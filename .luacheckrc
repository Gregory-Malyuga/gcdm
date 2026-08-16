-- Static check for the WoW addon environment: luacheck Core Skin Options DB Locales Init.lua
-- Catches undefined names (a nil global call only shows up in game otherwise).
std = "lua51"
max_line_length = false
self = false

-- Unused arguments and loop variables are idiomatic in event/callback code, and
-- every file starts with the standard `local ADDON_NAME, ns = ...` header.
unused_args = false
ignore = { "211/ns", "211/ADDON_NAME" }

exclude_files = { "Libs/**" }

globals = {
	"GCDM",
	"GCDMDB",
	"GCDMBuffBarDumpFrame",
	"SLASH_GCDM1",
}

read_globals = {
	-- Addon libraries
	"LibStub",

	-- Secret values / taint helpers
	"issecretvalue",
	"canaccessvalue",
	"secretunwrap",
	"issecure",
	"securecall",
	"securecallfunction",
	"secureexecuterange",
	"hooksecurefunc",

	-- Core API namespaces
	"C_ActionBar",
	"C_AddOns",
	"C_CooldownViewer",
	"C_CurveUtil",
	"C_EncodingUtil",
	"C_EventUtils",
	"C_Spell",
	"C_Timer",
	"C_UnitAuras",
	"Enum",
	"EventRegistry",
	"EventUtil",

	-- Widgets and frames
	"ActionButtonDown",
	"ActionButtonUp",
	"MultiActionButtonDown",
	"MultiActionButtonUp",
	"CreateFrame",
	"CreateFont",
	"CreateColor",
	"GameFontHighlightSmall",
	"GetPhysicalScreenSize",
	"CooldownViewerSettings",
	"DEFAULT_CHAT_FRAME",
	"EditModeManagerFrame",
	"NineSliceUtil",
	"UIParent",
	"UIErrorsFrame",
	"ShowUIPanel",
	"HideUIPanel",
	"LoadAddOn",
	"GetCurrentKeyBoardFocus",

	-- CDM mixins
	"BuffBarCooldownViewerMixin",
	"CooldownViewerBuffBarItemMixin",
	"CooldownViewerBuffIconItemMixin",
	"CooldownViewerCooldownItemMixin",
	"CooldownViewerItemMixin",

	-- Game state
	"GetActionBarPage",
	"GetActionInfo",
	"GetBindingKey",
	"GetFileIDFromPath",
	"GetLocale",
	"GetMacroSpell",
	"GetOverrideBarIndex",
	"GetTempShapeshiftBarIndex",
	"GetTime",
	"GetVehicleBarIndex",
	"HasOverrideActionBar",
	"HasTempShapeshiftActionBar",
	"HasVehicleActionBar",
	"InCombatLockdown",
	"IsAltKeyDown",
	"IsControlKeyDown",
	"IsKeyDown",
	"IsShiftKeyDown",
	"FindBaseSpellByID",
	"FindSpellOverrideByID",
	"PowerBarColor",
	"UnitClass",
	"UnitIsDeadOrGhost",
	"UnitPower",
	"UnitPowerMax",
	"UnitPowerPercent",
	"UnitPowerType",

	-- Sound
	"PlaySound",
	"PlaySoundFile",
	"SOUNDKIT",

	-- Lua-side helpers Blizzard adds
	"CopyTable",
	"strtrim",
	"time",
	"wipe",
}
