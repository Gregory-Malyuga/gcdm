local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

function Skin.BuffBarResolveWidth(db)
	if Skin.BarWidth and Skin.BarWidth.Resolve then
		return Skin.BarWidth.Resolve(db, "buffBarFollowEssential", "buffBarWidth")
	end
	local minW = Skin.BarWidth and Skin.BarWidth.Min() or ((GCDM.CONST and GCDM.CONST.MIN_BAR_WIDTH) or 200)
	if Skin.BarWidth and Skin.BarWidth.Clamp then return Skin.BarWidth.Clamp(db.buffBarWidth or minW) end
	return Pixel.Snap(tonumber(db.buffBarWidth) or minW)
end

function Skin.BuffBarResolveHeight(db)
	local C = GCDM.CONST or {}
	local h = db.buffBarHeight or C.DEFAULT_BUFF_BAR_HEIGHT or 16
	local minH = C.MIN_BUFF_BAR_HEIGHT or 4
	if type(h) ~= "number" or h < minH then h = minH end
	return Pixel.Snap(h)
end

local function ApplyTextVisibility(frame, bar, db)
	local showName = db.buffBarShowName ~= false
	local showDuration = db.buffBarShowDuration ~= false
	frame.GCDMShowBarName = showName
	frame.GCDMShowBarDuration = showDuration
	local function hook(hookKey, region, flagKey)
		if not region or frame[hookKey] then return end
		frame[hookKey] = true
		hooksecurefunc(region, "Show", function(self)
			if frame[flagKey] == false then self:SetAlpha(0) end
		end)
		hooksecurefunc(region, "SetShown", function(self, shown)
			if shown and frame[flagKey] == false then self:SetAlpha(0) end
		end)
	end
	hook("GCDMNameHooked", bar and bar.Name, "GCDMShowBarName")
	hook("GCDMDurationHooked", bar and bar.Duration, "GCDMShowBarDuration")
	if bar and bar.Name then bar.Name:SetAlpha(showName and 1 or 0) end
	if bar and bar.Duration then bar.Duration:SetAlpha(showDuration and 1 or 0) end
end

-- Visual only: HidePandemicStateFrame re-registers Blizzard's OnUpdate, and doing
-- that from addon code taints the secret comparisons inside it.
local function HideBuffBarPandemic(frame)
	local db = GCDM:GetDB()
	if not db or db.hidePandemicIndicator == false then return end
	if frame.PandemicIcon then
		frame.PandemicIcon:SetAlpha(0)
		frame.PandemicIcon:Hide()
	end
	if frame.ShowPandemicStateFrame and not frame.GCDMPandemicHooked then
		frame.GCDMPandemicHooked = true
		hooksecurefunc(frame, "ShowPandemicStateFrame", function(self)
			local profile = GCDM:GetDB()
			if not profile or profile.hidePandemicIndicator == false then return end
			if self.PandemicIcon then
				self.PandemicIcon:SetAlpha(0)
				self.PandemicIcon:Hide()
			end
		end)
	end
end

Skin.HideBuffBarPandemic = HideBuffBarPandemic

local StyleOneBar

local function GuardBarSize(frame, width, height)
	frame.GCDMWantW, frame.GCDMWantH = width, height
	if frame.GCDMSizeGuardHooked then return end
	frame.GCDMSizeGuardHooked = true
	local function onSizeTouch(self)
		if self.GCDMApplyingSize then return end
		if GCDM.ShouldDeferIconLayout and GCDM:ShouldDeferIconLayout() then return end
		local w, h = self.GCDMWantW, self.GCDMWantH
		if not w or not h then return end
		local epsilon = (GCDM.CONST and GCDM.CONST.SIZE_EPSILON) or 0.5
		if math.abs((self:GetWidth() or 0) - w) > epsilon or math.abs((self:GetHeight() or 0) - h) > epsilon then
			self.GCDMApplyingSize = true
			self:SetSize(w, h)
			self.GCDMApplyingSize = false
		end
		if self.GCDMSizeGuardPending then return end
		self.GCDMSizeGuardPending = true
		C_Timer.After(0, function()
			self.GCDMSizeGuardPending = false
			if GCDM.ShouldDeferIconLayout and GCDM:ShouldDeferIconLayout() then return end
			local db = GCDM:GetDB()
			if db and db.enabled and self.Bar and self.GCDMWantW and self.GCDMWantH then
				StyleOneBar(self, db, self.GCDMWantW, self.GCDMWantH)
			end
		end)
	end
	hooksecurefunc(frame, "SetWidth", onSizeTouch)
	hooksecurefunc(frame, "SetHeight", onSizeTouch)
	hooksecurefunc(frame, "SetSize", onSizeTouch)
end

StyleOneBar = function(frame, db, width, height)
	local bar = frame.Bar
	if not bar or not width or width < 8 or not height or height < 2 then return end
	local style = Skin.BuffBarResolveStyle(db)
	HideBuffBarPandemic(frame)
	Skin.HideBuffBarPipAndExtras(frame, style)
	Pixel.Update()
	GuardBarSize(frame, width, height)
	frame:SetSize(width, height)
	local showIcon, iconFrame = Skin.ApplyBuffBarIconVisibility(frame, db, height)
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
	if style == "solid" then Skin.ApplyBuffBarSolid(frame, bar, db) else Skin.ApplyBuffBarBlizzard(frame, bar) end
	ApplyTextVisibility(frame, bar, db)
	if Skin.ApplyBuffBarText then Skin.ApplyBuffBarText(frame, db) end
	if frame.GCDMBackdropBorder then frame.GCDMBackdropBorder:Hide() end
	Skin.ApplyBuffBarOwnedBorder(frame, "GCDMBarBorder", bar, db)
	Skin.ApplyBuffBarOwnedBorder(frame, "GCDMBarIconBorder", showIcon and iconFrame or nil, db)
end

Skin.StyleOneBuffBar = StyleOneBar

function Skin.ApplyBuffBars()
	local last = { bars = 0, shown = 0, width = -1, height = -1, err = nil }
	GCDM._buffBarLastApply = last
	local ok, err = pcall(function()
		Pixel.Update()
		local db = GCDM:GetDB()
		if not db or not db.enabled or db.buffBarEnabled == false then last.err = "disabled" return end
		local viewer = GCDM.ViewerRegistry:BuffBar()
		if not viewer then last.err = "no-viewer" return end
		local inCombat = InCombatLockdown and InCombatLockdown()
		local bars = Skin.CollectBarFrames(viewer)
		last.bars = #bars
		local height = Skin.BuffBarResolveHeight(db)
		local spacing = Pixel.Snap(db.buffBarSpacing or 0)
		local width = Skin.BuffBarResolveWidth(db)
		last.width, last.height = width, height
		local shown = {}
		for i = 1, #bars do
			local frame = bars[i]
			if frame and frame.Bar then
				if not frame.GCDMShowHooked then
					frame.GCDMShowHooked = true
					frame:HookScript("OnShow", function()
						if Skin.QueueBuffBarRelayout then Skin.QueueBuffBarRelayout() end
					end)
				end
				StyleOneBar(frame, db, width, height)
				local active = false
				if frame.IsActive then
					local okA, a = pcall(frame.IsActive, frame)
					active = okA and a == true
				end
				local shownOk, isShown = pcall(frame.IsShown, frame)
				if (shownOk and isShown) or active then shown[#shown + 1] = frame end
			end
		end
		table.sort(shown, function(a, b)
			local ai = type(a.layoutIndex) == "number" and a.layoutIndex or 0
			local bi = type(b.layoutIndex) == "number" and b.layoutIndex or 0
			return ai < bi
		end)
		last.shown = #shown
		local count = #shown
		local containerH = count > 0 and ((count * height) + ((count - 1) * spacing)) or height
		if viewer.SetAlpha then pcall(viewer.SetAlpha, viewer, 1) end
		pcall(viewer.SetSize, viewer, width, Pixel.Snap(containerH))
		for i = 1, count do
			local frame = shown[i]
			local y = -((i - 1) * (height + spacing))
			if not inCombat then
				pcall(function() frame:ClearAllPoints() frame:SetPoint("TOPLEFT", viewer, "TOPLEFT", 0, y) end)
			else
				pcall(frame.SetPoint, frame, "TOPLEFT", viewer, "TOPLEFT", 0, y)
				last.err = "combat-skin"
			end
			pcall(frame.SetAlpha, frame, 1)
			StyleOneBar(frame, db, width, height)
		end
	end)
	if not ok then last.err = tostring(err) end
end
