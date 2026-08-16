local ADDON_NAME, ns = ...

function ns.Tests.Behavior.LayoutBuff(h, ctx)
	local Skin = ctx.Skin
	local Geom = Skin.LayoutGeometry
	local buff = ctx.registry and ctx.registry:Buff()
	if not buff then
		return
	end

	h.check("BUFF center helper exists", type(Skin.LayoutBuffIconsCentered) == "function")

	local park = Skin.PARK_OFFSET or -10000
	local icons = Skin.CollectIconFrames(buff)
	local shownN = 0
	local xs = {}
	for i = 1, #icons do
		local f = icons[i]
		if f and f:IsShown() and not f.GCDMParked then
			shownN = shownN + 1
			h.check(
				"BUFF shown icon alpha>0",
				(f:GetAlpha() or 0) > 0.5,
				tostring(f.layoutIndex)
			)
			local x = Skin.FrameAnchorX(f)
			h.check(
				"BUFF shown not parked by GCDM",
				x ~= park,
				tostring(f.layoutIndex)
			)
			if type(x) == "number" then
				xs[#xs + 1] = x
			end
		end
	end
	h.check("BUFF pool enumerated", #icons >= 0, string.format("n=%d shown=%d", #icons, shownN))

	-- When Essential is wider than the active buff row, the first icon must sit
	-- past X=0 (centered inside Essential width) — the old SetSize(content) bug.
	local containerW = Skin.EssentialLayoutWidth
	if type(containerW) == "number" and containerW > 0 and shownN > 0 and #xs > 0 and Geom then
		table.sort(xs)
		local db = ctx.db
		local spacing = Geom.NormalizeSpacing((db and db.spacing) or 0)
		local overlap = Geom.BorderOverlap(db, spacing)
		local iw = (db and db.sizeBuff and db.sizeBuff.w) or 40
		local rowW = Geom.UniformRowWidth(shownN, iw, spacing, overlap)
		if containerW > rowW + (Geom.ROW_CENTER_SLACK or 0.5) then
			h.check(
				"BUFF row is centered in Essential width",
				xs[1] > 0.5,
				string.format("x0=%.1f container=%.1f row=%.1f", xs[1], containerW, rowW)
			)
		end
	end
end
