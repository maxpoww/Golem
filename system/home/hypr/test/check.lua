-- test/check.lua <root> <layers root> <gaming root>: what must hold of
-- Golem's Hyprland configuration, checked with the recording mock (mock.lua)
-- and no compositor. Run through check.sh, which makes the roots:
--   <root>         the tree with a machine's real generated facts;
--   <layers root>  the tree with the sample facts, an app module's file
--                  (golem/modules/demo.lua), a machine's own tail
--                  (golem/extra.lua) and an owner's file (user.lua), each
--                  setting general.gaps_in to a number of its own;
--   <gaming root>  the first root with the Gaming module on (facts.modules).
-- XDG_CONFIG_HOME/golem/settings.lua (the live settings) sets it to 7.

local here = arg[0]:match("^(.*)/[^/]*$") or "."
MOCK_LIBRARY = true
local run = dofile(here .. "/mock.lua")
local failed = 0
local function check(what, ok, detail)
    if ok then
        print("ok   " .. what)
    else
        failed = failed + 1
        print("FAIL " .. what .. (detail and (": " .. tostring(detail)) or ""))
    end
end
local function index_of(lines, pattern, from)
    for i = from or 1, #lines do
        if lines[i]:find(pattern, 1, true) then
            return i
        end
    end
end

---- 1. a machine's real facts ----
local lines, binds = run(arg[1], true)
local facts = dofile(arg[1] .. "/golem/machine.lua")
check("the configuration loads and says what it does", #lines > 200, #lines)

local names, twice = {}, {}
for _, line in ipairs(lines) do
    if line:sub(1, 12) == "window_rule(" then
        local name = line:match('name = "([^"]*)"')
        if name then
            if names[name] then twice[#twice + 1] = name end
            names[name] = true
        end
    end
end
check("every window rule has a name of its own (a second one REPLACES the first)", #twice == 0, table.concat(twice, ", "))

-- Two binds on one key, one way (press or release), in one keymap both
-- fire: Super+Return bound twice toggled the stage twice (2026-09-12).
local seen, doubled = {}, {}
for _, b in ipairs(binds) do
    local release = type(b.opts) == "table" and b.opts.release and "release" or "press"
    local id = b.scope .. " | " .. b.keys .. " | " .. release
    if seen[id] then doubled[#doubled + 1] = id end
    seen[id] = true
end
check("no key is bound twice the same way in one keymap", #doubled == 0, table.concat(doubled, "; "))
check("the binds are there", #binds >= 90, #binds)
for _, want in ipairs({
    " | SUPER + Q | press", " | SUPER + L | press", " | SUPER + RETURN | press", " | Print | press", " | Print | release",
    " | XF86AudioRaiseVolume | press", " | XF86PowerOff | release", " | SUPER + mouse:272 | press",
    -- the stage's keymap always carries its own way out (compositor only)
    "stage | SUPER + RETURN | press", "stage | SUPER + SHIFT + ESCAPE | press",
}) do
    check("bound: " .. want, seen[want])
end

local start = index_of(lines, "-- hyprland.start")
check("the lock screen is the first thing the session starts (it is the login)",
    start and lines[start + 1] == 'exec_cmd("golem-lock-screen --login")', start and lines[start + 1])
if not facts.dev then
    local leaked
    for _, line in ipairs(lines) do
        if line:find("/home/max", 1, true) then leaked = line break end
    end
    check("an install runs nothing from /home/max", leaked == nil, leaked)
    check("an install calls the dock's tool from PATH",
        index_of(lines, [[dsp.exec_cmd("sh -c 'waverunner-ctl capture press || golem-screenshot screen'")]]) ~= nil)
    check("an install does not start the dock from here (it is a systemd unit)", index_of(lines, "waverunner-dev") == nil)
end
if facts.plugin then
    check("the overview plugin is loaded at start", index_of(lines, 'exec_cmd("hyprctl plugin load ' .. facts.plugin, start) ~= nil)
end
check("Bluetooth is started only where there is an adapter",
    (index_of(lines, 'exec_cmd("bluetoothctl power on")', start) ~= nil) == (facts.bluetooth and true or false))
check("the keyboard is the machine's",
    index_of(lines, 'kb_layout = "' .. facts.keyboard.layout .. '"') ~= nil)

---- 2. the layers, each after the one before ----
local layers = run(arg[2], false)
local function gaps(n)
    return index_of(layers, "config({ general = { gaps_in = " .. n .. " } })")
end
local golem = index_of(layers, 'name = "move-hyprland-run"') -- the last rule Golem declares
local module, extra, user, live = gaps(21), gaps(22), gaps(23), gaps(7)
check("an app module's own Lua is loaded for a module that is on", module ~= nil)
check("this machine's own Lua is loaded", extra ~= nil)
check("the owner's user.lua is loaded", user ~= nil)
check("the live settings are run", live ~= nil)
check("in order: Golem's modules, the app modules', the machine's, the owner's, the live settings last",
    golem and module and extra and user and live and golem < module and module < extra and extra < user and user < live
    and live == #layers)

---- 3. an app module's own Lua: Gaming ----
local function rule(list, name)
    local found, count
    for i, line in ipairs(list) do
        if line:sub(1, 12) == "window_rule(" and line:find('name = "' .. name .. '"', 1, true) then
            found, count = found or i, (count or 0) + 1
        end
    end
    return found, count or 0
end
local on = false
for _, name in ipairs(facts.modules or {}) do
    if name == "gaming" then on = true end
end
check("Gaming's rule is there on this machine only if the module is on", (rule(lines, "golem-gaming-awake") ~= nil) == on)
check("a module that is off brings nothing (the sample machine has no Gaming)", rule(layers, "golem-gaming-awake") == nil)
local gaming = run(arg[3], false)
local awake, times = rule(gaming, "golem-gaming-awake")
check("Gaming on: a game that fills the screen keeps the computer awake",
    awake ~= nil and times == 1 and gaming[awake]:find('idle_inhibit = "fullscreen"', 1, true) ~= nil
    and gaming[awake]:find("steam_app_", 1, true) ~= nil, awake and gaming[awake])
check("Gaming's rule comes after every rule Golem declares",
    awake ~= nil and (index_of(gaming, 'name = "move-hyprland-run"') or math.huge) < awake)

print(failed == 0 and "hypr-config: all good" or ("hypr-config: " .. failed .. " FAILED"))
os.exit(failed == 0 and 0 or 1)
