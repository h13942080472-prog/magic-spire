param([Parameter(Mandatory)][string]$Directory,[switch]$ChargeAll,[switch]$WitchBalance)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'find-godot.ps1')
$releaseDirectory=(Resolve-Path -LiteralPath $Directory).Path
$gameDirectory=Split-Path -Parent $PSScriptRoot
$checkDirectory=Join-Path $gameDirectory ('build/package-check-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff'))
[IO.Directory]::CreateDirectory($checkDirectory) | Out-Null
$manifest=Get-Content -LiteralPath (Join-Path $releaseDirectory 'manifest.json') -Raw | ConvertFrom-Json
foreach ($entry in $manifest.files) {
    $filePath=[IO.Path]::GetFullPath((Join-Path $releaseDirectory $entry.path))
    if (-not $filePath.StartsWith($releaseDirectory + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Manifest path leaves package directory.' }
    if ((Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash -ine $entry.sha256) { throw ('Package checksum mismatch: '+$entry.path) }
}
function Invoke-PackageCheck {
    param([string]$Executable,[string[]]$Arguments,[string]$Name,[string]$Expected='')
    $log=Join-Path $checkDirectory ($Name+'.log')
    $start=[Diagnostics.ProcessStartInfo]::new()
    $start.FileName=$Executable
    $start.WorkingDirectory=$releaseDirectory
    $start.UseShellExecute=$false
    $start.CreateNoWindow=$true
    $start.Environment['APPDATA']=Join-Path $checkDirectory 'appdata'
    $start.Environment['SPIRE_PROBE_SAVES']=Join-Path $checkDirectory 'saves'
    $start.Environment['SPIRE_PROBE_CONTENT']=Join-Path $releaseDirectory 'content/packs'
    $start.Environment['SPIRE_PROBE_VERSION']=[string]$manifest.version
    if ($ChargeAll) { $start.Environment['SPIRE_PROBE_CHARGE_ALL']='1' }
    if ($WitchBalance) { $start.Environment['SPIRE_PROBE_WITCH_BALANCE']='1' }
    foreach ($argument in (@('--log-file',$log)+$Arguments)) { $start.ArgumentList.Add($argument) }
    $process=[Diagnostics.Process]::Start($start)
    try {
        if (-not $process.WaitForExit(60000)) { $process.Kill(); $process.WaitForExit(); throw ('Package check timed out: '+$Name) }
        if (-not (Test-Path -LiteralPath $log)) { throw ('Package check produced no log: '+$Name) }
        $output=Get-Content -LiteralPath $log -Raw
        if ($process.ExitCode -ne 0 -or $output -match '(?m)^\s*(?:USER )?(?:SCRIPT |PARSE )?ERROR:' -or ($Expected -and $output -notmatch $Expected)) { throw ('Package check failed: '+$log) }
    } finally { $process.Dispose() }
}
Invoke-PackageCheck -Executable (Find-SpireGodot) -Name 'pck' -Expected '(?m)^RELEASE PROBE PASS$' -Arguments @('--headless','--path',$releaseDirectory,'--main-pack',(Join-Path $releaseDirectory '紧缚尖塔.pck'),'--script',(Join-Path $PSScriptRoot 'release_probe.gd'))
Invoke-PackageCheck -Executable (Join-Path $releaseDirectory '紧缚尖塔.exe') -Name 'native' -Expected 'Godot Engine' -Arguments @('--headless','--quit-after','120')
Write-Output ('PACKAGE CHECK PASS: '+$releaseDirectory)
Write-Output ('PACKAGE CHECK LOGS: '+$checkDirectory)
