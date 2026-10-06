---
name: spire-architecture
description: >-
  《紧缚尖塔》模块的架构边界与数据流规范：指令收口与只读投影、候选与索引、
  随机域、只读复用边界、装备事务与分层、注册表与实例分离。改动 spire-godot 的
  core/、data/、ui/ 之前读它；涉及具体机制时再按根 AGENTS 的文档入口表取专题文档。
---

# 架构边界（spire-godot）

- 规则使用稳定 ID 和显式数据。
  显示名称、译文和图片不能参与判定。

- 派生状态从真实实例计算。
  不维护多份可能失去同步的规则副本。

- 内容不得反向开放尚未实现的能力。
  菜单入口必须对应真实可执行流程。

- 规则变化同步相关玩家可见文字。
  数值、费用、原因与实际行为必须一致。

- core/game.gd 是状态与事务唯一提交入口；core/game_view.gd 生成只读显示快照，UI 不读不写 game.state。
- UI 提交经 `ui/command_router.gd` 的 `emit` 收口（分类转发表 `ROUTES`）；提交处复核指令形状（kind＋params）与状态版本；显示查询只读 View 的显示事实，不重算资格。
- ui/target_queries.gd 是身体目标／拖放载荷／解除候选的唯一查询入口：只吃 View 的显示事实，不持有游戏、控件（见 docs/spec/release-interface.md）。
- core/pressure.gd 等助手沿正式初始化／行动／回合管线执行，不另立玩家命令；失败必须完整回滚。
- balance、card_rules、relics、enemies 等注册表集中维护数值；敌人种类与实例 ID 分离，意图／生命／来源／打断按实例保存。
- data/field_tools.gd 只维护注册表与说明，规则落在 core/tool_rules.gd；规则内只用 g.Tools，不复制第二份数值表。
- 随机由种子与独立随机域驱动，结果按所属阶段冻结；查询、预览、翻面、翻译与公开意图不推进随机。
- core 装备查询作用域的索引、预览输入与返回容器隔离复制，只在该次只读调用内复用、不跨提交保留（见 docs/spec/equipment-query-seam.md）。UI 投影与显示态按 docs/spec/response-pipeline.md 的可证失效规则复用，不把 core 查询作用域限制扩大为 UI 跨帧禁令。
- 装备安装／替换／删除复用工厂与统一清理（批次保留 protected_ids）；层级、真实覆盖、容量、锁、触及与操作来源必须同时复核，不用件数或区域标签猜能力（见 docs/design/equipment-design.md）。
- 正式练习先过工厂初始化，此后与玩家流程一致；不向 UI 开放夹具写入。
- 新功能先复用现有模板、工厂、通用字段／效果与事务；新职责边界须有具体需求与依据。
  在用户已授权目标内自行选择实现；新玩法或超出任务范围的机制才说明缺口并确认。
- 一个可试玩闭环一次做完；任务记录在 `docs/record/changelog.md`，验证在 `docs/record/verification.md`，不另建看板。

界面文案、本地化回退与素材来源见 `skills/spire-ui-content/SKILL.md` 及其专题文档；
审查、夹具隔离与验证见 `skills/spire-validation-release/SKILL.md`；代码规范见根 `AGENTS.md`。按任务读取。
