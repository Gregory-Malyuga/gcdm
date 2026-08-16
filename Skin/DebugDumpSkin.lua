local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local Skin = GCDM.Skin
local D = Skin.DebugUtil

function GCDM:DumpSkinDebug()
	local db = self:GetDB()
	self:Print(string.format(
		"GCDM debugSkin=%s zoom=%.3f border=%s",
		tostring(db and db.debugSkin),
		db and db.iconZoom or -1,
		db and db.borderSize or -1
	))
	local count = 0
	Skin.ForEachManagedIcon(function(frame, viewer, viewerName)
		count = count + 1
		if count > 8 then
			return
		end
		local icon = Skin.GetIconTexture(frame)
		local fw, fh = frame:GetWidth() or 0, frame:GetHeight() or 0
		local iw, ih = 0, 0
		if icon then
			iw, ih = icon:GetWidth() or 0, icon:GetHeight() or 0
		end
		local fname = frame.GetName and frame:GetName() or "<anon>"
		self:Print(string.format(
			"#%d %s/%s frame=%.1fx%.1f icon=%s %.1fx%.1f tex=%s masks=%d",
			count,
			tostring(viewerName),
			tostring(fname),
			fw,
			fh,
			icon and "yes" or "NO",
			iw,
			ih,
			D.DescribeTexCoord(icon),
			Skin.CountIconMasks(frame)
		))
		self:Print("  points frame: " .. D.DescribePoints(frame))
		if icon then
			self:Print("  points icon:  " .. D.DescribePoints(icon))
		end
		self:Print("  regions: " .. D.ListTextures(frame))
		if count == 1 and Skin.DescribeRegions then
			local details = Skin.DescribeRegions(frame)
			for i = 1, #details do
				self:Print("    " .. details[i])
			end
		end
	end)
	if count == 0 then
		self:Print("No managed icon frames found. Is Cooldown Manager enabled?")
	else
		self:Print(string.format(
			"Dumped %d icon(s) (max 8). Green=frame Magenta=icon texture.",
			math.min(count, 8)
		))
	end
end
