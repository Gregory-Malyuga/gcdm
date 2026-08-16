local ADDON_NAME, ns = ...

function ns.BuildSkinSizesArgs(ctx)
	local db = ctx.db
	local L = ctx.L
	local addon = ctx.addon
	return {
essW = {
	type = "range",
	name = L["SIZE_ESSENTIAL"] .. " " .. L["WIDTH"],
	order = 1,
	min = 16,
	max = 96,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().sizeEssential.w
	end,
	set = function(_, v)
		setSize(db().sizeEssential, "w", v)
	end,
},
essH = {
	type = "range",
	name = L["SIZE_ESSENTIAL"] .. " " .. L["HEIGHT"],
	order = 2,
	min = 16,
	max = 96,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().sizeEssential.h
	end,
	set = function(_, v)
		setSize(db().sizeEssential, "h", v)
	end,
},
ess2W = {
	type = "range",
	name = L["SIZE_ESSENTIAL_ROW2"] .. " " .. L["WIDTH"],
	order = 3,
	min = 16,
	max = 96,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().sizeEssentialRow2.w
	end,
	set = function(_, v)
		setSize(db().sizeEssentialRow2, "w", v)
	end,
},
ess2H = {
	type = "range",
	name = L["SIZE_ESSENTIAL_ROW2"] .. " " .. L["HEIGHT"],
	order = 4,
	min = 16,
	max = 96,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().sizeEssentialRow2.h
	end,
	set = function(_, v)
		setSize(db().sizeEssentialRow2, "h", v)
	end,
},
utilW = {
	type = "range",
	name = L["SIZE_UTILITY"] .. " " .. L["WIDTH"],
	order = 5,
	min = 16,
	max = 96,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().sizeUtility.w
	end,
	set = function(_, v)
		setSize(db().sizeUtility, "w", v)
	end,
},
utilH = {
	type = "range",
	name = L["SIZE_UTILITY"] .. " " .. L["HEIGHT"],
	order = 6,
	min = 16,
	max = 96,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().sizeUtility.h
	end,
	set = function(_, v)
		setSize(db().sizeUtility, "h", v)
	end,
},
buffW = {
	type = "range",
	name = L["SIZE_BUFF"] .. " " .. L["WIDTH"],
	order = 7,
	min = 16,
	max = 96,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().sizeBuff.w
	end,
	set = function(_, v)
		setSize(db().sizeBuff, "w", v)
	end,
},
buffH = {
	type = "range",
	name = L["SIZE_BUFF"] .. " " .. L["HEIGHT"],
	order = 8,
	min = 16,
	max = 96,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().sizeBuff.h
	end,
	set = function(_, v)
		setSize(db().sizeBuff, "h", v)
	end,
},
	}
end
