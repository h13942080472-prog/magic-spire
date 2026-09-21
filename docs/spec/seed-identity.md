# 本局种子标识（初始种子 · 塔路次数 · 查看与复制）

契约文件：本局标识的保存、校验、读档回填、只读投影，以及玩家在地图角落查看与复制的语义。
内部实现以代码为准，接口语义以本文件为准；函数名与稳定 ID 是锚点，本文件不写行号。
本文件不写执行结果：通过／失败／未执行与红集登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 收束对象：**本局标识的字段、校验、回填与玩家可见的查看／复制**。标识＝
  （`state.initial_seed`，`state.tower_generation`）。
- 不含：塔路生成与随机域本身（见 `docs/design/content.md` §3）、当前塔路种子的改写时机
  （`core/game.gd::_restart_tower`）、存档写入时机与固定点（见 `docs/spec/save-fixed-points.md`）、
  反馈上传（见 `docs/spec/feedback-deployment.md`）。
- 明文口径：标识是**本局的稳定身份**，不是复现配方。当前塔路种子与各随机域计数随游玩推进，
  房间库还按 `seed`＋`tower_generation`＋房间 ID 派生（`core/room_services.gd`）；
  精确复现当前进度只由反馈一并上传的存档承担（`SaveStore.fixed_point_text`）。

## 接口

```gdscript
# 写入一次、此后不变：core/game.gd::_init
state.initial_seed: int          # = _init 的 run_seed
# 既有字段与被改写点不变：state.seed 由 _restart_tower 改写，state.tower_generation += 1

# 唯一正式恢复入口＝唯一回填点：core/game.gd::restore_snapshot(saved) -> {ok, error?, code?}
#   is_current(saved) 通过后、Snapshot.check 之前，对**副本**回填：
#   if not candidate.has("initial_seed"): candidate.initial_seed = candidate.get("seed", 0)
#   随后 state = candidate（一次深拷贝）；调用方传入的字典不被改动。

# 只读投影（UI 不读 game.state）：core/game_view.gd::build
#   追加 {"initial_seed": state.initial_seed, "tower_generation": state.tower_generation, …}

# UI：唯一文本与复制入口（ui/main.gd）
func seed_report_text() -> String   # 复制文本，四要素；见下
func copy_seed() -> String          # = DisplayServer.clipboard_set(seed_report_text()) + 显示态

# 控件：地图工作区右上角（`RouteMessages` 顶部标题行右端）按钮 `SeedChip`
ui.seed_copied_until: int           # 复制反馈的显示截止（msec）
```

- **校验沿用通用字段校验**：`Snapshot.check` 的 `for key in g.state` 循环已要求 `initial_seed` 存在且为
  `int`（string／float 一律拒绝，文案沿用「基础数值记录不正确。」）。`core/snapshot.gd` **零改动**；
  `Snapshot.REVISION` **不升**（升版会把既有玩家存档判为不兼容）；**不得**把 `initial_seed` 加入
  `character_id` 一类的豁免名单。
- **旧档且只旧档回填**：缺 `initial_seed` 的档按当时的 `state.seed` 回填；缺 `save_revision` 或
  修订号不符的档仍按既有规则拒绝，不因回填规则放宽。
- `_scene_key` **不变**（仍只用既有键）：`initial_seed` 在单局内恒定，加入不改变固定点身份语义。
- 次数口径：出狱返塔与出口「继续游玩」都会重建塔路并使 `tower_generation + 1`；新局与练习局从 0 起。
  「第 N 次塔路」＝`tower_generation + 1`，由显示层计算，core 不新增派生字段。

### 显示与复制文本

- 显示：`ui._text("ui.map.seed","初始种子 {initial} · 第 {iteration} 次塔路", …)`。
- 复制（四要素必须齐；文字可调，结构不改）：
  `紧缚尖塔 · 初始种子 <initial_seed> · 第 <tower_generation+1> 次塔路 · 当前塔路种子 <view.seed>（精确复现需同批上传的存档）`
- 复制后 1200 ms 内控件显示 `ui._text("ui.map.seed_copied","已复制")`；到期复原。失效守卫沿用
  `_queue_map_step` 的写法（`is_inside_tree()`＋截止时间），旧回调不得改写新一局或已关闭的界面。

## 输入域

- 可见性唯一判据＝**路线屏是否被渲染**：地图相位（`map`／`travel`／`cleared`／`pack`）与任意相位的
  「地图」覆盖显示 `SeedChip`；普通战斗屏与 `view.practice` 的练习屏（`_practice_screen`）不显示。
  不得引入第二判据。
- 位置：`RouteMessages` 顶部标题行右端，不新增布局行；不覆盖 `TowerMapScroll`／`TowerRoute`，
  不与 `MapOverview`／`MapLocate`／`MapClearDrawing` 相交。
- 点击只写剪贴板与显示态：不派发候选、不读随机、不写盘、不进 `_submit`、不改 `game.state`。
- 英文缺译走既有回退（`ui._text` 的第二参数），不强制随本片新增译文。

## 失败语义

- `initial_seed` 类型损坏：恢复失败，走既有「不可恢复」路径（回主页、保留原文件、当前局不变）。
- 缺 `initial_seed` 的旧档：恢复成功并回填，不得因此判为损坏。
- 回填不得改动调用方字典；`restore_snapshot` 失败时 `state` 不变（既有原子性）。
- 剪贴板不可用（无窗口驱动）不构成失败分支：不读回校验，也不改任何游戏状态；剪贴板判据只在
  有窗口的 UI 阶段成立。

## 证据入口

具名 check（规则侧走真实构造与真实重建，UI 侧走真实控件与真实点击）：

| 判据 | 落点（分类 → 用例文件） |
| --- | --- |
| `SAVE initial_seed is fixed at run start`（`Game.new(42)` 的 `initial_seed==42`；真实重建后 `state.seed!=initial_seed`、`initial_seed` 不变、`tower_generation==1`、投影两键同步） | `persistence` → `tests/persistence_cases.gd` |
| `SAVE initial_seed survives a round trip`（隔离目录 pack→unpack→`restore_snapshot`，字段与当前塔路种子一并还原） | `persistence` → `tests/persistence_cases.gd` |
| `SAVE legacy save without initial_seed loads and backfills from seed`（活档 `erase("initial_seed")` 后恢复成功、`state.initial_seed==state.seed`、调用方字典未被改动） | `persistence` → `tests/persistence_cases.gd` |
| `SAVE initial_seed uses the shared field check`（`"42"`／`42.0` → 恢复失败，文案与既有类型错误一致） | `persistence` → `tests/persistence_cases.gd` |
| `SAVE UI damaged initial_seed is unrecoverable`（既有损坏矩阵增一项，判据＝**类型错误**；缺键是上一条正例，不算损坏） | UI `persistence` → `tests/persistence_ui_cases.gd` |
| `ROUTE seed chip shows initial seed and tower iteration`（文本含初始种子与「第 1 次塔路」；rect 在 `RouteMessages` 内、与地图滚动区与既有地图控件不相交） | UI `route` → `tests/route_ui_cases.gd` |
| `ROUTE seed chip follows a rebuilt tower`（真实重建后显示「第 2 次塔路」，初始种子不变） | UI `route` → `tests/route_ui_cases.gd` |
| `ROUTE seed chip copies the labelled identity`（真实点击 → `DisplayServer.clipboard_get()==ui.seed_report_text()`，四要素齐；「已复制」1.2 s 后复原） | UI `route` → `tests/route_ui_cases.gd` |
| `ROUTE seed chip is not part of rules, candidates or randomness`（点击前后 `export_snapshot()` 逐字节相同、无候选被消费、无新日志、未写盘） | UI `route` → `tests/route_ui_cases.gd` |
| `ROUTE seed chip is bound to the route screen`（普通战斗屏与练习屏无 `SeedChip`；`OpenMap` 的六个相位各出现一次） | UI `route` → `tests/route_ui_cases.gd` |

命令（在 `spire-godot/` 下执行；范围预检加 `-ListOnly`，不算通过）：

```powershell
& tools/check.ps1 -Suite persistence -Impact -KeepGoing -TimeoutSeconds 600
& tools/check.ps1 -UIOnly -UISuite persistence,route -TimeoutSeconds 900
```

- 判据：退出码 0；每分类 `SUITE RESULT: <name> PASS`；`summary.json` 的 `status=passed` 且
  `before==after` 指纹（`source_changed` 不算通过）。
- 在 `--headless` 下不得宣称剪贴板判据通过。
- 依赖约束（cleaner 可核对）见 `docs/spec/seed-feedback-dependencies.md`。
