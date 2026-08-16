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
	-- Blizzard's Show()/SetShown() leave alpha alone, so hiding a label by alpha
	-- sticks without a hook that would run inside Blizzard's refresh.
	if bar and bar.Name then bar.Name:SetAlpha(showName and 1 or 0) end
	if bar and bar.Duration then bar.Duration:SetAlpha(showDuration and 1 or 0) end
end

-- Visual only. Never call HidePandemicStateFrame: it ends in
-- RefreshOnUpdateRegistration, which re-registers Blizzard's OnUpdate under our
-- taint. Alpha survives Blizzard's own Show(), so zeroing it is enough and needs
-- no hook running inside Blizzard's refresh.
local function HideBuffBarPandemic(frame)
	local db = GCDM:GetDB()
	if not db or db.hidePandemicIndicator == false then return end
	if frame.PandemicIcon then
		frame.PandemicIcon:SetAlpha(0)
		frame.PandemicIcon:Hide()
	end
end

Skin.HideBuffBarPandemic = HideBuffBarPandemic

local StyleOneBar

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

local function PlainBool(ok, value)
	if not ok then
		return nil
	end
	if issecretvalue and issecretvalue(value) then
		return nil
	end
	if canaccessvalue and not canaccessvalue(value) then
		return nil
	end
	if value == true then
		return true
	end
	if value == false then
		return false
	end
	return nil
end

local function LayoutIndexOf(frame)
	return PlainNumber(frame and frame.layoutIndex) or 0
end

local function IsBarShownOrActive(frame)
	if frame.IsActive then
		local active = PlainBool(pcall(frame.IsActive, frame))
		if active == true then
			return true
		end
	end
	local shown = PlainBool(pcall(frame.IsShown, frame))
	return shown == true
end

-- Bar size used to be guarded by SetWidth/SetHeight/SetSize hooks that fought
-- Blizzard inside its own layout pass. The size is re-applied by the next
-- CDMWatch pass instead.
local function RememberBarSize(frame, width, height)
	frame.GCDMWantW, frame.GCDMWantH = width, height
end

StyleOneBar = function(frame, db, width, height)
	local bar = frame.Bar
	if not bar or not width or width < 8 or not height or height < 2 then return end
	local style = Skin.BuffBarResolveStyle(db)
	HideBuffBarPandemic(frame)
	Skin.HideBuffBarPipAndExtras(frame, style)
	Pixel.Update()
	RememberBarSize(frame, width, height)
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

-- Keep BuffBarCooldownViewer on Essential (a Blizzard frame), never on GCDM_PowerBarHost.
-- Anchoring the viewer to an addon frame made Blizzard's OnUnitAura continue tainted.
function Skin.PlaceBuffBarViewer(db)
	db = db or (GCDM.GetDB and GCDM:GetDB())
	if not db or not db.enabled or db.buffBarEnabled == false then
		return
	end
	if db.buffBarFollowEssential == false then
		return
	end
	local cfg = db.viewerPos and db.viewerPos.buffBar
	if cfg and cfg.enabled then
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		return
	end
	if GCDM.ShouldDeferCDMLayout and GCDM:ShouldDeferCDMLayout() then
		return
	end
	local registry = GCDM.ViewerRegistry
	local viewer = registry and registry:BuffBar()
	local essential = registry and registry:Essential()
	if not viewer or not essential then
		return
	end
	local lift = 1
	if db.powerBarEnabled ~= false and db.powerBarFollowEssential ~= false then
		local hostH = PlainNumber(Skin.PowerBarHostHeight) or 0
		if hostH > 0 then
			lift = Pixel.Snap(hostH) + 1
		end
	end
	pcall(function()
		viewer:ClearAllPoints()
		viewer:SetPoint("BOTTOMLEFT", essential, "TOPLEFT", 0, lift)
		viewer:SetPoint("BOTTOMRIGHT", essential, "TOPRIGHT", 0, lift)
	end)
end

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
				StyleOneBar(frame, db, width, height)
				if IsBarShownOrActive(frame) then
					shown[#shown + 1] = frame
				end
			end
		end
		table.sort(shown, function(a, b)
			return LayoutIndexOf(a) < LayoutIndexOf(b)
		end)
		last.shown = #shown
		local count = #shown
		local containerH = count > 0 and ((count * height) + ((count - 1) * spacing)) or height
		if viewer.SetAlpha then pcall(viewer.SetAlpha, viewer, 1) end
		pcall(viewer.SetSize, viewer, width, Pixel.Snap(containerH))
		Skin.PlaceBuffBarViewer(db)
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
