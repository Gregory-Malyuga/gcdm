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
	MaterializeColor("borderColor")
	MaterializeColor("swipeColor")
	MaterializeColor("buffBarColor")
	MaterializeColor("buffBarBackgroundColor")
	MaterializeColor("cooldownTextColor")
	MaterializeColor("stackTextColor")
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
	LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)
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
