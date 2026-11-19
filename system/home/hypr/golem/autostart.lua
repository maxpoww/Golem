local M = require("golem.lib").machine

---- AUTOSTART ----
hl.on("hyprland.start", function()
-- The lock screen first: it is the login (home/idle.nix, golem-lock-screen).
hl.exec_cmd("golem-lock-screen --login")
-- The overview plugin: an install loads the one this system was built with,
-- the dev box its live build (machine.plugin).
if M.plugin then
    hl.exec_cmd("hyprctl plugin load " .. M.plugin)
end
hl.exec_cmd("hyprctl setcursor phinger-cursors-light 24")
-- The dock is a systemd user service (programs.waverunner); only the dev box
-- starts its live checkout from here (machine.dock).
if M.dock then
    hl.exec_cmd(M.dock)
end
-- The wallpaper is a placeholder until it is designed (Max, 2026-09-30: "for
-- now keep it quiet"). awww-daemon aborts (a Rust panic) the instant the
-- compositor goes away, so every session that ended by itself left a core
-- dump and an error in the journal. Core limit 1 is the kernel's "do not dump"
-- value for a piped handler: no core, no coredumpctl entry, no error line
-- (limit 0 still records the crash; measured).
-- It starts EMPTY (`--no-cache`: not with the last picture it showed, which
-- came up at every start before the owner's own — Max, 2026-10-13: "cuando
-- recargás aparece el fondo viejo"). Until the dock puts the chosen
-- wallpaper up (controls.rs `reassert`), and whenever none can be shown,
-- the screen is the compositor's bare grey (misc.background_color, golem/misc.lua).
-- waypaper is gone: the wallpaper is chosen in the dock's own box.
hl.exec_cmd("prlimit --core=1 awww-daemon --no-cache")
-- Bluetooth only where there is an adapter: the census turns the stack off
-- on a machine without one (desktop/bluetooth.nix), and these would be two
-- commands with no program (ASUS X550LC parity, 2026-10-02).
if M.bluetooth then
hl.exec_cmd("bluetoothctl power on")
hl.exec_cmd("sleep 2 && bluetoothctl devices Trusted | awk '{print $2}' | xargs -I {} bluetoothctl connect {}")
end
end)
