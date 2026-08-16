local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local MASK_ATLAS = "UI-HUD-CoolDownManager-Mask"
local OVERLAY_ATLAS = "UI-HUD-CoolDownManager-IconOverlay"
local OVERLAY_FILE_ID = 6707800

local function SafeEquals(value, expected)
	if type(value) == "number" and canaccessvalue and not canaccessvalue(value) then
		return false
	end
	return value == expected
end

local function TextureMatchesOverlay(tex)
	if tex == nil then
		return false
	end
	if SafeEquals(tex, OVERLAY_FILE_ID) then
		return true
	end
	if type(tex) == "string" then
		local lower = string.lower(tex)
		return lower:find("cooldownmanager", 1, true) ~= nil
			or lower:find("cool-down-manager", 1, true) ~= nil
			or lower:find("iconoverlay", 1, true) ~= nil
	end
	return false
end

local function KillLegacyEdgeBorders(frame)
	if frame.GCDMBorders then
		for i = 1, #frame.GCDMBorders do
			local tex = frame.GCDMBorders[i]
			tex:Hide()
			tex:SetAlpha(0)
			tex:ClearAllPoints()
			tex:SetTexture(nil)
		end
		frame.GCDMBorders = nil
	end
	if frame.GCDMBorder then
		frame.GCDMBorder:Hide()
		frame.GCDMBorder:SetAlpha(0)
		frame.GCDMBorder = nil
	end
end

local function HideBlizzardChrome(frame)
	local border = frame.IconBorder or frame.Border or frame.border
	if border and border.Hide then
		border:Hide()
		border:SetAlpha(0)
	end
	if frame.SlotBackground and frame.SlotBackground.Hide then
		frame.SlotBackground:Hide()
	end
end

local function StripCooldownManagerMask(icon)
	if not icon or not icon.GetNumMaskTextures or icon.GCDMMaskRemoved then
		return
	end
	for i = 1, icon:GetNumMaskTextures() do
		local mask = icon:GetMaskTexture(i)
		if mask and SafeEquals(mask.GetAtlas and mask:GetAtlas(), MASK_ATLAS) then
			icon:RemoveMaskTexture(mask)
			icon.GCDMMaskRemoved = true
			icon.GCDMMaskSource = mask
			break
		end
	end
end

local function HideCooldownManagerOverlays(frame, icon)
	local regions = { frame:GetRegions() }
	for i = 1, #regions do
		local region = regions[i]
		if region and region.IsObjectType and region:IsObjectType("Texture") and region ~= icon then
			if region ~= frame.OutOfRange and region ~= frame.GCDMDebugFrame and region ~= frame.GCDMDebugIcon then
				local atlas = region.GetAtlas and region:GetAtlas()
				local tex = region.GetTexture and region:GetTexture()
				if SafeEquals(atlas, OVERLAY_ATLAS) or TextureMatchesOverlay(tex) then
					region:SetAlpha(0)
					region:Hide()
				end
			end
		end
	end
end

local function SuppressCooldownFlash(flash)
	if not flash or flash.GCDMSuppressingFlash then
		return
	end
	flash.GCDMSuppressingFlash = true
	if flash.FlashAnim and flash.FlashAnim.Stop then flash.FlashAnim:Stop() end
	if flash.SetAlpha then flash:SetAlpha(0) end
	if flash.Hide then flash:Hide() end
	flash.GCDMSuppressingFlash = false
end

-- Blizzard only calls Show/Hide on the cooldown flash and the out-of-range
-- texture (the flash animation drives the alpha of its own child texture, not
-- of the frame), so zeroing alpha here keeps both silenced for good. Hooking
-- their Show/SetAlpha instead would run inside RefreshSpellCooldownInfo and
-- taint the rest of that refresh.
local function EnsureFeedbackLayers(frame)
	SuppressCooldownFlash(frame.CooldownFlash)
	local cd = frame.Cooldown
	if cd then
		SuppressCooldownFlash(cd.CooldownFlash)
	end
	local chargeCd = frame.ChargeCooldown
	if chargeCd then
		SuppressCooldownFlash(chargeCd.CooldownFlash)
	end
	local oor = frame.OutOfRange
	if not oor then
		return
	end
	oor:SetAlpha(0)
	oor:Hide()
end
function Skin.ApplyIconChrome(frame, icon)
	KillLegacyEdgeBorders(frame)
	HideBlizzardChrome(frame)
	if icon then
		HideCooldownManagerOverlays(frame, icon)
		StripCooldownManagerMask(icon)
	end
	EnsureFeedbackLayers(frame)
end
