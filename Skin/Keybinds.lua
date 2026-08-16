local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local eventsActive = false
local invalidatePending = false
local delayedToken = 0

local eventFrame = CreateFrame("Frame")
local debounceFrame = CreateFrame("Frame")
debounceFrame:Hide()

local BAR_CHANGE = {
	UPDATE_BONUS_ACTIONBAR = true,
	ACTIONBAR_PAGE_CHANGED = true,
	UPDATE_OVERRIDE_ACTIONBAR = true,
	UPDATE_VEHICLE_ACTIONBAR = true,
}

--- Spell ids coming off CDM frames can be secret; carrying one into keybinds or
--- sound rules would spread that into everything comparing it.
local function PlainSpellID(value)
	if type(value) ~= "number" then
		return nil
	end
	if issecretvalue and issecretvalue(value) then
		return nil
	end
	if canaccessvalue and not canaccessvalue(value) then
		return nil
	end
	return value
end

function Skin.GetFrameSpellID(frame)
	if not frame then
		return nil
	end
	local direct = PlainSpellID(frame.spellID)
	if direct then
		return direct
	end
	local info = frame.cooldownInfo
	local fromInfo = info and PlainSpellID(info.spellID)
	if fromInfo then
		return fromInfo
	end
	local cdID = PlainSpellID(frame.cooldownID)
	if cdID and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo then
		local ok, data = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
		if ok and data then
			return PlainSpellID(data.spellID)
		end
	end
	return nil
end

local function WantKeybindEvents()
	local db = GCDM:GetDB()
	if not db or not db.enabled then
		return false
	end
	return db.keybindTextEnabled ~= false or db.pressOverlayEnabled ~= false
end

local function NotifyConsumers()
	if Skin.RefreshKeybindTexts then
		Skin.RefreshKeybindTexts()
	end
	if Skin.RebuildPressOverlayMap then
		Skin.RebuildPressOverlayMap()
	end
end

local function DoInvalidate()
	invalidatePending = false
	Skin.InvalidateKeybinds()
	NotifyConsumers()
end

debounceFrame:SetScript("OnUpdate", function(self)
	self:Hide()
	DoInvalidate()
end)

local function DebouncedInvalidate()
	if invalidatePending then
		return
	end
	invalidatePending = true
	debounceFrame:Show()
end

local function OnEvent(_, event)
	DebouncedInvalidate()
	if BAR_CHANGE[event] then
		delayedToken = delayedToken + 1
		local token = delayedToken
		C_Timer.After(0.1, function()
			if token == delayedToken then
				DebouncedInvalidate()
			end
		end)
	end
end

local function EnableEvents()
	if eventsActive then
		return
	end
	eventsActive = true
	eventFrame:RegisterEvent("UPDATE_BINDINGS")
	eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
	eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
	eventFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
	eventFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
	eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	eventFrame:SetScript("OnEvent", OnEvent)
end

local function DisableEvents()
	if not eventsActive then
		return
	end
	eventsActive = false
	eventFrame:UnregisterAllEvents()
	eventFrame:SetScript("OnEvent", nil)
end

function Skin.SyncKeybindEvents()
	if WantKeybindEvents() then
		EnableEvents()
		DebouncedInvalidate()
	else
		DisableEvents()
		Skin.InvalidateKeybinds()
		NotifyConsumers()
	end
end

GCDM:RegisterRefreshCallback("Skin.Keybinds", function()
	Skin.SyncKeybindEvents()
end, 52, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})
