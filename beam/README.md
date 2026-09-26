# Beam — security update lane

Beam is Golem's browser: **Mozilla's official Firefox Linux build**, wrapped with
Golem's chrome script (`golem-chrome.js`: tab overview, tool row, bar pinning) and
enterprise policies (uBlock Origin, telemetry off, …) by `/etc/nixos/golem-browser.nix`.

This directory keeps Beam on Mozilla's **current** release. A browser can't wait days
for a distro channel. On 2026-09-25 Mozilla shipped **156.0.1** while nixpkgs, even
unstable, was still on 156.0.

## Files — Beam is ONE module (since 2026-09-25)

| file | role |
|---|---|
| `default.nix` | **the module**: import this directory (Golem flake `golemModules`; dev box `/etc/nixos/configuration.nix`) |
| `browser.nix` | Firefox build (Mozilla's, pinned) + enterprise policies (uBO, ATBC, telemetry off…) + the chrome script |
| `golem-chrome.js` | **the chrome script**: tab overview, tool row, bar pinning, safety net, blank-tab fixes. **Edit HERE.** |
| `home.nix` | per-user half (home-manager): `user.js` prefs, `userChrome.css`/`userContent.css`, creates the `golem` profile |
| `userChrome.css`, `userContent.css` | the Beam look (were hand-edited profile files until 2026-09-25) |
| `sources.json` | **the pin**: Firefox version, Mozilla tarball URL, SHA-256 (from Mozilla's `SHA256SUMS`) |
| `lane.nix` | security update lane: overlay from the pin, `beam-update`, `beam-selftest`, `beam-update.timer` |
| `update.sh`, `selftest.sh` | bodies of `beam-update` / `beam-selftest` |

**Where it's imported:**
- **Golem flake:** `flake.nix` `golemModules` imports `./beam`, and `system/home/home.nix` imports `../../beam/home.nix`.
- **Dev box:** `/etc/nixos/configuration.nix` imports `/home/max/Golem/beam`, and `/etc/nixos/home.nix` imports `/home/max/Golem/beam/home.nix`.
- **One source of truth.** The old `/etc/nixos/golem-browser.nix` and `golem-chrome.js` were retired to `~/beam-retired-from-etc-nixos/`.

**Update lane, per system:**
- **Golem (flake).** The updater writes the pin into the machine's own checkout (`golem.flakeDir`/beam), `git add`s it (a flake only sees tracked files), then runs `nixos-rebuild switch --flake <flakeDir>#<flakeAttr>`.
- **Dev box (channel).** It updates the pin in this directory and runs plain `nixos-rebuild switch`.
- **Post-update self-test.** It runs as `nobody` on a world-readable copy of the pin and script, because the owner's home isn't readable by `nobody`.

⛔ **Never evaluate the flake with a `path:` ref.** It copies all of ~/Golem (about 70 GB) into the store and filled the disk on 2026-09-25. Use `git+file:///home/max/Golem`.

## How an update flows

1. **`beam-update.timer`** fires every 4h (and 10 min after boot; catches up after sleep).
2. It waits for the network (`golem-wait-online`, the same gate as the daily upgrade).
3. It asks Mozilla for the current release:
   `product-details.mozilla.org/1.0/firefox_versions.json` → `LATEST_FIREFOX_VERSION`.
4. If the release is newer than the pin, it takes the hash from Mozilla's
   `releases/<v>/SHA256SUMS` and rewrites `sources.json` atomically. The old pin is kept as `sources.json.prev`.
5. It runs `nixos-rebuild switch`. **Only Beam changes.** The channel isn't bumped; that stays with the daily `nixos-upgrade`.
   - If the build fails, the old pin is restored and the unit fails (visible in `systemctl status beam-update`). You never end up with a broken pin.
6. **Notifies you**: "Beam updated to X — restart Beam to apply". A running browser keeps
   its old binary until relaunched. Session restore brings the tabs back.

It never downgrades (it compares with `sort -V`), and it serializes with other rebuilds via
`/run/golem-rebuild.lock`. The only outbound requests go to Mozilla's public endpoints, carrying no identifiers.
Firefox's own updater is disabled (`DisableAppUpdate`). This lane replaces it.

## Commands

```
beam-update --check          # pinned / built / latest, changes nothing (any user)
sudo beam-update             # update now if Mozilla has a newer release
sudo beam-update --force     # re-pin to latest and rebuild even if current
systemctl status beam-update # last run
journalctl -u beam-update    # history
systemctl list-timers beam-update
```

**Rollback:** `sudo mv ~/Golem/beam/sources.json.prev ~/Golem/beam/sources.json && sudo nixos-rebuild switch`,
or boot the previous generation.

## Safety net (2026-09-25)

Beam takes every Firefox release automatically, and Firefox changes its internal UI
structure without notice. `golem-chrome.js` therefore protects itself:

- **The overview never leaves the browser broken.** Open, close and switch are guarded. Any error runs
  `ovRestore`, which puts back the content, the nav bar and the bar colours, and disables the overview for
  that session.
- **Health check, once after startup** (no polling, so no cost while browsing). If a hook the overview needs is
  missing (`#browser`, `#tabbrowser-tabpanels`, `#nav-bar`, the toolbar slot, the grid button, the
  agent stylesheet), the overview switches off and Beam is plain, working Firefox. If the
  vertical-tab sidebar is gone as well, Firefox's horizontal tab strip comes back for that session.
- **Local only.** It writes `golem-health.json` in the profile and shows one desktop notice per
  Firefox version. Nothing is sent anywhere.
- **Tab switching is checked.** If Firefox silently ignores the tab change, Beam falls back to
  `tabContainer.selectedIndex`. (A headless run showed that it can ignore it.)

### Self-test

```
./selftest.sh              # full check: normal path + 6 simulated failures, headless
./selftest.sh --one nav-bar
```

It runs the **real installed Beam build** headless, with a throwaway profile and nothing on screen. It covers
the normal path (open → close → switch, then checks the browser is left in a clean state), and simulated
failures: `throw-open`, `nav-bar`, `tabbrowser-tabpanels`, `golem-overview-btn`, `agent-sheet`,
`sidebar-main`. It exits 0 only if every case passes. It passed 7/7 on 156.0.1, 2026-09-25.
**Run it after every Firefox update.** Next step: `beam-update` runs it automatically after each rebuild.

## Bar colour: Beam tint (replaces the ATBC extension)

ATBC injected a script into **every page**. That script re-sampled the page colour on every `scroll`, `click`,
`resize` and animation end, and ran 4 page observers. Each sample could rewrite the whole browser
theme and restyle all of the chrome. That's the scroll cost. Beam tint does the same job without any of it:

- **Source:** 2 px at the top centre of the **viewport**, the bar's edge and ATBC's own sample point, read from the
  rendered frame with `drawSnapshot`. `drawSnapshot`'s rect is **document-relative** (confirmed headless), so the
  read is offset by the tab's current scroll position.
- **When:** on page load, on in-page navigation, and **while scrolling** (the bar follows what's under it, like ATBC).
  A minimal frame script in each tab only sends "scrolled" plus the scroll position, at most one ping per
  120 ms and one more when scrolling stops. There are **no DOM queries in the page** (ATBC ran
  `elementsFromPoint` + `getComputedStyle` on every event). Samples are coalesced, one in flight, and the bar
  restyles **only when the colour actually changes**. ATBC rewrote the whole theme on every event.
- **Maths:** an exact port of ATBC's defaults, which are the settings Beam used (decoded from its storage 2026-09-25;
  none had been changed): contrast correction for white text, and near-white pages switch to a light bar with black text.
  Surfaces: frame/toolbar **and the vertical-tab sidebar** at +0 (Golem choice: ATBC used +5 for the sidebar), field/panel +5 %, field border +10, sidebar border / selected tab +15. Toolbar buttons incl. the grid button and tool row use `--toolbarbutton-icon-fill` (black/white per page).
- **Apply:** Beam sets its own `--gt-*` variables. An agent stylesheet (`:root[golem-tint]`) maps them onto
  Firefox 156's theme variables with `!important`, so nothing can overwrite them.
- **Cache:** per tab and per site. Tab switches paint the known colour straight away.

**Verification**
- `node tint-oracle-check.js ./atbc-colour-oracle.js /etc/nixos/golem-chrome.js`: the shipped maths
  compared with **ATBC's own colour class** (extracted from the extension) on 4,109 colours. Result: **0 mismatches** (bit-for-bit, dark and light).
- `./selftest.sh`: real pages (red, near-white, near-black) plus scroll cases (red top → white after scrolling down → red after scrolling back up; a fixed header keeps its colour), headless. Firefox's computed theme variables
  match the expected values, and the tint clears when switched off.

**Built in, on by default** for every user. There's nothing to configure. ATBC is set to `blocked` in
`golem-browser.nix` policies, so Firefox also uninstalls it from profiles that already had it.
(`golem.beam.tint=false` is a hidden kill switch for development only.)

## Performance

**Target:** Beam competes with Chrome, not plain Firefox. It should use the same memory as Chrome or less, and it should *feel* snappier. The benchmark harness is `bench/bench.sh`; its header lists the modes.

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

Beam now sets `prefetchingDisabled=false`. It has to be a **top-level** `userSettings` key in uBO's policy; inside `adminSettings` it isn't applied. Measured with a 150 ms handshake: 221 → 58 ms (hovered link), 223 → 102 ms (instant click). The benchmark is `BENCH_CLICK`. It needs public addresses (`BENCH_CLICK_HOST`/`BENCH_CLICK_HOST2`), because Firefox never preconnects to loopback or private addresses.

**Done 2026-09-26: restored tabs warm in the background.**
- **What:** after a restart, once the session is back, startup has settled and the UI is idle, the N most recently used restored tabs load in the background, one at a time. The rest stay unloaded. `golem.beam.warmTabs` sets N (default 5; 0 turns it off).
- **Mechanism:** Firefox's own lazy-tab `reload()` hook.
- **Tests:** selftest `bwTest`, plus a real restart test with `BENCH_RESTORE=1`.

**Done 2026-09-26: back is instant.** `docshell.shistory.bfcache.allow_unload_listeners=true` (in `home.nix`). Firefox drops pages with an `unload` handler from the back-forward cache, and most sites have one. Measured with `BENCH_BACK=3`: a heavy page came back in 224 ms before, 14–24 ms now. "no-store" pages (banks) are still never cached; that's the site's explicit wish.

**Done 2026-09-26: unload idle tabs when memory runs low.** `browser.tabs.unloadOnLowMemory=true`. The Linux watcher already exists but ships off. It unloads the least recently used tab idle for 10+ minutes; never the current tab, one playing sound, a call, picture-in-picture or a private tab. Verified by calling `TabUnloader.unloadTabAsync`, the watcher's own call.

## Why Mozilla's build and not nixpkgs'

- **Speed:** the pin tracks Mozilla directly, so the delay is hours, not the days a channel takes.
- **No compiling:** Golem runs on varied hardware, and a weak laptop must never build Firefox from source. The tarball is Mozilla's prebuilt binary, verified against their checksum.
- **Same Beam:** `wrapFirefox` accepts the same `extraPrefs` / `extraPolicies` / `extraAutoConfig`, so the chrome script and policies are unchanged.

## Known limits / next steps

- **Channel choice:** this tracks the **rapid release** (`LATEST_FIREFOX_VERSION`).
  To move to ESR, where internals stay stable for about a year and security point releases still arrive, switch the key to `FIREFOX_ESR` and
  the URL path. It's a two-line change in `update.sh`. Still to be decided.
- **Distro build:** today `beam.nix` is imported by `/etc/nixos`. The Golem flake should import
  it too, so installed systems get the same lane.
- **x86_64 only** (`linux-x86_64` tarball). Add `aarch64` if Golem ships on ARM.
