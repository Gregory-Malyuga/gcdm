local ADDON_NAME, ns = ...

function ns.AppendIconKeybindTextArgs(ctx, args, viewerKey, orderBase)
	orderBase = orderBase or 100
	local db = ctx.db
	local L = ctx.L
	local FSTEP = ctx.FSTEP
	local TextStyle = ctx.TextStyle
	local getStyleColor = ctx.getStyleColor
	local setStyleColor = ctx.setStyleColor
	local RefreshSkin = ctx.RefreshSkin
	local ANCHOR_VALUES = ctx.ANCHOR_VALUES

	args.keybindHeader = { type = "header", name = L["KEYBIND_TEXT"], order = orderBase + 30 }
	args.keybindTextEnabled = {
		type = "toggle",
		name = L["KEYBIND_TEXT_ENABLED"],
		desc = L["KEYBIND_TEXT_ENABLED_DESC"],
		order = orderBase + 31,
		get = function()
			return db().keybindTextEnabled ~= false
		end,
		set = function(_, v)
			db().keybindTextEnabled = v and true or false
			RefreshSkin()
		end,
	}
	args.pressOverlayEnabled = {
		type = "toggle",
		name = L["PRESS_OVERLAY_ENABLED"],
		desc = L["PRESS_OVERLAY_ENABLED_DESC"],
		order = orderBase + 32,
		get = function()
			return db().pressOverlayEnabled ~= false
		end,
		set = function(_, v)
			db().pressOverlayEnabled = v and true or false
			RefreshSkin()
		end,
	}
	args.keybindFontSize = {
		type = "range",
		name = L["KEYBIND_FONT_SIZE"],
		order = orderBase + 33,
		min = 8,
		max = 28,
		step = 1,
		get = function()
			return TextStyle(viewerKey).keybindFontSize or 11
		end,
		set = function(_, v)
			TextStyle(viewerKey).keybindFontSize = v
			RefreshSkin()
		end,
	}
	args.keybindTextColor = {
		type = "color",
		name = L["KEYBIND_TEXT_COLOR"],
		order = orderBase + 34,
		hasAlpha = true,
		get = function()
			return getStyleColor(TextStyle(viewerKey), "keybindTextColor", { r = 1, g = 1, b = 1, a = 1 })
		end,
		set = function(_, r, g, b, a)
			setStyleColor(TextStyle(viewerKey), "keybindTextColor", r, g, b, a)
			RefreshSkin()
		end,
	}
	args.keybindTextPoint = {
		type = "select",
		name = L["KEYBIND_TEXT_POINT"],
		order = orderBase + 35,
		values = ANCHOR_VALUES,
		get = function()
			return TextStyle(viewerKey).keybindTextPoint or "TOPLEFT"
		end,
		set = function(_, v)
			TextStyle(viewerKey).keybindTextPoint = v
			RefreshSkin()
		end,
	}
	args.keybindTextOffsetX = {
		type = "range",
		name = L["KEYBIND_TEXT_OFFSET_X"],
		order = orderBase + 36,
		min = -40,
		max = 40,
		step = FSTEP,
		bigStep = 1,
		get = function()
			return TextStyle(viewerKey).keybindTextOffsetX or 2
		end,
		set = function(_, v)
			TextStyle(viewerKey).keybindTextOffsetX = v
			RefreshSkin()
		end,
	}
	args.keybindTextOffsetY = {
		type = "range",
		name = L["KEYBIND_TEXT_OFFSET_Y"],
		order = orderBase + 37,
		min = -40,
		max = 40,
		step = FSTEP,
		bigStep = 1,
		get = function()
			return TextStyle(viewerKey).keybindTextOffsetY or -1
		end,
		set = function(_, v)
			TextStyle(viewerKey).keybindTextOffsetY = v
			RefreshSkin()
		end,
	}
end
