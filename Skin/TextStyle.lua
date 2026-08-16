local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local fontObjs = {}
local VIEWERS = GCDM.CONST.VIEWERS

Skin.TEXT_ICON_VIEWERS = {
	[VIEWERS.ESSENTIAL] = true,
	[VIEWERS.UTILITY] = true,
	[VIEWERS.BUFF] = true,
}

Skin.TEXT_KEYBIND_VIEWERS = {
	[VIEWERS.ESSENTIAL] = true,
	[VIEWERS.UTILITY] = true,
}

local function CopyColor(c, fallback)
	if Skin.ColorUtil and Skin.ColorUtil.Copy then return Skin.ColorUtil.Copy(c, fallback) end
	fallback = fallback or { r = 1, g = 1, b = 1, a = 1 }
	if type(c) ~= "table" then return { r = fallback.r, g = fallback.g, b = fallback.b, a = fallback.a } end
	return { r = c.r or fallback.r, g = c.g or fallback.g, b = c.b or fallback.b, a = c.a or fallback.a }
end

local function DefaultIconStyle()
	return {
		textFont = "Expressway",
		textOutline = "OUTLINE",
		cooldownFontSize = 14,
		cooldownTextColor = { r = 1, g = 1, b = 1, a = 1 },
		cooldownTextPoint = "CENTER",
		cooldownTextOffsetX = 0,
		cooldownTextOffsetY = 0,
		stackFontSize = 12,
		stackTextColor = { r = 1, g = 1, b = 1, a = 1 },
		stackTextPoint = "BOTTOMRIGHT",
		stackTextOffsetX = -1,
		stackTextOffsetY = 1,
		keybindFontSize = 11,
		keybindTextColor = { r = 1, g = 1, b = 1, a = 1 },
		keybindTextPoint = "TOPLEFT",
		keybindTextOffsetX = 2,
		keybindTextOffsetY = -1,
	}
end

local function DefaultBuffBarStyle()
	return {
		textFont = "Expressway",
		textOutline = "OUTLINE",
		nameFontSize = 12,
		durationFontSize = 14,
		nameTextColor = { r = 1, g = 1, b = 1, a = 1 },
		durationTextColor = { r = 1, g = 1, b = 1, a = 1 },
		nameTextOffsetX = 4,
		nameTextOffsetY = 0,
		durationTextOffsetX = -4,
		durationTextOffsetY = 0,
	}
end

function Skin.GetViewerKeyForFrame(frame)
	local parent = frame
	for _ = 1, 12 do
		if not parent then return nil end
		local name = parent.GetName and parent:GetName()
		if name == VIEWERS.ESSENTIAL or name == VIEWERS.UTILITY or name == VIEWERS.BUFF or name == VIEWERS.BUFF_BAR then
			return name
		end
		parent = parent.GetParent and parent:GetParent()
	end
	return nil
end

function Skin.GetTextStyle(db, viewerKey)
	db = db or GCDM:GetDB()
	if not db then
		return viewerKey == VIEWERS.BUFF_BAR and DefaultBuffBarStyle() or DefaultIconStyle()
	end
	db.textByViewer = db.textByViewer or {}
	local style = db.textByViewer[viewerKey]
	if type(style) ~= "table" then
		style = (viewerKey == VIEWERS.BUFF_BAR) and DefaultBuffBarStyle() or DefaultIconStyle()
		db.textByViewer[viewerKey] = style
	end
	if viewerKey == VIEWERS.BUFF_BAR then
		style.nameTextColor = CopyColor(style.nameTextColor)
		style.durationTextColor = CopyColor(style.durationTextColor)
	else
		style.cooldownTextColor = CopyColor(style.cooldownTextColor)
		style.stackTextColor = CopyColor(style.stackTextColor)
		if Skin.TEXT_KEYBIND_VIEWERS[viewerKey] then
			style.keybindTextColor = CopyColor(style.keybindTextColor or { r = 1, g = 1, b = 1, a = 1 })
		end
	end
	return style
end

function Skin.ResolveOutline(outline)
	if outline == nil then return GCDM.CONST.FONT_OUTLINE or "OUTLINE" end
	if outline == "" or outline == "NONE" then return "" end
	return outline
end

function Skin.TextNormalizePoint(point, fallback)
	if Skin.AnchorUtil and Skin.AnchorUtil.NormalizePoint then
		return Skin.AnchorUtil.NormalizePoint(point, fallback)
	end
	return fallback or "CENTER"
end

function Skin.TextGetFontObj(key)
	if not fontObjs[key] then fontObjs[key] = CreateFont("GCDM_Text_" .. key) end
	return fontObjs[key]
end

function Skin.TextApplyFontObject(fontObj, path, size, outline)
	if not fontObj or not fontObj.SetFont or not path then return false end
	local ok = pcall(fontObj.SetFont, fontObj, path, size or 12, outline or "")
	if not ok or (fontObj.GetFont and not fontObj:GetFont()) then
		pcall(fontObj.SetFont, fontObj, GCDM.CONST.FONT_PATH or "Fonts\\FRIZQT__.TTF", size or 12, outline ~= "" and outline or "OUTLINE")
	end
	return true
end

function Skin.TextApplyFontToString(fs, path, size, outline, color)
	if not fs then return end
	if path and fs.SetFont then
		local ok = pcall(fs.SetFont, fs, path, size or 12, outline or "")
		if not ok or (fs.GetFont and not fs:GetFont()) then
			pcall(fs.SetFont, fs, GCDM.CONST.FONT_PATH or "Fonts\\FRIZQT__.TTF", size or 12, outline ~= "" and outline or "OUTLINE")
		end
	end
	if color and fs.SetTextColor then
		if Skin.ColorUtil and Skin.ColorUtil.Unpack then
			fs:SetTextColor(Skin.ColorUtil.Unpack(color))
		else
			fs:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
		end
	end
end

function Skin.TextStyleFontString(fs, fontObj, color, point, ox, oy, relativeTo, path, size, outline)
	if not fs then return end
	if fontObj and fs.SetFontObject then fs:SetFontObject(fontObj) end
	Skin.TextApplyFontToString(fs, path, size, outline, color)
	if relativeTo and fs.ClearAllPoints and fs.SetPoint then
		fs:ClearAllPoints()
		fs:SetPoint(point, relativeTo, point, ox or 0, oy or 0)
	end
end
