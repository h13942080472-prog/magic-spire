# 状态字段读者声明与反向溯源：现行契约

域：`spire-godot/tests/state_reader_scan.gd`（唯一静态派生模块）、`tests/source_text.gd`（被扫描源码的归一读取）、
`tests/state_readers.json`（冻结真源）、`tools/build_state_readers.gd`（唯一重生成入口）与
`tests/architecture_cases.gd` 的三条 `STATEREAD` 判据。
「state 字段的读者面」＝`core|data|ui` 源码文本里对 `state` 字典的字段读点。本片是**静态**契约：
不新增运行期读取路径、不新增开关、不发 release 行为差异（见「发行口径」）。

本文件是这一面的现行契约（口径、冻结物形状、判据语义、基线对照值、残差）。允许改动面、依赖方向与
清洁检查点见 `docs/spec/state-readers-dependencies.md`；判据的机械真源是 `tests/architecture_cases.gd`
的三条具名检查与 `tests/mutations.json` 的三条突变条目，散文不复述断言文本。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`data/`、`ui/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

## 真源与唯一写者

- `tests/state_readers.json`（schema 1）是读者面的冻结真源，**永不手改**。唯一写者是
  `tools/build_state_readers.gd --write`（headless，SceneTree）；`tools/build_state_readers.gd` 缺省走 `--verify`，
  与三条判据共用 `tests/state_reader_scan.gd::scan` 的同一实现（判据侧只读）。
- `generated_from.inputs_sha256` 覆盖 `core|data|ui` 全部 `.gd` 的归一文本（路径排序，逐文件经
  `tests/source_text.gd::normalized_text_sha256` 取哈希后拼接再哈希）。归一＝只把 CRLF 对折成 LF，
  孤立的 `\r` 与 BOM 原样保留；规则与理由见 `docs/spec/check-routing.md`「输入文本先归一」。
  这些路径下**任何**文本变化（含注释）都让判据红，必须同批重生成并提交（fail-closed）。
  `tests/` 不在输入面（避免自指：`tests/state_reader_scan.gd` 不扫自己）；`tests/state_readers.json` 与
  `tests/state_reader_scan.gd` 也不进 `tests/check_index.json` 的 `case_files`（前者不是 `.gd`，
  后者无 `static func run(`）——重冻索引只在 `tests/architecture_cases.gd` 文本变化时发生。
- `--write` 是确定性的：同一输入的两次运行输出逐字节相同，无时间戳、键序稳定
  （`tests/state_reader_scan.gd::canonical`）。
- 本片改了 `tests/architecture_cases.gd` ⇒ 同批必须 `tools/check-index.ps1 -Write` 重冻
  `tests/check_index.json`，随后 `tools/check-index.ps1` 零漂移绿（既有机制，不是新依赖）。

## 扫描口径（唯一实现＝`tests/state_reader_scan.gd`）

1. **读形态**（接收者按文本匹配 `state`：`state`／`g.state`，以及同一字典的别名接收者 `_g.state`／
   `game.state`／`self.state`）：①`state.<字段>`／`g.state.<字段>`；②`state.get("<字段>"…)`；
   ③`state["<字段>"]`／`state[&"<字段>"]`。同一行多处计多次。
2. **写分离**：纯写 `state.<字段>=(?!=)` 不计读；复合写 `state.<字段>+=`（及 `-=`／`*=` 等）计读 1 次；
   子字段写 `state.<父>.<子>=`／`state.<父>[key]=` 计**父字段**读 1 次（子键名不进表）。
3. **整字典形态**（`core|data`；`ui/` 无此面）：`state` 作为整体被交出／消费的形态进 `whole_state`，
   不进字段计数：`pass`（`…state,`／`…state)` 整字典交出）、`duplicate`（`state.duplicate(`）、
   `iterate`（`for k in (g.)state`）、`has`（`state.has(`）、`get_variable`（`state.get(<非字面量>)`）。
   同一行同一形态只记 1 次（按行计）。
4. **字段登记表**（`tests/state_reader_scan.gd::field_registry`）：`core/game.gd::_init` 的 state 字面键
   （深度 1、后随 `:` 的引号键）＋`core|data|ui` 内任何后续写键（`state.X=`／`state["X"]=`／复合写）＋
   `state.get("X", …)` 名；排序去重。基线 124 个字段。
5. **未知名**：`core|data` 内以读形态出现、又不在登记表、又不在保留方法名
   `{get, has, duplicate}` 里的名字 ⇒ `unknown`（判据红，带 `文件::函数:行`，fail-closed：
   `state.erase(`／`state.keys(` 之类新方法调用同样以未登记名红）。`ui/` 内只认登记表字段名——
   `ui/` 的局部变量 `state`（样式节点名）不是 state 读，不误报。
6. **归属**：接收者形态按行内最近的上一个 `func`／`static func` 声明归属（注释按第一个 `#` 截断）；
   首个声明之前出现的读点归属 `<file>`，由到达性判据判红。
7. **别名接收者**（`ALIAS_DECLARATIONS`，6 个函数）：形参把 state 收在其它名下时，按声明的形参名替换接收者，
   用同一套读形态派生该函数的字段**集合**（不记次数，故写侧同名出现不改集合），单独进 `aliases`，
   不混入 `owners`。
8. **模式串**：`Snapshot.fields(state|g.state, "<spec>")` 调用点按 spec 串（`"名:类型"` 空格分隔）取字段名，
   按所属函数取并集进 `schema_strings`；接收嵌套记录的调用点不进本表（子键不是顶层字段）。
9. **注释与字符串**：每行先按第一个 `#` 截断再匹配；只做文本匹配，不解析 GDScript AST。

## 冻结物内容（`tests/state_readers.json`，schema 1）

| 键 | 形状 | 语义 |
| --- | --- | --- |
| `owners` | `{"文件::函数": {"字段": 出现次数}}` | 直读面：`core|data` 全部读点按 (owner, 字段) 计数（同一函数内同字段读两次记 2） |
| `ui_reads` | `[]` | 架构不变量：UI 直读 state 字段＝0，非空即红 |
| `whole_state` | `[{"file","function","kind","count"}]` | 整字典形态逐处登记（按 (file,function,kind) 聚合，`count` 为该行计数） |
| `aliases` | `{"文件::函数": {"param","fields":[…]}}` | 别名函数的形参名与字段集合（排序） |
| `schema_strings` | `{"文件::函数": {"fields":[…]}}` | 模式串调用点（按函数归并）的 spec 字段并集 |
| `unread_fields` | `[…]` | 登记表里既无直读、又无别名读、又无模式串读者的字段（登记为死字段） |
| `generated_from` | `{inputs_sha256,files,fields,cells,sites,whole_state,ui_reads}` | 输入指纹与统计；`fields`＝有直读的字段数，`cells`＝(owner,字段) 单元数，`sites`＝读点数 |

判据不写死上表的计数：判「派生＝冻结」与双向覆盖；打印行的数字是**当前派生值**（改读面后随重生成移动）。

## 三张只能登记的表与理由

- **整字典读取**：`state` 被整体交出（传参／`duplicate`／迭代／`has`／变量键 `get`）时没有任何字段名参与匹配，
  字段级计数无法归因；这些点改走 `whole_state` 逐处登记，双向（多一处／少一处／计数变化都红）。
  字段计数面因此**不含**这些点（两表互斥，避免同一读点被记两次）。
- **别名形参**：`core/game.gd::_scene_key`／`core/snapshot.gd::{is_current, check, migrate_iron_drone,
  migrate_cup_stacks}`／`core/prison.gd::reinforcement_issue` 把 state 收在形参名下，通用字段计数看不到；
  按声明表派生字段集合并冻结。**非 state 形参的排除表**（理由逐条）在
  `docs/spec/state-readers-dependencies.md`：`core/prison_space.gd::walkable`／`core/prison_space.gd::path` 的
  `s` 是牢房空间字典，`core/snapshot.gd::intent` 的 `p`、`core/snapshot.gd::effect` 的 `e` 是嵌套记录；
  误把排除项计入别名面会改变 `aliases` ⇒ 判据红。
- **模式串**：`core/snapshot.gd::fields(value,spec)` 用字符串里的字段名做存在／类型校验
  （`value[pair[0]]` 动态取值），字段名不写在代码标识符里；接收 state 自身的调用点（基线 7 处，属 4 个函数：
  `core/game.gd::validate` 4 处、`core/mana_flask.gd::validate`／`core/pressure.gd::validate`／
  `core/room_services.gd::validate` 各 1 处）按 spec 字段并集登记；其余 16 处接收嵌套记录（`combat`／`bind`／
  `buff`／`departure` 选项等），键是子键不是顶层字段，按排除处理。

## 失败面（报告，非判据）

- 打印行：`STATE FAILURE FACE fields=%d cells=%d kinds=%d sites=%d` 与逐 kind 的
  `STATE FAILURE FACE kind=<kind> fields=%d cells=%d sites=%d`；落点
  `tests/state_reader_scan.gd::failure_face`（三条判据中的第一条随批打印）。
- 种子（契约冻结的**起点**，不是面本身）：`core/command_registry.gd::ENTRIES` 全部臂
  （`source`／`keys`／`build`／`member`）＋`core/command_registry.gd::FACT_UNITS` 的 `producer`＋
  五道 debug 校验器（`core/consumables.gd::validate_buffs`、`core/torso_binding.gd::state_issue`、
  `data/special_equipment.gd::validate`、`core/card_effects.gd::validate`、`core/relic_effects.gd::validate`）
  ＋`core/game.gd::validate`＋`core/game.gd::get_view`／`core/game_view.gd::build`。
- 面＝种子的**静态调用闭包**（跟随所有分支）：节点＝`文件::函数`，边＝同文件裸调用、常量前缀调用
  （`Snapshot.fields(`／`Enemies.encounter_member(` 等）、`g.<方法>(`（进 `core/game.gd`）、
  `g.<常量>.<方法>(`、`self.<方法>(`；逐 kind 的面再并入 `core/game.gd::command_fact`／
  `core/game.gd::_command_fact_row`。
- **口径诚实性**：闭包跟随所有分支，是**上界**，不是实测读集；数字仅供 P3 消费与规模对照，
  不得写成「实测读集」「判据」或「失败路径只读这些字段」。
- 基线（`b887d28` 派生值）：合计 fields=117／cells=878／sites=1387／kinds=39；逐 kind 例：
  `card` 78/368/553、`chain` 79/373/561、`event` 100/528/876、`attack` 43/135/162、`prison` 41/127/157、
  `item_use` 44/126/153、`hook` 39/106/133、`wall_move` 38/105/137。

## 判据（`tests/architecture_cases.gd`，消息前缀 `STATEREAD`）

| 判据 | 语义（红＝违反） | 突变条目（`tests/mutations.json`） |
| --- | --- | --- |
| `state_read_sites_are_pinned` | 派生（owners／ui_reads／whole_state／aliases／schema_strings／unread_fields／generated_from）与冻结物全等：表外读、表内缺读、计数不符、输入指纹不符都红；随批打印 `STATE READERS files=… fields=… cells=… sites=… whole_state=… ui_reads=… digest=…` 与 `STATE FAILURE FACE …` 报告行 | `state_read_sites_are_pinned`：`core/game.gd::item_action_block` 签名后插恒真探针读 `state.version`（唯一锚＝签名行）⇒ 该 owner 多一处读 ⇒ 红 |
| `state_read_scan_reaches_every_source` | 到达性与覆盖：每行读点的字段名都在登记表（未知名红并给出 `文件::函数:行`）；`ui_reads==[]`；每个 owner 都能解析到非空函数体（改名／空体静默红）；登记表＝「直读∪别名∪模式串∪`unread_fields`」双向（漏一面红）；随批打印 `STATE READERS unknown=… unread=… registry=…` | `state_read_scan_reaches_every_source`：`ui/main.gd::_submit` 的 `game.dispatch(cmd…)` 行后插 `var _probe_state_read=game.state.phase`（唯一锚）⇒ `ui_reads` 非空 ⇒ 红 |
| `state_read_registrations_are_pinned` | 三张登记表的双向：`whole_state` 逐 (file,function,kind,count) 相等；`aliases` 与冻结的逐函数字段集合相等且每个声明别名都能解析到非空体；`schema_strings` 的并集相等；随批打印 `STATE READERS REGISTRATIONS …` | `state_read_registrations_are_pinned`：`core/game.gd::command_issue` 体首插 `var _probe_whole_state=state.duplicate(true)`（唯一锚＝签名行）⇒ `whole_state` 多一处 ⇒ 红 |

突变条目的锚唯一性与「RED＋逐字节还原」由 `tools/check-mutation.ps1` 执行：
`& tools/check-mutation.ps1 -Check state_read_sites_are_pinned,state_read_scan_reaches_every_source,state_read_registrations_are_pinned`。
重生成入口：`& tools/check-index.ps1 -Write`（索引同批重冻）与
`& $env:GODOT_BIN --headless --path . --script res://tools/build_state_readers.gd -- --write`／`-- --verify`。

## 基线对照值（`b887d28` 派生值，非判据钉值）

- 扫描面：`files=129`（源文件数＝`tests/check_index.json` 的 `stats.source_files`）；
  登记表 124 字段；有直读的字段 121；读点 2075（`state.<字段>` 1950／`state.get("<字段>"…)` 56／
  复合写 69／`state["<字段>"]` 0）；读者函数 527；(owner,字段) 单元 1264；按目录 `core` 2034／`data` 41／`ui` 0。
- `whole_state` 52 处（pass 43／duplicate 6／iterate 1／has 1／get_variable 1），聚合 37 条记录。
- `aliases`：`_scene_key` 8／`is_current` 1／`check` 61／`migrate_iron_drone` 1／`migrate_cup_stacks` 5／
  `reinforcement_issue` 5（`check` 的设计期估计为 59，差异来自 `s.get("…")` 形态计入）。
- `schema_strings`：4 个函数、7 处调用点、15 个字段名。
- `unread_fields`＝`["dexterity","strength"]`（两者也从未被写入，属死字段）；`ui_reads`＝`[]`；`unknown`＝`[]`。

## 残差与仍靠人审（无机械判据）

- **新别名不被自动发现**：新写一个把 state 收进形参的函数，通用计数只看到 `state.<字段>` 形态，不会自动
  归因；必须按仓规登记进 `ALIAS_DECLARATIONS`（`tests/state_reader_scan.gd`）并同批重生成，否则该函数的读
  是静默面。声明本身的双向（多／少一个函数或字段都红）已由 `state_read_registrations_are_pinned` 钉住。
- **模式串并集口径的盲点**：同一函数内新增一处与既有 spec 字段集相同的调用不改并集，不红（按函数并集登记）。
- **变量键字段面不可归因（静默面，登记为仍靠人审）**：`state[变量]` 形态的**读取不进入任何表**——现探 19 处
  非字面 `state[` 形态（读／写／复合混合；其中 `for item in g.state[field]`／`float(g.state[key])` 等为纯读或
  迭代读），全部静默、无字段级记录；`get_variable` 仅覆盖 `core/equipment_replacement.gd::_commit_changes`
  的 `state.get(<非字面量>)` 一处，不构成对本形态读的覆盖。新增此类读点不经判据变红，须人审（审查记录：独立
  审查实测该类纯读 ≥11 处，与上列一致）。
- **子键与嵌套记录**：子键名（`state.combat.serial` 的 `serial` 等）不登记；嵌套记录上的 `Snapshot.fields`
  按排除处理（理由见上）。
- **变量键写**：`state.rng[domain]=0` 这类变量键写不计读、也不进 `whole_state`（形态不属于五类之一）；
  其对父字段的读由同行的父字段读形态承担。
- **整字典形态按行级文本匹配**：`pass`／`duplicate`／`has`／`get_variable` 按行匹配一次、不区分接收者——
  名字恰为 `state` 的成员访问（`x.state`）与整字典交出同样计入；同一字典的别名接收者
  （`_g.state`／`game.state`）计入是正确的，其它对象的 `state` 子键若出现，`whole_state` 的逐处登记
  供人审核对。
- 登记表与三张表是**声明面**，不是行为面：本片不含运行期读观察（见「发行口径」）。

## 发行口径

- 本片不产出 release 运行期面：判据只在 `architecture` 套件（debug/headless 引擎）运行；
  派生读的是源码文本、与构建类型无关（不存在 release/debug 两套派生结果）；
  release 二进制**无对应行为差异**，也没有「release 已验证」结论。
- 不打包、不发版、不改版本号（红线见根 `AGENTS.md`「禁区」）。
