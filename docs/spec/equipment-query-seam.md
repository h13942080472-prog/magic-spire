# 装备只读查询接缝契约（查询 → 索引 → 作用域）

本文件冻结 core 装备只读查询的接口语义、返回值政策、作用域生命周期与 oracle 协议，
供实现者、清洗者、加固者、验收者只读消费：内部实现以代码为准，接口语义以本文件为准。
本文件不写执行结果；通过／失败／未执行只登记在验证记录（`docs/record/verification.md`）。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- core 内对「普通件／复合组件／独立链接／特殊件／肩部件／躯干连接」的只读查询在**一次只读调用内**的复用。
- 三个接缝：
  - 接缝 A（查询 ↔ 索引）：`Game._equipment_read` 与本文「接口清单」的全部查询；
  - 接缝 B（调用方 ↔ 作用域）：`_begin_equipment_read()`／`_equipment_read=previous` 的进出点；
  - 接缝 C（投影 ↔ 索引）：`GameView.equipment_entry` 的只读复用。
- 不含：UI 响应路径与节键（见 `docs/spec/response-pipeline.md`）、玩家可见文案的按需投影
  （见 `docs/spec/ondemand-copy.md`）、规则数值、候选资格与候选 ID、存档语义与快照格式。
- 锚点约定：函数名与接口名是稳定锚点；实现类调用点会随重构移动，动手前用 `rg` 复算，不按记忆里的位置找函数。

## 接口（接口清单与语义）

「无作用域来源」的拼装顺序 = 返回数组顺序；**顺序是接口的一部分**：`_equipment_name` 用
`equipment_at(target.slot).find(target)`／`_stack_items(target)` 生成「第 N 条／第 N 件」，
候选与详情直接消费该名称，任何重排都会改玩家可见文本。

| 接口 | 作用域内来源 | 无作用域来源（拼装顺序＝返回顺序） | 过滤条件 | 返回容器 | 元素 |
| --- | --- | --- | --- | --- | --- |
| `physical_pieces()` | 件集合 `pieces` | `state.equipment` 原序 → `state.composites[*].components`（root 序、组件序）→ `Shoulders.pieces(self)`（`state.equipment` 原序 × `host.shoulders.pieces` 原序） | **无**（不看耐久、不看覆盖） | 新数组 | 权威实例 |
| `equipment_at(slot)` | 部位→件 `slots` | `physical_pieces()` | `slot in Equipment.coverage(e)` ∧ `e.durability>0` | 新数组（命中索引时 `.duplicate()`） | 权威实例 |
| `targets_at("shoulder")` | 部位→目标边[`"shoulder"`] | `physical_pieces()` | `Equipment.is_shoulder(e)` ∧ `e.durability>0`；**不走 coverage**（含复合肩带 `glove_strap` 与 `shoulder_host` 件） | 新数组（命中索引时 `.duplicate()`） | 权威实例 |
| `targets_at(特殊槽)` | 部位→目标边[slot] | `state.special_equipment` → `links_at(slot)` | 特殊件：`SpecialEquipment.occupies(e,slot)`，**无耐久过滤**；绳：`durability>0` ∧ `slot in link.slots` | 新数组（命中索引时 `.duplicate()`） | 权威实例 |
| `targets_at(普通槽)` | 部位→目标边[slot] | `equipment_at(slot)` → 覆盖该槽且活跃的复合组件（`slot in Composites.definition(root).coverage` ∧ `Composites.active(root)`，排除 `is_shoulder`，按**引用**去重）→ `links_at(slot)` → `Binding.connections(self)` 中 `e.slot==slot` | 同左 | 新数组（命中索引时 `.duplicate()`） | 权威实例 |
| `links_at(slot)` | 部位→绳 | `state.links` | `durability>0` ∧ `slot in link.slots` | 新数组 | 权威实例 |
| `link_anchors()` | 锚清单 | `physical_pieces()` → `state.special_equipment` | 特殊件：`Links.is_crotch_anchor`，**无耐久过滤** | 新数组 | 权威实例 |
| `equipment_targets()` | 目标清单 | `physical_pieces()` → `state.links` | 无（**链接不看耐久**） | 新数组 | 权威实例 |
| `action_targets()` | `actions` 清单 | `equipment_targets()` → `state.special_equipment` → `Binding.connections(self)` | 连接：`Binding.present(e)` ∧ `kind=="linked"`（一体式不入列） | 新数组 | 权威实例 |
| `_equipment(id)` | id→件 `ids` | `action_targets()` | id 相等，**首个命中** | **同一实例引用，不复制**（唯一例外） | 权威实例 |
| `_composite(id)` | 根→组件 | `state.composites` | `root.id==id` | 同一实例引用 | 权威实例 |
| `occupied(slot)` | 部位→件 `slots` | `equipment_at(slot)` | `palm`／`fingers`：`hand_blocked(slot,"left") and hand_blocked(slot,"right")`；其余：非空 | bool | — |
| `hand_blocked(slot,side)` | 部位→件 `slots` | `equipment_at(slot)` | `e.get("side","") in ["",side]` | bool | — |
| `capacity_used(slot)` | 点→件（容量） | `physical_pieces()` | `point in Equipment.capacity_points(e)`，对 `Equipment.points(slot)` 逐点计数取 `max` | int | — |
| `_point_count(point)` | 点→件（容量） | `physical_pieces()` | `point in Equipment.capacity_points(e)` | int | — |
| `_capacity_issue(pieces)` | **入参数组**（不保证是权威件集合） | **入参数组**（不保证是权威件集合） | 逐点计数 > `_capacity(slot)` | String（原因或空） | — |
| `_stack_items(target)` | 索引 `stacks` | 见 `_query_stack_items` | `parent_id` 递归；特殊件按 `occupied_slots` 交集；`coverage` 空或 `link_rope` → `[target]`；否则 `Equipment.overlaps` ∧（非独立件或同 id 或不同 root） | 新数组／索引副本 | 权威实例 |
| `Shoulders.pieces(g)` | `state.equipment` 中带 `shoulders` 的宿主 | `state.equipment` 中带 `shoulders` 的宿主 | 无（耐久过滤在 `attached`） | 新数组 | 权威实例 |
| `Shoulders.attached(g,host)` | `host.shoulders.pieces`（`glove_body` 宿主改取 `root.components`） | `host.shoulders.pieces`（`glove_body` 宿主改取 `root.components`） | `is_shoulder` ∧ `durability>0.000001` | 新数组 | 权威实例 |
| `Binding.connections(g)` | `state.equipment` | `state.equipment` | `present(e)` ∧ `binding.kind=="linked"` | 新数组 | 权威实例 |
| `cast_view(profile)` | 索引 `casts` | 索引 `casts` | 键 = 规范化 profile（见「输入域」的键规则） | 深拷贝 | 结果字典 |
| `equipment_entry(g,e,slot)` | 索引 `equipment_views` | 索引 `equipment_views` | 仅当 `is_same(e, _equipment(e.id))`（非权威实例绕开复用） | 深拷贝 + 覆盖 `slot` | 显示行 |

- **「无耐久过滤」的四处必须原样保留**（`targets_at` 特殊件分支、`equipment_targets`／`action_targets` 的链接、
  `link_anchors` 的股绳锚、`equipment_targets` 整体）：它们决定徒手解除与监狱巡视基准清单的范围，收紧或放松都会改候选。
- **返回值政策**：索引内部只读共享；只在真正需要的边界复制一次（`equipment_at`／`targets_at`／`physical_pieces`／
  `_stack_items`／`escape_preview`／`cast_view`／`equipment_entry` 在返回处 `.duplicate()`／`.duplicate(true)`）。
  新增的边（点→件、根→组件、宿主→肩、连接、绳、锚、部位→目标、`targets`／`actions` 清单）沿用同一政策：
  **索引里存一份，返回时复制一份**，同一作用域内只复制不重算。
- **例外一（保留）：`_equipment(id)` 返回权威实例引用**。它是规则层拿实例的通道
  （耐久写入、替换、清理、投影）。「调用方不得写共享结果」对返回容器成立、**对装备实例不成立**；
  装备实例只能由正式管线写。不得因为「看起来像查询」而给它加 `.duplicate()`——那会让写入落到副本上，
  候选与视图仍绿而状态不变。
- 消费方可以信任：返回值与上表逐项一致；返回的件是当前权威实例；返回的数组可以排序／清空而不影响其它调用。
  消费方不得：按名称／译文／图片识别对象；把返回容器当作索引的一部分长期持有；写权威实例（只有正式管线写）。
- 谓词与计数接口的判据统一为：**只允许改「怎么取到件集合」，不允许改过滤条件、过滤顺序或返回类型**；
  上表即它们的规范。手部特例不得用「数组非空」替代：一条 `side="left"` 的件 →
  `occupied("palm")==false` 且 `hand_blocked("palm","left")==true`；左右各一条 → `true`；`side=""` 的件两侧全挡。
  `_capacity_issue(pieces)` 的入参不是权威件集合时必须现算（如 `physical_pieces()` 与 `root.components` 相加时），
  原因文本与阈值不变；「能否用索引」的判据必须显式，不得靠逐元素相等去猜。

### 非缓存路径

没有作用域时，各查询走 live 实现（`filter`／`map` 新数组），返回值仍与上表一致；
作用域内 `targets_at` 只读部位→目标边，无作用域走 live。
任何路径都不得把索引容器直接返回，「返回容器隔离复制」的既有断言必须继续通过。

### `targets_at` 路径（邻接表）

本域声称一条查询路径、无第二套公开入口、作用域内查询不扫权威容器。边＝稳定符号。
行为检查器＝具名 `INDEX targets edge parity` 与 `index_materializes_once_per_scope`（关掉查表分流须让其中一条变红）。

| 边 | 来源 → 去向 | 类型 | 对应路径（唯一） |
| --- | --- | --- | --- |
| T1 | `core/game.gd::targets_at` → `_equipment_read.slot_targets` | 数据 | 作用域内：`slot_targets.get(slot,[]).duplicate()`；未登记＝已知空，不 live 补扫 |
| T2 | `core/game.gd::targets_at` → `core/game.gd::_query_targets_at` | 调用 | 无作用域：唯一 live 拼装入口 |
| T3 | `core/game.gd::_build_equipment_read_index` → `core/game.gd::_materialize_slot_target_edge` | 调用 | `slots`／`roots`／`links`／`connections` 已写入之后、`actions`／`ids` 之前写入 `slot_targets`；自检作废早退不建此边 |
| T4 | `core/game.gd::_materialize_slot_target_edge` → `core/game.gd::_query_targets_at` | 调用 | 键宇宙每个槽一次；禁止调 `core/game.gd::targets_at`（表尚未开放） |
| T5 | `core/game.gd::_query_targets_at` → `core/game.gd::physical_pieces` | 调用 | `"shoulder"` 分支；过滤见接口表 |
| T6 | `core/game.gd::_query_targets_at` → `state.special_equipment`＋`core/game.gd::links_at` | 数据／调用 | 特殊槽分支；特殊件无耐久过滤，不拼连接 |
| T7 | `core/game.gd::_query_targets_at` → `core/game.gd::equipment_at` → `core/game.gd::_composite_roots` → `core/game.gd::links_at` → 连接清单 | 调用 | 普通槽；连接：作用域内 `_equipment_read.connections`，否则 `core/torso_binding.gd::connections` |

禁止边（出现即未洁）：

- `core/game.gd::targets_at` 方法体 → `core/game.gd::physical_pieces`／`core/game.gd::equipment_at`／`core/game.gd::_composite_roots`／`core/game.gd::links_at`／`core/torso_binding.gd::connections`／`state.special_equipment.filter`（作用域内也不经 `_query_targets_at` 再拼）
- `core/game.gd::_query_targets_at` → `core/game.gd::targets_at`（不回调、不读 `slot_targets`）
- 第二套公开 `targets_at`（`_query_targets_at` 是私有拼装，不是第二入口）
- 写路径跟随 `slot_targets`；把肩带写入 `slots["shoulder"]`

非本刀、不升格：键空间「宿主→肩部件」与 B6 `INDEX host edge parity` 仍未落地。`core/shoulder_links.gd::attached` 与 `core/torso_binding.gd::connections` 的作用域内来源仍是 live（`host.shoulders.pieces`／`state.equipment`），不声称读未落地边。`equipment_at`／`occupied`／`hand_blocked` 仍走部位→件边，本刀零行为变化。

## 输入域

### 作用域协议（既有，不改签名）

- 进入：`var previous=_begin_equipment_read()`；无活跃作用域时创建（含 `state` 身份与各边容器），
  已有作用域时返回同一容器，即**嵌套安全**。
- 退出：`_equipment_read=previous`，必须在同一次调用**所有出口**执行。
- 活跃判定：`_equipment_read_active()` = `_equipment_read` 非空 ∧ `is_same(_equipment_read.state,state)`。
- **作用域 = 只读事务**：作用域内不得（a）给 `state.equipment`／`state.composites`／`state.links`／
  `state.special_equipment` 增删成员，或改这些边依赖的字段（`durability`、`coverage`、`points`、`layer`、
  `root_id`、`shoulder_host`、`parent_id`、`binding`、`locked`）；（b）替换 `state`。
  违反即过期表，而身份判定**不会发现**（原地修改不改身份）。
- 进出纪律：单出口函数可包全身；多出口函数（`match`、早退）只包住只读子块（三行局部作用域）
  或把只读子块提为私有函数；不得把作用域跨过写动作，也不得用 `return` 跳过释放。
- **禁止自动跟随 `state`**：缓存只在显式作用域里存在。理由：`dispatch` 里
  `state=state.duplicate(true)` 之后在**同一对象上原地继续修改**，版本号到收尾才 +1；
  任何「state 变了就重建」的自动跟随都会在提交中途重建出一份尚未完成、且此后不再变身份的中间表，
  并把它当权威继续用。正式管线一律 live；只读投影只在显式作用域内建表。
- 不得把 `version` 当缓存键或失效键；不得跨调用保留任何索引内容。

### 必须新开作用域的入口（读-only，各开一次）

| 入口 | 位置 | 作用域包住什么 |
| --- | --- | --- |
| `EnemyPlans.targets` | `core/enemy_plans.gd` | 全函数（单出口）；只读筛选，候选文案的敌人计划目标 |
| `Contact.workspace` | `core/contact.gd` | 全函数；只读槽位表，内部多次 `occupied`／`physical_pieces` |
| `EquipmentOffers.preferred` | `core/equipment_offers.gd` | 全函数；只读排序，`_fills_empty` 逐件判定 |
| `EquipmentOffers.for_pool`／`ordinary`／`links` | `core/equipment_offers.gd` | 各自只读体；被敌人池与事件反复调用 |
| `SelfBinding.tighten_targets`（含 `capacity()`） | `core/self_binding.gd` | 全函数（叶）；推演期换 state 时由身份判定自动绕开 |
| `RoomEvents.selector_values` | `core/room_events.gd` | `"restraint"` 分支的只读块 |
| `RoomEvents.compile` | `core/room_events.gd` | **只包** `targets=` 过滤表达式；`locked_assembly` 分支会换 state，不得包全函数 |
| `Prison.validate` | `core/prison.gd` | 无自带只读块；若已在 `Game.validate` 之下的嵌套调用，则为空操作 |
| `Game._prepare_assembly` | `core/game.gd` | 规划段（`_assembly_reason`、层序循环、`_capacity_issue`）；真正写入在其后的 `_install_assembly` |

- 作用域**不得加在叶查询上**（`equipment_at`／`physical_pieces`／`_equipment`／`capacity_used`／
  `_point_count`／`links_at`／…）：它们跟随外层作用域，自带作用域只会造成「每次查询重建一次」。
- `candidates()` 与 `get_view()` 的现有进出保持不变。

### 明确豁免（不得开作用域）

| 入口 | 理由 |
| --- | --- |
| `Prison.intake_equipment` | 循环内读后写（`_refresh_equipment` 可新增肩带，作用域跨写即过期） |
| `SlipMotion.apply` | 正式施加滑脱，读后写 |
| `RoomEvents.freeze_effects` | 循环内逐次读后写 |
| `Shoulders.cleanup` | 迭代中 `erase` 肩带成员 |
| `Game.validate` | 存档／读档守卫，按「验证的边界」从原始 state 现算，且未测得瓶颈 |
| `EquipmentReplacement` 收尾校验 | 替换管线内的读后写收尾 |
| `data/first_floor_enemy_pools.gd` 的 `eligible` | 已决（人裁）：保持 live；**数据层不得调用 core 的读作用域进出**，其收益经 core 侧自带作用域间接到达 |

豁免不是「可以不看」：这是契约判据（读后写／多出口／存档守卫），清洗者与加固者不得「顺手补上」作用域；
加了即算未完成。

### 键空间（索引内部，清洗者检查对象）

边名可用实现者的命名，但必须与下表 1:1 对应，且**只沿「构建方向」由权威容器正向投影**
（不得反向搜索 `root_id`／`shoulder_host` 来「发现」成员）。

| 边 | 键 | 值（有序） | 构建方向 |
| --- | --- | --- | --- |
| 件集合 `pieces` | — | 物理件数组 | `state.equipment` → 各 `root.components` → 各 `host.shoulders.pieces` |
| 部位→件 `slots` | 槽 ID（所有件的 `coverage` 槽 + `"shoulder"` + 特殊槽） | 件数组（件集合顺序） | 由件集合按 `Equipment.coverage` 正向投影，**入口一次物化全量**；未登记的槽 = 已知空，直接返回空数组，不重扫 |
| id→件 `ids` | 装备 id | 件（引用） | 由 `action_targets()` 组合结果正向投影 |
| 点→件（容量） | 点 ID | 件数组 | 由件集合按 `Equipment.capacity_points` 正向投影 |
| 点→件（物理） | 点 ID | 件数组 | 由件集合按 `Equipment.physical_points` 正向投影 |
| 根→组件 | `root.id` | 组件数组（root 序） | 由 `state.composites[]` 正向投影 |
| 部位→绳 | 槽 ID | 绳数组（`state.links` 原序） | 由 `state.links` 按 `slots` 正向投影 |
| 宿主→肩部件 | 宿主 id | `host.shoulders.pieces`（原序）；`glove_body` 宿主取 `root.components` 中 `is_shoulder` 件；`durability>0.000001` 过滤只属于 `attached` | 由 `state.equipment` 正向投影 |
| 连接 | — | 连接件数组（`state.equipment` 原序） | 由 `state.equipment` 的 `binding.kind=="linked"` 正向投影 |
| 部位→目标 | 槽 ID（`B.SLOT_NAMES.keys()` ∪ `B.SLOTS` ∪ 已物化 `slots`／`links` 键 ∪ `"shoulder"` ∪ `SpecialEquipment.slots()` ∪ 连接件 `.slot` ∪ 各根 `definition.coverage`） | 目标数组（接口表三路拼装顺序） | 入口一次按接口表三路正向投影；未登记＝已知空，不 live 补扫 |
| 目标清单 | — | 有序数组 | 按上表拼装顺序组合上述边；只对应 `equipment_targets()` |
| `stacks`／`escapes`／`casts`／`equipment_views` | 见下 | 结果副本 | 维持既有填充点 |

`casts` 改稳定键的规则：键 = 规范化序列化（键名排序、递归处理嵌套容器、数值 int/float 同值归一）后的字符串，
**不得丢字段**（`parts`、`multiplier`、`chance_bonus`、`body_free`、`paid_cast`、`toe_route` 及将来新增字段全部进键）；
语义要求 `键相等 ⇔ profile 相等`：宁可少命中（多算一次，走 live 结果），**不可错命中**；
键里不得放目标 id、卡牌名、译文或实例身份来「猜等价」。结果与输入仍隔离深拷贝，退出作用域即释放。

### 图结构与运行期事实

- 图的构建期保证：深度 1、无任意链——普通件禁止携带 `coverage`／`root_id`／`parent_id`／`shoulder_host`；
  组件 id 必须等于 `root.id+"_"+part` 且字段与 spec 逐字段相等；固缚 id 必须是 `"binding_"+宿主.id`。
- **运行期无环守卫**：`_outer`、`_effective_ratio`、`_query_stack_items→_stack_items`、
  `equipment_entry→_equipment_name` 都是无守卫递归，今天安全只因数据形状保证深度为 1。
  本片不得加深递归，也不得靠递归兜底。

## 失败语义

- **构建期自检（不猜、不修、可归因）**：四项检查任一失败 → 该**整个作用域的索引作废**，
  该次调用余下的查询全部按 live 重建路径回答，并留一条可见记录。
  1. 组件归属：`component.root_id == root.id`，且该组件确实在该 `root.components` 中；
  2. 肩部件宿主：`piece.shoulder_host` 能解析到件集合内的宿主，且该宿主的 `shoulders.pieces` 确实列出该件；
  3. 引用唯一：同一物理件在件集合中出现两次，或 `{id:件}` 出现两个不同实例同一 id；
  4. 连接宿主：连接式固缚的 `binding.parent_id` 能解析到件集合内的宿主。
- 「不猜不修」：不得就地改写 `root_id`／`shoulder_host`／id 来「让它一致」，也不得跳过坏边继续用其余边
  （跳过会静默改变结果）。
- 可见记录：每次作用域最多一条，含检查编号、边名、涉事 id；写在游戏实例上的独立诊断列表，
  **不得**写进 `_equipment_read`（既有断言要求它读写后为空），不进玩家日志／存档／UI，不做成计数器。
  记录不改变返回值：作废后该次调用所有查询结果必须等于「无索引」参照（`UncachedGame`）。
- **验证的边界**：不重写验证逻辑——`Game.validate`、`Prison.validate`、`Composites.validate`、`Links.validate`、
  `Shoulders.validate_host`、`SpecialEquipment.validate`、`Snapshot.check` 的判定与文本一行不改。
- **独立路径（不得依赖索引）**：存档／读档的「从原始 state 现算」路径由 `core/save_store.gd` 承担——
  存档前调用 `game.validate()`，读档前用全新探针 `Game.new(...)` 走 `restore_snapshot`（其内再调 `validate()`）；
  两处都在无作用域下调用。另有 `Game.validate` 保持 live（不接索引）与 `UncachedGame`
  （`_begin_equipment_read()` 返回 `{}`）。读档／存档前的完整性判断必须能在索引关闭时得出同样结论。
- **索引不得成为验证的唯一输入**：每条边都必须同时保留 live 实现（现算代码不删），
  架构套件里始终存在 index-on／index-off 的成对断言。
- 算未完成（任一）：作用域泄漏（调用后 `_equipment_read` 非空）；给豁免入口加了作用域；
  自检「就地修正」或跳过坏边继续用；`_equipment(id)` 被改成返回副本；
  `Game.validate`／存档路径接了索引；删除或弱化既有断言换取绿灯；
  改动规则数值／候选资格／存档／随机／文案／UI 响应路径／节键；新增运行时依赖或新增文件；
  以耗时或「应该更快」作完成判据，或用查询调用次数减少推导「显著提速」式结论。

## 证据入口

### oracle 与夹具

夹具（可复现序列；件数必须断言）：

```
battle   : tests/game_fixture.gd.new(42)      # 稳定遭遇夹具
departure: core/game.gd.new(42)               # 出货开局，departure 相位
0 件 : 不加
12 件: for slot in B.SLOTS: add_fixture(slot,7,10)
26 件: 再做一遍 12 件，然后 for slot in ["upper_arm","wrist","thigh"]: add_fixture(slot,7,10)
```

落地时必须断言：`physical_pieces().size() == state.equipment.size() == 0/12/26`，
`links == composites == special == 0`，`validate()==""`；与记录不符即夹具问题，先修夹具再看结果。

- 口径：`JSON.stringify` 后 sha256 只作快速指纹，**判定以逐字段比对为准**（`==` 深比较 + 首个差异路径）。
- 切片开始时必须用**未改源码**复算 `candidates()` 与 `get_view()` 的基线并记录（一致的哈希与原始值）；
  不一致以复算值为准并记录差异，**不得改基线去迁就实现**。
- 三路比对缺一不可：`当前（索引开）` == `当前（索引关／UncachedGame）` == `复算基线`。
- 基线捕获脚本只放已忽略的 `build/<topic>-<date>/`（本片为 `build/equipment-layers-20260915/`，
  含 `counters.json` 与 pristine 源码副本），用完删除；不入库、不留运行时钩子。
- 判据只用相等性与「每作用域每边建表 ≤1 次」（测试侧包装计数），生产源码不带计数器／计时钩子。
- **跨契约有效期**：整份 View 的相等性在 `docs/spec/ondemand-copy.md` 的按需投影落地后不再成立；
  重跑本片判据时改用该契约的 mask 判据与重算基线，两片都不得把对方批次或对方版本的通过拼进自己的结论。

### 分批与具名 check

新增 check 统一用 `INDEX` 前缀，落在该套件既有的 case 文件里（套件名 ↔ 文件见 `tests/test_game.gd` 的 `SUITES`）。

| 批 | 边／改动 | 该批命令（`-TimeoutSeconds 600`） | 该批也要过的具名 check |
| --- | --- | --- | --- |
| B1 | 部位→件 + 件集合全量物化 | `-Suite equipment` | `INDEX slot edge parity`、`INDEX targets edge parity`（`tests/equipment_cases.gd`） |
| B2 | id→件 | `-Suite architecture` | `INDEX id edge parity`（`tests/architecture_cases.gd`） |
| B3 | 点→件（容量、物理） | `-Suite equipment_complete` | `INDEX point edge parity`（`tests/equipment_complete_cases.gd`） |
| B4 | 根→组件 | `-Suite composites` | `INDEX root edge parity`（`tests/composite_cases.gd`） |
| B5 | 部位→绳、锚、目标清单 | `-Suite links` | `INDEX link edge parity`（`tests/link_cases.gd`） |
| B6 | 宿主→肩部件 | `-Suite shoulder` | `INDEX host edge parity`（`tests/shoulder_cases.gd`） |
| B7 | 连接 | `-Suite torso_binding` | `INDEX connection edge parity`（`tests/torso_binding_cases.gd`） |
| B8 | 谓词／计数（上表谓词全部） | `-Suite architecture,equipment` | `INDEX predicate parity`（architecture + equipment 各一条） |
| B9 | 「必须新开作用域的入口」全部 | `-Suite architecture,prison,events` | `INDEX entry parity`（`tests/architecture_cases.gd`） |

部位→目标边随入口物化，具名 check `INDEX targets edge parity`（`tests/equipment_cases.gd`）；`equipment_index_materializes_once_per_scope` 扩到该边。不新开 B 编号。

- 每批只加一类边，跑完该批一次 oracle 比对，红了可归因；`contact` 不是独立套件名（只作 `-Impact` 的跨域标签），
  B9 触及 `EnemyPlans`／`Contact`／`EquipmentOffers`／`SelfBinding` 的检查落在既有实例与套件里。
- 具名场景（每条 Given／When／Then 即实现与门禁的验收合同）：
  1. `equipment_index_edge_parity`：逐项调用上表每个查询（全槽位 `equipment_at`／`targets_at`（含 `"shoulder"`
     与特殊槽）、`physical_pieces`、`links_at`、`link_anchors`、`equipment_targets`、`action_targets`、
     每件 `_equipment(id)`、`capacity_used`、`_point_count`、`occupied`／`hand_blocked` 全槽位×两侧）
     → 与参照逐字段相等、数组顺序相等；`candidates()`／`get_view()` 与基线相等；`state` 与随机游标不变；
     退出后 `_equipment_read.is_empty()`。
  2. `equipment_index_materializes_once_per_scope`（测试侧计数包装）：同一作用域内同一边的不同键各查一次
     → 建表次数 ≤1、无重扫（含部位→目标边）；无作用域时不建表；清空或排序任一返回值不影响后续查询。
     具名 `INDEX targets edge parity`：作用域内／无作用域 `targets_at` 与 live 参照逐字段／顺序相等。
  3. `equipment_index_self_check_falls_back`：三种破坏夹具（组件 `root_id` 不一致、肩带 `shoulder_host`
     指向不存在的宿主、两条不同实例共用同一 id）→ 结果等于无索引参照；每次作用域恰好一条具名记录；
     `_equipment_read` 为空；状态、日志、存档无变化。
  4. `equipment_index_predicates_unchanged`：单手侧别件、`side=""` 件、`palm`／`fingers` 混合、
     复合／链接／特殊件夹具 → 索引开／关逐项相等（含手部真值表与原因文本）。
  5. `equipment_index_scope_entries_release`：逐个调用入口（含嵌套 `Prison.validate`）
     → 每个调用后 `_equipment_read` 为空、`state` 未变、返回值与索引关闭时一致。
  6. `equipment_index_entry_parity`：索引开／关运行 `EnemyPlans.targets`、`Contact.workspace`、
     `EquipmentOffers.preferred`／`for_pool`、`SelfBinding.tighten_targets`／`capacity`、
     `RoomEvents.selector_values`／`compile`、`Prison.enter`／`validate`、`Game._prepare_assembly`
     → 返回的 id 序列／槽位表／顺序／原因文本逐项相等。
  7. 边上取样（每批一条，落在对应套件）：部位→件与「第 N 条」名称、点→件与容量、根→组件与 `targets_at`
     拼接顺序、绳／锚／目标清单的耐久过滤差异、宿主→肩部件与 `0.000001` 过滤、连接清单只含连接式。
  8. `equipment_index_cast_keys_exact`：等价但键序不同的两个 profile、仅一个字段不同的两个 profile
     → 等价者只算一次、不同者各自不命中；结果与无索引参照相等；退出后无残留。

### 命令与人工路径

```powershell
& tools/check.ps1 -Suite architecture,equipment,equipment_complete,links,composites,shoulder,torso_binding,casting,prison,events,slip_motion -TimeoutSeconds 900
& tools/check.ps1 -UI -Suite architecture -UISuite equipment_complete,body_layout,shoulder,torso_binding -TimeoutSeconds 900
```

- 范围预检用同列表加 `-ListOnly`（输出 `PLAN ONLY:` 且列出上述套件；不算通过）。
- 判读：退出码 0；输出含 `RULE SCOPE:`、每个 `SUITE RESULT: PASS <name>`、`PASS: N assertions`；
  `summary.json` 的 `status=passed` 且 `before==after` 指纹（`source_changed` 不算通过）。
- 人的路径证明（判据是套件布尔 check，按顺序操作界面）：战斗中开身体栏点开普通件／带肩带件／复合组件与链接绳，
  文本与 View 一致；真实打出一张会损坏装备的牌，详情随实际状态更新；进入地图／事件／监室各一次不因作用域泄漏卡住。
- 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`；结果与域写验证记录
  （`docs/record/verification.md`，validator 负责，不在本文件宣称通过）。
- 必保留的既有断言：`tests/architecture_cases.gd` 的 `equipment_read_batches`、`equipment_projection_batches`、
  `preview_read_batches`，以及 `tests/equipment_ui_cases.gd` 的作用域读写后为空断言。

## 成本与收益上限

- 26 件 battle 相位一次完整 View 为 93–114 ms，其中全部装备查询合计约 6.5 ms：
  **本片的收益上限约 7%**。物化邻接表是正确性与结构的改进（一份真值、少一层重复扫描、红了可归因），
  **不是卡顿的解药**；任何「能显著提速」的表述都不许写。
- 真正的成本在文案与投影（`card_texts` 与候选 `detail`），属 `docs/spec/ondemand-copy.md` 的域；
  `escape_preview` 的按需化已由协调者裁决归入本片后续批次、**未排期**，排期确认前任何一片都不得实现。
- 完成判据只用相等性与「每作用域每边建表 ≤1 次」，不用耗时数字。

## 依赖与允许改动

- 允许改动：`core/game.gd`、`core/game_view.gd`、`core/enemy_plans.gd`、`core/contact.gd`、
  `core/equipment_offers.gd`、`core/self_binding.gd`、`core/room_events.gd`、`core/prison.gd`
  （仅加作用域进出或改内部取数），并在既有 `tests/*_cases.gd` 追加具名 check；不新增文件、不新增第三方依赖、
  不新建看板或流程文件，不新增计时钩子／计数器到生产源码。
- 不新增「每次调用都跑全图遍历」的路径：全图遍历只允许出现在作用域入口的建表里，每次作用域一次。
- 不新增 UI 可见行为、文案、动画；不改 `present`／`render`／`commit`、`ui/target_queries.gd`（行动行索引文件已在批 R5 删除）。
