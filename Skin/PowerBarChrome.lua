-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- Power bar create + font helpers.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

local PowerBarChrome = {}
Skin.PowerBarChrome = PowerBarChrome

local function PowerBarBgUnpack(db)
	local fallback = (GCDM.CONST and GCDM.CONST.POWER_BAR_BG_COLOR) or { r = 0.1, g = 0.1, b = 0.1, a = 0.95 }
	local c = (db and db.powerBarBackgroundColor) or fallback
	if Skin.ColorUtil and Skin.ColorUtil.Unpack then
		return Skin.ColorUtil.Unpack(c, fallback.r, fallback.g, fallback.b, fallback.a)
	end
	return c.r or fallback.r, c.g or fallback.g, c.b or fallback.b, c.a or fallback.a
end

PowerBarChrome.BgUnpack = PowerBarBgUnpack

function PowerBarChrome.EnsureBar(parent, name)
	local bar = CreateFrame("StatusBar", name, parent)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(PowerBarBgUnpack(nil))
	bar.GCDMBg = bg
	bar.GCDMEdge = {
		T = bar:CreateTexture(nil, "OVERLAY", nil, 7),
		B = bar:CreateTexture(nil, "OVERLAY", nil, 7),
		L = bar:CreateTexture(nil, "OVERLAY", nil, 7),
		R = bar:CreateTexture(nil, "OVERLAY", nil, 7),
	}
	for _, tex in pairs(bar.GCDMEdge) do
		tex:SetColorTexture(0, 0, 0, 1)
		if Pixel.DisableTextureSnap then
			Pixel.DisableTextureSnap(tex)
		end
		tex:Hide()
	end
	local fs = bar:CreateFontString(nil, "OVERLAY")
	fs:SetPoint("CENTER")
	fs:SetJustifyH("CENTER")
	pcall(fs.SetFont, fs, GCDM.CONST.FONT_PATH or "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	bar.GCDMText = fs
	bar.GCDMTicks = {}
	return bar
end

function PowerBarChrome.ApplyFont(fs, db)
	if not fs then
		return
	end
	local fontPath = (Skin.FetchFont and Skin.FetchFont(db and (db.powerBarFont or db.textFont) or "Expressway")) or GCDM.CONST.FONT_PATH
	local fontSize = (db and db.powerBarFontSize) or (GCDM.CONST and GCDM.CONST.DEFAULT_POWER_BAR_FONT_SIZE) or 12
	if type(fontSize) ~= "number" or fontSize < 1 then
		fontSize = (GCDM.CONST and GCDM.CONST.DEFAULT_POWER_BAR_FONT_SIZE) or 12
	end
	local outlineRaw = db and db.powerBarTextOutline
	if outlineRaw == nil then
		outlineRaw = "OUTLINE"
	end
	local outline = (Skin.ResolveOutline and Skin.ResolveOutline(outlineRaw)) or outlineRaw or "OUTLINE"
	if outline == "NONE" then
		outline = ""
	end
	local ok = pcall(fs.SetFont, fs, fontPath, fontSize, outline)
	local hasFont = ok and fs.GetFont and fs:GetFont()
	if not hasFont then
		pcall(fs.SetFont, fs, GCDM.CONST.FONT_PATH or "Fonts\\FRIZQT__.TTF", fontSize, outline ~= "" and outline or "OUTLINE")
	end
	if fs.GetFont and not fs:GetFont() then
		pcall(fs.SetFont, fs, "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	end
	return outline
end

function PowerBarChrome.SafeSetText(fs, value)
	if not fs then
		return
	end
	if fs.GetFont and not fs:GetFont() then
		PowerBarChrome.ApplyFont(fs, GCDM.GetDB and GCDM:GetDB())
	end
	if value == nil then
		pcall(fs.SetText, fs, "")
		return
	end
	if fs.SetTextToFit then
		local okFit = pcall(fs.SetTextToFit, fs, value)
		if okFit then
			return
		end
	end
	pcall(fs.SetText, fs, value)
end
