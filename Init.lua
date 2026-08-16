-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- See LICENSE in the addon root. Redistribution / rebranding prohibited.
local ADDON_NAME, ns = ...

local AceAddon = LibStub("AceAddon-3.0")
local GCDM = AceAddon:NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

ns.GCDM = GCDM
_G.GCDM = GCDM

GCDM.ADDON_NAME = ADDON_NAME
GCDM.VERSION = "0.1.2"
GCDM.BUILD = "20260816-c22"
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
	print("|cff3bb273GCDM|r loaded " .. tostring(self.VERSION) .. " build=" .. tostring(self.BUILD))
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
	local immediate = (self.CONST and self.CONST.LAYOUT_REAPPLY_IMMEDIATE) or 0
	local retry = (self.CONST and self.CONST.LAYOUT_RETRY_AFTER_LOADING) or 0.25
	C_Timer.After(immediate, function()
		if GCDM and GCDM.Refresh then
			GCDM:Refresh()
		end
	end)
	C_Timer.After(retry, function()
		if GCDM and GCDM.Refresh then
			GCDM:Refresh(GCDM.CONST.REFRESH.LAYOUT)
		end
	end)
end

function GCDM:GetDB()
	return self.db and self.db.profile
end

local function ModuleState(addon, id)
	return addon:IsModuleEnabled(id) and "|cff3bb273on|r" or "|cffff5555off|r"
end

--- /gcdm modules · /gcdm module <id> [on|off] · /gcdm safe [on|off]
function GCDM:ModuleCommand(cmd, input)
	local ids = self:GetRefreshModuleIDs()
	if cmd == "safe" then
		local arg = input:match("^%S+%s+(%S+)")
		local on
		if arg == "on" then
			on = true
		elseif arg == "off" then
			on = false
		else
			on = not self:IsSafeMode()
		end
		self:SetSafeMode(on)
		self:Print((on and "safe mode ON — " or "safe mode OFF — ") .. "/reload to drop hooks already installed")
		self:Refresh()
		return
	end

	local name, state = input:match("^%S+%s+(%S+)%s*(%S*)$")
	if not name then
		self:Print("modules (/gcdm module <id> on|off, /gcdm safe):")
		for i = 1, #ids do
			self:Print("  " .. ids[i] .. " = " .. ModuleState(self, ids[i]))
		end
		return
	end

	local match
	for i = 1, #ids do
		if string.lower(ids[i]) == string.lower(name) then
			match = ids[i]
			break
		end
	end
	if not match then
		self:Print("unknown module: " .. name)
		return
	end

	local enabled
	if state == "on" then
		enabled = true
	elseif state == "off" then
		enabled = false
	else
		enabled = not self:IsModuleEnabled(match)
	end
	self:SetModuleEnabled(match, enabled)
	self:Print(match .. " = " .. ModuleState(self, match) .. " (/reload to drop hooks already installed)")
	self:Refresh()
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
	if cmd == "module" or cmd == "modules" or cmd == "safe" then
		self:ModuleCommand(cmd, input)
		return
	end
	if cmd == "debug" then
		self:ToggleDebugSkin()
		return
	end
	if cmd == "editdump" or cmd == "edit" or cmd == "icons" or cmd == "icondump" then
		if type(self.DumpEditModeDebug) ~= "function" then
			print("|cff3bb273GCDM|r icons: DumpEditModeDebug missing. /reload")
			return
		end
		print("|cff3bb273GCDM|r icon dump ver=9 build=" .. tostring(self.BUILD) .. " addon=" .. tostring(self.VERSION))
		local ok, err = pcall(function()
			self:DumpEditModeDebug(false)
		end)
		if not ok then
			print("|cff3bb273GCDM|r icons ERROR: " .. tostring(err))
		end
		return
	end
	if cmd == "editdebug" then
		local db = self:GetDB()
		if db then
			db.debugEditMode = not (db.debugEditMode == true)
			self:Print("debugEditMode = " .. tostring(db.debugEditMode) .. " (auto dump on Edit Mode enter/exit)")
		end
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
