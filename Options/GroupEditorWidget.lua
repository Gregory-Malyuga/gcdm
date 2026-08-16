local ADDON_NAME, ns = ...
local GCDM = ns.GCDM
local AceGUI = LibStub("AceGUI-3.0")

local TYPE = "GCDMGroupEditor"
local VERSION = 1
local ICON_SIZE = 40
local ICON_GAP = 4

local function SetIconVisual(button, entry, active)
	button.entry = entry
	button.Icon:SetTexture(entry and entry.iconID or 134400)
	button.Icon:SetDesaturated(not active)
	button.Icon:SetAlpha(active and 1 or 0.72)
	button.ActiveBorder:SetColorTexture(active and 0.23 or 0.15, active and 0.78 or 0.15, active and 0.45 or 0.15, 1)
	button:SetShown(entry ~= nil)
end

local function FinishDrag(button)
	local owner = button.owner
	local drag = owner and owner.dragging
	if not drag then return end
	owner.dragging = nil
	ResetCursor()
	if InCombatLockdown and InCombatLockdown() then
		owner.Status:SetText(ns.L["CUSTOM_EDITOR_COMBAT"])
		return
	end
	local overActive = MouseIsOver(owner.ActiveArea)
	local overInactive = MouseIsOver(owner.InactiveArea)
	if overActive then
		local insertIndex = owner.hoverActiveIndex or (#GCDM.CustomCatalog:GetGroup(owner.targetKey) + 1)
		if drag.fromActive then
			GCDM.CustomCatalog:Move(owner.targetKey, drag.entry.cooldownID, insertIndex)
		else
			GCDM.CustomCatalog:Assign(owner.targetKey, drag.entry.cooldownID, insertIndex)
		end
	elseif overInactive and drag.fromActive then
		GCDM.CustomCatalog:Remove(owner.targetKey, drag.entry.cooldownID)
	end
end

local function CreateIconButton(parent, owner)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(ICON_SIZE, ICON_SIZE)
	button:RegisterForDrag("LeftButton")
	button.owner = owner

	local border = button:CreateTexture(nil, "BACKGROUND")
	border:SetPoint("TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", 1, -1)
	border:SetColorTexture(0.15, 0.15, 0.15, 1)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.18)

	button.Icon = icon
	button.ActiveBorder = border
	button:SetScript("OnEnter", function(self)
		if self.activeIndex then owner.hoverActiveIndex = self.activeIndex end
		if self.entry then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(self.entry.tooltipSpellID or self.entry.spellID)
			GameTooltip:AddLine(ns.L["CUSTOM_EDITOR_DRAG_HINT"], 0.7, 0.8, 1, true)
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function(self)
		if self.activeIndex and owner.hoverActiveIndex == self.activeIndex then owner.hoverActiveIndex = nil end
		GameTooltip:Hide()
	end)
	button:SetScript("OnDragStart", function(self)
		if not self.entry or (InCombatLockdown and InCombatLockdown()) then return end
		owner.dragging = {
			entry = self.entry,
			fromActive = self.fromActive,
			index = self.activeIndex,
		}
		SetCursor(self.entry.iconID)
	end)
	button:SetScript("OnDragStop", FinishDrag)
	button:SetScript("OnDoubleClick", function(self)
		if not self.entry or (InCombatLockdown and InCombatLockdown()) then return end
		if self.fromActive then
			GCDM.CustomCatalog:Remove(owner.targetKey, self.entry.cooldownID)
		else
			GCDM.CustomCatalog:Assign(owner.targetKey, self.entry.cooldownID)
		end
	end)
	return button
end

local function EnsureButtons(self, pool, parent, count)
	for index = #pool + 1, count do
		pool[index] = CreateIconButton(parent, self)
	end
end

local function RefreshWidget(self)
	if not self.targetKey or not GCDM.CustomCatalog then return end
	if not GCDM.CustomCatalog:IsReady() then
		for _, button in ipairs(self.activeButtons) do button:Hide() end
		for _, button in ipairs(self.inactiveButtons) do button:Hide() end
		self.Status:SetText(ns.L["CUSTOM_EDITOR_UNAVAILABLE"])
		return
	end
	local active = GCDM.CustomCatalog:GetActiveEntries(self.targetKey)
	local inactive = GCDM.CustomCatalog:GetInactiveEntries(self.targetKey)
	EnsureButtons(self, self.activeButtons, self.ActiveArea, #active)
	EnsureButtons(self, self.inactiveButtons, self.InactiveChild, #inactive)
	local activeColumns = math.max(1, math.floor(((self.frame.width or 760) - 20) / (ICON_SIZE + ICON_GAP)))

	for index, button in ipairs(self.activeButtons) do
		local entry = active[index]
		SetIconVisual(button, entry, true)
		button.fromActive = true
		button.activeIndex = index
		if entry then
			local row = math.floor((index - 1) / activeColumns)
			local column = (index - 1) % activeColumns
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", self.ActiveArea, "TOPLEFT", column * (ICON_SIZE + ICON_GAP), -row * (ICON_SIZE + ICON_GAP))
		end
	end

	local columns = math.max(1, math.floor(((self.frame.width or 760) - 30) / (ICON_SIZE + ICON_GAP)))
	for index, button in ipairs(self.inactiveButtons) do
		local entry = inactive[index]
		SetIconVisual(button, entry, false)
		button.fromActive = false
		button.activeIndex = nil
		if entry then
			local row = math.floor((index - 1) / columns)
			local column = (index - 1) % columns
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", self.InactiveChild, "TOPLEFT", column * (ICON_SIZE + ICON_GAP), -row * (ICON_SIZE + ICON_GAP))
		end
	end
	local rows = math.max(1, math.ceil(#inactive / columns))
	self.InactiveChild:SetHeight(rows * (ICON_SIZE + ICON_GAP))
	self.Status:SetText(string.format(ns.L["CUSTOM_EDITOR_COUNTS"], #active, #inactive))
end

local function LayoutWidget(self, width)
	width = math.max(420, width or 760)
	self.frame:SetHeight(420)
	self.frame.height = 420
	self.ActiveArea:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 4, -42)
	self.ActiveArea:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -4, -42)
	self.InactiveArea:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 4, -200)
	self.InactiveArea:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -4, 6)
	self.InactiveScroll:SetAllPoints(self.InactiveArea)
	self.InactiveChild:SetWidth(width - 30)
	RefreshWidget(self)
end

local methods = {
	OnAcquire = function(self)
		self.dragging = nil
		self.hoverActiveIndex = nil
		self.InactiveScroll:SetVerticalScroll(0)
		self.frame:Show()
		self:SetWidth(760)
	end,
	OnRelease = function(self)
		self.dragging = nil
		self.hoverActiveIndex = nil
		self.targetKey = nil
		self.InactiveScroll:SetVerticalScroll(0)
		for _, button in ipairs(self.activeButtons) do
			button.entry, button.activeIndex, button.fromActive = nil, nil, nil
		end
		for _, button in ipairs(self.inactiveButtons) do
			button.entry, button.activeIndex, button.fromActive = nil, nil, nil
		end
		ResetCursor()
		self.frame:Hide()
	end,
	OnWidthSet = function(self, width)
		LayoutWidget(self, width)
	end,
	SetText = function(self, targetKey)
		self.targetKey = targetKey
		RefreshWidget(self)
	end,
	SetFontObject = function()
	end,
	SetDisabled = function()
	end,
}

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local activeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	activeLabel:SetPoint("TOPLEFT", 4, -4)
	activeLabel:SetText(ns.L["CUSTOM_EDITOR_ACTIVE"])
	local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	status:SetPoint("TOPRIGHT", -4, -6)

	local activeArea = CreateFrame("Frame", nil, frame)
	activeArea:SetHeight(132)
	activeArea:EnableMouse(true)
	local activeBG = activeArea:CreateTexture(nil, "BACKGROUND")
	activeBG:SetAllPoints()
	activeBG:SetColorTexture(0.04, 0.09, 0.065, 0.95)

	local inactiveLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	inactiveLabel:SetPoint("TOPLEFT", 4, -178)
	inactiveLabel:SetText(ns.L["CUSTOM_EDITOR_INACTIVE"])
	local inactiveArea = CreateFrame("Frame", nil, frame)
	inactiveArea:EnableMouse(true)
	local inactiveBG = inactiveArea:CreateTexture(nil, "BACKGROUND")
	inactiveBG:SetAllPoints()
	inactiveBG:SetColorTexture(0.045, 0.045, 0.05, 0.95)

	local scroll = CreateFrame("ScrollFrame", nil, inactiveArea, "UIPanelScrollFrameTemplate")
	local child = CreateFrame("Frame", nil, scroll)
	child:SetHeight(1)
	scroll:SetScrollChild(child)

	local widget = {
		type = TYPE,
		frame = frame,
		ActiveArea = activeArea,
		InactiveArea = inactiveArea,
		InactiveScroll = scroll,
		InactiveChild = child,
		Status = status,
		activeButtons = {},
		inactiveButtons = {},
	}
	for name, method in pairs(methods) do widget[name] = method end
	LayoutWidget(widget, 760)
	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(TYPE, Constructor, VERSION)

function ns.BuildCustomGroupEditorArgs(targetKey, order)
	return {
		customGroupEditor = {
			type = "description",
			name = targetKey,
			order = order or 900,
			width = "full",
			dialogControl = TYPE,
		},
	}
end
