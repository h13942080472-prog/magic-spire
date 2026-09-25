---
name: repo-ops
description: >-
  本仓（magic-spire）的命令与操作流程：分类检查门禁、内容包校验、引擎定位与启动、
  打包与发布入口。要在本仓跑检查、启动或打包，或问"命令是什么/怎么验证"时使用。
  AGENTS.md 只写规范；本文件写操作。
---

# 本仓命令与操作流程

规范见仓库根 `AGENTS.md` 与同目录技能（`spire-architecture`／`spire-ui-content`／`spire-validation-release`）；本文件只放操作与命令。
命令在标明的目录执行；占位分类替换为本次实际影响的分类。

## 仓库根

**开工前先查上游是否已吸收我们的 PR**（作者习惯选择性吸收后自己发版，被吸收的旧分支继续叠提交会立刻冲突）：

```powershell
git fetch origin main
git log --oneline origin/main -8                 # 找 "Release … with PRn integration" 之类
gh pr list --repo h13942080472-prog/magic-spire --state all
git log --oneline HEAD..origin/main              # 差多少
```

已吸收时：把**尚未被吸收的增量** cherry-pick／rebase 到最新 `origin/main`（丢掉被取代的中间提交），重跑受影响门禁后再推；同时关闭已被吸收的 PR 并附去向说明。实例：2026-09-19，v0.17.2（`79c499a`）吸收 #4／#5 后，剩余的 5 个提交 rebase 成 `prison-cell-baseline`（PR #6）。

```powershell
git status --short
git diff --stat
git diff --check
git diff --name-only
```

## spire-godot（Godot 模块）

```powershell
& tools/check.ps1 -Suite architecture
& tools/check.ps1 -Suite casting,pressure -Impact
& tools/check.ps1 -UIOnly -UISuite equipment_art,hero_art
& tools/check.ps1 -Import -Suite architecture -UI -UISuite home
& tools/check.ps1 -Suite installation_priority -Impact -Exhaustive
& tools/check.ps1 -Suite runner -VerifyRunner
& tools/check.ps1 -Suite all -UI -UISuite all            # 完整回归
& tools/check.ps1 -RerunFailed build/checks/<运行号>      # 只续跑失败与未完成分类
```

- 默认（不传 `-Suite`）跑快速检查 `runner`＋`architecture`，默认窗口分类是 `home`；分类名注册在 `tests/test_game.gd`（`SUITES`）与 `tests/ui_smoke.gd`（`UI_MODULES`）。
- `-Suite`／`-UISuite` 逗号分隔、重复项去重；纯显示用 `-UIOnly -UISuite <窗口分类>`；规则与窗口同时改则 `-Suite <规则分类> -UI -UISuite <窗口分类>`（只写 `-UI` 会拒绝：`-UISuite` 必须配 `-UI` 或 `-UIOnly`）。
- 共享规则用 `-Impact` 合并交叉分类一次跑完；随机生成改动加 `-Exhaustive`（`-Suite all` 自动启用完整随机样本）。
- 影响范围的唯一声明为 `tests/suite_selection.gd::CROSS_AREAS`：键是需要补跑的测试分类，值是会影响它的修改域；只从用户原始选择展开一次。新增跨系统联动时同步这份声明，并在 `runner_cases` 验证具体联动会被选中；仅把用例加入某分类的 `run`，不能保证修改其上游时会自动补跑。
- `-ListOnly` 只预览范围（输出 `PLAN ONLY:`），不算通过；`all` 只用于明确完整回归，检查通过后不无故重复运行。失败分类默认停止后续分类：`-KeepGoing` 只继续当前规则或 UI 阶段，脚本错误始终停止。
- `-RerunFailed <目录或 summary.json>` 只重跑失败与未完成的分类，不能与 `-Suite`／`-UISuite`／`-UI`／`-UIOnly`／`-Impact`／`-Exhaustive` 同用；`status=passed` 的上轮结果会被拒绝。
- `-VerifyRunner` 跑测试器自身的负例探针（未启用范围的拒绝、故意脚本错误、超时、失败停止与继续执行），不能与 `-ListOnly` 同用；`-Import` 在首次没有 `.godot/` 或新增素材导入时使用。
- **判读**：退出码、每个分类的 `SUITE RESULT: <name> PASS|FAIL`、完成标记（`PASS: N assertions`／`UI PASS: N assertions`）与 `summary.json`（`status`／`before`／`after`／`rules.retry`）。检查期间源码或内容变化会打印 `SOURCE CHANGED:`、整轮记为 `source_changed` 并 exit 1，须重跑全部原选范围——`source_changed` 不得当作冻结版本通过。口径见 `.zcode/skills/spire-validation-release/SKILL.md`。
- 日志与证据：每轮写入 `build/checks/<运行号>/`（`check-rules.log`、`check-ui.log`、`summary.json` 等），不入库；摘要登记到 `docs/record/verification.md`。
- 内容包校验：`& tools/check-content.ps1`（改动 `spire-godot/content/packs/` 后必跑）；`-Path <目录>` 可指向别处，如 `-Path content/templates`。
- 规则类文档引用门禁 `spire-godot/tools/check-docs.ps1`：现在是 `tools/check.ps1` 的**独立阶段**（先用引擎无关的它开路，有自己的 `DOCS RESULT: PASS|FAIL` 结果行与 `summary.json` 的 `docs` 字段，失败即整轮失败），也可单跑做局部核对；改 `docs/spec`／`docs/design`／`docs/guide`／根 `AGENTS.md`／`.zcode/skills` 后必跑（或随主门禁带上）。检查点名路径存在、`文件::符号` 锚点已声明、本地 md 链接可达，并打印允许清单条数；扫描范围与排除理由的唯一声明在 `tools/doc-scan-scope.ps1`，`-ListTokens` 逐条打印。这些规则类文档同时在源码指纹内：改动它们会触发 `SOURCE CHANGED`。
- 引擎与启动：`tools/find-godot.ps1` 提供 `Find-SpireGodot`（`GODOT_BIN` → `godot`／`godot4` → `%USERPROFILE%\Downloads` 顺序探测），`tools/launch.ps1` 启动游戏。
- 打包输出默认写到仓库根 `outputs/`（`package.ps1 -OutputRoot` 可覆盖）；打包入口 `tools/package.ps1`、`tools/package-android.ps1`，成品检查 `tools/check-package.ps1`、`tools/check-android-package.ps1`；先读 `docs/spec/packaging.md`，不以旧发布说明代替当前脚本。
- **打包脚本必须用 PowerShell 7**（`pwsh`）：`package.ps1`／`package-android.ps1` 用 `[IO.Path]::GetRelativePath`，`powershell.exe` 是 5.1、没有该方法，第一段就抛 `MethodNotFound`。2026-09-17 实测。
- **`GODOT_BIN` 必须指向 `*_console.exe`**（如 `Godot_v4.7.2-stable_win64_console.exe`）：`find-godot.ps1 -Console` 在无匹配时不报错而是**回退返回 GUI 版 exe**；Windows GUI 子系统进程被 PowerShell 启动后不等待、`$LASTEXITCODE` 为空，于是导出其实成功也会报 `Export failed (exit=)`，并留下只含 `紧缚尖塔.exe`／`.pck` 的**不完整暂存目录**（脚本拒绝覆盖，重跑前须手工删除该目录）。2026-09-17 实测。
- **打包的环境前置**：Godot 导出模板须装在 `%APPDATA%\Godot\export_templates\<引擎版本>\`，否则 `--export-release` 报"未找到导出模板"；引擎版本须与 `docs/spec/packaging.md` 记录一致（v0.11–v0.17 都为 **4.7.2**）——`find-godot.ps1` 不校验版本，本机版本不符时打出的包与既有发布口径不符，须在交付说明里写明。
- **打包读取的输入**（改动前先确认仍在原位）：模块根 `基础操作教学.txt`（随包分发）、`docs/record/release-notes/release-v<版本>.txt`（作为包内 `版本更新内容.txt`）与 `docs/record/release-notes/release-android-v<版本>.txt`、`spire-godot/packaging/licenses/GODOT-LICENSE.txt`／`GODOT-COPYRIGHT.txt`、`assets/vendor/CREDITS.md`、`assets/fonts/OFL`、仓库根 `LICENSE`／`ASSET_RIGHTS.md`／`版本更新内容.txt`。玩家面副本与启动器另存于仓库根 `release/`（`基础操作教学.txt`、`开始游戏.cmd`、`开始游戏.vbs`；从 `release/` 启动时回退找 `../spire-godot/tools/launch.ps1`）。

## 产物与清理

- 计时脚本、基准数据、验收补充脚本等一次性产物放已忽略的 `spire-godot/build/`，
  不入库、不进运行时（见根 `AGENTS.md`「禁区」）；摘要登记到 `docs/record/verification.md` 后清理原始目录。
