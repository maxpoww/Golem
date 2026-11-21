-- standard/compat.lua: what apps need from the compositor to behave
-- (XWayland's scaling, popups and dialogs that would open hidden, unfocused
-- or tiled). The windows' LOOK by state is rules.lua.

---- XWAYLAND SCALING ----
hl.config({
    xwayland = {
        force_zero_scaling = false,
        use_nearest_neighbor = false,
    }
})

---- CATCH-ALL WINDOW RULES FOR POPUPS ----
hl.window_rule({
    name = "fix-popups-focus",
    match = { float = true, title = "^$" },
    stay_focused = true,
})

hl.window_rule({
    name = "prevent-xwayland-focus-steal",
    match = { float = true, xwayland = true },
    no_initial_focus = true,
})
---- CATCH-ALL APP COMPATIBILITY RULES ----

-- Fix invisible or un-focusable dropdown menus/popups across XWayland apps
hl.window_rule({
    name = "fix-xwayland-popups",
    match = { float = true, xwayland = true, title = "^$" },
    no_initial_focus = true,
})

-- Prevent modal dialogs (file pickers, alerts) from opening hidden behind parent windows
hl.window_rule({
    name = "float-file-pickers",
    match = { title = "^(Open File|Save As|Select a File|Choose Files|Browse.*)$" },
    float = true,
})

-- Prevent full-screen popups or splash screens from capturing full tile dimensions
hl.window_rule({
    name = "constrain-splash-screens",
    match = { title = "^(splash|Splash|Loading.*)$" },
    float = true,
})
