-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
-- Secondary power type + bar value/text updates.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Chrome = Skin.PowerBarChrome
local PowerBarLayout = Skin.PowerBarLayout

local CLASS_SECONDARY = {
	PALADIN = "HolyPower",
	MONK = "Chi",
	ROGUE = "ComboPoints",
	DRUID = "ComboPoints",
	WARLOCK = "SoulShards",
	MAGE = "ArcaneCharges",
	EVOKER = "Essence",
	DEATHKNIGHT = "Runes",
	SHAMAN = "Maelstrom",
}

local function PowerEnum(key)
	local pt = Enum and Enum.PowerType and Enum.PowerType[key]
	if type(pt) == "number" then
		return pt
	end
	return nil
end

function PowerBarLayout.FindSecondaryPowerType(primaryType)
	local _, classFile = UnitClass("player")
	local key = classFile and CLASS_SECONDARY[classFile]
	local pt = key and PowerEnum(key) or nil
	if not pt or pt == primaryType then
		return nil
	end
	local ok, maxP = pcall(UnitPowerMax, "player", pt)
	if not ok or maxP == nil then
		return nil
	end
	if issecretvalue and issecretvalue(maxP) then
		return pt
	end
	if canaccessvalue and not canaccessvalue(maxP) then
		return pt
	end
	if type(maxP) == "number" and maxP > 0 then
		return pt
	end
	return nil
end

function PowerBarLayout.UpdateBarValues(bar, text, powerType, showText)
	if not bar or powerType == nil then
		return
	end
	local filled = false
	if UnitPowerPercent then
		local ok, pct = pcall(UnitPowerPercent, "player", powerType)
		if ok and pct ~= nil then
			pcall(bar.SetMinMaxValues, bar, 0, 1)
			if Skin.SmoothBarSetValue then
				Skin.SmoothBarSetValue(bar, pct, Skin.IsBarSmoothEnabled and Skin.IsBarSmoothEnabled())
				filled = true
			else
				local okSet = pcall(bar.SetValue, bar, pct)
				filled = okSet and true or false
			end
		end
	end
	if not filled then
		local okCur, cur = pcall(UnitPower, "player", powerType)
		local okMax, maxP = pcall(UnitPowerMax, "player", powerType)
		if okCur and okMax and cur ~= nil and maxP ~= nil then
			pcall(bar.SetMinMaxValues, bar, 0, maxP)
			if Skin.SmoothBarSetValue then
				Skin.SmoothBarSetValue(bar, cur, Skin.IsBarSmoothEnabled and Skin.IsBarSmoothEnabled())
			else
				pcall(bar.SetValue, bar, cur)
			end
			filled = true
		end
	end
	if not filled then
		pcall(bar.SetMinMaxValues, bar, 0, 1)
		if Skin.SmoothBarSetValue then
			Skin.SmoothBarSetValue(bar, 0, false)
		else
			pcall(bar.SetValue, bar, 0)
		end
	end
	if text and showText then
		local ok, cur = pcall(UnitPower, "player", powerType)
		if ok and cur ~= nil then
			Chrome.SafeSetText(text, cur)
		else
			Chrome.SafeSetText(text, "")
		end
	elseif text then
		Chrome.SafeSetText(text, "")
	end
end
