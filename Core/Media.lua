local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
GCDM.Skin = GCDM.Skin or {}
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

local LSM = LibStub("LibSharedMedia-3.0", true)

local SOLID = "Solid"
local DEFAULT_STATUSBAR = "Interface\\TargetingFrame\\UI-StatusBar"
local EXPRESSWAY = "Expressway"
-- Prefer Bold: ElvUI's bundled Expressway reads heavier than SharedMedia "Regular".
local EXPRESSWAY_SOURCES = {
	"Expressway, Bold",
	"Expressway Bold",
	"Expressway, Regular",
	"Expressway Regular",
}
local EXPRESSWAY_FALLBACK_PATH = [[Interface\AddOns\SharedMediaAdditionalFonts\fonts\Expressway-Bold.ttf]]

local function EnsureLSM()
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
	local lib = EnsureLSM()
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
		-- Only use bundled SharedMedia path when the file actually exists.
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
		local lib = EnsureLSM()
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

function Skin.RegisterMediaDefaults()
	local lib = EnsureLSM()
	if not lib then
		return
	end
	lib:Register("border", SOLID, GCDM.CONST.TEX_WHITE8X8)
	lib:Register("statusbar", SOLID, GCDM.CONST.TEX_WHITE8X8)
	lib:Register("background", SOLID, GCDM.CONST.TEX_WHITE8X8)
	Skin.RegisterExpresswayAlias()
end

function Skin.ListMedia(mediaType)
	local out = {}
	local lib = EnsureLSM()
	if lib then
		local mt = mediaType
		if lib.MediaType then
			if mediaType == "font" then
				mt = lib.MediaType.FONT or "font"
			elseif mediaType == "border" then
				mt = lib.MediaType.BORDER or "border"
			elseif mediaType == "statusbar" then
				mt = lib.MediaType.STATUSBAR or "statusbar"
			elseif mediaType == "background" then
				mt = lib.MediaType.BACKGROUND or "background"
			elseif mediaType == "sound" then
				mt = lib.MediaType.SOUND or "sound"
			end
		end
		for _, name in ipairs(lib:List(mt)) do
			out[name] = name
		end
	end
	-- Solid is a GCDM texture alias, not a font/sound.
	if mediaType ~= "font" and mediaType ~= "sound" and not out[SOLID] then
		out[SOLID] = SOLID
	end
	return out
end

function Skin.FetchMedia(mediaType, name, fallback)
	local lib = EnsureLSM()
	if lib and name then
		local mt = mediaType
		if lib.MediaType then
			if mediaType == "font" then
				mt = lib.MediaType.FONT or "font"
			elseif mediaType == "border" then
				mt = lib.MediaType.BORDER or "border"
			elseif mediaType == "statusbar" then
				mt = lib.MediaType.STATUSBAR or "statusbar"
			elseif mediaType == "background" then
				mt = lib.MediaType.BACKGROUND or "background"
			elseif mediaType == "sound" then
				mt = lib.MediaType.SOUND or "sound"
			end
		end
		local path = lib:Fetch(mt, name, true)
		if path then
			return path
		end
	end
	if name == SOLID then
		return GCDM.CONST.TEX_WHITE8X8
	end
	return fallback
end

function Skin.FetchStatusBarTexture(name)
	return Skin.FetchMedia("statusbar", name or SOLID, DEFAULT_STATUSBAR)
end

function Skin.FetchBorderEdgeFile(name)
	return Skin.FetchMedia("border", name or SOLID, GCDM.CONST.TEX_WHITE8X8)
end

function Skin.FetchBackgroundTexture(name)
	return Skin.FetchMedia("background", name or SOLID, GCDM.CONST.TEX_WHITE8X8)
end

function Skin.FetchFont(name)
	local fallback = GCDM.CONST.FONT_PATH
	if type(name) == "string" and name:find("\\", 1, true) then
		return name
	end
	local resolved = Skin.ResolveFontName(name)
	local lib = EnsureLSM()
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
	local lib = EnsureLSM()
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

function Skin.IsPixelBorder(name)
	return not name or name == SOLID
end

function Skin.BuildBorderBackdrop(db)
	Pixel.Update()
	local name = (db and db.borderTexture) or SOLID
	local edgeFile = Skin.FetchBorderEdgeFile(name)
	local pixels = math.max(1, math.floor(((db and db.borderSize) or 1) + 0.5))
	local onePixel = Pixel.GetSize()
	local edgeSize
	local insetSize
	if Skin.IsPixelBorder(name) then
		edgeSize = pixels * onePixel
		insetSize = math.floor(pixels / 2) * onePixel
	else
		-- SharedMedia borders use larger edge slices (typical 8–16).
		edgeSize = math.max(8, pixels * 8)
		insetSize = edgeSize / 3
	end
	return {
		bgFile = nil,
		edgeFile = edgeFile,
		tileSize = 0,
		edgeSize = edgeSize,
		insets = { left = insetSize, right = insetSize, top = insetSize, bottom = insetSize },
	}
end

local function OnMediaRegistered(_, mediatype, key)
	if Skin._registeringExpressway then
		return
	end
	if mediatype == "font" and key ~= EXPRESSWAY then
		Skin.RegisterExpresswayAlias()
	end
	if GCDM.Refresh then
		GCDM:Refresh(GCDM.CONST.REFRESH.STYLE)
	end
end

function Skin.InitSharedMedia()
	Skin.RegisterMediaDefaults()
	Skin.RegisterExpresswayAlias()
	-- One-shot: switch stock Friz default to Expressway (ElvUI-style).
	local db = GCDM.GetDB and GCDM:GetDB()
	if db and not db.expresswayDefaultApplied then
		db.expresswayDefaultApplied = true
		local preferred = Skin.DefaultFontName()
		if preferred and preferred ~= "Friz Quadrata TT" then
			db.textByViewer = db.textByViewer or {}
			for _, key in ipairs({
				"EssentialCooldownViewer",
				"UtilityCooldownViewer",
				"BuffIconCooldownViewer",
				"BuffBarCooldownViewer",
			}) do
				local st = db.textByViewer[key]
				if type(st) == "table" and (not st.textFont or st.textFont == "Friz Quadrata TT") then
					st.textFont = preferred
				end
			end
			if not db.powerBarFont or db.powerBarFont == "Friz Quadrata TT" then
				db.powerBarFont = preferred
			end
		end
	end
	local lib = EnsureLSM()
	if lib and lib.RegisterCallback and not Skin._lsmCallbacks then
		Skin._lsmCallbacks = true
		lib.RegisterCallback(GCDM, "LibSharedMedia_Registered", OnMediaRegistered)
		lib.RegisterCallback(GCDM, "LibSharedMedia_SetGlobal", OnMediaRegistered)
	end
end

GCDM:RegisterRefreshCallback("Skin.Media", function()
	Skin.InitSharedMedia()
end, 8, {
	GCDM.CONST.REFRESH.ALL,
})
