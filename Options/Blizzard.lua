local ADDON_NAME, ns = ...
local L = ns.L

function ns.BuildBlizzardArgs()
	return {
		hint = {
			type = "description",
			name = L["BLIZZARD_DESC"],
			order = 1,
			fontSize = "medium",
		},
	}
end
