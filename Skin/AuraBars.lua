local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

-- Custom duration bars for selected buff/debuff spell IDs (12.1 Duration Objects).
-- Width matches Essential; stacked above PowerBar (or Essential if power off).

local host
local bars = {} -- [spellID] = { frame=StatusBar, spellID= }
local eventsFrame
local applying = false

local function ParseSpellList(str)
	local out = {}
	if type(str) ~= "string" or str == "" then
		return out
	end
	for part in string.gmatch(str, "[^,%s]+") do
		local id = tonumber(part)
		if id and id > 0 then
			out[#out + 1] = id
		end
	end
	return out
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
	host = CreateFrame("Frame", "GCDM_AuraBarHost", UIParent)
	host:SetSize(200, 10)
	return host
end

local function EnsureAuraBar(spellID)
	local entry = bars[spellID]
	if entry then
		return entry
	end
	local bar = CreateFrame("StatusBar", nil, EnsureHost())
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bar.GCDMBg = bg
	local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
	border:SetAllPoints()
	border:SetFrameLevel((bar:GetFrameLevel() or 0) + 5)
	bar.GCDMBorder = border
	local fs = bar:CreateFontString(nil, "OVERLAY")
	fs:SetPoint("LEFT", 4, 0)
	fs:SetJustifyH("LEFT")
	bar.GCDMText = fs
	local timer = bar:CreateFontString(nil, "OVERLAY")
	timer:SetPoint("RIGHT", -4, 0)
	timer:SetJustifyH("RIGHT")
	bar.GCDMTimer = timer
	entry = { frame = bar, spellID = spellID }
	bars[spellID] = entry
	return entry
end

local function StyleAuraBar(bar, db, height)
	local texName = db.auraBarTexture or db.buffBarTexture or "Solid"
	local bgName = db.auraBarBackgroundTexture or db.buffBarBackgroundTexture or texName
	local tex = (Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(texName)) or GCDM.CONST.TEX_WHITE8X8
	local bgPath = (Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(bgName)) or GCDM.CONST.TEX_WHITE8X8
	local fill = db.auraBarColor or db.buffBarColor or { r = 0.4, g = 0.6, b = 0.9, a = 1 }
	local bgc = db.auraBarBackgroundColor or db.buffBarBackgroundColor or { r = 0.1, g = 0.1, b = 0.1, a = 1 }

	bar:SetHeight(Pixel.Snap(height))
	bar:SetStatusBarTexture(tex)
	local st = bar:GetStatusBarTexture()
	if st then
		if Pixel.DisableTextureSnap then
			Pixel.DisableTextureSnap(st)
		end
		st:SetVertexColor(fill.r or 0.4, fill.g or 0.6, fill.b or 0.9, fill.a or 1)
	end
	bar:SetStatusBarColor(fill.r or 0.4, fill.g or 0.6, fill.b or 0.9, fill.a or 1)
	bar.GCDMBg:SetTexture(bgPath)
	bar.GCDMBg:SetVertexColor(bgc.r or 0.1, bgc.g or 0.1, bgc.b or 0.1, bgc.a or 1)

	-- Thin strip: own border (default 0), not icon borderSize.
	local size = db.auraBarBorderSize
	if size == nil then
		size = 0
	end
	local bc = db.borderColor or { r = 0, g = 0, b = 0, a = 1 }
	if size <= 0 then
		bar.GCDMBorder:Hide()
	else
		local backdrop = {
			edgeFile = GCDM.CONST.TEX_WHITE8X8,
			edgeSize = size,
		}
		pcall(bar.GCDMBorder.SetBackdrop, bar.GCDMBorder, backdrop)
		pcall(bar.GCDMBorder.SetBackdropBorderColor, bar.GCDMBorder, bc.r or 0, bc.g or 0, bc.b or 0, bc.a or 1)
		bar.GCDMBorder:Show()
	end

	local fontPath = Skin.FetchFont and Skin.FetchFont(db.textFont or "Expressway") or GCDM.CONST.FONT_PATH
	local fontSize = db.auraBarFontSize or 10
	local outline = db.textOutline or "OUTLINE"
	if outline == "NONE" then
		outline = ""
	end
	pcall(bar.GCDMText.SetFont, bar.GCDMText, fontPath, fontSize, outline)
	pcall(bar.GCDMTimer.SetFont, bar.GCDMTimer, fontPath, fontSize, outline)
	local tc = db.auraBarTextColor or { r = 1, g = 1, b = 1, a = 1 }
	bar.GCDMText:SetTextColor(tc.r or 1, tc.g or 1, tc.b or 1, tc.a or 1)
	bar.GCDMTimer:SetTextColor(tc.r or 1, tc.g or 1, tc.b or 1, tc.a or 1)
	local showName = db.auraBarShowName == true
	bar.GCDMText:SetShown(showName)
	bar.GCDMTimer:SetShown(false)
end

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

local function UpdateAuraBar(entry, db)
	local bar = entry.frame
	local spellID = entry.spellID
	local data = FindPlayerAuraData(spellID)
	if not data then
		bar:Hide()
		return false
	end

	StyleAuraBar(bar, db, db.auraBarHeight or 6)

	if db.auraBarShowName == true then
		local labeled = false
		if data.name ~= nil then
			local ok = pcall(bar.GCDMText.SetText, bar.GCDMText, data.name)
			labeled = ok
		end
		if not labeled then
			local sn
			if C_Spell and C_Spell.GetSpellName then
				local ok, name = pcall(C_Spell.GetSpellName, spellID)
				if ok then
					sn = name
				end
			end
			bar.GCDMText:SetText(sn or tostring(spellID))
		end
		bar.GCDMText:Show()
	else
		bar.GCDMText:SetText("")
		bar.GCDMText:Hide()
	end
	bar.GCDMTimer:SetText("")
	bar.GCDMTimer:Hide()

	local dur
	if C_UnitAuras and C_UnitAuras.GetAuraDuration and data.auraInstanceID then
		local ok, d = pcall(C_UnitAuras.GetAuraDuration, "player", data.auraInstanceID)
		if ok then
			dur = d
		end
	end

	if dur and bar.SetTimerDuration then
		local dir = Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime
		pcall(bar.SetTimerDuration, bar, dur, nil, dir)
	else
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(1)
	end
	bar:Show()
	return true
end

local function LayoutAuraBars(db, active)
	local h = EnsureHost()
	local width = ResolveWidth(db)
	local height = Pixel.Snap(db.auraBarHeight or 6)
	local spacing = Pixel.Snap(db.auraBarSpacing or 1)
	local gap = Pixel.Snap(db.auraBarGap or 2)
	local count = #active
	local hostH = 1
	if count > 0 then
		hostH = (count * height) + ((count - 1) * spacing)
	end
	h:SetSize(width, hostH)

	for i = 1, count do
		local bar = active[i].frame
		bar:ClearAllPoints()
		bar:SetWidth(width)
		local y = -((i - 1) * (height + spacing))
		bar:SetPoint("TOPLEFT", h, "TOPLEFT", 0, y)
		bar:SetPoint("TOPRIGHT", h, "TOPRIGHT", 0, y)
	end

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

local function ApplyAuraBars()
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
			return
		end
		if GCDM.IsEditModeActive and GCDM:IsEditModeActive() then
			return
		end

		Pixel.Update()
		EnsureHost()
		local ids = ParseSpellList(db.auraBarSpellIDs or "")
		local active = {}
		local seen = {}
		for i = 1, #ids do
			local spellID = ids[i]
			seen[spellID] = true
			local entry = EnsureAuraBar(spellID)
			if UpdateAuraBar(entry, db) then
				active[#active + 1] = entry
			end
		end
		for spellID, entry in pairs(bars) do
			if not seen[spellID] then
				entry.frame:Hide()
			end
		end
		LayoutAuraBars(db, active)
	end)
	applying = false
	if not ok and not GCDM._auraBarsErrOnce then
		GCDM._auraBarsErrOnce = true
		print("|cff3bb273GCDM|r AuraBars error: " .. tostring(err))
	end
end

local function EnsureEvents()
	if eventsFrame then
		return
	end
	eventsFrame = CreateFrame("Frame")
	eventsFrame:SetScript("OnEvent", function(_, event, unit)
		if event == "UNIT_AURA" and unit and unit ~= "player" then
			return
		end
		ApplyAuraBars()
	end)
	eventsFrame:RegisterUnitEvent("UNIT_AURA", "player")
	eventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
end

Skin.QueueAuraBarsRelayout = ApplyAuraBars

GCDM:RegisterRefreshCallback("Skin.AuraBars", function()
	EnsureEvents()
	ApplyAuraBars()
end, 49, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.LAYOUT,
	GCDM.CONST.REFRESH.STYLE,
})
