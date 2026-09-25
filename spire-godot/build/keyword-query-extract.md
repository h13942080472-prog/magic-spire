# 规划者契约：card_facts 消费 keyword_ids 最小查询

状态：切分已批，可交实现者。**无新模块、无新允许边**（扩既有 `card_effects` → `g.B` 与 `balance` → `card_text`），不标 `needs-human-review`。HEAD `8b4cb89`。域：`core/card_effects.gd::card_facts` 用 PR #9 `keyword_ids`＋既有 `SPECS.target_slots`／`Rules.face_mode` 决定是否／对哪些槽做装备收集；`Game.get_view` → `View.build` → `command_facts` → `card_facts` 变便宜是因为生产者少问。默认投影仍全开。越权未提交补丁已丢弃，禁止还原。本刀不写 `docs/spec`。

## 已有入口（扩展，不建第二套）

- `data/card_text.gd::keyword_ids(type, free, traits) -> Array`：TERMS 键，顺序＝`keywords()`。`keywords()` 只调它一次。**不要**给 `face_keywords`／`TERMS` 加 `id`。
- 槽／模式：`Rules.SPECS[type].get("target_slots", [])`、`Rules.face_mode(type, free)`。`card_facts` 槽循环已按这两处走声明槽，并已对将 `targets_at` 的槽先问 `Game.has_targets_at`。
- `g.B`＝`data/balance.gd`。`card_effects` 已用 `g.B.card_metadata`／`CARD_TRAITS`；`card_metadata` 已 `preload("res://data/card_text.gd").metadata`。**没有** `card_effects` → `card_text` preload。
- `Game.get_view` 仍 `_begin_equipment_read`＋`View.build` 全枝；`View.build` 现先 `command_facts()`（内含每张手牌 `card_facts`）。不收窄 `build` 枝，不新开 `present` 节。

## 切分、接口和依赖

- 在 `balance.gd` 增加与 `card_metadata` 同形的转发：`keyword_ids(type, free) -> Array`，内部 `card_text.keyword_ids(type, free, CARD_TRAITS.get(type, {}))`。`card_facts` 只经 `g.B.keyword_ids`（traits 不得另抄一份）。禁止 `card_effects` preload `card_text`；禁止新模块、新 `present`、改 `View.build` 枝集合。
- `card_facts(g, card) -> Array`：在**现有槽循环之前**读该牌 bound＋free 的 `g.B.keyword_ids`、`spec.target_slots`、`Rules.face_mode`。收集是否需要＝`spec.has("target_slots")` **或** 两面 ids 与「装备收集键」有交：即 `keyword_ids` 已会为拘束面发出的 TERMS 键（`TERMS.has(face_mode)` 的 mode：`strain`／`slip`／`magic_slip`／`lower`／`unlock`）以及 `follow_through`。该键集只是对已有 ids 的过滤，禁止平行再走 SPECS／效果／`term.name`。无交且无 `target_slots` → **不得**进入槽循环（不得 `has_targets_at`／`targets_at`／该循环内 `occupied`）。`self_faces`／`single_face`／`free_slots` 的既有事实生产保留；自身事实仍先于槽循环。
- 需要收集时：槽循环规则与本刀前相同（声明槽先 `has_targets_at` 再 `targets_at`；无表牌每槽 `declared==true`；表外占用 `occupied` continue；空普通槽 `{}`；事实＝`card_facts_union_slot_oracle`）。不得复制 `_visit_targets_at` 过滤，不得用 `occupied` 判空，不得把 `has_targets_at` 写成 `targets_at(slot).is_empty()`。
- 允许实现面：`spire-godot/data/balance.gd`（仅上述转发）、`spire-godot/core/card_effects.gd` 的 `card_facts` 槽循环门控、`spire-godot/tests/architecture_cases.gd` 的单个具名场景／`run` 注册。不得改 `core/game.gd` 走查、`core/game_view.gd::build`、`reason`／`has_escape_target`、`data/card_text.gd` 收集器、UI、`docs/spec`。实现若必须 preload `card_text`、新模块、收窄默认 `View.build`、或无法保持事实形状 → `needs-human-review` 并停下。

## Gherkin：`card_facts_keyword_min_query`（一个可观察行为）

Given `tests/architecture_cases.gd` 的 `TargetsAtCountingGame.new(42)`（生产无计数器），`state.phase=="battle"`。钉三张：无 `target_slots` 的 `strain`（bound ids 含 `"strain"`）；有表 `strong_elbow`；无表且 ids 不含装备收集键的 `pot_of_greed`（可同夹具再钉 `mana_search`）。夹具：四类装备清空；`copy_baseline_fixture` 同形的 12 件占用；以及 `has_targets_at_parity` 已用的单侧 `palm`。Oracle＝`card_facts_union_slot_oracle`（`strain`／`strong_elbow`）或本刀前 `card_facts` 快照（`pot_of_greed` 自身事实）。先算 oracle／快照／`state.rng`，再清零 `targets_at_slots`。改 `TERMS.strain.name` 后再调一次（测后恢复）。
When 对各夹具调用 `g.Cards.card_facts(g,card)`。
Then `strain` 空装：`targets_at_slots` 空，事实含空普通槽 `{}` 且与 oracle 逐字段相等；单侧 `palm` 仍出现在 `targets_at_slots` 且事实含该件。`strong_elbow`：`targets_at_slots` 均在 `target_slots` 内，表外占用无解除行，事实＝oracle。`pot_of_greed`／`mana_search` 在 12 件占用上 `targets_at_slots` 仍空，事实＝本刀前自身行（无槽位解除／自由面行）。改 TERMS 名后收集集合不变。快照／`state.rng` 不变。既有 `card_facts_declared_slots`／`card_facts_consumes_has_targets_at`／`card_keyword_deps_stable_ids` 不得变红。判定不得用 `term.name`／译文／`requirements()`／`SLOT_NAMES`。生产源码不加计数器、不 preload `card_text`。

## 完成定义及档 2（尚未执行）

- 实现者交 `g.B.keyword_ids` 转发、`card_facts` 唯一消费点与上述场景；独立新会话审查者只核对本域源码／测试与本契约；清洁者核对：未复制走查过滤、未新 `card_effects`→`card_text` 边、未改 `View.build`、`face_keywords` 未加 `id`、依赖面 ⊆ 允许面。本次不写 `docs/spec`。
- 实现者在 `spire-godot/` 运行 `& tools/check.ps1 -Suite architecture -TimeoutSeconds 600`。通过＝退出码 0、`SUITE RESULT: architecture PASS`、完成标记、`summary.json` 的 `status=passed` 且指纹未变。未运行、`source_changed`、钉牌缺失或无 ids 仍全身 `targets_at`＝未完成。不借 `card_facts_consumes_has_targets_at` 旧绿宣称本域通过。
- 档 2（选定加固者，独立实现／清洁后）对上述有限输入域跑 architecture。变异须红：①只用 `spec.has("target_slots")` 决定收集（无表的 `strain` 有件也不 `targets_at`）；②用 `term.name=="挣扎"`／译文／`SLOT_NAMES` 当 ids；③`card_effects` preload `card_text` 或把 `id` 写入 `face_keywords`；④无装备收集键仍走槽循环（12 件上 `pot_of_greed` 出现 `targets_at`）。原版绿；变异复原后重跑本域。不能靠静态搜索替代行为敏感性。缺工具或失败＝未通过，不算不适用。
- UI 验收 **none**：事实形状与本刀前相等，无玩家新行为；不派验收者。无打包、发布、push。

## 非目标

牵涉／交互掩码；收窄默认 `View.build`；新 `present` 节；T4／T5／分区 delta；改 `has_targets_at`／`_visit_targets_at`；改 `reason`／`has_escape_target`；改 TERMS 文案与 `face_keywords` 形状；新模块；`card_effects` → `card_text` preload。

## 风险假设

现行到达槽循环的牌 bound ids 均含装备收集键；`self_faces`／`single_face` 早退已使 `pot_of_greed` 不收集——本刀要把「不收集」收口到 keyword_ids 交，而不是只靠结构早退。无表＋有装备键仍必须按 consume 刀收集占用槽。若实现无法经 `g.B` 转发而要 preload `card_text`、或无法保持事实形状，停工交回，不扩边、不还原已丢弃补丁。
