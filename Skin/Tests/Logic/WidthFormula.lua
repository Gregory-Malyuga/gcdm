local ADDON_NAME, ns = ...

function ns.Tests.Logic.WidthFormula(h, ctx)
	local Skin = ctx.Skin
	local Pixel = ctx.Pixel
	local db = ctx.db
	if not Skin.EssentialWidthFormula then
		h.check("EssentialWidthFormula missing", false)
		return
	end
	if not db then
		return
	end

	local mock = {
		maxIconsPerRow = 7,
		sizeEssential = { w = 46, h = 40 },
		spacing = 0,
		pixelSnap = false,
	}
	-- Formula should be deterministic for fixed inputs; temporarily use mock fields on a copy.
	local prevSnap = db.pixelSnap
	db.pixelSnap = false
	if Pixel and Pixel.Update then
		Pixel.Update()
	end

	local w = Skin.EssentialWidthFormula(mock)
	h.check("WidthFormula spacing0 → 7*46", h.Near(w, 7 * 46, 0.01), tostring(w))

	mock.spacing = 2
	local w2 = Skin.EssentialWidthFormula(mock)
	h.check("WidthFormula spacing2 → 7*46+6*2", h.Near(w2, 7 * 46 + 6 * 2, 0.01), tostring(w2))

	db.pixelSnap = prevSnap
end
