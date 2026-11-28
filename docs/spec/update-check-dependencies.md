# 更新检查：依赖约束

`docs/spec/update-check.md` 的依赖约束索引：判据的真源是下表点名的检查，散文不复述内容
（格式参照 `docs/spec/seed-feedback-dependencies.md`）。
本文件不写执行结果：通过、失败、未执行一律登记在 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`update/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 允许改动

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `spire-godot/update/update_manifest.gd`（新） | 纯函数：`evaluate(manifest_bytes, signature, keys, current, platform)`、`compare(a, b)`、`is_newer`、`is_sha256`；schema 1 的解析（唯一 JSON 解析入口 `document`，补丁状态共用）；`Crypto.verify`（SHA-256，RSA PKCS#1 v1.5）；包体判定 `verify_patch_file(path, bytes, sha256)`（只读指定文件，分块哈希） | 除 `verify_patch_file` 读它被指定的那一个文件外无 IO：不访问网络与单例状态；不读 `ProjectSettings`（当前版本与平台都由参数传入）；拒绝原因只有固定枚举 `signature/key/schema/platform/size/json/url`；「已验签但不是更新」用空 `reason`；验签只经 `_verified`，公钥以 `CryptoKey.load_from_string(pem, true)` 加载；键表条目含 `PRIVATE KEY` 时在 `key` 步拒绝 |
| `spire-godot/update/update_keys.gd`（新；写入 `k1`） | 常量 `KEYS = {key_id: 公钥 PEM}`；现只有 `k1`，条目是三引号 PEM 字面量 | **只放公钥**；不放私钥、口令或任何令牌；恰好一条 `k1`，DER sha256 钉住；轮换先并列加 `k2` 再切换清单 `key_id`；显式传入的空表仍让 `evaluate` 返回 `none`／`key` |
| `spire-godot/update/update_check.gd`（新） | `check()`、`deliver()`、`manifest_url()`、`platform_key()`、`scripted_run()`（转调 `spire-godot/update/update_store.gd::scripted_run`）、`auto_allowed()`、`keys`、`transport: Callable` 接缝、`HTTPRequest`（10 秒超时、`max_redirects=0`、`body_size_limit=65536`）、`checked(offer)` | 一次检查最多 2 个 GET；只用 HTTPS；不写盘；不重试；请求不带存档、种子、设备标识、账号或自定义标识头；失败一律静默；`[update]` 只在此文件读取 |
| `spire-godot/project.godot` | 新增 `[update]` 段：`manifest_url`、`check_on_start`；`run/main_scene` 指向 `res://update/boot.tscn`；`config/name` 不带版本后缀（窗口标题的版本由 `ui/main.gd::_ready` 拼接） | 不改 `application/config/version`、`[feedback]`；不新增 `[autoload]`；`config/custom_user_dir_name*` 不变 |
| `spire-godot/update/boot.gd`、`spire-godot/update/boot.tscn`（新） | 引导场景与脚本：`start(store, mounter, session)`、`engine_mount(path)`；`_ready` 在玩家会话挂载后以场景路径字符串切到 `res://main.tscn` | 只预载 `update_store.gd` 与 `update_manifest.gd`；不引用 `ui`／`core`／`data`／`tests`；`ProjectSettings.load_resource_pack` 在产品运行时只在 `engine_mount` 一处（发布侧工具 `spire-godot/tools/patch_release_pck.gd` 除外）；`--script` 运行不挂载、不切场景；不触碰 `user://saves/` 与旧档导入标记 |
| `spire-godot/update/update_store.gd`（新） | 补丁状态与版本身份：`baseline_version`、`effective_version`、`record_mounted`、`identity`、`load_state`、`write_state`、`patch_path`、`mark_failed`、`begin_mount`、`mark_boot_succeeded`、`reset_for_baseline`、`clear_staging`、`valid_version`、`scripted_run`、`player_session`；目录可注入 | 全仓唯一读取 `application/config/version` 的文件、唯一写 `user://updates` 的文件；有效版本只由 `record_mounted` 写；版本经 `valid_version` 文法后才拼路径；状态文件经临时文件、回读、改名写入；不联网、不调用 `core/save_store.gd` |
| `spire-godot/ui/main.gd`、`spire-godot/ui/feedback_report.gd`、`spire-godot/tools/release_probe.gd`（版本身份） | `ui/main.gd::_ready` 的窗口标题＝`config/name`＋` v`＋有效版本，并在 `_restore_startup` 之后调 `mark_boot_succeeded`；`ui/feedback_report.gd::_capture_context` 读有效版本；`tools/release_probe.gd::run` 读基线版本 | 三处都经 `update_store.gd`，不再直接读版本设置；`update_store` 字段只在玩家会话构造（用例可注入）；不触碰存档 |
| `spire-godot/ui/display_settings.gd` | `update_check_enabled`、`set_update_check(enabled)`；既有 `user://display-settings.cfg` 的 `update/check_on_start` 一键 | 不新增 `user://` 文件、不新增设置存储；`initialize` 的复位与加载顺序不变；既有 setter 行为不变 |
| `spire-godot/ui/home_screen.gd`、`spire-godot/ui/main.gd` | 主页 `HomeUpdateNotice`、`HomeUpdateDownload`、`HomeUpdateMirror`（放在主页布局层，不在 `GameHome` 内）；设置页 `UpdateCheckEnabled`、`UpdateCheckNow`、`UpdateCheckStatus`；持有并启动 `update_check`；`open_url` 可替换的跳转接缝 | 主页左侧标题区仍是原来四个子节点；不改开局、继续、设置的入口与布局语义；检查不阻塞主页输入、不改 `Game` 状态与存档；不调用 `command_router` 或 `Game` 的任何写接口；版本比较、验签、解析不在 UI 里出现第二份；宿主在入树前被释放时（`_notification` 的 `NOTIFICATION_PREDELETE`）一并释放未入树的 `update_check` |
| `spire-godot/assets/localization/zh_CN.json`、`en_US.json`、`ja_JP.json` | 新增 `ui.update.*` 与 `ui.settings.update_check*`、`ui.settings.update_now` 十条 ID 的文案与译文 | 既有 ID 与文案不变；`en_US`／`ja_JP` 的 `source` 与中文原文逐字相同；不删条目 |
| `spire-godot/tests/update_cases.gd`（新）、`spire-godot/tests/update_ui_cases.gd`（新）、`spire-godot/tests/interface_ui_cases.gd`（版本期望）、`spire-godot/tests/test_game.gd` 的 `SUITES`、`spire-godot/tests/ui_smoke.gd` 的 `UI_MODULES` | 本契约的具名 check；登记 `update` suite；补丁存储只注入 `res://build/` 下的独立目录，从不读写真实 `user://updates`；期望版本读 `spire-godot/update/update_store.gd::effective_version` | 现场 `Crypto.generate_rsa` 生成密钥对并把公钥交给 `evaluate`；`spire-godot/tests/fixtures/update/` 只提交公钥 PEM、清单与签名（OpenSSL 互通夹具；`release-scripts/` 另含三份脚本输入），**不提交任何私钥**；不联网（只用 `transport` 替身）；不删除、不放宽既有的 HOME 断言 |
| `spire-godot/tests/architecture_cases.gd::update_module_is_a_leaf` | 新增 `update/` 的禁止边（不引用 `ui`／`core`／`data`／`tests`；`core`／`data` 不引用 `update`；只有 `update_check.gd` 发 HTTP）；新增五条单点判据 `update_compare_single_entry`、`update_document_single_entry`、`update_verify_single_entry`、`update_http_single_entry`、`update_jump_single_entry`；新增两条判据 `version_read_single_entry`、`update_store_is_single_writer` 及扫描助手 `update_gd_files` | 既有判定函数与既有边不变；`update_compare_single_entry` 的期望集合含 `is_newer`，`update_document_single_entry` 的期望是 `document` |
| `spire-godot/tests/architecture_cases.gd`（发布侧加固） | 新增三条发布侧单点判据 `update_sign_single_entry`、`update_signature_write_single_entry`、`update_manifest_write_single_entry` 及扫描助手 `update_release_files`、`update_release_scopes`、`update_release_matches` | 只读源码文本，不调用脚本；扫描 `tools/**/*.ps1` 与 `**/*.gd`，只跳过 `.gitignore` 忽略的目录；既有判定函数与既有边不变 |
| `spire-godot/tests/fixtures/update/` 的 `.gitattributes`（新） | 把三份夹具标为 `-text`，让检出字节等于签名字节 | 不改夹具内容；不引入第二份夹具 |
| `spire-godot/tools/update-manifest.ps1`、`spire-godot/tools/sign-update-manifest.ps1`、`spire-godot/tools/update-manifest-check.ps1`（新） | 唯一清单生成入口与唯一签名入口，接口见 `docs/spec/update-check.md`「发布侧脚本」；两者 dot-source 的回读自检 `spire-godot/tools/update-manifest-check.ps1::Assert-UpdateManifest` | 与游戏代码零依赖（签名脚本只按文本读 `update/update_keys.gd`）；回读自检只有这一份实现，生成器回读临时文件、签名器签名前回读 `-Manifest` 都调用它；Android 哈希只取自包清单、Windows ZIP 哈希只在生成器算一次；`-Revoked` 只收字符串元素；拒签与拒绝路径不留输出；不接受口令明文参数，不打印私钥、口令或其哈希，报错不回显 `-PrivateKey` 与 `-PassphraseEnv` 的取值；两份脚本 `#Requires -Version 7.0`；`-KeyTable` 只作测试接缝 |
| `spire-godot/tools/check.ps1::Get-SourceFingerprint` | 目录集合加入 `update` | 只改目录集合；指纹仍只作同一次运行内的守卫（`before==after`），不当身份，没有冻结值依赖它 |
| `spire-godot/tests/fixtures/update/mount_probe.gd`（新） | 子引擎进程的挂载探针（`--headless --script`，参数＝`res://` 存储根与绝对结果文件路径）：经 `spire-godot/update/boot.gd::start` 与默认挂载器挂载，把一份 JSON 结论写到结果文件后 `quit`；挂载在主线程上同步执行，引擎调用挂死时主循环也停，进程内没有能触发的计时器，**唯一兜底是父测试的超时与 `OS.kill`** | 真实挂载只在子进程里做，主测试进程不挂载：挂载会让该进程之后对 `res://` 的目录访问走包内文件系统，同进程后续套件（`runner` 在 `SUITES` 里排在 `update` 之后）建 `res://build` 即失败；父测试 `tests/update_cases.gd::engine_mounter_loads_a_real_pack` 以 `OS.create_process` 启动、每 100 毫秒轮询、60 秒超时即由 `tests/update_cases.gd::wait_or_reap` 杀掉并再等至多 5 秒（`MOUNT_REAP_MSEC`）确认子进程已退出，`OS.kill` 返回非零或仍在运行都判红（消息写明 pid 与「child still running」），并读回子进程的引擎日志、出现退出泄漏行即红；子进程继承父进程环境（含沙盒 `APPDATA`）；探针不直接调用 `load_resource_pack`，只走生产入口 |
| `spire-godot/tests/fixtures/update/release-scripts/`（新） | 两份脚本用一次性密钥产出的清单与签名，及一次性公钥、`notes.txt`、`android-package-manifest.json`、`windows.zip` 三份输入；同目录 `.gitattributes` 标 `-text` | 只经脚本生成；**不提交任何私钥**；既有 OpenSSL 夹具不变 |
| `spire-godot/tests/state_readers.json`（生成物） | 由 `tools/build_state_readers.gd --write` 重写，登记 `update/` 的读取点 | 只经工具写入；不手工编辑；他行不变 |
| `spire-godot/tests/check_index_edges.gd::CLOSURE` | 新增 `spire-godot/update/` 前缀条目：规则 `update,architecture`、界面 `update`；索引只扫 `core|data|ui`，不加这条则 `update/` 下改动落到 `ROUTE UNMAPPED` 而退回全量 | 只增这一条；窗口标题与反馈报告的断言经 `ui/main.gd`、`ui/feedback_report.gd` 既有的边路由到 `interface`，不在此重复 |
| `spire-godot/tests/check_index.json`（生成物） | 由 `tools/check-index.ps1 -Write` 重冻，登记 `update/` 与新增测试文件 | 只经工具写入；不手工编辑；他行不变 |
| `spire-godot/tests/update_cases.gd.uid`、`spire-godot/tests/update_ui_cases.gd.uid`、`spire-godot/tests/fixtures/update/mount_probe.gd.uid`（新） | 引擎生成的脚本 UID 旁文件 | 只经引擎导入写入；不手工编辑 |
| `spire-godot/tests/mutations.json` | 为本片具名 check 追加条目（含引导挂载、有效版本与两条新架构判据） | 既有条目、`known_gaps` 与冻结清单不变；`find` 仍唯一 |
| `docs/spec/update-check.md`、`docs/spec/update-check-dependencies.md`、根 `AGENTS.md` 文档入口表、`docs/spec/project-map.md` 目录表 | 本契约落盘 | `docs/spec/` 被取代即删 |
| `docs/spec/packaging.md` | 流水线加「生成并签名更新清单」一步，链接本契约；两处人工「生成最终 ZIP」步骤的 SHA256 改为引用清单里的值 | 发行 ZIP 的 SHA256 只有清单一个来源，人工步骤不另算；其余打包契约不变；补丁 PCK 的增补留给后续的补丁挂载（本片不改它） |

## 判据 → 检查

判据名＝测试里的具名 check（断言标签 `UPDATE <name>:`／`DEP <name>:` 的 `<name>`，也是该 check 的函数名）。
表与 `tests/update_cases.gd`、`tests/update_ui_cases.gd`、`tests/architecture_cases.gd` 的 update 具名 check
**双向相等**：一条判据一行，一行只点名一个检查；漏行、多行、改名或幽灵条目都要同批改表。
本版共 71 条（规则 48、窗口 12、架构 11），按 `tests/<file>.gd::<name>` 逐名核对。

| 判据 | 执行它的检查 |
| --- | --- |
| 已签名的更新版本给出 `notice`，只暴露清单覆盖的字段 | `tests/update_cases.gd::newer_latest_yields_notice`（规则分类 `update`） |
| 同版本与旧版本只给 `none`／空 reason，不提供降级 | `tests/update_cases.gd::same_or_older_latest_yields_none`（规则分类 `update`） |
| 版本比较的数值段、缺省段与非数字段；自反、反对称、传递 | `tests/update_cases.gd::version_order_is_numeric_per_segment`（规则分类 `update`） |
| 签后改版本、清单头字节翻转与签名翻转都被拒 | `tests/update_cases.gd::tampered_manifest_fails_signature`（规则分类 `update`） |
| 另一把密钥签的清单按 `signature` 拒绝 | `tests/update_cases.gd::foreign_key_signature_is_rejected`（规则分类 `update`） |
| 未知或缺失 `key_id` 都是 `key` | `tests/update_cases.gd::missing_key_entry_is_rejected`（规则分类 `update`） |
| 空签名与非 base64 文本都是 `signature` | `tests/update_cases.gd::unusable_signature_is_rejected`（规则分类 `update`） |
| 显式传入的空公钥表只给 `key` | `tests/update_cases.gd::empty_key_table_yields_no_offer`（规则分类 `update`） |
| 生产键表恰好一条 `k1`：以 `public_only=true` 加载、不含私钥、DER sha256 钉住 | `tests/update_cases.gd::production_key_table_pins_k1`（规则分类 `update`） |
| SPKI 公钥 PEM 以 `public_only=true` 加载后验签通过 | `tests/update_cases.gd::public_key_pem_verifies_signed_manifest`（规则分类 `update`） |
| 键表条目是私钥 PEM 时一律 `key`，签名有效也不放行 | `tests/update_cases.gd::private_key_table_entry_is_rejected`（规则分类 `update`） |
| OpenSSL 签名夹具验签通过；签后改一字节→`signature` | `tests/update_cases.gd::openssl_signed_manifest_interops`（规则分类 `update`） |
| 两份发布侧脚本的产出在两个平台都验签为 `notice`，字段等于脚本输入（Android 哈希等于包清单、Windows 哈希等于 ZIP 独立重算）；签后改一字节→`signature` | `tests/update_cases.gd::release_scripts_manifest_interops`（规则分类 `update`） |
| `schema` 不是 1→`schema` | `tests/update_cases.gd::unknown_schema_is_rejected`（规则分类 `update`） |
| 清单缺当前平台→`platform` | `tests/update_cases.gd::missing_platform_yields_none`（规则分类 `update`） |
| 当前版本被撤回→`notice` 且 `revoked=true` | `tests/update_cases.gd::revoked_current_yields_notice`（规则分类 `update`） |
| 超上限／空 body→`size`；坏 JSON→`json`，都无引擎错误 | `tests/update_cases.gd::oversized_or_broken_manifest_yields_none`（规则分类 `update`） |
| `url`／`mirror` 不是 `https://` 开头→`url` | `tests/update_cases.gd::non_https_url_is_rejected`（规则分类 `update`） |
| `patches` 非空也不产生补丁结果 | `tests/update_cases.gd::patches_are_ignored`（规则分类 `update`） |
| 开关写既有设置文件的 `update/check_on_start`，不出第二份存储；新装默认开 | `tests/update_cases.gd::settings_toggle_uses_one_store`（规则分类 `update`） |
| 恰好上限、上限+1、空 body、非 UTF-8、`latest.version` 类型 | `tests/update_cases.gd::manifest_size_and_shape_domain`（规则分类 `update`） |
| `url`／`mirror` 的 `https` 前缀变体与缺失 mirror | `tests/update_cases.gd::manifest_link_domain`（规则分类 `update`） |
| 签名头／中／尾翻转、base64 内部空白与截断 | `tests/update_cases.gd::signature_position_and_shape_domain`（规则分类 `update`） |
| 多 key 按 `key_id` 选择、错配与 PEM 前后空白 | `tests/update_cases.gd::key_table_selection_domain`（规则分类 `update`） |
| 缺省段、前导零与超长文本段 | `tests/update_cases.gd::version_segment_edges`（规则分类 `update`） |
| 20 位数字段按数字串比较且不溢出；前导零与全零段 | `tests/update_cases.gd::version_segment_digit_compare`（规则分类 `update`） |
| 签名文件首尾换行／空白仍验签通过 | `tests/update_cases.gd::signature_outer_whitespace_domain`（规则分类 `update`） |
| 缺 `version` 或 `latest`→`json`；缺／空 `url`→`url`；两者同时坏先报 `url` | `tests/update_cases.gd::missing_field_attribution_domain`（规则分类 `update`） |
| 手动检查后主页提示、版本与约 MB、两个按钮各开自己的链接；状态不变 | `tests/update_ui_cases.gd::startup_offer_renders_notice`（窗口分类 `update`） |
| 超时只发一次请求、无提示、主页仍可操作 | `tests/update_ui_cases.gd::startup_offline_is_silent`（窗口分类 `update`） |
| 被改清单读完两次请求后按 `signature` 静默拒绝 | `tests/update_ui_cases.gd::startup_bad_signature_is_silent`（窗口分类 `update`） |
| 关掉后写盘并在下次启动不检查；「立即检查」不受开关影响 | `tests/update_ui_cases.gd::toggle_off_skips_startup`（窗口分类 `update`） |
| 检查挂起时主页与设置页仍可交互，且不重复请求 | `tests/update_ui_cases.gd::check_in_flight_keeps_home_interactive`（窗口分类 `update`） |
| 超时／404／302 各只一次请求、静默、无弹窗、不重试 | `tests/update_ui_cases.gd::transport_failures_are_silent`（窗口分类 `update`） |
| 检查进行中重复调用 `check()` 被忽略（不发请求、不另发 `checked`）；在途那次完成时只发一次 `checked` | `tests/update_ui_cases.gd::check_in_flight_ignores_second_call`（窗口分类 `update`） |
| `manifest_url` 为空串时自动检查与「立即检查」都不发请求、不显示提示 | `tests/update_ui_cases.gd::empty_manifest_url_sends_no_request`（窗口分类 `update`） |
| 宿主在入树前被释放时一并释放未入树的 `update_check`；入树宿主的检查节点有父节点 | `tests/update_ui_cases.gd::host_free_releases_unparented_check`（窗口分类 `update`） |
| `spire-godot/update/` 不引用 `ui`／`core`／`data`／`tests`；只有 `spire-godot/update/update_check.gd` 发 HTTP | `tests/architecture_cases.gd::update_module_is_a_leaf`（规则分类 `architecture`） |
| 版本比较只有 `spire-godot/update/update_manifest.gd::compare`／`evaluate`／`is_newer`／`_revoked` | `tests/architecture_cases.gd::update_compare_single_entry`（规则分类 `architecture`） |
| 更新模块的 JSON 解析只有 `spire-godot/update/update_manifest.gd::document`（清单与补丁状态共用） | `tests/architecture_cases.gd::update_document_single_entry`（规则分类 `architecture`） |
| 键加载与验签只有 `spire-godot/update/update_manifest.gd::_verified` | `tests/architecture_cases.gd::update_verify_single_entry`（规则分类 `architecture`） |
| 更新特性面只有 `spire-godot/update/update_check.gd` 一处 HTTP | `tests/architecture_cases.gd::update_http_single_entry`（规则分类 `architecture`） |
| 跳转只有 `spire-godot/ui/main.gd::_open_update_url` 一处 `OS.shell_open` | `tests/architecture_cases.gd::update_jump_single_entry`（规则分类 `architecture`） |
| 调用 `openssl dgst` 并带 `-sign` 的只有 `spire-godot/tools/sign-update-manifest.ps1`（扫描 `tools/**/*.ps1` 与 `**/*.gd` 的源码文本） | `tests/architecture_cases.gd::update_sign_single_entry`（规则分类 `architecture`） |
| 写出 `manifest.json.sig` 的只有 `spire-godot/tools/sign-update-manifest.ps1`：别处点名 `.sig` 文件且写文件的作用域即红 | `tests/architecture_cases.gd::update_signature_write_single_entry`（规则分类 `architecture`） |
| 写出带 `key_id` 与 `platforms` 的更新清单的只有 `spire-godot/tools/update-manifest.ps1` | `tests/architecture_cases.gd::update_manifest_write_single_entry`（规则分类 `architecture`） |
| 已验证的 pending 补丁被挂载：有效版本＝补丁、基线不变；成功启动后 pending 转 active | `tests/update_cases.gd::boot_mounts_verified_pending`（规则分类 `update`） |
| 摘要或大小被破坏的补丁不挂载、记入 failed、文件删除、下次启动不再尝试 | `tests/update_cases.gd::boot_skips_bad_patch_and_records_failure`（规则分类 `update`） |
| 记录的基线与当前基线不符时清空 `patches/`、`staging/` 与状态 | `tests/update_cases.gd::boot_resets_on_baseline_change`（规则分类 `update`） |
| pending 替换 active：只挂载一个包，成功启动后 `patches/` 只剩新包 | `tests/update_cases.gd::boot_replaces_active_with_pending`（规则分类 `update`） |
| pending 校验失败而 active 完好时，pending 记 failed 并挂载 active | `tests/update_cases.gd::boot_falls_back_to_active_when_pending_fails`（规则分类 `update`） |
| 上次启动遗留的 mounting 标记使该版本记 failed 并跳过，不重试 | `tests/update_cases.gd::boot_skips_crash_residue`（规则分类 `update`） |
| 版本已在 failed 列表的完好补丁不挂载，条目与文件被清掉 | `tests/update_cases.gd::boot_skips_failed_version`（规则分类 `update`） |
| 不比基线新的补丁（等于或更旧）不挂载，记 failed 并清掉 | `tests/update_cases.gd::boot_skips_not_newer_patch`（规则分类 `update`） |
| 标记写不进去（`begin_mount` 为假）时不挂载任何包 | `tests/update_cases.gd::boot_requires_marker_before_mount`（规则分类 `update`） |
| 标记写不进去只跳过当前候选、不记 failed，条目与文件保留，下次能写时同一候选照常挂载 | `tests/update_cases.gd::boot_keeps_candidate_when_marker_unwritable`（规则分类 `update`） |
| `--script` 运行不挂载、不触碰补丁状态，有效版本等于基线 | `tests/update_cases.gd::boot_is_inert_under_script`（规则分类 `update`） |
| `record_mounted` 移动有效版本、基线不动、`identity` 带基线；空串回到基线 | `tests/update_cases.gd::effective_version_follows_mount`（规则分类 `update`） |
| 记录了但没挂上（状态里有 active、引擎拒绝挂载）时有效版本仍是基线 | `tests/update_cases.gd::effective_version_requires_mount`（规则分类 `update`） |
| `verify_patch_file` 的字节数、小写摘要、缺失文件、目录与空包；`is_newer` 严格大于 | `tests/update_cases.gd::patch_file_verification_domain`（规则分类 `update`） |
| 状态文件的敌意输入（路径穿越、坏字段、坏 JSON）被丢弃，版本不合文法不成路径 | `tests/update_cases.gd::store_rejects_hostile_state`（规则分类 `update`） |
| `run/main_scene` 是可实例化的引导场景，`config/name` 不含版本 | `tests/update_cases.gd::main_scene_is_boot_scene`（规则分类 `update`） |
| 默认挂载器经真实 `load_resource_pack` 让包内文件在 `res://` 可见；真实挂载只在子引擎进程里做（探针 `tests/fixtures/update/mount_probe.gd`），测试进程自己不挂载 | `tests/update_cases.gd::engine_mounter_loads_a_real_pack`（规则分类 `update`） |
| `update` 套件跑完后同进程里 `res://build` 仍可建、可删目录（防真实挂载再回到共享的规则进程）；**不变量**：该检查必须是 `run()` 的最后一次调用，否则其后加入的挂载发现不了（核对见下一行） | `tests/update_cases.gd::suite_leaves_res_build_writable`（规则分类 `update`） |
| `suite_leaves_res_build_writable` 是 `run()` 的最后一次调用（把任一调用挪到它之后即红）；源码经 `tests/source_text.gd::normalized_text` 读入（CRLF 与 LF 检出同判），按块尾锚定 `run()`（到下一个顶格的非空、非注释行为止），空行与注释不影响；`run()` 内的调用保持一行一条语句、缩进一个空格，更深缩进的续行判红 | `tests/update_cases.gd::run_ends_with_writable_check`（规则分类 `update`） |
| 超时分支确定性回收：挂不退出的子进程在限时后被杀且已退出（用不启引擎的替身子进程构造，因真实探针平时不会超时） | `tests/update_cases.gd::child_reaper_stops_a_hung_child`（规则分类 `update`） |
| 已挂载的版本进入窗口标题与反馈报告 | `tests/update_ui_cases.gd::mounted_version_reaches_title_and_report`（窗口分类 `update`） |
| 记录了但没挂上的补丁不进标题与反馈报告，二者报基线 | `tests/update_ui_cases.gd::unmounted_patch_reports_baseline`（窗口分类 `update`） |
| 启动恢复之后清标记并提升本进程已挂载的 pending；未挂载的 pending 不提升 | `tests/update_ui_cases.gd::start_marks_boot_succeeded`（窗口分类 `update`） |
| 读取 `application/config/version` 的只有 `spire-godot/update/update_store.gd::baseline_version`（扫描全部 `.gd`） | `tests/architecture_cases.gd::version_read_single_entry`（规则分类 `architecture`） |
| `user://updates` 只由 `spire-godot/update/update_store.gd` 提及（扫描全部 `.gd`） | `tests/architecture_cases.gd::update_store_is_single_writer`（规则分类 `architecture`） |

## 单一路径（邻接表）

每个语义只有一个入口；边用稳定符号声明，判据一列只点名执行该边的检查。

| 语义 | 唯一入口 | 边 | 机械判据 |
| --- | --- | --- | --- |
| 判定（解析／验签／版本比较／撤回） | `spire-godot/update/update_manifest.gd::evaluate` | `::document`、`::_public_material`、`::_verified`、`::compare`、`::_revoked` | `spire-godot/tests/update_cases.gd` 的 UPDATE 具名 check；`spire-godot/tests/architecture_cases.gd::update_compare_single_entry`（版本比较）、`::update_document_single_entry`（解析）、`::update_verify_single_entry`（验签） |
| 网络（清单与签名各一次 GET） | `spire-godot/update/update_check.gd::check` | `::_secure_url`、`::_send`、`::deliver`，结果交 `spire-godot/update/update_manifest.gd::evaluate` | `spire-godot/tests/update_ui_cases.gd::startup_offline_is_silent`、`::transport_failures_are_silent`、`::check_in_flight_ignores_second_call`（在途重入）；`spire-godot/tests/architecture_cases.gd::update_http_single_entry`（唯一 HTTP 文件） |
| 启动门槛 | `spire-godot/update/update_check.gd::auto_allowed` | `::scripted_run`、`::_secure_url`、`ui/display_settings.gd::update_check_enabled` | `spire-godot/tests/update_ui_cases.gd::toggle_off_skips_startup`、`::empty_manifest_url_sends_no_request`（空 `manifest_url`） |
| 设置写入 | `spire-godot/ui/display_settings.gd::set_update_check` | `::save` 写同一文件的 `update/check_on_start` | `spire-godot/tests/update_cases.gd::settings_toggle_uses_one_store` |
| 设置读取 | `spire-godot/ui/display_settings.gd::initialize` | 同一文件的 `update/check_on_start` | `spire-godot/tests/update_ui_cases.gd::toggle_off_skips_startup` |
| 主页提示 | `spire-godot/ui/main.gd::_home_update_notice` | 只读 `spire-godot/update/update_check.gd::offer`；由 `spire-godot/ui/home_screen.gd` 调用 | `spire-godot/tests/update_ui_cases.gd::startup_offer_renders_notice`、`::check_in_flight_keeps_home_interactive`（检查进行中主页可交互） |
| 设置页状态 | `spire-godot/ui/main.gd::_update_status_text` | 只读 `offer` 与 `busy` | `spire-godot/tests/update_ui_cases.gd::toggle_off_skips_startup` |
| 跳转 | `spire-godot/ui/main.gd::_open_update_url` | `open_url`，默认 `OS.shell_open` | `spire-godot/tests/update_ui_cases.gd::startup_offer_renders_notice`；`spire-godot/tests/architecture_cases.gd::update_jump_single_entry`（唯一 `OS.shell_open`） |
| 生产键表 | `spire-godot/update/update_keys.gd::KEYS` | `spire-godot/update/update_check.gd::keys` 的默认值；签名脚本的比较对象 | `spire-godot/tests/update_cases.gd::production_key_table_pins_k1` |
| 清单生成（发布侧） | `spire-godot/tools/update-manifest.ps1` | `spire-godot/tools/update-manifest.ps1::Add-Platform` 建平台条目，`spire-godot/tools/update-manifest-check.ps1::Assert-UpdateManifest` 回读自检（唯一实现，签名器共用）；Android 哈希读 `tools/package-android.ps1` 写出的 `manifest.json` | `spire-godot/tests/update_cases.gd::release_scripts_manifest_interops`；`spire-godot/tests/architecture_cases.gd::update_manifest_write_single_entry`（唯一清单写出点） |
| 发行 ZIP 的 SHA256 | `spire-godot/tools/update-manifest.ps1`（`Get-FileHash`，一次） | 写入清单 `platforms.windows-x64.full.sha256`；`docs/spec/packaging.md` 的人工步骤只引用该值 | `spire-godot/tests/update_cases.gd::release_scripts_manifest_interops`（清单值等于 ZIP 独立重算） |
| 签名（发布侧） | `spire-godot/tools/sign-update-manifest.ps1` | 签名前先调 `spire-godot/tools/update-manifest-check.ps1::Assert-UpdateManifest` 回读自检；`spire-godot/tools/sign-update-manifest.ps1::Read-KeyTable` 读 `spire-godot/update/update_keys.gd::KEYS`，`spire-godot/tools/sign-update-manifest.ps1::Invoke-OpenSsl` 签名与复核 | `spire-godot/tests/update_cases.gd::release_scripts_manifest_interops`；`spire-godot/tests/architecture_cases.gd::update_sign_single_entry`（唯一 `openssl dgst -sign`）、`::update_signature_write_single_entry`（唯一 `.sig` 写出点） |
| 版本身份 | `spire-godot/update/update_store.gd::baseline_version`（基线）、`::effective_version`（有效版本） | `::record_mounted`（有效版本的唯一写入，只由 `spire-godot/update/boot.gd::start` 调用）；窗口标题 `spire-godot/ui/main.gd::_ready`、反馈报告 `spire-godot/ui/feedback_report.gd::_capture_context`、清单判定 `spire-godot/update/update_check.gd::deliver` 读有效版本；`spire-godot/tools/release_probe.gd::run` 读基线 | `spire-godot/tests/update_cases.gd::effective_version_follows_mount`、`::effective_version_requires_mount`；`spire-godot/tests/update_ui_cases.gd::mounted_version_reaches_title_and_report`、`::unmounted_patch_reports_baseline`；`spire-godot/tests/architecture_cases.gd::version_read_single_entry`（唯一读取点） |
| 挂载 | `spire-godot/update/boot.gd::start` | `::engine_mount`（产品运行时唯一的 `load_resource_pack`）；`spire-godot/update/update_manifest.gd::verify_patch_file`、`::is_newer`；`spire-godot/update/update_store.gd::begin_mount`、`::mark_failed`、`::reset_for_baseline` | `spire-godot/tests/update_cases.gd::boot_mounts_verified_pending`、`::boot_skips_bad_patch_and_records_failure`、`::boot_resets_on_baseline_change`、`::boot_replaces_active_with_pending`、`::boot_falls_back_to_active_when_pending_fails`、`::boot_skips_crash_residue`、`::boot_is_inert_under_script`、`::child_reaper_stops_a_hung_child`、`::wait_or_reap`、`::run_ends_with_writable_check`、`::engine_mounter_loads_a_real_pack`（子进程里挂载，探针 `spire-godot/tests/fixtures/update/mount_probe.gd`）、`::suite_leaves_res_build_writable`、`::main_scene_is_boot_scene`、`::patch_file_verification_domain` |
| 补丁状态与用户目录 | `spire-godot/update/update_store.gd::write_state`（唯一写 `state.json`） | `::load_state`、`::patch_path`、`::mark_boot_succeeded`、`::clear_staging`；`user://updates` 只在该文件出现 | `spire-godot/tests/update_cases.gd::store_rejects_hostile_state`；`spire-godot/tests/architecture_cases.gd::update_store_is_single_writer` |
| 启动证明 | `spire-godot/ui/main.gd::_ready` 在 `_restore_startup` 之后调 `spire-godot/update/update_store.gd::mark_boot_succeeded` | 只提升本进程已挂载的 pending；玩家会话才构造 `update_store` | `spire-godot/tests/update_ui_cases.gd::start_marks_boot_succeeded` |

## 仍靠人审（无机械判据，本批保留）

- 公网清单的**部署与签名**：`update.magicspire.xyz/v1/manifest.json` 与其 `.sig` 尚未发布。
  这一步没做时，只能记「桌面接缝验收通过、公网未验收」，不得宣称已上线。
- 生产私钥的保管与生产签名（操作见 `skills/repo-ops/SKILL.md`「更新签名私钥保管」）没有机械判据；
  仓库、测试、日志与文档都不得出现私钥、口令或 Cloudflare 令牌。机械判据只钉住公钥一侧
  （`tests/update_cases.gd::production_key_table_pins_k1`）。
- Android 真机与真实网络（断网、代理、蜂窝）的行为：桌面接缝不能代表安卓验收。
- 发布侧脚本的拒签路径（清单不过回读自检：超过 65536 字节、BOM、CR、非严格 JSON、链接非 `https://`；
  私钥与表内公钥不配、`key_id` 无条目、已有 `.sig`、`-PassphraseEnv` 未设置或口令错误、签名后清单被改动）
  与生成器的拒绝路径（链接非 `https://` 或为空、超过 65536 字节、没有平台、`-Serial` 不是正整数、
  `-Revoked` 含不是字符串的元素、`-KeyId` 含换行或其它字符、ZIP 不存在、Android 包清单缺 `bytes`／`sha256`
  或 `sha256` 不是 64 位小写十六进制、版本不符、`-Out` 是相对路径），以及报错不回显 `-PassphraseEnv` 取值、
  Windows PowerShell 5.1 下按 `#Requires` 拒跑，都没有常驻门禁，证据是脚本实跑日志；
  「回读自检只有一份实现」与「人工步骤不另算发行 ZIP 的 SHA256」也没有机械扫描。
  唯一签名入口与唯一清单写出点由 `tests/architecture_cases.gd::update_sign_single_entry`、
  `::update_signature_write_single_entry`、`::update_manifest_write_single_entry` 按源码文本钉住。
  这三条判据识别不了：拆成多行的令牌；运行时拼出的文件名与清单键；`>` 重定向写文件（不计入「写文件」）；
  `openssl dgst -sign` 以外的签名原语——`openssl pkeyutl -sign`、.NET `SignData`／`SignHash`、引擎 `Crypto.sign`
  （现只在测试助手 `tests/update_cases.gd::signature_of`，签内存里的测试密钥）。PowerShell `<# #>` 块注释里的令牌
  按代码算，只会误红、不会漏报。
- 后续的下载安装阶段若要把下载的清单或 `.sig` 落到 `user://`，`tests/architecture_cases.gd::update_signature_write_single_entry` 或
  `tests/architecture_cases.gd::update_manifest_write_single_entry` 会具名变红：须同批更新这两条判据的期望集合与本文件，
  不得靠把「点名 `.sig`／清单键」与「写文件」拆到不同作用域让判据转绿。
- 引导挂载只在门禁替身与一次子引擎进程里的真实 `load_resource_pack` 上取证；真实导出成品上的行为没有机械判据：成品叠加补丁后 `res://` 被覆盖、
  `tools/check-package.ps1` 在引导场景作为 `run/main_scene` 时照常通过、冷启动耗时、挂载后工程设置是否重载（官方文档未写明）、
  Windows 文件属性仍显示基线。这些只能在导出成品上人工取证。
- 引导闭包（`update/boot.gd`、`update/update_store.gd`、`update/update_manifest.gd`）在挂载前已载入，本会话不会换成补丁里的版本；
  `update/update_check.gd` 与 `update/update_keys.gd` 在挂载之后才由 `ui/main.gd` 载入，可被补丁替换。
- 有效版本的一种缺陷没有机械判据：`spire-godot/update/update_store.gd::effective_version` 若改为读 `state.json` 的 `active.to`，
  门禁抓不到——用例只注入补丁目录，静态读取走默认的 `user://updates`，而用例从不读真实用户目录。
  `tests/update_cases.gd::effective_version_requires_mount` 只钉住等价的另一种缺陷：引擎拒绝挂载时仍记录有效版本。
- 不属于本片授权面：`spire-godot/tools/package*.ps1`、`spire-godot/core/**`、`spire-godot/data/**`；`docs/spec/packaging.md` 里的
  主场景与成品检查描述随后续补丁挂载的发布侧一并更新。
