local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local VIEWERS = GCDM.CONST.VIEWERS

GCDM.ViewerRegistry = GCDM.ViewerRegistry or {}
local Registry = GCDM.ViewerRegistry

local cache = {}

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

function Registry:RefreshCache()
	wipe(cache)
	for i = 1, #GCDM.CONST.ALL_VIEWER_NAMES do
		Resolve(GCDM.CONST.ALL_VIEWER_NAMES[i])
	end
end

GCDM:RegisterRefreshCallback("ViewerRegistry", function()
	Registry:RefreshCache()
end, 10, { GCDM.CONST.REFRESH.ALL, GCDM.CONST.REFRESH.LAYOUT, GCDM.CONST.REFRESH.STYLE })
