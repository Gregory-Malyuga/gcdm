local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local D = Skin.DebugUtil

function GCDM._DumpEditModeIconHelpers()
	local function frameActive(f)
		if not f or not f.IsActive then
			return "?"
		end
		local ok, a = pcall(f.IsActive, f)
		if not ok then
			return "err"
		end
		if canaccessvalue and type(a) ~= "boolean" and not canaccessvalue(a) then
			return "secret"
		end
		return tostring(a)
	end

	local function dumpOne(L, idx, f, viewerLeft, viewerTop)
		if not f then
			return
		end
		local name = (f.GetName and f:GetName()) or ("anon" .. tostring(idx))
		local shown = "?"
		if f.IsShown then
			local okS, s = pcall(f.IsShown, f)
			shown = okS and tostring(s) or "err"
		end
		local fw = D.SafeNum(f.GetWidth and f:GetWidth())
		local fh = D.SafeNum(f.GetHeight and f:GetHeight())
		local fl = D.SafeNum(f.GetLeft and f:GetLeft())
		local fr = D.SafeNum(f.GetRight and f:GetRight())
		local ft = D.SafeNum(f.GetTop and f:GetTop())
		local fb = D.SafeNum(f.GetBottom and f:GetBottom())
		local relX, relY = -1, -1
		if fl >= 0 and viewerLeft >= 0 then
			local okX, dx = pcall(function()
				return fl - viewerLeft
			end)
			if okX then
				relX = D.SafeNum(dx)
			end
		end
		if ft >= 0 and viewerTop >= 0 then
			local okY, dy = pcall(function()
				return viewerTop - ft
			end)
			if okY then
				relY = D.SafeNum(dy)
			end
		end
		L(D.SafeFormat(
			"  icon[%d] %s shown=%s active=%s size=%.1fx%.1f L=%.1f R=%.1f T=%.1f B=%.1f relXY=%.1f,%.1f alpha=%.2f parked=%s row=%s",
			idx,
			D.SafeStr(name),
			shown,
			frameActive(f),
			fw,
			fh,
			fl,
			fr,
			ft,
			fb,
			relX,
			relY,
			D.SafeNum(f.GetAlpha and f:GetAlpha()),
			tostring(f.GCDMParked),
			tostring(f.GCDMRow)
		))
		L("    points: " .. D.DescribePoints(f))
	end

	local function dumpViewer(L, label, viewer, isBar)
		if not viewer then
			L(label .. ": MISSING")
			return
		end
		local vLeft = D.SafeNum(viewer.GetLeft and viewer:GetLeft())
		local vRight = D.SafeNum(viewer.GetRight and viewer:GetRight())
		local vTop = D.SafeNum(viewer.GetTop and viewer:GetTop())
		local vBottom = D.SafeNum(viewer.GetBottom and viewer:GetBottom())
		L(D.SafeFormat(
			"== %s shown=%s alpha=%.2f size=%.1fx%.1f L=%.1f R=%.1f T=%.1f B=%.1f ==",
			label,
			tostring(viewer.IsShown and viewer:IsShown()),
			D.SafeNum(viewer.GetAlpha and viewer:GetAlpha()),
			D.SafeNum(viewer.GetWidth and viewer:GetWidth()),
			D.SafeNum(viewer.GetHeight and viewer:GetHeight()),
			vLeft,
			vRight,
			vTop,
			vBottom
		))
		L("  viewer points: " .. D.DescribePoints(viewer))
		local list
		if isBar then
			list = Skin and Skin.CollectBarFrames and Skin.CollectBarFrames(viewer)
		else
			list = Skin and Skin.CollectIconFrames and Skin.CollectIconFrames(viewer)
		end
		if not list then
			L("  children: none")
			return
		end
		local shownN = 0
		for i = 1, #list do
			local f = list[i]
			if f and f.IsShown then
				local okS, s = pcall(f.IsShown, f)
				if okS and s then
					shownN = shownN + 1
				end
			end
		end
		L(D.SafeFormat("  pool=%d shown=%d (listing ALL)", #list, shownN))
		local ordered = {}
		for i = 1, #list do
			ordered[i] = list[i]
		end
		table.sort(ordered, function(a, b)
			local at = D.SafeNum(a and a.GetTop and a:GetTop())
			local bt = D.SafeNum(b and b.GetTop and b:GetTop())
			if at ~= bt then
				return at > bt
			end
			return D.SafeNum(a and a.GetLeft and a:GetLeft()) < D.SafeNum(b and b.GetLeft and b:GetLeft())
		end)
		for i = 1, #ordered do
			dumpOne(L, i, ordered[i], vLeft, vTop)
		end
	end

	return dumpViewer
end
