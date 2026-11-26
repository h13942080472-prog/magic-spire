# 塔路历史（state.route_history）

契约文件：`state.route_history` 是存档 state 里的**加性**字段，按「局 → 周目 → 塔路」记录每次塔路切换。
内部实现以代码为准，接口语义以本文件为准；函数名与稳定 ID 是锚点，本文件不写行号。
本文件不写执行结果：通过／失败／未执行与红集登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 收束对象：`state.route_history` 的记录形状、进入原因、关闭口径与写入面。
- 记录粒度为**塔路**：一张地图从生成到被替换的整个生命期。被捕不是塔路切换（地图不换，
  只追加 `prison` 房）；被捕后的服刑出狱与越狱才是切换。
- 文件域：`core/route_history.gd`（唯一写入者）、`core/game.gd`（`_init` 字面、`TRANSITIONS` 的
  `route` 列、`_apply_transition` 的唯一追加点、`restore_snapshot` 的唯一回填点）。
- 非目标：不改存档格式与 `Snapshot.REVISION`；不把地图、走过的节点、进入时的版本或时间／随机值
  放进 state（归档所需的 `run.segments` 属后续塔路归档切片的信封内容，不在本片）；不改 `_restart_tower`
  的签名；不改 `core/prison.gd`、`core/demo_exit.gd`。

## 接口

```gdscript
# 唯一写入者：纯 static，经传入的 g 访问，不 preload 其它模块。
core/route_history.gd::open(g, kind: String) -> void      # 关闭上一条，追加下一条
core/route_history.gd::reason(g, kind: String) -> String  # 推导进入原因
core/route_history.gd::backfill(s: Dictionary) -> Array   # 旧档回填为单条 unknown 记录
```

- **记录形状固定为九个键**：`enter`、`cycle`、`generation`、`region`、`seed`、`boss`、`security`、
  `nodes`、`floor`。

| 键 | 写入时机 | 取值 |
| --- | --- | --- |
| `enter` | 打开时 | `start`／`release`／`escape`／`gate_exit`／`cycle`／`unknown`（见下表） |
| `cycle` | 打开时 | `state.demo_cycle` |
| `generation` | 打开时 | `state.tower_generation`（越狱路线不加代数，与前一条相同） |
| `region` | 打开时 | `state.map_region`：`tower` 或 `prison` |
| `seed` | 打开时 | 打开时的 `state.seed`（该条路线自己的塔种子；换塔后旧记录的 `seed` 不等于新的 `state.seed`） |
| `boss` | 打开时 | `tower`：`state.room_encounters.get("summit","")`（稳定 ID）；`prison`：`""` |
| `security` | 打开时 | `state.security` |
| `nodes`、`floor` | 下一条打开时回写（关闭本条） | `completed_rooms.size()`，以及已完成房间的最高层＋1；仍在进行的最后一条为 `-1`／`-1` |

- **唯一追加点**：`core/game.gd::_apply_transition` 的 `if not continuation:` 块，由迁移声明表
  `TRANSITIONS` 的 `route` 列派生（`setup_init`／`tower_restart`／`prison_escape`）。同一 kind 的
  房间／阶段两段写入只追加一条（沿用 `continuation` 语义）。三个调用方共用这一处写入。
- **进入原因**（`reason`，只读 `kind`、上一条记录与挂载点当时的 `state`）：
  - `setup_init` → `start`；
  - `prison_escape` → `escape`；
  - `tower_restart`：`demo_cycle` 大于上一条的 `cycle` → `cycle`；否则挂载点当时 `state.prison` 仍非空
    → `release`（服刑出狱：`core/prison.gd::completed_turn` 路径；`core/game.gd::_restart_tower` 在
    挂载点之后才清空牢房）；否则上一条 `region=="prison"`（越狱路线）→ `gate_exit`；其余 → `release`。
  - 依据：`DemoExit.continue_run` 先 `demo_cycle+=1` 再 `_restart_tower(true)`，调换这两步顺序会让
    `cycle` 被误判为 `release`。`Prison.escape` 清空 `state.prison`，击败出口守卫后
    `core/prison.gd::return_to_tower` 执行时牢房已空。越狱路线在出口守卫战再次被收押、服满刑期时，
    上一条记录的 `region` 仍是 `prison` 而牢房非空，所以判别信号取当时的 `state.prison`；按上一条
    `region` 推断会把这条「服刑出狱」误记成 `gate_exit`。
- **关闭口径**：`open` 先用当前 `completed_rooms` 关闭上一条；楼层按**该条记录自己的**
  `region`／`seed`／`boss`／`security` 重建当时的路线图（`Tower.generate`／`Tower.prison_route`
  都是确定性的），不读切换后的新图；夹具改名后的 id 才回落到当前 `state.rooms` 的同名房间。
  `nodes` 是已完成房间数；`floor` 是**已完成房间**的最高层＋1。这与 `ui/run_review.gd::_progress_text`
  的口径不同：那里把当前所在房间也计入 `floor`，当前房间比最高已完成房间更深时两者给出不同的层数。
- **回填**：`core/game.gd::restore_snapshot` 在 `initial_seed` 回填之后、`Snapshot.check` 之前，对
  **载入副本**补一条 `enter="unknown"` 记录（`nodes`／`floor` 留 `-1`，等下一次真正关闭时补齐）。
  读不写盘；调用方字典与文件字节都不变。`Snapshot.check` 验证数组及每条记录的九个必填字段类型。记录损坏时拒绝载入，保留当前游戏。
- **不升 `Snapshot.REVISION`**：加性字段不升版（依据 `docs/spec/save-fixed-points.md`）。
  同种子、同指令串复现同一段历史：记录不含时间、版本、外部标识或随机值，也不消费任何随机域。
- **新档被旧版本读取**：本字段引入之前的版本打开其后写的档时，`Snapshot.check` 不拒绝多出的键，
  读档会原样保留 `route_history`，但旧版本不会追加记录，历史因此缺段。这种降级是静默的（不升版、
  没有版本警告），且不做缺段修复；旧版本再写出的档仍带着那段不完整的历史。

## 输入域

真实切换点（全部经既有迁移 kind；`unknown` 只由回填产生）：

| `enter` | 迁移 kind | 调用链 |
| --- | --- | --- |
| `start` | `setup_init` | `Game._init`；`Tower.generate` 总会放入 `entrance` 房 |
| `release` | `tower_restart` | `Prison.completed_turn` → `_restart_tower()` |
| `escape` | `prison_escape` | `Prison.execute`（`vent_exit`／`door_exit`）或 `return_seal` → `Prison.escape` |
| `gate_exit` | `tower_restart` | `Prison.after_preparation` → `return_to_tower` → `_restart_tower()` |
| `cycle` | `tower_restart` | `DemoExit.continue_run` → `_restart_tower(true)` |
| `unknown` | — | `restore_snapshot` 回填（旧档缺字段） |

- 同周目内 `boss` 保留：`release` 与 `gate_exit` 的 `_restart_tower` 不带 `from_exit`，沿用
  `state.room_encounters` 的峰顶遭遇；只有 `cycle`（`from_exit=true`）才可能换首领。
- `release` 覆盖两条真实路径：塔路内被捕后服刑出狱，以及越狱路线在出口守卫战再次被收押后服刑出狱；
  `gate_exit` 只对应「击败出口守卫、整备完成回到塔路」这一条路径。
- 越狱路线 `region=="prison"` 且 `boss==""`，守卫数取 `security`。
- 练习局不经过 `setup_init`；`Prison.exit_practice` 会走 `escape`，所以练习位里可能出现一条
  `escape` 记录。练习局不归档，core 不为此加练习判断。
- 加固矩阵：进入原因 {`start`、`release`、`escape`、`gate_exit`、`cycle`} ×
  存档 {新档、缺 `route_history` 的旧档、`IRON_DRONE_REVISION` 迁移档}，共 15 格；
  每格从真实命令推进到切换点，再经真实 `dispatch` 触发切换。

## 失败语义

- 追加只发生在 `dispatch` 的事务内；被拒绝的提交随 state 一起回滚，不留部分记录。
- 挂载点必须在 `if not continuation:` 块内：同一 kind 的两段写入只算一次切换；移出块外会让一次切换
  记两条。
- 回填只发生在载入副本上；不得写回调用方字典、存档文件或玩家数据。

## 证据入口

| 判据 | 落点（分类） |
| --- | --- |
| `ROUTEHIST-1`～`ROUTEHIST-12`（正例、最近反例、四种切换、去重、确定性、原子性、旧档与迁移回填且回填不改存档修订号、往返一致） | `tests/persistence_cases.gd`（`persistence`） |
| `route_history_second_capture_release`（越狱路线在出口守卫战再次被收押后服刑，`enter=="release"`） | `tests/persistence_cases.gd`（`persistence`） |
| `route_history_cycle_capture_release`（`cycle` 之后在新一代塔路被捕服刑，`enter=="release"`） | `tests/persistence_cases.gd`（`persistence`） |
| `route_history_switch_matrix`（15 格切换矩阵：条数与 `enter`／`cycle`／`generation`／`region`／`boss`） | `tests/persistence_cases.gd`（`persistence`） |
| `route_history_single_writer`（唯一写入者、唯一调用点、追加在 `not continuation` 块内、无别名写） | `tests/architecture_cases.gd`（`architecture`） |
| `route_history_references_are_pinned`（引用白名单：`core`／`data`／`ui` 里引用 `route_history` 的位置只允许 owner 模块、`core/game.gd` 的三行及 `core/snapshot.gd::check`） | `tests/architecture_cases.gd`（`architecture`） |
| `route_switch_declared`（带 `route` 的 kind 恰为三个） | `tests/architecture_cases.gd`（`architecture`） |
| `route_reason_branches_declared`（`cycle` 分支先于 `prison` 分支） | `tests/architecture_cases.gd`（`architecture`） |
| `route_reason_called_only_by_open`（`reason` 只由 `open` 调用，`_serving_sentence` 只由 `reason` 调用；`core`／`data`／`ui` 里经 `RouteHistory` 句柄调用这两个函数，或给句柄起别名，都判红） | `tests/architecture_cases.gd`（`architecture`） |
| `route_legacy_backfill_is_pinned`（回填位置与次数） | `tests/architecture_cases.gd`（`architecture`） |
| `route_history_no_version`（记录键与源文本不含时间／版本／随机值） | `tests/architecture_cases.gd`（`architecture`） |

- 命令（在 `spire-godot/` 下执行；结果与域写 `docs/record/verification.md`）：

```powershell
& tools/check.ps1 -Suite persistence,architecture -TimeoutSeconds 900
& tools/check.ps1 -Suite persistence,tower_progression,prison,architecture -TimeoutSeconds 1800
```

- 判读：退出码 0；每个 `SUITE RESULT: PASS <name>`；`summary.json` 的 `status=passed` 且
  `before==after` 指纹（`source_changed` 不算通过）。
- 依赖约束：`core/game.gd → core/route_history.gd` 为本片新增的唯一依赖边；`core/route_history.gd`
  不 preload 其它模块，也不引用 `update/`。允许改动面＝`core/route_history.gd`（新）、
  `core/game.gd`（上述四处）、`core/snapshot.gd::check`（读档校验）、`tests/persistence_cases.gd`、`tests/architecture_cases.gd`、
  `tests/mutations.json`；生成物只经唯一写者重冻。
