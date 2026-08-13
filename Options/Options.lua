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

	local options = {
		type = "group",
		name = L["ADDON_NAME"],
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
				args = {
					layout = {
						type = "group",
						name = L["LAYOUT"],
						order = 1,
						inline = true,
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
						inline = true,
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
						inline = true,
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
						inline = true,
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
					text = {
						type = "group",
						name = L["TEXT"],
						order = 3.5,
						inline = true,
						args = {
							textFont = {
								type = "select",
								name = L["TEXT_FONT"],
								desc = L["TEXT_FONT_DESC"],
								order = 1,
								values = function()
									return addon.Skin.ListMedia("font")
								end,
								get = function()
									return addon.Skin.ResolveFontName(db().textFont or addon.Skin.DefaultFontName())
								end,
								set = function(_, v)
									db().textFont = v
									RefreshSkin(addon)
								end,
							},
							textOutline = {
								type = "select",
								name = L["TEXT_OUTLINE"],
								order = 2,
								values = {
									NONE = L["TEXT_OUTLINE_NONE"],
									OUTLINE = L["TEXT_OUTLINE_OUTLINE"],
									THICKOUTLINE = L["TEXT_OUTLINE_THICK"],
									MONOCHROME = L["TEXT_OUTLINE_MONOCHROME"],
								},
								get = function()
									local v = db().textOutline or "OUTLINE"
									if v == "" then
										return "NONE"
									end
									return v
								end,
								set = function(_, v)
									db().textOutline = (v == "NONE") and "" or v
									RefreshSkin(addon)
								end,
							},
							cooldownHeader = {
								type = "header",
								name = L["COOLDOWN_TEXT"],
								order = 10,
							},
							cooldownFontSize = {
								type = "range",
								name = L["COOLDOWN_FONT_SIZE"],
								order = 11,
								min = 8,
								max = 32,
								step = 1,
								get = function()
									return db().cooldownFontSize or 14
								end,
								set = function(_, v)
									db().cooldownFontSize = v
									RefreshSkin(addon)
								end,
							},
							cooldownTextColor = {
								type = "color",
								name = L["COOLDOWN_TEXT_COLOR"],
								order = 12,
								hasAlpha = true,
								get = function()
									return getColor("cooldownTextColor", { r = 1, g = 1, b = 1, a = 1 })
								end,
								set = function(_, r, g, b, a)
									setColor("cooldownTextColor", r, g, b, a)
									RefreshSkin(addon)
								end,
							},
							cooldownTextPoint = {
								type = "select",
								name = L["COOLDOWN_TEXT_POINT"],
								order = 13,
								values = {
									CENTER = L["ANCHOR_CENTER"],
									TOP = L["ANCHOR_TOP"],
									BOTTOM = L["ANCHOR_BOTTOM"],
									LEFT = L["ANCHOR_LEFT"],
									RIGHT = L["ANCHOR_RIGHT"],
									TOPLEFT = L["ANCHOR_TOPLEFT"],
									TOPRIGHT = L["ANCHOR_TOPRIGHT"],
									BOTTOMLEFT = L["ANCHOR_BOTTOMLEFT"],
									BOTTOMRIGHT = L["ANCHOR_BOTTOMRIGHT"],
								},
								get = function()
									return db().cooldownTextPoint or "CENTER"
								end,
								set = function(_, v)
									db().cooldownTextPoint = v
									RefreshSkin(addon)
								end,
							},
							cooldownTextOffsetX = {
								type = "range",
								name = L["COOLDOWN_TEXT_OFFSET_X"],
								order = 14,
								min = -40,
								max = 40,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().cooldownTextOffsetX or 0
								end,
								set = function(_, v)
									db().cooldownTextOffsetX = v
									RefreshSkin(addon)
								end,
							},
							cooldownTextOffsetY = {
								type = "range",
								name = L["COOLDOWN_TEXT_OFFSET_Y"],
								order = 15,
								min = -40,
								max = 40,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().cooldownTextOffsetY or 0
								end,
								set = function(_, v)
									db().cooldownTextOffsetY = v
									RefreshSkin(addon)
								end,
							},
							stackHeader = {
								type = "header",
								name = L["STACK_TEXT"],
								order = 20,
							},
							stackFontSize = {
								type = "range",
								name = L["STACK_FONT_SIZE"],
								order = 21,
								min = 8,
								max = 32,
								step = 1,
								get = function()
									return db().stackFontSize or 12
								end,
								set = function(_, v)
									db().stackFontSize = v
									RefreshSkin(addon)
								end,
							},
							stackTextColor = {
								type = "color",
								name = L["STACK_TEXT_COLOR"],
								order = 22,
								hasAlpha = true,
								get = function()
									return getColor("stackTextColor", { r = 1, g = 1, b = 1, a = 1 })
								end,
								set = function(_, r, g, b, a)
									setColor("stackTextColor", r, g, b, a)
									RefreshSkin(addon)
								end,
							},
							stackTextPoint = {
								type = "select",
								name = L["STACK_TEXT_POINT"],
								order = 23,
								values = {
									CENTER = L["ANCHOR_CENTER"],
									TOP = L["ANCHOR_TOP"],
									BOTTOM = L["ANCHOR_BOTTOM"],
									LEFT = L["ANCHOR_LEFT"],
									RIGHT = L["ANCHOR_RIGHT"],
									TOPLEFT = L["ANCHOR_TOPLEFT"],
									TOPRIGHT = L["ANCHOR_TOPRIGHT"],
									BOTTOMLEFT = L["ANCHOR_BOTTOMLEFT"],
									BOTTOMRIGHT = L["ANCHOR_BOTTOMRIGHT"],
								},
								get = function()
									return db().stackTextPoint or "BOTTOMRIGHT"
								end,
								set = function(_, v)
									db().stackTextPoint = v
									RefreshSkin(addon)
								end,
							},
							stackTextOffsetX = {
								type = "range",
								name = L["STACK_TEXT_OFFSET_X"],
								order = 24,
								min = -40,
								max = 40,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().stackTextOffsetX or 0
								end,
								set = function(_, v)
									db().stackTextOffsetX = v
									RefreshSkin(addon)
								end,
							},
							stackTextOffsetY = {
								type = "range",
								name = L["STACK_TEXT_OFFSET_Y"],
								order = 25,
								min = -40,
								max = 40,
								step = FSTEP,
								bigStep = 1,
								get = function()
									return db().stackTextOffsetY or 0
								end,
								set = function(_, v)
									db().stackTextOffsetY = v
									RefreshSkin(addon)
								end,
							},
						},
					},
					glow = {
						type = "group",
						name = L["GLOW"],
						order = 4,
						inline = true,
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
						inline = true,
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
									return db().buffBarBackgroundTexture or db().buffBarTexture or "Solid"
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
				},
			},
			profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db),
		},
	}

	options.args.profiles.order = 99

	AceConfig:RegisterOptionsTable(ADDON_NAME, options)
	AceConfigDialog:SetDefaultSize(ADDON_NAME, 720, 560)
	AceConfigDialog:AddToBlizOptions(ADDON_NAME, L["ADDON_NAME"])
end
