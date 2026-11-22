#Requires -Version 7.0
param(
    [Parameter(Mandatory)][string]$Version,
    [Parameter(Mandatory)][string]$NotesFile,
    # Untyped on purpose: an [int] parameter rounds 1.5 (or '1.5') to 2 while binding, before any
    # check can see the value. The parameter checks below accept whole numbers only.
    [Parameter(Mandatory)][object]$Serial,
    [string]$KeyId = 'k1',
    # Untyped on purpose, like -Serial: a bare list such as 0.20,0.19.5 is built before binding, so
    # 0.20 arrives as the number 0.2 and a [string[]] parameter would write "0.2". The parameter
    # checks below refuse every element that is not a string.
    [object]$Revoked = @(),
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
# and checked by tools/update-manifest-check.ps1::Assert-UpdateManifest (strict JSON, at most
# 65536 bytes, every url/mirror starting with https://; the signer runs the same check before it
# signs); any failure throws and leaves no output file behind. An existing -Out is never
# overwritten. The closing UPDATE MANIFEST line echoes version, revoked, key_id, serial and the
# platforms as written, for the maintainer to check before signing.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'update-manifest-check.ps1')
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

# ---- parameters: nothing is read yet ----
if (-not $Version.Trim() -or $Version -match '\s') { throw "-Version must be one token without whitespace: '$Version'" }
# \z, not $: in .NET `$` also matches before a final line feed, so 'k1\n' would pass and the
# signer would refuse the manifest only after it had been written.
if ($KeyId -cnotmatch '^[A-Za-z0-9_-]+\z') { throw "-KeyId may contain only letters, digits, '_' and '-': '$KeyId'" }
# -Serial is an integer or a string of decimal digits from 1 to 2147483647; 1.5, '1.5', '1e3',
# ' 7' and $true are refused, never rounded or coerced.
$serialNumber = 0
$serialText = if ($Serial -is [int] -or $Serial -is [long]) { [string]$Serial } elseif ($Serial -is [string]) { $Serial } else { '' }
if (-not [int]::TryParse($serialText, [Globalization.NumberStyles]::None, [Globalization.CultureInfo]::InvariantCulture, [ref]$serialNumber) -or $serialNumber -lt 1) { throw "-Serial must be a whole number from 1 to 2147483647: '$Serial'" }
# -Revoked: every element must arrive as a string. A non-string element is refused, never
# converted: the text of a bare 0.20 is gone by the time this script sees the number 0.2.
$unquoted = @(foreach ($entry in @($Revoked)) { if ($entry -isnot [string]) { if ($null -eq $entry) { '$null' } else { [string]$entry + ' [' + $entry.GetType().Name + ']' } } })
if ($unquoted.Count -gt 0) { throw ("-Revoked entries must be strings; quote every version (-Revoked '0.20','0.19.5' or -Revoked '0.20,0.19.5'). PowerShell bound these bare values as non-strings: " + ($unquoted -join ', ')) }
# Comma-separated like check.ps1 -Suite, so `pwsh -File` callers can pass several versions.
$revokedList = @(@($Revoked) | ForEach-Object { ([string]$_) -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
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
    # \z, not $: in .NET `$` also matches before a final line feed, so '<64 hex>\n' would pass.
    if ([string]$package.sha256 -cnotmatch '^[0-9a-f]{64}\z') { throw "-AndroidManifest sha256 must be 64 lower-case hex digits, not '$($package.sha256)': $AndroidManifest" }
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
    serial = $serialNumber
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
    $size = Assert-UpdateManifest $temporary -ParameterPrefix $parameterPrefix
    Move-Item -LiteralPath $temporary -Destination $Out
} catch {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    throw
}
Write-Output ('UPDATE MANIFEST: ' + $Out + ' (' + $size + ' bytes, version=' + $Version + ', revoked=' + (ConvertTo-Json -Compress -InputObject @($revokedList)) + ', key_id=' + $KeyId + ', serial=' + $serialNumber + ', platforms=' + (@($platforms.Keys) -join ',') + ')')
Write-Output 'Next: tools/sign-update-manifest.ps1 -Manifest <this file> -PrivateKey <maintainer key>'
