# 本局回顾面板：依赖约束索引

「本局回顾」（`docs/spec/run-review.md`）一片已落地。本文件是这一片的依赖约束索引：
判据的真源是下表点名的检查，散文不复述内容（2026-10-05 重写；规则见 `skills/spire-docs/SKILL.md`「判据优先」）。
本片与种子角标／反馈存档两片同批提 PR，切口独立：`docs/spec/seed-feedback-dependencies.md` 仍约束那两片。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。
本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

## 判据 → 检查

| 判据 | 执行它的检查 |
| --- | --- |
| 面板只读：打开、滚动、点地图、右键拖拽、复制都不改快照／View 版本／存档 | `tests/route_ui_cases.gd::run_review`（`review_is_read_only`） |
| 回顾地图 `read_only` 为真、`buttons` 为空、点节点不出发 | `tests/route_ui_cases.gd::run_review`（`review_node_click_never_departs`） |
| 地图与投影逐项相同（已走边、未走边、锁定房） | `tests/route_ui_cases.gd::run_review`（`review_map_matches_projection`） |
| 节点概况＝已走房间数与该层号（权威来源逐项相同） | `tests/route_ui_cases.gd::run_review`（`review_progress_counts_walked_nodes`） |
| 卡组列出每张牌（不写第二套列表实现） | `tests/route_ui_cases.gd::run_review`（`review_deck_lists_every_card`） |
| 标识块复用 `ui/main.gd::seed_report_text` 的四要素结构 | `tests/route_ui_cases.gd::run_review`（`review_identity_reuses_report`） |
| 复制按钮与路线屏角标共用同一实现与 1.2 s 窗口（`ui/main.gd::copy_seed`、`ui/main.gd::_refresh_seed_chip`） | `tests/route_ui_cases.gd::run_review`（`review_copy_shares_the_chip`）＋ `tests/architecture_cases.gd::run_identity_single_writer` |
| 面板走共享抽屉开合（Esc／安卓返回同语义） | `tests/route_ui_cases.gd::run_review`（`review_behaves_like_the_shared_drawer`） |
| 中英两条 `ui.run_review.*` 文案齐备 | `tests/route_ui_cases.gd::run_review`（`review_copy_exists_in_both_languages`）＋ `tests/localization_cases.gd`（en_US／ja_JP `missing==0`） |
| `ui/run_review.gd` 只读：不含 `DisplayServer`／`clipboard`／`_submit`／`_save_progress`／`ui.game` 与自绘地图 | `tests/architecture_cases.gd::slice_dependency_directions` |
| 面板不新增 View 键、候选、`state` 字段；不改 `core/`（`core/snapshot.gd::REVISION` 不升） | `tests/architecture_cases.gd::behavior_baseline_equivalence`、`tests/persistence_cases.gd` |

## 仍靠人审（无机械判据，本批保留）

- 入口不可见＝控件不存在（`ui/run_review.gd::can_open` 为假时不建控件），不得用"先打开面板再让
  `visible=false`"冒充；面板里不得留空白格表示无数据。
- `ui/route_map.gd` 的 `STATUS` 文案表、`data/balance.gd::RNG_SALTS`、协调者的本地发布脚本不在本片授权面。
- 推送、打标签、改版本号、改 `project.godot` 或导出预设不在本片授权面（红线见根 `AGENTS.md`「禁区」）。
