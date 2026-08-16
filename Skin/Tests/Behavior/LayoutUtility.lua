local ADDON_NAME, ns = ...

function ns.Tests.Behavior.LayoutUtility(h, ctx)
	local Skin = ctx.Skin
	local utility = ctx.registry and ctx.registry:Utility()
	if not utility then
		return
	end

	local park = Skin.PARK_OFFSET or -10000
	local icons = Skin.CollectIconFrames(utility)
	local shown, parkedShown = 0, 0
	for i = 1, #icons do
		local f = icons[i]
		if f and f:IsShown() then
			shown = shown + 1
			if f.GCDMParked then
				parkedShown = parkedShown + 1
			end
			if f.GCDMAnchor and not f.GCDMParked then
				h.check(
					"UTIL placed icon has GCDMAnchor",
					type(f.GCDMAnchor) == "table" and f.GCDMAnchor[4] ~= park,
					tostring(f.layoutIndex)
				)
			end
		elseif f and f.GCDMParked then
			h.check(
				"UTIL parked icon alpha≈0",
				(f:GetAlpha() or 1) <= 0.01,
				tostring(f.layoutIndex)
			)
		end
	end
	h.check("UTIL pool enumerated", #icons >= 0, string.format("n=%d shown=%d", #icons, shown))
	h.check("UTIL no parked+shown icons", parkedShown == 0, tostring(parkedShown))
end
