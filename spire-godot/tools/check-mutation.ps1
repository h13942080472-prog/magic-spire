param(
    [string[]]$Check = @(),
    [switch]$All,
    [ValidateRange(1,3600)][int]$TimeoutSeconds = 600
)
# Sensitivity evidence for the named checks: for one entry of tests/mutations.json, apply the
# declared source mutation, run the narrowest rule suite, require that named check to redden
# (the suite must fail and an engine error line must name the check), then restore the file
# byte-for-byte. Any failure -- anchor not unique, suite green, suite failed without an error
# line naming this check, restore hash mismatch -- makes the whole invocation exit non-zero.
#
# The table's find/replace strings use \n; the anchor and the injected text are expanded to the
# target file's own line ending (CRLF here) so matching and writing stay byte-exact.
#
# This tool mutates tracked source for the duration of one suite run. Run it with one engine
# process at a time and never concurrently with another gate.
$ErrorActionPreference = 'Stop'
$Check = @($Check | ForEach-Object { $_ -split ',' } | Where-Object { $_ } | Select-Object -Unique)
if ($All -and $Check.Count -gt 0) { throw '-All and -Check are mutually exclusive.' }
if (-not $All -and $Check.Count -eq 0) { throw 'Select entries with -All or -Check <name>.' }
. (Join-Path $PSScriptRoot 'find-godot.ps1')
$gameDirectory = Split-Path -Parent $PSScriptRoot
$repositoryRoot = Split-Path -Parent $gameDirectory
$engine = Find-SpireGodot -Console
$tablePath = Join-Path $gameDirectory 'tests/mutations.json'
$table = [IO.File]::ReadAllText($tablePath, [Text.UTF8Encoding]::new($false)) | ConvertFrom-Json
if ($table.schema -ne 1) { throw 'tests/mutations.json: unexpected schema.' }
$names = @($table.mutations.PSObject.Properties.Name)
if ($names.Count -eq 0) { throw 'tests/mutations.json: no entries.' }
if ($All) { $selected = $names } else {
    $unknown = @($Check | Where-Object { $_ -notin $names })
    if ($unknown.Count -gt 0) { throw ('Unknown mutation entry: ' + ($unknown -join ', ')) }
    $selected = @($Check)
}
$runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff') + '-' + $PID
$runDirectory = Join-Path $gameDirectory ('build/mutations/' + $runId)
[IO.Directory]::CreateDirectory($runDirectory) | Out-Null
Write-Output ('MUTATION LOGS: ' + $runDirectory)
Write-Output ('MUTATION TABLE: ' + $names.Count + ' entry(ies); this run selects ' + $selected.Count + '.')
$statusBefore = (@(git -C $repositoryRoot status --porcelain) -join "`n")
$timer = [Diagnostics.Stopwatch]::StartNew()
$rows = [Collections.Generic.List[object]]::new()

function Invoke-MutationEngine {
    param([string]$Log, [string]$Suite)
    $arguments = @('--path', $gameDirectory, '--log-file', $Log, '--headless', '--script', 'res://tests/test_game.gd', '--', ('--suite=' + $Suite))
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $engine
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.Arguments = ($arguments | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }) -join ' '
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        [void]$process.Start()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            $process.WaitForExit()
            return @{ exit = $null; timeout = $true }
        }
        return @{ exit = $process.ExitCode; timeout = $false }
    } finally {
        $process.Dispose()
    }
}

foreach ($name in $selected) {
    $row = $table.mutations.$name
    $result = [ordered]@{ name = $name; file = [string]$row.file; suite = [string]$row.suite; red = $false; restored = $false; hash = ''; reason = ''; seconds = 0.0; log = '' }
    $entryTimer = [Diagnostics.Stopwatch]::StartNew()
    $mutated = $false
    $original = $null
    $originalHash = ''
    $path = ''
    try {
        if (-not $row.file -or -not ($row.find -is [string]) -or -not ($row.replace -is [string]) -or -not $row.suite) { throw 'entry is missing file/find/replace/suite.' }
        if ($row.find -eq $row.replace) { throw 'find and replace are identical.' }
        $path = Join-Path $gameDirectory ([string]$row.file)
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw ('target file not found: ' + $row.file) }
        $original = [IO.File]::ReadAllBytes($path)
        $originalHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        $hasBom = $original.Length -ge 3 -and $original[0] -eq 0xEF -and $original[1] -eq 0xBB -and $original[2] -eq 0xBF
        $text = [Text.Encoding]::UTF8.GetString($original, $(if ($hasBom) { 3 } else { 0 }), $original.Length - $(if ($hasBom) { 3 } else { 0 }))
        $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
        $find = $row.find -replace "`r?`n", $newline
        $replace = $row.replace -replace "`r?`n", $newline
        $count = 0; $index = 0
        while (($index = $text.IndexOf($find, $index, [StringComparison]::Ordinal)) -ge 0) { $count++; $index += $find.Length }
        if ($count -ne 1) { throw ('anchor must occur exactly once in ' + $row.file + '; found ' + $count) }
        $mutatedText = $text.Replace($find, $replace)
        if ($mutatedText -eq $text) { throw 'mutation left the file unchanged.' }
        $bytes = [Text.Encoding]::UTF8.GetBytes($mutatedText)
        if ($hasBom) { [IO.File]::WriteAllBytes($path, [byte[]](@(0xEF, 0xBB, 0xBF) + $bytes)) } else { [IO.File]::WriteAllBytes($path, $bytes) }
        $mutated = $true
        $log = Join-Path $runDirectory ($name + '.log')
        $result.log = $log
        $run = Invoke-MutationEngine -Log $log -Suite ([string]$row.suite)
        if ($run.timeout) { throw ('suite ' + $row.suite + ' timed out after ' + $TimeoutSeconds + 's.') }
        $output = if (Test-Path -LiteralPath $log) { [IO.File]::ReadAllText($log) } else { '' }
        $started = $output -match ('(?m)^SUITE START: ' + [regex]::Escape([string]$row.suite) + '\s*$')
        $failed = $output -match ('(?m)^SUITE RESULT: ' + [regex]::Escape([string]$row.suite) + ' FAIL\s*$')
        $errorLines = @($output -split '\r?\n' | Where-Object { $_ -match '^\s*(?:USER )?(?:SCRIPT |PARSE )?ERROR:' -and $_.Contains($name) })
        if ($run.exit -eq $null -or $run.exit -eq 0) { throw ('suite ' + $row.suite + ' exited ' + $run.exit + '; the mutated source did not fail the run.') }
        if (-not $started) { throw ('suite ' + $row.suite + ' never started; the mutation broke loading instead of the check.') }
        if (-not $failed) { throw ('SUITE RESULT: ' + $row.suite + ' did not report FAIL.') }
        if ($errorLines.Count -eq 0) { throw ('no engine error line names the mutated check ' + $name + '.') }
        $result.red = $true
    } catch {
        $result.reason = $_.Exception.Message
    } finally {
        if ($mutated) {
            [IO.File]::WriteAllBytes($path, $original)
            $restoredHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            $result.restored = $restoredHash -eq $originalHash
            if (-not $result.restored) { $result.reason = 'restore hash mismatch: ' + $restoredHash + ' != ' + $originalHash }
        }
        $entryTimer.Stop()
        $result.seconds = [math]::Round($entryTimer.Elapsed.TotalSeconds, 1)
        $result.hash = $originalHash.Substring(0, 12)
        $rows.Add($result)
    }
    $verdict = if ($result.red -and $result.restored) { 'RED' } else { 'FAILED' }
    $detail = if ($result.reason) { ' -- ' + $result.reason } else { '' }
    Write-Output ('MUTATION ' + $name + ' [' + $result.file + ']: ' + $verdict + ' exit-red=' + $result.red + ' restored=' + $result.restored + ' sha256=' + $result.hash + ' ' + $result.seconds + 's' + $detail)
    if ($result.log) { Write-Output ('  log: ' + $result.log) }
}
$timer.Stop()
$statusAfter = (@(git -C $repositoryRoot status --porcelain) -join "`n")
$clean = $statusAfter -eq $statusBefore
if (-not $clean) { Write-Output 'MUTATION RESIDUE: git status changed across the run; inspect the worktree.' }
$good = @($rows | Where-Object { $_.red -and $_.restored }).Count
Write-Output ('MUTATION SUMMARY: ' + $good + '/' + $rows.Count + ' entr(ies) reddened the named check and restored byte-for-byte; worktree unchanged=' + $clean + '; elapsed ' + [math]::Round($timer.Elapsed.TotalSeconds, 1) + 's')
if ($good -ne $rows.Count -or -not $clean) { exit 1 }
exit 0
