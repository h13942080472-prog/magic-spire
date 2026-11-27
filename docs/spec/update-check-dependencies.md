# 更新检查：依赖约束

`docs/spec/update-check.md` 的依赖约束索引：判据的真源是下表点名的检查，散文不复述内容
（格式参照 `docs/spec/seed-feedback-dependencies.md`）。
本文件不写执行结果：通过、失败、未执行一律登记在 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`update/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 允许改动

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `spire-godot/update/update_manifest.gd`（新） | 纯函数：`evaluate(manifest_bytes, signature, keys, current, platform, local={})`、`compare(a, b)`、`is_newer`、`is_sha256`；补丁条目校验 `_patch_entry` 与匹配 `_matching_patch`、常量 `PATCH_PLATFORM`、`MAX_PATCH_BYTES`（256 MiB）；schema 1 的解析（唯一 JSON 解析入口 `document`，补丁状态共用）；`Crypto.verify`（SHA-256，RSA PKCS#1 v1.5）；包体判定 `verify_patch_file(path, bytes, sha256)`（只读指定文件，分块哈希） | 除 `verify_patch_file` 读它被指定的那一个文件外无 IO：不访问网络与单例状态；不读 `ProjectSettings`（当前版本与平台都由参数传入）；拒绝原因只有固定枚举 `signature/key/schema/platform/size/json/url`；「已验签但不是更新」用空 `reason`；验签只经 `_verified`，公钥以 `CryptoKey.load_from_string(pem, true)` 加载；键表条目含 `PRIVATE KEY` 时在 `key` 步拒绝；`local` 只喂补丁匹配，`local` 为空（含省略）时回答与不带补丁的清单逐字相同；补丁条目只经 `_patch_entry` 校验、只经 `_matching_patch` 匹配，`from` 对本机基线（`local.baseline`）比较而不对 `current`，`to` 必须等于最新版本且不在 `revoked` 与 `local.failed` 里，多条合格取第一条；坏条目只让该条不合格，已验签清单的完整包提示不受影响；`offer` 只在匹配成功时多一个 `patch` 键；补丁只为 `windows-x64` 匹配；复用 `is_sha256`、`compare`、`HTTPS`，不另写第二套判定 |
| `spire-godot/update/update_keys.gd`（新；写入 `k1`） | 常量 `KEYS = {key_id: 公钥 PEM}`；现只有 `k1`，条目是三引号 PEM 字面量 | **只放公钥**；不放私钥、口令或任何令牌；恰好一条 `k1`，DER sha256 钉住；轮换先并列加 `k2` 再切换清单 `key_id`；显式传入的空表仍让 `evaluate` 返回 `none`／`key` |
| `spire-godot/update/update_check.gd`（新） | `check()`、`deliver()`、`manifest_url()`、`platform_key()`、`scripted_run()`（转调 `spire-godot/update/update_store.gd::scripted_run`）、`auto_allowed()`、`keys`、`store` 注入口与 `_identity()`、`transport: Callable` 接缝、`HTTPRequest`（10 秒超时、`max_redirects=0`、`body_size_limit=65536`）、`checked(offer)` | 一次检查最多 2 个 GET；只用 HTTPS；不写盘；不重试；请求不带存档、种子、设备标识、账号或自定义标识头；失败一律静默；`[update]` 只在此文件读取；`deliver` 把 `_identity()` 交给 `evaluate`；`--script` 与非玩家会话下不构造默认 `update_store`（只有显式注入的 `store` 能给出身份，否则身份为空、不匹配补丁） |
| `spire-godot/project.godot` | 新增 `[update]` 段：`manifest_url`、`check_on_start`；`run/main_scene` 指向 `res://update/boot.tscn`；`config/name` 不带版本后缀（窗口标题的版本由 `ui/main.gd::_ready` 拼接） | 不改 `application/config/version`、`[feedback]`；不新增 `[autoload]`；`config/custom_user_dir_name*` 不变 |
| `spire-godot/update/boot.gd`、`spire-godot/update/boot.tscn`（新） | 引导场景与脚本：`start(store, mounter, session)`、`engine_mount(path)`；`_ready` 在玩家会话挂载后以场景路径字符串切到 `res://main.tscn` | 只预载 `update_store.gd` 与 `update_manifest.gd`；不引用 `ui`／`core`／`data`／`tests`；`ProjectSettings.load_resource_pack` 在产品运行时只在 `engine_mount` 一处（发布侧工具 `spire-godot/tools/patch_release_pck.gd` 除外）；`--script` 运行不挂载、不切场景；不触碰 `user://saves/` 与旧档导入标记 |
| `spire-godot/update/update_store.gd`（新） | 补丁状态与版本身份：`baseline_version`、`effective_version`、`record_mounted`、`identity`、`load_state`、`write_state`、`patch_path`、`mark_failed`、`begin_mount`、`mark_boot_succeeded`、`reset_for_baseline`、`clear_staging`、`valid_version`、`scripted_run`、`player_session`；目录可注入 | 全仓唯一读取 `application/config/version` 的文件、唯一写 `user://updates` 的文件；基线在进程内首次读取后冻结（存进 `Engine` meta，键为私有常量 `BASELINE_KEY`；补丁必然带 `project.binary`，挂载后工程设置是否重载未证实）；有效版本只由 `record_mounted` 写；版本经 `valid_version` 文法后才拼路径；状态文件经临时文件、回读、改名写入；不联网、不调用 `core/save_store.gd` |
| `spire-godot/ui/main.gd`、`spire-godot/ui/feedback_report.gd`、`spire-godot/tools/release_probe.gd`（版本身份） | `ui/main.gd::_ready` 的窗口标题＝`config/name`＋` v`＋有效版本，并在 `_restore_startup` 之后调 `mark_boot_succeeded`；`ui/feedback_report.gd::_capture_context` 读有效版本；`tools/release_probe.gd::run` 读基线版本 | 三处都经 `update_store.gd`，不再直接读版本设置；`update_store` 字段只在玩家会话构造（用例可注入）；不触碰存档 |
| `spire-godot/ui/display_settings.gd` | `update_check_enabled`、`set_update_check(enabled)`；既有 `user://display-settings.cfg` 的 `update/check_on_start` 一键 | 不新增 `user://` 文件、不新增设置存储；`initialize` 的复位与加载顺序不变；既有 setter 行为不变 |
| `spire-godot/ui/home_screen.gd`、`spire-godot/ui/main.gd` | 主页 `HomeUpdateNotice`、`HomeUpdateDownload`、`HomeUpdateMirror`（放在主页布局层，不在 `GameHome` 内）；设置页 `UpdateCheckEnabled`、`UpdateCheckNow`、`UpdateCheckStatus`；持有并启动 `update_check`；`open_url` 可替换的跳转接缝 | 主页左侧标题区仍是原来四个子节点；不改开局、继续、设置的入口与布局语义；检查不阻塞主页输入、不改 `Game` 状态与存档；不调用 `command_router` 或 `Game` 的任何写接口；版本比较、验签、解析不在 UI 里出现第二份；宿主在入树前被释放时（`_notification` 的 `NOTIFICATION_PREDELETE`）一并释放未入树的 `update_check` |
| `spire-godot/assets/localization/zh_CN.json`、`en_US.json`、`ja_JP.json` | 新增 `ui.update.*` 与 `ui.settings.update_check*`、`ui.settings.update_now` 十条 ID 的文案与译文 | 既有 ID 与文案不变；`en_US`／`ja_JP` 的 `source` 与中文原文逐字相同；不删条目 |
| `spire-godot/tests/update_cases.gd`（新）、`spire-godot/tests/update_ui_cases.gd`（新）、`spire-godot/tests/interface_ui_cases.gd`（版本期望）、`spire-godot/tests/test_game.gd` 的 `SUITES`、`spire-godot/tests/ui_smoke.gd` 的 `UI_MODULES` | 本契约的具名 check；登记 `update` suite；补丁存储只注入 `res://build/` 下的独立目录，从不读写真实 `user://updates`；期望版本读 `spire-godot/update/update_store.gd::effective_version` | 现场 `Crypto.generate_rsa` 生成密钥对并把公钥交给 `evaluate`；`spire-godot/tests/fixtures/update/` 只提交公钥 PEM、清单与签名（OpenSSL 互通夹具；`release-scripts/` 另含五份脚本输入），**不提交任何私钥**；补丁导出的可行性夹具由用例在 `res://build/` 下现场写出，经 `OS.execute` 调真实的 `tools/export-patch.ps1 -CheckOnly`，不在 GDScript 里重写判定；不联网（只用 `transport` 替身）；不删除、不放宽既有的 HOME 断言 |
| `spire-godot/tests/architecture_cases.gd::update_module_is_a_leaf` | 新增 `update/` 的禁止边（不引用 `ui`／`core`／`data`／`tests`；`core`／`data` 不引用 `update`；只有 `update_check.gd` 发 HTTP）；新增五条单点判据 `update_compare_single_entry`、`update_document_single_entry`、`update_verify_single_entry`、`update_http_single_entry`、`update_jump_single_entry`；新增两条判据 `version_read_single_entry`、`update_store_is_single_writer` 及扫描助手 `update_gd_files` | 既有判定函数与既有边不变；`update_compare_single_entry` 的期望集合含 `is_newer`，`update_document_single_entry` 的期望是 `document` |
| `spire-godot/tests/architecture_cases.gd`（发布侧加固） | 新增三条发布侧单点判据 `update_sign_single_entry`、`update_signature_write_single_entry`、`update_manifest_write_single_entry` 及扫描助手 `update_release_files`、`update_release_scopes`、`update_release_matches` | 只读源码文本，不调用脚本；扫描 `tools/**/*.ps1` 与 `**/*.gd`，只跳过 `.gitignore` 忽略的目录；既有判定函数与既有边不变 |
| `spire-godot/tests/fixtures/update/` 的 `.gitattributes`（新） | 把脚本产出与脚本输入的夹具标为 `-text`，让检出字节等于签名字节 | 不改夹具内容；不引入第二份夹具 |
| `spire-godot/tools/update-manifest.ps1`、`spire-godot/tools/sign-update-manifest.ps1`、`spire-godot/tools/update-manifest-check.ps1`（新） | 唯一清单生成入口与唯一签名入口，接口见 `docs/spec/update-check.md`「发布侧脚本」；两者 dot-source 的回读自检 `spire-godot/tools/update-manifest-check.ps1::Assert-UpdateManifest`（含补丁条目回读：`from`／`to` 非空、`to` 等于 `latest.version`、`url`／`mirror` 为 `https://`、`bytes` 为 (0, 256 MiB] 的整数、`sha256` 为 64 位小写十六进制、`(from, to)` 不重复）；生成器的补丁条目参数 `-WindowsPatchMeta`／`-WindowsPatchUrl`／`-WindowsPatchMirror` | 与游戏代码零依赖（签名脚本只按文本读 `update/update_keys.gd`）；回读自检只有这一份实现，生成器回读临时文件、签名器签名前回读 `-Manifest` 都调用它；Android 哈希只取自包清单、Windows ZIP 哈希只在生成器算一次；补丁条目的 `from`／`to`／`bytes`／`sha256` 只取自 `export-patch.ps1` 写的元信息 JSON，生成器不重算；`-Revoked` 只收字符串元素；拒签与拒绝路径不留输出；不接受口令明文参数，不打印私钥、口令或其哈希，报错不回显 `-PrivateKey` 与 `-PassphraseEnv` 的取值；两份脚本 `#Requires -Version 7.0`；`-KeyTable` 只作测试接缝 |
| `spire-godot/tools/export-patch.ps1`、`spire-godot/tools/export-patch-feasibility.ps1`（新） | 补丁 PCK 的唯一生成入口与它 dot-source 的可行性判定 `Test-PatchFeasibility`；参数 `-BasePackage`、`-BaseVersion`、`-Out`、`-CheckOnly`、`-ProjectRoot`、`-BaseRef`，测试接缝 `-BaseSourceDirectory`、`-EngineVersion`；接口见 `docs/spec/update-check.md`「发布侧脚本」 | `#Requires -Version 7.0`；先判定后导出，任一判定命中或任何步骤失败都非零退出且不留 `-Out` 与暂存目录；基线源只取自基线版本标签（或 `-BaseRef`）的 git 对象，取不到即拒绝、不默认放行；补丁的哈希只在这里算一次；只经 Godot 命令行 `--export-patch`／`--patches` 导出；与游戏代码零依赖 |
| `spire-godot/tools/package.ps1::Get-RuntimeFingerprint`、`spire-godot/tools/package-android.ps1::Get-SourceFingerprint` | 路径集合加入 `update` | 只改路径集合：导出期间 `update/` 下的改动与 `core`／`ui` 一样会被源码稳定性检查发现；不改打包流程与产出 |
| `spire-godot/tools/check.ps1::Get-SourceFingerprint` | 目录集合加入 `update` | 只改目录集合；指纹仍只作同一次运行内的守卫（`before==after`），不当身份，没有冻结值依赖它 |
| `spire-godot/tests/fixtures/update/release-scripts/`（新） | 两份脚本用一次性密钥产出的清单与签名，及一次性公钥、`notes.txt`、`android-package-manifest.json`、`windows.zip`、`patch.pck`（占位包，其独立哈希须等于元信息）、`patch-meta.json`（`export-patch.ps1` 元信息的形状）五份输入；同目录 `.gitattributes` 标 `-text` | 只经脚本生成；**不提交任何私钥**；既有 OpenSSL 夹具不变 |
| `spire-godot/tests/fixtures/update/manifest-check/`（新） | `good.json`（补丁条目完好）与十一份各违反一条回读规则的 `bad-*.json`，及只调用 `Assert-UpdateManifest` 并打印结论的 `assert-manifest.ps1`；同目录 `.gitattributes` 标 `-text` | 夹具只在 `tests/update_cases.gd::update_manifest_patch_entries_are_judged` 里经 pwsh 真实运行；harness 不自带判定；不在 GDScript 里重写判定 |
| `spire-godot/tests/state_readers.json`（生成物） | 由 `tools/build_state_readers.gd --write` 重写，登记 `update/` 的读取点 | 只经工具写入；不手工编辑；他行不变 |
| `spire-godot/tests/check_index_edges.gd::CLOSURE` | 新增 `spire-godot/update/` 前缀条目：规则 `update,architecture`、界面 `update`；索引只扫 `core|data|ui`，不加这条则 `update/` 下改动落到 `ROUTE UNMAPPED` 而退回全量 | 只增这一条；窗口标题与反馈报告的断言经 `ui/main.gd`、`ui/feedback_report.gd` 既有的边路由到 `interface`，不在此重复 |
| `spire-godot/tests/check_index.json`（生成物） | 由 `tools/check-index.ps1 -Write` 重冻，登记 `update/` 与新增测试文件 | 只经工具写入；不手工编辑；他行不变 |
| `spire-godot/tests/update_cases.gd.uid`、`spire-godot/tests/update_ui_cases.gd.uid`（新） | 引擎生成的脚本 UID 旁文件 | 只经引擎导入写入；不手工编辑 |
| `spire-godot/tests/mutations.json` | 为本片具名 check 追加条目（含引导挂载、有效版本与两条新架构判据；补丁匹配、条目校验、身份传递与导出可行性各一条） | 既有条目、`known_gaps` 与冻结清单不变；`find` 仍唯一 |
| `docs/spec/update-check.md`、`docs/spec/update-check-dependencies.md`、根 `AGENTS.md` 文档入口表、`docs/spec/project-map.md` 目录表 | 本契约落盘 | `docs/spec/` 被取代即删 |
| `docs/spec/packaging.md` | 流水线加「生成并签名更新清单」一步，链接本契约；两处人工「生成最终 ZIP」步骤的 SHA256 改为引用清单里的值 | 发行 ZIP 的 SHA256 只有清单一个来源，人工步骤不另算；其余打包契约不变；补丁 PCK 的增补：每版发行包仓外归档、可选步骤「生成补丁」（`tools/export-patch.ps1` → 成品叠加验收 → 上传桶与 GitHub Release → 核对公网 → `update-manifest.ps1` → 签名 → 最后上传清单与 `.sig`）、首个含引导场景的版本只发完整包 |

## 判据 → 检查

判据名＝测试里的具名 check（断言标签 `UPDATE <name>:`／`DEP <name>:` 的 `<name>`，也是该 check 的函数名）。
表与 `tests/update_cases.gd`、`tests/update_ui_cases.gd`、`tests/architecture_cases.gd` 的 update 具名 check
**双向相等**：一条判据一行，一行只点名一个检查；漏行、多行、改名或幽灵条目都要同批改表。
本版共 80 条（规则 57、窗口 12、架构 11），按 `tests/<file>.gd::<name>` 逐名核对。

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
| 五参调用（无本机身份）时 `patches` 不产生补丁结果、不进 `offer` | `tests/update_cases.gd::patches_are_ignored`（规则分类 `update`） |
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
| 版本比较只有 `spire-godot/update/update_manifest.gd::compare`／`evaluate`／`is_newer`／`_revoked`／`_matching_patch` | `tests/architecture_cases.gd::update_compare_single_entry`（规则分类 `architecture`） |
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
| 按基线匹配：`from` 等于本机基线、`to` 等于最新版本、字段全合格 → `offer.patch` 恰有六个字段；多条合格取第一条；`from` 按版本比较；Android 不匹配；完整包字段仍在 | `tests/update_cases.gd::patch_matches_baseline`（规则分类 `update`） |
| 按有效版本误配：只有 `from` 等于有效版本的条目、`to` 不是最新版本、身份没有基线都不给补丁，完整包提示仍在 | `tests/update_cases.gd::patch_ignores_effective_version_match`（规则分类 `update`） |
| 不再反复提示：有效版本已是最新 → `none`／空 reason；同一清单在未挂载的版本上仍是 `notice` 且带补丁 | `tests/update_cases.gd::patch_not_reoffered_once_mounted`（规则分类 `update`） |
| 撤回与失败：当前版本被撤回仍提示且仍可带补丁；`to` 在 `revoked` 或在本机 `failed` 里 → 无补丁，其它版本失败不影响 | `tests/update_cases.gd::patch_withdrawn_or_failed_is_dropped`（规则分类 `update`） |
| 坏条目与兼容：哈希畸形、`bytes` 越界或非整数、非 `https`、缺字段、非对象条目、`patches` 非数组只让该条不合格，完整包提示仍在；恰好 256 MiB 合格；无本机身份时 `offer` 与五参调用逐字相同 | `tests/update_cases.gd::patch_entry_domain_and_compat`（规则分类 `update`） |
| 生产调用点把本机身份交给 `evaluate`：注入的存储给出身份时有补丁，目标已失败时无补丁，`--script` 下没有存储时无补丁 | `tests/update_cases.gd::check_passes_identity_to_evaluate`（规则分类 `update`） |
| 补丁导出的可行性判定经 `spire-godot/tools/export-patch.ps1` 真实运行：内容包有改、增、删，`project.godot` 或导出预设有版本以外的差异，引导闭包五个文件各有改动，基线没有引导场景，引擎不同，基线源取不到，主 PCK 与包清单不符，包清单缺失，都非零退出且不留输出；全部相同则可行 | `tests/update_cases.gd::export_patch_feasibility_domain`（规则分类 `update`） |
| 补丁导出前断言内容包根为发布值：开发树上以导出模式（非 `-CheckOnly`）运行可行的夹具，在启动引擎之前因 `PACKS_ROOT` 不是 `adjacent` 而非零退出，不留输出与暂存目录；`-CheckOnly` 在开发树上不受此断言；发布值通过断言并走到引擎步骤（判据以不存在的引擎路径收场，从不启动引擎） | `tests/update_cases.gd::export_patch_requires_release_packs_root`（规则分类 `update`） |
| 引擎步骤的失败出口经 `-EngineBinary` 接缝（`.cmd` 替身，不启动引擎）：替身写出完好的包与日志时发布 `-Out`；退出码非零（即使包与日志完好）、空包、最后一步移动失败都非零退出、不留 `-Out`、不留暂存目录，且不覆盖 `-Out` 处已有的内容 | `tests/update_cases.gd::export_patch_engine_failure_leaves_nothing`（规则分类 `update`） |
| 引擎退出 0 且有包，但日志里有 `ERROR:` 行 → 非零退出、不留 `-Out`、不留暂存目录 | `tests/update_cases.gd::export_patch_engine_error_log_is_failure`（规则分类 `update`） |
| `Assert-UpdateManifest` 的补丁条目回读规则经 pwsh 真实运行夹具：完好条目通过；`from` 为空、`to` 不等于 `latest.version`、`url` 或 `mirror` 不是 `https://`、`bytes` 为 0／超过 256 MiB／非整数、`sha256` 大写、不足 64 位或末尾带换行（`\z` 锚）、`(from, to)` 重复，各被自己的规则拒绝 | `tests/update_cases.gd::update_manifest_patch_entries_are_judged`（规则分类 `update`） |
| 版本已在 failed 列表的完好补丁不挂载，条目与文件被清掉 | `tests/update_cases.gd::boot_skips_failed_version`（规则分类 `update`） |
| 不比基线新的补丁（等于或更旧）不挂载，记 failed 并清掉 | `tests/update_cases.gd::boot_skips_not_newer_patch`（规则分类 `update`） |
| 标记写不进去（`begin_mount` 为假）时不挂载任何包 | `tests/update_cases.gd::boot_requires_marker_before_mount`（规则分类 `update`） |
| 标记写不进去只跳过当前候选、不记 failed，条目与文件保留，下次能写时同一候选照常挂载 | `tests/update_cases.gd::boot_keeps_candidate_when_marker_unwritable`（规则分类 `update`） |
| `--script` 运行不挂载、不触碰补丁状态，有效版本等于基线 | `tests/update_cases.gd::boot_is_inert_under_script`（规则分类 `update`） |
| `record_mounted` 移动有效版本、基线不动、`identity` 带基线；空串回到基线 | `tests/update_cases.gd::effective_version_follows_mount`（规则分类 `update`） |
| 记录了但没挂上（状态里有 active、引擎拒绝挂载）时有效版本仍是基线 | `tests/update_cases.gd::effective_version_requires_mount`（规则分类 `update`） |
| 基线在进程内冻结：首次读取之后工程设置的 `application/config/version` 被改写，`baseline_version`、无挂载时的 `effective_version` 与 `identity().baseline` 仍是原值 | `tests/update_cases.gd::baseline_version_is_frozen`（规则分类 `update`） |
| `verify_patch_file` 的字节数、小写摘要、缺失文件、目录与空包；`is_newer` 严格大于 | `tests/update_cases.gd::patch_file_verification_domain`（规则分类 `update`） |
| 状态文件的敌意输入（路径穿越、坏字段、坏 JSON）被丢弃，版本不合文法不成路径 | `tests/update_cases.gd::store_rejects_hostile_state`（规则分类 `update`） |
| `run/main_scene` 是可实例化的引导场景，`config/name` 不含版本 | `tests/update_cases.gd::main_scene_is_boot_scene`（规则分类 `update`） |
| 默认挂载器经真实 `load_resource_pack` 让包内文件在 `res://` 可见 | `tests/update_cases.gd::engine_mounter_loads_a_real_pack`（规则分类 `update`） |
| 已挂载的版本进入窗口标题与反馈报告 | `tests/update_ui_cases.gd::mounted_version_reaches_title_and_report`（窗口分类 `update`） |
| 记录了但没挂上的补丁不进标题与反馈报告，二者报基线 | `tests/update_ui_cases.gd::unmounted_patch_reports_baseline`（窗口分类 `update`） |
| 启动恢复之后清标记并提升本进程已挂载的 pending；未挂载的 pending 不提升 | `tests/update_ui_cases.gd::start_marks_boot_succeeded`（窗口分类 `update`） |
| 读取 `application/config/version` 的只有 `spire-godot/update/update_store.gd::baseline_version`（扫描全部 `.gd`） | `tests/architecture_cases.gd::version_read_single_entry`（规则分类 `architecture`） |
| `user://updates` 只由 `spire-godot/update/update_store.gd` 提及（扫描全部 `.gd`） | `tests/architecture_cases.gd::update_store_is_single_writer`（规则分类 `architecture`） |

## 单一路径（邻接表）

每个语义只有一个入口；边用稳定符号声明，判据一列只点名执行该边的检查。

| 语义 | 唯一入口 | 边 | 机械判据 |
| --- | --- | --- | --- |
| 判定（解析／验签／版本比较／撤回） | `spire-godot/update/update_manifest.gd::evaluate` | `::document`、`::_public_material`、`::_verified`、`::compare`、`::_revoked`、`::_patch_entry`、`::_matching_patch` | `spire-godot/tests/update_cases.gd` 的 UPDATE 具名 check；`spire-godot/tests/architecture_cases.gd::update_compare_single_entry`（版本比较）、`::update_document_single_entry`（解析）、`::update_verify_single_entry`（验签） |
| 补丁匹配 | `spire-godot/update/update_manifest.gd::_matching_patch`（由 `evaluate` 的第六个参数 `local` 驱动） | `::_patch_entry` 校验条目；本机身份来自 `spire-godot/update/update_store.gd::identity`，经 `spire-godot/update/update_check.gd::_identity` 交给 `evaluate`（唯一生产调用点 `::deliver`） | `spire-godot/tests/update_cases.gd::patch_matches_baseline`、`::patch_ignores_effective_version_match`、`::patch_not_reoffered_once_mounted`、`::patch_withdrawn_or_failed_is_dropped`、`::patch_entry_domain_and_compat`、`::check_passes_identity_to_evaluate` |
| 网络（清单与签名各一次 GET） | `spire-godot/update/update_check.gd::check` | `::_secure_url`、`::_send`、`::deliver`，结果交 `spire-godot/update/update_manifest.gd::evaluate` | `spire-godot/tests/update_ui_cases.gd::startup_offline_is_silent`、`::transport_failures_are_silent`、`::check_in_flight_ignores_second_call`（在途重入）；`spire-godot/tests/architecture_cases.gd::update_http_single_entry`（唯一 HTTP 文件） |
| 启动门槛 | `spire-godot/update/update_check.gd::auto_allowed` | `::scripted_run`、`::_secure_url`、`ui/display_settings.gd::update_check_enabled` | `spire-godot/tests/update_ui_cases.gd::toggle_off_skips_startup`、`::empty_manifest_url_sends_no_request`（空 `manifest_url`） |
| 设置写入 | `spire-godot/ui/display_settings.gd::set_update_check` | `::save` 写同一文件的 `update/check_on_start` | `spire-godot/tests/update_cases.gd::settings_toggle_uses_one_store` |
| 设置读取 | `spire-godot/ui/display_settings.gd::initialize` | 同一文件的 `update/check_on_start` | `spire-godot/tests/update_ui_cases.gd::toggle_off_skips_startup` |
| 主页提示 | `spire-godot/ui/main.gd::_home_update_notice` | 只读 `spire-godot/update/update_check.gd::offer`；由 `spire-godot/ui/home_screen.gd` 调用 | `spire-godot/tests/update_ui_cases.gd::startup_offer_renders_notice`、`::check_in_flight_keeps_home_interactive`（检查进行中主页可交互） |
| 设置页状态 | `spire-godot/ui/main.gd::_update_status_text` | 只读 `offer` 与 `busy` | `spire-godot/tests/update_ui_cases.gd::toggle_off_skips_startup` |
| 跳转 | `spire-godot/ui/main.gd::_open_update_url` | `open_url`，默认 `OS.shell_open` | `spire-godot/tests/update_ui_cases.gd::startup_offer_renders_notice`；`spire-godot/tests/architecture_cases.gd::update_jump_single_entry`（唯一 `OS.shell_open`） |
| 生产键表 | `spire-godot/update/update_keys.gd::KEYS` | `spire-godot/update/update_check.gd::keys` 的默认值；签名脚本的比较对象 | `spire-godot/tests/update_cases.gd::production_key_table_pins_k1` |
| 清单生成（发布侧） | `spire-godot/tools/update-manifest.ps1` | `spire-godot/tools/update-manifest.ps1::Add-Platform` 建平台条目，`spire-godot/tools/update-manifest-check.ps1::Assert-UpdateManifest` 回读自检（唯一实现，签名器共用）；Android 哈希读 `tools/package-android.ps1` 写出的 `manifest.json`，补丁条目读 `spire-godot/tools/export-patch.ps1` 写的元信息 JSON | `spire-godot/tests/update_cases.gd::release_scripts_manifest_interops`；`spire-godot/tests/architecture_cases.gd::update_manifest_write_single_entry`（唯一清单写出点） |
| 补丁生成与可行性判定（发布侧） | `spire-godot/tools/export-patch.ps1` | `spire-godot/tools/export-patch-feasibility.ps1::Test-PatchFeasibility`（内容包逐文件哈希、`project.godot`、导出预设、引导闭包、基线无引导场景五条判定，外加基线包自检与引擎一致）；补丁的哈希只在此处算一次，元信息 JSON 交给 `spire-godot/tools/update-manifest.ps1`；导出前经 `spire-godot/tools/assert-packs-root.ps1::Assert-SpirePacksRoot` 断言 `PACKS_ROOT` 为 `adjacent`（与 `tools/package.ps1` 同一函数，不复制判定） | `spire-godot/tests/update_cases.gd::export_patch_feasibility_domain`、`::export_patch_requires_release_packs_root` |
| 发行 ZIP 的 SHA256 | `spire-godot/tools/update-manifest.ps1`（`Get-FileHash`，一次） | 写入清单 `platforms.windows-x64.full.sha256`；`docs/spec/packaging.md` 的人工步骤只引用该值 | `spire-godot/tests/update_cases.gd::release_scripts_manifest_interops`（清单值等于 ZIP 独立重算） |
| 签名（发布侧） | `spire-godot/tools/sign-update-manifest.ps1` | 签名前先调 `spire-godot/tools/update-manifest-check.ps1::Assert-UpdateManifest` 回读自检；`spire-godot/tools/sign-update-manifest.ps1::Read-KeyTable` 读 `spire-godot/update/update_keys.gd::KEYS`，`spire-godot/tools/sign-update-manifest.ps1::Invoke-OpenSsl` 签名与复核 | `spire-godot/tests/update_cases.gd::release_scripts_manifest_interops`；`spire-godot/tests/architecture_cases.gd::update_sign_single_entry`（唯一 `openssl dgst -sign`）、`::update_signature_write_single_entry`（唯一 `.sig` 写出点） |
| 版本身份 | `spire-godot/update/update_store.gd::baseline_version`（基线）、`::effective_version`（有效版本） | `::record_mounted`（有效版本的唯一写入，只由 `spire-godot/update/boot.gd::start` 调用）；窗口标题 `spire-godot/ui/main.gd::_ready`、反馈报告 `spire-godot/ui/feedback_report.gd::_capture_context`、清单判定 `spire-godot/update/update_check.gd::deliver` 读有效版本；`spire-godot/tools/release_probe.gd::run` 读基线 | `spire-godot/tests/update_cases.gd::effective_version_follows_mount`、`::effective_version_requires_mount`；`spire-godot/tests/update_ui_cases.gd::mounted_version_reaches_title_and_report`、`::unmounted_patch_reports_baseline`；`spire-godot/tests/architecture_cases.gd::version_read_single_entry`（唯一读取点） |
| 挂载 | `spire-godot/update/boot.gd::start` | `::engine_mount`（产品运行时唯一的 `load_resource_pack`）；`spire-godot/update/update_manifest.gd::verify_patch_file`、`::is_newer`；`spire-godot/update/update_store.gd::begin_mount`、`::mark_failed`、`::reset_for_baseline` | `spire-godot/tests/update_cases.gd::boot_mounts_verified_pending`、`::boot_skips_bad_patch_and_records_failure`、`::boot_resets_on_baseline_change`、`::boot_replaces_active_with_pending`、`::boot_falls_back_to_active_when_pending_fails`、`::boot_skips_crash_residue`、`::boot_is_inert_under_script`、`::engine_mounter_loads_a_real_pack`、`::main_scene_is_boot_scene`、`::patch_file_verification_domain` |
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
- 引导挂载只在门禁替身与一次真实 `load_resource_pack` 上取证；真实导出成品上的行为没有机械判据：成品叠加补丁后 `res://` 被覆盖、
  `tools/check-package.ps1` 在引导场景作为 `run/main_scene` 时照常通过、冷启动耗时、挂载后工程设置是否重载（官方文档未写明）、
  Windows 文件属性仍显示基线。这些只能在导出成品上人工取证。
- 引导闭包（`update/boot.gd`、`update/update_store.gd`、`update/update_manifest.gd`）在挂载前已载入，本会话不会换成补丁里的版本；
  `update/update_check.gd` 在挂载之后才由 `ui/main.gd` 载入，可被补丁替换；`update/update_keys.gd` 同样晚于挂载载入，但补丁导出的可行性判定拒绝改动它的补丁：公钥只随完整包变化。
- 有效版本的一种缺陷没有机械判据：`spire-godot/update/update_store.gd::effective_version` 若改为读 `state.json` 的 `active.to`，
  门禁抓不到——用例只注入补丁目录，静态读取走默认的 `user://updates`，而用例从不读真实用户目录。
  `tests/update_cases.gd::effective_version_requires_mount` 只钉住等价的另一种缺陷：引擎拒绝挂载时仍记录有效版本。
- 补丁导出在真实成品上的行为没有常驻门禁：`tools/package.ps1` 出基线包（它断言 `PACKS_ROOT` 为发布值 `adjacent`）后 `tools/export-patch.ps1` 的真实导出、
  内容包被改一字节时的拒绝与无输出，只能实跑取证，结果登记在验证记录；成品叠加启动、公网上传与下载、重定向与镜像回退属后续的下载与交互。
- 补丁导出与补丁条目的拒绝路径中，`export-patch.ps1` 的参数拒绝、基线源取不到（除 `baseline-unavailable` 一行）、`update-manifest.ps1` 的补丁参数拒绝没有常驻门禁，
  证据是脚本实跑日志；`export_patch_feasibility_domain` 只钉住可行性判定本身，`export_patch_requires_release_packs_root` 只钉住导出前的内容包根断言，
  两条引擎步骤判据钉住失败出口的清理。`Assert-UpdateManifest` 的补丁条目回读规则由 `update_manifest_patch_entries_are_judged` 常驻钉住。
- 引擎步骤里「包文件不存在」这一支没有独立判据：`Get-Item` 在包缺失时同样抛错，去掉该子句不改变结果，故不为它留检查。
- `Assert-UpdateManifest` 里两处子句没有独立的「关掉即红」：`to` 为空已被 `to == latest.version` 先行拒绝，所以不留 `to` 为空的夹具；`bytes` 小数的 `TryGetInt64` 失败后 `$size` 仍为 0，由 `$size -le 0` 兜住，所以只关掉 `TryGetInt64` 子句不会变红（整条 `bytes` 规则关掉时小数夹具变红）。
- `spire-godot/tests/update_cases.gd::baseline_version_is_frozen` 要改写工程设置，用运行时拼出的键（`const VERSION_SETTING`，与 `version_read_single_entry` 自己的写法相同），
  所以 `spire-godot/tests/architecture_cases.gd::version_read_single_entry` 的文本扫描看不见它：该判据只管「读取基线」，这处改写不是读取者；
  用例里若新增对该键的读取，门禁识别不了，只能靠人审。
- 基线冻结只钉住进程内行为；挂载补丁后引擎是否真的重载工程设置仍未证实，冻结是对该未证实项的防御，不是它的证据。
- 不属于本片授权面：`spire-godot/core/**`、`spire-godot/data/**`、`spire-godot/ui/**`；`spire-godot/tools/package*.ps1` 只改源码稳定性清单。
