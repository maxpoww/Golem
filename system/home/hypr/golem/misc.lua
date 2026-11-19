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
        -- Adaptive sync (VRR) only for a fullscreen window (games, video).
        -- On the desktop the panel keeps its fixed rate: with VRR there, every
        -- change in how often frames come (a busy terminal, the pointer over a
        -- still screen, a redraw after rest) is a change in the panel's refresh,
        -- and many panels show each one as a brightness step: flicker in
        -- episodes, hell on some screens, never on others (Max's 165 Hz panel,
        -- 2026-09-10, 10-20, 11-15). The battery saving is debug:vfr below (no
        -- frame drawn while nothing changes), which stays on; it does not need
        -- VRR. KDE, GNOME and Windows choose the same.
        vrr = 2,
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        -- What is seen where no wallpaper is (none chosen, or it could not
        -- be shown): a quiet grey, the last-resort screen's too
        -- (desktop/crash-recovery.nix).
        background_color = 0xff3a3a3c,
        -- Any key or pointer motion wakes a display that is off, whatever
        -- turned it off: the safety net under hypridle's own screen-on (which
        -- once toggled the screen OFF on a wake-up, 2026-09-30).
        -- A drag does not focus (so does not raise) the windows it passes
        -- over: a file is carried across one window to drop on another that
        -- lies under it (Max, 2026-10-10, macOS's way). HOLDING it still over
        -- a window brings that one forward (hyprland-dnd-hold-raise.patch),
        -- and over an app's tile in the dock, that app (launcher).
        always_follow_on_dnd     = false,
        key_press_enables_dpms   = true,
        mouse_move_enables_dpms  = true,
        -- A locked session whose lock screen died accepts a new one (Super+L,
        -- or the next idle lock) instead of staying frozen until a relogin.
        allow_session_lock_restore = true,
    },
})
hl.config({
  debug = {
    vfr = true,
    -- The log with times: a start's 3.5 s on the 2013 MacBook Air is
    -- silent without them (2026-10-29). The log lives in /run, tmpfs.
    disable_time = false,
  }
})

-- Hyprland's own rule ("auto"), as Omarchy leaves it: the display engine's cursor
-- plane, except where NVIDIA draws the screen and it is known to misbehave. This was
-- `true` from the first day with no reason written down, and every move of the
-- pointer then redrew the screen. Moving it on an empty workspace (dev box, 165 Hz):
-- the GPU 24 % busy -> 1 %, the compositor 6.7 % of a CPU -> 1.8 %. The panel still
-- follows each move: 130 refreshes a second at 125 moves a second, VRR on.
hl.config({
    cursor = {
        no_hardware_cursors = 2,
    },
})

hl.config({
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})
