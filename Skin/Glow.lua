local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local Glow = GCDM.Glow or {}
GCDM.Glow = Glow

function Glow:ApplyFrame(frame)
	if not Glow.IsCooldownViewerIcon(frame) then
		return
	end
	Glow.ClearLegacyGCDMGlow(frame)
	if Glow.IsDisabledForFrame(frame) then
		Glow.SuppressAlert(frame)
		return
	end
	local alert = frame.SpellActivationAlert
	if alert and alert:IsShown() then
		Glow.StyleBlizzardAlert(frame)
	end
end

function Glow:ListVisibleCooldownOptions()
	local values = {}
	GCDM.Skin.ForEachManagedIcon(function(frame, _, viewerName)
		if viewerName ~= GCDM.CONST.VIEWERS.ESSENTIAL and viewerName ~= GCDM.CONST.VIEWERS.UTILITY then
			return
		end
		local cdID = frame and frame.cooldownID
		if not cdID then
			return
		end
		local spellID = GCDM.Skin.GetFrameSpellID and GCDM.Skin.GetFrameSpellID(frame)
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
		if not Glow.IsCooldownViewerIcon(frame) then
			return
		end
		if Glow.IsDisabledForFrame(frame) then
			Glow.SuppressAlert(frame)
			return
		end
		Glow.StyleBlizzardAlert(frame)
		C_Timer.After(0, function()
			if frame.SpellActivationAlert then
				Glow.SuppressProcStartBurst(frame.SpellActivationAlert)
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
		Glow.ClearLegacyGCDMGlow(frame)
		if not db or not db.enabled then
			return
		end
		if Glow.IsDisabledForFrame(frame) then
			Glow.SuppressAlert(frame)
			return
		end
		local alert = frame.SpellActivationAlert
		if alert and alert:IsShown() then
			Glow.StyleBlizzardAlert(frame)
		end
	end)
end

GCDM:RegisterRefreshCallback("Skin.Glow", ApplyGlow, 60, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
	GCDM.CONST.REFRESH.GLOW,
})
