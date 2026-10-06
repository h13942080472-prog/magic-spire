# 玩家可见文案：路由收口与按需投影契约

本文件是现行契约，分两阶段，**顺序即裁定**：先把不同功能的文案收口到同一处路由（类别 + 参数），
再做按需投影（View 只带界面固有集合，其余在真正显示时才经路由取）。
供实现者、清洗者、加固者、验收者只读消费：内部实现以代码为准，接口语义以本文件为准。
本文件不写执行结果；通过／失败／未执行只登记在验证记录（`docs/record/verification.md`）。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 一次 `get_view()` 里为**玩家看得见的文字**所做的投影（卡面文案、候选详情），
  以及 UI 在真正显示时才取用这些文字的只读路径。
- 不含：规则判定、随机、存档与快照、候选资格与候选 ID、`dispatch` 语义、事务与回合。
- 与另两份契约的分工：`docs/spec/response-pipeline.md`（UI 输入 → 提交 → 落地）不动 `_submit`／`commit`／
  `present`／`render`、节键与候选资格；`docs/spec/equipment-query-seam.md` 拥有装备只读查询与 `escape_preview`
  （其按需化判归装备片后续批次、**未排期**，本片不得实现）。本片不改 UI 响应路径与节键。

## 接口

### 唯一生成函数（三路共用）

- `core/card_effects.gd` 的 `static func text_entry(g, type: String, uid: String = "") -> Dictionary`：
  条目正文 = 四步 `face_texts` → `face_costs` → `merge(metadata)` → 可能的 `casting`。
- 实时条目的 `face_damage` 为 `bound/free` 两面的逐段伤害数值数组，无伤害面为空；与卡面正文共用 `Cards.face_damage_values`，具体加成与波及读取规则见 [卡牌设计](../design/cards.md#9-图鉴与卡面投影)。该字段只读，不写入牌实例或存档。
- 判据（结果面）＝`tests/architecture_cases.gd::copy_single_entry_matches_projection` 与
  `tests/card_text_cases.gd::copy_fixed_set_matches_full_entry`：下面三条路径的返回逐字段相等。

### 只读入口

| 接口 | 输入 | 返回 | 谁能调 |
| --- | --- | --- | --- |
| `get_view().card_texts` | — | 界面固有显示集合 **S** 的条目（纯数据，可逐字段比对） | 全部只读消费方 |
| `get_view().card_instances` | — | `state.hand` 中命中既有判据（`damage_growth`／`hannya_stage`）的 uid 条目 | 同上 |
| `Game.live_card_text(type, uid="")` | 任意注册牌型（含 `encyclopedia_hidden`） | 全新 Dictionary，与 S 同键条目逐字段相等 | UI 显示边界、测试 |
| `Game.live_card_text_set(cards)` | `cards=[{"type":String,"uid":String}]`（uid 可缺省） | 全新 `{"texts":{type:entry},"instances":{uid:entry}}` | 牌堆浏览、商店去卡、测试 |
| `Game.candidate_detail(candidate)` | 当前 View 的候选 | String；card 组现算，非 card 组逐字节等于 `candidate.detail` | UI 显示边界、测试 |

- 共同语义：只读（不写 `state`、不推进随机、不改 `state.version`、不产日志与事件、不进存档与快照）；
  每次调用返回**新容器**，调用方可以改写返回值且不影响 View 与后续调用；判定按字段比对，不按 JSON 字符串顺序。
- 陈旧输入：`candidate_detail` 只对「当前 View 的候选」承诺与投影一致；对陈旧候选（此前一次渲染留下的
  显示事实）允许按当前 state 重算，显示点按其记录，不承诺与旧投影相同。
- `deck_list` 已移出 View（全仓无 UI 读取点）；同值数据由 `live_card_text_set` 提供。
  `card_texts`／`card_instances` 除键集合收窄外，条目内容与键序不变。

### 按需的候选详情

- 组范围**只做 card 目标候选组**（`payload.kind=="card"`：自由面／冲开捕缚／多段目标，由
  `core/card_effects.gd` 的 card 目标事实构造产出）：该组候选字典**不再带 `detail` 键**，显示时经
  `Game.candidate_detail` 现算；其余组（组名＝`view.display_facts` 的 `group` 字段）保持预生成 `detail`。
- 写路径不读 detail（`dispatch` 只用 `payload`／`cost`／`mana_payment`／`valid`／`reason`）；
  显示点身份＝`core/game.gd::shape_key(payload)`（kind＋params）；detail 的组装抽成
  `core/game.gd::_candidate_detail`，eager 路径（`core/game.gd::_fact_core`）与新入口
  （`core/game.gd::candidate_detail`）共用。
- 不得改 detail 的文案与可见性规则（含短原因映射与行动行的显示条件）。

### 文案路由（收口阶段）

- 生产者侧：事实构造 `core/game.gd::_fact(payload, label, copy, cost, mana, reason, risk, group)` 的 `copy`
  既可以是今天的 `String`（**直传通道**，行为与今天逐字节相同），也可以是 descriptor
  `{"kind":String,"args":Dictionary,"fallback":String}`；转发包装 `core/prison.gd::add`、
  `core/room_services.gd::paid_fact` 与 `core/card_effects.gd` 内的 card 目标事实构造同样接受 String 或 descriptor。
- 路由侧（`core/copy_router.gd`，全 static）：
  - `text(g, copy) -> String`：`copy` 是 String → 原样返回；是 descriptor → 按 `kind` 分派到注册的 builder；
  - `categories() -> Array[String]`：可枚举的类别清单（测试与接手方据此核对覆盖）；
  - builder 由模块自带并在路由注册（**不要求把中文搬到路由文件**）；
  - 共享片段只放实测确认的横切流程，当前只有 `two_face(type)`（两面拼接）。
- 消费者侧：UI 不直连路由、不 preload `core/copy_router.gd`；只经上面的 `Game` 只读入口，再由显示侧 helper 取用。

### 显示侧取用 helper

- 取用点唯一 helper（都在 `ui/main.gd`）：
  - `card_entry(type, uid="") -> Dictionary`：命中 `view.card_texts`／`view.card_instances` 即用；
    未命中 → `game.live_card_text(type,uid)` 并追加 `ui.projection_misses` 记录；`ui/main.gd::card_face_name`
    是它的具名薄包装；
  - `detail_of(candidate) -> String`：`candidate.detail` 存在即用；缺失 → `game.candidate_detail(candidate)` 并记录。
- 卡面投影的直读点（与当前代码一致；改实现须同步本条）：`view.card_texts`／`view.card_instances` 在 UI 内
  只由 `ui/main.gd::card_entry` 与 `ui/main.gd::_card`（`live_state` 卡面的唯一合并点）直读；其余界面取卡面
  文案经 helper 或 `ui/main.gd::_display_card`。
- 候选详情的直读点：card 组候选（`payload.kind=="card"`）字典不带 `detail`，只能经 `ui/main.gd::detail_of`
  → `Game.candidate_detail`；其余组（event／item 等）保持预生成 `detail`，允许的直读点＝
  `ui/event_screen.gd`（`selector_button`／`action`／`drawer`）与 `ui/main.gd::_drawer_presentation_key`
  （item 组节键）。不得对缺 `detail` 的候选写 `c.get("brief", c.detail…)` 这种**预求值**写法
  （GDScript 会先算默认参数，缺键即崩）。
- 消费面判据＝`tests/architecture_cases.gd::ondemand_copy_consumer_boundary`：UI 不引用 `core/copy_router`；
  `candidate_detail` 只由 `ui/main.gd::detail_of` 消费，`live_card_text_set` 只由牌堆浏览与商店去卡消费，
  `live_card_text` 只由 `ui/main.gd::card_entry` 消费；`card_texts`／`card_instances` 的直读点白名单为上面两处。
  语义条目（S 取源、或然失败、复用准入线）仍为本文件真源。

## 输入域

### S（界面固有显示集合）的取源

S 按下列显示入口**逐条取源再取并集**；只允许用本次 View 已经算出的数据正向投影，
**不得为收集 S 新增规则查询**，也不得给 `get_view` 加「显示需求」参数：

| 来源 | 取值 |
| --- | --- |
| 手牌 | `state.hand` 每张牌的 `type`（uid 变体走 `card_instances`） |
| 保留行 | 同手牌 |
| 奖励三选一 | `state.reward_options` |
| 休息选牌 | `state.rest_cards` |
| 出发选牌 | departure 面板条目 `type`／候选 `payload.type` |
| 事件卡选项 | `view.room_event` 卡牌选择项的 `type`（候选 `payload.type` 为兜底） |
| **商店买卡** | `view.shop.stock` 中 `kind=="card"` 行的 `type` |
| 其余会显示卡面的候选 | 候选 `payload.type`：`payload.has("type")` 且值 ∈ `Cards.Rules.SPECS`，非卡牌（attack／item／relic／tool）被注册表过滤 |

- **反例（必须写进实现）**：商店买卡的候选 payload 只有 `{"kind":"service","op":"take","index":…}`，
  **没有 `type`**；只扫候选 payload 会漏掉这个牌型，表现为商店卡面缺失（缺失而非降级）。
- 不计入 S、走全量入口：抽／弃／牌堆整摞、能力区、牌堆浏览、商店去卡；图鉴不进 S（保持 `live_state=false`）。
- 幽灵卡（打出）不在 S（投影期不可知），现场补算并留记录。
- 新增显示入口时必须同步补 S 的推导；判据是 `ui.projection_misses` 为空。例外只有打出的幽灵卡（投影期不可知，现场补算并记录）。

### descriptor 与类别

- descriptor 用「类别（kind）+ 参数（args）」，由路由按 kind 分派渲染；**不选「模板 id + 参数」**：
  做模板库等于把作者写好的整句重写成模板，且最容易破坏逐字节判据。
- 明令禁止：不得为了「统一」把整段中文搬进中央模板库，也不得借机改动既有措辞。
- 两份卡面组装与费用双源**不合并**：静态 `Catalog.card`（`Rules.energy_label` + `B.card_metadata`）与
  实时 `Cards.text_entry`（`Cards.energy_label` + `Cards.metadata`）继续并存；允许且仅允许的收口是
  实时路径集中到 `text_entry` 并登记为路由类别（`kind="card.face"` 实时、`kind="card.catalog"` 静态）——
  **入口一处可见，实现仍是两份**。图鉴的 `live_state=false` 与既有反向断言原样保留。

### 复用准入线（现行结论）

- **复用必须附可证失效规则；无证明即禁止。** 这条适用于跨提交／跨调用保留投影内容、增量更新与惰性求值：
  任何复用都要给出可验证的失效条件与检查；给不出即不得实现。
- 现行明确保留的做法：core 只读调用内的装备显示行复用与 `face_texts` 合批；UI 跨操作持有的 `ui.view`
  与其显示态（属投影，不是核心缓存）。
- 现行明确禁止：用 `version` 当缓存键或失效键；用译文、颜色、名称、图片识别玩法对象；
  把 `version` 当渲染内容新旧的判据。
- 不得新增没有可证失效规则的常驻缓存；不得让 View 变成不可逐字段比对的对象（不出现惰性对象、函数值或引用外部状态的占位）；
  不得给 `get_view` 加显示需求参数。

## 失败语义

- **三态必须区分，不得混同**：
  1. 直传通道（String）→ 原样返回，行为与今天一致；
  2. descriptor 命中 builder → 返回该 builder 的字符串；
  3. **未知 kind／无效 builder／结果类型不符** → 追加一条 `copy_router_failures` 记录
     （游戏实例上的独立诊断列表：含 kind、入口、失败点与涉事 descriptor；**不进 `state`／不进 View／
     不进存档／不渲染／不做成计数器**），返回 descriptor 自带的 `fallback`（迁移期生产者必须提供）；
     没有 `fallback` 时返回空值**并记录**，绝不允许「空白且无记录」。
- **语言限制（按 GDScript 事实写，勿写成「捕获异常」）**：GDScript 无异常捕获，builder 内部的引擎错误会
  中断调用栈，无法实现「捕获 builder 抛错」。第三态只覆盖**可判定的失败**；真正的引擎错误由测试套件
  当作失败处理，不再是静默空值。该措辞与 `core/copy_router.gd` 头部注释保持一致。
- **缺失即补算并留记录**：显示点只能经 helper 取用；未命中时补算并记录，**不报错、不空白**。
  禁止静默空白、静默回落到目录基础文本、用 helper 存没有可证失效规则的第二份跨调用缓存。
- 记录：`ui.projection_misses`，元素 `{"point":String,"key":String,"view_version":int}`；每
  (point,key,view_version) 至多一条；**清空时机是「`ui.view` 被替换」**，不是「version 数字变化」；
  `view_version` 只是诊断标签，不得当缓存键或失效键，也不得据它判定渲染内容的新旧；
  不渲染、不进日志／存档／快照、不做成计数器。允许的「没省到」：打出的幽灵卡（该 type 投影时不保证在 S 内）。
- 算未完成（任一）：出现未附可证失效规则的复用（含 UI 侧第二份文案副本、惰性对象）、
  给 `get_view` 加显示需求参数；显示点绕过 helper 直读投影字段；缺失时静默空白或静默回落目录基础文本；
  改判定／随机／存档／快照／候选资格／候选 ID／可见文案；实现 `escape_preview` 按需化或改 UI 响应路径与节键；
  以耗时数字或「应该更快」作完成判据；把既有断言删掉或弱化换取绿灯。

## 证据入口

### oracle 三条（必须换判据）

按需落地后，旧「整份 View 哈希相等」不再是判据，改判：

1. **按需 == 全量**：对全部注册牌型 `type`：`live_card_text(type)` 与 `live_card_text_set([{type}]).texts[type]`
   逐字段相等；`type ∈ S` 时还必须与 `view.card_texts[type]` 逐字段相等。
   **实例字段是包含关系，不是相等关系**：`view.card_instances[uid]` 的每个字段与 `live_card_text(type,uid)`
   的同名字段逐项相等，键集合之差只允许 `face_costs`（恒有）与 `casting`（仅施法牌）两个新增键；
   不得要求整字典相等，也不为补齐这两键去做无收益的改动。
   候选：非 card 组 `candidate_detail(c)` 逐字节等于 `candidate.detail`；card 组现算且非空
   （判据＝`tests/architecture_cases.gd::copy_candidate_detail_on_demand`）。
2. **端到端不缺失**：对每个可见显示点，在真实夹具下渲染文本正确，且 `ui.projection_misses` 为空；
   人为删除投影键（`card_texts` 键或 card 组候选的 `detail`）时仍不崩、不空白并留具名记录
   （判据＝`copy_missing_key_never_crashes`，`display`／`targeting` 两处）。
   覆盖路径至少：手牌卡面、保留行、奖励三选一、休息选牌、事件卡选项、出发选牌、拖放落点提示（含右键切换提示）、
   身体详情里的选中卡详情与行动行、牌堆浏览、商店去卡。
3. **被显示子集（mask 定义）**：只按**显式声明集合**判定，不按「新视图有什么就比什么」：
   `card_texts` 恰为 S（∈ S 的一个不少、∉ S 的一个不多），键序按注册表序，条目与单条入口
   （`live_card_text`）逐字段相等；`card_instances` 只含手牌 uid；card 组候选不带 `detail`；`deck_list` 整键不在 View。
   判据＝`tests/architecture_cases.gd::copy_projection_masked_baseline`：S 由 `copy_display_set` 按显示入口
   独立重算（不读 `View.build`），声明集合打印在日志里。

### 具名 check 与命令

不新建流程文件、不新建看板；用具名函数加入既有 case 文件，复用现有夹具与真实输入助手：

0. `copy_missing_key_never_crashes`（`display`、`targeting`）：缺键夹具渲染不崩、文本不变、有具名记录；
   完整投影下 `ui.projection_misses` 为空。
1. `copy_fixed_set_matches_full_entry`（`card_power`，经 `tests/card_text_cases.gd`）：三路逐字段相等；
   ∈ S 的 type 在场、∉ S 的不在；状态、随机、version 不变。
2. `copy_projection_masked_baseline`（`architecture`）：见「oracle 三条」判据 3。
3. `copy_single_entry_matches_projection`（`architecture`）：`live_card_text`／`live_card_text_set` 与投影
   三路逐字段相等；实例字段是包含关系（只允许新增 `face_costs`／`casting`）；返回全新容器；不写 state 与 version。
4. `copy_candidate_detail_on_demand`（`architecture` + `targeting`）：逐候选逐字节相等；card 组候选字典无
   `detail` 键且现算非空；其余组等于预生成 `detail`；写路径未受影响（真实提交一次）。
5. `copy_route_bytes_unchanged`（`architecture`，收口批判据）＋ `copy_migrated_kinds`／`copy_r4_sites`／`copy_r6_sites`：
   每个候选的三条路（生产者字符串、descriptor 经 `core/copy_router.gd` 渲染、`candidate_detail`）逐字节相等；
   `copy_router.categories()` 覆盖已注册类别且无未知 kind；未迁移生产者走直传通道行为不变；
   `copy_router_failures` 为空。红时按四类归因：文本内容／候选数量顺序／缺 detail／未知 kind。
   新增类别时同步注册类别断言，并在 `copy_migrated_kinds` 验证真实候选站点；用不同于正常文案的哨兵回退值，避免漏注册时返回原文而掩盖失败。商店购买、刷新、解除与删牌均走这条证据路径。

```powershell
& tools/check.ps1 -Suite card_power,architecture,casting,card_growth -Impact -TimeoutSeconds 900
& tools/check.ps1 -UI -Suite architecture -UISuite display,targeting,keyboard,interface,card_power,card_growth,shoulder,torso_binding -TimeoutSeconds 900
```

- 判读：退出码 0；输出含 `RULE SCOPE:`、每个 `SUITE RESULT: <name> PASS`、`PASS: N assertions`；
  `summary.json` 的 `status=passed` 且 `before==after` 指纹（`source_changed`／`plan` 不算通过）。
- 范围内出现失败时，记录实际失败分类、断言及日志 id，整轮仍为失败；可分别列明本片已通过的判据和尚未解决的问题，不沿用历史失败名单作为豁免。修复后按受影响范围重新取证，不删除有效失败断言或缩小范围换取绿灯。
- 被触及的既有断言（`tests/card_text_cases.gd` 全类型读取、`tests/casting_cases.gd`、
  `tests/hannya_ui_cases.gd`、`tests/card_power_ui_cases.gd`、`tests/encyclopedia_ui_cases.gd`、
  `tests/concentration_cases.gd`、`tests/graduate_certificate_cases.gd` 及 tests 中全部 `.detail` 读取）
  按新入口 1:1 迁移后仍通过，期望值与断言语义不变。
- 人的路径证明（判据是套件布尔 check）：战斗中打出／翻面手牌、卡组一览、商店去卡、拖牌到身体与键盘悬浮、
  奖励三选一／休息选牌／事件卡选项／出发选牌、商店买卡（S 的已知回归点）、图鉴不产生 `projection_misses`、
  人为缺键不报错不空白。
- 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`；入库的只有验证摘要。
