

---- MONITORS ----
-- Distro default FIRST: every panel auto-configures to its preferred mode and
-- a DPI-appropriate scale. Do NOT hardcode a specific panel as the default. A
-- fixed 3200x2000@165 / scale 1.60 (the dev's Slim Pro) shipped in the ISO
-- and, on a 1366x768 Acer, the mode didn't exist so Hyprland fell to scale
-- 2.0 — a cramped desktop on first boot (2026-09-02). Verified live on that
-- panel: this catch-all gives preferred mode at scale 1.0.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
-- Personal override, matched by DESCRIPTION so it applies only to Max's
-- Slim Pro 9i panel and never to a stranger's machine. Comes after the
-- catch-all so it wins on that one output. This is the ONLY place a specific
-- panel belongs — a per-device tuning, not the shipped default.
hl.monitor({ output = "desc:Lenovo Group Limited 0x8BA2", mode = "3200x2000@165", position = "0x0", scale = 1.60 })


---- MY PROGRAMS ----
local terminal    = "foot"
local fileManager = "foot yazi"
local Suspend     = "systemctl suspend"

---- WAVERUNNER LAYER RULES ----
hl.layer_rule({ match = { namespace = "waverunner" }, blur = true })
hl.layer_rule({ match = { namespace = "waverunner" }, ignore_alpha = 0.5 })
-- The OPTIONS topbar surface: its open boxes (clipboard, notifications) draw
-- slightly translucent so this blur reads through them as frosted glass. Only
-- the compositor can blur what is BEHIND a layer surface — the daemon's own
-- scene texture holds nothing but the bar's pixels. ignore_alpha keeps the
-- resting bar exempt: its strip and pill washes sit well under 0.5, so
-- nothing is blurred until a box actually opens.
hl.layer_rule({ match = { namespace = "waverunner-options" }, blur = true })
hl.layer_rule({ match = { namespace = "waverunner-options" }, ignore_alpha = 0.5 })

---- AUTOSTART ----
hl.on("hyprland.start", function()
hl.exec_cmd("hyprctl plugin load /home/max/waveview/result/lib/libwaveview.so")
hl.exec_cmd("hyprctl setcursor phinger-cursors-light 24")
hl.exec_cmd("/home/max/launcher/waverunner-dev")
hl.exec_cmd("awww-daemon")
hl.exec_cmd("waypaper --restore")
hl.exec_cmd("bluetoothctl power on")
hl.exec_cmd("blueman-applet")
hl.exec_cmd("sleep 2 && bluetoothctl devices Trusted | awk '{print $2}' | xargs -I {} bluetoothctl connect {}")
end)


---- ENVIRONMENT VARIABLES ----
hl.env("SHELL",          "/run/current-system/sw/bin/zsh")
-- What apps launched from here should use (a .desktop entry with
-- Terminal=true needs $TERMINAL; without it xdg-open had nothing to run).
hl.env("TERMINAL",       "foot")
hl.env("EDITOR",         "nvim")
hl.env("VISUAL",         "nvim")
hl.env("XCURSOR_THEME",  "phinger-cursors-light")
hl.env("XCURSOR_SIZE",   "24")
hl.env("HYPRCURSOR_THEME", "phinger-cursors-light")
hl.env("HYPRCURSOR_SIZE",  "24")

ecosystem = {
 no_update_news = "true"
},

---- ENVIRONMENT VARIABLES ----
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

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




---- LOOK AND FEEL ----


hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

hl.config({
    gestures = {
        -- "One empty stop": from an occupied workspace the swipe steps to the
        -- raw neighbour (a single empty workspace is reachable); from an empty
        -- workspace it jumps to the next occupied one. Provided by the
        -- hyprland-workspace-swipe-one-empty.patch overlay; overrides use_r.
        workspace_swipe_one_empty = true,
    },
})

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
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 12,
        rounding_power = 12,
        -- Opaque focused windows: 0.95 forced the compositor to alpha-blend
        -- every window each frame (and blocks fullscreen direct-scanout of
        -- video). 1.0 removes that per-frame blend — the biggest free win for
        -- weak GPUs; the frosted glass lives on the shell surfaces, not the
        -- window fill (2026-09-02 perf pass).
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive = true,
        dim_strength = 0.3,
        -- How dark the screen goes behind a window carrying `dim_around`. Only
        -- Golem's STAGE uses that rule, so this number is the stage's backdrop
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
            -- "NEEDS a live Golem boot to confirm feel" — this is that boot.
            size      = 1,
            passes    = 4,
            vibrancy  = 0.0,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- 0.85⁴·0.9 the time of 71.2633/15.8273644 (same shape); waveview's SPRING_K/SPRING_C match — keep them equal
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 322.8714, dampening = 33.6891 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 1%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 1%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.18, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 0.73, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.18, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

hl.config({
    dwindle = {
        preserve_split = true,
        force_split = 2,
        precise_mouse_move = true, -- drops split by cursor quadrant (overview preview matches)
    },
})

hl.config({
    master = {
        new_status = "dwindle",
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})



----  MISC  ----
hl.config({
    -- Direct scanout: let a fullscreen client's buffer go straight to the
    -- display, skipping the composite pass. Verified live on the 2013 Air
    -- (2026-09-02): flipping this cleared the "user settings" blocker in
    -- hyprctl. Scanout still waits on the topbar layer no longer sitting
    -- over fullscreen (overFullscreen:1 → "missing candidate") — that's the
    -- wgpu layer-unmap follow-up in GRIND.md. Harmless on all hardware:
    -- it only ever activates when a candidate qualifies.
    render = {
        direct_scanout = true,
    },

    misc = {
        vrr = 1,
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
    },
})
hl.config({
  debug = {
    vfr = true,
  }
})

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})

hl.config({
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})


---- INPUT ----
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 2,

        -- Click to focus, floating windows included. At the default (1) focus
        -- jumps to whatever is under the cursor the moment it crosses between a
        -- tiled and a floating window — so a floating window steals focus just
        -- by being passed over, while tiled ones politely wait to be clicked.
        -- Two different rules for the same act is one rule too many.
        float_switch_override_focus = 0,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },
})



---- KEYBINDINGS ----
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session")) -- the lock screen (hypridle/hyprlock, home/idle.nix)
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd(Suspend))
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(fileManager))
--hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("/home/max/launcher/target/debug/waverunner-ctl toggle"))
-- Usage-aware focus cycle — the same frecency brain as the current-task
-- pill's clicks (waverunner ranks by decayed focus frequency).
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("/home/max/launcher/target/debug/waverunner-ctl focus-next"))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.exec_cmd("/home/max/launcher/target/debug/waverunner-ctl focus-other"))
hl.bind(mainMod .. " + R", function() hl.plugin.waveview.toggle() end) -- waveview 3x3 overview (digits 1-9 jump, Esc closes)

-- The Mac's own keys for the same two places (every MacBook with the classic
-- F-row, 2011–2020: hid_apple maps them for all of them). No other keyboard
-- sends these keysyms, so the binds cost nothing elsewhere.
--   F3, Mission Control (KEY_SCALE → XF86LaunchA): spread, overview, close:
--   one step per press (waveview's cycle()).
--   F4, Launchpad (KEY_DASHBOARD → XF86LaunchB): opens the apps box, as
--   Super+Space. The open box holds the keyboard, so the second press is
--   caught by the box itself, which closes (waverunner handle_key_event).
hl.bind("XF86LaunchA", function() hl.plugin.waveview.cycle() end)
hl.bind("XF86LaunchB", hl.dsp.exec_cmd("/home/max/launcher/target/debug/waverunner-ctl toggle"))
hl.bind(mainMod .. " + Z",     hl.dsp.window.float({ action = "toggle" }))
-- Pseudo through the Golem policy (tag + proportional size + frame rule),
-- the same daemon path as the topbar pill — never the raw toggle.
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("/home/max/launcher/target/debug/waverunner-ctl pseudo-toggle"))
-- STAGE mode: one task alone on screen at the stage rect, the deck of every
-- other task in the gap beneath it. Toggling off puts the desktop back exactly
-- as it was, focus included. The daemon owns all of it (see stage.rs).
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("/home/max/launcher/target/debug/waverunner-ctl stage-toggle"))
hl.bind(mainMod .. " + J", hl.dsp.layout("movetoroot"))

-- STAGE mode's keymap. While the stage owns the screen nothing should launch,
-- close, tile or move anything — so the daemon switches to this submap, in
-- which the ONLY binds are the way out. Everything else simply isn't bound, and
-- ordinary typing still reaches the staged window (a submap changes binds, not
-- input). The control keys stay live through `submap_universal = true`.
--
-- Super+Shift+Escape is a compositor-only escape hatch: `submap reset` needs no
-- daemon, so a waverunner that dies mid-stage cannot strand the keyboard. (An
-- empty submap can't be registered at all — Hyprland refuses it — so a submap
-- always carries at least its own exit.)
hl.define_submap("stage", function()
    hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("/home/max/launcher/target/debug/waverunner-ctl stage-toggle"))
    hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.submap("reset"))
    -- The overview is reachable from the stage (it is how you find the task you
    -- want on it, and whatever you land on is handed straight to the stage), so
    -- its key has to be here too: a submap hides the ordinary keymap, so the
    -- Super+R bound further down would not fire.
    hl.bind(mainMod .. " + R", function() hl.plugin.waveview.toggle() end)
    hl.bind("XF86LaunchA", function() hl.plugin.waveview.toggle() end) -- the Mac's Mission Control key, as Super+R here
    -- Super+[1-9] keeps meaning "go there", it is just the deck it aims at now:
    -- the N-th tile while the stage shows one task, workspace N while it shows
    -- a whole desk (the number the tile is labelled with). A number with no tile
    -- does nothing. The daemon decides which — see `deck.rs::stage_pick`.
    --
    -- These live HERE rather than being bound by the daemon at runtime: a submap
    -- can only be *defined*, and defining one that exists APPENDS to it, so a
    -- second definition would leave two Super+Return binds and one press would
    -- toggle the stage twice (measured 2026-09-12).
    for i = 1, 9 do
        hl.bind(mainMod .. " + " .. i,
            hl.dsp.exec_cmd("/home/max/launcher/target/debug/waverunner-ctl stage-pick " .. i))
    end
end)

-- Move focus with mainMod + WASD
hl.bind(mainMod .. " + A", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + D", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + W", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + S", hl.dsp.focus({ direction = "down" }))

-- Move windows with mainMod + SHIFT + WASD
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ direction = "down" }))

-- Resize the focused window with mainMod + arrows (hold to repeat)
hl.bind(mainMod .. " + Left",  hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + Right", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + Up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + Down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
--hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
--hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Move windows with mainMod + LMB drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })

-- The control keys below all carry `submap_universal = true`: they keep working
-- inside any submap, which is what keeps volume/brightness/media alive while
-- Golem's STAGE mode has taken every other bind away (see the "stage" submap).
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("systemctl hibernate"), { submap_universal = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, submap_universal = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, submap_universal = true })
-- No `repeating` on these two: they are TOGGLES, not steps. Key repeat would
-- flip mute on and off at repeat rate while the key is held, so the state you
-- land on is whatever the last repeat happened to set. One press, one flip.
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, submap_universal = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, submap_universal = true })
-- golem-brightness picks the backlight driving the CONNECTED panel (adapts to the
-- hybrid-GPU mux) — no hardcoded intel_backlight/nvidia_0. See system/golem-brightness.nix.
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("golem-brightness set 5%+"),                       { locked = true, repeating = true, submap_universal = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("golem-brightness set 5%-"),                       { locked = true, repeating = true, submap_universal = true })

-- Keyboard backlight (MacBook, ThinkPad, most laptops with a lit keyboard). The
-- device is matched by its kernel role, not a name: smc::kbd_backlight on a
-- Mac, tpacpi::kbd_backlight on a ThinkPad, and the same glob covers the rest.
-- Writable by the `input` group through brightnessctl's udev rule
-- (golem-brightness.nix). Before this, the keys did nothing and the light
-- stayed off (macbook, 2026-09-29).
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -d '*::kbd_backlight' set 10%+"), { locked = true, repeating = true, submap_universal = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d '*::kbd_backlight' set 10%-"), { locked = true, repeating = true, submap_universal = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, submap_universal = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, submap_universal = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })



---- WINDOWS AND WORKSPACES ----

---- Rounding for floating windows ----
hl.window_rule({
    name  = "floating-rounding",
    match = { float = true },
    rounding = 12,
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
    rounding    = 12,
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
    rounding    = 12,
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

