{ ... }:

# Seam (Golem's browser) — the system half: the Firefox build, enterprise policies and
# the chrome script. Moved here from /etc/nixos/golem-browser.nix (2026-09-25) so the
# Golem flake and the dev box share ONE Seam. Part of ./default.nix.
#
# Golem's browser: privacy defaults.
#
# Two halves, deliberately:
#   * POLICIES (here) — things that must be true before the first launch and
#     that the user should not have to install by hand: the content blocker,
#     telemetry off. Delivered as Firefox enterprise policies baked into the
#     package, so a fresh Golem install has them on boot.
#   * PREFS (home.nix) — the tracking-protection settings themselves, which
#     live alongside the rest of the browser's user.js.
#
# Done as an OVERLAY rather than `programs.firefox` on purpose: the firefox
# package comes from ~/.config/waverunner/packages.list (generated into
# waverunner-packages.nix). `programs.firefox` would wrap firefox into a
# SECOND, different derivation and collide with that one. An overlay replaces
# the single `firefox` attribute, so the generated package list transparently
# picks up the hardened build.

{
  nixpkgs.overlays = [
    (final: prev: {
      # Base = Mozilla's own build pinned by the Seam update lane
      # (~/Golem/seam: sources.json + seam-update.timer), NOT the channel's
      # firefox, which lags Mozilla's security releases by days.
      # (Until 2026-09-27 this overrode `firefox` itself, so "install Firefox" gave Beam.
      # Seam is its own package now; `pkgs.firefox` is plain Firefox again, side by side.)
      golem-seam-wrapped = final.golem-seam-base.override {
        # The Golem chrome script — privileged UI foundation. extraPrefs
        # is appended verbatim into mozilla.cfg (the autoconfig file);
        # the sandbox pref below is what elevates it from pref-setting to
        # full chrome JS. Ships with the package, survives FF updates.
        # See golem-chrome.js for the feature set and the hard-won facts.
        extraAutoConfig = ''
          pref("general.config.sandbox_enabled", false);
        '';
        extraPrefs = builtins.readFile ./golem-chrome.js;

        extraPolicies = {
          # ---- the content blocker -------------------------------------
          #
          # uBlock Origin, force-installed. This is the FULL uBO, not uBO
          # Lite — it still exists on Firefox because Firefox kept Manifest
          # V2. On Chromium (152 here) MV2 is long gone and only the weaker
          # Lite build survives; that asymmetry is a large part of why this
          # browser is Firefox at all.
          #
          # ONE blocker, on purpose. Stacking Privacy Badger / Ghostery /
          # AdGuard on top buys almost nothing over uBO + strict tracking
          # protection, and multiple blockers racing on the same request
          # cause breakage that is miserable to diagnose.
          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              install_url =
                "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
              private_browsing = true;
              # On the toolbar itself — the extensions puzzle-menu is
              # hidden, and the uBO popup is the only un-break-this-site
              # escape hatch, so it must stay reachable.
              default_area = "navbar";
            };

            # Adaptive Tab Bar Colour (ATBC) — RESTORED (2026-09-25). A built-in
            # pixel-sampling replacement was tried and rejected live ("it sucks…
            # wrong color"): one sampled pixel lands on text/images/edges, while
            # ATBC reads the page's element colours. Don't replace it with pixel
            # sampling again. Earlier note: its content script coincided with a
            # measured scroll regression on this machine.
            "ATBC@EasonWong" = {
              install_url =
                "https://addons.mozilla.org/firefox/downloads/latest/adaptive-tab-bar-colour/latest.xpi";
              installation_mode = "force_installed";
              private_browsing = true;
            };
          };

          # ---- debloat: windows, tabs, search — nothing else -----------
          # (2026-09-12, Max's spec.) Killed at the FEATURE level so no
          # shortcut or hidden path resurrects them; the visible chrome
          # cuts live in userChrome.css + browser.uiCustomization.state.
          DisableDeveloperTools = true;
          DisableFirefoxAccounts = true;
          # Password saving ON (Max, 2026-09-26: "turn on saving passwords").
          # Local only: Firefox accounts/sync are disabled below, so logins
          # never leave the machine (logins.json, encrypted with key4.db).
          PasswordManagerEnabled = true;
          OfferToSaveLogins = true;
          DisableProfileImport = true;
          DontCheckDefaultBrowser = true;
          DisableSetDesktopBackground = true;
          DisableFirefoxScreenshots = true;

          # uBO managed settings. (Managed-storage format: [name, value].)
          "3rdparty" = {
            Extensions = {
              "uBlock0@raymondhill.net" = {
                # (A showIconBadge=false setting sat inside adminSettings, where
                # uBO ignores it, so the blocked-count badge always showed. Max
                # likes the number (2026-09-26): removed, badge stays. Don't
                # "fix" it back.)
                # Top-level userSettings — uBO's managed-storage key (inside
                # adminSettings it is NOT applied; measured 2026-09-26).
                # prefetchingDisabled=false (Max's call, 2026-09-26): uBO's
                # default turns off ALL of Firefox's connection warming
                # (network.http.speculative-parallel-limit=0, DNS prefetch off)
                # — no preconnect on link hover, from the address bar, or for
                # Early Hints. Measured on a link click with a 150ms handshake:
                # 221 -> 58ms (hovered link), 223 -> 102ms (instant click), i.e.
                # stock Firefox's speed. Privacy cost: a bare connection (no
                # request, no cookies) may open before the click; uBO still
                # blocks every actual request.
                userSettings = [ [ "prefetchingDisabled" "false" ] ];
              };
            };
          };

          # ---- DRM: complete out of the box ----------------------------
          # Netflix / Spotify / Disney+ need the Widevine CDM. Enabled=true
          # pre-consents EME so Firefox provisions the CDM on its own —
          # no "enable DRM?" bar on a fresh Golem install. Unlocked so it
          # can still be turned off from settings.
          EncryptedMediaExtensions = {
            Enabled = true;
            Locked = false;
          };

          # ---- tracking protection -------------------------------------
          # The policy switch; the detailed prefs are in home.nix. Left
          # unlocked so it can still be turned off per-site from the UI.
          EnableTrackingProtection = {
            Value = true;
            Locked = false;
            Cryptomining = true;
            Fingerprinting = true;
            EmailTracking = true;
          };

          # ---- nothing phones home -------------------------------------
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          # The "feature recommendation" surfaces that fetch remote content.
          UserMessaging = {
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
            MoreFromMozilla = false;
          };

          # Crash reports carry URLs and memory contents.
          DisableFeedbackCommands = true;
          # No first-run / post-update pages phoning out.
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
        };
      };

      # THE Seam package: the wrapped browser plus (1) a launcher that gives it its OWN
      # profile — ~/.local/share/seam, never ~/.mozilla, so a plain Firefox beside it is
      # untouched and unaware — (2) its own desktop entry (Name=Seam, class seam, the
      # web-browser MIME types, so it can be the default browser) and (3) its own icon.
      golem-seam = final.symlinkJoin {
        name = "seam-${final.golem-seam-unwrapped.version}";
        paths = [ final.golem-seam-wrapped ];
        passthru = { version = final.golem-seam-unwrapped.version; wrapped = final.golem-seam-wrapped; };
        postBuild = ''
          rm -f "$out/bin/firefox" "$out/bin/seam"   # only `seam` on the PATH: a plain Firefox's `firefox` stays its own
          cat > "$out/bin/seam" <<'EOF'
          #!${final.runtimeShell}
          # Seam — Golem's browser. Its own profile; --name sets the window class.
          p="''${XDG_DATA_HOME:-$HOME/.local/share}/seam"
          mkdir -p "$p"
          exec "${final.golem-seam-wrapped}/bin/firefox" --name seam -profile "$p" "$@"
          EOF
          chmod +x "$out/bin/seam"
          rm -rf "$out/share/applications" "$out/share/icons"
          mkdir -p "$out/share/applications" "$out/share/icons/hicolor/scalable/apps"
          cp ${./seam.svg} "$out/share/icons/hicolor/scalable/apps/seam.svg"
          cat > "$out/share/applications/seam.desktop" <<'EOF'
          [Desktop Entry]
          Type=Application
          Version=1.5
          Name=Seam
          GenericName=Web Browser
          Comment=Golem's browser
          Exec=seam %U
          Icon=seam
          Terminal=false
          StartupNotify=true
          StartupWMClass=seam
          Categories=Network;WebBrowser;
          Keywords=web;browser;internet;
          MimeType=text/html;text/xml;application/xhtml+xml;application/xml;x-scheme-handler/http;x-scheme-handler/https;
          Actions=new-window;new-private-window;

          [Desktop Action new-window]
          Name=New Window
          Exec=seam --new-window %U

          [Desktop Action new-private-window]
          Name=New Private Window
          Exec=seam --private-window %U
          EOF
        '';
      };
    })
  ];
}
