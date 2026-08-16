local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
GCDM.Skin = GCDM.Skin or {}
local Skin = GCDM.Skin

local LSM = LibStub("LibSharedMedia-3.0", true)
local EXPRESSWAY = "Expressway"
-- Prefer Bold: ElvUI's bundled Expressway reads heavier than SharedMedia "Regular".
local EXPRESSWAY_SOURCES = {
	"Expressway, Bold",
	"Expressway Bold",
	"Expressway, Regular",
	"Expressway Regular",
}
local EXPRESSWAY_FALLBACK_PATH = [[Interface\AddOns\SharedMediaAdditionalFonts\fonts\Expressway-Bold.ttf]]

function Skin.EnsureLSM()
	if LSM then
		return LSM
	end
	LSM = LibStub("LibSharedMedia-3.0", true)
	return LSM
end

local function FontLocaleBits(lib)
	local bits = 0
	if lib.LOCALE_BIT_western then
		bits = bits + lib.LOCALE_BIT_western
	end
	if lib.LOCALE_BIT_ruRU then
		bits = bits + lib.LOCALE_BIT_ruRU
	end
	return bits
end

-- ElvUI's Expressway is a heavier cut; map our "Expressway" alias to Bold when available.
function Skin.RegisterExpresswayAlias()
	if Skin._registeringExpressway then
		return false
	end
	local lib = Skin.EnsureLSM()
	if not lib then
		return false
	end
	local mt = (lib.MediaType and lib.MediaType.FONT) or "font"
	local path
	for i = 1, #EXPRESSWAY_SOURCES do
		local src = EXPRESSWAY_SOURCES[i]
		if src ~= EXPRESSWAY and lib.IsValid and lib:IsValid(mt, src) then
			path = lib:Fetch(mt, src, true)
			if path then
				break
			end
		end
	end
	if not path then
		local fallbackOK = false
		if GetFileIDFromPath then
			local ok, id = pcall(GetFileIDFromPath, EXPRESSWAY_FALLBACK_PATH)
			fallbackOK = ok and id and id ~= 0
		end
		if fallbackOK then
			path = EXPRESSWAY_FALLBACK_PATH
		else
			path = GCDM.CONST.FONT_PATH or [[Fonts\FRIZQT__.TTF]]
		end
	end
	if lib.IsValid and lib:IsValid(mt, EXPRESSWAY) then
		local existing = lib:Fetch(mt, EXPRESSWAY, true)
		if existing == path then
			return true
		end
	end
	Skin._registeringExpressway = true
	local locale = FontLocaleBits(lib)
	if locale > 0 then
		lib:Register(mt, EXPRESSWAY, path, locale)
	else
		lib:Register(mt, EXPRESSWAY, path)
	end
	Skin._registeringExpressway = false
	return lib:IsValid(mt, EXPRESSWAY)
end

function Skin.ResolveFontName(name)
	if type(name) == "string" and name ~= "" then
		local lib = Skin.EnsureLSM()
		local mt = lib and ((lib.MediaType and lib.MediaType.FONT) or "font")
		if lib and lib.IsValid and lib:IsValid(mt, name) then
			return name
		end
		if name == EXPRESSWAY or name:find("Expressway", 1, true) then
			Skin.RegisterExpresswayAlias()
			if lib and lib.IsValid and lib:IsValid(mt, EXPRESSWAY) then
				return EXPRESSWAY
			end
			for i = 1, #EXPRESSWAY_SOURCES do
				local src = EXPRESSWAY_SOURCES[i]
				if lib and lib.IsValid and lib:IsValid(mt, src) then
					return src
				end
			end
		end
		return name
	end
	return Skin.DefaultFontName()
end

function Skin.FetchFont(name)
	local fallback = GCDM.CONST.FONT_PATH
	if type(name) == "string" and name:find("\\", 1, true) then
		return name
	end
	local resolved = Skin.ResolveFontName(name)
	local lib = Skin.EnsureLSM()
	if lib then
		local mt = (lib.MediaType and lib.MediaType.FONT) or "font"
		if resolved then
			local path = lib:Fetch(mt, resolved, true)
			if path then
				return path
			end
		end
		Skin.RegisterExpresswayAlias()
		if lib:IsValid(mt, EXPRESSWAY) then
			local path = lib:Fetch(mt, EXPRESSWAY, true)
			if path then
				return path
			end
		end
		local def = lib.DefaultMedia and lib.DefaultMedia[mt] or lib.DefaultMedia and lib.DefaultMedia.font
		if def then
			local path = lib:Fetch(mt, def, true)
			if path then
				return path
			end
		end
	end
	return fallback
end

function Skin.DefaultFontName()
	Skin.RegisterExpresswayAlias()
	local lib = Skin.EnsureLSM()
	local mt = lib and ((lib.MediaType and lib.MediaType.FONT) or "font")
	if lib and mt and lib.IsValid and lib:IsValid(mt, EXPRESSWAY) then
		return EXPRESSWAY
	end
	for i = 1, #EXPRESSWAY_SOURCES do
		local src = EXPRESSWAY_SOURCES[i]
		if lib and mt and lib.IsValid and lib:IsValid(mt, src) then
			return src
		end
	end
	if lib and lib.DefaultMedia then
		return lib.DefaultMedia.font or lib.DefaultMedia[mt] or "Friz Quadrata TT"
	end
	return "Friz Quadrata TT"
end

Skin.MEDIA_SOLID = "Solid"
Skin.MEDIA_EXPRESSWAY = EXPRESSWAY
