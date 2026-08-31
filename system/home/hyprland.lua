

---- MONITORS ----
hl.monitor({
    output = "eDP-1",
    mode = "3200x2000@165",
    position = "0x0",
    scale = 1.60
})


---- MY PROGRAMS ----
local terminal    = "foot"
local fileManager = "foot yazi"
local Suspend     = "systemctl suspend"

---- WAVERUNNER LAYER RULES ----
hl.layer_rule({ match = { namespace = "waverunner" }, blur = true })
hl.layer_rule({ match = { namespace = "waverunner" }, ignore_alpha = 0.5 })

---- AUTOSTART ----
hl.on("hyprland.start", function()
hl.exec_cmd("hyprctl plugin load /home/max/waveview/result/lib/libwaveview.so")
hl.exec_cmd("hyprctl setcursor phinger-cursors-light 24")
hl.exec_cmd("/home/max/launcher/waverunner-dev")
hl.exec_cmd("awww-daemon")
hl.exec_cmd("waypaper --restore")
hl.exec_cmd("easyeffects --gapplication-service")
hl.exec_cmd("bluetoothctl power on")
hl.exec_cmd("blueman-applet")
hl.exec_cmd("sleep 2 && bluetoothctl devices Trusted | awk '{print $2}' | xargs -I {} bluetoothctl connect {}")
hl.exec_cmd("kdeconeectd")
end)


---- ENVIRONMENT VARIABLES ----
hl.env("SHELL",          "/run/current-system/sw/bin/zsh")
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
        active_opacity   = 0.95,
        inactive_opacity = 0.95,
        dim_inactive = true,
        dim_strength = 0.3,

	shadow = {
            enabled      = true,
            range        = 2,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
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

hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

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
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
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

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },
})



---- KEYBINDINGS ----
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(terminal))
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
hl.bind(mainMod .. " + Z",     hl.dsp.window.float({ action = "toggle" }))
-- Pseudo through the Golem policy (tag + proportional size + frame rule),
-- same as the topbar pill — never the raw toggle.
hl.bind(mainMod .. " + P", function()
    local d = golemPseudoToggle()
    if d then hl.dispatch(d) end
end)
hl.bind(mainMod .. " + J", hl.dsp.layout("movetoroot"))   

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

hl.bind("XF86PowerOff", hl.dsp.exec_cmd("systemctl hibernate"))

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })



---- WINDOWS AND WORKSPACES ----

---- Rounding for floating windows ----
hl.window_rule({
    name  = "floating-rounding",
    match = { float = true },
    rounding = 12,
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
    no_dim      = true,
})
hl.window_rule({
    name  = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

---- Golem pseudo: a framed window at a proportional default size ----
-- The pseudo pill (waverunner) calls golemPseudoToggle(): it tags the
-- window "golem-pseudo", toggles pseudotile, and sizes it to a fixed
-- fraction of its tile — so the inset reads the same on every screen
-- (Max picked the frame-inset look, 2026-08-31). The tag IS the state:
-- readable from w.tags, it survives daemon restarts and dies with the
-- window. This rule must come AFTER the no-gaps rules — same priority,
-- last set wins — so a solo pseudo window keeps its rounding + border
-- while smart gaps stay untouched for plain tiled windows.
hl.window_rule({
    name  = "golem-pseudo-frame",
    match = { tag = "golem-pseudo" },
    border_size = 3,
    rounding    = 12,
})

local PSEUDO_W, PSEUDO_H = 0.89, 0.84 -- fraction of the tile

local function hasGolemPseudoTag(w)
    local tags = w.tags
    if type(tags) == "table" then
        for _, t in pairs(tags) do
            if t == "golem-pseudo" then return true end
        end
        return false
    end
    return tags == "golem-pseudo"
end

function golemPseudoToggle()
    local w = hl.get_active_window()
    if not w then return nil end
    if hasGolemPseudoTag(w) then
        hl.dispatch(hl.dsp.window.tag({ tag = "-golem-pseudo", window = w }))
        return hl.dsp.window.pseudo({ action = "off", window = w })
    end
    -- Read the tile size BEFORE pseudo shrinks the window into it.
    local size = w.size
    local sw = type(size) == "table" and (size.x or size[1]) or nil
    local sh = type(size) == "table" and (size.y or size[2]) or nil
    hl.dispatch(hl.dsp.window.tag({ tag = "+golem-pseudo", window = w }))
    hl.dispatch(hl.dsp.window.pseudo({ action = "on", window = w }))
    if not sw or not sh then return nil end
    return hl.dsp.window.resize({
        x = math.floor(sw * PSEUDO_W),
        y = math.floor(sh * PSEUDO_H),
        window = w,
    })
end

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

