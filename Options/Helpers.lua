local ADDON_NAME, ns = ...
local L = ns.L

ns.FSTEP = 0.1

function ns.RefreshSkin(addon)
	addon:Refresh(addon.CONST.REFRESH.STYLE)
end

function ns.RefreshLayout(addon)
	addon:Refresh(addon.CONST.REFRESH.LAYOUT)
end

function ns.RefreshBuffBars(addon)
	addon:Refresh(addon.CONST.REFRESH.LAYOUT)
	addon:Refresh(addon.CONST.REFRESH.STYLE)
end

function ns.RefreshGlow(addon)
	addon:Refresh(addon.CONST.REFRESH.GLOW)
end

--- Shared closures for Options builders (set once in SetupOptions).
function ns.MakeOptionsCtx(addon)
	local db = function()
		return addon.db.profile
	end
	local ctx = {
		addon = addon,
		db = db,
		L = L,
		FSTEP = ns.FSTEP,
		ANCHOR_VALUES = {
			CENTER = L["ANCHOR_CENTER"],
			TOP = L["ANCHOR_TOP"],
			BOTTOM = L["ANCHOR_BOTTOM"],
			LEFT = L["ANCHOR_LEFT"],
			RIGHT = L["ANCHOR_RIGHT"],
			TOPLEFT = L["ANCHOR_TOPLEFT"],
			TOPRIGHT = L["ANCHOR_TOPRIGHT"],
			BOTTOMLEFT = L["ANCHOR_BOTTOMLEFT"],
			BOTTOMRIGHT = L["ANCHOR_BOTTOMRIGHT"],
		},
		OUTLINE_VALUES = {
			NONE = L["TEXT_OUTLINE_NONE"] or "None",
			OUTLINE = L["TEXT_OUTLINE_OUTLINE"] or "Outline",
			THICKOUTLINE = L["TEXT_OUTLINE_THICK"] or "Thick",
			MONOCHROME = L["TEXT_OUTLINE_MONOCHROME"] or "Monochrome",
		},
	}

	function ctx.TextStyle(viewerKey)
		local root = db()
		root.textByViewer = root.textByViewer or {}
		local st = root.textByViewer[viewerKey]
		if type(st) ~= "table" then
			st = {}
			root.textByViewer[viewerKey] = st
		end
		return st
	end

	function ctx.getColor(key, fallback)
		local c = db()[key] or fallback
		return c.r or 1, c.g or 1, c.b or 1, c.a or 1
	end

	function ctx.setColor(key, r, g, b, a)
		db()[key] = { r = r, g = g, b = b, a = a }
	end

	function ctx.getStyleColor(style, key, fallback)
		local c = style[key] or fallback
		return c.r or 1, c.g or 1, c.b or 1, c.a or 1
	end

	function ctx.setStyleColor(style, key, r, g, b, a)
		style[key] = { r = r, g = g, b = b, a = a }
	end

	function ctx.RefreshSkin()
		ns.RefreshSkin(addon)
	end

	function ctx.RefreshLayout()
		ns.RefreshLayout(addon)
	end

	function ctx.RefreshBuffBars()
		ns.RefreshBuffBars(addon)
	end

	function ctx.RefreshGlow()
		ns.RefreshGlow(addon)
	end

	ns.OptionsCtx = ctx
	return ctx
end
