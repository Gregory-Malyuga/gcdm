-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- Pure layout math for CDM icon rows (no frame mutation).
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

local Geom = {}
Skin.LayoutGeometry = Geom

Geom.DEFAULT_ICON_WIDTH = 46
Geom.DEFAULT_ICON_HEIGHT = 40
Geom.DEFAULT_BORDER_SIZE = (GCDM.CONST and GCDM.CONST.DEFAULT_BORDER_SIZE) or 1
Geom.DEFAULT_MAX_ICONS_PER_ROW = 7
--- Shrink first↔second and penultimate↔last gaps on Essential rows by this many UI units.
Geom.ESSENTIAL_END_GAP_TRIM = 0.5
--- Ignore sub-pixel width drift when deciding whether a row fills its container.
Geom.ROW_CENTER_SLACK = (GCDM.CONST and GCDM.CONST.SIZE_EPSILON) or 0.5

local function Snap(value)
	if Pixel and Pixel.Snap then
		return Pixel.Snap(value)
	end
	return value
end

function Geom.DefaultIconSize()
	return Geom.DEFAULT_ICON_WIDTH, Geom.DEFAULT_ICON_HEIGHT
end

--- Non-negative spacing; optional physical-pixel floor when pixelSnap is on.
function Geom.NormalizeSpacing(rawSpacing)
	local spacing = tonumber(rawSpacing) or 0
	if spacing < 0 then
		spacing = 0
	end
	if spacing <= 0 then
		return 0
	end
	if not (Pixel and Pixel.IsSnapEnabled and Pixel.IsSnapEnabled()) then
		return spacing
	end
	local snapped = Snap(spacing)
	local px = Pixel.GetSize and Pixel.GetSize() or 1
	if snapped < px then
		snapped = px
	end
	return snapped
end

--- When spacing is 0, overlap frames by border thickness so edges share one pixel.
function Geom.BorderOverlap(db, spacing)
	spacing = tonumber(spacing) or 0
	if spacing > 0 then
		return 0
	end
	local border = db and db.borderSize
	if border == nil then
		border = Geom.DEFAULT_BORDER_SIZE
	end
	border = tonumber(border) or 0
	if border < 0 then
		border = 0
	end
	return Snap(border)
end

function Geom.IconStride(iconWidth, spacing, borderOverlap)
	return iconWidth + spacing - (borderOverlap or 0)
end

--- Width of a row with uniform strides (Utility / Buff / internal helper).
function Geom.UniformRowWidth(iconCount, iconWidth, spacing, borderOverlap)
	if iconCount <= 0 then
		return 0
	end
	borderOverlap = borderOverlap or 0
	return (iconCount * iconWidth) + ((iconCount - 1) * (spacing - borderOverlap))
end

--- True for the gap before `iconIndex` (1-based), i.e. between icons iconIndex-1 and iconIndex.
function Geom.IsEssentialEndGap(iconIndex, iconCount)
	if iconCount < 2 or iconIndex < 1 then
		return false
	end
	if iconIndex == 1 then
		return true
	end
	return iconIndex == (iconCount - 1)
end

function Geom.EssentialEndGapTrimTotal(iconCount)
	if iconCount < 2 then
		return 0
	end
	local trim = Geom.ESSENTIAL_END_GAP_TRIM
	if iconCount == 2 then
		return trim
	end
	return trim * 2
end

function Geom.EssentialRowWidth(iconCount, iconWidth, spacing, borderOverlap)
	return Geom.UniformRowWidth(iconCount, iconWidth, spacing, borderOverlap)
		- Geom.EssentialEndGapTrimTotal(iconCount)
end

function Geom.StrideBeforeIcon(iconIndex, iconCount, baseStride)
	if Geom.IsEssentialEndGap(iconIndex, iconCount) then
		return baseStride - Geom.ESSENTIAL_END_GAP_TRIM
	end
	return baseStride
end

--- Left origin: flush when the row fills the container; otherwise center.
function Geom.RowOriginX(rowWidth, containerWidth)
	local slack = Geom.ROW_CENTER_SLACK
	if type(containerWidth) == "number"
		and type(rowWidth) == "number"
		and containerWidth > rowWidth + slack then
		return (containerWidth - rowWidth) * 0.5
	end
	return 0
end

function Geom.UniformColumnX(columnIndex0, iconWidth, spacing, borderOverlap, rowWidth, containerWidth)
	local origin = Geom.RowOriginX(rowWidth, containerWidth)
	return origin + (columnIndex0 * Geom.IconStride(iconWidth, spacing, borderOverlap))
end

--- Column X for Essential (0-based), with end-gap trim on first and last gaps.
function Geom.EssentialColumnX(columnIndex0, iconCount, iconWidth, spacing, borderOverlap, rowWidth, containerWidth)
	local origin = Geom.RowOriginX(rowWidth, containerWidth)
	if columnIndex0 <= 0 then
		return origin
	end
	local baseStride = Geom.IconStride(iconWidth, spacing, borderOverlap)
	local x = origin
	for iconIndex = 1, columnIndex0 do
		x = x + Geom.StrideBeforeIcon(iconIndex, iconCount, baseStride)
	end
	return x
end

function Geom.StackedRowHeight(row1Height, row2Height, spacing, borderOverlap)
	if spacing <= 0 and (borderOverlap or 0) > 0 then
		return row1Height + row2Height - borderOverlap
	end
	return row1Height + spacing + row2Height
end

function Geom.SecondRowOffsetY(row1Height, spacing, borderOverlap)
	if spacing <= 0 and (borderOverlap or 0) > 0 then
		return -(row1Height - borderOverlap)
	end
	return -(row1Height + spacing)
end

function Geom.SnapIconSize(sizeTable, fallbackW, fallbackH)
	fallbackW = fallbackW or Geom.DEFAULT_ICON_WIDTH
	fallbackH = fallbackH or Geom.DEFAULT_ICON_HEIGHT
	sizeTable = sizeTable or {}
	return Snap(sizeTable.w or fallbackW), Snap(sizeTable.h or fallbackH)
end

--- Configured full Essential width (maxIconsPerRow), including end-gap trim.
function Geom.EssentialConfiguredWidth(db)
	if not db then
		return 0
	end
	local maxRow = db.maxIconsPerRow or Geom.DEFAULT_MAX_ICONS_PER_ROW
	if maxRow < 1 then
		maxRow = 1
	end
	local iconW = Geom.SnapIconSize(db.sizeEssential)
	local spacing = Geom.NormalizeSpacing(db.spacing or 0)
	local overlap = Geom.BorderOverlap(db, spacing)
	return Snap(Geom.EssentialRowWidth(maxRow, iconW, spacing, overlap))
end
