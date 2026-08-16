-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local function Const()
	return GCDM.CONST or {}
end

local function HookCooldownViewerSettings()
	local panel = _G.CooldownViewerSettings
	if not panel or panel.GCDMLayoutHooked then
		return
	end
	panel.GCDMLayoutHooked = true
	if not panel.HookScript then
		return
	end
	local C = Const()
	local delays = {
		C.LAYOUT_REAPPLY_IMMEDIATE or 0,
		C.LAYOUT_REAPPLY_DELAY or 0.15,
	}
	panel:HookScript("OnShow", function()
		if GCDM.LayoutApply then
			GCDM.LayoutApply.Schedule(delays)
		end
	end)
	panel:HookScript("OnHide", function()
		if GCDM.LayoutApply then
			GCDM.LayoutApply.Schedule({ C.LAYOUT_REAPPLY_IMMEDIATE or 0 })
		end
	end)
end

local function HookEditModeManager()
	local em = _G.EditModeManagerFrame
	if not em or em.GCDMEditModeHooked then
		return
	end
	em.GCDMEditModeHooked = true
	if em.HookScript then
		em:HookScript("OnShow", function()
			if GCDM._SetEditMode then
				GCDM._SetEditMode(true)
			end
		end)
		em:HookScript("OnHide", function()
			if GCDM._SetEditMode then
				GCDM._SetEditMode(false)
			end
		end)
	end
	if GCDM._IsEditModeUIOpen and GCDM._IsEditModeUIOpen() then
		GCDM._SetEditMode(true)
	end
end

function GCDM._SetupEditModeHooks()
	if EventRegistry and EventRegistry.RegisterCallback then
		EventRegistry:RegisterCallback("EditMode.Enter", function()
			GCDM._SetEditMode(true)
		end, GCDM)
		EventRegistry:RegisterCallback("EditMode.Exit", function()
			GCDM._SetEditMode(false)
		end, GCDM)
	end
	HookEditModeManager()
	if EventUtil and EventUtil.ContinueOnAddOnLoaded then
		EventUtil.ContinueOnAddOnLoaded("Blizzard_EditMode", HookEditModeManager)
	end
	HookCooldownViewerSettings()
	if EventUtil and EventUtil.ContinueOnAddOnLoaded then
		EventUtil.ContinueOnAddOnLoaded("Blizzard_CooldownViewer", HookCooldownViewerSettings)
		EventUtil.ContinueOnAddOnLoaded("Blizzard_CooldownViewerSettings", HookCooldownViewerSettings)
	end
end
