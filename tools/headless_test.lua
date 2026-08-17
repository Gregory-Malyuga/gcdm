#!/usr/bin/env lua5.1
-- Headless runner for GCDM's pure "logic" test suites.
--
-- GCDM ships an in-game harness (/gcdm test) that needs the live WoW client.
-- This runner loads the addon's pure modules under a minimal WoW/Ace shim so
-- the logic suites in Skin/Tests/Logic/*.lua can run in CI without the client.
-- It reuses the repository's own suites and assertions (no duplicated tests).

local BASE = (arg and arg[1]) or "."
BASE = BASE:gsub("/+$", "")

-- WoW-only globals the addon expects. Missing ones stay nil on purpose: the
-- modules probe with `X and X()` guards, and nil makes those paths degrade the
-- same way an unsupported client would.
function wipe(t)
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end

function strtrim(s, chars)
	s = tostring(s or "")
	if chars then
		local pat = "[" .. chars:gsub("(%W)", "%%%1") .. "]"
		return (s:gsub("^" .. pat .. "+", ""):gsub(pat .. "+$", ""))
	end
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function DeepCopy(v)
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, val in pairs(v) do
		out[k] = DeepCopy(val)
	end
	return out
end
CopyTable = DeepCopy

time = os.time

-- A frame stub: every method is a harmless no-op returning nil, which is enough
-- for the handful of load-time CreateFrame(...) calls in optional modules.
local FRAME_MT = {
	__index = function()
		return function()
			return nil
		end
	end,
}
function CreateFrame()
	return setmetatable({}, FRAME_MT)
end

UIParent = CreateFrame()

function GetPhysicalScreenSize()
	return 2560, 1440
end

-- Minimal LibStub: only AceAddon-3.0 is asked for at module load time, and it
-- just needs to hand back the one shared addon table.
local GCDM = {}

local ACE = {
	["AceAddon-3.0"] = {
		GetAddon = function()
			return GCDM
		end,
		NewAddon = function()
			return GCDM
		end,
	},
}

function LibStub(name)
	return ACE[name] or setmetatable({}, {
		__index = function()
			return function() end
		end,
	})
end

local ns = { GCDM = GCDM }
-- Locale table: return the key itself when a string is missing.
ns.L = setmetatable({}, {
	__index = function(_, k)
		return k
	end,
})

function GCDM:GetDB()
	return self.db and self.db.profile
end

function GCDM:Print() end
function GCDM:IsEditModeActive()
	return false
end

local function LoadFile(rel)
	local path = BASE .. "/" .. rel
	local chunk, err = loadfile(path)
	if not chunk then
		error("load " .. rel .. ": " .. tostring(err), 0)
	end
	local ok, ferr = pcall(chunk, "GCDM", ns)
	if not ok then
		error("run " .. rel .. ": " .. tostring(ferr), 0)
	end
end

-- Addon modules needed by the logic suites, in dependency (TOC) order.
local MODULES = {
	"Core/Constants.lua",
	"Core/Refresh.lua",
	"Core/Pixel.lua",
	"DB/Defaults.lua",
	"Skin/Util.lua",
	"Skin/ColorUtil.lua",
	"Skin/LayoutGeometry.lua",
	"Skin/PowerBarCurve.lua",
	"Skin/KeybindSlots.lua",
	"Skin/KeybindResolve.lua",
	"Skin/TextStyle.lua",
	"Skin/AuraSoundValues.lua",
	"Core/ProfileShareCodec.lua",
	"Core/ProfileShare.lua",
	"Core/CDMContent.lua",
}

for i = 1, #MODULES do
	LoadFile(MODULES[i])
end

-- Build the saved-variables profile from shipped defaults.
GCDM.db = { profile = DeepCopy(ns.defaults.profile) }

-- Harness + the pure logic suites (the same files the in-game runner uses).
LoadFile("Skin/Tests/Harness.lua")

local LOGIC = {
	"Refresh",
	"ProfileShare",
	"PowerBarCurve",
	"KeybindSlots",
	"TextStyle",
	"AuraSoundKeys",
	"WidthFormula",
	"CDMContent",
}

for i = 1, #LOGIC do
	LoadFile("Skin/Tests/Logic/" .. LOGIC[i] .. ".lua")
end

local ctx = {
	addon = GCDM,
	db = GCDM:GetDB(),
	registry = GCDM.ViewerRegistry,
	Skin = GCDM.Skin,
	Pixel = GCDM.Pixel,
}

local h = ns.Tests.NewHarness()
h.check("db.enabled", ctx.db and ctx.db.enabled == true, ctx.db and tostring(ctx.db.enabled))

for i = 1, #LOGIC do
	local suite = ns.Tests.Logic[LOGIC[i]]
	if type(suite) ~= "function" then
		h.check(LOGIC[i] .. " suite missing", false)
	else
		local ok, err = pcall(suite, h, ctx)
		if not ok then
			h.check(LOGIC[i] .. " suite error", false, tostring(err))
		end
	end
end

local pass = h.Finish(GCDM, "GCDM headless logic tests")
os.exit(pass and 0 or 1)
