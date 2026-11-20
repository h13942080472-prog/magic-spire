# 游戏内检查更新与提示（U1）

契约文件：一次签名清单读取、唯一判定、主页提示与两个跳转按钮、设置页开关的语义。
内部实现以代码为准，接口语义以本文件为准；函数名与稳定 ID 是锚点，本文件不写行号。
本文件不写执行结果：通过／失败／未执行与红集登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`update/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 收束对象：**把一个已签名的更新清单变成玩家可见的一次提示**。链路只有一条：
  `spire-godot/update/update_check.gd::check` 读配置、发最多两个 HTTPS GET，把字节交给
  `spire-godot/update/update_manifest.gd::evaluate` 判定，主页与设置页只显示判定结果。
- 不含：下载、校验包体、挂载补丁、写入 `user://` 或 EXE 目录、改 `run/main_scene`（U2）、
  发布侧生成清单与签名脚本（U1b）、反馈上传（D20）。
- 明文口径：**U1 只读一个公开文件**。请求不带存档、种子、设备标识、账号或自定义标识头；
  判定失败对玩家完全静默，原因只在 `--verbose` 下可诊断。
- 生产公钥表在 U1 为空（`spire-godot/update/update_keys.gd::KEYS`）。空表的正确答案是
  `none`／`key`，不是崩溃，也不是跳过验签；发布公钥与部署清单属于 U1b，在此之前
  任何构建都**不会**弹出更新提示。
- 验签方只持有公开材料：`spire-godot/update/update_manifest.gd::_verified` 用
  `CryptoKey.load_from_string(pem, true)` 加载键表条目的公钥 PEM（SPKI，`-----BEGIN PUBLIC KEY-----`）。
  `public_only=true` 不可省略：官方文档写明「If `public_only` is `true`, only the public key will be loaded.」，
  不传时引擎按私钥载荷解析，公开 PEM 返回 `Error parsing key`，验签于是永远失败。
- 键表条目只收公开材料：`evaluate` 在 `key` 步拒绝空条目与含 `PRIVATE KEY` 的 PEM，
  即使签名本身有效也不放行——私钥被贴进 `update_keys.gd` 时结果是 `none`／`key`。

## 接口

```gdscript
# 唯一判定（纯函数，无 IO、无单例状态、不读 ProjectSettings）：spire-godot/update/update_manifest.gd
static func evaluate(manifest_bytes: PackedByteArray, signature: PackedByteArray, keys: Dictionary,
                     current: String, platform: String) -> Dictionary
#   offer = {"kind":"notice", "version":String, "bytes":int, "url":String, "mirror":String,
#            "notes":String, "revoked":bool, "platform":String}
#   none  = {"kind":"none", "reason":String}   # reason ∈ REJECTIONS 或 ""（已验签、不是更新）
static func compare(a: String, b: String) -> int   # 版本比较，-1／0／1；数字段按十进制数字串比较，不经整数

const SCHEMA=1
const MAX_BYTES=65536
const REJECTIONS=["signature","key","schema","platform","size","json","url"]

# 唯一网络入口（Node）：spire-godot/update/update_check.gd
signal checked(offer)
var host                    # ui/main.gd；开关与自动检查门槛的唯一读取点
var keys: Dictionary        # 生产默认＝update_keys.gd 的 KEYS；探针／用例可换成本地密钥
var transport: Callable     # 测试接缝：有效时替代 HTTPRequest，形状同 ui/feedback_report.gd
func check() -> void        # 手动入口：不看开关，成功或失败都只发一次 checked(offer)
func deliver(result: int, status: int, headers: PackedStringArray, body: PackedByteArray) -> void
static func manifest_url() -> String     # [update] manifest_url 的唯一读取点
static func current_version() -> String  # 当前版本唯一真源＝ProjectSettings application/config/version
static func platform_key() -> String     # "android" / "windows-x64" / ""（未覆盖平台）
static func scripted_run() -> bool       # 引擎带 --script 启动：用例／探针／工具，不是玩家会话
func auto_allowed() -> bool              # 自动检查门槛，见「输入域」

# 配置真源：spire-godot/project.godot
[update]
manifest_url="https://update.magicspire.xyz/v1/manifest.json"
check_on_start=true

# 开关（CC-D22-1）：ui/display_settings.gd，写入既有 user://display-settings.cfg 的一节
var update_check_enabled: bool           # 出厂 true
func set_update_check(enabled: bool) -> void   # 保存键 update/check_on_start

# 主页与设置页（ui/main.gd 持有，ui/home_screen.gd 只调用）
var update_check                          # 场景进入树之前创建，探针可在 _ready 前装 transport
var open_url: Callable                    # 唯一跳转入口；探针替换为记录器
func _home_update_notice() -> void        # 节点 HomeUpdateNotice／HomeUpdateDownload／HomeUpdateMirror
func _open_update_url(url: String) -> void # 只接受 https://，默认 OS.shell_open
func _manual_update_check() -> void       # 设置页「立即检查」：不受启动开关影响
# 设置页节点：UpdateCheckEnabled（CheckButton）、UpdateCheckNow、UpdateCheckStatus
```

- 提示位置：主页布局层（`ui.layout`）上的独立面板，**不在** `GameHome` 之内，
  因此主页左侧标题区仍只有原来四个子节点（`HomeTitle`、`LanguageSelection`、
  `HomeDisclaimer`、`HomeSettingsSaveNotice`）。矩形与主页其它控件不相交。
- 文案走本地化：`ui.update.notice`、`ui.update.notice.revoked`、`ui.update.download`、
  `ui.update.mirror`、`ui.update.checking`、`ui.update.available`、`ui.update.latest`、
  `ui.settings.update_check`、`ui.settings.update_check_note`、`ui.settings.update_now`。

## 输入域

- 清单：`v1/manifest.json`，UTF-8 JSON，**≤ 65536 字节**，schema 1；签名是
  `manifest.json.sig`，内容为「对清单原始字节做 RSA PKCS#1 v1.5 + SHA-256」后的 base64。
  签名文件是**单行** base64：首尾空白与换行由 `strip_edges()` 容忍，内部出现任何空白都不是
  base64，按 `signature` 拒绝。U1b 的签名脚本必须用 `openssl base64 -A` 输出单行——默认的
  `base64` 每 64 字符换行，会被这条规则拒绝。
  清单字段：`schema`、`serial`、`issued`、`key_id`、`latest.version`、`latest.notes_zh`、
  `revoked`、`platforms.<platform>.full.{url,mirror,bytes,sha256}`、`platforms.<platform>.patches`。
- 判定顺序（每步失败即 `none`，不再往下读）：
  1. `size`：空字节或超过上限；
  2. `json`：解析失败；
  3. `key`：`key_id` 为空、公钥表里没有，或表内条目不是公开材料（含 `PRIVATE KEY` 的 PEM）；
  4. `signature`：签名缺失、非 base64、公钥不可加载或 `Crypto.verify` 失败；
  5. `schema`：`schema` 不是整数 1；
  6. `platform`：清单 `platforms` 里没有当前平台键；
  7. `json`：`full` 不是对象；`latest` 不是对象、缺 `version` 或 `version` 不是字符串；
     `bytes` 不是数字或为负；
  8. `url`：`full` 缺失，或其 `url`／`mirror` 缺失、为空串、不是 `https://` 开头；
  9. 判定结果：当前版本在 `revoked` 里 → `notice`（`revoked=true`）；
     `compare(latest.version, current)>0` → `notice`（`revoked=false`）；否则 `none`／`""`。
- 形状与链接两组的实际判定顺序是 `full` 对象 → 两个链接 → `latest` 与 `bytes`：`full.url`
  缺失或不合格时返回 `url`，即使 `latest.version` 同时缺失；`latest`／`bytes` 的形状错误
  只在两个链接可用之后才会返回 `json`。
- 平台键：Windows 用 `windows-x64`，Android 用 `android`；其它平台得到 `none`／`platform` 或空键。
- 版本比较（Q8）：按 `.` 分段；数字段是纯十进制数字串（只含 `0`–`9`），去掉前导零后位数多者大、
  位数相同按字典序比较，全程不经引擎整数，因此 20 位以上的数字段也不会溢出或退化成相等；
  缺省段等于数字 0；非数字段排在缺省段之后，彼此按文本比较。于是 `0.18.10>0.18.9`、
  `0.18.3.fix>0.18.3`、`0.18==0.18.0`、`01==1`。
- `patches` 数组 U1 不读、不显示、不产生 `patch` 结果。
- 请求：HTTPS GET 清单 → HTTPS GET `<manifest_url>.sig`；`timeout=10`、`max_redirects=0`、
  `body_size_limit=65536`；一次检查**最多两个**请求，不重试、不轮询。
- 自动检查门槛（`auto_allowed`，四条全真才发）：引擎不是 `--script` 启动（玩家会话）、
  `[update] check_on_start` 为真、玩家开关 `update_check_enabled` 为真、
  `manifest_url` 以 `https://` 开头。由 `ui/main.gd` 在 `render` 之后以 `call_deferred`
  启动一次，**不阻塞**主页。
- 手动检查：设置页「立即检查」直接调 `check()`，与启动开关无关；开关的语义只是
  「启动时自动检查」。

## 失败语义

- 断网、超时、非 200、3xx、体积超限、签名不符、平台缺失一律**静默**：不弹窗、不重试、
  不写盘、不改 `Game` 状态与存档，也不改变主页可操作性。`none` 的 `reason` 只进
  `--verbose` 日志。
- 检查在 `_ready` 之后延迟启动，主页先渲染；结果到达后只重建当前页面
  （`show_home` → `render`，设置页 → `_refresh_drawers`）。
- 非 `https://` 的目标即使已在签名清单里也不跳转：`_open_update_url` 先做前缀判断。
- 公钥表为空时 `evaluate` 返回 `none`／`key`：这是「没有可用公钥」的正确回答，
  不得退化成只看 sha256、只看 HTTPS 或跳过验签。
- 落地失败不影响玩家：`project.godot` 缺 `[update]` 时 `manifest_url` 为空 → 门槛不成立，
  一次请求都不发。

## 证据入口

具名 check（规则侧走真实 `Crypto.generate_rsa` 现场生成密钥对、把**公钥**交给 `evaluate`；
`openssl_signed_manifest_interops` 另复放提交在 `tests/fixtures/update/` 的 OpenSSL 夹具
（公钥 PEM、清单与签名）；UI 侧走真实 `main.tscn` 与真实点击，transport 替身回答两次 GET）：

| 判据 | 落点（分类 → 用例文件） |
| --- | --- |
| `UPDATE newer_latest_yields_notice`（更新版本给出 `notice`：版本、字节数、两个链接、说明、`revoked=false`、平台，且不含清单未验签字段） | `update` → `tests/update_cases.gd` |
| `UPDATE same_or_older_latest_yields_none`（同版本与旧版本都只给 `none`，不提供降级） | `update` → `tests/update_cases.gd` |
| `UPDATE version_order_is_numeric_per_segment`（数值段、缺省段、非数字段；自反、反对称、传递） | `update` → `tests/update_cases.gd` |
| `UPDATE version_segment_digit_compare`（20 位数字段按数字串比出大小且不触发引擎溢出；前导零被去掉；`0.18.10>0.18.9`） | `update` → `tests/update_cases.gd` |
| `UPDATE tampered_manifest_fails_signature`（签后改版本号＝`signature`；清单头 64 字节逐字节翻转与签名 16 字节翻转全部被拒） | `update` → `tests/update_cases.gd` |
| `UPDATE foreign_key_signature_is_rejected`（用另一把密钥签名仍按 `signature` 拒绝） | `update` → `tests/update_cases.gd` |
| `UPDATE missing_key_entry_is_rejected`（未知 `key_id` 与缺 `key_id` 都是 `key`） | `update` → `tests/update_cases.gd` |
| `UPDATE unusable_signature_is_rejected`（空签名与非 base64 文本都是 `signature`） | `update` → `tests/update_cases.gd` |
| `UPDATE signature_outer_whitespace_domain`（签名文件带尾部换行、前导换行或两端空白时仍验签通过） | `update` → `tests/update_cases.gd` |
| `UPDATE empty_key_table_yields_no_offer`（空公钥表→`key`，不崩溃、不放行） | `update` → `tests/update_cases.gd` |
| `UPDATE public_key_pem_verifies_signed_manifest`（`save_to_string(true)` 导出 SPKI 公钥 PEM；引擎按 `public_only=true` 加载；只放公钥的键表验签通过） | `update` → `tests/update_cases.gd` |
| `UPDATE private_key_table_entry_is_rejected`（表内条目是私钥 PEM 时→`key`，签名有效也不放行） | `update` → `tests/update_cases.gd` |
| `UPDATE openssl_signed_manifest_interops`（OpenSSL 3072 位 RSA 签名的清单夹具验签通过；签后改一字节→`signature`） | `update` → `tests/update_cases.gd` |
| `UPDATE unknown_schema_is_rejected`（schema 2→`schema`） | `update` → `tests/update_cases.gd` |
| `UPDATE missing_platform_yields_none`（清单无当前平台→`platform`） | `update` → `tests/update_cases.gd` |
| `UPDATE revoked_current_yields_notice`（当前版本被撤回→`notice` 且 `revoked=true`） | `update` → `tests/update_cases.gd` |
| `UPDATE oversized_or_broken_manifest_yields_none`（超上限→`size`、坏 JSON→`json`，都无引擎错误） | `update` → `tests/update_cases.gd` |
| `UPDATE non_https_url_is_rejected`（`http://` 的 `url` 与 `mirror` 都→`url`） | `update` → `tests/update_cases.gd` |
| `UPDATE missing_field_attribution_domain`（`latest` 缺 `version`→`json`；`full` 缺 `url` 或 `url` 为空串→`url`；两组同时不合格时按实际顺序先返回 `url`） | `update` → `tests/update_cases.gd` |
| `UPDATE patches_are_ignored`（`patches` 非空也不产生补丁结果） | `update` → `tests/update_cases.gd` |
| `UPDATE settings_toggle_uses_one_store`（开关写既有设置文件的 `update/check_on_start`，不出第二份存储；新装默认为开） | `update` → `tests/update_cases.gd` |
| `UPDATE startup_offer_renders_notice`（`--script` 会话不自动检查；手动 `check()` 后主页提示、版本与约 MB、两个按钮各自跳到自己那条链接、状态不变、提示不在 `GameHome` 内、与存档提示不相交） | UI `update` → `tests/update_ui_cases.gd` |
| `UPDATE startup_offline_is_silent`（超时只剩一个请求、无提示、主页仍可操作） | UI `update` → `tests/update_ui_cases.gd` |
| `UPDATE startup_bad_signature_is_silent`（被改的清单读完两次请求后按签名拒绝、不显示） | UI `update` → `tests/update_ui_cases.gd` |
| `UPDATE toggle_off_skips_startup`（默认开；关掉后写盘并在下次启动不检查；「立即检查」不受开关影响，同版本显示「已是最新版本。」且不显示提示） | UI `update` → `tests/update_ui_cases.gd` |
| `update/` 是叶子模块：不引用 `ui`、`core`、`data`、`tests`；`core`／`data` 不引用 `update`；只有 `update_check.gd` 发 HTTP | `architecture` → `tests/architecture_cases.gd::update_module_is_a_leaf` |

命令（在 `spire-godot/` 下执行；范围预检加 `-ListOnly`，不算通过）：

```powershell
& tools/check.ps1 -Suite update -TimeoutSeconds 600
& tools/check.ps1 -UIOnly -UISuite update,home,interface -TimeoutSeconds 900
& tools/check-mutation.ps1 -Check <check-name>
```

- 判据：退出码 0；每分类 `SUITE RESULT: <name> PASS`；`summary.json` 的 `status=passed` 且
  `before==after` 指纹（`source_changed` 不算通过）。
- 生产公钥表为空时，**不宣称**任何构建会显示更新提示；公网清单未部署时，只记「桌面接缝
  验收通过、公网未验收」，不得宣称已上线。
- 依赖约束（cleaner 可核对）见 [update-check-dependencies.md](update-check-dependencies.md)。
