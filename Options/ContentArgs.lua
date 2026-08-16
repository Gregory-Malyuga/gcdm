local ADDON_NAME, ns = ...

-- Panel contents editor: what sits inside Essential / Utility / buff icons /
-- buff bars, in which order, and what is hidden. Drives Blizzard's own
-- Cooldown Manager data provider, so its rules and live refresh still apply.

local selection = {}

local function Content(addon)
	return addon.CDMContent
end

local function EntryValues(entries)
	local values = {}
	for i = 1, #entries do
		local entry = entries[i]
		values[entry.cooldownID] = i .. ". " .. entry.name
	end
	return values
end

local function SelectedID(key, entries)
	local current = selection[key]
	if current then
		for i = 1, #entries do
			if entries[i].cooldownID == current then
				return current
			end
		end
	end
	return entries[1] and entries[1].cooldownID or nil
end

local function NotifyOptions()
	local registry = LibStub("AceConfigRegistry-3.0", true)
	if registry then
		registry:NotifyChange(ADDON_NAME)
	end
end

local function Report(addon, L, reason)
	if reason == "combat" then
		addon:Print(L["MSG_CONTENT_COMBAT"])
	elseif reason == "unavailable" then
		addon:Print(L["MSG_CONTENT_UNAVAILABLE"])
	elseif reason ~= "edge" then
		addon:Print(L["MSG_CONTENT_REJECTED"])
	end
end

--- key is one of essential / utility / buff / buffBar.
function ns.BuildPanelContentArgs(ctx, key, orderBase)
	orderBase = orderBase or 200
	local addon = ctx.addon
	local L = ctx.L

	local function entries()
		return Content(addon):GetEntries(Content(addon):CategoryForKey(key))
	end

	local function hiddenEntries()
		return Content(addon):GetEntries(Content(addon):HiddenCategoryForKey(key))
	end

	local function siblingName()
		local sibling = Content(addon):SiblingKey(key)
		return L["BLOCK_" .. string.upper(sibling == "buffBar" and "buff_bar" or sibling)] or sibling
	end

	local function act(ok, reason)
		if not ok then
			Report(addon, L, reason)
		end
		NotifyOptions()
	end

	return {
		contentHeader = {
			type = "header",
			name = L["CONTENT"],
			order = orderBase,
		},
		contentHint = {
			type = "description",
			name = L["CONTENT_DESC"],
			order = orderBase + 1,
			fontSize = "medium",
		},
		contentList = {
			type = "description",
			order = orderBase + 2,
			fontSize = "medium",
			name = function()
				if not Content(addon):IsAvailable() then
					return L["CONTENT_UNAVAILABLE"]
				end
				local list = entries()
				if #list == 0 then
					return L["CONTENT_EMPTY"]
				end
				local lines = {}
				for i = 1, #list do
					local entry = list[i]
					local icon = entry.icon and ("|T" .. entry.icon .. ":16:16:0:0|t ") or ""
					local name = entry.isKnown and entry.name or ("|cff808080" .. entry.name .. "|r")
					lines[#lines + 1] = i .. ". " .. icon .. name
				end
				return table.concat(lines, "\n")
			end,
		},
		contentEntry = {
			type = "select",
			name = L["CONTENT_ENTRY"],
			order = orderBase + 3,
			width = "double",
			values = function()
				return EntryValues(entries())
			end,
			get = function()
				return SelectedID(key, entries())
			end,
			set = function(_, value)
				selection[key] = value
			end,
		},
		contentUp = {
			type = "execute",
			name = L["CONTENT_MOVE_UP"],
			order = orderBase + 4,
			func = function()
				local list = entries()
				local id = SelectedID(key, list)
				if not id then
					return
				end
				act(Content(addon):MoveEntry(Content(addon):CategoryForKey(key), id, -1))
			end,
		},
		contentDown = {
			type = "execute",
			name = L["CONTENT_MOVE_DOWN"],
			order = orderBase + 5,
			func = function()
				local list = entries()
				local id = SelectedID(key, list)
				if not id then
					return
				end
				act(Content(addon):MoveEntry(Content(addon):CategoryForKey(key), id, 1))
			end,
		},
		contentHide = {
			type = "execute",
			name = L["CONTENT_HIDE"],
			desc = L["CONTENT_HIDE_DESC"],
			order = orderBase + 6,
			func = function()
				local id = SelectedID(key, entries())
				if not id then
					return
				end
				act(Content(addon):SetEntryCategory(id, Content(addon):HiddenCategoryForKey(key)))
			end,
		},
		contentMove = {
			type = "execute",
			name = function()
				return string.format(L["CONTENT_MOVE_TO"], siblingName())
			end,
			desc = L["CONTENT_MOVE_TO_DESC"],
			order = orderBase + 7,
			func = function()
				local id = SelectedID(key, entries())
				if not id then
					return
				end
				local sibling = Content(addon):SiblingKey(key)
				act(Content(addon):SetEntryCategory(id, Content(addon):CategoryForKey(sibling)))
			end,
		},
		contentHiddenHeader = {
			type = "header",
			name = L["CONTENT_HIDDEN"],
			order = orderBase + 10,
		},
		contentHiddenEntry = {
			type = "select",
			name = L["CONTENT_HIDDEN_ENTRY"],
			desc = L["CONTENT_HIDDEN_ENTRY_DESC"],
			order = orderBase + 11,
			width = "double",
			values = function()
				return EntryValues(hiddenEntries())
			end,
			get = function()
				return SelectedID(key .. "Hidden", hiddenEntries())
			end,
			set = function(_, value)
				selection[key .. "Hidden"] = value
			end,
		},
		contentRestore = {
			type = "execute",
			name = L["CONTENT_RESTORE"],
			order = orderBase + 12,
			func = function()
				local id = SelectedID(key .. "Hidden", hiddenEntries())
				if not id then
					return
				end
				act(Content(addon):SetEntryCategory(id, Content(addon):CategoryForKey(key)))
			end,
		},
	}
end
