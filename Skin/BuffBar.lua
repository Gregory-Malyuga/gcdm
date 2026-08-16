local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

local BLIZZARD_BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local relayoutQueued = false
local mixinsHooked = false

-- Taint-safe BuffBar skin:
-- Never hook RefreshData / aura paths, never write Blizzard baseBarWidth,
-- never sync-mutate frames inside Blizzard call stacks (only C_Timer.After).

local function LayoutIndexOf(frame)
	local idx = frame and frame.layoutIndex
	if type(idx) == "number" then
		return idx
	end
	return 0
end

local function SortBars(frames)
	table.sort(frames, function(a, b)
		return LayoutIndexOf(a) < LayoutIndexOf(b)
	end)
end

local function FormulaEssentialWidth(db)
	local size = db.sizeEssential or { w = 46, h = 40 }
	local iw = Pixel.Snap(size.w or 46)
	local spacing = Pixel.Snap(db.spacing or 0)
	if Pixel.IsSnapEnabled() and (db.spacing or 0) > 0 and spacing < Pixel.GetSize() then
		spacing = Pixel.GetSize()
	end
	local maxRow = db.maxIconsPerRow or 7
	if maxRow < 1 then
		maxRow = 1
	end
	return (maxRow * iw) + ((maxRow - 1) * spacing)
end

local function ResolveBarWidth(db)
	local width = db.buffBarWidth or 0
	if width > 0 then
		return Pixel.Snap(width)
	end
	-- Full configured Essential row (maxIconsPerRow * size). Do not use GetWidth /
	-- live count — Blizzard SetBarWidth(220) and partial layouts made the bar short.
	local formula = FormulaEssentialWidth(db)
	local laid = Skin.EssentialLayoutWidth
	if type(laid) == "number" and laid >= formula then
		return Pixel.Snap(laid)
	end
	return formula
end

local function ResolveBarStyle(db)
	local s = db and db.buffBarStyle
	if s == nil or s == "solid" or s == "SharedMedia" or s == "sharedmedia" then
		return "solid"
	end
	return s
end

local function ResolveBarHeight(db)
	local h = db.buffBarHeight or 16
	if type(h) ~= "number" or h < 4 then
		h = 4
	end
	return Pixel.Snap(h)
end

local function SyncSkinBarValues(frame, bar)
	local skin = frame.GCDMSkinBar
	if not skin or not bar then
		return
	end
	local minV, maxV = 0, 1
	if bar.GetMinMaxValues then
		minV, maxV = bar:GetMinMaxValues()
	end
	if type(minV) ~= "number" then
		minV = 0
	end
	if type(maxV) ~= "number" then
		maxV = 1
	end
	skin:SetMinMaxValues(minV, maxV)
	local value = 0
	if bar.GetValue then
		value = bar:GetValue() or 0
	end
	if type(value) ~= "number" then
		value = 0
	end
	if Skin.SmoothBarSetValue then
		Skin.SmoothBarSetValue(skin, value, Skin.IsBarSmoothEnabled and Skin.IsBarSmoothEnabled(db))
	else
		skin:SetValue(value)
	end
end

local function HideBlizzardBarArt(bar)
	if not bar then
		return
	end
	local sbTex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	if sbTex and sbTex.SetAlpha then
		sbTex:SetAlpha(0)
	end
	if bar.BarBG then
		bar.BarBG:SetAlpha(0)
	end
	if bar.Pip then
		bar.Pip:SetAlpha(0)
	end
	if bar.SetAlpha then
		bar:SetAlpha(1)
	end
end

local function ApplySolidBar(frame, bar, db)
	local tex = Skin.FetchStatusBarTexture(db.buffBarTexture or "Solid") or GCDM.CONST.TEX_WHITE8X8
	local bgTexPath = Skin.FetchStatusBarTexture(db.buffBarBackgroundTexture or db.buffBarTexture or "Solid")
		or GCDM.CONST.TEX_WHITE8X8
	local fill = db.buffBarColor or { r = 0.4, g = 0.6, b = 0.9, a = 1 }
	local bg = db.buffBarBackgroundColor or { r = 0.1, g = 0.1, b = 0.1, a = 0.8 }
	local fr, fg, fb, fa = fill.r or 0.4, fill.g or 0.6, fill.b or 0.9, fill.a or 1

	-- Don't fight Blizzard atlas fill — hide it and draw our own StatusBar.
	HideBlizzardBarArt(bar)

	local skin = frame.GCDMSkinBar
	if not skin then
		skin = CreateFrame("StatusBar", nil, bar)
		local bl = bar:GetFrameLevel() or 0
		skin:SetFrameLevel(math.max(1, bl - 1))
		frame.GCDMSkinBar = skin
		frame.GCDMSkinBarBG = skin:CreateTexture(nil, "BACKGROUND", nil, -1)
		frame.GCDMSkinBarBG:SetAllPoints(skin)
	end

	skin:ClearAllPoints()
	skin:SetAllPoints(bar)
	skin:SetStatusBarTexture(tex)
	local skinTex = skin:GetStatusBarTexture()
	if skinTex then
		Pixel.DisableTextureSnap(skinTex)
		if skinTex.SetVertexColor then
			skinTex:SetVertexColor(fr, fg, fb, fa)
		end
	end
	skin:SetStatusBarColor(fr, fg, fb, fa)
	skin:SetOrientation("HORIZONTAL")
	if skin.SetReverseFill then
		skin:SetReverseFill(false)
	end

	local bgTex = frame.GCDMSkinBarBG
	bgTex:SetTexture(bgTexPath)
	bgTex:SetVertexColor(bg.r or 0.1, bg.g or 0.1, bg.b or 0.1, bg.a or 0.8)
	bgTex:Show()
	Pixel.DisableTextureSnap(bgTex)

	SyncSkinBarValues(frame, bar)
	skin:Show()
	skin:SetAlpha(1)

	if not bar.GCDMValueHooked then
		bar.GCDMValueHooked = true
		hooksecurefunc(bar, "SetValue", function(self)
			local parent = self:GetParent()
			if parent and parent.GCDMSkinBar and parent.GCDMSkinBar:IsShown() then
				SyncSkinBarValues(parent, self)
			end
		end)
		hooksecurefunc(bar, "SetMinMaxValues", function(self)
			local parent = self:GetParent()
			if parent and parent.GCDMSkinBar and parent.GCDMSkinBar:IsShown() then
				SyncSkinBarValues(parent, self)
			end
		end)
	end

	if frame.GCDMBarBackground then
		frame.GCDMBarBackground:Hide()
	end
end

local function SuppressPip(pip)
	if not pip or pip.GCDMPipGuarded then
		return
	end
	pip.GCDMPipGuarded = true
	local function lockAlpha(self)
		if self.GCDMPipLock then
			return
		end
		local db = GCDM:GetDB()
		if not db or (ResolveBarStyle(db)) ~= "solid" then
			return
		end
		self.GCDMPipLock = true
		self:SetAlpha(0)
		self.GCDMPipLock = false
	end
	hooksecurefunc(pip, "Show", lockAlpha)
	hooksecurefunc(pip, "SetShown", function(self, shown)
		if shown then
			lockAlpha(self)
		end
	end)
	hooksecurefunc(pip, "SetAlpha", function(self, alpha)
		if self.GCDMPipLock then
			return
		end
		if type(alpha) == "number" and alpha > 0 then
			lockAlpha(self)
		end
	end)
end

local function HidePipAndExtras(frame, style)
	if frame.DebuffBorder and frame.DebuffBorder.Hide then
		frame.DebuffBorder:Hide()
	end
	if style ~= "solid" then
		return
	end
	local bar = frame.Bar
	if not bar then
		return
	end
	if bar.BarBG then
		bar.BarBG:SetAlpha(0)
	end
	if bar.Pip then
		SuppressPip(bar.Pip)
		bar.Pip:SetAlpha(0)
	end
end

local function InstallTextHideHook(frame, hookKey, region, flagKey)
	if not region or frame[hookKey] then
		return
	end
	frame[hookKey] = true
	hooksecurefunc(region, "Show", function(self)
		if frame[flagKey] ~= false then
			return
		end
		self:SetAlpha(0)
	end)
	hooksecurefunc(region, "SetShown", function(self, shown)
		if not shown or frame[flagKey] ~= false then
			return
		end
		self:SetAlpha(0)
	end)
end

local function ApplyTextVisibility(frame, bar, db)
	local showName = db.buffBarShowName ~= false
	local showDuration = db.buffBarShowDuration ~= false
	frame.GCDMShowBarName = showName
	frame.GCDMShowBarDuration = showDuration
	local nameText = bar and bar.Name
	local durationText = bar and bar.Duration
	InstallTextHideHook(frame, "GCDMNameHooked", nameText, "GCDMShowBarName")
	InstallTextHideHook(frame, "GCDMDurationHooked", durationText, "GCDMShowBarDuration")
	if nameText then
		nameText:SetAlpha(showName and 1 or 0)
	end
	if durationText then
		durationText:SetAlpha(showDuration and 1 or 0)
	end
end

local function StripBuffBarIconMask(iconTex)
	if not iconTex or not iconTex.GetNumMaskTextures then
		return
	end
	for i = iconTex:GetNumMaskTextures(), 1, -1 do
		local mask = iconTex:GetMaskTexture(i)
		if mask then
			iconTex:RemoveMaskTexture(mask)
		end
	end
end

local function ApplyIconVisibility(frame, db, barHeight)
	local iconFrame = frame.Icon
	local showIcon = db.buffBarShowIcon ~= false
	if not iconFrame then
		return showIcon, nil
	end
	frame.GCDMShowBarIcon = showIcon
	if not iconFrame.GCDMIconHideHooked then
		iconFrame.GCDMIconHideHooked = true
		hooksecurefunc(iconFrame, "Show", function(self)
			if frame.GCDMShowBarIcon ~= false then
				self:SetAlpha(1)
				return
			end
			self:SetAlpha(0)
		end)
	end
	if not showIcon then
		iconFrame:SetAlpha(0)
		return false, nil
	end
	iconFrame:SetAlpha(1)
	iconFrame:Show()
	local size = Pixel.Snap(barHeight)
	iconFrame:SetSize(size, size)
	iconFrame:ClearAllPoints()
	iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
	local iconTex = Skin.GetIconTexture(frame)
	if iconTex then
		StripBuffBarIconMask(iconTex)
		iconTex:ClearAllPoints()
		iconTex:SetAllPoints(iconFrame)
		Pixel.DisableTextureSnap(iconTex)
		Skin.ApplyIconTexCoord(iconTex, db.iconZoom or 0.08, size, size)
	end
	return true, iconFrame
end

local function ApplyBlizzardBar(frame, bar)
	if frame.GCDMSkinBar then
		frame.GCDMSkinBar:Hide()
	end
	if frame.GCDMBarBackground then
		frame.GCDMBarBackground:Hide()
	end
	local sbTex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	if sbTex and sbTex.SetAlpha then
		sbTex:SetAlpha(1)
	end
	if bar.GetStatusBarTexture and not bar:GetStatusBarTexture() then
		bar:SetStatusBarTexture(BLIZZARD_BAR_TEXTURE)
	end
	if bar.BarBG then
		bar.BarBG:SetAlpha(1)
		bar.BarBG:Show()
	end
end

local function EnsureOwnedBorder(owner, key, parent)
	local border = owner[key]
	if border then
		if border:GetParent() ~= parent then
			border:SetParent(parent)
		end
		return border
	end
	border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	owner[key] = border
	return border
end

local function ApplyOwnedBorder(owner, key, parent, db)
	if not parent then
		local existing = owner[key]
		if existing then
			existing:Hide()
		end
		return
	end
	local size = db.borderSize or 1
	local c = db.borderColor or { r = 0, g = 0, b = 0, a = 1 }
	local border = EnsureOwnedBorder(owner, key, parent)
	if size <= 0 then
		border:Hide()
		return
	end
	border:SetFrameLevel((parent:GetFrameLevel() or 0) + 5)
	border:SetBackdrop(Skin.BuildBorderBackdrop(db))
	if NineSliceUtil and NineSliceUtil.DisableSharpening then
		NineSliceUtil.DisableSharpening(border)
	end
	border:ClearAllPoints()
	border:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	border:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
	border:SetBackdropBorderColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
	border:Show()
end

local StyleOneBar

local function GuardBarSize(frame, width, height)
	frame.GCDMWantW = width
	frame.GCDMWantH = height
	if frame.GCDMSizeGuardHooked then
		return
	end
	frame.GCDMSizeGuardHooked = true

	local function onSizeTouch(self)
		if self.GCDMApplyingSize then
			return
		end
		local w, h = self.GCDMWantW, self.GCDMWantH
		if not w or not h then
			return
		end
		local cw = self:GetWidth() or 0
		local ch = self:GetHeight() or 0
		if math.abs(cw - w) > 0.5 or math.abs(ch - h) > 0.5 then
			self.GCDMApplyingSize = true
			self:SetSize(w, h)
			self.GCDMApplyingSize = false
		end
		-- One deferred restyle pass (Blizzard SetBarContent after SetBarWidth).
		if self.GCDMSizeGuardPending then
			return
		end
		self.GCDMSizeGuardPending = true
		C_Timer.After(0, function()
			self.GCDMSizeGuardPending = false
			local db = GCDM:GetDB()
			if not db or not db.enabled or not self.Bar then
				return
			end
			local wantW, wantH = self.GCDMWantW, self.GCDMWantH
			if wantW and wantH then
				StyleOneBar(self, db, wantW, wantH)
			end
		end)
	end

	hooksecurefunc(frame, "SetWidth", onSizeTouch)
	hooksecurefunc(frame, "SetHeight", onSizeTouch)
	hooksecurefunc(frame, "SetSize", onSizeTouch)
end

StyleOneBar = function(frame, db, width, height)
	local bar = frame.Bar
	if not bar or not width or width < 8 or not height or height < 2 then
		return
	end

	local style = ResolveBarStyle(db)
	HidePipAndExtras(frame, style)
	Pixel.Update()

	GuardBarSize(frame, width, height)
	frame:SetSize(width, height)

	local showIcon, iconFrame = ApplyIconVisibility(frame, db, height)
	local gap = Pixel.Snap(db.buffBarIconGap or 0)

	bar:ClearAllPoints()
	bar:SetHeight(height)
	if showIcon and iconFrame then
		bar:SetPoint("LEFT", iconFrame, "RIGHT", gap, 0)
		bar:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
		bar:SetPoint("TOP", frame, "TOP", 0, 0)
		bar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
	else
		bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
		bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	end

	if style == "solid" then
		ApplySolidBar(frame, bar, db)
	else
		ApplyBlizzardBar(frame, bar)
	end
	ApplyTextVisibility(frame, bar, db)
	if Skin.ApplyBuffBarText then
		Skin.ApplyBuffBarText(frame, db)
	end

	if frame.GCDMBackdropBorder then
		frame.GCDMBackdropBorder:Hide()
	end
	ApplyOwnedBorder(frame, "GCDMBarBorder", bar, db)
	if showIcon and iconFrame then
		ApplyOwnedBorder(frame, "GCDMBarIconBorder", iconFrame, db)
	else
		ApplyOwnedBorder(frame, "GCDMBarIconBorder", nil, db)
	end
end

local function ApplyBuffBars()
	local last = { bars = 0, shown = 0, width = -1, height = -1, err = nil }
	GCDM._buffBarLastApply = last

	local ok, err = pcall(function()
		Pixel.Update()
		local db = GCDM:GetDB()
		if not db or not db.enabled or db.buffBarEnabled == false then
			last.err = "disabled"
			return
		end
		if GCDM.IsEditModeActive and GCDM:IsEditModeActive() then
			last.err = "editmode"
			return
		end

		local viewer = GCDM.ViewerRegistry:BuffBar()
		if not viewer then
			last.err = "no-viewer"
			return
		end

		local inCombat = InCombatLockdown and InCombatLockdown()
		local bars = Skin.CollectBarFrames(viewer)
		last.bars = #bars
		local height = ResolveBarHeight(db)
		local spacing = Pixel.Snap(db.buffBarSpacing or 0)
		local width = ResolveBarWidth(db)
		last.width = width
		last.height = height

		-- Always skin every pooled bar (even while hidden). Dump showed shown=0 →
		-- StyleOneBar never ran → stuck at Blizzard 220*scale=330, no GCDMSkinBar.
		local shown = {}
		for i = 1, #bars do
			local frame = bars[i]
			if frame and frame.Bar then
				if not frame.GCDMShowHooked then
					frame.GCDMShowHooked = true
					frame:HookScript("OnShow", function()
						if Skin.QueueBuffBarRelayout then
							Skin.QueueBuffBarRelayout()
						end
					end)
				end
				StyleOneBar(frame, db, width, height)
				local active = false
				if frame.IsActive then
					local okA, a = pcall(frame.IsActive, frame)
					active = okA and a == true
				end
				local shownOk, isShown = pcall(frame.IsShown, frame)
				if (shownOk and isShown) or active then
					shown[#shown + 1] = frame
				end
			end
		end
		SortBars(shown)
		last.shown = #shown

		local count = #shown
		local containerH = height
		if count > 0 then
			containerH = (count * height) + ((count - 1) * spacing)
		else
			containerH = height
		end
		-- Keep viewer visible; never write baseBarWidth (taints CDM aura paths).
		if viewer.SetAlpha then
			pcall(viewer.SetAlpha, viewer, 1)
		end

		-- Geometry: avoid ClearAllPoints in combat (orphan frames if SetPoint is blocked).
		if not inCombat then
			pcall(viewer.SetSize, viewer, width, Pixel.Snap(containerH))
			for i = 1, count do
				local frame = shown[i]
				local y = -((i - 1) * (height + spacing))
				pcall(function()
					frame:ClearAllPoints()
					frame:SetPoint("TOPLEFT", viewer, "TOPLEFT", 0, y)
				end)
				pcall(frame.SetAlpha, frame, 1)
				StyleOneBar(frame, db, width, height)
			end
		else
			pcall(viewer.SetSize, viewer, width, Pixel.Snap(containerH))
			for i = 1, count do
				local frame = shown[i]
				local y = -((i - 1) * (height + spacing))
				-- Re-assert without clearing first.
				pcall(frame.SetPoint, frame, "TOPLEFT", viewer, "TOPLEFT", 0, y)
				pcall(frame.SetAlpha, frame, 1)
				StyleOneBar(frame, db, width, height)
			end
			last.err = "combat-skin"
		end
	end)

	if not ok then
		last.err = tostring(err)
	end
end

-- Always defer; never mutate CDM frames inside Blizzard mixin call stacks.
-- Dirty-flag so SetBarWidth during an in-flight queue is not dropped (was sticking at ~220).
local relayoutDirty = false

local function QueueRelayout()
	relayoutDirty = true
	if relayoutQueued then
		return
	end
	relayoutQueued = true
	local function pump()
		if GCDM.IsEditModeActive and GCDM:IsEditModeActive() then
			relayoutQueued = false
			relayoutDirty = false
			return
		end
		relayoutDirty = false
		ApplyBuffBars()
		if relayoutDirty then
			C_Timer.After(0, pump)
			return
		end
		-- Trailing pass: Blizzard SetBarWidth often lands after the first After(0).
		C_Timer.After(0, function()
			if relayoutDirty then
				pump()
				return
			end
			ApplyBuffBars()
			if relayoutDirty then
				pump()
				return
			end
			relayoutQueued = false
		end)
	end
	C_Timer.After(0, pump)
end

Skin.QueueBuffBarRelayout = QueueRelayout

local function HookBuffBarMixins()
	if mixinsHooked then
		return
	end
	mixinsHooked = true
	-- Deferred only — never Restyle sync inside these hooks (taints aura RefreshData).
	if CooldownViewerBuffBarItemMixin then
		if CooldownViewerBuffBarItemMixin.SetBarContent then
			hooksecurefunc(CooldownViewerBuffBarItemMixin, "SetBarContent", QueueRelayout)
		end
		if CooldownViewerBuffBarItemMixin.SetBarWidth then
			hooksecurefunc(CooldownViewerBuffBarItemMixin, "SetBarWidth", QueueRelayout)
		end
		if CooldownViewerBuffBarItemMixin.SetTimerShown then
			hooksecurefunc(CooldownViewerBuffBarItemMixin, "SetTimerShown", QueueRelayout)
		end
		if CooldownViewerBuffBarItemMixin.OnActiveStateChanged then
			hooksecurefunc(CooldownViewerBuffBarItemMixin, "OnActiveStateChanged", QueueRelayout)
		end
		if CooldownViewerBuffBarItemMixin.RefreshCooldownInfo then
			hooksecurefunc(CooldownViewerBuffBarItemMixin, "RefreshCooldownInfo", function(self)
				if self.GCDMVisualPending then
					return
				end
				self.GCDMVisualPending = true
				C_Timer.After(0, function()
					self.GCDMVisualPending = false
					local db = GCDM:GetDB()
					if not db or not db.enabled or not self.Bar then
						return
					end
					local w = self.GCDMWantW or ResolveBarWidth(db)
					local h = self.GCDMWantH or ResolveBarHeight(db)
					StyleOneBar(self, db, w, h)
				end)
			end)
		end
	end
	if BuffBarCooldownViewerMixin then
		if BuffBarCooldownViewerMixin.SetBarContent then
			hooksecurefunc(BuffBarCooldownViewerMixin, "SetBarContent", QueueRelayout)
		end
		if BuffBarCooldownViewerMixin.SetBarWidthScale then
			hooksecurefunc(BuffBarCooldownViewerMixin, "SetBarWidthScale", QueueRelayout)
		end
		if BuffBarCooldownViewerMixin.SetTimerShown then
			hooksecurefunc(BuffBarCooldownViewerMixin, "SetTimerShown", QueueRelayout)
		end
	end
end

local function HookBuffBarViewer(viewer)
	if not viewer or viewer.GCDMBuffBarHooked then
		return
	end
	viewer.GCDMBuffBarHooked = true
	if viewer.RefreshLayout then
		hooksecurefunc(viewer, "RefreshLayout", QueueRelayout)
	end
	pcall(function()
		hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, itemFrame)
			if itemFrame and Skin.IsBuffBarItem(itemFrame) then
				QueueRelayout()
			end
		end)
	end)
end

GCDM:RegisterRefreshCallback("Skin.BuffBar", function()
	HookBuffBarMixins()
	local viewer = GCDM.ViewerRegistry:BuffBar()
	HookBuffBarViewer(viewer)
	QueueRelayout()
end, 45, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.LAYOUT,
	GCDM.CONST.REFRESH.STYLE,
})