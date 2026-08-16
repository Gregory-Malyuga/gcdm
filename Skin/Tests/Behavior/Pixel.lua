local ADDON_NAME, ns = ...

function ns.Tests.Behavior.Pixel(h, ctx)
	local Pixel = ctx.Pixel
	local db = ctx.db
	if not Pixel or not db then
		return
	end
	Pixel.Update()
	local prev = db.pixelSnap
	db.pixelSnap = false
	h.check("Pixel.Snap passthrough when pixelSnap=false", Pixel.Snap(50.3) == 50.3, tostring(Pixel.Snap(50.3)))
	db.pixelSnap = true
	local snapped = Pixel.Snap(50.3)
	h.check("Pixel.Snap snaps when pixelSnap=true", type(snapped) == "number", tostring(snapped))
	db.pixelSnap = prev
end
