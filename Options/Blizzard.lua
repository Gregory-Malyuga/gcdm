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
	}
end
