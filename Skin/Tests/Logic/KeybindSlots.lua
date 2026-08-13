local ADDON_NAME, ns = ...

function ns.Tests.Logic.KeybindSlots(h, ctx)
	local Skin = ctx.Skin
	if not Skin.GetActionSlotForMainBarButton then
		h.check("Keybind slot API missing", false)
		return
	end

	local s1 = Skin.GetActionSlotForMainBarButton(1)
	h.check("MainBar button 1 → number slot", type(s1) == "number" and s1 >= 1, tostring(s1))

	local s12 = Skin.GetActionSlotForMainBarButton(12)
	h.check("MainBar button 12 → number slot", type(s12) == "number" and s12 >= 1, tostring(s12))

	if Skin.GetActionSlotForMultiBar then
		local m = Skin.GetActionSlotForMultiBar("MultiBarBottomLeft", 1)
		h.check("MultiBarBottomLeft btn1 slot number-or-nil", m == nil or type(m) == "number", tostring(m))
	end

	if Skin.GetBindingCommandForActionSlot and type(s1) == "number" then
		local cmd = Skin.GetBindingCommandForActionSlot(s1)
		h.check("Binding command for slot is string-or-nil", cmd == nil or type(cmd) == "string", tostring(cmd))
	end

	if Skin.SpellLookupIDs then
		local ids = Skin.SpellLookupIDs(1680)
		h.check("SpellLookupIDs returns list", type(ids) == "table" and #ids >= 1, tostring(ids and ids[1]))
	end
end
