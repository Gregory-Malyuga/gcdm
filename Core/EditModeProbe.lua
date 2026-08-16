-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local PROBE_METRIC_KEYS = {
	"iconWidth",
	"iconHeight",
	"iconSize",
	"childWidth",
	"childHeight",
	"buttonWidth",
	"buttonHeight",
	"iconPadding",
	"padding",
	"childXPadding",
	"childYPadding",
	"stride",
	"baseIconWidth",
	"baseIconHeight",
}

local PROBE_ICON_SIZE_MIN = 8
local PROBE_ICON_SIZE_MAX = 256

local function TakeProbeNumber(v)
	if type(v) ~= "number" then
		return nil
	end
	if canaccessvalue and not canaccessvalue(v) then
		return nil
	end
	local ok = pcall(function()
		return v > PROBE_ICON_SIZE_MIN and v < PROBE_ICON_SIZE_MAX
	end)
	if not ok then
		return nil
	end
	if v > PROBE_ICON_SIZE_MIN and v < PROBE_ICON_SIZE_MAX then
		return v
	end
	return nil
end

function GCDM:ProbeViewerLayoutMetrics(viewer)
	local out = { iconW = nil, iconH = nil, pad = nil, keys = {} }
	if not viewer then
		return out
	end
	for i = 1, #PROBE_METRIC_KEYS do
		local key = PROBE_METRIC_KEYS[i]
		local v = viewer[key]
		if type(v) == "function" then
			local ok, a, b = pcall(v, viewer)
			if ok then
				local n = TakeProbeNumber(a)
				if n then
					out.keys[key] = n
				elseif TakeProbeNumber(b) then
					out.keys[key] = TakeProbeNumber(b)
				end
			end
		else
			local n = TakeProbeNumber(v)
			if n then
				out.keys[key] = n
			end
		end
	end
	if viewer.GetIconSize then
		local ok, a, b = pcall(viewer.GetIconSize, viewer)
		if ok then
			out.keys.GetIconSizeW = TakeProbeNumber(a)
			out.keys.GetIconSizeH = TakeProbeNumber(b) or TakeProbeNumber(a)
		end
	end
	out.iconW = out.keys.iconWidth
		or out.keys.GetIconSizeW
		or out.keys.iconSize
		or out.keys.childWidth
		or out.keys.buttonWidth
		or out.keys.baseIconWidth
	out.iconH = out.keys.iconHeight
		or out.keys.GetIconSizeH
		or out.keys.iconSize
		or out.keys.childHeight
		or out.keys.buttonHeight
		or out.keys.baseIconHeight
		or out.iconW
	out.pad = out.keys.iconPadding or out.keys.padding or out.keys.childXPadding
	return out
end
