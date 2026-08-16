local ADDON_NAME, ns = ...
local L = ns.L

--- Attach GCDM export/import controls onto AceDBOptions profiles args.
function ns.AttachProfileShareOptions(addon, profilesArgs)
	if not profilesArgs then
		return
	end
	local share = {
		exportString = "",
		importString = "",
		importName = "",
		importMode = "new",
		status = "",
	}
	local function ImportErrorMessage(err)
		if err == "empty" then
			return L["PROFILE_IMPORT_ERR_EMPTY"]
		end
		if err == "encoding_unavailable" then
			return L["PROFILE_IMPORT_ERR_ENCODING"]
		end
		if err == "wrong_addon" then
			return L["PROFILE_IMPORT_ERR_ADDON"]
		end
		return L["PROFILE_IMPORT_ERR_INVALID"]
	end

	profilesArgs.gcdmShareHeader = {
		type = "header",
		name = L["PROFILE_SHARE"],
		order = 200,
	}
	profilesArgs.gcdmShareDesc = {
		type = "description",
		name = L["PROFILE_SHARE_DESC"],
		order = 201,
		fontSize = "medium",
	}
	profilesArgs.gcdmExportBtn = {
		type = "execute",
		name = L["PROFILE_EXPORT"],
		order = 202,
		width = "full",
		func = function()
			local str, err = addon:ExportProfileString()
			if not str then
				share.status = L["PROFILE_EXPORT_ERR"] .. (err and (" (" .. err .. ")") or "")
				share.exportString = ""
			else
				share.exportString = str
				share.status = L["PROFILE_EXPORT_HINT"]
			end
		end,
	}
	profilesArgs.gcdmExportString = {
		type = "input",
		name = L["PROFILE_EXPORT_STRING"],
		order = 203,
		width = "full",
		multiline = 6,
		get = function()
			return share.exportString
		end,
		set = function(_, v)
			share.exportString = v or ""
		end,
	}
	profilesArgs.gcdmImportString = {
		type = "input",
		name = L["PROFILE_IMPORT_STRING"],
		order = 210,
		width = "full",
		multiline = 6,
		get = function()
			return share.importString
		end,
		set = function(_, v)
			share.importString = v or ""
		end,
	}
	profilesArgs.gcdmImportName = {
		type = "input",
		name = L["PROFILE_IMPORT_NAME"],
		desc = L["PROFILE_IMPORT_NAME_DESC"],
		order = 211,
		width = "full",
		get = function()
			return share.importName
		end,
		set = function(_, v)
			share.importName = v or ""
		end,
	}
	profilesArgs.gcdmImportMode = {
		type = "select",
		name = L["PROFILE_IMPORT_MODE"],
		order = 212,
		values = {
			new = L["PROFILE_IMPORT_MODE_NEW"],
			current = L["PROFILE_IMPORT_MODE_CURRENT"],
		},
		get = function()
			return share.importMode
		end,
		set = function(_, v)
			share.importMode = v
		end,
	}
	profilesArgs.gcdmImportBtn = {
		type = "execute",
		name = L["PROFILE_IMPORT"],
		order = 213,
		width = "full",
		func = function()
			local name, err = addon:ImportProfileString(
				share.importString,
				share.importMode,
				(share.importName ~= "" and share.importName) or nil
			)
			if not name then
				share.status = ImportErrorMessage(err)
			else
				share.status = string.format(L["PROFILE_IMPORT_OK"], name)
				share.importString = ""
				LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
			end
		end,
	}
	profilesArgs.gcdmShareStatus = {
		type = "description",
		name = function()
			return share.status or ""
		end,
		order = 220,
		fontSize = "medium",
	}
end
