local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local VIEWERS = GCDM.CONST.VIEWERS

GCDM.ViewerRegistry = GCDM.ViewerRegistry or {}
local Registry = GCDM.ViewerRegistry

local cache = {}
local visibilityStates = setmetatable({}, { __mode = "k" })
local mouseStates = setmetatable({}, { __mode = "k" })
local visibilityAcquireHooked = setmetatable({}, { __mode = "k" })
local customVisibilityHidden = false

local function EnsureVisibilityState(frame)
	local state = visibilityStates[frame]
	if state then return state end
	local alpha = 1
	if frame.GetAlpha then
		local ok, value = pcall(frame.GetAlpha, frame)
		if ok and type(value) == "number" then alpha = value end
	end
	state = { originalAlpha = alpha, applying = false }
	visibilityStates[frame] = state
	if frame.SetAlpha then
		hooksecurefunc(frame, "SetAlpha", function(self, value)
			local current = visibilityStates[self]
			if not current or current.applying then return end
			if customVisibilityHidden then
				current.applying = true
				self:SetAlpha(0)
				current.applying = false
			elseif type(value) == "number" then
				current.originalAlpha = value
			end
		end)
	end
	return state
end

local function SetMouseSuppressed(frame, suppressed)
	if not frame or not frame.EnableMouse then return end
	if InCombatLockdown and InCombatLockdown() then return end
	local state = mouseStates[frame]
	if suppressed then
		if state == nil then
			local motion, click = false, false
			if frame.IsMouseMotionEnabled then
				local ok, value = pcall(frame.IsMouseMotionEnabled, frame)
				motion = ok and value and true or false
			end
			if frame.IsMouseClickEnabled then
				local ok, value = pcall(frame.IsMouseClickEnabled, frame)
				click = ok and value and true or false
			end
			state = { motion = motion, click = click }
			mouseStates[frame] = state
		end
		if frame.SetMouseMotionEnabled then frame:SetMouseMotionEnabled(false) end
		if frame.SetMouseClickEnabled then frame:SetMouseClickEnabled(false) end
	elseif state then
		if frame.SetMouseMotionEnabled then frame:SetMouseMotionEnabled(state.motion) end
		if frame.SetMouseClickEnabled then frame:SetMouseClickEnabled(state.click) end
		mouseStates[frame] = nil
	end
end

local function SetViewerMouseSuppressed(viewer, suppressed)
	SetMouseSuppressed(viewer, suppressed)
	local Skin = GCDM.Skin
	local frames = {}
	if Skin then
		if viewer == _G[GCDM.CONST.VIEWERS.BUFF_BAR] and Skin.CollectBarFrames then
			frames = Skin.CollectBarFrames(viewer)
		elseif Skin.CollectIconFrames then
			frames = Skin.CollectIconFrames(viewer)
		end
	end
	for _, frame in ipairs(frames) do SetMouseSuppressed(frame, suppressed) end
	if viewer.OnAcquireItemFrame and not visibilityAcquireHooked[viewer] then
		visibilityAcquireHooked[viewer] = true
		hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, itemFrame)
			SetMouseSuppressed(itemFrame, customVisibilityHidden)
		end)
	end
end

local function Resolve(name)
	local frame = _G[name]
	if frame then
		cache[name] = frame
	end
	return frame
end

function Registry:Get(name)
	return cache[name] or Resolve(name)
end

function Registry:Essential()
	return self:Get(VIEWERS.ESSENTIAL)
end

function Registry:Utility()
	return self:Get(VIEWERS.UTILITY)
end

function Registry:Buff()
	return self:Get(VIEWERS.BUFF)
end

function Registry:BuffBar()
	return self:Get(VIEWERS.BUFF_BAR)
end

function Registry:GetManaged()
	local list = {}
	for i = 1, #GCDM.CONST.MANAGED_VIEWER_NAMES do
		local frame = self:Get(GCDM.CONST.MANAGED_VIEWER_NAMES[i])
		if frame then
			list[#list + 1] = frame
		end
	end
	return list
end

function Registry:GetAll()
	local list = {}
	for i = 1, #GCDM.CONST.ALL_VIEWER_NAMES do
		local frame = self:Get(GCDM.CONST.ALL_VIEWER_NAMES[i])
		if frame then
			list[#list + 1] = frame
		end
	end
	return list
end

function Registry:HookOnce(frame, flagName, method, fn)
	if not frame or type(method) ~= "string" or type(fn) ~= "function" then
		return false
	end
	flagName = flagName or ("GCDMHook_" .. method)
	if frame[flagName] then
		return false
	end
	if type(frame[method]) ~= "function" then
		return false
	end
	frame[flagName] = true
	hooksecurefunc(frame, method, fn)
	return true
end

function Registry:RefreshCache()
	wipe(cache)
	for i = 1, #GCDM.CONST.ALL_VIEWER_NAMES do
		Resolve(GCDM.CONST.ALL_VIEWER_NAMES[i])
	end
end

function Registry:SetCustomVisibility(hidden)
	customVisibilityHidden = hidden and true or false
	for i = 1, #GCDM.CONST.ALL_VIEWER_NAMES do
		local frame = self:Get(GCDM.CONST.ALL_VIEWER_NAMES[i])
		if frame and frame.SetAlpha then
			local state = EnsureVisibilityState(frame)
			state.applying = true
			frame:SetAlpha(customVisibilityHidden and 0 or state.originalAlpha)
			state.applying = false
			SetViewerMouseSuppressed(frame, customVisibilityHidden)
		end
	end
end

GCDM:RegisterRefreshCallback("ViewerRegistry", function()
	Registry:RefreshCache()
end, 10, { GCDM.CONST.REFRESH.ALL, GCDM.CONST.REFRESH.LAYOUT, GCDM.CONST.REFRESH.STYLE })
