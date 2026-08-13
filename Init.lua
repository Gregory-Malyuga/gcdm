local ADDON_NAME, ns = ...

local AceAddon = LibStub("AceAddon-3.0")
local GCDM = AceAddon:NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

ns.GCDM = GCDM
_G.GCDM = GCDM

GCDM.ADDON_NAME = ADDON_NAME
GCDM.VERSION = "0.1.0"

function GCDM:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("GCDMDB", ns.defaults, true)
	-- Ensure nested size tables exist for older profiles.
	local p = self.db.profile
	p.sizeEssentialRow2 = p.sizeEssentialRow2 or { w = 36, h = 32 }
	if not p.maxIconsPerRow then
		p.maxIconsPerRow = 7
	end
	if self.db.profile.iconZoom and self.db.profile.iconZoom < 0.05 then
		self.db.profile.iconZoom = 0.08
	end
	-- Restore pandemic hide after a brief period where default was flipped to false.
	if not self.db.profile._gcdmPandemicHideRestored then
		self.db.profile.hidePandemicIndicator = true
		self.db.profile._gcdmPandemicHideRestored = true
	elseif self.db.profile.hidePandemicIndicator == nil then
		self.db.profile.hidePandemicIndicator = true
	end
	self.db.profile.glowDisabledCooldowns = self.db.profile.glowDisabledCooldowns or {}
	self.db.profile.glowDisabledSpells = self.db.profile.glowDisabledSpells or {}
	-- Proc glow was off by default; turn on once for existing profiles.
	if not self.db.profile._gcdmGlowEnabledDefault then
		self.db.profile.glowEnabled = true
		self.db.profile._gcdmGlowEnabledDefault = true
	elseif self.db.profile.glowEnabled == nil then
		self.db.profile.glowEnabled = true
	end
	if self.db.profile.powerBarEnabled == nil then
		self.db.profile.powerBarEnabled = true
	elseif self.db.profile.powerBarEnabled == false then
		-- Keep explicit false; do not force on.
	end
	-- Ensure height is never zero/invalid from old profiles.
	if type(self.db.profile.powerBarHeight) ~= "number" or self.db.profile.powerBarHeight < 1 then
		self.db.profile.powerBarHeight = 10
	end
	if self.db.profile.powerBarShowText == nil then
		self.db.profile.powerBarShowText = true
	end
	-- Drop ColorCurve / ticks UI; force simple class|solid (+ no ticks).
	if not self.db.profile._gcdmPowerBarSimpleColor then
		if self.db.profile.powerBarColorMode == "curve" then
			self.db.profile.powerBarColorMode = "class"
		end
		self.db.profile.powerBarTickMode = "none"
		local profiles = self.db.profile.powerBarProfiles
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
		self.db.profile._gcdmPowerBarSimpleColor = true
	end
	if not self.db.profile.glowScale then
		self.db.profile.glowScale = 1
	end
	if self.db.profile.glowAutoFit == nil then
		self.db.profile.glowAutoFit = true
	end
	if self.db.profile.glowOffsetX == nil and self.db.profile.glowXOffset ~= nil then
		self.db.profile.glowOffsetX = self.db.profile.glowXOffset
	end
	if self.db.profile.glowOffsetY == nil and self.db.profile.glowYOffset ~= nil then
		self.db.profile.glowOffsetY = self.db.profile.glowYOffset
	end
	-- AceDB does not persist mutations of nested default tables; own copies required.
	local function MaterializeColor(key)
		local c = p[key]
		if type(c) == "table" then
			p[key] = { r = c.r or 1, g = c.g or 1, b = c.b or 1, a = c.a or 1 }
		end
	end
	-- Migrate legacy global text → per-viewer textByViewer (once).
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
		if p.auraBarFont == nil then
			p.auraBarFont = p.textFont or "Expressway"
		end
		if p.auraBarTextOutline == nil then
			p.auraBarTextOutline = p.textOutline or "OUTLINE"
		end
		p._gcdmPerViewerText = true
	end
	MaterializeColor("borderColor")
	MaterializeColor("swipeColor")
	MaterializeColor("buffBarColor")
	MaterializeColor("buffBarBackgroundColor")
	MaterializeColor("auraBarColor")
	MaterializeColor("auraAppBarColor")
	MaterializeColor("auraBarBackgroundColor")
	MaterializeColor("auraBarTextColor")
	MaterializeColor("powerBarColor")
	MaterializeColor("powerBarBackgroundColor")
	MaterializeColor("powerBarTextColor")
	MaterializeColor("powerBarSecondaryColor")
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
	if self.db.profile.auraAppSpellIDs == nil then
		self.db.profile.auraAppSpellIDs = ""
	end
	if self.db.profile.auraBarShowTicks == nil then
		self.db.profile.auraBarShowTicks = true
	end
	if self.db.profile.auraBarShowDuration == nil then
		self.db.profile.auraBarShowDuration = true
	end
	if self.db.profile.auraBarFontSize == nil then
		self.db.profile.auraBarFontSize = 10
	end
	if self.db.profile.auraSoundEnabled == nil then
		self.db.profile.auraSoundEnabled = true
	end
	if self.db.profile.auraSoundRules == nil then
		self.db.profile.auraSoundRules = {}
	end
	if type(self.db.profile.auraSoundDraft) ~= "table" then
		self.db.profile.auraSoundDraft = {
			spellSelect = "custom",
			spellID = "",
			unit = "player",
			event = "apply",
			soundKey = "kit:878",
		}
	else
		local d = self.db.profile.auraSoundDraft
		if d.soundKey == nil and d.soundKitID ~= nil then
			local kit = tonumber(d.soundKitID) or 878
			d.soundKey = "kit:" .. kit
		end
		if d.spellSelect == nil then
			d.spellSelect = "custom"
		end
	end
	if self.db.profile.auraSoundDefaultKitID == nil then
		self.db.profile.auraSoundDefaultKitID = 878
	end
	if self.db.profile.powerBarProfiles == nil then
		self.db.profile.powerBarProfiles = {}
	end
	if self.db.profile.powerBarColorMode == nil then
		self.db.profile.powerBarColorMode = "class"
	end
	if self.db.profile.powerBarCurvePointsStr == nil then
		self.db.profile.powerBarCurvePointsStr =
			"0:1,0.85,0.1,1|100:1,0.85,0.1,1|100.01:1,1,1,1|200:1,1,1,1"
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
	self:RegisterChatCommand("gcdm", "SlashCommand")
	self:RegisterChatCommand("gcdmconfig", "SlashCommand")
	if ns.SetupOptions then
		ns.SetupOptions(self)
	end
	if self.Skin and self.Skin.InitSharedMedia then
		self.Skin.InitSharedMedia()
	end
end

function GCDM:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnViewerDataChanged")
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "OnViewerDataChanged")
	self:RegisterEvent("LOADING_SCREEN_DISABLED", "OnLoadingScreenDisabled")
	if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("COOLDOWN_VIEWER_DATA_LOADED") then
		self:RegisterEvent("COOLDOWN_VIEWER_DATA_LOADED", "OnViewerDataChanged")
	end
	if EventUtil and EventUtil.ContinueOnAddOnLoaded then
		EventUtil.ContinueOnAddOnLoaded("Blizzard_CooldownViewer", function()
			if GCDM.ViewerRegistry then
				GCDM.ViewerRegistry:RefreshCache()
			end
			GCDM:Refresh()
			C_Timer.After(0, function()
				if GCDM and GCDM.Refresh then
					GCDM:Refresh(GCDM.CONST.REFRESH.LAYOUT)
				end
			end)
		end)
	end
	self:Refresh()
end

function GCDM:OnViewerDataChanged()
	if self.ViewerRegistry then
		self.ViewerRegistry:RefreshCache()
	end
	self:Refresh()
end

function GCDM:OnLoadingScreenDisabled()
	if self.ViewerRegistry then
		self.ViewerRegistry:RefreshCache()
	end
	-- CDM frames may appear after loading screen; retry like Edit Mode Exit Refresh.
	C_Timer.After(0, function()
		if GCDM and GCDM.Refresh then
			GCDM:Refresh()
		end
	end)
	C_Timer.After(0.25, function()
		if GCDM and GCDM.Refresh then
			GCDM:Refresh(GCDM.CONST.REFRESH.LAYOUT)
		end
	end)
end

function GCDM:GetDB()
	return self.db and self.db.profile
end

function GCDM:OpenOptions()
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	local open = AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames[ADDON_NAME]
	if open and open.frame and open.frame:IsShown() then
		AceConfigDialog:Close(ADDON_NAME)
		return
	end
	AceConfigDialog:Open(ADDON_NAME)
	open = AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames[ADDON_NAME]
	if open and open.SetStatusText then
		open:SetStatusText(ns.L["OPTIONS_DRAG_HINT"] or "Drag the title bar to move")
	end
end

function GCDM:SlashCommand(input)
	input = strtrim(input or "")
	local cmd = input:match("^(%S+)") or ""
	cmd = string.lower(cmd)
	if cmd == "debug" then
		self:ToggleDebugSkin()
		return
	end
	if cmd == "dump" then
		self:DumpSkinDebug()
		return
	end
	if cmd == "test" or cmd == "tests" then
		local ok, err = pcall(function()
			self:RunBehaviorTests()
		end)
		if not ok then
			print("|cff3bb273GCDM|r test ERROR: " .. tostring(err))
		end
		return
	end
	if cmd == "buffbar" or cmd == "bb" or cmd == "bar" or cmd == "log" or cmd == "dumpbar" then
		local ok, err = pcall(function()
			self:DumpBuffBarDebug()
		end)
		if not ok then
			print("|cff3bb273GCDM|r dump ERROR: " .. tostring(err))
			if DEFAULT_CHAT_FRAME then
				DEFAULT_CHAT_FRAME:AddMessage("|cff3bb273GCDM|r dump ERROR: " .. tostring(err))
			end
		end
		return
	end
	self:OpenOptions()
end
