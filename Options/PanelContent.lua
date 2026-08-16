local ADDON_NAME, ns = ...
local L = ns.L

local TARGETS = {
	essential = { category = "Essential", hidden = "HiddenActive", mode = "spells" },
	utility = { category = "Utility", hidden = "HiddenActive", mode = "spells" },
	buff = { category = "TrackedBuff", hidden = "HiddenPassive", mode = "auras" },
	buffBar = { category = "TrackedBar", hidden = "HiddenPassive", mode = "auras" },
}

local MODE_CATEGORIES = {
	spells = {
		Essential = true,
		Utility = true,
		HiddenActive = true,
		EquipSlotEssential = true,
		SpecAgnosticEssential = true,
	},
	auras = {
		TrackedBuff = true,
		TrackedBar = true,
		HiddenPassive = true,
		EquipSlotTracked = true,
		SpecAgnosticTracked = true,
	},
}

local selectedCooldown = {}

local function GetCategoryValue(name)
	local categories = Enum and Enum.CooldownViewerCategory
	return categories and categories[name]
end

local function LoadCooldownViewer()
	if _G.CooldownViewerSettings then
		return _G.CooldownViewerSettings
	end
	if C_AddOns and C_AddOns.LoadAddOn then
		pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
	elseif LoadAddOn then
		pcall(LoadAddOn, "Blizzard_CooldownViewer")
	end
	return _G.CooldownViewerSettings
end

local function GetEditorObjects()
	local panel = LoadCooldownViewer()
	if not panel or type(panel.GetDataProvider) ~= "function" then
		return nil
	end
	local okProvider, provider = pcall(panel.GetDataProvider, panel)
	if not okProvider or not provider or type(provider.GetLayoutManager) ~= "function" then
		return nil
	end
	local okManager, manager = pcall(provider.GetLayoutManager, provider)
	if not okManager or not manager then
		return nil
	end
	return panel, provider, manager
end

local function GetDisplaySpellID(info)
	return info and (info.overrideTooltipSpellID or info.overrideSpellID or info.spellID)
end

local function GetCooldownLabel(info)
	local spellID = GetDisplaySpellID(info)
	local spellInfo = spellID and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
	local name = spellInfo and spellInfo.name or (spellID and ("Spell " .. tostring(spellID))) or ("Cooldown " .. tostring(info.cooldownID))
	local iconID = spellInfo and spellInfo.iconID
	if iconID then
		return string.format("|T%d:18:18:0:0|t %s", iconID, name)
	end
	return name
end

local function IsInfoInMode(provider, info, mode)
	local modeNames = MODE_CATEGORIES[mode]
	if not modeNames or not info then
		return false
	end
	local defaults = provider.GetCooldownDefaults and provider:GetCooldownDefaults(info.cooldownID)
	local category = defaults and defaults.category or info.category
	local categories = Enum and Enum.CooldownViewerCategory
	if not categories then
		return false
	end
	for name in pairs(modeNames) do
		if category == categories[name] then
			return true
		end
	end
	return false
end

local function GetEntries(targetKey, targetOnly)
	local target = TARGETS[targetKey]
	local _, provider = GetEditorObjects()
	if not target or not provider then
		return {}, nil
	end
	local category = GetCategoryValue(target.category)
	local entries = {}
	local ok, cooldownIDs = pcall(provider.GetOrderedCooldownIDs, provider)
	if not ok or type(cooldownIDs) ~= "table" then
		return entries, provider
	end
	for _, cooldownID in ipairs(cooldownIDs) do
		local okInfo, info = pcall(provider.GetCooldownInfoForID, provider, cooldownID)
		if okInfo and info and info.isKnown and IsInfoInMode(provider, info, target.mode) then
			if not targetOnly or info.category == category then
				entries[#entries + 1] = {
					id = cooldownID,
					info = info,
					label = GetCooldownLabel(info),
				}
			end
		end
	end
	return entries, provider
end

local function BuildValues(targetKey, targetOnly, numbered, orderedKeys)
	local entries = GetEntries(targetKey, targetOnly)
	local values = {}
	for index, entry in ipairs(entries) do
		local key = orderedKeys and string.format("%06d:%d", index, entry.id) or entry.id
		values[key] = numbered and string.format("%02d. %s", index, entry.label) or entry.label
	end
	return values
end

local function GetCooldownIDFromOptionKey(key)
	if type(key) == "number" then
		return key
	end
	return tonumber(type(key) == "string" and key:match(":(%d+)$") or nil)
end

local function GetSelected(targetKey)
	local entries = GetEntries(targetKey, true)
	local selected = selectedCooldown[targetKey]
	for _, entry in ipairs(entries) do
		if entry.id == selected then
			return selected
		end
	end
	selected = entries[1] and entries[1].id or nil
	selectedCooldown[targetKey] = selected
	return selected
end

local function NotifyOptions()
	local registry = LibStub("AceConfigRegistry-3.0", true)
	if registry then
		registry:NotifyChange(ADDON_NAME)
	end
end

local function SaveAndRefresh(panel)
	if panel and type(panel.SaveCurrentLayout) == "function" then
		local ok, err = pcall(panel.SaveCurrentLayout, panel)
		if not ok then
			print("|cff3bb273GCDM|r: " .. string.format(L["PANEL_CONTENT_SAVE_ERROR"], tostring(err)))
			return false
		end
	end
	local addon = ns.GCDM
	if addon and addon.Refresh then
		addon:Refresh(addon.CONST.REFRESH.LAYOUT)
	end
	return true
end

local function ReportStatus(status)
	local success = Enum and Enum.CooldownLayoutStatus and Enum.CooldownLayoutStatus.Success
	if status == nil or status == success then
		return true
	end
	print("|cff3bb273GCDM|r: " .. string.format(L["PANEL_CONTENT_ERROR"], tostring(status)))
	return false
end

local function SetTracked(targetKey, cooldownID, enabled)
	if InCombatLockdown and InCombatLockdown() then
		print("|cff3bb273GCDM|r: " .. L["PANEL_CONTENT_COMBAT"])
		return
	end
	local target = TARGETS[targetKey]
	local panel, provider = GetEditorObjects()
	if not target or not provider then
		print("|cff3bb273GCDM|r: " .. L["PANEL_CONTENT_UNAVAILABLE"])
		return
	end
	local category = GetCategoryValue(enabled and target.category or target.hidden)
	if category == nil then
		return
	end
	local ok, status = pcall(provider.SetCooldownToCategory, provider, cooldownID, category)
	if not ok or not ReportStatus(status) then
		return
	end
	selectedCooldown[targetKey] = cooldownID
	SaveAndRefresh(panel)
end

local function IsTracked(targetKey, cooldownID)
	local target = TARGETS[targetKey]
	local _, provider = GetEditorObjects()
	if not target or not provider then
		return false
	end
	local ok, info = pcall(provider.GetCooldownInfoForID, provider, cooldownID)
	return ok and info and info.category == GetCategoryValue(target.category) or false
end

local function GetSelectedPosition(targetKey)
	local selected = GetSelected(targetKey)
	local entries = GetEntries(targetKey, true)
	for index, entry in ipairs(entries) do
		if entry.id == selected then
			return index, entries
		end
	end
	return nil, entries
end

local function MoveSelected(targetKey, direction)
	if InCombatLockdown and InCombatLockdown() then
		print("|cff3bb273GCDM|r: " .. L["PANEL_CONTENT_COMBAT"])
		return
	end
	local position, entries = GetSelectedPosition(targetKey)
	local destination = position and entries[position + direction]
	if not position or not destination then
		return
	end
	local panel, provider = GetEditorObjects()
	if not provider then
		return
	end
	local okIDs, allIDs = pcall(provider.GetOrderedCooldownIDs, provider)
	if not okIDs or type(allIDs) ~= "table" then
		return
	end
	local sourceIndex
	local destinationIndex
	for index, cooldownID in ipairs(allIDs) do
		if cooldownID == entries[position].id then
			sourceIndex = index
		elseif cooldownID == destination.id then
			destinationIndex = index
		end
	end
	if not sourceIndex or not destinationIndex then
		return
	end
	local reorderOffset = direction > 0 and 1 or 0
	local ok, status = pcall(provider.ChangeOrderIndex, provider, sourceIndex, destinationIndex, reorderOffset)
	if not ok or not ReportStatus(status) then
		return
	end
	SaveAndRefresh(panel)
end

local function IsEditorDisabled()
	return (InCombatLockdown and InCombatLockdown()) or GetEditorObjects() == nil
end

function ns.BuildPanelContentArgs(targetKey, orderBase)
	orderBase = orderBase or 900
	return {
		panelContent = {
			type = "group",
			name = L["PANEL_CONTENT"],
			order = orderBase,
			inline = true,
			args = {
				hint = {
					type = "description",
					name = L["PANEL_CONTENT_DESC"],
					order = 1,
					fontSize = "medium",
				},
				items = {
					type = "multiselect",
					name = L["PANEL_CONTENT_ITEMS"],
					desc = L["PANEL_CONTENT_ITEMS_DESC"],
					order = 2,
					width = "full",
					disabled = IsEditorDisabled,
					values = function()
						return BuildValues(targetKey, false, false, true)
					end,
					get = function(_, optionKey)
						return IsTracked(targetKey, GetCooldownIDFromOptionKey(optionKey))
					end,
					set = function(_, optionKey, enabled)
						SetTracked(targetKey, GetCooldownIDFromOptionKey(optionKey), enabled)
					end,
				},
				orderHeader = {
					type = "header",
					name = L["PANEL_CONTENT_ORDER"],
					order = 10,
				},
				selected = {
					type = "select",
					name = L["PANEL_CONTENT_SELECTED"],
					order = 11,
					width = "full",
					disabled = IsEditorDisabled,
					values = function()
						return BuildValues(targetKey, true, true)
					end,
					sorting = function()
						local entries = GetEntries(targetKey, true)
						local sorting = {}
						for _, entry in ipairs(entries) do
							sorting[#sorting + 1] = entry.id
						end
						return sorting
					end,
					get = function()
						return GetSelected(targetKey)
					end,
					set = function(_, cooldownID)
						selectedCooldown[targetKey] = cooldownID
					end,
				},
				moveUp = {
					type = "execute",
					name = L["PANEL_CONTENT_MOVE_UP"],
					order = 12,
					width = 0.75,
					disabled = function()
						local position = GetSelectedPosition(targetKey)
						return IsEditorDisabled() or not position or position <= 1
					end,
					func = function()
						MoveSelected(targetKey, -1)
					end,
				},
				moveDown = {
					type = "execute",
					name = L["PANEL_CONTENT_MOVE_DOWN"],
					order = 13,
					width = 0.75,
					disabled = function()
						local position, entries = GetSelectedPosition(targetKey)
						return IsEditorDisabled() or not position or position >= #entries
					end,
					func = function()
						MoveSelected(targetKey, 1)
					end,
				},
			},
		},
	}
end

local function QueueEditorReadyRefresh()
	C_Timer.After(0, NotifyOptions)
	C_Timer.After(0.25, NotifyOptions)
end

if EventRegistry and EventRegistry.RegisterFrameEventAndCallback then
	EventRegistry:RegisterFrameEventAndCallback("COOLDOWN_VIEWER_DATA_LOADED", QueueEditorReadyRefresh, ns)
end
if EventUtil and EventUtil.ContinueOnAddOnLoaded then
	EventUtil.ContinueOnAddOnLoaded("Blizzard_CooldownViewer", QueueEditorReadyRefresh)
end
