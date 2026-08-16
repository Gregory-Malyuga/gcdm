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
		-- Log Edit Mode release + allow /gcdm editdump (also on when debugSkin).
		debugEditMode = false,
		-- [refreshCallbackID] = true stops that module; used to bisect taint.
		disabledModules = {},

		-- Per-viewer text (Essential / Utility / Buff icons / Buff bars). No global Text tab.
		textByViewer = {
			EssentialCooldownViewer = {
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
				keybindFontSize = 11,
				keybindTextColor = { r = 1, g = 1, b = 1, a = 1 },
				keybindTextPoint = "TOPLEFT",
				keybindTextOffsetX = 2,
				keybindTextOffsetY = -1,
			},
			UtilityCooldownViewer = {
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
				keybindFontSize = 11,
				keybindTextColor = { r = 1, g = 1, b = 1, a = 1 },
				keybindTextPoint = "TOPLEFT",
				keybindTextOffsetX = 2,
				keybindTextOffsetY = -1,
			},
			BuffIconCooldownViewer = {
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
			},
			BuffBarCooldownViewer = {
				textFont = "Expressway",
				textOutline = "OUTLINE",
				nameFontSize = 12,
				durationFontSize = 14,
				nameTextColor = { r = 1, g = 1, b = 1, a = 1 },
				durationTextColor = { r = 1, g = 1, b = 1, a = 1 },
				nameTextOffsetX = 4,
				nameTextOffsetY = 0,
				durationTextOffsetX = -4,
				durationTextOffsetY = 0,
			},
		},

		fadeOutOfCombat = false,
		fadeAlpha = 0.35,

		-- Essential/Utility: action-bar keybind label + press feedback.
		keybindTextEnabled = true,
		pressOverlayEnabled = true,
		pressOverlayDebug = false,

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
			powerBar = { enabled = false, point = "CENTER", x = 0, y = -100 },
		},

		buffBarEnabled = true,
		buffBarStyle = "solid", -- blizzard | solid (SharedMedia textures)
		buffBarTexture = "Solid",
		buffBarBackgroundTexture = "Solid",
		-- true = width/position follow Essential (+ PowerBar nudge). false = own width + viewerPos.
		buffBarFollowEssential = true,
		buffBarWidth = 200, -- used when not following Essential (min 200)
		buffBarHeight = 16,
		buffBarSpacing = 0,
		buffBarIconGap = 0,
		buffBarShowIcon = true,
		buffBarShowName = true,
		buffBarShowDuration = true,
		buffBarColor = { r = 0.4, g = 0.6, b = 0.9, a = 1 },
		buffBarBackgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 },
		-- Smooth StatusBar fill (Power / Aura / Buff bars). Off by default.
		barSmoothProgress = false,

		-- Player power (energy/rage/runic/…). Separate from thin aura strips.
		powerBarEnabled = true,
		powerBarShowSecondary = true,
		powerBarShowText = true,
		-- true = width/position follow Essential. false = own width + viewerPos.powerBar.
		powerBarFollowEssential = true,
		powerBarWidth = 200, -- used when not following Essential (min 200)
		powerBarHeight = 10,
		powerBarGap = 2,
		powerBarBorderSize = 1,
		powerBarFontSize = 12,
		powerBarFont = "Expressway",
		powerBarTextOutline = "OUTLINE",
		powerBarTexture = "Solid",
		powerBarBackgroundTexture = "Solid",
		powerBarBackgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 },
		powerBarTextColor = { r = 1, g = 1, b = 1, a = 1 },
		-- Global / DEFAULT profile (overridable per class in powerBarProfiles).
		powerBarColorMode = "class", -- class | solid
		powerBarCurveMode = "absolute", -- unused in UI; kept for old profiles
		-- value:r,g,b,a | …  (legacy ColorCurve; UI removed)
		powerBarCurvePointsStr = "0:1,0.85,0.1,1|100:1,0.85,0.1,1|100.01:1,1,1,1|200:1,1,1,1",
		powerBarColor = { r = 0.55, g = 0.1, b = 0.1, a = 1 },
		powerBarTickMode = "none", -- none | equal | values (UI removed; default none)
		powerBarTickCount = 4,
		powerBarTickAtStr = "25,50,75,100",
		powerBarTickMax = 100,
		powerBarTickColor = { r = 1, g = 1, b = 1, a = 0.55 },
		powerBarSecondaryUseCustomColor = false,
		powerBarSecondaryColor = { r = 0.9, g = 0.85, b = 0.2, a = 1 },
		powerBarProfiles = {}, -- [CLASSFILE] = { colorMode, curveMode, curvePointsStr, … }
		powerBarEditClass = "DEFAULT", -- UI only last-selected class in options

		-- Independent sound rules tab (AddAuraSound).
		auraSoundEnabled = true,
		auraSoundDefaultKitID = 878,
		auraSoundRules = {},
		auraSoundDraft = {
			spellSelect = "",
			spellID = "",
			unit = "player",
			event = "apply",
			soundKey = "kit:878",
		},
	},
}
