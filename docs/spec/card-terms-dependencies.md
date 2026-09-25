# 卡面词条悬停显示：依赖约束（cleaner 可核对）

本文件是「卡面词条悬停显示」（`docs/spec/card-terms.md`）一片的依赖约束：允许改动的文件、允许的依赖方向与禁止项。
本片在分支 `seed-chip-save-upload` 上独立成片，与种子角标／反馈存档／本局回顾三片**无文件交叉**：
同名的 `ui/main.gd` 行只覆盖悬停与词条弹窗，回顾片对 `ui/main.gd` 的允许改动（`_refresh_drawers`、`_drawer_shell`、
`navigation`、`copy_seed` 等）与本片不重叠，无需并集处理。
本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

## 允许改动

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `ui/main.gd::_card_tooltip` | 词条不再拼进 `detail` 行；改按顺序传 `entry.terms`；无词条且无其它行时仍走 `_hide_term()` | 其它行（溢出正文、`施法成功率 · …`、`card.note`）的文本、顺序与触发条件不变；只读 `button`／`card`，不调用任何 `ui.game.*` 或 `ui.actions` |
| `ui/main.gd::_show_term` | 按可选键 `entry.terms` 逐条生成词条框（每框名称＋定义两个标签，沿用 CYAN 19px／TEXT 15px——**字号与配色是机制声明，无断言覆盖**，见 `docs/spec/card-terms.md`「接口」），整组仍挂在 `term_popup`（节点名 `TermExplanation`）子树内；`terms` 空或缺省时保持今日单面板 | `term_popup`／`term_anchor` 仍是唯一属主变量，`_hide_term()` 是唯一关闭入口；`_ignore_mouse(term_popup)` 保持（**防御性保留：删除后点击断言仍绿，无断言覆盖**，见同契约「接口」的已知不可观测项）；`touch_input.finger>=0 and not details_allowed` 的早退守卫不变；`_drag_rejection` 的 `drag_reason` 元数据语义不变 |
| `ui/main.gd::_position_term` | 默认零改动（若多框需要整组测量，只允许改测量对象） | 右侧 `anchor.end.x+12`／越界改左／x∈[20,1580−宽]、y∈[74,886−高] 的 clamp 与「不与锚面重叠」不变；`_position_term` 仍是唯一定位入口 |
| `ui/main.gd::_card`／`ui/main.gd::_display_card` | 默认零改动（悬停信号连接与 `source` 合并已满足本片） | `mouse_entered`／`mouse_exited`／`focus_entered`／`focus_exited` 的连接对象与 `_refresh_card_face` 的悬停重入不变 |
| `ui/card_face.gd` | 默认零改动 | `ui/card_face.gd::separate_keywords` 与卡面徽章渲染（`CardKeywords`）不变；本片不读卡面文本反推词条 |
| `ui/touch_input.gd::show_details` | 默认零改动（已对卡面 `mouse_entered.emit()` 触发同一入口） | `held`／`details_allowed`／`finger` 语义与 `tooltip_text` 兜底路径不变；不新增第二条长按弹窗路径 |
| `tests/interface_ui_cases.gd` | 新增具名 check（建议 `static func card_terms(t)`），复用该文件既有的卡组浏览／导航路径 | 既有断言与助手签名不改；不新增分类文件、不改 `tests/ui_smoke.gd::UI_MODULES` |
| `tests/encyclopedia_ui_cases.gd` | 在图鉴用例里新增悬停／翻面词条框断言 | 既有 `BOOK` 断言不删不改；`tests/encyclopedia_ui_cases.gd` 的 `t.check(tip==null or …)` 语义不放宽成「不检查」 |
| `tests/card_power_ui_cases.gd` | 仅允许改写 `SEARCH UI hover is one short explanation…`（`检索：从抽牌堆抽取指定类型的牌。` 这一连续子串断言）：名称与定义分成两个标签后，改为分别断言词条名与定义两段（仍限该面唯一框、仍带长度上界） | 该场景不得删除或放宽成「弹窗非空」；`POT UI hovering explains exhaust…` 与 `DUAL UI`／`MAGIC SLIP`／`ROUTE UI` 的悬停断言不改 |
| `tests/event_ui_cases.gd`、`tests/reward_ui_cases.gd` | 各新增一条悬停词条框断言（事件卡选项、奖励选牌的真实入口） | 既有断言不删不改；不新增镜像测试 |
| `tests/touch_ui_cases.gd` | 新增长按等价断言（复用既有触摸模拟助手） | 既有长按／拖动断言不改 |
| `docs/spec/card-terms.md`、`docs/spec/card-terms-dependencies.md` | 本片契约落盘 | 被取代的口径删改，不加「更正」段 |
| 根 `AGENTS.md` 文档入口表 | 增加一行指向 `docs/spec/card-terms.md` | 其它行不改 |
| `docs/record/changelog.md`、`docs/record/verification.md` | 实现完成后各追加一条／一节（日期＋域＋命令＋结果＋未跑项） | 只追加，不改历史条目 |

商店买卡与去卡的悬停（`ui/shop_screen.gd::_card_offer`／`ui/shop_screen.gd::services`）没有点名该文件的既有用例，
本片不为它新建分类或新用例文件：由验收程序在真实窗口逐点操作覆盖（见 `docs/spec/card-terms.md`「验收程序」）。

## 允许的依赖方向

- 不新增任何依赖边：`ui/main.gd` 继续只读它收到的 `card` 字典（`face_keywords` 由 `data/*` 既有管线写入），
  不新增 `ui → core`／`ui → data` 的 preload，不新增跨层边。
- `core` 不 preload `ui`（`ARCH core event module never names ui/` 继续成立）。
- 不新增模块、不新增运行时依赖、不新增随机域、不新增存档域、不新增 View 键、不新增候选、不新增本地化 key。

## 禁止项

- 在 `ui/` 里重算词条集合（再写一份 `keywords()` 判定）、按名称字符串反查 `TERMS`、或复制第二份词条文案。
- 新增第二个弹窗属主变量／第二条关闭路径（自建 `_hide_terms()`、直接 `queue_free` 而不经 `_hide_term`）。
- 把词条框做成覆盖锚点卡面的浮层，或让框拦截鼠标（去掉 `_ignore_mouse`、把 `mouse_filter` 改成 `STOP`）：
  前者有几何断言（`docs/spec/card-terms.md` 判据 6），后者**无机械判据**——删除 `_ignore_mouse` 不会让任何断言变红，
  只靠 cleaner／审查者核对差异面。
- 把无词条的面渲染成空框、空白面板，或以「面板先显示再 `visible=false`」冒充无词条。
- 改 `data/card_text.gd::TERMS` 的文案与集合、改卡面徽章渲染、动 `_position_term` 的边界常量。
- 在 `ui/main.gd::_card_tooltip` 里提交候选、写 `view.version`、调用 `ui.game.dispatch`／`ui._submit`／`_save_progress`。
- 新增分类文件或改 `tests/ui_smoke.gd::UI_MODULES`／`tests/suite_selection.gd::CROSS_AREAS`。
- 推送、打标签、改版本号、改 `project.godot` 或导出预设。

## 自检清单（实现者交付前逐条对照）

- `ui/main.gd::_card_tooltip` 里不再有 `term.name+"："` 拼接；词条只经 `entry.terms` 传递。
- 没有 `terms` 的 `_show_term` 调用（意图图标、拖拽拒绝、`tooltip_text` 长按）输出与改动前逐字相同。
- 弹窗里每个词条恰好一个名称标签与一个定义标签，数量等于 `card.face_keywords[side].size()`。
- `find_child("TermExplanation")` 仍能找到弹窗根，`visible_text(ui.term_popup)` 仍包含词条名与定义。
- 悬停前后 `ui.game.export_snapshot()` 相等，`ui.view.version` 不变。
- 未改任何本地化文件（本片无新增可见文案）；若实现里出现新的中文字面量，先停下回报。
