local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

-- Per-viewer text / keybind migration chunks (called from RunMigrations).

function GCDM.MigratePerViewerText(p)
	if p._gcdmPerViewerText then
		return
	end
	p.textByViewer = p.textByViewer or {}
	local function copyColor(c, fb)
		fb = fb or { r = 1, g = 1, b = 1, a = 1 }
		if type(c) ~= "table" then
			return { r = fb.r, g = fb.g, b = fb.b, a = fb.a }
		end
		return { r = c.r or fb.r, g = c.g or fb.g, b = c.b or fb.b, a = c.a or fb.a }
	end
	local function ensureIcon(key)
		local st = p.textByViewer[key]
		if type(st) ~= "table" then
			st = {}
			p.textByViewer[key] = st
		end
		st.textFont = st.textFont or p.textFont or "Expressway"
		if st.textOutline == nil then
			st.textOutline = p.textOutline or "OUTLINE"
		end
		st.cooldownFontSize = st.cooldownFontSize or p.cooldownFontSize or 14
		st.cooldownTextColor = copyColor(st.cooldownTextColor or p.cooldownTextColor)
		st.cooldownTextPoint = st.cooldownTextPoint or p.cooldownTextPoint or "CENTER"
		st.cooldownTextOffsetX = st.cooldownTextOffsetX or p.cooldownTextOffsetX or 0
		st.cooldownTextOffsetY = st.cooldownTextOffsetY or p.cooldownTextOffsetY or 0
		st.stackFontSize = st.stackFontSize or p.stackFontSize or 12
		st.stackTextColor = copyColor(st.stackTextColor or p.stackTextColor)
		st.stackTextPoint = st.stackTextPoint or p.stackTextPoint or "BOTTOMRIGHT"
		st.stackTextOffsetX = st.stackTextOffsetX or p.stackTextOffsetX or -1
		st.stackTextOffsetY = st.stackTextOffsetY or p.stackTextOffsetY or 1
	end
	ensureIcon("EssentialCooldownViewer")
	ensureIcon("UtilityCooldownViewer")
	ensureIcon("BuffIconCooldownViewer")
	do
		local st = p.textByViewer.BuffBarCooldownViewer
		if type(st) ~= "table" then
			st = {}
			p.textByViewer.BuffBarCooldownViewer = st
		end
		st.textFont = st.textFont or p.textFont or "Expressway"
		if st.textOutline == nil then
			st.textOutline = p.textOutline or "OUTLINE"
		end
		st.nameFontSize = st.nameFontSize or p.stackFontSize or 12
		st.durationFontSize = st.durationFontSize or p.cooldownFontSize or 14
		st.nameTextColor = copyColor(st.nameTextColor or p.stackTextColor)
		st.durationTextColor = copyColor(st.durationTextColor or p.cooldownTextColor)
		st.nameTextOffsetX = st.nameTextOffsetX or 4
		st.nameTextOffsetY = st.nameTextOffsetY or 0
		st.durationTextOffsetX = st.durationTextOffsetX or -4
		st.durationTextOffsetY = st.durationTextOffsetY or 0
	end
	if p.powerBarFont == nil then
		p.powerBarFont = p.textFont or "Expressway"
	end
	if p.powerBarTextOutline == nil then
		p.powerBarTextOutline = p.textOutline or "OUTLINE"
	end
	p._gcdmPerViewerText = true
end

function GCDM.MigrateKeybindTextDefaults(p)
	if p._gcdmKeybindTextDefaults then
		return
	end
	p.textByViewer = p.textByViewer or {}
	local function ensureKeybind(key)
		local st = p.textByViewer[key]
		if type(st) ~= "table" then
			st = {}
			p.textByViewer[key] = st
		end
		st.keybindFontSize = st.keybindFontSize or 11
		if type(st.keybindTextColor) ~= "table" then
			st.keybindTextColor = { r = 1, g = 1, b = 1, a = 1 }
		else
			st.keybindTextColor = {
				r = st.keybindTextColor.r or 1,
				g = st.keybindTextColor.g or 1,
				b = st.keybindTextColor.b or 1,
				a = st.keybindTextColor.a or 1,
			}
		end
		st.keybindTextPoint = st.keybindTextPoint or "TOPLEFT"
		st.keybindTextOffsetX = st.keybindTextOffsetX or 2
		st.keybindTextOffsetY = st.keybindTextOffsetY or -1
	end
	ensureKeybind("EssentialCooldownViewer")
	ensureKeybind("UtilityCooldownViewer")
	if p.keybindTextEnabled == nil then
		p.keybindTextEnabled = true
	end
	if p.pressOverlayEnabled == nil then
		p.pressOverlayEnabled = true
	end
	p._gcdmKeybindTextDefaults = true
end
