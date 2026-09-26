param(
    [switch]$UI, [switch]$UIOnly, [switch]$Import, [switch]$VerifyRunner,
    [switch]$Exhaustive, [switch]$ListOnly, [switch]$Impact, [switch]$KeepGoing,
    [string]$RerunFailed = '', [string[]]$Screenshots = @(),
    [string[]]$Suite = @('runner', 'architecture'), [string[]]$UISuite = @('home'),
    [ValidateRange(1,3600)][int]$TimeoutSeconds = 300
)
$ErrorActionPreference = 'Stop'
$Suite = @($Suite | ForEach-Object { $_ -split ',' } | Select-Object -Unique)
$UISuite = @($UISuite | ForEach-Object { $_ -split ',' } | Select-Object -Unique)
if ($RerunFailed) {
    foreach ($option in @('Suite','UISuite','UI','UIOnly','Impact','Exhaustive')) {
        if ($PSBoundParameters.ContainsKey($option)) { throw "-RerunFailed cannot be combined with -$option." }
    }
    $previousPath = if (Test-Path -LiteralPath $RerunFailed -PathType Container) { Join-Path $RerunFailed 'summary.json' } else { $RerunFailed }
    $previous = Get-Content -LiteralPath $previousPath -Raw | ConvertFrom-Json
    if ($previous.schema -ne 1 -or $previous.status -eq 'plan') { throw 'Expected a completed check summary, not a plan.' }
    if ($previous.status -eq 'passed') { throw 'The previous check already passed; select a new scope explicitly.' }
    $Suite = @($previous.rules.retry)
    $UISuite = @($previous.ui.retry)
    if (-not $ListOnly) { $VerifyRunner = $VerifyRunner -or $previous.verify_runner }
    if ($Suite.Count + $UISuite.Count -eq 0) {
        if ($VerifyRunner) { $Suite = @('runner') } else { throw 'No failed or unfinished suites to rerun.' }
    }
    $UIOnly = $Suite.Count -eq 0
    $UI = $UISuite.Count -gt 0
    $Exhaustive = $previous.exhaustive
    $Impact = $previous.impact -and -not $previous.rules.scope_resolved -and -not $UIOnly
    Write-Output 'RERUN: failed/unfinished suites only; this is not a full-project pass.'
}
if ($UI -and -not $UIOnly -and $PSBoundParameters.ContainsKey('Suite') -and -not $PSBoundParameters.ContainsKey('UISuite')) {
    throw 'Use -UISuite with targeted -UI; use -UIOnly for window checks alone.'
}
if ($UIOnly -and $PSBoundParameters.ContainsKey('Suite')) {
    throw '-UIOnly does not run -Suite; select window checks with -UISuite.'
}
if ($PSBoundParameters.ContainsKey('UISuite') -and -not ($UI -or $UIOnly)) {
    throw '-UISuite requires -UI or -UIOnly; window checks would otherwise be skipped.'
}
if ($ListOnly -and ($Import -or $VerifyRunner)) { throw '-ListOnly cannot be combined with -Import or -VerifyRunner.' }
if ($UIOnly -and $Impact) { throw '-Impact applies to rule suites; UI suites are selected explicitly.' }
. (Join-Path $PSScriptRoot 'find-godot.ps1')
. (Join-Path $PSScriptRoot 'doc-scan-scope.ps1')
$gameDirectory = Split-Path -Parent $PSScriptRoot
$repositoryRoot = Split-Path -Parent $gameDirectory
$engine = Find-SpireGodot -Console
$buildDirectory = Join-Path $gameDirectory 'build'
[IO.Directory]::CreateDirectory($buildDirectory) | Out-Null
[IO.File]::Open((Join-Path $buildDirectory '.gdignore'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite).Dispose()
$checkRunId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff') + '-' + $PID
$checkDirectory = Join-Path $buildDirectory ('checks/' + $checkRunId)
[IO.Directory]::CreateDirectory($checkDirectory) | Out-Null
Write-Output ('CHECK LOGS: ' + $checkDirectory)

# Record source stability, never reuse PASS from a previous source version.
function Get-SourceFingerprint {
    $entries = [Collections.Generic.List[string]]::new()
    foreach ($directory in @('core','data','ui','tests','content','assets','tools')) {
        Get-ChildItem -LiteralPath (Join-Path $gameDirectory $directory) -File -Recurse | Where-Object {
            $_.Extension -in @('.gd','.json','.tscn','.tres','.svg','.png','.webp','.ps1','.py')
        } | ForEach-Object {
            $relative = $_.FullName.Substring($gameDirectory.Length + 1)
            $entries.Add($relative + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)
        }
    }
    Get-ChildItem -LiteralPath $gameDirectory -File | Where-Object { $_.Extension -in @('.godot','.gd','.tscn','.tres') } | ForEach-Object {
        $entries.Add($_.Name + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash)
    }
    # Rule-class documents sit above the module (docs/, AGENTS.md, .zcode/skills) and are part of
    # the guarded surface: a contract edit must move the fingerprint instead of passing silently.
    # Records and the archive are excluded in doc-scan-scope.ps1 (append-only churn, not rules).
    foreach ($document in (Get-RuleDocFiles -RepositoryRoot $repositoryRoot)) {
        $entries.Add($document.Substring($repositoryRoot.Length + 1) + ':' + (Get-FileHash -LiteralPath $document -Algorithm SHA256).Hash)
    }
    # Ordinal sort, not Sort-Object: Sort-Object collates with the host's culture (ICU in pwsh 7,
    # NLS in Windows PowerShell 5.1), which ordered case/accent/hyphen neighbours differently and
    # gave one source tree two different values depending on the host that happened to run it.
    # Ordinal comparison is culture-free, so the same file set yields the same value anywhere.
    # The value stays a within-run guard, not an identity (see .zcode/skills/spire-docs/SKILL.md).
    $ordered = $entries.ToArray()
    [Array]::Sort($ordered, [StringComparer]::Ordinal)
    $bytes = [Text.Encoding]::UTF8.GetBytes(($ordered -join "`n"))
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','') } finally { $sha.Dispose() }
}

function Get-PhaseSummary {
    param([string]$Name, [string[]]$Requested, [bool]$Enabled)
    $logPath = Join-Path $checkDirectory ('check-' + $Name + '.log')
    $output = if (Test-Path -LiteralPath $logPath) { [IO.File]::ReadAllText($logPath) } else { '' }
    $scope = [regex]::Match($output, '(?m)^(?:RULE|UI) SCOPE: ([^\r\n]+)')
    $selected = if (-not $Enabled) { @() } elseif ($scope.Success) { @($scope.Groups[1].Value -split ',') } else { @($Requested) }
    $passed = @(); $failed = @()
    foreach ($result in [regex]::Matches($output, '(?m)^SUITE RESULT: (\S+) (PASS|FAIL)')) {
        if ($result.Groups[2].Value -eq 'PASS') { $passed += $result.Groups[1].Value } else { $failed += $result.Groups[1].Value }
    }
    foreach ($start in [regex]::Matches($output, '(?m)^SUITE START: (\S+)')) {
        $nameValue = $start.Groups[1].Value
        if ($nameValue -notin $passed -and $nameValue -notin $failed) { $failed += $nameValue }
    }
    $unrun = @($selected | Where-Object { $_ -notin $passed -and $_ -notin $failed })
    $retry = @($selected | Where-Object { $_ -notin $passed })
    $complete = $output -match '(?m)^(?:UI )?PASS: \d+ assertions\s*$'
    if ($Enabled -and -not $complete -and $retry.Count -eq 0 -and -not $ListOnly) { $retry = @($selected) }
    return [ordered]@{ selected=@($selected); passed=@($passed); failed=@($failed); unrun=@($unrun); retry=@($retry); scope_resolved=$scope.Success; complete=$complete; log=$logPath }
}

# Rule-class document gate (tools/check-docs.ps1): one barrier over the whole guarded document
# set, so it has no per-suite selection -- the counts come straight from its own log. The allowlist
# entry count is reported on every run to keep that debt visible; this phase never rebuilds the
# document list (scope stays in tools/doc-scan-scope.ps1).
function Get-DocumentPhaseSummary {
    $logPath = Join-Path $checkDirectory 'check-docs.log'
    $output = if (Test-Path -LiteralPath $logPath) { [IO.File]::ReadAllText($logPath) } else { '' }
    $result = [regex]::Match($output, '(?m)^DOCS RESULT: (PASS|FAIL)\s*$')
    $pass = [regex]::Match($output, '(?m)^DOCS PASS: (\d+) rule-class document\(s\), (\d+) reference\(s\) checked, allowlist (\d+) entrie\(s\)')
    $fail = [regex]::Match($output, '(?m)^DOCS FAIL: (\d+) unresolved reference\(s\) in rule-class documents; allowlist (\d+) entrie\(s\)')
    $status = 'unrun'
    if ($result.Success) {
        $status = 'failed'
        if ($result.Groups[1].Value -eq 'PASS') { $status = 'passed' }
    }
    # Counts the gate only states on success stay null instead of reading as zero: a failed or
    # never-run gate must not look like an empty document set.
    $documentsChecked = $null; $referencesChecked = $null; $problems = $null; $allowlist = $null
    if ($pass.Success) {
        $documentsChecked = [int]$pass.Groups[1].Value
        $referencesChecked = [int]$pass.Groups[2].Value
        $allowlist = [int]$pass.Groups[3].Value
        $problems = 0
    }
    if ($fail.Success) { $problems = [int]$fail.Groups[1].Value; $allowlist = [int]$fail.Groups[2].Value }
    return [ordered]@{
        status=$status; complete=$pass.Success; documents=$documentsChecked; references=$referencesChecked
        problems=$problems; allowlist=$allowlist; log=$logPath
    }
}

# Every engine process is owned by this invocation; never stop an interactive game.
function Invoke-CheckEngine {
    param([string]$Log, [string[]]$Arguments, [int]$LimitSeconds = $TimeoutSeconds)
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $engine
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.Arguments = ((@('--path', $gameDirectory, '--log-file', $Log) + $Arguments) | ForEach-Object {
        '"' + $_.Replace('"', '\"') + '"'
    }) -join ' '
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        [void]$process.Start()
        if (-not $process.WaitForExit($LimitSeconds * 1000)) {
            $process.Kill()
            $process.WaitForExit()
            throw [TimeoutException]::new("Godot check exceeded ${LimitSeconds}s. See $Log")
        }
        return $process.ExitCode
    } finally {
        $process.Dispose()
    }
}

function Invoke-SpireCheck {
    param([string]$Name, [string[]]$EngineArguments, [string]$Expected = '')
    $checkLog = Join-Path $checkDirectory ('check-' + $Name + '.log')
    [IO.File]::WriteAllText($checkLog, '')
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $checkExit = Invoke-CheckEngine -Log $checkLog -Arguments $EngineArguments
    $output = [IO.File]::ReadAllText($checkLog)
    $output -split '\r?\n' | Where-Object { $_ -match '^(RULE |UI SCOPE:|SUITE RESULT:|SAMPLES |PASS:|UI PASS:|FAIL:|UI FAIL:|PLAN ONLY:)' -or ($ListOnly -and $_ -match '^  \S+ \[') } | Write-Output
    if ($checkExit -ne 0 -or $output -match '(?m)^\s*(?:USER )?(?:SCRIPT |PARSE )?ERROR:') {
        $output -split '\r?\n' | Where-Object { $_ -match '^\s*(?:USER )?(?:SCRIPT |PARSE )?ERROR:' } | Select-Object -First 3 | Write-Output
        throw "Godot $Name check failed (exit=$checkExit). See $checkLog"
    }
    if ($Expected -and $output -notmatch $Expected) { throw "Godot $Name check did not finish. See $checkLog" }
    Write-Output ('CHECK {0}: {1:N2}s' -f $Name, $timer.Elapsed.TotalSeconds)
}

$beforeFingerprint = Get-SourceFingerprint
$exitCode = 0
$failureMessage = ''
$documentFailure = ''
try {
    # Rule-class document reference gate: an independent phase in the same shape as the content-pack
    # gate (tools/check-content.ps1), run through this shell with its own log, result line and
    # summary field. It needs no engine, so it runs first and it runs on every round. A failure is
    # recorded, not thrown: one typo in a contract must not cancel the engine phases and throw away
    # a whole round of rule/UI evidence -- the round takes the non-zero exit at the end instead, so
    # a document red and a rule red land in the same evidence. -ExecutionPolicy Bypass: the child is
    # a fresh host whose policy is the machine default, and a blocked script would read as a red gate.
    $documentLog = Join-Path $checkDirectory 'check-docs.log'
    $documentOutput = ''
    $documentExit = 1
    try {
        $documentOutput = (& (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'check-docs.ps1') 2>&1 | Out-String)
        $documentExit = $LASTEXITCODE
    } catch {
        $documentOutput = [string]$_.Exception.Message
        $documentExit = 1
    }
    $documentResult = 'FAIL'
    if ($documentExit -eq 0) { $documentResult = 'PASS' }
    $documentOutput = $documentOutput.TrimEnd() + "`nDOCS RESULT: $documentResult`n"
    [IO.File]::WriteAllText($documentLog, $documentOutput)
    $documentOutput -split '\r?\n' | Where-Object { $_ -match '^DOCS? ' } | Write-Output
    if ($documentResult -eq 'FAIL') {
        $documentFailure = ('Rule-class document gate failed (exit=' + $documentExit + '). See ' + $documentLog)
        Write-Output $documentFailure
    }
    if ($Import -or -not (Test-Path -LiteralPath (Join-Path $gameDirectory '.godot'))) {
        Invoke-SpireCheck -Name 'import' -EngineArguments @('--headless', '--editor', '--quit')
    }
    if (-not $UIOnly) {
        $arguments = @('--headless', '--script', 'res://tests/test_game.gd', '--', ('--suite=' + ($Suite -join ',')))
        if ($Impact) { $arguments += '--impact' }
        if ($Exhaustive) { $arguments += '--exhaustive' }
        if ($KeepGoing) { $arguments += '--keep-going' }
        if ($ListOnly) { $arguments += '--list-only' }
        $expected = if ($ListOnly) { '(?m)^PLAN ONLY: no rule tests executed$' } else { '(?m)^PASS: \d+ assertions\s*$' }
        Invoke-SpireCheck -Name 'rules' -EngineArguments $arguments -Expected $expected
    }
    if ($UI -or $UIOnly) {
        $arguments = @('--script', 'res://tests/ui_smoke.gd', '--', ('--ui-suite=' + ($UISuite -join ',')))
        if ($KeepGoing) { $arguments += '--keep-going' }
        if ($Screenshots.Count -gt 0) { $arguments += ('--screenshots=' + ($Screenshots -join ',')) }
        if ($ListOnly) { $arguments = @('--headless') + $arguments + @('--list-only') }
        $expected = if ($ListOnly) { '(?m)^PLAN ONLY: no UI tests executed$' } else { '(?m)^UI PASS: \d+ assertions\s*$' }
        Invoke-SpireCheck -Name 'ui' -EngineArguments $arguments -Expected $expected
    }
if ($VerifyRunner) {
    $checkShell = (Get-Process -Id $PID).Path
    foreach ($selectionProbe in @(
        @{ Name='ui-only-rule-scope'; Arguments=@('-UIOnly','-Suite','runner','-ListOnly'); Message='-UIOnly does not run -Suite' },
        @{ Name='inactive-ui-scope'; Arguments=@('-UISuite','home','-ListOnly'); Message='-UISuite requires -UI or -UIOnly' }
    )) {
        $probeArguments = $selectionProbe.Arguments
        $probeOutput = (& $checkShell -NoProfile -File $PSCommandPath @probeArguments 2>&1 | Out-String)
        $probeExit = $LASTEXITCODE
        [IO.File]::WriteAllText((Join-Path $checkDirectory ('check-negative-' + $selectionProbe.Name + '.log')), $probeOutput)
        if ($probeExit -eq 0 -or -not $probeOutput.Contains($selectionProbe.Message) -or $probeOutput.Contains('CHECK LOGS:')) {
            throw "Inactive test selection was not rejected before engine startup: $($selectionProbe.Name)"
        }
        Write-Output "CHECK negative-$($selectionProbe.Name): ignored scope rejected before engine startup"
    }
    $timeoutDetected = $false
    try {
        Invoke-CheckEngine -Log (Join-Path $checkDirectory 'check-negative-timeout.log') -Arguments @('--headless', '--script', 'res://tests/hang_probe.gd') -LimitSeconds 1 | Out-Null
    } catch [TimeoutException] {
        $timeoutDetected = $true
    }
    if (-not $timeoutDetected) { throw 'Timeout probe failed to stop an unfinished process.' }
    Write-Output 'CHECK negative-timeout: unfinished process stopped after 1s'

    foreach ($probeName in @('rules', 'ui')) {
        $probeScript = if ($probeName -eq 'rules') { 'res://tests/test_game.gd' } else { 'res://tests/ui_smoke.gd' }
        $probeLog = Join-Path $checkDirectory ('check-negative-' + $probeName + '.log')
        [IO.File]::WriteAllText($probeLog, '')
        $probeExit = Invoke-CheckEngine -Log $probeLog -Arguments @('--headless', '--script', $probeScript, '--', '--suite=runner', '--probe-runtime-error')
        $probeOutput = [IO.File]::ReadAllText($probeLog)
        if ($probeExit -eq 0 -or $probeOutput -match '(?m)^(?:UI )?PASS:' -or $probeOutput -notmatch 'deliberate_missing_test_key' -or $probeOutput -notmatch '(?m)^(?:UI )?FAIL:') {
            throw "Runtime-error detection probe failed: $probeName. See $probeLog"
        }
        Write-Output "CHECK negative-${probeName}: correctly rejected intentional runtime error, no false PASS"
    }
    foreach ($continueSuites in @($false, $true)) {
        $probeName = if ($continueSuites) { 'negative-continue' } else { 'negative-stop' }
        $probeLog = Join-Path $checkDirectory ('check-' + $probeName + '.log')
        $probeArguments = @('--headless', '--script', 'res://tests/test_game.gd', '--', '--suite=runner,tower', '--probe-suite-failure')
        if ($continueSuites) { $probeArguments += '--keep-going' }
        $probeExit = Invoke-CheckEngine -Log $probeLog -Arguments $probeArguments
        $probe = Get-PhaseSummary -Name $probeName -Requested @('runner','tower') -Enabled $true
        if ($probeExit -eq 0 -or $probe.failed -notcontains 'runner' -or $probe.complete) { throw "Suite failure probe was not rejected: $probeName" }
        if ($continueSuites) {
            if ($probe.passed -notcontains 'tower' -or ($probe.retry -join ',') -ne 'runner') { throw 'KeepGoing probe lost the successful suite or retried it unnecessarily.' }
        } else {
            if (($probe.unrun -join ',') -ne 'tower' -or ($probe.retry -join ',') -ne 'runner,tower') { throw 'Stop probe did not preserve the unfinished suite for retry.' }
        }
        Write-Output "CHECK ${probeName}: failure, unfinished scope and retry report verified"
    }
}

} catch {
    $exitCode = 1
    $failureMessage = $_.Exception.Message
    Write-Output $failureMessage
} finally {
    $afterFingerprint = Get-SourceFingerprint
    $rules = Get-PhaseSummary -Name rules -Requested $Suite -Enabled (-not $UIOnly)
    $window = Get-PhaseSummary -Name ui -Requested $UISuite -Enabled ([bool]($UI -or $UIOnly))
    $documentGate = Get-DocumentPhaseSummary
    # Deferred document failure: the phase collected its result, the round fails here. A rule/UI
    # failure keeps the message it already recorded.
    if ($documentFailure) {
        $exitCode = 1
        if (-not $failureMessage) { $failureMessage = $documentFailure }
    }
    $changed = $beforeFingerprint -ne $afterFingerprint
    if ($changed -and -not $ListOnly) {
        $exitCode = 1
        $rules.retry = @($rules.selected); $window.retry = @($window.selected)
        Write-Output 'SOURCE CHANGED: results belong to a moving workspace; rerun after edits settle.'
    }
    $status = if ($ListOnly -and $exitCode -eq 0) { 'plan' } elseif ($changed -and -not $ListOnly) { 'source_changed' } elseif ($exitCode -eq 0) { 'passed' } else { 'failed' }
    $summary = [ordered]@{ schema=1; status=$status; error=$failureMessage; impact=[bool]$Impact; exhaustive=[bool]($Exhaustive -or 'all' -in $Suite); verify_runner=[bool]$VerifyRunner; before=$beforeFingerprint; after=$afterFingerprint; rules=$rules; ui=$window; docs=$documentGate }
    $summaryPath = Join-Path $checkDirectory 'summary.json'
    [IO.File]::WriteAllText($summaryPath, ($summary | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    Write-Output ('SUMMARY: ' + $summaryPath)
    if ($exitCode -ne 0) {
        # A document-only failure leaves no suite to rerun, and -RerunFailed refuses such a round.
        if (($rules.retry.Count + $window.retry.Count) -gt 0) { Write-Output ('.\tools\check.ps1 -RerunFailed "' + $checkDirectory + '"') }
    }
}
exit $exitCode
