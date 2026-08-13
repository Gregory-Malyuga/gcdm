local ADDON_NAME, ns = ...

function ns.Tests.Behavior.PowerBar(h, ctx)
	local Skin = ctx.Skin
	local db = ctx.db
	local GCDM = ctx.addon
	if not db then
		return
	end
	if db.powerBarEnabled == false then
		h.check("PowerBar disabled skipped", true)
		return
	end

	local ph = GCDM.GetPowerBarHost and GCDM:GetPowerBarHost()
	h.check("PowerBar host exists after Refresh", ph ~= nil)
	if not ph then
		return
	end
	h.check("PowerBar host shown", ph:IsShown() == true)
	local pw = ph:GetWidth() or 0
	local wantW = Skin.EssentialLayoutWidth
	if type(wantW) == "number" and wantW >= 40 then
		h.check(
			"PowerBar width ≈ EssentialLayoutWidth",
			h.Near(pw, wantW, 3),
			string.format("pw=%.1f want=%.1f", pw, wantW)
		)
	else
		h.check("PowerBar width > 40", pw > 40, string.format("%.1f", pw))
	end
	local primary = _G.GCDM_PowerBarPrimary
	h.check("PowerBar primary StatusBar exists", primary ~= nil)
	if primary then
		h.check("PowerBar primary shown", primary:IsShown() == true)
	end
end
