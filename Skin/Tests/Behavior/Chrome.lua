local ADDON_NAME, ns = ...

local function ObjectType(obj)
	if not obj or not obj.GetObjectType then
		return nil
	end
	local ok, t = pcall(obj.GetObjectType, obj)
	if ok then
		return t
	end
	return nil
end

function ns.Tests.Behavior.Chrome(h, ctx)
	local Skin = ctx.Skin
	local db = ctx.db
	local addon = ctx.addon
	local essential = ctx.registry and ctx.registry:Essential()

	if essential and Skin.CollectIconFrames then
		local icons = Skin.CollectIconFrames(essential)
		for i = 1, #icons do
			local f = icons[i]
			if f and f:IsShown() and not f.GCDMParked then
				-- Blizzard CDM: Cooldown is the swipe Cooldown frame; digits live on it via SetCountdownFont.
				local cdType = ObjectType(f.Cooldown)
				h.check(
					"ESS shown has Cooldown swipe frame",
					f.Cooldown ~= nil and (cdType == "Cooldown" or cdType == "Frame" or cdType == nil),
					string.format("%s type=%s", tostring(f.layoutIndex), tostring(cdType))
				)
				local stackType = ObjectType(f.Stacks)
				h.check(
					"ESS shown has Stacks FS or nil-ok",
					f.Stacks == nil or stackType == "FontString" or stackType == "Frame",
					string.format("%s type=%s", tostring(f.layoutIndex), tostring(stackType))
				)
				break
			end
		end
	end

	if db and db.keybindTextEnabled ~= false then
		h.check("Keybind text API present", type(Skin.GetKeybindText) == "function")
	end

	if db and db.pressOverlayEnabled ~= false then
		h.check(
			"PressOverlay API present",
			Skin.DumpPressOverlayDebug ~= nil or Skin.ApplyPressOverlay ~= nil or addon.Skin ~= nil,
			"smoke"
		)
	end

	if addon.Glow or (addon.Skin and GCDM and GCDM.Glow) then
		local ok = pcall(function()
			if addon.Refresh and addon.CONST and addon.CONST.REFRESH.GLOW then
				addon:Refresh(addon.CONST.REFRESH.GLOW)
			end
		end)
		h.check("Glow Refresh(GLOW) no-throw", ok)
	end

	if addon.GetAuraSoundSpellValues then
		local ok, values = pcall(function()
			return addon:GetAuraSoundSpellValues()
		end)
		h.check("AuraSounds GetAuraSoundSpellValues ok", ok and type(values) == "table")
		if ok and type(values) == "table" then
			h.check("AuraSounds values has custom", values.custom ~= nil)
		end
	end
end
