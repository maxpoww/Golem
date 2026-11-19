-- test/mock.lua: Golem's Hyprland configuration run with NO compositor.
--
--   lua mock.lua <config root> [handlers]
--
-- A recording `hl` stands in for Hyprland's: every call the configuration
-- makes is written down, in order, with its arguments (tables with their keys
-- sorted, functions as <fn>, the hl.dsp.* constructors as what they build).
-- Two configurations that print the same lines DO the same thing; that is how
-- the split of the one-file hyprland.lua into modules was proven (README.md).
--
-- With `handlers` the functions the configuration registered are then run
-- too: what starts with the session, a new screen, a window taking the
-- focus, and every key whose action is Lua (in the order of their keys, then
-- a few sequences: a tap of Super, the Lenovo's PrtSc burst, voice to text).
--
-- The environment the configuration reads is the caller's: point
-- XDG_STATE_HOME and XDG_CONFIG_HOME at scratch folders (the screens' blocks
-- are WRITTEN under the first; the live settings are read from the second).
--
-- As a library (`MOCK_LIBRARY = true` before dofile) it returns
-- run(root, handlers) -> the lines, the binds, the monitors it faked.

local function ser(v)
    local t = type(v)
    if t == "string" then
        return (string.format("%q", v):gsub("\\\n", "\\n"))
    elseif t == "number" then
        if math.type(v) == "integer" then
            return tostring(v)
        end
        return string.format("%.14g", v) .. "f"
    elseif t == "boolean" or t == "nil" then
        return tostring(v)
    elseif t == "function" then
        return "<fn>"
    elseif t == "table" then
        local dsp = rawget(v, "__dsp")
        if dsp then
            local parts = {}
            for i = 1, v.args.n do
                parts[#parts + 1] = ser(v.args[i])
            end
            return "dsp." .. dsp .. "(" .. table.concat(parts, ", ") .. ")"
        end
        if rawget(v, "__handle") then
            return "<" .. v.__handle .. ">"
        end
        local parts, n = {}, #v
        for i = 1, n do
            parts[#parts + 1] = ser(v[i])
        end
        local keys = {}
        for k in pairs(v) do
            if not (math.type(k) == "integer" and k >= 1 and k <= n) then
                keys[#keys + 1] = k
            end
        end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        for _, k in ipairs(keys) do
            parts[#parts + 1] = tostring(k) .. " = " .. ser(v[k])
        end
        return "{ " .. table.concat(parts, ", ") .. " }"
    end
    return "<" .. t .. ">"
end

local function args(...)
    local packed, parts = table.pack(...), {}
    for i = 1, packed.n do
        parts[#parts + 1] = ser(packed[i])
    end
    return table.concat(parts, ", ")
end

local function run(root, with_handlers)
    local lines = {}
    local function emit(line)
        lines[#lines + 1] = line
    end

    -- hl.dsp.a.b(...) builds a dispatcher (no effect); hl.plugin.a.b(...) acts.
    local function proxy(kind, path)
        return setmetatable({}, {
            __index = function(_, k)
                return proxy(kind, path == "" and k or (path .. "." .. k))
            end,
            __call = function(_, ...)
                if kind == "dsp" then
                    return { __dsp = path, args = table.pack(...) }
                end
                emit("plugin." .. path .. "(" .. args(...) .. ")")
            end,
        })
    end

    local function monitors()
        return {
            { name = "eDP-1", description = "Lenovo Group Limited 0x8BA2", active_workspace = { id = 1 } },
            { name = "HDMI-A-1", description = "LG Electronics LG TV 0x01010101", active_workspace = { id = 7 } },
        }
    end

    local scope, handlers, binds, timers = "", {}, {}, {}
    local hl = { dsp = proxy("dsp", ""), plugin = proxy("plugin", "") }
    function hl.on(event, fn)
        emit("on(" .. ser(event) .. ", <fn>)")
        handlers[#handlers + 1] = { event = event, fn = fn }
        return { __handle = "on" }
    end
    function hl.bind(keys, action, opts)
        emit("bind\t" .. scope .. "\t" .. ser(keys) .. "\t" .. ser(action) .. "\t" .. ser(opts))
        binds[#binds + 1] = { scope = scope, keys = keys, action = action, opts = opts }
        return { __handle = "bind" }
    end
    function hl.define_submap(name, fn)
        emit("bind\t" .. name .. "\t<define_submap begin>")
        local outer = scope
        scope = name
        fn()
        scope = outer
        emit("bind\t" .. name .. "\t<define_submap end>")
    end
    function hl.timer(fn, opts)
        emit("timer(<fn>, " .. ser(opts) .. ")")
        timers[#timers + 1] = fn
        return { __handle = "timer" }
    end
    function hl.get_monitors()
        emit("get_monitors()")
        return monitors()
    end
    function hl.get_active_monitor()
        emit("get_active_monitor()")
        return monitors()[1]
    end
    setmetatable(hl, {
        __index = function(t, name)
            local f = function(...)
                emit(name .. "(" .. args(...) .. ")")
                return { __handle = name }
            end
            rawset(t, name, f)
            return f
        end,
    })

    _G.hl = hl
    package.path = root .. "/?.lua;" .. root .. "/?/init.lua"
    for name in pairs(package.loaded) do
        if name == "user" or name:match("^golem%.") then
            package.loaded[name] = nil
        end
    end
    dofile(root .. "/hyprland.lua")

    if with_handlers then
        emit("== handlers ==")
        local function fire_timers()
            local due = timers
            timers = {}
            for _, fn in ipairs(due) do
                fn()
            end
        end
        for _, h in ipairs(handlers) do
            if h.event == "hyprland.start" then
                emit("-- hyprland.start")
                h.fn()
            end
        end
        for _, h in ipairs(handlers) do
            if h.event == "monitor.added" then
                emit("-- monitor.added: a screen seen before, then a new one")
                h.fn(monitors()[2])
                h.fn({ name = "DP-3", description = "ACME Projector 42", active_workspace = { id = 1 } })
                h.fn({ name = "FALLBACK", description = "", active_workspace = { id = 1 } })
            elseif h.event == "window.active" then
                emit("-- window.active: a floating window, then a tiled one")
                h.fn({ floating = true, address = "0x1" }, 1)
                h.fn({ floating = false, address = "0x2" }, 1)
                h.fn(nil, 1)
            end
        end
        -- every key whose action is Lua, in the order of its keys
        local lua_binds = {}
        for i, b in ipairs(binds) do
            if type(b.action) == "function" then
                lua_binds[#lua_binds + 1] = { at = i, b = b, key = b.scope .. "\t" .. b.keys .. "\t" .. ser(b.opts) }
            end
        end
        table.sort(lua_binds, function(x, y)
            if x.key ~= y.key then
                return x.key < y.key
            end
            return x.at < y.at
        end)
        for _, e in ipairs(lua_binds) do
            emit("-- key " .. e.key:gsub("\t", " | "))
            e.b.action()
        end
        fire_timers()
        local function press(scope_, keys, release)
            for _, b in ipairs(binds) do
                local rel = type(b.opts) == "table" and b.opts.release or false
                if b.scope == scope_ and b.keys == keys and (rel and true or false) == (release and true or false) then
                    if type(b.action) == "function" then
                        b.action()
                    else
                        emit("  -> " .. ser(b.action))
                    end
                end
            end
        end
        emit("-- sequence: Super down, Super+Shift+S within the burst (the Lenovo's PrtSc), then after it")
        press("", "Super_L")
        press("", "SUPER + SHIFT + S")
        fire_timers()
        press("", "SUPER + SHIFT + S")
        emit("-- sequence: a tap of Super (down, up), then a hold (down, 300 ms, up)")
        press("", "Super_L")
        press("", "SUPER + Super_L", true)
        press("", "Super_R")
        fire_timers()
        press("", "SUPER + Super_R", true)
        emit("-- sequence: voice to text (Super+Space down, Space up, Space up again)")
        press("", "SUPER + SPACE")
        press("", "SPACE", true)
        press("", "SPACE", true)
        emit("-- sequence: Super+Escape while dictating, then not")
        _G.golem_dictating = true
        press("", "SUPER + ESCAPE")
        _G.golem_dictating = nil
        press("", "SUPER + ESCAPE")
    end
    return lines, binds
end

if MOCK_LIBRARY then
    return run
end
local root = arg and arg[1]
if not root then
    io.stderr:write("usage: lua mock.lua <config root> [handlers]\n")
    os.exit(2)
end
for _, line in ipairs((run(root, arg[2] == "handlers"))) do
    print(line)
end
