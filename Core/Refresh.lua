local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local callbacks = {}
local ordered = {}
local seq = 0

-- Infrastructure that the rest of the pipeline reads from; not user-switchable.
local ALWAYS_ON = {
	["Pixel"] = true,
	["ViewerRegistry"] = true,
	["Skin.Media"] = true,
	["EditMode.Setup"] = true,
}

-- Modules that hook or restyle Blizzard CDM frames. Safe mode turns them off so
-- a taint source can be bisected across reloads.
local INVASIVE = {
	"Skin.Layout",
	"Skin.Position",
	"Skin.Size",
	"Skin.Icon",
	"Skin.Border",
	"Skin.Text",
	"Skin.Keybinds",
	"Skin.PressOverlay",
	"Skin.Glow",
	"Skin.BuffBar",
	"Skin.AuraSounds",
	"Skin.Debug",
}

local function InsertSorted(entry)
	for i = 1, #ordered do
		local cur = ordered[i]
		if entry.priority < cur.priority or (entry.priority == cur.priority and entry.seq < cur.seq) then
			table.insert(ordered, i, entry)
			return
		end
	end
	ordered[#ordered + 1] = entry
end

function GCDM:RegisterRefreshCallback(id, callback, priority, scopes)
	if callbacks[id] then
		self:UnregisterRefreshCallback(id)
	end

	seq = seq + 1
	local scopeSet
	if scopes then
		scopeSet = {}
		for i = 1, #scopes do
			scopeSet[scopes[i]] = true
		end
	end

	local entry = {
		id = id,
		callback = callback,
		priority = priority or 50,
		seq = seq,
		scopes = scopeSet,
	}
	callbacks[id] = entry
	InsertSorted(entry)
end

function GCDM:UnregisterRefreshCallback(id)
	local entry = callbacks[id]
	if not entry then
		return
	end
	callbacks[id] = nil
	for i = 1, #ordered do
		if ordered[i] == entry then
			table.remove(ordered, i)
			break
		end
	end
end

--- Refresh module ids in run order, infrastructure ones excluded.
function GCDM:GetRefreshModuleIDs()
	local ids = {}
	for i = 1, #ordered do
		local id = ordered[i].id
		if not ALWAYS_ON[id] then
			ids[#ids + 1] = id
		end
	end
	return ids
end

function GCDM:IsModuleEnabled(id)
	if ALWAYS_ON[id] then
		return true
	end
	local db = self:GetDB()
	local disabled = db and db.disabledModules
	return not (disabled and disabled[id])
end

--- Disabled modules stop refreshing immediately; hooks they already installed
--- only go away on /reload.
function GCDM:SetModuleEnabled(id, enabled)
	local db = self:GetDB()
	if not db or ALWAYS_ON[id] then
		return
	end
	db.disabledModules = db.disabledModules or {}
	db.disabledModules[id] = (not enabled) or nil
end

function GCDM:GetSafeModeModuleIDs()
	return INVASIVE
end

function GCDM:SetSafeMode(on)
	for i = 1, #INVASIVE do
		self:SetModuleEnabled(INVASIVE[i], not on)
	end
end

function GCDM:IsSafeMode()
	for i = 1, #INVASIVE do
		if self:IsModuleEnabled(INVASIVE[i]) then
			return false
		end
	end
	return true
end

function GCDM:Refresh(scope)
	scope = scope or GCDM.CONST.REFRESH.ALL
	for i = 1, #ordered do
		local entry = ordered[i]
		if not entry.scopes or entry.scopes[scope] or scope == GCDM.CONST.REFRESH.ALL then
			if self:IsModuleEnabled(entry.id) then
				entry.callback(scope)
			end
		end
	end
end
