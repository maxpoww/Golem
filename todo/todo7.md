# todo7 — S7 The Golem system flake

<!-- Coarse on purpose — break down on entry. -->

- [x] New repo (or `golem/` in the site repo?): the distro flake
      → Max's call 2026-08-30: the flake lives at the ROOT of ~/Golem (the
      plan repo doubles as the distribution) and pushes to the public
      github.com/maxpoww/Golem. `github:maxpoww/Golem` is directly buildable.
- [x] Compose: custom Hyprland 0.55.4 (+ Lua API) as a flake input/output
      → via the pinned nixpkgs input (exact live channel rev 21ea275a), same
      programs.hyprland the machine runs today; repin deliberately on bumps.
- [x] Compose: waverunner + options-notify + dictionaries + waverunner-apply
      → waverunner flake input: daemon (dictionaries wrapped in) + ctl via
      its homeManagerModules.default (systemd user service replaces the
      hyprland.lua waverunner-dev exec — no more debug builds on PATH);
      options-notify via its nixosModule; waverunner-apply REWRITTEN for the
      flake world (generates system/home/waverunner-packages.nix INSIDE the
      repo + git add — flakes can't see untracked files — and rebuilds with
      --flake; gated on golem.flakeDir, off in the VM; autoUpgrade dropped:
      flake upgrade = input bump, story TBD).
- [ ] Compose: `golem-apps.nix` (from S5)
- [x] Golem defaults: theming, fonts, hyprland.lua, session startup
      → home.nix/zsh/foot/nvim/yazi/webapp icons ported verbatim;
      hyprland.lua's three /home/max assumptions rewritten at build time
      (waveview .so from store path, waverunner via systemd, ctl from PATH).
      CAVEAT until cutover: hyprland.lua now exists in BOTH /etc/nixos and
      the flake — edits must land in both or they drift.
- [ ] Stopgap kit: curated plain GUIs for network/audio/bluetooth (each
      dies when its S4 module ships in Arc 2)
      → started: pavucontrol + networkmanagerapplet in systemPackages,
      blueman already shipped; audit what else a stranger needs (wifi
      first-connect flow!) before ticking.
- [x] Ship chromium (webapp engine fallback — SH F2 resolves it at runtime,
      the flake must make it exist)
      → google-chrome ships via home.nix programs.chromium (unfree on), so
      F2's first-choice browser exists on every Golem machine.
- [x] Pin fonts: the UI font + the Nerd Font the glyphs need (SH F4 —
      renderer loads system fonts only; without them, tofu pills). Also set
      the fontconfig default sans to the chosen font (SH F7: the daemon
      requests generic sans-serif; today that aliases to a missing Noto
      Sans → silent DejaVu fallback, i.e. the UI font is currently
      accidental)
      → flake ships JetBrains Mono + its Nerd Font + dejavu_fonts, and pins
      fontconfig default sans to "DejaVu Sans" — today's accidental look
      made deliberate, zero visual change. Choosing Golem's REAL UI font
      stays open as a design call (Max + mockup, per project law).
- [ ] Ship `~/notification-fix` (Chrome ext: FB/Messenger/IG notifications
      on Wayland — no occlusion tracking) with the webapp profile via
      `--load-extension`; it lives ONLY in Max's homedir today — get it
      into a repo first
- [x] User/home layer (home-manager module wired in)
      → home-manager flake input (release-26.05, follows nixpkgs) as a
      NixOS module, useGlobalPkgs; home-manager.users.max = system/home/.
- [x] `nixos-rebuild build-vm` target — one command → Golem VM (this becomes
      the daily test loop for S8/S9)
      → `nixos-rebuild build-vm --flake .#golem-vm && ./result/bin/run-Golem-vm`
      hosts/vm.nix: no nvidia, virtio-vga-gl, 4G/4 cores, greetd autologs
      max into Hyprland, initialPassword golem. BUILDS clean (2026-08-30);
      first graphical boot still needs eyes.
- [x] Pin + document every input; the flake IS the distribution
      → DONE 2026-08-30 (Max: public): maxpoww/launcher flipped
      public + pushed to head, maxpoww/waveview created public. Both
      inputs repinned github:maxpoww/* (same revs, same narHash — zero
      rebuild); nixpkgs + home-manager were already GitHub pins. The
      flake is now buildable by ANY machine. Dev loop against local
      checkouts: `--override-input waverunner ~/launcher`.

- [x] **Ship a prebuilt package index with the flake** (from Round 2's VM
      crash-loop): waverunner's cold start builds its package index with
      `nix search nixpkgs ^ --json` (~3GB eval) + a `nix shell
      nixpkgs#nix-index` icon sweep — on a 4G machine the OOM killer took
      the whole service cgroup down and systemd respawned it: an INFINITE
      cold-start crash-loop on small hardware (5 daemon starts in 7 min,
      Chrome died as collateral). Invisible on the 32G host; the VM's first
      catch.
      → DONE (launcher `0fdafa7`, Round 5 below): the launcher flake
      builds the index as a derivation from its own pinned nixpkgs
      (nix-env eval → jq → new `waverunner build-index` CLI mode reusing
      the exact parse/filter/save path — 23.9k packages, v5 TSV). HM
      module wires WAVERUNNER_PKG_INDEX; when set it is AUTHORITATIVE
      (no runtime dump ever — a fresh dump could only diverge from the
      pinned system). nix-locate now runs from PATH (nix-index in
      runtimeTools), killing the second 3GB eval; env unset = old dev
      behavior. Icon hints are runtime-lazy (flathub/store fetchers);
      build-time hints via a nix-index-database input = possible later.
      VERIFIED: fresh-disk cold boot loads 23661 packages (prebuilt) in
      ~2s, 0 OOM; the afternoon's 4G repro config re-run — 0 OOM, ONE
      daemon start, desktop in ~1GB. 4G machines run Golem now.
- [ ] VM loop friction: host Hyprland swallows Super before QEMU sees it,
      so Golem binds can't be exercised in the VM from the host desktop.
      Idea: a host "VM mode" (submap that releases all binds + escape key).
- [ ] **F9 — "already in package list; treating as installed" is a lie
      while the rebuild runs.** The applier equates list-presence with
      installed; if the entry is mid-apply (status phase "building"),
      the pending install completes instantly, no GUI app exists yet,
      and the resolver falls through to the CLI-tile fallback — brave
      and gimp presented as terminals printing "is ready". Must consult
      apply-status.json (building = still pending). Launcher-repo.
- [ ] **F11 — the daemon clobbers packages.list at startup** ("seeding
      declarative package list with 0 attrs"): on start it REWRITES the
      list from its own managed state — on a fresh machine that's empty,
      so (a) any external/manual entries are silently destroyed (the
      apply security model explicitly calls the list "the ONLY
      user-writable surface" — the daemon treats it as a private cache),
      and (b) the rewrite itself triggers a pointless first-boot apply
      run: 8 minutes of input downloads + eval to rebuild an unchanged
      system, with every real install queueing behind it into F10's
      false failures. The list on disk must be the source of truth the
      daemon ADOPTS, not a mirror it overwrites. Launcher-repo.
- [ ] **F10 — a queued install is not a failed install.** The applier
      waits 120s for the apply UNIT to start; a long build keeps the
      oneshot busy, the queued path-trigger can't start it, and the
      daemon reports failure + reverts + retries in a loop while the
      first run is still legitimately building (signal-desktop,
      2026-08-30). Watch the status file (phase/mtime), not unit-start.
      Launcher-repo.
- [ ] VM loop niceness: qemu user-net (slirp) downloads at ~hundreds of
      KB/s — a first brave+gimp closure takes 10-20 min. Fine for
      correctness tests; consider virtio-net or a host-side cache if it
      gets old.
- [ ] **F8 — renderer init failure = shell silently dead forever.** Seen in
      the Venus experiment: wgpu couldn't create a surface, the daemon
      errored out, systemd's restart limit exhausted in seconds → no dock,
      no bar, no OPTIONS, and nothing tells the user why. The daemon (or
      its unit) needs a real degrade path: retry with backoff, fall back
      to a software adapter, or at minimum leave a visible breadcrumb.
      Launcher-repo work.
- [ ] VM-only: waverunner renders on llvmpipe (virgl gives GL, wgpu wants
      Vulkan) → dock is CPU-drawn, video can stutter with it. Venus
      (vulkan passthrough) tried 2026-08-30 and REVERTED — wgpu got no
      surface at all (F8 is its own finding). Acceptable for the test
      loop; revisit if the VM ever becomes a daily driver. Real hardware
      unaffected.

## Log

- Round 1 (2026-08-30, "lets keep going with the plan" — SH had nothing
  actionable left for Claude, all remaining boxes are Max's hands or the
  daily-driving clock): S7 OPENED. Max decided the flake pushes to the
  empty public github.com/maxpoww/Golem; since local ~/Golem shares the
  name and had no remote, the plan repo IS the distro repo — flake.nix at
  the root. Ported all of /etc/nixos into system/ + hosts/ (nvidia split
  host-side so the VM is hardware-free); /etc/nixos left untouched and
  live until Max cuts over (cutover = `rebuild-golem`, which the flake
  builds as `nixos-rebuild switch --flake $flakeDir#golem`). Both
  nixosConfigurations eval clean; golem-vm BUILT first try (compiled
  waverunner release binaries for the first time ever — the live session
  still runs debug builds from the checkout). Secrets scan of the plan
  docs before the public push: clean. NEXT: Max runs
  ./result/bin/run-Golem-vm and eyeballs the first foreign-hardware boot;
  then push launcher + waveview to GitHub and repin the two local inputs.
- Round 2 (2026-08-30, first VM boot): ✅ Max: dock, OPTIONS, overview —
  "its all there". Then: installed the YouTube webapp, played a video →
  "it crash, the whole thing restart somehow". Diagnosis (sshd + loopback
  :2222 added to the VM, journal read from the crashed boot's persistent
  disk): FOUR OOM-killer events in 6 min, every victim a ~3GB `nix`
  process inside waverunner.service — the cold-start `nix search
  nixpkgs ^` index dump (see the new prebuilt-index item above). Hyprland
  + greetd survived every kill (same pids across all four OOM tables):
  the "session restart" Max saw was the daemon crash-looping + Chrome
  dying (SIGTRAP, core dumped) under memory pressure, not the compositor.
  VM bumped 4G→8G to unblock the loop — the honest minimum-spec question
  is now open. NEXT: Max re-runs YouTube in the 8G VM; watch the index
  build complete (first success takes minutes — nixpkgs eval from cold).
- Round 3 (2026-08-30, Max: "yt works now, video plays fine but there is
  freezing, and also the keyboard looses focus"): 8G verdict — ZERO OOMs,
  index built clean (23779 pkgs, one daemon start). Freeze root-caused:
  waverunner's wgpu picked llvmpipe (device_type: Cpu) — virgl exposes
  GL, wgpu wants Vulkan — so the dock CPU-renders while Chrome
  soft-decodes video on 4 cores. Venus (Vulkan passthrough,
  virtio-vga-gl,venus=on) tried: WORSE — wgpu got no surface, daemon hit
  its restart limit, shell gone ("no bar, no dock, nothing") → REVERTED
  to virgl + cores 4→8; that death mode filed as F8. Keyboard-focus loss
  on the YT search bar still OPEN — no journal culprit; next repro gets a
  live `hyprctl activewindow` over ssh to split guest-focus-bug vs
  QEMU/host grab boundary.
  ✅ verified by Max post-revert: Firefox + Chrome, several sites at
  once — "all worked well no freezing". Focus loss not yet re-seen;
  watch stays armed.
- Round 4 (2026-08-30): INPUTS FREED FROM THE LAPTOP. launcher made
  public (was private + 10 days stale — first push attempt lied
  "Everything up-to-date" while the remote sat at a46cfd1; explicit
  main:main pushed 84efa5a), waveview created public (master pushed as
  main). Flake inputs repinned git+file → github:maxpoww/{launcher,
  waveview}; identical revs/narHashes so the repin cost zero rebuilds;
  VM target verified building from the GitHub-only closure.
  `github:maxpoww/Golem` is now buildable by any machine with nix —
  first time Golem exists independently of Max's laptop.
- Round 5 (2026-08-30, Max: "lets do the prebuilt index"): the OOM fix,
  see the ticked item above for the design. Notable in the doing: the
  daemon's TSV cache format (v5, header-versioned) made the prebuilt
  path clean — `load_cache` already validates the header, so a future
  format bump silently invalidates stale prebuilts and falls back;
  `nix-env -f <pinned> -qa --json --meta` inside the build sandbox is
  the eval (no flakes/store needed there), jq reshapes it to nix-search
  JSON, and the daemon's own binary converts (`build-index` mode) so
  filter/dedupe can never drift from the runtime path. 135/135 daemon
  tests pass. Golem input bumped; VM disk wiped for a TRUE first boot.
  Both proofs: 8G fresh-disk (prebuilt in ~2s, 0 OOM) and the 4G repro
  (0 OOM, 1 daemon start). The VM currently runs at 4G via QEMU_OPTS —
  vm.nix stays 8G for comfort.
