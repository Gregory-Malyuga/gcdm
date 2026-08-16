local ADDON_NAME, ns = ...
local L = ns.L

--- Dynamic rules list rebuild for Aura Sounds tab.
function ns.RebuildAuraSoundRuleArgs(addon, db, auraSoundsArgs, listGenRef, NotifyOptions)
	if not auraSoundsArgs or not auraSoundsArgs.rulesList then
		return listGenRef
	end
	local container = auraSoundsArgs.rulesList.args
	for k in pairs(container) do
		if type(k) == "string" and (string.sub(k, 1, 5) == "rule_" or k == "rulesEmpty") then
			container[k] = nil
		end
	end

	listGenRef = (listGenRef or 0) + 1
	local rules = db().auraSoundRules or {}
	if #rules == 0 then
		container.rulesEmpty = {
			type = "description",
			name = L["AURA_SOUNDS_EMPTY"],
			order = 1,
			fontSize = "medium",
		}
		return listGenRef
	end

	for i = 1, #rules do
		local rule = rules[i]
		local idx = i
		local kit = tonumber(rule.soundKitID) or 0
		local soundKey = rule.soundKey or (kit > 0 and ("kit:" .. kit) or "kit:878")
		local key = string.format("rule_%d_%d", listGenRef, i)
		container[key] = {
			type = "group",
			name = string.format(
				"%s · %s · %s · %s",
				ns.AuraSoundSpellLabel(rule.spellID),
				ns.AuraSoundUnitLabel(rule.unit),
				ns.AuraSoundEventLabel(rule.event),
				ns.AuraSoundSoundLabel(addon, soundKey)
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
						listGenRef = ns.RebuildAuraSoundRuleArgs(addon, db, auraSoundsArgs, listGenRef, NotifyOptions)
						NotifyOptions()
					end,
				},
			},
		}
	end
	return listGenRef
end
