local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local D = Skin.DebugUtil
function GCDM._DumpBuffBarHead(self, L, db, viewer, essential, editMode)
	local Skin = self.Skin
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
local iw = D.SafeNum(sizeE.w)
if iw < 0 then
	iw = 46
end
local formulaW = (maxRow * iw) + ((maxRow - 1) * (tonumber(spacing) or 0))
L(D.SafeFormat(
	"enabled=%s buffBarEnabled=%s powerBarEnabled=%s styleRaw=%s styleResolved=%s editMode=%s",
	tostring(db and db.enabled),
	tostring(db and db.buffBarEnabled),
	tostring(db and db.powerBarEnabled),
	tostring(styleRaw),
	tostring(styleResolved),
	tostring(editMode)
))
L(D.SafeFormat(
	"h=%s wSetting=%s showIcon=%s showName=%s showTimer=%s",
	tostring(db and db.buffBarHeight),
	tostring(db and db.buffBarWidth),
	tostring(db and db.buffBarShowIcon),
	tostring(db and db.buffBarShowName),
	tostring(db and db.buffBarShowDuration)
))
L(D.SafeFormat(
	"sizeEssential=%sx%s spacing=%s maxRow=%s formulaW=%.1f EssentialLayoutWidth=%s",
	tostring(sizeE.w),
	tostring(sizeE.h),
	tostring(spacing),
	tostring(maxRow),
	D.SafeNum(formulaW),
	D.SafeStr(Skin.EssentialLayoutWidth)
))
L(D.SafeFormat(
	"tex=%s path=%s | bg=%s path=%s",
	tostring(texName),
	tostring(texPath),
	tostring(bgName),
	tostring(bgPath)
))
L(D.SafeFormat(
	"fill=%.2f,%.2f,%.2f,%.2f bg=%.2f,%.2f,%.2f,%.2f",
	D.SafeNum(fill.r), D.SafeNum(fill.g), D.SafeNum(fill.b), D.SafeNum(fill.a),
	D.SafeNum(bgc.r), D.SafeNum(bgc.g), D.SafeNum(bgc.b), D.SafeNum(bgc.a)
))
L(D.SafeFormat(
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
L(D.SafeFormat(
	"viewer shown=%s alpha=%.2f size=%.1fx%.1f left=%.1f right=%.1f parent=%s baseW=%s scale=%s",
	tostring(viewer:IsShown()),
	D.SafeNum(viewer:GetAlpha()),
	D.SafeNum(viewer:GetWidth()),
	D.SafeNum(viewer:GetHeight()),
	D.SafeNum(vLeft),
	D.SafeNum(vRight),
	tostring(parentName),
	tostring(viewer.baseBarWidth),
	tostring(viewer.barWidthScale)
))
L("viewer points: " .. D.DescribePoints(viewer))

if essential then
	local eLeft, eRight = essential:GetLeft(), essential:GetRight()
	L(D.SafeFormat(
		"essential size=%.1fx%.1f left=%.1f right=%.1f shown=%s",
		D.SafeNum(essential:GetWidth()),
		D.SafeNum(essential:GetHeight()),
		D.SafeNum(eLeft),
		D.SafeNum(eRight),
		tostring(essential:IsShown())
	))
	if type(vRight) == "number" and type(eRight) == "number" then
		L(D.SafeFormat(
			"deltaRight(bar-ess)=%.1f deltaLeft(bar-ess)=%.1f deltaW(bar-ess)=%.1f",
			D.SafeNum(vRight - eRight),
			D.SafeNum((vLeft or 0) - (eLeft or 0)),
			D.SafeNum((viewer:GetWidth() or 0) - (essential:GetWidth() or 0))
		))
	end
	L("essential points: " .. D.DescribePoints(essential))
else
	L("essential: MISSING")
end

do
	local ph = self.GetPowerBarHost and self:GetPowerBarHost() or _G.GCDM_PowerBarHost
	local primary = _G.GCDM_PowerBarPrimary
	L(D.SafeFormat(
		"powerBarEnabled=%s height=%s widthSetting=%s gap=%s tex=%s",
		tostring(db and db.powerBarEnabled),
		tostring(db and db.powerBarHeight),
		tostring(db and db.powerBarWidth),
		tostring(db and db.powerBarGap),
		tostring(db and db.powerBarTexture)
	))
	if ph then
		L(D.SafeFormat(
			"PowerHost shown=%s a=%.2f size=%.1fx%.1f left=%.1f right=%.1f strata=%s level=%s parent=%s",
			D.SafeStr(ph:IsShown()),
			D.SafeNum(ph:GetAlpha()),
			D.SafeNum(ph:GetWidth()),
			D.SafeNum(ph:GetHeight()),
			D.SafeNum(ph:GetLeft()),
			D.SafeNum(ph:GetRight()),
			D.SafeStr(ph:GetFrameStrata()),
			D.SafeStr(ph:GetFrameLevel()),
			D.SafeStr(ph:GetParent() and ph:GetParent():GetName())
		))
		L("PowerHost points: " .. D.DescribePoints(ph))
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
		L(D.SafeFormat(
			"PowerPrimary shown=%s a=%.2f size=%.1fx%.1f values=%.2f/%.2f/%.2f hasTex=%s",
			D.SafeStr(primary:IsShown()),
			D.SafeNum(primary:GetAlpha()),
			D.SafeNum(primary:GetWidth()),
			D.SafeNum(primary:GetHeight()),
			D.SafeNum(mn),
			D.SafeNum(mx),
			D.SafeNum(cur),
			tostring(st ~= nil)
		))
	else
		L("PowerPrimary: MISSING")
	end
end

end

