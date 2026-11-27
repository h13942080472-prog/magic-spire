#Requires -Version 7.0
# Test harness for tests/update_cases.gd::update_manifest_patch_entries_are_judged: runs the real
# tools/update-manifest-check.ps1::Assert-UpdateManifest on one manifest file and prints the verdict.
# It judges nothing itself; the rejection text is the one Assert-UpdateManifest throws.
param(
    [Parameter(Mandatory)][string]$Check,
    [Parameter(Mandatory)][string]$Path
)
$ErrorActionPreference = 'Stop'
. $Check
try {
    $count = Assert-UpdateManifest -Path $Path
    Write-Output "MANIFEST OK: $count bytes"
} catch {
    Write-Output ('MANIFEST REJECTED: ' + $_.Exception.Message)
    exit 1
}
