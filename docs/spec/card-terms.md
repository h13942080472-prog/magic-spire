# 卡面词条悬停显示：契约（planner）

域：战斗外卡面（`ui/main.gd::_display_card`／`ui/main.gd::_card` 建出的卡）悬停或聚焦时，
把该卡**当前面**的规则词条逐条显示为独立方框（一条词条一个框：名称＋一句定义）。
本片只改**接线与呈现**：不新增词条、不改词条文案、不改任何规则判定。

## 取源（唯一）

- 词条真源唯一：`data/card_text.gd::TERMS`。每面集合由 `data/card_text.gd::keywords(type, free, traits)` 计算，
  经 `data/card_text.gd::metadata()` 写入 `face_keywords[side]`；公开入口 `data/balance.gd::card_metadata(type)`。
  `data/encyclopedia.gd::card(type)` 已合并元数据，**图鉴卡（无实例）同样带 `face_keywords`**。
  实例卡的成长/来源文案由 `ui/main.gd::_display_card` 的 `source` 参数合并，不改这一来源结构。
- 显示侧只读 `card.face_keywords[side]`（`card` 即 `ui/main.gd::_card_tooltip` 收到的字典）。
  禁止 UI 重算词条集合、禁止按名称字符串反查、禁止第二份词条文案表。
- `side` 只由 `button.free_face` 决定（`"free" if button.free_face else "bound"`）：翻转后悬停取换面集合，不串面。

## 触发面（逐个点名）

战斗外卡面共享一个决策点 `ui/main.gd::_card_tooltip(button, card)`（由 `ui/main.gd::_card` 连接
`mouse_entered`／`mouse_exited`／`focus_entered`／`focus_exited`）与一个呈现入口 `ui/main.gd::_show_term(anchor, entry)`：

| 面 | 建造点（`_display_card`／`_card` 的调用者） |
| --- | --- |
| 图鉴 | `ui/encyclopedia.gd::show_entry` → `ui/encyclopedia.gd::_card_family` |
| 卡组浏览 | `ui/deck_browser.gd::refresh` |
| 商店买卡 | `ui/shop_screen.gd::_card_offer` |
| 商店去卡 | `ui/shop_screen.gd::services` |
| 事件卡选项 | `ui/event_screen.gd::action` |
| 奖励选牌 | `ui/reward_screen.gd::cards` |
| 保留选牌 | `ui/main.gd::_action_row`（`c.payload.kind=="retain"` 分支） |
| 回顾面板卡组 | `ui/deck_browser.gd::setup` → `ui/deck_browser.gd::refresh` |

战斗内手牌走同一 `ui/main.gd::_card_tooltip`；本片**不新增战斗判定分支**：改动按共用入口一并生效（见未决问题）。

## 接口

- `ui/main.gd::_card_tooltip(button, card)`：不再把 `card.face_keywords[side]` 拼进 `detail` 文本行；
  改按原顺序把该集合作为 `entry.terms` 传给呈现入口。其余行（溢出正文、`施法成功率 · …`、`card.note`）与
  今日一致，仍走 `entry.label`／`entry.detail`。
- `ui/main.gd::_show_term(anchor, entry)`：`entry` 允许可选键 `terms: Array`，元素是 `face_keywords[side]` 的
  原始字典，不复制、不重排、不改写。`terms` 为空或缺省时**逐字保持今日的单面板行为**（其它调用者
  `ui/touch_input.gd::show_details`、`ui/main.gd::_drag_rejection` 因此不受影响）。
- `terms` 非空时：每条词条一个方框，每框一个名称标签＋一个定义标签（框内两段文本与框数有断言，见判据 1／3／5），
  整组框同处一个容器，仍挂在 `ui/main.gd::term_popup`（节点名 `TermExplanation`）子树内。
  框内样式沿用既有 `entry.label`（名称，CYAN 19px）与 `entry.detail`（定义，TEXT 15px）两个标签的字体与配色；
  **样式是机制声明（已知不可观测项）**：断言只比较框内文本与框数（`tests/interface_ui_cases.gd::term_boxes`），
  字号与配色无断言覆盖，改字号或配色不会让任何断言变红。
- 唯一属主与唯一关闭入口不变：`ui/main.gd::term_popup`／`ui/main.gd::term_anchor`／`ui/main.gd::_hide_term`。
  不得新增第二个弹窗属主变量或第二条关闭路径；`drag_reason` 元数据的语义（`ui/main.gd::_drag_rejection` 设置、
  拖拽路径据此关闭）不变。
- 定位仍只经 `ui/main.gd::_position_term(anchor_rect)`：整组框默认在锚点右侧（`anchor.end.x+12`），
  越界时改左侧，并 clamp 在 x∈[20,1580−宽]、y∈[74,886−高]。即**不与锚点卡面矩形重叠、不出屏**。
  具体偏移量与 clamp 常量是机制描述（改动它们不必然变红）：断言判定的只是「与锚面矩形不相交且整组在视口内」，
  敏感性见判据 6。
- `ui/main.gd::_ignore_mouse(term_popup)` 保持：整组框及其子节点的 `mouse_filter` 全为 IGNORE，按防御保留。
  **点击不被拦截是机制声明，不是该调用的判据（已知不可观测项）**：实测删掉 `_ignore_mouse(term_popup)`
  （含叠加「压住锚面」）后，判据 6 的真实点击断言仍绿。可观测的机制只有一条——框与锚面矩形不重叠
  （判据 6 的几何条）；另两条机制在卡面路径上没有断言：指针离开即经 `ui/main.gd::_hide_term` 销毁弹窗
  （该「离开即关闭」行为只在意图图标路径有断言 `INTENT UI leaving term closes explanation`），以及
  卡面所在 `drawer_layer` 在 `layout` 内位于 `term_popup` 之后、输入拾取仍在弹窗之上。因此 `_ignore_mouse`
  的必要性无法由断言观测，保留它属于防御，不得写成「由断言保证」。点击是否落到卡面的行为断言见判据 6。
- `ui/main.gd::_refresh_card_face` 末尾的悬停重入（`term_anchor==button or has_focus or 鼠标在卡上 → _card_tooltip`）不变：
  刷新时框集合随当前面重建，不残留旧面词条。

## 失败语义

- 该面无词条且无其它行 → 走 `ui/main.gd::_hide_term()`：不弹空框、不留无内容的静默。
  **这是机制声明，无断言覆盖（已知不可观测项）**：既有悬停断言都落在非空词条面上，零词条面「不弹框」
  没有正例断言，不得写成「由断言保证」。
- 词条框数等于 `card.face_keywords[side].size()`（正例面的框数断言见判据 1／3／5）；词条为 0 时不补空框，
  该零词条分支与上一条同属无断言覆盖的机制声明。
- 词条集合与顺序只来自取源；断言按 `data/card_text.gd::TERMS` 的字面比较，不按名称前缀或近似匹配。

## Gherkin（判据）

前缀 `TERMS UI`，直接写进已注册分类的既有用例文件；`{"name","detail"}` 逐项含顺序比较。

1. Given 图鉴打开任一张卡，When `mouse_entered` 该卡面，Then 弹窗子树的词条框集合与该面 `face_keywords[side]`
   逐项相同（含顺序）。
   敏感性：改本条钉住的词条（`data/card_text.gd::TERMS` 的 `search`／`levels`／`strain`／`slip`）`detail` 一字
   → 断言红（实测）；改 `data/card_text.gd::keywords()` 让被钉的面多一条或少一条词条、或改这些词条的 `name`
   → 断言红（钉值是字面值，与实现数量或文本不等即红；改文案一字已实测，数量变化未逐条实测）。
   钉值只覆盖 `tests/interface_ui_cases.gd::TERM_PINS` 里的 `mana_search`／`witch_escape_practice` 两面，
   其余卡面与词条的改动不在本条断言的可观测域内。
2. Given 同一张卡，When 翻面后再悬停，Then 词条集合等于 `face_keywords["free" if free_face else "bound"]`，与另一面不同。
   敏感性：把 `side` 取值固定成 `"bound"` → 断言红。
3. Given 卡组浏览里的实例卡（带成长/来源文案）与图鉴卡（无实例），When 各自悬停，Then 两者都按各自 1 的规则成立。
   敏感性：去掉 `ui/main.gd::_display_card` 对 `source` 的合并 → 实例卡断言红（成长文案丢失）。
4. Given 战斗外任一屏，When 悬停并关闭弹窗，Then `ui.game.export_snapshot()` 前后相等、`ui.view.version` 不变。
   敏感性：在 `ui/main.gd::_card_tooltip` 里直接写状态（如 `ui.game.state.tick+=1`）→ 断言红（实测）。
   经 `ui.actions`／`ui.game.dispatch` 的注入不构成这条断言的敏感性证据：实测该点的候选被陈旧版本拒绝
   （`ui.game.dispatch(...).ok=false`，`state` 未变），断言仍绿。
5. Given 触摸路径，When 长按同一卡面（`ui/touch_input.gd::show_details` 的既有路径），Then 与 1 相同的词条框成立。
   敏感性：让 `show_details` 不对卡面 `mouse_entered.emit()` → 断言红。
6. Given 任一卡面悬停中，When 测量几何，Then 整组框矩形与锚点卡面矩形不相交，且整组框在 1600×900 视口内。
   敏感性：把 `ui/main.gd::_position_term` 的右侧偏移改成 `-12`（压住锚面）→ 几何断言红（实测）。
   同场景的行为面另有断言：用真实点击助手点该卡仍打开它自己的界面（`tests/encyclopedia_ui_cases.gd` 的
   `TERMS UI real click on the hovered card still opens its own surface`）。该点击断言**不是**
   `ui/main.gd::_ignore_mouse` 的判据：删掉该调用（含叠加「压住锚面」）后它仍绿（实测）。
   点击不被拦截由哪些机制保证、`_ignore_mouse` 为何按防御保留，见「接口」的已知不可观测项条目。
7. 回归保持：`ui/main.gd::_show_term` 无 `terms` 的调用（意图图标、拖拽拒绝、`tooltip_text` 长按）输出与今日相同。
   敏感性：把单面板改成必须多框渲染 → `tests/intent_ui_cases.gd` 的短提示尺寸断言红。

## 验收程序（validator，真实窗口）

先判定本片性质：**第一步**在真实窗口悬停战斗外各卡面，记录实际弹出内容（截图＋`build/` 日志，不入库），
据此记录本片是「接线缺失」还是「呈现不合 StS 式」。

1. `& tools/launch.ps1` 启动；图鉴 → 逐张悬停 → 截图；右键翻面 → 再悬停 → 截图。
2. 路线屏卡组浏览、回顾面板卡组：悬停一张有成长文案的实例卡。
3. 商店买卡与去卡、事件卡选项、奖励选牌、保留选牌：各悬停一次。
4. 触摸或模拟长按同一卡面；确认与悬停等价。
5. 点击被悬停的卡（选择/购买/翻开）确认未被弹窗拦截；确认弹窗不压住卡面。
6. 结果（命令、结果、未跑项）追加到 `docs/record/verification.md`。

## 定义完成

`& tools/check.ps1 -UIOnly -UISuite interface,encyclopedia,card_power,events,rewards,touch,status,casting`
出现各分类 `UI RESULT: … PASS`；`docs/spec/card-terms.md` 与依赖表的路径／锚点被 `tools/check-docs.ps1` 接受；
验收程序 1–5 **逐步**登记到 `docs/record/verification.md`——每步写实际结果，未做的步骤写「未跑」及原因；
缺步不登记、或把未跑写成通过，即未完成。上面 `-UIOnly` 分类里的既有用例不含商店买卡／去卡、事件卡选项、
奖励选牌、保留选牌的悬停断言（`events`／`rewards` 只跑既有非悬停断言），也不含 3／5 两步在界面上的逐点操作，
故分类 PASS 不能代替这两步的登记。未跑分类、`SOURCE CHANGED:` 轮次不算通过。

## 非目标

- 不动卡面徽章渲染（`ui/card_face.gd::separate_keywords`、`CardKeywords` 容器）与卡面正文。
- 不改 `data/card_text.gd::TERMS` 文案、不改 `keywords()`／`metadata()` 的集合与顺序。
- 不做词条点击展开、跳转图鉴、悬浮高亮联动等新交互；不新增本地化 key（词条名与定义仍是既有中文真源）。
- 不改 `_position_term` 的边界常量与拖拽、候选、存档、随机域。

## 分批

单片独立完工：接线（`_card_tooltip` 传 `terms`）＋呈现（`_show_term` 按 `terms` 分框）＋测试与记录。
无新文件、无新依赖、无存档或协议变化；不需要再切子片。
