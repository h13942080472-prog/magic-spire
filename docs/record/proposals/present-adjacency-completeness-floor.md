# present 邻接表的完整性下限（已落地）

状态：**已落地（2026-10-19）**。2026-10-02 实现者评估后登记为后续项；2026-10-18 规划者按命名族下限
（`plan.md` A 档）设计并经协调者裁定，2026-10-19 实现。落点＝`spire-godot/tests/architecture_cases.gd`
的五条判据（`present_adjacency_rows_are_complete`／`present_section_dispatch_is_total`／
`present_pipeline_routines_are_registered`／`present_full_render_fallback_is_pinned`／
`present_adjacency_symbol_floor_is_pinned`）、`spire-godot/ui/main.gd::PRESENT_ADJACENCY` 补 11 个管线条目
（9 个 `_*_key_hit`＋2 个 `_unload_*_section`，14 条边，符号 97→108）、`spire-godot/tests/mutations.json`
的 5 条突变证据与表头／`skills/spire-docs/SKILL.md` 第五类的规范描述。
域：`spire-godot/ui/main.gd::PRESENT_ADJACENCY` 及其机械判据
`spire-godot/tests/architecture_cases.gd::present_adjacency_graph_is_pinned` 与本片的五条完整性判据。

## 落地口径

- 管线条目＝冻结的命名形状（`PRESENT_PIPELINE_SHAPES`／`PRESENT_PIPELINE_EXACT` 常量，单一声明）：
  节重建、present 内同步、构建入口、节键、节键命中探针、节拆卸、节级全量谓词，以及 `render`／
  `_present_needs_full_render`。新增落在形状内的例程必须入表，否则 `present_pipeline_routines_are_registered` 红。
- 符号下限＝`PRESENT_SYMBOL_FLOOR=108`，只许增；下调须同批写明理由。
- 本片只改声明表与表头注释，零运行行为变化；`section_read_sets_are_pinned` 的冻结读集实跑零移动。

## 残差（仍靠评审）

- 任意命名的非形状辅助（例如 `_apply_new_stage`）；带名字的屏／抽屉构建器；外部符号（`header.configure`、
  `layout.*`、`configure_enemy`、`EquipmentPortrait.configure`、`CardFace.separate_keywords`）内部完整性。
- 结构性判据不证明调用顺序；顺序与读集由 `section_read_sets_are_pinned` 与运行期窗口套件承担。

## 缺口（落地前登记，保留原证据）

判据只校验**已声明**的边，不保证每个管线条目都已登记：

- 新增节／舞台例程而不入表：全绿。
- 删除整行：全绿（只剩孤立子时由 3a 孤儿检查兜住，删整条链则无感）。
- 把整表掏空为 `{"present":[]}`：全绿（三条检查均空过）。

## 为何本片不设下限

候选下限＝「已登记父在 `ui/main.gd` 里的每个直调（已声明 `func`、不属表头不入表类）必须入表或成子」。
实测会牵出 **80** 个本地例程，其中仅 9 个落在现有不入表名单
（`_label`/`_place`/`_panel`/`_button`/`_style`/`_bar`/`_scroll`/`_text`/`_localize_controls`），
其余 71 个为构建／域例程（仅 `render` 就调用约 20 个）。把它写成白名单或全部入表，
都等于维护第二份随实现频繁变动的手工清单，违背「同一语义只走一条路径」。

## 闭合时须成立（未设计怎么做）

- 下限的枚举面必须从**单一声明**派生，不是手抄的函数名清单（例如由分类注解或节注册表派生）。
- 能抓三类回归：新增例程不入表、删除整行、整表掏空。
- 不因为设下限而被迫登记纯构建／框架例程；现有三条检查保持成立。

## 非本条

表头与 `spire-docs` 第五类的覆盖边界文字（本片已完成）；present 管线本身的实现路径改动。
