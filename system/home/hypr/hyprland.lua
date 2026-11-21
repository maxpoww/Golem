-- Standard's Hyprland configuration: the entry.
--
-- Nothing is configured here: each line loads one module, one concern a file
-- (standard/<name>.lua beside this file; the map is system/home/hypr/README.md).
-- THE ORDER IS THE CONTRACT: rules of the same weight are settled by the last
-- one declared, so the windows' rules come after the look they adjust, the
-- machine's own after Standard's, the owner's after the machine's, and what was
-- chosen in the control panel last of all.
--
-- Standard's modules are the same text on every machine. What differs is in
-- standard/machine.lua (generated: system/home/hyprland.nix), read by standard/lib.lua.
--
-- On a machine this file, its modules and the facts are ONE folder in the
-- store, and ~/.config/hypr/hyprland.lua is a generated file of three lines
-- that puts that folder first in package.path and runs this file.

require("standard.monitors")       -- every screen at its own size and scale
require("standard.layers")         -- the shell's surfaces: frosted glass
require("standard.autostart")      -- what starts with the session
require("standard.environment")    -- what every program started from here is told
require("standard.compat")         -- XWayland, popups, dialogs
require("standard.gestures")       -- the touchpad's swipes
require("standard.look")           -- gaps, borders, corners, shadows, blur
require("standard.animations")     -- the curves and what moves on them
require("standard.layout")         -- how tiles split
require("standard.misc")           -- scanout, VRR, the cursor, the log
require("standard.input")          -- keyboard, pointer, touchpad
require("standard.binds.apps")     -- keys: open a program
require("standard.binds.shell")    -- keys: the dock, the card, the overview, STAGE
require("standard.binds.windows")  -- keys: the window in hand
require("standard.screens")        -- each screen its own desks, and the keys to them
require("standard.binds.keys")     -- keys: power, volume, brightness, player, Print
require("standard.rules")          -- the windows' look by state
require("standard.effects")        -- a weak GPU: no blur
require("standard.lab")            -- a lab machine: the whole log

-- THE APP MODULES' OWN LUA (standard/modules/<name>.lua): the rules and keys a
-- module of programs brings with it, for the modules this machine has on
-- (machine.modules). A name with no file is not an error.
for _, name in ipairs(require("standard.lib").machine.modules) do
    pcall(require, "standard.modules." .. name)
end

-- THIS MACHINE'S OWN LUA (standard.home.hyprlandExtra in its configuration),
-- after everything Standard declares: standard/extra.lua, there only when set.
pcall(require, "standard.extra")

-- THE OWNER'S OWN FILE: ~/.config/hypr/user.lua, written by hand, optional
-- (found beside the generated entry: that folder stays in package.path).
-- After Standard's and the machine's, so it wins over both; saving it reloads
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
