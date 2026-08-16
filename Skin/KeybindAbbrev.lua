local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local MOD_ABBREV = {
	SHIFT = "S",
	CTRL = "C",
	ALT = "A",
	META = "M",
}

local KEY_ABBREV = {
	MOUSEWHEELUP = "MwU",
	MOUSEWHEELDOWN = "MwD",
	BUTTON1 = "M1",
	BUTTON2 = "M2",
	BUTTON3 = "M3",
	BUTTON4 = "M4",
	BUTTON5 = "M5",
	NUMPADMULTIPLY = "N*",
	NUMPADDIVIDE = "N/",
	NUMPADPLUS = "N+",
	NUMPADMINUS = "N-",
	NUMPADDECIMAL = "NDEL",
	NUMPADENTER = "NEnt",
	NUMPAD0 = "N0",
	NUMPAD1 = "N1",
	NUMPAD2 = "N2",
	NUMPAD3 = "N3",
	NUMPAD4 = "N4",
	NUMPAD5 = "N5",
	NUMPAD6 = "N6",
	NUMPAD7 = "N7",
	NUMPAD8 = "N8",
	NUMPAD9 = "N9",
	CAPSLOCK = "CpLk",
	BACKSPACE = "BkSp",
	DELETE = "DEL",
	INSERT = "Ins",
	PAGEUP = "PU",
	PAGEDOWN = "PD",
	ENTER = "Ent",
	HOME = "Hm",
	SPACE = "SPC",
	END = "End",
	UP = "Up",
	DOWN = "Dn",
	LEFT = "Lt",
	RIGHT = "Rt",
	TAB = "Tab",
	ESCAPE = "Esc",
}

function Skin.FormatRawKey(key)
	if type(key) ~= "string" or key == "" then
		return nil
	end
	local modPrefix = ""
	local remaining = key
	while true do
		local hyphen = remaining:find("-", 1, true)
		if not hyphen then
			break
		end
		local token = remaining:sub(1, hyphen - 1)
		local abbrev = MOD_ABBREV[token]
		if not abbrev then
			break
		end
		modPrefix = modPrefix .. abbrev
		remaining = remaining:sub(hyphen + 1)
	end
	local baseAbbrev = KEY_ABBREV[remaining]
	if not baseAbbrev then
		local n = remaining:match("^BUTTON(%d+)$")
		baseAbbrev = n and ("M" .. n) or remaining
	end
	return modPrefix .. baseAbbrev
end

function Skin.BindingKeys(command)
	if not command or not GetBindingKey then
		return {}
	end
	return { GetBindingKey(command) }
end
