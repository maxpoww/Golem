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

> **I2 CLOSED / I3 OPEN 2026-09-23.** I2's install-to-disk gate PASSED and the
> boot bar (#116/#117) was proven on real i915 (asus 3m26s + acer 3m46s, both
> boot-bar-on-metal). Rather than run the rest of the I2 roster with a known
> reboot-loop bug (#118), Max folded #118 (verify bar + gated reboot) + #119
> (Diagnosing) and the fresh lock into a **recut I3** — one clean roster on the
> complete image (the §2 spirit: every machine meets the SAME final ISO). I3 is
> VM-gated end to end (menu · autostart · install-to-disk · installed boot bar ·
> the #118 two-bar verify → gated reboot). The roster now runs on I3.
>
> **[archived I2 status]** RECUT I2 BUILT 2026-09-22 — VM-gated on menu + boot +
> census; install-to-disk + metal proven on asus + acer. A
> fresh `golem-installer.iso` (3.0 GiB, clean-tree build) FREEZES the fixes
> below. The one piece of NEW work the recut itself owed — the medium's own
> grub (#89/#95/#92, "the ISO side owed at the recut") — is done: `iso.nix`
> imports the shared `boot/grub-patch-overlay.nix`, and the medium's UEFI menu
> renders centred + silent like the machines it installs (screendump-verified).
> Also folded + marker-verified: #96 facetimehd, #97 pciutils, #98 the lenovo
> facts-matrix row, and #102 below. These entries move to Applied once the
> stick is reflashed and metal-verified.

### 119. "READING THIS DEVICE" → "DIAGNOSING THIS DEVICE" — the census status line — [DONE 2026-09-23 · Max: "i dont like 'reading this device', lets say 'Diagnosing device'"]
The census-status line (shown while the audit reads the machine behind the
questions) said "Reading this device" / "Device read". "Diagnosing" is the truer
verb — the census reads AND decides — and it rhymes with the #118 verify bar:
Golem DIAGNOSES the device, then VERIFIES the install (the "careful, double-
checks itself" positioning). Changed `reading`→"Diagnosing this device" and its
`read_ok` counterpart→"Device diagnosed", all 6 languages, kept parallel.
**where:** `mockup/install-cli` (S[*:reading], S[*:read_ok]). **PROCESS:** rides
the next recut (§2). **size:** done.

### 118. THE AUTO-REBOOT BOOTS THE USB AGAIN — an unattended install loops back into the installer — [FOUND 2026-09-23 · the acer, I2-close roster · Max: "if the user is not there the pc will boot to the usb again instead of booting to Golem. how do we handle that?"]
At 100% `golem-install` finishes and install-cli does `systemctl reboot` (step_go
— "the full bar IS the signal, reboot immediate", Max 2026-09-06). But the USB is
still in, and most firmwares boot removable media before the internal disk — so
the reboot re-enters the INSTALLER, and unattended it loops instead of landing in
Golem. Breaks the 8e "reliable as fuck, never fail" promise for a walk-away
install.
- **poweroff — REJECTED by Max:** doesn't actually fix it. The user comes back,
  powers ON with the USB still in → it boots the USB anyway. poweroff just delays
  the loop.
- **THE FIX (Max, 2026-09-23) — a SECOND bar + a GATED reboot, and a positioning
  turn.** After the copy bar hits 100%, a second bar runs: "comprobando
  instalación" (~5–6 s of REAL post-install checks on /mnt), then "la instalación
  está sana — remove the USB and press ENTER" → ENTER reboots. Gated on a
  keypress, so **unattended it HOLDS at the message and never loops** — that is
  the fix. Present, you pull the stick then press ENTER → Golem.
  - **WHY, the brand turn:** Golem will not beat Omarchy on install TIME (~10 s).
    So it competes on TRUST instead — "Golem takes a few minutes, but it is
    stable, double-checked." The verify bar IS that promise, made visible.
  - **§10 — it must be REAL, not a 5 s spinner.** "success without verification is
    the lie this lab exists to prevent." The check is the §6 first-boot audit run
    OFFLINE on /mnt as a "will this boot?" pre-flight: bootloader on the ESP,
    system toplevel valid, kernel+initrd present, fstab root/ESP correct, the
    seed + rebuild machinery there, the owner loginable (hash/key). A FAILED
    check says what's wrong BEFORE the reboot — the reliability payoff.
- **THE VERDICT, refined (Max, 2026-09-23):** the verify bar SHOWS the checking
  (same bar idiom — flying effect + %), fast, 7–8 s max; it does NOT print
  per-check results on screen. One calm final line: all-pass → "la instalación
  está sana — remove the USB and press ENTER"; anything off → "instalación
  terminada — …" (neutral, still true — it did finish; we just do not claim
  "sana"). §10 stays satisfied two ways: "sana" is only ever said when it is,
  and the REAL results go to the LOG (screen calm, log honest — "terminada" is
  the soft tell to read the log). Critical failures are already caught upstream
  by golem-install's check_fail (format/fs/copy), so this pre-flight is the
  subtle would-it-boot layer.
- **Rejected too:** efibootmgr `--bootnext` (UEFI-only; #94 NVRAM untrustworthy).
- **where (when applied):** `mockup/install-cli` step_go (second bar + the
  gated-ENTER reboot) + a small offline health-check the surface runs on /mnt
  (or golem-install emits its verdict). **PROCESS:** §2 — rides the NEXT recut,
  not a mid-roster reburn; the current roster is attended, so it doesn't block.
  **size:** medium — **BUILT + VM-gated 2026-09-23** (I3): copy bar → verify bar (6 real /mnt checks: bootloader·system·kernel·fstab·seed·account, results to verify.txt) → "La instalación está sana — retira el USB y pulsa ENTER"; it HELD static (no auto-reboot), ENTER rebooted. The unattended USB-loop is gone. The reboot cannot exec `systemctl` off the pulled USB (the installer runs FROM it — Max hit the I/O-error/getty-loop when he removed the stick then pressed ENTER); it reboots through the KERNEL instead — `echo b > /proc/sysrq-trigger`, a bash builtin with no store access — so Max's exact flow survives: pull USB → ENTER → into Golem. sysrq enabled on the medium (iso.nix).

### 117. THE BOOT BAR DIDN'T RENDER ON AN INSTALLED SYSTEM — no GPU DRM in the minimal initrd — [FOUND + FIXED 2026-09-23 · the I2-close VM install+boot gate · this is the root of Max's earlier "no bar on installed Golem, blank until login"]
The baked-Plymouth fix (#116c verified `plymouth-start` + the theme in the
installed closure) was necessary but NOT sufficient. On the I2-close gate the
installed system booted straight to `Golem login:` with a black screen — the bar
never painted. Root cause: the minimal installed **initrd has no display driver**
(ahci/ata_piix/hid_*… but no `bochs`/`i915`/`virtio_gpu`), so Plymouth has no DRM
device in early boot; the GPU module only loads in the main system, after getty
takes the console. The installer MEDIUM never showed this because installation-cd
ships a fat initrd. **fix:** `boot.initrd.kernelModules = [ "bochs" "i915"
"amdgpu" "virtio_gpu" ]` in `boot/plymouth.nix` — force-load the lab's display
drivers early (a no-matching-device module no-ops). nouveau/radeon left out
(nouveau fights the proprietary-nvidia bind; the failing-radeon machine displays
on its intel). **where:** `boot/plymouth.nix`. **size:** done, re-gated.

### 116. THE BAR EVERYWHERE — a Plymouth boot bar styled as the OPTIONS status bar — [DONE 2026-09-23 · Max: "can we add the same bar as the status bar loading on boot? … lets show our bar everywhere" · chose bar + flying service names, on installed Golem + the installer stick]
The quiet boot (base/core.nix) gives a black screen from kernel handoff to the
compositor; now it fills with the accent bar. A `script`-module Plymouth theme
(`boot/golem-plymouth/golem.script`) draws the one accent (#d7af87 = fg 180)
filling on a dim track, with the service that is starting flying past
underneath — the boot echo of the installer's flying filenames. `boot/
plymouth.nix` packages the theme (two 1px colour tiles the script scales),
enables `boot.plymouth`, and re-adds `splash` + `systemd.show_status=auto`
(mkAfter, so they beat base's `show_status=false`). Wired into the base
composition (every installed Golem) AND the installer `iso.nix` (the stick's own
boot). **VERIFIED in a headless VM** (bochs-drm): the boot came up with the
accent bar half-filled and "plymouth-read-write.service" flying beneath it —
exactly the look. **THE #65 TAX:** base drops `splash`/`fbcon=map:1` because the
acer's single fb0 made `fbcon=map:1` fatal; this re-adds `splash` ONLY (never
the mapping) — Plymouth renders via DRM/KMS with a text fallback, so it does not
take the console away the way the mapping did. The oldest lab GPUs (GM45 GMA)
are the metal to watch. All 8 effect-matrix fixtures still evaluate.
**where:** `boot/plymouth.nix`, `boot/golem-plymouth/golem.script`,
`composition.nix`, `iso.nix`. **size:** done; refinements (bar thickness,
segmented block look, tuning which units fly) are Max's call on metal.

### 115. THE STATUS BAR FLICKER — [DONE 2026-09-23 · Max, install working on metal: "the status bar flickers, it is not constant, but it does"]
`paint_bar` repaints ~20×/s (the flying-names copy loop). Each repaint did two
things that flicker: it erased the WHOLE line with `[2K` before redrawing, and
it drew the filename in a SECOND `printf` — so every frame the bar and the name
blanked and redrew, which at 20 Hz reads as flicker. Rewrote it as ONE `printf`
that redraws over itself from column 0 (`\r`, identical blocks landing on
identical blocks — invisible) and clears only the LEFTOVER past the new content
with a trailing `[K`. No blank frame, so the bar is rock-steady while the name
still changes underneath. **where:** `mockup/install-cli` (`paint_bar`).
**size:** done.

### 114. THE DEFINITIVE NO-BANNER AUTOSTART — no agetty line at all — [DONE 2026-09-23 · Max: "do the definitive fix, no banner at all"]
#113 could only shorten agetty's autologin line (it hardcodes "(automatic
login)"; no flag mutes it). The definitive fix drops autologin on the Install
boot entirely: tty1's getty runs `--skip-login --login-program ${installSurface}`,
so agetty prompts for nothing, prints NOTHING, and execs `installSurface` (a new
`writeShellScript` in iso.nix) as root — `--skip-login` never drops privilege, so
no sudo either. On tty1 it clears and `exec`s `${setup}/bin/golem-setup-install`;
on any other VT it falls through to the real `login`, so tty2-6 stay a normal
debuggable console. There is no login shell on tty1 now, so the old
`environment.loginShellInit` autostart (and its #103 sudo dance) is gone — the
launcher IS the autostart and the first thing on the console. The old design's
"no systemd service for tty1" caution still holds and is respected: getty still
owns tty1; we only changed what it execs. **Not** a service.
- **where:** `iso.nix` (`installSurface` let-binding + the `specialisation.install`
  getty overrides: `autologinUser = mkForce null`, `loginProgram`, `extraArgs +=
  --skip-login`). **verified:** headless VM — Install autostarts straight to a
  clean "Press ENTER", menu clean, and with no login step there is no banner to
  render at any boot speed. **size:** done. Supersedes #113's `--nohostname`
  half (kept, harmless) for the login banner.
- **114a — the PATH regression this introduced, and its fix (2026-09-23 · Max:
  "after pressing enter on 'install golem?' the installer restart → 'press ENTER
  to choose your language'").** Dropping the login shell also dropped the PATH it
  supplied: agetty's env has no system profile, so `sudo`'s old `secure_path`
  (which carried `/run/current-system/sw/bin`) was gone. install-cli's confirm
  step runs the bare `golem-install` (a systemPackage) → command-not-found →
  install-cli falls off its end → getty respawns the surface → the restart Max
  saw. **fix:** `installSurface` exports `PATH=/run/current-system/sw/bin:$PATH`
  (+ HOME/USER/LOGNAME, mirroring the root session `sudo` set up) before
  `exec`ing the surface. **Verified END-TO-END in a headless VM** (40 GB virtio
  target so the fit check passes): drove language→…→you→confirm, ENTER on
  "Install Golem?" → the install RAN — bar to 79%, the white flying filenames
  churning (libxau-1.0.12 → perl5.42.0-HTML-Parser-3), no restart. Also
  incidentally confirmed: #113 white names live, #111 wider bar, tty2 login path
  works. (Diagnosis note: a 12 GB VM disk trips a legit pre-flight `FAIL fit:
  … closure ~19 GiB` — that also restarts, but is disk-size, not this bug.)

### 113. METAL FOLLOW-UPS: WHITE FLYING NAMES · PRE-MENU SPLASH · THE LOGIN HOSTNAME — [2026-09-23 · Max: "make the names white" + "there is a splash before the menu (start | install)" + "the golem-install login is still there before the 'press ENTER…'"]
Three metal findings from the flying-names ISO:
- **The flying names go white.** They rendered in `C_DIM` gray like the
  "copying" verb. `paint_bar` gained a 4th arg — the filename — drawn in
  `C_VALUE` (the palette's brightest ink, the same white the answered values
  wear), while "copying" stays dim scaffolding. The `##golem` parser splits
  "copying <name>" into verb + name. **where:** `mockup/install-cli`.
- **The pre-menu splash.** On UEFI, GRUB printed "Loading graphical boot
  menu… / Press 't' to use the text boot menu…" before the Start|Install menu.
  Removed those echoes from the vendored grub.cfg (`iso-image-golem.nix`);
  `clear` still wipes firmware output, so it's black → menu. Text fallback is
  still 't', unadvertised. **where:** `iso-image-golem.nix`.
- **The login line that says "golem-install".** DIAGNOSED in a headless VM:
  greeting-blanking works (evaluated `""`), and the surviving line is agetty's
  OWN autologin banner "golem-installer login: nixos (automatic login)" — it
  prints the format "%s%s (automatic login)", the hostname `golem-installer`
  being what Max read as "golem-install". The VM boots fast enough that the
  loginShellInit clear (#111) wins and it never renders (frame 1 of text is
  already "Press ENTER"); the slow asus shows it for ~1-2 s first. No agetty
  flag silences the "(automatic login)" notice, so `--nohostname --noissue`
  (`services.getty.extraArgs`, install specialisation) at least drops the
  hostname + issue — the flash no longer says "golem-install". The clear still
  covers the rest. If the residual "login: nixos" flash still bugs Max, the
  definitive fix is `--skip-login --login-program` (a tty-aware launcher, no
  agetty banner at all) — deferred as more invasive. **where:** `iso.nix`.

### 112. FLYING FILENAMES — THE WINDOWS-XP COPY FEELING — [DONE 2026-09-23 · Max: "i would like to see file names moving faster, like 'copying python3'… the name changing every ms… a feeling of dinamicity… windows xp used to do that. if that is possible, and cost nothing."]
The copy phase used to label the bar "copying 800/830" — a moving count. Max
wanted the XP feeling instead: real package names flying past fast. **How, for
free:** the closure's store-path NAMES are captured ONCE (mapfile) from the very
`nix-store -qR "$system"` query install.nix already runs to size the bar — hash
prefix stripped with `sed -E 's#.*/[a-z0-9]{32}-##'`. The copy loop now ticks at
~20/s and flies one name per tick as the label (wrapping the list, each name
truncated to 24 chars so a 42-cell bar + "  NN%  " + name never overflows 80
cols). The bar's PERCENT still tracks the REAL copy — `find /mnt/nix/store`
still runs only every ~2 s (40 ticks), kept OFF the per-tick path, so the fast
churn adds zero disk I/O. The names are the actual things being installed, just
shown faster than they literally land — the honest XP illusion. The old
count-only label existed only because a per-tick `ls|head` would SIGPIPE under
pipefail (SC2012); an in-memory array has neither problem. install-cli needs no
change — "copying <name>" passes through its `##golem` parser and renders
capitalised. **where:** `install.nix` (the 5b copy loop). **size:** done; churn
rate is `sleep 0.05` (~20/s), a one-line tweak if Max wants faster/slower.

### 111. THE LAST SPLASH LINE + A LONGER STATUS BAR — [DONE 2026-09-23 · Max, on metal: "there is still some splash before the 'press enter to select language', i saw something like 'golem-install etc etc' like one line" + "the status bar should be 50% longer and 50% wider"]
Two metal findings from the reverted-centering install:
- **The one surviving splash line.** #109 blanked the getty greeting, but one
  line still sat before "Press ENTER": agetty's autologin banner
  `golem-installer login: nixos (automatic login)` (the hostname is
  `golem-installer` — that's the "golem-install etc etc" Max read). It stayed
  on screen for the ~1 s the login shell takes to sudo, spawn the wrapper and
  parse the 4k-line TUI before its first screen-clear. **fix:** `iso.nix`
  `loginShellInit` now clears the console (`printf '\033[H\033[2J\033[3J'`)
  the instant the shell starts, before that gap — pure escape, no binary
  needed. Black boot straight into the installer, for real this time.
- **The status bar 50% longer.** `paint_bar` width 28 → 42 cells. Asked Max
  what "50% wider" meant for a one-row bar (a terminal can't do half a row);
  he picked **same axis, just longer** — not a taller multi-row bar. Still one
  row, fits 80 cols with the margin + "  NN%  " + label. **where:**
  `mockup/install-cli` (paint_bar), `iso.nix` (loginShellInit). **size:** done.

### 110. CENTRE THE INSTALLER — TRIED, REVERTED — [REVERTED 2026-09-23 · Max, seeing it on metal: "it sucks, it is poorly centered, we dont need to deal with it now, fuck it, lets go back to the classic left aligned."]
Max wanted the installer's content in the CENTRE of the screen, like the boot
menu. Built it: `mockup/install-cli` read the console geometry (`stty size`)
and centred its fixed-width column — `IND` as the horizontal margin,
`compute_layout` computing it once after TTY is decided, and `screen` →
`vcenter` padding the top to centre each block vertically (with a scroll guard
for the tall review). On metal it looked poorly centred, and Max called it off:
**back to classic left-aligned.** `install-cli` restored to its pre-#110 state
(`IND='  '`, `screen` just `printf '\n'` — the version with #106/#107 intact);
`compute_layout`/`vcenter` removed entirely. Not a look worth chasing now — if
we ever want it, it needs real per-screen line counts, not a fixed guess.
NOTE: the census-off-step-1 move rode in on #109 (the audit banner is what was
on step 1), not on this — that stays; only the centring is reverted. **where:**
`mockup/install-cli`. **size:** reverted, net zero.

### 109. THE SPLASH BEFORE THE INSTALLER — the tty "loaded" before Press ENTER — [FOUND + FIXED 2026-09-23 · Max, after installing: "there is a splash before the 'press enter to select your language' like the tty loading before the installer. can we get rid of that?"]
On the INSTALL boot, after the silent black boot, the getty greeting + helpLine
and the audit's census banner printed to tty1 — then the guided TUI cleared the
screen over them. That flash of console furniture is the "splash". On the Start
(live) boot it belongs; on Install the surface owns the screen and the review
shows the census anyway, so it is pure noise.
- **fix:** `audit.nix` skips the census banner when `golem.install` is on the
  kernel cmdline (the `owns-console` race-guard stayed; this is the certain
  one). The Install specialisation (`iso.nix`) blanks
  `services.getty.greetingLine` + `helpLine` with `mkOverride 10` (beating the
  base `mkForce`). The one line left is agetty's own "login: nixos (automatic
  login)", cleared instantly by the TUI. Black boot → straight into the
  installer.
- **where:** `audit.nix`, `iso.nix`. **size:** done.

### 108. GOLEM'S SHELL IS PLAIN BASH NOW, NOT ZSH — [DECIDED + DONE + VM-VERIFIED 2026-09-23 · Max, after installing on the asus: "we don't need the shell teaking on Golem. lets use plain bash, minimal configuration. classic good old shell."]
`base/zsh.nix` brought zsh (autosuggestions + syntax highlighting) and the home
layer's starship / eza / bat / fzf / zoxide / aliases — "Golem's zsh" was even
called the stage-0 IDENTITY (2026-09-10, base/ port). Max reversed it after the
first real install: plain bash, minimal, the classic shell.
- **done:** `base/zsh.nix` → `base/shell.nix` (the owner's home-manager config,
  empty but for `home.stateVersion` — no prompt theme, no plugins, no aliases);
  `base/users.nix` sets `shell = pkgs.bashInteractive`; `composition.nix` imports
  `shell.nix`; `effect-matrix.nix` asserts bash (`hasPrefix "bash"` on
  `shell.pname`, which is "bash-interactive"). `home/zsh.nix` kept on disk (the
  fat config still imports it), just no longer in the minimal path.
- **VM-PROVEN:** installed → booted the disk → `Golem login: max` → the classic
  `[max@Golem:~]$` bash prompt; `echo $0` → `-bash`. minimal-matrix green (8
  composed).
- **left for Max:** the FAT dogfood config (`system/configuration.nix`) still
  has zsh — his own machine, his call to flip.
- **where:** `base/shell.nix` (new), `base/zsh.nix` (removed), `base/users.nix`,
  `composition.nix`, `effect-matrix.nix`. **size:** done; rides the recut.

### 107. THE INSTALL BAR FROZE AT 83% AND SAID "READING THE DEVICE" TWICE — [FOUND + FIXED + VM-VERIFIED 2026-09-23 · the asus install · Max: "the status bar sounld be dinamic … is just no plecent"]
Max, watching the first metal install: the bar jumped 16→44→66 then sat at 83%
for 2m30s (the system copy), and "reading the device" appeared BOTH before the
install and again at 66%.
- **the freeze:** 6 equal phases (~16.7% each), but the copy — phase 5 — is
  ~90% of the wall-clock, so it parked at 83%. Fix: the `##golem` markers moved
  to a PERCENT scale (`<pct>/100 <key>`, weighted toward the copy: format 5,
  fs 10, seed 14, probe 18, install 20→95, done 100), and the copy now STREAMS
  — `nixos-install` runs in the background while `install.nix` watches its
  closure's store paths land in /mnt and emits fine markers 20→95% with a live
  "copying N/total" count. VM-PROVEN: the bar climbed 20% → 48% "Copying
  389/1026" → done + reboot, moving the whole time. (Rehearse is untouched — it
  exits before the install phase.) The count is CLAMPED to N/N — Max saw
  "copying 1020/1019" because the store's `.links` dir (and maybe `.lock`) tips
  the /mnt count one past the closure; clamp so it never overshoots (2026-09-23).
- **⚠ the gate caught a regression:** `find /mnt/nix/store` runs BEFORE
  nixos-install creates that dir, so `find` exits 1, and under `pipefail` the
  whole install died at 20% ("died line 859: wc -l"). Fixed by neutralising the
  pipeline (`{ find … || true; } | wc -l`) so a missing dir just counts 0. This
  is exactly why the VM gates every change before metal.
- **the double "reading the device":** the census says it once up front; phase
  4 (`nixos-generate-config`, "probe") re-used the exact phrase at 66%. Fix:
  `ph_probe` renamed to "hardware profile" (all 6 languages) — "reading the
  device" now appears once, before the install, as Max asked.
- **where:** `install.nix` (markers + streaming copy), `mockup/install-cli`
  (ph_probe). **size:** done.

### 106. "TESTED, DIDN'T WAKE UP" READ LIKE A BUG ON METAL — a second GPU is now LISTED, not judged — [FOUND + FIXED 2026-09-23 · the asus's old dGPU · Max's call after the first install]
Max, on the asus's first install: the census showed its old nvidia dGPU as
"tested, didn't wake up" and he hated it — it reads like a failure when the
machine is actually FINE. Golem is being unusually diligent: it powers on a
second GPU to check its health (#17c), and a failing/asleep dGPU "doesn't
wake". Golem's answer is the RIGHT one — never bind a driver to it or power it
on, so a flaky dGPU (the thing that bricks other distros' installs) can't hang
the machine — but the WORDING reported a save as a failure.
- **fix (Max's call):** a second GPU that fails the wake-test is LISTED like
  any other part — its name + driver, NO verdict (`install-cli` hw_row: the
  `failing` case is now the same as the default). Only the GPU DRIVING THE
  SCREEN earns a "working" line; showing hardware is not a promise it works, so
  Golem neither claims nor scares. `S[*:gpu_dead]` ("tested, didn't wake up")
  is now unused.
- **note:** other distros never show this because they don't TEST — they load
  a driver and you meet the black screen at runtime if the chip is dead. Golem
  catches it up front and stays away from it; the message just needed to sound
  like the save it is.
- **where:** `mockup/install-cli`. **size:** done.

### 105. THE INSTALLER COULDN'T WIPE A DISK THAT ALREADY HELD AN OS — wipefs died "busy" at 16% on the FIRST real metal install — [FOUND + FIXED 2026-09-23 · the asus, Max's first product install from the recut stick · rides the recut]
Max installed from the recut stick onto the asus's internal disk (its own fat
dogfood Golem) and it stopped at 1/6 (16%). `status`: `error: line 136 (exit
1)`; `transcript`: `run swapoff -a / cryptsetup close golem / umount -R /mnt /
wipefs -a /dev/sda → died`. The format phase's disk-release was naive — it only
did `umount -R /mnt` and closed a HARDCODED LUKS name "golem", so it never
touched the partition the LIVE MEDIUM had AUTO-MOUNTED elsewhere
(`/run/media/…`). wipefs refuses a disk with any partition still busy, so the
install died before it wrote a single byte (disk intact — nothing lost).
- **fix (`install.nix` format phase):** release the target disk COMPLETELY
  before wipefs — swapoff; umount every mounted partition of THIS disk wherever
  it landed (`lsblk -o MOUNTPOINT`, deepest first); `vgchange -an` then `dmsetup
  remove -f` every crypt/lvm/dm/raid leaf backed by the disk (a re-install over
  an encrypted or LVM Golem); `udevadm settle`; THEN wipefs. wipefs is now a
  guarded gate: on failure it dumps `lsblk` + `fuser` to the transcript and
  fails with a plain "could not free $disk" instead of the cryptic "died at $@".
- **why the VM never caught it:** the VM's target disk is a blank virtio — there
  is nothing to auto-mount. The first disk that ALREADY held an OS was the asus,
  on metal — exactly why the round runs on real hardware.
- **where:** `Installer/preinstall/install.nix`. **size:** done; rides the recut.

### 104. THE MEDIUM BOOTED LOUD — the kernel + systemd log spilled over the screen after Start/Install — [FOUND + FIXED + VM-VERIFIED 2026-09-23 · Max's eyes on the first metal boot of the recut · rides the recut]
Max, booting the recut stick on metal (menu + census confirmed good): *"the only
thing we need is to make the boot silent. i don't want to see all those letters
after i pick start or install.. Golem boot is black screen until booted."* The
medium (installation-cd-minimal + `iso.nix`) only lowered `consoleLogLevel` and
never carried the quiet kernel cmdline the INSTALLED system has
(`base/core.nix`), so its boot spilled the kernel + systemd log to the
framebuffer. Fix: `iso.nix` now carries the same log-quieting params —
`quiet loglevel=0 {rd.,}systemd.show_status=false {rd.,}systemd.log_level=0
{rd.,}udev.log_level=0 vt.global_cursor_default=0` + `consoleLogLevel=0` +
`initrd.verbose=false`. This is the SAFE set: NOT `fbcon=map:1`/`splash`, which
take the display away and left the first metal machine's minimal console a DEAD
black screen (#65) — these only silence the log, the framebuffer console stays.
The Install specialisation's `golem.install` param APPENDS (list merge), so both
entries boot silently. `consoleLogLevel=0` also keeps the HP's red Radeon resume
errors off the installer surface (the #17a reason for the old `=3`, now stricter).
- **VM-PROVEN (2026-09-23):** Start → **pure black** through the whole boot (no
  kernel/systemd letters) → the census banner lands clean, console fully usable.
- **where:** `iso.nix`. **size:** done. **owed:** Max's eyes on the reflashed
  stick (the metal that asked for it).

### 103. THE PRODUCT INSTALLER'S AUTOSTART RAN golem-install WITHOUT ROOT — the TUI-driven install died before its own logdir — [FOUND + FIXED + VM-VERIFIED 2026-09-22 · the recut's install-to-disk VM gate · rides the recut]
The 8e "Install" autostart (`iso.nix` loginShellInit → `golem-setup-install`)
runs as the autologin **`nixos`** user, and step_go (`mockup/install-cli:3618`)
invokes `golem-install … --yes` with **no sudo**. golem-install needs root (it
repartitions the disk and writes `/var/log/golem-install`), so it dies at the
first privileged step — `mkdir -p /var/log/golem-install` (`install.nix:184`) —
BEFORE the logdir and the ERR trap that would record why. The TUI's read-loop
then DISCARDS golem-install's output (`install-cli:3663-3667`, "the log stays
off the screen"), so a stranger sees only "The install stopped — the log is
above" over an empty log. This is exactly why **"TUI-driven full product
install" was still OWED**: the 8e gate proved golem-install via SSH-driven
INDIVIDUAL flags (as root) and proved the autostart LAUNCHES, but never drove
the product autostart to a finished install.
- **PROVEN at the recut gate (2026-09-22, VM):** drove the full guided TUI
  (language→user→password) to "Install Golem?" → stop; `vda` unpartitioned,
  logdir empty. Re-ran the SAME answers file by hand as `nixos`
  (`golem-install --answers /tmp/golem-answers --disk /dev/vda --yes`) → same
  stop. Prefixed **`sudo`** → the install ran to completion: format → fs →
  seed → probe → **BAKED toplevel direct-copy, offline** → bootloader →
  "installation finished!" → 6/6. Booted the installed disk (removable EFI,
  #94) → clean quiet boot to `Golem login:` → **login as `max` works**
  (#101 usable-install, now proven on the recut). So the recut installs
  perfectly; the ONLY defect is the missing privilege.
- **fix (Max chose 2026-09-22: "sudo the whole autostart"):** `iso.nix`
  loginShellInit now runs **`sudo golem-setup-install`** — the whole product
  surface runs as root, so golem-install has the privilege it needs whichever
  step reaches for it. The medium's `nixos` user has passwordless sudo, and
  `sudo golem-setup` was already the lab idiom (the getty helpLine), so sudo
  resolves the same way. Simplest of the three (vs sudo-in-step_go or a
  self-elevating golem-install); the surface is an installer, root is fine.
- **VERIFIED (recut #2, VM, 2026-09-22):** rebuilt the ISO with the fix, booted
  "Install" → the autostart TUI came up (as root), drove it (English) to
  "Install Golem?" → ENTER → the install ran to completion and **rebooted at
  6/6 with NO manual sudo** (a failed install shows "stopped" + a shell; a
  reboot is the 6/6 done trigger, step_go). The fresh target disk grew to 5 GB
  (a real system written). The TUI-driven full product install is no longer
  owed — it works.
- **where:** `iso.nix` (loginShellInit). **size:** one line, done.

### 102. THE COMODORE'S PER-MACHINE FILES WERE COMMITTED AGAIN — a leaked install-drop that pollutes CI and would ship in the ISO seed — [FOUND + FIXED 2026-09-22 · the recut · fba74c5's recurrence, closed structurally with a gitignore]
Preparing the recut, `hosts/target/` held FOUR committed files —
`golem-hardware.nix`, `hardware-configuration.nix`, `machine.nix`,
`modules.nix` — all the COMODORE's (Pentium T4200 / 1931 MB / BIOS, its
hostname AND its hashed password). Both `hosts/target/default.nix` and
`flake.nix` say plainly that the published repo has NONE of these ("`nix flake
check` on the plain repo must stay green"); they materialise only when an
install DROPS them into a seeded checkout. Committed here they:
- **broke facts-matrix (#98's procedure half):** `mkTarget` composes
  `golemModules ++ [ ./hosts/target ]`, so the comodore's facts leaked into
  EVERY matrix row — the `floor` row especially, whose whole point is "no
  detection → safe defaults".
- **would ship in the ISO seed:** `git archive` includes tracked files, so the
  installer's `/etc/golem/src` would carry the comodore's hostname + password.
- **kept RECURRING:** fba74c5 removed them once ("swept into tracking AGAIN
  during the #44 build"); the comodore session (6efe957) re-committed them,
  because `.gitignore` deliberately UN-ignored `hosts/target/` (the drops had
  to be committable on an installed machine's seed — the old assumption).
- **fix — git-rm + a narrowed gitignore:** removed the four from tracking; the
  `.gitignore` now re-ignores the per-machine drops (golem-hardware /
  hardware-configuration / machine / modules / postinstall-questions) while
  keeping `default.nix` tracked. SAFE because the installed seed is a PLAIN COPY
  (`install.nix` `cp -a`, no `git init`), so its path-flake self-rebuild reads
  the drops from DISK — it never needed them git-tracked. #88's "unknown"
  `configurationRevision` is the tell: a git seed, even dirty, yields dirtyRev,
  not "unknown". The shipped `.gitignore` is inert in the seed (no git there).
  If #35b ever makes the seed git-based, the install flow force-adds them.
- **where:** `.gitignore`, `hosts/target/` (four files removed). **size:** done.

### 101. 8e USABLE INSTALL — gen-1 is loginable (password + SSH key) on the opt-A generic system, verified — [2026-09-18 · Max: "take on the usable-install piece next"]
The opt-A direct-copy installs a GENERIC baked toplevel that never imports this
machine's machine.nix, so its owner had no password and no key — the machine
booted to a login nobody could pass. **Fix (install.nix, step 5b, after
nixos-install):** apply the answers IMPERATIVELY into /mnt — `chpasswd -e` for
the owner's hashed password (via `nixos-enter`), and write the SSH key to
`~owner/.ssh/authorized_keys`. This STICKS because Golem sets no
`users.mutableUsers` → the NixOS default (true) holds → activation does not
reassert /etc/shadow or ~/.ssh. The seed's machine.nix still carries the
DECLARATIVE answers (owner, hostName, hashedPassword, keys), so the first
`rebuild-golem` makes them permanent AND swaps the generic hardware config for
this box's measured one. Offline, no rebuild at install; harmless on the
from-seed path (same values re-applied). Hostname stays the baked default until
that first rebuild (cosmetic, not a login blocker).
- **VM-PROVEN on the FLOOR (hardest case — an unbaked VBox+unknown-GPU machine):**
  installed with `--password-hash <sha512> --lab-ssh <key> --hostname golembox`,
  clean sync, booted the disk alone → **logged in as `max@Golem` over SSH with
  the key** (shell zsh), **and the console password works** (`sudo -S` with
  `golemtest123` → root; wrong password rejected). machine.nix on the installed
  system carries `hostName="golembox"` + hashedPassword + the keys for the first
  rebuild. Every install path gets this (the personalize step runs after any
  nixos-install), so exact-match class installs are usable too.
- **CONVERGENCE TO IDEAL — works ONLINE, offline is a deliberate non-goal
  [investigated + decided 2026-09-18].** `rebuild-golem` (→ #golem-minimal, via
  base/loop.nix's flakeAttr default) converges gen-1 → the IDEAL per-machine
  system. VM-PROVEN ONLINE on the exact-match install: `nixos-rebuild switch
  --flake …#golem-minimal` built `nixos-system-golembox`, activated **gen-2**
  with the MEASURED hardware-config (fstab now by-uuid, ESP fsck + swap units) +
  real hostname + declarative creds. This is Max's L2 rung (online for the
  ideal). The FLAKE EVAL itself works offline (inputs resolve from the seed's
  cached lock; version now matches the bake, `…20260829.c5c4a43`, not the old
  `19700101.dirty`). What does NOT work offline: the rebuild must BUILD its thin
  per-machine glue (the initrd trimmed to the measured modules, os-release, the
  toplevel), and a gen-1 disk carries only the RUNTIME closure — no toolchain —
  so it tries to build stdenv/initrd offline and dies. `system.includeBuildDependencies`
  would fold the whole build closure onto the disk, but it is the sledgehammer
  (every package's -dev/-debug/source) — realizing it timed out and would blow
  the 8 GB-stick budget, so it was tried and REVERTED. **Decision:** gen-1 is
  fully usable offline; convergence to the ideal is ONLINE (matches the L1-baked
  / L2-online ladder). A curated on-disk toolchain for offline convergence is a
  possible future effort, weighed against stick size — not shipped.

### 100. 8e DEEP DOUBLE-CHECK — A/B/C FIXED + never-fail PROVEN END-TO-END to multi-user (unbaked VBox → floor → login+sshd); E was a harness artifact (sync-before-quit), D latent; integrity all-green — [2026-09-18 · Max: "run deep debug test … then we move on", then "E now"]
A hands-on audit of the whole 8e install path (bake machinery, matcher,
autostart, chooser throw-safety). **Verified SOUND:** firmware override flips
ONLY the boot leaf per class (no leakage); all 18 baked toplevels incl. both
floors are in the `bakedMatrix` closure (offline-installable, 0 missing);
`loginShellInit` is confined to the Install specialisation (Start never
autostarts); firmware detect emits exactly `bios`/`uefi` (matches manifest +
exact-match is implicitly firmware-correct, the boot leaf is in the leaf-list);
**exact-match integrity holds** — install evals `$seed/…/choose.nix` from
`golemSrc`, the SAME tree `bakedManifest` baked from, and **all 8 fixtures
exact-match their correct baked entry** (acer→acer-uefi … asus→asus-uefi w/
nouveau-floor, comodore/hp→bios). Prepare tolerates a chooser throw (guarded).
- **HOLE A — the installer floor was gated behind a successful chooser [FIXED +
  unit-tested; ISO-gate owed].** `install.nix` step 5 had
  `if [[ -r manifest && -n "$leaves_json" ]]` wrapping BOTH exact-match AND the
  floor. So if the leaves eval returned EMPTY — chooser `throw`, bad facts, any
  nix error — the floor was SKIPPED and it fell to an offline from-seed build
  that DIES on a stranger's machine. The floor needs only `$firmware`, never the
  leaves. **Fix:** split — `-n "$leaves_json"` now guards only the exact-match;
  the floor runs on any `-z "$system"`, outside that guard. **Proven:** a
  VirtualBox facts file → chooser throws → leaves empty → floor-uefi selected
  (direct copy, offline). `golem-install` rebuilds clean (shellcheck passes).
- **HOLE B — the chooser THREW on VMware/VirtualBox/Hyper-V [FIXED, Max blessed
  "floor it to []" 2026-09-18].** `choose.nix` `refuse "virt"` threw when
  `vmGuest ∉ {qemu,none}`, and the census (`hardware-detect.nix:344-349,453`)
  DOES emit `vmGuest = "vmware"|"virtualbox"|"hyperv"`. **Fix:** the `virt` group
  now floors to `[ ]` (else-branch) with an honest `virtSkip` note, exactly like
  the `gpu2` group — a missing guest-agent leaf is not a boot risk, unlike a GPU
  driver, so the guest boots generic and a real leaf can land later. The GPU
  tripwire STAYS (a display driver is not optional). **Proven:** a VirtualBox
  guest now yields `grub-efi cpu/intel-microcode gpu/auto zram-tier1 swap disk`
  + a virt skip (no throw); and the change is ZERO-regression — the baked
  manifest hash is IDENTICAL and all 8 fixtures still exact-match their class
  (qemu still gets qemu-guest). Net: hypervisor guests get a climbable
  modules.nix (floor install now, self-rebuild to their proper config later),
  instead of a dead install (pre-HOLE-A) or a bare unclimbable floor (HOLE-A
  only).
- **HOLE C — the opt-A baked install BOOTS TO EMERGENCY: the generic initrd
  lacked the target's disk controller [FIX IMPLEMENTED, Max blessed "broad initrd
  in the bake" 2026-09-18; initrd-verified, ISO re-gate pending].** Fix:
  `bakedFakeDisk` (flake.nix) now sets a broad `boot.initrd.availableKernelModules`
  — the virtio family (`virtio_pci/mmio/blk/scsi`) + SATA/PATA/AHCI + nvme/sd/sr +
  USB storage + eMMC/SD + common SAS/RAID — additive to includeDefaultModules, so
  it only ever ADDS bootability. Every baked toplevel now boots on any common
  controller at gen-1; the first self-rebuild measures + trims to the real
  hardware. VERIFIED: the rebuilt floor initrd now carries `virtio_blk virtio_pci
  virtio_scsi virtio_mmio` (was absent). Below is the discovery record.
  The definitive live floor gate (VirtualBox+unknown-GPU facts → chooser floors
  → `golem-install` picks floor-uefi → "Installation finished. No error." offline,
  ALL PROVEN) then FAILED to reach multi-user: the installed floor disk, booted
  alone, hangs `A start job is running for /dev/disk/by-label/golem (…/1min 30s)`
  → systemd-initrd **emergency mode** (root account locked). Root cause, proven
  by unpacking the baked initrd: it carries only the DEFAULT modules
  (`ahci nvme sd_mod xhci libahci`) and **NO `virtio_blk`/`virtio_pci`** — so on
  a virtio-blk machine the initrd never sees `vda`, the root device never
  appears, boot times out. The opt-A DIRECT COPY installs the baked toplevel
  as-is, skipping the per-machine `nixos-generate-config` that normally adds the
  measured `boot.initrd.availableKernelModules`. **Blast radius:** any machine
  whose disk controller is outside {ahci,nvme,sd_mod,xhci} — notably ANY
  virtio-blk VM (a huge share of "a stranger tries Golem in a VM") — installs but
  cannot boot. Real AHCI/NVMe/SATA/USB laptops likely boot (those modules ARE in
  the initrd), which is why the roster (from-seed, MEASURED configs) never hit it
  and the earlier opt-A gate (only checked "GRUB starts") missed it. This means
  8e's install, as built, is NOT never-fail to multi-user. **Fix options (Max's
  call):** (a) bake a BROAD `boot.initrd.availableKernelModules` (add the virtio
  family + common controllers) into every baked toplevel via `mkMinimal`/the
  `bakedFakeDisk` module — the true "boots on anything" floor, keeps opt-A direct
  copy [recommended, low-risk: only ever adds bootability]; (b) first-boot
  auto-rebuild to the measured hardware-configuration.nix (needs the deferred
  reproducible-rebuild, the deep "usable install" work); (c) a+b (broad initrd
  for gen-1, then rebuild to ideal). Proven with `-vga std`+virtio-blk +
  rigged facts; the exact-match class path uses the SAME generic initrd, so it is
  affected identically on any non-{ahci,nvme,sd_mod,xhci} controller.
- **HOLE E — grub rescue `normal.mod not found` = A TEST ARTIFACT, NOT a Golem
  bug [RESOLVED 2026-09-18].** Chased it into the grub-rescue prompt: `set`
  showed correct `root='hd0,gpt1'` + `prefix='(hd0,gpt1)/grub'`; `ls /grub/`
  listed `x86_64-efi/`; but `ls /grub/x86_64-efi/` returned only a PARTIAL set
  (~15 of 250 modules) and `insmod normal` → not found. `fsck.fat -v` on the ESP
  revealed the cause: **corrupted LFN directory entries** ("Long filename
  fragment 'video_cirrus.' found outside a LFN sequence — start bit missing",
  boot-sector≠backup). GRUB's strict fat driver stops at the malformed LFN run;
  Linux's lenient vfat reads past it (so `find`/`ls` on the medium saw the files).
  **Cause: my harness hard-quit QEMU (`quit`) right after the install without a
  guest sync, dropping unflushed FAT writes** — the real product flow REBOOTS
  after the 6/6 marker (a clean sync/unmount). PROVEN: re-installed, then
  `sync; umount -R /mnt` before power-off → `fsck.fat` clean (`344 files`, no LFN
  errors) → the disk **booted to `Golem login:` on tty1 AND sshd answered
  (`Permission denied (publickey)`) = FULL MULTI-USER.** No code change needed;
  the harness lesson (sync before hard-quit) is noted in vm.md. Below is the
  original discovery record, kept for the trail.
- **[superseded — kept for the trail] HOLE E discovery: opt-A UEFI boot landed in
  `grub rescue> normal.mod not found`.** With
  the HOLE-C fix in, the re-gate floor install succeeded ("using the generic
  FLOOR" → "Installation finished. No error." offline), but booting the installed
  disk in OVMF hit `error: file '/grub/x86_64-efi/normal.mod' not found →
  grub rescue>` — BEFORE grub.cfg. Inspected the ESP: normal.mod IS present at
  exactly `/grub/x86_64-efi/normal.mod`, grub.cfg correctly does
  `search --fs-uuid B478-EC19` (= the ESP's real UUID), BUT the CORE image
  (`EFI/BOOT/BOOTX64.EFI`) embeds a bare `prefix` with **no fs-uuid search and no
  `search`/`search_fs_uuid` module built in** — so `$root` never resolves in OVMF
  and `/grub/...` points nowhere. Behavior is INCONSISTENT with OVMF NVRAM state
  (pre-fix floor-target booted GRUB via its install-time NVRAM entry → reached
  the kernel; floor2 grub-rescues via both its install NVRAM and fresh/removable
  vars; floor-target+fresh-vars = blank) → reads as a FRAGILE UEFI-removable
  boot-path interaction, not obviously a regression (nothing I changed touches
  GRUB, and the metal roster — real firmware, from-seed installs — boots fine).
  **Consequence:** "opt-A floor reaches MULTI-USER" is still UNPROVEN in the VM —
  the install + the initrd fix are proven, but a clean end-to-end boot of a
  direct-copied baked system to a login is blocked by this GRUB/OVMF murk (and
  compounded by the generic-system no-login gap). **Follow-up (focused, separate
  from never-fail):** why the opt-A removable GRUB core can't resolve $root under
  OVMF — likely a grub-mkimage prefix/search-module issue in the bootloader
  install for a direct-copied (non-generate-config) system; compare a from-seed
  install's core image; consider `efiInstallAsRemovable` + an fs-uuid search in
  the embedded core. This is the next thing to chase before 8e can claim a
  verified multi-user boot.
- **LATENT D — `gpu2="other"` is not folded to a safe value [low].** Primary
  `gpu` folds `other`→`auto` (`hardware-detect.nix:162`); `gpu2` (line 180) does
  NOT. Harmless today (the `gpu2` group floors to `[]`, no refuse) but a future
  `refuse` on gpu2 would make `gpu2="other"` an instant hole. Optional one-line
  fold for symmetry.
- **where:** `Installer/preinstall/install.nix` (HOLE A, fixed),
  `system/Modular/choose.nix` (HOLE B/C), `system/hardware-detect.nix`.
- **Owed:** rebuild the ISO to carry HOLE A (+ HOLE B if Max blesses it), then
  the **live floor install→boot** gate now exercises HOLE A's path for real.

### 99. 8e — THE ALL-IN BAKED INSTALLER (the Omarchy model) — ISO builds (3.0 GiB); opt-A install + coverage + autostart all VM-gated; live floor-boot + TUI product install still owed — [IN PROGRESS 2026-09-18 · Max: "reliable as fuck, never fail" · "Cobertura/autoarranque first"]
Max's end goal, decided after the math: **no online install / no 50 G ISO —
BAKE the whole hardware matrix, install by LOCAL COPY.** DHH's Omarchy does
~1-min installs exactly this way (image on the stick, copy-not-download).
- **DONE + measured:** `flake.nix` `bakedMatrix` (linkFarm of every fixture's
  minimal toplevel, `bakedFakeDisk` by-label golem/ESP) → `iso.nix`
  `system.extraDependencies`. **All-in ISO = 2.91 GiB** (union 6.64 GiB
  uncompressed; squashfs + medium overlap compress it), fits 8 GB with ~4.5 GiB
  spare. btop added to base/core.nix. Preinstall flake made self-contained
  (`../../system/...` → `"${golem}/system/..."`), builds via
  `--override-input golem path:<clean git tree>`.
- **VM BOOT-GATE PASSED (2026-09-18, vm.md):** the 2.91 GiB all-in ISO boots
  (UEFI/OVMF), comes up `golem-installer`, carries all 8 class closures offline,
  census runs (virtio/intel/bios), floor logic confirmed.
- **VM INSTALL-GATE FAILED + CAUGHT A REAL GAP (2026-09-18):** with golem-install
  building golem-minimal offline from the seed, a VM install died building
  cmake/glib/elfutils from SOURCE — the seed-rebuild is
  `…19700101.dirty`, the bake is `…20260829.c5c4a43`, DIFFERENT evals →
  `--offline` can't reuse the bake. **"Rebuild from the seed at install" cannot
  reuse the baked matrix.** ARCHITECTURE FORK (awaiting Max): **(A) install the
  BAKED toplevel DIRECTLY** (`nixos-install --system <baked class>`, local copy,
  no rebuild — can't mismatch; per-machine hostname/owner/swap/wifi via a
  first-boot rebuild on the target where the closure is present) — recommended;
  or **(B)** make the seed-rebuild byte-reproduce the bake (fragile). This is
  why we VM-gate — the gap was caught before shipping.
- **OPT A WIRED + PROVEN (2026-09-18):** `flake.nix` `bakedManifest` (leaf-list →
  toplevel JSON) + `iso.nix` `/etc/golem/baked-manifest.json` + `install.nix`
  matches the machine's chosen leaves to a baked toplevel and
  `nixos-install --system <baked>` (direct copy, no rebuild). Fall back to the
  from-seed build only when no baked match. **VM-PROVEN:** UEFI VM → live leaves
  == baked `qemu` → `nixos-install --system` copied paths + installed GRUB-EFI,
  **"Installation finished. No error." offline, no rebuild** — the mismatch is
  gone; OVMF then started the disk's removable grub-efi (bootable). One-word
  unblock: the leaves eval needed `--impure`.
- **COBERTURA + AUTOARRANQUE DONE + VM-GATED (2026-09-18, Max: "Cobertura/
  autoarranque first"):**
  - **Coverage:** `flake.nix` bakes+manifests **18** entries — 8 classes × both
    firmwares (16) + `floor-bios`/`floor-uefi` (`isFloor:true`). `install.nix`:
    exact leaf-list → the ideal class, else the floor-for-firmware, both DIRECT
    copies. NEVER-FAIL selection proven on a real weird machine (9-leaf unbaked
    combo → exact miss → floor-uefi, whose 1017-path closure is 0-missing
    offline). Resolves owed items (2) coverage and the ⚠ COVERAGE note.
  - **Autostart:** new `golem-setup-install` wrapper (`setup.nix`) = the surface
    with neither `GOLEM_REHEARSE` nor `GOLEM_LAB` (mode ladder: neither = the
    full real install); the `install` specialisation (`iso.nix`) autostarts it
    on tty1 via `environment.loginShellInit`, `tty`-guarded. Resolves owed (3).
    **Bug caught in the gate:** NixOS `/etc/profile` does NOT source
    `/etc/profile.d/*.sh` — the first `environment.etc."profile.d/…"` cut
    silently no-op'd; `loginShellInit` fixed it. VM-PROVEN: Install boot →
    autologin → surface live on tty1 in product mode (no REHEARSE/LAB in its
    `/proc/environ`), SSH stays on a pty (guard holds).
- **STILL OWED after opt A:** (1) a USABLE install — the baked-generic has no
  owner/hostname/sshd (no machine.nix); applying the surface's answers means a
  FIRST-BOOT rebuild that must REUSE the baked deps (the deeper reproducibility
  the gen-1 copy sidestepped — likely needs mkMinimal==golem-minimal so the
  rebuild matches the bake). (4) full multi-user boot capture + a **live floor
  install→boot** (selection+closure proven; the disk-boot of the floor is the
  last gold-standard never-fail proof) + a **TUI-driven full product install**
  (autostart → 6 answers → confirm → installed system boots).
- **⚠ COVERAGE (the never-fail requirement for opt A):** the match is EXACT on
  the leaf-list, and firmware SPLITS every class (bios→grub-bios vs
  uefi→grub-efi are different leaf-lists). The current 8 fixtures each carry
  ONE firmware, so e.g. a BIOS-qemu machine won't match the UEFI-qemu bake and
  falls through. For never-fail the bake must cover {GPU class × firmware ×
  common tier} AND a **floor entry** (gpu=auto/unknown, both firmwares) so the
  generic floor is itself directly-installable. Follow-on: expand
  `bakedFixtures` (or synthesize the permutations) so every reachable leaf-list
  — including the floor — is a baked, direct-installable entry.
- **The never-fail ladder (Max's demand):** L1 baked matrix → L2 online pull for
  the rare unbaked driver → **L3 the generic floor (`gpu/auto`, boots on
  anything)**. Proven the chooser FLOORS (not throws) on nothing-detected; the
  floor is a CI row. Census degrades every fact to a safe default. For the
  PRODUCT the chooser must floor-not-throw on unknown (lab throws for the CI
  tripwire) — confirm the census never emits an unfloorable GPU value.
- **STILL OWED:** (a) `golem-install` offline path — pick the chosen toplevel
  from the medium's baked store (not a delivery/build); ask the store DB, not
  `[-e]` (#85). (b) `golem.install` boot autostart: Install-boot → `golem-setup`
  → `golem-install`, gated `ConditionKernelCommandLine=golem.install`. (c) L2
  online fallback for a driver outside the bake. (d) **VM-GATE (§3): boot the
  ISO, install a deliberately-weird fake machine, watch it land on `gpu/auto`
  and boot** — the never-fail end-to-end proof. (e) fold the #62–#98 queue.
- **where:** `flake.nix`, `Installer/preinstall/{flake,iso,install,setup}.nix`,
  `system/hardware-detect.nix` (census floor), `system/Modular/choose.nix`.

### 98. THE FULL-SYSTEM FACT MATRIX IS THIN — no lenovo row, and it can't run from a seeded checkout — [FOUND 2026-09-18 · the lenovo nvidia audit · needs-Max on scope]
Two related gaps the lenovo audit surfaced in `system/hardware/matrix.nix`:
- **Coverage:** its header claims "the committed lab fixtures' facts files are
  permutations too, so a … change that would regress a past machine fails CI in
  seconds" — but only **2 of 8** committed fixtures are `facts-matrix` rows
  (`acer-e5-573`, `qemu-virtio`). The nvidia coverage is a SYNTHETIC
  `nvidia-hybrid-ada` row hard-coding `ramMB=32768`/`cores=20` and omitting
  `gpu2`/`gpu2Health`/`panelDpi=239`/`hasBluetooth`. The machine just proven on
  metal (lenovo) has **no** facts-matrix row for its real fact-set. Fix: add
  `fixture-lenovo-slim-pro-9-16irp8` (and ideally the other real fixtures) as
  rows.
- **Procedure:** `facts-matrix` **cannot be run from an install-seeded
  checkout** — `mkTarget` composes `golemModules ++ [ ./hosts/target ]`, so the
  installer's dropped `golem-hardware.nix` (real lenovo facts) leaks into EVERY
  row, and the `floor` row (whose point is "no detection → safe defaults")
  fails on nvidia/laptop-power/resume it should never see. Confirmed: a pristine
  tree (dropped files removed) makes `facts-matrix` green + `nix flake check` =
  `all checks passed!`. So an installed Golem can self-prove chooser-matrix /
  minimal-matrix / keyboard-table / timezone-defaults, but NOT facts-matrix.
  A future audit must be told this or it reads the `floor` failure as a
  regression. (Adding the lenovo row would have caught this as a side effect.)
- **where:** `system/hardware/matrix.nix`; `hosts/target/default.nix` (already
  documents the "pristine repo stays green" premise). **size:** small-medium;
  scope is Max's (how many real fixtures become facts rows).

### 97. `lspci` IS NOT IN THE MINIMAL IMAGE — the driver-binding audit must read sysfs — [FOUND 2026-09-18 · the lenovo nvidia audit · small]
The rule-6 / GPU audits ask for `lspci -nnk`'s "Kernel driver in use:" line, but
**pciutils ships only in the fat/desktop set, not stage-0 minimal** — so the
literal command fails on a freshly installed machine. The lenovo audit read the
binding from **sysfs** instead (`/sys/bus/pci/devices/<bdf>/driver` →
`…/drivers/nvidia`, and the device `uevent`'s `DRIVER=`), which is the SAME
source `lspci` itself reads, so the fact stands. Fix (pick one): add `pciutils`
to the minimal closure (a few hundred KB — convenient for every future hardware
audit), OR make sysfs the canonical driver-binding check in `firstboot-audit.sh`
and the audit instructions. **where:** `system/Modular/base/*` (if adding
pciutils) or `tools/firstboot-audit.sh`. **size:** small.

### 96. THE FACETIME HD WEBCAM — a new leaf, fact and chooser rule; PROVEN capturing on the installed MacBook — [BUILT + INSTALLED + live-captured 2026-09-18 · the macbook · must ride the recut]
Max, at the macbook: *"IMPORTANT!! drivers | audio | wifi | BT | WEBCAM |
etc. …it is important that Golem install the webcam and make it functional."*
The 2013 Air's camera is the Broadcom 720p **FaceTime HD (PCI 14e4:1570)** —
an out-of-tree `facetimehd` (bcwc_pcie) module + an ISP firmware blob nixpkgs
extracts from a 2 MB byte-range of Apple's OSXUpd10.11.5.dmg (unfree, but
cached on cache.nixos.org — no live dependency on Apple's CDN).
- **Made modular, the Golem way** (spec growth rule + rule 4): new census
  fact **`hasFacetimeHD`** (probe detects 14e4:1570), new leaf
  **`quirks/facetimehd.nix`** (`hardware.facetimehd.enable` +
  `allowUnfreePredicate` scoped to the blob, composes with broadcom-wl's
  `allowInsecurePredicate`), chooser rule, matrix assertion + fixture.
- **THE GOTCHA — the fact must be declared TWICE.** `golem.hardware` options
  live in BOTH the Modular `base/options.nix` AND the fat `system/hardware.nix`;
  `golem-postinstall-questions` evaluates `lib.golem.postinstallQuestions`,
  which routes through the FAT config, so a fact declared only in the Modular
  set makes prepare die at the postinstall-questions drop ("option
  `golem.hardware.hasFacetimeHD' does not exist"). Declare new facts in both.
- **THE OTHER GOTCHA — golemSrc must be git, not `path:`.** Building the
  patched engine with `--override-input golem path:$HOME/Golem` baked the
  WHOLE working tree (70 GB of build artifacts) into the closure. The frozen
  golemSrc is git-based (3 MiB). Use a clean tree (`git archive HEAD` +
  overlay the uncommitted deltas) for `--override-input golem path:<clean>`.
- **PROVEN:** live on the medium before the wipe (720p frame), and on the
  INSTALLED system — `/dev/video0` auto-appears at boot, `facetimehd-firmware`
  + `facetimehd-calibration` both load (the `1871_01XX.dat` error is gone),
  captured a 1,843,200-byte frame. See macbook.md.
- **where:** `system/Modular/quirks/facetimehd.nix` (new),
  `system/Modular/base/options.nix`, `system/hardware.nix`,
  `system/hardware-detect.nix`, `system/Modular/choose.nix`,
  `system/Modular/matrix.nix`, `Installer/preinstall/fixtures/macbook-air-2013/facts.nix`.
- **owed:** all uncommitted; ride the recut (8e) so the webcam reaches the
  image, and run `nix flake check` to confirm the updated chooser/effect
  matrices are green (validated by hand: the chooser emits the macbook's 10
  leaves incl facetimehd; postinstall-questions returns []).

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
- **BOTH FIRMWARES, SAME MENU (2026-09-15):** live on the acer
  (UEFI/GRUB-EFI) and the comodore (2008 BIOS, MBR chainload) — booted,
  healthy, verified on the wire. #92 stops being a design goal here and
  becomes a fact on metal.
- **owed:** the ISO's own menu at the recut (its grub is unpatched, so
  it ignores `item_align` and keeps the old look until then), so the
  medium finally matches the machines it installs.

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

### 87. A CHOSEN LEAF THAT DOES NOTHING, AND EVERY LAYER SAYS IT WORKS — thermald is a silent no-op on pre-RAPL Intel — [FOUND 2026-09-14 the comodore (Penryn) · CONFIRMED 2026-09-18 on the hp (Arrandale), a second microarch · rule-10 class · fix still needs-Max]
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
- **blast radius — the hp CONFIRMS it (2026-09-18):** the **hp** (i5 M 460
  Arrandale, family 6 model 37 — also pre-Sandy-Bridge) booted its
  clean-image stage-0 with `thermald` **inactive** and **0 failed units**,
  identical to the comodore on a different microarchitecture. Prediction is
  now a result: two pre-RAPL machines, same silent no-op, same green audit.
  The acer (Broadwell) and asus (Haswell) are post-RAPL and genuinely run
  it — their records saying "thermald active" are correct. So the fix's
  motivation is now doubled: this is a class, not a comodore quirk.
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
