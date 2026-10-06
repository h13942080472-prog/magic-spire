# 仓库现状与目录职责（索引）

本文件是索引：登记本仓的物理边界、目录职责与相邻项目边界。
模块定位、必须遵守的规则与禁区以根 `AGENTS.md` 为准，本文件不重复其正文。
本文件不写执行结果；通过／失败／未执行只登记在验证记录（`docs/record/verification.md`）。

## 域

- 本仓当前只维护 `spire-godot/`：《紧缚尖塔》，Godot 4 塔路与卡牌游戏，本仓唯一模块。
- 网页文字 RPG《魔法少女又白给了》是同级另一仓库 `mahou-shoujo-escape`，不在本仓；
  本仓不引用其源码、素材清单或构建流程，也不运行它的 npm 门禁与发布。
- 相邻项目的数值与流程不适用于 `spire-godot/`：不据其实现或界面反向修改本仓规则定义。
- 游戏面向成人；所有登场角色均为成年人。素材与文案按任务授权及资源许可处理。

## 接口（目录与入口）

| 路径 | 职责 | 消费方 |
| --- | --- | --- |
| `AGENTS.md`（根） | 红线、本仓特有约束、Godot 技术栈与代码规范、最小索引 | 所有任务的第一入口 |
| `docs/spec/` | 现行契约：域、接口、输入域、失败语义与证据入口；**被取代即删，不留「更正」段** | 实现者、清洗者、加固者、验收者 |
| `docs/design/` | 玩法与内容真源（数值、流程、内容定义） | 规则与内容任务 |
| `docs/guide/` | 怎么干活：操作、文案与本地化的改法 | 动手前 |
| `docs/record/` | 只追加记录：验证卷（按时间分卷）、版本日志、性能测量、未落地提案 | 取证与追溯 |
| `docs/history/` | 只读归档：历史契约与已被推翻记录；用于追溯，不是待办 | 需要追溯决策时 |
| `spire-godot/core/`、`ui/`、`data/` | 规则内核、界面、静态数据 | 改动与运行时 |
| `spire-godot/content/`、`assets/` | 内容包（加载源与打包取值见 `docs/spec/packaging.md`）、素材（来源与差分见 `spire-godot/assets/art/ART-NOTES.md`、`spire-godot/assets/vendor/CREDITS.md`） | 内容与美术任务 |
| `spire-godot/tests/`、`spire-godot/tools/` | 规则／界面检查与打包、探针脚本 | 验证与发布 |
| `spire-godot/project.godot` | 版本号与导出预设的读取源（打包脚本据此选择预设） | 打包与发布 |
| `spire-godot/build/`、`outputs/` | 已忽略目录：构建证据与交付产物，不入库 | 按验证记录中的路径取证 |
| `release/` | 玩家面副本与启动器（`基础操作教学.txt`、`开始游戏.cmd`／`.vbs`） | 随包分发与启动 |
| `skills/` | 操作与领域技能正文：`repo-ops`（命令与操作流程）、`spire-architecture`、`spire-ui-content`、`spire-validation-release`；`.zcode/skills/` 下同名文件仅为 ZCode 发现用薄桩 | 动手前 |
| `LICENSE`、`ASSET_RIGHTS.md`、`版本更新内容.txt` | 许可、素材权利范围与版本更新记录 | 发布与素材处理 |

命令与操作流程不在本文件，也不在 `AGENTS.md`：见 `skills/repo-ops/SKILL.md`
（根级 git 检查、分类门禁、内容包校验、引擎定位、打包发布）。

## 输入域（本文件收录什么）

- 收录：目录职责、模块边界、相邻项目边界、文档入口的所在位置。
- 不收：玩法数值与规则（见 `docs/design/`）、接口语义、验证结果、版本日志。

## 失败语义

- 本文件与根 `AGENTS.md` 冲突时，以根 `AGENTS.md` 为准；与技术事实冲突时，以实际仓库位置为准。
- 目录职责或代码位置变化时同步更新本表；不得留下失效入口。

## 证据入口

- 文档改动：核对链接指向的文件在仓库内存在、编码与体积符合约定（纯文档修改不重跑游戏回归）。
- 仓库级检查命令与判读见 `skills/repo-ops/SKILL.md`；`spire-godot/` 的分类门禁与打包见该技能与
  `docs/spec/packaging.md`；验证结果登记在 `docs/record/verification.md`。
