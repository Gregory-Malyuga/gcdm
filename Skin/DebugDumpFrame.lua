local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local D = Skin.DebugUtil

local function EnsureDumpFrame()
	local f = GCDMBuffBarDumpFrame
	if f then
		return f
	end
	f = CreateFrame("Frame", "GCDMBuffBarDumpFrame", UIParent, "BackdropTemplate")
	f:SetSize(520, 360)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -14)
	title:SetText("GCDM dump — Ctrl+A, Ctrl+C, paste to chat")
	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)
	local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 16, -40)
	scroll:SetPoint("BOTTOMRIGHT", -36, 16)
	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetFontObject(GameFontHighlightSmall)
	edit:SetWidth(460)
	edit:SetAutoFocus(false)
	edit:SetScript("OnEscapePressed", function()
		f:Hide()
	end)
	scroll:SetScrollChild(edit)
	f.edit = edit
	f:Hide()
	return f
end

function D.ShowDumpWindow(text)
	local ok, err = pcall(function()
		local f = EnsureDumpFrame()
		f.edit:SetText(text or "")
		f.edit:SetCursorPosition(0)
		f.edit:HighlightText()
		f.edit:SetFocus()
		f:Show()
	end)
	if not ok then
		D.Emit("Dump window error: " .. D.SafeStr(err))
		for line in string.gmatch(text or "", "[^\n]+") do
			D.Emit(line)
		end
	end
end
