-- GAMING: what the Gaming module's programs need from the compositor.
-- Loaded only on a machine that has the module on (machine.modules holds
-- "gaming": golem.modules.active), after everything Golem declares.

-- A game that fills the screen keeps the computer awake. To the compositor a
-- controller is neither a keyboard nor a pointer: its sticks and buttons do
-- not reset the idle clock, so a game played with one would have the screen
-- dim, lock and the machine sleep in the middle of it. Only while the game
-- is fullscreen: one left in a window, or behind another program, lets the
-- machine rest as usual. Steam gives every game's window the class
-- steam_app_<its number>; gamescope is the window games run inside.
hl.window_rule({
    name = "golem-gaming-awake",
    match = { class = "^(steam_app_.*|gamescope)$" },
    idle_inhibit = "fullscreen",
})
