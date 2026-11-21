# 事实表的「面 / 点」边界收口：依赖约束索引

「事实表的『面 / 点』边界收口」片（`docs/spec/candidate-removal.md`「接口」T4／T5／T8 之后的收口）的依赖约束索引：
**A 批（K0 分支词表＋K1 单元表）、B 批（K2 点查询的限定生产者：39 kind 各自一个域臂）、C 批（K3 点形家族一次构造：
一次走查直接产行）、D 批（K1 第二半：批内复用的唯一机制，整表／走查／逐卡行共用一条）与 E 批（K4 需求机制：
`get_view(demand)`＋需求闭包＋行过滤；K7 成功结果两个提交后只读标量）已落地**；
F（K5 接线）实现面＝UI 节→组声明、共享精确开合、失败退化、逐节读集与真实读取记录器、R-T8 槽位内容等值及前缀态画像；G（声明切片）未进入。四个 `get_view` 函数白名单不变；仅 `_submit` 的局部重建候选传声明需求，其余取全组。
判据的真源是下表点名的检查，散文不复述内容（规则见 `skills/spire-docs/SKILL.md`「判据优先」）。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

## 收口后的唯一入口（A＋B＋C＋D＋E；F 接线见需求声明）

| 语义 | 唯一入口 |
| --- | --- |
| 表出口 | `core/game.gd::command_facts`（唯一整表出口；D 批起批内只构建一次） |
| 表的组成（单元序列） | `core/command_registry.gd::FACT_UNITS`（单元表：id／order／owner／producer／groups／input） |
| 单元连接 | `core/game.gd::_join_fact_units`（唯一通道：按表序 `call(producer, facts)`；未声明单元不产行） |
| 阶段分支 | `core/game.gd::_phase_branch`（具名分支 id；`core/game.gd::_phase_facts` 与 23 项 kind 域臂共用） |
| 点查询的来源 | `core/command_registry.gd::ENTRIES[kind].source`（每 kind 一个域臂＝分支守卫＋该分支单元的最小生产者；B 批落地） |
| 点形家族的行构造 | `core/game.gd::attack_point_walk`（一次走查产出 `{params, row}` 成对结果；`core/game.gd::attack_point_keys` 与基础／装备自解两半的表生产者共用它）／`core/card_effects.gd::_card_point_rows`（card 域的一次走查，逐卡切片） |
| 点形家族的单行构造 | `core/game.gd::attack_point_fact`（attack 域）／`core/card_effects.gd::_card_point_row`（card 域：点查询与表 pass 共用同一实现） |
| 批内复用（D 批） | `core/game.gd::_batch_rows`（整表／攻击走查／逐卡行三条条目共用一条机制；寿命＝`core/game.gd::_begin_equipment_read` 的批次，出批即弃；不按键判等、不跨提交、不挂 `self`；命中与首算都返回深拷贝） |
| 行 → 组 | `core/game.gd::display_fact` 的 `fact.group=` 写入点（本批未改） |
| 需求（投影输入面，E 批 K4） | `core/game.gd::fact_demand_groups`（唯一闭包入口：`demand` ＋ 投影承接组 ＋ 入口守卫；`[]` 缺省与显式全组同一取值＝`core/command_registry.gd::fact_groups`） |
| 组 → 单元 | `core/command_registry.gd::FACT_UNITS` 的 `groups` 列（同一张表，不另立）；单元选择＝`core/command_registry.gd::fact_units_in_scope`（点名单元的组 ∩ 闭包，另含其 `input` 前置） |
| 行过滤（表的行面，E 批） | `core/game.gd::_fact_rows_in_scope`（唯一丢弃行的地方；`display_facts` 因此恒为全组行的纯子序列） |
| 投影承接组（闭包下限，E 批） | `core/command_registry.gd::VIEW_FACT_GROUPS`（`core/game_view.gd::build` 除 `display_facts`／`display_fact_scope` 外的键消费的组） |
| 新 View 键（E 批） | `core/game_view.gd::fact_groups_of`（`display_fact_scope`＝行面 `group` 的去重排序，可推导；追加在返回字典末尾） |
| 提交后过载标量（E 批 K7） | `core/pressure.gd::overloaded`（`Pressure.view` 的 `overloaded` 字段与 `core/game.gd::dispatch` 的成功结果共用它；归一化段的唯一依据） |
| 动工前冻结值（E 批起） | `tests/frozen-baselines.json`（外部锚定、只新增：A 批常量摘要、E 批 26 cell 的动工前内容（历史面，K4 不再重放）、2026-11-21 重冻批链节 C 的 PRE `baseline_pre_cells_c`（重冻前字面值＋被移动的非摘要记录路径原值）、`known_gaps` 的冻结清单；逐项锚定到提交哈希与文件 sha256） |

## 判据 → 检查

| 判据 | 执行它的检查 |
| --- | --- |
| 单元表 ↔ 测试内字面期望双向全量（owner 序／id／producer／input／order）；生产者都在 `core/game.gd` 上存在；连接通道唯一（源码文本）；每单元 input 指向同 owner 更早的单元；组列与实测行 group 值域双向一致；测试侧重放与 `core/game.gd::_fact_source`／`core/game.gd::_phase_facts` 逐字节相等 | `tests/architecture_cases.gd::fact_units_cover_fact_source` |
| 分支词表三处双向全量：`tests/architecture_cases.gd::PHASE_BRANCH_VOCABULARY`（字面表）↔ `core/game.gd::_phase_branch` 的 return 点 ↔ `core/game.gd::_phase_facts` 的 return 点；`core/game.gd::_phase_facts` 体内无条件链 | `tests/architecture_cases.gd::phase_branch_vocabulary_is_total` |
| G-1 历史冻结与 F 唯一 mask 增量 | `tests/architecture_cases.gd::baseline_constants_are_unchanged` |
| 缺省（无参）投影 == 显式全组投影逐字节；每个 cell 都带唯一新增 View 键 `display_fact_scope`；`core/game.gd::get_view` 的形参恰为 `demand` | `tests/architecture_cases.gd::default_projection_is_unchanged` |
| LPI 值面、纯子序列行面与两前缀态画像 | `tests/architecture_cases.gd::lazy_projection_invariant` |
| 组清点双向全量：表出口产出的行 group 值域 == 测试内字面组全集 == `core/command_registry.gd::FACT_UNITS` 的组列并集；每个声明组都能被至少一个单元覆盖；投影承接组 ⊆ 声明组全集 | `tests/architecture_cases.gd::fact_groups_are_total` |
| 接管／`card_chain`／`pending_retain` 的需求恒为全组：裁一个窄需求仍与全组构建逐字节相等；接管注入行仍在投影内；`R5_FIRST_TURN` 的逐 cell 摘要不变 | `tests/architecture_cases.gd::whole_table_branches_force_full_demand` |
| 成功结果两键：键面（含顺序）== 字面表（`tests/architecture_cases.gd::E_SUBMIT_KEYS`）；`phase` == 提交后 `state.phase`；`overloaded` == 同实例 `get_view().pressure.overloaded` == 守卫后的（`state.overloaded ∧ phase ∈ 战斗相位`）；失败结果键面仍是 `{ok,error,fact}`；成功结果的取值只来自 `state.phase` 与 `core/pressure.gd::overloaded`（源码文本，不由 `payload.kind` 或裸 state 标志反推） | `tests/architecture_cases.gd::submit_result_scalars_are_pinned` |
| 基线差异声明链（G-2 程序；自 2026-11-21 经人批准的重冻起只重放本批链节 C）：现值相对 `tests/frozen-baselines.json` 的 `baseline_pre_cells_c`（锚 `69cf2f1` 的测试文件；五个 R5 面与移动的 snapshot／rng＝重冻前（69cf2f1）字面值；被移动的非摘要记录路径（rows_payloads／logs／reject_invalid／submit_keys）＝a6fb649 提交树上的值，由 `<record>` 自证约束）的移动 ⊆ 声明且声明 ⊆ 移动（`tests/architecture_cases.gd::E_DECLARED_DIFF`＝链节 → 格 → 字段 → 原因，原因常量按归因组 A–F 加派生 `<record>`；表外移动或无移动的声明即红）；自证＝把声明内的记录路径换回 PRE 值后重算 `<record>`，逐 cell 等于 PRE.record（59 条路径中任一未声明的移动或携带的 PRE 原值有误即红）；`submit_keys` 两端按原因核对（POST＝`tests/architecture_cases.gd::E_SUBMIT_KEYS` 摘要，PRE＝去掉 `sound_feedback` 后的摘要）。E 批历史链节不再重放，其自证见 `docs/record/verification.md` 原条目 | `tests/architecture_cases.gd::baseline_diff_is_declared` |
| 缺省路径逐字节不变（26 cell 的 facts／verdicts／view／record 摘要） | `tests/architecture_cases.gd::behavior_baseline_equivalence` |
| 本片判据的突变证据存在；`known_gaps` 只许相对 A 批冻结清单缩短（新增条目即红）。冻结清单在**独立文件** `tests/frozen-baselines.json`（A 批审查缺口 3：不得与被核对的 `known_gaps` 同文件，否则同批加一条并同步改冻结值即可白名单化）；声明表里残留 `known_gaps_frozen` 即红 | `tests/architecture_cases.gd::mutation_evidence_is_total`＋`tools/check-mutation.ps1` |
| 全 39 kind 的双向等价：方向①（点查询 == 该 kind 表内首条 params 命中行）／方向②（变异 params 的接受集 == 表成员集）＋跨夹具成员语料（过宽臂在此层红）；表形 kind 跳 keys／member 步骤 | `tests/architecture_cases.gd::fact_lookup_all_kinds` |
| 域臂守卫只经 `core/game.gd::_phase_branch()` 取分支（扫域臂体，不扫 `_phase_facts` 体）；9 个 K0 之前的窄来源与 1 个恒空臂逐条豁免且双向核对 | `tests/architecture_cases.gd::domain_arm_guards_call_phase_branch` |
| 域臂守卫的**分支 id** 正确性两层判据：① 文本层（双向）每臂体点名的分支 id 字面恰等于 `tests/architecture_cases.gd::DOMAIN_ARM_BRANCH_IDS` 的声明集合（两臂互换守卫即红）；② 运行期：夹具矩阵上臂行 ⇒ 分支 ∈ `tests/architecture_cases.gd::DOMAIN_ARM_ROW_BRANCHES`，且每个声明分支必须被观测到行或登记进 `tests/architecture_cases.gd::DOMAIN_ARM_ROW_BRANCHES_UNOBSERVED`（双向，登记行不许腐烂） | `tests/architecture_cases.gd::domain_arm_branch_ids_are_pinned` |
| 整表来源不再是点查询的答案：登记表文本无整表来源名；每个 table kind 的臂体（含被调 helper 白名单 `tests/architecture_cases.gd::TABLE_ARM_HELPERS`，双向核对）不调整表形态（`tests/architecture_cases.gd::TABLE_ARM_WHOLE_TABLE_CALLS`＝`_fact_source`／`command_facts`／`_join_fact_units`／`_phase_branch_units`）；23 项绑定各自的域臂；kinds／arms 规模为断言（`tests/architecture_cases.gd::POINT_SOURCE_TABLE_KINDS`／`POINT_SOURCE_DOMAIN_ARMS`／`POINT_SOURCE_ARMS_TOTAL`） | `tests/architecture_cases.gd::point_sources_are_kind_limited` |
| 点查询不建整表：可行动期每条（去重后的）表行做一次 `command_fact`，整表出口与三个连接入口（`_fact_source`／`command_facts`／`_join_fact_units`／`_phase_branch_units`／`_phase_facts` 直调）计数全为 0；接管期声明豁免＝1；唯一一处相位单元豁免（`tests/architecture_cases.gd::POINT_LOOKUP_PHASE_UNIT_EXEMPT`＝`end`×`overload_climax`）恰为 1 且必须被观测到；23 项里至少 15 项命中非空行 | `tests/architecture_cases.gd::point_query_builds_no_table` |
| 分支/前缀态的行面按动工前值冻结（63 态：13 相位 × plain／relic_bundle／departure／domain_blocked ＋ 十一个状态标志分支），前缀零移动在仓库内可重放；冻结值只在提交树上取数，出处 sha256＝取数提交的 `core/game.gd` git blob 原始字节（`git show` 输出，LF；2026-11-21 重冻批在 `69cf2f1` 重算 `flag:equipment_spell`／`flag:relic_rows` 两态），与字面状态数一起写进常量（`tests/architecture_cases.gd::PREFIX_BRANCH_TABLE_SOURCE_SHA256`／`PREFIX_BRANCH_TABLE_STATE_COUNT`），扫描规模＝基线规模＝字面状态数（删一态并同步删基线即红） | `tests/architecture_cases.gd::prefix_branch_tables_are_frozen` |
| 点形家族表 pass 每行恰构造一次（计数子类按 payload 逐家族对照返回行集；单卡夹具的槽位问询面＝一卡一次走查） | `tests/architecture_cases.gd::table_rows_constructed_once` |
| 点形家族表生产者只有一个走查入口（源码文本：三处生产者体内各恰一次，且不出现「先取键再构造」两步形态；走查／keys／build／member 各一处实现） | `tests/architecture_cases.gd::table_walk_single_entry` |
| 批次语义：测试侧持批时三个点形生产者与无批次逐字节相等且攻击走查恰一次；出批后改状态再调用必须按新状态给值（不陈旧） | `tests/architecture_cases.gd::point_family_rows_respect_read_scope` |
| 整表批内复用：同一批次内三次取用只构建一次、`core/game.gd::_fact_source` 一次，表的唯一出口在同一批次内命中同一条目；出批后下一次读取必重建；被拒提交不留可复用条目、拒绝文案逐字不变 | `tests/architecture_cases.gd::fact_table_reuse_within_batch` |
| 缓存寿命＝批次（文本层）：条目容器只被 `core/game.gd::_batch_rows` 读写；机制体只见批次字典（无 `self`／`set_meta`／`is_same`／`version`／`state`）；条目名只在声明的调用点；`core/game.gd::command_facts()` 只被 `core/game_view.gd::build` 调用；`core/game.gd::dispatch` 的投影取用只在 `state=state.duplicate(true)` 之前；`get_view()` 仍是四点白名单（同批复跑既有判据） | `tests/architecture_cases.gd::fact_table_cache_lifetime_is_pinned` |
| 复用路径 == 从零路径：真实输入配方（seed=7／cap=60／style=trade）逐提交与 `export_snapshot`→`restore_snapshot` 的从零实例逐字节相等（含批内两次取用）；oracle 自检＝restore 后除声明的版本推进外 state 逐字节相等 | `tests/architecture_cases.gd::table_reuse_matches_fresh_projection` |
| 复用／取用边界不可污染：三条批内条目各自「批内取回的行被调用方改写后，同批第二次取用仍等于从零路径」；重复归一化 params 的行是互不别名的独立等值字典（attack 走查） | `tests/architecture_cases.gd::batch_reuse_never_aliases_callers` |
| 走查行的空行面：两条表生产者的取行都保留改动前的 `is_empty` 过滤（文本＋顺序），且 `core/game.gd::attack_point_walk` 在全部夹具上产出的每条 `{params,row}` 的 row 都是完整行（过滤今天不吞任何行；基础／巫女／装备自解三家族覆盖 > 0） | `tests/architecture_cases.gd::walk_rows_are_never_empty` |
| kind → table 来源的身份字面冻结（23 项已 rebase 到域臂；少改／多改都红） | `tests/architecture_cases.gd::fact_source_map_is_pinned`、`tests/architecture_cases.gd::pipeline_lookup_inspect` |
| 单元生产者不得写判定、不得推进随机（只读面） | `tests/architecture_cases.gd::single_eligibility_implementation`、`tests/architecture_cases.gd::behavior_baseline_equivalence` 的 `rng`／`rng_total` 逐 cell |

## 需求声明（F）

| 判据 | 执行它的检查 |
| --- | --- |
| C-F-1 需求声明受钉（声明⊆读集＋未声明读组登记理由＋有效 scope 真子集差集冻结＋open_items 分支源文本钉）与单入口闭包 | `tests/architecture_cases.gd::demand_declarations_are_total` |
| C-F-1 core 词汇边界扫描非空 | `tests/architecture_cases.gd::demand_core_source_is_nonempty` |
| C-F-2 逐节源码读集（含节键） | `tests/architecture_cases.gd::section_read_sets_are_pinned` |
| C-F-3 实际读取与全组同值 | `tests/display_ui_cases.gd::present_demand_recorder` |
| C-F-2 逐域真实读集覆盖 | `tests/display_ui_cases.gd::section_read_sets_runtime` |
| C-F-3 观察边界、还原与副本隔离 | `tests/display_ui_cases.gd::read_observer_boundaries` |
| C-F-3 debug/未装无观察成本与无叶绕过 | `tests/architecture_cases.gd::target_queries_read_observer_is_debug_only` |
| C-F-4 source差异与非空dirty完整回落 | `tests/display_ui_cases.gd::submit_full_fallback_uses_source` |
| C-F-4 四点实参与共享开合；C-F-5 监狱页组查询 | `tests/architecture_cases.gd::submit_demand_call_sites_are_pinned` |
| C-F-6 逐字契约文本 | `tests/architecture_cases.gd::contract_text_is_updated_verbatim` |
| C-F-6 历史 PRE 正向单项差集与逆向复算 | `tests/architecture_cases.gd::baseline_constants_are_unchanged` |
| C-F-6 View 累计与 F 增量键面 | `tests/architecture_cases.gd::default_projection_is_unchanged` |
| C-F-7 F cell 增量零移动（E 历史自证降为记录：`docs/record/verification.md` 原条目） | `tests/architecture_cases.gd::behavior_baseline_equivalence` |
| C-F-8 等 size 非全组不得污染整表槽位 | `tests/architecture_cases.gd::command_facts_full_scope_is_content_equal` |
| C-F-9 两前缀态 × 全部需求画像 | `tests/architecture_cases.gd::lazy_projection_invariant` |

| 语义 | 唯一通道 |
| --- | --- |
| UI 节→组（需求声明，修复批 G2 分表） | `ui/main.gd::PRESENT_DEMAND`（需求声明不是读集名册：每节行 ⊆ `tests/architecture_cases.gd::SECTION_READ_SETS` 同节行；未声明的读组由测试内登记理由承接——理由=VIEW ⇒ 组 ∈ `core/command_registry.gd::VIEW_FACT_GROUPS` 恒在闭包 scope，理由=page ⇒ 节=page 走全组回落；理由表＝`tests/architecture_cases.gd::F_DEMAND_EXCLUSIONS`，有效 scope＝声明并集 ∪ 承接组，与组全集的差集冻结为 `tests/architecture_cases.gd::F_DEMAND_SCOPE_DIFFERENCE`）；读集冻结与运行期期望仍＝`tests/architecture_cases.gd::SECTION_READ_SETS` |
| 需求求值 | `ui/main.gd::_present_demand` → 节声明并集（raw 并集不含 `item`，pack 开抽屉的 item 由 `_submit_opens` 的 open_items 分支承载）＋共享开合；仅失败追加 `ui/main.gd::PHASE_OPEN_DEMAND` |
| 成功结果的精确开合 | 需求求值与 `_submit` 归一化 → `ui/main.gd::_submit_opens` → phase／overloaded；执行关抽屉／pack 开物品 |
| 四个投影调用函数／五条调用语句 | `_resume_snapshot`／`render` 空快照／`restart` 各一条取全组；`_submit` 初投声明需求或全组，完整 fallback 需要时仅经既有第二条回取全组（1/1/2/1） |
| 完整 fallback | `_submit` 求 dirty 后与 `present` 共用 `ui/main.gd::_present_needs_full_render` 的 source 决策，局部展示不复制条件链 |
| 真实读取观察 | `ui/target_queries.gd::facts`／`fact_by_key` → 唯一 `_debug_observe_read` → 测试独占Callable；debug交换入口 `debug_exchange_read_observer`，release或无观察者不捕栈/复制 |
| 记录生命周期 | 原 `tests/recipe_driver.gd::_run_recipe` → 动态display begin/snapshot/end；原 `_drive` 动作体不变；独立oracle在还原Callable后核 |
| 逐节归属 | `tests/architecture_cases.gd::SECTION_BODIES`／`SECTION_BUILDERS` → `f_main_owners`，静态跨节与真实栈消费同源；target_drag是独立交互，不入present节声明 |
| 突变执行 | `tools/check-mutation.ps1` 规范化execution并唯一委托 `tools/check.ps1` 原rules/ui/recipe阶段，目标原summary/log判RED与逐字节还原 |
| 组→单元及前置关系 | `core/game.gd::fact_demand_groups` → `core/command_registry.gd::fact_scope`／`fact_units_in_scope` → 单元表生产通道 |
| 整表槽位 | `core/game.gd::command_facts` 的 scope 内容等于 `core/command_registry.gd::fact_groups` 才经批内条目 |
| 监狱页取行 | `ui/main.gd::_prison_location_details` → `ui/target_queries.gd::facts`／`select` 的 prison／item 组 |
| 遗物条与节键 | `ui/main.gd::_relic_row`／`_relic_presentation_key` → 同一 relic 组查询 |

实际 F 实现文件面：`core/game.gd`、`ui/main.gd`、`ui/target_queries.gd`、`tests/architecture_cases.gd`、`tests/display_ui_cases.gd`、`tests/recipe_driver.gd`、`tests/ui_smoke.gd`、`tests/mutations.json`、`tools/check-mutation.ps1`、本索引、`docs/spec/response-pipeline.md`、`skills/spire-architecture/SKILL.md`；`tests/frozen-baselines.json` 的历史面零改动。正式证据由后续阶段追加 `docs/record/verification.md`，不属于本实现提交的文件面。

## 允许的依赖方向

- `core/game.gd` → `core/command_registry.gd`：允许；单元表只存 `g` 上的方法名与字面数据（零 preload、无 Callable）。
- 单元生产者只写在 `core/game.gd` 上，签名 `(facts: Array, groups: Array = []) -> Array`；`facts`＝本单元之前已累积的表，
  `groups`＝需求闭包（空＝不裁剪；E 批 K4 起的目标通道，只有 `core/game.gd::_unit_phase` 往下透传）；
  连表只经 `core/game.gd::_join_fact_units`（表外不追加任何行）。
- 需求（E 批 K4）：需求只决定**哪些单元被构建**（`core/command_registry.gd::fact_units_in_scope`）与**哪些行外放**
  （`core/game.gd::_fact_rows_in_scope`，唯一丢行点）；闭包只有一处实现（`core/game.gd::fact_demand_groups`），
  接管／`card_chain`／`pending_retain` 三支由该入口取全组（调用方预知不到，见 `docs/spec/response-pipeline.md` 接缝 A 的
  `game.get_view()` 行）；缺省 `[]` 与显式全组是同一语义、同一条路径（不是两条路径，也不是特权模式）；
  批内条目（`BATCH_TABLE`）的槽位义＝整表，故只有全组走批内条目，裁剪需求每次现算、不占该槽位。
- 投影承接组（`core/command_registry.gd::VIEW_FACT_GROUPS`）是需求闭包的**下限**：闭包必须至少含这些组，
  否则 `core/game_view.gd::build` 的其它键会被裁剪改写（`tests/architecture_cases.gd::lazy_projection_invariant` 的 LPI 面）。
- 提交后两标量（E 批 K7）：`core/game.gd::dispatch` 的成功结果只带**提交后状态的只读标量**；
  过载态的唯一定义处是 `core/pressure.gd::overloaded`（`Pressure.view` 与 `dispatch` 共用），不得复制条件式、
  不得由 `payload.kind` 反推、失败结果键面一字不动。
- `core/game.gd::_phase_branch`：只读——不写 `state`、不推进随机、不改 `version`。
- 域臂（`core/game.gd::_chain_kind_facts` 一族，`ENTRIES[*].source` 的取值）× 分支守卫：只经 `core/game.gd::_phase_branch()`
  取分支 id；不得复制 `core/game.gd::_phase_facts` 的早退链，也不得回落 `core/game.gd::_fact_source()`／`core/game.gd::command_facts()`。
- 域臂的生产者＝`core/command_registry.gd::FACT_UNITS` 里该分支的单元生产者（休息／奖励／旅途复用同一单元生产者，
  不写第二份实现）；点查询路径与整表出口共用同一批生产者，故两者不可能各自漂移。
- 点形家族（attack／card）的表 pass 只经一次走查取行（`core/game.gd::attack_point_walk`／`core/card_effects.gd::_card_point_rows`）；
  候选键枚举（`core/game.gd::attack_point_keys`／`core/card_effects.gd::card_point_keys`）与两半表生产者共用同一次走查，
  单行构造（`core/game.gd::attack_point_fact`／`core/card_effects.gd::_card_point_row`）仍是点查询的唯一构造器，member 仍独立。
- 批内复用的唯一机制是 `core/game.gd::_batch_rows`（D 批）：整表（`core/game.gd::command_facts` 的条目
  `BATCH_TABLE`）／攻击走查（`core/game.gd::attack_facts`／`core/game.gd::attack_point_keys`／
  `core/game.gd::equipment_spell_facts` 的条目 `BATCH_ATTACK_WALK`）／逐卡行（`core/card_effects.gd::card_facts`
  的条目 `BATCH_CARD_ROWS:<uid>`）都只经这一条入口取用；条目只落在 `core/game.gd::_begin_equipment_read`
  的批次字典上，出批即弃，禁止按键判等、禁止跨提交、禁止挂 `self`；**命中与首算都返回深拷贝**（批次内的
  存量不外借，`core/game_view.gd::build` 的就地写碰不到它）；批次外调用每次现算（退化等同改动前）。
- 不新增依赖边；core／data 不 preload ui；本批不新增 View 键、不新增存档字段、不改提交事务与判定语义。

## 不可独立增量（显式登记）

读已累积表的单元与宽切片单元不得开切片复用（G 批不得触碰）：`relic_bundle_consumables`／`departure_consumables`／
`noncombat_consumables`（按 payload.kind／item 去重）、`route`（读累积表的出口行＋现算 `core/game.gd::room_entry_reason`）、
`relic_effects`／`hand_cards`／`prison`／`events`／`services`。任何"按本次提交的 kind 决定复用"的做法同禁。

## 仍靠人审（无机械判据，A 批保留；B／C／D／F 续登）

### F 的测试侧 display_facts 读者清点

下表是读取域与覆盖理由，不把裁剪视图冒称整表 oracle。规则读者保留无参全组路径；UI 全表比较只在 restart／全组 render 取得的视图上成立。无需为同值性改绿而迁移读者；新增读者或组仍须独立审查覆盖面。源码扫描范围为 `tests/`，交付报告保留精确命中索引。

| 读者/接口 | 读组/域 | 当次投影包含理由 |
| --- | --- | --- |
| `tests/architecture_cases.gd` 的冻结、表复用与点表比较；`tests/basic_attack_cases.gd`、`tests/battle_reward_cases.gd`、`tests/enemy_cases.gd`、`tests/equipment_cases.gd`、`tests/equipment_complete_cases.gd`、`tests/fire_dynamics_cases.gd` | 全表，或 attack／flow／reward／card／manual | 都由规则侧无参 `get_view` 取得全组；画像裁剪比较另以显式全组行构成期望 |
| `tests/display_ui_cases.gd` 的 R3/R4/R5 比较与接管 | 分域全集、接管全部 | 独立夹具无参投影；接管入口强制全组，既有冻结/锁定断言未放宽 |
| `tests/display_ui_cases.gd` 的提交/行动/姿态/舞台探针 | attack／flow／posture／wall_move／pressure，拒绝探针的全部已见行 | 节声明覆盖前五组；拒绝与接管夹具由 restart 全组进入，后续逐节真实读取仍须记录器验证 |
| `tests/ui_smoke.gd` 的 click／拖牌助手；`tests/normal_play_cases.gd::choose` 与 `tests/normal_play_ui_cases.gd` | 玩家可见事实全集、攻击形态 | 战斗声明并集加核心承接组覆盖战斗可行动族；非战斗与进出战斗取全组。策略只消费可见投影，不作为整表 oracle |
| `tests/route_driver.gd::event_action` 的 `tests/ui_smoke.gd` 调用；`tests/event_ui_cases.gd` | event | 非战斗事件页取全组 |
| `tests/exploration_ui_cases.gd`、`tests/prison_ui_cases.gd` | prison／item | 监狱页与提交全组；page 的 prison／item 声明保留 |
| `tests/enemy_feedback_ui_cases.gd`、`tests/guard_ui_cases.gd`、`tests/enemy_ui_cases.gd`、`tests/tower_progression_ui_cases.gd` | flow／attack，可用下一步 | flow 属核心承接组；attack 属行动/舞台节声明；非战斗下一步取全组 |
| `tests/impact_feedback_ui_cases.gd`、`tests/pressure_ui_cases.gd` | status_toggle、战斗行动（排除 flask/item_discard） | status_toggle 与战斗行动组均在节声明并集 |
| `tests/home_ui_cases.gd`、`tests/home_persistence_ui_cases.gd`、`tests/persistence_ui_cases.gd` | 出发全表、合法/旧版本首行 | restart／恢复路径取全组 |
| `tests/installed_tools_ui_cases.gd` | 当前视图与 command_facts 全表比对 | 只在 restart 后无提交取得全组时比较，非裁剪状态 |
| `tests/localization_ui_cases.gd`、`tests/route_ui_cases.gd` | 事实副本守恒，不枚举未见组 | 对比同一视图的本地选择前后，无新的 get_view；不依赖全表身份 |
| `tests/target_sidebar_ui_cases.gd` | 合成TargetQueries数据、attack | 合成查询单测不经过投影；真实攻击来自节声明，r4比较来自规则夹具全组 |

残留：源码文字扫描不能证明将来新增的动态组读者完备；真实配方与逐节夹具之外的新路径由独立审查承接。F 不把少量UI提交或声明重放当真实60读取证据。

- **`core/game.gd::_phase_facts` 直呼的语义残差**：其三个前缀臂（relic_bundle／departure／domain_blocked）落回尾段；
  改动前该函数在这些状态会命中链内的相位分支。可达面：三个前缀由 `core/game.gd::_fact_source` 先行解析，
  `core/game.gd::_flow_kind_facts` 带域守卫，`core/game.gd::_depart` 在前缀表上不可达，路线理由只消费出口行；
  实测（A 批差分探针，`build/` 目录，不随提交）＝90 个状态里表出口面逐字节相等，仅 6 个前缀状态 × 直呼
  `core/game.gd::_phase_facts`（rest_choice／reward／travel × relic_bundle／domain_blocked）不同，且都不在生产调用路径上。
  **B 批起表出口面的前缀零移动已在仓库内可重放**（`tests/architecture_cases.gd::prefix_branch_tables_are_frozen` 冻结
  63 个分支/前缀态的行面摘要）；上面这条直呼残差仍只由差分探针实测，不在仓库内重放。
- **豁免与恒空臂**：9 个 K0 之前的窄来源（`tests/architecture_cases.gd::PHASE_BRANCH_ARM_EXEMPT`）与 1 个恒空臂
  （`tests/architecture_cases.gd::BATCH_ARM_GUARDLESS`，`core/game.gd::_relic_control_done_kind_facts`）逐条登记并双向核对
  （列错即红）；但「臂在夹具矩阵之外的分支是否真的不产行」只由该矩阵与覆盖断言保证，无全机械证明。
- **域臂分支 id 的运行期未见观测项（B 批审查条目 2／4 收口）**：`tests/architecture_cases.gd::DOMAIN_ARM_ROW_BRANCHES_UNOBSERVED`
  逐条登记矩阵里观测不到行的 (臂, 分支) 对——`core/game.gd::_depart_kind_facts` 在 `shop_treasure`／`event` 两分支的出口行
  需要「服务／事件已产出离开行」的夹具，本矩阵（26 cell 的 0／12 ＋ 63 个分支态）没有；判据双向核对（观测到即表示该登记行过期）。
  这两个分支的守卫字面由文本层钉住，**行面无机械证据**。
- **9 个 domain 合成守卫的窄来源**：`tests/architecture_cases.gd::DOMAIN_ARM_DOMAIN_GUARDED`（＝`tests/architecture_cases.gd::PHASE_BRANCH_ARM_EXEMPT`）
  不吃分支 id 判据——它们的守卫是域合成条件（`core/game.gd::_fact_source_domain`／`core/game.gd::_phase_action_tail`／`core/game.gd::command_domain_ready`）；
  行面只由 `tests/architecture_cases.gd::fact_lookup_all_kinds` 的「臂行 ⊆ 表行」与覆盖断言保证。
- **批内条目的寿命（D 批）**：由 `tests/architecture_cases.gd::fact_table_reuse_within_batch`（持批／出批＋被拒提交）、
  `tests/architecture_cases.gd::fact_table_cache_lifetime_is_pinned`（源码文本：容器只被机制读写、条目名只出现在声明调用点、
  机制体不见 `self`／`set_meta`／`is_same`／`version`／`state`）与 `tests/architecture_cases.gd::table_reuse_matches_fresh_projection`
  （真实配方 60 提交逐字节 vs 从零实例）三层钉住。**残留**：「以后会不会有人把某条新条目接到第二条容器上」只由
  `core/game.gd::_batch_rows` 的文本事实与条目名文本判据兜底，无全机械证明；`core/game_view.gd::equipment_entry` 的
  `equipment_views` 是另一条独立接缝（`docs/spec/equipment-query-seam.md` 的批次），本批不并入。
- **从零 oracle 的覆盖面**：`tests/architecture_cases.gd::table_reuse_matches_fresh_projection` 每提交新建从零实例
  （否则两侧会一起读到同一个陈旧值）；因此它钉的是「条目在 live 实例上跨批存活」。**类级（`static`）常驻缓存
  不在它的面内**（两侧会一起读到它），那一条由 `tests/architecture_cases.gd::fact_table_reuse_within_batch` 的
  「出批必重建」与 `tests/architecture_cases.gd::point_family_rows_respect_read_scope` 的跨批次变异承接。
- **card 域的重复归一化 params 行独立性**：`tests/architecture_cases.gd::batch_reuse_never_aliases_callers` 的重复行部分
  只覆盖 attack 走查（既有 `tests/architecture_cases.gd::attack_duplicate_params_fixture` 给出可辨认的重复 params 对）；
  card 域现有重复夹具（`tests/architecture_cases.gd::card_duplicate_params_fixture`）产出的两条行内容不同，无法用内容分组
  辨认同一 params 对，故 card 侧的 `core/card_effects.gd::_card_point_rows` 重复行独立性**无机械证据**——它与 attack 侧
  同写一次（`(first[key] as Dictionary).duplicate(true)`），由该函数的文本与本题人审承接；card 侧的批内污染面由
  上述同一判据的①（三条条目各自「批内改写后同批第二次取用」）覆盖。
- **走查行的空行面**：`tests/architecture_cases.gd::walk_rows_are_never_empty` 同时钉「两条生产者的取行保留
  改动前的 `is_empty` 过滤」（文本）与「走查产出的 row 非空」（在全部夹具上）；但「未来新增家族在夹具矩阵
  之外回 `{}`」不在机械判据内（矩阵外的分支无夹具），只由该过滤与本题人审承接。
- **点形家族点查询路径的构造次数**：点查询（`core/game.gd::attack_point_fact`／`core/card_effects.gd::card_point_fact` 族）仍各自走
  单行路径且不进批内条目；`tests/architecture_cases.gd::attack_point_lookup_reads_one_row`／`tests/architecture_cases.gd::card_point_lookup_reads_one_row`
  只钉「不经整表生产者」与「member 独立」，不钉点查询自身的构造次数（无机械判据）。
- **组列观测夹具的覆盖上限**：`tests/architecture_cases.gd::FACT_UNIT_GROUP_UNCOVERED` 逐条登记矩阵里观测不到的
  (单元:组) 对（A 批为 chain 相关两项，需牌链夹具）；判据双向核对（列出的必须真的观测不到），豁免不能腐烂。
- **单元表的完备性**：新增一个生产者而不登记，由源码文本判据（表外第二处追加点）与 G6 行面兜底；
  表自身"少声明一个单元"由测试内字面期望与实测组列抓。
- **需求闭包下限的完备性（E 批）**：`core/command_registry.gd::VIEW_FACT_GROUPS` 由 `core/game_view.gd::build`
  的跨组消费点逐条推出（`docs/spec/response-pipeline.md` 的 `game.get_view()` 行列出判据名），
  并且 LPI 判据（`tests/architecture_cases.gd::lazy_projection_invariant`）在 26 cell × 6 画像 ＋ 配方 60 提交上
  断言「除 `display_facts`／`display_fact_scope` 外每个 View 键与全组构建逐字节相等」。**残留**：矩阵之外的相位
  （如 `reward`／`pack`／`travel` 的奖励面板路径）若某 View 字段消费了未登记的组，LPI 抓不到；
  该面只由上述消费点清单与本题人审承接。
- **单元级惰性的证据面（E 批）**：E 批没有计数判据断言「未被点名的单元生产者不被调用」（计数判据属 D 批的
  `BATCH_TABLE`／`BATCH_ATTACK_WALK`／`BATCH_CARD_ROWS`）；单元选择由 `core/command_registry.gd::fact_units_in_scope`
  的文本事实（组 ∩ 闭包 ＋ `input` 前置）与行面判据间接保证，无直接计数证据。
- **冻结域**：有效排除集只留 `tests/architecture_cases.gd::R3_VIEW_MASK`；历史 PRE（A 批常量摘要、E 批 26 cell）仍在 `tests/frozen-baselines.json` 原位不改，该文件只新增（2026-11-21 重冻批链节 C 的 PRE 与锚）。F 对 E／T 入口的 cell 字段增量为零；`tests/architecture_cases.gd::baseline_diff_is_declared` 只重放链节 C（双向声明与逆向自证），E 批历史 26 个 record 差异的自证降为 `docs/record/verification.md` 原条目。独立审查应核对历史 PRE 未被替换为 POST，并核对链节 C 的 PRE：五个 R5 面与移动的 snapshot／rng＝重冻前（69cf2f1）字面值；被移动的非摘要记录路径（rows_payloads／logs／reject_invalid／submit_keys）＝a6fb649 提交树上的值，由 `<record>` 自证约束。锚 blob 自检不替代语义逆向证明。
- **core 节名泄漏扫描的扫描面残差（修复批 G7）**：`tests/architecture_cases.gd::demand_declarations_are_total`
  的 core 文本扫描面＝15 节中可机械扫描的 11 个（`header`／`actions`／`resources`／`notice`／`page`／`show_log`／
  `body_bar`／`body_details`／`pickers`／`drawers`／`scene_instances`，quoted 字面匹配）；其余 4 节与 core 自身词汇
  撞形、机械扫描即误报，泄漏与否只由人审承接——`posture` 与组名同形（`core/command_registry.gd` 组列含
  `posture`），`relics`／`hand`／`speech` 与 core 自身 state／View 键词汇同形（如 `core/game_view.gd` 的
  `"relics"`／`"hand"`／`"speech"` 键）。`PRESENT_DEMAND`／`PHASE_OPEN_DEMAND`／`PRESENT_SECTIONS`
  三个表名的缺席检查仍覆盖全部 15 节的表级泄漏。
- 不属于本片授权面：推送／打标签、打包；改 `project.godot` 与导出预设；改 `tools/check.ps1`／
  `tools/check-docs.ps1`／`tools/doc-scan-scope.ps1` 与其允许清单。
