# Changes — the deferred queue for the next ISO

Every change the current round teaches us to make lands here, and is
applied **only when the round is done** — when the current ISO has cleared
all five laptops (see [constitution.md](constitution.md)). Nothing here is
built into an ISO mid-round; that is what keeps the five machines testing
the same Golem.

## How to use this file

- While testing round N, when a finding implies a fix, add an entry under
  **Queued for the next ISO**. Keep the raw observation in the laptop's own
  file; keep the *change* here.
- When the round closes: work the queue top to bottom, build the new ISO,
  reflash, then move the applied entries to **Applied** with the round they
  shipped in, and empty the queue for the next round.
- An entry names: **what** to change, **why** (which finding/machine),
  **where** (file:location if known), and **size** (small / medium / needs
  a decision from Max).
- **Live-fix refinement (Max, 2026-09-06):** a queued fix may be applied to
  SOURCE and `nix copy`'d onto the booted laptop as a RAM overlay to verify
  it on real hardware — the frozen ISO is not rebuilt, so the discipline
  holds. Mark such entries **[verified live on \<laptop\>]**. The source
  edit is the round-close change staged early; the ISO rebuild still
  happens once, at round close. Re-verify on each laptop's own hardware.

## Queued for the next ISO

### 22. decide.nix crashes on an nvidia machine on the iron-law floor — [fixed in round-3 source, pre-reflash · ASUS verifies on metal]
- **what (ASUS X550LC, round-2 first contact — the audit's FIRST decide
  failure on metal):** with `gpu/gpu2 = nvidia` but `nvidiaGen =
  "unknown"` (GF117M Fermi — below the Maxwell id floor), the iron law
  correctly keeps nvidia OUT of videoDrivers. But decide.nix's nvidia
  rows read `hardware.nvidia.open` / `.prime.offload.enable` / etc.
  regardless — and with the driver inactive the upstream nvidia module's
  internal package is null, so evaluating those options dies:
  `expected a set but found null`. The whole decision surface crashes;
  `status: FAILED at: golem-hw-decide`; decision.json never written.
  No prior lab machine had an nvidia GPU, so the trap sat unfired — and
  the just-gated round-3 build carried the same reads (now keyed on
  gpu2), so first contact caught it hours before the reflash.
- **proof of the boundary:** the same machine's target EVAL passes
  (rehearsal ok, 30 s) — the floor config never reads nv.*; only the
  row rendering did.
- **fix (applied):** the nv.* rows render only when `"nvidia"` is in
  `services.xserver.videoDrivers`; otherwise one honest row:
  `kernel module: none — open floor (modesetting/nouveau)`.
- **also, downstream surface gap — [applied to source · round 3]:**
  with decision.json missing, the confirm screen silently showed NO
  decision rows. Now: if the audit's status file exists but the
  decisions are unreadable, one dim line — "audit incomplete — the
  decisions could not be shown" (`audit_bad`, 6 languages). Dev boxes
  (no audit at all) stay silent as before.
- **where:** `system/hardware/decide.nix` (nvidia rows); the surface
  gap: `mockup/install-cli` census_reveal.

### 21. The reveal picks the WRONG one of several same-class devices — [applied to source · round 3 ("all in" — Max) · ThinkPad verifies on metal]
**Applied:** audio row prefers the non-HDMI audio device (audio_row —
unit-tested on the ThinkPad's exact device list: picks Family 17h HD
Audio); touchpad row goes two-tier — explicit pad names first, vendor
names as fallback — so the TrackPoint no longer shadows the pad.
- **what (ThinkPad E15, round-2 first contact):** two instances of one
  class — "first match wins" is wrong when a machine has several devices
  of a kind:
  a. **Audio row names the HDMI audio, not the speakers.** AMD APUs
     expose two audio-class PCI functions (04:00.1 "Renoir/Cezanne
     HDMI/DP Audio" + 04:00.6 "Family 17h HD Audio" — the actual
     speakers/mic); `hw_pci 'Audio device|…'` takes the first. Prefer
     the non-HDMI device (name-filter out HDMI/DP) or show both.
     **Also (Max, on the physical screen):** the row reads "AMD/ATI …
     · snd_hda_intel" — a perceived vendor mismatch. It is CORRECT
     (HDA is the Intel-authored audio standard; the module drives
     every vendor's HDA controller and its name is historical), and
     the module name is the proof, so do not rename it — but the
     rework here is the place to reconsider if it keeps confusing.
  b. **Touchpad row names the TrackPoint.** A ThinkPad carries both
     ("ETPS/2 Elantech TrackPoint" AND a touchpad); `hw_input` returns
     the first /proc match, so the row is labeled Touchpad but names the
     stick, and the real touchpad is unshown. Prefer a name actually
     matching pad patterns over TrackPoint, or show both rows.
- **why:** round 2, ThinkPad — the reveal's one-device-per-class
  assumption met its first machine with real duplicates (same family as
  #9's two GPUs, now solved by hw_pci_all).
- **where:** `mockup/install-cli` `hardware_reveal` (audio row filter,
  hw_input ordering).
- **size:** small.

### 29. Fingerprint reader missing from the reveal — and Max wants it shown "working" — [DECIDED direction (Max, round 3 HP) · round 4]
- **what (HP dm4, round 3):** the HP has a fingerprint reader; the
  reveal showed NO fingerprint row. **Investigated (RAM-swap reboot):
  the reader does NOT enumerate** — absent from lsusb, lsusb -t, PCI,
  and there is no kernel trace of any Validity/AuthenTec chip and no
  failed-enumeration error. It is present physically but dark to the
  OS: BIOS-disabled (HP dm4 Security toggle) or dead. So the reveal is
  NOT at fault here — nothing to detect. NOTE for the #29 build: this
  HP is a bad "working"-verdict demo even once BIOS-enabled — dm4
  readers are typically old Validity VFS, which libfprint supports
  poorly. It's the machine that would PROVE the honesty gate: detect =
  yes, "working" = only if libfprint backs the specific id. Get a
  DIFFERENT machine with a supported reader (Goodix 27c6 on modern
  ThinkPad/Framework) to demo the happy "working" path.
- **Max's direction:** "that is the kind of hardware i want to see on
  the items and i think will be good if it says 'working'." Fingerprint
  (and this class of "Linux won't do this" hardware) is a morale win —
  same spirit as the GPU verdict rows (#17). Show it, and affirm it.
- **the honesty wrinkle [needs-Max on wording]:** unlike the GPU (which
  we WAKE-TEST), a fingerprint reader we can only detect as PRESENT.
  Many readers — Validity/Synaptics especially — are present but
  UNSUPPORTED by libfprint (no working driver). A blanket "working"
  would occasionally be the exact false promise Golem exists to kill.
  Proposal: check the reader's USB id against libfprint's supported
  device list; say "tested, working" (or "supported") ONLY when it is
  actually backed, and something honest-but-not-damning otherwise (or,
  per #17's silence rule, just the name). Decide the two strings when
  the HP is back and we know its reader.
- **where:** `system/hardware-detect.nix` (widen the fingerprint probe
  if the id was missed), `mockup/install-cli` (a fingerprint row with a
  verdict, libfprint-support gated).
- **size:** small–medium; wording needs-Max.

### 28. The boot audit dumps its census to tty1 and RACES golem-setup — [round 4, important]
- **what (MacBook, round 3, Max's photo):** on a slow machine the boot
  audit takes ~60 s (this boot: 26.8→86.9 s on 3.8 GB). `golem-audit-
  start` prints its full census table to `/dev/tty1` when it FINISHES
  ("say so on the console" step, guarded only by `-w /dev/tty1` +
  decision.json non-empty). Auto-login lands early, Max started
  golem-setup before the audit finished → TWO symptoms, one cause:
  a. the confirm reveal drew while decision.json didn't exist yet →
     "audit incomplete — the decisions could not be shown" (#22's line,
     here literally TRUE — not the ASUS crash, just not-done-yet);
  b. at ~87 s the audit finished and dumped its census onto tty1 OVER
     the confirm screen, staircase-scattered (plain `\n` to the raw
     console golem-setup owns) — the garbled screen in the photo.
- **fix (two halves):**
  1. **the collision:** the audit's console print must not fire while
     golem-setup owns the screen. Cleanest: golem-setup drops
     `/run/golem-setup.owns-console`; the audit's tty1 step skips if it
     exists. (Or the audit prints to console only before getty, via
     systemd ordering.)
  2. **the wait:** golem-setup's confirm reveal should WAIT for the
     audit (`status: ok`) before drawing — it already has CENSUS_SECONDS
     / census_line for the keyboard step; the reveal reads decision.json
     directly and does not wait. Then distinguish "still running" (wait)
     from "failed" (the #22 audit_bad line, the ASUS case).
- **where:** the audit unit (`Installer/audit.nix` console step),
  `mockup/install-cli` (reveal wait + the marker file).
- **size:** medium. Frozen round-3 stick keeps the race.

### 27. The driver-count line is GONE from the surface — [DECIDED (Max, round 3, Comodore) · applied to source · round-4 build]
- **what:** "25 of 26 (96%) drivers will be installed" — Max, seeing it:
  a stranger fixates on the missing ONE ("i need that one to be
  complete!"), googles it, starts tinkering, breaks Golem. And the lab
  data says the missing ones are never real: ThinkPad = IOMMU +
  a by-design-declining ACP; Comodore = the #26 phantom sibling
  function. The score graded a test whose missing points don't exist
  as hardware.
- **DECIDED: drop the line.** The hardware rows (name · driver) ARE the
  proof; Golem does not grade itself. The probe still runs (numbers in
  $DRV_FILE for a lab hand); drv_line/drv_ing/drv_none strings stay in
  the table, unused, in case the number ever returns to the AUDIT.
- **downstream:** #25 (IOMMU exclusion) and #10's wording caveat are
  now surface-moot — keep #25 only if the count ever surfaces again.

### 26. A same-chip sibling function enumerates as a second GPU — [round 4, concrete]
- **what (Comodore, round 3):** the GMA 4500 exposes 00:02.0 (VGA,
  boot_vga) AND 00:02.1 (a second display-class function of the SAME
  chip). The census's PCI 0x03* enumeration reports it as
  `gpu2 = "intel"`, health-probes it (reads "working", stably), and
  the reveal fibs a "GPU 2 … tested, working · apps can use it on
  demand" row — a driverless dead sibling of the machine's ONLY GPU
  wearing the offload promise. Config impact: none (intel + working
  activates nothing). Surface honesty: real.
- **fix:** exclude display-class functions sharing the primary's PCI
  SLOT from gpu2 (same rule as #21c's GPU-adjacent audio: a .N sibling
  function is the same silicon, not a second device).
- **where:** `system/hardware-detect.nix` (the gpu2 pick),
  `mockup/install-cli` reveal follows the facts.
- **size:** small.

### 25. The driver count still holds one phantom class: the IOMMU — [round 4, small]
- **what (ThinkPad round 3, chased on a dedicated boot after Max asked
  why 89%):** the 2 driverless of 19 are (a) `00:00.2` the AMD IOMMU
  function (class 0806) — which NEVER shows "Kernel driver in use" on
  any OS, AMD-Vi is core kernel, same phantom-denominator class as the
  bridges #10 excluded — and (b) `04:00.5` the ACP audio co-processor,
  whose driver loads and DECLINES by design because this unit's mic is
  wired through the ALC257 HDA codec (capture stream verified present —
  the mic works; the ACP is dormant silicon).
- **fix:** exclude class 0806 (IOMMU) from the count like 06xx bridges
  → ThinkPad reads 17/18 (94%). The declined-by-design ACP cannot be
  genericized away (a declining driver is indistinguishable from a
  missing one by class); 94% honest beats 100% clever.
- **where:** `mockup/install-cli` `probe_compute` (the class filter).

### 21c. The audio row's HDMI filter misses Intel's naming — [round 4, concrete]
- **what (Acer round 3; ASUS retroactively):** #21a excludes audio
  devices with "HDMI" in the name — but Intel's GPU-audio functions are
  named "Broadwell-U Audio Controller" / "Haswell-ULT HD Audio
  Controller" (00:03.0), no HDMI anywhere, so the row still shows the
  monitor-audio function instead of the speakers (Wildcat Point-LP /
  8 Series at 00:1b.0).
- **fix:** filter by TOPOLOGY, not names: exclude audio functions that
  share a PCI slot with a display controller (ThinkPad 04:00.1, HP
  01:00.1) or sit at 00:03.0 beside an Intel iGPU at 00:02.0 (the
  pre-Skylake pattern); prefer what remains. hw_pci_all already carries
  the bus ids.
- **where:** `mockup/install-cli` `audio_row`.
- **size:** small.

### 24. Encryption says "password", not "passphrase" — [DECIDED (Max, round 3 visual review) · applied to source · round-4 build]
- **what:** every LUKS surface string used "passphrase" — jargon, and a
  different word than the account screen's "password" for what a
  stranger experiences as the same kind of secret. Max, reviewing the
  ASUS round-3 visual: "lets use password instead."
- **applied:** all 6 languages, with gender agreement where the word
  changes it (fr: mot de passe → masculine "demandé"; de: das Passwort
  → "wer es vergisst"). es contraseña / it password / pt palavra-passe
  now match each language's account-password word. Also fixed a stray
  backtick in fr:p_lpass ("l`oubliez" → "l’oubliez"). Code comments
  keep "passphrase" (developer-facing, technically precise).
- **note:** the frozen round-3 stick still says passphrase; the change
  rides the round-4 build.

### 23. Health probe must FORCE the dGPU cold before every poke — [QUEUED round 4 · DECIDED approach (Max, HP round 3): force-cold]
**The fix, decided:** before EACH poke, set `power/control = auto`, wait
(bounded ~10 s) for `runtime_status = suspended`, then `echo on` and scan
the kernel log at the device address. Won't-suspend-in-bound → `unknown`
(unspoken), never a default "working". This replaces the passive
wait-before-retry; the HP's false positive proved passive isn't enough.
The HP is the round-4 proof machine for the whole failing→powered-off
path (gpu-second.nix has still never run from a real verdict on metal).
Detail and evidence below.
- **what (ASUS, round 3 machine 1 — predicted by the round-2 preview,
  caught live by the facts-match check):** the boot audit ran the probe
  while the dGPU was still awake from init → vacuously clean poke →
  `gpu2Health = "working"`. The rehearsal's re-probe minutes later met
  a long-suspended chip → real cold resume faults, real retry (bounded
  wait worked), faults again → `failing`. checks.txt flagged the flap:
  `warn facts: … working → failing` — the instability instrument's
  first real catch.
- **two consequences, one cause:**
  a. **verdict flap across boots** — fix: before the FIRST poke, wait
     (same bounded 10 s) for `runtime_status = suspended`; a chip that
     never suspends is genuinely awake and a clean poke then is honest.
  b. **reveal/target skew THIS boot:** the confirm screen promised
     "apps can use it on demand" (boot facts) while the evaluated
     target powers the chip off (install-time facts — the rehearsal
     evals the RE-PROBED facts, which is the safer of the two).
- **silver lining:** the failing branch is REAL now — this boot was
  gpu-second.nix's first evaluation inside an actual target (eval ok,
  30 s).
- **STRONGER MANIFESTATION (HP dm4, round 3) — a FALSE POSITIVE, worse
  than a flap:** the HP's Evergreen radeon read `working` on BOTH the
  boot audit AND the rehearsal reprobe → facts-match `ok` (falsely
  reassuring) → reveal promised "apps can use it on demand" for a chip
  that fails EVERY resume. Proven same boot: forced to a genuine
  suspended state then cold-resumed, it threw the exact round-2
  signature (`No VRAM object for PCIE GART` + `evergreen startup failed
  on resume`, 2 errors). Neither probe caught it because the poke
  didn't guarantee a COLD resume (chip already awake from init / prior
  lspci pokes → `echo on` is a no-op → 0 errors → latched "working",
  no retry). Passive waiting isn't enough either: at boot the chip may
  not autosuspend within the bound.
- **REVISED FIX (the HP sharpens it): FORCE cold before every poke.**
  Set `power/control = auto`, wait (bounded) for `runtime_status =
  suspended`, THEN `echo on` and scan. If it will not suspend within
  the bound, the cold-resume path is untestable → `unknown`
  (unspoken), never a default "working". This replaces the passive
  "wait before the retry" with an active force-cold before poke 1 —
  the only version that catches the HP.
- **gap this leaves for round 4:** the FAILING→powered-off path
  (gpu-second.nix) has still NEVER triggered on real metal from a real
  failing verdict — only from a fixture eval. The HP with the revised
  probe is the machine that finally exercises it end to end.
- **where:** `system/hardware-detect.nix` (the gpu2 health probe —
  force-cold before poke 1).
- **size:** small (logic), but load-bearing for #17c's whole promise.

### 20b. …and the round-3 fix has a SECOND failure mode — [round 4]
- **what (ASUS, round 3 machine 1):** the #20 fix chases `/iso` — but a
  USB isohybrid mounts from the WHOLE DISK (`findmnt` says `/dev/sdb`,
  no partition), whose own PKNAME row is EMPTY, and `head -1` grabs that
  empty line → `boot=""` → the stick is offered again. The VM gate
  could not see it (its medium is sr0, name-filtered before the PKNAME
  path runs). The engine's target≠medium check handles the same shape
  correctly (falls back to the source device) and still backstops.
- **fix:** take the first NON-empty PKNAME (`grep -m1 .`), and when
  there is none and the source is a /dev node, use the node itself
  (`boot=''${src##*/}`) — the engine check's exact recipe.
- **where:** `mockup/install-cli` `disk_load`.
- **size:** small. Frozen round-3 stick keeps the flaw; the engine
  check guards the gap for the round.

### 20. The drive list offered the boot stick itself — [applied to source · round 3]
**2nd on-metal instance (ThinkPad, round-2 first contact):** "USB 2.0
FD 14.4G" offered again on the frozen stick — as expected; the round-3
build carries the /iso-based fix.
- **what (Dell round 2 → understood during the round-3 close):** the disk
  step's "never a target" filter chases the disk behind `/` — but on the
  medium the live root is a TMPFS, so the filter resolved nothing and
  excluded nothing: the Dell's list offered "USB 2.0 FD 14.4G", the very
  stick it booted from, under a header that says everything on it will be
  erased. (The round-2 dell.md called it "likely by design" — the comment
  right above the code says the opposite.) The engine's target≠medium
  check was the only thing standing between a stranger and eating the
  installer mid-install.
- **fix:** resolve the medium via `/iso` first (same source the engine's
  own check reads), fall back to `/` for the dev-box case.
- **where:** `mockup/install-cli` `disk_load`.

### 19. Engine dies SILENTLY when the BIOS target disk has no by-id alias — [applied to source · round 3 · VM gate re-proves it]
- **what (VM, round 2, 2026-09-07 — machine zero's first catch):** on the
  BIOS branch the engine resolves the target disk to its stable name:
  `disk_byid=$(for l in /dev/disk/by-id/*; do [[ "$(readlink -f "$l")" ==
  "$disk" ]] && { echo "$l"; break; }; done)` (golem-install ~494, inside
  the machine.nix heredoc block). When NO by-id entry resolves to the
  disk, the loop's last status is the failed `[[ ]]` guard → the command
  substitution returns 1 → **`set -o errexit` kills the engine at the
  assignment** — one line BEFORE its own fallback (`[[ -n "$disk_byid" ]]
  || disk_byid="$disk"`) can run. Death is mid-step-4, mid-file: no
  check_fail, no eval.err, no status file, machine.nix truncated; the TUI
  can only say "the installation stopped — the log is above" and the log
  above says nothing. Minimal repro proven on the guest; also reproduced
  end-to-end twice (Max's TUI run + a direct `golem-install --rehearse`).
- **why the laptops never saw it:** every SATA disk has an `ata-…` by-id
  entry, and UEFI machines skip the branch. The VM's virtio disk had no
  serial → no by-id entry → first machine to walk the branch bare. Real
  hardware can get here too (odd USB bridges expose no usable by-id).
- **fix, two parts:**
  a. **the line:** restructure to an errexit-safe `if` loop
     (`for l in …; do if [[ … ]]; then disk_byid="$l"; break; fi; done`)
     so the existing fallback finally gets to do its job. Also mind the
     empty-glob case (`/dev/disk/by-id/*` unmatched → literal string —
     same death).
  b. **the class [approach OK'd (Max, 2026-09-07)]:** a silently dying
     engine is the real bug — ANY future errexit death shows the same
     blank "stopped". Add an ERR/EXIT trap that prints the failing line
     to stderr and writes `status: error` + a trace file, so the TUI's
     "the log is above" is never again pointing at nothing.
- **rig note:** run-vm.sh now passes `serial=golemtarget` so the VM disk
  has a by-id alias like real hardware — the frozen round-2 ISO works in
  the VM again. Flip the serial off once in round 3 to verify fix (a).
- **where:** `install.nix` (the golem-install disk_byid line, ~494 in the
  built script; + the trap), `Installer/run-vm.sh` (done).
- **size:** (a) small; (b) small-medium, wants Max's nod on the shape.

### 18. English leaks in a translated run — [applied to source · round 3 — a, b, c, d AND e]
- **what (HP, round 2, Spanish run):** three strings render English on an
  otherwise fully-Spanish surface, each for a different structural reason
  (none is a missing translation — `S[es:drv_line]` is on the stick):
  a. **driver count pre-rendered at boot:** `probe_start` backgrounds
     `probe_compute > $DRV_FILE` at startup, and probe_compute renders
     `t drv_line` right then — `UI` is still `en`. The confirm screen cats
     the cache. **Fix:** cache the NUMBERS (`have total`), render the
     translated sentence at display time in `driver_count`.
  b. **engine emits label text, not a key:** `##golem 5/6 evaluating the
     system` (install.nix:603) carries literal English through the
     protocol; step_go prints it verbatim. **Fix:** emit a phase key (or
     just the fraction) and let step_go map phase → `t` string.
  c. **rehearsed outcome hardcoded:** `rehearsed — nothing was written,
     no findings` / `… %s finding(s)` are raw printfs
     (install-cli:3171/3173), not in the string table. **Fix:** move both
     into `S[...]` + translate the 6 languages.
- **also, same family:**
  d. **R3-3's LUKS strings are English-only** (`luks_warn`, `luks_ack`,
     `erased_enc`, `e_lcpass`, `t_lcpass` — key-diff vs en). The scare
     screen is the one place translation is SAFETY, not polish: a Spanish
     stranger must be scared in Spanish. Add es/fr/de/it/pt.
  e. **[DECIDED (Max, 2026-09-07): keys at display time]** decision-row
     VALUES (`Zram 150% of ram…`, `Lid Suspend-then-hibernate`) are
     audit-time English from decide.nix. Fix like a–b: decide.nix emits
     stable keys/structured values, the surface maps key → translated
     string at render time. Joins a–d as concrete round-3 work.
- **why:** round 2, HP — Max's photo of the Spanish console; reproduced
  and traced over SSH same day (hp.md third follow-up).
- **where:** `mockup/install-cli` (probe_compute/driver_count, step_go,
  the rehearsed arm, string table), `install.nix:603`.
- **size:** a–d small; e needs-Max.

### 17. Muxless AMD hybrid — dGPU failing/spamming, census picks the wrong GPU — [DECIDED · b/c/wording applied to source, round 3 — verify on HP (failing path) + Lenovo (working path)]
**Round-3 close (2026-09-07):** all parts are now in source. b: census
enumerates PCI display class (not drm — a driverless dGPU has no drm
card), primary by `boot_vga`, second GPU emitted as `gpu2` +
`gpu2BusAddr`. c: the wake test from the prototype runs in
golem-hw-detect (forced runtime resume, kernel-log scan at the device's
address, reproducing retry; verdicts working / failing / unspoken);
`gpu2Health=working` + nvidia → PRIME offload via gpu-nvidia.nix;
`failing` → new `gpu-second.nix` powers the chip off (vgaswitcheroo OFF
+ PCI remove, never the boot_vga card). Wording: `reveal_gpus` renders
primary-first verdict rows with `gpu_short` names (all four approved
renders reproduce byte-for-byte); strings in all 6 languages.
- **what (HP Pavilion dm4, round 2):** the kernel spams
  `radeon 0000:01:00.0: No VRAM object for PCIE GART` +
  `evergreen startup failed on resume`, repeatedly, over the installer
  console. Diagnosis: it's a MUXLESS hybrid — card0 i915 `enabled=1` drives
  the display; card1 radeon `enabled=0`, runtime `suspended`;
  vgaswitcheroo shows `IGD:+:Pwr` (Intel active) / `DIS: :DynOff` (AMD off).
  Something keeps runtime-resuming the sleeping AMD Evergreen dGPU, the
  resume fails, it re-suspends, repeat → console flood. **The display is
  fine (Intel); the machine is not broken.**
- **it corrects the reveal:** "AMD … · radeon" is bound but NOT functional
  (dGPU off, can't resume). And the census `gpu = "amd"` is the wrong
  PRIMARY here — the priority nvidia>amd>intel picks the discrete GPU, but
  the ENABLED/display GPU is the Intel iGPU. On a muxless hybrid the
  `enabled=1` card is the real primary.
- **DECIDED (Max, 2026-09-07) — health-gated, not blanket:** "we can not
  have Golem leaving all dedicated GPUs out." Three parts:
  a. **[applied to source · mechanism verified live on HP · round 3]**
     quiet the kernel console so the reveal isn't buried in radeon
     errors. Two layers: `boot.consoleLogLevel = 3` on the medium
     (iso.nix — covers boot-to-attract) and `dmesg -n 3` when install-cli
     takes the screen (root on a real VT only, so terminal demos and SSH
     drives stay hands-off; util-linux already in setup.nix inputs).
     **A/B-proven on the HP over SSH (2026-09-07):** at the default
     loglevel 4 a poked radeon error painted onto tty1 (read back via
     `/dev/vcs1` — the photo's behavior, on demand); at loglevel 3 the
     same poke logged to dmesg and nothing reached the screen. The
     frozen stick is unchanged; the HP's loglevel was restored to 4
     after the test so round-2 behavior stays frozen. Errors keep
     dmesg + journal.
     **Second on-metal instance (Dell, round 2, 2026-09-07):** the
     Dell's dead ME paints `mei mei0: … timeout` / `disabling the
     device` onto the attract screen (Max's photo) — different driver,
     same class. Both lines are priority `err` (= level 3), which
     `consoleLogLevel = 3` suppresses. The fix covers it as-is.
     **Third instance (ASUS X550LC, round 2, 2026-09-07) — A/B-PROVEN
     on metal:** nouveau MMIO PRIVRING faults from the GF117M dGPU over
     the attract screen (Max's photo) — sporadic, at the dGPU's own
     address, verified `kern :err` via dmesg -x. At loglevel 3 a forced
     dGPU resume threw the same fault and tty1 stayed byte-identical;
     loglevel restored to 4 after. Three drivers (mei, radeon, nouveau)
     across three machines: the class is broad, the fix keeps holding.
  b. **[DECIDED]** reveal + census: the PRIMARY GPU is the enabled one
     driving the display (`/sys/class/drm/card*/device/enable` +
     vgaswitcheroo) — here intel; the dGPU shows as a **second GPU row**,
     never silently dropped (the sticker on the lid stays honest).
  c. **[DECIDED]** per-dGPU HEALTH TEST during the boot audit: actively
     wake the dGPU (runtime-PM resume) and watch its PCI address for
     resume/startup errors. The medium carries full firmware (round-2
     correction), so a failure is the chip, not the stick. **Passes →
     configure it properly as a usable second GPU (render-offload). Fails
     (like the HP's Evergreen) → power it OFF and keep it quiet** — no
     spam, no wake-attempt battery drain. Safe test: worst case is one
     more of the errors it already prints.
  - **PROTOTYPED AND PROVEN BOTH WAYS (2026-09-07,
    `fixtures/tools/gpu-health-probe`):** the same script ran on the HP
    (radeon: wake → 2 kernel errors → **FAILING**) and on Max's dev
    laptop, an Iris Xe + RTX 4050 hybrid (nvidia: wake from suspended →
    functional, 0 errors → **HEALTHY**). Two design facts it surfaced,
    binding on the real implementation:
    1. **Primary pick = `boot_vga`, not `enable`** — a healthy offload
       dGPU also reads enable=1 (dev box); only boot_vga singles out the
       display GPU on both machines.
    2. **`runtime_status` lies after a failed resume** — the HP reported
       `suspended → active` even though the driver's startup failed. The
       kernel-log error scan at the device's address is the load-bearing
       check; a functional device-open (what nvidia-smi does) is an even
       stronger healthy signal than a power-state poke.
    3. **The retry is only real if the device RE-SUSPENDS between
       pokes** (ASUS X550LC preview, 2026-09-07): back-to-back, poke 2
       finds the chip still awake and reads 0 errors — so a
       faults-on-cold-resume chip lands "unspoken", not "failing".
       **FIXED (round 3, "all in" — Max):** the probe now waits up to
       10 s (bounded) for `runtime_status = suspended` before the
       retry, so a retry is a real cold resume. A chip that stays
       awake past the bound keeps the single-flake silence. Expected
       effect on the ASUS: if its cold resume faults reproducibly, the
       verdict moves from unspoken to FAILING → dGPU powered off —
       round 3 on that metal decides.
  - **Lab coverage:** FAIL path proven on the HP; HEALTHY path proven on
    the dev box (NVIDIA, prototype only — not a lab machine). Max is
    bringing an AMD-dGPU laptop for the lab (2026-09-07), which would
    prove the healthy path on lab metal and on the amdgpu/radeon side.
  - **SURFACE WORDING (DECIDED, Max, 2026-09-07) — observation + what it
    means for the user; never a hardware judgment, never a prohibition:**
    - **FINAL (Max, 2026-09-07) — asymmetric on purpose:** good news
      gets the promise clause, bad news gets brevity.
      - working dGPU: **`tested, working · apps can use it on demand`**
        — "tested" next to a GPU is the moment no other installer gives
        a Linux user; and it promises USE, not just detection.
      - dead dGPU: **`tested, didn't wake up`** — terse; the consequence
        is self-evident. Shows NO driver name (nothing drives a sleeping
        chip; `· radeon` next to "didn't wake up" would contradict it).
      - the PRIMARY GPU row carries a verdict too: **`tested, working ·
        driving this screen`** (approved) — the strongest proof there
        is; you're reading its output. Approved reference render, both
        machines:
        ```
        ·  GPU     Intel Iris Xe Graphics · i915 — tested, working · driving this screen
        ·  GPU 2   NVIDIA GeForce RTX 4050 Max-Q · nvidia — tested, working · apps can use it on demand

        ·  GPU     Intel Core Processor Graphics · i915 — tested, working · driving this screen
        ·  GPU 2   AMD/ATI Radeon HD 6370M — tested, didn't wake up
        ```
      - **implementation note:** GPU rows use a SHORTENED name (the full
        lspci string — "Intel Corporation Core Processor Integrated
        Graphics Controller" — is 55 chars before the verdict starts and
        pushes it off an 80-col console). Strip "Corporation"/bracket
        noise so the verdict always fits the line. **2nd evidence
        (ThinkPad, round 2): the Renoir string wraps even a 120-col
        tmux pane** — `· amdgpu` landed on the next line with no verdict
        involved at all; gpu_short renders it "AMD/ATI Renoir".
      - vetoed on the way, with reasons (do not re-litigate in round 4):
        "unhealthy" (silicon diagnosis we can't perfect — BIOS
        modes/driver bugs mimic dead chips); "Golem keeps it off" (OS
        confiscating hardware); "keeps Golem stable" (names instability
        → plants it); "unsupported" (a claim about GOLEM, not the chip —
        feeds the exact Linux-GPU trauma we're flipping, and is
        contestable since radeon does support the chip).
    - unclear (ambiguous evidence, single flake, odd states): **say
      nothing** — no annotation, conservative config, raw evidence into
      the audit bundle. Silence is reserved for the gray zone only.
    - **verdict discipline:** three-way (working / didn't-wake /
      unclear); didn't-wake requires a strict known-fatal error signature
      at the device's own PCI address AND a reproducing retry — the HP
      showed the polite signals lie (`runtime_status` read active after
      a failed resume), so only the error log convicts. Both surface
      strings go through the string table in all 6 languages (#18
      discipline).
- **where:** `system/hardware-detect.nix` (hybrid-aware gpu pick),
  `system/hardware/` (dGPU power-off), `iso.nix`/audit (console loglevel).

### 16. Very-low-RAM machines can't run the local install eval — [DECIDED · applied to source, round 3 — Comodore verifies on metal]
**DECIDED:** option (b)'s refusal half, now: a RAM preflight before the
eval — "this machine has N MB; installing Golem needs about **4 GB** of
RAM" (figure per Max, 2026-09-07) — instead of thrashing into an
unresponsive box.
- **Message vs cutoff:** the message speaks sticker-language (4 GB); the
  CHECK refuses below ~3300 MB, because a sticker-4 GB machine never
  reports 4096 to the kernel — the lab's 4 GB-class boxes read 3718–3833
  MB and ALL passed their evals (31–171 s). 3300 sits above the Comodore's
  1931 / any sticker-2-or-3 GB box, below the lowest proven pass (3718).
- **Placement (Max, 2026-09-07 — keep low-RAM machines testable):** a
  REHEARSAL check in the checks.txt family (like round 1's UEFI check),
  NOT a lockout at golem-setup launch. All six screens still walk; the
  rehearsal reports `FAIL ram: …` as a finding and **skips the eval** —
  the thrash never starts, the machine stays responsive, everything else
  still gets exercised. Only a REAL install refuses outright. So the
  Comodore remains a full lab participant, and its round-3 rehearsal
  becomes the test of the refusal itself.
- The prebuilt-closure path (option a) stays a ROUND-4 decision; the
  preflight doesn't foreclose it, it makes low RAM fail honestly today.
- **what:** on ~2 GB the boot census runs (barely) but `golem-install`
  itself makes the machine unresponsive — not only the target eval, even
  the early `nix eval` (swap rule) + seed copy thrash it into a swap spiral
  (Comodore 1931 MB, round 2; Dell at 1.8 GB in round 1 same). A LOCAL
  eval/build install is not viable below ~2–3 GB.
- **why:** reinforces the closure-delivery open question (PLAN.md's biggest
  item). Options: (a) deliver a PREBUILT closure and skip local evaluation
  entirely on such machines; (b) have the installer detect very-low-RAM up
  front and either refuse with a clear message or switch to a
  no-local-eval path, rather than thrash into an unresponsive box; (c)
  accept ~2 GB as below the supported floor and say so.
- **where:** install strategy (closure delivery) + a RAM preflight in
  `install.nix` / the surface.
- **size:** NEEDS-MAX — ties into the closure-delivery decision (round 4).

### R3-1. Touchpad reveal row had no driver — [applied to source · verified on Acer · round 3]
- **what:** every reveal row reads "name · driver" except the touchpad,
  which showed only the name (Max, round 2). `hw_input` returned just the
  /proc Name; now it also reads the block's `S: Sysfs=` path and walks UP
  it to the bound kernel driver. Acer touchpad now reads
  `SYN1B81:01 06CB:2970 Touchpad · hid-multitouch`.
- **also fixed a bug in the doing:** the parse used `exit` on match, and
  awk's exit runs END with the vars still set — the SAME double-print trap
  hw_pci hit in round 1 — which corrupted `$sysfs` and hid the driver.
  Now a `found` flag, no exit.
- **where:** `mockup/install-cli` `hw_input`.

### R3-3. Encryption was too easy to enable by accident — [applied to source · verified live on Acer · round 3]
Max drove the LUKS flow (round 2) and it let a stranger walk into
irreversible data loss too easily. Made it deliberately hard, all verified
live on the Acer (`mockup/install-cli`):
- **passphrase typed twice** (`step_luks`): confirm field + mismatch retry.
  The one secret with no recovery gets the same gate as the account
  password, even though it's shown in the clear.
- **a full-screen red warning** after confirmation — "asked EVERY time …
  no recovery … lost forever" — that must be acknowledged; ESC turns
  encryption off (`luks_warn` / `luks_ack` strings).
- **state reads `LOCKED`** (was "on"), in the danger colour, on the
  Advanced row and the summary item (translated: BLOQUEADO / VERROUILLÉ /
  GESPERRT / BLOCCATO).
- **default selection returns to Back** after enabling (`seed_row=3`), so
  the person sees "— LOCKED" and one ENTER returns to the drive list.
- **disk summary reads "(Will be erased and encrypted)"** when on
  (`erased_enc` string).
- **why:** Max — "we don't want people to use encryption if they don't
  know what that is … they can lose data. so scare them." LOCKED (not
  "on") tells the truth without lying about what it costs.

### R3-2. zram row shows a confusing percentage — [applied to source · verified · round 3]
- **what:** the zram row read "150% of ram". Interpolating the real RAM
  ("150% of 3833 MB") made it WORSE, not better: the % is RAM-tiered and
  EXCEEDS 100% on small machines (1 GB → 150% → a 1.5 GiB device, which
  looks impossible until you know zram is compressed), and even "50% of
  8 GB" is misread as "am I losing half my RAM / do they only see half?".
  **Decision (Max, round 2): show no number — just `active`.** A number a
  stranger will misread is worse than no number.
- **now reads:** `zram   active, zstd, priority 100` on every machine.
- **where:** `system/hardware/decide.nix` (the ram section's zram row).


### 1. Hardware reveal shows only the last PCI device — [applied to source · verified live on Acer + MacBook]
- **what:** rewrite `hw_pci` so it captures the FIRST device matching the
  class and strips the "busid class:" prefix. `lspci -k` has no blank lines
  between devices, so the current awk (which prints a device only at a
  blank line, else at `END`) keeps just the last PCI device — Wi-Fi — and
  drops GPU/audio. It also mis-strips the name (bus id has a colon), so
  Wi-Fi rendered as "03:00.0 Network controller: …".
- **why:** round 1, Acer — Max: "why there is not GPU, audio, etc.. only
  WIFI, and touchpad." The reveal is meant to name GPU/Wi-Fi/audio/etc.
- **where:** `mockup/install-cli` `hw_pci()` (~line 2739).
- **verified fix** (against the Acer's real `lspci -k` — GPU/Wi-Fi/audio
  all render clean, exactly one line each):
  ```awk
  hw_pci() {
    printf '%s' "$1" | awk -v want="$2" '
      /^[0-9a-f]+:[0-9a-f]+/ {
        if (matched) exit                      # first match fully captured
        if ($0 ~ want) { matched=1; line=$0
          sub(/ \(rev [0-9a-f]+\)$/,"",line)
          i=index(line,": "); out=substr(line,i+2) }
        next
      }
      matched && /Kernel driver in use:/ { out = out " \xc2\xb7 " $NF }
      END { if (matched) print out }'
  }
  ```
- **size:** small.

### 2. Bluetooth row misses combo cards the census detects — [applied to source · verified live on Acer + MacBook]
- **what:** the reveal's `hw_usb 'Bluetooth'` greps lsusb for the literal
  word "Bluetooth"; the Acer's QCA9377 BT doesn't say it, so no row — even
  though the census reports `hasBluetooth = true` (triangulated: sysfs
  class ∨ rfkill ∨ USB class e0). Align the reveal with the census: show a
  Bluetooth row when the probe says the radio is present (read
  decision.json / the same triangulation), rather than a lone lsusb grep.
- **why:** round 1, Acer — bluetooth present but absent from the reveal.
- **where:** `mockup/install-cli` `hw_usb`/`hardware_reveal` (~2732, 2748).
- **size:** small–medium (decide the source of truth: reuse the probe's
  bluetooth verdict).

### 3. golem-setup reaches outside its closure for lspci/lsusb — [applied to source · verified live on Acer + MacBook]
- **what:** add `pciutils` and `usbutils` to setup.nix `runtimeInputs`. The
  reveal + `driver_count` call `lspci`/`lsusb`, which are NOT declared;
  they resolve only from the medium's system PATH. Same class as the gawk
  bug (a tool that reaches outside its closure works until a stripped PATH).
- **why:** round 1, Acer — noticed while tracing finding 1; works today
  only by the installation-cd profile leaking the tools in.
- **where:** `setup.nix` runtimeInputs / makeWrapper `--prefix PATH`.
- **size:** small.

### 4. Progress bar stops at 83% on a rehearsal — [applied to source · verified live on Acer + MacBook]
- **what:** when step_go sees `##golem rehearsed`, fill the bar to 100%
  with a "rehearsed" label before printing the outcome. Rehearse emits up
  to `5/6` (83%) then `rehearsed` (never `6/6`, which is the reboot
  trigger), so the bar currently sits at 83% and reads as stuck.
- **why:** round 1, Acer — Max: "stop at 83% … the bar has stuck at 83%."
- **where:** `mockup/install-cli` step_go, the `'##golem rehearsed'*)` arm
  (~line 2958) — call `paint_bar "$max" "$max" "<rehearsed label>"`.
- **size:** small.

### 6. Medium's console keymap is implicit (English by accident) — [applied to source · round 3]
- **what:** pin `console.keyMap = lib.mkDefault "us"` on the MiniGolem ISO
  (iso.nix). Today the fresh-boot tty is English only because it's the
  kernel default — `systemd-vconsole-setup` logs "Configuration of first
  virtual console was skipped", so `KEYMAP=us` from vconsole.conf is never
  actively applied. Pinning makes English-on-fresh-boot a guarantee, not an
  accident. Also investigate WHY vconsole-setup skips, so the pin takes.
- **why:** round 1, MacBook+Acer — chasing a reported "Spanish tty on fresh
  boot". PROVEN NOT an ISO bug: the fresh default is us (keycode 39 =
  semicolon on a freshly booted machine); the Spanish was `loadkeys es`
  residue from golem-setup runs that picked Español (Madrid timezone → ES →
  Spanish). `loadkeys es` globally → keycode 39 = ñ; `loadkeys us` restores.
  This item is hardening, not a fix for a live bug.
- **where:** `iso.nix` — add `console.keyMap`. Possibly `console.earlySetup`.
- **size:** small.

### 7. golem-setup leaves the global console keymap changed — [DECIDED · applied to source, round 3]
**Applied:** `kb_apply` dumps the arriving keymap before its first
`loadkeys` (a full `dumpkeys` — the running map has no queryable name);
`kb_restore` reloads it when the keyboard step is ESCaped or the surface
exits without launching an install (EXIT trap + `INSTALL_LAUNCHED`).
**DECIDED:** save the prior keymap when the step applies one; restore it
when the user ESCs back out of the keyboard step or quits before
installing. A completed install keeps the chosen map (the machine
reboots into it). Round 3.
- **what:** the keyboard step runs `loadkeys "$KB_CONSOLE"` globally
  (install-cli:2050) so the live echo box reflects the chosen map — correct
  DURING setup, but it persists to the bare tty after exit/back-out. Decide
  whether to restore the prior keymap when the user backs out of the step
  or quits before installing.
- **why:** round 1 — this is what made the medium look "stuck in Spanish"
  after test runs. Harmless for a real one-shot install (the machine
  reboots into the chosen keymap), so low priority.
- **where:** `mockup/install-cli` around the apply seam (~2025-2050) and
  step exit paths.
- **size:** needs-Max — is persisting the applied keymap desired or not?

### 10. The driver count counted chipset bridges — [DONE · verified live on HP · round 3]
**Fixed (round-2 build):** `probe_compute` now excludes PCI bridge-class
devices (0x06xx — host/PCI/ISA bridges, QPI registers) that never bind a
driver. HP went from a misleading "23 of 31 (74%)" to an honest **"19 of
19 (100%)"** — every real peripheral driven. (The medium already carries
all firmware; see the round-2 correction below for that story.)


**CORRECTION (round-2 build, 2026-09-07).** Inspecting the round-2 squashfs
showed the medium ALREADY carried `linux-firmware` all along (the
installation-cd profile pulls it via all-hardware.nix) — 10,931 firmware
files, incl. brcmfmac blobs. So the round-1 story "the minimal medium ships
almost no firmware" was WRONG. `enableAllFirmware` in iso.nix now adds the
UNFREE firmware on top (broadcom-bt for the MacBook's BT, facetimehd, etc.,
+4.5 MB) — a real but small gain, not the hundreds of MB I expected.

Consequences to re-examine:
- The HP's "74% (23/31)" is therefore NOT simply missing firmware. The 8
  driverless devices were never enumerated (the HP dropped offline). Needs a
  real look in round 2 — some may be genuinely unhandled on the medium, some
  firmware-gated-but-now-present. The metric's "will be installed" wording is
  still misleading and #10c (fix the wording) still stands.
- The MacBook BCM4360 has NO brcmfmac firmware upstream (Broadcom never
  released it) — which is exactly why it needs `wl`. So firmware-on-medium
  does NOT light up the MacBook wifi; only `wl` does. That lives on the
  INSTALLED target (finding #5, broadcom-wifi.nix) — and since the install
  is OFFLINE, the medium never needs MacBook wifi. Optional future polish:
  add `wl` to the medium for a live-session-with-wifi UX.

**CONCRETE FIX (HP enumerated, round 2):** the HP's "23/31 (74%)" is
chipset glue, not missing support — its 8 driverless PCI devices are ALL
host bridges / PCI bridges / QPI registers (class 0x06xx), which no OS ever
binds a driver to. Fix `probe_compute` (mockup/install-cli) to EXCLUDE PCI
bridge-class devices (0x0600–0x06ff) from both numerator and denominator,
so the count reflects real peripherals. Then the HP reads ~100%. This is
the honest fix, better than rewording — round 3.

Original (round-1) framing below, kept for the record:

- **what:** `probe_compute` counts devices with a kernel driver bound ON
  THE RUNNING MEDIUM (`lspci -k | grep -c 'Kernel driver in use'` +
  USB with /driver), and the label says "%h of %t drivers **will be
  installed**". But the medium is minimal and ships almost no firmware, so
  firmware-gated devices (the AMD Radeon, some controllers, Broadcom wifi)
  show driverless — undercounting what the INSTALLED Golem delivers. The
  installed system sets `hardware.enableAllFirmware = true`
  (configuration.nix:414) and drives them. HP read "23 of 31 (74%)" and
  looked poorly supported when it is not.
- **twin problem, same root cause:** the MacBook's internal Broadcom wifi
  was dark on the medium for the same reason (finding #5) — no firmware on
  the minimal medium.
- **fix options (Max's call):**
  a. **Carry all-hardware firmware on MiniGolem** (like the full live ISO
     does) → the count is honest AND internal wifi works during install (no
     USB dongle). Cost: a bigger image. This also softens #5.
  b. Make the count reflect the INSTALLED target's driver coverage, not the
     medium's loaded set (harder to measure honestly from the medium).
  c. At minimum, stop the label promising "will be installed" about a
     present-tense medium measurement.
- **where:** `Installer/iso.nix` (firmware on the medium) and/or
  `mockup/install-cli` `probe_compute`/`drv_line`.
- **size:** NEEDS-MAX — image-size vs honesty tradeoff.

### 13. The rotating welcome shows boxes for non-Latin scripts on the console — [DONE · console-visual CONFIRMED on the VM, 2026-09-07]
**CONFIRMED on a rendered console** (VM, qemu screendumps of tty1, 8
frames across the full rotation): exactly the 7 ASCII welcomes rotate —
es / romanized-hi / pt / fr / id / it / en, then the cycle wraps — every
frame crisp, no boxes, no garbling. The French line uses ASCII "ENTER"
(not "ENTRÉE"), so it survives the byte test legitimately. The last
pending check on this item; it is closed.
Max chose **option A**. Applied to source: on the console (ASCII=yes) the
invitation keeps only the PURE-ASCII welcomes (tested by bytes, not a
per-language flag), so the 7 that render rotate (en/es/fr/pt/it/id + the
romanized hi) and CJK/Arabic/Cyrillic/accented lines are dropped;
off-console the full native set still rotates. Verified via `--dump invite`
(console = ASCII-only, endonym = native scripts present). Still wants a
LOOK at the physical console to confirm no boxes — can't be seen over SSH.
**Also (Max): rotation beat 5s → 4s** (`SECONDS_PER`), so `./mockup/install-cli
--fake-disks` shows the faster beat.

### 14. Touchpad reveal missed vendor-named pads (ALPS GlidePoint) — [applied · verified live on Comodore + Dell]
- **what:** `hw_input`'s pattern was `ouchpad|rackpad`; the Comodore's pad
  is `AlpsPS/2 ALPS GlidePoint` — no "touchpad"/"trackpad" in the name, so
  no row. Broadened to `[Tt]ouch[Pp]ad|[Tt]rackpad|GlidePoint|Synaptics|
  ALPS|Elan|Cypress`. A capability probe (input device with ABS axes +
  BTN_TOOL_FINGER) would be fully robust — noted, not done.
- **verified:** the Comodore reveal now shows `Touchpad AlpsPS/2 ALPS
  GlidePoint`. **Round 2, Dell:** same row appears there too — and it
  CORRECTS the round-1 Dell record, which read "touchpad didn't
  enumerate (keyboard fault)". It enumerated fine; the old pattern
  couldn't see a vendor-named ALPS pad. Two of five lab machines carry
  one — this was never an edge case.
- **where:** `mockup/install-cli` `hardware_reveal` touchpad row.

### 15. Reveal showed no networking on a wired-only machine — [applied · verified live on Comodore]
- **what:** `hardware_reveal` only queried the Wi-Fi PCI class (`Network
  controller`), so a machine with only wired Ethernet (Comodore: Marvell
  88E8055) showed no network at all. Added an Ethernet row (`hw_pci
  'Ethernet controller'`). Machines with both now show Wi-Fi AND Ethernet.
- **verified:** the Comodore reveal now shows `Ethernet Marvell … 88E8055 ·
  sky2`.
- **where:** `mockup/install-cli` `hardware_reveal` (+ the fake block).

### 12. intelLegacy misclassifies ancient GMA GPUs (0x2xxx) as iHD-capable — [DONE — shipped in the round-2 build]
**Verified during the round-3 close:** the source already carries the
two-range test (`< 0x1600` OR `0x2500–0x2e99`) with the Comodore's GMA
4500 (0x2a42) called out — it went in with the round-2 build (commit
"GMA fix"). Nothing left to do; kept for the record.
- **what:** the probe decides `intelLegacy` with `device-id < 0x1600 →
  legacy (i965)`, else iHD. That holds from Ironlake through Skylake, but
  the pre-Ironlake GMA parts have numerically HIGH ids (GM45 GMA 4500 =
  0x2a42) despite being the OLDEST — so they fall above the threshold and
  are wrongly marked iHD-capable. iHD supports Broadwell+ only; a Gen4 GMA
  gets NO hardware video decode from iHD (needs i965, or accept none).
  Fix: extend the legacy condition to cover the old GMA ranges (roughly
  0x2500–0x2fff, the Gen4/GMA 4500 family), or replace the single threshold
  with a generation lookup. Display is unaffected (kernel i915 handles
  GMA 4500), so this is decode-quality, not a black-screen risk.
- **why:** round 1, Comodore — `8086:2a42` GMA 4500 read as `intelLegacy =
  false → iHD`.
- **where:** `system/hardware-detect.nix` — the `intel_legacy` test
  (~line 92, `(( dev < 0x1600 ))`).
- **size:** medium — needs the right GMA id ranges; keep a fixture (the
  Comodore's facts) so CI covers it.

### 11. `video decode: none` reported for AMD/nvidia — [applied to source · round 3]
**Live on metal (ThinkPad, round 2):** the lab's first AMD machine shows
exactly this — `gpu = amd`, `video decode: none` on the frozen stick.
The round-3 stick will read "vaapi, mesa radeonsi" on the same machine —
a clean before/after for the record.
- **what:** decide.nix's GPU "video decode" row only knows the Intel VA-API
  driver names (i965/iHD) and prints "none" for AMD/nvidia — even though
  `gpu="amd"` enables the AMD VA-API (hardware.nix:62). A reporting gap, not
  a missing feature. Surface the AMD/nvidia VA-API in the census instead of
  "none".
- **why:** round 1, HP — `gpu="amd"` showed `video decode: none`,
  reinforcing the "AMD unsupported" misimpression.
- **where:** `system/hardware/decide.nix` (the gpu section's video-decode row).
- **size:** small.

### 9. Reveal GPU row shows the iGPU, not the decided dGPU (hybrid machines) — [DONE · verified live on HP · round 3]
**Fixed (round-2 build):** `hw_pci_all` enumerates EVERY display controller,
so a hybrid shows both. HP now lists `Intel … · i915` AND `AMD/ATI Robson
CE [Radeon HD 6370M/7370M] · radeon` — matching the big red AMD sticker on
the lid, which was Max's whole point (round 2: "our installer showing only
an intel GPU"). Original diagnosis below.

- **what:** on a switchable-graphics laptop, `hw_pci 'VGA|3D|Display'`
  returns the FIRST VGA controller — the Intel iGPU — so the reveal says
  "GPU: Intel · i915" while the census DECISION is about the discrete GPU
  (AMD/nvidia) and installs its driver. The screen and the decision
  disagree. Fix: for the GPU row, enumerate ALL display controllers (show
  both on a hybrid), or prefer the discrete one to match the census
  priority (nvidia > amd > intel). Showing both is the honest option — a
  hybrid laptop has two.
- **why:** round 1, HP Pavilion dm4 — `gpu = "amd"` (Radeon HD 6370M) but
  reveal named the Intel iGPU.
- **where:** `mockup/install-cli` `hardware_reveal`/`hw_pci` (GPU row).
- **size:** small–medium (hw_pci returns one device by contract; showing
  all GPUs means iterating matches for that row).

### 8. BIOS/legacy-only machines can't boot the installed target — [DECIDED: support BIOS]
- **what:** the target installs systemd-boot, which is UEFI-only. A machine
  that can only boot BIOS/legacy (or is set to legacy) takes the install and
  then can't boot it. The rehearsal's UEFI preflight already REFUSES this
  cleanly (good) — the open question is whether Golem should SUPPORT such
  machines (a GRUB-BIOS bootloader path on the target, chosen by a firmware
  fact) or stay UEFI-only and rely on the refusal + telling the user to
  enable UEFI in their firmware.
- **why:** round 1 — Dell E6420, HP Pavilion dm4, AND the Comodore all
  booted BIOS: **3 of the 5 lab machines**. Legacy boot is the MAJORITY
  among old laptops, not an edge case. Some can likely do UEFI via a
  firmware setting (so part of the answer may be "tell the user"), but 3/5
  means Golem needs a real position on BIOS boot, not just a refusal.
- **where:** target bootloader (`system/configuration.nix` boot.loader) +
  possibly a firmware fact in the census; the refusal already lives in
  `install.nix` preflight.
- **size:** NEEDS-MAX — support-scope decision (UEFI-only vs BIOS fallback).

### 5. Broadcom Macs lose Wi-Fi after install — [DELIVERED round-2 build · rehearsal-proven on MacBook · live proof = round 4]

**Round-2 proof (MacBook, 2026-09-07):** census `broadcomWifi = true` →
target golem-hardware.nix → broadcom-wifi.nix (broadcom_sta +
kernelModules wl + scoped allowInsecurePredicate) → **broadcom-wl
sources in the toplevel drv's closure**. Also closed on metal: brcmfmac
+ firmware does NOT light the BCM4360 on the medium (no interface,
brcmfmac not loaded — bcma holds the card) — wl is the only path.
**Small round-3 edit queued:** broadcom-wifi.nix's comment claims
brcmfmac is "the clean default for most parts, incl. the BCM4360" —
wrong for the 4360 (no upstream firmware; proven dark on the medium);
fix the comment so the next reader isn't misled. Live wifi-up proof
lands at round 4's first real install.
- **what:** the installed Golem on a Broadcom-wifi Mac comes up with no
  working internal wifi. The BCM4360 needs the UNFREE `broadcom-sta` (`wl`)
  kernel module; `nixos-generate-config` never emits it, the census has no
  wifi-chipset fact, and nothing tells the target to enable it. On the
  medium the card binds `bcma-pci-bridge` (a bus bridge, not functional
  wifi) — the reveal names it but it does not work, hence the lab's USB
  dongle. This is the MacBook's whole reason to be in the lab.
- **why:** round 1, MacBook — installed target's hardware-config carries no
  Broadcom module; census has no wifi fact.
- **where:** census (`system/hardware-detect.nix` — a wifi/broadcom fact)
  + target (`system/hardware/` — enable `boot.extraModulePackages` /
  `broadcom_sta` on that fact). PLAN.md already notes
  `system/hardware-runtime.nix` carries the `wl` quirk for the LIVE
  session; the open question is the INSTALLED system.
- **size:** NEEDS-MAX — turns on an **unfree** driver (broadcom-sta), which
  is a distro policy call (allowUnfree, and whether to auto-enable on
  detection or ask). Also: which Broadcom chips get it. Not a mechanical
  fix; Max decides scope before it's built.

<!--
Entry template:

### <short title>
- **what:** …
- **why:** … (round N, surfaced on <laptop(s)>)
- **where:** `path/to/file.nix:line` (if known)
- **size:** small | medium | needs-Max
-->

## Applied

- **Round 0 → Round 1 (2026-09-06, pre-constitution):** sysfs cores fix
  (`system/hardware-detect.nix` — dropped the awk dependency the boot
  audit's clean PATH stripped) and the hostname ghost-placeholder fix
  (`mockup/install-cli` — typing no longer appends to the "Golem"
  default). Both surfaced by the Acer's first rehearsal and baked into the
  round-1 ISO before the queue discipline began.
