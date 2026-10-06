# 手牌卡增量刷新：依赖约束（cleaner 可核对）

本文件是「手牌卡增量刷新」一片的依赖约束：允许改动的文件、允许的依赖方向与禁止项。
当前实现与失效条件见 `docs/spec/response-pipeline.md`；本文件登记手牌刷新依赖、重建边界及验证范围。
本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`data/`、`ui/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

本片新增的私有例程与卡面 setter（**落地后的现状清单**；下表按 `文件::符号` 锚点形式点名，本段只是同一份清单的短名索引，
两处不一致时以表内为准——表内受文档门禁校验）：`ui/main.gd` 的 `_hand_card_key`／`_hand_card_data`／`_hand_face_slice`／
`_hand_apply_card`／`_hand_mount_card`／`_hand_release_card`／`_hand_place_row`／`_hand_row_plan`／`_hand_reset_row`／
`_hand_node_counts` 与成员 `_hand_cards`／`_hand_layout`（幂等守卫是保留名 `ui/main.gd::_hand_key_hit`）；`ui/card_face.gd` 的
`set_title`／`set_cost`／`set_classification`／`set_effect`／`set_warning`／`set_availability`／
`set_keywords`／`set_requirements`／`set_art`、改写 `set_mana`，以及为"唯一写入路径＋节点复用"所必需的私有助手
`_shown`／`_new_label`／`_take`／`_park`／`_exit_tree`／`_request_fit`／`_content_slot`／
`_write_tags`／`_mana_slot`／`_write_mana`／`_apply_art_texture` 与成员 `text_overflow`／`_fit_pending`／`_spare`／
`CONTENT_SLOTS`（自 `set_title` 起的名称都在 `ui/card_face.gd`）。

## 允许改动

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `ui/main.gd::_hand` | 改为**固定顺序**：拦截（`_hand_presentation_key` ＋ `_hand_key_hit`／`_hand_row_plan` 纯数据 diff）→ 逐卡（`_hand_apply_card`）→ 成员增删（`_hand_release_card` 先、`_hand_mount_card` 后）→ 重排（`_hand_place_row`，几何/顺序未变不调用）；行态（`cards`／`empty`／`climax`）经 `_hand_reset_row` | `card_buttons` 与 `view.hand` 一一对应；`_hand_key` 是唯一保存点；命中路径零 `_hand_card_data` 调用；不 `dispatch`／不 `get_view`／不读不写 `game.state`；行几何公式与常量（`CardFace.dimensions(252)`、`746.0`、`850.0`、`630`、`0.018`）不变 |
| `ui/main.gd::_hand_presentation_key` | 名字与「节键真源」地位保留；体改为行键：`[locale, row_state, order(uid 数组), pending(uid 数组), {uid: 每卡窄键}]`，不再逐卡 `duplicate(true)` | 覆盖该节渲染实际读取的全部 View 字段与本地显示态（含 `selected_card`／选择态／`card_faces`／pending）；`version` 不进键；每卡窄键只含该卡自身透传字段，不含 `view.card_costs` 与任何 View 级切片 |
| `ui/main.gd::_hand_key_hit` | 保留为幂等守卫：键相等 ＋ 成员集／每 uid 单节点（经 `ui/main.gd::_hand_node_counts` 一次扫描）／行态节点数一致 | 不得变成"什么变了"的判据；失灵只报该 uid 需删＋增（或行态切换），**不得整行重建** |
| `ui/main.gd`（本片唯一新增面） | `ui/main.gd::_hand_card_key`／`ui/main.gd::_hand_card_data`／`ui/main.gd::_hand_face_slice`（每面值切片的唯一构造点）／`ui/main.gd::_hand_apply_card`（第 4 个可选参数 `prepared`＝预构造切片）／`ui/main.gd::_hand_mount_card`（`row` 缺失即早退；构造一次切片并交给 `_hand_apply_card`）／`ui/main.gd::_hand_release_card`／`ui/main.gd::_hand_place_row`／`ui/main.gd::_hand_row_plan`（`added` 只收 `view.hand` 成员；`broken` 非成员只进 `removed`）／`ui/main.gd::_hand_reset_row`／`ui/main.gd::_hand_node_counts`（一次整树扫描按名字分组，替代逐 uid 扫描）；`ui/main.gd::_hand_cards`（每卡缓存：`button_id`＋每卡窄键＋数据＋两面切片＋已应用面）、`ui/main.gd::_hand_layout`（行几何键） | 输入只有 `view.hand` 行／`card_entry` 结果／纯数据／uid；不读节点文本、不读 `game.state`；每语义一个入口（建卡只经 `_hand_mount_card`、节点销毁只经 `_hand_release_card`、位置只经 `_hand_place_row`、面值只经 `ui/main.gd::_refresh_card_face` 的组合 setter）；不新增公开接口 |
| `ui/main.gd::_card` | 加一个可选参数（预合并数据，手牌路径传入 `_hand_card_data` 结果）以复用唯一数据构造；「有无预合并数据」以 `merged.is_empty()` 为信号（只允许加一个可选参数时的唯一可用信号，手牌调用方显式传参，不靠默认值或形状推断）；`ui/main.gd::_card` 的 `mouse_entered`／`focus_entered` 两条闭包按 uid 读当前数据（手牌卡经 `ui/main.gd::_hand_cards[uid].data`，与翻面闭包同一入口），不再用构建期快照；手牌路径（`merged` 非空）不在 `_card` 内重复应用面值，由 `ui/main.gd::_hand_mount_card` 经唯一入口应用一次 | `hand_interaction`／`lift`／`live_state` 语义不变；非手牌调用方（`ui/main.gd::_display_card`、`ui/card_motion.gd` 经 `_display_card`、`ui/departure_screen.gd::build` 与 `ui/reward_screen.gd::build` 两处直调）的既有合并分支与调用形态**逐字不变**（直调方继续不传该可选参数） |
| `ui/main.gd::_refresh_card_face` | 体改为调用 `ui/card_face.gd` 新 setter 的组合（仍是「全字段应用」入口）；**新增第 3 个可选参数 `prepared`（预构造面值切片，由 `ui/main.gd::_hand_mount_card` 与 `ui/main.gd::_hand_apply_card` 传入，使每个 (card, side) 切片至多构造一次；不传时现构造）**——签名变更由本次审查裁定授权；翻面接线改为按 uid 读当前数据（`_hand_cards[uid]`），不再捕获构建期 `card` 字典；悬停重入改为延迟调用（与 `fit_text` 同一帧内先布局后重入） | 名字保留、`prepared` 为空时行为与签名语义不变；卡面节点写入只在 `ui/card_face.gd` 的 setter 里（不得留第二份实现）；卡面结构不新增嵌套（见下「必须保持」的节点直接子级） |
| `ui/main.gd::_card_tooltip` | 正文溢出判据改读 `ui/card_face.gd` 的 `text_overflow`（`fit_text` 的结果），不再读 `Content.size`（就地更新后节点尺寸要等引擎排序趟） | 其余行集合、词条框、锚点与显示条件逐字不变 |
| `ui/main.gd::_sync_card_faces`／`card_faces`／`card_draw_serials` | 离行 uid 的键改由 `_hand_release_card` 删除（`ui/main.gd::_receive_player_drop` 的写面路径不变） | 面状态仍是 `card_faces` 单一份；`_sync_card_faces` 仍是「新抽牌面→`card_faces`」的唯一例程；`ui/card_motion.gd` 的临时 display 键（`display_motion_*`）不在清理范围 |
| `ui/main.gd::PRESENT_ADJACENCY` 与表头注释 | `_hand` 行补本片新例程；保留 `_hand → _sync_card_faces`／`_hand_presentation_key` | 只按实现体声明真实直接调用，不加假边；共享手牌辅助函数入表后，其余已登记父函数对这些符号的直接调用同步补边，并补齐每个子符号的独立行 |
| `ui/card_face.gd` | 新增原地更新 setter（每字段一个，值相同即早退）：标题／费用／分类／正文／警告／可用性／词条／条件／art；改写 `ui/card_face.gd::set_mana` 为**按位置／kind 复用**徽章节点与 `StyleBoxFlat`（只改文本、tooltip、字号、`bg_color`／`border_color`；条目数或 kind 变才增删；入参为该面的扁平条目 `[kind, text, detail]`，同 kind 撞名以位置为主、kind 作匹配提示、首个该 kind 保持原名）；词条／条件／魔力三类组的备用节点出树入池（`_spare`，按 kind 分区）而不是销毁，翻回已应用过的面复用同一实例；**内容标签不池化、出 `Content` 后不回插**——条件槽（`CardWarning`／`CardAvailability`）文本清空即由 `ui/card_face.gd::_content_slot` `remove_child`＋`queue_free`、需要时新建，常驻槽（`CardClassification`／`CardEffect`，`always=true`）保持挂载只切 `visible`；由此**内容差额（某条件槽由空变非空或反之）允许销毁／新建该内容标签**，其余值变与重排不得增删实例（**本游戏卡面路径上的经验事实**：把已移除的内容标签再插回 ScrollContainer 的 `Content`，配方里必在后续提交的延迟阶段 SIGSEGV；停用该池化即消失、恢复即复现——配方与消融证据见 `docs/record/verification.md` 2026-10-05 条；E1 表明该形态单独不足以复现（只否定充分性，不是安全性结论），引擎侧机理未确证）；词条与条件共用一条标签组写入路径（`ui/card_face.gd::_write_tags`，样式差异作参数）；`text_overflow` 记录 `fit_text` 的正文溢出结果 | `CardIllustration`／`CardHeader`／`CardTitle`／`CardCost`／`CardMana`（含 `Mana_<kind>`）／`CardText`（含 `Content`、`CardClassification`／`CardEffect`／`CardWarning`／`CardAvailability`）／`CardKeywords`／`CardRequirements` 必须仍是按钮的**直接子节点**且名字不变；`ui/card_face.gd::separate_keywords`／`ui/card_face.gd::dimensions`／`ui/card_face.gd::text_scale`／`ui/card_face.gd::flip_requested`／`ui/card_face.gd::_get_drag_data` 语义不变；不新增 `_process`／tween／第二套节点树 |
| `ui/card_motion.gd` | **零改动** | `ui/card_motion.gd::positions`／`ui/card_motion.gd::enqueue`／`ui/card_motion.gd::clear` 与 `pending_draws` 的隐藏/显示语义不变（本片把 pending 只当 `visible` 值字段） |
| `tests/display_ui_cases.gd` | 新增 `static func present_hand_incremental(t)`（P1–P4／N1–N5／E1–E10 的具名 check，含实例 id 集合差与几何助手 `present_hand_row`／`present_hand_rows`／`present_hand_nodes`／`present_hand_styles`／`present_hand_children`／`present_hand_lost`／`present_hand_delta`／`present_hand_seat`／`present_hand_slot`／`present_hand_given`／`present_hand_source_text` 与源文本判据）；改写 `DISPLAY present hand rebuilds the card when the presentation key changes` 一条；**本轮复核（bunny 2.3／2.4）裁定的夹具与判据调整由本次审查裁定授权**：E7 夹具前提改由投影 `view.hand[i].draw_serial` 驱动（不再强改 `ui.card_draw_serials`，`ui.card_draw_serials` 只在 E8 里作为前提归零）、断言消息措辞、E8 断言体（恒真式 → 实例 id ＋ 八个直接子级）、N2／E9 夹具（起始面预置与幽灵条目 `card_ghost`／`candidate_buttons` 悬空项）——判据面不变、不弱化既有断言；**本轮（手牌崩溃修复审计裁定）新增** P4 段（条件内容标签跨空边界的可达夹具：真→假→真只许该标签销毁／新建，其余实例不变）并把翻面夹具显式限定为"起点面没有一面独有的条件内容标签"的往返 | 其余既有断言不删不改；`present_routes_hand_or_full` 的 `get_view` 计数断言不放宽；不新增分类文件、不改 `tests/ui_smoke.gd` 的 `UI_MODULES` |
| `tests/interface_ui_cases.gd` | 新增卡面 setter 逐字段幂等与布局重算断言（含 N3 的真尺寸分支） | 既有卡面布局／卡图扫描（`get_node` 路径、`CardMana` 子节点数＝该面条目数、`art_bottom` 比例、滚动可达性）不删不改 |
| `tests/card_power_ui_cases.gd`、`tests/binding_search_ui_cases.gd`、`tests/body_layout_ui_cases.gd` | 默认**零改动**（仅当就地更新暴露真实错值时才新增断言） | 翻面后 `visible_text` 只含当前面；`BIND SEARCH UI flipping shows full free effect`；`FOCUS face flip retains the hand control` |
| `docs/spec/response-pipeline.md` | `hand` 节键行改写为「先 `ui/main.gd::_sync_card_faces`，再按固定顺序：每卡窄键＋成员增删＋幂等重排」；缓存清单补面缓存与失效规则；节键成本句补每卡键；证据入口场景 3 给 hand 加限定（每卡键变 ⇒ 该卡按重建边界表处理，不整节替换） | 其余节与场景编号不变；不写执行结果；被取代的措辞删改而不加「更正」段 |
| `docs/spec/release-interface.md` | 「翻面重建对应词条与条件」改为「翻面切换到该面已缓存的词条与条件」（不重建卡面） | 布局常量、词条分离规则、节点名与几何描述不变 |
| `tests/architecture_cases.gd::PRESENT_EXTERNAL_OWNERS`、`tests/architecture_cases.gd::present_adjacency_graph_is_pinned` | 合并管线声明表校验时登记 `CardFace` 的属主文件；手牌新增表项及其已登记直调边同步到 `ui/main.gd::PRESENT_ADJACENCY` | 不放宽直调、可达性、入边与属主解析判据；外部边界仍按文件核对 |
| `docs/spec/hand-refresh-dependencies.md` | 本片契约落盘 | 与主体实现不一致时改本文件而不是放宽实现 |
| 根 `AGENTS.md` 文档入口表 | 增加一行：任务「手牌卡增量刷新（cleaner 核对）」→ `docs/spec/hand-refresh-dependencies.md` | 其它行不改 |
| `docs/record/changelog.md`、`docs/record/verification.md` | 实现完成后各追加一条／一节（日期＋域＋命令＋结果＋未跑项） | 只追加，不改历史条目 |

## 允许的依赖方向

- 不新增任何依赖边：`ui/main.gd` 仍是唯一 `preload` core 的 UI 文件；卡面文案仍只经 `ui/main.gd::card_entry`
  取用（本片把**手牌路径**从直读 `view.card_texts`／`view.card_instances` 收口到该 helper；
  `docs/spec/ondemand-copy.md` §显示侧取用 helper 的其余偏差登记为后续切片，本片不动非手牌调用方）。
- `ui/card_face.gd` 继续只 preload `ui/visual_theme.gd`／`data/card_rules.gd`／`assets`；
  不新增对 `core`／`data` 的读取，不持有 Game／View／候选。
- `core`／`data` 不 preload ui；不新增 View 键、候选、随机域、存档字段、本地化 key。
- 不新增模块、不新增文件（本契约文件除外）、不新增第三方依赖。

## 禁止项

- 用「退回整行重建／整节全量」处理任何值变化或顺序变化（含失灵修复：只修失灵的那一张或切行态）。
- 把 `_hand_key_hit` 的一致性守卫当变更判据；在 `ui/card_face.gd` 里嗅探差异（读节点自身文本）或读 `game.state`。
- 步骤「逐卡」里 free／新建卡面节点或 `StyleBox`（**内容差额触发的该条件内容标签销毁／新建不在此列**，见允许改动表 `ui/card_face.gd` 行；该例外之外仍不得 free／新建）；`set_mana` 保留每次重建；把卡面内容收进每面子容器（双面节点树）。
- 每卡窄键里放 View 级切片（候选／身体／装备／`view.card_costs`）、`version`、纹理或译文文本本体；
  面缓存里放节点引用或纹理；面缓存无 `button_id` 守卫地跨按钮实例存活。
- 在 `ui/` 别处再写一份卡面文案拼装或第二份行键／每卡键；改 `_submit`／`present`／`render` 的先后语义与失败分支；
  改 `ui/main.gd::_hand` 的行几何常量与系数。
- 改 `tests/ui_smoke.gd` 的 `UI_MODULES`／`tests/suite_selection.gd` 的 `CROSS_AREAS`；删或弱化任何既有断言
  （唯一允许的改写是上面点名的那一条，且是**反向而不删**）。
- 推送、打标签、升版本号、打包；把探针／计时脚本／中间产物入库；生产源码留计数器或计时钩子。

## 登记（后续刀候选，本片不要求）

- `ui/main.gd::_hand_node_counts` 在**失配**提交里被扫两遍（`ui/main.gd::_hand_key_hit` 与 `ui/main.gd::_hand_row_plan` 各一次；
  修复前是逐 uid 的 2N 次）。契约未要求单遍：改单遍需沿参数把扫描结果传下去、会改这两处的签名，
  故只登记为后续刀候选，不在本片实施。

## 自检清单（实现者交付前逐条对照）

- 一次只改值且内容占用不变的提交（如 `availability[面].text` 在同可用状态内变）后：同 uid 按钮实例 id 不变、子树实例 id 集合不变、
  `position`／`home`／`rotation` 不变、内容等于新值、`get_view` 计数不变。内容占用跨空边界（该面由可用变不可用或反之）时，
  只允许该条件内容标签（`CardWarning`／`CardAvailability`）销毁或新建，其余实例不变。
- 一次纯顺序变（`view.hand` 顺序变）后：全部实例 id 不变、零增删、位置成对换到新槽位；再 `present` 一次零写入。
- 一次出牌／抽牌后：只有涉及 uid 的按钮被释放／新建，存活 uid 实例 id 不变，位置按新张数几何；
  `card_buttons`／`candidate_buttons`／`card_faces`／`card_draw_serials`／`_hand_cards` 只含当前手牌 uid。
- 翻面两次（翻出再翻回）：按钮与八个直接子节点实例 id 不变；未变魔力条目的徽章节点与
  `get_theme_stylebox_override("panel")` 样式资源实例 id 不变；**实例集合的增删只允许来自条件内容标签
  （`CardWarning`／`CardAvailability`）的跨空边界重建**：起点面没有**一面独有的**条件内容标签
  （两面都没有，或两面都有且存活）的往返零增删（`tests/display_ui_cases.gd::present_hand_incremental`
  的翻面夹具按此前提挑选并断言前提）；
  起点面独有该标签的往返（如一面可用、另一面不可用）只许该标签销毁后新建，其余实例不变
  （同函数 P4 段的跨面夹具钉住这条）。每个 (card, side) 切片构造 ≤ 1 次。
- 只看值字段变化时：`_hand_place_row`（本片新增的重排入口）未被调用（几何键未变）；`fit_text`／头栏布局只在相关字段变时才跑。
- `symbol`／`type` 变与卡增删只重建该 uid；`render` 全量路径仍经 `ui/main.gd::_hand`。
- 手牌路径的卡数据只经 `ui/main.gd::card_entry`（缺键夹具下不崩、`ui.projection_misses` 有具名记录）。
- 源文本（判据的文件域＝`ui/main.gd`）：`render` 函数体内出现 `_hand()`；`CardFace.new()` 只在 `_card` 内；
  `_card(` 的调用点（限 `ui/main.gd`）⊆ 成员增删入口与 `_display_card` —— 离开 `ui/main.gd` 另有
  `ui/departure_screen.gd::build`／`ui/reward_screen.gd::build` 两处直调，不在本判据范围内（它们不传预合并数据）。
- 既有断言全绿（含 `DISPLAY present hand keeps first card instance`、`FOCUS face flip retains the hand control`、
  `interface` 的卡面几何扫描），被改写的那一条按新判据绿且**没有被删掉**。
- 计数与耗时证据：节点创建／销毁、卡面重建次数、整行重建次数（S1–S5＝0）＋ 子键逐档（0／12／26／44 件）不随件数增长；
  探针只放 `build/`，`git diff` 内无打印／临时夹具。
