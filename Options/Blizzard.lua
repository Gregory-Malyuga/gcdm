local ADDON_NAME, ns = ...
local L = ns.L

function ns.OpenBlizzardEditMode()
	if InCombatLockdown and InCombatLockdown() then
		print("|cff3bb273GCDM|r: " .. L["MSG_EDITMODE_COMBAT"])
		return
	end
	local function show()
		local em = _G.EditModeManagerFrame
		if not em then
			return false
		end
		if em.EnterEditMode then
			pcall(function()
				em:EnterEditMode()
			end)
		end
		if ShowUIPanel then
			ShowUIPanel(em)
		elseif em.Show then
			em:Show()
		end
		return (em.IsShown and em:IsShown()) or (em.IsEditModeActive and em:IsEditModeActive())
	end
	if show() then
		return
	end
	if C_AddOns and C_AddOns.LoadAddOn then
		pcall(C_AddOns.LoadAddOn, "Blizzard_EditMode")
	elseif LoadAddOn then
		pcall(LoadAddOn, "Blizzard_EditMode")
	end
	show()
end

local VALID_CDM_DISPLAY_MODES = {
	spells = true,
	auras = true,
}

local function ApplyCooldownViewerDisplayMode(panel, displayMode)
	if not panel or not VALID_CDM_DISPLAY_MODES[displayMode] or type(panel.SetDisplayMode) ~= "function" then
		return
	end
	pcall(panel.SetDisplayMode, panel, displayMode)
end

function ns.OpenBlizzardCooldownViewerSettings(displayMode)
	if InCombatLockdown and InCombatLockdown() then
		print("|cff3bb273GCDM|r: " .. L["MSG_CDM_COMBAT"])
		return
	end
	local function show()
		local panel = _G.CooldownViewerSettings
		if not panel then
			return false
		end
		if ShowUIPanel then
			ShowUIPanel(panel)
		elseif panel.Show then
			panel:Show()
		end
		ApplyCooldownViewerDisplayMode(panel, displayMode)
		return panel.IsShown and panel:IsShown()
	end
	if show() then
		return
	end
	if C_AddOns and C_AddOns.LoadAddOn then
		pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
	elseif LoadAddOn then
		pcall(LoadAddOn, "Blizzard_CooldownViewer")
	end
	if not show() then
		ns.OpenBlizzardEditMode()
		print("|cff3bb273GCDM|r: " .. L["MSG_CDM_FALLBACK"])
	end
end

function ns.BuildBlizzardContentEditorArgs(displayMode, orderBase)
	orderBase = orderBase or 900
	return {
		contentEditorHeader = {
			type = "header",
			name = L["PANEL_CONTENT"],
			order = orderBase,
		},
		contentEditorHint = {
			type = "description",
			name = L["PANEL_CONTENT_DESC"],
			order = orderBase + 1,
			fontSize = "medium",
		},
		contentEditorOpen = {
			type = "execute",
			name = L["PANEL_CONTENT_OPEN"],
			desc = L["PANEL_CONTENT_DESC"],
			order = orderBase + 2,
			width = "full",
			func = function()
				ns.OpenBlizzardCooldownViewerSettings(displayMode)
			end,
		},
	}
end

function ns.BuildBlizzardArgs()
	return {
		hint = {
			type = "description",
			name = L["BLIZZARD_DESC"],
			order = 1,
			fontSize = "medium",
		},
		openEditMode = {
			type = "execute",
			name = L["BLIZZARD_EDIT_MODE"],
			desc = L["BLIZZARD_EDIT_MODE_DESC"],
			order = 2,
			width = "full",
			func = ns.OpenBlizzardEditMode,
		},
		openCooldownViewer = {
			type = "execute",
			name = L["BLIZZARD_CDM_SETTINGS"],
			desc = L["BLIZZARD_CDM_SETTINGS_DESC"],
			order = 3,
			width = "full",
			func = function()
				ns.OpenBlizzardCooldownViewerSettings()
			end,
		},
	}
end
