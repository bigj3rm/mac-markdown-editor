#!/bin/bash
# Packages a built app into a drag-to-install disk image.
#
# Usage: scripts/package-dmg.sh <path to the .app> <path of the .dmg to create>
set -euo pipefail

app_path="${1:?Usage: package-dmg.sh <path to the .app> <path of the .dmg to create>}"
dmg_path="${2:?Usage: package-dmg.sh <path to the .app> <path of the .dmg to create>}"

app_name="Markdown Editor.app"
volume_name="Markdown Editor"

staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT

# The product is named after the Xcode target; the installed app gets its friendly name here.
ditto "$app_path" "$staging_dir/$app_name"
ln -s /Applications "$staging_dir/Applications"

# Fail now, not on someone else's Mac, if the copy's signature is broken.
codesign --verify --deep --strict "$staging_dir/$app_name"

hdiutil create -volname "$volume_name" -srcfolder "$staging_dir" -ov -format UDZO "$dmg_path"
echo "Created $dmg_path"
