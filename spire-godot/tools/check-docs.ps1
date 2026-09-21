param([switch]$ListTokens)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc-scan-scope.ps1')
$gameDirectory = Split-Path -Parent $PSScriptRoot
$repositoryRoot = Split-Path -Parent $gameDirectory

# Document reference gate for rule-class documents (scope declared in tools/doc-scan-scope.ps1).
# Three reference classes are enforced:
#  1. named repository paths must exist: root-relative (spire-godot/, docs/, .zcode/, release/)
#     or module-relative (tools/, tests/, core/, data/, ui/, assets/, content/, packaging/,
#     build/), per the "路径约定" stated at the top of docs/spec/*.md.
#  2. file::symbol anchors must be declared in the named file (GDScript func/var/const/signal/
#     class_name/enum, PowerShell function/dollar-variable).
#  3. markdown relative links must resolve to an existing local file.
#
# Boundaries (deliberately not guarded here):
#  - build/ and outputs/ paths: git-ignored transient evidence and artifact directories; docs
#    name run-scoped evidence there (see docs/spec/project-map.md), so they are not stable
#    content and cannot be required to exist.
#  - deleting a dependency-table row whose remaining rows still exist: detecting that needs the
#    implemented file face as a second source of truth; this gate only checks that names resolve.
#  - markdown heading anchors (#fragment): only the target file is checked.
#  - tokens that are neither `<root>/.../<name>.<letter-ext>` nor `<root>/.../` are prose
#    fragments and are not treated as references.
#  - symbol kinds other than GDScript and PowerShell: file existence only, reported as a note.
#
# -ListTokens prints every accepted, skipped and allowed token for triage.

# Declared-missing references. Every entry carries why it is allowed and the condition that
# removes it. The list may only shrink; adding an entry requires a verification-record entry
# naming the reason. The entry count is printed on every run so the debt stays visible.
$declaredMissing = [ordered]@{
    'core/candidate_deps.gd'             = 'docs/spec/candidate-delta.md declares this slice not landed (header, 2026-09-18); removal condition: that slice lands.'
    'ui/candidate_delta.gd'              = 'same not-landed slice as core/candidate_deps.gd; removal condition: that slice lands.'
    'tools/candidate-deps.ps1'           = 'same not-landed slice as core/candidate_deps.gd; removal condition: that slice lands.'
    'tools/check-index.ps1'              = 'belongs to the unlanded check-routing slice (docs/record/proposals/check-routing-and-per-click-checks.md); removal condition: that slice lands.'
    'tests/check_index.json'             = 'unlanded check-routing slice freeze file; removal condition: that slice lands.'
    'tests/check_index*.gd'              = 'unlanded check-routing slice test files; removal condition: that slice lands.'
}

$repositoryPrefixes = @('spire-godot', 'docs', '.zcode', 'release', 'outputs')
$modulePrefixes = @('tools', 'tests', 'core', 'data', 'ui', 'assets', 'content', 'packaging', 'build')
$rootDirectoryNames = @('spire-godot', 'docs', '.zcode', 'release', 'outputs') + $modulePrefixes
$rootAlternation = '(?:spire-godot|docs|\.zcode|release|outputs|tools|tests|core|data|ui|assets|content|packaging|build)'
$evidenceDirectories = @(
    (Join-Path $gameDirectory 'build'),
    (Join-Path $repositoryRoot 'build'),
    (Join-Path $repositoryRoot 'outputs')
)
# File references stop at the first dotted extension: `core/game.gd.new(42)` in a contract names
# core/game.gd, and `release-v0.18.1.txt` keeps all version dots because numeric segments are not
# extensions (the extension must start with a letter).
$pathTokenPatterns = @(
    ('(?<![\w./\\-])' + $rootAlternation + '/[A-Za-z0-9_./*?\-]*?\.[A-Za-z][A-Za-z0-9]{0,7}'),
    ('(?<![\w./\\-])' + $rootAlternation + '/[A-Za-z0-9_./*?\-]*/')
)
$anchorPattern = '(?<![\w./\\-])([A-Za-z0-9_./*?\-]+\.(?:gd|ps1|py))::([A-Za-z_*][A-Za-z0-9_*\-]*)'
$linkPattern = '\[[^\]]*\]\(([^)\s]+)\)'
$gdDeclarationPattern = '(?m)^[ \t]*(?:@[A-Za-z_][A-Za-z0-9_]*(?:\([^)\r\n]*\))?[ \t]*)*(?:static[ \t]+)?(?:func|var|const|signal|class_name|enum)[ \t]+([A-Za-z_][A-Za-z0-9_]*)'
$psFunctionPattern = '(?m)^[ \t]*function[ \t]+([A-Za-z_][A-Za-z0-9_\-]*)'
$psVariablePattern = '(?m)^[ \t]*(?:\[[^\]]+\][ \t]*)?\$([A-Za-z_][A-Za-z0-9_]*)[ \t]*='

$problems = [Collections.Generic.List[string]]::new()
$usedMissing = @{}
$checkedReferences = 0

function Add-Problem {
    param([string]$Document, [string]$Token, [string]$Reason)
    if ($declaredMissing.Contains($Token)) {
        $script:usedMissing[$Token] = $true
        if ($ListTokens) { Write-Output ('DOC ALLOW: {0}: {1}' -f $Document, $Token) }
        return
    }
    $script:problems.Add(('DOC FAIL: {0}: {1} ({2})' -f $Document, $Token, $Reason))
}

function Resolve-RepositoryPath {
    # Maps a documented path token to an absolute path; $null means the token is not a repository
    # path (prose fragment). Every path root is consumed here, never at call sites.
    param([string]$Token)
    foreach ($prefix in $repositoryPrefixes) {
        if ($Token -eq $prefix -or $Token.StartsWith($prefix + '/')) { return (Join-Path $repositoryRoot $Token) }
    }
    foreach ($prefix in $modulePrefixes) {
        if ($Token -eq $prefix -or $Token.StartsWith($prefix + '/')) { return (Join-Path $gameDirectory $Token) }
    }
    return $null
}

function Test-EvidencePath {
    # build/ and outputs/ hold run-scoped evidence and artifacts; they are not stable content.
    param([string]$Path)
    foreach ($directory in $evidenceDirectories) {
        if ($Path -eq $directory -or $Path.StartsWith($directory + [IO.Path]::DirectorySeparatorChar)) { return $true }
    }
    return $false
}

function Test-NamedPathExists {
    # Wildcards mean "this file family exists": the directory part is walked to its longest
    # wildcard-free prefix, then the leaf is matched by name (recursively, so `**` and a wildcard
    # directory segment such as `.zcode/skills/*/SKILL.md` both work).
    param([string]$Path)
    if (-not ($Path.Contains('*') -or $Path.Contains('?'))) { return (Test-Path -LiteralPath $Path) }
    $directoryForm = $Path.EndsWith('/') -or $Path.EndsWith('\')
    $trimmed = $Path.TrimEnd('/', '\')
    $leaf = Split-Path -Leaf $trimmed
    $basePath = Split-Path -Parent $trimmed
    if (-not $leaf -or -not $basePath) { return $false }
    $segments = @($basePath -split '[\\/]')
    $base = [Collections.Generic.List[string]]::new()
    $recursive = $false
    foreach ($segment in $segments) {
        if ($segment.Contains('*') -or $segment.Contains('?')) { $recursive = $true; break }
        $base.Add($segment)
    }
    $wildcardBase = $base -join [IO.Path]::DirectorySeparatorChar
    if (-not $wildcardBase -or -not (Test-Path -LiteralPath $wildcardBase -PathType Container)) { return $false }
    $options = @{ LiteralPath = $wildcardBase }
    if (-not $directoryForm) { $options['File'] = $true }
    if ($recursive -or $directoryForm) { $options['Recurse'] = $true }
    return @(Get-ChildItem @options | Where-Object { $_.Name -like $leaf }).Count -gt 0
}

function Get-DeclaredSymbols {
    param([string]$Path)
    $extension = [IO.Path]::GetExtension($Path)
    if ($extension -notin @('.gd', '.ps1')) { return @() }
    $text = [IO.File]::ReadAllText($Path)
    $names = [Collections.Generic.List[string]]::new()
    if ($extension -eq '.gd') {
        foreach ($match in [regex]::Matches($text, $gdDeclarationPattern)) { $names.Add($match.Groups[1].Value) }
    } else {
        foreach ($match in [regex]::Matches($text, $psFunctionPattern)) { $names.Add($match.Groups[1].Value) }
        foreach ($match in [regex]::Matches($text, $psVariablePattern)) { $names.Add($match.Groups[1].Value) }
    }
    return @($names)
}

function Test-SymbolDeclared {
    # Compound anchors (`file.gd::TYPES/ENCOUNTERS`) and wildcards (`::PRISON_*`) are supported;
    # segment matching is case-sensitive because GDScript symbol names are.
    param([string[]]$Declared, [string]$Symbol)
    foreach ($segment in ($Symbol -split '/')) {
        if (-not $segment) { continue }
        $found = $false
        foreach ($name in $Declared) {
            if ($name -clike $segment) { $found = $true; break }
        }
        if (-not $found) { return $false }
    }
    return $true
}

# Bare anchor targets (`witch_character.gd::relic_allowed`) resolve by file name inside the
# module; ambiguous names are accepted when any candidate declares the symbol.
$anchorIndex = @{}
foreach ($directory in @('core', 'data', 'ui', 'tests', 'tools')) {
    $absolute = Join-Path $gameDirectory $directory
    if (-not (Test-Path -LiteralPath $absolute -PathType Container)) { continue }
    Get-ChildItem -LiteralPath $absolute -File -Recurse |
        Where-Object { $_.Extension -in @('.gd', '.ps1', '.py') } | ForEach-Object {
            if (-not $anchorIndex.ContainsKey($_.Name)) { $anchorIndex[$_.Name] = @() }
            $anchorIndex[$_.Name] = @($anchorIndex[$_.Name]) + $_.FullName
        }
}

$documents = @(Get-RuleDocFiles -RepositoryRoot $repositoryRoot)
foreach ($document in $documents) {
    $documentName = $document.Substring($repositoryRoot.Length + 1)
    $documentDirectory = Split-Path -Parent $document
    $text = [IO.File]::ReadAllText($document)

    foreach ($pattern in $pathTokenPatterns) {
        foreach ($match in [regex]::Matches($text, $pattern)) {
            $token = $match.Value.TrimEnd('.', ',', ';', ':')
            if (-not $token) { continue }
            $segments = @($token.Trim('/') -split '/')
            if ($segments.Count -ge 3 -and @($segments | Where-Object { $_ -notin $rootDirectoryNames }).Count -eq 0) {
                if ($ListTokens) { Write-Output ('DOC SKIP: {0}: {1} (directory enumeration, not a path)' -f $documentName, $token) }
                continue
            }
            $resolved = Resolve-RepositoryPath -Token $token
            if ($null -eq $resolved -or (Test-EvidencePath -Path $resolved)) { continue }
            $checkedReferences++
            if (Test-NamedPathExists -Path $resolved) {
                if ($ListTokens) { Write-Output ('DOC PASS: {0}: {1}' -f $documentName, $token) }
                continue
            }
            Add-Problem -Document $documentName -Token $token -Reason 'named path does not exist'
        }
    }

    foreach ($match in [regex]::Matches($text, $anchorPattern)) {
        $target = $match.Groups[1].Value
        $symbol = $match.Groups[2].Value.TrimEnd('-', '/')
        if (-not $symbol) { continue }
        $token = $target + '::' + $symbol
        $candidates = @()
        if ($target.Contains('/')) {
            $resolved = Resolve-RepositoryPath -Token $target
            if ($resolved -and -not (Test-EvidencePath -Path $resolved) -and (Test-Path -LiteralPath $resolved -PathType Leaf)) { $candidates = @($resolved) }
        } elseif ($anchorIndex.ContainsKey($target)) {
            $candidates = @($anchorIndex[$target])
        }
        $checkedReferences++
        if ($candidates.Count -eq 0) {
            Add-Problem -Document $documentName -Token $token -Reason 'anchored file does not exist'
            continue
        }
        if ([IO.Path]::GetExtension($candidates[0]) -notin @('.gd', '.ps1')) {
            Write-Output ('DOC NOTE: {0}: {1} (symbol check unsupported for this file type; file exists)' -f $documentName, $token)
            continue
        }
        $declared = @()
        foreach ($candidate in $candidates) { $declared += Get-DeclaredSymbols -Path $candidate }
        if (Test-SymbolDeclared -Declared $declared -Symbol $symbol) {
            if ($ListTokens) { Write-Output ('DOC PASS: {0}: {1}' -f $documentName, $token) }
            continue
        }
        Add-Problem -Document $documentName -Token $token -Reason 'symbol is not declared in the anchored file'
    }

    foreach ($match in [regex]::Matches($text, $linkPattern)) {
        $target = $match.Groups[1].Value
        if ($target -match '^[A-Za-z][A-Za-z0-9+.\-]*:' -or $target.StartsWith('#')) { continue }
        $path = ($target -split '#')[0]
        if (-not $path) { continue }
        $relative = [Uri]::UnescapeDataString($path).Replace('/', [IO.Path]::DirectorySeparatorChar)
        $resolved = Join-Path $documentDirectory $relative
        $checkedReferences++
        if (Test-Path -LiteralPath $resolved) {
            if ($ListTokens) { Write-Output ('DOC PASS: {0}: {1}' -f $documentName, $target) }
            continue
        }
        Add-Problem -Document $documentName -Token $target -Reason 'relative link target does not exist'
    }
}

foreach ($token in $declaredMissing.Keys) {
    if (-not $usedMissing.ContainsKey($token)) {
        Write-Output ('DOC NOTE: declared-missing entry is no longer referenced: ' + $token)
    }
}
foreach ($problem in $problems) { Write-Output $problem }
if ($problems.Count -gt 0) {
    Write-Output ('DOCS FAIL: {0} unresolved reference(s) in rule-class documents; allowlist {1} entrie(s)' -f $problems.Count, $declaredMissing.Count)
    exit 1
}
Write-Output ('DOCS PASS: {0} rule-class document(s), {1} reference(s) checked, allowlist {2} entrie(s)' -f $documents.Count, $checkedReferences, $declaredMissing.Count)
exit 0
