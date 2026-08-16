local ADDON_NAME, ns = ...

function ns.BuildSkinGlowArgs(ctx)
	local db = ctx.db
	local L = ctx.L
	local addon = ctx.addon
	return {
glowEnabled = {
	type = "toggle",
	name = L["GLOW_ENABLED"],
	desc = L["GLOW_ENABLED_DESC"],
	order = 1,
	width = "full",
	get = function()
		return db().glowEnabled ~= false
	end,
	set = function(_, v)
		db().glowEnabled = v and true or false
		ctx.RefreshGlow()
	end,
},
glowAutoFit = {
	type = "toggle",
	name = L["GLOW_AUTOFIT"],
	desc = L["GLOW_AUTOFIT_DESC"],
	order = 2,
	width = "full",
	get = function()
		return db().glowAutoFit ~= false
	end,
	set = function(_, v)
		db().glowAutoFit = v and true or false
		ctx.RefreshGlow()
	end,
},
glowScale = {
	type = "range",
	name = L["GLOW_SCALE"],
	order = 3,
	min = 0.5,
	max = 2.5,
	step = 0.05,
	isPercent = true,
	get = function()
		return db().glowScale or 1
	end,
	set = function(_, v)
		db().glowScale = v
		ctx.RefreshGlow()
	end,
},
glowOffsetX = {
	type = "range",
	name = L["GLOW_OFFSET_X"],
	order = 4,
	min = -40,
	max = 40,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().glowOffsetX or 0
	end,
	set = function(_, v)
		db().glowOffsetX = v
		ctx.RefreshGlow()
	end,
},
glowOffsetY = {
	type = "range",
	name = L["GLOW_OFFSET_Y"],
	order = 5,
	min = -40,
	max = 40,
	step = ctx.FSTEP,
	bigStep = 1,
	get = function()
		return db().glowOffsetY or 0
	end,
	set = function(_, v)
		db().glowOffsetY = v
		ctx.RefreshGlow()
	end,
},
glowDisabledCooldowns = {
	type = "multiselect",
	name = L["GLOW_DISABLE_BUTTONS"],
	desc = L["GLOW_DISABLE_BUTTONS_DESC"],
	order = 6,
	values = function()
		return addon.Glow:ListVisibleCooldownOptions()
	end,
	get = function(_, key)
		local t = db().glowDisabledCooldowns or {}
		return t[key] and true or false
	end,
	set = function(_, key, value)
		db().glowDisabledCooldowns = db().glowDisabledCooldowns or {}
		if value then
			db().glowDisabledCooldowns[key] = true
		else
			db().glowDisabledCooldowns[key] = nil
		end
		ctx.RefreshGlow()
	end,
},
glowDisabledSpellsInput = {
	type = "input",
	name = L["GLOW_DISABLE_SPELLS"],
	desc = L["GLOW_DISABLE_SPELLS_DESC"],
	order = 7,
	width = "full",
	multiline = false,
	get = function()
		local t = db().glowDisabledSpells or {}
		local ids = {}
		for id in pairs(t) do
			ids[#ids + 1] = tostring(id)
		end
		table.sort(ids, function(a, b)
			return tonumber(a) < tonumber(b)
		end)
		return table.concat(ids, ", ")
	end,
	set = function(_, v)
		local t = {}
		for part in string.gmatch(v or "", "[^,%s]+") do
			local id = tonumber(part)
			if id then
				t[id] = true
			end
		end
		db().glowDisabledSpells = t
		ctx.RefreshGlow()
	end,
},
	}
end
