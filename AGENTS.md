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

- 命令与操作流程见 `.zcode/skills/repo-ops/SKILL.md`；打包与发布先读 `docs/spec/packaging.md`。

- 历史决策与归档见 `docs/history/`（只读，含作者侧的 PR 集成评审）。
  只读取当前任务相关的文档和章节。

- 历史记录用于追溯，不是新的待办。
  不把归档中的旧约束恢复成当前要求。

- 规则集中在根 AGENTS.md；将来加入第二个模块时再按模块拆分。

## 常用命令

命令与操作流程不在本文件：见 `.zcode/skills/repo-ops/SKILL.md`
（根级 git 检查、`spire-godot` 分类门禁与语义、内容包校验、引擎定位、打包发布）。

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

- 改动文档没有门禁兜底：`docs/` 不在检查指纹集合内，改文档不会让任何检查变红。
  文档改动必须自证——点名的路径与符号存在、依赖表与实现的文件面一致、被取代的段落改写或删除而不是加批注；
  细则见 `.zcode/skills/spire-docs/SKILL.md`。

## 实现规约（改动前必读）

- 完成需要有检查证据；返工使受影响域的既有结论作废，必须在该域重新取证。
  只消费接口：接口契约成立时内部视为可信，接口结果变红或任务点名时才打开内部。
  结构服从四件事：行为可验证、结构可理解、依赖受控、失败可确定性识别。

- **先查重，再新增**：动手前先搜索是否已有相同实现（函数、判定、候选、写入点、查询入口）。
  有相同语义的实现就在原接口上扩展，不新增第二套接口。

- **先规划结构再写代码**：实现前把结构写清楚并作图（数据流、调用通道、写入点），
  保证同类方法走同一条通道，到具体运作层再路由；写入、判定、执行各自只允许一个入口，
  多入口要么合并、要么由一份声明表派生；同一语义有且仅有一条路径。

- **不做无意义的 validation**：只保留能抓真实缺陷的检查，每条检查要有
  "关掉它会让既有测试变红"的敏感性证明，否则删除。这类检查走 debug 通路
  （构建类型判定），发行包不开启；缺失的早拦由提交后的聚合校验兜底并回滚。

- **引用代码不写行号**，用函数名与符号锚点（行号随每次改动漂移）。

- 实现完成后派**独立子代理审查**（新会话，不做自我验收）；审查以接口契约为边界，
  报告点名域与证据，审查者不顺手改代码。

## 禁区

- 不复制第二套 Demo 或规则内核。
  不从历史部署归档恢复当前源码。

- 不绕过正式候选修正界面结果。
  不由组件直接修改资源、装备或回合。

- 不为了展示效果伪造装备或状态。
  不把占位入口宣称为已实现功能。

- 不从叙事、颜色或标签猜规则事实。
  不用本地化后的文本识别对象。

- 不删除有效失败案例换取绿灯。
  过期或重复测试须依据覆盖关系处理。

- 不把少量采样称为完整回归。
  不把桌面资源探针称为安卓真机验收。

- 不提交缓存、用户存档和临时日志。
  构建目录及依赖目录不得手工修补。

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
  不为说明文件重跑整个游戏回归。

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
| 事件管线与事件结构 | docs/spec/event-pipeline.md |
| 状态迁移管线（单写入者） | docs/spec/transition-pipeline.md |
| 固定点存档 | docs/spec/save-fixed-points.md |
| 本局种子标识与查看复制 | docs/spec/seed-identity.md |
| 本片依赖约束（cleaner 核对） | docs/spec/seed-feedback-dependencies.md |
| 本局回顾（战报面板） | docs/spec/run-review.md |
| 本局回顾依赖约束（cleaner 核对） | docs/spec/run-review-dependencies.md |
| 候选局部筛查契约 | docs/spec/candidate-delta.md |
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

细节规范与操作按类拆到本目录技能，改动前按需读取：

- `repo-ops`：命令与操作流程（检查门禁及语义、内容包校验、引擎定位、打包发布）。
- `spire-docs`：文档规范（五类生命周期、符号锚点、判据优先、依赖表与允许改动表、记录诚实、文档守卫）。
- `spire-architecture`：架构边界与数据流（提交入口、只读投影、候选与索引、随机、只读复用、装备事务、分层）。
- `spire-ui-content`：界面、文案、本地化、立绘与素材。
- `spire-validation-release`：验证口径、测试夹具隔离、自动推送与打包发布边界。

### 代码规范

以下为本模块现状约定，检查工具覆盖不到，改动时人工遵守：

- GDScript 缩进是**每层一个空格**（不是四空格）；不重排函数、不批量格式化未触及的代码。
- 命名：变量与函数 snake_case，常量与 preload 类 PascalCase；判定只用稳定 ID（template/type/id）。
- 失败用返回原因字符串表达（空串=成功）或 `{ok,error}` 字典，不用异常；早退守卫写在前面。
- 注释写不变量、原因与边界（英文）；玩家可见文案与 docs 用中文。
- 新增文件须有明确职责边界与依据；大文件按职责拆，不按行数硬拆。
- 测试断言消息用英文并写明域；优先复用 `tests/` 既有夹具与真实输入助手。
