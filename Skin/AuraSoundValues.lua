local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local KIT_PRESETS = {
	{ id = 878, label = "UI Quest Complete" },
	{ id = 5274, label = "Auction Window Open" },
	{ id = 5275, label = "Auction Window Close" },
	{ id = 8959, label = "Raid Warning" },
	{ id = 12867, label = "Alarm Clock Warning 3" },
	{ id = 18019, label = "UI Bonus Loot Roll" },
	{ id = 11466, label = "UI EpicLoot Toast" },
}
local function DefaultKit(db)
	local kit = db and db.auraSoundDefaultKitID or 0
	if type(kit) ~= "number" or kit <= 0 then
		kit = (SOUNDKIT and SOUNDKIT.UI_AUTO_QUEST_COMPLETE) or 878
	end
	return kit
end
local function SpellName(spellID)
	if C_Spell and C_Spell.GetSpellName then
		local ok, name = pcall(C_Spell.GetSpellName, spellID)
		if ok and name and name ~= "" then
			return name
		end
	end
	return nil
end
local function AddSpell(seen, values, spellID)
	spellID = tonumber(spellID)
	if not spellID or spellID <= 0 or seen[spellID] then
		return
	end
	local name = SpellName(spellID)
	if not name then
		return
	end
	for id, _ in pairs(seen) do
		if type(id) == "number" and values[tostring(id)] == name then
			seen[spellID] = true
			return
		end
	end
	seen[spellID] = true
	values[tostring(spellID)] = name
end
local function CategoryEnum(name)
	local cat = Enum and Enum.CooldownViewerCategory and Enum.CooldownViewerCategory[name]
	if type(cat) == "number" then
		return cat
	end
	return nil
end
local function IsInvisibleInfo(info)
	if not info then
		return true
	end
	if info.isInvisible == true then
		return true
	end
	return false
end
local function DisplaySpellID(info)
	if not info then
		return nil
	end
	return info.overrideTooltipSpellID or info.overrideSpellID or info.spellID
end
local function AddBuffInfoSpells(seen, values, info)
	if not info or IsInvisibleInfo(info) then
		return
	end
	local trackedBuff = CategoryEnum("TrackedBuff")
	if trackedBuff and info.category and info.category ~= trackedBuff then
		return
	end
	AddSpell(seen, values, DisplaySpellID(info))
end
function GCDM:GetAuraSoundSpellValues()
	local values = {}
	local seen = {}
	local registry = self.ViewerRegistry
	local buffViewer = registry and registry.Buff and registry:Buff()
	if buffViewer and Skin and Skin.CollectIconFrames then
		local icons = Skin.CollectIconFrames(buffViewer)
		for j = 1, #icons do
			local frame = icons[j]
			local info = frame and frame.cooldownInfo
			if type(info) ~= "table" and frame and frame.cooldownID and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo then
				local ok, data = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, frame.cooldownID)
				if ok then
					info = data
				end
			end
			if type(info) == "table" then
				AddBuffInfoSpells(seen, values, info)
			else
				AddSpell(seen, values, Skin.GetFrameSpellID and Skin.GetFrameSpellID(frame))
			end
		end
	end
	if next(seen) == nil and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCategorySet then
		local trackedBuff = CategoryEnum("TrackedBuff")
		if trackedBuff then
			local ok, set = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, trackedBuff, false)
			if ok and type(set) == "table" then
				for j = 1, #set do
					local cdID = set[j]
					local info
					if C_CooldownViewer.GetCooldownViewerCooldownInfo then
						local ok2, data = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
						if ok2 then
							info = data
						end
					end
					AddBuffInfoSpells(seen, values, info)
				end
			end
		end
	end
	values.custom = (ns.L and ns.L["AURA_SOUNDS_CUSTOM"]) or "Custom"
	return values
end
local function ParseSoundKey(key, db)
	if type(key) ~= "string" or key == "" then
		return "kit", DefaultKit(db), nil
	end
	local kit = string.match(key, "^kit:(%d+)$")
	if kit then
		return "kit", tonumber(kit), nil
	end
	local lsm = string.match(key, "^lsm:(.+)$")
	if lsm then
		return "lsm", nil, lsm
	end
	local n = tonumber(key)
	if n and n > 0 then
		return "kit", n, nil
	end
	return "lsm", nil, key
end
ns.Testables = ns.Testables or {}
ns.Testables.ParseSoundKey = ParseSoundKey
ns.AuraSoundDefaultKit = DefaultKit
ns.AuraSoundParseKey = ParseSoundKey
local function PlayLSM(name)
	if not name or not Skin or not Skin.FetchMedia then
		return
	end
	local path = Skin.FetchMedia("sound", name)
	if path and PlaySoundFile then
		pcall(PlaySoundFile, path, "Master")
	end
end
local function PlayKit(kit)
	kit = tonumber(kit)
	if not kit or kit <= 0 or not PlaySound then
		return
	end
	pcall(PlaySound, kit, "Master")
end
ns.AuraSoundPlayLSM = PlayLSM
ns.AuraSoundPlayKit = PlayKit
function GCDM:PlayAuraSoundChoice(key)
	local kind, kit, lsm = ParseSoundKey(key, self:GetDB())
	if kind == "kit" then
		PlayKit(kit or DefaultKit(self:GetDB()))
	else
		PlayLSM(lsm)
	end
end
function GCDM:GetAuraSoundSoundValues()
	local values = {}
	for i = 1, #KIT_PRESETS do
		local p = KIT_PRESETS[i]
		values["kit:" .. p.id] = p.label
	end
	if Skin and Skin.ListMedia then
		local lsm = Skin.ListMedia("sound")
		for name in pairs(lsm) do
			values["lsm:" .. name] = name
		end
	end
	return values
end
