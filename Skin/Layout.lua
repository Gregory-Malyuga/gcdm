local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

local relayoutQueued = false
local combatLayoutPending = false
local combatWatcher
local applyingLayout = false
local buffCenterQueued = false
local QueuePostBlizzardLayout
local LayoutBuffIconsCentered
local QueueBuffCenterLayout
local EnsureIconLifecycleHooks

local function InCombat()
	return InCombatLockdown and InCombatLockdown()
end

local function EnsureCombatWatcher()
	if combatWatcher then
		return
	end
	combatWatcher = CreateFrame("Frame")
	combatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
	combatWatcher:SetScript("OnEvent", function()
		if combatLayoutPending then
			combatLayoutPending = false
			QueuePostBlizzardLayout()
		end
	end)
end

local function MarkCombatLayoutPending()
	combatLayoutPending = true
	EnsureCombatWatcher()
end

--- Viewer SetSize is protected in combat (ADDON_ACTION_BLOCKED).
local function SafeViewerSetSize(viewer, w, h)
	if not viewer or not viewer.SetSize then
		return false
	end
	if InCombat() then
		MarkCombatLayoutPending()
		return false
	end
	local ok = pcall(viewer.SetSize, viewer, w, h)
	if not ok then
		MarkCombatLayoutPending()
	end
	return ok
end

local function RowWidth(count, itemW, gap)
	if count <= 0 then
		return 0
	end
	return (count * itemW) + ((count - 1) * gap)
end

local function CenteredX(col, itemW, gap, containerW, rowW)
	local startX = (containerW - rowW) * 0.5
	return startX + (col * (itemW + gap))
end

local function SnapGap(value)
	local v = tonumber(value) or 0
	if v <= 0 then
		return 0
	end
	if not Pixel.IsSnapEnabled() then
		return v
	end
	local snapped = Pixel.Snap(v)
	local px = Pixel.GetSize()
	if snapped < px then
		snapped = px
	end
	return snapped
end

local function LayoutIndexOf(frame)
	local idx = frame and frame.layoutIndex
	if type(idx) == "number" then
		return idx
	end
	return 0
end

local function SortIconsStable(icons)
	table.sort(icons, function(a, b)
		local ai = LayoutIndexOf(a)
		local bi = LayoutIndexOf(b)
		if ai ~= bi then
			return ai < bi
		end
		local ay = a:GetTop() or 0
		local by = b:GetTop() or 0
		if math.abs(ay - by) > 1 then
			return ay > by
		end
		return (a:GetLeft() or 0) < (b:GetLeft() or 0)
	end)
end

local function HasDrawableIcon(frame)
	local icon = Skin.GetIconTexture(frame)
	if not icon then
		return false
	end
	local ok, tex = pcall(function()
		return icon:GetTexture()
	end)
	if ok and tex ~= nil then
		if canaccessvalue and not canaccessvalue(tex) then
			return true
		end
		local okCmp, empty = pcall(function()
			return tex == "" or tex == 0
		end)
		if not okCmp then
			return true
		end
		if not empty then
			return true
		end
	end
	if icon.GetAtlas then
		local okA, atlas = pcall(icon.GetAtlas, icon)
		if okA and atlas and atlas ~= "" then
			if canaccessvalue and not canaccessvalue(atlas) then
				return true
			end
			return true
		end
	end
	return false
end

local function IsFrameShownSafe(frame)
	if not frame or not frame.IsShown then
		return false
	end
	local ok, shown = pcall(frame.IsShown, frame)
	if not ok then
		return false
	end
	if issecretvalue and issecretvalue(shown) then
		return nil
	end
	if canaccessvalue and not canaccessvalue(shown) then
		return nil
	end
	return shown and true or false
end

local function IsFrameActiveSafe(frame)
	if not frame or not frame.IsActive then
		return nil
	end
	local ok, active = pcall(frame.IsActive, frame)
	if not ok then
		return nil
	end
	if issecretvalue and issecretvalue(active) then
		return nil
	end
	if canaccessvalue and not canaccessvalue(active) then
		return nil
	end
	if active == true then
		return true
	end
	if active == false then
		return false
	end
	return nil
end

--- Prefer IsActive; else shown+drawable (secret shown → drawable only).
local function IsIconLayoutActive(frame)
	local blizzActive = IsFrameActiveSafe(frame)
	if blizzActive == true then
		return true
	end
	local okDraw, drawable = pcall(HasDrawableIcon, frame)
	local shown = IsFrameShownSafe(frame)
	if shown == nil then
		return okDraw and drawable and true or false
	end
	if blizzActive == false and not shown then
		return false
	end
	return shown and okDraw and drawable and true or false
end

local function IsBuffViewer(viewer)
	local name = viewer and viewer.GetName and viewer:GetName()
	return name == GCDM.CONST.VIEWERS.BUFF
end

local function ViewerOf(frame)
	if not frame then
		return nil
	end
	if frame.viewerFrame then
		return frame.viewerFrame
	end
	if frame.GetParent then
		return frame:GetParent()
	end
	return nil
end

local function ShouldDeferLayout()
	return GCDM.ShouldDeferCDMLayout and GCDM:ShouldDeferCDMLayout()
end

-- Blizzard RefreshLayout re-SetPoints icons; snap back to our place-anchor.
-- Buff: also snap in combat (Blizzard left-aligns the full pool including empties).
local function InstallAnchorSnapBack(frame)
	if frame.GCDMSnapHooked then
		return
	end
	frame.GCDMSnapHooked = true
	hooksecurefunc(frame, "SetPoint", function(self)
		if self.GCDMParked or self.GCDMApplyingAnchor then
			return
		end
		local isBuff = IsBuffViewer(ViewerOf(self))
		if InCombat() and not isBuff then
			return
		end
		if ShouldDeferLayout() then
			self.GCDMAnchor = nil
			return
		end
		local a = self.GCDMAnchor
		if not a then
			return
		end
		self.GCDMApplyingAnchor = true
		pcall(function()
			if not InCombat() then
				self:ClearAllPoints()
			end
			self:SetPoint(a[1], a[2], a[3], a[4], a[5])
		end)
		self.GCDMApplyingAnchor = false
	end)
end

local function PlaceIcon(frame, viewer, x, y, w, h, row, opts)
	opts = opts or {}
	EnsureIconLifecycleHooks(frame)
	frame.GCDMParked = false
	frame.GCDMRow = row
	pcall(frame.SetAlpha, frame, 1)
	if not opts.keepSize and w and h then
		pcall(frame.SetSize, frame, w, h)
	end
	frame.GCDMApplyingAnchor = true
	pcall(function()
		if not InCombat() then
			frame:ClearAllPoints()
		end
		frame:SetPoint("TOPLEFT", viewer, "TOPLEFT", x, y)
	end)
	frame.GCDMApplyingAnchor = false
	frame.GCDMAnchor = { "TOPLEFT", viewer, "TOPLEFT", x, y }
	InstallAnchorSnapBack(frame)
end

EnsureIconLifecycleHooks = function(frame)
	if not frame or frame.GCDMIconLifeHooked then
		return
	end
	frame.GCDMIconLifeHooked = true
	frame:HookScript("OnShow", function(self)
		local viewer = ViewerOf(self)
		self.GCDMParked = false
		pcall(self.SetAlpha, self, 1)
		if IsBuffViewer(viewer) then
			QueueBuffCenterLayout(viewer)
			return
		end
		self.GCDMAnchor = nil
		QueuePostBlizzardLayout()
	end)
	frame:HookScript("OnHide", function(self)
		local viewer = ViewerOf(self)
		if IsBuffViewer(viewer) then
			self.GCDMParked = false
			QueueBuffCenterLayout(viewer)
			return
		end
		self.GCDMAnchor = nil
		QueuePostBlizzardLayout()
	end)
end

local function ParkEmptyIcon(frame, viewer)
	if not frame then
		return
	end
	EnsureIconLifecycleHooks(frame)
	if IsBuffViewer(viewer) then
		frame.GCDMParked = false
		frame.GCDMAnchor = nil
		return
	end
	InstallAnchorSnapBack(frame)
	frame.GCDMParked = true
	if InCombat() then
		frame.GCDMAnchor = nil
		pcall(frame.SetAlpha, frame, 0)
		return
	end
	frame.GCDMAnchor = nil
	frame.GCDMApplyingAnchor = true
	pcall(function()
		frame:ClearAllPoints()
		if viewer then
			frame:SetPoint("TOPLEFT", viewer, "TOPLEFT", Skin.PARK_OFFSET or -10000, 0)
		end
	end)
	frame.GCDMApplyingAnchor = false
	pcall(frame.SetAlpha, frame, 0)
end

local function CollectShownIcons(viewer)
	local raw = Skin.CollectIconFrames(viewer)
	local out = {}
	for i = 1, #raw do
		local frame = raw[i]
		if frame then
			EnsureIconLifecycleHooks(frame)
			if IsIconLayoutActive(frame) then
				out[#out + 1] = frame
			else
				pcall(ParkEmptyIcon, frame, viewer)
			end
		end
	end
	SortIconsStable(out)
	return out
end

local function ResolveIconSize(frame, fallback)
	local w = Pixel.Snap((fallback and fallback.w) or 40)
	local h = Pixel.Snap((fallback and fallback.h) or 40)
	if frame then
		local okW, fw = pcall(function()
			return frame:GetWidth()
		end)
		local okH, fh = pcall(function()
			return frame:GetHeight()
		end)
		if okW and type(fw) == "number" and fw > 0 then
			w = fw
		end
		if okH and type(fh) == "number" and fh > 0 then
			h = fh
		end
	end
	return w, h
end

--- Center active buff icons only. Blizzard sizes the viewer for the full pool and
--- left-aligns; empty slots shift the visible row left of Essential.
LayoutBuffIconsCentered = function(viewer)
	if not viewer or not IsBuffViewer(viewer) or ShouldDeferLayout() then
		return
	end
	local db = GCDM:GetDB()
	if not db or not db.enabled then
		return
	end

	local raw = Skin.CollectIconFrames(viewer)
	local active = {}
	for i = 1, #raw do
		local frame = raw[i]
		if frame then
			EnsureIconLifecycleHooks(frame)
			if IsIconLayoutActive(frame) then
				active[#active + 1] = frame
			else
				frame.GCDMAnchor = nil
			end
		end
	end
	SortIconsStable(active)

	local spacing = SnapGap(db.spacing or 0)
	local w, h = ResolveIconSize(active[1], db.sizeBuff)
	local total = #active
	if total == 0 then
		SafeViewerSetSize(viewer, Pixel.Snap(w), Pixel.Snap(h))
		return
	end

	local width = RowWidth(total, w, spacing)
	local sized = SafeViewerSetSize(viewer, Pixel.Snap(width), Pixel.Snap(h))
	local containerW = width
	if not sized then
		local curW = viewer.GetWidth and viewer:GetWidth()
		if type(curW) == "number" and curW > 0 then
			containerW = curW
		end
	end
	local startX = (containerW - width) * 0.5
	for i = 1, total do
		PlaceIcon(active[i], viewer, startX + (i - 1) * (w + spacing), 0, w, h, 1, { keepSize = true })
	end
end

QueueBuffCenterLayout = function(viewer)
	if not viewer then
		return
	end
	if buffCenterQueued then
		return
	end
	buffCenterQueued = true
	C_Timer.After(0, function()
		buffCenterQueued = false
		LayoutBuffIconsCentered(viewer)
	end)
end

local function LayoutEssential(viewer, db)
	local icons = CollectShownIcons(viewer)
	local total = #icons
	local spacing = SnapGap(db.spacing or 0)
	local maxRow = db.maxIconsPerRow or 7
	if maxRow < 1 then
		maxRow = 1
	end

	local row1 = db.sizeEssential or { w = 46, h = 40 }
	local row2 = db.sizeEssentialRow2 or row1
	local row1W, row1H = Pixel.Snap(row1.w), Pixel.Snap(row1.h)
	local row2W, row2H = Pixel.Snap(row2.w), Pixel.Snap(row2.h)

	if total == 0 then
		SafeViewerSetSize(viewer, Pixel.Snap(row1W), Pixel.Snap(row1H))
		Skin.EssentialLayoutWidth = Skin.EssentialWidthFormula(db)
		return
	end

	local row1Count = math.min(maxRow, total)
	local row2Count = math.max(0, total - maxRow)
	local row1Width = RowWidth(row1Count, row1W, spacing)
	local row2Width = RowWidth(row2Count, row2W, spacing)
	local wantW = math.max(row1Width, row2Width)
	local containerH = row1H
	if row2Count > 0 then
		containerH = row1H + spacing + row2H
	end

	local sized = SafeViewerSetSize(viewer, Pixel.Snap(wantW), Pixel.Snap(containerH))
	local containerW = wantW
	if not sized then
		local curW = viewer.GetWidth and viewer:GetWidth()
		if type(curW) == "number" and curW > 0 then
			containerW = curW
		end
	end
	Skin.EssentialLayoutWidth = Skin.EssentialWidthFormula(db)

	for i = 1, total do
		local frame = icons[i]
		local w, h, x, y, row
		if i <= maxRow then
			row = 1
			w, h = row1W, row1H
			x = CenteredX(i - 1, row1W, spacing, containerW, row1Width)
			y = 0
		else
			row = 2
			w, h = row2W, row2H
			x = CenteredX(i - maxRow - 1, row2W, spacing, containerW, row2Width)
			y = -(row1H + spacing)
		end
		PlaceIcon(frame, viewer, x, y, w, h, row)
	end
end

local function LayoutSimpleRow(viewer, db, size)
	local icons = CollectShownIcons(viewer)
	local total = #icons
	if not size then
		return
	end

	local spacing = SnapGap(db.spacing or 0)
	local w, h = Pixel.Snap(size.w), Pixel.Snap(size.h)
	if total == 0 then
		SafeViewerSetSize(viewer, Pixel.Snap(w), h)
		return
	end

	local width = RowWidth(total, w, spacing)
	local sized = SafeViewerSetSize(viewer, Pixel.Snap(width), h)
	local containerW = width
	if not sized then
		local curW = viewer.GetWidth and viewer:GetWidth()
		if type(curW) == "number" and curW > 0 then
			containerW = curW
		end
	end
	local startX = (containerW - width) * 0.5
	for i = 1, total do
		PlaceIcon(icons[i], viewer, startX + (i - 1) * (w + spacing), 0, w, h, 1)
	end
end

local function ApplyLayout()
	if InCombat() then
		MarkCombatLayoutPending()
		local registry = GCDM.ViewerRegistry
		local buff = registry and registry.Buff and registry:Buff()
		if buff then
			LayoutBuffIconsCentered(buff)
		end
		if Skin.QueueBuffBarRelayout then
			Skin.QueueBuffBarRelayout()
		end
		return
	end
	if ShouldDeferLayout() or applyingLayout then
		return
	end

	applyingLayout = true
	local ok, err = pcall(function()
		Pixel.Update()
		local db = GCDM:GetDB()
		if not db or not db.enabled then
			return
		end

		local registry = GCDM.ViewerRegistry
		local essential = registry:Essential()
		if essential then
			LayoutEssential(essential, db)
		end

		local utility = registry:Utility()
		if utility then
			LayoutSimpleRow(utility, db, db.sizeUtility)
		end

		local buff = registry:Buff()
		if buff then
			LayoutBuffIconsCentered(buff)
		end

		if Skin.QueueBuffBarRelayout then
			Skin.QueueBuffBarRelayout()
		end
		if Skin.QueuePowerBarRelayout then
			Skin.QueuePowerBarRelayout()
		end
		if Skin.RefreshKeybindTexts then
			Skin.RefreshKeybindTexts()
		end
		if Skin.RebuildPressOverlayMap then
			Skin.RebuildPressOverlayMap()
		end
	end)
	applyingLayout = false
	if not ok and not GCDM._layoutApplyErrOnce then
		GCDM._layoutApplyErrOnce = true
		print("|cff3bb273GCDM|r Layout error: " .. tostring(err))
	end
end

QueuePostBlizzardLayout = function()
	if applyingLayout then
		return
	end
	if InCombat() then
		MarkCombatLayoutPending()
		local registry = GCDM.ViewerRegistry
		local buff = registry and registry.Buff and registry:Buff()
		if buff then
			LayoutBuffIconsCentered(buff)
		end
		if Skin.QueueBuffBarRelayout then
			Skin.QueueBuffBarRelayout()
		end
		return
	end
	if ShouldDeferLayout() or relayoutQueued then
		return
	end
	relayoutQueued = true
	C_Timer.After(0, function()
		relayoutQueued = false
		if applyingLayout or InCombat() then
			if InCombat() then
				MarkCombatLayoutPending()
				local registry = GCDM.ViewerRegistry
				local buff = registry and registry.Buff and registry:Buff()
				if buff then
					LayoutBuffIconsCentered(buff)
				end
				if Skin.QueueBuffBarRelayout then
					Skin.QueueBuffBarRelayout()
				end
			end
			return
		end
		if ShouldDeferLayout() then
			return
		end
		ApplyLayout()
	end)
end

local function HookViewerRefreshLayout(viewer)
	if not viewer then
		return
	end
	if IsBuffViewer(viewer) then
		if viewer.OnAcquireItemFrame and not viewer.GCDMLayoutAcquireHooked then
			viewer.GCDMLayoutAcquireHooked = true
			hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, itemFrame)
				EnsureIconLifecycleHooks(itemFrame)
				if itemFrame then
					itemFrame.GCDMParked = false
				end
				QueueBuffCenterLayout(viewer)
			end)
		end
		return
	end

	local Registry = GCDM.ViewerRegistry
	if Registry and Registry.HookOnce then
		Registry:HookOnce(viewer, "GCDMRefreshLayoutHooked", "RefreshLayout", function()
			QueuePostBlizzardLayout()
		end)
	elseif not viewer.GCDMRefreshLayoutHooked then
		viewer.GCDMRefreshLayoutHooked = true
		if viewer.RefreshLayout then
			hooksecurefunc(viewer, "RefreshLayout", function()
				QueuePostBlizzardLayout()
			end)
		end
	end
	if viewer.OnAcquireItemFrame and not viewer.GCDMLayoutAcquireHooked then
		viewer.GCDMLayoutAcquireHooked = true
		hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, itemFrame)
			EnsureIconLifecycleHooks(itemFrame)
		end)
	end
end

local function HookAllViewers()
	local registry = GCDM.ViewerRegistry
	if not registry then
		return
	end
	local names = GCDM.CONST.MANAGED_VIEWER_NAMES
	for i = 1, #names do
		HookViewerRefreshLayout(registry:Get(names[i]))
	end
end

GCDM:RegisterRefreshCallback("Skin.Layout", function()
	HookAllViewers()
	ApplyLayout()
end, 35, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.LAYOUT,
	GCDM.CONST.REFRESH.STYLE,
})
