local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

-- One-shot SavedVariables migrations. Call once from OnInitialize.
-- Flag names are stable for profile compatibility / export.

local function MaterializeColor(p, key)
	local c = p[key]
	if type(c) == "table" then
		p[key] = { r = c.r or 1, g = c.g or 1, b = c.b or 1, a = c.a or 1 }
	end
end

function GCDM:RunMigrations()
	local p = self.db and self.db.profile
	if not p then
		return
	end

	p.sizeEssentialRow2 = p.sizeEssentialRow2 or { w = 36, h = 32 }
	if not p.maxIconsPerRow then
		p.maxIconsPerRow = 7
	end
	if p.iconZoom and p.iconZoom < 0.05 then
		p.iconZoom = 0.08
	end

	if not p._gcdmPandemicHideRestored then
		p.hidePandemicIndicator = true
		p._gcdmPandemicHideRestored = true
	elseif p.hidePandemicIndicator == nil then
		p.hidePandemicIndicator = true
	end

	p.glowDisabledCooldowns = p.glowDisabledCooldowns or {}
	p.glowDisabledSpells = p.glowDisabledSpells or {}

	if not p._gcdmGlowEnabledDefault then
		p.glowEnabled = true
		p._gcdmGlowEnabledDefault = true
	elseif p.glowEnabled == nil then
		p.glowEnabled = true
	end

	if p.powerBarEnabled == nil then
		p.powerBarEnabled = true
	end
	if type(p.powerBarHeight) ~= "number" or p.powerBarHeight < 1 then
		p.powerBarHeight = 10
	end
	if p.powerBarShowText == nil then
		p.powerBarShowText = true
	end

	if not p._gcdmPowerBarSimpleColor then
		if p.powerBarColorMode == "curve" then
			p.powerBarColorMode = "class"
		end
		p.powerBarTickMode = "none"
		local profiles = p.powerBarProfiles
		if type(profiles) == "table" then
			for _, cfg in pairs(profiles) do
				if type(cfg) == "table" then
					if cfg.colorMode == "curve" then
						cfg.colorMode = "class"
					end
					cfg.tickMode = "none"
				end
			end
		end
		p._gcdmPowerBarSimpleColor = true
	end

	if not p.glowScale then
		p.glowScale = 1
	end
	if p.glowAutoFit == nil then
		p.glowAutoFit = true
	end
	if p.glowOffsetX == nil and p.glowXOffset ~= nil then
		p.glowOffsetX = p.glowXOffset
	end
	if p.glowOffsetY == nil and p.glowYOffset ~= nil then
		p.glowOffsetY = p.glowYOffset
	end

	-- Legacy global text → per-viewer textByViewer (once).
	if not p._gcdmPerViewerText then
		p.textByViewer = p.textByViewer or {}
		local function copyColor(c, fb)
			fb = fb or { r = 1, g = 1, b = 1, a = 1 }
			if type(c) ~= "table" then
				return { r = fb.r, g = fb.g, b = fb.b, a = fb.a }
			end
			return { r = c.r or fb.r, g = c.g or fb.g, b = c.b or fb.b, a = c.a or fb.a }
		end
		local function ensureIcon(key)
			local st = p.textByViewer[key]
			if type(st) ~= "table" then
				st = {}
				p.textByViewer[key] = st
			end
			st.textFont = st.textFont or p.textFont or "Expressway"
			if st.textOutline == nil then
				st.textOutline = p.textOutline or "OUTLINE"
			end
			st.cooldownFontSize = st.cooldownFontSize or p.cooldownFontSize or 14
			st.cooldownTextColor = copyColor(st.cooldownTextColor or p.cooldownTextColor)
			st.cooldownTextPoint = st.cooldownTextPoint or p.cooldownTextPoint or "CENTER"
			st.cooldownTextOffsetX = st.cooldownTextOffsetX or p.cooldownTextOffsetX or 0
			st.cooldownTextOffsetY = st.cooldownTextOffsetY or p.cooldownTextOffsetY or 0
			st.stackFontSize = st.stackFontSize or p.stackFontSize or 12
			st.stackTextColor = copyColor(st.stackTextColor or p.stackTextColor)
			st.stackTextPoint = st.stackTextPoint or p.stackTextPoint or "BOTTOMRIGHT"
			st.stackTextOffsetX = st.stackTextOffsetX or p.stackTextOffsetX or -1
			st.stackTextOffsetY = st.stackTextOffsetY or p.stackTextOffsetY or 1
		end
		ensureIcon("EssentialCooldownViewer")
		ensureIcon("UtilityCooldownViewer")
		ensureIcon("BuffIconCooldownViewer")
		do
			local st = p.textByViewer.BuffBarCooldownViewer
			if type(st) ~= "table" then
				st = {}
				p.textByViewer.BuffBarCooldownViewer = st
			end
			st.textFont = st.textFont or p.textFont or "Expressway"
			if st.textOutline == nil then
				st.textOutline = p.textOutline or "OUTLINE"
			end
			st.nameFontSize = st.nameFontSize or p.stackFontSize or 12
			st.durationFontSize = st.durationFontSize or p.cooldownFontSize or 14
			st.nameTextColor = copyColor(st.nameTextColor or p.stackTextColor)
			st.durationTextColor = copyColor(st.durationTextColor or p.cooldownTextColor)
			st.nameTextOffsetX = st.nameTextOffsetX or 4
			st.nameTextOffsetY = st.nameTextOffsetY or 0
			st.durationTextOffsetX = st.durationTextOffsetX or -4
			st.durationTextOffsetY = st.durationTextOffsetY or 0
		end
		if p.powerBarFont == nil then
			p.powerBarFont = p.textFont or "Expressway"
		end
		if p.powerBarTextOutline == nil then
			p.powerBarTextOutline = p.textOutline or "OUTLINE"
		end
		p._gcdmPerViewerText = true
	end

	if not p._gcdmKeybindTextDefaults then
		p.textByViewer = p.textByViewer or {}
		local function ensureKeybind(key)
			local st = p.textByViewer[key]
			if type(st) ~= "table" then
				st = {}
				p.textByViewer[key] = st
			end
			st.keybindFontSize = st.keybindFontSize or 11
			if type(st.keybindTextColor) ~= "table" then
				st.keybindTextColor = { r = 1, g = 1, b = 1, a = 1 }
			else
				st.keybindTextColor = {
					r = st.keybindTextColor.r or 1,
					g = st.keybindTextColor.g or 1,
					b = st.keybindTextColor.b or 1,
					a = st.keybindTextColor.a or 1,
				}
			end
			st.keybindTextPoint = st.keybindTextPoint or "TOPLEFT"
			st.keybindTextOffsetX = st.keybindTextOffsetX or 2
			st.keybindTextOffsetY = st.keybindTextOffsetY or -1
		end
		ensureKeybind("EssentialCooldownViewer")
		ensureKeybind("UtilityCooldownViewer")
		if p.keybindTextEnabled == nil then
			p.keybindTextEnabled = true
		end
		if p.pressOverlayEnabled == nil then
			p.pressOverlayEnabled = true
		end
		p._gcdmKeybindTextDefaults = true
	end

	-- One-shot: kill temporary press debug spam (do not force every login).
	if not p._gcdmPressOverlayDebugOff then
		p.pressOverlayDebug = false
		p._gcdmPressOverlayDebugOff = true
	end

	MaterializeColor(p, "borderColor")
	MaterializeColor(p, "swipeColor")
	MaterializeColor(p, "buffBarColor")
	MaterializeColor(p, "buffBarBackgroundColor")
	MaterializeColor(p, "powerBarColor")
	MaterializeColor(p, "powerBarBackgroundColor")
	MaterializeColor(p, "powerBarTextColor")
	MaterializeColor(p, "powerBarSecondaryColor")

	do
		local tv = p.textByViewer
		if type(tv) == "table" then
			for _, st in pairs(tv) do
				if type(st) == "table" then
					for _, ck in ipairs({
						"cooldownTextColor",
						"stackTextColor",
						"nameTextColor",
						"durationTextColor",
						"keybindTextColor",
					}) do
						local c = st[ck]
						if type(c) == "table" then
							st[ck] = { r = c.r or 1, g = c.g or 1, b = c.b or 1, a = c.a or 1 }
						end
					end
				end
			end
		end
	end

	if p.auraSoundEnabled == nil then
		p.auraSoundEnabled = true
	end
	if p.auraSoundRules == nil then
		p.auraSoundRules = {}
	end
	if type(p.auraSoundDraft) ~= "table" then
		p.auraSoundDraft = {
			spellSelect = "custom",
			spellID = "",
			unit = "player",
			event = "apply",
			soundKey = "kit:878",
		}
	else
		local d = p.auraSoundDraft
		if d.soundKey == nil and d.soundKitID ~= nil then
			local kit = tonumber(d.soundKitID) or 878
			d.soundKey = "kit:" .. kit
		end
		if d.spellSelect == nil then
			d.spellSelect = "custom"
		end
	end
	if p.auraSoundDefaultKitID == nil then
		p.auraSoundDefaultKitID = 878
	end
	if p.powerBarProfiles == nil then
		p.powerBarProfiles = {}
	end
	if p.powerBarColorMode == nil then
		p.powerBarColorMode = "class"
	end
	if p.powerBarCurvePointsStr == nil then
		p.powerBarCurvePointsStr = "0:1,0.85,0.1,1|100:1,0.85,0.1,1|100.01:1,1,1,1|200:1,1,1,1"
	end

	-- Layout oneshots (formerly ApplyLayout side-effects).
	if p.spacingTightDefault == nil then
		p.spacingTightDefault = true
		if p.spacing == nil or p.spacing == 1 then
			p.spacing = 0
		end
	end
	if p.buffIconSizeSynced == nil then
		p.buffIconSizeSynced = true
		local sb = p.sizeBuff
		if sb and sb.w == 40 and sb.h == 36 then
			sb.w, sb.h = 46, 40
		end
	end

	-- BuffBar oneshots (formerly Apply side-effects).
	if p.buffBarSolidStyleV2 == nil then
		p.buffBarSolidStyleV2 = true
		p.buffBarStyle = "solid"
		if not p.buffBarTexture then
			p.buffBarTexture = "Solid"
		end
	end
	if p.buffBarTightDefault == nil then
		p.buffBarTightDefault = true
		if (p.buffBarStyle or "blizzard") == "blizzard" then
			p.buffBarStyle = "solid"
		end
		if (p.buffBarHeight or 20) >= 20 then
			p.buffBarHeight = 16
		end
		if (p.buffBarSpacing or 0) >= 2 then
			p.buffBarSpacing = 0
		end
		if (p.buffBarIconGap or 0) >= 1 then
			p.buffBarIconGap = 0
		end
		local sb = p.sizeBuff
		if sb and sb.w == 40 and sb.h == 36 then
			sb.w, sb.h = 46, 40
		end
	end

	-- Expressway default font (formerly InitSharedMedia side-effect).
	if not p.expresswayDefaultApplied then
		p.expresswayDefaultApplied = true
		local Skin = self.Skin
		local preferred = Skin and Skin.DefaultFontName and Skin.DefaultFontName() or "Expressway"
		if preferred and preferred ~= "Friz Quadrata TT" then
			p.textByViewer = p.textByViewer or {}
			for _, key in ipairs({
				"EssentialCooldownViewer",
				"UtilityCooldownViewer",
				"BuffIconCooldownViewer",
				"BuffBarCooldownViewer",
			}) do
				local st = p.textByViewer[key]
				if type(st) == "table" and (not st.textFont or st.textFont == "Friz Quadrata TT") then
					st.textFont = preferred
				end
			end
			if not p.powerBarFont or p.powerBarFont == "Friz Quadrata TT" then
				p.powerBarFont = preferred
			end
		end
	end

	do
		local defaultsPos = (ns.defaults.profile.viewerPos) or {}
		p.viewerPos = p.viewerPos or {}
		local keys = { "essential", "utility", "buff", "buffBar" }
		for i = 1, #keys do
			local key = keys[i]
			local src = p.viewerPos[key] or defaultsPos[key] or {}
			p.viewerPos[key] = {
				enabled = src.enabled and true or false,
				point = src.point or "CENTER",
				x = src.x or 0,
				y = src.y or 0,
			}
		end
	end
end
