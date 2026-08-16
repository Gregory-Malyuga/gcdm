local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local Tests = ns.Tests

local LOGIC_SUITES = {
	{ name = "refresh", fn = function()
		return Tests.Logic.Refresh
	end },
	{ name = "profileshare", fn = function()
		return Tests.Logic.ProfileShare
	end },
	{ name = "powerbarcurve", fn = function()
		return Tests.Logic.PowerBarCurve
	end },
	{ name = "keybindslots", fn = function()
		return Tests.Logic.KeybindSlots
	end },
	{ name = "textstyle", fn = function()
		return Tests.Logic.TextStyle
	end },
	{ name = "aurasoundkeys", fn = function()
		return Tests.Logic.AuraSoundKeys
	end },
	{ name = "widthformula", fn = function()
		return Tests.Logic.WidthFormula
	end },
	{ name = "cdmcontent", fn = function()
		return Tests.Logic.CDMContent
	end },
}

local BEHAVIOR_SUITES = {
	{ name = "viewers", fn = function()
		return Tests.Behavior.Viewers
	end },
	{ name = "layoutessential", fn = function()
		return Tests.Behavior.LayoutEssential
	end },
	{ name = "layoututility", fn = function()
		return Tests.Behavior.LayoutUtility
	end },
	{ name = "layoutbuff", fn = function()
		return Tests.Behavior.LayoutBuff
	end },
	{ name = "buffbar", fn = function()
		return Tests.Behavior.BuffBar
	end },
	{ name = "powerbar", fn = function()
		return Tests.Behavior.PowerBar
	end },
	{ name = "chrome", fn = function()
		return Tests.Behavior.Chrome
	end },
	{ name = "pixel", fn = function()
		return Tests.Behavior.Pixel
	end },
}

local function BuildCtx(addon)
	return {
		addon = addon,
		db = addon:GetDB(),
		registry = addon.ViewerRegistry,
		Skin = addon.Skin,
		Pixel = addon.Pixel,
	}
end

local function RunSuites(h, ctx, suites, filter)
	for i = 1, #suites do
		local entry = suites[i]
		if not filter or filter == entry.name then
			local mod = entry.fn()
			if type(mod) == "function" then
				local ok, err = pcall(mod, h, ctx)
				if not ok then
					h.check(entry.name .. " suite error", false, tostring(err))
				end
			else
				h.check(entry.name .. " suite missing", false)
			end
		end
	end
end

--- In-game behavior + logic checks.
--- /gcdm test | /gcdm test logic | /gcdm test behavior | /gcdm test <suite>
function GCDM:RunBehaviorTests(filter)
	filter = type(filter) == "string" and string.lower(strtrim(filter)) or nil
	if filter == "" then
		filter = nil
	end

	local h = Tests.NewHarness()
	local ctx = BuildCtx(self)
	local editMode = self.IsEditModeActive and self:IsEditModeActive()

	h.check("db.enabled", ctx.db and ctx.db.enabled == true, ctx.db and tostring(ctx.db.enabled))

	local runLogic = not filter or filter == "logic" or filter == "all"
	local runBehavior = not filter or filter == "behavior" or filter == "all"
	local named = filter and filter ~= "logic" and filter ~= "behavior" and filter ~= "all"

	if runLogic or named then
		RunSuites(h, ctx, LOGIC_SUITES, named and filter or nil)
	end

	if runBehavior or named then
		if editMode and not named then
			h.check("Edit Mode active — behavior suites skipped", true, "skip")
		else
			if editMode then
				h.check("Edit Mode: named behavior may be incomplete", true, "warn")
			end
			if self.Refresh and not editMode then
				self:Refresh(self.CONST.REFRESH.LAYOUT)
				self:Refresh(self.CONST.REFRESH.STYLE)
			end
			RunSuites(h, ctx, BEHAVIOR_SUITES, named and filter or nil)
		end
	end

	-- Avoid double Pixel when full run already included it in both lists.
	return h.Finish(self, "GCDM tests")
end
