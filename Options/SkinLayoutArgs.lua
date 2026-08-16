local ADDON_NAME, ns = ...

function ns.BuildSkinLayoutArgs(ctx)
	local db = ctx.db
	local L = ctx.L
	local addon = ctx.addon
	return {
pixelSnap = {
	type = "toggle",
	name = L["PIXEL_SNAP"],
	desc = L["PIXEL_SNAP_DESC"],
	order = 0,
	width = "full",
	get = function()
		return db().pixelSnap == true
	end,
	set = function(_, v)
		db().pixelSnap = v and true or false
		ctx.RefreshLayout()
		ctx.RefreshSkin()
	end,
},
spacing = {
	type = "range",
	name = L["SPACING"],
	desc = L["SPACING_DESC"],
	order = 1,
	min = 0,
	max = 20,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().spacing or 0
	end,
	set = function(_, v)
		db().spacing = v
		ctx.RefreshLayout()
	end,
},
maxIconsPerRow = {
	type = "range",
	name = L["MAX_PER_ROW"],
	desc = L["MAX_PER_ROW_DESC"],
	order = 2,
	min = 1,
	max = 16,
	step = 1,
	get = function()
		return db().maxIconsPerRow
	end,
	set = function(_, v)
		db().maxIconsPerRow = v
		ctx.RefreshSkin()
	end,
},
	}
end
