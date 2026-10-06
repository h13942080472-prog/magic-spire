# 候选层移除与指令路由：依赖约束索引

「候选层移除与指令路由」（`docs/spec/candidate-removal.md`）一片已落地（批 R1–R5 全部合并）。
本文件是这一片的依赖约束索引：判据的真源是下表点名的检查，散文不复述内容
（2026-10-05 重写：允许改动表、183 文件迁移面清单与逐批授权期结束，规则见 `skills/spire-docs/SKILL.md`「判据优先」）。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。
本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

## 判据 → 检查

| 判据 | 执行它的检查 |
| --- | --- |
| 终态：四个历史符号（`candidates`／`_candidate`／`_build_candidates`／`_phase_candidates`）与已删除的行动行索引文件 `action_index.gd` 不存在，无按提交身份 id 的取行复核 | `tests/architecture_cases.gd::removal_end_state` |
| `valid`／`reason` 只有一个判定产出（UI 与接管路径只消费） | `tests/architecture_cases.gd::single_eligibility_implementation` |
| UI 提交唯一入口：`ui/command_router.gd::emit`／`emit_deferred`，`ui/main.gd::_submit` 只由路由调用，`ui/command_router.gd`／`ui/command_routes.gd` 不 preload core | `tests/architecture_cases.gd::instruction_router_single_entry` |
| `ui/command_router.gd::ROUTES` 的 kind 全集与逐域分类（表外 kind fail-closed） | `tests/architecture_cases.gd::instruction_route_table_is_total` |
| 指令经 kind 命中行 ≡ 全表同形状（`core/game.gd::command_fact` 经 `core/game.gd::_kind_facts`） | `tests/architecture_cases.gd::command_fact_kind_lookup` |
| 卡牌事实的声明槽位（`target_slots` 表外槽不调 `targets_at`，事实与刀前相等） | `tests/architecture_cases.gd::card_facts_declared_slots`、`tests/architecture_cases.gd::card_facts_consumes_has_targets_at`、`tests/architecture_cases.gd::card_facts_keyword_min_query` |
| 行为基线等价（记录路径／视图键面／基线值只按显式声明的掩码变化） | `tests/architecture_cases.gd::behavior_baseline_equivalence` |
| 跨层方向：`core`／`data` 不引用 `ui`；`ui/` 内只有 `ui/main.gd` preload core | `tests/architecture_cases.gd::slice_dependency_directions` |
| 存档迁移不被绕过（旧版本拒绝、`core/snapshot.gd::REVISION` 与迁移用例） | `tests/persistence_cases.gd` |

## 仍靠人审（无机械判据，本批保留）

- 生产源码不带计数器／计时钩子；本片不新增运行时钩子或第三方依赖。
- UI 自行判定资格、用译文／名称／颜色／图片识别对象、用 `version` 当缓存键——这些是根 `AGENTS.md`「禁区」与
  `skills/spire-architecture/SKILL.md` 的通用约束，本片不复述。
- 装备只读查询接缝内部（`_query_stack_items`／`targets_at`）不因本片改写。
- 推送、打标签、改版本号；改 `project.godot` 或导出预设不在本片授权面。
