#Requires -Version 7.0
param(
    [Parameter(Mandatory)][string]$Manifest,
    [Parameter(Mandatory)][string]$PrivateKey,
    [string]$PassphraseEnv = '',
    [string]$KeyTable = ''
)
# docs/spec/update-check.md「发布侧脚本」: the only signer of the update manifest. The signature
# is RSA PKCS#1 v1.5 over SHA-256 of the manifest's exact bytes (`openssl dgst -sha256 -sign`),
# written as one base64 line (`openssl base64 -A`) to <manifest>.sig -- the shape that
# update/update_manifest.gd verifies.
#
# Guards before signing: -Manifest must pass the generator's own read-back check
# (tools/update-manifest-check.ps1::Assert-UpdateManifest: at most 65536 bytes, no BOM or CR,
# strict JSON, every url/mirror https://), so a manifest edited by hand after generation is
# refused instead of signed and then silently rejected by every client; and the public half of
# -PrivateKey (`openssl pkey -pubout`) must have the same DER sha256 as the update/update_keys.gd
# entry that the manifest's key_id names, so a release can never carry a signature the game
# rejects. Otherwise nothing is signed. After signing, the written base64 is decoded and
# verified with that table key (`openssl dgst -verify`).
#
# Secrets: the passphrase only travels as `-passin env:<name>` (-PassphraseEnv takes the variable
# name, never the value). The script never prints, logs or stores the private key, the
# passphrase or a hash of either; its scratch directory holds public material and the signature
# only, and is removed on every exit path. An existing <manifest>.sig is never overwritten.
# Errors name the parameter and the value that failed, except that the script's own messages
# never echo the -PrivateKey value or the -PassphraseEnv value (malformed, or naming a variable
# that is not set): a misused parameter could carry the key or the passphrase itself. openssl
# diagnostics, passed through when a step fails, may name the key file's path; a value that is
# not an existing absolute file path never reaches openssl.
#
# Test seam (测试接缝): -KeyTable points the guard at another file of the same shape. It exists
# only so that test fixtures can be signed with a one-time key; release signing never passes it
# and uses the default, update/update_keys.gd.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'update-manifest-check.ps1')
$utf8 = [Text.UTF8Encoding]::new($false, $true)

function Find-OpenSsl {
    if ($env:OPENSSL_BIN) {
        if (Test-Path -LiteralPath $env:OPENSSL_BIN -PathType Leaf) { return $env:OPENSSL_BIN }
        throw "OPENSSL_BIN does not name a file: $env:OPENSSL_BIN"
    }
    $command = Get-Command openssl -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }
    foreach ($candidate in @((Join-Path $env:ProgramFiles 'Git\usr\bin\openssl.exe'), (Join-Path $env:ProgramFiles 'Git\mingw64\bin\openssl.exe'))) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    throw 'openssl was not found: set OPENSSL_BIN or install Git for Windows.'
}

# Native exit codes decide success; stderr alone is not a failure.
function Invoke-OpenSsl {
    param([string]$Step, [string[]]$Arguments)
    $output = @(& $script:openssl @Arguments 2>&1 | ForEach-Object { "$_" })
    if ($LASTEXITCODE -ne 0) { throw ('openssl ' + $Step + ' failed (exit ' + $LASTEXITCODE + '): ' + ($output -join ' | ')) }
    return $output
}

# -Secret keeps the value out of the message (see the header).
function Assert-AbsoluteFile {
    param([string]$Path, [string]$Name, [switch]$Secret)
    $shown = if ($Secret) { ' (value not echoed)' } else { ': ' + $Path }
    if (-not [IO.Path]::IsPathFullyQualified($Path)) { throw ('-' + $Name + ' must be an absolute path' + $shown) }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw ('-' + $Name + ' does not name a file' + $shown) }
}

function Get-Sha256Hex {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

# key_id -> PEM text of every triple-quoted entry in the KEYS constant. The table is read as text
# on purpose: signing needs no engine.
function Read-KeyTable {
    param([string]$Path)
    $text = [IO.File]::ReadAllText($Path, $utf8).Replace("`r`n", "`n")
    $start = $text.IndexOf('const KEYS=')
    if ($start -lt 0) { throw "-KeyTable has no 'const KEYS=': $Path" }
    $table = @{}
    foreach ($match in [regex]::Matches($text.Substring($start), '(?s)"([A-Za-z0-9_-]+)"\s*:\s*"""(.*?)"""')) {
        $name = $match.Groups[1].Value
        if ($table.ContainsKey($name)) { throw "-KeyTable names key_id '$name' twice: $Path" }
        $table[$name] = $match.Groups[2].Value
    }
    return $table
}

# ---- parameters ----
Assert-AbsoluteFile $Manifest 'Manifest'
Assert-AbsoluteFile $PrivateKey 'PrivateKey' -Secret
$signaturePath = $Manifest + '.sig'
if (Test-Path -LiteralPath $signaturePath) { throw "-Manifest already has a signature, which is never overwritten: $signaturePath" }
$passin = @()
if ($PassphraseEnv) {
    if ($PassphraseEnv -cnotmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw '-PassphraseEnv takes the name of an environment variable, not the passphrase (value not echoed).' }
    if (-not [Environment]::GetEnvironmentVariable($PassphraseEnv)) { throw '-PassphraseEnv names an environment variable that is not set (value not echoed).' }
    $passin = @('-passin', ('env:' + $PassphraseEnv))
}
if (-not $KeyTable) { $KeyTable = Join-Path (Split-Path -Parent $PSScriptRoot) 'update/update_keys.gd' }
Assert-AbsoluteFile $KeyTable 'KeyTable'
$script:openssl = Find-OpenSsl
Write-Output ('OPENSSL: ' + $script:openssl + ' (' + ((Invoke-OpenSsl 'version' @('version')) -join ' ') + ')')

# ---- inputs: the generator's read-back check first; then the manifest's own key_id selects the
# table entry, exactly as evaluate() does ----
try { $null = Assert-UpdateManifest $Manifest }
catch { throw ('REFUSED: -Manifest fails the update-manifest read-back check: ' + $_.Exception.GetBaseException().Message + " ($Manifest); nothing was signed.") }
try { $document = [Text.Json.JsonDocument]::Parse([IO.File]::ReadAllText($Manifest, $utf8), [Text.Json.JsonDocumentOptions]::new()) }
catch { throw "-Manifest is not strict UTF-8 JSON: $Manifest ($($_.Exception.GetBaseException().Message))" }
try {
    $keyProperty = [Text.Json.JsonElement]::new()
    if (-not $document.RootElement.TryGetProperty('key_id', [ref]$keyProperty) -or $keyProperty.ValueKind -ne [Text.Json.JsonValueKind]::String) { throw "-Manifest has no string key_id: $Manifest" }
    $keyId = $keyProperty.GetString()
} finally { $document.Dispose() }
$table = Read-KeyTable $KeyTable
if (-not $keyId -or -not $table.ContainsKey($keyId)) { throw "REFUSED: key_id '$keyId' has no entry in $KeyTable; nothing was signed." }

$scratch = Join-Path (Split-Path -Parent $Manifest) ('.sign-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($scratch) | Out-Null
try {
    $tablePem = Join-Path $scratch 'table-public.pem'
    $tableDer = Join-Path $scratch 'table-public.der'
    $derivedDer = Join-Path $scratch 'derived-public.der'
    $raw = Join-Path $scratch 'signature.bin'
    $encoded = Join-Path $scratch 'signature.b64'
    $decoded = Join-Path $scratch 'signature-check.bin'
    [IO.File]::WriteAllText($tablePem, $table[$keyId], $utf8)
    Invoke-OpenSsl 'pkey (table entry)' @('pkey', '-pubin', '-in', $tablePem, '-outform', 'DER', '-out', $tableDer) | Out-Null
    Invoke-OpenSsl 'pkey (public half of -PrivateKey)' (@('pkey', '-in', $PrivateKey) + $passin + @('-pubout', '-outform', 'DER', '-out', $derivedDer)) | Out-Null
    $expected = Get-Sha256Hex $tableDer
    if ((Get-Sha256Hex $derivedDer) -cne $expected) {
        throw "REFUSED: -PrivateKey does not match key table entry '$keyId' (table DER sha256 $expected); nothing was signed."
    }
    Write-Output ("KEY MATCH: key_id=$keyId table DER sha256=$expected")
    Invoke-OpenSsl 'dgst -sign' (@('dgst', '-sha256', '-sign', $PrivateKey) + $passin + @('-out', $raw, $Manifest)) | Out-Null
    Invoke-OpenSsl 'base64 -A' @('base64', '-A', '-in', $raw, '-out', $encoded) | Out-Null
    $line = [IO.File]::ReadAllText($encoded, [Text.Encoding]::ASCII)
    if ($line -cnotmatch '^[A-Za-z0-9+/]+={0,2}$') { throw 'openssl base64 -A did not produce one base64 line.' }
    Invoke-OpenSsl 'base64 -d' @('base64', '-d', '-A', '-in', $encoded, '-out', $decoded) | Out-Null
    $verdict = Invoke-OpenSsl 'dgst -verify' @('dgst', '-sha256', '-verify', $tablePem, '-signature', $decoded, $Manifest)
    if (($verdict -join "`n") -notmatch 'Verified OK') { throw ('Signature verification did not report Verified OK: ' + ($verdict -join ' | ')) }
    Move-Item -LiteralPath $encoded -Destination $signaturePath
    Write-Output ('VERIFY: ' + ($verdict -join ' ') + " (key table entry '$keyId')")
    Write-Output ('SIGNATURE: ' + $signaturePath + ' (' + $line.Length + ' base64 characters, ' + (Get-Item -LiteralPath $raw).Length + '-byte RSA block)')
} finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
