local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local Pixel = {}
GCDM.Pixel = Pixel

local cachedPixelSize = 1
local cachedPhysH = 0
local cachedScale = 1

function Pixel.Update()
	local physH = select(2, GetPhysicalScreenSize())
	local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
	if physH and physH > 0 and scale and scale > 0 then
		if physH == cachedPhysH and scale == cachedScale then
			return
		end
		cachedPhysH = physH
		cachedScale = scale
		cachedPixelSize = 768 / (physH * scale)
	end
end

function Pixel.GetSize()
	return cachedPixelSize
end

function Pixel.IsSnapEnabled()
	local db = GCDM.GetDB and GCDM:GetDB()
	-- Default off: allow fractional sizes/positions. Opt-in for pixel-perfect.
	return db and db.pixelSnap == true
end

--- Snap to physical pixel when pixelSnap is on; otherwise pass value through.
function Pixel.Snap(value)
	if value == nil then
		return 0
	end
	local n = tonumber(value)
	if not n or n == 0 then
		return 0
	end
	if not Pixel.IsSnapEnabled() then
		return n
	end
	local px = n / cachedPixelSize
	if px >= 0 then
		return math.floor(px + 0.5) * cachedPixelSize
	end
	return math.ceil(px - 0.5) * cachedPixelSize
end

function Pixel.DisableTextureSnap(tex)
	if not tex then
		return
	end
	if tex.SetSnapToPixelGrid then
		tex:SetSnapToPixelGrid(false)
	end
	if tex.SetTexelSnappingBias then
		tex:SetTexelSnappingBias(0)
	end
end

GCDM:RegisterRefreshCallback("Pixel", function()
	Pixel.Update()
end, 5, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
	GCDM.CONST.REFRESH.LAYOUT,
})
