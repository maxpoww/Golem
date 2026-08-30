# Golem OS — Roadmap (now → finished ISO)

> One project, one order, starting at `todo/todo1.md`. Each section S<N> has
> a matching task file `todo/todo<N>.md`; the Android workstream has
> `todo/todo-android.md`. A section is entered only when the previous one's
> exit line is true (S3 is the exception — continuous once opened). Near
> sections have detailed todos; far ones are coarse on purpose and get
> broken down on entry ("just-in-time detail").
>
> Scope sources: `Golem.md` (vision) · `features.md` (universe of user
> needs) · `apps.md` (app strategy) · `android.md` (phone strategy) ·
> `optionsmodules.md` (module queue, Max's file).

## S1 — Land & clean *(where we are now)*

Close every open loop so we start the climb with empty hands: land the
clipboard-dictionary branch, retire the stale plan docs, fix doc drift,
version this directory.
**Exit:** main is green, nothing uncommitted, docs point at this roadmap.

## S2 — The Spine (Brain ↔ Body)

Wire `options-engine` into the daemon (tokio→calloop bridge) and drive ONE
existing affordance from an `OptionSet`, deleting its daemon-side duplicate
sensing. This turns the philosophy into a running system. Also unblocks W-A
(the phone collector needs this wiring).
**Exit:** one surface is engine-driven end to end, on the live session.

## S3 — OPTIONS modules *(continuous from here on)*

The production line: migrate the live surfaces onto the Brain, then
implement modules from `optionsmodules.md` (its Planned list is the queue)
as collector → provider → surface. New ideas enter *that* file; work enters
*this* section. Never blocks S4+.
**Exit:** never "done" — the definition-of-done in optionsmodules.md is the gate per module.

## S4 — System controls

The things a person expects to just work from the shell: wi-fi, bluetooth,
audio devices, brightness, power/battery, displays (features.md §4–§5).
Each built as an OPTIONS module (they're contexts too), so S3's pipeline is
the factory.
**Exit:** a Golem session is livable without ever opening a terminal.

## S5 — The app set

Ship the everyday apps per `apps.md`: `golem-apps.nix` for the CURATE
column, theming pass, default-apps/mime wiring, per-app touch check,
browser decision, Nautilus handoff. BUILD-column apps flow through S3 as
modules; the long tail stays webapps.
**Exit:** a fresh Golem covers every §6 need in `features.md` — nobody stranded.

## S6 — Configuration UI

Settings as a surface: theme, dock behavior, input, OPTIONS toggles — the
full panel inventory of features.md §3. The UI edits *intent*; underneath
it writes the declarative config (TOML / generated nix) — same trust model
as the install pipeline.
**Exit:** everything a user may want to change is changeable without editing files.

## S7 — The Golem system flake

The distro composition: ONE flake that describes a complete Golem PC —
custom Hyprland, waverunner, options-notify, golem-apps, defaults, theming,
users. `nixos-rebuild build-vm` gives us a full test Golem in a window,
which becomes the daily test loop for everything after.
**Exit:** one command produces a bootable Golem VM identical to the vision.

## S8 — First run & onboarding

The "everyone" moment: first boot, user creation, language, and a diegetic
tour — OPTIONS teaching itself by surfacing at the right moments (game
onboarding, not a slideshow). Seeds the skill calibration.
**Exit:** a non-Linux person gets from first boot to browsing + installing an app, unassisted.

## S9 — Installer & ISO

The live ISO boots straight into a real Golem session; installing is one
guided, friction-free flow (disk, user, done) that instantiates the S7
flake onto the machine.
**Exit:** ISO on a USB stick → working Golem PC, no terminal, no docs.

## S10 — Website & release

golem-os.com grows from the manifesto (live since 2026-08-29) into the
front door: the story, screenshots, the download, honest install
instructions. First public alpha: **Golem 26 "Uprise"**.
**Exit:** a stranger can find, download, install, and use Golem.

## S11 — Everyone-hardening *(cross-cutting, finishes last)*

The gap between "everyone" as ethos and as spec: i18n of the shell,
keyboard-only paths, accessibility (features.md §9), testing with real
non-expert humans. Runs alongside S8–S10, closes after them.
**Exit:** the word "everyone" on the website is true.

---

## W-A — Golem × Android *(parallel workstream; see `android.md`, `todo/todo-android.md`)*

Starts any time after S2 (the phone collector needs the Brain↔Body wiring).
Fork KDE Connect Android → rebrand **Golem** → P1 presence (pair, notifs,
universal clipboard, phone pill) → P2 communication → P3 magic (mirroring,
webcam, hotspot, unlock) → P4 fusion. The open answer to Mac+iPhone.
**Exit (P1):** a non-technical person pairs in under a minute and sees phone notifications on the desktop.

---

**Cross-cutting rules (always):** coherence over features · see it before you
believe it (verify-ui) · dt-based motion · safety at the OS edge (no
unprompted rebuild/switch) · new ideas → `optionsmodules.md`, never straight
to code.
