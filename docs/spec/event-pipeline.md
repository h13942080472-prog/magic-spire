# 事件管线（定义形态 → 单求值入口 → 事件链）

契约文件：冻结事件的定义形态（内容包 schema）、单求值入口、节点与事件链模型、存档表示与依赖规范。
内部实现以代码为准，接口语义以本文件为准；函数名与稳定 ID（`kind`／`type`／`id`）是锚点，
本文件不写行号。本文件不写执行结果：通过／失败／未执行与红集登记 `docs/record/verification.md`。
迁移过程与当时的任务范围见 `docs/history/`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、
`tools/`、`build/`、`content/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

| 范围 | 文件 |
| --- | --- |
| 事件定义、生成、求值、执行、投影、校验 | `core/room_events.gd` |
| 内容编译与校验 | `core/content_catalog.gd` |
| 事件进度与选项存档校验 | `core/snapshot.gd`（事件段） |
| 外部内容 | `content/packs/*.json`、`content/templates/event*.json*` |
| 判据宿主 | `tests/{event_cases,event_flow_cases,event_ui_cases,event_draw_cases,content_cases,persistence_cases,architecture_cases,localization_cases}.gd` |

- 事件投影经 `Events.view` → `GameView.build` → `get_view().room_event`；诊断 trace 不进入玩家投影。
- 状态提交与迁移分别遵循 `docs/spec/response-pipeline.md`、`docs/spec/transition-pipeline.md`。
- 存档兼容范围由 `Snapshot.REVISION` 与 `docs/spec/save-fixed-points.md` 决定；本文件的冻结形态要求
  不构成对任意旧版存档的迁移承诺。

## 运行结构（现行；每一阶段只有一个决策者）

| 阶段 | 决策者／入口 | 职责 |
| --- | --- | --- |
| 进入房间 | `Game._arrive_room` | 按房间 `kind` 进入事件、商店、宝箱或战斗；事件调用 `Events.start` |
| 内容加载与校验 | `ContentCatalog`（`_definition`／`_references`） | 扫描 JSON、解析 `kind/id/schema_version`、编译入注册表；单一形态校验与引用解析 |
| 事件实例化 | `Events.start` | 选择事件 id、标记 `event_seen`、建立 `state.room_event`、进入起始节点 |
| 节点推进 | `Events.enter_node`（唯一节点管线） | 读节点声明的全部策略，逐作者选项调 `evaluate_option`，把冻结结果写入 `state.room_event.options` |
| 求值 | `Events.evaluate_option`（唯一入口） | 记 `decision` 与逐条 `gates`；只读（唯一写状态的分支是到达时的冻结结果落地） |
| 候选与显示事实 | `Events.candidates` → 唯一判定 | 由冻结选项生成显示事实；被丢弃的选项不出现 |
| 只读投影 | `Events.view` → `GameView.build` | 输出事件名、intro、stage、report、result_status 与 selector 的分组身份；不输出隐藏原因 |
| 界面 | `ui/event_screen.gd` | 只消费 `view.room_event` 与显示事实；实际提交经指令路由发事件指令 |
| 提交复核 | `Game.dispatch` | 校验版本与指令形状／参数合法性，按形状取该条行动并由唯一判定确认 `valid`，在事务副本上执行，失败完整回滚 |
| 执行 | `Events.execute` → `apply_effects` | 取冻结选项执行效果；分流到道具奖励、事件战斗、卡牌／遗物奖励、下一节点或结果 |
| 事件战斗 | `Events.begin_battle` → `Game._start_battle` → `Game._finish_battle` → `Events.finish_battle` | 冻结战斗 spec；事件战斗绕过普通奖励路径，只执行事件 `victory_effects` |
| 结果与离开 | `Events.execute("leave")` | 执行 cleanup、检查暂存装备、进入整备或结束房间 |
| 终局校验 | `Events.validate`／`Events.history_issue` | 校验事件历史、阶段、战斗／道具状态、遗物、暂存装备与计数 |

现行结构事实（据此写契约，不据叙事猜）：

- `core/room_events.gd` 集中定义访问、生成、随机冻结、探测、效果、候选、投影、战斗桥与校验；
  各消费者必须经本文件声明的入口访问事件能力。
- 事件战斗**借用**普通战斗的 `room_encounters` 与奖励状态：这是事实；不得据此直接改存档字段。
- UI 只消费过滤后的显示事实：`event_screen` 无法区分「未生成／被隐藏／生成但不可用」，
  具名原因只存在于 core 的 trace。
- 单节点与多节点共用节点声明、求值与执行管线；`recipe`、`hold_special`／`restore_held` 有测试夹具覆盖，
  当前正式内容包未使用。`frozen_form` 与兼容拼写（`availability`／`when`／`hide_when_unavailable`）
  通过同一声明表与解析入口处理，不构成第二套事件引擎。

## 接口

### 事件定义访问（唯一入口）

```gdscript
Events.definition(id) -> Dictionary          # 编译后的注册表条目就是作者形态（不做第二套内部结构）
Events.node(spec, node_id) -> Dictionary     # 缺失 id 返回空字典，不抛错
Events.node_ids(spec) -> Array               # 唯一的节点枚举入口
```

禁止出现 `definition.choices`／`definition.stages`／`definition.start_stage` 三种并行访问
（`tests/architecture_cases.gd::event_definition_accessors_only` 覆盖旧键不出现在编译形态）。

### 单求值入口与节点推进

```gdscript
# 唯一求值入口：任何「这条选项现在是什么状态」的判断都走这里
Events.evaluate_option(g, request) -> Dictionary
# request={"definition","node","choice","selected","purpose":"arrival"|"candidate"|"probe"|"execute",
#          "outcome":<预先抽到的权重结果，可选>, "frozen":<已冻结选项，candidate/probe/execute 必带>}
# 返回 {"decision","gates":Array[Dictionary]（全部命中条目，按求值顺序；每条 {"gate","kind","mode","index","detail","reason"}）,
#       "gate"（兼容单值＝首个命中）, "reason","option"}

Events.condition_entries(node, choice) -> Array   # 唯一的状态条件条目解析入口（校验与求值共用）

Events.enter_node(g, node_id) -> String           # 唯一节点推进入口；返回 ""＝成功，否则具名 issue
Events.enter_node_result(g, node_id, purpose) -> Dictionary
Events.enter_target(g, target, purpose) -> Dictionary
Events.next_target(next) -> Dictionary            # 唯一的 next 解释器
Events.request_for(g, option, purpose) -> Dictionary  # 请求装配器：只装配、不判定
```

- 生成侧与执行／探测路径上的节点推进都调用 `enter_node`／`enter_target`。
- 消费侧：`candidates`（`purpose:"candidate"`）、`probe`／`probe_choice`（`purpose:"probe"`）、
  `execute`（`purpose:"execute"`）都从同一入口取「决定＋具名原因」，不再各自重算资格；
  入口**只读**，唯一写状态的分支是到达（`purpose=="arrival"`）时把冻结选项写入 `state.room_event`。
- 节点推进入口为 `enter_node`，不保留 `enter_stage` 别名。
- 事件模块的其他接口：`start`／`view`／`candidates`／`execute`／`validate`／`history_issue`／
  `probe`／`probe_choice`／`availability_issue`／`selector_values`／`freeze_effects`／`apply_effects`／
  `describe`／`describe_result`／战斗桥与道具奖励入口。

### 结果词汇与具名 gate

`decision`（由 `gates` 聚合）：`generated`（已生成且可执行，`gates` 为空）／
`dropped`（未生成，结构性闸门）／`hidden`（生成后被隐藏；任一 `hidden` 模式条目命中）／
`disabled`（生成但禁用；只有 `optional` 模式条目命中，列出全部命中条目）。

`gate` 具名清单（**无静默丢弃**；每条命中都带 `index`＋`kind`＋`mode`＋`detail`；词汇表由
`tests/event_cases.gd::event_gate_names_are_total` 校验）：

| gate | 明细字段 | 现状出处 |
| --- | --- | --- |
| `condition_unmet` | `kind`＝`counter`／`selector_count`，`detail`＝key／selector.kind | 实例条件（`when`） |
| `relic_pool_empty` | `kind`＝`relic_pool` | `relic_gate:"pool"`，冻结前查池 |
| `selector_empty` | `kind`＝`selector` | selector 展开为空 |
| `recipe_empty` | `kind`＝`recipe` | `recipe` 编译为空 |
| `freeze_failed` | `kind`＝`feasibility` | 随机效果冻结失败 |
| `relic_already_offered` | `kind`＝`relic_offered` | `relic_gate:"claimed"`，冻结后查本事件冻结的遗物 |
| `availability_unmet` | `kind`＝状态条件种类（见声明表） | 状态条件命中 |
| `chain_loop` | `kind`＝`chain`，`detail`＝目标事件 id，`reason`＝`CHAIN_LOOP_REASON` | 链上已走过的目标事件 |
| `probe_failed` | `kind`＝`feasibility` | 效果探测失败 |
| `encounter_invalid` | `kind`＝`feasibility` | 战斗记录或胜利效果探测失败 |
| `validate_failed` | `kind`＝`feasibility` | 探测末尾的 `validate()` |
| `node_empty`／`stage_missing` | 节点级 issue（`enter_node` 返回） | 节点没有任何可执行选项／目标节点不存在 |
| `held_pending` | `kind`＝`feasibility` | 暂存装备未清 |

`reason` 一律为**现状字符串原文**（候选原因、issue 文案），不得改写措辞。

### 求值顺序（顺序是判据的一部分）

```
evaluate_option(purpose):
  0. 实例条件（when）命中 → 记 gate condition_unmet
  1. relic_gate=="pool" 且名义 reward=="relic" 且遗物池为空 → 记 gate relic_pool_empty（冻结前）
  2. arrival：selector 展开为空 → 记 gate selector_empty；否则逐 selection freeze_one
     candidate／probe／execute：用传入的 frozen 选项，不重新冻结、不消耗随机
  3. relic_gate=="claimed" 且冻结后 reward=="relic" 且 room_event.relic=="" → 记 gate relic_already_offered
  4. 状态条件条目（按声明顺序）：命中且（purpose!="execute" 或 mode=="optional"）→ 记 gate availability_unmet
     chain_loop：next 指向已走过的事件 → 记 gate chain_loop（purpose!="execute"）
     可行性探测：记 probe_failed／encounter_invalid／validate_failed（purpose!="execute"，且到达时仅当显式声明隐藏）
  5. 聚合 gates → decision／reason；hidden 或 dropped 的选项不进入 options
freeze_one()：按节点声明选布局——
  frozen_form=="in_place" 且选项无 selector → in_place（作者对象就地更新，键集与键序＝作者原文）
  其余一律 staged（固定字段序）
  二者都要：先抽 outcomes（outcome_draw=="option" 时整条选项只抽一次并复制给每个 selection）→
  recipe 编译（为空记 recipe_empty）→ 效果合并／$selected 替换／remove_restraints 归一 →
  随机冻结（random_freeze=="always" 或效果含生成器；失败记 freeze_failed）→
  item_rewards 冻结 → detail 解析 → result_status／selected 落位
```

**随机关键词**：`weighted`／`compile`／`freeze_effects`／`freeze_item_rewards` 的调用次序决定
`state.rng.event` 计数；`RelicRewards.offer` 用 `relic` 域，且只在「该定义含遗物奖励选项且遗物池非空」
时调用一次。上述随机消耗点（关键词 `weighted`／`compile`／`freeze_effects`／`freeze_item_rewards` 与
`RelicRewards.offer`）不得改序、不得改次数、不得改判据。条目**求值顺序**不影响随机消耗（只影响 `gates` 顺序与 `reason` 拼接），
但必须按声明顺序记录，保证 trace 与原因可复现。

各 `purpose` 的检查清单必须逐项等价、不得多不得少：

| purpose | 执行到哪一步 |
| --- | --- |
| `arrival` | 全部（含状态条件的隐藏丢弃），并把结果写入 `room_event.options` |
| `candidate` | 探测结果只影响 `valid/reason`；不写状态；`hidden` 的选项不会出现在这里 |
| `probe` | 同 `candidate`，另在有后继节点且 `reward=="none"` 时探测后继节点（`purpose:"next_probe"`） |
| `execute` | **只**复核 `optional` 模式的状态条件（不得改成全量探测，否则拒绝文案会变） |

### 状态条件的单一声明与四处派生

单一声明落在 `core/room_events.gd` 的 `CONDITIONS`（一种条件一行；`required/optional`＝作者字段，
`check`＝内容校验，`probe(g, entry) -> bool`＝是否命中）。条件条目（规范形状）：
`{"kind":…, "mode":"optional"|"hidden", "reason":String, <kind required 字段…>}`。

| 消费者 | 派生接口 | 不得另写 |
| --- | --- | --- |
| 条目解析 | `Events.condition_entries(node, choice)` | 两套路径各自在代码里决定 |
| 内容校验 | `Events.condition_issue(g, entry, data)`（逐条目，含 `mode` 合法性） | `content_catalog` 自带白名单 |
| 运行时求值 | `Events.condition_probe(g, entry)` | `availability_issue` 内的 `match` |
| 存档校验 | `Events.condition_saved_fields(kind)`（＝`["kind","reason"]+required`） | `snapshot.gd` 手写键集 |

**kind 字面量只允许出现在 `CONDITIONS` 声明表内**；内容校验／运行时求值／存档校验三处枚举出的
kind 集合必须相等（`tests/architecture_cases.gd::event_condition_kinds_share_one_declaration`）。
`condition_entries` 只产出**状态条件**条目；实例条件（`when`）、奖励遗物闸门（`relic_gate`）与可行性探测
**不进条目列表**，固定在求值步骤 0／1／3／4 上。

### trace（debug 开关）

- 落点：只挂在**游戏对象上的调试字段**（默认关闭）：`Events.trace_enabled(g)`／`Events.event_trace(g)`／
  `Events.trace_entry(g, fields)`，清空必须走同一接口 `Events.clear_trace(g)`。
  **不进 `state`／View／存档／日志／渲染，不做成计数器，不改 `core/game.gd`。**
- 条目字段（语义钉死）：`event`、`node`、`source_choice`（＝作者选项 id，选择器选项不含
  `__<实例>` 后缀）、`option_id`（＝本次求值的冻结实例 id，与 `room_event.options[*].id`、
  候选 `payload.choice` 同值；无冻结实例时回落作者 id）、`decision`、`gate`、`kind`、`mode`、
  `index`（状态条件＝该条目在选项声明列表中的下标，从 0 起；非条件类 gate 的 `index` 是本次求值的
  记账位置，不参与跨 purpose 比较、不得当稳定标识）、`reason`、`purpose`。
- 行集合不变量：**状态条件行**在同一选项的 `arrival`／`candidate`／`probe` 任意两次求值中逐字段相同
  （唯一允许变化的是 `purpose`；缺行即实现缺陷）；**非条件行**按阶段产生，只承诺「同一次求值内每个
  命中各一行、不重复、按求值顺序追加」。**禁止按 trace 总行数断言**——断言必须按
  `(purpose, source_choice, option_id, gate|kind, index)` 过滤后判定。
- 每次 `start` 在启用时清空；`enter_node`／`evaluate_option`／`probe_choice` 写入。
- 硬约束：开启与关闭时 `candidates`／`view`／`options`／`snapshot`／`rng` 摘要必须相同；
  release 默认关闭、运行不产出（`tests/persistence_cases.gd::event_trace_never_reaches_state_or_save`）。

### 事件链

`next` 指向三种目标，由 `Events.next_target` 唯一解释：`"result"`（结束事件，缺省）／
`"<node_id>"`（同一定义内的后继节点，只能向后）／`{"event":"<id>","node":"<node_id>"}`（跨事件跳转）。

| 项 | 规则 |
| --- | --- |
| 实例容器 | 同一次进入仍只有一个 `room_event`；跳转时重写 `id` 与 `stage`，不新建实例 |
| 计数器 `values` | 链上共享（跨事件继续累加） |
| 暂存 `held` | 链上共享；暂存 key 在整条链上唯一 |
| `cleanup_effects` | 链上**并集**（按 `key` 去重，来源定义在前）；离开时按并集逐条执行一次 |
| `room.event` | 保持抵达时抽取的 id（`history_issue` 与 `event_seen` 判据不变） |
| `event_seen` | 目标事件加入 `event_seen`（不得被本局再次抽到） |
| `flow` 镜像 | 每次跳转按当前定义是否有 >1 个节点重写（兼容键） |
| 新键 `chain` | **只在真的发生跨事件跳转时**写入：`chain:[event_id,…]`；元素＝已经走过的事件 id |
| 遗物 | 跳转时**按目标事件重算** `room_event.relic`：目标定义含遗物奖励选项且池非空 → 抽一次；目标不含 → 置空。不得保留来源事件的遗物 |
| 环 | 目标事件已在当前实例 `chain` 中 → 候选阶段不可用，gate＝`chain_loop`，`reason`＝`CHAIN_LOOP_REASON`；静态校验另拒绝「事件引用自身」 |
| 暂存 key | 跨定义的 `hold_special` key **编译期整包拒绝**；运行期守卫保留 |

安全规则：同一定义内的 `next` 保持现状校验（不倒退、不循环、必须已声明）；跨事件跳转的目标必须
已登记且目标定义合法；**静态只拒自引用**，跨定义环（A→B→A）由运行期 `chain_loop` 守卫拒绝——
静态不拒绝跨定义环是**有意的**（不引入跨事件图上的静态环检测）。当前 12 份正式内容没有事件链，
链语义由夹具与专门场景验证；新增链内容须同步作者定义与对应测试。

## 输入域

### 定义级字段（`kind:"event"`）

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `schema_version` | 是 | 事件为 **2**（其他 kind 仍为 1） |
| `kind`／`id`／`name`／`intro` | 是 | 与既有形态一致 |
| `pool` | 可选（默认 true） | 是否进入随机池 |
| `start_node` | 是 | 起始节点 id；单节点定义固定为 `choice` |
| `nodes` | 是 | 节点数组（1–12 项），顺序＝作者顺序 |
| `cleanup_effects` | 可选 | 定义级（≤8 项，只接受 `restore_held`） |

顶层不再有 `choices`／`stages`／`allow_refuse`；两者同时出现或残留一律拒绝。

### 节点级字段

| 字段 | 取值 | 含义 |
| --- | --- | --- |
| `id` | 稳定 id | **单节点定义必须用 `choice`**；**多节点定义禁用** `choice`／`reward`／`result`／`battle`／`loot`／`keys` |
| `title`／`intro` | 多节点必填；单节点**不得出现**（键缺失，不是空串） | `view` 的拼接按「键存在」判定 |
| `allow_refuse` | 是，**必填、无默认** | 是否追加拒绝选项（`refusal`） |
| `unavailable` | `"hide"`／`"disable"` | 该节点选项的默认模式：`disable`→`optional`，`hide`→`hidden` |
| `relic_gate` | `"pool"`／`"claimed"` | 遗物闸门位置：`pool`＝冻结前查池，`claimed`＝冻结后查本事件冻结的遗物 |
| `random_freeze` | `"generators"`／`"always"` | `generators`＝只有含生成器的效果才预跑；`always`＝一律预跑 |
| `outcome_draw` | `"option"`／`"selection"` | `option`＝整条选项抽一次并复制给每个 selection；`selection`＝每个 selection 各抽一次 |
| `frozen_form` | `"in_place"`／`"staged"` | 冻结布局；见下面的布局判据 |
| `empty_node` | `"allow"`／`"fail"` | 节点没有任何可执行选项时：`allow`＝保持零候选，`fail`＝返回具名 issue |
| `choices` | 1–6 项 | 作者选项 |

**布局判据（就近写明，不留在代码注释里）**：`frozen_form=="in_place"` **且选项没有 `selector`** 时
才用 in_place 布局，其余一律 staged；节点声明仍决定 staged 节点的整体布局。依据：选择器选项历来由
共享 staged 构建器冻结；只按节点声明选布局会改变这类选项的冻结 `id`（含 `__<实例 id>` 后缀）与
`selected` 键。改这条必须重新人审。

### 选项级字段（唯一清单）

| 字段 | 取值 | 说明 |
| --- | --- | --- |
| `conditions` | 1–8 条条目的数组 | **规范拼写**；可叠加，两类模式可同时声明 |
| `availability` | `{kind, reason, …}` | **兼容拼写**：等价于一条「按选项默认模式解析」的状态条件；只为 12 份内容与冻结产物键集保留 |
| `unavailable` | `"hide"`／`"disable"` | 选项级覆盖，决定该选项**未被显式 `mode` 约束的条目**的默认模式；与 `hide_when_unavailable` 冲突即拒绝 |
| `hide_when_unavailable` | 布尔 | **兼容拼写**，等价 `unavailable:"hide"`（今日语义：状态条件与可行性探测**都**隐藏） |
| `when` | `{counter｜selector, equals/minimum/maximum}` | **兼容拼写**：实例条件，模式固定 `hidden` |
| `outcome_draw` | `"option"`／`"selection"` | 可选覆盖；只在有 `outcomes` 时有效 |
| `next` | `"result"`／节点 id／`{"event":"<id>","node":"<id>"}` | 缺省 `"result"` |
| `encounter`／`item_rewards`／`selector`／`outcomes`／`recipe`／`effects`／`report`／`report_variants`／`detail`／`result_status`／`show_pressure_sources` | 不变 | 合并白名单后，单节点与多阶段**都可使用全部字段** |

- 同一选项**不得**同时写 `conditions` 与 `availability`（两种容器只允许选一种），否则拒收——
  避免同一份资格出现两个真相源。
- `mode` 只允许 `"optional"`／`"hidden"`；省略时按模式解析（优先级：① 条目自带 `mode`；
  ② 选项 `unavailable`；③ `hide_when_unavailable:true` → `hidden`；④ 种类默认：状态条件＝`optional`，
  可行性条件＝节点 `unavailable` 默认，实例条件与奖励遗物条件＝`hidden`）。
- 冻结产物键集是兼容要求、不是设计目标：用兼容拼写的内容在冻结选项里保留原键；
  用规范拼写的新内容携带 `conditions` 数组（含 `mode`）。两者都由同一张声明表派生，且都被存档校验接受。
- 选项级 `pressure`／`pressure_source` 已删除：不在白名单，写了即拒收（不得恢复死分支）。

### 编译后注册表形态

`Data.TYPES[id]` **就是**作者形态（同一份定义，不做第二套内部结构）；节点与选项只能经
`definition`／`node`／`node_ids` 访问。

### 校验规则取值

下表是现行作者形态的接受范围。变更取值时须同步正式内容与正例、最近反例和边界；
过期或重复测试按覆盖关系处理，不删除有效失败案例换取通过。

| # | 校验项 | 当前取值 |
| --- | --- | --- |
| 1 | `effects` 上限 | 12（`outcome.effects` 另计 12） |
| 2 | 空 `effects` | 允许（含带 reward） |
| 3 | `hold_special`／`restore_held` | 允许（保持 key 唯一＋cleanup 配平） |
| 4 | `recipe` 与 `effects` | 不能同时出现；允许只有 `outcomes` |
| 5 | `allow_refuse` | 节点必填、无默认 |
| 6 | 节点 id 保留字 | 单节点必须 `choice`；多节点追加挡 `battle`／`loot` |
| 7 | 起始节点免费出口 | 保持（`allow_refuse:true` 或无条件免费离开）——**只约束多节点定义**；单节点可以是强制事件 |
| 8 | 奖励选项的 `next` | 带 reward 的选项必须结束事件（`"result"`） |

### 叠加求值

1. 所有条目都要满足才算通过；命中的条目按声明顺序收集进 `gates`；
2. 聚合优先级：任一 `hidden` 命中 → `decision="hidden"`（其余命中一并记进 `gates`）；
3. 否则任一 `optional` 命中 → `decision="disabled"`，`gates` 列出**全部**命中条目；
4. 全部通过 → `decision="generated"`，`gates` 为空；
5. `reason` 拼接：单条命中＝该条 `reason` 原文；多条 `optional` 命中＝按声明顺序用 `"\n"` 连接；
   `hidden` 命中的 `reason` 供 trace 与节点 issue 使用。

`reason_surface="secondary"` 的判定＝`decision=="disabled"` 且 `gates` 非空且每条命中都是状态条件条目；
不再二次调用 `availability_issue`（去掉平行真相）。

### 存档表示

- **冻结产物逐字节不变**（兼容要求，不是设计目标）：`room_event` 的键集合与键序、冻结选项的字段布局
  保持不变。普通非选择器选项的冻结结果＝作者选项对象本身，**不得增删键、不得改键序**。
- `flow` 与 `next_stage` 降级为**兼容镜像**：`flow` 仍按定义节点数（>1）写入，`next_stage` 仍写 `""`；
  **不再有任何运行分支读它们**。
- 新增键只在链实际发生时出现：`chain` 只在跨事件跳转后出现；`conditions` 只在用规范拼写的新内容上出现。
- 事件段存档校验口径：基础形状（`id/label/detail/reward/effects`＋`result_status`）保持；
  **`flow` 实例**的全部既有检查逐条保留；`conditions` 键按声明表的键集＋`mode` 增量接受，与 `availability`
  互斥；`chain` 增量接受（数组、已登记、不重复、非空）。**不得**改写成「按 `option.has("next")` 判定」。
- **既有缺口**：单节点 in_place 事件的冻结选项 `next` 不被存档校验覆盖；运行期影响有限（未知目标经
  `stage_missing` 等具名 gate 失败）。修法（不触碰既有 `flow` 分支）：在它之外新增一条**只针对 in_place
  实例**的校验——对 `has("next")` 的选项要求 `next` 是 String 且 ∈ `{"result"} ∪ node_ids(definition)`。
  该修复需另立批次，未落地前不得在契约里宣称已覆盖。

## 失败语义

- **无静默丢弃**：任何「选项不出现／不可用」都要有具名 `gate` 与 trace 行；`decision ∈ {dropped,hidden}`
  的行必须带非空且在清单内的 `gate`。
- 节点入口失败必须两类都写：`node_empty` 与 `stage_missing`，各写一行（`gate`＋`node`＋空 `option_id`）。
- 内容校验拒绝项（编译期、整包拒绝）：顶层残留 `choices`／`stages`／`allow_refuse`；缺 `start_node`
  或节点缺任一声明键；节点 id 用保留字；`recipe` 与 `effects` 同填；单节点用非 `choice` id；
  多节点起始节点没有免费出口；带 reward 的选项 `next` 指向节点；`conditions` 与 `availability` 并存；
  未知状态条件 kind 或 `mode` 非法；选项级 `pressure`／`pressure_source`；跨定义的 `hold_special` key；
  事件引用自身。**内容错误在加载时确定性拒绝**，而不是等运行期被挡住。
- 运行期拒绝：`chain_loop`（候选保留但不可用，`reason`＝`CHAIN_LOOP_REASON`）；`failed`／`unrun`
  不得当通过。
- trace 只在 debug 开关下产出；release 运行不得产出 trace，且开／关两种设置下的摘要必须相同。
- 禁止：为凑绿改断言或删套件；删既有反例；把「某处等价」的判定当作已证（求值顺序与随机消耗
  必须由 oracle 逐场景证明）；把测试夹具当作正式内容。

## 依赖规范

允许的依赖方向：`data/* → core/* → ui/*`。

- 允许的 `preload` 边（**恰好等于**此集合，多一条少一条即红，
  `tests/architecture_cases.gd::event_dependency_edges_pinned`）：
  `core/room_events.gd` → `data/room_events.gd`、`data/relics.gd`；
  `core/snapshot.gd` → `data/phases.gd`；`core/content_catalog.gd` → 无。
- `core/room_events.gd` 经传入的 `g.*` 调用 Game 及其子域；`core/content_catalog.gd` 只经 `g.*`；
  `core/snapshot.gd` 的事件段只经 `g.Events.condition_saved_fields`／`battle_spec_issue`／
  `item_rewards_issue` 等既有入口；`ui/*` 只经 `ui/main.gd` 的 `preload` 调用
  `get_view`／`dispatch`／`number`／`Prison.*`／快照入口／三个按需只读入口。
- 禁止的边（其余一律禁止；机检覆盖见括号）：
  1. `core/**` 不 preload／load 或书写 `ui/**`（`tests/architecture_cases.gd::slice_dependency_directions`）。
  2. `data/**` 不 preload `core/**` 或 `ui/**`；不持有事件资格判定（条件种类、隐藏／禁用策略）。
  3. `snapshot.gd` 不自带第二套状态条件键集或 kind 清单；必须调 `g.Events.condition_saved_fields(kind)`。
  4. `content_catalog.gd` 不复写条件种类校验与 `mode` 语义；必须调 `g.Events.condition_issue(...)`；
     不决定「隐藏还是禁用」（那是运行时求值入口的事）。
  5. 生产代码（`core/`／`data/`／`ui/`）不 preload／引用 `res://tests/**`，测试不得成为生产依赖
     （`tests/architecture_cases.gd::production_source_never_preloads_tests`）。
  6. 资格求值只允许一个入口：`probe_choice`／`availability_issue`／`condition_met`／`freeze_choice`
     不得被 `evaluate_option` 之外的 core 函数调用；兼容拼写（`availability`／`when`／`hide_when_unavailable`）
     只允许出现在 `condition_entries` 与冻结投影两处（`tests/architecture_cases.gd::event_single_evaluation_entry`）。
  7. 状态条件 kind 字面量只允许出现在 `Events.CONDITIONS` 声明表内。
  8. 存档写入：`room_event.chain` 只允许在跨事件跳转时写入；`room_event.options[*].conditions`
     只允许由冻结投影写入；其他模块不得改写这两个键。
  9. debug trace 只允许挂在游戏对象上的调试字段；不进 `state`／View／存档／日志，也不得做成计数器。

文件与职责边界：

| 文件 | 拥有 | 不得承担 |
| --- | --- | --- |
| `core/room_events.gd` | 定义访问、节点与链管线、单求值入口、条件声明表与四处派生、冻结与效果执行、候选与投影、战斗桥与道具奖励桥、事件校验 | 内容 JSON 的结构校验、存档形状与键集、UI 文本 |
| `core/content_catalog.gd` | 读取 JSON、作者层 schema 与引用校验、注册表提交 | 运行时资格判定、隐藏／禁用决策、存档键集 |
| `core/snapshot.gd`（事件段） | 存档形状、键集与委派 | 玩家可见资格（不得自己判断「该不该出现」） |
| `data/room_events.gd` | `TYPES` 注册表、卡牌池、`REFUSAL_MANA` | 规则逻辑、条件判定 |
| `content/packs/*.json`、`content/templates/*` | 作者声明 | 运行时状态、脚本、按事件 id 的分支 |
| `tests/*_cases.gd` | 具名 check 与夹具 | 被生产代码引用 |

## 证据入口

```powershell
# 按影响选择规则、内容或窗口分类；操作口径见 repo-ops。
& tools/check-content.ps1
& tools/check.ps1 -Suite event_flow,events,content,architecture -Impact -TimeoutSeconds 900
& tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900
```

- 判据口径：退出码 0；每个 `SUITE RESULT: PASS <name>`；`summary.json` 的 `status=passed` 且
  `before==after` 指纹（`source_changed` 不算通过）；界面输出含 `UI PASS: N assertions`。
- 内容门：`check-content.ps1` 通过（`CONTENT PASS: N file(s)`）；改 `content/packs`、`content/templates`
  或站点文档示例后必跑（文档示例可复制为临时 `.json` 后用 `-Path` 指向该目录校验）。
- 具名 check 索引（落点＝对应 case 文件；分类见 `tests/test_game.gd` 的 `SUITES`）：
  定义单形态与访问器＝`event_definition_single_form`／`event_definition_accessors_only`；
  选项策略与叠加求值＝`event_option_policies_match_current_behaviour`／`event_single_node_declarations`／
  `event_stacked_conditions`；gate 词汇＝`event_gate_names_are_total`；
  单求值入口＝`event_single_evaluation_entry`；只读探测与投影＝`event_probe_and_projection_readonly`；
  条件三处一致＝`event_condition_kinds_share_one_declaration`；内容校验＝`event_stage_available_condition_validates`／
  `event_definition_form_rejects_legacy_shape`／`event_union_validation_rules`／`event_author_manual_lists_current_fields`；
  空节点＝`event_node_empty_policy_kept`；事件链＝`event_chain_jumps_to_another_event_node`／
  `event_chain_loop_refused`／`event_chain_references_fail_closed`／`event_chain_hold_keys_fail_closed`／
  `event_chain_relic_drawn_from_target`／`event_chain_trace_rows`；存档＝`event_frozen_options_roundtrip`／
  `event_trace_never_reaches_state_or_save`。
- 人的路径证明与敏感性证明按 `docs/record/verification.md` 登记；本地化缺译不得写成通过。
