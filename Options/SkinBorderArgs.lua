local ADDON_NAME, ns = ...

function ns.BuildSkinBorderArgs(ctx)
	local db = ctx.db
	local L = ctx.L
	local addon = ctx.addon
	return {
borderSize = {
	type = "range",
	name = L["BORDER_SIZE"],
	order = 1,
	min = 0,
	max = 4,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().borderSize
	end,
	set = function(_, v)
		db().borderSize = v
		ctx.RefreshSkin()
	end,
},
borderTexture = {
	type = "select",
	name = L["BORDER_TEXTURE"],
	desc = L["BORDER_TEXTURE_DESC"],
	order = 2,
	values = function()
		return addon.Skin.ListMedia("border")
	end,
	get = function()
		return db().borderTexture or "Solid"
	end,
	set = function(_, v)
		db().borderTexture = v
		ctx.RefreshSkin()
	end,
},
borderColor = {
	type = "color",
	name = L["BORDER_COLOR"],
	order = 3,
	hasAlpha = true,
	get = function()
		return ctx.getColor("borderColor", { r = 0, g = 0, b = 0, a = 1 })
	end,
	set = function(_, r, g, b, a)
		ctx.setColor("borderColor", r, g, b, a)
		ctx.RefreshSkin()
	end,
},
iconZoom = {
	type = "range",
	name = L["ICON_ZOOM"],
	desc = L["ICON_ZOOM_DESC"],
	order = 4,
	min = 0,
	max = 0.4,
	step = 0.01,
	isPercent = true,
	get = function()
		return db().iconZoom
	end,
	set = function(_, v)
		db().iconZoom = v
		ctx.RefreshSkin()
	end,
},
	}
end
