local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

function Skin.LayoutIsBuffViewer(viewer)
	local name = viewer and viewer.GetName and viewer:GetName()
	return name == GCDM.CONST.VIEWERS.BUFF
end

function Skin.LayoutViewerOf(frame)
	if not frame then return nil end
	if frame.viewerFrame then return frame.viewerFrame end
	return frame.GetParent and frame:GetParent() or nil
end

function Skin.LayoutShouldDefer()
	if GCDM.ShouldDeferIconLayout then return GCDM:ShouldDeferIconLayout() end
	return GCDM.IsCooldownViewerSettingsOpen and GCDM:IsCooldownViewerSettingsOpen()
end

local function LayoutIndexOf(frame)
	local idx = frame and frame.layoutIndex
	return type(idx) == "number" and idx or 0
end

function Skin.LayoutSortIconsStable(icons)
	table.sort(icons, function(a, b)
		local ai, bi = LayoutIndexOf(a), LayoutIndexOf(b)
		if ai ~= bi then return ai < bi end
		local ay, by = a:GetTop() or 0, b:GetTop() or 0
		if math.abs(ay - by) > 1 then return ay > by end
		return (a:GetLeft() or 0) < (b:GetLeft() or 0)
	end)
end

local function HasDrawableIcon(frame)
	local icon = Skin.GetIconTexture(frame)
	if not icon then return false end
	local ok, tex = pcall(function() return icon:GetTexture() end)
	if ok and tex ~= nil then
		if canaccessvalue and not canaccessvalue(tex) then return true end
		local okCmp, empty = pcall(function() return tex == "" or tex == 0 end)
		if not okCmp or not empty then return true end
	end
	if icon.GetAtlas then
		local okA, atlas = pcall(icon.GetAtlas, icon)
		if okA and atlas and atlas ~= "" then return true end
	end
	return false
end

local function SecretBool(ok, value)
	if not ok then return nil end
	if issecretvalue and issecretvalue(value) then return nil end
	if canaccessvalue and not canaccessvalue(value) then return nil end
	if value == true then return true end
	if value == false then return false end
	return value and true or false
end

function Skin.LayoutIsIconActive(frame)
	local blizzActive = nil
	if frame and frame.IsActive then blizzActive = SecretBool(pcall(frame.IsActive, frame)) end
	if blizzActive == true then return true end
	local okDraw, drawable = pcall(HasDrawableIcon, frame)
	local shown = false
	if frame and frame.IsShown then shown = SecretBool(pcall(frame.IsShown, frame)) end
	if shown == nil then return okDraw and drawable and true or false end
	if blizzActive == false and not shown then return false end
	return shown and okDraw and drawable and true or false
end

local function InCombat()
	return InCombatLockdown and InCombatLockdown()
end

local function InstallAnchorSnapBack(frame)
	if frame.GCDMSnapHooked then return end
	frame.GCDMSnapHooked = true
	hooksecurefunc(frame, "SetPoint", function(self)
		if self.GCDMParked or self.GCDMApplyingAnchor then return end
		if InCombat() then
			if Skin.LayoutMarkCombatPending then Skin.LayoutMarkCombatPending() end
			return
		end
		if Skin.LayoutShouldDefer() then self.GCDMAnchor = nil return end
		local a = self.GCDMAnchor
		if not a then return end
		self.GCDMApplyingAnchor = true
		pcall(function()
			if not InCombat() then self:ClearAllPoints() end
			self:SetPoint(a[1], a[2], a[3], a[4], a[5])
		end)
		self.GCDMApplyingAnchor = false
	end)
end

function Skin.LayoutEnsureIconLifecycleHooks(frame)
	if not frame or frame.GCDMIconLifeHooked then return end
	frame.GCDMIconLifeHooked = true
	frame:HookScript("OnShow", function(self)
		if Skin.LayoutShouldDefer() then
			self.GCDMAnchor, self.GCDMParked = nil, false
			pcall(self.SetAlpha, self, 1)
			return
		end
		local viewer = Skin.LayoutViewerOf(self)
		self.GCDMParked = false
		pcall(self.SetAlpha, self, 1)
		if Skin.LayoutIsBuffViewer(viewer) then
			if Skin.QueueBuffCenterLayout then Skin.QueueBuffCenterLayout(viewer) end
		else
			self.GCDMAnchor = nil
			if Skin.QueuePostBlizzardLayout then Skin.QueuePostBlizzardLayout() end
		end
	end)
	frame:HookScript("OnHide", function(self)
		if Skin.LayoutShouldDefer() then
			self.GCDMAnchor, self.GCDMParked = nil, false
			return
		end
		local viewer = Skin.LayoutViewerOf(self)
		if Skin.LayoutIsBuffViewer(viewer) then
			self.GCDMParked = false
			if Skin.QueueBuffCenterLayout then Skin.QueueBuffCenterLayout(viewer) end
		else
			self.GCDMAnchor = nil
			if Skin.QueuePostBlizzardLayout then Skin.QueuePostBlizzardLayout() end
		end
	end)
end

function Skin.LayoutPlaceIcon(frame, viewer, x, y, w, h, row, opts)
	opts = opts or {}
	Skin.LayoutEnsureIconLifecycleHooks(frame)
	frame.GCDMParked, frame.GCDMRow = false, row
	pcall(frame.SetAlpha, frame, 1)
	if not opts.keepSize and w and h then pcall(frame.SetSize, frame, w, h) end
	frame.GCDMApplyingAnchor = true
	pcall(function()
		if not InCombat() then frame:ClearAllPoints() end
		frame:SetPoint("TOPLEFT", viewer, "TOPLEFT", x, y)
	end)
	frame.GCDMApplyingAnchor = false
	frame.GCDMAnchor = { "TOPLEFT", viewer, "TOPLEFT", x, y }
	InstallAnchorSnapBack(frame)
end

function Skin.LayoutParkEmptyIcon(frame, viewer)
	if not frame then return end
	Skin.LayoutEnsureIconLifecycleHooks(frame)
	if Skin.LayoutIsBuffViewer(viewer) then
		frame.GCDMParked, frame.GCDMAnchor = false, nil
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
		if viewer then frame:SetPoint("TOPLEFT", viewer, "TOPLEFT", Skin.PARK_OFFSET or -10000, 0) end
	end)
	frame.GCDMApplyingAnchor = false
	pcall(frame.SetAlpha, frame, 0)
end

function Skin.LayoutCollectShownIcons(viewer)
	local raw = Skin.CollectIconFrames(viewer)
	local out = {}
	for i = 1, #raw do
		local frame = raw[i]
		if frame then
			Skin.LayoutEnsureIconLifecycleHooks(frame)
			if Skin.LayoutIsIconActive(frame) then
				out[#out + 1] = frame
			else
				pcall(Skin.LayoutParkEmptyIcon, frame, viewer)
			end
		end
	end
	Skin.LayoutSortIconsStable(out)
	return out
end

function Skin.LayoutResolveIconSize(frame, fallback)
	local w = Pixel.Snap((fallback and fallback.w) or 40)
	local h = Pixel.Snap((fallback and fallback.h) or 40)
	if frame then
		local okW, fw = pcall(function() return frame:GetWidth() end)
		local okH, fh = pcall(function() return frame:GetHeight() end)
		if okW and type(fw) == "number" and fw > 0 then w = fw end
		if okH and type(fh) == "number" and fh > 0 then h = fh end
	end
	return w, h
end
