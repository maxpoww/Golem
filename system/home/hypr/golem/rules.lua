local windowCorner = require("golem.lib").windowCorner

---- WINDOWS AND WORKSPACES ----

---- Rounding for floating windows ----
hl.window_rule({
    name  = "floating-rounding",
    match = { float = true },
    rounding = windowCorner,
})

---- Golem browser: a subtle border, only on Firefox ----
-- Firefox floats BARE — no Golem titlebar, its own macOS traffic lights stand in
-- (see golemBar.cpp `windowIsFirefox`). A full 3px frame reads too loud around a
-- bare window, so thin it to a 1px hairline: present but quiet, macOS-like.
-- Placed BEFORE the stage rule so a staged Firefox still drops to border_size=0
-- (same priority, last-set-wins). NOTE: only border_size/rounding are per-window
-- here — a window rule can't set a per-window COLOUR — so the hairline keeps the
-- shell's dynamic border colour; muting that would need the waveview plugin.
hl.window_rule({
    name  = "browser-subtle-border",   -- Seam (Golem's browser) and a plain Firefox alike: both float bare with their own controls
    match = { class = "^(firefox|seam)$" },
    border_size = 1,
})

---- Raise floating windows on focus ----
hl.on("window.active", function(w, reason)
    if w and w.floating then
        hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = w }))
    end
end)

---- Smart gaps ----
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
hl.window_rule({
    name  = "no-gaps-wtv1",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
    opacity     = "1.0 override",
})
hl.window_rule({
    name  = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

---- Shadow only where a window reads as a card: floating + golem-pseudo ----
-- Tiled windows sit edge-to-edge in the layout, so a drop shadow there only
-- muddies the gaps. Must come BEFORE golem-pseudo-frame (same priority, last
-- set wins) so the tagged rule below can hand the shadow back.
hl.window_rule({
    name  = "no-shadow-tiled",
    match = { float = false },
    no_shadow = true,
})

---- Golem pseudo: a framed window at a proportional default size ----
-- waverunner tags the window "golem-pseudo", pseudotiles it, and sizes it
-- to a fixed fraction of its tile (see hypr.rs::toggle_golem_pseudo) — so
-- the inset reads the same on every screen (Max picked the frame-inset
-- look, 2026-08-31). This rule is the other half: it gives a tagged window
-- its rounding + border back. It must come AFTER the no-gaps rules — same
-- priority, last set wins — so a solo pseudo window keeps its frame while
-- smart gaps stay untouched for plain tiled windows.
--
-- The toggle lives in the DAEMON, not here, because the state is only
-- readable from that side: this Lua binding's `window.tags` reads as an
-- empty table even for a tagged window (verified 2026-08-31), and pseudo
-- state is exposed nowhere — so a config-side toggle can never tell "on"
-- from "off". Both the topbar pill and Super+P route through the daemon.
hl.window_rule({
    name  = "golem-pseudo-frame",
    match = { tag = "golem-pseudo" },
    border_size = 3,
    rounding    = windowCorner,
    no_shadow   = false,
})

---- Golem STAGE: the staged window keeps its corners ----
-- The staged task is tiled and maximized, so it matches the no-gaps rules above
-- and loses its rounding — but on the stage it is a card sitting in its own
-- inset, and it should read like one. Same trick as golem-pseudo-frame:
-- waverunner tags the window, and this rule (AFTER the no-gaps rules — same
-- priority, last set wins) hands the corners back. `rounding` and `border_size`
-- are dynamic props, so they re-apply the moment the tag flips.
--
-- No border, deliberately (Max, 2026-09-05): the stage is the only thing on the
-- screen, so nothing needs telling apart from anything else. The peach frame
-- lives on the deck's tile instead, where it does have a job — saying which of
-- the tiles is the one you are looking at.
-- `dim_around` darkens the whole screen behind the staged window, at
-- `decoration.dim_around` strength. It is what makes the stage read as the only
-- thing running: the wallpaper drops away and the task is left alone in the
-- dark. It costs nothing when the mode is off, because nothing else in the
-- config ever carries this tag — and dropping the tag on exit takes the dim with
-- it, so there is no state to restore.
hl.window_rule({
    name  = "golem-stage-frame",
    match = { tag = "golem-stage" },
    border_size = 0,
    rounding    = windowCorner,
    no_shadow   = false,
    dim_around  = true,
})

local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
