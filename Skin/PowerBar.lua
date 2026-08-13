local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

-- Player power bar above Essential.
-- Per-class color profiles: class / solid / ColorCurve (absolute or %).
-- Secret-safe: never compare power; ColorCurve:Evaluate(UnitPower|UnitPowerPercent).

local host
local primaryBar
local primaryText
local secondaryBar
local secondaryText
local eventsFrame
local applying = false
local queued = false
local colorCurve
local curveFingerprint

local CLASS_FILES = {
	"DEFAULT",
	"WARRIOR",
	"PALADIN",
	"HUNTER",
	"ROGUE",
	"PRIEST",
	"DEATHKNIGHT",
	"SHAMAN",
	"MAGE",
	"WARLOCK",
	"MONK",
	"DRUID",
	"DEMONHUNTER",
	"EVOKER",
}

local function PowerEnum(key)
	local pt = Enum and Enum.PowerType and Enum.PowerType[key]
	if type(pt) == "number" then
		return pt
	end
	return nil
end

local CLASS_SECONDARY = {
	PALADIN = "HolyPower",
	MONK = "Chi",
	ROGUE = "ComboPoints",
	DRUID = "ComboPoints",
	WARLOCK = "SoulShards",
	MAGE = "ArcaneCharges",
	EVOKER = "Essence",
	DEATHKNIGHT = "Runes",
	SHAMAN = "Maelstrom",
}

local function SafePowerColor(powerType, powerToken, altR, altG, altB)
	local ok, c = pcall(function()
		if powerToken and type(powerToken) == "string" and PowerBarColor and PowerBarColor[powerToken] then
			return PowerBarColor[powerToken]
		end
		return nil
	end)
	if ok and c then
		return c.r or 0.6, c.g or 0.1, c.b or 0.1, 1
	end
	if type(altR) == "number" and type(altG) == "number" and type(altB) == "number" then
		return altR, altG, altB, 1
	end
	ok, c = pcall(function()
		if powerType ~= nil and type(powerType) == "number" and PowerBarColor and PowerBarColor[powerType] then
			return PowerBarColor[powerType]
		end
		return PowerBarColor and PowerBarColor["ENERGY"] or PowerBarColor and PowerBarColor["RAGE"] or nil
	end)
	if ok and c then
		return c.r or 0.6, c.g or 0.1, c.b or 0.1, 1
	end
	return 0.78, 0.1, 0.1, 1
end

local function PlayerClassFile()
	local _, classFile = UnitClass("player")
	return classFile or "DEFAULT"
end

-- Parse "0:1,0,0|100:1,0,0|101:1,1,1" → { {x=,r=,g=,b=,a=}… }
function Skin.ParsePowerBarCurvePoints(str)
	local out = {}
	if type(str) ~= "string" or str == "" then
		return out
	end
	for part in string.gmatch(str, "[^|]+") do
		local x, r, g, b, a = string.match(part, "^%s*([%d%.]+)%s*:%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,?%s*([%d%.]*)%s*$")
		if x then
			out[#out + 1] = {
				x = tonumber(x) or 0,
				r = tonumber(r) or 1,
				g = tonumber(g) or 1,
				b = tonumber(b) or 1,
				a = (a ~= "" and tonumber(a)) or 1,
			}
		end
	end
	table.sort(out, function(a, b)
		return a.x < b.x
	end)
	return out
end

function Skin.FormatPowerBarCurvePoints(points)
	if type(points) ~= "table" then
		return ""
	end
	local parts = {}
	for i = 1, #points do
		local p = points[i]
		if p then
			parts[#parts + 1] = string.format(
				"%.4g:%.3g,%.3g,%.3g,%.3g",
				p.x or 0,
				p.r or 1,
				p.g or 1,
				p.b or 1,
				p.a or 1
			)
		end
	end
	return table.concat(parts, "|")
end

local function DefaultCurvePointsAbsolute()
	-- Example: normal color until 100, then white (energy overflow / high rage).
	return {
		{ x = 0, r = 1, g = 0.85, b = 0.1, a = 1 },
		{ x = 100, r = 1, g = 0.85, b = 0.1, a = 1 },
		{ x = 100.01, r = 1, g = 1, b = 1, a = 1 },
		{ x = 200, r = 1, g = 1, b = 1, a = 1 },
	}
end

local function DefaultCurvePointsPercent()
	return {
		{ x = 0, r = 1, g = 0.2, b = 0.2, a = 1 },
		{ x = 0.35, r = 1, g = 0.85, b = 0.2, a = 1 },
		{ x = 0.7, r = 0.2, g = 0.9, b = 0.3, a = 1 },
		{ x = 1, r = 1, g = 1, b = 1, a = 1 },
	}
end

local function CopyColor(c, fallback)
	fallback = fallback or { r = 1, g = 1, b = 1, a = 1 }
	c = c or fallback
	return { r = c.r or fallback.r, g = c.g or fallback.g, b = c.b or fallback.b, a = c.a or fallback.a }
end

function Skin.GetPowerBarProfile(db, classFile)
	db = db or GCDM:GetDB()
	classFile = classFile or PlayerClassFile()
	local profiles = db and db.powerBarProfiles
	local base = {
		colorMode = db.powerBarColorMode or "class", -- class | solid | curve
		curveMode = db.powerBarCurveMode or "absolute", -- absolute | percent
		curvePointsStr = db.powerBarCurvePointsStr or Skin.FormatPowerBarCurvePoints(DefaultCurvePointsAbsolute()),
		solidColor = CopyColor(db.powerBarColor, { r = 0.55, g = 0.1, b = 0.1, a = 1 }),
		tickMode = db.powerBarTickMode or "none", -- none | equal | values
		tickCount = db.powerBarTickCount or 4,
		tickAtStr = db.powerBarTickAtStr or "25,50,75,100",
		tickMax = db.powerBarTickMax or 100,
		tickColor = CopyColor(db.powerBarTickColor, { r = 1, g = 1, b = 1, a = 0.55 }),
	}
	if type(profiles) == "table" and type(profiles[classFile]) == "table" then
		local o = profiles[classFile]
		if o.colorMode ~= nil then
			base.colorMode = o.colorMode
		end
		if o.curveMode ~= nil then
			base.curveMode = o.curveMode
		end
		if o.curvePointsStr ~= nil then
			base.curvePointsStr = o.curvePointsStr
		end
		if o.solidColor ~= nil then
			base.solidColor = CopyColor(o.solidColor, base.solidColor)
		end
		if o.tickMode ~= nil then
			base.tickMode = o.tickMode
		end
		if o.tickCount ~= nil then
			base.tickCount = o.tickCount
		end
		if o.tickAtStr ~= nil then
			base.tickAtStr = o.tickAtStr
		end
		if o.tickMax ~= nil then
			base.tickMax = o.tickMax
		end
		if o.tickColor ~= nil then
			base.tickColor = CopyColor(o.tickColor, base.tickColor)
		end
	end
	return base
end

function Skin.SetPowerBarProfileField(db, classFile, field, value)
	db.powerBarProfiles = db.powerBarProfiles or {}
	if classFile == "DEFAULT" then
		-- Mirror into global defaults for new classes.
		if field == "colorMode" then
			db.powerBarColorMode = value
		elseif field == "curveMode" then
			db.powerBarCurveMode = value
		elseif field == "curvePointsStr" then
			db.powerBarCurvePointsStr = value
		elseif field == "solidColor" then
			db.powerBarColor = value
		elseif field == "tickMode" then
			db.powerBarTickMode = value
		elseif field == "tickCount" then
			db.powerBarTickCount = value
		elseif field == "tickAtStr" then
			db.powerBarTickAtStr = value
		elseif field == "tickMax" then
			db.powerBarTickMax = value
		elseif field == "tickColor" then
			db.powerBarTickColor = value
		end
	end
	db.powerBarProfiles[classFile] = db.powerBarProfiles[classFile] or {}
	db.powerBarProfiles[classFile][field] = value
end

local function EnsureColorCurve(profile)
	local points = Skin.ParsePowerBarCurvePoints(profile.curvePointsStr)
	if #points < 2 then
		if profile.curveMode == "percent" then
			points = DefaultCurvePointsPercent()
		else
			points = DefaultCurvePointsAbsolute()
		end
	end
	local fp = profile.curveMode .. "|" .. Skin.FormatPowerBarCurvePoints(points)
	if colorCurve and curveFingerprint == fp then
		return colorCurve
	end
	if not C_CurveUtil or not C_CurveUtil.CreateColorCurve then
		return nil
	end
	local curve = C_CurveUtil.CreateColorCurve()
	if curve.SetType and Enum and Enum.LuaCurveType then
		pcall(curve.SetType, curve, Enum.LuaCurveType.Linear)
	end
	if curve.ClearPoints then
		pcall(curve.ClearPoints, curve)
	end
	for i = 1, #points do
		local p = points[i]
		local col
		if CreateColor then
			col = CreateColor(p.r or 1, p.g or 1, p.b or 1, p.a or 1)
		end
		if col and curve.AddPoint then
			pcall(curve.AddPoint, curve, p.x or 0, col)
		end
	end
	colorCurve = curve
	curveFingerprint = fp
	return colorCurve
end

local function ApplyFillColor(bar, powerType, profile, fallbackR, fallbackG, fallbackB, fallbackA)
	local fr, fg, fb, fa = fallbackR, fallbackG, fallbackB, fallbackA or 1
	local mode = profile.colorMode or "class"

	if mode == "solid" then
		local c = profile.solidColor or {}
		fr, fg, fb, fa = c.r or fr, c.g or fg, c.b or fb, c.a or 1
	elseif mode == "curve" then
		local curve = EnsureColorCurve(profile)
		if curve then
			local ok, color
			if profile.curveMode == "percent" and UnitPowerPercent then
				ok, color = pcall(UnitPowerPercent, "player", powerType, false, curve)
				if (not ok or color == nil) and curve.Evaluate then
					local okp, pct = pcall(UnitPowerPercent, "player", powerType)
					if okp and pct ~= nil then
						ok, color = pcall(curve.Evaluate, curve, pct)
					end
				end
			else
				local okp, cur = pcall(UnitPower, "player", powerType)
				if okp and cur ~= nil and curve.Evaluate then
					ok, color = pcall(curve.Evaluate, curve, cur)
				end
			end
			if ok and color then
				if color.GetRGBA then
					fr, fg, fb, fa = color:GetRGBA()
				elseif color.GetRGB then
					fr, fg, fb = color:GetRGB()
					fa = 1
				elseif type(color) == "table" then
					fr, fg, fb, fa = color.r or fr, color.g or fg, color.b or fb, color.a or 1
				end
			end
		end
	end

	local st = bar:GetStatusBarTexture()
	if st then
		st:SetVertexColor(fr, fg, fb, fa)
	end
	pcall(bar.SetStatusBarColor, bar, fr, fg, fb, fa)
end

local function ResolveWidth(db)
	local w = db.powerBarWidth or 0
	if type(w) == "number" and w > 0 then
		return Pixel.Snap(w)
	end
	local laid = Skin.EssentialLayoutWidth
	if type(laid) == "number" and laid >= 40 then
		return Pixel.Snap(laid)
	end
	local essential = GCDM.ViewerRegistry and GCDM.ViewerRegistry:Essential()
	if essential then
		local ok, ew = pcall(essential.GetWidth, essential)
		if ok and type(ew) == "number" and ew >= 40 then
			return Pixel.Snap(ew)
		end
	end
	local size = db.sizeEssential or { w = 46 }
	local maxRow = db.maxIconsPerRow or 7
	local iw = Pixel.Snap(size.w or 46)
	local spacing = Pixel.Snap(db.spacing or 0)
	return (maxRow * iw) + ((maxRow - 1) * spacing)
end

local function EnsureBar(parent, name)
	local bar = CreateFrame("StatusBar", name, parent)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.1, 0.1, 0.1, 0.95)
	bar.GCDMBg = bg
	local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
	border:SetAllPoints()
	border:SetFrameLevel((bar:GetFrameLevel() or 0) + 5)
	bar.GCDMBorder = border
	local fs = bar:CreateFontString(nil, "OVERLAY")
	fs:SetPoint("CENTER")
	fs:SetJustifyH("CENTER")
	bar.GCDMText = fs
	bar.GCDMTicks = {}
	return bar
end

local function ClearTicks(bar)
	if not bar or not bar.GCDMTicks then
		return
	end
	for i = 1, #bar.GCDMTicks do
		bar.GCDMTicks[i]:Hide()
	end
end

local function ParseTickValues(str)
	local out = {}
	if type(str) ~= "string" then
		return out
	end
	for part in string.gmatch(str, "[^,%s]+") do
		local n = tonumber(part)
		if n then
			out[#out + 1] = n
		end
	end
	return out
end

local function LayoutTicks(bar, profile)
	ClearTicks(bar)
	if not bar or not profile or profile.tickMode == "none" then
		return
	end
	local tc = profile.tickColor or { r = 1, g = 1, b = 1, a = 0.55 }
	local ratios = {}
	if profile.tickMode == "equal" then
		local n = math.max(1, math.floor(profile.tickCount or 4))
		for i = 1, n - 1 do
			ratios[#ratios + 1] = i / n
		end
	elseif profile.tickMode == "values" then
		local maxV = profile.tickMax or 100
		if maxV <= 0 then
			maxV = 100
		end
		local vals = ParseTickValues(profile.tickAtStr or "")
		for i = 1, #vals do
			local r = vals[i] / maxV
			if r > 0 and r < 1 then
				ratios[#ratios + 1] = r
			end
		end
	end
	local w = bar:GetWidth() or 0
	if w < 2 then
		return
	end
	for i = 1, #ratios do
		local tick = bar.GCDMTicks[i]
		if not tick then
			tick = bar:CreateTexture(nil, "OVERLAY")
			bar.GCDMTicks[i] = tick
		end
		tick:SetColorTexture(tc.r or 1, tc.g or 1, tc.b or 1, tc.a or 0.55)
		tick:ClearAllPoints()
		tick:SetWidth(1)
		local x = w * ratios[i]
		tick:SetPoint("TOPLEFT", bar, "TOPLEFT", x, 0)
		tick:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x, 0)
		tick:Show()
	end
end

local function StyleBarChrome(bar, db, height)
	local tex = (Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(db.powerBarTexture or "Solid"))
		or GCDM.CONST.TEX_WHITE8X8
	local bgPath = (Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(db.powerBarBackgroundTexture or db.powerBarTexture or "Solid"))
		or GCDM.CONST.TEX_WHITE8X8
	local bgc = db.powerBarBackgroundColor or { r = 0.1, g = 0.1, b = 0.1, a = 0.95 }

	bar:SetHeight(Pixel.Snap(height))
	bar:SetStatusBarTexture(tex)
	local st = bar:GetStatusBarTexture()
	if st and Pixel.DisableTextureSnap then
		Pixel.DisableTextureSnap(st)
	end
	bar.GCDMBg:SetTexture(bgPath)
	bar.GCDMBg:SetVertexColor(bgc.r or 0.1, bgc.g or 0.1, bgc.b or 0.1, bgc.a or 0.95)
	if Pixel.DisableTextureSnap then
		Pixel.DisableTextureSnap(bar.GCDMBg)
	end

	local size = db.powerBarBorderSize
	if size == nil then
		size = 1
	end
	local bc = db.borderColor or { r = 0, g = 0, b = 0, a = 1 }
	local border = bar.GCDMBorder
	if size <= 0 then
		border:Hide()
	else
		pcall(border.SetBackdrop, border, {
			edgeFile = GCDM.CONST.TEX_WHITE8X8,
			edgeSize = size,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		pcall(border.SetBackdropBorderColor, border, bc.r or 0, bc.g or 0, bc.b or 0, bc.a or 1)
		border:Show()
	end

	local fontPath = Skin.FetchFont and Skin.FetchFont(db.textFont or "Expressway") or GCDM.CONST.FONT_PATH
	local fontSize = db.powerBarFontSize or 12
	local outline = db.textOutline or "OUTLINE"
	if outline == "NONE" then
		outline = ""
	end
	pcall(bar.GCDMText.SetFont, bar.GCDMText, fontPath, fontSize, outline)
	local tc = db.powerBarTextColor or { r = 1, g = 1, b = 1, a = 1 }
	bar.GCDMText:SetTextColor(tc.r or 1, tc.g or 1, tc.b or 1, tc.a or 1)
	bar.GCDMText:SetShown(db.powerBarShowText ~= false)
end

local function EnsureHost()
	if host then
		return host
	end
	host = CreateFrame("Frame", "GCDM_PowerBarHost", UIParent)
	host:SetSize(200, 20)
	host:SetFrameStrata("MEDIUM")
	host:SetFrameLevel(500)
	primaryBar = EnsureBar(host, "GCDM_PowerBarPrimary")
	primaryBar:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
	primaryBar:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, 0)
	primaryText = primaryBar.GCDMText
	secondaryBar = EnsureBar(host, "GCDM_PowerBarSecondary")
	secondaryBar:SetPoint("TOPLEFT", primaryBar, "BOTTOMLEFT", 0, -1)
	secondaryBar:SetPoint("TOPRIGHT", primaryBar, "BOTTOMRIGHT", 0, -1)
	secondaryText = secondaryBar.GCDMText
	secondaryBar:Hide()
	return host
end

local function FindSecondaryPowerType(primaryType)
	local _, classFile = UnitClass("player")
	local key = classFile and CLASS_SECONDARY[classFile]
	local pt = key and PowerEnum(key) or nil
	if not pt or pt == primaryType then
		return nil
	end
	local ok, maxP = pcall(UnitPowerMax, "player", pt)
	if not ok or maxP == nil then
		return nil
	end
	if issecretvalue and issecretvalue(maxP) then
		return pt
	end
	if canaccessvalue and not canaccessvalue(maxP) then
		return pt
	end
	if type(maxP) == "number" and maxP > 0 then
		return pt
	end
	return nil
end

local function UpdateBarValues(bar, text, powerType, showText, profile)
	if not bar or powerType == nil then
		return
	end
	-- Absolute fill when curve/ticks are absolute-oriented; else percent.
	local preferAbsolute = profile and profile.colorMode == "curve" and profile.curveMode == "absolute"
	if preferAbsolute then
		local okCur, cur = pcall(UnitPower, "player", powerType)
		local okMax, maxP = pcall(UnitPowerMax, "player", powerType)
		if okMax and maxP ~= nil then
			pcall(bar.SetMinMaxValues, bar, 0, maxP)
		else
			local tickMax = (profile and profile.tickMax) or 100
			pcall(bar.SetMinMaxValues, bar, 0, tickMax)
		end
		if okCur and cur ~= nil then
			pcall(bar.SetValue, bar, cur)
		end
	elseif UnitPowerPercent then
		local ok, pct = pcall(UnitPowerPercent, "player", powerType)
		if ok and pct ~= nil then
			pcall(bar.SetMinMaxValues, bar, 0, 1)
			pcall(bar.SetValue, bar, pct)
		end
	else
		local okCur, cur = pcall(UnitPower, "player", powerType)
		local okMax, maxP = pcall(UnitPowerMax, "player", powerType)
		if okMax and maxP ~= nil then
			pcall(bar.SetMinMaxValues, bar, 0, maxP)
		end
		if okCur and cur ~= nil then
			pcall(bar.SetValue, bar, cur)
		end
	end
	if text and showText then
		local ok, cur = pcall(UnitPower, "player", powerType)
		if ok and cur ~= nil then
			pcall(text.SetText, text, cur)
		else
			text:SetText("")
		end
	elseif text then
		text:SetText("")
	end
end

local function NudgeBuffBarAbovePower(db, h, gap)
	local registry = GCDM.ViewerRegistry
	local buffBar = registry and registry:BuffBar()
	if not buffBar or not buffBar:IsShown() then
		return
	end
	local cfg = db.viewerPos and db.viewerPos.buffBar
	if cfg and cfg.enabled then
		return
	end
	if GCDM.IsEditModeActive and GCDM:IsEditModeActive() then
		return
	end
	local lift = Pixel.Snap(gap or 1)
	buffBar:ClearAllPoints()
	buffBar:SetPoint("BOTTOMLEFT", h, "TOPLEFT", 0, lift)
	buffBar:SetPoint("BOTTOMRIGHT", h, "TOPRIGHT", 0, lift)
end

local function AnchorHost(db)
	local h = EnsureHost()
	local essential = GCDM.ViewerRegistry and GCDM.ViewerRegistry:Essential()
	local width = ResolveWidth(db)
	local height = Pixel.Snap(db.powerBarHeight or 10)
	local gap = Pixel.Snap(db.powerBarGap or 2)
	local showSecondary = secondaryBar and secondaryBar:IsShown()
	local hostH = height
	if showSecondary then
		hostH = height + 1 + height
	end
	h:SetSize(width, hostH)
	primaryBar:SetHeight(height)
	if showSecondary then
		secondaryBar:SetHeight(height)
	end

	h:ClearAllPoints()
	if essential then
		local strata = essential:GetFrameStrata()
		if strata then
			h:SetFrameStrata(strata)
		end
		h:SetFrameLevel(math.max((essential:GetFrameLevel() or 0) + 20, 100))
		h:SetPoint("BOTTOMLEFT", essential, "TOPLEFT", 0, gap)
		h:SetPoint("BOTTOMRIGHT", essential, "TOPRIGHT", 0, gap)
		NudgeBuffBarAbovePower(db, h, 1)
	else
		h:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
		h:SetWidth(width)
	end
	Skin.PowerBarHostHeight = hostH + gap
end

local function ApplyPowerBars()
	if applying then
		queued = true
		return
	end
	applying = true
	queued = false
	local ok, err = pcall(function()
		local db = GCDM:GetDB()
		if not db or not db.enabled or db.powerBarEnabled == false then
			if host then
				host:Hide()
			end
			Skin.PowerBarHostHeight = 0
			return
		end
		if GCDM.IsEditModeActive and GCDM:IsEditModeActive() then
			if host then
				host:Hide()
			end
			return
		end

		Pixel.Update()
		EnsureHost()

		local profile = Skin.GetPowerBarProfile(db, PlayerClassFile())
		local primaryType, primaryToken, altR, altG, altB = UnitPowerType("player")
		if primaryType == nil then
			primaryType = PowerEnum("Energy") or PowerEnum("Rage") or 3
			primaryToken = primaryToken or "ENERGY"
		end

		local pr, pg, pb, pa = SafePowerColor(primaryType, primaryToken, altR, altG, altB)
		local height = db.powerBarHeight or 10
		StyleBarChrome(primaryBar, db, height)
		UpdateBarValues(primaryBar, primaryText, primaryType, db.powerBarShowText ~= false, profile)
		ApplyFillColor(primaryBar, primaryType, profile, pr, pg, pb, pa)
		LayoutTicks(primaryBar, profile)
		primaryBar:Show()

		local secondaryType = nil
		if db.powerBarShowSecondary ~= false then
			secondaryType = FindSecondaryPowerType(primaryType)
		end
		if secondaryType then
			local sr, sg, sb, sa = SafePowerColor(secondaryType, nil)
			StyleBarChrome(secondaryBar, db, height)
			-- Secondary uses class/solid only (no curve) unless same profile curve requested.
			local secProfile = {
				colorMode = (profile.colorMode == "curve") and "class" or profile.colorMode,
				solidColor = profile.solidColor,
				tickMode = "none",
			}
			UpdateBarValues(secondaryBar, secondaryText, secondaryType, db.powerBarShowText ~= false, secProfile)
			ApplyFillColor(secondaryBar, secondaryType, secProfile, sr, sg, sb, sa)
			ClearTicks(secondaryBar)
			secondaryBar:Show()
		else
			secondaryBar:Hide()
			if secondaryText then
				secondaryText:SetText("")
			end
		end

		AnchorHost(db)
		LayoutTicks(primaryBar, profile)
		host:Show()
		host:SetAlpha(1)
	end)
	applying = false
	if not ok and not GCDM._powerBarErrOnce then
		GCDM._powerBarErrOnce = true
		print("|cff3bb273GCDM|r PowerBar error: " .. tostring(err))
	end
	if queued then
		queued = false
		C_Timer.After(0, ApplyPowerBars)
	end
end

local function EnsureEvents()
	if eventsFrame then
		return
	end
	eventsFrame = CreateFrame("Frame")
	eventsFrame:SetScript("OnEvent", function(_, event, unit)
		if unit and unit ~= "player" then
			return
		end
		if event == "UNIT_POWER_UPDATE"
			or event == "UNIT_MAXPOWER"
			or event == "UNIT_DISPLAYPOWER"
			or event == "PLAYER_ENTERING_WORLD"
			or event == "PLAYER_SPECIALIZATION_CHANGED"
			or event == "PLAYER_LOGIN" then
			ApplyPowerBars()
		end
	end)
	eventsFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
	eventsFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
	eventsFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
	eventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventsFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	eventsFrame:RegisterEvent("PLAYER_LOGIN")
end

GCDM:RegisterRefreshCallback("Skin.PowerBar", function()
	curveFingerprint = nil
	EnsureEvents()
	ApplyPowerBars()
end, 48, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.LAYOUT,
	GCDM.CONST.REFRESH.STYLE,
})

Skin.QueuePowerBarRelayout = function()
	C_Timer.After(0, ApplyPowerBars)
end

Skin.PowerBarClassFiles = CLASS_FILES

function GCDM:GetPowerBarHost()
	return host
end
