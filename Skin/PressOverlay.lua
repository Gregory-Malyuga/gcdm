local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local COOLDOWN_VIEWERS = GCDM.CONST.COOLDOWN_VIEWER_NAMES
local PO = Skin._PressOverlayState

local function IsComboDown(combo)
	if not combo then
		return false, "nil_combo"
	end
	if not IsKeyDown then
		return false, "no_IsKeyDown"
	end
	local wantShift = combo.shift and true or false
	local wantCtrl = combo.ctrl and true or false
	local wantAlt = combo.alt and true or false
	local haveShift = IsShiftKeyDown and IsShiftKeyDown() or false
	local haveCtrl = IsControlKeyDown and IsControlKeyDown() or false
	local haveAlt = IsAltKeyDown and IsAltKeyDown() or false
	if wantShift ~= haveShift or wantCtrl ~= haveCtrl or wantAlt ~= haveAlt then
		return false, "mod_mismatch"
	end
	local ok, down = pcall(IsKeyDown, combo.key)
	if not ok then
		return false, "IsKeyDown_err:" .. tostring(down)
	end
	if down then
		return true, "down"
	end
	return false, "up"
end

local function SyncOverlaysFromKeys()
	PO.syncTicks = PO.syncTicks + 1
	if not Skin.PressOverlayIsEnabled() then
		Skin.PressOverlayHideAll()
		return
	end
	if GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() then
		if PO.syncTicks % 40 == 1 then
			Skin.PressOverlayLog("skip: keyboard focus active")
		end
		Skin.PressOverlayHideAll()
		return
	end

	Skin.PressOverlayEnsureMap()

	local pressedFrames = {}
	local downSpells = {}
	local firstFail
	for spellID, combos in pairs(PO.spellCombos) do
		local down = false
		for i = 1, #combos do
			local okDown, reason = IsComboDown(combos[i])
			if okDown then
				down = true
				break
			elseif not firstFail and reason and reason ~= "up" and reason ~= "mod_mismatch" then
				firstFail = string.format("sid=%s raw=%s reason=%s", tostring(spellID), tostring(combos[i].raw), tostring(reason))
			end
		end
		if down then
			downSpells[#downSpells + 1] = spellID
			local frames = PO.spellFrames[spellID]
			if frames then
				for j = 1, #frames do
					pressedFrames[frames[j]] = true
				end
			end
		end
	end

	local pressedCount = Skin.PressOverlayCountKeys(pressedFrames)
	local sig = table.concat(downSpells, ",")
	if sig ~= PO.lastPressedSig then
		PO.lastPressedSig = sig
		if sig ~= "" then
			Skin.PressOverlayLog(string.format("PRESSED spells=[%s] frames=%d", sig, pressedCount))
		else
			Skin.PressOverlayLog("released all")
		end
	elseif PO.syncTicks % 60 == 0 then
		Skin.PressOverlayLog(string.format(
			"poll ok ticks=%d combos=%d pressed=%d pollShown=%s",
			PO.syncTicks,
			Skin.PressOverlayCountKeys(PO.spellCombos),
			pressedCount,
			tostring(PO.pollFrame:IsShown())
		))
		if firstFail then
			Skin.PressOverlayLog("  sample IsKeyDown fail: " .. firstFail)
		end
	end

	local registry = GCDM.ViewerRegistry
	if registry then
		for i = 1, #COOLDOWN_VIEWERS do
			local icons = Skin.CollectIconFrames(registry:Get(COOLDOWN_VIEWERS[i]))
			for j = 1, #icons do
				local frame = icons[j]
				if pressedFrames[frame] then
					Skin.PressOverlayShow(frame)
				else
					Skin.PressOverlayHide(frame)
				end
			end
		end
	end
end

PO.pollFrame:SetScript("OnUpdate", function(_, dt)
	PO.pollElapsed = PO.pollElapsed + dt
	if PO.pollElapsed < Skin.PressOverlayPollInterval() then
		return
	end
	PO.pollElapsed = 0
	SyncOverlaysFromKeys()
end)

local function StartPoll()
	Skin.PressOverlayInstallHooks()
	Skin.RebuildPressOverlayMap()
	PO.pollElapsed = Skin.PressOverlayPollInterval()
	PO.pollFrame:Show()
	Skin.PressOverlayLog(string.format("poll STARTED shown=%s", tostring(PO.pollFrame:IsShown())))
end

local function StopPoll()
	PO.pollFrame:Hide()
	Skin.PressOverlayHideAll()
	Skin.PressOverlayLog("poll STOPPED")
end

local function ApplyPressOverlay()
	local db = GCDM:GetDB()
	Skin.PressOverlayLog(string.format(
		"Apply enabled=%s press=%s debug=%s",
		tostring(db and db.enabled),
		tostring(db and db.pressOverlayEnabled ~= false),
		tostring(db and db.pressOverlayDebug == true)
	))
	if Skin.PressOverlayIsEnabled() then
		StartPoll()
	else
		StopPoll()
	end
end

function Skin.DumpPressOverlayDebug()
	local db = GCDM:GetDB()
	if db then
		db.pressOverlayDebug = true
	end
	PO.mapCacheVer = -1
	Skin.PressOverlayEnsureMap()
	Skin.PressOverlayLog(string.format("manual dump pollShown=%s ticks=%d", tostring(PO.pollFrame:IsShown()), PO.syncTicks))
	for spellID, combos in pairs(PO.spellCombos) do
		for i = 1, #combos do
			local down, reason = IsComboDown(combos[i])
			Skin.PressOverlayLog(string.format("probe sid=%s raw=%s down=%s reason=%s", tostring(spellID), tostring(combos[i].raw), tostring(down), tostring(reason)))
		end
		break
	end
end

GCDM:RegisterRefreshCallback("Skin.PressOverlay", ApplyPressOverlay, 56, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})
