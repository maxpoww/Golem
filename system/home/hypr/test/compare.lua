-- test/compare.lua <old.log> <new.log>: do two recordings (mock.lua, with
-- `handlers`) describe the same configuration?
--
-- What must hold:
--   1. every call that is not a key bind: the SAME lines in the SAME order
--      (rules, settings, layers, animations, monitors, environment, events);
--   2. the key binds: the same binds, and for each KEY (whatever the
--      modifiers, whatever the submap) in the same order. Hyprland walks its
--      binds in the order they were made and acts on those that match the
--      key event (KeybindManager.cpp, handleKeybinds): only binds of one key
--      can meet on one event, so their order among themselves is all that a
--      hand can tell. Across different keys the order is free, which is
--      what lets the binds be grouped by concern;
--   3. what the handlers do when run: the SAME lines in the SAME order.
-- Exit 0 when all three hold; prints what differs otherwise.

local function read(path)
    local load, handlers, binds, target = {}, {}, {}, nil
    target = load
    for line in io.lines(path) do
        if line == "== handlers ==" then
            target = handlers
        elseif target == load and line:sub(1, 5) == "bind\t" then
            binds[#binds + 1] = line
        else
            target[#target + 1] = line
        end
    end
    return load, binds, handlers
end

local function same_sequence(what, a, b)
    local n = math.max(#a, #b)
    for i = 1, n do
        if a[i] ~= b[i] then
            print(("DIFFERENT %s at line %d:\n  old: %s\n  new: %s"):format(what, i, tostring(a[i]), tostring(b[i])))
            return false
        end
    end
    print(("same %s: %d lines, same order"):format(what, #a))
    return true
end

local function by_key(binds)
    local keys, order = {}, {}
    for _, line in ipairs(binds) do
        -- the key itself: the last word of "SUPER + SHIFT + S" (a submap's
        -- own begin and end lines go by the submap's name)
        local scope, combo = line:match("^bind\t([^\t]*)\t([^\t]*)")
        local id = combo:match('^"(.*)"$')
        id = id and (id:match("([^ +]+)$") or id):lower() or ("submap " .. scope)
        if not keys[id] then
            keys[id] = {}
            order[#order + 1] = id
        end
        table.insert(keys[id], line)
    end
    table.sort(order)
    return keys, order
end

local old_load, old_binds, old_handlers = read(arg[1])
local new_load, new_binds, new_handlers = read(arg[2])
local ok = same_sequence("calls that are not binds", old_load, new_load)

local ok_binds = #old_binds == #new_binds
local old_keys, old_order = by_key(old_binds)
local new_keys, new_order = by_key(new_binds)
if table.concat(old_order, "\n") ~= table.concat(new_order, "\n") then
    ok_binds = false
    print("DIFFERENT keys bound")
end
for _, id in ipairs(old_order) do
    local a, b = old_keys[id], new_keys[id] or {}
    if table.concat(a, "\n") ~= table.concat(b, "\n") then
        ok_binds = false
        print("DIFFERENT binds of the key " .. id .. ":\n  old: " .. table.concat(a, "\n       ") .. "\n  new: " .. table.concat(b, "\n       "))
    end
end
local in_order = table.concat(old_binds, "\n") == table.concat(new_binds, "\n")
if ok_binds then
    -- (a submap's begin and end are two lines of the list and one "key" of it)
    local real, submaps = 0, 0
    for _, line in ipairs(old_binds) do
        if line:match('^bind\t[^\t]*\t"') then real = real + 1 else submaps = submaps + 1 end
    end
    submaps = submaps // 2
    print(("same binds: %d binds on %d keys (and %d submap), each key's binds in the same order%s"):format(
        real, #old_order - submaps, submaps, in_order and "; the whole list in the same order too" or " (regrouped across keys)"))
end
local ok_handlers = same_sequence("handlers' doings", old_handlers, new_handlers)
os.exit((ok and ok_binds and ok_handlers) and 0 or 1)
