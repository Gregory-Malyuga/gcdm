local ADDON_NAME, ns = ...

function ns.Tests.Logic.AuraSoundKeys(h, ctx)
	local T = ns.Testables
	if not T or not T.ParseSoundKey then
		h.check("ParseSoundKey testable exported", false)
		return
	end

	local kind, kit, lsm = T.ParseSoundKey("kit:878", {})
	h.check("ParseSoundKey kit", kind == "kit" and kit == 878 and lsm == nil, tostring(kind) .. ":" .. tostring(kit))

	kind, kit, lsm = T.ParseSoundKey("lsm:MySound", {})
	h.check("ParseSoundKey lsm", kind == "lsm" and lsm == "MySound", tostring(lsm))

	kind, kit, lsm = T.ParseSoundKey("1234", {})
	h.check("ParseSoundKey legacy number", kind == "kit" and kit == 1234)

	kind, kit, lsm = T.ParseSoundKey("", { auraSoundDefaultKitID = 878 })
	h.check("ParseSoundKey empty → default kit", kind == "kit" and type(kit) == "number", tostring(kit))
end
