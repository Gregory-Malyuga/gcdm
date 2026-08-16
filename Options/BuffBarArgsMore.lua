local ADDON_NAME, ns = ...

function ns.BuildBuffBarArgsMore(ctx)
	local db = ctx.db
	local L = ctx.L
	local addon = ctx.addon
	return {
buffBarWidth = {
	type = "range",
	name = L["BUFF_BAR_WIDTH"],
	desc = L["BUFF_BAR_WIDTH_DESC"],
	order = 6,
	min = 200,
	max = 600,
	step = ctx.FSTEP,
	bigStep = 1,
	disabled = function()
		return db().buffBarFollowEssential ~= false
	end,
	get = function()
		local w = db().buffBarWidth or 200
		if w < 200 then
			w = 200
		end
		return w
	end,
	set = function(_, v)
		db().buffBarWidth = math.max(200, v)
		ctx.RefreshLayout()
		ctx.RefreshSkin()
	end,
},
buffBarShowIcon = {
	type = "toggle",
	name = L["BUFF_BAR_SHOW_ICON"],
	order = 7,
	get = function()
		return db().buffBarShowIcon ~= false
	end,
	set = function(_, v)
		db().buffBarShowIcon = v and true or false
		ctx.RefreshSkin()
	end,
},
buffBarShowName = {
	type = "toggle",
	name = L["BUFF_BAR_SHOW_NAME"],
	order = 8,
	get = function()
		return db().buffBarShowName ~= false
	end,
	set = function(_, v)
		db().buffBarShowName = v and true or false
		ctx.RefreshSkin()
	end,
},
buffBarShowDuration = {
	type = "toggle",
	name = L["BUFF_BAR_SHOW_DURATION"],
	order = 9,
	get = function()
		return db().buffBarShowDuration ~= false
	end,
	set = function(_, v)
		db().buffBarShowDuration = v and true or false
		ctx.RefreshSkin()
	end,
},
barSmoothProgress = {
	type = "toggle",
	name = L["BAR_SMOOTH"],
	desc = L["BAR_SMOOTH_DESC"],
	order = 8.5,
	width = "full",
	get = function()
		return db().barSmoothProgress == true
	end,
	set = function(_, v)
		db().barSmoothProgress = v and true or false
		ctx.RefreshSkin()
	end,
},
buffBarColor = {
	type = "color",
	name = L["BUFF_BAR_COLOR"],
	order = 10,
	hasAlpha = true,
	disabled = function()
		local s = db().buffBarStyle or "solid"
		return s ~= "solid" and s ~= "SharedMedia"
	end,
	get = function()
		return ctx.getColor("buffBarColor", { r = 0.4, g = 0.6, b = 0.9, a = 1 })
	end,
	set = function(_, r, g, b, a)
		ctx.setColor("buffBarColor", r, g, b, a)
		ctx.RefreshBuffBars()
	end,
},
buffBarBackgroundColor = {
	type = "color",
	name = L["BUFF_BAR_BG_COLOR"],
	order = 11,
	hasAlpha = true,
	disabled = function()
		local s = db().buffBarStyle or "solid"
		return s ~= "solid" and s ~= "SharedMedia"
	end,
	get = function()
		return ctx.getColor("buffBarBackgroundColor", { r = 0.1, g = 0.1, b = 0.1, a = 0.8 })
	end,
	set = function(_, r, g, b, a)
		ctx.setColor("buffBarBackgroundColor", r, g, b, a)
		ctx.RefreshBuffBars()
	end,
},
	}
end
