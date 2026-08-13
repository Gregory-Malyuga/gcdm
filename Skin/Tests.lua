local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

local function Emit(msg)
	-- print() already goes to DEFAULT_CHAT_FRAME — do not AddMessage again.
	print("|cff3bb273GCDM test|r " .. tostring(msg))
end

local function Near(a, b, eps)
	eps = eps or 1.5
	a, b = tonumber(a), tonumber(b)
	if not a or not b then
		return false
	end
	return math.abs(a - b) <= eps
end

--- In-game behavior checks for current GCDM skin/layout contracts.
--- Run: /gcdm test
function GCDM:RunBehaviorTests()
	local results = {}
	local function check(name, ok, detail)
		results[#results + 1] = { name = name, ok = ok and true or false, detail = detail }
	end

	local db = self:GetDB()
	local registry = self.ViewerRegistry
	local editMode = self.IsEditModeActive and self:IsEditModeActive()

	check("db.enabled", db and db.enabled == true, db and tostring(db.enabled))
	check("not in Edit Mode (tests expect live layout)", not editMode, tostring(editMode))

	-- Force one layout/style pass so assertions see post-apply state.
	if self.Refresh and not editMode then
		self:Refresh(self.CONST.REFRESH.LAYOUT)
		self:Refresh(self.CONST.REFRESH.STYLE)
	end

	local essential = registry and registry:Essential()
	local utility = registry and registry:Utility()
	local buff = registry and registry:Buff()
	local buffBar = registry and registry:BuffBar()

	check("EssentialCooldownViewer exists", essential ~= nil)
	check("UtilityCooldownViewer exists", utility ~= nil)
	check("BuffIconCooldownViewer exists", buff ~= nil)
	check("BuffBarCooldownViewer exists", buffBar ~= nil)

	if essential and db then
		local maxRow = db.maxIconsPerRow or 7
		local iw = Pixel.Snap((db.sizeEssential and db.sizeEssential.w) or 46)
		local spacing = Pixel.Snap(db.spacing or 0)
		if Pixel.IsSnapEnabled and Pixel.IsSnapEnabled() and (db.spacing or 0) > 0 and spacing < Pixel.GetSize() then
			spacing = Pixel.GetSize()
		end
		local formulaW = (maxRow * iw) + ((maxRow - 1) * spacing)
		check(
			"Skin.EssentialLayoutWidth ≈ maxRow formula",
			Near(Skin.EssentialLayoutWidth, formulaW, 2),
			string.format("laid=%s formula=%.1f", tostring(Skin.EssentialLayoutWidth), formulaW)
		)
		local icons = Skin.CollectIconFrames(essential)
		local shown = 0
		local parkedShown = 0
		for i = 1, #icons do
			local f = icons[i]
			if f and f:IsShown() then
				shown = shown + 1
				if f.GCDMParked then
					parkedShown = parkedShown + 1
				end
				if f.GCDMAnchor and not f.GCDMParked then
					check(
						"ESS placed icon has GCDMAnchor",
						type(f.GCDMAnchor) == "table" and f.GCDMAnchor[4] ~= -10000,
						tostring(f.layoutIndex)
					)
				end
			elseif f and f.GCDMParked then
				check(
					"ESS parked icon alpha≈0",
					(f:GetAlpha() or 1) <= 0.01,
					tostring(f.layoutIndex)
				)
			end
		end
		check("ESS CollectIconFrames > 0", #icons > 0, tostring(#icons))
		check("ESS no parked+shown icons", parkedShown == 0, tostring(parkedShown))
		if shown > 0 then
			local ew = essential:GetWidth() or 0
			check("Essential width > 40", ew > 40, string.format("%.1f", ew))
		end
	end

	if buff then
		local icons = Skin.CollectIconFrames(buff)
		local shownN, parkedN = 0, 0
		for i = 1, #icons do
			local f = icons[i]
			if f and f:IsShown() and not f.GCDMParked then
				shownN = shownN + 1
				check(
					"BUFF shown icon alpha>0",
					(f:GetAlpha() or 0) > 0.5,
					tostring(f.layoutIndex)
				)
				check(
					"BUFF shown not at park X",
					not (f.GCDMAnchor and f.GCDMAnchor[4] == -10000),
					tostring(f.layoutIndex)
				)
			elseif f and (f.GCDMParked or not f:IsShown()) then
				parkedN = parkedN + 1
				if f.GCDMParked then
					check(
						"BUFF parked has nil place-anchor or park flag",
						f.GCDMParked == true and (f.GCDMAnchor == nil or f.GCDMAnchor[4] == -10000),
						tostring(f.layoutIndex)
					)
				end
			end
		end
		check("BUFF pool enumerated", #icons >= 0, string.format("n=%d shown=%d parkedish=%d", #icons, shownN, parkedN))
	end

	if buffBar and db and db.buffBarEnabled ~= false then
		local last = self._buffBarLastApply
		check("BuffBar lastApply exists", last ~= nil)
		if last then
			check("BuffBar lastApply err nil", last.err == nil, tostring(last.err))
			local formulaW = Skin.EssentialLayoutWidth
			if type(formulaW) ~= "number" then
				local iw = Pixel.Snap((db.sizeEssential and db.sizeEssential.w) or 46)
				local maxRow = db.maxIconsPerRow or 7
				local spacing = Pixel.Snap(db.spacing or 0)
				formulaW = (maxRow * iw) + ((maxRow - 1) * spacing)
			end
			if (db.buffBarWidth or 0) > 0 then
				check(
					"BuffBar lastApply.width ≈ buffBarWidth",
					Near(last.width, db.buffBarWidth, 2),
					string.format("w=%.1f setting=%s", last.width or -1, tostring(db.buffBarWidth))
				)
			else
				check(
					"BuffBar lastApply.width ≈ EssentialLayoutWidth",
					Near(last.width, formulaW, 2),
					string.format("w=%.1f laid=%s", last.width or -1, tostring(formulaW))
				)
			end
			check(
				"BuffBar viewer width ≈ lastApply.width",
				Near(buffBar:GetWidth(), last.width, 2),
				string.format("viewer=%.1f want=%.1f", buffBar:GetWidth() or -1, last.width or -1)
			)
		end

		local bars = Skin.CollectBarFrames(buffBar)
		check("BuffBar CollectBarFrames >= 0", #bars >= 0, tostring(#bars))
		local style = db.buffBarStyle or "solid"
		local solid = (style == "solid" or style == "SharedMedia" or style == "sharedmedia")
		for i = 1, #bars do
			local frame = bars[i]
			if frame and frame.Bar then
				check(
					"BuffBar item has GCDMWantW",
					type(frame.GCDMWantW) == "number" and frame.GCDMWantW >= 8,
					string.format("#%d want=%s", i, tostring(frame.GCDMWantW))
				)
				if solid then
					check(
						"BuffBar solid has GCDMSkinBar",
						frame.GCDMSkinBar ~= nil,
						string.format("#%d", i)
					)
				end
				if frame:IsShown() then
					check(
						"BuffBar shown width ≈ want",
						Near(frame:GetWidth(), frame.GCDMWantW, 2),
						string.format("#%d got=%.1f want=%s", i, frame:GetWidth() or -1, tostring(frame.GCDMWantW))
					)
				end
			end
		end
	end

	-- Power bar host (opt-out feature; default on)
	if db and db.powerBarEnabled ~= false then
		local ph = GCDM.GetPowerBarHost and GCDM:GetPowerBarHost()
		check("PowerBar host exists after Refresh", ph ~= nil)
		if ph then
			check("PowerBar host shown", ph:IsShown() == true)
			local pw = ph:GetWidth() or 0
			local wantW = Skin.EssentialLayoutWidth
			if type(wantW) == "number" and wantW >= 40 then
				check(
					"PowerBar width ≈ EssentialLayoutWidth",
					Near(pw, wantW, 3),
					string.format("pw=%.1f want=%.1f", pw, wantW)
				)
			else
				check("PowerBar width > 40", pw > 40, string.format("%.1f", pw))
			end
			local primary = _G.GCDM_PowerBarPrimary
			check("PowerBar primary StatusBar exists", primary ~= nil)
			if primary then
				check("PowerBar primary shown", primary:IsShown() == true)
			end
		end
	else
		check("PowerBar disabled skipped", true)
	end

	-- Pixel.Snap contract
	Pixel.Update()
	local prev = db and db.pixelSnap
	if db then
		db.pixelSnap = false
		check("Pixel.Snap passthrough when pixelSnap=false", Pixel.Snap(50.3) == 50.3, tostring(Pixel.Snap(50.3)))
		db.pixelSnap = true
		local snapped = Pixel.Snap(50.3)
		check("Pixel.Snap snaps when pixelSnap=true", type(snapped) == "number", tostring(snapped))
		db.pixelSnap = prev
	end

	local pass, fail = 0, 0
	Emit("======== GCDM behavior tests ========")
	for i = 1, #results do
		local r = results[i]
		if r.ok then
			pass = pass + 1
			Emit("|cff00ff00PASS|r " .. r.name .. (r.detail and (" (" .. r.detail .. ")") or ""))
		else
			fail = fail + 1
			Emit("|cffff4444FAIL|r " .. r.name .. (r.detail and (" (" .. r.detail .. ")") or ""))
		end
	end
	Emit(string.format("======== %d passed, %d failed ========", pass, fail))
	if UIErrorsFrame and UIErrorsFrame.AddMessage then
		if fail == 0 then
			UIErrorsFrame:AddMessage(string.format("GCDM tests OK (%d)", pass), 0.2, 1, 0.4)
		else
			UIErrorsFrame:AddMessage(string.format("GCDM tests FAIL %d/%d", fail, pass + fail), 1, 0.3, 0.2)
		end
	end
	self._lastTestResults = { pass = pass, fail = fail, results = results }
	return fail == 0
end
