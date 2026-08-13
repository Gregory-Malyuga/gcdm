local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

-- Aura sounds (Ayije-like, clean-room):
-- Hook Blizzard CDM buff/bar TriggerAuraAppliedAlert / TriggerAuraRemovedAlert,
-- then PlaySound (SoundKit) or PlaySoundFile (LibSharedMedia).
-- No C_UnitAuras.AddAuraSound — unreliable for many combat auras / stack buffs.

local applying = false
local lastPlay = {} -- [spellID..":"..event] = GetTime()
local THROTTLE = 0.35

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
	-- One dropdown entry per display name (IDs stay internal keys only).
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

-- Spell picker: only cooldowns assigned to the Buff icon row (BuffIconCooldownViewer).
-- Do not dump whole TrackedBuff CategorySet — that lists every trackable class aura.

local function IsInvisibleInfo(info)
	if not info then
		return true
	end
	-- 12.x: Blizzard marks "Not displayed" tracked buffs as invisible.
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

	-- Fallback when the viewer pool is empty: TrackedBuff entries that are not "Not displayed".
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

local function SpellIDsMatch(ruleSpell, frameSpell)
	ruleSpell = tonumber(ruleSpell)
	frameSpell = tonumber(frameSpell)
	if not ruleSpell or not frameSpell then
		return false
	end
	if ruleSpell == frameSpell then
		return true
	end
	if Skin.SpellLookupIDs then
		local a = Skin.SpellLookupIDs(ruleSpell)
		for i = 1, #a do
			if a[i] == frameSpell then
				return true
			end
		end
		local b = Skin.SpellLookupIDs(frameSpell)
		for i = 1, #b do
			if b[i] == ruleSpell then
				return true
			end
		end
	end
	return false
end

local function CanPlayNow()
	if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
		return false
	end
	return true
end

local function ThrottleOk(spellID, event)
	local key = tostring(spellID) .. ":" .. tostring(event)
	local now = GetTime and GetTime() or 0
	local prev = lastPlay[key] or 0
	if now - prev < THROTTLE then
		return false
	end
	lastPlay[key] = now
	return true
end

local function PlayRulesForSpell(spellID, event)
	if not spellID or not CanPlayNow() then
		return
	end
	local db = GCDM:GetDB()
	if not db or not db.enabled or db.auraSoundEnabled == false then
		return
	end
	local rules = db.auraSoundRules
	if type(rules) ~= "table" then
		return
	end
	-- CDM buff alerts are always the player's aura show/hide.
	if not ThrottleOk(spellID, event) then
		return
	end
	for i = 1, #rules do
		local rule = rules[i]
		if rule and (rule.event or "apply") == event then
			local unit = rule.unit or "player"
			if unit == "player" and SpellIDsMatch(rule.spellID, spellID) then
				local kind, kit, lsm = ParseSoundKey(rule.soundKey or rule.soundKitID, db)
				if kind == "kit" then
					PlayKit(kit or DefaultKit(db))
				else
					PlayLSM(lsm)
				end
			end
		end
	end
end

local function OnAuraApplied(frame)
	local spellID = Skin.GetFrameSpellID and Skin.GetFrameSpellID(frame)
	PlayRulesForSpell(spellID, "apply")
end

local function OnAuraRemoved(frame)
	local spellID = Skin.GetFrameSpellID and Skin.GetFrameSpellID(frame)
	PlayRulesForSpell(spellID, "remove")
end

local function HookAuraFrame(frame)
	if not frame or frame.GCDMAuraSoundHooked then
		return
	end
	frame.GCDMAuraSoundHooked = true
	if frame.TriggerAuraAppliedAlert then
		hooksecurefunc(frame, "TriggerAuraAppliedAlert", function(f)
			OnAuraApplied(f)
		end)
	end
	if frame.TriggerAuraRemovedAlert then
		hooksecurefunc(frame, "TriggerAuraRemovedAlert", function(f)
			OnAuraRemoved(f)
		end)
	end
	-- Buff bars / some templates expose applications refresh for stack ticks.
	if frame.RefreshApplications then
		hooksecurefunc(frame, "RefreshApplications", function(f)
			if f and f:IsShown() then
				PlayRulesForSpell(Skin.GetFrameSpellID and Skin.GetFrameSpellID(f), "stack")
			end
		end)
	end
end

local function HookViewerPool(viewer)
	if not viewer then
		return
	end
	local registry = GCDM.ViewerRegistry
	if registry and registry.HookOnce then
		registry:HookOnce(viewer, "GCDMAuraSoundAcquireHooked", "OnAcquireItemFrame", function(_, itemFrame)
			HookAuraFrame(itemFrame)
		end)
	elseif viewer.OnAcquireItemFrame and not viewer.GCDMAuraSoundAcquireHooked then
		viewer.GCDMAuraSoundAcquireHooked = true
		hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, itemFrame)
			HookAuraFrame(itemFrame)
		end)
	end
	if Skin.CollectIconFrames then
		local icons = Skin.CollectIconFrames(viewer)
		for i = 1, #icons do
			HookAuraFrame(icons[i])
		end
	end
	if Skin.CollectBarFrames then
		local bars = Skin.CollectBarFrames(viewer)
		for i = 1, #bars do
			HookAuraFrame(bars[i])
		end
	end
end

local function ApplyAuraSounds()
	if applying then
		return
	end
	applying = true
	local ok, err = pcall(function()
		local db = GCDM:GetDB()
		if not db or not db.enabled or db.auraSoundEnabled == false then
			return
		end
		local registry = GCDM.ViewerRegistry
		if not registry then
			return
		end
		if registry.Buff then
			HookViewerPool(registry:Buff())
		end
		if registry.BuffBar then
			HookViewerPool(registry:BuffBar())
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
		soundKitID = tonumber(rule.soundKitID) or 0,
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
