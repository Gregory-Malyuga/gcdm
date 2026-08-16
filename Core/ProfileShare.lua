local ADDON_NAME, ns = ...
local GCDM = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

-- Profile import/apply (depends on ProfileShareCodec).

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
	local DeepCopy = ns.ProfileShareCodec.DeepCopy
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
	local data = ns.ProfileShareCodec.SanitizeProfile(decoded.data)

	if mode == "current" then
		WriteProfileData(db.profile, data)
		if self.Refresh then
			self:Refresh(self.CONST.REFRESH.ALL)
		end
		return db:GetCurrentProfile(), "ok"
	end

	local name = UniqueProfileName(db, requestedName or decoded.name)
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
