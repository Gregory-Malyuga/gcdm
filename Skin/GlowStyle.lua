local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local Glow = GCDM.Glow or {}
GCDM.Glow = Glow

local BLIZZARD_FIT = 1.4

function Glow.IsCooldownViewerIcon(frame)
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

function Glow.ClearLegacyGCDMGlow(frame)
	if not frame then
		return
	end
	-- Hide only: clearing the fields would be an insecure write into a CDM item
	-- frame, and Blizzard reads those frames inside secret cooldown paths.
	local legacy = frame._ProcGlowGCDM_SpellAlert
	if legacy and legacy.Hide then
		legacy:Hide()
	end
	if frame._ButtonGlow and frame._ButtonGlow.Hide then
		frame._ButtonGlow:Hide()
	end
	HideRegion(frame.OverlayGlow)
	HideRegion(frame.overlay)
	if frame.ActionButtonOverlay and frame.ActionButtonOverlay.Hide then
		frame.ActionButtonOverlay:Hide()
	end
end

function Glow.SuppressProcStartBurst(alert)
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

function Glow.SuppressAlert(frame)
	local alert = frame and frame.SpellActivationAlert
	if not alert then
		return
	end
	alert:SetAlpha(0)
	alert:Hide()
end

function Glow.StyleBlizzardAlert(frame)
	local alert = frame and frame.SpellActivationAlert
	if not alert then
		return
	end

	local db = GCDM:GetDB()
	if not db or not db.enabled then
		return
	end

	Glow.ClearLegacyGCDMGlow(frame)
	Glow.SuppressProcStartBurst(alert)

	if Glow.IsDisabledForFrame(frame) then
		Glow.SuppressAlert(frame)
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
			if not parent or not Glow.IsCooldownViewerIcon(parent) then
				return
			end
			if Glow.IsDisabledForFrame(parent) then
				Glow.SuppressAlert(parent)
				return
			end
			Glow.StyleBlizzardAlert(parent)
			C_Timer.After(0, function()
				if parent.SpellActivationAlert then
					Glow.SuppressProcStartBurst(parent.SpellActivationAlert)
				end
			end)
		end)
	end
end
