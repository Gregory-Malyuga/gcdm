local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Pixel = GCDM.Pixel
local VIEWERS = GCDM.CONST.VIEWERS

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

local VIEWER_KEYS = {
	{ key = "essential", name = VIEWERS.ESSENTIAL },
	{ key = "utility", name = VIEWERS.UTILITY },
	{ key = "buff", name = VIEWERS.BUFF },
	{ key = "buffBar", name = VIEWERS.BUFF_BAR },
}

local function NormalizePoint(point)
	if type(point) == "string" and ANCHOR_POINTS[point] then
		return point
	end
	return "CENTER"
end

local function GetPosConfig(db, key)
	local all = db and db.viewerPos
	local cfg = all and all[key]
	if type(cfg) ~= "table" then
		return nil
	end
	return cfg
end

local function InstallViewerSnap(viewer)
	if viewer.GCDMPosSnapHooked then
		return
	end
	viewer.GCDMPosSnapHooked = true
	hooksecurefunc(viewer, "SetPoint", function(self)
		local a = self.GCDMViewerAnchor
		if not a or self.GCDMApplyingViewerAnchor then
			return
		end
		if GCDM.ShouldDeferCDMLayout and GCDM:ShouldDeferCDMLayout() then
			return
		end
		-- In combat still restore BuffBar nudge (no ClearAllPoints — avoids orphan frames).
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
	end)
end

local function ClearViewerAnchor(viewer)
	if not viewer then
		return
	end
	viewer.GCDMViewerAnchor = nil
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

	if viewer.SetParent and viewer:GetParent() ~= UIParent then
		-- Keep Blizzard parent; only move via points.
	end
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
			if cfg and cfg.enabled then
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
	GCDM.CONST.REFRESH.STYLE,
})
