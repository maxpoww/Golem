-- Golem: pick a sound card's profile by what is plugged in, not only by its
-- priority.
--
-- PipeWire splits a codec's Speaker and Headphones into two profiles when the
-- two share one PCM (the Lenovo Slim Pro 9i: "HiFi (HDMI1..3, Headphones,
-- Mic1, Mic2)" at priority 10300 and "HiFi (HDMI1..3, Mic1, Mic2, Speaker)" at
-- 10200). A profile counts as available when ANY of its outputs is, so with a
-- screen on HDMI both are available, WirePlumber's find-best-profile takes the
-- higher-priority Headphones one with nothing in the jack, and the laptop's
-- speakers vanish from the output list for as long as the screen is plugged in.
--
-- This hook runs just before find-best-profile and makes the same choice, but
-- first sets aside every profile that carries an output only it has whose
-- jack reports "unplugged". It changes nothing when no such profile exists,
-- when every profile is in that state, or when the user picked a profile
-- (find-stored-profile runs earlier and wins). ALSA cards only.

cutils = require ("common-utils")
log = Log.open_topic ("s-device")

local function hasProfile (route, index)
  for _, i in ipairs (route.profiles or {}) do
    if i == index then
      return true
    end
  end
  return false
end

-- The profile to select, or nil to leave the choice to WirePlumber.
function golemJackProfile (profiles, routes)
  local candidates = {}
  for _, p in ipairs (profiles) do
    if p.name ~= "off" and p.name ~= "pro-audio" and p.available ~= "no" then
      table.insert (candidates, p)
    end
  end
  if #candidates < 2 then
    return nil
  end

  local alive = {}
  for _, p in ipairs (candidates) do
    local dead = false
    for _, r in ipairs (routes) do
      if r.direction == "Output" and r.available == "no" and hasProfile (r, p.index) then
        local shared = false
        for _, other in ipairs (candidates) do
          if other.index ~= p.index and hasProfile (r, other.index) then
            shared = true
            break
          end
        end
        if not shared then
          dead = true
          break
        end
      end
    end
    if not dead then
      table.insert (alive, p)
    end
  end
  if #alive == 0 or #alive == #candidates then
    return nil
  end

  -- find-best-profile's own rule, among the profiles left
  local best, unknown = nil, nil
  for _, p in ipairs (alive) do
    if p.available == "yes" then
      if best == nil or p.priority > best.priority then
        best = p
      end
    elseif unknown == nil or p.priority > unknown.priority then
      unknown = p
    end
  end
  return best or unknown
end

local function params (device, id)
  local out = {}
  for p in device:iterate_params (id) do
    local parsed = cutils.parseParam (p, id)
    if parsed then
      table.insert (out, parsed)
    end
  end
  return out
end

SimpleEventHook {
  name = "device/golem-find-jack-profile",
  after = "device/find-preferred-profile",
  before = "device/find-best-profile",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "select-profile" },
    },
  },
  execute = function (event)
    if event:get_data ("selected-profile") then
      return
    end
    local device = event:get_subject ()
    if device.properties ["device.api"] ~= "alsa" or device.properties ["device.profile"] then
      return
    end

    local profile = golemJackProfile (params (device, "EnumProfile"), params (device, "EnumRoute"))
    if profile then
      log:info (device, string.format ("golem: profile '%s' (%d), its jacks are plugged in",
          profile.name, profile.index))
      event:set_data ("selected-profile", profile)
    end
  end
}:register ()

-- A jack changing state can leave every profile's own availability as it was
-- (with a screen on HDMI, both profiles stay "yes" whether or not headphones
-- are in), and WirePlumber only re-selects a profile when that changes. So a
-- route change asks for a selection too; apply-profile does nothing when the
-- answer is the profile already set.
SimpleEventHook {
  name = "device/golem-reselect-on-jack",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "device-params-changed" },
      Constraint { "event.subject.param-id", "=", "EnumRoute" },
    },
  },
  execute = function (event)
    local device = event:get_subject ()
    if device.properties ["device.api"] ~= "alsa" then
      return
    end
    event:get_source ():call ("push-event", "select-profile", device, nil)
  end
}:register ()
