local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local function EnsureOverlay(parent, key, r, g, b, a)
	local overlay = parent[key]
	if overlay then
		return overlay
	end
	overlay = parent:CreateTexture(nil, "OVERLAY", nil, 7)
	overlay:SetColorTexture(r, g, b, a)
	parent[key] = overlay
	return overlay
end

local function ClearOverlays(frame)
	for _, key in ipairs({ "GCDMDebugFrame", "GCDMDebugIcon" }) do
		local tex = frame[key]
		if tex then
			tex:Hide()
		end
	end
end

local function SafeNum(v)
	if type(v) ~= "number" then
		return -1
	end
	if canaccessvalue and not canaccessvalue(v) then
		return -1
	end
	-- Even without canaccessvalue, refuse secret-like values that break format/concat.
	local ok = pcall(function()
		return v == v and v > -1e12 and v < 1e12
	end)
	if not ok then
		return -1
	end
	return v
end

local function SafeStr(v)
	if v == nil then
		return "nil"
	end
	if canaccessvalue and (type(v) == "number" or type(v) == "string") and not canaccessvalue(v) then
		return "<secret>"
	end
	local ok, s = pcall(tostring, v)
	if not ok or type(s) ~= "string" then
		return "<err>"
	end
	if canaccessvalue and not canaccessvalue(s) then
		return "<secret>"
	end
	-- Ensure concat-safe plain string.
	local ok2 = pcall(function()
		return s .. ""
	end)
	if not ok2 then
		return "<secret>"
	end
	return s
end

local function SafeFormat(fmt, ...)
	local n = select("#", ...)
	local args = {}
	for i = 1, n do
		local a = select(i, ...)
		if type(a) == "number" then
			args[i] = SafeNum(a)
		elseif type(a) == "string" then
			args[i] = SafeStr(a)
		elseif type(a) == "boolean" then
			args[i] = a and "true" or "false"
		else
			args[i] = SafeStr(a)
		end
	end
	local ok, s = pcall(string.format, fmt, unpack(args))
	if not ok then
		return "<fmt err>"
	end
	return SafeStr(s)
end

local function DescribePoints(region)
	if not region or not region.GetNumPoints then
		return "?"
	end
	local parts = {}
	local okN, n = pcall(function()
		return region:GetNumPoints() or 0
	end)
	n = (okN and n) or 0
	for i = 1, n do
		local ok, point, relativeTo, relativePoint, x, y = pcall(function()
			return region:GetPoint(i)
		end)
		if ok then
			local relName = relativeTo and (relativeTo.GetName and relativeTo:GetName()) or SafeStr(relativeTo)
			parts[#parts + 1] = string.format(
				"%s->%s:%s (%.1f,%.1f)",
				SafeStr(point),
				SafeStr(relName),
				SafeStr(relativePoint),
				SafeNum(x),
				SafeNum(y)
			)
		end
	end
	return table.concat(parts, " | ")
end

local function DescribeTexCoord(icon)
	if not icon or not icon.GetTexCoord then
		return "n/a"
	end
	local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = icon:GetTexCoord()
	if URx then
		return string.format("UL(%.3f,%.3f) LR(%.3f,%.3f)", ULx or 0, ULy or 0, LRx or 0, LRy or 0)
	end
	-- older signature returns 4 values
	local left, right, top, bottom = icon:GetTexCoord()
	return string.format("l=%.3f r=%.3f t=%.3f b=%.3f", left or 0, right or 0, top or 0, bottom or 0)
end

local function ListTextures(frame)
	local list = {}
	if frame.Icon then list[#list + 1] = "Icon" end
	if frame.icon then list[#list + 1] = "icon" end
	if frame.IconBorder then list[#list + 1] = "IconBorder" end
	if frame.Border then list[#list + 1] = "Border" end
	if frame.Cooldown then list[#list + 1] = "Cooldown" end
	local regions = { frame:GetRegions() }
	for i = 1, #regions do
		local r = regions[i]
		if r and r.GetObjectType and r:GetObjectType() == "Texture" then
			local name = r.GetName and r:GetName() or ("anon" .. i)
			local draw = r.GetDrawLayer and r:GetDrawLayer() or "?"
			list[#list + 1] = string.format("%s[%s]", tostring(name), tostring(draw))
		end
	end
	return table.concat(list, ", ")
end

local function ApplyDebugVisuals()
	local db = GCDM:GetDB()
	local enabled = db and db.debugSkin

	Skin.ForEachManagedIcon(function(frame, viewer, viewerName)
		if not enabled then
			ClearOverlays(frame)
			return
		end

		local frameOverlay = EnsureOverlay(frame, "GCDMDebugFrame", 0, 1, 0, 0.25)
		frameOverlay:ClearAllPoints()
		frameOverlay:SetAllPoints(frame)
		frameOverlay:Show()

		local icon = Skin.GetIconTexture(frame)
		local iconOverlay = EnsureOverlay(frame, "GCDMDebugIcon", 1, 0, 1, 0.35)
		if icon then
			iconOverlay:ClearAllPoints()
			iconOverlay:SetAllPoints(icon)
			iconOverlay:Show()
		else
			iconOverlay:Hide()
		end
	end)

	Skin.ForEachBuffBar(function(frame)
		if not enabled then
			ClearOverlays(frame)
			if frame.Bar then
				ClearOverlays(frame.Bar)
			end
			if frame.GCDMSkinBar then
				ClearOverlays(frame.GCDMSkinBar)
			end
			return
		end
		local frameOverlay = EnsureOverlay(frame, "GCDMDebugFrame", 0, 1, 1, 0.35)
		frameOverlay:ClearAllPoints()
		frameOverlay:SetAllPoints(frame)
		frameOverlay:Show()
		if frame.Bar then
			local barOverlay = EnsureOverlay(frame.Bar, "GCDMDebugFrame", 1, 1, 0, 0.35)
			barOverlay:ClearAllPoints()
			barOverlay:SetAllPoints(frame.Bar)
			barOverlay:Show()
		end
		if frame.GCDMSkinBar then
			local skinOverlay = EnsureOverlay(frame.GCDMSkinBar, "GCDMDebugFrame", 1, 0, 1, 0.45)
			skinOverlay:ClearAllPoints()
			skinOverlay:SetAllPoints(frame.GCDMSkinBar)
			skinOverlay:Show()
		end
	end)
end

local function Emit(msg)
	msg = SafeStr(msg)
	-- print alone — AddMessage+print duplicates every chat line.
	print("|cff3bb273GCDM|r " .. msg)
end

local function EnsureDumpFrame()
	local f = GCDMBuffBarDumpFrame
	if f then
		return f
	end
	f = CreateFrame("Frame", "GCDMBuffBarDumpFrame", UIParent, "BackdropTemplate")
	f:SetSize(520, 360)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -14)
	title:SetText("GCDM dump — Ctrl+A, Ctrl+C, paste to chat")

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 16, -40)
	scroll:SetPoint("BOTTOMRIGHT", -36, 16)

	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetFontObject(GameFontHighlightSmall)
	edit:SetWidth(460)
	edit:SetAutoFocus(false)
	edit:SetScript("OnEscapePressed", function()
		f:Hide()
	end)
	scroll:SetScrollChild(edit)
	f.edit = edit
	f:Hide()
	return f
end

local function ShowDumpWindow(text)
	local f = EnsureDumpFrame()
	f.edit:SetText(text or "")
	f.edit:HighlightText()
	f.edit:SetFocus()
	f:Show()
end

function GCDM:DumpBuffBarDebug()
	local lines = {}
	local function L(s)
		local ok, text = pcall(function()
			if type(s) == "string" then
				return s
			end
			return SafeStr(s)
		end)
		if not ok then
			lines[#lines + 1] = "<line err>"
			return
		end
		-- Scrub any secret payload that slipped into the string via format.
		if canaccessvalue and type(text) == "string" and not canaccessvalue(text) then
			lines[#lines + 1] = "<secret line>"
			return
		end
		lines[#lines + 1] = SafeStr(text)
	end

	local ok, err = pcall(function()
		if self.Refresh and self.CONST and self.CONST.REFRESH then
			self:Refresh(self.CONST.REFRESH.LAYOUT)
		end
		local db = self:GetDB()
		local viewer = self.ViewerRegistry and self.ViewerRegistry:BuffBar()
		local essential = self.ViewerRegistry and self.ViewerRegistry:Essential()
		local editMode = false
		if self.IsEditModeActive then
			editMode = self:IsEditModeActive() and true or false
		end

		-- Sample live on-screen state (no Refresh — keep the mismatch visible).
		L("---- GCDM layout/buff debug ----")
		local styleRaw = db and db.buffBarStyle
		local styleResolved = "solid"
		if styleRaw and styleRaw ~= "solid" and styleRaw ~= "SharedMedia" and styleRaw ~= "sharedmedia" then
			styleResolved = styleRaw
		end
		local texName = (db and db.buffBarTexture) or "Solid"
		local bgName = (db and db.buffBarBackgroundTexture) or texName
		local texPath = Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(texName)
		local bgPath = Skin.FetchStatusBarTexture and Skin.FetchStatusBarTexture(bgName)
		local fill = db and db.buffBarColor or {}
		local bgc = db and db.buffBarBackgroundColor or {}
		local sizeE = db and db.sizeEssential or {}
		local spacing = db and db.spacing or 0
		local maxRow = db and db.maxIconsPerRow or 7
		local iw = SafeNum(sizeE.w)
		if iw < 0 then
			iw = 46
		end
		local formulaW = (maxRow * iw) + ((maxRow - 1) * (tonumber(spacing) or 0))
		L(SafeFormat(
			"enabled=%s buffBarEnabled=%s powerBarEnabled=%s styleRaw=%s styleResolved=%s editMode=%s",
			tostring(db and db.enabled),
			tostring(db and db.buffBarEnabled),
			tostring(db and db.powerBarEnabled),
			tostring(styleRaw),
			tostring(styleResolved),
			tostring(editMode)
		))
		L(SafeFormat(
			"h=%s wSetting=%s showIcon=%s showName=%s showTimer=%s",
			tostring(db and db.buffBarHeight),
			tostring(db and db.buffBarWidth),
			tostring(db and db.buffBarShowIcon),
			tostring(db and db.buffBarShowName),
			tostring(db and db.buffBarShowDuration)
		))
		L(SafeFormat(
			"sizeEssential=%sx%s spacing=%s maxRow=%s formulaW=%.1f EssentialLayoutWidth=%s",
			tostring(sizeE.w),
			tostring(sizeE.h),
			tostring(spacing),
			tostring(maxRow),
			SafeNum(formulaW),
			SafeStr(Skin.EssentialLayoutWidth)
		))
		L(SafeFormat(
			"tex=%s path=%s | bg=%s path=%s",
			tostring(texName),
			tostring(texPath),
			tostring(bgName),
			tostring(bgPath)
		))
		L(SafeFormat(
			"fill=%.2f,%.2f,%.2f,%.2f bg=%.2f,%.2f,%.2f,%.2f",
			SafeNum(fill.r), SafeNum(fill.g), SafeNum(fill.b), SafeNum(fill.a),
			SafeNum(bgc.r), SafeNum(bgc.g), SafeNum(bgc.b), SafeNum(bgc.a)
		))
		L(SafeFormat(
			"mixins BuffBarItem=%s BuffBarViewer=%s",
			tostring(CooldownViewerBuffBarItemMixin ~= nil),
			tostring(BuffBarCooldownViewerMixin ~= nil)
		))

		if not viewer then
			L("BuffBarCooldownViewer: MISSING _G=" .. tostring(_G.BuffBarCooldownViewer))
			return
		end

		local parent = viewer:GetParent()
		local parentName = parent and parent.GetName and parent:GetName() or tostring(parent)
		local vLeft, vRight = viewer:GetLeft(), viewer:GetRight()
		L(SafeFormat(
			"viewer shown=%s alpha=%.2f size=%.1fx%.1f left=%.1f right=%.1f parent=%s baseW=%s scale=%s",
			tostring(viewer:IsShown()),
			SafeNum(viewer:GetAlpha()),
			SafeNum(viewer:GetWidth()),
			SafeNum(viewer:GetHeight()),
			SafeNum(vLeft),
			SafeNum(vRight),
			tostring(parentName),
			tostring(viewer.baseBarWidth),
			tostring(viewer.barWidthScale)
		))
		L("viewer points: " .. DescribePoints(viewer))

		if essential then
			local eLeft, eRight = essential:GetLeft(), essential:GetRight()
			L(SafeFormat(
				"essential size=%.1fx%.1f left=%.1f right=%.1f shown=%s",
				SafeNum(essential:GetWidth()),
				SafeNum(essential:GetHeight()),
				SafeNum(eLeft),
				SafeNum(eRight),
				tostring(essential:IsShown())
			))
			if type(vRight) == "number" and type(eRight) == "number" then
				L(SafeFormat(
					"deltaRight(bar-ess)=%.1f deltaLeft(bar-ess)=%.1f deltaW(bar-ess)=%.1f",
					SafeNum(vRight - eRight),
					SafeNum((vLeft or 0) - (eLeft or 0)),
					SafeNum((viewer:GetWidth() or 0) - (essential:GetWidth() or 0))
				))
			end
			L("essential points: " .. DescribePoints(essential))
		else
			L("essential: MISSING")
		end

		do
			local ph = self.GetPowerBarHost and self:GetPowerBarHost() or _G.GCDM_PowerBarHost
			local primary = _G.GCDM_PowerBarPrimary
			L(SafeFormat(
				"powerBarEnabled=%s height=%s widthSetting=%s gap=%s tex=%s",
				tostring(db and db.powerBarEnabled),
				tostring(db and db.powerBarHeight),
				tostring(db and db.powerBarWidth),
				tostring(db and db.powerBarGap),
				tostring(db and db.powerBarTexture)
			))
			if ph then
				L(SafeFormat(
					"PowerHost shown=%s a=%.2f size=%.1fx%.1f left=%.1f right=%.1f strata=%s level=%s parent=%s",
					SafeStr(ph:IsShown()),
					SafeNum(ph:GetAlpha()),
					SafeNum(ph:GetWidth()),
					SafeNum(ph:GetHeight()),
					SafeNum(ph:GetLeft()),
					SafeNum(ph:GetRight()),
					SafeStr(ph:GetFrameStrata()),
					SafeStr(ph:GetFrameLevel()),
					SafeStr(ph:GetParent() and ph:GetParent():GetName())
				))
				L("PowerHost points: " .. DescribePoints(ph))
			else
				L("PowerHost: MISSING (ApplyPowerBars never created host)")
			end
			if primary then
				local st = primary.GetStatusBarTexture and primary:GetStatusBarTexture()
				local mn, mx, cur = 0, 0, 0
				pcall(function()
					mn, mx = primary:GetMinMaxValues()
					cur = primary:GetValue()
				end)
				L(SafeFormat(
					"PowerPrimary shown=%s a=%.2f size=%.1fx%.1f values=%.2f/%.2f/%.2f hasTex=%s",
					SafeStr(primary:IsShown()),
					SafeNum(primary:GetAlpha()),
					SafeNum(primary:GetWidth()),
					SafeNum(primary:GetHeight()),
					SafeNum(mn),
					SafeNum(mx),
					SafeNum(cur),
					tostring(st ~= nil)
				))
			else
				L("PowerPrimary: MISSING")
			end
		end

		local function DumpViewerIcons(label, v)
			if not v then
				L(label .. ": MISSING")
				return
			end
			local icons = Skin.CollectIconFrames(v)
			L(SafeFormat("%s CollectIconFrames=%d size=%.1fx%.1f", label, #icons, SafeNum(v:GetWidth()), SafeNum(v:GetHeight())))
			for i = 1, math.min(#icons, 16) do
				local frame = icons[i]
				local icon = Skin.GetIconTexture(frame)
				local tex = "?"
				if icon and icon.GetTexture then
					local okT, t = pcall(icon.GetTexture, icon)
					tex = okT and SafeStr(t) or "<err>"
				end
				local active = "?"
				if frame.IsActive then
					local okA, a = pcall(frame.IsActive, frame)
					active = okA and SafeStr(a) or "<err>"
				end
				local parked = frame.GCDMAnchor and frame.GCDMAnchor[4] == -10000
				L(SafeFormat(
					"  %s#%d shown=%s a=%.2f %.0fx%.0f left=%.1f idx=%s cd=%s active=%s parked=%s tex=%s",
					label,
					i,
					SafeStr(frame:IsShown()),
					SafeNum(frame:GetAlpha()),
					SafeNum(frame:GetWidth()),
					SafeNum(frame:GetHeight()),
					SafeNum(frame:GetLeft()),
					SafeStr(frame.layoutIndex),
					SafeStr(frame.cooldownID),
					SafeStr(active),
					tostring(parked),
					SafeStr(tex)
				))
			end
		end

		local registry = self.ViewerRegistry
		DumpViewerIcons("ESS", essential)
		DumpViewerIcons("UTIL", registry and registry:Utility())
		DumpViewerIcons("BUFF", registry and registry:Buff())

		local last = self._buffBarLastApply
		if last then
			L(SafeFormat(
				"lastApply bars=%s shown=%s w=%.1f h=%.1f err=%s",
				tostring(last.bars),
				tostring(last.shown),
				SafeNum(last.width),
				SafeNum(last.height),
				tostring(last.err)
			))
		else
			L("lastApply: none (skin never applied?)")
		end

		local bars = Skin.CollectBarFrames(viewer)
		L(SafeFormat(
			"CollectBarFrames=%d pool=%s itemFrames=%s",
			#bars,
			tostring(viewer.itemFramePool ~= nil),
			tostring(viewer.itemFrames ~= nil)
		))

		if #bars == 0 then
			local children = { viewer:GetChildren() }
			L("raw children=" .. tostring(#children))
			for i = 1, math.min(#children, 8) do
				local c = children[i]
				L(SafeFormat(
					" child#%d type=%s Bar=%s shown=%s %.1fx%.1f",
					i,
					c and c.GetObjectType and c:GetObjectType() or "?",
					tostring(c and c.Bar ~= nil),
					tostring(c and c:IsShown()),
					SafeNum(c and c:GetWidth()),
					SafeNum(c and c:GetHeight())
				))
			end
		end

		for i = 1, math.min(#bars, 6) do
			local frame = bars[i]
			local bar = frame.Bar
			local sb = bar and bar.GetStatusBarTexture and bar:GetStatusBarTexture()
			local sbTex = sb and sb.GetTexture and sb:GetTexture()
			local sbAtlas = sb and sb.GetAtlas and sb:GetAtlas()
			local sbAlpha = sb and sb.GetAlpha and sb:GetAlpha()
			local pip = bar and bar.Pip
			local nameFS = bar and bar.Name
			local durFS = bar and bar.Duration
			local skin = frame.GCDMSkinBar
			local skinTexObj = skin and skin.GetStatusBarTexture and skin:GetStatusBarTexture()
			local skinTex = skinTexObj and skinTexObj.GetTexture and skinTexObj:GetTexture()
			local activeStr = "?"
			if frame.IsActive then
				local okA, a = pcall(frame.IsActive, frame)
				activeStr = okA and SafeStr(a) or "<err>"
			end
			L(SafeFormat(
				"#%d frame shown=%s a=%.2f %.1fx%.1f want=%.1fx%.1f left=%.1f right=%.1f active=%s",
				i,
				tostring(frame:IsShown()),
				SafeNum(frame:GetAlpha()),
				SafeNum(frame:GetWidth()),
				SafeNum(frame:GetHeight()),
				SafeNum(frame.GCDMWantW),
				SafeNum(frame.GCDMWantH),
				SafeNum(frame:GetLeft()),
				SafeNum(frame:GetRight()),
				activeStr
			))
			L("  frame: " .. DescribePoints(frame))
			if bar then
				L(SafeFormat(
					"  Bar shown=%s a=%.2f %.1fx%.1f blizzTex=%s atlas=%s texA=%.2f",
					tostring(bar:IsShown()),
					SafeNum(bar:GetAlpha()),
					SafeNum(bar:GetWidth()),
					SafeNum(bar:GetHeight()),
					tostring(sbTex),
					tostring(sbAtlas),
					SafeNum(sbAlpha)
				))
				L("  bar:   " .. DescribePoints(bar))
				local minV, maxV = 0, 0
				if bar.GetMinMaxValues then
					minV, maxV = bar:GetMinMaxValues()
				end
				L(SafeFormat(
					"  values min=%.2f max=%.2f cur=%.2f",
					SafeNum(minV),
					SafeNum(maxV),
					SafeNum(bar.GetValue and bar:GetValue())
				))
				L(SafeFormat(
					"  Pip=%s shown=%s a=%.2f | Name a=%.2f shown=%s | Dur a=%.2f shown=%s",
					pip and "yes" or "NO",
					tostring(pip and pip:IsShown()),
					SafeNum(pip and pip.GetAlpha and pip:GetAlpha()),
					SafeNum(nameFS and nameFS.GetAlpha and nameFS:GetAlpha()),
					tostring(nameFS and nameFS:IsShown()),
					SafeNum(durFS and durFS.GetAlpha and durFS:GetAlpha()),
					tostring(durFS and durFS:IsShown())
				))
				if nameFS and nameFS.GetText then
					local okText, text = pcall(nameFS.GetText, nameFS)
					L("  NameText=" .. SafeStr(okText and text or "?"))
				end
			else
				L("  Bar: NO")
			end
			if skin then
				L(SafeFormat(
					"  GCDMSkinBar shown=%s a=%.2f %.1fx%.1f tex=%s level=%s",
					SafeStr(skin:IsShown()),
					SafeNum(skin:GetAlpha()),
					SafeNum(skin:GetWidth()),
					SafeNum(skin:GetHeight()),
					SafeStr(skinTex),
					SafeStr(skin.GetFrameLevel and skin:GetFrameLevel())
				))
				L("  skin:  " .. DescribePoints(skin))
			else
				L("  GCDMSkinBar: MISSING (solid overlay never created)")
			end
			L(SafeFormat(
				"  Icon shown=%s a=%.2f | borderBar=%s borderIcon=%s",
				SafeStr(frame.Icon and frame.Icon:IsShown()),
				SafeNum(frame.Icon and frame.Icon.GetAlpha and frame.Icon:GetAlpha()),
				SafeStr(frame.GCDMBarBorder ~= nil),
				SafeStr(frame.GCDMBarIconBorder ~= nil)
			))
		end

		local pos = db and db.viewerPos and db.viewerPos.buffBar
		if pos then
			L(SafeFormat(
				"viewerPos.buffBar en=%s point=%s x=%s y=%s",
				SafeStr(pos.enabled),
				SafeStr(pos.point),
				SafeStr(pos.x),
				SafeStr(pos.y)
			))
		end
		local posB = db and db.viewerPos and db.viewerPos.buff
		if posB then
			L(SafeFormat(
				"viewerPos.buff en=%s point=%s x=%s y=%s",
				SafeStr(posB.enabled),
				SafeStr(posB.point),
				SafeStr(posB.x),
				SafeStr(posB.y)
			))
		end
		local posE = db and db.viewerPos and db.viewerPos.essential
		if posE then
			L(SafeFormat(
				"viewerPos.essential en=%s point=%s x=%s y=%s",
				SafeStr(posE.enabled),
				SafeStr(posE.point),
				SafeStr(posE.x),
				SafeStr(posE.y)
			))
		end
		L("---- end ----")
	end)

	if not ok then
		L("DUMP ERROR: " .. SafeStr(err))
	end

	-- Sanitize every line before concat (Midnight secret values).
	local clean = {}
	for i = 1, #lines do
		clean[i] = SafeStr(lines[i])
	end
	local text = table.concat(clean, "\n")
	self._lastBuffBarDump = text
	if self.db and self.db.profile then
		self.db.profile._lastBuffBarDump = text
	end

	Emit("Dump ready — popup: Ctrl+A Ctrl+C, paste in chat")
	if UIErrorsFrame and UIErrorsFrame.AddMessage then
		UIErrorsFrame:AddMessage("GCDM dump: Ctrl+A Ctrl+C", 0.2, 1, 0.4)
	end
	-- Short chat breadcrumbs (avoid flood).
	for i = 1, math.min(#clean, 8) do
		Emit(clean[i])
	end
	if #clean > 8 then
		Emit("... +" .. tostring(#clean - 8) .. " lines in popup")
	end
	ShowDumpWindow(text)
end

function GCDM:DumpSkinDebug()
	local db = self:GetDB()
	self:Print(string.format("GCDM debugSkin=%s zoom=%.3f border=%s",
		tostring(db and db.debugSkin),
		db and db.iconZoom or -1,
		db and db.borderSize or -1
	))

	local count = 0
	Skin.ForEachManagedIcon(function(frame, viewer, viewerName)
		count = count + 1
		if count > 8 then
			return
		end
		local icon = Skin.GetIconTexture(frame)
		local fw, fh = frame:GetWidth() or 0, frame:GetHeight() or 0
		local iw, ih = 0, 0
		if icon then
			iw, ih = icon:GetWidth() or 0, icon:GetHeight() or 0
		end
		local fname = frame.GetName and frame:GetName() or "<anon>"
		self:Print(string.format(
			"#%d %s/%s frame=%.1fx%.1f icon=%s %.1fx%.1f tex=%s masks=%d",
			count,
			tostring(viewerName),
			tostring(fname),
			fw, fh,
			icon and "yes" or "NO",
			iw, ih,
			DescribeTexCoord(icon),
			Skin.CountIconMasks(frame)
		))
		self:Print("  points frame: " .. DescribePoints(frame))
		if icon then
			self:Print("  points icon:  " .. DescribePoints(icon))
		end
		self:Print("  regions: " .. ListTextures(frame))
		if count == 1 and Skin.DescribeRegions then
			local details = Skin.DescribeRegions(frame)
			for i = 1, #details do
				self:Print("    " .. details[i])
			end
		end
	end)

	if count == 0 then
		self:Print("No managed icon frames found. Is Cooldown Manager enabled?")
	else
		self:Print(string.format("Dumped %d icon(s) (max 8). Green=frame Magenta=icon texture.", math.min(count, 8)))
	end
end

function GCDM:ToggleDebugSkin()
	local db = self:GetDB()
	if not db then
		return
	end
	db.debugSkin = not db.debugSkin
	self:Print("debugSkin = " .. tostring(db.debugSkin))
	self:Refresh(self.CONST.REFRESH.STYLE)
	if db.debugSkin then
		self:DumpSkinDebug()
	end
end

GCDM:RegisterRefreshCallback("Skin.Debug", ApplyDebugVisuals, 90, {
	GCDM.CONST.REFRESH.ALL,
	GCDM.CONST.REFRESH.STYLE,
})
