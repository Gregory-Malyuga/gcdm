local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

-- Text used to be re-applied from hooks on the CDM item mixins (OnCooldownIDSet,
-- RefreshSpellChargeInfo, RefreshApplications). Those run inside Blizzard's
-- refresh and taint everything it does afterwards, so the same work is now
-- driven by CDMWatch from our own event frame.
local function ApplyTextAll()
	local db = GCDM:GetDB()
	if not db or not db.enabled then return end
	GCDM.Skin.ForEachManagedIcon(function(frame, _, viewerName)
		Skin.ApplyText(frame, viewerName)
	end)
	if GCDM.Skin.ForEachBuffBar then
		GCDM.Skin.ForEachBuffBar(function(frame)
			if Skin.StyleBuffBarLabels then Skin.StyleBuffBarLabels(frame, db) end
		end)
	end
end

GCDM:RegisterRefreshCallback("Skin.Text", ApplyTextAll, 55, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})

GCDM.CDMWatch:Register("Skin.Text", ApplyTextAll, 0.1)
