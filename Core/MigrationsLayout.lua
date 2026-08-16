local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

-- Layout / BuffBar / Expressway / viewerPos migration chunks.

function GCDM.MigrateLayoutOneshots(p)
	if p.spacingTightDefault == nil then
		p.spacingTightDefault = true
		if p.spacing == nil or p.spacing == 1 then
			p.spacing = 0
		end
	end
	if p.buffIconSizeSynced == nil then
		p.buffIconSizeSynced = true
		local sb = p.sizeBuff
		if sb and sb.w == 40 and sb.h == 36 then
			sb.w, sb.h = 46, 40
		end
	end
	if p.buffBarSolidStyleV2 == nil then
		p.buffBarSolidStyleV2 = true
		p.buffBarStyle = "solid"
		if not p.buffBarTexture then
			p.buffBarTexture = "Solid"
		end
	end
	if p.buffBarTightDefault == nil then
		p.buffBarTightDefault = true
		if (p.buffBarStyle or "blizzard") == "blizzard" then
			p.buffBarStyle = "solid"
		end
		if (p.buffBarHeight or 20) >= 20 then
			p.buffBarHeight = 16
		end
		if (p.buffBarSpacing or 0) >= 2 then
			p.buffBarSpacing = 0
		end
		if (p.buffBarIconGap or 0) >= 1 then
			p.buffBarIconGap = 0
		end
		local sb = p.sizeBuff
		if sb and sb.w == 40 and sb.h == 36 then
			sb.w, sb.h = 46, 40
		end
	end
end

function GCDM.MigrateExpresswayFont(p, addon)
	if p.expresswayDefaultApplied then
		return
	end
	p.expresswayDefaultApplied = true
	local Skin = addon.Skin
	local preferred = Skin and Skin.DefaultFontName and Skin.DefaultFontName() or "Expressway"
	if preferred and preferred ~= "Friz Quadrata TT" then
		p.textByViewer = p.textByViewer or {}
		for _, key in ipairs({
			"EssentialCooldownViewer",
			"UtilityCooldownViewer",
			"BuffIconCooldownViewer",
			"BuffBarCooldownViewer",
		}) do
			local st = p.textByViewer[key]
			if type(st) == "table" and (not st.textFont or st.textFont == "Friz Quadrata TT") then
				st.textFont = preferred
			end
		end
		if not p.powerBarFont or p.powerBarFont == "Friz Quadrata TT" then
			p.powerBarFont = preferred
		end
	end
end

function GCDM.MigrateViewerPos(p)
	local defaultsPos = (ns.defaults.profile.viewerPos) or {}
	p.viewerPos = p.viewerPos or {}
	local keys = { "essential", "utility", "buff", "buffBar", "powerBar" }
	for i = 1, #keys do
		local key = keys[i]
		local src = p.viewerPos[key] or defaultsPos[key] or {}
		p.viewerPos[key] = {
			enabled = src.enabled and true or false,
			point = src.point or "CENTER",
			x = src.x or 0,
			y = src.y or 0,
		}
	end
	if not p._gcdmCoordinatesOwnPlacement then
		for i = 1, #keys do
			p.viewerPos[keys[i]].enabled = true
		end
		p._gcdmCoordinatesOwnPlacement = true
	end
	if p.buffBarFollowEssential == nil then
		p.buffBarFollowEssential = true
	end
	if p.powerBarFollowEssential == nil then
		p.powerBarFollowEssential = true
	end
	if type(p.buffBarWidth) == "number" and p.buffBarWidth > 0 and p.buffBarWidth < 200 then
		p.buffBarWidth = 200
	end
	if type(p.powerBarWidth) == "number" and p.powerBarWidth > 0 and p.powerBarWidth < 200 then
		p.powerBarWidth = 200
	end
	if type(p.customGroups) ~= "table" then
		p.customGroups = {}
	end
	if type(p.customGroupSeeded) ~= "table" then
		p.customGroupSeeded = {}
	end
	for _, key in ipairs({ "essential", "utility", "buff", "buffBar" }) do
		if type(p.customGroups[key]) ~= "table" then
			p.customGroups[key] = {}
		end
	end
	if p.customPanelsEnabled == nil then
		p.customPanelsEnabled = true
	end
	if p.hideBlizzardViewers == nil then
		p.hideBlizzardViewers = true
	end
end
