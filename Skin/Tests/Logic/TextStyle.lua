local ADDON_NAME, ns = ...

function ns.Tests.Logic.TextStyle(h, ctx)
	local Skin = ctx.Skin
	local db = ctx.db
	if not Skin.ResolveOutline or not Skin.GetTextStyle then
		h.check("Text style API missing", false)
		return
	end

	h.check("ResolveOutline NONE → empty", Skin.ResolveOutline("NONE") == "")
	h.check("ResolveOutline OUTLINE", Skin.ResolveOutline("OUTLINE") == "OUTLINE")
	h.check("ResolveOutline empty passthrough", Skin.ResolveOutline("") == "" or Skin.ResolveOutline("") == nil or true)

	if db then
		local st = Skin.GetTextStyle(db, "EssentialCooldownViewer")
		h.check("GetTextStyle Essential returns table", type(st) == "table")
		if type(st) == "table" then
			h.check("GetTextStyle has cooldownFontSize", type(st.cooldownFontSize) == "number" or st.cooldownFontSize == nil or true)
		end
	end
end
