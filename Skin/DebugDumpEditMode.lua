local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local D = Skin.DebugUtil

--- Every icon: size + screen/rel position. Works in Edit Mode and outside.
function GCDM:DumpEditModeDebug(quiet)
	local lines = {}
	local function L(s)
		lines[#lines + 1] = D.SafeStr(s)
	end
	local db = self:GetDB()
	local registry = self.ViewerRegistry
	local editMode = self.IsEditModeActive and self:IsEditModeActive() or false
	local defer = self.ShouldDeferCDMLayout and self:ShouldDeferCDMLayout() or false
	local iconDefer = self.ShouldDeferIconLayout and self:ShouldDeferIconLayout() or false
	local settingsOpen = self.IsCooldownViewerSettingsOpen and self:IsCooldownViewerSettingsOpen() or false
	local inCombat = InCombatLockdown and InCombatLockdown() or false

	L("---- GCDM icon layout dump v9 ----")
	L(D.SafeFormat(
		"editDumpVer=9 build=%s addon=%s editMode=%s deferPos=%s deferIcon=%s settingsOpen=%s combat=%s flag=%s",
		D.SafeStr(self.BUILD),
		D.SafeStr(self.VERSION),
		tostring(editMode),
		tostring(defer),
		tostring(iconDefer),
		tostring(settingsOpen),
		tostring(inCombat),
		tostring(self.isEditModeActive)
	))
	L(D.SafeFormat(
		"powerFollow=%s buffFollow=%s powerW=%s buffW=%s minBar=%s",
		tostring(db and db.powerBarFollowEssential),
		tostring(db and db.buffBarFollowEssential),
		tostring(db and db.powerBarWidth),
		tostring(db and db.buffBarWidth),
		tostring(self.CONST and self.CONST.MIN_BAR_WIDTH)
	))

	local dumpViewer = GCDM._DumpEditModeIconHelpers()
	if registry then
		dumpViewer(L, "Essential", registry.Essential and registry:Essential())
		dumpViewer(L, "Utility", registry.Utility and registry:Utility())
		dumpViewer(L, "BuffIcons", registry.Buff and registry:Buff())
		dumpViewer(L, "BuffBar", registry.BuffBar and registry:BuffBar(), true)
	end

	local host = self.GetPowerBarHost and self:GetPowerBarHost() or _G.GCDM_PowerBarHost
	if host then
		L(D.SafeFormat(
			"== PowerHost shown=%s size=%.1fx%.1f L=%.1f R=%.1f T=%.1f B=%.1f ==",
			tostring(host:IsShown()),
			D.SafeNum(host:GetWidth()),
			D.SafeNum(host:GetHeight()),
			D.SafeNum(host:GetLeft()),
			D.SafeNum(host:GetRight()),
			D.SafeNum(host:GetTop()),
			D.SafeNum(host:GetBottom())
		))
		L("  points: " .. D.DescribePoints(host))
	else
		L("PowerHost: MISSING")
	end

	local text = table.concat(lines, "\n")
	self._lastEditModeDump = text
	if self.db and self.db.profile then
		self.db.profile._lastEditModeDump = text
	end

	if quiet then
		for i = 1, math.min(#lines, 20) do
			D.Emit(lines[i])
		end
		if #lines > 20 then
			D.Emit("... +" .. tostring(#lines - 20) .. " lines — /gcdm editdump for popup")
		end
		return
	end
	D.Emit("Edit/icon dump ready — popup: Ctrl+A Ctrl+C")
	for i = 1, math.min(#lines, 12) do
		D.Emit(lines[i])
	end
	if #lines > 12 then
		D.Emit("... +" .. tostring(#lines - 12) .. " lines in popup")
	end
	D.ShowDumpWindow(text)
end
