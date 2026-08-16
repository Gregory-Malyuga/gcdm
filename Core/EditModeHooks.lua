-- Copyright (c) 2026 GCDM authors. All Rights Reserved.
local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local function Const()
	return GCDM.CONST or {}
end

local function CreateCooldownViewerBlocker(panel)
	if not panel or panel.GCDMEditorBlocker then
		return panel and panel.GCDMEditorBlocker
	end

	local blocker = CreateFrame("Frame", nil, panel)
	blocker:SetAllPoints(panel)
	blocker:SetFrameLevel(panel:GetFrameLevel() + 100)
	blocker:EnableMouse(true)

	local background = blocker:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(0.025, 0.025, 0.03, 0.97)

	local title = blocker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("CENTER", blocker, "CENTER", 0, 44)
	title:SetText((ns.L and ns.L["BLIZZARD_EDITOR_BLOCKED_TITLE"]) or "Cooldown Manager")

	local message = blocker:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	message:SetPoint("TOP", title, "BOTTOM", 0, -14)
	message:SetWidth(420)
	message:SetJustifyH("CENTER")
	message:SetText((ns.L and ns.L["BLIZZARD_EDITOR_BLOCKED_DESC"]) or "Configure panel content in GCDM.")

	local openButton = CreateFrame("Button", nil, blocker, "UIPanelButtonTemplate")
	openButton:SetSize(220, 24)
	openButton:SetPoint("TOP", message, "BOTTOM", 0, -24)
	openButton:SetText((ns.L and ns.L["BLIZZARD_EDITOR_OPEN_GCDM"]) or "Open GCDM")
	openButton:SetScript("OnClick", function()
		if HideUIPanel then
			HideUIPanel(panel)
		else
			panel:Hide()
		end
		C_Timer.After(0, function()
			local dialog = LibStub("AceConfigDialog-3.0", true)
			if dialog then
				dialog:Open(ADDON_NAME)
			end
		end)
	end)

	local closeButton = CreateFrame("Button", nil, blocker, "UIPanelButtonTemplate")
	closeButton:SetSize(120, 24)
	closeButton:SetPoint("TOP", openButton, "BOTTOM", 0, -8)
	closeButton:SetText(CLOSE)
	closeButton:SetScript("OnClick", function()
		if HideUIPanel then
			HideUIPanel(panel)
		else
			panel:Hide()
		end
	end)

	panel.GCDMEditorBlocker = blocker
	return blocker
end

local function HookCooldownViewerSettings()
	local panel = _G.CooldownViewerSettings
	if not panel or panel.GCDMLayoutHooked then
		return
	end
	panel.GCDMLayoutHooked = true
	if not panel.HookScript then
		return
	end
	local C = Const()
	local delays = {
		C.LAYOUT_REAPPLY_IMMEDIATE or 0,
		C.LAYOUT_REAPPLY_DELAY or 0.15,
	}
	local blocker = CreateCooldownViewerBlocker(panel)
	panel:HookScript("OnShow", function()
		if blocker then
			blocker:Show()
			blocker:Raise()
		end
		if GCDM.LayoutApply then
			GCDM.LayoutApply.Schedule(delays)
		end
	end)
	panel:HookScript("OnHide", function()
		if blocker then
			blocker:Hide()
		end
		if GCDM.LayoutApply then
			GCDM.LayoutApply.Schedule({ C.LAYOUT_REAPPLY_IMMEDIATE or 0 })
		end
	end)
	if panel:IsShown() and blocker then
		blocker:Show()
		blocker:Raise()
	end
end

local function HookEditModeManager()
	local em = _G.EditModeManagerFrame
	if not em or em.GCDMEditModeHooked then
		return
	end
	em.GCDMEditModeHooked = true
	if em.HookScript then
		em:HookScript("OnShow", function()
			if GCDM._SetEditMode then
				GCDM._SetEditMode(true)
			end
		end)
		em:HookScript("OnHide", function()
			if GCDM._SetEditMode then
				GCDM._SetEditMode(false)
			end
		end)
	end
	if GCDM._IsEditModeUIOpen and GCDM._IsEditModeUIOpen() then
		GCDM._SetEditMode(true)
	end
end

function GCDM._SetupEditModeHooks()
	if EventRegistry and EventRegistry.RegisterCallback then
		EventRegistry:RegisterCallback("EditMode.Enter", function()
			GCDM._SetEditMode(true)
		end, GCDM)
		EventRegistry:RegisterCallback("EditMode.Exit", function()
			GCDM._SetEditMode(false)
		end, GCDM)
	end
	HookEditModeManager()
	if EventUtil and EventUtil.ContinueOnAddOnLoaded then
		EventUtil.ContinueOnAddOnLoaded("Blizzard_EditMode", HookEditModeManager)
	end
	HookCooldownViewerSettings()
	if EventUtil and EventUtil.ContinueOnAddOnLoaded then
		EventUtil.ContinueOnAddOnLoaded("Blizzard_CooldownViewer", HookCooldownViewerSettings)
		EventUtil.ContinueOnAddOnLoaded("Blizzard_CooldownViewerSettings", HookCooldownViewerSettings)
	end
end
