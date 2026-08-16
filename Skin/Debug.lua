local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local D = Skin.DebugUtil

local function ApplyDebugVisuals()
	local db = GCDM:GetDB()
	local enabled = db and db.debugSkin
	Skin.ForEachManagedIcon(function(frame)
		if not enabled then
			D.ClearOverlays(frame)
			return
		end
		local frameOverlay = D.EnsureOverlay(frame, "GCDMDebugFrame", 0, 1, 0, 0.25)
		frameOverlay:ClearAllPoints()
		frameOverlay:SetAllPoints(frame)
		frameOverlay:Show()
		local icon = Skin.GetIconTexture(frame)
		local iconOverlay = D.EnsureOverlay(frame, "GCDMDebugIcon", 1, 0, 1, 0.35)
		if icon then
			iconOverlay:ClearAllPoints()
			iconOverlay:SetAllPoints(icon)
			iconOverlay:Show()
		else
			iconOverlay:Hide()
		end
	end)
	Skin.ForEachBuffBar(function(frame)
		if not enabled then
			D.ClearOverlays(frame)
			if frame.Bar then
				D.ClearOverlays(frame.Bar)
			end
			if frame.GCDMSkinBar then
				D.ClearOverlays(frame.GCDMSkinBar)
			end
			return
		end
		local frameOverlay = D.EnsureOverlay(frame, "GCDMDebugFrame", 0, 1, 1, 0.35)
		frameOverlay:ClearAllPoints()
		frameOverlay:SetAllPoints(frame)
		frameOverlay:Show()
		if frame.Bar then
			local barOverlay = D.EnsureOverlay(frame.Bar, "GCDMDebugFrame", 1, 1, 0, 0.35)
			barOverlay:ClearAllPoints()
			barOverlay:SetAllPoints(frame.Bar)
			barOverlay:Show()
		end
		if frame.GCDMSkinBar then
			local skinOverlay = D.EnsureOverlay(frame.GCDMSkinBar, "GCDMDebugFrame", 1, 0, 1, 0.45)
			skinOverlay:ClearAllPoints()
			skinOverlay:SetAllPoints(frame.GCDMSkinBar)
			skinOverlay:Show()
		end
	end)
end

function GCDM:ToggleDebugSkin()
	local db = self:GetDB()
	if not db then
		return
	end
	db.debugSkin = not db.debugSkin
	self:Print("debugSkin = " .. tostring(db.debugSkin))
	self:Refresh(self.CONST.REFRESH.STYLE)
	if db.debugSkin then
		self:DumpSkinDebug()
	end
end

GCDM:RegisterRefreshCallback("Skin.Debug", ApplyDebugVisuals, 90, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})
