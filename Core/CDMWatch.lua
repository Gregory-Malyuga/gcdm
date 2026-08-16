local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

-- Why this exists: hooking Cooldown Manager mixins puts GCDM inside Blizzard's
-- own call stack, and everything Blizzard does after that point runs tainted —
-- which is fatal now that cooldown and aura values are secret ("attempted to
-- index a table that cannot be accessed while tainted"). So we listen to the
-- same game events on our own frame and restyle afterwards, on our own stack.

GCDM.CDMWatch = GCDM.CDMWatch or {}
local Watch = GCDM.CDMWatch

local listeners = {}
local order = {}
local pending = false

local EVENTS = {
	"SPELL_UPDATE_COOLDOWN",
	"SPELL_UPDATE_CHARGES",
	"SPELL_UPDATE_ICON",
	"SPELL_UPDATE_USABLE",
	"SPELLS_CHANGED",
	"PLAYER_EQUIPMENT_CHANGED",
	"TRAIT_CONFIG_UPDATED",
	"ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
	"PLAYER_TARGET_CHANGED",
	"PLAYER_ENTERING_WORLD",
	"COOLDOWN_VIEWER_DATA_LOADED",
	"COOLDOWN_VIEWER_TABLE_HOTFIXED",
}

local function Now()
	return GetTime and GetTime() or 0
end

local function Flush()
	pending = false
	local now = Now()
	local soonest
	for i = 1, #order do
		local entry = listeners[order[i]]
		if entry then
			local wait = (entry.last + entry.throttle) - now
			if entry.throttle > 0 and wait > 0 then
				if not soonest or wait < soonest then
					soonest = wait
				end
			else
				local events = entry.events
				entry.events = {}
				entry.last = now
				if GCDM:IsModuleEnabled(entry.id) then
					local ok, err = pcall(entry.fn, events)
					if not ok and not entry.errored then
						entry.errored = true
						print("|cff3bb273GCDM|r " .. entry.id .. " watch error: " .. tostring(err))
					end
				end
			end
		end
	end
	if soonest then
		Watch:Schedule(soonest)
	end
end

--- Ask for a pass; repeated calls inside one frame collapse into one.
function Watch:Schedule(delay)
	if pending then
		return
	end
	pending = true
	C_Timer.After(delay or 0, Flush)
end

function Watch:Notify()
	self:Schedule(0)
end

--- throttle is the minimum gap in seconds between two passes of this listener.
--- The listener is called with the set of events seen since its last pass.
function Watch:Register(id, fn, throttle)
	if not listeners[id] then
		order[#order + 1] = id
	end
	listeners[id] = {
		id = id,
		fn = fn,
		throttle = throttle or 0,
		last = 0,
		events = {},
	}
end

function Watch:Unregister(id)
	listeners[id] = nil
	for i = 1, #order do
		if order[i] == id then
			table.remove(order, i)
			break
		end
	end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, event)
	for i = 1, #order do
		local entry = listeners[order[i]]
		if entry then
			entry.events[event] = true
		end
	end
	Watch:Schedule(0)
end)

for i = 1, #EVENTS do
	local event = EVENTS[i]
	local valid = true
	if C_EventUtils and C_EventUtils.IsEventValid then
		valid = C_EventUtils.IsEventValid(event)
	end
	if valid then
		pcall(frame.RegisterEvent, frame, event)
	end
end
pcall(frame.RegisterUnitEvent, frame, "UNIT_AURA", "player")
