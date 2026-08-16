local ADDON_NAME, ns = ...

function ns.Tests.Logic.CDMContent(h, ctx)
	local addon = ctx.addon
	local Content = addon.CDMContent
	if not Content then
		h.check("CDMContent module missing", false)
		return
	end

	local V = addon.CONST.VIEWERS
	h.check("Essential viewer maps to a panel key", Content:KeyForViewer(V.ESSENTIAL) == "essential")
	h.check("Buff bar viewer maps to a panel key", Content:KeyForViewer(V.BUFF_BAR) == "buffBar")

	h.check("Essential and Utility are siblings", Content:SiblingKey("essential") == "utility")
	h.check("Buff icons and buff bars are siblings", Content:SiblingKey("buffBar") == "buff")

	local categories = Content:Categories()
	h.check(
		"Category ids resolve to numbers",
		type(categories.essential) == "number" and type(categories.buffBar) == "number",
		tostring(categories.essential) .. "," .. tostring(categories.buffBar)
	)

	local activeHidden = Content:HiddenCategoryForKey("essential")
	local passiveHidden = Content:HiddenCategoryForKey("buff")
	h.check(
		"Spells and auras hide into separate categories",
		activeHidden ~= passiveHidden,
		tostring(activeHidden) .. "," .. tostring(passiveHidden)
	)

	local entries = Content:GetEntries(categories.essential)
	h.check("GetEntries returns a list", type(entries) == "table", tostring(#entries) .. " entries")

	if Content:IsAvailable() then
		local ok = true
		for i = 1, #entries do
			local entry = entries[i]
			if type(entry.cooldownID) ~= "number" or type(entry.orderIndex) ~= "number" then
				ok = false
				break
			end
		end
		h.check("Entries carry cooldown id and order index", ok)
	else
		h.check("CDM settings data not loaded — entry checks skipped", true, "skip")
	end
end
