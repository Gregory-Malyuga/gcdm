local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local cachedMainBarPage = nil

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

local MULTI_BAR_FIRST_SLOT = {
	MultiBarBottomLeft = 61,
	MultiBarBottomRight = 49,
	MultiBarRight = 25,
	MultiBarLeft = 37,
	MultiBar5 = 145,
	MultiBar6 = 157,
	MultiBar7 = 169,
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

function Skin.GetMainBarPage()
	if not cachedMainBarPage then
		cachedMainBarPage = DetectMainBarPage()
	end
	return cachedMainBarPage
end

function Skin.ClearMainBarPageCache()
	cachedMainBarPage = nil
end

local function GetBindingCommandForSlot(slot)
	if type(slot) ~= "number" or slot < 1 then
		return nil
	end
	local page = math.ceil(slot / 12)
	local buttonID = ((slot - 1) % 12) + 1
	local mainPage = Skin.GetMainBarPage()
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

function Skin.GetBindingCommandForActionSlot(slot)
	return GetBindingCommandForSlot(slot)
end

function Skin.GetActionSlotForMainBarButton(buttonID)
	buttonID = tonumber(buttonID)
	if not buttonID or buttonID < 1 or buttonID > 12 then
		return nil
	end
	local page = Skin.GetMainBarPage()
	return (page - 1) * 12 + buttonID
end

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

function Skin.ShortestTextForSlot(slot)
	local command = GetBindingCommandForSlot(slot)
	if not command then
		return nil
	end
	local shortest
	local keys = Skin.BindingKeys(command)
	for i = 1, #keys do
		local key = keys[i]
		if key then
			local text = Skin.FormatRawKey(key)
			if text and (not shortest or #text < #shortest) then
				shortest = text
			end
		end
	end
	return shortest
end

function Skin.CollectRawKeysForSlot(slot, out)
	local command = GetBindingCommandForSlot(slot)
	if not command then
		return
	end
	local keys = Skin.BindingKeys(command)
	for i = 1, #keys do
		local key = keys[i]
		if key and not key:find("MOUSEWHEEL", 1, true) then
			out[#out + 1] = key
		end
	end
end
