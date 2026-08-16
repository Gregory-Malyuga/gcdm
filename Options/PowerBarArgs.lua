local ADDON_NAME, ns = ...

function ns.BuildPowerBarArgs(ctx)
	local db = ctx.db
	local L = ctx.L
	local addon = ctx.addon
	local a = {
powerBarEnabled = {
	type = "toggle",
	name = L["POWER_BAR_ENABLED"],
	desc = L["POWER_BAR_ENABLED_DESC"],
	order = 1,
	width = "full",
	get = function()
		return db().powerBarEnabled ~= false
	end,
	set = function(_, v)
		db().powerBarEnabled = v and true or false
		ctx.RefreshLayout()
		ctx.RefreshSkin()
	end,
},
powerBarShowSecondary = {
	type = "toggle",
	name = L["POWER_BAR_SECONDARY"],
	desc = L["POWER_BAR_SECONDARY_DESC"],
	order = 2,
	width = "full",
	get = function()
		return db().powerBarShowSecondary ~= false
	end,
	set = function(_, v)
		db().powerBarShowSecondary = v and true or false
		ctx.RefreshLayout()
		ctx.RefreshSkin()
	end,
},
powerBarShowText = {
	type = "toggle",
	name = L["POWER_BAR_SHOW_TEXT"],
	order = 3,
	get = function()
		return db().powerBarShowText ~= false
	end,
	set = function(_, v)
		db().powerBarShowText = v and true or false
		ctx.RefreshSkin()
	end,
},
barSmoothProgress = {
	type = "toggle",
	name = L["BAR_SMOOTH"],
	desc = L["BAR_SMOOTH_DESC"],
	order = 3.2,
	width = "full",
	get = function()
		return db().barSmoothProgress == true
	end,
	set = function(_, v)
		db().barSmoothProgress = v and true or false
		ctx.RefreshSkin()
	end,
},
powerBarHeight = {
	type = "range",
	name = L["POWER_BAR_HEIGHT"],
	order = 4,
	min = 1,
	max = 40,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().powerBarHeight or 10
	end,
	set = function(_, v)
		db().powerBarHeight = v
		ctx.RefreshLayout()
		ctx.RefreshSkin()
	end,
},
powerBarFollowEssential = {
	type = "toggle",
	name = L["POWER_BAR_FOLLOW_ESSENTIAL"],
	desc = L["POWER_BAR_FOLLOW_ESSENTIAL_DESC"],
	order = 4.5,
	width = "full",
	get = function()
		return db().powerBarFollowEssential ~= false
	end,
	set = function(_, v)
		db().powerBarFollowEssential = v and true or false
		if not v then
			db().viewerPos = db().viewerPos or {}
			local t = db().viewerPos.powerBar or {}
			db().viewerPos.powerBar = {
				enabled = true,
				point = t.point or "CENTER",
				x = t.x or 0,
				y = t.y or -100,
			}
			if not db().powerBarWidth or db().powerBarWidth < 200 then
				db().powerBarWidth = 200
			end
		end
		ctx.RefreshLayout()
		ctx.RefreshSkin()
	end,
},
powerBarWidth = {
	type = "range",
	name = L["POWER_BAR_WIDTH"],
	desc = L["POWER_BAR_WIDTH_DESC"],
	order = 5,
	min = 200,
	max = 600,
	step = ctx.FSTEP,
	bigStep = 1,
	disabled = function()
		return db().powerBarFollowEssential ~= false
	end,
	get = function()
		local w = db().powerBarWidth or 200
		if w < 200 then
			w = 200
		end
		return w
	end,
	set = function(_, v)
		db().powerBarWidth = math.max(200, v)
		ctx.RefreshLayout()
		ctx.RefreshSkin()
	end,
},
powerBarGap = {
	type = "range",
	name = L["POWER_BAR_GAP"],
	order = 6,
	min = 0,
	max = 40,
	step = ctx.FSTEP,
	bigStep = 1,
	disabled = function()
		return db().powerBarFollowEssential == false
	end,
	get = function()
		return db().powerBarGap or 2
	end,
	set = function(_, v)
		db().powerBarGap = v
		ctx.RefreshLayout()
	end,
},
powerBarFontSize = {
	type = "range",
	name = L["POWER_BAR_FONT_SIZE"],
	order = 7,
	min = 8,
	max = 28,
	step = 1,
	get = function()
		return db().powerBarFontSize or 12
	end,
	set = function(_, v)
		db().powerBarFontSize = v
		ctx.RefreshSkin()
	end,
},
	}
	if type(ns.BuildPowerBarArgsMore) == "function" then
		for k, v in pairs(ns.BuildPowerBarArgsMore(ctx)) do
			a[k] = v
		end
	end
	-- Always stamp outline values AFTER More merge. A stale PowerBarArgsMore that
	-- still says `values = OUTLINE_VALUES` (nil global) must not win.
	a.powerBarTextOutline = {
		type = "select",
		name = L["TEXT_OUTLINE"] or "Outline",
		order = 7.5,
		values = {
			NONE = "None",
			OUTLINE = "Outline",
			THICKOUTLINE = "Thick",
			MONOCHROME = "Monochrome",
		},
		get = function()
			local v = db().powerBarTextOutline or "OUTLINE"
			if v == "" then
				return "NONE"
			end
			return v
		end,
		set = function(_, v)
			db().powerBarTextOutline = (v == "NONE") and "" or v
			ctx.RefreshSkin()
		end,
	}
	return a
end
