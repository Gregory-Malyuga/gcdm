local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

-- Read/write bridge to the contents of Blizzard's Cooldown Manager panels.
-- Blizzard keeps the panel contents (which cooldown sits in which category,
-- in which order, and what is hidden) in a serialized per-character layout.
-- The only sane way in is Blizzard's own data provider: it validates category
-- moves, keeps the in-memory layout in sync and notifies the live viewers.

GCDM.CDMContent = GCDM.CDMContent or {}
local Content = GCDM.CDMContent

local VIEWERS = GCDM.CONST.VIEWERS

local function EnumCategory(name, fallback)
	local e = Enum and Enum.CooldownViewerCategory
	local value = e and e[name]
	if type(value) == "number" then
		return value
	end
	return fallback
end

--- Blizzard adds the hidden pseudo-categories from Lua, so read them lazily.
function Content:Categories()
	return {
		essential = EnumCategory("Essential", 0),
		utility = EnumCategory("Utility", 1),
		buff = EnumCategory("TrackedBuff", 2),
		buffBar = EnumCategory("TrackedBar", 3),
		hiddenActive = EnumCategory("HiddenActive", -1),
		hiddenPassive = EnumCategory("HiddenPassive", -2),
	}
end

local VIEWER_TO_KEY = {
	[VIEWERS.ESSENTIAL] = "essential",
	[VIEWERS.UTILITY] = "utility",
	[VIEWERS.BUFF] = "buff",
	[VIEWERS.BUFF_BAR] = "buffBar",
}

-- Blizzard only allows moves inside a family: active spells and passive auras
-- never mix (see legalOriginalSourceCategoryToTargetCategory in its settings).
local SIBLING_KEY = {
	essential = "utility",
	utility = "essential",
	buff = "buffBar",
	buffBar = "buff",
}

function Content:KeyForViewer(viewerName)
	return VIEWER_TO_KEY[viewerName]
end

function Content:SiblingKey(key)
	return SIBLING_KEY[key]
end

function Content:CategoryForKey(key)
	local categories = self:Categories()
	return categories[key]
end

function Content:HiddenCategoryForKey(key)
	local categories = self:Categories()
	if key == "buff" or key == "buffBar" then
		return categories.hiddenPassive
	end
	return categories.hiddenActive
end

local function Settings()
	return _G.CooldownViewerSettings
end

function Content:GetProvider()
	local settings = Settings()
	if not settings or not settings.GetDataProvider then
		return nil
	end
	local ok, provider = pcall(settings.GetDataProvider, settings)
	if not ok then
		return nil
	end
	return provider
end

function Content:GetLayoutManager()
	local provider = self:GetProvider()
	if provider and provider.GetLayoutManager then
		local ok, manager = pcall(provider.GetLayoutManager, provider)
		if ok and manager then
			return manager
		end
	end
	local settings = Settings()
	if not settings or not settings.GetLayoutManager then
		return nil
	end
	local ok, manager = pcall(settings.GetLayoutManager, settings)
	if not ok or not manager then
		return nil
	end
	if manager.IsLoaded and not manager:IsLoaded() then
		return nil
	end
	return manager
end

function Content:IsAvailable()
	local provider = self:GetProvider()
	if not provider or not provider.GetOrderedCooldownIDs then
		return false
	end
	local ok, ids = pcall(provider.GetOrderedCooldownIDs, provider)
	return ok and type(ids) == "table"
end

local function PlainNumber(value)
	if type(value) ~= "number" then
		return nil
	end
	if issecretvalue and issecretvalue(value) then
		return nil
	end
	if canaccessvalue and not canaccessvalue(value) then
		return nil
	end
	return value
end

local function SpellDisplay(info)
	local spellID = PlainNumber(info and (info.overrideSpellID or info.spellID))
	if not spellID then
		return nil, nil
	end
	local name, icon
	if C_Spell and C_Spell.GetSpellName then
		local ok, value = pcall(C_Spell.GetSpellName, spellID)
		if ok then
			name = value
		end
	end
	if C_Spell and C_Spell.GetSpellTexture then
		local ok, value = pcall(C_Spell.GetSpellTexture, spellID)
		if ok then
			icon = PlainNumber(value) or value
		end
	end
	return name, icon
end

--- Entries of one category in panel order.
--- Each entry keeps its index in Blizzard's global order, which is what the
--- reorder API works on.
function Content:GetEntries(category)
	local entries = {}
	local provider = self:GetProvider()
	if not provider or type(category) ~= "number" then
		return entries
	end
	local ok, ids = pcall(provider.GetOrderedCooldownIDs, provider)
	if not ok or type(ids) ~= "table" then
		return entries
	end
	for index = 1, #ids do
		local cooldownID = ids[index]
		local okInfo, info = pcall(provider.GetCooldownInfoForID, provider, cooldownID)
		if okInfo and type(info) == "table" and info.category == category then
			local name, icon = SpellDisplay(info)
			entries[#entries + 1] = {
				cooldownID = cooldownID,
				orderIndex = index,
				name = name or ("#" .. tostring(cooldownID)),
				icon = icon,
				isKnown = info.isKnown ~= false,
			}
		end
	end
	return entries
end

function Content:FindEntry(entries, cooldownID)
	for i = 1, #entries do
		if entries[i].cooldownID == cooldownID then
			return entries[i], i
		end
	end
	return nil, nil
end

local function StatusFailed(status)
	local success = Enum and Enum.CooldownLayoutStatus and Enum.CooldownLayoutStatus.Success
	if status == nil or success == nil then
		return false
	end
	return status ~= success
end

function Content:Save()
	local settings = Settings()
	-- Same path Blizzard's CDM settings UI uses after a reorder / category move.
	if settings and type(settings.CheckSaveCurrentLayout) == "function" then
		local ok = pcall(settings.CheckSaveCurrentLayout, settings)
		if ok then
			return
		end
	end
	if settings and type(settings.SaveCurrentLayout) == "function" then
		local ok = pcall(settings.SaveCurrentLayout, settings)
		if ok then
			return
		end
	end
	local manager = self:GetLayoutManager()
	if manager and manager.SaveLayouts then
		pcall(manager.SaveLayouts, manager)
	end
end

--- Blizzard's settings panel refuses layout edits in combat; so do we.
function Content:CanEdit()
	if InCombatLockdown and InCombatLockdown() then
		return false, "combat"
	end
	if not self:IsAvailable() then
		return false, "unavailable"
	end
	return true
end

--- Move an entry one slot up (delta -1) or down (delta 1) inside its category.
function Content:MoveEntry(category, cooldownID, delta)
	local canEdit, reason = self:CanEdit()
	if not canEdit then
		return false, reason
	end
	local provider = self:GetProvider()
	local entries = self:GetEntries(category)
	local _, position = self:FindEntry(entries, cooldownID)
	if not position then
		return false, "missing"
	end
	local neighbour = entries[position + delta]
	if not neighbour then
		return false, "edge"
	end

	-- Insert before when moving up, after when moving down.
	local offset = delta < 0 and 0 or 1
	local ok, status = pcall(
		provider.ChangeOrderIndex,
		provider,
		entries[position].orderIndex,
		neighbour.orderIndex,
		offset
	)
	if not ok or StatusFailed(status) then
		return false, "rejected"
	end
	self:Save()
	return true
end

--- Move an entry to another category: sibling panel or hidden.
function Content:SetEntryCategory(cooldownID, category)
	local canEdit, reason = self:CanEdit()
	if not canEdit then
		return false, reason
	end
	local provider = self:GetProvider()
	local ok, status = pcall(provider.SetCooldownToCategory, provider, cooldownID, category)
	if not ok or StatusFailed(status) then
		return false, "rejected"
	end
	self:Save()
	return true
end
