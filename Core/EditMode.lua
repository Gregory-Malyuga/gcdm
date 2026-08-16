-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

GCDM.isEditModeActive = false

local function Const()
	return GCDM.CONST or {}
end

local function DebugEditEnabled()
	local db = GCDM.GetDB and GCDM:GetDB()
	return db and (db.debugEditMode or db.debugSkin)
end

local function EditLog(msg)
	if not DebugEditEnabled() then
		return
	end
	print("|cff3bb273GCDM|r [edit] " .. tostring(msg))
end

local function IsEditModeUIOpen()
	local em = _G.EditModeManagerFrame
	if not em then
		return false
	end
	if em.IsEditModeActive then
		local ok, active = pcall(em.IsEditModeActive, em)
		if ok and active then
			return true
		end
	end
	if em.IsShown then
		local ok, shown = pcall(em.IsShown, em)
		if ok and shown then
			return true
		end
	end
	return false
end

GCDM._IsEditModeUIOpen = IsEditModeUIOpen

local function ClearViewerPositionSnaps()
	local Skin = GCDM.Skin
	local registry = GCDM.ViewerRegistry
	if not registry then
		return
	end
	local names = Const().ALL_VIEWER_NAMES or Const().MANAGED_VIEWER_NAMES or {}
	for i = 1, #names do
		local viewer = registry:Get(names[i])
		if viewer then
			viewer.GCDMViewerAnchor = nil
			viewer.GCDMViewerAnchor2 = nil
			local icons = Skin and Skin.CollectIconFrames and Skin.CollectIconFrames(viewer)
			if icons then
				for j = 1, #icons do
					local frame = icons[j]
					if frame then
						frame.GCDMApplyingAnchor = false
					end
				end
			end
		end
	end
end

local function ApplyLayoutIfEditing()
	if not GCDM.isEditModeActive then
		return
	end
	if GCDM.LayoutApply then
		GCDM.LayoutApply.RefreshManagedLayout()
	end
end

local function ScheduleEditModeEnterPasses()
	local immediate = Const().LAYOUT_REAPPLY_IMMEDIATE or 0
	local delayed = Const().LAYOUT_REAPPLY_DELAY or 0.15
	C_Timer.After(immediate, function()
		if not GCDM.isEditModeActive then
			return
		end
		ClearViewerPositionSnaps()
		ApplyLayoutIfEditing()
	end)
	C_Timer.After(delayed, function()
		if not GCDM.isEditModeActive then
			return
		end
		ApplyLayoutIfEditing()
		if DebugEditEnabled() and GCDM.DumpEditModeDebug then
			pcall(function()
				GCDM:DumpEditModeDebug(true)
			end)
		end
	end)
end

local function ScheduleEditModeExitPasses()
	local immediate = Const().LAYOUT_REAPPLY_IMMEDIATE or 0
	C_Timer.After(immediate, function()
		if GCDM.isEditModeActive then
			return
		end
		if GCDM.Refresh then
			GCDM:Refresh()
			GCDM:Refresh(Const().REFRESH.LAYOUT)
		end
		if DebugEditEnabled() and GCDM.DumpEditModeDebug then
			C_Timer.After(immediate, function()
				if not GCDM.isEditModeActive then
					pcall(function()
						GCDM:DumpEditModeDebug(true)
					end)
				end
			end)
		end
	end)
end

local function SetEditMode(active)
	local was = GCDM.isEditModeActive
	GCDM.isEditModeActive = active and true or false
	GCDM.editModeSuppressPowerBar = false
	EditLog(string.format("SetEditMode %s → %s", tostring(was), tostring(GCDM.isEditModeActive)))
	if active then
		ClearViewerPositionSnaps()
		ScheduleEditModeEnterPasses()
	elseif was then
		ScheduleEditModeExitPasses()
	end
end

GCDM._SetEditMode = SetEditMode

function GCDM:IsEditModeActive()
	if self.isEditModeActive then
		return true
	end
	return IsEditModeUIOpen()
end

function GCDM:IsCooldownViewerSettingsOpen()
	local panel = _G.CooldownViewerSettings
	if panel and panel.IsShown and panel:IsShown() then
		return true
	end
	return false
end

function GCDM:ShouldDeferCDMLayout()
	return self.isEditModeActive or IsEditModeUIOpen()
end

function GCDM:ShouldDeferIconLayout()
	return false
end

GCDM:RegisterRefreshCallback("EditMode.Setup", function()
	if not GCDM._editModeHooked then
		GCDM._editModeHooked = true
		GCDM._SetupEditModeHooks()
	end
end, 1, {
	GCDM.CONST.REFRESH.ALL,
})
