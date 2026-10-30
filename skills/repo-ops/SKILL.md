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
& tools/check.ps1 -Suite all -UI -UISuite all            # 完整回归（里程碑专用）
& tools/check.ps1 -RerunFailed build/checks/<运行号>      # 只续跑失败与未完成分类
& tools/check.ps1 -Changed -ListOnly                     # 按工作区变更出计划（PLAN ONLY，不算通过）
& tools/check.ps1 -Changed -TimeoutSeconds 1200          # 按工作区变更跑路由出的范围（开发期快速反馈）
& tools/check.ps1 -Changed -Since <ref>                  # 已提交后：ref → 工作区
& tools/check.ps1 -ChangedList <清单文件> -ListOnly        # 显式清单：一行一仓根相对路径，# 与空行忽略
& tools/check-index.ps1                                  # 索引零漂移校验（退出码 0／1）
& tools/check-index.ps1 -Write                           # 重冻 tests/check_index.json（必须与源码同批提交）
& $env:GODOT_BIN --headless --path . --script res://tools/build_state_readers.gd -- --verify   # 状态字段读者表零漂移
& $env:GODOT_BIN --headless --path . --script res://tools/build_state_readers.gd -- --write    # 重生成 tests/state_readers.json（只此写者，同批提交）
```

- 默认（不传 `-Suite`）跑快速检查 `runner`＋`architecture`，默认窗口分类是 `home`；分类名注册在 `tests/test_game.gd`（`SUITES`）与 `tests/ui_smoke.gd`（`UI_MODULES`）。
- `-Suite`／`-UISuite` 逗号分隔、重复项去重；纯显示用 `-UIOnly -UISuite <窗口分类>`；规则与窗口同时改则 `-Suite <规则分类> -UI -UISuite <窗口分类>`（只写 `-UI` 会拒绝：`-UISuite` 必须配 `-UI` 或 `-UIOnly`）。
- 共享规则用 `-Impact` 合并交叉分类一次跑完；随机生成改动加 `-Exhaustive`（`-Suite all` 自动启用完整随机样本）。
- 影响范围的唯一声明为 `tests/suite_selection.gd::CROSS_AREAS`：键是需要补跑的测试分类，值是会影响它的修改域；只从用户原始选择展开一次。新增跨系统联动时同步这份声明，并在 `runner_cases` 验证具体联动会被选中；仅把用例加入某分类的 `run`，不能保证修改其上游时会自动补跑。
- **路由模式（`-Changed`／`-ChangedList`）**：范围由冻结的派生索引 `tests/check_index.json` 决定，契约见 `docs/spec/check-routing.md`。三者与 `-Suite`／`-UISuite`／`-UI`／`-UIOnly`／`-Impact`／`-RerunFailed` 互斥，`-Since` 只配 `-Changed`，所有拒绝都在起引擎前。计划逐文件打印 `ROUTE ROW`／`ROUTE DEFAULT`／`ROUTE UNMAPPED`／`ROUTE NONE`／`ROUTE MILESTONE`／`ROUTE WIDEN CANDIDATE`；未命中索引不是失败，而是走目录闭包，闭包也未命中落到 `all-dev`＋`all-dev-ui`；`docs/`／`release/`／`.zcode/`／`skills/`／`spire-godot/build/`／模块内 `.godot/`／仓根 `*.md` 等 declared-none 路径不选任何套件、也永不作为通过；仓库外路径与空集拒绝。
- **路由只服务开发期快速反馈**：PR／打包／发版／版本推进前必须 `-Suite all -UI -UISuite all`。里程碑套件 `normal_play`／`baseline` 被路由显式扣除（每次计划打印扣除清单与闭包覆盖清单）；`summary.route` 记录不得用于宣称里程碑或交付通过。
- **索引维护**：`tests/check_index.json` 是生成物，只许 `tools/check-index.ps1 -Write` 写。更新触发＝任一扫描输入文本变化：`core|data|ui` 的 `.gd`、所有 `tests/*_cases.gd`（含 `tests/runner_cases.gd`）、两个宿主 `tests/test_game.gd`／`tests/ui_smoke.gd`、`tests/check_index.gd`、`tests/check_index_edges.gd`；忘记重冻会被 `runner` 的 `index_matches_regeneration` 打红（默认快速门禁含 `runner`）。
- **状态字段读者表维护**：`tests/state_readers.json` 是生成物，只许 `tools/build_state_readers.gd --write` 写；更新触发＝`core|data|ui` 任一 `.gd` 文本变化（含注释，输入指纹＝全部文本），忘记重生成会被 `architecture` 的 `state_read_sites_are_pinned` 打红。口径、判据与残差见 `docs/spec/state-readers.md`。
- `-ListOnly` 只预览范围（输出 `PLAN ONLY:`），不算通过；`all` 只用于明确完整回归，检查通过后不无故重复运行。失败分类默认停止后续分类：`-KeepGoing` 只继续当前规则或 UI 阶段，脚本错误始终停止。
- `-RerunFailed <目录或 summary.json>` 只重跑失败与未完成的分类，不能与 `-Suite`／`-UISuite`／`-UI`／`-UIOnly`／`-Impact`／`-Exhaustive` 同用；`status=passed` 的上轮结果会被拒绝。
- `-VerifyRunner` 跑测试器自身的负例探针，不能与 `-ListOnly` 同用：既有七条 `negative-*`（未启用范围的拒绝、故意脚本错误、超时、失败停止与继续执行）＋路由八条 `route-*`（`route-ui-only`／`route-content`／`route-save`／`route-snapshot-domain`／`route-blind-closure`／`route-unmapped-fail-closed`／`route-declared-none`／`route-scope-matches`，最后一条证明 `-ListOnly` 的计划＝真跑的范围）；探针日志逐条落 `build/checks/<运行号>/check-<探针名>.log`。`-Import` 在首次没有 `.godot/` 或新增素材导入时使用。
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

## 工作树与取证

- 每个工作树同一时间一个写者；运行引擎与突变检查期间不得修改该树的受检文件。并发任务按实际工作树、进程与任务状态确认归属。
- 引擎通过 `tools/find-godot.ps1` 定位并核对版本，不沿用其他机器的绝对路径；导入后只处理已确认由导入产生的元数据差异，保留业务与文档在途修改。
- 交付验证优先在已提交的隔离树执行，记录 HEAD、工作区差异和所载文件哈希；仅受影响源码、测试或环境变化时重新取证。运行内 `before==after` 不能独自证明跨运行源码相同。
- 突变检查只在独占的隔离树执行；运行前后核对字节还原与差异，保留具名失败和还原证据。日志留在 `spire-godot/build/`，计划放该工作树的 `tmp/`。
- 独立审查的模型、人数与证据复用统一遵循 `skills/spire-validation-release/SKILL.md`，不在操作卡另设重复审查流程。
