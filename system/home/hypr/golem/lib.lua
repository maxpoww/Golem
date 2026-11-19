-- golem/lib.lua: what the modules share.
--
-- 1. THIS MACHINE'S FACTS (`machine`): golem/machine.lua, a table the home
--    layer generates for the machine it is built for (system/home/home.nix):
--    where the dock's command is, which keyboard the installer was told, the
--    panel's scale, whether there is Bluetooth. It is the ONE generated file;
--    every other module is the same text on every Golem machine and reads
--    what differs from here. A tree with no machine.lua (a copy run by hand,
--    a test rig) gets a plain install's answers: programs from PATH, no
--    plugin, no dock started from here.
-- 2. THE NAMES the binds use (the programs, the main modifier, the windows'
--    corner), so two files cannot disagree about them.
-- 3. THE STATE two files both touch (`superBurst`: set by the Super tap in
--    binds/shell.lua, read by Super+Shift+S in binds/windows.lua).
--
-- Returned as a table, never as globals: a module that needs something asks
-- for it (`local G = require("golem.lib")`).

local found, facts = pcall(require, "golem.machine")
if not found or type(facts) ~= "table" then
    facts = {}
end
local function given(value, otherwise)
    if value == nil then
        return otherwise
    end
    return value
end
local keyboard = given(facts.keyboard, {})

local machine = {
    -- the dev box: the dock and the plugin run from their live checkouts
    dev = given(facts.dev, false),
    -- the dock's command line tool, as every bind calls it
    ctl = given(facts.ctl, "waverunner-ctl"),
    -- the overview plugin to load at start (nil: none)
    plugin = facts.plugin,
    -- the dock's own start command (nil: it is a systemd user service)
    dock = facts.dock,
    -- the owner's login shell, for $SHELL
    shell = given(facts.shell, os.getenv("SHELL") or "/bin/sh"),
    -- the installer's keyboard answer (golem.keyboard)
    keyboard = {
        layout  = given(keyboard.layout, "us"),
        variant = given(keyboard.variant, ""),
        model   = given(keyboard.model, ""),
        options = given(keyboard.options, ""),
    },
    -- the laptop panel's density and the scale it gets for it (nil: the catch-all's)
    panel_dpi = given(facts.panel_dpi, 0),
    panel_scale = facts.panel_scale,
    -- a Bluetooth adapter is there
    bluetooth = given(facts.bluetooth, true),
    -- "full", or "light" on a weak GPU (golem.desktop.effects)
    effects = given(facts.effects, "full"),
    -- a lab testbed (Modular/lab/lab-door.nix)
    lab = given(facts.lab, false),
    -- the app modules whose own Lua is loaded (golem/modules/<name>.lua)
    modules = given(facts.modules, {}),
}

return {
    machine = machine,

    ---- MY PROGRAMS ----
    terminal    = "foot",
    fileManager = "foot yazi",
    Suspend     = "systemctl suspend",

    mainMod = "SUPER", -- Sets "Windows" key as main modifier

    -- the windows' corner radius (see decoration.rounding in look.lua); also
    -- what rules.lua hands back to the windows it frames
    windowCorner = 14,

    ctl = machine.ctl,

    -- True for 40 ms after Super goes down: tells a keyboard's own macro
    -- (a Lenovo's PrtSc types Super+Shift+S in one burst) from a hand.
    superBurst = false,
}
