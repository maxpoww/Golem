local M = require("golem.lib").machine

---- LIGHT EFFECTS (golem.desktop.effects = "light") ----
-- For a weak GPU (set by gpu/intel-legacy): Hyprland's blur off. On the 2013
-- MacBook Air it held the 3D engine at 98% during video; the rest of the look
-- (shadows, dimming, rounding) costs nothing measurable and stays. Loaded
-- after everything else Golem declares, so it wins over the decoration block.
if M.effects == "light" then
    hl.config({ decoration = { blur = { enabled = false } } })
end
