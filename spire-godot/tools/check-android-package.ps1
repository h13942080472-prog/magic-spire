param([Parameter(Mandatory)][string]$Apk)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'find-godot.ps1')
$gameDirectory = Split-Path -Parent $PSScriptRoot
$apkPath = (Resolve-Path -LiteralPath $Apk).Path
$manifest = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $apkPath) 'manifest.json') -Raw | ConvertFrom-Json
if ((Get-FileHash -LiteralPath $apkPath).Hash -ine $manifest.sha256) { throw 'APK checksum does not match its manifest.' }
$directory = Join-Path $gameDirectory ('build/android-probe-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff'))
[IO.Directory]::CreateDirectory($directory) | Out-Null
# Read APK assets unchanged through Godot's ZIP resource loader on the host.
# This checks the packaged game; it is not an Android device launch test.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$source = [IO.Compression.ZipFile]::OpenRead($apkPath)
$resourceZip = Join-Path $directory 'resources.zip'
$target = [IO.Compression.ZipFile]::Open($resourceZip,[IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($entry in $source.Entries) {
        if (-not $entry.FullName.StartsWith('assets/') -or $entry.FullName.EndsWith('/')) { continue }
        $copy = $target.CreateEntry($entry.FullName.Substring(7),[IO.Compression.CompressionLevel]::Fastest)
        $inputStream = $entry.Open(); $outputStream = $copy.Open()
        try { $inputStream.CopyTo($outputStream) } finally { $inputStream.Dispose(); $outputStream.Dispose() }
    }
} finally { $source.Dispose(); $target.Dispose() }
$log = Join-Path $directory 'probe.log'
$start = [Diagnostics.ProcessStartInfo]::new()
$start.FileName = Find-SpireGodot -Console
$start.WorkingDirectory = $directory
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.Environment['APPDATA'] = Join-Path $directory 'appdata'
$start.Environment['SPIRE_PROBE_SAVES'] = Join-Path $directory 'saves'
$start.Environment['SPIRE_PROBE_CONTENT'] = 'res://content/packs'
$start.Environment['SPIRE_PROBE_VERSION'] = [string]$manifest.version
foreach ($arg in @('--headless','--path',$directory,'--main-pack',$resourceZip,'--script',(Join-Path $PSScriptRoot 'release_probe.gd'),'--log-file',$log)) { $start.ArgumentList.Add($arg) }
$process = [Diagnostics.Process]::Start($start)
try {
    if (-not $process.WaitForExit(60000)) { $process.Kill(); $process.WaitForExit(); throw 'APK resource probe timed out.' }
    $output = Get-Content -LiteralPath $log -Raw
    if ($process.ExitCode -ne 0 -or $output -match '(?m)^\s*(?:USER )?(?:SCRIPT |PARSE )?ERROR:' -or $output -notmatch '(?m)^RELEASE PROBE PASS$') { throw "APK resource probe failed: $log" }
} finally { $process.Dispose() }
Write-Output ('APK RESOURCE PROBE PASS: ' + $log)
