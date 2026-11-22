#Requires -Version 7.0
# docs/spec/update-check.md「发布侧脚本」: the one read-back check of update manifest bytes. Both
# release scripts dot-source this file and call Assert-UpdateManifest; no second copy of these
# checks may exist anywhere else:
#  - tools/update-manifest.ps1 runs it on its temporary file, before -Out appears;
#  - tools/sign-update-manifest.ps1 runs it on -Manifest before anything is signed, so a manifest
#    edited by hand after generation (say, notes grown past the limit) is refused instead of being
#    signed and then silently rejected by every client (update/update_manifest.gd::evaluate).
# Checked, in this order: 1..65536 bytes (the client's MAX_BYTES), no UTF-8 BOM, no CR, strict
# UTF-8, strict JSON, at least one platform, and every platform's full.url and full.mirror start
# with https://. Any failure throws. Dot-sourcing this file only defines the function.

# -ParameterPrefix maps a manifest platform key to the generator's parameter prefix, so that the
# generator's message names -WindowsUrl/-AndroidMirror; without an entry the message names the
# manifest field alone. Returns the byte count.
function Assert-UpdateManifest {
    param([string]$Path, [hashtable]$ParameterPrefix = @{})
    $maximumBytes = 65536
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -eq 0 -or $bytes.Length -gt $maximumBytes) { throw "manifest is $($bytes.Length) bytes; the limit is $maximumBytes (-NotesFile is the free-length input)." }
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { throw 'manifest starts with a UTF-8 BOM.' }
    if ([Array]::IndexOf($bytes, [byte]13) -ge 0) { throw 'manifest contains CR; line ends must be LF.' }
    $text = [Text.UTF8Encoding]::new($false, $true).GetString($bytes)
    $document = [Text.Json.JsonDocument]::Parse($text, [Text.Json.JsonDocumentOptions]::new())
    try {
        $platforms = @($document.RootElement.GetProperty('platforms').EnumerateObject())
        if ($platforms.Count -eq 0) { throw 'manifest names no platform.' }
        foreach ($platform in $platforms) {
            $full = $platform.Value.GetProperty('full')
            foreach ($field in @('url', 'mirror')) {
                $link = $full.GetProperty($field).GetString()
                $place = $platform.Name + '.full.' + $field
                $subject = if ($ParameterPrefix.ContainsKey($platform.Name)) { '-' + $ParameterPrefix[$platform.Name] + $(if ($field -eq 'url') { 'Url' } else { 'Mirror' }) + " is not https:// ($place)" } else { "manifest $place is not https://" }
                if (-not $link.StartsWith('https://', [StringComparison]::Ordinal)) { throw "${subject}: $link" }
            }
        }
    } finally { $document.Dispose() }
    return $bytes.Length
}
