# 候选层移除与指令路由契约（candidate-removal）

本文件是现行契约：指令路由与唯一判定的落地形态。候选层（行表、提交身份 id、行动行索引）已移除，
现行通道＝前端指令 → `ui/command_router.gd::emit` → 分类子路由 → core 唯一提交入口 `core/game.gd::dispatch`。
迁移过程与已作废的旧案（F/W/B/H/C 编号）见 `docs/history/`，不再是现行要求。
本文件不写执行结果；通过／失败／未执行只登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。引用代码不写行号，用函数名与符号锚点；
未落地符号只写纯文本名并注明「未落地」，不写成 `文件::符号` 锚点。

## 域

- 收束对象：前端指令汇集、分类分发、指令形状与参数键面、唯一合法性判定、后端唯一提交入口与投影取事实。
- 不含：规则数值与候选资格语义本身、存档与随机、`ui/main.gd` 的展示编排（见 `docs/spec/response-pipeline.md`）。
- 明文口径：提交身份＝指令形状（`kind`＋`params`）＋`expected_version`；`kind` 与 `params` 只用稳定 ID，
  不含候选提交身份 id；任何地方重算 `valid`／`reason` 的第二份判定实现都算未完成。

## 接口

| 节点 | 符号 | 语义 |
| --- | --- | --- |
| 指令路由 | `ui/command_router.gd::emit`／`ui/command_router.gd::ROUTES` | 前端唯一指令入口；按 `kind` 查声明表分发；表外 kind fail-closed（拒绝并留一条记录，不静默、不崩） |
| 分类子路由 | `ui/command_routes.gd` | 每类指令恰一条装配子路由；把 UI 意图装成类型化指令，不判定资格、不 preload core |
| 类型化指令 | `core/game.gd::command_params`／`core/game.gd::command` | 数据形状 `{kind, params, expected_version}`；`params` 键面＝`core/game.gd::COMMAND_KEYS`（唯一投影，同一形状 → 同一 params） |
| 唯一合法性判定 | `core/game.gd::command_fact`／`core/game.gd::command_facts`／`core/game.gd::display_fact` | 形状 ＋ 当前状态 → 投影事实；提交侧与显示侧同一实现的两条调用边 |
| 提交入口 | `core/game.gd::dispatch` | 事务副本、失败全回滚、成功 `version` 一次自增；只有 UI 侧 `ui/main.gd::_submit` 一个调用点 |
| 投影 | `core/game.gd::get_view` → `core/game_view.gd::build` | 按显示点取显示事实（`core/game.gd::shape_key` 为显示点身份）；不再物化行表、不再有候选身份 id |
| 显示消费 | `ui/target_queries.gd::facts`／`ui/target_queries.gd::fact_key`／`ui/target_queries.gd::first_usable` | 按显示点读事实；不可用文本＝判定 `reason` 原文；首／末项回退按 `fallback` 显式声明 |

落地邻接（每节点一条对应路径，取代旧 A1–A60 直连与 B2 按 id 取行）：

| 边 | 路径 | 类型 |
| --- | --- | --- |
| T1 | 各 UI 指令来源 → 指令路由 | 唯一前端指令入口 |
| T2 | 指令路由 → 分类子路由 | 唯一分类点（`ROUTES`；表外拒绝） |
| T3 | 分类子路由 → `core/game.gd::dispatch` | 唯一后端提交边（UI 侧 dispatch 调用点唯一） |
| T4 | `core/game.gd::dispatch` → 唯一判定 | 提交侧强制复核（形状＋参数合法性＋判定） |
| T5 | `core/game_view.gd::build` → 唯一判定 | 显示侧取可用／原因／风险／费用 |
| T6 | 显示路径 → `core/game.gd::candidate_detail`／`core/game.gd::live_card_text`（经 `ui/main.gd::detail_of`／`ui/main.gd::card_entry`） | 文案按需现算 |
| T7 | `core/game.gd::dispatch` → 执行与事务 | 现状不变（事务副本、全回滚、version 一次自增） |
| T8 | 投影 → `view.display_facts` | 每显示点 `{可用, reason, risk, cost, …}`；不含候选行与提交身份 id |
| T9 | 显示消费 ← `view` 显示事实 | 节函数按显示点读事实上屏 |
| T10 | 持久化与世界替换（`ui/main.gd::_save_progress`／`_resume_snapshot`／`restart`／`_quick_sl`） | 现状不变 |

判据真源（散文不复述）：kind 全集与 params 键面＝`tests/architecture_cases.gd::COMMAND_KEY_SETS`（与
`core/game.gd::COMMAND_KEYS` 逐条相等）；分类表全量＝`tests/architecture_cases.gd::instruction_route_table_is_total`；
提交入口唯一＝`tests/architecture_cases.gd::instruction_router_single_entry`；唯一判定＝
`tests/architecture_cases.gd::single_eligibility_implementation`；终态断言＝
`tests/architecture_cases.gd::removal_end_state`；行为基线＝`tests/architecture_cases.gd::behavior_baseline_equivalence`；
查找边机读表＝`tests/architecture_cases.gd::PIPELINE_LOOKUP_EDGES`（入口
`tests/architecture_cases.gd::pipeline_lookup_inspect`）；get_view 调用点白名单＝
`tests/architecture_cases.gd::get_view_call_sites_are_pinned`；显示改线＝
`tests/display_ui_cases.gd::r3_display_points_do_not_read_rows`／
`tests/display_ui_cases.gd::r4_display_points_do_not_read_rows`／
`tests/display_ui_cases.gd::r5_display_facts_match_determination`。

## 输入域

- `kind` 必须是声明表已声明的键；`params` 只用稳定 ID（type／uid／slot／target／item／enemy／mode…），
  不得用译文、名称、颜色或图片；`params` 不携带候选提交身份 id。
- `expected_version` 由 UI 侧统一补：默认取提交时的当前 `view.version`；选择类与拖放／键盘／接管路径在
  **选中或拖起时抓取**并在提交时传回，保留「陈旧版本拒绝」的可见行为。
- 分类转发表是**闭集**：新增 kind 必须先回填 `core/game.gd::COMMAND_KEYS`（及 `tests/architecture_cases.gd::COMMAND_KEY_SETS`）
  与 `ui/command_router.gd::ROUTES` 的对应子路由，再实现。
- 显示侧现用的 `label`／`detail`／`brief`／`reason`／`risk`／`cost`／`mana` 均不进 `params`（由唯一判定与显示事实给出）。

## 失败语义

- 拒绝文案逐字不变：版本不符 → 「状态已更新，请重新选择行动。」；未声明 kind／形状或键面不合法／形状在当前状态
  没有对应行动 → 「该行动已经失效，请重新选择。」；形状合法但判定不通过（`valid=false`）→ 判定的 `reason` 原文。
- 预检顺序：`Consumables.validate_buffs`、`Binding.state_issue` 在版本比对**之前**；
  `SpecialEquipment.validate`、`Cards.validate`、`RelicEffects.validate` 在**之后**，各自返回自己的 `error`。
- 事务：任一 issue → `state=original` 全回滚，不留部分付款／部分装备；`version` 只在成功提交时自增一次。
- 禁止：把写入退化为「注释式清单」（表里写了 kind、代码仍各写各的）；给 `get_view` 加显示需求参数；UI 预判资格或自行推断作废范围；
  为凑绿删弱既有断言；把旧案（F1–F9／W1–W5／B1–B4／H1–H5／C0–C4）当作现行约束复活。

## 证据入口

- 规则侧：`& tools/check.ps1 -Suite architecture,persistence -Impact -TimeoutSeconds 1200`。
- 窗口侧：`& tools/check.ps1 -UIOnly -UISuite all -KeepGoing -TimeoutSeconds 3600`。
- 判读（退出码、`SUITE RESULT`、`status=passed` 且 `before==after`、引擎错误 0 行）与登记口径见
  `skills/repo-ops/SKILL.md` 与 `docs/record/verification.md`；未跑项不得写成通过。
