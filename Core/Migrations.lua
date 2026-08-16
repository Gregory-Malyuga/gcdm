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

	GCDM.MigratePerViewerText(p)
	GCDM.MigrateKeybindTextDefaults(p)

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

	GCDM.MigrateLayoutOneshots(p)
	GCDM.MigrateExpresswayFont(p, self)
	GCDM.MigrateViewerPos(p)
end
