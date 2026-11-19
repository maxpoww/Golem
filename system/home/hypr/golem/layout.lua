---- LAYOUT ----
hl.config({
    dwindle = {
        preserve_split = true,
        -- A NEW TILE OPENS BESIDE THE WINDOW UNDER THE POINTER, on the side
        -- the pointer is on, and nothing is focused for it (Max, 2026-11-17:
        -- "que se abra al lado de la ventana que está abajo del mouse, como
        -- cuando el mouse enfoca, pero sin enfocar la ventana"; "que siga al
        -- mouse"). It was the window the keyboard is in, always to its right
        -- or below. The keyboard stays where it was: follow_mouse = 2 (golem/input.lua).
        -- Read from DwindleAlgorithm::addTarget (0.55.4) and rig-tested: the
        -- gaps count as the window beside them (the border grab area,
        -- resize_on_border + extend_border_grab_area), the bar splits the
        -- closest tile, and a window that opens on a desk the focused screen
        -- is not showing splits that desk's first tile.
        use_active_for_splits = false,
        -- 0: the new tile takes the half of that window the pointer is in
        -- (left or right, top or bottom, by the window's shape).
        force_split = 0,
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
