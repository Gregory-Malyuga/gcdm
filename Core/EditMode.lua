local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

GCDM.isEditModeActive = false

local function SetEditMode(active)
	GCDM.isEditModeActive = active and true or false
	if not active then
		GCDM:Refresh()
		-- Buff icons often only exist / reflow after Edit Mode teardown.
		C_Timer.After(0, function()
			if GCDM and GCDM.Refresh then
				GCDM:Refresh(GCDM.CONST.REFRESH.LAYOUT)
			end
		end)
	end
end

function GCDM:IsEditModeActive()
	if self.isEditModeActive then
		return true
	end
	local em = _G.EditModeManagerFrame
	if em and em.IsEditModeActive and em:IsEditModeActive() then
		return true
	end
	if em and em.IsShown and em:IsShown() then
		return true
	end
	return false
end

local function SetupEditMode()
	if EventRegistry and EventRegistry.RegisterCallback then
		EventRegistry:RegisterCallback("EditMode.Enter", function()
			SetEditMode(true)
		end, GCDM)
		EventRegistry:RegisterCallback("EditMode.Exit", function()
			SetEditMode(false)
		end, GCDM)
	end

	local em = _G.EditModeManagerFrame
	if em then
		if em:IsEditModeActive() then
			SetEditMode(true)
		end
	elseif EventUtil and EventUtil.ContinueOnAddOnLoaded then
		EventUtil.ContinueOnAddOnLoaded("Blizzard_EditMode", function()
			local frame = _G.EditModeManagerFrame
			if frame and frame:IsEditModeActive() then
				SetEditMode(true)
			end
		end)
	end
end

GCDM:RegisterRefreshCallback("EditMode.Setup", function()
	if not GCDM._editModeHooked then
		GCDM._editModeHooked = true
		SetupEditMode()
	end
end, 1, {
	GCDM.CONST.REFRESH.ALL,
})
