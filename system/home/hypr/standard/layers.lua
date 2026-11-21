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
-- The desktop (icons behind the windows): its right-click menu and the
-- name field wear the boxes' frosted glass the same way; icons, names, the
-- selection wash and the rubber band all sit under 0.5 or are opaque, so
-- nothing else is blurred.
hl.layer_rule({ match = { namespace = "waverunner-desktop" }, blur = true })
hl.layer_rule({ match = { namespace = "waverunner-desktop" }, ignore_alpha = 0.5 })
-- Its menus are drawn on a surface of their own ABOVE the windows (so a
-- folder peeking from behind a window still gets its menu in sight): the
-- same glass there.
hl.layer_rule({ match = { namespace = "waverunner-desktop-menu" }, blur = true })
hl.layer_rule({ match = { namespace = "waverunner-desktop-menu" }, ignore_alpha = 0.5 })
