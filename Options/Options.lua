local ADDON_NAME, ns = ...
local L = ns.L

local function RefreshSkin(addon)
	addon:Refresh(addon.CONST.REFRESH.STYLE)
end

local function RefreshLayout(addon)
	addon:Refresh(addon.CONST.REFRESH.LAYOUT)
end

local function RefreshBuffBars(addon)
	addon:Refresh(addon.CONST.REFRESH.LAYOUT)
	addon:Refresh(addon.CONST.REFRESH.STYLE)
end

local function RefreshGlow(addon)
	addon:Refresh(addon.CONST.REFRESH.GLOW)
end

-- Fractional UI units (sizes, offsets, spacing). Integer counts stay step=1.
local FSTEP = 0.1

function ns.SetupOptions(addon)
	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	local db = function()
		return addon.db.profile
	end

	local function setSize(tbl, key, value)
		tbl[key] = value
		RefreshSkin(addon)
	end

	local function setColor(key, r, g, b, a)
		db()[key] = { r = r, g = g, b = b, a = a }
	end

	local function getColor(key, fallback)
		local c = db()[key] or fallback
		return c.r or 1, c.g or 1, c.b or 1, c.a or 1
	end

	local ANCHOR_VALUES = {
		CENTER = L["ANCHOR_CENTER"],
		TOP = L["ANCHOR_TOP"],
		BOTTOM = L["ANCHOR_BOTTOM"],
		LEFT = L["ANCHOR_LEFT"],
		RIGHT = L["ANCHOR_RIGHT"],
		TOPLEFT = L["ANCHOR_TOPLEFT"],
		TOPRIGHT = L["ANCHOR_TOPRIGHT"],
		BOTTOMLEFT = L["ANCHOR_BOTTOMLEFT"],
		BOTTOMRIGHT = L["ANCHOR_BOTTOMRIGHT"],
	}

	local OUTLINE_VALUES = {
		NONE = L["TEXT_OUTLINE_NONE"],
		OUTLINE = L["TEXT_OUTLINE_OUTLINE"],
		THICKOUTLINE = L["TEXT_OUTLINE_THICK"],
		MONOCHROME = L["TEXT_OUTLINE_MONOCHROME"],
	}

	local function TextStyle(viewerKey)
		local root = db()
		root.textByViewer = root.textByViewer or {}
		local st = root.textByViewer[viewerKey]
		if type(st) ~= "table" then
			st = {}
			root.textByViewer[viewerKey] = st
		end
		return st
	end

	local function getStyleColor(style, key, fallback)
		local c = style[key] or fallback
		return c.r or 1, c.g or 1, c.b or 1, c.a or 1
	end

	local function setStyleColor(style, key, r, g, b, a)
		style[key] = { r = r, g = g, b = b, a = a }
	end

	local function MakeIconTextArgs(viewerKey, orderBase, withKeybind)
		orderBase = orderBase or 100
		local args = {
			textHeader = {
				type = "header",
				name = L["TEXT"],
				order = orderBase,
			},
			textFont = {
				type = "select",
				name = L["TEXT_FONT"],
				order = orderBase + 1,
				values = function()
					return addon.Skin.ListMedia("font")
				end,
				get = function()
					local st = TextStyle(viewerKey)
					return addon.Skin.ResolveFontName(st.textFont or addon.Skin.DefaultFontName())
				end,
				set = function(_, v)
					TextStyle(viewerKey).textFont = v
					RefreshSkin(addon)
				end,
			},
			textOutline = {
				type = "select",
				name = L["TEXT_OUTLINE"],
				order = orderBase + 2,
				values = OUTLINE_VALUES,
				get = function()
					local v = TextStyle(viewerKey).textOutline or "OUTLINE"
					if v == "" then
						return "NONE"
					end
					return v
				end,
				set = function(_, v)
					TextStyle(viewerKey).textOutline = (v == "NONE") and "" or v
					RefreshSkin(addon)
				end,
			},
			cooldownHeader = {
				type = "header",
				name = L["COOLDOWN_TEXT"],
				order = orderBase + 10,
			},
			cooldownFontSize = {
				type = "range",
				name = L["COOLDOWN_FONT_SIZE"],
				order = orderBase + 11,
				min = 8,
				max = 32,
				step = 1,
				get = function()
					return TextStyle(viewerKey).cooldownFontSize or 14
				end,
				set = function(_, v)
					TextStyle(viewerKey).cooldownFontSize = v
					RefreshSkin(addon)
				end,
			},
			cooldownTextColor = {
				type = "color",
				name = L["COOLDOWN_TEXT_COLOR"],
				order = orderBase + 12,
				hasAlpha = true,
				get = function()
					return getStyleColor(TextStyle(viewerKey), "cooldownTextColor", { r = 1, g = 1, b = 1, a = 1 })
				end,
				set = function(_, r, g, b, a)
					setStyleColor(TextStyle(viewerKey), "cooldownTextColor", r, g, b, a)
					RefreshSkin(addon)
				end,
			},
			cooldownTextPoint = {
				type = "select",
				name = L["COOLDOWN_TEXT_POINT"],
				order = orderBase + 13,
				values = ANCHOR_VALUES,
				get = function()
					return TextStyle(viewerKey).cooldownTextPoint or "CENTER"
				end,
				set = function(_, v)
					TextStyle(viewerKey).cooldownTextPoint = v
					RefreshSkin(addon)
				end,
			},
			cooldownTextOffsetX = {
				type = "range",
				name = L["COOLDOWN_TEXT_OFFSET_X"],
				order = orderBase + 14,
				min = -40,
				max = 40,
				step = FSTEP,
				bigStep = 1,
				get = function()
					return TextStyle(viewerKey).cooldownTextOffsetX or 0
				end,
				set = function(_, v)
					TextStyle(viewerKey).cooldownTextOffsetX = v
					RefreshSkin(addon)
				end,
			},
			cooldownTextOffsetY = {
				type = "range",
				name = L["COOLDOWN_TEXT_OFFSET_Y"],
				order = orderBase + 15,
				min = -40,
				max = 40,
				step = FSTEP,
				bigStep = 1,
				get = function()
					return TextStyle(viewerKey).cooldownTextOffsetY or 0
				end,
				set = function(_, v)
					TextStyle(viewerKey).cooldownTextOffsetY = v
					RefreshSkin(addon)
				end,
			},
			stackHeader = {
				type = "header",
				name = L["STACK_TEXT"],
				order = orderBase + 20,
			},
			stackFontSize = {
				type = "range",
				name = L["STACK_FONT_SIZE"],
				order = orderBase + 21,
				min = 8,
				max = 32,
				step = 1,
				get = function()
					return TextStyle(viewerKey).stackFontSize or 12
				end,
				set = function(_, v)
					TextStyle(viewerKey).stackFontSize = v
					RefreshSkin(addon)
				end,
			},
			stackTextColor = {
				type = "color",
				name = L["STACK_TEXT_COLOR"],
				order = orderBase + 22,
				hasAlpha = true,
				get = function()
					return getStyleColor(TextStyle(viewerKey), "stackTextColor", { r = 1, g = 1, b = 1, a = 1 })
				end,
				set = function(_, r, g, b, a)
					setStyleColor(TextStyle(viewerKey), "stackTextColor", r, g, b, a)
					RefreshSkin(addon)
				end,
			},
			stackTextPoint = {
				type = "select",
				name = L["STACK_TEXT_POINT"],
				order = orderBase + 23,
				values = ANCHOR_VALUES,
				get = function()
					return TextStyle(viewerKey).stackTextPoint or "BOTTOMRIGHT"
				end,
				set = function(_, v)
					TextStyle(viewerKey).stackTextPoint = v
					RefreshSkin(addon)
				end,
			},
			stackTextOffsetX = {
				type = "range",
				name = L["STACK_TEXT_OFFSET_X"],
				order = orderBase + 24,
				min = -40,
				max = 40,
				step = FSTEP,
				bigStep = 1,
				get = function()
					return TextStyle(viewerKey).stackTextOffsetX or 0
				end,
				set = function(_, v)
					TextStyle(viewerKey).stackTextOffsetX = v
					RefreshSkin(addon)
				end,
			},
			stackTextOffsetY = {
				type = "range",
				name = L["STACK_TEXT_OFFSET_Y"],
				order = orderBase + 25,
				min = -40,
				max = 40,
				step = FSTEP,
				bigStep = 1,
				get = function()
					return TextStyle(viewerKey).stackTextOffsetY or 0
				end,
				set = function(_, v)
					TextStyle(viewerKey).stackTextOffsetY = v
					RefreshSkin(addon)
				end,
			},
		}
		if withKeybind then
			args.keybindHeader = {
				type = "header",
				name = L["KEYBIND_TEXT"],
				order = orderBase + 30,
			}
			args.keybindTextEnabled = {
				type = "toggle",
				name = L["KEYBIND_TEXT_ENABLED"],
				desc = L["KEYBIND_TEXT_ENABLED_DESC"],
				order = orderBase + 31,
				get = function()
					return db().keybindTextEnabled ~= false
				end,
				set = function(_, v)
					db().keybindTextEnabled = v and true or false
					RefreshSkin(addon)
				end,
			}
			args.pressOverlayEnabled = {
				type = "toggle",
				name = L["PRESS_OVERLAY_ENABLED"],
				desc = L["PRESS_OVERLAY_ENABLED_DESC"],
				order = orderBase + 32,
				get = function()
					return db().pressOverlayEnabled ~= false
				end,
				set = function(_, v)
					db().pressOverlayEnabled = v and true or false
					RefreshSkin(addon)
				end,
			}
			args.keybindFontSize = {
				type = "range",
				name = L["KEYBIND_FONT_SIZE"],
				order = orderBase + 33,
				min = 8,
				max = 28,
				step = 1,
				get = function()
					return TextStyle(viewerKey).keybindFontSize or 11
				end,
				set = function(_, v)
					TextStyle(viewerKey).keybindFontSize = v
					RefreshSkin(addon)
				end,
			}
			args.keybindTextColor = {
				type = "color",
				name = L["KEYBIND_TEXT_COLOR"],
				order = orderBase + 34,
				hasAlpha = true,
				get = function()
					return getStyleColor(TextStyle(viewerKey), "keybindTextColor", { r = 1, g = 1, b = 1, a = 1 })
				end,
				set = function(_, r, g, b, a)
					setStyleColor(TextStyle(viewerKey), "keybindTextColor", r, g, b, a)
					RefreshSkin(addon)
				end,
			}
			args.keybindTextPoint = {
				type = "select",
				name = L["KEYBIND_TEXT_POINT"],
				order = orderBase + 35,
				values = ANCHOR_VALUES,
				get = function()
					return TextStyle(viewerKey).keybindTextPoint or "TOPLEFT"
				end,
				set = function(_, v)
					TextStyle(viewerKey).keybindTextPoint = v
					RefreshSkin(addon)
				end,
			}
			args.keybindTextOffsetX = {
				type = "range",
				name = L["KEYBIND_TEXT_OFFSET_X"],
				order = orderBase + 36,
				min = -40,
				max = 40,
				step = FSTEP,
				bigStep = 1,
				get = function()
					return TextStyle(viewerKey).keybindTextOffsetX or 2
				end,
				set = function(_, v)
					TextStyle(viewerKey).keybindTextOffsetX = v
					RefreshSkin(addon)
				end,
			}
			args.keybindTextOffsetY = {
				type = "range",
				name = L["KEYBIND_TEXT_OFFSET_Y"],
				order = orderBase + 37,
				min = -40,
				max = 40,
				step = FSTEP,
				bigStep = 1,
				get = function()
					return TextStyle(viewerKey).keybindTextOffsetY or -1
				end,
				set = function(_, v)
					TextStyle(viewerKey).keybindTextOffsetY = v
					RefreshSkin(addon)
				end,
			}
		end
		return args
	end

	local function MakeBuffBarTextArgs(orderBase)
		orderBase = orderBase or 100
		local key = "BuffBarCooldownViewer"
		return {
			textHeader = {
				type = "header",
				name = L["TEXT"],
				order = orderBase,
			},
			textFont = {
				type = "select",
				name = L["TEXT_FONT"],
				order = orderBase + 1,
				values = function()
					return addon.Skin.ListMedia("font")
				end,
				get = function()
					local st = TextStyle(key)
					return addon.Skin.ResolveFontName(st.textFont or addon.Skin.DefaultFontName())
				end,
				set = function(_, v)
					TextStyle(key).textFont = v
					RefreshSkin(addon)
				end,
			},
			textOutline = {
				type = "select",
				name = L["TEXT_OUTLINE"],
				order = orderBase + 2,
				values = OUTLINE_VALUES,
				get = function()
					local v = TextStyle(key).textOutline or "OUTLINE"
					if v == "" then
						return "NONE"
					end
					return v
				end,
				set = function(_, v)
					TextStyle(key).textOutline = (v == "NONE") and "" or v
					RefreshSkin(addon)
				end,
			},
			nameFontSize = {
				type = "range",
				name = L["BUFF_BAR_NAME_FONT_SIZE"],
				order = orderBase + 3,
				min = 8,
				max = 32,
				step = 1,
				get = function()
					return TextStyle(key).nameFontSize or 12
				end,
				set = function(_, v)
					TextStyle(key).nameFontSize = v
					RefreshSkin(addon)
				end,
			},
			nameTextColor = {
				type = "color",
				name = L["BUFF_BAR_NAME_COLOR"],
				order = orderBase + 4,
				hasAlpha = true,
				get = function()
					return getStyleColor(TextStyle(key), "nameTextColor", { r = 1, g = 1, b = 1, a = 1 })
				end,
				set = function(_, r, g, b, a)
					setStyleColor(TextStyle(key), "nameTextColor", r, g, b, a)
					RefreshSkin(addon)
				end,
			},
			durationFontSize = {
				type = "range",
				name = L["BUFF_BAR_DUR_FONT_SIZE"],
				order = orderBase + 5,
				min = 8,
				max = 32,
				step = 1,
				get = function()
					return TextStyle(key).durationFontSize or 14
				end,
				set = function(_, v)
					TextStyle(key).durationFontSize = v
					RefreshSkin(addon)
				end,
			},
			durationTextColor = {
				type = "color",
				name = L["BUFF_BAR_DUR_COLOR"],
				order = orderBase + 6,
				hasAlpha = true,
				get = function()
					return getStyleColor(TextStyle(key), "durationTextColor", { r = 1, g = 1, b = 1, a = 1 })
				end,
				set = function(_, r, g, b, a)
					setStyleColor(TextStyle(key), "durationTextColor", r, g, b, a)
					RefreshSkin(addon)
				end,
			},
			nameTextOffsetX = {
				type = "range",
				name = L["BUFF_BAR_NAME_OFFSET_X"],
				order = orderBase + 7,
				min = -40,
				max = 40,
				step = FSTEP,
				bigStep = 1,
				get = function()
					return TextStyle(key).nameTextOffsetX or 4
				end,
				set = function(_, v)
					TextStyle(key).nameTextOffsetX = v
					RefreshSkin(addon)
				end,
			},
			durationTextOffsetX = {
				type = "range",
				name = L["BUFF_BAR_DUR_OFFSET_X"],
				order = orderBase + 8,
				min = -40,
				max = 40,
				step = FSTEP,
				bigStep = 1,
				get = function()
					return TextStyle(key).durationTextOffsetX or -4
				end,
				set = function(_, v)
					TextStyle(key).durationTextOffsetX = v
					RefreshSkin(addon)
				end,
			},
		}
	end

	local function OpenBlizzardEditMode()
		if InCombatLockdown and InCombatLockdown() then
			print("|cff3bb273GCDM|r: " .. L["MSG_EDITMODE_COMBAT"])
			return
		end
		local function show()
			local em = _G.EditModeManagerFrame
			if not em then
				return false
			end
			if em.EnterEditMode then
				pcall(function()
					em:EnterEditMode()
				end)
			end
			if ShowUIPanel then
				ShowUIPanel(em)
			elseif em.Show then
				em:Show()
			end
			return (em.IsShown and em:IsShown()) or (em.IsEditModeActive and em:IsEditModeActive())
		end
		if show() then
			return
		end
		if C_AddOns and C_AddOns.LoadAddOn then
			pcall(C_AddOns.LoadAddOn, "Blizzard_EditMode")
		elseif LoadAddOn then
			pcall(LoadAddOn, "Blizzard_EditMode")
		end
		show()
	end

	local function OpenBlizzardCooldownViewerSettings()
		if InCombatLockdown and InCombatLockdown() then
			print("|cff3bb273GCDM|r: " .. L["MSG_CDM_COMBAT"])
			return
		end
		local function show()
			local panel = _G.CooldownViewerSettings
			if not panel then
				return false
			end
			if ShowUIPanel then
				ShowUIPanel(panel)
			elseif panel.Show then
				panel:Show()
			end
			return panel.IsShown and panel:IsShown()
		end
		if show() then
			return
		end
		if C_AddOns and C_AddOns.LoadAddOn then
			pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
		elseif LoadAddOn then
			pcall(LoadAddOn, "Blizzard_CooldownViewer")
		end
		if not show() then
			-- Settings often live next to Edit Mode; open EM as fallback entry point.
			OpenBlizzardEditMode()
			print("|cff3bb273GCDM|r: " .. L["MSG_CDM_FALLBACK"])
		end
	end

	local options = {
		type = "group",
		name = L["ADDON_NAME"],
		childGroups = "tab",
		args = {
			general = {
				type = "group",
				name = L["GENERAL"],
				order = 1,
				args = {
					enabled = {
						type = "toggle",
						name = L["ENABLED"],
						desc = L["ENABLED_DESC"],
						order = 1,
						width = "full",
						get = function()
							return db().enabled
						end,
						set = function(_, value)
							db().enabled = value
							addon:Refresh()
						end,
					},
					hint = {
						type = "description",
						name = L["PLACEHOLDER"] .. "\n" .. L["OPEN_HINT"],
						order = 2,
						fontSize = "medium",
					},
					debugSkin = {
						type = "toggle",
						name = L["DEBUG_SKIN"],
						desc = L["DEBUG_SKIN_DESC"],
						order = 3,
						width = "full",
						get = function()
							return db().debugSkin
						end,
						set = function(_, value)
							db().debugSkin = value
							RefreshSkin(addon)
							if value then
								addon:DumpSkinDebug()
							end
						end,
					},
					dumpLog = {
						type = "execute",
						name = L["DUMP_LOG"],
						desc = L["DUMP_LOG_DESC"],
						order = 3.5,
						width = "full",
						func = function()
							local ok, err = pcall(function()
								addon:DumpBuffBarDebug()
							end)
							if not ok then
								print("|cff3bb273GCDM|r dump ERROR: " .. tostring(err))
							end
						end,
					},
					runTests = {
						type = "execute",
						name = L["RUN_TESTS"],
						desc = L["RUN_TESTS_DESC"],
						order = 3.6,
						width = "full",
						func = function()
							local ok, err = pcall(function()
								addon:RunBehaviorTests()
							end)
							if not ok then
								print("|cff3bb273GCDM|r test ERROR: " .. tostring(err))
							end
						end,
					},
					hidePandemicIndicator = {
						type = "toggle",
						name = L["HIDE_PANDEMIC"],
						desc = L["HIDE_PANDEMIC_DESC"],
						order = 4,
						width = "full",
						get = function()
							return db().hidePandemicIndicator ~= false
						end,
						set = function(_, value)
							db().hidePandemicIndicator = value and true or false
							RefreshSkin(addon)
						end,
					},
				},
			},
			skin = {
				type = "group",
				name = L["SKIN"],
				order = 2,
				childGroups = "tab",
				args = {
					layout = {
						type = "group",
						name = L["LAYOUT"],
						order = 1,
						args = {
							pixelSnap = {
								type = "toggle",
								name = L["PIXEL_SNAP"],
								desc = L["PIXEL_SNAP_DESC"],
								order = 0,
								width = "full",
								get = function()
									return db().pixelSnap == true
								end,
								set = function(_, v)
									db().pixelSnap = v and true or false
									RefreshLayout(addon)
									RefreshSkin(addon)
								end,
							},
							spacing = {
								type = "range",
								name = L["SPACING"],
								desc = L["SPACING_DESC"],
								order = 1,
								min = 0,
								max = 20,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().spacing or 0
								end,
								set = function(_, v)
									db().spacing = v
									RefreshLayout(addon)
								end,
							},
							maxIconsPerRow = {
								type = "range",
								name = L["MAX_PER_ROW"],
								desc = L["MAX_PER_ROW_DESC"],
								order = 2,
								min = 1,
								max = 16,
								step = 1,
								get = function()
									return db().maxIconsPerRow
								end,
								set = function(_, v)
									db().maxIconsPerRow = v
									RefreshSkin(addon)
								end,
							},
						},
					},
					positions = {
						type = "group",
						name = L["POSITIONS"],
						order = 1.5,
						args = (function()
							local args = {
								hint = {
									type = "description",
									name = L["POSITIONS_DESC"],
									order = 0,
									fontSize = "medium",
								},
							}
							local blocks = {
								{ key = "essential", label = L["POS_ESSENTIAL"], order = 10 },
								{ key = "utility", label = L["POS_UTILITY"], order = 20 },
								{ key = "buff", label = L["POS_BUFF"], order = 30 },
								{ key = "buffBar", label = L["POS_BUFF_BAR"], order = 40 },
							}
							local points = {
								CENTER = L["ANCHOR_CENTER"],
								TOP = L["ANCHOR_TOP"],
								BOTTOM = L["ANCHOR_BOTTOM"],
								LEFT = L["ANCHOR_LEFT"],
								RIGHT = L["ANCHOR_RIGHT"],
								TOPLEFT = L["ANCHOR_TOPLEFT"],
								TOPRIGHT = L["ANCHOR_TOPRIGHT"],
								BOTTOMLEFT = L["ANCHOR_BOTTOMLEFT"],
								BOTTOMRIGHT = L["ANCHOR_BOTTOMRIGHT"],
							}
							local function pos(key)
								db().viewerPos = db().viewerPos or {}
								local t = db().viewerPos[key]
								if type(t) ~= "table" then
									t = { enabled = false, point = "CENTER", x = 0, y = 0 }
									db().viewerPos[key] = t
								end
								return t
							end
							for i = 1, #blocks do
								local b = blocks[i]
								args[b.key .. "Header"] = {
									type = "header",
									name = b.label,
									order = b.order,
								}
								args[b.key .. "Enabled"] = {
									type = "toggle",
									name = L["POS_ENABLED"],
									order = b.order + 1,
									width = "full",
									get = function()
										return pos(b.key).enabled and true or false
									end,
									set = function(_, v)
										pos(b.key).enabled = v and true or false
										-- replace table so AceDB persists nested fields
										local t = pos(b.key)
										db().viewerPos[b.key] = {
											enabled = t.enabled,
											point = t.point or "CENTER",
											x = t.x or 0,
											y = t.y or 0,
										}
										RefreshLayout(addon)
									end,
								}
								args[b.key .. "Point"] = {
									type = "select",
									name = L["POS_POINT"],
									order = b.order + 2,
									values = points,
									disabled = function()
										return not pos(b.key).enabled
									end,
									get = function()
										return pos(b.key).point or "CENTER"
									end,
									set = function(_, v)
										local t = pos(b.key)
										db().viewerPos[b.key] = {
											enabled = t.enabled and true or false,
											point = v,
											x = t.x or 0,
											y = t.y or 0,
										}
										RefreshLayout(addon)
									end,
								}
								args[b.key .. "X"] = {
									type = "range",
									name = L["POS_X"],
									order = b.order + 3,
									min = -1000,
									max = 1000,
									softMin = -500,
									softMax = 500,
									step = FSTEP,
									bigStep = 1,
									disabled = function()
										return not pos(b.key).enabled
									end,
									get = function()
										return pos(b.key).x or 0
									end,
									set = function(_, v)
										local t = pos(b.key)
										db().viewerPos[b.key] = {
											enabled = t.enabled and true or false,
											point = t.point or "CENTER",
											x = v,
											y = t.y or 0,
										}
										RefreshLayout(addon)
									end,
								}
								args[b.key .. "Y"] = {
									type = "range",
									name = L["POS_Y"],
									order = b.order + 4,
									min = -1000,
									max = 1000,
									softMin = -500,
									softMax = 500,
									step = FSTEP,
									bigStep = 1,
									disabled = function()
										return not pos(b.key).enabled
									end,
									get = function()
										return pos(b.key).y or 0
									end,
									set = function(_, v)
										local t = pos(b.key)
										db().viewerPos[b.key] = {
											enabled = t.enabled and true or false,
											point = t.point or "CENTER",
											x = t.x or 0,
											y = v,
										}
										RefreshLayout(addon)
									end,
								}
							end
							return args
						end)(),
					},
					sizes = {
						type = "group",
						name = L["SIZE"],
						order = 2,
						args = {
							essW = {
								type = "range",
								name = L["SIZE_ESSENTIAL"] .. " " .. L["WIDTH"],
								order = 1,
								min = 16,
								max = 96,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().sizeEssential.w
								end,
								set = function(_, v)
									setSize(db().sizeEssential, "w", v)
								end,
							},
							essH = {
								type = "range",
								name = L["SIZE_ESSENTIAL"] .. " " .. L["HEIGHT"],
								order = 2,
								min = 16,
								max = 96,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().sizeEssential.h
								end,
								set = function(_, v)
									setSize(db().sizeEssential, "h", v)
								end,
							},
							ess2W = {
								type = "range",
								name = L["SIZE_ESSENTIAL_ROW2"] .. " " .. L["WIDTH"],
								order = 3,
								min = 16,
								max = 96,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().sizeEssentialRow2.w
								end,
								set = function(_, v)
									setSize(db().sizeEssentialRow2, "w", v)
								end,
							},
							ess2H = {
								type = "range",
								name = L["SIZE_ESSENTIAL_ROW2"] .. " " .. L["HEIGHT"],
								order = 4,
								min = 16,
								max = 96,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().sizeEssentialRow2.h
								end,
								set = function(_, v)
									setSize(db().sizeEssentialRow2, "h", v)
								end,
							},
							utilW = {
								type = "range",
								name = L["SIZE_UTILITY"] .. " " .. L["WIDTH"],
								order = 5,
								min = 16,
								max = 96,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().sizeUtility.w
								end,
								set = function(_, v)
									setSize(db().sizeUtility, "w", v)
								end,
							},
							utilH = {
								type = "range",
								name = L["SIZE_UTILITY"] .. " " .. L["HEIGHT"],
								order = 6,
								min = 16,
								max = 96,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().sizeUtility.h
								end,
								set = function(_, v)
									setSize(db().sizeUtility, "h", v)
								end,
							},
							buffW = {
								type = "range",
								name = L["SIZE_BUFF"] .. " " .. L["WIDTH"],
								order = 7,
								min = 16,
								max = 96,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().sizeBuff.w
								end,
								set = function(_, v)
									setSize(db().sizeBuff, "w", v)
								end,
							},
							buffH = {
								type = "range",
								name = L["SIZE_BUFF"] .. " " .. L["HEIGHT"],
								order = 8,
								min = 16,
								max = 96,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().sizeBuff.h
								end,
								set = function(_, v)
									setSize(db().sizeBuff, "h", v)
								end,
							},
						},
					},
					border = {
						type = "group",
						name = L["BORDER"],
						order = 3,
						args = {
							borderSize = {
								type = "range",
								name = L["BORDER_SIZE"],
								order = 1,
								min = 0,
								max = 4,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().borderSize
								end,
								set = function(_, v)
									db().borderSize = v
									RefreshSkin(addon)
								end,
							},
							borderTexture = {
								type = "select",
								name = L["BORDER_TEXTURE"],
								desc = L["BORDER_TEXTURE_DESC"],
								order = 2,
								values = function()
									return addon.Skin.ListMedia("border")
								end,
								get = function()
									return db().borderTexture or "Solid"
								end,
								set = function(_, v)
									db().borderTexture = v
									RefreshSkin(addon)
								end,
							},
							borderColor = {
								type = "color",
								name = L["BORDER_COLOR"],
								order = 3,
								hasAlpha = true,
								get = function()
									return getColor("borderColor", { r = 0, g = 0, b = 0, a = 1 })
								end,
								set = function(_, r, g, b, a)
									setColor("borderColor", r, g, b, a)
									RefreshSkin(addon)
								end,
							},
							iconZoom = {
								type = "range",
								name = L["ICON_ZOOM"],
								desc = L["ICON_ZOOM_DESC"],
								order = 4,
								min = 0,
								max = 0.4,
								step = 0.01,
								isPercent = true,
								get = function()
									return db().iconZoom
								end,
								set = function(_, v)
									db().iconZoom = v
									RefreshSkin(addon)
								end,
							},
						},
					},
					glow = {
						type = "group",
						name = L["GLOW"],
						order = 4,
						args = {
							glowEnabled = {
								type = "toggle",
								name = L["GLOW_ENABLED"],
								desc = L["GLOW_ENABLED_DESC"],
								order = 1,
								width = "full",
								get = function()
									return db().glowEnabled ~= false
								end,
								set = function(_, v)
									db().glowEnabled = v and true or false
									RefreshGlow(addon)
								end,
							},
							glowAutoFit = {
								type = "toggle",
								name = L["GLOW_AUTOFIT"],
								desc = L["GLOW_AUTOFIT_DESC"],
								order = 2,
								width = "full",
								get = function()
									return db().glowAutoFit ~= false
								end,
								set = function(_, v)
									db().glowAutoFit = v and true or false
									RefreshGlow(addon)
								end,
							},
							glowScale = {
								type = "range",
								name = L["GLOW_SCALE"],
								order = 3,
								min = 0.5,
								max = 2.5,
								step = 0.05,
								isPercent = true,
								get = function()
									return db().glowScale or 1
								end,
								set = function(_, v)
									db().glowScale = v
									RefreshGlow(addon)
								end,
							},
							glowOffsetX = {
								type = "range",
								name = L["GLOW_OFFSET_X"],
								order = 4,
								min = -40,
								max = 40,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().glowOffsetX or 0
								end,
								set = function(_, v)
									db().glowOffsetX = v
									RefreshGlow(addon)
								end,
							},
							glowOffsetY = {
								type = "range",
								name = L["GLOW_OFFSET_Y"],
								order = 5,
								min = -40,
								max = 40,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().glowOffsetY or 0
								end,
								set = function(_, v)
									db().glowOffsetY = v
									RefreshGlow(addon)
								end,
							},
							glowDisabledCooldowns = {
								type = "multiselect",
								name = L["GLOW_DISABLE_BUTTONS"],
								desc = L["GLOW_DISABLE_BUTTONS_DESC"],
								order = 6,
								values = function()
									return addon.Glow:ListVisibleCooldownOptions()
								end,
								get = function(_, key)
									local t = db().glowDisabledCooldowns or {}
									return t[key] and true or false
								end,
								set = function(_, key, value)
									db().glowDisabledCooldowns = db().glowDisabledCooldowns or {}
									if value then
										db().glowDisabledCooldowns[key] = true
									else
										db().glowDisabledCooldowns[key] = nil
									end
									RefreshGlow(addon)
								end,
							},
							glowDisabledSpellsInput = {
								type = "input",
								name = L["GLOW_DISABLE_SPELLS"],
								desc = L["GLOW_DISABLE_SPELLS_DESC"],
								order = 7,
								width = "full",
								multiline = false,
								get = function()
									local t = db().glowDisabledSpells or {}
									local ids = {}
									for id in pairs(t) do
										ids[#ids + 1] = tostring(id)
									end
									table.sort(ids, function(a, b)
										return tonumber(a) < tonumber(b)
									end)
									return table.concat(ids, ", ")
								end,
								set = function(_, v)
									local t = {}
									for part in string.gmatch(v or "", "[^,%s]+") do
										local id = tonumber(part)
										if id then
											t[id] = true
										end
									end
									db().glowDisabledSpells = t
									RefreshGlow(addon)
								end,
							},
						},
					},
					buffBar = {
						type = "group",
						name = L["BUFF_BAR"],
						order = 5,
						args = {
							buffBarEnabled = {
								type = "toggle",
								name = L["BUFF_BAR_ENABLED"],
								order = 1,
								width = "full",
								get = function()
									return db().buffBarEnabled ~= false
								end,
								set = function(_, v)
									db().buffBarEnabled = v and true or false
									RefreshSkin(addon)
								end,
							},
							buffBarStyle = {
								type = "select",
								name = L["BUFF_BAR_STYLE"],
								order = 2,
								values = {
									blizzard = L["BUFF_BAR_STYLE_BLIZZARD"],
									solid = L["BUFF_BAR_STYLE_SOLID"],
								},
								get = function()
									return db().buffBarStyle or "solid"
								end,
								set = function(_, v)
									db().buffBarStyle = v
									RefreshBuffBars(addon)
								end,
							},
							buffBarTexture = {
								type = "select",
								name = L["BUFF_BAR_TEXTURE"],
								desc = L["BUFF_BAR_TEXTURE_DESC"],
								order = 3,
								values = function()
									return addon.Skin.ListMedia("statusbar")
								end,
								disabled = function()
									local s = db().buffBarStyle or "solid"
									return s ~= "solid" and s ~= "SharedMedia"
								end,
								get = function()
									return db().buffBarTexture or "Solid"
								end,
								set = function(_, v)
									db().buffBarTexture = v
									RefreshBuffBars(addon)
								end,
							},
							buffBarBackgroundTexture = {
								type = "select",
								name = L["BUFF_BAR_BG_TEXTURE"],
								order = 4,
								values = function()
									return addon.Skin.ListMedia("statusbar")
								end,
								disabled = function()
									local s = db().buffBarStyle or "solid"
									return s ~= "solid" and s ~= "SharedMedia"
								end,
								get = function()
									return db().buffBarBackgroundTexture or "Solid"
								end,
								set = function(_, v)
									db().buffBarBackgroundTexture = v
									RefreshBuffBars(addon)
								end,
							},
							buffBarHeight = {
								type = "range",
								name = L["BUFF_BAR_HEIGHT"],
								order = 5,
								min = 4,
								max = 64,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().buffBarHeight or 16
								end,
								set = function(_, v)
									db().buffBarHeight = v
									RefreshBuffBars(addon)
								end,
							},
							buffBarWidth = {
								type = "range",
								name = L["BUFF_BAR_WIDTH"],
								order = 6,
								min = 0,
								max = 600,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().buffBarWidth or 0
								end,
								set = function(_, v)
									db().buffBarWidth = v
									RefreshLayout(addon)
									RefreshSkin(addon)
								end,
							},
							buffBarShowIcon = {
								type = "toggle",
								name = L["BUFF_BAR_SHOW_ICON"],
								order = 7,
								get = function()
									return db().buffBarShowIcon ~= false
								end,
								set = function(_, v)
									db().buffBarShowIcon = v and true or false
									RefreshSkin(addon)
								end,
							},
							buffBarShowName = {
								type = "toggle",
								name = L["BUFF_BAR_SHOW_NAME"],
								order = 8,
								get = function()
									return db().buffBarShowName ~= false
								end,
								set = function(_, v)
									db().buffBarShowName = v and true or false
									RefreshSkin(addon)
								end,
							},
							buffBarShowDuration = {
								type = "toggle",
								name = L["BUFF_BAR_SHOW_DURATION"],
								order = 9,
								get = function()
									return db().buffBarShowDuration ~= false
								end,
								set = function(_, v)
									db().buffBarShowDuration = v and true or false
									RefreshSkin(addon)
								end,
							},
							barSmoothProgress = {
								type = "toggle",
								name = L["BAR_SMOOTH"],
								desc = L["BAR_SMOOTH_DESC"],
								order = 8.5,
								width = "full",
								get = function()
									return db().barSmoothProgress == true
								end,
								set = function(_, v)
									db().barSmoothProgress = v and true or false
									RefreshSkin(addon)
								end,
							},
							buffBarColor = {
								type = "color",
								name = L["BUFF_BAR_COLOR"],
								order = 10,
								hasAlpha = true,
								disabled = function()
									local s = db().buffBarStyle or "solid"
									return s ~= "solid" and s ~= "SharedMedia"
								end,
								get = function()
									return getColor("buffBarColor", { r = 0.4, g = 0.6, b = 0.9, a = 1 })
								end,
								set = function(_, r, g, b, a)
									setColor("buffBarColor", r, g, b, a)
									RefreshBuffBars(addon)
								end,
							},
							buffBarBackgroundColor = {
								type = "color",
								name = L["BUFF_BAR_BG_COLOR"],
								order = 11,
								hasAlpha = true,
								disabled = function()
									local s = db().buffBarStyle or "solid"
									return s ~= "solid" and s ~= "SharedMedia"
								end,
								get = function()
									return getColor("buffBarBackgroundColor", { r = 0.1, g = 0.1, b = 0.1, a = 0.8 })
								end,
								set = function(_, r, g, b, a)
									setColor("buffBarBackgroundColor", r, g, b, a)
									RefreshBuffBars(addon)
								end,
							},
						},
					},
					powerBar = {
						type = "group",
						name = L["POWER_BAR"],
						order = 6,
						args = {
							powerBarEnabled = {
								type = "toggle",
								name = L["POWER_BAR_ENABLED"],
								desc = L["POWER_BAR_ENABLED_DESC"],
								order = 1,
								width = "full",
								get = function()
									return db().powerBarEnabled ~= false
								end,
								set = function(_, v)
									db().powerBarEnabled = v and true or false
									RefreshLayout(addon)
									RefreshSkin(addon)
								end,
							},
							powerBarShowSecondary = {
								type = "toggle",
								name = L["POWER_BAR_SECONDARY"],
								desc = L["POWER_BAR_SECONDARY_DESC"],
								order = 2,
								width = "full",
								get = function()
									return db().powerBarShowSecondary ~= false
								end,
								set = function(_, v)
									db().powerBarShowSecondary = v and true or false
									RefreshLayout(addon)
									RefreshSkin(addon)
								end,
							},
							powerBarShowText = {
								type = "toggle",
								name = L["POWER_BAR_SHOW_TEXT"],
								order = 3,
								get = function()
									return db().powerBarShowText ~= false
								end,
								set = function(_, v)
									db().powerBarShowText = v and true or false
									RefreshSkin(addon)
								end,
							},
							barSmoothProgress = {
								type = "toggle",
								name = L["BAR_SMOOTH"],
								desc = L["BAR_SMOOTH_DESC"],
								order = 3.2,
								width = "full",
								get = function()
									return db().barSmoothProgress == true
								end,
								set = function(_, v)
									db().barSmoothProgress = v and true or false
									RefreshSkin(addon)
								end,
							},
							powerBarHeight = {
								type = "range",
								name = L["POWER_BAR_HEIGHT"],
								order = 4,
								min = 1,
								max = 40,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().powerBarHeight or 10
								end,
								set = function(_, v)
									db().powerBarHeight = v
									RefreshLayout(addon)
									RefreshSkin(addon)
								end,
							},
							powerBarWidth = {
								type = "range",
								name = L["POWER_BAR_WIDTH"],
								order = 5,
								min = 0,
								max = 600,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().powerBarWidth or 0
								end,
								set = function(_, v)
									db().powerBarWidth = v
									RefreshLayout(addon)
									RefreshSkin(addon)
								end,
							},
							powerBarGap = {
								type = "range",
								name = L["POWER_BAR_GAP"],
								order = 6,
								min = 0,
								max = 40,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().powerBarGap or 2
								end,
								set = function(_, v)
									db().powerBarGap = v
									RefreshLayout(addon)
								end,
							},
							powerBarFontSize = {
								type = "range",
								name = L["POWER_BAR_FONT_SIZE"],
								order = 7,
								min = 8,
								max = 28,
								step = 1,
								get = function()
									return db().powerBarFontSize or 12
								end,
								set = function(_, v)
									db().powerBarFontSize = v
									RefreshSkin(addon)
								end,
							},
							powerBarFont = {
								type = "select",
								name = L["TEXT_FONT"],
								order = 7.4,
								values = function()
									return addon.Skin.ListMedia("font")
								end,
								get = function()
									return addon.Skin.ResolveFontName(db().powerBarFont or addon.Skin.DefaultFontName())
								end,
								set = function(_, v)
									db().powerBarFont = v
									RefreshSkin(addon)
								end,
							},
							powerBarTextOutline = {
								type = "select",
								name = L["TEXT_OUTLINE"],
								order = 7.5,
								values = OUTLINE_VALUES,
								get = function()
									local v = db().powerBarTextOutline or "OUTLINE"
									if v == "" then
										return "NONE"
									end
									return v
								end,
								set = function(_, v)
									db().powerBarTextOutline = (v == "NONE") and "" or v
									RefreshSkin(addon)
								end,
							},
							powerBarTexture = {
								type = "select",
								name = L["POWER_BAR_TEXTURE"],
								order = 8,
								values = function()
									return addon.Skin.ListMedia("statusbar")
								end,
								get = function()
									return db().powerBarTexture or "Solid"
								end,
								set = function(_, v)
									db().powerBarTexture = v
									RefreshSkin(addon)
								end,
							},
							powerBarBackgroundTexture = {
								type = "select",
								name = L["POWER_BAR_BG_TEXTURE"],
								order = 9,
								values = function()
									return addon.Skin.ListMedia("statusbar")
								end,
								get = function()
									return db().powerBarBackgroundTexture or "Solid"
								end,
								set = function(_, v)
									db().powerBarBackgroundTexture = v
									RefreshSkin(addon)
								end,
							},
							powerBarBackgroundColor = {
								type = "color",
								name = L["POWER_BAR_BG_COLOR"],
								order = 9.5,
								hasAlpha = true,
								get = function()
									return getColor("powerBarBackgroundColor", { r = 0.1, g = 0.1, b = 0.1, a = 0.85 })
								end,
								set = function(_, r, g, b, a)
									setColor("powerBarBackgroundColor", r, g, b, a)
									RefreshSkin(addon)
								end,
							},
							powerBarTextColor = {
								type = "color",
								name = L["POWER_BAR_TEXT_COLOR"],
								order = 9.6,
								hasAlpha = true,
								get = function()
									return getColor("powerBarTextColor", { r = 1, g = 1, b = 1, a = 1 })
								end,
								set = function(_, r, g, b, a)
									setColor("powerBarTextColor", r, g, b, a)
									RefreshSkin(addon)
								end,
							},
							powerBarEditClass = {
								type = "select",
								name = L["POWER_BAR_EDIT_CLASS"],
								desc = L["POWER_BAR_EDIT_CLASS_DESC"],
								order = 10,
								width = "full",
								values = function()
									local t = {}
									local files = addon.Skin.PowerBarClassFiles or { "DEFAULT" }
									for i = 1, #files do
										t[files[i]] = files[i]
									end
									return t
								end,
								get = function()
									return db().powerBarEditClass or "DEFAULT"
								end,
								set = function(_, v)
									db().powerBarEditClass = v
								end,
							},
							powerBarColorMode = {
								type = "select",
								name = L["POWER_BAR_COLOR_MODE"],
								desc = L["POWER_BAR_COLOR_MODE_DESC"],
								order = 11,
								values = {
									class = L["POWER_BAR_MODE_CLASS"],
									solid = L["POWER_BAR_MODE_SOLID"],
								},
								get = function()
									local cls = db().powerBarEditClass or "DEFAULT"
									local mode = addon.Skin.GetPowerBarProfile(db(), cls).colorMode or "class"
									if mode == "curve" then
										return "class"
									end
									return mode
								end,
								set = function(_, v)
									local cls = db().powerBarEditClass or "DEFAULT"
									addon.Skin.SetPowerBarProfileField(db(), cls, "colorMode", v)
									RefreshSkin(addon)
								end,
							},
							powerBarSolidColor = {
								type = "color",
								name = L["POWER_BAR_COLOR"],
								order = 12,
								hasAlpha = true,
								disabled = function()
									local cls = db().powerBarEditClass or "DEFAULT"
									return (addon.Skin.GetPowerBarProfile(db(), cls).colorMode or "class") ~= "solid"
								end,
								get = function()
									local cls = db().powerBarEditClass or "DEFAULT"
									local c = addon.Skin.GetPowerBarProfile(db(), cls).solidColor
										or { r = 0.55, g = 0.1, b = 0.1, a = 1 }
									return c.r or 1, c.g or 1, c.b or 1, c.a or 1
								end,
								set = function(_, r, g, b, a)
									local cls = db().powerBarEditClass or "DEFAULT"
									addon.Skin.SetPowerBarProfileField(db(), cls, "solidColor", { r = r, g = g, b = b, a = a })
									RefreshSkin(addon)
								end,
							},
						},
					},
				},
			},
			profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db),
		},
	}

	-- Reorganize root tabs by CDM block (not by theme: layout/text/border).
	local skinArgs = options.args.skin.args
	local layoutArgs = skinArgs.layout.args
	local sizeArgs = skinArgs.sizes.args
	local posArgs = skinArgs.positions.args

	local function takePos(key, orderBase)
		orderBase = orderBase or 50
		local enabled = posArgs[key .. "Enabled"]
		local point = posArgs[key .. "Point"]
		local x = posArgs[key .. "X"]
		local y = posArgs[key .. "Y"]
		if enabled then
			enabled.order = orderBase + 1
		end
		if point then
			point.order = orderBase + 2
		end
		if x then
			x.order = orderBase + 3
		end
		if y then
			y.order = orderBase + 4
		end
		return {
			posHeader = {
				type = "header",
				name = L["POSITIONS"],
				order = orderBase,
			},
			posHint = {
				type = "description",
				name = L["POSITIONS_DESC"],
				order = orderBase + 0.5,
				fontSize = "medium",
			},
			posEnabled = enabled,
			posPoint = point,
			posX = x,
			posY = y,
		}
	end

	local function mergeArgs(...)
		local out = {}
		for i = 1, select("#", ...) do
			local t = select(i, ...)
			if t then
				for k, v in pairs(t) do
					out[k] = v
				end
			end
		end
		return out
	end

	-- Shared icon chrome в†’ General
	local generalArgs = options.args.general.args
	generalArgs.iconStyleHeader = {
		type = "header",
		name = L["ICON_STYLE"],
		order = 20,
	}
	generalArgs.pixelSnap = layoutArgs.pixelSnap
	if generalArgs.pixelSnap then
		generalArgs.pixelSnap.order = 21
	end
	do
		local border = skinArgs.border.args
		for k, v in pairs(border) do
			v.order = 30 + (v.order or 0)
			generalArgs["border_" .. k] = v
		end
		local glow = skinArgs.glow.args
		for k, v in pairs(glow) do
			v.order = 80 + (v.order or 0)
			generalArgs["glow_" .. k] = v
		end
	end

	-- Per-block text lives under Essential / Utility / Buff / Buff bars (no global Text tab).

	if sizeArgs.essW then
		sizeArgs.essW.name = L["WIDTH"]
		sizeArgs.essW.order = 11
	end
	if sizeArgs.essH then
		sizeArgs.essH.name = L["HEIGHT"]
		sizeArgs.essH.order = 12
	end
	if sizeArgs.ess2W then
		sizeArgs.ess2W.name = L["SIZE_ESSENTIAL_ROW2"] .. " — " .. L["WIDTH"]
		sizeArgs.ess2W.order = 13
	end
	if sizeArgs.ess2H then
		sizeArgs.ess2H.name = L["SIZE_ESSENTIAL_ROW2"] .. " — " .. L["HEIGHT"]
		sizeArgs.ess2H.order = 14
	end
	if layoutArgs.spacing then
		layoutArgs.spacing.order = 5
	end
	if layoutArgs.maxIconsPerRow then
		layoutArgs.maxIconsPerRow.order = 6
	end

	local V = addon.CONST.VIEWERS
	options.args.essential = {
		type = "group",
		name = L["BLOCK_ESSENTIAL"],
		order = 2,
		args = mergeArgs({
			layoutHeader = { type = "header", name = L["LAYOUT"], order = 1 },
			spacing = layoutArgs.spacing,
			maxIconsPerRow = layoutArgs.maxIconsPerRow,
			sizeHeader = { type = "header", name = L["SIZE"], order = 10 },
			essW = sizeArgs.essW,
			essH = sizeArgs.essH,
			ess2W = sizeArgs.ess2W,
			ess2H = sizeArgs.ess2H,
		}, takePos("essential", 50), MakeIconTextArgs(V.ESSENTIAL, 100, true)),
	}

	if sizeArgs.utilW then
		sizeArgs.utilW.name = L["WIDTH"]
		sizeArgs.utilW.order = 11
	end
	if sizeArgs.utilH then
		sizeArgs.utilH.name = L["HEIGHT"]
		sizeArgs.utilH.order = 12
	end
	options.args.utility = {
		type = "group",
		name = L["BLOCK_UTILITY"],
		order = 3,
		args = mergeArgs({
			sizeHeader = { type = "header", name = L["SIZE"], order = 10 },
			utilW = sizeArgs.utilW,
			utilH = sizeArgs.utilH,
		}, takePos("utility", 50), MakeIconTextArgs(V.UTILITY, 100, true)),
	}

	if sizeArgs.buffW then
		sizeArgs.buffW.name = L["WIDTH"]
		sizeArgs.buffW.order = 11
	end
	if sizeArgs.buffH then
		sizeArgs.buffH.name = L["HEIGHT"]
		sizeArgs.buffH.order = 12
	end
	options.args.buff = {
		type = "group",
		name = L["BLOCK_BUFF"],
		order = 4,
		args = mergeArgs({
			sizeHeader = { type = "header", name = L["SIZE"], order = 10 },
			buffW = sizeArgs.buffW,
			buffH = sizeArgs.buffH,
		}, takePos("buff", 50), MakeIconTextArgs(V.BUFF, 100)),
	}

	options.args.buffBar = {
		type = "group",
		name = L["BLOCK_BUFF_BAR"],
		order = 5,
		args = mergeArgs(takePos("buffBar", 1), skinArgs.buffBar.args, MakeBuffBarTextArgs(100)),
	}
	for k, v in pairs(options.args.buffBar.args) do
		if type(k) == "string" and k:sub(1, 3) ~= "pos" and type(v) == "table" and v.order and v.order < 100 then
			v.order = 20 + (v.order or 0)
		end
	end

	options.args.powerBar = {
		type = "group",
		name = L["BLOCK_POWER"],
		order = 6,
		args = skinArgs.powerBar.args,
	}


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
							RebuildAuraSoundRuleArgs()
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
				RefreshSkin(addon)
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
				RefreshSkin(addon)
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
					RebuildAuraSoundRuleArgs()
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

	options.args.auraSounds = {
		type = "group",
		name = L["AURA_SOUNDS"],
		order = 8,
		args = auraSoundsArgs,
	}

	options.args.blizzard = {
		type = "group",
		name = L["BLIZZARD"],
		order = 90,
		args = {
			hint = {
				type = "description",
				name = L["BLIZZARD_DESC"],
				order = 1,
				fontSize = "medium",
			},
			openEditMode = {
				type = "execute",
				name = L["BLIZZARD_EDIT_MODE"],
				desc = L["BLIZZARD_EDIT_MODE_DESC"],
				order = 2,
				width = "full",
				func = OpenBlizzardEditMode,
			},
			openCooldownViewer = {
				type = "execute",
				name = L["BLIZZARD_CDM_SETTINGS"],
				desc = L["BLIZZARD_CDM_SETTINGS_DESC"],
				order = 3,
				width = "full",
				func = OpenBlizzardCooldownViewerSettings,
			},
		},
	}

	options.args.profiles.order = 99
	options.args.profiles.name = L["PROFILES"]

	do
		local share = {
			exportString = "",
			importString = "",
			importName = "",
			importMode = "new",
			status = "",
		}
		local function ImportErrorMessage(err)
			if err == "empty" then
				return L["PROFILE_IMPORT_ERR_EMPTY"]
			end
			if err == "encoding_unavailable" then
				return L["PROFILE_IMPORT_ERR_ENCODING"]
			end
			if err == "wrong_addon" then
				return L["PROFILE_IMPORT_ERR_ADDON"]
			end
			return L["PROFILE_IMPORT_ERR_INVALID"]
		end
		local args = options.args.profiles.args
		args.gcdmShareHeader = {
			type = "header",
			name = L["PROFILE_SHARE"],
			order = 200,
		}
		args.gcdmShareDesc = {
			type = "description",
			name = L["PROFILE_SHARE_DESC"],
			order = 201,
			fontSize = "medium",
		}
		args.gcdmExportBtn = {
			type = "execute",
			name = L["PROFILE_EXPORT"],
			order = 202,
			width = "full",
			func = function()
				local str, err = addon:ExportProfileString()
				if not str then
					share.status = L["PROFILE_EXPORT_ERR"] .. (err and (" (" .. err .. ")") or "")
					share.exportString = ""
				else
					share.exportString = str
					share.status = L["PROFILE_EXPORT_HINT"]
				end
			end,
		}
		args.gcdmExportString = {
			type = "input",
			name = L["PROFILE_EXPORT_STRING"],
			order = 203,
			width = "full",
			multiline = 6,
			get = function()
				return share.exportString
			end,
			set = function(_, v)
				share.exportString = v or ""
			end,
		}
		args.gcdmImportString = {
			type = "input",
			name = L["PROFILE_IMPORT_STRING"],
			order = 210,
			width = "full",
			multiline = 6,
			get = function()
				return share.importString
			end,
			set = function(_, v)
				share.importString = v or ""
			end,
		}
		args.gcdmImportName = {
			type = "input",
			name = L["PROFILE_IMPORT_NAME"],
			desc = L["PROFILE_IMPORT_NAME_DESC"],
			order = 211,
			width = "full",
			get = function()
				return share.importName
			end,
			set = function(_, v)
				share.importName = v or ""
			end,
		}
		args.gcdmImportMode = {
			type = "select",
			name = L["PROFILE_IMPORT_MODE"],
			order = 212,
			values = {
				new = L["PROFILE_IMPORT_MODE_NEW"],
				current = L["PROFILE_IMPORT_MODE_CURRENT"],
			},
			get = function()
				return share.importMode
			end,
			set = function(_, v)
				share.importMode = v
			end,
		}
		args.gcdmImportBtn = {
			type = "execute",
			name = L["PROFILE_IMPORT"],
			order = 213,
			width = "full",
			func = function()
				local name, err = addon:ImportProfileString(
					share.importString,
					share.importMode,
					(share.importName ~= "" and share.importName) or nil
				)
				if not name then
					share.status = ImportErrorMessage(err)
				else
					share.status = string.format(L["PROFILE_IMPORT_OK"], name)
					share.importString = ""
					LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
				end
			end,
		}
		args.gcdmShareStatus = {
			type = "description",
			name = function()
				return share.status or ""
			end,
			order = 220,
			fontSize = "medium",
		}
	end

	options.args.skin = nil
	options.args.bars = nil

	AceConfig:RegisterOptionsTable(ADDON_NAME, options)
	AceConfigDialog:SetDefaultSize(ADDON_NAME, 900, 640)
	AceConfigDialog:AddToBlizOptions(ADDON_NAME, L["ADDON_NAME"])

	local status = AceConfigDialog:GetStatusTable(ADDON_NAME)
	status.width = status.width or 900
	status.height = status.height or 640
end
