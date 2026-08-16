local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local mixinsHooked = false

local function HookMixins()
	if mixinsHooked then return end
	mixinsHooked = true
	if CooldownViewerCooldownItemMixin and CooldownViewerCooldownItemMixin.RefreshSpellChargeInfo then
		hooksecurefunc(CooldownViewerCooldownItemMixin, "RefreshSpellChargeInfo", function(self)
			local db = GCDM:GetDB()
			if db and db.enabled then Skin.ApplyText(self) end
		end)
	end
	if CooldownViewerBuffIconItemMixin and CooldownViewerBuffIconItemMixin.RefreshApplications then
		hooksecurefunc(CooldownViewerBuffIconItemMixin, "RefreshApplications", function(self)
			local db = GCDM:GetDB()
			if db and db.enabled then Skin.ApplyText(self) end
		end)
	end
	if CooldownViewerItemMixin and CooldownViewerItemMixin.OnLoad then
		hooksecurefunc(CooldownViewerItemMixin, "OnLoad", function(self)
			local db = GCDM:GetDB()
			if db and db.enabled then Skin.ApplyText(self) end
		end)
	end
	local function OnCooldownReassigned(self)
		local db = GCDM:GetDB()
		if not db or not db.enabled or not self then return end
		self.GCDMAnchor = nil
		Skin.ApplyText(self)
		if Skin.RebuildPressOverlayMap then
			C_Timer.After(0, function()
				if Skin.RebuildPressOverlayMap then Skin.RebuildPressOverlayMap() end
			end)
		end
	end
	if CooldownViewerItemMixin and CooldownViewerItemMixin.OnCooldownIDSet then
		hooksecurefunc(CooldownViewerItemMixin, "OnCooldownIDSet", OnCooldownReassigned)
	elseif CooldownViewerItemMixin and CooldownViewerItemMixin.SetCooldownID then
		hooksecurefunc(CooldownViewerItemMixin, "SetCooldownID", OnCooldownReassigned)
	end
	if CooldownViewerCooldownItemMixin and CooldownViewerCooldownItemMixin.OnCooldownIDSet then
		hooksecurefunc(CooldownViewerCooldownItemMixin, "OnCooldownIDSet", OnCooldownReassigned)
	end
end

local function ApplyTextAll()
	HookMixins()
	local db = GCDM:GetDB()
	if not db or not db.enabled then return end
	GCDM.Skin.ForEachManagedIcon(function(frame, _, viewerName)
		Skin.ApplyText(frame, viewerName)
	end)
	if GCDM.Skin.ForEachBuffBar then
		GCDM.Skin.ForEachBuffBar(function(frame)
			if Skin.StyleBuffBarLabels then Skin.StyleBuffBarLabels(frame, db) end
		end)
	end
end

GCDM:RegisterRefreshCallback("Skin.Text", ApplyTextAll, 55, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})
