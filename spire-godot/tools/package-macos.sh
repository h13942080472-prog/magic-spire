#!/usr/bin/env bash
# macOS counterpart of package.ps1: fresh output folder, export log checks,
# runtime source fingerprint, third-party licenses and a SHA-256 file manifest.
set -euo pipefail

usage() { echo 'Usage: tools/package-macos.sh [--output-root DIR] [--build-id ID]' >&2; exit 2; }
fail() { echo "ERROR: $*" >&2; exit 1; }

output_root=''
build_id=''
while [ $# -gt 0 ]; do
    case $1 in
        --output-root) [ $# -ge 2 ] || usage; output_root=$2; shift 2 ;;
        --build-id) [ $# -ge 2 ] || usage; build_id=$2; shift 2 ;;
        *) usage ;;
    esac
done

[ "$(uname -s)" = Darwin ] || fail 'macOS packages must be built on a Mac (codesign is required).'
tools_dir=$(cd "$(dirname "$0")" && pwd)
game_dir=$(dirname "$tools_dir")
repo_dir=$(dirname "$game_dir")
. "$tools_dir/find-godot.sh"

version=$(grep -E '^config/version="[0-9]+\.[0-9]+(\.[0-9]+)?"$' "$game_dir/project.godot" | head -n 1 | cut -d '"' -f 2 || true)
[ -n "$version" ] || fail 'Project version is missing or invalid.'
preset="macOS v$version"
grep -qxF "name=\"$preset\"" "$game_dir/export_presets.cfg" || fail "Export preset is missing: $preset"
[ -n "$output_root" ] || output_root="$repo_dir/outputs"
[ -n "$build_id" ] || build_id=$(date -u +%Y%m%dT%H%M%S)
case $build_id in *[!A-Za-z0-9_-]*) fail 'BuildId may contain only letters, numbers, hyphens and underscores.' ;; esac
destination="$output_root/spire-v$version-macos-universal-$build_id"
[ ! -e "$destination" ] || fail "Output already exists: $destination"
engine=$(find_godot)
log_dir="$game_dir/build/package-macos-$build_id"
mkdir -p "$destination" "$log_dir"
app="$destination/紧缚尖塔.app"

runtime_fingerprint() {
    (cd "$game_dir" && find core data ui assets content/packs project.godot main.tscn export_presets.cfg -type f ! -name '*.uid' ! -name '*.import' -print0 |
        xargs -0 shasum -a 256 | LC_ALL=C sort)
}

# Accept both the module docs layout and docs/ + release/ at the repository root.
first_existing() {
    local path
    for path in "$@"; do
        if [ -e "$path" ]; then printf '%s\n' "$path"; return 0; fi
    done
    echo "ERROR: none of these files exist: $*" >&2
    return 1
}

source_before=$(runtime_fingerprint)
export_log="$log_dir/export.log"
export_exit=0
"$engine" --headless --path "$game_dir" --log-file "$export_log" --export-release "$preset" "$app" > "$log_dir/export-console.log" 2>&1 || export_exit=$?
if [ "$export_exit" -ne 0 ] || [ ! -d "$app" ] || [ ! -f "$export_log" ] || grep -Eq '^[[:space:]]*(USER )?(SCRIPT |PARSE )?ERROR:' "$export_log"; then
    fail "Export failed (exit=$export_exit): $export_log"
fi

# content_catalog.gd reads content/packs beside the executable, which is Contents/MacOS.
# Store the packs as bundle resources and link them there so the app can be signed as a whole.
mkdir -p "$app/Contents/Resources/content"
cp -R "$game_dir/content/packs" "$app/Contents/Resources/content/"
ln -s ../Resources/content "$app/Contents/MacOS/content"
codesign --force --sign - --options runtime --preserve-metadata=identifier,entitlements,requirements,flags "$app" > "$log_dir/codesign.log" 2>&1 ||
    fail "Ad-hoc signing failed: $log_dir/codesign.log"
codesign --verify --deep --strict "$app" >> "$log_dir/codesign.log" 2>&1 || fail "Signature check failed: $log_dir/codesign.log"

notes=$(first_existing "$game_dir/docs/release-v$version.txt" "$repo_dir/docs/release-v$version.txt" "$repo_dir/版本更新内容.txt")
cp "$notes" "$destination/版本更新内容.txt"
guide=$(first_existing "$game_dir/基础操作教学.txt" "$repo_dir/release/基础操作教学.txt")
cp "$guide" "$destination/基础操作教学.txt"
cp "$tools_dir/macos-first-open.txt" "$destination/Mac首次打开说明.txt"
mkdir -p "$destination/licenses"
cp "$game_dir/assets/vendor/CREDITS.md" "$destination/licenses/"
cp "$game_dir/assets/fonts/OFL" "$destination/licenses/NotoSansCJK-OFL.txt"
cp "$repo_dir/LICENSE" "$repo_dir/ASSET_RIGHTS.md" "$destination/"
godot_license=$(first_existing "$game_dir/docs/licenses/GODOT-LICENSE.txt" "$repo_dir/docs/licenses/GODOT-LICENSE.txt")
cp "$godot_license" "$(dirname "$godot_license")/GODOT-COPYRIGHT.txt" "$destination/licenses/"

source_after=$(runtime_fingerprint)
[ "$source_before" = "$source_after" ] || fail 'Runtime sources changed during export. Keep this staging folder unpublished and export a fresh build.'
printf '%s\n' "$source_before" > "$log_dir/source-manifest.txt"

json_string() { printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"; }
engine_version=$("$engine" --version 2>/dev/null | tail -n 1)
manifest="$log_dir/manifest.json"
{
    printf '{\n  "version": %s,\n  "platform": "macos-universal",\n  "build": %s,\n  "engine": %s,\n  "files": [' \
        "$(json_string "$version")" "$(json_string "$build_id")" "$(json_string "$engine_version")"
    separator=''
    (cd "$destination" && find . -type f | sed 's#^\./##' | LC_ALL=C sort) | while IFS= read -r file; do
        printf '%s\n    {"path": %s, "bytes": %s, "sha256": "%s"}' "$separator" "$(json_string "$file")" \
            "$(stat -f %z "$destination/$file")" "$(shasum -a 256 "$destination/$file" | cut -d ' ' -f 1)"
        separator=','
    done
    printf '\n  ]\n}\n'
} > "$manifest"
cp "$manifest" "$destination/manifest.json"

echo "PACKAGE DIRECTORY: $destination"
echo "EXPORT LOG: $export_log"
echo 'Export complete. Run tools/check-package-macos.sh --directory <package> --zip before distributing it.'
