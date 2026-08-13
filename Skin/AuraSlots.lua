local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

-- Custom aura strips via 12.1 AuraContainer / AddAuraSlot when available.
-- Modes: duration (SetDurationBar) and applications (SetApplicationBar + cosmetic ticks).
-- Sounds: apply / stack gain / remove only (no stacks==N conditions — impossible in combat).

local host
local container
local slotEntries = {} -- [key] = { spellID=, mode=, maxApps=, button=, bar=, ticks={} }
local soundHandles = {}
local applying = false
local useContainerAPI = nil -- nil=unknown, true/false after probe

local function ParseDurationList(str)
	local out = {}
	if type(str) ~= "string" or str == "" then
		return out
	end
	for part in string.gmatch(str, "[^,%s]+") do
		local id = tonumber(part)
		if id and id > 0 then
			out[#out + 1] = { spellID = id, mode = "duration", maxApps = 1 }
		end
	end
	return out
end

-- "85739:4" → applications bar with max 4 (+ ticks). Plain id → duration.
local function ParseAppList(str)
	local out = {}
	if type(str) ~= "string" or str == "" then
		return out
	end
	for part in string.gmatch(str, "[^,%s]+") do
		local id, maxS = string.match(part, "^(%d+):(%d+)$")
		if id then
			local spellID = tonumber(id)
			local maxApps = tonumber(maxS) or 1
			if spellID and spellID > 0 and maxApps > 0 then
				out[#out + 1] = { spellID = spellID, mode = "applications", maxApps = maxApps }
			end
		else
			local spellID = tonumber(part)
			if spellID and spellID > 0 then
				out[#out + 1] = { spellID = spellID, mode = "applications", maxApps = 4 }
			end
		end
	end
	return out
end

local function CollectSlotConfigs(db)
	local list = {}
	local seen = {}
	local dur = ParseDurationList(db.auraBarSpellIDs or "")
	for i = 1, #dur do
		local c = dur[i]
		if not seen[c.spellID] then
			seen[c.spellID] = true
			list[#list + 1] = c
		end
	end
	local apps = ParseAppList(db.auraAppSpellIDs or "")
	for i = 1, #apps do
		local c = apps[i]
		-- Apps config wins over duration for same spellID.
		if seen[c.spellID] then
			for j = 1, #list do
				if list[j].spellID == c.spellID then
					list[j] = c
					break
				end
			end
		else
			seen[c.spellID] = true
			list[#list + 1] = c
		end
	end
	return list
end

local function ResolveWidth(db)
	local w = db.auraBarWidth or 0
	if type(w) == "number" and w > 0 then
		return Pixel.Snap(w)
	end
	local laid = Skin.EssentialLayoutWidth
	if type(laid) == "number" and laid >= 40 then
		return Pixel.Snap(laid)
	end
	if GCDM.GetPowerBarHost then
		local ph = GCDM:GetPowerBarHost()
		if ph and ph:IsShown() then
			local ok, pw = pcall(ph.GetWidth, ph)
			if ok and type(pw) == "number" and pw >= 40 then
				return Pixel.Snap(pw)
			end
		end
	end
	local essential = GCDM.ViewerRegistry and GCDM.ViewerRegistry:Essential()
	if essential then
		local ok, ew = pcall(essential.GetWidth, essential)
		if ok and type(ew) == "number" and ew >= 40 then
			return Pixel.Snap(ew)
		end
	end
	return 200
end

local function EnsureHost()
	if host then
		return host
	end
	host = CreateFrame("Frame", "GCDM_AuraSlotHost", UIParent)
	host:SetSize(200, 10)
	host:SetFrameStrata("BACKGROUND")
	host:SetFrameLevel(1)
	return host
end

local function StyleStatusBar(bar, db, fr, fg, fb, fa)
	local texName = db.auraBarTexture or db.buffBarTexture or "Solid"
	local bgName = db.auraBarBackgroundTexture or "Solid"
	local tex = (Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(texName)) or GCDM.CONST.TEX_WHITE8X8
	local bgc = db.auraBarBackgroundColor or db.buffBarBackgroundColor or { r = 0.1, g = 0.1, b = 0.1, a = 1 }

	bar:SetStatusBarTexture(tex)
	local st = bar:GetStatusBarTexture()
	if st then
		if Pixel.DisableTextureSnap then
			Pixel.DisableTextureSnap(st)
		end
		st:SetVertexColor(fr, fg, fb, fa or 1)
	end
	pcall(bar.SetStatusBarColor, bar, fr, fg, fb, fa or 1)
	if not bar.GCDMBg then
		bar.GCDMBg = bar:CreateTexture(nil, "BACKGROUND")
		bar.GCDMBg:SetAllPoints()
	end
	-- Rear strip: independent of fill texture.
	if bgName == "Solid" then
		bar.GCDMBg:SetColorTexture(bgc.r or 0.1, bgc.g or 0.1, bgc.b or 0.1, bgc.a or 1)
	else
		local bgPath = (Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(bgName)) or GCDM.CONST.TEX_WHITE8X8
		bar.GCDMBg:SetTexture(bgPath)
		if bar.GCDMBg.SetTexCoord then
			bar.GCDMBg:SetTexCoord(0, 1, 0, 1)
		end
		if not bar.GCDMBg:GetTexture() then
			bar.GCDMBg:SetColorTexture(bgc.r or 0.1, bgc.g or 0.1, bgc.b or 0.1, bgc.a or 1)
		else
			bar.GCDMBg:SetVertexColor(bgc.r or 0.1, bgc.g or 0.1, bgc.b or 0.1, bgc.a or 1)
		end
	end
	bar.GCDMBg:Show()
	if Pixel.DisableTextureSnap then
		Pixel.DisableTextureSnap(bar.GCDMBg)
	end
end

local function StyleAuraFontString(fs, db)
	if not fs then
		return
	end
	local fontPath = (Skin.FetchFont and Skin.FetchFont(db.auraBarFont or db.textFont or "Expressway")) or GCDM.CONST.FONT_PATH
	local fontSize = db.auraBarFontSize or 10
	local outlineRaw = db.auraBarTextOutline
	if outlineRaw == nil then
		outlineRaw = "OUTLINE"
	end
	local outline = (Skin.ResolveOutline and Skin.ResolveOutline(outlineRaw)) or outlineRaw or "OUTLINE"
	if outline == "NONE" then
		outline = ""
	end
	pcall(fs.SetFont, fs, fontPath, fontSize, outline)
	local tc = db.auraBarTextColor or { r = 1, g = 1, b = 1, a = 1 }
	fs:SetTextColor(tc.r or 1, tc.g or 1, tc.b or 1, tc.a or 1)
	if outline ~= "" then
		fs:SetShadowColor(0, 0, 0, 1)
		fs:SetShadowOffset(1, -1)
	else
		fs:SetShadowColor(0, 0, 0, 0)
		fs:SetShadowOffset(0, 0)
	end
end

local function SpellDisplayName(spellID)
	if C_Spell and C_Spell.GetSpellName then
		local ok, name = pcall(C_Spell.GetSpellName, spellID)
		if ok and name then
			return name
		end
	end
	if GetSpellInfo then
		local ok, name = pcall(GetSpellInfo, spellID)
		if ok and name then
			return name
		end
	end
	return tostring(spellID or "")
end

-- Name left, duration/value right. Prefer Blizzard AuraButton text setters when present.
local function EnsureSlotTexts(owner, entry, db)
	if not owner or not entry then
		return
	end
	local showName = db.auraBarShowName == true
	local showDuration = db.auraBarShowDuration ~= false

	if showName then
		if not entry.nameFS then
			entry.nameFS = owner:CreateFontString(nil, "OVERLAY")
			entry.nameFS:SetPoint("LEFT", owner, "LEFT", 4, 0)
			entry.nameFS:SetJustifyH("LEFT")
			if owner.SetSpellName then
				pcall(owner.SetSpellName, owner, entry.nameFS)
			end
		end
		StyleAuraFontString(entry.nameFS, db)
		if not owner.SetSpellName then
			entry.nameFS:SetText(SpellDisplayName(entry.spellID))
		end
		entry.nameFS:Show()
	elseif entry.nameFS then
		entry.nameFS:Hide()
	end

	if showDuration then
		if not entry.durFS then
			entry.durFS = owner:CreateFontString(nil, "OVERLAY")
			entry.durFS:SetPoint("RIGHT", owner, "RIGHT", -4, 0)
			entry.durFS:SetJustifyH("RIGHT")
			local bound = false
			if owner.SetDurationText then
				bound = pcall(owner.SetDurationText, owner, entry.durFS)
			elseif owner.SetTimerText then
				bound = pcall(owner.SetTimerText, owner, entry.durFS)
			elseif owner.SetApplicationText and entry.mode == "applications" then
				bound = pcall(owner.SetApplicationText, owner, entry.durFS)
			end
			entry.durFS._gcdmBlizzBound = bound and true or false
		end
		StyleAuraFontString(entry.durFS, db)
		entry.durFS:Show()
	elseif entry.durFS then
		entry.durFS:Hide()
	end
end

local function ClearTicks(entry)
	if not entry.ticks then
		return
	end
	for i = 1, #entry.ticks do
		entry.ticks[i]:Hide()
	end
end

local function EnsureTicks(entry, maxApps, showTicks)
	ClearTicks(entry)
	entry.ticks = entry.ticks or {}
	if not showTicks or maxApps < 2 or not entry.bar then
		return
	end
	local bar = entry.bar
	for i = 1, maxApps - 1 do
		local tick = entry.ticks[i]
		if not tick then
			tick = bar:CreateTexture(nil, "OVERLAY")
			tick:SetColorTexture(1, 1, 1, 0.55)
			entry.ticks[i] = tick
		end
		tick:ClearAllPoints()
		tick:SetWidth(1)
		tick:SetPoint("TOP", bar, "TOPLEFT", 0, 0)
		tick:SetPoint("BOTTOM", bar, "BOTTOMLEFT", 0, 0)
		-- Position via width fraction after layout; store ratio.
		tick.GCDMRatio = i / maxApps
		tick:Show()
	end
end

local function LayoutTicks(entry)
	local bar = entry.bar
	if not bar or not entry.ticks then
		return
	end
	local w = bar:GetWidth() or 0
	if w < 2 then
		return
	end
	for i = 1, #entry.ticks do
		local tick = entry.ticks[i]
		if tick and tick.GCDMRatio then
			local x = w * tick.GCDMRatio
			tick:ClearAllPoints()
			tick:SetWidth(1)
			tick:SetPoint("TOPLEFT", bar, "TOPLEFT", x, 0)
			tick:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x, 0)
		end
	end
end

local function ProbeContainerAPI()
	if useContainerAPI ~= nil then
		return useContainerAPI
	end
	local ok, frame = pcall(CreateFrame, "AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
	if not ok or not frame then
		ok, frame = pcall(CreateFrame, "AuraContainer", nil, UIParent, "ManagedAuraContainerTemplate")
	end
	if ok and frame and type(frame.AddAuraSlot) == "function" then
		frame:Hide()
		frame:SetParent(nil)
		useContainerAPI = true
		return true
	end
	if frame then
		frame:Hide()
		frame:SetParent(nil)
	end
	useContainerAPI = false
	return false
end

local function EnsureContainer()
	if container then
		return container
	end
	EnsureHost()
	local ok, frame = pcall(CreateFrame, "AuraContainer", "GCDM_AuraContainer", host, "CustomAuraContainerTemplate")
	if not ok or not frame then
		ok, frame = pcall(CreateFrame, "AuraContainer", "GCDM_AuraContainer", host, "ManagedAuraContainerTemplate")
	end
	if not ok or not frame then
		return nil
	end
	container = frame
	container:SetSize(1, 1)
	container:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
	if container.SetUnit then
		pcall(container.SetUnit, container, "player")
	end
	if container.SetEnabled then
		pcall(container.SetEnabled, container, true)
	end
	return container
end

local function MakeBarForButton(parent, height)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	bar:SetHeight(Pixel.Snap(height))
	bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
	return bar
end

local function InitializeSlotFrame(auraButton, cfg, db)
	if not auraButton then
		return
	end
	local height = db.auraBarHeight or 6
	auraButton:SetSize(ResolveWidth(db), Pixel.Snap(height))

	local key = "gcdm_" .. tostring(cfg.spellID)
	local entry = slotEntries[key] or { spellID = cfg.spellID, mode = cfg.mode, maxApps = cfg.maxApps }
	entry.button = auraButton
	entry.mode = cfg.mode
	entry.maxApps = cfg.maxApps or 1
	entry.spellID = cfg.spellID
	slotEntries[key] = entry

	local fill = db.auraBarColor or db.buffBarColor or { r = 0.4, g = 0.6, b = 0.9, a = 1 }
	if cfg.mode == "applications" then
		fill = db.auraAppBarColor or { r = 0.2, g = 0.85, b = 0.75, a = 1 }
	end

	if not auraButton.GCDMSlotWired then
		auraButton.GCDMSlotWired = true
		local bar = MakeBarForButton(auraButton, height)
		entry.bar = bar
		StyleStatusBar(bar, db, fill.r or 0.4, fill.g or 0.6, fill.b or 0.9, fill.a or 1)

		if cfg.mode == "applications" then
			if auraButton.SetApplicationBar then
				pcall(auraButton.SetApplicationBar, auraButton, bar, { maxApplications = cfg.maxApps or 4 })
			end
			EnsureTicks(entry, cfg.maxApps or 4, db.auraBarShowTicks ~= false)
		else
			if auraButton.SetDurationBar then
				pcall(auraButton.SetDurationBar, auraButton, bar, {})
			end
		end
	else
		if entry.bar then
			StyleStatusBar(entry.bar, db, fill.r or 0.4, fill.g or 0.6, fill.b or 0.9, fill.a or 1)
			if cfg.mode == "applications" then
				EnsureTicks(entry, cfg.maxApps or 4, db.auraBarShowTicks ~= false)
			end
		end
	end

	EnsureSlotTexts(auraButton, entry, db)
end

local function ClearContainerSlots()
	if not container then
		return
	end
	for key, entry in pairs(slotEntries) do
		if container.RemoveAuraSlot then
			pcall(container.RemoveAuraSlot, container, key)
		end
		ClearTicks(entry)
	end
	wipe(slotEntries)
end

local function RegisterAuraSounds(db, configs)
	for i = 1, #soundHandles do
		local h = soundHandles[i]
		if h and C_UnitAuras and C_UnitAuras.RemoveAuraSound then
			pcall(C_UnitAuras.RemoveAuraSound, h)
		elseif h and C_UnitAuras and C_UnitAuras.RemoveAuraAppliedSound then
			pcall(C_UnitAuras.RemoveAuraAppliedSound, h)
		end
	end
	wipe(soundHandles)

	if not C_UnitAuras then
		return
	end
	local kit = db.auraSoundKitID or 0
	if kit <= 0 then
		kit = SOUNDKIT and SOUNDKIT.UI_AUTO_QUEST_COMPLETE or 878
	end

	local function TryAdd(spellID, whenKey)
		local opts = {
			spellID = spellID,
			unitToken = "player",
			soundKitID = kit,
		}
		if whenKey then
			opts[whenKey] = true
		end
		if C_UnitAuras.AddAuraSound then
			local ok, handle = pcall(C_UnitAuras.AddAuraSound, opts)
			if ok and handle then
				soundHandles[#soundHandles + 1] = handle
				return
			end
			ok, handle = pcall(C_UnitAuras.AddAuraSound, spellID, kit)
			if ok and handle then
				soundHandles[#soundHandles + 1] = handle
			end
		elseif C_UnitAuras.AddAuraAppliedSound and whenKey ~= "onRemove" and whenKey ~= "onApplication" then
			local ok, handle = pcall(C_UnitAuras.AddAuraAppliedSound, opts)
			if ok and handle then
				soundHandles[#soundHandles + 1] = handle
			end
		end
	end

	for i = 1, #configs do
		local spellID = configs[i].spellID
		if db.auraSoundOnApply then
			TryAdd(spellID, "onApply")
		end
		if db.auraSoundOnStack then
			TryAdd(spellID, "onApplication")
		end
		if db.auraSoundOnRemove then
			TryAdd(spellID, "onRemove")
		end
	end
end

local function AnchorHost(db, count, height, spacing)
	local h = EnsureHost()
	local width = ResolveWidth(db)
	local gap = Pixel.Snap(db.auraBarGap or 1)
	local hostH = 1
	if count > 0 then
		hostH = (count * height) + ((count - 1) * spacing)
	end
	h:SetSize(width, hostH)
	h:SetFrameStrata("BACKGROUND")
	h:SetFrameLevel(1)
	h:ClearAllPoints()
	local anchor = GCDM.GetPowerBarHost and GCDM:GetPowerBarHost()
	if anchor and anchor:IsShown() then
		h:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, gap)
		h:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, gap)
	else
		local essential = GCDM.ViewerRegistry and GCDM.ViewerRegistry:Essential()
		if essential then
			h:SetPoint("BOTTOMLEFT", essential, "TOPLEFT", 0, gap)
			h:SetPoint("BOTTOMRIGHT", essential, "TOPRIGHT", 0, gap)
		else
			h:SetPoint("CENTER", UIParent, "CENTER", 0, -80)
		end
	end
	h:SetShown(count > 0)
end

local function LayoutSlotButtons(db, orderedKeys, height, spacing, width)
	for i = 1, #orderedKeys do
		local entry = slotEntries[orderedKeys[i]]
		local btn = entry and (entry.button or entry.legacyBar)
		if btn then
			btn:ClearAllPoints()
			btn:SetSize(width, height)
			local y = -((i - 1) * (height + spacing))
			btn:SetPoint("TOPLEFT", host, "TOPLEFT", 0, y)
			btn:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, y)
			if entry.bar then
				entry.bar:SetHeight(height)
				LayoutTicks(entry)
			end
			btn:Show()
		end
	end
end

-- Legacy fallback: StatusBar + GetPlayerAuraBySpellID (works when aura data is accessible).
local function FindPlayerAuraData(spellID)
	if not C_UnitAuras then
		return nil
	end
	if C_UnitAuras.GetPlayerAuraBySpellID then
		local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
		if ok and aura then
			return aura
		end
	end
	local filters = { "HELPFUL", "HARMFUL" }
	for fi = 1, #filters do
		if C_UnitAuras.GetUnitAuras then
			local ok, list = pcall(C_UnitAuras.GetUnitAuras, "player", filters[fi])
			if ok and type(list) == "table" then
				for i = 1, #list do
					local aura = list[i]
					local sid = aura and (aura.spellId or aura.spellID)
					if sid == spellID then
						return aura
					end
				end
			end
		end
	end
	return nil
end

local function EnsureLegacyBar(key, cfg, db)
	local entry = slotEntries[key]
	if entry and entry.legacyBar then
		EnsureSlotTexts(entry.legacyBar, entry, db)
		return entry
	end
	EnsureHost()
	local bar = CreateFrame("StatusBar", nil, host)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	local fill = db.auraBarColor or { r = 0.4, g = 0.6, b = 0.9, a = 1 }
	if cfg.mode == "applications" then
		fill = db.auraAppBarColor or { r = 0.2, g = 0.85, b = 0.75, a = 1 }
	end
	StyleStatusBar(bar, db, fill.r or 0.4, fill.g or 0.6, fill.b or 0.9, fill.a or 1)
	entry = {
		spellID = cfg.spellID,
		mode = cfg.mode,
		maxApps = cfg.maxApps or 1,
		legacyBar = bar,
		bar = bar,
	}
	slotEntries[key] = entry
	if cfg.mode == "applications" then
		EnsureTicks(entry, cfg.maxApps or 4, db.auraBarShowTicks ~= false)
	end
	EnsureSlotTexts(bar, entry, db)
	return entry
end

local function UpdateLegacyEntry(entry, db)
	local data = FindPlayerAuraData(entry.spellID)
	local bar = entry.legacyBar
	if not data then
		bar:Hide()
		return false
	end
	local fill = db.auraBarColor or { r = 0.4, g = 0.6, b = 0.9, a = 1 }
	if entry.mode == "applications" then
		fill = db.auraAppBarColor or { r = 0.2, g = 0.85, b = 0.75, a = 1 }
		StyleStatusBar(bar, db, fill.r, fill.g, fill.b, fill.a)
		local maxApps = entry.maxApps or 4
		pcall(bar.SetMinMaxValues, bar, 0, maxApps)
		local apps = data.applications
		if apps ~= nil then
			if Skin.SmoothBarSetValue then
				Skin.SmoothBarSetValue(bar, apps, Skin.IsBarSmoothEnabled and Skin.IsBarSmoothEnabled())
			else
				pcall(bar.SetValue, bar, apps)
			end
			if entry.durFS and db.auraBarShowDuration ~= false and type(apps) == "number" then
				entry.durFS:SetText(tostring(apps))
			end
		else
			if Skin.SmoothBarSetValue then
				Skin.SmoothBarSetValue(bar, 1, false)
			else
				pcall(bar.SetValue, bar, 1)
			end
			if entry.durFS then
				entry.durFS:SetText("")
			end
		end
	else
		StyleStatusBar(bar, db, fill.r, fill.g, fill.b, fill.a)
		if C_UnitAuras and C_UnitAuras.GetAuraDuration and data.auraInstanceID and bar.SetTimerDuration then
			local ok, dur = pcall(C_UnitAuras.GetAuraDuration, "player", data.auraInstanceID)
			if ok and dur then
				local dir = Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime
				pcall(bar.SetTimerDuration, bar, dur, nil, dir)
			else
				bar:SetMinMaxValues(0, 1)
				bar:SetValue(1)
			end
		else
			bar:SetMinMaxValues(0, 1)
			bar:SetValue(1)
		end
		-- Duration digits are secret-safe only via Blizzard duration objects / setters; leave blank in legacy.
		if entry.durFS and not entry.durFS._gcdmBlizzBound then
			entry.durFS:SetText("")
		end
	end
	EnsureSlotTexts(bar, entry, db)
	bar:Show()
	return true
end

local function ApplyViaContainer(db, configs)
	local c = EnsureContainer()
	if not c or type(c.AddAuraSlot) ~= "function" then
		useContainerAPI = false
		return false
	end

	ClearContainerSlots()
	local height = Pixel.Snap(db.auraBarHeight or 6)
	local spacing = Pixel.Snap(db.auraBarSpacing or 1)
	local width = ResolveWidth(db)
	local ordered = {}

	for i = 1, #configs do
		local cfg = configs[i]
		local key = "gcdm_" .. tostring(cfg.spellID)
		local filter = "HELPFUL"
		local options = {
			initializeFrame = function(auraButton)
				InitializeSlotFrame(auraButton, cfg, db)
			end,
			candidateFilters = {
				includeSpellIDs = { [cfg.spellID] = true },
			},
		}
		local ok = pcall(c.AddAuraSlot, c, key, filter, options)
		if not ok then
			-- Retry harmful filter for DoTs etc.
			ok = pcall(c.AddAuraSlot, c, key, "HARMFUL", options)
		end
		if ok then
			ordered[#ordered + 1] = key
			-- Manual slot anchor if API exposes the frame.
			if c.GetAuraSlotFrame then
				local okf, frame = pcall(c.GetAuraSlotFrame, c, key)
				if okf and frame then
					local entry = slotEntries[key] or { spellID = cfg.spellID, mode = cfg.mode, maxApps = cfg.maxApps }
					entry.button = frame
					slotEntries[key] = entry
					if not entry.bar then
						InitializeSlotFrame(frame, cfg, db)
					end
				end
			end
		end
	end

	-- Also try HELPFUL|PLAYER for player-cast buffs.
	AnchorHost(db, #ordered, height, spacing)
	LayoutSlotButtons(db, ordered, height, spacing, width)
	RegisterAuraSounds(db, configs)
	return #ordered > 0 or #configs == 0
end

local function ApplyViaLegacy(db, configs)
	EnsureHost()
	local height = Pixel.Snap(db.auraBarHeight or 6)
	local spacing = Pixel.Snap(db.auraBarSpacing or 1)
	local width = ResolveWidth(db)
	local ordered = {}
	local activeKeys = {}

	for i = 1, #configs do
		local cfg = configs[i]
		local key = "gcdm_" .. tostring(cfg.spellID)
		activeKeys[key] = true
		local entry = EnsureLegacyBar(key, cfg, db)
		if UpdateLegacyEntry(entry, db) then
			ordered[#ordered + 1] = key
		else
			entry.legacyBar:Hide()
		end
	end
	for key, entry in pairs(slotEntries) do
		if not activeKeys[key] and entry.legacyBar then
			entry.legacyBar:Hide()
		end
	end

	AnchorHost(db, #ordered, height, spacing)
	LayoutSlotButtons(db, ordered, height, spacing, width)
	RegisterAuraSounds(db, configs)
end

local function ApplyAuraSlots()
	if applying then
		return
	end
	applying = true
	local ok, err = pcall(function()
		local db = GCDM:GetDB()
		if not db or not db.enabled or db.auraBarsEnabled ~= true then
			if host then
				host:Hide()
			end
			ClearContainerSlots()
			return
		end
		if GCDM.IsEditModeActive and GCDM:IsEditModeActive() then
			return
		end

		Pixel.Update()
		local configs = CollectSlotConfigs(db)
		if #configs == 0 then
			if host then
				host:Hide()
			end
			ClearContainerSlots()
			return
		end

		local usedContainer = false
		if ProbeContainerAPI() then
			usedContainer = ApplyViaContainer(db, configs)
		end
		if not usedContainer then
			ApplyViaLegacy(db, configs)
		end
	end)
	applying = false
	if not ok and not GCDM._auraSlotsErrOnce then
		GCDM._auraSlotsErrOnce = true
		print("|cff3bb273GCDM|r AuraSlots error: " .. tostring(err))
	end
end

local eventsFrame
local function EnsureEvents()
	if eventsFrame then
		return
	end
	eventsFrame = CreateFrame("Frame")
	eventsFrame:SetScript("OnEvent", function(_, event, unit)
		if event == "UNIT_AURA" and unit and unit ~= "player" then
			return
		end
		ApplyAuraSlots()
	end)
	eventsFrame:RegisterUnitEvent("UNIT_AURA", "player")
	eventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
end

Skin.QueueAuraBarsRelayout = ApplyAuraSlots
Skin.QueueAuraSlotsRelayout = ApplyAuraSlots

GCDM:RegisterRefreshCallback("Skin.AuraSlots", function()
	EnsureEvents()
	ApplyAuraSlots()
end, 49, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.LAYOUT,
	GCDM.CONST.REFRESH.STYLE,
})
