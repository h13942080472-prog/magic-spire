---
name: spire-docs
description: >-
  《紧缚尖塔》的文档规范：五类生命周期与写入规则、符号锚点、判据优先、改动同步义务、
  依赖表与允许改动表、记录诚实、文档守卫。改动 docs/、写契约或写记录之前读它。
---

# 文档规范（magic-spire）

## 五类生命周期与写入规则

| 类 | 目录 | 规则 |
| --- | --- | --- |
| 现行契约 | `docs/spec/` | 只写现在成立的事；**被取代即删**，不留"更正"段；同一条规则只写一处 |
| 设计与内容真源 | `docs/design/` | 每条事实只写一处，其它文件只链接，不复制 |
| 怎么干活 | `docs/guide/` | 操作口径（本地化、文案指南等） |
| 记录 | `docs/record/` | **只追加**；每条带日期＋域；验证册按时间分卷；历史压缩仅允许**整句删除**且保留句须逐字，原始文本以 git 历史为准 |
| 归档 | `docs/history/` | 只读；含已被推翻的旧决策，不得当成现行指令 |

## 引用与锚点

- 引用代码用**符号锚点**（如 `core/game.gd::route_view`、`ui/route_map.gd::_input`），**不写行号**——行号随每次改动漂移。
- 引用文件用仓库相对路径（`spire-godot/ui/route_map.gd`、`docs/spec/…`）；写进文档前先确认该路径存在。

## 规范句写作约束

- 规范句必须自足——写明主体、范围、极性与被禁对象；否定与肯定分句写；例外另起一句；不得留下可被读成"整类做法一律禁止"的表述。

## 判据优先

- 一条规则要么配一个"关掉它什么会红"的检查，要么明写"本规则无机械判据、靠人审"。**没有判据又没有替代动作的禁令就是噪声**：不要写"不从叙事、颜色或标签猜规则事实"这类句子，写正面规则——判定只用稳定 ID。
- 契约里的判据条目若尚无对应检查，必须标注"未守卫"，并登记到 `docs/record/proposals/`。

## 改动同步义务

- 文档以当前架构为基线；架构改变时同批推翻受影响文档；发现文档与实现冲突时先问，不得绕行遵守旧文档。
- 改代码或内容时，同步改动点名的文档：文档入口表、依赖约束索引、本地化 key 表、设计真源、
  **管线／邻接表**（第五类）。
- **管线／邻接表**：声明"某入口按哪些边到达哪些子例程"的表，改实现路径、改节／例程名或改边时，
  必须在**同一批**改动里同步该表，否则表与实现漂移而无人可查。现有三张：
  - `spire-godot/ui/main.gd::PRESENT_ADJACENCY`（present 管线声明表）：入表口径见其表头注释，判据＝
    `spire-godot/tests/architecture_cases.gd::present_adjacency_graph_is_pinned`（三条：声明边必须有直调、
    表内符号被已登记父函数直调必须登记、无死项）。该判据只校验**已声明**的边，不保证每个管线条目都已登记：
    新增节／舞台例程不入表、删整行、乃至把整表掏空为 `{"present":[]}` 都不会变红，**由评审负责**；
    不设完整性下限（"已登记父在 `ui/main.gd` 里的每个直调都须入表或成子"会牵出约 80 个本地例程，
    多为随实现频繁变动的构建／域例程，属第二份易漂移手工清单）。每个被声明的符号（含仅作子出现的叶）都必须在表内有自己的行。
  - `docs/spec/candidate-removal.md` 的管线表（邻接表，第 1 节现状图与第 2 节目标图）：跨文件锚点、
    含历史行与未落地行，**无整表机械判据**；其机读子集＝
    `spire-godot/tests/architecture_cases.gd::PIPELINE_LOOKUP_EDGES`（检查入口
    `spire-godot/tests/architecture_cases.gd::command_fact_kind_lookup`）与
    `spire-godot/tests/architecture_cases.gd::instruction_router_single_entry`。改该表的边或锚点须同批核对这两处。
  - `docs/spec/equipment-query-seam.md` 的邻接表（`targets_at`／`has_targets_at` 路径一节）：声明查询入口到
    按槽走查的边与禁止边，**无整表机械判据**；其行为检查器＝
    `spire-godot/tests/equipment_cases.gd::index_targets_edge_parity`、
    `spire-godot/tests/architecture_cases.gd::has_targets_at_parity` 与
    `spire-godot/tests/architecture_cases.gd::index_materializes_once_per_scope`。改该表的边或锚点须同批核对这三处。
- 被取代的段落**改写为新事实或删除**；不要在新事实旁边留着旧事实当注释。

## 依赖约束索引（`docs/spec/*-dependencies.md`）

- 片落地后依赖规约退化为索引：判据只留"名字＋执行它的检查符号"（`文件::符号`），不复述判据内容；
  检查符号由 `spire-godot/tools/check-docs.ps1` 的锚点校验保证不腐烂，改名或删除检查会让门禁变红。
- 允许改动表随授权期结束删除；无机械判据但仍约束行为的条目留在文件末尾「仍靠人审」一节。

## 记录诚实

- `docs/record/**` 是**证据索引**（2026-10-05 起）：每条 = 日期＋标题＋域行＋证据句（命令、运行号、
  断言计数、退出码／status／指纹、产物路径）＋**未跑项**＋失败与不作证据轮；不得把未跑写成通过；
  空出的可查性靠 `build/checks/<运行号>` 与具名 check。
- 历史压缩的保留白名单（这些形态今后不可删）：任何分隔写法的 `before/after`、小写 `failed`、
  「哈希」／`SHA256`／checksum 行、40／64 位十六进制、运行号、`build/`／`outputs/` 路径、
  含失败／未跑／未验证／不作证的原句，以及标题、日期与域行。
  取证：`spire-godot/tools/check-record-conservation.ps1 -Base <rev>`（迁移期脚本，四类差集非空即非零退出）。
- 指纹与摘要只作**同一次运行内**的守卫，**不当身份**；跨运行可对账的是逐分类计数与具名 check。
- 运行号必须可查（`build/checks/<运行号>`）；日志已被清理时写明"随临时 worktree 删除"。

## 文档守卫（现行）

- 规则类文档（`docs/spec`、`docs/design`、`docs/guide`、根 `AGENTS.md`、`skills/*/SKILL.md` 正文与其
  `.zcode/skills/*/SKILL.md` 发现用薄桩）在 `tools/check.ps1::Get-SourceFingerprint` 内：
  改这些文档会触发 `SOURCE CHANGED`，不再是零守卫。
  范围与排除理由（`docs/record/**` 只追加、`docs/history/**` 只读归档）的唯一声明在
  `spire-godot/tools/doc-scan-scope.ps1`。
- 引用门禁 `spire-godot/tools/check-docs.ps1`：点名路径必须存在、`文件::符号` 锚点必须已声明、
  本地 md 链接必须可达。允许存在的缺失引用逐条登记在检查内的允许清单（带理由与消掉条件），
  检查每次打印条目数；清单只能缩小。
- 仍靠人审：仍存在的允许改动表与实现的文件面一致（多写、少写都要改）、判据条目的实质正确性、
  被取代段落的删除。这三条没有机械判据。
