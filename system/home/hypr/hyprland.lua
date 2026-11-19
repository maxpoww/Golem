-- Golem's Hyprland configuration: the entry.
--
-- Nothing is configured here: each line loads one module, one concern a file
-- (golem/<name>.lua beside this file; the map is system/home/hypr/README.md).
-- THE ORDER IS THE CONTRACT: rules of the same weight are settled by the last
-- one declared, so the windows' rules come after the look they adjust, the
-- machine's own after Golem's, the owner's after the machine's, and what was
-- chosen in the control panel last of all.
--
-- Golem's modules are the same text on every machine. What differs is in
-- golem/machine.lua (generated: system/home/hyprland.nix), read by golem/lib.lua.

require("golem.monitors")       -- every screen at its own size and scale
require("golem.layers")         -- the shell's surfaces: frosted glass
require("golem.autostart")      -- what starts with the session
require("golem.environment")    -- what every program started from here is told
require("golem.compat")         -- XWayland, popups, dialogs
require("golem.gestures")       -- the touchpad's swipes
require("golem.look")           -- gaps, borders, corners, shadows, blur
require("golem.animations")     -- the curves and what moves on them
require("golem.layout")         -- how tiles split
require("golem.misc")           -- scanout, VRR, the cursor, the log
require("golem.input")          -- keyboard, pointer, touchpad
require("golem.binds.apps")     -- keys: open a program
require("golem.binds.shell")    -- keys: the dock, the card, the overview, STAGE
require("golem.binds.windows")  -- keys: the window in hand
require("golem.screens")        -- each screen its own desks, and the keys to them
require("golem.binds.keys")     -- keys: power, volume, brightness, player, Print
require("golem.rules")          -- the windows' look by state
require("golem.effects")        -- a weak GPU: no blur
require("golem.lab")            -- a lab machine: the whole log

-- THE APP MODULES' OWN LUA (golem/modules/<name>.lua): the rules and keys a
-- module of programs brings with it, for the modules this machine has on
-- (machine.modules). A name with no file is not an error.
for _, name in ipairs(require("golem.lib").machine.modules) do
    pcall(require, "golem.modules." .. name)
end

-- THIS MACHINE'S OWN LUA (golem.home.hyprlandExtra in its configuration),
-- after everything Golem declares: golem/extra.lua, there only when set.
pcall(require, "golem.extra")

-- THE OWNER'S OWN FILE: ~/.config/hypr/user.lua, written by hand, optional.
-- After Golem's and the machine's, so it wins over both; saving it reloads
-- the configuration. A mistake in it is shown as a configuration error and
-- stops nothing else.
pcall(require, "user")

---- LIVE SETTINGS (the control panel) ----
-- What the owner chose in the control panel (a screen's scale and
-- resolution so far). The dock sets a choice live and saves it to
-- ~/.config/golem/settings.json, with a copy as Lua beside it. That
-- copy runs here, last: a choice wins over every default above, is on
-- the screen from the compositor's first frame, and comes back on
-- every reload, whether or not the dock is running.
-- dofile, not require: a required file is watched, and each click in
-- the panel would reload this whole config. A missing or broken file
-- changes nothing.
do
    local dir = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
    local path = dir .. "/golem/settings.lua"
    local file = io.open(path, "r")
    if file then
        file:close()
        local ok, err = pcall(dofile, path)
        if not ok then
            print("golem: live settings not applied: " .. tostring(err))
        end
    end
end
