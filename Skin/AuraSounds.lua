local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

-- Hook CDM aura alerts and play matching rules.

local applying = false
local lastPlay = {}
local THROTTLE = 0.35

local function SpellIDsMatch(ruleSpell, frameSpell)
	ruleSpell = tonumber(ruleSpell)
	frameSpell = tonumber(frameSpell)
	if not ruleSpell or not frameSpell then
		return false
	end
	if ruleSpell == frameSpell then
		return true
	end
	if Skin.SpellLookupIDs then
		local a = Skin.SpellLookupIDs(ruleSpell)
		for i = 1, #a do
			if a[i] == frameSpell then
				return true
			end
		end
		local b = Skin.SpellLookupIDs(frameSpell)
		for i = 1, #b do
			if b[i] == ruleSpell then
				return true
			end
		end
	end
	return false
end

local function CanPlayNow()
	if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
		return false
	end
	return true
end

local function ThrottleOk(spellID, event)
	local key = tostring(spellID) .. ":" .. tostring(event)
	local now = GetTime and GetTime() or 0
	local prev = lastPlay[key] or 0
	if now - prev < THROTTLE then
		return false
	end
	lastPlay[key] = now
	return true
end

local function PlayRulesForSpell(spellID, event)
	if not spellID or not CanPlayNow() then
		return
	end
	local db = GCDM:GetDB()
	if not db or not db.enabled or db.auraSoundEnabled == false then
		return
	end
	local rules = db.auraSoundRules
	if type(rules) ~= "table" then
		return
	end
	if not ThrottleOk(spellID, event) then
		return
	end
	local ParseSoundKey = ns.AuraSoundParseKey
	local DefaultKit = ns.AuraSoundDefaultKit
	for i = 1, #rules do
		local rule = rules[i]
		if rule and (rule.event or "apply") == event then
			local unit = rule.unit or "player"
			if unit == "player" and SpellIDsMatch(rule.spellID, spellID) then
				local kind, kit, lsm = ParseSoundKey(rule.soundKey or rule.soundKitID, db)
				if kind == "kit" then
					ns.AuraSoundPlayKit(kit or DefaultKit(db))
				else
					ns.AuraSoundPlayLSM(lsm)
				end
			end
		end
	end
end

local function OnAuraApplied(frame)
	local spellID = Skin.GetFrameSpellID and Skin.GetFrameSpellID(frame)
	PlayRulesForSpell(spellID, "apply")
end

local function OnAuraRemoved(frame)
	local spellID = Skin.GetFrameSpellID and Skin.GetFrameSpellID(frame)
	PlayRulesForSpell(spellID, "remove")
end

local function HookAuraFrame(frame)
	if not frame or frame.GCDMAuraSoundHooked then
		return
	end
	frame.GCDMAuraSoundHooked = true
	if frame.TriggerAuraAppliedAlert then
		hooksecurefunc(frame, "TriggerAuraAppliedAlert", function(f)
			OnAuraApplied(f)
		end)
	end
	if frame.TriggerAuraRemovedAlert then
		hooksecurefunc(frame, "TriggerAuraRemovedAlert", function(f)
			OnAuraRemoved(f)
		end)
	end
	if frame.RefreshApplications then
		hooksecurefunc(frame, "RefreshApplications", function(f)
			if f and f:IsShown() then
				PlayRulesForSpell(Skin.GetFrameSpellID and Skin.GetFrameSpellID(f), "stack")
			end
		end)
	end
end

local function HookViewerPool(viewer)
	if not viewer then
		return
	end
	local registry = GCDM.ViewerRegistry
	if registry and registry.HookOnce then
		registry:HookOnce(viewer, "GCDMAuraSoundAcquireHooked", "OnAcquireItemFrame", function(_, itemFrame)
			HookAuraFrame(itemFrame)
		end)
	elseif viewer.OnAcquireItemFrame and not viewer.GCDMAuraSoundAcquireHooked then
		viewer.GCDMAuraSoundAcquireHooked = true
		hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, itemFrame)
			HookAuraFrame(itemFrame)
		end)
	end
	if Skin.CollectIconFrames then
		local icons = Skin.CollectIconFrames(viewer)
		for i = 1, #icons do
			HookAuraFrame(icons[i])
		end
	end
	if Skin.CollectBarFrames then
		local bars = Skin.CollectBarFrames(viewer)
		for i = 1, #bars do
			HookAuraFrame(bars[i])
		end
	end
end

local function ApplyAuraSounds()
	if applying then
		return
	end
	applying = true
	local ok, err = pcall(function()
		local db = GCDM:GetDB()
		if not db or not db.enabled or db.auraSoundEnabled == false then
			return
		end
		local registry = GCDM.ViewerRegistry
		if not registry then
			return
		end
		if registry.Buff then
			HookViewerPool(registry:Buff())
		end
		if registry.BuffBar then
			HookViewerPool(registry:BuffBar())
		end
	end)
	applying = false
	if not ok and not GCDM._auraSoundsErrOnce then
		GCDM._auraSoundsErrOnce = true
		print("|cff3bb273GCDM|r AuraSounds error: " .. tostring(err))
	end
end

GCDM:RegisterRefreshCallback("Skin.AuraSounds", function()
	ApplyAuraSounds()
end, 50, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})