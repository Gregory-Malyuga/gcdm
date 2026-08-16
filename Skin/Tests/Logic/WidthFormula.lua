local ADDON_NAME, ns = ...

function ns.Tests.Logic.WidthFormula(h, ctx)
	local Skin = ctx.Skin
	local Pixel = ctx.Pixel
	local db = ctx.db
	local Geom = Skin.LayoutGeometry
	if not Skin.EssentialWidthFormula then
		h.check("EssentialWidthFormula missing", false)
		return
	end
	if not Geom then
		h.check("LayoutGeometry missing", false)
		return
	end
	if not db then
		return
	end

	local mock = {
		maxIconsPerRow = 7,
		sizeEssential = { w = 46, h = 40 },
		spacing = 0,
		borderSize = 0,
		pixelSnap = false,
	}
	local prevSnap = db.pixelSnap
	db.pixelSnap = false
	if Pixel and Pixel.Update then
		Pixel.Update()
	end

	local trim = Geom.ESSENTIAL_END_GAP_TRIM
	local endTrim = trim * 2 -- seven icons → two end gaps

	local w = Skin.EssentialWidthFormula(mock)
	h.check(
		"WidthFormula spacing0 border0 → 7*46 - endTrim",
		h.Near(w, 7 * 46 - endTrim, 0.01),
		tostring(w)
	)

	mock.borderSize = 1
	local wOverlap = Skin.EssentialWidthFormula(mock)
	h.check(
		"WidthFormula spacing0 border1 → overlap + endTrim",
		h.Near(wOverlap, 7 * 46 - 6 - endTrim, 0.01),
		tostring(wOverlap)
	)

	mock.spacing = 2
	mock.borderSize = 1
	local w2 = Skin.EssentialWidthFormula(mock)
	h.check(
		"WidthFormula spacing2 → 7*46+6*2 - endTrim",
		h.Near(w2, 7 * 46 + 6 * 2 - endTrim, 0.01),
		tostring(w2)
	)

	h.check("IsEssentialEndGap first", Geom.IsEssentialEndGap(1, 7) == true)
	h.check("IsEssentialEndGap middle", Geom.IsEssentialEndGap(3, 7) == false)
	h.check("IsEssentialEndGap last", Geom.IsEssentialEndGap(6, 7) == true)
	h.check("IsEssentialEndGap pair", Geom.IsEssentialEndGap(1, 2) == true)

	db.pixelSnap = prevSnap
end
