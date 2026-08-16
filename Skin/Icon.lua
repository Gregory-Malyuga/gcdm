local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

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
	HidePandemicIndicator(frame)

	local icon = Skin.GetIconTexture(frame)
	Skin.ApplyIconChrome(frame, icon)
	if not icon then
		return
	end

	local w = frame:GetWidth() or 0
	local h = frame:GetHeight() or 0
	local db = GCDM:GetDB()
	local zoom = (db and db.iconZoom) or (GCDM.CONST and GCDM.CONST.DEFAULT_ICON_ZOOM) or 0.08

	Skin.ApplyIconTexCoord(icon, zoom, w, h)
	icon:ClearAllPoints()
	icon:SetAllPoints(frame)
	Pixel.DisableTextureSnap(icon)
	icon:SetDrawLayer("ARTWORK", 0)

	Skin.StyleCooldownSwipe(frame, db)
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
