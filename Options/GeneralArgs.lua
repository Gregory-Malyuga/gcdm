local ADDON_NAME, ns = ...

function ns.BuildGeneralArgs(ctx)
	local db = ctx.db
	local L = ctx.L
	local addon = ctx.addon
	return {
enabled = {
	type = "toggle",
	name = L["ENABLED"],
	desc = L["ENABLED_DESC"],
	order = 1,
	width = "full",
	get = function()
		return db().enabled
	end,
	set = function(_, value)
		db().enabled = value
		addon:Refresh()
	end,
},
hint = {
	type = "description",
	name = L["PLACEHOLDER"] .. "\n" .. L["OPEN_HINT"],
	order = 2,
	fontSize = "medium",
},
debugSkin = {
	type = "toggle",
	name = L["DEBUG_SKIN"],
	desc = L["DEBUG_SKIN_DESC"],
	order = 3,
	width = "full",
	get = function()
		return db().debugSkin
	end,
	set = function(_, value)
		db().debugSkin = value
		ctx.RefreshSkin()
		if value then
			addon:DumpSkinDebug()
		end
	end,
},
debugEditMode = {
	type = "toggle",
	name = L["DEBUG_EDIT_MODE"],
	desc = L["DEBUG_EDIT_MODE_DESC"],
	order = 3.2,
	width = "full",
	get = function()
		return db().debugEditMode and true or false
	end,
	set = function(_, value)
		db().debugEditMode = value and true or false
	end,
},
dumpLog = {
	type = "execute",
	name = L["DUMP_LOG"],
	desc = L["DUMP_LOG_DESC"],
	order = 3.5,
	width = "full",
	func = function()
		local ok, err = pcall(function()
			addon:DumpBuffBarDebug()
		end)
		if not ok then
			print("|cff3bb273GCDM|r dump ERROR: " .. tostring(err))
		end
	end,
},
dumpEditMode = {
	type = "execute",
	name = L["DUMP_EDIT_MODE"],
	desc = L["DUMP_EDIT_MODE_DESC"],
	order = 3.55,
	width = "full",
	func = function()
		local ok, err = pcall(function()
			addon:DumpEditModeDebug(false)
		end)
		if not ok then
			print("|cff3bb273GCDM|r editdump ERROR: " .. tostring(err))
		end
	end,
},
runTests = {

	type = "execute",
	name = L["RUN_TESTS"],
	desc = L["RUN_TESTS_DESC"],
	order = 3.6,
	width = "full",
	func = function()
		local ok, err = pcall(function()
			addon:RunBehaviorTests()
		end)
		if not ok then
			print("|cff3bb273GCDM|r test ERROR: " .. tostring(err))
		end
	end,
},
modulesHeader = {
	type = "header",
	name = L["MODULES"],
	order = 5,
},
modulesHint = {
	type = "description",
	name = L["MODULES_DESC"],
	order = 5.1,
	fontSize = "medium",
},
safeMode = {
	type = "toggle",
	name = L["SAFE_MODE"],
	desc = L["SAFE_MODE_DESC"],
	order = 5.2,
	width = "full",
	get = function()
		return addon:IsSafeMode()
	end,
	set = function(_, value)
		addon:SetSafeMode(value and true or false)
		addon:Refresh()
	end,
},
modules = {
	type = "multiselect",
	name = L["MODULES_ACTIVE"],
	desc = L["MODULES_ACTIVE_DESC"],
	order = 5.3,
	values = function()
		local values = {}
		local ids = addon:GetRefreshModuleIDs()
		for i = 1, #ids do
			values[ids[i]] = ids[i]
		end
		return values
	end,
	get = function(_, key)
		return addon:IsModuleEnabled(key)
	end,
	set = function(_, key, value)
		addon:SetModuleEnabled(key, value)
		addon:Refresh()
	end,
},
hidePandemicIndicator = {
	type = "toggle",
	name = L["HIDE_PANDEMIC"],
	desc = L["HIDE_PANDEMIC_DESC"],
	order = 4,
	width = "full",
	get = function()
		return db().hidePandemicIndicator ~= false
	end,
	set = function(_, value)
		db().hidePandemicIndicator = value and true or false
		ctx.RefreshSkin()
	end,
},
	}
end
