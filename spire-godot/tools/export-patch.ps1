#Requires -Version 7.0
param(
    # The baseline release package directory written by tools/package.ps1 (main .pck + manifest.json).
    [Parameter(Mandatory)][string]$BasePackage,
    [Parameter(Mandatory)][string]$BaseVersion,
    # The output directory; it appears only when everything succeeded and must not exist yet.
    [Parameter(Mandatory)][string]$Out,
    # Judge only: print the verdict, start no engine, write nothing.
    [switch]$CheckOnly,
    [string]$ProjectRoot = '',
    # Where the baseline sources come from: the git objects of this ref (default v<BaseVersion>).
    [string]$BaseRef = '',
    # Test seam: a directory that already holds the baseline sources; replaces the git fetch.
    [string]$BaseSourceDirectory = '',
    # Test seam: the engine identity, instead of asking the engine (-CheckOnly then needs no engine).
    [string]$EngineVersion = ''
)
# docs/spec/update-check.md「发布侧脚本」: the only generator of a patch pack. A patch is cumulative
# against the baseline release package (it carries every change since the baseline), so the
# baseline package must be archived outside the repository for as long as its patches are published.
#
# Order: arguments -> feasibility judgement (tools/export-patch-feasibility.ps1; a refusal prints
# `PATCH REFUSED: <gate>: <detail>` and exits 1) -> engine export into a staging directory -> hash
# (the one place a patch is hashed) -> staging moves to -Out. Any failure leaves no -Out and no
# staging directory behind.
#
# Baseline sources are read from the git objects of -BaseRef (default tag v<BaseVersion>), never from
# the working tree: the source is determined by a ref, and a ref that cannot be resolved is a
# refusal, not a pass.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'export-patch-feasibility.ps1')
$gameDirectory = if ($ProjectRoot) { $ProjectRoot } else { Split-Path -Parent $PSScriptRoot }
$versionPattern = '^[0-9]+\.[0-9]+(?:\.[0-9]+)?(?:\.fix)?\z'

foreach ($pair in @(@('BasePackage', $BasePackage), @('Out', $Out), @('ProjectRoot', $gameDirectory))) {
    if (-not [IO.Path]::IsPathFullyQualified($pair[1])) { throw "-$($pair[0]) must be an absolute path: $($pair[1])" }
}
if ($BaseSourceDirectory -and -not [IO.Path]::IsPathFullyQualified($BaseSourceDirectory)) { throw "-BaseSourceDirectory must be an absolute path: $BaseSourceDirectory" }
if ($BaseVersion -cnotmatch $versionPattern) { throw "-BaseVersion is not a release version: '$BaseVersion'" }
if (-not (Test-Path -LiteralPath $BasePackage -PathType Container)) { throw "-BasePackage does not name a directory: $BasePackage" }
if (Test-Path -LiteralPath $Out) { throw "-Out already exists and is never overwritten: $Out" }
$outParent = Split-Path -Parent $Out
if (-not (Test-Path -LiteralPath $outParent -PathType Container)) { throw "-Out names a directory that does not exist: $outParent" }
$projectPath = Join-Path $gameDirectory 'project.godot'
if (-not (Test-Path -LiteralPath $projectPath -PathType Leaf)) { throw "no project.godot in -ProjectRoot: $gameDirectory" }
$targetMatch = [regex]::Match((Read-PatchText $projectPath), '(?m)^config/version="([0-9]+\.[0-9]+(?:\.[0-9]+)?(?:\.fix)?)"')
if (-not $targetMatch.Success) { throw 'Project version is missing or invalid.' }
$targetVersion = $targetMatch.Groups[1].Value
if ($targetVersion -ceq $BaseVersion) { throw "the project is still at -BaseVersion $BaseVersion; a patch needs a newer target version" }

# ---- baseline sources: one place that fetches them ----
function Get-GitBlob {
    param([string]$Repository, [string]$Spec, [string]$Destination)
    $start = [Diagnostics.ProcessStartInfo]::new('git')
    foreach ($argument in @('-C', $Repository, 'show', $Spec)) { $start.ArgumentList.Add($argument) }
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.UseShellExecute = $false
    $process = [Diagnostics.Process]::Start($start)
    $errors = $process.StandardError.ReadToEndAsync()
    $stream = [IO.File]::Create($Destination)
    try { $process.StandardOutput.BaseStream.CopyTo($stream) } finally { $stream.Dispose() }
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { Remove-Item -LiteralPath $Destination -Force; return $false }
    return $true
}

$sourceRoot = $BaseSourceDirectory
$temporarySources = ''
if (-not $sourceRoot) {
    $ref = if ($BaseRef) { $BaseRef } else { 'v' + $BaseVersion }
    $top = (& git -C $gameDirectory rev-parse --show-toplevel 2>$null | Select-Object -First 1)
    $prefix = (& git -C $gameDirectory rev-parse --show-prefix 2>$null | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0 -or -not $top) { throw "-ProjectRoot is not inside a git work tree, so the baseline sources cannot be fetched: $gameDirectory" }
    $temporarySources = Join-Path ([IO.Path]::GetTempPath()) ('export-patch-base-' + [guid]::NewGuid().ToString('N'))
    $sourceRoot = $temporarySources
    foreach ($path in @('project.godot', 'export_presets.cfg') + $script:PatchBootClosure) {
        $destination = Join-Path $sourceRoot $path
        [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
        # A blob that is not there simply leaves no file; Test-PatchFeasibility turns that into a refusal.
        [void](Get-GitBlob $top ($ref + ':' + $prefix + $path) $destination)
    }
}

$staging = ''
try {
    $engine = ''
    if (-not $EngineVersion) {
        . (Join-Path $PSScriptRoot 'find-godot.ps1')
        $engine = Find-SpireGodot -Console
        $EngineVersion = (& $engine --version | Out-String).Trim()
    }
    $refusals = @(Test-PatchFeasibility $BasePackage $BaseVersion $sourceRoot $gameDirectory $targetVersion $EngineVersion)
    if ($refusals.Count -gt 0) {
        foreach ($refusal in $refusals) { Write-Output ('PATCH REFUSED: ' + $refusal.Gate + ': ' + $refusal.Detail) }
        Write-Output "PATCH NOT EXPORTED: $($refusals.Count) judgement(s) refused $BaseVersion -> $targetVersion; a client on that baseline gets the full package"
        exit 1
    }
    if ($CheckOnly) {
        Write-Output "PATCH FEASIBLE: $BaseVersion -> $targetVersion (judged only; nothing was exported)"
        exit 0
    }

    # ---- export ----
    if (-not $engine) { . (Join-Path $PSScriptRoot 'find-godot.ps1'); $engine = Find-SpireGodot -Console }
    $basePck = (Get-ChildItem -LiteralPath $BasePackage -File -Filter '*.pck' | Select-Object -First 1).FullName
    # The Windows preset is found by platform, not by its version-bearing name: a version bump renames it.
    $presetText = Read-PatchText (Join-Path $gameDirectory 'export_presets.cfg')
    $presets = @([regex]::Matches($presetText, '(?ms)^\[preset\.\d+\]\s*\n(.*?)(?=^\[|\z)') | Where-Object { $_.Groups[1].Value -match '(?m)^platform="Windows Desktop"\s*$' })
    if ($presets.Count -ne 1) { throw "export_presets.cfg must hold exactly one Windows Desktop preset, found $($presets.Count)" }
    $presetName = [regex]::Match($presets[0].Groups[1].Value, '(?m)^name="([^"]+)"\s*$').Groups[1].Value
    if (-not $presetName) { throw 'the Windows Desktop preset has no name' }
    $staging = $Out + '.tmp-' + [guid]::NewGuid().ToString('N')
    [IO.Directory]::CreateDirectory($staging) | Out-Null
    $logDirectory = Join-Path $gameDirectory ('build/export-patch-' + [guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($logDirectory) | Out-Null
    $exportLog = Join-Path $logDirectory 'export.log'
    $name = "patch-$BaseVersion-$targetVersion"
    $pack = Join-Path $staging ($name + '.pck')
    Write-Output ('EXPORT: ' + $presetName + ' against ' + $basePck)
    & $engine --headless --path $gameDirectory --log-file $exportLog --export-patch $presetName $pack --patches $basePck *> (Join-Path $logDirectory 'export-console.log')
    $exportExit = $LASTEXITCODE
    if ($exportExit -ne 0 -or -not (Test-Path -LiteralPath $pack -PathType Leaf) -or (Get-Item -LiteralPath $pack).Length -le 0 -or (Get-Content -LiteralPath $exportLog -Raw) -match '(?m)^\s*(?:USER )?(?:SCRIPT |PARSE )?ERROR:') {
        throw "Patch export failed (exit=$exportExit): $exportLog"
    }
    # The one hash of the pack in the whole pipeline: tools/update-manifest.ps1 copies it from here.
    $info = Get-Item -LiteralPath $pack
    $meta = [ordered]@{ from = $BaseVersion; to = $targetVersion; bytes = $info.Length; sha256 = (Get-FileHash -LiteralPath $pack -Algorithm SHA256).Hash.ToLowerInvariant() }
    $metaText = ($meta | ConvertTo-Json).Replace("`r`n", "`n") + "`n"
    [IO.File]::WriteAllBytes((Join-Path $staging ($name + '.json')), [Text.UTF8Encoding]::new($false).GetBytes($metaText))
    Move-Item -LiteralPath $staging -Destination $Out
    $staging = ''
    Write-Output ('PATCH EXPORT: ' + $Out + ' (' + $name + '.pck bytes=' + $meta.bytes + ' sha256=' + $meta.sha256 + ')')
    Write-Output 'Next: verify the patch on a package (docs/spec/packaging.md), then tools/update-manifest.ps1 -WindowsPatchMeta <this json>.'
} catch {
    Write-Output ('PATCH EXPORT FAILED: ' + $_.Exception.Message)
    exit 1
} finally {
    if ($staging -and (Test-Path -LiteralPath $staging)) { Remove-Item -LiteralPath $staging -Recurse -Force }
    if ($temporarySources -and (Test-Path -LiteralPath $temporarySources)) { Remove-Item -LiteralPath $temporarySources -Recurse -Force }
}
