local ADDON_NAME, ns = ...

function ns.Tests.Logic.Refresh(h, ctx)
	local addon = ctx.addon
	if not addon.RegisterRefreshCallback or not addon.Refresh then
		h.check("Refresh API missing", false)
		return
	end

	local log = {}
	local idA, idB, idC = "GCDM.Test.Refresh.A", "GCDM.Test.Refresh.B", "GCDM.Test.Refresh.C"
	addon:UnregisterRefreshCallback(idA)
	addon:UnregisterRefreshCallback(idB)
	addon:UnregisterRefreshCallback(idC)

	addon:RegisterRefreshCallback(idA, function()
		log[#log + 1] = "A"
	end, 30, { addon.CONST.REFRESH.STYLE })
	addon:RegisterRefreshCallback(idB, function()
		log[#log + 1] = "B"
	end, 10, { addon.CONST.REFRESH.STYLE })
	addon:RegisterRefreshCallback(idC, function()
		log[#log + 1] = "C"
	end, 10, { addon.CONST.REFRESH.LAYOUT })

	addon:Refresh(addon.CONST.REFRESH.STYLE)
	h.check(
		"Refresh STYLE order by priority",
		log[1] == "B" and log[2] == "A" and #log == 2,
		table.concat(log, ",")
	)

	wipe(log)
	addon:Refresh(addon.CONST.REFRESH.LAYOUT)
	h.check(
		"Refresh LAYOUT only matching scopes",
		log[1] == "C" and #log == 1,
		table.concat(log, ",")
	)

	wipe(log)
	addon:Refresh(addon.CONST.REFRESH.ALL)
	h.check(
		"Refresh ALL includes all scopes",
		#log == 3,
		table.concat(log, ",")
	)

	if addon.SetModuleEnabled then
		local wasEnabled = addon:IsModuleEnabled(idA)
		addon:SetModuleEnabled(idA, false)
		wipe(log)
		addon:Refresh(addon.CONST.REFRESH.STYLE)
		h.check(
			"Refresh skips disabled module",
			log[1] == "B" and #log == 1,
			table.concat(log, ",")
		)

		addon:SetModuleEnabled(idA, true)
		wipe(log)
		addon:Refresh(addon.CONST.REFRESH.STYLE)
		h.check(
			"Refresh runs module again once enabled",
			#log == 2,
			table.concat(log, ",")
		)
		addon:SetModuleEnabled(idA, wasEnabled)
	end

	addon:UnregisterRefreshCallback(idA)
	addon:UnregisterRefreshCallback(idB)
	addon:UnregisterRefreshCallback(idC)
end
