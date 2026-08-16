local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local Skin = {}
GCDM.Skin = Skin

-- Parked empty CDM icons sit at this X so Blizzard RefreshLayout cannot reclaim them.
-- Protocol: GCDMParked=true, GCDMAnchor[4]=PARK_OFFSET, alpha 0; never snap SetPoint while parked.
Skin.PARK_OFFSET = -10000

--- When spacing is 0, adjacent icon borders would stack; overlap by borderSize (see LayoutGeometry).
function Skin.BorderOverlap(db, gap)
	local Geom = Skin.LayoutGeometry
	if Geom and Geom.BorderOverlap then
		return Geom.BorderOverlap(db, gap)
	end
	return 0
end

--- Full configured Essential row width (maxIconsPerRow), used by BuffBar/PowerBar/tests.
function Skin.EssentialWidthFormula(db)
	local Geom = Skin.LayoutGeometry
	if Geom and Geom.EssentialConfiguredWidth then
		return Geom.EssentialConfiguredWidth(db)
	end
	return 0
end

local function IsBuffBarItem(frame)
	return frame ~= nil and frame.Bar ~= nil
end

local function IsIconLike(frame)
	if not frame or not frame.GetObjectType then
		return false
	end
	if IsBuffBarItem(frame) then
		return false
	end
	if frame.Icon or frame.icon or frame.Cooldown then
		return true
	end
	local texture = frame.GetNormalTexture and frame:GetNormalTexture()
	return texture ~= nil
end

function Skin.IsBuffBarItem(frame)
	return IsBuffBarItem(frame)
end

function Skin.CollectIconFrames(viewer)
	local out = {}
	if not viewer then
		return out
	end

	-- Prefer active pool frames (Blizzard CDM); avoid stale GetChildren / released slots.
	if viewer.itemFramePool and viewer.itemFramePool.EnumerateActive then
		for frame in viewer.itemFramePool:EnumerateActive() do
			if frame and not IsBuffBarItem(frame) then
				out[#out + 1] = frame
			end
		end
		return out
	end

	if viewer.itemFrames then
		for _, frame in pairs(viewer.itemFrames) do
			if frame and not IsBuffBarItem(frame) then
				out[#out + 1] = frame
			end
		end
		return out
	end

	local children = { viewer:GetChildren() }
	for i = 1, #children do
		local child = children[i]
		if IsIconLike(child) then
			out[#out + 1] = child
		end
	end
	return out
end

function Skin.CollectBarFrames(viewer)
	local out = {}
	if not viewer then
		return out
	end

	if viewer.itemFramePool and viewer.itemFramePool.EnumerateActive then
		for frame in viewer.itemFramePool:EnumerateActive() do
			if frame and IsBuffBarItem(frame) then
				out[#out + 1] = frame
			end
		end
		return out
	end

	if viewer.itemFrames then
		for _, frame in pairs(viewer.itemFrames) do
			if frame and IsBuffBarItem(frame) then
				out[#out + 1] = frame
			end
		end
		return out
	end

	local children = { viewer:GetChildren() }
	for i = 1, #children do
		local child = children[i]
		if IsBuffBarItem(child) then
			out[#out + 1] = child
		end
	end
	return out
end

function Skin.GetIconTexture(frame)
	if not frame then
		return nil
	end
	local icon = frame.Icon or frame.icon
	if icon and icon.GetObjectType then
		local ot = icon:GetObjectType()
		if ot == "Texture" then
			return icon
		end
		-- Buff-bar style nested icon frame: Icon.Icon
		if icon.Icon and icon.Icon.GetObjectType and icon.Icon:GetObjectType() == "Texture" then
			return icon.Icon
		end
		if icon.icon and icon.icon.GetObjectType and icon.icon:GetObjectType() == "Texture" then
			return icon.icon
		end
	end
	if frame.GetNormalTexture then
		return frame:GetNormalTexture()
	end
	return nil
end

function Skin.ForEachManagedIcon(callback)
	local registry = GCDM.ViewerRegistry
	local names = GCDM.CONST.MANAGED_VIEWER_NAMES
	for i = 1, #names do
		local viewerName = names[i]
		local viewer = registry:Get(viewerName)
		if viewer then
			local icons = Skin.CollectIconFrames(viewer)
			for j = 1, #icons do
				callback(icons[j], viewer, viewerName)
			end
		end
	end
end

function Skin.ForEachBuffBar(callback)
	local viewer = GCDM.ViewerRegistry:BuffBar()
	if not viewer then
		return
	end
	local bars = Skin.CollectBarFrames(viewer)
	for i = 1, #bars do
		callback(bars[i], viewer)
	end
end
