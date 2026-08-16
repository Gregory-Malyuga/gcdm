local ADDON_NAME, ns = ...

function ns.MakeBuffBarTextArgs(ctx, orderBase)
	orderBase = orderBase or 100
	local addon = ctx.addon
	local L = ctx.L
	local FSTEP = ctx.FSTEP
	local TextStyle = ctx.TextStyle
	local getStyleColor = ctx.getStyleColor
	local setStyleColor = ctx.setStyleColor
	local RefreshSkin = ctx.RefreshSkin
	local OUTLINE_VALUES = ctx.OUTLINE_VALUES
	local key = "BuffBarCooldownViewer"

	return {
		textHeader = { type = "header", name = L["TEXT"], order = orderBase },
		textFont = {
			type = "select",
			name = L["TEXT_FONT"],
			order = orderBase + 1,
			values = function()
				return addon.Skin.ListMedia("font")
			end,
			get = function()
				local st = TextStyle(key)
				return addon.Skin.ResolveFontName(st.textFont or addon.Skin.DefaultFontName())
			end,
			set = function(_, v)
				TextStyle(key).textFont = v
				RefreshSkin()
			end,
		},
		textOutline = {
			type = "select",
			name = L["TEXT_OUTLINE"],
			order = orderBase + 2,
			values = OUTLINE_VALUES,
			get = function()
				local v = TextStyle(key).textOutline or "OUTLINE"
				if v == "" then
					return "NONE"
				end
				return v
			end,
			set = function(_, v)
				TextStyle(key).textOutline = (v == "NONE") and "" or v
				RefreshSkin()
			end,
		},
		nameFontSize = {
			type = "range",
			name = L["BUFF_BAR_NAME_FONT_SIZE"],
			order = orderBase + 3,
			min = 8,
			max = 32,
			step = 1,
			get = function()
				return TextStyle(key).nameFontSize or 12
			end,
			set = function(_, v)
				TextStyle(key).nameFontSize = v
				RefreshSkin()
			end,
		},
		nameTextColor = {
			type = "color",
			name = L["BUFF_BAR_NAME_COLOR"],
			order = orderBase + 4,
			hasAlpha = true,
			get = function()
				return getStyleColor(TextStyle(key), "nameTextColor", { r = 1, g = 1, b = 1, a = 1 })
			end,
			set = function(_, r, g, b, a)
				setStyleColor(TextStyle(key), "nameTextColor", r, g, b, a)
				RefreshSkin()
			end,
		},
		durationFontSize = {
			type = "range",
			name = L["BUFF_BAR_DUR_FONT_SIZE"],
			order = orderBase + 5,
			min = 8,
			max = 32,
			step = 1,
			get = function()
				return TextStyle(key).durationFontSize or 14
			end,
			set = function(_, v)
				TextStyle(key).durationFontSize = v
				RefreshSkin()
			end,
		},
		durationTextColor = {
			type = "color",
			name = L["BUFF_BAR_DUR_COLOR"],
			order = orderBase + 6,
			hasAlpha = true,
			get = function()
				return getStyleColor(TextStyle(key), "durationTextColor", { r = 1, g = 1, b = 1, a = 1 })
			end,
			set = function(_, r, g, b, a)
				setStyleColor(TextStyle(key), "durationTextColor", r, g, b, a)
				RefreshSkin()
			end,
		},
		nameTextOffsetX = {
			type = "range",
			name = L["BUFF_BAR_NAME_OFFSET_X"],
			order = orderBase + 7,
			min = -40,
			max = 40,
			step = FSTEP,
			bigStep = 1,
			get = function()
				return TextStyle(key).nameTextOffsetX or 4
			end,
			set = function(_, v)
				TextStyle(key).nameTextOffsetX = v
				RefreshSkin()
			end,
		},
		durationTextOffsetX = {
			type = "range",
			name = L["BUFF_BAR_DUR_OFFSET_X"],
			order = orderBase + 8,
			min = -40,
			max = 40,
			step = FSTEP,
			bigStep = 1,
			get = function()
				return TextStyle(key).durationTextOffsetX or -4
			end,
			set = function(_, v)
				TextStyle(key).durationTextOffsetX = v
				RefreshSkin()
			end,
		},
	}
end
