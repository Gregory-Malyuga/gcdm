local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

local relayoutQueued = false
local QueuePostBlizzardLayout

local function RowWidth(count, itemW, gap)
	if count <= 0 then
		return 0
	end
	return (count * itemW) + ((count - 1) * gap)
end

local function CenteredX(col, itemW, gap, containerW, rowW)
	local startX = (containerW - rowW) * 0.5
	return startX + (col * (itemW + gap))
end

local function LayoutIndexOf(frame)
	local idx = frame and frame.layoutIndex
	if type(idx) == "number" then
		return idx
	end
	return 0
end

local function SortIconsStable(icons)
	table.sort(icons, function(a, b)
		local ai = LayoutIndexOf(a)
		local bi = LayoutIndexOf(b)
		if ai ~= bi then
			return ai < bi
		end
		local ay = a:GetTop() or 0
		local by = b:GetTop() or 0
		if math.abs(ay - by) > 1 then
			return ay > by
		end
		return (a:GetLeft() or 0) < (b:GetLeft() or 0)
	end)
end

local function HasDrawableIcon(frame)
	local icon = Skin.GetIconTexture(frame)
	if not icon then
		return false
	end
	local ok, tex = pcall(function()
		return icon:GetTexture()
	end)
	if ok and tex ~= nil then
		if canaccessvalue and not canaccessvalue(tex) then
			return true
		end
		local okCmp, empty = pcall(function()
			return tex == "" or tex == 0
		end)
		if not okCmp then
			return true
		end
		if not empty then
			return true
		end
	end
	-- Some CDM icons use atlas only.
	if icon.GetAtlas then
		local okA, atlas = pcall(icon.GetAtlas, icon)
		if okA and atlas and atlas ~= "" then
			if canaccessvalue and not canaccessvalue(atlas) then
				return true
			end
			return true
		end
	end
	return false
end

-- Blizzard RefreshLayout keeps re-SetPoint'ing placed icons; snap back to our anchor.
-- Do NOT snap parked (-10000) slots — aura Show without RefreshLayout would trap them off-screen.
local function InstallAnchorSnapBack(frame)
	if frame.GCDMSnapHooked then
		return
	end
	frame.GCDMSnapHooked = true
	hooksecurefunc(frame, "SetPoint", function(self)
		if self.GCDMParked or self.GCDMApplyingAnchor then
			return
		end
		local a = self.GCDMAnchor
		if not a then
			return
		end
		self.GCDMApplyingAnchor = true
		self:ClearAllPoints()
		self:SetPoint(a[1], a[2], a[3], a[4], a[5])
		self.GCDMApplyingAnchor = false
	end)
end

local function EnsureIconLifecycleHooks(frame)
	if not frame or frame.GCDMIconLifeHooked then
		return
	end
	frame.GCDMIconLifeHooked = true
	frame:HookScript("OnShow", function(self)
		self.GCDMParked = false
		if self.GCDMAnchor and self.GCDMAnchor[4] == -10000 then
			self.GCDMAnchor = nil
		end
		self:SetAlpha(1)
		QueuePostBlizzardLayout()
	end)
end

local function ParkEmptyIcon(frame, viewer)
	if not frame then
		return
	end
	EnsureIconLifecycleHooks(frame)
	InstallAnchorSnapBack(frame)
	frame.GCDMParked = true
	frame.GCDMAnchor = nil
	frame.GCDMApplyingAnchor = true
	frame:ClearAllPoints()
	if viewer then
		frame:SetPoint("TOPLEFT", viewer, "TOPLEFT", -10000, 0)
	end
	frame.GCDMApplyingAnchor = false
	frame:SetAlpha(0)
end

local function CollectShownIcons(viewer)
	local raw = Skin.CollectIconFrames(viewer)
	local out = {}
	for i = 1, #raw do
		local frame = raw[i]
		if frame then
			EnsureIconLifecycleHooks(frame)
			local okDraw, drawable = pcall(HasDrawableIcon, frame)
			-- Park hidden / empty placeholders (CDM includeAsLayoutChildWhenHidden).
			if frame:IsShown() and okDraw and drawable then
				out[#out + 1] = frame
			else
				pcall(ParkEmptyIcon, frame, viewer)
			end
		end
	end
	SortIconsStable(out)
	return out
end

local function PlaceIcon(frame, viewer, x, y, w, h, row)
	EnsureIconLifecycleHooks(frame)
	frame.GCDMParked = false
	frame.GCDMRow = row
	frame:SetAlpha(1)
	frame:SetSize(w, h)
	frame.GCDMApplyingAnchor = true
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", viewer, "TOPLEFT", x, y)
	frame.GCDMApplyingAnchor = false
	frame.GCDMAnchor = { "TOPLEFT", viewer, "TOPLEFT", x, y }
	InstallAnchorSnapBack(frame)
end

local function SnapGap(value)
	local v = tonumber(value) or 0
	if v <= 0 then
		return 0
	end
	if not Pixel.IsSnapEnabled() then
		return v
	end
	local snapped = Pixel.Snap(v)
	-- Avoid collapsing a positive gap to 0 on coarse pixel scales.
	local px = Pixel.GetSize()
	if snapped < px then
		snapped = px
	end
	return snapped
end

local function LayoutEssential(viewer, db)
	local icons = CollectShownIcons(viewer)
	local total = #icons
	if total == 0 then
		return
	end

	local spacing = SnapGap(db.spacing or 0)
	local maxRow = db.maxIconsPerRow or 7
	if maxRow < 1 then
		maxRow = 1
	end

	local row1 = db.sizeEssential or { w = 46, h = 40 }
	local row2 = db.sizeEssentialRow2 or row1
	local row1W, row1H = Pixel.Snap(row1.w), Pixel.Snap(row1.h)
	local row2W, row2H = Pixel.Snap(row2.w), Pixel.Snap(row2.h)

	local row1Count = math.min(maxRow, total)
	local row2Count = math.max(0, total - maxRow)
	local row1Width = RowWidth(row1Count, row1W, spacing)
	local row2Width = RowWidth(row2Count, row2W, spacing)
	local containerW = math.max(row1Width, row2Width)
	local containerH = row1H
	if row2Count > 0 then
		containerH = row1H + spacing + row2H
	end

	viewer:SetSize(Pixel.Snap(containerW), Pixel.Snap(containerH))
	-- Full configured row width for BuffBar (not actual icon count).
	Skin.EssentialLayoutWidth = Pixel.Snap(RowWidth(maxRow, row1W, spacing))

	for i = 1, total do
		local frame = icons[i]
		local w, h, x, y, row
		if i <= maxRow then
			row = 1
			w, h = row1W, row1H
			x = CenteredX(i - 1, row1W, spacing, containerW, row1Width)
			y = 0
		else
			row = 2
			w, h = row2W, row2H
			x = CenteredX(i - maxRow - 1, row2W, spacing, containerW, row2Width)
			y = -(row1H + spacing)
		end
		PlaceIcon(frame, viewer, x, y, w, h, row)
	end
end

local function LayoutSimpleRow(viewer, db, size)
	local icons = CollectShownIcons(viewer)
	local total = #icons
	if total == 0 or not size then
		return
	end

	local spacing = SnapGap(db.spacing or 0)
	local w, h = Pixel.Snap(size.w), Pixel.Snap(size.h)
	local width = RowWidth(total, w, spacing)
	viewer:SetSize(Pixel.Snap(width), h)

	for i = 1, total do
		local frame = icons[i]
		local x = (i - 1) * (w + spacing)
		PlaceIcon(frame, viewer, x, 0, w, h, 1)
	end
end

local function ApplyLayout()
	Pixel.Update()
	local db = GCDM:GetDB()
	if not db or not db.enabled then
		return
	end
	if GCDM.IsEditModeActive and GCDM:IsEditModeActive() then
		return
	end

	-- One-shot: old default spacing=1 was inflated to ~2px by SnapGap floor.
	if db.spacingTightDefault == nil then
		db.spacingTightDefault = true
		if db.spacing == nil or db.spacing == 1 then
			db.spacing = 0
		end
	end
	-- Match buff icon row to Essential size (was 40×36).
	if db.buffIconSizeSynced == nil then
		db.buffIconSizeSynced = true
		local sb = db.sizeBuff
		if sb and sb.w == 40 and sb.h == 36 then
			sb.w, sb.h = 46, 40
		end
	end

	local registry = GCDM.ViewerRegistry
	local essential = registry:Essential()
	if essential then
		LayoutEssential(essential, db)
	end

	local utility = registry:Utility()
	if utility then
		LayoutSimpleRow(utility, db, db.sizeUtility)
	end

	local buff = registry:Buff()
	if buff then
		LayoutSimpleRow(buff, db, db.sizeBuff)
	end

	-- Bars follow Essential width after empties are parked.
	if Skin.QueueBuffBarRelayout then
		Skin.QueueBuffBarRelayout()
	end
	if Skin.QueuePowerBarRelayout then
		Skin.QueuePowerBarRelayout()
	end
end

QueuePostBlizzardLayout = function()
	if relayoutQueued then
		return
	end
	relayoutQueued = true
	C_Timer.After(0, function()
		relayoutQueued = false
		if GCDM.IsEditModeActive and GCDM:IsEditModeActive() then
			return
		end
		-- Positions only — avoid STYLE churn that fights Blizzard every tick.
		ApplyLayout()
	end)
end

local function HookViewerRefreshLayout(viewer)
	if not viewer or viewer.GCDMRefreshLayoutHooked then
		return
	end
	viewer.GCDMRefreshLayoutHooked = true
	if viewer.RefreshLayout then
		hooksecurefunc(viewer, "RefreshLayout", function()
			QueuePostBlizzardLayout()
		end)
	end
end

local function HookAllViewers()
	local registry = GCDM.ViewerRegistry
	if not registry then
		return
	end
	local names = GCDM.CONST.MANAGED_VIEWER_NAMES
	for i = 1, #names do
		HookViewerRefreshLayout(registry:Get(names[i]))
	end
end

GCDM:RegisterRefreshCallback("Skin.Layout", function()
	HookAllViewers()
	ApplyLayout()
end, 35, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.LAYOUT,
	GCDM.CONST.REFRESH.STYLE,
})
