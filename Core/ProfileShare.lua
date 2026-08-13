local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

-- Profile string share via C_EncodingUtil (CBOR + compress + base64).
-- Wire: !GCDM:1!<base64>

local WIRE_PREFIX = "!GCDM:1!"
local EXPORT_VERSION = 1

local SKIP_KEYS = {
	auraSoundDraft = true,
	powerBarEditClass = true,
	_lastBuffBarDump = true,
}

local function DeepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	if CopyTable then
		return CopyTable(value)
	end
	local out = {}
	for k, v in pairs(value) do
		out[k] = DeepCopy(v)
	end
	return out
end

local function EncodingReady()
	return C_EncodingUtil
		and C_EncodingUtil.SerializeCBOR
		and C_EncodingUtil.DeserializeCBOR
		and C_EncodingUtil.CompressString
		and C_EncodingUtil.DecompressString
		and C_EncodingUtil.EncodeBase64
		and C_EncodingUtil.DecodeBase64
end

local function SanitizeProfile(profile)
	local out = {}
	if type(profile) ~= "table" then
		return out
	end
	for k, v in pairs(profile) do
		if type(k) == "string" and not SKIP_KEYS[k] then
			-- Keep migration markers; drop only known ephemeral UI junk.
			out[k] = DeepCopy(v)
		end
	end
	return out
end

local function NormalizeWire(str)
	if type(str) ~= "string" or str == "" then
		return nil
	end
	local normalized = str:gsub("[%s%z]", "")
	local _, prefixEnd = normalized:find(WIRE_PREFIX, 1, true)
	if prefixEnd then
		normalized = normalized:sub(prefixEnd + 1)
	elseif normalized:sub(1, 6) == "!GCDM:" then
		-- Allow future versions: !GCDM:N!
		local verEnd = normalized:find("!", 7, true)
		if verEnd then
			normalized = normalized:sub(verEnd + 1)
		end
	end
	if normalized == "" then
		return nil
	end
	return normalized
end

ns.Testables = ns.Testables or {}
ns.Testables.SanitizeProfile = SanitizeProfile
ns.Testables.NormalizeWire = NormalizeWire

function GCDM:ExportProfileString(profileName)
	if not EncodingReady() then
		return nil, "encoding_unavailable"
	end
	local db = self.db
	if not db or not db.profile then
		return nil, "no_profile"
	end
	profileName = profileName or (db.GetCurrentProfile and db:GetCurrentProfile()) or "Default"
	local payload = {
		addon = ADDON_NAME,
		exportVersion = EXPORT_VERSION,
		profileName = profileName,
		name = profileName,
		timestamp = time and time() or 0,
		data = SanitizeProfile(db.profile),
	}
	local okCbor, cbor = pcall(C_EncodingUtil.SerializeCBOR, payload)
	if not okCbor or not cbor then
		return nil, "serialize_failed"
	end
	local okComp, compressed = pcall(C_EncodingUtil.CompressString, cbor)
	if not okComp or not compressed then
		return nil, "compress_failed"
	end
	local okB64, b64 = pcall(C_EncodingUtil.EncodeBase64, compressed)
	if not okB64 or not b64 then
		return nil, "encode_failed"
	end
	return WIRE_PREFIX .. b64
end

function GCDM:DecodeProfileString(profileString)
	if not EncodingReady() then
		return nil, "encoding_unavailable"
	end
	local normalized = NormalizeWire(profileString)
	if not normalized then
		return nil, "empty"
	end
	local okB64, compressed = pcall(C_EncodingUtil.DecodeBase64, normalized)
	if not okB64 or not compressed then
		return nil, "invalid_base64"
	end
	local okDecomp, cbor = pcall(C_EncodingUtil.DecompressString, compressed)
	if not okDecomp or not cbor then
		return nil, "decompress_failed"
	end
	local okPay, payload = pcall(C_EncodingUtil.DeserializeCBOR, cbor)
	if not okPay or type(payload) ~= "table" then
		return nil, "invalid_payload"
	end
	if payload.addon and payload.addon ~= ADDON_NAME then
		return nil, "wrong_addon"
	end
	local data = payload.data
	if type(data) ~= "table" then
		-- Allow bare profile table payloads.
		if payload.enabled ~= nil or payload.textByViewer ~= nil then
			data = payload
		else
			return nil, "invalid_profile_data"
		end
	end
	local name = payload.profileName or payload.name or "Imported"
	if type(name) ~= "string" or name == "" then
		name = "Imported"
	end
	return {
		name = name,
		data = SanitizeProfile(data),
		exportVersion = payload.exportVersion or 1,
	}
end

local function UniqueProfileName(db, baseName)
	baseName = tostring(baseName or "Imported")
	baseName = baseName:gsub("[%c]", ""):sub(1, 60)
	if baseName == "" then
		baseName = "Imported"
	end
	local name = baseName
	local i = 2
	while rawget(db.profiles, name) do
		name = string.format("%s (%d)", baseName, i)
		i = i + 1
		if i > 99 then
			name = baseName .. "-" .. tostring(time and time() or math.random(1000, 9999))
			break
		end
	end
	return name
end

local function WriteProfileData(dest, data)
	for k in pairs(dest) do
		dest[k] = nil
	end
	for k, v in pairs(data) do
		dest[k] = DeepCopy(v)
	end
end

--- Import decoded profile. mode = "new" | "current"
function GCDM:ImportProfileData(decoded, mode, requestedName)
	local db = self.db
	if not db or type(decoded) ~= "table" or type(decoded.data) ~= "table" then
		return nil, "invalid_profile_data"
	end
	mode = mode or "new"
	local data = SanitizeProfile(decoded.data)

	if mode == "current" then
		WriteProfileData(db.profile, data)
		if self.Refresh then
			self:Refresh(self.CONST.REFRESH.ALL)
		end
		return db:GetCurrentProfile(), "ok"
	end

	local name = UniqueProfileName(db, requestedName or decoded.name)
	-- Create profile storage then switch.
	if not rawget(db.profiles, name) then
		db.profiles[name] = {}
	end
	WriteProfileData(db.profiles[name], data)
	db:SetProfile(name)
	if self.Refresh then
		self:Refresh(self.CONST.REFRESH.ALL)
	end
	return name, "ok"
end

function GCDM:ImportProfileString(profileString, mode, requestedName)
	local decoded, err = self:DecodeProfileString(profileString)
	if not decoded then
		return nil, err
	end
	return self:ImportProfileData(decoded, mode, requestedName)
end
