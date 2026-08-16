local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local D = Skin.DebugUtil
function GCDM._DumpBuffBarViewers(self, L, essential)
	local Skin = self.Skin
local function DumpViewerIcons(label, v)
	if not v then
		L(label .. ": MISSING")
		return
	end
	local icons = Skin.CollectIconFrames(v)
	L(D.SafeFormat("%s CollectIconFrames=%d size=%.1fx%.1f", label, #icons, D.SafeNum(v:GetWidth()), D.SafeNum(v:GetHeight())))
	for i = 1, math.min(#icons, 16) do
		local frame = icons[i]
		local icon = Skin.GetIconTexture(frame)
		local tex = "?"
		if icon and icon.GetTexture then
			local okT, t = pcall(icon.GetTexture, icon)
			tex = okT and D.SafeStr(t) or "<err>"
		end
		local active = "?"
		if frame.IsActive then
			local okA, a = pcall(frame.IsActive, frame)
			active = okA and D.SafeStr(a) or "<err>"
		end
		local parked = frame.GCDMAnchor and frame.GCDMAnchor[4] == -10000
		L(D.SafeFormat(
			"  %s#%d shown=%s a=%.2f %.0fx%.0f left=%.1f idx=%s cd=%s active=%s parked=%s tex=%s",
			label,
			i,
			D.SafeStr(frame:IsShown()),
			D.SafeNum(frame:GetAlpha()),
			D.SafeNum(frame:GetWidth()),
			D.SafeNum(frame:GetHeight()),
			D.SafeNum(frame:GetLeft()),
			D.SafeStr(frame.layoutIndex),
			D.SafeStr(frame.cooldownID),
			D.SafeStr(active),
			tostring(parked),
			D.SafeStr(tex)
		))
	end
end

local registry = self.ViewerRegistry
DumpViewerIcons("ESS", essential)
DumpViewerIcons("UTIL", registry and registry:Utility())
DumpViewerIcons("BUFF", registry and registry:Buff())

local last = self._buffBarLastApply
if last then
	L(D.SafeFormat(
		"lastApply bars=%s shown=%s w=%.1f h=%.1f err=%s",
		tostring(last.bars),
		tostring(last.shown),
		D.SafeNum(last.width),
		D.SafeNum(last.height),
		tostring(last.err)
	))
else
	L("lastApply: none (skin never applied?)")
end

end

