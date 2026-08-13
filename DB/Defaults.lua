local ADDON_NAME, ns = ...

ns.defaults = {
	profile = {
		enabled = true,

		sizeEssential = { w = 46, h = 40 },
		sizeEssentialRow2 = { w = 36, h = 32 },
		sizeUtility = { w = 46, h = 40 },
		sizeBuff = { w = 46, h = 40 },
		spacing = 0,
		maxIconsPerRow = 7,
		-- false = fractional sizes/positions as entered; true = snap to physical pixels
		pixelSnap = false,

		iconZoom = 0.08,
		borderSize = 1,
		borderOffsetX = 0,
		borderOffsetY = 0,
		borderColor = { r = 0, g = 0, b = 0, a = 1 },
		borderTexture = "Solid",
		swipeColor = { r = 0, g = 0, b = 0, a = 0.6 },
		debugSkin = false,

		textFont = "Expressway",
		textOutline = "OUTLINE",
		cooldownFontSize = 14,
		cooldownTextColor = { r = 1, g = 1, b = 1, a = 1 },
		cooldownTextPoint = "CENTER",
		cooldownTextOffsetX = 0,
		cooldownTextOffsetY = 0,
		stackFontSize = 12,
		stackTextColor = { r = 1, g = 1, b = 1, a = 1 },
		stackTextPoint = "BOTTOMRIGHT",
		stackTextOffsetX = -1,
		stackTextOffsetY = 1,

		fadeOutOfCombat = false,
		fadeAlpha = 0.35,

		glowEnabled = true,
		glowAutoFit = true,
		glowScale = 1,
		glowOffsetX = 0,
		glowOffsetY = 0,
		glowDisabledCooldowns = {}, -- [cooldownID] = true
		glowDisabledSpells = {}, -- [spellID] = true (optional manual)
		hidePandemicIndicator = true,

		-- Screen positions (UIParent). When enabled, overrides Edit Mode placement outside Edit Mode.
		viewerPos = {
			essential = { enabled = false, point = "CENTER", x = 0, y = -120 },
			utility = { enabled = false, point = "CENTER", x = 0, y = -180 },
			buff = { enabled = false, point = "CENTER", x = 0, y = 120 },
			buffBar = { enabled = false, point = "CENTER", x = 0, y = 80 },
		},

		buffBarEnabled = true,
		buffBarStyle = "solid", -- blizzard | solid (SharedMedia textures)
		buffBarTexture = "Solid",
		buffBarBackgroundTexture = "Solid",
		buffBarWidth = 0, -- 0 = match Essential row 1 width
		buffBarHeight = 16,
		buffBarSpacing = 0,
		buffBarIconGap = 0,
		buffBarShowIcon = true,
		buffBarShowName = true,
		buffBarShowDuration = true,
		buffBarColor = { r = 0.4, g = 0.6, b = 0.9, a = 1 },
		buffBarBackgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 },
	},
}
