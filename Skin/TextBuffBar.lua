local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local VIEWERS = GCDM.CONST.VIEWERS

local function StyleBuffBarLabels(frame, db)
	local bar = frame and frame.Bar
	if not bar then return end
	local style = Skin.GetTextStyle(db, VIEWERS.BUFF_BAR)
	local path = Skin.FetchFont(style.textFont or "Expressway")
	local outline = Skin.ResolveOutline(style.textOutline)
	local nameSize = math.max(8, style.nameFontSize or 12)
	local durSize = math.max(8, style.durationFontSize or 14)
	local nameOx = style.nameTextOffsetX or 4
	local nameOy = style.nameTextOffsetY or 0
	local durOx = style.durationTextOffsetX or -4
	local durOy = style.durationTextOffsetY or 0
	local duration = bar.Duration
	local name = bar.Name
	local cdFont = Skin.TextGetFontObj("buffbar_cd")
	local nameFont = Skin.TextGetFontObj("buffbar_name")
	if duration then
		if db.buffBarShowDuration ~= false then
			Skin.TextApplyFontObject(cdFont, path, durSize, outline)
			if duration.SetFontObject then duration:SetFontObject(cdFont) end
			Skin.TextApplyFontToString(duration, path, durSize, outline, style.durationTextColor)
			duration:ClearAllPoints()
			duration:SetPoint("RIGHT", bar, "RIGHT", durOx, durOy)
			if duration.SetJustifyH then duration:SetJustifyH("RIGHT") end
			if duration.SetWidth then duration:SetWidth(42) end
			duration:SetAlpha(1)
		else
			duration:SetAlpha(0)
		end
	end
	if name then
		if db.buffBarShowName ~= false then
			Skin.TextApplyFontObject(nameFont, path, nameSize, outline)
			if name.SetFontObject then name:SetFontObject(nameFont) end
			Skin.TextApplyFontToString(name, path, nameSize, outline, style.nameTextColor)
			name:ClearAllPoints()
			name:SetPoint("LEFT", bar, "LEFT", nameOx, nameOy)
			if duration and db.buffBarShowDuration ~= false then
				name:SetPoint("RIGHT", duration, "LEFT", -4, 0)
			else
				name:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
			end
			if name.SetJustifyH then name:SetJustifyH("LEFT") end
			if name.SetWordWrap then name:SetWordWrap(false) end
			if name.SetMaxLines then name:SetMaxLines(1) end
			name:SetAlpha(1)
		else
			name:SetAlpha(0)
		end
	end
	Skin.StyleStackText(frame, {
		textFont = style.textFont,
		textOutline = style.textOutline,
		stackFontSize = style.nameFontSize or 12,
		stackTextColor = style.nameTextColor,
		stackTextPoint = "BOTTOMRIGHT",
		stackTextOffsetX = -1,
		stackTextOffsetY = 1,
	}, VIEWERS.BUFF_BAR)
end

function Skin.ApplyBuffBarText(frame, db)
	db = db or GCDM:GetDB()
	if not db or not frame then return end
	StyleBuffBarLabels(frame, db)
end

Skin.StyleBuffBarLabels = StyleBuffBarLabels
