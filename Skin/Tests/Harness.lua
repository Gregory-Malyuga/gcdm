local ADDON_NAME, ns = ...

ns.Tests = ns.Tests or {}
ns.Tests.Logic = ns.Tests.Logic or {}
ns.Tests.Behavior = ns.Tests.Behavior or {}

local Tests = ns.Tests

function Tests.Near(a, b, eps)
	eps = eps or 1.5
	a, b = tonumber(a), tonumber(b)
	if not a or not b then
		return false
	end
	return math.abs(a - b) <= eps
end

function Tests.Emit(msg)
	-- print() already goes to DEFAULT_CHAT_FRAME — do not AddMessage again.
	print("|cff3bb273GCDM test|r " .. tostring(msg))
end

--- Create a check harness for one suite run.
function Tests.NewHarness()
	local results = {}
	local h = {
		results = results,
	}

	function h.check(name, ok, detail)
		results[#results + 1] = { name = name, ok = ok and true or false, detail = detail }
	end

	function h.Near(a, b, eps)
		return Tests.Near(a, b, eps)
	end

	function h.Finish(addon, title)
		local pass, fail = 0, 0
		Tests.Emit("======== " .. (title or "GCDM tests") .. " ========")
		for i = 1, #results do
			local r = results[i]
			if r.ok then
				pass = pass + 1
				Tests.Emit("|cff00ff00PASS|r " .. r.name .. (r.detail and (" (" .. r.detail .. ")") or ""))
			else
				fail = fail + 1
				Tests.Emit("|cffff4444FAIL|r " .. r.name .. (r.detail and (" (" .. r.detail .. ")") or ""))
			end
		end
		Tests.Emit(string.format("======== %d passed, %d failed ========", pass, fail))
		if UIErrorsFrame and UIErrorsFrame.AddMessage then
			if fail == 0 then
				UIErrorsFrame:AddMessage(string.format("GCDM tests OK (%d)", pass), 0.2, 1, 0.4)
			else
				UIErrorsFrame:AddMessage(string.format("GCDM tests FAIL %d/%d", fail, pass + fail), 1, 0.3, 0.2)
			end
		end
		if addon then
			addon._lastTestResults = { pass = pass, fail = fail, results = results }
		end
		return fail == 0, pass, fail
	end

	return h
end
