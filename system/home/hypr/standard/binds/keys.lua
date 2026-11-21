-- standard/binds/keys.lua: the keyboard's own keys: power, volume, brightness,
-- the keyboard's light, the player, Print Screen.
local ctl = require("standard.lib").ctl

-- The control keys below all carry `submap_universal = true`: they keep working
-- inside any submap, which is what keeps volume/brightness/media alive while
-- Standard's STAGE mode has taken every other bind away (see the "stage" submap).
-- The power key (Max, 2026-11-03): a SHORT press brings the banner's power
-- pills right of the gear (hibernate, and sleep and restart behind it on
-- hover); a LONG one is logind's and powers off (desktop/idle.nix). Sent when
-- the key is let go, so a long press never shows the pills on its way out.
-- Not while locked: the lock screen covers the banner.
hl.bind("XF86PowerOff", hl.dsp.exec_cmd(ctl .. " power"), { release = true, submap_universal = true })

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

-- PrtSc (Max, 2026-11-16): the screen is taken the moment the key goes
-- down and shown on the card's pill; a click there cuts it to a region or a
-- window, left alone it is kept whole. HELD a second and a half it records
-- the screen instead, and a tap stops a recording. The dock does all of it
-- (capture.rs) and has to know both ends of the press. A dock that does not
-- answer, or one from before this: a plain shot of the screen.
-- Shift: the whole screen, and Alt: the window, at once and with a
-- notification (golem-screenshot, system/home/screenshot.nix).
hl.bind("Print", hl.dsp.exec_cmd("sh -c '" .. ctl .. " capture press || golem-screenshot screen'"), { submap_universal = true })
hl.bind("Print", hl.dsp.exec_cmd(ctl .. " capture release"), { release = true, submap_universal = true })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("golem-screenshot screen"), { submap_universal = true })
hl.bind("ALT + Print", hl.dsp.exec_cmd("golem-screenshot window"), { submap_universal = true })
-- Ctrl + Print records the screen the keyboard is on (plan F3.3): the first
-- press starts, the next stops and keeps the film in Videos/Screencasts.
-- While it runs it is on the bar's task pill, whose Stop stops it too.
hl.bind("CTRL + Print", hl.dsp.exec_cmd(ctl .. " record"), { submap_universal = true })
