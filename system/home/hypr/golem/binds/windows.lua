-- golem/binds/windows.lua: the keys that act on the window in hand: close,
-- float, pseudo, focus, move, resize, and the drag with Super held.
local G = require("golem.lib")
local mainMod, ctl = G.mainMod, G.ctl

local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- Alt+F4 is Super+Q: the reflex a hand brings from every other desktop.
hl.bind("ALT + F4", hl.dsp.window.close())
--hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Z",     hl.dsp.window.float({ action = "toggle" }))
-- Pseudo through the Golem policy (tag + proportional size + frame rule),
-- the same daemon path as the topbar pill — never the raw toggle.
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(ctl .. " pseudo-toggle"))

-- Move focus with mainMod + WASD
hl.bind(mainMod .. " + A", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + D", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + W", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + S", hl.dsp.focus({ direction = "down" }))

-- Move windows with mainMod + SHIFT + WASD
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.window.move({ direction = "up" }))
-- The PrtSc key of a Lenovo (Slim Pro 9, 2026-10-20) is Windows' Snipping
-- Tool chord: the keyboard itself types Super+Shift+S, all three inside a few
-- ms (only Fn+PrtSc sends a real Print). A hand never gets S in within 40 ms
-- of Super, so a burst that fast is the key: a screenshot, not a move.
-- This keyboard's key cannot be held (it lets go by itself), so it is the
-- tap alone: the dock's `capture shot` (see PrtSc in binds/keys.lua). A dock that does
-- not answer, or one from before the tool: a plain shot of the screen.
local screenshot = hl.dsp.exec_cmd("sh -c '" .. ctl .. " capture shot || golem-screenshot screen'")
hl.bind(mainMod .. " + SHIFT + S", function()
    if G.superBurst then
        hl.dispatch(screenshot)
    else
        hl.dispatch(hl.dsp.window.move({ direction = "down" }))
    end
end)

-- Resize the focused window with mainMod + arrows (hold to repeat)
hl.bind(mainMod .. " + Left",  hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + Right", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + Up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + Down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })

-- Move windows with mainMod + LMB drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
