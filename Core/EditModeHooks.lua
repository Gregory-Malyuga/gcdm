-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

-- Edit Mode and the Cooldown Manager settings panel are watched through
-- EventRegistry, never through HookScript. Blizzard runs EnterEditMode and
-- ExitEditMode from those frames' own OnShow/OnHide, so a script hook there
-- taints the whole teardown: HideSystemSelections then walks every registered
-- system frame tainted, and unit frames, the damage meter and encounter
-- warnings start erroring on their secret values. EventRegistry callbacks are
-- dispatched through securecallfunction, so they stay out of that stack.

local function Const()
	return GCDM.CONST or {}
end

local function ScheduleLayout(delays)
	if GCDM.LayoutApply then
		GCDM.LayoutApply.Schedule(delays)
	end
end

local function OnSettingsShown()
	local C = Const()
	ScheduleLayout({
		C.LAYOUT_REAPPLY_IMMEDIATE or 0,
		C.LAYOUT_REAPPLY_DELAY or 0.15,
	})
end

local function OnSettingsHidden()
	ScheduleLayout({ Const().LAYOUT_REAPPLY_IMMEDIATE or 0 })
end

function GCDM._SetupEditModeHooks()
	if not EventRegistry or not EventRegistry.RegisterCallback then
		return
	end

	EventRegistry:RegisterCallback("EditMode.Enter", function()
		GCDM._SetEditMode(true)
	end, GCDM)
	EventRegistry:RegisterCallback("EditMode.Exit", function()
		GCDM._SetEditMode(false)
	end, GCDM)

	EventRegistry:RegisterCallback("CooldownViewerSettings.OnShow", OnSettingsShown, GCDM)
	EventRegistry:RegisterCallback("CooldownViewerSettings.OnHide", OnSettingsHidden, GCDM)

	-- Edit Mode may already be open when we load.
	if GCDM._IsEditModeUIOpen and GCDM._IsEditModeUIOpen() then
		GCDM._SetEditMode(true)
	end
end
