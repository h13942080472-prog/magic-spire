# 游戏内检查更新与提示（U1、U1b）

契约文件：一次签名清单读取、唯一判定、主页提示与两个跳转按钮、设置页开关的语义；
发布侧清单生成与签名两份脚本的接口（U1b）。
内部实现以代码为准，接口语义以本文件为准；函数名与稳定 ID 是锚点，本文件不写行号。
本文件不写执行结果：通过／失败／未执行与红集登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`update/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 收束对象：**把一个已签名的更新清单变成玩家可见的一次提示**。链路只有一条：
  `spire-godot/update/update_check.gd::check` 读配置、发最多两个 HTTPS GET，把字节交给
  `spire-godot/update/update_manifest.gd::evaluate` 判定，主页与设置页只显示判定结果。
- 发布侧（U1b）同样只有一条链路：`spire-godot/tools/update-manifest.ps1` 生成清单，
  `spire-godot/tools/sign-update-manifest.ps1` 签名，两者见「发布侧脚本」。
- 不含：下载、校验包体、挂载补丁、写入 `user://` 或 EXE 目录、改 `run/main_scene`（U2）、
  上传与部署清单（人工动作）、反馈上传（D20）。
- 模块边界：`spire-godot/update/` 是叶子模块，不引用 `ui`、`core`、`data`、`tests`；
  `core` 与 `data` 也不引用 `update`。发 HTTP 的只有 `spire-godot/update/update_check.gd`。
- 明文口径：**U1 只读一个公开文件**。请求不带存档、种子、设备标识、账号或自定义标识头。
- 生产公钥表（`spire-godot/update/update_keys.gd::KEYS`）恰好一条 `k1`：维护者离线生成的
  RSA-3072 公钥，SPKI PEM，DER sha256 为
  `a4311195c39051d64a0fc5bec6352316eebc9a836d93f0982d52006bcbb8727c`。条目写成三引号 PEM 字面量，
  签名脚本按文本读取它（不运行引擎）。公网清单部署之前，检查按「失败语义」静默，
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

- `notice` 只含上面列出的八个字段：清单里的其它字段（如 `sha256`）不进入 `offer`。
- `check()` 的重入：检查进行中（`busy`）再次调用会被忽略——不发请求、不排队、不另发 `checked`；
  在途那次检查完成时只发一次 `checked(offer)`。
- 提示位置：主页布局层（`ui.layout`）上的独立面板，**不在** `GameHome` 之内，
  因此主页左侧标题区仍只有原来四个子节点（`HomeTitle`、`LanguageSelection`、
  `HomeDisclaimer`、`HomeSettingsSaveNotice`）。矩形与主页其它控件不相交。
- 提示内容：首行给出最新版本号与按 `bytes` 换算、保留一位小数的约 MB 大小；`revoked=true` 时改用撤回文案。
- 提示按钮：两个按钮分别打开 `offer.url`（`HomeUpdateDownload`）与 `offer.mirror`
  （`HomeUpdateMirror`），都只经 `_open_update_url`。
- 设置页状态（`UpdateCheckStatus`）：检查在途显示 `ui.update.checking`；有 `notice` 时显示
  `ui.update.available` 与版本号；已验签且不是更新时显示 `ui.update.latest`；拒绝原因不显示文本。
- 文案走本地化：`ui.update.notice`、`ui.update.notice.revoked`、`ui.update.download`、
  `ui.update.mirror`、`ui.update.checking`、`ui.update.available`、`ui.update.latest`、
  `ui.settings.update_check`、`ui.settings.update_check_note`、`ui.settings.update_now`。

## 输入域

- 清单：`v1/manifest.json`，UTF-8 JSON，**≤ 65536 字节**，schema 1；签名是
  `manifest.json.sig`，内容为「对清单原始字节做 RSA PKCS#1 v1.5 + SHA-256」后的 base64。
  签名文件是**单行** base64：首尾空白与换行由 `strip_edges()` 容忍，内部出现任何空白都不是
  base64，按 `signature` 拒绝。签名脚本因此用 `openssl base64 -A` 输出单行——默认的
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
  缺省段等于数字 0；非数字段排在缺省段之后，彼此按文本比较；文本段比较不区分大小写
  （`0.18.3.FIX` 与 `0.18.3.fix` 相等），段两端的空白不算内容（`0.18.3. fix` 与 `0.18.3.fix` 相等），
  显式空段（如 `0.18..1`）等于数字段 0。
- 版本序：`compare` 是 `.` 分段上的全序（自反、反对称、传递），于是 `0.18.10>0.18.9`、
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

- 断网、超时、非 200、3xx、体积超限、坏 JSON、签名不符、平台缺失一律**静默**：判定层只返回
  `none`（每步带自己的 `reason`，不产生引擎错误），不弹窗、不重试、不写盘、不改 `Game` 状态与存档，
  也不改变主页可操作性。`none` 的 `reason` 只进 `--verbose` 日志。
- 检查在 `_ready` 之后延迟启动，主页先渲染；结果到达后只重建当前页面
  （`show_home` → `render`，设置页 → `_refresh_drawers`）。
- 非 `https://` 的目标即使已在签名清单里也不跳转：`_open_update_url` 先做前缀判断。
- 公钥表为空时 `evaluate` 返回 `none`／`key`：这是「没有可用公钥」的正确回答，
  不得退化成只看 sha256、只看 HTTPS 或跳过验签。
- 落地失败不影响玩家：`project.godot` 缺 `[update]` 时 `manifest_url` 为空 → 门槛不成立，
  一次请求都不发；手动 `check()` 同样不发请求，按 `url` 拒绝且不显示提示。

## 发布侧脚本

在 `spire-godot/` 下用 PowerShell 7 执行；路径参数一律是绝对路径；已存在的输出文件一律不覆盖。

```powershell
# 唯一清单生成入口
& tools/update-manifest.ps1 -Version <版本> -NotesFile <UTF-8 文本> -Serial <正整数> [-KeyId k1] [-Revoked <版本,…>] -Out <manifest.json>
    [-WindowsZip <发行 ZIP> -WindowsUrl <https://…> -WindowsMirror <https://…>]
    [-AndroidManifest <package-android 写出的 manifest.json> -AndroidUrl <https://…> -AndroidMirror <https://…>]
# 唯一签名入口：输出 <manifest>.sig
& tools/sign-update-manifest.ps1 -Manifest <manifest.json> -PrivateKey <私钥 PEM> [-PassphraseEnv <环境变量名>]
```

- 生成：字段与「输入域」逐项一致；`issued` 取生成时刻的 UTC（`yyyy-MM-ddTHH:mm:ssZ`），`patches` 为 `[]`；
  平台按需给一组或两组，一组的三个参数缺一即拒绝，至少要有一个平台。`-Serial` 只收整数或十进制数字串
  （1–2147483647），`1.5`、`'1.5'` 之类直接拒绝，不取整；Android 包清单的 `sha256` 必须恰好是
  64 位小写十六进制，末尾多一个换行也拒绝。
- 哈希单一来源：Android 的 `bytes`／`sha256` 直接取自 `tools/package-android.ps1` 写在 APK 旁的
  `manifest.json`，不重算，且其 `version` 必须等于 `-Version`；Windows 发行 ZIP 在 `tools/package.ps1`
  之后人工打成，流水线里没有它的哈希，`update-manifest.ps1` 是计算它的唯一位置（`Get-FileHash`，一次）。
- 生成自检：先写临时文件再回读，核对 UTF-8 无 BOM、LF、严格 JSON、不超过 65536 字节、每个平台的
  `url`／`mirror` 都以 `https://` 开头；任一不满足即抛错，不留输出文件。
- 签名：对清单原始字节做 `openssl dgst -sha256 -sign`（RSA PKCS#1 v1.5 + SHA-256），再用
  `openssl base64 -A` 写成单行 `<manifest>.sig`。
- 签名防错：签名前用 `openssl pkey -pubout` 导出私钥的公钥半，与 `update/update_keys.gd` 里清单
  `key_id` 对应条目比较 DER sha256；`key_id` 没有条目或两者不一致即拒签，不产生 `.sig`。
  签名后把 `.sig` 解码，用该条目公钥 `openssl dgst -verify` 复核。
- 口令只经 `-PassphraseEnv` 点名的环境变量交给 `openssl -passin env:<名>`，不接受口令明文参数；
  脚本不打印私钥、口令或二者的哈希；临时目录只放公开材料与签名，任何出口都会删除。
  错误信息点名出错的参数与取值；脚本自己的报错不回显 `-PrivateKey` 与格式不对的 `-PassphraseEnv`
  （误用时它们可能就是私钥或口令），openssl 失败时透传的诊断可能含私钥文件路径。
- `-KeyTable <同形状的 .gd 绝对路径>` 是测试接缝：只用于一次性测试密钥产出夹具时替换比较对象；
  发布签名不传它，一律用默认的 `update/update_keys.gd`。
- 私钥保管与生产签名（只由维护者本人运行）的操作见 `skills/repo-ops/SKILL.md`「更新签名私钥保管」。
- 轮换：新公钥以 `k2` 与 `k1` 并列写入 `KEYS` 并随一个版本发布，之后清单才切换 `key_id`；
  旧构建只认它携带的键。`k1` 在用它签名的清单全部被替换后再删。

## 证据入口

取证方式：规则侧用真实 `Crypto.generate_rsa` 现场生成密钥对、把**公钥**交给 `evaluate`，并复放提交在
`tests/fixtures/update/` 的 OpenSSL 夹具（公钥 PEM、清单与签名）与两份发布侧脚本产出的两平台夹具
（`tests/fixtures/update/release-scripts/`：一次性公钥、三份输入、清单与签名；私钥用后即删）；
生产键表按 DER sha256 钉住。UI 侧走真实 `main.tscn` 与真实点击，transport 替身回答两次 GET。
发布侧脚本的拒签与拒绝路径没有常驻门禁，证据是脚本实跑日志；唯一签名入口与唯一清单写出点
由 architecture 的三条发布侧单点判据按源码文本钉住。

判据全集与执行符号见 [update-check-dependencies.md「判据 → 检查」](update-check-dependencies.md)。

命令（在 `spire-godot/` 下执行；范围预检加 `-ListOnly`，不算通过）：

```powershell
& tools/check.ps1 -Suite update -TimeoutSeconds 600
& tools/check.ps1 -UIOnly -UISuite update,home,interface -TimeoutSeconds 900
& tools/check-mutation.ps1 -Check <check-name>
```

- 判据：退出码 0；每分类 `SUITE RESULT: <name> PASS`；`summary.json` 的 `status=passed` 且
  `before==after` 指纹（`source_changed` 不算通过）。
