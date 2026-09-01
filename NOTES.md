# NOTES

> **READ THIS BEFORE TRUSTING ANY ENTRY BELOW — 2026-09-01, prep for run 2.**
>
> Everything under this line was written by the 2026-08-31 loop, which ran with
> `Read,Edit,Bash(npm test *),Bash(git *)` on a session sandboxed to `~/Golem`.
> Its reasoning is sound and its parks were honest, but a large share of them
> rest on one premise that is **no longer true**: that the other trees are
> unreachable and that `nix` does not exist.
>
> What changed:
>
> * All five other trees are on this machine and in scope for run 2 —
>   `~/launcher` (waverunner), `~/waveview`, `~/Golem-web` (the site, which the
>   notes call "a separate repo this sandbox cannot reach"),
>   `~/AndroidStudioProjects/Golem`, `~/notification-fix`. None of them were
>   ever missing; the harness just could not see them.
> * `nix` works. So does `cargo`, inside `nix develop` in the Rust trees
>   (245 workspace tests, green). `nixos-rebuild` is present.
> * The ISO's real problem was not that it was unbuilt — it was that it did not
>   **evaluate**: `boot.loader.timeout` collided with iso-image.nix. Fixed in
>   `7441320`. It has since been built warm, before run 2 starts.
>
> What did NOT change, and is still correctly parked:
>
> * Anything needing Max's eyes, taste, or a values call — the browser, the
>   surface pattern, the installer, the licence, the daily-driving week.
> * Anything needing hardware this box does not have: no QEMU, no second
>   machine, no USB stick, no phone on the bench, no wifi device to scan with.
> * Anything outward-facing. Run 2 is **local commits only** — no push, no
>   deploy, no F-Droid. A hook enforces it.
> * Anything the roadmap freeze forbids: S3 modules, the S6 settings surface,
>   the S8 tour. Reachable now, still frozen. Arc 1 is SH → S7 → S9.
>
> Nine items were unparked on that basis and annotated in place in the todo
> files with `UNPARKED 2026-09-01` and the reason. Entries below that say
> "sandboxed to ~/Golem" or "this harness has no nix" describe run 1's cage,
> not the state of the project.

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

- todo5 "Replace launcher's Files section with Nautilus handoff": DONE
  2026-09-01 (~/launcher feecc69) — the reach wall above expired when the
  sandbox opened. Folder activation now falls through to the launch path
  (xdg-open → Nautilus); in-launcher browsing (files_dir/try_navigate/the
  ".." lead-cell machinery) is deleted, the home strip and file search
  results remain. cargo test --workspace green at 244 (one deleted test
  asserted the ".." lead geometry). NOTE for Max: the flake pins waverunner
  by rev, so the ISO/VM won't see this until the input is bumped — and the
  handoff deserves one live click (verify-ui) before that bump.

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
    recycle bin (`todoSH.md:21`). So the item is really the *flow*, and its
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

- todo9 item 5 (wifi in the install flow): blocked on the flow (item 2) and,
  underneath it, on a curation call todoSH round 19 already put in Max's
  hands — nm-connection-editor cannot scan and nm-applet is a tray client on
  a desktop with no tray, so there is no scan-and-join GUI anywhere in Golem
  today; the libadwaita-consistent fix (gnome-control-center's Wi-Fi panel)
  drags in a Settings app that collides with S6's. What this session can add
  is the S9-specific half nobody had written: whether wifi must work DURING
  the install is not a given, it is a consequence of the ISO not being
  self-contained. `hosts/iso.nix` now carries the flake source at
  /etc/golem/src, but carrying the source is not an offline install — the
  eval still wants the inputs. Prefetching the inputs into the image (or
  installing a prebuilt toplevel) would demote wifi from "blocks the
  install" to "needed on first boot", which is a much easier bar and makes
  the Arc-1 exit depend on the curation call above only AFTER the machine is
  installed. That is the trade to make deliberately in item 2, not by
  accident.

- todo9 item 6 (verify the stopgap kit covers post-install life): the audit
  half is already done and did not need this item — todoSH round 19
  (`todo/todo7.md:207-217`) has the verdict: bluetooth and audio ARE covered
  (blueman-manager plus the applet as pairing agent; pavucontrol plus the
  wpctl keys), network is NOT. Nothing landed since that changes it. The
  remaining half is the item's own verb, "verify", and it means a person at
  a keyboard on an INSTALLED machine — which needs item 8's metal and cannot
  be substituted from here (the VM cannot test it either: slirp gives a
  wired virtio NIC, there is no wifi device to fail on). Closing it as
  "verified" while its network third is known broken would be a lie.

- todo9 item 7 (S10-lite: download link + install notes on golem-os.com):
  still parked, but two of the three original blockers expired 2026-09-01
  and the entry should not keep claiming them: the site repo IS reachable
  now (~/Golem-web — carrying 14 uncommitted files, so any work there must
  not discard them), and the ISO HAS been built green (golem.iso, 6.33 GiB,
  todo9 item 2 has the closure record). What still parks it: the ISO has
  never been booted, so "honest install notes" cannot yet honestly say it
  works; a download link needs a *hosted* artifact and publishing is a
  deploy — Max's, per the local-only rule; and the notes are downstream of
  item 2 (no install procedure to describe until the installer is picked).

- todo9 item 8 (burn to USB, install on real metal, then on a machine that
  isn't yours): blocked on physics. It needs a USB stick, a second computer,
  someone else's computer, and a human watching what happens — an agent can
  supply none of the four. It is also the roadmap's Arc-1 exit criterion,
  so it is the last thing in the file by design: items 2 and 3 have to exist
  before there is anything to burn.

- todo10 item 1 (site structure): blocked on access — golem-os.com is a
  separate repo and this sandbox reaches only /home/max/Golem, so there is
  no site tree here to structure. The item is also mostly a container for
  the rest of the file: its four slots are the manifesto (already live),
  item 2 (screenshots), item 5 (download) and an install guide that cannot
  be written until todo9 item 2 picks the installer.

- todo10 item 2 (capture real screenshots/screencasts): blocked on a running
  machine and an eye. It needs a live Golem session on a display, a
  recorder, and — since the item's own point is that "the motion IS the
  pitch" — someone judging which take is worth showing. This harness has no
  nix (every `nix` invocation is permission-blocked, same as the last three
  loops) and no display. It is also downstream of SH: seven of the surfaces
  worth filming are fixed-in-code but never looked at
  (`release-checklist.md` §2.3), so filming now risks shipping a recording
  of a bug.

- todo10 item 3 (headline the Ground superpower): blocked twice, and the
  second one matters more than the site being out of reach. The headline it
  asks for is "atomic updates + a roll back BUTTON", and the button does not
  exist — `features.md:129-134` still lists it as needed, and rolling back
  today means catching a 3-second boot menu
  (`system/configuration.nix:35`) on a machine that boots deliberately
  silent. Half the claim is true and unmatched; half is a feature that would
  exist only on a website, which `Golem.md:52` refuses by name. What this
  session could add is the choice, not the copy: `release-checklist.md` §3
  states both halves with the citations and recommends headlining the
  capability with the boot menu shown honestly. Picking the words is Max's.
  Worth knowing before that copy is written: rollback depth is the smaller
  of `configurationLimit = 15` and the daily gc's `--delete-older-than 7d`
  (`system/configuration.nix:39,241-245`) — on the feature being headlined,
  a machine broken and unnoticed for eight days may have nothing left to
  roll back to. Confirm which limit bites first at build.

- todo10 item 5 (publish ISO + instructions on golem-os.com): blocked the
  same three ways todo9 item 7 already recorded — separate repo, deploy
  credentials this session has no business using unasked, and no honest
  artifact to link (the ISO has still never been built or booted). Now also
  gated by its own file: `release-checklist.md` §5 is the ordered gate, and
  every line above "publish" is open.

- todo11 item 1 (i18n pass: shell strings extractable, Spanish first):
  blocked the same way todo3 and todo4 are — "the shell" is waverunner's
  Rust, and the item's two halves (pick an extraction mechanism, then wrap
  every user-visible string in it) are both edits in a tree this session
  cannot list, let alone build. The dictionary that "leads the way" is a
  waverunner module too. What is reachable from here is a different, smaller
  i18n fact worth not confusing with the item: `system/configuration.nix:98-110`
  pins `America/La_Paz` and nine `es_BO` `LC_*` settings onto every Golem
  machine including the ISO — already on the known-issues list
  (`release-checklist.md:130-134`). That is the installer's to ask, not S11's
  to translate, and changing it changes Max's daily driver, so it stays his.

- todo11 item 2 (keyboard-only audit: every gesture reachable without a
  pointer): blocked on seeing half the subject. The audit's rows are the
  OPTIONS surfaces — dock, pills, boxes, the drag-to-install gesture, the
  overview's drags — and whether each has a keyboard path is a property of
  waverunner's and waveview's input handling, which is out of reach and
  cannot be run either (no display, no `nix`). Writing "unknown" in two
  thirds of an audit is not an audit. The half that IS knowable was done and
  is recorded in `accessibility-research.md` §5: the compositor's own
  keyboard coverage is complete — focus, move, resize, workspaces, close,
  launcher, window cycling and the overview all have binds
  (`system/home/hyprland.lua:263-329`) — so the gap this item exists to
  close is entirely in the surfaces. One in-repo finding for whoever runs
  it: `input.follow_mouse = 2` (`hyprland.lua:250`) means focus can be moved
  by the pointer, which is worth checking doesn't fight keyboard-only
  navigation.

- todo11 item 4 (reduce-motion / reduce-transparency): blocked, but only on
  ordering. Three of the four things that have to move live in this repo and
  are one-liners (`hyprland.lua:172` kills compositor animation wholesale,
  `:139-156` is the blur/opacity block, `home.nix:102-107` is where the apps'
  `enable-animations` would go). The fourth is the shell's own motion and
  glass, which needs waverunner to read a flag from
  `xdg.configFile."waverunner/config.toml"` (`home.nix:316-326`) — and until
  it does, flipping the other three produces the worst possible result: a
  desktop where the windows are still and the dock still flies. So the
  engine goes first, in the waverunner tree. Design is settled in
  `accessibility-research.md` §4: one intent, four consumers, never a
  per-layer toggle.

- todo11 item 5 (non-expert testing rounds): blocked on people. The item's
  verb is "watch" — real humans, unprompted, on a running machine — and an
  agent can supply neither the humans nor the machine (no display here, and
  the ISO has never been booted). It is also downstream of S8's tour and of
  the seven SH surfaces that are fixed in code but never looked at
  (`release-checklist.md` §2.3): testing a stranger against unverified
  surfaces measures the bugs, not the design.

- todo11 item 6 (the final check: is the word "everyone" on the website
  true?): blocked twice. The website is a separate repo this sandbox cannot
  reach (same wall as todo10 items 1/2/5), and the check is by design the
  last thing in the file — its answer is the sum of items 1-5, all open. The
  answer as of today was still worth writing down rather than leaving to the
  moment someone writes copy: `accessibility-research.md` §8 states it with
  citations — a blind person cannot use Golem at all, and a pointer-less
  person can move windows but cannot reach the shell that is Golem's whole
  point. That is acceptable for an alpha (S11 closes last by design) and
  unacceptable to imply otherwise on a page, which is the same refusal
  `Golem.md:52` already makes.

- todoSH, the six parked items — one shared wall and one shared shape. SH is
  the "working perfectly" pass, and what makes something work perfectly is a
  person looking at it; six items ask for exactly that and nothing else. The
  wall underneath is the sandbox (`~/Golem` only — no `~/waveview`, no `nix`,
  no display; re-confirmed this session by `ls /home/max/waveview` being
  refused outright), so even the code half of these is out of reach: every
  overview fix cited in this file lives in the waveview plugin tree, a pinned
  flake input here. Per item:
  * "Max's bug inventory (visual/feel eye)" — the instrument IS Max's eye.
    Everything under "Max's list" is in his words from live use; an agent can
    only add what it can see, and it sees no screen. It is also not really a
    task but a collection point, and it should stay open through the
    daily-driving week that feeds it.
  * "Multi-resolution/scale check (1080p scale 1, HiDPI scale 2)" — parked by
    its own text ("needs eyes + hardware"). Two outputs or a scaled VM, plus
    someone looking; no display and no `nix` here. Worth knowing before it
    runs: the code half is already grounded — the foreign-hardware audit found
    no hardcoded monitors/resolutions/scales, and the overview's design
    constants are logical px throughout — so this is a look for surprises, not
    a hunt for known suspects.
  * "overview opens sometimes with no pointer" — fixed in code (waveview
    `92913d3`), and the item's own closing condition is "a week of daily
    driving shows zero recurrences". An intermittent bug closes on absence
    over time; only the week below can supply it.
  * "overview motion leaking to the workspace underneath" — the one overview
    item with a built fix (`b095aa7`) and NO recorded verdict from Max; it is
    the reason `release-checklist.md` §2.3 exists. Indirect evidence is real
    (the twenty drag/resize rounds after it all ran with motion swallowed and
    the leak was never re-reported), but indirect is not verified. One
    deliberate check closes it: open the overview, sweep the pointer over the
    windows underneath, confirm no focus-follows-mouse and no hover reaction.
    Cheapest item in the file for Max to retire.
  * "One week daily driving with a notes file" — the roadmap's own SH exit
    (`roadmap.md:29`, "a week of daily use with zero surprises"). An agent
    cannot daily-drive a desktop it cannot see. The notes file is the section
    itself: surprises land under "Max's list", one line each.
  * "Exit review: zero known brokenness → open S7" — downstream of all five
    above and last in the file by design. It cannot honestly clear while §2.3
    still lists anything, and asserting it early would be exactly the kind of
    lie SH exists to prevent.
  What this session could do it did: five items that were fixed AND verified
  but left unticked are now closed (overview integration, overview layout,
  empty frames/scrolling, overview design, floating mode), each with the
  verification it rests on written under it, and `release-checklist.md` §2.3
  re-cut to match — that list was conflating "unverified" with "checkbox still
  open", which made SH's remaining risk look about three times larger than it
  is.

- todo-android, all 18 unchecked items: parked as a file, and unlike todo3/4
  the wall here is doubled. W-A's code lives in two trees, and this session can
  reach neither: the desktop half is options-engine in the waverunner checkout
  (`github:maxpoww/launcher`, a pinned flake input here — `~/Golem` holds no
  `.rs` file at all, confirmed by `find`), and the phone half is the Kotlin app
  at `~/AndroidStudioProjects/Golem`, which `ls` refuses outright. Nothing in
  this repo is W-A implementation; `android.md` is scope, not code. Per item:
  * **`collectors/phone.rs`** (P1) and its two restatements — "phone pill in
    the topbar itself" and the DoD line "every feature reaches the desktop
    THROUGH the Brain" — are one job wearing three hats: the collector, the
    surface it feeds, and the promise that lands when both exist. All three are
    Rust in the waverunner tree. They need a session rooted there, same as
    todo3/todo4. Worth carrying into that session: the phone data feed is
    already complete and verified on the wire (battery), so the collector is
    writing a client for a protocol that is answering today, not designing one.
  * **One piece of that job does live in this repo** and is the reason to read
    this note before starting: the mDNS line above records that the Golem PC
    runs no responder (avahi and systemd-resolved both inactive), so discovery
    is phone-side-only until `system/configuration.nix` enables one. That is a
    ~3-line host change here — but it is not an item in this file, and Arc-1 is
    under the fix-don't-grow freeze, so it is flagged, not taken. It should
    ship in the same breath as the collector, since discovery is the collector's
    first move.
  * **Pairing UX test** (P1) and **"paired in <1 min by a non-technical
    person"** (DoD) are the same test written twice, and the instrument is a
    person who has never seen Golem. An agent cannot be that person, and an
    agent that has read the pairing code cannot even simulate one. Max supplies
    a stranger and a stopwatch; both close together.
  * **Distribute: F-Droid first, Play Store second** — an external service, an
    account, and $25. The readiness half is already done and ticked (FOSS audit,
    README, fastlane metadata, honest 0.1.0); what remains is submission under
    Max's identity.
  * **Choose a license** — the item says DECISION NEEDED and it is right. It is
    a values call between GPL-3 (ecosystem/ethos), Apache-2.0 and MPL-2.0
    (wider reuse), and the app being written from scratch is precisely what
    makes it free — and therefore Max's. One datum for it: Golem OS itself is
    GPL-3.0-or-later (`LICENSE`, and the SPDX header on `flake.nix`), so GPL-3
    is the choice that keeps one licence across the whole project. Everything
    downstream of this — signing, the F-Droid submission — waits on it.
  * **Signing config + reproducible release build** — gradle work in the app
    tree, and it wants a keystore, which is a secret this session has no
    business holding even if it could reach the files.
  * **Call audio relay, MMS/RCS + attachments** (P2), **all five P3 Magic
    items**, **P4 photo sync / shared surfaces / cross-device DND / app
    streaming** — feature work in the app tree, and every one of them needs a
    desktop counterpart in waverunner too, so they are blocked twice and are
    Arc-2 besides. One note for whoever picks up continuity camera: the host
    prep is already standing — `system/configuration.nix:58` loads
    v4l2loopback with `card_label="Android WebCam"` on video10.
  * **Remaining untested surface is I/O-bound** (Quality) — the item names its
    own requirement, instrumented tests on a device. App tree plus hardware.
  * **Phone battery cost negligible** (DoD) — attempted honestly and recorded
    as inconclusive, which is the right answer to have written down. Closing it
    needs a multi-hour run on the phone and Battery Historian; the 11-minute
    window already tried is the wrong instrument, not a wrong result.
  Nothing was changed in the two trees and nothing is claimed about them. The
  one thing this session could contribute is above: the avahi gap is named as
  part of the collector's job rather than left as a footnote under a ticked
  line, so the waverunner session starts knowing discovery has a host-side
  half.
- ~~parked todo11.md: loop made no progress in 3 iterations~~ CORRECTED
  2026-09-01: that park was the quota, not the items. At ~12:40 the account
  hit its session limit ("resets 4pm America/La_Paz") and every iteration
  after that died on turn 1 at $0 — the loop's stuck-detector read three such
  instant deaths as "no progress" and force-parked the file. The two items
  (keyboard-only audit, reduce-motion engine flag) are reopened `- [ ]`;
  nothing about them was attempted or found hard. Re-run after 4pm.
