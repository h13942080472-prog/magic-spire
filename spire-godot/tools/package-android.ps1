param([string]$BuildId, [string]$SigningConfig = 'G:\CodexData\keys\spire-android\signing.json')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'find-godot.ps1')
. (Join-Path $PSScriptRoot 'assert-packs-root.ps1')
$gameDirectory = Split-Path -Parent $PSScriptRoot
# The APK carries content/packs in its assets and reads them through res://, so this export needs
# the development value; a flip to "adjacent" would leave the installed game without content.
Assert-SpirePacksRoot -GameDirectory $gameDirectory -Expected 'res://content/packs'
$projectText = Get-Content -LiteralPath (Join-Path $gameDirectory 'project.godot') -Raw
$versionMatch = [regex]::Match($projectText, '(?m)^config/version="([0-9]+\.[0-9]+(?:\.[0-9]+)?(?:\.fix)?)"')
if (-not $versionMatch.Success) { throw 'Project version is missing or invalid.' }
$packageVersion = $versionMatch.Groups[1].Value
if (-not $BuildId) { $BuildId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmss') }
if ($BuildId -notmatch '^[A-Za-z0-9_-]+$') { throw 'Invalid BuildId.' }
$destination = Join-Path (Split-Path -Parent $gameDirectory) ('outputs/spire-v' + $packageVersion + '-android-' + $BuildId)
if (Test-Path -LiteralPath $destination) { throw 'Output directory already exists.' }
[IO.Directory]::CreateDirectory($destination) | Out-Null
$logDirectory = Join-Path $gameDirectory ('build/android-' + $BuildId)
[IO.Directory]::CreateDirectory($logDirectory) | Out-Null
$engine = Find-SpireGodot -Console
$apk = Join-Path $destination ('spire-v' + $packageVersion + '.apk')
$sdk = Join-Path $gameDirectory 'build/android-tools/sdk'
$jdk = (Get-ChildItem (Join-Path $gameDirectory 'build/android-tools/jdk17') -Directory | Select-Object -First 1).FullName
$signing = Get-Content -LiteralPath $SigningConfig -Raw | ConvertFrom-Json
function Get-SourceFingerprint {
    @('core','data','ui','assets','content/packs','project.godot','main.tscn','export_presets.cfg') | ForEach-Object {
        Get-ChildItem -LiteralPath (Join-Path $gameDirectory $_) -File -Recurse
    } | Where-Object { $_.Extension -notin @('.uid','.import') } | Sort-Object FullName | ForEach-Object {
        [ordered]@{ path = [IO.Path]::GetRelativePath($gameDirectory,$_.FullName); sha256 = (Get-FileHash -LiteralPath $_.FullName).Hash }
    } | ConvertTo-Json -Compress
}
$before = Get-SourceFingerprint
$oldJava = $env:JAVA_HOME
try {
    $env:JAVA_HOME = $jdk
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $signing.path
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $signing.alias
    $secret = ConvertTo-SecureString $signing.protectedPassword
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = [Net.NetworkCredential]::new('', $secret).Password
    & $engine --headless --path $gameDirectory --log-file (Join-Path $logDirectory 'export.log') --export-release ('Android v' + $packageVersion) $apk *> (Join-Path $logDirectory 'export-console.log')
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $apk)) { throw "Android export failed: $logDirectory" }
    if ((Get-Content (Join-Path $logDirectory 'export.log') -Raw) -match '(?m)^\s*(?:USER )?(?:SCRIPT |PARSE )?ERROR:') { throw "Export engine errors: $logDirectory" }
    $unsigned = Join-Path $logDirectory 'unsigned.apk'
    & python (Join-Path $PSScriptRoot 'fix_android_manifest.py') $apk $unsigned
    if ($LASTEXITCODE -ne 0) { throw 'Android manifest repair failed.' }
    & "$sdk/build-tools/35.0.1/zipalign.exe" -f -P 16 4 $unsigned $apk
    if ($LASTEXITCODE -ne 0) { throw 'Repaired APK alignment failed.' }
    & "$sdk/build-tools/35.0.1/apksigner.bat" sign --ks $signing.path --ks-key-alias $signing.alias --ks-pass env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD --key-pass env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD $apk *> (Join-Path $logDirectory 'signing.txt')
    if ($LASTEXITCODE -ne 0) { throw 'Repaired APK signing failed.' }
    & "$sdk/build-tools/35.0.1/apksigner.bat" verify --verbose --print-certs $apk *> (Join-Path $logDirectory 'signature.txt')
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    & "$sdk/build-tools/35.0.1/aapt.exe" dump badging $apk *> (Join-Path $logDirectory 'manifest.txt')
    if ($LASTEXITCODE -ne 0) { throw 'APK manifest verification failed.' }
    & "$sdk/build-tools/35.0.1/aapt.exe" dump xmltree $apk AndroidManifest.xml *> (Join-Path $logDirectory 'manifest-xml.txt')
    if ($LASTEXITCODE -ne 0) { throw 'APK binary manifest could not be decoded.' }
    $xml = Get-Content (Join-Path $logDirectory 'manifest-xml.txt') -Raw
    $authorities = [regex]::Matches($xml, 'android:authorities\([^)]*\)="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
    if (@($authorities).Count -ne @($authorities | Select-Object -Unique).Count -or $xml -notmatch 'android.intent.category.LAUNCHER' -or $xml -notmatch 'android.intent.action.MAIN') { throw 'Invalid Android providers or launcher.' }
    & "$sdk/build-tools/35.0.1/zipalign.exe" -c -P 16 -v 4 $apk *> (Join-Path $logDirectory 'alignment.txt')
    if ($LASTEXITCODE -ne 0) { throw 'APK alignment verification failed.' }
} finally {
    $env:JAVA_HOME = $oldJava
    foreach ($name in @('GODOT_ANDROID_KEYSTORE_RELEASE_PATH','GODOT_ANDROID_KEYSTORE_RELEASE_USER','GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD')) {
        Remove-Item ('Env:' + $name) -ErrorAction SilentlyContinue
    }
}
if ($before -cne (Get-SourceFingerprint)) { throw 'Runtime files changed during export. Rebuild before distributing.' }
$before | Set-Content (Join-Path $logDirectory 'source-manifest.json') -Encoding utf8
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($apk)
try {
    $names = @($archive.Entries.FullName)
    foreach ($file in Get-ChildItem (Join-Path $gameDirectory 'content/packs') -Filter '*.json' -File -Recurse) {
        $entryName = 'assets/' + [IO.Path]::GetRelativePath($gameDirectory,$file.FullName).Replace('\','/')
        $entry = $archive.GetEntry($entryName)
        if ($null -eq $entry) { throw "Missing embedded content: $entryName" }
        $stream = $entry.Open()
        $hash = [Security.Cryptography.SHA256]::Create()
        try { $actual = [Convert]::ToHexString($hash.ComputeHash($stream)) } finally { $stream.Dispose(); $hash.Dispose() }
        if ($actual -ne (Get-FileHash -LiteralPath $file.FullName).Hash) { throw "Embedded content mismatch: $entryName" }
    }
    if ($names | Where-Object { $_ -match '^assets/(tests|tools|build|content/templates)/|(^|/)(saves|signing\.json|release\.keystore)(/|$)' }) { throw 'APK contains development files, content templates or saved user data.' }
    $names | Set-Content (Join-Path $logDirectory 'apk-files.txt') -Encoding utf8
} finally { $archive.Dispose() }
$manifest = [ordered]@{ version = $packageVersion; platform = 'Android ARM64 + ARMv7'; package = 'org.magic.spire'; build = $BuildId; file = [IO.Path]::GetFileName($apk); bytes = (Get-Item -LiteralPath $apk).Length; sha256 = (Get-FileHash -LiteralPath $apk).Hash.ToLowerInvariant() }
$manifest | ConvertTo-Json | Set-Content (Join-Path $destination 'manifest.json') -Encoding utf8
& (Join-Path $PSScriptRoot 'copy-release-documents.ps1') -GameDirectory $gameDirectory -Destination $destination
Write-Output ('ANDROID APK: ' + $apk)
Write-Output ('VERIFICATION: ' + $logDirectory)
