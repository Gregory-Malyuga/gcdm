local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local Pixel = GCDM.Pixel

function Skin.StyleCooldownSwipe(frame, db)
	local cd = frame.Cooldown
	if not cd then
		return
	end

	cd:ClearAllPoints()
	cd:SetAllPoints(frame)

	local border = frame.GCDMBackdropBorder
	local baseLevel = frame:GetFrameLevel() or 0
	local borderLevel = border and border:GetFrameLevel() or (baseLevel + 3)
	cd:SetFrameLevel(math.max(baseLevel + 1, borderLevel - 1))

	if cd.SetSwipeTexture then
		cd:SetSwipeTexture(GCDM.CONST.TEX_WHITE8X8)
	end
	local sc = (db and db.swipeColor) or GCDM.CONST.SWIPE_COLOR
	if cd.SetSwipeColor and sc then
		cd:SetSwipeColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.6)
	end
	if cd.SetUseCircularEdge then
		cd:SetUseCircularEdge(false)
	end
	if cd.SetDrawEdge then
		cd:SetDrawEdge(false)
	end
	if cd.SetDrawBling then
		cd:SetDrawBling(false)
	end
	if cd.SetDrawSwipe then
		cd:SetDrawSwipe(true)
	end
	if not cd.GCDMBlingSuppressed then
		cd.GCDMBlingSuppressed = true
		local function KillBling(self)
			if self.GCDMKillingBling then
				return
			end
			self.GCDMKillingBling = true
			if self.SetDrawBling then
				self:SetDrawBling(false)
			end
			if self.SetDrawEdge then
				self:SetDrawEdge(false)
			end
			self.GCDMKillingBling = false
		end
		if cd.SetDrawBling then
			hooksecurefunc(cd, "SetDrawBling", function(self, draw)
				if draw then
					KillBling(self)
				end
			end)
		end
		if cd.SetDrawEdge then
			hooksecurefunc(cd, "SetDrawEdge", function(self, draw)
				if draw then
					KillBling(self)
				end
			end)
		end
		if cd.SetCooldown then
			hooksecurefunc(cd, "SetCooldown", KillBling)
		end
		if cd.SetCooldownFromDurationObject then
			hooksecurefunc(cd, "SetCooldownFromDurationObject", KillBling)
		end
		if cd.Clear then
			hooksecurefunc(cd, "Clear", KillBling)
		end
	end

	local regions = { cd:GetRegions() }
	for i = 1, #regions do
		local region = regions[i]
		if region and region.IsObjectType and region:IsObjectType("Texture") then
			Pixel.DisableTextureSnap(region)
			local name = region.GetName and region:GetName()
			if type(name) == "string" and (name:find("Bling", 1, true) or name:find("Edge", 1, true)) then
				region:SetAlpha(0)
			end
		end
	end

	local chargeCd = frame.ChargeCooldown
	if chargeCd and chargeCd.SetDrawBling then
		chargeCd:SetDrawBling(false)
		if chargeCd.SetDrawEdge then
			chargeCd:SetDrawEdge(false)
		end
		if not chargeCd.GCDMBlingSuppressed then
			chargeCd.GCDMBlingSuppressed = true
			local function KillChargeBling(self)
				if self.SetDrawBling then
					self:SetDrawBling(false)
				end
				if self.SetDrawEdge then
					self:SetDrawEdge(false)
				end
			end
			hooksecurefunc(chargeCd, "SetDrawBling", function(self, draw)
				if draw then
					KillChargeBling(self)
				end
			end)
			if chargeCd.SetCooldown then
				hooksecurefunc(chargeCd, "SetCooldown", KillChargeBling)
			end
		end
	end
end
