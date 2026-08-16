local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Pixel = GCDM.Pixel
local Skin = GCDM.Skin

local CustomPanels = {}
GCDM.CustomPanels = CustomPanels

local abilityPanels = {}
local auraPanels = {}
local combatPending = false
local eventFrame

local PANEL_VIEWER = {
	essential = GCDM.CONST.VIEWERS.ESSENTIAL,
	utility = GCDM.CONST.VIEWERS.UTILITY,
	buff = GCDM.CONST.VIEWERS.BUFF,
	buffBar = GCDM.CONST.VIEWERS.BUFF_BAR,
}

local function InCombat()
	return InCombatLockdown and InCombatLockdown()
end

local function ApplyPoint(frame, cfg)
	cfg = cfg or {}
	frame:ClearAllPoints()
	local point = cfg.point or "CENTER"
	frame:SetPoint(point, UIParent, point, Pixel.Snap(cfg.x or 0), Pixel.Snap(cfg.y or 0))
end

local function AddBorder(frame, size, color)
	if not frame.GCDMCustomBorder then
		local border = CreateFrame("Frame", nil, frame)
		border:SetAllPoints()
		border:SetFrameLevel(frame:GetFrameLevel() + 5)
		for _, edge in ipairs({ "Top", "Bottom", "Left", "Right" }) do
			border[edge] = border:CreateTexture(nil, "OVERLAY")
			border[edge]:SetColorTexture(0, 0, 0, 1)
		end
		frame.GCDMCustomBorder = border
	end
	local border = frame.GCDMCustomBorder
	size = math.max(1, Pixel.Snap(size or 1))
	color = color or { r = 0, g = 0, b = 0, a = 1 }
	for _, edge in ipairs({ "Top", "Bottom", "Left", "Right" }) do
		border[edge]:ClearAllPoints()
		border[edge]:SetColorTexture(color.r or 0, color.g or 0, color.b or 0, color.a or 1)
	end
	border.Top:SetPoint("TOPLEFT")
	border.Top:SetPoint("TOPRIGHT")
	border.Top:SetHeight(size)
	border.Bottom:SetPoint("BOTTOMLEFT")
	border.Bottom:SetPoint("BOTTOMRIGHT")
	border.Bottom:SetHeight(size)
	border.Left:SetPoint("TOPLEFT")
	border.Left:SetPoint("BOTTOMLEFT")
	border.Left:SetWidth(size)
	border.Right:SetPoint("TOPRIGHT")
	border.Right:SetPoint("BOTTOMRIGHT")
	border.Right:SetWidth(size)
end

local function CreateAbilityButton(parent)
	local button = CreateFrame("Button", nil, parent)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints()
	cooldown:SetDrawEdge(false)
	cooldown:SetHideCountdownNumbers(false)
	button.Icon = icon
	button.Cooldown = cooldown
	button:SetScript("OnEnter", function(self)
		if not self.spellID then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetSpellByID(self.tooltipSpellID or self.spellID)
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)
	return button
end

local function UpdateAbilityCooldown(button)
	if not button.spellID or not C_Spell or not C_Spell.GetSpellCooldownDuration then
		button.Cooldown:Clear()
		return
	end
	local durationGetter = button.hasCharges and C_Spell.GetSpellChargeDuration or C_Spell.GetSpellCooldownDuration
	local ok, duration
	if button.hasCharges then
		ok, duration = pcall(durationGetter, button.spellID)
	else
		ok, duration = pcall(durationGetter, button.spellID, true)
	end
	if ok and duration then
		button.Cooldown:SetCooldownFromDurationObject(duration, true)
	else
		button.Cooldown:Clear()
	end
end

local function EnsureAbilityPanel(key)
	local panel = abilityPanels[key]
	if panel then return panel end
	panel = CreateFrame("Frame", "GCDMCustom" .. key:gsub("^%l", string.upper) .. "Panel", UIParent)
	panel.buttons = {}
	abilityPanels[key] = panel
	return panel
end

local function LayoutAbilityPanel(key, db)
	local panel = EnsureAbilityPanel(key)
	local entries = GCDM.CustomCatalog:GetActiveEntries(key)
	local size = key == "essential" and db.sizeEssential or db.sizeUtility
	local width = Pixel.Snap((size and size.w) or 40)
	local height = Pixel.Snap((size and size.h) or 36)
	local spacing = Pixel.Snap(db.spacing or 0)
	local columns = key == "essential" and math.max(1, db.maxIconsPerRow or 7) or math.max(1, #entries)
	local rows = math.max(1, math.ceil(#entries / columns))
	local usedColumns = math.max(1, math.min(#entries, columns))
	panel:SetSize((usedColumns * width) + ((usedColumns - 1) * spacing), (rows * height) + ((rows - 1) * spacing))
	ApplyPoint(panel, db.viewerPos and db.viewerPos[key])
	for index, entry in ipairs(entries) do
		local button = panel.buttons[index] or CreateAbilityButton(panel)
		panel.buttons[index] = button
		button.spellID = entry.spellID
		button.tooltipSpellID = entry.tooltipSpellID
		button.hasCharges = entry.hasCharges
		button.cooldownID = entry.cooldownID
		button.Icon:SetTexture(entry.iconID)
		local zoom = math.max(0, math.min(0.25, db.iconZoom or 0))
		button.Icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
		button:SetSize(width, height)
		button:ClearAllPoints()
		local row = math.floor((index - 1) / columns)
		local column = (index - 1) % columns
		button:SetPoint("TOPLEFT", panel, "TOPLEFT", column * (width + spacing), -row * (height + spacing))
		AddBorder(button, db.borderSize, db.borderColor)
		UpdateAbilityCooldown(button)
		button:Show()
	end
	for index = #entries + 1, #panel.buttons do
		panel.buttons[index]:Hide()
	end
	panel:SetShown(db.customPanelsEnabled and #entries > 0)
end

local function InitializeAuraIcon(button)
	button:SetSize(36, 32)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints()
	cooldown:SetDrawEdge(false)
	local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	count:SetPoint("BOTTOMRIGHT", -1, 1)
	button:SetIcon(icon)
	button:SetDurationCooldown(cooldown)
	button:SetApplicationCount(count, {})
	button.Icon = icon
end

local function InitializeAuraBar(button)
	button:SetSize(220, 16)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(16, 16)
	icon:SetPoint("RIGHT", button, "LEFT", -1, 0)
	local bar = CreateFrame("StatusBar", nil, button)
	bar:SetAllPoints()
	bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	bar:SetStatusBarColor(0.4, 0.6, 0.9, 1)
	local name = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	name:SetPoint("LEFT", 4, 0)
	local duration = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	duration:SetPoint("RIGHT", -4, 0)
	button:SetIcon(icon)
	button:SetSpellName(name)
	button:SetDurationText(duration, {})
	button:SetDurationBar(bar, {})
	button.Icon = icon
	button.Bar = bar
end

local function EnsureAuraPanel(key)
	local panel = auraPanels[key]
	if panel then return panel end
	if InCombat() then return nil end
	if C_AddOns and C_AddOns.LoadAddOn then
		pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer")
	end
	local container = CreateFrame("AuraContainer", "GCDMCustom" .. key:gsub("^%l", string.upper) .. "Container", UIParent, "CustomAuraContainerTemplate")
	container:SetUnit("player")
	container:SetEnabled(true)
	panel = { frame = container, slots = {}, buttons = {}, signatures = {}, key = key }
	auraPanels[key] = panel
	return panel
end

local function EnsureAuraSlots(panel, count, isBar)
	for index = #panel.slots + 1, count do
		local slotKey = panel.key .. tostring(index)
		local button = panel.frame:AddAuraSlot(slotKey, "HELPFUL", {
			candidateFilters = { includeSpellIDs = {} },
			initializeFrame = isBar and InitializeAuraBar or InitializeAuraIcon,
		})
		panel.slots[index] = slotKey
		panel.buttons[index] = button
	end
end

local function LayoutAuraPanel(key, db)
	local panel = EnsureAuraPanel(key)
	if not panel then combatPending = true return end
	local entries = GCDM.CustomCatalog:GetActiveEntries(key)
	local isBar = key == "buffBar"
	EnsureAuraSlots(panel, #entries, isBar)
	ApplyPoint(panel.frame, db.viewerPos and db.viewerPos[key])
	local spacing = isBar and Pixel.Snap(db.buffBarSpacing or 0) or Pixel.Snap(db.spacing or 0)
	for index, slotKey in ipairs(panel.slots) do
		local entry = entries[index]
		local filters = { includeSpellIDs = {} }
		local signatureParts = {}
		if entry then
			filters.includeSpellIDs[entry.spellID] = true
			signatureParts[#signatureParts + 1] = tostring(entry.spellID)
			for _, spellID in ipairs(entry.linkedSpellIDs or {}) do
				if type(spellID) == "number" then
					filters.includeSpellIDs[spellID] = true
					signatureParts[#signatureParts + 1] = tostring(spellID)
				end
			end
		end
		table.sort(signatureParts)
		local signature = table.concat(signatureParts, ",")
		if panel.signatures[index] ~= signature then
			panel.signatures[index] = signature
			panel.frame:SetAuraSlotCandidateFilters(slotKey, filters)
		end
		local button = panel.buttons[index]
		if button then
			button:ClearAllPoints()
			if isBar then
				local width = Pixel.Snap(db.buffBarWidth or 220)
				local height = Pixel.Snap(db.buffBarHeight or 16)
				button:SetSize(width, height)
				if button.Icon then button.Icon:SetSize(height, height) end
				button:SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 0, -((index - 1) * (height + spacing)))
			else
				local size = db.sizeBuff or { w = 36, h = 32 }
				local width, height = Pixel.Snap(size.w or 36), Pixel.Snap(size.h or 32)
				button:SetSize(width, height)
				button:SetPoint("TOPLEFT", panel.frame, "TOPLEFT", (index - 1) * (width + spacing), 0)
			end
		end
	end
	panel.frame:SetEnabled(db.customPanelsEnabled)
end

local function ApplyNativeVisibility(db)
	if not GCDM.ViewerRegistry then return end
	local catalogReady = GCDM.CustomCatalog and GCDM.CustomCatalog:IsReady()
	local hide = db.enabled and db.customPanelsEnabled and db.customGroupsSeeded and catalogReady and db.hideBlizzardViewers
	GCDM.ViewerRegistry:SetCustomVisibility(hide)
end

function CustomPanels:Refresh()
	local db = GCDM:GetDB()
	if not db then return end
	if InCombat() then
		combatPending = true
		return
	end
	combatPending = false
	ApplyNativeVisibility(db)
	local catalogReady = GCDM.CustomCatalog and GCDM.CustomCatalog:IsReady()
	local effectiveEnabled = db.enabled and db.customPanelsEnabled and db.customGroupsSeeded and catalogReady
	if not effectiveEnabled then
		for _, panel in pairs(abilityPanels) do panel:Hide() end
		for _, panel in pairs(auraPanels) do panel.frame:SetEnabled(false) end
		return
	end
	Pixel.Update()
	LayoutAbilityPanel("essential", db)
	LayoutAbilityPanel("utility", db)
	LayoutAuraPanel("buff", db)
	LayoutAuraPanel("buffBar", db)
	if Skin.QueuePowerBarRelayout then Skin.QueuePowerBarRelayout() end
end

function CustomPanels:UpdateCooldowns()
	for _, panel in pairs(abilityPanels) do
		for _, button in ipairs(panel.buttons) do
			if button:IsShown() then UpdateAbilityCooldown(button) end
		end
	end
end

function CustomPanels:GetFrame(key)
	local ability = abilityPanels[key]
	if ability then return ability end
	local aura = auraPanels[key]
	return aura and aura.frame or nil
end

eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_ENABLED" then
		if combatPending then CustomPanels:Refresh() end
	else
		CustomPanels:UpdateCooldowns()
	end
end)

GCDM:RegisterRefreshCallback("Groups.CustomPanels", function(scope)
	if scope == GCDM.CONST.REFRESH.STYLE then
		CustomPanels:Refresh()
	else
		CustomPanels:Refresh()
	end
end, 65, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
	GCDM.CONST.REFRESH.LAYOUT,
	GCDM.CONST.REFRESH.GROUPS,
})
