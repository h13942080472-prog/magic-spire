param(
    [Parameter(Mandatory)][string]$GameDirectory,
    [Parameter(Mandatory)][string]$Destination
)
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $GameDirectory
$notes = @('版本更新内容.txt', '卡牌遗物修改合集.txt')
foreach ($name in $notes + @('LICENSE', 'ASSET_RIGHTS.md')) {
    Copy-Item -LiteralPath (Join-Path $repository $name) -Destination $Destination
}
$licenses = Join-Path $Destination 'licenses'
[IO.Directory]::CreateDirectory($licenses) | Out-Null
Copy-Item -LiteralPath (Join-Path $GameDirectory 'assets/vendor/CREDITS.md') -Destination $licenses
Copy-Item -LiteralPath (Join-Path $GameDirectory 'assets/fonts/OFL') -Destination (Join-Path $licenses 'NotoSansCJK-OFL')
foreach ($name in @('GODOT-LICENSE', 'GODOT-COPYRIGHT')) {
    Copy-Item -LiteralPath (Join-Path $GameDirectory "packaging/licenses/$name.txt") -Destination (Join-Path $licenses $name)
}
$included = @(Get-ChildItem -LiteralPath $Destination -File -Recurse -Filter '*.txt' | ForEach-Object {
    [IO.Path]::GetRelativePath($Destination, $_.FullName)
})
if (Compare-Object $notes $included) { throw "Unexpected TXT inventory in $Destination" }
foreach ($name in $notes) {
    if ((Get-FileHash -LiteralPath (Join-Path $repository $name)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $Destination $name)).Hash) {
        throw "Packaged document differs from its source: $name"
    }
}
