# Sourced by the macOS packaging scripts; prints the Godot editor executable.
find_godot() {
    local candidate
    for candidate in "${GODOT_BIN:-}" "$(command -v godot 2>/dev/null || true)" "$(command -v godot4 2>/dev/null || true)" \
        /Applications/Godot.app/Contents/MacOS/Godot "$HOME/Applications/Godot.app/Contents/MacOS/Godot" \
        "$HOME"/Downloads/Godot*.app/Contents/MacOS/Godot "$HOME"/Downloads/Godot*/Godot*.app/Contents/MacOS/Godot; do
        if [ -n "$candidate" ] && [ -f "$candidate" ] && [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo 'Godot 4 was not found. Set GODOT_BIN to Godot.app/Contents/MacOS/Godot.' >&2
    return 1
}
