param(
    [switch]$UI, [switch]$UIOnly, [switch]$Import, [switch]$VerifyRunner,
    [switch]$Exhaustive, [switch]$ListOnly, [switch]$Impact, [switch]$KeepGoing,
    [switch]$Changed, [string]$Since = '', [string]$ChangedList = '',
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
    # The recipe phase keeps its retry token in its own summary field; carry it into the suite
    # scope like a rule suite and let the extraction below take it back out.
    if ($previous.PSObject.Properties.Name -contains 'recipe') { $Suite += @($previous.recipe.retry) }
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
# The long-horizon real-input recipe is its own check.ps1 phase, not a test_game.gd rule suite: it
# drives a real window through the shipped UI helpers and owns its exit-code evidence. Pull the
# token out of the rule scope here; `all` deliberately does not expand to it (see the operations
# card in skills/repo-ops/SKILL.md).
$Recipe = 'recipe' -in $Suite
$Suite = @($Suite | Where-Object { $_ -ne 'recipe' })
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
# Route mode: the change set decides the scope, so an explicit scope is a conflict. All
# rejections happen here, before any engine starts (docs/spec/check-routing.md §2.3).
$routeMode = [bool]($Changed -or $ChangedList)
if ($Since -and -not $Changed) { throw '-Since requires -Changed.' }
if ($Changed -and $ChangedList) { throw '-Changed and -ChangedList are mutually exclusive.' }
if ($routeMode -and $RerunFailed) { throw '-RerunFailed cannot be combined with -Changed or -ChangedList.' }
if ($routeMode) {
    foreach ($option in @('Suite','UISuite','UI','UIOnly','Impact')) {
        if ($PSBoundParameters.ContainsKey($option)) { throw "-Changed/-ChangedList cannot be combined with -$option." }
    }
}
. (Join-Path $PSScriptRoot 'find-godot.ps1')
. (Join-Path $PSScriptRoot 'doc-scan-scope.ps1')
$gameDirectory = Split-Path -Parent $PSScriptRoot
$repositoryRoot = Split-Path -Parent $gameDirectory
# -Changed: tracked changes against <base> plus untracked files; base defaults to HEAD.
# -ChangedList: one repository-root relative path per line, # comments and blanks ignored.
# Ambiguous git lines (renames, quoted paths, tabs) are refused instead of guessed, and
# anything outside spire-godot/ that is not a declared-none document is not source.
$routeFiles = @()
$declaredNone = @('docs/','release/','.zcode/','skills/','spire-godot/build/','spire-godot/.godot/')
function Test-DeclaredNone {
    param([string]$Path)
    foreach ($prefix in $declaredNone) { if ($Path.StartsWith($prefix)) { return $true } }
    if ($Path -match '^[^/]+\.md$') { return $true }
    return $Path -in @('README.md','AGENTS.md','.gitignore','LICENSE','ASSET_RIGHTS.md')
}
if ($routeMode) {
    if ($Changed) {
        $base = if ($Since) { $Since } else { 'HEAD' }
        $tracked = @(& git -C $repositoryRoot -c core.quotepath=false diff --name-only $base)
        if ($LASTEXITCODE -ne 0) { throw "git diff failed for base $base." }
        $untracked = @(& git -C $repositoryRoot -c core.quotepath=false ls-files --others --exclude-standard)
        if ($LASTEXITCODE -ne 0) { throw 'git ls-files failed for the untracked change set.' }
        $routeFiles = @($tracked + $untracked | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    } else {
        $routeFiles = @(Get-Content -LiteralPath $ChangedList | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and -not $_.StartsWith('#') })
    }
    $ambiguous = @($routeFiles | Where-Object { $_ -match '"' -or $_ -match '=>' -or $_ -match "`t" })
    if ($ambiguous.Count -gt 0) { throw "Ambiguous change-set line(s): $($ambiguous -join ', '). Use -ChangedList with explicit module paths." }
    # Strip one leading "./" only: TrimStart('./') would also eat the dot of paths like
    # .zcode/skills/repo-ops/SKILL.md and turn declared-none into an error.
    $routeFiles = @($routeFiles | ForEach-Object { $_.Replace('\','/') } | ForEach-Object { if ($_.StartsWith('./')) { $_.Substring(2) } else { $_ } } | Sort-Object -Unique)
    if ($routeFiles.Count -eq 0) { throw 'The change set is empty; committed changes need -Changed -Since <ref> (default base is HEAD).' }
    foreach ($file in $routeFiles) {
        if ($file.StartsWith('spire-godot/')) { continue }
        if (Test-DeclaredNone $file) { continue }
        throw "Path is outside spire-godot/: $file. That is not source; use -ChangedList with explicit module paths."
    }
}
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
    foreach ($directory in @('core','data','ui','tests','content','assets','tools','update')) {
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
    # Rule-class documents sit above the module (docs/, AGENTS.md, skills/ and its .zcode/skills
    # discovery stubs) and are part of the guarded surface: a contract edit must move the
    # fingerprint instead of passing silently.
    # Records and the archive are excluded in doc-scan-scope.ps1 (append-only churn, not rules).
    foreach ($document in (Get-RuleDocFiles -RepositoryRoot $repositoryRoot)) {
        $entries.Add($document.Substring($repositoryRoot.Length + 1) + ':' + (Get-FileHash -LiteralPath $document -Algorithm SHA256).Hash)
    }
    # Ordinal sort, not Sort-Object: Sort-Object collates with the host's culture (ICU in pwsh 7,
    # NLS in Windows PowerShell 5.1), which ordered case/accent/hyphen neighbours differently and
    # gave one source tree two different values depending on the host that happened to run it.
    # Ordinal comparison is culture-free, so the same file set yields the same value anywhere.
    # The value stays a within-run guard, not an identity (see skills/spire-docs/SKILL.md).
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

# Long-horizon real-input recipe (-Suite recipe). Unlike the rule/UI phases this is not a suite
# inside test_game.gd / ui_smoke.gd: the engine runs tests/recipe_driver.gd on its own, the recipe
# needs a real window, and a product crash takes the whole process down with it. Its evidence file
# is therefore assembled here -- RUN IDENTITY header, engine output, then exit=<code> -- so a crash
# keeps its signal/exit code in-band instead of surviving only as a thrown message. Acceptance is
# exit=0 plus the driver's closing line `RECIPE seed=<n> commits=<cap> steps=<n> stop=cap`.
function Invoke-RecipeCheck {
    param([int]$Seed, [int]$Cap, [string]$Style)
    $checkLog = Join-Path $checkDirectory 'check-recipe.log'
    $bodyLog = Join-Path $checkDirectory 'check-recipe.body.log'
    $errorLog = Join-Path $checkDirectory 'check-recipe.stderr.log'
    $head = 'unavailable'; $dirty = 'unavailable'
    try {
        $head = ((git -C $repositoryRoot rev-parse HEAD) | Select-Object -First 1).Trim()
        $dirty = @(git -C $repositoryRoot status --porcelain).Count
    } catch {
        Write-Output ('RECIPE identity unavailable: ' + $_.Exception.Message)
    }
    $identity = [Collections.Generic.List[string]]::new()
    $identity.Add('RUN IDENTITY')
    $identity.Add('head=' + $head)
    $identity.Add('started=' + [DateTime]::Now.ToString('yyyy-MM-ddTHH:mm:sszzz'))
    $identity.Add('dirty=' + $dirty)
    foreach ($relative in @('spire-godot/ui/card_face.gd', 'spire-godot/tests/recipe_driver.gd', 'spire-godot/tests/ui_smoke.gd', 'spire-godot/tests/normal_play_cases.gd', 'spire-godot/tests/game_fixture.gd')) {
        $path = Join-Path $repositoryRoot $relative
        $hash = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash } else { 'missing' }
        $identity.Add($relative + ' sha256=' + $hash)
    }
    $arguments = (@('--path', $gameDirectory, '--script', 'res://tests/recipe_driver.gd', '--', ('--seed=' + $Seed), ('--cap=' + $Cap), ('--style=' + $Style)) | ForEach-Object {
        '"' + $_.Replace('"', '\"') + '"'
    }) -join ' '
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $process = Start-Process -FilePath $engine -ArgumentList $arguments -WorkingDirectory $gameDirectory -NoNewWindow -PassThru -RedirectStandardOutput $bodyLog -RedirectStandardError $errorLog
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill()
        $process.WaitForExit()
        throw [TimeoutException]::new("Godot recipe check exceeded ${TimeoutSeconds}s. See $checkLog")
    }
    $checkExit = $process.ExitCode
    $body = if (Test-Path -LiteralPath $bodyLog) { [IO.File]::ReadAllText($bodyLog) } else { '' }
    [IO.File]::WriteAllText($checkLog, ($identity -join "`r`n") + "`r`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::AppendAllText($checkLog, $body, [Text.UTF8Encoding]::new($false))
    [IO.File]::AppendAllText($checkLog, "exit=$checkExit`r`n", [Text.UTF8Encoding]::new($false))
    if (Test-Path -LiteralPath $errorLog) {
        $stderrText = [IO.File]::ReadAllText($errorLog)
        if ($stderrText) { [IO.File]::AppendAllText($checkLog, 'stderr: ' + $stderrText + "`r`n", [Text.UTF8Encoding]::new($false)) }
    }
    $identity | Write-Output
    $body -split '\r?\n' | Where-Object { $_ -match '^(RECIPE |FK SESSION|UI TIME:|UI INPUT:|UI (?:PASS|FAIL):)' } | Write-Output
    $closing = [regex]::Match($body, '(?m)^RECIPE seed=(\d+) commits=(\d+) steps=(\d+) stop=(\S+)\s*$')
    if ($checkExit -ne 0) { throw "Godot recipe check failed (exit=$checkExit). See $checkLog" }
    if (-not $closing.Success) { throw "Godot recipe check did not finish: no RECIPE closing line. See $checkLog" }
    if ($closing.Groups[4].Value -ne 'cap' -or [int]$closing.Groups[2].Value -lt $Cap) {
        throw ('Godot recipe check stopped before the commit cap (' + $closing.Value + '). See ' + $checkLog)
    }
    Write-Output ('CHECK recipe: {0:N2}s, exit={1}, {2}' -f $timer.Elapsed.TotalSeconds, $checkExit, $closing.Value)
}

# Summary field of the recipe phase, shaped like the rule/UI phases so -RerunFailed can carry its
# token and the round record states the closing line instead of a bare assertion count.
function Get-RecipePhaseSummary {
    param([bool]$Enabled)
    $logPath = Join-Path $checkDirectory 'check-recipe.log'
    $output = if (Test-Path -LiteralPath $logPath) { [IO.File]::ReadAllText($logPath) } else { '' }
    $closing = [regex]::Match($output, '(?m)^RECIPE seed=(\d+) commits=(\d+) steps=(\d+) stop=(\S+)\s*$')
    $exitLine = [regex]::Match($output, '(?m)^exit=(-?\d+)\s*$')
    $ran = $Enabled -and -not $ListOnly
    $passed = $ran -and $exitLine.Success -and [int]$exitLine.Groups[1].Value -eq 0 -and $closing.Success -and $closing.Groups[4].Value -eq 'cap'
    $selected = @(); if ($Enabled) { $selected = @('recipe') }
    return [ordered]@{
        selected=$selected
        passed=@(if ($passed) { 'recipe' })
        failed=@(if ($ran -and -not $passed) { 'recipe' })
        retry=@(if ($ran -and -not $passed) { 'recipe' })
        exit=$(if ($exitLine.Success) { [int]$exitLine.Groups[1].Value } else { $null })
        seed=$(if ($closing.Success) { [int]$closing.Groups[1].Value } else { $null })
        commits=$(if ($closing.Success) { [int]$closing.Groups[2].Value } else { $null })
        steps=$(if ($closing.Success) { [int]$closing.Groups[3].Value } else { $null })
        stop=$(if ($closing.Success) { $closing.Groups[4].Value } else { $null })
        log=$logPath
    }
}

$beforeFingerprint = Get-SourceFingerprint
$exitCode = 0
$failureMessage = ''
$documentFailure = ''
$routeSummary = $null
$gateResults = $null
$planOnly = [bool]($routeMode -and $ListOnly)
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
    if ($routeMode) {
        # Plan host first: it prints the ROUTE lines and writes the plan JSON that decides
        # both phases. No test host starts before the plan is accepted, and the ROUTE lines
        # are the review surface for every default decision (docs/spec/check-routing.md §2.2).
        $routeListPath = Join-Path $checkDirectory 'changed-files.txt'
        [IO.File]::WriteAllLines($routeListPath, $routeFiles, [Text.UTF8Encoding]::new($false))
        $routePlanPath = Join-Path $checkDirectory 'route-plan.json'
        $routeLogPath = Join-Path $checkDirectory 'check-route.log'
        $routeArguments = @('--headless', '--script', 'res://tests/route_plan.gd', '--', ('--files=' + $routeListPath), ('--plan=' + $routePlanPath))
        if ($ListOnly) { $routeArguments += '--list-only' }
        $routeExit = Invoke-CheckEngine -Log $routeLogPath -Arguments $routeArguments
        $routeOutput = [IO.File]::ReadAllText($routeLogPath)
        $routeOutput -split '\r?\n' | Where-Object { $_ -match '^(ROUTE |PLAN ONLY:)' } | Write-Output
        if ($routeExit -ne 0 -or -not (Test-Path -LiteralPath $routePlanPath)) { throw "Route plan refused the change set (exit=$routeExit). See $routeLogPath" }
        $plan = Get-Content -LiteralPath $routePlanPath -Raw | ConvertFrom-Json
        $Suite = @($plan.rules | Where-Object { $_ })
        $UISuite = @($plan.ui | Where-Object { $_ })
        $UI = $UISuite.Count -gt 0
        $UIOnly = $Suite.Count -eq 0
        $routeSummary = [ordered]@{ mode=$plan.mode; since=$Since; files_count=@($plan.files).Count; files_sha256=$plan.files_sha256
            index_digest=$plan.index_digest; rules=@($plan.rules); ui=@($plan.ui); gates=@($plan.gates); unmapped=@($plan.unmapped)
            default_files=@($plan.default_files); blind_files=@($plan.blind_files); defect_hits=@($plan.defect_hits)
            widen=@($plan.widen); widen_candidates=@($plan.widen_candidates); milestone=@($plan.milestone); notes=@($plan.notes)
            declared_none=@($plan.declared_none); plan=$routePlanPath; log=$routeLogPath }
    }
    if (-not $planOnly -and ($Import -or -not (Test-Path -LiteralPath (Join-Path $gameDirectory '.godot')))) {
        Invoke-SpireCheck -Name 'import' -EngineArguments @('--headless', '--editor', '--quit')
    }
    if (-not $planOnly -and -not $UIOnly -and $Suite.Count -gt 0) {
        $arguments = @('--headless', '--script', 'res://tests/test_game.gd', '--', ('--suite=' + ($Suite -join ',')))
        if ($Impact) { $arguments += '--impact' }
        if ($Exhaustive) { $arguments += '--exhaustive' }
        if ($KeepGoing) { $arguments += '--keep-going' }
        if ($ListOnly) { $arguments += '--list-only' }
        $expected = if ($ListOnly) { '(?m)^PLAN ONLY: no rule tests executed$' } else { '(?m)^PASS: \d+ assertions\s*$' }
        Invoke-SpireCheck -Name 'rules' -EngineArguments $arguments -Expected $expected
    }
    if (-not $planOnly -and ($UI -or $UIOnly)) {
        $arguments = @('--script', 'res://tests/ui_smoke.gd', '--', ('--ui-suite=' + ($UISuite -join ',')))
        if ($KeepGoing) { $arguments += '--keep-going' }
        if ($Screenshots.Count -gt 0) { $arguments += ('--screenshots=' + ($Screenshots -join ',')) }
        if ($ListOnly) { $arguments = @('--headless') + $arguments + @('--list-only') }
        $expected = if ($ListOnly) { '(?m)^PLAN ONLY: no UI tests executed$' } else { '(?m)^UI PASS: \d+ assertions\s*$' }
        Invoke-SpireCheck -Name 'ui' -EngineArguments $arguments -Expected $expected
    }
    if ($Recipe) {
        if ($ListOnly) {
            Write-Output 'PLAN ONLY: recipe phase not executed'
        } else {
            # Canonical recipe identity: seed 7 / cap 60 / trade is the run that caught the crash.
            Invoke-RecipeCheck -Seed 7 -Cap 60 -Style 'trade'
        }
    }
    if ($routeMode -and -not $planOnly -and @($plan.gates) -contains 'content') {
        # The content gate is its own phase (docs/spec/check-routing.md §2.2): its exit code
        # and log are recorded in summary.route.gate_results and are not rule/UI conclusions.
        $gateLog = Join-Path $checkDirectory 'check-content.log'
        $gateOutput = ''
        $gateExit = 1
        try {
            $gateOutput = (& (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'check-content.ps1') 2>&1 | Out-String)
            $gateExit = $LASTEXITCODE
        } catch {
            $gateOutput = [string]$_.Exception.Message
            $gateExit = 1
        }
        [IO.File]::WriteAllText($gateLog, $gateOutput)
        $gateOutput -split '\r?\n' | Where-Object { $_ -match '^CONTENT ' } | Write-Output
        $gateResults = [ordered]@{ content = [ordered]@{ passed = ($gateExit -eq 0); exit = $gateExit; log = $gateLog } }
        if ($gateExit -ne 0) { $exitCode = 1; Write-Output 'ROUTE GATE FAILED: content (see the log above)' }
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
    # Route probes (docs/spec/check-routing.md §3.3): the plan is the review surface, so these
    # pin the decisions the plan host must make for the contract's example change sets. Each
    # probe runs this script again with -ChangedList ... -ListOnly and checks the printed plan.
    foreach ($routeProbe in @(
        @{ Name='route-ui-only'; Files=@('spire-godot/ui/main.gd')
           Must=@('(?m)^ROUTE ROW: spire-godot/ui/main\.gd -> rules=architecture ui=.*\[signals=symbol_ui\]\r?$', '(?m)^ROUTE RULE SCOPE: architecture\r?$') },
        @{ Name='route-content'; Files=@('spire-godot/content/packs/abandoned_storeroom.json')
           Must=@('(?m)^ROUTE DEFAULT: spire-godot/content/packs/abandoned_storeroom\.json \(blind, closure=spire-godot/content/\)\r?$', '(?m)^ROUTE UI SCOPE: \(none\)\r?$', '(?m)^ROUTE GATE: content ') },
        @{ Name='route-save'; Files=@('spire-godot/core/save_store.gd')
           Must=@('(?m)^ROUTE CORE APPEND: spire-godot/core/save_store\.gd \+= architecture,persistence,runner ', 'signals=preload,core-append', '(?m)^ROUTE RULE SCOPE: architecture,runner,persistence\r?$', '(?m)^ROUTE UI SCOPE: encyclopedia,home_persistence,home,interface,persistence\r?$') },
        @{ Name='route-snapshot-domain'; Files=@('spire-godot/core/snapshot.gd')
           Must=@('(?m)^ROUTE ROW: spire-godot/core/snapshot\.gd .*\[signals=domain,core-append\]\r?$', '(?m)^ROUTE RULE SCOPE: architecture,runner,persistence\r?$') },
        @{ Name='route-blind-closure'; Files=@('spire-godot/core/tool_rules.gd')
           Must=@('(?m)^ROUTE DEFAULT: spire-godot/core/tool_rules\.gd \(blind, closure=spire-godot/core/\)\r?$', '(?m)^ROUTE BLIND: spire-godot/core/tool_rules\.gd \(BLIND_BY_DESIGN: ', '(?m)^ROUTE RULE SCOPE: (?!.*normal_play).*\r?$') },
        @{ Name='route-unmapped-fail-closed'; Files=@('spire-godot/newdir/x.gd')
           Must=@('(?m)^ROUTE UNMAPPED: spire-godot/newdir/x\.gd \(no index edge and no closure; fail-closed to all-dev \+ all-dev-ui\)\r?$', '(?m)^ROUTE MILESTONE: declared baseline,normal_play; deducted in this plan: ') },
        @{ Name='route-declared-none'; Files=@('docs/spec/check-routing.md')
           Must=@('(?m)^ROUTE NONE: docs/spec/check-routing\.md \(outside the source fingerprint; no suites, never a pass\)\r?$', '(?m)^ROUTE RULE SCOPE: \(none\)\r?$') }
    )) {
        $probeName = $routeProbe.Name
        $probeListPath = Join-Path $checkDirectory ('probe-' + $probeName + '.txt')
        [IO.File]::WriteAllLines($probeListPath, $routeProbe.Files, [Text.UTF8Encoding]::new($false))
        $probeOutput = ''
        $probeExit = 1
        try {
            $probeOutput = (& $checkShell -NoProfile -File $PSCommandPath -ChangedList $probeListPath -ListOnly 2>&1 | Out-String)
            $probeExit = $LASTEXITCODE
        } catch {
            $probeOutput = [string]$_.Exception.Message
            $probeExit = 1
        }
        [IO.File]::WriteAllText((Join-Path $checkDirectory ('check-' + $probeName + '.log')), $probeOutput)
        if ($probeExit -ne 0) { throw "Route probe did not produce a usable plan: $probeName" }
        foreach ($pattern in $routeProbe.Must) {
            if ($probeOutput -notmatch $pattern) { throw "Route probe missed an expected plan line: $probeName / $pattern" }
        }
        Write-Output "CHECK ${probeName}: plan decisions verified"
    }
    # -ListOnly must equal the executed scope: compare the plan with the real run.
    $scopeListPath = Join-Path $checkDirectory 'probe-route-scope-matches.txt'
    [IO.File]::WriteAllLines($scopeListPath, @('spire-godot/tests/runner_cases.gd'), [Text.UTF8Encoding]::new($false))
    $scopeOutput = ''
    $scopeExit = 1
    try {
        $scopeOutput = (& $checkShell -NoProfile -File $PSCommandPath -ChangedList $scopeListPath 2>&1 | Out-String)
        $scopeExit = $LASTEXITCODE
    } catch {
        $scopeOutput = [string]$_.Exception.Message
        $scopeExit = 1
    }
    [IO.File]::WriteAllText((Join-Path $checkDirectory 'check-route-scope-matches.log'), $scopeOutput)
    if ($scopeExit -ne 0) { throw 'Route scope probe: the routed runner run did not finish green.' }
    $scopeSummaryPath = [regex]::Match($scopeOutput, '(?m)^SUMMARY: (.+)$').Groups[1].Value.Trim()
    if (-not $scopeSummaryPath) { throw 'Route scope probe: no summary.json was reported.' }
    $scopeSummary = Get-Content -LiteralPath $scopeSummaryPath -Raw | ConvertFrom-Json
    if ((@($scopeSummary.route.rules) -join ',') -ne (@($scopeSummary.rules.selected) -join ',')) { throw 'Route scope probe: the planned rule scope differs from the executed rule scope.' }
    if ((@($scopeSummary.route.ui) -join ',') -ne (@($scopeSummary.ui.selected) -join ',')) { throw 'Route scope probe: the planned UI scope differs from the executed UI scope.' }
    if ($scopeSummary.status -ne 'passed' -or $scopeSummary.route.mode -ne 'changed') { throw "Route scope probe: unexpected status or mode ($($scopeSummary.status)/$($scopeSummary.route.mode))." }
    Write-Output 'CHECK route-scope-matches: the planned scope equals the executed scope'
}

} catch {
    $exitCode = 1
    $failureMessage = $_.Exception.Message
    Write-Output $failureMessage
} finally {
    $afterFingerprint = Get-SourceFingerprint
    $rules = Get-PhaseSummary -Name rules -Requested $Suite -Enabled ($Suite.Count -gt 0 -and -not $UIOnly)
    $window = Get-PhaseSummary -Name ui -Requested $UISuite -Enabled ([bool]($UI -or $UIOnly))
    $recipe = Get-RecipePhaseSummary -Enabled $Recipe
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
        $recipe.retry = @($recipe.selected)
        Write-Output 'SOURCE CHANGED: results belong to a moving workspace; rerun after edits settle.'
    }
    $status = if ($ListOnly -and $exitCode -eq 0) { 'plan' } elseif ($changed -and -not $ListOnly) { 'source_changed' } elseif ($exitCode -eq 0) { 'passed' } else { 'failed' }
    if ($routeSummary) { $routeSummary['gate_results'] = $gateResults }
    # route is the only added key (docs/spec/check-routing.md §2.4): every existing key keeps
    # its shape and semantics, and a routed round is never a milestone pass.
    $summary = [ordered]@{ schema=1; status=$status; error=$failureMessage; impact=[bool]$Impact; exhaustive=[bool]($Exhaustive -or 'all' -in $Suite); verify_runner=[bool]$VerifyRunner; before=$beforeFingerprint; after=$afterFingerprint; rules=$rules; ui=$window; recipe=$recipe; docs=$documentGate; route=$routeSummary }
    $summaryPath = Join-Path $checkDirectory 'summary.json'
    [IO.File]::WriteAllText($summaryPath, ($summary | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    Write-Output ('SUMMARY: ' + $summaryPath)
    if ($exitCode -ne 0) {
        # A document-only failure leaves no suite to rerun, and -RerunFailed refuses such a round.
        if (($rules.retry.Count + $window.retry.Count + $recipe.retry.Count) -gt 0) { Write-Output ('.\tools\check.ps1 -RerunFailed "' + $checkDirectory + '"') }
    }
}
exit $exitCode
