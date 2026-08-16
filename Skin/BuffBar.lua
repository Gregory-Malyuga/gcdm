local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local relayoutQueued = false
local mixinsHooked = false
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

local function HookBuffBarMixins()
	if mixinsHooked then return end
	mixinsHooked = true
	if CooldownViewerBuffBarItemMixin then
		if CooldownViewerBuffBarItemMixin.SetBarContent then
			hooksecurefunc(CooldownViewerBuffBarItemMixin, "SetBarContent", QueueRelayout)
		end
		if CooldownViewerBuffBarItemMixin.SetBarWidth then
			hooksecurefunc(CooldownViewerBuffBarItemMixin, "SetBarWidth", QueueRelayout)
		end
		if CooldownViewerBuffBarItemMixin.SetTimerShown then
			hooksecurefunc(CooldownViewerBuffBarItemMixin, "SetTimerShown", QueueRelayout)
		end
		if CooldownViewerBuffBarItemMixin.OnActiveStateChanged then
			hooksecurefunc(CooldownViewerBuffBarItemMixin, "OnActiveStateChanged", QueueRelayout)
		end
		if CooldownViewerBuffBarItemMixin.RefreshCooldownInfo then
			hooksecurefunc(CooldownViewerBuffBarItemMixin, "RefreshCooldownInfo", function(self)
				if self.GCDMVisualPending then return end
				self.GCDMVisualPending = true
				C_Timer.After(0, function()
					self.GCDMVisualPending = false
					local db = GCDM:GetDB()
					if not db or not db.enabled or not self.Bar then return end
					local w = self.GCDMWantW or Skin.BuffBarResolveWidth(db)
					local h = self.GCDMWantH or Skin.BuffBarResolveHeight(db)
					Skin.StyleOneBuffBar(self, db, w, h)
				end)
			end)
		end
	end
	if BuffBarCooldownViewerMixin then
		if BuffBarCooldownViewerMixin.SetBarContent then
			hooksecurefunc(BuffBarCooldownViewerMixin, "SetBarContent", QueueRelayout)
		end
		if BuffBarCooldownViewerMixin.SetBarWidthScale then
			hooksecurefunc(BuffBarCooldownViewerMixin, "SetBarWidthScale", QueueRelayout)
		end
		if BuffBarCooldownViewerMixin.SetTimerShown then
			hooksecurefunc(BuffBarCooldownViewerMixin, "SetTimerShown", QueueRelayout)
		end
	end
end

local function HookBuffBarViewer(viewer)
	if not viewer or viewer.GCDMBuffBarHooked then return end
	viewer.GCDMBuffBarHooked = true
	if viewer.RefreshLayout then
		hooksecurefunc(viewer, "RefreshLayout", QueueRelayout)
	end
	pcall(function()
		hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, itemFrame)
			if itemFrame and Skin.IsBuffBarItem(itemFrame) then
				QueueRelayout()
			end
		end)
	end)
end

GCDM:RegisterRefreshCallback("Skin.BuffBar", function()
	HookBuffBarMixins()
	HookBuffBarViewer(GCDM.ViewerRegistry:BuffBar())
	QueueRelayout()
end, 45, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.LAYOUT,
	GCDM.CONST.REFRESH.STYLE,
})
