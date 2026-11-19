-- golem/binds/shell.lua: the keys of Golem's shell: the lock screen, the
-- dock box, voice to text, fast launch, the card, the control panel, the
-- walk round the windows and the screens, the overview, and STAGE mode with
-- its own keymap. Most of them only tell the dock (waverunner-ctl).
local G = require("golem.lib")
local mainMod, ctl = G.mainMod, G.ctl
local Suspend = G.Suspend

-- The lock screen, called directly (logind refuses to lock a greeter-class
-- session; home/idle.nix). `locked`: it also works on a locked session, so if
-- the lock screen ever dies (the session stays locked, frozen on its last
-- frame), Super+L brings a live one back (allow_session_lock_restore, golem/misc.lua).
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("golem-lock-screen"), { locked = true })
-- (While something dictated is being written out, Escape cancels it — the
-- dock binds the bare key for that long and raises `golem_dictating`. A hand
-- that has not let go of Super yet presses THIS key instead: it cancels too,
-- it does not put the computer to sleep. launcher card/dictate.rs.)
hl.bind(mainMod .. " + ESCAPE", function()
    if golem_dictating then
        hl.dispatch(hl.dsp.exec_cmd(ctl .. " card dictate cancel"))
    else
        hl.dispatch(hl.dsp.exec_cmd(Suspend))
    end
end)
-- A TAP of Super alone opens the dock box (Max, 2026-10-12: "can we open
-- the dock box by pressing only Super? like a short hit opens it?"; it "feels
-- good", so Super+Space, the key it had until then, is voice to text now). A release
-- bind of the key under its own modifier is already dropped by Hyprland when
-- another key, a click or a scroll came while Super was down; what it lacks is
-- a time limit, so Super held and let go (a change of mind, a hover with
-- Super+drag in sight) opened the box. The press starts a 300 ms window; only
-- a release inside it counts. Rig: ~/.cache/golem-nested/tap-test.sh.
-- The same press also opens a 40 ms window that tells a keyboard's own macro
-- from a hand (superBurst, read by Super+Shift+S in binds/windows.lua).
local tapFresh, tapGen = false, 0 -- (superBurst is G.superBurst)
for _, key in ipairs({ "Super_L", "Super_R" }) do
    hl.bind(key, function()
        tapGen = tapGen + 1
        local mine = tapGen
        tapFresh, G.superBurst = true, true
        hl.timer(function() if tapGen == mine then G.superBurst = false end end, { timeout = 40, type = "oneshot" })
        hl.timer(function() if tapGen == mine then tapFresh = false end end, { timeout = 300, type = "oneshot" })
    end, { non_consuming = true })
    hl.bind(mainMod .. " + " .. key, function()
        if tapFresh then
            tapFresh = false
            hl.dispatch(hl.dsp.exec_cmd(ctl .. " toggle"))
        end
    end, { release = true, description = "Dock box (tap)" })
end
-- VOICE TO TEXT on Super+Space (Max, 2026-10-12: a tap "opens the card on
-- voice to text"; held, it is dictation "without the card": the seconds on
-- the task pill, then the words pasted into the window). Which of the two it
-- was is told by the dock (launcher card/dictate.rs), from how long it took:
-- here only "down" and "up". The "up" is Space coming up WHATEVER the
-- modifiers then, since Super is often let go first and a release bind under
-- SUPER would never fire; it cannot be shadowed (transparent: with Super let
-- go first Hyprland shadows every bind on a key still down), it eats nothing
-- (a plain Space is typed as ever) and does nothing unless a "down" went out.
local talkDown = false
hl.bind(mainMod .. " + SPACE", function()
    talkDown = true
    hl.dispatch(hl.dsp.exec_cmd(ctl .. " card dictate down"))
end, { description = "Voice to text (tap: the card; hold: dictate)" })
hl.bind("SPACE", function()
    if talkDown then
        talkDown = false
        hl.dispatch(hl.dsp.exec_cmd(ctl .. " card dictate up"))
    end
end, { release = true, ignore_mods = true, non_consuming = true, transparent = true })
-- FAST LAUNCH: one bubble mid-screen, an apps-only search; a few letters
-- and Enter open a new instance (Super+J; it took the dwindle movetoroot key).
hl.bind(mainMod .. " + J", hl.dsp.exec_cmd(ctl .. " fast-launch"))
-- QUICK CONTROLS: the same bubble over the control panel's settings (Max,
-- 2026-10-13) — a few letters and Enter open that setting in a box
-- mid-screen (Super+H).
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd(ctl .. " fast-controls"))
-- THE CARD, straight to a page of it, on the focused window (Max,
-- 2026-10-12): Super+. its clipboard, Super+, its emoji, Super+/ its
-- memory. The same key again puts the card away.
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd(ctl .. " card at clipboard"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ctl .. " card at emoji"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(ctl .. " card at memory"))
-- The control panel (the dock's gear): Super+Ctrl, tapped. Fires on the
-- RELEASE of whichever of the two keys lets go first while the other is still
-- held — at that instant Hyprland 0.55 still counts the released key in the
-- mods, hence SUPER + CTRL on all four. Binding only Ctrl's release missed the
-- left-hand roll-off where Super lets go a hair before Ctrl (~2 in 10).
local controlPanel = hl.dsp.exec_cmd(ctl .. " control-panel")
for _, key in ipairs({ "Control_L", "Control_R", "Super_L", "Super_R" }) do
    hl.bind(mainMod .. " + CTRL + " .. key, controlPanel, { release = true, description = "Control panel" })
end
-- Usage-aware focus cycle — the same frecency brain as the current-task
-- pill's clicks (waverunner ranks by decayed focus frequency).
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd(ctl .. " focus-next"))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.exec_cmd(ctl .. " focus-other"))
-- The reflex a hand brings from every other desktop: Alt+Tab is Super+Tab
-- (the same walk, the same order). (Alt+F4 is in binds/windows.lua.)
hl.bind("ALT + TAB", hl.dsp.exec_cmd(ctl .. " focus-next"))
hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd(ctl .. " focus-other"))
-- The same walk one level up, round the SCREENS: the first press goes to the
-- screen last worked on; pressed again with nothing touched it goes on to the
-- next one and wraps home; touching the screen commits it.
hl.bind(mainMod .. " + grave", hl.dsp.exec_cmd(ctl .. " focus-screen"))
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
hl.bind("XF86LaunchB", hl.dsp.exec_cmd(ctl .. " toggle"))
-- STAGE mode: one task alone on screen at the stage rect, the deck of every
-- other task in the gap beneath it. Toggling off puts the desktop back exactly
-- as it was, focus included. The daemon owns all of it (see stage.rs).
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(ctl .. " stage-toggle"))

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
    hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(ctl .. " stage-toggle"))
    hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.submap("reset"))
    -- The overview is reachable from the stage (it is how you find the task you
    -- want on it, and whatever you land on is handed straight to the stage), so
    -- its key has to be here too: a submap hides the ordinary keymap, so the
    -- Super+R bound above would not fire.
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
            hl.dsp.exec_cmd(ctl .. " stage-pick " .. i))
    end
end)
