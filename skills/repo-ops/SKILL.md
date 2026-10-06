---
name: repo-ops
description: >-
  本仓（magic-spire）的命令与操作流程：分类检查门禁、职能工作树、内容包校验、
  引擎定位与启动、打包与发布入口。要在本仓跑检查、加工作树、启动或打包，
  或问"命令是什么/怎么验证"时使用。AGENTS.md 只写规范；本文件写操作。
---

# 本仓命令与操作流程

规范见仓库根 `AGENTS.md` 与同目录技能（`spire-architecture`／`spire-ui-content`／`spire-validation-release`）；本文件只放操作与命令。
命令在标明的目录执行；占位分类替换为本次实际影响的分类。

## 仓库根

先检查工作区差异；纯本地维护不例行联网查询 PR：

```powershell
git status --short
git diff --stat
git diff --check
git diff --name-only
```

**集成 PR、同步上游、准备推送或继续旧 PR 分支时**，再检查上游是否已吸收该分支：

```powershell
git fetch origin main
git log --oneline origin/main -8
git log --oneline HEAD..origin/main
```

先核对实际远端与分支；上例适用于本仓的 `origin/main`。需要 PR 状态时用已连接的 GitHub 工具或可用的 `gh pr list`，不为本地检查安装额外工具。
已吸收时：保留工作区在途修改，只将**尚未被吸收的增量**集成到最新上游并跑受影响门禁；不强推或覆盖远端提交。
关闭 PR 或向他人发送说明遵循当前任务授权，不作为每次维护的附带操作。

## 工作树

主检出以实际仓库位置为准；职能树放在主检出目录外的专用临时目录，分支使用 `codex/` 前缀。

```powershell
$repoRoot = git rev-parse --show-toplevel
$worktreeRoot = Join-Path (Split-Path -Parent $repoRoot) 'tmp'
New-Item -ItemType Directory -Force -Path $worktreeRoot | Out-Null
git worktree add (Join-Path $worktreeRoot 'magic-spire-wt-<slice>') -b codex/<slice> HEAD
git worktree list
```

任务结束后按需清理；删除工作树前确认其改动与证据已保留，不得用强制删除（`--force`）跳过对未提交改动的检查。

## spire-godot（Godot 模块）

```powershell
& tools/check.ps1 -Suite architecture
& tools/check.ps1 -Suite casting,pressure -Impact
& tools/check.ps1 -UIOnly -UISuite equipment_art,hero_art
& tools/check.ps1 -Import -Suite architecture -UI -UISuite home
& tools/check.ps1 -Suite installation_priority -Impact -Exhaustive
& tools/check.ps1 -Suite runner -VerifyRunner
& tools/check.ps1 -Suite recipe -TimeoutSeconds 1800      # 长时程真实输入配方（预发布与交付前必跑）
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
- **敏感性证据**：`tools/check-mutation.ps1`（`-All` 或 `-Check <判据名>`）按 `tests/mutations.json` 的声明逐条做临时突变——改源码 → 跑该条声明的规则套件 → 要求具名判据变红 → **逐字节还原并用哈希自证**，任一环节失败即非零退出。`tools/check-mutation.ps1` 改的是跟踪中的源码；运行时必须串行单引擎，不得与其他门禁并发；日志在 `build/mutations/<运行号>/`。表与判据全集的核对判据是 `tests/architecture_cases.gd::mutation_evidence_is_total`。
- **长时程真实输入配方（`-Suite recipe`）**：固定配方种子 7／`--cap=60`／`--style=trade`，跑 `tests/recipe_driver.gd`，用真实点击与拖拽（窗口 1600×900，非 headless）走到 60 次提交。判读：收尾行 `RECIPE seed=7 commits=60 steps=60 stop=cap` 且 `exit=0`，`stop` 不是 `cap` 或退出码非 0 即整轮失败（产品崩溃时引擎退出码不被吞掉，留在 `check-recipe.log` 末行 `exit=`）。证据在 `build/checks/<运行号>/check-recipe.log`，头部为 `RUN IDENTITY`（`head`／`dirty`／关键文件 `sha256`），摘要见 `summary.json` 的 `recipe` 字段，`-RerunFailed` 会带上失败的 `recipe`。默认**不并入 `all`**（先观察稳定性），但**预发布与交付前必跑**；实测单轮约 51s（`-TimeoutSeconds 1800` 足够）。`-ListOnly` 只登记范围、不执行该阶段。
- **判读**：退出码、每个分类的 `SUITE RESULT: <name> PASS|FAIL`、完成标记（`PASS: N assertions`／`UI PASS: N assertions`）与 `summary.json`（`status`／`before`／`after`／`rules.retry`）。检查期间源码或内容变化会打印 `SOURCE CHANGED:`、整轮记为 `source_changed` 并 exit 1，须重跑全部原选范围——`source_changed` 不得当作冻结版本通过。口径见 `skills/spire-validation-release/SKILL.md`。
- 日志与证据：每轮写入 `build/checks/<运行号>/`（`check-rules.log`、`check-ui.log`、`summary.json` 等），不入库；摘要登记到 `docs/record/verification.md`。
- 内容包校验：`& tools/check-content.ps1`（改动 `spire-godot/content/packs/` 后必跑）；`-Path <目录>` 可指向别处，如 `-Path content/templates`。
- 规则类文档引用门禁 `spire-godot/tools/check-docs.ps1`：现在是 `tools/check.ps1` 的**独立阶段**（先用引擎无关的它开路，有自己的 `DOCS RESULT: PASS|FAIL` 结果行与 `summary.json` 的 `docs` 字段，失败即整轮失败），也可单跑做局部核对；改 `docs/spec`／`docs/design`／`docs/guide`／根 `AGENTS.md`／`skills`（含 `.zcode/skills` 薄桩）后必跑（或随主门禁带上）。检查点名路径存在、`文件::符号` 锚点已声明、本地 md 链接可达，并打印允许清单条数；扫描范围与排除理由的唯一声明在 `tools/doc-scan-scope.ps1`，`-ListTokens` 逐条打印。这些规则类文档同时在源码指纹内：改动它们会触发 `SOURCE CHANGED`。
- 记录守恒核对 `tools/check-record-conservation.ps1 -Base <rev>`（默认 `8e83876`）：对三卷验证册比较基线，输出标识、逐字保真、标题／日期／域行、失败／未跑行四类差集，差集非空即非零退出。**迁移期脚本，不是常驻门禁**（只在历史压缩或记录修整时取证）；保留白名单与压缩规则见 `skills/spire-docs/SKILL.md` 记录诚实节。
- 引擎与启动：`tools/find-godot.ps1` 提供 `Find-SpireGodot`（`GODOT_BIN` → `godot`／`godot4` → `%USERPROFILE%\Downloads` 顺序探测），`tools/launch.ps1` 启动游戏。
- 打包输出默认写到仓库根 `outputs/`（`package.ps1 -OutputRoot` 可覆盖）；打包入口 `tools/package.ps1`、`tools/package-android.ps1`，成品检查 `tools/check-package.ps1`、`tools/check-android-package.ps1`；先读 `docs/spec/packaging.md`，不以旧发布说明代替当前脚本。
- **打包脚本必须用 PowerShell 7**（`pwsh`）：`package.ps1`／`package-android.ps1` 使用 `[IO.Path]::GetRelativePath`，Windows PowerShell 5.1 不支持。
- **Windows 打包的 `GODOT_BIN` 指向 `*_console.exe`**：`find-godot.ps1 -Console` 无匹配时可能回退到 GUI 版，导致退出码缺失与不完整暂存目录；启动前核对返回路径。失败后保留证据，重试使用新 `BuildId`，不为重试强制删除旧目录。
- **打包的环境前置**：Godot 导出模板须装在 `%APPDATA%\Godot\export_templates\<引擎版本>\`；引擎版本与 `docs/spec/packaging.md` 的当前契约一致。`find-godot.ps1` 不校验版本，存在偏差时先处理，不能将不同环境的产物宣称为已按约验收。
- **打包读取的输入**（改动前先确认仍在原位）：模块根 `基础操作教学.txt`（随包分发）、`docs/record/release-notes/release-v<版本>.txt`（作为包内 `版本更新内容.txt`）与 `docs/record/release-notes/release-android-v<版本>.txt`、`spire-godot/packaging/licenses/GODOT-LICENSE.txt`／`GODOT-COPYRIGHT.txt`、`assets/vendor/CREDITS.md`、`assets/fonts/OFL`、仓库根 `LICENSE`／`ASSET_RIGHTS.md`／`版本更新内容.txt`。玩家面副本与启动器另存于仓库根 `release/`（`基础操作教学.txt`、`开始游戏.cmd`、`开始游戏.vbs`；从 `release/` 启动时回退找 `../spire-godot/tools/launch.ps1`）。

## 产物与清理

- 计时脚本、基准数据、验收补充脚本等一次性产物放已忽略的 `spire-godot/build/`，
  不入库、不进运行时（见根 `AGENTS.md`「禁区」）。摘要登记后保留本批复核需要的原始证据；
  清理时确认不再被当前验收引用，避免记录刚写完就失去证据。

## 多 harness 协作（操作卡）

本节只写操作事实；带 † 的条目为 2026-10-05 多 harness 实测、本轮实现未复跑（待核实）。

### 引擎与门禁

- 引擎显式指定 `C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`。
  `GODOT_BIN` 可能已被改坏（当前 User 级指向不存在的
  `C:\1\Tools\Godot\v4.7-stable\Godot_v4.7-stable_win64.exe`）；每次在同一 shell 显式覆盖，
  不要信 `tools/find-godot.ps1` 的回退（本机无 `godot`／`godot4` 命令、`Downloads` 无候选时会直接抛错）：

  ```powershell
  $env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
  Test-Path $env:GODOT_BIN
  ```
- 同一时间只跑一个引擎进程；跑前跑后各查一次：
  ```powershell
  Get-Process Godot* -ErrorAction SilentlyContinue
  ```
- 新工作树首次运行前先导入；导入会把工作树内 `.import` 按本机行尾整批改写（实测 516 个文件），
  跑完 `git checkout -- .` 还原，再 `git status --short` 确认干净：

  ```powershell
  & $env:GODOT_BIN --headless --path <工作树>/spire-godot --import
  ```
- 门禁判读（全部满足才算通过）：退出码 0；每分类 `SUITE RESULT: <name> PASS`；`summary.json` 的
  `status=passed` 且 `before==after`；日志无 `SOURCE CHANGED`；日志无
  `Failed to read the root certificate store`（该行＝沙箱假红，换非沙箱宿主重跑）。
- 指纹面：`docs/spec`、`docs/design`、`docs/guide`、`skills`（含 `.zcode/skills` 薄桩）、`AGENTS.md` 属 rule-class、
  在源码指纹内 ⇒ 先改完再跑门禁；`docs/record/**` 不在指纹内。范围唯一声明为 `tools/doc-scan-scope.ps1`。

### 工作树并发纪律

- 每个工作树同一时间只允许一个写者；派工前确认该树没有其它会话在写。
- 等待判据（全部满足才算对方收工）：① `Get-Process Godot*` 为空；② `spire-godot/build/checks/`
  下连续 3 分钟无新运行目录；③ `git status --short` 为空；④ HEAD 稳定（隔一段时间两次
  `git rev-parse HEAD` 相同）。
- **提交 ≠ 收工**：门禁与突变脚本运行期会临时改文件（`tools/check-mutation.ps1` 跑前跑后比对工作区，
  残留即自报 `MUTATION_RESIDUE` 并非零退出）；等待按上一条判据，不按"有没有提交"。
- 引擎与突变脚本：同一时间一个引擎进程；`tools/check-mutation.ps1` 运行期不得有其它写者。

### harness 清单

- **ZCode 子代理**（Agent 工具）：只在同一会话内；`run_in_background`；派工载荷需自含
  （域／接口契约路径／授权范围／证据要求）。
- **opencode CLI**（`opencode run`，1.18.29）：模型 `opencode/muse-spark-1.3-contributor-free`
  （`--variant xhigh`）与 `opencode/space-bunny-free`（`--variant max`）；`--dir` 指向固定提交的
  detached 工作树；`--auto`；每个审查者独立 XDG 目录（`XDG_DATA_HOME`／`XDG_CACHE_HOME`／
  `XDG_CONFIG_HOME` 各指到各自的 `C:\1\tmp\oc-*`）；载荷写明只读：不改任何文件、不提交、不跑引擎。
- **codex CLI**：`~/.local/bin/codex.exe` 是 0.153.1、落后——`gpt-6.1-sol` 被 ChatGPT 账号拒绝
  （原文 `not supported when using Codex with a ChatGPT account`）。可用核＝desktop 包内的 0.160.0：
  `C:\Program Files\WindowsApps\OpenAI.Codex_26.930.3930.0_x64__2p2nqsd0c76g0\app\resources\codex.exe`，
  同 `~/.codex/config.toml`、同账号可正常跑 `-m gpt-6.1-sol`†。
- **codex 沙箱限制**†：`--sandbox workspace-write` 下 ①跑 `tools/check.ps1` 会报
  `Failed to read the root certificate store.` 并 `status=failed`（假红）；②`git add`／`git commit`
  会因主仓 `.git` 不在可写面而失败。需要它跑门禁或提交时用 `--sandbox danger-full-access`，
  否则只让它做只读分析。

### 审查协议

- 审查者固定在 detached 工作树（`C:\1\tmp\magic-spire-wt-*-review-*`）、只读、不跑引擎、不读他人报告；
  任一路 FAIL 即按 FAIL 结论处理；同一对象多路独立（muse＋bunny，必要时加 codex）；收口后做窄口径确认（只查被提的项）；
  每路给出 `[已核对通过]`／`[应修]`／`[存疑]` ＋域＋证据＋`VERDICT` 行。
- 证据带内：临时 runner 的日志头写 `RUN IDENTITY`（`head=<git rev-parse HEAD>`、
  `dirty=<porcelain 条目数>`、所载关键文件 `sha256`），日志尾写 `exit=<code>`；"预期 PASS"不是证据。
- 证据位置：探针／驱动／日志一律 `spire-godot/build/`（gitignored，随工作树拆除消失）；
  计划与裁定在 `C:\1\tmp\<slice>-plan\`；个人记忆在 `C:/1/Myself`（项目外）。
