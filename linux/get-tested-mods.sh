#!/bin/bash
# Collects the mods this fork was tested with into one directory.
#
#   linux/get-tested-mods.sh [directory]        (default: ./mods)
#
# What it does:
#   - Downloads the two weapon packs that are hosted on GitHub and checks their SHA-256.
#   - Brutal Doom and the Liquid Texture Pack are hosted on ModDB, which does not allow
#     scripted downloads. For those the script tells you where to get them, and checks the
#     files once you have put them into the directory.
#
# The checksums are those of the files the tests were run with. A different checksum does
# not mean a file is broken, only that it is another version than the tested one.
#
# None of these mods belong to this project. They have their own authors and terms; this
# script only fetches them from where their authors published them. No game data
# (DOOM.WAD, DOOM2.WAD) is downloaded, you need your own.
set -euo pipefail

dir="${1:-mods}"
mkdir -p "$dir"

# name | sha256 | download URL
downloads=(
	"BR_VR_pbr_RC2.zip|4977270f1ed31d521998dd9686730051958ca8717cf6e7ea02cc48fb53679604|https://github.com/ajantaju/br_vr/releases/download/RC2/BR_VR_pbr_RC2.zip"
	"HDVRweapons.zip|84643dd9197b7d19e9ae22f1741d5c19a2e958af89120e92815d06d515dd4b9f|https://github.com/hh79/gz3doom/files/4378108/HDVRweapons.zip"
)

# name | sha256 | page to get it from
manual=(
	"brutalv21.pk3|e449e65604b1e9429099c7d3496830138425ba09c01fe49c08fb1c7acba7f6e0|https://www.moddb.com/mods/brutal-doom"
	"LTP V7.0.1.pk3|3a8287449ef1087ad94be2cdebbaa1585e4a0010d86aabad8950b66771647301|https://www.moddb.com/addons/doom-liquid-texture-pack"
	"LTP 21x9 RT Reflection 2560x1080.pk3|a4024d1152e725ae6fefa76e9ee428d57d6dd884dd3b2d76ad0264fe00635b6f|https://www.moddb.com/addons/doom-liquid-texture-pack"
	"LTP - Brutal Doom Lava Texture Patch.pk3|d2950359a2c6ba0299816b8c56d565c4a8139273d8a7b69f200c258677de16cf|https://www.moddb.com/addons/doom-liquid-texture-pack"
	"LTP - Doom Terrain Splashes.pk3|a98ae38dad3697fddc40c99440259473c2283e88945c4afbe7d9473753d01f12|https://www.moddb.com/addons/doom-liquid-texture-pack"
	"LTP - Doom 1 Texture Patch For E4M5.pk3|712106f28e22a0adcd24f31df9a72bcb0d957f36d20f20db444881192cb4e092|https://www.moddb.com/addons/doom-liquid-texture-pack"
)

checksum_ok() {
	[ "$(sha256sum "$1" | cut -d' ' -f1)" = "$2" ]
}

missing=0

echo "Weapon packs (downloaded):"
for entry in "${downloads[@]}"; do
	IFS='|' read -r name sum url <<<"$entry"
	file="$dir/$name"
	if [ -f "$file" ] && checksum_ok "$file" "$sum"; then
		echo "  ok       $name"
		continue
	fi
	echo "  fetching $name"
	tmp="$file.part"
	if ! curl --fail --location --silent --show-error --output "$tmp" "$url"; then
		rm -f "$tmp"
		echo "  FAILED   $name: could not download $url" >&2
		missing=1
		continue
	fi
	if checksum_ok "$tmp" "$sum"; then
		mv "$tmp" "$file"
		echo "  ok       $name"
	else
		rm -f "$tmp"
		echo "  FAILED   $name: the download does not have the expected checksum, not kept" >&2
		missing=1
	fi
done

echo
echo "Mods from ModDB (put them into '$dir' yourself):"
for entry in "${manual[@]}"; do
	IFS='|' read -r name sum page <<<"$entry"
	file="$dir/$name"
	if [ ! -f "$file" ]; then
		echo "  missing  $name"
		echo "           get it from $page"
		missing=1
	elif checksum_ok "$file" "$sum"; then
		echo "  ok       $name"
	else
		echo "  differs  $name (present, but not the version that was tested)"
	fi
done

cat <<EOF

The Liquid Texture Pack needs GZDoom 4.14, so use the branch linux-openvr-4.14 with it.
Its "RT Reflection" file is made for one screen resolution; pick the one for yours from
the pack. The E4M5 patch is only for the first Doom.

Tested load order for Doom 2 with Brutal Doom:

  gzdoomvr -iwad /path/to/DOOM2.WAD -file \\
    "$dir/brutalv21.pk3" \\
    "$dir/BR_VR_pbr_RC2.zip" \\
    "$dir/LTP V7.0.1.pk3" \\
    "$dir/LTP 21x9 RT Reflection 2560x1080.pk3" \\
    "$dir/LTP - Brutal Doom Lava Texture Patch.pk3" \\
    "$dir/LTP - Doom Terrain Splashes.pk3"

Without Brutal Doom, use HDVRweapons.zip instead of the first two files and leave out the
lava patch.
EOF

exit "$missing"
