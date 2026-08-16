local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin

local ICON_VIEWERS = Skin.TEXT_ICON_VIEWERS
local KEYBIND_VIEWERS = Skin.TEXT_KEYBIND_VIEWERS

local function GetCountdownFontString(cd)
	if not cd then return nil end
	if cd.GetCountdownFontString then
		local ok, fs = pcall(cd.GetCountdownFontString, cd)
		if ok and fs then return fs end
	end
	local regions = { cd:GetRegions() }
	for i = 1, #regions do
		local r = regions[i]
		if r and r.GetObjectType and r:GetObjectType() == "FontString" then return r end
	end
	return nil
end

function Skin.GetStackFontString(frame)
	if not frame then return nil end
	local charge = frame.ChargeCount
	if charge and charge.Current then return charge.Current, charge end
	local apps = frame.Applications
	if apps then
		if apps.Applications then return apps.Applications, apps end
		if apps.GetObjectType and apps:GetObjectType() == "FontString" then return apps, frame end
	end
	if frame.Count and frame.Count.GetObjectType and frame.Count:GetObjectType() == "FontString" then
		return frame.Count, frame
	end
	local icon = frame.Icon
	if icon and icon.Applications then
		local a = icon.Applications
		if a.GetObjectType and a:GetObjectType() == "FontString" then return a, icon end
	end
	return nil
end

Skin.GetStackFontString = GetStackFontString

local function StyleCooldownText(frame, style, viewerKey)
	local cd = frame.Cooldown
	if not cd or not style then return end
	local path = Skin.FetchFont(style.textFont or "Expressway")
	local size = style.cooldownFontSize or 14
	local outline = Skin.ResolveOutline(style.textOutline)
	local fontObj = Skin.TextGetFontObj((viewerKey or "icon") .. "_cd")
	Skin.TextApplyFontObject(fontObj, path, size, outline)
	if cd.SetCountdownFont then pcall(cd.SetCountdownFont, cd, fontObj:GetName()) end
	local fs = GetCountdownFontString(cd)
	if not fs then return end
	if fs.SetDrawLayer then fs:SetDrawLayer("OVERLAY", 7) end
	Skin.TextStyleFontString(fs, fontObj, style.cooldownTextColor, Skin.TextNormalizePoint(style.cooldownTextPoint, "CENTER"),
		style.cooldownTextOffsetX or 0, style.cooldownTextOffsetY or 0, frame, path, size, outline)
	if not cd.GCDMTextHooked then
		cd.GCDMTextHooked = true
		cd:HookScript("OnShow", function(self)
			local parent = self:GetParent()
			local profile = GCDM:GetDB()
			if parent and profile and profile.enabled then
				local key = Skin.GetViewerKeyForFrame(parent)
				if key and ICON_VIEWERS[key] then
					StyleCooldownText(parent, Skin.GetTextStyle(profile, key), key)
				end
			end
		end)
	end
end

local function RaiseStackAboveSwipe(frame, fs, anchor)
	local cd = frame and frame.Cooldown
	local base = (frame and frame.GetFrameLevel and frame:GetFrameLevel()) or 0
	local above = ((cd and cd.GetFrameLevel and cd:GetFrameLevel()) or (base + 1)) + 5
	local holder = anchor
	if holder and holder ~= frame and holder.SetFrameLevel then
		holder:SetFrameLevel(above)
	elseif fs then
		local overlay = frame.GCDMStackOverlay
		if not overlay then
			overlay = CreateFrame("Frame", nil, frame)
			overlay:SetAllPoints(frame)
			frame.GCDMStackOverlay = overlay
		end
		overlay:SetFrameLevel(above)
		if fs.GetParent and fs.SetParent and fs:GetParent() ~= overlay then
			local point, _, relPoint, x, y = fs:GetPoint(1)
			fs:SetParent(overlay)
			fs:ClearAllPoints()
			if point then fs:SetPoint(point, overlay, relPoint or point, x or 0, y or 0) end
		end
	end
	if fs and fs.SetDrawLayer then fs:SetDrawLayer("OVERLAY", 7) end
end

function Skin.StyleStackText(frame, style, viewerKey)
	local fs, anchor = GetStackFontString(frame)
	if not fs or not style then return end
	local path = Skin.FetchFont(style.textFont or "Expressway")
	local size = style.stackFontSize or 12
	local outline = Skin.ResolveOutline(style.textOutline)
	local fontObj = Skin.TextGetFontObj((viewerKey or "icon") .. "_stack")
	Skin.TextApplyFontObject(fontObj, path, size, outline)
	Skin.TextStyleFontString(fs, fontObj, style.stackTextColor, Skin.TextNormalizePoint(style.stackTextPoint, "BOTTOMRIGHT"),
		style.stackTextOffsetX or 0, style.stackTextOffsetY or 0, anchor or frame, path, size, outline)
	RaiseStackAboveSwipe(frame, fs, anchor)
	if not fs.GCDMStackHooked then
		fs.GCDMStackHooked = true
		if fs.HookScript then
			fs:HookScript("OnShow", function()
				local profile = GCDM:GetDB()
				if profile and profile.enabled then
					local key = Skin.GetViewerKeyForFrame(frame)
					if key and ICON_VIEWERS[key] then
						Skin.StyleStackText(frame, Skin.GetTextStyle(profile, key), key)
					end
				end
			end)
		end
	end
end

local function EnsureKeybindFontString(frame)
	local holder = frame.GCDMKeybind
	if not holder then
		holder = CreateFrame("Frame", nil, frame)
		holder:SetAllPoints(frame)
		frame.GCDMKeybind = holder
		local fs = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		fs:SetDrawLayer("OVERLAY", 7)
		holder.Text = fs
	end
	local cd = frame.Cooldown
	local base = frame:GetFrameLevel() or 0
	holder:SetFrameLevel(((cd and cd.GetFrameLevel and cd:GetFrameLevel()) or (base + 1)) + 6)
	return holder, holder.Text
end

local function HideKeybindText(frame)
	if frame and frame.GCDMKeybind then frame.GCDMKeybind:Hide() end
end

local function StyleKeybindText(frame, style, viewerKey)
	if not frame or not KEYBIND_VIEWERS[viewerKey] then HideKeybindText(frame) return end
	local db = GCDM:GetDB()
	if not db or db.keybindTextEnabled == false then HideKeybindText(frame) return end
	local spellID = Skin.GetFrameSpellID and Skin.GetFrameSpellID(frame)
	local text = spellID and Skin.GetKeybindText and Skin.GetKeybindText(spellID) or nil
	if not text or text == "" then HideKeybindText(frame) return end
	local holder, fs = EnsureKeybindFontString(frame)
	local path = Skin.FetchFont(style.textFont or "Expressway")
	local size = style.keybindFontSize or 11
	local outline = Skin.ResolveOutline(style.textOutline)
	local fontObj = Skin.TextGetFontObj((viewerKey or "icon") .. "_kb")
	Skin.TextApplyFontObject(fontObj, path, size, outline)
	Skin.TextStyleFontString(fs, fontObj, style.keybindTextColor, Skin.TextNormalizePoint(style.keybindTextPoint, "TOPLEFT"),
		style.keybindTextOffsetX or 2, style.keybindTextOffsetY or -1, holder, path, size, outline)
	fs:SetText(text)
	if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
	holder:Show()
	fs:Show()
end

function Skin.RefreshKeybindTexts()
	local db = GCDM:GetDB()
	if not db or not db.enabled or db.keybindTextEnabled == false then
		GCDM.Skin.ForEachManagedIcon(function(frame, _, viewerName)
			if KEYBIND_VIEWERS[viewerName] then HideKeybindText(frame) end
		end)
		return
	end
	GCDM.Skin.ForEachManagedIcon(function(frame, _, viewerName)
		if KEYBIND_VIEWERS[viewerName] then
			StyleKeybindText(frame, Skin.GetTextStyle(db, viewerName), viewerName)
		end
	end)
end

function Skin.ApplyText(frame, viewerKey)
	local db = GCDM:GetDB()
	if not db or not db.enabled or not frame then return end
	viewerKey = viewerKey or Skin.GetViewerKeyForFrame(frame)
	if not viewerKey or not ICON_VIEWERS[viewerKey] then return end
	local style = Skin.GetTextStyle(db, viewerKey)
	StyleCooldownText(frame, style, viewerKey)
	Skin.StyleStackText(frame, style, viewerKey)
	StyleKeybindText(frame, style, viewerKey)
end
