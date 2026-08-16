local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

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

local function AspectTexCoord(frameW, frameH, zoomPadding)
	if not frameH or frameH <= 0 then
		return 0, 1, 0, 1
	end
	local padding = zoomPadding or 0
	local texWidth = 1 - (padding * 2)
	local aspectRatio = frameW / frameH
	local xRatio = aspectRatio < 1 and aspectRatio or 1
	local yRatio = aspectRatio > 1 and (1 / aspectRatio) or 1
	local left = -0.5 * texWidth * xRatio + 0.5
	local right = 0.5 * texWidth * xRatio + 0.5
	local top = -0.5 * texWidth * yRatio + 0.5
	local bottom = 0.5 * texWidth * yRatio + 0.5
	return left, right, top, bottom
end

function Skin.ApplyIconTexCoord(texture, zoomAmount, frameW, frameH)
	if not texture or not texture.SetTexCoord then
		return
	end
	local padding = (type(zoomAmount) == "number") and zoomAmount or 0
	if frameW and frameH and frameW > 0 and frameH > 0 then
		local left, right, top, bottom = AspectTexCoord(frameW, frameH, padding)
		texture:SetTexCoord(left, right, top, bottom)
	elseif padding > 0 then
		texture:SetTexCoord(padding, 1 - padding, padding, 1 - padding)
	else
		texture:SetTexCoord(0, 1, 0, 1)
	end
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
	if not icon or not icon.GetNumMaskTextures then
		return
	end
	if icon.GCDMMaskRemoved then
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
			-- Keep usability / click-use feedback.
			if region == frame.OutOfRange
				or region == frame.GCDMDebugFrame
				or region == frame.GCDMDebugIcon
			then
				-- leave alone
			else
				local atlas = region.GetAtlas and region:GetAtlas()
				local tex = region.GetTexture and region:GetTexture()
				local hide = SafeEquals(atlas, OVERLAY_ATLAS) or TextureMatchesOverlay(tex)
				if hide then
					region:SetAlpha(0)
					region:Hide()
				end
			end
		end
	end
end

local function SuppressCooldownFlash(flash)
	if not flash then
		return
	end
	if flash.GCDMSuppressingFlash then
		return
	end
	flash.GCDMSuppressingFlash = true
	if flash.FlashAnim and flash.FlashAnim.Stop then
		flash.FlashAnim:Stop()
	end
	if flash.SetAlpha then
		flash:SetAlpha(0)
	end
	if flash.Hide then
		flash:Hide()
	end
	flash.GCDMSuppressingFlash = false
end

local function HookCooldownFlash(flash)
	if not flash or flash.GCDMFlashSuppressed then
		return
	end
	flash.GCDMFlashSuppressed = true
	SuppressCooldownFlash(flash)
	if flash.HookScript then
		flash:HookScript("OnShow", function(self)
			SuppressCooldownFlash(self)
		end)
	end
	if flash.Show then
		hooksecurefunc(flash, "Show", function(self)
			SuppressCooldownFlash(self)
		end)
	end
	if flash.SetShown then
		hooksecurefunc(flash, "SetShown", function(self, shown)
			if shown then
				SuppressCooldownFlash(self)
			end
		end)
	end
	if flash.SetAlpha then
		hooksecurefunc(flash, "SetAlpha", function(self, alpha)
			if self.GCDMSuppressingFlash then
				return
			end
			if type(alpha) == "number" and alpha > 0 then
				SuppressCooldownFlash(self)
			end
		end)
	end
	local anim = flash.FlashAnim
	if anim and anim.Play then
		hooksecurefunc(anim, "Play", function(self)
			self:Stop()
			SuppressCooldownFlash(flash)
		end)
	end
end

local function EnsureFeedbackLayers(frame)
	-- Thin CD-finish flash (CooldownFlash) — suppress on icon and nested Cooldown.
	HookCooldownFlash(frame.CooldownFlash)
	local cd = frame.Cooldown
	if cd then
		HookCooldownFlash(cd.CooldownFlash)
	end
	local chargeCd = frame.ChargeCooldown
	if chargeCd then
		HookCooldownFlash(chargeCd.CooldownFlash)
	end

	local oor = frame.OutOfRange
	if oor then
		-- Blizzard already tints Icon via RefreshIconColor when out of range.
		-- The OutOfRange atlas (corner wedges) is larger than the icon and fills
		-- the pixel gap between buttons — suppress the chrome, keep the tint.
		oor:SetAlpha(0)
		oor:Hide()
		if not oor.GCDMSuppressed then
			oor.GCDMSuppressed = true
			local function Suppress(self)
				if self.GCDMSuppressing then
					return
				end
				self.GCDMSuppressing = true
				self:SetAlpha(0)
				if self.IsShown and self:IsShown() then
					self:Hide()
				end
				self.GCDMSuppressing = false
			end
			hooksecurefunc(oor, "Show", Suppress)
			hooksecurefunc(oor, "SetShown", function(self, shown)
				if shown then
					Suppress(self)
				end
			end)
			hooksecurefunc(oor, "SetAlpha", function(self, alpha)
				if self.GCDMSuppressing then
					return
				end
				if type(alpha) == "number" and alpha > 0 then
					Suppress(self)
				end
			end)
		end
	end
end

local function StyleCooldownSwipe(frame, db)
	local cd = frame.Cooldown
	if not cd then
		return
	end

	cd:ClearAllPoints()
	cd:SetAllPoints(frame)

	local border = frame.GCDMBackdropBorder
	local baseLevel = frame:GetFrameLevel() or 0
	local borderLevel = border and border:GetFrameLevel() or (baseLevel + 3)
	cd:SetFrameLevel(math.max(baseLevel + 1, borderLevel - 1))

	-- Solid square swipe: fills corners under the pixel border (CDM soft+circular leaves gaps).
	if cd.SetSwipeTexture then
		cd:SetSwipeTexture(GCDM.CONST.TEX_WHITE8X8)
	end
	local sc = (db and db.swipeColor) or GCDM.CONST.SWIPE_COLOR
	if cd.SetSwipeColor and sc then
		cd:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.6)
	end
	if cd.SetUseCircularEdge then
		cd:SetUseCircularEdge(false)
	end
	-- No thin spinning edge / end-of-CD bling (proc SpellActivationAlert glow stays in Glow.lua).
	if cd.SetDrawEdge then
		cd:SetDrawEdge(false)
	end
	if cd.SetDrawBling then
		cd:SetDrawBling(false)
	end
	if cd.SetDrawSwipe then
		cd:SetDrawSwipe(true)
	end
	if not cd.GCDMBlingSuppressed then
		cd.GCDMBlingSuppressed = true
		local function KillBling(self)
			if self.GCDMKillingBling then
				return
			end
			self.GCDMKillingBling = true
			if self.SetDrawBling then
				self:SetDrawBling(false)
			end
			if self.SetDrawEdge then
				self:SetDrawEdge(false)
			end
			self.GCDMKillingBling = false
		end
		if cd.SetDrawBling then
			hooksecurefunc(cd, "SetDrawBling", function(self, draw)
				if draw then
					KillBling(self)
				end
			end)
		end
		if cd.SetDrawEdge then
			hooksecurefunc(cd, "SetDrawEdge", function(self, draw)
				if draw then
					KillBling(self)
				end
			end)
		end
		-- SetCooldown often restores default bling/edge from template.
		if cd.SetCooldown then
			hooksecurefunc(cd, "SetCooldown", KillBling)
		end
		if cd.SetCooldownFromDurationObject then
			hooksecurefunc(cd, "SetCooldownFromDurationObject", KillBling)
		end
		if cd.Clear then
			hooksecurefunc(cd, "Clear", KillBling)
		end
	end

	local regions = { cd:GetRegions() }
	for i = 1, #regions do
		local region = regions[i]
		if region and region.IsObjectType and region:IsObjectType("Texture") then
			Pixel.DisableTextureSnap(region)
			-- Hide leftover bling/edge textures if present as named children.
			local name = region.GetName and region:GetName()
			local drawLayer = region.GetDrawLayer and region:GetDrawLayer()
			if (type(name) == "string" and (name:find("Bling", 1, true) or name:find("Edge", 1, true)))
				or drawLayer == "OVERLAY"
			then
				-- Don't hide swipe (BACKGROUND/ARTWORK); only suppress obvious edge/bling overlays.
				if type(name) == "string" and (name:find("Bling", 1, true) or name:find("Edge", 1, true)) then
					region:SetAlpha(0)
				end
			end
		end
	end

	-- Charge cooldown often has its own bling when a charge restores.
	local chargeCd = frame.ChargeCooldown
	if chargeCd and chargeCd.SetDrawBling then
		chargeCd:SetDrawBling(false)
		if chargeCd.SetDrawEdge then
			chargeCd:SetDrawEdge(false)
		end
		if not chargeCd.GCDMBlingSuppressed then
			chargeCd.GCDMBlingSuppressed = true
			local function KillChargeBling(self)
				if self.SetDrawBling then
					self:SetDrawBling(false)
				end
				if self.SetDrawEdge then
					self:SetDrawEdge(false)
				end
			end
			hooksecurefunc(chargeCd, "SetDrawBling", function(self, draw)
				if draw then
					KillChargeBling(self)
				end
			end)
			if chargeCd.SetCooldown then
				hooksecurefunc(chargeCd, "SetCooldown", KillChargeBling)
			end
		end
	end
end

local function HidePandemicIndicator(frame)
	local db = GCDM:GetDB()
	if not db or db.hidePandemicIndicator == false then
		return
	end

	if frame.PandemicIcon then
		frame.PandemicIcon:SetAlpha(0)
		frame.PandemicIcon:Hide()
	end

	if frame.ShowPandemicStateFrame and not frame.GCDMPandemicHooked then
		frame.GCDMPandemicHooked = true
		hooksecurefunc(frame, "ShowPandemicStateFrame", function(self)
			local profile = GCDM:GetDB()
			if not profile or profile.hidePandemicIndicator == false then
				return
			end
			if self.PandemicIcon then
				self.PandemicIcon:SetAlpha(0)
				self.PandemicIcon:Hide()
			end
		end)
	end
end

local function ApplyOneIcon(frame)
	if Skin.IsBuffBarItem and Skin.IsBuffBarItem(frame) then
		return
	end
	KillLegacyEdgeBorders(frame)
	HideBlizzardChrome(frame)
	HidePandemicIndicator(frame)

	local icon = Skin.GetIconTexture(frame)
	if not icon then
		return
	end

	HideCooldownManagerOverlays(frame, icon)
	StripCooldownManagerMask(icon)
	EnsureFeedbackLayers(frame)

	local w = frame:GetWidth() or 0
	local h = frame:GetHeight() or 0
	local db = GCDM:GetDB()
	local zoom = (db and db.iconZoom) or 0.08

	Skin.ApplyIconTexCoord(icon, zoom, w, h)
	icon:ClearAllPoints()
	icon:SetAllPoints(frame)
	Pixel.DisableTextureSnap(icon)
	icon:SetDrawLayer("ARTWORK", 0)

	StyleCooldownSwipe(frame, db)
	if GCDM.Glow and GCDM.Glow.ApplyFrame then
		GCDM.Glow:ApplyFrame(frame)
	end
end

local function ApplyIcon()
	local db = GCDM:GetDB()
	if not db or not db.enabled then
		return
	end
	Skin.ForEachManagedIcon(ApplyOneIcon)
end

local function HookViewerAcquire(viewer)
	if not viewer or viewer.GCDMAcquireHooked then
		return
	end
	viewer.GCDMAcquireHooked = true
	pcall(function()
		hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, itemFrame)
			local db = GCDM:GetDB()
			if itemFrame and db and db.enabled then
				ApplyOneIcon(itemFrame)
				if Skin.ApplyText then
					Skin.ApplyText(itemFrame)
				end
			end
		end)
	end)
end

local function HookViewers()
	local registry = GCDM.ViewerRegistry
	for i = 1, #GCDM.CONST.MANAGED_VIEWER_NAMES do
		HookViewerAcquire(registry:Get(GCDM.CONST.MANAGED_VIEWER_NAMES[i]))
	end
end

function Skin.CountIconMasks(frame)
	local icon = Skin.GetIconTexture(frame)
	if not icon or not icon.GetNumMaskTextures then
		return 0
	end
	return icon:GetNumMaskTextures() or 0
end

function Skin.DescribeRegions(frame)
	local icon = Skin.GetIconTexture(frame)
	local parts = {}
	local regions = { frame:GetRegions() }
	for i = 1, #regions do
		local r = regions[i]
		if r and r.IsObjectType and r:IsObjectType("Texture") then
			local layer = r.GetDrawLayer and select(1, r:GetDrawLayer()) or "?"
			local atlas = r.GetAtlas and r:GetAtlas()
			local tex = r.GetTexture and r:GetTexture()
			local shown = r.IsShown and r:IsShown()
			local alpha = r.GetAlpha and r:GetAlpha() or -1
			parts[#parts + 1] = string.format(
				"%d:%s a=%s tex=%s shown=%s alpha=%.2f%s",
				i,
				tostring(layer),
				tostring(atlas),
				tostring(tex),
				tostring(shown),
				alpha,
				(r == icon) and " [ICON]" or ""
			)
		end
	end
	return parts
end

GCDM:RegisterRefreshCallback("Skin.Icon", function()
	HookViewers()
	ApplyIcon()
end, 55, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})
