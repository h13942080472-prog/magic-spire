# 本地化（操作指南）

现状：默认简体中文；设置页可即时切换 English／日本語。
本文只写怎么改、怎么验；卡面与候选详情文案的按需投影契约见 `docs/spec/ondemand-copy.md`，语言在显示边界的处理入口是 `ui/localization.gd`（代码即接口）。

## 资源结构

| 文件 | 作用 |
| --- | --- |
| `assets/localization/zh_CN.json` | 共用语义 ID 与当前中文源文。 |
| `assets/localization/en_US.json` | 共用语义 ID 的英文译文，`source` 必须与中文源文一致。 |
| `assets/localization/ja_JP.json` | 共用语义 ID 的日文译文。 |
| `assets/localization/legacy-ja_JP.json` | 尚未逐项迁移为语义 ID 的全运行时日文兼容目录。 |
| `assets/localization/legacy-en_US.json` | 尚未逐项迁移为语义 ID 的全运行时英文兼容目录，每项保存稳定哈希 ID、中文 `source` 与英文 `text`。 |

写入约定：

- 新增文案优先稳定语义 ID 或 `narrativeCue + payload`；兼容目录只承接现有硬编码正文的过渡，**不得**用于规则判断、候选身份、随机键或状态枚举。
- 语义消息格式：`"ui.example": {"source":"当前{count}次", "text":"{count} remaining"}`；命名参数由调用方通过 `localization.text(...)` 代入。
- 动态模板至少保留两个中文文字字符（空白、标点与拉丁字母不能凑足两个字）；弱模板跳过，已登记的完整字符串仍可精确翻译。
- 兼容目录只匹配完整源句或受约束的动态模板，再代入并递归翻译其中的牌名、装备名、状态词等参数；不从译文反推规则。
- 语言偏好保存于 `localization.locale`（显示设置），不进入 `GameState` 或玩法存档。

## 维护流程

先盘点，再生成，最后人工检查受影响的界面：

1. `python tools/localization_inventory.py` 重新扫描运行时源码与内容包，输出 `build/localization/inventory.json`。清单跳过 `legacy-*` 翻译目录；注释、测试夹具、开发文档与图片内文字不计入。
2. `python tools/build_english_catalog.py` 从本机离线模型与缓存重建兼容英文目录；`python tools/build_japanese_catalog.py` 从中文源文重建语义 ID 与日文兼容目录。日文生成器使用 `build/nllb-200-distilled-600M-ct2-int8/` 下的 CTranslate2 模型；模型与缓存均在被忽略的 `build/` 下工作，不随游戏资源发布。高频界面和关键规则使用生成器内的人工日文，自动生成内容仍须按本次改动涉及的界面人工复核。所有源文已有缓存时，重建无需加载离线模型。
3. 新增或修改中文时按「盘点 → 生成 → 人工检查关键界面」执行；成功加载中文源目录后清空旧兼容缓存，缺失／损坏的兼容包回退原文。

条目数（共用语义 ID 数、兼容目录条数、覆盖的中文串数）用上面两条命令复算，不写死在本文。

## 判据

- 资源校验由 `ui/localization.gd` 执行：重复键、源文版本、模板参数与结构。未知 ID、中文源文变化、参数错漏及损坏资源都会留下开发诊断并安全回退；非法资源整包拒绝，不产生半套翻译。
- 语言只影响显示：切换后立即重绘当前页面；卡面延迟缩字、拖拽预览、商店台词滚动区等后续刷新保持当前语言。判据是不改候选、费用、随机结果与存档快照。
- 字体：所有语言统一使用随游戏提供的 `assets/fonts/NotoSansCJKsc-Regular.otf`（主界面主题与项目默认字体均指向它，切换语言不改回系统字体，玩家无需安装字体或改系统地区）；来源、固定版本与授权见 `assets/fonts/SOURCE.md`，Windows／Android 导出均包含原始 OFL 许可。

## 验证

- 规则侧覆盖：英文资源完整性、源文变更、缺译／未知 ID 回退、动态模板、嵌套参数、非法包原子拒绝、偏好保存，以及语言切换前后快照与候选不变。
- 窗口侧覆盖：主页、设置、商店、事件、战斗、卡面延迟刷新与切回中文；扫描代表性英文页面不得残留中文字符。
- 一次实际范围示例（2026-09-13 批次）：资源导入 + `localization`／`architecture`／`runner` 规则分类 + `localization`／`home`／`display`／`services`／`events`／`card_power` 窗口分类。命令与分类语义见 `skills/repo-ops/SKILL.md`。
- 未运行的范围（全项目回归、安卓真机、打包）必须在结论里写明；结果只登记到 `docs/record/verification.md`。
