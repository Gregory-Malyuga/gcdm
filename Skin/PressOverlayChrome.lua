local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local PRESS_R, PRESS_G, PRESS_B, PRESS_A = 1.0, 0.82, 0.12, 0.40

local PO = Skin._PressOverlayState
if not PO then
	PO = {
		overlays = setmetatable({}, { __mode = "k" }),
		spellCombos = {},
		spellFrames = {},
		mapCacheVer = -1,
		hooksInstalled = false,
		pollElapsed = 0,
		lastPressedSig = "",
		syncTicks = 0,
		pollFrame = CreateFrame("Frame"),
	}
	PO.pollFrame:Hide()
	Skin._PressOverlayState = PO
end

local POLL_INTERVAL = 0.05

function Skin.PressOverlayWantLog()
	local db = GCDM:GetDB()
	return db and db.pressOverlayDebug == true
end

function Skin.PressOverlayLog(msg)
	if not Skin.PressOverlayWantLog() then
		return
	end
	print("|cff3bb273GCDM Press|r " .. tostring(msg))
end

function Skin.PressOverlayIsEnabled()
	local db = GCDM:GetDB()
	return db and db.enabled and db.pressOverlayEnabled ~= false
end

local function ApplyPressTint(tex)
	if not tex then
		return
	end
	tex:SetColorTexture(PRESS_R, PRESS_G, PRESS_B, PRESS_A)
	tex:SetBlendMode("BLEND")
end

local function GetOrCreateOverlay(frame)
	local ov = PO.overlays[frame]
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
	PO.overlays[frame] = ov
	Skin.PressOverlayLog(string.format("overlay created for frame=%s", tostring(frame:GetName() or frame)))
	return ov
end

function Skin.PressOverlayShow(frame)
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

function Skin.PressOverlayHide(frame)
	local ov = frame and PO.overlays[frame]
	if ov then
		ov:Hide()
	end
end

function Skin.PressOverlayHideAll()
	for _, ov in pairs(PO.overlays) do
		ov:Hide()
	end
end

function Skin.PressOverlayPollInterval()
	return POLL_INTERVAL
end
