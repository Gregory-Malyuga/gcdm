local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel
local VIEWERS = GCDM.CONST.VIEWERS

local function SizeForFrame(viewerName, frame, db)
	if viewerName == VIEWERS.ESSENTIAL then
		if frame.GCDMRow == 2 then
			return db.sizeEssentialRow2 or db.sizeEssential
		end
		return db.sizeEssential
	end
	if viewerName == VIEWERS.UTILITY then
		return db.sizeUtility
	end
	if viewerName == VIEWERS.BUFF then
		return db.sizeBuff
	end
	return db.sizeEssential
end

local function ApplySize()
	Pixel.Update()
	local db = GCDM:GetDB()
	if not db or not db.enabled then
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		return
	end
	if GCDM.ShouldDeferIconLayout and GCDM:ShouldDeferIconLayout() then
		return
	end

	-- Layout already sets sizes when it runs; keep this as a safety net.
	-- Buff icon row: leave size to Blizzard GridLayout / CDM settings.
	Skin.ForEachManagedIcon(function(frame, _, viewerName)
		if viewerName == VIEWERS.BUFF then
			return
		end
		local size = SizeForFrame(viewerName, frame, db)
		if size and size.w and size.h then
			pcall(frame.SetSize, frame, Pixel.Snap(size.w), Pixel.Snap(size.h))
		end
	end)
end

GCDM:RegisterRefreshCallback("Skin.Size", ApplySize, 40, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
	GCDM.CONST.REFRESH.LAYOUT,
})
