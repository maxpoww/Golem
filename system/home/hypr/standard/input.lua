local keyboard = require("standard.lib").machine.keyboard

---- INPUT ----
hl.config({
    input = {
        -- The installer's keyboard answer (standard.keyboard, machine.keyboard).
        -- Hyprland does not read services.xserver.xkb: this block decides what
        -- the owner types into. A Russian gets "ru,us" with a toggle here.
        kb_layout  = keyboard.layout,
        kb_variant = keyboard.variant,
        kb_model   = keyboard.model,
        kb_options = keyboard.options,
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
