local ADDON_NAME, ns = ...

function ns.Tests.Behavior.LayoutEssential(h, ctx)
	local Skin = ctx.Skin
	local Pixel = ctx.Pixel
	local db = ctx.db
	local essential = ctx.registry and ctx.registry:Essential()
	if not essential or not db then
		return
	end

	local park = Skin.PARK_OFFSET or -10000
	local formulaW = Skin.EssentialWidthFormula and Skin.EssentialWidthFormula(db)
	if type(formulaW) ~= "number" then
		local maxRow = db.maxIconsPerRow or 7
		local iw = Pixel.Snap((db.sizeEssential and db.sizeEssential.w) or 46)
		local spacing = Pixel.Snap(db.spacing or 0)
		if Pixel.IsSnapEnabled and Pixel.IsSnapEnabled() and (db.spacing or 0) > 0 and spacing < Pixel.GetSize() then
			spacing = Pixel.GetSize()
		end
		formulaW = (maxRow * iw) + ((maxRow - 1) * spacing)
	end

	h.check(
		"Skin.EssentialLayoutWidth ≈ maxRow formula",
		h.Near(Skin.EssentialLayoutWidth, formulaW, 2),
		string.format("laid=%s formula=%.1f", tostring(Skin.EssentialLayoutWidth), formulaW)
	)

	local icons = Skin.CollectIconFrames(essential)
	local shown = 0
	local parkedShown = 0
	for i = 1, #icons do
		local f = icons[i]
		if f and f:IsShown() then
			shown = shown + 1
			if f.GCDMParked then
				parkedShown = parkedShown + 1
			end
			if f.GCDMAnchor and not f.GCDMParked then
				h.check(
					"ESS placed icon has GCDMAnchor",
					type(f.GCDMAnchor) == "table" and f.GCDMAnchor[4] ~= park,
					tostring(f.layoutIndex)
				)
			end
		elseif f and f.GCDMParked then
			h.check(
				"ESS parked icon alpha≈0",
				(f:GetAlpha() or 1) <= 0.01,
				tostring(f.layoutIndex)
			)
		end
	end
	h.check("ESS CollectIconFrames > 0", #icons > 0, tostring(#icons))
	h.check("ESS no parked+shown icons", parkedShown == 0, tostring(parkedShown))
	if shown > 0 then
		local ew = essential:GetWidth() or 0
		h.check("Essential width > 40", ew > 40, string.format("%.1f", ew))
	end
end
