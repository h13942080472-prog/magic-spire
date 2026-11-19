# 更新检查 U1：依赖约束

`docs/spec/update-check.md` 的依赖约束索引：判据的真源是下表点名的检查，散文不复述内容
（格式参照 `docs/spec/seed-feedback-dependencies.md`）。
本文件不写执行结果：通过、失败、未执行一律登记在 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`update/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 允许改动

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `spire-godot/update/update_manifest.gd`（新） | 纯函数：`evaluate(manifest_bytes, signature, keys, current, platform)`、`compare(a, b)`；schema 1 的解析；`Crypto.verify`（SHA-256，RSA PKCS#1 v1.5） | 无 IO：不访问文件、网络与单例状态；不读 `ProjectSettings`（当前版本与平台都由参数传入）；拒绝原因只有固定枚举 `signature/key/schema/platform/size/json/url`；「已验签但不是更新」用空 `reason` |
| `spire-godot/update/update_keys.gd`（新） | 常量 `KEYS = {key_id: 公钥 PEM}`；U1 为空表 | **只放公钥**；不放私钥、口令或任何令牌；空表必须让 `evaluate` 返回 `none`／`key` |
| `spire-godot/update/update_check.gd`（新） | `check()`、`deliver()`、`manifest_url()`、`current_version()`、`platform_key()`、`scripted_run()`、`auto_allowed()`、`keys`、`transport: Callable` 接缝、`HTTPRequest`（10 秒超时、`max_redirects=0`、`body_size_limit=65536`）、`checked(offer)` | 一次检查最多 2 个 GET；只用 HTTPS；不写盘；不重试；请求不带存档、种子、设备标识、账号或自定义标识头；失败一律静默；`[update]` 只在此文件读取 |
| `spire-godot/project.godot` | 新增 `[update]` 段：`manifest_url`、`check_on_start` | 不改 `application/config/version`、`run/main_scene`、`[feedback]`；不新增 `[autoload]` |
| `spire-godot/ui/display_settings.gd`（CC-D22-1） | `update_check_enabled`、`set_update_check(enabled)`；既有 `user://display-settings.cfg` 的 `update/check_on_start` 一键 | 不新增 `user://` 文件、不新增设置存储；`initialize` 的复位与加载顺序不变；既有 setter 行为不变 |
| `spire-godot/ui/home_screen.gd`、`spire-godot/ui/main.gd` | 主页 `HomeUpdateNotice`、`HomeUpdateDownload`、`HomeUpdateMirror`（放在主页布局层，不在 `GameHome` 内）；设置页 `UpdateCheckEnabled`、`UpdateCheckNow`、`UpdateCheckStatus`；持有并启动 `update_check`；`open_url` 可替换的跳转接缝 | 主页左侧标题区仍是原来四个子节点；不改开局、继续、设置的入口与布局语义；检查不阻塞主页输入、不改 `Game` 状态与存档；不调用 `command_router` 或 `Game` 的任何写接口；版本比较、验签、解析不在 UI 里出现第二份 |
| `spire-godot/assets/localization/zh_CN.json`、`en_US.json`、`ja_JP.json` | 新增 `ui.update.*` 与 `ui.settings.update_check*`、`ui.settings.update_now` 十条 ID 的文案与译文 | 既有 ID 与文案不变；`en_US`／`ja_JP` 的 `source` 与中文原文逐字相同；不删条目 |
| `spire-godot/tests/update_cases.gd`（新）、`spire-godot/tests/update_ui_cases.gd`（新）、`spire-godot/tests/test_game.gd` 的 `SUITES`、`spire-godot/tests/ui_smoke.gd` 的 `UI_MODULES` | 本契约的具名 check；登记 `update` suite | 现场 `Crypto.generate_rsa` 生成密钥对，**不提交私钥夹具**；不联网（只用 `transport` 替身）；不删除、不放宽既有的 HOME 断言 |
| `spire-godot/tests/architecture_cases.gd::update_module_is_a_leaf` | 新增 `update/` 的禁止边（不引用 `ui`／`core`／`data`／`tests`；`core`／`data` 不引用 `update`；只有 `update_check.gd` 发 HTTP） | 既有判定函数与既有边不变 |
| `spire-godot/tests/mutations.json` | 为本片具名 check 追加条目 | 既有条目、`known_gaps` 与冻结清单不变；`find` 仍唯一 |
| `docs/spec/update-check.md`、`docs/spec/update-check-dependencies.md`、根 `AGENTS.md` 文档入口表、`docs/spec/project-map.md` 目录表 | 本契约落盘 | `docs/spec/` 被取代即删；不改 `docs/spec/packaging.md`（它的增补留到 U2） |

## 判据 → 检查

| 判据 | 执行它的检查 |
| --- | --- |
| 判定只由 `UpdateManifest.evaluate` 给出：`size`→`json`→`key`→`signature`→`schema`→`platform`→形状→`url`→`revoked`／新版本 | `tests/update_cases.gd` 的 UPDATE 具名 check（规则分类 `update`） |
| 版本比较按 `.` 分段、数字段按数值、缺省段为 0、非数字段排在缺省段之后 | `tests/update_cases.gd::version_order_is_numeric_per_segment` |
| 空公钥表只给 `none`／`key`，不放行、不崩溃（CC-D22-2） | `tests/update_cases.gd::empty_key_table_yields_no_offer` |
| 启动开关写入既有设置文件的 `update/check_on_start`，不出第二份存储（CC-D22-1） | `tests/update_cases.gd::settings_toggle_uses_one_store` |
| 主页提示、两个跳转按钮、设置页开关与「立即检查」的真实点击语义 | `tests/update_ui_cases.gd` 的 UPDATE 具名 check（窗口分类 `update`） |
| `update/` 是叶子模块：不引用 `ui`、`core`、`data`、`tests`；`core`／`data` 不引用 `update` | `tests/architecture_cases.gd::update_module_is_a_leaf` |
| 一次检查最多两个 HTTPS 请求、不重试、失败静默 | `tests/update_ui_cases.gd::startup_offline_is_silent`、`tests/update_ui_cases.gd::startup_offer_renders_notice` |
| 生产公钥表为空时任何构建都不显示提示 | `tests/update_cases.gd::empty_key_table_yields_no_offer`（判定面）＋ `docs/spec/update-check.md`「域」的口径 |

## 仍靠人审（无机械判据，本批保留）

- 公网清单的**部署与签名**：`update.magicspire.xyz/v1/manifest.json` 与其 `.sig` 尚未发布。
  这一步没做时，只能记「桌面接缝验收通过、公网未验收」，不得宣称已上线。
- 生产公钥的生成与保管（`spire-godot/update/update_keys.gd::KEYS` 的填写，U1b）：私钥必须在
  维护者离线环境生成，仓库、测试、日志与文档都不得出现私钥、口令或 Cloudflare 令牌。
- Android 真机与真实网络（断网、代理、蜂窝）的行为：桌面接缝不能代表安卓验收。
- 发布侧脚本（由成品 `manifest.json` 派生更新清单、签名上传，U1b）不在本片授权面。
- 不属于本片授权面：`spire-godot/ui/feedback_report.gd`、`spire-godot/tools/package*.ps1`、
  `spire-godot/core/**`、`spire-godot/data/**`，以及 U2 的 `update/boot.gd`、`update/update_store.gd`。
