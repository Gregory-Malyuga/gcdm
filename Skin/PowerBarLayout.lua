-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- Power bar host + Essential/buff anchors.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel
local Chrome = Skin.PowerBarChrome

local PowerBarLayout = {}
Skin.PowerBarLayout = PowerBarLayout

local host
local primaryBar
local primaryText
local secondaryBar
local secondaryText

local function MinBarWidth()
	return Skin.BarWidth and Skin.BarWidth.Min() or ((GCDM.CONST and GCDM.CONST.MIN_BAR_WIDTH) or 200)
end

local function ResolveWidth(db)
	if Skin.BarWidth and Skin.BarWidth.Resolve then
		return Skin.BarWidth.Resolve(db, "powerBarFollowEssential", "powerBarWidth")
	end
	local w = db.powerBarWidth or MinBarWidth()
	if Skin.BarWidth and Skin.BarWidth.Clamp then
		return Skin.BarWidth.Clamp(w)
	end
	return Pixel.Snap(tonumber(w) or 0)
end

function PowerBarLayout.GetHost()
	return host
end

function PowerBarLayout.GetBars()
	return primaryBar, secondaryBar, primaryText, secondaryText
end

function PowerBarLayout.EnsureHost()
	if host then
		return host
	end
	host = CreateFrame("Frame", "GCDM_PowerBarHost", UIParent)
	host:SetSize(200, 20)
	host:SetFrameStrata("MEDIUM")
	host:SetFrameLevel((GCDM.CONST and GCDM.CONST.HOST_FRAME_LEVEL) or 100)
	primaryBar = Chrome.EnsureBar(host, "GCDM_PowerBarPrimary")
	primaryBar:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
	primaryBar:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, 0)
	primaryText = primaryBar.GCDMText
	secondaryBar = Chrome.EnsureBar(host, "GCDM_PowerBarSecondary")
	secondaryBar:SetPoint("TOPLEFT", primaryBar, "BOTTOMLEFT", 0, -1)
	secondaryBar:SetPoint("TOPRIGHT", primaryBar, "BOTTOMRIGHT", 0, -1)
	secondaryText = secondaryBar.GCDMText
	secondaryBar:Hide()
	return host
end

local function NudgeBuffBarAbovePower(db, h, gap)
	local registry = GCDM.ViewerRegistry
	local buffBar = registry and registry:BuffBar()
	if not buffBar then
		return
	end
	if db.buffBarFollowEssential == false then
		return
	end
	local shownOk, isShown = pcall(buffBar.IsShown, buffBar)
	if shownOk and not isShown then
		return
	end
	local lift = Pixel.Snap(gap or 1)
	local inCombat = InCombatLockdown and InCombatLockdown()
	if inCombat then
		if Skin.LayoutMarkCombatPending then
			Skin.LayoutMarkCombatPending()
		end
		return
	else
		pcall(function()
			buffBar:ClearAllPoints()
			buffBar:SetPoint("BOTTOMLEFT", h, "TOPLEFT", 0, lift)
			buffBar:SetPoint("BOTTOMRIGHT", h, "TOPRIGHT", 0, lift)
		end)
	end
	buffBar.GCDMViewerAnchor = { "BOTTOMLEFT", h, "TOPLEFT", 0, lift }
	buffBar.GCDMViewerAnchor2 = { "BOTTOMRIGHT", h, "TOPRIGHT", 0, lift }
end

local function AnchorHostIndependent(db, h, width, hostH)
	h:SetFrameStrata("MEDIUM")
	h:SetFrameLevel((GCDM.CONST and GCDM.CONST.HOST_FRAME_LEVEL) or 100)
	h:SetSize(width, hostH)
	local cfg = db.viewerPos and db.viewerPos.powerBar
	local point = "CENTER"
	local x, y = 0, (GCDM.CONST and GCDM.CONST.DEFAULT_INDEPENDENT_BAR_Y) or -100
	if type(cfg) == "table" then
		point = cfg.point or point
		x = cfg.x or 0
		y = cfg.y or y
	end
	h:ClearAllPoints()
	h:SetPoint(point, UIParent, point, Pixel.Snap(x), Pixel.Snap(y))
	h.GCDMViewerAnchor = { point, UIParent, point, Pixel.Snap(x), Pixel.Snap(y) }
	h.GCDMViewerAnchor2 = nil
end

function PowerBarLayout.AnchorHost(db)
	local h = PowerBarLayout.EnsureHost()
	local essential = GCDM.ViewerRegistry and GCDM.ViewerRegistry:Essential()
	local width = ResolveWidth(db)
	local height = Pixel.Snap(db.powerBarHeight or (GCDM.CONST and GCDM.CONST.DEFAULT_POWER_BAR_HEIGHT) or 10)
	local gap = Pixel.Snap(db.powerBarGap or (GCDM.CONST and GCDM.CONST.DEFAULT_POWER_BAR_GAP) or 2)
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

	if db.powerBarFollowEssential == false then
		AnchorHostIndependent(db, h, width, hostH)
		Skin.PowerBarHostHeight = hostH
		return
	end

	h:ClearAllPoints()
	h.GCDMViewerAnchor = nil
	h.GCDMViewerAnchor2 = nil
	if essential then
		local strata = essential:GetFrameStrata()
		if strata then
			h:SetFrameStrata(strata)
		end
		h:SetFrameLevel(math.max((essential:GetFrameLevel() or 0) + 10, 100))
		local essW = essential.GetWidth and essential:GetWidth()
		local minW = MinBarWidth()
		if type(essW) == "number" and essW >= 40 and essW + 0.5 >= minW then
			width = essW
			h:SetSize(width, hostH)
			h:SetPoint("BOTTOMLEFT", essential, "TOPLEFT", 0, gap)
			h:SetPoint("BOTTOMRIGHT", essential, "TOPRIGHT", 0, gap)
		else
			width = math.max(width, minW)
			h:SetSize(width, hostH)
			h:SetPoint("BOTTOM", essential, "TOP", 0, gap)
		end
		NudgeBuffBarAbovePower(db, h, 1)
	else
		h:SetFrameStrata("MEDIUM")
		h:SetFrameLevel((GCDM.CONST and GCDM.CONST.HOST_FRAME_LEVEL) or 100)
		local fallbackY = (GCDM.CONST and GCDM.CONST.DEFAULT_INDEPENDENT_BAR_Y) or -100
		h:SetPoint("CENTER", UIParent, "CENTER", 0, fallbackY)
	end
	Skin.PowerBarHostHeight = hostH + gap
end
