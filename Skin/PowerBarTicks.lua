-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- Power bar tick marks (equal / values).
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local PowerBarChrome = Skin.PowerBarChrome

function PowerBarChrome.ClearTicks(bar)
	if not bar or not bar.GCDMTicks then
		return
	end
	for i = 1, #bar.GCDMTicks do
		bar.GCDMTicks[i]:Hide()
	end
end

local function ParseTickValues(str)
	local out = {}
	if type(str) ~= "string" then
		return out
	end
	for part in string.gmatch(str, "[^,%s]+") do
		local n = tonumber(part)
		if n then
			out[#out + 1] = n
		end
	end
	return out
end

function PowerBarChrome.LayoutTicks(bar, profile)
	PowerBarChrome.ClearTicks(bar)
	if not bar or not profile or profile.tickMode == "none" then
		return
	end
	local tc = profile.tickColor or { r = 1, g = 1, b = 1, a = 0.55 }
	local ratios = {}
	if profile.tickMode == "equal" then
		local n = math.max(1, math.floor(profile.tickCount or 4))
		for i = 1, n - 1 do
			ratios[#ratios + 1] = i / n
		end
	elseif profile.tickMode == "values" then
		local maxV = profile.tickMax or 100
		if maxV <= 0 then
			maxV = 100
		end
		local vals = ParseTickValues(profile.tickAtStr or "")
		for i = 1, #vals do
			local r = vals[i] / maxV
			if r > 0 and r < 1 then
				ratios[#ratios + 1] = r
			end
		end
	end
	local w = bar:GetWidth() or 0
	if w < 2 then
		return
	end
	for i = 1, #ratios do
		local tick = bar.GCDMTicks[i]
		if not tick then
			tick = bar:CreateTexture(nil, "OVERLAY")
			bar.GCDMTicks[i] = tick
		end
		tick:SetColorTexture(tc.r or 1, tc.g or 1, tc.b or 1, tc.a or 0.55)
		tick:ClearAllPoints()
		tick:SetWidth(1)
		local x = w * ratios[i]
		tick:SetPoint("TOPLEFT", bar, "TOPLEFT", x, 0)
		tick:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x, 0)
		tick:Show()
	end
end
