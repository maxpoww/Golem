# Golem OS — Roadmap (now → finished ISO → the soul)

> **Two arcs** (decided 2026-08-29): **Arc 1 — reach metal**: take what
> exists, make it work *perfectly*, and get it onto an ISO that installs
> Golem on other PCs. Feature freeze: no new OPTIONS surfaces, no module
> growth — incompleteness is accepted, brokenness is not. **Arc 2 — grow
> the soul**: after the ISO, wire the Brain, build out the modules, the
> phone, the everything. Module ideas keep landing in `optionsmodules.md`
> during Arc 1; they just don't get built yet.
>
> Section IDs (S1…S11, SH, W-A) are stable names; the ARC ORDER below is the
> order of work. Each section has `todo/todo<id>.md`. Scope sources:
> `Golem.md` · `features.md` · `apps.md` · `android.md` · `optionsmodules.md`.

## ARC 1 — Reach metal: S1 ✔ → SH (running) + S2 ✔ → S7 → S9

*(S2 pulled forward from Arc 2 by Max, 2026-08-29 — done that night: the
Brain streams into the daemon, window pill engine-driven with a degrade
path. SH bug-catching continues in parallel.)*

### S1 — Land & clean ✅ (2026-08-29)
Dictionary branch landed on main, docs de-drifted, plan versioned.

### SH — Harden what exists *(new; the "working perfectly" pass)*
Everything already built becomes reliable enough to hand to a stranger:
bug sweep of the live surfaces, cold-start on foreign hardware (no Max
homedir assumptions), graceful degradation when deps are missing, daily
driving with notes. Freeze rule: fix, don't grow.
**Exit:** a week of daily use with zero surprises; every known bug fixed or filed.

### S7 — The Golem system flake
ONE flake = a complete Golem PC: custom Hyprland, waverunner,
options-notify, dictionaries, defaults, theming, users — *and the stopgap
kit*: curated plain tools for what OPTIONS doesn't cover yet (network,
audio, bluetooth GUIs) so an installed machine is livable today; each
stopgap dies when its Arc-2 module ships. `nixos-rebuild build-vm` = the
test loop.
**Exit:** one command produces a bootable Golem VM a stranger could use, including getting online.

### S9 — Installer & ISO
Live ISO boots into real Golem; guided install (disk, user, wifi, done)
instantiates the S7 flake. Test on the VM, then real metal, then a machine
that isn't yours.
**Exit — THE Arc-1 exit:** ISO on a USB stick → working Golem PC on another computer, no terminal, no Max in the room.

*(S10-lite rides along: golem-os.com gets a download link + honest install
notes when the ISO exists. The full release push stays in Arc 2.)*

## ARC 2 — Grow the soul: S2 → S3 → S4 → S5 → S6 → S8 → S10 → S11, + W-A

### S2 — The Spine (Brain ↔ Body) ✅ (2026-08-30, pulled into Arc 1)
Done: `brain.rs` bridge (tokio thread → calloop channel), window pill
engine-driven with poll fallback while the compositor layer is dark.
Unblocks W-A. Remaining surfaces migrate in S3.

### S3 — OPTIONS modules *(continuous once open)*
The production line: migrate live surfaces onto the Brain, then build the
`optionsmodules.md` queue — including finishing the incomplete ones
(clipboard/dictionary have known gaps, parked on purpose during Arc 1).

### S4 — System controls
Wi-fi, bluetooth, audio, brightness, power, displays as OPTIONS modules.
Each one shipped retires its Arc-1 stopgap tool.

### S5 — The app set
`apps.md`: golem-apps.nix, theming pass, mime defaults, browser decision,
Nautilus handoff, touch check.

### S6 — Configuration UI
Settings as a surface; writes declarative intent (features.md §3 inventory).

### S8 — First run & onboarding
Diegetic tour, skill seeding, "first five minutes" test with a real human.

### S10 — Website & release
Manifesto ✔ → story, motion screencasts, generations/"roll back" headline,
alpha release of **Golem 26 "Uprise"** proper.

### S11 — Everyone-hardening *(cross-cutting, closes last)*
i18n (Spanish first), keyboard-only, accessibility, non-expert testing.

### W-A — Golem × Android *(parallel, any time after S2)*
`android.md`: fork KDE Connect → Golem app; phone collector; P1→P4.

---

**Cross-cutting rules (always):** Arc-1 freeze — fix, don't grow · coherence
over features · see it before you believe it (verify-ui) · dt-based motion ·
safety at the OS edge (no unprompted rebuild/switch) · new ideas →
`optionsmodules.md`, never straight to code.
