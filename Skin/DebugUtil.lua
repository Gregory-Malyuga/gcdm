local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
GCDM.Skin = GCDM.Skin or {}
local Skin = GCDM.Skin

local function EnsureOverlay(parent, key, r, g, b, a)
	local overlay = parent[key]
	if overlay then
		return overlay
	end
	overlay = parent:CreateTexture(nil, "OVERLAY", nil, 7)
	overlay:SetColorTexture(r, g, b, a)
	parent[key] = overlay
	return overlay
end

local function ClearOverlays(frame)
	for _, key in ipairs({ "GCDMDebugFrame", "GCDMDebugIcon" }) do
		local tex = frame[key]
		if tex then
			tex:Hide()
		end
	end
end

local function SafeNum(v)
	if type(v) ~= "number" then
		return -1
	end
	if canaccessvalue and not canaccessvalue(v) then
		return -1
	end
	local ok = pcall(function()
		return v == v and v > -1e12 and v < 1e12
	end)
	if not ok then
		return -1
	end
	return v
end

local function SafeStr(v)
	if v == nil then
		return "nil"
	end
	if canaccessvalue and (type(v) == "number" or type(v) == "string") and not canaccessvalue(v) then
		return "<secret>"
	end
	local ok, s = pcall(tostring, v)
	if not ok or type(s) ~= "string" then
		return "<err>"
	end
	if canaccessvalue and not canaccessvalue(s) then
		return "<secret>"
	end
	local ok2 = pcall(function()
		return s .. ""
	end)
	if not ok2 then
		return "<secret>"
	end
	return s
end

local function SafeFormat(fmt, ...)
	local n = select("#", ...)
	local args = {}
	for i = 1, n do
		local a = select(i, ...)
		if type(a) == "number" then
			args[i] = SafeNum(a)
		elseif type(a) == "string" then
			args[i] = SafeStr(a)
		elseif type(a) == "boolean" then
			args[i] = a and "true" or "false"
		else
			args[i] = SafeStr(a)
		end
	end
	local ok, s = pcall(string.format, fmt, unpack(args))
	if not ok then
		return "<fmt err>"
	end
	return SafeStr(s)
end

local function DescribePoints(region)
	if not region or not region.GetNumPoints then
		return "?"
	end
	local parts = {}
	local okN, n = pcall(function()
		return region:GetNumPoints() or 0
	end)
	n = (okN and n) or 0
	for i = 1, n do
		local ok, point, relativeTo, relativePoint, x, y = pcall(function()
			return region:GetPoint(i)
		end)
		if ok then
			local relName = relativeTo and (relativeTo.GetName and relativeTo:GetName()) or SafeStr(relativeTo)
			parts[#parts + 1] = string.format(
				"%s->%s:%s (%.1f,%.1f)",
				SafeStr(point),
				SafeStr(relName),
				SafeStr(relativePoint),
				SafeNum(x),
				SafeNum(y)
			)
		end
	end
	return table.concat(parts, " | ")
end

local function DescribeTexCoord(icon)
	if not icon or not icon.GetTexCoord then
		return "n/a"
	end
	local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = icon:GetTexCoord()
	if URx then
		return string.format("UL(%.3f,%.3f) LR(%.3f,%.3f)", ULx or 0, ULy or 0, LRx or 0, LRy or 0)
	end
	local left, right, top, bottom = icon:GetTexCoord()
	return string.format("l=%.3f r=%.3f t=%.3f b=%.3f", left or 0, right or 0, top or 0, bottom or 0)
end

local function ListTextures(frame)
	local list = {}
	if frame.Icon then list[#list + 1] = "Icon" end
	if frame.icon then list[#list + 1] = "icon" end
	if frame.IconBorder then list[#list + 1] = "IconBorder" end
	if frame.Border then list[#list + 1] = "Border" end
	if frame.Cooldown then list[#list + 1] = "Cooldown" end
	local regions = { frame:GetRegions() }
	for i = 1, #regions do
		local r = regions[i]
		if r and r.GetObjectType and r:GetObjectType() == "Texture" then
			local name = r.GetName and r:GetName() or ("anon" .. i)
			local draw = r.GetDrawLayer and r:GetDrawLayer() or "?"
			list[#list + 1] = string.format("%s[%s]", tostring(name), tostring(draw))
		end
	end
	return table.concat(list, ", ")
end

local function Emit(msg)
	print("|cff3bb273GCDM|r " .. SafeStr(msg))
end

Skin.DebugUtil = {
	EnsureOverlay = EnsureOverlay,
	ClearOverlays = ClearOverlays,
	SafeNum = SafeNum,
	SafeStr = SafeStr,
	SafeFormat = SafeFormat,
	DescribePoints = DescribePoints,
	DescribeTexCoord = DescribeTexCoord,
	ListTextures = ListTextures,
	Emit = Emit,
}
