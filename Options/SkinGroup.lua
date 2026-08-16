local ADDON_NAME, ns = ...
local L = ns.L

function ns.BuildSkinArgs(ctx)
	return {
		layout = {
			type = "group",
			name = L["LAYOUT"],
			order = 1,
			args = ns.BuildSkinLayoutArgs(ctx),
		},
		positions = {
			type = "group",
			name = L["POSITIONS"],
			order = 1.5,
			args = ns.BuildSkinPositionsArgs(ctx),
		},
		sizes = {
			type = "group",
			name = L["SIZE"],
			order = 2,
			args = ns.BuildSkinSizesArgs(ctx),
		},
		border = {
			type = "group",
			name = L["BORDER"],
			order = 3,
			args = ns.BuildSkinBorderArgs(ctx),
		},
		glow = {
			type = "group",
			name = L["GLOW"],
			order = 4,
			args = ns.BuildSkinGlowArgs(ctx),
		},
		buffBar = {
			type = "group",
			name = L["BUFF_BAR"],
			order = 5,
			args = ns.BuildBuffBarArgs(ctx),
		},
		powerBar = {
			type = "group",
			name = L["POWER_BAR"],
			order = 6,
			args = ns.BuildPowerBarArgs(ctx),
		},
	}
end
