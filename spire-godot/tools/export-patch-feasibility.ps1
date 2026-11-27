#Requires -Version 7.0
# docs/spec/update-check.md「发布侧脚本」: the judgement of whether a patch pack may exist for a
# baseline release package. tools/export-patch.ps1 dot-sources this file and is its only caller;
# dot-sourcing only defines functions. The judgement is split from the export so it can run (and
# be tested) without starting the engine.
#
# Each refusal is {Gate, Detail}; the gates are the closed list below, and an empty result means
# "feasible". An input that cannot be read is itself a refusal: nothing here defaults to "allowed".
#   package              the baseline package is not the one the version claims (manifest, main pack)
#   baseline-unavailable the baseline sources cannot be fetched
#   baseline-no-boot     the baseline has no boot scene/closure, so it cannot mount a patch
#   content-packs        content/packs differs from the baseline package (hash, added or removed file)
#   project-settings     project.godot differs beyond config/version
#   export-presets       export_presets.cfg differs beyond the version fields
#   engine               the engine that builds the patch is not the one that built the baseline
#   boot-closure         a file the boot scene loads before mounting differs (that code can never
#                        be replaced by a patch: it is loaded and cached before the mount)

# The files loaded before a patch is mounted. update_keys.gd is listed although boot.gd does not
# preload it: the public keys may only change with a full package.
$script:PatchBootClosure = @('update/boot.gd', 'update/boot.tscn', 'update/update_store.gd', 'update/update_manifest.gd', 'update/update_keys.gd')
# Export-preset lines that carry the version and are therefore allowed to differ.
$script:PatchPresetVersionKeys = @('application/file_version', 'application/product_version', 'version/code', 'version/name')
$script:PatchMainScene = 'run/main_scene="res://update/boot.tscn"'

function New-PatchRefusal {
    param([string]$Gate, [string]$Detail)
    return [pscustomobject]@{ Gate = $Gate; Detail = $Detail }
}

# Text with LF line ends, so a checkout's line ends never decide a comparison.
function Read-PatchText {
    param([string]$Path)
    return [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false, $true)).Replace("`r`n", "`n")
}

function Get-PatchFileSha256 {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

# The package manifest written by tools/package.ps1 and the main pack it lists.
function Test-PatchBasePackage {
    param([string]$BasePackage, [string]$BaseVersion)
    $manifestPath = Join-Path $BasePackage 'manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { return , @(New-PatchRefusal 'package' "no manifest.json in $BasePackage") }
    try { $manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json -ErrorAction Stop }
    catch { return , @(New-PatchRefusal 'package' "manifest.json is not JSON: $($_.Exception.Message)") }
    $refusals = @()
    if ([string]$manifest.version -cne $BaseVersion) { $refusals += New-PatchRefusal 'package' "manifest.json is version '$($manifest.version)', not -BaseVersion '$BaseVersion'" }
    if ([string]$manifest.platform -cne 'windows-x64') { $refusals += New-PatchRefusal 'package' "manifest.json is platform '$($manifest.platform)', not windows-x64" }
    $packs = @(Get-ChildItem -LiteralPath $BasePackage -File -Filter '*.pck')
    if ($packs.Count -ne 1) { return , @($refusals + (New-PatchRefusal 'package' "the package must hold exactly one main .pck beside its manifest, found $($packs.Count)")) }
    $listed = @($manifest.files | Where-Object { ([string]$_.path).Replace('\', '/') -ceq $packs[0].Name })
    if ($listed.Count -ne 1) { return , @($refusals + (New-PatchRefusal 'package' "manifest.json does not list $($packs[0].Name) exactly once")) }
    if ([long]$listed[0].bytes -ne $packs[0].Length -or [string]$listed[0].sha256 -cne (Get-PatchFileSha256 $packs[0].FullName)) {
        $refusals += New-PatchRefusal 'package' "$($packs[0].Name) is not the file manifest.json describes (bytes or sha256 differ)"
    }
    return , $refusals
}

# content/packs: the shipped files of the target tree against the baseline package's own list.
# package.ps1 copies every file below content/packs except *.txt, so the same set is compared.
function Test-PatchContentPacks {
    param([string]$BasePackage, [string]$ProjectRoot)
    $manifest = [IO.File]::ReadAllText((Join-Path $BasePackage 'manifest.json')) | ConvertFrom-Json
    $prefix = 'content/packs/'
    $baseline = @{}
    foreach ($file in @($manifest.files)) {
        $path = ([string]$file.path).Replace('\', '/')
        if ($path.StartsWith($prefix, [StringComparison]::Ordinal)) { $baseline[$path.Substring($prefix.Length)] = [string]$file.sha256 }
    }
    if ($baseline.Count -eq 0) { return , @(New-PatchRefusal 'content-packs' 'the baseline package manifest lists no content/packs file, so nothing can be compared') }
    $root = Join-Path $ProjectRoot 'content/packs'
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { return , @(New-PatchRefusal 'content-packs' "no content/packs in $ProjectRoot") }
    $current = @{}
    foreach ($file in Get-ChildItem -LiteralPath $root -File -Recurse | Where-Object Extension -ne '.txt') {
        $current[[IO.Path]::GetRelativePath($root, $file.FullName).Replace('\', '/')] = Get-PatchFileSha256 $file.FullName
    }
    $changed = @($current.Keys | Where-Object { $baseline.ContainsKey($_) -and $baseline[$_] -cne $current[$_] } | Sort-Object)
    $added = @($current.Keys | Where-Object { -not $baseline.ContainsKey($_) } | Sort-Object)
    $removed = @($baseline.Keys | Where-Object { -not $current.ContainsKey($_) } | Sort-Object)
    if ($changed.Count + $added.Count + $removed.Count -eq 0) { return , @() }
    return , @(New-PatchRefusal 'content-packs' ("content/packs differs from the baseline package: changed=[" + (($changed | Select-Object -First 5) -join ', ') + "] added=[" + (($added | Select-Object -First 5) -join ', ') + "] removed=[" + (($removed | Select-Object -First 5) -join ', ') + ']'))
}

# project.godot: identical except the config/version line.
function Test-PatchProjectSettings {
    param([string]$BaseSources, [string]$ProjectRoot)
    $strip = { param($text) @($text.Split("`n") | Where-Object { $_ -notmatch '^config/version=' }) }
    $left = & $strip (Read-PatchText (Join-Path $BaseSources 'project.godot'))
    $right = & $strip (Read-PatchText (Join-Path $ProjectRoot 'project.godot'))
    for ($index = 0; $index -lt [Math]::Max($left.Count, $right.Count); $index++) {
        $a = if ($index -lt $left.Count) { $left[$index] } else { '<end>' }
        $b = if ($index -lt $right.Count) { $right[$index] } else { '<end>' }
        if ($a -cne $b) { return , @(New-PatchRefusal 'project-settings' "project.godot differs beyond config/version at line $($index + 1): baseline '$a' vs target '$b'") }
    }
    return , @()
}

# export_presets.cfg: identical once the version fields are dropped and the version spelled in
# preset names and descriptions is replaced by a placeholder.
function Test-PatchExportPresets {
    param([string]$BaseSources, [string]$ProjectRoot, [string]$BaseVersion, [string]$TargetVersion)
    $normalize = {
        param($text, $version)
        @($text.Split("`n") | Where-Object { $line = $_; -not ($script:PatchPresetVersionKeys | Where-Object { $line.StartsWith($_ + '=', [StringComparison]::Ordinal) }) } | ForEach-Object { $_.Replace($version, '<version>') })
    }
    $left = & $normalize (Read-PatchText (Join-Path $BaseSources 'export_presets.cfg')) $BaseVersion
    $right = & $normalize (Read-PatchText (Join-Path $ProjectRoot 'export_presets.cfg')) $TargetVersion
    for ($index = 0; $index -lt [Math]::Max($left.Count, $right.Count); $index++) {
        $a = if ($index -lt $left.Count) { $left[$index] } else { '<end>' }
        $b = if ($index -lt $right.Count) { $right[$index] } else { '<end>' }
        if ($a -cne $b) { return , @(New-PatchRefusal 'export-presets' "export_presets.cfg differs beyond the version fields at line $($index + 1): baseline '$a' vs target '$b'") }
    }
    return , @()
}

function Test-PatchBootClosure {
    param([string]$BaseSources, [string]$ProjectRoot)
    $refusals = @()
    foreach ($path in $script:PatchBootClosure) {
        $target = Join-Path $ProjectRoot $path
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { $refusals += New-PatchRefusal 'boot-closure' "$path is missing from the target tree"; continue }
        if ((Read-PatchText (Join-Path $BaseSources $path)) -cne (Read-PatchText $target)) { $refusals += New-PatchRefusal 'boot-closure' "$path differs from the baseline (the boot closure is loaded before any patch mounts and can only change with a full package)" }
    }
    return , $refusals
}

# The whole judgement. $BaseSources is a directory holding the baseline's project.godot,
# export_presets.cfg and boot closure at their project-relative paths (tools/export-patch.ps1
# fetches them from the baseline version's git objects); $EngineVersion is the engine that would
# build the patch. Returns every refusal, in a fixed order.
function Test-PatchFeasibility {
    param([string]$BasePackage, [string]$BaseVersion, [string]$BaseSources, [string]$ProjectRoot, [string]$TargetVersion, [string]$EngineVersion)
    $refusals = Test-PatchBasePackage $BasePackage $BaseVersion
    $packageUsable = $refusals.Count -eq 0
    # Baseline sources: unreadable -> refusal; no boot scene or closure -> the baseline cannot mount a patch.
    $baseProject = Join-Path $BaseSources 'project.godot'
    $basePresets = Join-Path $BaseSources 'export_presets.cfg'
    if (-not (Test-Path -LiteralPath $baseProject -PathType Leaf) -or -not (Test-Path -LiteralPath $basePresets -PathType Leaf)) {
        return @($refusals + (New-PatchRefusal 'baseline-unavailable' "the baseline sources (project.godot, export_presets.cfg) cannot be read from $BaseSources"))
    }
    $baseText = Read-PatchText $baseProject
    if (-not [regex]::IsMatch($baseText, '(?m)^config/version="' + [regex]::Escape($BaseVersion) + '"\s*$')) {
        return @($refusals + (New-PatchRefusal 'baseline-unavailable' "the baseline project.godot does not declare config/version $BaseVersion"))
    }
    $missingBoot = @($script:PatchBootClosure | Where-Object { -not (Test-Path -LiteralPath (Join-Path $BaseSources $_) -PathType Leaf) })
    if ($missingBoot.Count -gt 0 -or -not $baseText.Contains($script:PatchMainScene)) {
        return @($refusals + (New-PatchRefusal 'baseline-no-boot' "the baseline has no boot scene to mount a patch (missing: $($missingBoot -join ', '); main scene boot=$($baseText.Contains($script:PatchMainScene)))"))
    }
    if ($packageUsable) { $refusals += Test-PatchContentPacks $BasePackage $ProjectRoot }
    $refusals += Test-PatchProjectSettings $BaseSources $ProjectRoot
    $refusals += Test-PatchExportPresets $BaseSources $ProjectRoot $BaseVersion $TargetVersion
    if ($packageUsable) {
        $baseEngine = [string]([IO.File]::ReadAllText((Join-Path $BasePackage 'manifest.json')) | ConvertFrom-Json).engine
        if (-not $baseEngine.Trim() -or $baseEngine.Trim() -cne $EngineVersion.Trim()) { $refusals += New-PatchRefusal 'engine' "the baseline package was built by '$baseEngine', this engine is '$EngineVersion'" }
    }
    $refusals += Test-PatchBootClosure $BaseSources $ProjectRoot
    return $refusals
}
