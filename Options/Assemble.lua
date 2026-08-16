local ADDON_NAME, ns = ...
local L = ns.L

--- Reorganize skin subgroups into Essential / Utility / Buff / BuffBar / Power tabs.
function ns.AssembleBlockTabs(addon, options, ctx)
	local skinArgs = options.args.skin.args
	local layoutArgs = skinArgs.layout.args
	local sizeArgs = skinArgs.sizes.args
	local posArgs = skinArgs.positions.args
	local mergeArgs = ns.OptionsMergeArgs
	local takePos = ns.OptionsTakePos

	local generalArgs = options.args.general.args
	generalArgs.iconStyleHeader = {
		type = "header",
		name = L["ICON_STYLE"],
		order = 20,
	}
	generalArgs.pixelSnap = layoutArgs.pixelSnap
	if generalArgs.pixelSnap then
		generalArgs.pixelSnap.order = 21
	end
	do
		local border = skinArgs.border.args
		for k, v in pairs(border) do
			v.order = 30 + (v.order or 0)
			generalArgs["border_" .. k] = v
		end
		local glow = skinArgs.glow.args
		for k, v in pairs(glow) do
			v.order = 80 + (v.order or 0)
			generalArgs["glow_" .. k] = v
		end
	end

	if sizeArgs.essW then
		sizeArgs.essW.name = L["WIDTH"]
		sizeArgs.essW.order = 11
	end
	if sizeArgs.essH then
		sizeArgs.essH.name = L["HEIGHT"]
		sizeArgs.essH.order = 12
	end
	if sizeArgs.ess2W then
		sizeArgs.ess2W.name = L["SIZE_ESSENTIAL_ROW2"] .. " — " .. L["WIDTH"]
		sizeArgs.ess2W.order = 13
	end
	if sizeArgs.ess2H then
		sizeArgs.ess2H.name = L["SIZE_ESSENTIAL_ROW2"] .. " — " .. L["HEIGHT"]
		sizeArgs.ess2H.order = 14
	end
	if layoutArgs.spacing then
		layoutArgs.spacing.order = 5
	end
	if layoutArgs.maxIconsPerRow then
		layoutArgs.maxIconsPerRow.order = 6
	end

	local V = addon.CONST.VIEWERS
	options.args.essential = {
		type = "group",
		name = L["BLOCK_ESSENTIAL"],
		order = 2,
		args = mergeArgs(
			{
				layoutHeader = { type = "header", name = L["LAYOUT"], order = 1 },
				spacing = layoutArgs.spacing,
				maxIconsPerRow = layoutArgs.maxIconsPerRow,
				sizeHeader = { type = "header", name = L["SIZE"], order = 10 },
				essW = sizeArgs.essW,
				essH = sizeArgs.essH,
				ess2W = sizeArgs.ess2W,
				ess2H = sizeArgs.ess2H,
			},
			takePos(posArgs, "essential", 50),
			ns.MakeIconTextArgs(ctx, V.ESSENTIAL, 100, true)
		),
	}

	if sizeArgs.utilW then
		sizeArgs.utilW.name = L["WIDTH"]
		sizeArgs.utilW.order = 11
	end
	if sizeArgs.utilH then
		sizeArgs.utilH.name = L["HEIGHT"]
		sizeArgs.utilH.order = 12
	end
	options.args.utility = {
		type = "group",
		name = L["BLOCK_UTILITY"],
		order = 3,
		args = mergeArgs(
			{
				sizeHeader = { type = "header", name = L["SIZE"], order = 10 },
				utilW = sizeArgs.utilW,
				utilH = sizeArgs.utilH,
			},
			takePos(posArgs, "utility", 50),
			ns.MakeIconTextArgs(ctx, V.UTILITY, 100, true)
		),
	}

	if sizeArgs.buffW then
		sizeArgs.buffW.name = L["WIDTH"]
		sizeArgs.buffW.order = 11
	end
	if sizeArgs.buffH then
		sizeArgs.buffH.name = L["HEIGHT"]
		sizeArgs.buffH.order = 12
	end
	options.args.buff = {
		type = "group",
		name = L["BLOCK_BUFF"],
		order = 4,
		args = mergeArgs(
			{
				sizeHeader = { type = "header", name = L["SIZE"], order = 10 },
				buffW = sizeArgs.buffW,
				buffH = sizeArgs.buffH,
			},
			takePos(posArgs, "buff", 50),
			ns.MakeIconTextArgs(ctx, V.BUFF, 100)
		),
	}

	options.args.buffBar = {
		type = "group",
		name = L["BLOCK_BUFF_BAR"],
		order = 5,
		args = mergeArgs(
			takePos(posArgs, "buffBar", 1),
			skinArgs.buffBar.args,
			ns.MakeBuffBarTextArgs(ctx, 100)
		),
	}
	for k, v in pairs(options.args.buffBar.args) do
		if type(k) == "string" and k:sub(1, 3) ~= "pos" and type(v) == "table" and v.order and v.order < 100 then
			v.order = 20 + (v.order or 0)
		end
	end

	options.args.powerBar = {
		type = "group",
		name = L["BLOCK_POWER"],
		order = 6,
		args = skinArgs.powerBar.args,
	}

	options.args.auraSounds = {
		type = "group",
		name = L["AURA_SOUNDS"],
		order = 8,
		args = ns.BuildAuraSoundsArgs(addon, ctx.db),
	}

	options.args.blizzard = {
		type = "group",
		name = L["BLIZZARD"],
		order = 90,
		args = ns.BuildBlizzardArgs(),
	}

	options.args.profiles.order = 99
	options.args.profiles.name = L["PROFILES"]
	ns.AttachProfileShareOptions(addon, options.args.profiles.args)

	options.args.skin = nil
	options.args.bars = nil
end
