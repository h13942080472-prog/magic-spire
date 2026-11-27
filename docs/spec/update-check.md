# 游戏内检查更新与提示

契约文件：一次签名清单读取、唯一判定、主页提示与两个跳转按钮、设置页开关的语义；
发布侧清单生成与签名两份脚本的接口。
内部实现以代码为准，接口语义以本文件为准；函数名与稳定 ID 是锚点，本文件不写行号。
本文件不写执行结果：通过／失败／未执行与红集登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`update/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 收束对象：**把一个已签名的更新清单变成玩家可见的一次提示**。链路只有一条：
  `spire-godot/update/update_check.gd::check` 读配置、发最多两个 HTTPS GET，把字节交给
  `spire-godot/update/update_manifest.gd::evaluate` 判定，主页与设置页只显示判定结果。
- 发布侧同样只有一条链路：`spire-godot/tools/export-patch.ps1` 生成补丁（可选），`spire-godot/tools/update-manifest.ps1` 生成清单，
  `spire-godot/tools/sign-update-manifest.ps1` 签名，三者见「发布侧脚本」。
- 不含：下载补丁、联网校验包体、主页的补丁提示与自动下载（留给后续的下载与交互）、上传与部署清单（人工动作）、
  反馈上传。启动时的补丁挂载与版本身份见「引导挂载与版本身份」，清单里补丁条目的匹配见「补丁条目匹配」；检查本身仍不写盘。
- 模块边界：`spire-godot/update/` 是叶子模块，不引用 `ui`、`core`、`data`、`tests`；
  `core` 与 `data` 也不引用 `update`。发 HTTP 的只有 `spire-godot/update/update_check.gd`。
- 明文口径：**更新检查只读一个公开文件**。请求不带存档、种子、设备标识、账号或自定义标识头。
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
                     current: String, platform: String, local: Dictionary = {}) -> Dictionary
#   offer = {"kind":"notice", "version":String, "bytes":int, "url":String, "mirror":String,
#            "notes":String, "revoked":bool, "platform":String}
#          匹配到补丁时多一个 "patch":{"from","to","url","mirror","bytes","sha256"}，见「补丁条目匹配」
#   none  = {"kind":"none", "reason":String}   # reason ∈ REJECTIONS 或 ""（已验签、不是更新）
static func compare(a: String, b: String) -> int   # 版本比较，-1／0／1；数字段按十进制数字串比较，不经整数
# 引导挂载用的纯函数与解析入口见「引导挂载与版本身份」（verify_patch_file／is_newer／is_sha256／document）

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
static func manifest_url() -> String     # [update] manifest_url 的唯一读取点；`deliver` 把 spire-godot/update/update_store.gd::effective_version() 与本机身份 `_identity()` 交给 evaluate
var store                                # 本机身份来源的注入口（update_store.gd 实例）；玩家会话缺省时现建默认存储，--script 下不建
static func platform_key() -> String     # "android" / "windows-x64" / ""（未覆盖平台）
static func scripted_run() -> bool       # 引擎带 --script 启动：用例／探针／工具，不是玩家会话（定义在 update_store.gd，此处转调）
func auto_allowed() -> bool              # 自动检查门槛，见「输入域」

# 配置真源：spire-godot/project.godot
[update]
manifest_url="https://update.magicspire.xyz/v1/manifest.json"
check_on_start=true

# 开关：ui/display_settings.gd，写入既有 user://display-settings.cfg 的一节
var update_check_enabled: bool           # 出厂 true
func set_update_check(enabled: bool) -> void   # 保存键 update/check_on_start

# 主页与设置页（ui/main.gd 持有，ui/home_screen.gd 只调用）
var update_check                          # 场景进入树之前创建，探针可在 _ready 前装 transport；宿主在入树前被释放时一并释放
var open_url: Callable                    # 唯一跳转入口；探针替换为记录器
func _home_update_notice() -> void        # 节点 HomeUpdateNotice／HomeUpdateDownload／HomeUpdateMirror
func _open_update_url(url: String) -> void # 只接受 https://，默认 OS.shell_open
func _manual_update_check() -> void       # 设置页「立即检查」：不受启动开关影响
# 设置页节点：UpdateCheckEnabled（CheckButton）、UpdateCheckNow、UpdateCheckStatus
```

- `notice` 只含上面列出的八个字段，匹配到补丁时再多一个 `patch` 键：清单里的其它字段（如完整包的 `sha256`）不进入 `offer`。
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

## 引导挂载与版本身份

收束对象：**本进程运行的是哪一份代码、对外报告哪一个版本**。入口只有两处：
`spire-godot/update/boot.gd`（产品运行时的唯一挂载者；发布侧工具 `spire-godot/tools/patch_release_pck.gd` 只在打包机上以 `--script` 运行，另有一次挂载）与 `spire-godot/update/update_store.gd`（`user://updates/` 的唯一读写者、
版本身份的唯一来源）。本节不含联网、下载与主页补丁提示；清单里补丁条目的匹配见「补丁条目匹配」。

```gdscript
# spire-godot/update/update_store.gd（RefCounted；目录可注入：Store.new(directory)，默认 user://updates）
static func baseline_version() -> String        # 基线＝EXE 与主 PCK 的版本；进程内首次读取后冻结；全仓唯一读取 application/config/version 的位置
static func effective_version() -> String       # 有效版本＝本进程实际挂载成功的补丁 to，否则等于基线；读进程内 Engine meta，不读磁盘
static func record_mounted(to: String) -> void  # 有效版本的唯一写入者，只由 boot.gd 在引擎接受补丁后调用；空串＝回到基线
func identity() -> Dictionary                   # {"baseline":String,"failed":Array}，供清单补丁匹配（evaluate 的 local）
static func scripted_run() -> bool              # 引擎带 --script 启动（spire-godot/update/update_check.gd::scripted_run 转调这里）
static func player_session() -> bool            # 桌面特性 pc 且非 scripted_run：补丁只在这样的会话里挂载与证明
static func valid_version(value) -> bool        # 版本文法，见下
func load_state() -> Dictionary                 # 状态的唯一读取：缺失、不可解析或敌意内容都回到空状态
func write_state(state: Dictionary) -> bool     # 状态的唯一写入：临时文件、回读、改名；只写通过校验的字段
func patch_path(to: String) -> String           # patches/<to>.pck；版本不合文法时返回 ""，版本变成路径只在这里
func mark_failed(to: String) -> void            # 记入 failed、丢弃点名它的条目、删除其包；幂等
func begin_mount(to: String) -> bool            # 落盘 mounting 标记；写不进去时调用方不得挂载
func mark_boot_succeeded() -> void              # 清标记；提升本进程已挂载的 pending；删除没有条目指向的包
func reset_for_baseline() -> void               # 清空 patches/、staging/ 与状态，并记下当前基线
func clear_staging() -> void                    # 清除 staging/ 下的残留

# spire-godot/update/boot.gd（Node；update/boot.tscn 是 run/main_scene）
static func start(store, mounter := Callable(), session = null) -> Dictionary   # {"ran":bool,"mounted":String}
static func engine_mount(path: String) -> bool  # 默认挂载器：ProjectSettings.load_resource_pack(path, true)

# spire-godot/update/update_manifest.gd（纯函数，增补）
static func verify_patch_file(path: String, bytes: int, sha256: String) -> bool   # 文件存在、恰好 bytes 字节、SHA-256 相等；空包永不通过
static func is_newer(candidate: String, current: String) -> bool                  # 严格大于
static func is_sha256(text: String) -> bool                                        # 64 位小写十六进制
static func document(bytes: PackedByteArray) -> Variant                            # 更新模块唯一的 JSON 解析（清单与补丁状态共用）
```

- 两个版本各有一个来源：**基线**读工程设置，挂载补丁不改变它；**有效版本**只表示「本进程实际挂载成功」，
  进程级、不落盘（`Engine` meta，键为 `update_store.gd` 的私有常量）。状态文件里记录了某个补丁不等于它被挂载：
  记录了但没挂上时跑的是基线代码，必须报基线。消费者：窗口标题（`ui/main.gd::_ready`）、反馈报告
  （`ui/feedback_report.gd::_capture_context`）与清单判定的 `current`（`spire-godot/update/update_check.gd::deliver`）读有效版本；
  `tools/release_probe.gd::run` 验的是导出的主 PCK，读基线；发布侧脚本按文本读 `project.godot`，不运行引擎。
- 基线在进程内冻结：`baseline_version` 在本进程第一次被调用时读一次工程设置，存进 `Engine` meta（与有效版本各用一个私有常量键），
  此后一律返回这份副本。理由：每个补丁的 `config/version` 必然与基线不同，所以每个补丁都带 `project.binary`；
  挂载补丁后引擎是否重载工程设置，官方文档未写明（未证实）。若重载而基线仍实时读取，本会话的 `identity().baseline`
  会变成补丁版本、补丁匹配出错，无挂载记录时的有效版本也跟着漂移。冻结使 `spire-godot/update/boot.gd::start` 在挂载之前读到的值就是本进程之后读到的值。
- 窗口标题＝`config/name`＋` v`＋有效版本；`config/name` 不带版本后缀，发版只改 `config/version`。
- 状态文件 `user://updates/state.json`：`from`（记录时的基线）、`active`、`pending`（各为 `{to, bytes, sha256}` 或 `{}`）、
  `mounting`（上次启动尝试的版本，成功启动后清空）、`failed`（失败过的版本）。补丁包在 `patches/<to>.pck`，
  半截下载在 `staging/`（每次启动清空）。版本文法：二到四个十进制段（每段至多九位），可再加 `.fix`；
  读自磁盘的版本、`bytes`、`sha256` 任一不合法，整条条目被丢弃。
- 启动序列：`update/boot.tscn` 的 `spire-godot/update/boot.gd::_ready`（挂载）→ `ui/main.gd::_ready` → `ui/legacy_import.gd::run_once` →
  `_restore_startup` → `mark_boot_succeeded` → 之后的更新检查。引导脚本只预载 `update_store.gd` 与 `update_manifest.gd`，
  以场景路径字符串切到 `res://main.tscn`，所以补丁能替换 `ui/`、`core/`、`data/` 里的脚本；引导闭包本会话不会被补丁替换。
- 引导挂载（`spire-godot/update/boot.gd::start`，仅玩家会话）：
  1. 清空 `staging/`；读状态。
  2. 状态的 `from` 与基线不符且状态非空（玩家覆盖安装了另一个完整包）→ `reset_for_baseline`，以基线进入。
  3. 遗留的 `mounting` → 该版本记入 `failed`，不重试。
  4. 候选顺序 `pending`、`active`。候选在 `failed` 里、不严格新于基线、或 `verify_patch_file` 不通过 → `mark_failed`（删包），换下一个。
  5. 通过后 `begin_mount` 落盘标记，再调挂载器；引擎返回 `true` 才 `record_mounted(to)`；返回 `false` → `mark_failed` 并换下一个。
  6. 都不行则以基线进入，有效版本等于基线。
- 同一时刻只挂载一个补丁：`pending` 通过则 `active` 不挂载；`mark_boot_succeeded` 之后 `patches/` 只剩被提升的那个包。
- 非玩家会话：`--script` 运行（用例、探针、工具）不挂载、不碰状态、不切场景，有效版本等于基线；
  没有 `pc` 特性的平台（Android）只切场景，不挂载。
- 挂载与状态读取的任何失败都不弹窗、不影响进入游戏；失败只体现为「以基线进入」与 `failed` 里多一条。


## 补丁条目匹配

收束对象：**清单里的哪一个补丁条目适用于这台机器**。入口只有 `spire-godot/update/update_manifest.gd::evaluate` 的第六个参数
`local` 与它的私有函数 `_matching_patch`（条目校验 `_patch_entry`）；本节不含下载、校验包体与主页提示。

```gdscript
# local = spire-godot/update/update_store.gd::identity() 的形状；省略或为空字典时不匹配补丁
local := {"baseline": String, "failed": Array}
# 匹配成功时 offer 多一个键（其余八个字段不变）：
offer.patch = {"from": String, "to": String, "url": String, "mirror": String, "bytes": int, "sha256": String}
const PATCH_PLATFORM = "windows-x64"
const MAX_PATCH_BYTES = 268435456    # 256 MiB
```

- 条目位置：`platforms.windows-x64.patches[]`。条目字段（全部必填）：`from`（补丁所针对的**基线版本**，即玩家 EXE 与主 PCK 的版本）、
  `to`（目标版本）、`url`（维护者存储桶的直链）、`mirror`（GitHub Releases 镜像）、`bytes`（整数）、`sha256`（64 位小写十六进制）。
- 补丁是累计的：每个补丁都相对基线主 PCK 导出，包含基线以来的全部变更；同一时刻只挂载一个补丁，新补丁替换旧补丁而不叠加。
  所以 `from` 对**基线**比较，不对正在运行的有效版本：基线 0.18.4、已挂载 0.18.5 时清单发布 0.18.6，适用的条目是 `from=0.18.4`、`to=0.18.6`，
  `from=0.18.5` 的条目不匹配。
- 全部成立才给出 `offer.patch`：平台为 `windows-x64`；`local` 非空且 `local.baseline` 非空；条目字段全部合格（`from`／`to` 非空字符串，
  `url`／`mirror` 以 `https://` 开头，`bytes` 是 `0 < bytes ≤ MAX_PATCH_BYTES` 的整数，`sha256` 通过 `is_sha256`）；
  `compare(from, local.baseline)==0`；`to` 等于 `latest.version`；`to` 不在 `revoked` 里，也不在 `local.failed` 里。
  这一步发生在既有判定第 9 步给出 `notice` 之后，所以有效版本已是最新（`none`）时永远没有补丁；多条合格取第一条（发布侧保证唯一）。
- 坏条目（缺字段、哈希畸形、非 `https`、`bytes` 越界或非整数、非对象）只让该条不合格，**不**让整份清单变成 `none`：
  清单已验签，完整包提示依旧有效。`patches` 不是数组同样只是没有补丁。
- 没有匹配的条目就只给完整包提示——这是清单「退回完整包」的唯一表达：发布侧不为该基线写任何 `from` 条目，客户端不需要也没有 `full_only` 一类的标志。
- 生产调用点只有 `spire-godot/update/update_check.gd::deliver`，它把 `_identity()` 交给 `evaluate`：注入的 `store` 优先，否则玩家会话
  （`spire-godot/update/update_store.gd::player_session`）里现建默认存储取 `identity()`；`--script` 运行与没有 `pc` 特性的平台不构造存储，身份为空，不匹配补丁。
- 补丁包本身不带 `.sig`：信任来自已验签清单里的 `bytes` 与 `sha256`，下载与逐块校验属于后续的下载与交互，不在本检查内。

## 输入域

- 清单：`v1/manifest.json`，UTF-8 JSON，**≤ 65536 字节**，schema 1；签名是
  `manifest.json.sig`，内容为「对清单原始字节做 RSA PKCS#1 v1.5 + SHA-256」后的 base64。
  签名文件是**单行** base64：首尾空白与换行由 `strip_edges()` 容忍，内部出现任何空白都不是
  base64，按 `signature` 拒绝。签名脚本因此用 `openssl base64 -A` 输出单行——默认的
  `base64` 每 64 字符换行，会被这条规则拒绝。
  清单字段：`schema`、`serial`、`issued`、`key_id`、`latest.version`、`latest.notes_zh`、
  `revoked`、`platforms.<platform>.full.{url,mirror,bytes,sha256}`、`platforms.<platform>.patches`（条目字段与匹配见「补丁条目匹配」）。
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
     给出 `notice` 之后才做补丁匹配（见「补丁条目匹配」）；坏的补丁条目不影响这一步的结论。
- 形状与链接两组的实际判定顺序是 `full` 对象 → 两个链接 → `latest` 与 `bytes`：`full.url`
  缺失或不合格时返回 `url`，即使 `latest.version` 同时缺失；`latest`／`bytes` 的形状错误
  只在两个链接可用之后才会返回 `json`。
- 平台键：Windows 用 `windows-x64`，Android 用 `android`；其它平台得到 `none`／`platform` 或空键。
- 版本比较：按 `.` 分段；数字段是纯十进制数字串（只含 `0`–`9`），去掉前导零后位数多者大、
  位数相同按字典序比较，全程不经引擎整数，因此 20 位以上的数字段也不会溢出或退化成相等；
  缺省段等于数字 0；非数字段排在缺省段之后，彼此按文本比较；文本段比较不区分大小写
  （`0.18.3.FIX` 与 `0.18.3.fix` 相等），段两端的空白不算内容（`0.18.3. fix` 与 `0.18.3.fix` 相等），
  显式空段（如 `0.18..1`）等于数字段 0。
- 版本序：`compare` 是 `.` 分段上的全序（自反、反对称、传递），于是 `0.18.10>0.18.9`、
  `0.18.3.fix>0.18.3`、`0.18==0.18.0`、`01==1`。
- `evaluate` 的 `current` 是有效版本（`spire-godot/update/update_store.gd::effective_version`），撤回与「是否更新」都对它判定；补丁匹配另用 `local.baseline`。
  `local` 为空时 `patches` 不被读取，回答与不带补丁的清单逐字相同。
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

在 `spire-godot/` 下用 PowerShell 7 执行（脚本都带 `#Requires -Version 7.0`，Windows PowerShell 5.1 下直接报版本要求，
不产出文件）；路径参数一律是绝对路径；已存在的输出文件一律不覆盖。

```powershell
# 补丁 PCK 唯一生成入口（可选；先判定后导出）
& tools/export-patch.ps1 -BasePackage <基线发行包目录> -BaseVersion <基线版本> -Out <尚不存在的输出目录> [-CheckOnly] [-ProjectRoot <目标源码根>] [-BaseRef <git 引用>]
# 唯一清单生成入口
& tools/update-manifest.ps1 -Version <版本> -NotesFile <UTF-8 文本> -Serial <正整数> [-KeyId k1] [-Revoked '<版本>','<版本>'…] -Out <manifest.json>
    [-WindowsZip <发行 ZIP> -WindowsUrl <https://…> -WindowsMirror <https://…>]
    [-WindowsPatchMeta <元信息 JSON>,… -WindowsPatchUrl <https://…>,… -WindowsPatchMirror <https://…>,…]   # 每个补丁各一项，三个列表一一对应
    [-AndroidManifest <package-android 写出的 manifest.json> -AndroidUrl <https://…> -AndroidMirror <https://…>]
# 唯一签名入口：输出 <manifest>.sig
& tools/sign-update-manifest.ps1 -Manifest <manifest.json> -PrivateKey <私钥 PEM> [-PassphraseEnv <环境变量名>]
```

- 补丁生成（`spire-godot/tools/export-patch.ps1`，可选；只在打包机上运行）：补丁是对**基线发行包**的累计差量，所以基线发行包
  （`tools/package.ps1` 的产出：恰有一个顶层主 `.pck`，加上逐文件 `bytes`／`sha256` 的 `manifest.json`）必须在仓外归档，丢失即无法为该基线出补丁。
  目标版本取 `-ProjectRoot`（默认本仓 `spire-godot/`）`project.godot` 的 `config/version`（与 `tools/package.ps1` 同一正则），须不同于 `-BaseVersion`。
  顺序：参数 → 可行性判定 → （`-CheckOnly` 到此为止）内容包根断言 → 引擎导出到暂存目录 → 哈希 → 暂存目录改名为 `-Out`；`-Out` 必须是尚不存在的目录。判定命中或任何步骤失败都
  打印 `PATCH REFUSED: <门>: <说明>`／`PATCH EXPORT FAILED: …`、退出码 1，且不留 `-Out` 与暂存目录；`-CheckOnly` 只判定，不起导出、不写任何文件。
- 基线源取自基线版本的 git 对象（`git show <引用>:<路径>`；引用默认版本标签 `v<BaseVersion>`，可用 `-BaseRef` 指定），不读工作区：
  来源由引用确定、可复现；引用解析不了或文件缺失一律拒绝，不默认放行。取 `project.godot`、`export_presets.cfg` 与引导闭包五个文件。
  `-BaseSourceDirectory`（直接给一个基线源目录）与 `-EngineVersion`（不问引擎）只作测试接缝，发布不传。
- 可行性判定（`spire-godot/tools/export-patch-feasibility.ps1::Test-PatchFeasibility`，补丁只对「基线发行包 → 目标构建」成立）。任一命中即不出补丁，
  该基线上的客户端按「清单如何退回完整包」只得到完整包提示：
  1. `content-packs`：`content/packs` 的逐文件 SHA-256（`*.txt` 不计，与 `tools/package.ps1` 的复制范围一致）与基线包 `manifest.json` 里
     `content/packs/` 条目不一致（含增删）；基线包清单没有任何内容包条目也拒绝。内容包在 Windows 成品里是 EXE 旁的文件，补丁 PCK 改不了它。
  2. `project-settings`：`project.godot` 除 `config/version` 一行外有任何差异（挂载后工程设置是否重载，官方文档未写明，保守处理）。
  3. `export-presets`：`export_presets.cfg` 除版本字段（`application/file_version`、`application/product_version`、`version/code`、`version/name`）
     与预设名、说明里的版本号写法外有差异——这些写进 EXE 元数据，补丁改不了。
  4. `boot-closure`：引导闭包五个文件（`update/boot.gd`、`update/boot.tscn`、`update/update_store.gd`、`update/update_manifest.gd`、`update/update_keys.gd`）
     有任何差异——它们在挂载前已载入并缓存，本会话换不成补丁里的版本；公钥只随完整包变化。
  5. `baseline-no-boot`：基线没有引导场景与闭包，或其 `run/main_scene` 不是 `res://update/boot.tscn`——更早的基线没有挂载能力。
  另有三道前置自检：`package`（包清单缺失、版本或平台不符、顶层 `.pck` 不是恰好一个、`.pck` 的字节数或哈希与清单不符）、
  `baseline-unavailable`（基线源取不到，或其 `config/version` 不是 `-BaseVersion`）、`engine`（基线包记录的引擎版本与当前引擎不同）。
  同一语义只在 `Test-PatchFeasibility` 里判定；测试经真实入口 `-CheckOnly` 取证，不在 GDScript 里重写。
- 内容包根断言：导出（非 `-CheckOnly`）在启动引擎之前，经 `tools/assert-packs-root.ps1::Assert-SpirePacksRoot -Expected 'adjacent'`（与 `tools/package.ps1` 同一函数）
  断言 `core/content_catalog.gd` 的 `PACKS_ROOT` 为发布值。Windows 成品的内容包在 EXE 旁，补丁若带着开发值 `res://content/packs` 的目录定位，
  挂载后游戏会去 `res://` 找内容包而加载不出来。断言失败即 `PATCH EXPORT FAILED`、退出码 1，不留 `-Out` 与暂存目录；常量不自动翻转，导出前手改、导出后改回（见 [packaging.md](packaging.md)）。
  `-CheckOnly` 不做这条断言：它只判定可行性，测试与日常都在开发树上运行，那里的值就是开发值。`-EngineBinary` 只作测试接缝（引擎可执行文件路径，不是文件即在启动任何进程之前失败），发布不传。
- 导出与输出：Windows 预设按平台（`Windows Desktop`，恰好一个）而不按含版本号的名称查找，命令为
  `<引擎> --headless --path <根> --export-patch <预设> <暂存 .pck> --patches <基线主 .pck>`（Godot 4.7.2 `--help` 原文：
  `--export-patch <preset> <path>` 「Export pack with changed files only」，`--patches <paths>` 「List of patches to use with --export-patch. The list is comma-separated.」），
  引擎退出码非零、产物缺失或为空、日志含 `ERROR:` 都算失败。输出 `patch-<from>-<to>.pck` 与 `patch-<from>-<to>.json`
  （`from`、`to`、`bytes`、`sha256`）；**补丁的哈希只在这里算一次**，`update-manifest.ps1` 只复制它。
- 生成：字段与「输入域」逐项一致；`issued` 取生成时刻的 UTC（`yyyy-MM-ddTHH:mm:ssZ`），`patches` 默认为 `[]`，只有 `windows-x64` 可以带补丁条目；
  平台按需给一组或两组，一组的三个参数缺一即拒绝，至少要有一个平台。`-Serial` 只收整数或十进制数字串
  （1–2147483647），`1.5`、`'1.5'` 之类直接拒绝，不取整；Android 包清单的 `sha256` 必须恰好是
  64 位小写十六进制，末尾多一个换行也拒绝。`-Revoked` 的每个版本都要加引号（`-Revoked '0.20','0.19.5'`
  或 `-Revoked '0.20,0.19.5'`）：裸写的 `0.20,0.19.5` 在参数绑定时 `0.20` 就变成了数字 0.2，脚本拒绝一切
  不是字符串的元素并提示加引号，不转换；`pwsh -File` 形式的参数本来就是字符串，裸写可用。`-KeyId` 只收字母、
  数字、`_`、`-`，末尾多一个换行也拒绝。完成时的摘要行回显 `version`、`revoked`、`key_id`、`serial` 与平台，
  签名前对照核对。
- 哈希单一来源：Android 的 `bytes`／`sha256` 直接取自 `tools/package-android.ps1` 写在 APK 旁的
  `manifest.json`，不重算，且其 `version` 必须等于 `-Version`；因此 `-AndroidUrl`／`-AndroidMirror` 必须指向
  APK 本体，不能指向含说明与许可的 Android ZIP（大小与哈希会对不上所链接的文件）。Windows 发行 ZIP 在
  `tools/package.ps1` 之后人工打成，流水线里没有它的哈希，`update-manifest.ps1` 是计算它的唯一位置
  （`Get-FileHash`，一次）。补丁条目的 `from`／`to`／`bytes`／`sha256` 取自 `export-patch.ps1` 写的元信息 JSON，不重算；`url`／`mirror`
  是每个补丁的 `-WindowsPatchUrl`／`-WindowsPatchMirror`（维护者存储桶直链为主，GitHub Releases 作镜像；本契约只要求两者都是 `https://`）。
- 生成自检：先写临时文件再回读，核对 UTF-8 无 BOM、LF、严格 JSON、不超过 65536 字节、每个平台的
  `url`／`mirror` 都以 `https://` 开头，且每个补丁条目都是客户端能接受的（`from`／`to` 非空、`to` 等于 `latest.version`、`url`／`mirror` 为 `https://`、
  `bytes` 为 (0, 256 MiB] 的整数、`sha256` 为 64 位小写十六进制、同一平台内 `(from, to)` 不重复）；任一不满足即抛错，不留输出文件。这份回读自检只有一份实现
  `tools/update-manifest-check.ps1::Assert-UpdateManifest`，两份脚本 dot-source 共用。
- 签名：对清单原始字节做 `openssl dgst -sha256 -sign`（RSA PKCS#1 v1.5 + SHA-256），再用
  `openssl base64 -A` 写成单行 `<manifest>.sig`。
- 签名防错：签名前先对 `-Manifest` 跑同一份回读自检，生成后被手工改过（例如说明加长到超过 65536 字节、
  链接改成 `http://`）的清单不通过即拒签；再用 `openssl pkey -pubout` 导出私钥的公钥半，与
  `update/update_keys.gd` 里清单 `key_id` 对应条目比较 DER sha256；`key_id` 没有条目或两者不一致即拒签。
  拒签都不产生 `.sig`。签名后把 `.sig` 解码，用该条目公钥 `openssl dgst -verify` 复核。
- 口令只经 `-PassphraseEnv` 点名的环境变量交给 `openssl -passin env:<名>`，不接受口令明文参数；
  脚本不打印私钥、口令或二者的哈希；临时目录只放公开材料与签名，任何出口都会删除。
  错误信息点名出错的参数与取值；脚本自己的报错不回显 `-PrivateKey` 与 `-PassphraseEnv` 的取值（格式不对、
  或点名的变量未设置都一样；误用时它们可能就是私钥或口令），openssl 失败时透传的诊断可能含私钥文件路径。
- `-KeyTable <同形状的 .gd 绝对路径>` 是测试接缝：只用于一次性测试密钥产出夹具时替换比较对象；
  发布签名不传它，一律用默认的 `update/update_keys.gd`。
- 私钥保管与生产签名（只由维护者本人运行）的操作见 `skills/repo-ops/SKILL.md`「更新签名私钥保管」。
- 轮换：一个构建只验证它自带的键，公网只有一份现行清单。新公钥以 `k2` 与 `k1` 并列写入 `KEYS` 并随一个版本发布；
  公告这个双键版本的那份清单**仍用 `k1` 签名**，否则只带 `k1` 的存量构建收不到这次升级提示。清单的 `key_id`
  切到 `k2` 之后，只带 `k1` 的构建对它一律得到 `none`／`key`，按「失败语义」静默失联，所以切换时机由维护者
  按升级情况决定。`KEYS` 里的 `k1` 在用它签名的清单全部被替换后再删；销毁 `k1` 私钥之前，先确认不再需要向
  只带 `k1` 的构建发提示。
- 密钥泄露后，经独立可信的项目发布渠道分发移除旧键的恢复版本。操作见 `skills/repo-ops/SKILL.md`「更新签名私钥保管」。

## 证据入口

取证方式：规则侧用真实 `Crypto.generate_rsa` 现场生成密钥对、把**公钥**交给 `evaluate`，并复放提交在
`tests/fixtures/update/` 的 OpenSSL 夹具（公钥 PEM、清单与签名）与两份发布侧脚本产出的两平台夹具
（`tests/fixtures/update/release-scripts/`：一次性公钥、五份输入（含占位补丁包与元信息）、清单与签名；私钥用后即删）；
生产键表按 DER sha256 钉住。UI 侧走真实 `main.tscn` 与真实点击，transport 替身回答两次 GET。
补丁导出的可行性判定经真实入口 `tools/export-patch.ps1 -CheckOnly` 由 `export_patch_feasibility_domain` 常驻取证，
导出前的内容包根断言经同一入口的导出模式由 `export_patch_requires_release_packs_root` 取证（不启动引擎）；
引擎步骤的失败出口（非零退出、空包、日志里的 `ERROR:` 行、最后一步移动失败）经 `-EngineBinary` 接缝指向 `.cmd` 替身，
由 `export_patch_engine_failure_leaves_nothing` 与 `export_patch_engine_error_log_is_failure` 取证（同样不启动引擎）；
`Assert-UpdateManifest` 对补丁条目的六条回读规则经 pwsh 真实运行 `tests/fixtures/update/manifest-check/` 的夹具，由
`update_manifest_patch_entries_are_judged` 取证；
其余发布侧脚本的拒签与拒绝路径没有常驻门禁，证据是脚本实跑日志；唯一签名入口与唯一清单写出点
由 architecture 的三条发布侧单点判据按源码文本钉住。

判据全集与执行符号见 [update-check-dependencies.md「判据 → 检查」](update-check-dependencies.md)。

命令（在 `spire-godot/` 下执行；范围预检加 `-ListOnly`，不算通过）：

```powershell
& tools/check.ps1 -Suite update -TimeoutSeconds 600
& tools/check.ps1 -UIOnly -UISuite update,home,interface -TimeoutSeconds 900
& tools/check-mutation.ps1 -Check <check-name>
```

- 判据：退出码 0；每分类 `SUITE RESULT: <name> PASS`；`summary.json` 的 `status=passed` 且
  `before==after` 指纹（`source_changed` 不算通过）。`tools/check.ps1::Get-SourceFingerprint` 的目录集合含
  `update/`，生产键表 `update/update_keys.gd` 在运行中被换键也会改变指纹。
