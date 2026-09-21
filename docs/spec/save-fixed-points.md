# 固定点存档（进度写盘的三个固定点）

契约文件：进度存档只在三个固定点写入，写入内容＝写入时刻的场景起点；其余路径按显式意图或独立产物
保留。内部实现以代码为准，接口语义以本文件为准；函数名与稳定 ID 是锚点，本文件不写行号。
本文件不写执行结果：通过／失败／未执行与红集登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 收束对象：**进度的写盘时机与写入内容**。"进度"＝玩家在本局内的推进；恢复粒度＝三个固定点。
- 文件域：`core/game.gd`（声明表的 `checkpoint` 标记、`_checkpoint_kind`、`dispatch` 结果的
  `checkpoint` 键；另见「加性字段与只读入口」的 `state.initial_seed` 与 `restore_snapshot` 回填）、
  `ui/main.gd`（写盘判据与三条非进度写盘）、`core/save_store.gd`（文件读写与校验；新增只读入口 `fixed_point_text`）。
- 人可见后果（人已裁定接受）：
  1. 崩溃／退出后回到三个固定点中最近的一个（本层入口／上一场战斗结束／上次整备结束）；
     场景内（战斗中途、整备途中、房间之间）的进度不再保留。
  2. `saved_at` 含义＝"上次固定点写入时间"（不再是"上次点击"）。
  3. `.bak` 稳定持有**上一次固定点内容**；主菜单"继续"在损坏时回退到它。
  4. 主菜单摘要时间更新频率明显下降（只在三个固定点、手动保存与画线时变化）。
- 非目标：不改存档格式与 `save_revision`、不改 `pack()`／`unpack()` 的格式与校验、
  不改 `restart_snapshot()` 的冻结时机、不改 `read_slot` 回退规则与 `summary()` 语义、
  不改 `TRANSITIONS` 既有 kind 语义（只加 `checkpoint` 标记）、不新增生产文件与只读接口、
  不新增模块依赖、不做启动期迁移脚本、不改启动链。（后续切片新增的加性字段与只读入口见下节；`pack()`／`unpack()`
  与 `write_game` 的格式、校验、`.bak` 顺序仍不变。）

## 接口

```gdscript
# 本次提交实际产生的迁移条目（迁移日志增量）→ 固定点名；无命中返回 ""
const CHECKPOINT_PRIORITY = ["battle_end", "prepare_end", "floor"]
_checkpoint_kind(log_start: int) -> String

# dispatch 成功结果新增（加性）键：
#   {"checkpoint": "" | "floor" | "battle_end" | "prepare_end", …既有键与顺序不变…}

# UI 取法（不得做内容比较、不得读快照）：
#   if result.ok and String(result.get("checkpoint","")) != "": _save_progress()

# 签名不变：_save_progress(replace_incompatible=false)
# 签名不变：SaveStore.write_game(game, replace_incompatible=false, map_drawings={})
```

- **固定点＝声明表上的 kind**：`core/game.gd` 的 `TRANSITIONS` 中带 `checkpoint` 列的非空项
  （kind 清单与其余列见 `docs/spec/transition-pipeline.md`）。**必须只有一处声明**。
  `checkpoint` 的取值集合恰为 `floor`／`battle_end`／`prepare_end`，且与 `CHECKPOINT_PRIORITY`
  的取值集合相等。
- **推导按类别、与条目数无关**：`checkpoint` 只由本次提交出现过的 **kind 集合**按优先级取一
  （`battle_end` ＞ `prepare_end` ＞ `floor`）；**不得**依赖条目条数或相邻重复的次数；
  同一提交内重复出现同一 kind 时结果不变。
- **写入内容**＝写入时刻的 `restart_snapshot()` ＋ 当时线稿；写盘发生在**提交之后**
  （`dispatch` 成功返回、UI 收到非空 `checkpoint` 之后）。
- **删除恢复后立刻写盘**；**保留**三条非进度写盘（见"输入域"）。
- 明文约束：`read_slot` 的回退规则与 `summary()` 的语义、`.bak` 顺序（先 `copy 主→.bak`、
  后 `rename tmp→主`，故 `.bak` ＝写入前的主档＝上一次固定点内容）、存档格式与 `save_revision`
  均不变。

### 加性字段与只读入口（现行）

```gdscript
# 只读入口（无文件访问、不写盘、不改 state；唯一序列化仍 pack()）：
#   core/save_store.gd::fixed_point_text(game, map_drawings={}) -> {ok, slot, filename, text}
#   text = pack(game.restart_snapshot(), map_drawings)　# 与 write_game 写出的主档字节同源

# 加性字段（_init 写入一次，此后不变）：
state.initial_seed: int    # = _init 的 run_seed；state.seed 仍由 _restart_tower 改写

# 唯一回填点：core/game.gd::restore_snapshot
#   is_current 通过后、Snapshot.check 之前，对副本回填 initial_seed = seed（缺字段时）
```

- 加性字段**不升** `Snapshot.REVISION`（升版会把既有玩家存档判为不兼容）；`Snapshot.check` 的
  通用逐字段循环已要求该字段存在且为 `int`，`core/snapshot.gd` 零改动。
- 缺字段的旧档按当时的 `state.seed` 回填；缺 `save_revision` 或修订号不符的档仍按既有规则拒绝。
- `_scene_key` 不变；固定点身份与写入时机不受影响。
- 本节的字段与回填语义、`fixed_point_text` 的消费方（反馈附件）与玩家可见标识见
  `docs/spec/seed-identity.md` 与 `docs/spec/feedback-deployment.md`。

## 输入域

三个固定点（写入内容一律＝写入时刻的 `restart_snapshot()` ＋当时线稿）：

| `checkpoint` 值 | 来源 kind（声明表） | 预期恢复点 |
| --- | --- | --- |
| `"floor"` | `floor_enter`（**目标层高于当前层**，只用于真实移动与换塔落点） | 该层入口（新层第一个房间的起点） |
| `"battle_end"` | `battle_end_victory`／`battle_end_saturated`／`battle_end_captured`（**收押含在内**） | 战斗结束后的阶段起点（奖励／事件结果／收押结果） |
| `"prepare_end"` | `prepare_end`（三条分支：`pack`／`map`／`cleared`） | 整备结束后的起点（下一步行动前） |

- **同类多条目按类别去重**：取值不由条目数决定。
- **同层移动（`room_enter`）不是固定点；换塔（`tower_restart`）不是固定点**（人审裁定）。
- `floor_enter` **只认上行**（"进入新的一层"＝目标层更深）。若将来希望"回到上层也算固定点"，
  须先改 `docs/spec/transition-pipeline.md` 的 kind 语义，再改本片的标记（属行为口径变更，须立批）。
- 非进度写盘（按显式意图／独立产物保留，不变）：

| 触发 | 入口 | 写什么 | 说明 |
| --- | --- | --- | --- |
| 地图线稿变更 | `graph.drawings_changed` → `_save_progress` | 当前 `restart_snapshot()` ＋最新线稿 | 玩家批注是独立产物；**不改变恢复点**（文件内容始终是"起点＋最新线稿"，因此画线也会刷新主档；若要求画线不触碰主档，须把线稿拆成独立文件，属新切片） |
| 新局替换不兼容档 | `_save_progress(true)` | 开局起点＋线稿 | 版本不兼容时开始新局的必经路径 |
| 手动"保存场景起点" | 主菜单按钮 | 当前 `restart_snapshot()`＋线稿 | 显式用户意图；**无去重机制**，点击即写 |

- 删除恢复后那次写盘后，读档时被 `restore_snapshot` 抬升过的 `version` 不再立即写回文件；
  该字段只是乐观并发计数，存档内容不受影响，最新内容在下一次固定点写入时落盘。

## 失败语义

- 存档文件读写不设置字节数上限；超过原8 MiB的主档和备份均走相同格式、校验和、状态验证及回退流程。底层文件读写失败仍正常报告。
- **保留不得弱化**：失败路径与全部文案（`"保存失败：…原存档保留。"`／
  `"保存已暂停：原存档版本不兼容…"`／slot 非法／回读校验失败）；`pack()`／`unpack()`
  的格式与校验；`restart_snapshot()` 的冻结时机；`read_slot` 的回退规则与 `summary()` 的语义；
  `.bak` 顺序；任一失败不得被放行、不得为绿灯改文案。
- 语义归属：`checkpoint` 的推导只回答"这次提交是不是固定点、是哪一类"；
  "恰一条 `battle_end_*`"这类**语义**由闭环 check 与具名场景承接，
  **不得依赖 oracle 对迁移日志列的折叠边界**；`checkpoint` 推导不得读历史条目或跨提交累积。
- 算未完成（任一）：任一必跑命令未执行／失败／未知或跳过；`summary.json` 为
  `source_changed`／`failed`／`plan`；场景内仍有写盘；固定点漏写或 `checkpoint` 取值错；
  `checkpoint` 推导依赖条目数；闭环 check 与声明表标记不一致；新增生产文件、改 `pack()`／`unpack()`
  格式与校验、改 `restart_snapshot()` 冻结时机、改 `read_slot` 回退规则；未做敏感性证明；
  宣称完整回归或打包。

## 证据入口

- 具名 check（全部走真实公开命令：取候选 → `dispatch`；计数只用测试侧 `SaveStore` 子类包装，
  生产源码不带计数器）：

| 判据 | 落点（分类） |
| --- | --- |
| `save_writes_on_new_floor`（更深的层 → 写盘一次、恢复点＝该层入口、写入的是写入时刻的 `restart_snapshot()`） | `tests/persistence_cases.gd`（`persistence`） |
| `save_writes_when_battle_finishes`（三个 `battle_end_*` 各一例 → 各写一次、`phase` 等于结束后的阶段） | `tests/persistence_cases.gd` |
| `save_writes_when_prepare_finishes`（`prepare` 三种结束 → 各写一次、`phase` 不再为 `prepare`） | `tests/persistence_cases.gd` |
| `explicit_and_checkpoint_writes`（固定点提交恰写一次、写入写盘时刻的场景起点；其后非固定点提交不再写） | `tests/persistence_ui_cases.gd`（UI `persistence`） |
| `save_skips_representative_non_points`（战斗中出牌／结束回合／翻面／同层移动／商店交易／事件选择／宝箱领取／监狱巡视与牢房行动／休息房行动与休息回合／demo 结束／读档成功 → 主档与 `.bak` 字节与 mtime 不变且未调 `write_game`） | `tests/persistence_cases.gd` |
| `save_backup_holds_previous_fixed_point`（固定点 A → 固定点 B → 场景内活动；破坏主档后 `read_slot` 回退到 A） | `tests/persistence_cases.gd` |
| `save_fixed_point_preserves_failure_and_format_contract`（各类失败前置的返回值与文案逐字相同，格式与回退规则不变） | `tests/persistence_cases.gd` |
| `save_checkpoint_kinds_are_pinned`（声明表标了 `checkpoint` 的 kind 集合与固定清单**完全一致**，多一个少一个即红；取值合法；`CHECKPOINT_PRIORITY` 的取值集合与声明出的固定点名相等） | `tests/architecture_cases.gd`（`architecture`） |
| `map_drawings`（线稿与场景起点一起持久化，恢复点不变） | `tests/persistence_cases.gd` |
| 重复不敏感（向本次提交的迁移日志注入一条相邻重复 → `checkpoint` 取值不变、写盘次数仍为 1） | 由 `persistence` 分类的具名 check 承接（与上表同一批判据） |

- 本片之外的现行判据见 `docs/spec/seed-identity.md` 与 `docs/spec/feedback-deployment.md` 的证据入口表；
  本片新增的只读入口另有具名 check：`fixed_point_text` 与 `write_game` 写出的主档字节逐字一致、
  只调用它不产生文件与 mtime 变化且不改 `state`／随机、`slot`／`filename` 与 `game.state.save_slot` 一致
  （落点：`persistence` → `tests/persistence_cases.gd`）。

- 命令（在 `spire-godot/` 下执行）：

```powershell
& tools/check.ps1 -Suite persistence,architecture -Impact -KeepGoing -TimeoutSeconds 600
& tools/check.ps1 -UIOnly -UISuite persistence,home -TimeoutSeconds 900
```

  范围预检（不算通过）：两条命令加 `-ListOnly`。判据：退出码 0；`summary.json` 的 `status=passed`
  且 `before==after` 指纹（`source_changed` 不算通过）；红集口径见
  `docs/spec/transition-pipeline.md`（**不得新红**）；`content/packs` 未改动，不跑 `check-content.ps1`。
- **敏感性证明（必须做，随后还原）**：临时让一个非固定点的 `dispatch` 也带 `checkpoint`
  （或让某个固定点 kind 不写）→ 相关 check 必须变红；还原后全绿。证据（临时补丁＋红日志）入报告。
- 人的路径证明（判据是套件的布尔 check）：战斗内点若干张牌与结束回合 → 主档与 `.bak` 的 mtime 不变；
  打赢这一场 → 写盘，主页"继续"回到战斗结束后的起点；走完整备 → 写盘，整备中再做操作 → 不再写；
  走到更深的层 → 写盘且恢复点＝该层入口，同层换房不写；塔路图画一笔 → 写盘（恢复点不变）；
  手工破坏主档 → 主页"继续"回到上一次固定点且状态完整；不打包、不发布。
- 性能判据：沿用 `docs/spec/response-pipeline.md` 与 `docs/record/equipment-performance.md` 的配对协议
  （0／12／26 件 × battle／departure，2 热身＋15 配对，报逐对比值中位与两侧独立中位）。
  口径：①**场景内提交的 `save` 段＝0**（由"未调用 `write_game`"＋mtime／字节断言立证），
  同夹具总耗时下降量照报；②固定点单次写盘成本**照报**（不设下降目标）；③不得以"应该更快"、
  单次采样或拼接历史数字宣称收益。计时脚本与 JSON 只放已忽略的 `build/`，摘要登记后删除原始目录，
  生产源码不留计数器。
- 登记位置：`build/checks/<id>/`（`check-rules.log`／`check-ui.log`／`summary.json`）；
  结论与域写 `docs/record/verification.md`（validator 负责，不在本文件宣称通过）。
- 依赖约束（cleaner 可核对）：允许改动＝`core/game.gd`（声明表 `checkpoint` 标记、`dispatch` 结果的
  `checkpoint` 键与其推导）、`ui/main.gd`（删除恢复后写盘点；`_submit` 只在 `checkpoint` 非空时写盘）、
  `tests/persistence_cases.gd`／`tests/persistence_ui_cases.gd`／`tests/architecture_cases.gd`、
  计时脚本（不入库）。依赖方向＝`ui/main.gd → core/{Game,SaveStore}`（既有边）；
  `core/game.gd` 内部改一处推导。
- 本片之后的现行改动清单（`fixed_point_text`、`state.initial_seed` 与 `restore_snapshot` 回填、
  只读投影与地图角标）见 `docs/spec/seed-feedback-dependencies.md`；本段其余约束继续有效。
