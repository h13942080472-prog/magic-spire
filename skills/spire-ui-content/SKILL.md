---
name: spire-ui-content
description: >-
  《紧缚尖塔》的界面、文案、本地化、立绘与素材规范：静态布局与局部刷新、
  抽屉与模态、拖牌目标、投影分工、对白与旁白口径、译文边界、差分与字体授权。
  改动 ui/、玩家可见文案或美术资源之前读它。
---

# 界面、文案与素材（spire-godot）

- 静态布局逐步由 .tscn 管理，脚本读 View 并经指令路由提交意图与版本；普通刷新保留立绘与焦点，禁止每帧重画或整树销毁重建（见 docs/spec/release-interface.md）。
- 抽屉、二级说明与模态复用共享入口；遮罩关闭不得把点击穿透成背后行动。
- 拖牌按真实身体部位展开目标、提交前不付费；锁定或无效目标保留具体原因，不自动改牌面效果。
- 状态、卡面、日志、对白与旁白各用对应投影；不重复规则说明，不删玩家决策所需的费用、概率与限制。
- 文案按 wear_style 与人物／附魔物自行动作区分；对白只写实际发声，旁白第二人称（见 docs/guide/action-copy-guide.md）。
- 语言与译文只经 ui/localization.gd 在显示边界处理；显示偏好独立保存，不改候选、存档或随机（见 docs/guide/localization.md）。
- 立绘与差分统一由 ui/equipment_portrait.gd 组合，读真实覆盖与占位；马眼棒差分只在「任意平板锁＋内置导尿管或独立马眼棒」时显示；只读映射不改装备效果（见 docs/design/cursed-plate-lock.md）。
- 外部素材只从授权来源导入并保留处理记录；全语言使用内置字体及其许可（见 assets/art/ART-NOTES.md、assets/fonts/SOURCE.md）。
- 快照版本以 core/snapshot.gd 为准，不擅自新增旧档迁移。

### 验证与发布

见 `skills/spire-validation-release/SKILL.md`「验证与发布」（唯一副本；本节原为逐字重复）。

### 代码规范

见根 `AGENTS.md`「代码规范」（唯一副本；本节原为逐字重复）。
