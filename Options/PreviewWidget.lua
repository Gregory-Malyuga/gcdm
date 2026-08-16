local ADDON_NAME, ns = ...
local GCDM = ns.GCDM
local AceGUI = LibStub("AceGUI-3.0")

local TYPE = "GCDMLayoutPreview"
local VERSION = 1
local PLACEHOLDER_ICON = 134400

local function SafeTexturePath(texture)
	if not texture or type(texture.GetTexture) ~= "function" then
		return nil
	end
	local ok, path = pcall(texture.GetTexture, texture)
	if not ok then
		return nil
	end
	if canaccessvalue and not canaccessvalue(path) then
		return nil
	end
	if path == nil then
		return nil
	end
	return path
end

local function CollectViewerTextures(viewerName, limit)
	local paths = {}
	local registry = GCDM and GCDM.ViewerRegistry
	local Skin = GCDM and GCDM.Skin
	local viewer = registry and registry:Get(viewerName)
	local frames = viewer and Skin and Skin.CollectIconFrames and Skin.CollectIconFrames(viewer) or {}
	for i = 1, math.min(#frames, limit) do
		local icon = Skin.GetIconTexture and Skin.GetIconTexture(frames[i])
		paths[#paths + 1] = SafeTexturePath(icon) or PLACEHOLDER_ICON
	end
	return paths
end

local function SetRowTextures(row, paths)
	for i = 1, #row do
		local icon = row[i]
		local path = paths[i]
		icon:SetTexture(path or PLACEHOLDER_ICON)
		icon:SetDesaturated(path == nil)
		icon:SetAlpha(path and 1 or 0.28)
	end
end

local function RefreshPreview(self)
	local db = GCDM and GCDM.GetDB and GCDM:GetDB() or {}
	local viewers = GCDM and GCDM.CONST and GCDM.CONST.VIEWERS or {}
	SetRowTextures(self.essentialIcons, CollectViewerTextures(viewers.ESSENTIAL, #self.essentialIcons))
	SetRowTextures(self.utilityIcons, CollectViewerTextures(viewers.UTILITY, #self.utilityIcons))
	SetRowTextures(self.buffIcons, CollectViewerTextures(viewers.BUFF, #self.buffIcons))

	local color = db.powerBarColor or { r = 0.15, g = 0.55, b = 0.95, a = 1 }
	self.powerFill:SetColorTexture(color.r or 0.15, color.g or 0.55, color.b or 0.95, color.a or 1)
	self.powerFill:SetWidth(math.max(1, self.powerWidth * 0.68))

	local barColor = db.buffBarColor or { r = 0.4, g = 0.6, b = 0.9, a = 1 }
	self.buffBarFill:SetColorTexture(barColor.r or 0.4, barColor.g or 0.6, barColor.b or 0.9, barColor.a or 1)
	self.buffBarFill:SetWidth(math.max(1, self.buffBarWidth * 0.56))
end

local function LayoutPreview(self, width)
	width = math.max(360, width or 620)
	self.frame:SetHeight(196)
	self.frame.height = 196
	self.canvas:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 4, -24)
	self.canvas:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -4, -24)
	self.canvas:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -4, 4)

	local centerX = 0
	for i, icon in ipairs(self.buffIcons) do
		icon:ClearAllPoints()
		icon:SetPoint("TOP", self.canvas, "TOP", centerX + (i - 3) * 27, -12)
	end
	for i, icon in ipairs(self.essentialIcons) do
		icon:ClearAllPoints()
		icon:SetPoint("TOP", self.canvas, "TOP", centerX + (i - 4) * 35, -48)
	end
	for i, icon in ipairs(self.utilityIcons) do
		icon:ClearAllPoints()
		icon:SetPoint("TOP", self.canvas, "TOP", centerX + (i - 3.5) * 29, -88)
	end

	self.powerWidth = math.min(360, width - 90)
	self.powerBackground:SetWidth(self.powerWidth)
	self.buffBarWidth = math.min(250, width - 150)
	self.buffBarBackground:SetWidth(self.buffBarWidth)
	RefreshPreview(self)
end

local methods = {
	OnAcquire = function(self)
		self:SetWidth(620)
		self:SetText("")
		self.frame:Show()
		RefreshPreview(self)
	end,
	OnRelease = function(self)
		self.frame:Hide()
	end,
	OnWidthSet = function(self, width)
		LayoutPreview(self, width)
	end,
	SetText = function(self)
		RefreshPreview(self)
	end,
	SetFontObject = function()
	end,
	SetDisabled = function()
	end,
}

local function CreateIcon(canvas, size)
	local texture = canvas:CreateTexture(nil, "ARTWORK")
	texture:SetSize(size, size)
	texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	local border = canvas:CreateTexture(nil, "BACKGROUND")
	border:SetColorTexture(0, 0, 0, 1)
	border:SetPoint("TOPLEFT", texture, "TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT", 1, -1)
	return texture
end

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -2)
	title:SetText((ns.L and ns.L["LAYOUT_PREVIEW"]) or "Layout preview")

	local canvas = CreateFrame("Frame", nil, frame)
	local background = canvas:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(0.035, 0.04, 0.05, 0.92)

	local essentialIcons = {}
	for i = 1, 7 do
		essentialIcons[i] = CreateIcon(canvas, 32)
	end
	local utilityIcons = {}
	for i = 1, 6 do
		utilityIcons[i] = CreateIcon(canvas, 26)
	end
	local buffIcons = {}
	for i = 1, 5 do
		buffIcons[i] = CreateIcon(canvas, 24)
	end

	local powerBackground = canvas:CreateTexture(nil, "BORDER")
	powerBackground:SetHeight(10)
	powerBackground:SetPoint("BOTTOM", canvas, "BOTTOM", 0, 12)
	powerBackground:SetColorTexture(0.08, 0.08, 0.08, 1)
	local powerFill = canvas:CreateTexture(nil, "ARTWORK")
	powerFill:SetPoint("TOPLEFT", powerBackground, "TOPLEFT")
	powerFill:SetPoint("BOTTOMLEFT", powerBackground, "BOTTOMLEFT")

	local buffBarBackground = canvas:CreateTexture(nil, "BORDER")
	buffBarBackground:SetHeight(12)
	buffBarBackground:SetPoint("BOTTOM", powerBackground, "TOP", 0, 7)
	buffBarBackground:SetColorTexture(0.08, 0.08, 0.08, 1)
	local buffBarFill = canvas:CreateTexture(nil, "ARTWORK")
	buffBarFill:SetPoint("TOPLEFT", buffBarBackground, "TOPLEFT")
	buffBarFill:SetPoint("BOTTOMLEFT", buffBarBackground, "BOTTOMLEFT")

	local widget = {
		type = TYPE,
		frame = frame,
		canvas = canvas,
		essentialIcons = essentialIcons,
		utilityIcons = utilityIcons,
		buffIcons = buffIcons,
		powerBackground = powerBackground,
		powerFill = powerFill,
		buffBarBackground = buffBarBackground,
		buffBarFill = buffBarFill,
		powerWidth = 360,
		buffBarWidth = 250,
	}
	for name, method in pairs(methods) do
		widget[name] = method
	end
	LayoutPreview(widget, 620)
	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(TYPE, Constructor, VERSION)

function ns.BuildLayoutPreviewArgs(order)
	return {
		layoutPreview = {
			type = "description",
			name = "",
			order = order or 1,
			width = "full",
			dialogControl = TYPE,
		},
	}
end
