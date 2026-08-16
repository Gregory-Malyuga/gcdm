local ADDON_NAME, ns = ...
local L = ns.L

function ns.SetupOptions(addon)
	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	local ctx = ns.MakeOptionsCtx(addon)

	local options = {
		type = "group",
		name = L["ADDON_NAME"],
		args = {
			general = {
				type = "group",
				name = L["GENERAL"],
				order = 1,
				args = ns.BuildGeneralArgs(ctx),
			},
			skin = {
				type = "group",
				name = L["SKIN"],
				order = 2,
				childGroups = "tab",
				args = ns.BuildSkinArgs(ctx),
			},
			profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db),
		},
	}

	ns.AssembleBlockTabs(addon, options, ctx)

	-- Last line of defense: AceConfig select.options require values.
	local fallbackOutline = {
		NONE = "None",
		OUTLINE = "Outline",
		THICKOUTLINE = "Thick",
		MONOCHROME = "Monochrome",
	}
	local function FixSelectValues(node)
		if type(node) ~= "table" then
			return
		end
		if node.type == "select" or node.type == "multiselect" then
			local vt = type(node.values)
			if vt ~= "table" and vt ~= "function" and vt ~= "string" then
				node.values = fallbackOutline
			end
		end
		if type(node.args) == "table" then
			for _, child in pairs(node.args) do
				FixSelectValues(child)
			end
		end
	end
	FixSelectValues(options)

	AceConfig:RegisterOptionsTable(ADDON_NAME, options)
	AceConfigDialog:SetDefaultSize(ADDON_NAME, 900, 640)
	AceConfigDialog:AddToBlizOptions(ADDON_NAME, L["ADDON_NAME"])

	local status = AceConfigDialog:GetStatusTable(ADDON_NAME)
	status.width = status.width or 900
	status.height = status.height or 640
end
