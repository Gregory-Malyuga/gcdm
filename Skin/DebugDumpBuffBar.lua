local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local D = Skin.DebugUtil
function GCDM:DumpBuffBarDebug()
	local lines = {}
	local function L(s)
		local ok, text = pcall(function()
			if type(s) == "string" then
				return s
			end
			return D.SafeStr(s)
		end)
		if not ok then
			lines[#lines + 1] = "<line err>"
			return
		end
		if canaccessvalue and type(text) == "string" and not canaccessvalue(text) then
			lines[#lines + 1] = "<secret line>"
			return
		end
		lines[#lines + 1] = D.SafeStr(text)
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
		L("---- GCDM layout/buff debug ----")
		GCDM._DumpBuffBarHead(self, L, db, viewer, essential, editMode)
		GCDM._DumpBuffBarViewers(self, L, essential)
		GCDM._DumpBuffBarBarsDetail(self, L, lines, viewer, db)
	end)

	if not ok then
		L("DUMP ERROR: " .. D.SafeStr(err))
	end

	local clean = {}
	for i = 1, #lines do
		clean[i] = D.SafeStr(lines[i])
	end
	local text = table.concat(clean, "\n")
	self._lastBuffBarDump = text
	if self.db and self.db.profile then
		self.db.profile._lastBuffBarDump = text
	end

	D.Emit("Dump ready — popup: Ctrl+A Ctrl+C, paste in chat")
	if UIErrorsFrame and UIErrorsFrame.AddMessage then
		UIErrorsFrame:AddMessage("GCDM dump: Ctrl+A Ctrl+C", 0.2, 1, 0.4)
	end
	for i = 1, math.min(#clean, 8) do
		D.Emit(clean[i])
	end
	if #clean > 8 then
		D.Emit("... +" .. tostring(#clean - 8) .. " lines in popup")
	end
	D.ShowDumpWindow(text)
end
