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
		-- Smooth StatusBar fill (Power / Aura / Buff bars). Off by default.
		barSmoothProgress = false,

		-- Player power (energy/rage/runic/…). Separate from thin aura strips.
		powerBarEnabled = true,
		powerBarShowSecondary = true,
		powerBarShowText = true,
		powerBarWidth = 0, -- 0 = Essential row width
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

		-- Custom aura strips (12.1 AuraContainer slots when available; legacy fallback).
		-- Duration: auraBarSpellIDs = "6673,32216"
		-- Applications (e.g. Whirlwind): auraAppSpellIDs = "85739:4" (spell:maxStacks + ticks)
		-- Sounds: apply / each stack / remove only — NOT "only at N stacks" (impossible in combat).
		auraBarsEnabled = false,
		auraBarSpellIDs = "",
		auraAppSpellIDs = "",
		auraBarWidth = 0,
		auraBarHeight = 6,
		auraBarSpacing = 1,
		auraBarGap = 1,
		auraBarBorderSize = 0,
		auraBarFontSize = 10,
		auraBarFont = "Expressway",
		auraBarTextOutline = "OUTLINE",
		auraBarTexture = "Solid",
		auraBarBackgroundTexture = "Solid",
		auraBarColor = { r = 0.4, g = 0.6, b = 0.9, a = 1 },
		auraAppBarColor = { r = 0.2, g = 0.85, b = 0.75, a = 1 },
		auraBarBackgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
		auraBarTextColor = { r = 1, g = 1, b = 1, a = 1 },
		auraBarShowName = false,
		auraBarShowDuration = true,
		auraBarShowTicks = true,
		auraSoundOnApply = false,
		auraSoundOnStack = false,
		auraSoundOnRemove = false,
		auraSoundKitID = 0,
		-- Independent sound rules tab (AddAuraSound).
		auraSoundEnabled = true,
		auraSoundDefaultKitID = 878,
		auraSoundRules = {},
		auraSoundDraft = {
			spellSelect = "custom",
			spellID = "",
			unit = "player",
			event = "apply",
			soundKey = "kit:878",
		},
	},
}
