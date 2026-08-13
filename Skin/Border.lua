local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

local function EnsureBackdropBorder(frame)
	local border = frame.GCDMBackdropBorder
	if border then
		return border
	end
	border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	border:SetFrameLevel(frame:GetFrameLevel() + 2)
	frame.GCDMBackdropBorder = border

	if frame.GCDMBorders then
		for i = 1, #frame.GCDMBorders do
			frame.GCDMBorders[i]:Hide()
		end
	end
	if frame.GCDMBorder then
		frame.GCDMBorder:Hide()
	end
	return border
end

local function ApplyBorder()
	Pixel.Update()
	local db = GCDM:GetDB()
	if not db or not db.enabled then
		Skin.ForEachManagedIcon(function(frame)
			local border = frame.GCDMBackdropBorder
			if border then
				border:Hide()
			end
		end)
		return
	end

	local size = db.borderSize or 1
	local c = db.borderColor or { r = 0, g = 0, b = 0, a = 1 }
	local offsetX = db.borderOffsetX or 0
	local offsetY = db.borderOffsetY or 0

	Skin.ForEachManagedIcon(function(frame)
		if frame.GCDMBorders then
			for i = 1, #frame.GCDMBorders do
				frame.GCDMBorders[i]:Hide()
			end
		end
		if frame.GCDMBorder then
			frame.GCDMBorder:Hide()
		end

		local border = EnsureBackdropBorder(frame)
		if size <= 0 then
			border:Hide()
			return
		end

		border:SetFrameLevel((frame:GetFrameLevel() or 0) + 3)
		border:SetBackdrop(Skin.BuildBorderBackdrop(db))
		if NineSliceUtil and NineSliceUtil.DisableSharpening then
			NineSliceUtil.DisableSharpening(border)
		end
		border:ClearAllPoints()
		border:SetPoint("TOPLEFT", frame, "TOPLEFT", offsetX, offsetY)
		border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -offsetX, -offsetY)
		border:SetBackdropBorderColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
		border:Show()
	end)
end

GCDM:RegisterRefreshCallback("Skin.Border", ApplyBorder, 50, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})
