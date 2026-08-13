-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- See LICENSE in the addon root. Redistribution / rebranding prohibited.
local ADDON_NAME, ns = ...

local AceAddon = LibStub("AceAddon-3.0")
local GCDM = AceAddon:NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

ns.GCDM = GCDM
_G.GCDM = GCDM

GCDM.ADDON_NAME = ADDON_NAME
GCDM.VERSION = "0.1.0"
GCDM.LICENSE = "Proprietary — All Rights Reserved"

function GCDM:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("GCDMDB", ns.defaults, true)
	if self.Skin and self.Skin.InitSharedMedia then
		self.Skin.InitSharedMedia()
	end
	if self.RunMigrations then
		self:RunMigrations()
	end
	self:RegisterChatCommand("gcdm", "SlashCommand")
	self:RegisterChatCommand("gcdmconfig", "SlashCommand")
	if ns.SetupOptions then
		ns.SetupOptions(self)
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
	if cmd == "press" or cmd == "presslog" then
		local db = self:GetDB()
		if db then
			if cmd == "presslog" or input:find("toggle", 1, true) then
				db.pressOverlayDebug = not (db.pressOverlayDebug == true)
				self:Print("pressOverlayDebug = " .. tostring(db.pressOverlayDebug == true))
			else
				db.pressOverlayDebug = true
			end
		end
		if self.Skin and self.Skin.DumpPressOverlayDebug then
			self.Skin.DumpPressOverlayDebug()
		end
		self:Refresh(self.CONST.REFRESH.STYLE)
		return
	end
	if cmd == "debug" then
		self:ToggleDebugSkin()
		return
	end
	if cmd == "dump" then
		self:DumpSkinDebug()
		return
	end
	if cmd == "test" or cmd == "tests" then
		local filter = input:match("^%S+%s+(.+)$")
		local ok, err = pcall(function()
			self:RunBehaviorTests(filter)
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
