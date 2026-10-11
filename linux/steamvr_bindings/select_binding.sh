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
steamvr="http://127.0.0.1:27062"

# The path goes into a file:// URL and into JSON as it is. Refuse anything that would need
# encoding (spaces, umlauts, quotes, #, %) instead of sending a broken request.
if [[ ! "$dir" =~ ^[A-Za-z0-9/._+~-]+$ ]]; then
	echo "The repository path contains characters this script cannot pass to SteamVR:" >&2
	echo "  $dir" >&2
	echo "Move the repository, or load index_legacy.json by hand in SteamVR's binding editor." >&2
	exit 1
fi
binding="file://$dir/index_legacy.json"

response="$(curl --fail --silent --show-error \
	-H "Referer: $steamvr/dashboard/controllerbinding.html" \
	-H "Origin: $steamvr" \
	-H "Content-Type: application/json" \
	-d "{\"app_key\":\"system.generated.gzdoomvr\",\"controller_type\":\"knuckles\",\"url\":\"$binding\"}" \
	"$steamvr/input/selectconfig.action")"

# SteamVR answers with HTTP 200 even when it rejects the request.
if ! grep -q '"success"[[:space:]]*:[[:space:]]*true' <<<"$response"; then
	echo "SteamVR did not accept the binding. Its answer was:" >&2
	echo "$response" >&2
	exit 1
fi
echo "Selected $binding"
