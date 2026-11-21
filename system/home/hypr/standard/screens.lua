local mainMod = require("standard.lib").mainMod

---- SCREENS: EACH ITS OWN WORKSPACES ----
-- Every screen has its own 18 workspaces (the overview's 3x3, two pages), as a
-- block of ids: block k is workspaces 100k+1 .. 100k+18. The laptop's own
-- panel keeps 1..18; each other screen takes the next free block the first
-- time it is plugged in, and keeps it: the blocks are remembered by the
-- screen's description in ~/.local/state/golem/screens ("<block><TAB><screen>"
-- per line), so a TV plugged back in finds its own workspaces again (Max,
-- 2026-11-07: "deberiamos definir los WSs para cada pantalla").
-- A block's workspaces are bound to its screen by workspace rules (its first
-- one is the screen's default), so a workspace opens on its own screen
-- whatever screen asked for it. While a screen is gone, Hyprland shows its
-- workspaces on another one; they keep their ids, so they stay a block apart
-- and go back when it returns. The swipe walks one screen's block only
-- (gestures:workspace_swipe_bound, hyprland-workspace-swipe-screen.patch),
-- and the overview and the dock read a screen's block from its default
-- workspace rule.
local SCREEN_STRIDE = 100
local SCREEN_SPAN   = 18
local screensPath   = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/golem/screens"
local screenBlocks  = {} -- monitor selector ("desc:…", or the output name) → block

-- The selector a rule names the screen by: its description (make, model,
-- serial: the same TV on another port is the same screen), or its output
-- name when it has none (a virtual screen).
local function screenKey(m)
    if m.description and m.description ~= "" then
        return "desc:" .. m.description
    end
    return m.name
end

local function isPanel(m)
    return m.name:match("^eDP") or m.name:match("^LVDS") or m.name:match("^DSI")
end

local function bindScreen(key, b)
    for i = 1, SCREEN_SPAN do
        hl.workspace_rule({ workspace = tostring(SCREEN_STRIDE * b + i), monitor = key, default = (i == 1) })
    end
end

do
    local file = io.open(screensPath, "r")
    if file then
        for line in file:lines() do
            local b, key = line:match("^(%d+)\t(.+)$")
            if b then
                screenBlocks[key] = tonumber(b)
            end
        end
        file:close()
    end
    for key, b in pairs(screenBlocks) do
        bindScreen(key, b)
    end
end

local function saveScreens()
    os.execute("mkdir -p '" .. screensPath:gsub("/[^/]*$", "") .. "'")
    local tmp = screensPath .. ".tmp"
    local file = io.open(tmp, "w")
    if not file then
        return
    end
    for key, b in pairs(screenBlocks) do
        file:write(b, "\t", key, "\n")
    end
    file:close()
    os.rename(tmp, screensPath)
end

-- The block of screen `m`, given one the first time it is seen: the lowest
-- free one, except that block 0 waits for the laptop's own panel while that
-- panel is connected and still without one.
local function screenBlock(m)
    -- Hyprland's stand-in while no screen is there is no screen: no block
    if m.name == "FALLBACK" then
        return 0
    end
    local key = screenKey(m)
    if screenBlocks[key] then
        return screenBlocks[key]
    end
    local used = {}
    for _, b in pairs(screenBlocks) do
        used[b] = true
    end
    if not isPanel(m) then
        for _, other in ipairs(hl.get_monitors() or {}) do
            if isPanel(other) and not screenBlocks[screenKey(other)] then
                used[0] = true
            end
        end
    end
    local b = 0
    while used[b] do
        b = b + 1
    end
    screenBlocks[key] = b
    saveScreens()
    bindScreen(key, b)
    return b
end

local function inBlock(id, b)
    return id and id > SCREEN_STRIDE * b and id <= SCREEN_STRIDE * b + SCREEN_SPAN
end

-- A screen seen for the first time came up on whatever workspace was free
-- (its rules did not exist yet): it shows the first of its own instead, and
-- the keyboard stays on the screen it was on.
local function settleScreen(m)
    if m.name == "FALLBACK" then
        return
    end
    local b = screenBlock(m)
    local ws = m.active_workspace
    if ws and not inBlock(ws.id, b) then
        local here = hl.get_active_monitor()
        hl.dispatch(hl.dsp.focus({ workspace = SCREEN_STRIDE * b + 1 }))
        if here and here.name ~= m.name then
            hl.dispatch(hl.dsp.focus({ monitor = here.name }))
        end
    end
end

-- Panel first, so it takes block 0 on a first start with a TV attached.
do
    local now = hl.get_monitors() or {}
    table.sort(now, function(a, c) return (isPanel(a) and 0 or 1) < (isPanel(c) and 0 or 1) end)
    for _, m in ipairs(now) do
        screenBlock(m)
    end
end
hl.on("monitor.added", settleScreen)

-- SHARED DESKS (Max, 2026-11-12): a screen can show any desk, its own or
-- another screen's (the overview brings a desk to the screen you pick it
-- from; waveview >= 2.31). "Here" is then the PAGE of the desk on show: the
-- block that desk belongs to, whatever screen you are on.
-- Super+[0-9] BRINGS desk 1..10 of that page to the screen you are on (a desk
-- another screen was showing sends that screen one desk further), Super+Shift
-- sends the window there.
local function hereBase()
    local m = hl.get_active_monitor()
    if not m then
        return 0
    end
    local ws = m.active_workspace
    if ws and ws.id and ws.id >= 1 then
        return math.floor((ws.id - 1) / SCREEN_STRIDE) * SCREEN_STRIDE
    end
    return SCREEN_STRIDE * screenBlock(m)
end
local function bringDesk(id)
    -- (the plugin not loaded: the plain switch, which goes to the desk where it is)
    if hl.plugin and hl.plugin.waveview and hl.plugin.waveview.bring then
        hl.plugin.waveview.bring(id)
    else
        hl.dispatch(hl.dsp.focus({ workspace = id }))
    end
end
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         function() bringDesk(hereBase() + i) end)
    hl.bind(mainMod .. " + SHIFT + " .. key, function() hl.dispatch(hl.dsp.window.move({ workspace = hereBase() + i })) end)
end

-- Example special workspace (scratchpad)
--hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
--hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
