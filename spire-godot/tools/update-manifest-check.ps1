#Requires -Version 7.0
# docs/spec/update-check.md「发布侧脚本」: the one read-back check of update manifest bytes. Both
# release scripts dot-source this file and call Assert-UpdateManifest; no second copy of these
# checks may exist anywhere else:
#  - tools/update-manifest.ps1 runs it on its temporary file, before -Out appears;
#  - tools/sign-update-manifest.ps1 runs it on -Manifest before anything is signed, so a manifest
#    edited by hand after generation (say, notes grown past the limit) is refused instead of being
#    signed and then silently rejected by every client (update/update_manifest.gd::evaluate).
# Checked, in this order: 1..65536 bytes (the client's MAX_BYTES), no UTF-8 BOM, no CR, strict
# UTF-8, strict JSON, at least one platform, every platform's full.url and full.mirror start
# with https://, and every patches[] entry of every platform is one the client can accept: from and
# to non-empty strings, to == latest.version, url and mirror https://, bytes a whole number in
# (0, 256 MiB] (update/update_manifest.gd::MAX_PATCH_BYTES), sha256 64 lower-case hex digits, and no
# (from, to) pair twice. Any failure throws. Dot-sourcing this file only defines the functions.

# One named member of a JSON object element; a missing member or a wrong kind throws.
function Get-ManifestMember {
    param([Text.Json.JsonElement]$Element, [string]$Name, [Text.Json.JsonValueKind]$Kind, [string]$Place)
    foreach ($property in $Element.EnumerateObject()) {
        if ($property.Name -ceq $Name) {
            if ($property.Value.ValueKind -ne $Kind) { throw "manifest $Place.$Name is $($property.Value.ValueKind), not $Kind." }
            return $property.Value
        }
    }
    throw "manifest $Place.$Name is missing."
}

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
        $latestVersion = $document.RootElement.GetProperty('latest').GetProperty('version').GetString()
        foreach ($platform in $platforms) {
            $full = $platform.Value.GetProperty('full')
            foreach ($field in @('url', 'mirror')) {
                $link = $full.GetProperty($field).GetString()
                $place = $platform.Name + '.full.' + $field
                $subject = if ($ParameterPrefix.ContainsKey($platform.Name)) { '-' + $ParameterPrefix[$platform.Name] + $(if ($field -eq 'url') { 'Url' } else { 'Mirror' }) + " is not https:// ($place)" } else { "manifest $place is not https://" }
                if (-not $link.StartsWith('https://', [StringComparison]::Ordinal)) { throw "${subject}: $link" }
            }
            foreach ($member in $platform.Value.EnumerateObject()) {
                if ($member.Name -cne 'patches') { continue }
                $listed = "$($platform.Name).patches"
                if ($member.Value.ValueKind -ne [Text.Json.JsonValueKind]::Array) { throw "manifest $listed is not an array." }
                $pairs = @{}
                $index = 0
                foreach ($entry in $member.Value.EnumerateArray()) {
                    $place = "$listed[$index]"
                    if ($entry.ValueKind -ne [Text.Json.JsonValueKind]::Object) { throw "manifest $place is not an object." }
                    $from = (Get-ManifestMember $entry 'from' String $place).GetString()
                    $to = (Get-ManifestMember $entry 'to' String $place).GetString()
                    if (-not $from -or -not $to) { throw "manifest $place has an empty from or to." }
                    if ($to -cne $latestVersion) { throw "manifest $place.to is '$to', not latest.version '$latestVersion'." }
                    foreach ($field in @('url', 'mirror')) {
                        $link = (Get-ManifestMember $entry $field String $place).GetString()
                        $subject = if ($ParameterPrefix.ContainsKey($platform.Name)) { '-' + $ParameterPrefix[$platform.Name] + 'Patch' + $(if ($field -eq 'url') { 'Url' } else { 'Mirror' }) + " is not https:// ($place.$field)" } else { "manifest $place.$field is not https://" }
                        if (-not $link.StartsWith('https://', [StringComparison]::Ordinal)) { throw "${subject}: $link" }
                    }
                    $size = [long]0
                    if (-not (Get-ManifestMember $entry 'bytes' Number $place).TryGetInt64([ref]$size) -or $size -le 0 -or $size -gt 268435456) { throw "manifest $place.bytes must be a whole number from 1 to 268435456." }
                    # \z, not $: in .NET `$` also matches before a final line feed.
                    if ((Get-ManifestMember $entry 'sha256' String $place).GetString() -cnotmatch '^[0-9a-f]{64}\z') { throw "manifest $place.sha256 must be 64 lower-case hex digits." }
                    if ($pairs.ContainsKey("$from|$to")) { throw "manifest $listed names the pair $from -> $to twice." }
                    $pairs["$from|$to"] = $true
                    $index++
                }
            }
        }
    } finally { $document.Dispose() }
    return $bytes.Length
}
