local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

-- Watch CDM aura frames and play matching rules.
--
-- This used to hook TriggerAuraAppliedAlert / TriggerAuraRemovedAlert on the
-- item frames. Those hooks run inside Blizzard's UNIT_AURA loop, which then
-- continues tainted and blows up on its own secret aura values. We now sample
-- frame state from our own event frame instead.

local applying = false
local lastPlay = {}
local THROTTLE = 0.35

local shownState = setmetatable({}, { __mode = "k" })
local stackState = setmetatable({}, { __mode = "k" })

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

local function IsFrameActive(frame)
	if frame.IsActive then
		local ok, active = pcall(frame.IsActive, frame)
		if ok and active ~= nil then
			return active == true
		end
	end
	local ok, shown = pcall(frame.IsShown, frame)
	return ok and shown == true
end

--- Stack text can be a secret string; then stack rules simply stay silent.
local function StackText(frame)
	local fs = Skin.GetStackFontString and Skin.GetStackFontString(frame)
	if not fs or not fs.GetText then
		return nil
	end
	local ok, text = pcall(fs.GetText, fs)
	if not ok then
		return nil
	end
	if issecretvalue and issecretvalue(text) then
		return nil
	end
	if canaccessvalue and not canaccessvalue(text) then
		return nil
	end
	return text
end

local function CollectAuraFrames()
	local frames = {}
	local registry = GCDM.ViewerRegistry
	if not registry then
		return frames
	end
	local viewers = { registry:Buff(), registry:BuffBar() }
	for i = 1, #viewers do
		local viewer = viewers[i]
		if viewer then
			if Skin.CollectIconFrames then
				local icons = Skin.CollectIconFrames(viewer)
				for j = 1, #icons do
					frames[#frames + 1] = icons[j]
				end
			end
			if Skin.CollectBarFrames then
				local bars = Skin.CollectBarFrames(viewer)
				for j = 1, #bars do
					frames[#frames + 1] = bars[j]
				end
			end
		end
	end
	return frames
end

--- silent seeds the state without playing: on login and after a reload every
--- aura already up would otherwise fire its apply rule.
local function ScanAuraFrames(silent)
	if applying then
		return
	end
	applying = true
	local ok, err = pcall(function()
		local db = GCDM:GetDB()
		if not db or not db.enabled or db.auraSoundEnabled == false then
			return
		end
		local frames = CollectAuraFrames()
		for i = 1, #frames do
			local frame = frames[i]
			local active = IsFrameActive(frame)
			local was = shownState[frame]
			shownState[frame] = active

			local spellID = Skin.GetFrameSpellID and Skin.GetFrameSpellID(frame)
			if not silent and was ~= nil and spellID then
				if active and not was then
					PlayRulesForSpell(spellID, "apply")
				elseif was and not active then
					PlayRulesForSpell(spellID, "remove")
				end
			end

			local stack = active and StackText(frame) or nil
			local prevStack = stackState[frame]
			stackState[frame] = stack
			if not silent and active and stack and prevStack and stack ~= prevStack and spellID then
				PlayRulesForSpell(spellID, "stack")
			end
		end
	end)
	applying = false
	if not ok and not GCDM._auraSoundsErrOnce then
		GCDM._auraSoundsErrOnce = true
		print("|cff3bb273GCDM|r AuraSounds error: " .. tostring(err))
	end
end

GCDM:RegisterRefreshCallback("Skin.AuraSounds", function()
	ScanAuraFrames(true)
end, 50, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})

GCDM.CDMWatch:Register("Skin.AuraSounds", function(events)
	ScanAuraFrames(events and events.PLAYER_ENTERING_WORLD)
end)