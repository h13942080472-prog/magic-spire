# 种子标识与反馈存档：依赖约束（cleaner 可核对）

本文件是「种子标识」（`docs/spec/seed-identity.md`）与「反馈一并上传存档」
（`docs/spec/feedback-deployment.md`）两片的共同依赖约束：允许改动的文件、允许的依赖方向与禁止项。
`docs/spec/save-fixed-points.md` 的「加性字段与只读入口」一节引用本文件。
本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 允许改动

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `core/game.gd` | `_init` 写入 `state.initial_seed`；`restore_snapshot` 内唯一回填（副本上、`Snapshot.check` 之前） | `_restart_tower` 的种子改写与 `tower_generation` 自增不变；`_scene_key` 不变；`TRANSITIONS` 与 `checkpoint` 声明不变；恢复失败的原文件与 `state` 保留语义不变 |
| `core/game_view.gd` | 只读投影追加 `initial_seed`／`tower_generation` | 既有键与顺序不受影响；不新增规则派生字段 |
| `core/save_store.gd` | 新增只读入口 `fixed_point_text(game, map_drawings={})` | `pack()`／`unpack()`／`read_slot()`／`write_game()`／`summary()`／`MAX_BYTES`／回退规则不变；不做回填、不做大小判定、无文件访问 |
| `core/snapshot.gd` | **零改动** | `Snapshot.REVISION` 不升；`initial_seed` 不进豁免名单；通用逐字段校验继续生效 |
| `ui/main.gd` | 路线屏 `SeedChip`、`seed_report_text()`、`copy_seed()`、`seed_copied_until` | 不改 `restart` 签名与开局屏；不新增新局／重开入口；既有地图控件与布局不动 |
| `ui/feedback_report.gd` | `draft.include_save`（默认 true）、`MAX_SAVE_BYTES`、`save_attachment`／`save_note`、payload 的 `save` 键、提交前的服务端 schema 探测与降级、披露文案 | 唯一存档序列化仍为 `SaveStore.pack`（经 `fixed_point_text`）；附件不进草稿文件；附件与探测失败都不阻塞提交；同一草稿重试的 POST body 逐字相同 |
| `tools/feedback-service/Code.gs` | `save` 的形状／大小／信封校验、原始 POST 上限、附件转发、回执哈希排除 `save`、GET 声明 `schema` 支持级别 | 固定收件人；10 秒限流与 48 小时回执；不解析游戏规则；不泄露凭据 |
| `tools/feedback-service/test.cjs` | 接受与拒绝场景（含旧 schema 降级） | 不联网、不发信 |
| `tests/persistence_cases.gd`、`tests/persistence_ui_cases.gd`、`tests/route_ui_cases.gd`、`tests/interface_ui_cases.gd` | 两片证据入口表列出的具名 check | 不删除有效失败断言；既有断言按「探测 GET＋POST」更新请求计数，判据本身不变 |
| `docs/spec/seed-identity.md`、`docs/spec/feedback-deployment.md`、`docs/spec/save-fixed-points.md`、`docs/spec/seed-feedback-dependencies.md`、`docs/design/content.md`、`docs/design/game-design.md`、根 `AGENTS.md` 文档入口表 | 本次契约落盘 | 不保留被取代的旧口径（`docs/spec/` 被取代即删） |

## 允许的依赖方向

- 既有边：`ui/main.gd → core/{Game,SaveStore}`、`ui/feedback_report.gd → core/save_store.gd`
  （经 `host.saves` 与既有的 `host.game`／`host.map_drawings` 宿主访问）。
- `core` 不 preload `ui`（`ARCH core event module never names ui/` 继续成立）。
- `tools/feedback-service/*` 与游戏代码零依赖，只由 `node` 直接运行。
- 不新增模块、不新增运行时依赖、不新增随机域、不新增存档域。

## 禁止项

- 在 `ui/feedback_report.gd` 写第二份存档序列化；在 `SaveStore` 写第二处回填或大小判定。
- `SeedChip` 引入第二可见性判据；点击路径进入 `_submit`／候选／随机／写盘。
- 未探测服务端 schema 就附带 `save`；用「先带附件、失败再重发」兜底（会重复投递）。
- 服务端解析游戏规则、改写收件人、把 `save` 计入回执哈希。
- 升 `Snapshot.REVISION`；删除或放宽 `pack()`／`unpack()` 校验；改 `read_slot` 回退与 `summary()` 语义。
- 顺手改动固定点声明表、`ui/route_map.gd`、随机域表 `data/balance.gd::RNG_SALTS`。
