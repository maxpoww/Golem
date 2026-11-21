---- GESTURES ----
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

hl.config({
    gestures = {
        -- "One empty stop": from an occupied workspace the swipe steps to the
        -- raw neighbour (a single empty workspace is reachable); from an empty
        -- workspace it jumps to the next occupied one. Provided by the
        -- hyprland-workspace-swipe-one-empty.patch overlay; overrides use_r.
        workspace_swipe_one_empty = true,
        -- A swipe stays on the screen's own workspaces (standard/screens.lua):
        -- hyprland-workspace-swipe-screen.patch.
        workspace_swipe_bound = true,
    },
})
