#!/usr/bin/env bash
# Exports the game for every platform and packs each into a zip, plus their checksums: what the
# release workflow attaches, and what the export check builds on every pull request. The names
# carry no version, so https://github.com/itriumid/felterra-tall-order/releases/latest/download/
# <name> always means the newest release; the version is in the release itself, in each app's own
# metadata (the Windows file properties, the macOS bundle, both from config/version), and on the
# game's title. Needs Godot's export templates installed for the Godot version below.
#
#   GODOT=/path/to/godot tools/export.sh [output folder]
#
# GODOT defaults to `godot` on the path; the output folder to build/release.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot="${GODOT:-godot}"
out="${1:-$here/build/release}"
version=$(sed -n 's/^config\/version="\(.*\)"$/\1/p' "$here/project.godot")
if [ -z "$version" ]; then
  echo "error: project.godot has no config/version" >&2
  exit 1
fi
name="FelterraTallOrder"
echo "Exporting version $version"

cd "$here"
# WebRTC, which room codes play over: fetched at its pinned version, checked, and exported with
# the game, its library beside each platform's executable (inside the app on macOS).
tools/fetch_webrtc.sh
rm -rf build/windows build/macos build/linux build/linux_arm "$out"
mkdir -p build/windows build/macos build/linux build/linux_arm "$out"
# As an absolute path: the zipping below happens from inside each platform's folder, where a
# relative one would point nowhere.
out="$(cd "$out" && pwd)"
# Importing builds the class name cache; it can report editor errors that don't matter here.
"$godot" --headless --path . --import > /dev/null 2>&1 || true
for preset in "Windows" "macOS" "Linux" "Linux ARM"; do
  echo "Exporting $preset"
  "$godot" --headless --path . --export-release "$preset" > "build/export_${preset// /_}.log" 2>&1 || {
    cat "build/export_${preset// /_}.log"
    echo "error: exporting $preset failed" >&2
    exit 1
  }
done

# Godot reports some failures in the log but still exits 0, so the files are checked too.
for file in "build/windows/Felterra Tall Order.exe" "build/macos/Felterra Tall Order.zip" \
  "build/linux/felterra_tall_order.x86_64" "build/linux_arm/felterra_tall_order.arm64"; do
  if [ ! -s "$file" ]; then
    echo "error: $file wasn't exported" >&2
    exit 1
  fi
done

# WebRTC's library has to be beside each executable, or room codes are gone from that build.
for file in build/windows/libwebrtc_native.windows.template_release.x86_64.dll \
  build/linux/libwebrtc_native.linux.template_release.x86_64.so \
  build/linux_arm/libwebrtc_native.linux.template_release.arm64.so; do
  if [ ! -s "$file" ]; then
    echo "error: $file wasn't exported" >&2
    exit 1
  fi
done

# The licenses of what's inside besides the game: WebRTC and the libraries it's built on. Two of
# those (libdatachannel and libjuice) are under the Mozilla Public License, whose notice has to
# travel with the binaries; their source is at https://github.com/paullouisageneau.
rm -rf build/licenses && mkdir -p build/licenses
cp addons/webrtc_native/LICENSE.* build/licenses/

# One zip per platform, each holding the game, its libraries and the licenses.
(cd build/windows && cp "$here/LICENSE" . && cp -R ../licenses . && zip -q -X -r "$out/${name}_windows_x86_64.zip" "Felterra Tall Order.exe" ./*.dll LICENSE licenses)
# macOS can't have a colon in a file name, so Godot names the app "Felterra- Tall Order.app".
# Renaming the bundle's folder keeps its signature. The zip carries no macOS file metadata, so
# every unzip tool, not only Finder, extracts the app with its seal intact.
rm -rf build/macos/app && mkdir -p build/macos/app
(cd build/macos/app && unzip -q "../Felterra Tall Order.zip" && mv ./*.app "Felterra Tall Order.app")
app="build/macos/app/Felterra Tall Order.app"
if ! ls "$app/Contents/Frameworks/" | grep -q webrtc_native; then
  echo "error: WebRTC's library isn't in the Mac app's Frameworks" >&2
  exit 1
fi
# The licenses go inside the app, and it's signed again, ad hoc as Godot signed it, to cover them.
cp -R build/licenses "$app/Contents/Resources/licenses"
codesign --force --deep --sign - "$app"
codesign --verify --deep "$app"
ditto -c -k --norsrc --noextattr --noacl --keepParent "build/macos/app/Felterra Tall Order.app" "$out/${name}_macos_universal.zip"
(cd build/linux && cp "$here/LICENSE" . && cp -R ../licenses . && chmod +x felterra_tall_order.x86_64 && zip -q -X -r "$out/${name}_linux_x86_64.zip" felterra_tall_order.x86_64 ./*.so LICENSE licenses)
(cd build/linux_arm && cp "$here/LICENSE" . && cp -R ../licenses . && chmod +x felterra_tall_order.arm64 && zip -q -X -r "$out/${name}_linux_arm64.zip" felterra_tall_order.arm64 ./*.so LICENSE licenses)
(cd "$out" && shasum -a 256 ./*.zip | sed 's| \./| |' > "${name}_checksums.txt")
ls -l "$out"
