local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local fontObjs = {}
local mixinsHooked = false

local ANCHOR_POINTS = {
	CENTER = true,
	TOP = true,
	BOTTOM = true,
	LEFT = true,
	RIGHT = true,
	TOPLEFT = true,
	TOPRIGHT = true,
	BOTTOMLEFT = true,
	BOTTOMRIGHT = true,
}

local VIEWERS = GCDM.CONST.VIEWERS
local ICON_VIEWERS = {
	[VIEWERS.ESSENTIAL] = true,
	[VIEWERS.UTILITY] = true,
	[VIEWERS.BUFF] = true,
}

local function CopyColor(c, fallback)
	fallback = fallback or { r = 1, g = 1, b = 1, a = 1 }
	if type(c) ~= "table" then
		return { r = fallback.r, g = fallback.g, b = fallback.b, a = fallback.a }
	end
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
		if not parent then
			return nil
		end
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
	-- Own color tables (AceDB shares nested defaults).
	if viewerKey == VIEWERS.BUFF_BAR then
		style.nameTextColor = CopyColor(style.nameTextColor)
		style.durationTextColor = CopyColor(style.durationTextColor)
	else
		style.cooldownTextColor = CopyColor(style.cooldownTextColor)
		style.stackTextColor = CopyColor(style.stackTextColor)
	end
	return style
end

local function ResolveOutline(outline)
	if outline == nil then
		return GCDM.CONST.FONT_OUTLINE or "OUTLINE"
	end
	if outline == "" or outline == "NONE" then
		return ""
	end
	return outline
end

function Skin.ResolveOutline(outline)
	return ResolveOutline(outline)
end

local function NormalizePoint(point, fallback)
	if type(point) == "string" and ANCHOR_POINTS[point] then
		return point
	end
	return fallback
end

local function GetFontObj(key)
	if not fontObjs[key] then
		fontObjs[key] = CreateFont("GCDM_Text_" .. key)
	end
	return fontObjs[key]
end

local function ApplyFontObject(fontObj, path, size, outline)
	if not fontObj or not fontObj.SetFont or not path then
		return false
	end
	local ok = pcall(fontObj.SetFont, fontObj, path, size or 12, outline or "")
	if not ok or (fontObj.GetFont and not fontObj:GetFont()) then
		pcall(fontObj.SetFont, fontObj, GCDM.CONST.FONT_PATH or "Fonts\\FRIZQT__.TTF", size or 12, outline ~= "" and outline or "OUTLINE")
	end
	return true
end

local function ApplyFontToString(fs, path, size, outline, color)
	if not fs then
		return
	end
	if path and fs.SetFont then
		local ok = pcall(fs.SetFont, fs, path, size or 12, outline or "")
		if not ok or (fs.GetFont and not fs:GetFont()) then
			pcall(fs.SetFont, fs, GCDM.CONST.FONT_PATH or "Fonts\\FRIZQT__.TTF", size or 12, outline ~= "" and outline or "OUTLINE")
		end
	end
	if color and fs.SetTextColor then
		fs:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
	end
end

local function StyleFontString(fs, fontObj, color, point, ox, oy, relativeTo, path, size, outline)
	if not fs then
		return
	end
	if fontObj and fs.SetFontObject then
		fs:SetFontObject(fontObj)
	end
	ApplyFontToString(fs, path, size, outline, color)
	if relativeTo and fs.ClearAllPoints and fs.SetPoint then
		fs:ClearAllPoints()
		fs:SetPoint(point, relativeTo, point, ox or 0, oy or 0)
	end
end

local function GetCountdownFontString(cd)
	if not cd then
		return nil
	end
	if cd.GetCountdownFontString then
		local ok, fs = pcall(cd.GetCountdownFontString, cd)
		if ok and fs then
			return fs
		end
	end
	local regions = { cd:GetRegions() }
	for i = 1, #regions do
		local r = regions[i]
		if r and r.GetObjectType and r:GetObjectType() == "FontString" then
			return r
		end
	end
	return nil
end

local function GetStackFontString(frame)
	if not frame then
		return nil
	end
	local charge = frame.ChargeCount
	if charge and charge.Current then
		-- Anchor/raise ChargeCount so stacks sit above Cooldown swipe.
		return charge.Current, charge
	end
	local apps = frame.Applications
	if apps then
		if apps.Applications then
			return apps.Applications, apps
		end
		if apps.GetObjectType and apps:GetObjectType() == "FontString" then
			return apps, frame
		end
	end
	if frame.Count and frame.Count.GetObjectType and frame.Count:GetObjectType() == "FontString" then
		return frame.Count, frame
	end
	local icon = frame.Icon
	if icon and icon.Applications then
		local a = icon.Applications
		if a.GetObjectType and a:GetObjectType() == "FontString" then
			return a, icon
		end
	end
	return nil
end

local function StyleCooldownText(frame, style, viewerKey)
	local cd = frame.Cooldown
	if not cd or not style then
		return
	end

	local path = Skin.FetchFont(style.textFont or "Expressway")
	local size = style.cooldownFontSize or 14
	local outline = ResolveOutline(style.textOutline)
	local fontKey = (viewerKey or "icon") .. "_cd"
	local fontObj = GetFontObj(fontKey)
	ApplyFontObject(fontObj, path, size, outline)

	if cd.SetCountdownFont then
		pcall(cd.SetCountdownFont, cd, fontObj:GetName())
	end

	local fs = GetCountdownFontString(cd)
	if not fs then
		return
	end

	-- Keep countdown digits above the swipe fill.
	if fs.SetDrawLayer then
		fs:SetDrawLayer("OVERLAY", 7)
	end

	local point = NormalizePoint(style.cooldownTextPoint, "CENTER")
	local ox = style.cooldownTextOffsetX or 0
	local oy = style.cooldownTextOffsetY or 0
	StyleFontString(fs, fontObj, style.cooldownTextColor, point, ox, oy, frame, path, size, outline)

	if not cd.GCDMTextHooked then
		cd.GCDMTextHooked = true
		cd:HookScript("OnShow", function(self)
			local parent = self:GetParent()
			local profile = GCDM:GetDB()
			if parent and profile and profile.enabled then
				local key = Skin.GetViewerKeyForFrame(parent)
				if key and ICON_VIEWERS[key] then
					StyleCooldownText(parent, Skin.GetTextStyle(profile, key), key)
				end
			end
		end)
	end
end

local function RaiseStackAboveSwipe(frame, fs, anchor)
	local cd = frame and frame.Cooldown
	local base = (frame and frame.GetFrameLevel and frame:GetFrameLevel()) or 0
	local cdLevel = (cd and cd.GetFrameLevel and cd:GetFrameLevel()) or (base + 1)
	local above = cdLevel + 5

	-- ChargeCount / Applications container is a child frame — raise it over Cooldown swipe.
	local holder = anchor
	if holder and holder ~= frame and holder.SetFrameLevel then
		holder:SetFrameLevel(above)
	elseif fs then
		-- FontString parented to icon frame draws under child Cooldown; move to overlay holder.
		local overlay = frame.GCDMStackOverlay
		if not overlay then
			overlay = CreateFrame("Frame", nil, frame)
			overlay:SetAllPoints(frame)
			frame.GCDMStackOverlay = overlay
		end
		overlay:SetFrameLevel(above)
		if fs.GetParent and fs.SetParent and fs:GetParent() ~= overlay then
			local point, rel, relPoint, x, y = fs:GetPoint(1)
			fs:SetParent(overlay)
			fs:ClearAllPoints()
			if point then
				fs:SetPoint(point, overlay, relPoint or point, x or 0, y or 0)
			end
		end
	end
	if fs and fs.SetDrawLayer then
		fs:SetDrawLayer("OVERLAY", 7)
	end
end

local function StyleStackText(frame, style, viewerKey)
	local fs, anchor = GetStackFontString(frame)
	if not fs or not style then
		return
	end

	local path = Skin.FetchFont(style.textFont or "Expressway")
	local size = style.stackFontSize or 12
	local outline = ResolveOutline(style.textOutline)
	local fontKey = (viewerKey or "icon") .. "_stack"
	local fontObj = GetFontObj(fontKey)
	ApplyFontObject(fontObj, path, size, outline)

	local point = NormalizePoint(style.stackTextPoint, "BOTTOMRIGHT")
	local ox = style.stackTextOffsetX or 0
	local oy = style.stackTextOffsetY or 0
	StyleFontString(fs, fontObj, style.stackTextColor, point, ox, oy, anchor or frame, path, size, outline)
	RaiseStackAboveSwipe(frame, fs, anchor)

	if not fs.GCDMStackHooked then
		fs.GCDMStackHooked = true
		if fs.HookScript then
			fs:HookScript("OnShow", function()
				local profile = GCDM:GetDB()
				if profile and profile.enabled then
					local key = Skin.GetViewerKeyForFrame(frame)
					if key and ICON_VIEWERS[key] then
						StyleStackText(frame, Skin.GetTextStyle(profile, key), key)
					end
				end
			end)
		end
	end
end

function Skin.ApplyText(frame, viewerKey)
	local db = GCDM:GetDB()
	if not db or not db.enabled or not frame then
		return
	end
	viewerKey = viewerKey or Skin.GetViewerKeyForFrame(frame)
	if not viewerKey or not ICON_VIEWERS[viewerKey] then
		return
	end
	local style = Skin.GetTextStyle(db, viewerKey)
	StyleCooldownText(frame, style, viewerKey)
	StyleStackText(frame, style, viewerKey)
end

local function StyleBuffBarLabels(frame, db)
	local bar = frame and frame.Bar
	if not bar then
		return
	end
	local style = Skin.GetTextStyle(db, VIEWERS.BUFF_BAR)
	local path = Skin.FetchFont(style.textFont or "Expressway")
	local outline = ResolveOutline(style.textOutline)
	local nameSize = math.max(8, style.nameFontSize or 12)
	local durSize = math.max(8, style.durationFontSize or 14)
	local nameOx = style.nameTextOffsetX or 4
	local nameOy = style.nameTextOffsetY or 0
	local durOx = style.durationTextOffsetX or -4
	local durOy = style.durationTextOffsetY or 0

	local duration = bar.Duration
	local name = bar.Name
	local cdFont = GetFontObj("buffbar_cd")
	local nameFont = GetFontObj("buffbar_name")

	if duration then
		if db.buffBarShowDuration ~= false then
			ApplyFontObject(cdFont, path, durSize, outline)
			if duration.SetFontObject then
				duration:SetFontObject(cdFont)
			end
			ApplyFontToString(duration, path, durSize, outline, style.durationTextColor)
			duration:ClearAllPoints()
			duration:SetPoint("RIGHT", bar, "RIGHT", durOx, durOy)
			if duration.SetJustifyH then
				duration:SetJustifyH("RIGHT")
			end
			if duration.SetWidth then
				duration:SetWidth(42)
			end
			duration:SetAlpha(1)
		else
			duration:SetAlpha(0)
		end
	end

	if name then
		if db.buffBarShowName ~= false then
			ApplyFontObject(nameFont, path, nameSize, outline)
			if name.SetFontObject then
				name:SetFontObject(nameFont)
			end
			ApplyFontToString(name, path, nameSize, outline, style.nameTextColor)
			name:ClearAllPoints()
			name:SetPoint("LEFT", bar, "LEFT", nameOx, nameOy)
			if duration and db.buffBarShowDuration ~= false then
				name:SetPoint("RIGHT", duration, "LEFT", -4, 0)
			else
				name:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
			end
			if name.SetJustifyH then
				name:SetJustifyH("LEFT")
			end
			if name.SetWordWrap then
				name:SetWordWrap(false)
			end
			if name.SetMaxLines then
				name:SetMaxLines(1)
			end
			name:SetAlpha(1)
		else
			name:SetAlpha(0)
		end
	end

	-- Stack/applications on buff-bar icon use buff-bar style stack fields if present, else icon defaults.
	local stackStyle = {
		textFont = style.textFont,
		textOutline = style.textOutline,
		stackFontSize = style.nameFontSize or 12,
		stackTextColor = style.nameTextColor,
		stackTextPoint = "BOTTOMRIGHT",
		stackTextOffsetX = -1,
		stackTextOffsetY = 1,
	}
	StyleStackText(frame, stackStyle, VIEWERS.BUFF_BAR)
end

function Skin.ApplyBuffBarText(frame, db)
	db = db or GCDM:GetDB()
	if not db or not frame then
		return
	end
	StyleBuffBarLabels(frame, db)
end

local function HookMixins()
	if mixinsHooked then
		return
	end
	mixinsHooked = true

	if CooldownViewerCooldownItemMixin and CooldownViewerCooldownItemMixin.RefreshSpellChargeInfo then
		hooksecurefunc(CooldownViewerCooldownItemMixin, "RefreshSpellChargeInfo", function(self)
			local db = GCDM:GetDB()
			if db and db.enabled then
				Skin.ApplyText(self)
			end
		end)
	end

	if CooldownViewerBuffIconItemMixin and CooldownViewerBuffIconItemMixin.RefreshApplications then
		hooksecurefunc(CooldownViewerBuffIconItemMixin, "RefreshApplications", function(self)
			local db = GCDM:GetDB()
			if db and db.enabled then
				Skin.ApplyText(self)
			end
		end)
	end

	if CooldownViewerItemMixin and CooldownViewerItemMixin.OnLoad then
		hooksecurefunc(CooldownViewerItemMixin, "OnLoad", function(self)
			local db = GCDM:GetDB()
			if db and db.enabled then
				Skin.ApplyText(self)
			end
		end)
	end
end

local function ApplyTextAll()
	HookMixins()
	local db = GCDM:GetDB()
	if not db or not db.enabled then
		return
	end
	GCDM.Skin.ForEachManagedIcon(function(frame, _, viewerName)
		Skin.ApplyText(frame, viewerName)
	end)
	if GCDM.Skin.ForEachBuffBar then
		GCDM.Skin.ForEachBuffBar(function(frame)
			StyleBuffBarLabels(frame, db)
		end)
	end
end

GCDM:RegisterRefreshCallback("Skin.Text", ApplyTextAll, 55, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})
