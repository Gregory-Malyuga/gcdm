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
	if GCDM.ShouldDeferIconLayout then
		return GCDM:ShouldDeferIconLayout()
	end
	if GCDM.ShouldDeferCDMLayout and GCDM:ShouldDeferCDMLayout() then
		return true
	end
	return GCDM.IsCooldownViewerSettingsOpen and GCDM:IsCooldownViewerSettingsOpen()
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

local function LayoutIndexOf(frame)
	return PlainNumber(frame and frame.layoutIndex) or 0
end

function Skin.LayoutSortIconsStable(icons)
	table.sort(icons, function(a, b)
		local ai, bi = LayoutIndexOf(a), LayoutIndexOf(b)
		if ai ~= bi then return ai < bi end
		local ay = PlainNumber(a.GetTop and a:GetTop()) or 0
		local by = PlainNumber(b.GetTop and b:GetTop()) or 0
		if math.abs(ay - by) > 1 then return ay > by end
		local ax = PlainNumber(a.GetLeft and a:GetLeft()) or 0
		local bx = PlainNumber(b.GetLeft and b:GetLeft()) or 0
		return ax < bx
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

-- Icon placement used to defend itself with a SetPoint hook plus OnShow/OnHide
-- script hooks on each item frame. All three run inside Blizzard's own layout
-- and refresh, which then continues tainted, so placement is re-applied from
-- the next CDMWatch pass instead of fighting Blizzard inside its call stack.

function Skin.LayoutPlaceIcon(frame, viewer, x, y, w, h, row, opts)
	opts = opts or {}
	frame.GCDMParked, frame.GCDMRow = false, row
	pcall(frame.SetAlpha, frame, 1)
	if not opts.keepSize and w and h then pcall(frame.SetSize, frame, w, h) end
	pcall(function()
		if not InCombat() then frame:ClearAllPoints() end
		frame:SetPoint("TOPLEFT", viewer, "TOPLEFT", x, y)
	end)
end

function Skin.LayoutParkEmptyIcon(frame, viewer)
	if not frame then return end
	if Skin.LayoutIsBuffViewer(viewer) then
		frame.GCDMParked = false
		return
	end
	frame.GCDMParked = true
	if InCombat() then
		pcall(frame.SetAlpha, frame, 0)
		return
	end
	pcall(function()
		frame:ClearAllPoints()
		if viewer then frame:SetPoint("TOPLEFT", viewer, "TOPLEFT", Skin.PARK_OFFSET or -10000, 0) end
	end)
	pcall(frame.SetAlpha, frame, 0)
end

function Skin.LayoutCollectShownIcons(viewer)
	local raw = Skin.CollectIconFrames(viewer)
	local out = {}
	for i = 1, #raw do
		local frame = raw[i]
		if frame then
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
