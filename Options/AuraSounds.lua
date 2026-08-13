local ADDON_NAME, ns = ...
local L = ns.L

--- Build AceConfig args for the Aura Sounds tab.
function ns.BuildAuraSoundsArgs(addon, db)
	local function RefreshSkin()
		addon:Refresh(addon.CONST.REFRESH.STYLE)
	end

	local function NotifyOptions()
		LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
		local ACD = LibStub("AceConfigDialog-3.0", true)
		if ACD and ACD.OpenFrames and ACD.OpenFrames[ADDON_NAME] and ACD.SelectGroup then
			ACD:SelectGroup(ADDON_NAME, "auraSounds")
		end
	end

	local function SpellLabel(spellID)
		spellID = tonumber(spellID)
		if not spellID then
			return "?"
		end
		if C_Spell and C_Spell.GetSpellName then
			local ok, name = pcall(C_Spell.GetSpellName, spellID)
			if ok and name and name ~= "" then
				return name
			end
		end
		return L["AURA_SOUNDS_SPELL_UNKNOWN"] or "Unknown"
	end

	local function SoundLabel(soundKey)
		if type(soundKey) ~= "string" or soundKey == "" then
			return "?"
		end
		local values = addon:GetAuraSoundSoundValues()
		if values and values[soundKey] then
			return values[soundKey]
		end
		local lsm = string.match(soundKey, "^lsm:(.+)$")
		if lsm then
			return lsm
		end
		local kit = string.match(soundKey, "^kit:(%d+)$")
		if kit then
			local kits = addon:GetAuraSoundSoundValues()
			local key = "kit:" .. kit
			if kits and kits[key] then
				return kits[key]
			end
		end
		return soundKey
	end

	local function EventLabel(event)
		if event == "stack" then
			return L["AURA_SOUNDS_EVENT_STACK"]
		end
		if event == "remove" then
			return L["AURA_SOUNDS_EVENT_REMOVE"]
		end
		return L["AURA_SOUNDS_EVENT_APPLY"]
	end

	local function UnitLabel(unit)
		if unit == "target" then
			return L["AURA_SOUNDS_UNIT_TARGET"]
		end
		if unit == "focus" then
			return L["AURA_SOUNDS_UNIT_FOCUS"]
		end
		return L["AURA_SOUNDS_UNIT_PLAYER"]
	end

	local function Draft()
		local d = db().auraSoundDraft
		if type(d) ~= "table" then
			d = {
				spellSelect = "",
				spellID = "",
				unit = "player",
				event = "apply",
				soundKey = "kit:878",
			}
			db().auraSoundDraft = d
		end
		return d
	end

	local function FirstSpellKey()
		local values = addon:GetAuraSoundSpellValues()
		local first
		for k in pairs(values) do
			if type(k) == "string" and k ~= "" then
				if not first or k < first then
					first = k
				end
			end
		end
		return first
	end

	local auraSoundsArgs
	local listGen = 0

	local function ClearDynamicRuleArgs(container)
		if not container then
			return
		end
		for k in pairs(container) do
			if type(k) == "string" and (string.sub(k, 1, 5) == "rule_" or k == "rulesEmpty") then
				container[k] = nil
			end
		end
	end

	local function RebuildAuraSoundRuleArgs()
		if not auraSoundsArgs or not auraSoundsArgs.rulesList then
			return
		end
		local container = auraSoundsArgs.rulesList.args
		ClearDynamicRuleArgs(container)

		listGen = listGen + 1
		local rules = db().auraSoundRules or {}
		if #rules == 0 then
			container.rulesEmpty = {
				type = "description",
				name = L["AURA_SOUNDS_EMPTY"],
				order = 1,
				fontSize = "medium",
			}
			return
		end

		for i = 1, #rules do
			local rule = rules[i]
			local idx = i
			local kit = tonumber(rule.soundKitID) or 0
			local soundKey = rule.soundKey or (kit > 0 and ("kit:" .. kit) or "kit:878")
			local key = string.format("rule_%d_%d", listGen, i)
			container[key] = {
				type = "group",
				name = string.format(
					"%s · %s · %s · %s",
					SpellLabel(rule.spellID),
					UnitLabel(rule.unit),
					EventLabel(rule.event),
					SoundLabel(soundKey)
				),
				order = i,
				inline = true,
				args = {
					test = {
						type = "execute",
						name = L["AURA_SOUNDS_TEST"],
						order = 1,
						width = "half",
						func = function()
							addon:PlayAuraSoundChoice(soundKey)
						end,
					},
					del = {
						type = "execute",
						name = L["AURA_SOUNDS_DELETE"],
						order = 2,
						width = "half",
						func = function()
							addon:RemoveAuraSoundRule(idx)
							RebuildAuraSoundRuleArgs()
							NotifyOptions()
						end,
					},
				},
			}
		end
	end

	auraSoundsArgs = {
		hint = {
			type = "description",
			name = L["AURA_SOUNDS_DESC"],
			order = 1,
			fontSize = "medium",
		},
		enabled = {
			type = "toggle",
			name = L["AURA_SOUNDS_ENABLED"],
			order = 2,
			width = "full",
			get = function()
				return db().auraSoundEnabled ~= false
			end,
			set = function(_, v)
				db().auraSoundEnabled = v and true or false
				RefreshSkin()
			end,
		},
		draftHeader = {
			type = "header",
			name = L["AURA_SOUNDS_ADD"],
			order = 10,
		},
		draftSpellSelect = {
			type = "select",
			name = L["AURA_SOUNDS_SPELL_SELECT"],
			desc = L["AURA_SOUNDS_SPELL_SELECT_DESC"],
			order = 11,
			values = function()
				return addon:GetAuraSoundSpellValues()
			end,
			get = function()
				local d = Draft()
				local values = addon:GetAuraSoundSpellValues()
				local sel = d.spellSelect
				if sel and sel ~= "" and sel ~= "custom" and values[sel] then
					return sel
				end
				if d.spellID and d.spellID ~= "" and values[tostring(d.spellID)] then
					return tostring(d.spellID)
				end
				return FirstSpellKey()
			end,
			set = function(_, v)
				local d = Draft()
				d.spellSelect = v
				d.spellID = v
			end,
		},
		draftUnit = {
			type = "select",
			name = L["AURA_SOUNDS_UNIT"],
			order = 12,
			values = {
				player = L["AURA_SOUNDS_UNIT_PLAYER"],
				target = L["AURA_SOUNDS_UNIT_TARGET"],
				focus = L["AURA_SOUNDS_UNIT_FOCUS"],
			},
			get = function()
				return Draft().unit or "player"
			end,
			set = function(_, v)
				Draft().unit = v
			end,
		},
		draftEvent = {
			type = "select",
			name = L["AURA_SOUNDS_EVENT"],
			order = 13,
			values = {
				apply = L["AURA_SOUNDS_EVENT_APPLY"],
				stack = L["AURA_SOUNDS_EVENT_STACK"],
				remove = L["AURA_SOUNDS_EVENT_REMOVE"],
			},
			get = function()
				return Draft().event or "apply"
			end,
			set = function(_, v)
				Draft().event = v
			end,
		},
		draftSound = {
			type = "select",
			name = L["AURA_SOUNDS_SOUND"],
			desc = L["AURA_SOUNDS_SOUND_DESC"],
			order = 14,
			values = function()
				return addon:GetAuraSoundSoundValues()
			end,
			get = function()
				local d = Draft()
				if d.soundKey then
					return d.soundKey
				end
				return "kit:878"
			end,
			set = function(_, v)
				Draft().soundKey = v
			end,
		},
		draftTest = {
			type = "execute",
			name = L["AURA_SOUNDS_TEST"],
			order = 15,
			width = "half",
			func = function()
				local d = Draft()
				addon:PlayAuraSoundChoice(d.soundKey or "kit:878")
			end,
		},
		draftAdd = {
			type = "execute",
			name = L["AURA_SOUNDS_ADD"],
			order = 16,
			width = "half",
			func = function()
				local d = Draft()
				local spellID = d.spellSelect or d.spellID
				if not spellID or spellID == "" or spellID == "custom" then
					spellID = FirstSpellKey()
				end
				local ok = addon:AddAuraSoundRule({
					spellID = spellID,
					unit = d.unit,
					event = d.event,
					soundKey = d.soundKey or "kit:878",
				})
				if ok then
					RebuildAuraSoundRuleArgs()
					NotifyOptions()
				else
					print("|cff3bb273GCDM|r " .. (L["AURA_SOUNDS_ADD_FAIL"] or "Could not add sound rule (pick a buff)."))
				end
			end,
		},
		rulesList = {
			type = "group",
			name = L["AURA_SOUNDS_LIST"],
			order = 40,
			inline = true,
			args = {},
		},
	}

	RebuildAuraSoundRuleArgs()
	return auraSoundsArgs
end
