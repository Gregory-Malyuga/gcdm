-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- Small color helpers shared by Skin modules.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local ColorUtil = {}
Skin.ColorUtil = ColorUtil

function ColorUtil.Copy(color, fallback)
	fallback = fallback or { r = 1, g = 1, b = 1, a = 1 }
	if type(color) ~= "table" then
		return {
			r = fallback.r or 1,
			g = fallback.g or 1,
			b = fallback.b or 1,
			a = fallback.a or 1,
		}
	end
	return {
		r = color.r or fallback.r or 1,
		g = color.g or fallback.g or 1,
		b = color.b or fallback.b or 1,
		a = color.a or fallback.a or 1,
	}
end

function ColorUtil.Unpack(color, fallbackR, fallbackG, fallbackB, fallbackA)
	color = color or {}
	return color.r or fallbackR or 1,
		color.g or fallbackG or 1,
		color.b or fallbackB or 1,
		color.a or fallbackA or 1
end
