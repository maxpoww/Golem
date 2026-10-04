{ config, lib, pkgs, ... }:

# Seam — the per-user half (home-manager): the package, prefs, look, its own profile,
# and "default browser". Imported by the Golem flake's home layer AND by the dev box's
# /etc/nixos/home.nix, so both run the same Seam. The system half (Mozilla build,
# policies, chrome script, update lane) is ./default.nix. See ./README.md.

let
  # Seam's profile. NOT ~/.mozilla/firefox: that is a plain Firefox's, which can be
  # installed beside Seam and must never share prefs, history, logins or lock files.
  # The launcher (browser.nix) passes -profile with exactly this path.
  profile = ".local/share/seam";
in
{
  home.packages = [
    pkgs.golem-seam
    (pkgs.writeShellScriptBin "seam-open" ''exec seam "$@"'')   # $BROWSER, see below
  ];

  # The Golem look (sidebar auto-hide, new-tab = bar colour, separator fix), shipped with Golem.
  home.file."${profile}/chrome/userChrome.css".source = ./userChrome.css;
  home.file."${profile}/chrome/userContent.css".source = ./userContent.css;

  # Golem's default browser: links, xdg-open, "open in browser" everywhere.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "seam.desktop" ];
      "application/xhtml+xml" = [ "seam.desktop" ];
      "x-scheme-handler/http" = [ "seam.desktop" ];
      "x-scheme-handler/https" = [ "seam.desktop" ];
      "x-scheme-handler/about" = [ "seam.desktop" ];
      "x-scheme-handler/unknown" = [ "seam.desktop" ];
    };
  };
  # $BROWSER names a launcher of its OWN, not `seam`: xdg-settings answers "which app
  # is the default browser" by taking the first .desktop whose command is $BROWSER's
  # program, ~/.local/share first — and every webapp runs `seam -golem-app …`. With
  # BROWSER=seam it named webapp-1password.desktop, and `check default-web-browser
  # seam.desktop` said NO (ASUS deep probe, 2026-10-02). No .desktop runs seam-open,
  # so the lookup falls through to the mime default above: seam.desktop.
  home.sessionVariables.BROWSER = "seam-open";

  # One-time move of a Beam-era profile (~/.mozilla/firefox/golem, 2026-09-27) into Seam's
  # own place, before home-manager links this generation's files into it; the old profile
  # is kept aside, and the profiles.ini Beam wrote is retired so a plain Firefox starts
  # clean. A fresh Golem install has neither and just gets the directory.
  home.activation.seamProfile = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    new="$HOME/${profile}"; old="$HOME/.mozilla/firefox/golem"
    if [ ! -e "$new" ] && [ -d "$old" ]; then
      run cp -a "$old" "$new"
      run rm -f "$new/lock" "$new/.parentlock"   # the copy is not the running instance's: a copied lock names Beam's live pid and Seam would see "profile in use"
      run mv "$old" "$old.moved-to-seam"
      ini="$HOME/.mozilla/firefox/profiles.ini"
      if [ -f "$ini" ] && grep -q '^Path=golem$' "$ini" && [ "$(grep -c '^\[Profile' "$ini")" = 1 ]; then
        run mv "$ini" "$ini.moved-to-seam"
      fi
    fi
    run mkdir -p "$new"
  '';

  # Prefs: scroll tuning (bisected), privacy, sidebar/vertical tabs, chrome-CSS loading.
  home.file."${profile}/user.js".text = ''
    // Managed by Golem (seam/home.nix) — edits here are overwritten.

    // --- Feel: Chrome-style spring physics (off by default) ---
    user_pref("general.smoothScroll", true);
    user_pref("general.smoothScroll.msdPhysics.enabled", true);
    user_pref("apz.overscroll.enabled", true);

    // --- Display rate: PER MACHINE, set by Seam itself (golem-chrome.js). ---
    // History: 2026-09-11 this pinned layout.frame_rate=165 because auto-detect
    // (-1) believes the panel's PREFERRED mode (60) and ran Max's 165 Hz panel
    // at a third of its rate. A distro can't pin one number: on a 60 Hz laptop
    // 165 renders ~3 frames per one shown. Since 2026-09-26 Seam asks the
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

    // Disk cache fixed 1GB instead of smart sizing. The MEMORY cache is
    // sized per machine from its RAM by golem-chrome.js (PER-MACHINE
    // MEMORY): 1 GB was right for the 31 GB dev box and wrong on a 4 GB
    // MacBook (2026-09-29).
    user_pref("browser.cache.disk.smart_size.enabled", false);
    user_pref("browser.cache.disk.capacity", 1048576);

    // Session snapshots every 60s instead of 15s. With a large restored
    // session each snapshot is real disk I/O — quarters the periodic
    // write jank. Cost: a hard crash loses up to 60s of tab state.
    user_pref("browser.sessionstore.interval", 60000);

    // Back/forward cache size (12 live pages on the dev box): per machine,
    // from its RAM, in golem-chrome.js (PER-MACHINE MEMORY).

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
    // Seam opens on the workspace YOU are on (Max, 2026-09-26: "seam opens
    // on this WS no matter where i am"). Firefox saves each window's
    // workspace at quit and session restore moved the window back there
    // (on Wayland via an activation token "for workspace placement"); the
    // dock then followed it, pulling you along. Tabs are still restored —
    // only the move is off.
    user_pref("browser.sessionstore.restore_windows_to_virtual_desktop", false);

    // ================= LEAN: NOTHING RUNS THAT SEAM DOES NOT SHOW =================
    // (2026-10-04, Max: "there is a lot of things that we dont use and will not use,
    // that is there, we just hide it… lightweight, simple and robust only on
    // navigation".) Measured on the 4 GB MacBook Air with a new profile: the first
    // start opened on "Welcome to Firefox / Terms of Use", and the second start
    // burned 25 s of CPU and kept 3 spare page processes for a blank tab.
    // Untouched on purpose: codecs, DRM, WebRTC, web push, translation, saved
    // passwords and form autofill, the site-compatibility fixes, certificate
    // revocation data, Safe Browsing, the captive-portal check — browsing needs them.

    // --- No first-run surfaces (the Terms-of-Use modal itself: SkipTermsOfUse policy) ---
    user_pref("browser.preonboarding.enabled", false);
    user_pref("browser.aboutwelcome.enabled", false);
    user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
    user_pref("browser.startup.homepage_override.mstone", "ignore");
    user_pref("startup.homepage_welcome_url", "");
    user_pref("startup.homepage_welcome_url.additional", "");
    user_pref("startup.homepage_override_url", "");
    user_pref("browser.uitour.enabled", false);
    // On a NEW profile Firefox "introduces" its sidebar toggle into the toolbar once,
    // whatever the layout says: the first launch had a button the second did not.
    user_pref("browser.toolbarbuttons.introduced.sidebar-button", true);
    // A preloaded new tab raced userContent.css: its colour was a coin toss.
    user_pref("browser.newtab.preload", false);

    // --- No experiments, no remote messaging, no promotions ---
    user_pref("app.normandy.enabled", false);
    user_pref("app.normandy.api_url", "");
    user_pref("messaging-system.rsexperimentloader.enabled", false);
    user_pref("messaging-system.askForFeedback", false);
    user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
    user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);
    user_pref("browser.vpn_promo.enabled", false);
    user_pref("browser.promo.pin.enabled", false);
    user_pref("browser.promo.relay.enabled", false);
    user_pref("extensions.getAddons.showPane", false);
    user_pref("extensions.getAddons.cache.enabled", false);
    user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);

    // --- No AI (the AIControls policy locks the features; these stop their engines) ---
    user_pref("browser.ml.enable", false);
    user_pref("browser.ml.chat.enabled", false);
    user_pref("browser.ml.chat.sidebar", false);
    user_pref("browser.ml.chat.menu", false);
    user_pref("browser.ml.chat.page", false);
    user_pref("browser.ml.chat.shortcuts", false);
    user_pref("browser.ml.linkPreview.enabled", false);
    user_pref("browser.tabs.groups.smart.enabled", false);
    user_pref("browser.tabs.groups.smart.userEnabled", false);
    user_pref("browser.smartwindow.autoTabGrouping.enabled", false);
    user_pref("extensions.ml.enabled", false);
    user_pref("pdfjs.enableAltText", false);

    // --- The new-tab engine: Seam's new tab is a blank page ---
    // Its feeds off (stories, weather, wallpapers, shortcuts). feeds.system.topsites
    // stays ON: the address bar's "your most visited" list on an empty focus reads it.
    user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
    user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
    user_pref("browser.newtabpage.activity-stream.feeds.system.topstories", false);
    user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
    user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);
    user_pref("browser.newtabpage.activity-stream.feeds.weatherfeed", false);
    user_pref("browser.newtabpage.activity-stream.discoverystream.enabled", false);
    user_pref("browser.newtabpage.activity-stream.showWeather", false);
    user_pref("browser.newtabpage.activity-stream.newtabWallpapers.enabled", false);
    user_pref("browser.startup.homepage.abouthome_cache.enabled", false);
    // That list is YOUR most used sites and nothing else (Max, 2026-10-04: "it shows
    // weird things, i want it to show most used websites" — a new tab listed YouTube,
    // Wikipedia, Reddit and "Add-ons for Firefox" on a machine that never visited
    // them, then "Recent Searches"). Firefox pads the list with its own default
    // sites (fetched from Mozilla, or a built-in per-country set) and with search-
    // engine shortcuts: none of them. No recent-searches block under it either.
    user_pref("browser.topsites.useRemoteSetting", false);
    user_pref("browser.newtabpage.activity-stream.default.sites", "");
    user_pref("browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts", false);
    user_pref("browser.urlbar.suggest.recentsearches", false);

    // --- Address bar: history, bookmarks, open tabs, search suggestions. Nothing else. ---
    user_pref("browser.urlbar.quicksuggest.enabled", false);
    user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
    user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
    user_pref("browser.urlbar.suggest.trending", false);
    user_pref("browser.urlbar.trending.featureGate", false);
    user_pref("browser.urlbar.suggest.weather", false);
    user_pref("browser.urlbar.suggest.yelp", false);
    user_pref("browser.urlbar.suggest.yelpRealtime", false);
    user_pref("browser.urlbar.suggest.addons", false);
    user_pref("browser.urlbar.suggest.mdn", false);
    user_pref("browser.urlbar.suggest.amp", false);
    user_pref("browser.urlbar.suggest.wikipedia", false);

    // --- Background bookkeeping nobody reads ---
    // Per-page interaction metrics, search-page categorisation (downloads its own
    // database), the profile picker, profile backups, region re-detection, a reader-
    // mode parse of EVERY page (Seam has no reader button), the remaining pings.
    user_pref("browser.places.interactions.enabled", false);
    user_pref("browser.search.serpEventTelemetryCategorization.enabled", false);
    user_pref("browser.profiles.enabled", false);
    user_pref("browser.backup.archive.enabled", false);
    user_pref("browser.backup.restore.enabled", false);
    user_pref("browser.region.update.enabled", false);
    user_pref("reader.parse-on-load.enabled", false);
    user_pref("browser.shopping.experience2023.enabled", false);
    user_pref("toolkit.telemetry.newProfilePing.enabled", false);
    user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
    user_pref("toolkit.telemetry.updatePing.enabled", false);
    user_pref("toolkit.telemetry.bhrPing.enabled", false);
    user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
    user_pref("toolkit.telemetry.coverage.opt-out", true);
    user_pref("toolkit.coverage.opt-out", true);
    user_pref("datareporting.usage.uploadEnabled", false);
    user_pref("browser.tabs.crashReporting.sendReport", false);
  '';
}
