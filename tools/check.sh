#!/usr/bin/env bash
# GCDM CI checks: static analysis + headless logic tests.
# Usage: tools/check.sh   (run from the addon root)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0

echo "== luacheck (errors gate) =="
# Warnings are informational; only genuine errors fail the build.
luacheck Core Skin Options DB Locales Init.lua
rc=$?
# luacheck exit codes: 0 = clean, 1 = warnings only, 2+ = errors/critical.
if [ "$rc" -ge 2 ]; then
	echo "luacheck reported errors (exit $rc)"
	status=1
else
	echo "luacheck: no errors (exit $rc)"
fi

echo
echo "== headless logic tests =="
lua5.1 tools/headless_test.lua "$ROOT" || status=1

exit "$status"
