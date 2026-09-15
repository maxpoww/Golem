# Changes — the Installing ledger

The deferred queue for the next ISO, exactly as preinstall ran it
(archived original: `~/GolemOne/Install/Preinstall/testing/changes.md`).
**The number line is one line:** #1–#61 live in the preinstall archive
and DockMenu's FINDINGS.md; this file continues at **#62**. Round-scoped
surface items are `I<round>-<n>`.

## How to use this file

- While a round runs, a finding's raw experience goes in the machine's
  file; the CHANGE it implies lands here: what / why (which finding,
  which machine) / where (file:location) / size (small · medium ·
  needs-Max). Status rides the header tag.
- Nothing lands in an ISO mid-round. Round closes → work the queue top
  to bottom → `nix flake update` → rebuild → verify the built artifact
  → VM gate → reflash → move applied entries below with their round.
- Waverunner-side fixes ride the launcher → Golem lock → seed pipeline
  and are marked with their launcher rev.
- The live-fix refinement applies: a queued fix may be verified on a
  booted machine as a RAM overlay / seed update, marked
  **[verified live on <machine>]** — the frozen stick still never
  reburns mid-round.

## Queued for the next ISO

### 95. THE MENU FINALLY READS LIKE GOLEM — item_align, the hidden icon gutter, and the words — [BUILT + live on the acer 2026-09-15 · Max's eyes owed · the comodore and the ISO owe the same update]
Max at the acer's first GRUB-EFI menu: *"it does not look like
systemd-boot, on grub, the items are centered but aligned to the left
and the selection is huge. i want the look that we got on the usb."*
Three separate causes, all found by reading `gui_list.c` rather than
guessing:
- **A 32px icon gutter nobody asked for.** GRUB defaults
  `icon_width`/`icon_height` to **32** and reserves `icon_width +
  item_icon_space` on the left of every row whether an icon exists or
  not. Our theme never set them, so every label sat 32px right of where
  the theme said. Fixed: both to 0 in grub-theme.nix.
- **GRUB cannot centre a menu item at all.** `draw_menu` draws each
  title at x=0 of its viewport and stretches the selection bar across
  the full content width — the same one-width-for-all-rows rule
  syslinux has, but WITHOUT syslinux's `MENU INDENT` escape hatch.
  Fixed by patch: `grub-item-align.patch` adds an `item_align`
  property (left/center/right), using the row's own font and clamping
  at 0 so an over-wide label still clips exactly as before.
- **The words were NixOS's, not Golem's.** `<distro> - All
  configurations` and `<distro> - Configuration N (date - version)` —
  the latter ~600px, clipping off the box for as long as the theme has
  existed. The menu now reads **`Start Golem`** / **`Previous
  Versions`**, with **`Gen N - YYYY-MM-DD`** inside. Max landed there
  after weighing snapshots / backups / recover / restore; two traps
  were dodged on the way, and both are claims about what a generation
  IS:
  - "snapshots"/"backups" promise DATA safety it does not give — the
    files are untouched, not backed up;
  - "restore" promises PERMANENCE it does not give either. **Checked
    on the acer before arguing it:** the entries carry no
    `savedefault` and `set default=0` pins the newest generation, so
    picking an old one is a **one-time boot** — next reboot is back on
    current. A noun phrase promises nothing and stays true.
  "Start" also lines the installed menu up with the medium's
  Start/Install, so a stranger meets the same verb on the USB and on
  the machine it installed.
  Mechanism: the titles are baked into `install-grub.pl` with no
  option behind them, so the leaf rewrites the generated grub.cfg in
  `extraInstallCommands` (runs right after the generator, idempotent
  by construction). The alternative was vendoring the whole 900-line
  grub module for two strings — the ISO already vendors iso-image.nix,
  so that door stays open if this ever gets fragile.
- **Geometry, measured not guessed** (ImageMagick against the same
  DejaVu at the same size): widest row in the whole tree is now
  `Gen 15 - 2026-09-15` at 210px → a 222px bar in a **226px** box at
  `50%-113`, down from 360px.
- **Also done:** `boot/grub-patched.nix` — the patched package AND the
  menu wording, imported by both leaves, so the two firmware halves
  cannot drift (#92's lockstep comment was an invitation to drift).
- **still available if it reads too wide:** drop the dates from the
  recovery rows and every row becomes "Gen N"-sized — box collapses to
  ~95px, genuinely USB-tight, at the cost of picking a generation by
  number with no date to reason about.
- **where:** `boot/grub-item-align.patch`, `boot/grub-patched.nix`,
  `boot/grub-theme.nix`, both leaves' geometry.
- **owed:** the comodore (powered off — one delivery + reboot) and the
  ISO's own menu at the recut, so medium and installed match.

### 94. THE FIRMWARE DELETES YOUR BOOT ENTRY — a loader that lives only in NVRAM is at the mercy of the machine — [FOUND + FIXED 2026-09-15 · the acer, #92's first metal · wire-verified]
The acer took GRUB-EFI perfectly: `grubx64.efi` installed, a named
`Golem-boot` NVRAM entry created, BootOrder **`0002,0001,2001,…`** with
Golem first. One reboot later the firmware had **dropped entry 0002 from
BootOrder entirely** (`0001,2001,2002,2003`) and booted its own generic
`HDD: Hitachi` entry — which runs the removable fallback
`\EFI\BOOT\BOOTX64.EFI`. That file was still **systemd-boot**, whose
entries stop at generation 2, so the machine came up on the OLD
generation and GRUB never ran. Everything we installed was correct; the
firmware simply refused to keep it.
- **why this is a class, not a machine:** old consumer firmware curates
  its own boot list. Trusting NVRAM means trusting the machine to
  remember a favour. The removable path is the one location every
  firmware falls back to, and nothing purges it.
- **fix:** `efiInstallAsRemovable = lib.mkDefault true` +
  `canTouchEfiVariables = false` (NixOS asserts they are mutually
  exclusive) in `boot/grub-efi.nix` — the DEFAULT for every UEFI
  machine, not an acer quirk. With no NVRAM writes there is no named
  entry to lose; mkDefault leaves room for a machine that needs one.
- **the gotcha that cost a reboot:** `nixos-rebuild boot` re-generates
  grub.cfg but SKIPS `grub-install` when it thinks nothing changed —
  `efiInstallAsRemovable` flipping is not enough to trigger it.
  **`--install-bootloader` is required** whenever the loader's
  installation shape changes. Worth remembering for the installer too.
- **predicted:** this is very likely what would have met us on the
  macbook (Apple EFI) — the quirk grub-efi.nix's header anticipated is
  now the default, so that boss fight may already be won.
- **verified:** fallback path is byte-identical to `grubx64.efi`;
  `booted == current == jr3f86mg…` (a generation only GRUB knows);
  running, 0 failed. sd-boot's binary + a backup of the old fallback
  kept on the ESP as an F12 escape hatch.
- **where:** `system/Modular/boot/grub-efi.nix`.
- **size:** done. Same change carries to the ISO's UEFI side at the recut.

### 93. THE KERNEL'S STUB SAYS "No EFI environment detected." ON EVERY BIOS BOOT — unsilenceable by loglevel, cured by the graphics handoff — [VERIFIED 2026-09-15 · gen 6, wire + Max's eyes: "the message is gone, clean boot"]
After the menu, one line survived the quiet boot: the kernel's
REAL-MODE STUB warns "No EFI environment detected." when it finds no
EFI tables on a BIOS machine, writing STRAIGHT INTO VGA TEXT MEMORY
before printk exists — no `quiet`, no `loglevel=0`, no journal setting
can reach it (which is why the string appears on screen yet in no log;
found by grepping the whole closure: it lives in bzImage's
uncompressed stub region).
- **why it was visible at all:** NixOS's BIOS grub.cfg does
  `set gfxpayload=text` — the screen is switched BACK to text mode for
  the kernel handoff, so the stub's VGA write shows (and the
  menu→boot mode-switch flash comes from the same line). The EFI path
  has always used `gfxpayload=keep`.
- **fix:** `gfxpayloadBios = "keep"` in grub-bios.nix (#92's sameness
  principle applied one layer deeper): the menu's framebuffer survives
  into KMS, the stub's text lands in memory nothing displays, and the
  text-mode flash is gone. Wire-verified on gen 6: booted, `running`,
  0 failed, console on `i915drmfb`.
- **tradeoff, accepted and recorded:** a stub-LEVEL kernel failure
  (corrupt image, decompression error — rare) is now a silent black
  hang instead of a printed error. If a BIOS machine ever hangs black
  before any disk activity, boot once with gfxpayload=text and read
  the screen.
- **where:** `system/Modular/boot/grub-bios.nix`. The ISO's loaders
  are syslinux (BIOS) / GRUB-EFI — neither has this handoff, nothing
  owed there.
- **size:** one line, done.

### 92. TWO BOOTLOADERS, ONE LOOK — systemd-boot retires, GRUB-EFI takes firmware=uefi — [DECIDED by Max 2026-09-15 · REWIRED in source, matrices green · metal owed on the UEFI machines]
Max, after the comodore's quiet boot landed: *"i want Golem to look and
feel the same no matter if it is booting on grub or Systemd."* The
technical fact that decides the shape: **systemd-boot has no theming at
all** — font, colors, geometry are compiled in — so the grub theme's
sd-boot mimicry had a hard ceiling, and one look everywhere means one
MENU everywhere.
- **done in source:** `boot/grub-efi.nix` (new leaf: same theme
  numbers, same #89 quiet-patch overlay, `efiSupport`+`nodev`,
  canTouchEfiVariables; sd-boot's stale-boot-pin housekeeping does NOT
  carry over — that was a bootctl/EFI-var mechanism only sd-boot
  reads). Chooser: `firmware=uefi → boot/grub-efi.nix`. All six
  fixture expectations in chooser-matrix and four UEFI assertions in
  minimal-matrix flipped and GREEN. The patched EFI grub variant
  builds (the BIOS-sector hunks simply don't compile on EFI; the
  banner/cursor hunks do). `systemd-boot.nix` kept with a RETIRED
  header for the day a machine truly cannot GRUB.
- **owed on metal:** the acer and asus run sd-boot today — each gets
  grub-efi by live-fix rebuild on its next turn (their ESPs keep
  sd-boot files until then; harmless, grub writes its own). The
  macbook's Apple EFI may need `efiInstallAsRemovable` as a quirk —
  decide on its metal. The ISO's UEFI GRUB gets theme+patch at the
  recut (#89's note) — after which ALL four boot surfaces (ISO
  BIOS/UEFI, installed BIOS/UEFI) show the same Golem menu, the ISO's
  BIOS syslinux being the one bespoke sibling.
- **where:** `boot/grub-efi.nix`, `boot/systemd-boot.nix` (header),
  `choose.nix`, both matrices.
- **size:** source done; metal = one rebuild per UEFI machine.

### 91. A HIBERNATION IMAGE MAKES A POWER-ON NOT A BOOT — "reboot required" can be undischargeable from the power button — [FOUND 2026-09-15 · the comodore · lab-method + audit consequence]
Gen 2 was activated 09-14 with `REBOOT REQUIRED` recorded as owed. The
machine was then power-cycled at least twice (hibernated overnight, Max's
power-on at the screen 09-15) — and this morning `/run/booted-system`
STILL said gen 1 (`yi4krfsi…`) while the profile said gen 2 (`8mwl79j0…`).
- **mechanism:** power/laptop's bag timer (`suspend-then-hibernate`,
  image to disk after 120 min) + the wired `resume=` mean a power-on
  goes GRUB → initrd finds the hibernation image → **restores the OLD
  session** — same kernel, same boot id, same generation. The GRUB menu
  shows, the machine "boots", and no boot happened. On the comodore,
  #90's stuck lid is what wrote the image unattended.
- **why it matters to the method:** "power-cycled" and "rebooted" are
  different claims on any machine carrying this leaf. The `REBOOT
  REQUIRED` state can survive the power button INDEFINITELY; only an
  explicit `systemctl reboot` (a clean shutdown discards no-image) or a
  consumed/absent image lets the new generation actually boot. The
  audit already asks the right question (`booted:` vs `current:` from
  /run) — trust THAT line, never the power button.
- **not a bug:** hibernation doing its exact job. The finding is that
  our records equated power-on with boot; they must not.
- **where:** lab method + a note in the audit's reading; touches #88's
  generation bookkeeping and this machine's "still owed" reboot.
- **size:** no source change. Method note; recorded here so the next
  machine with power/laptop doesn't re-earn it.

### 90. THE LID SWITCH LIES — stuck "closed", the machine sleeps 30 s after every wake — [VERIFIED LIVE 2026-09-15 · quirk live since gen 3, zero suspends across gens 3–5 · the census fact is needs-Max]
**Addendum:** after the gen-3 reboot the switch read **open** again —
it lies INTERMITTENTLY, which is worse than stuck (yesterday's clean
audit was luck, not health). The quirk stays regardless of today's
reading.
Max: *"after like 30s ish, it goes sleep, i have to touch the power
button to wake it up.. and that is Golem."* It was. Evidence, pulled in
one of the 30 s wake windows (the machine was then pinned awake by
masking the sleep targets):
- `/proc/acpi/button/lid/LID/state` = **closed** — with the lid open
  and Max standing at the screen. The switch is stuck.
- battery innocent: BAT0 fully-charged 100%, on AC (`on-battery: no`).
- journal: `PM: suspend entry (deep)` every **~31–35 s**, the cadence
  of logind's post-resume holdoff.
- **mechanism:** power/laptop (chassis=laptop) sets `HandleLidSwitch =
  suspend-then-hibernate`. logind ignores the lid for
  `HoldoffTimeoutSec` (default **30 s**) after every boot/resume, then
  acts on the LEVEL it reads — stuck "closed" → sleep, forever. The
  eyes at the screen change nothing; systemd believes the switch.
- **why the lab never saw it:** the installation medium sets the lid
  switch to ignore (installation-device profile) — every census and
  delivery night was immune; and on the 09-14 audit morning the switch
  still read open — the machine was moved between sessions, and a 2008
  magnetic reed switch sticks.
- **fix (in source, owner-edit):** `system/Modular/quirks/lid-switch-broken.nix`
  — `HandleLidSwitch = "ignore"`, plain definition beating
  power/laptop's mkDefault; power button, manual suspend and the bag
  timer stay live. Wired into the comodore's `hosts/target/modules.nix`
  as a commented OWNER EDIT (rule: the chooser points, the owner may
  add) — the chooser matrix pins the chooser's resolve, so an owner
  line is visible drift-free.
- **needs-Max (the chooser question):** a census fact IS possible —
  during an interactive census someone is typing at the machine, so a
  lid device reading "closed" at that moment is self-evidently a lie →
  `lidSwitchStuck=true` → the chooser adds the quirk itself. Worth it,
  or does a lying lid stay an owner call?
- **where:** the quirk leaf, `hosts/target/modules.nix`, the census
  fact set if blessed; the raw capture in the machine file.
- **size:** done for the comodore; small for the fact.

### 89. GRUB SAYS ITS OWN NAME BEFORE THE THEME CAN STOP IT — the banner, then the blinking cursor — [VERIFIED LIVE 2026-09-15, gens 3→5 on the comodore · software side CLOSED · the UEFI/ISO side owed at the recut]
**Final state:** boot fully silent from Golem's first MBR instruction to
the themed menu. Three iterations, Max's eyes as the instrument each
time (gen 3 banner gone / gen 4 cursor still blinks — window is earlier
than core / gen 5 cursor-hide as boot.S's OPENING MOVE → one blink
left, which is the BIOS's own pre-MBR cursor, out of software's reach).
MBR bytes read back from /dev/sda after landing. Full account:
comodore.md, the I2 coda.
**Live-verify, first half (gen 3, Max at the screen):** the "GRUB.."
banner is gone — "looks good". What the silence exposed: the firmware's
hardware TEXT CURSOR, blinking alone on the empty screen ("it blinks
twice") while core loads modules/theme/font from the 2008 HDD. GRUB
never hides it until gfxterm takes the display. Second hunk added to
the same patch: `grub_console_init` now hides the cursor at
registration (BIOS int 10h, shape 0x2000), before anything else runs;
the command-line reader re-enables it through `setcursor` when it
actually wants one, so the emergency CLI keeps its cursor.
Max's eyes on the comodore's first themed boot (#68's still-owed
observation): the menu itself "looks better", but a `GRUB..` message
flashes before it. Three banners print BEFORE grub.cfg is ever read, so
no theme or config option can prevent them — the theme only clears them
after the fact (grub-bios.nix's header even documented the chatter and
assumed clearing was enough; a flash is still a flash):
- `boot.S` (the MBR sector) prints **"GRUB "**;
- `diskboot.S` prints **"loading"** + a dot per read while core.img
  loads — on a 2008 machine this is the visible part;
- `kern/main.c` prints **"Welcome to GRUB!"** — upstream already
  silences this one on EFI ("this breaks flicker-free boot on EFI"),
  BIOS just never got the same care.
- **fix (in source):** `system/Modular/boot/grub-quiet.patch` — empties
  the three success-path strings, keeps every error string ("Geom",
  "Read", " Error"): silence on success, words on failure. Wired as a
  `nixpkgs.overlays` entry in `grub-bios.nix` because the grub module
  has no package option — it reaches for `pkgs.grub2` directly.
  Verified on the built artifact: `strings` on boot.img/diskboot.img
  show only error strings; zero "Welcome to GRUB" anywhere in
  `lib/grub/i386-pc/`.
- **why the stick never showed this:** on BIOS the medium boots through
  **syslinux/vesamenu** (its boot sector prints nothing and the round-8
  work alpha-zeroed its text); GRUB is only on the stick for UEFI —
  where the SAME flash exists in the ISO's GRUB side. The ISO grub is a
  different program (`iso-image-golem.nix`); pointing it at the same
  patched package is part of the next recut, noted there.
- **cost note:** a patched grub is not in cache.nixos.org, so a
  machine's LOCAL self-rebuild would compile grub from source (~slow on
  the small boxes). Deliver the closure from the dev box first (the #67
  throttle exists now) and the local rebuild finds it in the store.
- **where:** `system/Modular/boot/grub-quiet.patch` (the patch, header
  documents the re-vendor rule), `grub-bios.nix` (the overlay + #89
  comment), `iso-image-golem.nix` (owed: the UEFI side, next recut).
- **size:** done in source; live-verify on the comodore = deliver +
  switch + one more power-on with Max watching.

### 88. A SELF-REBUILT MACHINE FORGETS WHAT IT IS — `configurationRevision` becomes "unknown" — [FOUND 2026-09-14 · the comodore's gen 2 · answers the #35b carried decision with evidence]
The comodore's self-rebuild produced a toplevel that DIFFERS from the one
installed. Chased to the bottom, **the entire difference is one string**:
| | `configurationRevision` |
|---|---|
| gen 1 — built on the dev box | `d0347f9d34940e7225f39f39938097afcbef0fbc-dirty` |
| gen 2 — rebuilt from its own seed | **`unknown`** |

Everything else is byte-identical: same kernel, same kernel-params, same
binaries, `nix store diff-closures` **empty**, and the two `system-path`
buildEnvs differ only by the `nixos-version` input that carries the string.
- **cause:** `flake.nix` sets `system.configurationRevision = self.rev or
  self.dirtyRev or "unknown"`. The dev box's `~/Golem` is a git checkout,
  so it resolves to a dirtyRev; **the seed is a plain directory copy with
  no `.git`** (confirmed: `du` shows no `.git` in the seed), so it falls
  all the way through to `"unknown"`.
- **why it matters:** an installed Golem in the field, after its first
  self-rebuild, can no longer say what source it is running.
  `nixos-version --json` reports `"configurationRevision":"unknown"`
  forever after. That is the one field whose whole job is traceability,
  and the rebuild loop — the thing stage 0 exists to provide — is what
  erases it. Support, bisection and "which fix does this machine have?"
  all go through it.
- **this ANSWERS #35b** (implementation.md's carried decision: *seed git
  policy — plain-path vs git*). The question was open on aesthetics; it
  now has a consequence. Plain-path seeding costs the machine its
  identity string. Options: (a) seed as a real git repo with one commit,
  so `self.rev` resolves and stays stable; (b) have `golem-install` write
  the revision it built from into the seed as an explicit
  `system.configurationRevision` override, which needs no git at all and
  survives copying — **probably the right answer**, since the seed is a
  distribution artifact rather than a working tree; (c) accept "unknown"
  and stop claiming traceability.
- **not a regression, and not urgent:** gen 2 is functionally identical
  and the machine is healthy (`running`, 0 failed units). This is about
  what the machine can TELL you, not what it does.
- **where:** `Installer/preinstall/install.nix` (phase 3, the seed drop),
  `flake.nix` (the `configurationRevision` line), implementation.md's
  #35b carried decision.
- **size:** small for option (b). Needs-Max on which option.

### 87. A CHOSEN LEAF THAT DOES NOTHING, AND EVERY LAYER SAYS IT WORKS — thermald is a silent no-op on pre-RAPL Intel — [FOUND 2026-09-14 · the comodore's first boot · rule-10 class]
The chooser deliberately points the comodore at `power/thermald.nix`
(`chassis=laptop` + `cpuVendor=intel`). On the booted machine:
```
thermald[597]: NO RAPL sysfs present
thermald[597]: 13 CPUID levels; family:model:stepping 0x6:17:a (6:23:10)
thermald[597]: Need Linux PowerCap sysfs
thermald[597]: Unsupported cpu model or platform
```
…and it **exits 0**. Not a crash — a clean, successful exit after 2.2 s.
- **why nothing catches it:** systemd sees `status=0/SUCCESS`, so the unit
  is `enabled`, `inactive (dead)`, and **`failed units` stays 0**. The
  effect matrix asserts `services.thermald.enable == true` — which is
  TRUE, and useless. The install record would have said "thermald on" and
  been wrong in the only sense that matters. This is exactly constitution
  §10's lie: *success without verification*.
- **root cause:** RAPL / `/sys/class/powercap` arrive with **Sandy Bridge**
  (family 6 model 42). The comodore is **family 6 model 23** — Penryn,
  2008. `/sys/class/powercap/` does not exist on it. thermald has nothing
  to drive, correctly declines, and says so only in its own journal.
- **the chooser rule is too coarse.** `laptop + intel → thermald` is not
  the question; "does this CPU expose powercap/RAPL" is. Note
  `intelLegacy` is NOT the right discriminator either — the asus is
  Haswell, `intelLegacy=true`, and thermald works fine there.
- **the machine is NOT unprotected** (do not over-read this): `acpitz`
  zone reads 40.8 °C, two `Processor` cooling devices + LCD, `coretemp`
  loaded, `acpi_cpufreq` with the `schedutil` governor. Kernel/ACPI
  passive throttling is live. What is missing is thermald's adaptive
  layer — and, more importantly, our HONESTY about whether it is there.
- **blast radius:** the **hp** (i5 M 460 Arrandale, family 6 model 37 —
  also pre-Sandy-Bridge) is predicted to behave identically; it was
  powered off at the time of writing, so that is a prediction to confirm,
  not a result. The acer (Broadwell) and asus (Haswell) are post-RAPL and
  genuinely run it — their records saying "thermald active" are correct.
- **fix (needs-Max on the shape):** either (a) a new census fact —
  powercap/RAPL presence is directly observable on the medium, which boots
  the same kernel — and narrow the chooser to point at `power/thermald`
  only when it is true; or (b) keep pointing at it and make the leaf's
  header state plainly that it self-disables below Sandy Bridge, so the
  record stops implying an effect that is not there. (a) is the
  rule-4-correct answer: the chooser is the brain, and this is a fact
  about the machine.
- **the wider lesson, worth more than the leaf:** `minimal-matrix` proves
  CONFIGURATION, not EFFECT-ON-HARDWARE. "the option is set" and "the
  thing happens" are different claims, and only metal separates them.
  Every leaf whose payoff is a running daemon deserves an is-active check
  in the first-boot audit, not just an enable-flag assertion on source.
- **where:** `system/Modular/choose.nix` (the rule),
  `system/Modular/power/thermald.nix` (the header), the census/fact set,
  `system/Modular/effect-matrix.nix` (assert what it can).
- **size:** small to state, medium to do properly (a new fact).

### 86. THE NUMBER LINE HAS FORKED — #68 names two different findings — [FOUND 2026-09-14 · records integrity · needs-Max]
Constitution rule 9 says the number line is ONE line. It currently is not.
- **#68 (a)** — `OPTIONS/changes.md`: *"The Mind's ranked control row
  re-flows under the pointer — the Still Bar was never applied to it"*
  (STATED 2026-09-04). OPTIONS declares itself as continuing at #68 and
  has since allocated through **#84**.
- **#68 (b)** — the in-flight GRUB work, in source comments:
  `system/Modular/boot/grub-bios.nix`, `system/Modular/boot/grub-theme.nix`,
  `system/Modular/boot/systemd-boot.nix`, `system/Modular/base/core.nix`
  (*"#68 — Max, on the hp's stock menu: 'grub looks like shit…'"*).
- **how it happened:** both programs read "#1–#67 are taken" and both
  claimed #68, in different files, on the same night (09-11/09-12).
- **why it matters:** every rule-9 reference — "#68 ships in the I2 cut",
  "verified live on the comodore" — is now ambiguous, and tonight's
  install is the first artifact that carries one of them to metal.
- **the fix is Max's call**, because renumbering rewrites either a
  17-entry OPTIONS block or four source files' comments. The cheap
  direction: leave OPTIONS #68–#84 alone (they are written down and
  cross-referenced) and give the GRUB work **#85's successor number**,
  editing the four source comments. The durable direction: one allocator
  file that both ledgers append to, so a number is claimed once.
- **where:** `Installer/installing/constitution.md` §9 (the rule),
  `OPTIONS/changes.md` (the declaration), the four boot leaves.
- **size:** small to fix, needs-Max to decide which way.

### 85. A delivered store path can be PRESENT but UNREGISTERED — an `[ -e ]` presence check re-runs #67's damage silently — [FOUND + FIXED in the lab method 2026-09-14 · the comodore]
Found while resuming the comodore: `/mnt/nix/store` held **78** path
directories while the target database had registered only **76**. The gap
was a truncated `nix-manual-2.34.8` (plus its `.lock`) left mid-write when
#67 killed the machine.
- **why it is a trap:** the obvious "what still needs sending?" test is
  `[ -e /mnt$path ]`, and that test calls a half-written directory
  **present**. The first overnight delivery script used exactly that, so
  it would have skipped the one path that was actually broken and
  declared the closure complete.
- **the fix (applied in the delivery method):** ask the DATABASE —
  `nix --store /mnt path-info --all` lists only VALID paths, so a
  truncated path is correctly seen as missing and re-sent. Cheap: one ssh
  round-trip per round, compared locally.
- **how bad was it really:** it would have failed LOUDLY, not silently —
  `nixos-install` against an invalid path errors out. So this costs a
  wasted delivery, not a broken machine. Recording it anyway because
  **the offline installer will write this exact code** (implementation.md
  step 8e), and it will be delivering to a disk whose previous attempt
  may have died the same way.
- **where:** lab method; and a note owed at implementation.md step 8e so
  the offline installer inherits the database check rather than
  rediscovering it.
- **size:** no Golem source change owed today. Method + a design note.

### 67. A multi-GB closure delivery over a USB WIFI DONGLE kills the machine — two machines, same night, same signature — [ROOT CAUSE FOUND + ANSWERED 2026-09-14 · it is SATURATION, and a throttle fixes it]
**ANSWERED (2026-09-14, the comodore).** The killer is **link saturation,
not the dongle's existence**. A rate-limited, per-path delivery moved the
**whole 2.96 GiB / 1037-path closure over a USB wifi dongle in 1 h 52 m
with ZERO drops, ZERO backoffs and ZERO waits** — one uninterrupted pass,
~460 KB/s average, the cap auto-climbing 400 → 500 → 625 → 781 → 900 KB/s
and holding all the way.
- **why this is a real control, not luck:** same machine that died, same
  payload size, and tonight's radio was the **rtw88_8821au — the DELL's
  dongle**, i.e. the other half of the original pair. Two variables
  changed and nothing else: a **throughput cap** (`pv -L`) and **per-path
  granularity** (one `nix-store --export | ssh … --import` at a time,
  missing set recomputed from the target DB each round).
- **it was predicted by #67's own number.** The original finding measured
  ~25 KB/s *sustained* before the drop and called it "the link was
  already collapsing long before the drop". That is a saturation
  signature. Capping below saturation is the direct answer to it.
- **what this changes:** the workaround order in this entry was wrong.
  Sneakernet is NOT needed for these machines. **(a) throttle** is first;
  ethernet remains better where a cable reaches; sneakernet drops to a
  last resort. The offline installer's rationale is unaffected — it
  removes the delivery entirely, which is still the right end state.
- **method, reusable:** cap ~400 KB/s to start, halve on any failure to a
  48 KB/s floor, ease up 25% after 20 consecutive clean paths, 2 s
  between paths, and **ask the database** what is missing (see #85).
- **not yet proven:** the dell itself (double-USB load: dongle *and* USB
  target disk) has not been retried under the throttle. That is the
  honest remaining gap in this finding.

Original finding below. **The dell and the comodore both died mid-`nix copy`**, minutes apart in
behaviour: transfer stalls → `error: write of N bytes: Broken pipe` →
the machine drops OFF the network entirely and does not return (needs a
physical power-cycle).
- **common factor:** both were receiving a ~3 GiB closure over a **USB
  wifi dongle** (dell: rtw88_8821au; comodore: rtl8187). The dell was
  also writing to a USB drive (double USB load); the comodore wrote to
  its internal SATA, so the dongle alone is sufficient to trigger it.
- **the control:** the ASUS took the same 2.93 GiB delivery over its
  **internal** ath9k card and finished clean. So: internal radio fine,
  USB dongle fatal.
- **measured pathology before the comodore's death:** ~25 KB/s
  sustained (188 MB in ~48 min of a 2.95 GiB closure — a ~30 h ETA),
  i.e. the link was already collapsing long before the drop; this is
  not merely "slow old hardware".
- **not a Golem bug** — it is the LAB's delivery method meeting weak
  USB stacks. But it shapes real work: the offline installer exists
  precisely so a machine never needs a 3 GiB network delivery, and
  these two machines are the argument for it.
- **workarounds, in order:** (a) internal NIC/ethernet where one
  exists; (b) **sneakernet** — write the closure to a USB drive from
  the dev box and import locally on the target (no network in the
  path); (c) batched, resumable delivery — one path at a time with
  retries, so drops cost seconds instead of the whole transfer (script
  written this session, unused so far:
  `scratchpad/overnight-copy.sh`).
- **where:** lab method (OPERATIONS-level), plus the offline-installer
  design rationale in implementation.md step 8e.
- **size:** no source change owed. Record + method change.

### 66. The #16 RAM floor refused a PREPARE that never evaluates — the guard fired on the wrong verb — [FIXED 2026-09-11 · ⚠ REOPENED-IN-PART 2026-09-14: the floor's PREMISE is wrong for golem-minimal]
**MEASURED 2026-09-14 on the comodore (1931 MB).** The entry below — and
#16 before it — rests on "a small machine cannot EVALUATE the target
config locally without thrashing". **That is true of the FAT
`golem-target`, which is what it was measured against, and FALSE of
`golem-minimal`:**

| | |
|---|---|
| `rebuild-golem` (`nixos-rebuild switch --flake …#golem-minimal`) | 07:02:28 → **07:05:25**, EXIT=0 |
| peak memory | **~1165 MB** of 1931 |
| **peak swap** | **1 MB** |
| result | generation 2, `running`, 0 failed units |

Under three minutes, 60% of RAM, essentially no swap. No thrash.
- **what is still right:** gating `--prepare-only` / `--skip-prepare` was
  the wrong verb, and that fix stands. A *local-eval install of the fat
  target* on a 2 GB box would still be a bad idea.
- **what is now wrong:** the floor is stated as a property of "installing
  Golem", and its message says *"installing Golem needs about 4 GB of
  RAM"*. On the minimal path that sentence is simply untrue, and it is
  the sentence a stranger will read.
- **why this matters beyond wording:** it means **rule 5's ladder holds on
  the smallest hardware** — stage 1 can reach the comodore by REBUILD
  rather than reinstall, which is exactly what the constitution requires
  and what we could not previously assume. It also removes an argument
  for the offline installer being mandatory on small machines.
- **fix:** make the floor a property of *which config is being evaluated*
  (`golem-minimal` vs `golem-target`), not of the machine alone; and
  re-word the message accordingly. Re-measure the fat target on a small
  box before keeping 3300 for it.
- **where:** `Installer/preinstall/install.nix` (the ram check + its
  message), and #16's original reasoning.
- **size:** small (a config-aware threshold + wording).

*Original entry:*
**Found on the comodore's first real install (1931 MB):** `golem-install
--prepare-only` died at the preflight with *"this machine has 1931 MB —
installing Golem needs about 4 GB of RAM"*, before touching the disk.
- **why it was wrong:** #16's floor exists because a small machine
  cannot EVALUATE the target config locally without thrashing. But
  `--prepare-only` evaluates nothing — it partitions, mounts, seeds and
  drops the target files; the system is BUILT ELSEWHERE and delivered
  (`nix copy` — the closure-delivery seam used since the ASUS, and the
  shape a product stick will use). Same for a `--skip-prepare` resume:
  it activates a closure that already exists. So the check was gating
  the wrong verb — refusing an install that was never going to thrash
  the machine.
- **fix (applied):** the floor now distinguishes `eval_is_local`. A
  local-eval install still hard-FAILS below 3300 MB (unchanged, and a
  rehearsal still records the finding); a delivery-seam run
  (`--prepare-only` / `--skip-prepare`) records an honest **warn** —
  *"below the local-eval floor — fine here: this run does not evaluate
  (the system is built elsewhere and delivered)"* — and proceeds.
  Nothing is silently skipped; checks.txt still tells the truth.
- **why it matters beyond tonight:** this is exactly the distinction
  the OFFLINE INSTALLER needs — "can this machine eval?" vs "can it
  receive a prebuilt system?". Answering it here means the offline work
  inherits a preflight that already asks the right question.
- **where:** `Installer/preinstall/install.nix` (the ram check).
- **size:** done. Live-fixed on the comodore (patched golem-install
  nix-copied onto the running medium — the constitution's live-fix
  refinement, the frozen stick untouched); ships in the next cut.

### 65. Minimal boots to a BLANK console — fbcon=map:1 maps the tty to a framebuffer that doesn't exist — [FOUND + FIXED LIVE on the acer, first metal · 2026-09-10]
**The most important find of the first metal install, and the textbook
minimal-first catch.** The installed acer showed systemd-boot, then a
dead screen — no login ever drew. Max typed the login + `nmcli`
BLINDLY and it worked: the system was fully up and SSH-reachable the
whole time (running, 0 failed units) — only the display was dark.
- **root cause (read-only diagnosis):** `fbcon=map:1` in the kernel
  params (base/core.nix) maps the framebuffer console to fb**1**; the
  acer has only fb0 (`i915drmfb`), so getty@tty1 renders to nowhere.
  The param — plus `splash` — rode in VERBATIM from the fat config,
  where greetd→Hyprland takes the screen through KMS and a mapped-away
  fbcon is invisible-and-harmless. On minimal there is no compositor:
  **fbcon IS the display**, so the same param is invisible-and-FATAL.
- **fix (APPLIED to source + verified live):** drop `fbcon=map:1` and
  `splash` from `base/core.nix`; keep the log-quieting params (quiet,
  not blank). Built the fixed toplevel, updated the acer's seed,
  self-rebuilt `#golem-minimal` → gen 3, rebooted → **Max saw boot
  loader → quiet blank → `login:` → zsh on the acer's own screen.**
  Running kernel has no fbcon=map:1; vtconsole is `(M) frame buffer
  device` not the dummy. The desktop stage (I2) re-adds its own
  clean-boot handoff and should reconsider whether fbcon=map is the
  right mechanism on a single-framebuffer machine at all.
- **where:** `system/Modular/base/core.nix` (done). Ships in the I2 cut.
- **size:** done. The self-rebuild that applied it also proved stage-0
  self-rebuild on metal.

### 64. A lab-installed minimal has no wifi — unreachable for the remote first-boot audit — [FIXED in source 2026-09-11 · --lab-wifi · ships in the I2 cut]
**APPLIED (2026-09-11):** `golem-install` gained `--lab-wifi SSID`,
mirroring `--lab-ssh`. It writes an OPEN NetworkManager profile
(`golem-lab`, autoconnect) into the installed `machine.nix`, so a lab
testbed auto-joins after reboot and is reachable over SSH with NO
keyboard — which is exactly what the dell (broken keyboard: only
e/g/i/Enter/Backspace) forces. Lab-only; a stranger's install gets none
of it (they pick their own wifi). Carries `autoconnect-retries = 0`
(infinite) so a slow driver/AP at boot can't exhaust NM's default 4 —
the cheap half of #63, ridden along here where it's free. `where`:
install.nix (arg + the machine.nix writer, beside the --lab-ssh block).
Original finding below.

The installed stage-0 acer booted healthy but off the network: the
`golem-lab` wifi profile lives on the INSTALLER medium (iso.nix), not
in the installed config, and minimal has no GUI to connect from. Had to
connect it at the keyboard (`nmcli device wifi connect HOLA`) to audit
over SSH. `--lab-ssh` already wires the lab KEY into machine.nix; the
lab needs the same for the lab WIFI so an installed lab machine is
reachable without a keyboard trip.
- **fix (queued):** a `--lab-wifi` that writes the golem-lab profile
  (open, or the baked PSK) into the installed `machine.nix`, gated the
  same way `--lab-ssh` is — lab-only, never on a shipped image
  (GolemSecurity phase 3). A real user connects to their own wifi; this
  is purely a lab-reachability affordance.
- **where:** `Installer/preinstall/install.nix` (arg + the machine.nix
  writer) — mirrors the `--lab-ssh` block.
- **size:** small. Ships in the I2 cut.

### 63. The lab medium sometimes doesn't join the network by itself — [UPGRADED to PREDICTED-AND-OBSERVED 2026-09-14 · still owed its journal · the comodore]
**NEW EVIDENCE (2026-09-14, the comodore's post-install reboot).** The
machine was rebooted at 01:47 and watched until 07:31 — **5 h 45 m, never
appeared on the network.** That silence discriminates between the two
configurations, because they retry differently:
- **installed system** (`machine.nix`, written by `--lab-wifi`):
  `autoconnect-retries = 0` → **infinite**, keeps trying forever.
- **the medium** (`iso.nix` `golem-lab`): **no retries key at all** → NM's
  default **4**, then it gives up and stays silent.

A booted installed Golem with a working radio would have retried all night
and turned up; it did not. A booted MEDIUM goes permanently silent after
four attempts — which is precisely what was observed. So the theory below
now has a **successful prediction** behind it, on one of the two machines
whose hand-bounce was the original real evidence.
- **what is still owed, unchanged:** the captured NM "giving up" journal.
  This is inference from a retry asymmetry, not the log. Do not close the
  finding on it — but the fix is now much better motivated than
  "plausible and cheap".
- **note the asymmetry is itself the smell:** the installed system got
  `retries = 0` for free when #64 landed, while the MEDIUM — the thing
  that has to come up unattended in a lab, with no keyboard, on the
  slowest radios we own — still runs NM's default 4. That is backwards.
- **where (unchanged):** `Installer/preinstall/iso.nix`, the `golem-lab`
  profile — add `"autoconnect-retries" = 0;` beside `autoconnect = true`,
  exactly as `--lab-wifi` already writes for installed machines.
- **size:** one line, and it is now the single most likely reason a lab
  machine goes dark after a reboot.

Original entry below. — [DOWNGRADED to UNCONFIRMED 2026-09-11 · my detection was broken · re-verify before fixing]
**CORRECTION (2026-09-11, the thinkpad sweep):** the thinkpad joined
HOLA on its own, no bounce — and that exposed that my own reachability
checks were the unreliable part: `zsh -c 'echo >/dev/tcp/host/22'` FAILS
UNCONDITIONALLY (zsh has no /dev/tcp; it is a bash-only feature), so
every "not on the network" reading I reported from those sweeps was a
false negative. The "medium doesn't auto-join" narrative was built on a
mix of Max's REAL nmtui bounces (acer + comodore, round 5 — genuine)
and my broken checks reinforcing it. So the finding is NOT dismissed
(Max did have to bounce real machines) but its SCOPE and ROOT CAUSE are
unconfirmed: I never captured the NM "giving up" log I claimed. Method
fixed (ssh/ping/bash only, never zsh /dev/tcp). **Re-verify with a
working check WHICH machines actually fail to auto-join, and capture the
real NM journal, before applying the autoconnect-retries=0 fix below.**
The fix is still plausible and cheap, but it must be earned by evidence,
not by my tooling error.
- **real evidence:** Max DID have to nmtui-bounce the acer and the
  comodore (round 5) — his own hands, not my check. So SOME machines
  don't auto-join. The thinkpad (2026-09-11) did, cleanly. Inconsistent
  across machines — which is itself a clue.
- **original theory (UNCONFIRMED — the plausible fix to earn):**
  `iso.nix`'s `golem-lab` profile sets
  `autoconnect = true` but no `connection.autoconnect-retries`, so it
  takes NM's **default of 4**. When the wifi driver isn't up yet
  (ath10k/ath9k firmware load is seconds) OR the AP/DHCP is momentarily
  busy at boot, NM spends all 4 attempts before the device/router is
  ready and then STOPS trying until a manual `nmcli con up`. Same
  mechanism hit the comodore's WIRED sky2 (NM's default wired profile,
  same default-4 retries, waiting on DHCP) — which is why "slow wifi
  driver" alone never explained it.
- **fix (queued, needs-verify):** set infinite retries so NM keeps
  trying until it gets an address, for BOTH the baked wifi profile and
  the default wired profile:
  - `iso.nix` golem-lab profile: `connection.autoconnect-retries = 0;`
  - global default (covers auto wired): `networking.networkmanager`
    connection defaults — `settings.connection."autoconnect-retries" =
    0;` (NetworkManager.conf `[connection]`).
  - belt-and-suspenders candidate: a `NetworkManager-wait-online`-ordered
    oneshot that `nmcli con up golem-lab` if still down after boot —
    decide whether the retry fix alone suffices first (verify on the
    machine that a giving-up log actually appears).
- **verify:** confirm on the acer's journal that NM logged
  "autoconnect: giving up" (or retries exhausted) at boot BEFORE
  committing the fix as root cause; then prove a rebuilt medium joins
  unattended across a cold boot on the slowest wifi machine (acer/asus).
- **where:** `Installer/preinstall/iso.nix` (the golem-lab profile +
  networkmanager settings). Medium-only — the installed system uses the
  owner's own wifi, but the same retries=0 default is worth carrying
  into `base/network.nix` so a stranger's flaky-AP first boot doesn't
  strand them either (decide at fix time).
- **size:** small (the profile line); the wired/global half + the
  optional nudge need a decision. Ships in the round-I2 cut (no
  mid-round reburn — the acer installs on the current stick with the
  manual bounce).

### 62. The installed minimal seed can't reproduce itself — the engine never dropped modules.nix, and golem-minimal never wired its self-rebuild loop — [FOUND + FIXED in source, pre-ISO · VM stage-0 self-rebuild proof, 2026-09-10]
Caught by round I1's first VM stage-0 install (UEFI, golem-minimal),
exactly by the self-rebuild proof the constitution mandates. Two holes,
both breaking "a stage-0 machine can rebuild itself":
- **the engine dropped no `modules.nix`.** Phase 4 wrote golem-hardware
  / hardware-configuration / machine / postinstall-questions, but the
  chooser wasn't part of the engine — so the installed seed had no
  pointer list, and its `golem-minimal` self-rebuild would evaluate
  base-only (no chosen hardware leaves). **Fix:** `install.nix` phase 4
  now runs the chooser (`nix eval … Modular/choose.nix … .rendered`)
  and drops `hosts/target/modules.nix` into the seed, from the same
  facts it just wrote. A chooser THROW (an unmatchable machine) warns
  rather than blocks — the fat golem-target doesn't need it; a minimal
  install would then fail visibly at its own rebuild with the reason.
- **golem-minimal never set flakeDir/flakeAttr.** It doesn't import
  `hosts/target/default.nix` (which wires the FAT target), so flakeDir
  stayed null → `selfrebuild.nix` emitted no `rebuild-golem`, and the
  machine had no way to rebuild at all. **Fix:** new leaf
  `Modular/base/loop.nix` (flakeDir = /home/owner/Golem, flakeAttr =
  golem-minimal), in the base composition. The machine now reproduces
  the composition it actually runs; stage 1/2 are rebuilds of THIS attr
  with more leaves in modules.nix.
- **proven the same session (UEFI VM):** after both fixes, the installed
  minimal rebuilt itself `#golem-minimal` from its seed → generation 2,
  `is-system-running: running`. The engine's chooser line is verified
  to emit the 7-module list; its LIVE drop is owed on the round-I1 recut
  (this session's stick predates the Modular work, so its seed's
  flake.nix had no golem-minimal — a harness artifact, not a Golem bug).
- **where:** `Installer/preinstall/install.nix` (phase 4),
  `system/Modular/base/loop.nix`, `system/Modular/composition.nix`.
- **size:** done (pre-ISO source fix). Verify the engine's live drop +
  BIOS-minimal install on the round-I1 recut.

## Applied

*(moves here at round close, tagged with the round that shipped it)*
