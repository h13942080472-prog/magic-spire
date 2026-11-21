param(
    [Parameter(Mandatory)][string]$Version,
    [Parameter(Mandatory)][string]$NotesFile,
    [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$Serial,
    [string]$KeyId = 'k1',
    [string[]]$Revoked = @(),
    [Parameter(Mandatory)][string]$Out,
    [string]$WindowsZip = '', [string]$WindowsUrl = '', [string]$WindowsMirror = '',
    [string]$AndroidManifest = '', [string]$AndroidUrl = '', [string]$AndroidMirror = ''
)
# docs/spec/update-check.md「发布侧脚本」: the only generator of the schema-1 update manifest
# that tools/sign-update-manifest.ps1 signs and update/update_manifest.gd judges.
#
# Hash single source: an artifact is hashed once in the whole pipeline.
#  - android: bytes/sha256 are copied from the manifest.json that tools/package-android.ps1 wrote
#    next to the APK; this script never re-hashes the APK.
#  - windows-x64: the distribution ZIP is assembled by hand after tools/package.ps1, so no
#    pipeline step hashes it; this script is the one place that does (Get-FileHash, once).
#
# The manifest is written as UTF-8 without BOM with LF line ends to a temporary file, read back
# and checked (strict JSON, at most 65536 bytes, every url/mirror starting with https://); any
# failure throws and leaves no output file behind. An existing -Out is never overwritten.
$ErrorActionPreference = 'Stop'
$maximumBytes = 65536
$utf8 = [Text.UTF8Encoding]::new($false, $true)

function Assert-AbsoluteFile {
    param([string]$Path, [string]$Name)
    if (-not [IO.Path]::IsPathFullyQualified($Path)) { throw "-$Name must be an absolute path: $Path" }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "-$Name does not name a file: $Path" }
}

# One platform is either fully described (artifact, url, mirror) or absent.
function Test-PlatformGroup {
    param([string]$Name, [string]$Artifact, [string]$Url, [string]$Mirror)
    $given = @($Artifact, $Url, $Mirror | Where-Object { $_ })
    if ($given.Count -eq 0) { return $false }
    if ($given.Count -ne 3) { throw "$Name needs all three of its parameters (artifact, -${Name}Url, -${Name}Mirror)." }
    return $true
}

# The read-back check of the written bytes; the generator's only validation of url/mirror and size.
function Assert-UpdateManifest {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -eq 0 -or $bytes.Length -gt $maximumBytes) { throw "manifest is $($bytes.Length) bytes; the limit is $maximumBytes." }
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { throw 'manifest starts with a UTF-8 BOM.' }
    if ([Array]::IndexOf($bytes, [byte]13) -ge 0) { throw 'manifest contains CR; line ends must be LF.' }
    $text = $utf8.GetString($bytes)
    $document = [Text.Json.JsonDocument]::Parse($text, [Text.Json.JsonDocumentOptions]::new())
    try {
        $platforms = @($document.RootElement.GetProperty('platforms').EnumerateObject())
        if ($platforms.Count -eq 0) { throw 'manifest names no platform.' }
        foreach ($platform in $platforms) {
            $full = $platform.Value.GetProperty('full')
            foreach ($field in @('url', 'mirror')) {
                $link = $full.GetProperty($field).GetString()
                if (-not $link.StartsWith('https://', [StringComparison]::Ordinal)) { throw "$($platform.Name).full.$field is not https://: $link" }
            }
        }
    } finally { $document.Dispose() }
    return $bytes.Length
}

if (-not $Version.Trim() -or $Version -match '\s') { throw "-Version must be one token without whitespace: '$Version'" }
if ($KeyId -cnotmatch '^[A-Za-z0-9_-]+$') { throw "-KeyId may contain only letters, digits, '_' and '-': '$KeyId'" }
# Comma-separated like check.ps1 -Suite, so `pwsh -File` callers can pass several versions.
$revokedList = @($Revoked | ForEach-Object { ([string]$_) -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if (@($revokedList | Where-Object { $_ -match '\s' }).Count -gt 0) { throw '-Revoked entries must be versions without whitespace.' }
Assert-AbsoluteFile $NotesFile 'NotesFile'
if (-not [IO.Path]::IsPathFullyQualified($Out)) { throw "-Out must be an absolute path: $Out" }
if (Test-Path -LiteralPath $Out) { throw "Output already exists: $Out" }
$outDirectory = Split-Path -Parent $Out
if (-not (Test-Path -LiteralPath $outDirectory -PathType Container)) { throw "Output directory does not exist: $outDirectory" }
$windows = Test-PlatformGroup 'Windows' $WindowsZip $WindowsUrl $WindowsMirror
$android = Test-PlatformGroup 'Android' $AndroidManifest $AndroidUrl $AndroidMirror
if (-not $windows -and -not $android) { throw 'Give at least one platform: -WindowsZip/-WindowsUrl/-WindowsMirror or -AndroidManifest/-AndroidUrl/-AndroidMirror.' }

$notes = [IO.File]::ReadAllText($NotesFile, $utf8).Replace("`r`n", "`n").Trim()
if (-not $notes) { throw "-NotesFile is empty: $NotesFile" }

$platforms = [ordered]@{}
if ($windows) {
    Assert-AbsoluteFile $WindowsZip 'WindowsZip'
    if ([IO.Path]::GetExtension($WindowsZip) -ne '.zip') { throw "-WindowsZip must be the distribution .zip: $WindowsZip" }
    $zip = Get-Item -LiteralPath $WindowsZip
    $zipHash = (Get-FileHash -LiteralPath $zip.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $platforms['windows-x64'] = [ordered]@{ full = [ordered]@{ url = $WindowsUrl; mirror = $WindowsMirror; bytes = $zip.Length; sha256 = $zipHash }; patches = @() }
    Write-Output ('PLATFORM windows-x64: bytes=' + $zip.Length + ' sha256=' + $zipHash + ' (computed here from ' + $zip.FullName + ')')
}
if ($android) {
    Assert-AbsoluteFile $AndroidManifest 'AndroidManifest'
    $package = [IO.File]::ReadAllText($AndroidManifest, $utf8) | ConvertFrom-Json
    if ([string]$package.version -cne $Version) { throw "Android package manifest is version '$($package.version)', not -Version '$Version': $AndroidManifest" }
    if (-not ($package.bytes -is [long] -or $package.bytes -is [int]) -or [long]$package.bytes -le 0) { throw "Android package manifest has no positive integer bytes: $AndroidManifest" }
    if ([string]$package.sha256 -cnotmatch '^[0-9a-f]{64}$') { throw "Android package manifest has no lower-case sha256: $AndroidManifest" }
    $platforms['android'] = [ordered]@{ full = [ordered]@{ url = $AndroidUrl; mirror = $AndroidMirror; bytes = [long]$package.bytes; sha256 = [string]$package.sha256 }; patches = @() }
    Write-Output ('PLATFORM android: bytes=' + $package.bytes + ' sha256=' + $package.sha256 + ' (copied from ' + $AndroidManifest + ')')
}

$document = [ordered]@{
    schema = 1
    serial = $Serial
    issued = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
    key_id = $KeyId
    latest = [ordered]@{ version = $Version; notes_zh = $notes }
    revoked = $revokedList
    platforms = $platforms
}
# ConvertTo-Json indents with CRLF on Windows; JSON strings escape their own line breaks, so the
# replacement only touches structural whitespace.
$text = ($document | ConvertTo-Json -Depth 8).Replace("`r`n", "`n") + "`n"
$temporary = $Out + '.tmp-' + [guid]::NewGuid().ToString('N')
try {
    [IO.File]::WriteAllBytes($temporary, $utf8.GetBytes($text))
    $size = Assert-UpdateManifest $temporary
    Move-Item -LiteralPath $temporary -Destination $Out
} catch {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    throw
}
Write-Output ('UPDATE MANIFEST: ' + $Out + ' (' + $size + ' bytes, key_id=' + $KeyId + ', serial=' + $Serial + ', platforms=' + (@($platforms.Keys) -join ',') + ')')
Write-Output 'Next: tools/sign-update-manifest.ps1 -Manifest <this file> -PrivateKey <maintainer key>'
