-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- Shared PowerBar / BuffBar width resolution (follow Essential vs independent).
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

local BarWidth = {}
Skin.BarWidth = BarWidth

local function Const()
	return GCDM.CONST or {}
end

function BarWidth.Min()
	return Const().MIN_BAR_WIDTH or 200
end

function BarWidth.Clamp(width)
	local minW = BarWidth.Min()
	width = tonumber(width) or 0
	if width < minW then
		width = minW
	end
	if Pixel and Pixel.Snap then
		return Pixel.Snap(width)
	end
	return width
end

function BarWidth.LiveEssentialWidth()
	local registry = GCDM.ViewerRegistry
	local essential = registry and registry.Essential and registry:Essential()
	if not essential or not essential.GetWidth then
		return nil
	end
	local ok, ew = pcall(essential.GetWidth, essential)
	local minLive = Const().MIN_LIVE_ESSENTIAL_WIDTH or 40
	if ok and type(ew) == "number" and ew >= minLive then
		if canaccessvalue and not canaccessvalue(ew) then
			return nil
		end
		return ew
	end
	return nil
end

function BarWidth.EssentialFallback(db)
	local live = BarWidth.LiveEssentialWidth()
	if live then
		return live
	end
	local laid = Skin.EssentialLayoutWidth
	if type(laid) == "number" and laid >= (Const().MIN_LIVE_ESSENTIAL_WIDTH or 40) then
		return laid
	end
	if Skin.EssentialWidthFormula then
		return Skin.EssentialWidthFormula(db)
	end
	return BarWidth.Min()
end

--- followFlagKey: "powerBarFollowEssential" or "buffBarFollowEssential"
--- independentWidthKey: "powerBarWidth" or "buffBarWidth"
function BarWidth.Resolve(db, followFlagKey, independentWidthKey)
	db = db or {}
	local follow = db[followFlagKey]
	if follow == nil then
		follow = true
	end
	if not follow then
		return BarWidth.Clamp(db[independentWidthKey] or BarWidth.Min())
	end
	return BarWidth.Clamp(BarWidth.EssentialFallback(db))
end
