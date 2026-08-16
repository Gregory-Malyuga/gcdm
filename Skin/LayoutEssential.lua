local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel
local Geom = Skin.LayoutGeometry

local buffCenterQueued = false

local function InCombat()
	return InCombatLockdown and InCombatLockdown()
end

function Skin.LayoutSafeViewerSetSize(viewer, w, h)
	if not viewer or not viewer.SetSize then return false end
	if InCombat() then
		if Skin.LayoutMarkCombatPending then Skin.LayoutMarkCombatPending() end
		return false
	end
	local ok = pcall(viewer.SetSize, viewer, w, h)
	if not ok and Skin.LayoutMarkCombatPending then Skin.LayoutMarkCombatPending() end
	return ok
end

function Skin.LayoutBuffIconsCentered(viewer)
	if not viewer or not Skin.LayoutIsBuffViewer(viewer) or Skin.LayoutShouldDefer() then return end
	local db = GCDM:GetDB()
	if not db or not db.enabled then return end
	local raw = Skin.CollectIconFrames(viewer)
	local active = {}
	for i = 1, #raw do
		local frame = raw[i]
		if frame then
			Skin.LayoutEnsureIconLifecycleHooks(frame)
			if Skin.LayoutIsIconActive(frame) then
				active[#active + 1] = frame
			else
				frame.GCDMAnchor = nil
			end
		end
	end
	Skin.LayoutSortIconsStable(active)
	local spacing = Geom.NormalizeSpacing(db.spacing or 0)
	local overlap = Geom.BorderOverlap(db, spacing)
	local w, h = Skin.LayoutResolveIconSize(active[1], db.sizeBuff)
	local total = #active
	if total == 0 then
		Skin.LayoutSafeViewerSetSize(viewer, Pixel.Snap(w), Pixel.Snap(h))
		return
	end
	local width = Pixel.Snap(Geom.UniformRowWidth(total, w, spacing, overlap))
	Skin.LayoutSafeViewerSetSize(viewer, width, Pixel.Snap(h))
	local startX = Geom.RowOriginX(width, width)
	local stride = Geom.IconStride(w, spacing, overlap)
	for i = 1, total do
		Skin.LayoutPlaceIcon(active[i], viewer, startX + (i - 1) * stride, 0, w, h, 1, { keepSize = true })
	end
end

function Skin.QueueBuffCenterLayout(viewer)
	if not viewer or buffCenterQueued then return end
	buffCenterQueued = true
	C_Timer.After(0, function()
		buffCenterQueued = false
		Skin.LayoutBuffIconsCentered(viewer)
	end)
end

function Skin.LayoutEssential(viewer, db)
	local icons = Skin.LayoutCollectShownIcons(viewer)
	local total = #icons
	local spacing = Geom.NormalizeSpacing(db.spacing or 0)
	local overlap = Geom.BorderOverlap(db, spacing)
	local maxRow = db.maxIconsPerRow or Geom.DEFAULT_MAX_ICONS_PER_ROW
	if maxRow < 1 then maxRow = 1 end
	local row1W, row1H = Geom.SnapIconSize(db.sizeEssential)
	local row2W, row2H = Geom.SnapIconSize(db.sizeEssentialRow2 or db.sizeEssential)
	if total == 0 then
		Skin.LayoutSafeViewerSetSize(viewer, row1W, row1H)
		Skin.EssentialLayoutWidth = Skin.EssentialWidthFormula(db)
		return
	end
	local row1Count = math.min(maxRow, total)
	local row2Count = math.max(0, total - maxRow)
	local row1Width = Geom.EssentialRowWidth(row1Count, row1W, spacing, overlap)
	local row2Width = Geom.EssentialRowWidth(row2Count, row2W, spacing, overlap)
	local wantW = Pixel.Snap(math.max(row1Width, row2Width))
	local containerH = row1H
	if row2Count > 0 then containerH = Geom.StackedRowHeight(row1H, row2H, spacing, overlap) end
	containerH = Pixel.Snap(containerH)
	Skin.LayoutSafeViewerSetSize(viewer, wantW, containerH)
	Skin.EssentialLayoutWidth = wantW
	local row2Y = Geom.SecondRowOffsetY(row1H, spacing, overlap)
	for i = 1, total do
		local frame = icons[i]
		local w, h, x, y, row
		if i <= maxRow then
			row, w, h = 1, row1W, row1H
			x = Geom.EssentialColumnX(i - 1, row1Count, row1W, spacing, overlap, row1Width, wantW)
			y = 0
		else
			row, w, h = 2, row2W, row2H
			x = Geom.EssentialColumnX(i - maxRow - 1, row2Count, row2W, spacing, overlap, row2Width, wantW)
			y = row2Y
		end
		Skin.LayoutPlaceIcon(frame, viewer, x, y, w, h, row)
	end
end

function Skin.LayoutSimpleRow(viewer, db, size)
	local icons = Skin.LayoutCollectShownIcons(viewer)
	local total = #icons
	if not size then return end
	local spacing = Geom.NormalizeSpacing(db.spacing or 0)
	local overlap = Geom.BorderOverlap(db, spacing)
	local w, h = Pixel.Snap(size.w), Pixel.Snap(size.h)
	if total == 0 then
		Skin.LayoutSafeViewerSetSize(viewer, Pixel.Snap(w), h)
		return
	end
	local width = Pixel.Snap(Geom.UniformRowWidth(total, w, spacing, overlap))
	Skin.LayoutSafeViewerSetSize(viewer, width, h)
	local startX = Geom.RowOriginX(width, width)
	local stride = Geom.IconStride(w, spacing, overlap)
	for i = 1, total do
		Skin.LayoutPlaceIcon(icons[i], viewer, startX + (i - 1) * stride, 0, w, h, 1)
	end
end
