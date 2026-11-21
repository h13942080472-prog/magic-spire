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
# Guard before signing: the public half of -PrivateKey (`openssl pkey -pubout`) must have the
# same DER sha256 as the update/update_keys.gd entry that the manifest's key_id names; otherwise
# nothing is signed, so a release can never carry a signature the game rejects. After signing,
# the written base64 is decoded and verified with that table key (`openssl dgst -verify`).
#
# Secrets: the passphrase only travels as `-passin env:<name>` (-PassphraseEnv takes the variable
# name, never the value). The script never prints, logs or stores the private key, the
# passphrase or a hash of either; its scratch directory holds public material and the signature
# only, and is removed on every exit path. An existing <manifest>.sig is never overwritten.
#
# -KeyTable points the guard at another file of the same shape. It exists for test fixtures
# signed with a one-time key; release signing uses the default, update/update_keys.gd.
$ErrorActionPreference = 'Stop'

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

# key_id -> PEM text of every triple-quoted entry in the KEYS constant. The table is read as text
# on purpose: signing needs no engine.
function Read-KeyTable {
    param([string]$Path)
    $text = [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false, $true)).Replace("`r`n", "`n")
    $start = $text.IndexOf('const KEYS=')
    if ($start -lt 0) { throw "No 'const KEYS=' in key table: $Path" }
    $table = @{}
    foreach ($match in [regex]::Matches($text.Substring($start), '(?s)"([A-Za-z0-9_-]+)"\s*:\s*"""(.*?)"""')) {
        $name = $match.Groups[1].Value
        if ($table.ContainsKey($name)) { throw "Key table names '$name' twice: $Path" }
        $table[$name] = $match.Groups[2].Value
    }
    return $table
}

if (-not [IO.Path]::IsPathFullyQualified($Manifest)) { throw "-Manifest must be an absolute path: $Manifest" }
if (-not [IO.Path]::IsPathFullyQualified($PrivateKey)) { throw '-PrivateKey must be an absolute path.' }
if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) { throw "-Manifest does not name a file: $Manifest" }
if (-not (Test-Path -LiteralPath $PrivateKey -PathType Leaf)) { throw '-PrivateKey does not name a file.' }
$signaturePath = $Manifest + '.sig'
if (Test-Path -LiteralPath $signaturePath) { throw "Signature already exists: $signaturePath" }
$passin = @()
if ($PassphraseEnv) {
    if ($PassphraseEnv -cnotmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw '-PassphraseEnv takes an environment variable name.' }
    if (-not [Environment]::GetEnvironmentVariable($PassphraseEnv)) { throw "Environment variable $PassphraseEnv is not set." }
    $passin = @('-passin', ('env:' + $PassphraseEnv))
}
if (-not $KeyTable) { $KeyTable = Join-Path (Split-Path -Parent $PSScriptRoot) 'update/update_keys.gd' }
if (-not [IO.Path]::IsPathFullyQualified($KeyTable) -or -not (Test-Path -LiteralPath $KeyTable -PathType Leaf)) { throw "-KeyTable must name an existing file by absolute path: $KeyTable" }
$script:openssl = Find-OpenSsl
Write-Output ('OPENSSL: ' + $script:openssl + ' (' + ((Invoke-OpenSsl 'version' @('version')) -join ' ') + ')')

# The manifest's own key_id selects the table entry, exactly as evaluate() does.
$document = [Text.Json.JsonDocument]::Parse([IO.File]::ReadAllText($Manifest, [Text.UTF8Encoding]::new($false, $true)), [Text.Json.JsonDocumentOptions]::new())
try {
    $keyProperty = [Text.Json.JsonElement]::new()
    if (-not $document.RootElement.TryGetProperty('key_id', [ref]$keyProperty) -or $keyProperty.ValueKind -ne [Text.Json.JsonValueKind]::String) { throw "Manifest has no string key_id: $Manifest" }
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
    [IO.File]::WriteAllText($tablePem, $table[$keyId], [Text.UTF8Encoding]::new($false))
    Invoke-OpenSsl 'pkey (table entry)' @('pkey', '-pubin', '-in', $tablePem, '-outform', 'DER', '-out', $tableDer) | Out-Null
    Invoke-OpenSsl 'pkey (public half of -PrivateKey)' (@('pkey', '-in', $PrivateKey) + $passin + @('-pubout', '-outform', 'DER', '-out', $derivedDer)) | Out-Null
    $expected = (Get-FileHash -LiteralPath $tableDer -Algorithm SHA256).Hash.ToLowerInvariant()
    if ((Get-FileHash -LiteralPath $derivedDer -Algorithm SHA256).Hash.ToLowerInvariant() -cne $expected) {
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
