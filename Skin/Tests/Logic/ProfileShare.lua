local ADDON_NAME, ns = ...

function ns.Tests.Logic.ProfileShare(h, ctx)
	local T = ns.Testables
	if not T or not T.SanitizeProfile or not T.NormalizeWire then
		h.check("ProfileShare testables exported", false)
		return
	end

	local sanitized = T.SanitizeProfile({
		enabled = true,
		auraSoundDraft = { x = 1 },
		powerBarEditClass = "WARRIOR",
		_lastBuffBarDump = "nope",
		glowEnabled = true,
	})
	h.check("Sanitize drops auraSoundDraft", sanitized.auraSoundDraft == nil)
	h.check("Sanitize drops powerBarEditClass", sanitized.powerBarEditClass == nil)
	h.check("Sanitize drops _lastBuffBarDump", sanitized._lastBuffBarDump == nil)
	h.check("Sanitize keeps glowEnabled", sanitized.glowEnabled == true)

	local wire = T.NormalizeWire("  !GCDM:1!abcXYZ  \n")
	h.check("NormalizeWire strips prefix+whitespace", wire == "abcXYZ", tostring(wire))

	local bare = T.NormalizeWire("plainbase64")
	h.check("NormalizeWire bare payload", bare == "plainbase64", tostring(bare))

	local addon = ctx.addon
	if addon.ExportProfileString and addon.DecodeProfileString then
		local exported, err = addon:ExportProfileString()
		if not exported then
			h.check("ExportProfileString encoding skip-or-ok", err == "encoding_unavailable", tostring(err))
		else
			h.check("Export starts with wire prefix", exported:sub(1, 8) == "!GCDM:1!", exported:sub(1, 16))
			local decoded, derr = addon:DecodeProfileString(exported)
			h.check("Decode roundtrip ok", decoded ~= nil and type(decoded.data) == "table", tostring(derr))
		end
	end
end
