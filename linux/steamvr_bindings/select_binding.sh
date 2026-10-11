#!/bin/bash
# Selects index_legacy.json as the SteamVR controller binding for gzdoomvr.
#
# SteamVR must be running and gzdoomvr must have been started once before, so that SteamVR
# knows the application. SteamVR remembers the selection together with the path of the
# file: run this again after moving the repository. To undo it, choose the default binding
# for gzdoomvr under SteamVR Settings -> Controllers -> Manage Controller Bindings.
#
# This talks to the local web interface that SteamVR's own binding editor uses. It is not
# a documented API and may change with SteamVR updates; the binding can always be loaded
# by hand in that editor instead.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
binding="file://$dir/index_legacy.json"
steamvr="http://127.0.0.1:27062"

curl --fail --silent --show-error \
	-H "Referer: $steamvr/dashboard/controllerbinding.html" \
	-H "Origin: $steamvr" \
	-H "Content-Type: application/json" \
	-d "{\"app_key\":\"system.generated.gzdoomvr\",\"controller_type\":\"knuckles\",\"url\":\"$binding\"}" \
	"$steamvr/input/selectconfig.action"
echo
echo "Selected $binding"
