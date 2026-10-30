# AGENTS.md

## 项目是什么

- 本仓当前只维护 `spire-godot/`（《紧缚尖塔》，Godot 塔路与卡牌游戏）。
  模块边界与目录职责见 `docs/spec/project-map.md`。

- 网页项目《魔法少女又白给了》是同级另一仓库 `mahou-shoujo-escape`，不在本仓。
  本仓不引用其源码或构建流程；其数值与流程不适用于 Godot，
  不据其界面反向修改本仓规则定义。

- 游戏面向成人；所有登场角色均为成年人。
  素材与文案按任务授权及资源许可处理。

- 当前工作区以实际仓库位置为准。
  不使用历史文档中的旧绝对路径定位源码。

- 历史决策与归档见 `docs/history/`（只读，含作者侧的 PR 集成评审）。
  只读取当前任务相关的文档和章节。

- 历史记录用于追溯，不是新的待办。
  不把归档中的旧约束恢复成当前要求。

- 规则集中在根 AGENTS.md；将来加入第二个模块时再按模块拆分。

## 常用命令

命令与操作流程不在本文件：见 `skills/repo-ops/SKILL.md`
（根级 git 检查、职能工作树、`spire-godot` 分类门禁与语义、内容包校验、引擎定位、打包发布）。

## 必须遵守的规则

- 最新明确用户要求优先于旧设计记录。
  冲突时先核对文档日期及所属模块。

- 已确认规则优先于旧 Demo 行为。
  不根据旧界面反向修改规则定义。

- 开始修改前检查已有差异。
  用户和其他任务的在途修改必须保留。

- 先读相关规则、实现及现有测试。
  修改范围以当前任务及其必要依赖为限。

- 验证结论必须对应实际运行的源码。
  报告测试范围、失败和未验证部分。

- 长背景、数值修订和执行结果写入 docs。
  AGENTS.md 不追加聊天流水或版本日志。

- 指引只写长期规范与索引；细节、操作与历史拆到 docs/ 与项目 skill。

- 前端呈现文字禁止过度防御化与过度描写；直接表达玩家需要的信息，保留必要的规则事实。
  适用范围与写法见 `docs/guide/action-copy-guide.md`「前端文字表达」。

- 规则类文档由文档门禁检查引用，并纳入源码指纹；历史归档与执行记录不在此门禁范围。
  文档改动必须自证——点名的路径与符号存在、依赖表与实现的文件面一致、被取代的段落改写或删除而不是加批注；
  细则见 `skills/spire-docs/SKILL.md`。

## 实现规约（改动前必读）

- 完成需要有检查证据；修改使受影响行为及其依赖的既有结论作废，只在受影响范围重新取证。
  只消费接口：接口契约成立时内部视为可信，接口结果变红或任务点名时才打开内部。
  结构服从四件事：行为可验证、结构可理解、依赖受控、失败可确定性识别。

- **先查重，再新增**：动手前先搜索是否已有相同实现（函数、判定、候选、写入点、查询入口）。
  有相同语义的实现就在原接口上扩展，不新增第二套接口。

- **结构变化先规划**：新增或改变模块边界、调用通道、状态写入点时，先说明结构并补充必要的图；
  已有图仍适用时直接引用，局部修复只需说明影响范围，不另写设计文档。
  保证同类方法走同一条通道，到具体运作层再路由；写入、判定、执行各自只允许一个入口，
  多入口要么合并、要么由一份声明表派生；同一语义有且仅有一条路径。

- **校验按职责保留**：输入合法性、指令形状与状态版本、支付、事务一致性及失败回滚属于正式契约，发行包仍须执行。
  额外诊断与重复一致性断言走 debug 通路；新增或修改检查须有能触发对应缺陷的负例，必要时补敏感性实验。
  不因缺少旧证明直接删除检查；只有契约已失效、路径不可达或已有等价覆盖时，才依据证据删除或合并。

- **高频路径只做增量**：每次点击或提交走的路径按变化量更新，耗时不得随装备数量增长；
  全量重算只允许在读档与阶段切换时发生。显示层可跨帧、跨提交复用，但须写明失效条件
  （见 `docs/spec/response-pipeline.md`）。

- **引用代码不写行号**，用函数名与符号锚点（行号随每次改动漂移）。

- **纯数值修改无需独立审查**：仅调整既有配置或常量中的生命、伤害、费用、倍率、概率、数量等数值，
  以及同步对应文案和测试预期时，不派独立子代理审查；仍按影响范围完成必要校验。
  仅修正文档错字、格式、链接且不改变契约时，同样不派独立审查。
  规则逻辑、执行流程、接口、架构、测试判据或门禁规范变化，按完成的逻辑批次派一次**独立子代理审查**；
  初审使用新会话，返修沿用审查者，只复核受影响范围；审查者只读，不顺手改代码。
  模型选择、证据复用与结束条件统一见 `skills/spire-validation-release/SKILL.md`「审查流程」。

## 禁区

- 不复制第二套 Demo 或规则内核。
  不从历史部署归档恢复当前源码。

- 不绕过指令路由与唯一判定修正界面结果。
  不由组件直接修改资源、装备或回合。

- 不为了展示效果伪造装备或状态。
  不把占位入口宣称为已实现功能。

- 不用本地化后的文本识别对象。

- 不删除有效失败案例换取绿灯。
  过期或重复测试须依据覆盖关系处理。

- 不把少量采样称为完整回归。
  不把桌面资源探针称为安卓真机验收。

- 不提交缓存、用户存档和临时日志。
  构建目录及依赖目录不得手工修补。
  职能工作树放在主检出目录外的专用临时目录，定位方式见 `skills/repo-ops/SKILL.md`。

- 不把密钥、签名秘密或令牌写入仓库。
  日志与归档也必须遵守此限制。

- 不强推或覆盖远端提交。
  有歧义的冲突、权限问题先说明阻碍。

- 不把源码同步等同于打包或发布。
  安装包、标签和 Release 遵循明确要求。

- Godot 大版本完成且门禁通过后自动推送。
  先核对远端、分支与范围，只提交已完成内容。

- 小修改不触发大版本自动提交。
  不为推送提前宣布里程碑完成。

## 验证方式

- 格式与导入约束交给已有检查工具。
  代码风格保持现状，不做无关批量格式化。

- 新规则覆盖正例、最近反例与边界。
  有支付、版本或随机变化时检查回滚。

- 跨系统变化覆盖真实交互路径。
  UI 出现和静态文本匹配不能代替行为验证。

- 纯文档修改验证链接、编码和体积。
  不为说明文件重跑整个游戏回归；契约或流程文档变化另核对相关实现或实际任务情景。

- 测试通过后只因新修改或新问题重跑。
  不无故扩大范围或重复已完成的检查。

- 交付前复查本次差异及验证结果。
  明确是否只改源码、是否已打包或发布。

## 模块规则（spire-godot/）

以下是模块的文档索引、项目 skill 索引与代码规范；架构、界面文案素材、验证发布的细则在同目录技能里。

### 文档入口

文档按生命周期分五类，各有写入规则：
`docs/spec/` 现行契约（**被取代即删，不留"更正"段**）；`docs/design/` 玩法与内容真源（每条事实只写一处，其它文件只链接）；
`docs/guide/` 怎么干活；`docs/record/` 只追加（每条带日期＋域，验证册按时间分卷）；`docs/history/` 只读归档。

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
| 事实查询与按需投影 | docs/spec/fact-lookup-dependencies.md、docs/spec/fact-table-dependencies.md |
| 检查路由 | docs/spec/check-routing.md |
| 状态字段读者 | docs/spec/state-readers.md、docs/spec/state-readers-dependencies.md |
| 事件管线与事件结构 | docs/spec/event-pipeline.md |
| 状态迁移管线（单写入者） | docs/spec/transition-pipeline.md |
| 固定点存档 | docs/spec/save-fixed-points.md |
| 本局种子标识与查看复制 | docs/spec/seed-identity.md |
| 本片依赖约束（cleaner 核对） | docs/spec/seed-feedback-dependencies.md |
| 手牌卡增量刷新（cleaner 核对） | docs/spec/hand-refresh-dependencies.md |
| 本局回顾（战报面板） | docs/spec/run-review.md |
| 本局回顾依赖约束（cleaner 核对） | docs/spec/run-review-dependencies.md |
| 卡面词条悬停显示 | docs/spec/card-terms.md |
| 卡面词条依赖约束（cleaner 核对） | docs/spec/card-terms-dependencies.md |
| 指令判定与候选移除 | docs/spec/candidate-removal.md、docs/spec/candidate-removal-dependencies.md |
| 装备只读查询 | docs/spec/equipment-query-seam.md |
| 玩家可见文案的收口与按需 | docs/spec/ondemand-copy.md |
| 界面拆分与装备详情 | docs/spec/release-interface.md |
| 项目结构 | docs/spec/project-map.md |
| 打包与反馈服务 | docs/spec/packaging.md、docs/spec/feedback-deployment.md |
| 文案与本地化 | docs/guide/localization.md、docs/guide/action-copy-guide.md |
| 验证结果（现行卷） | docs/record/verification.md |
| 版本日志与历史验证分卷 | docs/record/changelog.md、docs/record/ |
| 性能测量 | docs/record/equipment-performance.md |
| 未落地提案与前端问题清单 | docs/record/proposals/ |
| 美术来源与差分 | spire-godot/assets/art/ART-NOTES.md、spire-godot/assets/vendor/CREDITS.md |
| 历史决策追溯 | docs/history/ |

历史归档包含已被推翻的记录；先搜索主题再读取相关段落，
按用户最终要求和最新专题文档判断，不能整份视为现行指令。

### 项目 skill 索引

技能正文在根 `skills/`，`.zcode/skills/` 保留发现用薄桩；改动前按需读取：

- `repo-ops`：命令与操作流程（检查门禁及语义、工作树、内容包校验、引擎定位、打包发布）。
- `spire-docs`：文档规范（五类生命周期、符号锚点、判据优先、依赖表与允许改动表、记录诚实、文档守卫）。
- `spire-architecture`：架构边界与数据流（提交入口、只读投影、候选与索引、随机、只读复用、装备事务、分层）。
- `spire-ui-content`：界面、文案、本地化、立绘与素材。
- `spire-validation-release`：验证口径、测试夹具隔离、自动推送与打包发布边界。

### 代码规范

以下为本模块现状约定，检查工具覆盖不到，改动时人工遵守：

- GDScript 缩进是**每层一个空格**（不是四空格）；不重排函数、不批量格式化未触及的代码。
- 命名：变量与函数 snake_case，常量与 preload 类 PascalCase；判定只用稳定 ID（template/type/id）。
- 早退守卫写在前面。
- 注释写不变量、原因与边界（英文）；玩家可见文案与 docs 用中文。
- 新增文件须有明确职责边界与依据；大文件按职责拆，不按行数硬拆。
- 测试断言消息用英文并写明域；优先复用 `tests/` 既有夹具与真实输入助手。
