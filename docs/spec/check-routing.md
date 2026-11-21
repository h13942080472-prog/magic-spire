# 检查路由契约（派生索引）

域：`tests/check_index.gd`、`tests/check_index_edges.gd`、`tests/check_index.json`、`tests/route_plan.gd`、`tests/runner_cases.gd`、`tools/build_check_index.gd`、`tools/check-index.ps1`、`tools/check.ps1` 的路由面。
依赖方向与规模见 `docs/spec/check-routing-dependencies.md`。

## 1. 问题与目标

常态检查的范围此前靠人列举 `-Suite`／`-UISuite`；`-Impact` 只按 `tests/suite_selection.gd::CROSS_AREAS` 从初始请求展开一次；`-ListOnly` 只列计划、不校验完整性。本契约让范围由仓库现状**派生**：改了哪些文件 → 该跑哪些套件；未命中不许静默；里程碑命令与既有定向命令语义不变。

非目标：不改套件内部断言、不删套件、不放宽红集口径、不改测试写法；不新增运行时依赖；不新建 CI；不改 `summary.json` 既有键语义（只新增 `route`）；不做失败隔离（另片）。

## 2. 命令面

```powershell
& tools/check.ps1 -Changed                              # 工作区变更（git diff --name-only HEAD ＋ 未跟踪文件）→ 路由实跑
& tools/check.ps1 -Changed -Since <ref>                 # 已提交后：ref → 工作区
& tools/check.ps1 -Changed -ListOnly                    # 只出版计划，不算通过
& tools/check.ps1 -ChangedList <清单文件>                 # 显式清单（`#` 注释与空行忽略；探针与确定性复跑用）
& tools/check-index.ps1                                 # 索引零漂移校验（退出码 0／1）
& tools/check-index.ps1 -Write                          # 重冻 tests/check_index.json（与源码同批提交）
& tools/check.ps1 -Suite all -UI -UISuite all           # 里程碑全量（唯一入口；PR／打包／发版／版本推进前必跑）
```

- **互斥与拒绝（全部发生在起引擎前）**：`-Changed`／`-ChangedList` 与 `-Suite`／`-UISuite`／`-UI`／`-UIOnly`／`-Impact`／`-RerunFailed` 互斥；`-Since` 必须配 `-Changed`；`-Changed` 与 `-ChangedList` 互斥。
- **变更集解析**：仓根相对、`/` 分隔、排序去重；重命名（`=>`）、带引号、含制表符的 git 行按歧义拒绝并提示改用 `-ChangedList`；空集拒绝（提交后的空集提示 `-Since <base>`）。
- **declared-none（不产生套件，也永不作为通过）**：`docs/`、`release/`、`.zcode/`、`skills/`、`spire-godot/build/`、模块内 `.godot/`、仓根 `*.md` 与 `README.md`／`AGENTS.md`／`.gitignore`／`LICENSE`／`ASSET_RIGHTS.md`。其余不在 `spire-godot/` 内的路径在起引擎前拒绝。
- `-ListOnly` 的平面路线只跑计划宿主并打印 `PLAN ONLY: no game tests executed`；`status=plan` 不算通过。
- `summary.json` **只新增** `route` 键（既有键一律不动）：`mode`／`since`／`files_count`／`files_sha256`／`index_digest`／`rules`／`ui`／`gates`／`unmapped`／`default_files`／`blind_files`／`defect_hits`／`widen`／`widen_candidates`／`milestone`／`notes`／`declared_none`／`plan`／`log`／`gate_results`（内容门阶段）。
- **用途边界**：路由只服务开发期快速反馈。PR、打包（`tools/package.ps1` 等）、发版、版本推进或跨域大改前必须跑里程碑全量；`summary.route` 记录不得用于宣称里程碑或交付通过。

## 3. 路由语义（确定性、可打印）

对每个变更文件（仓根相对路径）逐文件打印一行：

1. **索引命中** → 冻结表里指向它的套件（每条边带信号类别 `preload`／`symbol`／`symbol_ui`／`domain`），再并上 `tests/check_index_edges.gd::WIDEN` 的声明放大；`spire-godot/core/**` 的命中结果**固定追加** `architecture,persistence,runner`（协调者裁定，跨切面／元数据套件）并打印 `ROUTE CORE APPEND`。
2. **索引未命中（盲区）** → 按 `tests/check_index_edges.gd::CLOSURE` 的目录过近似：`core/**`／`data/**` → 全部规则套件（`all-dev`）、`ui/**` → 全部界面套件（`all-dev-ui`）、`content/` → 内容消费者＋内容门、`tests/` → `all-dev`＋`all-dev-ui`、其余按表内声明。逐条打印 `ROUTE DEFAULT`。
3. **闭包也未命中** → fail-closed 到 `all-dev`＋`all-dev-ui`，逐条打印 `ROUTE UNMAPPED` 并进 `summary.route.unmapped`。
4. **里程碑扣除**：`normal_play`／`baseline` **永不进入**路由结果；每次计划打印 `ROUTE MILESTONE: declared …; deducted …` 与 `ROUTE MILESTONE COVERAGE`（走到闭包／兜底、只能由里程碑全量覆盖的文件）。
5. 结果按注册表顺序（`tests/test_game.gd::SUITES`、`tests/ui_smoke.gd::UI_MODULES`）排序去重，便于逐字比对；同输入逐字节同输出（键排序、数组排序、无时间戳）。
6. `tests/check_index_edges.gd::DOMAINS` 解析的盲区打印 `ROUTE DOMAIN`；`INDEX_DEFECTS` 命中的路径打印 `ROUTE KNOWN GAP`；`CROSS_AREAS` 与本索引选择不一致处打印 `ROUTE WIDEN CANDIDATE`（**只提示，不自动放宽**）。

## 4. 索引：派生、冻结与更新触发

- **唯一派生实现**：`tests/check_index.gd::derive()`（顶部注释写抽取规则）。生成器 `tools/build_check_index.gd`、零漂移门 `tools/check-index.ps1`、自检 `tests/runner_cases.gd`、计划宿主 `tests/route_plan.gd` 共用它。
- **冻结物**：`tests/check_index.json`（schema 1，**生成物，永不手改**；在 `tests/` 内、源码指纹面内）。主表 `suite_files` ＝ `套件 → {源文件 → [信号]}`；另载 `case_files`／`domains`／`blind`／`domain_words`／`registries`／`stats`／`generated_from`／`digest`。
- **判据只读**：检查流程永不自动重写冻结物；`-Write` 是唯一写入口，判定用 `--verify`（缺省，退出码 0／1）。
- **扫描输入（`generated_from` 的覆盖面）**：`tests/test_game.gd`、`tests/ui_smoke.gd`、`tests/check_index.gd`、`tests/check_index_edges.gd`、`tests/source_text.gd`（归一规则本身，改它即改派生）、全部 `*_cases.gd` 用例文件、`core|data|ui` 下全部 `.gd`。**任一输入文本变化（含注释）都要在同一提交里 `-Write` 重冻**；忘记重冻会被 `runner` 的 `index_matches_regeneration`／`index_regeneration_is_the_only_writer` 打红（默认快速门禁含 `runner`，属有意的 fail-closed）。
- **输入文本先归一**：读取被扫描的源码文本时统一经 `tests/source_text.gd::normalized_text`（只把 CRLF 对折成 LF；孤立的 `\r` 与 BOM 原样保留，与 git `core.autocrlf` 同一条规则），逐文件取哈希经 `normalized_text_sha256`，扫描也吃同一段归一文本。因此 `generated_from` 与冻结值只由文本内容决定，与检出的行尾（LF／CRLF／混合）无关：同一提交在两种检出上算出同一值，`-Write` 不再需要与门禁同处一个检出。
- **冻结物冲突不手合**：`tests/check_index.json` 的合并冲突一律用 `tools/check-index.ps1 -Write` 重生成后以零漂移校验收尾；手改值会被 `index_regeneration_is_the_only_writer` 打红。
- 抽取规则（`preload`／`symbol`／`symbol_ui`／`domain`、归属、`static func` 不入索引）写在 `tests/check_index.gd` 顶部；改规则＝派生变化，必须重冻并说明旧规则看不见什么。

## 5. 判据与探针

- `tests/runner_cases.gd` 的九条具名判据（消息第二词＝判据名，供突变工具匹配）：`index_covers_every_case_file`／`index_targets_exist`／`index_matches_regeneration`／`index_regeneration_is_the_only_writer`／`index_suites_are_all_reachable`／`index_skips_no_source_file`／`index_declared_domains_exist`／`index_defects_stay_closed`／`index_route_examples_are_pinned`。一次 `derive()` 供全部断言共用。
- `-VerifyRunner` 的路由探针（`CHECK route-*:` 行）：`route-ui-only`／`route-content`／`route-save`／`route-snapshot-domain`／`route-blind-closure`／`route-unmapped-fail-closed`／`route-declared-none`／`route-scope-matches`（计划＝执行：`-ListOnly` 的计划与真跑的 `summary.rules.selected`／`summary.ui.selected`／`index_digest` 逐项相等）。既有 `negative-*` 七条逐字保留。
- 突变证据：`tests/mutations.json` 里五条 `suite=runner` 条目（`index_matches_regeneration`／`index_skips_no_source_file`／`index_declared_domains_exist`／`index_suites_are_all_reachable`／`index_route_examples_are_pinned`）；`-VerifyRunner` 探针的敏感性由同一语义的突变继承。`runner_cases.gd` 的判据**不进** `tests/architecture_cases.gd::mutation_judgment_universe()`（该口径只扫 architecture 一个文件），本片以合同强制新判据必带突变条目。

## 6. 当前实测面（2026-10-13，`60f7ab1` 起）

- 语料：220 个含 `static func run(` 的用例文件、规则套件 52、界面套件 47、`core|data|ui` 源文件 129。
- 派生：96 个套件有派生边、521 条套件→源文件边、127 个源文件有边或域；`DOMAINS` 60 条、`BLIND_BY_DESIGN` 3 条（`core/tool_rules.gd`／`core/item_presentation.gd`／`data/phases.gd`）、`EXCLUDE` 15 条、`SUITE_EXEMPT` 3 条（`rule:runner`／`rule:core`／`ui:baseline`）。
- 例（判据里冻结）：`core/save_store.gd` → 规则 `architecture,runner,persistence`、界面 `encyclopedia,home_persistence,home,interface,persistence`；`core/game.gd` 的 `WIDEN impact:persistence` 展开到 30+ 规则套件。

## 7. 已知边界（有意接受）

- **组合才红的用例不可由静态边推导**（历史：`home_persistence` 只在组合形式下红）→ 里程碑全量是检出该类的唯一手段，不可被路由替代。
- **规则套件对 `ui/` 文件的文本级断言不在派生边内**（例：`tests/architecture_cases.gd` 读 `ui/command_routes.gd` 的形状）；`DOMAINS` 对 `ui/**` 只解析界面套件，规则侧由里程碑全量覆盖。
- **夹具层不产生精确边**（`tests/check_index_edges.gd::EXCLUDE` 逐条给理由）；`tests/**` 的其余文件按测试层整体兜底。
- **`INDEX_DEFECTS` 学习环**：路由漏掉、更宽运行抓到的红，按条登记并补齐边／域；`added` 缺项或回退即红。当前为空。
- `ROUTE WIDEN CANDIDATE` 的不一致只提示：`CROSS_AREAS` 仍是「影响域→需补跑分类」的唯一手工声明，本索引不回写它。
