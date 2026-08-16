local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local textCache = {}
local rawCache = {}
local cacheVersion = 0

local function FindSlotsForSpell(spellID)
	if not spellID then
		return nil
	end
	if C_ActionBar and C_ActionBar.FindSpellActionButtons then
		local ok, slots = pcall(C_ActionBar.FindSpellActionButtons, spellID)
		if ok and type(slots) == "table" and #slots > 0 then
			return slots
		end
	end
	if not GetActionInfo then
		return nil
	end
	local out
	for slot = 1, 180 do
		local actionType, id = GetActionInfo(slot)
		if actionType == "spell" and id == spellID then
			out = out or {}
			out[#out + 1] = slot
		elseif actionType == "macro" and type(id) == "number" and GetMacroSpell then
			local ok, sid = pcall(GetMacroSpell, id)
			if ok and sid == spellID then
				out = out or {}
				out[#out + 1] = slot
			end
		end
	end
	return out
end

function Skin.SpellLookupIDs(spellID)
	local ids = {}
	local seen = {}
	local function add(id)
		id = tonumber(id)
		if id and id > 0 and not seen[id] then
			seen[id] = true
			ids[#ids + 1] = id
		end
	end
	add(spellID)
	if C_Spell and C_Spell.GetBaseSpell then
		local ok, base = pcall(C_Spell.GetBaseSpell, spellID)
		if ok then
			add(base)
		end
	end
	if FindBaseSpellByID then
		local ok, base = pcall(FindBaseSpellByID, spellID)
		if ok then
			add(base)
		end
	end
	if FindSpellOverrideByID then
		local ok, ov = pcall(FindSpellOverrideByID, spellID)
		if ok then
			add(ov)
		end
	end
	return ids
end

local function ComputeShortestText(spellID)
	local shortest
	local ids = Skin.SpellLookupIDs(spellID)
	for i = 1, #ids do
		local slots = FindSlotsForSpell(ids[i])
		if slots then
			for j = 1, #slots do
				local text = Skin.ShortestTextForSlot(slots[j])
				if text and (not shortest or #text < #shortest) then
					shortest = text
				end
			end
		end
	end
	return shortest
end

local function ComputeRawKeys(spellID)
	local out = {}
	local seen = {}
	local ids = Skin.SpellLookupIDs(spellID)
	for i = 1, #ids do
		local slots = FindSlotsForSpell(ids[i])
		if slots then
			for j = 1, #slots do
				local bucket = {}
				Skin.CollectRawKeysForSlot(slots[j], bucket)
				for k = 1, #bucket do
					local key = bucket[k]
					if not seen[key] then
						seen[key] = true
						out[#out + 1] = key
					end
				end
			end
		end
	end
	if #out == 0 then
		return nil
	end
	return out
end

function Skin.GetKeybindCacheVersion()
	return cacheVersion
end

function Skin.InvalidateKeybinds()
	wipe(textCache)
	wipe(rawCache)
	if Skin.ClearMainBarPageCache then
		Skin.ClearMainBarPageCache()
	end
	cacheVersion = cacheVersion + 1
end

function Skin.GetKeybindText(spellID)
	spellID = tonumber(spellID)
	if not spellID then
		return nil
	end
	local cached = textCache[spellID]
	if cached ~= nil then
		return cached or nil
	end
	local text = ComputeShortestText(spellID)
	textCache[spellID] = text or false
	return text
end

function Skin.GetRawKeysForSpell(spellID)
	spellID = tonumber(spellID)
	if not spellID then
		return nil
	end
	local cached = rawCache[spellID]
	if cached ~= nil then
		return cached or nil
	end
	local keys = ComputeRawKeys(spellID)
	rawCache[spellID] = keys or false
	return keys
end
