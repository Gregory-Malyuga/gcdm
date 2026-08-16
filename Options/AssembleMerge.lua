local ADDON_NAME, ns = ...
local L = ns.L

function ns.OptionsTakePos(posArgs, key, orderBase)
	orderBase = orderBase or 50
	local enabled = posArgs[key .. "Enabled"]
	local point = posArgs[key .. "Point"]
	local x = posArgs[key .. "X"]
	local y = posArgs[key .. "Y"]
	if enabled then
		enabled.order = orderBase + 1
	end
	if point then
		point.order = orderBase + 2
	end
	if x then
		x.order = orderBase + 3
	end
	if y then
		y.order = orderBase + 4
	end
	return {
		posHeader = { type = "header", name = L["POSITIONS"], order = orderBase },
		posHint = {
			type = "description",
			name = L["POSITIONS_DESC"],
			order = orderBase + 0.5,
			fontSize = "medium",
		},
		posEnabled = enabled,
		posPoint = point,
		posX = x,
		posY = y,
	}
end

function ns.OptionsMergeArgs(...)
	local out = {}
	for i = 1, select("#", ...) do
		local t = select(i, ...)
		if t then
			for k, v in pairs(t) do
				out[k] = v
			end
		end
	end
	return out
end
