local ADDON_NAME, ns = ...

function ns.BuildBuffBarArgs(ctx)
	local db = ctx.db
	local L = ctx.L
	local addon = ctx.addon
	local a = {
buffBarEnabled = {
	type = "toggle",
	name = L["BUFF_BAR_ENABLED"],
	order = 1,
	width = "full",
	get = function()
		return db().buffBarEnabled ~= false
	end,
	set = function(_, v)
		db().buffBarEnabled = v and true or false
		ctx.RefreshSkin()
	end,
},
buffBarStyle = {
	type = "select",
	name = L["BUFF_BAR_STYLE"],
	order = 2,
	values = {
		blizzard = L["BUFF_BAR_STYLE_BLIZZARD"],
		solid = L["BUFF_BAR_STYLE_SOLID"],
	},
	get = function()
		return db().buffBarStyle or "solid"
	end,
	set = function(_, v)
		db().buffBarStyle = v
		ctx.RefreshBuffBars()
	end,
},
buffBarTexture = {
	type = "select",
	name = L["BUFF_BAR_TEXTURE"],
	desc = L["BUFF_BAR_TEXTURE_DESC"],
	order = 3,
	values = function()
		return addon.Skin.ListMedia("statusbar")
	end,
	disabled = function()
		local s = db().buffBarStyle or "solid"
		return s ~= "solid" and s ~= "SharedMedia"
	end,
	get = function()
		return db().buffBarTexture or "Solid"
	end,
	set = function(_, v)
		db().buffBarTexture = v
		ctx.RefreshBuffBars()
	end,
},
buffBarBackgroundTexture = {
	type = "select",
	name = L["BUFF_BAR_BG_TEXTURE"],
	order = 4,
	values = function()
		return addon.Skin.ListMedia("statusbar")
	end,
	disabled = function()
		local s = db().buffBarStyle or "solid"
		return s ~= "solid" and s ~= "SharedMedia"
	end,
	get = function()
		return db().buffBarBackgroundTexture or "Solid"
	end,
	set = function(_, v)
		db().buffBarBackgroundTexture = v
		ctx.RefreshBuffBars()
	end,
},
buffBarHeight = {
	type = "range",
	name = L["BUFF_BAR_HEIGHT"],
	order = 5,
	min = 4,
	max = 64,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().buffBarHeight or 16
	end,
	set = function(_, v)
		db().buffBarHeight = v
		ctx.RefreshBuffBars()
	end,
},
buffBarFollowEssential = {
	type = "toggle",
	name = L["BUFF_BAR_FOLLOW_ESSENTIAL"],
	desc = L["BUFF_BAR_FOLLOW_ESSENTIAL_DESC"],
	order = 5.5,
	width = "full",
	get = function()
		return db().buffBarFollowEssential ~= false
	end,
	set = function(_, v)
		db().buffBarFollowEssential = v and true or false
		if not v then
			db().viewerPos = db().viewerPos or {}
			local t = db().viewerPos.buffBar or {}
			db().viewerPos.buffBar = {
				enabled = true,
				point = t.point or "CENTER",
				x = t.x or 0,
				y = t.y or 80,
			}
			if not db().buffBarWidth or db().buffBarWidth < 200 then
				db().buffBarWidth = 200
			end
		end
		ctx.RefreshLayout()
		ctx.RefreshSkin()
	end,
},
	}
	for k, v in pairs(ns.BuildBuffBarArgsMore(ctx)) do
		a[k] = v
	end
	return a
end
