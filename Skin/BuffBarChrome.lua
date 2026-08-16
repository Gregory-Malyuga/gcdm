local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel
local BLIZZARD_BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"

function Skin.BuffBarResolveStyle(db)
	local s = db and db.buffBarStyle
	if s == nil or s == "solid" or s == "SharedMedia" or s == "sharedmedia" then return "solid" end
	return s
end

local function PlainNumber(value)
	if type(value) ~= "number" then
		return nil
	end
	if issecretvalue and issecretvalue(value) then
		return nil
	end
	if canaccessvalue and not canaccessvalue(value) then
		return nil
	end
	return value
end

local function SyncSkinBarValues(frame, bar)
	local skin = frame.GCDMSkinBar
	if not skin or not bar then return end

	-- Blizzard's buff StatusBar often carries secret min/max/value. We may SetValue
	-- those onto our own bar, but must never compare or lerp them (that throws),
	-- and must never replace a secret with 0 — that left the digit visible and the
	-- fill empty ("цифра есть, полосы нет").
	local minV, maxV = 0, 1
	local minMaxPlain = true
	if bar.GetMinMaxValues then
		local ok, a, b = pcall(bar.GetMinMaxValues, bar)
		if ok then
			local pa, pb = PlainNumber(a), PlainNumber(b)
			if pa and pb then
				minV, maxV = pa, pb
			else
				pcall(skin.SetMinMaxValues, skin, a, b)
				minMaxPlain = false
			end
		end
	end
	if minMaxPlain then
		skin:SetMinMaxValues(minV, maxV)
	end

	if not bar.GetValue then
		return
	end
	local ok, v = pcall(bar.GetValue, bar)
	if not ok or v == nil then
		return
	end
	local plain = PlainNumber(v)
	if plain then
		if Skin.SmoothBarSetValue then
			Skin.SmoothBarSetValue(skin, plain, Skin.IsBarSmoothEnabled and Skin.IsBarSmoothEnabled(GCDM:GetDB()))
		else
			skin:SetValue(plain)
		end
		return
	end
	pcall(skin.SetValue, skin, v)
end

-- The skinned fill used to follow Blizzard's bar through SetValue and
-- SetMinMaxValues hooks. Blizzard drives those from the buff bar OnUpdate, the
-- same handler that compares secret pandemic values, so the hooks tainted it
-- every frame. We mirror the value from our own OnUpdate instead, and stop as
-- soon as no skinned bar is visible.
local valueDriver

local function SyncAllSkinBars()
	if not Skin.ForEachBuffBar then return false end
	local active = false
	Skin.ForEachBuffBar(function(frame)
		local skin = frame.GCDMSkinBar
		if skin and skin:IsShown() and frame.Bar then
			SyncSkinBarValues(frame, frame.Bar)
			active = true
		end
	end)
	return active
end

local function StartValueDriver()
	if not valueDriver then
		valueDriver = CreateFrame("Frame")
	end
	if valueDriver:GetScript("OnUpdate") then return end
	valueDriver:SetScript("OnUpdate", function(self)
		if not SyncAllSkinBars() then
			self:SetScript("OnUpdate", nil)
		end
	end)
end

function Skin.StopBuffBarValueDriver()
	if valueDriver then valueDriver:SetScript("OnUpdate", nil) end
end

local function HideBlizzardBarArt(bar)
	if not bar then return end
	local sbTex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	if sbTex and sbTex.SetAlpha then sbTex:SetAlpha(0) end
	if bar.BarBG then bar.BarBG:SetAlpha(0) end
	if bar.Pip then bar.Pip:SetAlpha(0) end
	if bar.SetAlpha then bar:SetAlpha(1) end
end

function Skin.ApplyBuffBarSolid(frame, bar, db)
	local tex = Skin.FetchStatusBarTexture(db.buffBarTexture or "Solid") or GCDM.CONST.TEX_WHITE8X8
	local bgTexPath = Skin.FetchStatusBarTexture(db.buffBarBackgroundTexture or db.buffBarTexture or "Solid") or GCDM.CONST.TEX_WHITE8X8
	local fill = db.buffBarColor or { r = 0.4, g = 0.6, b = 0.9, a = 1 }
	local bg = db.buffBarBackgroundColor or { r = 0.1, g = 0.1, b = 0.1, a = 0.8 }
	local fr, fg, fb, fa = fill.r or 0.4, fill.g or 0.6, fill.b or 0.9, fill.a or 1
	HideBlizzardBarArt(bar)
	local skin = frame.GCDMSkinBar
	if not skin then
		-- Child of Blizzard's StatusBar so Name/Duration (also on the bar) stay above
		-- the fill. We only SetValue from our own OnUpdate — no SetValue hooks.
		skin = CreateFrame("StatusBar", nil, bar)
		frame.GCDMSkinBar = skin
		frame.GCDMSkinBarBG = skin:CreateTexture(nil, "BACKGROUND", nil, -1)
		frame.GCDMSkinBarBG:SetAllPoints(skin)
	elseif skin:GetParent() ~= bar then
		skin:SetParent(bar)
	end
	skin:SetFrameLevel(math.max(1, (bar:GetFrameLevel() or 0)))
	skin:ClearAllPoints()
	skin:SetAllPoints(bar)
	skin:SetStatusBarTexture(tex)
	local skinTex = skin:GetStatusBarTexture()
	if skinTex then
		Pixel.DisableTextureSnap(skinTex)
		if skinTex.SetVertexColor then skinTex:SetVertexColor(fr, fg, fb, fa) end
	end
	skin:SetStatusBarColor(fr, fg, fb, fa)
	skin:SetOrientation("HORIZONTAL")
	if skin.SetReverseFill then skin:SetReverseFill(false) end
	local bgTex = frame.GCDMSkinBarBG
	bgTex:SetTexture(bgTexPath)
	bgTex:SetVertexColor(bg.r or 0.1, bg.g or 0.1, bg.b or 0.1, bg.a or 0.8)
	bgTex:Show()
	Pixel.DisableTextureSnap(bgTex)
	SyncSkinBarValues(frame, bar)
	skin:Show()
	skin:SetAlpha(1)
	StartValueDriver()
	if frame.GCDMBarBackground then frame.GCDMBarBackground:Hide() end
end

function Skin.HideBuffBarPipAndExtras(frame, style)
	if frame.DebuffBorder and frame.DebuffBorder.Hide then frame.DebuffBorder:Hide() end
	if style ~= "solid" then return end
	local bar = frame.Bar
	if not bar then return end
	if bar.BarBG then bar.BarBG:SetAlpha(0) end
	-- Pip alpha is re-zeroed by each styling pass rather than by hooks on its
	-- Show/SetAlpha, which would run inside Blizzard's bar update.
	if bar.Pip then bar.Pip:SetAlpha(0) end
end

function Skin.ApplyBuffBarBlizzard(frame, bar)
	if frame.GCDMSkinBar then frame.GCDMSkinBar:Hide() end
	if frame.GCDMBarBackground then frame.GCDMBarBackground:Hide() end
	local sbTex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	if sbTex and sbTex.SetAlpha then sbTex:SetAlpha(1) end
	if bar.GetStatusBarTexture and not bar:GetStatusBarTexture() then bar:SetStatusBarTexture(BLIZZARD_BAR_TEXTURE) end
	if bar.BarBG then bar.BarBG:SetAlpha(1) bar.BarBG:Show() end
end

function Skin.ApplyBuffBarOwnedBorder(owner, key, parent, db)
	if not parent then
		if owner[key] then owner[key]:Hide() end
		return
	end
	local size = db.borderSize or (GCDM.CONST and GCDM.CONST.DEFAULT_BORDER_SIZE) or 1
	local c = db.borderColor or { r = 0, g = 0, b = 0, a = 1 }
	local border = owner[key]
	if not border then
		-- Own the border under the item frame, not under Blizzard's StatusBar/Icon.
		border = CreateFrame("Frame", nil, owner, "BackdropTemplate")
		owner[key] = border
	elseif border:GetParent() ~= owner then
		border:SetParent(owner)
	end
	if size <= 0 then border:Hide() return end
	border:SetFrameLevel((parent:GetFrameLevel() or 0) + 5)
	border:SetBackdrop(Skin.BuildBorderBackdrop(db))
	if NineSliceUtil and NineSliceUtil.DisableSharpening then NineSliceUtil.DisableSharpening(border) end
	border:ClearAllPoints()
	border:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	border:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
	border:SetBackdropBorderColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
	border:Show()
end

function Skin.ApplyBuffBarIconVisibility(frame, db, barHeight)
	local iconFrame = frame.Icon
	local showIcon = db.buffBarShowIcon ~= false
	if not iconFrame then return showIcon, nil end
	frame.GCDMShowBarIcon = showIcon
	-- Alpha, not a Show hook: Blizzard shows the icon from inside its bar
	-- refresh, and a hook there would taint it.
	if not showIcon then iconFrame:SetAlpha(0) return false, nil end
	iconFrame:SetAlpha(1)
	iconFrame:Show()
	local size = Pixel.Snap(barHeight)
	iconFrame:SetSize(size, size)
	iconFrame:ClearAllPoints()
	iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
	local iconTex = Skin.GetIconTexture(frame)
	if iconTex then
		if iconTex.GetNumMaskTextures then
			for i = iconTex:GetNumMaskTextures(), 1, -1 do
				local mask = iconTex:GetMaskTexture(i)
				if mask then iconTex:RemoveMaskTexture(mask) end
			end
		end
		iconTex:ClearAllPoints()
		iconTex:SetAllPoints(iconFrame)
		Pixel.DisableTextureSnap(iconTex)
		Skin.ApplyIconTexCoord(iconTex, db.iconZoom or (GCDM.CONST and GCDM.CONST.DEFAULT_ICON_ZOOM) or 0.08, size, size)
	end
	return true, iconFrame
end
