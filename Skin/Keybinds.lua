local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

-- Action-bar keybind lookup for Essential/Utility CDM icons (clean-room).

local textCache = {}
local rawCache = {}
local cacheVersion = 0
local cachedMainBarPage = nil
local eventsActive = false
local invalidatePending = false

local eventFrame = CreateFrame("Frame")
local debounceFrame = CreateFrame("Frame")
debounceFrame:Hide()

local PAGE_TO_BINDING = {
	[2] = "ELVUIBAR2BUTTON",
	[3] = "MULTIACTIONBAR3BUTTON",
	[4] = "MULTIACTIONBAR4BUTTON",
	[5] = "MULTIACTIONBAR2BUTTON",
	[6] = "MULTIACTIONBAR1BUTTON",
	[7] = "ELVUIBAR7BUTTON",
	[8] = "ELVUIBAR8BUTTON",
	[9] = "ELVUIBAR9BUTTON",
	[10] = "ELVUIBAR10BUTTON",
	[13] = "MULTIACTIONBAR5BUTTON",
	[14] = "MULTIACTIONBAR6BUTTON",
	[15] = "MULTIACTIONBAR7BUTTON",
}

local MAIN_BAR_PROBE = {
	"ElvUI_Bar1Button1",
	"NDui_ActionBar1Button1",
	"BT4Button1",
	"DominosActionButton1",
	"ActionButton1",
}

local MOD_ABBREV = {
	SHIFT = "S",
	CTRL = "C",
	ALT = "A",
	META = "M",
}

local KEY_ABBREV = {
	MOUSEWHEELUP = "MwU",
	MOUSEWHEELDOWN = "MwD",
	BUTTON1 = "M1",
	BUTTON2 = "M2",
	BUTTON3 = "M3",
	BUTTON4 = "M4",
	BUTTON5 = "M5",
	NUMPADMULTIPLY = "N*",
	NUMPADDIVIDE = "N/",
	NUMPADPLUS = "N+",
	NUMPADMINUS = "N-",
	NUMPADDECIMAL = "NDEL",
	NUMPADENTER = "NEnt",
	NUMPAD0 = "N0",
	NUMPAD1 = "N1",
	NUMPAD2 = "N2",
	NUMPAD3 = "N3",
	NUMPAD4 = "N4",
	NUMPAD5 = "N5",
	NUMPAD6 = "N6",
	NUMPAD7 = "N7",
	NUMPAD8 = "N8",
	NUMPAD9 = "N9",
	CAPSLOCK = "CpLk",
	BACKSPACE = "BkSp",
	DELETE = "DEL",
	INSERT = "Ins",
	PAGEUP = "PU",
	PAGEDOWN = "PD",
	ENTER = "Ent",
	HOME = "Hm",
	SPACE = "SPC",
	END = "End",
	UP = "Up",
	DOWN = "Dn",
	LEFT = "Lt",
	RIGHT = "Rt",
	TAB = "Tab",
	ESCAPE = "Esc",
}

local function DetectMainBarPage()
	if HasVehicleActionBar and HasVehicleActionBar() and GetVehicleBarIndex then
		return GetVehicleBarIndex()
	end
	if HasOverrideActionBar and HasOverrideActionBar() and GetOverrideBarIndex then
		return GetOverrideBarIndex()
	end
	if HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() and GetTempShapeshiftBarIndex then
		return GetTempShapeshiftBarIndex()
	end
	for i = 1, #MAIN_BAR_PROBE do
		local btn = _G[MAIN_BAR_PROBE[i]]
		if btn and btn.GetAttribute then
			local action = btn:GetAttribute("action")
			if type(action) == "number" and action > 0 then
				return math.ceil(action / 12)
			end
			local page = btn:GetAttribute("actionpage")
			if type(page) == "number" and page > 0 then
				return page
			end
		end
	end
	if C_ActionBar and C_ActionBar.HasBonusActionBar and C_ActionBar.HasBonusActionBar() and GetActionBarPage and GetActionBarPage() == 1 then
		if C_ActionBar.GetBonusBarIndex then
			return C_ActionBar.GetBonusBarIndex()
		end
	end
	return (GetActionBarPage and GetActionBarPage()) or 1
end

local function GetMainBarPage()
	if not cachedMainBarPage then
		cachedMainBarPage = DetectMainBarPage()
	end
	return cachedMainBarPage
end

local function GetBindingCommandForSlot(slot)
	if type(slot) ~= "number" or slot < 1 then
		return nil
	end
	local page = math.ceil(slot / 12)
	local buttonID = ((slot - 1) % 12) + 1
	local mainPage = GetMainBarPage()
	if page == mainPage then
		return "ACTIONBUTTON" .. buttonID
	end
	if page == 1 and mainPage ~= 1 then
		return nil
	end
	local prefix = PAGE_TO_BINDING[page]
	if not prefix then
		return nil
	end
	return prefix .. buttonID
end

local function FormatRawKey(key)
	if type(key) ~= "string" or key == "" then
		return nil
	end
	local modPrefix = ""
	local remaining = key
	while true do
		local hyphen = remaining:find("-", 1, true)
		if not hyphen then
			break
		end
		local token = remaining:sub(1, hyphen - 1)
		local abbrev = MOD_ABBREV[token]
		if not abbrev then
			break
		end
		modPrefix = modPrefix .. abbrev
		remaining = remaining:sub(hyphen + 1)
	end
	local baseAbbrev = KEY_ABBREV[remaining]
	if not baseAbbrev then
		local n = remaining:match("^BUTTON(%d+)$")
		baseAbbrev = n and ("M" .. n) or remaining
	end
	return modPrefix .. baseAbbrev
end

local function BindingKeys(command)
	if not command or not GetBindingKey then
		return {}
	end
	return { GetBindingKey(command) }
end

local function ShortestTextForSlot(slot)
	local command = GetBindingCommandForSlot(slot)
	if not command then
		return nil
	end
	local shortest
	local keys = BindingKeys(command)
	for i = 1, #keys do
		local key = keys[i]
		if key then
			local text = FormatRawKey(key)
			if text and (not shortest or #text < #shortest) then
				shortest = text
			end
		end
	end
	return shortest
end

local function CollectRawKeysForSlot(slot, out)
	local command = GetBindingCommandForSlot(slot)
	if not command then
		return
	end
	local keys = BindingKeys(command)
	for i = 1, #keys do
		local key = keys[i]
		if key and not key:find("MOUSEWHEEL", 1, true) then
			out[#out + 1] = key
		end
	end
end

local function FindSlotsForSpell(spellID)
	if not spellID then
		return nil
	end
	if C_ActionBar and C_ActionBar.FindSpellActionButtons then
		local ok, slots = pcall(C_ActionBar.FindSpellActionButtons, spellID)
		if ok and type(slots) == "table" and #slots > 0 then
			return slots
		end
	end
	-- Fallback: scan visible action slots (FindSpellActionButtons is often empty for overrides).
	if not GetActionInfo then
		return nil
	end
	local out
	for slot = 1, 180 do
		local actionType, id = GetActionInfo(slot)
		if actionType == "spell" and id == spellID then
			out = out or {}
			out[#out + 1] = slot
		elseif actionType == "macro" and type(id) == "number" and GetMacroSpell then
			local ok, sid = pcall(GetMacroSpell, id)
			if ok and sid == spellID then
				out = out or {}
				out[#out + 1] = slot
			end
		end
	end
	return out
end

function Skin.SpellLookupIDs(spellID)
	local ids = {}
	local seen = {}
	local function add(id)
		id = tonumber(id)
		if id and id > 0 and not seen[id] then
			seen[id] = true
			ids[#ids + 1] = id
		end
	end
	add(spellID)
	if C_Spell and C_Spell.GetBaseSpell then
		local ok, base = pcall(C_Spell.GetBaseSpell, spellID)
		if ok then
			add(base)
		end
	end
	if FindBaseSpellByID then
		local ok, base = pcall(FindBaseSpellByID, spellID)
		if ok then
			add(base)
		end
	end
	if FindSpellOverrideByID then
		local ok, ov = pcall(FindSpellOverrideByID, spellID)
		if ok then
			add(ov)
		end
	end
	return ids
end

local function SpellLookupIDs(spellID)
	return Skin.SpellLookupIDs(spellID)
end

local function ComputeShortestText(spellID)
	local shortest
	local ids = SpellLookupIDs(spellID)
	for i = 1, #ids do
		local slots = FindSlotsForSpell(ids[i])
		if slots then
			for j = 1, #slots do
				local text = ShortestTextForSlot(slots[j])
				if text and (not shortest or #text < #shortest) then
					shortest = text
				end
			end
		end
	end
	return shortest
end

local function ComputeRawKeys(spellID)
	local out = {}
	local seen = {}
	local ids = SpellLookupIDs(spellID)
	for i = 1, #ids do
		local slots = FindSlotsForSpell(ids[i])
		if slots then
			for j = 1, #slots do
				local bucket = {}
				CollectRawKeysForSlot(slots[j], bucket)
				for k = 1, #bucket do
					local key = bucket[k]
					if not seen[key] then
						seen[key] = true
						out[#out + 1] = key
					end
				end
			end
		end
	end
	if #out == 0 then
		return nil
	end
	return out
end

function Skin.GetFrameSpellID(frame)
	if not frame then
		return nil
	end
	if type(frame.spellID) == "number" then
		return frame.spellID
	end
	local info = frame.cooldownInfo
	if info and type(info.spellID) == "number" then
		return info.spellID
	end
	local cdID = frame.cooldownID
	if cdID and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo then
		local ok, data = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
		if ok and data and type(data.spellID) == "number" then
			return data.spellID
		end
	end
	return nil
end

function Skin.GetKeybindCacheVersion()
	return cacheVersion
end

function Skin.InvalidateKeybinds()
	wipe(textCache)
	wipe(rawCache)
	cachedMainBarPage = nil
	cacheVersion = cacheVersion + 1
end

function Skin.GetKeybindText(spellID)
	spellID = tonumber(spellID)
	if not spellID then
		return nil
	end
	local cached = textCache[spellID]
	if cached ~= nil then
		return cached or nil
	end
	local text = ComputeShortestText(spellID)
	textCache[spellID] = text or false
	return text
end

function Skin.GetRawKeysForSpell(spellID)
	spellID = tonumber(spellID)
	if not spellID then
		return nil
	end
	local cached = rawCache[spellID]
	if cached ~= nil then
		return cached or nil
	end
	local keys = ComputeRawKeys(spellID)
	rawCache[spellID] = keys or false
	return keys
end

function Skin.GetBindingCommandForActionSlot(slot)
	return GetBindingCommandForSlot(slot)
end

function Skin.GetActionSlotForMainBarButton(buttonID)
	buttonID = tonumber(buttonID)
	if not buttonID or buttonID < 1 or buttonID > 12 then
		return nil
	end
	local page = GetMainBarPage()
	return (page - 1) * 12 + buttonID
end

local MULTI_BAR_FIRST_SLOT = {
	MultiBarBottomLeft = 61,
	MultiBarBottomRight = 49,
	MultiBarRight = 25,
	MultiBarLeft = 37,
	MultiBar5 = 145,
	MultiBar6 = 157,
	MultiBar7 = 169,
}

function Skin.GetActionSlotForMultiBar(barName, buttonID)
	buttonID = tonumber(buttonID)
	local first = barName and MULTI_BAR_FIRST_SLOT[barName]
	if not first or not buttonID or buttonID < 1 or buttonID > 12 then
		return nil
	end
	return first + buttonID - 1
end

function Skin.GetSpellIDForActionSlot(slot)
	if type(slot) ~= "number" or not GetActionInfo then
		return nil
	end
	local actionType, id = GetActionInfo(slot)
	if actionType == "spell" and type(id) == "number" then
		return id
	end
	if actionType == "macro" and type(id) == "number" and GetMacroSpell then
		local ok, spellID = pcall(GetMacroSpell, id)
		if ok and type(spellID) == "number" then
			return spellID
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

local BAR_CHANGE = {
	UPDATE_BONUS_ACTIONBAR = true,
	ACTIONBAR_PAGE_CHANGED = true,
	UPDATE_OVERRIDE_ACTIONBAR = true,
	UPDATE_VEHICLE_ACTIONBAR = true,
}

local delayedToken = 0

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
