-- Golem: the owner's equalizer, one per output, put back whenever the output
-- appears (start, a profile switch, a Bluetooth device connecting).
--
-- The dock owns the equalizer: its pages change the sound live (pw-cli on
-- the output's own node) and keep what was chosen in this WirePlumber state
-- file, ~/.local/state/wireplumber/golem-eq:
--
--   [golem-eq]
--   <node.name>={"on":true,"pre":-3.0,"bands":[{"t":"low","f":100,"g":3.0,"q":0.7}, …]}
--
--   t   low | bell | high | cut   (low shelf, peak, high shelf, high-pass)
--   f   Hz;  g  dB;  q  width
--   pre dB in front of the bands: minus the curve's highest boost, worked out
--       by the dock, so a boost never pushes a peak past what came in
--
-- This hook only reads it: on a new output node it loads that output's
-- equalizer as filter graph 1 inside the node (audioconvert.filter-graph.1),
-- after graph 0, the model's speaker tuning (tunings.nix), so the owner's
-- choice sits on top of the factory one. Nothing is loaded when it is off or
-- flat, so an untouched output costs nothing.

log = Log.open_topic ("s-node")

local KINDS = { low = "bq_lowshelf", bell = "bq_peaking", high = "bq_highshelf", cut = "bq_highpass" }
local MAX_BANDS = 12

-- A number as SPA-JSON wants it, whatever LC_NUMERIC says: Lua's own
-- formatting follows the C locale, and a comma there breaks the graph.
function golemEqNum (x)
  x = tonumber (x) or 0
  local sign = x < 0 and "-" or ""
  x = math.abs (x)
  local whole = math.floor (x)
  local frac = math.floor ((x - whole) * 1000 + 0.5)
  if frac >= 1000 then
    whole = whole + 1
    frac = 0
  end
  return sign .. string.format ("%d", whole) .. "." .. string.format ("%03d", frac)
end

-- The filter graph for one output's equalizer, or nil when there is nothing
-- to load (off, no bands, every band flat).
function golemEqGraph (eq)
  if type (eq) ~= "table" or eq.on == false or type (eq.bands) ~= "table" then
    return nil
  end
  local nodes, links, prev = {}, {}, nil
  local any = false
  local pre = tonumber (eq.pre) or 0
  if pre < -0.05 then
    local mult = 10 ^ (pre / 20)
    table.insert (nodes, "{ type = builtin name = pre label = linear control = { Mult = " .. golemEqNum (mult) .. " } }")
    prev = "pre"
  end
  for i, b in ipairs (eq.bands) do
    if i > MAX_BANDS then
      break
    end
    local label = KINDS [b.t]
    local f, g, q = tonumber (b.f), tonumber (b.g) or 0, tonumber (b.q) or 0.7
    if label and f and f >= 10 and f <= 24000 and q > 0 and (b.t == "cut" or math.abs (g) >= 0.05) then
      local name = "b" .. i
      local control = "Freq = " .. golemEqNum (f) .. " Q = " .. golemEqNum (q)
      if b.t ~= "cut" then
        control = control .. " Gain = " .. golemEqNum (g)
      end
      table.insert (nodes, "{ type = builtin name = " .. name .. " label = " .. label .. " control = { " .. control .. " } }")
      if prev then
        table.insert (links, "{ output = \"" .. prev .. ":Out\" input = \"" .. name .. ":In\" }")
      end
      prev = name
      any = true
    end
  end
  if not any then
    return nil
  end
  return "{ nodes = [ " .. table.concat (nodes, " ") .. " ] links = [ " .. table.concat (links, " ") .. " ] }"
end

local function apply (node)
  local name = node.properties ["node.name"]
  if node.properties ["media.class"] ~= "Audio/Sink" or not name then
    return
  end
  local value = State ("golem-eq"):load () [name]
  if not value then
    return
  end
  local ok, eq = pcall (function () return Json.Raw (value):parse () end)
  if not ok then
    log:warning (node, "golem-eq: unreadable equalizer for " .. name)
    return
  end
  local graph = golemEqGraph (eq)
  if not graph then
    return
  end
  log:info (node, "golem-eq: equalizer on " .. name)
  node:set_params ("Props", Pod.Object {
    "Spa:Pod:Object:Param:Props", "Props",
    params = Pod.Struct { "audioconvert.filter-graph.1", graph }
  })
end

-- An output that appears from now on…
SimpleEventHook {
  name = "node/golem-eq",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "node-added" },
      Constraint { "library.name", "=", "audioconvert/libspa-audioconvert", type = "pw" },
    },
  },
  execute = function (event)
    apply (event:get_subject ())
  end
}:register ()

-- …and the ones already there when this script loads: components load in
-- their own order, and the outputs WirePlumber's monitor made before this
-- one came up never pass through the hook above (seen in an isolated
-- WirePlumber 0.5.14). Setting the same graph twice is harmless.
golem_eq_outputs = ObjectManager {
  Interest {
    type = "node",
    Constraint { "media.class", "=", "Audio/Sink", type = "pw-global" },
  }
}
golem_eq_outputs:connect ("installed", function (om)
  for node in om:iterate () do
    apply (node)
  end
end)
golem_eq_outputs:activate ()
