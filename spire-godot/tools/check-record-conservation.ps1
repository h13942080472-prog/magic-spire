param(
    [string]$Base = '8e83876'
)
$ErrorActionPreference = 'Stop'

# Record-conservation check -- MIGRATION-PERIOD script, deliberately not wired into check.ps1.
# It compares each verification volume (docs/record/verification*.md) against a base revision and
# reports four conservation classes. A verification volume is an append-only record of what was
# actually run; losing an identifier, rewriting a kept sentence or dropping a failure/unrun line
# destroys traceability that no other gate can restore (docs/record/** is outside the source
# fingerprint). The keep-filter white list this check enforces lives in
# skills/spire-docs/SKILL.md, section "记录诚实".
#   1. identifiers : run ids (\d{8}T\d{9}-\d+), 40/64-hex values and build//outputs/ evidence paths
#                    present in Base must still be present in the current file.
#   2. verbatim    : every current body sentence inside a section that also exists in Base must be
#                    a verbatim fragment (split at 。！？) of the Base text; rewrites fail.
#   3. structure   : Base headings, heading dates and 域 lines must all still exist. Extra current
#                    lines are appended records, reported as additions, not failures.
#   4. marker lines: Base sentences carrying 失败／未跑／未验证／不作证 must still exist or be
#                    listed in $markerAllowlist with a reason and a removal condition.
# Exit is non-zero when any class has a non-empty difference set.
# Usage (module root): & tools/check-record-conservation.ps1 [-Base <rev>]

try { [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false) } catch { }

$gameDirectory = Split-Path -Parent $PSScriptRoot
$repositoryRoot = Split-Path -Parent $gameDirectory
$volumes = @(
    'docs/record/verification.md',
    'docs/record/verification-2026-09-13.md',
    'docs/record/verification-2026-09-12-and-earlier.md'
)

# Declared losses that may stay missing. Every entry carries why it is allowed and the condition
# that removes it; the entry count is printed on every run. The list may only shrink; adding an
# entry requires a verification-record entry naming the reason.
$markerAllowlist = [ordered]@{
    '作者侧 `修复18条基线失败` 与原文登记的既有红项并存，两侧原文均保留。' =
        'preamble sentence of the 2026-09-18 merge volume, replaced wholesale by the 2026-10-05 evidence-index header; original text is in git history 8e83876. Removal condition: the header re-includes this sentence or its fact lands elsewhere.'
}

$runIdPattern = '\b\d{8}T\d{9}-\d+\b'
$hexPattern = '(?<![0-9A-Za-z])(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})(?![0-9A-Za-z])'
$evidencePathPattern = '(?<![\w/.])(?:spire-godot/)?(?:build|outputs)/[A-Za-z0-9_./*?\-]*[A-Za-z0-9_]'
$markerPattern = '失败|未跑|未验证|不作证'
$listMarkerPattern = '^\s*(?:[-*※]|\d+[.、)])\s+'

$usedAllowlist = @{}

function Get-TextFile {
    param([string]$AbsolutePath)
    return [IO.File]::ReadAllText($AbsolutePath)
}

function Get-BaseText {
    # git stdout is decoded with [Console]::OutputEncoding, set to UTF-8 above; stderr is left on
    # the error stream so a missing revision fails the $LASTEXITCODE guard instead of throwing.
    param([string]$Revision, [string]$RelativePath)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & git --no-pager -C $repositoryRoot show ('{0}:{1}' -f $Revision, $RelativePath)
    $exit = $LASTEXITCODE
    $ErrorActionPreference = $previous
    if ($exit -ne 0) { throw ('cannot read {0} at revision {1}' -f $RelativePath, $Revision) }
    return (@($output) -join "`n")
}

function Get-HeadingLines {
    param([string]$Text)
    return @($Text -split "`n" | Where-Object { $_.Trim().StartsWith('## ') } | ForEach-Object { $_.Trim() })
}

function Get-DomainLines {
    param([string]$Text)
    return @($Text -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_.StartsWith('域：') })
}

function Get-Sentences {
    # Body sentences outside headings: list markers stripped, fragments split after 。！？
    # -IncludePreamble keeps text above the first '## ' heading (headers are rewritten, not
    # compressed); -AllowedHeadings restricts the scan to sections that exist in the base version.
    param(
        [string]$Text,
        [switch]$IncludePreamble,
        [string[]]$AllowedHeadings
    )
    $result = [Collections.Generic.List[string]]::new()
    $section = ''
    foreach ($rawLine in ($Text -split "`n")) {
        $line = $rawLine.Trim()
        if ($line.StartsWith('## ')) { $section = $line; continue }
        if ($line.StartsWith('#')) { continue }
        if ($line -eq '' -or $line -match '^[\s\-|]+$') { continue }
        if (-not $IncludePreamble -and $section -eq '') { continue }
        if ($AllowedHeadings -and $section -notin $AllowedHeadings) { continue }
        $body = [regex]::Replace($line, $listMarkerPattern, '').Trim().Trim('|').Trim()
        if ($body -eq '') { continue }
        foreach ($piece in [regex]::Split($body, '(?<=[。！？])')) {
            $sentence = $piece.Trim().Trim('|').Trim()
            if ($sentence.Length -gt 1) { $result.Add($sentence) }
        }
    }
    return @($result)
}

function Get-MissingIdentifiers {
    # Every identifier-shaped token of Base must still exist verbatim in the current file: an id or
    # evidence path is what a reader follows to re-open the corresponding run.
    param([string]$BaseText, [string]$CurrentText)
    $missing = [Collections.Generic.List[string]]::new()
    foreach ($pattern in @($runIdPattern, $hexPattern, $evidencePathPattern)) {
        foreach ($match in [regex]::Matches($BaseText, $pattern)) {
            $token = $match.Value
            if ($token -ne '' -and -not $CurrentText.Contains($token) -and -not $missing.Contains($token)) {
                $missing.Add($token)
            }
        }
    }
    return @($missing)
}

$totalDifferences = 0
foreach ($volume in $volumes) {
    $absolutePath = Join-Path $repositoryRoot $volume
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) { throw ('missing volume ' + $volume) }
    $baseText = Get-BaseText -Revision $Base -RelativePath $volume
    if (-not $baseText.Contains('域：')) { throw ('base text for {0} did not decode as UTF-8' -f $volume) }
    $currentText = Get-TextFile -AbsolutePath $absolutePath

    $baseHeadings = @(Get-HeadingLines -Text $baseText)
    $currentHeadings = @(Get-HeadingLines -Text $currentText)

    # 1. identifiers
    $missingIdentifiers = @(Get-MissingIdentifiers -BaseText $baseText -CurrentText $currentText)
    # 2. verbatim (sections shared with Base only; the rewritten header and new sections are skips)
    $checkedSentences = @(Get-Sentences -Text $currentText -AllowedHeadings $baseHeadings)
    $nonVerbatim = @($checkedSentences | Where-Object { -not $baseText.Contains($_) })
    $skippedSections = @($currentHeadings | Where-Object { $_ -notin $baseHeadings })
    # 3. structure
    $missingHeadings = @($baseHeadings | Where-Object { $_ -notin $currentHeadings })
    $extraHeadings = @($currentHeadings | Where-Object { $_ -notin $baseHeadings })
    $baseDates = @($baseHeadings | ForEach-Object { [regex]::Matches($_, '\d{4}-\d{2}-\d{2}') } | ForEach-Object { $_.Value } | Select-Object -Unique)
    $currentDates = @($currentHeadings | ForEach-Object { [regex]::Matches($_, '\d{4}-\d{2}-\d{2}') } | ForEach-Object { $_.Value } | Select-Object -Unique)
    $missingDates = @($baseDates | Where-Object { $_ -notin $currentDates })
    $baseDomains = @(Get-DomainLines -Text $baseText)
    $currentDomains = @(Get-DomainLines -Text $currentText)
    $missingDomains = @($baseDomains | Where-Object { $_ -notin $currentDomains })
    # 4. failure/unrun marker sentences
    $baseMarkers = @(Get-Sentences -Text $baseText -IncludePreamble | Where-Object { $_ -match $markerPattern })
    $missingMarkers = [Collections.Generic.List[string]]::new()
    foreach ($markerSentence in $baseMarkers) {
        if ($currentText.Contains($markerSentence)) { continue }
        if ($markerAllowlist.Contains($markerSentence)) {
            $script:usedAllowlist[$markerSentence] = $true
            continue
        }
        $missingMarkers.Add($markerSentence)
    }

    foreach ($item in $missingIdentifiers) { Write-Output ('CONSERVE MISS [identifiers] {0}: {1}' -f $volume, $item) }
    foreach ($item in $nonVerbatim) { Write-Output ('CONSERVE MISS [verbatim] {0}: {1}' -f $volume, $item) }
    foreach ($item in $missingHeadings) { Write-Output ('CONSERVE MISS [headings] {0}: {1}' -f $volume, $item) }
    foreach ($item in $missingDates) { Write-Output ('CONSERVE MISS [dates] {0}: {1}' -f $volume, $item) }
    foreach ($item in $missingDomains) { Write-Output ('CONSERVE MISS [domains] {0}: {1}' -f $volume, $item) }
    foreach ($item in $missingMarkers) { Write-Output ('CONSERVE MISS [markers] {0}: {1}' -f $volume, $item) }
    if ($extraHeadings.Count -gt 0) {
        Write-Output ('CONSERVE ADD [headings] {0}: {1} appended section(s), allowed by append-only records' -f $volume, $extraHeadings.Count)
    }

    $differences = $missingIdentifiers.Count + $nonVerbatim.Count + $missingHeadings.Count + $missingDates.Count + $missingDomains.Count + $missingMarkers.Count
    $totalDifferences += $differences
    Write-Output ('CONSERVE SUMMARY {0}: identifiers={1} non_verbatim={2} headings={3} dates={4} domains={5} markers={6} (sentences_checked={7}, new_sections_skipped={8}, appended_headings={9})' -f `
        $volume, $missingIdentifiers.Count, $nonVerbatim.Count, $missingHeadings.Count, $missingDates.Count, $missingDomains.Count, $missingMarkers.Count, `
        $checkedSentences.Count, $skippedSections.Count, $extraHeadings.Count)
}

foreach ($entry in $markerAllowlist.Keys) {
    if (-not $usedAllowlist.ContainsKey($entry)) {
        Write-Output ('CONSERVE NOTE: allowlist entry is no longer referenced: ' + $entry)
    }
}

if ($totalDifferences -gt 0) {
    Write-Output ('CONSERVE FAIL: {0} difference(s) against {1}; allowlist {2} entrie(s)' -f $totalDifferences, $Base, $markerAllowlist.Count)
    exit 1
}
Write-Output ('CONSERVE PASS: {0} volume(s) conserve identifiers, verbatim sentences, structure and marker lines against {1}; allowlist {2} entrie(s)' -f $volumes.Count, $Base, $markerAllowlist.Count)
exit 0
