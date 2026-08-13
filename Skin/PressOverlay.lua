local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

-- Press feedback on Essential/Utility while the bound action-bar key is held.
-- Poll runs only while pressOverlayEnabled (stopped when off). Hooks are a bonus.

local COOLDOWN_VIEWERS = GCDM.CONST.COOLDOWN_VIEWER_NAMES

local overlays = setmetatable({}, { __mode = "k" })
local spellCombos = {} -- [spellID] = { { key=, shift=, ctrl=, alt= }, ... }
local spellFrames = {} -- [spellID] = { frame, ... }
local mapCacheVer = -1
local hooksInstalled = false
local pollElapsed = 0
local POLL_INTERVAL = 0.05
local lastPressedSig = ""
local lastMapLogAt = 0
local syncTicks = 0
-- Soft yellow press wash (solid tint, no flash/star).
local PRESS_R, PRESS_G, PRESS_B, PRESS_A = 1.0, 0.82, 0.12, 0.40

local pollFrame = CreateFrame("Frame")
pollFrame:Hide()

local function WantLog()
	local db = GCDM:GetDB()
	return db and db.pressOverlayDebug == true
end

local function Log(msg)
	if not WantLog() then
		return
	end
	print("|cff3bb273GCDM Press|r " .. tostring(msg))
end

local function IsEnabled()
	local db = GCDM:GetDB()
	return db and db.enabled and db.pressOverlayEnabled ~= false
end

local function ParseRawKey(rawKey)
	if type(rawKey) ~= "string" or rawKey == "" then
		return nil
	end
	local shift, ctrl, alt = false, false, false
	local remaining = rawKey
	while true do
		if remaining:sub(1, 6) == "SHIFT-" then
			shift = true
			remaining = remaining:sub(7)
		elseif remaining:sub(1, 5) == "CTRL-" then
			ctrl = true
			remaining = remaining:sub(6)
		elseif remaining:sub(1, 4) == "ALT-" then
			alt = true
			remaining = remaining:sub(5)
		else
			break
		end
	end
	if remaining == "" then
		return nil
	end
	return { key = remaining, shift = shift, ctrl = ctrl, alt = alt, raw = rawKey }
end

local function IsComboDown(combo)
	if not combo then
		return false, "nil_combo"
	end
	if not IsKeyDown then
		return false, "no_IsKeyDown"
	end
	local wantShift = combo.shift and true or false
	local wantCtrl = combo.ctrl and true or false
	local wantAlt = combo.alt and true or false
	local haveShift = IsShiftKeyDown and IsShiftKeyDown() or false
	local haveCtrl = IsControlKeyDown and IsControlKeyDown() or false
	local haveAlt = IsAltKeyDown and IsAltKeyDown() or false
	if wantShift ~= haveShift or wantCtrl ~= haveCtrl or wantAlt ~= haveAlt then
		return false, "mod_mismatch"
	end
	local ok, down = pcall(IsKeyDown, combo.key)
	if not ok then
		return false, "IsKeyDown_err:" .. tostring(down)
	end
	if down then
		return true, "down"
	end
	return false, "up"
end

local function ApplyPressTint(tex)
	if not tex then
		return
	end
	tex:SetColorTexture(PRESS_R, PRESS_G, PRESS_B, PRESS_A)
	tex:SetBlendMode("BLEND")
end

local function GetOrCreateOverlay(frame)
	local ov = overlays[frame]
	if ov then
		return ov
	end
	ov = CreateFrame("Frame", nil, frame)
	ov:SetAllPoints(frame)
	ov:EnableMouse(false)
	local tex = ov:CreateTexture(nil, "OVERLAY", nil, 7)
	tex:SetAllPoints(ov)
	ApplyPressTint(tex)
	ov.texture = tex
	ov:Hide()
	overlays[frame] = ov
	Log(string.format("overlay created for frame=%s", tostring(frame:GetName() or frame)))
	return ov
end

local function ShowOverlay(frame)
	if not frame then
		return
	end
	local ov = GetOrCreateOverlay(frame)
	ApplyPressTint(ov.texture)
	local base = frame:GetFrameLevel() or 0
	local border = frame.GCDMBackdropBorder
	local borderLevel = border and border.GetFrameLevel and border:GetFrameLevel() or (base + 3)
	ov:SetFrameLevel(math.max(borderLevel + 2, base + 10))
	ov:SetAlpha(1)
	ov:Show()
end

local function HideOverlay(frame)
	local ov = frame and overlays[frame]
	if ov then
		ov:Hide()
	end
end

local function HideAllOverlays()
	for _, ov in pairs(overlays) do
		ov:Hide()
	end
end

local function SpellAliases(spellID)
	local ids = {}
	local seen = {}
	local function add(id)
		id = tonumber(id)
		if id and id > 0 and not seen[id] then
			seen[id] = true
			ids[#ids + 1] = id
		end
	end
	add(spellID)
	if C_Spell and C_Spell.GetBaseSpell then
		local ok, base = pcall(C_Spell.GetBaseSpell, spellID)
		if ok then
			add(base)
		end
	end
	if FindBaseSpellByID then
		local ok, base = pcall(FindBaseSpellByID, spellID)
		if ok then
			add(base)
		end
	end
	if FindSpellOverrideByID then
		local ok, ov = pcall(FindSpellOverrideByID, spellID)
		if ok then
			add(ov)
		end
	end
	return ids
end

local function CountKeys(t)
	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end
	return n
end

local function EnsureMapFresh(forceLog)
	local ver = Skin.GetKeybindCacheVersion and Skin.GetKeybindCacheVersion() or 0
	if ver == mapCacheVer then
		return
	end
	mapCacheVer = ver
	wipe(spellCombos)
	wipe(spellFrames)

	if not IsEnabled() then
		Log("map rebuild skipped (press disabled)")
		return
	end

	local registry = GCDM.ViewerRegistry
	if not registry then
		Log("map rebuild: no ViewerRegistry")
		return
	end

	local iconCount = 0
	local withSpell = 0
	local withKeys = 0
	local samples = {}

	for i = 1, #COOLDOWN_VIEWERS do
		local viewerName = COOLDOWN_VIEWERS[i]
		local viewer = registry:Get(viewerName)
		local icons = Skin.CollectIconFrames(viewer)
		for j = 1, #icons do
			iconCount = iconCount + 1
			local frame = icons[j]
			local spellID = Skin.GetFrameSpellID and Skin.GetFrameSpellID(frame)
			if spellID then
				withSpell = withSpell + 1
				local aliases = SpellAliases(spellID)
				local rawKeys = Skin.GetRawKeysForSpell and Skin.GetRawKeysForSpell(spellID)
				local text = Skin.GetKeybindText and Skin.GetKeybindText(spellID)
				local combos
				if rawKeys then
					combos = {}
					for k = 1, #rawKeys do
						local combo = ParseRawKey(rawKeys[k])
						if combo then
							combos[#combos + 1] = combo
						end
					end
					if #combos == 0 then
						combos = nil
					end
				end
				if combos then
					withKeys = withKeys + 1
				end
				if #samples < 8 then
					samples[#samples + 1] = string.format(
						"%s sid=%s kb=%s raw=%s",
						tostring(viewerName):gsub("CooldownViewer", ""),
						tostring(spellID),
						tostring(text),
						rawKeys and table.concat(rawKeys, ",") or "nil"
					)
				end
				for a = 1, #aliases do
					local sid = aliases[a]
					local list = spellFrames[sid]
					if not list then
						list = {}
						spellFrames[sid] = list
					end
					list[#list + 1] = frame
					if combos then
						spellCombos[sid] = combos
					end
				end
			end
		end
	end

	Log(string.format(
		"map v=%d icons=%d withSpell=%d withKeys=%d comboSpells=%d",
		ver,
		iconCount,
		withSpell,
		withKeys,
		CountKeys(spellCombos)
	))
	for i = 1, #samples do
		Log("  " .. samples[i])
	end
	if withKeys == 0 and withSpell > 0 then
		Log("WARN: CDM icons found but no action-bar keybinds matched (FindSpellActionButtons/scan empty?)")
	end
	if iconCount == 0 then
		Log("WARN: no Essential/Utility icon frames")
	end
end

function Skin.RebuildPressOverlayMap()
	mapCacheVer = -1
	EnsureMapFresh(true)
end

local function SyncOverlaysFromKeys()
	syncTicks = syncTicks + 1
	if not IsEnabled() then
		HideAllOverlays()
		return
	end
	if GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() then
		if syncTicks % 40 == 1 then
			Log("skip: keyboard focus active")
		end
		HideAllOverlays()
		return
	end

	EnsureMapFresh()

	local pressedFrames = {}
	local downSpells = {}
	local firstFail
	for spellID, combos in pairs(spellCombos) do
		local down = false
		for i = 1, #combos do
			local okDown, reason = IsComboDown(combos[i])
			if okDown then
				down = true
				break
			elseif not firstFail and reason and reason ~= "up" and reason ~= "mod_mismatch" then
				firstFail = string.format("sid=%s raw=%s reason=%s", tostring(spellID), tostring(combos[i].raw), tostring(reason))
			end
		end
		if down then
			downSpells[#downSpells + 1] = spellID
			local frames = spellFrames[spellID]
			if frames then
				for j = 1, #frames do
					pressedFrames[frames[j]] = true
				end
			end
		end
	end

	local pressedCount = CountKeys(pressedFrames)
	local sig = table.concat(downSpells, ",")
	if sig ~= lastPressedSig then
		lastPressedSig = sig
		if sig ~= "" then
			Log(string.format("PRESSED spells=[%s] frames=%d", sig, pressedCount))
		else
			Log("released all")
		end
	elseif syncTicks % 60 == 0 then
		-- Heartbeat every ~3s
		Log(string.format(
			"poll ok ticks=%d combos=%d pressed=%d pollShown=%s",
			syncTicks,
			CountKeys(spellCombos),
			pressedCount,
			tostring(pollFrame:IsShown())
		))
		if firstFail then
			Log("  sample IsKeyDown fail: " .. firstFail)
		end
	end

	local registry = GCDM.ViewerRegistry
	if registry then
		for i = 1, #COOLDOWN_VIEWERS do
			local icons = Skin.CollectIconFrames(registry:Get(COOLDOWN_VIEWERS[i]))
			for j = 1, #icons do
				local frame = icons[j]
				if pressedFrames[frame] then
					ShowOverlay(frame)
				else
					HideOverlay(frame)
				end
			end
		end
	end
end

local function SetPressedForSpell(spellID, pressed)
	if not spellID or not IsEnabled() then
		Log(string.format("SetPressed skip sid=%s pressed=%s enabled=%s", tostring(spellID), tostring(pressed), tostring(IsEnabled())))
		return
	end
	EnsureMapFresh()
	local seen = {}
	local hit = 0
	local aliases = SpellAliases(spellID)
	for a = 1, #aliases do
		local frames = spellFrames[aliases[a]]
		if frames then
			for i = 1, #frames do
				local frame = frames[i]
				if not seen[frame] then
					seen[frame] = true
					hit = hit + 1
					if pressed then
						ShowOverlay(frame)
					else
						HideOverlay(frame)
					end
				end
			end
		end
	end
	Log(string.format("hook SetPressed sid=%s pressed=%s frames=%d aliases=%s", tostring(spellID), tostring(pressed), hit, table.concat(aliases, ",")))
end

local function OnActionButton(buttonID, pressed)
	local slot = Skin.GetActionSlotForMainBarButton and Skin.GetActionSlotForMainBarButton(buttonID)
	local spellID = slot and Skin.GetSpellIDForActionSlot and Skin.GetSpellIDForActionSlot(slot)
	Log(string.format("ActionButton%s id=%s slot=%s spell=%s", pressed and "Down" or "Up", tostring(buttonID), tostring(slot), tostring(spellID)))
	if spellID then
		SetPressedForSpell(spellID, pressed)
	end
end

local function OnMultiActionButton(barName, buttonID, pressed)
	local slot = Skin.GetActionSlotForMultiBar and Skin.GetActionSlotForMultiBar(barName, buttonID)
	local spellID = slot and Skin.GetSpellIDForActionSlot and Skin.GetSpellIDForActionSlot(slot)
	Log(string.format("MultiActionButton%s bar=%s id=%s slot=%s spell=%s", pressed and "Down" or "Up", tostring(barName), tostring(buttonID), tostring(slot), tostring(spellID)))
	if spellID then
		SetPressedForSpell(spellID, pressed)
	end
end

local function InstallHooks()
	if hooksInstalled then
		return
	end
	hooksInstalled = true

	local hasABD = type(ActionButtonDown) == "function"
	local hasABU = type(ActionButtonUp) == "function"
	local hasMAD = type(MultiActionButtonDown) == "function"
	local hasMAU = type(MultiActionButtonUp) == "function"
	Log(string.format("hooks install ActionButtonDown=%s Up=%s MultiDown=%s Up=%s", tostring(hasABD), tostring(hasABU), tostring(hasMAD), tostring(hasMAU)))

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

pollFrame:SetScript("OnUpdate", function(_, dt)
	pollElapsed = pollElapsed + dt
	if pollElapsed < POLL_INTERVAL then
		return
	end
	pollElapsed = 0
	SyncOverlaysFromKeys()
end)

local function StartPoll()
	InstallHooks()
	Skin.RebuildPressOverlayMap()
	pollElapsed = POLL_INTERVAL
	pollFrame:Show()
	Log(string.format("poll STARTED shown=%s", tostring(pollFrame:IsShown())))
end

local function StopPoll()
	pollFrame:Hide()
	HideAllOverlays()
	Log("poll STOPPED")
end

local function ApplyPressOverlay()
	local db = GCDM:GetDB()
	Log(string.format(
		"Apply enabled=%s press=%s debug=%s",
		tostring(db and db.enabled),
		tostring(db and db.pressOverlayEnabled ~= false),
		tostring(db and db.pressOverlayDebug == true)
	))
	if IsEnabled() then
		StartPoll()
	else
		StopPoll()
	end
end

function Skin.DumpPressOverlayDebug()
	local prev = WantLog()
	local db = GCDM:GetDB()
	if db then
		db.pressOverlayDebug = true
	end
	mapCacheVer = -1
	EnsureMapFresh(true)
	Log(string.format("manual dump pollShown=%s ticks=%d", tostring(pollFrame:IsShown()), syncTicks))
	-- Probe first combo IsKeyDown
	for spellID, combos in pairs(spellCombos) do
		for i = 1, #combos do
			local down, reason = IsComboDown(combos[i])
			Log(string.format("probe sid=%s raw=%s down=%s reason=%s", tostring(spellID), tostring(combos[i].raw), tostring(down), tostring(reason)))
		end
		break
	end
	if db and not prev then
		-- keep debug on after dump so user sees live logs
	end
end

GCDM:RegisterRefreshCallback("Skin.PressOverlay", ApplyPressOverlay, 56, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})
