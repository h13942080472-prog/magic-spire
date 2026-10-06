# Windows / Android 打包契约

本文件是现行契约：登记两平台打包的版本来源、脚本接口、入包内容、签名、探针与验收记录。
本文件不写执行结果；通过／失败／未完成项只登记在验证记录（`docs/record/verification.md`）。

路径约定：不带 `spire-godot/` 前缀的脚本、工程与产物路径（`tools/`、`content/`、`export_presets.cfg`、`build/`）
均相对 `spire-godot/`；设置与产出目录为 `spire-godot/project.godot` 与仓库根 `outputs/`；`docs/` 相对仓库根。
发布（标签、Release、上传）需用户明确要求；本文件只描述打包与验收流程。

## v0.18.2.fix 修复与维护版

当前 project.godot 及两平台预设统一为 0.18.2.fix；版本读取接受原有两段／三段数字及可选的 `.fix` 后缀。Windows 文件版本保持数字格式 0.18.2.0，Android 显示版本为 0.18.2.fix，安装版本暂为14；下次发布新 APK 前须递增安装版本并保留原签名。两平台随包版本说明均读取 [本版说明](../record/release-notes/release-v0.18.2.fix.txt)，Android 附 [Android 说明](../record/release-notes/release-android-v0.18.2.fix.txt) 及基础操作教学。历史标签和安装包不覆盖。

交付普通 Windows ZIP、Android APK及含说明与许可的 Android ZIP；本地另交付仅含完整 PC 目录的双层加密7z。内外两层均使用用户指定密码并加密文件名；双层包不上传 GitHub。两层实际解压后核对文件 SHA256，确认内层不含安卓包；密码不写入游戏或签名配置。

## 域

- 从版本号来源、导出预设、打包脚本、导出模板、签名配置，到成品清单、资源探针与包内验证说明的整条流水线。
- 覆盖 Windows x86_64 与 Android；不含游戏规则、源码内容与反馈服务（见 `docs/spec/feedback-deployment.md`）。
- 操作细节与已知环境陷阱（打包脚本须用 PowerShell 7；`GODOT_BIN` 必须指向 `*_console.exe`；
  导出模板须装在引擎版本目录下）见 `skills/repo-ops/SKILL.md`，不在本文件重复。
- 程序与 PCK 必须一起分发；正式 `content/packs` 复制在 EXE 旁。内容包根只由
  `core/content_catalog.gd` 的常量 `PACKS_ROOT` 决定，其余代码经 `packs_root()` 读取：
  开发值 `"res://content/packs"`（编辑器、测试与 Android 包内资源），发布值 `"adjacent"`
  （可执行文件旁的 `content/packs`，不进 PCK）。
- **导出前把 `core/content_catalog.gd` 的 `PACKS_ROOT` 改成 `"adjacent"`，导出后改回
  `"res://content/packs"`**；Android 保持开发值（包内 `res://`）。
  `tools/package.ps1` 与 `tools/package-android.ps1` 在导出前断言各自需要的值，
  不匹配即失败并给出文件名与要改的那一行，不自动改。

## 接口

| 命令 | 作用 |
| --- | --- |
| `tools/package.ps1 -BuildId <本次唯一编号>` | Windows：在仓库根 `outputs/` 建立新目录并完成导出与自检 |
| `tools/package-android.ps1 -BuildId <唯一编号> [-SigningConfig <本机配置>]` | Android：生成签名 APK；默认签名配置见下 |
| `tools/check-package.ps1 -Directory <成品目录>` | 复验清单、发布 EXE 启动及成品 PCK |
| `tools/check-android-package.ps1 -Apk <APK 路径>` | 直接取 APK 的 assets，用主机 Godot ZIP 资源加载器启动包内游戏 |
| `tools/release_probe.gd` | 用编辑器经 `--main-pack` 载入同一成品 PCK 的探针 |
| `tools/fix_android_manifest.py` | Android 清单 authorities 修复与重签 |
| `export_presets.cfg` | 导出内容与预设（编译脚本、运行资源、动态装备 JSON）的事实来源 |

## 输入域

- **版本号来源**：脚本从 `project.godot` 读取版本并选择同名导出预设；当前版本、Windows 文件版本、
  Android 安装版本与随包版本说明文件名见本文「v0.18.2.fix 修复与维护版」段。不手改脚本内的版本常量。
- **进包内容**：编译脚本、运行资源、动态装备 JSON；正式 `content/packs` 与授权文件随包。
- **不得进包**：测试、工具、文档、日志、内容模板、存档、密钥、构建工具，以及第三方授权清单以外的构建产物。
- **Windows 导出**：目标 Windows x86_64 发布模板；只安装 Windows x86_64、版本标记与 ICU 数据；
  模板来自 [Godot 4.7.2 官方归档](https://godotengine.org/download/archive/4.7.2-stable/)，完整 TPZ 的 SHA256 为
  `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`；导出配置参照
  [官方 Windows 导出说明](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html)，未进行代码签名。
- **Android 工具链**：Godot 4.7.2 官方 Android 模板、JDK 17、Android build-tools 35.0.1；
  模板自身为 minSdk 24／targetSdk 36，支持 ARM64 与 ARMv7；ETC2/ASTC 导入与兼容渲染器开启，横屏保持 16:9；
  导出配置参照 [官方 Android 导出文档](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)。
- **Android 权限与备份**：允许主动反馈所需的网络权限；不申请共享存储权限；禁止云端备份恢复旧安装数据。
  系统返回键先关闭当前窗口，没有窗口时打开菜单。
- **签名**：默认配置在 `G:/CodexData/keys/spire-android/signing.json`，密码由当前 Windows 账户 DPAPI 保护；
  `-SigningConfig` 指定其他本机配置。发布脚本只通过环境变量传递密码，源码及 APK 不包含私钥。

## 失败语义

- `package.ps1` 拒绝覆盖已存在的产物目录；脚本核对导出退出码、错误、文件存在以及导出前后源码指纹，
  **不把变化中的代码批次认定为稳定包**。导出日志与源码指纹存入 `build/package-<编号>`。
- 覆盖安装必须保留同一签名并递增 version/code；迁移签名环境时另行妥善备份密钥。
- Godot 4.7.2 非 Gradle 导出器会把所有 provider 的 authorities 写成 `.fileprovider`
  （[官方导出器源码](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/export/export_plugin.cpp)）；
  `fix_android_manifest.py` 只把 AndroidX Startup 的标识改回本包的 `.androidx-startup`，
  保留其他清单事实和全部资源，移除旧签名后重新进行 16 KB 对齐、发布签名和验签；
  工具校验唯一 provider 标识、启动入口及内容包逐文件 SHA256。
- 探针边界：`check-android-package.ps1` 不代表 Android 虚拟机或真机运行；
  桌面探针同样不能替代真机验收。设备字体、触控尺寸、系统键盘、性能及安装后启动仍待真机确认。
- 官方模板禁止脚本／路径覆盖，因此**不能声称**使用发布 EXE 执行了 `release_probe.gd`；
  实际 EXE 的启动检查独立进行，检查使用临时用户目录，不读取或覆盖玩家存档。
- 完整回归存在失败、超时或未完成项时，必须在包内验证说明及交付消息中写明，不把局部通过写成全量通过。
- 触屏桥接覆盖主窗口与 PopupMenu 的独立窗口，嵌入弹窗通过父 Viewport 转发到 Godot 原生 Window 输入边界；
  选择、滑动、取消和返回键沿原菜单处理，不直接修改游戏状态——该行为需单独确认真机运行。

## 证据入口

- 成品清单：版本／文件 SHA256 清单与第三方授权随包；`check-package.ps1` 复验清单、发布 EXE 启动及成品 PCK。
- 验收记录：检查使用临时用户目录；`release_probe.gd` 验证开发脚本排除、版本、12 份相邻内容包、动态贴图、
  新游戏、练习及隔离目录的存档读写恢复；压缩前核对本批验证记录，生成最终 ZIP 与 SHA256，
  并从 ZIP 重新解压核对所有清单文件。
- 触屏专项：`tools/check.ps1 -UIOnly -UISuite touch`（真实 `ScreenTouch`／`ScreenDrag` 输入进入正式 UI）。
- 结果与失败集登记在验证记录（`docs/record/verification.md`）；未执行项不记作通过。

## 流水线验收要点

- Windows：`tools/package.ps1` 建目录、写清单与授权，导出日志与源码指纹存 `build/package-<编号>`；
  发布 EXE 直接运行查主页与启动错误，`tools/release_probe.gd` 经 `--main-pack` 载入同一 PCK，
  `tools/check-package.ps1 -Directory <成品目录>` 复验清单、EXE 启动与成品 PCK；
  压缩前核对本批验证记录，生成最终 ZIP 与 SHA256，并从 ZIP 重新解压核对所有清单文件。
- Android：`tools/package-android.ps1` 生成签名 APK（ETC2/ASTC 与兼容渲染器开启，横屏 16:9）；
  `content/packs` 打进 APK 按开发值经 `res://` 读取；`tools/check-android-package.ps1` 直接取 APK assets
  启动包内游戏并验证主页、内容、动态资源、新游戏、练习和隔离存档；
  触屏行为通过真实 `ScreenTouch`／`ScreenDrag` 输入进入正式 UI，专项入口
  `tools/check.ps1 -UIOnly -UISuite touch`。
