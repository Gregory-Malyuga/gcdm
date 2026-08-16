local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel
local VIEWERS = GCDM.CONST.VIEWERS
local AnchorUtil = Skin.AnchorUtil

local VIEWER_KEYS = {
	{ key = "essential", name = VIEWERS.ESSENTIAL },
	{ key = "utility", name = VIEWERS.UTILITY },
	{ key = "buff", name = VIEWERS.BUFF },
	{ key = "buffBar", name = VIEWERS.BUFF_BAR },
}

local function NormalizePoint(point)
	if AnchorUtil and AnchorUtil.NormalizePoint then
		return AnchorUtil.NormalizePoint(point, "CENTER")
	end
	return "CENTER"
end

local function DefaultIndependentY()
	return (GCDM.CONST and GCDM.CONST.DEFAULT_VIEWER_POS_Y) or 80
end

local function GetPosConfig(db, key)
	local all = db and db.viewerPos
	local cfg = all and all[key]
	if type(cfg) ~= "table" then
		return nil
	end
	return cfg
end

local function RestoreViewerAnchor(self)
	local a = self.GCDMViewerAnchor
	if not a then
		return
	end
	local inCombat = InCombatLockdown and InCombatLockdown()
	self.GCDMApplyingViewerAnchor = true
	if inCombat then
		pcall(function()
			self:SetPoint(a[1], a[2], a[3], a[4], a[5])
			local a2 = self.GCDMViewerAnchor2
			if a2 then
				self:SetPoint(a2[1], a2[2], a2[3], a2[4], a2[5])
			end
		end)
	else
		pcall(function()
			self:ClearAllPoints()
			self:SetPoint(a[1], a[2], a[3], a[4], a[5])
			local a2 = self.GCDMViewerAnchor2
			if a2 then
				self:SetPoint(a2[1], a2[2], a2[3], a2[4], a2[5])
			end
		end)
	end
	self.GCDMApplyingViewerAnchor = false
end

local function InstallViewerSnap(viewer)
	if viewer.GCDMPosSnapHooked then
		return
	end
	viewer.GCDMPosSnapHooked = true
	hooksecurefunc(viewer, "SetPoint", function(self)
		if GCDM.ShouldDeferCDMLayout and GCDM:ShouldDeferCDMLayout() then
			self.GCDMViewerAnchor = nil
			self.GCDMViewerAnchor2 = nil
			return
		end
		if not self.GCDMViewerAnchor or self.GCDMApplyingViewerAnchor then
			return
		end
		RestoreViewerAnchor(self)
	end)
end

local function ClearViewerAnchor(viewer)
	if not viewer then
		return
	end
	viewer.GCDMViewerAnchor = nil
	viewer.GCDMViewerAnchor2 = nil
end

local function ApplyViewerPosition(viewer, cfg)
	if not viewer or not cfg or cfg.enabled == false then
		ClearViewerAnchor(viewer)
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		return
	end
	if GCDM.ShouldDeferCDMLayout and GCDM:ShouldDeferCDMLayout() then
		return
	end

	Pixel.Update()
	local point = NormalizePoint(cfg.point)
	local x = Pixel.Snap(cfg.x or 0)
	local y = Pixel.Snap(cfg.y or 0)

	InstallViewerSnap(viewer)
	viewer.GCDMApplyingViewerAnchor = true
	pcall(function()
		viewer:ClearAllPoints()
		viewer:SetPoint(point, UIParent, point, x, y)
	end)
	viewer.GCDMApplyingViewerAnchor = false
	viewer.GCDMViewerAnchor = { point, UIParent, point, x, y }
end

local function ResolveBuffBarIndependentConfig(db, cfg)
	local fallbackY = DefaultIndependentY()
	local use = cfg or { enabled = true, point = "CENTER", x = 0, y = fallbackY }
	if not use.enabled then
		use = {
			enabled = true,
			point = use.point or "CENTER",
			x = use.x or 0,
			y = use.y or fallbackY,
		}
	end
	return use
end

local function ApplyPositions()
	local db = GCDM:GetDB()
	if not db or not db.enabled then
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		return
	end
	if GCDM.ShouldDeferCDMLayout and GCDM:ShouldDeferCDMLayout() then
		return
	end

	local registry = GCDM.ViewerRegistry
	for i = 1, #VIEWER_KEYS do
		local entry = VIEWER_KEYS[i]
		local viewer = registry:Get(entry.name)
		local cfg = GetPosConfig(db, entry.key)
		if viewer then
			local forceIndependent = entry.key == "buffBar" and db.buffBarFollowEssential == false
			if forceIndependent then
				ApplyViewerPosition(viewer, ResolveBuffBarIndependentConfig(db, cfg))
			elseif cfg and cfg.enabled then
				ApplyViewerPosition(viewer, cfg)
			else
				ClearViewerAnchor(viewer)
			end
		end
	end
end

GCDM:RegisterRefreshCallback("Skin.Position", ApplyPositions, 30, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.LAYOUT,
})
