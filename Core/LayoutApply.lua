-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- Shared “re-apply GCDM layout after Blizzard” helper.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local LayoutApply = {}
GCDM.LayoutApply = LayoutApply

function LayoutApply.RefreshManagedLayout()
	if not GCDM.Refresh or not GCDM.CONST or not GCDM.CONST.REFRESH then
		return
	end
	pcall(function()
		GCDM:Refresh(GCDM.CONST.REFRESH.LAYOUT)
	end)
	local Skin = GCDM.Skin
	if Skin and Skin.QueuePowerBarRelayout then
		pcall(Skin.QueuePowerBarRelayout)
	end
	if Skin and Skin.QueueBuffBarRelayout then
		pcall(Skin.QueueBuffBarRelayout)
	end
end

--- Schedule one or more deferred layout passes (Edit Mode / CDM settings).
function LayoutApply.Schedule(delays)
	delays = delays or { 0 }
	local CONST = GCDM.CONST or {}
	for i = 1, #delays do
		local delay = delays[i]
		if delay == nil then
			delay = CONST.LAYOUT_REAPPLY_IMMEDIATE or 0
		end
		C_Timer.After(delay, function()
			LayoutApply.RefreshManagedLayout()
		end)
	end
end
