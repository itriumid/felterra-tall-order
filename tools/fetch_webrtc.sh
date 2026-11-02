#!/usr/bin/env bash
# Fetches Godot's WebRTC extension (webrtc-native), which room codes play over: exactly the version
# below, checked against its SHA-256 before anything in it is used, and only the libraries for the
# platforms we ship. Its binaries stay out of git: the tests, the export check and the release
# workflow run this first, and so does tools/export.sh. Without it, the game still runs, and plays
# online by address only.
#
#   tools/fetch_webrtc.sh
#
# Updating it: change VERSION and SHA256 together, from the release's zip.

set -euo pipefail

VERSION="1.2.2-stable"
SHA256="98e9446921740d995bd9ca1be48798dc3c2ceed51e044a25ce18b3cff11f56e5"
URL="https://github.com/godotengine/webrtc-native/releases/download/$VERSION/godot-extension-webrtc_native.zip"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
addon="$here/addons/webrtc_native"
if [ -f "$addon/.version" ] && [ "$(cat "$addon/.version")" = "$VERSION" ]; then
  echo "webrtc-native $VERSION is already here"
  exit 0
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
curl --fail --location --silent --show-error --output "$work/webrtc.zip" "$URL"
# shasum on macOS and Linux runners alike; sha256sum isn't on macOS.
found="$(shasum -a 256 "$work/webrtc.zip" | cut -d ' ' -f 1)"
if [ "$found" != "$SHA256" ]; then
  echo "error: webrtc-native $VERSION has SHA-256 $found, not $SHA256" >&2
  exit 1
fi

# Only what we ship: Windows x86-64, macOS universal, Linux x86-64 and ARM, debug (the editor and
# the tests) and release (the exports).
unzip -q "$work/webrtc.zip" -d "$work/extracted" \
  "addons/webrtc_native/webrtc_native.gdextension" "addons/webrtc_native/LICENSE.*" \
  "addons/webrtc_native/lib/*windows*x86_64*" "addons/webrtc_native/lib/*macos*" \
  "addons/webrtc_native/lib/*linux*x86_64*" "addons/webrtc_native/lib/*linux*arm64*"
rm -rf "$addon"
mkdir -p "$here/addons"
mv "$work/extracted/addons/webrtc_native" "$addon"
echo "$VERSION" > "$addon/.version"
echo "webrtc-native $VERSION fetched into addons/webrtc_native"
