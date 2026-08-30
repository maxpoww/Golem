# todoSH — SH Harden what exists (Arc 1, current section)

<!-- The "working perfectly" pass. Freeze rule: fix, don't grow. -->

- [ ] Bug inventory: Max lists every known glitch/annoyance in the live
      surfaces (dock, openbox, install, clipboard, notifs, topbar) — one
      line each, here; incomplete-by-design gaps go to optionsmodules.md
      ideas instead
- [ ] Foreign-hardware audit: grep the daemon/flake for Max-machine
      assumptions (hostnames, paths, hardcoded outputs/scales, GPU
      assumptions, llvmpipe fallback)
- [ ] Graceful-degradation sweep: every best-effort dep (grim, curl,
      nix-index, Flathub, Papirus, google-chrome-stable for webapps)
      absent → no crash, sane fallback (webapps without Chrome?)
- [ ] Cold-start test: fresh user account, empty caches/config — daemon
      comes up correct (no seeded pins/groups/webapps assumptions)
- [ ] Multi-resolution/scale check: works at 1080p scale 1 and HiDPI
      scale 2 (hidpi_rendering memory)
- [ ] Error-path audit: install worker failures, socket errors, IPC
      timeouts all surface gently (no silent wedges)
- [ ] One week daily driving with a notes file; every surprise → a fix or
      a filed line here
- [ ] Exit review: zero known brokenness → open S7
