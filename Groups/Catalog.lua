local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local Catalog = {}
GCDM.CustomCatalog = Catalog

local TARGET_MODE = {
	essential = "abilities",
	utility = "abilities",
	buff = "auras",
	buffBar = "auras",
}

local CATEGORIES = Enum and Enum.CooldownViewerCategory or {}
local CATEGORY_TARGET = {
	[CATEGORIES.Essential or 0] = "essential",
	[CATEGORIES.Utility or 1] = "utility",
	[CATEGORIES.TrackedBuff or 2] = "buff",
	[CATEGORIES.TrackedBar or 3] = "buffBar",
	[CATEGORIES.GroupBuff or 4] = "buff",
	[CATEGORIES.SpecAgnosticEssential or 5] = "essential",
	[CATEGORIES.SpecAgnosticTracked or 6] = "buff",
}
local SUPPORTED_CATEGORIES = {
	CATEGORIES.Essential or 0,
	CATEGORIES.Utility or 1,
	CATEGORIES.TrackedBuff or 2,
	CATEGORIES.TrackedBar or 3,
	CATEGORIES.GroupBuff or 4,
	CATEGORIES.SpecAgnosticEssential or 5,
	CATEGORIES.SpecAgnosticTracked or 6,
}

local entriesByID = {}
local orderedIDs = {}
local catalogPending = false
local catalogReady = false

local function IsAccessible(value)
	return not canaccessvalue or canaccessvalue(value)
end

local function AddCatalogEntry(cooldownID, targetEntries, targetOrder)
	if type(cooldownID) ~= "number" then return false end
	if targetEntries[cooldownID] then return true end
	if not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCooldownInfo then return false end
	local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cooldownID)
	if not ok or type(info) ~= "table" then return false end
	if info.isKnown == false or info.isInvisible == true then return true end
	if info.equipSlot or info.spellCategoryID then return true end
	local trackingSpellID = info.overrideSpellID or info.spellID
	local tooltipSpellID = info.overrideTooltipSpellID or trackingSpellID
	if type(trackingSpellID) ~= "number" or not IsAccessible(trackingSpellID) then return false end
	local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(tooltipSpellID)
	local category = info.category
	local target = CATEGORY_TARGET[category]
	local mode = (target == "buff" or target == "buffBar") and "auras" or "abilities"
	local entry = {
		cooldownID = cooldownID,
		spellID = trackingSpellID,
		tooltipSpellID = tooltipSpellID,
		linkedSpellIDs = CopyTable(info.linkedSpellIDs or {}),
		hasCharges = info.charges and true or false,
		mode = mode,
		name = spellInfo and spellInfo.name or ("Spell " .. tostring(tooltipSpellID)),
		iconID = spellInfo and spellInfo.iconID or 134400,
		defaultCategory = info.category,
	}
	targetEntries[cooldownID] = entry
	targetOrder[#targetOrder + 1] = cooldownID
	return true
end

local function ReadStaticCatalog()
	if InCombatLockdown and InCombatLockdown() then return end
	if not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCategorySet then
		catalogReady = false
		return
	end
	local nextEntries = {}
	local nextOrder = {}
	local allSucceeded = true
	for _, category in ipairs(SUPPORTED_CATEGORIES) do
		local ok, ids = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, category, true)
		if ok and type(ids) == "table" then
			for _, cooldownID in ipairs(ids) do
				if IsAccessible(cooldownID) and not AddCatalogEntry(cooldownID, nextEntries, nextOrder) then
					allSucceeded = false
				end
			end
		else
			allSucceeded = false
		end
	end
	if not allSucceeded or #nextOrder == 0 then
		catalogPending = true
		catalogReady = false
		return
	end
	table.sort(nextOrder, function(a, b)
		local ea, eb = nextEntries[a], nextEntries[b]
		if ea.mode ~= eb.mode then return ea.mode < eb.mode end
		if ea.name ~= eb.name then return ea.name < eb.name end
		return a < b
	end)
	entriesByID = nextEntries
	orderedIDs = nextOrder
	catalogReady = true
end

local function CopyNativeViewerOrder(viewer, collector)
	local ids = {}
	local frames = viewer and collector and collector(viewer) or {}
	table.sort(frames, function(a, b)
		local ai = type(a.layoutIndex) == "number" and a.layoutIndex or 0
		local bi = type(b.layoutIndex) == "number" and b.layoutIndex or 0
		return ai < bi
	end)
	for _, frame in ipairs(frames) do
		local cooldownID = frame and frame.cooldownID
		if type(cooldownID) == "number" and entriesByID[cooldownID] then
			ids[#ids + 1] = cooldownID
		end
	end
	return ids
end

local function SeedGroupsFromNative()
	local db = GCDM:GetDB()
	if not db or db.customGroupsSeeded then return end
	db.customGroups = db.customGroups or {}
	db.customGroupSeeded = db.customGroupSeeded or {}
	local registry = GCDM.ViewerRegistry
	if #orderedIDs == 0 then return end
	local sources = registry and {
		essential = { registry:Essential(), Skin.CollectIconFrames },
		utility = { registry:Utility(), Skin.CollectIconFrames },
		buff = { registry:Buff(), Skin.CollectIconFrames },
		buffBar = { registry:BuffBar(), Skin.CollectBarFrames },
	} or {}
	for _, key in ipairs({ "essential", "utility", "buff", "buffBar" }) do
		if not db.customGroupSeeded[key] then
			local source = sources[key]
			local ids = source and CopyNativeViewerOrder(source[1], source[2]) or {}
			if #ids == 0 then
				for _, cooldownID in ipairs(orderedIDs) do
					local entry = entriesByID[cooldownID]
					if entry and CATEGORY_TARGET[entry.defaultCategory] == key then
						ids[#ids + 1] = cooldownID
					end
				end
			end
			db.customGroups[key] = ids
			db.customGroupSeeded[key] = true
		end
	end
	db.customGroupsSeeded = db.customGroupSeeded.essential
		and db.customGroupSeeded.utility
		and db.customGroupSeeded.buff
		and db.customGroupSeeded.buffBar
		and true or false
end

local function GroupList(key)
	local db = GCDM:GetDB()
	if not db then return {} end
	db.customGroups = db.customGroups or {}
	db.customGroups[key] = db.customGroups[key] or {}
	return db.customGroups[key]
end

local function NotifyChanged()
	GCDM:Refresh(GCDM.CONST.REFRESH.GROUPS)
	local registry = LibStub("AceConfigRegistry-3.0", true)
	if registry then registry:NotifyChange(ADDON_NAME) end
end

function Catalog:Refresh()
	ReadStaticCatalog()
	SeedGroupsFromNative()
end

function Catalog:GetEntry(cooldownID)
	return entriesByID[cooldownID]
end

function Catalog:IsReady()
	return catalogReady
end

function Catalog:GetGroup(key)
	return GroupList(key)
end

function Catalog:GetActiveEntries(key)
	local out = {}
	for _, cooldownID in ipairs(GroupList(key)) do
		local entry = entriesByID[cooldownID]
		if entry then out[#out + 1] = entry end
	end
	return out
end

function Catalog:GetInactiveEntries(key)
	local out = {}
	local active = {}
	for _, cooldownID in ipairs(GroupList(key)) do active[cooldownID] = true end
	local mode = TARGET_MODE[key]
	for _, cooldownID in ipairs(orderedIDs) do
		local entry = entriesByID[cooldownID]
		if entry and entry.mode == mode and not active[cooldownID] then
			out[#out + 1] = entry
		end
	end
	return out
end

function Catalog:Assign(key, cooldownID, insertIndex)
	if InCombatLockdown and InCombatLockdown() then return false, "combat" end
	local entry = entriesByID[cooldownID]
	local mode = TARGET_MODE[key]
	if not entry or entry.mode ~= mode then return false, "invalid" end
	for groupKey, groupMode in pairs(TARGET_MODE) do
		if groupMode == mode then
			local list = GroupList(groupKey)
			for i = #list, 1, -1 do
				if list[i] == cooldownID then table.remove(list, i) end
			end
		end
	end
	local list = GroupList(key)
	insertIndex = math.max(1, math.min(tonumber(insertIndex) or (#list + 1), #list + 1))
	table.insert(list, insertIndex, cooldownID)
	NotifyChanged()
	return true
end

function Catalog:Remove(key, cooldownID)
	if InCombatLockdown and InCombatLockdown() then return false, "combat" end
	local list = GroupList(key)
	for i = #list, 1, -1 do
		if list[i] == cooldownID then
			table.remove(list, i)
			NotifyChanged()
			return true
		end
	end
	return false, "missing"
end

function Catalog:Move(key, cooldownID, insertIndex)
	if InCombatLockdown and InCombatLockdown() then return false, "combat" end
	local list = GroupList(key)
	local oldIndex
	for i, id in ipairs(list) do
		if id == cooldownID then oldIndex = i break end
	end
	if not oldIndex then return self:Assign(key, cooldownID, insertIndex) end
	table.remove(list, oldIndex)
	if oldIndex < insertIndex then insertIndex = insertIndex - 1 end
	insertIndex = math.max(1, math.min(insertIndex, #list + 1))
	table.insert(list, insertIndex, cooldownID)
	NotifyChanged()
	return true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("COOLDOWN_VIEWER_DATA_LOADED") then
	eventFrame:RegisterEvent("COOLDOWN_VIEWER_DATA_LOADED")
end
for _, event in ipairs({ "COOLDOWN_VIEWER_TABLE_HOTFIXED", "COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED" }) do
	if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid(event) then
		eventFrame:RegisterEvent(event)
	end
end
eventFrame:SetScript("OnEvent", function(_, event)
	if InCombatLockdown and InCombatLockdown() then
		catalogPending = true
		return
	end
	if event == "PLAYER_REGEN_ENABLED" and not catalogPending then return end
	catalogPending = false
	C_Timer.After(0, function()
		if InCombatLockdown and InCombatLockdown() then
			catalogPending = true
			return
		end
		Catalog:Refresh()
		GCDM:Refresh(GCDM.CONST.REFRESH.GROUPS)
	end)
end)

GCDM:RegisterRefreshCallback("Groups.Catalog", function()
	if #orderedIDs == 0 and not (InCombatLockdown and InCombatLockdown()) then
		Catalog:Refresh()
	end
end, 15, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.GROUPS,
})
