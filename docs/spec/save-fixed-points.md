# 固定点存档（进度写盘的三个固定点）

契约文件：进度存档只在三个固定点写入，写入内容＝写入时刻的场景起点；其余路径按显式意图或独立产物
保留。内部实现以代码为准，接口语义以本文件为准；函数名与稳定 ID 是锚点，本文件不写行号。
本文件不写执行结果：通过／失败／未执行与红集登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 收束对象：**进度的写盘时机与写入内容**。「进度」＝玩家在本局内的推进；恢复粒度＝三个固定点。
- 文件域：`core/game.gd`（声明表的 `checkpoint` 标记、`_checkpoint_kind`、`dispatch` 结果的
  `checkpoint` 键；另见「加性字段与只读入口」的 `state.initial_seed` 与 `restore_snapshot` 回填）、
  `ui/main.gd`（写盘判据与三条非进度写盘）、`core/save_store.gd`（文件读写与校验；只读入口 `fixed_point_text`）。
- 人可见后果（人已裁定接受）：
  1. 崩溃／退出后回到三个固定点中最近的一个（本层入口／上一场战斗结束／上次整备结束）；
     场景内（战斗中途、整备途中、房间之间）的进度不再保留。
  2. `saved_at` 含义＝「上次固定点写入时间」（不再是「上次点击」）。
  3. `.bak` 稳定持有**上一次固定点内容**；主菜单「继续」在损坏时回退到它。
  4. 主菜单摘要时间更新频率明显下降（只在三个固定点、手动保存与画线时变化）。
- 非目标：不改存档格式与 `save_revision`、不改 `pack()`／`unpack()` 的格式与校验、
  不改 `restart_snapshot()` 的冻结时机、不改 `read_slot` 回退规则与 `summary()` 语义、
  不改 `TRANSITIONS` 既有 kind 语义（只加 `checkpoint` 标记）、不新增模块依赖、不做启动期迁移脚本、
  不改启动链。

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
  的取值集合相等（`tests/architecture_cases.gd::save_checkpoint_kinds_are_pinned`）。
- **推导按类别、与条目数无关**：`checkpoint` 只由本次提交出现过的 **kind 集合**按优先级取一
  （`battle_end` ＞ `prepare_end` ＞ `floor`）；**不得**依赖条目条数或相邻重复的次数；
  同一提交内重复出现同一 kind 时结果不变。
- **写入内容**＝写入时刻的 `restart_snapshot()` ＋ 当时线稿；写盘发生在**提交之后**
  （`dispatch` 成功返回、UI 收到非空 `checkpoint` 之后）。
- **删除恢复后立刻写盘**；**保留**三条非进度写盘（见「输入域」）。
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
- 缺字段的旧档按当时的 `state.seed` 回填；缺 `save_revision` 或修订号**不是当前值**的档按迁移链口径处置：
  比当前早的三档修订号（`core/snapshot.gd::REINFORCEMENT_STATE_REVISION`／`core/snapshot.gd::CUP_STACK_REVISION`／
  `core/snapshot.gd::IRON_DRONE_REVISION`）由 `core/game.gd::restore_snapshot` 在 `Snapshot.check` 之前
  按迁移链升级（迁移判定旧档数据不完整时整档拒绝、保留当前游戏）；**更早、更新、缺 `save_revision`
  或非整数的一律拒绝，不作迁移**。同口径与迁移函数见 `docs/design/game-design.md` 存档节。
- `_scene_key` 不变；固定点身份与写入时机不受影响。
- 本节的字段与回填语义、`fixed_point_text` 的消费方（反馈附件）与玩家可见标识见
  `docs/spec/seed-identity.md` 与 `docs/spec/feedback-deployment.md`。

## 旧目录导入（一次性复制）

D23a 之后用户目录是固定名；旧版本各自带版本号的目录**仍在同一父目录下**。`ui/legacy_import.gd` 在首次
启动把它们复制一次进新目录，旧目录只读：**不删除、不改名、不覆盖任何字节**。

- 路径来源（`ui/legacy_import.gd::run_once`）：目标目录、标记与选源父目录一律从宿主注入的存档 store
  （`host.saves.directory`）推导——目标＝存档目录的上一级，标记在目标根下，父目录＝目标的上一级。生产中
  `host.saves` 是 `user://saves`，目标即用户目录、父目录即 `app_userdata`；测试 store 指向 `res://build/…`
  时，标记与复制都留在 build 下，不碰 `user://`。不另设第二套路径来源。
- 判定顺序（`ui/legacy_import.gd::_import`）：标记 → 目标非空 → 选源 → 复制。标记存在即短路；目标非空时
  不扫描父目录，只写标记；两者都不成立才扫描兄弟目录选源。
- 选源（`ui/legacy_import.gd::find_source`）：父目录下名字以 `紧缚尖塔demo v` 开头、且 `saves/` 里至少一份档
  （主档或 `.bak`）能通过 `core/save_store.gd::read_file` 读出的兄弟目录是候选；按**可读主档**
  （`tower.json`／`practice.json`）的修改时间取最新，`.bak` 不参与排序（只有 `.bak` 可读的候选排在所有
  有可读主档的候选之后）。与目录名里的版本号无关；`紧缚尖塔-dev` 与无关目录不参与。
  修改时间相同时依次比较：该主档读出的 `saved_at`、其 `snapshot.save_revision`，最后按目录名字典序
  **降序**兜底；排序值取自判定可读性的那一次读档，不再解包第二次，结果不依赖文件系统的目录枚举顺序。
- 复制面：`saves/tower.json`、`saves/tower.json.bak`、`saves/practice.json`、`saves/practice.json.bak`
  逐字节复制（`core/save_store.gd::adopt_legacy`）；`display-settings.cfg`、`key-bindings.cfg` 交给
  `ui/display_settings.gd::import_from` 与 `ui/key_bindings.gd::import_from`：读入属主 `save()` 写出的全部键
  （含 `display/mode`、`display/resolution`），按各自 `initialize()` 的取值域校验，不合法的值保持属主未读该键
  时的取值（新实例即默认值），再经各自的 `save()` 写自己的路径。坏档与新修订号档不落地，记入标记的
  `skipped`（键 `code`，值 `invalid`／`version`）。不复制 `feedback-draft.json` 等其他文件。
- 唯一原子写：`.tmp` → 回读 → 改名 全仓只有 `core/save_store.gd::commit_file` 一份。`write_game`
  （改名前把可读主档轮换进 `.bak`）、`adopt_legacy`（回读即 `read_file(temp).ok`）与迁移标记（逐字节回读）
  都经它提交。
- 写入失败可重试：任一存档提交失败（`skipped` 出现 `write`）时**不写终结标记**，结果 `ok=false`、
  `code=write`，下一次启动重试。终结标记只用于导入完成与校验类结论（`invalid`／`version`／
  `target_not_empty`／`none`）。
- 目标非空即不复制：`saves` 下已有任一位主档或 `.bak` 时不动任何文件，标记记 `target_not_empty`
  （父目录里有没有候选都一样）。中断的复制因此在下一次启动收敛到同一结果：`.tmp` 写完、改名之前退出时
  目标仍视为空，下一次启动重试并完成复制，`.tmp` 被提交的档替换；复制到一半退出时按 `target_not_empty`
  收敛，已落地的档不再重写。两个崩溃点的判据经 `core/save_store.gd::commit_file` 里的故障注入点
  （`debug_crash`，默认关闭，由 `OS.is_debug_build()` 守卫，发行包不可达）在真实提交序列中触发。
- 标记：目标根下 `legacy-import.json`，`schema=1`，含 `source`／`copied`／`skipped`／`at`；经
  `core/save_store.gd::commit_file` 原子提交，半写不会留下截断的标记。**标记存在即不再扫描、不再写**。
  只有 `ui/legacy_import.gd` 发起这次写入。
- 关闸与接线：`persistence_enabled=false` 或非桌面构建（`OS.has_feature("pc")` 为假）都不解析任何
  用户路径；接线只有 `ui/main.gd::_ready` 在 `_restore_startup()` 之前的一行。
- 生效时机：存档复制后由既有读档路径加载；键位在当次会话即生效（同一属主对象），显示设置（含窗口模式与
  分辨率）与语言在下一次启动由 `initialize()` 读入。

判据（全部走 `persistence` 与 `architecture` 两个规则套件；函数名即判据名）：

| 场景 | 判据 |
| --- | --- |
| LEGACY-1 最新旧目录 → 逐字节复制两个存档位、两个设置文件整份读回与源相等、标记 `schema=1` 逐项登记 | `legacy_source_is_the_newest_directory_with_a_readable_save` |
| LEGACY-2 选源按存档 mtime，不按目录名版本号 | `legacy_source_follows_save_mtime_not_version` |
| LEGACY-3 目标已有存档时不复制任何文件 | `legacy_never_imports_into_a_non_empty_target` |
| LEGACY-4 标记存在即短路，只导入一次 | `legacy_import_runs_only_once` |
| LEGACY-5 旧目录字节与 mtime 不变 | `legacy_leaves_every_legacy_byte_untouched` |
| LEGACY-6 坏档与新修订号档跳过并记 `invalid`／`version` | `legacy_skips_invalid_saves_and_keeps_the_rest` |
| LEGACY-7 关持久化或非桌面构建不导入 | `legacy_stays_off_without_persistence_or_desktop` |
| LEGACY-8 中断的复制下一次启动收敛 | `legacy_interrupted_copy_converges` |
| LEGACY-9 目录组合穷举（旧目录 {0,1,3} × 有无 `saves/` × 档状态 × 目标 {空,非空} × 标记 {有,无}）逐格合 §2.1，旧目录（相对路径, 大小, sha256）不变 | `legacy_directory_matrix_matches_the_plan` |
| LEGACY-10 注入点在 `.tmp` 写完、改名之前杀掉真实提交后，下一次启动收敛为完整复制 | `legacy_crash_after_temp_write_converges` |
| LEGACY-11 注入点在复制到一半（标记未写）时杀掉真实提交后，下一次启动收敛为 `target_not_empty`，不重写已落地档 | `legacy_crash_midway_before_marker_converges` |
| LEGACY-12 平手按 `saved_at` → `save_revision` → 目录名降序取契约指定的候选 | `legacy_source_tie_is_deterministic` |
| LEGACY-13 名字像 demo 但没有可读档的目录不是候选 | `legacy_source_ignores_directories_without_saves` |
| LEGACY-14 `紧缚尖塔-dev` 与新目录自身不参与选源 | `legacy_source_never_picks_dev_or_target_name` |
| LEGACY-15 非 ASCII 或多余空格的名字仍按前缀匹配（前缀内部多空格不匹配） | `legacy_source_accepts_non_ascii_and_spaced_names` |
| LEGACY-16 生产入口的目标、标记与父目录从注入的 store 推导，不碰真实 `user://` | `legacy_run_once_derives_paths_from_the_injected_store` |
| LEGACY-17 窗口模式与分辨率按 `initialize()` 的取值域导入，非法值保持默认 | `legacy_display_import_follows_initialize_domains` |
| LEGACY-18 写入失败不写终结标记，下一次启动重试并能完成 | `legacy_write_failure_keeps_the_import_retryable` |
| 旧路径只读、`legacy-import.json` 只被本模块命名、模块唯一的写是经 store 原子提交的标记 | `legacy_import_opens_legacy_read_only` |
| `user://saves` 单一写者（豁免处只碰自己的常量） | `saves_single_writer` |
| 接线恰一行且在 `_restore_startup()` 之前、闸先于路径解析 | `legacy_import_is_wired_once` |
| `.tmp` → 回读 → 改名 全仓唯一，`write_game` 与 `adopt_legacy` 都经 `commit_file` | `atomic_commit_is_single` |
| 崩溃注入点只在 debug 构建生效、只在 `_debug_crash_point` 里被读 | `commit_crash_injection_is_debug_only` |

LEGACY-1 至 LEGACY-18 在 `tests/persistence_cases.gd`，后五条在 `tests/architecture_cases.gd`。
LEGACY-1、LEGACY-2、LEGACY-3、LEGACY-4、LEGACY-9 至 LEGACY-18 与五条架构判据各配一条登记突变
（`tests/mutations.json`）。

## 输入域

三个固定点（写入内容一律＝写入时刻的 `restart_snapshot()` ＋当时线稿）：

| `checkpoint` 值 | 来源 kind（声明表） | 预期恢复点 |
| --- | --- | --- |
| `"floor"` | `floor_enter`（**目标层高于当前层**，只用于真实移动与换塔落点） | 该层入口（新层第一个房间的起点） |
| `"battle_end"` | `battle_end_victory`／`battle_end_saturated`／`battle_end_captured`（**收押含在内**） | 战斗结束后的阶段起点（奖励／事件结果／收押结果） |
| `"prepare_end"` | `prepare_end`（三条分支：`pack`／`map`／`cleared`） | 整备结束后的起点（下一步行动前） |

- **同类多条目按类别去重**：取值不由条目数决定。
- **同层移动（`room_enter`）不是固定点；换塔（`tower_restart`）不是固定点**（人审裁定）。
- `floor_enter` **只认上行**（「进入新的一层」＝目标层更深）。若将来希望「回到上层也算固定点」，
  须先改 `docs/spec/transition-pipeline.md` 的 kind 语义，再改本片的标记（属行为口径变更，须立批）。
- 非进度写盘（按显式意图／独立产物保留，不变）：

| 触发 | 入口 | 写什么 | 说明 |
| --- | --- | --- | --- |
| 地图线稿变更 | `graph.drawings_changed` → `_save_progress` | 当前 `restart_snapshot()` ＋最新线稿 | 玩家批注是独立产物；**不改变恢复点**（文件内容始终是「起点＋最新线稿」，因此画线也会刷新主档；若要求画线不触碰主档，须把线稿拆成独立文件，属新切片） |
| 新局替换不兼容档 | `_save_progress(true)` | 开局起点＋线稿 | 版本不兼容时开始新局的必经路径 |
| 手动「保存场景起点」 | 主菜单按钮 | 当前 `restart_snapshot()`＋线稿 | 显式用户意图；**无去重机制**，点击即写 |

- 删除恢复后那次写盘后，读档时被 `restore_snapshot` 抬升过的 `version` 不再立即写回文件；
  该字段只是乐观并发计数，存档内容不受影响，最新内容在下一次固定点写入时落盘。

## 失败语义

- 存档文件读写不设置字节数上限；超过原8 MiB的主档和备份均走相同格式、校验和、状态验证及回退流程。
  底层文件读写失败仍正常报告。
- **须保留，不得弱化**：失败路径与全部文案（`"保存失败：…原存档保留。"`／
  `"保存已暂停：原存档版本不兼容…"`／slot 非法／回读校验失败）；`pack()`／`unpack()`
  的格式与校验；`restart_snapshot()` 的冻结时机；`read_slot` 的回退规则与 `summary()` 的语义；
  `.bak` 顺序；任一失败不得被放行、不得为绿灯改文案。
- 语义归属：`checkpoint` 的推导只回答「这次提交是不是固定点、是哪一类」；
  「恰一条 `battle_end_*`」这类**语义**由闭环 check 与具名场景承接，
  **不得依赖 oracle 对迁移日志列的折叠边界**；`checkpoint` 推导不得读历史条目或跨提交累积。

## 证据入口

- 具名 check（全部走真实公开命令：发指令 → `dispatch`；计数只用测试侧 `SaveStore` 子类包装，
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

  判据：退出码 0；`summary.json` 的 `status=passed` 且 `before==after` 指纹（`source_changed` 不算通过）；
  `content/packs` 未改动，不跑 `check-content.ps1`。
- 依赖约束（cleaner 可核对）：允许改动＝`core/game.gd`（声明表 `checkpoint` 标记、`dispatch` 结果的
  `checkpoint` 键与其推导）、`ui/main.gd`（删除恢复后写盘点；`_submit` 只在 `checkpoint` 非空时写盘）、
  `tests/persistence_cases.gd`／`tests/persistence_ui_cases.gd`／`tests/architecture_cases.gd`。
  依赖方向＝`ui/main.gd → core/{Game,SaveStore}`（既有边）；`core/game.gd` 内部改一处推导。
- 本片之后的现行改动清单（`fixed_point_text`、`state.initial_seed` 与 `restore_snapshot` 回填、
  只读投影与地图角标）见 `docs/spec/seed-feedback-dependencies.md`；登记位置
  `build/checks/<id>/`（`check-rules.log`／`check-ui.log`／`summary.json`），结论与域写
  `docs/record/verification.md`（validator 负责，不在本文件宣称通过）。
