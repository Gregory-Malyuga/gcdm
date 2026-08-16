local ADDON_NAME, ns = ...

function ns.Tests.Behavior.BuffBar(h, ctx)
	local Skin = ctx.Skin
	local db = ctx.db
	local addon = ctx.addon
	local buffBar = ctx.registry and ctx.registry:BuffBar()
	if not buffBar or not db or db.buffBarEnabled == false then
		return
	end

	local last = addon._buffBarLastApply
	h.check("BuffBar lastApply exists", last ~= nil)
	if last then
		h.check("BuffBar lastApply err nil", last.err == nil, tostring(last.err))
		local formulaW = Skin.EssentialLayoutWidth
		if type(formulaW) ~= "number" then
			formulaW = Skin.EssentialWidthFormula and Skin.EssentialWidthFormula(db)
		end
		if type(formulaW) ~= "number" then
			local Pixel = ctx.Pixel
			local iw = Pixel.Snap((db.sizeEssential and db.sizeEssential.w) or 46)
			local maxRow = db.maxIconsPerRow or 7
			local spacing = Pixel.Snap(db.spacing or 0)
			formulaW = (maxRow * iw) + ((maxRow - 1) * spacing)
		end
		local minW = (addon.CONST and addon.CONST.MIN_BAR_WIDTH) or 200
		local follow = db.buffBarFollowEssential ~= false
		if not follow then
			local want = db.buffBarWidth or minW
			if want < minW then
				want = minW
			end
			h.check(
				"BuffBar lastApply.width ≈ independent width",
				h.Near(last.width, want, 2),
				string.format("w=%.1f setting=%s", last.width or -1, tostring(want))
			)
		else
			local want = formulaW
			if type(want) == "number" and want < minW then
				want = minW
			end
			h.check(
				"BuffBar lastApply.width ≈ EssentialLayoutWidth (min 200)",
				h.Near(last.width, want, 2),
				string.format("w=%.1f laid=%s", last.width or -1, tostring(want))
			)
		end
		h.check(
			"BuffBar viewer width ≈ lastApply.width",
			h.Near(buffBar:GetWidth(), last.width, 2),
			string.format("viewer=%.1f want=%.1f", buffBar:GetWidth() or -1, last.width or -1)
		)
	end

	local bars = Skin.CollectBarFrames(buffBar)
	h.check("BuffBar CollectBarFrames >= 0", #bars >= 0, tostring(#bars))
	local style = db.buffBarStyle or "solid"
	local solid = (style == "solid" or style == "SharedMedia" or style == "sharedmedia")
	for i = 1, #bars do
		local frame = bars[i]
		if frame and frame.Bar then
			h.check(
				"BuffBar item has GCDMWantW",
				type(frame.GCDMWantW) == "number" and frame.GCDMWantW >= 8,
				string.format("#%d want=%s", i, tostring(frame.GCDMWantW))
			)
			if solid then
				h.check(
					"BuffBar solid has GCDMSkinBar",
					frame.GCDMSkinBar ~= nil,
					string.format("#%d", i)
				)
			end
			if frame:IsShown() then
				h.check(
					"BuffBar shown width ≈ want",
					h.Near(frame:GetWidth(), frame.GCDMWantW, 2),
					string.format("#%d got=%.1f want=%s", i, frame:GetWidth() or -1, tostring(frame.GCDMWantW))
				)
			end
		end
	end
end
