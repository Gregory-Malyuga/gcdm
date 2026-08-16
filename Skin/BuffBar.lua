local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local relayoutQueued = false
local relayoutDirty = false

-- Always defer; never mutate CDM frames inside Blizzard mixin call stacks.
local function QueueRelayout()
	relayoutDirty = true
	if relayoutQueued then return end
	relayoutQueued = true
	local function pump()
		relayoutDirty = false
		Skin.ApplyBuffBars()
		if relayoutDirty then
			C_Timer.After(0, pump)
			return
		end
		C_Timer.After(0, function()
			if relayoutDirty then
				pump()
				return
			end
			Skin.ApplyBuffBars()
			if relayoutDirty then
				pump()
				return
			end
			relayoutQueued = false
		end)
	end
	C_Timer.After(0, pump)
end

Skin.QueueBuffBarRelayout = QueueRelayout

-- Bars used to be re-laid out from hooks on the buff bar mixins (SetBarContent,
-- RefreshCooldownInfo, OnActiveStateChanged, RefreshLayout). Those hooks made
-- Blizzard's own aura refresh continue tainted, so the same triggers now come
-- from CDMWatch on our own event frame.
GCDM:RegisterRefreshCallback("Skin.BuffBar", QueueRelayout, 45, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.LAYOUT,
	GCDM.CONST.REFRESH.STYLE,
})

GCDM.CDMWatch:Register("Skin.BuffBar", QueueRelayout, 0.1)
