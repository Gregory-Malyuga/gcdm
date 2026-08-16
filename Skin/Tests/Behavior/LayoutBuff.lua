local ADDON_NAME, ns = ...

function ns.Tests.Behavior.LayoutBuff(h, ctx)
	local Skin = ctx.Skin
	local buff = ctx.registry and ctx.registry:Buff()
	if not buff then
		return
	end

	-- Buff icons are laid out by Blizzard GridLayout; GCDM must not park or
	-- re-center them (that left-aligned the row and fought Edit Mode saves).
	h.check("BUFF layout is left to Blizzard", Skin.LayoutBuffIconsCentered == nil)

	local park = Skin.PARK_OFFSET or -10000
	local icons = Skin.CollectIconFrames(buff)
	local shownN = 0
	for i = 1, #icons do
		local f = icons[i]
		if f and f:IsShown() then
			shownN = shownN + 1
			h.check(
				"BUFF shown icon alpha>0",
				(f:GetAlpha() or 0) > 0.5,
				tostring(f.layoutIndex)
			)
			h.check(
				"BUFF shown not parked by GCDM",
				f.GCDMParked ~= true and Skin.FrameAnchorX(f) ~= park,
				tostring(f.layoutIndex)
			)
		end
	end
	h.check("BUFF pool enumerated", #icons >= 0, string.format("n=%d shown=%d", #icons, shownN))
end
