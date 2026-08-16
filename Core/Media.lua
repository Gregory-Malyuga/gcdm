local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
GCDM.Skin = GCDM.Skin or {}
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

local SOLID = Skin.MEDIA_SOLID or "Solid"
local DEFAULT_STATUSBAR = "Interface\\TargetingFrame\\UI-StatusBar"
local EXPRESSWAY = Skin.MEDIA_EXPRESSWAY or "Expressway"

function Skin.RegisterMediaDefaults()
	local lib = Skin.EnsureLSM()
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
	local lib = Skin.EnsureLSM()
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
	if mediaType ~= "font" and mediaType ~= "sound" and not out[SOLID] then
		out[SOLID] = SOLID
	end
	return out
end

function Skin.FetchMedia(mediaType, name, fallback)
	local lib = Skin.EnsureLSM()
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

local mediaRefreshQueued = false

local function OnMediaRegistered(_, mediatype, key)
	if Skin._registeringExpressway then
		return
	end
	if mediatype == "font" and key ~= EXPRESSWAY then
		Skin.RegisterExpresswayAlias()
	end
	if not GCDM.Refresh or mediaRefreshQueued then
		return
	end
	-- Media is registered from whoever is loading at the time (any addon), so
	-- restyling here would run our CDM code on that stack and taint it.
	mediaRefreshQueued = true
	C_Timer.After(0, function()
		mediaRefreshQueued = false
		GCDM:Refresh(GCDM.CONST.REFRESH.STYLE)
	end)
end

function Skin.InitSharedMedia()
	Skin.RegisterMediaDefaults()
	Skin.RegisterExpresswayAlias()
	local lib = Skin.EnsureLSM()
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
