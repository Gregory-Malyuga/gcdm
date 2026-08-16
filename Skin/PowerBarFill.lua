-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- ColorCurve build + statusbar fill color (secret-safe Evaluate).
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local PowerBarCurve = Skin.PowerBarCurve

local colorCurve
local curveFingerprint

local function EnsureColorCurve(profile)
	local points = Skin.ParsePowerBarCurvePoints(profile.curvePointsStr)
	if #points < 2 then
		if profile.curveMode == "percent" then
			points = PowerBarCurve.DefaultPointsPercent()
		else
			points = PowerBarCurve.DefaultPointsAbsolute()
		end
	end
	local fp = profile.curveMode .. "|" .. Skin.FormatPowerBarCurvePoints(points)
	if colorCurve and curveFingerprint == fp then
		return colorCurve
	end
	if not C_CurveUtil or not C_CurveUtil.CreateColorCurve then
		return nil
	end
	local curve = C_CurveUtil.CreateColorCurve()
	if curve.SetType and Enum and Enum.LuaCurveType then
		pcall(curve.SetType, curve, Enum.LuaCurveType.Linear)
	end
	if curve.ClearPoints then
		pcall(curve.ClearPoints, curve)
	end
	for i = 1, #points do
		local p = points[i]
		local col = CreateColor and CreateColor(p.r or 1, p.g or 1, p.b or 1, p.a or 1)
		if col and curve.AddPoint then
			pcall(curve.AddPoint, curve, p.x or 0, col)
		end
	end
	colorCurve = curve
	curveFingerprint = fp
	return colorCurve
end

function PowerBarCurve.Reset()
	curveFingerprint = nil
end

function PowerBarCurve.ApplyFillColor(bar, powerType, profile, fallbackR, fallbackG, fallbackB, fallbackA)
	local fr = fallbackR or 0.78
	local fg = fallbackG or 0.1
	local fb = fallbackB or 0.1
	local fa = fallbackA or 1
	local mode = profile and profile.colorMode or "class"

	if mode == "solid" then
		local c = profile.solidColor or {}
		fr, fg, fb, fa = c.r or fr, c.g or fg, c.b or fb, c.a or 1
	elseif mode == "curve" then
		local curve = EnsureColorCurve(profile)
		if curve then
			local ok, color
			if profile.curveMode == "percent" and UnitPowerPercent then
				ok, color = pcall(UnitPowerPercent, "player", powerType, false, curve)
				if not ok or color == nil then
					local okp, pct = pcall(UnitPowerPercent, "player", powerType)
					if okp and pct ~= nil and curve.Evaluate then
						ok, color = pcall(curve.Evaluate, curve, pct)
					end
				end
			else
				local okp, cur = pcall(UnitPower, "player", powerType)
				if okp and cur ~= nil and curve.Evaluate then
					ok, color = pcall(curve.Evaluate, curve, cur)
				end
			end
			if ok and color then
				if color.GetRGBA then
					fr, fg, fb, fa = color:GetRGBA()
				elseif color.GetRGB then
					fr, fg, fb = color:GetRGB()
					fa = 1
				elseif type(color) == "table" then
					fr, fg, fb, fa = color.r or fr, color.g or fg, color.b or fb, color.a or 1
				end
			end
		end
	end

	if type(fr) ~= "number" or type(fg) ~= "number" or type(fb) ~= "number" then
		fr, fg, fb, fa = fallbackR or 0.78, fallbackG or 0.1, fallbackB or 0.1, fallbackA or 1
	end

	local st = bar:GetStatusBarTexture()
	if st then
		st:SetVertexColor(fr, fg, fb, fa)
		st:SetAlpha(fa)
		st:Show()
	end
	pcall(bar.SetStatusBarColor, bar, fr, fg, fb, fa)
end
