# 状态字段读者声明与反向溯源：依赖约束索引

「状态字段读者声明与反向溯源」（`docs/spec/state-readers.md`）一片的依赖约束索引。本文件给清洁者核对：
单一声明面、无第二扫描实现、产品码零引用、冻结物只此写者、UI 零直读；判据的真源是下表点名的检查，
散文不复述断言文本。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`data/`、`ui/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

## 判据 → 检查

| 判据 | 执行它的检查 |
| --- | --- |
| 派生＝冻结（表外读、表内缺读、计数不符、输入指纹不符都红）＋报告行 | `tests/architecture_cases.gd::state_read_sites_are_pinned`（配合 `tests/state_reader_scan.gd::compare`） |
| 到达性／函数体非空／未知名／`ui_reads==[]`／登记表双向覆盖 | `tests/architecture_cases.gd::state_read_scan_reaches_every_source` |
| 整字典／别名／模式串三表双向 | `tests/architecture_cases.gd::state_read_registrations_are_pinned` |
| 三条判据各自的敏感性（临时突变 → 该判据 RED → 逐字节还原） | `tests/mutations.json` 的三条条目 ＋ `tools/check-mutation.ps1` |
| 冻结物可读、schema 1（红＝不可读或形状不符） | `tests/state_reader_scan.gd::frozen_error`（三条判据共用） |
| 重冻 `tests/check_index.json` 后零漂移 | `tools/check-index.ps1`（verify）＋ `tests/runner_cases.gd::index_matches_regeneration` |
| 失败面报告（非判据，只打印） | `tests/state_reader_scan.gd::failure_face`（随 `state_read_sites_are_pinned` 打印 `STATE FAILURE FACE …`） |

## 允许改动表（表外即越界）

| 面 | 路径 | 改动 |
| --- | --- | --- |
| 冻结真源 | `tests/state_readers.json` | 派生入库；**永不手改**，只由重生成入口覆盖 |
| 派生模块 | `tests/state_reader_scan.gd` | 纯静态、无引擎依赖、无 `run()`：`scan`／`field_registry`／`failure_face`／`compare`／`canonical`／`body`／`frozen`／`frozen_error`／`function_body` |
| 重生成入口 | `tools/build_state_readers.gd` | `--verify`（缺省，退出码 0/1）／`--write`（覆盖冻结物，**只此写者**） |
| 判据 | `tests/architecture_cases.gd` | 三条新判据＋`run()` 注册；不改既有判据的声明与语义 |
| 突变证据 | `tests/mutations.json` | 三条对应条目；`known_gaps` 不增 |
| 既有冻结物（同批重冻） | `tests/check_index.json` | 因 `tests/architecture_cases.gd` 文本变化，必须同批 `tools/check-index.ps1 -Write` |
| 契约文档 | `docs/spec/state-readers.md`、`docs/spec/state-readers-dependencies.md` | 本文件与现行契约 |

禁止（零改动）：`core/**`、`ui/**`、`data/**`、`content/**`、`assets/**`、`tests/frozen-baselines.json`、
`tests/check_index_edges.gd`／`tests/suite_selection.gd`、`tools/check.ps1`、`tests/mutations.json` 的既有条目与
`known_gaps`；`tests/check_index.json` 只允许被 `tools/check-index.ps1 -Write` 覆盖。

## 依赖方向（本片允许的边）

- `tests/architecture_cases.gd` → `tests/state_reader_scan.gd` → `tests/source_text.gd` → `FileAccess`
  （`tests/state_reader_scan.gd` 自身只用 `FileAccess` 读冻结物 `FROZEN_PATH`）；叶不 preload 产品码、
  测试夹具或本模块。
- `tools/build_state_readers.gd` → `tests/state_reader_scan.gd`。
- 禁止：`tests/state_reader_scan.gd` 引 `core/`／`ui/`／`data/`／测试夹具（它只读文本，不 preload 产品码）；
  产品码引 `tests/`；`tests/architecture_cases.gd` 出现第二套 state 扫描实现（三条判据只消费同一派生模块，
  不自行枚举源码）。
- 扫描原语边界：被扫描的源码文本的读取收口在 `tests/source_text.gd`（`normalized_text`／`normalized_text_sha256`，
  只把 CRLF 对折成 LF）；`tests/state_reader_scan.gd` 只保留最小枚举原语 `_rel_files` 与单次运行内的文本缓存
  `_source_text`，不再自带读文本原语。`tests/check_index.gd` 的扫描与逐文件哈希、
  `tests/runner_cases.gd::source_text_folds_crlf_pairs`／`tests/runner_cases.gd::source_text_keeps_lone_cr`
  共用同一读入口（边见 `docs/spec/check-routing-dependencies.md`）：归一规则一处声明，扫描与哈希
  吃同一段归一文本。`tests/architecture_cases.gd::source_text` 仍是架构判据侧的独立小原语（不在本片允许面内，
  本批未改）。

## 行数线

- `tests/state_readers.json` 不设行数线（生成物，评审靠判据打印行与统计）；`tests/architecture_cases.gd` 净增 83 行（限 220）。
- `tests/state_reader_scan.gd` 452 行：**协调者已裁接受（2026-10-14，P5 派工记录）**，计划行数线 ≤ 320 是规划者的
  规模估计，不是本仓的硬约束（先例：`tests/check_index.gd` 534 行同为单职责的派生／判据模块）。接受理由：
  本模块职责单一（全片唯一扫描实现：派生＋冻结物形状＋失败面），超出估计的部分＝`failure_face` 的静态调用闭包
  （函数体索引、常量前缀／`g.`／`self.` 调用边、闭包遍历、逐 kind 种子），它是 G-SR-7 的判据落点与套件内
  `STATE FAILURE FACE …` 报告行的实现。若日后要把失败面报告移出本模块，须同时给出 G-SR-7 的新落点，
  不单独改本行。

## 单一声明面与唯一写者（清洁检查点）

- 扫描实现只有 `tests/state_reader_scan.gd` 一份：`tools/build_state_readers.gd --verify`／`--write` 与三条判据
  都调 `tests/state_reader_scan.gd::scan`；`tests/architecture_cases.gd` 不复制任何正则或归属逻辑。
- 冻结物只有 `tools/build_state_readers.gd --write` 一个写者（`tests/state_reader_scan.gd::body` 定义冻结形状）；
  判据与 `--verify` 都只读。
- 别名声明只有一处：`tests/state_reader_scan.gd::ALIAS_DECLARATIONS`（6 个函数）；非 state 形参排除表见下。
- UI 零直读：`ui_reads` 恒为空表；`ui/` 内的局部样式变量 `state` 不是 state 读（口径见
  `docs/spec/state-readers.md`「扫描口径」第 5 条）。
- UI 面的既有 token 禁令（`ui/` 不出现 `game.state`，含写与未登记成员）见 `docs/spec/release-interface.md`；
  本片 `ui_reads` 是 state 字段读面（登记表字段名的直读＝0），两条判据语义不同、不重复。

## 非 state 形参排除表（不得计入别名面，逐条带理由）

| 形参位点 | 理由 |
| --- | --- |
| `core/prison_space.gd::walkable` 的 `s` | 牢房空间字典（`position`／`blocked`／`sites`），字段名不在 state 登记表 |
| `core/prison_space.gd::path` 的 `s` | 同上：牢房空间寻路输入 |
| `core/snapshot.gd::intent` 的 `p` | 敌人意图记录（嵌套记录），不是 state 顶层 |
| `core/snapshot.gd::effect` 的 `e` | 事件效果记录（嵌套记录），不是 state 顶层 |

误把排除项计入别名面会改变 `aliases` 的字段集合（`tests/architecture_cases.gd::state_read_registrations_are_pinned` 红）。

## 仍靠人审（无机械判据，本批保留）

- **新别名函数不被自动发现**：新写 `func f(s)` 收 state 的读是静默面，必须按仓规登记进
  `tests/state_reader_scan.gd::ALIAS_DECLARATIONS` 并同批重生成；判据只钉「已声明集合」的双向。
- **模式串并集**：同一函数内新增一处与既有 spec 字段集相同的 `Snapshot.fields` 调用不改并集、不红。
- **变量键读／写与子键**：`state[变量]`、`state.rng[domain]=0`、子键名不进字段表（口径见
  `docs/spec/state-readers.md`「残差与仍靠人审」）。
- **失败面上的口径**：静态闭包是上界、不是实测读集；登记与打印口径见
  `docs/spec/state-readers.md`「失败面」。
- 推送、打标签、改版本号、打包不在本片授权面（红线见根 `AGENTS.md`「禁区」）。
