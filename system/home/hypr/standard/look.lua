local windowCorner = require("standard.lib").windowCorner

---- LOOK AND FEEL ----

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = {
         top = 3,
         right = 10,
         bottom = 10,
         left = 10,
        },
        border_size = 3,
        col = {
            active_border   = { colors = { "rgba(ffbe98ff)"},  },
            inactive_border = "rgba(3c3836aa)",
        },
        resize_on_border      = true,
        extend_border_grab_area = 10,
        hover_icon_on_border  = true,
        -- Magnets: a dragged floating window's edges pull to the other
        -- windows' edges and to the screen's. 18 px, stronger than
        -- stock's 10 (Max, 2026-10-14: "more sticky", "stronger" twice, then at 68, 48, 32 and 24 "make it weaker").
        -- Flush, no gaps: floats are placed by hand. At the top the magnet
        -- is the bar's bottom edge (hyprland-snap-reserved-edge.patch).
        snap = {
            enabled     = true,
            window_gap  = 18,
            monitor_gap = 18,
        },
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        -- THE WINDOWS' CORNER, chosen by eye on the live screen (Max,
        -- 2026-10-12): 14 at power 3. It was 12 at power 12 — long straight
        -- shoulders and a tight bend, "como si no fueran del todo redondas";
        -- a circle (power 2) at 12 read as "too square"; power 4 showed "una
        -- ligera punta" on the diagonal. The card's frame is drawn with the
        -- SAME curve (launcher content::WINDOW_CORNER + rounded_rect.wgsl's
        -- WINDOW_POWER): change the three together. `windowCorner` is also
        -- what the rules (standard/rules.lua) hand back to the windows they frame.
        rounding       = windowCorner,
        rounding_power = 3,
        -- Opaque focused windows: 0.95 forced the compositor to alpha-blend
        -- every window each frame (and blocks fullscreen direct-scanout of
        -- video). 1.0 removes that per-frame blend — the biggest free win for
        -- weak GPUs; the frosted glass lives on the shell surfaces, not the
        -- window fill (2026-09-02 perf pass).
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive = true,
        -- (The dock sets it by the apps' look — 15% Light, 25% Dark — through
        -- settings.lua and live: 0.3 took almost every word under 4.5:1, the
        -- legibility audit, 2026-10-23. This is the Dark one, before the dock.)
        dim_strength = 0.25,
        -- How dark the screen goes behind a window carrying `dim_around`. Only
        -- Standard's STAGE uses that rule, so this number is the stage's backdrop
        -- and nothing else's.
        dim_around   = 0.8,

	shadow = {
            enabled      = true,
            range        = 14,
            render_power = 3,
            color        = 0x661a1a1a,
        },

        blur = {
            enabled   = true,
            -- size 1 with FOUR passes is the frosted glass. The passes are what
            -- grow the radius here (each halves the resolution it samples), so
            -- at size 1 dropping 4 → 2 does not "keep the frosted look while
            -- halving the cost" — it deletes the blur. The shell then reads as
            -- plain see-through: on the 2013 Air the whole btop behind the menu
            -- stayed sharply legible through the panel (Max caught it on the
            -- first boot of the new ISO, 2026-09-02).
            --
            -- MEASURED live on that machine (the weakest target we have — HD
            -- 5000, menu open, blur actually running) before restoring it:
            --   size 1 / passes 2 — no blur      — Hyprland 2 % of a core
            --   size 1 / passes 4 — frosted      — Hyprland 3 % of a core
            --   size 4 / passes 3 — frosted      — Hyprland 3 % of a core
            --   size 8 / passes 2 — frosted      — Hyprland 8 % of a core
            -- One point of one core is what the look actually costs. The
            -- earlier pass traded it away on reasoning, having written that it
            -- "NEEDS a live Standard boot to confirm feel" — this is that boot.
            size      = 1,
            passes    = 4,
            vibrancy  = 0.0,
        },
    },

    animations = {
        enabled = true,
    },
})

-- NOTHING IS BLURRED BEHIND A WINDOW (Max, 2026-11-15: "i wont worry about the
-- blur on the windows we can use transparency on them, with high opacity").
-- The frosted glass is the shell's (the layer rules, standard/layers.lua). A window that
-- is see-through shows what is behind it as it is. Blurring behind every
-- floating window is redone on each frame something under it moves, and on a
-- fast panel the compositor then misses every other refresh. Measured on the
-- dev box (3200x2000 at 165 Hz, integrated graphics, performance mode, gears
-- under a see-through terminal): 138 to 161 frames a second with it, 161 to
-- 162 without.
hl.window_rule({ name = "golem-no-window-blur", match = { class = ".*" }, no_blur = true })
