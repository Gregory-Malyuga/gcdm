-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- Power bar color profiles (parse/format/get/set) + curve defaults.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local PowerBarCurve = {}
Skin.PowerBarCurve = PowerBarCurve

local function CopyColor(c, fallback)
	if Skin.ColorUtil and Skin.ColorUtil.Copy then
		return Skin.ColorUtil.Copy(c, fallback)
	end
	fallback = fallback or { r = 1, g = 1, b = 1, a = 1 }
	c = c or fallback
	return { r = c.r or fallback.r, g = c.g or fallback.g, b = c.b or fallback.b, a = c.a or fallback.a }
end

function PowerBarCurve.DefaultPointsAbsolute()
	return {
		{ x = 0, r = 1, g = 0.85, b = 0.1, a = 1 },
		{ x = 100, r = 1, g = 0.85, b = 0.1, a = 1 },
		{ x = 100.01, r = 1, g = 1, b = 1, a = 1 },
		{ x = 200, r = 1, g = 1, b = 1, a = 1 },
	}
end

function PowerBarCurve.DefaultPointsPercent()
	return {
		{ x = 0, r = 1, g = 0.2, b = 0.2, a = 1 },
		{ x = 0.35, r = 1, g = 0.85, b = 0.2, a = 1 },
		{ x = 0.7, r = 0.2, g = 0.9, b = 0.3, a = 1 },
		{ x = 1, r = 1, g = 1, b = 1, a = 1 },
	}
end

-- Parse "0:1,0,0|100:1,0,0|101:1,1,1" → { {x=,r=,g=,b=,a=}… }
function Skin.ParsePowerBarCurvePoints(str)
	local out = {}
	if type(str) ~= "string" or str == "" then
		return out
	end
	for part in string.gmatch(str, "[^|]+") do
		local x, r, g, b, a = string.match(part, "^%s*([%d%.]+)%s*:%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,?%s*([%d%.]*)%s*$")
		if x then
			out[#out + 1] = {
				x = tonumber(x) or 0,
				r = tonumber(r) or 1,
				g = tonumber(g) or 1,
				b = tonumber(b) or 1,
				a = (a ~= "" and tonumber(a)) or 1,
			}
		end
	end
	table.sort(out, function(a, b)
		return a.x < b.x
	end)
	return out
end

function Skin.FormatPowerBarCurvePoints(points)
	if type(points) ~= "table" then
		return ""
	end
	local parts = {}
	for i = 1, #points do
		local p = points[i]
		if p then
			parts[#parts + 1] = string.format(
				"%.4g:%.3g,%.3g,%.3g,%.3g",
				p.x or 0,
				p.r or 1,
				p.g or 1,
				p.b or 1,
				p.a or 1
			)
		end
	end
	return table.concat(parts, "|")
end

function Skin.GetPowerBarProfile(db, classFile)
	db = db or GCDM:GetDB()
	classFile = classFile or select(2, UnitClass("player")) or "DEFAULT"
	local profiles = db and db.powerBarProfiles
	local tickDefaults = (GCDM.CONST and GCDM.CONST.POWER_BAR_TICK_DEFAULTS) or "25,50,75,100"
	local base = {
		colorMode = db.powerBarColorMode or "class",
		curveMode = db.powerBarCurveMode or "absolute",
		curvePointsStr = db.powerBarCurvePointsStr or Skin.FormatPowerBarCurvePoints(PowerBarCurve.DefaultPointsAbsolute()),
		solidColor = CopyColor(db.powerBarColor, { r = 0.55, g = 0.1, b = 0.1, a = 1 }),
		tickMode = db.powerBarTickMode or "none",
		tickCount = db.powerBarTickCount or 4,
		tickAtStr = db.powerBarTickAtStr or tickDefaults,
		tickMax = db.powerBarTickMax or 100,
		tickColor = CopyColor(db.powerBarTickColor, { r = 1, g = 1, b = 1, a = 0.55 }),
	}
	if type(profiles) == "table" and type(profiles[classFile]) == "table" then
		local o = profiles[classFile]
		if o.colorMode ~= nil then
			base.colorMode = o.colorMode
		end
		if o.curveMode ~= nil then
			base.curveMode = o.curveMode
		end
		if o.curvePointsStr ~= nil then
			base.curvePointsStr = o.curvePointsStr
		end
		if o.solidColor ~= nil then
			base.solidColor = CopyColor(o.solidColor, base.solidColor)
		end
		if o.tickMode ~= nil then
			base.tickMode = o.tickMode
		end
		if o.tickCount ~= nil then
			base.tickCount = o.tickCount
		end
		if o.tickAtStr ~= nil then
			base.tickAtStr = o.tickAtStr
		end
		if o.tickMax ~= nil then
			base.tickMax = o.tickMax
		end
		if o.tickColor ~= nil then
			base.tickColor = CopyColor(o.tickColor, base.tickColor)
		end
	end
	return base
end

function Skin.SetPowerBarProfileField(db, classFile, field, value)
	db.powerBarProfiles = db.powerBarProfiles or {}
	if classFile == "DEFAULT" then
		if field == "colorMode" then
			db.powerBarColorMode = value
		elseif field == "curveMode" then
			db.powerBarCurveMode = value
		elseif field == "curvePointsStr" then
			db.powerBarCurvePointsStr = value
		elseif field == "solidColor" then
			db.powerBarColor = value
		elseif field == "tickMode" then
			db.powerBarTickMode = value
		elseif field == "tickCount" then
			db.powerBarTickCount = value
		elseif field == "tickAtStr" then
			db.powerBarTickAtStr = value
		elseif field == "tickMax" then
			db.powerBarTickMax = value
		elseif field == "tickColor" then
			db.powerBarTickColor = value
		end
	end
	db.powerBarProfiles[classFile] = db.powerBarProfiles[classFile] or {}
	db.powerBarProfiles[classFile][field] = value
end
