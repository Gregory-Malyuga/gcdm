local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local COOLDOWN_VIEWERS = GCDM.CONST.COOLDOWN_VIEWER_NAMES
local PO = Skin._PressOverlayState

local function SpellAliases(spellID)
	if Skin.SpellLookupIDs then
		return Skin.SpellLookupIDs(spellID)
	end
	return { tonumber(spellID) }
end

local function CountKeys(t)
	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end
	return n
end

function Skin.PressOverlayParseRawKey(rawKey)
	if type(rawKey) ~= "string" or rawKey == "" then
		return nil
	end
	local shift, ctrl, alt = false, false, false
	local remaining = rawKey
	while true do
		if remaining:sub(1, 6) == "SHIFT-" then
			shift = true
			remaining = remaining:sub(7)
		elseif remaining:sub(1, 5) == "CTRL-" then
			ctrl = true
			remaining = remaining:sub(6)
		elseif remaining:sub(1, 4) == "ALT-" then
			alt = true
			remaining = remaining:sub(5)
		else
			break
		end
	end
	if remaining == "" then
		return nil
	end
	return { key = remaining, shift = shift, ctrl = ctrl, alt = alt, raw = rawKey }
end

function Skin.PressOverlayEnsureMap()
	local ver = Skin.GetKeybindCacheVersion and Skin.GetKeybindCacheVersion() or 0
	if ver == PO.mapCacheVer then
		return
	end
	PO.mapCacheVer = ver
	wipe(PO.spellCombos)
	wipe(PO.spellFrames)

	if not Skin.PressOverlayIsEnabled() then
		Skin.PressOverlayLog("map rebuild skipped (press disabled)")
		return
	end

	local registry = GCDM.ViewerRegistry
	if not registry then
		Skin.PressOverlayLog("map rebuild: no ViewerRegistry")
		return
	end

	local iconCount, withSpell, withKeys = 0, 0, 0
	local samples = {}

	for i = 1, #COOLDOWN_VIEWERS do
		local viewerName = COOLDOWN_VIEWERS[i]
		local viewer = registry:Get(viewerName)
		local icons = Skin.CollectIconFrames(viewer)
		for j = 1, #icons do
			iconCount = iconCount + 1
			local frame = icons[j]
			local spellID = Skin.GetFrameSpellID and Skin.GetFrameSpellID(frame)
			if spellID then
				withSpell = withSpell + 1
				local aliases = SpellAliases(spellID)
				local rawKeys = Skin.GetRawKeysForSpell and Skin.GetRawKeysForSpell(spellID)
				local text = Skin.GetKeybindText and Skin.GetKeybindText(spellID)
				local combos
				if rawKeys then
					combos = {}
					for k = 1, #rawKeys do
						local combo = Skin.PressOverlayParseRawKey(rawKeys[k])
						if combo then
							combos[#combos + 1] = combo
						end
					end
					if #combos == 0 then
						combos = nil
					end
				end
				if combos then
					withKeys = withKeys + 1
				end
				if #samples < 8 then
					samples[#samples + 1] = string.format(
						"%s sid=%s kb=%s raw=%s",
						tostring(viewerName):gsub("CooldownViewer", ""),
						tostring(spellID),
						tostring(text),
						rawKeys and table.concat(rawKeys, ",") or "nil"
					)
				end
				for a = 1, #aliases do
					local sid = aliases[a]
					local list = PO.spellFrames[sid]
					if not list then
						list = {}
						PO.spellFrames[sid] = list
					end
					list[#list + 1] = frame
					if combos then
						PO.spellCombos[sid] = combos
					end
				end
			end
		end
	end

	Skin.PressOverlayLog(string.format(
		"map v=%d icons=%d withSpell=%d withKeys=%d comboSpells=%d",
		ver, iconCount, withSpell, withKeys, CountKeys(PO.spellCombos)
	))
	for i = 1, #samples do
		Skin.PressOverlayLog("  " .. samples[i])
	end
	if withKeys == 0 and withSpell > 0 then
		Skin.PressOverlayLog("WARN: CDM icons found but no action-bar keybinds matched (FindSpellActionButtons/scan empty?)")
	end
	if iconCount == 0 then
		Skin.PressOverlayLog("WARN: no Essential/Utility icon frames")
	end
end

function Skin.RebuildPressOverlayMap()
	PO.mapCacheVer = -1
	Skin.PressOverlayEnsureMap()
end

function Skin.PressOverlaySpellAliases(spellID)
	return SpellAliases(spellID)
end

function Skin.PressOverlayCountKeys(t)
	return CountKeys(t)
end
