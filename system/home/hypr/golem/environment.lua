local M = require("golem.lib").machine

---- ENVIRONMENT VARIABLES ----
-- The owner's REAL login shell (machine.shell, from users.users.<owner>.shell):
-- zsh on the dev box, plain bash on an install, where a fixed zsh made
-- every bare `foot` die at once (thinkpad, 2026-09-29).
hl.env("SHELL",          M.shell)
-- Where the zone files are. A zone picked in the control panel rides the
-- session as a bare name (TZ=America/…); glibc has no built-in place for
-- the files on NixOS, so without this every clock read UTC (2026-10-20).
hl.env("TZDIR",          "/etc/zoneinfo")
-- What apps launched from here should use (a .desktop entry with
-- Terminal=true needs $TERMINAL; without it xdg-open had nothing to run).
hl.env("TERMINAL",       "foot")
hl.env("EDITOR",         "nvim")
hl.env("VISUAL",         "nvim")
hl.env("XCURSOR_THEME",  "phinger-cursors-light")
hl.env("XCURSOR_SIZE",   "24")
hl.env("HYPRCURSOR_THEME", "phinger-cursors-light")
hl.env("HYPRCURSOR_SIZE",  "24")

---- ENVIRONMENT VARIABLES ----
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
