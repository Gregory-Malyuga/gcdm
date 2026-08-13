local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local Glow = {}
GCDM.Glow = Glow

local BLIZZARD_FIT = 1.4

local function IsCooldownViewerIcon(frame)
	if not frame then
		return false
	end
	local parent = frame
	for _ = 1, 8 do
		if not parent then
			return false
		end
		local name = parent.GetName and parent:GetName()
		if name == GCDM.CONST.VIEWERS.ESSENTIAL or name == GCDM.CONST.VIEWERS.UTILITY then
			return true
		end
		parent = parent.GetParent and parent:GetParent()
	end
	return false
end

local function HideRegion(region)
	if not region then
		return
	end
	if region.Stop then
		region:Stop()
	end
	if region.SetAlpha then
		region:SetAlpha(0)
	end
	if region.Hide then
		region:Hide()
	end
end

local function ClearLegacyGCDMGlow(frame)
	if not frame then
		return
	end
	local legacy = frame._ProcGlowGCDM_SpellAlert or frame["_ProcGlowGCDM_SpellAlert"]
	if legacy and legacy.Hide then
		legacy:Hide()
	end
	frame._ProcGlowGCDM_SpellAlert = nil
	if frame._ButtonGlow and frame._ButtonGlow.Hide then
		frame._ButtonGlow:Hide()
		frame._ButtonGlow = nil
	end
	-- Old action-button ants glow stacks with SpellActivationAlert.
	HideRegion(frame.OverlayGlow)
	HideRegion(frame.overlay)
	if frame.ActionButtonOverlay and frame.ActionButtonOverlay.Hide then
		frame.ActionButtonOverlay:Hide()
	end
end

-- ProcStartFlipbook is the large intro burst; together with ProcLoop it reads as a second ring.
local function SuppressProcStartBurst(alert)
	if not alert then
		return
	end
	if alert.ProcStartFlipbook and alert.ProcStartFlipbook.SetAlpha then
		alert.ProcStartFlipbook:SetAlpha(0)
	end
	if alert.ProcStart then
		if alert.ProcStart.SetAlpha then
			alert.ProcStart:SetAlpha(0)
		end
		if alert.ProcStart.ProcStartAnim and alert.ProcStart.ProcStartAnim.Stop then
			alert.ProcStart.ProcStartAnim:Stop()
		end
	end
	if alert.ProcStartAnim and alert.ProcStartAnim.Stop then
		alert.ProcStartAnim:Stop()
	end
end

local function GetFrameSpellID(frame)
	local Skin = GCDM.Skin
	if Skin and Skin.GetFrameSpellID then
		return Skin.GetFrameSpellID(frame)
	end
	return nil
end

local function GetFrameCooldownID(frame)
	return frame and frame.cooldownID or nil
end

function Glow.IsDisabledForFrame(frame)
	local db = GCDM:GetDB()
	if not db then
		return false
	end
	if db.glowEnabled == false then
		return true
	end
	local byCd = db.glowDisabledCooldowns
	local bySpell = db.glowDisabledSpells
	local cdID = GetFrameCooldownID(frame)
	if byCd and cdID and byCd[cdID] then
		return true
	end
	local spellID = GetFrameSpellID(frame)
	if bySpell and spellID and bySpell[spellID] then
		return true
	end
	return false
end

local function SuppressAlert(frame)
	local alert = frame and frame.SpellActivationAlert
	if not alert then
		return
	end
	alert:SetAlpha(0)
	alert:Hide()
end

local function StyleBlizzardAlert(frame)
	local alert = frame and frame.SpellActivationAlert
	if not alert then
		return
	end

	local db = GCDM:GetDB()
	if not db or not db.enabled then
		return
	end

	ClearLegacyGCDMGlow(frame)
	SuppressProcStartBurst(alert)

	if Glow.IsDisabledForFrame(frame) then
		SuppressAlert(frame)
		return
	end

	local w = frame:GetWidth() or 0
	local h = frame:GetHeight() or 0
	if w < 1 or h < 1 then
		return
	end

	local scale = db.glowScale or 1
	local fit = (db.glowAutoFit ~= false) and BLIZZARD_FIT or 1
	local aw = w * fit * scale
	local ah = h * fit * scale
	local ox = db.glowOffsetX or 0
	local oy = db.glowOffsetY or 0

	if alert.SetScale then
		alert:SetScale(1)
	end
	alert:SetAlpha(1)

	alert:ClearAllPoints()
	alert:SetPoint("CENTER", frame, "CENTER", ox, oy)
	alert:SetSize(aw, ah)

	local border = frame.GCDMBackdropBorder
	local baseLevel = frame:GetFrameLevel() or 0
	local borderLevel = border and border:GetFrameLevel() or (baseLevel + 3)
	alert:SetFrameLevel(borderLevel + 5)

	-- Loop only: start burst is the second yellow ring.
	if alert.ProcLoopFlipbook and alert.ProcLoopFlipbook.SetAlpha then
		alert.ProcLoopFlipbook:SetAlpha(1)
	end
	if alert.ProcLoop then
		if alert.ProcLoop.ClearAllPoints then
			alert.ProcLoop:ClearAllPoints()
			alert.ProcLoop:SetAllPoints(alert)
		end
		if alert.ProcLoop.Play and not alert.ProcLoop:IsPlaying() then
			alert.ProcLoop:Play()
		end
	end

	if not alert.GCDMStyleHooked then
		alert.GCDMStyleHooked = true
		alert:HookScript("OnShow", function(self)
			local parent = self:GetParent()
			if not parent or not IsCooldownViewerIcon(parent) then
				return
			end
			if Glow.IsDisabledForFrame(parent) then
				SuppressAlert(parent)
				return
			end
			StyleBlizzardAlert(parent)
			-- Blizzard may restart ProcStart after ShowAlert; kill it next frame.
			C_Timer.After(0, function()
				if parent.SpellActivationAlert then
					SuppressProcStartBurst(parent.SpellActivationAlert)
				end
			end)
		end)
	end
end

function Glow:ApplyFrame(frame)
	if not IsCooldownViewerIcon(frame) then
		return
	end
	ClearLegacyGCDMGlow(frame)
	if Glow.IsDisabledForFrame(frame) then
		SuppressAlert(frame)
		return
	end
	local alert = frame.SpellActivationAlert
	if alert and alert:IsShown() then
		StyleBlizzardAlert(frame)
	end
end

function Glow:ListVisibleCooldownOptions()
	local values = {}
	GCDM.Skin.ForEachManagedIcon(function(frame, _, viewerName)
		if viewerName ~= GCDM.CONST.VIEWERS.ESSENTIAL and viewerName ~= GCDM.CONST.VIEWERS.UTILITY then
			return
		end
		local cdID = GetFrameCooldownID(frame)
		if not cdID then
			return
		end
		local spellID = GetFrameSpellID(frame)
		local label = tostring(cdID)
		if spellID and C_Spell and C_Spell.GetSpellName then
			local name = C_Spell.GetSpellName(spellID)
			if name then
				label = string.format("%s (%d)", name, spellID)
			end
		elseif spellID then
			label = string.format("Spell %d", spellID)
		end
		values[cdID] = label
	end)
	return values
end

function Glow:HookAlertManager()
	if self.alertManagerHooked then
		return
	end
	local mgr = _G.ActionButtonSpellAlertManager
	if not mgr then
		return
	end

	hooksecurefunc(mgr, "ShowAlert", function(_, frame)
		if not IsCooldownViewerIcon(frame) then
			return
		end
		if Glow.IsDisabledForFrame(frame) then
			SuppressAlert(frame)
			return
		end
		StyleBlizzardAlert(frame)
		C_Timer.After(0, function()
			if frame.SpellActivationAlert then
				SuppressProcStartBurst(frame.SpellActivationAlert)
			end
		end)
	end)

	self.alertManagerHooked = true
end

local function ApplyGlow()
	Glow:HookAlertManager()
	local db = GCDM:GetDB()
	GCDM.Skin.ForEachManagedIcon(function(frame, _, viewerName)
		if viewerName ~= GCDM.CONST.VIEWERS.ESSENTIAL and viewerName ~= GCDM.CONST.VIEWERS.UTILITY then
			return
		end
		ClearLegacyGCDMGlow(frame)
		if not db or not db.enabled then
			return
		end
		if Glow.IsDisabledForFrame(frame) then
			SuppressAlert(frame)
			return
		end
		local alert = frame.SpellActivationAlert
		if alert and alert:IsShown() then
			StyleBlizzardAlert(frame)
		end
	end)
end

GCDM:RegisterRefreshCallback("Skin.Glow", ApplyGlow, 60, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
	GCDM.CONST.REFRESH.GLOW,
})
