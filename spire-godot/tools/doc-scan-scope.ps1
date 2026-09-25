# Rule-class document scan scope: the single declaration consumed by tools/check.ps1
# (source fingerprint) and tools/check-docs.ps1 (document reference gate).
#
# Invariant: the guarded document set has exactly one definition. Adding a document that states
# current rules means adding its root here, not a second list in a consumer.
#
# Rule-class = documents that state what currently holds: docs/spec, docs/design, docs/guide,
# root AGENTS.md and the project skills' markdown.
#
# Excluded, with reasons:
#  - docs/record/**: append-only records. Every verification entry churns them, so guarding them
#    would flag unrelated check runs as source changes while adding no rule coverage.
#    docs/record/proposals/** is inside this tree and is excluded for the same reason (unlanded
#    proposals are not current rules).
#  - docs/history/**: read-only archive of superseded decisions; not current instruction.
$RuleDocumentDirectoryRoots = @('docs/spec', 'docs/design', 'docs/guide', '.zcode/skills')
$RuleDocumentFilePaths = @('AGENTS.md')

function Get-RuleDocFiles {
    param([Parameter(Mandatory)][string]$RepositoryRoot)
    $files = [Collections.Generic.List[string]]::new()
    foreach ($relative in $RuleDocumentDirectoryRoots) {
        $directory = Join-Path $RepositoryRoot $relative
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) { continue }
        Get-ChildItem -LiteralPath $directory -File -Recurse -Filter '*.md' |
            ForEach-Object { $files.Add($_.FullName) }
    }
    foreach ($relative in $RuleDocumentFilePaths) {
        $file = Join-Path $RepositoryRoot $relative
        if (Test-Path -LiteralPath $file -PathType Leaf) { $files.Add($file) }
    }
    return @($files | Sort-Object)
}
