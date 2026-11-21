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
#    pipeline step hashes it; this script is the one place that does (Get-FileHash, once). The
#    sha256 it writes into the manifest is the value every manual release step quotes
#    (docs/spec/packaging.md); nobody hashes the ZIP a second time.
#
# Order: every parameter is checked before any input is read, and every input is read and
# checked before the ZIP is hashed, so a bad argument never costs a full ZIP hash. Errors name
# the parameter and the value that failed.
#
# The manifest is written as UTF-8 without BOM with LF line ends to a temporary file, read back
# and checked (strict JSON, at most 65536 bytes, every url/mirror starting with https://); any
# failure throws and leaves no output file behind. An existing -Out is never overwritten.
$ErrorActionPreference = 'Stop'
$maximumBytes = 65536
$utf8 = [Text.UTF8Encoding]::new($false, $true)
# Manifest platform key -> parameter prefix (-<prefix>Url, -<prefix>Mirror).
$parameterPrefix = @{ 'windows-x64' = 'Windows'; 'android' = 'Android' }

function Assert-AbsolutePath {
    param([string]$Path, [string]$Name)
    if (-not [IO.Path]::IsPathFullyQualified($Path)) { throw "-$Name must be an absolute path: $Path" }
}

function Assert-AbsoluteFile {
    param([string]$Path, [string]$Name)
    Assert-AbsolutePath $Path $Name
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "-$Name does not name a file: $Path" }
}

function Read-Utf8Text {
    param([string]$Path, [string]$Name)
    try { return [IO.File]::ReadAllText($Path, $utf8) }
    catch [Text.DecoderFallbackException] { throw "-$Name is not valid UTF-8: $Path ($($_.Exception.GetBaseException().Message))" }
}

# One platform is either fully described (artifact, url, mirror) or absent.
function Test-PlatformGroup {
    param([Collections.Specialized.OrderedDictionary]$Group)
    $missing = @($Group.Keys | Where-Object { -not $Group[$_] })
    if ($missing.Count -eq $Group.Count) { return $false }
    if ($missing.Count -gt 0) { throw ('-' + (@($Group.Keys) -join ', -') + ' go together; missing: -' + ($missing -join ', -')) }
    return $true
}

# The one place a platform entry is built; the PLATFORM line names where bytes/sha256 came from.
function Add-Platform {
    param([string]$Key, [string]$Url, [string]$Mirror, [long]$Bytes, [string]$Sha256, [string]$Source)
    $script:platforms[$Key] = [ordered]@{ full = [ordered]@{ url = $Url; mirror = $Mirror; bytes = $Bytes; sha256 = $Sha256 }; patches = @() }
    Write-Output ('PLATFORM ' + $Key + ': bytes=' + $Bytes + ' sha256=' + $Sha256 + ' (' + $Source + ')')
}

# The read-back check of the written bytes; the generator's only validation of url/mirror and size.
function Assert-UpdateManifest {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -eq 0 -or $bytes.Length -gt $maximumBytes) { throw "manifest is $($bytes.Length) bytes; the limit is $maximumBytes (-NotesFile is the free-length input)." }
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
                $parameter = '-' + $parameterPrefix[$platform.Name] + $(if ($field -eq 'url') { 'Url' } else { 'Mirror' })
                if (-not $link.StartsWith('https://', [StringComparison]::Ordinal)) { throw "$parameter is not https:// ($($platform.Name).full.$field): $link" }
            }
        }
    } finally { $document.Dispose() }
    return $bytes.Length
}

# ---- parameters: nothing is read yet ----
if (-not $Version.Trim() -or $Version -match '\s') { throw "-Version must be one token without whitespace: '$Version'" }
if ($KeyId -cnotmatch '^[A-Za-z0-9_-]+$') { throw "-KeyId may contain only letters, digits, '_' and '-': '$KeyId'" }
# Comma-separated like check.ps1 -Suite, so `pwsh -File` callers can pass several versions.
$revokedList = @($Revoked | ForEach-Object { ([string]$_) -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$spaced = @($revokedList | Where-Object { $_ -match '\s' })
if ($spaced.Count -gt 0) { throw ("-Revoked entries must be versions without whitespace: '" + ($spaced -join "', '") + "'") }
Assert-AbsoluteFile $NotesFile 'NotesFile'
Assert-AbsolutePath $Out 'Out'
if (Test-Path -LiteralPath $Out) { throw "-Out already exists and is never overwritten: $Out" }
$outDirectory = Split-Path -Parent $Out
if (-not (Test-Path -LiteralPath $outDirectory -PathType Container)) { throw "-Out names a directory that does not exist: $outDirectory" }
$windows = Test-PlatformGroup ([ordered]@{ WindowsZip = $WindowsZip; WindowsUrl = $WindowsUrl; WindowsMirror = $WindowsMirror })
$android = Test-PlatformGroup ([ordered]@{ AndroidManifest = $AndroidManifest; AndroidUrl = $AndroidUrl; AndroidMirror = $AndroidMirror })
if (-not $windows -and -not $android) { throw 'Give at least one platform: -WindowsZip/-WindowsUrl/-WindowsMirror or -AndroidManifest/-AndroidUrl/-AndroidMirror.' }
if ($windows) {
    Assert-AbsoluteFile $WindowsZip 'WindowsZip'
    if ([IO.Path]::GetExtension($WindowsZip) -ne '.zip') { throw "-WindowsZip must be the distribution .zip: $WindowsZip" }
}
if ($android) { Assert-AbsoluteFile $AndroidManifest 'AndroidManifest' }

# ---- inputs: read and checked before the ZIP is hashed ----
$notes = (Read-Utf8Text $NotesFile 'NotesFile').Replace("`r`n", "`n").Trim()
if (-not $notes) { throw "-NotesFile is empty: $NotesFile" }
if ($android) {
    $packageText = Read-Utf8Text $AndroidManifest 'AndroidManifest'
    try { $package = $packageText | ConvertFrom-Json } catch { throw "-AndroidManifest is not JSON: $AndroidManifest ($($_.Exception.GetBaseException().Message))" }
    if ([string]$package.version -cne $Version) { throw "-AndroidManifest is version '$($package.version)', not -Version '$Version': $AndroidManifest" }
    if (-not ($package.bytes -is [long] -or $package.bytes -is [int]) -or [long]$package.bytes -le 0) { throw "-AndroidManifest bytes must be a positive integer, not '$($package.bytes)': $AndroidManifest" }
    if ([string]$package.sha256 -cnotmatch '^[0-9a-f]{64}$') { throw "-AndroidManifest sha256 must be 64 lower-case hex digits, not '$($package.sha256)': $AndroidManifest" }
}

# ---- platforms, in manifest order ----
$platforms = [ordered]@{}
if ($windows) {
    $zip = Get-Item -LiteralPath $WindowsZip
    Add-Platform 'windows-x64' $WindowsUrl $WindowsMirror $zip.Length (Get-FileHash -LiteralPath $zip.FullName -Algorithm SHA256).Hash.ToLowerInvariant() ('computed here from ' + $zip.FullName)
}
if ($android) { Add-Platform 'android' $AndroidUrl $AndroidMirror ([long]$package.bytes) ([string]$package.sha256) ('copied from ' + $AndroidManifest) }

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
