local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local D = Skin.DebugUtil
function GCDM._DumpBuffBarBarsDetail(self, L, lines, viewer, db)
	local Skin = self.Skin
	if not viewer then
		return
	end
local bars = Skin.CollectBarFrames(viewer)
L(D.SafeFormat(
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
		L(D.SafeFormat(
			" child#%d type=%s Bar=%s shown=%s %.1fx%.1f",
			i,
			c and c.GetObjectType and c:GetObjectType() or "?",
			tostring(c and c.Bar ~= nil),
			tostring(c and c:IsShown()),
			D.SafeNum(c and c:GetWidth()),
			D.SafeNum(c and c:GetHeight())
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
		activeStr = okA and D.SafeStr(a) or "<err>"
	end
	L(D.SafeFormat(
		"#%d frame shown=%s a=%.2f %.1fx%.1f want=%.1fx%.1f left=%.1f right=%.1f active=%s",
		i,
		tostring(frame:IsShown()),
		D.SafeNum(frame:GetAlpha()),
		D.SafeNum(frame:GetWidth()),
		D.SafeNum(frame:GetHeight()),
		D.SafeNum(frame.GCDMWantW),
		D.SafeNum(frame.GCDMWantH),
		D.SafeNum(frame:GetLeft()),
		D.SafeNum(frame:GetRight()),
		activeStr
	))
	L("  frame: " .. D.DescribePoints(frame))
	if bar then
		L(D.SafeFormat(
			"  Bar shown=%s a=%.2f %.1fx%.1f blizzTex=%s atlas=%s texA=%.2f",
			tostring(bar:IsShown()),
			D.SafeNum(bar:GetAlpha()),
			D.SafeNum(bar:GetWidth()),
			D.SafeNum(bar:GetHeight()),
			tostring(sbTex),
			tostring(sbAtlas),
			D.SafeNum(sbAlpha)
		))
		L("  bar:   " .. D.DescribePoints(bar))
		local minV, maxV = 0, 0
		if bar.GetMinMaxValues then
			minV, maxV = bar:GetMinMaxValues()
		end
		L(D.SafeFormat(
			"  values min=%.2f max=%.2f cur=%.2f",
			D.SafeNum(minV),
			D.SafeNum(maxV),
			D.SafeNum(bar.GetValue and bar:GetValue())
		))
		L(D.SafeFormat(
			"  Pip=%s shown=%s a=%.2f | Name a=%.2f shown=%s | Dur a=%.2f shown=%s",
			pip and "yes" or "NO",
			tostring(pip and pip:IsShown()),
			D.SafeNum(pip and pip.GetAlpha and pip:GetAlpha()),
			D.SafeNum(nameFS and nameFS.GetAlpha and nameFS:GetAlpha()),
			tostring(nameFS and nameFS:IsShown()),
			D.SafeNum(durFS and durFS.GetAlpha and durFS:GetAlpha()),
			tostring(durFS and durFS:IsShown())
		))
		if nameFS and nameFS.GetText then
			local okText, text = pcall(nameFS.GetText, nameFS)
			L("  NameText=" .. D.SafeStr(okText and text or "?"))
		end
	else
		L("  Bar: NO")
	end
	if skin then
		L(D.SafeFormat(
			"  GCDMSkinBar shown=%s a=%.2f %.1fx%.1f tex=%s level=%s",
			D.SafeStr(skin:IsShown()),
			D.SafeNum(skin:GetAlpha()),
			D.SafeNum(skin:GetWidth()),
			D.SafeNum(skin:GetHeight()),
			D.SafeStr(skinTex),
			D.SafeStr(skin.GetFrameLevel and skin:GetFrameLevel())
		))
		L("  skin:  " .. D.DescribePoints(skin))
	else
		L("  GCDMSkinBar: MISSING (solid overlay never created)")
	end
	L(D.SafeFormat(
		"  Icon shown=%s a=%.2f | borderBar=%s borderIcon=%s",
		D.SafeStr(frame.Icon and frame.Icon:IsShown()),
		D.SafeNum(frame.Icon and frame.Icon.GetAlpha and frame.Icon:GetAlpha()),
		D.SafeStr(frame.GCDMBarBorder ~= nil),
		D.SafeStr(frame.GCDMBarIconBorder ~= nil)
	))
end

local pos = db and db.viewerPos and db.viewerPos.buffBar
if pos then
	L(D.SafeFormat(
		"viewerPos.buffBar en=%s point=%s x=%s y=%s",
		D.SafeStr(pos.enabled),
		D.SafeStr(pos.point),
		D.SafeStr(pos.x),
		D.SafeStr(pos.y)
	))
end
local posB = db and db.viewerPos and db.viewerPos.buff
if posB then
	L(D.SafeFormat(
		"viewerPos.buff en=%s point=%s x=%s y=%s",
		D.SafeStr(posB.enabled),
		D.SafeStr(posB.point),
		D.SafeStr(posB.x),
		D.SafeStr(posB.y)
	))
end
local posE = db and db.viewerPos and db.viewerPos.essential
if posE then
	L(D.SafeFormat(
		"viewerPos.essential en=%s point=%s x=%s y=%s",
		D.SafeStr(posE.enabled),
		D.SafeStr(posE.point),
		D.SafeStr(posE.x),
		D.SafeStr(posE.y)
	))
end
L("---- end ----")
end

