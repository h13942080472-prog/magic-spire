# 种子标识与反馈存档：依赖约束索引

「种子标识」（`docs/spec/seed-identity.md`）与「反馈一并上传存档」（`docs/spec/feedback-deployment.md`）两片已落地。
本文件是这两片的依赖约束索引：判据的真源是下表点名的检查，散文不复述内容
（2026-10-05 重写；规则见 `skills/spire-docs/SKILL.md`「判据优先」）。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。
本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

## 判据 → 检查

| 判据 | 执行它的检查 |
| --- | --- |
| `core`／`data` 不引用 `ui` 模块 | `tests/architecture_cases.gd::slice_dependency_directions` |
| `ui/` 内只有 `ui/main.gd` preload `core`（既有边 `ui/main.gd → core/game.gd`、`ui/main.gd → core/save_store.gd`） | `tests/architecture_cases.gd::slice_dependency_directions` |
| 附件只经 `core/save_store.gd::fixed_point_text` 读取，`ui/` 里没有第二份存档序列化 | `tests/architecture_cases.gd::feedback_save_single_serializer` |
| 附件默认勾选、探测 GET 先于 POST、旧 schema 降级不重发、失败不阻塞提交 | `tests/interface_ui_cases.gd` 的 FEEDBACK 具名 check（窗口分类 `interface`） |
| 服务端 `save` 形状／大小／信封校验与限流、回执哈希排除 `save` | `spire-godot/tools/feedback-service/test.cjs`（`node --test`） |
| 存档序列化面与文件替换（`core/save_store.gd::pack`、`unpack`、`read_slot`、`write_game`、`summary` 的回退与校验） | `tests/persistence_cases.gd`（往返、损坏回退、隔离用例） |
| `core/game.gd::TRANSITIONS` 的 checkpoint 声明不随无关改动变动 | `tests/architecture_cases.gd::save_checkpoint_kinds_are_pinned` |
| 随机域集合不变（不新增随机域） | `tests/architecture_cases.gd::run` 的 "ARCH initialization creates exactly the registered random domains" |
| 投影键面／记录路径／基线值不漂移 | `tests/architecture_cases.gd::behavior_baseline_equivalence` |

## 仍靠人审（无机械判据，本批保留）

- `core/game.gd::restore_snapshot` 内的种子回填只允许一处（副本上、`Snapshot.check` 之前）；
  恢复失败时原文件与 `state` 保留语义不变。
- `core/save_store.gd`：不新增第二处回填、大小判定或文件访问；回退规则不变。
- `ui/feedback_report.gd`：附件不进草稿文件；同一草稿重试的 POST body 逐字相同。
- `tools/feedback-service/Code.gs`：固定收件人、10 秒限流与 48 小时回执、不解析游戏规则、不泄露凭据。
- 不属于本片授权面：固定点声明表、`ui/route_map.gd`、`data/balance.gd::RNG_SALTS`。
