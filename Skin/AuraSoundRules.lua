local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

function GCDM:AddAuraSoundRule(rule)
	local db = self:GetDB()
	if not db then
		return false
	end
	db.auraSoundRules = db.auraSoundRules or {}
	local spellID = tonumber(rule and rule.spellID)
	if not spellID or spellID <= 0 then
		return false
	end
	local soundKey = rule.soundKey
	if type(soundKey) ~= "string" or soundKey == "" then
		local kit = tonumber(rule.soundKitID) or 0
		soundKey = "kit:" .. (kit > 0 and kit or ns.AuraSoundDefaultKit(db))
	end
	db.auraSoundRules[#db.auraSoundRules + 1] = {
		spellID = spellID,
		unit = rule.unit or "player",
		event = rule.event or "apply",
		soundKey = soundKey,
		soundKitID = tonumber(rule.soundKitID) or 0,
	}
	self:Refresh(self.CONST.REFRESH.STYLE)
	return true
end

function GCDM:RemoveAuraSoundRule(index)
	local db = self:GetDB()
	if not db or type(db.auraSoundRules) ~= "table" then
		return
	end
	index = tonumber(index)
	if not index or index < 1 or index > #db.auraSoundRules then
		return
	end
	table.remove(db.auraSoundRules, index)
	self:Refresh(self.CONST.REFRESH.STYLE)
end
