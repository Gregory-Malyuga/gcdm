local ADDON_NAME, ns = ...

function ns.BuildPowerBarArgsMore(ctx)
	local db = ctx.db
	local L = ctx.L
	local addon = ctx.addon
	local OUTLINE_VALUES = ctx.OUTLINE_VALUES
	return {
powerBarFont = {
	type = "select",
	name = L["TEXT_FONT"],
	order = 7.4,
	values = function()
		return addon.Skin.ListMedia("font")
	end,
	get = function()
		return addon.Skin.ResolveFontName(db().powerBarFont or addon.Skin.DefaultFontName())
	end,
	set = function(_, v)
		db().powerBarFont = v
		ctx.RefreshSkin()
	end,
},
powerBarTextOutline = {
	type = "select",
	name = L["TEXT_OUTLINE"],
	order = 7.5,
	values = OUTLINE_VALUES,
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
},
powerBarTexture = {
	type = "select",
	name = L["POWER_BAR_TEXTURE"],
	order = 8,
	values = function()
		return addon.Skin.ListMedia("statusbar")
	end,
	get = function()
		return db().powerBarTexture or "Solid"
	end,
	set = function(_, v)
		db().powerBarTexture = v
		ctx.RefreshSkin()
	end,
},
powerBarBackgroundTexture = {
	type = "select",
	name = L["POWER_BAR_BG_TEXTURE"],
	order = 9,
	values = function()
		return addon.Skin.ListMedia("statusbar")
	end,
	get = function()
		return db().powerBarBackgroundTexture or "Solid"
	end,
	set = function(_, v)
		db().powerBarBackgroundTexture = v
		ctx.RefreshSkin()
	end,
},
powerBarBackgroundColor = {
	type = "color",
	name = L["POWER_BAR_BG_COLOR"],
	order = 9.5,
	hasAlpha = true,
	get = function()
		return ctx.getColor("powerBarBackgroundColor", { r = 0.1, g = 0.1, b = 0.1, a = 0.85 })
	end,
	set = function(_, r, g, b, a)
		ctx.setColor("powerBarBackgroundColor", r, g, b, a)
		ctx.RefreshSkin()
	end,
},
powerBarTextColor = {
	type = "color",
	name = L["POWER_BAR_TEXT_COLOR"],
	order = 9.6,
	hasAlpha = true,
	get = function()
		return ctx.getColor("powerBarTextColor", { r = 1, g = 1, b = 1, a = 1 })
	end,
	set = function(_, r, g, b, a)
		ctx.setColor("powerBarTextColor", r, g, b, a)
		ctx.RefreshSkin()
	end,
},
powerBarEditClass = {
	type = "select",
	name = L["POWER_BAR_EDIT_CLASS"],
	desc = L["POWER_BAR_EDIT_CLASS_DESC"],
	order = 10,
	width = "full",
	values = function()
		local t = {}
		local files = addon.Skin.PowerBarClassFiles or { "DEFAULT" }
		for i = 1, #files do
			t[files[i]] = files[i]
		end
		return t
	end,
	get = function()
		return db().powerBarEditClass or "DEFAULT"
	end,
	set = function(_, v)
		db().powerBarEditClass = v
	end,
},
powerBarColorMode = {
	type = "select",
	name = L["POWER_BAR_COLOR_MODE"],
	desc = L["POWER_BAR_COLOR_MODE_DESC"],
	order = 11,
	values = {
		class = L["POWER_BAR_MODE_CLASS"],
		solid = L["POWER_BAR_MODE_SOLID"],
	},
	get = function()
		local cls = db().powerBarEditClass or "DEFAULT"
		local mode = addon.Skin.GetPowerBarProfile(db(), cls).colorMode or "class"
		if mode == "curve" then
			return "class"
		end
		return mode
	end,
	set = function(_, v)
		local cls = db().powerBarEditClass or "DEFAULT"
		addon.Skin.SetPowerBarProfileField(db(), cls, "colorMode", v)
		ctx.RefreshSkin()
	end,
},
powerBarSolidColor = {
	type = "color",
	name = L["POWER_BAR_COLOR"],
	order = 12,
	hasAlpha = true,
	disabled = function()
		local cls = db().powerBarEditClass or "DEFAULT"
		return (addon.Skin.GetPowerBarProfile(db(), cls).colorMode or "class") ~= "solid"
	end,
	get = function()
		local cls = db().powerBarEditClass or "DEFAULT"
		local c = addon.Skin.GetPowerBarProfile(db(), cls).solidColor
			or { r = 0.55, g = 0.1, b = 0.1, a = 1 }
		return c.r or 1, c.g or 1, c.b or 1, c.a or 1
	end,
	set = function(_, r, g, b, a)
		local cls = db().powerBarEditClass or "DEFAULT"
		addon.Skin.SetPowerBarProfileField(db(), cls, "solidColor", { r = r, g = g, b = b, a = a })
		ctx.RefreshSkin()
	end,
},
	}
end
