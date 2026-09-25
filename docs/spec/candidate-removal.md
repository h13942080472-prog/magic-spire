# 候选层移除与指令路由契约（candidate-removal）

本文件是现行契约（规划产物）：**彻底移除候选层**（候选行表全量物化、稳定 ID 提交身份、行动行索引文件（`action_index.gd`，R5 已删除）
行索引、`dispatch` 按 ID 取行复核），代之以「前端指令 → 同一路由 → 分类子路由 → 后端 core 唯一提交入口」。
本文件**取代**原 candidate-bypass、candidate-bypass-dependencies、candidate-delta 三片（文件已删）的全案（F1–F9／W1–W5／B1–B4／H1–H5／C0–C4 作废为**未开工**，不是已通过）；
依据＝人类指令（2026-09-23）："候选层的存在无意义，规划彻底移除候选层，前端指令汇集到同一个路由，
分类发到子路由，子路由再发到后端"＋"行动前先建管线表，用邻接表储存，根据建的表做修改，每条边有且仅有一条
对应路径，确保同一个方法没有重复实现"。

**状态：`needs-human-review`**——人审通过（协调者记录）前，实现者不得开工。本文件不写执行结果；
通过／失败／未执行只登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。引用代码不写行号，用函数名与符号锚点；
未落地符号只写纯文本名并注明「未落地」，不写成 `文件::符号` 锚点。

## 1 管线表·现状图（邻接表，源码复算）

- 口径：节点＝**已核对声明存在**的符号锚点（本分支工作树 `rg` 实测）；边＝（来源→去向＋类型：
  调用／数据／写入）＋**恰好一条对应路径**；同一语义的多条边在第 2 节「重复实现检查」逐条列成缺陷。
- 本表**从源码复算**，不从契约文本转抄；契约与源码冲突之处以源码为准，差异见表末「源码↔契约差异」。
- 标记：**[R]**＝移除对象（候选层载体）；**[K]**＝保留（语义不变，仅改取值来源或保持原样）；
  **[K*]**＝保留但走新载体（判定本身不消失，见 P1）。

### 1.1 A 组：指令汇集（前端指令 → 提交入口）[R]（目标态改走指令路由，见第 2 节）

**R2 前**：`ui/main.gd::_submit` 是唯一提交入口，但指令的形成散布在 54 条控件回调路径，每条自行持
候选字典 `c` 并直接 `_submit(c)`；下表为规划时的边集（R2（`a18860a`）已把这 60 条边收敛为 T1 单一路径，
直连 0 条，见 §2 与第 4 节；锚点按批同步到落地符号）：

| 边 | 来源 → 去向 | 类型 | 对应路径（唯一） |
| --- | --- | --- | --- |
| A1 | `ui/main.gd::_relic_row` → `ui/main.gd::_submit` | 调用 | 遗物行快捷键回调 `_submit(choice)` |
| A2 | `ui/main.gd::_status_control` → `ui/main.gd::_submit` | 调用 | 状态按钮回调 `_submit(choice)` |
| A3 | `ui/main.gd::_basic_action_tile` → `ui/main.gd::_submit` | 调用 | 行动格按钮回调（不可翻面分支） |
| A4 | `ui/main.gd::_posture_controls` → `ui/main.gd::_submit` | 调用 | 姿态按钮回调 `func():_submit(c)` |
| A5 | `ui/main.gd::_bottom_controls` → `ui/main.gd::_submit` | 调用 | 底栏行动按钮回调 `func(): _submit(c)` |
| A6 | `ui/main.gd::_bottom_controls` → `ui/main.gd::_submit` | 调用 | 投降分支 `_submit(surrender)` |
| A7 | `ui/main.gd::_wall_controls` → `ui/main.gd::_submit` | 调用 | 墙面按钮回调 `func():_submit(c)` |
| A8 | `ui/main.gd::_equipment_tile` → `ui/main.gd::_submit` | 调用 | 一键解除按钮回调 |
| A9 | `ui/main.gd::_action_row` → `ui/main.gd::_submit` | 调用 | 保留面卡按钮回调 |
| A10 | `ui/main.gd::_action_row` → `ui/main.gd::_submit` | 调用 | 行动行按钮回调 `func(): _submit(c)` |
| A11 | `ui/main.gd::_card_target` → `ui/main.gd::_submit` | 调用 | 打出按钮回调 |
| A12 | `ui/main.gd::_prison_controls` → `ui/main.gd::_submit` | 调用 | 监狱「前往」按钮回调 |
| A13 | `ui/main.gd::_prison_controls` → `ui/main.gd::_submit` | 调用 | 监狱选项按钮回调 |
| A14 | `ui/main.gd::_compact_action` → `ui/main.gd::_submit` | 调用 | 紧凑行动按钮回调 |
| A15 | `ui/main.gd::_route_screen` → `ui/main.gd::_submit` | 调用 | 路线屏「前进一回合」按钮回调 |
| A16 | `ui/main.gd::_select_route_room` → `ui/main.gd::_submit` | 调用 | 房间按钮回调 |
| A17 | `ui/main.gd::_queue_map_step` → `ui/main.gd::_submit` | 调用 | 地图步进分支 |
| A18 | `ui/main.gd::_show_drop_targets` → `ui/main.gd::_submit` | 调用 | 落点 `click_to_use` 回调 |
| A19 | `ui/main.gd::_activate_guard_bind_target` → `ui/main.gd::_submit` | 调用 | 捕缚条目标分支 |
| A20 | `ui/main.gd::_receive_player_drop` → `ui/main.gd::_submit` | 调用 | `self_action_id` 拖放分支 |
| A21 | `ui/command_routes.gd::_card_intent` → `ui/main.gd::_submit` | 调用 | 自由面分支 |
| A22 | `ui/main.gd::_activate_card` → `ui/main.gd::_submit` | 调用 | 手牌选择分支 |
| A23 | `ui/main.gd::_activate_card` → `ui/main.gd::_submit` | 调用 | 快捷解除分支 |
| A24 | `ui/main.gd::_activate_card` → `ui/main.gd::_submit` | 调用 | 唯一装备分支 |
| A25 | `ui/command_routes.gd::_card_intent` → `ui/main.gd::_submit` | 调用 | 非 `hand_uid` 分支 |
| A26 | `ui/main.gd::_item_details` → `ui/main.gd::_submit` | 调用 | 道具目标按钮回调 |
| A27 | `ui/main.gd::_item_details` → `ui/main.gd::_submit` | 调用 | 丢弃按钮回调 |
| A28 | `ui/deck_browser.gd::refresh` → `ui/main.gd::_submit` | 调用 | 牌堆浏览选择回调 |
| A29 | `ui/departure_screen.gd::build` → `ui/main.gd::_submit` | 调用 | 出发卡牌按钮回调 |
| A30 | `ui/departure_screen.gd::build` → `ui/main.gd::_submit` | 调用 | 出发条目按钮回调 |
| A31 | `ui/departure_screen.gd::build` → `ui/main.gd::_submit` | 调用 | 出发候选按钮回调 |
| A32 | `ui/event_screen.gd::action` → `ui/main.gd::_submit` | 调用 | 事件行动按钮回调 |
| A33 | `ui/event_screen.gd::drawer` → `ui/main.gd::_submit` | 调用 | 事件卡面按钮回调 |
| A34 | `ui/event_screen.gd::multi_restraint_selector` → `ui/main.gd::_submit` | 调用 | 多拘束选择确认分支 |
| A35 | `ui/first_turn_presenter.gd::_step` → `ui/main.gd::_submit` | 调用 | 自动接管步骤（`takeover=true`） |
| A36 | `ui/keyboard_input.gd::handle` → `ui/main.gd::_submit` | 调用 | 键盘确认分支 |
| A37 | `ui/keyboard_input.gd::confirm` → `ui/main.gd::_submit` | 调用 | 键盘目标确认 |
| A38 | `ui/keyboard_input.gd::_process` → `ui/main.gd::_submit` | 调用 | 长按结束回合分支 |
| A39 | `ui/mana_flask.gd::build` → `ui/main.gd::_submit` | 调用 | 魔瓶按钮回调 |
| A40 | `ui/command_router.gd::emit` → `ui/command_routes.gd::_resolved_card` | 调用 | 带 `hand_uid` 卡牌的改道分支 |
| A41 | `ui/main.gd::_activate_card` → `ui/command_routes.gd::_card_intent` | 调用 | 自身目标卡改道 |
| A42 | `ui/main.gd::_receive_player_drop` → `ui/command_routes.gd::_card_intent` | 调用 | 拖放自身目标改道 |
| A43 | `ui/main.gd::_activate_card` → `ui/command_routes.gd::_card_intent` | 调用 | 自由面改道 |
| A44 | `ui/main.gd::_receive_player_drop` → `ui/command_routes.gd::_card_intent` | 调用 | 拖放自由面改道 |
| A45 | `ui/main.gd::_activate_card` → `ui/quick_release_bar.gd::candidate` | 调用 | 快捷解除取行（唯一查询路径） |
| A46 | `ui/reward_screen.gd::build` → `ui/main.gd::_submit` | 调用 | 额外奖励按钮回调（`extra`） |
| A47 | `ui/reward_screen.gd::build` → `ui/main.gd::_submit` | 调用 | 奖励页继续按钮回调（`next`） |
| A48 | `ui/reward_screen.gd::row` → `ui/main.gd::_submit` | 调用 | 单选奖励行分支 `_submit(choices[0])` |
| A49 | `ui/reward_screen.gd::cards` → `ui/main.gd::_submit` | 调用 | 三选一卡面按钮回调 |
| A50 | `ui/reward_screen.gd::relics` → `ui/main.gd::_submit` | 调用 | 遗物选项按钮回调 |
| A51 | `ui/reward_screen.gd::skip_button` → `ui/main.gd::_submit` | 调用 | 跳过按钮回调 |
| A52 | `ui/relic_bundle_screen.gd::build` → `ui/main.gd::_submit` | 调用 | 继续按钮回调（`skip` 变量，continue_label） |
| A53 | `ui/relic_bundle_screen.gd::build` → `ui/main.gd::_submit` | 调用 | 领取按钮回调（`take`） |
| A54 | `ui/relic_bundle_screen.gd::build` → `ui/main.gd::_submit` | 调用 | 跳过按钮回调（`skip`） |
| A55 | `ui/relic_bundle_screen.gd::build` → `ui/main.gd::_submit` | 调用 | 完成领取／跳过剩余按钮回调（`finish`） |
| A56 | `ui/shop_screen.gd::_ready` → `ui/main.gd::_submit` | 调用 | 刷新按钮回调（`refresh_button`） |
| A57 | `ui/shop_screen.gd::_ready` → `ui/main.gd::_submit` | 调用 | 继续旅程按钮回调（`leave`） |
| A58 | `ui/shop_screen.gd::_card_offer` → `ui/main.gd::_submit` | 调用 | 商店卡面按钮回调 |
| A59 | `ui/shop_screen.gd::_offer` → `ui/main.gd::_submit` | 调用 | 报价按钮回调 |
| A60 | `ui/shop_screen.gd::services` → `ui/main.gd::_submit` | 调用 | 去卡卡面按钮回调 |

A 组每条边＝一条对应路径（同函数内两条提交分支已拆成两条边）；但 54 条指令路径**各自持候选字典**
（同一「前端指令→提交」语义 54 条路径），列入第 2 节重复实现检查 DUP1——**R2（`a18860a`）已销**：
收敛为 `ui/command_router.gd::emit` 单一路径。

### 1.2 B 组：提交与复核链（后端唯一提交入口）

| 边 | 来源 → 去向 | 类型 | 对应路径（唯一） | 标记 |
| --- | --- | --- | --- | --- |
| B1 | `ui/main.gd::_submit` → `core/game.gd::dispatch` | 调用 | 表达式 `game.dispatch(c.id, …)`；UI 侧实测唯一 `dispatch` 调用点 | [K] |
| B2 | `core/game.gd::dispatch` → ``candidates`（历史名，R5 已删除）` | 调用 | `for c in candidates():` 按 `c.id==candidate_id` 取首条命中行复核 | [R] |
| B3 | `core/game.gd::dispatch` →（预检×5）`Consumables.validate_buffs`／`Binding.state_issue`／`SpecialEquipment.validate`／`Cards.validate`／`RelicEffects.validate` | 调用 | `dispatch` 开头五条早退守卫（顺序见差异 D-1） | [K] |
| B4 | `core/game.gd::dispatch` → 版本比对 | 判定 | `expected_version!=state.version` 早退 | [K] |
| B5 | `core/game.gd::dispatch` → `core/game.gd::_execute` | 调用 | 默认执行分支 | [K] |
| B6 | `core/game.gd::dispatch` → `Events.execute`／`Departure.execute`／`Services.execute`／`Prison.execute`／`Guard.capture`／`Game._depart` | 调用 | `payload.kind` 分支执行（event／departure／service／depart／surrender／prison） | [K] |
| B7 | `core/game.gd::dispatch` → `state` | 写入 | `state=state.duplicate(true)` 事务副本；issue → `state=original` 全回滚；成功 `state.version` 一次自增 | [K] |
| B8 | `core/game.gd::dispatch` → `core/first_turn_control.gd::commit` | 调用＋写入 | 事务内消费 `control_next`（写 `state.combat.first_turn_control`） | [K] |
| B9 | `ui/main.gd::_submit` → `core/game.gd::get_view` | 调用 | 提交后取投影（成功／被拒均取）；白名单调用点之一 | [K] |
| B10 | `core/game.gd::dispatch` → `core/game.gd::validate` | 调用 | 收尾校验，issue → 全回滚 | [K] |

### 1.3 C 组：候选物化（行表构建）[R 整组]

| 边 | 来源 → 去向 | 类型 | 对应路径（唯一） | 标记 |
| --- | --- | --- | --- | --- |
| C1 | ``candidates`（历史名，R5 已删除）` → ``_build_candidates`（历史名，R5 已删除）` | 调用 | `candidates()` 体内唯一调用 | [R] |
| C2 | ``candidates`（历史名，R5 已删除）` → `core/first_turn_control.gd::select` | 调用 | `candidates()` 体内后处理（改写行——R1 `20e3ff1` 后改由判定结论 merge，见差异 D-2） | [R] |
| C3 | ``_build_candidates`（历史名，R5 已删除）` → ``_phase_candidates`（历史名，R5 已删除）` | 调用 | `_build_candidates` 体内唯一调用 | [R] |
| C4 | ``_build_candidates`（历史名，R5 已删除）`／``_phase_candidates`（历史名，R5 已删除）` → ``_candidate`（历史名，R5 已删除）` | 调用 | 内联行构造（surrender／item_discard／status_toggle／rest_*／retain 等） | [R] |
| C5 | core 各生产者 → ``_candidate`（历史名，R5 已删除）` | 调用 | `g._candidate(…)` 转发 38 处、`_candidate(` 命中 79 处（含定义行；精确复算见 §3.3.3 ③）（`core/card_effects.gd`、`core/consumables.gd`、`core/demo_exit.gd` 等＋转发包装 `Prison.add`／`target_candidate`／`paid_candidate`） | [R] |
| C6 | `core/first_turn_control.gd::select` → ``_candidate`（历史名，R5 已删除）` | 调用 | 直呼行工厂合成「接管结束」行（候选表构建之外的调用者，见差异 D-3） | [R] |
| C7 | ``_candidate`（历史名，R5 已删除）` → 行字典 | 写入 | 唯一行工厂：`row.id=JSON.stringify(payload).sha256_text().substr(0,24)`、`valid`／`reason`／`risk`／`mana_payment`／`detail`（card 组不预生成） | [R] |
| C8 | `core/first_turn_control.gd::select` → 行字典 | 写入 | 原为 `blocked.valid=false`、`blocked.reason="豆包接管中"`（`valid`／`reason` 第二写点）；R1 `20e3ff1` 已销——改由判定 `eligibility_takeover` 结论 merge | [R] |
| C9 | `core/game.gd::candidate_detail` → ``_candidate`（历史名，R5 已删除）_detail` | 调用 | card 组 detail 按需现算 | [K*] |

### 1.4 D 组：投影与显示读取

| 边 | 来源 → 去向 | 类型 | 对应路径（唯一） | 标记 |
| --- | --- | --- | --- | --- |
| D1 | `core/game.gd::get_view` → `core/game_view.gd::build` | 调用 | `get_view()` 体内唯一调用 | [K] |
| D2 | `core/game_view.gd::build` → ``candidates`（历史名，R5 已删除）` | 调用 | `var actions=g.candidates()`——投影全量物化行表 | [R] |
| D3 | `core/game_view.gd::build` → 行字典 | 写入 | 投影追加 `release_preview`／`casting`／`body_part`／`brief`／`brief_tags` | [R] |
| D4 | `core/game_view.gd::build` → `core/card_effects.gd::availability` | 调用 | `hand.availability` 显示派生（输入＝该牌候选行 `choices`） | [K*] |
| D5 | `core/game_view.gd::build` → `core/first_turn_control.gd::view` | 调用 | `first_turn_control` 投影键 | [K] |
| D6 | `core/game_view.gd::build` → `view.candidates` | 数据 | 行表原样进 View（`"candidates":actions`） | [R] |
| D7 | `ui/main.gd::render` → `core/game.gd::get_view` | 调用 | 空快照兜底（白名单调用点之一） | [K] |
| D8 | `ui/main.gd::render` → `行动行索引的 `_init`（历史名）` | 调用＋数据 | `actions=ActionIndex.new(view.candidates)`——每次 `render` 全量重建行索引 | [R] |
| D9 | `行动行索引的 `select`（历史名）`／`find`／`first_usable` → 行字典 | 数据 | 按 `by_id`／`by_group` 查行，读 `payload`／`valid`；`first_usable` 末项回退 | [R] |
| D10 | `ui/target_queries.gd::*` → `行动行索引的 `select`（历史名）`／`first_usable` | 调用 | 拖放／身体／快捷解除的取行筛选（`body_cards`／`single_*`／`payload_candidates`／`release_*`） | [R] |
| D11 | `ui/main.gd::detail_of` → `core/game.gd::candidate_detail` | 调用 | 显示侧 detail 取用唯一 helper | [K*] |
| D12 | `ui/main.gd::card_entry` → `core/game.gd::live_card_text` | 调用 | 卡面文案补算 helper | [K] |
| D13 | `ui/main.gd` 各节函数 → `行动行索引的 `select`（历史名）`／`find` | 调用 | 显示可用性／原因读取（`valid`／`reason` 原文上屏） | [R] |

### 1.5 E 组：世界替换与持久化 [K 全组]

| 边 | 来源 → 去向 | 类型 | 对应路径（唯一） |
| --- | --- | --- | --- |
| E1 | `ui/main.gd::_resume_snapshot` → `core/game.gd::get_view`／`restore_snapshot` | 调用 | 读档／继续（白名单调用点） |
| E2 | `ui/main.gd::restart` → `core/game.gd::get_view`／`restart_snapshot` | 调用 | 新局／练习（白名单调用点） |
| E3 | `ui/main.gd::_quick_sl` → 快照入口 | 调用 | 快速 SL（白名单调用点） |
| E4 | `ui/main.gd::_submit` → `ui/main.gd::_save_progress` | 调用＋写入 | 仅 `result.checkpoint` 非空时写盘 |
| E5 | `ui/first_turn_presenter.gd::sync`／`advance` → `view.first_turn_control` | 数据 | 接管展示只读 View，经 A35 回提交 |

### 1.6 源码↔契约差异（以源码为准，实现期须同步契约文字）

| 差异 | 契约说法 | 源码实测 |
| --- | --- | --- |
| D-1 | `response-pipeline.md`「失败语义」：版本不符→ID 失效→valid=false→五个 validate；`candidate-bypass.md` F5：六个 validate→版本比对 | 5 条预检：`Consumables.validate_buffs`、`Binding.state_issue` 在版本比对**之前**，`SpecialEquipment.validate`、`Cards.validate`、`RelicEffects.validate` 在**之后**；版本比对是第 3 步 |
| D-2 | F4／F7 口径：`valid`／`reason` 唯一写点是 `_candidate` | **R1（`20e3ff1`）已销**：原 `core/first_turn_control.gd::select` 也写 `blocked.valid`／`blocked.reason`（"豆包接管中"）；现唯一写点是 `core/game.gd::eligibility`／`eligibility_takeover` |
| D-3 | F6：行工厂只服务候选集合构建 | `core/first_turn_control.gd::select` 直呼 `_candidate` 合成「接管结束」行 |
| D-4 | `response-pipeline.md` 接缝 A：`candidate_id` 必须来自当前 View 的 `candidates` | 实测一致；但**取行复核**在 `dispatch` 内以「当前 `candidates()` 全量重建＋按 id 首命中」实现（B2），而非查表 |

## 2 管线表·目标图（邻接表）＋增删边清单＋重复实现检查

### 2.1 目标图

节点约定：**未落地**符号只写工作名并注明「未落地」，不写 `文件::符号` 锚点；落地名以实现批为准，
改名须改本契约。现存符号沿用第 1 节锚点。

- N1 **指令路由**（`ui/command_router.gd`，R2 落地）：前端**唯一指令入口**；
  接收类型化指令，持有「分类 → 子路由」声明表（唯一分类点，`ROUTES`）。
- N2 **分类子路由**（`ui/command_routes.gd`，R2 落地）：
  每类指令一条子路由，把 UI 意图（点击、键盘、触屏、拖放、自动接管）**装配**为类型化指令并做 UI 级
  前置（版本取值、本地选中态解析）；**不判定资格**。
- N3 **类型化指令**（数据形状，未落地）：`{kind: String, params: Dictionary, expected_version: int}`；
  `kind`／`params` 只用稳定 ID（template/type/id/uid/slot/target…），不用译文、名称、颜色、图片。
- N4 **唯一合法性判定**（工作名 eligibility，未落地）：输入＝指令形状＋当前状态，输出＝
  `{valid, reason, risk, cost, mana_payment, …}`（文案逐字沿用现状）；**全仓唯一一份判定实现**。
- N5 **后端唯一提交入口**：`core/game.gd::dispatch`（现存，签名改收类型化指令＋`expected_version`）。
- N6 执行与事务：`core/game.gd::_execute` 与各 `*.execute`／`Guard.capture`／`_depart`、事务副本与全回滚（现状不动）。
- N7 投影：`core/game.gd::get_view` → `core/game_view.gd::build`（现存；改为按**显示点**经 N4 取显示事实，
  不再物化行表）。
- N8 显示消费：`ui/main.gd` 各节函数＋`ui/target_queries.gd` 的**纯显示查询**（`body_at`／`equipment_entries` 等，
  不含行筛选面）；`ui/main.gd::detail_of`／`card_entry`（现存 helper，保留）。
- N9 持久化与世界替换：`ui/main.gd::_save_progress`／`_resume_snapshot`／`restart`／`_quick_sl`（现状不动）。

目标邻接表（**每条边恰好一条对应路径**；未落地边的「对应路径」＝落点声明，落地后由实现批补实测）：

| 边 | 来源 → 去向 | 类型 | 对应路径 | 取代 |
| --- | --- | --- | --- | --- |
| T1 | 各 UI 指令来源（A1–A39、A46–A60 的来源符号）→ N1 指令路由 | 调用 | **唯一前端指令入口**：控件回调只 `emit(类型化指令)`，不持候选字典、不直接提交 | A1–A60 |
| T2 | N1 指令路由 → N2 分类子路由 | 调用 | 唯一分类点：按 `kind` 查声明表转子路由；表外 `kind` fail-closed（拒绝并记录，不静默） | （新） |
| T3 | N2 分类子路由 → `core/game.gd::dispatch` | 调用 | **唯一后端提交边**（UI 侧 `dispatch` 调用点唯一，实测断言锁住） | B1（改签名） |
| T4 | `core/game.gd::dispatch` → N4 唯一判定 | 调用 | 提交侧**强制复核**（指令形状＋参数合法性＋判定）；`core/game.gd::command_fact` 经 kind 调该生产者，不经全表 | B2 |
| T5 | `core/game_view.gd::build` → N4 唯一判定 | 调用 | 显示侧取可用／原因／风险（按显示点计算，不物化全表）；R3 落地：`core/game.gd::command_facts` 逐显示点调 `core/game.gd::display_fact`；R4 落地：同投影增加 equipment／hooks／items／chain／retain | D2、D3、D4、D6 |
| T6 | N2 分类子路由 → `core/game.gd::candidate_detail`／`live_card_text`（经 `ui/main.gd` helper） | 调用 | detail／卡面按需现算（现状保留） | D11、D12（保留） |
| T7 | `core/game.gd::dispatch` → N6 执行与事务 | 调用＋写入 | 事务副本、失败全回滚、成功 `version` 一次自增（不变） | B5–B8、B10（保留） |
| T8 | N7 投影 → `view` 显示事实 | 数据 | 每显示点的 `{可用, reason, risk, cost, …}`＋现有显示字段；**不含候选行、不含提交身份 id** | D6 |
| T9 | N8 显示消费 ← `view` 显示事实 | 数据 | 节函数按显示点读显示事实上屏；不可用文本＝判定 `reason` 原文；R3 落地：显示点按 `ui/main.gd::display_key`（＝`core/game.gd::shape_key` 的形状键）取事实；R4 落地：仍存行 id 的装备／拖放／道具接合用 `ui/target_queries.gd::fact_key`（载荷摘要，不把提交身份写进显示事实） | D9、D10、D13 |
| T10 | N9 持久化（E1–E5） | 调用＋写入 | 世界替换与固定点写盘（不变） | E1–E5（保留） |

**P2 口径**：T4（提交侧）与 T5（显示侧）是**同一判定实现的两条调用边**，不构成第二份判定；
任何第三条判定路径（重算 `valid`／`reason` 的第二实现）即缺陷。

查找边真源＝`tests/architecture_cases.gd::PIPELINE_LOOKUP_EDGES`（机读表）；检查入口＝`tests/architecture_cases.gd::pipeline_lookup_inspect`（由 `tests/architecture_cases.gd::command_fact_kind_lookup` 调用）。本契约不复制该表。

### 2.2 增删边清单

- **删边（随对应增边同批删除）**：A1–A60（54 条直连＋6 条改道链，收敛为 T1）、B2（按 id 取行复核）、
  C1–C8（候选物化整组，含 `first_turn_control` 的行写点与直呼行工厂）、D2、D3、D4（改走 T5）、D6、
  D8、D9、D10、D13（行索引与行筛选）。
  **R3 已删 D13 的手牌／行动／姿态／墙面／底栏行读边**（`ui/main.gd::_build_action_rail`／`_posture_layout`／
  `_posture_controls`／`_wall_controls`／`_bottom_controls`／`_hand_choice`；核对面＝`tests/display_ui_cases.gd::r3_display_points_do_not_read_rows`）。
  **R4 已删装备／快捷解除／拖放／道具行读边**（D10 的 `ui/target_queries.gd::body_cards`／`single_*`／`payload_candidates`／`release_*`，以及 `ui/main.gd::_equipment_actions`／`_attack_drop_candidate`／`_item_details`／`_door_candidate`／`_free_player_candidate`／`_hook_drawer`／`_guard_bind_card_candidate`／`_chain_screen`、`ui/quick_release_bar.gd`、`ui/drag_targets.gd`、`ui/keyboard_input.gd::select_card`／`refresh_choices`；核对面＝`tests/display_ui_cases.gd::r4_display_points_do_not_read_rows`）。
  **R5 已删服务／事件／监狱／路线／奖励／出发行读边**（同批删除行载体与行索引文件，销 DUP3／DUP5；
  核对面＝`tests/architecture_cases.gd::removal_end_state` 与 `tests/display_ui_cases.gd::r5_display_facts_match_determination`）。
- **新增边**：T1、T2、T3（签名改）、T4、T5。
- **保留边**：B1（签名改）、B3–B7、B9、B10、C9、D1、D5、D11、D12、E1–E5。
- **终态断言**（全部批次完成后 `rg` 复算）：`candidates`／`_candidate`／`_build_candidates`／
  `_phase_candidates`／行动行索引文件（`action_index.gd`，R5 已删除） **不存在**；写 `valid`／`reason` 的位置只有 N4 一处；
  UI 侧 `dispatch` 调用点唯一；无按提交身份 id 的取行复核。

### 2.3 重复实现检查（同一语义多路径，逐条列成缺陷）

| 编号 | 语义 | 现状多路径 | 处置 |
| --- | --- | --- | --- |
| DUP1 | 「前端指令 → 提交」 | 54 条控件回调路径各自持候选字典直提（A1–A39） | 收敛为 T1（批 R2 同批删直连）——**R2（`a18860a`）已销项** |
| DUP2 | 「资格结论（valid／reason）的产生」 | ``_candidate`（历史名，R5 已删除）`（行工厂写）＋`core/first_turn_control.gd::select`（接管阻断改写） | 收敛进 N4 一处（批 R1；接管阻断改由判定读接管状态返回同文案）——**R1（`20e3ff1`）已销项** |
| DUP3 | 「从可选行动中定位要提交的那条」 | `core/game.gd::dispatch` 按 id 首命中＋`行动行索引的 `select`（历史名）/find/first_usable`＋`ui/target_queries.gd` 的筛选族 | 提交侧＝N4 形状复核（T4）；显示侧＝显示事实（T9）；行筛选整族删除 |
| DUP4 | 「首个可用项回退」 | `行动行索引的 `first_usable`（历史名）`（全不可用返回**末项**）与 `ui/target_queries.gd::first_usable`（返回**首项**）同名不同义 | **R4 已落地**：唯一通道＝`ui/target_queries.gd::first_usable`（参数 `fallback`）；`行动行索引的 `first_usable`（历史名）` 以 `last` 委托。首项与末项可见行为各自保留 |
| DUP5 | 「行的构造」 | `_build_candidates`／`_phase_candidates` 生产链（`g._candidate(` 38 处；口径见 §3.3.3 ③）＋`first_turn_control` 直呼行工厂 | 行构造随行载体删除（批 R5）；生产者改投影显示事实构建 |
| DUP6 | 「提交前的指令装配／改道」 | `_submit → _use_self_card → _submit` 等 6 条改道边（A40–A45） | 并入 N2 分类子路由的装配逻辑（批 R2）——**R2（`a18860a`）已销项** |
| （非缺陷） | detail 组装 | eager（`_candidate` 内）与按需（`candidate_detail`）共用同一组装函数 | 同一实现两条调用边，符合 P2；随行载体删除后只留按需一路 |

## 3 模块切法（边界・依赖方向・小接口）＋术语消歧

### 3.1 切法与 Deep Module 小接口

| 模块 | 边界（谁） | 小接口 | 内部（藏） |
| --- | --- | --- | --- |
| M-I 指令层（UI） | **指令路由**（`ui/command_router.gd`，R2 落地）＋**分类子路由**（`ui/command_routes.gd`，R2 落地）＋**指令形状**（数据约定，未落地） | 指令路由：`emit(cmd)`（前端**唯一**指令入口）；分类转发表 `ROUTES = {kind → 子路由}`（唯一分类点）。子路由：`assemble(意图) -> cmd`（每类指令恰一条） | 分类表、守卫早退（首页／播报期／接管锁）、UI 意图装配（本地选中态、拖放数据→`params`）、原 A40–A45 改道逻辑 |
| M-II 判定（core） | **唯一合法性判定**（工作名 eligibility，未落地） | `check(game_state, cmd) -> {valid, reason, risk, cost, mana_payment, …}` | 现 ``_candidate`（历史名，R5 已删除）` 的全部判定分支（能量／魔力／锁／诅咒／施法率／end 原因／接管阻断）；文案逐字不变 |
| M-III 提交（core） | `core/game.gd::dispatch`＋执行与事务（现存） | `dispatch(cmd, expected_version) -> {ok, error, version, resource_feedback, card_feedback, music_feedback, checkpoint}`（**返回形状不变**） | 指令形状＋参数合法性复核、事务副本、全回滚、执行分支 |
| M-IV 投影（core） | `core/game.gd::get_view`／`core/game_view.gd::build`（现存） | `get_view()` 签名与调用点白名单不变 | 显示点 → 指令形状的映射；显示事实计算（调 M-II） |
| M-V 显示消费（UI） | `ui/main.gd` 节函数、`ui/target_queries.gd` 纯显示查询、`ui/main.gd::detail_of`／`card_entry` | 显示事实读取（`reason` 原文上屏） | 节重建、布局 |
| M-VI 持久化 | `ui/main.gd::_save_progress`／`_resume_snapshot`／`restart`／`_quick_sl`（现存，不动） | 现状不变 | — |

- **指令形状**（N3）：`{kind: String, params: Dictionary, expected_version: int}`；`kind` 与 `params`
  只用稳定 ID（type／uid／slot／target／item／enemy／mode…），**不含候选提交身份 id**；
  **kind 全集与 params 键表见 §3.3**（Q5 裁定：先出清单供人类过目，再批 R2 实现）。
  本行旧句「各 kind 的 `params` 键表在 R2 批随分类子路由定稿」与 §3.3 冲突时**以 §3.3 为准**：
  R2 只按 §3.3 的键面装配指令，落地期新增 kind 须先回填 §3.3（覆盖优先：每条可提交指令恰有一个 kind）。
- **依赖方向（不新增反向边）**：core／data 不 preload ui；UI 内只有 `ui/main.gd` 允许 preload core
  （现行规则）。指令路由与分类子路由**不得** preload core；提交执行段留在 `ui/main.gd`
  （即 `ui/main.gd::_submit` 的改造形态或改名后的同位符号，实现期定名），子路由**经该段**触
  `core/game.gd::dispatch`——T3 的「唯一后端提交边」指该段到 `dispatch` 的唯一调用点（断言锁住）。
- **指令路由／子路由落在哪一层**：UI 层 M-I，落法一已落地（Q1 提名两案中的新增文件案）：
  新增 `ui/command_router.gd`（指令路由）与 `ui/command_routes.gd`（分类子路由），按
  `docs/spec/response-pipeline.md` 的授权边界「默认不新增 UI 文件，先向协调者提案」走审批。落法二
  （不新增文件、在 `ui/main.gd` 内立指令段）随两文件落地作废。
- **Deep Module 口径**：调用方（控件回调）只见 `emit(cmd)`；判定调用方只见 `check(...)`；
  `dispatch` 调用方只见返回字典。内部杂乱（改道、守卫、判定分支、装配）全部藏在小接口后。
- **同名方法去重义务**：装配、分类、判定、提交各只允许一条实现路径（第 2.3 节 DUP 表逐条销项）；
  新增任何第二实现即违反本契约。

### 3.2 术语消歧（一次消歧，P4）

| 术语 | 唯一含义 |
| --- | --- |
| **指令路由／子路由** | 前端指令分发层（本契约 M-I），别名 command router |
| **套件选择** | 测试按源码变更选套件（原被称作"检查路由"／"路由"）；本契约起文档统一称「套件选择」 |
| **文案路由** | `core/copy_router.gd` 的文案收口（`docs/spec/ondemand-copy.md` 专有），引用须带「文案」限定 |
| （动词"路由／分发"） | 泛指把调用送到具体运作层，不是上述任何名词 |

受影响文件（点名，实现期随批统一改写，本片不动）：`docs/spec/response-pipeline.md`
（「术语与增量方向」段改为「套件选择」＋「指令收口／分发」新义）；`docs/spec/ondemand-copy.md`
（标题与正文的"路由"补「文案」限定，可选）；`docs/record/proposals/check-routing-and-per-click-checks.md`
（record 只追加**不改**，以本表为准）；根 `AGENTS.md` 实现规约「到具体运作层再路由」（动词用法，**不改**）。

### 3.3 指令 kind 全集与 params 键表（R2 定稿输入）

Q5 裁定：**先出清单供人类过目，再批 R2 实现**。本节对**源码复算**（不从契约文本转抄），是 R2 批
指令形状（N3）与分类转发表（N2）的键面真源；R2 的 Gherkin 2（分类表全量）按本节逐条核。落地状态：
本节为**清单**，不是「已通过」；R2 仍未获批。

**复算命令与命中（在 `spire-godot/` 下执行，2026-09-23 工作树实测）**

```powershell
rg -o '(^|[^_a-zA-Z])_candidate\(' core/*.gd                      # 79（含定义行 1＝调用点 78）
rg -o 'g\._candidate\(' core/*.gd                                 # 38（生产者转发包装直呼）
rg -n 'chosen\.payload\.kind==' core/game.gd                      # 12（dispatch 的 kind 特判分支条件）
rg -n 'match p\.kind:' -A 40 core/game.gd                         # _execute 默认执行分支（30 arm／33 kind）
rg -n 'actions\.(select|find|first_usable)\("' ui/ --glob '*.gd'  # 显示侧按 payload 字段取行＝params 键的证据面
rg -o '_submit\(' ui/ --glob '*.gd'                               # 55（54 提交边＋定义行）
```

- **kind 判定法＝三面交叉，实测相等**：①各生产者产出的 payload `kind` 取值（`core/` 内 `_candidate`
  第 2 实参的字面量与动态构造，含 `core/prison.gd::add`／`core/room_services.gd::paid_fact`
  两个转发包装）；②`core/game.gd::_execute` 的 `match p.kind`；③`core/game.gd::dispatch` 的 6 类特判
  （`event`／`departure`／`service`／`depart`／`surrender`／`prison`）。**合计 39 条 kind**。
- **逐域计数**：战斗／装备／道具 15；整备／休息／保留 9；商店服务 1；事件 1；监狱 1；路线 2；
  奖励 3；出发 1；遗物／魔瓶／状态／demo 6。
- **params 键的证据面**＝显示侧按 payload 字段取行的实际字段（上表第 5 条命令的命中），
  不是从生产者读法反推；凡显示侧按某字段取行，该字段就必须是指令 params 键。

#### 3.3.1 kind 全集与 params 键表（39 条）

「现状 payload 中的非提交字段」＝今日随行携带、但不构成指令提交身份；其中被执行分支消费的字段
（`after`）R2 须二选一（判定重算回填／保留为 params 但不作身份），同批在 R2 判据点名。

| kind | 域 | params 键（提交身份，只用稳定 ID） | 现状 payload 中的非提交字段 | 显示侧按字段取行的字段面 |
| --- | --- | --- | --- | --- |
| `card` | 战斗 | `uid`・`type`・`slot`・`target`・`free`・`mode`・`self_target`・`x`・`hand_uid` | `preview`・`after`（`mode=lower` 时被执行分支写回耐久）・`tool_bonus`・`replay`（内部复演，不提交） | `uid`／`free`／`target`／`slot`／`self_target`／`hand_uid`／`type` |
| `chain` | 战斗 | `action`（hit／stop／select_exhaust）・`type`・`target`・`slot`・`free`・`mode`・`selected_uid` | `preview`・`after`・`tool_bonus` | `action`／`type`／`target` |
| `attack` | 战斗 | `type`・`form`・`enemy`・`all`・`target`・`x`・`part`・`charge_action` | `hits`・`damage`・`damage_type`・`interrupt`・`fall`・`cooldown_turns`・`mana_attachment`・`witch_action` | `type`／`form`／`enemy`／`target`（`all`＝`enemy` 空） |
| `status_toggle` | 战斗 | `status`・`enabled`・`uid` | — | `status` |
| `posture` | 战斗 | `dest`・`wall` | `adjacent` | `dest`／`wall`／`adjacent` |
| `wall_move` | 战斗 | `direction` | `distance`・`after`（执行写 `state.wall_distance`） | `direction` |
| `manual` | 战斗 | `target` | `after`（执行写耐久） | `target` |
| `hook` | 战斗 | `target` | `after`（执行写耐久） | `target` |
| `end` | 战斗 | —（无键） | — | `kind` |
| `calm` | 战斗 | —（无键） | — | `kind` |
| `surrender` | 战斗 | —（无键） | — | 组名 `surrender` |
| `item_use` | 道具 | `item`・`target` | — | `item`／`target` |
| `item_install` | 道具 | `item`・`mount`・`operator` | — | `item`／`mount` |
| `item_retrieve` | 道具 | `item`・`mount`・`operator` | — | `item`／`mount` |
| `item_discard` | 道具 | `item` | — | `item` |
| `finish_prepare` | 整备 | —（无键） | — | `kind` |
| `finish_rest` | 整备 | —（无键） | — | `kind` |
| `finish_pack` | 整备 | —（无键） | — | `kind` |
| `retain` | 整备 | `uid` | — | `kind`／`uid` |
| `retain_skip` | 整备 | —（无键） | — | `kind` |
| `rest_rare` | 休息 | —（无键） | — | `kind` |
| `rest_card` | 休息 | `type` | — | `kind`／`type` |
| `rest_flask` | 休息 | —（无键） | — | `kind` |
| `rest_begin` | 休息 | —（无键） | — | `kind` |
| `service` | 商店服务 | `op`（take／refresh／release／remove／leave）・`index`・`target`・`uid`・`payment`（self／flask） | — | `op`／`index`／`target`／`uid`／`payment` |
| `event` | 事件 | `action`（choose／reward／leave）・`choice`・`type` | — | `action`／`choice`／`type` |
| `prison` | 监狱 | `action`（enter／inspect／accept／resume／resist／explore／vent_kick／vent_exit／key／door_exit／unlock）・`site`・`direction`・`steps`・`uid`・`type`・`target`・`slot`・`mode`・`free` | `wall_warning`；`temporary` 只在 `core/prison.gd::release_inspection` 的内部直调出现（非候选，不进 params） | `action`／`site`／`uid`／`target` |
| `depart` | 路线 | `room` | — | `room` |
| `travel_step` | 路线 | —（无键） | — | `kind` |
| `reward` | 奖励 | `category`・`type`・`reward_id` | — | `category`／`type`／`reward_id` |
| `reward_skip` | 奖励 | `category` | — | `category` |
| `relic_bundle` | 奖励 | `op`（claim／skip／copy／finish）・`index`・`uid`・`type` | — | `op`／`index` |
| `departure` | 出发 | `op`（choose／skip／card／finish）・`option`・`uid`・`type` | — | `op`／`option`／`uid`／`type` |
| `flask` | 魔瓶 | `op`（deposit／withdraw） | — | `op` |
| `relic_toggle` | 遗物 | `relic` | — | `relic` |
| `relic_discharge` | 遗物 | `relic` | — | `relic` |
| `relic_control_done` | 遗物 | —（无键） | — | `kind` |
| `demo_end` | demo | —（无键） | — | 组名 `demo_exit` |
| `demo_continue` | demo | —（无键） | — | 组名 `demo_exit` |

「显示侧按字段取行的字段面」＝今日 `ui/` 里 `actions.select／find／first_usable` 的实际字段集合
（R2 改为按指令形状取显示事实后，这些字段仍须能由显示点提供）。

#### 3.3.2 覆盖核对表：显示点 → kind（第 1 节 A1–A60 收敛面逐条落 kind）

| 显示点 | 现提交来源符号 | 落 kind（含子键） |
| --- | --- | --- |
| A1 | `ui/main.gd::_relic_row` | `relic_discharge`／`relic_toggle`（`relic`；现状先取 discharge 再回退 toggle） |
| A2 | `ui/main.gd::_status_control` | `status_toggle`（`status`） |
| A3 | `ui/main.gd::_basic_action_tile` | `attack`（战斗格）／`calm`（深呼吸格） |
| A4 | `ui/main.gd::_posture_controls` | `posture`（`dest`・`wall`） |
| A5 | `ui/main.gd::_bottom_controls` | `end`／`finish_prepare`／`finish_rest`／`finish_pack`（组 `flow`） |
| A6 | `ui/main.gd::_bottom_controls` | `surrender` |
| A7 | `ui/main.gd::_wall_controls` | `wall_move`（`direction=toward`） |
| A8 | `ui/main.gd::_equipment_tile` | `manual`（`target`） |
| A9 | `ui/main.gd::_action_row` | `retain`（`uid`）／`retain_skip` |
| A10 | `ui/main.gd::_action_row` | 通用行：按该调用点传入的行落 kind（链抽屉＝`chain`；另见 `flow`／`route`／`reward`／`service` 各点） |
| A11 | `ui/main.gd::_card_target` | `card`（`uid`・`slot`・`target`・`free`・`hand_uid`；提交时传选中时抓取的版本，保留陈旧版本拒绝） |
| A12 | `ui/main.gd::_prison_controls` | `prison`（`action=explore`・`site`／`direction`・`steps`） |
| A13 | `ui/main.gd::_prison_controls` | `prison`（其余 `action`：inspect／accept／resume／resist／vent_kick／vent_exit／key／door_exit／unlock） |
| A14 | `ui/main.gd::_compact_action` | 通用紧凑行：按调用点落 `item_use`／`item_install`／`item_retrieve`／`card`／`event`／`service`／`prison`／`demo_*` |
| A15 | `ui/main.gd::_route_screen` | `travel_step`（组 `route`） |
| A16 | `ui/main.gd::_select_route_room` | `depart`（`room`） |
| A17 | `ui/main.gd::_queue_map_step` | `travel_step` |
| A18 | `ui/main.gd::_show_drop_targets` | `card`（`card_uid`）／`attack`（`action_type`・`form`）／`prison`（`action=unlock`・`uid`）／`item_use`／`hook`（落点 `click_to_use`；版本取拖起时的 `data.version`） |
| A19 | `ui/main.gd::_activate_guard_bind_target` | `card`（`target=guard_bind`・`free`・`uid`） |
| A20 | `ui/main.gd::_receive_player_drop` | `posture`（现唯一 `self_action_id` 源＝`ui/main.gd::_posture_controls` 的拖放；R2 拖放改装配后按落点落 kind） |
| A21 | `ui/command_routes.gd::_card_intent` | `card`（`free=true`） |
| A22 | `ui/main.gd::_activate_card` | `card`（`hand_uid` 消耗选择） |
| A23 | `ui/main.gd::_activate_card` | `card`（快捷解除：`mode`∈`ui/target_queries.gd::RELEASE_MODES`・`target`） |
| A24 | `ui/main.gd::_activate_card` | `card`（唯一装备：`free`） |
| A25 | `ui/command_routes.gd::_card_intent` | `card`（`self_target=true`） |
| A26 | `ui/main.gd::_item_details` | `item_use`（`item`・`target`）／`item_install`（`mount`・`operator`）／`item_retrieve` |
| A27 | `ui/main.gd::_item_details` | `item_discard`（`item`） |
| A28 | `ui/deck_browser.gd::refresh` | `relic_bundle`（`op=copy`・`uid`・`type`；唯一带 choices 的调用点＝`ui/relic_bundle_screen.gd::build`） |
| A29 | `ui/departure_screen.gd::build` | `departure`（`op=card`） |
| A30 | `ui/departure_screen.gd::build` | `departure`（`op=choose`・`option`） |
| A31 | `ui/departure_screen.gd::build` | `departure`（`op=choose`／`card`／`skip`／`finish`，按 `core/departure.gd::panel` 的 `entries`） |
| A32 | `ui/event_screen.gd::action` | `event`（`action=choose`／`leave`） |
| A33 | `ui/event_screen.gd::drawer` | `event`（`action=reward`・`type`；提交传选中时的版本） |
| A34 | `ui/event_screen.gd::multi_restraint_selector` | `event`（`action=choose`・`choice`） |
| A35 | `ui/first_turn_presenter.gd::_step` | `posture`／`wall_move`／`attack`／`flask`／`end`／`relic_control_done`（`core/first_turn_control.gd::select` 实测 kind 过滤面；漏一条＝接管步骤不可提交） |
| A36 | `ui/keyboard_input.gd::handle` | `end`（组 `flow` 内 `kind`）／当前选中行（`card`／`attack` 等） |
| A37 | `ui/keyboard_input.gd::confirm` | `card`（`uid`・`free`）／`attack`（`type`・`form`） |
| A38 | `ui/keyboard_input.gd::_process` | `end`（长按结束回合） |
| A39 | `ui/mana_flask.gd::build` | `flask`（`op=deposit`／`withdraw`） |
| A40 | `ui/command_router.gd::emit` | 改道边：带 `hand_uid` 且非 `self_target` 的 `card` → `ui/command_routes.gd::_resolved_card`（仍落 `card`） |
| A41 | `ui/main.gd::_activate_card` | 同上（自身目标 `card`） |
| A42 | `ui/main.gd::_receive_player_drop` | 同上（拖放自身目标，仍落 `card`） |
| A43 | `ui/main.gd::_activate_card` | 改道边：自由面 `card` → `ui/command_routes.gd::_card_intent` |
| A44 | `ui/main.gd::_receive_player_drop` | 同上（拖放自由面） |
| A45 | `ui/main.gd::_activate_card` | `card`（快捷解除取行 `ui/quick_release_bar.gd::candidate`，kind 不变） |
| A46 | `ui/reward_screen.gd::build` | **无实例**：`extra_ids` 在 `core/game_view.gd`／`core/departure.gd::panel`／`core/relic_bundle.gd::panel` 实测恒空（见 3.3.3-1） |
| A47 | `ui/reward_screen.gd::build` | 继续按钮＝该面板 `continue_id`：`reward`（`type=skip`）／`rest_begin`／`service`（`op=leave`）／`event`（`action=reward`・`type=skip`）／`relic_bundle`（`op=finish`） |
| A48 | `ui/reward_screen.gd::row` | `reward`（`category`・`reward_id`）／`rest_card`／`rest_rare`／`rest_flask`／`service`（`op=take`・`index`） |
| A49 | `ui/reward_screen.gd::cards` | `reward`（`category=card`）／`event`（`action=reward`）／`service`（`op=take`） |
| A50 | `ui/reward_screen.gd::relics` | `reward`（`category=relic`） |
| A51 | `ui/reward_screen.gd::skip_button` | `reward_skip`（`category`） |
| A52 | `ui/relic_bundle_screen.gd::build` | `relic_bundle`（`op=finish`） |
| A53 | `ui/relic_bundle_screen.gd::build` | `relic_bundle`（`op=claim`・`index`） |
| A54 | `ui/relic_bundle_screen.gd::build` | `relic_bundle`（`op=skip`・`index`） |
| A55 | `ui/relic_bundle_screen.gd::build` | `relic_bundle`（`op=finish`） |
| A56 | `ui/shop_screen.gd::_ready` | `service`（`op=refresh`・`payment`） |
| A57 | `ui/shop_screen.gd::_ready` | `service`（`op=leave`） |
| A58 | `ui/shop_screen.gd::_card_offer` | `service`（`op=take`・`index`・`payment`） |
| A59 | `ui/shop_screen.gd::_offer` | `service`（`op=take`・`index`・`payment`） |
| A60 | `ui/shop_screen.gd::services` | `service`（`op=remove`・`uid`／`op=release`・`target`） |

**覆盖结论**：A1–A60 全部可落 kind，**无未归类显示点**；唯一空面是 A46（`extra_ids` 恒空，今日无实例）。
39 条 kind 全部有生产者与显示点来源；反之 39 条里没有只由测试或工具构造的 kind。

#### 3.3.3 存疑／口径差异项（逐条）

1. **A46 空面**：`extra_ids` 在三个面板构造点实测恒为 `[]`，故 A46「额外奖励按钮」今日无实例；
   保留为潜在入口时不新增 kind（沿用 `reward`／`service`／`event` 的继续面）。
2. **死 kind 名 `release`**：`ui/drag_targets.gd::targeted` 的 kind 白名单含 `"release"`，全仓无生产者
   （`rg '"kind":"release"'` 0 命中）；同一白名单另含 `"card_continue"`（仅 `core/action_copy.gd` 引用）。
   二者是历史名，不构成 kind；R2 随拖放改指令装配删除。
3. **转发计数口径**：精确复算＝`_candidate(` 79（含定义行）／`g._candidate(` 38；§1 C5／DUP5 已按精确数
   改写。早期宽松口径的「96 处」（含 `_candidate_detail`／`_candidate_base_detail` 与同行多次命中）
   不再出现在本契约，不得据此判定覆盖。
4. **同 kind 多分支不拆 kind**：`reward`（`category`×`type`＋`reward_id`）、`prison`（`action`）、
   `service`（`op`）、`departure`／`relic_bundle`／`flask`（`op`）、`chain`（`action`）均按 params 子键区分；
   分类转发表按 kind 收键（39 条），子键合法性由唯一判定与 `dispatch` 形状复核共同负责。
5. **`after` 系字段（`card`／`wall_move`／`manual`／`hook`）**：今日被执行分支消费（写回耐久或
   `state.wall_distance`、进日志文案）。**裁定（人类 2026-09-23 过目通过）**：由唯一判定随指令形状
   重算回填；`params` 只带稳定 ID 与玩家意图、不带 `after`；不得两侧各算一次（违反唯一判定）。
6. **接管面（A35）须在分类表内**：`core/first_turn_control.gd::select` 只从
   `posture`／`wall_move`／`attack`／`flask`／`end` 五类挑步骤，末步另加 `relic_control_done`；
   Gherkin 2 的 kind 枚举须含这六项。

#### 3.3.4 边界说明（不逐 kind 重复）

- **`expected_version` 由 UI 侧统一补**（现状语义，见 `ui/main.gd::_submit` 的
  `view.version if expected_version<0 else expected_version`）：默认取提交时的当前 `view.version`；
  选择类与拖放／键盘／接管路径在**选中或拖起时抓取**版本并在提交时传回，以保留「陈旧版本拒绝」
  （"状态已更新，请重新选择行动。"）的可见行为。指令形状只在顶层带一个 `expected_version`，
  不逐 kind 重复、不进 params。
- **kind 与 params 不含候选提交身份 id**：现 ``_candidate`（历史名，R5 已删除）` 的
  `row.id=JSON.stringify(payload).sha256_text().substr(0,24)` 随行载体删除（批 R5）；
  R2 起不存在按 id 取行复核（T4 改为指令形状＋参数合法性＋判定）。
- **表外 kind fail-closed**（Gherkin 2）：分类转发表（`ui/command_router.gd` 的 `ROUTES`，R2 落地）无该 kind 时拒绝并留一条
  记录，不静默放行、不崩。**本表是闭集**：新增 kind 必须先回填本节再实现。
- **显示点只提供稳定 ID**：params 键不得用译文、名称、颜色或图片；显示侧现用的 `label`／`detail`／
  `brief`／`reason`／`risk`／`cost`／`mana` 均不进 params（由唯一判定与显示事实给出）。

## 4 分批（每批独立完工・提交・回退；批间门禁绿；不得跨批开工）

不变量（**任何时刻**成立）：①每条边只有一条对应路径；②**同批立新边即删旧边**；③合法性感判定实现
始终只有一份（R1 起）；④UI 侧 `dispatch` 调用点始终唯一。后批被裁定否决时前批仍成立。

| 批 | 范围 | 该批判据 | 前置 |
| --- | --- | --- | --- |
| **R1** | 判定收口（行为零变化）：从 ``_candidate`（历史名，R5 已删除）` 抽出**唯一合法性判定**（工作名 eligibility，未落地）；`_candidate` 改为调它；接管阻断（现 `core/first_turn_control.gd::select` 写 `blocked.valid`／`blocked.reason`）改为判定内读接管状态返回同文案——销 DUP2 | Gherkin 4、6；行为与未改源码基线逐字段相等；「写 `valid`／`reason` 的位置只有判定一处」源文本断言 | 人审通过 |
| **R2** | 指令收口＋后端身份复核：落地指令形状、指令路由、分类子路由（新 UI 文件＝提案获批，或 Q1 选定落法）；A1–A60 收敛为 T1（同批删直连与改道链）；`core/game.gd::dispatch` 改收类型化指令，复核＝指令形状＋参数合法性＋判定（T4），**删除按 id 取行（B2）与提交身份 id**；拒绝文案逐字不变 | Gherkin 1、2、3、8；A／B 边表 `rg` 复算（直连 0 条、UI→dispatch 唯一） | R1；Q1 裁定；§3.3 清单经人类过目（Q5 裁定） |
| **R3** | 显示改线・手牌／行动／姿态／墙面／底栏域：这些显示点改读判定显示事实（T5／T9），同批删这些点的行读边（D13 对应行）；`ui/main.gd::detail_of`／`card_entry` 不动。**已落地**：事实来源＝`core/game.gd::_fact`／`core/game.gd::display_fact`（行与显示事实共用同一事实与同一判定），投影键＝`view.display_facts`（G6 的显式 mask），显示键＝`core/game.gd::shape_key` | Gherkin 5、6（该域显示文本逐字相等）——G5 落 `tests/display_ui_cases.gd::display_facts_match_determination`（display 分类的手牌／行动／姿态／墙面／底栏） | R2 |
| **R4** | 显示改线・装备／快捷解除／拖放／道具域：`ui/target_queries.gd` 行筛选面改指令装配（并入分类子路由），纯显示查询保留；同批删对应行读边（D9／D10 对应行）；DUP4 收敛（保留首／末项回退各自可见行为）。**已落地**：事实来源＝`core/game.gd::manual_facts`／`hook_facts`／`item_facts`／`retain_facts`、`core/card_effects.gd::chain_display_facts`、`core/consumables.gd::use_facts`；读取＝`ui/target_queries.gd` 的显示事实筛选；接合＝`ui/target_queries.gd::fact_key`；DUP4＝`ui/target_queries.gd::first_usable` | Gherkin 5、6（该域）＋拖放／快捷解除真实输入例——G5 落 `tests/display_ui_cases.gd::r4_display_facts_match_determination`（display／targeting／body_layout）；真实指针落 `tests/target_sidebar_ui_cases.gd::r4_pointer_paths` | R3 |
| **R5** | 显示改线・服务／事件／监狱／路线／奖励／出发域＋**行载体删除**：各生产者改投影显示事实构建；删除 ``candidates`（历史名，R5 已删除）`／`_candidate`／`_build_candidates`／`_phase_candidates` 与 行动行索引文件（`action_index.gd`，R5 已删除）（销 DUP3／DUP5）；`view.candidates` 键删除 **已落地**：事实源＝`core/game.gd::command_facts`（原始事实＝`core/game.gd::_fact_source`）；投影＝`core/game.gd::display_fact`（含显示点身份 `key`）；提交复核＝`core/game.gd::command_fact`；接管步骤选择＝`core/first_turn_control.gd::select`；显示域读取＝`ui/target_queries.gd::facts` 与 `ui/main.gd` 节函数 | Gherkin 5、6、7、9；终态断言全绿（`removal_end_state`）；基线等价（`behavior_baseline_equivalence` 的 `R5_VIEW_MASK`／`R5_RECORD_MASK`／`R5_RECORD_ADDED`／`R5_RECOMPUTED` 显式声明） | R4 |

- 敏感性证明（每批判据各一次**实际运行**取证）：把该批实现点换回旧路径（或去掉该批机制），该批具名 check
  必须变红；随后还原。未做敏感性证明＝该批未完成。
- 终态义务（R5 同批）：本契约第 1 节对**已删符号**的 `文件::符号` 锚点与路径提及，同批改写为纯文本历史名
  （否则 `tools/check-docs.ps1` 变红）；波及清单（第 10 节）的现行契约段落按人类批准统一改写。

## 5 验收合同（Gherkin：具名 check＋落点分类）

落点写测试分类名（套件注册：`tests/test_game.gd` 的 `SUITES`、`tests/ui_smoke.gd` 的 `UI_MODULES`）；
计数只用测试侧包装（经 `ui/main.gd::game_factory` 注入计数子类，生产源码不带计数器／计时钩子）；
测试断言消息用英文并写明域；复用既有夹具与真实输入助手。

1. `instruction_router_single_entry`（`architecture`＋源文本断言，`tests/architecture_cases.gd`）
   - Given 现行代码全量扫描 `ui/`
   - When 核对提交通道
   - Then 控件回调只调指令路由的 `emit`，不存在直连提交执行段的提交类回调（A1–A60 形态的路径 0 条）；
     UI 侧 `dispatch` 调用点唯一；自动接管与键盘仍经同一入口（takeover 参数语义不变）
2. `instruction_route_table_is_total`（`architecture`）
   - Given 分类转发表 `ROUTES`
   - When 枚举全部可提交 `kind`（覆盖优先：含战斗／整备／休息／商店／事件／监狱／路线／奖励／出发／demo）
   - Then 每个 `kind` 恰有一条子路由（多一条少一条即红）；伪造未知 `kind` 的指令被 fail-closed 拒绝
     且留一条记录，不静默放行、不崩
3. `submit_reject_semantics_unchanged`（`display`＋`persistence`，真实输入）
   - Given 真实窗口与 44 件战斗夹具
   - When 分别提交：陈旧 `expected_version`、当前状态不可提交的指令形状、判定不通过（`valid=false`）、
     五预检各一例失败
   - Then 五类拒绝文案与改动前逐字相同（"状态已更新，请重新选择行动。"／"该行动已经失效，请重新选择。"／
     判定 `reason` 原文／各预检 `error`）；失败后 `export_snapshot()` 相等（全回滚、无部分付款／部分装备）；
     存档写入仍只发生在 `ok` 且 `checkpoint` 非空；`tests/ui_smoke.gd` 的 `_index_boundary_tests` 四条不删不改
4. `single_eligibility_implementation`（`architecture`＋源文本断言）
   - Given 现行代码
   - When 扫描 `core/` 与 `ui/` 中对 `valid`／`reason` 的写点
   - Then 写点只有唯一判定一处（接管阻断在判定内返回同文案）；`ui/` 无第二判定实现；显示不可用文本
     等于判定 `reason` 原文（不改写、不拼接）
5. `display_facts_match_determination`（`display`／`targeting`／`body_layout`；R3 落地 `tests/display_ui_cases.gd::display_facts_match_determination`，夹具矩阵 0／12／26／44 件 × 战斗／整备／休息＋未改源码基线；R4 落地 `tests/display_ui_cases.gd::r4_display_facts_match_determination`，同矩阵再加商店／事件／监狱，由 display／targeting／body_layout 三分类调用）
   - Given 夹具矩阵（0／12／26／44 件 × 战斗／整备／休息／商店／事件／监狱，同种子）
   - When 逐显示点读取显示事实（手牌 availability、装备／快捷解除可用与原因、道具 target_groups／
     unavailable_reasons、行动／姿态／墙面／底栏按钮、路线／奖励／服务／事件／监狱条目）
   - Then 每个显示点的可用／原因／风险／费用与唯一判定对同一指令形状的输出逐字段相等；
     与未改源码基线的对应显示文本逐字相等
6. `behavior_baseline_equivalence`（`architecture`）
   - Given 切片开始时用未改源码复算记录的基线（`get_view()` 显示字段、提交结果字典、拒绝文案、
     `export_snapshot()`、随机域计数；含完整 JSON，判定用逐字段比对＋首个差异路径）
   - When 各批完成后在同一夹具矩阵重算
   - Then 逐字段相等；删除键集合恰好等于显式声明的 mask（候选行／`view.candidates`／提交身份 id），
     多一个少一个即红；不一致以复算值为准并记录，不得改基线迁就实现
7. `removal_end_state`（`architecture`＋源文本断言）
   - Given R5 完成后的代码
   - When 全仓扫描
   - Then `candidates`／`_candidate`／`_build_candidates`／`_phase_candidates` 四个符号与
     行动行索引文件（`action_index.gd`，R5 已删除） 文件**不存在**；不存在按提交身份 id 的取行复核；不存在第二份合法性判定
8. `takeover_path_unchanged`（`display`）
   - Given 装备豆包遗物的战斗首回合
   - When 走真实接管演示并尝试手动输入
   - Then 只有已选步骤可提交（其余显示"豆包接管中"文案不变）；手动输入被接管锁阻挡；
     换局／返回首页后旧步骤不提交；`control_next` 仍只在事务内消费、失败回滚
9. `save_and_random_untouched`（`persistence`，`tests/persistence_cases.gd`）
   - Given 任一夹具
   - When 走完显示读取路径与一次成功／一次失败提交
   - Then 纯读取前后 `export_snapshot()` 相等；随机域计数不变；`core/snapshot.gd::REVISION` 不变；
     不新增存档字段；固定点写盘时机与现状一致

## 6 验收流程（validator：真人 UI 操作口径）

给验收者的合同：真实窗口、真实指针／键盘／触屏按序操作，**不得**直接调用符号、不得改夹具绕过 UI。
每步核对「可见结果」列；任一步不符即失败并记录步号。全程与改动前截图／文本对照（同种子）。

| 步 | 操作（真人路径） | 可见结果（判据） |
| --- | --- | --- |
| V1 | 新局进入战斗：点手牌选牌→点敌人提交；点不可用牌 | 可用牌可点、不可用牌显示原因原文；提交后面板即时刷新；不可用原因与第 5 节显示事实一致 |
| V2 | 拖一张解除牌到身体栏装备、拖到捕缚条、拖到自身、拖到空处 | 各落点可用性高亮与原因正确；成功即提交一次；错牌面／旧版本拒绝且 notice 可见（触屏同桌面可见） |
| V3 | 快捷挣脱栏：选区域→用牌；左右箭头循环；右键切小部位；一键解除 | 格内显示真实耐久／紧度／锁与不可用原因；提交走同一入口；不改投别件 |
| V4 | 姿态／墙面／底栏：深呼吸、移动、结束回合、（可投降时）投降 | 各按钮状态与原因正确；结束回合推进敌方；拒绝文案逐字同改动前 |
| V5 | 道具：道具抽屉用一件道具／丢弃；商店买一件服务／去一张卡 | 目标分组与不可用原因正确；交易成功扣费、失败全退 |
| V6 | 事件选一项、奖励三选一、休息选牌、出发选牌、路线移动一格、监狱巡视与开锁 | 各屏条目可用性／风险显示正确；提交后进入正确阶段 |
| V7 | 翻面手牌、开关身体栏、切抽屉、开行动日志、开图鉴 | 纯显示操作零提交、零写盘、零随机消耗（对比主档 mtime 与状态导出） |
| V8 | 固定点核对：打完一场（写盘）、整备结束（写盘）、同层换房（不写）、深层层口（写盘）、塔图画一笔（写盘） | 主档写盘时机与现状一致；主页"继续"回正确起点 |
| V9 | 读档、新局、快速 SL 各一次 | 世界替换正常、首屏显示完整、后续提交正常 |
| V10 | 装豆包遗物打一场首回合；期间尝试手动输入；中途返回首页再进 | 自动接管演示完整、台词与步骤同改动前；手动输入被挡；旧步骤不提交 |
| V11 | 键盘全流程（选牌／选目标／确认／取消／长按结束回合）与触屏抽样各一遍 | 输入语义与键位不变；拒绝提示触屏可见 |

- 判据形式：每步的布尔结果映射到第 5 节具名 check（V1→5、V2/V3→3/5、V4→3、V5/V6→5、V7→9、
  V8→9、V9→6/9、V10→8、V11→3）；操作全部真实输入。
- 测量（只报告，不作判据）：同机同窗口 2 热身＋15 有效配对，报逐对比值中位与两侧独立中位；
  毫秒不得写成完成判据或提速宣称（P5）。

## 7 Definition of done

全部满足才算完成（缺一即未完成，见第 8 节）：

1. **批次**：R1–R5 每批独立完工、独立提交、独立回退；批间门禁绿；每批做完敏感性证明一次实测取证。
2. **Gherkin**：第 5 节 9 条具名 check 全部通过（真实输入、真实夹具矩阵）。
3. **验收流程**：第 6 节 V1–V11 全部通过（真实窗口真人路径）。
4. **终态断言**：`candidates`／`_candidate`／`_build_candidates`／`_phase_candidates`／行动行索引文件（`action_index.gd`，R5 已删除）
   不存在；写 `valid`／`reason` 只有唯一判定一处；UI 侧 `dispatch` 调用点唯一；无按提交身份 id 取行复核。
5. **命令**（在 `spire-godot/` 下执行；判读＝退出码 0、每个分类 `SUITE RESULT: PASS`、
   `PASS: N assertions`、`summary.json` 的 `status=passed` 且 `before==after` 指纹
   （`source_changed` 不算通过）、引擎错误日志 0 行）：

```powershell
& tools/check.ps1 -Suite architecture,persistence -Impact -TimeoutSeconds 1200
& tools/check.ps1 -UIOnly -UISuite all -KeepGoing -TimeoutSeconds 3600
& tools/check.ps1 -Suite runner -VerifyRunner
& tools/check-docs.ps1
```

- 窗口门禁取**全量分类**（`-UISuite all`）：本片显示改线逐文件触及绝大多数窗口分类（含
  `basic_attacks`／`services`／`route`／`events`——R5 补正的解析错与运行时 `Invalid access` 正落在这些
  分类），点名子集会让未点名的迁移面无人复算。`-KeepGoing` 只用于一轮内取全逐分类结果，
  末轮判读仍是「每个分类 `SUITE RESULT: PASS`」。

6. **独立审查**：实现完成后由独立子代理（新会话）按本契约边界审查通过；实现者不自审。
7. **记录**：`docs/record/changelog.md`、`docs/record/verification.md` 各按「日期＋域＋命令＋结果＋未跑项」
   登记（由协调者指派写入；本文件不写执行结果）。
8. **契约同步**：第 10 节波及清单的段落按人类批准统一改写完成；`tools/check-docs.ps1` 允许清单
   **零新增**（随删除自然消掉的 `core/candidate_deps.gd`／`ui/candidate_delta.gd`／`tools/candidate-deps.ps1`
   三条会出现「已无人引用」DOC NOTE——属预期，删条目是 `tools/` 改动，只点名不动手）。

## 8 算未完成（任一成立即未完成）

- 五个移除对象（`candidates`／`_candidate`／`_build_candidates`／`_phase_candidates`／行动行索引文件（`action_index.gd`，R5 已删除））
  仍存在；或存在按提交身份 id 的取行复核。
- 出现**第二份合法性判定**（任何地方重算 `valid`／`reason`，含 UI 侧合成资格结论、按名称／译文／颜色反查规则）。
- UI 侧 `dispatch` 调用点不唯一；或存在绕过指令路由的第二提交入口（测试直调 `dispatch`／`ui/main.gd::game_factory`
  注入除外）。
- 指令分类表外的 `kind` 被静默放行；或同一条语义出现第二条实现路径（第 2.3 节 DUP1–DUP6 任一未销项）。
- 任一批次内新旧边并存（同批立新边未删旧边）；或跨批开工。
- 拒绝文案、显示原因文本、数值、可见文案有任何字面变化；输入语义／键位变化；立绘与动画体系变化。
- 失败回滚不完整（部分付款／部分装备残留）；`version` 递增不再是成功一次；`core/snapshot.gd::REVISION`
  变化；新增存档字段；随机域语义变化。
- 装备只读查询接缝内部（`docs/spec/equipment-query-seam.md` 的 ①–⑤）被改动；实现了 `escape_preview` 按需化。
- 用毫秒数、"应该更快"、单次采样作完成判据或提速宣称；只报调用次数不报工作量。
- 任一必跑分类未执行／失败／无授权跳过而被记为通过；敏感性证明未做实测；不同提交的结果拼接。
- 生产源码留下计数器／计时钩子；`tools/check-docs.ps1` 允许清单新增条目；把「未裁定」写成「已通过」；
  旧案（F1–F9／W1–W5／B1–B4／H1–H5／C0–C4）被写成已通过或被当作现行约束复活。

## 9 假设与待裁定点

### 9.1 优先假设核对结果（源码实测，P1–P5）

| 假设 | 核对结果 |
| --- | --- |
| P1 移除对象＝行表＋提交身份 id＋行索引；判定不消失 | **成立**：C 组（物化）／B2＋C7（身份 id）／D8–D10（行索引与行筛选）实测存在；判定逻辑在 `_candidate` 内（valid／reason／risk／mana_payment），抽为唯一判定后保留 |
| P2 显示侧与提交侧同判定、两条调用边不算第二判定 | **成立（写入第 2.1 节）**：现状两侧本就共用 `_candidate` 的结论（经行载体）；目标态＝T4／T5 两条调用边一个实现 |
| P3 新提交语义＝类型化指令＋`expected_version`；失败全回滚不动 | **成立**：`dispatch` 现签名即 `(candidate_id, expected_version)`＋事务副本全回滚（B7 实测）；改形状不触回滚不变量 |
| P4「路由」术语冲突 | **成立**：`docs/spec/response-pipeline.md`「术语与增量方向」段与人类用词冲突，另有 `docs/spec/ondemand-copy.md`「文案路由」第三义；消歧见 3.2 |
| P5 毫秒只作报告项 | **成立**：与现行测量纪律一致，写入第 6 节测量口径 |

### 9.2 needs-human-review 理由（why flagged）

- 新增模块与新文件：指令路由／分类子路由（新 UI 文件提案，触 `docs/spec/response-pipeline.md` 的
  「默认不新增 UI 文件，先向协调者提案」授权边界）。
- 新增允许的依赖边超出微调：UI 指令层整层重排（A 组 45 条边收敛）。
- 计划复杂、跨 5 批：`ui/main.gd`、`core/game.gd` 大改；显示改线与投影契约三份（response-pipeline／
  release-interface／ondemand-copy）交叉。
- 不能诚实地说 Gherkin＋验收流程就是全部契约：还依赖第 10 节波及清单的人类批准与 Q1–Q4 裁定。

### 9.3 待人类裁定点

| 编号 | 待裁 | 说明 |
| --- | --- | --- |
| Q1 | 指令路由／子路由的落法 | 新增两个 UI 文件（推荐）vs `ui/main.gd` 内立段；新文件须过提案 |
| Q2 | 术语消歧 | 「指令路由／子路由」＋测试侧改称「套件选择」（3.2 表）是否照准 |
| Q3 | H1 处置建议 | 旧 H1（equipment-query-seam 两症结违反其自身遍历禁令＋`escape_preview` 按需化未排期）**建议保持另案**：本片非目标不触接缝内部，受限级判据不进本片；请协调者另立裁定，不在本片复活旧编号体系 |
| Q4 | `ui/main.gd::_submit` 去留 | `docs/spec/response-pipeline.md` 把 host 成员名 `_submit` 冻结在键盘／接管契约里；改造为路由执行段（保留名字，推荐）vs 改名（须同批改写该契约冻结行） |
| Q5 | 指令 `params` 键表定稿权 | **已裁定（2026-09-23）**：先出 kind 全集与键表清单供人类过目，再批 R2 实现；清单落 §3.3；**人类已于 2026-09-23 过目通过**（39 kind、A1–A60 全覆盖；⑤`after` 系字段＝判定随形状重算回填），R2 前置「§3.3 过目」已满足 |
| Q6 | View 键变化波及 | `view.candidates` 等键删除对 `docs/spec/release-interface.md`／`ondemand-copy.md` 的改写口径（见第 10 节）是否照准 |

### 9.4 可能爆雷的假设（A）

- **A1（最可能爆）：显示点 ↔ 指令形状映射的覆盖枚举。** 行表删除后每个可交互显示点都要有对应指令形状与
  显示事实来源；漏一处＝按钮消失或不可点（正确性问题）。缓解：覆盖优先（kind 全集清单先行）、
  Gherkin 5／6 的夹具矩阵＋基线逐字段兜底、V1–V11 真人路径抽查。
- **A2（行为保持）**：接管阻断并入判定后文案"豆包接管中"与不可提交语义必须逐字保持（Gherkin 8）。
- **A3（入口断言漂移）**：`get_view` 调用点白名单（`_resume_snapshot`／`render` 空快照／`_submit`／`restart`）
  在 R2 改造 `_submit` 时不得变化；变化须先改 `docs/spec/response-pipeline.md` 接缝 A（第 10 节）。
- **A4（输入原件缺失）**：交接文件（原点名路径）在本机不存在，本计划未消费它；若其中含本片所需证据索引，
  协调者补读后须复核本计划假设。
- **A5（旧案误用）**：本片取代的三片里未落地的设计（display_rows、get_view_scoped、candidate_deps 等）
  **不得**被实现者顺手复活；一切以本契约 T 图为准。

## 10 契约波及清单（只点名、不动手；交协调者走人类批准后统一同步）

实现期须改写的现行契约段落与规则行。本片规划**不改**它们；由协调者汇总送人类批准后统一同步。
落点由 `rg` 复算（2026-09-23），改写要点＝以本契约 T 图／3.2 术语消歧／1.6 差异为准。

| # | 文件 | 点名段落／行 | 改写要点 |
| --- | --- | --- | --- |
| 1 | `docs/spec/response-pipeline.md` | 接缝 A 表：`game.dispatch(candidate_id, expected_version)` 行、`ActionIndex` 行、`TargetQueries` 行、三个按需只读入口段 | 提交语义改「类型化指令＋expected_version」；行索引行删除；`candidate_detail` 输入改指令形状 |
| 2 | `docs/spec/response-pipeline.md` | 「术语与增量方向」段 | 按 3.2 消歧：测试侧称「套件选择」，指令侧称「指令收口／分发」 |
| 3 | `docs/spec/response-pipeline.md` | 「失败语义」段：dispatch 拒绝顺序句、锁定断言行 | 拒绝顺序按 1.6 D-1 以源码为准；锁定断言④「ui.actions 已按新状态重建」随行索引删除改等价显示事实断言（**不放松**，须人批） |
| 4 | `docs/spec/response-pipeline.md` | 「输入域」段：`candidate_id` 来自当前 View、`commit` 的 `c` 为候选字典、选择类／提交类清单 | 指令形状口径（kind＋params）；清单改「指令来源」 |
| 5 | `docs/spec/response-pipeline.md` | 「未排期方向」段：「候选 ID 是 `payload` 的哈希」句 | 提交身份已改形状＋参数合法性复核，整句改写 |
| 6 | `docs/spec/release-interface.md` | 域节排除句；共享目标查询方法语义（"优先可用候选"、"火球沿原候选"、"原候选的可用性、具体阻止原因和风险保持权威"）；只读投影（"从正式候选投影"）；场景结构图节点「原有候选及版本提交入口」；输入域「提交一律走**候选 ID ＋ 版本复核**的正式入口」；失败语义末条 | 「候选」措辞改「指令／判定显示事实」；提交入口改指令路由口径 |
| 7 | `docs/spec/ondemand-copy.md` | 三个只读入口表 `Game.candidate_detail(candidate)` 行；陈旧输入条；「按需的候选详情」节（组范围、写路径不读 detail、"候选 ID = `JSON.stringify(payload)` 不变"句） | 输入改类型化指令；id 句删除；其余按需语义不动 |
| 8 | `docs/spec/transition-pipeline.md` | 证据入口「取候选 → `dispatch`」措辞 | 改「发指令 → `dispatch`」 |
| 9 | `docs/spec/save-fixed-points.md` | 证据入口「取候选 → `dispatch`」措辞 | 同上 |
| 10 | `docs/spec/event-pipeline.md` | 事件系统结构表「候选／界面／提交复核」三行（`Events.candidates` → `Game._candidate`、`ActionIndex`／原候选 ID、"重生成候选、确认 valid"） | 改显示事实构建／唯一判定复核口径 |
| 11 | `docs/spec/equipment-query-seam.md` | 域节「候选资格与候选 ID」排除句；作用域协议「`candidates()` 与 `get_view()` 的现有进出保持不变」；oracle 基线句与场景 1 断言（`candidates()` 基线）；算未完成「候选资格」句 | `candidates()` 消失后改判定／显示事实口径；**接缝 ①–⑤ 内部一行不改** |
| 12 | 根 `AGENTS.md` | 禁区行「不绕过正式候选修正界面结果。」（下句「不由组件直接修改资源、装备或回合。」去留由人裁定） | 改「不绕过指令路由与唯一判定修正界面结果」口径 |
| 13 | `.zcode/skills/spire-architecture/SKILL.md` | 描述行「候选与索引」；规则行「提交必须复核候选身份与状态版本。」「UI 提交已有候选 ID＋版本，action_index 只查找、不重算资格。」「ui/target_queries.gd …只吃 View 与 ActionIndex…」行 | 改「指令路由／唯一判定」口径；「身份」＝指令形状＋参数合法性 |
| 14 | `docs/spec/candidate-removal.md`（本文件） | 第 1 节已删符号的锚点与路径提及 | R5 同批改写为纯文本历史名（终态义务，见第 4 节） |
