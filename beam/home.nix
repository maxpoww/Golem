{ config, lib, ... }:

# Beam — the per-user half (home-manager): prefs, look, and the `golem` profile.
# Imported by the Golem flake's home layer AND by the dev box's /etc/nixos/home.nix,
# so both run the same Beam. The system half (Firefox build, policies, chrome
# script, update lane) is ./default.nix. See ./README.md.

{
  # The Golem look (sidebar auto-hide, new-tab = bar colour, separator fix). Until
  # 2026-09-25 these were hand-edited files in the profile — now they ship with Golem.
  home.file.".mozilla/firefox/golem/chrome/userChrome.css".source = ./userChrome.css;
  home.file.".mozilla/firefox/golem/chrome/userContent.css".source = ./userContent.css;

  # The `golem` profile must exist and be the default, so plain `firefox` (the dock,
  # xdg-open, links) opens Beam. Created ONLY if missing — an existing profiles.ini is
  # never rewritten (the wrapper sets MOZ_LEGACY_PROFILES=1, so Default=1 is honoured).
  home.activation.beamProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ini="$HOME/.mozilla/firefox/profiles.ini"
    run mkdir -p "$HOME/.mozilla/firefox/golem"
    if [ ! -e "$ini" ]; then
      run install -m 0644 /dev/stdin "$ini" <<'EOF'
[Profile0]
Name=golem
IsRelative=1
Path=golem
Default=1

[General]
StartWithLastProfile=1
Version=2
EOF
    elif ! grep -q '^Path=golem$' "$ini"; then
      n=$(grep -c '^\[Profile' "$ini" || true)
      run sh -c "printf '\n[Profile%s]\nName=golem\nIsRelative=1\nPath=golem\n' '$n' >> '$ini'"
    fi
  '';

  # Prefs: scroll tuning (bisected), privacy, sidebar/vertical tabs, chrome-CSS loading.
  home.file.".mozilla/firefox/golem/user.js".text = ''
    // Managed by Golem (beam/home.nix) — edits here are overwritten.

    // --- Feel: Chrome-style spring physics (off by default) ---
    user_pref("general.smoothScroll", true);
    user_pref("general.smoothScroll.msdPhysics.enabled", true);
    user_pref("apz.overscroll.enabled", true);

    // --- Display rate: PER MACHINE, set by Beam itself (golem-chrome.js). ---
    // History: 2026-09-11 this pinned layout.frame_rate=165 because auto-detect
    // (-1) believes the panel's PREFERRED mode (60) and ran Max's 165 Hz panel
    // at a third of its rate. A distro can't pin one number: on a 60 Hz laptop
    // 165 renders ~3 frames per one shown. Since 2026-09-26 Beam asks the
    // compositor (hyprctl monitors -j) at startup and sets the pref LIVE to the
    // real rate — 165 here, 60/120/144 elsewhere. Nothing to set in this file.
    // (If detection ever fails, Firefox's own -1 applies; golem-media.json says.)

    // --- Touchpad: LINE mode (1), not pixel (2) — changed for FF156.
    // Pixel mode was the 155 choice (1:1 tracking, good speed). On 156
    // its delta scaling changed: scrolling went sluggish ("slow, like
    // 60hz"). Line mode routes the touchpad through the smoothScroll
    // springs below, which also fills the ~130Hz-touchpad / 165Hz-panel
    // gap with synthesized frames. Default 0 = page, coarsest.
    user_pref("apz.gtk.kinetic_scroll.enabled", true);
    user_pref("apz.gtk.pangesture.delta_mode", 1);
    user_pref("mousewheel.min_line_scroll_amount", 1);

    // --- Wheel: keep slow input counted as one continuous motion ---
    user_pref("general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS", 300);

    // --- Slowdown detector: less eager, and gentler when it fires.
    // All three springs matched so there is no abrupt handover.
    user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaMS", 50);
    user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaRatio", "2.5");
    user_pref("general.smoothScroll.msdPhysics.slowdownSpringConstant", 700);
    user_pref("general.smoothScroll.msdPhysics.motionBeginSpringConstant", 700);
    user_pref("general.smoothScroll.msdPhysics.regularSpringConstant", 700);

    // --- Displayport lookahead overrides: REMOVED on FF156. ---
    // The 155-tuned skate/stationary/danger/expiry values (4x lookahead
    // etc.) turned HARMFUL on 156 — firm periodic stalls; stock defaults
    // measured clearly better ("way better", 2026-09-12). If these ever
    // come back, they must be re-bisected against the running version,
    // and the stale user-set values purged from prefs.js — commenting
    // them out here does NOT reset an already-set pref.

    // --- Work per repaint. 256 beat 512 and 128 on 155; unproven but
    // harmless on 156 — kept because the blessed final feel includes it.
    user_pref("gfx.webrender.picture-tile-height", 256);

    // --- Native fractional scaling for the 1.60 scale factor.
    // Already default in FF155; pinned so it survives a regression.
    user_pref("widget.wayland.fractional-scale.enabled", true);

    // --- THE second most important value (FF156 regression fix). ---
    // 156's Wayland frame-callback pacing presents INPUT-driven (APZ)
    // scrolling at a fraction of the refresh rate: a JS-driven scroll
    // measured 160fps while the same slow touchpad scroll looked
    // 30-60Hz (kicks with VRR on; duplicated-frame blur with VRR off).
    // false = pace from Firefox's own timer, which layout.frame_rate
    // above pins to the panel's 165. Fixed it instantly (2026-09-12).
    // Trade-off to remember: the timer renders at full rate even when
    // the compositor would throttle — fine here, revisit on battery.
    user_pref("widget.wayland.vsync.enabled", false);

    // Scroll gain: percent of each touchpad/wheel delta. 100 = stock;
    // 85 = Max's "slightly less responsive". The distance dial,
    // independent of pacing and springs.
    user_pref("mousewheel.default.delta_multiplier_y", 85);

    // Timer pacing broke partial-present integrity: tiny damage rects
    // during slow scrolling flickered (stale buffer ages without
    // callback bookkeeping). 0 = always present the full frame; the
    // full-frame path measured 160fps here, so it is already paid for.
    // These two prefs are a PAIR with vsync.enabled=false above.
    user_pref("gfx.webrender.max-partial-present-rects", 0);

    // Hardware video decode (pairs with intel-media-driver in
    // nvidia-module.nix). Keeps YouTube off the CPU so video pages
    // stop stealing the scroll budget. Revert if video glitches.
    user_pref("media.ffmpeg.vaapi.enabled", true);

    // ================= MEDIA: COMPLETE OUT OF THE BOX ================
    // DRM. The policy in golem-browser.nix pre-consents EME for fresh
    // installs; these make THIS profile provision Widevine immediately
    // (the CDM auto-downloads into the profile as a GMP).
    user_pref("media.eme.enabled", true);
    user_pref("media.gmp-widevinecdm.enabled", true);
    user_pref("media.gmp-widevinecdm.visible", true);

    // HEVC playback via the system ffmpeg (H.264/AAC/MP3/VP9/AV1 are
    // already covered by the nixpkgs build + bundled ffvpx). If this
    // pref turns out to be integer-typed in a future version a bool is
    // silently ignored — harmless either way.
    user_pref("media.hevc.enabled", true);

    // ================= PERFORMANCE PASS (2026-09-12) =================
    // Constraint honoured: nothing here touches the scroll stack,
    // privacy, or ad-blocking. Caches, I/O cadence, network parallelism.

    // Accessibility engine instantiation. When ANY tool speaks the a11y
    // API, Firefox mirrors every page into it — a 10-30% tax on heavy
    // pages. 1 = never instantiate. MUST become 0 if a screen reader or
    // other assistive tech is ever needed.
    user_pref("accessibility.force_disabled", 1);

    // 31GB machine: memory cache 1GB (units are KB; auto caps far
    // lower), disk cache fixed 1GB on the NVMe instead of smart sizing.
    user_pref("browser.cache.memory.capacity", 1048576);
    user_pref("browser.cache.disk.smart_size.enabled", false);
    user_pref("browser.cache.disk.capacity", 1048576);

    // Session snapshots every 60s instead of 15s. With a large restored
    // session each snapshot is real disk I/O — quarters the periodic
    // write jank. Cost: a hard crash loses up to 60s of tab state.
    user_pref("browser.sessionstore.interval", 60000);

    // Back/forward cache: keep 12 pages alive (auto ~8) — instant
    // back-button on this much RAM.
    user_pref("browser.sessionhistory.max_total_viewers", 12);

    // BACK IS INSTANT (Max, 2026-09-26: "going back should be instant").
    // Firefox drops any page with an "unload" handler from that cache —
    // and analytics/ad scripts add one to most sites — so BACK reloaded
    // it instead. Allowed here: measured on a heavy page 224ms -> 24ms,
    // served from the cache. Such pages get "pagehide" instead of
    // "unload" when you leave (Chrome is phasing unload out entirely).
    // "no-store" pages (banks etc.) still never go in the cache — that's
    // the site's explicit wish, kept.
    user_pref("docshell.shistory.bfcache.allow_unload_listeners", true);

    // Memory budget ~ Chrome's: when the SYSTEM runs low on memory,
    // unload the least-recently-used tab idle for 10+ minutes (Firefox
    // watches /proc/meminfo + PSI on Linux but ships this OFF there).
    // Never the current tab, one playing sound, a call, picture-in-
    // picture or a private tab. The tab reloads when you pick it.
    user_pref("browser.tabs.unloadOnLowMemory", true);

    // Media memory buffer 64MB (default 8MB) — smoother video seeking.
    user_pref("media.memory_cache_max_size", 65536);

    // Network: 10 parallel connections per server (default 6), no
    // artificial request pacing — image-heavy pages fill faster.
    user_pref("network.http.max-persistent-connections-per-server", 10);
    user_pref("network.http.pacing.requests.enabled", false);

    // DNS: 2000 entries for an hour (defaults ~400 for 60s). Local
    // cache only, no privacy surface.
    user_pref("network.dnsCacheEntries", 2000);
    user_pref("network.dnsCacheExpiration", 3600);

    // Mozilla's connectivity probe — periodic pings; perf-and-privacy
    // aligned removal. (Captive-portal probe already off in this build.)
    user_pref("network.connectivity-service.enabled", false);

    // ================= THEME: FOLLOW THE SYSTEM =================
    // Max's call (2026-09-12): no forced dark, no toggle button — the
    // browser tracks the system scheme, and light/dark is Golem's job
    // (the portal / OPTIONS side), not the browser's. The old forced-
    // dark pins were removed from prefs.js too — a pref deleted here
    // but left there would silently keep forcing dark.

    // No sign-in / sync ANYWHERE. The DisableFirefoxAccounts policy in
    // golem-browser.nix kills it at the package level; this master pref
    // is the immediate + redundant kill (it is what removes the
    // "Sign in" footer from the History and Bookmarks panels).
    user_pref("identity.fxaccounts.enabled", false);
    user_pref("identity.fxaccounts.toolbar.enabled", false);

    // ================= DEBLOAT + VERTICAL TABS =================
    // (2026-09-12, Max.) The FUNCTION: buttons not menus, no sync, no
    // scrollbars, tabs vertical. Feature-level kills are policies in
    // golem-browser.nix. The chrome script (golem-browser.nix ->
    // golem-chrome.js) owns the sidebar action buttons and forces the
    // launcher expanded; the profile's userChrome.css holds the functional
    // hides plus the sidebar auto-hide slide. This layout pref places the
    // nav-bar buttons.
    user_pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[],\"nav-bar\":[\"back-button\",\"forward-button\",\"stop-reload-button\",\"urlbar-container\",\"ublock0_raymondhill_net-browser-action\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"tabbrowser-tabs\"],\"PersonalToolbar\":[\"personal-bookmarks\"]},\"seen\":[\"save-page-button\",\"downloads-button\",\"history-panelmenu\",\"bookmarks-menu-button\",\"privatebrowsing-button\",\"new-window-button\",\"ublock0_raymondhill_net-browser-action\"],\"dirtyAreaCache\":[\"nav-bar\",\"TabsToolbar\",\"toolbar-menubar\",\"PersonalToolbar\"],\"currentVersion\":99,\"newElementCount\":0}");

    // Tabs vertical, via the native sidebar revamp (no extension).
    //
    // AUTO-HIDE: the sidebar is always present ("always-show") and forced
    // EXPANDED (full-width tab rows with titles) — Firefox's own
    // expandOnHover is OFF. userChrome.css slides that expanded sidebar
    // off-screen, leaving a 4px opaque sliver, and reveals it on hover.
    // Doing the hide/reveal in CSS (not native) is what makes the reveal
    // genuine full width: native hide collapses to a useless icon rail.
    // The launcher is forced expanded by the chrome script
    // (setAttribute("expanded")) because the pref/backupState alone render
    // the rail; backupState below just pre-seeds it so the first paint is
    // already expanded (no collapse flash before the script runs).
    user_pref("sidebar.main.tools", "");
    user_pref("sidebar.revamp", true);
    user_pref("sidebar.verticalTabs", true);
    user_pref("sidebar.visibility", "always-show");
    user_pref("sidebar.expandOnHover", false);
    user_pref("sidebar.backupState", "{\"command\":\"\",\"panelOpen\":false,\"launcherWidth\":255,\"expandedLauncherWidth\":255,\"launcherExpanded\":true,\"launcherVisible\":true}");
    user_pref("sidebar.verticalTabs.dragToPinPromo.dismissed", true);
    user_pref("browser.toolbars.bookmarks.visibility", "never");
    user_pref("browser.download.autohideButton", false);

    // ================= PRIVACY =================
    // The blocker itself (uBlock Origin) is force-installed by policy in
    // golem-browser.nix. These are the settings around it.

    // --- Enhanced Tracking Protection, STRICT ---
    // Firefox's own anti-tracker, and it is genuinely good — the reason no
    // second anti-tracking EXTENSION is installed. Strict turns on Total
    // Cookie Protection (dFPI): every site gets its own cookie jar, so a
    // tracker embedded on twenty sites cannot join them up. That defeats
    // cross-site tracking structurally rather than by blocklist, which is
    // the part uBlock Origin cannot do.
    user_pref("browser.contentblocking.category", "strict");
    user_pref("network.cookie.cookieBehavior", 5);
    user_pref("privacy.trackingprotection.enabled", true);
    user_pref("privacy.trackingprotection.socialtracking.enabled", true);
    user_pref("privacy.trackingprotection.cryptomining.enabled", true);
    user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
    user_pref("privacy.trackingprotection.emailtracking.enabled", true);

    // Strip known tracking parameters (fbclid, gclid, utm_*) from URLs.
    user_pref("privacy.query_stripping.enabled", true);
    user_pref("privacy.query_stripping.enabled.pbmode", true);

    // A legally-recognised "do not sell/share" signal, unlike the old DNT
    // header which was ignored and merely added fingerprinting entropy.
    user_pref("privacy.globalprivacycontrol.enabled", true);

    // --- Transport ---
    // HTTPS by default, with a click-through rather than a hard failure.
    user_pref("dom.security.https_only_mode", true);
    user_pref("dom.security.https_only_mode_ever_enabled", true);

    // WebRTC leaks your LAN address to any page that asks, with no prompt.
    // This restricts it to the default route instead of disabling
    // peerconnection outright, which would break video calls.
    user_pref("media.peerconnection.ice.default_address_only", true);

    // --- Nothing phones home ---
    user_pref("toolkit.telemetry.enabled", false);
    user_pref("toolkit.telemetry.unified", false);
    user_pref("toolkit.telemetry.archive.enabled", false);
    user_pref("datareporting.healthreport.uploadEnabled", false);
    user_pref("datareporting.policy.dataSubmissionEnabled", false);
    user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
    user_pref("browser.newtabpage.activity-stream.telemetry", false);
    user_pref("app.shield.optoutstudies.enabled", false);
    user_pref("browser.discovery.enabled", false);

    // No sponsored content anywhere.
    user_pref("browser.newtabpage.activity-stream.showSponsored", false);
    user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
    user_pref("browser.urlbar.suggest.sponsored", false);
    user_pref("extensions.pocket.enabled", false);

    // NOT set, deliberately — see the notes when this was added:
    //   privacy.resistFingerprinting — the strongest anti-fingerprinting
    //     lever, but it spoofs timezone, screen size, canvas and fonts, so
    //     sites mis-render and clocks read wrong. Opt-in, not a default.
    //   network.trr.mode (DNS-over-HTTPS) — hides DNS from the local
    //     network but hands every lookup to one resolver. A trade, not an
    //     improvement; pick a provider deliberately or leave it.

    // --- Golem UI: blank slate ---
    // Required before Firefox will load chrome/userChrome.css at all.
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
    // No shortcut tiles / sponsored content on a new tab — just blank.
    user_pref("browser.newtabpage.enabled", false);
    user_pref("browser.startup.homepage", "about:blank");
    // ALWAYS restore the previous session. 3 = resume where you left off
    // (0 would be a blank page, 1 the homepage).
    user_pref("browser.startup.page", 3);
    // Restore after a crash too, not just a clean exit — otherwise a hang
    // loses the session that this setting exists to keep.
    user_pref("browser.sessionstore.resume_from_crash", true);
    // Beam opens on the workspace YOU are on (Max, 2026-09-26: "beam opens
    // on this WS no matter where i am"). Firefox saves each window's
    // workspace at quit and session restore moved the window back there
    // (on Wayland via an activation token "for workspace placement"); the
    // dock then followed it, pulling you along. Tabs are still restored —
    // only the move is off.
    user_pref("browser.sessionstore.restore_windows_to_virtual_desktop", false);
  '';
}
