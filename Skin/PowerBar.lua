-- Player power bar above Essential — apply + events (glue).
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel
local Curve = Skin.PowerBarCurve
local Chrome = Skin.PowerBarChrome
local Layout = Skin.PowerBarLayout
local eventsFrame, applying, queued = nil, false, false
local CLASS_FILES = {
	"DEFAULT", "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT",
	"SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER",
}

local function PowerEnum(key)
	local pt = Enum and Enum.PowerType and Enum.PowerType[key]
	return (type(pt) == "number") and pt or nil
end

local function PlayerClassFile()
	local _, classFile = UnitClass("player")
	return classFile or "DEFAULT"
end

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
			local h = Layout.EnsureHost()
			h:Hide()
			Skin.PowerBarHostHeight = 0
			if Skin.PlaceBuffBarViewer then
				Skin.PlaceBuffBarViewer(db)
			end
			return
		end
		Pixel.Update()
		local host = Layout.EnsureHost()
		local primaryBar, secondaryBar, primaryText, secondaryText = Layout.GetBars()
		local profile = Skin.GetPowerBarProfile(db, PlayerClassFile())
		local primaryType, primaryToken, altR, altG, altB
		do
			local okType, a, b, c, d, e = pcall(UnitPowerType, "player")
			if okType then
				primaryType, primaryToken, altR, altG, altB = a, b, c, d, e
			end
		end
		local typeUsable = false
		pcall(function()
			typeUsable = primaryType ~= nil
		end)
		if not typeUsable then
			primaryType = PowerEnum("Rage") or PowerEnum("Energy") or 1
			primaryToken = "RAGE"
		end

		local pr, pg, pb, pa = SafePowerColor(primaryType, primaryToken, altR, altG, altB)
		local height = db.powerBarHeight or (GCDM.CONST and GCDM.CONST.DEFAULT_POWER_BAR_HEIGHT) or 10
		if type(height) ~= "number" or height < 1 then
			height = (GCDM.CONST and GCDM.CONST.DEFAULT_POWER_BAR_HEIGHT) or 10
		end
		Chrome.StyleBarChrome(primaryBar, db, height)
		Layout.UpdateBarValues(primaryBar, primaryText, primaryType, db.powerBarShowText ~= false)
		Curve.ApplyFillColor(primaryBar, primaryType, profile, pr, pg, pb, pa)
		Chrome.LayoutTicks(primaryBar, profile)
		primaryBar:Show()
		primaryBar:SetAlpha(1)

		local secondaryType = nil
		if db.powerBarShowSecondary ~= false then
			local okSec, sec = pcall(Layout.FindSecondaryPowerType, primaryType)
			if okSec then
				secondaryType = sec
			end
		end
		if secondaryType then
			local sr, sg, sb, sa = SafePowerColor(secondaryType, nil)
			Chrome.StyleBarChrome(secondaryBar, db, height)
			local secProfile = {
				colorMode = (profile.colorMode == "curve") and "class" or profile.colorMode,
				solidColor = profile.solidColor,
				tickMode = "none",
			}
			Layout.UpdateBarValues(secondaryBar, secondaryText, secondaryType, db.powerBarShowText ~= false)
			Curve.ApplyFillColor(secondaryBar, secondaryType, secProfile, sr, sg, sb, sa)
			Chrome.ClearTicks(secondaryBar)
			secondaryBar:Show()
			secondaryBar:SetAlpha(1)
		else
			secondaryBar:Hide()
			Chrome.SafeSetText(secondaryText, "")
		end

		Layout.AnchorHost(db)
		Chrome.LayoutTicks(primaryBar, profile)
		host:Show()
		host:SetAlpha(1)
	end)
	applying = false
	if not ok then
		print("|cff3bb273GCDM|r PowerBar error: " .. tostring(err))
		local db = GCDM:GetDB()
		if db and db.enabled and db.powerBarEnabled ~= false then
			pcall(function()
				local host = Layout.EnsureHost()
				local primaryBar = Layout.GetBars()
				local profile = Skin.GetPowerBarProfile(db, PlayerClassFile())
				local pt = PowerEnum("Rage") or PowerEnum("Energy") or 1
				local pr, pg, pb, pa = SafePowerColor(pt, "RAGE")
				local h = db.powerBarHeight or (GCDM.CONST and GCDM.CONST.DEFAULT_POWER_BAR_HEIGHT) or 10
				Chrome.StyleBarChrome(primaryBar, db, h)
				Layout.UpdateBarValues(primaryBar, primaryBar.GCDMText, pt, db.powerBarShowText ~= false)
				Curve.ApplyFillColor(primaryBar, pt, profile, pr, pg, pb, pa)
				primaryBar:Show()
				Layout.AnchorHost(db)
				host:Show()
				host:SetAlpha(1)
			end)
		end
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
		if event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER"
			or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED"
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
	if Curve.Reset then
		Curve.Reset()
	end
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
	return Layout.GetHost()
end
