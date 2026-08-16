local ADDON_NAME, ns = ...
function ns.MakeIconTextArgs(ctx, viewerKey, orderBase, withKeybind)
	orderBase = orderBase or 100
	local addon, L = ctx.addon, ctx.L
	local TextStyle, getStyleColor, setStyleColor = ctx.TextStyle, ctx.getStyleColor, ctx.setStyleColor
	local RefreshSkin, ANCHOR_VALUES, OUTLINE_VALUES = ctx.RefreshSkin, ctx.ANCHOR_VALUES, ctx.OUTLINE_VALUES
	local args = {
		textHeader = { type = "header", name = L["TEXT"], order = orderBase },
		textFont = {
			type = "select",
			name = L["TEXT_FONT"],
			order = orderBase + 1,
			values = function()
				return addon.Skin.ListMedia("font")
			end,
			get = function()
				local st = TextStyle(viewerKey)
				return addon.Skin.ResolveFontName(st.textFont or addon.Skin.DefaultFontName())
			end,
			set = function(_, v)
				TextStyle(viewerKey).textFont = v
				RefreshSkin()
			end,
		},
		textOutline = {
			type = "select",
			name = L["TEXT_OUTLINE"],
			order = orderBase + 2,
			values = OUTLINE_VALUES,
			get = function()
				local v = TextStyle(viewerKey).textOutline or "OUTLINE"
				if v == "" then
					return "NONE"
				end
				return v
			end,
			set = function(_, v)
				TextStyle(viewerKey).textOutline = (v == "NONE") and "" or v
				RefreshSkin()
			end,
		},
		cooldownHeader = { type = "header", name = L["COOLDOWN_TEXT"], order = orderBase + 10 },
		cooldownFontSize = {
			type = "range",
			name = L["COOLDOWN_FONT_SIZE"],
			order = orderBase + 11,
			min = 8,
			max = 32,
			step = 1,
			get = function()
				return TextStyle(viewerKey).cooldownFontSize or 14
			end,
			set = function(_, v)
				TextStyle(viewerKey).cooldownFontSize = v
				RefreshSkin()
			end,
		},
		cooldownTextColor = {
			type = "color",
			name = L["COOLDOWN_TEXT_COLOR"],
			order = orderBase + 12,
			hasAlpha = true,
			get = function()
				return getStyleColor(TextStyle(viewerKey), "cooldownTextColor", { r = 1, g = 1, b = 1, a = 1 })
			end,
			set = function(_, r, g, b, a)
				setStyleColor(TextStyle(viewerKey), "cooldownTextColor", r, g, b, a)
				RefreshSkin()
			end,
		},
		cooldownTextPoint = {
			type = "select",
			name = L["COOLDOWN_TEXT_POINT"],
			order = orderBase + 13,
			values = ANCHOR_VALUES,
			get = function()
				return TextStyle(viewerKey).cooldownTextPoint or "CENTER"
			end,
			set = function(_, v)
				TextStyle(viewerKey).cooldownTextPoint = v
				RefreshSkin()
			end,
		},
		cooldownTextOffsetX = {
			type = "range",
			name = L["COOLDOWN_TEXT_OFFSET_X"],
			order = orderBase + 14,
			min = -40,
			max = 40,
			step = ctx.FSTEP,
			bigStep = 1,
			get = function()
				return TextStyle(viewerKey).cooldownTextOffsetX or 0
			end,
			set = function(_, v)
				TextStyle(viewerKey).cooldownTextOffsetX = v
				RefreshSkin()
			end,
		},
		cooldownTextOffsetY = {
			type = "range",
			name = L["COOLDOWN_TEXT_OFFSET_Y"],
			order = orderBase + 15,
			min = -40,
			max = 40,
			step = ctx.FSTEP,
			bigStep = 1,
			get = function()
				return TextStyle(viewerKey).cooldownTextOffsetY or 0
			end,
			set = function(_, v)
				TextStyle(viewerKey).cooldownTextOffsetY = v
				RefreshSkin()
			end,
		},
		stackHeader = { type = "header", name = L["STACK_TEXT"], order = orderBase + 20 },
		stackFontSize = {
			type = "range",
			name = L["STACK_FONT_SIZE"],
			order = orderBase + 21,
			min = 8,
			max = 32,
			step = 1,
			get = function()
				return TextStyle(viewerKey).stackFontSize or 12
			end,
			set = function(_, v)
				TextStyle(viewerKey).stackFontSize = v
				RefreshSkin()
			end,
		},
		stackTextColor = {
			type = "color",
			name = L["STACK_TEXT_COLOR"],
			order = orderBase + 22,
			hasAlpha = true,
			get = function()
				return getStyleColor(TextStyle(viewerKey), "stackTextColor", { r = 1, g = 1, b = 1, a = 1 })
			end,
			set = function(_, r, g, b, a)
				setStyleColor(TextStyle(viewerKey), "stackTextColor", r, g, b, a)
				RefreshSkin()
			end,
		},
		stackTextPoint = {
			type = "select",
			name = L["STACK_TEXT_POINT"],
			order = orderBase + 23,
			values = ANCHOR_VALUES,
			get = function()
				return TextStyle(viewerKey).stackTextPoint or "BOTTOMRIGHT"
			end,
			set = function(_, v)
				TextStyle(viewerKey).stackTextPoint = v
				RefreshSkin()
			end,
		},
		stackTextOffsetX = {
			type = "range",
			name = L["STACK_TEXT_OFFSET_X"],
			order = orderBase + 24,
			min = -40,
			max = 40,
			step = ctx.FSTEP,
			bigStep = 1,
			get = function()
				return TextStyle(viewerKey).stackTextOffsetX or 0
			end,
			set = function(_, v)
				TextStyle(viewerKey).stackTextOffsetX = v
				RefreshSkin()
			end,
		},
		stackTextOffsetY = {
			type = "range",
			name = L["STACK_TEXT_OFFSET_Y"],
			order = orderBase + 25,
			min = -40,
			max = 40,
			step = ctx.FSTEP,
			bigStep = 1,
			get = function()
				return TextStyle(viewerKey).stackTextOffsetY or 0
			end,
			set = function(_, v)
				TextStyle(viewerKey).stackTextOffsetY = v
				RefreshSkin()
			end,
		},
	}
	if withKeybind then
		ns.AppendIconKeybindTextArgs(ctx, args, viewerKey, orderBase)
	end
	return args
end

