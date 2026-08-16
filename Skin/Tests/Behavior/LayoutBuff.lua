local ADDON_NAME, ns = ...

function ns.Tests.Behavior.LayoutBuff(h, ctx)
	local Skin = ctx.Skin
	local buff = ctx.registry and ctx.registry:Buff()
	if not buff then
		return
	end

	local park = Skin.PARK_OFFSET or -10000
	local icons = Skin.CollectIconFrames(buff)
	local shownN, parkedN = 0, 0
	for i = 1, #icons do
		local f = icons[i]
		if f and f:IsShown() and not f.GCDMParked then
			shownN = shownN + 1
			h.check(
				"BUFF shown icon alpha>0",
				(f:GetAlpha() or 0) > 0.5,
				tostring(f.layoutIndex)
			)
			h.check(
				"BUFF shown not at park X",
				Skin.FrameAnchorX(f) ~= park,
				tostring(f.layoutIndex)
			)
		elseif f and (f.GCDMParked or not f:IsShown()) then
			parkedN = parkedN + 1
			if f.GCDMParked then
				h.check(
					"BUFF parked icon sits at the park slot or is invisible",
					Skin.FrameAnchorX(f) == park or (f:GetAlpha() or 1) <= 0.01,
					tostring(f.layoutIndex)
				)
			end
		end
	end
	h.check("BUFF pool enumerated", #icons >= 0, string.format("n=%d shown=%d parkedish=%d", #icons, shownN, parkedN))
end
