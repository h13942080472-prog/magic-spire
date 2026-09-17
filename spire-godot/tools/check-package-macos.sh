#!/usr/bin/env bash
# macOS counterpart of check-package.ps1: manifest hashes, content link and signature,
# the release PCK probe, and a headless launch of the packaged app.
# --zip then creates the distribution ZIP with ditto and re-verifies the extracted copy.
set -euo pipefail

usage() { echo 'Usage: tools/check-package-macos.sh --directory DIR [--zip]' >&2; exit 2; }
fail() { echo "ERROR: $*" >&2; exit 1; }

directory=''
make_zip=0
while [ $# -gt 0 ]; do
    case $1 in
        --directory) [ $# -ge 2 ] || usage; directory=$2; shift 2 ;;
        --zip) make_zip=1; shift ;;
        *) usage ;;
    esac
done
[ -n "$directory" ] || usage
[ -d "$directory" ] || fail "Package directory not found: $directory"
directory=$(cd "$directory" && pwd)
tools_dir=$(cd "$(dirname "$0")" && pwd)
game_dir=$(dirname "$tools_dir")
. "$tools_dir/find-godot.sh"
check_dir="$game_dir/build/package-check-macos-$(date -u +%Y%m%dT%H%M%S)"
mkdir -p "$check_dir/home" "$check_dir/saves"

verify_package() {
    local root=$1 manifest="$1/manifest.json" app="$1/紧缚尖塔.app" count index=0 path expected
    [ -f "$manifest" ] || fail "manifest.json is missing: $root"
    count=$(plutil -extract files raw -o - "$manifest")
    [ "$count" -gt 0 ] || fail 'Manifest lists no files.'
    while [ "$index" -lt "$count" ]; do
        path=$(plutil -extract "files.$index.path" raw -o - "$manifest")
        expected=$(plutil -extract "files.$index.sha256" raw -o - "$manifest")
        case "/$path/" in //*|*/../*) fail "Manifest path leaves package directory: $path" ;; esac
        [ -f "$root/$path" ] || fail "Packaged file is missing: $path"
        [ "$(shasum -a 256 "$root/$path" | cut -d ' ' -f 1)" = "$expected" ] || fail "Package checksum mismatch: $path"
        index=$((index + 1))
    done
    [ "$(readlink "$app/Contents/MacOS/content" || true)" = ../Resources/content ] || fail 'Contents/MacOS/content must link to ../Resources/content.'
    codesign --verify --deep --strict "$app" || fail "Signature check failed: $app"
}

run_with_timeout() {
    local seconds=$1 pid watchdog status=0
    shift
    "$@" &
    pid=$!
    (sleep "$seconds"; kill "$pid" 2>/dev/null) &
    watchdog=$!
    wait "$pid" || status=$?
    pkill -P "$watchdog" 2>/dev/null || true
    kill "$watchdog" 2>/dev/null || true
    wait "$watchdog" 2>/dev/null || true
    return "$status"
}

# Saves and Godot user data go to temporary folders, never the player's own profile.
run_check() {
    local name=$1 expected=$2 executable=$3 log="$check_dir/$1.log" status=0
    shift 3
    run_with_timeout 60 env HOME="$check_dir/home" SPIRE_PROBE_SAVES="$check_dir/saves" \
        SPIRE_PROBE_CONTENT="$app/Contents/MacOS/content/packs" SPIRE_PROBE_VERSION="$version" \
        "$executable" --log-file "$log" "$@" > "$check_dir/$name-console.log" 2>&1 || status=$?
    [ "$status" -eq 0 ] || fail "Package check failed or timed out ($name, exit=$status): $log"
    [ -f "$log" ] || fail "Package check produced no log: $name"
    ! grep -Eq '^[[:space:]]*(USER )?(SCRIPT |PARSE )?ERROR:' "$log" || fail "Package check logged errors ($name): $log"
    grep -Eq "$expected" "$log" || fail "Package check is missing its completion marker ($name): $log"
}

verify_package "$directory"
version=$(plutil -extract version raw -o - "$directory/manifest.json")
app="$directory/紧缚尖塔.app"
pck=$(find "$app/Contents/Resources" -maxdepth 1 -name '*.pck' | head -n 1)
[ -n "$pck" ] || fail 'Release PCK is missing from Contents/Resources.'
executable="$app/Contents/MacOS/$(plutil -extract CFBundleExecutable raw -o - "$app/Contents/Info.plist")"
engine=$(find_godot)
run_check pck '^RELEASE PROBE PASS$' "$engine" --headless --path "$app/Contents/Resources" --main-pack "$pck" --script "$tools_dir/release_probe.gd"
run_check native 'Godot Engine' "$executable" --headless --quit-after 120

if [ "$make_zip" -eq 1 ]; then
    zip_path="$directory.zip"
    [ ! -e "$zip_path" ] || fail "ZIP already exists: $zip_path"
    # ditto keeps the content link and signature intact; zip -r would copy the packs into Contents/MacOS.
    ditto -c -k --sequesterRsrc --keepParent "$directory" "$zip_path"
    mkdir -p "$check_dir/zip"
    ditto -x -k "$zip_path" "$check_dir/zip"
    verify_package "$check_dir/zip/$(basename "$directory")"
    echo "PACKAGE ZIP: $zip_path"
    echo "PACKAGE ZIP SHA256: $(shasum -a 256 "$zip_path" | cut -d ' ' -f 1)"
fi
echo "PACKAGE CHECK PASS: $directory"
echo "PACKAGE CHECK LOGS: $check_dir"
