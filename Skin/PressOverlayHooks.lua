local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local PO = Skin._PressOverlayState

local function SetPressedForSpell(spellID, pressed)
	if not spellID or not Skin.PressOverlayIsEnabled() then
		Skin.PressOverlayLog(string.format("SetPressed skip sid=%s pressed=%s enabled=%s", tostring(spellID), tostring(pressed), tostring(Skin.PressOverlayIsEnabled())))
		return
	end
	Skin.PressOverlayEnsureMap()
	local seen = {}
	local hit = 0
	local aliases = Skin.PressOverlaySpellAliases(spellID)
	for a = 1, #aliases do
		local frames = PO.spellFrames[aliases[a]]
		if frames then
			for i = 1, #frames do
				local frame = frames[i]
				if not seen[frame] then
					seen[frame] = true
					hit = hit + 1
					if pressed then
						Skin.PressOverlayShow(frame)
					else
						Skin.PressOverlayHide(frame)
					end
				end
			end
		end
	end
	Skin.PressOverlayLog(string.format("hook SetPressed sid=%s pressed=%s frames=%d aliases=%s", tostring(spellID), tostring(pressed), hit, table.concat(aliases, ",")))
end

local function OnActionButton(buttonID, pressed)
	local slot = Skin.GetActionSlotForMainBarButton and Skin.GetActionSlotForMainBarButton(buttonID)
	local spellID = slot and Skin.GetSpellIDForActionSlot and Skin.GetSpellIDForActionSlot(slot)
	Skin.PressOverlayLog(string.format("ActionButton%s id=%s slot=%s spell=%s", pressed and "Down" or "Up", tostring(buttonID), tostring(slot), tostring(spellID)))
	if spellID then
		SetPressedForSpell(spellID, pressed)
	end
end

local function OnMultiActionButton(barName, buttonID, pressed)
	local slot = Skin.GetActionSlotForMultiBar and Skin.GetActionSlotForMultiBar(barName, buttonID)
	local spellID = slot and Skin.GetSpellIDForActionSlot and Skin.GetSpellIDForActionSlot(slot)
	Skin.PressOverlayLog(string.format("MultiActionButton%s bar=%s id=%s slot=%s spell=%s", pressed and "Down" or "Up", tostring(barName), tostring(buttonID), tostring(slot), tostring(spellID)))
	if spellID then
		SetPressedForSpell(spellID, pressed)
	end
end

function Skin.PressOverlayInstallHooks()
	if PO.hooksInstalled then
		return
	end
	PO.hooksInstalled = true
	local hasABD = type(ActionButtonDown) == "function"
	local hasABU = type(ActionButtonUp) == "function"
	local hasMAD = type(MultiActionButtonDown) == "function"
	local hasMAU = type(MultiActionButtonUp) == "function"
	Skin.PressOverlayLog(string.format("hooks install ActionButtonDown=%s Up=%s MultiDown=%s Up=%s", tostring(hasABD), tostring(hasABU), tostring(hasMAD), tostring(hasMAU)))
	if hasABD then
		hooksecurefunc("ActionButtonDown", function(id)
			OnActionButton(id, true)
		end)
	end
	if hasABU then
		hooksecurefunc("ActionButtonUp", function(id)
			OnActionButton(id, false)
		end)
	end
	if hasMAD then
		hooksecurefunc("MultiActionButtonDown", function(bar, id)
			OnMultiActionButton(bar, id, true)
		end)
	end
	if hasMAU then
		hooksecurefunc("MultiActionButtonUp", function(bar, id)
			OnMultiActionButton(bar, id, false)
		end)
	end
end
