param([string]$OutputRoot = '', [string]$BuildId = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'find-godot.ps1')
. (Join-Path $PSScriptRoot 'assert-packs-root.ps1')
$gameDirectory = Split-Path -Parent $PSScriptRoot
# The Windows PCK excludes content/, so the shipped packs must be read from the directory next to
# the executable; the development value would produce a package without content.
Assert-SpirePacksRoot -GameDirectory $gameDirectory -Expected 'adjacent'
$projectText = Get-Content -LiteralPath (Join-Path $gameDirectory 'project.godot') -Raw
$versionMatch = [regex]::Match($projectText, '(?m)^config/version="([0-9]+\.[0-9]+(?:\.[0-9]+)?(?:\.fix)?)"')
if (-not $versionMatch.Success) { throw 'Project version is missing or invalid.' }
$packageVersion = $versionMatch.Groups[1].Value
if (-not $OutputRoot) { $OutputRoot = Join-Path (Split-Path -Parent $gameDirectory) 'outputs' }
if (-not $BuildId) { $BuildId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmss') }
if ($BuildId -notmatch '^[A-Za-z0-9_-]+$') { throw 'BuildId may contain only letters, numbers, hyphens and underscores.' }
$destination = Join-Path $OutputRoot ('spire-v' + $packageVersion + '-windows-x64-' + $BuildId)
if (Test-Path -LiteralPath $destination) { throw "Output already exists: $destination" }
[IO.Directory]::CreateDirectory($destination) | Out-Null
$engine = Find-SpireGodot -Console
$executable = Join-Path $destination '紧缚尖塔.exe'
$logDirectory = Join-Path $gameDirectory ('build/package-' + $BuildId)
[IO.Directory]::CreateDirectory($logDirectory) | Out-Null
$exportLog = Join-Path $logDirectory 'export.log'
function Get-RuntimeFingerprint {
    $paths = @('core','data','ui','update','assets','content/packs','project.godot','main.tscn','export_presets.cfg')
    return @($paths | ForEach-Object { Get-ChildItem -LiteralPath (Join-Path $gameDirectory $_) -File -Recurse } |
        Where-Object { $_.Extension -notin @('.uid','.import') } | Sort-Object FullName | ForEach-Object {
            [ordered]@{ path = [IO.Path]::GetRelativePath($gameDirectory,$_.FullName); sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
        })
}
$sourceBefore = Get-RuntimeFingerprint | ConvertTo-Json -Depth 4 -Compress
& $engine --headless --path $gameDirectory --log-file $exportLog --export-release ('Windows v' + $packageVersion) $executable *> (Join-Path $logDirectory 'export-console.log')
$exportExit = $LASTEXITCODE
if ($exportExit -ne 0 -or -not (Test-Path -LiteralPath $executable) -or (Get-Content -LiteralPath $exportLog -Raw) -match '(?m)^\s*(?:USER )?(?:SCRIPT |PARSE )?ERROR:') {
    throw "Export failed (exit=$exportExit): $exportLog"
}
$contentDirectory = Join-Path $destination 'content'
[IO.Directory]::CreateDirectory($contentDirectory) | Out-Null
$packs = Join-Path $gameDirectory 'content/packs'
foreach ($file in Get-ChildItem -LiteralPath $packs -File -Recurse | Where-Object Extension -ne '.txt') {
    $target = Join-Path (Join-Path $contentDirectory 'packs') ([IO.Path]::GetRelativePath($packs, $file.FullName))
    [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target
}
& (Join-Path $PSScriptRoot 'copy-release-documents.ps1') -GameDirectory $gameDirectory -Destination $destination
$sourceAfter = Get-RuntimeFingerprint | ConvertTo-Json -Depth 4 -Compress
if ($sourceBefore -cne $sourceAfter) { throw 'Runtime sources changed during export. Keep this staging folder unpublished and export a fresh build.' }
$sourceBefore | Set-Content -LiteralPath (Join-Path $logDirectory 'source-manifest.json') -Encoding utf8
$manifest = [ordered]@{ version = $packageVersion; platform = 'windows-x64'; build = $BuildId; engine = (& $engine --version | Out-String).Trim(); files = @() }
$manifest.files = @(Get-ChildItem -LiteralPath $destination -File -Recurse | Sort-Object FullName | ForEach-Object {
    [ordered]@{ path = [IO.Path]::GetRelativePath($destination, $_.FullName); bytes = $_.Length; sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
})
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $destination 'manifest.json') -Encoding utf8
Write-Output ('PACKAGE DIRECTORY: ' + $destination)
Write-Output ('EXPORT LOG: ' + $exportLog)
Write-Output 'Export complete. Verify this standalone build before creating the distribution ZIP.'
