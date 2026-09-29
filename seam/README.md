# Seam — Golem's browser

Seam is Golem's browser: **Mozilla's official Firefox Linux build**, wrapped with
Golem's chrome script (`golem-chrome.js`: tab overview, tool row, bar pinning) and
enterprise policies (uBlock Origin, telemetry off, …) by `/etc/nixos/golem-browser.nix`.

This directory keeps Seam on Mozilla's **current** release. A browser can't wait days
for a distro channel. On 2026-09-25 Mozilla shipped **156.0.1** while nixpkgs, even
unstable, was still on 156.0.

## Identity (2026-09-27): Seam, independent of Firefox, Golem's default browser

Beam was renamed **Seam** (Max, 2026-09-27: "totally independent... side by side with firefox"). What that means concretely:
- **Package `golem-seam`** (`browser.nix`): the policied wrapper plus its own launcher, desktop entry and icon. It no longer overrides `pkgs.firefox` — a plain Firefox can be installed beside it (the dock's Install section, `firefox` in packages.list) and is a different program with a different profile.
- **Binary `seam`, window class `seam`** (`wrapFirefox { applicationName = "seam"; wmClass = "seam"; ... }`, `--name seam`). Hyprland's subtle-border rule, the titlebar plugin's bare-float rule and the dock's title grooming know both `firefox` and `seam`.
- **Profile `~/.local/share/seam`** (the launcher passes `-profile`), never `~/.mozilla`. `home.nix` migrates a Beam-era `~/.mozilla/firefox/golem` once (copy; the old dir and the profiles.ini Beam wrote are kept aside as `*.moved-to-seam`, so a plain Firefox starts clean).
- **Default browser**: `xdg.mimeApps` for http/https/html and `BROWSER=seam`.
- **The window says Seam** (`ttInit`: the title builder is wrapped). The app menu and about: pages still say Firefox — that text is packed in omni.ja's locale, out of a config script's reach.
- Internals renamed with it: `golem.seam.*` prefs, `SEAM_*` env, `seam-update` service/timer, `/var/lib/seam`, `seam-selftest`.

## Files — Seam is ONE module (since 2026-09-25)

| file | role |
|---|---|
| `default.nix` | **the module**: import this directory (Golem flake `golemModules`; dev box `/etc/nixos/configuration.nix`) |
| `browser.nix` | Firefox build (Mozilla's, pinned) + enterprise policies (uBO, ATBC, telemetry off…) + the chrome script |
| `golem-chrome.js` | **the chrome script**: tab overview, tool row, bar pinning, safety net, blank-tab fixes. **Edit HERE.** |
| `home.nix` | per-user half (home-manager): `user.js` prefs, `userChrome.css`/`userContent.css`, creates the `golem` profile |
| `userChrome.css`, `userContent.css` | the Seam look (were hand-edited profile files until 2026-09-25) |
| `sources.json` | **the pin**: Firefox version, Mozilla tarball URL, SHA-256 (from Mozilla's `SHA256SUMS`) |
| `lane.nix` | security update lane: overlay from the pin, `seam-update`, `seam-selftest`, `seam-update.timer` |
| `update.sh`, `selftest.sh` | bodies of `seam-update` / `seam-selftest` |

**Where it's imported:**
- **Golem flake:** `flake.nix` `golemModules` imports `./seam`, and `system/home/home.nix` imports `../../seam/home.nix`.
- **Dev box:** `/etc/nixos/configuration.nix` imports `/home/max/Golem/seam`, and `/etc/nixos/home.nix` imports `/home/max/Golem/seam/home.nix`.
- **One source of truth.** The old `/etc/nixos/golem-browser.nix` and `golem-chrome.js` were retired to `~/seam-retired-from-etc-nixos/`.

**Update lane, per system:**
- **Golem (flake).** The updater writes the pin into the machine's own checkout (`golem.flakeDir`/seam), `git add`s it (a flake only sees tracked files), then runs `nixos-rebuild switch --flake <flakeDir>#<flakeAttr>`.
- **Dev box (channel).** It updates the pin in this directory and runs plain `nixos-rebuild switch`.
- **Post-update self-test.** It runs as `nobody` on a world-readable copy of the pin and script, because the owner's home isn't readable by `nobody`.

⛔ **Never evaluate the flake with a `path:` ref.** It copies all of ~/Golem (about 70 GB) into the store and filled the disk on 2026-09-25. Use `git+file:///home/max/Golem`.

## How an update flows

1. **`seam-update.timer`** fires every 4h (and 10 min after boot; catches up after sleep).
2. It waits for the network (`golem-wait-online`, the same gate as the daily upgrade).
3. It asks Mozilla for the current release:
   `product-details.mozilla.org/1.0/firefox_versions.json` → `LATEST_FIREFOX_VERSION`.
4. If the release is newer than the pin, it takes the hash from Mozilla's
   `releases/<v>/SHA256SUMS` and rewrites `sources.json` atomically. The old pin is kept as `sources.json.prev`.
5. It runs `nixos-rebuild switch`. **Only Seam changes.** The channel isn't bumped; that stays with the daily `nixos-upgrade`.
   - If the build fails, the old pin is restored and the unit fails (visible in `systemctl status seam-update`). You never end up with a broken pin.
6. **Notifies you**: "Seam updated to X — restart Seam to apply". A running browser keeps
   its old binary until relaunched. Session restore brings the tabs back.

It never downgrades (it compares with `sort -V`), and it serializes with other rebuilds via
`/run/golem-rebuild.lock`. The only outbound requests go to Mozilla's public endpoints, carrying no identifiers.
Firefox's own updater is disabled (`DisableAppUpdate`). This lane replaces it.

## Commands

```
seam-update --check          # pinned / built / latest, changes nothing (any user)
sudo seam-update             # update now if Mozilla has a newer release
sudo seam-update --force     # re-pin to latest and rebuild even if current
systemctl status seam-update # last run
journalctl -u seam-update    # history
systemctl list-timers seam-update
```

**Rollback:** `sudo mv ~/Golem/seam/sources.json.prev ~/Golem/seam/sources.json && sudo nixos-rebuild switch`,
or boot the previous generation.

## Safety net (2026-09-25)

Seam takes every Firefox release automatically, and Firefox changes its internal UI
structure without notice. `golem-chrome.js` therefore protects itself:

- **The overview never leaves the browser broken.** Open, close and switch are guarded. Any error runs
  `ovRestore`, which puts back the content, the nav bar and the bar colours, and disables the overview for
  that session.
- **Health check, once after startup** (no polling, so no cost while browsing). If a hook the overview needs is
  missing (`#browser`, `#tabbrowser-tabpanels`, `#nav-bar`, the toolbar slot, the grid button, the
  agent stylesheet), the overview switches off and Seam is plain, working Firefox. If the
  vertical-tab sidebar is gone as well, Firefox's horizontal tab strip comes back for that session.
- **Local only.** It writes `golem-health.json` in the profile and shows one desktop notice per
  Firefox version. Nothing is sent anywhere.
- **Tab switching is checked.** If Firefox silently ignores the tab change, Seam falls back to
  `tabContainer.selectedIndex`. (A headless run showed that it can ignore it.)

### Self-test

```
./selftest.sh              # full check: normal path + 6 simulated failures, headless
./selftest.sh --one nav-bar
```

It runs the **real installed Seam build** headless, with a throwaway profile and nothing on screen. It covers
the normal path (open → close → switch, then checks the browser is left in a clean state), and simulated
failures: `throw-open`, `nav-bar`, `tabbrowser-tabpanels`, `golem-overview-btn`, `agent-sheet`,
`sidebar-main`. It exits 0 only if every case passes. It passed 7/7 on 156.0.1, 2026-09-25.
**Run it after every Firefox update.** Next step: `seam-update` runs it automatically after each rebuild.

## Bar colour: Seam tint (replaces the ATBC extension)

ATBC injected a script into **every page**. That script re-sampled the page colour on every `scroll`, `click`,
`resize` and animation end, and ran 4 page observers. Each sample could rewrite the whole browser
theme and restyle all of the chrome. That's the scroll cost. Seam tint does the same job without any of it:

- **Source:** 2 px at the top centre of the **viewport**, the bar's edge and ATBC's own sample point, read from the
  rendered frame with `drawSnapshot`. `drawSnapshot`'s rect is **document-relative** (confirmed headless), so the
  read is offset by the tab's current scroll position.
- **When:** on page load, on in-page navigation, and **while scrolling** (the bar follows what's under it, like ATBC).
  A minimal frame script in each tab only sends "scrolled" plus the scroll position, at most one ping per
  120 ms and one more when scrolling stops. There are **no DOM queries in the page** (ATBC ran
  `elementsFromPoint` + `getComputedStyle` on every event). Samples are coalesced, one in flight, and the bar
  restyles **only when the colour actually changes**. ATBC rewrote the whole theme on every event.
- **Maths:** an exact port of ATBC's defaults, which are the settings Seam used (decoded from its storage 2026-09-25;
  none had been changed): contrast correction for white text, and near-white pages switch to a light bar with black text.
  Surfaces: frame/toolbar **and the vertical-tab sidebar** at +0 (Golem choice: ATBC used +5 for the sidebar), field/panel +5 %, field border +10, sidebar border / selected tab +15. Toolbar buttons incl. the grid button and tool row use `--toolbarbutton-icon-fill` (black/white per page).
- **Apply:** Seam sets its own `--gt-*` variables. An agent stylesheet (`:root[golem-tint]`) maps them onto
  Firefox 156's theme variables with `!important`, so nothing can overwrite them.
- **Cache:** per tab and per site. Tab switches paint the known colour straight away.

**Verification**
- `node tint-oracle-check.js ./atbc-colour-oracle.js /etc/nixos/golem-chrome.js`: the shipped maths
  compared with **ATBC's own colour class** (extracted from the extension) on 4,109 colours. Result: **0 mismatches** (bit-for-bit, dark and light).
- `./selftest.sh`: real pages (red, near-white, near-black) plus scroll cases (red top → white after scrolling down → red after scrolling back up; a fixed header keeps its colour), headless. Firefox's computed theme variables
  match the expected values, and the tint clears when switched off.

**Built in, on by default** for every user. There's nothing to configure. ATBC is set to `blocked` in
`golem-browser.nix` policies, so Firefox also uninstalls it from profiles that already had it.
(`golem.seam.tint=false` is a hidden kill switch for development only.)

## Performance

**Target:** Seam competes with Chrome, not plain Firefox. It should use the same memory as Chrome or less, and it should *feel* snappier. The benchmark harness is `bench/bench.sh`; its header lists the modes.

**What the harness cannot measure:** headless Firefox never presents layers, because SWGL has no framebuffer. Switch latency and paint smoothness therefore need a real session. The harness measures UI-thread work only (`BENCH_SWITCH=n`).

**Done in 2026-09-26: thumbnail work moved off the UI thread.** Measured on the real build with a real 3.9 MB cache, each tab switch used to cost:
- about 11 ms of synchronous save (stringify plus write), plus
- about 5–6 ms of synchronous JPEG encode,

which is 2–3 dropped frames at 165 Hz. Now:
- **Encode:** `toBlob` encodes on a worker.
- **Save:** stringify runs in `requestIdleCallback`, and `IOUtils.writeUTF8` writes on its own thread, atomically via `tmpPath`.
- **Startup load:** `IOUtils.readUTF8`, then the parse runs when idle.
- **Quit:** the save stays synchronous.

Gotcha: `IOUtils` and `PathUtils` are *not* globals in the autoconfig scope. Use `win.IOUtils`.

**Done 2026-09-26: link clicks at stock speed.** uBlock Origin's default "Disable pre-fetching" turns off all of Firefox's connection warming:
- hover preconnect,
- the address-bar preconnect,
- DNS prefetch,
- Early Hints.

Seam now sets `prefetchingDisabled=false`. It has to be a **top-level** `userSettings` key in uBO's policy; inside `adminSettings` it isn't applied. Measured with a 150 ms handshake: 221 → 58 ms (hovered link), 223 → 102 ms (instant click). The benchmark is `BENCH_CLICK`. It needs public addresses (`BENCH_CLICK_HOST`/`BENCH_CLICK_HOST2`), because Firefox never preconnects to loopback or private addresses.

**Done 2026-09-26: restored tabs warm in the background.**
- **What:** after a restart, once the session is back, startup has settled and the UI is idle, the N most recently used restored tabs load in the background, one at a time. The rest stay unloaded. `golem.seam.warmTabs` sets N (default 5; 0 turns it off).
- **Mechanism:** Firefox's own lazy-tab `reload()` hook.
- **Tests:** selftest `bwTest`, plus a real restart test with `BENCH_RESTORE=1`.

**Done 2026-09-26: back is instant.** `docshell.shistory.bfcache.allow_unload_listeners=true` (in `home.nix`). Firefox drops pages with an `unload` handler from the back-forward cache, and most sites have one. Measured with `BENCH_BACK=3`: a heavy page came back in 224 ms before, 14–24 ms now. "no-store" pages (banks) are still never cached; that's the site's explicit wish.

**Done 2026-09-26: unload idle tabs when memory runs low.** `browser.tabs.unloadOnLowMemory=true`. The Linux watcher already exists but ships off. It unloads the least recently used tab idle for 10+ minutes; never the current tab, one playing sound, a call, picture-in-picture or a private tab. Verified by calling `TabUnloader.unloadTabAsync`, the watcher's own call.

**Done 2026-09-26: Seam adapts to each machine (speed pass, "speed first").**
- **Display rate.** `layout.frame_rate` used to be hardcoded to 165 (Max's panel) on every Golem machine. Seam now asks the compositor at startup (`hyprctl monitors -j`, the focused monitor) and sets the pref live. Proven headless: the rAF cadence follows the pref within one session (30 → 30 fps, 90 → 90 fps), and on the dev box 165 Hz is detected and applied before the first window. If hyprctl is unreachable nothing is set (Firefox's default `-1`). Pacing prefs are unchanged. `home.nix` no longer sets the rate.
- **Codecs.** Older chips decode only H.264 in hardware, yet YouTube serves VP9/AV1 by default → software decode. Seam reads Firefox's decoder report (`gfxInfo.CodecSupportInfo`, e.g. `VP9 SWDEC HWDEC`) and, where VP9/AV1 are *known* not to be hardware, tells streaming sites they are unsupported: a content-side patch of `MediaSource.isTypeSupported` in every new document, before any page script runs. Plain video files still play. A codec the report doesn't list yet is left untouched; the decision is re-checked a minute in and after a video starts. Modern machines: nothing changes (dev box: all five video codecs hardware → blocks nothing). Kill switch `golem.seam.preferHwCodecs=false`. Both are recorded per machine in `golem-media.json` (`display`, `codecPolicy`).
- ⚠ `mediaCapabilities.decodingInfo(...).powerEfficient` is NOT a hardware-decode probe from the browser process: it answers for that process, where video is never decoded, and said "no hardware" on a machine that decodes everything in hardware (live, 2026-09-26). It is only used to make Firefox instantiate its decoders.
- Gotchas found: `media.mediasource.vp9.enabled` is dead in 156; `media.webm.enabled=false` also kills WebM files; Firefox strips STRING prefs from web content processes (use bools); a browser's outer window is reused across loads (key per-document work on the document); autoconfig skips the first line of `mozilla.cfg`.
- **Not done:** the network predictor's prefetch — the predictor was removed from Firefox before 156, nothing to enable.

**Done 2026-09-26: the tab you look at wins the CPU.** Firefox's Linux process priority manager only sets `oom_score_adj`; every Seam process ran at nice 0, so a busy background tab competed equally with the one on screen (Chrome on Linux: same). Two halves:
- **Dock (waverunner `launch.rs`):** every app now launches in its own systemd user scope (`systemd-run --user --scope --slice=app-graphical.slice -p CPUWeight=100 -p Delegate=yes`), which gives it a cgroup with the cpu controller. Probed once at daemon start; plain launch if scopes aren't available. Before this, apps inherited the compositor's cgroup (`memory pids` only).
- **Seam (`cs*` in `golem-chrome.js`):** inside its scope it creates `fg` and `bg` (bg `cpu.weight` 20 vs 100). Content processes whose tabs are all background (not selected in any window, not playing sound) move to bg on tab switch, sound start/stop, window focus and a 30 s sweep; back to fg the moment their tab is picked. Refuses any cgroup it doesn't own outright (every pid must be Seam's own tree, incl. the launch wrappers above it) and anything that isn't a transient `.scope`, so an old-style launch does nothing. Kill switch `golem.seam.cpuShare=false` moves everything back. Reported in `golem-media.json` (`cpuShare`).
- **Proof:** `./selftest.sh --host` runs the farm on the host in its own scope pinned to one core: groups created, a background tab's process in bg, the selected one in fg, kill switch restores; and a fixed chunk of foreground work while a background tab spins a whole core: median 513 ms with the share vs 651 ms with equal shares (runs 424–528 vs 639–675, no overlap). The ideal 5:1 is diluted because Seam's own painting/UI share the front group.
- Gotchas: a `.scope` created by `systemd-run` contains the launch wrappers (`sh`, `systemd-run`, `timeout`) as Seam's ANCESTORS — ownership must accept ancestors, not only descendants; Firefox re-parents its `crashhelper` to the session manager, so it is neither — ownership also accepts any process whose cmdline starts with Seam's install dir (`GreD`; `/proc/pid/exe` is not readable across process boundaries, cmdline is); the first live launch failed on exactly that and is the reason `selftest.sh --host` now runs with the crash helper ON; the scope root must be emptied into a child before `+cpu` can be written to its `cgroup.subtree_control` ("no internal processes"); cgroupfs writes must be plain writes (no temp+rename); a toolbox can't write cgroups but can read the host's via `/run/host/sys/fs/cgroup`.

**Done 2026-09-26: hover prefetch.** After the connection is warm, the biggest wait on a click is request → first byte (the server's think-time). A same-site link hovered for 65 ms has its page fetched into the HTTP cache **by the page itself** (`fetch()` in the page's context, `Purpose: prefetch`), so the click paints from cache. Rules: same site only; never a link with a query string, a fragment-only or non-http link; one per link per page, 20 per page, one per 100 ms; trusted input only; a site answering `no-store`/`no-cache`/`max-age=0` is not prefetched again in that process. Kill switch `golem.seam.hoverPrefetch=false`.
- **Measured** (click bench, 300 ms server think-time, 150 ms connection delay): cacheable page 55–69 ms instead of ~375 ms, served from cache 3/3; forced revalidation (`max-age=0`) 347 vs 374 ms (body saved, think-time stays); no-store: nothing. A survey of 15 real sites: about a third cacheable (Guardian, MDN, Apple, Python docs), a third revalidating (BBC, Wikipedia, GitHub, Amazon), a third no-store (NYT, Reddit, Ars, YouTube).
- ⚠ Firefox's own prefetch service (`nsIPrefetchService`, what `<link rel=prefetch>` uses) stores entries a top-level navigation NEVER uses (0/3 served from cache, even fresh) — the page `fetch()` route is the one that works (3/3). Its 2nd argument in 156 is an `nsIReferrerInfo`, and it refuses with a bare NS_ERROR_ABORT while `network.prefetch-next` is false (uBO's first run flips it off in a fresh profile before its managed setting lands; a live profile has it on).
- Bench gotchas: `data:` URLs decode `+` to a space; the two variants share proxy ports; the proxy logs only the first request per connection (a click reusing the prefetch's connection is invisible there — count `http-on-modify-request` / `http-on-examine-cached-response` inside Firefox instead); temporary IPv6 addresses rotate on reboot (`BENCH_CLICK_HOST` must be re-read).

## Why Mozilla's build and not nixpkgs'

- **Speed:** the pin tracks Mozilla directly, so the delay is hours, not the days a channel takes.
- **No compiling:** Golem runs on varied hardware, and a weak laptop must never build Firefox from source. The tarball is Mozilla's prebuilt binary, verified against their checksum.
- **Same Seam:** `wrapFirefox` accepts the same `extraPrefs` / `extraPolicies` / `extraAutoConfig`, so the chrome script and policies are unchanged.

## Known limits / next steps

- **Channel choice:** this tracks the **rapid release** (`LATEST_FIREFOX_VERSION`).
  To move to ESR, where internals stay stable for about a year and security point releases still arrive, switch the key to `FIREFOX_ESR` and
  the URL path. It's a two-line change in `update.sh`. Still to be decided.
- **Distro build:** today `seam.nix` is imported by `/etc/nixos`. The Golem flake should import
  it too, so installed systems get the same lane.
- **x86_64 only** (`linux-x86_64` tarball). Add `aarch64` if Golem ships on ARM.
