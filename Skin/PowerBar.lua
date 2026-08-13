local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

-- Player power bar (rage/energy/…) above Essential, below BuffBar strips.
-- Secret-safe: prefer UnitPowerPercent + SetValue; never compare/index secrets.

local host
local primaryBar
local primaryText
local secondaryBar
local secondaryText
local eventsFrame
local applying = false
local queued = false

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
	-- Prefer string token (RAGE/ENERGY/…) — not secret. Never use secret as table key.
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
		return PowerBarColor and PowerBarColor["RAGE"] or nil
	end)
	if ok and c then
		return c.r or 0.6, c.g or 0.1, c.b or 0.1, 1
	end
	return 0.78, 0.1, 0.1, 1
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
	return bar
end

local function StyleBar(bar, db, height, fr, fg, fb, fa)
	local tex = (Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(db.powerBarTexture or "Solid"))
		or GCDM.CONST.TEX_WHITE8X8
	local bgPath = (Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(db.powerBarBackgroundTexture or db.powerBarTexture or "Solid"))
		or GCDM.CONST.TEX_WHITE8X8
	local bgc = db.powerBarBackgroundColor or { r = 0.1, g = 0.1, b = 0.1, a = 0.95 }

	bar:SetHeight(Pixel.Snap(height))
	bar:SetStatusBarTexture(tex)
	local st = bar:GetStatusBarTexture()
	if st then
		if Pixel.DisableTextureSnap then
			Pixel.DisableTextureSnap(st)
		end
		st:SetVertexColor(fr, fg, fb, fa or 1)
	end
	pcall(bar.SetStatusBarColor, bar, fr, fg, fb, fa or 1)
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
		-- Known class resource: still show; SetValue accepts secrets.
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

local function UpdateBarValues(bar, text, powerType, showText)
	if not bar or powerType == nil then
		return
	end
	-- Prefer percent API (Midnight-friendly for StatusBar).
	if UnitPowerPercent then
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
		else
			pcall(bar.SetMinMaxValues, bar, 0, 1)
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
	-- Respect explicit UIParent coordinates for BuffBar.
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
		-- Above Essential icons; BuffBar is nudged above this host.
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

		local primaryType, primaryToken, altR, altG, altB = UnitPowerType("player")
		-- Warrior / fallback: ensure we always have a numeric power type.
		if primaryType == nil then
			primaryType = PowerEnum("Rage") or 1
			primaryToken = primaryToken or "RAGE"
		end

		local pr, pg, pb, pa = SafePowerColor(primaryType, primaryToken, altR, altG, altB)
		if db.powerBarUseCustomColor then
			local c = db.powerBarColor or {}
			pr, pg, pb, pa = c.r or pr, c.g or pg, c.b or pb, c.a or 1
		end
		local height = db.powerBarHeight or 10
		StyleBar(primaryBar, db, height, pr, pg, pb, pa)
		UpdateBarValues(primaryBar, primaryText, primaryType, db.powerBarShowText ~= false)
		primaryBar:Show()

		local secondaryType = nil
		if db.powerBarShowSecondary ~= false then
			secondaryType = FindSecondaryPowerType(primaryType)
		end
		if secondaryType then
			local sr, sg, sb, sa = SafePowerColor(secondaryType, nil)
			if db.powerBarSecondaryUseCustomColor then
				local c = db.powerBarSecondaryColor or {}
				sr, sg, sb, sa = c.r or sr, c.g or sg, c.b or sb, c.a or 1
			end
			StyleBar(secondaryBar, db, height, sr, sg, sb, sa)
			UpdateBarValues(secondaryBar, secondaryText, secondaryType, db.powerBarShowText ~= false)
			secondaryBar:Show()
		else
			secondaryBar:Hide()
			if secondaryText then
				secondaryText:SetText("")
			end
		end

		AnchorHost(db)
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
	EnsureEvents()
	ApplyPowerBars()
end, 48, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.LAYOUT,
	GCDM.CONST.REFRESH.STYLE,
})

-- Defer so Layout → Queue does not nest inside an in-flight apply.
Skin.QueuePowerBarRelayout = function()
	C_Timer.After(0, ApplyPowerBars)
end

function GCDM:GetPowerBarHost()
	return host
end
