# 状态迁移管线（同类迁移一条主路径）

契约文件：`state.phase`／`state.room` 的写入与「战斗是否结束」的判定／执行都必须只有一条主路径。
内部实现以代码为准，接口语义以本文件为准；函数名与稳定 ID 是锚点，本文件不写行号。
本文件不写执行结果：通过／失败／未执行与红集登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 收束对象：`state.phase` 与 `state.room` 的全部写入点、战斗结束的判定点与执行点。
  目标＝判定一处、写入一处、可枚举可检查；散落点只允许「调用主路径」，不得保留第二条写入路径。
- 文件域：`core/game.gd`（声明表 `TRANSITIONS` 与主路径 `_apply_transition`／`_battle_end_reason`／
  `_finish_battle`／`_room_transition_kind`）＋ 调用方 `core/guard.gd`、`core/prison.gd`、
  `core/room_events.gd`、`core/room_services.gd`、`core/departure.gd`、`core/demo_exit.gd`。
- 非目标：不改存档格式与语义（`pack`／`unpack`／`snapshot` 校验、`save_revision`）、
  不改玩家可见文案与数值、不改 `ui/**`、不改随机域与消耗、不改 `dispatch` 的事务／回滚／版本／
  场景起点冻结语义；不做全量回归、不打包、不发版。
- 本管线为固定点存档（`docs/spec/save-fixed-points.md`）预留挂点：声明表的 `checkpoint` 列与
  进程内迁移日志；本管线自身不消费迁移日志。

## 接口

```gdscript
# 全仓唯一写 state.phase／state.room 的地方。返回 ""＝成功，否则 issue（沿用既有失败字符串风格）
_apply_transition(kind: String, args: Dictionary = {}) -> String

# 唯一战斗结束判定："" ／ "victory" ／ "saturated" ／ "captured"
_battle_end_reason() -> String

# 唯一战斗结束执行——只拥有胜利／饱和的奖励体；收押不走这里（见下）
_finish_battle(end_kind: String = "victory") -> void

# 进入房间时使用的 kind：目标层高于当前层 ⇒ floor_enter，否则 ⇒ room_enter
_room_transition_kind(target: String) -> String
```

- `_apply_transition` 读声明表 `TRANSITIONS`，按 `kind` 写声明的 `phase`／`room` 字段，并追加一条
  **迁移日志**：`_transition_log: Array[String]`（元素＝`kind`）——**只存在于进程内**，
  **不进 `state`／不进存档／不进 View**；测试侧用只读助手读取
  （`tests/architecture_cases.gd::transition_log`／`transition_delta`／`transition_kinds`）。
- **立即写入、单一写入者，不做「事务末统一执行」**：事务中段会读 `state.phase`，延后会改变行为；
  本管线只收束**判定与赋值**，不改变赋值在控制流中的位置。
- **随机域**：主路径只写 `phase`／`room`（既有副作用留在原处），不得新增或减少任何随机消耗。
- 迁移日志的一次迁移＝一条：同一 kind 的 `phase`／`room` 由调用点分两次写入时（收押），
  第二条若只写还没写过的字段则不再记（continuation 判据）；重复写同一字段仍是新的一次迁移。
- 与 `dispatch` 事务、回滚、版本、场景起点冻结的关系（**不得改变**）：

| 关注点 | 约定 |
| --- | --- |
| 事务边界 | 主路径在 `dispatch` 的事务副本内被调用（与收束前的写入点相同） |
| 失败回滚 | 任一 issue → `state=original`，不留部分变化；不得新增「部分写入后再报错」的路径 |
| `version` 递增 | 仍只在成功提交时一次 |
| 场景起点冻结 | `_commit_scene_start` 仍是场景键变化才重冻；本管线不消费迁移日志 |

### 迁移声明表 `TRANSITIONS`

`const TRANSITIONS = {kind: {"phases":Array[String], "room":bool, "tx":bool, "checkpoint":String, "owners":Array[String]}}`
（`checkpoint` 缺省＝不是固定点；kind 全集与 checkpoint 列的机读冻结副本＝
`tests/architecture_cases.gd::TRANSITION_KINDS`／`TRANSITION_CHECKPOINTS`，
检查＝`tests/architecture_cases.gd::transition_kind_set_pinned`。）

- `phases`＝该 kind **允许**写入的阶段；空＝不写阶段。写入值由调用点经 `args.phase` 给出且必须落在集合内。
- `room=true`＝该迁移允许改当前房间；写入值由调用点经 `args.room` 给出。
- `tx=false`＝构造／练习等事务外路径（`tx` 列只登记事实，供存档切片消费）。
- `checkpoint` 非空＝该 kind 是进度固定点（取值 `floor`／`battle_end`／`prepare_end`）；
  缺省＝不是。**固定点语义与写盘规则见 `docs/spec/save-fixed-points.md`**，本表只声明事实。
- `owners`＝允许触发该 kind 的调用者；每个 kind 有**唯一实现分支**。

| kind | 允许写入的阶段 | 改 room | tx | checkpoint | owners |
| --- | --- | --- | --- | --- | --- |
| `setup_init` | `map` | 否 | 否 | — | `_init` |
| `tower_restart` | `map` | 是 | 是 | — | `_restart_tower` |
| `practice_init` | （不写） | 是 | 否 | — | `_start_practice` |
| `prison_cell_init` | （不写） | 是 | 否 | — | `Prison.start_practice` |
| `prison_gate_init` | （不写） | 是 | 否 | — | `Prison.exit_practice` |
| `battle_start` | `battle` | 否 | 是 | — | `_start_battle` |
| `battle_end_victory` | `reward`／`event` | 否 | 是 | `battle_end` | `_finish_battle` |
| `battle_end_saturated` | `reward`／`event` | 否 | 是 | `battle_end` | `_finish_battle` |
| `battle_end_captured` | `captured` | 是 | 是 | `battle_end` | `Guard.capture` |
| `prepare_start` | `prepare` | 否 | 是 | — | `_start_preparation` |
| `prepare_end` | `pack`／`map`／`cleared` | 否 | 是 | `prepare_end` | `_finish_preparation` |
| `rest_start` | `rest_choice`／`rest` | 否 | 是 | — | `_start_rest`／`_begin_rest` |
| `room_enter` | `map`／`cleared` | 是 | 是 | — | `_arrive_room` |
| `floor_enter` | （不写） | 是 | 是 | `floor` | `_depart`／`_advance_travel` |
| `travel_start` | `travel` | 否 | 是 | — | `_depart` |
| `prison_cell_enter` | `prison` | 否 | 是 | — | `Prison.begin_turn` |
| `inspection_start` | `inspection` | 否 | 是 | — | `Prison.end_turn` |
| `prison_exit_battle_start` | `battle` | 否 | 是 | — | `Prison.execute` |
| `prison_escape` | `map` | 是 | 是 | — | `Prison.escape` |
| `event_enter` | `event` | 否 | 是 | — | `Events.start` |
| `event_leave_empty` | `map` | 否 | 否 | — | `Events.start` |
| `event_item_rewards` | `reward` | 否 | 是 | — | `Events.begin_item_rewards` |
| `shop_enter` | `shop`／`treasure` | 否 | 是 | — | `Services.start` |
| `departure_start` | `departure` | 否 | 否 | — | `Departure.start` |
| `departure_end` | `map` | 否 | 是 | — | `Departure.execute` |
| `demo_end` | （不写） | 否 | 是 | — | `_execute` |

## 输入域

- `kind` 必须是 `TRANSITIONS` 已声明的键；`args.phase` 必须落在该 kind 的 `phases` 内；
  `args.room` 只在该 kind `room=true` 时生效。
- 调用者必须是该 kind `owners` 声明的函数；**副作用（生成敌人、滚奖励、收押清理、牢房初始化等）
  留在原函数、原顺序**，不下沉进主路径。
- 硬线：**`state.phase=`／`state.room=` 只允许出现在 `_apply_transition` 内**；其余写入点一律改为
  「调用 `_apply_transition("<kind>", {…})`」。
- 收押（`battle_end_captured`）：`Guard.capture` 对同一 kind 调用 `_apply_transition` **两次**
  （先 `phase`、后 `room`），**不经过 `_finish_battle`**；收押的所有副作用仍在 `Guard.capture`、顺序不变。
- `floor_enter` **只认上行**（目标 `floor` 更高）；同层换房用 `room_enter`。`floor_enter` 只用于
  真实移动与换塔落点；构造期写入由各自构造 kind 承担。
- 已冻结的不可达路径：`_enemy_phase` 尾部的战斗结束判定在真实流程不可达（仅非法卡链状态可达），
  但**保留**——它仍在源码里参与判定，删掉属行为变更。将来若要删除，须单独立批并给出「不可达」证明
  与 oracle 影响面。
- 构造期路径（`tx=false`）经主路径只做赋值，**不得引入新的校验失败**。

## 失败语义

- 未声明的 `kind` → `push_error` 并返回 `"未声明的状态迁移：<kind>"`（不写任何字段）。
- `args.phase` 不在该 kind 的 `phases` 内 → `push_error` 并返回 `"迁移<kind>不接受阶段：<phase>"`
  （不写任何字段）。
- 其余 issue 一律由既有回滚路径处理：`state=original`，不留部分变化；不得新增「部分写入后再报错」
  的路径，不得把失败降级为静默。
- 禁止：把写入退化为「注释式清单」（表里写了 kind、代码仍各写各的）；合并判定时减少调用位点
  （会改变随机消耗与日志顺序）；让 `state.phase`／`state.room` 出现第二处写入点；
  为凑绿删弱既有断言或把套件从门禁里拿掉。
- 固定点相关的算未完成口径见 `docs/spec/save-fixed-points.md`；本管线只对「判定与写入唯一」负责。

## 证据入口

- **闭环 check**：`tests/architecture_cases.gd::transition_write_sites_are_pinned`。
  扫描面＝`core/**/*.gd`（`#` 之后按注释截断，排除 `==`），四组模式：
  ① `state.room=`／`g.state.room=` ② `state.phase=`／`g.state.phase=` ③
  `_finish_battle(`／`_finish_if_saturated(`／`_battle_end_reason(` ④ `_restart_tower(`。
  双向比对：扫描集 ⊆ 钉住点表 **且** 表内每一点都被扫到（表外或未命中都打印 `文件:行:函数`）。
  另断言：`state.phase`／`state.room` 各恰有 1 处写入点（都在 `_apply_transition` 内）；
  战斗结束判定只来自 8 个函数；`tower_restart` 的 4 个钉住点保留。
- **行为基线**：`tests/architecture_cases.gd::behavior_baseline_equivalence`（显示字段、提交结果字典、
  拒绝文案、`export_snapshot()`、随机域计数的逐字段比对与显式 mask）承接原「迁移 oracle」的行为逐字节
  不变判据；历史 oracle 脚本与基线只存在于已忽略的 `build/`，不作为当前门禁。
- 具名 check（分类点名，全部走真实公开命令：发指令 → `dispatch`；不得直接调 `_apply_transition`
  或手工改 `state.phase` 伪造迁移）：

| 判据 | 落点（分类） |
| --- | --- |
| `battle_end_single_path_for_all_entry_points` | `tests/battle_reward_cases.gd`（`rewards`／战斗结束入口） |
| `prepare_end_three_branches_one_kind` | `tests/battle_reward_cases.gd` |
| `floor_enter_is_one_family`、`demo_end_and_tower_restart_use_declared_kinds` | `tests/tower_cases.gd`（`tower`） |
| `capture_routes_through_the_main_path` | `tests/guard_cases.gd`（`guard`） |
| `non_transitions_do_not_write` | `tests/service_cases.gd`（`services`／`events`） |
| `transition_log_never_reaches_state_or_view` | `tests/persistence_cases.gd`（`persistence`） |
| `transition_write_sites_are_pinned` | `tests/architecture_cases.gd`（`architecture`） |

- 命令（在 `spire-godot/` 下执行；结果与域写 `docs/record/verification.md`）：

```powershell
& tools/check.ps1 -Suite core,rewards,battle_saturation,guard,prison,tower,tower_progression,events,event_flow,persistence,architecture -Impact -TimeoutSeconds 900
& tools/check.ps1 -UIOnly -UISuite persistence,home,events -TimeoutSeconds 900
```

- 判读：退出码 0；每个 `SUITE RESULT: PASS <name>`；`summary.json` 的 `status=passed` 且 `before==after`
  指纹（`source_changed` 不算通过）；报告带墙钟。未跑、未知、被跳过的分类不得计入通过。
- `content/packs` 未改动时不跑 `check-content.ps1`（非本管线范围）。
