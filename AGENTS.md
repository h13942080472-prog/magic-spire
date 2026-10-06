# AGENTS.md

本文件只写：红线、本仓特有约束、Godot 技术栈与代码规范、最小索引。
全局 AGENTS 的红线照旧生效；全局 AGENTS 的职能与交接规则、完成证据与接口信任规则不在此复述。
命令与操作流程见 `skills/repo-ops/SKILL.md`。

## 红线（禁区）

- 密钥、凭据与 `.env*` 不得进入提交与回复；构建产物不得进入提交；调试残留与无关 WIP 不得进入改动。
- 测试与临时产物一律放工作区 `tmp/`；不得散落在工作区外或工作区根目录。
- `git worktree` 只加在 `C:\1\tmp\magic-spire-wt-*`；不得加在 `C:\1\` 根，不得加在仓库目录内。
- 不得修改 git config、force-push、跳过 hook 或创建空提交。
- Push、tag、Release、PR 或部署须有用户明确指示。不得自行升版本号。
- 例外：Godot 模块的大版本（用户确认的版本里程碑，不是每次小修改）完成且门禁通过后，可准备好推送并请用户确认一次；确认后推送。
- 新增运行时依赖须说明理由并征得同意。
- 不得把全仓审阅当作默认做法：没有域与接口契约的派工即交付失败；结论必须写明域。
- 除非用户要求英文，一律用中文回复。

## 本仓特有约束

- 本仓当前只维护 `spire-godot/`（《紧缚尖塔》，Godot 塔路与卡牌游戏）。
- 游戏面向成人；所有登场角色均为成年人。素材与文案按任务授权及资源许可处理。
- 网页项目《魔法少女又白给了》是同级另一仓库 `mahou-shoujo-escape`，不在本仓：本仓不引用其源码或构建流程，不据其界面反向修改本仓规则定义与数值。
- 历史归档 `docs/history/` 只读，含已被推翻的旧决策；不是待办，不把归档中的旧约束恢复成当前要求。
- 最新明确用户要求优先于旧设计记录；已确认规则优先于旧 Demo 行为，不据旧界面反向修改规则定义。
- 开始修改前检查已有差异；用户和其他任务的在途修改必须保留。
- 长背景、数值修订与执行结果写入 `docs/`；AGENTS.md 不追加聊天流水或版本日志。
- 文档以当前架构为基线；架构改变时同批推翻受影响文档；发现文档与实现冲突时先问，不得绕行遵守旧文档。

## Godot 技术栈

- 引擎：Godot 4.x 稳定版；当前 `4.7.2`，引擎与导出模板版本一致，真源在 `docs/spec/packaging.md`；**换版本是显式任务**。
- 语言：GDScript 为主，C# 为备选（当前无 C# 代码）。
- 平台：Windows x64 与 Android（ARM64／ARMv7、触屏）；桌面与移动共用同一输入与表现入口（见 `docs/design/input-controls.md`）。
- 依赖边界：引擎内建优先；第三方 addon／GDExtension／.NET 包按需引入并写明理由。
- 工具面：`tools/check.ps1` 是文档、规则与窗口门禁的唯一入口（文档阶段＋规则套件＋窗口套件＋可选 recipe 配方）；内容包改动后跑 `tools/check-content.ps1`；打包入口 `tools/package.ps1`／`tools/package-android.ps1`。规则与文档阶段用 `--headless` 调用引擎；窗口套件刻意走真实窗口（不加 `--headless`），是真实交互证据要求。打包脚本用 `pwsh`；`GODOT_BIN` 指向 `*_console.exe`。

### 表现层选型

| 场景 | 用什么 |
| --- | --- |
| 面板／卡牌／列表／文字 | `Control` 与容器；静态布局交 `.tscn` |
| 地图／棋盘／图形密集 | `Node2D` + `_draw()`／纹理／`MultiMesh` |
| 过渡与动画 | `Tween`／`AnimationPlayer`（不驱动规则） |
| 瞬时效果（震屏／滤镜／边框） | 单独瞬时层，节点 `MOUSE_FILTER_IGNORE`，不拦点击 |
| 触摸 | 与鼠标同一入口；长按等价右键（见 `docs/design/input-controls.md`） |

## 代码规范（GDScript）

以下为本仓强制约定（以当前代码为基线），检查工具覆盖不到，改动时人工遵守；与其它文档或旧说明冲突时以本文件为准：

- 缩进**每层一个空格**（不是四空格）；不重排函数、不批量格式化未触及的代码。该约定与官方风格工具（gdtoolkit）冲突，故本仓不引入 gdtoolkit 的 lint／format。
- 命名：变量与函数 `snake_case`，常量与 preload 类 PascalCase；判定只用稳定 ID（template／type／id），不用译文、颜色、名称或图片。
- 早退守卫写在前面。
- 注释写不变量、原因与边界；玩家可见文案与 docs 用中文。
- 新增文件须有明确职责边界与依据；大文件按职责拆，不按行数硬拆。
- 测试断言消息用英文并写明域；优先复用 `tests/` 既有夹具与真实输入助手。

## 实现规约（审查）

- 纯数值修改（既有配置或常量中的生命、伤害、费用、倍率、概率、数量）与同步文案／测试预期，不派独立子代理审查；仅修正文档错字、格式、链接且不改契约时也不派审查。规则逻辑、执行流程、接口、架构、测试判据或门禁规范变化，按完成的逻辑批次派一次**独立子代理审查**：初审用新会话，返修时沿用原审查者、只复核受影响范围；审查者只读，不得改动代码。
- 审查模型、证据复用与结束条件见 `skills/spire-validation-release/SKILL.md`「审查流程」。

## 检查力度与报告四态

- 每条检查（单条判据）都必须能被违反、并因此变红；新增检查必须随批附「改相反语义→红→还原」的证据。
- 按成本累加选档并记录原因：1 不需引擎（语法扫描／文档引用／依赖允许面）→ 2 headless（规则套件、内容包）→ 3 真实窗口（窗口套件、真实交互、只读投影断言）→ 4 冻结基线（oracle／摘要比对与重放）→ 5 成品与环境矩阵（打包、包内探针、双平台）。
- 报告四态：已测（带运行号）／未跑／被跳过（带授权）／假设。缺检查器只能补一个最小检查器或写「未建」；不得当通过，也不得把未跑写成通过。

## 最小索引

- 命令与操作流程见 `skills/repo-ops/SKILL.md`。

### 文档入口

| 任务 | 按需阅读 |
| --- | --- |
| 玩法、场次、奖励、资源 | docs/design/game-design.md |
| 装备、覆盖、链接、解除 | docs/design/equipment-design.md |
| 卡牌与内容创作 | docs/design/cards.md、docs/design/content.md |
| 角色2 | docs/design/character-two.md |
| 监狱及出狱 | docs/design/prison.md |
| 平板锁 | docs/design/cursed-plate-lock.md |
| 第一幕敌人 | docs/design/enemies-first-floor.md |
| 键盘与触屏 | docs/design/input-controls.md |
| 输入到落地的提交与刷新 | docs/spec/response-pipeline.md |
| 事件管线与事件结构 | docs/spec/event-pipeline.md |
| 状态迁移管线（单写入者） | docs/spec/transition-pipeline.md |
| 固定点存档 | docs/spec/save-fixed-points.md |
| 本局回顾（战报面板） | docs/spec/run-review.md |
| 卡面词条悬停显示 | docs/spec/card-terms.md |
| 文案与本地化 | docs/guide/localization.md、docs/guide/action-copy-guide.md |
| 验证结果（现行卷） | docs/record/verification.md |
| 版本日志 | docs/record/changelog.md |
| 美术来源与差分 | spire-godot/assets/art/ART-NOTES.md、spire-godot/assets/vendor/CREDITS.md |

### 项目 skill

skill 正文在根 `skills/*/SKILL.md`（供多 harness 使用）；`.zcode/skills/` 下同名文件仅为 ZCode 发现用的薄桩。

- `repo-ops`：命令与操作流程（检查门禁及语义、工作树、内容包校验、引擎定位、打包发布）。
- `spire-docs`：文档规范（五类生命周期、符号锚点、判据优先、依赖约束索引、记录诚实、文档守卫）。
- `spire-architecture`：架构边界与数据流（提交入口、只读投影、候选与索引、随机、只读复用、装备事务、分层）。
- `spire-ui-content`：界面、文案、本地化、立绘与素材。
- `spire-validation-release`：审查流程、验证口径、夹具隔离与发布边界。
