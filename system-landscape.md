# System landscape — what an S4 collector listens to

> Survey for **S4 — System controls** (roadmap). One section per control:
> the bus/protocol it lives on, the exact thing a collector subscribes to,
> the thing a module calls to *act*, what Golem already ships for it, and
> the gotcha that will bite.
>
> **Provenance.** Everything marked *(Golem)* is cited to a file:line in this
> repo and is checkable. Interface, signal and property names are from the
> published NetworkManager / BlueZ / systemd / UPower / wlroots specs — this
> survey was written without live D-Bus introspection, so treat the spec-side
> names as "verify with `busctl introspect` on first use", not as measured.
>
> Freeze note: this is Arc-2 prep. Nothing here gets built until S3 opens.

## The shape of the problem

Five controls, but only **three** transports:

| Control | Transport | Collector connection |
|---|---|---|
| network | D-Bus **system** bus, `org.freedesktop.NetworkManager` | new |
| bluetooth | D-Bus **system** bus, `org.bluez` | new (same connection) |
| power / battery / idle | D-Bus **system** bus, `org.freedesktop.login1` (+ UPower, not installed) | new (same connection) |
| brightness | sysfs read + logind write | none (fd) |
| audio | PipeWire native protocol — **not D-Bus** | its own mainloop thread |
| displays | Hyprland IPC (already spoken) | existing |

So S4's real plumbing cost is **one system-bus connection** shared by three
modules, plus **one PipeWire mainloop thread**. Everything else reuses what
the engine already has. The engine talks to the *session* bus today (busctl
→ options-notify, optionsmodules.md:35); the system bus is genuinely new.

`zbus` is the natural Rust binding for all the D-Bus work — async and
tokio-native, so it drops into the same tokio thread that `brain.rs` already
runs and feeds the calloop channel. PipeWire is the odd one out: it insists
on its own loop.

## 1. Network (NetworkManager)

**Listens to** — system bus, `org.freedesktop.NetworkManager` at
`/org/freedesktop/NetworkManager`:

- Root `PropertiesChanged`: `State` (20 disconnected / 40 connecting /
  50 connected-local / 60 site / 70 global), `Connectivity`,
  `PrimaryConnection`, `WirelessEnabled`, `Devices`.
- Per-device `org.freedesktop.NetworkManager.Device.StateChanged(new, old,
  reason)` — `reason` is what tells a surface *why* a join failed
  (bad psk = `NM_DEVICE_STATE_REASON_NO_SECRETS`, 7).
- Wi-Fi device `…Device.Wireless`: `AccessPointAdded` / `AccessPointRemoved`,
  props `ActiveAccessPoint`, `LastScan`.
- AP objects `…AccessPoint`: `Ssid` (**`ay`, raw bytes — not a string**),
  `Strength` (`y`, 0–100), `Flags` / `WpaFlags` / `RsnFlags` (security),
  `Frequency`, `HwAddress`.
- `…Settings`: `NewConnection` / `ConnectionRemoved` — this is "known
  networks". `…Settings.Connection.Updated`, `GetSettings`.

**Acts by** — `AddAndActivateConnection2` (join a new SSID, psk passed
inline), `ActivateConnection` (rejoin a known one), `DeactivateConnection`,
`Settings.Connection.Delete` (forget), `Device.Wireless.RequestScan`.

**Secrets.** Two paths: register a `org.freedesktop.NetworkManager.SecretAgent`
via `AgentManager.Register`, or pass `802-11-wireless-security.psk` inline in
`AddAndActivateConnection2` and let NM persist it in its own keyfile store.
**Take the inline path** — a secret agent means the daemon must stay alive to
answer for every reconnect, and Golem has no keyring in the picture.

*(Golem)* `networking.networkmanager.enable = true`
(system/configuration.nix:88); `max` is in the `networkmanager` group
(system/configuration.nix:116) → polkit grants
`org.freedesktop.NetworkManager.settings.modify.system` with no password
prompt. Stopgap: `networkmanagerapplet` / nm-connection-editor
(system/configuration.nix:189).

**Gotcha.** `Strength` repaints continuously during a scan. Piped straight
into `OptionSet` it churns the Mind every few hundred ms. Debounce in the
collector — quantise to bars, emit on change only.

## 2. Bluetooth (BlueZ)

**Listens to** — system bus, `org.bluez`. The primary subscription is *not* a
BlueZ interface at all, it's `org.freedesktop.DBus.ObjectManager` at `/`:
`GetManagedObjects` once, then `InterfacesAdded` / `InterfacesRemoved`.
Devices *are* objects; appearing and disappearing is the event stream.

- Adapter `/org/bluez/hci0`, `org.bluez.Adapter1`: `Powered`, `Discovering`,
  `Discoverable`, `Pairable`; `StartDiscovery`, `StopDiscovery`,
  `SetDiscoveryFilter`, `RemoveDevice`.
- Device `/org/bluez/hci0/dev_XX_…`, `org.bluez.Device1`: `Alias` / `Name`,
  `Address`, `Paired`, `Bonded`, `Trusted`, `Connected`, `RSSI` (present
  **only while discovering**), `Icon`, `Appearance` / `Class`, `UUIDs`;
  `Pair`, `Connect`, `Disconnect`.
- `org.bluez.Battery1.Percentage` — peripheral battery, for the headset pill.

**Pairing needs a surface mid-transaction.** `AgentManager1.RegisterAgent`
with an object implementing `org.bluez.Agent1` — `RequestConfirmation`
(show a 6-digit passkey, wait for yes), `DisplayPasskey`, `RequestPinCode`,
`AuthorizeService`. Capability `"KeyboardDisplay"`. This is the only S4
control that must *block on the user* inside a D-Bus method call, and it's
the strongest argument for a real box rather than a pill (see §7).

*(Golem)* `hardware.bluetooth.enable`, `powerOnBoot`, `Policy.AutoEnable`,
and `Experimental = true` (system/bluetooth.nix:6–18) — experimental turns on
`Battery1` for more devices and `AdvertisementMonitor1`. Autostart already
shell-scripts what the module will own: `bluetoothctl power on`
(system/home/hyprland.lua:37) and a trusted-device auto-reconnect loop
(system/home/hyprland.lua:39). Stopgap: blueman
(system/home/waverunner-packages.nix:6) + `blueman-applet`
(system/home/hyprland.lua:38).

**Gotcha.** BlueZ allows exactly **one** default agent, and `blueman-applet`
registers one at login. The Golem agent will lose the race or steal it.
Retire blueman in the *same* commit that lands the module — not the one after.

## 3. Audio (PipeWire / WirePlumber)

**There is no D-Bus name to subscribe to.** PipeWire speaks its own protocol
over `$XDG_RUNTIME_DIR/pipewire-0`. Three ways in:

1. **`pipewire-rs`** (recommended). Register a registry listener on the core;
   sinks/sources arrive as `PipeWire:Interface:Node` with props
   `media.class = Audio/Sink | Audio/Source`, `node.name`,
   `node.description`. Volume and mute are not props — they live in the
   node's `SPA_PARAM_Props` param (`channelVolumes`, `mute`), read via
   `enum_params` and set via `set_param`. The *default* sink/source is
   WirePlumber's metadata object (`PipeWire:Interface:Metadata`, name
   `default`, keys `default.audio.sink` / `default.audio.source`) — watch it
   for the picker's current selection.
2. **libpulse** against the pulse compat layer. `services.pipewire.pulse.enable`
   is on (system/audio.nix:11), so the classic subscribe-to-events API works
   and is much simpler than the registry. Heavier dep, and it lies about
   anything PipeWire-native.
3. **Shell out to `wpctl`** and poll. What the session does today.

Go with (1), and accept the cost: `pipewire-rs` runs its own mainloop, so the
audio collector is a *second* dedicated thread feeding the brain channel —
the same shape as the tokio thread in `brain.rs`, not a passenger on it.

*(Golem)* PipeWire with alsa/pulse/jack and WirePlumber rules pinned for the
TAS2781 amp and BlueZ codecs (system/audio.nix:7–51). Volume/mute keys go
through `wpctl` today (system/home/hyprland.lua:318–321). Stopgap:
`pavucontrol` (system/configuration.nix:188).

**Gotcha 1.** `audio-keepalive` holds a permanent silent stream on the sink
to keep the amp awake (system/audio.nix:53–63). Any "is audio playing?"
heuristic based on active streams is **always true** on this hardware. Sense
playback from MPRIS, not from PipeWire node state.

**Gotcha 2.** A connected headset exists twice — as a BlueZ `Device1` and as
a PipeWire node. Two collectors, two truths, one physical object. Deciding
which module owns the headset is a §7 question, not an implementation detail.

## 4. Brightness + power / battery

One todo item, but **three unrelated sources**:

**Backlight** — sysfs `/sys/class/backlight/*/{brightness,max_brightness}`.
Reading is a file read (real backlights support `poll()` via `sysfs_notify`,
so no timer needed). Writing has two paths: the `video`-group udev rule
(`max` is in `video`, system/configuration.nix:118), or — cleaner —
logind's `org.freedesktop.login1.Session.SetBrightness(subsystem, name, value)`
on the session object, which needs no group, no udev rule and no suid helper.
Prefer logind: it survives a stranger's user account, which the group path
does not.

**Battery / AC** — either sysfs
`/sys/class/power_supply/BAT*/{capacity,status}` + `AC*/online`, or UPower on
the system bus: `org.freedesktop.UPower` `DeviceAdded`/`DeviceRemoved`, and
`org.freedesktop.UPower.Device` props `Percentage`, `State` (1 charging,
2 discharging, 4 full), `TimeToEmpty`, `WarningLevel`, with the aggregate at
`/org/freedesktop/UPower/devices/DisplayDevice`.

> **Verified finding: UPower is not installed on Golem.** No `services.upower`
> anywhere in `system/`, and `upower` is absent from `PATH`. The shipped
> battery module (optionsmodules.md:30–37) therefore senses via sysfs, not
> UPower. Any power module that wants `TimeToEmpty` or `WarningLevel` is
> **adding a system dependency**, not picking up a free upgrade — that's a
> deliberate call, and it belongs in the flake, so it's an S7 edit too.

**Sleep / idle / lock** — logind, system bus:
`org.freedesktop.login1.Manager.PrepareForSleep(bool)` fires **both** before
sleep (`true`) and after wake (`false`) — the `false` edge is exactly where
the battery ladder's "woken and still ≤5%" step hangs. Also `Suspend`,
`Hibernate`, `Inhibit` (returns an fd; hold it to finish a warning before the
machine goes down), `LockedHint`; and on the Session object, `Lock` / `Unlock`
signals and `IdleHint`.

*(Golem)* `brightnessctl` bound to the XF86MonBrightness keys
(system/home/hyprland.lua:322–323, package
system/home/waverunner-packages.nix:8) — that's the stopgap.
`XF86PowerOff` → `systemctl hibernate` (system/home/hyprland.lua:315).

**Gotcha.** The battery ladder already calls suspend and hibernate. A power
module that also drives logind means two things racing for the same
transition — precisely the "no duplicate plumbing left in the daemon" the
DoD forbids (optionsmodules.md:63–65). The power module must **absorb** the
shipped battery module, not land beside it. Budget for that: it is a rewrite
of something that already works, and it should be checked against Max's
ladder spec line by line.

## 5. Displays

The portable answer is **`wlr-output-management-unstable-v1`**:
`zwlr_output_manager_v1` emits a `head` per output, each head emitting
`name`, `description`, `physical_size`, `mode`, `enabled`, `current_mode`,
`position`, `transform`, `scale`, `make`/`model`/`serial_number`, then a
`done(serial)`. Changes go through `zwlr_output_configuration_v1` — build it,
`enable_head`/`disable_head`, `apply`, then wait for
`succeeded`/`failed`/`cancelled`. Properly atomic and properly testable.

But Golem ships **its own Hyprland fork**, and the window-pills collector
already speaks Hyprland's IPC (optionsmodules.md:11–17). Hyprland gives
`hyprctl monitors -j` (name, make/model/serial, resolution, refreshRate,
x/y, scale, transform, focused, activeWorkspace, availableModes, disabled)
and socket2 events `monitoradded` / `monitorremoved` / `focusedmon`.

**Recommendation:** sense via Hyprland IPC — reuse the connection that
exists. Reach for wlr-output-management only if a displays module ever has
to run off-Hyprland, which the roadmap says it never does (ONE flake = custom
Hyprland).

**Gotcha — this is the hard one.** `hyprctl keyword monitor …` does **not**
persist. Golem's real monitor state is declarative Lua
(`hl.monitor{ output = "eDP-1", mode = "3200x2000@165", scale = 1.60 }`,
system/home/hyprland.lua:4–9). A displays module that lets someone drag a
screen and doesn't write back into that config produces an arrangement that
vanishes at logout — worse than no module. Writing back means the module
edits declarative intent, which is **S6's** problem
(roadmap:69–70) arriving early inside S4. Sequence displays *last* of the
five, or accept it stays session-only and say so on the surface.

## 6. Cross-cutting

- **Polkit.** Everything above is granted either by group membership
  (`networkmanager`, `video`) or to the active local session by logind. That
  works because this is Max's machine. **OPTIONS has no password-prompt
  surface at all** — the first action that needs one has nowhere to go. Not
  an S4 blocker, but it is an S9 one: a stranger installing Golem may not
  land in the same groups (system/configuration.nix:111–122 hardcodes `max`).
- **MPRIS** (`org.mpris.MediaPlayer2.*`, **session** bus) belongs to the media
  module (todo3), not S4 — but it shares the session-bus collector and it is
  the honest source for "is something playing" given the keepalive stream.
  Stopgap: `playerctl` (system/home/home.nix:49,
  system/home/hyprland.lua:326–329).
- **Every stopgap has a name and an owner.** networkmanagerapplet → network ·
  blueman + blueman-applet → bluetooth · pavucontrol → audio · brightnessctl
  → brightness · playerctl → media. Each dies in the commit that lands its
  module (roadmap:62–63), and each removal is a `system/` edit in this repo,
  so every S4 module is a two-repo change: waverunner for the module, Golem
  for the retirement.

## 7. Open — feeds the surface-pattern decision

Left for Max (todo4's last item). The survey's contribution to it:

- **Bluetooth pairing blocks on the user** (passkey confirmation inside a
  D-Bus call). A pill cannot host that; something box-shaped must exist.
- **Wi-Fi joining needs text entry** (psk). Same conclusion.
- **Volume, brightness and battery are glanceable scalars** that want to be
  visible without opening anything. Opposite conclusion.
- **The headset exists in two modules at once** (§3), so whatever the pattern
  is, it needs an answer for one object surfacing twice.

That reads as *both*: resting pills for the scalars, one shared "system" box
for the transactional controls (join, pair, pick output, arrange). But which
one is Max's call, and it should be made before the first module is built,
not after — the pattern decides the module boundaries, not the reverse.
