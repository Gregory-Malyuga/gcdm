local ADDON_NAME, ns = ...
local L = ns.L

--- Shared label helpers for Aura Sounds options.
function ns.AuraSoundSpellLabel(spellID)
	spellID = tonumber(spellID)
	if not spellID then
		return "?"
	end
	if C_Spell and C_Spell.GetSpellName then
		local ok, name = pcall(C_Spell.GetSpellName, spellID)
		if ok and name and name ~= "" then
			return name
		end
	end
	return L["AURA_SOUNDS_SPELL_UNKNOWN"] or "Unknown"
end

function ns.AuraSoundSoundLabel(addon, soundKey)
	if type(soundKey) ~= "string" or soundKey == "" then
		return "?"
	end
	local values = addon.GetAuraSoundSoundValues and addon:GetAuraSoundSoundValues()
	if values and values[soundKey] then
		return values[soundKey]
	end
	local lsm = string.match(soundKey, "^lsm:(.+)$")
	if lsm then
		return lsm
	end
	local kit = string.match(soundKey, "^kit:(%d+)$")
	if kit then
		local key = "kit:" .. kit
		if values and values[key] then
			return values[key]
		end
	end
	return soundKey
end

function ns.AuraSoundEventLabel(event)
	if event == "stack" then
		return L["AURA_SOUNDS_EVENT_STACK"]
	end
	if event == "remove" then
		return L["AURA_SOUNDS_EVENT_REMOVE"]
	end
	return L["AURA_SOUNDS_EVENT_APPLY"]
end

function ns.AuraSoundUnitLabel(unit)
	if unit == "target" then
		return L["AURA_SOUNDS_UNIT_TARGET"]
	end
	if unit == "focus" then
		return L["AURA_SOUNDS_UNIT_FOCUS"]
	end
	return L["AURA_SOUNDS_UNIT_PLAYER"]
end
