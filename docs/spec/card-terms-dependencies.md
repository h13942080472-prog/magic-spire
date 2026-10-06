# 卡面词条悬停显示：依赖约束索引

「卡面词条悬停显示」（`docs/spec/card-terms.md`）一片已落地。本文件是这一片的依赖约束索引：
判据的真源是下表点名的检查，散文不复述内容（2026-10-05 重写；规则见 `skills/spire-docs/SKILL.md`「判据优先」）。
本片与种子角标／反馈存档、本局回顾、候选层移除三片无文件交叉；同名文件的行只覆盖悬停与词条弹窗。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。
本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

## 判据 → 检查

| 判据 | 执行它的检查 |
| --- | --- |
| 悬停框集合＝该面 `face_keywords`、框数与每个词条一名称一定义 | `tests/interface_ui_cases.gd::card_terms` |
| 词条框与锚面不相交、视口内含（几何与 clamp） | `tests/interface_ui_cases.gd::card_terms` |
| 悬停前后 `ui.game.export_snapshot()` 相等、`ui.view.version` 不变（只读） | `tests/interface_ui_cases.gd::card_terms` |
| 图鉴悬停／翻面的词条框（含 `_hide_term` 收口路径） | `tests/encyclopedia_ui_cases.gd` 的 BOOK 具名 check |
| 检索面悬停的两段式断言（词条名与定义分开） | `tests/card_power_ui_cases.gd`（`SEARCH UI hover …` 场景） |
| 事件卡选项、奖励选牌的真实入口悬停 | `tests/event_ui_cases.gd`、`tests/reward_ui_cases.gd` |
| 长按（触屏）等价入口 | `tests/touch_ui_cases.gd` |
| 词条集合只有一份实现（`data/card_text.gd::keywords`，`TERMS` 不被 `core/`／`ui/` 读） | `tests/architecture_cases.gd::card_terms_single_source` |
| `core`／`data` 不引用 `ui` 模块 | `tests/architecture_cases.gd::slice_dependency_directions` |

## 仍靠人审（无机械判据，本批保留）

- `ui/main.gd::_show_term` 里 `_ignore_mouse(term_popup)` 的防御性保留：删除它不会让任何断言变红
  （点击断言实测仍绿），只靠 cleaner／审查者核对差异面。
- 词条框的字号（CYAN 19px／TEXT 15px）与配色是机制声明，无断言覆盖。
- 商店买卡与去卡（`ui/shop_screen.gd::_card_offer`、`ui/shop_screen.gd::services`）的悬停由验收程序在真实窗口逐点操作覆盖。
- 本片不新增分类文件，也不改 `tests/ui_smoke.gd::UI_MODULES`／`tests/suite_selection.gd::CROSS_AREAS`；
  推送、打标签、改版本号、改 `project.godot` 或导出预设不在本片授权面（红线见根 `AGENTS.md`「禁区」）。
