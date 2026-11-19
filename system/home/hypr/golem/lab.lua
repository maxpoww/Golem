local M = require("golem.lib").machine

-- A lab machine keeps Hyprland's whole log (Modular/lab/lab-door.nix).
if M.lab then
    hl.config({ debug = { disable_logs = false } })
end
