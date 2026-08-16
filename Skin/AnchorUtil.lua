-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- Anchor point normalization shared by Position / Text.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local AnchorUtil = {}
Skin.AnchorUtil = AnchorUtil

AnchorUtil.POINTS = {
	TOPLEFT = true,
	TOP = true,
	TOPRIGHT = true,
	LEFT = true,
	CENTER = true,
	RIGHT = true,
	BOTTOMLEFT = true,
	BOTTOM = true,
	BOTTOMRIGHT = true,
}

function AnchorUtil.NormalizePoint(point, fallback)
	fallback = fallback or "CENTER"
	if type(point) ~= "string" then
		return fallback
	end
	local upper = string.upper(point)
	if AnchorUtil.POINTS[upper] then
		return upper
	end
	return fallback
end
