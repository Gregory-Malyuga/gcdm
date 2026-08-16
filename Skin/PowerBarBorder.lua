-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- Power bar pixel border + statusbar chrome styling.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel
local PowerBarChrome = Skin.PowerBarChrome

local function StylePixelBorder(bar, size, r, g, b, a)
	if not bar.GCDMEdge then
		bar.GCDMEdge = {
			T = bar:CreateTexture(nil, "OVERLAY", nil, 7),
			B = bar:CreateTexture(nil, "OVERLAY", nil, 7),
			L = bar:CreateTexture(nil, "OVERLAY", nil, 7),
			R = bar:CreateTexture(nil, "OVERLAY", nil, 7),
		}
		for _, tex in pairs(bar.GCDMEdge) do
			tex:SetColorTexture(0, 0, 0, 1)
			if Pixel.DisableTextureSnap then
				Pixel.DisableTextureSnap(tex)
			end
		end
	end
	local edges = bar.GCDMEdge
	if bar.GCDMBorder then
		bar.GCDMBorder:Hide()
	end
	if not size or size <= 0 then
		for _, tex in pairs(edges) do
			tex:Hide()
		end
		return
	end
	local t
	if size <= 1 then
		Pixel.Update()
		t = Pixel.GetSize()
		if not t or t <= 0 or t > 2 then
			t = 1
		end
	else
		t = Pixel.Snap(size)
	end
	edges.T:ClearAllPoints()
	edges.T:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
	edges.T:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
	edges.T:SetHeight(t)
	edges.B:ClearAllPoints()
	edges.B:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
	edges.B:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
	edges.B:SetHeight(t)
	edges.L:ClearAllPoints()
	edges.L:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -t)
	edges.L:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, t)
	edges.L:SetWidth(t)
	edges.R:ClearAllPoints()
	edges.R:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -t)
	edges.R:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, t)
	edges.R:SetWidth(t)
	for _, tex in pairs(edges) do
		tex:SetColorTexture(r or 0, g or 0, b or 0, a or 1)
		tex:Show()
	end
end

function PowerBarChrome.StyleBarChrome(bar, db, height)
	local texName = db.powerBarTexture or "Solid"
	local tex = (Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(texName)) or GCDM.CONST.TEX_WHITE8X8
	local bgName = db.powerBarBackgroundTexture or "Solid"
	local bgr, bgg, bgb, bga = PowerBarChrome.BgUnpack(db)

	bar:SetHeight(Pixel.Snap(height))
	bar:SetStatusBarTexture(tex)
	local st = bar:GetStatusBarTexture()
	if not st or (texName ~= "Solid" and st.GetTexture and not st:GetTexture()) then
		bar:SetStatusBarTexture(GCDM.CONST.TEX_WHITE8X8)
		st = bar:GetStatusBarTexture()
	end
	if st and Pixel.DisableTextureSnap then
		Pixel.DisableTextureSnap(st)
	end
	if st then
		st:SetAlpha(1)
		st:Show()
	end
	if bgName == "Solid" then
		bar.GCDMBg:SetColorTexture(bgr, bgg, bgb, bga)
	else
		local bgPath = (Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(bgName)) or GCDM.CONST.TEX_WHITE8X8
		bar.GCDMBg:SetTexture(bgPath)
		if bar.GCDMBg.SetTexCoord then
			bar.GCDMBg:SetTexCoord(0, 1, 0, 1)
		end
		if not bar.GCDMBg:GetTexture() then
			bar.GCDMBg:SetColorTexture(bgr, bgg, bgb, bga)
		else
			bar.GCDMBg:SetVertexColor(bgr, bgg, bgb, bga)
		end
	end
	bar.GCDMBg:SetAlpha(1)
	bar.GCDMBg:Show()
	if Pixel.DisableTextureSnap then
		Pixel.DisableTextureSnap(bar.GCDMBg)
	end

	local size = db.powerBarBorderSize
	if size == nil then
		size = 1
	end
	local bc = db.borderColor or { r = 0, g = 0, b = 0, a = 1 }
	StylePixelBorder(bar, size, bc.r or 0, bc.g or 0, bc.b or 0, bc.a or 1)

	local outline = PowerBarChrome.ApplyFont(bar.GCDMText, db) or "OUTLINE"
	local tc = db.powerBarTextColor or { r = 1, g = 1, b = 1, a = 1 }
	bar.GCDMText:SetTextColor(tc.r or 1, tc.g or 1, tc.b or 1, tc.a or 1)
	if outline ~= "" then
		bar.GCDMText:SetShadowColor(0, 0, 0, 1)
		bar.GCDMText:SetShadowOffset(1, -1)
	else
		bar.GCDMText:SetShadowColor(0, 0, 0, 0)
		bar.GCDMText:SetShadowOffset(0, 0)
	end
	bar.GCDMText:SetShown(db.powerBarShowText ~= false)
end
