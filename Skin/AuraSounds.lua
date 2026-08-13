local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

-- Combat-safe aura sounds:
--   SoundKit → C_UnitAuras.AddAuraSound (apply / stack / remove)
--   LibSharedMedia → PlaySoundFile on apply/remove via UNIT_AURA (stack stays SoundKit-only)

local handles = {}
local lsmRules = {} -- rules that need UNIT_AURA + PlaySoundFile
local knownAuras = {} -- [unit][spellID] = true
local applying = false
local watchFrame

local EVENT_TO_KEY = {
	apply = "onApply",
	stack = "onApplication",
	remove = "onRemove",
}

local KIT_PRESETS = {
	{ id = 878, label = "UI Quest Complete" },
	{ id = 5274, label = "Auction Window Open" },
	{ id = 5275, label = "Auction Window Close" },
	{ id = 8959, label = "Raid Warning" },
	{ id = 12867, label = "Alarm Clock Warning 3" },
	{ id = 18019, label = "UI Bonus Loot Roll" },
	{ id = 11466, label = "UI EpicLoot Toast" },
}

local function ClearHandles()
	if not C_UnitAuras then
		wipe(handles)
		return
	end
	for i = 1, #handles do
		local h = handles[i]
		if h then
			if C_UnitAuras.RemoveAuraSound then
				pcall(C_UnitAuras.RemoveAuraSound, h)
			elseif C_UnitAuras.RemoveAuraAppliedSound then
				pcall(C_UnitAuras.RemoveAuraAppliedSound, h)
			end
		end
	end
	wipe(handles)
end

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
		if ok and name then
			return name
		end
	end
	return tostring(spellID)
end

local function GetFrameSpellID(frame)
	if not frame then
		return nil
	end
	if type(frame.spellID) == "number" then
		return frame.spellID
	end
	local info = frame.cooldownInfo
	if info and type(info.spellID) == "number" then
		return info.spellID
	end
	local cdID = frame.cooldownID
	if cdID and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo then
		local ok, data = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
		if ok and data and type(data.spellID) == "number" then
			return data.spellID
		end
	end
	return nil
end

local function AddSpell(seen, values, spellID, prefix)
	spellID = tonumber(spellID)
	if not spellID or spellID <= 0 or seen[spellID] then
		return
	end
	seen[spellID] = true
	local key = tostring(spellID)
	local label = SpellName(spellID) .. " (" .. key .. ")"
	if prefix then
		label = prefix .. " · " .. label
	end
	values[key] = label
end

local function ParseIdList(str, seen, values, prefix)
	if type(str) ~= "string" or str == "" then
		return
	end
	for part in string.gmatch(str, "[^,%s]+") do
		local id = string.match(part, "^(%d+)")
		AddSpell(seen, values, id, prefix)
	end
end

local function CategoryEnum(name)
	local cat = Enum and Enum.CooldownViewerCategory and Enum.CooldownViewerCategory[name]
	if type(cat) == "number" then
		return cat
	end
	return nil
end

local function IsEffectCategory(cat)
	local trackedBuff = CategoryEnum("TrackedBuff")
	local trackedBar = CategoryEnum("TrackedBar")
	local groupBuff = CategoryEnum("GroupBuff")
	local specTracked = CategoryEnum("SpecAgnosticTracked")
	local equipTracked = CategoryEnum("EquipSlotTracked")
	return cat == trackedBuff
		or cat == trackedBar
		or cat == groupBuff
		or cat == specTracked
		or cat == equipTracked
end

local function EffectCategoryPrefix(cat, info, L)
	local trackedBuff = CategoryEnum("TrackedBuff")
	local trackedBar = CategoryEnum("TrackedBar")
	local groupBuff = CategoryEnum("GroupBuff")
	local invisible = info and info.isInvisible
	if invisible then
		return L["CDM_EFFECT_HIDDEN"] or "Not displayed"
	end
	if cat == trackedBuff then
		return L["BLOCK_BUFF"] or "Buff icons"
	end
	if cat == trackedBar then
		return L["BLOCK_BUFF_BAR"] or "Buff bars"
	end
	if cat == groupBuff then
		return L["CDM_EFFECT_GROUP"] or "Group buffs"
	end
	return L["CDM_EFFECT_HIDDEN"] or "Not displayed"
end

-- Effect spells only (buff icons / buff bars / hidden), including inactive & unlearned.
-- Does NOT list Essential/Utility abilities.
function GCDM:GetAuraSoundSpellValues()
	local values = {}
	local seen = {}
	local L = ns.L

	local categories = {
		CategoryEnum("TrackedBuff"),
		CategoryEnum("TrackedBar"),
		CategoryEnum("GroupBuff"),
		CategoryEnum("EquipSlotTracked"),
		-- Last: leftover / not-displayed / unlearned effect pool.
		CategoryEnum("SpecAgnosticTracked"),
	}

	if C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCategorySet and C_CooldownViewer.GetCooldownViewerCooldownInfo then
		for i = 1, #categories do
			local cat = categories[i]
			if cat ~= nil then
				-- true = include unlearned + not currently displayed.
				local ok, ids = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, cat, true)
				if ok and type(ids) == "table" then
					for j = 1, #ids do
						local cdID = ids[j]
						local okInfo, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
						if okInfo and type(info) == "table" then
							local spellID = info.spellID or info.overrideSpellID
							local infoCat = info.category or cat
							-- Never list Essential/Utility abilities.
							if spellID and IsEffectCategory(infoCat) then
								local prefix = EffectCategoryPrefix(infoCat, info, L)
								AddSpell(seen, values, spellID, prefix)
								if type(info.linkedSpellIDs) == "table" then
									for k = 1, #info.linkedSpellIDs do
										AddSpell(seen, values, info.linkedSpellIDs[k], prefix)
									end
								end
							end
						end
					end
				end
			end
		end
	end

	-- Fallback: currently shown Buff / BuffBar viewer frames only (if API empty).
	if next(seen) == nil then
		local registry = self.ViewerRegistry
		if registry and Skin and Skin.CollectIconFrames then
			local buff = registry.Buff and registry:Buff()
			if buff then
				local icons = Skin.CollectIconFrames(buff)
				local prefix = L["BLOCK_BUFF"] or "Buff icons"
				for j = 1, #icons do
					AddSpell(seen, values, GetFrameSpellID(icons[j]), prefix)
				end
			end
			if Skin.CollectBarFrames and registry.BuffBar then
				local bars = Skin.CollectBarFrames(registry:BuffBar())
				local prefix = L["BLOCK_BUFF_BAR"] or "Buff bars"
				for j = 1, #bars do
					AddSpell(seen, values, GetFrameSpellID(bars[j]), prefix)
				end
			end
		end
	end

	local db = self:GetDB()
	if db then
		ParseIdList(db.auraBarSpellIDs, seen, values, L["BLOCK_AURA"] or "Aura")
		ParseIdList(db.auraAppSpellIDs, seen, values, L["BLOCK_AURA"] or "Aura")
	end
	values["custom"] = L["AURA_SOUNDS_SPELL_CUSTOM"] or "Custom spell ID…"
	return values
end

function GCDM:GetAuraSoundSoundValues()
	local values = {}
	local L = ns.L
	for i = 1, #KIT_PRESETS do
		local p = KIT_PRESETS[i]
		values["kit:" .. p.id] = string.format("[Kit] %s (%d)", p.label, p.id)
	end
	if Skin and Skin.ListMedia then
		local lsm = Skin.ListMedia("sound")
		for name in pairs(lsm) do
			values["lsm:" .. name] = (L["AURA_SOUNDS_LSM_PREFIX"] or "[Media] ") .. name
		end
	end
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
	-- Legacy numeric kit
	local n = tonumber(key)
	if n and n > 0 then
		return "kit", n, nil
	end
	-- Bare LSM name
	return "lsm", nil, key
end

local function PlayLSM(name)
	if not name or not Skin or not Skin.FetchMedia then
		return
	end
	local path = Skin.FetchMedia("sound", name)
	if path and PlaySoundFile then
		pcall(PlaySoundFile, path, "Master")
	end
end

function GCDM:PlayAuraSoundChoice(key)
	local kind, kit, lsm = ParseSoundKey(key, self:GetDB())
	if kind == "kit" then
		kit = kit or DefaultKit(self:GetDB())
		if PlaySound then
			pcall(PlaySound, kit, "Master")
		end
	else
		PlayLSM(lsm)
	end
end

function GCDM:PlayAuraSoundKit(kit)
	-- Back-compat for older options calls.
	self:PlayAuraSoundChoice("kit:" .. tostring(tonumber(kit) or DefaultKit(self:GetDB())))
end

local function RegisterKitRule(rule, db)
	if not C_UnitAuras then
		return
	end
	local spellID = tonumber(rule.spellID)
	if not spellID or spellID <= 0 then
		return
	end
	local event = rule.event or "apply"
	local whenKey = EVENT_TO_KEY[event]
	if not whenKey then
		return
	end
	local unit = rule.unit or "player"
	if unit ~= "player" and unit ~= "target" and unit ~= "focus" then
		unit = "player"
	end
	local kind, kit = ParseSoundKey(rule.soundKey or rule.soundKitID, db)
	if kind ~= "kit" then
		-- LSM stack/apply handled elsewhere; kit path only here.
		if event == "stack" then
			kit = DefaultKit(db)
		else
			return
		end
	end
	kit = kit or DefaultKit(db)

	local opts = {
		spellID = spellID,
		unitToken = unit,
		soundKitID = kit,
	}
	opts[whenKey] = true

	if C_UnitAuras.AddAuraSound then
		local ok, handle = pcall(C_UnitAuras.AddAuraSound, opts)
		if ok and handle then
			handles[#handles + 1] = handle
			return
		end
		ok, handle = pcall(C_UnitAuras.AddAuraSound, spellID, kit)
		if ok and handle then
			handles[#handles + 1] = handle
		end
	elseif C_UnitAuras.AddAuraAppliedSound and whenKey == "onApply" then
		local ok, handle = pcall(C_UnitAuras.AddAuraAppliedSound, opts)
		if ok and handle then
			handles[#handles + 1] = handle
		end
	end
end

local function UnitHasSpell(unit, spellID)
	if not C_UnitAuras then
		return false
	end
	if unit == "player" and C_UnitAuras.GetPlayerAuraBySpellID then
		local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
		if ok and aura then
			return true
		end
	end
	-- Fallback: scan helpful/harmful (may be limited in combat).
	local filters = { "HELPFUL", "HARMFUL" }
	for fi = 1, #filters do
		if C_UnitAuras.GetUnitAuras then
			local ok, list = pcall(C_UnitAuras.GetUnitAuras, unit, filters[fi])
			if ok and type(list) == "table" then
				for i = 1, #list do
					local aura = list[i]
					local sid = aura and (aura.spellId or aura.spellID)
					if sid == spellID then
						return true
					end
				end
			end
		end
	end
	return false
end

local function EnsureKnown(unit)
	knownAuras[unit] = knownAuras[unit] or {}
	return knownAuras[unit]
end

local function OnUnitAura(unit)
	if not unit then
		return
	end
	local map = EnsureKnown(unit)
	local interested = {}
	for i = 1, #lsmRules do
		local r = lsmRules[i]
		if r.unit == unit then
			interested[r.spellID] = interested[r.spellID] or {}
			interested[r.spellID][#interested[r.spellID] + 1] = r
		end
	end
	for spellID, rules in pairs(interested) do
		local has = UnitHasSpell(unit, spellID)
		local had = map[spellID] and true or false
		if has and not had then
			for j = 1, #rules do
				if rules[j].event == "apply" then
					local _, _, lsm = ParseSoundKey(rules[j].soundKey, GCDM:GetDB())
					PlayLSM(lsm)
				end
			end
		elseif (not has) and had then
			for j = 1, #rules do
				if rules[j].event == "remove" then
					local _, _, lsm = ParseSoundKey(rules[j].soundKey, GCDM:GetDB())
					PlayLSM(lsm)
				end
			end
		end
		map[spellID] = has or nil
	end
end

local ApplyAuraSounds

local function EnsureWatchFrame()
	if watchFrame then
		return
	end
	watchFrame = CreateFrame("Frame")
	watchFrame:SetScript("OnEvent", function(_, event, unit)
		if event == "UNIT_AURA" then
			OnUnitAura(unit)
		elseif event == "PLAYER_TARGET_CHANGED" then
			knownAuras["target"] = {}
			OnUnitAura("target")
			ApplyAuraSounds()
		elseif event == "PLAYER_FOCUS_CHANGED" then
			knownAuras["focus"] = {}
			OnUnitAura("focus")
			ApplyAuraSounds()
		end
	end)
	watchFrame:RegisterUnitEvent("UNIT_AURA", "player", "target", "focus")
	watchFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	watchFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
end

ApplyAuraSounds = function()
	if applying then
		return
	end
	applying = true
	local ok, err = pcall(function()
		ClearHandles()
		wipe(lsmRules)
		local db = GCDM:GetDB()
		if not db or not db.enabled or db.auraSoundEnabled == false then
			return
		end
		local rules = db.auraSoundRules
		if type(rules) ~= "table" then
			return
		end
		EnsureWatchFrame()
		for i = 1, #rules do
			local rule = rules[i]
			local kind = ParseSoundKey(rule.soundKey or rule.soundKitID, db)
			if kind == "lsm" and (rule.event == "apply" or rule.event == "remove") then
				lsmRules[#lsmRules + 1] = rule
			else
				RegisterKitRule(rule, db)
			end
		end
		local seeded = {}
		for i = 1, #lsmRules do
			local u = lsmRules[i].unit or "player"
			if not seeded[u] then
				seeded[u] = true
				OnUnitAura(u)
			end
		end
	end)
	applying = false
	if not ok and not GCDM._auraSoundsErrOnce then
		GCDM._auraSoundsErrOnce = true
		print("|cff3bb273GCDM|r AuraSounds error: " .. tostring(err))
	end
end

function GCDM:AddAuraSoundRule(rule)
	local db = self:GetDB()
	if not db then
		return false
	end
	db.auraSoundRules = db.auraSoundRules or {}
	local spellID = tonumber(rule and rule.spellID)
	if not spellID or spellID <= 0 then
		return false
	end
	local soundKey = rule.soundKey
	if type(soundKey) ~= "string" or soundKey == "" then
		local kit = tonumber(rule.soundKitID) or 0
		soundKey = "kit:" .. (kit > 0 and kit or DefaultKit(db))
	end
	db.auraSoundRules[#db.auraSoundRules + 1] = {
		spellID = spellID,
		unit = rule.unit or "player",
		event = rule.event or "apply",
		soundKey = soundKey,
		soundKitID = tonumber(rule.soundKitID) or 0, -- legacy field
	}
	self:Refresh(self.CONST.REFRESH.STYLE)
	return true
end

function GCDM:RemoveAuraSoundRule(index)
	local db = self:GetDB()
	if not db or type(db.auraSoundRules) ~= "table" then
		return
	end
	index = tonumber(index)
	if not index or index < 1 or index > #db.auraSoundRules then
		return
	end
	table.remove(db.auraSoundRules, index)
	self:Refresh(self.CONST.REFRESH.STYLE)
end

GCDM:RegisterRefreshCallback("Skin.AuraSounds", function()
	ApplyAuraSounds()
end, 50, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})

-- Target/focus token + LSM watch.
GCDM:RegisterRefreshCallback("Skin.AuraSounds.Watch", function()
	EnsureWatchFrame()
end, 51, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})
