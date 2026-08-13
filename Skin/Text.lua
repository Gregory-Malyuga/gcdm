local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local COOLDOWN_FONT_NAME = "GCDM_CooldownCountdownFont"
local STACK_FONT_NAME = "GCDM_StackCountFont"

local cooldownFontObj
local stackFontObj
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

local function EnsureFonts()
	if not cooldownFontObj then
		cooldownFontObj = CreateFont(COOLDOWN_FONT_NAME)
	end
	if not stackFontObj then
		stackFontObj = CreateFont(STACK_FONT_NAME)
	end
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

local function NormalizePoint(point, fallback)
	if type(point) == "string" and ANCHOR_POINTS[point] then
		return point
	end
	return fallback
end

local function ApplyFontObject(fontObj, path, size, outline)
	if not fontObj or not fontObj.SetFont then
		return false
	end
	if not path then
		return false
	end
	local ok = fontObj:SetFont(path, size or 12, outline or "")
	return ok ~= false
end

local function ApplyFontToString(fs, path, size, outline, color)
	if not fs then
		return
	end
	if path and fs.SetFont then
		pcall(fs.SetFont, fs, path, size or 12, outline or "")
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
		return charge.Current, frame
	end
	local apps = frame.Applications
	if apps then
		if apps.Applications then
			return apps.Applications, frame
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
			return a, frame
		end
	end
	return nil
end

local function StyleCooldownText(frame, db)
	local cd = frame.Cooldown
	if not cd then
		return
	end

	local path = Skin.FetchFont(db.textFont)
	local size = db.cooldownFontSize or 14
	local outline = ResolveOutline(db.textOutline)
	ApplyFontObject(cooldownFontObj, path, size, outline)

	if cd.SetCountdownFont then
		pcall(cd.SetCountdownFont, cd, COOLDOWN_FONT_NAME)
	end

	local fs = GetCountdownFontString(cd)
	if not fs then
		return
	end

	local point = NormalizePoint(db.cooldownTextPoint, "CENTER")
	local ox = db.cooldownTextOffsetX or 0
	local oy = db.cooldownTextOffsetY or 0
	StyleFontString(fs, cooldownFontObj, db.cooldownTextColor, point, ox, oy, frame, path, size, outline)

	if not cd.GCDMTextHooked then
		cd.GCDMTextHooked = true
		cd:HookScript("OnShow", function(self)
			local parent = self:GetParent()
			local profile = GCDM:GetDB()
			if parent and profile and profile.enabled then
				StyleCooldownText(parent, profile)
			end
		end)
	end
end

local function StyleStackText(frame, db)
	local fs, anchor = GetStackFontString(frame)
	if not fs then
		return
	end

	local path = Skin.FetchFont(db.textFont)
	local size = db.stackFontSize or 12
	local outline = ResolveOutline(db.textOutline)
	ApplyFontObject(stackFontObj, path, size, outline)

	local point = NormalizePoint(db.stackTextPoint, "BOTTOMRIGHT")
	local ox = db.stackTextOffsetX or 0
	local oy = db.stackTextOffsetY or 0
	StyleFontString(fs, stackFontObj, db.stackTextColor, point, ox, oy, anchor or frame, path, size, outline)

	if not fs.GCDMStackHooked then
		fs.GCDMStackHooked = true
		if fs.HookScript then
			fs:HookScript("OnShow", function()
				local profile = GCDM:GetDB()
				if profile and profile.enabled then
					StyleStackText(frame, profile)
				end
			end)
		end
	end
end

function Skin.ApplyText(frame)
	local db = GCDM:GetDB()
	if not db or not db.enabled or not frame then
		return
	end
	EnsureFonts()
	StyleCooldownText(frame, db)
	StyleStackText(frame, db)
end

local function StyleBuffBarLabels(frame, db)
	local bar = frame and frame.Bar
	if not bar then
		return
	end
	EnsureFonts()
	local path = Skin.FetchFont(db.textFont)
	local outline = ResolveOutline(db.textOutline)
	local nameSize = math.max(10, math.min(db.stackFontSize or 12, (frame:GetHeight() or 16) - 2))
	local durSize = math.max(10, math.min(db.cooldownFontSize or 14, (frame:GetHeight() or 16) - 2))
	local pad = 4

	local duration = bar.Duration
	local name = bar.Name

	if duration then
		if db.buffBarShowDuration ~= false then
			ApplyFontObject(cooldownFontObj, path, durSize, outline)
			if duration.SetFontObject then
				duration:SetFontObject(cooldownFontObj)
			end
			ApplyFontToString(duration, path, durSize, outline, db.cooldownTextColor)
			duration:ClearAllPoints()
			duration:SetPoint("RIGHT", bar, "RIGHT", -pad, 0)
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
			ApplyFontObject(stackFontObj, path, nameSize, outline)
			if name.SetFontObject then
				name:SetFontObject(stackFontObj)
			end
			ApplyFontToString(name, path, nameSize, outline, db.stackTextColor)
			name:ClearAllPoints()
			name:SetPoint("LEFT", bar, "LEFT", pad, 0)
			if duration and db.buffBarShowDuration ~= false then
				name:SetPoint("RIGHT", duration, "LEFT", -pad, 0)
			else
				name:SetPoint("RIGHT", bar, "RIGHT", -pad, 0)
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

	StyleStackText(frame, db)
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
				StyleStackText(self, db)
			end
		end)
	end

	if CooldownViewerBuffIconItemMixin and CooldownViewerBuffIconItemMixin.RefreshApplications then
		hooksecurefunc(CooldownViewerBuffIconItemMixin, "RefreshApplications", function(self)
			local db = GCDM:GetDB()
			if db and db.enabled then
				StyleStackText(self, db)
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
	EnsureFonts()
	HookMixins()
	local db = GCDM:GetDB()
	if not db or not db.enabled then
		return
	end
	GCDM.Skin.ForEachManagedIcon(function(frame)
		Skin.ApplyText(frame)
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
