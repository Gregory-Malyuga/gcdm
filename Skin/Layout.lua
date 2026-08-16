local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

local relayoutQueued = false
local combatLayoutPending = false
local combatWatcher
local applyingLayout = false

local function InCombat()
	return InCombatLockdown and InCombatLockdown()
end

local function EnsureCombatWatcher()
	if combatWatcher then return end
	combatWatcher = CreateFrame("Frame")
	combatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
	combatWatcher:SetScript("OnEvent", function()
		if combatLayoutPending then
			combatLayoutPending = false
			Skin.QueuePostBlizzardLayout()
		end
	end)
end

function Skin.LayoutMarkCombatPending()
	combatLayoutPending = true
	EnsureCombatWatcher()
end

local function CombatBuffPass()
	Skin.LayoutMarkCombatPending()
	local registry = GCDM.ViewerRegistry
	local buff = registry and registry.Buff and registry:Buff()
	if buff then Skin.LayoutBuffIconsCentered(buff) end
	if Skin.QueueBuffBarRelayout then Skin.QueueBuffBarRelayout() end
end

local function ApplyLayout()
	if Skin.LayoutShouldDefer() then return end
	if InCombat() then CombatBuffPass() return end
	if applyingLayout then return end
	applyingLayout = true
	local ok, err = pcall(function()
		Pixel.Update()
		local db = GCDM:GetDB()
		if not db or not db.enabled then return end
		local registry = GCDM.ViewerRegistry
		local essential = registry:Essential()
		if essential then Skin.LayoutEssential(essential, db) end
		local utility = registry:Utility()
		if utility then Skin.LayoutSimpleRow(utility, db, db.sizeUtility) end
		local buff = registry:Buff()
		if buff then Skin.LayoutBuffIconsCentered(buff) end
		if Skin.QueueBuffBarRelayout then Skin.QueueBuffBarRelayout() end
		if Skin.QueuePowerBarRelayout then Skin.QueuePowerBarRelayout() end
		if Skin.RefreshKeybindTexts then Skin.RefreshKeybindTexts() end
		if Skin.RebuildPressOverlayMap then Skin.RebuildPressOverlayMap() end
	end)
	applyingLayout = false
	if not ok and not GCDM._layoutApplyErrOnce then
		GCDM._layoutApplyErrOnce = true
		print("|cff3bb273GCDM|r Layout error: " .. tostring(err))
	end
end

Skin.QueuePostBlizzardLayout = function()
	if applyingLayout or Skin.LayoutShouldDefer() then return end
	if InCombat() then CombatBuffPass() return end
	if relayoutQueued then return end
	relayoutQueued = true
	C_Timer.After(0, function()
		relayoutQueued = false
		if applyingLayout or Skin.LayoutShouldDefer() then return end
		if InCombat() then CombatBuffPass() return end
		ApplyLayout()
	end)
end

-- Layout used to run from hooks on the viewers' RefreshLayout and
-- OnAcquireItemFrame. Both fire inside Blizzard's refresh, which then continues
-- tainted and errors on its secret cooldown values, so the relayout is queued
-- from CDMWatch on our own event frame instead.
GCDM:RegisterRefreshCallback("Skin.Layout", ApplyLayout, 35, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.LAYOUT,
	GCDM.CONST.REFRESH.STYLE,
})

GCDM.CDMWatch:Register("Skin.Layout", Skin.QueuePostBlizzardLayout, 0.1)
