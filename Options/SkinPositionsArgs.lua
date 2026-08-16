local ADDON_NAME, ns = ...

function ns.BuildSkinPositionsArgs(ctx)
	local db = ctx.db
	local L = ctx.L
	return (function()
	local args = {
		hint = {
			type = "description",
			name = L["POSITIONS_DESC"],
			order = 0,
			fontSize = "medium",
		},
	}
	local blocks = {
		{ key = "essential", label = L["POS_ESSENTIAL"], order = 10 },
		{ key = "utility", label = L["POS_UTILITY"], order = 20 },
		{ key = "buff", label = L["POS_BUFF"], order = 30 },
		{ key = "buffBar", label = L["POS_BUFF_BAR"], order = 40 },
		{ key = "powerBar", label = L["POS_POWER_BAR"], order = 50 },
	}
	local points = {
		CENTER = L["ANCHOR_CENTER"],
		TOP = L["ANCHOR_TOP"],
		BOTTOM = L["ANCHOR_BOTTOM"],
		LEFT = L["ANCHOR_LEFT"],
		RIGHT = L["ANCHOR_RIGHT"],
		TOPLEFT = L["ANCHOR_TOPLEFT"],
		TOPRIGHT = L["ANCHOR_TOPRIGHT"],
		BOTTOMLEFT = L["ANCHOR_BOTTOMLEFT"],
		BOTTOMRIGHT = L["ANCHOR_BOTTOMRIGHT"],
	}
	local function pos(key)
		db().viewerPos = db().viewerPos or {}
		local t = db().viewerPos[key]
		if type(t) ~= "table" then
			t = { enabled = true, point = "CENTER", x = 0, y = 0 }
			db().viewerPos[key] = t
		end
		t.enabled = true
		return t
	end
	for i = 1, #blocks do
		local b = blocks[i]
		args[b.key .. "Header"] = {
			type = "header",
			name = b.label,
			order = b.order,
		}
		args[b.key .. "Point"] = {
			type = "select",
			name = L["POS_POINT"],
			order = b.order + 2,
			values = points,
			disabled = function()
				if b.key == "powerBar" then
					return db().powerBarFollowEssential ~= false
				end
				if b.key == "buffBar" and db().buffBarFollowEssential == false then
					return false
				end
				return false
			end,
			get = function()
				return pos(b.key).point or "CENTER"
			end,
			set = function(_, v)
				local t = pos(b.key)
				db().viewerPos[b.key] = {
					enabled = true,
					point = v,
					x = t.x or 0,
					y = t.y or 0,
				}
				ctx.RefreshLayout()
			end,
		}
		args[b.key .. "X"] = {
			type = "range",
			name = L["POS_X"],
			order = b.order + 3,
			min = -1000,
			max = 1000,
			softMin = -500,
			softMax = 500,
			step = ctx.FSTEP,
			bigStep = 1,
			disabled = function()
				if b.key == "powerBar" then
					return db().powerBarFollowEssential ~= false
				end
				if b.key == "buffBar" and db().buffBarFollowEssential == false then
					return false
				end
				return false
			end,
			get = function()
				return pos(b.key).x or 0
			end,
			set = function(_, v)
				local t = pos(b.key)
				db().viewerPos[b.key] = {
					enabled = true,
					point = t.point or "CENTER",
					x = v,
					y = t.y or 0,
				}
				ctx.RefreshLayout()
			end,
		}
		args[b.key .. "Y"] = {
			type = "range",
			name = L["POS_Y"],
			order = b.order + 4,
			min = -1000,
			max = 1000,
			softMin = -500,
			softMax = 500,
			step = ctx.FSTEP,
			bigStep = 1,
			disabled = function()
				if b.key == "powerBar" then
					return db().powerBarFollowEssential ~= false
				end
				if b.key == "buffBar" and db().buffBarFollowEssential == false then
					return false
				end
				return false
			end,
			get = function()
				return pos(b.key).y or 0
			end,
			set = function(_, v)
				local t = pos(b.key)
				db().viewerPos[b.key] = {
					enabled = true,
					point = t.point or "CENTER",
					x = t.x or 0,
					y = v,
				}
				ctx.RefreshLayout()
			end,
		}
	end
	return args
end)()
end
