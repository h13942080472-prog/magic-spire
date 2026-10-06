# 本局回顾（战报面板：本局标识 · 节点概况 · 卡组）

契约文件：回顾面板的入口可见性、三块取源、只读保证、只读地图口径、布局、失败语义与验证判据。
内部实现以代码为准，接口语义以本文件为准；函数名与稳定 ID 是锚点，本文件不写行号。
本文件不写执行结果：通过／失败／未执行与红集登记 `docs/record/verification.md`。
依赖约束索引（判据＝检查符号）见 `docs/spec/run-review-dependencies.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 收束对象：**玩家在路线屏与通关屏打开的本局回顾面板**——它把本局标识、节点概况（只读紧凑地图＋进度行）
  与卡组列表放在同一个抽屉里展示。
- 不含：塔路生成与路线投影本身（`core/game.gd::route_view`，见 `docs/spec/response-pipeline.md`）、
  本局标识的字段与复制语义（见 `docs/spec/seed-identity.md`）、卡面文案的按需投影
  （见 `docs/spec/ondemand-copy.md`）、存档与固定点（见 `docs/spec/save-fixed-points.md`）。
- 明文口径：回顾面板是**纯只读显示入口**。它不产生提交、不消费候选、不推进随机、不写盘，
  也不改显示态以外的任何运行状态；打开与操作后 `view.version`、`export_snapshot()`
  与存档字节必须逐字节不变。

## 接口

### 面板组装（唯一入口）

```gdscript
# ui/run_review.gd（extends RefCounted，与 ui/event_screen.gd::drawer 同形）
const TITLE_KEY="ui.run_review.title"
const TITLE_FALLBACK="本局回顾"
static func title_text(ui) -> String        # = ui._text(TITLE_KEY,TITLE_FALLBACK)；面板标题与两个入口按钮共用
static func can_open(route: Array) -> bool  # = not route.is_empty()：两处入口的创建守卫（观测按控件是否存在，见「入口可见性」）
static func drawer(ui) -> void              # 建 ui._drawer_shell(...) 面板并追加三块
#   复制按钮 name="RunReviewCopy"：初始文本读 ui._run_review_copy_text()，pressed → ui.copy_seed()，
#   建好后把 ui.run_review_copy 指向它（面板自己唯一的 ui 字段写入）。

# ui/main.gd 侧唯一接线点
const RunReview=preload("res://ui/run_review.gd")
var show_run_review=false                   # 并加入 const DRAWERS
var run_review_copy: Button                 # 回顾面板复制按钮的视图指针（第二个视图，不持有计时）
func _run_review_copy_text() -> String      # 未复制=_text("ui.run_review.copy","复制本局标识")；窗口内=_text("ui.map.seed_copied","已复制")
# _refresh_drawers() 非主页分支：if show_run_review: RunReview.drawer(self)
# _drawer_shell() 的全窗遮罩条件增 show_run_review（面板宽 1480 与 show_deck 相同，取同一种整窗遮罩面）
```

复制显示态的属主仍是 `ui/main.gd::seed_copied_until` 与唯一刷新入口
`ui/main.gd::_refresh_seed_chip()`（由 `_process` 每帧驱动，只在到期那一帧改写文本；函数名不改）：
`copy_seed()` 写剪贴板与截止时间后立即经同一刷新入口改写两处视图（路线屏角标 + 回顾面板按钮），
不另开计时器、不保留回调；面板隐藏或被重建后，旧指针由 `is_instance_valid` 守卫，不写入已释放控件；
面板按钮被重建时按同一文本规则重读截止时间。Esc 与安卓返回键沿既有 `DRAWERS` 清单关闭，不新增关闭通道。

### 三块取源（逐项点名）

| 块 | 取源（唯一） | 口径 |
| --- | --- | --- |
| 本局标识 | `ui.seed_report_text()`（文本）＋ `ui.copy_seed()`（复制按钮 `RunReviewCopy` 的唯一回调） | 标签文本与 `seed_report_text()` **逐字节相等**；不得出现第二份种子文案，也不得自写剪贴板或第二份计时；按钮「已复制」态复用 `ui.map.seed_copied` 与同一 `seed_copied_until` 窗口 |
| 节点概况·进度 | `view.route` | `{floor}` = `status in ["completed","current"]` 的房间的最大 `floor` ＋1（`floor=-1` 的塔底 → 0，与 `core/game_view.gd::run_header` 的「第0层」同口径）；`{nodes}` = `status=="completed"` 的房间数 |
| 节点概况·地图 | `ui/route_map.gd` 的同一渲染器：`rooms=ui.view.route`、`compact=true`、`read_only=true` | 不裁剪 `rooms`、不重算 `status`、不新增第二份绘制 |
| 卡组 | `ui/deck_browser.gd::setup(ui, ui.view.deck_cards, false, ui._text("ui.run_review.deck_empty","卡组为空。"))` | 全量入口：只吃 `view.deck_cards`；默认筛选下条目数＝`view.deck_cards.size()` |

- 不使用 `view.rooms_completed` 作为进度来源：进度行与地图必须来自同一数组，避免同一语义的第二个来源。
- 卡组块的现算文案经 `deck_browser.setup` 内部既有入口 `ui.game.live_card_text_set`
  （`docs/spec/ondemand-copy.md`「三个只读入口」登记的全量入口）；`run_review.gd` 自身不调用
  任何 `ui.game.*`（源文本判据见「证据入口」）。

### 只读保证（实现必须同时满足）

1. 不调用 `ui._submit`、`ui.actions`、`ui.game.dispatch`、`ui._save_progress`；
   不读写 `ui.game.state`。例外：测试与夹具可读写 `ui.game.state`。唯一的写动作是复制按钮 → `ui.copy_seed()`：
   它只写剪贴板与 `seed_copied_until`，不得自写 `DisplayServer.clipboard_set`、不得自建截止时间或回调。
2. 回顾地图实例只读：`room_selected` 不接 `ui._select_route_room`，`drawings_changed` 不接
   `ui._save_progress`（这两条连接只属于 `_route_screen()`）。
3. `route_map.read_only=true`：`_ready()` 不建房间按钮（回顾地图「点节点不出发」的实际保证）；
   `_input()` 的 `read_only` 首行早退保留，但在回顾地图上不是生效路径。
4. 回顾地图实例的 `buttons` 为空，`strokes` 保持空；不写 `ui.map_drawings`、不进 `ui.candidate_buttons`。
5. 除 `_open_drawer`／`_close_drawers` 的抽屉显示态与 `ui.run_review_copy`（面板自己的视图指针）外，
   本面板不改任何 `ui` 字段。

判据：打开、滚动、筛选、点击面板内任意位置（含点复制按钮）后，`view.version`、`ui.view.candidates`、
`ui.game.export_snapshot()`（含 `state.rng` 计数）与存档主档＋`.bak` 的字节与 mtime 全部不变。

### 入口可见性

- 观测判据＝**入口控件是否存在**：`view.route` 为空（`core/game_view.gd::build` 里
  `state.practice` 或 `state.room=="prison"` 的练习局与牢房）时**不创建**入口控件——不是
  `visible=false` 的空壳，`ui.find_children("OpenRunReview","",true,false)` 必须为空。
  实现侧的守卫是两处调用点上的 `RunReview.can_open(view.route)`
  （`ui/main.gd::_route_screen()` 与 `ui/main.gd::_demo_exit_screen()`）；函数名只是定位用的
  符号锚点，判据不按它的返回值判定。**可证伪性限制（如实记录）**：把 `can_open` 改成恒真在现有
  `route` 套件里实测 0 条变红（练习局走练习屏、牢房相位不渲染这两个入口屏）；能证伪空壳入口的是
  「无条件创建入口」变异（实测 5 条红，运行号 `20260919T100708396-34440`）。
- 两个入口，同一个 `name="OpenRunReview"`（两屏在 `render()` 里互斥，任意时刻至多一个）：
  - 路线屏 `ui/main.gd::_route_screen()`：追加在右栏 `navigation`（`MapOverview`／`MapLocate` 之后）；
    既有控件的**文本、行为与相互判据不动**；追加使该格多出一行、既有格随之上移，
    `TravelMessageScroll` 相应变矮——这是追加的必然布局后果，不算改动既有控件。
  - 通关屏 `ui/main.gd::_demo_exit_screen()`：追加在 `DemoExitPanel` 的按钮列
    （`view.demo_exit` 成立时 `view.route` 仍非空）；面板 rect 高度可按内容调整，
    判据是每个可见子控件都在面板矩形内（含 `view.demo_finished` 多出「返回菜单」的两态）。
- 入口点击只做 `ui._open_drawer("show_run_review")`；不触发候选、不出发、不写盘。

### 布局

- 单抽屉：`_drawer_shell(RunReview.title_text(ui),Rect2(60,78,1480,780),GOLD)`
  （与 `_deck_drawer`／`EventScreen.drawer` 同尺寸同遮罩面）。
- 内容列顺序：`本局标识`（小标题＋标识文本）→`节点概况`（小标题＋进度行＋只读地图）→`卡组`（小标题＋列表）。
- 尺寸口径：只读地图 `custom_minimum_size=Vector2(710,420)`；卡组浏览 `custom_minimum_size.y=340`。
  卡组浏览网格固定 6 列、卡片 210 宽，网格最小宽约 1380（工具条另需约 800），因此卡组块必须整宽，
  **不与地图并排**；本片取单列 + 整宽卡组，内容列放进 `ui._scroll()` 返回的滚动列，
  总高超出面板时纵向滚动，控件不得溢出面板矩形。
- 节点名（检查定位用，唯一）：`RunReviewIdentity`／`RunReviewCopy`／`RunReviewProgress`／`RunReviewMap`／`RunReviewDeck`。
- 标识块布局：小标题「本局标识」下先排 `RunReviewIdentity`（四要素文本，Label 可选中），
  其右侧同一行放 `RunReviewCopy`（未复制时文本为「复制本局标识」）。

### 只读地图的实现口径（`ui/route_map.gd`）

- 新增 `var read_only=false`。回顾地图下**实际生效的只有 `_ready()` 一处**：
  - `_ready()`（生效路径）：`read_only` 时不遍历 `rooms` 建 `Button`、不连
    `pressed → room_selected.emit`，也不连 `resized → _layout_nodes`／不调用 `_layout_nodes()`
    （`buttons` 保持空，房间因此没有任何点击命中格；只读分支改连 `resized → queue_redraw`）。
  - `_input()`：`read_only` 首行早退代码存在，但回顾地图**不靠它**——紧随其后的
    `get_parent() as ScrollContainer` 守卫先返回（回顾地图的父节点是滚动列内的 `VBoxContainer`）。
    不得把这个首行早退当成回顾地图只读的生效点或观测点。
- `_draw()`、`point_for()`、`_layout_nodes()`、`ink_position()` 不改：同一渲染器、同一坐标与配色，
  紧凑模式继续只画图标与层号（`compact` 分支）。
- `read_only=false`（路线屏）逐项不变：既有 `ROUTE` 断言（每房间都有按钮、节点点击出发、
  右键绘画、按住左键平移）继续成立。
- 回顾地图的父节点是滚动列内的 `VBoxContainer`，`_background()` 走 `scroll==null` 分支（纸面按控件矩形铺满）；
  不得为此改 `_draw()`。

### 本地化 key 表（zh_CN 与 en_US 各一条，`source` 与 zh_CN 的 `text` 逐字相同）

| key | zh_CN `text` | zh_CN `context` | en_US `text` |
| --- | --- | --- | --- |
| `ui.run_review.title` | 本局回顾 | 回顾面板标题与路线屏／通关屏两个入口按钮；唯一文本入口 `RunReview.title_text` | Run Review |
| `ui.run_review.identity` | 本局标识 | 回顾面板第一块小标题 | Run identity |
| `ui.run_review.route` | 节点概况 | 回顾面板第二块小标题 | Route overview |
| `ui.run_review.deck` | 卡组 | 回顾面板第三块小标题 | Deck |
| `ui.run_review.progress` | 已到达第 {floor} 层 · 已走过 {nodes} 个节点 | 节点概况的进度行；{floor}／{nodes} 由 `view.route` 现算的整数 | Reached floor {floor} · {nodes} nodes travelled |
| `ui.run_review.no_route` | 没有可回顾的路线数据。 | `view.route` 为空而面板已开时的失败态，替代地图位置 | No route data to review. |
| `ui.run_review.deck_empty` | 卡组为空。 | 卡组块空数据文案，交给 `deck_browser.setup` 的 `empty_message` | The deck is empty. |
| `ui.run_review.copy` | 复制本局标识 | 标识块的复制按钮；点击调用 `ui.copy_seed()`，「已复制」分支复用 `ui.map.seed_copied` | Copy run identity |

- 所有玩家可见文本只经 `ui._text(key, 与 zh_CN 逐字相同的 fallback)`；两个入口按钮与面板标题共用
  `RunReview.title_text(ui)`，不复制字面量（复制会触发 `stale_callsite` 诊断）。
- 标识块同时提供复制：按钮 `RunReviewCopy` 是同一复制入口 `ui/main.gd::copy_seed()` 的**第二个视图**，
  「已复制」显示态仍由 `seed_copied_until` 与唯一刷新入口 `_refresh_seed_chip()` 驱动，
  文本复用既有 key `ui.map.seed_copied`，**不新增同义 key、不自写剪贴板、不自持计时**；
  标识文本 `ui.seed_report_text()` 是四要素引用文本，本身不随语言切换，面板内不另造翻译副本。

### 失败语义

- `view.route` 为空而面板已开（相位被替换的极端情形）：地图块位置显示 `ui.run_review.no_route` 文本，
  不空白、不报错、不显示空地图；卡组块照常显示（练习局也有卡组）。
- `view.deck_cards` 为空：交给 `deck_browser` 的既有空数据文案 `ui.run_review.deck_empty`。
- 进度行：`completed∪current` 为空时按 `{floor}=0,{nodes}=0` 显示（防御；`route_view` 正常产出下
  当前房间必在该集合内）。计数不得在面板里另开第二套推导。
- 面板内不出现规则失败提示：它不提交任何东西；也不为缺席数据留空白格且无记录。

## 证据入口

- 窗口 `route` 分类 → `tests/route_ui_cases.gd` 的 `run_review(t)`（在既有 `run(t)` 恢复存档隔离之前调用；
  复用既有真实指针助手与真实夹具）。具名 check（原文见该文件）：
  `ROUTE run review is not part of rules, facts or randomness`／`ROUTE run review node click never departs`／
  `ROUTE run review map matches the projected route`／`ROUTE run review progress counts the walked nodes`／
  `ROUTE run review deck lists every physical card`／`ROUTE run review identity reuses the run report text`／
  `ROUTE run review entries follow the route data`／`ROUTE run review behaves like the shared drawer`／
  `ROUTE run review copy exists in both languages and records no miss`／`ROUTE run review copy shares the chip display state`。
- 源文本判据（只读保证 1）：`tests/architecture_cases.gd::run_review_is_read_only_source`
  （`ui/run_review.gd` 不引用 `ui.game.*`、`DisplayServer.clipboard_set`、`_save_progress`、`.dispatch(`、
  `seed_copied_until=`，且唯一写动作是 `ui.copy_seed`）。
- 命令：

```powershell
# 规则侧：本片改了本地化资源；architecture 作为 ui 新增文件的静态旁证（core 零改动）
& tools/check.ps1 -Suite localization,architecture -KeepGoing -TimeoutSeconds 900
# 窗口侧：route 为本片新 check 的落点，localization 复查诊断与英文残留
& tools/check.ps1 -UIOnly -UISuite route,localization -TimeoutSeconds 900
```

- 判据：退出码 0；每个分类 `SUITE RESULT: <name> PASS`；`summary.json` 的 `status=passed` 且
  `before==after`（同一源码指纹，无 `SOURCE CHANGED`）；`unrun=[]`。
  每条判据的敏感性证明（关掉或改错它会让哪条断言变红）见 `tests/route_ui_cases.gd` 的断言语义与
  `docs/record/verification.md` 的本片条目；不会变红的机制声明不得写成「由断言保证」。
