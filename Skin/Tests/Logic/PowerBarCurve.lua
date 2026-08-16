local ADDON_NAME, ns = ...

function ns.Tests.Logic.PowerBarCurve(h, ctx)
	local Skin = ctx.Skin
	if not Skin.ParsePowerBarCurvePoints or not Skin.FormatPowerBarCurvePoints then
		h.check("PowerBar curve API missing", false)
		return
	end

	local pts = Skin.ParsePowerBarCurvePoints("0:1,0,0,1|100:0,1,0|101:1,1,1")
	h.check("Parse curve point count", #pts == 3, tostring(#pts))
	h.check("Parse curve sorted by x", pts[1].x == 0 and pts[2].x == 100 and pts[3].x == 101)
	h.check("Parse curve colors", pts[1].r == 1 and pts[2].g == 1 and pts[3].b == 1)

	local formatted = Skin.FormatPowerBarCurvePoints(pts)
	local again = Skin.ParsePowerBarCurvePoints(formatted)
	h.check("Format/Parse roundtrip count", #again == 3, formatted)
	h.check("Format/Parse roundtrip x0", again[1] and again[1].x == 0)

	local empty = Skin.ParsePowerBarCurvePoints("")
	h.check("Parse empty → {}", #empty == 0)
end
