local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local callbacks = {}
local ordered = {}
local seq = 0

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

function GCDM:Refresh(scope)
	scope = scope or GCDM.CONST.REFRESH.ALL
	for i = 1, #ordered do
		local entry = ordered[i]
		if not entry.scopes or entry.scopes[scope] or scope == GCDM.CONST.REFRESH.ALL then
			entry.callback(scope)
		end
	end
end
