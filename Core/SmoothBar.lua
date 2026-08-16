local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

-- Smooth StatusBar fill. OnUpdate only while approaching target; stops when idle.
-- Secret-safe: secrets / inaccessible values snap instantly (no lerp arithmetic).

local SPEED = 14
local EPS = 0.0005

-- Bars can be Blizzard StatusBars; keep our state outside their tables so we
-- never write into a frame Blizzard reads while handling secret values.
local targets = setmetatable({}, { __mode = "k" })
local drivers = setmetatable({}, { __mode = "k" })

local function IsPlainNumber(v)
	if v == nil then
		return false
	end
	if issecretvalue and issecretvalue(v) then
		return false
	end
	if canaccessvalue and not canaccessvalue(v) then
		return false
	end
	return type(v) == "number"
end

local function StopSmooth(bar)
	if not bar then
		return
	end
	targets[bar] = nil
	local driver = drivers[bar]
	if driver then
		driver:SetScript("OnUpdate", nil)
	end
end

local function EnsureDriver(bar)
	local driver = drivers[bar]
	if driver then
		return driver
	end
	driver = CreateFrame("Frame", nil, bar)
	drivers[bar] = driver
	return driver
end

local function Snap(bar, value)
	StopSmooth(bar)
	pcall(bar.SetValue, bar, value)
end

function Skin.IsBarSmoothEnabled(db)
	db = db or (GCDM.GetDB and GCDM:GetDB())
	return db and db.barSmoothProgress == true
end

--- Set StatusBar value; optional smooth lerp when enabled and both values are plain numbers.
function Skin.SmoothBarSetValue(bar, value, enabled)
	if not bar or not bar.SetValue then
		return
	end
	if not enabled then
		Snap(bar, value)
		return
	end
	if not IsPlainNumber(value) then
		Snap(bar, value)
		return
	end

	local okCur, cur = pcall(bar.GetValue, bar)
	if not okCur or not IsPlainNumber(cur) then
		Snap(bar, value)
		return
	end

	local okMin, minV, maxV = pcall(bar.GetMinMaxValues, bar)
	if okMin and IsPlainNumber(minV) and IsPlainNumber(maxV) then
		if value < minV then
			value = minV
		elseif value > maxV then
			value = maxV
		end
	end

	if math.abs(value - cur) <= EPS then
		Snap(bar, value)
		return
	end

	targets[bar] = value
	local driver = EnsureDriver(bar)
	if driver:GetScript("OnUpdate") then
		return
	end
	driver:SetScript("OnUpdate", function(self, elapsed)
		local target = targets[bar]
		if target == nil then
			self:SetScript("OnUpdate", nil)
			return
		end
		if not IsPlainNumber(target) then
			Snap(bar, target)
			return
		end
		local ok, now = pcall(bar.GetValue, bar)
		if not ok or not IsPlainNumber(now) then
			Snap(bar, target)
			return
		end
		local diff = target - now
		if math.abs(diff) <= EPS then
			Snap(bar, target)
			return
		end
		local step = diff * math.min(1, (elapsed or 0) * SPEED)
		-- Avoid overshooting.
		if (diff > 0 and step > diff) or (diff < 0 and step < diff) then
			step = diff
		end
		pcall(bar.SetValue, bar, now + step)
	end)
end

function Skin.SmoothBarStop(bar)
	StopSmooth(bar)
end
