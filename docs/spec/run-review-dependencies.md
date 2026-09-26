# 本局回顾面板：依赖约束（cleaner 可核对）

本文件是「本局回顾」（`docs/spec/run-review.md`）一片的依赖约束：允许改动的文件、允许的依赖方向与禁止项。
本片在分支 `seed-chip-save-upload` 上与种子角标／反馈存档两片**同批提 PR**，但切口独立：
`docs/spec/seed-feedback-dependencies.md` 仍约束那两片；两文件对同一文件（`ui/main.gd`、两份本地化、
`tests/route_ui_cases.gd`）的约束是**并集**，冲突处按更严格的一条执行。
本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 允许改动

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `ui/run_review.gd`（新建） | 新建 `extends RefCounted` 的静态组装入口：`TITLE_KEY`／`TITLE_FALLBACK`／`title_text(ui)`／`can_open(route)`／`drawer(ui)` 与三块内容（标识／节点概况／卡组）；标识块复制按钮 `RunReviewCopy`（初始文本读 `ui._run_review_copy_text()`，`pressed → ui.copy_seed()`） | 只读 `ui.view`、`ui._text`、`ui._label`、`ui._scroll`、`ui._drawer_shell`；自身不调用任何 `ui.game.*`；不派发候选、不进 `_submit`、不写盘；不新增计时器／回调，不写剪贴板 |
| `ui/route_map.gd` | 新增 `var read_only=false`；`_ready()` 在该标志下不建房间按钮、不连 `room_selected`／`_layout_nodes`（回顾地图只读的**实际生效守卫**）；`_input()` 在该标志下首行早退（保留，但不是回顾地图的生效路径：回顾地图的父节点是滚动列内的 `VBoxContainer`，其后的父滚动守卫先返回） | `read_only=false` 的既有行为逐项不变（`buttons`、`room_selected`、右键绘画、按住左键平移）；`_draw()`／`point_for()`／`_layout_nodes()`／`ink_position()` 的渲染与坐标语义不变 |
| `ui/main.gd` | `DRAWERS` 增 `show_run_review`；`var show_run_review=false`；`var run_review_copy: Button`；`const RunReview=preload("res://ui/run_review.gd")`；`func _run_review_copy_text()`；`_refresh_drawers()` 非主页分支增一行分派；`_drawer_shell()` 的整窗遮罩条件增 `show_run_review`；`_route_screen()` 的 `navigation` 增 `OpenRunReview`；`_demo_exit_screen()` 增 `OpenRunReview`（其面板 rect 高度可按内容调整）；`copy_seed()` 与 `_refresh_seed_chip()` 改为经同一刷新入口同时改写角标与面板按钮两处文本（守卫沿用 `is_instance_valid`） | `SeedChip` 的可见性判据、文本、位置与 1.2 s 窗口不变；`seed_report_text()`／`copy_seed()` 的签名、剪贴板内容与四要素结构不变；`MapOverview`／`MapLocate`／`MapClearDrawing`／`TowerRoute`／`TowerMapScroll` 的**文本、行为与相互判据不动**（本片只**追加**一个按钮；追加使 `navigation` 整格上移一行、`TravelMessageScroll` 变矮，属追加的必然布局后果）；`_select_route_room`、`_open_drawer`／`_close_drawers`、Esc 与安卓返回键清单语义不变 |
| `assets/localization/zh_CN.json` | 新增「本地化 key 表」的 8 条（`text`＋`context`） | 既有条目不改不删；`schema_version`／`locale` 不变 |
| `assets/localization/en_US.json` | 新增同 8 条（`source` 与 zh_CN 的 `text` 逐字相同，`text` 非空） | 既有条目的 `source`／`text` 不改；`coverage("en_US").missing==0` 继续成立 |
| `tests/route_ui_cases.gd` | 新增 `run_review(t)` 与场景 A–J 的具名 check（在既有 `run(t)` 恢复 `ui.saves`／`persistence_enabled` 之前调用） | 既有断言与既有 `merged_departure`／`seed_chip` 不删不改；不新增镜像测试；分类注册（`tests/ui_smoke.gd` 的 `UI_MODULES`）不动 |
| `tests/route_driver.gd` | 默认零改动；若确需夹具 helper，只能是通用夹具（不得绕过正式命令的移动／提交通道） | 既有 helper 的签名与语义不变 |
| `docs/spec/run-review.md`、`docs/spec/run-review-dependencies.md`、根 `AGENTS.md` 文档入口表 | 本片契约落盘与登记两行 | 其它表的行不改；不保留被取代的旧口径 |
| `docs/record/changelog.md`、`docs/record/verification.md` | 实现完成后各追加一条／一节（日期＋域＋命令＋结果＋未跑项） | 只追加，不改历史条目 |

## 允许的依赖方向

- 新增边只在 `ui/` 内部：`ui/main.gd → ui/run_review.gd → ui/{route_map,deck_browser}.gd`；
  与既有 `ui/main.gd → ui/{route_map,shop_screen,event_screen}` 同向，不新增跨层边。
- `ui/run_review.gd` 不 preload `core/*`、`data/*`；卡面现算只经 `deck_browser.setup` 内部既有的
  `ui.game.live_card_text_set`（`ui → core` 既有只读边，不新增）。
- `core` 不 preload `ui`（`ARCH core event module never names ui/` 继续成立）。
- 不新增模块、不新增运行时依赖、不新增随机域、不新增存档域、不新增 View 键、不新增候选。

## 禁止项

- 在 `ui/run_review.gd` 写第二份地图渲染（画线、摆节点、算坐标）；给 `route_map.gd` 加第二个绘制分支。
- 在 `ui/run_review.gd` 手写种子文案（「初始种子」等字面量）；标识只读 `ui.seed_report_text()`。
- 写第二套卡组列表（自建网格／条目）；卡组只经 `deck_browser.setup(ui, ui.view.deck_cards, false, …)`。
- 在回顾面板里调用 `ui._submit`／`ui.actions`／`ui.game.dispatch`／`ui._save_progress`；
  把回顾地图的 `drawings_changed` 接 `_save_progress`；把 `room_selected` 接 `_select_route_room`。
- 自写第二份复制实现：面板按钮直接 `DisplayServer.clipboard_set(...)`、自建 `seed_copied_until` 之外的
  计时或回调、新增「已复制」同义 key（唯一 key 是 `ui.map.seed_copied`，唯一计时与刷新入口是
  `seed_copied_until`＋`_refresh_seed_chip()`，唯一复制实现是 `copy_seed()`）。
- 新增 View 键、候选、`state` 字段；升 `Snapshot.REVISION`；改 `core/snapshot.gd`／`core/game.gd`／
  `core/game_view.gd`／`core/save_store.gd`。
- 改动 `ui/feedback_report.gd` 与反馈附件域、`ui/route_map.gd` 的 `STATUS` 文案表、
  `data/balance.gd::RNG_SALTS`、协调者的本地发布脚本（未入库，本表不点名其路径）。
- 用「先打开面板再让 `visible=false`」冒充入口不可见；在面板里留空白格表示无数据。
- 推送、打标签、改版本号、改 `project.godot` 或导出预设。

## 与 `seed-feedback-dependencies.md` 的交叉说明

- 那一片的 `ui/main.gd` 行「既有地图控件与布局不动」指 `SeedChip` 与路线屏既有三件控件本身不受影响；
  本片在 `navigation` 里**追加**一个新按钮，不改动它们的文本、行为与相互判据；
  追加使整格上移一行、`TravelMessageScroll` 变矮，是追加的必然布局后果，两约束不冲突。
- 本片对种子域的改动是**结构性**的、可观察语义不变：`copy_seed()` 不再内联只改角标文本，而是与
  `_refresh_seed_chip()` 共用同一刷新入口同时改写角标与面板按钮两处视图。剪贴板内容、
  1.2 s 窗口、`seed_copied_until` 的属主地位、「已复制」文案 key（`ui.map.seed_copied`）
  与角标可见性判据全部不变；`seed_report_text()` 与其四要素结构不变。
- 两份本地化新增条目不重叠（`ui.map.seed*`／`ui.feedback.save.*` 与 `ui.run_review.*`，
  本片新增 8 条）；同一 PR 内先后运行门禁时，`coverage("en_US").missing==0` 是两条片共同维持的判据。
- `tests/route_ui_cases.gd` 同时被两片追加：两片各自新增独立的 `static func`（`seed_chip`／`run_review`），
  互不修改对方的函数与断言。

## 自检清单（实现者交付前逐条对照）

- `ui/run_review.gd` 里没有 `DisplayServer`／`clipboard`／`_submit`／`_save_progress`／`ui.game` 字样。
- 回顾地图的 `read_only` 为真、`buttons` 为空、`room_selected`／`drawings_changed` 都没有连接。
- 面板复制按钮的回调就是 `ui.copy_seed`，没有第二处 `_text("ui.run_review.copy", …)` 之外的文案拼装。
- 两处视图的文本只在「建控件时读 `_run_review_copy_text()`／`_seed_chip_text()`」与
  「`copy_seed()`／`_refresh_seed_chip()` 到期那一帧」被改写。
- 新增 8 条 locale key 在 zh_CN 与 en_US 各一条，`source` 与 zh 逐字相同。
