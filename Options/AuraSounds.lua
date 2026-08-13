local ADDON_NAME, ns = ...
local L = ns.L

--- Build AceConfig args for the Aura Sounds tab.
function ns.BuildAuraSoundsArgs(addon, db)
	local function RefreshSkin()
		addon:Refresh(addon.CONST.REFRESH.STYLE)
	end

	local function SpellLabel(spellID)
		spellID = tonumber(spellID)
		if not spellID then
			return "?"
		end
		if C_Spell and C_Spell.GetSpellName then
			local ok, name = pcall(C_Spell.GetSpellName, spellID)
			if ok and name then
				return string.format("%s (%d)", name, spellID)
			end
		end
		return tostring(spellID)
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
				spellSelect = "custom",
				spellID = "",
				unit = "player",
				event = "apply",
				soundKey = "kit:878",
			}
			db().auraSoundDraft = d
		end
		return d
	end

	local auraSoundsArgs
	local function RebuildAuraSoundRuleArgs()
		if not auraSoundsArgs then
			return
		end
		for k in pairs(auraSoundsArgs) do
			if type(k) == "string" and string.sub(k, 1, 5) == "rule_" then
				auraSoundsArgs[k] = nil
			end
		end
		auraSoundsArgs.rulesEmpty = nil
		local rules = db().auraSoundRules or {}
		if #rules == 0 then
			auraSoundsArgs.rulesEmpty = {
				type = "description",
				name = L["AURA_SOUNDS_EMPTY"],
				order = 50,
				fontSize = "medium",
			}
			return
		end
		for i = 1, #rules do
			local rule = rules[i]
			local idx = i
			local kit = tonumber(rule.soundKitID) or 0
			local soundLabel = rule.soundKey or (kit > 0 and ("kit:" .. kit) or "default")
			auraSoundsArgs["rule_" .. i] = {
				type = "group",
				name = string.format(
					"#%d  %s  В·  %s  В·  %s  В·  %s",
					i,
					SpellLabel(rule.spellID),
					UnitLabel(rule.unit),
					EventLabel(rule.event),
					soundLabel
				),
				order = 50 + i,
				inline = true,
				args = {
					test = {
						type = "execute",
						name = L["AURA_SOUNDS_TEST"],
						order = 1,
						width = "half",
						func = function()
							addon:PlayAuraSoundChoice(soundLabel)
						end,
					},
					del = {
						type = "execute",
						name = L["AURA_SOUNDS_DELETE"],
						order = 2,
						width = "half",
						func = function()
							addon:RemoveAuraSoundRule(idx)
							LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
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
		defaultKit = {
			type = "input",
			name = L["AURA_SOUNDS_DEFAULT_KIT"],
			desc = L["AURA_SOUNDS_DEFAULT_KIT_DESC"],
			order = 3,
			get = function()
				return tostring(db().auraSoundDefaultKitID or 878)
			end,
			set = function(_, v)
				db().auraSoundDefaultKitID = tonumber(v) or 878
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
				local sel = d.spellSelect
				if sel and sel ~= "custom" then
					return sel
				end
				if d.spellID and d.spellID ~= "" then
					local values = addon:GetAuraSoundSpellValues()
					if values[tostring(d.spellID)] then
						return tostring(d.spellID)
					end
				end
				return "custom"
			end,
			set = function(_, v)
				local d = Draft()
				d.spellSelect = v
				if v ~= "custom" then
					d.spellID = v
				end
			end,
		},
		draftSpell = {
			type = "input",
			name = L["AURA_SOUNDS_SPELL"],
			desc = L["AURA_SOUNDS_SPELL_DESC"],
			order = 11.5,
			hidden = function()
				return (Draft().spellSelect or "custom") ~= "custom"
			end,
			get = function()
				return Draft().spellID or ""
			end,
			set = function(_, v)
				Draft().spellID = v or ""
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
				local kit = tonumber(d.soundKitID) or 878
				return "kit:" .. kit
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
				addon:PlayAuraSoundChoice(d.soundKey or ("kit:" .. tostring(d.soundKitID or 878)))
			end,
		},
		draftAdd = {
			type = "execute",
			name = L["AURA_SOUNDS_ADD"],
			order = 16,
			width = "half",
			func = function()
				local d = Draft()
				local spellID = d.spellID
				if d.spellSelect and d.spellSelect ~= "custom" then
					spellID = d.spellSelect
				end
				local ok = addon:AddAuraSoundRule({
					spellID = spellID,
					unit = d.unit,
					event = d.event,
					soundKey = d.soundKey or ("kit:" .. tostring(d.soundKitID or 878)),
				})
				if ok then
					LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
				end
			end,
		},
		listHeader = {
			type = "header",
			name = L["AURA_SOUNDS_LIST"],
			order = 40,
		},
	}


	RebuildAuraSoundRuleArgs()
	return auraSoundsArgs
end

