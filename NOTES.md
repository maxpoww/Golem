# NOTES

- todo2 "Max's eyes + a day of daily use (window pill behaves identically)":
  blocked — needs Max personally daily-driving the live session for a day and
  judging the pill's feel. No test or screenshot substitutes for the owner's
  eyes here, so it can't be closed by an agent.

- todo3 (all six migration/new-module items — intellihide, window-pills,
  notifications, clipboard, notes, media): blocked — every one is Rust work in
  the waverunner tree (`github:maxpoww/launcher`, local checkout outside
  ~/Golem), which is only a pinned flake input here. This repo holds no engine
  collectors, no Mind providers and no surfaces, and the agent session is
  sandboxed to ~/Golem, so none can be edited or tested from here. They need a
  session rooted at the waverunner checkout.
- todo3 "Refine per-module when picked": blocked — contingent by its own
  wording on a module first being picked from optionsmodules.md, and S3 has not
  opened (roadmap ARC 1 is at S7, under the fix-don't-grow freeze). Writing the
  per-module DoD checklists now would be guessing at picks Max hasn't made.

- todo4 (the five module items — wi-fi, bluetooth, audio, brightness+power,
  displays): blocked for the same reason as todo3 — each is a collector +
  Mind provider + surface in the waverunner tree (`github:maxpoww/launcher`,
  checkout at ~/launcher), and this session is sandboxed to ~/Golem, so
  ~/launcher cannot even be listed. Only the stopgap-retirement half of each
  module (dropping networkmanagerapplet, blueman, pavucontrol, brightnessctl
  from `system/`) lives in this repo, and retiring a stopgap before its module
  exists would just break the machine. They need a session rooted at the
  waverunner checkout. `system-landscape.md` is the prep work done from here.
  Second, softer blocker: all five are downstream of the surface-pattern
  decision below, which is Max's.
- todo4 "Decide surface pattern: topbar pills vs a 'system' box": blocked —
  a design-language call on OPTIONS' coherence, which is the owner's, not an
  agent's. It also decides the module boundaries (does a bluetooth headset
  belong to the bluetooth module or the audio one?), so guessing it wrong
  would misshape all five modules above. `system-landscape.md` §7 collects
  the constraints the decision has to satisfy — pairing and wi-fi joining
  block on the user and need something box-shaped, volume/brightness/battery
  are glanceable scalars that want to rest visible, and a connected headset
  surfaces in two modules at once.

- todo5 "Decide default browser": blocked — the default browser is a values
  call (privacy story vs one-engine simplicity) and it's the OS's most
  visible third-party choice, so it's Max's. What an agent can add is the
  fact the item's framing misses: the webapp engine that actually ships is
  **google-chrome** (unfree, `programs.chromium.package = pkgs.google-chrome`
  in `system/home/home.nix`), not chromium — while apps.md says "Chromium
  (webapp engine already)" and todoSH F2 records that S7 "must SHIP
  chromium". So the real fork is three-way: (a) Firefox default + keep
  google-chrome as the engine (privacy headline undercut by an unfree Google
  browser in the image), (b) Firefox default + swap the engine to chromium
  (F2's runtime fallback chain google-chrome-stable → chromium already
  handles it, costs a second big build), (c) chromium as both. Whichever Max
  picks, apps.md line 48 and home.nix have to end up saying the same thing.

- todo5 (nix items generally): this loop's harness allows `Read,Edit,git`
  only — no `nix`, no /nix/store, no network — so nothing written here can be
  evaluated or built in-session. `system/golem-apps.nix` is therefore landed
  but unbuilt: package attrs are the top-level GNOME names (the `gnome.`
  namespace is gone in 26.05) and the option names are common ones, but the
  first `nixos-rebuild build-vm --flake .#golem-vm` is what makes it true.
  Most likely failure mode is a missing attr for one of the newer apps
  (showtime, decibels, papers, snapshot) — deleting the offending line is the
  whole fix.

- todo5 "Per-app touch check": blocked — it is fingers on glass (tap, scroll,
  pinch, on-screen keyboard per app), and the apps to check only exist as of
  the golem-apps.nix commit, unbuilt. But there is a prerequisite an agent
  CAN name: `system/configuration.nix` currently ships a udev rule setting
  `LIBINPUT_IGNORE_DEVICE=1` on every `ID_INPUT_TOUCHSCREEN` device, i.e.
  touch is switched off system-wide right now. Nothing can be touch-checked
  until that rule goes or is narrowed to Max's specific panel, and removing
  it is a call about his machine (it was presumably added for a reason — a
  ghost-touch panel), so it is his, not an agent's.

- todo5 "Music pick: try Decibels vs Amberol": blocked — the item's verb is
  "try", and the winner is a taste call about how Max listens (one file at a
  time vs a library). What this session could do it did: golem-apps.nix ships
  BOTH, so the trying needs no setup, and the audio mime default points at
  Decibels with a comment saying it flips if Amberol wins. Whichever loses
  gets deleted from golem-apps.nix, not left installed.

- todo5 "Replace launcher's Files section with Nautilus handoff": blocked —
  same wall as todo3/todo4. The Files section is a waverunner surface
  (`github:maxpoww/launcher`, checkout at ~/launcher, a pinned flake input
  here), and this session is sandboxed to ~/Golem. The ~/Golem half is done:
  Nautilus ships and owns `inode/directory`, so the handoff has something to
  hand off TO — what remains is Rust, in the other tree.

- todo6 (all six items — knob inventory, surface design, declarative write
  path, live-apply, theme picker, OPTIONS toggles): blocked, two walls.
  First, the same one as todo3/todo4/todo5: S6 IS a waverunner surface plus
  its `core::config` schema, and that source lives in `github:maxpoww/launcher`
  (checkout at ~/launcher), a pinned flake input here — this session is
  sandboxed to ~/Golem and cannot even list it. Item 1 in particular asks to
  inventory "every existing knob (core::config TOML schema)"; its authoritative
  source is the unreadable file, so any list written from here would be a
  guess dressed as an inventory.
  Second, and this one holds even from a waverunner-rooted session: S6 has not
  opened. The roadmap's ARC 1 is S1 → SH + S2 → S7 → S9 under "no new OPTIONS
  surfaces, no module growth" — and a settings surface is precisely a new
  OPTIONS surface. Building it now would break the freeze, not serve it.
  What ~/Golem does hold, so the future S6 session starts ahead:
  * The only knobs this repo seeds are `theme.icon_theme` and
    `options.link_unfurl`, in `system/home/home.nix`
    (`xdg.configFile."waverunner/config.toml"`). That is the write target
    item 6 needs, and it is currently home-manager-owned — generated read-only
    into the store — so a settings surface writing it means either taking the
    file out of home-manager's hands or splitting seeded-default from
    user-override. That fork is real and unresolved.
  * Item 3's "same model as packages.list" is `system/waverunner-apply.nix`:
    user writes a DATA file, a systemd.path fires a root oneshot that
    validates every token, generates root-owned nix INSIDE the flake checkout,
    `git add`s it (flakes can't read untracked files), rebuilds, and restores
    last-good on failure with the result in apply-status.json. Any settings
    knob that lowers to nix has to ride that same path, and the validation
    step is per-knob work — a package name is one regex, a theme colour or a
    display arrangement is not.

- todo7 "Compose golem-apps.nix (from S5)": blocked on the build check, not on
  the composing. The composing is already in the tree and readable:
  `system/golem-apps.nix` is imported by `system/configuration.nix:10`, which
  is in `golemModules`, so BOTH nixosConfigurations pick it up, and the file is
  git-tracked (flakes can't see untracked files). What is missing is the only
  thing a tick would be asserting: the eval. This session's harness has no
  `nix` at all (`nix --version` is refused) and no network, so todo5's "BUILD
  CHECK OWED" is still owed — `nixos-rebuild build-vm --flake .#golem-vm`
  closes it. Likeliest failure remains one missing attr among the newer GNOME
  apps (showtime, decibels, papers, snapshot); deleting that line is the fix.

- todo7 "Stopgap kit (network/audio/bluetooth GUIs)": blocked on a curation
  call that is Max's and on hardware the VM does not have. The audit the item
  asks for "before ticking", done from this repo:
  * Bluetooth — covered. `services.blueman.enable` (`system/bluetooth.nix:4`)
    ships blueman-manager as a real .desktop app, and `hyprland.lua:38`
    autostarts blueman-applet. Keep that exec even though Golem has NO tray
    (nothing in this repo implements a StatusNotifier host, so the icon is
    invisible): the applet is also NM-of-bluetooth's pairing AGENT, and its
    PIN/confirm dialogs arrive as ordinary windows.
  * Audio — covered. pavucontrol (`configuration.nix:189`) for devices and
    per-app volume, plus the wpctl key binds (`hyprland.lua:318-321`).
  * Network — NOT covered, and this is precisely the S7 exit clause
    ("including getting online"). `networkmanagerapplet` gives
    nm-connection-editor, which cannot SCAN: joining means typing the SSID and
    security by hand. nm-applet does scan, but it is a tray client and is not
    autostarted — and there is no tray to start it into. So a stranger on
    wifi-only hardware has no scan-and-join GUI. The fix is to ship a NM GUI
    that lists networks; the pick that matches the CURATE column's libadwaita
    set is gnome-control-center's Wi-Fi panel, at the price of shipping a whole
    Settings app whose other panels are half-broken under Hyprland and which
    collides head-on with S6's own Settings surface. That trade is a curation
    decision of the same kind as the browser one, i.e. Max's — and it cannot be
    tested in the VM regardless: qemu slirp gives a wired virtio NIC, there is
    no wifi device to scan with, so this one needs real hardware.
  * Finding that is not about GUIs, same stranger, same item: `brightnessctl`,
    which `hyprland.lua:322-323` binds the brightness keys to, is NOT in the
    system stopgap kit — it arrives from `system/home/waverunner-packages.nix`,
    i.e. Max's own launcher-installed list. A fresh Golem starts that list
    EMPTY (F11), so on a stranger's machine the brightness keys do nothing.
    Moving it into configuration.nix's stopgap block is a one-line fix, left
    undone here only because nothing written in this session can be built.
    Adjacent, same class: `hyprland.lua:40` execs `kdeconeectd` — a typo, and
    the real binary lives under libexec rather than on PATH, so the correct
    line is not a one-character guess.

- todo7 "Ship ~/notification-fix with the webapp profile": blocked — the
  extension exists only in `~/notification-fix`, outside this session's
  sandbox (~/Golem only), and the item's own first step ("get it into a repo
  first") is a push to Max's GitHub account. The flake half is one
  `--load-extension` on the webapp profile in `home.nix`'s `programs.chromium`,
  but writing it without seeing the extension's manifest and layout would be
  inventing a path.

- todo8 (all five items): parked as a file. Two walls stand behind every one
  of them. First, S8 has not opened — roadmap ARC 1 is SH → S7 → S9 under
  "no new OPTIONS surfaces, no module growth", and an onboarding tour is a
  new surface plus a new collector plus a new Mind provider. Second, the
  same wall as todo3-todo6: all of that is waverunner code
  (`github:maxpoww/launcher`, checkout at ~/launcher), a pinned flake input
  here, and this session is sandboxed to ~/Golem and cannot list it. What
  this session could do it did: `onboarding-design.md`, the design doc item 2
  asks for by name, written the way `system-landscape.md` was written for S4
  — every claim about current behaviour cited to a file:line in this repo,
  nothing invented about waverunner's internals. Per item, beyond that:
  * "First-boot detection + flow" — a first-run detection already exists on
    both sides and neither teaches: the kernel/greetd path lands on a
    finished desktop with no words (`configuration.nix:60`,`:151`,
    `hyprland.lua:218`) and the daemon's own cold start builds caches and a
    recycle bin (`todoSH.md:17`). So the item is really the *flow*, and its
    "language, user" clause collides head-on with roadmap S9's installer
    ("disk, user, wifi, done") — they cannot both own that choice, and which
    one does is Max's. Concrete finding underneath it either way: the user is
    hardcoded in four places, and one of them has teeth —
    `system/waverunner-apply.nix:31` is `user = "max"`, so the apply service
    watches `/home/max/.config/waverunner/packages.list` and on an account
    not named `max` **installing an app does not work at all**. Left unfixed
    here on purpose: it is S9's to arrange together with the flake checkout
    at `golem.flakeDir` (`waverunner-apply.nix:125`, `flake.nix:88`), and
    nothing written in this session can be built.
  * "Diegetic tour" — doc landed, tour blocked. The doc's own §6 is the
    reason it can go no further: the biggest fork (teach the foreign reflex,
    or just bind it — `Alt+Tab`, `Super` alone, `Alt+F4`, `Ctrl+Alt+arrow`
    are all bound to nothing in `hyprland.lua`, verified) decides how large
    S8 even is, and it is a values call about what Golem is.
  * "Seed skill calibration (Tuning.skill)" — doubly downstream: it needs
    the onboarding choices of item 1 (which do not exist) and Tuning.skill
    itself, a Brain-side artifact in the unreadable tree. The doc's §5 makes
    the one claim worth carrying forward: this is not separate work, it is
    the *second reader* of the skill store the tour needs, and building the
    two independently would produce two disagreeing models of the person.
  * "First five minutes script" — cannot be scripted yet, and the doc's §7
    says why in three checkable points: "browse" has no answer while the
    default browser is an open owner decision (todo5 above), "install" is a
    minutes-long `nixos-rebuild` with an F10 history of reporting a queued
    install as failed (`todo7.md:110`), and "install" is inert entirely
    without a flake checkout at `golem.flakeDir`. Also needs a bootable
    Golem, which is S9.
  * "Test with one real non-Linux human" — blocked on a human and on a
    machine to sit them at; an agent can neither be the human nor watch one.

- todo7 (the four VM-loop items — Super passthrough / "VM mode", useBootLoader
  so reboots keep the latest generation, slirp download speed, llvmpipe
  rendering): blocked as a family — each one's only test is building the VM and
  looking at it, and this session has no `nix`, no /nix/store, no QEMU and no
  display. Per item, beyond that: the Super fix would be a submap in
  `system/home/hyprland.lua`, but the fork's Lua API reference lives in the
  launcher tree (unreadable from here), that file uses no submap today, and it
  is the file that boots Max's desktop — an untested binding there costs him a
  session, and which key escapes VM mode is his muscle memory anyway.
  useBootLoader says in its own text that it needs a careful round on a fresh
  disk. The slirp and llvmpipe items are both written as "revisit if it gets
  old / if the VM ever becomes a daily driver", so neither is actionable until
  the loop actually hurts.

- todo9 item 1 (ISO module): LANDED BUT UNBUILT — same harness limit as the
  todo5 nix items (Read/Edit/git only; no `nix`, no /nix/store, no network),
  so `nix build .#iso` has never run and nothing has booted from it. The nix
  itself is small and mechanical, but two things in it are genuinely unproven
  and both are called out in `hosts/iso.nix`'s closing comment: (a) Golem core
  boots a systemd initrd (`system/configuration.nix:54`) while nixpkgs' own
  installer ISOs still use the scripted one, so iso-image.nix's overlay-store
  mounts are the least-travelled path in the whole config — if stage 1 hangs,
  `boot.initrd.systemd.enable = lib.mkForce false` is the one-line proof;
  (b) quiet boot (loglevel=0, printk zeroed, `fbcon=map:1`) means a failed
  session looks exactly like a dead machine — tty2 keeps a getty from the
  installation-device profile, so Ctrl+Alt+F2 is the way in. Expect the image
  to be large: the live session carries golem-apps.nix, google-chrome and the
  full home layer, because "live session boots into REAL Golem" is the item.

- todo9 item 2 (decide installer): blocked twice over. Its own decision
  procedure is a *friction test*, which needs the ISO built and two candidate
  images to sit in front of — this harness has no `nix`, no VM and no display
  — and "the installer is Golem's first impression" makes it the same class of
  call as the browser and the surface pattern: Max's. Three facts the item's
  binary framing misses, for whoever runs that test:
  * calamares-nixos is not a drop-in. The graphical NixOS ISOs use it with
    `calamares-nixos-extensions`, whose `nixos` job renders
    `/mnt/etc/nixos/configuration.nix` from a TEMPLATE plus the GUI's answers
    and then runs `nixos-install` — i.e. it produces a channel-based plain
    NixOS with a stock DE, not Golem. Installing Golem through it means
    forking that extension (Python + template) so it instead seeds a flake
    checkout and instantiates our attr, which is the shape S7 already fixed
    (`golem.flakeDir`/`golem.flakeAttr`, `hosts/vm.nix:21`). Its cost is a
    fork, not an integration.
  * It is also a Qt app: the very first screen a stranger sees would be
    system-wide-nothing-like-Golem, on an ISO whose whole point is that the
    live session IS Golem.
  * The fork is not really two-way. "Our own guided surface" is waverunner
    code (out of reach from ~/Golem) plus privileged disk work; the third
    option nobody wrote down is *neither surface* — `disko` + `nixos-install
    --flake` behind a handful of questions, which would turn item 3's
    "guided partitioning, encryption option" into a data file instead of a
    program. That option is the cheapest path to the Arc-1 exit and the
    ugliest first impression, which is exactly the trade the friction test
    exists to settle.

- todo9 item 3 (disk flow): blocked on item 2 — partitioning, the encryption
  option and the single "install" action are all shaped by which surface owns
  them, and building either before that is picked is guessing. Two concrete
  things the flow will have to handle, found while reading the tree:
  * There is no host attr for a machine that isn't Max's.
    `nixosConfigurations.golem` carries `hosts/golem/hardware-configuration.nix`
    (his disk UUIDs) and `nvidia.nix`; `golem-vm` is the VM. A stranger's
    install needs a generic host whose `hardware-configuration.nix` is
    generated at install time INTO the seeded checkout — the ISO already
    carries the source to seed it from (`/etc/golem/src`, `hosts/iso.nix`).
  * Encryption may boot to a black screen. Golem core boots silent on
    purpose (`quiet`, `loglevel=0`, `kernel.printk` all zeroes,
    `fbcon=map:1`, `system/configuration.nix:43-75`) and ships no plymouth
    at all — the `splash` kernel param in that list is inert today. A LUKS
    passphrase prompt on such a console is the first thing to verify on the
    first encrypted install: if it is invisible, the encryption option is
    worse than not offering it.
