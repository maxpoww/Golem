local M = require("standard.lib").machine

---- MONITORS ----
-- Distro default FIRST: every panel auto-configures to its preferred size at
-- its top refresh rate (Standard's preferred-top-rate patch: many fast screens
-- flag a 60 Hz mode as preferred) and a DPI-appropriate scale. Do NOT hardcode a specific panel as the default. A
-- fixed 3200x2000@165 / scale 1.60 (the dev's Slim Pro) shipped in the ISO
-- and, on a 1366x768 Acer, the mode didn't exist so Hyprland fell to scale
-- 2.0 — a cramped desktop on first boot (2026-09-02). Verified live on that
-- panel: this catch-all gives preferred mode at scale 1.0.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
-- HiDPI from the census (standard.hardware.panelDpi, EDID width against the
-- native mode, eDP only): the laptop's own panel gets a scale for its
-- density, right after the catch-all, so a 4K 13" laptop does not boot at
-- ant size while external screens stay at the catch-all's. The tiers are in
-- system/home/hyprland.nix (machine.panel_scale); nil on an ordinary panel.
if M.panel_scale then
    hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = M.panel_scale })
end
-- Personal override, matched by DESCRIPTION so it applies only to Max's
-- Slim Pro 9i panel and never to a stranger's machine. Comes after the
-- catch-all so it wins on that one output. This is the ONLY place a specific
-- panel belongs — a per-device tuning, not the shipped default.
hl.monitor({ output = "desc:Lenovo Group Limited 0x8BA2", mode = "3200x2000@165", position = "0x0", scale = 1.60 })
