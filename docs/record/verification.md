# 验证记录（现行卷 · 2026-09-14 及以后）

## 2026-09-21 图鉴原图检视

- 域：`Encyclopedia._card_family/_inspect_card`、`ArtInspection`、`Main.modal_region/_input/_notification`、中英文按钮。复用当前卡面原始纹理、现有模态及触屏输入，不另行解析画风或正反面。
- 首轮 `20260921T052056596-38184`：localization 167断言通过，UI测试误用了MainLoop上的安卓通知常量；改为Node。`20260921T052140692-28592` 暴露图鉴退出回调捕获已释放节点，改WeakRef；同时将背景快捷键测试从会激活焦点按钮的Space改为攻击键Z。原失败未删除，均不作整轮通过结论。
- `20260921T052232688-4508` UI231断言通过后，按用户最新要求去掉关闭键，补暗部触摸返回；独立审查指出1:1需包含窗口变换、同帧重开需同步释放节点名，已改用完整屏幕变换及同步remove_child，并增加对应断言。
- 阶段验证 `20260921T052448050-20764`：encyclopedia UI235断言通过，包含卡面点击、正反面原纹理、居中全图、1:1及1280×720窗口像素尺寸、测试画风、暗部／Esc／安卓返回及同帧重开。独立复审随后指出真实图鉴退出时同步remove_child可能重入父移除，原模拟退出信号测试未覆盖此路径。
- 最终 `20260921T052725152-18272`：改为隐藏并释放活动节点名后queue_free，以真实关闭图鉴替代模拟退出，再补1:1内部暗部触摸；encyclopedia UI237断言通过，exit=0、status=passed、源码指纹一致。已人工检查 `build/ui-card-art-inspection.png`。Peirce独立只读复审确认此前问题修复，无阻塞项；未做安卓真机或1:1拖动滚动专项验收。
- 源码差异检查通过；既有本地化验证后未再更改语言资源。未完整回归、打包或发布。

## 2026-09-21 施法失败提示文案

- `Main._card_tooltip` 与 `Game._cast_path` 的文案后缀精简，结算不变；旧长句及闲置后缀译文清除，短句英文已同步。
- `20260920T162124914-38800`：`localization` 167断言、`casting` UI 59断言通过；exit=0、status=passed、源码指纹一致。差异检查通过，Lorentz独立只读审查无问题。未打包或发布。

## 2026-09-20 商店刷新

- 域：`Services.start/_restock/candidates/execute/validate`、`Data.refresh_price`、初始累计字段、文案路由、商店刷新按钮与中英文。
- `20260920T050422606-4252`：`localization,services` 808规则断言通过；UI因新按钮误按行动种类查找候选，实际接口要求分组，出现脚本错误及21条连带失败。已改为按 `service_refresh` 分组查询，不删除既有失败覆盖；该轮不算整轮通过。
- `20260920T050510479-4160`：仅续跑失败的 `services` UI，289断言通过（含截图保存），exit=0、status=passed、前后源码指纹一致。规则侧通过后只改UI查询入口，原规则验证仍对应其实现。
- 覆盖50／100／200／400费用、两种付款、余额不足和旧版本提交不改资源与随机、会员卡折扣、平板锁付款限制、刷新补满已售位且不恢复删牌服务、读档后下一次库存一致、换店／Boss续轮／出狱保留价格，新局归零。UI实际点击刷新、自身不足切魔瓶、更新商品和费用、英文切换只读；已人工检查 `build/ui-shop-refresh.png` 的立绘右上按钮位置。
- 差异检查通过；未做完整回归、安卓真机、打包或发布。
- Boyle独立只读审查交易、价格、随机、存档与界面候选接口，通过且无待修问题；未另改代码或扩大测试。

## 2026-09-20 牢房探索魔瓶单次存入

- 域：`ManaFlask.limit/remaining/candidates/execute/view`、存入／取出独立次数展示、既有回合重置与存档恢复接口。
- `20260920T045425107-42156`：`consumables` 315规则断言、同名UI分类60断言通过；exit=0、status=passed，前后源码指纹一致。覆盖第二次存入原子拒绝、少于10点仍消耗次数、存档恢复不能刷新、真实回合刷新、巡视不限、反抗战斗各3次、胜利后整备不限与返回牢房重新限1次。
- UI以实际按钮完成牢房存入，验证单圆点消耗、禁用原因、取出仍可用，以及结束回合恢复。保留原战斗三次与非战斗不限次数用例；差异检查通过。此次不是完整监狱回归，也未进行打包、发布或安卓真机验证。
- Noether独立只读审查上述接口与用例，无阻断项；未修改代码或扩大到其他在途任务。

## 2026-09-20 反抗狱警失败后的警戒度核对

- 只读核对：`Guard.capture` 仅在战斗相位执行，收押时警戒度＋1并封顶5；`Prison.enter` 不再增加警戒度。已有 `prison_cases` 包含反抗失败后警戒度由1到2、再次入牢重建牌堆的断言。本次不修改规则。
- 专项 `20260920T044152453-7896` 未通过：1/1238断言失败、10引擎错误，包含在途 `_build_escape_preview` 覆写签名不匹配、依赖脚本编译错误和 `CUP PRISON legacy pair` 断言失败。保留其他任务修改，不将局部断言或静态核对宣称为通过的监狱回归。

## 2026-09-20 欲望魔方Boss奖励与小魔女淫魔法适配

- 域：Boss／开局随机遗物资格、显式拾取来源、主题遗物／稀有卡筛选、永久发牌与共用入手牌通道、小魔女七张独立卡及精神集中、中文／英文、奖励到整备。
- `20260920T042224286-37456`：`witch_character` 652、`card_expansion` 1648、`architecture` 506、`tower` 319断言通过；`relics` 两条快照断言失败。定位为新测试夹具把浮点快感赋值为整型0，复用已恢复实例时触发数值类型校验；改为0.0，保留领取／存档断言。该轮不作整轮通过结论。
- `20260920T042654100-41384`：`relics` 1914断言通过；新增英文句子的格式参数误用 `%s` 导致兼容目录加载失败和41个连带失败，已按既有规范改为 `{p0}`。独立审查同时发现奖励到整备会弃掉赠牌，已用既有 `retain_until` 保留到首个整备回合，永久副本保持普通状态。
- 最终 `20260920T042805477-13296`：`localization,relics,core` 共2511规则断言、`home` UI 140断言通过，exit=0、status=passed、前后源码指纹一致。UI双角色均以真实点击领取Boss魔方，再离开奖励进入整备，核对心痒难耐同一UID仍可使用。源码差异检查通过。
- 新用例覆盖固定兑换无赠品、随机Boss交换有赠品、角色适配后限定卡池、专用遗物耗尽滚木兜底、满手转弃牌、原基础牌保留、陈旧／重复领取不变更状态与随机、实际精神集中层数与爱欲魔纹30点阈值、原版蓄力定义不变。Goodall独立只读审查最终修复无阻断项；审查侧旧UI的source_changed结果不计入通过证据。
- 本次8条相关英文定向同步手工目录与兼容目录，既有译文保留；全目录离线生成的无关缓存缺口未处理。未做完整回归、安卓真机、打包或发布。

## 2026-09-20 连续踢：X支付、多段伤害与攻击后躺下

- 域：`BasicAttacks.forms/energy_cost/posture`、`Game._attack_offer/_execute_attack`、腿部动作切换与拖放、战神形态、体术减费、中文／英文。
- `20260920T040910113-2188`：`localization` 165、`basic_attacks` 223断言通过。`card_expansion` 首轮3个失败，来自既有减费测试将所有腿部招式预设为站姿固定费；更新该用例走正式坐下操作，分别断言固定费减费和X耗尽支付，未删除失败覆盖。
- `20260920T041013513-41584`：正式 `-RerunFailed`，`card_expansion` 1618断言、UI `basic_attacks` 259断言通过，exit=0、status=passed、前后源码指纹一致。UI经真实右键循环至连续踢，再拖至敌人，核对能量归零、四次伤害及躺姿，以及零能量红字拒绝。
- `20260920T041044599-39960`：`architecture` 506断言通过，exit=0、status=passed、前后源码指纹一致。
- 新规则用例覆盖X=0／1／2／3／5、逐击日志顺序、力量与蓄力、腿部严密度0—4、提前击杀不转移目标、固定姿势捕缚、姿势豁免、旧版本拒绝及只读预览。独立子代理Raman只读审查未发现明确问题。
- 英文完整目录生成因94条无关源文缺少离线缓存／依赖未完成；本次五句人工译文已定向同步兼容目录，既有译文保留，localization门禁通过。未做全项目回归、安卓真机验收、打包或发布。

> 路径说明：本卷正文保留撰写当时的文件路径（旧 `docs/<名>.md` 现按类归入 `docs/spec|design|guide|record|history/`）；需要定位时按文件名搜索。


- 性质：记录类，只追加；本卷即现行口径。归档卷：`verification-2026-09-13.md`（2026-09-11～09-13，190 条）、
  `verification-2026-09-12-and-earlier.md`（2026-09-07～09-10，203 条）。
- 本卷内容：84 条条目 + 卷首 3 个现行口径节。条目 = 原文 2026-09-17～14 标题条目 79 条
  + 原文缺标题的 09-17 条目 2 条（标题按正文重建，正文逐字保留）+ 作者侧 `origin/main`（v0.17.1 提交）新增 3 条。
- 现行口径节：`检查入口`／`覆盖范围`／`当前边界` 是无日期小节，属检查入口、覆盖范围与边界的现行说明，
  不随归档卷迁出；`覆盖范围` 正文含 2026-09-06 的存档批次结果，同样留在本卷。
- 条目格式：`## <日期> <标题>（角色）`。标题与正文逐字保留（仅把标题内的日期统一到标题前）；
  角色沿用原文署名，原文未署角色者不补。「域」行原文已有者保留，缺者按正文中的代码路径、
  契约文档名与主题词机械提取（无路径者为主题词归类），不新增正文事实。
- 口径与指针（不改写原文）：B3 条目存在「本批未完成 → 仍未完成 → B3 完成」更正链，三条原文均保留；
  `2026-09-17 状态迁移管线收束` 内的「截断／补跑」口径已由正文 superseded 标记指向检查路由契约；
  「提交面去重」方向经人裁定不实施，契约在 `docs/history/submit-dedup-2026-09-17.md`；
  作者侧 `修复18条基线失败` 与原文登记的既有红项并存，两侧原文均保留。
- 链接对应：作者侧条目正文中的 `pr2-integration-review.md` 即 `docs/history/pr2-integration-review-2026-09-17.md`；
  正文中的 `verification.md` 自指即本文件。
- 规范类结论（规则、接口与检查口径的可执行定义）以 `docs/spec/*` 为准，本卷只记录与链接，不复制规范正文。

## 检查入口

**现行口径**（非历史条目）。

- 规则：`Godot --headless --path . --script res://tests/test_game.gd`
- 界面与完整流程：`Godot --path . --script res://tests/ui_smoke.gd`
- Windows：`tools/check.ps1`，加 `-UI` 包含窗口内操作与截图。
- 窗口专项：`tools/check.ps1 -UIOnly -UISuite rewards`；可选equipment_complete、pressure、guard、prison、tower_progression、events、rewards，并可逗号组合。从同一窗口入口运行既有模块、每项先重置、按注册顺序去重；默认all保留原完整流程，未知套件拒绝。不复制测试，不把部分专项统计成完整窗口结果。
- 相关规则：`tools/check.ps1 -Suite equipment_complete`，按统一注册表补齐core/equipment/links/composites依赖、去重运行。可逗号指定多个套件，默认all；每套件记录耗时。规则通过后的纯显示修改用同一入口的`-UIOnly`，保持错误日志与完成标记检查。

## 覆盖范围

**现行口径**（非历史条目）。

2026-09-06存档批次最终结果：`tools/check.ps1 -Suite persistence -UI -UISuite persistence`通过2285项规则断言、33项存档窗口专项，无引擎错误。14个规则套件按依赖去重运行，其中persistence293，其余继承rewards及传递依赖1991项，另有选择断言1项。此前本批完整窗口`-UIOnly`通过552项断言；最后补充运行期间不兼容文件保护后，重跑完整关联规则及存档窗口专项，不把专项计作新的完整窗口结果。

存档案例覆盖全部33项实际练习与64位大种子；保存→恢复→正式下一步和不中断运行逐项对照，资源、随机、牌堆与日志均不变化，只有操作版本刷新。覆盖战斗、奖励、整备、地图、行进、休息、整理道具、事件选择/钥匙/结果、多段挣扎与双重开锁中途、已保留一张牌、待发放遗物、过载、入狱结果、牢房、巡视到达/结果/完成、反抗战斗、五级结束与练习完成。练习实际开门逃回塔底后存档身份仍为practice，写入不覆盖tower。

失败案例检查缺字段、未知阶段/卡牌、牌堆不一致、损坏随机/意图/地图引用、重复编号风险、非有限数、错误格式、损坏JSON和校验和；失败恢复保留当前状态。真实文件案例检查首次保存、连续替换、上次备份、主文件损坏回退、后续修复、不同档位隔离、文件夹不可写时保留原文件；不兼容主文件不自动回退，也不能在游戏运行期间被普通自动保存覆盖，只有明确新局可以替换。

初次完整对照发现文本浮点往返与Godot StringName转普通字符串导致差异。当前整数使用十进制类型标记、浮点保存原始64位、StringName保留名称类型；全部真实装备/事件往返及后续动作对照已通过，没有用近似比较掩盖状态差异。恢复不运行状态清理、回合开始或随机生成，无法继续的损坏多段选择被拒绝。

窗口专项实际启动新场景读取自动保存，验证成功操作写入而翻面/查看/旧版本拒绝不写；塔路/练习按钮、缺档禁用原因、练习分档、多段拖牌恢复不重复扣费、事件隐藏结果保留与结算后不能重选、备份回退提示、未知版本暂停自动保存、明确重开后恢复写入。截图`ui-56-save-menu.png`、`ui-57-resumed-card.png`、`ui-58-save-recovery.png`、`ui-59-save-incompatible.png`已查看，界面内容在视口内。测试在独立build临时目录执行，基础窗口挂载前禁用文件保存，未访问玩家存档。

架构：Game继续持有唯一游戏状态，snapshot只作结构保护、复用现有注册表及规则校验；save_store统一无损编码、格式和文件替换。UI仅在已有成功提交入口调用保存，读档清理界面焦点并派发完整恢复。状态新增save_slot用于固定开局归属，不根据逃狱后的practice标志猜测档位。未来已有字段含义变化需显式迁移/版本升级；本批是首个格式，无历史版本迁移承诺。

2026-09-06首批奖励补全：规则入口`tools/check.ps1 -Suite rewards -UI`通过1992项断言，包含全部13个相关套件且各执行一次：rewards162、events204、core301、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184、tower_progression145，另有选择断言1项。同轮完整窗口通过520项断言，无引擎错误。随后仅修订第二段开锁说明，完整窗口复查因最小化暂停并打断鼠标拖放，该轮明确作废；恢复干净窗口后最终执行`tools/check.ps1 -UIOnly -UISuite equipment_complete,pressure,rewards`，34项装备、28项压力、27项奖励共89项窗口专项全部通过，无引擎错误，模块耗时合计约11秒。规则行为未因这次显示与检查入口修订改变。

本批完成找准松处、扯开缺口、接连挣动、逐层抽离、双重解锁，以及断缚护腕、游丝指环、回身缎带、余烬晶石。规则覆盖32种子随机奖励无重复/可复现/独立域、8张牌全部可抽取、只读预览；五种自由效果的费用与魔法身体条件、先保留后抽牌与两张保留不重复延期；滑脱标记实际加伤/免疫消耗/回合及提前离房清理；直接解除返能量；两段每次重新计算强制目标与新外层、并列选择、只支付一次、旧版本拒绝、选择期间不能插入其他行动、无目标不转自由效果；整张牌后一次压力增长与立即过载。

遗物检查直接归零与连带移除区分、每玩家回合刷新、实际二档到一档抽牌与纯降档/直接移除排除；真实飞踢落地后躺到坐的零费边界与机会消耗；实际魔力费用减免后的50%返还、每战首次限制、自由面不占机会、非战斗不触发。补充双重解锁先牢门后装备/先装备后牢门、储备术式只消耗一次、可停止第二把且不退费、真实收押保留全部遗物并清临时状态。非法多段状态在提交前原子拒绝。

窗口沿既有入口新增`tests/reward_ui_cases.gd`，共用原生拖牌、实际候选按钮、目标框滚动与截图助手。验证2费显示、拖向第一件后真实选择并列第二件、自由面直接拖到玩家保留两张、两把实际装备锁只耗一次魔力、单手受限时自由魔法仍禁用、新牌奖励进入卡组、完整遗物列表可滚动到最后一件。截图`ui-52-chain-targets.png`至`ui-55-relics-scrolled.png`已查看；最初测试误传装备ID而非候选ID，门禁正确报失败，修正后重跑通过。末次截图发现第二段开锁说明重复提示下一把，已修正为本次结束并补窗口断言，最终奖励专项通过。

整合：`data/card_rules.gd`集中机械定义及普通／罕见／稀有／完整奖励池；`core/card_effects.gd`共用旧牌和新牌的目标、费用、保留及逐段处理；`core/relic_effects.gd`统一直接触发、次数与行动后发放。只读投影/界面不增加状态写入口，卡牌和遗物均继续沿`dispatch`提交。事件奖励池已按真实稀有度拆分，文档及扩展接口同步。暂定数值为滑脱准备＋3、重挣扎9、两段各4、晶石返还50%；不表示最终平衡完成。

2026-09-06首批事件与扩展接口历史结果：`tools/check.ps1 -Suite events -UI`通过1826项规则断言、494项窗口断言，无引擎错误。相关依赖覆盖当前全部12个规则套件，每套件只执行一次：events200、core301、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184、tower_progression145，另有选择断言1项。

本批新增`tests/event_cases.gd`和`tests/event_ui_cases.gd`，沿既有入口检查。规则覆盖：12种子冻结完整方案、独立事件随机域、预览不写状态/编号/随机、不向UI泄露有效钥匙；三种裁缝交易真实普通/复合安装与组件锁、加固2/10→8/10、无目标中级回退、选牌与跳过不退代价；拒绝费不足/为零仍能结束；三枚钥匙分别用实际种子覆盖全部成功/失败、锁优先新目标、眼罩/皮带真实加固、不可重复领奖、满眼部容量拒绝完整赌局。检查未知效果、无效状态和目标不合法不留下部分装备或奖励。

奖励覆盖：慌乱无主动候选、虚无先于保留、卡组不删除、下一战和完整巡视恢复；开锁针零能量真实开锁、不改耐久、消耗次数、不能安装、手腕限制及姿态接触；开牢门仍检查逃离速度，逃出保留工具次数和遗物。折叠工具匣增加实际容量，整备沙漏延长实际战后整备；同遗物拒绝重复，池耗尽不提供无法发放的遗物方案。事件不触发回魔或战后奖励，不消耗跨战增益，离房仍检查容量。

窗口覆盖：正式地图两事件图标、进入后查看地图不重抽、真实点击交易/三选一/跳过/离房，钥匙阶段只有三个选项且无道具操作；领取遗物显示已生效说明，实际中奖开锁针在休息房打开指定锁并扣次数。已查看`ui-46-tailor-choices.png`至`ui-51-lockpick-tool.png`：选项代价、锁的变化、事件奖励与遗物说明完整。窗口长路线也逐房经过事件，通过正式拒绝和离房完成；新事件占用原战斗分支位置，因此路线最低数量按战斗＋已完成事件合计检查，战斗奖励仍逐场一一对应。

整合：警卫与事件共用`equipment_offers`及真实实例工厂；复合生成组合回到结构数据，敌人将行为/外观/装备池拆成模板字段；事件配置使用配方或显式原子效果，新增内容不得再复制阶段流程。遗物与卡牌特性通过注册表参与真实规则；扩展位置和约束在`docs/content-extension.md`。该历史批次仅用过渡牌池，五张奖励牌和四件遗物在后续批次补齐；没有新增升级、专属首领行为或完成最终数值平衡。

2026-09-06塔路精英与塔顶批次历史结果：导入通过，全部11个规则套件共1622项断言通过；修正窗口测试对并拢飞踢伤害及躺姿代价的预期后，`tools/check.ps1 -UIOnly`通过479项窗口断言，无引擎错误。规则分项：core297、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184、tower_progression145，另有套件选择断言1项。

新增`tests/tower_progression_cases.gd`与`tests/tower_progression_ui_cases.gd`，共用原检查入口。覆盖12种子下第8/12层可选精英及实际绕行连接、第16层双警卫与唯一出口连接；实际旅途保留装备和资源，两名70生命警卫分别受击，只击倒一名不能领奖；奖励、整备和容量整理完成前出口不开放，伪造抵达出口的移动完整回滚。精英与塔顶均沿正式收押、探索、坐姿踢开通风口、逃离和重建塔路流程检查，安全等级保留，新塔顶使用新敌人实例。

窗口验证实际地图查看不跳房、拖踢击到指定警卫、携带腿部装备时并拢飞踢造成10伤害并打断且变躺姿、双警卫失败仅入狱一次、正式塔路重开入口、领取奖励和整备后前往出口。`ui-41-elite-summit-map.png`至`ui-45-summit-cleared.png`已实际查看：地图图例、双敌意图、失败分支与通关文字完整。初次窗口测试把携带腿部拘束的踢击误按普通6伤害断言，修正为真实10伤害及姿态代价；修正过程中的测试字段笔误由错误日志门禁拦截，最终窗口重跑通过。

本批统一`room_entry_reason`供地图与正式前进读取；`-Suite tower_progression`自动合并监狱、警卫、塔路及传递依赖，各套件只执行一次。长路线规则与窗口复用`tests/route_driver.gd`，仅在流程测试中降低警卫生命，后续攻击、奖励和整备仍使用正式操作。定点窗口夹具从真实相邻休息房开始；原长路线检查仍逐房前进。这些通过结果不表示70生命双警卫与当前牌池的最终难度已经平衡。

监狱批次历史最终结果：`tools/check.ps1 -Suite prison -UI`通过1463项规则断言和423项窗口断言，无引擎错误。相关依赖覆盖当前全部10个规则套件：core283、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184，另有选择断言1项。最终左右分栏牢房与返塔地图截图已再次查看。

2026-09-06监狱批次：新增`tests/prison_cases.gd`与`tests/prison_ui_cases.gd`，沿原套件/窗口主入口执行。`-Suite prison`合并guard/tower及所有实际依赖，每套件一次；初次完整`-Import -UI`通过1444项规则、423项窗口断言。随后优化牢房左右分栏，并补充高安全等级、手势条件和反抗整备超容量检查，最终结果见下方。

规则覆盖：真实收押进入牢房、普通抽弃补能、独立有限发现随机、只读投影不泄露未发现顺序；探索费用按真实区域等级、零费发现不可重复刷取；倒计时精确到巡视，降低耐久不等于缺装，组件编号丢失可被发现；清单齐全保留随身工具、没收已安装工具；违规收紧及按安全等级追加真实装备、没收所有工具、不恢复通风口。检查完成才恢复消耗牌至弃堆、不能重复确认。三个巡视节点都可反抗且不提前恢复消耗区；胜利发专用钥匙、一次正常奖励/恢复、整备容量整理后回牢房；失败保留装备并只增加一次安全等级。开锁使用真实卡牌、手势条件、压力魔力费用和储备，旧版本/姿态变化不能绕过出口速度。坐姿并腿踢击打开通风口，每玩家回合一次，扣能量并消费对应蓄力；出口检查携带容量。逃离保留资源/装备/卡组/增益/安全等级，遗留墙面工具，重建路线而非复刷旧房，下场才正常补能。最后一回合过载只到达一次巡视、下一玩家回合只扣一次惩罚，回合中过载关闭探索和出口。非法发现记录导致回合、牌堆、资源和日志完整回滚。

窗口覆盖：真实练习菜单，测试夹具仅把警卫的已公开意图推进至收押，随后实际结束回合与进入牢房；点击探索获得两件有限工具和通风口，安装工具沿原道具入口，逐回合进入巡视，检查后真实没收墙面工具，继续启动下一巡视钟。坐姿三次踢击后经独立出口返回新塔底，地图实际显示可达的新入口。原生拖牌确认自由面不能开门、拘束面消耗实际“术式解锁”和魔力后打开牢门，并沿速度合格路线逃出。基础三姿态与原身体装备拖放继续保留。

截图`ui-37-prison-cell.png`、`ui-38-prison-inspection.png`、`ui-39-prison-vent.png`、`ui-40-prison-return.png`已查看。牢房最初纵向长列表已改为探索/通风口与牢门左右分栏；返塔地图使用独立塔底节点，不与首层重叠，也不再显示当前房间不可达的矛盾提示。五级只完成终局流程，不把未生成的专用固定套装计作通过；当时特殊道具路线和塔路精英节点尚未接入；本批已接入塔路精英。

2026-09-06警卫批次历史检查：`tools/check.ps1 -Import -UI`通过，导入无错误，规则1310项断言、窗口381项断言通过。规则分项：core283、equipment108、links37、composites83、equipment_complete229、guard120、pressure105、enemies160、tower184，另有套件选择断言1项。相关入口`-Suite guard`已通过1126项断言，自动合并依赖，每套件只执行一次；最后完整回归同时确认原塔路与普通敌人流程。

警卫规则覆盖：12个种子的意图/普通与复合工厂合法性、同种子复现、工厂探测不改状态或随机；公开的额外操作不递归、先加固再上锁、原目标失效落空；蓄力与先手双操作、普通回合不重复执行、打断延后；第10回合完成后11准备/12执行，双区域满级触发锁定、解除不取消、不改写当前意图；准备和执行分别打断、击倒取消、躺姿仍按既定先后手执行收押；双警卫首个收押立即终止整场且只增加一次安全等级，击倒两者才发一次奖励。入狱验证原装备耐久/锁/组件/链接及魔力/压力/卡组保留、随身与安装工具没收、增益/惩罚清理、实际新增普通件和链接、检查基准一致、无战后恢复奖励、重复回调与旧行动拒绝。非法附加操作引起整个正式提交回滚，资源和日志一并恢复。案例集中在`tests/guard_cases.gd`，不复制通用规则测试。

警卫窗口覆盖：真实菜单启动单/双警卫，拖踢击到指定实例只影响该敌人；逐回合经过打断、连动、收押进入真实结果，查看保留/新增装备不写状态；该批结果仅到入狱；本次已改为通过正式入口继续牢房。`ui-34-guard-intent.png`、`ui-35-capture-result.png`、`ui-36-double-guard.png`已实际查看，意图与收押提示完整，双敌目标分离。警卫仍为临时轮廓，非最终人物素材。

压力批次历史最终界面复核：`tools/check.ps1 -UIOnly`通过339项断言，无引擎错误；当时保留上一轮1000项相关规则日志。法术牌当前费用和过载空手牌提示已随截图复核。

2026-09-06压力批次：首次`-Import -UI`完整回归通过1183项规则断言、338项窗口断言。随后补充法术牌实时费用与无来源时的预览快速返回，以`-Suite pressure -UI`通过1000项相关规则断言和338项窗口断言；相关套件为core283、equipment108、links37、composites83、equipment_complete223、pressure105、enemies160，另有选择断言1项。tower184已在本批完整回归通过，后续修改未触及塔路。过载空手牌文案另用UIOnly复核，最终结果见下方。

新增压力覆盖：0/40/80分档与单调魔力曲线、加费后再扣储备、实时法术牌费用、免费魔法不加费且休息房仍禁自由效果；稳定心神费用/版本/回滚；来源时机和装备移除停止；行动后增长、立即过载、余数、多次累计、魔力归零下限、禁用全部剩余动作；后续回合惩罚只消费一次并与能量增益抵扣；先后手下的两名敌人顺序、打断一并延后、不取消第二名敌人、不重复前一敌人阶段；战斗结束/奖励/整备/练习退出只继承压力；移动来源保留、房间来源停止；非法来源使整个提交回滚。核心案例为`tests/pressure_cases.gd`，沿原依赖注册表合并运行。

压力窗口：真实滚动菜单启动两种练习，压力按钮显示实际来源/时机/魔力倍率，稳定心神扣费；两次原生拖牌触发过载、弹出结果、只保留继续入口；继续后准确更新休息计数和能量；敌人意图显示威压65，两个实际行动累计过载2次；完成战斗、选奖励进入整备保留压力而无惩罚。截图`ui-31-pressure-sources.png`、`ui-32-overload.png`、`ui-33-enemy-pressure.png`已查看。看到空手牌旧提示与过载冲突后，已修改为跳过剩余行动并增加窗口断言。

- 初始10牌、抽弃牌守恒、保留牌到期、奖励加牌、三回合整备和跨战继承。
- 紧度边界、同比降档、锁减半、单件无堆叠惩罚、分层与同层目标选择。
- 普通滑脱免疫时仍付费、眼部无挣扎不能触发自由分支、魔法身体条件及资源折扣。
- 姿态相邻切换、借墙结束玩家阶段、先后手只在回合开始判定。
- 冻结意图、打断不重抽、连续打断限制、击倒与附着离场各自结束战斗。
- 版本过期、伪造或不可用行动拒绝且不改状态；预览不推进随机；固定种子复现。
- 实际窗口按钮完成选牌、目标选择、出牌、遭遇、奖励、整备、下一场与重开。

2026-09-06装备补全历史记录：Godot 4.7.2。该批通过`tools/check.ps1 -Import -UI`：导入无错误，规则1073项断言、界面311项断言通过。窗口检查覆盖1600×900与默认1440×810。规则分项为core283、equipment108、links37、composites83、equipment_complete217、enemies160、tower184，另有套件选择断言1项。全规则约6.6秒，各套件只执行一次；未缩减既有规则覆盖。

本批修正了底栏溢出、同部位目标名称混淆、蓄力在体术衰减前计入基础伤害，以及浮游锁在蓄力时确定最终目标。确认目标提前解除后，锁的最终附着落空，不改选新目标。

新增覆盖：沿不同分支均可完成长塔路并抵达出口；禁止跳房与重复领奖；移动耗时按姿态和实际固定部位计算；移动期间牌堆、资源、玩家回合增益与随机游标不变。

界面测试使用真实鼠标事件验证右键翻面和Godot原生拖放：自由面生效、错误牌面拒绝、拖离目标取消、两件装备分别展开、拖入第二框只移除第二件，以及三档免疫滑脱仍扣除卡牌和费用。

新增角色拖放：固定攻击以实际落点敌人为目标，法术费用只扣一次；攻击不能作用玩家，已离场敌人不接收，挣脱牌不能作用敌人。姿态拖到玩家使用正常费用和回合规则。拘束面拖到玩家后先选部位，再选具体装备；选择前无消耗，右键翻面撤销原选择。自由面点击或拖到玩家直接生效；魔法身体条件不满足、能量不足均不扣资源。截图补充 `build/ui-09-actor-actions.png`、`build/ui-10-player-picker.png`。

休息房覆盖：真实塔路进入与离开、5回合耗尽、提前离开、每房服务仅一次、无自动回魔与消耗牌恢复、禁止自由效果但允许拘束分支的附加收益；挂钩3次、同比降档、三档紧度绕过、结构及外层限制和姿态范围。

工具覆盖：手指与脚趾安装、使用无能量费用、只切外露兼容材质、锁不减伤、次数共享与耗尽移除、携带容量减少、超载整理、随身次数跨房保留与安装工具离房遗失。窗口操作覆盖领取、打开道具面板、安装到墙脚、改变姿态和两次实际切割。截图：`build/ui-11-rest-room.png`、`build/ui-12-hook-targets.png`、`build/ui-13-field-tool.png`。

新版截图：`build/ui-01-battle.png`、`ui-02-free-drag.png`、`ui-03-two-targets.png`、`ui-04-reward.png`、`ui-05-map.png`、`ui-06-travel.png`、`ui-07-cleared.png`、`ui-08-default-window.png`。较早无ui前缀的截图仅为历史验证产物。

## 当前边界

**现行口径**（非历史条目）。

架构整合验证：显示投影不推进随机或修改状态，嵌套显示数据不引用可写的运行状态；篡改显示中的伤害或费用不能覆盖提交时的正式判定。战斗、整备、休息三种真实流程下，下回合能量只消费一次，抽弃牌守恒，魔力不额外恢复，战斗计数与非战斗倒计时分别推进。

界面索引验证：实际敌人与不存在目标分离、空行动组保持为空；打开面板不推进规则，外部状态推进后旧候选与旧拖放均拒绝且不消耗资源，失败提交也刷新显示和索引。原有125项界面断言包含完整战斗、路线、休息房和工具操作。

检查入口新增退出码、错误日志和完成标记三重检查。实测临时注入运行时错误后，Godot仍打印`PASS: 261 assertions`，入口正确判失败；已恢复原测试文件并重新跑通过。故障注入仅用于验证检查入口，未留在游戏或测试源码中。最新日志为`build/check-rules.log`与`build/check-ui.log`。

模板批次覆盖：四类材质的生成与实际解除、初/中级和紧度独立、材质版本随意图冻结、独立随机序列、错误部位/锁定/材质版本/耐久的原子拒绝、同部位混合容量与外层追加、加固与滑脱共用既有规则、胶带不继承旧粘性封锁、锁选择和执行时的双重复核、石片与锯条对塑料的实际兼容差异。专项案例在`tests/equipment_cases.gd`，由原规则入口统一运行。

装备练习通过真实界面入口启动：鼠标点击重开面板、编号合法性、四材质显示、明确的徒手/切割禁用原因、锯条两次切断扎带、原生拖牌滑脱胶带、挂钩解除绳索、练习结束及回到塔路。练习沿用正式候选和提交，5回合到期不产生战斗奖励或塔路进度。截图：`build/ui-14-equipment-practice.png`、`build/ui-15-material-tools.png`、`build/ui-16-practice-menu.png`。

敌人批次覆盖：绳索四阶段与第二回合两类分支；眼罩两回合蓄力、规格冻结、初/中级、各阶段打断、提前击倒、公开前后眼部容量改变的施加落空；同种多敌的独立生命、行动和来源，跨房ID不复用，全部离场仅奖励一次。眼部受阻立即显示且不擅自隐藏敌人意图。弱池开局抽取与只读预览可复现。专项案例在`tests/enemy_cases.gd`，由规则入口统一运行。

地图覆盖：已走连线严格对应真实移动记录；未选分支、正在移动与未来路线分别投影；房间图标查看不改变状态、不产生跳房候选，滚动位置随查看保留。窗口中实际点击未来节点，进入绳索＋眼罩战斗，并拖放踢击到第二只绳索，确认只有落点目标受伤与延后。战斗内查看地图不会叠出结束回合按钮。截图：`build/ui-17-rope-blindfold.png`、`build/ui-18-double-rope.png`、`build/ui-19-spire-map.png`。

长塔路覆盖：30个种子的节点唯一、向上连接、全节点可达、无非出口死路、生成段分支不交叉；同种子复现与不同种子变化；第7/11/15层休息点；预览不修改图或随机游标；两条完整长路线每战奖励一次。案例在`tests/tower_cases.gd`。窗口通过真实按钮完成长塔路，切换整塔总览、定位当前房间并维持不可跳房规则。整塔截图为`build/ui-20-full-tower.png`。

人物美术覆盖：从正式姿态动作依次切换站/坐/躺，显示正确图集区域并保持比例与地面对齐；绘制与动画不改变状态或随机游标；窗口像素检查确认绿底消失且粉色人物仍可见，原拖牌目标继续正常工作。当前使用用户本轮指定的三姿态附件，躺姿区域已扩展以完整容纳头发。截图：`build/ui-21-hero-stand.png`、`build/ui-21-hero-sit.png`、`build/ui-21-hero-lie.png`。绿底透明由专用画材在运行时完成，保留源图。

普通链接覆盖：两端引用同一共享耐久，显示快照无可写引用；同对逆序重复、失效目标、跨区域连接与普通施加入口拒绝；独立紧度伤害、蓄力只消耗一次、旧拖放原子拒绝、无滑脱与上锁；方向声明只阻止指定装备的滑脱。徒手接触检查任一外露且可达连接处，不把连接装备的锁或材质误当链接自身限制；工具固定伤害、次数与零能量费用；移除链接保留装备，移除必要装备清理链接，新装备不重接；战后、整备和房间移动保留连接。非法链接导致回合事务完整回滚。专项案例在`tests/link_cases.gd`。

链接窗口覆盖：真实点击独立练习入口、两部位显示连接标记、原生拖牌选择共享链接目标且仅结算一次、坐下后切割并同步更新两处详情。截图：`build/ui-22-link-targets.png`、`build/ui-23-link-released.png`。链接练习继续使用正式5回合规则与两件切割工具。

单手套覆盖：短/长与直/交叉四种组合的原子创建、覆盖与能力差分、组件共享目标和只读投影、容量与内外层、关闭手指后的施法/握持/安装条件、组件独立锁、肩带紧度上限、结构滑脱/挂钩前置、首次肩带解除不触发同次脱下、跨三档伤害不倒推资格、切割/滑脱不冒用挣扎捷径、外层阻挡、套体破坏保留独立内外层、敌人组件上锁、跨战与跨房保持、错误覆盖原子回滚。新增83项断言集中于`tests/composite_cases.gd`，通用材质、链接与回合案例不复制。

单手套窗口覆盖：真实菜单启动短型/长型，拖牌至手腕或小臂后选肩带和套体；两次滑脱去除一侧直肩带，再用一次挣扎按预览解除整件并更新资源/容量。长型验证交叉肩带共享耐久、挂钩前置、关闭手指后的切割拒绝、脚趾安装与躺姿固定工具切割。截图：`build/ui-24-glove-components.png`、`build/ui-25-glove-release-preview.png`、`build/ui-26-long-glove-tool.png`。目标摘要与完整详情分开，禁用原因不重复堆放。

检查整合实测：composites选项自动执行core/equipment/links/composites，各套件仅一次；完整规则约5秒（按输出分项耗时），未削减既有断言。未知套件misspelled实际返回非零且不生成成功标记，日志为`build/check-suite-rejection.log`，其中错误属于这次预期拒绝。窗口共用真实练习启动和滚动至指定拖放目标助手；UIOnly只重跑窗口流程，保留此前规则日志。

装备补全覆盖：29个练习的真实生成数量与配置一致，预览不写状态；普通模板全部合法等级；四种单腿套破坏套体后的外带ID/耐久/锁/链接保留、能力恢复与容量预留、长短叠层和超容量原子拒绝；拘束衣双前置、无滑脱袖部连接、已安装工具处理与整件清理；左右独立包裹的手势/握持/卡牌自由分支和上肢容量单次扣减；眼口胶带、马具逐眼罩紧度比较、相等允许、母件/附属件分别解除、马具独立锁减伤；十二种躯干固定的手持/徒手范围；高级复合基础耐久且无未定义魔法效果。损坏组件结构后的失败回合完整回滚。新增217项断言集中在`tests/equipment_complete_cases.gd`。

装备窗口补全：共用助手滚动到菜单下方并真实点击；工具三次切断单腿套套体后，链接仍引用遗留外带，随后原生拖牌到该外带准确扣耐久；自由的另一只手切开单侧包裹；拘束衣禁用原因可见，并用脚趾安装工具、切换坐/躺、切割真实袖部连接；马具分别阻止较松眼罩并允许等紧度眼罩使用挂钩；高级材料真实显示。新增窗口案例集中于`tests/equipment_ui_cases.gd`，从原窗口入口运行，共用助手。截图`ui-27-leg-bands-retained.png`、`ui-28-jacket-structure.png`、`ui-29-head-comparison.png`、`ui-30-advanced-catalog.png`已查看确认。悬浮眼罩另新增16种子规格文案检查与两模板覆盖，保留冻结/打断/落空原有测试。

四类普通材质、眼口、包裹、单手套、四种单腿套、拘束衣、躯干固定和普通/组件链接均有真实装备规则与练习入口。29项装备练习、2项压力练习、2项警卫练习合计33项。警卫练习已施加合法中级普通/复合装备，并完成实际入狱保留、没收与追加结算。普通塔路敌人生成绳索、皮带及布带/胶带眼罩；第8、12层的可选警卫与第16层塔顶双警卫可生成合法中级普通/复合装备。地图包含15层房间、第16层双警卫与第17层出口，约30节点。监狱探索、巡视、反抗、消耗恢复、三条基本逃路与返回塔底现已实现。第5/9层已加入首批两个事件，慌乱、开锁针、工具匣与沙漏已实际结算。五级专用固定结局装备、特殊逃离道具、其余道具与多章节尚未实现；自动存档与继续游戏已在后续批次实现；颈部用途、肩部跨区域链接、额外通用加固、驷马/折叠固定和专项模板不在本批已定义范围。数值集中暂定，主角仍只有基础三姿态，无逐件穿戴差分；警卫临时轮廓不代表最终美术。

窗口截图生成在 `build/`，不是运行资源。

## 2026-09-17 v0.17.1 修复版发布成品

来源：作者侧 `origin/main`（v0.17.1 提交，2026-09-17），正文逐字保留。

域：检查与测试、打包与发布。

- 用户要求更新GitHub为0.17修复版，同时提供PC、Android及密码保护的双层压缩版。版本统一为0.17.1，Windows文件版本0.17.1.0，Android versionCode由9升至10；保留原v0.17标签与发布，不并入PR #3的macOS打包。Android打包脚本改为读取同版本说明并附基础教学，避免沿用根目录旧说明；成品探针继续对0.17.x执行小魔女检查。
- `20260917T030419647-26868`：导入、architecture 471、touch 23通过，退出码0、源码指纹稳定。此前修复批次与PR整合各分类结果仍按下文分别记录；本次未重跑全项目或全部种子。根指引检查及5项检查器测试通过。
- Windows输出`outputs/spire-v0.17.1-windows-x64-fix-20260917`，导出前后运行资源指纹一致。`package-check-20260917T030529454`通过PCK内容、贴图、新局、练习、隔离保存恢复、小魔女平衡及发布EXE独立无头启动检查；未将无头启动宣称为目视渲染验收。
- Android输出`outputs/spire-v0.17.1-android-fix-20260917`，导出指纹一致，包名org.magic.spire、版本0.17.1／安装版本10、minSdk24、ARM64＋ARMv7。V2／V3验签、16KB对齐、provider唯一性及12份内容逐文件校验通过；证书SHA256与v0.17相同。`android-probe-20260917T030545246`包内资源探针通过。adb未发现设备，未做真机安装／触控／性能验收。
- 最终成品在`outputs/release-v0.17.1-20260917`，附验证说明、许可、基础教学和SHA256SUMS.txt。普通Windows／Android ZIP实际解压后与成品目录逐文件SHA256一致；双层7z包含两平台完整目录，内外两层都加密文件名，正确密码解压成功、错误密码拒绝读取，两次解压后的全部文件与源目录一致。证据在`outputs/verify-v0.17.1-20260917/verification.json`。
- GitHub按v0.17.1新标签及同名修复版Release交付，上传后以服务端附件SHA256与本地文件比对，再公开发布。缓存、测试存档、签名秘密、临时发布脚本及构建日志不纳入源码提交。

## 2026-09-17 修复18条基线失败

来源：作者侧 `origin/main`（v0.17.1 提交，2026-09-17），正文逐字保留。

域：界面、检查与测试。

- RuleChangePackage：玩法数值、候选、事务、随机和存档结构不变。本批修正17条过时测试前提，并把主页显示设置保存错误提示从右下角移到左侧免责声明上方，解决字体最小高度使控件底边超出900逻辑画布7像素的问题；保留现有错误文案及更新入口，无新增翻译或运行时状态副本。
- card_power的5条失败来自通用奖励池误包含小魔女专属牌；保留稀有度与排除条件检查，补五张专属牌在双方角色奖励池中的正反例。tower_progression的6条生命断言补上夹具保留的警戒2所产生的10点加成，保留周目倍率、分裂不重复缩放及固定治疗5点；另4条出狱顶层流程失败改为先正式选择10／11层入口，并增加未选择时拒绝跳顶层、失败状态不变的检查。
- home_persistence的新局预期改为真实开局奖励阶段departure，同时核对落盘阶段；宝箱恢复检查真实奖励面板，商店保留服务面板检查，二者均实际点击离开／继续并核对房间完成。保留精确恢复、资源和库存断言；新增非空保存错误在缩放后仍位于画布内、不压住免责声明且不改变游戏状态的检查。
- 主工作区`20260917T025735300-30980`：`tools/check.ps1 -Suite card_power,tower_progression -UI -UISuite home_persistence,home -KeepGoing -TimeoutSeconds 600`，规则card_power 1788／tower_progression 225共2013项通过，UI home_persistence 51项通过；home原左侧三控件断言因新增提示区失败，同批退出码1，源码指纹稳定。原失败日志保留。
- 更新home布局断言，明确检查标题、角色说明、保存提示和免责声明四个控件及状态不变；仅补跑受此修改影响的home分类。`20260917T030014632-4392`：`tools/check.ps1 -UIOnly -UISuite home -TimeoutSeconds 600`，113项通过，退出码0、源码指纹稳定。
- 本批最终按分类去重为规则2013项、UI164项通过，18条基线失败均已处理；不是一次全项目或全部种子回归。未生成截图、提交、推送、打包或发布。

## 2026-09-17 PR #2 架构与固定点存档选择性整合

来源：作者侧 `origin/main`（v0.17.1 提交，2026-09-17），正文逐字保留。

域：契约 `pr2-integration-review.md`。

基线e635bf5，PR头a56de58；先在隔离工作树验证，保留根／模块指引与现有目录。引入查询索引、文案按需入口、统一事件节点、状态迁移和checkpoint保存。修复非手牌实例显示被覆盖、四个测试文件漏迁移详情接口、重开时旧候选访问新游戏；存档文案及英文生成来源同步。RuleChangePackage、逐分类结果与可复现日志见[整合审查](pr2-integration-review.md)。

首批17个规则分类7996项、11个UI分类1280项分别通过；当时card_power 5条、tower_progression 10条、home_persistence 3条失败均在真正v0.17基线复现。这18条随后已处理，详见本文顶部修复记录；原失败日志保留。不是一次全项目门禁；未运行全部种子、Android／macOS真机或上游私有oracle，未截图、提交、推送、打包或发布。

## 2026-09-17 打包：Windows x64 v0.17（build pr2-20260917，协调者）

域：`tools/package.ps1`／`tools/check-package.ps1` 的产物与复验。**只打包，未发版、未推送、未做 Android。**

**环境（本机首次搭起，两条前置已登记 `.zcode/skills/repo-ops/SKILL.md`）**：引擎 Godot **4.7.2.stable.official.ed1daf0bf**（本机原先只有 4.7.0，与既有发布口径不符，故按 `docs/packaging.md` 装 4.7.2）；导出模板取自官方 4.7.2-stable TPZ，**SHA256 `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` 逐字等于文档记录值**，只安装 Windows x86_64 的 release／debug（±console）、`version.txt`（`4.7.2.stable`）与 `icudt_godot.dat`；打包脚本须用 **PowerShell 7**（5.1 无 `[IO.Path]::GetRelativePath`），且 `GODOT_BIN` 必须指向 `*_console.exe`（否则 GUI exe 不被等待、`$LASTEXITCODE` 为空，导出成功也会被判失败）。

**产物（`outputs/`，已被 `.gitignore` 忽略，不入库）**：目录 `spire-v0.17-windows-x64-pr2-20260917/`（24 项，含 `紧缚尖塔.exe`／`.pck`／12 份内容包／授权／`版本更新内容.txt`／`验证说明.txt`／`manifest.json`）；ZIP `spire-v0.17-windows-x64-pr2-20260917.zip`；校验和 `…-checksums.json`。

| 判据 | 结果 |
| --- | --- |
| `package.ps1 -BuildId pr2-20260917` | 退出码 0；导出前后运行源码指纹一致（`build/package-pr2-20260917/source-manifest.json`）；日志无 ERROR 行 |
| `check-package.ps1 -Directory <成品>` | **PASS**（清单逐项 SHA256 一致、发布 EXE 启动、成品 PCK 资源探针）；两次：`build/package-check-20260917T115621322`，加入包内验证说明并同步登记清单后 `…T115708521` 再次 PASS |
| ZIP 解压复核 | 24/24 清单项哈希与字节一致；清单外文件仅 `manifest.json` 自身（脚本按设计不把自身写入 files） |
| 哈希 | ZIP `8212e594af0d4e511fff70b550469c5075f8799f9d0870716fc83fadaf7d479d`（143545728 B）；EXE `28e19c54…`；PCK `5bf7f18b…`；manifest `62aa0857…` |

**未完成／不得当作通过（已写入包内 `验证说明.txt`）**：里程碑全量 `-Suite all -UI -UISuite all` **未运行**（本仓该命令历史上从未跑完）；本包依据的是开发路由的受影响套件轮（218.8s、`unrun=[]`、红集未超出既有六项）与两个冻结 oracle 的逐字通过，**两者都不能替代里程碑门禁**；Android 未打包（本机缺签名配置 `G:/CodexData/keys/spire-android/signing.json`）。包内另写明"每点击完整性检查改 debug feature"的过渡实现导致 release 不跑五道提交前检查与两道候选闸（早拦缺失由提交后聚合校验兜底并回滚）。

## 2026-09-17 per-click 完整性检查改 debug feature（实现者；协调者转写）

域：`spire-godot/core/game.gd`（提交入口／候选）、`core/room_events.gd`（事件探针）、`tests/architecture_cases.gd`＋`tests/check_index.json`。
契约 `docs/per-click-checks.md`。提交 `3f96965`（4 文件 +177/−18）＋`84eb12f`（2 文件 +8/−3），本地提交，未推送／未打包。

**实现**：`debug_checks_enabled()` 为单一判据（`OS.is_debug_build()` 为假恒 false；真时可由 `set_debug_checks_enabled(bool)` 覆盖，字段 `_debug_checks_override`；release 里 setter 直接 return）。门控点位：`game.dispatch` 五道早拦（`Consumables.validate_buffs`／`Binding.state_issue`／`SpecialEquipment.validate`／`Cards.validate`／`RelicEffects.validate`，顺序与版本判定位置不变）、`game._build_candidates` 两道候选闸、`room_events.probe_result` 只门控 `g.validate()` 一半（effects／可行性与 `held_pending` 不动）。**保持不门控**：版本相等、`write_game` 写档前聚合校验、`restore_snapshot` 读档聚合校验、`Snapshot.check`、`SpecialEquipment.validate` 的规则用途（`room_events.gd:783/903/1250`）、`equipment_replacement` 自检。
诊断落 `debug_check_failures`（`{check,reason,location}`）＋`push_warning`；**不进 state／存档／View／玩家日志／`{ok,error}`**，由新 check 逐条断言。

**判据（最终提交内容上复跑）**：①冻结 oracle 各两遍全绿且逐字等于基线（`EVENTDIGEST 1f11bea5…`、`TRANSITIONDIGEST 14eb8cf9…`）；②`-Suite architecture,core,runner,persistence,rewards,guard,battle_saturation -Impact -KeepGoing`：退出码 1、218.8s、`FAIL 15/20157`、**红集＝{card_power 5, installed_tools 1, tower_progression 10} ⊆ 既有六项**、`unrun=[]`、`runner` 索引零漂移 PASS；③新具名 check `tests/architecture_cases.gd:per_click_checks_are_debug_only`（消息前缀 `PERCLICK`）；④敏感性证明（临时把覆盖默认值改 false）：`events` 红 1 条（`tests/event_cases.gd:179` 确有既有用例依赖被门控的探针 validate 半）、`event_flow`／`core` PASS（＝五道检查与两道候选闸在既有语料里从不失败）、`architecture` 红 17 条（证明新 check 非空转），随后按 sha256 还原（`core/game.gd=71484d1e…`）。

**release 行为差异（登记要点）**：release 下五道 dispatch 检查与两道候选闸**不跑**——早拦消失；候选闸跳过**等于带坏状态继续建候选**；`dispatch` 内"执行后、提交前"的聚合 `validate()` 不在冻结清单、未动，仍是 release 的安全网（坏提交被"行动未提交：…"拒绝并回滚）。写档／读档／规则用途不受影响。

**未验证**：真 release 二进制行为（需打包，超出本片边界）、UI 套件与全量 `-Suite all -UI -UISuite all`、Android 真机。**观察交回**：执行后的聚合 `validate()` 是否纳入后续片待裁。

**追记（协调者，同日）**：人已裁定本 debug feature 属**过渡形态**，将在点击路径根治的提交中一并替换（`docs/refactor-direction.md`），届时本条的 release 门控结论随之失效，须重跑受影响的域。

## 2026-09-17 长流程试玩策略零进展护栏（原文缺标题，按正文重建）

域：`spire-godot/tests/normal_play_cases.gd`（长流程试玩策略）——**:184 断言未改、三条种子未删、1800 步上限未动**；
**产品代码零改动**（`git diff c356c64` 不含 `spire-godot/core|data|ui|content|assets`）。索引随 `tests/**` 改动 `check-index.ps1 -Write` 重冻结同批提交。

**复现与原始数据（分类依据，非断言失败推断）**
- 复现：`& tools/check.ps1 -Suite normal_play -TimeoutSeconds 900 -KeepGoing` → 退出码 1、`SUITE RESULT: normal_play FAIL`、
  `FAIL: 1/2779 assertions`、`SUITE RUNTIME: normal_play 1`（`n`＝该套件窗口内的引擎错误数，出处 `tests/test_game.gd`）、**660716 ms**（耗时字段出自另一行 `SUITE normal_play: 2779 assertions, 660716 ms`，同 `tests/test_game.gd`）；红项只有 :184；`seed=20260906 style=elite` → `result=action_limit`、**1800 步**（550216 ms），
  step≈226 起每 25 步采样恒为 `自由 · 手腕`。日志 `build/checks/20260917T060154346-39608/`。
- 打转步抓取（`build/diag-normal-20260917/`，复刻同一循环逐步 dump 候选／dispatch 结果／前后状态差）：
  - `seed 42/cautious step 331`：`valid=3`＝{`自由 · 脚趾`（`magic_slip` 自由面，0 能量 0 魔力，`slot=toes` 空位）、`结束回合`、`取出`}；提交 `ok=true`、**`CHANGED=["version"]`**（手牌、四堆计数、魔力、快感、牢房字段全不动），事件 `「魔力松缚」施法失败（成功率0.92%）。卡牌留在手中。`
  - `seed 20260906/elite step 226`：`valid=52`；提交 `解除 · 普通假阳具口球`（`magic_slip` 束缚面，10 魔力、失败返还 5、成功率 **0.03%**）→ `CHANGED=["version","mana"]`（每次净耗 5 魔力），事件 `「魔力松缚」施法失败（成功率0.03%）。返还5魔力。卡牌留在手中。`
  - 结论性事实：**每次提交都被受理（`ok=true`、`version+1`），但装备耐久、牢房进度（turn/vent/door/key/position）、阶段与牌堆都不动**；
    动作是零／低成本的施法抽奖，而 `结束回合`（唯一能恢复能量、推进牢房回合的动作）被策略分数永久排在后面（`end`=−50 ＜ 自由面 0 ＜ 束缚面伤害分）。RNG 每步推进，因此不是状态完全冻结，而是**策略永不改选**。

**分类：(b) 测试策略缺陷**（非 (a) 产品缺陷、非 (c) 环境噪声）。依据：该候选由 `_candidate` 按真实施法成功率（0.03%／0.92% > 0）判为 valid，失败留手与按 `failure_outcome` 返还魔力是既有规则（`core/game.gd:2609 _cast_magic`）且有玩家可见文案；同一投影里本就有 `结束回合`／`item_discard` 等可推进候选，产品侧不存在"反复成功却不改状态"的动作，也没有无法脱出的状态机死路（修复后同种子 317 步到达检查点）。

**机制定性（明确）**："低成功率施法＝抽奖，失败只退默认 50% 魔力"是**刻意的游戏机制，不是 bug**——`core/card_effects.gd:39 failure_refund_rates`（默认 `CAST_FAILURE_REFUND`＝50%）、`:73 failure_refund_detail`（"失败默认返还本次耗魔的50%，自身与临时魔力各退回原池"），增益可改写为全额返还（如"失败返还100% · 能量＋1"），单卡 `refund` 可覆盖；因此"烧掉一半魔力而什么都不推进"是合法结果，成功率低到 0.03% 时近乎空转仍属机制内。本次**产品代码零改动**，只修测试策略；`tests/normal_play_cases.gd` 头部注释已按此改写（旧措辞"pays and refunds mana"易被读成全额退还，与实测"10 魔力净耗 5"不符）。

**修复（`tests/normal_play_cases.gd`，+94 行）**：新增"零进展重试护栏"——提交后由驱动侧记录**可见投影指纹** `progress_key`（阶段／房间／回合／姿态／墙／手臂腿／快感／手牌 uid／四堆计数／状态／装备耐久与锁／敌人 hp／牢房 turn-left-vent-door-key-checks-found-sites），**已付与已返还的魔力不计入进展**；同一 `attempt_key`（载荷可见身份，不含 preview 数字）在指纹未变时只允许**重试一次**，其后 `choose` 先跳过它改选其它合法动作，指纹一移动即解除。
护栏只覆盖"原地尝试类"（`card`／`manual`／`hook`／`item_*`／`flask`／`calm`／`status_toggle`）；移动与回合动作不进入（盲走合法性允许重复同一方向，`结束回合` 正是要到达的兜底）。护栏是**偏好不是锁**：若它是唯一合法候选则照常选择（`choose` 两遍），不会产生 `no_candidate`。
新增 6 条具名 check：失败候选在结果未知时可打、指纹忽略已付/返还魔力、允许一次重试、零进展后改选、指纹移动后复位、绝不抽空合法动作、盲走不进入护栏。

**判据（本机墙钟）**
1. `& tools/check.ps1 -Suite normal_play -TimeoutSeconds 900 -KeepGoing`：**退出码 0**〔**274.2s**，其中 `CHECK rules` 271.46s〕、`SUITE RESULT: normal_play PASS`、**959 assertions**；
   三条种子全部 `result=prison_route`：42/cautious **334 步**（38.7s，护栏命中 6 步）、20260906/elite **317 步**（130.8s，护栏 16 步；原为 1800 步 action_limit）、7/trade **285 步**（99.6s，护栏 2 步）。274s ＜ 打转时 660s。
2. `& tools/check.ps1 -Suite prison,guard,persistence,architecture,runner -Impact -KeepGoing -TimeoutSeconds 900`：退出码 1〔**209.6s**〕、38 套件全有 `SUITE RESULT`、`unrun=[]`、`before==after`；
   `FAIL: 15/17673 assertions; 16 engine errors`，**红集＝{`card_power` 5, `installed_tools` 1, `tower_progression` 10(+1)} ⊆ 既有登记六项集**，无新增红项；`runner`（含索引零漂移自检）PASS。
3. 冻结 oracle：event `EVENT RESULT: PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字等于冻结基线、退出码 0、`SCRIPT ERROR|ERROR:|Invalid access` **0 行**〔5.7s〕；
   transition `TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（＝收束后记录值）、退出码 0、错误行 0〔4.4s〕。

**未验证／未做**：全量 `-Suite all -UI -UISuite all`（里程碑重跑由协调者决定；本片只修长流程策略）；Android 真机；打包／发版／推送。
残余风险：`attempt_key`／`progress_key` 是测试侧启发式，若将来出现"合法重复且指纹不动"的动作类别需按新证据重分类。

## 2026-09-17 检查路由与隔离·实现侧记录（原文缺标题，按正文重建）

域：`spire-godot` 检查入口（`tools/check.ps1` ＋ `tests/`）——**套件失败隔离**与**派生检查索引＋路由**。
契约 `docs/check-routing.md`（§11 七条裁定随施工生效）。**产品代码零改动**：`git diff 3afdc55 -- spire-godot/core spire-godot/ui spire-godot/data spire-godot/content spire-godot/assets` 为空；
不推送、不打包、不发版；未跑全量 `-Suite all -UI -UISuite all`（契约未要求，见"未验证"）。

**两段提交（基线 `3afdc55`，分支 `event-pipeline-unification`）**

| 段 | 提交 | 内容 |
| --- | --- | --- |
| ① 隔离 | `eaa003a` | `tests/test_game.gd`／`tests/ui_smoke.gd`：去掉整轮 `break`／`return`，脚本错误与断言失败只记该套件 `FAIL`（脚本错误另打 `SUITE RUNTIME: <name> <n>`，`n≥1` 才打印）；套件加载失败打 `SUITE LOAD FAILED` 并继续；`-KeepGoing` 变兼容无操作；新增负例夹具 `tests/runtime_error_ui_probe.gd`（在 `await` 之后于协程内报错，证明控制权返回宿主）；`-VerifyRunner` 探针改为隔离反例；旧口径加 superseded 指针（event-pipeline-unification／transition-pipeline／verification／changelog／repo-ops）。 |
| ② 索引 | `aa199f4` | `tests/check_index.gd`（derive／frozen／compare／suites_for，单一派生实现）＋`tests/check_index_edges.gd`（手写层，每条带理由）＋冻结物 `tests/check_index.json`＋生成器 `tools/build_check_index.gd`／`tools/check-index.ps1`（`-Write` 是唯一写者）＋计划宿主 `tests/route_plan.gd`；`tests/runner_cases.gd` 落 §3.4 i–viii 自检与 §6-G3 路由样例；`tools/check.ps1` 增 `-Changed`／`-Since`／`-ChangedList`（与 `-Suite`／`-UISuite`／`-UI`／`-UIOnly`／`-Impact` 互斥）、仓库外路径起引擎前拒绝、内容门独立阶段、`summary.route`；repo-ops 更新命令面与里程碑条款。 |

**三段墙钟（本机实测）**

1. **隔离收益**：同一命令
   `-Suite event_flow,events,content,architecture,localization,persistence -Impact -KeepGoing -TimeoutSeconds 900`
   ——**改动前**〔278.6s 截断＋261s 补跑＝539.6s，两个进程，`unrun`＝18 类〕→ **改动后**〔**729s 一次进程**，37/37 套件都有 `SUITE RESULT`，`unrun=[]`〕。
   覆盖未减少：**逐套件断言数与改动前逐条相等**（37/37，合计 16903 条），红集不变＝{`card_power` 5, `installed_tools` 1, `tower_progression` 10}，`SUITE RUNTIME` 分别记 5／1／10。
   口径说明：本机这一次进程比"两段之和"慢约 190s，全部落在 `prison`（92→283s）与 `persistence`（24→169s）两套件；单跑 `-Suite prison,persistence` 回到 91s／23s〔125s 墙钟〕，即长驻进程的开销，**不是行为变化**（断言数不变）。契约 §5.6 预期"≈400s 一次进程"在本机未复现；隔离的可复现收益是"单进程＋`unrun=[]`＋无需人工补跑编排"，不是时间。
2. **路由收益**：内容包清单 `-ChangedList`（内容门＋7 个消费者）**43s**（规则 31.5s、3023 断言、`CONTENT PASS: 12 file(s)`、退出码 0）；`ui/event_screen.gd` **44s**（`ROUTE RULE SCOPE: (none)`、UI `events` PASS 180 断言、退出码 0，两相分离仍成立）；计划宿主一次 **约 7s**（契约 §5.6 预期 8–10s）。
3. **索引维护成本**：`tools/check-index.ps1` 零漂移校验 **2.4s**（退出码 0）；`runner` 套件内含 i–viii 自检与 G3 样例，**1.3s／+52 断言**（≤10s 目标），`-Suite runner -VerifyRunner` 全探针 **154s**。

**索引规模（实测）**：`suite_files` 覆盖 **97 个注册套件**（规则 51＋界面 46；其中 **94 个有派生边**＝`suites_with_edges` 的另一口径；`rule:core`／`ui:baseline` 由宿主 `_core_cases()`／`_baseline_tests()` 承载、无用例文件，登记在 `SUITE_EXEMPT`）；**436 条（套件→源文件）边**；176 个用例文件全部有唯一 owner；`core|data|ui` 120 个 `.gd` 中 **117 个有边或域解析**、**4 个盲区**（`core/tool_rules.gd`／`core/item_presentation.gd`／`core/release_view.gd`／`data/phases.gd`，逐条 `BLIND_BY_DESIGN` 理由并注明由哪条闭包兜住）；`DOMAINS` 58 条、`WIDEN` 1 条（`core/game.gd + impact:persistence`）、`EXCLUDE` 12 条、`SUITE_EXEMPT` 3 条、`ORACLE_NOTES` 2 条、`INDEX_DEFECTS` **空**（无未闭合缺陷）。冻结物 `digest db5617dd…`、`generated_from 2214ff1a…`（冻结物以 `tests/check_index.json` 为准，2026-09-17 重冻为 digest `e2f17665…`／`generated_from 8c32ce78…`／437 边；上述 436 条与本段数字为撰写时值，原值保留为历史）；**连续两次 `-Write` 产物逐字节相同**（`cmp` 通过，键序稳定 §11-6，`git status` 无差异）。**体积 71 KB／3250 行**（契约估计 ≈11 KB）：主表 29.7 KB、`case_files` 17.6 KB、`domains` 10.8 KB、`domain_words` 4.2 KB、`registries` 1.8 KB——为可逐行 diff 用了 2 空格缩进与排序键。**任何 `core|data|ui`／`tests/**` 文本改动不改索引即红**（见敏感性证明 4）。

**盲区闭包清单（里程碑全量必须覆盖的路径）**：`spire-godot/core/**`→`all-dev`（含 `tool_rules.gd` 等 4 个 `BLIND_BY_DESIGN`）、`spire-godot/data/**`→`all-dev`、`spire-godot/ui/**`→`all-dev-ui`、`spire-godot/tests/**` 无法归属者→`all-dev`＋`all-dev-ui`、`spire-godot/content/**`→7 个消费者＋内容门、`spire-godot/assets/**`→`localization`（`assets/art/**` 另加 `hero_art`／`equipment_art`）、`spire-godot/tools/**`→`runner`、模块根文件→`all-dev`＋`all-dev-ui`、其他新目录→`ROUTE UNMAPPED` fail-closed。每次计划逐条打印 `ROUTE DEFAULT`／`ROUTE DOMAIN`／`ROUTE UNMAPPED`／`ROUTE WIDEN CANDIDATE`／`ROUTE MILESTONE`（扣除清单）。**`all-dev`／`all-dev-ui` 扣除 `normal_play`／`baseline`**，扣除清单每次打印，里程碑唯一入口仍是 `-Suite all -UI -UISuite all`（已写进契约命令面与 repo-ops）。

**判据（命令／退出码／断言／红集）**

- `& tools/check.ps1 -Suite runner -VerifyRunner -TimeoutSeconds 900`：**退出码 0**〔154s〕；`negative-isolation-assertion`／`-assertion-keepgoing`／`-runtime`／`-load`／`-ui` 与 `route-ui-only`／`route-content`／`route-save`／`route-snapshot-domain`／`route-blind-closure`／`route-unmapped-fail-closed`／`route-declared-none`／`route-scope-matches` **全部 PASS**；`negative-stop`／`negative-continue`（旧行为探针）已按 §4.3 改为隔离反例。
- `& tools/check-index.ps1`：**退出码 0**〔2.4s〕，`CHECK INDEX PASS: frozen index equals the derivation (digest db5617dd…)`。
- `-Suite runner`：**PASS 1446 断言**〔1.3s〕（含 i–viii 与 G3 全部样例）。
- 注入复现（真实注入，非桩）：`--probe-suite-failure`／`--probe-suite-runtime-error`（`tests/runtime_error_probe.gd`）／`--probe-suite-load-failure` 三种都得到 `SUITE RESULT: runner FAIL`＋后续 `tower PASS`、`unrun=[]`、`rules.retry=[runner]`、退出码 1；UI 侧 `--probe-module-runtime-error` 得到 `SUITE RESULT: localization FAIL`＋`SUITE RUNTIME: localization 1`＋`home PASS`（`await` 内报错后控制权返回宿主，§10-2 的回退条件不成立，UI 隔离按 §4.2 正常交付）。
- `-Changed -ListOnly`（本片工作区 9 个文件）〔7s〕：`.zcode/…` 正确判为 `ROUTE NONE`、新增 `tests/*` 判为 `tests/**` 闭包、`tools/*` 判为 `runner`、`runner_cases.gd` 判为 owner `runner`。
- **`-VerifyRunner` 的既有缺口（本片修）**：选择探针的原实现把子进程 stderr 经 `2>&1` 灌进父进程，`ErrorActionPreference=Stop` 下变成终止错误——`-Suite runner -VerifyRunner` 在 `3afdc55`（stash 后重跑）**同样失败**，属既有 harness 缺陷；改为 try/catch 捕获后退出码与消息都成为探针证据。

**敏感性证明（原始输出，全部还原、`git status` 干净）**

1. 冻结物改一字节（`"schema": 1`→`2`）：`CHECK INDEX FAIL: frozen index schema is not 1`、退出码 1。
2. 冻结物改内容一字节（`"blind": 4`→`5`）：`CHECK INDEX FAIL: frozen index is not the derivation, first difference at root.stats.blind (4 vs 5.0)`；默认门禁 `-Suite runner` 同步红：`RUNNER index_matches_regeneration: … first difference: root.stats.blind (4 vs 5.0)`＋`FAIL: 1/1446 assertions`。
3. 删一条索引边（`rule:action_copy → spire-godot/core/action_copy.gd`）：`first difference at root.suite_files.rule:action_copy.spire-godot/core/action_copy.gd (missing on right)`，`runner` 同红。
4. 源码漂移不 `-Write`（给 `tests/content_cases.gd` 追加一行注释）：`RUNNER index_matches_regeneration: … first difference: root.generated_from`＋`index_regeneration_is_the_only_writer`，`FAIL: 2/1446 assertions`。
5. 隔离：见上"注入复现"。

**新登记：一条既有红项（非本片引入，未修）**：界面模块 `interface`（`tests/interface_ui_cases.gd:156`）失败——
`CARD ART every registered card has an illustration: [witch_strain, … witch_authority]`（28 张角色二卡无立绘），`UI SUITE interface: 355 assertions`。
**分类证据**：`git diff 3afdc55` 对 `spire-godot/ui`、`spire-godot/assets`、`spire-godot/content` 与该用例文件**均为空**（本片只改 `tests/` 宿主／`tools/`；用例内部断言未动），断言内容与种子／夹具未变 → **既有内容缺口**，此前未登记是因为门禁从未单独跑过 `interface` 模块。另记：`spire-godot/ui/event_screen.gd`→UI `events`、内容包清单两条路由实跑均绿，说明该红不是路由引入。

**未验证／未做**：全量 `-Suite all -UI -UISuite all`（契约要求它只作里程碑唯一入口，本片按其规定未跑）；Android 真机；打包／发版／推送；`INDEX_DEFECTS` 学习环尚无条目可演（列表为空是"未发生漏检"的记录，不是覆盖证明）。四态计数：**passed**＝隔离 37 套件＋内容路由 7 套件＋界面 events／home／localization＋runner／tower＋8 个 route 探针＋5 个隔离探针；**failed**＝`card_power` 5、`installed_tools` 1、`tower_progression` 10（均既有登记）、`interface` 1（本次新登记）；**unverified**＝全量与 Android 真机；**skipped**＝`-Exhaustive` 与 `normal_play`／`baseline`（按设计不进路由）。

## 2026-09-16 状态迁移管线收束：实现四批落地与四项判据（实现者）

域：`spire-godot` 状态迁移管线——`state.phase=`／`state.room=` 的唯一写入者 `_apply_transition`、
唯一战斗结束判定 `_battle_end_reason()`、唯一执行 `_finish_battle(end_kind)`、进程内迁移日志
`_transition_log`。契约 `docs/transition-pipeline.md` §2–§6；基线见本文件同日的冻结记录
（`TRANSITIONDIGEST 00089c29a675e1268473645ab6b7a363e70295abf575cc6cc2929db995ca3e11`）。
不推送、不打包、不发版；本片不新增 `core/*.gd`，不改存档格式、玩家文案、数值与 UI。

**四批提交（均在 `event-pipeline-unification`，基线 `ce4f978` 之后）**

| 批 | 提交 | 内容 |
| --- | --- | --- |
| 基线 | `9ee7a2f` | 冻结迁移 oracle 与基线（脚本与基线在 gitignored `build/`，摘要入本文件） |
| ① 战斗结束判定 | `d519402` | `_battle_end_reason()`（""／victory／captured／saturated）＋`_finish_battle(end_kind)`；`_finish_if_saturated()` 变薄封装；4 处 `_all_gone()` 判定改走同一判定；2 个测试调用点按声明 kind 适配 |
| ② 阶段赋值 | `a1744de` | 26 个 `state.phase=` 写入点全部改走 `_apply_transition`；新增 `TRANSITIONS` 声明表与 `_transition_log`（进程内） |
| ③ 房间赋值 | `9d5a6af` | 最后 10 个 `state.room=` 写入点改走主路径；`_room_transition_kind`（层高＝`floor_enter`，否则 `room_enter`） |
| ④ 闭环 check 与收口 | 本批 | `transition_write_sites_are_pinned`（architecture）＋§5 八条 Gherkin 具名 check；`_apply_transition` 阶段显式化与日志一次一记 |

**收束后规模（实测扫描，`文件|函数|组`）**：①`state.room=`／②`state.phase=` 各 1 点（都在
`_apply_transition` 内）；③战斗结束 19 行／8 个函数（`_battle_end_reason`／`_finish_battle`／
`_finish_if_saturated`／`_start_round`／`_enemy_phase`／`dispatch`／`_execute`／`_end_turn`，
即契约 §1 的"8 个语义入口"，13 个引用点保留为同一批函数；④`_restart_tower(` 4 行（定义＋
`demo_exit.continue_run`／`prison.return_to_tower`／`prison.completed_turn`）。

**判据（墙钟为本机实测）**

1. **迁移 oracle**〔7s〕`--baseline=` 退出码 0、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、
   输出 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**；31 个场景的
   `before`／`after`／`commit_logs`／`log_texts`／`digest` **逐字段等于冻结基线**，迁移日志增量等于
   抓取时冻结的 `transition_log_declared`（比对时两侧按"相邻同名＝同一次迁移"合并，见下"口径"）。
2. **规则门**〔2m08s〕`& tools/check.ps1 -Suite core,rewards,battle_saturation,guard,prison,tower,tower_progression,events,event_flow,persistence,architecture -Impact -KeepGoing -TimeoutSeconds 900`
   → `-Impact` 展开 44 分类；`FAIL: 5/7861 assertions; 6 engine errors`，
   **红集＝{`card_power` 5 条, `installed_tools` 1 条} ⊆ 已知四项**；`installed_tools` 的
   `SCRIPT ERROR` 触发 runner 的 `runtime_error` 分支，其后 **24 个分类 `unrun`**
   （清单：environment_height／exploration／shoulder／slip_motion／torso_binding／casting／wall／
   special_equipment／services／intent／action_copy／status／persistence／rewards／events／core／links／
   prison／guard／pressure／enemies／trader／tower／tower_progression），**合并为一次调用补跑**〔3m29s〕：
   23 PASS，`tower_progression` FAIL＝**10 条（已登记）**；补跑后 `unrun` 为空（未记作通过）。
   `summary.json`：`before==after`、无 `source_changed`。
   > **本条已取代（superseded，2026-09-17；新口径见 `docs/check-routing.md` §4.3）**："截断／`unrun`／合并为一次调用补跑"口径作废——脚本错误只记该套件 `FAIL(runtime)`＋`SUITE RUNTIME: <name> <n>`，同轮跑完其余套件、`unrun=[]`；数字原样保留为历史。
3. **界面门**〔1m22s〕`& tools/check.ps1 -UIOnly -UISuite persistence,home,events -TimeoutSeconds 900`
   → 退出码 0、三分类 PASS、`UI PASS: 369 assertions`。
4. **闭环 check 双向比对**〔架构套件 25s〕：扫描 `core/**/*.gd`（递归）、`#` 之后截断、`==` 排除，
   四组模式；扫描集 ⊆ 声明表（表外为空）且表内 14 项逐项命中（含③的 8 函数集合断言）。
   **敏感性证明（原始输出）**：在 `_finish_if_saturated` 顶部临时插入一处表外 `state.phase="battle"`
   → `SUITE RESULT: architecture FAIL`、`FAIL: 1/462 assertions`、
   `ERROR: ARCH transition scan finds no write site outside the pinned table: ["[\"res://core/game.gd:803:_finish_if_saturated\"]"]`
   （即 `文件:行:函数`）〔26s〕；随后还原（`git diff` 无残留）→ `architecture PASS`、`PASS: 466 assertions`〔25s〕。

**§5 八条 Gherkin 具名 check（全部走真实公开命令：先取 `candidates()` 再 `dispatch`）**

| 场景 | 落点 | 断言要点 |
| --- | --- | --- |
| 01 `battle_end_single_path_for_all_entry_points` | `tests/battle_reward_cases.gd` | 9 个入口（普通最后一击／`end` 后全灭／空间耗尽／事件战／监狱出口战／`dispatch` 后全灭／敌人离场后全灭／投降收押／警卫宣告收押）各自：迁移日志恰一条 `battle_end_*`、目标阶段不变、`_finish_battle` 计数 1（收押 0，走 `_apply_transition`） |
| 02 `prepare_end_three_branches_one_kind` | 同上 | `pack`／`map`／`cleared` 三支日志均为 `prepare_end`、目标阶段分别正确 |
| 03 `floor_enter_is_one_family` | `tests/tower_cases.gd` | 跨层抵达恰一条 `floor_enter` 且 room 变化在该条内；同层（牢房 -1→塔底 -1，真实出狱回合）零 `floor_enter` 且有 `tower_restart` |
| 04 `capture_routes_through_the_main_path` | `tests/guard_cases.gd` | 投降与警卫宣告两条收押：日志恰一条 `battle_end_captured`、`captured`／`prison` 不变、能量归零／无力化／牢房初始化与入狱快照（在迁移之后建立）一致、`validate()` 通过 |
| 05 `non_transitions_do_not_write` | `tests/service_cases.gd` | 打牌／未全灭的结束回合／商店交易／事件选择／牢房移动：日志为空、阶段与房间不变 |
| 06 `transition_log_never_reaches_state_or_view` | `tests/persistence_cases.gd` | 迁移日志在进程内非空；`state` 无 transition 键、快照／`pack` 存档／`get_view` 均不含 `battle_end_` 或 `_transition_log`；恢复存档不写日志 |
| 07 `transition_write_sites_are_pinned` | `tests/architecture_cases.gd` | §4 双向比对（含敏感性证明，见上） |
| 08 `demo_end_and_tower_restart_use_declared_kinds` | `tests/tower_cases.gd` | demo 结束＝`demo_end` 且阶段／房间不动；返塔继续日志全为 `tower_restart`、`map`／`tower_bottom` 不变 |

**迁移日志口径（新增，冻结基线时声明、收束后按此判定）**：一次迁移记一条。①同一 kind 的
`phase`／`room` 由调用点分两次写入（**赋值位置一律不变**），第二条只写未写过的字段时不再记；
②重复写同一字段仍是新的一次迁移（例如牢房每回合 `prison_cell_enter`）；③`_apply_transition` 只在
调用点显式给出 `phase` 时写阶段，且必须落在 `TRANSITIONS` 声明的集合内；只带 `room` 的续写调用不写阶段。
oracle 比对按"相邻同名合并"处理两侧，故行数差异不算漂移，kind 或顺序差异才算。

**与契约文面的偏差（实现中发现，已在报告列出）**：①契约 §5 场景 01 的"恰有一条"以本口径满足
（收押的 phase／room 两次写入合并为一条）；②契约 §3 表把 `guard.gd:113/117` 写作"经主路径执行"，
实现为两次 `_apply_transition`（不经 `_finish_battle`：后者拥有胜利／饱和的奖励体，收押副作用仍全部留在
`Guard.capture`、顺序不变）；③`floor_enter` 为契约 §5 场景 03 用到的 kind，§3 表只列了 `room_enter`，
本片补声明 `floor_enter`（层高判定）并保留 `room_enter`（抵达阶段的阶段写入）；④`demo_end` 为新增
marker kind（不写 phase／room，只记日志）；⑤`_enemy_phase` 尾部的 `_battle_end_reason()=="victory"`
判定在真实流程中不可达（1126／1166 的两处饱和调用先接管；只有"未完成的连续卡牌"这一非法状态才落到它），
oracle 用该非法状态单列一个场景（`battle_end_enemy_phase_all_gone`，唯一 `skip_validate` 行）冻结其行为。

**oracle 基线声明的两处更正（harness 缺陷，非行为漂移）**：抓取时无法自证的两行声明与代码事实不符——
`tower_restart_same_floor`／`demo_continue_restart` 声明 2 条 `tower_restart`（实际合并为 1 条）、
`prepare_end_cleared` 与 `practice_init_rest` 的重复同名写入；因两侧按同一合并口径比对，
**基线 JSON 与脚本的冻结内容未改**、行为字段零差异（31/31 逐字段相同）。

**未验证／未做**：`-Suite all`／`-UISuite all` 全量回归（契约未要求）；android 真机；
`docs/save-fixed-points.md`（暂停中，未 `stash pop`、未消费迁移日志，挂点已留）；打包／发版／推送。

## 2026-09-16 状态迁移管线收束：迁移 oracle 基线冻结（实现者，改道前）

域：`spire-godot` 状态迁移管线（`state.phase=`／`state.room=` 写入点、战斗结束判定、迁移日志）。契约 `docs/transition-pipeline.md` §3／§6(b)／协调者记录（本片硬前提：**改 `core/` 之前先冻结迁移基线**）。基线提交 `ce4f978`，抓取时 `git status --short` 为空。

- 脚本（gitignored）：`spire-godot/build/transition-oracle-20260916/transition_oracle.gd`，
  sha256 `b49b0164a6b962fc8eae4a843c36510e1fa12c846d9f0e565856fdc6ed092278`；式样照 `build/event-oracle-20260916/event_oracle.gd`，含 JSON 数字类型归一（比对侧）。
- 基线：`spire-godot/build/transition-oracle-20260916/baseline.json`，
  sha256 `ba979d18c31952d6d69ef06ce2ed102f7503c518fa8c6125ea6482c92bb5b4c8`，
  `TRANSITIONDIGEST 00089c29a675e1268473645ab6b7a363e70295abf575cc6cc2929db995ca3e11`，**31 个场景**。
- 抓取命令（`spire-godot/` 下）：`<godot> --headless --path . --script res://build/transition-oracle-20260916/transition_oracle.gd -- --write=build/transition-oracle-20260916/baseline.json`
  → 退出码 0，日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**，`TRANSITION PROBLEM` 0 条；同参数连抓两遍产物**逐字节相同**（`baseline-rerun.json`）。
- 场景覆盖（逐类）：`setup_init`／`departure_start|end`；八类战斗结束入口（普通最后一击／`end` 后全灭／空间耗尽／事件战／监狱出口战／投降收押／警卫宣告收押／`_enemy_phase` 尾部全灭）；整备结束三类（`pack`／`map`／`cleared`）；进层（`floor_enter`）与换塔同层（`tower_restart`，牢房 -1→塔底 -1）；房间迁移与练习初始化四种（rest／shop／battle／prison）；牢房回合、巡视、逃脱；事件进入／空房离开／事件道具奖励；demo 结束与返塔。
- 每场景逐字段冻结：迁移前后的 `phase`／`room`／`floor`／`version`／`state.rng`／本次提交日志 sha256（`commit_logs`）＋可读日志行（`log_texts`）／`room_event` 摘要，并给出行摘要 sha256（`digest`）。
- **迁移日志的比对口径**（写进脚本头注，供后续复核）：`transition_log` 是本次新增的进程内日志，收束前不存在；基线在抓取时冻结 `transition_log_declared`（31 行的期望 kind 清单），比对时要求收束后的日志增量**逐字等于该冻结声明**，其余字段双向逐字段比对。
- 基线自检（收束前用 `--baseline=` 自比）：仅 31 行 `transition_log` 差异（期望），**其余行为字段零差异**，`TRANSITION RESULT: FAIL (31 scenarios, 31 failures)` —— 证明该 oracle 的行为字段在收束前是逐字段自洽的（`selfcheck.log`）。
- 未验证／未做：`core/` 尚未改动（本记录只冻结基线）；`_apply_transition`／`_battle_end_reason` 与迁移日志尚未存在。

## 2026-09-15 文案路由与按需投影（B0、R0–R6、B1–B3）验收与配对收益

域：spire-godot 玩家可见文案的投影路径（`get_view().card_texts` 收窄到显示集合 S、`card_instances` 只留手牌 uid、`deck_list` 移出 View、card 组候选 detail 改按需、`core/copy_router.gd` 收口 74 类文案）。契约 `docs/ondemand-copy.md`。

提交链：`cc5e8f0`(B0)／`7f1c748`(R0)／`40071d4`(R1)／`3f895b0`(R2)／`ee02495`·`2c2115c`·`964347a`(R3a/b/c)／`6247a56`(R4)／`ed2b5b2`(R5)／`0ce790e`(R6)／`6eca6e0`(B1+B2)／`a3cdcbe`·`638d6bc`(B3)／`67650f9`(场景 1/5 具名 check)。

- 三条 oracle（实现者运行，协调者核对日志）：`MASK DECLARATION` 与实际移除键集合**相等**（B1 `card_texts` 90/90/90/92/92/92 键、`card_instances` 0；B2 `deck_list`；B3 card 组 detail 60/60/130），`sha256(mask(new))==sha256(mask(基线))`、`masked_hash=true`、无差异；全牌型三入口（`live_card_text`／`live_card_text_set`／∈S 的 `view.card_texts`）逐字段相等，实例部分为包含关系（只允许 `face_costs`／`casting`）；真实夹具 `ui.projection_misses` 为空，缺键场景留有具名记录。收口阶段（R0–R6）为**空声明集**全等，即未改变 View 内容。
- 门禁（§8 原命令）：规则 `20260915T200001805-38332` 红集=`card_power`；界面 `20260915T200035182-33956` 红集=`shoulder`；`-KeepGoing` 版 `20260915T194250607-55264`＝5/9608（失败集恰好 5 条已登记 `witch_*`）、`20260915T194512850-9968` UI 1045 断言红集恰好 `shoulder`2+`torso_binding`1+`interface`4。**红集只等于已登记既有阻塞项，未多一条。**
- 夹具序列与具名 check：场景 0／1／4／5／7 已落地（场景 4 由 B2 oracle 的全量条目比对 + 牌堆浏览/商店去卡套件 + 三入口相等三层覆盖，未单列）。
- **配对收益**（`docs/equipment-performance.md:45` 协议：同机同批、交替、2 次热身 + 15 次有效配对；headless；对象为一次 `get_view()` 与一次 `candidates()`；旧侧 `0ce790e`（收口后、按需前）、新侧 `67650f9`）：

| 夹具 | 视图 旧→新 中位 (ms) | 配对比值中位 | 候选 旧→新 中位 (ms) | 候选条数 |
| --- | --- | --- | --- | --- |
| battle:0 | 79.39→23.22 | 0.311 | 24.14→11.46 | 86 = 86 |
| battle:12 | 108.72→44.87 | 0.416 | 44.70→27.22 | 98 = 98 |
| battle:26 | 206.28→81.24 | 0.398 | 120.54→54.83 | 182 = 182 |
| departure:0 | 50.04→6.56 | 0.127 | 0.56→0.50 | 6 = 6 |
| departure:12 | 58.89→9.37 | 0.164 | 0.73→0.69 | 6 = 6 |
| departure:26 | 72.14→13.61 | 0.186 | 0.96→0.81 | 6 = 6 |

- 夹具未漂：旧侧六档的 `view`／`candidates` 哈希与 `docs/equipment-query-seam.md` §8.2 冻结基线逐项一致（如 battle:26 `f7401077…`／`361c3777…`）；新侧按设计不同，其中 departure 的 candidates 哈希**未变**（该相位没有卡牌候选）。
- 口径：这是**同机同批配对数字**，不与历史批次拼接、不外推为帧率或全设备结论；本批只测 headless；收益来自按需化，收口阶段是逐字节等价的纯结构迁移。
- 未验证：**一次完整的独立验收未跑完**（验收者两次中断，已复跑的片段为规则门、`-KeepGoing` 界面门与人路径套件，日志见仓库根 `tmp/_spire-wt/gate-*.log` 与 `build/checks/20260915T22*`–`T23*`）；未跑 `-Suite all`、未做 Android 真机；`escape_preview` 未动；UI 响应路径与节键未动；未打包、未推送。收尾过程中另行发现并登记了 `rewards` 的既有红项（见下"既有红项登记"）。

## 2026-09-15 既有红项登记（非本次两片引入，未修复）

域：spire-godot 测试门禁在本次两片（装备只读查询接缝、文案路由与按需）**开工前的提交上即已存在**的失败项。两项均不属任何一片的改动范围，**未修复、未分类**；登记供后续接手方与全量回归判断使用。不得把其中任一项当作已通过，也不得为凑绿而从门禁命令里删除对应套件。

- `card_power` 规则侧：`tests/card_power_cases.gd:85` 的 `CARD reward membership follows rarity and explicit gift exclusion` 等 5 条 `witch_*` 奖励归属断言失败。复现：在未改源码的 HEAD（`1795e86`）上 `git stash` 后运行该套件 → `build/checks/20260915T163500673-34468`，退出码 1、5 失败 / 1781 断言。归因方向：`core/witch_expansion.gd` 的 `REWARDS` 与 `rules.SPECS.rarity` 的关系；未定类，未修改。
- `shoulder` / `torso_binding` 界面侧：三条失败（`SHOULDER UI compact cards show side and method`、`SHOULDER UI host card explains remaining-side penalty`、`BIND UI attachment and independent durability are visible`）。复现与根因见下方装备片验收条目；摘要：在切片父提交 `16c89e9` 的临时工作树上结果相同（`20260915T160616347-54344`、`20260915T160711923-52452`），根因 `ui/release_details.gd:35-38`（v0.17 `e635bf5`）只为 `lock_only`／`is_special` 渲染 `card_status`。
- `tower_progression`（规则 + 界面）：10 条规则断言 + 1 条界面断言失败（`tests/demo_exit_cases.gd:44/51/55`、`tests/tower_progression_cases.gd`；含 `DEMO boss health uses normal base, not compounded previous health`、`DEMO custom encounter health also scales`、`DEMO summon base scales while fixed healing remains five`、`PROGRESSION actual adjacent departure summit`、`PROGRESSION rebuilt summit creates a new boss instance without clearing safety history`）。**四点定位，失败集逐条相同、均在 10/215、退出码 1**：`964347a`（HEAD，`20260915T171801224-46088`）／`1795e86`（B0 之前，`20260915T171350281-47260`）／`e635bf5`（v0.17 发布点，`20260915T172946961-28640`）／HEAD 且仅把 `core/demo_exit.gd` 还原到 R1 之前（`20260915T171821467-40568`）→ **先于 v0.17 即存在**；证据留档 `build/ondemand-copy-20260915/preexisting-tower-progression-*.log`。
- `interface`（界面）：多套件连跑时报 4 条错（单独跑只 1 条，属模块间状态污染）。`964347a`（`20260915T171841906-51540`）与 `1795e86`（`20260915T172502057-47120`）失败集相同 → 既有。
- `rewards`（界面）：1 条断言失败——`tests/reward_ui_cases.gd:138` 的 `REWARD UI final unlock segment does not promise a third lock`（313 断言、exit 1）。**三点定位，失败集逐条相同**：`67650f9`（HEAD，`20260915T233305923-26972`）／`base-0ce790e`（R1–R6 后、B1–B3 前，`20260915T233523727-20952`）／`1795e86`（**文案片首个代码提交之前，`core/copy_router.gd` 尚不存在**，`20260915T234925378-16980`）→ **非本次两片引入**；`e635bf5`(v0.17) 亦红（`20260915T234617519-20320`，但在 217 行因另一处脚本报错先中断，仅作旁证）。根因：链式行的 detail 由 `ui/release_details.gd:53-54` 放进**默认折叠**（"效果详情 ＋"），故不在 `visible_text` 中；`core/release_view.gd` 与 `tests/reward_ui_cases.gd` 在 `e635bf5→HEAD` 逐字节未变，属 **v0.17 UI 渲染 vs 测试期望**同族（与上面 `shoulder`／`torso_binding` 同源）。该套件自 v0.17 起未绿、且从未列入任何门禁命令。
  - 若日后要修，两条路都需先裁定：(a) 测试改为先展开"效果详情 ＋"再断言（等于改断言，须明确授权）；(b) 让链式行恢复内联 detail（改 v0.17 的 UI 设计，超出本片范围）。**本次两片都不得动。**

## 2026-09-15 装备只读查询接缝（B1–B9）验收

域：spire-godot core 装备只读查询（`_equipment_read` 作用域、契约 §1 查询接口、§3.1 外层入口作用域）。对象提交 `def4039`；链 `eb6eeed`(B1)／`094c1d3`(B2)／`240658c`(B3)／`8de2957`(B4)／`79946ab`(B5)／`5af275d`(B7)／`09ccdd7`(B8)／`def4039`(B9)，B6 并入 B9 无独立提交。验收者为独立复跑（非继承），未改产品代码与测试逻辑；测试存档隔离（`ui.persistence_enabled=false`），不默认截图。

- 范围预检（不算通过）：`& tools/check.ps1 -Suite architecture,equipment,equipment_complete,links,composites,shoulder,torso_binding,casting,prison,events,slip_motion -ListOnly` → 退出码 0、`PLAN ONLY`、列出全部 11 个套件。日志 `build/checks/20260915T154755781-47440`。
- 规则门（验收者复跑）：同一 11 套件 `-TimeoutSeconds 900` → 退出码 0；11/11 `SUITE RESULT: PASS`、`PASS: 3509 assertions`；`build/checks/20260915T154809866-41232/summary.json` 的 `status=passed`、`before==after=089A94CB8229B7444E752F15A5FC2219079BF97ED3D9CB5F4985BD8DCF5F351D`，与实现者早前同一棵树的 `20260915T154200809-8364` 指纹一致（指纹稳定）。§11 具名检查随所通过的分类执行，未按条单独打印。
- 界面门（验收者运行）：`& tools/check.ps1 -UI -Suite architecture -UISuite equipment_complete,body_layout,shoulder,torso_binding -TimeoutSeconds 900` → 退出码 1、`summary=status=failed`（`build/checks/20260915T155153696-56180`）。architecture 规则 193 项通过；UI 在 `shoulder` 套件 19 项断言后失败 2 项：`SHOULDER UI compact cards show side and method`、`SHOULDER UI host card explains remaining-side penalty`；该次调用中 `torso_binding,body_layout,equipment_complete` 未执行。
- 归因（保持未定类，留协调者裁决）：上述失败在切片父提交 `16c89e9` 的临时工作树上复跑结果相同——`shoulder` `20260915T160616347-54344` 19 项断言、同样 2 错；`torso_binding` `20260915T160711923-52452` 11 项断言、1 错（`BIND UI attachment and independent durability are visible`）。根因是 `ui/release_details.gd:35-38`（git blame 落在 v0.17 提交 `e635bf5`）只为 `lock_only`／`is_special` 渲染 `card_status`，而既有检查期待普通件的 `card_status` 文案（"无法挣扎"／"肩带N条…×0.5"／"躯干固缚"／"独立连接耐久"）出现在 EquipmentDetails；与 B1–B9 的实现代码无关。归类处于"程序本身（既有 UI 文案渲染）"与"测试脚本（既有期望未随 v0.17 更新）"之间，无法确定单一归属；未自行修改，也未放宽断言。临时工作树已删除。
- 其余界面分类（验收者复跑，干净工作区）：`-UIOnly -UISuite body_layout,equipment_complete` → `20260915T161052970-53984` 245 项通过、退出码 0、`status=passed`、指纹稳定（此前一次 `20260915T160743098-42972` 因验收者临时脚本改变指纹被标 `source_changed`，仅记录 245 项断言结果，不称冻结通过）；`-UIOnly -UISuite route,events,prison` → `20260915T161152069-53156` 531 项通过（route 地图、prison 牢房、events 事件）、退出码 0、`status=passed`、指纹稳定。
- 人的路径证明：优先复用既有分类，缺口由验收者补充脚本补齐（运行时临时置于 `tests/`，跑完已删除；脚本与日志归档在忽略目录 `build/validator/validator_equipment_seam_paths.gd`、`build/validator/supplement-head.log`，`VALIDATOR PASS: 44 assertions`、退出码 0；工作区随后恢复干净）：
  1. 战斗中真实点开普通件详情：位置行与 View section 文本、耐久／紧度行与 View entry、View entry 与权威实例逐项一致 → 新补（`body_layout`／`equipment_complete` 复用了开合、位置标签与文案断言）。
  2. 肩带件：详情卡片数 = `Shoulders.attached`（2/2）、每件名称、视图 `card_status` 的"连接至宿主"= 权威 `_equipment_name(host)` → 新补；`shoulder_ui_cases` 的可见"无法挣扎"文案属上一条红项，不计通过。
  3. 复合组件与链接绳：链接绳卡片使用 View 名称、每张卡片耐久 = 权威件耐久、三次真实切割根套体后"遗留外带"出现且被移除件无残留卡片 → 新补（"遗留外带"复用 `equipment_complete` 既有断言）。
  4. 真实打出会损坏装备的牌（`strain` 经真实拖放提交）：详情显示新的耐久／紧度行且不再包含旧行 → 新补（既有 `release_preview` 只覆盖提交前数值预览）。
  5. 进入地图／事件／监室各一次：三项既有套件全通过（上条）；补充脚本另断言三处入口后 `_equipment_read.is_empty()`、`validate()==""`，并以 QuickSL 完成一次读档校验 → 新补。
- 未验证项与边界：未运行全项目 `all` 回归；未做 Android 真机验收；未独立复核 §8 的 oracle 基线与分批记录（不在 §12 命令内，属实现者证据）；界面门整体仍为 `failed`，`shoulder`／`torso_binding` 两项既有红未修复，本片不能宣称验收全绿或全项目通过。本次只读验收：未改产品代码与契约、未截图、未打包或发布。

## 2026-09-15 v0.17 发布

域：检查与测试、打包与发布。

- 用户要求Windows / Android打包、推送GitHub并发布v0.17；随后明确要求停止继续测试并直接发布。原已完成角色2、监狱、快捷解除、图鉴与立绘等工作随当前项目一并交付。
- Android通用PopupMenu接入独立触摸桥接；通过嵌入窗口入口处理原生选项，修复设置点选不生效、长列表覆盖打开按钮时误选；滑动不点选，取消不提交，系统返回键优先关闭选项框。游戏规则未因这次修复改变。
- 触摸专项20260914T154140815-7672通过23项断言，退出码0，源码指纹稳定；根指引检查及其5项单元测试通过。
- 全量尝试20260914T154351828-34328未完成。card_power中5项旧公共卡池断言未兼容新增小魔女专属卡；normal_play策略在零费失败留手法术上反复重试，诊断确认结束回合仍为有效候选。停止检查进程后汇总为failed，全量UI未执行。本次不宣称完整回归通过；未发布后续尚未验证的测试策略修改。
- Windows目录outputs/spire-v0.17-windows-x64-release-20260915：导出前后运行资源指纹一致；package-check-20260914T154921029通过PCK探针、角色2平衡探针与发布EXE独立启动。最终ZIP重新解压后23个清单文件校验一致。
- Android目录outputs/spire-v0.17-android-release-20260915：版本0.17、versionCode9、minSdk24、ARM64+ARMv7；V2/V3发布签名、provider唯一性、16KB对齐及内容包校验通过。android-probe-20260914T155014250包内资源探针通过。没有连接的Android设备，未做真机验收。
- 交付文件位于outputs/release-v0.17-20260915，均为正常无密码包，附SHA256SUMS.txt。源码/测试/资源/文档纳入对应提交；缓存、日志、玩家存档及签名秘密排除。

## 2026-09-15 点击／拖牌／快捷栏目标查询收拢

域：`ui/target_queries.gd`；契约 `release-interface.md`。

- 共用ui/target_queries.gd的10个只读查询；main、drag_targets、quick_release_bar保留原交互入口并转交共享筛选。模块不持有Game、控件或跨刷新缓存，返回原候选供既有ID＋版本提交；各入口原有去重、牌面、自动目标及首／末不可用原因顺序保持。RuleChangePackage见docs/release-interface.md。
- build/target-queries-20260915/compare.json记录空装备、多装备、复合与链接、拘束衣、长型单手套、监狱及特殊装备七场景；每场景1390项，共9730项新旧查询结果与顺序一致，完整状态和View未变。旧实现仅为忽略目录内诊断参照，不进入运行代码；本批不宣称帧率提升。
- targeting原分类新增17项契约断言，覆盖共享物理目标与两面、候选引用、返回容器隔离、首／末拒绝原因、捕缚额外目标、手牌去重、牢门、火球、指定ID顺序及失效版本；继续执行原真实点击和拖放用例。
- `tools/check.ps1 -UIOnly -UISuite targeting,basic_attacks,body_layout,keyboard,guard,equipment_complete,casting,card_power,exploration -TimeoutSeconds 600`：`20260914T145522480-63836`的card_power 307、basic_attacks 236、exploration 43、keyboard 87、casting 55、body_layout 147、targeting 100、equipment_complete 98、guard 87，共1160项断言全部通过，用时338.36秒。检查期间工作区变化，汇总为source_changed、退出码1；按修改时间发现同期英文目录、目录生成脚本和本地化测试更新，只记录断言结果，不宣称冻结源码门禁通过。
- 本批相关文件git diff --check无空白错误。纯UI查询重构未重复运行规则全量；未生成截图、处理存档、打包或发布。

## 2026-09-15 工具模块数据／规则分层

域：`core/tool_rules.gd`、`data/field_tools.gd`；契约 `game-design.md`。

- 20个读取对局状态的工具查询方法原样迁到core/tool_rules.gd，继承data/field_tools.gd的同一只读注册表；数据层保留3个纯方法，197→61行，移除core/contact依赖。g.Tools入口与规则算法保持；game、game_view、consumables改读规则模块，图鉴／掉落继续只读数据。23个方法正文逐项一致，无重复转发或第二份数值表。实施边界同步game-design.md与AGENTS.md。
- build/tool-boundary-20260915记录普通／复合链接／监狱／特殊装备×站坐卧×有无触手朋友的24组完整View和候选对照，以及33次正式安装／取回的返回值与完整状态对照，全部一致，查询保持状态。副本仅在忽略目录，运行源码只有一套实现；此批不以耗时或帧率提升为目标。
- 工具、高度和消耗品按Impact合并item_discard、consumables、encyclopedia、installed_tools、environment_height、casting。`20260914T144300639-62632`中item_discard288／consumables229通过，图鉴测试仍通过Book.Tools调用实时description而解析失败；改为neutral.Tools，保留图鉴与实时说明一致性断言。`20260914T144358099-59992`补跑encyclopedia506／installed_tools44／environment_height25／casting581，共1156项通过。
- 新增架构检查先修正了脚本反射写法（初次ListOnly即报告解析失败，未作通过证据），随后`20260914T144358082-58872`暴露测试错误地试图修改只读常量表；未改运行时放宽只读，而将断言改为继承表身份、常量只读与标签一致。`20260914T144518873-60540`：architecture158／exploration198／prison1255，共1611项通过，退出码0、指纹稳定。规则去重合计3284项通过。
- `20260914T144358099-59992`窗口encyclopedia170／installed_tools56／exploration43／items46通过；consumables原断言仍要求普通动作栏总有InstalledTool按钮，实际入口已迁到快捷栏。改为真实关闭抽屉、切换快捷栏、点击该工具，核对全身固定说明、精准物品和无行动消耗。`20260914T144702242-63500`补跑consumables52项通过，窗口去重合计367项。最后批次运行期间有同期源码变化，状态source_changed；仅报告逐批断言通过，不称整版冻结回归。原失败日志均保留，UI SCREENSHOTS:none。
- 存档专项继续延期；没有全项目回归、打包、发布或大版本完成宣告。此前记录中的data/field_tools职责混杂已在本批解决，其他大文件和图鉴／教程分层风险仍按后续独立批次处理。

## 2026-09-15 架构与接口边界检查

域：`data/field_tools.gd`、`data/encyclopedia.gd`、`data/tutorial.gd`；契约 `ui-scene-refresh.md`。

- 静态扫描core 45／data 26／ui 46，共117个运行脚本的显式load／preload依赖与UI对game的调用；检查主提交入口、候选索引、只读投影、只读查询生命周期、自缚临时状态及新增快捷栏／释放预览的职责。诊断范围与当时源码散列保存在忽略的build/architecture-20260915/audit.json。没有显式加载循环、core／data反向加载ui／tests或UI直接game.state／私有game方法调用；动态助手调用不由此静态扫描证明安全。
- 发现并修复两个间接越层读取：主立绘和身体栏通过Character.active(game)读取实时角色，可能与render(snapshot)的独立快照不一致。改为EquipmentPortrait共享显示策略，只消费已有character_id与固定立绘偏好；无新状态、规则、文案或存档字段。display补5项真实不同角色对局与快照交叉显示、两处一致、偏好覆盖及状态不变检查。契约见ui-scene-refresh.md。
- 保留职责不同的接口：physical_pieces／equipment_targets／action_targets查询范围不同；ActionIndex.find取首个匹配，first_usable取首个可用并在全不可用时返回末个，快捷栏first则保留首个不可用原因，不能按名称相近直接合并。正式UI行动仍统一进入game.dispatch，候选ID、版本与资格在支付前复核，事务复制状态后执行并在失败时恢复；未添加另一套执行入口。
- 未消除的维护风险：检查时game.gd约2848行、main.gd约2693行，分别集中大量规则协调与页面／目标选择职责。data/field_tools.gd兼具注册表及触及计算，data/encyclopedia.gd与data/tutorial.gd包含说明投影并引用core，共5条data→core显式依赖；目前无加载循环，但data并非全是纯数据。后续宜按物品操作、目标选择、展示投影等完整职责逐批迁出，保留现有权威规则及分类门禁。本次未为了缩短文件而整体搬移或统一掉不同语义。
- 首轮`20260914T142208740-61812`：architecture151项、display127／home113／equipment_art169／hero_art50共459项窗口断言通过。期间另一批单手套立绘修改了game_view、equipment_portrait、装备立绘测试及素材，报告source_changed，不能视为冻结工作区通过；本次共享显示策略仍完整保留。交叉文件重新导入并补跑architecture、display、equipment_art、hero_art，主页已通过且未涉及后续变化。
- `20260914T142425356-51572`：资源导入、architecture151项、display127／equipment_art176／hero_art50共353项窗口断言通过，退出码0且指纹稳定。随后继续审查新字段的完整传递，发现arena精简hero_view漏掉composite_portrait_layers，既有装备立绘测试只检查身体栏，未捕获战场立绘不一致。将精简显示数据生成收回EquipmentPortrait.snapshot并补短／长单手套在两处立绘一致及输入复制隔离6项检查。`20260914T142716643-60772`因新增测试误将局部变量用于类型判断而解析失败，其他类未执行；改为脚本常量后仅补跑失败／未执行的窗口分类，原失败报告保留。
- 修正后`20260914T142750772-9268`：display133／equipment_art176／hero_art51共360项通过，源码变化仅为同期hero_art测试补充；两项运行代码修复均保留。最后只复核该变化分类，`20260914T142918982-56744`的hero_art51项通过、退出码0、指纹稳定。按各分类最终已执行结果去重，本轮architecture151项，窗口display133＋home113＋equipment_art176＋hero_art51＝473项逐批通过；不把多轮混合结果称作整版冻结全量验收。无默认截图。
- 本轮检查不等同全项目逐条玩法验收；存档专项继续延期，没有打包、发布或大版本完成宣告。

## 2026-09-15 快捷栏重复选择优化

域：契约 `equipment-performance.md`。

- 只读UI优化包与分段测量见equipment-performance.md。同一格更新只解析一次部位和装备；原候选、排序、精准选择和具体原因保持，不跨同版本的UI操作保留缓存。新增10项检查覆盖换目标、翻面往返、过期版本、缺失部位／目标、主动选择空部位、候选身份及View／状态／控件不变。
- `20260914T141124582-58372`：`tools/check.ps1 -UIOnly -UISuite basic_attacks,keyboard,body_layout,targeting,equipment_complete -TimeoutSeconds 600`，分别236／87／147／83／98，共651项窗口断言全部通过，退出码0、指纹前后一致、summary.status=passed。包含正式出牌、火球、降紧／开锁、原生拖放、键盘和详情开关。测试中窗口最小化导致绘制等待，恢复同一窗口后完成；因此总369.57秒不是运行性能数据。UI SCREENSHOTS:none。
- 五场景9600组新旧显示及候选逐项一致，默认四格全卡牌扫描空闲16→8、带选牌24→4；已记住选择的路径另测，空闲扫描没有下降且密集样例计时回退，具体数据及限制完整保留。诊断副本只在忽略的build目录。
- 本批纯显示选择优化，按模块约定只跑以上受影响窗口分类，没有全项目规则回归、存档跟进、打包或发布。

## 2026-09-14 小魔女扩展与脱缚练习

域：契约 `character-two.md`。

- 规则包见character-two.md最新扩展段。初始11张、每部位无限预备／每回合一次成功释放、五张新奖励牌、两面混合牌类型、回合增益和强制锁回合均沿正式候选提交。脱缚练习两面共享实体进度，按1×3／1×6／2×6／3×6逐段结算，10／20／30／40次后进化；累计1张而非累计段数，跨战斗保留，卡组与牌堆进度不一致拒绝恢复。
- 初次合批20260914T133646540-24076中card_splash144、architecture151、persistence597、pressure1076通过；其间源码变化，标记source_changed，不作为冻结全量结果。card_expansion的休息限制优先级修复后，20260914T134345605-3048中card_expansion1088、encyclopedia506通过。图鉴旧数量断言已改为按角色过滤。
- 连续开锁旧用例写死入狱魔力100，实际夹具入狱后为80；改为核对真实入狱值扣除本次支付，保留连续开锁、一次付费和临时魔力优先断言。20260914T134638179-22204中rewards666、localization73通过；窗口encyclopedia170、localization51通过。home的旧断言未展开新“装备说明”折叠层，补正式点击后20260914T134844634-62396 home113通过，指纹一致。
- 最后增加同一初始牌依次打出两面、同阶段卡组／牌堆累计差异的回滚检查；20260914T134754114-43468 witch_character455断言通过，指纹一致。窗口覆盖角色2实际选角、预备／释放、释放后自动切回，图鉴角色选择不改对局、五个进化阶段同页、初始稀有度、两面红色警告和分面技能／魔法分类。
- 本批只报告上述受影响分类与补跑结果，没有全项目回归、截图、打包、发布或大版本完成宣告。

## 2026-09-14 墙缝高度与安装工具状态栏

域：装备与解除、检查与测试。

- 位置名称从固定高度表生成，详情、候选、地块与日志共用；不改变安装 ID、触及表、费用或存档。
- 只将正式候选中可触发的安装工具投影到角色状态栏及“环境”分类；沿用道具图标，角标显示次数，点击打开对应详情。随身切割工具和可用药剂不加入；无次数、离墙、不可触及及非行动阶段不显示有效工具状态。预览及点击详情均不改状态或随机。
- `20260914T124451422-55624` 资源导入通过；修正新增英文模板参数后，`20260914T124647878-50060` 的 localization 分类73断言通过。
- `20260914T124714118-55180`：installed_tools/environment_height/exploration/status 规则566断言通过，installed_tools/exploration 窗口99断言通过。期间其他源码仍有修改，门禁标记 source_changed；这些为已执行断言结果，不宣称冻结工作区全量通过。
- 状态窗口旧测试将费用徽标也拼进标题，错误要求整个控件文本以“深呼吸”开头；改为检查实际标题控件后，`20260914T124949797-19420` 的 status 窗口58断言通过。未截图、打包或发布。

## 2026-09-14 拘束具图鉴关键数值与限制补全

域：契约 `equipment-design.md`。

- 按用户要求保持简短，只扩充既有条目。普通装备补品质、紧度分档、锁效果；四种口球列出品质与紧度倍率和三档合计，眼罩说明意图遮挡与马具影响。复合装备显示各组件耐久／方法及关键解除前置；链接补向下1.25加成；特殊装备补取出条件与费用、刺激倍率、环境要求、电量耗尽仍保留、平板锁的已有特殊效果。口球按当前规则填写，没有新增假阳具款禁施法效果。RuleChangePackage见docs/equipment-design.md。
- 20260914T124657697-59256：localization73／architecture151／encyclopedia493／content380，共1097项规则断言全部通过；encyclopedia窗口79项通过，实际搜索并选中普通假阳具口球，核对0.25品质倍率及0.375／0.25／0.125三档合计，浏览不修改状态。UI SCREENSHOTS:none。
- 运行期间有同期源码变化，报告为source_changed，不作为整版冻结验收；本批只补文案与只读图鉴，未更改规则、存档、随机或发行版本，不打包。

## 2026-09-14 全卡牌双面资料与跨部位装备投影合批

域：契约 `equipment-performance.md`。

- 完整83种牌型仍供图鉴、奖励和牌堆浏览；双面正文与metadata分别一次生成，普通牌型card_info重复工作4→2。按两面各自费用、原显示精度、动态数量和实例成长生成，不冻结规则注册表。装备基础资料在既有只读上下文按权威实例复用，各部位拿独立副本并设置slot。影响包、旧接口语义与结果见docs/equipment-performance.md；玩法、事件、随机、数值、支付和玩家文案保持。
- 20260914T112226775-48592：architecture151、encyclopedia399共550项通过；源码同期变化，状态source_changed。新增装备检查覆盖跨槽内容、返回值污染、复制目标、临时状态和同版本耐久修改；保留完整只读View、候选与引用检查。
- 20260914T112702588-52316：witch_character224／card_power1671／card_expansion1083／card_growth20／architecture151／encyclopedia399／content380／casting565／special_equipment332／equipment_complete448，共5273项规则全部通过。卡面新增检查覆盖三个快感值、全部注册牌型、独立两面费用、内联数值舍入、规则表即时修改和成长／般若汤实例。
- 同批窗口card_power307／encyclopedia76／casting55通过；card_growth11项只有1项旧UI前提失败：它要求候选全文默认可见，但现有ReleasePreview已改为摘要＋“效果详情”展开。更新为先核对正式headline／change，再真实点击展开核对candidate.detail，保留真实出牌、成长与牌堆浏览。后续三类未执行，未标绿。报告source_changed，失败证据保留。
- 20260914T113235836-13300只补card_growth13／special_equipment52／body_layout147／equipment_complete98，共310项窗口通过，前后源码指纹一致，状态passed。无截图。其余已通过分类沿前述报告，不将跨批结果称为全项目冻结验收；本批三个运行文件与规则门禁前备份一致。
- 五场景新旧完整投影及全部83类metadata逐项相同，状态与随机游标未改变。完整刷新首测有明显负载波动，另以相同正式候选单独计量显示生成；15个有效交替配对的新／旧比值中位为空装备0.823、29件0.886、拘束衣0.755、复合链接0.743、特殊装备0.745。这里只报告显示阶段，不冒充整帧提速。初次基线词表未加载动态注册变体的诊断无效，纠正诊断初始化后复测，无引擎／脚本错误。数据和限制见性能文档。
- README和既有性能／引用文档同步。无旧档迁移、帧率设置修改、打包或版本里程碑宣告；诊断与基线仅放忽略的build/projection-batch-20260914。

## 2026-09-14 继续优化解除预览与候选费用

域：契约 `equipment-performance.md`、`equipment-reference-audit.md`、`content-generation.md`。

- 单次只读刷新按完整参数复用解除／施法预览，输入键和返回嵌套容器隔离，临时状态绕开原缓存，退出即释放；正式执行重新计算。卡牌逐目标候选按牌面共用费用，不改资格、数值、支付、随机、正文或存档。RuleChangePackage和测量见docs/equipment-performance.md，调用及引用说明见docs/equipment-reference-audit.md。
- 20260914T110022875-18612：architecture145项通过，包含24项新增检查；由于同期源码变化，状态source_changed。新检查涵盖全部四个布尔参数的16种组合、三种方法、极近浮点基础值、嵌套辅助档案、输入／结果修改隔离、复制目标、临时状态恢复及复合／肩带／躯干连接／特殊装备连续正式出牌。
- 20260914T110309543-53012按casting、equipment、hand_assist、slip_motion、card_splash、architecture的Impact展开36类；已执行30类共9653项，前29类全部通过，core657项仅TC-ENEMY-0003失败，后6类和窗口未运行。失败仍要求离场施加中级2档，而docs/content-generation.md和正式声明已固定中级3档；更新该单项旧预期，保留真实准备、行动和最终离场检查。报告有同期源码变化，保留原失败记录。
- 20260914T110819356-47620只补core及前批未执行的equipment、links、composites、equipment_complete、prison、trader，2870项全部通过；窗口使用实际登记的card_power307／card_splash12／casting55／equipment_complete98，共472项通过，无截图。此前命令中的card_expansion没有对应窗口分类且窗口尚未启动，补测按正式注册入口选择，未新增或伪造分类。36类规则的断言至此逐批通过，但两批报告均source_changed，不合称当前整版冻结验收；本轮game.gd、card_effects.gd、architecture_cases.gd与测试前备份一致，不覆盖同期改动。
- 最终独立交替性能对照无引擎／脚本错误，0／12／29件完整显示、各次查询只读及实际提交最终状态均相同。29件候选生成中位167.816→146.757ms，完整View266.329→237.540ms，样本出牌172.458→125.554ms；本轮与前批绝对时间不可跨负载拼接，空装备样例收益不稳定。解除实际计算264→149、施法217→10、魔力费用231→175。一次被同期测试文件改写打断的诊断保留为paired-interrupted.log，其数据未用于结论。
- 同步README、AGENTS和既有两份性能／引用文档；不迁移旧档、不修改帧率偏好、不打包或宣告v0.17完成。诊断副本与计数器只在忽略的build/equipment-preview-20260914目录。

## 2026-09-14 出狱新地图普通战斗统一强怪池

域：契约 `prison-release.md`。

- 到期出狱与击败出口守卫重建地图时，将全部普通房间的已有pool字段设为strong，实际入场继续沿原随机与连续不重复选择。精英／Boss、通关后塔底重新开始的前期弱怪保持。先选商店、退出起点选择或保存恢复不清除配置；地图仍用普通战斗图标，房间说明、出狱日志和教程新增强怪池说明，中英文同步。规则与影响边界见docs/prison-release.md。
- 20260914T101221506-56428：localization71／architecture69／content380／prison1203项通过；tower因测试种子42生成的第10—11层没有商店，索引空数组导致1个引擎错误，保留失败报告。测试改用实际有合法商店的固定种子47，补非空断言；读档比较沿既有same排除恢复时更新的版本号，提交后重新取得真实房间引用，不使用旧事务前对象。
- 20260914T101717427-56212：tower292项、prison窗口209项全部通过。覆盖两种出狱标记、第一场及连续多场强怪、不重复抽取、先选商店、保存恢复与敌人名单一致、强怪房间被篡改成弱怪时原子拒绝、正常新开反例及地图说明／图标。各分类用例通过，但运行期间另有源码变化，报告状态source_changed，不将其作为整版冻结验收；不为同期变化重复跑全量。窗口无新增截图。
- 无新增存档字段、快照修订或历史存档迁移；不打包、不发布，不宣告大版本完成。

## 2026-09-14 出狱练习按正式监狱重做

域：契约 `prison-release.md`。

- 用户反馈旧练习空身、登记清单为空，预装工具被没收后便直接合格。到期与延期练习改用正式Guard.capture生成收押装备、链接和完整登记清单，先显示收押结果，玩家确认进入牢房后从第1回合、已服刑0／20、巡视剩余16回合开始。移除19／20回合和预装工具夹具，不预设检查结果；出口守卫练习保留正式收押装备及正常敌人血量。菜单、说明、提示和英文同步，正式监狱规则及快照结构保持；RuleChangePackage见docs/prison-release.md。
- 首轮20260914T075836722-41224：localization71、architecture69、content380通过；prison1194项仅1项失败，原因是测试错误要求出口战斗开场之后仍恰好8件，遗漏正式开场追加的2件。诊断确认收押为8件普通装备、2件特殊装备和1条链接，出口战斗为10件；修正为收押时精确核对配额、战斗后保留正式追加。首轮存在源码变化，不作冻结验收，失败记录保留。
- 最终20260914T080116670-50964：prison1196项、prison窗口208项全部通过，源码指纹稳定，状态passed。覆盖真实收押确认、非空清单、完整20回合、第16回合巡视、已登记装备缺失导致补装和延期、8个追加回合及存读档一致、10—11层起点按钮和正常守卫生命。窗口未生成截图；UI边界案例只在确认真实入狱后加速一次到期检查，完整计时另有规则及真实窗口点击覆盖。
- 不打包、不发布，不将本次练习修复视为v0.17大版本完成；旧练习进度不迁移，需从练习菜单重新开始。

## 2026-09-14 大量拘束具性能与对象接口追踪

域：`core/game.gd`、`assets/localization/legacy-en_US.json`；契约 `equipment-reference-audit.md`、`equipment-performance.md`。

- 已按用户补充要求沿普通件、复合根／部件、肩带、链接绳、躯干连接和特殊装备逐类追踪创建、存放、查询、候选、事务、删除与UI。9个正式练习场景目标ID唯一、查询返回权威实例、读批次结束释放索引；引用列表及动态调用边在build/equipment-performance-20260914，说明见docs/equipment-reference-audit.md。
- 29件、5张手牌、200候选的一次get_view中，equipment_at1694次但只实际筛选13次，堆叠264次但只实际计算29次；_candidate原每目标重复查3次改为1次，该路径600→200。body_sections也复用查到的对象。索引只覆盖一轮只读调用，临时state绕开，提交和清理不复用；折叠详情首次展开才创建动作树，重复开合不再重复建节点。
- 原生窗口29件样例完整View147.735→87.390ms、候选95.131→46.767ms、手胸详情刷新中位33.444→26.595ms。0／12／29件完整View与优化前逐项相同，快照只读；最终代码的无索引／有索引11次对照，29件View中位162.136→93.422ms，正式出牌7次中位107.031→54.667ms且最终状态一致。具体数据及局限见docs/equipment-performance.md，不将一次样例当成全设备帧率。
- 首轮20260914T102147204-42804：12类规则5955项，card_power1661／card_expansion1083／relics848／application71／architecture107／runner431／casting565／special_equipment332／links165／composites90全部通过；equipment154与equipment_complete448合计11项旧前提失败。错误涉及离场档位、新监狱练习开局及限制项圈固定生命周期，不是索引输出不一致。第一次更新遗漏守卫练习已清空收押报告，20260914T102549544-49100保留失败；修正为检查正式入狱配额、真实链接及守卫战阶段后，20260914T102713460-21548两类602项全部通过，源码稳定。
- 20260914T102847180-2600窗口1180项：card_power307／display122／keyboard67／special_equipment52／body_layout147／targeting83／equipment_complete96通过；localization51中3项缺英文，services255中1项旧“紧度 1档”空格断言失败。补齐现有主页原角色说明及“双腿”英文，生成词表同步；旧标签测试按当前“紧度1档”更新，未删除可见数值检查。
- 最终20260914T103645837-17220状态passed，源码前后指纹一致：localization71／architecture121／equipment154／equipment_complete448，共794项规则；localization51／services255／equipment_complete98，共404项窗口通过。新增实际解除后旧装备详情节点释放、按钮索引无脱树节点、目标唯一与权威引用检查均通过。其他已通过分类沿用上述报告，不将多批结果合称全项目验收。
- 更新AGENTS及性能／引用说明。所有本次窗口检查未指定截图，未发送真实反馈，未新增存档迁移、改变帧率偏好或打包发布；v0.17仍在开发，不宣告版本里程碑完成。性能插桩只放忽略的build目录，游戏运行时代码不带诊断计时器。
- 收尾复核发现core/game.gd、tools/build_english_catalog.py和assets/localization/legacy-en_US.json在上述稳定门禁之后又有同期修改；本批读查询索引、重复查找合并及两项英文映射仍在。794项规则与404项窗口的通过结论仅对应报告记录的源码快照，不自动覆盖这些后续改动；没有覆盖同期工作或重新宣告当前整版全绿。

## 2026-09-14 项目跟进：身体栏复用与测试入口补齐

域：契约 `ui-scene-refresh.md`。

- 跟进当前四区解缚、场景复用、魔女角色及近期监狱／卡牌／遗物变更。扫描115个运行脚本、223条字面脚本依赖，未发现循环、失效路径、core／data反向引用UI、UI直接game.state访问或至少5行的重复完整函数体；这是静态限定检查，不等于所有接口或玩法均无问题。证据在build/progress-optimization-20260914/final-structure.json。
- 身体栏显示事实未变时保留部位按钮、滚动容器和输入映射；区域滚动不再因普通刷新回到顶部。失效覆盖语言、真实计数／占用／解除标记、焦点、展开顺序和高度；回调只持有稳定部位ID并读取当前候选，不保存旧View、装备图或候选。影响边界见docs/ui-scene-refresh.md。
- 首轮20260914T073306145-19316发现witch_character_cases未登记归属；补上唯一witch_character规则分类和17个实际交互区域，并列入当前开发分类。没有复制或删除原测试，最终224项角色规则全部执行通过。20260914T073345856-35224复现按钮重建／滚动复位／等价投影重建；新增焦点断言也纠正为实际选中hover色，原样式没有改变。
- 修复后20260914T073524855-48352：当时的规则716项通过，touch18／keyboard67／body_layout136／targeting83／equipment_complete96项全部通过，共400项交互断言；display121项中只有原音乐连打失败，未记整组通过。该报告源码稳定，保留失败记录。
- 音乐定位报告20260914T073755935-43964与20260914T073905346-49500确认音源相同、播放位置正常前进，但第二次实际出牌剩余0能量，正式候选拒绝。测试夹具显式准备10能量并新增点击前正式资格断言，保留实际消耗、暂停、进度和循环检查；未改播放实现或游戏费用。20260914T074007901-7688的display122项通过，但同期其他源码变化，不能作为冻结验收。
- 最终20260914T074057043-50376状态passed、前后源码指纹一致：witch_character224／architecture69／runner429，共722项规则；display122项全部通过。五类交互沿用前述报告，不把跨批次结果合称全项目回归。所有本次窗口检查UI SCREENSHOTS:none，未发送真实反馈，未新增旧档适配。当前v0.17仍有其他在途功能，未宣告里程碑完成或触发版本提交／推送／打包。

## 2026-09-14 场景拆分与立绘按需刷新

域：契约 `ui-scene-refresh.md`。

- 主布局、顶栏、身体栏、角色立绘、敌人分组、装备立绘拆为 6 个 `.tscn`；运行代码仍消费原 View 和候选。没有合并旧 PR、改变规则、重写文案、修改版本或发布包。规则说明与影响边界见 `docs/ui-scene-refresh.md`。
- `display` 增加真实绘制计数和实例身份检查：连续三次普通界面更新保留布局、主角、敌人和装备立绘，三个立绘绘制计数均为 0；程序绘制敌人静置 12 帧重绘 0 次；没有空闲 `_process`，姿势恢复、固定立绘忽略无关变化、无关／对应素材变更和游戏快照只读均检查。
- 初轮 `20260914T031721707-1144`：display／equipment_art／hero_art 共 326 项通过、源码指纹稳定。补充固定立绘和素材变更反例后 display 为 111 项。
- 扩展检查发现复用身体栏与商店新面板的鼠标层序冲突，已在本批次修正：身体栏恢复原兄弟顺序，不再只依赖 z_index；收起时释放该栏。原有真实鼠标检查保留，未放宽断言。临时定位输出已移除。
- 修复后 `20260914T032632664-30612`：display 111、services 255、consumables 49、rewards 307 项全部通过；interface 353 项中 352 通过，唯一失败是工作区已有 17 张新增魔女卡牌缺少插图。合计 1075 项、1074 通过；不标成整组通过。此前 body_layout 97、targeting 91、installed_tools 43、home 110、route 134、equipment_art 168、hero_art 50 项通过，详见 `20260914T032010796-7892`，该报告包含已修复的界面失败，不作为全绿证据。
- 移除临时诊断打印后的连续切页收尾报告 `20260914T033053718-6868`：display／home／route／services／consumables 全部通过；interface 仍只剩上述魔女卡图缺失，合计 1012 项、1011 通过。没有放宽原交互断言，也未把已知失败标绿；运行前后源码指纹一致。
- 其他在途门禁问题保留：`20260914T031830111-47100` 的 architecture 69 项通过，runner 因 `witch_character_cases.gd` 尚未登记归属失败；`20260914T032010796-7892` 的 localization 因新增主页角色选择文字缺英文失败。没有覆盖这些在途功能或删除失败检查。
- 各次检查使用独立 APPDATA、既有检查入口和限定分类，`UI SCREENSHOTS: none`；没有新增验收截图，也未发送真实反馈。大版本完成后自动提交推送源码的规则已写入两级 AGENTS.md，本次不提前发布在途 v0.17。

## 2026-09-14 角色2平衡修订验收

域：契约 `character-two.md`。

- 规则与界面范围见AGENTS.md「角色2第二批平衡修订」、docs/character-two.md。最终补充开局Boss交换按角色实际初始遗物读取名称、资格并移除正确遗物；不能仍向角色2索取余烬护符。
- 稳定检查20260913T141159390-60236：core/relics/casting -Impact一次展开22个相关完整分类，8983项规则断言通过；home/status窗口168项通过。涵盖原角色回归、专属新局75/75/50与护符、战斗阶段限制、新遗物、2层抵挡、分部位伤害/清空、精神集中保留和乌龟壳、失败退款与减层、分面消耗、增伤预览、原生切换及自动回切。
- 最后开局交换及内容补全后，稳定检查20260913T141724506-31156：localization/encyclopedia/content/services/persistence/core共2575项通过，home窗口110项通过。追加魔术手实际连续降低4档（部位目标移除后顺延全身）、30魔力只付一次、过期回滚、最终消耗一次及真实开局遗物交换；没有用只读定义断言代替实际执行。
- 首轮core失败源于伤害调整后旧胜利夹具仍按旧伤害假设击杀；调整明确夹具蓄力层数后复验。首次扩大检查遇到新SVG尚未导入造成预加载错误，随后通过正式-Import导入再完整重验；失败报告保留，不宣称其为通过。
- 两份通过报告各自源码前后指纹一致；不把不同源码批次合并宣称全项目all。git diff --check通过；无全量all、长程随机试玩、打包或发布。当前源码保留其他任务既有修改；旧0.17交付ZIP不覆盖。

## 2026-09-14 角色2平衡版Windows完整包

域：角色与美术、打包与发布。

用户授权打包当前项目，本地交付、不发布。build/package-witch-balance-20260914导出源码指纹前后一致；成品check-package -ChargeAll -WitchBalance通过，日志build/package-check-20260913T143629354。验证0.17版本、原角色/角色2、75魔力与快感上限、50魔瓶魔力、魔女护符、魔术手新效果、两件专属SVG、12份外部内容包、存档与真实释放清空、独立EXE启动。最初成品探针沿旧夹具注入100魔力超过新75上限，故被正式提交校验拒绝；修正探针按实际mana_max补满后通过，未修改玩法。

ZIP解压后逐一核对23份文件的大小与SHA256，总计24 个文件含manifest，全部一致。交付紧缚尖塔demo-v0.17-角色2平衡更新-Windows64.zip，135294326 字节，SHA256：3d948be397b926f59884d4d34e706f0c40e13e46884d0d07afd26f356c3fdb08。未覆盖旧交付、未含存档，不制作Android。此前功能专项记录保留，本次只做成品检查。

## 2026-09-14 反馈1847ba708526785c2322abae5cdd7561

域：战斗与敌人、架构与接口。

用户确认截图开局启用了无限效果模式。反馈文本是第8层战后整备、截图是第11层第50回合；缺少实际存档，不声称按种子精确重放了两者之间的整局操作。以该种子、两名mixed_bundle、无限模式高保留系数建立明确状态夹具，经正式end复现每轮0能量和持续中断：回合增加，敌人每轮只执行一次；首次草拟夹具在开场后才切卧姿，会合法跨越“旧回合玩家先手、下一回合敌人先手”的两个敌人阶段，已改为开场前设置真实卧姿，不能把前者误报为重复结算。

根因：无限模式的回落值接近阈值，回合开始的持续来源再次触发强制状态；同时原surrender候选排除了overloaded，导致普通行动与投降都隐藏。修复保留战斗中的正式投降、原二次确认、版本复核与完整收押事务，不调整无限效果、资源、敌人行为或end管线。普通警戒进入牢房后仍可能继续受设备影响，不强行清除该模式；截图警戒4时投降沿原规则进入警戒5的终局。整备复现从3回合连续提交至0并回地图，已击败敌人不再施加装备。

验证：20260913T185256036-42504改动前最小回归仅“中断期间保留投降出口”失败，确认覆盖缺陷。扩大交叉检查20260913T185329577-34216的其余12分类通过；pressure两条旧预期分别错误地要求入狱不再受无限效果、练习只允许继续，已按本次规则修正。最终20260913T185531623-49552：prison/pressure完整规则1753项、pressure窗口79项全部通过，源码前后指纹一致。覆盖反复继续、不重复敌方阶段、整备结束、版本过期回滚、重复投降拒绝、普通/警戒4退出路径以及实际投降按钮两次点击。git diff --check通过。未运行全项目all，未改或重新打包已交付0.16/0.17文件。

## 2026-09-14 离场怪附加装备加强

域：装备与解除、战斗与敌人。

RuleChangePackage：离场施加统一中级／紧度3。Balance登记离场grade=2/tier=3，EnemyPlans.application对final声明统一使用；安装能力扫描与实际意图同源。漂浮锁固定平板锁来源同用常量，开启锁池后维持固定类型／无概率／无法佩戴仍离场，正常紧度3规则自动附带中级加固带。漂浮口球由初级2档升至中级3档；四种基础材料怪由中级2档升至中级3档。原非离场施加仍初级2档，其他持续型敌人不变。

影响等级、紧度、所导出的耐久／部位限制与附属组件；资格、模板池、数量、锁规则、来源、替换、回合、准备／打断、失败离场、死亡取消、奖励、随机域、存档结构不新增接口或分支。原安装与日志直接使用新规格；图鉴中英及词表同步。十四交互轴仅等级／紧度及原规则连带效果改变。既有enemies案例覆盖实际附加、非离场反例、打断／死亡、无空位、概率两端、存读和奖励；窗口检查真实口球附着规格。不打包。

## 2026-09-14 魔路精通与 henshin 费用

域：契约 `game-design.md`。

用户最终确认为两个角色共同更新、henshin拘束面＋1（3费）、自由仍4费；魔路精通两面互斥，不同时存在。RuleChangePackage见game-design.md同名章节。卡牌说明、状态条件／次数、失败实付来源退款和回能日志、互斥候选拒绝、中英文资源均同步；不重发旧版安装包。

最小及边界案例沿card_power扩展：纯自身／混合／纯临时支付、正数耗魔条件、实际0费卡前两次及第三次、成功及复放反例、2/2→3/2→3/3→2/3动态限制、降级不刷新配额、下一回合重置、失去／恢复等级、两角色共享注册、同面及另一面重复提交原子拒绝、存档次数及非法状态、整备清理、henshin普通与完美版分面费用。旧henshin批量解除和捕缚案例按3费修正输入与付费期望，非费用机制保持。

初轮card_power有1条批量解除旧2费断言失败，源码期间还受到其他批次修改，不记通过；后续修正。英文兼容表初次追加用了printf形式目标参数，被加载器正确拒绝；改用{p0}后localization通过。20260914T051707385-38532中localization 68与card_power 1596通过，其card_expansion有3条捕缚夹具仍给2能量而失败。修正夹具后20260914T051755588-46308：card_expansion 1082、architecture 69、content 380、casting 564、persistence 585全部通过，源码指纹稳定。core仅TC-ENEMY-0003的敌人离场紧度旧2档断言失败：工作区另有离场附加改成中级3档的修改，不由本次卡牌调整引起，本次没有覆盖该改动或将core记为通过。

验证：首轮build/checks/20260914T051444647-46880/summary.json的唯一规则失败为混合遭遇口球旧初级断言，已同步为中级3档，并补齐练习入口旧文案。复跑build/checks/20260914T051739888-16116/summary.json：enemies/architecture/content/localization规则2278项、enemies窗口213项全部通过；同期其他任务修改源码，整轮状态为source_changed，不声明冻结版本整体Verified。新规格、平板锁加固带、原离场边界与实际界面操作均无断言失败。本批未截图、打包、发布或推送大版本。

## 2026-09-14 传送符入狱保留

域：监狱与收押、检查与测试。

RuleChangePackage：传送符声明 keep_on_capture，统一收押流程过滤没收名单并按实际移除数量记录；主动投降、敌人收押及五级监室均保留原实例、次数与顺序。无需新存档字段或迁移，不重复发放。其他道具仍没收，巡视检查、使用消耗、主动丢弃、使用资格、容量、回合、随机和装备规则不变。十四交互轴仅涉及道具生命周期与收押，其他不变。

玩家文案同步道具详情、图鉴共用说明、收押词条、教程及警卫练习说明和英文回退。机械日志继续报告真实没收数量，无新增叙事事件。复用 prison／guard／architecture／content／localization 分类，覆盖实际投降与敌人收押、五级边界、旧候选回滚、实例次数保持、快照恢复、普通道具反例与共享说明；不新增窗口、截图、打包或发布。

20260914T051926160-7184：relics 786项及card_power窗口302项断言全部通过，但运行期间其他批次源码改动导致source_changed。补做20260914T052204848-40212，同样786项规则／302项窗口断言通过，仍检测到工作区源码变化，因此两次均不标记稳定源码整体门禁通过，不无限重跑并行修改中的工作区。既有稳定运行中的card_power、localization、card_expansion、architecture、content、casting、persistence结果分别保留；core的无关旧敌人数值断言仍如实记失败。git diff --check无空白错误。本批源码完成，未打包、提交、推送或发布，不作为新的大版本里程碑完成声明。

验证完成：20260914T052724734-42644 的 localization／architecture／content／prison 通过；guard 最后一条回滚断言误把恢复后递增的版本号与原快照比较，改为与恢复后的提交前快照比较。20260914T053035005-44188 仅重跑 guard，40项通过。相关五分类合计1336项通过，两次最终运行均无 source_changed；非全项目回归，不打包。此前失败包括旧“再次收押没收传送符”断言及入狱背包必须为空的校验，均已修正。收押阶段校验与存档恢复现只允许带 keep_on_capture 的道具保留，其他道具夹带仍拒绝且回滚。

## 2026-09-14 体术动作格字号与居中

域：契约 `game-design.md`。

名称与实际伤害以整行测量后同排居中，默认18号、长招式最低16号；费用／标签居中显示，默认14号、长行最低12号。右下快捷键维持11号原样并预留对称安全区；轨道、候选、点击／右键切换／拖动／禁用条件不变。具体RuleChangePackage见game-design.md对应章节。

20260914T053122276-45688：architecture 69＋basic_attacks窗口79项通过，源码稳定。检查现有ui-basic-action-rail.png及ui-basic-attack-forms.png发现火球费用标签尾部省略，改为紧凑分隔并按长度适配字号。20260914T053334413-42704：basic_attacks 84、touch 18、keyboard 67项窗口断言全部通过；期间工作区其他main.gd改动造成source_changed，不能作为整体稳定通过。最终20260914T053516805-25700：basic_attacks 82项通过、源码指纹一致（不启用截图，因此比带截图运行少2项）。截图已人工查看名称／伤害同排、连击长名完整、火球费用／次数／成功率完整、快捷键无遮挡。git diff --check无空白错误。不打包、不发布，不修改正在进行的其他装备UI改动。

## 2026-09-14 墙缝道具遮挡与捕缚移动限制

域：塔路与地图、界面。

RuleChangePackage：UI安装工具面板从魔瓶区域移至体术栏右侧／非战斗手牌上方；体术格仅在存在已安装工具时预留宽度。CaptureBind提供共用移动拒绝原因，wall_move候选与正式提交复核禁止捕缚中的两方向移动，移动按钮灰置并直接解释。状态／图鉴／教程与英文兼容目录和人工词表同步。影响捕缚行动资格及界面布局，无新增状态、事件、随机、存档字段或迁移；能量、距离、姿势原规则、装备／层级／锁／材料／目标、伤害、工具触发／次数、回合与其余十四交互轴不变。拒绝无机械日志；已有捕缚与移动成功日志保持准确，非UI叙事N/A。

最小正例、无捕缚反例、两方向边界、旧候选复核和原子回滚加入wall现有分类，覆盖三种来源及解除恢复。guard窗口验证真实第三回合施加后按钮灰置和具体原因；installed_tools窗口验证面板不覆盖魔瓶／体术、真实鼠标存入与新入口打开。复用完整wall／guard／installed_tools／enemies／content／localization／architecture规则及installed_tools／guard／wall窗口；结果待记录。本批不截图、不打包、不发布。


本批结果：20260914T054719458-47044 的七项规则分类2530项全部通过，installed_tools与guard窗口通过；wall窗口发现禁用提示挤入姿势行及另一批身体详情改动的空脖颈缺失。已修正本次提示布局：紧凑行直接显示具体拒绝原因，普通贴墙状态保持距离提示；非战斗工具栏缩至32高并压缩内边距，验证与真实手牌、魔瓶均不重叠。20260914T060238373-44540 相关六类规则769项通过；wall窗口的移动布局及新非战斗面板断言通过，仅空脖颈详情旧检查仍失败。guard新增位置断言初版没有处理高潮时无姿势栏的情况，已改为检查存在时不重叠。

最终20260914T060515825-18304：installed_tools／guard完整窗口95项全部通过，源码指纹稳定。实测安装后魔瓶存入、工具入口打开和真实捕缚移动灰置；前两轮规则运行期间存在其他任务修改，按source_changed保留单类结果，不声明整个工作区全量通过。颈部详情断言属于另一批在途身体栏改动，未在本批覆盖或放宽；未打包、发布或推送。git diff --check通过。

## 2026-09-14 角色选择名称

域：界面、检查与测试。

RuleChangePackage：选择页角色1改为“魔法少女(futa)”，角色2改为“小魔女·测试版”。通过两个独立本地化ID显示，中英文与中文安全回退同步；内部original／witch标识、顺序、选中角色、新开／继续流程、角色规则和存档均保持。仅UI名称受影响，候选、数值、事务、事件／日志、非UI叙事、随机及十四规则交互轴N/A。既有witch_character窗口检查准确名称、选中后新局及切回原角色；localization／architecture分类复核资源与边界。不截图、不打包。

## 2026-09-14 魔力耳坠阈值30

域：压力与快感、检查与测试。

RuleChangePackage：每累计消耗自身魔力30点获得1能量，替换原20点。统一遗物注册数值、效果说明、英文回退与规则对照；计数显示和校验沿同一阈值读取。触发阶段、跨回合余数、本场结束清零、临时魔力排除、失败施法及退款逻辑不变；不增加状态、候选、随机或存档字段，其他交互轴不变。既有具名触发日志无须改写。复用 relics／card_expansion／casting／architecture／content／localization 完整分类，覆盖20不触发、29边界、30触发、跨回合与多阈值、兑换及余火交互；不打包。


验证：20260914T061242279-41644 的localization／architecture共137项通过。窗口分类最初误填witch_character（实际由home分类加载），未执行有效窗口案例；改用正式home完整分类。20260914T061525492-47556共111项检查，仅平板锁练习的上锁／加固带可见说明断言失败；本次两个名称、角色2开局及切回角色1的实际流程断言均通过。该失败涉及另一批在途装备详情UI，未修改或放宽；运行期间源码变化，整轮不标记通过。不打包。

魔力耳坠验证：20260914T061541360-47872 的 localization／card_expansion／relics／architecture／content／casting 六分类共2952项断言全部通过。运行期间工作区存在并行源码修改，门禁结果为 source_changed，因此不声称最终合并版本冻结通过；未打包或发布。

## 2026-09-14 四区解缚界面预览

域：契约 `release-interface.md`。

RuleChangePackage：docs/release-interface.md。UI 四区/单区展开、同部位外内层、共享物理目标去重、正式端点候选、前后耐久及衰减短提示；特殊装备仍显示电量与当前状态，长说明/公式按需展开。原动作资格和事务不变，不打包或发布。

20260914T060525904-40228：body_layout、targeting、equipment_complete、keyboard、touch 共359项窗口断言通过，源码指纹一致。含真实鼠标拖放、自由区域拒绝、跨区域目标替换、单目标预览与实际扣费/伤害一致、无回合检查和旧版本拒绝。之后增加特殊装备状态显示，并修正共享连接绳候选必须匹配当前部位。20260914T061425186-6328：special_equipment、body_layout、targeting 共228项全部通过，但并行工作区改动使该次状态为source_changed，不能作为最终稳定版本的发布门禁。

20260914T060525909-13704：localization 68项、architecture 69项通过；equipment的新增只读预览、零伤害、限制项圈开锁/取下事务案例通过。该完整分类154项中仍有4条 POOL grade independent of application tier（rope/belt/tape/cable_tie）断言失败，关联正在调整的敌人生成等级/紧度，本次未改其规则或旧期望值。display在20260914T055250277-45188中的场景复用检查通过，但 DUCK MUSIC repeated actual soup play preserves progress 未通过；未宣称整个display分类通过，未修改音乐逻辑。

预览图为显式选择的 build/ui-release-region-panel.png 和 build/ui-release-numeric-panel.png，仅截取区域入口与解缚详情，已人工检查外内层顺序、数值/倍率及按钮排版。未运行全项目发布检测。

最终窗口复核 20260914T061735866-22176：special_equipment、body_layout、targeting 共230项通过（含两张局部截图）；仍发生外部源码变动，状态source_changed。停止重复整批窗口测试，不将并行变化中的工作区标记为稳定发布版本。本次交付为可评审UI预览。

英文补充最终复核 20260914T062045304-684：localization 69项通过，源码指纹一致，包含四区动态件数及特殊装备主体标签。

## 2026-09-14 监狱期限与起点选择

域：契约 `prison-release.md`。

- RuleChangePackage见`docs/prison-release.md`。已实现分级刑期、单次检查最多延长8回合、到期施加与自动出狱、出口稀有三选一／遗物／60魔瓶奖励、8—10层非休息起点、倍率后的安全等级生命加成，以及两项正式流程练习。快照52，不迁移旧档，不打包或发布。
- 首轮`20260914T061623932-45708`：architecture通过，prison旧的连续巡视夹具因新刑期提前结束而失败；已将该夹具的后两次巡视倒计时设为1，继续验证真实检查／登记而不与独立刑期案例互相覆盖。
- `20260914T061906250-44988`：architecture69、content380、persistence593、rewards672、prison869、enemies1761，共4344项规则通过。运行期间补了召唤物跨收押的生命加成记录和英文文案，不视为最终完整指纹证明。
- 主页原先依赖练习顺序的音乐入口已恢复原顺序；新增出狱练习列于现有条目之后。`20260914T062451809-47736`：home111项仍有一条原有平板锁详情检查失败，与本批监狱规则和新增入口无关，未修改其断言或把该组标为通过。
- 复查`20260914T062524537-46312`：localization69、persistence593、prison870、enemies1761，共3293项规则通过；route134、prison155项窗口检查通过，运行前后源码指纹稳定。随后按用户补充排除宝箱房，相关规则、窗口文字与反例同步，并另跑最终专项。

- 用户补充“宝箱房也不能选”后，正式入口仅允许8／9／10层的battle／event／shop；rest／treasure同时拒绝，文案及英文同步。`20260914T063040663-3304`：localization69、content380、prison913，共1362项规则及prison155项窗口通过，源码指纹稳定。新增范围矩阵及真实非法depart拒绝／状态不变反例，没有用页面隐藏代替规则拒绝。
- 最后只补巡视确认前的处罚提示与英文，规则数值保持；另跑localization／content与prison窗口，结果随后记录。

- 最终提示复查`20260914T063524115-5108`：localization69、content380和prison窗口156项全部通过，源码指纹稳定；检查前处罚提示通过实际窗口断言。相关实现已完成，已知主页失败保持记录，不打包。

## 2026-09-14 自缚正式接入

域：装备与解除、卡牌与奖励。

稳定ID：self_binding；名称：自缚；正式生成：罕见X费技能，加入UNCOMMON／REWARDS，沿原商店、休息罕见选择、普通奖励与图鉴入口，两名角色共用。无保留／消耗／唯一标签，打出后正常弃置；沿已有self_binding.svg。

自由面：腿部随机佩戴2件普通拘束具，每件品质＋紧度＝2X；具体池为绳索／细绳／皮带／细皮带／胶带／扎带，腿部五类身体槽与精准位置、层级、容量均使用现有安装资格。无上锁、替换、链接或特殊装备生成。先确认存在可完整安装的两件组合；随机第一件必须给第二件留出合法位置，不能部分执行后回魔。主动佩戴属于卡牌代价，明确以Application内部voluntary参数跳过闪避与魔女蓄力抵挡，不消耗这两类状态；原敌人／事件施加默认仍可被抵挡，参数没有接为独立玩家命令。

拘束面：按原可加固的真实普通件／复合组件／独立肩带随机逐档收紧，总计2X档；紧度已3不算可收紧空间，不触发上锁额度，也不靠补附件凑档。实际收紧沿_reinforce_equipment与原刷新规则，原有锁不变，正常到3档的附属效果保留。当前完整容量小于2X时禁用整张牌；不改变装备、不扣能量、不回魔。两面完整执行后恢复15X自身魔力，受原上限限制，临时魔力／魔瓶不作为这项回魔目标。

X为打出前全部剩余能量，候选保存X并由原事务支付。自由面X=0或X>3没有合法品质／紧度组合而禁用；拘束面X=0可以打出但不收紧、不回魔，X>3只要容量足够即可。复放沿用原X并重新检查剩余容量，不能完整执行则跳过该次复放，不追加回魔。休息房禁止自由效果等原阶段规则保持。

RuleChangePackage：影响卡牌定义／双面区别、共用X费用、随机装备选择、收紧、回魔、奖励池与玩家说明；不增加GameState／快照字段、随机域或UI直写入口。预演临时隔离并恢复状态和反馈，不消耗随机、不写外部日志；实际装备／收紧／实回魔以结构化事件进入原行动摘要与日志。手牌、图鉴保留完整2X／15X公式和不足禁用说明，具体预览同时展示当前X与收益；英文目录及词表同步。十四交互轴仅费用、品质／紧度、现有安装资格／容量、装备触发、资源回报与原复放相关，姿势、伤害、施法、回合、捕缚、特殊装备与其他规则不变。

验证用例归既有card_power，覆盖X=0/1/2/3/4、每件独立求和、只剩1位置拒绝／恰好2位置成功、无替换、收紧不足原子拒绝、预览只读、旧版本拒绝、回魔封顶、免费复放继承X／不足跳过、实际存读不重复、两角色与抵挡边界、休息自由禁用。窗口沿card_power，核对X费、原图、罕见与完整文案、实际点击佩戴及不足时零变化；rewards验证正式随机池可达，application验证原施加行为。不新增套件，不截图、不打包。


自缚验证结果：20260914T065430605-47564 的card_power／application／architecture／content共2179项通过，源码指纹稳定。补齐角色2／休息边界及英文后，20260914T065903980-45828 的localization／card_power／application／architecture／content／rewards共2917项全部通过，正式奖励抽样包含自缚。窗口初次两条失败来自测试在首次渲染前设置牌面被原抽牌定向覆盖，改为首次显示后通过真实右键翻面；未改游戏默认牌面。20260914T070308720-44332 的完整card_power窗口307项全部通过，包含X费、原图、完整公式、实际两件佩戴与空间不足无变化。后两轮因同时进行的其他工作区修改标记source_changed，不声称冻结源码全量门禁通过，也不无限重跑其他任务的在途改动。git diff --check通过；不截图、打包或发布。

## 2026-09-14 秘密武器

域：装备与解除、压力与快感。

稀有奖励遗物，加入普通奖励、宝箱、商店与套娃稀有来源。脚趾可代替手部施法，选手部／脚趾合法路线中的较高成功率；独立口部路线、无部位和明确身体豁免仍按原规则。脚趾只要有真实覆盖拘束便不可用于施法，最终成功率为0%，必成与最低成功率不能绕过。脚趾代替的是施法，不放开握持、工具、药剂或体术的手部条件；火球手势和控火手部施法条件可由脚趾满足。

持有时，空脚趾施加优先级从普通档提升至嘴部／手指同档，仅次于空手腕；已有脚趾装备仍落回原追加档。来源模板、精准部位、容量、层级、合法性、闪避与替换机制不变，不更改卡牌超级顺延的解除排序。

用户授权自行调数值：牵扯按真实覆盖脚趾的每个物理件品质＋当前紧度合计2／3／4／5／6，分别增加1／2／3／4／6基础快感，多件累加。每次花能量的行动触发一次，2能量不额外倍增；熟练而已的额外牵扯同样触发。复用原快感来源倍率（含大理石、平板锁等）、上限保护与高潮结算，无新增敏感度倍率。普通／复合覆盖共用equipment_at，拾取时已有拘束立即生效，降档立即重算，解除后停止。现有特殊装备没有通用品质紧度表，本表只属于秘密武器，不回写特殊装备规则。

RuleChangePackage：状态为遗物持有及实时派生牵扯；无新存档字段、随机域或迁移。候选／事务涉及施法部位准入、最高概率选择、统一施加优先级、统一消耗能量牵扯；数值注册于遗物表，结构化法术事件保留hand类别并新增实际source_part。其他交互轴包括锁／层序／姿势／工具／移动／资源／魔力池／回合均沿原规则；未涉及的规则不改。玩家可见文字覆盖稀有遗物效果及分档、专属SVG图标、图鉴共用展示、手部／脚趾概率对比、拒绝原因、真实施法来源日志、行动风险与状态详情，英文回退同步。无新增文学叙事，现有通用施法叙事沿用。

测试并入relics下secret_weapon_cases，覆盖casting／installation_priority／pressure／persistence交互，不复制到多套件；复用casting窗口验证图标、概率、禁用及实时状态，无截图。相关完整规则分类relics／casting／installation_priority／application／pressure／architecture／content／localization；不打包或发布。

## 2026-09-14 魔血平衡调整

域：契约 `verification.md`。

RuleChangePackage：魔血力量加成3→2、稀有→罕见，共用定义同步奖励池、商店定价、图鉴与中英文说明。每玩家回合开始快感＋5保持；既有实例按稳定遗物ID读取新值，无需存档迁移，不改变已冻结商品价格。正式体术／挣扎属性读取共用修正，不新增状态、事务、事件、随机域或叙事。十四交互轴除力量数值外保持。更新rewards规则／窗口现有真实伤害与奖励池断言，覆盖回合效果、预览只读、失败不变和存读档；content／localization复核共用说明，不打包。验证结果见docs/verification.md后续记录。

秘密武器验证：20260914T071730474-48696 的 localization 70项通过；修正测试中近身短打要求双腿自由的夹具，改用2能量接连挣动，并修复无捕缚时原能量上下文为0导致漏触发的问题。20260914T071956026-8264 的 relics／application／architecture／installation_priority／content／casting／pressure 共2990项通过，casting窗口55项通过。合计相关规则3060项、窗口55项，无新增截图。最后运行因并行源码修改标记 source_changed，仅记录断言通过，不声称最终合并版本冻结通过；不打包、提交或发布。

## 2026-09-14 自适应分区与紧凑解缚详情

域：契约 `release-interface.md`。

RuleChangePackage见docs/release-interface.md。身体框与分区列收窄，小部位字体放大，按实际高度保留多区，溢出按开启顺序收起；单区过长内部滚动。详情缩小图标及空白，手胸／臀腿显示正式小数严密度，确认按钮固定页脚。高亮保留按钮边距，避免拖牌时几何变化。无规则、存档、数值或事件变更。

20260914T071957134-48380：architecture／localization共139项通过；body_layout／targeting／equipment_complete／keyboard／touch共403项通过，含精确高度及少1像素、单区滚动、多个展开、刷新只读、小数严密度、固定确认按钮、真实拖牌与出牌结算。此前窗口失败暴露高亮覆盖紧凑边距及确认按钮被滚动裁切，修复后原断言通过。当前有其他任务同时修改源码，检查器标记source_changed，不能作为冻结工作区或发布门禁通过证明；不追加全量测试。已查看build/ui-release-region-panel.png、ui-release-adaptive-panel.png及ui-release-numeric-panel.png，确认标题数值横排、层级列表及固定页脚无裁切。不打包或发布。

## 2026-09-14 奖励页顶部遮罩接缝

域：`tests/reward_ui_cases.gd`。

RuleChangePackage：顶栏高62，旧奖励遮罩从78开始，漏出16像素背景。普通奖励／套娃／开场奖励共用reward_backdrop，读取实际GameHeader底边并换算奖励容器局部坐标，遮罩覆盖到底部900，保持各奖励内容位置与原透明度。顶栏继续可访问；没有新文本，changedUiAndLogs=N/A（仅消除背景接缝，原标签、日志不变）。状态、规则、候选、资源、回合、随机和存档及其他交互轴均不变。rewards／home窗口沿已有真实领奖流程核对三种布局的遮罩全宽、上下边缘及顶栏排除，复用architecture；不新增截图、不打包、不发布。


2026-09-14 魔血：已改为罕见、力量＋2，回合开始快感＋5保持；新生成商店按罕见65魔力定价。localization／content／rewards规则1116项通过；rewards窗口309项中仅双重解锁提示断言失败（tests/reward_ui_cases.gd:138），魔血图标、真实回合与＋2伤害预览检查通过。同期其他源码仍在变化，报告为source_changed，不记整批或冻结全量通过。报告spire-godot/build/checks/20260914T072117822-45376/summary.json；未打包。

2026-09-14 马眼棒立绘差分依附平板锁：`SpecialEquipment.portrait_layers`要求任意平板锁与导尿管／独立马眼棒条件同时成立，单独马眼棒不再错误叠加基于锁体制作的差分。既有普通平板锁无差分、导尿管平板锁有差分用例保持，并新增普通平板锁＋独立马眼棒及单独马眼棒反例。`20260914T072907893-49312`的architecture规则69项、equipment_art／hero_art窗口219项全部通过，源码前后指纹一致；未重做素材、截图、打包或发布。

遮罩验证：20260914T072428777-48320 architecture 69项通过；home执行113项，本次开场奖励遮罩两项通过，另有既有PLATE LOCK HOME状态／加固带文字检查失败。20260914T072536852-40220 rewards执行313项，本次普通与套娃遮罩四项通过，另有REWARD UI final unlock segment does not promise a third lock文案检查失败，且运行期间并行修改导致source_changed。未改动这两项无关文案／行为，不宣称完整UI门禁通过；无截图、打包或发布。

## 2026-09-14 出狱临时检查与显示楼层校正

域：契约 `prison-release.md`。

- 以地图实际显示的10—11层为准（内部9／10），候选与中文／英文说明同步，继续排除休息与宝箱。出狱到期在同一正式结束回合中自动执行一次正常规则的临时检查；违规处罚且最多追加8回合，下次到期重新检查。通过才执行出狱装备判定并打开起点选择。
- 临时检查不插入回合、不改变正常巡视倒计时；同回合正常巡视仍按期到来。持钥匙或反抗时正常巡视暂停，但到期检查仍执行。复用已有检查次数与延期字段，不提升快照52、不迁移、不打包。
- `20260914T072424293-48388`：localization70、architecture69、content380、persistence593、prison935，共2047项规则通过；route134、prison160，共294项窗口通过。案例含重复延期、多类违规只加一次、周期同回合边界、钥匙暂停、过期命令原子拒绝、保存恢复、显示楼层边界与正式延期后继续操作。
- 报告为`source_changed`：测试期间另有departure_ui_cases、release_view、英文目录、equipment_art_ui_cases与special_equipment修改；未把用例通过写成固定源码整批门禁通过。本任务代码未因这些修改回滚或覆盖，相关实现记录见`docs/prison-release.md`。

## 2026-09-14 更新出狱练习入口

域：契约 `prison-release.md`。

- 练习菜单现在分别提供检查通过、违规延期、击败出口守卫。前两项均从19／20回合开始；延期项由真实道具工厂预装一件低墙缝小石片，包含正式墙面位置，玩家结束回合后真实没收并延长8回合。再实际完成8回合，正常临时检查通过并打开10—11层起点选择。守卫练习说明同步稀有三选一、遗物、60魔瓶及起点范围；菜单和开场提示均有英文。
- RuleChangePackage见`docs/prison-release.md`；只改练习配置、对应初始化与文案，不新增正式规则、存档字段或旁路命令。窗口检查直接从新练习按钮进入，已删除测试里手工制造缺装的替代夹具。
- 首轮`20260914T074055848-35216`：localization70、architecture69、content380通过；prison发现预装工具缺少具体墙缝位置，已补上`Space.attachment_position`。
- 修复复查`20260914T074248079-46568`：prison959项规则、prison170项真实窗口用例全部通过，包括有效初始化、没收、期限／正常周期、保存恢复、8个实际回合和新地图选择。运行期间其他源码有同期变化，报告为`source_changed`，不宣称固定源码的整批门禁通过。没有打包或发布。

## 2026-09-14 战斗施加后自动展开身体区域

域：战斗与敌人、装备与解除。

RuleChangePackage：正式行动成功后，以提交前后只读body_regions.targets的物理ID对比确认新增或替换的拘束具，自动展开受影响区域并更新展开顺序；普通、复合、链接及特殊装备均复用其正式区域投影。仅战斗内动作生效（包含该动作结算进入奖励／整备），不在开局、读档、SL、非战斗行动、普通重绘或失败提交时自动展开。同件纯加固／降档不触发；手动收起保持到后续真实施加。只展开左侧区域，不选择装备、不弹出详情、不派发额外动作；空间不足继续按实际高度收起旧区域，最新区域可内部滚动。

不新增游戏状态、存档、随机或事件，不改变施加资格、数量、部位、层级、费用、回合及十四规则交互轴。玩家文案N/A：使用已有区域名称、计数、展开／收起标志；无新日志或叙事。body_layout窗口补真实结束回合施加、旧版本拒绝、同数量替换、手动收起与刷新、加固反例、非战斗隔离及只读断言；复用architecture与display窗口覆盖场景刷新边界，不打包。

## 2026-09-14 基础动作部位与左侧能量徽标

域：装备与解除、压力与快感。

RuleChangePackage：基础动作栏统一采用32像素左侧能量徽标（复用energy-medallion.svg，数字读取candidate.cost），右侧主行显示名称与伤害，次行显示部位、耗魔、次数和成功率。删除主副两行的重复能量消费字样，0费与不可用状态均保持徽标；右下快捷键不变。深呼吸同样采用徽标，并保留次回合回能效果说明，它不是当前费用。使用部位由只读GameView投影：肘击双臂，近身短打双臂／双腿，踢击双腿，魔法采用正式casting.source_part，覆盖秘密武器脚趾替代、魔女部位及无部位施法。深呼吸读既有正式嘴部判定与效果。

没有修改费用、伤害、施法、部位资格或动作规则。点击、拖拽、右键换式、快捷键、禁用原因和详细悬停继续用原候选；日志N/A（原结算事件未变），结构化状态、回合、随机、存档与其余交互轴不变。中英部位／效果文案同步，窗口检查费用徽标的0／1切换、部位说明、文字与徽标不重叠、热点保留及实际付款。运行basic_attacks／architecture／localization规则和basic_attacks／casting窗口，不新增截图、不打包。


2026-09-14 战斗施加自动展开：正式提交成功后按区域投影中新增物理ID展开左侧对应区域，兼容同数量替换；手动收起不被普通刷新重开、不弹详情。body_layout完整窗口145项通过且源码稳定，报告spire-godot/build/checks/20260914T075354234-48868/summary.json。首轮architecture69项通过；display窗口另有语言切换后身体标签旧断言失败，本批不改翻译路径，未记跨分类全绿；首轮新增测试误用行动分组已修正并完整复测body_layout。未打包。


2026-09-14 基础动作栏验证：build/checks/20260914T075316120-20556 中 localization 71、basic_attacks 181、architecture 69，共321项规则断言通过；basic_attacks 87、casting 55，共142项窗口断言通过。覆盖左侧0/1费用徽标、部位只读投影、文字对齐及真实点击/拖拽/招式切换。运行期间其他任务修改源码，报告为 source_changed，不宣称固定源码整批门禁通过。同步修复阻止语言包加载的已有守卫增援英文占位符格式；不打包、不发布。

## 2026-09-14 监狱探索警卫战援军

域：契约 `prison-reinforcements.md`。

按用户最终要求做成战场负面效果，开战起每4个完整回合召来1名警卫，全场上限1＋警戒度，胜利立刻取消；出逃战不生效。RuleChangePackage与规则边界见docs/prison-reinforcements.md。复用正式敌人创建、结束回合、状态投影、存档复核；新警卫出生回合不行动，先手／后手及原警卫阵亡均不改变场地时钟。

20260914T075204241-16528：prison 1135、guard 40、status 299、intent 89、architecture 69、content 380项通过；新增用例包含4回合边界、警戒度1／2／4上限、打断不中止、原警卫阵亡、胜利取消、奖励整备、出逃排除、存读档重放、过期提交及坏存档原子拒绝。该轮localization因英文参数格式被拒绝，随后词条改为兼容包的{pN}格式；20260914T075522198-20088 localization 71项通过，guard窗口69项通过，验证常驻倒计时、新警卫真实目标和共享计数。首次测试误期望返回牢房后保留已退场敌人列表，按原正式清场行为改为列表为空，并保留无召唤事件断言。工作区存在其他任务并行修改，source_changed不作为冻结源码／发布门禁通过证明。未跑全量、未截图、未打包或发布。

## 2026-09-14 基础动作费用居中与禁用原因

域：界面、装备与解除。

RuleChangePackage：费用数字关闭自动换行并固定居中，避免最小高度撑出徽标。不可用动作保留部位行，在底部单独显示11号红色简短原因；说明关闭自动换行并限制在按钮内，悬停继续显示完整正式原因。常见双臂／双腿限制、站姿、次数和无力化仅缩短显示文案，中英文同步；不改变候选资格、费用、状态、随机、回合、存档、输入或日志。窗口补齐实际布局后的徽标数字矩形、禁用原因颜色／位置／裁切和腿部限制反例；复用basic_attacks、casting窗口及architecture、localization规则。


2026-09-14 动作栏对齐复验：关闭费用数字自动换行后，实际布局中心与32像素徽标中心一致；不可用动作使用24像素标题行、17像素部位行与17像素红字原因行，按钮增至60、整栏72像素，仍与手牌区分离。首轮140项localization／architecture规则通过；窗口发现中文字形最小行高17超出原14像素分配，已修复并补齐正义飞踢简短原因。最终build/checks/20260914T100955306-55060中basic_attacks105、casting55，共160项窗口断言通过，源码稳定。未打包或发布。

## 2026-09-14 警卫开场满位加固

域：监狱与收押、装备与解除。

RuleChangePackage：首回合三处apply原有replace权限保留，补tighten_missing；不足次数通过共用加固候选，仅限该操作required_slots真实覆盖部位，1次只加固1件／1档。满3档可上锁时复用加固上锁与满耐久，空位先施加、合法替换先替换、不原样替换。被闪避的次数不转加固；无加固目标则落空，不跨部位补装。共用targets增加可选部位过滤，默认空列表保持六缚等原全身后备行为。已保存首回合旧意图执行时补同样后备，不增加存档字段。首回合后循环、准备、捕缚、随机域、资源费用及其余十四交互轴不变。图鉴／练习中英说明同步，实际日志沿既有施加、替换、加固／上锁与落空日志；不新增叙事。guard增加满位低品质替换、高品质加固、3档锁恢复、跨部位反例、只读／过期拒绝、存读档与阶段推进；关联application、replacement、enemies、intent、persistence、content、localization。不打包。


警卫首回合修复验证：20260914T104131444-3824中localization／replacement／application／architecture／content／intent／enemies全部通过（2590项）；guard初轮70项仅“满3档加固上锁”测试失败，原因是测试持有被正式安装流程更新前的字典引用，已按稳定ID读取最终装备并补旧意图存读档用例。20260914T105830535-51180最终guard规则75项、完整guard窗口69项全部通过；同期其他源码变化，报告source_changed，保留专项通过记录，不标记冻结全量通过。git diff --check通过。未打包。

## 2026-09-14 其他人形敌人装备流程排查

域：战斗与敌人、装备与解除。

范围：按humanoid注册逐项核对玩偶师、玩偶、六缚、多面手、奴隶贩子，并回归已修复的警卫。installation_intents与实际application_spec均保留替换权限；普通空位优先、满位比较及结构封闭仍沿Application/Replacement。六缚开场与收尾逐区域、双重束缚缺额及复合失败已有各自加固分支；多面手有独立上锁／双件加固。奴隶贩子按准备就绪确定实际紧度并执行指定偏好；玩偶受击的普通及预备附加仍沿正式人形施加。未发现第二处与警卫首回合同类的漏接；没有将警卫新增后备扩展到其他未声明此效果的动作，也未修改运行规则。

测试补入已有enemies分类：枚举全部当前人形来源、确认只读权限和真实满位替换、保持原品质与无关装备、替换日志、六缚初／中级区域施加失败后加固、多面手双件3档上锁和满耐久、无目标不反向补装。无新状态、候选、数值、事务、随机域、存档、UI或玩家文案；RuleChangePackage.changedUiAndLogs=N/A（仅审计及测试，运行表现不变）。专项结果随后记录；不打包。


人形流程审计验证结果：20260914T111017278-57252完整enemies1793项通过且源码稳定；20260914T111220973-8144完整battle_saturation34项通过（首次临时脚本加载错误已在重试消失）。20260914T110818892-48760中replacement／application／intent／guard／trader均通过；新增审计夹具初轮误用了六缚练习ID、并把奴隶贩子初级施加预期写成中级，已修正夹具并完整复测enemies，未因此改动游戏规则。已核对所有当前人形的替换权限、正式满位替换、规定的加固后备和全场无操作后的逮捕条件，未发现新的规则漏接。未运行全项目或重新打包。

## 2026-09-14 监狱巡视榨精与正常出狱对白

域：`assets/art/enemy-guards-v1/README.md`。

每次例行巡视接受检查结果时，以及每次刑期到期的额外巡视中，均通过正式检查事务追加一次狱警手部榨精。复用通用高潮身体、装备及遗物反应，高潮总数增加1，自身魔力立即损失`min(20，当前魔力)`；不打开战斗高潮覆盖层，不生成高潮后乏力或滑精两回合延迟。低于20魔力、平板锁、平板锁且低魔力分别选用稳定文案cue，重复接受已完成检查不能重复结算。正常出狱在重建塔路后仍显示一次无名字的棕发资深狱警对白框；例行巡视固定显示紫发狱警。两张用户指定图片已按透明抠图流程替换原警卫资源，来源、裁框和哈希见`assets/art/enemy-guards-v1/README.md`。

最终门禁`build/checks/20260914T112747431-54388`源码前后指纹一致：localization、architecture、content、action_copy、prison、guard、pressure共2989项规则断言全部通过；prison真实窗口212项全部通过。窗口流程实际确认巡视到来、接受检查、扣除20魔力、平板锁低储量正文、两张狱警立绘、无名字对白框和正常出狱后对白。未运行全项目、未生成截图、未打包或发布。

## 2026-09-14 收押与巡视短文案

域：监狱与收押、文案与本地化。

收押页移除保底规则、状态保留与战后奖励说明，改为押送和登记演出加三项实际数量；巡视页移除检查次数、清单原理、事务过程与重复规则提示，公开和完成结果改为短句。进入牢房后新增无名字棕发狱警对白。底层检查事件仍保存缺失、请求、实际安装、更新后清单、牌区恢复、电池与延期事实；规则断言因此改读结构化字段，而不要求玩家界面重新显示实现报告。

`build/checks/20260914T114658541-5540`中localization、architecture、content、action_copy、prison、guard共2002项规则断言全部通过，guard窗口70项通过；prison窗口的两项旧长句断言暴露后已改为短文案＋结构化事实检查。最终复验`build/checks/20260914T115315468-54688`的prison窗口216项全部通过，源码前后指纹一致。两轮均未生成截图；未运行全项目、打包或发布。

## 2026-09-14 一次性收押事件页与收押榨精

域：`ui/quick_release_bar.gd`；契约 `prison-release.md`。

RuleChangePackage见`docs/prison-release.md`。正式收押先执行既有战斗结束、装备追加与链接安装，再进行一次脚本高潮，立即损失最多20自身魔力，最后执行进入监狱的遗物钩子；主动投降也停在同一个`captured`收押页，确认“进入牢房”后才开始牢房回合或五级终局。捕获记录新增可选`intake_scene`，保存实际普通／复合拘束具、连接绳与性玩具的共用佩戴正文以及榨精差分；旧快照没有该字段时仅使用安全回退，不提高快照修订。原`prison.guard.cell_entry`持久NPC日志已删除，普通牢房回合不再反复弹出收押对白。

规则检查`build/checks/20260914T124444794-54936`中relics、architecture、content、action_copy、prison、guard、pressure共3775项通过；localization在同期目录重生期间失败，随后重新生成英文目录并由`build/checks/20260914T124800800-59224`以73项单独通过。更早的定向`build/checks/20260914T122057604-57588`验证guard 77项及平板锁低魔力差分。监狱窗口`build/checks/20260914T124914202-47392`共217项通过，覆盖事件式收押页、具体装备正文、真实扣魔、主动投降入口和进入牢房后旧对白不复现；运行期间有其他界面源码更新，报告标记`source_changed`，因此仅记录专项通过，不宣称冻结源码全量门禁。pressure窗口先通过本次强制高潮投降分支，后在同期快捷栏改动造成的两条深呼吸显示旧断言处失败，未计为整组通过。

本批没有生成截图、没有打包或发布。为恢复窗口检查，顺带修正同期新增`ui/quick_release_bar.gd`中一个缺失的闭合括号及对应缩进；该修复不改变候选、费用、资源或规则。

## 2026-09-14 体术连击名称截断

域：界面、装备与解除。

RuleChangePackage：名称／伤害默认字号18降至16，按两段实际字体宽度共同缩小，间距8减至6；移除伤害区62%比例限额，以完整文字的测量宽度居中分配。沿已有能量徽章、部位／次数副行及不可用原因，未缩写招式名称或改动作规则、数值、候选、日志、存档与随机。basic_attacks窗口新增肘击连击／近身短打连击，在有／无墙缝工具压缩栏位下测量完整文字、边界、间距及只读状态。20260914T114156443-48444完整basic_attacks窗口123项通过，git diff --check通过。未打包。

## 2026-09-14 体术及身体栏位置互换

域：检查与测试、界面。

RuleChangePackage：体术显示列表交换heavy与kick，顺序为肘击、踢击、近身短打、火球术、深呼吸；身体栏仅在渲染时排序为头颈、手胸、性器、臀腿。原候选列表／规则区域顺序、快捷键绑定、右键招式切换、目标ID、费用、伤害、展开优先级及溢出收起规则不变。没有新增文案、状态、事务、日志、随机或存档；玩家标签沿用现有名称。现有basic_attacks补位置先后断言，body_layout调整预期顺序及最底部可见滚动区高度边界检查，不改底层分区。未打包。

位置互换验证：20260914T114527346-52760的basic_attacks完整124项通过且源码稳定；20260914T114620561-48244的body_layout完整147项通过，但同期其他源码变化，报告source_changed，不标记整批冻结通过。两处位置、展开／收起、实际点击及宽高边界检查均通过；未打包。

## 2026-09-14 动作栏切页与快捷挣脱

域：检查与测试、装备与解除。

已接入：右侧零回合切页；四区默认装备／耐久／紧度／锁状态；右键切小部位；先点部位再点挣扎／滑脱牌，以及真实拖牌直接提交；第五格已安装道具；探索、整备及休息保留动作页的深呼吸。费用、目标资格及版本继续由原候选决定，无新游戏状态或存档字段，中英文提示同步，未打包。

- `20260914T120922083-46916`：architecture 151、localization 71项通过，共222；工作区同时有编辑，脚本标记source_changed，仅记录断言结果，不记作冻结源码门禁。该次窗口新增测试误将只读pressure对象当数字比较，修正为测试状态的数值后重新执行相关分类。
- `20260914T121317688-53964`：basic_attacks 158、installed_tools 51、body_layout 147、targeting 83项通过。包括先部位后牌真实点击、真实滑脱拖放、独立区域不变、只扣一次费用、缺能量／旧版本／错误牌面拒绝、切页保留立绘与手牌、右键零消耗、非战斗深呼吸、安装道具及魔瓶不遮挡、英文提示。此批唯一失败为exploration旧远端牢门案例没有确定的开门资格，依赖随机起手含开锁牌，不是横栏功能失败。
- 为该远端测试明确注入持有狱警钥匙的前提，原“需要先到牢门前”及不夹杂其他地点断言保留；玩法代码未改。`20260914T121459900-55468`重新执行exploration完整分类43项通过，退出码0、源码指纹稳定。

五个受影响窗口分类最终合计482项通过（分上述两次结果），没有宣称原组合失败批次整体通过，也没有进行全项目回归。相关规则断言与窗口结果的源码稳定性分别如上记录。截图未默认生成。

## 2026-09-14 左侧捕缚拖牌、快捷装备循环、探索火球术

域：`core/game.gd`。

已完成：左侧捕缚整行与战场捕缚共用接收函数；四区上一件／下一件和←／→循环本区物理目标，默认优先最外层可挣扎的最低紧度项；切换联动左侧小部位和展开的装备详情；手动目标保持，失效候选不改打其他装备；X为踢击、V为近身短打；探索显示火球术与深呼吸，自解能力沿原施法候选拖到拘束具或快捷格。

- `20260914T123350477-57924`：keyboard 67、guard 87项通过。捕缚新例以合法牌堆夹具验证拖到标签与条身，两处高亮、实际进度／能量、错误牌及旧版本拒绝、移除捕缚后接收区消失。该批源码变化，`source_changed`，只记录断言结果；同批basic_attacks的火球拖放测试先拖牌再展开部位导致输入取消，调整为先展开后真实拖牌，不改正式接收逻辑。
- `20260914T123737669-58032`：architecture 151、localization 71，共222项规则断言通过；basic_attacks 174、body_layout 147、targeting 83项通过。含默认低紧度目标、实体选择、跨小部位循环、空部位开始循环、左右键、二三级详情联动和不遮挡横栏、X/V真实选择、探索炫火自解实际拖放及正式费用。该批源码指纹稳定，但exploration一条旧安装位置文案断言仍期待“墙缝一”，与当前正式“离地0.2米的墙缝”不一致，因此不记录组合批次整体通过。
- exploration断言改为验证当前正式mount_label及原3次使用数。重新检查时发现同时改动的投降分支有一行Guard.capture缩进脱离elif，修复为仅在surrender分支执行；`core/game.gd --check-only`解析通过。`20260914T124233679-8536`：exploration完整43项通过，退出码0、源码指纹稳定。

相关窗口六分类最终601项通过，规则222项通过；结果来自上述批次，源码稳定性分别记录，不宣称全项目或同一次冻结检查全部通过。早期捕缚新测试直接替换手牌而未同步卡组，被正式验证正确拒绝；改为共用加牌工厂且保留原牌区后通过，未绕过一致性检查。

本地化门禁发现英文兼容表新加入的5条具名占位符未转为p0格式，导致整个兼容表拒绝加载；仅修正参数标记并同步生成脚本映射，原中文及英文正文语义不变。localization重新71项通过。没有生成截图、打包或发布。

## 2026-09-14 图鉴卡牌与实时对局显示隔离

域：装备与解除、卡牌与奖励。

图鉴通过现有卡面入口显式关闭实时卡牌类型／实体投影合并；原牌、衍生牌、双面、魔力角标及悬浮说明统一采用静态注册表。手牌及其他展示默认沿用实时投影，角色专属定义及图鉴筛选不变。只读显示变化，无规则、存档或新文案。

- `20260914T130814854-57824`：card_power完整307项通过；该批`source_changed`，仅记录断言结果。新增图鉴局内夹具最初沿用主页的正式开局，未进入战斗导致取不到手牌控件，改为既有game_fixture；之后改用正式打开抽屉入口，避免直接置位同时留下其他启动抽屉，保留原关闭面板断言。
- `20260914T131234528-7932`：encyclopedia完整158项通过，退出码0、源码稳定。覆盖真实装备使汇流收益及般若汤费用变化的前提、手牌动态效果保留、图鉴基础费用／效果／角标、两面及全部相关衍生牌、不显示即时施法概率、浏览不改快照及实际关闭。

未运行全项目回归，未截图、打包或发布。

## 2026-09-14 拘束具图鉴简洁排版

域：装备与解除、检查与测试。

按最新要求移除通用耐久百分比紧度分档说明；保留装备具体施法倍率及滑脱限制。基础信息、组件明细和特殊效果以空行分段，删除重复组件汇总，整数耐久不显示小数尾零；拘束具正文18号字、行距6。仅改只读图鉴及相应测试，不改规则、候选、数值、日志、随机、存档或其他分类布局。

`20260914T125159535-59980`：localization 73、architecture 151、encyclopedia 495，共719项规则断言通过；encyclopedia窗口82项通过，包含胶带包裹分段、字号行距、完整耐久和口球倍率保留。工作区期间有源码变化，报告`source_changed`，仅记录断言通过，不宣称冻结源码门禁通过。`git diff --check`无空白错误。未打包、发布或生成截图。

## 2026-09-14 快捷栏两侧箭头与同栏位键位

域：界面、装备与解除。

四区上一件／下一件改为左右端28×60的整高点击区，三角图形直接绘制，中央文字与键位提示不覆盖箭头。对应栏位的strike／kick／heavy／fireball绑定在快捷页只选择头颈／手胸／性器／臀腿，默认Z／X／V／F；原←／→循环、右键小部位、详情联动及拖牌仍沿原入口。

`tools/check.ps1 -UIOnly -UISuite basic_attacks,keyboard -TimeoutSeconds 300 -KeepGoing`：`20260914T125218834-46768`，basic_attacks 202、keyboard 81，共283项通过，退出码0，源码指纹稳定。检查两侧整高几何、文本与键位不相交、空区禁用、真实点击及拖牌、四个原键位只读选择、自定义Q替代Z、旧键失效、抽屉阻挡和切回原动作选择。`git diff --check`无空白错误。纯UI改动，未运行全项目回归，未截图、打包或发布。

## 2026-09-14 快捷框无数字耐久条

域：装备与解除、界面。

RuleChangePackage：装备名称右侧增加48×8的剩余耐久条，只消费现有ratio，隐藏数字和百分比，空部位隐藏；名称留出空间，原悬浮完整名称与耐久／紧度文字沿用。条形忽略鼠标输入，不改点击、详情开关、拖放及原候选。仅显示变化，状态、数值、费用、事务、日志／对白、随机、存档、迁移和十四规则轴不变；无新增中英文文案。

`tools/check.ps1 -UIOnly -UISuite basic_attacks -TimeoutSeconds 300 -KeepGoing`：`20260914T130918718-46368`，完整basic_attacks 226项断言通过。新增当前比例、切换与实际卡牌伤害后更新、空区隐藏、数字隐藏、名称与箭头边界、点击条形开关详情且不扣费；原真实拖牌回归通过。检查期间其他源码变化，汇总source_changed、退出码1，未声明冻结门禁通过。`git diff --check`无空白错误；未截图、打包或发布。

## 2026-09-14 快捷框点击开关三级详情

域：装备与解除、界面。

RuleChangePackage：点击快捷框或对应栏位快捷键展开当前目标的原装备三级详情，再次选择同框关闭，保留部位及目标供直接点牌；选择另一框切换详情，箭头和右键切换仍始终展开。空部位只显示原部位页面，快捷模式详情统一保持在横栏上方。只改UI开关和几何，不新增状态字段或文案；原中英文名称、说明及原因沿用，日志／叙事N/A，候选、费用、事务、回合、随机、存档、迁移与十四规则轴不变。

`tools/check.ps1 -UIOnly -UISuite basic_attacks,keyboard -TimeoutSeconds 300 -KeepGoing`：最终`20260914T130353156-59888`，basic_attacks 217、keyboard 87，共304项通过，退出码0、源码稳定。覆盖同部位多件装备的精确三级展开、同框关闭／重开、关闭后实际点牌效果、跨框切换、快捷键开关及空部位窗口不遮横栏。此前`20260914T130213557-52928`的299项检查是在用户追加关闭要求前启动，不作为最终版本门禁。`git diff --check`无空白错误；未截图、打包或发布。

## 2026-09-14 快捷栏补齐降紧与开锁

域：界面、检查与测试。

RuleChangePackage：修复快捷卡牌模式过滤遗漏lower／unlock，魔力撑除及开锁牌均复用原选中物理目标、卡面、候选ID和版本，经原事务执行。UI匹配及中英文不适用提示／探索说明受影响；状态、数值、施法成功率、费用、回合、事件、日志、叙事、存档、迁移、随机与十四规则轴不变。无有效目标仍显示原候选原因，禁止改用其他可用装备。

`tools/check.ps1 -Suite localization -UI -UISuite basic_attacks,casting -TimeoutSeconds 300 -KeepGoing`：`20260914T125921838-56060`，localization 73、basic_attacks 212、casting 55项断言通过。新例覆盖多件装备中先选目标再真实点击魔力撑除、精确降紧及费用、无锁目标拒绝且不改打另一件、缺魔拖放拒绝、旧版本及自由面拒绝、真实拖放开锁一次。共267项窗口断言通过，但检查期间其他源码有变化，汇总为source_changed、退出码1；此记录不代表冻结源码门禁或全项目回归通过。`git diff --check`无空白错误。未截图、打包或发布。

## 2026-09-14 狱警巡视事件页与紫发狱警透明图修复

域：`core/witch_expansion.gd`。

RuleChangePackage：正式`inspection`候选、结算、处罚、榨精、反抗和巡视周期保持不变；仅把arrival／result／done三个阶段集中投影为事件式页面，并移除普通巡视事件中的持久`npc_copy`，避免浮动对白覆盖牢房或跨阶段重放。延长8回合仍作为结构化结果显示，狱警对白不再念规则数值。紫发狱警继续使用用户原图，本地边缘分离提高白色阈值并补充尾巴封闭区背景种子，保留白手套、丝袜、手臂和腿部，不生成、不重绘。英文目录、UI回归及规则对照同步；不改变状态、随机、数值、事务和存档格式，不截图、不打包。

验证：`20260914T131733355-43252`的localization／architecture／action_copy／prison共1551项规则断言通过；prison窗口执行217项，仅旧测试把带已安装工具的结果误当成完全合规而失败，实际页面已正确显示藏工具差分，断言随后按结构化场景修正。复跑被同期删除、仍由角色2入口引用的`core/witch_expansion.gd`阻断，未擅自恢复另一批文件；本批Godot导入在该同期删除前为0错误。未截图。

## 2026-09-15 单手套拘束具立绘差分

域：角色与美术、装备与解除。

RuleChangePackage：使用用户提供的两张对齐原图，通过本地脚本提取银白套体、黑色肩带与扣件的像素差异，并生成普通和平板锁组合的透明替换底图及大腿根切片。`GameView`从真实复合拘束具投影`composite_portrait_layers`，只有主体仍有效的`glove`根启用该显示；短型、长型与肩带样式共享差分。左侧装备肖像和战斗受限站姿同步，解除套体后恢复原图。规则、数值、候选、费用、事务、回合、日志、叙事、随机和存档不变，无新增玩家文案；没有调用图像生成工具。

验证：`build/checks/20260914T142422863-63312`完成Godot导入，architecture 151项、equipment_art 176项通过；战场快照发现只读字段未随英雄快照复制后，统一经`EquipmentPortrait.snapshot`传递并复测。最终`build/checks/20260914T142821261-39696`中equipment_art与hero_art共231项窗口断言通过，覆盖短／长单手套、普通／平板锁组合、左侧与战场同步及状态只读；截图`build/ui-equipment-single-glove.png`、`build/ui-hero-single-glove.png`和`build/ui-hero-restrained-special-equipment.png`已人工查看。未运行全项目回归，未打包或发布。

## 2026-09-15 小魔女三姿势与身体栏立绘

域：角色与美术、塔路与地图。

- 本地抠图：站、坐、躺三张用户原图均保留RGBA透明通道与原始比例；坐姿仅补清帽内及脚／斗篷间白底，未使用会吃进大腿的白色连通区；躺姿补清双腿间白底。左侧身体栏使用站姿窄裁版。
- 左栏构图：专用裁框由源图`(140,0,1060,2304)`平移为`(460,0,1380,2304)`，显示宽高比不变；按人物身体中心而非帽檐与斗篷的整体透明重心定位，使人物在178×454画框内向左移动并居中。
- 显示边界：战场只读取View中的角色与姿势；小魔女佩戴拘束具后仍使用对应默认姿势，不借用角色1差分。角色1原有自由、拘束及固定立绘路径保持。
- 规则影响：N/A。图片与映射不改候选、费用、事务、事件、日志、随机、存档或任何装备判定；玩家可见文字沿现有角色和姿势名称，无新增机械文案。
- 自动检查：`tools/check.ps1 -RerunFailed build/checks/20260914T145515294-42952 -TimeoutSeconds 300`稳定通过；`architecture` 158项，`display,home,equipment_art,hero_art` 485项。首轮导入和截图轮的同组断言也全部通过，但因工作区同时有其他既有修改而被指纹门禁标为`source_changed`，最终稳定轮退出码为0。实机截图`build/ui-witch-portrait-stand.png`、`sit.png`、`lie.png`已检查三姿势切图、透明背景、原始比例、落地线和左栏窄裁显示。
- 左移复核：最终裁图重新导入后，`tools/check.ps1 -Import -UIOnly -UISuite hero_art -Screenshots ui-witch-portrait-stand.png -TimeoutSeconds 300`通过64项；截图确认人物身体位于左栏画框中部。

## 2026-09-16 事件选项状态条件的存档校验（`has_relic` 读档失败修复）

域：`core/snapshot.gd`、`content/README.md`、`tests/persistence_cases.gd`、`tests/content_cases.gd`。

缺陷（仅存在于未发布的本地提交）：`4441120` 为漂浮皮带群加入 `has_relic` 状态条件后，冻结选项把它带进存档，而 `core/snapshot.gd:391` 仍只接受 `kind=="no_chastity_lock"` 且键集必须为 2。持有「软化扣环」进入该事件时写出的存档在读取时被判「事件选项的状态条件损坏。」，`Store.unpack` 与 `restore_snapshot` 均拒绝，该存档槽无法继续。写入侧 `SaveStore.write_game` 只跑 `game.validate()`，而事件 `validate` 不检查 availability，所以保存会成功、失败只出现在读档——不对称是本缺陷难被发现的原因。`e635bf5`（v0.17）不含 `has_relic`，缺陷不在任何已发布版本中。

RuleChangePackage：`core/snapshot.gd` 的状态条件校验改为按 `kind` 复核键集——`no_chastity_lock` 恰好 `{kind,reason}`；`has_relic` 恰好 `{kind,type,reason}` 且 `type` 必须是已登记遗物；未知 `kind` 或多余键一律拒绝。`content/README.md` 同步记录两种条件的键集与"新增条件种类必须同时扩展存档校验"。规则、候选、费用、事务、随机、存档格式与旧档兼容性不变。

验证：`tools/check.ps1 -Suite persistence,events,event_flow,content,architecture -TimeoutSeconds 600 -KeepGoing`：`build/checks/20260916T023640988-18172`，architecture／event_flow／content／persistence／events 全部 PASS，共 2118 项断言。新增 `tests/persistence_cases.gd:event_conditions`（持有遗物时的事件往返 + 五类畸形条件的原子拒绝）与 `tests/content_cases.gd` 的 `has_relic` 正例及三类反例（缺 `type`／未登记遗物／多余键）。反向对照：临时撤销 `snapshot.gd` 修复后 `-Suite persistence` 复现真实错误（`build/checks/20260916T023516144-10164`，persistence FAIL，1/604，"无法继续这份存档：事件选项的状态条件损坏。"），证明该断言确实覆盖本缺陷。未运行全项目回归、未截图、未打包。

## 2026-09-16 E0 事件等价判据：比较器类型缺陷修复与判据身份登记

域：契约 `verification.md`。

缺陷（**判据侧，不是产品行为**）：`build/event-oracle-20260916/event_oracle.gd` 的比较路径用 `JSON.stringify` 比对进程内整数与从基线文件读回的浮点（Godot 4.7 的 `JSON.parse_string` 把所有 JSON 数字解析为 float），所以基线一旦冻结，94 个场景恒判红（差异形如 `count: 4.0 -> 4`）。实现者在改动任何产品代码前停下上报，并给出独立证据：以 `--write=` 重放写出的文件与冻结基线逐字节相同、摘要仍为 `1f11bea5…`——据此把"判据坏了"与"行为漂移"分开，协调者裁决后才动手（授权范围仅比较路径，冻结基线与捕获路径一字不动）。

修复：仅新增 `_normalized()`，把基线侧整数值 float 归一为 int 后再比较；场景集合、捕获路径、摘要算法、基线文件均未改动。

验证（域：E0 oracle 判据，`build/` 产物）：
- 干净跑：退出码 0，`EVENT RESULT: PASS (94 scenarios, 0 failures)`，`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（＝契约 §0.1 记录的基线摘要）；日志 `build/e0-diagnostic-20260916/compare-fixed.log`。
- 反向对照（证明判据不是永远绿灯）：进程内注入两处真实漂移（`start:abandoned_storeroom` 的 `count` +1、`choose:binding_cleric:purify` 的 `view` sha256 首位改 0），退出码 1、`FAIL (94 scenarios, 2 failures)`，逐条打印场景与字段差异，摘要同时变红（`1c640cde8a6e83a64404d8c153cd92711a2d44c0a228c581650bcc01703f7306`）；日志 `build/e0-diagnostic-20260916/compare-drift.log`，漂移副本 `event_oracle_drift.gd`。
- 捕获侧未变：`build/e0-diagnostic-20260916/rows_after_fix.json` 与冻结基线逐字节相同（各 50744 字节，`cmp` 通过）。
- 判据身份（`build/` 已 gitignore，脚本不进仓库，故登记哈希作为复核依据）：脚本修复前 `651890ac192f0d3e836b3b7fd6616ce4263e8ae788d8993658c0932082b6725a` → 修复后 `cf48529a19af7773f4d8ac6be343a759fa6038151942fdf66dd249c89e20557f`；基线 `bdf08765f8dea0c1f6ac489245abd689907fd6974f794b7cea1e98d7a090e9c8`（未变）；漂移副本 `d12652336d4246ecaee94c08093bfb9faff42d57944ff2314f9dcbf19c47245b`。四个哈希与 `cmp` 结果已由协调者独立复核。
- 产品代码零改动（本项全部落在 gitignore 的 `build/` 内）；事件管线 B1 的判据自此可用字面退出码。

判据适用说明：B1–B4 的分类门禁以**增量**判定——红集必须恰好等于 `docs/verification.md` 已登记的既有阻塞项（当前为 `card_power` 的 5 条 `witch_*`），多出任何一条即停手上报；`card_power` 的修复不在本片范围，另行排期。

## 2026-09-16 B1b 作者文档同步（事件节点形态）

域：`content/README.md`、`tests/architecture_cases.gd`、`tests/content_cases.gd`、`tools/check-content.ps1` 等；契约 `content-templates.md`、`content-generation.md`、`content-extension.md` 等。

RuleChangePackage（文档与测试，零产品代码）：`spire-godot/content/README.md` §3 事件整节重写为单一节点形态（`start_node`／`nodes`／`schema_version: 2`、七个节点声明键与取值、合并后的选项白名单含"适用形态"列、起始节点免费出口只约束多节点、`availability` 两形态都生效、完整示例只指向两个模板）；`docs/content-templates.md`、`docs/content-generation.md`、`docs/content-extension.md` 同步到节点形态，模板为真源、文档跟随；已死的选项级 `pressure` 示例删除，B1 之前就不被校验接受的 `wager`／`reward:"keys"` 改为显式标注为早期设计记录（不整段删除）。新增具名 check：`tests/architecture_cases.gd` 的 `event_dependency_edges_pinned`、`event_definition_accessors_only`，`tests/content_cases.gd` 的 `event_author_manual_lists_current_fields`（读 README §3，字段 token 必须落在校验器词汇内，并逐条把文档里的声明取值拿去编译）。内容包与模板未改动；oracle／基线、契约、`core/`、`ui/` 未改动。

验证（提交 `a57dec3`，父 `c0b6a1d`；域：文档同步 + 事件分类）：
- E0 等价：退出码 0、`PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（与冻结基线逐字相同）。
- 内容包：`tools/check-content.ps1` 退出码 0、`CONTENT PASS: 12 file(s)`；模板探针 `tools/check-content.ps1 -Path build/b1b-docs-20260916/template-probe` 退出码 0、`CONTENT PASS: 2 file(s)`。
- 规则门：`tools/check.ps1 -Suite event_flow,events,content,architecture -TimeoutSeconds 600 -KeepGoing` 四类全 PASS；`-Impact` 展开集的唯一红项分类＝`card_power`（5 条 `witch_*`，登记于本文件第 29 行），未多一条；断言总数由 B1 的 10339 增至 10523（文档 check +184）。
- 旧形态残留：对四份文档检索 `start_stage`／`"stages"`／顶层 `choices` 零命中（`rg` 退出码 1）。协调者已独立复核上述 E0、四类套件（2147 断言）、内容包与模板探针三项。
- 具名 check 非空洞性：`event_author_manual_lists_current_fields` 在修正 `allow_refuse` 取值拼写前真实红过一次（`EVENT MANUAL node declaration documents every accepted value: allow_refuse ["true","false"]`）。

遗留（另行排期，不属本批）：①`docs/event-structure.md` §1 结构地图仍描述 B1 前的 `stages/start_stage` 形态（该文件是规划者契约，须由其加注或修订）；②本地化词表漂移——`assets/localization/legacy-en_US.json` 仍登记 B1 已删除的校验文案，新校验文案缺译（按已定义安全回退显示源文，无玩法影响）；③`docs/content-generation.md` §7.4 的早期设计记录是否彻底移除属文档裁定。未跑：`-Suite all`、打包与发布门禁（本批零产品代码改动）；未推送、未打包。

## 2026-09-16 B2 事件管线：声明表、单求值入口与叠加条件（含 B2b 收口与本地化）

域：`tools/check-content.ps1`。

RuleChangePackage（规则内重构，行为逐字节不变）：事件选项的资格判定从四条并行通道（`condition_met`／`availability_issue`／`hide_when_unavailable` 探测／遗物池闸门）收敛为**一份 `CONDITIONS` 声明表**，由它派生四处——运行时求值（`condition_probe`）、内容校验（`condition_issue`）、存档键集（`condition_saved_fields`）、trace 命名；新增**唯一求值入口** `evaluate_option`，返回逐条 `gates`（`gate`／`kind`／`mode`／`index`／`detail`／`reason`）与四种 `decision`，多命中按声明序以 `"\n"` 连接；`enter_node` 成为唯一节点管线，B1 遗留的"节点数分支"消失，七个节点声明（`frozen_form`／`relic_gate`／`random_freeze`／`outcome_draw`／`unavailable`／`empty_node`／`allow_refuse`）全部生效；新增规范拼写 `conditions`（1—8 条、每条 `mode∈{optional,hidden}`）与选项级 `unavailable`，与旧拼写互斥校验；`probe`／`candidates`／`execute`／`view`／`validate` 不再读 `flow` 镜像；删除选项级 `pressure`／`pressure_source` 死分支；`snapshot` 事件段**增量**补键集（保留原有 `flow` 分支全部检查，不以放宽换统一）。同批刷新英文字典。

**关键判据口径**：`frozen_form=="in_place"` **且选项无 `selector`** 时用 in_place 冻结布局，其余一律 staged（依据：选择器选项历来走共享 staged 构建器，改判据会让 `temper`／`dissolve` 的冻结 id 与 `selected` 键变化 → E0 必红）；`validate_failed` 与 `node_empty` 的具名 gate 缓到 B3（要单独命名须先拆 `probe()` 内部）。

验证（提交 `60869fc`（核心）→ `5a60cda`（B2b）→ `b6d45b5`（收口）；域：事件分类 + 存档 + 本地化）：
- **E0 等价**：退出码 0、`PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` —— 三次提交后各自复核均**逐字相同**（协调者亲自重跑，非采信报告）。
- **规则门**：`tools/check.ps1 -Suite event_flow,events,content,architecture,localization -Impact -TimeoutSeconds 600 -KeepGoing` 退出码 1，`5/10664`，`failed=['card_power']`、`unrun=[]`、`passed=23`、指纹前后一致 —— 红集**恰好**等于本文件第 29 行登记的 5 条 `witch_*`；`event_flow／events／content／architecture／localization／persistence` 六类全 PASS（协调者重跑 3044 断言）。
- **界面**：`tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900` 退出码 0、`UI PASS: 231 assertions`。**口径**：该命令默认 300 秒会因负载在 `events` 窗口套件中途被中止（`20260916T083346894-13484`，无 UI RESULT），记录与复跑一律用 `-TimeoutSeconds 900`。
- **内容包**：`tools/check-content.ps1` 退出码 0、`CONTENT PASS: 12 file(s)`。
- **本地化**：`legacy-en_US.json` 删 25 条本片已不存在的旧源文（阶段专用文案）、增 29 条新校验文案英文条目，条目 4943→4947；`removed still present: []`、`required missing: []`；`python tools/localization_inventory.py`：`needs_review 5690`、`connected_static_call 33`，`en_US 52/52`、`ja_JP 0/52`（ja 缺译非本片引入、未动）。具名 check `locale_legacy_catalog_matches_current_sources` 断言旧源文不存在且所需源文译文非空（安全回退不算通过）。
- **具名 check**：§10 场景 05／08／09／13／15–18 落地（`event_condition_kinds_share_one_declaration`、`event_single_node_declarations`、`event_node_empty_policy_kept`、`event_probe_and_projection_readonly`、`event_stacked_conditions`）；依赖规范三条 check 落地（`event_condition_kinds_share_one_declaration`、`event_single_evaluation_entry`、`event_pipeline_writes_only_declared_keys` 内容半；链半属 B4）。场景 05 经裁定为"一条 check 覆盖三处消费者即可"（判据是三处一致，不强制分文件）。

**一次"红项归因"记录（值得留档）**：B2b 首轮报告"`conditions` + `mode:"hidden"` 可能不丢弃选项"，实现者用最小复现（两组夹具 × 戴锁／不戴锁）分类为**断言写法错**而非产品缺口——原断言把 `options.is_empty()` 与 `candidates().is_empty()` 用 `and` 连接，而 `candidates()` 含非事件候选；且第二条夹具的期望默认 `no_chastity_lock` 在未戴锁时本不该命中。据此按契约字面判据重写断言，**未改产品代码**。这与 E0 比较器那次同类：先分类"判据坏了／行为漂移了"，再动手。

遗留（另行排期，不属本批）：B2c＝把 `conditions`／`unavailable`／叠加语义补进四份作者文档；B3＝trace 具名全覆盖（含 `validate_failed`／`node_empty`）与 debug 开关；B4＝事件链与环守卫；`card_power` 5 条与 `normal_play` 1 条为既有登记项。未跑：`-Suite all`、打包与发布门禁。**整片（B3／B4）未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B2c 作者文档补 conditions 与叠加语义

域：`content/README.md`、`tests/content_cases.gd`；契约 `content-templates.md`、`content-generation.md`、`content-extension.md`。

RuleChangePackage（文档与文档 check，零产品代码）：`spire-godot/content/README.md` §3 选项表新增 `conditions`／`unavailable` 两行（各写明与 `availability`／`hide_when_unavailable` 互斥），状态条件段重写为"两类拼写＋规范拼写规格（1—8 条、kind 只能取声明表种类）＋两种模式语义（`optional` 显示但禁用／`hidden` 不生成）＋完整模式优先级＋叠加求值与 `reason` 拼接规则（**声明顺序决定换行顺序**）"；`docs/content-templates.md`、`docs/content-generation.md`、`docs/content-extension.md` 同步；删除 B1b 遗留的"B2 起生效"标注。`README.md:219` 的"跨事件跳转／事件链 **B4 起生效**"据实保留（B4 未落地，文档不得提前宣称可用）。`tests/content_cases.gd` 的 `event_author_manual_lists_current_fields` 扩展词表（`conditions`／`unavailable`／`mode`／`optional`／`hidden`／`disable`／`hide`／`kind`／`reason`／`type`／`no_chastity_lock`／`has_relic`）并加反向断言（不得出现"B2 起生效／待 B2／尚不可用"，必须出现两类拼写、两类模式与"声明顺序"）；只加断言、未放宽任何既有断言。

验证（提交 `1f450d7`；域：作者文档 + 事件分类）：
- E0 等价：退出码 0、`PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea5…`（逐字相同）。
- 规则门：`content`／`architecture` 全 PASS；`-Impact` 变体（`20260916T084820647-6816`）退出码 1、`5/9455`、`failed=['card_power']`、`unrun=[]` —— 红集恰好等于本文件第 29 行既有登记项。
- 界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- 残留扫描：`B2 起生效`／`待 B2`／`B2 前`／`尚不可用` 零命中（唯一合法命中是 `README.md:219` 的 B4 标注）。协调者已独立复核 E0、两类套件（1019 断言）、UI 与内容门。
- 未跑：`-Suite all`、打包与发布门禁。**整片（B3／B4）未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B3 事件 trace 与具名 gate（核心 + B3b 收口，**本批未完成**）

域：`core/room_events.gd`、`core/game.gd`、`tests/installed_tools_cases.gd`。

RuleChangePackage（规则内重构，行为逐字节不变）：`core/room_events.gd` 新增 `probe_result`（唯一实现，`probe()` 保留原签名＝返回 `.reason`）把探测拆成可分别命名的阶段——`effects` 失败→`probe_failed`、`next_node`→取节点入口 gate、`validate` 失败→**`validate_failed`**、暂存未归还→**`held_pending`**；新增 `enter_node_result`（唯一实现）——空节点→**`node_empty`**、节点不存在→**`stage_missing`**，**既有 issue 文案一字未改**；`feasibility_gate` 改从 `probe_result` 取 gate。新增 **debug-only trace**：开关与数组挂在游戏对象的调试字段（`set_meta`／`get_meta`，**不进 `state`／不进存档／不进 View**，`core/game.gd` 未改），`trace_entry` 记录 `event／node／source_choice／option_id／decision／gate／kind／mode／index／reason／purpose`。修复实现者自查出的缺陷：`start` 原先用属性式 `g.get("event_trace_enabled")` 清空、而访问器用元数据，**两套存储**导致开关打开时不清空、trace 跨事件累积陈旧行（且 `g.event_trace=[]` 真执行会报脚本错误）；改为新增 `clear_trace(g)`，读／写／清三处统一到同一存储与接口。

验证（提交 `e78fc72`、`367477c`；域：事件分类 + 持久化）：
- **E0 两遍（协调者亲自复核，含引擎错误日志判定）**：关闭＝退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`；开启（冻结 oracle 的副本 + 一行开关，冻结物未改）＝同样退出码 0、同一摘要；两遍日志中 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（日志 `build/b3-verify/off.log`／`on.log`）。**口径补强**：oracle 显式 `quit(0)`，退出码不反映脚本错误，因此"退出码 0 + 摘要相同"必须与错误日志核对一起用。
- **release 不产出证据链**：①全仓 `rg` 显示只有测试与构建副本调用 `set_meta("event_trace_enabled"…)`，生产路径（`core/`／`data/`／`ui/`）无设置点、默认 false；②关闭与开启两遍摘要逐字相同；③`get_view`／`export_snapshot` 的 JSON 不含 `event_trace`／`event_trace_enabled`（由场景 10 的 check 断言）。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 2919 断言）；`-Impact` 展开集 `failed=[card_power, installed_tools]`、无本片新红（`unrun` 为预算内未跑完，非失败）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` 状态 `passed`（`summary.json` 复核）。内容包：`CONTENT PASS: 12 file(s)`。
- 落地具名 check：场景 04 `event_hidden_relic_option_traced`（event_flow_cases）、场景 10 `event_trace_never_reaches_state_or_save`（persistence_cases）。
- **未落地（本批未完成的原因）**：场景 03（gate 名全覆盖，须含 `validate_failed`／`node_empty`／`held_pending`／`stage_missing`）与场景 19（叠加逐条 trace＋关开关后为空＋上一事件行不残留）两者的断言在 D3 修复后**仍红**，实现者按纪律**移除红断言并未弱化、未提交**，怀疑与 `arrival`／`candidate` 两次评估间 trace 行的归属有关但未证实。**待定位并分类**（产品缺陷 vs 夹具期望）。

**新登记的既有红项**：`installed_tools` —— `tests/installed_tools_cases.gd:43` `SCRIPT ERROR: Invalid access to property or key 'detail'`，`FAIL: 0/9`；`t.find_action(g,"card",…)` 返回兜底 `{valid:false,payload:{}}`，即该 `strain` 卡候选未生成。**分类证据**：实现者在 `4d22a00`（B1 之前，临时签出 `core/`＋`content/`＋`tests/` 后还原、`git status` 干净）跑同一套件，**同样报错、同样 0/9** → 非本片回归；协调者在 HEAD 重跑复现同一错误。根因方向＝该夹具前置条件与当前卡牌/工具接口漂移，**未定类、未修**。门禁红集口径自此为 ⊆ {`card_power` 5 条, `installed_tools` 1 条}。

未跑：`-Suite all`、打包与发布门禁。**整片（B3 收口、B4）未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B3 续批：trace 行语义落地与两处实现缺陷修复（**B3 仍未完成**）

域：事件、检查与测试。

RuleChangePackage（规则内重构，行为逐字节不变）：
- **D1a**：`evaluate_option` 现在分别传 `source_choice`＝作者选项 id、`option_id`＝冻结实例 id（无冻结实例时回落作者 id），`trace_entry` 从字段取 `source_choice`——此前两者被写成同一个值，违反契约 §4.5（A25 第 3 条）。仅影响 trace 行。
- **`selector_empty` 具名化**：`enter_node` 在选择器展开为空时原先直接 `continue`，该选项**既不记 gate 也不产 trace 行**（违反 §4.2 的具名 gate 要求，也是场景 03 缺行的原因）。改为仍调用一次求值入口，使该选项得到 `selector_empty` gate 与一行 trace；**行为不变**（选项本就不进入冻结选项，E0 摘要即是其证明）。
- 场景 19 具名 check 落地（`event_flow_cases.gd:event_stacked_condition_trace_and_release`）：按 `purpose` 过滤、逐条比对 `source_choice`／`option_id`／`index`／`mode`／`gate`／`reason`、**跨 purpose 全等**（仅 `purpose` 可变）、`start` 后无残留、关闭时 0 行、存档与 View 不含 trace。

**一次误报的自我更正（留档）**：上一轮"套件上下文缺少 `purpose=="candidate" and index==0` 的行"**经原始数据否定**——实现者在取数前**多调用了一次 `candidates()`**（行数 4→6），且按总行数写死断言，违反 A25 第 2 条"禁止按 trace 总行数断言"。原始行数据显示两次求值的状态条件行**只差 `purpose`**、完全合规。这是本轮第三次"红项先定类"救回的时间（前两次：E0 比较器、`hidden` 模式立证）。

验证（提交 `4e9a1a2`；域：事件分类 + 持久化）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b3-verify2/off.log`／`on.log`）。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 2926 断言）；`-Impact` 红集 = {`card_power`, `installed_tools`}（均为既有登记项）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- **未完成**：场景 03（gate 名全覆盖，须含 `validate_failed`／`node_empty`／`held_pending`／`stage_missing` 与选择器两类 id 分开断言）仍为占位、未落地；B4 未做。**整片未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B3 完成：trace 与具名 gate 全覆盖（场景 03 落地）

域：`tests/event_cases.gd`、`core/room_events.gd`；契约 `event-pipeline-unification.md`。

RuleChangePackage（规则内重构，行为逐字节不变）：`tests/event_cases.gd` 新增 `event_gate_names_are_total`（+162/−18），按 `docs/event-pipeline-unification.md` §4.5（A25）与 §10 场景 03 的口径落地——①12 份内容逐事件：每个作者选项至少一条 arrival 行、未展开项恰一行、每行 `decision` ∈ {generated,dropped,hidden,disabled}、dropped/hidden 行必须命中 §4.2 的具名 gate 清单（12 名）；②状态条件行在 arrival↔candidate 双向**缺行/多行即失败**，逐字段（event／source_choice／option_id／decision／gate／kind／mode／index／reason）相等，单节点另断 `node` 相等，不进冻结集合的行必须确为 dropped/hidden；③**选择器两类 id 分开**：`source_choice` 恒不含 `__`，含 `__` 的行必须 `<source_choice>__…` 且逐实例恰一行、实例集合 == `room_event.options[*].id` == 候选 `payload.choice`；④**`selector_empty`**（`enchanters_empty_studio` 的 `temper`，seed 42）恰一行 `gate=="selector_empty"`＋`dropped`，且不进冻结选项与候选；⑤开/关两遍的 frozen options／candidates／rng／view 逐字相等、关闭时 0 行；⑥**禁止按 trace 总行数断言**，重复只按单次求值判定。五个具名 gate 全部用真实夹具（无桩）：`stage_missing`（已进事件上 `enter_node_result(g,"missing")`）、`node_empty`（关死多节点夹具 `finale` 的唯一选项后 `enter_node_result`）、`probe_failed`（真实魔力不足探针）、`validate_failed`（已进事件上把 `room_event.values` 弄坏后 `probe_result`）、`held_pending`（真装 `shaft_ring_low` → `hold_special` → `probe_result(...,true)`）。

**卡点定类（第四次"先分类"）**：前一轮的 `probe_result` 报 `Invalid access to property or key 'refs'`**不是** `validate_failed` 通路的问题——`probe_result` 首行即 `apply_effects(..., g.state.room_event.refs, …)`，而 `refs` 只有 `start` 之后才存在；同一条读取在 B3 之前（`f95e96f~1:core/room_events.gd:801`）逐字相同，产品全部调用点都在事件内。**结论＝夹具约束**（探针必须在已进入的事件上跑），非产品缺陷、非契约缺口；未改产品代码、未改契约、未放宽断言。

验证（提交 `79bd622`，父 `5c5ffda`；域：事件分类）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b3-verify3/off.log`／`on.log`）。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 3362 断言）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- **红集口径扩展**：`-Impact` 展开集的红集为 {`card_power`（5 条）, `installed_tools`（1 条）, `tower_progression`（10 条规则 + 1 条界面）}，三者均为本文件已登记的既有项（`tower_progression` 见本文件第 31 行；在新会话把它 `git stash` 掉后同样 10 条红，故非本片回归）。**门禁红集口径自此为 ⊆ 上述三项**。
- **操作口径**：`-Impact` 展开集里 `installed_tools` 的 `SCRIPT ERROR` 会触发 runner 的 runtime_error 分支而使其余分类 `unrun`——"红集恰好"的判定必须以**补充枚举**（跑完 `unrun` 分类）为准，报告里必须列出 `unrun` 清单，不得把未跑当通过。

**两处 trace 形状待裁（不影响玩法、不影响上述判据；已交规划者裁定后并入 B4 或 B3c）**：①`stage_missing` 无 trace 行（`enter_node_result` 只在 `node_empty` 分支写行，`room_events.gd:376` vs `:361`），而 A25 §4 把 `stage_missing` 列为节点入口失败行——补行还是改契约措辞待裁；②candidate 阶段探测后继节点时 `enter_node_result` 以 `purpose="arrival"`、`node=当前 stage` 写入且每个冻结实例各写一份（`succubus_three_games` 10 份相同行），A25 的过滤元组无法与真实 arrival 行区分——需给该情形独立的 `purpose` 取值或修订过滤口径。

B4（跨事件 `next` 与 `chain`）未做；`README.md:219` 的"B4 起生效"标注据实保留。**整片完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B4 完成：事件链（跨事件 next、chain 键、环守卫）——本片最后一批代码

域：事件、塔路与地图。

RuleChangePackage（行为在现有内容上逐字节不变，链能力为新）：`next` 接受对象形态 `{"event","node"}`，静态校验要求事件已登记、节点存在于该定义、拒绝自引用，同定义内仍只向后；新增 `next_target`（唯一解析入口）／`enter_target`／`chain_cleanup`／`_enter_chain`，跳转时重写 `room_event.id`／`stage`、`values`／`held` 延续、`cleanup_effects` 按 key 并集、`event_seen` 加入目标、`flow` 按新定义重算；`chain` **只在真跳转时**写入且与 `event_seen.append` 同一事务；候选阶段环守卫给 `disabled`＋gate `chain_loop`；A30 `stage_missing` 补节点入口失败行；A31 后继节点探测用独立 `purpose="next_probe"` 且节点级行按 `(event,purpose,node,gate)` 去重；`snapshot` 增量接受 `chain`（数组、元素已登记、不重复、非空），既有字符串分支与检查逐条保留。`_next_ends_event` 让"带奖励必须结束事件"与"起始节点可离开"不再对对象形态做 Dictionary↔String 比较。

验证（提交 `8633bd9`，父 `73e2f21`，6 files／+309−16；域：events + persistence）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b4-verify/off.log`／`on.log`）。12 份内容与冻结 oracle 夹具均不含跨事件 `next`，对象形态只在新夹具里用。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 3420 断言）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- **A29 补充枚举**：`-Impact` 展开集因 `installed_tools` 的 runtime error 使 18 分类 `unrun`；补跑后 17 PASS、仅 `tower_progression` 红（10 条）→ **补齐后红集恰好＝A28 三元集**，`unrun=[]`、指纹前后一致。
- 具名 check：`event_chain_jumps_to_another_event_node`（id／stage 切换、`chain==["chain_source_fixture"]`、`values`／`held` 延续、`flow` 镜像、`event_seen` 恰一次、cleanup 并集去重、离开时两个 cleanup 各执行一次且两件暂存装备原样装回）、`event_chain_loop_refused`（候选 invalid＋决策 `disabled`＋`gates==[chain_loop/kind chain]`、求值与提交均不改 state／rng／存档）、`event_chain_trace_rows`（A30／A31：`stage_missing` 行 `node`＝目标、`option_id` 空、重复进入仍 1 行；`node_empty` 由两个冻结选项探测仍恰 1 行 `next_probe`）、`event_chain_references_fail_closed`（自引用／未登记／节点不存在／缺 node／多余键／非字符串 node 逐例整包拒绝且注册表不变）、`event_pipeline_writes_only_declared_keys`（抵达实例无 `chain`；真跳转新增键恰为 `chain`；往返保持；`[]`／字符串／未登记／重复／非字符串元素原子拒绝；12 份内容仍无 `chain`）。

**B4 报出的三处缺口（待裁／待收尾，均不影响上述判据）**：①跳转**不重抽遗物**——`room_event.relic` 保持来源事件抽到的值，若目标事件含遗物奖励选项，`execute` 会发放**来源事件的遗物**（§3.3 未规定，未改随机消耗、未立证）；②`hold_special` 的 key 唯一性只在单定义内静态校验，**跨定义重复 key 无静态拒绝**（运行期"同一保管位置不能重复使用"会挡住，未立证）；③新增玩家可见 reason `CHAIN_LOOP_REASON` **缺英／日条目**，按安全回退显示中文。

**本片代码批次（B1／B1b／B2／B2b／B2c／B3／B3b／B4）至此全部落地**；仍待：上述三处缺口裁定与收尾、跨事件 `next` 与链语义补进四份作者文档（含删除 `README.md:219` 的"B4 起生效"标注）、validator 验收。**整片完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B5 完成：链遗物重抽、跨定义暂存 key、本地化与作者文档收尾（本片最后一批）

域：`tests/hand_assist_cases.gd`。

RuleChangePackage：①**A32 跳转重抽遗物**——抽出唯一 `offer_relic(g,spec)`，`start` 与 `_enter_chain` 共用；跳转时按**目标定义**重算 `room_event.relic`（目标含遗物奖励且池非空→抽一次；目标不含或池空→**置空**），不再保留来源事件的遗物。②**A33 跨定义暂存 key**——`_event_references` 末尾沿跳转图逐路径校验 `hold_special` key（`_chain_hold_key_issue`／`_hold_keys`／`_jump_targets`），跨定义重复或 cleanup 引用非本定义 key 即**整包拒绝**；运行期守卫文案未改。③**A34 本地化**——`legacy-en_US.json` 增 `legacy.hbe6fbb665a810824ce3c074b`（`CHAIN_LOOP_REASON`），条目 4947→**4948**，`needs_review` 5701→5702，`en_US 52/52`、`ja_JP 0/52`，旧源文零残留、译文非空。④**文档收尾**——四份作者文档补跨事件 `next` 对象形态与链语义（`chain`／并集／环／不能再回头），**删除 `README.md:219` 的"B4 起生效，当前不接受"**并改为现行说明；`event_author_manual_lists_current_fields` 纳入链关键词并加反向断言（只加未放宽）。

验证（提交 `556a231`，父 `8808be5`；域：events／persistence／本地化／文档）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b5-verify2/off.log`／`on.log`）。12 份内容仍不含链。
- 规则门（协调者重跑）：`event_flow,events,content,architecture,localization,persistence` 全 PASS（3586 断言）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- 具名 check：A32 三类（`event_chain_relic_drawn_from_target`／`..._cleared_without_target_offer`／`..._cleared_when_pool_empty`，各含随机域对拍）＋A33 `event_chain_hold_keys_fail_closed`（重复 key 与 cleanup 引用外部 key 双反例整包拒绝、注册表不变）＋A34 `locale_legacy_catalog_matches_current_sources`（`REQUIRED_SOURCES` 纳入新常量）＋文档反向断言。
- **判据敏感性**：临时停用 `_enter_chain` 的重算后 A32 五条断言变红（四条 class1＋一条 class2）——证明该 check 真的承载判据，不是空转。

**新登记的既有红项**：`hand_assist` —— `tests/hand_assist_cases.gd:38` `SCRIPT ERROR: Invalid access to property or key 'detail'`，`FAIL: 0/125`（与 `installed_tools` 同类：`find_action` 返回兜底 `{valid:false,payload:{}}`）。**分类证据**：把本批改动 `git stash` 后在 `8808be5` 上重跑同一套件**同样红** → 非本片回归；协调者在 HEAD 复现同一错误。**门禁红集口径自此扩为四项** ⊆ {`card_power` 5 条, `installed_tools` 1 条, `tower_progression` 10 条规则＋1 条界面, `hand_assist` 1 条}。根因方向＝夹具前置条件与当前动作接口漂移，未定类未修、另行排期。

**两条操作提示（留给后续与重建目录时用）**：①`python tools/build_english_catalog.py` 在本机**无法运行**（`build/translation-lite` 与 `english-translation-cache-v4.json` 不存在），新条目按契约 §17"离线模型不可用则人工补齐"直接写入目录；**日后重建英文目录时需把该条目补进生成器的 `MANUAL`／缓存，否则会被重建覆盖**。②新增作者层校验文案（本批 A33 的"事件链上重复使用了暂存 key："与 B4 同类新增）未补译，仅体现为盘点 `needs_review` +1，安全回退显示中文（作者层、非玩家主线）。③跨定义环（A→B→A）**静态不拒绝**（仅拒自引用，契约如此）：静态遍历以"路径上重复定义即停"保证终止，运行期由 `chain_loop` 守卫拒绝并由场景 12 立证。

**本片代码与文档批次（B1–B5 全部）至此收口**，下一步＝整片 validator 验收（契约 §11，20 条具名场景＋全部判据）。**B5 已收口，验收可开始；验收通过前不得打包发版。**未推送、未打包。

## 2026-09-16 事件管线统一（B1–B5）整片验收

域：`spire-godot` 事件管线统一切片——定义形态归一（`nodes`／`start_node`）、单求值入口（`evaluate_option`／`enter_node`）、资格从四条并行通道收敛为一份 `CONDITIONS` 声明派生四处、选项生命周期具名 gate、debug-only trace、跨事件 `next` 与 `chain`。契约 `docs/event-pipeline-unification.md` §11／§12／§10／§0.1／§4.5／§3.3／§3.4／§9；依赖规范 `docs/event-pipeline-dependency-spec.md` §4.2。

验收者：独立会话（未参与本片实现），未改产品代码／既有测试／内容包／契约与依赖规范／冻结 oracle 与基线；只新增忽略目录内的验证脚本与记录。对象提交 `3e64cff`（父 `84f8ea3`），验收期间工作区 `git status --porcelain` 前后均为空。

- 验收脚本（`spire-godot/build/validator-20260916/`，gitignored，可复跑）：
  `run-validation.ps1`（编排全部判据并产出 `run-20260916-02/report.json`／`report.txt`）；
  `scenario_probe.gd`（§10 01–20 具名 check 的逐条直调，附依赖规范 §4.2 五条与本地化口径①②，逐条打印断言数与引擎错误数）；
  `scenario14_roundtrip.gd`（场景 14 的 validator 侧覆盖，见下）；`human_path_ui.gd`（真实窗口与真实 viewport 输入驱动 §11 第 6 条缺口）。
  复跑：`powershell -NoProfile -ExecutionPolicy Bypass -File build/validator-20260916/run-validation.ps1 -RunId <id>`。
- **E0 两遍（关闭／开启 trace）**：均退出码 0、`EVENT RESULT: PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` **逐字相同且等于冻结基线**；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`e0-off.log`／`e0-on.log`）。
- 内容门：`& tools/check-content.ps1` 退出码 0、`CONTENT PASS: 12 file(s); validated without changing game or saves`（日志 `check-content-engine.log`）。
- **规则门** `& tools/check.ps1 -Suite event_flow,events,content,architecture,localization,persistence -Impact -KeepGoing -TimeoutSeconds 900`：退出码 1（既有红项），`-Impact` 展开 37 个分类，`summary.json` 各轮 `before==after`、无 `source_changed`。**红集＝{`card_power` 5 条, `installed_tools` 1 条, `tower_progression` 10 条}**，逐条计数与登记一致，**未超出 A35 四项集**。`installed_tools` 的 `SCRIPT ERROR` 触发 runner 的 `runtime_error` 分支，**使其后 18 个分类 `unrun`**（清单：environment_height／exploration／shoulder／slip_motion／torso_binding／casting／special_equipment／services／action_copy／persistence／rewards／events／links／prison／pressure／enemies／trader／tower_progression）；按 A29 **逐分类单进程补跑**，17 个 PASS、`tower_progression` FAIL（10 条），**补跑后 `unrun` 为空**，`unrun` 未记作通过。
- **界面门** `& tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900`（A17 时限）：退出码 0、`SUITE RESULT: localization PASS`／`events PASS`、`UI PASS: 231 assertions`、`summary=passed`。
- **§10 20 条具名场景：20/20 `passed`**（`scenario-probe.log`，同一进程逐条直调，断言数见括号）：01 event_definition_single_form(185)／02 event_option_policies_match_current_behaviour(134)／03 event_gate_names_are_total(436)／04 event_hidden_relic_option_traced(3)／05 event_condition_kinds_share_one_declaration(9)／06 event_stage_available_condition_validates(8)／07 event_definition_form_rejects_legacy_shape(14)／08 event_single_node_declarations(8)／09 event_node_empty_policy_kept(8)／10 event_trace_never_reaches_state_or_save(6)／11 event_chain_jumps_to_another_event_node(19)／12 event_chain_loop_refused(8)／13 event_probe_and_projection_readonly(3)／14 event_frozen_options_roundtrip(84，**validator 侧覆盖**，见下)／15–18 由合并 check `event_stacked_conditions`(14) 承载／19 event_stacked_condition_trace_and_release(7)／20 event_stacked_conditions_keep_current_content(98)。0 引擎错误。
- **场景 14 无落地的具名 check**（磁盘复核：`rg -n event_frozen_options_roundtrip spire-godot/tests/` 无命中；契约 §10 的 01–20 归属清单也未列 14）。validator 按 §11"把验收程序变成可执行脚本"在忽略目录补 `scenario14_roundtrip.gd`：12 份内容的冻结选项与 `room_event` 经真实 `SaveStore.pack/unpack` 与正式入口往返**逐字节相等**（8 单节点＋4 多节点），`next` 只在 staged 布局出现，六类畸形 `next`（缺键／非串或对象／未知节点／未登记事件／自引用／目标节点不存在）**整包原子拒绝**且文案＝"无法继续这份存档：多阶段事件冻结选项损坏。"（84 断言 PASS）。**该缺口属契约落地缺口，非产品缺陷**；正式具名 check 是否补落由规划者裁定。
- 另两条与字面合同的偏差（均不影响行为判据）：①场景 19 的**存档侧同断言**按 §10 应落 `tests/persistence_cases.gd`，实际落在 `tests/event_flow_cases.gd:800`（同一断言内含"存档与 View 不含 trace"半；B3 执行记录已按此登记，属落点与文面不一致）；②§11 第 6 条"付费离开"在所有内容包中已无对应选项（`rg 支付费用 content/packs/` 零命中），该人路径项按现行内容不存在，已改以正式离开路径与人路径 H2／H6 立证。
- **依赖规范 §4.2 五条 check：5/5 `passed`**（直调断言数）：event_dependency_edges_pinned(9)／event_definition_accessors_only(140)／event_condition_kinds_share_one_declaration(9)／event_single_evaluation_entry(26)／event_pipeline_writes_only_declared_keys(85)。
- **本地化口径①②③**：①＋②由 `locale_legacy_catalog_matches_current_sources` 直调 PASS(62 断言：`REMOVED_SOURCES` 25 条旧源文零残留、`REQUIRED_SOURCES` 35 条译文非空)；③盘点 `python tools/localization_inventory.py`＝`needs_review 5702`、`connected_static_call 33`、`en_US 52/52（缺 0）`、`ja_JP 0/52`，目录条目 **4948**（与 B5 记录 4947→4948 一致）。`python tools/build_english_catalog.py` **未运行**：本机缺 `build/translation-lite` 与 `english-translation-cache-v4.json`（A36① 已登记），目录按"离线不可用→人工补齐"维护。
- **§11 第 6 条人路径（真实窗口、真实 viewport 输入）**：既有 `-UISuite events` 覆盖首次进入候选、硬闯战斗→整备、选牌／道具奖励、多阶段逐阶段点击、离开；**其未覆盖的两项由 validator 驱动脚本补**（`human-path.log`，退出码 0、18 断言 PASS）：H2 持有 `softened_buckle` 后【硬闯】缺席且【离开】出现并可由真实点击走完（E6 政策维持现状）；H6 存档并在**正式入口** `HomeContinue` 继续后，阶段／冻结选项／报告与存档点逐字段一致、重按【祈福】报告文本逐字相同。§11 第 7 条叠加条件证明由场景 15–19 承载。
- **四态计数（本片 20 场景）**：`passed 20`／`failed 0`／`unverified 0`／`skipped 0`。步骤层：E0 `passed`、内容门 `passed`、规则门 `passed`（红集在册、`unrun` 清零）、界面门 `passed`、依赖五条 `passed`、本地化口径①②③ `passed`、人路径 `passed`。
- 补充核对（非判据，仅确认既有红项仍如登记）：`-Suite hand_assist` 退出码 1、`0/125`、`SCRIPT ERROR ...'detail'`（A35 一致）；`-UIOnly -UISuite tower_progression` 退出码 1、54 断言、1 条 `SUMMIT UI run loss offers correct restart instead of equipment practice`（登记一致）。
- 未验证／未跑：`-Suite all` 与 `-UISuite all` 全量回归（契约未要求）；Android 真机；`build_english_catalog.py`（环境不可用，见上）；§10 场景 14 的**正式具名 check**（validator 脚本已覆盖行为，落地归属待裁定）。人路径的"关闭 debug 开关：`g.event_trace` 为空"在规则侧场景 19／10 有断言，未另做界面侧重复操作（同一切面，无新增信息）。
- 结论：**本片通过验收**（20/20 场景、五条依赖 check、口径①②③、E0 两遍逐字相同且 0 错误行、红集 ⊆ A35 四项集且补跑后 `unrun` 为空）。未打包、未发版、未推送。归因纪律：本轮无新红项，未修改产品代码、未改动任何既有断言。

## 2026-09-16 B6 完成：场景 14 的具名 check 落进仓库（验收可复现性收口）

域：`tests/persistence_cases.gd`、`core/snapshot.gd`。

RuleChangePackage（仅测试，零产品代码）：`spire-godot/tests/persistence_cases.gd` 新增 `event_frozen_options_roundtrip`（定义 153 行、由 `run()` 在 255 行调用，本次 +75 行），把原先只由**忽略目录里验证者私有脚本**覆盖的场景 14 落成仓库内正式 check（域＝存档）——①12 份内容（8 单节点＋4 多节点）的冻结选项与 `room_event` 经真实 `SaveStore.pack/unpack` 与**正式入口** `restore_snapshot` 往返后 **`JSON.stringify` 逐字节相等**、`validate()==""`、单节点/多阶段计数 8/4；②`next` 只在 staged 布局（`frozen_form != "in_place"` 或作者选项带 `selector`）出现，并覆盖单节点 in_place 事件里由共享 staged 构建器冻结的选择器实例（`alchemist_tasting_stall`／`enchanters_empty_studio`）；③**六类畸形 `next`**（缺键／非字符串或非对象／未知节点／未登记事件／自引用／目标节点不存在）**整包原子拒绝**且文案＝`无法继续这份存档：多阶段事件冻结选项损坏。`，断言只改快照副本（A27）。

验证（提交 `3011cff`，父 `b9e5639`；域：persistence）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同、两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b6-verify/off.log`／`on.log`）。冻结 oracle 与基线未改。
- 规则门（协调者重跑）：`persistence,event_flow,events,content,architecture` 全 PASS（3544 断言）。实现者侧另跑 `-Impact -KeepGoing` 六类：红集＝{`card_power` 5, `installed_tools` 1, `tower_progression` 10} 在 A35 四项集内；`installed_tools` 的 SCRIPT ERROR 使 18 分类 `unrun`，**逐分类补跑后 `unrun=0`**（17 PASS＋`tower_progression` FAIL 10）。界面门 `-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231；内容门 12 file(s)。
- **敏感性证明**（随后还原、`git status` 干净）：①改错期望文案 → **恰 6 条红**，六类畸形 `next` 逐条打印；②往返比对注入漂移（`options[0].label` 加后缀）→ **12 条红**并打印 `SAVE DIFF state.options[0].label …`。证明该 check 不是空转；先试的"把比对改成恒真"因按构造不可能变红而弃用（属正确的判据设计判断）。

**越界缺口（本批未修、未断言，交规划者裁定，A40）**：单节点 **in_place** 事件的冻结选项 `next` **完全不被存档校验覆盖**——`core/snapshot.gd:427` 的 `next` 校验挂在 `if event.get("flow",false)` 分支内，普通事件从不进入该分支。最小复现：把 in_place 事件的选择器实例（如 `alchemist_tasting_stall` 的 `dissolve__equipment_2`）的 `next` 改成未知节点／未登记事件／`42`，`restore_snapshot` **全部接受**（`build/b6-probe-20260916/probe_inplace_next.gd`）。**来源判读：既有缺口，非本片引入**——该分支结构先于 B1，且 B2 已论证"把校验从 flow 分支改为按选项键判定"会**放宽** flow 侧的既有拒绝（缺 `next` 的损坏多阶段选项今天被拒），故当时按契约保留分支不动。影响有限：运行期 `next_target` 解析对未知目标会经 `stage_missing` 等具名 gate 失败（本片 B3 的产物），不是崩溃路径。**裁定：不在本片内修**，登记为既有缺口另行排期；契约 §6.3 需按现状改写（staged 布局选项的逐键校验已落地，in_place 实例的 `next` 未校验）。

**本片至此代码、文档、验证三线收口**：B1–B6 全部完成，整片通过验收（`3e64cff`，登记 `1881568`），场景 14 的仓库内可复现入口补齐（`3011cff`）。**未打包、未发版、未推送**；打包与发布须用户明确指令。

## 2026-09-17 状态迁移管线收束（单写入者 + 单战斗结束判定）

域：`core/game.gd`、`tests/architecture_cases.gd`；契约 `check-routing.md`。

RuleChangePackage（规则内重构，行为逐字节不变）：把散落的同类状态迁移收束到**单写入者**——`state.phase=` 26 点 → **1 点**、`state.room=` 10 点 → **1 点**（均在 `core/game.gd` 的 `_apply_transition` 内，由 `TRANSITIONS` 声明表驱动）；结束战斗从 13 个引用点／**8 个语义入口** → **1 处判定** `_battle_end_reason()` ＋**1 处执行** `_finish_battle(end_kind)`（调用位点保留，避免改变随机消耗与日志顺序）；**收押（`Guard.capture`）改道进同一路径**；`_restart_tower` 保留 3 个调用点。副作用（生成敌人、滚奖励、收押清理、牢房初始化）**留在原函数、原顺序**；**赋值在控制流中的位置不变**（明确拒绝"事务末统一执行"，因为事务中段会读 `state.phase`）；新增迁移日志 `_transition_log` 仅进程内（不进 `state`／存档／View）。新增闭环 check `tests/architecture_cases.gd:104 transition_write_sites_are_pinned`（四组模式扫描、注释与 `==` 不计入、**双向比对**：扫描集 ⊆ 表 ∧ 表内点都被扫到，表外或未命中打印 `文件:行:函数`），表内 **14 项**。

验证（提交 `9ee7a2f`（基线冻结）→ `d519402`（战斗结束）→ `a1744de`（阶段）→ `9d5a6af`（房间）→ `35f3411`（闭环与八条 check）；域：core + rewards/battle_saturation/guard/prison/tower/persistence/architecture）：
- **迁移 oracle（主证据）**：31 个场景覆盖八类战斗结束入口、`prepare_end` 三类、`floor_enter` 与同层换塔、练习初始化四种、牢房回合／巡视／逃脱／高安全、事件进入／空房／道具奖励、demo 结束与返塔；每场景冻结迁移前后 `phase/room/floor/version/rng/本次提交日志 sha256＋可读日志行/room_event 摘要`。**协调者独立重跑两次**：均退出码 0、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（两次同值）、`SCRIPT ERROR|ERROR:|Invalid access` **0 行**。
- **受影响套件（协调者重跑）**：`battle_saturation,rewards,guard,prison,tower,persistence,architecture` 全 PASS、3678 断言、墙钟 148s。实现者侧完整门禁：规则门 2m08s（11 类 → `-Impact` 展开 44 类）红集 **{`card_power` 5, `installed_tools` 1} ⊆ 已知四类**，`installed_tools` 的脚本错误令 24 分类 `unrun`，**合并一次调用**补跑 3m29s → 23 PASS ＋ `tower_progression` FAIL 10 条（已登记），`unrun` 清零；界面门 1m22s `persistence,home,events` PASS 369 断言；闭环 check 25s。
  > **本条已取代（superseded，2026-09-17；新口径见 `docs/check-routing.md` §4.3）**："截断／`unrun`／合并一次调用补跑"口径作废——脚本错误只记该套件 `FAIL(runtime)`＋`SUITE RUNTIME: <name> <n>`，同轮跑完其余套件、`unrun=[]`、无需补跑；数字原样保留为历史。
- **闭环 check 敏感性证明**：临时在 `_finish_if_saturated` 插一处表外 `state.phase="battle"` → `FAIL: 1/462`，并打印 `["res://core/game.gd:803:_finish_if_saturated"]`；还原后 `architecture PASS: 466 assertions`、`git diff` 无残留。
- **未跑（按契约保持未验证）**：`-Suite all`／`-UISuite all` 全量、Android 真机、迁移日志的消费方（存档切片仍暂停）；未推送、未打包。

**判据身份（迁移 oracle，2026-09-16 冻结）**：冻结脚本 sha256 `b49b0164a6b962fc8eae4a843c36510e1fa12c846d9f0e565856fdc6ed092278`（摘要 `00089c29a675e1268473645ab6b7a363e70295abf575cc6cc2929db995ca3e11`）；当前脚本 sha256 `59d41c682b3b302c1d291eb64aea770994c89508ee3fcb637afc7902024c045c`（摘要 `14eb8cf9…`，两次运行同值）；**基线文件 sha256 `ba979d18c31952d6d69ef06ce2ed102f7503c518fa8c6125ea6482c92bb5b4c8` 自冻结起未改**。脚本冻结后**只在比对侧改两处**（新增 `_merged` 折叠相邻同名、`_compare_row` 仅对 `transition_log` 一列双侧折叠；其余列仍逐字段硬比对并保留 `NEWFIELD／MISSINGFIELD` 双向检查），**抓取路径未动**。证据：用当前脚本 `--write=` 到 `build/transition-oracle-20260916/identity-tmp.json`（sha256 `8cf606aa94fb9d946fc7317ad07e55bc9395684deb1f1767595bfa01964cc1bc`）与冻结基线对照——行名与逐行键集完全相同，**唯一差异列是 `transition_log`（31/31，冻结时该列按设计为空、现在为真实 kind）**；把两侧投影到参与比对的六列（`before/after/commit_logs/log_texts/digest/transition_log_declared`）规范化后**两侧同为 sha256 `5333ab642896dd5932faca53211aa7f77510b59065fc0c3a0a1d6374bd78d2fb`**，即扩展未放宽任何比对项；冻结脚本自身 `--baseline=` 自比（`selfcheck.log`）显示 31 条差异**全在 `transition_log`**、行为字段 0 条。**口径**：摘要是脚本版本指纹、**比对才是门禁**；重跑时摘要不一致不等于行为漂移，须按上表核对身份。

**与契约文面的四处不符（已转规划者入契约，均不需改产品代码）**：①收押经 `_apply_transition` **两次**写入（phase／room），不经 `_finish_battle`（后者拥有胜利／饱和奖励体；副作用仍在 `Guard.capture`、顺序不变）；②新增 `floor_enter` 与 `demo_end` 两个 kind（§3 表原只列 `room_enter`，§5 场景 03 用到 `floor_enter`）；③`_enemy_phase` 尾部判定在真实流程**不可达**（仅非法卡链状态可达），oracle 单列 `skip_validate` 场景冻结它，删除会改动闭环表行数与函数集合，故保留；④oracle 两处冻结声明与代码事实不符（`tower_restart`×2、重复同名写入），按"两侧同口径合并"比对，**基线 JSON 与行为字段零改动**。**折叠边界（协调者裁定）**：`transition_log` 列放过"同一 kind 相邻重复的额外一条"——该列是进程内诊断、不进 `state`／存档／View，且"恰一条 `battle_end_*`／均为 `prepare_end`"由闭环 check 与场景 01／02／04 承接，故接受；若将来该日志成为存档切片的数据源，此边界须重审。

## 2026-09-17 固定点存档：只在三处写盘

域：`core/game.gd`、`ui/main.gd`、`tests/persistence_cases.gd`、`tests/persistence_ui_cases.gd` 等；契约 `equipment-performance.md`。

RuleChangePackage（行为对玩家不变，档案写入时机改变）：`core/game.gd` 的 `TRANSITIONS` 声明表新增 `checkpoint` 列——`floor_enter`→`floor`、三个 `battle_end_*`（含 `battle_end_captured`）→`battle_end`、`prepare_end`→`prepare_end`；新增 `CHECKPOINT_PRIORITY` 与 `_checkpoint_kind(log_start)`：`dispatch` 在 `var original=state` 前记 `log_start`，成功字典**末尾追加加性键 `checkpoint`**（`""`／`floor`／`battle_end`／`prepare_end`，由本次提交实际产生的迁移日志条目推导、同类去重、多类按 `battle_end ＞ prepare_end ＞ floor` 取一），失败字典保持原 `{ok,error}` 形状。`ui/main.gd` 的 `_submit` **仅在 `checkpoint` 非空时**调 `_save_progress()`；**删除恢复后立刻写盘**（`_quick_sl` 路径）；**保留**三条非进度写盘（地图线稿变更 `:1636`、新局替换不兼容档 `:1965`、手动"保存场景起点" `:2682`）。新增具名 check：`tests/persistence_cases.gd` 六个（正例 3／反例集合 1／`.bak` 与回退 1／失败与格式契约 1）＋`tests/persistence_ui_cases.gd` 真实 UI 写盘门控＋`tests/architecture_cases.gd` 的闭环 `save_checkpoint_kinds_are_pinned`（checkpoint 集合与声明表被标记的 kind 完全一致，多／少／改值／优先级名集不一致均红）。

验证（提交 `87a357e`，父 `9dd74fd`；域：persistence + architecture + UI home/persistence）：
- **迁移 oracle（第一道防线，协调者亲自复核）**：退出码 0、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（与当前脚本指纹一致）、脚本 `59d41c68…`／基线 `ba979d18…` 未动、引擎错误 0 行。墙钟 5s。
- **规则门（协调者重跑窄集）**：`persistence,architecture` 全 PASS、1426 断言、28.9s。实现者完整门禁：`-Impact -KeepGoing` 72s 红集 = {`card_power` 5, `installed_tools` 1} ⊆ 已知项，`unrun` 16 类**合并一次调用**补跑 142s → 15 PASS ＋ `tower_progression` 10 条（已知），`unrun=0`、**无新红**。
- **界面门（协调者重跑）**：`-UIOnly -UISuite persistence,home -TimeoutSeconds 900` 退出码 0、`home PASS`／`persistence PASS`、**217 断言**、66s。实现者另跑 `-UISuite route` PASS 134（证明地图线稿真手势写盘保留）。
- **性能配对**（`docs/equipment-performance.md:45` 协议；`build/save-fixed-points-20260916/paired-results.json`，`problems: []`）：0/12/26 × battle/departure 六组合**场景内提交 `save` 段中位全为 0.0ms、`new_writes=0`**（旧侧中位 28.0–38.0ms）、两侧最终状态 `identical: true`；固定点单次写盘中位 **18.1ms（0 件）／36.8ms（26 件）**。
- **敏感性证明**：①给非固定点 `rest_start` 标 checkpoint → `architecture` 与 `persistence` 同时红（11/1427，打印 `rest_start->floor` 与固定点集合尺寸）；②摘掉 `prepare_end` 标记 → 12/1422 红。两次均还原、`git status` 干净，日志 `build/save-fixed-points-20260916/sensitivity-{1,2}-*.log`。
- **口径裁定（协调者）**：休息房的**最后一个休息回合**经 `_finish_preparation` 落到 `prepare_end` → **写盘**（这正是"完成休整后存档"）；休息房内的行动、奖励选择与非末回合**不写**。该语义在 kind 粒度上不可再细分，故反例集合的措辞以"非末回合／奖励不写"为准。
- **实现的取舍记录**：`tests/persistence_cases.gd` 增至 735 行（超出项目 500 行惯例；本仓无 Size 计数规则，且本片边界禁止新增文件，故落在既有文件内）。

**新登记的既有红项**：`home_persistence`（UI 套件，`tests/home_persistence_ui_cases.gd`）——3 条断言失败：`HOME new game creates and saves actual tower entry`／`HOME controls remain in logical 16:9 frame after resize`／`HOME restored service room remains interactive`，`UI FAIL: 45`。**分类证据**：把 `core/`＋`ui/`＋`tests/` 整体回退到**已推送的 `a673352`**（早于迁移收束与存档两片）后跑同一套件，**同样三条断言失败** → **非本片引入**；此前未登记是因为门禁一直用 `persistence,home` 两个独立套件，从未跑过 `home_persistence` 这个组合套件。**方法注**：只回退产品文件会因 HEAD 的测试引用新符号而编译失败，定类必须整体回退 `core/`＋`ui/`＋`tests/`。门禁红集口径自此为 ⊆ {`card_power` 5, `installed_tools` 1, `tower_progression` 10＋1, `hand_assist` 1, `home_persistence` 3}。

未跑：`-Suite all`／`-UISuite all` 全量、Android 真机、打包发布。

## 2026-09-17 检查路由与隔离（派生索引 + 单套件失败不中断）

域：`tests/test_game.gd`、`tests/ui_smoke.gd`、`tests/runtime_error_ui_probe.gd`、`tests/check_index.gd` 等。

RuleChangePackage（**只改工具与测试，产品代码零改动**；`git diff a56de58 -- core ui data content assets` 为空）：
- **隔离**（`eaa003a`）：`tests/test_game.gd` 去掉整轮 `break` 与加载失败 `quit(1)`——脚本错误只记该套件 `FAIL` ＋ `SUITE RUNTIME: <name> <n>`（n≥1 才打印），其后套件照跑；`tests/ui_smoke.gd` 同款（setup 期错误打 `SUITE RESULT FAIL` ＋ `SUITE RUNTIME` 后进入下一模块）；`--keep-going` 成为兼容无操作；新增 `tests/runtime_error_ui_probe.gd` 负例夹具。`tools/check.ps1 -VerifyRunner` 探针扩为 5 条隔离反例，**并修掉一个既有 harness 缺陷**（选择探针把子进程 stderr 经 `2>&1` 灌进父进程，`ErrorActionPreference=Stop` 下变终止错误；该缺陷在 `3afdc55` 上同样复现）。5 处旧口径加 superseded 指针（**只加指针、未改历史文本**）。
- **索引**（`aa199f4`）：`tests/check_index.gd` 单一派生实现（信号：`preload`／门面符号／`ui.<成员>`／断言域前缀；`static func` 故意不入索引以免无精度放大），生成器 `tools/build_check_index.gd` ＋ `tools/check-index.ps1 -Write`（**判据只读**），冻结物 `tests/check_index.json`，手写层 `tests/check_index_edges.gd`（`DOMAINS` 58／`WIDEN` 1／`EXCLUDE` 12／`BLIND_BY_DESIGN` 4／`INDEX_DEFECTS` 空，逐条带理由），计划宿主 `tests/route_plan.gd`，`tools/check.ps1` 增 `-Changed`／`-Since`／`-ChangedList`（与 `-Suite`／`-UISuite`／`-UI`／`-UIOnly`／`-Impact` 互斥）。**索引规模**：覆盖 97 个注册套件（规则 51＋界面 46；`suites_with_edges` 94 是"有派生边"的另一口径）、**436 条"套件→源文件"边**、176 个用例文件全部有唯一 owner、`core|data|ui` 120 个源文件中 117 有边或域解析、4 个盲区；冻结摘要 `db5617dd2d272df99cbcca2b6f7a28d36dd823f8cc69f4fe5c258ee169894dda`（冻结物以 `tests/check_index.json` 为准，2026-09-17 重冻为 digest `e2f17665…`／437 边；436 条与原摘要保留为历史）。

验证（提交 `eaa003a`、`aa199f4`、`cfc5d9d`、`6100179`；域：检查工具与测试基础设施）：
- **协调者独立复核**：`tools/check-index.ps1` → `CHECK INDEX PASS: frozen index equals the derivation`（摘要 `db5617dd…`）、退出码 0、**2s**；`-Suite runner` **PASS 1446 断言**、11s；造一个真实改动（`ui/event_screen.gd` ＋1 行注释）→ 计划逐行打印 `ROUTE MODE`／`ROUTE FILES (sha256＋index digest)`／`ROUTE ROW … -> rules=(none) ui=events [signals=domain]`／`ROUTE MILESTONE: declared baseline,normal_play; deducted (none)`／`ROUTE RULE SCOPE`／`ROUTE UI SCOPE`／`ROUTE PLAN`；**干净工作区下 `-Changed` 显式报错**（"The change set is empty; committed changes need -Changed -Since <ref>"），不静默。
- **隔离判据（实现者实测）**：同一宽集命令改动前 **278.6s 截断 ＋ 补跑 261s ＝ 539.6s／2 进程／`unrun`=18** → 改动后 **729s／1 进程／37/37 有结果／`unrun`=[]**；红集不变；**逐套件断言数与改动前逐条相等，合计 16903 条**（"不靠减少覆盖换速度"成立）。
- **三处敏感性证明**（全部还原、工作区干净）：①冻结物改一字节 → `CHECK INDEX FAIL` ＋ 默认门禁 `runner` 同红；②删一条索引边 → `first difference at root.suite_files.…(missing on right)` ＋ `runner` 同红；③源码漂移不 `-Write` → `root.generated_from` ＋ `index_regeneration_is_the_only_writer`、`FAIL 2/1446`；④隔离四反例（assertion／assertion-keepgoing／runtime／load）经 `-VerifyRunner` 得 `SUITE RESULT: runner FAIL` ＋ 后续套件 PASS ＋ `unrun=[]`。
- **`-Changed` 正反例（实现者实测）**：改动内容包 → 7 个消费者＋内容门、退出码 0（43s）；`ui/event_screen.gd` → `RULE SCOPE (none)` ＋ UI `events` PASS 180（44s）；真实工作区计划 ≈7s。

**诚实的反发现（重要，纠正协调者早先的预期）**：契约 §5.6 预期的"隔离后一次进程 ≈400s"**未复现**——单进程 729s 比改动前两段之和 539.6s **慢约 190s**，全部落在 `prison`（92→283s）与 `persistence`（24→169s）；单独跑这两套件回到 91s／23s（125s）。即**长驻进程内的累积开销**，断言数不变。所以隔离的**可复现收益是"`unrun=[]`、免除人工补跑编排、运行时错误有具名标注"，不是墙钟时间**；"拿回五分钟"这一说法**作废**。待裁：是否改为**分批跑**（每 N 个套件重启一次进程，保留隔离语义）。

**与契约的偏差（均加性、已带理由，交规划者确认）**：①`check_index.gd` **551 行**（§9 目标 ≤300；其余文件达标）——为把抽取规则写进文件头与四个接口同文件；②冻结物 **71 KB／3250 行**（§11-6 引用的估算 ≈11 KB；键序稳定已证：两次 `-Write` 逐字节相同）；③`tests/**` 非用例文件走目录闭包（契约 §2.2 的示例早于协调者裁定⑤，属文面滞后）；④新增 3 个数据键（`CLOSURE`／`ORACLE_NOTES`／`SUITE_EXEMPT`）与路由对象内加性键 `gate_results`。

**新登记的既有红项**：界面模块 `interface`（`tests/interface_ui_cases.gd:156`）——`CARD ART every registered card has an illustration` 列出 **28 张 `witch_*` 卡缺立绘**，`UI FAIL: 355`。**分类证据**：`git diff a56de58` 对 `ui/`／`assets/`／`content/`／该用例文件均为空、断言与夹具未变 → 既有内容缺口（角色二卡缺立绘），此前未登记只因门禁从未单独跑过该模块。协调者在 HEAD 复现。**门禁红集口径自此为 ⊆ {`card_power` 5, `installed_tools` 1, `tower_progression` 10＋1, `hand_assist` 1, `home_persistence` 3, `interface` 1(28 张卡)}**。

未跑：全量 `-Suite all -UI -UISuite all`（契约定为里程碑唯一入口）、Android 真机、打包／发版。

## 2026-09-17 卡顿定位：一次点击的成本分布（P0 分段计时，测量非改动）

域：`tests/game_fixture.gd`、`core/game.gd`、`ui/main.gd`、`core/game_view.gd`；契约 `response-pipeline.md`。

方法：真实窗口 1600×900、zh；夹具 battle＝`tests/game_fixture.gd`(42)／departure＝`core/game.gd`(42)；0/12/26 件 × 三类点击（成功提交／选择类／被拒或无效）；`ui/main.gd render()` 与 `dispatch`／`get_view` 调用点**临时插桩**（标签用 `docs/response-pipeline.md` §8 节名），跑完 `git checkout --` 还原（**协调者复核：工作区干净、`build/` 外无插桩残留**）。产物与原始数据：`spire-godot/build/stutter-trace-20260917/`（`round-a.json`／`round-b.json`／`analysis.md`／`noise.md`）。

**结论（占比，% of 该次点击同步总耗时）**：
- **最大单项是候选生成，且被付了两遍**（2026-09-17 更正：两次 `candidates()` 面对不同状态，不是重复计算；见本条目下文更正段。）：battle:26 成功提交（A 轮，总计 **260.3ms**）＝ `dispatch` 39.4% ＋ `get_view` 29.1% ＋ `render` 20.4% ＋ feedback 10.3%；其中 `dispatch` 内 `candidates()+pick` 占 40–52%、`get_view` 内 `g.candidates()` 占 49–66%。结构佐证：`core/game.gd` 的 `dispatch` 内 `for c in candidates()`（提交前复核）与 `core/game_view.gd` 的投影（`get_view` 内 `g.candidates()`）各算一次。
- **整树重建 `render` 不是提交类点击的最大项**（battle 43–53ms，与件数几乎无关：0→26 件 51.4→53.0ms；占提交 20–37%），但**是"点牌选中"点击的 94–95%**（该次点击仅 45.4ms）与**被拒点击的 36–62%**。render 内部最大三节：`body_bar.configure` 约 11ms（仅在相位／身体内容变化时付；同相位刷新命中 `_presentation_key` 仅 0.3ms）、`hand` 9.6–12ms、`actions+rail` 6.5–8.6ms；departure 页面的 render 由 `header+relics` 占约 70%。
- **`save` 24 个单元格全部 0 次 `write_game`**（固定点存档已把磁盘移出点击路径；计数器经 `restart()` 固定点验证＝每次 1 次）。
- **被拒点击的 `dispatch` 只占 0.1–0.2%**（131–182µs，版本判定在候选生成之前返回）；其成本在 `get_view`（36–62%）与 `render`（36–62%）。
- **`get_view` 的 `card_texts` 只占 1.6–7.9%**——"每次无条件生成约 83 型"已是过期事实（`core/game_view.gd:4 _card_display_set` 按需，实测每次 2–4 型、departure 为 0）。

**两条与契约文面不符（协调者已核代码事实，待规划者改文本）**：①`docs/response-pipeline.md` 关于 `card_texts` 无条件全量的成本事实（§2.2／§6.1）已被按需化取代；②同文件"选择类点击每条分支都整树 `render(view)`"不成立——翻面与选敌现在 0 次重建（局部刷新），只有点牌选中会 1 次重建。

**可靠性边界（必须遵守）**：①占比可靠（两轮首位一致 23/24；占比比值无一处超 0.5–2.0）；②**绝对微秒不可跨进程使用**——两轮整体差约 ×0.6（98 处），与 2026-09-17 早先的跨会话方差发现一致；③battle:0 的 cardsel 样本混入了提交（不可用）；`body_bar.configure` 的"仅换相位时贵"为机制推断；④未覆盖 map／shop／event／reward／prison／practice 相位、触屏路径、英文 locale；⑤首次 B 轮在 `build_scene battle/12` 出现约 700s 引擎停滞（环境级，已重跑，本轮数据作废）。

**两条修复方向（均指向既有契约，非新设计）**：①**候选不要算两遍**——dispatch 复核重算候选，而 UI 手上已有同版本候选（`ActionIndex`），正是 `docs/response-pipeline.md` 里"候选 ID＋版本提交、索引只查找不重算"的本意，约可省一次 30% 量级的开销（2026-09-17 被否：该方向经人裁定"方向错误"、不实施，见本条目下文更正段）；②**`present(dirty)`**——整树重建只在"点牌选中"这类高频低改动点击上成为主项（45ms 中约 43ms），正是该契约的适用范围。

**更正（2026-09-17，协调者）**：上一条里"同一份候选算了两次"的说法**不准确**。核对代码：`ui/main.gd` 的 `_submit` 顺序是 `dispatch(c.id, version)` → 成功后 `get_view()`，两次 `candidates()` 面对的是**两个不同状态**——`dispatch` 内那次是**提交前**（用于复核提交的候选并取出其 payload），`get_view` 内那次是**提交后**（用于渲染新的行动栏）。二者内容不同、各自都有用途，**不是重复计算**。可省的只有第一条的"全表重建"（核心其实只需要那一个候选）：`_submit` 手上本就有候选对象 `c`，却只传了 `c.id`。详见协调者对该问题的答复。

**更正（2026-09-17，协调者）**：本条列出的"两条修复方向"中，**第①条（提交路径去重／候选不再全表重建）经人裁定"方向错误"**，契约已归档 `docs/history/submit-dedup-2026-09-17.md`（**不实施**），理由与四个替代方向写在该文件头。第②条（`present(dirty)` 局部刷新）**未裁决**，仍在待选。

**再归并（2026-09-17，协调者）：按"候选／校验／深拷贝／执行"重切同批原始数据**（只重算 `round-a.json`／`round-b.json` 的占位，未重跑仪器、无插桩）。
成功提交（battle，B 轮，件数 0／12／26，整次同步 98.1／110.7／187.7ms；上文 260.3ms 属 A 轮，跨轮不可比）：

| 段 | 0 件 | 12 件 | 26 件 | 26 件占整次点击 |
| --- | --- | --- | --- | --- |
| `dispatch` 内 候选+取回 | 8.4ms | 19.9ms | 41.6ms | 22.2% |
| `dispatch` 内 `_execute`+清理 | 6.2ms | 10.6ms | 27.5ms | **14.7%（第二大）** |
| `dispatch` 内 五项校验+版本 | 4.0ms | 3.5ms | 3.1ms | **1.7%（最小项）** |
| `dispatch` 内 `state.duplicate(true)` | 0.3ms | 0.4ms | 0.5ms | 0.3% |
| `get_view` 内 候选 | 9.1ms | 16.3ms | 36.2ms | 19.3% |
| `get_view` 内 preview／card_texts | 0.6／0.7ms | 1.6／0.6ms | 3.6／0.7ms | 1.9／0.4% |

- **五项校验不随候选数、只随装备件数走**（battle 3.1–4.0ms 平；departure 3.5→4.0ms），在 battle 26 件时只占整次点击 1.7%；**0 件档反而是它的相对高位**（4.1%）。
- **第二大头是 `_execute`+清理**（26 件 27.5ms，0→26 件放大 4.4×），从未分段，"执行一个动作到底花在哪"目前是空白。
- 0 件档的主导项是 UI：`render` 36%、`feedback` 20%，core 侧只有 41ms／98ms。
- **例外页：departure**（候选恒 6 条、`_execute` 0.2ms）——校验 3.5–5.6ms 成为 `dispatch` 首位（占 `dispatch` 39–42%、占整次点击 15–17%），debug 门控的相对收益主要落在这种"低候选、每次点击都付"的页面。
- 归并口径警告：`body_drawer` 是 `body_bar.configure` 的**外层包装**（`build/stutter-trace-20260917/instrument.py:166-176`，同一段时间被记两次），渲染节占比按 `body_bar.configure` 记 ~22–23%，**不得相加读成 44%**；`page`／`resources` 等节的完整排序见同目录 `analysis.md`。
- 本段只用同一次点击内的比值与同一轮内的件数曲线；绝对微秒仍受"不可跨进程"限制。未覆盖：map／shop／event／reward／prison／practice 相位、触屏路径、英文 locale。

## 2026-09-17 瞬时反馈批次：快感滤镜／蓄力·深呼吸边框／冲击震动（实现者）

域：`core/resource_feedback.gd`、`ui/main.gd`、新模块 `ui/impact_feedback.gd`、`tests/impact_feedback_ui_cases.gd`、`tests/pressure_cases.gd`、`tests/ui_smoke.gd`；契约 `docs/spec/response-pipeline.md`（提交面），无新增玩家文案。

RuleChangePackage（加性、零规则改动：不动候选、数值、存档、随机；不新增规则接口）：`core/resource_feedback.gd` 的 `FIELDS` 增第 6 个字段 `pressure`，`dispatch` 既有返回键 `resource_feedback` 因此携带提交内快感增量，UI 只读该返回值、不解析 `state.logs`。`ui/main.gd` 的 `_submit` 成功分支新增 `_impact_feedback(events,payload,updated)`；交给既有 `ui/resource_feedback.gd` 的事件经既有 `instant_fields` 参数抑制 `pressure`，避免与滤镜重复表现。三种效果共用同一个全屏层与同一张 `FEEDBACK_*` 参数表（`ui/impact_feedback.gd` 顶部）：**滤镜**在 `delta=Σ(after-before)>0` 时出一次（同提交多处上涨合并成一次），峰值 `clamp(0.06+0.24*ratio_now,0.06,0.30)` 再取 `max(峰值,0.5*ratio_rise)` 下限，淡出 `clamp(0.12+0.6*ratio_rise,0.12,0.40)` 秒、`alpha(t)=peak*(1-(t/fade)^2)`，形状按 `1-(d/dmax)^2` 加重的矩形 vignette，颜色复用 `main.gd` 的 `OVERLOAD_COLOR`；**边框**在 `charge` 增量>0／载荷为 `status_toggle` 的 charge 切换（不改数值，只能靠载荷判定）／载荷 `kind=="calm"` 时触发，用时长与强度区分来源（蓄力 0.22s／α0.50，深呼吸 0.60s／α0.30，颜色语义作废；边框取自己 0.18 倍半短边为 dmax，权重函数与滤镜相同）；**震动**在载荷 `kind=="attack"`（含火球术·自解 `attack_release`）单脉冲、`kind=="card"` 且 `mode` 为 strain 双脉冲／slip 与 magic_slip 单脉冲略长，幅度由 `preview.damage`／扁平 `damage` 归一化为 `clamp(1.2+0.45*damage,1.2,6.0)` 像素，只位移 `ImpactShakeHost`、结束复位、布局不动。淡出期间再来一次上涨只刷新强度、不重启计时（截止时刻与首次淡出长度都不变，避免连闪）。硬约束：层与全部子节点 `mouse_filter=IGNORE`；无 `_process`（一次性 Tween，`Fade.finish()` 后 `hide()`＋`set_process(false)`）；层 `z_index=218`，在全部抽屉／面板／浮字之下。

与假设不符的三处（已按实际代码实现）：①普攻载荷是**扁平 `damage`**，只有伤害卡才有 `preview.damage`；②`status_toggle` 载荷写的是 `status:"charge"`（`charge_all` 在 `enabled` 与 copy args 里），不是 `status:"charge_all"`；③`card` 载荷没有 `damage_type` 字段，判定用 `mode`（`strain`／`slip`／`magic_slip`；`magic_hand` 为 mode=magic_slip、damage_type=slip）。

验证（分支 `feedback-effects` 工作区实测，未提交推送；引擎 **4.7.2.stable.official.ed1daf0bf**，`GODOT_BIN` 指向 `*_console.exe`）：
- **冻结 oracle 逐字不变**：`transition_oracle.gd -- --baseline=build/transition-oracle-20260916/baseline.json` → `TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`；`event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json` → `EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`、`EVENT RESULT: PASS (94 scenarios, 0 failures)`。脚本与基线 sha256 与本卷登记值一致（transition 脚本 `59d41c68…`、基线 `ba979d18…`；event 脚本 `cf48529a…`、基线 `bdf08765…`，均未改）。
- **规则门**：`tools/check.ps1 -Suite runner,architecture,core,persistence,pressure,rewards,event_flow,casting -TimeoutSeconds 1800`（`build/checks/20260917T232152668-42784`）→ 退出码 0、8 套件全 PASS、`PASS: 5962 assertions`、139.91s。新增具名规则 check 在 `tests/pressure_cases.gd`：receipt 合并与"望远镜"不变式（两处 turn_end 上涨 ≥2 事件、Σ增量＝状态净变化）、净上涨才触发、下降只出边框不出滤镜、纯魔力支付不出滤镜；单独复跑 `-Suite pressure` 退出码 0、1081 断言（`build/checks/20260917T234326243-25172`）。
- **窗口门**：`tools/check.ps1 -UIOnly -UISuite impact_feedback,display,home,interface,route,pressure,rewards,persistence -KeepGoing`（`build/checks/20260917T232448848-48048`）→ 退出码 1、`UI FAIL: 1315 assertions`；`display／home／route／impact_feedback／persistence` PASS，红 = `interface`（既有登记：28 张 `witch_*` 卡缺立绘）＋`pressure`（2 条 CALM UI）＋`rewards`（1 条 REWARD UI）。新增模块 `impact_feedback` PASS **75 断言**（`build/checks/20260917T234336041-26092`，29.15s）：触发正／反例、合并、参数边界、颜色复用、层契约（`modulate.a` 峰值、淡出时钟、两种效果同帧共存且互不取消）、真实指针点击路径（普攻单击／拖拽挣扎卡／深呼吸／charge 切换）、穿透（特效运行中 press 仍落到按钮并提交）、空闲态（结束后 hide、`is_processing()==false`、无存活 Tween）。
- **新增红项定类（既有、非本片）**：把全部改动 `git stash -u` 后在**同一 HEAD 干净树**重跑 `-UIOnly -UISuite pressure,rewards`（`build/checks/20260917T233438622-22364`）→ **同样三条失败、断言数相同（pressure 79／rewards 313＝392）**，故 `pressure` 的 `CALM UI shows attenuated relief with unchanged deferred energy`／`CALM UI action description exposes the deferred reward` 与 `rewards` 的 `REWARD UI final unlock segment does not promise a third lock` 为既有红（此前门禁一直用独立套件，从未单独跑过这两套件）。**门禁红集口径自此扩为 ⊆ {`card_power` 5, `installed_tools` 1, `tower_progression` 10＋1, `hand_assist` 1, `home_persistence` 3, `interface` 1(28 张卡), `pressure` 2, `rewards` 1}**。
- **敏感性证明（三条，全部还原、产品文件与备份逐字节一致）**：①层 `mouse_filter` 改 `STOP` → 3 条 `IMPACT INPUT` 红（`build/checks/20260917T233901768-32216`，含"特效期间真实点击仍生效"）；②`filter.refresh`／`border.refresh` 改成总是 `start(...)`（朴素重启）→ 2 条"保持淡出时钟"红（`build/checks/20260917T234221325-44508`）；③`FIELDS` 去掉 `pressure` → `-Suite pressure` 2/1081 红（`build/checks/20260917T234301865-29524`）。**检查改进记录**：初版"淡出中不重启"只比较同一帧内的 `ends`，对同帧重启不敏感，已改成"淡出长度与截止时刻同时不变"（新涨幅淡出长度不同时才有区分度）。
- **未验证**：`-Suite all`／`-UISuite all` 全量回归、Android 真机、打包与发布；`UI SCREENSHOTS: none`（未做像素级截图比对，三种效果只断言参数、锚点与节点状态）。

**更正与返工（2026-09-17，实现者；独立审查 5 项，全部处置）**：

① **不实记录更正**：上文「`magic_hand` 为 mode=magic_slip／damage_type=slip」是错的。事实：`magic_hand`／`witch_magic_hand` 的 `mode` 为 `"lower"` 且**没有** `damage_type`（`data/card_rules.gd` 的 `MAGIC_HAND`；`core/witch_character.gd` 的 witch override 只改 mana／hits／free_effects），`mode=magic_slip`／`damage_type=slip` 的是 `magic_slip` 卡（`data/card_rules.gd`）。错误来源正是 `tests/impact_feedback_ui_cases.gd` 里那条合成载荷 `{"type":"magic_hand","mode":"magic_slip"}`——真实数据不存在这种组合。**已改**：三种卡载荷的 `mode` 一律由 `card_rules.gd` 的 `Rules.face_mode(type,false)` 现取，并新增一条规格锚点断言（`face_mode("strain"/"slip"/"magic_slip")` 与 `damage_type("magic_hand")==""`），另加一条**真实候选**形状断言（`tests/game_fixture.gd` 装腕部夹具后取真实 `card` 候选，断言 `mode` 存在且 `damage_of` 等于其 `preview.damage`）；`magic_slip` 用例改用真实卡 `{"type":"magic_slip","mode":face_mode("magic_slip")}`。第 3 条口径偏差由此改写为：**`card` 载荷无 `damage_type`，判定只用 `mode`；`strain`／`slip`／`magic_slip` 三个 mode 都对应真实卡（`magic_slip` 卡的 damage_type 是 `slip`），`magic_hand` 是无伤害的 `lower` 卡**。

② **规范同步**：`docs/spec/response-pipeline.md` 四处登记新模块——域的文件域列表、M6 行（边界／小接口／内部）、接口表新增 `impact_feedback.play(events, payload, snapshot) -> void` 一行（输入域、调用点、信任依据：不读 `state`／`state.logs`、无效果时为空操作、全 IGNORE 鼠标、无 `_process`、Tween 结束即 `hide()`＋`set_process(false)`）、输入域新增 `play` 条目（receipt 字段口径指向 `core/resource_feedback.gd` 的 `FIELDS`、载荷读法与"输入不是资格判定来源"）。原「本管线不新增 UI 文件」的绝对措辞改为「默认不新增（先提案）」＋本片经任务授权的唯一例外 `ui/impact_feedback.gd`（纯显示、只读消费）＋同类新增仍须提案。

③ **z_index 措辞更正（记录与代码注释同改，数值未改）**：218 并非"在全部抽屉／面板／浮字之下"——`ui/keyboard_input.gd` 的 `KeyboardTargets`(216) 在它**下面**。准确说法：唯一被它覆盖的是 `KeyboardTargets`（只读提示层，位于屏心、vignette 权重近 0，且点击仍穿透）；它在落点／拖放提示(220)、卡牌动画(225)、抽屉与遮罩(228／230)、战斗反馈(240–250)、术语窗(260)、资源浮字(270)、商店遮罩(280)、菜单(300+) **之下**。保留 218 的理由：滤镜必须压在棋盘与世界层之上才有"全屏"语义，而"低于一切可读面板"仍是硬要求——216 是唯一例外且无害。

④ **参数集中**：逐脉冲衰减 `0.35` 已并入顶部参数表 `FEEDBACK_SHAKE_PULSE_DECAY`（效果参数不再有表外魔法数）。

⑤ **新增 UI 层合并用例（含敏感性证明）**：`tests/impact_feedback_ui_cases.gd` 新增 `merged_receipt`，把**多事件 receipt**（两条快感上涨 + 一条魔力）直接喂进 `play()`，钉住：只装填一次包络（`Fade.starts==1`，新增该计数=包络被装填次数）、峰值与淡出长度取**求和**后的上涨、淡出截止时刻为本次提交起算的整段淡出。敏感性：把 `play()` 改成逐事件调用 `_play_filter` → 该 3 条同时红（`build/checks/20260918T000807288-22124`）。

**如实标注（审查要求，不改代码）**：①两个冻结 oracle 的 digest **不覆盖** `resource_feedback` 这条路径（摘要的是 candidates／view／options／snapshot／rng，不含 `dispatch` 返回的 receipt），故本片的**规则侧实际覆盖**就是上文 `tests/pressure_cases.gd` 的 3 条（含"Σ增量＝净变化"与"一次提交 ≥2 个上涨事件"），oracle 只证明事件／迁移结构未被本片改动。②`not is_processing()` 的断言在当前实现下**不可能变红**（脚本未定义 `_process`、无 `set_process(true)`），属结构性守卫，只作"不会退化成常驻逐帧"的静态标注，**不计作行为判据**。

**返工后实测（工作区，分支 `feedback-effects` 第二次提交前；`-KeepGoing`、`-TimeoutSeconds 1800`）**：规则门 `-Suite runner,architecture,core,persistence,pressure,rewards,event_flow,casting` → 退出码 0、8/8 PASS、`PASS: 5962 assertions`（`build/checks/20260918T000926231-16336`）；窗口门 `-UIOnly -UISuite impact_feedback,display,home,interface,route,pressure,rewards,persistence` → 退出码 1、8 套件全部跑完、`UI FAIL: 1320 assertions`，逐套件 display 141／home 113／route 134／interface 355／pressure 79／impact_feedback **81**（原 75 ＋ 规格锚点 1 ＋ 真实载荷 2 ＋ 合并 3）／rewards 313／persistence 104（`build/checks/20260918T001450395-11052`）；两个 oracle digest 逐字不变、脚本与基线 sha256 未动。未验证项不变（全量回归、Android 真机、打包发布、像素级截图比对）。

**第三次返工（2026-09-18，实现者；两项人工试玩缺陷＋触发／配色映射定稿）**：

域：`ui/impact_feedback.gd`、`ui/main.gd`（`_submit` 反馈节）、`ui/visual_theme.gd`（三个边框色 token）、`core/resource_feedback.gd` 的 `FIELDS`、`tests/impact_feedback_ui_cases.gd`、`tests/pressure_cases.gd`；契约 `docs/spec/response-pipeline.md`（`play` 接口行与输入域）。本条**取代**本案例上文两处已被推翻的措辞：①「只位移 `ImpactShakeHost`、布局不动」——正是这句排布导致震动只平移了近乎透明的边缘叠加层、游戏画面从未移动（缺陷 A 的直接原因）；②「颜色语义作废／两种边框只用时长与强度区分」——改为按触发族一族一色（白／黄／蓝，映射见下）。`docs/record/changelog.md` 的 2026-09-17 瞬时反馈批次条目中「不用颜色」「只位移反馈层、布局不动」两句同样以本条为准。

**缺陷 A（震动不可见，结构性）**：`filter_bands`／`border_bands` 原先是 `ImpactShakeHost` 的子节点，震动只把边缘带平移 1.2–6px。现改为位移承载全部已提交控件的 `main.gd` GameLayout（`shake_target=host.layout`；层自身与两条叠加带不动）：`_play_shake` 在效果开始前记录 `shake_origin`，淡出中来的第二次震动沿用同一原点，脉冲结束 `_shake_finished` 按该原点**精确复位**，`_exit_tree` 中途拆卸同样复位。「不得改变布局」的验收口径改为「效果结束后整帧与效果前逐像素相同」：`real_attack` 与两条像素探针都同时断言运行期间确实位移、结束后 `ui.layout.position` 与记录原点逐位相等。幅度 `1.2/0.45/1.2/6.0` → `FEEDBACK_SHAKE_BASE_PX=4.0`／`PER_DAMAGE=0.25`／`MIN=4.0`／`MAX=9.0`（真实伤害 6–8 的挣扎卡／普攻：3.9–4.8px → 5.5–6.0px）。

**缺陷 B（低快感滤镜不可见）**：实测 pressure 6/130、rise 6 时峰值 0.0744，存档帧边缘无可辨变化。参数改为 `FEEDBACK_FILTER_ALPHA_BASE=0.14`／`PER_RATIO=0.25`／`MIN=0.14`／`MAX=0.38`，滤镜与边框共用 `FEEDBACK_EDGE_EXTENT=0.30`（dmax=0.30×半短边；滤镜原 1.0、边框原 0.18），最低强度峰值 0.1438。（工作区里曾残留一次把四个 alpha 常量改回 0.06 的未提交试验，与已提交断言矛盾，本轮已按已提交值恢复。）

**映射定稿（C）**：触发全部来自已提交 receipt 的顶层状态字段净增量＋载荷：`pressure` 净涨→粉滤镜；`charge`／`next_energy` 净涨→黄边框；`mana`／`temporary_mana`／`witch_focus` 净涨→蓝边框；载荷 `kind=="calm"`→白边框；攻击／挣扎／滑脱→震动。`core/resource_feedback.gd` 的 `FIELDS` 加 `witch_focus`（加性、同一通道；该键只在女巫角色 state 上存在，`capture` 用 `state.has` 跳过缺失键，其他角色不受影响）；`ui/main.gd` 的 `instant_fields` 同时抑制它与 `pressure` 的浮字（含 flask 分支）。每族一行声明表 `FEEDBACK_BORDERS`（色 token＋峰值＋淡出），触发字段声明表 `FEEDBACK_BORDER_FIELDS` 的键序即优先级；`border_kind_of` 先判 calm 载荷、再按表返回首个净涨族，故**一次提交只出一条边框**：白＞黄＞蓝。色 token 落 `ui/visual_theme.gd`：`BORDER_CALM`(f2ede0)／`BORDER_CHARGE`(e8c47b)／`BORDER_MANA`(8fd3ee)，效果层无内联 hex。淡出中来的新触发换族色与标签、保留原包络时钟（不重启）。

**三条像素判据实测**（真实窗口 `root.get_texture().get_image()`；判据：震动内容区 max≥24/255 且差异像素占比≥2%，滤镜／边框边带内 mean≥3/255 且 max≥12/255；`build/checks/20260918T011931131-4724`）：
- 震动：峰值帧 vs 提交前帧的**内容区**（去掉 0.30×半短边边带）max=**243**、share=**0.6645**、mean=14.492，观测峰值位移 5.9px；效果结束后整帧 max=0、share=0（逐像素相同），直接脉冲探针观测位移 5.4px。
- 滤镜：最低强度（pressure 2/130、rise 2，峰值 0.1438）边带内 mean=**14.240**、max=**47**、share=0.9751。
- 边框每色一档：白（calm 载荷＋真实深呼吸的 `next_energy` 净涨，像素路径证明优先级）mean=**40.290**、max=**95**；黄（`charge` 净涨 +1）mean=**49.149**、max=**140**；蓝·魔法预备（`temporary_mana` +4）mean=**43.429**、max=**117**；蓝·精神集中（`witch_focus` +2）mean=**43.429**、max=**117**。

**门禁（同一冻结树；两轮 `summary.json` 的 before／after 都是 `A6CB801C3FB9D9B7CF68B63E4E2AC2560376F6D21EAC9074695BBB7BF7BC2926`，即运行期间 `spire-godot` 源码未变）**：
- 规则门 `-Suite runner,architecture,core,persistence,pressure,rewards,event_flow,casting -TimeoutSeconds 1800` → 退出码 0、8/8 PASS、`PASS: 5965 assertions`、98.5s（`build/checks/20260918T012810867-34568`）；新增 3 条 `tests/pressure_cases.gd` check（女巫 魔法预备 提交的 receipt 携带 `witch_focus`＋`temporary_mana` 增量、该 receipt 判为蓝族、精神集中被消耗的释放不触发任何边框）。
- 窗口门 `-UIOnly -UISuite impact_feedback,display,home,interface,route,pressure,rewards,persistence -KeepGoing -TimeoutSeconds 1800` → 退出码 1、8 套件全部跑完、`UI FAIL: 1349 assertions`；逐套件 display 141／home 113／route 134／interface 355／pressure 79／impact_feedback **110**（原 95：＋触发／优先级／色 token 8、＋蓝族重染 1、＋边框像素探针 6——原单条 calm 探针 2 条断言改为白／黄／蓝预备／蓝集中四条共 8 条）／rewards 313／persistence 104（`build/checks/20260918T011931131-4724`，465.6s，`-TimeoutSeconds 1800` 下 rewards 未被杀）。红项与登记集合完全一致、无新增红：`interface` 的 `CARD ART`（28 张 `witch_*` 缺立绘 1 条）＋`pressure` 2 条 `CALM UI` ＋`rewards` 1 条 `REWARD UI`（`UI ENGINE ERRORS: 4`＝这 4 条）。
- 冻结 oracle：两个 `summary.json` 的 before／after 逐字节相同（上表 digest）；内容 oracle 逐字不变——`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（31 场景 0 失败）、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（94 场景 0 失败）；脚本与基线 sha256 与上文登记值一致（transition 脚本 `59d41c68…`、基线 `ba979d18…`；event 脚本 `cf48529a…`、基线 `bdf08765…`）。

**可触发场景（人工口径，写入记录）**：挣扎与滑脱只在压力练习房可触发（菜单 `Practice_pressure`，UI 用例走 `t.start_practice("Practice_pressure")`）；密集装备的战斗夹具里打击被拘束手臂拦住、深呼吸被口部拘束具拦住，两者都到不了提交，所以真实点击用例必须落在练习房，战斗夹具只能覆盖普攻与法力支付。

**未验证**：全量回归（`-Suite all`／`-UISuite all`）、Android 真机、打包与发布；蓝边框的 `witch_focus` 只在规则侧 receipt＋直接 `play()` 的真实帧像素探针上验证过，未经女巫存档的真实点击提交；真实拖拽只覆盖挣扎卡（滑脱／magic_slip 的幅度与步长由 `shake_spec` 单元用例＋同一像素通道覆盖）；两次提交重叠窗口内的族色切换观感未人工确认。

**第四次返工·审查五项收口（2026-09-18，实现者）**：

域：`ui/visual_theme.gd`（新增令牌）、`ui/main.gd`（`OVERLOAD_COLOR` 改读令牌）、`ui/impact_feedback.gd`（两处回退色改读令牌）、`tests/impact_feedback_ui_cases.gd`（两条新证据＋像素判据改写）；契约 `docs/spec/response-pipeline.md` 不变，无规则／候选／存档／随机改动，无玩家文案。

- ① **门禁溯源更正**：第三次返工登记的 **`A6CB801C…`** 两轮（`build/checks/20260918T011931131-4724`、`20260918T012810867-34568`）是**提交前工作区**的指纹（交付提交 `5ef9173` 的树指纹为 `30D93BEC…`），不构成交付版本证据。本次已在交付提交 **`07795c6`** 复跑（其后仅有 docs 提交，不改源码指纹）：**原登记为提交前工作区，已在 `07795c6` 复跑，指纹 `C8D361BC9F49C8F70018C5C18EB0E3E873A7A0B111AE1459141383C45FDE056C`**。
- ② **令牌收口**：`ui/impact_feedback.gd` 的 `Color("ed82b9")` 两处（`FEEDBACK_FALLBACK_COLOR` 常量与 `Bands.color` 初值）删除，改读 `ui/visual_theme.gd` 新增令牌 `OVERLOAD` 与 `FEEDBACK_FALLBACK`；`ui/main.gd` 的 `OVERLOAD_COLOR` 同步改读 `Palette.OVERLOAD`，全仓 `ed82b9` 只剩令牌定义一处。「效果层无内联 hex」自本轮起为事实。
- ③ **变更日志指针**：`docs/record/changelog.md` 追加 2026-09-18 行，点名 2026-09-17 条目中「用时长与强度区分来源，不用颜色」与「只位移反馈层、布局不动」两句已被取代，并写明新行为（边框按触发族一族一色；震动位移承载全部已提交控件的 `GameLayout` 且效果后逐像素复位）。
- ④ **新增两条测试证据**（`tests/impact_feedback_ui_cases.gd`）：`layer_contract` 在脉冲中途再触发一次震动，断言沿用首次记录原点并从该原点重新起摆，再逐帧采样断言合并后的位移峰值落在该次幅度 ±0.5px 内（不叠加）；新函数 `teardown` 在脉冲中途 `queue_free()`，断言 `ui.layout.position` 与效果前逐位相等。敏感性（`build/checks/20260918T021254362-30836`，4.7.2）：把 `_play_shake` 续振分支改成重锚原点且不做复位、并移除 `_exit_tree` 复位后，恰好这 3 条红（合并峰值 6.54px＞幅度 6.00px），其余 112 条不动。
- ⑤ **像素判据改写（隔离位移）**：`shake_pixels` 不再对照提交前帧（那会混入本次提交自身的 energy／HP／候选行变化），改为**位移峰值帧 vs 复位后帧**——两帧同处已提交状态，提交自身的变化在两侧相同而相消；`restore_pixels`（settled 状态直接 `play()`，复位帧先断言与效果前帧逐像素相同 max=0／share=0）给出完全隔离的位移判据（内容区 max≥24 且 share≥2%）。**真实含义（登记）**：位移证据＝`peak_offset`＋复位帧与效果前帧逐像素相同；share 只是辅助量级，不单独作为位移证明。

**本轮门禁（同一冻结树；引擎 4.7.2.stable.official.ed1daf0bf，`GODOT_BIN` 指向 `*_console.exe`）**：
- 规则门 `-Suite runner,architecture,core,persistence,pressure,rewards,event_flow,casting -TimeoutSeconds 1800` → 退出码 0、8/8 PASS、`PASS: 5965 assertions`、86.6s（`build/checks/20260918T020049240-17784`）。
- 窗口门 `-UIOnly -UISuite impact_feedback,display,home,interface,route,pressure,rewards,persistence -KeepGoing -TimeoutSeconds 1800` → 退出码 1、8 套件全部跑完、`UI FAIL: 1354 assertions`（第三次返工 1349＋新增 5）：display 141／home 113／route 134／interface 355／pressure 79／impact_feedback **115**／rewards 313／persistence 104（`build/checks/20260918T020228172-37196`）。红项仍为登记集合、无新增红：`interface` 的 `CARD ART`（28 张 `witch_*` 缺立绘 1 条）＋`pressure` 2 条 `CALM UI` ＋`rewards` 1 条 `REWARD UI`（`UI ENGINE ERRORS: 4`＝这 4 条）。
- 本轮像素（4.7.2 实测）：滤镜 floor mean=14.301／max=47；边框白 mean=40.245／max=95、黄 mean=49.087／max=139、蓝·预备 mean=43.403／max=116、蓝·集中 mean=43.396／max=116；震动 `peak_offset=5.8px`、位移帧 vs 复位帧内容区 mean=12.580／max=242／share=0.6160（辅助量级）、复位帧 vs 效果前帧整帧 max=0／share=0、直接脉冲隔离探针 max=243／share=0.6128（复位帧已证同于效果前帧）。
- 冻结 oracle 复跑（脚本与基线 sha256 未动，与上文登记一致：transition 脚本 `59d41c68…`／基线 `ba979d18…`、event 脚本 `cf48529a…`／基线 `bdf08765…`）：`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（31 场景 0 失败）、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（94 场景 0 失败），逐字节与登记一致；两个 `summary.json` 的 before／after 同为 `C8D361BC…`（运行期间源码未变）。
- 环境注记：本次会话默认 `GODOT_BIN` 指向 `Godot_v4.7-stable_win64.exe`（`4.7.stable.official.5b4e0cb0f`，非登记引擎）；上述门禁、像素与 oracle 结果均在显式改用 `v4.7.2-stable` 的 `*_console.exe` 后取得，4.7-stable 下的中间结果（`20260918T015807820-17784` 等）不使用。

**未验证（本轮追加）**：新增的续振／拆卸证据是层内直接 `play()`＋`queue_free()` 路径，未覆盖重启或退场菜单触发 `_demo_exit_screen` 的拆卸；上述其余未验证项与前文相同。

**第五次返工·蓝族按 delta 触发、加减两变与强度（2026-09-18，实现者）**：

域：`ui/impact_feedback.gd`、`tests/impact_feedback_ui_cases.gd`、`tests/pressure_cases.gd`；契约 `docs/spec/response-pipeline.md`（`play` 接口行、输入域、dispatch 成功键）。`ui/main.gd` 与 `core/` **无净改动**：本轮开工时工作区里有一版把施法失败经 `core/game.gd` 的 `dispatch` 新键 `magic_failed` 透传给 UI 的未提交改动；按本轮明确口径（直接 trace delta、不得新增 `magic_failed` 键、不动 core）整段回退，两文件回到 `1378cd0` 原文，施法失败改由 receipt 净值自动落入蓝族 loss。无规则／候选／存档／随机改动，无玩家文案。

**判定与参数**（`FEEDBACK_*` 表仍是唯一参数源）：
- 触发：`charge`／`next_energy` 仍只认净涨（黄）、`pressure` 仍只认净涨（粉滤镜）；`mana`／`temporary_mana`／`witch_focus` 改为任一净变化（Δ≠0）出蓝，施法失败（付款后只返还一半的净下降）因此无需标志即出蓝；`flask_mana` 不进蓝族。优先级仍白＞黄＞蓝、一次提交仍只出一条边框。
- 变体：gain（Δ>0）＝`attack 0.10s` 上冲后 `fade 0.30s` 淡出、边带 `extent 0.34`（更宽）；loss（Δ<0）＝即刻峰值（`attack 0`）后 `fade 0.55s` 慢退、`extent 0.26`（更窄）；同一 `BORDER_MANA` token，只有包络／边带／峰值系数区分。边带经新增 `Bands.set_extent` 随变体重画，`Fade` 新增 `attack` 上升段（`ends=现在+(attack+fade)`）。
- 强度（替代阈值，无最小增量门槛）：`ratio=Σ(字段净Δ/该字段参考尺度)`（mana 用提交后 View 的 `mana_max`，临时魔力用 20 点保留上限、精神集中用 4 层上限），`peak=变体系数×min(|ratio|,1)`，loss 0.46／gain 0.34。例：−10/100 支付 peak=0.0460、+10 临时魔力 peak=0.17、−20/100 失败 peak=0.0920、`|ratio|=0.0005` 时 peak<0.001（近乎不可见）。

**新增证据（`tests/impact_feedback_ui_cases.gd`，146 断言，原 115；`tests/pressure_cases.gd` 净增 1 条）**：
- 真实失败施法（变身 40 魔力、强制低成功率、卡留手）→`border_kind=mana`、`variant=loss`、`border_ratio` 等于实际状态差的归一化值、`peak=0.46×ratio`、`border.starts==1`（只装填一次包络），边带像素 mean=**9.273**／max=**29**（判据 ≥3／≥12）。
- 真实成功支付（预备咏唱 10 魔力）→蓝 loss、peak=**0.0460**，并断言小于同池失败值 0.0920（成功支付更淡）。
- 真实魔力 gain（魔力涌流自由面 +10 临时魔力）→`variant=gain`、peak=**0.17**、`attack>0`、extent 0.34＞loss 0.26、token 不变。
- 两变体同比例断言 `mana_peak("loss",0.25)=0.115 > mana_peak("gain",0.25)=0.085`；无变化提交（真实 posture 变更）→`will_play=false` 且层根本未被创建。
- 定格像素探针：gain +10 预备 mean=**20.177**／max=**53**（focus +2 同值），loss −10/100 mean=**4.572**／max=**15**（即成功支付在自身强度上的判据）。

**敏感性（必须红）**：把 `border_kind_of` 的蓝族分支改成 rise-only（`elif delta>0.0`）→`-UIOnly -UISuite impact_feedback` 恰好 8 条红，含 `IMPACT BORDER a real failed cast lights the blue loss border from the receipt alone`、`IMPACT BORDER the successful mana-paying action draws the blue loss border instead of staying dark` 与 `BORDER mana loss` 两条像素断言（mean=0／max=0）；146→140 断言（层未创建使后续检查早退）；`build/checks/20260918T033102300-33700`。随后还原，并以 `-Suite runner`（`20260918T033202821-38336`，435 断言 PASS）复核树指纹未变。

**门禁（同一冻结树；`GODOT_BIN` 指向 `v4.7.2-stable` 的 `*_console.exe`，4.7.2.stable.official.ed1daf0bf）**：
- 规则门 `-Suite runner,architecture,core,persistence,pressure,rewards,event_flow,casting -TimeoutSeconds 1800` → 退出码 0、8/8 PASS、`PASS: 5966 assertions`、82.22s（`build/checks/20260918T024932533-9072`）。
- 窗口门 `-UIOnly -UISuite impact_feedback,display,home,interface,route,pressure,rewards,persistence -KeepGoing -TimeoutSeconds 1800` → 退出码 1、8 套件全部跑完、`UI FAIL: 1385 assertions`；逐套件 display 141／home 113／route 134／interface 355／pressure 79／impact_feedback **146**／rewards 313／persistence 104（`build/checks/20260918T025101998-27088`）。红项与登记集合完全一致、无新增红：`interface` 的 `CARD ART`（28 张 `witch_*` 缺立绘 1 条）＋`pressure` 2 条 `CALM UI` ＋`rewards` 1 条 `REWARD UI`（`UI ENGINE ERRORS: 4`）。环境注记：home 套件期间 Godot 窗口处于最小化、渲染降频使该套件耗时 1683.8s（其余 10–290s），窗口恢复后立刻回到常规速度；整套仍完整跑完、指纹未漂移，结果有效。
- 冻结 oracle 复跑：`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（31 场景 0 失败）、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（94 场景 0 失败），与登记逐字节一致；脚本／基线 sha256 未动（transition `59d41c68…`／`ba979d18…`、event `cf48529a…`／`bdf08765…`）。
- **交付树指纹**：规则门与窗口门的 before／after 同为 **`2D2AAD80AA0AF5A3C30D64905D3E88031588F8E706A02B42C9FB0469D758F5A0`**（运行期间 `spire-godot` 源码未变，交付提交沿用该树）。

**未验证（本轮追加）**：全量回归、Android 真机、打包与发布与前文相同；蓝族 loss 的真实像素证据取「变身失败」一条（失败卡留手、帧对干净），成功支付与 gain 的像素判据来自同比例的定格直接 `play()` 探针（成功施法会消耗卡牌、离手动画与效果窗口重叠，未做真实提交的像素对）；多字段混合符号的观感未人工确认（数值上按归一化求和并入单一边框）。

**独立复核（2026-09-18，独立会话子代理，轻量迭代口径）**：

域：`ui/impact_feedback.gd` 与 `tests/impact_feedback_ui_cases.gd`（提交 `51bfcfb`，交付树指纹 `2D2AAD80…`）；本会话不改产品代码，只读核对差异，敏感性改动用完即还原。

- 差异核对（只读）：`border_kind_of` 的非 rise-only 分支为 `elif delta!=0.0`；`FEEDBACK_BORDER_RISE_ONLY={"charge":true}`；蓝族字段表为 `mana`／`temporary_mana`／`witch_focus`（`flask_mana` 不在）；`border_spec` 的 gain／loss 行与 `mana_peak` 的 `min(|ratio|,1)` 均取自 `FEEDBACK_*` 表；`core/` 与 `ui/main.gd` 相对 `1378cd0` 无净改动。
- 独立窗口门：`tools/check.ps1 -UIOnly -UISuite impact_feedback -TimeoutSeconds 1800`（`GODOT_BIN` 指向 `v4.7.2-stable` 的 `*_console.exe`，4.7.2.stable.official.ed1daf0bf）→ 退出码 **0**、`SUITE RESULT: impact_feedback PASS`、**146 断言**、46.9s（`build/checks/20260918T033423088-27392`；before／after 同为 `2D2AAD80…`）。像素实测：失败施法 loss 边带 mean=9.244／max=38，蓝 gain 探针 mean=20.132／max=54，蓝 loss 探针 mean=4.514／max=16，滤镜 floor mean=14.302／max=47，震动 peak_offset=6.0px、隔离位移 max=243／share=0.6145、复位帧整帧 max=0／share=0。
- 敏感性（独立复现，与实现者报告一致）：把蓝族分支改成 rise-only（`elif delta>0.0`）→ 同一套件 **8 条红**、`SUITE RESULT: impact_feedback FAIL`、退出码 1、146→140 断言；红项含 `IMPACT BORDER a real failed cast lights the blue loss border from the receipt alone`、`IMPACT BORDER the successful mana-paying action draws the blue loss border instead of staying dark`、`BORDER mana loss` 两条像素（mean=0／max=0）；`build/checks/20260918T033536000-37300`，修改树指纹 `5FD8B57A…`（与实现者敏感性运行逐字相同）。随后 `git checkout` 还原：`git status` 干净、`border_kind_of` 回到 `elif delta!=0.0`、交付树指纹不变。
- **本轮未跑：规则门／oracle／性能测量**（按人指示"不必每次都测效率"，留到定稿轮）；像素判据未另跑独立脚本或截图，只随 `impact_feedback` 套件执行。实现者会话同轮另行跑过规则门与冻结 oracle（数字见上一段），不在本复核范围内。


## 2026-09-18｜PR #4／#5 本地整合验证

**来源与范围**：主分支基线 `80abcd71c99225e51916d163f5e9ae6c5372d402`；PR #4 `08b2caf57b312797a965cb020ed193145f8e87c3`；PR #5 `63993badc0a6c1425a5a0ca38432188c2fffc0a3`。#5 包含 #4；按用户「以 PR 为优先」完整接纳其目录、根指引、项目 skills、打包路径及反馈实现，保留独立审查发现的必要补修。没有并入 #2 后续提交或 #3 macOS 打包。

**补修域**：`ui/impact_feedback.gd` 的 `Fade.refresh` 保持同一 Tween 的时间线，仅调整当前强度，连续 gain 不再重播上升段或延长结束时间；`ui/main.gd` 的 `_clear_impact_feedback` 收口返回主页、结束画面与重启时的清理，立即恢复布局原点。`tests/impact_feedback_ui_cases.gd` 增加 9 条断言（146 → 155）。文档区分已实现的 `_submit`／`render` 与规划中的 commit／present／dirty section，明确 UI 复用要求可证明的失效条件，README 更新为现行 0.17.1 与新入口。独立子代理完成文档、调用边界与补修测试审查，没有剩余阻塞意见。

**规则检查**（日志均在整合工作树 `spire-godot/build/checks/`）：

- `20260918T045136391-25052`：`-Import -Suite architecture,pressure -UI -UISuite impact_feedback -KeepGoing`，architecture 471＋pressure 1085＝1556 条规则通过；上游反馈 146 条通过，退出码 0。此轮早于反馈清理／时间线补修，指纹 `69641D4BA790366B715EFB94D6C7B4E2BCBA28D37FF800AF021ACC52A93135A1` 前后一致；后续仅 UI 补修，没有改这些规则实现或规则测试。
- `20260918T045940041-2024`：`-Suite core,persistence,witch_character -KeepGoing`，core 888＋persistence 955＋witch_character 455＝2298 条通过，退出码 0。合计 3854 条规则断言通过，属于两轮分类检查，未宣称全量回归。
- 全新 worktree 第一次导入 `20260918T045058786-49172` 因尚未生成的字体缓存 `.fontdata` 报错；保留失败日志，第二次导入成功，没有以引擎退出码 0 掩盖首次错误。

**界面检查与原版对照**：

- 整合工作树 `20260918T045553428-42872`：`-UIOnly -UISuite impact_feedback,home,home_persistence,enemy_feedback,pressure,rewards,interface -KeepGoing`，全部 7 类运行完成，共 1107 条断言；impact_feedback 155、home 113、home_persistence 51 全部通过，其余四类共 8 条失败，退出码 1。
- 未改动的主分支基线 `20260918T050041299-48564`：独立运行 `enemy_feedback,interface,pressure,rewards`，788 条断言，退出码 1。逐条比较日志，8 条失败的文本与顺序完全相同，没有新增失败。
- 既有失败为 enemy_feedback 4 条（旧 `InstalledTool_item_1` 入口与剩余使用次数交互断言）、interface 1 条（28 张 `witch_*` 卡缺插图）、pressure 2 条（深呼吸描述）、rewards 1 条（最终解锁段描述）。这些失败保留，没有删除有效失败断言换取绿灯；本次不把它们记为已修复。
- 补修后 UI 与规则补查的 before／after 指纹均为 `918750D99A085B68B2F1A5B608A6DBBEC0A5C15F35EC4626B270B3635FC167CE`，运行期间源码没有漂移。反馈套件含真实提交、Tween 确定性推进及逐帧像素检查，未保存默认截图。

**迁移与成品**：当前文档、根入口和 skills 的 29 份 Markdown 链接检查通过；不存在残留的 PR 旧目录受版本管理副本。Windows 验证导出 `pr45-validation-20260918` 与 `check-package.ps1 -WitchBalance` 通过，探针 `package-check-20260918T050054756` 验证导出程序、PCK、资源、内容、新游戏、练习、存档隔离、快照与小魔女平衡。导出的版本说明、Godot 两份许可文件与新位置源文件 SHA-256 一致。Windows 与 Android 打包脚本均使用新许可路径，Android include filter 包含 `packaging/licenses/*.txt`；本轮没有生成或安装 Android 包。

**交付边界**：本地整合，不自动合并 GitHub PR、不推送、不改版本号、不发布 Release。未跑全量规则／全部 UI、全种子／独立冻结 oracle、Android 真机与 macOS；小魔女 focus 的真实点击像素链及多次效果重叠观感仍沿用 PR 记录的未验证边界。

**补修敏感性实测**：临时把 `ui/main.gd` 与 `ui/impact_feedback.gd` 换回 PR #5 原实现，保留新增测试；`20260918T050537005-37408` 的 impact_feedback 155 条中恰好 7 条失败（刷新包络 5 条、返回主页清理 2 条），退出码 1。这是主动回退缺陷的预期失败，不能混入前述 8 条基线失败；运行前后指纹一致。完成后已在 finally 中恢复两份补修源码，Git 确认与暂存的交付实现一致。

**恢复补修后复验**：`20260918T050752116-23240`，impact_feedback 155 条全部通过，退出码 0，前后指纹恢复为 `918750D99A085B68B2F1A5B608A6DBBEC0A5C15F35EC4626B270B3635FC167CE`。真实震动复位像素 mean／max／share 均为 0。

**主工作区同步验证**：完整补丁已应用到主工作区，147 个变更路径（包含删除项）与整合候选逐一核对一致。主工作区 `20260918T050947519-21640` 运行 `-Import -Suite architecture`，引擎导入成功、471 条架构断言通过、退出码 0。主工作区原始字节指纹 before／after 均为 `31358B427CF948CE1870A749B8A4DE37880E5D60408568A050C4303E4C039332`；与 worktree 指纹不同的原因是已有 checkout 的 LF／CRLF 差异。按检查器同一文件集合核对 632 份文件，仅 334 份文本换行不同，归一化后源码与资源完全一致，未改写这些无关文件的换行。更改保留在本地工作区，未创建提交、未推送、未合并远端 PR。


## 2026-09-18｜v0.17.2 发布准备与专项复验

用户明确要求推送为 0.17.2，并按上版提供 Windows、Android 与双层加密合集。当前整合源码未继续修改运行时规则；project.godot 与两平台预设统一为 0.17.2，Windows 文件版本 0.17.2.0，Android 安装版本 10 → 11，包名与原签名入口保持。

发布专项 `20260918T051429212-46436`：`-Suite runner,architecture -UI -UISuite impact_feedback,home,home_persistence,persistence,display,touch -KeepGoing`，规则 906、UI 588 条全部通过，退出码 0；before／after 指纹 `F25C673B7E8AC574DD230407339E93A5FBC38C220A18B6C5267394CE2125D972` 一致。既有 8 条界面失败仍按前文对照证据披露，本轮不重跑不相关失败分类，不声明全项目或全部种子通过。版本、说明路径、Android code 与签名边界已由独立只读子代理审查，无发布阻塞项。

**正式成品与压缩验收**：Windows 构建 `package-release-20260918`、成品探针 `package-check-20260918T051716988` 通过；PE 文件版本／产品版本均为 0.17.2.0。Android 构建 `android-release-20260918`、APK 资源探针 `android-probe-20260918T051750789` 通过，versionName 0.17.2、versionCode 11；与 v0.17.1 的证书 SHA-256 相同（`9da2962a178eec7a6be1bb45c77c37372c0f18c2f2efe313e3f8aad07cdd0608`），V2／V3 签名、16 KB 对齐、provider 唯一性及 12 份内置内容校验通过。两平台 440 份导出源码清单一致；APK CRC、迁移后的两份 Godot 许可原文与开发／存档文件排除检查通过。

产物目录 `outputs/release-v0.17.2-20260918/`：Windows64 ZIP、Android ZIP、独立 APK、PC＋Android 双层加密 7z、README 与 SHA256SUMS。两个普通 ZIP 已实际解压并逐文件 SHA256 核对；内外两层 7z 均使用本次指定密码和加密文件名，错误密码不能列出目录；外层解压后内层文件 SHA256 一致，再解内层后的 38 份文件逐个与原成品匹配。没有把只测试外层当作完整验证。包内说明及发布页均披露前述 8 条旧失败；未执行完整回归或 Android 真机验收。原始日志和解压证据保留在已忽略的 build／outputs，本批不进入源码提交。


## 2026-09-19｜练习生命说明、英文与内容取数边界

基线 `79c499a`（v0.17.2）。用户截图指出玩偶师、杂乱拘束具、绳蛇与多面手练习说明滞后，要求相关内容及测试及时更新。核对发现注册表与敌人设计总表已经一致，错误位于 `data/equipment_catalog.gd::entries` 的独立文案副本。

本批将 7 条含生命数值的练习说明改为从 `Enemies.TYPES` 动态生成，双怪练习继承同一来源；同步玩偶师开场携带玩偶、首次行动激活反击与嘲讽的实际流程。`enemy_health_cases.gd::practice_descriptions` 增 24 条：8 场正式 `LiveGame` 初始化核对说明与实际生命、读取前后快照相等，并临时改变注册表后重新初始化，证明文案不会停留在硬编码常量。临时注册表值每次恢复，不改游戏平衡。

英文经现有 inventory／build_english_catalog 流程更新：7 个生命动态模板改为完整人工译文，补齐扫描发现的 16 条现有缺译。旧源文删除 15 条，新增 23 条，最终 4959 条；其余共有源文的 ID 与译文完全未变。生成器按既有源文顺序输出，避免无关整表重排。`localization_cases.gd::run` 增 16 条，覆盖 8 场当前与调整后生命的完整英文显示。第一次生成因本地缺离线翻译依赖及 16 条未缓存源文而停止；补充人工译文后成功，不安装额外运行时依赖。

规则门 `20260919T050822758-32408`：`-Suite architecture,enemies,localization,content -KeepGoing`，architecture 471、enemies 1817、localization 156、content 574，共 **3018** 条通过，退出码 0；before／after 指纹 `38E00ACB19032C0AB4E888A7CF76AFE2CC649E55D46098B8777D7CA7FFEA5494` 一致。随机池采用日常采样，未称全部种子通过。

内容 CLI 独立进程探针 `build/content-cli-20260919`：正式目录 12 文件校验通过（退出 0），损坏 JSON 与不存在目录均失败（退出 1）；空目录返回 0 文件合法（退出 0），这只证明目录内没有非法定义，不能当成完整内容验收。现有 content 用例同时覆盖批次注册失败不留下部分数据、重复初始化不重复登记。`docs/design/content.md` 明确 Wiki／导出必须额外检查加载报告与所需内容集合，每次用新进程，基础生命与遭遇覆盖值分列；当前没有 Wiki 构建器，本轮不把 CLI 结果登记成 Wiki 导出验收。人工文章应登记适用源码及依赖，依赖改变后标记待复核。

独立只读子代理核对新增依赖无环、正式开局和查询只读性、玩偶流程、临时注册表恢复、翻译语义差异与文档边界，无阻塞问题。本批仅源码／测试／文档维护，不修改已发布 v0.17.2 标签或安装包，不推送、不打包；全量回归及安卓真机未执行。

**窗口复验**：`20260919T050947917-22676`，`-UIOnly -UISuite localization`，51 条断言通过、退出码 0，指纹与上述规则门相同。覆盖真实语言选择、英文主页／设置及商店、事件、战斗显示；未请求或生成默认截图。

**后续同步授权（2026-09-19）**：用户要求更新 GitHub，本批以维护提交同步 main；提交前复算源码指纹，与上述 3018 条规则及 51 条窗口断言通过的版本完全一致，复用已有证据，不重复运行。此次仅同步源码、翻译、测试与文档，v0.17.2 标签、Release 附件及本地安装包保持原发布内容。

## 2026-09-19｜过时 UI 测试与现行文档引用维护

基线 `71d2b28`。用户要求修改检查发现的旧测试／旧文档并更新 GitHub。生产代码、存档规则与资源未改；本批不新增旧档迁移，不打包或更新 Release。

此前 `20260918T050041299-48564` 的 8 条 UI 失败中，7 条来自过时交互前提：`enemy_feedback_ui_cases.player_interactions` 未展开快捷栏就查找已安装工具（4 条）；`pressure_ui_cases.run` 把完整深呼吸说明当成紧凑摘要（2 条）；`reward_ui_cases.run` 未展开效果详情就检查最终解锁说明（1 条）。按现行 `main._basic_action_tile`、快捷栏与 `release_details.preview` 的显示契约修订测试：真实点击展开快捷栏、真实 hover 获取完整说明、真实点击展开效果详情。保留原有不可用目标、快感衰减、延后能量、次数与只支付一次等断言，并补充查看详情不改快照的检查。

测试注释中的 60 处旧文档路径改为现行分类路径与语义标题；清除旧章节号、失效批次描述，合并 `event_stacked_condition_trace_and_release` 的三段重复注释并移除其过期的未落地备注。本轮该场景随 `event_flow` 实际通过。除上述三份 UI 测试外，另外 19 份测试只改注释或一条断言提示文字；静态比对去除注释并归一该提示后，可执行内容与基线一致，未改冻结哈希、布尔断言或删除用例。

`project-map` 删除重复归档目录行；`event-pipeline` 清除历史 PR 的 E4／E5／E6 授权、只允许重命名一处等阶段限制，将单一入口、依赖边界、内容事实与 trace 隔离写为现行契约。历史本地 oracle 脚本不再作为新工作区的必备命令，仍保留结构重构的冻结比对要求与禁止重写基线掩盖差异的约束。历史记录和发布说明不改写。

分类门 `20260919T062123711-6408`：`-Suite architecture,event_flow -UI -UISuite enemy_feedback,pressure,rewards -KeepGoing -TimeoutSeconds 1200`。规则 architecture **471**、event_flow **835**，合计 **1306**；窗口 enemy_feedback **43**、pressure **86**、rewards **315**，合计 **444**，全部通过。`summary.json` 为 `passed`，无失败／未运行分类；before／after 指纹均为 `FE1E3C23D36BD74541CACC9766CD6799FEB81AE0B9DDBD5C1F09251220CBF7C0`。未生成默认截图。

静态检查：测试内全部 `docs/*.md` 引用及新增标题锚点可解析；改动文档 UTF-8 无 BOM／替换字符，本次新增／改写的 Markdown 链接存在，事件契约约 41.6 KB、项目地图约 4.0 KB；`git diff --check` 通过。另有 12 处记录类旧链接沿用撰写时路径，均已存在于基线；按只追加规则保留，不计为本批新增链接通过。辅助脚本与结构图位于忽略目录 `build/test-doc-maintenance-20260919/`。独立只读子代理审查交互、断言保留、引用与事件契约，并复核最后两段文档修改，无阻塞项。

**仍未解决**：`interface_ui_cases` 的 `CARD ART every registered card has an illustration` 在既有日志中报告 **28** 个 `witch_*` 牌型缺图（1 条失败）；本批未改资源或该断言，也未重跑不相关的 interface 分类。不以这轮专项通过宣称全部 UI 或全项目通过。其他规则分类、完整随机回归、Android 真机和打包均未执行。按本次用户授权提交并推送 main，v0.17.2 标签与附件仍对应原发布源码。

**2026-09-19 五级＝普通牢房最小基线**（分支 `feedback-effects`；成果提交见 `changelog.md` 同日条）：

域：`core/prison.gd`（`Prison.enter` 统一入场、删除 `high_security`／终局校验与文案）、`core/game.gd`（`TRANSITIONS` 去掉 `prison_high_security`、`restore_snapshot` 丢弃旧键）、`core/snapshot.gd`（去掉 `capture.terminal_equipment` 类型校验）、`data/tutorial.gd`、`docs/design/prison.md` §5／`equipment-design.md` §12／`content.md`、`docs/spec/equipment-query-seam.md`／`transition-pipeline.md`；测试域 `prison`（TERMINAL 正反例）、`relics`（`axe_amulet`）、`status`、`pressure`、`persistence`、`prison_ui`、`architecture`（索引 parity 文案）。

改动与判据：

- 五级入场与一至四级同一条路径（`RelicEffects.begin_combat` → `Prison.initial`（`left=8`）→ `Space.initial` → 躺姿靠墙 → `_reset_piles` → `begin_turn`），不再调用 `high_security()`、不再写 `prison_end`、不再写 `capture.terminal_equipment`；`prison_end` 相位声明、`status_view`／`main.gd` 只读投影保留，只服务旧档。追加与替换仍由 `PRISON_SECURITY[5]`（高级／三档／普通＋定制复合）与 `PRISON_INTERVALS[4]`／`PRISON_SENTENCE[4]` 表驱动；传送符仍限 1–4 级（`core/tool_rules.gd::escape_reason` 未改），五级只剩开门／通风口／钥匙三条路线（prison.md §4／§5 已写明）。
- 旧档 `capture.terminal_equipment` 处理采用**读档时丢弃**（`Game.restore_snapshot` 在 `validate()` 前 `erase`），快照侧的独立类型校验删除；正例与旧档各验证一次：套件内 `TERMINAL legacy manifest is accepted and dropped on load without touching the cell`（注入旧字段后 `restore_snapshot().ok`、键被丢弃、`phase` 仍为 `prison`，且随后仍能正常 `end`），以及一次性探针 `build/probe/prison_probe.gd`（打印 `legacy restore ok=true has_key=false phase=prison`，登记后已删除）。
- 规则门（冻结树；退出码 0）：`tools/check.ps1 -Suite prison,persistence,equipment,relics,pressure,status,tower_progression,exploration,architecture -TimeoutSeconds 1800` → 9/9 PASS、`PASS: 5513 assertions`、106.56s（`build/checks/20260918T170243518-9668`；`before==after==6D92FE378D8FF733EB182308DA4187DA0C1848910E0D7935F6ABAC1E576B4EFC`，无 `SOURCE CHANGED`）。**红集为空**，无既有登记外的红项；请求中的 `demo_exit`／`prison_space` 在本修订不是注册分类（`tests/test_game.gd::SUITES`），改由 `tower_progression`（内含 `demo_exit_cases.run`）与 `exploration`（牢房空间）承载，另加断言被改的 `relics`／`status`／`pressure`／`architecture`。
- 窗口门（同一冻结树；退出码 0）：`tools/check.ps1 -UIOnly -UISuite prison -TimeoutSeconds 1800` → `UI PASS: 217 assertions`、131.99s（`build/checks/20260918T170437205-44524`；before／after 同指纹）。断言含 `TERMINAL UI five opens the ordinary cell with the shortest patrol and live actions` 与「无 `本次逃脱失败`／`高安全监室` 文案」两条新判据。
- 关键正反例（`tests/prison_cases.gd::remaining_routes`）：security 5 入场后 `phase=="prison"`、`left==8`、`turn==1`、追加 6 件高级三档普通／复合 + 2 件高级三档特殊 + 1 个上锁限制项圈、原有复合结构与口部带保留、`validate()==""`、有巡视计时与逃脱候选；反例为 `not capture.has("terminal_equipment")`、无 `prison_end`、无终局清单；另加 8 个种子跨档复核。

**未验证（本轮未跑）**：oracle（迁移／事件）、像素判据、性能测量——按人指示留到定稿轮；全量回归、`normal_play` 长跑、Android 真机、打包与发布与前文口径相同。`build/transition-oracle-20260916/transition_oracle.gd` 仍引用已删的 `prison_high_security` 场景，本轮未运行也未更新（属未入库产物）。

**2026-09-19 内容包根改为单一常量 + 打包断言**（分支 `feedback-effects`；成果提交见 `changelog.md` 同日条）：

域：`core/content_catalog.gd`（`PACKS_ROOT`／`packs_root()`）、`tools/assert-packs-root.ps1`、`tools/package.ps1`、`tools/package-android.ps1`、`tools/launch.ps1`；测试域 `content`（`packs_root_single_switch`）与 `architecture`（`content_pack_root_has_no_build_feature_branch`）。契约：`docs/spec/packaging.md`（取值、翻转步骤与断言的唯一正文）、`docs/spec/project-map.md`（目录表指针）。无规则／候选／随机／存档改动，无玩家可见文案，不新增第二套内容包加载。

改动与判据：

- 常量与访问器：`const PACKS_ROOT := "res://content/packs"`（注释英文写明：发布值为 `"adjacent"`、打包前翻转打包后改回、见 packaging.md）；`packs_root()` 是唯一读取点——`"adjacent"` → `OS.get_executable_path().get_base_dir().path_join("content/packs")`，其它值原样返回。`ensure(g,root)` 的显式 `root` 参数与 `Catalog.report.directory` 不变。
- 删除：原 `directory()` 的构建类型判断（`OS.has_feature("editor")`／`("android")`）；`tools/launch.ps1` 仍只拼 `--path <游戏目录>`（本分支从未传入该开关，未改）。`core/`・`ui/`・`data/` 内除 `content_catalog.gd` 外无 `content/packs` 字样（扫描断言）。
- 打包断言：新增 `tools/assert-packs-root.ps1::Assert-SpirePacksRoot -GameDirectory <模块> -Expected <值>`，正则取 `^const PACKS_ROOT` 的字符串字面量，不符即 throw，消息含文件绝对路径与要改成的整行（`... change that line to: const PACKS_ROOT := "<值>"`）。两个打包脚本在第 8 行（先于产物目录创建、先于 `--export-release`）调用：`package.ps1` 断 `"adjacent"`，`package-android.ps1` 断 `"res://content/packs"`；两处都不自动翻转。
- Android 断言方向与派单文字不同，依据（技术事实优先）：Android 预设 `include_filter` 含 `content/packs/**/*.json`、`exclude_filter` 不排除 content，`tools/check-android-package.ps1` 也按 `SPIRE_PROBE_CONTENT='res://content/packs'` 探针，APK 旁没有可写内容目录——跟随 Windows 断 `"adjacent"` 会让装机版读不到内容。Windows 预设 `exclude_filter` 含 `content/*`（不进 PCK），故断 `"adjacent"`。文档同口径。
- 测试：`tests/content_cases.gd::packs_root_single_switch` 三条（`PACK ROOT the constant keeps the development value res://content/packs`／`... a value other than adjacent is used as the pack root itself`／`... adjacent resolves to content/packs beside the executable`，末条为源码解析式静态断言，因常量不可在运行中改写）；`tests/architecture_cases.gd::content_pack_root_has_no_build_feature_branch` 保留无 `has_feature("editor")`／`has_feature("android")`，加常量＋访问器、删除物不得回归（`packs_root_switch`／`resolve_packs_root`／`packs_root_cache`）与「只有 `core/content_catalog.gd` 拼内容包路径」（扫 `core/`・`ui/`・`data/`；文件枚举抽成 `script_files(root)`，原 `transition_core_files()` 改为其调用，行为不变）。开关、覆盖、缓存三条镜像用例按派单删除。
- **敏感性（实测，改完即还原）**：把 `PACKS_ROOT` 临时改成 `"adjacent"` → `-Suite content` 5/483 红，前两条即新判据 ①`PACK ROOT the constant keeps the development value res://content/packs` ②`PACK ROOT a value other than adjacent is used as the pack root itself: C:/1/Tools/Godot/v4.7.2-stable/content/packs`（②同时实测证明 `"adjacent"` 解析到当前可执行文件（Godot console exe）同级的 `content/packs`），另 3 条为内容包整体加载失败连带的既有 `EVENT CONDITION` 断言（`build/checks/20260919T050936427-45868`）；同改动跑 `-Suite content,architecture` 时 architecture 阶段红 1 条 `ARCH the pack root is one constant behind the single packs_root entry`＋1 条连带 `ARCH definition accessor resolves a shipped event` 并停止后续分类（`build/checks/20260919T050912171-29136`）。
- **打包断言探针（一次性 pwsh，跑完已删除）**：`build/packs-root-guard-probe.ps1` 与翻转副本 `build/packs-root-guard-probe/core/content_catalog.gd`，四例四中：真实树×`"adjacent"`→FAIL、真实树×`"res://content/packs"`→PASS、翻转副本×`"adjacent"`→PASS、翻转副本×`"res://content/packs"`→FAIL；失败消息形如 `Content packs would not load: PACKS_ROOT is "res://content/packs" in C:\1\magic-spire\spire-godot\core\content_catalog.gd. This export needs "adjacent"; change that line to: const PACKS_ROOT := "adjacent"`。探针脚本与副本已删除（断言未实跑导出）。
- 文档：`docs/spec/packaging.md`「域」收「常量决定＋二值语义＋翻转步骤＋两脚本断言」，Windows／Android 流水线段各留本平台一句；`docs/spec/project-map.md` 目录表只留指针；`spire-godot/content/README.md` 未改（其「导出后用可执行文件旁目录」仍与发布值一致）。

**门禁（冻结树；`GODOT_BIN` 指向 `v4.7.2-stable` 的 `*_console.exe`，`Godot Engine v4.7.2.stable.official.ed1daf0bf`）**：

- 规则门 `tools/check.ps1 -Suite content,application,runner,architecture -TimeoutSeconds 1800` → 退出码 **0**、4/4 PASS、`PASS: 1563 assertions`、21.99s（`build/checks/20260919T050954359-15932`；before==after==`FD814F2C5065EEB9475BE0B0F5F35303E6340D8BD2C29096BBC7C838A2E244D5`，无 `SOURCE CHANGED`）。**红集为空**，无既有登记外的红项。断言数 1560→1563（content 5→4、architecture 4→8）。
- 同一命令在敏感性翻转前跑过一次，同样 4/4 PASS、1563 断言、同一指纹（`build/checks/20260919T050758181-3328`）；翻转还原后指纹回到该值，说明还原是精确的。

**未验证（本轮未跑）**：oracle（迁移／事件）、像素判据、性能测量、真实打包与成品探针（`check-package.ps1`／`release_probe.gd`）与 Android 真机——按人指示留到定稿轮；打包脚本只跑了断言探针，**未执行 `package.ps1`／`package-android.ps1` 全流程**、未向 `outputs/` 写产物（断言位置与顺序为静态核对：第 8 行，先于产物目录与 `--export-release`）；`tools/launch.ps1` 未实跑启动游戏；`content/packs` 未改动，未跑 `tools/check-content.ps1`；未入库的 `tools/play_release.ps1`（协调者所有）仍在传已删除的 `--packs-root` 开关（第 115 行与第 10 行注释），本轮未改，需其同步；未打包、未推送。

**2026-09-19 牢房计时在战斗内暂停＋战斗不重置牢房位置**（分支 `feedback-effects`，成果提交 `8cb7db5`）：

域：`core/prison.gd::completed_turn`（战斗相位守卫）、`core/prison.gd::execute` 的 `"resist"` 分支（删除 `wall_distance` 复位）；测试域 `prison`（`tests/prison_cases.gd::battle_pause_cases`）。契约：`docs/design/prison.md` §2（计时与开战位置的唯一正文）。不改候选、随机域、存档结构与 UI 只读投影；`prison.left` 仍只有 `Prison.end_turn` 一个递减点，`served_turns` 仍只有 `completed_turn` 一个递增点，到期判定仍只有 `release_inspection` 一处。

改动与判据：

- `completed_turn` 在 `state.phase=="battle"` 时直接返回 false：不推进 `served_turns`、不做 `release_inspection`。出口战不受影响（`Prison.escape` 已清空 `state.prison`，首行 `active` 守卫即返回）；`is_exit_battle` 的练习入口同路。
- 计时路径核实（结论，战斗内没有第二条推进牢房计时的路径）：`prison.left` 仅 `Prison.end_turn` 写，而它只在 `game._end_turn` 的 `state.phase=="prison"` 分支被调用；`Prison.begin_turn` 只写 `prison.turn`，其四个调用点（`Prison.enter`／`end_turn`／`execute "resume"`／`after_preparation`）都不在战斗内；`tick_reinforcements` 只写 `reinforcements`；`release_inspection` 仅由 `completed_turn` 调用。
- 位置：删除 `"resist"` 行的 `g.state.wall_distance=g._initial_wall_distance(true)`；`prison.space.position` 原本就未被改写，返回牢房由 `Prison.after_preparation` 从 `Space.wall_distance(prison.space.position)` 重算。牢房内进入战斗的入口只有 `execute "resist"` 一处（`Prison.exit_practice` 先 `escape` 再打 `prison_gate` 出口战，`prison` 已清空；塔路 `_start_battle` 与牢房无关）。
- 文案：`execute "resist"` 的日志「巡视暂停」与 `Prison.won` 的「巡视继续暂停」经核对与新口径一致（战后持钥匙返回牢房，巡视倒计时仍暂停），`data/tutorial.gd`「战斗期间暂停巡视」同样一致，均未改。
- 文档：`docs/design/prison.md` §2 计时条改写为「牢房与返回牢房前的整备共用正式结束回合计数（刑期按完整回合累计，巡视倒计时只在牢房相位递减）；反抗战期间整套牢房计时暂停：巡视倒计时与刑期都不推进，出狱到期检查也不会在战斗内触发，返回牢房后从暂停处继续」；§2 反抗条补「战斗开始时保留当前牢房位置，不重置离墙距离」。
- 新具名 check（英文、点名域，全部在本轮门禁中真实执行）：`PRISON resistance starts a real battle from the cell`、`PRISON battle start keeps the cell wall distance and never repositions the player`、`PRISON battle round 1／2 neither advances the clock nor runs the due release check`（到期日在战前已越过）、`PRISON resistance victory keeps the keyed cell`、`PRISON return to the cell reuses the same position, the same paused clock and recomputes its wall distance`、`PRISON first cell turn after the return runs the due check and its eight-turn delay`、`PRISON keyed patrol stays paused across the delayed due check`、`PRISON battle-pause scenario keeps a valid state`。
- **敏感性（实测，改完即还原）**：把相位守卫改回 `and false` 并恢复 `wall_distance` 复位后跑 `-Suite prison`，正好红 5 条新 check（开战离墙距离、战斗第 1／2 回合计时、返回牢房、回到牢房首回合到期），`build/checks/20260919T044534482-46904`；还原后同套件 PASS。
- 既有钉住行为未动：`release_inspection_cases` 的 `PRISON repeated due violation adds eight while keyed patrol remains paused` 与 `PRISON temporary inspection preserves normal patrol schedule` 在本轮通过。

**门禁（冻结树；本机 `GODOT_BIN` 为 `Godot Engine v4.7.stable.official.5b4e0cb0f`）**：

- 规则门 `tools/check.ps1 -Suite prison,persistence,tower_progression,exploration -TimeoutSeconds 1800` → 退出码 **0**、4/4 PASS、`PASS: 2671 assertions`、142.23s（`build/checks/20260919T052015476-11832`；before==after==`409D2AF2…`，无 `SOURCE CHANGED`）。**红集为空**，未超出既有登记项（本文件既有登记集 `card_power` 5／`installed_tools` 1／`tower_progression` 10＋1／`hand_assist` 1／`home_persistence` 3，本轮所属四套件全 PASS）。
- 窗口门 `tools/check.ps1 -UIOnly -UISuite prison -TimeoutSeconds 1800` → 退出码 **0**、`UI PASS: 217 assertions`、130.76s（`build/checks/20260919T051549108-48752`；与规则门同一指纹 `409D2AF2…`，无 `SOURCE CHANGED`）。
- 工作区说明：本轮有另一任务在同一工作区在途改动（`core/content_catalog.gd`、`tools/*.ps1`），窗口门另有三次同样 `UI PASS: 217` 但被 `source_changed` 标记的轮次（`build/checks/20260919T045244562-24840`／`20260919T050521650-28376`／`20260919T051120012-40596`）与一次在 `209dd5e` 干净基线（`git stash`）上的 PASS 217（`20260919T045003779-46524`，同样被 `source_changed` 标记），均未计作证据。

**未验证（本轮未跑，按人指示留到定稿轮）**：oracle、像素判据、性能测量；未打包、未推送。范围外行为照旧未改：战斗结束后的奖励与整备相位仍按完成回合累计刑期（只有战斗相位暂停），`state.phase=="prison"` 之外的 `end` 行为未加断言。

### 2026-09-19 重跑复核：rebase 到 `origin/main`（71d2b28，含作者 v0.17.2 整合）之后（协调者）

域：本分支四提交——五级＝普通牢房（`3ad81d3`）、战斗内暂停牢房计时并保留位置（`433df58`）、内容包根常量（`29eec43`）、记录（`d3b0592`）。上面那组门禁跑在 rebase 前的旧快照上（指纹 `409D2AF2…`）；rebase 后树里含作者 v0.17.2 的内容，重新取证如下。

- 规则门 `tools/check.ps1 -Suite prison,persistence,tower_progression,exploration,content,application,runner,architecture -TimeoutSeconds 1800` → 退出码 **0**、8/8 PASS、`PASS: 4234 assertions`（`build/checks/20260919T055237178-5988`；before==after==`907FE409…`，无 `SOURCE CHANGED`，`unrun=[]`）。逐套件：application 71／architecture 479／content 578／exploration 198／runner 435／persistence 955／prison 1293／tower_progression 225。
- 窗口门 `tools/check.ps1 -UIOnly -UISuite prison -TimeoutSeconds 1800` → 退出码 **0**、`UI PASS: 217 assertions`（`build/checks/20260919T055540091-16808`；与规则门同一指纹）。
- 覆盖未缩水的旁证：prison＋persistence＋tower_progression＋exploration＝2671 断言、content＋application＋runner＋architecture＝1563 断言，与 rebase 前**逐数相等**。
- **登记集漂移（按实际报告为准）**：本文件既有登记的 `tower_progression` 10＋1 在本轮未复现（225 断言 PASS）——作者 v0.17.2 之后该项已过期。`card_power`／`installed_tools`／`hand_assist`／`home_persistence`／`interface`／`pressure`／`rewards`／`enemy_feedback` 这些宿主套件本轮未跑，不能据此宣称它们通过。
- 未跑：oracle、像素判据、性能测量、打包（按人指示留到定稿轮）。

## 2026-09-19｜PR #6 合并到当前 main：监狱与内容包根

用户要求检查新 PR 并入项目，以 PR 为优先。本轮新增开放 PR 为 [#6](https://github.com/h13942080472-prog/magic-spire/pull/6)，head `683feefe5353ee8d79b7acd18d18c50206241130`，整合前 main `02ea62262a1a89d8abc0e7b7364ba2885f37c934`。采用正常三方合并并保留 PR 的六个提交；验证册追加冲突保留双方记录，架构测试冲突保留 PR 新检查和 main 的现行文档引用。此前三份 UI 测试修复与事件契约维护未回退。

**采用的规则与接口**：五级沿正式收押→入牢→巡视／探索路径，最高规格由 `PRISON_SECURITY[5]` 决定；普通／复合追加名额为6件，不是补到总数6件，也不把原装备全部升满上锁。五级不自动出狱，传送符仍只允许一至四级。`Prison.completed_turn` 仅对 battle 暂停刑期，原巡视暂停条件保留；战后整备仍累计刑期。反抗不重置离墙距离，回牢房由原空间位置恢复。内容根由 `ContentCatalog.PACKS_ROOT` 单常量与 `packs_root()` 决定：开发／Android 为 `res://content/packs`，Windows 导出前显式设为 `adjacent`，导出后改回；两个打包入口调用共用断言，不自动修改源码。

**整合补修**：PR 删除 `directory()` 后，`tools/check_content.gd` 仍调用旧入口。实际执行内容 CLI 先复现解析失败、退出1；改为 `packs_root()` 后正式12份内容校验通过、退出0。没有恢复旧接口别名。教程同步战斗暂停、整备计刑期、五级追加规则及无限刑期；补9条人工模板、移除6条失效人工源文，英文目录4959→4949条（新增8、退役18，另校订1个已有检查规格行模板）。新动态手册模板逐行捕获四条收押规格和五条检查规格，沿既有 Localizer 递归模板入口翻译，不改运行时翻译通道。

**测试修订与失败处理**：保留 PR 的五级正反例、正式交互、存档、计时与位置检查；增加战后整备边界2条，以及完整监狱英文与变更保底数值的8条检查。首轮 `20260919T070140846-6184` 在6633条规则中仅新增的完整英文手册断言失败，其他11分类通过，窗口阶段未执行；最小只读探针确认旧碎片回退不能完整翻译拼接正文。补完整模板与规格行译文后，重跑全部本次选择范围，首轮结果不作为最终通过证据。

**最终分类门** `20260919T070539163-26888`：`-Suite prison,persistence,tower_progression,exploration,content,application,runner,architecture,status,pressure,relics,localization -UI -UISuite prison,localization -KeepGoing -TimeoutSeconds 1800`，退出0。规则 localization164、relics850、application71、architecture479、content578、exploration198、runner435、status299、persistence955、prison1295、pressure1085、tower_progression225，合计 **6634**；窗口 localization51、prison217，合计 **268**。所有选中分类均 PASS，无失败／未运行项。`summary.json.status=passed`，before／after 都是 `DECF6AB380B94BB97C819BAA7E55AAAA5DC90A4BE4975B67D8E9F9C79F3B4AB1`；日常随机采样，不是完整种子矩阵，未请求默认截图。

**补充检查**：`build/pr6-integration-20260919/` 保存结构图和临时探针。路径探针执行原内容目录访问器及仅替换常量的内存脚本变体：开发目录实际读取12份定义、adjacent 指向进程可执行文件旁、其他显式路径原样返回；生产文件未改动。打包断言5个正反例通过（两平台正确值、两种相反值、缺声明），当前 Android 配置通过，三个 PowerShell 脚本解析通过。以上仅验证路径和导出前置条件，未导出或启动新安装包。静态核对本轮核心与打包实现同 PR 逐字相同、旧接口调用无残留、测试文档引用有效、无冲突标记／编码损坏、现行文档链接有效，`git diff --check` 通过。

独立只读子代理审查监狱单入口与回滚、战斗／整备计时、位置恢复、路径与平台配置、教程和英文模板，无阻塞项；按审查意见澄清“追加名额6件”。保留 PR 自带的旧 `prison_end` 只读投影及旧清单键丢弃逻辑，不额外扩展旧档迁移。未跑全项目回归、全部随机种子、像素或性能测量、打包、Android真机。既有 interface 的28张卡牌缺图及有效失败检查未改。本次仅合并同步源码、测试、翻译、工具与文档，不修改 v0.17.2 标签、Release 或本地成品。

## 2026-09-19｜本局种子标识（地图角标）与反馈附带固定点存档

域：`core/game.gd`（`state.initial_seed` 与 `restore_snapshot` 唯一回填）、`core/game_view.gd`（只读投影 `initial_seed`／`tower_generation`）、`core/save_store.gd`（`fixed_point_text` 只读入口）、`ui/main.gd`（路线屏 `SeedChip`／`seed_report_text`／`copy_seed`）、`ui/feedback_report.gd`（`include_save`／`MAX_SAVE_BYTES`／服务端 schema 探测与降级）、`tools/feedback-service/Code.gs`＋`test.cjs`、`assets/localization/{zh_CN,en_US}.json`（`ui.map.seed`／`ui.map.seed_copied`）；测试域＝规则 `persistence`、窗口 `route`／`persistence`／`interface`／`localization`。契约：`docs/spec/seed-identity.md`、`docs/spec/feedback-deployment.md`、`docs/spec/save-fixed-points.md`。

- 规则门 `tools/check.ps1 -Suite persistence,content,application,architecture,runner -KeepGoing -TimeoutSeconds 1800` → 退出码 **0**、5/5 PASS、`PASS: 2546 assertions`（`build/checks/20260919T080806747-812`；before==after==`437ECB01…`，无 `SOURCE CHANGED`，`unrun=[]`）。逐套件 application 71／architecture 479／content 578／runner 435／persistence **983**。
- 旁证（本片改了本地化资源，额外跑）：`tools/check.ps1 -Suite localization -TimeoutSeconds 600` → 退出码 **0**、`PASS: 164 assertions`（`build/checks/20260919T081004845-44508`，同一指纹）。
- 窗口门 `tools/check.ps1 -UIOnly -UISuite route,persistence,interface,localization -KeepGoing -TimeoutSeconds 1800` → 退出码 **1**、`UI FAIL: 710 assertions`（`build/checks/20260919T080855176-40788`；before==after==`437ECB01…`）。逐套件 localization 51 PASS／route **156** PASS／interface **392** FAIL／persistence **111** PASS；红集恰为既有登记项 `interface` 的 `CARD ART every registered card has an illustration`（28 张 `witch_*` 缺立绘，登记见本文件 2026-09-17 条目），本片新增 check 全绿，无新增红，无未跑分类。
- 服务端离线：`node tools/feedback-service/test.cjs` → 退出码 **0**、`Feedback service contract tests passed; no email sent.`（本机 Node v24.18.0；砂箱替身，不联系 Google、不发信）。
- 具名 check（实测全绿）：`SAVE initial_seed is fixed at run start`／`…survives a round trip`／`…legacy save without initial_seed loads and backfills from seed`（含磁盘 `Store.unpack` 路径）／`…uses the shared field check`（`"42"`／`42.0` 与既有整数字段同一文案）／`fixed_point_text reads the bytes write_game wrote`（与主档逐字相同、不建文件不动 mtime、不改 state／随机）；`SAVE UI damaged initial_seed…` 并入既有损坏矩阵 `run_identity` 项（类型错误）；`ROUTE seed chip shows initial seed and tower iteration`（文本＋rect 在 `RouteMessages` 内且不与地图滚动区／`TowerRoute`／`MapOverview`／`MapLocate`／`MapClearDrawing` 相交）／`…follows a rebuilt tower`（真实 `demo_continue` 重建后「第 2 次塔路」）／`…copies the labelled identity`（真实点击 → `DisplayServer.clipboard_get()==ui.seed_report_text()`、四要素齐、1.2 s 后复原；窗口运行下成立，headless 判红）／`…is not part of rules, candidates or randomness`（`export_snapshot` 逐字节相同、无日志与版本变化、主档字节与 mtime 不变）／`…is bound to the route screen`（战斗屏与练习屏无、六个相位各一个）；`FEEDBACK attaches the current save by default`（默认勾选、`name`＝当前 `slot`＋`.json`、信封 `format==2` 且校验和成立、确认页显示名与大小）／`…unchecked save is omitted but submit still works`／`…oversized or missing save never blocks`（可见原因、无 `save` 键、提交照常、游戏状态不变）／`…retry keeps identical save bytes`／`…old service schema submits without the save`（`schema:1` → 无 `save` 且页面显示「当前反馈服务暂不支持附带存档。」）／`…new service schema includes the save`（`schema:2` → 含 `save`）／`…probe failure degrades without blocking`（超时／非 200／坏 JSON 三种）；既有「探测 GET＋POST」请求计数断言按新顺序更新，判据本身未改。
- 范围未缩水的旁证（与前一基线逐数）：persistence 955→983（+28）、route 134→156（+22）、interface 355→392（+37）、窗口 persistence 104→111（+7）；content／application／runner／architecture 与 rebase 后基线逐数相同。
- 敏感性证明（随后还原）：临时把 `restore_snapshot` 的副本回填改成不生效（`if false and …`）→ `-Suite persistence` 退出码 1、`FAIL: 3/983 assertions`，红项恰为该规则点名的 `SAVE legacy save without initial_seed loads and backfills from seed` 三条（`build/checks/20260919T081339911-41792`，该轮指纹 `F84A2E92…`）；`git checkout --` 还原后复跑 `-Suite persistence` → 退出码 0、`PASS: 983 assertions`、指纹回到 `437ECB01…`（`build/checks/20260919T081401299-9136`），与上面门禁同一冻结树。
- **与契约的差异（均为实现细节，接口语义不变）**：①角标 1.2 s 到期复原改用本文件既有的 `speech_deadline` 式逐帧截止（不保留任何回调），契约括注的 `_queue_map_step` 写法取其「旧回调不得改写新一局或已关闭界面」的守卫意图；②角标文本 12 px 自动换行、最小宽 118，以保住 `RouteMessages` 既有 ≤240 宽判据；③`fixed_point_text` 在 `game.validate()` 非空时返回 `ok:false`（与 `write_game` 同源守卫；仍不做大小判定、无文件访问）；④草稿文件新增 `include_save`，旧草稿缺该键时按 `true` 读入；⑤探测应答要求 `service=="spire-feedback"`（字段不符按不支持降级）。
- **未跑**（按人指示与本片边界）：oracle、像素判据、性能测量、打包与发布；未跑全量回归与全部分类；未验证公网部署与真实收件——`Code.gs` 只在本机离线砂箱执行，**未部署**，`project.godot` 的 `feedback/endpoint` 未改，故「线上邮件送达」与 `schema>=2` 的上线顺序均未验收；未做 Android 真机与桌面探针。本片只改源码、测试、服务端脚本与文案资源，未打包、未推送。


## 2026-09-19｜反馈存档附件收尾：旧草稿的捕获与降级原因（分支 `seed-chip-save-upload`）

域：`ui/feedback_report.gd`（新增 `_capture_save_once()` 与 `save_captured`；`save_reason` 改为原因码 `SAVE_NONE`／`SAVE_INVALID`／`SAVE_OVERSIZED`；`save_status_text()` 各档文案改走 `host._text`）、`assets/localization/{zh_CN,en_US}.json`（新增 `ui.feedback.save.{attached,declined,unchecked,none,uncaptured,invalid,oversized}` 七个 key）；测试域＝窗口 `interface`、规则 `localization`；契约 `docs/spec/feedback-deployment.md`「存档附件」（同步捕获时机与降级原因，并登记两条新具名 check）。两条非契约缺陷：A＝载入旧草稿后 `include_save` 仍为勾选但附件为空（`_capture_context()` 原只在 `context` 为空时捕获，旧草稿的 `context` 非空就永不捕获）；B＝`fixed_point_text` 失败时也显示「未附带存档：当前没有可附带的存档。」，与事实不符。

- 窗口门 `tools/check.ps1 -UIOnly -UISuite interface` → 退出码 **1**、`UI FAIL: 404 assertions`（`build/checks/20260919T090404002-7596`；before==after==`04FD801774BA…`，无 `SOURCE CHANGED`）。红项恰为既有登记项 `interface` 的 `CARD ART every registered card has an illustration`（28 张 `witch_*` 缺立绘，登记见本文件 2026-09-17 条目）；本片在既有 `interface` 用例内净增 12 条断言（404＝上一基线 392＋12）全部通过，无新增红，无未跑分类。
- 规则门 `tools/check.ps1 -Suite localization,persistence,content,application,architecture,runner -TimeoutSeconds 1800` → 退出码 **0**、6/6 PASS、`PASS: 2710 assertions`（`build/checks/20260919T085917003-44996`；与窗口门同一指纹 `04FD8017…`）。逐套件 localization 164／application 71／architecture 479／content 578／runner 435／persistence 983。
- 服务端离线 `node tools/feedback-service/test.cjs` → 退出码 **0**、`Feedback service contract tests passed; no email sent.`（脚本未改，作旁证）。
- 具名 check（实测全绿）：`FEEDBACK restored draft before its first use names the real reason`（未捕获时显示「本次草稿没有捕获到存档。」而非「没有可附带的存档。」）、`FEEDBACK restored draft captures at its first use`（三条：`save_captured` 置位且保留原 `context`；附件 base64 解码后信封 `format==2`、`snapshot==game.restart_snapshot()`；确认页显示附件名；另一条在改动 `map_drawings` 后再走一次 `_capture_context()`，payload 逐字不变）、`FEEDBACK restored draft checked later captures on the toggle`（未勾选不捕；勾选补捕一次并带当前存档）、`FEEDBACK every missing save names its own reason`（无来源＝「当前没有可附带的存档。」／只读入口失败＝「当前进度存档校验未通过」／超限＝「超过 2 MB」；后两档不得出现「没有可附带的存档」）。
- 敏感性证明（均在**最终测试文件**上做，随后还原）：①退回「只在 `context` 为空时捕获」并去掉勾选补捕 → `build/checks/20260919T090139630-56208` 恰红 `restored draft captures at its first use` 三条＋`checked later captures on the toggle: the checked box carries the current save`；②把三档降级原因统一成「当前没有可附带的存档。」→ `20260919T090252780-41336` 恰红 `every missing save names its own reason` 的 rejected／oversized 两条＋`restored draft before its first use names the real reason`（`none` 档本就同文，保持绿）；③去掉每身份一次的守卫（每次使用都重捕）→ `20260919T085626188-53772` 红项含 `a later use of the same draft keeps the attachment bytes`，并在 `review()` 处重捕、连带超限／未勾选等既有场景。还原后复跑窗口门 → 退出码 1、404 断言、仅既有 CARD ART 红，指纹回到 `04FD8017…`（`20260919T090404002-7596`）。
- **与协调者裁定的差异（捕获时点；接口语义未变）**：裁定写「载入草稿时捕获」，实现取「载入的草稿首次被使用时捕获」。`feedback_report._ready()` 恢复草稿发生在 `ui/main.gd` 启动时，此刻 `game` 是本进程新建的默认局（`_restore_startup()` 只刷新存档摘要，真正的局要等玩家选「继续」经 `_continue_save()`→`_resume_snapshot()` 才进入）。危害是**内容错误**：独立复核者用 headless 探针实测 `Game.new()`（即 `_ready()` 时刻 `ui/main.gd` 手上的对象）的 `validate()` 返回空串、`SaveStore.fixed_point_text()` 返回 `ok=true`（`tower.json`、约 24 KB、`initial_seed=20260906`），故在 `_ready()` 捕获会把引擎默认、尚未开打的局**当作玩家进度成功附上**；「占用每身份一次的机会」只是这次错误捕获的后果，不是独立风险。改为在 `_capture_context()`（`open()`／`review()`）与勾选复选框时补捕：仍每草稿身份只捕一次、仍在 POST 之前、仍受 `MAX_SAVE_BYTES`（UTF-8 字节）与服务端 `schema>=2` 门控，探测／附件失败只降级不阻塞；同一草稿重试的 POST body 逐字相同（既有断言未放松）。
- **已知张力（`SAVE_INVALID` 文案的覆盖面）**：该档覆盖 `SaveStore.fixed_point_text` 的全部失败，除 `game.validate()` 非空外还含 `slot not in Snapshot.SLOTS` 时的「存档位置不存在。」；后一路径实际不可达（`slot` 取自 `game.state.save_slot`），故在不改 `core/` 与只读入口的前提下两路按同一档显示——「当前进度存档校验未通过」比这一罕见路径的措辞略宽，属已知取舍。
- **计数注意**：分类断言数不是恒定判据——同一分类在不同运行里出现过不同计数（本册 2026-09-14 记录中 `home` 分类曾为 110 与 111 项），故本片以「具名 check＋分类 PASS／FAIL＋本次实际计数」并列报告，不把计数差当作覆盖变化的唯一证据。
- **未跑**：oracle、像素判据、性能测量、打包与发布；未跑 `-Suite all` 全量回归与其余窗口分类（`route`／`persistence`／`localization` 窗口分类本片未跑，不能据此宣称它们通过）；未验证公网部署与真实收件（服务端未改、未部署）；未做 Android 真机。本片只改 UI 附件域源码、本地化资源、测试与文档，未打包、未推送。


## 2026-09-19｜本局回顾面板：只读紧凑地图＋进度行＋卡组（分支 `seed-chip-save-upload`）

域：`ui/run_review.gd`（新建；唯一组装入口 `TITLE_KEY`／`TITLE_FALLBACK`／`title_text`／`can_open`／`drawer`，三块取源）、`ui/route_map.gd`（新增 `var read_only`，只影响 `_ready()` 与 `_input()`）、`ui/main.gd`（`show_run_review` 进 `DRAWERS`、`run_review_copy` 视图指针、`_run_review_copy_text()`、`_refresh_drawers()` 非主页分支、`_drawer_shell()` 整窗遮罩、`_route_screen()`／`_demo_exit_screen()` 两处 `OpenRunReview`、`copy_seed()`／`_refresh_seed_chip()` 共用同一刷新入口）、`assets/localization/{zh_CN,en_US}.json`（`ui.run_review.*` 8 条）；测试域＝窗口分类 `route`（场景 A–J）与规则分类 `localization`（新增 key 的英文完整性）；契约 `docs/spec/run-review.md`、依赖约束 `docs/spec/run-review-dependencies.md`。本片 `core/`、`data/`、`Snapshot.REVISION`、`ui/feedback_report.gd`、未跟踪的 `tools/play_release.ps1` 零改动；未新增候选、View 键、随机域与存档域。

- 规则门 `tools/check.ps1 -Suite localization,architecture -KeepGoing -TimeoutSeconds 900` → 退出码 **0**、2/2 PASS、`PASS: 643 assertions`（`build/checks/20260919T101432352-51844`；`summary.json` `status=passed`、`before==after==1538E89D…`（本工作树当时的 before==after，见下「指纹口径」），无 `SOURCE CHANGED`，`unrun=[]`）。逐分类 localization 164／architecture 479（与上一批逐数相同）。
- 窗口门 `tools/check.ps1 -UIOnly -UISuite route,localization -TimeoutSeconds 900` → 退出码 **0**、`UI PASS: 304 assertions`（`build/checks/20260919T101507524-54388`；`status=passed`、`before==after==1538E89D…`，与规则门同一工作树、同一冻结源码，`unrun=[]`）。逐分类 localization 51 PASS／route **253** PASS；无引擎错误、无红项。引擎为本机既有门禁口径 `Godot Engine v4.7.stable`（`GODOT_BIN`，与前几轮 check 日志同版本）。
- 旁证（本片改了共享的 `ui/main.gd`，复查既有红项未被放大）`tools/check.ps1 -UIOnly -UISuite interface` → 退出码 **1**、`UI FAIL: 404 assertions`（`build/checks/20260919T101606115-49320`，同一工作树指纹）。红项恰为既有登记项 `CARD ART every registered card has an illustration`（28 张 `witch_*` 缺立绘，登记见本文件 2026-09-17 条目），断言总数与 2026-09-19 已登记的 interface 404 逐数相同 → 本片未在 interface 增加断言或红项。
- **指纹口径（复核更正，2026-09-19）**：`summary.json` 的 `before`／`after` 只是**同一次运行内**「源码有没有在运行期间漂移」的守卫（不等则 `SOURCE CHANGED` 且整轮 `source_changed`，不得当作通过），**不是提交或工作树身份**，不能拿两次不同运行的数字互相对账。`tools/check.ps1::Get-SourceFingerprint` 把 `core/data/ui/tests/content/assets/tools` 下**磁盘上实际存在**的 `.gd/.json/.tscn/.tres/.svg/.png/.webp/.ps1/.py` 文件（**含未跟踪文件**，如未入库的 `tools/play_release.ps1`）与模块根 `main.tscn`／`project.godot`，按「相对路径:sha256」排序拼接后再取 SHA256，故同一提交在不同工作副本、不同未跟踪文件集（各自的一次性探针、残留文件）下会算出不同数字。实测：本片三次运行（`20260919T101432352-51844`／`20260919T101507524-54388`／`20260919T101606115-49320`）都报 `1538E89D…`；本轮记录同步时在主工作树的 `ff031c7` 源码上（此后 `a5567f8` 只动 `docs/spec/`，不在指纹范围内）按同一算法复算仍是 `1538E89D…`（该文件集 635 条：core 47／data 27／ui 55／tests 186／content 17／assets 274／tools 27＋模块根 2），即该数字对本工作树的既有文件集可复现，与复核副本的差异来自文件集（未跟踪文件的有无），不是源码在动。独立复核者在其工作副本上两次运行得到 `44054EBEFFB8BBE4…`（`20260919T102005588-48648` 规则门 643＝164＋479；`20260919T102123055-19992` 窗口门 304＝51＋253），为复核侧的可复现值。跨运行可对账的是**逐分类计数与具名 check**，不是指纹。
- 具名 check（实测全绿，窗口 run 20260919T101507524-54388，即最终冻结树那轮）：`ROUTE run review is not part of rules, candidates or randomness`（面板内滚动、切费用筛选、点地图、右键拖拽、点复制按钮后 `ui.view.version`／`ui.view.candidates` 深比较／`export_snapshot()` 逐字节相同、主档与 `.bak` 字节与 mtime 不变、`RunReviewMap.strokes` 仍为空）／`ROUTE run review node click never departs`（`view.phase=="map"`、`rooms_completed`／`journey`／`version`／`state.room`／快照全不变，且 `RunReviewMap.read_only==true` 与 `buttons.is_empty()`）／`ROUTE run review map matches the projected route`（`graph.rooms==ui.view.route`；新塔无 `travelled`／`travelling` 边且 `state.traversed_edges` 为空；真实出发抵达后恰一条金边且与 `state.traversed_edges` 逐项一致）／`ROUTE run review progress counts the walked nodes`（新局 `{floor}=0,{nodes}=0` 且顶栏「第0层」；抵达后与 `max(state.room ∪ completed_rooms 各 floor)+1` 及 `completed_rooms.size()` 相同、顶栏「第1层」）／`ROUTE run review deck lists every physical card`（`RunReviewDeck.cards`／`DeckGrid` 子节点数／`DeckCount` 分母都等于 `view.deck_cards.size()`；搜索只改分子）／`ROUTE run review identity reuses the run report text`（`RunReviewIdentity.text==ui.seed_report_text()`、`RunReviewCopy` 未复制文本＝`ui._text("ui.run_review.copy",…)`；真实 `demo_continue` 重建塔路后仍与新的 report 逐字节相同）／`ROUTE run review entries follow the route data`（练习局与牢房 `find_children("OpenRunReview")` 为空；路线屏恰一个且在 `RouteWorkspace` 内且不与 `TowerMapScroll`／`TowerRoute`／`MapOverview`／`MapLocate`／`MapClearDrawing`／`SeedChip` 相交；通关屏与 `demo_finished` 两态各恰一个在 `DemoExitPanel` 内且面板 rect 尺寸不变、所有可见子控件都在其矩形内）／`ROUTE run review behaves like the shared drawer`（`DismissDrawer` 遮罩 1600×900；遮罩、`CloseDrawer`、Esc 三种方式都关闭且快照不变；面板内单击不关闭也不穿透）／`ROUTE run review copy exists in both languages and records no miss`（zh_CN `localization.diagnostics()` 为空；切 en_US 后 8 条 key 的实际解析文案无中文、面板子树除标识文本外无中文残留、`projection_misses` 为空；切回 zh_CN 复原）／`ROUTE run review copy shares the chip display state`（`RunReviewCopy` 点击后 `DisplayServer.clipboard_get()==ui.seed_report_text()`、`seed_copied_until` 未到期、角标与面板按钮同窗都显示 `ui.map.seed_copied`，1.3 s 后两处一起复原且 `seed_copied_until==0`；复制后先关面板再到期不产生引擎错误、角标照常复原；期间快照／候选／版本／主档与 `.bak` 不变）。
- 敏感性证明（逐条在**最终测试文件**上做，见下逐条 run；每条随后 `cp` 还原并复跑绿）：A 把复制按钮回调解成 `ui.copy_seed();ui._save_progress()` → `20260919T095555086-55116` 恰红 4 条存档不变量（`SAVE run review in-panel interaction leaves the primary/backup file bytes and mtime untouched`＋`SAVE run review copy leaves the primary/backup …`；快照断言仍绿，因写盘不改 `game.state`）；B 去掉 `route_map._ready()` 的 `read_only` 早退（保留 `_input` 早退）→ `20260919T095644123-51116` 恰红 1 条 `…the review map has no room hit target`（`buttons.is_empty()`；「点击不出发」仍绿，因该实例的 `room_selected` 未连接）；C 把回顾地图改成 `rooms=route.filter(status=="completed")` → `20260919T095734922-51696` 恰红 C 的 2 条同源/金边断言；D 把当前房间计入节点数 → `20260919T095840735-18804` 恰红 D 的 2 条（新局读到 1 个节点、抵达后与权威计数分叉）；E 卡组源换成 `view.draw_cards` → `20260919T095934653-10788` 恰红 E 的 2 条；F 标识文本改硬编码 → `20260919T100029985-30672` 恰红 F 的 2 条（逐字节相等与随重建变化）；G 临时在 `_bottom_controls()` 无条件建同名入口（模拟「漏掉空 route 判据的空壳」）→ `20260919T100708396-34440` 红 5 条：练习局无入口、监狱无入口、路线屏恰一个、通关屏「恰一个」与「子控件在面板内」；H 遮罩条件去掉 `show_run_review` → `20260919T100223366-43772` 恰红 H 的 2 条（遮罩 1600×900、遮罩点击关闭）；I 删 en_US `ui.run_review.copy` 条目 → 规则 `-Suite localization`（`20260919T100805693-54056`）恰红 `LOCALE English is complete for registered IDs while Japanese remains an empty scaffold`（1/164），另把标题写死中文 → 窗口 `20260919T100318434-51704` 恰红 1 条 `…the English panel keeps no Chinese outside the identity report: ["本局回顾"]`；J 让 `_refresh_seed_chip()` 只刷新角标 → `20260919T100406441-28524` 恰红 1 条 `…both views show the copy caption in the same window`。还原后末轮两门在 `1538E89D…` 上全绿（上两行 run；该轮只把 `ui/run_review.gd` 头部注释里 `clipboard` 一词改成「writes to disk」，以满足依赖清单的字面自检，行为零变化）。
- **与契约的差异（实现细节，接口语义不变）**：①契约括注 `RunReviewIdentity` 用「Label 可选中」，Godot 4.7 的 `Label` 没有 `selectable`（实测赋值报 `SCRIPT ERROR: Invalid assignment of property or key 'selectable' … on a base object of type 'Label'`），改用 `RichTextLabel`（`selection_enabled=true`、`bbcode_enabled=false`、`fit_content=true`、`scroll_active=false`）承载同一四要素文本，节点名仍为 `RunReviewIdentity`、文本仍逐字节等于 `ui.seed_report_text()`；②`_refresh_seed_chip(force: bool=false)`：函数名与「只在到期那一帧改写」的轮询语义不变，`copy_seed()` 写剪贴板与截止时间后走 `_refresh_seed_chip(true)` 立即改写两处视图；③通关屏 `DemoExitPanel` rect 高度 430→520（契约允许按内容调整），两态判据为「rect 尺寸不变＋每个可见子控件都在面板矩形内」；④面板内「滚动」由 `_scroll` 内容列自身的 `scroll_vertical` 驱动（仓库既有写法，如 `interface_ui_cases.gd`），不用合成滚轮事件——合成滚轮会把 viewport 的 GUI mouse focus 卡在滚动控件上，之后所有按钮点击都被吞掉（实测：A 场景后 `CloseDrawer` 连点两次 `pressed` 都不触发、按住时 `is_pressed()` 仍为 false，而该按钮可见、enabled、`mouse_filter=STOP` 且 `gui_get_hovered_control()` 就是它）；换成属性滚动后同一轮 253 条全绿。这是测试夹具的手法差异，不是产品行为；⑤`RunReviewDeck` 就是共享 `deck_browser` 实例（`setup()` 之后改名），契约点名的 `RunReviewDeck.cards` 即该实例字段，未写第二套卡组列表；⑥进度行 `{floor}` 取 `maxi(0, max(completed/current floor)+1)`，空集合与塔底（`floor=-1`）都按 0 显示；⑦场景 I 的 `no_route`／`deck_empty` 备选文案按 `ui._text(key, 与 zh 逐字相同的 fallback)` 的实际解析结果验证（进度行按真实调用形状传 `{floor}`／`{nodes}`，避免缺参调用记 `call_parameters` 并污染 `localization.diagnostics()`），未在界面上另造空 route／空卡组两态。
- **独立复核证据（新会话，域＝本局回顾面板，边界＝`docs/spec/run-review.md`；复核者不改代码）**：复核声明 1–9 逐条 pass，七条「与契约的差异」全部判为**契约中性**，**未发现产品缺陷**。它自己的变异（复核侧自报；除 V5 外其运行号不在本机 `build/checks/` 内，故只登记结果与红项）：V1 进度行把 `current` 计入 → 恰红 D 两条；V2 标识文本换 key → 恰红 F 两条；V3 复制按钮直连 `DisplayServer.clipboard_set` → 恰红 J 一条；V5 地图 `rooms` 过滤 `completed` → 恰红 C 两条（该轮在主工作树运行：`build/checks/20260919T102954207-42312`，route FAIL、253 条、`AF0405AE…`；复核随后 `git checkout` 还原并以 `hash-object` 与 HEAD 核对一致——**该目录是复核的变异轮，不是本片的运行，不进本片证据链**）。V4（`can_open` 恒真）**0 红**，见下条观察①。两条探针：leak 4 轮开关 `InformationDrawer` 子节点数恒为 `[1,1,1,1]`、活动节点数恒定 228、`ui.run_review_copy` 每轮跟随重建；输入探针确认滚轮能滚、只有「只发 press 不发 release」的合成滚轮才卡住 GUI mouse focus（补发 release 即恢复），Esc 可关。失败语义探针：`view.route=[]` 时 `RunReviewMap` 变为 Label 且文本逐字等于 `ui.run_review.no_route`；`view.deck_cards=[]` 时 `DeckEmpty` 可见且文本等于 `ui.run_review.deck_empty`；夹具还原后两处复原（与 `run_review.gd::_route_block`／`deck_browser.setup(…, empty_message)` 的实现一致）。
- **两条非缺陷观察（不在本片返工；planner 已据此改契约口径）**：①`can_open` 的敏感性缺口——本片建入口的两个站点（`_route_screen()`／`_demo_exit_screen()`）在练习局与牢房相位不会被渲染，故 `can_open` 改成恒真（V4）无红项；场景 G 的「练习局／牢房不摆空壳」守的是「入口只在有路线数据的屏上创建」，不是 `can_open` 本身的返回值；②路线屏 `navigation`（2 列 GridContainer）追加第三个单元后多出一行固定高度，`right` 列里 `SIZE_EXPAND_FILL` 的 `TravelMessageScroll` 相应变矮（复核者观察到的既有按钮相对位移以复核侧几何实测为准，本轮只做记录同步、未复测该几何）。
- **计数注意**：分类断言数不是恒定判据。本片窗口 `route` 253（上一批登记 156，本片新增 97 条）、`localization` 窗口 51 与规则 164、`architecture` 479 与上一批逐数相同；`interface` 旁证 404 与 2026-09-19 登记相同；复核侧两门计数与本片逐数相同（643＝164＋479、304＝51＋253）。计数只作范围佐证，判据仍是具名 check ＋分类 PASS／FAIL ＋本轮实际计数。
- **未跑**（按契约「证据入口」与本片边界）：`-Suite all` 全量回归、oracle、像素判据、性能测量、打包与发布（`tools/package*.ps1`）、`tools/check-content.ps1`（内容包未改）、公网部署与真实收件（反馈域未改）；窗口分类只跑了 `route`／`localization`／`interface`，`persistence`／`service`／`prison`／`tower_progression`／`home_persistence`／`departure` 等**未跑**，不能据此宣称它们通过；Android 真机、触屏与安卓返回键关闭未验证（返回键走既有 `DRAWERS` 清单，本片只加字段，窗口门只覆盖 Esc）；画面观感与窄窗布局未做像素判据。本片只改 `ui/` 三文件、两份本地化与测试，未打包、未推送、未打标签、未改版本号。

## 2026-09-19 · 反馈9659e10：饱和结算后第4→5回合卡住的调查

- 输入：反馈9659e10bf91d1e9625a5815e4df1fdbc，报告版本0.17、Android。玩家称大量拘束具后敌人自动离场、之后移动或战斗无法继续；没有原局存档和行动日志，提交时已新开一局，因此商店位置和种子1632031465不能认定为故障局状态。用户无法补充菜单是否响应，并明确排除本次内存／性能优化范围。
- 源码：main `00e6327`（已含0.17.2及PR #6）。只审查Game._finish_if_saturated／_finish_battle／_end_turn／_advance_travel和EnemyFeedback展示锁；未改运行时代码。未将本机样例当作原局复现，也未判定内存根因。
- 复现结构：测试夹具经共享Application安装和原强化操作形成99个可操作装备／连接目标，进入真实饱和奖励；后续只由候选ID＋版本提交reward→end→depart→travel_step→end，每步读取View并核对状态未被查询修改、有后续候选。特殊怀旧模式关闭。饱和奖励、3次整备结束、5次移动全部成功；下一场第4回合自然饱和进入reward。另以drone_solo通过正式_start_battle初始化持续战斗，4次end从第1回合进入第5回合。最终诊断exit0、无脚本／引擎错误。诊断初稿的日志路径和未生成意图的临时夹具错误已修正，不算产品复现或通过证据。
- 正式门禁：`tools/check.ps1 -Suite battle_saturation -UI -UISuite enemy_feedback -TimeoutSeconds 240`，运行号`20260919T074404772-30912`；battle_saturation 34、enemy_feedback 43，合计77项通过，exit0、summary.status=passed、before=after。窗口覆盖实际行动展示结束后解锁、跳过展示及返回主页清理；这不是Android真机验收或全项目回归。
- 独立只读审查：`review_feedback_9659e10`核对共享回合／移动入口和展示锁生命周期，未发现4→5专属守卫或确定性无法推进路径；认可上述局部证据，强调不能推出原局内存根因。
- 结论：当前样例未复现确定性逻辑死锁，不做猜测性规则修复，不宣称反馈已修复或0.17.2必然解决。后续若取得原局存档／日志或新版复现再定位。此次仅登记调查记录，未打包、推送或发布。

## 2026-09-19 · 控火：稀有度、永久加伤与分面消耗

- 实现：`CardRules.SPECS.fire_control` 改为稀有、自由面永久加伤＋1并声明分面消耗；移除 `Balance.CARD_TRAITS` 的整牌消耗，普通／稀有列表同步。沿既有 `CardRules.exhausts`、`CardEffects.play`／`settle_played_card` 和卡面动态投影，无新增执行分支。拘束面仍为2层魔力预备；小魔女排除规则保持。
- 覆盖：更新永久加伤叠加、倍率顺序、条件／资源／旧版本回滚、跨战与快照、复放、图鉴分面关键词及实际界面点击。新增同一张拘束面牌打出→弃置→洗回抽牌→再打出，再切自由面消耗的正式提交路径。
- 首轮 `20260919T100056260-27236`：新增夹具清空两牌堆但保留永久卡组，导致校验回滚、4条断言失败；奖励与窗口未执行。独立审查指出该夹具缺陷，修正为原卡全部移入消耗堆、保留牌堆一致性；没有放松运行时检查或删掉失败案例。
- 最终续跑 `20260919T100448254-48008`：card_expansion 1096、rewards 716、窗口 card_power 307，共2119条通过，退出0，summary.status=passed，无失败／未运行项；before=after=`B5065AA7E78863258828D9557BA8C686C947F0AF3E430D0834BA73765E184D29`。独立只读审查 `review_fire_control` 复查修正后无新问题；英语动态占位仅静态核对。
- 范围：针对卡牌规则、奖励及卡牌界面的局部验证，日常随机样本；未跑完整回归、英语窗口或Android真机。现行设计表已同步。本次仅本地源码和文档修改，未打包、推送或发布。


## 2026-09-19 · 控火稀有度更正为罕见

- 按用户最终要求，SPECS.fire_control.rarity 改为 uncommon，从 RARE 移入 UNCOMMON；同步现行设计表及规则、图鉴、窗口断言。上一轮的稀有度结论被本条取代，＋1加伤及分面消耗保持。
- 运行 20260919T101411091-33228：card_expansion 1096、rewards 716、card_power 窗口307，共2119项通过；exit0、status=passed，before=after=0AF8DEFF2210DFA5D5F7DB55FDED2C598F7EC186F6F0222A19920423C43FF4BE。本次无失败或未完成分类，日常随机采样，未做全项目回归或Android真机验收。
- 独立只读审查 review_control_uncommon 核对规则／列表／图鉴／测试／现行文档一致，无发现；小魔女仍排除此牌。仅本地源码与文档修改，未打包、推送或发布。


## 2026-09-19 · UI：左侧面板铺满黑边

范围：body_sidebar场景和分区几何、main._bottom_controls的面板及资源条几何；不改规则、候选、数值或存档。结构和数据流见[解缚界面契约](../spec/release-interface.md)的场景结构。保留其余在途修改。

检查：首次误用未注册mana_flask窗口分类，工具明确拒绝，未计通过；改用归属consumables。20260919T102902629-33020中display／body_layout／consumables共346项断言通过，含1项显式截图；检查期间源码变化标记source_changed。按原范围复跑20260919T103107218-35116，345项全部通过（未重新指定截图），仍因并行修改标记source_changed，因此不宣称冻结源码门禁通过。未跑规则全量、未做安卓真机验收。

已查看ui-83-portrait-equipment-sidebar.png：三个面板左右对齐，外框接顶栏与底部，立绘等比；新几何断言覆盖375宽、531高、4像素分隔和底边900；原展开、拖放与魔瓶真实支付测试保留。独立子代理review_left_fill只读审查无阻断发现，覆盖几何、命中、比例、缓存及测试契约；其提示adaptive_regions内512高仍为缩放夹具，本次视觉证据取初始531高截图，不使用该缩放截图交付。git diff --check通过。仅源码修改，未提交、打包或发布。

## 2026-09-19 · 魔瓶战斗内存取各3次，战斗外不限次数

- 规则：沿 ManaFlask 正式候选→Game.dispatch→ManaFlask.execute 通道，仅 phase=battle 分别限制存入与取出各3次。原存入计数沿用；取出计数为 combat 中可选 flask_withdrawals，旧快照缺项按0使用。原回合重置点改调用 ManaFlask.reset_turn，进入下一战重新初始化。战后领奖、整备、休息、商店与监狱等战斗外阶段不扣次数。转移量、实际余额、身体条件与药剂折算沿既有接口。
- 界面与文案：战斗中分别显示存／取三格次数，战斗外隐藏限次指示，操作提示明确不限次数；金额上移以避开双排次数。中英文提示、生成器人工译文及现行资源表同步。
- 覆盖：第3次成功／第4次资源充足仍拒绝、两类独立计数、旧版本提交回滚、下一回合重置、存档保留次数及缺新字段、负数／超限／错类型计数拒绝且回滚、领奖时用满计数立即解除、整备／商店／休息／监狱连续5组存取、实际按钮禁用及计数、完整英文提示。非法计数测试会直接检出移除相应校验后的错误接受，不增加无对应失败案例的校验。
- 首轮 20260919T102722152-14644 的4条新增测试失败：读档会更新版本，测试错比对入档前快照；下一回合敌人拘束上肢，干扰取出动作。修正为比较读档后的快照、用坐姿隔离握持条件，未修改实际身体规则。第二轮 20260919T102903863-31424 的1229条规则与55条UI均通过，但其他在途修改导致 source_changed，不作为最终证据。
- 独立只读审查 review_flask_limits 指出并复查修复：旧COPY R1夹具缺少limited及正确余次；英文取出提示需要完整动态模板。新增完整提示断言，同步夹具后加跑architecture；复查无遗留发现。
- 最终 20260919T103130091-42576：localization164、consumables275、architecture479、persistence955，规则1873；consumables窗口55，总1928项通过。exit0、summary.status=passed，无失败／未运行项，before=after=ABAF81F0A08C2A6B93D0DCE1D274FDC9F79F2E6E7B513F9BEB2F29AE035B8C1D。git diff --check通过。英文资源清单扫描及定向人工维护已完成，未整库自动重译。
- 口径：局部验证、日常随机样本，非完整回归，未做Android真机或像素验收。保留工作区其他任务的敌人、身体侧栏和控火等修改；本条仅记录魔瓶范围。仅本地源码与文档，未打包、推送或发布。


## 2026-09-19 · 玩偶师屏障、反击容量与循环

- RuleChangePackage：只调整玩偶师及玩偶注册表、统一敌人伤害入口、既有玩偶受击／缝补助手和只读状态投影。当前规则真源见[第一幕敌人 §7](../design/enemies-first-floor.md)。护身屏障额度不分攻击次数，覆盖物理、魔法、固定、群攻与玩偶转移；生命基数最终为15。持有上限由初始容量与缝补次数派生，不保存第二份上限。替换、层级、位置、品质和施法等资格仍走原装备／攻击管线。
- 数据流与写入边界：注册表 → 原召唤初始化 → Game._damage_enemy（倍率后扣本回合额度）／Puppets.damage（普通反击消耗与额外准备分离）／Puppets.execute（缝补补满） → 原状态固定点与StatusView。Game._start_round在回合开始效果前重置屏障计数；UI仅显示剩余数字，不维护镜像额度。

```mermaid
flowchart LR
  A[正式攻击、卡牌、遗物] --> B[统一敌人伤害入口]
  B --> C[玩偶受击反应]
  C --> D[消耗普通反击余量]
  D --> E[原装备施加入口]
  C --> F[独立消耗额外准备]
  F --> E
  C -->|溢出转移| B
  B --> G[玩偶师本回合额度限伤及扣血]
  H[正式回合开始] --> I[重置屏障额度]
  J[缝补行动] --> K[提高上限并补满生命与反击余量]
  G --> L[只读状态图标]
  I --> L
  K --> L
```

- 状态／快照：新增敌人实例barrier_damage及puppet_stock，导出、恢复保留当前余量；旧版本提交不重置。复用既有快照及提交后聚合校验，新增字段型别／范围有对应非法值回滚案例；没有新增提交前早拦。无旧档迁移，缺少新计数的旧玩偶师／玩偶战斗快照拒绝恢复，其他快照结构不改。随机仍用原enemy域，容量用尽不再执行普通施加随机；额外准备的冻结款式与原触发规则保持。
- 文案：更新屏障当前余量、反击容量图标及其说明、缝补意图与结果日志；图标只显示本回合剩余可受伤害，不强调层数。中文与英文人工映射及兼容目录同步。无新增旁白动作。
- 新案例：29／30／31伤害边界、多来源共用额度、真实多段及随后伤害不补额度、零伤害、下一正式回合重置、耗尽快照恢复／旧版本拒绝、反击第3次及第4次边界、库存耗尽时额外两类装束仍触发、缝补增容补满、错误型别及越界快照原子拒绝、真实闪避阻止佩戴仍扣库存、两个玩偶师独立额度。实际窗口点击验证图标30→22→30→0、反击3→1→4和英文说明；周目倍率与固定缝补生命仍覆盖。
- 过程：首轮20260919T102630212-27244规则通过，窗口测试错误地从按钮直接查找嵌套的StatusCount，改为按实际节点树查找；随后用户将生命定为15。20260919T102915804-23784的3条失败来自enemy_health_cases遗留10HP期望，保留同样断言并改为新批准值。20260919T103218744-45104的enemies1864与窗口220项通过，但源码变化，不能作为冻结结论。
- 独立只读审查review_puppeteer：检查统一伤害入口、重置时机、保存与回滚、库存隔离、UI与非目标敌人。提示的旧生命期望和旧设计正文均已修复；补充失败佩戴消耗及独立额度案例，复查无遗留实现问题。总表的循环描述亦按审查建议改为首轮觉醒后T2—T4。
- 最终20260919T103442351-31656：localization164、basic_attacks181、intent89、status299、enemies1864、tower310，共2907项规则断言；enemies窗口220项，共3127项通过。exit0、summary.status=passed、源码指纹前后一致。命令：tools/check.ps1 -Suite enemies,basic_attacks,status,intent,localization,tower -UI -UISuite enemies -TimeoutSeconds 300 -KeepGoing。git diff --check无空白错误。
- 口径：受影响分类与日常随机样本，不是全项目完整回归；没有截图、Android真机、打包、推送或发布。保留同仓卡牌、魔瓶与身体侧栏等其他任务修改。


## 2026-09-19｜卡牌：猪神之皇焚超级顺延与蓄力6

- 最终证据：spire-godot/build/checks/20260919T103732359-12812/summary.json，status=passed、源码指纹稳定。localization164、card_power1788、card_expansion1101、architecture479，共3532项规则断言通过；card_power窗口307项通过。不是全项目或安卓真机验收；只改源码，未打包、提交或发布。
- 覆盖原目标持续五段、区域内优先、全身补选手腕优先及新区域顺延、五段上限、仅一次付款、普通顺延不跨区反例、无目标提前结束、快照随机重现、过期／不足能量拒绝、自由6层及已有2层累加到8、目标详情与关键词同源，以及真实拖放跨区域／翻面／免费目标施放。
- 独立只读审查Hegel：发现目标详情沿用“不跨区域”和文档重复旧值，已修复；新增断言误传candidate ID被门禁捕获，改为候选字典后完整重跑原选择范围。复核无遗留问题，git diff --check通过。
- 本地化完成盘点，本次新“挣扎{base}×{hits}。超级顺延。”模板已人工加入生成器与英文目录；全目录生成因另两条dots源串无缓存且缺离线翻译依赖未完成，未修改这两条无关文案。最终localization分类验证通过。

## 2026-09-19｜装备：平板锁解锁后挣扎无视加固带

- 规则真源见 [装备设计 §11.1](../design/equipment-design.md)。复用 SpecialEquipment.unlocked_release 判定，正式候选、伤害执行与 ReleaseView 预览共用；只排除目标所属加固带，仍沿用手部／环境条件、支付和统一级联清理，无新增资源写入通道。
- 覆盖三个普通型号、锁定拒绝、锁体低紧度且加固带3档、零伤害、旧版本拒绝与状态不变、一次支付、只清理所属加固带、诅咒分支保护；原滑脱用例保留。UI 用真实拖放验证预览与整件取下。
- 20260919T105443822-35316：localization164、architecture479、content578、special_equipment350，共1571项，exit0且源码稳定。补充诅咒边界与拖放案例后，20260919T105652515-33456规则special_equipment351项通过；UI因并行新增素材endless_war_goddess.svg尚未导入而编译失败，未执行断言。
- 完成正式素材导入并仅重跑失败窗口范围：20260919T110010690-5484，special_equipment窗口57项通过，exit0、源码稳定。未重跑全项目回归、未做安卓真机验证。
- 独立只读审查review_plate_strain完成，检查准入、执行／预览一致性、级联清理、支付与保护边界，未发现遗留问题。git diff --check通过。仅源码与文档修改，未打包、推送或发布；保留并行任务修改。

## 2026-09-19｜卡牌：无尽魔法少女战神

- 结构：CardRules声明 → CardEffects.reason/face_mana → Game.dispatch/_cast_magic支付与施法 → 既有能力区。能力区 → CardEffects.basic_attack_freedom → 原有基础动作候选、施法投影与执行 → action rail既有右键切换。踢击变体由BasicAttacks原定义派生，未增加第二套伤害与支付通道。
- 覆盖两角色、两面，50点门槛、临时魔力优先、魔瓶不参与、嘴部硬条件、旧版本回滚、失败返还、专属成功台词、高拘束／高快感／躺姿、普通魔法卡反例、冷却与次数保留、存档恢复及战后失效。真实鼠标输入覆盖出牌、七种踢击循环及下一场重置。
- 初轮修复测试读取原始候选不存在casting字段、恢复整备禁止自由面效果的既有拒绝优先级；小魔女夹具使用角色实际快感上限避免非法状态。专项20260919T110758825-4244通过1171项；UI因并行新增formation.svg未导入未执行。导入后扩大检查遇并行卡池暂缺sympathetic_form定义；定义补齐后又定位到新增英文目录两条%d没有转换成{p0}，已同步修正目录与生成器以恢复目录加载。
- 20260919T111716833-24568：八个规则分类3950项、card_power/basic_attacks窗口573项均通过；期间共享源码变化，status=source_changed，不作为最终冻结工作区通过，已按门禁要求重跑全部原选范围。
- 独立只读审查review_war_goddess完成，修正火球手势伤害／说明一致性、固定捕缚时不误报踢击后躺下；保留原高潮流程以避免与零能量不变量冲突。增量复查未发现遗留问题。


## 2026-09-19｜卡牌：交感形态

- 完成3费稀有能力、两面回合开始触发、普通／复合／链接／肩带及限制项圈筛查、仅特殊装备豁免、mana上限与Pressure.gain倍率／高潮、能力叠加／共存、原始回能后能量追加、临时魔力池、卡面图鉴与专属SVG。语义与参数详见[卡牌设计](../design/cards.md)，调用路径见当日changelog。
- 规则：build/checks/20260919T111629727-11884中card_power1941、architecture479通过；其余失败后复跑build/checks/20260919T112107444-43908，localization164、card_expansion1173通过，pressure1109项中8项失败全部为在途endless_war_goddess的耗魔预期，与本卡新增效果无关。未删除这些失败案例，不称整批通过。
- 窗口：build/checks/20260919T111955822-21700中card_power337项全部通过，包含本卡两面展示、3费、专属图片、实际点击进入能力区、无即时赠予、实际结束回合后的mana／temporary_mana／energy投影。运行期间外部在途源码变化，summary为source_changed；先前整分类复跑曾被另一任务wrist_bracer.svg未导入阻止，经正常Import再完成此次用例。不是冻结工作区整批门禁或安卓真机验收。
- 独立只读审查Archimedes发现旧root计数排除限制项圈，已通过include_lock_only可选参数修复且保留原调用默认；仅项圈阻止与解除恢复、自由双层、普通高潮、大理石0.6倍率、过期／不足能量拒绝、条件重新满足、存档恢复、能力清理后不再触发均有直接证据。复核未发现遗留实现问题。早期失败来自SPECS漏登记、测试接口误用及沿用了旧高潮魔力预期，已修复，未删除失败案例。
- 新增中文与英文人工映射已同步；运行localization_inventory完成盘点，整目录英文再生曾因其他5条源串无缓存且离线依赖缺失而中止，本次条目独立补入目录后localization复验通过。矢量来源记录于ART-NOTES；diff检查通过。只改源码，未提交、打包或发布。


## 2026-09-19｜卡牌：布阵

- 规则真源见[卡牌设计](../design/cards.md)。新增 formation_cases／formation_ui_cases，经 card_power 分类运行；覆盖双面2费、严密度 OR／边界与原子拒绝、打出即用、双面叠加、0费与不判施法的魔法面、失败留牌消耗、基础动作排除、施法部位保护、复放不占次数、回合刷新、存读档与损坏计数拒绝、本场清理，以及真实翻面／点击／费用与状态刷新和英文展示。
- 独立只读审查 review_formation：发现 UI 测试误读魔法候选 casting（实际契约为手牌 face_casting），已修正并复核；未发现剩余规则缺陷。仅修测试读取，不给候选另加字段。
- 首轮 20260919T111053903-632 被并行交感形态注册未完成造成的脚本错误中断；20260919T111616952-39440 的卡牌、图鉴、施法、奖励分类通过，但新增英文动态模板误用 printf 占位符导致本地化拒绝，现已统一为 {p0}。
- 20260919T111754728-48336：4040 项规则及337项窗口断言通过；20260919T112125875-47640：4042 项规则及337项窗口断言通过。两轮均因并行源码／遗物用例更新导致 status=source_changed，不作为最终冻结验证。原选范围全部重跑，最终结果另记下条。
- 重跑20260919T112138818-6764：同范围规则3950项、窗口573项再次全部通过；status仍为source_changed（716C9FC9…→682E79AF…），不宣称当前整体门禁通过。之后工作区另有遗物及资源改动持续写入，交付本任务源码并保留该验证限制；未打包、未发布、未做安卓真机验证。最终本任务差异检查通过。
- 最后一轮 20260919T112448568-48172：localization、card_power、encyclopedia、casting、rewards 全部通过，共4042项规则断言，card_power窗口337项通过。但并行任务在检查期间继续修改 core/card_effects.gd、遗物规则、测试与翻译生成脚本，summary.status仍为source_changed；不能宣称当前工作区已取得冻结通过。本任务源码与文案已实现，最终冻结检查仍受并行写入阻碍。git diff --check通过；没有打包、提交或发布，也没有做全项目／安卓真机验收。
- 随后发现新减耗遗物与全魔力支付的实际交互冲突：face_mana恢复全额支付的提前返回，其他牌继续使用通用减耗。新增两角色两面的智力斗篷反例（80不能减为79），独立审查确认该检查具有敏感性。已针对该新变化再次启动原选验证范围，最终结论以下一条记录为准。
- 最后运行20260919T112843012-712：规则3954项、card_power与basic_attacks窗口573项，共4527项断言全部通过。执行期间另有遗物、监狱及英文目录更新，status=source_changed（B531E63E…→82C3C46E…）；当前整体门禁没有稳定通过，不能用该轮宣称冻结源码全绿。最终复核全额支付守卫仍在，本任务功能、台词、候选与真实输入用例均已落地；未打包、推送或发布。后续合并验收需在并行编辑结束后重跑上述原选范围。

## 2026-09-19｜遗物：护腕、怨灵系带、空灵挂件、智力斗篷

- 最终规则见[遗物表](../design/game-design.md)。新增4件普通遗物与原创SVG、中文／英文说明；护腕最终仅动态加力量，怨灵系带复用灵巧modifier，挂件复用整备回合结束与恢复钩子。斗篷复用collectible件数、普通池补位和Cards.face_mana统一费用；牢门解锁也接入相同入口。“耗尽全部魔力”牌按用户确认保持原规则。
- 20260919T112055705-48424首次检查localization164项通过；新护腕夹具误用了不存在的查询接口而中止。随后夹具经检查发现默认同层会替换且挣扎按紧度顺序并有波及，改用真实不同层与滑脱逐件解除，未改正式覆盖／解除规则。新增补位替代原滚木后，原测试中的“三份滚木”与“空池总是滚木”期望同步为分品质结果，未删失败案例。
- 20260919T112744807-31060的localization164项通过。20260919T113233955-48640：basic_attacks181、content580、casting584、prison1295通过；遗物夹具最后1项失败，修正逐层解除行动后仅重跑失败与未执行范围。
- 最终20260919T113418379-14836：relics1089、status窗口66项通过，exit0、summary.status=passed、源码指纹前后一致。窗口验证四个专用图标与悬停文案。规则覆盖手腕自由／前臂反例、复合覆盖、多件不叠加、正式逐件解除、普通及魔法与被动滑脱、每个整备回合／最后回合／提前结束／魔力上限、所有卡牌两面费用、零费、基本行动反例、正式混合付款、折后9魔力牢门开锁、重复补位、套娃领取、存档恢复与非法件数／过期提交原子拒绝。
- 独立只读审查review_wrist_ribbon发现牢门牌费旁路和套娃文档旧补位句，均已修复并复核通过。git diff --check通过。未新增运行时校验入口，扩展既有collectible契约由正例与不支持的叠加数值反例覆盖。
- 验证范围为上述相关分类与日常随机样本，未跑全项目回归、安卓真机或打包检查。仅源码、图标及文档修改，未提交、推送、打包或发布；保留同仓并行修改。


## 2026-09-19｜无尽魔法少女战神文案精简

- 本次仅修改两面正文、现有详情 note 及两条英文；嘴部条件沿原条件栏显示，不改玩法、字体或布局。
- 20260919T113041749-5992 与按原范围复跑的 20260919T113314392-31748：localization 均164项通过，card_power 窗口均337项通过。两轮均因并行源码写入被标记 source_changed，不作为冻结工作区门禁通过；未新增或删除测试。
- 独立只读审查 Boyle 核对条件栏、note 悬浮入口、双面条件与翻译一致，未发现本次实质问题。未对其他在途内容作审查，不宣称所有卡面无滚动或安卓真机验收。
- 仅源码文案变更，未打包、提交或发布。


## 2026-09-19｜行动日志并入菜单

- 本次入口、展示与只读契约见[界面契约](../spec/release-interface.md#行动日志)。菜单／L 共用 show_log，支持返回菜单、关闭、原行动结果与折叠详细记录；删除旧侧栏状态与引用，教程及两份教学同步。
- 20260919T114105607-48236：localization164、exploration43、keyboard87通过；wall仍引用被移除侧栏的旧布局断言而中断，已改成新默认无日志遮挡契约。续跑20260919T114225401-29780保留wall工具布局与可达部位文案两项失败。20260919T114308611-15104被并行新增great_wand.svg未导入中断，使用普通Import后按原范围全部复跑。
- 20260919T114424968-16364：localization164通过；UI共1032断言，exploration43、keyboard87、services257、targeting107、action_copy35、guard87均通过。直接覆盖菜单交接／返回、L双向开关、详细记录最新正文、遮罩不触发背后攻击、日志费用与行动结果、监狱嘴部操作及整备回合记录、关闭后真实目标点击／拖动与场景实例保持。
- 未通过：wall58项中工具位置与可达部位文案2项；interface358项中角色2部分卡图缺失、卡组窗口外侧点击／后续关闭、教程书按钮布局4项。未删除这些失败，未将综合检查宣称通过。工作区存在其他并行写入，本轮status=source_changed，不作为冻结版本或全项目回归；本任务不扩展修复这些未改动的界面职责。
- 独立只读审查Copernicus指出教程旧固定日志提示与现行契约旧接口引用，已全部修复并复核通过；原详细日志只检查展开可见，现补核最新正文。最终diff检查通过。仅源码及说明，未提交、打包、发布或安卓真机验收。

## 2026-09-19｜商店：会员卡

- 复用shop_only/shop_payment注册与遗物获取池，新增统一discounted_price读取shop_discount_percent；库存始终保留原价，商品候选与投影、删牌报价与日志、解除服务报价与结算均由该入口计算。规则真源见 [游戏设计§9.2](../design/game-design.md)。
- 覆盖自然种子生成会员卡、非商店池排除、原价90及仅自身付款、临时魔力不可混付、旧版本回滚、购得后即刻五折、三类商品仍可魔瓶付款、服务与递增删牌价、0.01不足边界、小数报价、读档不复折及真实鼠标购买。补齐专属SVG与中英文完整报价。
- 首轮20260919T114834050-32312：8项失败，1项为测试保存事务前room引用导致重复选择已售会员卡，7项为旧测试未适配当前普通池空缺由智力斗篷补位；修正夹具读取与现行补位断言，保留来源排除与普通遗物唯一性检查。
- 20260919T115131387-47144：localization164、architecture479、shop_release113、services569、rewards839，共2164项；services窗口262项，exit0/status=passed，前后指纹152525D5989BC565B4FD631014E7EB2D63EFA45BF123F40371ED089DD2B5F420一致。
- 独立只读审查review_membership未发现运行时阻断，指出购买后库存断言需读取提交后的room及英文后缀不足以覆盖完整报价。已修正：补真实库存引用及0.01边界后，20260919T115345252-45300 services570项稳定通过（5D24F6D7902D711773DDD9670A380C3ED9597E0D7D1366FC88602543F915D204）；再补四种完整报价模板及实际报价翻译断言。
- 最后20260919T115746717-2144：localization164、services597，761项中会员卡相关用例全部通过；综合分类尚有1项SCANNER malformed pending records reject without changing state失败，来自并行新增tests/universal_scanner_cases.gd。未删除或绕过该失败，不宣称当前整体门禁全绿。新增另一个商店罕见遗物后，M当劳定向品质测试改为明确排除其他商店候选，来源及品质规则保持不变。
- 仅源码与文档修改，未打包、推送或发布，未做安卓真机验证。保留其他任务修改。
- 英文复查进一步覆盖真实service.release_job_detail（说明＋换行＋报价），补齐四种完整详情模板，并通过普通件、带锁复合件及22.50魔力实际字符串断言。最终20260919T120045393-48848：localization164＋services601＝765项全部通过，status=passed/exit0，前后9D1F240223E1CDFEF2B6CB96B1FD7843292D00C9FD35D81F347A128FC67E8CC9一致；并行扫描全能王用例已在该次检查前修复。之前商店窗口262项及其余规则域的运行结果保留，未额外重复未受本轮英文修改影响的范围。git diff --check通过。

## 2026-09-19｜罕见遗物日晷

- 最终规则见[遗物表](../design/game-design.md)，参考[Slay the Spire 1 Sundial](https://slaythespire.wiki.gg/wiki/Sundial)。用户明确确认复刻空洗牌计数。唯一洗牌钩子在Game._shuffle的draw_cycle通道；_draw完成部分抽取后，若仍需抽牌而两堆已空，执行末尾空洗并立即退出。空洗不推进随机、不播放虚假牌背回洗动画；开场建立牌堆不触发。现有relic_counters持久化0—2余数，原遗物视图显示计数。
- 新增规则用例覆盖第1／2／3次与实际加能量、空抽牌堆单弃牌抽2及超抽8（总计两次）、末尾空洗触发奖励、起始空堆／抽0张／满手牌不计数、抽满手后不空洗、正常抽牌不计数、初始洗牌不计数、跨战斗与快照保留、非法计数原子拒绝、查询不推进随机以及正式抽2牌提交与旧版本拒绝。初版满手夹具误以为初始牌组足够填10张，改为通过原卡牌工厂补齐实际满手，未改正式手牌上限或删除断言。
- 20260919T115856588-44056：localization164、card_expansion1177、relics1155、content580，共3076项规则断言通过。status窗口92项中日晷相关断言通过，仍有并行开发大魔棒的右键兑换／后续计数共3项失败；该轮source_changed，不能宣称冻结源码整组门禁通过。更早一次被同仓新SVG尚未落盘／导入导致编译中断，随后正式导入后解除。
- 日晷首次悬停失败定位到HeroSpeechGroup内部HBox挡住遗物条；角色和NPC对白完成构建后复用_ignore_mouse递归穿透。仅父节点设IGNORE不足以让子控件穿透。并行任务重复添加的相同调用已合为一次。
- 最终针对日晷的补充真实窗口探针：build/sundial-ui-probe.gd继承现有ui_smoke，仅调用原tests/sundial_ui_cases.gd，不复制断言、不修改套件注册、不掩盖整组失败；build/sundial-ui-probe.log记录exit0、4项通过。覆盖原生点击抽2牌、能量与计数刷新、实际悬停说明及英文动态数字。此为日晷局部证据，不等同status整组通过；临时入口在记录后删除。
- 独立只读审查review_sundial：准入、抽牌循环、能量时序、持久化、显示及真实用例无阻断问题；发现空洗多余动画并已修复、对白子树穿透复核合理。git diff --check通过。
- 范围仅上述相关分类与日晷局部窗口探针；未做完整回归、截图、安卓真机、打包或发布，未提交／推送。保留同仓其他任务修改。


## 2026-09-19｜扫描全能王

- 规则与入口见[遗物表](../design/game-design.md#101-遗物表)。商店限定罕见，拾取后通过现有RelicBundle选择永久卡组实体牌，复用奖励资格排除双面唯一能力牌；扩展原_gain_card写入，UID重新分配，永久进度保留，本场成长不复制。界面复用DeckBrowser，不另建卡组列表或规则写入。
- 最终20260919T120155628-15544：localization164、architecture479、services606、persistence955、rewards839，共3043规则断言通过；services窗口272项通过，summary.status=passed，退出码0。不是全项目回归。
- 直接覆盖自然商店货位与其他奖励池排除、65魔力支付、支付不足／过期版本回滚、等待期间阻断其他商店交易、双面唯一排除与其他能力允许、同型不同UID、复制一次性、重复拾取拒绝、永久练习进度与临时伤害成长边界、空／全不合格卡组跳过、原始快照恢复后完成及拒绝重放。真实SaveStore.write_game/read_slot证明正常续玩仍保存商店场景起点，不宣称自动保存购物中途。UI实际购买／翻面／搜索及恢复候选映射／长列表末行点击／全不合格跳过均通过。
- 首轮20260919T115722564-16692中本次损坏快照测试错误地用载入前version作基线，改为恢复后取快照；同期会员卡英文与M当劳池隔离断言失败由其他在途任务修正。随后services599与窗口268通过；20260919T115945277-23784的3036规则及268窗口断言通过但source_changed，未作为最终冻结证据。增加审查要求的边界后取得上列最终通过。
- 独立只读审查Dalton：无复制逻辑缺陷；指出“待选择状态随存档保留”超出固定点保存能力，已收紧设计文档并增加真实Store证据；补齐末行、筛选恢复及无合法牌UI和恢复后实际复制，复核无遗留。最终diff检查通过，图鉴、SVG及英文同步。只改源码，未提交、打包或发布。
## 2026-09-19｜罕见遗物：大魔棒

- 规则真源见[遗物表](../design/game-design.md)。复用成功出牌记录、relic_counters、正式候选与既有动态图标；满点及右键统一结算，不新增独立存档状态。
- 规则覆盖技能逐次计数、0费计数、魔法／能力／复放反例、14至15自动兑换、手动兑换不推进回合、满魔上限、跨回合／战斗清理／存读档保留、非法点数与过期提交原子拒绝。战斗边界检查使用既有 begin_combat/end_combat 接口，不冒充完整通关回归。
- 窗口覆盖实际点击技能、真实鼠标右键兑换、0／1／14计数更新及第15张自动归零、中英文动态值。发现并修复 ActionIndex 按 group 查找的接线错误；对白只读子树改为不截获鼠标，实际遗物中心命中测试验证悬浮可达，同时保留对白位置、期限及全局左键关闭验证。
- 调试期间保留并修正新增测试的空候选判断与UI夹具调用错误、补齐文案路由分类；滚木商店夹具持有并行新增会员卡，付款检查改为正式候选报价，折扣数值由会员卡专项用例覆盖。并行日晷夹具失败及新资源待导入曾阻断综合检查，未删除失败案例。
- 20260919T120103926-46688：规则1798、窗口127项通过，但源码有并行写入，status=source_changed。按原范围完整复跑20260919T120226471-48376：localization／relics／architecture共1798项，action_copy／status窗口共127项，exit0、status=passed、前后源码指纹一致。
- 独立只读审查 review_great_wand 复核结算／候选／存档契约及最终输入接线，指出并修正旧对白测试未命中遗物的问题；最终无待修项。未运行全项目回归或安卓真机检查；仅源码、图标与文档，未打包、提交或发布。

## 2026-09-19｜余烬护符说明精简

- `TYPES.ember.detail` 删除“休息结束不触发。”，保留“战后整备结束时，恢复10魔力。”；同步英文兼容目录、源文哈希及生成器人工词表。沿原遗物说明→显示层→本地化目录调用，`battle_mana=10.0`与触发规则不变。
- `20260919T123021740-34700`：localization 164项通过，exit0；本次三处文件 diff --check 通过。独立只读审查 review_ember_copy 核对源文、译文、哈希及原数值，无待修项。仅文案源码，未运行窗口／全量回归，未打包或发布。

## 2026-09-19｜百变怪（商店遗物）

- 范围：逐来源形态解析、重复数值与触发、独立计数／手动兑换、角色筛选、四类场次生命周期、奖励冻结及存档恢复、商店购买与界面图标。
- 初跑 `20260919T122929344-8044`：relics 1360断言通过；扩展检查发现放大镜奖励快照误读当前实例，已修复。独立审查补查旧形态冻结奖励与角色2开战阶段，均已修复并加入用例。
- 修复后专项：临时探针复用正式测试助手及 `tests/ditto_cases.gd`，121断言／0失败／0引擎错误；与 `first_turn_control_cases.gd` 连续合跑240断言／0失败。临时探针位于忽略的build目录，不进入发行包。
- 最后扩展 `20260919T123611226-19580`：6712断言，witch_character、localization、architecture、casting、services、persistence、rewards分类通过；relics中接管胜利中断1项失败，pressure中无尽魔法少女战神固定费用旧断言8项失败。另有并行源码变动，状态source_changed；不计作冻结工作区通过，不宣称全量回归。接管单独119断言及与百变怪合跑240断言均通过，整组顺序问题未在本任务扩大修复。
- 界面 `20260919T123755721-37696`：services 277断言通过，包含自然商店购买65魔力、等待下场变形、双图标独立计数、原生右键仅兑换百变怪进度；无截图验收或安卓真机结论。
- 独立只读审查 Bohr：修复后三项问题关闭，未发现新的具体遗漏；监狱反抗／返牢房为静态调用链复核，动态结论以上述测试为准。
- 仅源码与资源；未提交、打包或发布。

## 2026-09-19｜左栏完整立绘查看

- 本次范围：BodySidebar 放大按钮／整栏布局／原立绘复用；main 与 TouchInput 共用展示态输入；KeyboardInput.clear 的可选按键清理。测试仍登记在 body_layout，不新增平行规则入口。
- 覆盖真实鼠标开启、栏内保持、点击结束回合位置只收起、原始触屏按下收起、不透明底色和魔瓶层级、刷新复用节点、矩形还原、新局重置、长按结束回合取消及按键恢复、缩放布局触屏，以及全程玩法快照不变。实际截图 ui-portrait-zoom-button.png / ui-portrait-expanded.png 已检查。
- 初次运行修复了新增本地化调用缺少 fallback 的脚本错误。20260919T122648580-30084 的 body_layout 在并行修改期间出现旧出牌／解除／敌方施加用例失败及空数组脚本错误，状态 source_changed，保留失败。复跑 20260919T123055808-49128：body_layout 165 项、exit0、status=passed。
- 截图发现原窗口底色半透明后增加不透明背景并补缩放触屏覆盖。20260919T123354798-50004：touch 23、keyboard 87、body_layout 169，共279项均通过；因并行源码变化，最终 source_changed、exit1，不视为冻结版本通过。按同一范围复跑 20260919T123606558-50880：touch 的蓄力长按切换用例失败，keyboard/body_layout 未继续，且再次 source_changed；未删除或绕过此失败。
- 最终补充验证直接调用同一 portrait_zoom 测试函数，复用 ui_smoke 的隔离主界面和真实输入助手，18项全部通过、exit0；记录 build/portrait-zoom-probe.log。该补充只证明本次交互，不替代整组门禁。临时调用脚本已清理。
- 独立只读子代理 review_portrait_zoom 发现并修复按键释放被吞导致待执行长按残留；同时修正触屏桥接优先消费的接线。最终复核（含不透明底色）无待修项。git diff --check 通过。未跑全项目回归、安卓真机或打包发布。

- 2026-09-19｜百变怪说明小改：玩家可见的“每次类战斗开始时”改为“战斗开始时”，同步英文目录与源文本哈希；JSON解析及限定文件diff检查通过。仅文案，触发规则未修改，未重跑战斗回归或打包。

## 2026-09-19｜乳头移动到性器区域

- `ReleaseView.REGIONS` 将稳定部位 `special_1` 从手胸移动到性器；装备、候选、容量与数值定义不变，身体栏和快捷解除继续读取同一只读区域投影。
- `20260919T124409680-16564`：UI `basic_attacks`、`special_equipment`、`body_layout` 共464项通过；实际乳夹断言覆盖区域成员、物理目标唯一归属及点击乳头展开性器区域。
- 限定文件 `git diff --check` 通过。仅源码、测试和现行界面契约；未打包或发布。

## 2026-09-19｜Boss遗物：抖M印记、豆包／DeepSeek

- 最终 `20260919T124714865-49300`：localization164、relics1405、architecture479、persistence955、prison1295、pressure1117，共5415规则断言；status窗口110项通过。exit0、summary.status=passed，前后源码指纹一致：`AFC4D8E959333DB454D659781371B6C4748671358D6D967E56BF6AFAAB24D68B`。非全项目回归，未进行安卓真机验收。
- 新规则覆盖两角色及战斗／整备／休息／监狱的首回合、后续回合不再接管、类战斗全程禁止切换、非类战斗双向切换、普通end及结束效果、两遗物同时持有的敌人先手打断、给定动作次序、新抽牌继续使用、可选步骤的不执行分支、魔瓶次数不可绕过、胜利立即停止且不领战利品、禁用end时归还操作权且不自动投降、预览不推进随机、原始快照恢复下一步一致、损坏快照拒绝与事务失败后资源及随机进度回滚。
- 窗口使用真实鼠标右键：通过正式奖励／整备命令回到地图后切换豆包与蓝鲸图标，验证战斗首回合过后仍拒绝切换；实际定时提交DeepSeek的end并触发冰心诀，豆包多步行动未卡在手动选靶。规则顺序夹具提高敌人血量，非正常数值通关证明。原始快照证据不扩展为接管中途自动存档；正式存档仍遵循场景起点规则。
- 调试记录：首轮修正新增夹具构造参数与监狱初始化；文案类别列表补齐两条新入口。旧pressure全牌固定耗魔断言未适配无尽魔法少女战神的全部魔力消耗，经并行任务适配后保留全牌覆盖。`20260919T123659213-20560` 与 `20260919T124247249-17060` 为source_changed，未作为最终通过；后者的窗口夹具在奖励遮罩后右键无法命中，改为真正回到地图再测试，未放开模态穿透。新范围均已完整复跑至上列冻结通过。
- 独立只读审查 `review_first_turn_control` 先后复核初始实现、最终阶段禁切规则与分行中英文描述，以及并行遗物接口变更；未发现必须修复项，建议的敌人先手中断组合已补证。最终差异检查通过。只改源码、图标及文档，未提交、打包或发布。

## 2026-09-19｜普通技能：鲤鱼打挺

- 规则真源见[卡牌定义](../design/cards.md)。总力量由既有RelicEffects.attribute读取，双面实际费用统一经Cards.energy_cost；保留沿用CARD_TRAITS，腿部姿态忽略沿用next_attack效果与统一攻击消耗。普通姿态行动和卡牌变站共用Game.change_posture，姿态风险从正式牌面字段派生。
- 新增规则用例覆盖力量0／3／4／5的双面候选、临时与遗物力量、保留、非躺姿拒绝、0能量站起、过期回滚、姿态时机风险与实际一次触发、坐姿／躺姿全部腿部体术形态、多段及全体一次消耗、手部／法术反例、拘束／捕缚／冷却／次数／付款限制、绑脚踢击原有击后躺下、存档与既有next_attack跨回合／跨战保留。UI覆盖真实翻面、点击站起、动态费用、状态出现与真实拖放腿攻后消失，中英文及专用SVG。
- 20260919T123043937-47648首次2089项中1项新测试失败：误以为next_attack战后清除；核对既有end_powers后修正为原跨战保留语义，不改清理规则。20260919T123341232-49756规则2089项通过，UI346项中2项新夹具失败：render初始化draw_serial覆盖预设牌面，改为真实右键翻面；未修改生产默认牌面逻辑。
- 20260919T123827109-30156规则3208项中旧pressure分类8项失败：旧固定耗魔断言未涵盖已有all_mana_minimum卡；补按声明全额耗魔预期，仍逐压力逐面断言，阈值及实付由既有战神专项覆盖。20260919T124028680-49444规则3208项通过，UI仅余火抽牌断言失败且源码变化；没有删除或放宽余火断言。
- 最后两轮20260919T124408366-2252、20260919T124742685-26436均为localization164、card_expansion1267、basic_attacks181、architecture479、pressure1117，共3208项通过；card_power窗口346项全部通过。两轮均被其他任务并行写入标记source_changed／exit1，不能作为冻结工作区门禁通过；本任务未宣称全项目回归通过。
- 独立只读审查review_kip_up复核费用、候选、姿态写入、攻击消耗、复放及存档接口；按建议澄清击后躺下并补用例，复核无待修问题。最终git diff --check通过。未做安卓真机验证，未提交、推送、打包或发布，保留全部其他在途修改。

## 2026-09-19｜漂浮口球与漂浮锁同场唯一

- 初跑 `20260919T125029451-49084`：`enemies -Exhaustive` 4307断言通过。独立只读审查 Sartre 未发现算法或现有生产组合路径缺陷，建议补齐严格候选非空但预算不足的放宽分支；用口球＋玩具箱受限池补证后，复审确认覆盖缺口闭合。
- 最终 `20260919T125230660-47616`：同范围4309断言通过，exit0、status=passed；敌人循环16／16种子、出场池24／24种子。覆盖正常弱怪与强组合真实入场、全部类型可达、其他类型重复、唯一类型不足时无部分名单／随机推进、口球与锁混合、既有保存恢复路径及候选放宽边界。
- 变更域：`Enemies.TYPES` 两项出场标记、`FirstFloor.can_fill/roll` 的统一唯一类型判定及预算补齐；已冻结的旧房间保持名单。相关文件diff检查通过，未运行全项目回归或打包发布。

## 2026-09-19｜豆包描述精简

仅修改豆包说明及对应英文目录／生成器。定向读取常量并解析JSON、Python AST，确认豆包三行内容不含行动顺序、随机省略说明或DeepSeek效果，英文对应文本与哈希ID一致，DeepSeek自己的说明保留。图鉴与悬浮提示均沿现有同一文本来源；git diff --check通过。独立只读审查 review_doubao_copy_trim 无问题。纯文案改动，未新增测试或重跑游戏回归，未打包发布。

## 2026-09-19｜布阵叠加说明精简

- 布阵两面卡面及状态详情删除每层增张／减费的重复解释，共用说明保留两面可同时生效。对应五条英文、源文哈希及人工词表同步；叠加与效果规则不变。
- 静态核对及独立只读审查 `review_formation_copy` 通过，四个文案文件 `git diff --check` 通过。
- `localization` 两次运行（`20260919T125848881-11228`、`20260919T125945273-50872`）均因 `core/game.gd`／`core/card_effects.gd` 解析依赖错误阻断，42／164断言通过，不能记作门禁通过；首次另有源码并发变化标记。本批未修改这两个核心文件，未运行全量回归，未打包发布。

## 2026-09-19｜魔路精通门槛与共鸣数值

- 范围：`card_power,casting,localization` 规则及 `card_power` 窗口。最初 `20260919T130322789-49496` 的2724项中7项新夹具失败；修正颈圈不计普通件数及复合安装紧度后，`20260919T130427223-16920` 余4项失败。按真实提交会替换状态这一契约，改为通过ID重新取得当前装备后调整紧度，未放宽规则断言。
- `20260919T130502798-7032`：规则2724项全部通过（能力1974、施法586、本地化164）。窗口354项完成，仅其他在途 `binding_search_ui_cases` 的英文名称／动态文案断言失败，本次 `reuse` 与 `resonance` 窗口断言通过。运行期间源码变化，整轮 `source_changed/exit1`，不记作冻结门禁通过。
- 按相同范围复跑 `20260919T130747262-18132`：规则2724项再次全部通过，窗口354项仍仅上述范围外英文断言失败。本轮窗口被最小化、等待实际绘制，恢复后正常完成；并行源码仍有变化，最终 `source_changed/exit1`。不将两轮采样宣称为冻结工作区或完整回归通过。
- 覆盖实际激活的两区域门槛、真实失败施法的支付与0费次数、9／10件、紧度1／2边界、特殊排除、复合计1、动态降级不刷新次数及保存恢复；共鸣两份能力每回合获得4闪避，连续回合累积到8。独立只读审查 Leibniz 确认本次接口无阻塞问题。
- 未运行全项目回归或安卓真机验证，未打包发布。

## 2026-09-19｜共鸣自由面费用澄清

- 用户澄清后，自由面为2费、每份每回合1层闪避，前次共鸣数值结论由本条取代。`20260919T131916600-20016`：`card_power` 1978项、`localization` 164项，共2142断言通过；exit0、status=passed、源码前后指纹一致。
- 复用 `card_power_ui_cases.resonance` 的临时原生窗口探针8项通过、exit0，覆盖自由面2费角标、说明1层闪避、两次真实扣费及下回合合计2层闪避。不是完整窗口分类或全项目回归。首次探针因其他在途豆包PNG尚未导入，0项断言并解析失败；标准资源导入完成后通过。
- 新规则断言覆盖1能量拒绝无部分支付、2能量足额支付、旧版本回滚、两份共鸣连续回合2→4。独立只读审查 Mendel 无阻塞问题；定向diff检查通过。仅源码、测试与文档，未打包发布。

## 2026-09-19｜紧缚检索

- 规则覆盖双面费用/类型/无部位施法、X=0至6的下取整边界、身体栏分组合并、单侧手部、跨部位复合装备、肩带双侧/单侧/全解除、特殊装备排除、随机结果可复现、主动佩戴不消耗闪避、满位置拒绝、预览不推进随机、过期/不足魔力原子拒绝、施法失败不佩戴不抽牌、拘束面按原规则复放且只支付一次。原自缚继续调用同一选项/安装接口。
- 调试失败已保留：首次导入发现 resolve 中局部 effects 重名，已改名；初版中文语义资源缺 context、测试 _install_special 漏槽位参数均已修正。自由面复放测试不符合既有规则，按契约改为拘束面复放；肩带计数发现 equipment_at 不含零容量肩带，改用既有 targets_at("shoulder") 并补边界。新肩带夹具改用合法等级最大耐久。
- 20260919T130825281-48972：localization 164、card_expansion 1315、casting 586，合计2065项；exit0、status=passed，源码前后指纹一致。20260919T130322256-48860 的 card_power 规则组另有7项 MASTERY/魔路精通失败；此前在途修改中还出现旧共鸣用例失败，没有删除或替换这些用例，不能据局部通过宣称整个能力规则组通过。
- 20260919T130448440-49240 的 card_power 窗口组首次仅新英文动态文案用例失败；已按实际 card_info→localization.display 的原兼容路径补齐源文哈希与 MANUAL 生成器映射，移除未接线的临时语义条目。20260919T130937820-50604：card_power UI 355项全部通过，exit0、status=passed、源码指纹一致；包括本牌真实翻面/点击提交、装备后实时卡面更新和英文数值。ui-binding-search.png 已人工查看，卡图/稀有度/能量/魔力/动态抽数显示正常。
- 独立只读审查 review_binding_search 已复核上述计数及复放修正，未发现其他待修问题，并核对2065项规则门禁摘要。git diff --check 通过。未运行全项目回归、安卓真机验证或打包发布。

## 2026-09-19｜罕见遗物：破铜烂铁机器人

- 规则真源见[遗物表](../design/game-design.md)。覆盖机械无人机／拘束箱的单段、多段、混合群攻、主角与小魔女预览和真实提交；魔法／固定伤害与非机械目标反例、百变怪复制及同效果并存、读取不修改状态、过期提交回滚、获取池、存档恢复与坚硬状态文案。
- 初轮新夹具失败：持有遗物后测试重复奖励、追加敌人未生成公开行动、小魔女预备不足4层。已按现行契约修正夹具，保留有效断言。20260919T133232070-49768 六类规则4707项通过，但UI被同期卡牌接口缺参阻断，且source_changed；该接口已由其他任务修复，本任务未修改。
- 20260919T133502099-29624：witch_character459、localization164、relics1464、basic_attacks181、architecture479、enemies1962，共4709项规则通过，前后源码指纹一致。UI因其他新卡图尚未导入而0断言失败；规则通过不等同整轮通过。敌人随机验证采用日常4种子，非全矩阵。
- 标准资源导入后，20260919T133645655-29572 的status窗口127项全部通过，包含本遗物图标、悬停、动态坚硬状态、真实拖放攻击及英文。运行期间其他源码变化，整轮source_changed，不能称为冻结工作区门禁通过。
- 独立只读审查review_scrap_robot复核统一倍率入口、所有调用点、存档及复制接口；夹具修正后复审无待修问题。未运行全项目回归或安卓真机验证，未提交、推送、打包或发布。
- 原窗口范围再次运行20260919T133847185-44128：status127项再次全部通过，但仍因并行源码写入记为source_changed／exit1。两次窗口采样通过，不宣称最新整体工作区冻结验收通过；交付时git diff --check通过。

## 2026-09-19｜高潮损失一半蓄力

- `20260919T134616688-20256`：localization164、card_power1988、architecture479、special_equipment351、pressure1182，共4164断言通过，exit0、status=passed、源码前后指纹一致。
- 新增用例覆盖0／1／2／3／5／8层、普通／全量模式、阈值前后、同批多次与同回合再次触发、整备／休息／牢房／事件、脚本触发、滑精延迟魔力变体、存档恢复不重复扣除、只读查询与过期提交；真实高潮练习出牌确认先获得1层，再从8层减至4层。未替换既有有效失败断言。
- 本次仅规则和文字变更；未运行窗口专项、全项目回归或安卓真机验证，未提交、推送、打包或发布。
- 最终文案复核发现减半说明误挂临时魔力，已移至蓄力状态；英文三条重写为准确文本，并补状态归属反例。返工后的 `20260919T134927870-51128`：localization164、card_power1988、architecture479、pressure1183通过，special_equipment356项中仅 `catalog_and_projection` 的 `TYPES.size()==39 && DESIGNS.size()==TYPES.size()` 目录断言失败。合计4170项中1项失败，exit1、源码指纹一致；本任务未改装备目录或该数量断言，不将整轮称为通过。
- 独立只读审查review_overload_charge确认机制入口、逐次取整、全量模式和修正后的文案归属无剩余问题。最终git diff --check通过。先前4164项结果保留为返工前记录，最终口径以上一条为准。
## 2026-09-19：魔力附着（规则／支付／状态开关）

- 实现范围：`mana_attachment` 双面魔法能力；激活与施法失败、体术群攻／减半／固定追加付款及不足回退、成功技能追加付款、复放隔离、临时魔力优先、独立开关与同面唯一、读档及能力清理。界面走现有翻面、出牌、状态右键正式提交；附卡图与英文。
- 分类运行 `build/checks/20260919T134952694-9648/`：`localization` 164、`card_expansion` 1387、`casting` 587（合计2138）和 `card_power` UI 366断言全部通过，失败与未运行分类为空。期间其它任务继续修改共享源码，`summary.status=source_changed`、退出1；此结果不记作冻结版本通过，未宣称完整回归。
- 最终定向复核复用上述分类里的原测试函数：`mana_attachment_cases.run` 71断言／0失败／0引擎错误，`mana_attachment_ui_cases.run` 11断言通过（真实鼠标翻面、双面打出、右键关闭／重开、技能耗魔蓄力、缺魔回退、英文）。日志 `build/attachment-final-rules.log`、`build/attachment-final-ui.log`；执行前后11个点名文件（规则、支付、状态、存档、主界面、卡面与测试）SHA256一致，清单 `build/attachment-final-source.json`，`stable=true`。该短程证据限本卡点名域，不替代整轮冻结验收。
- 新增开关校验仅在 debug 的 `Cards.validate` 单处执行。布尔类型／牌区／增益来源三个反例都被原实现拒绝，恢复损坏快照整包回滚；仅删除该检查块的临时副本对三例均返回成功，敏感性探针5断言通过，见 `build/attachment-sensitivity.log`。重复的 Snapshot 新增检查已撤除。
- 独立只读审查 `review_mana_attachment` 完成；指出的校验敏感性与 debug 路径缺口已修复并复审通过。截图 `build/ui-mana-attachment.png` 已检查；临时探针脚本已清理。`git diff --check` 通过。只改源码与文档，未打包、未发布；不作为安卓真机验收。

## 2026-09-19｜豆包接管表现、DeepSeek零能量首回合与图鉴

- 范围：像素遗物图标、75%不透明度气泡、两套对白、模拟鼠标与输入锁、豆包练习；DeepSeek四阶段首回合能量归零而不跳回合；豆包图鉴内独立列出DeepSeek图标与描述。
- 原工作区 `20260919T134211229-50132`：localization / relics / architecture / encyclopedia / persistence 共3598断言，UI encyclopedia / touch / keyboard / status 共411断言均执行通过；`source_changed`，不作为冻结版本绿灯。
- 隔离源码快照：`G:/CodexData/verification/doubao-20260919-1347`，复制当时工作文件并补入用户最后的半透明背景修改，不覆盖共享工作区。其构成记录在快照根 `verification-source.json`。
- 隔离规则检查 `20260919T134958552-49920`：总3598断言，1项失败 `NOODLES inspection resume does not reopen the session`（既有 `spicy_rice_noodles` 遗物监狱巡视恢复用例，不持有豆包）；其余分类通过。未删除该失败断言，未声称整仓回归通过。沿既有测试助手单独执行 `first_turn_control_cases.gd`：`DOUBAO RULES PASS: 125 assertions`，exit 0。
- 隔离 UI 检查 `20260919T135240984-48548`：encyclopedia172 / touch23 / keyboard87 / status129，共411断言，exit 0、status=passed；before=after=`8360303EB44B380C4EEF8A2CD4D9622961802567992904E8A7FBD35B162607C7`。覆盖真实练习入口、输入锁与解锁、鼠标移动、气泡锚点、DeepSeek手动操作与结束、中途换局取消、同条目双图标描述。
- 检查截图 `ui-doubao-intro.png` / `ui-doubao-cursor.png`：已实际查看像素头像、气泡尺寸、75%不透明度与控件上的点击圈。图片及原始检查日志保留在上述隔离快照 build；源码中不提交测试日志。
- 独立只读审查 `/root/review_doubao_presentation` 完成；发现并修复旧mode1/stage<6记录造成表现与候选不一致的边界，恢复时原子拒绝该非法进度。最新图鉴、输入和透明度补审无新增问题。
- 当前共享工作区仍有其他任务的变更；快照后的原工作区差异未作为完整回归重新验证。未做安卓真机检查，未打包、提交或发布。

## 2026-09-19｜魅魔警卫恢复原版战斗立绘

- 范围：从项目v0.15历史对象逐字节恢复两张原版制服魅魔透明PNG，新增战斗专用`SUCCUBUS_GUARD_PORTRAITS`映射；`guard_purple`／`guard_brown`稳定ID、敌人生成、随机域和存档不变。监狱巡视、收押及出狱继续读取现有`GUARD_PORTRAITS`狱警资源。
- `build/checks/20260919T134139555-18056`完成Godot素材导入；`guard`、`prison`窗口307项（含3张截图保存断言）全部通过。截图`ui-34-guard-intent.png`与`ui-guard-brown-portrait.png`已确认紫／棕原版魅魔，`ui-38-prison-inspection.png`确认监狱仍显示现有紫发狱警。
- 补充双人、增援与收押页纹理对象断言后，`20260919T135307082-50548`的`guard`、`prison`窗口304项全部通过；前一轮`20260919T134806214-33972`同样304项通过。三轮均因共享工作区其他任务持续写入而被检查器标记`source_changed`、退出1；两次额外30／45秒源码指纹观察也未稳定，因此这些结果只证明相关断言通过，不宣称冻结版本门禁通过或完整回归。
- 独立验证快照`G:/CodexData/verification/guard-art-20260919-1400`复制当时完整Godot模块且不覆盖共享工作区。首次新目录导入`20260919T140000978-50164`因字体`.fontdata`缓存尚未生成而失败，保留该失败；按摘要续跑`20260919T140053555-48780`后，`guard`、`prison`窗口304项全部通过，`status=passed`、源码前后指纹均为`D789AA0BD2BFAAC5A1EAD79DE48B88EC4307261B86313D6DDEF4C171ED4CFA32`。该证据对应快照中的本次最终实现，不代替共享工作区其它在途功能的整仓回归。
- 独立只读审查`review_guard_art_restore`确认：单人、双人和监狱反抗增援统一走原版魅魔映射；监狱NPC保持现有紫／棕狱警；历史PNG哈希、原始下载哈希、RGBA尺寸、稳定ID、随机与存档路径一致。审查提出的三处非阻塞测试缺口已补齐。定向`git diff --check`通过。未打包、提交或发布。
## 2026-09-20：耐心耐心～跨敌方行动保护窗口

- 反馈定位：小魔女「耐心耐心～」声明 `duration=turn`，被 `Game._end_turn` 在敌人行动前清除，与现行「直到下回合开始」文案不符。改为 `next_turn_start`，由同一 `Cards.expire_turn_buffs` 入口按开始／结束边界路由；状态投影显示「下回合开始」。无存档字段迁移。
- 新增 `witch_expansion_cases._patience_turn_window`：正式打牌→结束回合→敌人安装拘束→下回合；有／无保护对照、真实安装与预备是否抵挡、下一轮恢复抵挡、读档重放结果、后手下一轮清除时点、本场强制清理。既有释放、高潮保留、自由面能量等测试继续执行。最初用例确认了提前清除；随后将双敌人夹具收敛为正常单敌人 `rope_solo`，避免第二次安装影响单次扣层期望。
- 最终冻结分类验证：`build/checks/20260919T140518347-5988/`，`witch_character` 486、`card_power` 1998、`status` 300，共2784断言通过；退出0、`status=passed`、前后源码指纹一致。`git diff --check` 通过。
- 额外 `localization` 校验在 `build/checks/20260919T140354976-50932/` 失败：英文目录中已有另一任务的临时力量模板 `legacy.h8c3a978e823253c87e969a41` 报 `legacy_parameters`，引起目录加载及后续翻译断言共41项失败；未删除失败案例或改写该文案。本次「下回合开始」英文条目与生成器映射均已添加，但未将整份英文目录宣称为通过。
- 独立只读审查 `review_witch_patience` 无可行动缺陷：核对失效入口、先后手、回合开始装备、旧存档 ID 与本场清理。只改源码／文案／文档，未打包发布；未作 Android 真机或旧版存档文件实测。

## 2026-09-20｜普通技能：拘束就是力量！

- 新专项覆盖佩戴0至9件的双面取整、普通池登记、无施法与1费、实体消耗、动态卡面／图鉴公式、零收益、预览只读、过期与不足能量回滚、两面拘束复放、休息自由效果禁用反例、复合整件与特殊装备计数、获得后装备变化、存档与跨回合资源生命周期。窗口检查接入card_power分类，以真实翻面与点击验证。
- 首轮20260919T140205082-50600共3317项中43项失败：新增英文桥接错误沿用了命名占位符，导致英文目录整体拒绝；统一改为既有p0/p1协议。另一个旧测试把所有self_faces第二面都当自由面，按Rules.free_effect语义更新断言，继续遍历全部牌，并由新卡正例验证休息可用。该轮还有source_changed，未计作通过。
- 独立只读审查review_binding_power无待修问题，建议补专心致志共享双面路径。补跑20260919T140553407-29268的card_growth20项通过，exit0、status=passed、源码指纹一致；未重复执行已完成分类。
- 20260919T140426759-49700：localization165、card_expansion1482、architecture479、pressure1191，共3317规则断言通过；card_power窗口370项全部通过，包括新卡双面真实翻转／点击、支付、进入消耗区及英文动态值。整轮仍因其他源码并行变化记source_changed／exit1，未宣称冻结工作区通过，按原范围再次复跑。

## 2026-09-20｜非战斗动作栏对齐

- 范围：`Main._build_action_rail` 火球术禁用占位，复用原动作栏位置与高度；空原生按钮内独立排版标题、至多两行说明，保留完整提示和禁用行为。
- `20260919T140623943-49312`：basic_attacks 窗口244项断言全部执行通过，但共享源码变化，status=source_changed，不作为冻结通过。
- 重跑 `20260919T140807426-10360`：basic_attacks 窗口244项断言通过，exit 0，status=passed，源码前后指纹一致。覆盖整备／休息／监狱栏位上下边、英文缺能力说明、已解锁但无目标，以及原火球拖拽与深呼吸交互。
- 实际查看 `build/ui-exploration-action-rail.png`：1600×900画面中火球术、深呼吸、切换按钮上下边对齐，说明没有撑出动作栏。未作安卓真机验证。
- 独立只读审查 `/root/review_action_rail_alignment` 未发现缺陷；定向 diff --check 通过。仅源码修改，未打包、提交或发布。
- 最终原范围复跑20260919T140739669-30636：3317项规则＋370项card_power窗口断言全部通过，exit0、status=passed、源码前后指纹一致。专心致志20项补测结果见上；最终git diff --check通过。未运行全项目回归或安卓真机验证，未提交、推送、打包或发布。
## 2026-09-20：预备咏唱自由面延后生效

- 复用 `next_turn_start/on_expire_buff` 接续与统一增益清理入口，不新增计时状态。规则测试覆盖自由面当回合无加成、真实结束回合后启用、所有合法施法路线100%但不绕过部位条件、目标回合末失效、存档恢复、当前／预约共存、重复预约拒绝及本场清理。费用、失败返还、保留与消耗的既有检查保留。
- `build/checks/20260919T141146963-46864/`：`witch_character` 486、`localization` 165、`casting` 601，共1252断言通过；UI `casting` 59断言通过，包含原生翻面、点击出牌、结束回合、预约状态转为生效状态及概率显示。退出0，`status=passed`，前后源码指纹一致。
- 独立只读审查 `review_chant_next_turn` 未发现阻断问题，核对时点、接续顺序、共存、存档与清理。`git diff --check` 通过。未打包发布；不作为安卓真机验收。

## 2026-09-20｜中级马眼全包榨精杯与固定带

- 规则覆盖新增装备规格与监狱杯具开关、四种全包杯三档自动附带同品质固定带、二档不附带、杯体互斥、固定带独立耐久与零容量、普通／魔法滑脱拦截、挣扎直伤杯体、主体替换与解除级联、完整切断后的合法状态、正式卡牌＋已安装工具提交、工具次数、存档恢复、低紧度伪造带与孤立组件拒绝、版本52迁移及字段删除旁路。
- `20260919T141501095-29764`：`persistence` 960项通过，exit0、源码指纹一致。`20260919T141737784-32368`：执行标准资源导入后，`encyclopedia,special_equipment` 窗口232项通过，exit0；覆盖杯体与固定带同栏显示、说明及不误用平板锁立绘／上锁控件。
- `20260919T141821035-30056`：`localization,encyclopedia,content,special_equipment,persistence` 共2691项规则全部通过；运行期间其他在途源码继续变化，检查器最终标记 `source_changed/exit1`，不能称为冻结工作区整轮通过。此前同范围规则 `20260919T141612606-20860` 的2689项也全部通过，但窗口被同期新增且尚未导入的 `supple_flesh.svg` 阻断；导入后的窗口结果以上一条为准。
- 独立只读审查 Confucius 首轮发现真实切割入口、带体切断后校验、低紧度伪造与双杯共存四项缺口；修正后复审又发现缺字段可回落旧校验，改为版本52显式迁移与版本53严格字段。最终复审未发现剩余问题。
- 定向 `git diff --check` 无空白错误；未运行全项目回归、安卓真机、打包或发布。

## 2026-09-20｜豆包整备排除与随机核对

- 结构：`FirstTurnControl._eligible`统一首回合启动与持续接管资格；仅mode0排除prepare。保留原合法候选、独立种子随机与正式dispatch入口；mode1能量清零和四阶段禁止切换均不变。遗物与练习提示及英文同步。
- 导出当前`DoubaoDialogue.LINES`两套台词，共40条，按行动及结果顺序写入本地`outputs/豆包台词-两套差分-2026-09-20.txt`；逐条核对原句与数量，UTF-8 BOM，不提交本地交付文件。
- 共享工作区两轮`20260919T141346035-32076`、`20260919T141553868-27220`：规则1645与status UI130断言均执行通过；前轮包含练习提示补修、后轮受其它任务更新影响，均为source_changed，不视为冻结通过。
- 隔离副本`G:/CodexData/verification/doubao-no-prepare-20260920`：首次`20260919T141830119-51356`因复制期间其它任务新增`supple_flesh_cases.gd`引用而缺失依赖，脚本编译失败；补齐新增测试文件后重跑，未删除失败用例。
- 冻结运行`20260919T141946247-30984`：relics/localization规则1647、status UI130断言通过，exit 0，status=passed，before=after。覆盖真实战斗→领奖→整备手动结束、双角色整备、旧快照接管失效、其余阶段保留、DeepSeek不变；16个固定种子采样验证姿态做／不做与不同合法基础动作，预览不改状态，不称完整随机覆盖。
- 独立只读审查`/root/review_doubao_prepare_exclusion`未发现阻断问题；定向diff --check通过。未作安卓真机验收，未打包、提交或发布。

## 2026-09-20｜罕见技能：活动媚肉

- 专项覆盖零能量双面合法提交、无魔力／施法／消耗、重复叠加与两面共存、实际体术与滑脱伤害、攻击不消耗回合增益层数、状态总属性／层数／到期显示、只读与过期回滚、存档及缺层数原子拒绝、回合结束保留常驻属性、拘束面复放、休息自由面禁用、提前结束整备清理。沿用既有card_buffs/card_buff_uses，无存档字段变更。
- 首轮20260919T141919595-30708：localization165、card_power2008、basic_attacks181、architecture479通过；card_expansion1508项仅新滑脱夹具失败，原因是使用了3档不可滑脱目标。夹具改为高级2档16/20耐久并保留实际伤害断言，未改变规则来绕过限制。首轮exit1、源码指纹一致，未记作整轮通过。
- 续跑20260919T142034571-30816：card_expansion1508项及card_power窗口376项全部通过，覆盖新卡实际翻面／点击、状态出现与回合结束消失、中英文。运行中其他源码变化导致source_changed／exit1，不记作冻结版本通过，随后按最初全部五类规则＋窗口范围重跑。独立只读审查review_supple_flesh确认叠层、属性消费、生命周期和存档边界无待修问题。

## 2026-09-20｜现行内容与旧校验维护

- 范围：只修改 `relic_revision_cases.spicy_rice_noodles`、`special_equipment_cases.catalog_and_projection`、`test_game._core_cases`、`reward_ui_cases.rolling_log` 及本批记录。开工时已有216份在途文件，保留其他任务修改。巡视正式接受时按现行高潮规则验证蓄力2→1，恢复时另验蓄力／场次序号不变、开场反馈不重发；装备目录改为42个具体必需ID与两表键集配对，新增完整配对条目不误报；移除core对小魔女专项的重复调用，486项仍由独立分类与impact路由执行。
- 奖励窗口同步现行普通池智力斗篷／其他品质滚木补位。按冻结掉落ID校验奖励名称及对应徽标增量；真实逐槽购买核验售罄、单图标计数与显示报价扣款，替换旧“全部滚木／总价135”的假设。具体品质补位和最终持有数量继续由既有rolling_log规则用例覆盖。
- 共享工作区基线 `20260919T140751007-30848`：3707项中仅巡视旧蓄力预期失败；`20260919T140837701-49828`：core/card_expansion/card_power共4398项通过，均为当时源码稳定结果。修改后 `20260919T141330594-47172` 的8分类5171项执行通过，但source_changed。补跑 `20260919T141523264-50472` 规则5174项执行通过，窗口425项中4项奖励旧预期失败，整轮仍source_changed；这些移动工作区结果不作为最终冻结通过。
- 稳定验证快照：`G:/CodexData/verification/test-maintenance-20260920-start`。构成是HEAD `00e6327bb49d5226c27b11f282e2507779ac577d`＋开工时捕获的全部在途文件＋本批测试增量，未覆盖共享工作区，后续其他任务修改未纳入。逐文件哈希与构成记录见快照根 `verification-source.json`。正式入口递归可达214个测试脚本，开工内容的所有case均可达、无缺失引用；后续新增的supple_flesh引用曾出现文件尚未齐全的接入中状态，不据本批结果宣称这些后来内容验收完成。
- 快照规则 `20260919T141852873-50032`：witch_character486、localization165、relics1471、architecture479、runner493、special_equipment446、core432、pressure1191，共5163项，exit0、status=passed，before=after=`467D97B85A60C4EB5F077A3509B1EB11F651237F2AB3080FFE97B2124DA531A5`。后续仅修改奖励窗口测试，未改变此规则验证对应的实现与规则用例。
- 快照窗口 `20260919T142155417-50752`：pressure86、rewards342，共428项，exit0、status=passed，before=after=`84CDBEACD2CF7FE541EA3B0568FE897A52E38E87BEBD84ED49846887EDC1E1EF`。覆盖真实领取／购买、快感交互和重复奖励徽标；未生成截图。误启动的旧窗口轮 `20260919T142043279-29616` 在发现尚未应用UI修正后主动终止，不计通过。
- 装备目录敏感性探针：执行原catalog_and_projection，四种独立进程内场景中，原目录与额外完整配对条目通过；等量但错误设计ID只命中配对断言，双表同时删除必需装备只命中必需ID断言。日志与开工差异副本在共享工作区忽略目录 `spire-godot/build/validation-maintenance-20260920/`。
- 独立只读审查 `review_validation_maintenance` 对四个增量均未发现可行动缺陷；最终diff空白检查通过。以上为点名分类和快照的证据，不是当前持续变化工作区的全项目回归；未作安卓真机验证，未提交、推送、打包或发布。
- 原范围复跑20260919T142348851-49396：五类规则4341项全部通过。窗口进程50652被最小化，实际IsIconic返回true；仅恢复该自有窗口后仍超过300秒预算，窗口未完成，整轮同时source_changed／exit1，不能作为整体冻结验收。没有停止其他游戏或测试窗口。
- 最后复用supple_flesh_ui_cases的独立窗口探针（build/supple_flesh_ui_probe.gd，日志build/supple-flesh-ui-probe.log）：7项断言通过，exit0，实际翻面、0费点击、双面状态、结束回合清除及英文均通过；这是新卡专项，不是完整card_power分类通过。最终git diff --check通过。未运行全项目回归或安卓真机验证，未提交、推送、打包或发布。

## 2026-09-20｜DeepSeek像素形象与豆包接管主角气泡

- 用户图片经内置imagegen生成并原样复制为`assets/ui/relics/deepseek.png`，1254×1254 RGBA，透明背景。SHA256=`0A643B5A01179DF76CDE9A1B28FB434D513466B6F01F8C8887D497ABDD97C46C`。`RelicIcon.ART.deepseek`共用映射改为PNG，nearest过滤；素材导入正常。完整生成提示词交付于本地`outputs/deepseek-icon-prompt.txt`。
- 图标专项`20260919T142657395-8784`：Import完成；encyclopedia/status UI303断言通过，exit0、status=passed。实际查看`build/ui-deepseek-pixel-encyclopedia.png`，豆包条目内DeepSeek显示铁盆帽蓝发像素形象，说明保持原效果。
- 主角气泡沿`_submit → _skip_hero_speech → _speech_bubble`表现通道收口：接管期间及最后自动命令标记独立suppressed_hero_speech_id，新局复位，保留日志与豆包气泡；NPC覆盖通用speech_id也不复活旧主角台词。独立审查发现并修复该NPC边界。
- 首轮气泡`20260919T143009690-49520`的action_copy/status UI167断言通过，但新增NPC边界修复后该域重新取证：`20260919T143247442-33656` UI169断言通过，exit0、status=passed，源码前后指纹一致。覆盖真实接管行动产生台词但不弹主角气泡、结束刷新不补弹、NPC投影后返回不补弹、普通手动气泡、DeepSeek手动操作与输入解锁。
- 独立只读审查由未参与实现的`/root/review_doubao_prepare_exclusion`完成；新建审查代理受线程数量上限阻止，使用现有独立审查者的新回合检查本批变更。最终无未解决审查问题；定向diff --check通过。未作安卓真机验收，未打包、提交或发布。

## 2026-09-20｜鲤鱼打挺与捕缚优先级

- 在共用体术姿势查询中优先读取捕缚的强制姿势；预览、招式选择及正式候选沿同一入口。规则见[卡牌设计](../design/cards.md)，中英文详情同步。
- `kip_up_cases.capture_priority` 覆盖先打牌／先捕缚两种顺序、强制坐姿拒绝站姿动作且整份快照不变、合法坐姿攻击、存档恢复、解除捕缚后恢复待用增益、警卫禁止跳级起身，以及无人机固定站姿和禁止击后躺下。旧测试移除手工伪造与捕缚冲突姿势的夹具。
- `20260919T143555498-40876`：localization、card_expansion、basic_attacks、guard 共1967断言通过；exit0，summary.status=passed，before=after。`git diff --check` 通过。未跑整体回归、窗口自动化或安卓真机测试，未打包、提交或发布。
- 独立只读审查 `/root/review_kip_capture` 完成：候选重算与支付、实际执行、捕缚姿态约束、快照恢复及新测试真实性均未发现阻断问题；未重复执行测试。

## 2026-09-20｜架构接口检查与校验入口补强

- 检查域：UI→正式提交、状态迁移单写入者、事件求值与内容入口、装备索引／投影隔离，以及新增首回合接管、双面能力开关。开工229份在途文件保留；本批没有改玩法、数值、生产规则或另立接口。扫描49份UI、48份core与27份data脚本：未发现UI直接访问game.state或反向preload/load依赖；UI的game.dispatch仅有Main._submit一处。此为源码模式扫描，结合既有架构分类取证，不宣称动态调用完全形式化证明。
- 新首回合接管继续由core选择已有合法候选，经隔离View供展示器消费；展示器最终调用原_submit，支付／版本／回滚仍在dispatch。佩戴件数、装备根ID集合、占用身体区域计数对应不同规则事实，本批未因名称接近将其合并。响应管线契约同步_submit第三参数、自动接管展示职责与跨等待取消条件，未实施待定commit/present重构。
- 修正旧校验盲区：runner_cases.ownership原来只从注册分类追踪.run(t)，漏掉规则／UI根入口中的.run(self)。现在同时扫描两个根入口和两种调用者；只追踪玩法_cases.gd，保留共享运行器故障探针。防止上批已消除的core重复执行小魔女专项再次绕过检查；没有删去有效玩法用例。
- 复用architecture_cases.projection_contract，增加豆包自动接管、DeepSeek手动零能量首回合、双面能力同时启用与单面关闭。沿原真实出牌／状态切换命令取证：索引与实时查询等价、状态／随机只读、候选ID稳定、View不共享状态及注册表可写容器、查询作用域释放。未复制新的规则内核或专项全量调用。
- 修改前分类 `20260919T143612235-49940`：card_expansion、relics、architecture、content、runner、events、core，共5886项通过，exit0、status=passed，before=after=`DF8CCF385B85B8F6C93CBD4829841A780EC6EEB03AE35CC2DCFB04D0B14CAB0A`。修改后受影响分类 `20260919T143934115-49076`：architecture506、runner499，共1005项通过，exit0、status=passed，before=after=`FD91160AD0C964F8400CAC126E9BFBEE0919286CFF01FF94E7341AFA8F98AEE2`；未重复跑未改动的其余分类，不合计为互不重叠的6891条用例。
- 归属检查敏感性：在忽略目录中的最小独立Godot工程执行改前／改后两个实际ownership实现。基准和共享故障探针均通过；分别注入规则根入口、UI根入口对已注册case的.run(self)重复调用，旧实现漏报，新实现各准确报告1项重复归属。证据 `spire-godot/build/architecture-maintenance-20260920/ownership-sensitivity.log`；依赖扫描与开工副本同目录。
- 独立只读审查 `review_architecture_maintenance` 对三个增量未发现可行动缺陷；最终diff空白检查、现行文档链接与UTF-8检查通过。两轮均对应本地共享工作区的稳定源码，非前批隔离快照；本批未运行窗口分类、完整随机矩阵、完整项目回归或安卓真机检查，未提交、推送、打包或发布。

## 2026-09-20｜嘴部堆叠与胶带层序

- 原安装准备统一限定嘴部总量2、仅胶带追加；混材胶带强制在非胶带外层。替换的容量需求调用同一接口，保留原最外层、品质比较及同批保护。
- `equipment_cases.mouth_stacking` 覆盖口球＋胶带／双胶带、反向追加和第三件拒绝、明确层参数不能把胶带放入内层、真实Application安装、界面只读层序、卡牌移除胶带后徒手解除口球、正常读档及非法堆叠原子拒绝。
- 首轮 `20260919T145932925-51360`：application 1项旧嘴部容量预期失败；原测试的批次保护要求保留，改为先补空位、再替换旧胶带，共2次，不能第3次替换本批新件。之后 `20260919T150012201-48988` 六类1572断言通过；独立审查指出存档聚合缺少组合与层序约束，修复后原结论在该域重新取证。
- 最终 `20260919T150340275-16088`：equipment、replacement、application、equipment_complete、casting、localization 共1575断言通过，exit0，summary.status=passed，before=after。敌方循环使用分类默认4/16种子采样，不称完整随机回归。
- 新组合／层序聚合检查依项目要求仅debug开启。敏感性探针复制Game并只移除新增检查：两口球、胶带同层、胶带内层三种坏档原实现均拒绝且原状态不变，移除检查后的副本均接受；`build/mouth-sensitivity.log` 三项true，临时脚本已清理。发行工厂继续强制安装规则。
- 独立只读审查 `/root/review_mouth_stack` 初审发现的存档问题已修正并复核通过。未跑整体回归、窗口自动化或安卓真机；未提交、打包或发布。

## 2026-09-20｜商店旧CG跨塔串用

- 用户反馈仅有聊天截图，未确认具体CG和前置行程；已复现与现象一致的商店付款演出缺陷。根因Services.view倒序扫描全部历史日志，只按room匹配shop_trade；生成新塔会复用楼层／列房间ID。
- 修复前确定性路径：生产Game种子37，旧floor_10_4实际购卡后魔力100→85；_restart_tower后正式depart选择新floor_10_4。进店后mana_before=85、mana_after=85、taken=false，但performance仍为旧shop:floor_10_4:2:self。探针首次错用move候选导致数组越界，改为正式depart后得到上述结果，未将首次失败计作复现成功。
- 结构：既有Services.start进店日志附shop_entry；Services.view遇本次入口或非shop阶段停止回溯。前者覆盖同phase重入，后者兼容旧无marker记录。未新增状态／存档字段，保留日志与正常支付路径。
- `build/checks/20260919T150333709-50464`：services规则613、services UI283断言通过，exit0、status=passed，源码前后指纹一致。覆盖真实新塔同ID起点选择、新店未付款和未售出、旧快照无marker、新交易照常显示CG、重入隔离与界面切换付款来源不触发演出。
- 已查看`build/ui-shop-entry-no-stale-cg.png`：第11层商店商品未售出，自身魔力85，无旧付款遮罩。独立只读审查`/root/review_doubao_prepare_exclusion`无阻断问题；定向diff --check通过。尚未取得玩家原始存档，不能确认截图所述局面的全部前置条件。未打包、提交、发布或安卓真机验收。

## 2026-09-20｜杯类唯一名额、旧档与监狱循环

- `special_equipment_cases.cup_exclusion` 穷举全部杯类／品质的双向追加拒绝，拒绝不改完整快照；验证跨家族高品质替换、低品质拒绝、带体级联移除与非杯类兼容。
- `prison_cases.cup_stack_migration` 使用旧规则合法的两杯数据验证：大理石后高级马眼全包杯＋强制杯开场合计110.52，原阈值100；三组旧档按品质优先与同品最早清理主体／固定带／登记，原输入及资源不变，当前版多杯档拒绝。迁移后的五级监狱经过真实回合与至少两次巡视，仍有可行动回合、不会补回重复杯或判为违规。
- 初始探针曾遇另一任务SUMMIT_ENCOUNTER更名中的编译错误，输出不作通过证据；后续正式门禁完成复现数值和修复行为验证。64个从无杯开始的入狱种子未找到该组合，不据此否定已佩戴杯具被保留后形成叠加的路径。
- `20260919T152329190-51364`：旧SPECIAL测试仍假定全包杯可与龟头杯共存而失败；改用兼容冠沟环保持覆盖／容量／保存断言。`20260919T152411937-52128`：监狱旧断言暴露连接绳占用普通配额，以及新随机杯带体被误当作独立生成池根；前者修正入狱spec.allow_links，后者断言仍检查精确根数量与合法带体，并未删除有效失败案例。
- 独立只读审查 `/root/review_cup_exclusion` 发现真实revision52无带满紧度杯迁移失败，修正为保持无带；新增三组52历史形状验证，复核通过。事件暂存迁移本轮只有静态审查证据。
- `20260919T152805268-7184`：六类规则3179断言全部通过，工作区其他修改导致source_changed／exit1，未记为冻结通过，按原范围重跑。未进行整游回归、窗口或安卓真机验证。
- 最终冻结运行 `20260919T152955631-50892`：localization、replacement、application、special_equipment、persistence、prison 共3179断言通过；exit0、summary.status=passed、before=after。`git diff --check` 通过。仅源码、测试与文档修改，未提交、打包或发布。

## 2026-09-20｜铁男接入第一幕塔顶首领池

- 新增 `iron_man_cases` 29项，覆盖150／50／50生命、小魔女三单位×1.3、开场捕缚与姿态、普通平板锁替换、诅咒平板锁和小魔女四玩具分支、每3能量结算、无人机胶带／捕缚／遥控耗电／上锁、1电量时三次刺激顺序、仅加固普通拘束具、解除捕缚后的发呆与按敌方行动边界计时的机械减伤失效、四组强化累计、合法快照往返、强化次数与行动阶段冲突存档原子拒绝、Boss死亡联动及64种种子内两个塔顶首领均可抽到。
- `20260919T153215476-38960`：localization、replacement、encyclopedia、content、special_equipment、intent、persistence、iron_man、tower_progression共3185项通过，exit0、summary.status=passed、before=after。之后装备强制替换改为副本预演并原子提交，受影响域重新取证。
- `20260919T154241109-2680`：replacement、architecture、special_equipment、persistence、iron_man共2086项通过，exit0、summary.status=passed、before=after。覆盖替换失败不写入、依附清理、现行装备结构与铁男专项。
- 第一轮独立只读审查指出四项边界：加固可能选择复合组件、连续打断可延长破甲、1电量装备可能失去本次普通刺激、存档意图未与阶段核对。四项均按正式入口修正并加入上述反例；`20260919T155517678-48520`：localization、replacement、architecture、special_equipment、intent、persistence、pressure、iron_man、tower_progression共3776项通过，exit0、summary.status=passed、before=after。
- 第二轮独立只读审查指出强化次数未与阶段绑定、拘束盒图鉴遗漏铁男战生命差异；修正后又由第三轮独立审查补出普通拘束盒64生命的断言空档。三处均已补齐。`20260919T160806514-12776`：iron_man、encyclopedia共587项通过；`20260919T160815574-47904`：localization、replacement、architecture、encyclopedia、special_equipment、intent、persistence、pressure、iron_man、tower_progression共4391项通过。两轮均exit0、summary.status=passed、before=after。
- 窗口 `20260919T153651845-13856`：tower_progression 59项通过，真实进入铁男塔顶房并核对三单位生命与房间名称；`20260919T154428960-46248`：encyclopedia、enemies 392项通过。两轮均exit0、summary.status=passed、before=after。
- UI复跑 `20260919T160902332-46248` 首次被同期新增且尚未导入的 `pressure_heart.svg` 挡在主界面预载阶段；导入完成后，`20260919T161043379-38040` 的图鉴UI又在并行新增卡牌“心痒难耐”的测试版插图映射处失败，均未触及铁男断言。单独重跑 `20260919T161137396-45064` 时tower_progression 59项全部通过并再次真实进入铁男房、核对150／50／50；运行期间仍有并行文件写入，结果标记为source_changed，冻结通过仍以前述 `20260919T153651845-13856` 为准。本批不代替并行任务修补该卡牌图标。
- 较早的组合窗口轮 `20260919T153245811-51052` 在移动工作区中出现intent弹窗既有失败和塔顶旧按钮文案失败，不记作通过；塔顶断言同步当前“重新开始”按钮后已由上述59项重跑覆盖。规则 `20260919T153734114-41140` 的enemies分类1967项仍有2项六缚嘴部加固断言失败，铁男人形审计通过；这两项属于现行嘴部双层改动范围，本批未改六缚规则或删除失败案例。
- 定向 `git diff --check` 通过。使用默认每日种子采样，没有运行完整16／24种子矩阵、整项目回归、安卓真机或打包发布。


## 2026-09-20 欲望魔方 Pro Max 与角色限定（Codex）

- 域：`Departure`、`RelicEffects`、`Pressure.cast_chance`、`Character.allowed_card/relic_allowed`、`CardRewards.eligible`、开局界面与遗物图鉴。
- 最终规则以 [game-design.md](../design/game-design.md) §4.3／§9.4／§10.1 为准：仅魔法少女，第五项兑换；小魔女仍四项；淫魔法仅接通条件门禁，尚无正式标签卡。
- 检查：`spire-godot/build/checks/20260919T154427768-41160`，`witch_character,localization,relics,casting,tower` 3247断言、`encyclopedia,home` UI290断言通过，退出0，`status=passed`，前后指纹 `0693AB39BC4B98F7DB0E09BD504E92238F2C05831F80AB442E74C7914F3A5E91` 一致。
- 覆盖：原初始遗物的原子替换与50快感、重复领取／缺失初始遗物拒绝、旧四选及新五选存档；归一化曲线节点与对称单调、部位倍率、0%禁止施放及峰值正式施法；整备结束10快感一次结算、阈值过载后可离开、休息／监狱不触发；真实卡牌临时标签夹具覆盖开放／关闭及魔女排除。原生UI点击第五按钮完成兑换，魔女不存在该按钮；`ui-departure.png` 已人工查看，位于第四项下方且无重叠。
- 过程：首轮发现固定初始遗物误入随机遗物seen记录导致存档拒绝，已移除；0%施法测试按既有不可用规则修正，保留拒绝不扣费的断言。修复后首轮源码变动标记为source_changed，不算冻结通过；隔离副本补齐export_presets夹具后通过，但用户随后收窄角色范围，先前结果被本条最终检查替代。
- 独立只读复审：`review_doubao_prepare_exclusion` 在角色限定变更后重新审查，未发现阻断问题。未跑全项目回归、未作安卓真机验收；本次仅源码与素材更新，未打包、提交、推送或发布。

## 2026-09-20｜快感汲取器

- 范围：罕见遗物注册与奖励池、高潮共用钩子、批量次数、魔瓶资源隔离、剧情回执、读档与拒绝提交、图标及悬浮说明的真实 UI 输入。
- `check.ps1 -Import -Suite relics,pressure,localization -UI -UISuite status` 首轮 `20260919T160640184-47044` 因另一在途任务尚未创建 `edging_seal_cases.gd` 而解析失败；`20260919T160836762-15196` 因该任务两项 SEAL 用例失败；`20260919T160926037-38248` pressure 1255断言通过，但 UI 被另一项新 SVG 尚未导入挡住。这些均保留为失败记录，不作为本项验收通过。
- 依赖完成并重新导入后，`20260919T161010698-50448` 与同范围复跑 `20260919T161301856-3944` 均为 localization/relics/pressure 3167断言全部通过，UI status 144断言通过，无引擎错误。两轮最终均为 `source_changed`（退出1）：共享工作区持续有并行修改，故只报告实际断言结果，不声明冻结工作区或整库回归通过。
- 独立只读审查 `review_pleasure_extractor` 未发现本项实现缺陷；已确认缺失测试依赖恢复，注册、单一写入通道、剧情末条回执、图标与本地化契约一致。
- `git -c core.safecrlf=false diff --check` 通过。未运行全量回归、安卓真机验收；未打包或发布。

## 2026-09-20 · 寸止钢印（遗物／快感数值结算）

- 结构：沿 `RelicEffects.cap_pressure` 先限幅绿色小鸟，再通过现有 `trigger` 通道执行钢印减半与加蓄力；次数复用 `relic_used`＋`combat.serial`。`Pressure.overloads_at` 统一数值结算与钢印触发的浮点容差；剧情直接高潮不经过数值保护。界面只读遗物计数投影，未新增存档字段。
- 新用例：罕见池、阈值最近反例及三路径容差边界、减半后仍超限、无惩罚与原有蓄力保留、绿色小鸟两种持有顺序与保护到期、battle→prepare 续场、battle/rest/prison 新场、读档不刷新、无效提交与只读查询、Ditto 独立次数、真实回合提交及图标和悬浮说明更新、中英文显示。
- 首次命令误用未注册分类 `relic_revision`，未执行规则；更正为 `relics`。初版测试的奖励池夹具已持有目标遗物，且回合预期遗漏完全自由时的降快感；修正夹具与预期，未删除断言。独立审查 `review_edging_seal` 发现严格阈值与既有浮点容差不一致；已统一至 `overloads_at` 并新增9条边界断言，复审无遗留问题。
- 运行 `20260919T161000058-49416`（3673规则＋144 UI）和 `20260919T161321411-26044`（3682规则＋144 UI）断言均通过，但并行任务改动导致 `source_changed`，不计冻结验收。
- 最终原选范围重跑：`tools/check.ps1 -Suite relics,pressure,localization,architecture -UI -UISuite status -TimeoutSeconds 300 -KeepGoing`；证据 `spire-godot/build/checks/20260919T161601989-10788/summary.json`，退出0、源码指纹一致、`status=passed`。规则3682断言（localization 165、relics 1756、architecture 506、pressure 1255），状态界面144断言全部通过。
- `git -c core.safecrlf=false diff --check` 通过。仅验证上述范围，未宣称完整回归；仅修改源码／内容与文档，未打包、发布或提交。

## 2026-09-20｜铁男独立SVG立绘

- 范围：原创透明SVG、铁男外观标识及 `Arena.ILLUSTRATIONS` 共用映射。图鉴沿 `Encyclopedia.show_entry` 使用同一Arena；不改战斗规则或美术偏好存储。
- Godot原生SVG栅格化验证：720×780，透明通道为混合alpha，有效内容边界 `(66,61,605,689)`，未越出画布。人工查看 `build/art-preview/iron-man-scales.png` 的原尺寸与两档缩小图，检查机械臂、钳爪及胸舱轮廓。
- `tools/check.ps1 -Import -UIOnly -UISuite tower_progression -Screenshots ui-iron-man-battle.png -TimeoutSeconds 300`：证据 `build/checks/20260919T161923607-38956/summary.json`；退出0、`status=passed`、before=after，61项通过。真实塔顶界面加载独立透明SVG，三名敌人保持150／50／50生命；人工检查 `build/ui-iron-man-battle.png`，立绘等比完整、无白底、无遮挡血条或意图。
- 定向 `git diff --check` 通过。仅验证美术接入与塔顶界面，未跑全量规则回归或安卓真机；未打包、发布或提交。
- 独立只读审查 Erdos：核对本批增量与必要调用链、SVG内部引用及原图／缩略预览，未发现阻断问题；确认战斗与图鉴共用映射、默认与测试偏好、停机变暗及鼠标穿透契约，未见规则误触。

## 2026-09-20｜清醒项链

- 最终执行：`check.ps1 -Suite relics,pressure,localization -UI -UISuite status`，日志 `spire-godot/build/checks/20260919T162641974-51516/`；规则3204断言、status UI 150断言全部通过，退出0，summary=`passed`，源码前后指纹一致。先前 `20260919T162507434-30224` 规则3203断言通过但工作区变动，仅保留为过程证据。
- 新规则覆盖真实姿态行动触发、立即不抽/下回合兑现、多次累计、上限饱和、开场效果提前触发后的延迟、滑精/剧情/强制高潮、存档与过期提交、跨场景与百变怪、日晷洗牌。UI 使用真实点击核对专用图标、待抽角标、悬浮说明及下一回合牌数。
- 计数检查敏感性：对现有负例相同的 `-1`/`0.5` 状态，原 `RelicEffects.validate` 拒绝，复制脚本仅移除新增类型/非负守卫后接受。证据 `spire-godot/build/lucidity-counter-sensitivity.log`；临时复制脚本与探针已清理，正式源码未做临时变异。
- 独立只读审查 `review_lucidity_necklace` 核对接口、时机、存档、展示和最终证据，未发现本项缺陷；`git -c core.safecrlf=false diff --check` 通过。
- 仅验证上述分类与桌面 UI，不是完整回归或安卓真机验收；未打包、发布或提交。

## 2026-09-20｜新增装备替换接口与六缚旧校验

- 检查域：新增铁男强制装备替换与普通Replacement接口的一致性、状态写回／外层引用／反馈回滚、嘴部两件容量与六缚区域施加；开工274份在途文件完整保留。固定源码扫描49份core、27份data、49份UI脚本，未发现反向UI依赖或UI直接game.state访问，game.dispatch仍只在Main._submit一处；结合architecture迁移／事件／投影检查取证，不宣称动态调用完全形式化证明。
- 实际缺陷：force_special清理平板锁时会级联删除固定带，旧removed却只记录主体，与普通替换的物理差集契约不一致。新增forced_special_boundaries先在原实现复现：`20260919T162118035-49444`，replacement106项中仅回执完整性1项失败。修复为按实际前后目标差集区分removed与lost_links，并将execute／force_special重复状态写回合并到唯一_commit_changes；原权限、品质比较、工厂、清理及版本归属不变。
- 新回归覆盖真实主体／固定带回执、返回对象不共享状态、未变更的state／敌人／手牌／随机容器身份、无隐式费用／回合／版本递增、诅咒装备拒绝、真实工厂写入并推进随机后的迟失败完整回滚与反馈收集器恢复。独立审查建议补的真实股绳→手腕链接也已覆盖：强制安装小穴跳蛋后removed只记股绳、lost_links只记链接、另一端保留且状态有效；这是通用接口覆盖，不宣称铁男当前杯具路径发生过断链。
- 两条六缚旧失败按现行嘴部规则更新：单件高级口部装备仍允许追加低／中级外层胶带，原内层不变；另建高级口部装备＋高级外层胶带的真实满位夹具，继续断言拒绝弱替换并仅加固外层。保留不能新增时的加固反例，没有放宽生产规则。初始 `20260919T161907537-26068` 六分类3690项仅这2项旧失败；更新后 `20260919T162227841-47384` 八分类4275项全执行通过，但source_changed／exit1，不计冻结通过。
- 注释与断链用例补齐后的共享工作区 `20260919T162513274-50060`：replacement109项通过、exit0、status=passed、before=after。独立验证快照 `G:/CodexData/verification/architecture-followup-20260920` 由HEAD 00e6327＋开工全部在途文件＋本批四文件最终增量组成，构成及SHA256见根verification-source.json；未覆盖共享工作区，后续其他任务修改未纳入。
- 快照 `20260919T162604309-35420`：replacement、application、architecture、content、runner、special_equipment、enemies、iron_man共4278条规则断言全部通过，前后源码指纹=`03B4A51B2EA4F6FD58E6FBFEDDD9E94281EADF46F6B4F9ACE7E575E710CECF56`。同轮UI首次在arena预载iron_man.svg时缺导入缓存，0条窗口断言，整轮failed／exit1，不将其称整轮通过。沿原check.ps1以Import＋RerunFailed补导入并仅续跑未完成窗口；`20260919T162745941-51260`：special_equipment60、enemies220，共280条窗口断言全部通过，exit0、status=passed，before=after=`03B4A51B2EA4F6FD58E6FBFEDDD9E94281EADF46F6B4F9ACE7E575E710CECF56`。未重复已过规则；窗口涵盖真实特殊装备详情／拖放及敌人交互，未生成截图。
- 独立只读审查review_replacement_architecture初审与追加断链用例补审均无阻断问题；残留半句注释已修正。交付前维护函数与验证快照一致，diff空白、现行契约UTF-8与链接检查通过。本批只改一个生产模块、两个既有测试文件和契约／记录；未做任意旧档兼容工作，未运行全项目／完整随机矩阵或安卓真机，未提交、推送、打包或发布。

## 2026-09-20｜淫魔法条件卡池首批

- 范围：七张牌的条件卡池、快感费用与完整失败返还、技能／能力与魔法分类、延迟快感、实际增量累计能力、下一次行动豁免、强制高潮逐张选牌消耗及保留快感。规则见 [卡牌设计](../design/cards.md)。
- 新增真实提交用例覆盖三个候选牌区、排除自身及已消耗／能力区、少于三张拒绝、永久牌保留、中途存档、自然阈值与指定高潮先后、心理暗示多段及监狱开锁、错误类型／错误ID／重复ID存档拒绝。真实UI输入检查爱心与魔力费用同时显示及三次点击完成选择。
- 独立只读审查 `review_doubao_prepare_exclusion` 发现监狱牢门出牌漏消费心理暗示，以及新增连续行动增益字段缺少验证；已修复并补正反例，复审通过。
- 初次卡牌检查3项失败：新测试将基础卡不在奖励数组误当作通用资格不可用；另外两个失败发现快感不足提示抢先覆盖休息房禁用原因。分别修正测试语义与判定顺序，未移除断言。英文目录首次新增格式串未转为 `{p0}` 参数，导致资源加载失败；按现有兼容目录契约修正。
- 冻结中间结果 `spire-godot/build/checks/20260919T161452948-48144`：规则 card_expansion／casting／pressure 共3465，UI card_power 共385，退出0；结果早于最终监狱边界和美术／译文补丁。
- 最终共享工作区运行 `spire-godot/build/checks/20260919T162357884-40240` 的10个规则分类10580及两个UI分类557断言均通过，但 `source_changed`，不计冻结验收。为避免并行编辑干扰，将当前源码完整复制到 `G:/CodexData/verification/lewd-magic-20260920-1630`，排除构建缓存后独立导入，重跑全部原选分类。
- 隔离目录首次导入因尚未生成的字体缓存引用报错，未计通过；Godot已生成依赖后再次执行正式导入，无手工修改缓存。
- 最终冻结证据：`G:/CodexData/verification/lewd-magic-20260920-1630/build/checks/20260919T163147327-46992/summary.json`，退出0、`status=passed`，前后指纹均为 `44A661ECDDABA68E4F37E6E04F715AC9CB43F1D54FF1F819C74EDA23ABDA84F3`。规则 localization／card_power／card_expansion／relics／basic_attacks／content／casting／persistence／prison／pressure 共10607断言，UI card_power／encyclopedia 共557断言全部通过。
- 交付前逐一比较19个本批实现、资源与新测试文件，主工作区与冻结目录哈希全部一致。人工检查爱心与蓝色费用共存、法阵插图及选牌界面；定向 `git diff --check` 通过。未进行全量回归或安卓真机验证，未打包、发布或提交。

## 2026-09-20｜存档文件大小不设上限

- 按用户明确要求，删除 SaveStore 的8 MiB常量及读写两处容量拒绝，主档、临时文件回读与备份共用同一读取入口；保留版本、格式、校验和、状态验证、备份及替换规则。
- 在既有 persistence 分类补充实际超过8 MiB的合法日志存档：正式写入、完整读取、更新后保留大备份、主档损坏回退、备份校验和损坏拒绝。测试使用独立 build 目录，不接触玩家存档。
- `tools/check.ps1 -Suite persistence -TimeoutSeconds 300`：证据 `spire-godot/build/checks/20260919T164153528-42080/summary.json`，退出0、status=passed、前后源码指纹一致，967断言通过。
- 独立只读审查 review_doubao_prepare_exclusion 通过，未发现遗漏的存档字节上限；定向 diff --check 通过。本次仅改源码、测试和文档，未打包或发布。

## 2026-09-20｜豆包对应台词语音

- 来源：用户提供 `豆包语音.zip`。包内清单40句与现行 `DoubaoDialogue.LINES` 的20cue×A/B逐条精确相等；项目40个WAV按原字节复制，SHA-256全部匹配，时长3.48—7.84秒。原路径、稳定cue、时长与哈希记录在 `spire-godot/assets/audio/doubao/SOURCE.md`；没有执行包内文本中的操作指令。
- 实现域：`Dialogue.entry → FirstTurnPresenter._say` 一次选择字幕与语音，单播放器与原自动提交等待衔接；声音设置沿原显示偏好保存。没有新增核心状态或音频随机。结果对白与交还操作去重、普通刷新不重播、新局／主页停止、关闭后只保留字幕均有定向反例。
- 共享工作区 `20260919T164830346-49972`：localization／architecture 共671断言、display／status 共357断言全部通过；运行中有并行改动，最终 `source_changed`，不算冻结通过。设置截图 `spire-godot/build/ui-doubao-voice-settings.png` 已人工检查。
- 将源码与资源复制到 `G:/CodexData/verification/doubao-voice-20260920-025259` 后独立验证。首次导入 `20260919T165311298-48088` 因尚未生成的项目字体缓存引用而报错；Godot已正常生成依赖，随后重跑正式导入，未手工修补缓存。
- 独立只读审查 Volta：另行核对40条映射、原字节、哈希、时长及字幕，并检查等待、取消、结果去重、声音设置和译文，未发现阻断问题；未逐条人工听辨。界面自动测试静音运行，结论是音频资源、真实播放器状态、顺序与生命周期，不是扬声器或安卓真机音质验收。
- 最终冻结证据：`G:/CodexData/verification/doubao-voice-20260920-025259/spire-godot/build/checks/20260919T165405697-52204/summary.json`；正式导入与原选范围重跑退出0，`status=passed`，前后指纹均为 `3E9F6A889C7402E6F52EA39E1F7392F02F976D018B1B4C0B859EA36C68541DE6`。规则671项、display／status界面372项全部通过。
- 交付前将本批8个代码／本地化文件、40条录音、40份导入描述及来源记录共89个文件与冻结副本逐一比对，哈希完全一致，报告保留于 `spire-godot/build/doubao-voice-source-comparison.json`。定向 `git diff --check` 通过；仅源码与资源更新，未打包、提交或发布。

### 2026-09-20｜豆包默认音量32%

- 默认音量从0.8调整为0.32，静态核对属性默认、initialize重置、配置缺键回退三处一致，既有UI默认／异常配置／恢复断言与现行文档同步。合法已保存音量仍从配置读取。
- `spire-godot/build/checks/20260919T170057490-40760/summary.json`：localization 165断言通过，退出0、status=passed、源码指纹一致。本次数值调整未重复完整自动接管UI；未打包发布。
- 独立只读审查 Averroes：三处默认、异常回退、UI断言及文档一致，自定义35%用例与卡牌音乐默认保留；未发现问题。定向 `git diff --check` 通过。

## 2026-09-20 · 小魔女动作界面／拘束诱导

- 实现范围：窃取权柄结束按钮的锁链／锁头纹样及禁用，脱缚练习实例进度悬浮简介，移除小魔女探索与牢房的火球占位并拦截对应核心候选，基础动作标题及费用行，新罕见0费双拘束技能「拘束诱导」。玩法真源见 [角色2设计](../design/character-two.md)。
- 通道：锁定显示来自 `GameView.end_turn_locked`；进度在 `Cards.metadata` 生成并通过手牌实例投影覆盖静态 note；诱导位于 `Character.evade`，共享 `restraint_part`，生成与安装复用 `Application.choose/execute_concrete`，补装按主动代价语义绕过二次闪避。无新增存档字段。
- 初轮 `20260919T164755367-52340`：594条断言未失败，但新牢房测试跳过收押记录直接调用 `Prison.enter` 导致3个引擎错误；已改用现有 `prison_test` 角色夹具。
- `20260919T165019289-42456`：规则1445通过，UI home失败3条且 `source_changed`。确认静态 note 覆盖了动态进度，改为实例 metadata 覆盖；测试中的首次 draw_serial 刷新重置手工牌面、信息弹窗挡住悬浮，改用现有原生翻面与关信息窗助手。新功能独立 UI 探针9条通过，未用其代替分类门禁。
- 独立只读审查 `review_witch_revision`：确认效果持续与层级、已有闪避优先、补装不递归／不替换、界面状态投影。补测复合装束整件闪避与仅补1件、其他位置全满仍闪避且不推进随机、快照还原后随机及完整结果一致，15条全部通过；已纳入正式 `witch_revision_cases::_boundaries`，复审无遗留问题。
- 最终命令：`tools/check.ps1 -Suite witch_character,application,replacement,architecture,localization -UI -UISuite home,exploration,basic_attacks -TimeoutSeconds 300 -KeepGoing`。证据 `spire-godot/build/checks/20260919T165901188-34668/summary.json`，退出0，`status=passed`，源码指纹一致。规则1460条（witch_character 609、localization 165、replacement 109、application 71、architecture 506），UI 411条（basic_attacks 243、exploration 43、home 125）全部通过。
- `git -c core.safecrlf=false diff --check` 通过。敌方循环沿现有日常采样4／16种子，非穷尽完整回归；未打包、发布或提交。

## 2026-09-20｜命运同担稀有度

- 将 shared_fate 的定义与奖励池归属改为稀有，同步既有 shared_fate_cases 正反卡池及定义断言、设计表格。
- tools/check.ps1 -Suite card_expansion,content -TimeoutSeconds 300：2191断言通过，退出0；spire-godot/build/checks/20260919T170218385-39672/summary.json 为 passed，前后指纹一致（FA3F9FC4314026521FB2FA31F61AF409228C81725016555785A077481C001F3C）。
- 独立只读审查 review_doubao_prepare_exclusion 通过，确认图鉴使用共同分类接口且无独立稀有度覆盖。定向 diff --check 通过；未运行UI测试，未打包或发布。


## 2026-09-20｜四件淫魔法专用遗物

- 范围：洗脑耳环、催眠发卡、淫纹连体丝、淫纹丝手套，共用随机池门槛、快感增减、施法成功、蓄力消耗及高潮入口；只这四件需要欲望魔方 Pro Max，百变怪仍可变形。发卡不响应高潮回落。
- 新增 `lewd_relic_cases`／`lewd_relic_ui_cases`，覆盖门槛与品质池、百变怪、重复触发、零损失及上限、被动减快感、蓄力逐层消耗、成功／失败施法、身体限制、高潮正向奖励与免罚、旧版本动作拒绝、待发存档与拒绝回滚；界面覆盖图标、描述、中英文和真实动作。
- 返工：初轮新增用例2条失败为测试持有 dispatch 前对象引用及 restore 后版本比较错误，已修正夹具。独立只读审查 `review_lewd_relics` 发现均分后封印重复计损失、敌方回合与转场待发反应延后；已分别修复并补正例，含真实 travel_step、开场抽牌前后、战斗结束时旧手牌倍率。最终复审未发现遗留实质问题。
- 新增校验敏感性：在忽略的 build 副本分别移除 repeat 事件组合约束、待发快感整次数约束，已有非法 scope／非法 amount 负例由原版拒绝变为副本接受，两项 PASS；证据 `spire-godot/build/lewd-sensitivity.log`。临时脚本已清理，正式源码未被变异。
- 中间轮 `20260919T165152724-47128`（规则7045／UI230）及 `20260919T165641363-8636`（规则7047／UI230）断言通过但 source_changed，不作为冻结验收。
- 最终命令：`tools/check.ps1 -Suite relics,pressure,casting,card_expansion,localization,persistence,content -UI -UISuite status`。`spire-godot/build/checks/20260919T170336822-14672/summary.json` 为 passed，退出0且前后指纹一致；规则7051、UI230断言全部通过。范围为所列分类的日常采样，非全游戏回归或安卓真机验收。
- 本任务文件定向 `git -c core.safecrlf=false diff --check` 通过。根级检查另发现其他在途修改 `版本更新内容.txt` 的3处行尾空格，本任务未改动该文件。未打包、发布或提交。

## 2026-09-20｜奖励查询架构与门控采样校验维护

- 范围：`RelicRewards.available/offer/battle_drop`、`boss_relic_cases.reward_pool`、`reward_cases.reward_sampling`；当前查询契约补入 [内容创作指南](../design/content.md)。保留任务开始时393份在途修改；本轮只改奖励查询、两份既有测试及相关文档，不修改存档兼容规则。
- 架构：Boss 单件抽取与战后三选一共用 `available(g,"boss")`；移除两处独立筛选，普通／商店门槛、Boss 领取条件、随机调用顺序及冻结写入位置保持。按 response-pipeline 的依赖契约扫描49份 core、27份 data、49份 UI：未发现 core/data 引入 UI、UI 直接读 game.state 或 main 之外引入 core；UI dispatch 仍仅位于 main。数据目录中既有说明／图鉴对规则模块的引用另列为事实索引，不误判为该契约的禁边。
- 复现：`20260919T171055914-7032` 在旧查询实现下新增用例3/1871失败，指向 Boss 查询错用普通池及角色资格；修复后保留双角色、持有排除、低魔力、独立返回数组、只读及随机不变、批次排除、单件剩余池和空池补位覆盖。既有正式领取／重复领取拒绝用例保留。
- 旧校验原因：六分类运行发现 `reward_cases.run` 仍要求未解锁新局抽出整个奖励池。实际漏抽的6张牌与 `reward_pool=lewd_magic` 声明完全一致；不是生产抽取缺陷。现有采样改为未解锁／解锁两种前提，解锁组继续要求全部注册牌逐卡可达，未解锁组验证禁入；种子复现和三张唯一性保留，随机隔离扩至所有非 reward 域。完成覆盖后恢复提前退出，减少无效采样，不删除失败目标。
- `tools/check.ps1 -Suite architecture,runner,relics,rewards,services,witch_character -KeepGoing`：`20260919T171208814-50216`，指纹前后一致 `1CC28A1A087AC9E24FABE6495EBA13387639BEF86FA4B076B2D1CBC320B20A5F`。witch_character609、relics1871、architecture506、runner523、services613全部通过（合计4122）；rewards因上述旧前提1/1997失败，整轮6119且状态 failed，不能称整轮通过。此前误传未注册分类 departure 的运行 `20260919T171157567-39952` 在范围解析阶段拒绝、未执行断言，已改用实际分类。
- 仅修改奖励测试后，按 `-RerunFailed spire-godot/build/checks/20260919T171208814-50216` 重跑失败分类：`20260919T171511482-50664` rewards1290全部通过，退出0、status=passed，前后指纹一致 `EF6E92CFA2AB2F29017A5A142649C7411B5CB904174C15C93A89B32629426046`。生产实现未再变动；本次有效通过证据为五分类4122＋奖励1290，共5412条，分属上述两次运行，不称单次全绿或全项目回归。
- 独立只读审查 `review_reward_pool_maintenance` 完成实现审查及新增测试续审，未发现遗留问题。任务增量、计划、依赖扫描与基线在忽略的 `spire-godot/build/architecture-rewards-20260920/`；相关文件定向 diff --check 通过。
- 未运行 UI、完整随机矩阵、安卓真机；未提交、推送、打包或发布。

## 2026-09-20｜小魔女力量卡牌与遗物池

- 实现仅扩展 WitchCharacter.incompatible/relic_allowed，复用两面与关联buff递归及既有角色资格通道；测试在 witch_character_cases 覆盖五张牌、三件遗物、原角色保留及灵巧／魔力兼容反例。既有商店、开局变牌、战斗奖励及存档交互用例一并运行。
- 第一轮卡池单项检查通过后，按新增遗物池要求修改并重跑最终范围：tools/check.ps1 -Suite witch_character,card_expansion,encyclopedia,relics -TimeoutSeconds 300。
- 最终证据 spire-godot/build/checks/20260919T172027523-39200/summary.json：退出0，status=passed，4678断言通过；前后指纹一致（7B72C38BD8F9F670967DBE462C073EA99DDB9A16CDD327E55A3CA398E49EB290）。
- 独立只读审查 review_doubao_prepare_exclusion 通过，未发现当前力量机制的遗漏；定向 diff --check 通过。未运行窗口或安卓真机验证，未打包发布。

## 2026-09-20｜v0.18 发布验收

- 用户要求：推送0.18并按既有方式交付PC／安卓；双层加密包仅含PC且不上传GitHub。期间用户明确“不用试玩”，此后不再运行试玩或UI交互回归；最初命令中的 normal_play 已在该要求之前完成，未重复。本条记录实际门禁及成品证据，目标发布标签为 `v0.18`。
- 版本：项目与两平台预设0.18，Windows文件版本0.18.0.0，Android versionCode12；两平台版本说明及现行打包契约同步，历史标签和包保持。
- 初轮 `20260919T172400525-19076`：以完整分类／随机矩阵启动，规则在guard遇脚本错误后停止，未进入UI。8/20760断言失败、另2条脚本错误；前后指纹均 `173D96069F595E712E46803800AA62C3B3725C50CB6D1B9C73D44C198277D9CB`。失败来自旧开局数量、旧反抗随机墙距、铁男注册白名单和嘴部两口球无效夹具，不把失败轮写成通过。
- 修正仅涉及校验：开局数量按冻结选项＋跳过；反抗检查位置／墙距／随机游标不变；敌人白名单加入已有铁男与捕缚无人机；共用满位夹具外层嘴部使用胶带。游戏设计概述的墙距旧说法改为引用监狱专题。成品探针去掉仅0.17才检查角色2的限制，保持现行版本必检。
- 续跑命令：`tools/check.ps1 -Suite consumables,wall,events,guard,replacement,pressure,enemies,iron_man,trader,tower,tower_progression -Exhaustive -KeepGoing`。`20260919T173036348-48492` 的11分类9859断言全部通过、退出0，前后指纹均 `D3C3EC7BFE6F3B10E92C7A64C478715C8FF6D9E75CAE9EB281D086DED0772F3A`。按各分类最后有效结果汇总52分类29063条通过，原有受影响共享夹具域已重跑，不宣称单轮全量通过；汇总在 `spire-godot/build/release-v0.18/rules-evidence.json`。
- Windows：`outputs/spire-v0.18-windows-x64-release-20260920`；导出及源清单 `build/package-release-20260920`；成品 PCK、12个相邻内容包、新局／角色2／练习与隔离存档探针通过，发布EXE无界面启动通过。证据 `build/package-check-20260919T173240567`，不是人工试玩。
- Android：`outputs/spire-v0.18-android-release-20260920`；`build/android-release-20260920` 的清单 versionName0.18/code12、16KB对齐和v2/v3签名验证通过；签名证书SHA256与0.17.2一致。`build/android-probe-20260919T173316235/probe.log` 为 RELEASE PROBE PASS、12份内置内容包通过。未进行真机安装、触控、语音听感或性能验收。
- 两平台导出524份源码/资源的清单比较：唯一差异为内容包根的既定平台值，开发源码已恢复为res://；Android导出全部输入哈希与工作区一致。证据 `build/release-v0.18/export-equivalence.json`。
- 交付在 `outputs/release-v0.18-20260920`：普通PC ZIP、Android ZIP、APK、README、SHA256清单；另有仅PC的双层7z，两个压缩头均加密，错误密码拒绝，实际两次解压后逐文件哈希一致，内层仅Windows64且无APK。普通ZIP也重新解压逐文件核对；证据 `outputs/verify-v0.18-20260920/verification.json`。上传器只允许五项公开文件白名单，排除7z。
- 独立只读审查 `review_release_018` 覆盖版本配置、资源入包、Git候选密钥/缓存扫描、旧测试修正与打包/上传脚本。构建日志、签名秘密、存档及成品均不入Git；只提交现行源码、授权素材、校验和文档。

### 2026-09-20｜v0.18 成品返工与最终交付口径

- 独立成品审查发现首轮Android APK误带5份 `content/templates` JSON，违反不分发模板的契约；首轮成品及上条对应ZIP/7z不发布。Android预设补排除该目录，导出器已有禁止路径检查同步纳入，不改玩法源码；旧包5条命中构成检查敏感性证据 `build/release-v0.18/android-template-exclusion-before.json`。
- 最终双平台重新导出为 `release-20260920-r2`：Windows目录 `outputs/spire-v0.18-windows-x64-release-20260920-r2`，PCK/EXE检查 `build/package-check-20260919T173710161`；Android目录 `outputs/spire-v0.18-android-release-20260920-r2`，资源探针 `build/android-probe-20260919T173745375`。两者均通过，Android实际文件列表确认不含测试/工具/构建目录/内容模板/存档或签名秘密。
- 最终524份导出输入清单与工作区逐文件一致，仅保留平台内容包根差异；证据 `build/release-v0.18/export-equivalence-final.json`。本次返工仅影响打包域，按该域重新导出和验收，不重跑试玩/UI。
- 最终交付目录为 `outputs/release-v0.18-20260920-final`，ZIP及PC-only双层7z实际解压验证在 `outputs/verify-v0.18-20260920-final/verification.json`。GitHub上传器只读取final目录，仍只允许普通PC/安卓包及公开说明/校验清单，不包含双层7z。

- 最终独立只读复审确认r2模板排除、12正式内容包、原签名、两平台探针、六个交付文件哈希与两层解压后的25份PC文件均通过，无发布阻塞。


## 2026-09-20｜反馈草稿版本刷新

- 游戏配置已为0.18，旧反馈草稿的非空 context 导致显示0.17。`FeedbackReport._capture_context` 现在共用工程版本读取，跨版本时只更新版本并经 changed 清除旧提交编号和确认状态，保留文字、截图、原场次与日志；同版本重开不改编号。
- `tools/check.ps1 -UIOnly -UISuite interface`：`20260920T013204026-37652` 源码指纹一致，360条断言中2条失败，均在 card_illustrations：28种小魔女卡缺插图、6张淫魔法卡的非空／独立插图检查失败。反馈用例未报失败，整组不能宣称通过。
- 定向复用 `InterfaceCases.feedback` 的独立UI探针，并补同版本重开保留编号断言，38条通过，退出0；证据 `spire-godot/build/feedback-version-probe.log`。只运行模拟传输，未发送真实反馈、未读写玩家草稿。探针已清理；未实际覆盖磁盘草稿读取或安卓真机。
- 独立只读审查 `review_feedback_version` 未发现实质问题，确认提交内容改变时清除旧编号符合服务端去重约束。本次文件 diff --check 通过，未打包、发布或提交。

## 2026-09-20 铁男捕缚收押与正式练习（Codex）

- 域：`CaptureBind.capture_ready`、`IronMan.intent_facts/validate`、`Catalog.entries`；规则 `iron_man/guard/prison/enemies/persistence/architecture/localization`，窗口 `home`。
- 修复前敏感性证据：`20260920T013622126-12864`，新增正式提交测试在两名角色下均报「行动未提交：铁男意图与当前行动阶段不一致」，2/45失败。捕缚清空后仍验证活跃意图造成收押回滚。
- 定向修复验证：`20260920T013858337-14644`，`iron_man` 67断言通过。覆盖99与100边界、下一敌方行动正式收押、共用条只有拘束盒来源、打断延期与解除取消、收押前后快照、确认进入牢房、两名角色正式练习与正常生命倍率。
- 相关门禁：`20260920T014316109-7324`，`tools/check.ps1 -Suite iron_man,guard,prison,enemies,persistence,architecture,localization -UI -UISuite home -TimeoutSeconds 300 -KeepGoing`，退出0，5162规则断言＋131窗口断言通过；`status=passed`，前后指纹均为 `7FF11C18BE2C38C698531B9966EE2C01F194CB9EF962A12E2A7580FED6D6F078`。主页真实点击铁男练习，并结束回合验证真实捕缚建立。
- 随后仅调整英文模板格式、消除翻译目录无关排序并增加英文练习说明断言。受影响域补验 `20260920T014708684-21824`：`-Suite iron_man,localization`，233断言通过（铁男68、本地化165）；退出0、`status=passed`，前后指纹均为 `1A3918009CFCCA2649A31345BE276D0179EC3EDF9FA3200A087DF575FCB1BB62`。
- 独立只读审查：`review_iron_capture` 未发现可行动缺陷；确认非战斗阶段仍校验记录结构、强化计数及随行身份，仅停止用已清理的战斗状态重算历史意图。
- 边界：敌人循环与敌人池为日常抽样4/16、4/24，不是完整随机回归；未做安卓真机验收，未打包、发布或提交。并发反馈窗口修改保留，不计入本任务交付范围。

## 2026-09-20｜近高潮耗能行动与拘束之拥回滚

- 复现：诅咒平板锁＋拘束之拥自由面，滑脱解除低耐久拘束时，耗能牵扯先触发高潮清空能量，后续解除反应又恢复1能量，使提交报「高潮期间不能保留可用行动能量」并整笔回滚。距上限1、9、11点均复现；差20点及拘束面作为最近反例。
- 修复统一经 `Game._gain_energy` 获得当前能量：高潮中实际获得0，解除、抽牌、能力与遗物计数仍执行，下一回合能量不变；保留提交校验及回滚规则，日志记录实际回能。
- 红灯证据：`spire-godot/build/checks/20260920T020023997-35272/summary.json`，pressure新增用例6/1315失败，错误与反馈一致。最终运行 `tools/check.ps1 -Suite pressure,card_expansion,relics,witch_character -TimeoutSeconds 300`：`20260920T020612969-18028/summary.json`，退出0、status=passed，5441断言通过；前后指纹一致 `3D938807124E0979010BF70569E9ABC0477C3269BBDB27DA567F355065D41C39`。
- 覆盖正式出牌提交、过期版本不写入、临界差额、两面能力、正常回能、重复清理，以及高潮自动脱落→抽牌→日晷洗牌回能的真实联动。独立只读审查 `review_doubao_prepare_exclusion` 通过，未发现阻断问题。
- 本次仅修改源码、回归用例与文档；使用分类日常采样，未运行完整随机矩阵、窗口或安卓真机，未打包、提交或发布。其他并发修改保留，不计入本次交付。


## 2026-09-20｜铁男站位与血量

- 显示顺序调整为捕缚无人机／魔导拘束盒／铁男，基础生命40／40／120。通过原显示排序重排，不改战斗数组与行动顺序；小魔女生命52／52／156，续局倍率保持原通道。
- `20260920T015858629-16944`：规则 enemies／iron_man 2042条，UI home 133条，passed且指纹一致。独立审查 review_iron_positions 找到百科3条旧数值，已从注册表及遭遇覆盖派生，复核无遗留。补充 `20260920T020605147-1880` encyclopedia／localization 729条通过，指纹一致。非全量种子回归，未打包发布。

## 2026-09-20｜新增机制的架构边界与校验影响范围

- 本轮保留并发修改，只补充 `tests/suite_selection.gd::CROSS_AREAS`、`runner_cases` 与 repo-ops 使用说明：能力牌、扩展卡牌、遗物、特殊装备的影响模式补跑 pressure；core、guard 的影响模式补跑 iron_man。复用原分类和单次展开入口，默认范围、去重和非递归语义保持。
- 按响应管线契约扫描49份 core、27份 data、49份 UI，未发现禁止的依赖方向或 UI 直接读取 game.state，UI dispatch 仅在 main。当前能量增加的字面写入只在 `Game._gain_energy`；人工核对卡牌动态效果分支也先路由该入口。初始化、支付及清零各有既定职责，不因名称相近合并。静态扫描不等于全项目行为验收；证据与修改前结构图在忽略目录 `spire-godot/build/post018-architecture/`。
- 敏感性：先增加6项独立业务关联断言，保留旧映射运行 runner，`20260920T021734886-35640` 恰好6/529失败；随后只更新映射。断言不从待测声明表派生期望，既有范围、去重、非递归检查保留。
- `tools/check.ps1 -Suite runner,architecture,pressure,iron_man -KeepGoing -TimeoutSeconds 600`：`20260920T021826125-3184` 前后指纹一致 `9BAAF253FF8F8E3107250F7CCC8C7C15C2D1DA7D196EAF08EAD96B798F1696BA`。architecture506、runner529、pressure1327全部通过（合计2362）；iron_man的111条中2条失败，另有一次空数组访问，整轮2/2473失败、3 engine errors，不能记为全通过。
- 该轮铁男失败为新增杯具阶段检查及满位替换事务断言；铁男源码与用例正在另一任务中更新，本轮未覆盖其在途修改。其后的 `20260920T022020992-23348` 为另一任务运行：杯具失败已消除，iron_man仍有1/144断言失败（满位替换事务），后续以该域最新取证为准，不复用旧版铁男通过结论。
- 独立只读审查 `review_post018_validation` 覆盖本轮三文件，无阻断问题；确认六项映射均有真实接口依赖、测试非镜像、默认范围不扩大。本轮未试玩、运行UI、完整随机矩阵或安卓真机，未提交、推送、打包或发布。


## 2026-09-20｜铁男杯具与替代装备进阶

- 实现：当前强化层数派生杯具与不可佩戴杯具时的替代装备规格；开场／重新捕缚／补电共用 `IronMan.apply_capture_equipment`。杯具复用原子 `Replacement.force_special`，替代装备复用 `Application` 的合法新增／替换。普通与复合施加直接消费共同 `installation_intents`，未施加次数转为原普通拘束具加固。解除捕缚减1层、最低0，撤回派生效果而不改写已穿戴装备。
- 最终要求：耗能阈值4；不可佩戴杯具的0—5层规格数量3／3／4／4／5／6，紧度在1层升3、品质在3层升高级；4层起每层数量＋1。批次仍保护本批已装装备，空位不足不伪造第6件。
- 测试覆盖正式补电与第五步强化、杯具唯一性和第5层以后封顶、旧版本动作拒绝回滚、1—5层解除与存档恢复、零层和重复解除、诅咒装备保护、小魔女替代、真实普通替换与普通／复合加固回退。新增能量余数3存取、显示3/4、非法4拒绝回滚及恢复后第四点触发。
- 初轮 `20260920T021737131-10652` 的失败来自测试错误读取杯具家族及未填满眼罩位置；后两轮替换断言仍有可新增肩带或同品质不允许替换，已用真实三档满位且更高品质施加修正，并验证 can_apply 无空位。`20260920T022612884-16388` 规则1055／UI133通过，但被后续用户调整取代。`20260920T023118033-10676` 两条失败为测试要求满位仍安装第6件；实际已保护本批5件，补测无合法剩余候选后修正容量边界。
- 独立只读审查 `review_iron_cup_progression` 发现快照仍硬编码耗能余数小于2，已与结算、运行时校验一起改读 `CaptureBind.energy_threshold`；复审确认闭合，无遗留实质问题。
- 最终 `tools/check.ps1 -Suite iron_man,replacement,application,persistence,guard,encyclopedia,localization -UI -UISuite home`：`20260920T023651197-19608/summary.json` 为 passed，退出0、指纹一致。规则2164、UI133断言通过；为所列域日常采样，非全游戏穷尽回归或安卓真机测试。本次 diff --check通过；临时定位脚本已清理，未打包发布。

## 2026-09-20 杯类基础值下调（Codex）

- 域：`SpecialEquipment.TYPES` 七种杯类注册数据、共用 `gain` 与动态说明；更新既有倍率和注册规格测试期望。
- 最终门禁 `20260920T023905353-40316`：`tools/check.ps1 -Suite special_equipment,iron_man -TimeoutSeconds 300 -KeepGoing`，退出0，691断言通过（special_equipment 501、iron_man 190），`status=passed`，前后指纹一致：`705D8ACD8EA39B3CB92099273A95559D3B97847660B182D1524292044595879A`。
- 初轮 `20260920T023404669-5640`：special_equipment 501通过，iron_man 181中两条替代装备数量断言失败。随后观察到并发任务更新了铁男测试，原两分类在最终门禁完整重跑通过；本任务未修改铁男代码或断言。
- 隔离对照仅在忽略目录脚本进程内恢复旧杯数值：当前两分类共691断言中，只有本次两处新数值期望失败，铁男通过；不改正式注册表文件或玩家存档。
- 独立只读审查 `review_cup_values`：七种类型覆盖齐全、字段与数值对应正确；原牵扯0保持0，固定带不受影响。未发现可行动缺陷。
- 仅数值与文档修改，未做新窗口验收、未打包发布；并发修改保留。

## 2026-09-20 强制杯牵扯基础值8（Codex）

- 域：`SpecialEquipment.TYPES.forced_milking_cup_high`、共用结算与说明；仅energy_gain改8，turn_gain16与duration0保持。
- 首轮 `20260920T024811100-15872` 的501断言通过但source_changed，不作为冻结验收；原范围完整重跑 `20260920T024915625-39548`，`-Suite special_equipment`，退出0、501断言通过、status=passed，前后指纹一致：`237699D3AC6A97FDC2B5D01A0393E61BF81D7353F6257FCCBD92802A7490E44F`。
- 独立只读审查 `review_forced_cup_eight` 未发现问题。文档数值表同步；未打包或发布。

## 2026-09-20｜铁男随行单位独立捕缚与遭遇覆盖

- 域：`Enemies.encounter_member`、敌人工厂、`EnemyPlans`、`CaptureBind`、`IronMan`、快照恢复与图鉴。实例覆盖统一由遭遇成员声明读取；铁男和凑数型无人机分别沿捕缚来源累计耗能。具体数值以 `../design/enemies-first-floor.md` 为真源。
- 新增验证覆盖：两名随行单位命名与初始捕缚；拘束盒施加/加固的声明与实际装备结果、普通遭遇反例；无人机开场打断、无自身来源时不触发、解除后准备重施、离场停止；独立3/5能量边界、余数存取与非法阈值拒绝回滚。
- 快照版本55：旧52—54版本补齐新增无人机行动状态，旧52/53原装备迁移继续保留；不伪造捕缚、不推进随机，保留打断。缺失字段兼容仅限旧版，已有损坏字段及当前版本缺失字段仍拒绝并原子回滚。
- `tools/check.ps1 -Suite iron_man,guard,persistence,encyclopedia,localization -UI -UISuite home`：`20260920T025554226-10992/summary.json` 为 passed，退出0，before/after均为 `7C62361BFD9FCBCEDFD301D69A140610FA3F5307C5F389A928B1A8C94E0E2A36`。规则2015断言、home UI133断言通过；日常采样，非全游戏穷尽回归或安卓真机验收。
- 独立只读审查 `review_iron_supports` 对上述接口及测试证据未发现待修问题；未额外重复跑门禁。最终 `git diff --check` 通过，临时文案处理脚本已清理。保留无关在途修改，未打包、发布或提交。

## 2026-09-20 出狱检查与特殊装备电量排查（Codex）

- 只读定位 `Prison.execute(inspect/accept)` 与 `release_inspection`：登记清单仅存ID，巡视按现存ID判断缺件；回充记录不计入违规，延刑条件仅缺件或没收工具。电量上限校验与登记清单判定无关。
- 忽略目录隔离探针 `build/prison_battery_audit.gd` 使用正式收押、进入牢房、结束回合出狱路径；安全等级1／2／3分别覆盖空电、剩余1、满电，共9场景36断言、0失败，全部到期出狱且temporary inspection无缺件、无延刑。每场具有2或3件有限电量装备。
- 未复现合法剩余电量差异阻止出狱；未修改运行时代码，未声称覆盖具体玩家存档或非法电量值。

## 2026-09-20｜拘束盒首回合与铁男战捕缚追加

- 诊断：开场三来源实际依次为30、35、40，旧显示50来自紧接着玩家回合开始的拘束盒＋10，并非初始合并计算错误。
- 用户最终规则：所有拘束盒施加捕缚首回合跳过回合开始的装备及进度追加，重新施加同样处理；下一回合恢复。铁男战本体追加15→10，随行拘束盒的回合开始及库存耗尽追加10→5；普通拘束盒、警卫及无人机触发数值保持原规则。实际数值见 `../design/enemies-first-floor.md`。
- 结构：遭遇成员capture_gain经CaptureBind.gain_amount统一供执行/预告/说明；捕缚来源skip_turn_start在施加时按行动顺序建立，由原turn_start唯一消费。敌人先手时本回合upkeep已经过去，不额外跳过下一回合。旧档缺少可选标记沿原周期继续，损坏标记拒绝恢复。
- 测试：正式回合开场40、下一轮55，普通拘束盒40→50；两种盒子的准备/重施、敌人先手开场及重施、库存耗尽、跳过标记存取与损坏原子拒绝。隔离内存脚本移除唯一类型检查后，损坏标记能通过其余快照/运行校验，证明新检查确能捕获缺陷；未修改正式源码做探针，临时脚本已清理。
- 首轮仅数值调整 `20260920T030423347-4016` 1054断言通过，后被首回合需求取代。`20260920T030743727-2976` 有1条无人机锁断言失败：旧前置依赖首回合自动生成皮革；现用未上锁手腕夹具补足合法目标并保留断言。独立审查另发现敌人先手会多跳过一回合，已修复并添加真实先手流程验证。
- 最终 `tools/check.ps1 -Suite iron_man,enemies,guard,persistence,encyclopedia,localization -UI -UISuite home,enemies`：`20260920T031038783-21964/summary.json` passed，退出0、源码前后指纹一致；规则4021、UI354断言通过。为所列域日常采样与桌面窗口检查，非全游戏回归或安卓真机验收。
- `review_iron_supports` 独立只读复审确认上述两项问题已修复，无新增问题。diff --check通过；未打包、发布或提交。

## 2026-09-20｜捕缚姿态查询去重与新增规则复核

- 跟进上轮铁男满位替换失败：后续任务已补齐正确满位夹具，并更新独立捕缚阈值、遭遇覆盖及首回合跳过规则。本轮保留全部在途改动，复核当前实现，不恢复旧数值、不扩展存档迁移。
- 架构调整仅涉及 `CaptureBind.fixed_posture/apply_bind/observe`：删除第二份来源姿态交集计算，统一消费 `allowed_postures`。落地前缓存当次查询；施加捕缚在校正后重新查询供日志，保留多姿态可选与单姿态固定的原有区别，不跨提交缓存。实现入口说明同步到 [第一幕敌人](../design/enemies-first-floor.md)。
- 在既有 `iron_man_cases` 补8条接口断言：无来源、非法姿态校正、多种合法姿态保持、返回数组隔离、查询不改状态及随机、允许／拒绝、铁男与拘束盒交集、来源离场和完全解除。重构前 `20260920T031646442-40696` 铁男255断言通过、指纹一致；重构后复用相同用例，未删除失败目标或新增运行时校验。
- 最终 `tools/check.ps1 -Suite architecture,runner,iron_man,guard,enemies -KeepGoing -TimeoutSeconds 600`：`20260920T031734768-40652/summary.json` 为 passed，退出0，5分类3364断言通过；before/after 均为 `C8915DDD0EADAC75C07C87C826B8BC7B8288D5007CEE9FBA1532F44CB8819FD5`。本轮铁男255全部通过，上轮遗留失败已消除。敌人循环4/16、敌人池4/24为既定日常采样，不称全项目或穷尽回归。
- 再次静态核对49份 core、27份 data、49份 UI：未发现所查 core/data→UI、非main UI→core 预载依赖或 UI直接读取game.state；UI派发仍仅在main。静态扫描的边界与完整修改前基线、结构图在忽略目录 `spire-godot/build/capture-architecture-followup/`。
- 独立只读审查 `review_capture_postures` 未发现可行动缺陷；逐路径核对日志含义保持，日志文案未新增专门断言。本轮相关文档UTF-8、链接及 diff --check 通过。未试玩、运行UI、安卓真机、提交、推送、打包或发布。

## 2026-09-20｜铁男战初始合计50

- 用户明确开场合计50：铁男30、凑数型无人机20、凑数型拘束盒20。仅调整无人机基础捕缚与该遭遇拘束盒覆盖值，普通拘束盒40、首回合跳过与后续追加数值保留。
- `tools/check.ps1 -Suite iron_man,encyclopedia -UI -UISuite home`：`20260920T032158377-30728/summary.json` passed、退出0、指纹一致；规则819、home UI134断言通过。覆盖正式开场日志30→40→50、初次跳过、下一轮65、普通盒隔离与窗口50/100。
- 独立只读复审 `review_iron_supports` 通过，diff --check通过；未扩大为整体回归，未打包发布。

## 2026-09-20 降紧固定削减捕缚与蓄力确认（Codex）

- 域：`Cards.can_target_bind/bind_payload/reason/hit/chain_candidates`、`CaptureBind.LOWER_DAMAGE/damage_bind`、捕缚动态说明与正式拖拽；不改变普通装备降紧算法。
- `20260920T032304113-8920`：guard 127断言通过。新增正例、反例及边界覆盖单层固定8、多层逐段8、进度8／10／40时归零停止、空身倍伤与henshin不影响固定伤害、3层全蓄力保留、过期版本原子拒绝、能量魔力只支付一次；普通挣扎／滑脱分别验证1层蓄力与全蓄力的加伤、消费。
- 相关规则 `20260920T032442106-11072`：witch_character、card_expansion、casting、guard通过；localization一条失败，原因是既有测试仍传入已移除的旧捕缚全文。该轮共3145断言、一条失败；UI未启动。前后指纹一致：`C42B072AA790CAB9BA2464D38FAD1971D043FB3D43540187E5B47F3D2F169CE5`，不将整轮记为通过。
- 更新文案夹具，并保留原Capture术语与下一敌方回合收押断言，增加固定8和不消耗蓄力英文断言。补验 `20260920T032636078-18180`：`-Suite localization -UI -UISuite guard`，退出0、165规则＋92窗口断言通过，`status=passed`、前后指纹一致：`C9A9A20AEBD65600E91BF3C6723E96F82AE08A6F987112270B01714134D4758A`。窗口实际拖动ease卡到左侧捕缚条，核对高亮、悬停只读、伤害和费用、无效牌及过期载荷拒绝。
- 独立只读审查 `review_bind_lower` 未发现规则阻断问题，点出的旧文案夹具失败已修正并重验。规则在第一轮组合检查后未再改变，仅调整英文测试夹具与注释。
- 本次仅源码与说明更新，未打包发布；未称完整回归或安卓真机验收。

## 2026-09-20｜玩偶师血量、普通反击与周目屏障

- 用户确认仅人偶普通受击反击降低至初级紧度2；玩偶师基础血量76。额外复合备装仍中级2档，特殊备装仍中级3档。普通反击执行与双方安装资格查询统一读取 `Puppets.ordinary`。
- 护身屏障基础每回合上限30乘原多周目生命倍率，三阶段30／45／60；`Enemies.barrier_limit` 供伤害、剩余额度、状态文案和校验统一读取。快照验证使用候选快照的倍率，保留原有共享额度、回合重置及越界拒绝。
- 更新既有实际攻击施加/额外备装、生命倍率和UI76断言，新增三周目的上限减1、转移伤害共享、耗尽后阻止、正常回合恢复、合法存取与越界回滚验证。
- 首轮 `20260920T033229483-34392` 只有1个独立主人剩余血量期望未从89调整为69，已按76基础修正。追加周目屏障后 `20260920T033527848-30728` 失败因测试误用练习后续周目，被原规则拒绝；改用正常塔路及正式 `_start_battle`，未放宽存档校验。
- 最终 `tools/check.ps1 -Suite enemies,persistence,encyclopedia,localization -UI -UISuite enemies`：`20260920T033727086-27864/summary.json` passed、退出0，前后指纹 `EB68F17C5C1A4BE7459365C7E7EF5E88FF7E9124F9F97894DF0CE61372AFF0DA` 一致。规则3722、敌人UI220断言通过，日常采样，非整体穷尽回归或安卓真机验收。
- 独立只读审查 `review_iron_supports` 未发现实现问题，指出并复核上述多周目夹具修正；最终diff --check通过。仅源码与文档变更，未打包、发布或提交。

## 2026-09-20 一点点抽出0费（Codex）

- 门禁 `20260920T034012007-37860`：`-Suite core,card_expansion`，2043断言通过、退出0、status=passed，前后指纹一致：`10ECE9132F3D1628CD84486BA2FA3085A061E3816AB3F06AC1D69D57502E3F52`。
- 隔离探针 `build/inch_zero_probe.gd`：7断言通过；两面均在0剩余能量下产生合法0费候选，卡面投影显示0，正式提交不扣能量；拘束面正常滑脱，自由面完成保留选择。
- 独立只读审查 `review_inch_zero` 通过：费用只有注册表一个来源，未发现inch专属覆盖；效果未改。未打包发布。

## 2026-09-20 一点点抽出拘束0／自由1（Codex）

- `20260920T034631897-41204`，`-Suite core,card_expansion`，2043断言通过，退出0、status=passed，前后指纹一致：`1BF2BEEA6DB37D9D3594AB906BCBF53C50AFC0F475AC677CD6F664353275BD7C`。
- 隔离探针 `build/inch_face_cost_probe.gd`，11断言通过：运行时文案与百科两面费用0／1；拘束面0剩余能量成功，自由面0剩余能量原子拒绝、1能量成功扣1，原滑脱与抽牌保留流程正常。
- 独立只读审查 `review_inch_faces` 通过；最终费用取代同日双面0费验证结论。未打包发布。

## 2026-09-20｜扫描全能王排除基础牌

- 用户明确新增限制，非修复原复制功能。`RelicBundle.copy_cards` 按注册定义的基础稀有度过滤，列表、正式候选及复制执行共用该入口；包括小魔女基础牌与脱缚练习各阶段。双面唯一能力牌及既有资格过滤保留。商店遗物、图鉴、复制面板与中英文文案同步。
- 更新旧测试以非基础「一点点抽出」保留重复实体、复制、版本回滚、快照恢复与真实UI搜索／翻面／滚动／点击覆盖；基础训练复制用例按新要求改为拒绝且永久进度不变，并补小魔女非基础专属牌仍可复制。
- 红灯：`spire-godot/build/checks/20260920T035005405-20020/summary.json` services 4/616断言失败，均为基础过滤及新文案预期。最终 `tools/check.ps1 -Suite services,localization -UI -UISuite services -TimeoutSeconds 300`：`20260920T035202345-35316/summary.json` 退出0、status=passed；规则781、窗口282断言通过，前后指纹均 `9C58A31BDE4541DE2D12BC765DCB82D51CF9A2316BE916E0B960A937139B3C2A`。
- 独立只读审查 `review_doubao_prepare_exclusion` 通过。翻译盘点完成；全量英文生成因91条未缓存源文缺少离线依赖未完成，改为仅维护本任务两条人工译文及稳定哈希ID，保留其他任务目录变动，本地化分类通过。
- 定向差异检查通过；未进行完整随机矩阵或安卓真机验收，未打包、发布或提交。

## 2026-09-20｜玩偶屏障容量扣减与AOE分组

- 单次攻击、能力群伤或遗物群伤分配局部伤害组，全部命中及玩偶转移传递同组；Puppets.barrier_trigger 每个主人只扣一次。严格超过剩余额度才扣，零伤害／恰好打满不扣；容量最低0且不积欠，余量裁剪、跨回合保留、缝补加1补满。状态、图鉴及英文组合模板同步。
- 新用例覆盖真实两段攻击、连续攻击、双主人AOE、小魔女多段群攻、拆信刀连续两轮触发、国王之赐回合末群伤、存档兼容／异常值原子拒绝及缝补。校验敏感性探针：负扣减值在生产恢复中原子拒绝，仅在内存脚本去掉该守卫后验证通过；未修改生产文件，探针退出0。
- 040932354-11164 的小魔女测试因夹具魔力100超出实际上限失败，修正为mana_max；041135470-41428 规则5137通过，UI英文组合说明失败，补全模板。独立复审发现能力／遗物AOE未分组，已修复并加上述真实触发测试。
- 042143942-25532 被其他在途DESIRE遗物测试失败及源码变动中止；042507123-32552 规则9250全部通过，UI英文断言失败且源码变动，不能作为冻结版本通过。随后独立翻译探针通过，044204422-42524 敌人UI221断言全部通过，但全局编译捕获测试覆盖签名与新增正式参数不一致，整轮仍失败。
- 仅给 architecture_cases 的 _build_escape_preview 覆盖补齐 ignore_tightness_reduction 参数及super转发，保留spy计数；独立审查确认。043748174-41940 是修正前同一签名阻断；044839814-6848 修正后被其他在途DIPLOMA测试3条失败及源码变动中止，未改这些有效断言。
- review_iron_supports 独立只读审查确认所有敌方伤害调用已覆盖分组、旧档兼容及夹具修复，无剩余实现问题。定向diff --check通过；无打包、发布或提交。
- 最终本任务定向检查 20260920T045637432-31016：enemies规则2064、敌人UI221断言通过，退出0，status=passed，前后指纹一致：A2461921774C3EA2FA071E9DFBB5E7740C204FE89A6384F1C52F9A95B54D4C44。日常采样，非整体回归；扩大范围的其他遗物测试失败见上，不据此宣称全仓通过。

## 2026-09-20 猪神之皇焚无视紧度减伤与四牌品质（Codex）

- 主入口 `escape_preview` 新参数及缓存键同源；卡牌目标、后续段与溅射沿原接口传递。新增用例覆盖普通挣扎反例、低紧度增伤、上锁／叠层保留、五段主伤与五段溅射预览／实结算一致。四牌定义、奖池与小魔女派生一致。
- 初次命令误传未注册的 lewd_magic 分类而拒绝执行（该用例已包含在 card_expansion）；改用正式分类。`20260920T045112208-41760` 旧溅射基数断言失败；同时工作区独立更新面值溅射规则，保留该变更。`20260920T045913430-38532` 新溅射断言读提交前对象，修为提交后按ID查当前装备；本轮和 `20260920T050335265-5912` 为 source_changed，不作为冻结通过证据。
- 最终规则 `20260920T050625851-41544`：localization、card_expansion、card_splash、core、equipment 均通过；architecture 有1项商店 service.refresh 新路由未同步旧枚举断言，超出本次修改范围，未删除失败用例。共3099断言，1失败，退出1，前后指纹同为 `76A5CB11F37C3DCEE01B4DBAFFAC000087E7656F657398C5BE7A8C8E76CA6905`，status=failed，不宣称全部通过。
- 隔离UI探针 `build/blaze_ui_probe.gd` 复用现有 follow_through 真实输入助手，12断言通过、退出0：新增效果文案、双面完整排版、真实拖放、五段顺延和自由面蓄力。探针禁用玩家存档，使用正常费用／低耐久多目标测试夹具。
- 独立只读审查 `review_blaze_rarities` 及面值溅射接口复核通过；未修改其他任务的玩法范围。仅源码／文档，未打包发布。
- 综合UI初轮 `20260920T050531757-7412` 为 source_changed；原范围重跑 `20260920T051005091-34668`：card_power 共383断言，仅另一张牌的 `WAR GODDESS UI seven-form cycle is read only` 失败，退出1、status=failed，前后指纹一致；本次 follow_through 文案／交互断言通过。独立探针不替代整套UI结果。最终 diff --check 通过。

## 2026-09-20｜卡面实时力量、灵巧与蓄力

- 实时卡面、逐段数值接口和波及读取统一 `Cards.face_damage_values`；基础成长、属性与蓄力共用 `Game.escape_values`。卡面按面分别取力量／灵巧，多段按普通／全量蓄力投影；不改变资源消费入口、不重复叠加主目标属性。波及使用主效果前冻结的卡面值50%，不继承辅助或墙面真实伤害，不再额外消耗蓄力。图鉴保持静态。
- 覆盖 `Game.charge_bonus/escape_values`、`Cards.face_texts/metadata/target_payload/bind_payload`、`CardSplash`、`ActionReplay` 共用候选、`Balance.card_info`、小魔女训练模板；影响映射新增 relics/card_power/card_growth/witch_character → card_splash，并由runner断言保证。
- 初轮 `20260920T045635048-18784` 五分类6/4398失败：三条毕业证用例比较字典时尚未包含新增只读face_value、一条新主目标断言读取提交前旧对象；修正测试后按原目标验证全部字段和正式提交后状态。另两条DESIRE奖励失败属于其他在途改动，未改动它们。
- 扩展检查 `tools/check.ps1 -Suite card_splash,card_growth,witch_character,card_expansion,relics,equipment,basic_attacks,casting,guard,persistence,encyclopedia,architecture,runner -UI -UISuite card_splash -KeepGoing -TimeoutSeconds 300`：`spire-godot/build/checks/20260920T050608694-3968/summary.json`，13规则分类8133断言中3失败，退出1；前后指纹均 `76A5CB11F37C3DCEE01B4DBAFFAC000087E7656F657398C5BE7A8C8E76CA6905`。11分类通过，relics中2条DESIRE Boss奖励断言失败；architecture中路由预期未列service.refresh，1条失败。窗口阶段因此未运行；不能称整轮全绿。
- 独立只读审查 `review_doubao_prepare_exclusion` 未发现本次生产改动阻断问题，并核对上述3条失败不在伤害／卡面调用路径：两条检查Boss领取后的卡组／主题遗物，另一条为未修改的路由注册表与旧预期不符。这是源码与日志归因，没有撤销增量重跑的隔离证明；其他任务文件保持。
- 补充实际多段正式提交，检查主效果和波及的逐段值与显示数组逐项相等；普通与全量模式均检查一次支付、蓄力消费和过期版本回滚。窗口检查读取真实卡牌控件文字并原生拖放。最终 `-Suite card_splash,localization -UI -UISuite card_splash`：`20260920T051244516-15240/summary.json`，退出0、status=passed，330规则＋14窗口断言通过，前后指纹均 `D858E443332D7D8599860CA2891A2EDF067A3B06CC3E94F002A5E972D09A82A6`。此前单独窗口 `20260920T051028569-43492` 14通过，最终轮已取代其本域证据。
- 未做完整随机矩阵或安卓真机验收；仅源码、测试和文档，未打包、提交或发布。

## 2026-09-20 商店品质基础售价提高（Codex）

- 只调整 `RoomServices.CARD_PRICES/RELIC_PRICES` 三档价格；候选、显示、支付、会员卡折扣和冻结库存沿现有通道。现有 rarity_prices 正式购入覆盖三档卡牌／遗物及两种付款来源，会员卡／M当劳／扫描全能王覆盖不足、足额、过期版本、不可混付、半价及重复消费边界。
- 初轮 `20260920T051918251-26328` 扫描全能王夹具仍按65准备魔瓶，触发5断言及后继脚本错误；同步69不足／70足额后，`20260920T051959754-41100` 规则 services 643断言通过。该轮UI3断言仍用旧35余额，按100－70改为30；该轮前后源码指纹一致，规则结果有效，整轮因UI失败记 failed。
- 最终只复跑受影响UI：`20260920T052130551-35112`，`-UIOnly -UISuite services`，288断言通过、退出0、status=passed、前后指纹一致：EC433D08B58739F8B158C089ADC61D84DABA4346AEC40EB1E3E521DAFBAB5E2B。
- 独立只读审查 `review_shop_base_prices` 通过；最终 diff --check 通过。本次仅源码与文档，未打包、发布或提交；非完整回归或安卓真机验收。

## 2026-09-20 整备魔瓶存三次／取不限（Codex）

- `ManaFlask.limit` 仅增加 prepare＋deposit 分支，复用候选、计数提交、每回合重置和界面限额投影。更新原整备无限存取用例，覆盖正常战后及反抗守卫后的整备：三存成功、第四存原子拒绝、快照保留次数、五次取出成功、不推进回合、不返还存入次数、真实结束回合恢复三次；UI通过实际点击验证计数点、按钮和余额。
- `tools/check.ps1 -Suite consumables -UI -UISuite consumables -TimeoutSeconds 300 -KeepGoing`：`20260920T052923731-40416/summary.json` status=passed、退出0，规则328＋UI65断言通过，前后指纹均 `AB5F9BF55F67F2A564CE6B0CE2DE2C725E47893E500AA97615D9CD022D2BAF54`。
- 独立只读审查 `review_prepare_flask` 通过；最终 diff --check 通过。仅源码与文档，未打包、发布或提交，未作全量回归或安卓真机验收。

## 2026-09-20｜商店文案路由与Boss主题奖励校验维护

- 跟进新增商店刷新与卡牌品质调整，核对 `RoomServices.paid_candidate → CopyRouter → refresh_detail` 和 `RelicEffects.gain → reward_offer/RelicRewards.offer`。既有正式提交、支付与奖励生成入口满足本次契约，不新增生产接口或改动玩法；保留任务开始时86份在途修改。
- 初轮 `tools/check.ps1 -Suite architecture,relics -KeepGoing -TimeoutSeconds 600`，`20260920T053701157-5876` 稳定指纹、3/2420失败：路由类别白名单缺少service.refresh，以及双角色Boss赠卡仍指定已降为罕见的desire_rune。均为实际复现，非根据历史日志猜测。
- 更新原类别白名单与文案站点校验：刷新真实候选经注册路由与哨兵回退值对照，并验证读取不改库存、支付、随机等状态。Boss赠卡校验按新增UID确认永久心痒难耐及同一张手牌，另一张必须是角色兼容的rare＋lewd_magic；不将某次随机型号固化为规则。随机开局Boss交换复用该断言，补齐原有基础牌身份保留；双角色、遗物数量、旧版本拒绝、重复领取、满手弃牌与恢复覆盖保留。
- 最终 `tools/check.ps1 -Suite architecture,relics,services -KeepGoing -TimeoutSeconds 600`：`20260920T053848132-25028/summary.json` 为 passed、退出0，3071断言通过；before/after 均为 `56044E1A90EF91FB5866DA9DDDC45B20E118555920AA919AFC0F5030591195FE`。本轮范围内无遗留失败，不称全项目回归。
- 敏感性：隔离引擎进程内移除service.refresh路由，既有站点对照准确报错；Boss赠卡夹具的合法奖励通过，将赠卡改为错误品质desire_rune或非主题稀有shared_fate均使对应断言失败。正式源码未变异，探针已清理，日志保存在忽略的 `spire-godot/build/reward-routing-maintenance/sensitivity.log`。
- 静态依赖扫描49份core、27份data、49份UI，未发现所查禁止预载或UI直接读game.state，UI派发仅在main；不把静态扫描当全项目行为验收。修改前基线、结构图及扫描证据同在上述忽略目录。
- [按需文案契约](../spec/ondemand-copy.md) 补充新路由接入证据要求、修正SUITE RESULT格式，删除固定历史失败名单的豁免；失败必须按当前运行报告，不能沿用旧红灯作为许可。
- 独立只读审查 `review_reward_routing_checks` 对两份测试增量无可行动问题，确认没有降低契约或删除有效失败覆盖。文档UTF-8、新增链接与 diff --check 通过；未试玩、运行UI、安卓真机、提交、推送、打包或发布。

## 2026-09-20｜v0.18.1 发布验收

- 用户明确要求推送0.18.1，沿原交付方式提供Windows／Android，双层加密包仅PC、不上传GitHub。继续遵守“不用试玩”：本次不运行normal_play或UI交互回归，未做安卓真机验收。
- 版本：project与两平台预设0.18.1；Windows文件／产品版本0.18.1.0；Android code13，原发布签名证书SHA256保持 `9da2962a178eec7a6be1bb45c77c37372c0f18c2f2efe313e3f8aad07cdd0608`。版本专属说明、根更新日志及现行打包契约同步。
- 规则初轮：全部51个非试玩分类，以 `-Exhaustive -KeepGoing` 执行，`20260920T054831561-40660` 2/29034失败，49分类通过；两条均为旧断言。before/after均 `B0D8D6353F805A8D7AB6F5EFC2A31D3D27629F5C7345FB342C21755A149E2901`，整轮记failed，不称通过。
- 校验修订：链接端点波及期望改读正式冻结的卡面值，保留真实提交、蓄力消费、选中端点与另一端隔离；监狱双杯夹具移除被杯具降值取代的固定110.52历史前提，保留所有迁移、组件清除、伪造拒绝、30步巡视／回充及可行动断言。当前杯具数值与卡面数值另有独立分类覆盖。没有修改玩法或新增旧档适配。
- 按 `-RerunFailed` 续跑links／prison：`20260920T055537651-40752` 1554断言全通过、退出0；before/after均 `603AF9AD9FE94D38753858AE3715D9A7FE1035EAD0962DDAE73F79D0E68188E2`。按各分类最新有效结果汇总51分类29033条全部通过，保留完整随机样本；这是两次运行合并证据，不是单轮全绿。汇总在 `spire-godot/build/release-v0.18.1/rules-evidence.json`。
- Windows输出 `outputs/spire-v0.18.1-windows-x64-release-20260920-0181`，发布EXE无界面启动与PCK资源检查均通过，证据 `build/package-check-20260920T055720550`。Android输出 `outputs/spire-v0.18.1-android-release-20260920-0181`，清单／签名／16KB对齐及12份内置内容包检查通过，APK资源探针 `build/android-probe-20260920T055759513` 通过；无内容模板、测试、工具或签名秘密入包。
- 两平台524份导出输入逐文件比较，仅内容包根为既定平台差异，Android输入全部匹配当前工作区，Windows根差异也按字节重算核对；源码已恢复res根。证据 `build/release-v0.18.1/export-equivalence.json`。
- 最终交付 `outputs/release-v0.18.1-20260920-final`：Windows ZIP、Android ZIP／APK、公开说明及SHA256清单；另有仅PC的双层7z，两层密码与加密文件名均验证，错误密码被拒绝，两次实际解压后25份PC文件哈希一致且无APK。普通ZIP亦实际解压逐文件比对。证据 `outputs/verify-v0.18.1-20260920-final/verification.json`；上传器白名单只允许5项公开附件，排除7z。
- 独立只读审查 `review_release_0181` 初审配置、说明、源码／秘密边界及两处旧校验修订均通过，成品复审另见后续条目。包内明确记录此前card_power UI七形态旧断言未复验；不宣称窗口、安卓真机或性能验收通过。

- 最终独立成品复审通过：复算六项交付文件及两ZIP解压树、Windows清单、双层解压25份PC文件哈希；确认APK开发目录排除、12正式内容包、版本／原签名、包内说明和五项公开上传白名单均一致，无发布阻塞。

## 2026-09-20｜合并上游 v0.18.1（`b7aa046`）到分支 `seed-chip-save-upload`

域：本分支合 `origin/main`（v0.18／v0.18.1，两提交、428 文件、+15549/−1149），两侧都保留——上游的玩法与架构维护、验证刷新、美术与音频；本分支的种子角标（`state.initial_seed`／`SeedChip`／`SaveStore.fixed_point_text`）、反馈附带当前进度存档（`include_save`／原因码／`schema>=2` 门控）、本局回顾面板（`ui/run_review.gd`／`route_map.read_only`／`ui/main.gd` 两处 `OpenRunReview`）。冲突 10 文件：`docs/record/{changelog,verification}.md`、`docs/spec/{feedback-deployment,save-fixed-points}.md`、`assets/localization/{zh_CN,en_US}.json`、`core/game.gd`、`core/game_view.gd`、`ui/feedback_report.gd`、`ui/main.gd`；逐项处置与理由见本次合并提交信息。检查前先按新增素材做了导入（`--headless --editor --quit`，退出 0）。

- 规则门 `tools/check.ps1 -Suite persistence,content,application,architecture,runner,localization -KeepGoing -TimeoutSeconds 1800` → 退出码 **0**、6/6 PASS、`PASS: 2858 assertions`（`build/checks/20260920T164452551-14432`；`summary.json.status=passed`、`before==after==43694C5D…`、`unrun=[]`、无 `SOURCE CHANGED`）。逐分类 localization 165／application 71／architecture 507／content 580／runner 536／persistence 999。
- 窗口门 `tools/check.ps1 -UIOnly -UISuite route,localization,interface -TimeoutSeconds 1200` → 退出码 **1**、`UI FAIL: 713 assertions`（`build/checks/20260920T164605377-20092`；`status=failed`、`before==after==43694C5D…`（与规则门同一冻结源码）、`unrun=[]`、无 `SOURCE CHANGED`）。逐分类 localization 51 PASS／route **253** PASS／interface **409** FAIL。
- 红项（全部来自上游新增内容；本分支断言与本次冲突处置未新增红）：`interface` 的既有登记项 `CARD ART every registered card has an illustration`（缺立绘 28→**35** 张 `witch_*`，新增 7 张＝`witch_itching_heart`／`witch_self_satisfaction`／`witch_psychological_suggestion`／`witch_rally_spirit`／`witch_desire_rune`／`witch_forced_edging`／`witch_forced_climax`，经 `git grep HEAD` 核对只在上游侧存在）；以及同域新红 `CARD ART illustrations are nonempty and distinct except the magic-hand gift variant`（6 张上游新卡 `self_satisfaction`／`psychological_suggestion`／`rally_spirit`／`desire_rune`／`forced_climax`／`forced_edging` 共用 `assets/ui/cards/desire_magic.svg` 且未声明 `art_source`）。两条均源自上游 `ui/card_face.gd` 的新条目；上游 v0.18.1 发布说明称未安排 UI 回归。**本片未清这两条**：清除需要绘制／声明这 7 张卡的立绘（内容决定）或放宽该断言（禁区），留待裁定。
- 断言更新（语义仍成立、上游新规则使其失效）：`tests/interface_ui_cases.gd::feedback_save` 的 `FEEDBACK restored draft captures at its first use` 原断言「恢复的 `draft.context` 逐键不变」与上游新增的「重新打开跨版本草稿刷新 `context.version` 并清除旧提交编号、保留原场次」冲突；改为断言「捕获一次、原场次（`phase`／`scene`／`floor`／`round`／`seed`／`platform`）不变，只有 `version` 跟随本次构建」。同场景的附件字节不变、捕获时点与「不冒充没有存档」断言未改。
- 首轮窗口门（`build/checks/20260920T163745133-8768`）报 `SOURCE CHANGED`：运行期间 `core/content_catalog.gd` 的行尾被外部重写（归一化后与 HEAD 逐字相同、`PACKS_ROOT` 仍为开发值 `res://content/packs`，`git status` 干净），该轮不计通过；改断言后按原范围重跑，两门落在同一指纹 `43694C5D…` 且 `before==after`。
- **待裁定（本片未改）**：`docs/design/game-design.md` 的恢复条目（`只接受当前 Snapshot.REVISION`／`其余不做迁移`，本分支在上游同句基础上加了 `initial_seed` 单点回填）与 `core/game.gd::restore_snapshot` 保留的上游三档旧修订迁移链（`Snapshot.REINFORCEMENT_STATE_REVISION`／`CUP_STACK_REVISION`／`IRON_DRONE_REVISION` → `Snapshot.migrate_cup_stacks`／`migrate_iron_drone`，上游记录见本文件 2026-09-20「杯类唯一名额、旧档与监狱循环」）表述不一致；上游自己的 v0.18.1 树同样是该句旧措辞，故这是上游既有文档债、不是本次冲突处置引入。改这句等于改现行契约口径，交回规划者／协调者裁定。
- 未跑（按本片边界）：`-Suite all` 全量回归、oracle、像素判据、性能测量、打包与发布（`tools/package*.ps1`）、Android 真机与触屏；窗口分类只跑 `route`／`localization`／`interface`，其余窗口分类未跑，不能据此宣称它们通过。本次只提交合并，未推送、未打标签、未改版本号、未打包。

## 2026-09-20 铁男开场打断（Codex）

- 复现根因：`CaptureBind.required_intent` 对铁男始终返回空，`observe` 在打断后把原开场 bind_apply 重新生成并清掉 delayed。复用 `IronMan.intent_facts` 返回仍需要的开场捕缚，保留同一意图，不改变五步循环计划时机。
- 红灯证据 `20260920T102109772-37424`：iron_man 375断言中8失败，均对应两角色stage1打断未保留／读档丢失／未停顿及后续阶段不符；其余五步循环用例通过。
- 修复后 `tools/check.ps1 -Suite iron_man,guard -TimeoutSeconds 300 -KeepGoing`：`20260920T102148920-45344`，502断言通过、退出0、status=passed；前后指纹一致 `65478BEFCCC84F82156F8315CA9E62ABE8336F29562A0FD454C5163BE776704A`。覆盖原角色灌注手部攻击、小魔女腿部释放的真实派发，stage1—6打断、只读、快照、延后一回合且不推进，再恢复行动；既有捕缚100收押延期和发呆破甲用例仍通过。
- 独立只读审查 `review_iron_opening_interrupt` 通过，包含stage1发呆优先级静态边界检查。最终 diff --check 通过。未改UI，未做完整回归、打包发布或提交。

## 2026-09-20 铁男打断 v0.18.1 Windows 替换补丁（Codex）

- 用户明确请求替换文件补丁。基线为 `outputs/spire-v0.18.1-windows-x64-release-20260920-0181`。通过正式package脚本导出 `spire-v0.18.1-windows-x64-iron-interrupt-20260920`；PACKS_ROOT仅导出期间临时设adjacent，finally逐字节恢复。首轮替换表达式因空格格式不符拒绝，未开始导出；按实际声明重试成功。
- 两次正式source-manifest逐项比较，运行时仅core/capture_bind.gd差异；发布EXE SHA256一致。正式发布资源、隔离存档探针及EXE启动检查通过，日志 `build/package-check-20260920T102720608`。
- 成品专用探针 `build/iron_patch_probe.gd` 直接加载导出PCK，双角色实际打断、快照、跳过开场及下回合恢复共11断言通过。首次main-pack相对路径误用，资源加载失败后终止；改绝对路径后退出0。
- 补丁ZIP仅含紧缚尖塔.pck、manifest.json、补丁说明.txt、SHA256SUMS.txt。说明指定Windows v0.18.1，退出游戏备份并覆盖两个文件，保留原EXE/content与存档，不追溯补发旧版已丢失打断；披露未重跑完整回归/UI及原版验证边界。
- 最终 `outputs/紧缚尖塔-v0.18.1-铁男打断修复补丁.zip`，115409727字节，SHA256 `56569e6883b1672da3d526f62072a892865ee3fd409476c85d9e00d617033f02`。实际解压覆盖原包的独立副本，四文件逐项SHA相同；覆盖后check-package通过，日志 `build/package-check-20260920T102936314`。原发布包未改写，未上传或发布Release。
- 独立只读交付审查 review_iron_patch_package 通过：ZIP四文件、内部及外部SHA、覆盖后清单24项、EXE/PCK日志和适用版本说明均核对；最终 diff --check 通过。


## 2026-09-20 火动力学正式卡图（Codex）

- 用户提供图片清除元数据后接入 `DisplaySettings.FORMAL_ART.cards.fire_dynamics`。PNG仅保留IHDR／IDAT／IEND，1920×1920；原图与成品IDAT逐字节一致。原下载文件未修改。
- `tools/check.ps1 -Import -UIOnly -UISuite encyclopedia`：证据 `spire-godot/build/checks/20260920T131610445-35044`，导入成功、图鉴172断言通过、退出0、status=passed；before／after同为 `49B54064CA7BF98361B54296D2B83BDF3422EE35616AB8F9116410053E53FD77`。
- 独立只读审查 `review_fire_art` 通过：核对PNG各块CRC、像素块一致性、导入配置与正式／测试版共享选择通道。既有图鉴检查覆盖共享通道，未专门做火动力学截图视觉验收。按用户要求未跑全量；未打包、发布或提交。


## 2026-09-20 henshin正式卡图（Codex）

- 上传PNG原已仅含IHDR／IDAT／IEND；本地过滤后与原图逐字节相同，1920×1920，全部CRC通过。普通henshin与完美henshin共用正式图，保留测试版选项。
- Godot 4.7.2无界面导入退出0；一次性资源探针核对两变体默认正式、1920纹理路径及切换测试版后的回退，退出0。证据 `spire-godot/build/henshin-art-import.log`、`spire-godot/build/henshin-art-probe.log`。
- 独立只读审查 `review_henshin_art` 通过，diff --check通过。按用户要求只做素材定向检查，未跑全量、未做截图视觉验收，未打包发布或提交。


## 2026-09-20 身轻如燕正式卡图（Codex）

- 用户提供 `00130-3456336496.png`，本地移除tEXt元数据；成品1920×1920，仅IHDR／IDAT／IEND，全部CRC与原图IDAT一致性检查通过。SHA256 `e64fa6866d55ca6e4bc99ba7805194bd00c6077bfba0cb78bf6d32a67bc49f64`。普通版与般若汤赠送版共用正式图。
- Godot 4.7.2无界面导入及两变体资源探针退出0；核对正式默认、纹理路径与尺寸、测试版回退。证据 `spire-godot/build/swallow-art-import.log`、`spire-godot/build/swallow-art-probe.log`，无脚本错误。
- 独立只读审查 `review_swallow_art` 通过；本次素材／映射差异检查通过。未跑全量，未做画面视觉验收、打包发布或提交；不覆盖其他任务在途UI修改的验证结论。


## 2026-09-20 魔力回路正式卡图（Codex）

- 用户上传PNG本地去除tEXt；成品1920×1920、仅IHDR／IDAT／IEND，全部CRC及原图IDAT一致性通过。SHA256 `13d8df0a1df395293f4cd8462ceac1f82dfc0c24c5dfcd835d205f45d0b780c1`。沿既有正式卡图映射接入mana_circuit。
- Godot 4.7.2无界面导入与资源探针均退出0，核对默认正式纹理路径／尺寸以及测试版回退；证据 `spire-godot/build/mana-circuit-art-import.log`、`spire-godot/build/mana-circuit-art-probe.log`。
- 独立只读审查 `review_mana_art` 通过；本次差异diff --check通过。仅素材定向检查，无全量回归、视觉验收、打包、发布或提交；不覆盖其他在途UI任务。

## 2026-09-20 卡牌窄版、图鉴放大与关键词底栏（Codex）

- `CardFace.dimensions → main._card` 统一约5:8比例，普通页面保留牌高；手牌间距、商店居中、容器最小尺寸、牌库枢轴及转移动画使用实际卡面尺寸。图鉴为300×480，按大字号原生重绘，未缩放卡面截图。保留其它任务在途素材与正式画风映射。
- 关键词追加需求沿既有face_keywords分离独立关键词句，固定在底部整词排版，正文及条件滚动区避让；效果句中出现关键词不被截走，翻面和动态保留同步更新。图鉴静态值检查改为核对正文与底栏合并后的完整句子，未改费用、效果或资源规则。
- 开发中首轮 `20260920T132700433-33572` 超时且source_changed，不算通过。收窄阶段冻结轮 `20260920T133241485-40620` 跑完2235断言但失败；除既有断言外，targeting用例遗留layout.scale=0.85及position造成后续固定坐标点击与遗物悬停失败，不能作为相关交互通过证据。
- 最终运行时冻结指纹 `DC5F810F912EAD69B3F06C0DB7AFF501D1E4CA443E0F01486F931A7BFA57A1C3`，三轮before/after一致：`20260920T134358131-29532` 的encyclopedia172、display141、route134、services288、targeting107通过；`20260920T134651818-39460` 的touch23、keyboard87通过；隔离targeting状态后 `20260920T135005404-39460` 的events180、rewards358通过，interface364仅剩2条旧美术断言，点击、滚动、拖放及正文/关键词边界断言通过。
- card_power383断言剩战神七形态旧断言与魔术手原“降紧3。超级顺延”连续文本断言。后者按本次关键词分区要求更新为精确正文＋底栏检查，费用、品质与真实支付/施放不变；只改测试文件后，`build/card_keyword_contract.gd` 定向复验14断言通过、退出0（`build/card-keyword-contract.log`）。不把整轮card_power或interface宣称为通过；最终仍有战神1条与美术映射2条既有失败。
- 基线证据：`build/card-art-baseline.log` 核对HEAD与当前ILLUSTRATIONS完全相同，复现角色2 art_type别名没有直接键及共用魔法图违反旧唯一性断言；`build/card-baseline-ui.log` 用HEAD界面实现复现同2条美术失败，独立interface/events点击正常。未修改这些旧失败或删除案例。
- 定向视觉/布局探针 `build/card-portrait-preview.log`：全部注册卡牌双面、252/290/480三种牌高无标题裁切；正文滚动、关键词贴底/整词、效果句反例及紧缚爱好完整显示检查通过（后者正文107高、可用108）。探针总体仍因上述2条旧美术断言退出1，未宣称整探针绿灯。实际图鉴截图 `build/card-portrait-encyclopedia.png` 已目检：原图1920×1920完整适配大卡面，“唯一”单独显示在底部。
- 独立只读审查 `review_narrow_cards` 完成初审、关键词补审及魔术手测试更新复审，未发现新增缺陷；最终diff --check通过。仅修改源码/测试/文档，未做完整规则回归、安卓真机验证、打包、发布或提交；先前铁男替换补丁未被覆盖。


## 2026-09-20 火焰精通正式卡图（Codex）

- 用户图 `00133-803601954.png` 本地去除tEXt元数据；成品1920×1920、仅IHDR／IDAT／IEND，全部CRC及原图IDAT一致性通过。SHA256 `c8276165283ac80c820625764d74d9a078572ee732e04edcb472ee081756c5b7`。复用FORMAL_ART.cards.fire_mastery接入。
- Godot 4.7.2无界面导入和资源探针退出0，核对默认正式纹理路径／尺寸及测试版回退；证据 `spire-godot/build/fire-mastery-art-import.log`、`spire-godot/build/fire-mastery-art-probe.log`。
- 独立只读审查 `review_fire_mastery_art` 通过，素材／映射diff --check通过。仅定向素材检查，未跑全量、未做视觉验收、打包发布或提交；其他在途UI不在验证范围。

## 2026-09-21｜文档门禁：规则类文档入源码指纹＋引用检查（`docs/` 不再零守卫）

域：`spire-godot/tools/check.ps1::Get-SourceFingerprint`（新增规则类文档条目）、新增 `spire-godot/tools/check-docs.ps1`（引用门禁）与 `spire-godot/tools/doc-scan-scope.ps1`（范围与排除理由的唯一声明）、`.zcode/skills/repo-ops/SKILL.md`（命令面）、`.zcode/skills/spire-docs/SKILL.md`（「已知零守卫」节改写为「文档守卫」）、根 `AGENTS.md`（技能索引改用同词）。产品代码（`core`／`data`／`ui`／`content`／`assets`／`tests`）、`docs/spec/**` 正文、版本号零改动（`git status --short` 只有上述 4 改 2 新）。

- 范围（唯一声明 `spire-godot/tools/doc-scan-scope.ps1`）：规则类＝`docs/spec/**`、`docs/design/**`、`docs/guide/**`、根 `AGENTS.md`、`.zcode/skills/**/*.md`，本片实测 **32 份**文档。排除并写明理由：`docs/record/**`（只追加记录、每次验证写入都 churn，含 `docs/record/proposals/**`）、`docs/history/**`（只读归档）。
- 判据一（指纹纳入，`tools/check.ps1 -Suite architecture -ListOnly` 取 `summary.json` 的 `before`）：基线 `20260921T053104358-14452` → `82B98233…`；把 `docs/spec/project-map.md` 正文两处 `docs/spec/packaging.md` 改为 `docs/spec/packaging-missing.md`（`spire-godot/` 下零改动）后 `20260921T053220308-21168` → `69152F58…`（**变了**）；`git checkout` 还原后 `20260921T053228700-29232` → `82B98233…`（回到基线）；`docs/record/verification.md` 追加一行后 `20260921T053211461-29040` → `82B98233…`（**不变**）。规则类纳入与记录类排除都可观测。
- 判据二（引用门禁，四条敏感性证明，均「改坏即红、还原即绿」，退出码 0／1；最终树上重跑，脚本 `spire-godot/build/sensitivity-final.ps1`，一次性已清理）：①点名路径——`docs/spec/project-map.md` 的 `docs/spec/packaging.md` 改为 `docs/spec/packaging-missing.md` → `DOC FAIL … (named path does not exist)`×2、exit 1；还原 → `DOCS PASS: 32 rule-class document(s), 1093 reference(s) checked, allowlist 8 entrie(s)`、exit 0。②符号锚点——`docs/design/prison.md` 的 `data/tower.gd::prison_route` 改为 `data/tower.gd::prison_route_moved` → `DOC FAIL … (symbol is not declared in the anchored file)`、exit 1；还原 → PASS。③本地 md 链接（改链接）——`docs/design/character-two.md` 的 `[淫魔法卡池](cards.md)` 改为 `[淫魔法卡池](cards-missing.md)` → `DOC FAIL … (relative link target does not exist)`、exit 1；还原 → PASS。④本地 md 链接（删目标文件）——删 `docs/design/prison.md`（`docs/design/game-design.md` 的 `[监狱设计](prison.md)` 目标）→ `DOC FAIL: AGENTS.md: docs/design/prison.md (named path does not exist)` ＋ `DOC FAIL: docs\design\game-design.md: prison.md (relative link target does not exist)`、exit 1；还原 → PASS。阳性对照：`docs/record/verification.md` 追加一行 → 门禁 `DOCS PASS`、exit 0 且指纹保持基线不变，证明记录类是被显式排除、不是整片漏扫。
- 允许清单（**8 条**，逐条带理由与消掉条件，检查每次打印条目数；本片实测 8 条全部被引用、无未用条目）：`core/candidate_deps.gd`／`ui/candidate_delta.gd`／`tools/candidate-deps.ps1`（`docs/spec/candidate-delta.md` 头注自报未落地）＋`tools/check-index.ps1`／`tests/check_index.json`／`tests/check_index*.gd`（未落地的「检查路由」片）＋`spire-godot/tools/play_release.ps1`（`docs/spec/run-review.md`／`run-review-dependencies.md` 引用的未入库协调者脚本，已移出树，现入口为 `play-release.cmd` 与 `release/`）＋`docs/ondemand-copy.md`（**真实失效引用**：实际文件为 `docs/spec/ondemand-copy.md`；本片不得改 `docs/spec` 正文，交回规划者修正）。前 7 条随对应片落地消掉。
- 既有门禁复跑（最终树，窗口门为真实窗口、非沙箱）：规则门 `tools/check.ps1 -Suite architecture,localization -KeepGoing` → 退出码 **0**、2/2 PASS、`PASS: 672 assertions`（`build/checks/20260921T053534604-22544`；`status=passed`、`before==after==DEA47A3E…`、`unrun=[]`、无 `SOURCE CHANGED`；architecture 507／localization 165）。窗口门 `tools/check.ps1 -UIOnly -UISuite route,localization` → 退出码 **0**、`UI PASS: 304 assertions`（`build/checks/20260921T053603146-21192`；`status=passed`、`before==after==DEA47A3E…`、`unrun=[]`；route 253／localization 51）。**本片新增红 0**。既有登记红项（`CARD ART` 缺立绘所属的 `equipment_art`／`hero_art` 与 `wall` 分类）不在本次分类范围内，未跑，也未声称通过。
- 已知边界（本门禁不覆盖、仍靠人审）：删掉依赖表行而其余行仍成立（要抓需以实现文件面为第二真源）；`build/`／`outputs/` 路径按设计跳过（不入库的运行期证据与产物，`docs/spec/project-map.md` 明写）；md 标题锚点（`#片段`）只校验目标文件；非 GDScript／PowerShell 的符号锚点只校验文件存在。
- 未跑：`-Suite all` 全量回归、`-Impact`／`-Exhaustive`、oracle、像素判据、性能测量、打包与发布（`tools/package*.ps1`）、Android 真机；窗口分类只跑 `route`／`localization`，其余窗口分类未跑。`check-docs.ps1` 是独立命令，**未接入 `check.ps1` 的自动阶段**（即「改规则类文档后自动跑引用门」尚未接线，命令面见 `.zcode/skills/repo-ops/SKILL.md`）。本片只提交源码与文档，未推送、未打标签、未改版本号、未打包。
- 指纹宿主差异（本片发现；改前改后同样存在，非本片引入）：同一工作树在 `pwsh` 7 与 Windows PowerShell 5.1 下算出的指纹不同——旧算法实测 `55A4FF3D…`（pwsh）vs `4C690F77…`（5.1），新算法 `DEA47A3E…`（pwsh）vs `6F95384B…`（5.1）；来源是 `Sort-Object` 的排序规则（ICU 与 NLS）不同。故指纹只作**同一次运行内**的守卫，跨宿主／跨工作副本的数字不可对账（与 `.zcode/skills/spire-docs/SKILL.md` 的既有口径一致）。本片全部指纹证据均为 `pwsh` 7 下取值；两宿主下 `check-docs.ps1` 结果一致（`DOCS PASS: 32 … 1093 reference(s) … allowlist 8 entrie(s)`）。

## 2026-09-21｜文档门禁接入主门禁＋指纹改序数排序（宿主无关）

域：`spire-godot/tools/check.ps1`（新增文档阶段 `Get-DocumentPhaseSummary`、`DOCS RESULT:` 结果行与 `summary.json` 的 `docs` 字段；`Get-SourceFingerprint` 改序数排序）、`spire-godot/tools/check-docs.ps1`（允许清单删两条已消条件的条目，8→6）、`.zcode/skills/repo-ops/SKILL.md`（命令面一句）。提交 `1453748`（阶段接入＋序数排序）＋本次记录所在提交（清单收缩与记录）。产品代码（`core`／`data`／`ui`／`content`／`assets`／`tests`）、`docs/spec/**` 正文、版本号零改动。

- 接入形态（对齐内容包校验的独立阶段）：文档阶段在 `import`／规则门之前运行（不依赖引擎），日志 `build/checks/<运行号>/check-docs.log`，结果行 `DOCS RESULT: PASS|FAIL`，失败即 `throw` 整轮失败。扫描范围仍只有一份声明（`tools/doc-scan-scope.ps1::Get-RuleDocFiles`），阶段内不重建文件列表；允许清单条目数每轮打印，本条为 **6 条**——同日旧条目里的「未接入自动阶段」与「允许清单 8 条」由此条取代（记录只追加，不改写旧条目）。失败轮 `docs.documents`／`docs.references` 为 `null`（门禁只在成功行给出这两个计数），不写成 0。`-ListOnly` 下文档阶段照跑（门禁自身只读）。
- 敏感性证明（跑**完整**主门禁，不是只跑 `check-docs.ps1`）：把 `docs/spec/project-map.md` 表内 `spire-godot/project.godot` 改成 `spire-godot/project-absent.godot` → `& tools/check.ps1 -Suite architecture,localization` **退出码 1**（`build/checks/20260921T054926430-13080`）：`DOC FAIL: docs\spec\project-map.md: spire-godot/project-absent.godot (named path does not exist)`、`DOCS FAIL: 1 unresolved reference(s) in rule-class documents; allowlist 6 entrie(s)`、`DOCS RESULT: FAIL`、`Rule-class document gate failed (exit=1). See …\check-docs.log`；`summary.json` 为 `status=failed`、`docs.status=failed`、`docs.problems=1`、`docs.allowlist=6`、`rules.unrun=["architecture","localization"]`（文档红先于规则门失败，那两个规则分类未跑）。`git checkout` 还原后复跑同命令 **退出码 0**（`build/checks/20260921T054933989-19800`）：`DOCS RESULT: PASS`、`SUITE RESULT: localization PASS`、`SUITE RESULT: architecture PASS`、`PASS: 672 assertions`、`status=passed`、`before==after==C2E48624…`、`rules.retry=[]`、无 `SOURCE CHANGED`。
- 接入后完整门禁的新增字段原文（同上绿轮）：`DOCS PASS: 32 rule-class document(s), 1110 reference(s) checked, allowlist 6 entrie(s)`；`"docs": {"status":"passed","complete":true,"documents":32,"references":1110,"problems":0,"allowlist":6,"log":"…\\check-docs.log"}`。
- 指纹宿主差异修复（判据：两宿主取值相等，且同一次运行内 `before==after` 仍成立）：拼接顺序由 `Sort-Object`（宿主文化排序，ICU／NLS）改为 `[Array]::Sort($entries.ToArray(), [StringComparer]::Ordinal)`；条目内容与集合不变。改前实测（同一会话、planner 正在并行改文档）：`pwsh` 7 读 `DEA47A3E…`（该次工作树干净）、5.1 读 `038516C8…`——两次相隔约 11 秒且期间文档被外部改写，故另用一次性探针在同一**冻结**文件集上直接对比两种排序：753 条同一输入下 `Sort-Object` → `pwsh` `0DD9DF27…` vs 5.1 `2302ED3A…`（**不同**），序数排序 → 两宿主同为 `A20CA1FB…`（**相同**，且与改后首两轮真门禁 `-ListOnly` 的 `before` 逐字一致：`20260921T054519279-17816`／`20260921T054532961-30684`）。探针 `spire-godot/build/docgate-host/fingerprint-order-probe.ps1`（范围取自 `doc-scan-scope.ps1`，一次性、不入库、已清理）。
- 改后两宿主实跑（`& tools/check.ps1 -Suite architecture -ListOnly`，只读）：`pwsh` 7 `build/checks/20260921T054840962-30932`、Windows PowerShell 5.1 `build/checks/20260921T054846477-4256`——两轮 `before` 同为 `C2E48624…`、各自 `before==after`、`status=plan`、`DOCS RESULT: PASS`；两次运行之间 7 份门禁输入（`docs/spec/run-review.md`、`docs/design/game-design.md`、`docs/spec/run-review-dependencies.md`、`docs/spec/project-map.md`、`tools/check.ps1`、`.zcode/skills/repo-ops/SKILL.md`、`tools/check-docs.ps1`）的 blob 哈希逐条相同，确认两宿主读到同一文件集。同一源树的整轮全门禁（绿轮 `20260921T054933989-19800`）也是 `C2E48624…`。
- 允许清单收缩（协调者插单）：planner `ff4aae2` 把 `docs/ondemand-copy.md` 与 `play_release.ps1` 两处契约引用改成现行入口后，两条条目已无人引用（删除前每轮打印两条 `DOC NOTE: declared-missing entry is no longer referenced`）。本轮删除该两条：两宿主复跑 `& tools/check-docs.ps1` 均为 `DOCS PASS: 32 rule-class document(s), 1110 reference(s) checked, allowlist 6 entrie(s)`、退出码 0、**零 `DOC FAIL`**、两条 `DOC NOTE` 随之消失（证明已无人引用）；余 6 条保留（未落地的两片仍在引用）。清单只缩小，未新增。
- 未跑：窗口门（本片未触及 `ui/`，不弹真实窗口；文档阶段在窗口轮同样会先跑，未在真实窗口下实测）、`-Suite all` 全量回归、`-Impact`／`-Exhaustive`、`-VerifyRunner` 探针、oracle、像素判据、性能测量、打包与发布（`tools/package*.ps1`）、Android 真机；既有登记红项（`CARD ART` 缺立绘、`wall` 的 `prison resistance starts a fresh combat position`）不在本次分类范围内，未跑也未声称通过；**本片新增红 0**。本次只提交源码与记录，未推送、未打标签、未改版本号、未打包。
- **同日返工（协调者裁定 #3：文档红不阻断其余阶段；提交 `cc09e31`）**：上文敏感性证明里「文档红先于规则门失败、那两个规则分类未跑（`rules.unrun=[…]`）」是返工前的行为，由本条取代。现在的行为：文档阶段仍先跑、仍打印 `DOCS RESULT: FAIL` 与逐条 `DOC FAIL`、`summary.docs.status=failed`，但**不立即 `throw`**——继续跑 import／规则／窗口阶段并收齐结果，最后统一以非零退出（整轮 `status=failed`，`summary.error` 取该文档消息除非另有失败阶段），使「文档红」与「规则红」落在同一份证据里；`-ListOnly`／`-UIOnly` 轮照旧跑文档阶段（约 1.2 秒、不依赖引擎）。同源附带调整：文档单红（无失败分类）时不再打印 `-RerunFailed` 提示——该命令会以「没有失败或未完成分类」拒绝这样的轮次。
- 返工证据（同一轮内文档红与规则结果共存）：把 `docs/spec/project-map.md` 的 `spire-godot/project.godot` 改坏 → `& tools/check.ps1 -Suite architecture,localization` **退出码 1**（`build/checks/20260921T055451163-8088`），同一轮原文依次为 `DOC FAIL: docs\spec\project-map.md: spire-godot/project-absent.godot (named path does not exist)`、`DOCS FAIL: 1 unresolved reference(s) in rule-class documents; allowlist 6 entrie(s)`、`DOCS RESULT: FAIL`、`Rule-class document gate failed (exit=1). See …\check-docs.log`、`SUITE RESULT: localization PASS`、`SUITE RESULT: architecture PASS`、`PASS: 672 assertions`；`summary.json`：`status=failed`、`error="Rule-class document gate failed (exit=1). See …"`、`docs.status=failed`／`problems=1`／`allowlist=6`／`documents=null`、`rules.passed=["localization","architecture"]`、`rules.unrun=[]`、`rules.retry=[]`、`before==after==960A7944…`（该轮输入含被改坏的 `project-map.md`，与还原后的绿轮指纹不同属预期）。`git checkout` 还原后复跑同命令 **退出码 0**（`build/checks/20260921T055525667-20968`）：`DOCS PASS: 32 rule-class document(s), 1110 reference(s) checked, allowlist 6 entrie(s)`、`DOCS RESULT: PASS`、`SUITE RESULT: localization PASS`、`SUITE RESULT: architecture PASS`、`PASS: 672 assertions`、`status=passed`、`error=""`、`rules.retry=[]`、`before==after==EF0C8795…`（返工改了 `check.ps1`，指纹随之更新；两宿主相等与序数排序的结论不受影响）。

## 2026-09-21 卡牌关键词重叠与顶部对齐（Codex）

- 用户截图反馈已复现：首次打开魔术手图鉴，超级顺延实际宽68，但下一词仍按旧宽44定位到x52，重叠16；费用Label实际38×71，而原费用圆直径仅38。原测试只验证词条各自边界，未核对词条彼此相交，遗漏首次字号改变后的排版。
- 修复沿CardFace及main._card/_refresh_card_face共享通道：关键词改为HFlowContainer，使用最终字号创建；minimum_size_changed延迟刷新正文，字号值相同时不重复设置，避免重排循环。费用禁换行并居中，标题栏几何与文字共用text_scale；关键词距底14像素。
- 定向探针 `build/card_alignment_probe.gd`：修前重叠断言红，修后关键词宽68/34、第二项x76，间距8；费用57×57、标题高57，魔力角标高54且y1.5，三者中心y28.5一致。修后 `build/card-alignment-probe.log` 为UI PASS，实际截图 `build/card-alignment.png` 已目检。
- 门禁 `20260920T140031369-40752`：encyclopedia174断言通过；interface364断言仅两条既有CARD ART直接索引/共用插画断言失败，整体status=failed，未宣称全绿。新增首次进入魔术手图鉴间距与中心断言、全量双面三种尺寸关键词相交/标题边界/费用单行断言均通过；原翻面、滚动与拖放覆盖仍执行。before/after指纹一致 `A874FED2978A4CE46C617EC8012DA8B54250B43A980EBC36CBFFEB4A60FB36F7`。
- 独立只读审查 `review_card_alignment` 通过本轮范围，复核延迟布局收敛、图像及失败边界。最终diff --check通过。保留其他任务在途修改；未重跑全部规则、未打包或发布。

## 2026-09-21 卡牌白色正文微调（Codex）

- 结构沿共享通道：CardFace.fit_text → CardEffect字号 → 手牌／图鉴等卡面。本轮仅将基础字号13改12，480高图鉴字号20变18。
- Godot 4.7.2定向探针 `build/card_body_font_probe.gd` 打开henshin图鉴，原卡与衍生卡字号和正文避让底栏4断言通过（`build/card-body-font.log`，退出0）；实际截图 `build/card-body-font.png` 已目检。未扩大至完整规则回归，未打包或发布。
- 独立只读审查 review_card_body_font 通过本轮字号与证据范围；diff --check通过。


## 2026-09-21 汲取力量正式卡图（Codex）

- 用户上传PNG移除tEXt，成品1920×1920、仅IHDR／IDAT／IEND，全部CRC及原图IDAT一致性通过。SHA256 `4381382b5594cbb8c4f0581f9d8c64778d2dad2ea8a2139c4e82671b1952999c`。通过既有FORMAL_ART.cards.siphon_strength接入。
- Godot 4.7.2无界面导入与默认正式纹理／1920尺寸／测试版回退探针退出0；证据 `spire-godot/build/siphon-strength-art-import.log`、`spire-godot/build/siphon-strength-art-probe.log`。
- 独立只读审查 `review_siphon_art` 通过，素材／映射diff --check通过。只做素材定向检查，未跑全量、未做视觉验收、打包发布或提交；其他在途UI不在范围。

## 2026-09-21 卡牌施法条件右下角（Codex）

- 共享显示通道：main._refresh_card_face → CardRequirements／CardKeywords → CardFace.fit_text布局；无规则写入。蓝字基础字号11不变，按实际文本宽度右下对齐，关键词并排或上移，正文滚动区避让，详情仍收录条件。
- 冻结门禁 `20260920T141656448-2800`（interface、encyclopedia）共538断言；encyclopedia174通过，interface364仅两条既有CARD ART直接索引／共用插画断言失败，整体failed。全注册卡双面、252/290/480高度的条件完整性、右下锚点、底栏互不重叠与正文边界检查通过；原翻面与滚动交互检查通过。before/after一致：`FAA51D56B8D626959A828D93DB7EE67D7D026D57E34D85C46B3F6E8D0CE8755E`。
- `build/card_requirements_probe.gd` 实际打开魔术手图鉴，定向2断言通过，截图 `build/card-requirements.png` 已目检；保留其余任务在途改动。未跑全部规则回归、未打包或发布。
- 独立只读审查 review_card_requirements 通过本轮几何、翻面完整性及鼠标通道范围；diff --check通过。

## 2026-09-21 卡牌关键词金色（Codex）

- 单一入口 main._refresh_card_face 创建关键词时改用GOLD；CardRequirements仍使用CYAN，不改布局或规则。
- Godot定向探针 `build/card_footer_colors_probe.gd` 遍历全部注册卡牌双面检查关键词与施法／条件颜色，`build/card-footer-colors.log` 退出0，UI PASS；实际魔术手图鉴截图 `build/card-footer-colors.png` 已目检。此次仅验证配色，未重跑完整门禁，未打包发布。
- 探针实际核对111个关键词、121条条件；独立只读审查 review_card_footer_colors 通过，diff --check通过。


## 2026-09-21 灌注双面正式卡图（Codex）

- 手／腿用户PNG分别去除tEXt，仅保留IHDR／IDAT／IEND；均1920×1920，全部CRC及原图IDAT一致性通过。手图SHA256 `5b550168f2279b42cd3a82322f120b39024111a0f3eb6759bb2ea4f3635d3527`；腿图 `46ea8dda3874df8a3a6fba6cfcb266bbfb0de695e5abb061d828bdea19eb3c0a`。
- `tools/check.ps1 -Import -UIOnly -UISuite encyclopedia`退出0，185断言通过。证据 `spire-godot/build/checks/20260920T142801630-41400`，status=passed，before／after一致 `78926F9FA4D483834EF462EADCA3DF47C8CD81D97BFFA82E4A9937A7227F6497`。新增用例覆盖普通／赠送灌注初始腿图、翻为手图、测试SVG回退、测试模式翻面、恢复正式腿图与快照不变。
- 独立只读审查 `review_infusion_faces` 通过：核对效果面映射、初始化与翻面更新通道、单图卡牌及敌人接口兼容；相关diff --check通过。按要求未跑全量；未做视觉或安卓验收，未打包、发布或提交。其他在途布局变更不在本次审查范围。


## 2026-09-21 无尽魔法少女战神正式卡图（Codex）

- 用户图片去除tEXt元数据，成品仅IHDR／IDAT／IEND，1920×1920，全部CRC与原图IDAT一致性通过。SHA256 `ba243b25ee8ff0d78131c84bf6a821d8f40652c2b8c3e70b2ba70643185caf6d`。
- Godot 4.7.2导入与正式纹理加载／尺寸／测试版回退资源探针退出0；证据 `spire-godot/build/endless-war-goddess-art-import.log`、`spire-godot/build/endless-war-goddess-art-probe.log`。
- 独立只读审查 `review_goddess_art` 通过，素材映射diff --check通过。仅素材定向检查，未跑全量、未做视觉验收、打包发布或提交；其他在途改动不在范围。


## 2026-09-21 熟练而已正式卡图（Codex）

- 用户图去除tEXt元数据，成品仅IHDR／IDAT／IEND，1920×1920，全部CRC与原图IDAT一致性通过。SHA256 `57de8d3b3489f9a4c145e3dc16626fe3bcb00bfc82c345b5cd12330d5b0db612`。
- Godot 4.7.2导入与默认正式纹理／尺寸／测试回退资源探针退出0；证据 `spire-godot/build/practiced-art-import.log`、`spire-godot/build/practiced-art-probe.log`。
- 独立只读审查 `review_practiced_art` 通过，素材映射diff --check通过。仅素材定向检查，未跑全量、未做视觉验收、打包发布或提交；其他在途改动不在范围。


## 2026-09-21 般若汤系列与猪神之皇焚正式卡图（Codex）

- 般若汤PNG去tEXt、猪图JPEG去APP0；PNG CRC及IDAT一致、JPEG压缩扫描不变。Godot解码源图／成品逐像素比较通过，两图尺寸分别1920×1920与1080×1092。SHA256分别 `839463650f03d5f6ba67a74a87de1bd7ef3a28e3a77b33f671c6218041bcbbe4`、`2722930a619f30f68b8f3f899c0d7cd5692a44b341e3a64d8f23fe067cf3c71a`。
- Godot 4.7.2导入及定向探针退出0：五张饮用卡共用图、猪神独立图，六ID双面纹理路径／尺寸／默认正式版及测试回退通过。证据 `spire-godot/build/hannya-boar-art-import.log`、`spire-godot/build/hannya-boar-art-probe.log`。临时探针为比对原始像素使用load_from_file读取res产生两条导出警告；运行时映射使用load纹理，未改导出通道。
- 独立只读审查 `review_hannya_boar_art` 通过；素材映射diff --check通过。未跑全量、未做视觉或真机验收、未打包发布或提交。


## 2026-09-21 紧缚爱好正式卡图（Codex）

- 用户PNG去除tEXt元数据，成品仅IHDR／IDAT／IEND，1920×1920，全部CRC及原图IDAT一致性通过。SHA256 `fbac894575e5f29ad8b12b27cacc6bade216299d77d627d0138a7377bccbd152`。
- Godot 4.7.2导入与默认正式纹理路径／尺寸／测试回退资源探针退出0；证据 `spire-godot/build/binding-enthusiast-art-import.log`、`spire-godot/build/binding-enthusiast-art-probe.log`。
- 独立只读审查 `review_binding_art` 通过，素材映射diff --check通过。仅素材定向检查，未跑全量、未做视觉验收、打包发布或提交；既有布局和其他在途修改不在范围。


## 2026-09-21 紧缚爱好模式换图与图鉴选择（Codex）

- 新图去tEXt元数据、1920×1920，CRC与原始IDAT一致；SHA256 `3565bd753e11f787e80c827ac21de9b506bdf0edbad5eb285de7caca78e382dc`。默认正式版随fixed_hero_portrait切换，图鉴可固定选原图／替换图／测试图，显式选择优先。
- `tools/check.ps1 -Import -UIOnly -UISuite encyclopedia`退出0、195断言通过，证据 `spire-godot/build/checks/20260920T153541053-46468`；status=passed，before／after一致 `886354F8042B1865A5C11008220A8F2B38B5BFF76C677C2E525347060461EAFD`。新增用例覆盖已有卡面模式即时刷新、双面、手动原图与替换图优先、真实隔离设置保存／重载、恢复跟随模式、测试图回退和游戏快照不变。
- 独立只读审查 `review_binding_mode` 通过，新增PNG块及CRC独立复验通过，中英文选项齐全，相关diff --check通过。仅图鉴定向检查；未跑全量、未做安卓真机或安装包验收，未打包、发布或提交。其它在途布局修改不在本次审查范围。

## 2026-09-21 汇流自由面恢复量与消耗（Codex）

- 结构：SPECS.confluence.self_faces.free → worn_resource(amount=2) → Rules.worn_gain → 实际自身魔力／卡面实时预览；同一面的exhaust → Rules.exhausts → 既有消耗堆及关键词通道。未新增出牌或资源写入入口，其他件数收益默认amount=1。
- 规则测试覆盖0—4件两面、零收益照常消耗、拘束面正常弃置、复合及特殊计件、实时角标、魔力上限和临时池、过期版本回滚与非法amount定义。首轮card_expansion1670断言通过；同步英文源文与相关5条兼容译文后，最终门禁 `20260920T154010680-23348`：localization166＋card_expansion1670，共1836断言通过、退出0。仅定向生成本轮译文，未重建其他在途中文的翻译。
- 实际UI探针 `build/confluence_ui_probe.gd` 调用既有confluence交互用例，7断言通过（`build/confluence-ui.log`）：翻面、0件说明及消耗词条、3件实时角标+6、拘束力量和点击自由面恢复6并进入消耗堆。未做完整游戏回归、打包或发布，保留其他在途改动。
- 最终冻结指纹before/after一致：090D660193C2280FCE1668E8247A67B9218A27F7FFF0B31A30D69E8569D3CFF1。独立只读审查 review_confluence_buff 通过本轮规则、文案与证据范围；diff --check通过。


## 2026-09-21 命运同担正式卡图（Codex）

- 上传PNG去除tEXt元数据，成品仅IHDR／IDAT／IEND，1920×1920，全部CRC及原IDAT一致性通过。SHA256 `48f33dee02426e13c78dc432edb21a932396827a6b7e6b577fcd0cb8797cdb8c`。
- Godot 4.7.2导入及默认正式纹理路径／尺寸／测试回退探针退出0，证据 `spire-godot/build/shared-fate-art-import.log`、`spire-godot/build/shared-fate-art-probe.log`。
- 独立只读审查 `review_shared_fate_art` 通过，素材映射diff --check通过。仅素材定向检查，未跑全量、未做视觉验收、打包发布或提交；其他并行规则及UI改动不在范围。

## 2026-09-21 体术基础乘区与力量蓄力加区（Codex）

- 数据流：招式基础值及般若汤基础加成 → BasicAttacks.physical_damage（BODY_DAMAGE后加总力量／蓄力）→ _attack_offer其他倍率和候选 → _execute_attack冻结多段 → _damage_enemy敌方减伤／屏障。四个体术计算点复用一个公式入口；无第二个资源写入出口。腿部施法成功率从共享旧表拆为WitchCharacter.LEG_CAST_MULTIPLIERS，保持1／0.8／0.6／0.4／0。
- 首轮影响门禁 `20260920T161224177-43888`：witch_character652、card_expansion1670、basic_attacks352、status301、enemies2064，共5039断言通过。敌人种子为每日抽样，不称完整种子回归。
- 独立审查提出的般若汤基础加成边界已补：上肢0—4级、单段／连击、普通／全量蓄力、实际首次饮用般若汤、临时及能力力量，另覆盖加成后乘法buff／机械减伤、群攻、不可用动作与过期版本回滚、角色2施法隔离。初次补测孤立buff缺少等级状态导致12失败，改真实饮用后测试漏算般若汤力量1导致32失败；修正测试夹具及预期后，最终 `20260920T161726162-6116` basic_attacks372断言通过。未删失败用例或绕过状态校验。
- 英文只同步相关3条教程／状态文案，生成器保存人工译文。`20260920T161601048-35584` localization167断言通过，该轮basic失败如上，不能称整轮通过。教程同时修复横扫旧文案4为实际5。
- 实际UI探针 `build/physical_additive_ui_probe.gd` 调用bound_kick交互：基础4、力量2＋蓄力3后预览9、点击真实扣9并消耗一次蓄力，5断言通过（`build/physical-additive-ui.log`）。未跑完整UI、全部游戏回归或安卓真机，未打包、发布或提交。

## 2026-09-21 体术严密度倍率最终更正（Codex）

- 用户撤回力量／蓄力独立加区要求，明确只调整对应部位严密度的伤害倍率。前节独立加区实现及检查结论已被取代，不作为最终行为证据。
- 最终结构仍为共享入口 BasicAttacks.physical_damage，但公式改为（基础伤害＋基础加成＋总力量＋蓄力）×对应部位严密度倍率；双臂用于肘击／近身短打，双腿用于踢击／横扫，0—4级为100%／100%／80%／60%／40%。之后的其他增伤、敌方减伤、单次蓄力消费、禁用条件不变；角色2施法倍率继续隔离。
- 更正后首轮 `20260920T162045303-34228` 虽5226断言均过，但其他在途塔路源码在运行中变化，summary为source_changed，不计冻结通过。下一轮 `20260920T162232262-39528` 被测试夹具的_generate_tower旧签名阻断；仅将夹具签名及super调用透传新增retained_summit参数，未修改塔路实现或其规则。
- 第二次主工作区 `20260920T162324846-7504` 仍因并行塔路改动为source_changed，5226断言通过仅作诊断。转用忽略目录 `build/body-scaling-verified` 的完整源码与素材副本取冻结证据；首次Godot导入启动时字体缓存尚未创建而记录错误，导入结束后缓存已生成，后续规则/UI加载正常。
- 隔离副本 `20260920T162723138-44404`：witch_character652、card_expansion1670、basic_attacks372、status301、enemies2064全部通过；本地化因副本漏复制export_presets.cfg产生3条环境失败。补齐实际导出配置后 `20260920T162852540-43920` localization167通过。两轮before/after均为同一冻结源码指纹 `CCCA599B19D28768945B082DEAC7614CE73391983AC0D29510F15A3D6B986048`；因此六域合计5226断言验证完成，不把先前失败／移动工作区轮次称为全绿。
- 最新UI在隔离副本执行：`build/physical-additive-ui.log` 的5断言通过，验证并腿蹬击从基础4到加力量蓄力后的8，实际扣8并消耗1层；这是脚本点击定向验证，不是完整UI。逐文件比较本次11个相关文件与主工作区一致，game.gd四个攻击／伤害函数也一致。未运行全部规则或安卓真机，未打包发布。


## 2026-09-21 塔顶首领预告与同周目保留

- 范围：地图侧栏及节点真实首领名称、服刑出狱、越狱守卫胜利、重复重建地图、越狱中存读档、旧越狱档缺首领记录回填、非法首领键原子拒绝、二三周目重新抽取。复用 tower_progression／prison／route 现有分类。
- 首轮 `20260920T162427310-46764`：prison 通过；tower_progression 5项失败，4项是重复越狱夹具残留待选择起点，1项是旧断言写死返塔为六缚。修正夹具和按原冻结首领核对新实例后，中间轮1637规则＋136 UI通过。
- 独立只读审查发现旧越狱档无 summit 键边界；修复后复查通过。
- 最终 `tools/check.ps1 -Suite tower_progression,prison -UI -UISuite route -TimeoutSeconds 300`：1645规则断言＋136 UI断言通过；运行目录 `spire-godot/build/checks/20260920T162815576-40460`，status=passed；前后指纹一致：`1C3DFC774E2948176243A477FC1B4EF250DCC8949F86E0242BE94D8FAA7EADC1`。
- 非完整回归；未打包及发布，未进行安卓真机验证。
- 交付前复查：其他任务又修改balance.gd卡牌文案及英文生成器，整文件已不再相同；本轮BODY_DAMAGE常量、physical_damage入口及game.gd四个相关函数仍一致，运行时英文资源亦一致。最终结论仅覆盖本轮规则与定向UI，不声称整个实时工作区冻结。独立只读复审review_physical_additive通过该范围，diff --check通过。

## 2026-09-21｜狱警战后整备重新补装定位

- 只读定位，未更改玩法。Game._end_turn 在分派prepare/prison之前调用 Prison.completed_turn；后者仅排除battle，故整备仍累计刑期并可执行 release_inspection。普通巡视倒计时只由牢房 end_turn 推进，持钥匙时暂停；刑期临时检查不受钥匙暂停影响。
- 隔离探针使用正式收押、入牢、巡视反抗、击败狱警、跳过奖励、整备结束回合命令；仅测试夹具缩短敌人生命、清除装备以模拟缺件，并把刑期设在19/20边界。实测prepare/key=true/served=19/patrol=0/装备0 → prepare/key=true/served=20/patrol=0/装备11，inspection.temporary=true、刑期延长8；validate为空，进程退出0。证明可由出狱前检查在整备内补装，非普通巡视倒计时推进；没有用户存档，未断言其具体游玩实例必为此原因。
- 探针清理；未打包发布。

## 2026-09-21｜唯一与战神提示改写

- “唯一”关键词删除刷新实现的含糊尾句，保留重复使用／复放不叠加及不同牌面可共存。战神卡牌补充与状态详情明确火球术适用范围、右键切换踢击，以及费用、冷却和每回合次数限制；不改规则。
- 三条英文人工词表与兼容目录同步，源文、译文及哈希经独立只读审查 `review_keyword_plain_copy` 核对通过，五个涉及文件的差异空白检查通过。
- `localization` 检查 `20260920T163319017-47360`：167断言通过、退出0、summary=passed，前后源码指纹一致。未运行窗口验收或全量回归，未打包发布。

## 2026-09-21｜监狱战后整备暂停刑期

- 按用户确认修复：Prison.completed_turn 只在活动牢房相位累计刑期与执行到期检查；战斗、奖励、整备全部暂停。整备自然结束及提前结束不补算，回到牢房的下一完整回合恢复，已有服刑数不重置。
- 更新 battle_pause_cases：真实入狱→巡视反抗→胜利→奖励→整备，保留缺件基准且位于到期前一回合，走完全部整备预算仍不检查、不补装、不延刑；存取后首个牢房完整回合恢复临时检查与处罚。保留战斗暂停、提前返回与原周期验证。
- 独立只读审查 review_prison_prepare_clock 通过，检查调用顺序、最后整备回合、两种返回方式、存档边界与测试真实性。未改其他任务的首领保留逻辑。
- 定向门禁 20260920T163554849-28728：prison,persistence 共2370断言通过，退出0、status=passed，前后指纹一致：548F5166018143E972E062EC75CF1D487769777A87718C13909DB2F0B4B6EA28。diff --check通过；仅源码／文档修改，未进行UI、整体回归或安卓真机验收，未打包发布。


## 2026-09-21 美术：用力与顾涌正式卡图

- `00145-3340865038.png` → `strain`，`00151-4152057996.png` → `slip`；移除tEXt元数据，成品仅IHDR／IDAT／IEND，1920×1920；逐块CRC及原始IDAT逐字节一致，源文件未改。
- 成品SHA256：strain `125ae81b4961dd41e11e598ccabe907e4fde03b9eee185caa0dceeb8ea1d5946`；slip `f70074bff3dd9dbe353eb5e3f76711cafd26dfb74f716be8394e398a30e71d6e`。
- Godot 4.7.2 无头导入与资源探针退出0：`spire-godot/build/strain-slip-art-import.log`、`strain-slip-art-probe.log`；覆盖默认正式图、双面路径与尺寸、测试图回退。
- 图鉴缺图用例改为明确选取未配置正式图条目；仅运行 `-UIOnly -UISuite encyclopedia`，195断言通过，`build/checks/20260920T164512164-37904/summary.json` status=passed，before/after均为 `AC34F9C327DFEA9F487E5D6A6E558FBF5F0E6B529B42E65F81B683E5E5F415B6`。
- 独立只读审查 `review_strain_slip_art` 通过；指定文件diff检查通过。未跑全量、未做真机或视觉验收，未打包、提交或发布。

## 2026-09-21｜出狱后旧狱警对白重现

- 原因：ActionCopy从历史日志提取最后一条NPC台词，UI仅按phase匹配；旧存档中整备期间产生的检查失败台词，可能在离开牢房后的整备阶段再次出现。GameView在只读投影中过滤非活动牢房的prison对白，保留release_pass且tower_start_pending的正常刑满告别例外。保留日志，不改存档／随机／回合，不重新执行检查。
- 真实监狱路线用例覆盖开门逃离、击败全部出口警卫、返塔，旧检查日志保留而对白投影为空。UI通过真实攻击胜利→奖励→整备及存档恢复验证相同phase不会复活旧台词；既有刑满告别正例保留。
- 首轮20260920T164616001-42580规则1483断言通过，UI失败因新增测试没有切换踢击形态，点击了未展示的form1候选；已用真实右键切换修复，未修改生产攻击规则。独立审查review_stale_prison_dialogue确认生产投影及测试修复，无剩余发现。
- 20260920T164907136-26900界面257断言全部通过；20260920T165027706-47684规则1483断言全部通过；均因其他在途源码修改标记source_changed，不作为冻结工作区通过证据。


## 2026-09-21 美术：顾涌卡图替换

- 按用户最新要求以 `00152-3394080224.png` 替换 `card-slip-formal-v1.png`，既有slip映射不变。去除tEXt，仅IHDR／IDAT／IEND；1920×1920，CRC与新源IDAT一致，源图未改。SHA256 `f2d6b7bd90b796088ea9e0657528c66114305aba9638e6e7e460bc066c86d8a2`。
- Godot 4.7.2重新导入与既有素材探针退出0，日志 `spire-godot/build/slip-replacement-art-import.log`、`slip-replacement-art-probe.log`；默认正式图、双面路径尺寸、测试版回退通过。
- 独立只读审查 `review_slip_replacement` 通过；文档diff检查通过。仅素材替换验证，未跑全量或重跑UI门禁，未打包、提交或发布。
- 最终冻结检查：规则20260920T165212553-21996（action_copy,prison）1483断言、status=passed；窗口20260920T165212552-39244（action_copy,prison）257断言、status=passed，均退出0。两轮前后指纹一致：F8290E4BFECEAB7DEBC2DE8F3EB38E07C2A44BECFC84E58FAF83A8C1012DB2B9／F8290E4BFECEAB7DEBC2DE8F3EB38E07C2A44BECFC84E58FAF83A8C1012DB2B9。定向diff --check通过，非整体回归或安卓真机验证，未打包发布。


## 2026-09-21 美术：交感形态正式卡图

- `00153-1864203336.png` → `card-sympathetic-form-formal-v1.png`，沿既有FORMAL_ART注册sympathetic_form。去除tEXt，仅IHDR／IDAT／IEND；1920×1920，逐块CRC及源IDAT一致，源图不变。SHA256 `5d90a88a81298f7648548ad4dce2975c5cb31dd84a2b2a934baf7eb705c5c354`。
- Godot 4.7.2无头导入及资源探针退出0，日志 `spire-godot/build/sympathetic-form-art-import.log`、`sympathetic-form-art-probe.log`；默认正式图、双面共图、路径尺寸及测试版回退通过。
- 独立只读审查 `review_sympathetic_form_art` 通过，指定文件diff检查通过。未跑全量、未做真机或视觉验收，未打包、提交或发布。

## 2026-09-21｜出狱检查文案

- 刑期结束流程统一称为“出狱检查”；开始、通过、未通过三条结果改为直接说明当前结果，未通过保留刑期延长8回合。补充资深狱警对应的开始、通过与未通过对白，失败对白不再猜测是缺装还是工具被没收。
- 教程与练习说明同步，并依据正式流程明确只有牢房回合累计刑期，战斗及战后整备暂停；出狱装备统一表述为“施加”。九条英文人工词表、兼容目录与源文哈希同步，独立只读审查 `review_release_inspection_copy` 通过。
- 初轮 `20260920T165207566-27524`：`localization,prison` 1578断言通过。复审修正文案后，旧英文短语断言导致两次定向失败；调整译文措辞后，最终续跑 `20260920T170232338-11680`：同范围1578断言通过、退出0、summary=passed，前后源码指纹一致。未运行窗口或全量回归，未打包发布。


## 2026-09-21｜0.18.1 后架构与校验跟进

- 只读检查新增物理伤害共享入口、角色2施法倍率隔离、监狱相位计时、旧对白投影过滤、同周目首领保留和捕缚意图；上述范围未发现需要新增或合并运行时接口的问题，不将定向检查称为全项目无缺陷。保留其他任务的在途规则／界面／素材改动。
- 校验结构：修改域 → suite_selection.CROSS_AREAS唯一声明 → basic_attack_cases既有行为。补齐card_power、card_expansion、relics、witch_character、persistence五条影响边，依据分别为装备火球、般若／姿态buff、缎带触发、角色腿部施法隔离、首发费用当前格式存取。runner预期独立列出修改域；先加预期未修声明时，20260920T170452178-41608稳定指纹下精确5/541失败，证明原选测遗漏。
- 战神界面旧range(7)改为正式ActionIndex候选 → 逐形态真实右键 → 完整循环归位及规则状态不变；保留非空检查、出牌支付／火球／过期额外形态回退。八种具体招式仍由endless_war_goddess_cases::original_attacks独立锁定。Godot 4.7.2 --headless --check-only --script res://tests/endless_war_goddess_ui_cases.gd退出0，仅解析，未执行UI用例。
- 初轮20260920T170057672-47392的六域3156断言虽通过，但运行中工作区变化，summary=source_changed，仅作诊断。修复后重跑原六域并加入card_power和iron_man，最终运行20260920T170518530-7684：card_power 2158、basic_attacks 372、architecture 507、runner 541、action_copy 72、prison 1411、iron_man 375、tower_progression 258，共5694断言通过，退出0、status=passed，before/after同为F1C206378F3C6B2800B5559D7E88924AB27286A2675ED305663EF86A8BCB730E。使用每日样本，不是完整随机种子矩阵。
- 独立只读审查review_followup_0181_checks通过本轮三个测试文件相对修改前备份的增量，核对影响关系、敏感性、候选引用生命周期及旧断言保留。diff --check通过。未试玩、未执行UI交互／安卓真机、未跑全量、未打包提交或推送。

## 2026-09-21｜出狱检查失败对白返工

- 狱警失败对白删除“8回合”等规则数字，改为“检查没通过哦。回去乖乖待着，等我下次来吧❤”；刑期延长8回合仍只由事件结果说明。对应英文、兼容目录哈希与生成器排序同步。
- `localization` 检查 `20260920T170805997-40284`：167断言通过、退出0、summary=passed。指定文件差异空白检查通过；未运行窗口、监狱规则或全量回归，未打包发布。

## 2026-09-21｜玩偶师生命回调与容量下限

- 按用户要求将玩偶师基础生命从76恢复为此前的96；多周目生命倍率及30点屏障倍率不变。普通反击容量上限削减最低为1，剩余反击次数仍可耗尽至0，多段／群攻／玩偶转移每次攻击只削减一次。
- 运行时与下限判断共用 Enemies.PUPPET_MIN_CAPACITY；旧档曾降至0的容量显示为1，不补发余量。缝补前裁去旧下限遗留扣减，使下一次缝补按当前上限＋1到2并补满，无存档格式迁移。图鉴、状态、中文设计与英文模板同步。
- 更新真实生命／受伤／多周目断言；容量循环验证2→1→1→1，不积欠；真实回合缝补验证回到2，新增旧档0上限／0余量恢复并走到缝补的边界。既有余量耗尽与多段AOE用例保留。
- 首轮20260920T171659519-46896的localization、encyclopedia、persistence通过，但新增测试补丁使malformed loss断言少一格缩进，enemies编译失败；已修正并重跑。review_puppet_floor_one独立只读审查确认规则、兼容及AOE契约，无其他发现，并复核缩进阻断已修复。


## 2026-09-21 美术：欲能转换正式卡图

- `00155-2092312727.png` → `card-pleasure-conversion-formal-v1.png`，沿既有FORMAL_ART注册pleasure_conversion。去除tEXt，仅IHDR／IDAT／IEND；1920×1920，逐块CRC及源IDAT一致，源图不变。SHA256 `8b477fdd93aa74c128914c0a9c52f2aedced73cd08cd33251af00380bc514004`。
- Godot 4.7.2无头导入及资源探针退出0，日志 `spire-godot/build/pleasure-conversion-art-import.log`、`pleasure-conversion-art-probe.log`；默认正式图、双面共图、路径尺寸及测试版回退通过。
- 独立只读审查 `review_conversion_art` 通过，指定文件diff检查通过。未跑全量、未做真机或视觉验收，未打包、提交或发布。
- 修正后171841880-17528规则3780、敌人UI221断言全部通过，但其他在途源码变化令整轮source_changed，不计冻结通过。最终重跑：20260920T172233573-27540规则enemies,persistence,encyclopedia,localization共3780断言，status=passed；20260920T172233573-36816敌人UI221断言，status=passed，均退出0。两轮前后指纹一致：CD35B09547C29413C272F7CB00240D74E60C71DBC01A6C4802DA984291D79D76／CD35B09547C29413C272F7CB00240D74E60C71DBC01A6C4802DA984291D79D76。定向diff --check通过；非整体或安卓真机验证，未打包发布。

## 2026-09-21｜般若汤系列立绘版本联动

- DisplaySettings.ART_STYLE_GROUPS统一登记其一至其四、好汤、般若汤赠送的身轻如燕／灌注／完美henshin；art_choice_id作为偏好归一入口，载入／读取／设置均使用hannya_1键。一次保存后向全部8张牌发送原有art_changed通知，卡面仍选自己的纹理及正反面。普通身轻如燕、灌注、henshin不联动。
- 旧配置中其一优先于衍生牌，无其一时继承第一个有效衍生设置；保存时只保留统一键，不改游戏存档或玩法。图鉴UI真实选择器＋8张现存CardFace验证立即切换、衍生入口、原版牌隔离、旧配置冲突、仅衍生键及保存重载。
- 独立只读审查review_hannya_art_group通过；定向diff --check通过。
- 门禁20260920T174107208-46352：UI encyclopedia 216断言通过，退出0、status=passed，前后指纹一致：CCE7F13E9AB9845017D199DFB67703585C7D92068265ACF754F4E1DE237E310A。本次仅显示偏好联动，未重跑整体玩法回归，未打包发布。


## 2026-09-21 UI：紧缚爱好卡图区统一

- 删除CardFace的ART_HEIGHT_OVERRIDES，所有卡牌沿_layout_art统一使用2/3；更新既有全卡双面多尺寸断言，紧缚爱好全文直接可见断言按新要求改为统一比例及滚动末端可达。数据流：卡面尺寸 → _layout_art → 统一卡图区／fit_text正文滚动区，无规则写入。
- `tools/check.ps1 -UIOnly -UISuite interface,card_power`：card_power PASS，interface FAIL；共750断言。仅失败两项：动态witch_*未在ILLUSTRATIONS直接注册、desire_magic.svg共享插画未被旧唯一性断言接受。运行时分别已有art_type路由与共享SVG，均非本次布局改动范围；本次不改这些断言，不宣称整组通过。卡图区统一比例、双面多尺寸正文边界、滚轮与紧缚爱好文本末端可达断言未失败。
- 证据：`spire-godot/build/checks/20260920T174125835-26608/summary.json`，status=failed；before/after均为 `2AB1CCF0D523D6AE0735110358F1C66009107884C301ED45B467AD46906CF140`。
- 独立只读审查review_binding_card_size通过实现及测试范围；指定文件diff检查通过。未跑全量、未打包或发布。

## 2026-09-21｜猛火下山成功触发

- 通道：`Game._cast_magic` 仅成功时调用既有 `Cards.spell_used`，不新增抽牌入口。
- 覆盖：一／二层失败时全部牌堆不变且无抽牌或洗牌反馈；成功重试按层抽牌；现有群攻、装备目标、满手牌、致命攻击与存读档覆盖保留。复放测试要求包含失败，抽牌数量等于成功施法次数，保留独立判定与一次支付断言。
- 首轮 `20260921T023842449-1240` 发现 `echo_cast_cases::boundaries` 仍断言失败复放也抽牌；已按新规则修正，未删除该失败边界。
- 最终 `20260921T024212269-28128`：`check.ps1 -Suite card_power,casting,localization`，2947条断言通过，exit 0、status=passed；前后指纹均为 `5A594D703F839F7B0D36CD2F7739B62BEFC73D7E4C613C7584B862E29FEAF9A4`。`git diff --check` 通过。
- 独立只读审查 `review_wildfire_success` 复审通过；未运行完整回归或UI检查，未打包发布。


## 2026-09-21 美术：股绳局部差分与裁尖

- 仅采用最终确认的两张clipboard源图（9359ef44…无／0a5a87f5…有），1536×2304。像素差异41896，范围(675,858,954,1120)。复用既有本地抠图与差分辅助函数，导出两张299×282透明贴片，原点(665,848)，来源及成品哈希见equipment-crotch-rope-layer.json。
- 裁尖前双向alpha替换与源抠图可见像素／alpha完全一致；最终按用户要求将右下尖细突出部分alpha削去并羽化，保留颜色。PNG仅IHDR／IDAT／IEND，CRC有效、无文本元数据。已查看局部预览确认突起移除。
- Godot 4.7.2重新导入退出0，日志spire-godot/build/crotch-rope-art-import.log。独立只读review_crotch_rope_assets校验来源及产物哈希、尺寸、坐标、alpha裁剪与导入引用通过。
- 只准备素材；运行时装备映射未修改，未验证游戏合成，未跑全量、未打包。按用户最新指示暂缓平板锁适配。


## 2026-09-21 非Boss长战斗离场与逮捕预备

- 边界覆盖：第14／15回合、19／20件、总紧度39／40；现有所有非人形模板含机械与分裂怪；Boss房间及Boss遭遇整场豁免；混合敌群；同战仅一次奖励；捕缚来源离场清理；人形原捕缚机制豁免；反复预备、首次转换继承打断、正式结束回合至收押；存读档、只读预览与拒绝命令。
- 初始测试夹具曾把连接绳计作佩戴件数，且跨正式提交引用旧敌人字典，导致失败；修正为实际佩戴件数与按ID重新查询后通过。独立只读审查发现首次转换意图会清除原打断，已修复并补回归，复审通过。
- 最终 `tools/check.ps1 -Suite battle_saturation,guard,intent,rewards,enemies -TimeoutSeconds 300`：4224断言通过；目录 `spire-godot/build/checks/20260921T030314931-10340`，status=passed；前后指纹一致：`8528065347426ED8DE9D5D7B58F2F5D87998C07288DBDFCF59B2902D6B7FC846`。`git diff --check`通过。
- 非完整回归；未运行窗口分类、打包或安卓真机验证。


## 2026-09-21 塔顶首领生命调整

- `20260921T032658414-8`：iron_man／enemies／tower_progression共2704条规则断言通过；塔顶UI一项失败来自旧的150／50／50生命断言，该夹具实际是新局且无警戒加成，应为140／40／40，生产随从生命没有改动。
- 修正旧UI断言后，仅重跑受影响UI：`20260921T033038640-25792`，tower_progression 60断言通过，status=passed；前后指纹一致：`0665595735B71EF841DD2761B397CE83F39F6E62455F14B18D2F33204DABF0DC`。规则通过后只改UI测试与说明，没有再改生产代码。
- 独立只读审查指出game-design.md残留旧六缚例值，已改链接首领文档真源；已核对正常／小魔女／续局生命与动态英文练习说明。`git diff --check`通过。非完整回归，未打包及安卓真机验证。


## 2026-09-21 美术：平板锁版股绳局部差分

- 用户补充00170-135882225.png无版本与QQ图片20260911234734.png有版本，局部像素差异28723，范围(680,861,956,1113)。本地复用既有cutout/component_mask/overlay_from_mask/replace_rgba辅助，产出两张296×274透明贴片，origin(670,851)，来源与产物SHA256见equipment-crotch-rope-flat-lock-layer.json。
- 两个方向alpha替换与对应抠图可见像素和alpha完全一致，保留源图锁体和带子。查看局部预览确认无普通版尖细突起，因此不应用普通版裁尖线。PNG无文本元数据，源不变。
- Godot 4.7.2无头导入退出0，日志spire-godot/build/crotch-rope-flat-lock-art-import.log。独立只读review_lock_rope_assets校验CRC、图像块、尺寸、源及产物哈希、坐标、逐像素一致性和导入引用通过；文档diff检查通过。
- 仅交付本图对对应的平板锁＋带子差分素材，未改运行时、未验证其它组合或游戏合成；未跑全量、未打包。

## 2026-09-21｜单腿套装备差分与图层优先级

- `tools/build_equipment_single_leg_layers.py`在本地从四张1536×2304对齐源图提取三个腿部连通差异：短上段范围`(604,1171)-(875,1620)`、短下段范围`(601,1630)-(819,2125)`、长款范围`(601,1171)-(875,2125)`。面积分别为94010、72925、176935像素；共同的手臂差异位于`y=449`，未进入任何输出。五栏运行时重组预览覆盖无套体、单短上段、单短下段、上下短段叠合与长款，已人工查看，无白边或横向接缝。
- `GameView.build`只从活动复合根投影`single_leg_upper/lower/long`；`EquipmentPortrait`最后创建并对齐三张差分，使它们位于七个普通腿切片和特殊差分之上。`leg_layers`练习中的长款节点又位于两种短款之后。套体被破坏时活动投影消失，既有剩余外带显示通道保持不变。
- `20260921T041450188-31724`：Godot导入成功，`architecture`507断言通过；`equipment_art`共执行236断言，本次新增的四种单体映射、单短下段、上下短段合成、长款覆盖顺序、只读状态断言均未失败。分类最终仅失败两条同文件内另一项在途股绳解除用例（`PORTRAIT actual manual action releases rope`、`PORTRAIT real release clears rope in both standing views`），因此不宣称该分类整体通过；`hero_art`因停止策略未运行。
- `20260921T041641979-36900`：单独重跑`hero_art`，63断言通过、退出0、status=passed，前后源码指纹均为`F12F484EE7FCCB82D86D74A6390B377074CAB273F3FA0C8E8F77CDB6652B5301`。Python构建脚本编译与指定文件`git diff --check`通过。未跑全量、未打包或发布。
- 独立只读审查`review_doubao_prepare_exclusion`核对生成器、资产哈希、映射、短下段独立显示、上下组合及绘制顺序，未发现生产缺陷；指出实际剪开套体后缺少直接的差分清空断言。已在既有真实切割操作后补充`active_composite_layers`清空与`Overlay_single_leg_upper`隐藏检查。
- 最终冻结检查：`20260921T042241145-12568`的`equipment_art,hero_art`共298断言通过；`20260921T042349934-12548`的`architecture`507断言通过。两轮均退出0、status=passed，前后源码指纹同为`D8C0A209EC4BC0BB781A0A9E065F4751AE66B83B89842AA1EFE8D082074E6735`。未跑全量、未打包或发布。


## 2026-09-21 美术：股绳站姿接入与单手套排除

- 最终范围：普通／平板锁受限站姿由真实股绳family与正耐久切换；所有包含单手套的组合（含平板锁）保留原底图与原加强带。
- 最终 `tools/check.ps1 -Import -UIOnly -UISuite equipment_art,hero_art`：`20260921T042016171-27444`，两分类PASS，共297断言，退出0；前后源码指纹均`3AD12CD0810EF7563A2F87B3957B4E8344EDB424044EE7F030CB3F99BD866E46`。覆盖三档正耐久／零耐久投影、两种站姿两端同步切换、正式strain拖牌解除刷新及所有含单手套组合的排除条件；未跑全量。
- 初轮`20260921T041106932-27860`为source_changed，且新增用例误用股绳不支持的manual导致两条失败；不计通过。改用真实支持的strain候选与拖牌流程后重跑最终范围，保留解除刷新断言。
- 新三张运行PNG只含IHDR／IDAT／IEND，尺寸两张740×2214及加强带246×294，清单底图SHA-256匹配。差异覆盖包括目标透明区域，清除普通轮廓细线及平板锁边沿残绳；原图不变。单手套试产物按用户最终要求撤除。
- 独立只读子代理`review_rope_integration`最终复审通过：真实装备投影、原单手套资源优先与附属图层排除、测试及指纹均核对；不评价他人在途单腿套改动。仅源码／素材更新，未打包发布。

## 2026-09-21｜拘束就是力量的跨回合力量

- 拘束1沿佩戴计数与self结算，将收益转为既有增益层数；`next_turn_start` 增益在下回合逐层转为 `turn` 增益，不新增存档字段。覆盖0收益、奇偶件数、支付/过期提交回滚、复放、存读档、敌方阶段保留、下回合结束清除、连续回合分别到期、汇流混用与整备清理。
- 注册表力量收益的buff约束由删除buff引用的负例覆盖；去掉该约束会使该断言失败。状态实际数值与期限、卡面两拘束面显示均有检查。
- 独立只读审查 `review_binding_power_duration` 发现跨回合转换仍误报效果结束；已修正并加入日志反例，复审无剩余问题。
- `20260921T045809792-26556`：规则4311条通过但source_changed；UI被其他在途立绘加载函数缩进错误阻挡。只修复 `_load_single_leg_layers` 的result写入缩进，保留素材逻辑。`20260921T050142174-40508`：其他在途 `witch_character.gd` 加载失败；随后该脚本独立check-only通过。
- `20260921T050305997-38932`：规则4355、UI card_power386条均通过，但source_changed，未作为冻结源码通过。最终重新取证见下项。

## 2026-09-21｜单腿套透明分割与旧轮廓清理补验

- 针对短上段左侧旧腿像素、长款下的短款透明区穿透和直接隐藏横切片造成的缺口，生成器现在同时替换完整底图与受影响横切片的RGBA；普通／皮革、平板锁、单手套上下文使用各自原点。长款活动时保留真实装备投影，但隐藏短上段、短下段的连续覆盖节点。
- 本地像素探针验证短上段、短下段、长款底图在膨胀替换掩膜内相对目标抠图均为`alpha_missing=0`、`alpha_extra=0`。独立只读复审进一步核对110张底图／切片替换资产与清单哈希，并重建120种底图、材质和单手套组合，旧轮廓穿透及目标不透明缺口均为0；未发现分段坐标错位。
- `20260921T050340955-21708`：Godot导入成功，`architecture`507断言通过；`equipment_art`中本次底图替换、逐切片选择、长款隐藏短款、组合和真实解除清理断言均未失败。分类共执行290断言，最终仍有两条另一项在途材质解除用例失败（`MATERIAL actual strain candidate targets outer belt`、`MATERIAL release refreshes both views despite unchanged body occupancy`），因此不宣称该分类整体通过；`hero_art`因停止策略未运行。
- `20260921T050915498-7532`：单独运行`hero_art`，63断言通过，退出0、status=passed。最终源码下再次运行`equipment_art`为`20260921T051352716-32272`，仍仅上述两条材质解除用例失败，本次单腿套断言未失败，前后指纹均为`EF4D48F7510AA4B068B7D932B57A8DA4FF04F2F1BDCB2B68FCBE883ED60F838F`。Python生成器编译及指定文件`git diff --check`通过；未跑完整回归、未打包或发布。

## 2026-09-21｜普通腿部红绳／皮革混材接缝

- 根因是皮革源图与红绳源图的整段皮肤色调存在细微差异；旧生成器把完整横切片换成皮革源图，导致小腿、脚踝、脚掌相邻部位材质不同时出现矩形色块或深色横线。现改为从源差异中只保留9个大面积深色皮革组件及窄抗锯齿边缘，合成到统一自由皮肤底图；平板锁继续从其专用自由底图出发并排除锁体像素。
- 生成器要求皮革掩膜不得触及`1180/1325/1480/1625/1800/1965/2135`横切片边界。新增UI资产断言核对大腿中部至脚掌各切片的红绳／皮革可见边缘与自由切片一致；透明像素RGB因Godot的`fix_alpha_border`允许不同，alpha及可见像素必须一致。
- `20260921T053020194-26836`：Godot导入成功，`architecture`507断言通过；首轮UI仅失败脚掌皮革边缘断言，定位为测试错误比较了完全透明像素的填充RGB，运行画面不受影响。修正为比较alpha和可见RGB后，`20260921T053317334-5376`的`equipment_art,hero_art`共365断言通过，退出0、status=passed，前后指纹均为`0122EEC8BBABAEDE7609759858B3238A83D719688F26B5B358A13F74DCD648DC`。
- 独立只读复审重算9个组件与全部边界，核对材质及单腿套重建哈希，并查看脚踝六种混材和全皮革预览；未发现横向色块、黑线、残绳或皮带裁断。Python生成器编译与指定文件`git diff --check`通过；未跑完整回归、未打包或发布。

## 2026-09-21｜小魔女卡牌与法阵

- `20260921T050447316-28500`：witch_character／card_splash／basic_attacks／enemies 3358条通过，before=after；覆盖共享结算受影响域。后续独立审查发现X费技能分支未减费及耐心旧状态提示，均修复，补真实自缚出牌测试。
- `20260921T050849442-40264`：persistence 971、rewards 1290通过；witch_character新X费测试因未提供收紧目标失败，改用正式可佩戴的自由面验证；两条新增英文动态参数格式错误导致localization／card_expansion失败，已修复为目录的命名参数格式。未删除失败案例。
- `20260921T051032881-4184`：按RerunFailed续跑受影响及未完成域，witch_character 756、localization 167、card_expansion 1683共2606条通过；真实窗口encyclopedia 216、home 140共356条通过。before=after=`EF4D48F7510AA4B068B7D932B57A8DA4FF04F2F1BDCB2B68FCBE883ED60F838F`，status=passed。
- 边界包含：两面每7次升级的前后值、每段独立结算、27次打出升级但不提前清捕缚、28／34／35次清捕缚与费用、计数持久化；魔力松缚预览不加精神集中且成功后不消费；耐心释放清空、高潮保留、敌方窗口失效；法阵上身3／4级、四部位0魔力预备、释放照常、技能／魔法混合牌当前面、0费与X费、过期提交回滚、重复次数、跨回合、存读档与场次清理。原角色咏唱与汲取保持原值。
- 英文盘点已执行。全量生成因本机缺少离线翻译依赖且存在101条未缓存源文而停止；仅合并现有人工译文目录，保留已有译文，新增文案人工补全；最终localization门禁通过。
- 独立只读审查 `review_witch_circle_levels` 及修复后复审通过；未运行全项目回归、安卓真机、导出包。旧门槛进度档未迁移，此限制与实现保持一致。
- `20260921T050651547-27316` 再次全项通过但source_changed；因此复制当前项目与导入缓存到忽略目录中的临时固定副本验证，未改副本源码。
- 固定副本最终 `20260921T051139831-27988`：`check.ps1 -Suite card_expansion,card_power,status,localization -UI -UISuite card_power`，规则4355与UI386条通过，exit 0、status=passed；前后指纹均为 `EF4D48F7510AA4B068B7D932B57A8DA4FF04F2F1BDCB2B68FCBE883ED60F838F`。本任务8个实现／文案／测试文件与工作区逐字节比对一致：True。日志保留于 `spire-godot/build/checks/binding-power-frozen-20260921T051139831-27988`。
- 未运行完整回归，未打包发布。共享工作区其它改动不据此宣称验收。
- 独立审查最终核对固定副本门禁及工作区一致性通过。清理临时项目副本时，自动审批返回 blocked by policy，删除未执行；副本仍保留在忽略目录 spire-godot/build/binding-power-verification/，未入库。

## 2026-09-21｜脱缚练习超级顺延（最终修订）

- 用户随后明确取消清除捕缚：Lv.4（28次）改为3×6、超级顺延、1费；Lv.5（35次）同效果0费。此项替代本日“小魔女卡牌与法阵”中关于清捕缚的结论。Lv.0的1×3为每段1点共3段，两面分别挣扎／滑脱。
- `20260921T051413440-27312`：真实跨区和捕缚保留验证通过；新增关键词断言揭示双拘束第2面漏展示顺延，另修正测试在提交后需重取实体。保留所有反例；共享关键词投影改用真正自由效果判定。
- `20260921T051533302-2936`：最终witch_character 786、card_expansion 1683共2469条通过，窗口encyclopedia 216、home 140共356条通过。before=after=`0BA703ACD58EE12F997DEC7E83128864535DC171A2CCEE680360E6DD8DAACEEE`，status=passed。
- 边界覆盖21／27／28／34／35次，两面均从大腿实际释放，Lv.4起跨区接续至手腕；27次升级当次仍用普通顺延；所有阶段均不额外清除捕缚。进化后读取真实牌堆实体展示两面顺延关键词。
- `review_witch_circle_levels` 对最终效果与共享关键词投影分别独立只读复审通过。仅源码／文案／测试更新，未打包发布；旧练习进度档未新增迁移。

## 2026-09-21｜装备材质差分与缓存刷新

- 域：`GameView.portrait_materials`、`EquipmentPortrait.visual_facts/configure/_align_layers`、材质manifest与本地切片生成器。结构沿既有实体装备外层查询→只读投影→共用组合器，不改变装备或随机。
- 初轮 `20260921T044352731-27952` 失败且源码变化，不能作为通过证据：旧用例隐含默认皮带却断言红绳；真实解除用例未满足动作规则。旧覆盖改为显式红绳夹具；外层切换用例改用真实用力拖牌及满足最高紧度规则的皮带。第二轮 `20260921T050545104-27324` 剩2项解除断言失败，随后修正该夹具的最大耐久，不放宽正式候选。
- 最终 `20260921T051500746-25464`：素材导入及 `equipment_art,hero_art` UI通过353断言，exit=0、status=passed；前后源码指纹均为 `352A1303B6C676A65C99171DFBCD902525355E349DA3E3D3BBEB768A12A97817`。覆盖外层皮带优先、皮革／红绳数量、平局、皆无、上身合计、不同腿锚点混合材质、单手套排除，以及占位不变时真实解除外层皮带后的双立绘刷新。
- 32张材质输出无嵌入元数据；红绳／自由重建可见RGBA完全一致，深色背景重建目检未见旧绳边。独立只读审查发现并复核修复单腿套旧窄框错位与单手套专用腿根源误用；70张单腿套切片尺寸、113个组合输出及32个材质输出哈希一致，原1089个手臂残留像素区域与专用源一致，最终无待修项。
- 未跑完整回归、安卓真机或规则全量分类；未打包、提交或发布。其余在途修改保留。


## 2026-09-21｜长战斗图鉴与卡图接口校验跟进

- 跟进新增小魔女规则、长战斗结算与卡图映射。修正Encyclopedia.entries仍宣称循环敌人“不会自行离场”的过时说明。数据流：Enemy注册表＋Balance门槛 → 各敌人说明汇总 → 本地化显示边界；统一追加非首领战15回合、20件或总紧度40的条件，区别非人形离场与无捕缚机制人形反复准备逮捕，明确首领整场含随从豁免。门槛读取现有常量，未改运行时玩法／写入入口。
- 图鉴新增逐敌人文案边界检查。修前20260921T053604812-36720有69/646断言失败；保留这些用例，修正文案后通过。interface_ui_cases::card_illustrations按既有art_type、art_source、赠牌和明确七张欲望牌共享组检查；缺图、非空、意外重复、布局与只读断言均保留。
- 从旧／新测试谓词截取的无头资源探针不实例化卡面节点：旧谓词报39张映射卡缺图和6张共享图重复；新谓词121张注册卡通过且快照不变。对复制的纹理表删除slip、把strain错误映射到slip的两个负例均退出1，证明未放宽真实缺失及意外重复检测。日志在spire-godot/build/followup-current-20260921/。Godot --check-only解析interface_ui_cases退出0；未执行UI交互或布局验收。
- 本地化盘点完成；全量英文生成因本机缺少离线翻译依赖、104条未缓存源文而停止，未称全量生成成功。本轮仅在人工词表和兼容目录合并3条审定模板，保留其余现有译文；新增实际图鉴文本翻译断言验证参数和两种结局。
- 首轮20260921T053755270-12532：witch_character 786断言通过，随后新本地化测试误用PackedStringArray.filter发生脚本错误，中止后续域。仅将测试split结果包为Array；RerunFailed运行20260921T053815877-31972：localization171、card_power2204、battle_saturation641、architecture507、encyclopedia646、runner541，共4710断言通过，退出0、status=passed，before=after=C5FEAB535361C0FDD80CA027BB45B707BB2F1B965080CFE268643502B6F1D6C8。小魔女规则自首轮通过后未改实现；两轮合计7个域5496条通过断言，非一次全项目回归，也非完整随机种子矩阵。
- 独立只读审查review_current_followup_copy通过本轮6文件相对备份增量，核对实际规则、艺术映射、反例与翻译；diff --check通过。未试玩、未运行UI交互／安卓真机、未打包提交或推送。其他在途改动保留。


## 2026-09-21｜v0.18.2 发布校验

- 本批包含0.18.1后已完成的玩法、卡图、装备差分、监狱和校验维护；project.godot、Windows/Android预设、随包说明统一0.18.2，Windows文件版本0.18.2.0，Android安装版本14且沿用原发布签名。开始时记录430个已有修改／未跟踪文件，保留其内容；根版本更新内容仅去除尾随空格。
- 结构：冻结规则源码 → Windows相邻content/packs导出 → 恢复开发res://值 → Android导出 → 两平台成品探针 → ZIP及PC双层7z → GitHub五项公共附件。双层7z内外均按用户指定密码加密文件名，仅本地交付，不上传。
- 20260921T055704245-18128：素材导入通过，51个规则分类（排除normal_play）、完整种子矩阵（enemy_cycle16/16、enemy_pool24/24、tower_graph201/201），30315断言中2条失败：desire_cube::pool仍期待原prepared_chant而非witch_prepared_chant；TC-CHARGE-0001仍按旧二级60%得到6.6。
- 保留反例并只修旧测试：角色映射后的临时卡同样挂主题池标记，经正式reward_offer检查无遗物拒绝、有遗物获得映射ID及排除原ID，结束恢复原卡／映射卡注册表；伤害预期确认双臂二级并改为(8+3)×0.8=8.8，保留真实动作消耗蓄力。20260921T060244658-28856续跑relics/core共2361断言通过。两轮各自before=after；按分类最新结果计51类30315断言均通过。未为过测修改生产行为。
- Windows导出outputs/spire-v0.18.2-windows-x64-release-20260921-0182，成品检查build/package-check-20260921T060435261通过；Android导出outputs/spire-v0.18.2-android-release-20260921-0182，APK资源检查build/android-probe-20260921T060514979通过。两者均是主机无头成品启动／资源／新局与练习初始化探针，不是试玩或手机验收。
- 700项运行时输入逐项核对，Android等于规则验证源码，Windows仅core/content_catalog.gd的PACKS_ROOT按约定变为adjacent；已验证该替换后的文件hash，工作区原始字节恢复。证据build/release-v0.18.2/export-equivalence.json。Android证书SHA256为9da2962a178eec7a6be1bb45c77c37372c0f18c2f2efe313e3f8aad07cdd0608，与上一版相同；版本14、16KB对齐、provider唯一性、启动入口、12份内置内容包hash检查通过。
- 两平台成品另加载新增171张图片与2份材质／单腿套清单，均无缺失。补充Windows资源探针首次使用相对PCK路径未加载包而失败，改为绝对路径后通过，未修改成品。日志windows-assets-final.log、android-assets.log在build/release-v0.18.2；导出助手初次因PACKS_ROOT使用:=而提前守卫失败，修助手匹配后才开始导出，未改打包脚本或玩法。
- 最终目录outputs/release-v0.18.2-20260921-final。PCZIP、AndroidZIP均实际解压逐文件SHA256通过；PC双层7z两层分别校验、实际解开并逐文件核对25个文件，确认仅Windows64目录、无APK，错误密码不能列出文件名。证据outputs/verify-v0.18.2-20260921-final/verification.json。包内验证说明、manifest、SHA256已同步。
- 独立审查review_release_0182已通过版本、更新说明、已有改动保留及两项测试修复；最终成品复核另见本条后续结果。未运行normal_play、完整UI交互、人工游玩或安卓真机。相关英文定向检查通过，离线全量英文生成仍因依赖与未缓存源文缺失未完成；未声称全量界面回归。

- 最终成品独立只读复核review_release_0182通过：重算全部6交付文件hash，两平台ZIP逐文件比对（Windows25／Android13）、Windows manifest覆盖、双层7z密码／文件名加密与实际PC-only25文件、APK重新验签和16KB对齐、700项输入、资源探针与五项公共上传允许列表均通过，无发布阻断项。437个暂存文件不含构建、存档或签名秘密；源码与产物具备发布条件。

## 2026-09-21｜合并上游 v0.18.2（`1930470`）到分支 `seed-chip-save-upload`

域：本分支合 `origin/main`（`1930470`，Release v0.18.2；上游侧 437 文件、+10872/−464），两侧都保留——上游 v0.18.2 的玩法、监狱、美术与校验改动（含 171 张新增图片素材），以及本分支的种子角标（`state.initial_seed`／`SeedChip`／`SaveStore.fixed_point_text`）、反馈附带当前进度存档（`include_save`／原因码／`schema>=2` 门控）与本局回顾面板（`ui/run_review.gd`／`route_map.read_only`／`ui/main.gd` 两处 `OpenRunReview`／`show_run_review`）。冲突 4 文件逐项处置：

- `spire-godot/ui/main.gd`（`_route_screen`）：上游的塔顶首领预告循环（`TowerBossPreview` 先加到 `RouteMessages`）与本分支的标题行（`title_row` 载「移动消息」＋`SeedChip`）同时保留，chip 仍是该界面唯一的查看／复制入口，`copy_seed()`→`_refresh_seed_chip(true)` 与 `_run_review_copy_text()`／`run_review_copy` 刷新接线未动；合并后全文件无重名函数（`grep "^func "` 去重为空）。
- `docs/design/game-design.md` §10.4：上游把首领数值移入新文档（`[第一幕敌人](enemies-first-floor.md)`），本分支在同行追加了本局标识子句（`state.tower_generation`／`state.initial_seed`），取「上游措辞＋本分支子句」。**数值口径以「文档跟随实现」判定**：合并后的实现是 `data/enemies.gd` 的 `six_bind.hp=200`／`iron_man.hp=140`（上游 v0.18.2 的调整，本分支相对 merge base 未改该文件），`docs/design/enemies-first-floor.md` §续局缩放同记 200／300／400 与 140／210／280；merge base 与本分支继承的「六缚220／330／440」与实现不符，故不保留。上游在同一段落给出的新措辞与实现一致，未替任何一方做规则选择。
- `docs/record/{changelog,verification}.md`：两侧条目都留、按日期排序（09-20 条目在前、09-21 在后）、不改写任一方旧句。机械证据：与两侧父提交比较均为纯新增（`git diff --numstat HEAD`／`MERGE_HEAD` 无删除行，仅各合并掉 1 个空行）。
- `docs/design/game-design.md` §13（存档与恢复）：上一轮本分支已按实现改写为「当前 `Snapshot.REVISION` 直接接受；更早三档（`core/snapshot.gd::REINFORCEMENT_STATE_REVISION`／`CUP_STACK_REVISION`／`IRON_DRONE_REVISION`）由 `core/game.gd::restore_snapshot` 按迁移链升级并写回；其余拒绝」，本轮原样保留；上一条合并记录里的「待裁定」项至此与实现一致（本轮文档门禁点名这些符号均存在）。上游对本文件的其它改动（长战斗门槛、体术伤害公式等）全部保留。

- 导入：合并树按新增素材做导入（`--headless --editor --quit --path`，退出 0，171 步 reimport）。导入后 `.import` 与上游暂存内容逐字节一致（同一文件索引与工作区均 977 字节、零 CR），未把本地导入结果写进合并提交。
- 规则门 `tools/check.ps1 -Suite persistence,content,application,architecture,runner,localization -KeepGoing -TimeoutSeconds 1800` → 退出码 **0**、6/6 PASS、`PASS: 2869 assertions`（`build/checks/20260921T063345070-31840`）。`summary.json`：`status=passed`、`before==after==B2BC0F3914CE9F9404F7D686FAFABDD24301579BC1B0821D7DF4A58DC7DEC6A1`、`rules.failed=[]`、`rules.unrun=[]`、`rules.retry=[]`、`error=""`。逐分类 localization／application／architecture／content／runner／persistence 全 PASS，无 `SOURCE CHANGED`。
- 窗口门（真实窗口，非沙箱）`tools/check.ps1 -UIOnly -UISuite route,localization,interface -TimeoutSeconds 1200` → 退出码 **0**、`UI PASS: 719 assertions`（`build/checks/20260921T063459019-29680`）。`summary.json`：`status=passed`、`before==after==B2BC0F39…`（与规则门同一冻结源码）、`ui.failed=[]`、`ui.unrun=[]`、`error=""`。逐分类 localization **51** PASS／route **255** PASS／interface **413** PASS。
- 文档门禁（`tools/check.ps1` 的独立阶段，本轮随上面两条同轮跑）：`DOCS PASS: 32 rule-class document(s), 1112 reference(s) checked, allowlist 6 entrie(s)`、`DOCS RESULT: PASS`；`summary.docs`：`status=passed`／`documents=32`／`references=1112`／`problems=0`／`allowlist=6`。无 `DOC FAIL`，也无「条目已无人引用」的 `DOC NOTE`。**允许清单条目数仍为 6，本轮零新增**：上游 v0.18.2 未引入新的悬空引用，未触发「带理由新增」的条件；余下 6 条仍指向两片未落地实现（`docs/spec/candidate-delta.md` 自报未落地、未落地的检查路由片），无条目可缩。
- 美术红最新状态（上一条记录登记的两条，已实测消失，新增红 **0**）：①「缺立绘 35 张 `witch_*`」是当时断言按卡牌 id 直查 `ILLUSTRATIONS` 的判定产物，不是新增素材缺口——上游 v0.18.2 把 `tests/interface_ui_cases.gd::card_illustrations` 改成按 `spec.art_type`／`art_source` 解析（`var art=spec.get("art_type",id)`），小魔女副本沿 `core/witch_character.gd::register` 声明的 `spec.art_type=original` 解析到原角色牌插画，本轮该断言通过。②6 张新卡（`self_satisfaction`／`psychological_suggestion`／`rally_spirit`／`desire_rune`／`forced_edging`／`forced_climax`）与 `itching_heart` 现在被断言内的 `desire_art` 组显式声明为共用 `assets/ui/cards/desire_magic.svg`，共用事实未变：本轮 `assets/ui/cards/` 新增文件 0 个、`ui/display_settings.gd` 也**没有**这 6 张卡的正式卡图条目，故这条是「按上游声明分组消红」而非补齐立绘；上游 v0.18.2 新增的 171 张图片走 `assets/art/`＋`ui/display_settings.gd` 的正式卡图通道，不在该断言的 `ILLUSTRATIONS` 面内。上游同日的「卡图校验接入既有魔女牌映射与明确共用插画」条目即记录这两处口径调整。
- 未跑（按本片边界）：`-Suite all` 全量回归、`-Impact`／`-Exhaustive`、`-VerifyRunner`、oracle、像素判据、性能测量、打包与发布（`tools/package*.ps1`）、Android 真机与触屏；窗口分类只跑 `route`／`localization`／`interface`，其余窗口分类（`home`／`equipment_art`／`hero_art`／`wall` 等）未跑，不能据此宣称它们通过；既有登记红项（`wall` 的 `prison resistance starts a fresh combat position`）不在本次分类范围内，未跑、未清除、未声称通过。本次只提交合并，未推送、未打标签、未改版本号、未打包。

## 2026-09-21｜卡面词条悬停分框（`docs/spec/card-terms.md`）

- 域：战斗外卡面悬停呈现（`ui/main.gd::_card_tooltip` 单一决策点、`ui/main.gd::_show_term` 单一呈现入口、`term_popup`／`_hide_term`／`_position_term`／`_ignore_mouse` 唯一属主链，触发面见同契约表）。只改接线与呈现：`_card_tooltip` 不再把词条拼进 `detail`，改按取源顺序传 `entry.terms`；`_show_term` 在 `terms` 非空时逐条生成方框（名称 CYAN 19px＋定义 TEXT 15px，框用既有 `ui/visual_theme.gd::surface`），`terms` 缺省或为空时逐字保持原单面板。未改判定、数值、`Cards`／`Balance` 语义、`Snapshot.REVISION`、View 键、本地化文件与 `docs/spec/` 正文。
- 现状实测（真实窗口，非沙箱；产物 `spire-godot/build/terms-current/`，不入库）：改动前图鉴与卡组一览悬停确实弹出 `TermExplanation`，但为**单面板**，词条以 `名称：定义` 并进 `detail` 行：`OBSERVE encyclopedia-mana_search-bound: labels=2 ["魔路检索 · 拘束","检索：从抽牌堆抽取指定类型的牌。"]`；卡组一览 `deck-magic_slip-bound: labels=2`，detail 为施法行＋两条 `名称：定义` 的五段合并文本。定性：**本片是「呈现不合 StS 式」而不是接线缺失**——触发面已挂在同一 `_card_tooltip` 上，缺的是一条词条一个方框。截图 `encyclopedia-mana_search-bound.png`、`encyclopedia-mana_search-free.png`、`deck-magic_slip-bound.png`。改动后同路径复查：`children=["魔路检索 · 拘束","BOX[\"检索\",\"从抽牌堆抽取指定类型的牌。\"]"]`、`overlaps=false`；无 `terms` 的 `_show_term(anchor,{"label":"","detail":"短提示"})` 仍为单标签面板（71×39）。
- 判据 7 条落地位置：1／2／6／7 → `tests/encyclopedia_ui_cases.gd::card_terms`（悬停框集合与顺序、翻面取另一面集合、框与锚面矩形不相交且点击仍落到卡面自身界面、无 `terms` 调用保持单面板）；3／4 → `tests/interface_ui_cases.gd::card_terms`（卡组浏览实例卡保留物理实例合并出的升级进度、框集合等于当前面词条、悬停前后 `export_snapshot()` 相等且 `ui.view.version` 不变）；5 → `tests/touch_ui_cases.gd`（长按同一卡面得到与悬停相同的框）。期望值由 `tests/interface_ui_cases.gd::TERM_PINS` 字面钉住（形如 `tests/card_text_cases.gd` 既有措辞钉）：与同一 `face_keywords` 源比较对「改文案／删词条」不敏感，故按契约「字面比较」用钉值。
- 唯一改写的既有断言：`tests/card_power_ui_cases.gd::mana_search` 的 `SEARCH UI hover…`，由「含 `检索：从抽牌堆抽取指定类型的牌。` 连续子串」改为「该面唯一框，名称与定义分别断言（钉值），仍限 `visible_text(tip).length()<65`」；未删除、未放宽成「弹窗非空」。`POT UI`／`DUAL UI`／`MAGIC SLIP`／`ROUTE UI` 等悬停断言未改。
- 门禁 1（规则分类）：`tools/check.ps1 -Suite architecture,localization,persistence -KeepGoing -TimeoutSeconds 1200` → exit 0，`SUITE RESULT: localization／architecture／persistence PASS`、`PASS: 1677 assertions`。`summary.json`（`build/checks/20260921T114254533-15400`）：`status=passed`、`error=""`、`before==after==3B531E31F01B1C6830A423F5222F35291FA47F6E9F289AA772A260CE2B6CA895`、`rules.failed=[]`、`rules.unrun=[]`、`rules.retry=[]`。
- 门禁 2（窗口分类，真实窗口）：`tools/check.ps1 -UIOnly -UISuite interface,encyclopedia,card_power,events,rewards,touch,status,casting,route,localization -KeepGoing -TimeoutSeconds 1500` → exit 0，10／10 分类 PASS、`UI PASS: 2213 assertions`（`20260921T114352199-45100`，600.92s）。`summary.json`：`status=passed`、`before==after==3B531E31…`（与门禁 1 同一冻结源码）、`ui.failed=[]`、`ui.unrun=[]`；逐分类 localization／card_power／encyclopedia／touch／casting／route／status／interface／events／rewards 全 PASS。契约点名的 `card_power` 与协调者点名的 `route,localization,interface` 均在列。
- 文档门禁（随上面两轮同跑）：两轮均 `DOCS PASS: 34 rule-class document(s), 1275 reference(s) checked, allowlist 6 entrie(s)`、`DOCS RESULT: PASS`；`summary.docs`：`status=passed`／`documents=34`／`references=1275`／`problems=0`／`allowlist=6`。允许清单 6 条，本片**零新增、零缩减**（未被取代的悬空引用照旧）。
- 判据敏感性逐条实测（改坏即红、还原即绿）：
  1. 改 `data/card_text.gd::TERMS.search.detail` 一字 → `encyclopedia` 红：`TERMS UI encyclopedia hover renders one box per bound term in metadata order` 与翻面框断言（`20260921T112954412-28156`，248 断言）。还原后门禁 2 的 encyclopedia PASS（`20260921T114352199-45100`）。
  2. 把 `ui/main.gd::_card_tooltip` 的 `side` 取值固定成 `"bound"` → `encyclopedia` 红 `TERMS UI flipping the face replaces the boxes with the other side terms`（`20260921T113029189-37108`）。还原后同上绿。
  3. 删掉 `ui/main.gd::_display_card` 的 `source` 合并 → `interface` 新增红仅 `TERMS UI deck instance hover keeps the growth text merged from the physical card`（`20260921T113104018-17712`）。还原后 interface PASS（`20260921T114352199-45100`）。
  4. 在 `_card_tooltip` 里写 `game.state.tick+=1` → `interface` 红 `TERMS UI deck hover changes no state and no view version`（`20260921T113915122-39308`）。按契约另一次注入 `ui.actions.find("flow",{"kind":"end"})`＋`game.dispatch(…)`（`20260921T113303165-38100`）：该轮 `DECK browsing, filtering, sorting and Escape preserve full game state` 等既有状态断言变红，但本用例悬停处的注入被陈旧候选版本拒绝（探针实测该处 `game.dispatch(...).ok=false`、`state` 未变），本断言未红——如实登记，不声称该次注入已证到本断言。
  5. 让 `ui/touch_input.gd::show_details` 不再对卡面 `mouse_entered.emit()` → `touch` 红 `TOUCH hold shows the same term boxes as hover: []`（`20260921T114014614-30832`）。还原后 touch PASS（`20260921T114352199-45100`）。
  6. `_position_term` 右侧偏移改 `-12` → `encyclopedia` 红 `TERMS UI term boxes clear the anchor card and stay inside the viewport`（`20260921T114049798-42444`）。在该「压住锚面」条件下再删 `_ignore_mouse(term_popup)` → 本用例点击断言仍绿（`20260921T114126851-41404`）；机制：弹窗正式路径与锚面不重叠，且指针离开锚点即 `mouse_exited → _hide_term` 先销毁弹窗，卡面所在 `drawer_layer` 在 `layout` 内位于 `term_popup` 之后，输入拾取仍在弹窗之上。故契约判据 6 的「删 `_ignore_mouse` → 点击断言红」这一条**未能实测证明**，如实登记；`_ignore_mouse` 未删、按契约保留。
  7. 把无 `terms` 的单面板强改成必须分框 → `intent` 红 `INTENT UI short tooltip fits text without fixed-width blank space`（`20260921T114204980-25392`，该轮 7 条红＝既有 6 条＋本条）。还原后 `intent` 回到既有 6 条（`20260921T115802774-21160`），与改动前基线（`20260921T112413425-42452`，stash 掉本片改动后的 HEAD 树）逐行相同。
- 既有红项（不属本片、未清、未声称通过）：`intent` 分类 6 条——`LAST ORDER UI completed action is not described as idle`、`LAST ORDER UI eye obstruction retains its separate explanation`、`INTENT UI mouse hover shows only the concise sentence`、`INTENT UI first explanation fits viewport`、`INTENT UI right-side explanation automatically opens to left`、`INTENT UI blind hover only explains observation restriction`；改动前与还原后两次实测条数与文本完全相同。本片新增红为 0（门禁 1／2 全绿；判据敏感性引入的红均在还原后消失）。`card_power`／`interface` 的既有红在本轮门禁 2 中未出现（实测 PASS），未据此改写任何既有断言。
- 未跑：`-Suite all` 全量回归、`-Impact`／`-Exhaustive`／`-VerifyRunner`、oracle、像素判据、性能测量、打包与发布（`tools/package*.ps1`）、Android 真机与触屏；窗口分类只跑上列 10 类，其余分类（`home`／`equipment_art`／`hero_art`／`wall`／`enemy_feedback` 等）未跑，不能据此宣称它们通过。商店买卡／去卡、事件卡选项、奖励选牌、保留选牌未增设悬停断言（四者与图鉴／卡组共用 `ui/main.gd::_card`＋`_card_tooltip` 单一入口，按契约由验收程序 3 在真实窗口逐点覆盖），本轮只在 `events`／`rewards` 分类的既有用例上确认未回归。根 `AGENTS.md` 文档入口表本次未加 `docs/spec/card-terms.md` 行（该文件存在未提交的在途改动，混提会污染他人工作），契约文件本身仍由本片提交。本次只提交源码、测试与记录，未推送、未打标签、未改版本号、未打包。

## 2026-09-23｜日文本地化补齐：三片新增界面文案的 ja 译文（分支 `seed-chip-save-upload`）

- 域：`spire-godot/assets/localization/ja_JP.json` 的 17 条语义 ID 日文译文补齐——`ui.map.seed`／`ui.map.seed_copied`；`ui.feedback.save.attached`／`declined`／`unchecked`／`none`／`uncaptured`／`invalid`／`oversized`；`ui.run_review.title`／`identity`／`route`／`deck`／`progress`／`no_route`／`deck_empty`／`copy`。上游 `8398b1c`（2026-09-22）落地的 ja 体系缺这三片新增 key（补齐前 `ja_JP.json.messages` 64 条 vs `zh_CN.json`／`en_US.json` 81 条）。只改该文件；`zh_CN.json`／`en_US.json`、源码、测试与 `docs/spec/` 零改动。
- 资源校验（一次性 python，脚本不入库）：`ja_JP.json.messages`＝**81**；`zh_CN 有 ja 无`＝`[]`、`ja 有 zh 无`＝`[]`；`source` 与 `zh_CN.text` 逐字一致 0 例外；占位符集合逐条相等（`{initial}`／`{iteration}`／`{name}`／`{size}`／`{floor}`／`{nodes}`，名字与数量都不变）；条目形状均为 `{source,text}`；命中既有中文残留标记词表 0 条。`git diff --numstat` 该文件 **+68/−0**（17 条×4 行，纯新增；键序按 zh_CN，插在 `ui.settings.music_volume` 与 `ui.settings.doubao_voice_enabled` 之间）。
- 术语口径：沿 `ja_JP.json` 既有 64 条与 `tools/build_japanese_catalog.py` 的人工词表（卡组＝`デッキ`、塔路＝`塔路`、存档＝`セーブデータ`、反馈服务＝`フィードバックサービス`、层＝`層`、迭代＝`第{iteration}回目`），并参考 `legacy-ja_JP.json` 同术语的既有译法（`「…」をコピーしました。`、`下書きを保存しました。` 的完整句口径、`・` 分隔）；未另立术语，未引入中文残留，只译界面文案，不动规则事实与占位符。
- 门禁 1（规则；`GODOT_BIN` 指向 `Godot_v4.7.2-stable_win64_console.exe`）：`tools/check.ps1 -Suite localization -KeepGoing` → 退出码 **0**、`SUITE RESULT: localization PASS`、`PASS: 289 assertions`（运行号 `20260922T141707204-44916`）。`summary.json`：`status=passed`、`before==after==FE003DC35B1850E919AC0F99A2EE6AFD2D49EBB8FF4F2A0C46640854D86DC7B5`、`docs.status=passed`（34 份规则类文档、1282 条引用、0 问题、允许清单 6）、`rules.passed=["localization"]`、`rules.failed=[]`、`rules.unrun=[]`、`error=""`。
- 门禁 2（窗口分类，**真实窗口、非沙箱**）：`tools/check.ps1 -UIOnly -UISuite localization -TimeoutSeconds 900` → 退出码 **0**、`SUITE RESULT: localization PASS`、`UI PASS: 52 assertions`（`UI SUITE localization: 52 assertions, 6039 ms`；引擎日志 `Godot Engine v4.7.2.stable.official.ed1daf0bf`＋`OpenGL API 3.3.0 NVIDIA`，无 `--headless`），运行号 `20260922T141728159-24040`。`summary.json`：`status=passed`、`before==after==FE003DC3…`（与门禁 1 同一冻结源码）、`ui.passed=["localization"]`、`ui.failed=[]`、`ui.unrun=[]`、`docs.status=passed`。本片**新增红 0**；两条门禁均无 `SOURCE CHANGED`。
- 敏感性证明（`source` 与 zh_CN 不一致必须红）：把 `ui.map.seed_copied` 的 `source` 改一字（`已复制`→`已複製`）→ `tools/check.ps1 -Suite localization` 运行 `20260922T141809188-47348` 退出码 **1**、`FAIL: 4/289 assertions; 4 engine errors`、`SUITE RESULT: localization FAIL`，诊断 `{"code":"stale_translation","key":"ui.map.seed_copied"}`；红项 4 条＝`LOCALE shipped resources load locally and default to Chinese`（诊断非空）、`LOCALE English and Japanese are complete for registered IDs`（缺译 1）、`LOCALE registered Japanese copy resolves through its semantic ID`、`LOCALE Japanese flask actions keep deposit and withdrawal verbs`（整包原子拒绝后 ja 全量回退中文的连带红）。还原（sha256 与改动前同为 `7C7E6B9993423951FE1F558F78E32997F0CBEF8F60666C2A638E995D12FDBAE1`）后运行 `20260922T141838995-10168` 退出码 **0**、`PASS: 289 assertions`，指纹回到 `FE003DC3…`——门禁 1／2 与还原后是逐字节同一版本。红来自既有 `ui/localization.gd` 的源文版本校验，未改任何断言。
- 既有红项与本片红：上述两轮门禁全绿，本片新增红 0；未跑分类里的既有登记红（`intent` 6 条、`wall` 的 `prison resistance starts a fresh combat position` 等）不在本次分类内，未跑、未清、未声称通过。
- 未跑：`-Suite all` 全量回归、`-Impact`／`-Exhaustive`／`-VerifyRunner`、oracle、像素判据、性能测量、打包与发布（`tools/package*.ps1`）、Android 真机与触屏；窗口分类只跑 `localization`，其余窗口分类未跑。日文界面的观感（按钮宽度、换行与断行）未逐屏人工试玩检查；剪贴板判据只在门禁 2 的真实窗口内成立，未做安卓侧核对。
- 在途改动：工作区另有他人在途修改 `spire-godot/data/card_text.gd`（`检索`→`检索术`），非本片所改、本次不提交但保留；本片提交只含 `ja_JP.json` 与两份记录，未推送、未打标签、未改版本号、未打包。

## 2026-09-23｜词条悬停分框收口：框宽计边距、事件／奖励悬停断言、长内容几何（分支 `seed-chip-save-upload`）

- 域：战斗外卡面悬停的**呈现接线**——`ui/main.gd::_show_term` 的框宽测量（缺陷 A），以及悬停断言面：`tests/event_ui_cases.gd`（事件卡选项）、`tests/reward_ui_cases.gd`（奖励选牌）、`tests/interface_ui_cases.gd::card_terms`（卡组一览活卡面的长内容几何）。词条取源、判定、`data/`、`core/`、本地化与 `docs/spec/` 正文零改动；契约（`docs/spec/card-terms.md` 判据 6 与依赖表）由 planner 属主，本片不写。
- 缺陷 A 根因：`ui/main.gd::_show_term` 只用标签文本宽设 `column.custom_minimum_size.x`，而每个词条框是 `PanelContainer`（`ui/visual_theme.gd::surface`，左右 content_margin 各 12px），框内标签可用宽比列宽少 24px，文本宽落在该 24px 带内的框末必然换行（实测短 22px）。
- 缺陷 A 修法（只动呈现接线）：把原内联测量抽成单一测量路径 `ui/main.gd::_text_line_width(subtree)`（列与框共用，同一语义一条路径），每个词条框按**自身**标签文本宽设 `box.custom_minimum_size.x=clampf(ceilf(_text_line_width(box))+2,40,326)+chrome`，`chrome=frame.get_margin(SIDE_LEFT)+frame.get_margin(SIDE_RIGHT)` 从该框自己的 stylebox 读边距（不写死 24，token 改边距即跟随）；列的 `clampf(ceilf(...)+2,40,326)` 原式保留，故 `terms` 缺省／为空时单面板逐字不变（`intent` 补充轮仍恰为既有 6 条红，未出现「单面板被强改分框」的第 7 条）。未改 `_position_term` 常量、`_ignore_mouse`、`_card_tooltip` 的取源与 `_card` 的信号连接。
- 缺陷 A 真实窗口尺寸对照（1600×900，真实窗口非沙箱；探针 `spire-godot/build/term_probe.gd` 与截图在 `spire-godot/build/`，均为一次性产物、不入库；`presplit` 树＝`git show 7a9546f^:spire-godot/ui/main.gd`）：

| 面 | 分框前 `7a9546f^` | 修前（HEAD `621952c`，框宽未计边距） | 修后（本片） |
| --- | --- | --- | --- |
| 图鉴 `mana_search` 拘束面 | 266×78（单面板，词条并进 detail） | 221×151（框 197 宽→框内容 173＜文本 195，定义换 2 行） | **245×125**（框 221→内容 197≥195，定义 1 行） |
| 图鉴 `mana_search` 自由面 | 350×130 | 350×231 | 374×231 |
| 卡组一览 `endless_war_goddess` 拘束面（活卡面，含成长文案） | 350×494 | 350×710 | 374×710 |
| 图鉴 `hannya_1`（全库 233 面最高） | 未测（presplit 轮只跑前两面） | 350×632 | 374×632 |

- 全库扫描（探针 `--sweep`，对 `data/card_rules.gd::SPECS` 的 121 张卡两面各悬停一次共 242 次，其中 233 次弹出弹窗、9 次为无词条且无其它行的面（走 `_hide_term`）；真实窗口）：修前与修后均 `viewport_overflow=0`；最高的仍是 `hannya_1` 632 高（宽 350→374）。活卡面最高实测为卡组一览的 `endless_war_goddess` **374×710**（占 900 高视口 79%，锚点 y=572 时 clamp 后弹窗底 886），即本片长内容用例选它的理由：词条 4 条、最长定义 825px，是 y clamp 的最坏用例。**当前没有任何面压出屏底**（最高 710＜可容纳 826），故风险 B 未落地为真实缺陷，新断言是回归守卫而非复现已知红。
- 新增断言（3 个文件共 9 条：5 条行为＋4 条夹具守卫）：
  - `tests/event_ui_cases.gd`（`Practice_binding_cleric` 净化→`remove` 移除选牌真实入口，既有流程内追加）：`EVENT UI card option tile maps to a real deck card`、`EVENT UI card option fixture carries face terms`（夹具守卫）、`EVENT UI card option hover boxes equal the hovered face terms`、`EVENT UI card option term boxes clear the anchor card`。
  - `tests/reward_ui_cases.gd::battle_loot`（种子 78 精英奖励→卡牌三选一真实入口）：`LOOT UI reward choice fixture carries face terms`（夹具守卫）、`LOOT UI reward choice hover boxes equal the hovered face terms`、`LOOT UI reward choice term boxes clear the anchor card`。二者消掉依赖表「已授权但未加」的两条，同时消掉「依赖表与实现文件面不一致（多写）」。
  - `tests/interface_ui_cases.gd::card_terms`（既有卡组一览夹具追加一张活卡）：`TERMS UI tallest face fixture sits in the deck`（夹具守卫）、`TERMS UI tallest face keeps every term box inside the viewport and clear of the anchor`（一条覆盖视口内含与不相交）。
  - 事件／奖励两条的期望值取契约点名的公开入口 `data/balance.gd::card_metadata(type).face_keywords[side]`，`type` 由物理身份解析（事件：`physical_uid`→`ui.view.deck_cards`；奖励：`state.reward_options[0]`→`RewardChoice_<type>`）；字面措辞钉仍只在判据 1 的 `tests/interface_ui_cases.gd::TERM_PINS`。悬停前均先移开指针、按锚面真实矩形中心悬停。
- 新／改断言敏感性逐条实测（变异都在 `ui/main.gd` 上做，还原后与 `spire-godot/build/main.gd.orig` 逐字节相同，`cmp` 通过；还原状态＝门禁 1／2 的指纹 `FC5D650B…`）：
  1. 错面变异（`ui/main.gd::_card_tooltip` 的 `side` 固定为 `"free"`）→ `tools/check.ps1 -UIOnly -UISuite interface,encyclopedia,events,rewards -KeepGoing` 运行 `20260922T154738796-36084` exit **1**、四类全 FAIL：新增的 `EVENT UI card option hover boxes equal the hovered face terms` 红（渲染出自由面 `蓄力`，期望拘束面 `挣扎`）、`LOOT UI reward choice hover boxes equal the hovered face terms` 红（渲染 2 框＝自由面，期望 4 框），另有既有的图鉴／卡组框集合断言红。
  2. 压住锚面变异（`ui/main.gd::_position_term` 右侧偏移 `anchor.end.x+12`→`anchor.end.x-12`）→ 运行 `20260922T155152668-41600` exit **1**：`TERMS UI tallest face keeps every term box inside the viewport and clear of the anchor`、`EVENT UI card option term boxes clear the anchor card`、`LOOT UI reward choice term boxes clear the anchor card` 三条红（几何面有真判据）。
  3. 高度 clamp 变异（`ui/main.gd::_position_term` 的 y 上界 `maxf(74,886-term_popup.size.y)`→`900`，即丢掉高度项）→ `tools/check.ps1 -UIOnly -UISuite interface -KeepGoing` 运行 `20260922T155541376-31448` exit **1**，该分类**唯一**红＝`TERMS UI tallest face keeps every term box inside the viewport and clear of the anchor`（锚点 y=572、弹窗 710 高→底 1282＞900）。此条是本片对「弹窗高度只有 clamp 兜底」的直接守卫。
  4. 夹具守卫 4 条不另做变异：它们只在夹具卡不在位时红（例如卡组没有该类型、事件选牌为空），属取数守卫，不声称行为敏感性。
- 点击断言（`tests/encyclopedia_ui_cases.gd` 的 `TERMS UI real click on the hovered card still opens its own surface`）敏感性结论——**证到，但需要比复核建议更强的变异**：
  - 复核建议的变异（把弹窗定位改成覆盖点击点＋让弹窗不忽略输入）本片复现为：`ui/main.gd::_position_term` 改成把弹窗居中压在锚面矩形上、并删掉 `_ignore_mouse(term_popup)`。以探针 `--terms-case`（真实窗口，直接调用**未改动的** `tests/encyclopedia_ui_cases.gd::card_terms` 全函数，日志 `spire-godot/build/mutation-m3-terms-case.log`）实测：11 项检查中 1 红＝`TERMS UI term boxes clear the anchor card and stay inside the viewport`（几何），点击断言**仍绿**。机制：`Pointer.press` 先发一次 `InputEventMouseMotion`，此时弹窗已在指针下→卡面收到 `mouse_exited`→`_hide_term()` 先销毁弹窗，随后按下仍落到卡面。复核者的观察在本片复现。
  - 在上一条基础上再删 `ui/main.gd::_card` 的 `button.mouse_exited.connect(_hide_term)`（弹窗压住点击点＋不忽略输入＋指针离开不关闭）→ 同一探针运行（日志 `spire-godot/build/mutation-m4-terms-case.log`）中 `TERMS UI real click on the hovered card still opens its own surface` **红**（该轮 8 项检查 3 红：几何、点击、`TERMS UI escape closes only the card surface`）。
  - 结论：该断言有已知敏感性变异（上条），它钉的是「指针离开即关闭＋弹窗不拦截」这组机制；单独删 `_ignore_mouse` 或单独压住锚面都不会让它红，`_ignore_mouse` 仍无机械判据、按契约防御保留。在完整 `encyclopedia` 分类里该断言无法单独观测到红：同分类更早的 `ART INSPECT native card click uses current face source texture without thumbnail resampling` 断言同一可观测项（点击被拦截）且先红并触发 `SCRIPT ERROR` 中止分类（运行 `20260922T155704476-13596` exit 1、229 断言），故本条用探针单跑取证。
- 验收程序 1–5 逐步登记（真实窗口 1600×900；探针与截图见上）：
  1. **部分**：图鉴全库 233 个面逐面悬停（`--sweep`）＋`mana_search`／`hannya_1` 两面翻面后再悬停；截图 4 张（`before-encyclopedia-mana_search-bound.png`、`before-encyclopedia-mana_search-free.png`、`after-encyclopedia-hannya_1-bound.png`、`after-encyclopedia-hannya_1-free.png`，均在 `spire-godot/build/`）。未逐面截图（只截代表面），未做人工逐张目视核对。
  2. **部分**：卡组一览（整备屏 `OpenDeck`）活实例 `endless_war_goddess` 悬停并截图 `after-tall-face.png`（探针 `--tall`，与 `tests/interface_ui_cases.gd::card_terms` 同一夹具；同面另有 `before-deck-endless_war_goddess-bound.png`／`after-deck-endless_war_goddess-bound.png` 修前修后对照）；**回顾面板卡组未跑**（未取本局回顾面板入口）。
  3. **部分**：事件卡选项（`binding_cleric` 净化→移除选牌）与奖励选牌（种子 78 精英奖励→三选一）各悬停一次并截图 `after-event-card-hover.png`、`after-reward-card-hover.png`，两条断言已进门禁 2 的 `events`／`rewards`；**商店买卡／去卡、保留选牌未跑**（无点名用例、需真实窗口逐点操作，本片未做）。
  4. **未跑**：真实窗口长按逐点确认（`touch` 分类的既有长按等价断言在本片门禁 2 PASS，覆盖判据 5；未做触摸／长按的真实窗口逐点确认）。
  5. **部分**：既有点击断言在门禁 2 PASS；本片另用探针实测了「点击被拦截」的变异（见上）；**商店购买／翻开等逐点点击确认未逐点跑**。
- 轮次补登（复核漏枚举的两个运行号，目录可查 `spire-godot/build/checks/<运行号>`；任务书写的是 `20260922T…`，实际目录为 `20260921T…`，后缀与时刻相同，按实际目录登记）：
  - `20260921T112548298-13648`：`-UIOnly -UISuite card_power,encyclopedia,touch,interface`；`status=passed`、`ui.passed=[card_power,encyclopedia,touch,interface]`、`ui.failed=[]`、`ui.unrun=[]`（复核的绿色基线轮）。
  - `20260921T113202302-41408`：`-UIOnly -UISuite interface`；`status=failed`、`ui.failed=["interface"]`（415 断言），红项自首条起：`MENU native click opens secondary actions`、`INTERFACE actual navigation button available: OpenLog`、`HEADER preparation and visible action log use the same fourth turn`、`DECK browsing, filtering, sorting and Escape preserve full game state`、`escape card cannot target enemy`、`hero free card resolves directly without target selection`，并有两次 `SCRIPT ERROR`。该轮首条断言（真实点击打开菜单）即红，与「点击未落到控件」的征状一致；复核报告未给该轮归属，本片只如实登记其内容，不推断其变异。
- 门禁 1（规则；`GODOT_BIN`＝`Godot_v4.7.2-stable_win64_console.exe`）：`tools/check.ps1 -Suite architecture,localization,persistence -KeepGoing -TimeoutSeconds 1200` → 退出码 **0**；`SUITE RESULT: localization／architecture／persistence PASS`；`PASS: 1795 assertions`（`CHECK rules: 61.04s`）。运行号 `20260922T160155184-10180`。`summary.json`：`status=passed`、`error=""`、`before==after==FC5D650B397EAF2C6A0D1CDEE500C830B5C3D42057D4E1E353965E878F10862D`、`rules.failed=[]`、`rules.unrun=[]`、`rules.retry=[]`、`rules.complete=true`、`ui.selected=[]`。
- 门禁 2（窗口分类，**真实窗口、非沙箱**）：`tools/check.ps1 -UIOnly -UISuite interface,encyclopedia,card_power,events,rewards,touch,casting,route,localization -KeepGoing -TimeoutSeconds 1500` → 退出码 **0**；9／9 分类 PASS；`UI PASS: 1994 assertions`（`CHECK ui: 471.47s`）。运行号 `20260922T160640439-37168`。逐分类：localization 52、card_power 387、encyclopedia 248、touch 26、casting 59、route 255、interface 422、events 184、rewards 361。`summary.json`：`status=passed`、`before==after==FC5D650B…`（与门禁 1 同一冻结源码）、`ui.failed=[]`、`ui.unrun=[]`、`ui.retry=[]`、`ui.complete=true`。引擎日志首行 `Godot Engine v4.7.2.stable.official.ed1daf0bf`＋`OpenGL API 3.3.0 NVIDIA`，无 `--headless`。
- 提交后复核（记录本轮追加时）：`tools/check.ps1 -Suite runner -ListOnly`（`PLAN ONLY`，不计通过）运行 `20260922T162531204-37680`，`summary.json` 的 `before==after==FC5D650B397EAF2C…` 与门禁 1／2 相同——即提交的源码／测试字节与两门所跑的冻结源码同一（`docs/record/**` 不在源码指纹集合内，追加记录不改指纹）。
- 新增断言计数：interface 420→**422**、events 180→**184**、rewards 358→**361**（对比上一轮同范围 `20260922T153846992-34760`；该轮跑在 LF 行尾的测试文件上，已被本轮 CRLF 规范化后的同一内容取代，其指纹 `19D288F6…` 不再作为本片证据）。
- 文档门禁（随两轮同跑）：`DOCS PASS: 34 rule-class document(s), 1301 reference(s) checked, allowlist 6 entrie(s)`、`DOCS RESULT: PASS`；`summary.docs`：`status=passed`／`documents=34`／`references=1301`／`problems=0`／`allowlist=6`（零新增、零缩减；本片未动规则类文档）。
- 补充轮（不在任务点名分类内，用于判据 7 的单面板路径）：`tools/check.ps1 -UIOnly -UISuite intent,status -KeepGoing -TimeoutSeconds 1200` → 退出码 **1**（intent 既有红，非本片红），运行号 `20260922T160317032-2764`；`intent` 48 断言 FAIL、`status` 230 断言 PASS；`intent` 红项恰为既有 6 条（逐字相同），未出现「单面板被强改分框」时的第 7 条 `INTENT UI short tooltip fits text without fixed-width blank space` → 无 `terms` 的调用路径与改动前一致。`summary.json`：`before==after==FC5D650B…`。
- 环境失败登记（不是代码红）：本片第一次窗口门 `20260922T151244526-31324` 因 Godot 窗口被最小化（`IsIconic=true`）致帧循环被系统节流，card_power 未跑完即触发 `-TimeoutSeconds 1500`：`status=failed`、`error="Godot check exceeded 1500s"`、`ui.passed=["localization"]`、`ui.failed=["card_power"]`、`ui.unrun=[其余 7 类]`、`before==after`（源码未变）。随后用一次性脚本 `spire-godot/build/keep-awake.ps1`（每 2 秒对最小化的 Godot 窗口 `ShowWindow(SW_SHOWNOACTIVATE)`，日志 `spire-godot/build/keep-awake.log` 记到一次恢复）保住渲染窗口，之后各轮耗时与历史同范围一致（card_power 155s／rewards 146s）。
- 既有红项（分开列，未清、未声称通过）：`intent` 分类 6 条——`LAST ORDER UI completed action is not described as idle`、`LAST ORDER UI eye obstruction retains its separate explanation`、`INTENT UI mouse hover shows only the concise sentence`、`INTENT UI first explanation fits viewport`、`INTENT UI right-side explanation automatically opens to left`、`INTENT UI blind hover only explains observation restriction`（与既有登记逐字相同，见上文补充轮）；`wall` 的 `prison resistance starts a fresh combat position` 等不在本片分类内，未跑。**本片新增红 0**（两轮门禁全绿；三个敏感性变异引入的红均在还原后消失，还原文件与变异前逐字节相同）。
- 未跑：`-Suite all` 全量回归、`-Impact`／`-Exhaustive`／`-VerifyRunner`、oracle、像素判据、性能测量、打包与发布（`tools/package*.ps1`）、Android 真机与触屏；窗口分类只跑上列 9 类＋补充的 `intent`／`status`，其余分类（`home`／`equipment_art`／`hero_art`／`wall`／`enemy_feedback`／`baseline` 等）未跑。验收程序 4 全未跑，2／3／5 的未跑项见上。
- 已知不可观测项（如实登记，不声称由断言保证）：①「框内文本不换行」没有断言——契约判据 6 只判几何，框宽与字号／配色同属机制声明，本片对缺陷 A 的修复只有真实窗口实测与截图作证，把框宽改回旧算法（`box.custom_minimum_size.x` 不设）**不会**让任何断言变红；②`_ignore_mouse(term_popup)` 仍无机械判据（见上点击断言结论）。
- 产物：探针与截图是 `spire-godot/build/` 下一次性产物、不入库（`term_probe.gd`、`term-probe-*.log`、`before-*`／`after-*`／`presplit-*.png`、`mutation-m1.log`／`mutation-m2a.log`／`mutation-m2b.log`／`mutation-m3.log`、`mutation-m3-terms-case.log`、`mutation-m4-terms-case.log`、`keep-awake.ps1`／`keep-awake.log`）；运行号目录 `spire-godot/build/checks/<运行号>`。本次只提交源码、测试与记录，未推送、未打标签、未改版本号、未打包。

## 2026-09-23｜候选层移除 R1：判定收口（分支 `seed-chip-save-upload`，commit `20e3ff1`）

- 域：core 判定收口——`core/game.gd::eligibility`／`eligibility_takeover` 成为全仓唯一写 `valid`／`reason` 的位置；`core/first_turn_control.gd::select` 接管阻断并入判定（DUP2 销项）；`tests/architecture_cases.gd` 新增 G4／G6。契约 `docs/spec/candidate-removal.md` §4 R1 行／§5；依赖表 `candidate-removal-dependencies.md`。
- 实现者证据：迁移面复算 183 文件与依赖表逐文件一致（漂移＝无）；未改源码基线 26 单元 × 58 路径＝1508 路径（`build/r1-20260923/baseline.json`，脚本 `r1_baseline.gd` capture／compare 双模式）；实现后 `BASELINE EQUIVALENCE: PASS cells=26 paths=1508`、首个差异路径＝无；敏感性两轮实测——G4 把接管改回自写→红 `20260923T060536-61847-sens-g4`（3 断言）、还原→绿 `20260923T060633-61856-sens-g4-restore`；G6 判定文案改一字→红 `20260923T060748-61911-sens-g6`（首个差异 `shop:0.reject_invalid`）、还原→绿 `20260923T060841-61925-sens-g6-restore`。
- 门禁：`tools/check.ps1 -Suite architecture,relics,runner -Impact -TimeoutSeconds 900`（`GODOT_BIN`＝4.7.2 console）→ 运行号 `20260923T061728262-31144`，exit 0、`status=passed`、`before==after==3C521084…`、10 分类 PASS、`PASS: 9384 assertions`；文档门禁 `DOCS PASS`（35 文档／2071 引用／允许清单 6 零新增）。判读偏差：`first_turn_control` 不是注册分类（接管用例注册在 `relics`），故以 `relics` 覆盖；另有一轮 `20260923T061055514-34112` 因运行中改行尾被判 `source_changed`，未算通过、已重跑。
- 独立复核（新会话、只读主树、自做变异）：P1–P4 全过、**无产品缺陷**；行键集合（merge 序＋`extra_traction` erase）与抽出前逐项一致；在父提交 `d7edeaa` 上独立复算基线与实现者基线 0 差异；自做 3 个变异（接管改回自写→G4 红 3 断言；保留 `extra_traction` 键→G6 红 `battle:0.view`；eager detail 尾加空格→G6 红 `battle:0.view`）全部还原、临时 worktree 已移除、主树零残留。
- 复核登记的检查面缺口（契约中性、未改产品；协调者处置如下）：①G4 的 stray 断言只扫 `valid`，core/ 内「只写 reason」的第二判定不会变红（现存 `core/game_view.gd` 的 `reason` 只读复制可容忍）——**随 R2 前置补正**（加宽写点扫描面并复跑 architecture，属 R1 检查面补正）；②G6 对行键**顺序**不敏感（`JSON.stringify` 排序），order 仅由源文本核对支撑——如实登记为已知覆盖边界；③card 组按需 detail 内容不在 58 路径内（R1 未改该分支，无风险）——如实登记；④契约同步债——**已随本条完成**（`candidate-removal.md` 的 D-2／DUP2 改写为销项后事实）。
- 协调者接口核对：提交面 3 文件 ⊆ 允许面；`eligibility`／`eligibility_takeover` 已落地、`core/first_turn_control.gd` 零写点、`extra_traction` 行内 erase 复核通过；提交前后 `git status` 干净。
- 未跑（未验证）：Gherkin 8（接管真人 UI 路径，属 R2 判据）；UI 分类、`-VerifyRunner`、G1／G2／G3／G5／G7／G9（属 R2–R5）；全量回归、打包与发布。
- 产物：`build/r1-20260923/`（基线、脚本、敏感性／门禁日志）、实现者与复核者心跳、复核工作日志均为已忽略目录一次性产物，**随本条登记清理**；运行号身份以 `build/checks/<运行号>` 为准。

## 2026-09-23｜候选层移除 R2：指令收口＋后端身份复核（分支 `seed-chip-save-upload`，commit `a18860a`＋第 0 步 `3bbf1e1`）

- 域：前端指令收口（`ui/command_router.gd`／`ui/command_routes.gd`）＋`core/game.gd::dispatch` 改收类型化指令；39 kind 与 `COMMAND_KEYS`／`ROUTES` 落地；A1–A60 收敛（直连 0）。
- 实现者证据：边表复算 `ui/` 内 `_submit(` 2 命中（`ui/command_router.gd:45` 唯一调用＋`ui/main.gd:2060` 定义）、`.dispatch(` 1 命中（`ui/main.gd:2075`）；`command_router.emit` 13 文件 59 命中；迁移面 183 文件清单复算一致。判据：G1／G2 落 `tests/architecture_cases.gd`（arch 527 断言）、G3 分落 `tests/persistence_cases.gd` 与 `tests/display_ui_cases.gd`（display 160 断言）、G8 落 `display_ui_cases.gd`；`tests/ui_smoke.gd::_index_boundary_tests` 四条未删未放松（仅调用形态迁移）。
- 门禁：规则门 `20260923T092539286-22292`（PASS 21513 断言、`before==after`、docs PASS allowlist 6）；runner `20260923T094055495-53784` PASS；UI 门 `20260923T094128373-39396`——display／touch／body_layout／targeting PASS，**interface FAIL 3 条**（`INTERFACE outside click dismisses without activating covered attack`／`INTERFACE actual navigation button available: CloseDrawer`／`BOOK tutorial is a highlighted permanent header button`，后两条为级联）。
- **interface 序列 flake 的独立判定（既有红，非本批引入）**：复核者自跑——未改源码 `b28356f` 同 5 套件序列同样 3 条（`20260923T094938797-19792`）；R2 树同 3 条（`20260923T095306564-15752`）；`interface` 单跑 PASS（`20260923T095626849-12572`）；前驱定位＝`targeting` 在 `interface` 前即可触发（`20260923T100030861-42912`、`20260923T095807293-54016`）；失败断言所在 `tests/interface_ui_cases.gd` 与触发套件 `tests/target_sidebar_ui_cases.gd` 均 R2 未改（`git diff b28356f..a18860a --stat` 仅 body_layout／display／ui_smoke 测试文件）。实现者自述的 worktree 运行号 `20260923T093753113-54472` 目录已随临时 worktree 删除（只剩身份），由上述自跑替代。**协调者建议登记为「既有序列红」**（仅 `targeting` 先于 `interface` 的同轮序列；单跑绿），与既有 `intent` 6 条并列，是否另立修复片待人类裁定。
- 复核结论（P1–P5 通过、无产品缺陷；低项）：①`ui/main.gd::card_row_by_shape`（`:2474`）无调用者＝新增死代码——随 R3 前置清理；②G2 夹具 `COMMAND_KINDS` 域列对 end／calm／surrender 与 `ROUTES` 不一致且未被断言使用（小疵）；③`command_row` 过渡成本：`_submit` 经它取显示 payload（P2 允许的显示调用边、非第二判定），每次提交候选全量物化 2→3 次、`command_row` 为全表线性扫描——R3–R5 显示改线时替换；④`expected_version` 默认来源由 `view.version` 变 `state.version`（`core/game.gd::command`）——不变式下相等、未观察到行为差异，登记为字面偏移。
- 复核 P6（§10 授权面）发现的**同步缺口 3 处＋1 项已随本条补正**：`release-interface.md:185`（候选 ID 句）、`response-pipeline.md` 的 `_submit` 旧签名 3 处与「原样提交候选 ID」句、`event-pipeline.md` 两行（界面／提交复核）；并在接缝 A 登记 R2 新增的四个公开接口（`command_params`／`command`／`command_issue`／`command_row`）；`candidate-removal.md` 的 A 组引言与 DUP1／DUP6 标记销项。未成真条目（ActionIndex／TargetQueries 行、ondemand-copy、equipment-query-seam 等）未动。
- 协调者核对：提交面（`3bbf1e1`＋`a18860a`）与允许面一致；两提交后 `git status` 干净；临时 worktree 已移除（`git worktree list` 仅主树）；新文件与边表复算与实现者回报一致。
- 未跑（未验证）：G5／G6／G7／G9（R3–R5 面）、V1–V11 真人验收、`-Suite all -UI -UISuite all` 全量回归、打包与发布。
- 产物：`build/checks/` 内本次各运行号目录（含复核者自跑 6 轮）留证；实现者与复核者心跳随本条登记清理。

## 2026-09-23｜候选层移除 R3：显示改线＋R2 补正（分支 `seed-chip-save-upload`，commits `fdc4180`＋`797a4e1`＋`450487c`＋`0dca890`）

- 域：手牌／行动／姿态／墙面／底栏显示改线（T5／T9）＋卡片手牌改道补正（A40／A43–A45）。
- R3 证据：改线面＝`ui/main.gd::_hand_choice`／`_build_action_rail`／`_posture_controls`／`_posture_layout`／`_wall_controls`／`_bottom_controls`（显示事实 `view.display_facts`；`core/game.gd::shape_key`）；删边面＝上述函数体的 `actions.select|find` 行读（复核自扫命中 0）。判据：G5 `tests/display_ui_cases.gd::display_facts_match_determination` 绿 `20260923T114141956-52484`（12 单元×228 显示点、185 断言）；G6 绿 `20260923T114640744-55256`（530，`R3_VIEW_MASK=["display_facts"]`＋103 键基）。敏感性三红轮：`…114332198-42860`（G5 文案）／`…114437565-35040`（行读回退）／`…114540496-53260`（G6 mask）。
- R3 门禁：规则门 `20260923T114832434-32564` PASS（38 分类、22020 断言、`before==after`、docs PASS allowlist 6）；UI 门 `20260923T115717988-28856` display／touch／keyboard／body_layout／targeting PASS＋interface 3 条既有序列红；interface 单跑绿 `20260923T120101483-55660`（422）；runner `20260923T120209909-25556` PASS（541）。
- 补正证据：`ui/command_routes.gd::_hand_or_box` 唯一条件副本＋4 调用点（`_resolved_card`／自由面／快捷解除 A45／唯一装备，后三者经 `_seam_card`）；`ui/` 无 `valid`／`reason` 写点（G4 绿）。红→绿：`20260923T132406391-21484`（A45 回退→新断言 `BREATH UI quick-release card click opens native hand selection without payment` 红，diag `kept=false energy=1`）→`20260923T132751500-56504`（390）。G4 形态红轮 `20260923T130749159-56840`（前一版写法被判「ui 写 valid」，2 条）。门禁：`…132713987-18660`（architecture 530）／`…132751500-56504`（card_power+display 575）／`…133136058-54060`（runner 541），同一指纹 `6DC9AF029D00`；`…133412306-51692`（PLAN ONLY）同指纹。
- **指纹链更正（复核 P4）**：协调者随后提交的 `0dca890` 改了指纹面内的 `docs/spec/candidate-removal.md` → 上述「提交字节＝门禁源码」对当前 HEAD 不再成立。复核者按 HEAD 字节补跑：docs PASS＋runner PASS（`20260923T141341240-56688`）；引擎源码零差异（仅文档一行）。R3 门内容可复算：`fdc4180` 内容＋`ui/command_routes.gd` CRLF 时精确得 `4F7070AF2BFDB520`。**引擎版本登记**：R3 各门与 `450487c` 用 4.7.2（`ed1daf0bf`），补正各门用 4.7（`5b4e0cb0f`）——与项目打包口径（4.7.2）不完全一致，如实登记。
- **前轮 run 的事实更正**：`20260923T121228401-14192` 存在且 `status=passed`（card_power+display，fp `EB98F7A72427`）；其指纹不对应 `797a4e1`／`fdc4180` 任一提交，只能登记为**中断前任工作树**的结果，不作提交字节证据（协调者此前误记为“无 summary”，据实更正）。
- 独立复核（R3＋补正，新会话、只读、自做变异）：P1 通过（A45 属原行为——对照 pre-R2 `3bbf1e1:ui/main.gd::_submit` 首段必过该改道；无条件第二副本）；P2 通过（一份判定两条边 `_fact_core`→`_fact_verdict`→`eligibility`；D13 域零残留行读；`detail_of`／`card_entry` 三版函数体 sha 同值；域外未动）；P3 通过（自做 M1／M2 红→还原同指纹绿：`20260923T135957105-57740` 基线绿／`…140249345-47980` M1 红／`…140543305-57908` M2 红／`…140836534-54124` 还原绿，运行目录已留证 `build/checks/`）；P5 通过（`basic_attacks::KICK UI level-three sitting preview reads shared damage` 在 pre-R2 树同红 `20260923T135758084-18796`，260 断言）；P6 通过（5.1 假红复现 `20260923T141341240-56688`：runner PASS 后首个负例探针因执行策略中止，需 `-ExecutionPolicy Bypass`）。
- 既有红登记（与 `intent` 6 条并列，是否另立修复片待人类裁定）：①`interface` 序列红（`targeting` 先于 `interface` 同轮必红 3 条；单跑绿）；②**新增** `basic_attacks::KICK UI level-three sitting preview reads shared damage`（未改树同红，单条／260 断言）。
- 低项（已裁定/登记，不返工）：`_hand_or_box` 的 `expected_version` 原样传、归一收口在 `core/game.gd::command` 一处（pre-R2 在改道处另有一次；无可达差异例，按「同一语义一条路径」保留现单点）；`_self_action` 一条 `actions.by_id` 回落（注释声明 R5 过渡）；`core/game_view.gd::_takeover_step` 读行 `automated`（R5 行载体删除后消失）。
- 未跑（未验证）：§7.5 UI 全量组合在补正后未整轮重跑（interface 序列红已登记）；G5 冻基线未在未改源码树重算；V1–V11 真人验收；全量回归；打包发布。
- 产物：`build/checks/` 内本次各运行号目录（含复核者自跑 5 轮）留证；`build/r3-*`（探针／基线／变异备份／敏感性日志）与三份心跳、复核日志**随本条登记清理**（变异备份 `r3-mut-backup-*.gd` 确认未进主树）。

## 2026-09-24｜候选层移除 R4：显示改线（装备／快捷解除／拖放／道具）＋双模型审查（分支 `seed-chip-save-upload`，commit `41c1b6d`）

- 域：装备／快捷解除／拖放／道具域显示改线（T5／T9）：`ui/main.gd::_equipment_actions`／`_attack_drop_candidate`／`_item_details`／`_door_candidate`／`_free_player_candidate`／`_hook_drawer`／`_guard_bind_card_candidate`／`_chain_screen`；`ui/target_queries.gd` 行筛面改指令装配（首参由行索引改 `view`）；`ui/quick_release_bar.gd`／`ui/drag_targets.gd`／`ui/keyboard_input.gd` 取用同步；DUP4 收敛（`ui/target_queries.gd::first_usable(offers, fallback)` 唯一通道；`ui/action_index.gd::first_usable` 以 `"last"` 委托并注释声明 R5 随行载体消失）。
- 实现者证据（cursor-agent／grok-4.7-xhigh；16 文件 +628/−178）：UI 六套件门 `20260923T162644324-56872`（card_power／display／touch／keyboard／body_layout／targeting 全 PASS）；runner `20260923T163218114-35848`；还原绿轮 `20260923T164035134-28352`；三者同指纹 `E2E8F241C3FE439FB61C…`（协调者以 `-ListOnly` 复算一致）。
- **规则门覆盖缺口与其闭合（协调者核验发现）**：实现者引用的规则门 `20260923T153559213-53772` 跑在旧指纹 `5CA93EAF8860…`（其后仍有代码修复），不覆盖最终字节；审查 P0 在各自 worktree 补跑 `-Suite architecture,persistence,casting -Impact` 闭合——bunny `20260923T165257850-6948`（passed、38 分类、`before==after==E2E8F241C3FE…`，与主树字节指纹一致）；muse `20260923T165345859-35032`（passed、22020 断言；指纹 `7F99B3F8…` 为 worktree 行尾变体，muse 主动披露口径差）。
- **双匿名模型并行审查对照**（同一派单 `build/r4-review-brief.md` 逐字相同、同对象、并行；天花板不同＝bunny max／muse xhigh，已声明为混杂因素）：
  - 两者 P0–P5 全过、**零假阳性**；协调者抽查主树可验断言（`fact_id` 式 `JSON.stringify(payload).sha256_text().substr(0,24)`、依赖表 8＋2 行、四个具名用例 `r4_display_points_do_not_read_rows`／`r4_display_facts_match_determination`／`r4_pointer_paths`／`query_contract`、`ui/action_index.gd::first_usable` 委托、`basic_attack_ui_cases.gd:84` 的 KICK 属 UI 套件）逐条相符。
  - bunny（~15 分钟）：三屏未动取证＝`git diff --unified=0 | rg` 零命中；P3 变异 `_equipment_actions` 改回 `actions.select` → 红 `20260923T165834971-25268`（display FAIL、点名该函数）；还原（附 `ui/main.gd` SHA-256）→ 绿 `20260923T165952166-26544`（234 断言、同指纹）；如实登记自身 worktree 冷启动预热失败（不作源码结果）。
  - muse（~34 分钟）：额外 UI 六套件（`interface` 首轮 3 红经 `-RerunFailed` 复绿 `20260923T171134867-14784`）＋runner `20260923T171312159-25700`；P3 变异 `_chain_screen` → 红 `20260923T171437693-39812`（具名断言点名）→ 绿 `20260923T171757141-27740`；P1 深至接合机制（`fact_id`／`command_domain_ready` 守卫收敛／事实来源同源）；披露 518 个 `.import` 副产物（声明无源码差异）；一处轻微口径不精（把 `basic_attacks` 规则套件 PASS 表述为“未见 KICK 红”；KICK 为 UI 用例）。
  - 结论与取用建议：`build/r4-review-comparison.md`（两者均达可用审查者水准；bunny＝快档复核性价比高，muse＝深查／交叉印证）。
- **既有红更新**：①`interface` 序列红经 `-RerunFailed` 可复绿（登记口径更新）；②`basic_attacks::KICK UI level-three sitting preview reads shared damage`（`tests/basic_attack_ui_cases.gd:84`，UI 套件）未变。
- 未跑（未验证）：R5 终态与 G7；V1–V11 真人验收；`-Suite all` 全量回归；打包发布。
- 产物：两份审查报告 `build/review-r4-*-report.md`、对比 `build/r4-review-comparison.md`、派单 `build/r4-review-brief.md` **保留待人类过目**；实现者与审查心跳随本条登记清理（审查运行目录随各自临时 worktree 删除，运行号身份留存）。

## 2026-09-24｜候选层移除 R5 补正（分支 `seed-chip-save-upload`，commit `a1144d6`）

- 域：显示事实键（`Queries.fact_key`）、踢击预览字面、装备详情 `card_status`、遗物条命中、墙面安装快捷页与高度短标；契约 `docs/spec/candidate-removal.md` §7.5。相对 `7f4065e`（R5 删除行载体本体）。`ui/main.gd::_reset_interface` 相对该父提交无 scale 改动。
- 对照（证明四条红不是未提交 leftover 引入）：干净 HEAD 隔离 `20260924T082258017-50428`，`shoulder`／`torso_binding`／`wall`／`intent` 全 FAIL。脏树诊断隔离 `20260924T075431782-26284` 同红项。
- 规则门：`& tools/check.ps1 -Suite architecture,persistence -Impact -TimeoutSeconds 1200` → `20260924T090804005-38740`，`status=passed`，`PASS: 21060 assertions`，`before==after==930F16A19873309180257FC1EB9403108CA33631F22C2BC2E8BE9C3DC7CD5886`。
- 窗口隔离：`& tools/check.ps1 -UIOnly -UISuite shoulder,torso_binding,wall,intent -KeepGoing -TimeoutSeconds 600` → `20260924T091308877-38740` PASS。
- 窗口全量：`& tools/check.ps1 -UIOnly -UISuite all -KeepGoing -TimeoutSeconds 3600` → `20260924T091416176-44124`，`status=passed`，`UI PASS: 6901 assertions`，`failed=[]`，`unrun=[]`，同指纹。含 `siphon`／`installed_tools`／`basic_attacks`／`targeting`／`interface`／`impact_feedback`／`normal_play`。
- 文档门：同次 UI-all 摘要 docs `status=passed`，35 文档／2393 引用／allowlist 6；独立 `check-docs.ps1` 随 ListOnly／规则门复跑。
- runner：`& tools/check.ps1 -Suite runner -VerifyRunner` → `20260924T094649313-28740`，`status=passed`，`verify_runner=true`，同指纹（pwsh 7；PS 5.1 曾把探针 throw 打成假红，不计入通过）。
- 提交前 ListOnly：`20260924T094958646-3976`，`status=plan`，指纹仍 `930F16A1…CD5886`（`SOURCE CHANGED` 未出现）。
- 敏感性：`tests/basic_attack_ui_cases.gd::third_kick` 字面改 `"2.4 伤害"` → `20260924T094728959-41708` `basic_attacks` FAIL；还原 `"3.6 伤害"` → `20260924T094839774-19728` PASS，指纹回到 `930F16A1…CD5886`。
- 未跑（未验证）：独立审查结论（派单 `build/r5-review-brief.md`，本条写入时未回）；V1–V11 真人验收；`-Suite all` 规则全量（本片 DoD 是 architecture,persistence Impact，不是规则 all）；Android 真机；打包／发版／推送。不把 `-ListOnly` 当通过。

## 2026-09-24｜R5 补正独立审查（对象 `a1144d6`）

- 域：同上一节 R5 补正。只读审查（新会话），报告 `build/r5-review-report.md`。未改源码、未重跑 3600s UI-all；对照既有运行号与 `git diff 7f4065e a1144d6`。
- 结论：`No findings.` 指定修法未越权（无第二套 InstalledTools、未弱化断言、未把 scale 写回 `_reset_interface`、未改 `LEG_CAST`／历史卷）。声称门禁运行号、断言数、指纹 `930F16A1…CD5886`、`failed=[]`／`unrun=[]` 与日志相符。
- 残留（不作缺陷）：V1–V11；`-Suite all`；依赖表 `ui/main.gd` 行「允许改动」仍写 layout 复位进 `_reset_interface`，与「必须保持：不把 scale 写回」及源码（复位在 targeting 测试末行）字面不一致——代码遵守必须保持。
- 未跑：推送、打包、发版、真人验收。

## 2026-09-24｜R5 补正清洁（commit `4818a10`）

- 域：`docs/spec/candidate-removal-dependencies.md`。清洁者提交：允许列不再声称 `_reset_interface` 复位 layout，与源码及「必须保持」一致。未改 `ui/`／`tests/` 产品字节。
- `check-docs.ps1` PASS（35 文档／2394 引用／allowlist 6）。未跑 Godot。上一节残留的依赖表字面不一致已由本提交闭合。
- 未跑：OpenCode muse／bunny 双审结论（worktree 仍在跑）；V1–V11；推送／打包。同会话 grok `No findings` 不作正式独立审查。

## 2026-09-24｜R5 补正 OpenCode 双审（对象 `a1144d6`）

- 域：同 R5 补正。muse xhigh worktree 与 space-bunny max worktree，同一派单、只读、未重跑 3600s UI-all。
- muse：`No findings.`（`build/r5-review-muse-report.md`）。bunny：P0 无 finding；P1 F1＝依赖表允许列声称 `_reset_interface` 复位 layout，而 `a1144d6` 的 `_reset_interface` 无 scale／position 写入（`build/r5-review-bunny-report.md`）。
- F1 已由 `4818a10` 闭合。对照 `build/r5-review-comparison.md`。同会话 grok 审查不作正式结论。
- 未跑：V1–V11；`-Suite all`；打包／推送。

## 2026-09-24｜R5 候选层活痕迹双扫（HEAD `3129037`）

- 域：终态五符号、`view.candidates`、按 id 取行、UI `dispatch` 唯一性。muse／bunny 分离 worktree，无 Godot。
- 源码：两边 **No live traces.**（`build/muse-candidate-trace-report.md`、`build/bunny-candidate-trace-report.md`）。
- 文档：现行 spec／design 仍有 `ActionIndex`／`candidates()`／`candidate_id` 字面。并集见 `build/r5-trace-comparison.md`。未改文档。
- 未跑：V1–V11；文档统一改写（待人批准）；推送。

## 2026-09-24｜R5 只读投影／事实表配对测量（对照 `831c1b7` → `09d722d`）

- 域：`core/game.gd::candidates`（旧）／`command_facts`（新）与两侧 `get_view`；可选 headless `ui/main.gd::render`。契约 [候选层移除](../spec/candidate-removal.md) 第 6 节测量口径／P5。未改产品字节。
- 口径：同机、两侧 worktree 按夹具旧→新交替；2 热身不计 + 15 有效配对；配对比值＝逐对（新/旧）中位。种子 42，正式工厂，夹具 0／12／29 件均 `validate()==""`，读后快照相等。不与 `equipment-performance.md` 2026-09-14 绝对毫秒拼接。
- 结果：事实条数 88／100／202 两侧相同。事实配对比值 0.994／0.961／0.913；`get_view` 0.754／0.659／0.608。密夹具 UI 渲染配对比值 0.806。详情与表见 [equipment-performance.md](equipment-performance.md) 同日节；JSON `spire-godot/build/r5-stress-20260924/paired.json`。
- 毫秒只报告，不是完成判据，不宣称 R5 因提速完工。测量日志引擎错误 0；worktree 首次导入字体缓存 ERROR 8 行（第二次 0）。
- 未跑：V1–V11；`-Suite all`；真窗口／29 件 UI 渲染；打包／推送。

## 2026-09-24｜R5 密集夹具 ≥50 配对测量（对照 `831c1b7` → `09d722d`）

- 域：同上节。人类裁定 26／29 太少。未改产品字节。
- 夹具：空 0；`r1_install_equipment(44)` 两侧 44。同一循环 80／100 均停在 45 件普通装备；3 个大臂宿主三档自动肩带 +6＝51。`validate()==""`，读后快照相等。不与 0／12／29 或 2026-09-14 绝对毫秒拼接。
- 结果：事实条数 88／292／344 两侧相同。事实配对比值 0.959／0.906／0.920；`get_view` 0.701／0.623／0.662。51 件 UI 渲染配对比值 0.735。表见 [equipment-performance.md](equipment-performance.md) 同日密节；JSON `spire-godot/build/r5-stress-20260924/paired-dense.json`。
- 毫秒只报告，不是完成判据。测量日志引擎错误 0；首次导入字体缓存 ERROR 8 行。
- 未跑：V1–V11；真窗口；打包／推送。

## 2026-09-24｜T4 command_fact 按 kind 生产者查找（commit `b3c2731`）

- 域：`core/game.gd::command_fact`；契约 [候选层移除](../spec/candidate-removal.md) T4。接线 flask／attack（无自解目标）／item_discard／buff-escape item_use／flow／posture／wall_move／status_toggle／relic_toggle·discharge／surrender。未接线 kind 仍 `_fact_source`。接管仍全表 `select`。
- 检查：`architecture` `20260924T121448379-46068` PASS 687 断言、docs PASS。实现者报告 `spire-godot/build/t4-fact-prune-report.md`。
- 51 件中位（只报告，不当完成）：flask 329µs，attack 2848µs，全表 `command_facts` 68873µs。
- 独立审查：`No findings.`（`spire-godot/build/t4-review-report.md`，worktree `b3c2731`）。残留：等价只单向、未接线 kind 仍扫 `_fact_source`、T5／UI 未跑——不当本片缺陷。
- 清洁：`6a1daee` `_phase_action_tail` 复用 `command_tail`；architecture `20260924T125126110-31452` PASS 687。复杂度／依赖方向检查器未建。独立审查：`No findings.`（`spire-godot/build/t4-cleaner-review-report.md`）。
- 加固档 2：三变异均红（flask 全表 `20260924T125751962-25036`；命中行不等 `20260924T125950542-3764`；全表条数 `20260924T130331744-20096`）；关掉耗时后 ①② 仍红。还原 `20260924T130419784-51824` architecture PASS 687。无产品修复。报告 `spire-godot/build/t4-hardener-report.md`。
- 未跑：T5；出牌词条剪枝；分区 delta；UI 套件；推送。

## 2026-09-25｜人认可 `pipeline_lookup_graph` 切分

- 依据＝人「先这样」。提取物 `spire-godot/build/pipeline-graph-slice-extract.md`。产品 `core/`／`ui/` 零改。词条槽仍挡住。

## 2026-09-25｜`pipeline_lookup_graph` 实现（commit `2d75b47`）

- 域：`tests/architecture_cases.gd::pipeline_lookup_inspect`；真源 `PIPELINE_LOOKUP_EDGES`（L-wired／L-unwired／L-table）。契约指针见 [候选层移除](../spec/candidate-removal.md) §2.1。
- 检查：`architecture` `20260924T141520627-44672` PASS 710 断言、docs PASS。报告 `spire-godot/build/pipeline-graph-impl-report.md`。
- 独立审查：`No findings.`（`spire-godot/build/pipeline-graph-review-report.md`）。残留：P2 声明自证、抽函数体是子串计数、档 2 变异未在该次证据里——不当本片缺陷。
- 清洁：`50e4c37` inspect 消费边表；architecture `20260924T142457890-6640` PASS 712。独立审查：`No findings.`（`spire-godot/build/pipeline-graph-cleaner-review-report.md`）。
- 加固档 2：四变异均红（另加 `_fact_source` `20260924T143033198-26092`；L-table 去源 `20260924T143504278-18980`；flask 全表 `20260924T143630496-49428`；G4 多写点 `20260924T143741390-40376`）；关掉耗时后 ①②④ 仍红。还原 `20260924T143928122-53588` architecture PASS 712。无产品修复。报告 `spire-godot/build/pipeline-graph-hardener-report.md`。
- 未跑：T1–T3；其余 T；装备查询图；词条槽；UI 套件；推送。本刀收口完成。未推送。

## 2026-09-25｜人认可 `card_facts_declared_slots` 切分

- 依据＝人「继续」。提取物 `spire-godot/build/card-specs-slice-extract.md`。

## 2026-09-25｜`card_facts_declared_slots` 实现（commit `3b88ece`）

- 域：`core/card_effects.gd::card_facts`。有 `target_slots` 不对表外槽 `targets_at`。事实与本刀前相等。
- 检查：`architecture` `20260924T145132714-53204` PASS 717、docs PASS。报告 `spire-godot/build/card-slots-impl-report.md`。
- 独立审查：`No findings.`（`spire-godot/build/card-slots-review-report.md`）。
- 清洁：`614f683` 槽走查去重；architecture `20260924T145840409-6220` PASS 717。独立审查：`No findings.`（`spire-godot/build/card-slots-cleaner-review-report.md`）。
- 加固档 2：仍并全身再查未声明槽 `20260924T150434814-57380` 红；关掉计数并改行 `20260924T150537381-50620` 红（该次 `source_changed`，以 check-rules 断言为准）；漏自由面空槽 `20260924T150651349-21852` 红。还原 `20260924T150736483-37732` architecture PASS 717。无产品修复。报告 `spire-godot/build/card-slots-hardener-report.md`。心跳记有并行 Godot 串扰运行号，不当本刀结论。
- 未跑：T4 接线 card；T5；delta；UI 套件；推送。本刀收口完成。未推送。

## 2026-09-25｜下一刀规划（无 target_slots 全身扫描）

- 依据＝人「继续」。规划者经 Codex ark／`gpt-6-sol`／high。切分认可前不派实现者。

## 2026-09-26｜targets_at 查表 vs UncachedGame 配对测量（HEAD `78ab96d`）

- 域：`core/game.gd::targets_at`。测量记录见 [equipment-performance.md · targets_at 查表 vs UncachedGame · 2026-09-26](equipment-performance.md)。
- 命令（`spire-godot/`，`GODOT_BIN=C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`）：`--headless --path . --script res://build/equipment-index-targets-20260926/bench.gd`。夹具实际 0／12／29 件，均合法；2 热身＋15 有效配对；`export_snapshot`／`get_view`／`command_facts`／各槽 `targets_at` id 序列两侧相等；引擎错误 0（无 SCRIPT ERROR）。JSON：`spire-godot/build/equipment-index-targets-20260926/paired.json`。毫秒只写入性能卷，不是完成判据。
- 未跑：UI／窗口；`equipment_complete`；`-Suite all`；安卓真机；push。未改 `core/`／`tests/` 产品字节，未改 `docs/spec/`。

## 2026-09-27｜三条切片线归并为一条（`c1bc5f5` → 归并枝头 `4b15ca3`）

- 域：`core/game.gd::targets_at`／`has_targets_at`／`_visit_targets_at`／`_materialize_slot_target_edge`、`core/card_effects.gd::card_facts`（`keyword_ids` 收集门）、`ui/main.gd::present`／`_submit`（提交／呈现拆分与 F1 卸载过滤）、`docs/spec/equipment-query-seam.md`。归并＝三次 `git merge --no-ff`（#9 头 `dc1614e` → submit-present `83a0e38` → #10 `ac572fe`）＋一次 `git rm -r --cached spire-godot/build` 提交；枝 `worker/architecture-consolidate`，工作树 `C:\1\tmp\magic-spire-wt-architecture-consolidate`。
- 冲突 5 文件（逐条理由写在三个合并提交正文）：`spire-godot/tests/architecture_cases.gd`（两侧尾部追加取并集；分支侧块与 #8 已并入块逐字节相同，合并后每个用例只一份，未删任何用例）、`spire-godot/core/game.gd`、`docs/spec/equipment-query-seam.md`、`docs/record/equipment-performance.md`、`docs/record/verification.md`（两个记录两侧条目按日期并排、纯追加）。
- 契约收口：`_query_targets_at` 不再存在；`_visit_targets_at` 是唯一按槽走查（`targets_at` 收集、`has_targets_at` 首命中），`_materialize_slot_target_edge` 经它建边（不读表、不调 `targets_at`，防表未开放时递归）；作用域内 `targets_at`／`has_targets_at` 同读 `_equipment_read.slot_targets`。`tests/architecture_cases.gd::IndexCountingGame` 随符号移除把 `_query_targets_at` 计数替身改为 `_visit_targets_at`（计数名 `walk_calls`），其断言未改。
- 规则门（`spire-godot/`，`GODOT_BIN=C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`）：`& tools/check.ps1 -Import -Suite architecture,card_power,equipment,composites,links,shoulder,torso_binding,special_equipment,casting,status,hand_assist -Impact -KeepGoing -TimeoutSeconds 3600` → 运行号 `20260927T092155269-16952`。`-Impact` 一次展开到 40 分类：**39 PASS／1 FAIL（`composites`）**、`FAIL: 2/25440 assertions; 2 engine errors`；`summary.json` `status=failed`、`before==after==01A14471043BD601120EAD47713E2FA67FAB69696E5A9E5387317A82FD99A6B3`（无 `SOURCE CHANGED`）、`rules.unrun=[]`、`docs` PASS（35 文档／2486 引用／0 问题／allowlist 6）。分类计数：architecture 4468、card_power 2297、enemies 2070、prison 1411、pressure 1415、equipment 213、equipment_complete 459、links 169、shoulder 131、torso_binding 65、hand_assist 154、casting 623、status 301、special_equipment 501、composites 96。
- `composites` 2 条＝`tests/composite_cases.gd:92`「changed charge invalidates old damage candidate even without version fixture update」与 `:93`「body hit from wrist removes full root, consumes one card, energy and charge」（`state.charge`／命令复核域，本刀未触及）。同树 `614f683` 源码复跑 `-Suite composites` → 同 2 条、`2/96`（运行号 `20260927T093702474-15080`）：既红确认，非本刀引入；规划者所记 `2/1895` 与本轮日常采样 `2/96` 口径不同。
- 新树首次 `-Import`：运行号 `20260927T092020857-30052`，import 阶段红（`res://.godot/imported/NotoSansCJKsc-Regular.otf-…fontdata` 字形缓存 ERROR 4 行），规则／窗口未跑；同参数第二次导入 0 行 ERROR、`CHECK import: 10.00s`。两轮导入产生的 `*.import` 改动已还原；`ui/command_router.gd.uid`／`ui/command_routes.gd.uid` 为引擎生成、已删除；`git status` 干净。
- 窗口门 1：`& tools/check.ps1 -UIOnly -UISuite display,home,interface -KeepGoing -TimeoutSeconds 3600` → 运行号 `20260927T092845256-30944`：`display PASS`（951 断言）、`home FAIL`、`interface` 未跑（`home` 的 SCRIPT ERROR 中止窗口阶段）；`summary.json` `status=failed`、`ui.failed=["home"]`、`ui.unrun=["interface"]`。
- `home` 红点：`tests/home_ui_cases.gd:92`（`iron_practice`）`ui.find_child("HeroGuardBindValue",true,false)` 为 null → `SCRIPT ERROR: Invalid access to property or key 'text' …`（`Click.press`→`frames`）；即铁男练习开场提交后 `HeroGuardBind` 米表不存在（该米表只由 `ui/main.gd::_battle_scene` 建立）。
- 归因实验（同一工作树逐条，运行号可查；源码指纹与归并树不同且 docs 因混树 FAIL，只用于归因、不作为通过证据）：基树 `614f683` 源码 `-UIOnly -UISuite home` → `home PASS`（`20260927T093303030-34348`，140 断言）；`git diff 83a0e38 HEAD -- spire-godot/ui/main.gd` 为空（与 submit-present 枝逐字节相同）；`83a0e38` 树上 `-UIOnly -UISuite interface,enemies,home`（`20260927T094527003-30056`）复现同形 `home` 红，`-UIOnly -UISuite interface,enemies`（`20260927T094805797-26180`）复现 `enemies` 红。故 `home`／`enemies`／`guard` 红由 submit-present 的 `present` 分区引入（该枝当时只跑 `display`），局部节无人负责 `_battle_scene` 独占的显示面（`HeroGuardBind*`、敌图标计数）。未修：需改该切片的节条件表与契约，属设计决定。
- 窗口门 2／3（归并树）：`-UIOnly -UISuite guard,enemies` → `enemies FAIL` 3 条「PUPPET UI … barrier badge／stock」，随后同形 null `SCRIPT ERROR`（`20260927T094309951-15084`，33 断言，`guard` 未跑）；`-UIOnly -UISuite guard` → FAIL「GUARD UI compact bind meter appears below mana and accepts card targeting」＋null（`20260927T094922741-23348`，37 断言）。基树 `-UIOnly -UISuite interface,guard,enemies` → 3／3 PASS、`UI PASS: 735`（`20260927T093908714-12816`）。
- `interface` 非确定：同一源码指纹 `01A14471043BD601…` 下 4 次中 1 次红——FAIL `20260927T093500396-23496`（`TERMS UI tallest face keeps every term box inside the viewport and clear of the anchor`），PASS `20260927T095027049-7000`／`20260927T095246170-30820`／`20260927T095345027-16992`；不列为确定性红，也不宣称该检查全洁。
- 未跑：`-Suite all` 完整回归；`-Exhaustive`；其余窗口分类（`card_power`／`touch`／`keyboard`／`route`／`normal_play` 等）；安卓真机；打包／推送。窗口只跑过 `display`／`home`／`interface`／`guard`／`enemies`。
- 日志位置：`spire-godot/build/checks/<运行号>/`（本 worker 工作树内，`build/` 不入库；工作树删除后随其清理）。未 push、未打包、版本未动。

## 2026-09-27｜present 分区补 `_battle_scene` 独占显示面（枝 `worker/present-meter`）

- 域：`spire-godot/ui/main.gd`（`_battle_scene`、`_refresh_resource_section`、`_refresh_scene_instances_section`、`_hand`、`render`、`_status_strip`、新增 `_sync_hero_bind_meter`／`_sync_card_faces`／`_stage_control`、`ENEMY_STATUS_RECT`）；契约 [响应管线](../spec/response-pipeline.md) 节键表与 `scene_instances` 行。未改 `core/`、未新增文件、未改任何测试断言。
- 归因（上一条记录停在「未修：局部节无人负责 `_battle_scene` 独占的显示面（`HeroGuardBind*`、敌图标计数）」）：①英雄舞台捕缚米表与拖放接收器只由 `_battle_scene` 建，`resources` 局部路径只建侧栏米表，故绑缚在战斗开始后才出现时英雄舞台无米表／目标；②敌图标计数（`StatusIcon_*`／`StatusCount`）同属只在 `_battle_scene` 建的条；③局部路径不执行 `render` 的抽牌面同步（`card_draw_serials` → `card_faces`），上一子流程翻过的面留到下一流程，`guard` 主流程 strain 拖放落在自由面 → 候选 invalid（修前 `guard` 只跑到 92 断言的 59 行）。
- 修复：①绑缚舞台米表（caption＋meter＋value＋drop target＋`HeroCastingChance` 偏移）收口 `_sync_hero_bind_meter`，`_battle_scene` 与 `resources` 节共用同一例程：节点按名复用、数值原地更新（身份稳定，关抽屉后 `HeroGuardBind` 仍是同一实例）、绑缚清空即移除米表与目标并擦 `actor_targets.guard_bind`；②各 owner 状态图标条由 `_status_strip` 维护，按 owner 的键（`_status_keys`）命中则跳过，条缺失或该 owner 状态列表变化只重建该 owner，空列表移除条；`scene_instances` 局部入口同时同步英雄与存活敌人的条；③抽牌面同步抽为 `_sync_card_faces`，`render` 与 `hand` 节共用。
- 复现（修前，运行号可查）：`-Import -UI -UISuite home,enemies,guard` → `20260927T100803775-51256`（新树首轮 import 字体缓存 4 行 ERROR、二轮 0 行；`home` FAIL 139 断言、`SCRIPT ERROR` null `.text`）；`-UIOnly -UISuite guard` → `20260927T101026692-55804`（FAIL 37，null `get_global_rect`）；`-UIOnly -UISuite enemies` → `20260927T101055528-35820`（3 条「PUPPET UI … barrier badge／stock」值不符 + null `.text`）。
- 门禁（`spire-godot/`，`GODOT_BIN=C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`）：
  - 运行号 `20260927T105800160-17868`：`& tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 600` → `RULE SCOPE: architecture`（`-Impact` 未展开：`tests/suite_selection.gd::CROSS_AREAS` 中无分类把 `architecture` 列为受影响域）、`SUITE RESULT: architecture PASS`、`PASS: 4468 assertions`、docs PASS（35 文档／2486 引用／0 问题／allowlist 6）；`summary.json` `status=passed`、`before==after`，无 `SOURCE CHANGED`。
  - 运行号 `20260927T105832248-17868`：`& tools/check.ps1 -UI -UISuite home,enemies,guard,display,interface` → docs PASS；`architecture`／`runner` PASS（5009 断言）；`display`／`home`／`interface`／`enemies`／`guard` 五分类全 PASS、`UI PASS: 1826 assertions`（分类计数 display 951／home 140／interface 422／enemies 221／guard 92）；`summary.json` `status=passed`、`rules.unrun=[]`、`ui.unrun=[]`、`before==after`，无 `SOURCE CHANGED`。
- 过程：调试期在 `ui/main.gd` 与 `ui/drop_target.gd` 临时加过打印，均已移除（`git diff` 里不含 `print(`）；两轮 `-Import` 生成的 `*.import` 改动已 `git checkout -- .` 还原，`ui/command_router.gd.uid`／`ui/command_routes.gd.uid` 为引擎生成、已删除。
- 未跑：`-Suite all` 完整回归；`-Exhaustive`；其余窗口分类（`casting`／`touch`／`keyboard`／`route`／`normal_play`／`body_layout`／`targeting`／`composites` 等）；`composites` 既有基线红未在本刀复跑；安卓真机；打包／推送。
- 日志位置：`spire-godot/build/checks/<运行号>/`（本 worker 工作树内，`build/` 不入库）。未 push、未打包、版本未动。

## 2026-09-27｜`present` 分区补英雄舞台米表与敌人舞台件（枝 `worker/stage-sync`，基 `c9685a5`）

- 域：`spire-godot/ui/main.gd`（新增 `_sync_hero_stage_meters`／`_sync_stage_meter`／`_meter_value_text`／`_hero_casting_text`／`_sync_enemy_stage`／`_sync_enemy_select`／`_sync_enemy_intent_icons`／`_intent_icon_rect`／`_unload_stage_node`／`_release_enemy_stage`，改 `_battle_scene`／`_refresh_resource_section`／`_refresh_scene_instances_section`／`_resource_presentation_key`／`_resource_meter`／`PRESENT_ADJACENCY`）；新检查 `spire-godot/tests/display_ui_cases.gd::present_syncs_battle_stage_widgets`；契约 `docs/spec/response-pipeline.md` 的 `resources`／`scene_instances` 节键行与缓存清单。另按复审 1–7 触及 `docs/spec/equipment-query-seam.md`、`tests/normal_play_cases.gd`（夹具键）、`data/card_text.gd`＋`data/balance.gd`＋`core/card_effects.gd`（`collect_keys` 归位）。未改 core 规则、未改任何既有断言、未新增文件。
- 两条独立审查阻断的修复：①`HeroOverload`／`HeroMana` 只在 `_battle_scene` 建，`resources` 局部路径无人同步——收口 `_sync_hero_stage_meters`（快感／魔力／捕缚三米表＋捕缚拖放接收器＋`HeroCastingChance` 偏移：按名复用、数值与数值标签原地更新、缺件才建、绑缚清空即移除）；`resources` 键补 `view.casting.percent`（该节读出施法标签）。②敌人名条／血条／HP 文本／意图图标只在 `_battle_scene` 建——收口 `_sync_enemy_stage`（`EnemySelect_*` 按名字／选中／`gone` 键原地更新；`EnemyHp_*`／`EnemyHpValue_*` 原地更新；`IntentIcon_*` 按自身条目键增删并沿用构造接线），`gone` 敌人的整槽由 `_release_enemy_stage` 释放（局部路径不重建 `layout.used`，帧无法识别该释放）。③附带：`PRESENT_ADJACENCY` 补 `_hand → _sync_card_faces` 与新符号表项；`_sync_hero_stage_meters` 新建／更新分支统一走 `localization.display`。
- 新增检查的敏感性证明（同树同源码，仅临时回退新同步后还原；每条红都落在新断言上）：英雄米表——`_refresh_resource_section` 里临时去掉 `_sync_hero_stage_meters()`，`-UIOnly -UISuite display` 运行号 `20260927T121752479-36504` 红 6 条（overload 值／上限、overload 标签、mana 值／上限、临时魔力标签、二次更新）；敌人舞台件——`_refresh_scene_instances_section` 里临时去掉 `_sync_enemy_stage(e,group)`，运行号 `20260927T122259028-47188` 红 7 条（血条、HP 文本、`◇` 标记、图标集合、图标存在、真实提交后的血条与 HP 文本）。还原后 `-UIOnly -UISuite display` 运行号 `20260927T121306318-16868` PASS 986 断言。
- 复审 1–7 处置：1（补 `casting.percent`）已做；2（邻接声明）已做；3 已做——`docs/spec/equipment-query-seam.md` 敏感性括注重写并逐条点名：变异实测（临时删掉 `core/game.gd::targets_at`／`has_targets_at` 的查表分流，已还原）运行号 `20260927T124126151-30848`，`architecture FAIL 1/5140` 仅 `INDEX repeated targets_at queries inside one scope never rebuild or reassemble the slot-target edge`（即 `index_materializes_once_per_scope` 的 `walk_calls` 计数），`equipment`／`equipment_complete` PASS——两条 parity 比对返回值故仍绿，与原文「须让前两条之一变红」不符，已改为分条点名；4（口径对齐）已做；5 已做——**分类更正：`normal_play` 属规则分类**（`tests/test_game.gd::SUITES`），上一批记录把它列为「其余窗口分类」属分类错误；`tests/normal_play_cases.gd` 在 `c1bc5f5..HEAD` 逐字节相同（`git diff --stat c1bc5f5 c9685a5 -- spire-godot/tests/normal_play_cases.gd` 空输出；本刀只对齐夹具键，见下），他树两条更宽规则运行 `20260927T114402143-48716`（`FAIL: 7/19519`，`normal_play` FAIL、其后 16 分类 unrun）与 `20260927T114636591-31172`（19 分类选中、`normal_play` 失败后其余 unrun）为既有基线红（`choose()` 读 `v.display_facts` 而后三个夹具提供 `"facts"`），本刀已修（见下）；6 登记为遗留——`data/card_text.gd::TERMS` 的 `static var` 未收回：实测改回 `const` 会让 `tests/card_text_cases.gd:144` 的原地改名探针直接崩（`-Suite card_power` 运行号 `20260927T124943753-27932`：`Dictionary is in read-only state.`／`SCRIPT ERROR: Invalid assignment on read-only value (on base: 'Dictionary')`，`FAIL: 0/2282`），收回须改该探针机制（属另一切片的断言集），本轮不做；7 已做——`collect_keys` 归位：`data/card_text.gd::SLOT_TARGET_IDS` 唯一声明、`data/balance.gd::slot_target_ids()` 转发、`core/card_effects.gd::card_facts` 只调接口（值逐字相同、零行为变化，`tests/architecture_cases.gd::card_facts_keyword_min_query` 保留测试侧 oracle 副本）。
- P1 规则 `normal_play` 夹具修复：`tests/normal_play_cases.gd` 三处夹具键 `"facts"` → `"display_facts"`（helper 读 `v.display_facts`、`blind.display_facts.append`），断言语义一字未改。`& tools/check.ps1 -Suite normal_play -Exhaustive -TimeoutSeconds 1800` 运行号 `20260927T122640817-3164`：`SUITE RESULT: normal_play PASS`、1523 断言、717317 ms、docs PASS、exit 0。
- 门禁（`spire-godot/`，`GODOT_BIN=C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`）：
  - 新树首次 `-Import` 运行号 `20260927T120546422-44012`：import 阶段红（`NotoSansCJKsc-Regular.otf` 字形缓存 3 行 ERROR），规则／窗口未跑；同参数第二次 `20260927T120630951-8732`：`CHECK import: 7.52s`、architecture PASS 4468、UI 5 PASS／`display` FAIL 1（新检查夹具取 `mana_max` 钳制，非产品缺陷，已改夹具并在 `20260927T121306318-16868` 复绿）。
  - 最终门 1（`-Suite architecture,normal_play -UI -UISuite display,home,enemies,guard,interface,intent,special_equipment,hero_art,installed_tools,action_copy,normal_play -KeepGoing -TimeoutSeconds 3600`）运行号 `20260927T125226213-3404`：docs PASS（35 文档／2487 引用／0 问题／allowlist 6）；规则 `architecture PASS`＋`normal_play PASS`（`PASS: 5991 assertions`）；UI：`display`／`special_equipment`／`home`／`hero_art`／`intent` PASS，`installed_tools` FAIL 2、`action_copy` FAIL 2＋引擎错误（窗口阶段就此中止，后 4 模块 unrun）；`summary.json` `before==after=894587E4…D5D9`，无 `SOURCE CHANGED`。
  - 最终门 2（`-UIOnly -UISuite interface,enemies,guard,normal_play -KeepGoing`）运行号 `20260927T130735958-54184`：`interface PASS` 422、`enemies PASS` 221、`guard PASS` 92、`normal_play FAIL` 1。
  - `action_copy` 单模块复核（`-UIOnly -UISuite action_copy`）运行号 `20260927T131253711-50296`：同 2 条红＋3 引擎错误，**确定性单模块红、与模块顺序无关**。
  - 分类计数：display 986、home 140、hero_art 63、intent 48、special_equipment 60、interface 422、enemies 221、guard 92、installed_tools 57、action_copy 5（早停）、normal_play(UI) 605（长跑 step≈150 后早停）。
- P2 四条未修红（本轮只诊断，未改；均非本刀两项阻断，且不涉舞台米表／敌人舞台件）：
  - `installed_tools` 2 条（`ENV UI installed tool retains its class label`、`TOOL UI installed details show passive instead of direct cutting`）：现象＝`t.click("item_install",…)` 成功后 `visible_text(ui.layout)` 仍无「… · 已安装」／「伤害时触发」；可能域＝提交后**打开着的道具抽屉**（`ui/main.gd::_refresh_drawers`／`_items_drawer`／`_item_details`）只在 `render` 重建，而 `_drawer_presentation_key` 只有 `[save_failed,demo_finished]`，该次提交的脏集不含 `drawers`，局部路径无人负责抽屉内容；同源判断＝**同类不同面**（present 分区未覆盖 `render` 独占的面，与我修的两项同族，但不是同一缺陷）；所需裁定＝抽屉内容是否要节级归属，或把 `_drawer_presentation_key` 扩到覆盖打开抽屉读取的 View 字段（后者会让这类提交退回全量，属 perf 取舍，须规划者／协调者定）。
  - `action_copy` 2 条（`COPY UI real attack drag opens character bubble`、`COPY UI character bubble keeps portrait and spoken line without rendering a speaker name`＋`get_global_rect on null`）：现象＝`ui.restart(42)` 后把固定行动（`t.action_button("strike")`）拖到敌人接收器，`view.speech` 未落成气泡（`HeroSpeech` 缺失，第二个红与其后的 null 崩溃同因）；可能域＝固定行动拖放载荷（`ui/drag_targets.gd::intent` 携带构键时 `version` → `ui/drop_target.gd::_drop_data` → `main.gd::_attack_drop_candidate` 的版本／键面复核 → `_submit` → `speech` 节）；同源判断＝**未知偏否**（同类机制：拖放载荷版本与重建时机；卡牌拖放同路径在 `enemies`／`guard` 全绿，说明不是舞台件本身）；所需裁定＝是否另开切片复核「固定行动拖放」的载荷版本与 `speech` 节挂载，或先确认它是否本线既有基线红（本刀未做 base 对照，故不宣称归属）。
  - UI `normal_play` 1 条（`NORMAL UI chosen action commits once: 解除 · 大臂上侧—手肘上方链接绳`，长跑 step≈150）：现象＝链接绳目标上的解除牌拖放后 `view.version` 未前进（未提交）；可能域＝drag popout 目标（`ui/drag_targets.gd`＋`ui/main.gd::_refresh_body_details`）与解除卡候选的同一拖放路径；同源判断＝**未知**；所需裁定＝同上（是否另开切片；`release_target` 命中不提交的定向复现需要更长预算）。
  - `intent` 5 条（他树 `20260927T120501823-57064`）＝**已由本刀修复**：那 5 条正是意图图标在局部路径不更新（`INTENT UI actual highlighted term exists`×2、`hides original icons while interrupted`、`interrupt hover contains only the interrupted message`、`LAST ORDER UI completed action is not described as idle`），本树 `intent PASS`（`20260927T120630951-8732` 与 `20260927T125226213-3404`）。
- 未跑：`-Suite all` 完整回归；窗口其余分类（`casting`／`touch`／`keyboard`／`route`／`body_layout`／`targeting`／`composites`／`baseline`／`equipment_complete` 等）；`composites` 既有 2 条基线红未复跑；`-Exhaustive` 只用于 `normal_play`；`installed_tools`／`action_copy` 早停后其模块内后续断言未执行；安卓真机；打包／推送。
- 过程：调试期在 `tests/display_ui_cases.gd` 临时加过 3 条 `print` 与临时探针，均已移除（`git diff` 内不含 `print(`／`SENSITIVITY PROBE`）；`core/game.gd` 的变异与还原逐字节一致（`git diff` 空）；`-Import` 生成的 `*.import` 已按路径还原、`ui/command_router.gd.uid`／`ui/command_routes.gd.uid` 已删除、`spire-godot/tmp/` 探针目录已删；`build/` 不入库。
- 日志位置：`spire-godot/build/checks/<运行号>/`（本 worker 工作树内）。未 push、未打包、版本未动。

## 2026-09-27｜补记：`collect_keys` 归位后的卡片域覆盖（枝 `worker/stage-sync`，commit `ebf884b`）

- 域：`data/card_text.gd::SLOT_TARGET_IDS`／`data/balance.gd::slot_target_ids()`／`core/card_effects.gd::card_facts`（承诺零行为变化）。
- 命令（`spire-godot/`，`GODOT_BIN=…console.exe`）：`& tools/check.ps1 -Suite card_power,content,casting -KeepGoing -TimeoutSeconds 900` → 运行号 `20260927T131621014-19444`：`card_power PASS`／`content PASS`／`casting PASS`，`PASS: 3500 assertions`，docs PASS（35 文档／2487 引用——含 `-Suite casting` 未再拉宽 docs 之外的范围），exit 0。
- 该跑在冻结源（`git status` 干净、提交后未改文件）上执行，`before==after`；补上门禁原本未覆盖的卡片文本／内容分类，`architecture`（含 `card_facts_keyword_min_query`）已在 `20260927T125226213-3404` PASS。
- 未跑：`equipment`／`equipment_complete`（只在 item 3 的变异探针里跑过，非冻结源结论）；`data/`／`core/` 其余分类；`-Suite all`。

## 2026-09-27｜三条残留红收口：道具抽屉节级归属、speech 节挂载、拖放载荷版本盖章（枝 `worker/stage-sync`）

- 域：`spire-godot/ui/main.gd`（`_drawer_presentation_key`／`_drawer_key_hit`／`_refresh_drawer_section`／`_refresh_drawers`／`_menu_drawer`；`present` 与 `_present_needs_full_render` 的 `drawers` 谓词；`_submit`／`_submit_dirty` 的提交前过滤；`_begin_target_drag`）；契约 `docs/spec/response-pipeline.md`（`drawers` 节键行、输入域过滤句）与 `docs/spec/release-interface.md`（拖放载荷版本盖章）。未改任何既有断言，三个被修模块的断言一字未动——红→绿即敏感性证据（本刀未新增断言）。
- ① `installed_tools` 2 条（根因＝提交后**打开着的道具抽屉**只在 `render` 重建，而 `_drawer_presentation_key` 只有 `[save_failed,demo_finished]`）：键改为覆盖道具抽屉内容面（道具行、选中与说明态、选中道具候选切片、身体目标）；`_drawer_key_hit` 按**当前打开的抽屉**校验节点集；`_refresh_drawer_section` 就地重建该抽屉（`show_items` → `_items_drawer`，否则 `_menu_drawer`），**未退回全量**——`drawers` 谓词改为允许 `show_items` 单开，仅对其它抽屉保留全量兜底。红：`20260927T125226213-3404`（FAIL 2）；绿：`20260927T133516054-10724`（installed_tools／items／action_copy 全 PASS）。
- ② `action_copy` 2 条＋引擎错误（根因＝**刷新缺口**：`_submit` 的提交前过滤把「提交前未挂台词」的 `speech` 节从脏集剔除，而本次提交正是要挂载新台词；诊断 `20260927T133028224-2980`／`20260927T133206361-2968`：拖放提交成功、`view.speech` 已就位、仅 `HeroSpeechGroup` 未挂载——`_speech_key=[]`、`groups=0`、`_speech_visible` 与其它守卫全通过）：`speech` 退出该过滤，空台词／接管锁定／已跳过仍由 `present` 谓词兜底为全量。红：`20260927T131253711-50296`（单模块 FAIL 2＋3 引擎错误）；绿：`20260927T133516054-10724`、`20260927T134532592-35724`、`20260927T135103403-43628`。
- ③ UI `normal_play` 1 条（根因＝**拖放载荷版本陈旧**：卡牌按钮在版本自增前构建并存活于界面，`drag_payload.version` 落后于 `view.version`，落点 `accept_card` 的 `incoming.version==view.version` 复核因此拒绝；诊断 `20260927T134227820-15808`：`dragpre v=162 active.version=161`、`dragdone v=162 notice=""`、拖放字段 13 个仍在）：`ui/main.gd::_begin_target_drag` 在拖拽开始时把载荷 `version` 盖成当前 `view.version`（候选本就在此刻从当前 View 重取），拖拽期间状态再变化仍被拒。修复前本树**三次全红**（`20260927T130735958-54184`、`133820440-38428`、`134227820-15808`；确定性、非间歇——协调者记的 `125226213-3404` 该模块实为 unrun），修复后两次全绿（`134532592-35724` 跑完全程到路线检查点、`135103403-43628`）。
- 门禁（`spire-godot/`，`GODOT_BIN=C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`）：`& tools/check.ps1 -Suite architecture,normal_play -UI -UISuite installed_tools,action_copy,normal_play,display,intent,enemies,guard,interface,home,special_equipment,hero_art -KeepGoing -TimeoutSeconds 3600` → 运行号 `20260927T135103403-43628`：docs PASS（35 文档／2490 引用／0 问题／allowlist 6）；规则 `architecture PASS`＋`normal_play PASS`（`PASS: 5991 assertions`）；UI 11 模块全 PASS（`UI PASS: 3074 assertions`；分类计数 display 986／installed_tools 57／special_equipment 60／home 140／hero_art 63／intent 48／action_copy 40／interface 422／normal_play 945／enemies 221／guard 92）；`summary.json` `status=passed`、`before==after`、`failed=[]`、`unrun=[]`。
- 过程：调试期临时探针（`display_ui_cases.gd` 的 `probe_action_drag`、`action_copy_ui_cases.gd` 的 ACPROBE 打印、`normal_play_ui_cases.gd` 的 NPUI 打印）均已移除，三个测试文件相对上一提交零差异（`git diff` 空）；`*.import`／`*.uid`／`build/` 未入库。
- 未跑：`-Suite all` 完整回归；窗口其余分类（`casting`／`touch`／`keyboard`／`route`／`body_layout`／`targeting`／`composites`／`baseline` 等）；`items` 只在 `20260927T133516054-10724` 单跑覆盖；安卓真机；打包／推送。

## 2026-09-27｜第二轮复审收口：撤销拖拽盖章改显示侧刷新、敌人行布局单例程、邻接表与本地化对齐、键成本测量（枝 `worker/stage-sync`）

- 域：`spire-godot/ui/main.gd`（`_sync_drag_versions`／`_begin_target_drag`／`_enemy_row`／`_place_enemy_row`／`_battle_scene`／`_refresh_scene_instances_section`／`_drawer_presentation_key`／`_select_enemy`／`_sync_enemy_select`／`_sync_hero_stage_meters`／`PRESENT_ADJACENCY`）、`spire-godot/core/card_effects.gd`＋`spire-godot/data/card_text.gd`＋`spire-godot/data/balance.gd`（`need_slots` 判定归 data）；契约 `docs/spec/release-interface.md`（拖放载荷版本条目改写）与 `docs/spec/response-pipeline.md`（`drawers` 键面、`scene_instances` 行布局、局部固定顺序）。未改既有断言。
- **B1（阻断，muse／bunny 同判）**：撤销上一提交在 `ui/main.gd::_begin_target_drag` 的载荷 `version` 盖章，改由显示侧 `_sync_drag_versions()` 在 `present`／`render` 落地后对**保活的手牌卡面与行动瓦片**原地追平 `drag_payload.version`（同 `_refresh_card_face` 的保活刷新方式；用 `Object.get("drag_payload")` 而非 `is DropTarget`，因为手牌按钮是 `ui/card_face.gd` 而非 `DropTarget`——首次修复用类型过滤漏掉卡面，`normal_play` 仍红，已改正）。**如实更正上一条记录**：拖放载荷的版本刷新不是本轮新增能力；`targeting` 的 `for stale in [true,false]` 段一直断言「过期拖拽被拒并在目标旁显示『行动已失效』」，盖章会让它恒不成立；现在该拒绝完整保留。
- **R1（应修）**：敌人行布局收口 `_enemy_row()`＋`_place_enemy_row()`（展示顺序、契合缩放、行宽、起点、各组位移／缩放），`_battle_scene` 与 `scene_instances` 节共用，击杀后剩余敌人就地重排（此前局部路径不重算几何）。
- **R2／A（应修，纯一致性）**：`PRESENT_ADJACENCY` 逐条按实现体改正——`_release_enemy_stage` 删假边 `_unload_resource_direct`；`_configure_enemy_drop` 补 `_attack_drop_candidate`；`_refresh_drawer_section` 补 `_items_drawer`；`_menu_drawer` 删假边 `_drawer_presentation_key`；补 `_enemy_hp_text`、`_sync_drag_versions`、`_enemy_row`、`_place_enemy_row`，并同步 `_refresh_scene_instances_section` 与表头注释。
- **B（本地化／收敛）**：`_select_enemy` 的名条改写循环收敛进 `_sync_enemy_select`（同一文本表达式、同一色调与 `disabled` 来源，选中点击与局部刷新一条路径）；`_sync_enemy_select` 创建分支经 `_button`（其体为 `b.text=localization.display(text)`）与更新分支的显式 `localization.display` 同走显示边界——即两侧本就是同一入口，记录在案。
- **Q4（做）**：`HeroGuardBind` 数值标签并入 `_meter_value_text`；**Q3 登记为遗留**：`ui/resource_feedback.gd::update_numbers` 仍带第二份数值格式（`snappedf(...,0.1)`＋`.trim_suffix(".0")`），只在资源反馈动画期覆盖 `MainMana`／`HeroMana` 的条与标签，本刀不动（属动画期显示通道，与节侧终值格式并存）。
- **Q1（做）**：`core/card_effects.gd::card_facts` 的 `need_slots` 判定整体归 data——`data/card_text.gd::collects_slots(card_type,traits,has_target_slots)`（`FOLLOW_THROUGH_ID` 与 `SLOT_TARGET_IDS` 同处声明）＋`data/balance.gd::card_collects_slots(type)` 转发，core 只调接口；语义逐条保持（`target_slots`、面模式∩关键词 id、任一面带顺延）——注意**未**改成「任一收集 id 出现在 ids 即收集」，那会扩大候选集。
- **R3（测量＋收窄）**：在 display 临时探针里按 200 次/档测 `_drawer_presentation_key()`（`Cases.r1_build("battle",N)`，本机同一轮，探针已移除）：1／10／30 件 → **44／136／198 µs**（≈线性，+5.3 µs/件）；键体 JSON 字节：行 616／616／614、选中道具候选切片 789／2306／5656、全身体目标 562／5408／16292、收窄后触达条目 544／5463／16515。结论：线性来自**选中道具的候选切片＋其触达的装备行**（抽屉实际渲染的内容，不能删），`bodies` 收窄在本最坏用例（道具对每件都可用）**中性**（收窄版 44／138／200 µs、字节持平），一般情况严格更小。已按 bunny 建议把 `bodies` 收窄为「候选切片触达的身体组名或装备行」（`_item_details` 取名用 `body.id`／`name`、`_tool_target_card` 读该目标条目，两处均覆盖）。
- 门禁（`spire-godot/`，console 引擎）：`& tools/check.ps1 -Suite architecture,normal_play -UI -UISuite display,installed_tools,items,special_equipment,home,hero_art,targeting,intent,action_copy,interface,normal_play,enemies,guard -KeepGoing -TimeoutSeconds 3600` → 运行号 `20260927T145541727-44420`：docs PASS（35 文档／2490 引用／0 问题／allowlist 6）；规则 `architecture PASS`＋`normal_play PASS`（`PASS: 5991 assertions`）；UI **13／13 PASS**（`UI PASS: 3298 assertions`；display 986／installed_tools 57／items 46／special_equipment 60／home 140／hero_art 63／targeting 178／intent 48／action_copy 40／interface 422／normal_play 945／enemies 221／guard 92）；`summary.json` `status=passed`、`before==after`、`failed=[]`、`unrun=[]`。
- B1 定向前置门：`-UIOnly -UISuite targeting,normal_play` 运行号 `20260927T145142648-19712`：`targeting PASS`（含 `for stale in [true,false]` 段）＋`normal_play PASS`（1123 断言）；类型过滤未改正时同门的红跑为 `20260927T144748632-56464`（`ui.selected=[targeting,normal_play]`、`normal_play FAIL`、`UI FAIL: 783`；指纹早于最终树，只作诊断）。
- 过程：临时探针（键成本、拖拽诊断）均已移除；`*.import`／`*.uid`／`build/` 未入库。
- 未跑：`-Suite all` 完整回归；窗口其余分类（`casting`／`touch`／`keyboard`／`route`／`body_layout`／`composites`／`baseline` 等）；安卓真机；打包／推送。收尾（只动注释／契约／记录＋一条新断言）：①记录里那条红跑运行号更正为 `20260927T144748632-56464`；②`PRESENT_ADJACENCY` 补 `present → _sync_drag_versions`、`_sync_hero_stage_meters`／`_resource_meter` → `_meter_value_text`，表头删掉「`_menu_drawer` 读 `_drawer_presentation_key`」的不实句、并在 `scene_instances` 枚举里点名 `_enemy_row`／`_place_enemy_row`；③`release-interface.md` 的拒绝提示改为两句原文（「目标已离场或行动已失效。」／「行动已失效，请重新选择。」），覆盖面写全为 `card_buttons`＋`candidate_buttons`；④新增几何断言「局部路径击杀后剩余敌人重排」——绿 `20260927T154455876-57212`（display PASS 987 断言），敏感性：临时去掉 `_refresh_scene_instances_section` 的 `_place_enemy_row(_enemy_row())` → 运行号 `20260927T154638554-51676` 该断言红（`have=["enemy_2@(1178.0, 0.0)/(1.0, 1.0)"]`，幸存者留在双敌行位而未回到单人位 1038），已还原。
- 每帧成本：`_sync_drag_versions` 在每次 `present`／`render` 各跑一遍 O(存活拖放源) 的写循环（只改一个字段，无分配、无节点重建；只在 `card_buttons`＋`candidate_buttons` 上循环，对局内量级为手牌＋当前行动／体态瓦片）。残留：`_sync_drag_versions` 只覆盖手牌卡面与 `candidate_buttons`（快捷解除栏／身体栏／商店／卡组浏览等模块自建的 `DropTarget` 未纳入，若日后出现「版本自增后拖拽被拒」的症状，先在那些模块补同一例程）。

## 2026-09-21｜英文运行时目录补全与稀有卡面整句翻译

- 重新盘点英文兼容目录，人工补齐104条未缓存运行时源文，覆盖铁男及随行单位、塔顶、卡牌动态片段、显示设置与错误提示；生成后的`legacy-en_US.json`含5434条消息，英文译文CJK残留为0，动态参数校验通过。
- `猪神之皇焚`拘束面会先将`超级顺延`提取为独立关键词；补充提取后的完整正文模板，并将完整模板统一为`Struggle {base} × {hits} hits`、`Full Follow-Through`与`Tightness`术语，避免碎片回退产生`None视`／`Tightness减伤`。
- `20260921T065650387-13648`：`card_power`真实窗口套件387条断言通过，覆盖`Cards.give`→`ui.render`→实际卡面、关键词标签、整句正文及卡面无中文。生成脚本实际完成，`git diff --check`通过。
- 初轮`20260921T065048588-27736`中规则`localization`171条通过；随后工作区并行加入正式日语目录，现有两条“日语仍为空占位”旧断言失效，最终`20260921T065943018-29020`仅因此失败2条。全量盘点重跑也被同一在途改名的`ui.main`旧回退文案提前拦截；未覆盖或归入本次英文改动。
- 独立只读审查`review_english_localization`核对关键词拆分、参数顺序、术语与真实卡面回归，无阻断项。未跑全项目回归，未打包、提交或发布。

## 2026-09-21｜日语本地化全量接入

- `ja_JP.json`由空占位资源改为64条完整语义译文；新增`legacy-ja_JP.json`，覆盖当前5434条运行时中文源文。设置页语言名改为`日本語`，主界面、设置页与兼容显示管线均通过现有`ui/localization.gd`切换，不改变玩法状态、候选或随机。
- `tools/build_japanese_catalog.py`以中文为源，校验英文目录源版本，保存稳定哈希ID，并将旧式`%`／命名参数转换为兼容目录所需的`{pN}`。高频界面、出狱检查、临时魔力、布阵、唯一、火球与关键工具规则使用人工日文；其余目录采用机器辅助初译，长事件和对白经过第二轮润色。生成器拒绝空译文、乱码、占位符泄漏及异常重复。
- 结构检查：语义目录64／64、兼容目录5434／5434；中日源文集合、稳定ID和动态参数契约一致，空译文、`ブラックリスト`、乱码问号、`[PH]`／`ZXQ`残留、异常重复及信息量坍缩均为0。内置Noto Sans CJK字体覆盖日文假名与目录实际使用的CJK字符。
- 首轮`20260921T084832331-40560`因日文兼容目录沿用源格式参数而失败1条，保留失败并修正生成器统一转换参数。`20260921T085027456-19736`续跑通过；`20260921T085628526-20164`中规则234断言、真实窗口52断言通过，补截图后`20260921T090430523-30032`再次单跑真实窗口52断言通过。独立审查随后发现少量译文被压缩成符号／单个词，新增全目录信息量与重复片段门禁并重译，另加5条真实显示反例；首轮`20260921T092603865-18900`由术语不一致失败1条，保留用例并人工定稿，`20260921T092729667-39492`续跑规则239断言、真实窗口52断言全部通过，exit 0、status=passed。
- 第一轮独立复审继续发现两条音乐名幻觉、7条35%—50%区间的语义缺失及短文案只剩参数／符号。逐条定稿全部3种`雨爱`卡面、否定／目标／监狱／成长／弃牌堆／商店标题，并把信息量门禁提高至50%、覆盖最短2个可见字符；由此检出的33条短文案全部补齐动作语义，重扫为0。`20260921T094718470-18872`新增弃牌堆动态用例首次因测试牌名也被递归翻译而失败1条，改用中性动态值后`20260921T095032925-21296`续跑规则248断言、真实窗口52断言全部通过，exit 0、status=passed。生成器连续运行的两个目录SHA-256保持一致。
- 后续独立复审逐轮检出并关闭动态计数、存档校验、大魔棒、跨场恢复与“回合”误译。对被门禁拦下的79条回合相关源文全部改用人工定稿，不再接受仅靠目标中任意“回”字通过；门禁改为必须出现`ターン`或`ラウンド`，另拒绝目标中的`回合`／`原始`／`次数`／`装备`／`结算`／`档`简中残留。补充动态第N回合、准备回合恢复、100阈值收押、存档校验和大魔棒真实显示反例。
- `20260921T114317224-42668`首次加入简中残留测试时误扫整份JSON、把中文source也算作目标而失败1条；保留门禁并改为逐条只检查target。`20260921T114438601-3680`续跑规则261、UI52通过。随后扫描再发现`100年`与动态回合硬编码，修正后在当前源码重新生成，最终`20260921T115157119-36792`规则261、真实窗口52断言全部通过，exit 0、status=passed。兼容目录仍为5434条、空译文0；指定污染词全为0，生成器连续两次输出SHA-256一致。
- 独立语义复审继续按真实源句抽查监狱、快感、敌人行动、商店、卡牌、屏障、捕缚、事件与教程入口；逐批关闭会反转条件、漏价格／次数／阈值、丢动作或混淆资源类型的机器初译。门禁新增字面数字完整性以及“最多／至少／免费”的方向检查；新增检查当场从旧目录检出17条数字缺失、4条上限缺失及2条免费条件缺失，修复后均归零。关键反例另以真实`Localizer.display`断言固定三选一奖励、跨战快感、捕缚、会员卡半价、复放目标、屏障共享额度与大魔棒跨战计数。
- 最终`20260921T140301914-41128`：`localization`规则289条、真实窗口52条全部通过，exit 0、status=passed；独立只读复核在同一当前态 fresh 运行`20260921T140523289-20948`，同为规则289／UI52通过且无`SOURCE CHANGED`，未再发现改变玩法、数字、动作或流程的高置信问题。语义目录64条、兼容目录5434条；生成器`py_compile`通过，连续两次重建的SHA-256一致：`ja_JP.json`为`E0BE4A90CBAD72E1E9304DD7C49AB07565A91DD979216428CBA732DCCEB3E321`，`legacy-ja_JP.json`为`976EB153427E05740B163688913B6ED3203D8FD47D52F8717E5392E9B02A0DA1`。
- 未运行全项目回归、人工逐句母语校审、安卓真机、打包或发布。本次只接入资源、生成器、切换文案、文档与本地化测试；工作区其它在途修改保持原状。


## 2026-09-21｜审查规范按风险合并

- 范围：根AGENTS.md与repo-ops、spire-architecture、spire-validation-release三份技能。保留纯数值免独立审查；错字／链接／格式且不改契约的文档修正同样免审，核心契约和测试判据变化仍须审查。批次初审独立，返修复用审查者，文档／实现／测试合并审；日常Terra medium，关键Astra low，复杂疑点按需升级medium。
- 结构变化才补必要图，局部修复说明影响范围；PR上游核对按集成／同步／推送或旧PR分支触发。合并架构技能重复要求；正式运行所需校验保留，诊断与敏感性实验按影响范围执行，不因缺少旧证明删除有效检查。
- 四文件UTF-8、引用文档路径与git diff --check通过；技能元数据人工核对通过。系统与打包运行时Python均缺PyYAML，技能自带quick_validate未能启动，未记作通过、未安装额外依赖。证据：spire-godot/build/review-policy-20260921/docs-check.json，含四文件SHA256与体积。
- 独立只读审查review_review_policy（gpt-6-astra／low）无实质发现，推演纯数值、文档修正、核心事务联合变更、失败修复影响已通过分类、source_changed与本地无推送请求六个情景；核对必要接口，未重复运行游戏检查。仅调整规范与本条记录，未改游戏实现／测试、未更改全局模型配置、未打包或推送；其它在途修改保留。


## 2026-09-21｜魔力转换20魔力换2能量

- 只修改既有注册表费用／收益、卡面文案与对应测试预期，支付、临时魔力优先、失败返还和能力／遗物累计沿原管线。按当前AGENTS纯数值豁免不派独立审查。
- 20260921T101105634-11684：witch_character 786、card_power 2204、card_expansion 1683断言通过；relics旧后续断言仍按10耗魔的余额及收益计算而失败。同步为累计余量10、总能量增加3后，20260921T101419371-37708所有选定断言通过，但source_changed，不作冻结证据。
- 最终20260921T101603855-18784：relics／casting共2552规则断言、casting UI 59断言通过，退出0、status=passed，前后指纹同为D57B0515AC2E3524DFD61CBA59BA14A8C83453A0FBA32C13EE47C55252A89040；之前通过的三个分类在其后仅测试预期修订下复用。覆盖临时魔力支付、施法失败退款、共鸣固定费用、魔力回路与魔力耳环累计、双面卡面角标。定向diff检查通过。未跑全量、未打包发布。


## 2026-09-22｜项目代码许可升级 GPLv3

- 按用户要求将根LICENSE替换为GNU官方GPL第3版全文；README.md及ASSET_RIGHTS.md统一声明GPL-3.0-only，沿用仅此版本选择。适用于项目自有代码、测试与构建脚本；素材及第三方许可范围保留，历史版本以随附许可证为准。
- LICENSE与https://www.gnu.org/licenses/gpl-3.0.txt下载正文逐字节一致：35149字节，SHA256为3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986。三文件编码、9处本地链接、git diff --check通过；排除历史记录及第三方内容后的现行项目GPLv2声明残留为0。证据spire-godot/build/license-gpl3-20260922/check.json。
- 独立只读审查review_gpl3（Astra low）无实质发现；两平台打包脚本均复制根LICENSE，无需修改。未运行游戏回归、重打历史安装包、提交或推送；已有规范维护差异保留。


## 2026-09-28｜PR #11 合并准备

- 目标main 8398b1c、PR头ec60197；独立分支codex/pr11-integration-20260928整合PR与八项当地在途修改，原主检出逐文件哈希保持不变。修复反馈能力探针重定向丢附件，并按指令契约更新composites两条旧预期；不把PR切片基线红误称目标主分支既有红。
- 51规则分类34540断言、14界面模块3006断言、测试器负例、离线反馈服务契约与35文档2492引用均通过；最终四轮源码指纹一致。修前反馈新增302／303断言已证红。Astra low独立审查与定点复核完成。
- 命令、运行号、失败记录与未验证边界见[合并准备记录](pr11-integration-preparation-2026-09-28.md)。未跑normal_play及其余UI模块、人工试玩、安卓真机、实际邮件、性能或发布验收；未合入main、推送、部署或打包。


## 2026-09-28 合并发布标识：0.18.2.fix

- 用户授权将 PR #11 准备分支合入 main 并推送，数字版本保持0.18.2、显示后缀加`.fix`；本批不打包、不创建标签或Release。
- 项目标题、版本、两平台预设、英日文标题及其legacy哈希ID同步；Windows数字文件版本仍为0.18.2.0，Android安装code暂为14，下次出APK前按打包契约递增。两份原打包入口接受可选`.fix`，继续用完整版本选择预设、产物名及版本说明。
- 增量验证：`tools/check.ps1 -Suite localization -UI -UISuite localization,home -KeepGoing -TimeoutSeconds 300`，运行`20260928T124740514-40908`，localization 289 PASS，窗口2模块192 PASS，文档35文件2492引用PASS；exit0且before==after。未受影响规则复用上一条PR整合证据，未重跑全量。
- 版本脚本验证：PowerShell 7执行`spire-godot/build/pr11-prep-20260928/verify-fix-version.ps1`，32项通过；从实际两脚本AST取版本表达式，覆盖原数字版本、`.fix`、非法及重复后缀、路径混入，核对预设／说明存在与语法。恢复旧表达式会拒绝`.fix`，敏感性成立；未调用真实导出。
- 首次`20260928T124609227-54148`文档门禁将普通路径中的`.fix`截为扩展名；改用现有Markdown相对链接后复验通过。首次因同时改文档记为source_changed，不视为通过；上述冻结运行重跑完整原选范围。
- 原审查者对版本消费者、打包路径、本地化及说明定点只读复核，无新增阻断。原主检出八文件逐一SHA256与准备备份一致，内容已整合；额外保留stash `530be148ea0d1fc373847e9daaf247319c69d18a`，不重复应用。
- 未运行安装包验收、安卓真机、人工试玩或反馈部署；本批只同步源码。
## 2026-09-28｜手牌卡增量刷新：固定顺序、每卡窄键、面切片缓存（枝 `worker/hand-refresh`，实现者）

- 域：`spire-godot/ui/main.gd`（手牌节 `_hand`／`_hand_presentation_key`／`_hand_key_hit`／`_hand_card_key`／`_hand_card_data`／`_hand_face_slice`／`_hand_apply_card`／`_hand_mount_card`／`_hand_release_card`／`_hand_place_row`／`_hand_row_plan`／`_hand_reset_row`／`_hand_cards`／`_hand_layout`／`_card`／`_refresh_card_face`／`_card_tooltip`／`PRESENT_ADJACENCY`）与 `spire-godot/ui/card_face.gd`（原地更新 setter、`set_mana` 按位置／kind 复用、`text_overflow`）；契约 `docs/spec/response-pipeline.md`／`docs/spec/release-interface.md`／`docs/spec/hand-refresh-dependencies.md`／根 `AGENTS.md`；测试 `tests/display_ui_cases.gd::present_hand_incremental`（P1–P3／N1–N5／E1–E10）与 `tests/interface_ui_cases.gd::card_face_incremental`。唯一被改写的既有断言：`DISPLAY present hand rebuilds the card when the presentation key changes` → `…keeps the card and rewrites its values…`（反向而不删，判据＝同 uid 实例 id 不变＋`CardAvailability` 等于新值＋该卡子树零增删）。
- 门禁（`spire-godot/`，`GODOT_BIN=…Godot_v4.7.2-stable_win64_console.exe`；**串行**执行，每条跑完确认 `Get-Process Godot*` 为 0）：
  - `& tools/check.ps1 -UIOnly -UISuite display,interface,body_layout,card_power,targeting,keyboard,touch,localization,hand_assist,encyclopedia,casting,rewards,services -KeepGoing -TimeoutSeconds 1800` → 运行号 `20260928T065101211-31212`：13／13 分类 PASS，`UI PASS: 3443 assertions`，`summary.json` `status=passed`、`before==after=372CC9FBA0E0AB42F7A9EC9CC7987070EB9CF648451D5BFF9F3D1C8ED4A1497F`、`failed=[]`、`unrun=[]`、exit 0。（载荷分类列表外另加 `casting,rewards,services`：`set_mana` 改写的外溢面取证，审查要求。）
  - `& tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 900` → `20260928T070508397-34364`：`architecture PASS`，`PASS: 4468 assertions`，同一指纹。
  - `& tools/check-docs.ps1` → `DOCS PASS: 36 rule-class document(s), 2592 reference(s) checked, allowlist 6 entrie(s)`，exit 0（引擎无关，无独立运行号；同一文件的 `docs` 阶段在三条门禁里均为 passed）。
  - `& tools/check.ps1 -Suite runner -VerifyRunner` → `20260928T070552510-23932`：`runner PASS`（541 断言）＋7 条负例探针（范围拒绝／脚本错误／超时／失败停止与续跑）全绿。
- 三套计数（测试侧实例 id 集合差，真窗口、真实点击／拖拽；生产源码无计数器）：
  - 值变（P1）与纯重排（P3）＝卡面重建 0／整行重建 0／创建 0／销毁 0；P3 的第二次 `present` 位置、实例与子树全同（零写入）。
  - 翻面（P2）＝按钮与八个直接子节点实例 id 不变、未变魔力条目的徽章节点与 `panel` 样式资源实例 id 不变、翻回零增删、`_hand_cards[uid].sides` 的两面切片对象被复用（`is_same`）。
  - 出牌／行矩变（N1／N3）＝只释放该 uid，存活卡实例与子树零增删、位置与 `home` 等于新张数几何槽位。
  - 出牌＋抽牌同提交（E2，结束回合同提交）＝被删 uid 全释放、新 uid 全新建、保留卡实例不变、`_hand_cards` 与手牌对齐。
  - 清空／从空恢复（E5）＝`EmptyHand` 恰 1／恰 0，`card_faces`／`card_draw_serials`／`_hand_cards` 不含离行 uid；过载行态（S8）＝`ClimaxNarration` 恰 1、卡行与缓存清空，随后恢复。
  - 满手牌（E6）＝10 张零增删且槽位等式成立；`draw_serial` 变而面不变（E7）＝零写入；无关显示设置（E4）＝零动作、零 `get_view`；`type` 变（N2）＝只重建该 uid。
  - 现状基线：整行重建＝1（出牌／抽牌／值变场景），`hand` 节中位 13.0 ms——见 `C:\1\tmp\hand-refresh-plan\plan.md` §12 与 `docs/record/equipment-performance.md` 的口径。
- 子键逐档（`build/probe-hand/key_cost.gd`，headless 同机、200 次／档；探针已删）：`tests/architecture_cases.gd::r1_build("battle",N)`，N＝0／12／26／44 → 每卡键中位 **16／16／18／17 µs**，整行键中位 **91／91／104／92 µs**，每卡切片字节 **436／436／436／436**（非法术卡逐档持平）。整行键字节 2584／2684／2684／2789：增量只来自两张法术卡的 `face_casting`／`availability` 文本随装备变长（magic_slip 670→793、ease 556→638 字节，≈+2.9 字节／件），不是键随件数扇出；时间不随件数增长（对照记录：`_drawer_presentation_key` 1／10／30 件为 44／136／198 µs）。
- 敏感性（逐条：临时改源码 → 定向分类 → 指定断言红 → 逐字节还原并复核 `git` 指纹回 `372CC9FB…`）：
  - ①`_hand_apply_card` 改为「释放＋重建该卡」→ `20260928T070624507-28560`：P1／P2／P3 的实例 id、八子级与零增删断言红。
  - ②每卡键删 `locale` → `20260928T070832853-25952`：E3 的「切回中文」断言红（前向切英文由 `_localize_controls` 兜底，反向无兜底）。
  - ③`set_mana` 每次新建 `StyleBoxFlat` → `20260928T071043504-23032`：徽章节点与 `panel` 样式资源实例 id 断言红。
  - ④`_card_tooltip` 溢出判据改回 `Content.size.y` → `20260928T071147829-29028`：悬停详情行集合断言红（审查 D10 时序缺口的守卫）。
  - ⑤`_hand_release_card` 不清 `card_faces`／`card_draw_serials`／`_hand_cards` → `20260928T071250019-26808`：四表一致性两条红（N1／E5）。
- 未跑：`-Suite all` 完整回归；窗口其余分类（`route`／`home`／`pressure`／`enemies`／`guard`／`baseline`／`normal_play` 等）；**配对耗时**（`build/present-cost` 口径的 §D 阈值）——未建旧侧基线探针，故本片不报逐对比值，只有结构计数与键成本判据；§G 其余行（`_hand_mount_card` 整行重建、每卡键删 `chosen`、`_hand_place_row` 幂等守卫去掉、`type` 原地变更、pending 可见性走重建、手牌路径回读 `view.card_texts`、每卡键混入 View 级切片、删除步骤 3 的几何键比较）未逐条跑（每条各需一次临时改源码＋定向分类；`chosen` 与 `type` 的断言落点已在 `present_hand_incremental`）；安卓真机、打包、推送。
- 过程：探针与计时脚本只在 `build/probe-hand/`（登记后已删）；`*.import`／`*.uid`／`build/` 未入库。一条孤儿探针曾在源码带补丁时留下 display 跑 `20260928T063931003-28048`：**作废**（非冻结源；补丁已逐字节还原，指纹复核回冻结值）。

## 2026-09-28｜手牌增量刷新补记：配对耗时、剩余敏感性、挂载去重（枝 `worker/hand-refresh`）

- 域：`ui/main.gd::_hand_mount_card`（挂载后按同一份切片登记为“已应用”，去掉挂载后的第二次整面重写）、`tests/display_ui_cases.gd`（E2 追加 pending 可见性与实例断言）、`docs/spec/hand-refresh-dependencies.md`（登记挂载去重）、`docs/record/*`。
- **配对耗时（`acceptance.md` §D 口径）**：旧侧＝`C:\1\tmp\magic-spire-wt-hand-refresh-base`（detached `ec60197`，基础探针 `build/present-cost/probe_main.gd`）；新侧＝本树（`probe_main_hand.gd`＝基础＋hand 包装）；驱动 `build/present-cost/probe.gd` 两侧逐字相同；同机同窗口 1600×900、`tests/game_fixture.gd` 种子 42、`feedback_duration=0.04`、2 热身＋15 配对、旧/新逐次交替、每场景独立配对；电源方案 **Silent**（`powercfg /getactivescheme` = 64a64f24-65b9-4b56-befd-5ec1eaced9b3）。场景：s1 值变（`present(["hand"])`）／s2 纯重排／s3 真实点牌提交／s4 结束回合／s5 保留卡＋结束回合（增删同提交）。
  - 15 配对（新/旧 比值中位，两侧独立中位 µs）：`sections.hand` s1 **0.137**（6286→844）✓、s2 **0.122**（6625→782）✓、s3 1.133（592→645）、s4 1.177（5637→7182）、s5 1.125（6516→7335）；`submit_total_us` s3 **0.882**（33569→29852）✓、s4 **0.973** ✓、s5 **0.995** ✓；`present_total_us` s1 0.157／s2 0.142／s3 1.05／s4 1.02／s5 0.99。
  - 复核（7 配对，同一口径，最终修订）：`sections.hand` s1 **0.118**／s2 **0.086**／s3 1.244／s4 1.076／s5 **0.876**；`submit_total_us` s3 1.033／s4 1.009／s5 **0.958**。
  - 判读：S1／S2 的 `sections.hand` ≤0.5 达标（≈8–11 倍收益）；**S3–S5 的 `hand` 未达标**（+8…+24%，绝对值 +0.05…+1.5 ms）：整手牌被替换的提交（出牌／结束回合）在新路径上还要算行键与计划（每张新成员的键与数据合并），旧路径在该提交里本就是“卸下再建”的直线循环；同场景 `submit_total_us` 已在 0.88–1.00。结论记为“提交总量持平、hand 节在整手替换场景略慢”，不宣称该场景提速。
  - 新侧调用计数（探针中位）：s1 `apply_card=1, card_data=1, card_key=5, refresh_face=1, place_row=0`；s2 `card_key=5, place_row=1, refresh_face=0`；s4／s5 `mount_card=5, release_card=5／6, place_row=1`。
- **剩余敏感性（§G）**：R-a `_hand_mount_card` 改走整行重建 → `20260928T083849551-41880` 红 ✓；R-b 每卡键删 `chosen` → `20260928T084050468-28584`（`marks the selected card without rebuilding it`）红 ✓；R-c 去掉 `_hand_place_row` 幂等守卫 → 探针 `build/present-cost/pairs/rc_probe.json`：s1 的 `place_row` 调用 0→1 ✓（判据＝探针计数）；R-e pending 可见性写入丢弃（轻量变异）→ `20260928T090211341-22060`（`keeps the pending draw instance across a local refresh`）红 ✓；R-g 每卡键混入 View 级切片 → key-cost 探针：每卡切片字节 436→8718 起、行键字节 8839／8964／8964／9174 随件数增长 ✗ 判据红 ✓。**未取得**：R-d（`type` 边界）——删边界分支令引擎 signal 11 崩溃（`20260928T084253884-31948`），把键里的 `type` 去掉则数组位置漂移使 E1 断言红（`20260928T084901470-39756`），指定 N2 断言未红；R-f（手牌路径回读 `view.card_texts`）——该变异下 display 套件仍 PASS（`20260928T085130401-36100`），因为 `copy_missing_key_never_crashes` 夹具的缺失记录来自相邻消费者；替代口径：手牌路径的唯一数据构造点由 `_hand_card_data` 单点＋E10 源文本判据覆盖。
- 门禁（本树最终修订，指纹 `026FB832A514C0C3…`；串行，每条跑完 `Get-Process Godot*` = 0）：`-UIOnly -UISuite display,interface,body_layout,card_power,targeting,keyboard,touch,localization,hand_assist,encyclopedia,casting,rewards,services -KeepGoing` → `20260928T090935751-21888`：13／13 PASS、`UI PASS: 3446 assertions`、`status=passed`、`failed=[]`；`-Suite architecture -Impact` → `20260928T092617514-41500`：PASS 4468 断言；`tools/check-docs.ps1` → PASS（36 文档／2592 引用／allowlist 6）；`-Suite runner -VerifyRunner` → `20260928T092652269-2980`：PASS 541 断言＋7 条负例全绿。
- 过程：配对／键成本探针与成对 JSON 只在 `build/`（登记后删除，`build/present-cost/` 与旧侧工作树在收尾时移除）；`*.import`／`*.uid`／`build/` 未入库。一次并发事故（多枚 `run_pairs.sh` 同时存活导致约 10 分钟／次失速）已按串行规则终止，该轮数据作废、不作证据。
- 未跑：`-Suite all` 完整回归；窗口其余分类（route／home／pressure／enemies／guard／baseline／normal_play 等）；安卓真机；打包、标签、推送。

## 2026-09-28｜手牌卡增量刷新：清洁者结构核对与门禁复跑（枝 `worker/hand-refresh`，清洁者）

- 域：`spire-godot/ui/main.gd`（`_hand`／`_hand_presentation_key`／`_hand_key_hit`／`_hand_card_key`／`_hand_card_data`／`_hand_face_slice`／`_hand_apply_card`／`_hand_mount_card`／`_hand_release_card`／`_hand_place_row`／`_hand_row_plan`／`_hand_reset_row`／`_card`／`_refresh_card_face`／`PRESENT_ADJACENCY`）与 `spire-godot/ui/card_face.gd`（原地 setter／`set_mana`／`_write_tags`／`_spare`／`text_overflow`）；契约 `docs/spec/hand-refresh-dependencies.md`／`docs/spec/response-pipeline.md`。只做结构等价改写，未删改任何断言。
- 核对面（`docs/spec/hand-refresh-dependencies.md` 允许改动表）：逐文件对账＝改动面未超表（`ui/main.gd` 各行为允许行；`ui/card_face.gd` 行为新 setter／`set_mana`／池／`_write_tags`；`ui/card_motion.gd` 与 `tests/card_power_ui_cases.gd`／`tests/binding_search_ui_cases.gd`／`tests/body_layout_ui_cases.gd` 仍零改动）；无新增依赖边、无新增公开符号面。
- 单路径核对（邻接表逐边对源）：`_hand`→`_sync_card_faces`／`_hand_presentation_key`／`_hand_key_hit`／`_hand_row_plan`／`_hand_reset_row`／`_hand_apply_card`／`_hand_release_card`／`_hand_mount_card`／`_hand_place_row`；建卡只经 `_hand_mount_card`→`_card`（源文本判据：`CardFace.new()` 只在 `_card`，`_card(` 调用点＝`_display_card`／`_hand_mount_card`，**限 `ui/main.gd`**——`ui/reward_screen.gd`／`ui/departure_screen.gd` 的既有外部调用在判据文件域外）；卡节点销毁只经 `_hand_release_card`（行态节点 `EmptyHand`／`ClimaxNarration` 除外）；行几何只经 `_hand_place_row`；每面值切片只经 `_hand_face_slice`（3 个调用点）；`_hand_cards`／`card_buttons` 的写入点＝挂载／逐卡应用／释放各一处。
- 门禁（`spire-godot/`，`GODOT_BIN` = 4.7.2 `*_console.exe`；串行，每条之间 `Get-Process Godot*` 为空）：`-UIOnly -UISuite display,interface,body_layout,card_power,targeting,keyboard,touch,localization,hand_assist,encyclopedia,casting,rewards,services -KeepGoing -TimeoutSeconds 1800` → `20260928T094132487-33672`：13／13 PASS、`UI PASS: 3446 assertions`、`status=passed`、`before==after=BA1DED3716EEA7DBADD6DFD3B7426F30A41E97B222E85214FD74CC31BF1AD83F`、`failed=[]`、`unrun=[]`、exit 0（计数判据由 `tests/display_ui_cases.gd` 的不放宽断言复核）；`-Suite architecture -Impact -TimeoutSeconds 900` → `20260928T095220916-33896`：`architecture PASS`、4468 断言；`tools/check-docs.ps1` → `DOCS PASS: 36 rule-class document(s), 2594 reference(s) checked, allowlist 6 entrie(s)`（较实现者一轮 +2 引用＝本次新增的 `ui/card_face.gd::_write_tags` 锚）；`-Suite runner -VerifyRunner` → `20260928T095312129-26556`：runner PASS 541 断言＋7 条负例全绿。四条同指纹。
- 清洁者发现、**未动手**（交规划者／协调者裁定）：
  - `ui/card_face.gd::_write_mana` 的非-pressure 分支不写 `node.tooltip_text`；旧 `ui/card_face.gd::set_mana` 在建徽章时写 `_display(entry.detail)`，契约第 34 行也要求复用徽章"只改文本、tooltip、字号、`bg_color`／`border_color`"⇒ 新建徽章无 tooltip、复用徽章保留上一条目的旧 tooltip。可见性受限：徽章 `mouse_filter=IGNORE`，Godot 的 tooltip 命中卡面按钮，故现状不是可见回归；仍属契约与实现不一致。
  - `render` 不清 `_hand_cards`／`_hand_layout`（`plan.md` §6 失效规则 5 的字面要求）；实际由 `button_id` 守卫＋该次 `_hand` 的 added／removed 对账兜底，`response-pipeline.md` 缓存段⑤即按此写。`render` 不在本片允许改动面，故不动。
  - 每次挂载构造同一面切片两次（`_card`→`_refresh_card_face` 一次、`_hand_mount_card` 登记一次），`set_art` 在 `effect_free` 变时取纹理两次：都是被固定签名的 `_refresh_card_face` 与既有 `effect_free` setter 造成的重复取用，实现者补记的运行计数已如实登记，本次不改。
- 未跑：`-Suite all` 完整回归；窗口其余分类（route／home／pressure／enemies／guard／baseline／normal_play 等）；配对耗时与 §G 敏感性矩阵（清洁轮只做结构等价改写，未重跑探针）；安卓真机；打包、标签、推送。

## 2026-09-28｜清洁者五项裁定的落地：徽章 tooltip 修复与登记（枝 `worker/hand-refresh`，清洁者 `0710ded` 之后）

- 域：`ui/card_face.gd::_write_mana`（非 pressure 分支补写／刷新 `tooltip_text`）、`ui/main.gd::_card` 的预合并信号注释、`docs/spec/hand-refresh-dependencies.md`（`_card` 行的信号说明）、`tests/interface_ui_cases.gd`（两条 tooltip 断言）。行为只改一处（新建与复用徽章都写 tooltip）。
- ① **修（真缺陷，本片引入）**：非 `pressure` 分支原先不写 `tooltip_text` ⇒ 新建徽章无 tooltip、复用徽章留着上一条目的旧 tooltip。现两条路径都写／刷新，`tooltip_text == _display(entry[2])`。**断言**：`FACE SETTER set_mana writes every badge tooltip from its entry detail`／`…refreshes a reused badge tooltip`（落 `tests/interface_ui_cases.gd::card_face_incremental`，新建与复用各一条）。**敏感性**：临时去掉该写入 → `20260928T100206216-34068`，两条断言红（`…:  / `、`…: `，即徽章 tooltip 为空／陈旧），已逐字节还原（`git diff --stat ui/card_face.gd` = 2 insertions）。同一次变异跑另有一条**无关邻断**红 `MENU native click opens secondary actions`（干净跑 `20260928T095916021-36092` 该分类 PASS，判为与该变异无关的偶发，记录在案）。
- ② **登记（接受现状）**：`render` 不清 `_hand_cards`／`_hand_layout`。**清表非必需，守卫是机制**：全量路径后成员必为新，`button_id` 守卫使旧条目失效、该次 `_hand` 的增删对账（`removed = (registered ∪ cached) − members`）把离行条目释放；契约⑤即按此写。无需改动。
- ③ **登记为下一刀候选（不在本片修）**：①每次挂载同一面切片被构造两次（`_card`→`_refresh_card_face` 内一次、`_hand_mount_card` 登记一次）；②`set_art` 在 `effect_free` 变时取纹理两次（属性 setter 的 `_art_changed` 一次、`set_art` 的 `_apply_art_texture` 一次）。两者是成本项，与 S3–S5"整手替换略慢"直接相关（见上一节的配对表）；下一刀可让 `_card` 把已构造的切片回传或接受预构造切片。
- ④ **接受并登记**：`chosen`／`modulate` 在手牌路径由 `_refresh_card_face` 与 `_hand_apply_card` 各写一次（值一致、后写覆盖；合并需要改签名，不做）。行为无差。
- ⑤ **接受并写明**：`ui/main.gd::_card` 以 `merged.is_empty()` 作「有没有预合并数据」的信号——契约只允许加一个可选参数，这是唯一可用信号；手牌调用方（`_hand_mount_card`）显式传参，其余调用方不传，不靠默认值或数据形状推断（与计划 A1 同向）。已在 `_card` 处注释与 `docs/spec/hand-refresh-dependencies.md` 的 `_card` 行写明。
- 门禁（`0710ded`＋本次修复，串行、每条后 `Get-Process Godot*` = 0）：`-UIOnly -UISuite display,interface -KeepGoing -TimeoutSeconds 1800` → `20260928T095916021-36092`：`display PASS`＋`interface PASS`，`UI PASS: 1530 assertions`，同一命令内的 docs 阶段 PASS（36 文档／2594 引用／allowlist 6）；`-Suite architecture -Impact` → `20260928T100309545-34216`：`architecture PASS`，4468 断言；`tools/check-docs.ps1` 单跑 → PASS（36 文档／2594 引用／allowlist 6）。
- 未跑：`-Suite all`；UI 其余 11 分类（本刀只改了卡面徽章 tooltip 与两处注释／契约文本，`-UIOnly -UISuite display,interface` 之外的分类未重跑；上一节的全 13 分类跑对应改动前的 `f408238`）；`runner -VerifyRunner`（规则与测试器未改）；安卓真机；打包、标签、推送。

## 2026-09-28｜bunny 双审 FAIL 的逐条处置：悬停详情读当前值、崩溃路径、重挂保面、切片一次构造（枝 `worker/hand-refresh`）

- 域：`ui/main.gd`（`_card` 的悬停／聚焦闭包、`_hand_row_plan`、`_hand_mount_card`、`_hand_apply_card`、`_hand_release_card`、`_hand_key_hit` 与新增 `_hand_node_counts`、`_hand`、`_refresh_card_face`、`PRESENT_ADJACENCY`）、`tests/display_ui_cases.gd`、`docs/spec/hand-refresh-dependencies.md`、`docs/spec/response-pipeline.md`。审查报告：`C:\1\tmp\magic-spire-wt-hand-refresh-review-bunny\spire-godot\build\hand-refresh-review-bunny-report.md`。
- **1.1（阻断，已修）**：`ui/main.gd::_card` 的 `mouse_entered`／`focus_entered` 两条闭包改为按 uid 读当前数据（手牌卡经 `ui/main.gd::_hand_cards[uid].data`，与翻面闭包同一入口；其余调用方仍读构建期 `card`）。**新断言**：`DISPLAY hand refresh keeps the hover detail on the current casting copy`（改 `card_texts[type]` 的 `face_casting`／`casting` 后局部提交、移开再悬停，弹层含 `施法成功率 · 0%`）。**敏感性**：把两条闭包改回快照 `card` → `20260928T105612161-41864` 该断言红（弹层只剩卡名、无新成功率），已还原。契约：`docs/spec/hand-refresh-dependencies.md` 的 `ui/main.gd::_card` 行补授权与信号说明。
- **2.6（崩溃路径，已修）**：`ui/main.gd::_hand_row_plan` 的 `added` 只收 `view.hand` 成员（`broken` 非成员只进 `removed`）；`ui/main.gd::_hand_mount_card` 入口加 `row` 存在性早退。**新断言**：`DISPLAY hand refresh drops a non-member row without mounting it`（夹具造一条指向同一按钮的 `card_ghost` 行）。**敏感性**：同时还原这两处 → `20260928T104607931-36936` 出现 `SCRIPT ERROR: Invalid access to property or key 'card_ghost' …`（即该缺陷的错误形态），已还原。
- **2.7（重挂丢面，已修）**：`ui/main.gd::_hand` 在释放前记下 `plan.broken` 各 uid 的 `card_faces` 值、挂载前回填。**新断言**：`DISPLAY hand refresh keeps the turned face across a same-row release and mount`（E9）与 `…type change keeps the turned face across the rebuild`（N2）。**敏感性**：去掉回填 → `20260928T104159295-27084` 两条断言红；已还原。
- **2.8（清理被跳过，已修）**：`ui/main.gd::_hand_release_card` 的 `candidate_buttons` 清理移出 `button!=null` 守卫。**新断言**：`DISPLAY hand refresh drops the stale candidate entry of a released button`（E9 夹具写入一条指向该按钮的候选键，外部释放后必须消失，且 `candidate_buttons` 全部有效）。**敏感性**：把清理放回守卫 → `20260928T104404419-35480` 该断言红；已还原。
- **2.9（`modulate` 规则变了，已修）**：选择态恢复本片之前的规则（可选中＝纯白，不看 `dim`；不可选中＝0.45；只有非选择态按 `dim`）。记录④措辞改正：`chosen`／`modulate` 各写两次，但**值并不总一致**——选择态由 `ui/main.gd::_hand_apply_card` 决定、非选择态由 `ui/main.gd::_refresh_card_face` 按 `dim` 决定（当前实现选择态覆盖普通态）。**该规则无断言覆盖、靠人审**：选择态 tint 全仓无判别断言（新旧两条规则下套件都绿，本轮最强证据是源码逐分支对照、无敏感性）；已登记下一轮补一条「选择态＋`dim` ⇒ 纯白」断言。
- **2.1（判据 (A)③，已修）**：`ui/main.gd::_refresh_card_face` 新增第 3 个可选参数 `prepared`（预构造面值切片），`ui/main.gd::_hand_mount_card` 构造一次并经 `ui/main.gd::_hand_apply_card` 的 `prepared` 参数交给它；翻面（含翻回）复用 `ui/main.gd::_hand_cards[uid].sides[side]` 的缓存对象。⇒ 每个 (card, side) 的值切片至多构造一次（构造点：`ui/main.gd::_hand_mount_card`／`ui/main.gd::_hand_apply_card` 的缓存缺失分支；`ui/main.gd::_refresh_card_face` 只在未传 `prepared` 时现构造）。**该计数未由测试断言，由构造点枚举＋调用图确立（生产源码禁计数器，本片不新增计时／计数钩子）；它不是门禁证据，判据侧只有 P2 的对象复用断言（`is_same`）**。签名变更由本次审查裁定授权，已同步 `docs/spec/hand-refresh-dependencies.md`（`_refresh_card_face`／`_hand_apply_card`／`_hand_mount_card` 行）与 `docs/spec/response-pipeline.md` 缓存段②；记录里原先"对象复用＝至多构造一次"的措辞按实现改正。
- **2.5（每 uid 全树扫描，已修）**：新增 `ui/main.gd::_hand_node_counts`（一次 `find_children("HandCard_*")` 按名字分组），`ui/main.gd::_hand_key_hit` 与 `ui/main.gd::_hand_row_plan` 改读它；"每 uid 单节点"的守卫语义不变。S3–S5 的 `sections.hand` 未达标归因补上这一条（原先只写了"行键与计划"）。
- **2.2（死条件与注释，已修）**：删掉 `previous!=target`（`applied==side` 时两者恒为同一对象）；注释改为真实行为——值没变的提交仍会走一次组合，零节点写由各 setter 早退达成，判据是零节点增删而非零 setter 调用。
- **2.3（E7 空跑，已改真）**：夹具改为让 View 行的 `draw_serial` 真变（数据部分变、面切片不变），断言指向"行键已移动 + 该卡实例/子树/位置零变化"（`DISPLAY hand refresh moves the row key when only the draw serial changes`）。
- **2.4（E8 恒真，已改真）**：`present` 前记录实例 id 与八个直接子级集合，`present` 后逐项相等＋行键已变。
- **2.10（邻接表，已补）**：`_hand_presentation_key → _hand_card_key`、`_hand_mount_card → _activate_card`（其 lambda，与 `_card` 行同一口径）；另补 `_hand_node_counts`／`_hand_key_hit` 行。
- **P3 记录与可追溯性**：①末节阶段归属改正为"上一节的 13 分类整轮是清洁者的 `20260928T094132487-33672`（`BA1DED37…`）与实现者的 `20260928T090935751-21888`（`026FB832…`），两者都不等于任何已提交树的指纹——属'跑后又有受守卫面的契约／注释编辑'，最终阶段已按指纹独立复核"；②作废运行 `20260928T063931003-28048` 的日志**已随 `build/` 清理删除**，无法回看（登记如实）；未登记过的通过运行 `20260928T092843960-33012`（runner 541 断言、指纹 `026FB832…`）在此补记；③tooltip 敏感性那轮的无关红补全为**两条**：`MENU native click opens secondary actions` 与 `INTERFACE Escape closes focused menu without a turn or save`；④键成本措辞已核为"**时间不随件数增长；字节随两张法术卡的 `face_casting`／`availability` 文本微增（≈+2.9 字节/件），非按件扇出**"（该措辞在上一提交里即已逐字如此，本轮是核对，不是改写）；⑤依赖规约的落地符号已按 `文件::符号` 锚点补写（docs 门禁引用数 2594→2632）。
- 门禁（最终修订，串行、每条后 `Get-Process Godot*` = 0）：`-UIOnly -UISuite display,interface,casting -KeepGoing -TimeoutSeconds 1800` → `20260928T105825255-40644`：3／3 PASS、`UI PASS: 1598 assertions`（display 1082／interface 455／casting 61），同一命令 docs 阶段 PASS；`-Suite architecture -Impact` → `20260928T110126098-40012`：PASS 4468 断言；`tools/check-docs.ps1` 单跑 → PASS（36 文档／2632 引用／allowlist 6）；`-Suite runner -VerifyRunner` → `20260928T110204840-34036`：PASS 541 断言＋7 负例全绿。
- 新增/改真的断言与敏感性一览：悬停当前值 `20260928T105612161-41864`；重挂保面 `20260928T104159295-27084`；候选悬空条目 `20260928T104404419-35480`；非成员幽灵行 `20260928T104607931-36936`（崩溃形态）。上一条记录里较早的敏感性（R-a／R-b／R-c／R-e／R-g）仍有效。
- **登记（本轮不动，下一刀候选）**：
  - **F**：`ui/main.gd::_hand_node_counts` 在守卫未命中路径上仍会扫两遍——`ui/main.gd::_hand_key_hit` 一次、随后 `ui/main.gd::_hand_row_plan` 再一次（命中路径只扫一次）。可让 `_hand` 把这一次扫描的结果随计划传入（或把守卫与计划合并为一次读）。
  - **D2**：选择态 tint 的判别断言（选择态＋`dim` ⇒ 纯白），见上条 2.9 的登记。
  - **G**：`ui/main.gd::PRESENT_ADJACENCY` 的 `"_card"` 行仍缺它经闭包直调的 `_card_tooltip`／`_ignore_mouse` 两条边——**本轮之前就缺、非本轮引入**（该表是手工声明式邻接，无门禁校验；本轮只补了 `_hand` 节内新增的真实边）。
  - 成本项（沿用上一节③）：`ui/card_face.gd::set_art` 在 `effect_free` 变时取纹理两次（属性 setter 的 `ui/card_face.gd::_art_changed` 一次、`set_art` 的 `ui/card_face.gd::_apply_art_texture` 一次）；挂载重复构造切片一项已在本轮按 (A)③ 修掉。
- 未跑：`-Suite all`；UI 其余 10 分类（本刀只动 `ui/main.gd` 的手牌节、`ui/card_face.gd` 未动、`tests/display_ui_cases.gd`；`casting` 已按本次要求纳入）；安卓真机；打包、标签、推送。



## 2026-10-02｜present 邻接表机械判据入表（补记）

- 域：`spire-godot/ui/main.gd::PRESENT_ADJACENCY`、`spire-godot/tests/architecture_cases.gd::present_adjacency_graph_is_pinned`、`.zcode/skills/spire-docs/SKILL.md` 第五类「管线／邻接表」。源码依据 `5ed785f`。
- 判据三条：声明边必须在父体内有直调；表内符号被已登记父直调必须登记；无死项（无幻符、无孤儿、无不可达）。判据外读跨文件父体仅 `header.configure`（其子 `header._presentation_key`）；外部边界 `layout.hero_portrait`／`layout.body_sidebar`／`configure_enemy`／`EquipmentPortrait.configure` 按属主文件存在性核对。无产品行为改动。
- 运行（冻结于 `5ed785f`，前后指纹同为 `5574F0AE0269E10D61409FCFE4633474EB1302D11610A27E4FCC373395A80192`）：`20261002T080030763-14100`（architecture PASS 4474）、`20261002T080116217-42532`（runner PASS 541）。敏感性运行号：`20261002T075112837-53504`、`20261002T075208309-53512`、`20261002T075357601-30736`、`20261002T075500112-34832`、`20261002T075629416-5340`（照录）。`20261002T075722327-28468` 是 `-Import` 轮、指纹 `79B8D5CA948F680B260A77D21F4F7FC4198229FE8EB222DE9A49114813A5C897` 不等，不作冻结证据。
- 双审（muse／bunny）均 PASS；三条应修在本批落地：①补本记录；②`_intent_icon_rect`／`_attack_drop_candidate`／`_items_drawer` 由仅作子改为各自 `[]` 行，表头写明「每个被声明的符号都必须有行」；③判据只校验已声明边，不拦新增节例程／删整行／整表掏空，评估后采 ②：在表头与 `spire-docs` 第五类写死覆盖边界（由评审负责），并登记完整性下限为后续项（`docs/record/proposals/present-adjacency-completeness-floor.md`）。评估依据：候选下限「已登记父在 `ui/main.gd` 的每个直调须入表或成子」实测牵出 80 个本地例程，仅 9 个在现有不入表名单（`_label`/`_place`/`_panel`/`_button`/`_style`/`_bar`/`_scroll`/`_text`/`_localize_controls`）内，余 71 个为构建／域例程（`render` 单独约 20 个），非小而稳定，故不设。
- 本批增量复跑（新源码，前后指纹同为 `07EA7583B5ADBF08455CDD690DC575E611288EEA5578071B49E010648F05233E`）：`20261002T144103826-55716`（architecture PASS 4474）、`20261002T144147595-43320`（runner PASS 541，含 `-VerifyRunner` 六项负例探针）、`tools/check-docs.ps1`（35 规则文档 2521 引用，PASS）；exit 0。
- 失败：无。未验证：`-Suite all` 完整回归、窗口其余分类、安卓真机、打包与发布。


## 2026-10-05｜PR #12／#13 集成：手牌增量刷新与管线声明校验

- 基线 main `8e83876`；PR #12头部`255f1dd`（手牌增量刷新）、PR #13头部`8544275`（邻接表机械判据）。整合在独立工作树，版本保持0.18.2.fix；本批仅合并源码与推送，不打包、打标签或发布Release。旧#1／#3未有新更新，不纳入本批。
- 文本冲突：双侧验证记录全部保留；邻接行同时保留手牌窄键调用与行动栏render调用。交叉兼容：共享手牌辅助函数进入表后，补14个子符号行、52条已登记符号间真实直调边，测试属主表登记CardFace；不削弱判据、不更改产品规则。同步表头与依赖表，移除作者机器临时计划路径作为当前契约入口。
- 首轮`20261004T143429807-41832`：architecture两条失败（漏边、CardFace属主），runner及composites通过；问题修复后完整原范围`tools/check.ps1 -Suite architecture,runner,composites -KeepGoing -TimeoutSeconds 300`，`20261004T143619057-40756`，5111断言PASS（4474／541／96），exit0、before==after。
- 窗口：`tools/check.ps1 -UIOnly -UISuite display,interface,body_layout,card_power,targeting,keyboard,touch,localization,hand_assist,encyclopedia,casting,rewards,services -KeepGoing -TimeoutSeconds 900`，`20261004T143709729-40404`，13分类3469断言PASS，exit0、before==after，628.78秒。最后仅修改表头注释和依赖说明，产品实现及UI测试未变，复用这份行为证据。
- 最后文字修改后：`tools/check.ps1 -Suite architecture -TimeoutSeconds 300`，`20261004T144807111-41016`，4474断言PASS，exit0、before==after；文档门禁36文件2688引用通过。实际执行日志按UTC日期命名，用户侧日期为2026-10-05。
- 独立审查`review_pr12_pr13`（Astra low，只读）完成本批审查及定点返修复核，已提出问题全部关闭。未重跑测试器负例：运行器实现未变；未跑全量规则、其余UI、性能基准、人工试玩、安卓真机与打包。
- 主检出原有102个未提交文件另行逐字节备份于准备树`spire-godot/build/pr12-pr13-20261005/local-backup/`及`local-manifest.json`；本次推送不夹带这些在途修改。恢复它们时对重叠文件三方合并，局部适配及验证另记主检出本地记录。

## 2026-10-05｜手牌就地刷新的确定性 SIGSEGV：内容槽标签不得回插 Content（枝 `fix/hand-refresh-crash`，实现者）

- 域：`ui/card_face.gd::_content_slot`（内容槽 `CardClassification`／`CardEffect`／`CardWarning`／`CardAvailability` 不再池化）、`tests/interface_ui_cases.gd::card_face_incremental`（新增 4 条断言）、`docs/spec/hand-refresh-dependencies.md`（`ui/card_face.gd` 行与自检清单）。改动面：`ui/card_face.gd` +12/−10、`tests/interface_ui_cases.gd` +13。
- **缺陷与点名**：PR #12 头 `255f1dd` 上，配方（`<引擎> --path . --script res://build/fact-kinds/driver.gd -- --seeds=7 --cap=60 --style=trade --control=1`）在第 40 次提交后于延迟阶段 SIGSEGV（exit 139）；栈顶逐帧一致（`main+40d4d61`／`3b2b734`／`3e0f4aa`／`3e1082a`／`3b2b296`／`2407de2`），`--verbose` 无 GDScript 报错。以 `FileAccess.flush()` 面包屑（`fit_text`／`_request_fit`／`_park`／`_take`／`_content_slot`／`_exit_tree`／`_hand_*`／相位／draw 标记；跑后全部还原）点名：最后落盘的一行始终是本帧延迟刷新里的 `fit_exit`／`draw`（`CardMotion_play_card_12` 与幸存手牌），`is_inside_tree`／`is_queued_for_deletion` 探针 0 命中 ⇒ H1（延迟 fit 落在已出树／已拆除节点）不成立；`_hand_place_row` 的 `size` 写确实触发 `resized→fit_text` 同步重入（探针 137 次），但把 `resized` 改接延迟 `_request_fit` 后崩溃只是位移到第 39 次提交 ⇒ H2 也不是根因。
- **定位（消融矩阵）**：`fit_text` 整体空转 → 会话 60/60、进程退出仍 139；只停 `fit_text` 末尾字号覆写循环 → 同样 60/60＋退出 139；**只停内容槽池化**（清空即 `remove_child`＋`queue_free`、取用不复用）→ **60/60、exit 0**；词条／条件／魔力徽章保留原池 → 仍全绿；把内容槽改入**在树**隐藏 holder 再回插 → 仍崩 ⇒ 触发条件不是"出树"，而是**把已移除的内容标签重新插入 ScrollContainer 的 `Content`**。对照反汇编（`pefile`＋`capstone`，引擎官方 exe；控制台 exe 只是启动器）：崩溃栈＝`ObjectDB::get_instance` ← `core/object/message_queue.cpp` push 助手 ← `CallQueue::push_callablep` ← `CanvasItem::queue_redraw`（延迟调用入队阶段）。引擎侧最终机理**未确证**（`_flush_delete_queue` 对空对象直接 `memdelete` 而 `predelete_handler` 无空指针守卫，与"重复入删除队列＝双重删除"形态一致，未取到直接证据）。
- **修（最小面）**：`ui/card_face.gd::_content_slot` 的槽位清空路径由 `_park`（出树入池）改为 `remove_child`＋`queue_free`，取用路径不再 `_take`、直接新建；`_spare` 池只保留给词条／条件／魔力三类组。三类池的**回插**目标是卡面直属的 `CardKeywords`／`CardRequirements`／`CardMana`，不是 `CardText/Content`；**这不构成安全性证明**：`ui/encyclopedia.gd`／`ui/deck_browser.gd`／`ui/departure_screen.gd` 会把整张卡面放进 `ScrollContainer` 子树，三类池的复用在这三屏的滚动子树内**未证**（"回插目标不是 `Content`"不等于"回插目标不在滚动子树内"；残余风险与待验实验 E2 见下）。可见差异仅"槽位清空后再出现"的内容标签被重建；在树实例集合与既有断言口径不变（`docs/spec/hand-refresh-dependencies.md` 的 `ui/card_face.gd` 行与自检清单已同批改写）。
- **修复后配方**（同树，串行，起前 `Get-Process Godot*` 为空）：两次均 `FK SESSION seed7-trade commits=60 steps=60`＋`UI PASS: 65 assertions`＋exit 0＋无 SIGSEGV（`build/fact-kinds/fix-run1.log`／`fix-run2.log`）；对照好树 `ec60197` 同配方 exit 0。`--headless` 同配方**跑不了**：驱动在首个 `t.frames()` 卡在 `await RenderingServer.frame_post_draw`（headless 不触发），修复前后同样 0 提交、无崩溃（150 s 手动终止，`build/fact-kinds/fix-headless.log`）⇒ headless 不是本崩溃的可用复现路径，也不能由它判定修复。
- **回归测试（新增 4 条＋敏感性）**：`tests/interface_ui_cases.gd::card_face_incremental` 新增"清空即销毁、不留在卡内；再次出现必是新实例、绝不回插滚动容器"（警告／可用性各两条；既有断言不删不改）。**敏感性**：还原修复、保留新断言跑 `-UIOnly -UISuite interface` → `20261005T013813375-20316`，4 条全红；修复态同命令 `interface PASS`（见下）。
- **门禁**（本树最终修订，`GODOT_BIN`＝4.7.2 `*_console.exe`；串行，每条前 `Get-Process Godot*` 为空）：
  - `-UIOnly -UISuite display,interface,body_layout,card_power,targeting,keyboard,touch,localization,hand_assist,encyclopedia -KeepGoing -TimeoutSeconds 3600` → `20261005T012712927-10576`：10／10 `SUITE RESULT: <name> PASS`、`UI PASS: 2765 assertions`、`status=passed`、`before==after=94D2EDD40F5973DAC1B1D1525EDF65550A930CEB69B5673AE001FC042AAD8345`、`failed=[]`、`unrun=[]`、同命令 docs 阶段 PASS。
  - `-Suite architecture -TimeoutSeconds 1800` → `20261005T013701946-29700`：`SUITE RESULT: architecture PASS`、4468 断言、`status=passed`、同指纹、docs 阶段 PASS。
  - `tools/check-docs.ps1` 单跑 → `DOCS PASS: 36 rule-class document(s), 2655 reference(s) checked, allowlist 6 entrie(s)`。
  - 首轮同命令曾 `encyclopedia` 红两条 `ART INSPECT native-mode inner dark area dismisses art`／`ART INSPECT touch on inner dark area closes only art`（`20261005T010756541-1344`，9／10，2 条 engine error）；单分类 `-RerunFailed` → `20261005T012626373-28120` `encyclopedia PASS`（248 断言），随后整轮复跑 10／10 全绿 ⇒ 判为与本刀无关的偶发（本刀未触及 `ui/art_inspection.gd`／encyclopedia 用例，且复跑不重现）。
- 提交后复跑（最终态）：`-UIOnly -UISuite interface` → `20261005T014155464-25992`，`interface PASS`、473 断言（敏感性检查先还原修复、后按补丁恢复；此跑确认提交内容与门禁内容一致）。
- **第二轮（审计裁定收口，2026-10-05，同枝 `fix/hand-refresh-crash`）**：
  - **E1（独立最小驱动，只放 `build/`）**：`build/scroll-repro/scroll_repro.gd`——场景仅 1 个 `ScrollContainer`＋1 个 `VBoxContainer`（充当 `Content`）＋每轮 1 个 `Label`；窗口态、显式 4.7.2 `*_console.exe`、同一时间只跑一个引擎进程。三轮全部 exit 0：`reinsert`（add→remove→**同实例回插**→`queue_free`，60 轮）、`control`（不回插）、`reinsert_fit`（回插＋一次延迟 fit 式写入：字号覆写／`get_combined_minimum_size`／尺寸写／`queue_redraw`）。日志尾均带 `exit=<code>`（`build/scroll-repro/reinsert.log`／`control.log`／`reinsert_fit.log`）。**判定**（只否定充分性、不是安全性结论）："把曾被移除的 Control 回插进 ScrollContainer 子树"这一形态本身**不足以复现** SIGSEGV——触发需要游戏侧上下文（主题覆写／延迟 fit／消息队列时序）；**E1 没有证明该形态安全，更没有证明三类池的复用安全**（三类池的回插目标在图鉴／牌库／离狱三屏内确实落在 `ScrollContainer` 子树中，本轮已承认原"三类组不在滚动子树内"的前提在这三屏不成立），引擎最终机理仍未确证 ⇒ B 的范围决定＝**未证、待 E2**：修复范围暂不扩，残余风险保持登记（见下 B 条）。最终态复跑三轮（`*-rerun.log`）同为 exit 0。
  - **B（范围与残余风险）**：词条／条件／魔力三类池维持复用；其回插目标是 `CardKeywords`／`CardRequirements`／`CardMana`，不是 `Content`（`CardText/Content` 的唯一写入者仍是 `_content_slot`，且已无回插路径）。**这是"暂不扩范围"的决定，不是"已证安全"**：E1 只否定"回插本身足以复现"（否定充分性），三类池在图鉴／牌库／离狱滚动子树内是否同样触发**未证**（同时也未证其安全）。**登记残余风险＋待验实验 E2**：机理未确证，不能排除同形态在别的组合触发；E2＝在配方里加"图鉴／牌库翻面 N 次"段（或临时把三类池也改成清空即销毁）跑同配方＋`encyclopedia`／`display` 分类，本轮**未做**。
  - **C（文档与判据收口）**：`docs/spec/hand-refresh-dependencies.md` 的三处矛盾统一为"内容差额（条件内容标签跨空边界）触发的该标签销毁／新建允许；值变／重排不得增删实例"；允许改动行删除"四个内容槽清空即 `remove_child`＋`queue_free`"的不实描述（条件槽 `CardWarning`／`CardAvailability` 清空即销毁、需要时新建；常驻槽 `CardClassification`／`CardEffect` 只切 `visible`）；禁止项加内容差额例外；自检清单与翻面承诺按同一口径改写——翻面零增删收窄为"起点面没有一面独有的条件内容标签（或两面都有）的往返"。
  - **C4 可达夹具＋敏感性**：`tests/display_ui_cases.gd::present_hand_incremental` 新增 P4 段（单面可用性真→假→真：出现／同占用改值／销毁／重建；跨面往返：起点面独有该标签）＋辅助 `present_hand_usable`／`present_hand_delta`；翻面夹具改为按上述前提挑选并断言前提。修复态 `-UIOnly -UISuite display` → `20261005T021549640-18964`（1096 断言、PASS）；敏感性（临时还原 `_park` 池化实现、其余不变）→ `20261005T021819234-22308`：3 条新断言红（`DISPLAY hand refresh clearing the availability drops that instance`／`rebuilds the availability line instead of re-inserting the freed instance`／`flipping back rebuilds the line instead of re-inserting it`），随后已恢复修复态（`git checkout -- ui/card_face.gd`）。
  - **E4／5a 带内退出码与已知 139 对照**：配方三次与 E1 六次都经同一捕获（`Start-Process -Wait -PassThru` 的 `ExitCode` 追加为日志末行 `exit=<code>`）。对照：**临时还原 `255f1dd` 的 `ui/card_face.gd`** 跑同配方 → `round2-old-139.log`＝第 39 次提交后 `Program crashed with signal 11`、`exit=-1073741819`（0xC0000005，Windows 下的 SIGSEGV 形态；增量快照 `commits=39`）；恢复修复态后两跑 → `round2-fix-run1.log`／`round2-fix-run2.log`＝`FK SESSION seed7-trade commits=60 steps=60 stop=cap`＋`UI PASS: 65 assertions`＋`exit=0`。汇总索引（命令／日志／退出码）＝`build/fact-kinds/round2-index.json`。
  - **门禁（第二轮，`GODOT_BIN`＝4.7.2 `*_console.exe`，串行，跑前无 Godot 进程）**：`-UIOnly -UISuite display,interface,body_layout,card_power,targeting,keyboard,touch,localization,hand_assist,encyclopedia -KeepGoing -TimeoutSeconds 3600` → `20261005T022533651-17988`：10／10 `SUITE RESULT: <name> PASS`、`UI PASS: 2779 assertions`、`status=passed`、`before==after=E3BC88B01AF8B709AD6A126EAA01BEC05F250D6E22DDED8DE3A59DF7CB4C4E22`、`failed=[]`、`unrun=[]`、无 `SOURCE CHANGED`、docs 阶段 PASS（36 文档／2658 引用／允许清单 6）。`-Suite architecture` → `20261005T030021859-26500`：`SUITE RESULT: architecture PASS`、4468 断言、`status=passed`、同指纹、docs 阶段 PASS。`tools/check-docs.ps1` 单跑 → `DOCS PASS: 36 rule-class document(s), 2658 reference(s) checked, allowlist 6 entrie(s)`。（指纹由上一轮的 `94D2EDD4…` 变为 `E3BC88B0…`，与 `docs/spec/hand-refresh-dependencies.md` 的契约修订一致。）
  - **超时轮（补登，不作证据）**：第二轮收尾在 `d624360` 提交后跑 `-UIOnly -UISuite display`（同最终指纹 `E3BC88B0…`）→ `20261005T030601404-12088`：`SUITE START: display` 后**无任何断言输出**，被 `Godot check exceeded 300s` 记为 `status=failed`（该轮 docs 阶段 PASS）；**不作证据**（没有判定任何断言），随后同范围同指纹 `20261005T031124951-26928` → `SUITE RESULT: display PASS`＋`UI PASS: 1096 assertions`＋`UI TIME: 119392 ms`＋`status=passed`＋`before==after=E3BC88B0…`（119 s 通过）。
- **第三轮（bunny FAIL 收口，2026-10-05，同枝 `fix/hand-refresh-crash`，`d624360` 之上）**：
  - **① 未证写成未证（[应修]）**：原"修复范围不扩"的理由用了"三类组不在滚动子树内"，该前提在图鉴／牌库／离狱三屏**不成立**（三屏都把整张卡面放进 `ScrollContainer` 子树）；两处原句**就地在原条目改写、不留更正段**——原句一在**本条第一轮**"**修（最小面）**"段，原句二在**本条第二轮 `E1`** 段（两处都在本 2026-10-05 条内，未动更早的历史条目）。原句一："三类池的**回插**目标是卡面直属的 `CardKeywords`／`CardRequirements`／`CardMana`（不在滚动子树内），但**不等于这些卡面不承载滚动**……"→ 现句一："……不是 `CardText/Content`；**这不构成安全性证明**：……三类池的复用在这三屏的滚动子树内**未证**（"回插目标不是 `Content`"不等于"回插目标不在滚动子树内"）……"。原句二："**判定（绿）**：……引擎最终机理仍未确证 ⇒ B 取"修复范围不扩"分支。"→ 现句二："**判定**（只否定充分性、不是安全性结论）：……**E1 没有证明该形态安全，更没有证明三类池的复用安全**（三类池的回插目标在图鉴／牌库／离狱三屏内确实落在 `ScrollContainer` 子树中）……⇒ B 的范围决定＝**未证、待 E2**：修复范围暂不扩，残余风险保持登记"。B 条同口径补"**这是"暂不扩范围"的决定，不是"已证安全"**"；`docs/record/changelog.md` 同段"（B 绿分支）"改为"（B 范围暂不扩＝**未证、待 E2**）"、"本身不足以复现 SIGSEGV"后补"（**E1 只否定充分性、未证安全性**）"。
  - **② 超时轮（[存疑]，补登）**：已按第一轮"无关偶发红也写进正文"的实践补进上列一行（"超时轮（补登，不作证据）"）：`20261005T030601404-12088` 无断言输出、超时记 failed、**不作证据**；同范围同指纹 `20261005T031124951-26928` 119 s 通过。
  - **③ 带内身份（日志↔代码版本当轮自证）**：配方与 E1 的 runner（`build/fact-kinds/run-round2.ps1`／`build/scroll-repro/run.ps1`，只在 `build/`、不入库）改为在日志头写 `RUN IDENTITY`：`head=<git rev-parse HEAD>`、`started=<本地时间>`、`card_face.gd sha256=<…>` 与各自载入驱动的哈希（`driver.gd`／`scroll_repro.gd`）；引擎输出随后、`exit=<code>` 仍为末行。首版 `"键=" + 值,` 写法在 PowerShell 下被**逗号优先级**吞并（解析成 `"键=" + （值, 下一元素）`，日志头断行），该首跑日志已弃、不作证据；改为 `"键=$(…)"` 插值并复验（见下身份头）。
  - **④ 残留注释同步**：`ui/card_face.gd::_content_slot` 的"只保留给词条／条件／魔力这些不承载滚动的组"与事实不符，改为"……三类组：它们的回插目标不是 `Content`，但这不证明安全——卡面会被放进 ScrollContainer 子树（图鉴／牌库／离狱），该复用仍属未证（待 E2）"；同段"引擎会在随后的提交里于延迟阶段崩溃"收窄为"配方里……必崩、停用该池化即消失（E1 表明该形态单独不足以复现；机理未确证）"。**产品文件改动 ⇒ 受影响域门禁已重取（见下）**。
  - **验证（第三轮，`GODOT_BIN`＝4.7.2 `*_console.exe`，串行，跑前跑后无 Godot 进程）**：配方（修复态、windowed、1 次）`build/fact-kinds/round3-fix-run1.log`＝身份头 `head=d62436085dec5f1188fbd922a84f0d9bf2ec0f67`＋`card_face.gd sha256=9FB2161DF2B3675EF6933B10C7537F33357D214EC9A1879C607FCD45B232CFBB`＋`driver.gd sha256=FCECA14A3B99DF2D95853B823561059BF2905B7B3E4C33B2CD8049A36F4600E9`、正文 `FK SESSION seed7-trade commits=60 steps=60 stop=cap`、`UI PASS: 65 assertions`、末行 `exit=0`（out `build/fact-kinds/round3-fix1/`）。E1 runner 冒烟一次（`reinsert`，60 轮）`build/scroll-repro/round3-reinsert.log`＝同形身份头＋`SR DONE variant=reinsert rounds=60`＋`exit=0`。`-UIOnly -UISuite display,interface,body_layout,card_power,targeting,keyboard,touch,localization,hand_assist,encyclopedia -KeepGoing -TimeoutSeconds 3600` → `20261005T040331976-24876`：10／10 `SUITE RESULT: <name> PASS`、`UI PASS: 2779 assertions`、`UI TIME: 479778 ms`、`status=passed`、`before==after=41B216A6475422DF50EB4560A3210BA831AF40FB64264FF32A310AE7DBCF3829`、`failed=[]`、`unrun=[]`、无 `SOURCE CHANGED`、docs 阶段 PASS（36 文档／2658 引用／允许清单 6）、exit 0。`-Suite architecture` → `20261005T041145032-24876`：`SUITE RESULT: architecture PASS`、4468 断言、`status=passed`、同指纹、docs 阶段 PASS、exit 0。`tools/check-docs.ps1` 单跑 → `DOCS PASS: 36 rule-class document(s), 2658 reference(s) checked, allowlist 6 entrie(s)`、exit 0。（指纹由 `E3BC88B0…` 变为 `41B216A6…`＝`ui/card_face.gd` 注释改写；引用数不变。）
  - 未跑（第三轮）：`-Suite all` 完整回归；UI 其余窗口分类（route／home／pressure／enemies／guard／baseline／normal_play 等）；`-Suite runner -VerifyRunner`（规则与测试器未改）；**E2（三类池在图鉴／牌库／离狱滚动子树内的翻面压力）**；安卓真机；打包、标签、推送。
- **第四轮（复核 FAIL 终态收口，2026-10-05，同枝 `fix/hand-refresh-crash`，`e85f21b` 之上）**：
  - **C1（[应修] 自检清单翻面条句自相矛盾）**：`docs/spec/hand-refresh-dependencies.md` 自检清单的翻面条目里 (a)"起点面没有该标签（或两面都有，标签存活）的往返零增删"与 (b)"起点面独有该标签的往返（如一面可用、另一面不可用）只许该标签销毁后新建"对"一面可用、另一面不可用"给出相反判据（该情形同时落进两句；实现与 `tests/display_ui_cases.gd::present_hand_incremental` 的 P4 跨面夹具证明它不是零增删）。现 (a) 改为"起点面没有**一面独有的**条件内容标签（两面都没有，或两面都有且存活）的往返零增删"（两面占用一致；与第二轮既有口径"起点面没有一面独有的条件内容标签（或两面都有）"同一判据，此处把两个允许情形写出），(b) 不动；两句不再交叉，被取代句就地改写、不留更正段（提交 `e85f21b`，与 C6 同批）。
  - **C4（[存疑] 带内身份与脏标志）**：两个 runner（`build/fact-kinds/run-round2.ps1`／`build/scroll-repro/run.ps1`，只在 `build/`、不入库）的身份头追加 `dirty=<porcelain 条目数> dirty_sha256=<porcelain 摘要>`（干净树＝`dirty=0`＋空串摘要 `E3B0C442…`）。**139 对照已用新头重跑**：临时还原 `255f1dd` 的 `ui/card_face.gd`（sha256 `F3D7C194…`）→ `build/fact-kinds/round4-old-139.log`＝`head=e85f21b`＋`dirty=1 dirty_sha256=D0C308B5…`＋`card_face.gd sha256=F3D7C194…`，`FK step 40` 决定落盘后崩溃（无 `FK SESSION … commits=` 收尾行）、`Program crashed with signal 11`、`exit=-1073741819`（0xC0000005）；随后 `git checkout -- ui/card_face.gd` 还原（sha256 回 `9FB2161D…`、`git status --short` 空）。**旧对照缺带内身份**（第二轮 `round2-old-139.log` 连身份头都没有；第三轮 `round3-fix-run1.log` 的 `head=d624360` 配 `card_face.gd sha256=9FB2161D…`＝`8afb6c7` 字节，头里没有脏标志，不能自证是同一次未提交状态）⇒ 本轮的 `round4-old-139.log` 取代其对照证据地位（首次做到"日志自证跑在未提交的旧字节上"）。
  - **C6（[存疑] 记录措辞精确化）**：第三轮 ① 原写"第二轮条目**就地改写、不留更正段**"，实际被改写的是**本条第一轮**"**修（最小面）**"段的原句一与**本条第二轮 `E1`** 段的原句二（都在本 2026-10-05 条内、未动更早历史条目）；该句已就地改为点名两处位置（见上）。
  - **C2（终态门禁，`GODOT_BIN`＝4.7.2 `*_console.exe`，串行，跑前跑后无 Godot 进程）**：C1／C6 提交后、在 `e85f21b` 的干净树上重取，终态指纹 `55B243EAFD73DB27D81188D55C5150B7A130BF6571488AF324B43AC2CDE6DCF3`（`41B216A6…` → `55B243EA…`＝C1 的 `docs/spec` 改写，rule-class 在指纹内）。`-UIOnly -UISuite display,interface,body_layout,card_power,targeting,keyboard,touch,localization,hand_assist,encyclopedia -KeepGoing -TimeoutSeconds 3600` → `20261005T043212699-3020`：10／10 `SUITE RESULT: <name> PASS`、`UI PASS: 2779 assertions`、`UI TIME: 475791 ms`、`status=passed`、`before==after=55B243EA…`、`failed=[]`、`unrun=[]`、无 `SOURCE CHANGED`、docs 阶段 PASS（36 文档／2658 引用／允许清单 6）、exit 0。`-Suite architecture` → `20261005T044022148-3020`：`SUITE RESULT: architecture PASS`、4468 断言、`status=passed`、同指纹、docs 阶段 PASS、exit 0。`tools/check-docs.ps1` 单跑 → `DOCS PASS: 36 rule-class document(s), 2658 reference(s) checked, allowlist 6 entrie(s)`、exit 0。**先前轮次的来源关系**：第三轮 UI `20261005T040331976-24876`（`41B216A6…`）跑在 `d624360` 之后的树上——其配置含当时尚未提交的 `ui/card_face.gd` 注释改写（随后提交为 `8afb6c7`），与终态之间还隔着 `743b425` 的 `docs/spec` 一句与本轮 C1 的改写；该旧日志没有脏标志，**不能自证当时的树是否已含这两句**（正是 C4 的缺口），本轮已按推荐在终态重跑 UI 十模块，不再依赖旧轮；第二轮 UI `20261005T022533651-17988`（`E3BC88B0…`）更早，其与终态之间还隔着 `d624360` 的契约与夹具。本条记录提交只改 `docs/record`（不在指纹内、记录只追加），不改变上述终态指纹。
  - **配方复核（修复态、windowed、1 次）**：`build/fact-kinds/round4-fix-run1.log`＝身份头 `head=e85f21bc9b0507e74ae9d35fa7421a824bcf8e3e`＋`dirty=0 dirty_sha256=E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`＋`card_face.gd sha256=9FB2161DF2B3675EF6933B10C7537F33357D214EC9A1879C607FCD45B232CFBB`＋`driver.gd sha256=FCECA14A3B99DF2D95853B823561059BF2905B7B3E4C33B2CD8049A36F4600E9`、正文 `FK SESSION seed7-trade commits=60 steps=60 stop=cap`、`UI PASS: 65 assertions`、末行 `exit=0`（out `build/fact-kinds/round4-fix1/`）。E1 runner 冒烟一次（`reinsert`，60 轮）`build/scroll-repro/round4-reinsert.log`＝同形身份头（含 `dirty=0`）＋`SR DONE variant=reinsert rounds=60`＋`exit=0`（两跑都在 `e85f21b`；本条记录提交只加 `docs/record`）。
  - 未跑（第四轮）：`-Suite all` 完整回归；UI 其余窗口分类（route／home／pressure／enemies／guard／baseline／normal_play 等）；`-Suite runner -VerifyRunner`（规则与测试器未改）；**E2（三类池在图鉴／牌库／离狱滚动子树内的翻面压力）**；安卓真机；打包、标签、推送。
- 证据位置：本轮日志都在临时工作树 `C:\1\tmp\magic-spire-wt-hand-fix\spire-godot\build\`（`checks/<运行号>`、`fact-kinds/fix-run1.log`／`fix-run2.log`／`fix-headless.log`；第二轮 `fact-kinds/round2-*.log`／`round2-index.json`／`round2-old|fix1|fix2/`、`scroll-repro/*.log`；第三轮 `fact-kinds/round3-fix-run1.log`／`round3-fix1/`、`scroll-repro/round3-reinsert.log`、`checks/20261005T040331976-24876`／`20261005T041145032-24876`；第四轮 `fact-kinds/round4-old-139.log`／`round4-old/`／`round4-fix-run1.log`／`round4-fix1/`、`scroll-repro/round4-reinsert.log`、`checks/20261005T043212699-3020`／`20261005T044022148-3020`）；工作树拆除后随树删除，运行号可按上列字符串核对当时命令。
- 未跑：`-Suite all` 完整回归；UI 其余窗口分类（route／home／pressure／enemies／guard／baseline／normal_play 等）；`-Suite runner -VerifyRunner`（规则与测试器未改）；安卓真机；打包、标签、推送；**E2（三类池在图鉴／牌库／离狱滚动子树内的翻面压力）**。面包屑／探针只在 `build/` 与本树临时文件，已回退（`git diff` 仅 `docs/spec/hand-refresh-dependencies.md`／`docs/record/verification.md`／`docs/record/changelog.md` 与 `tests/display_ui_cases.gd`；第三轮另含 `ui/card_face.gd::_content_slot` 的注释改写，无行为差异；第四轮产品代码零改动——`ui/card_face.gd` 与修复态 `9FB2161D…` 一致，提交只有 `docs/spec` 的判据句与 `docs/record` 台账）。

## 2026-10-05｜手牌崩溃修复重放到合并后的 main：重放证据（枝 `fix/hand-refresh-crash-on-main` @ `2d033a6`，实现者）

- 域：`ui/card_face.gd::_content_slot`（内容槽标签不池化修复）＋ `tests/display_ui_cases.gd::present_hand_incremental`／`tests/interface_ui_cases.gd::card_face_incremental`（判据）＋ `docs/spec/hand-refresh-dependencies.md` 与 `docs/record/*`（依赖表与记录）。枝 `fix/hand-refresh-crash-on-main` @ `2d033a6`（base＝合并提交 `6ac813f`）；来源＝源线 `cbb002d..bece4ed`（含两端共 6 个提交）的 `cherry-pick -x`，逐条映射 `cbb002d→c7838ca`／`d624360→bf4585f`／`8afb6c7→23d084c`／`743b425→0e4ce14`／`e85f21b→c267557`／`bece4ed→2d033a6`（6 个提交体都带 `(cherry picked from commit …)` trailer）。本轮只补登重放证据、不改源码。
- 命令与结果（同机串行；配方 windowed；`GODOT_BIN`＝4.7.2 `*_console.exe`）：
  - ① 配方（`<引擎> --path . --script res://build/fact-kinds/driver.gd -- --seeds=7 --cap=60 --style=trade --control=1`）两跑：均 `FK SESSION seed7-trade commits=60 steps=60 stop=cap`＋`UI PASS: 65 assertions`＋末行 `exit=0`＋无 signal 11（`build/fact-kinds/fixonmain-run1.log`／`fixonmain-run2.log`）；身份头两跑同为 `head=2d033a6d02d1a4786341bc8bdf0b5faba00859b8`＋`dirty=0 dirty_sha256=E3B0C442…`＋`card_face.gd sha256=9FB2161DF2B3675EF6933B10C7537F33357D214EC9A1879C607FCD45B232CFBB`＋`driver.gd sha256=FCECA14A…`。
  - ② `& tools/check.ps1 -UIOnly -UISuite display,interface,body_layout,card_power,targeting,keyboard,touch,localization,hand_assist,encyclopedia -KeepGoing -TimeoutSeconds 3600` → `20261005T094721686-32312`：10／10 `SUITE RESULT: <name> PASS`、`UI PASS: 2779 assertions`、`status=passed`、`before==after=8E2C451C336163FDDD034FD1C92956968569FB4ED446A5F5F3930913DD24D7F2`、`failed=[]`、`unrun=[]`、同命令 docs 阶段 PASS（36 文档／2695 引用／允许清单 6）、exit 0。
  - ③ `& tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` → `20261005T095533175-5864`：`SUITE RESULT: architecture PASS`、`PASS: 4474 assertions`、`status=passed`、同指纹、docs 阶段 PASS、exit 0。（main 侧含 PR #13 的邻接表判据，断言数 4474 与源线的 4468 不同。）
  - ④ `& tools/check-docs.ps1` 单跑 → `DOCS PASS: 36 rule-class document(s), 2695 reference(s) checked, allowlist 6 entrie(s)`、exit 0（不占引擎；本条记录当轮补跑，结论与 ②③ 内的 docs 阶段一致）。
  - 不作证据轮：`20261005T093130506-34704`——`localization` 52 断言 PASS 后自 `SUITE START: card_power` 起约 13 分钟无任何输出（`check-ui.log` 末行停在 `SUITE START: card_power`），人工终止；`status=failed`（summary 的 `error`＝`check-ui.log` 正被另一进程占用），`card_power` 无断言输出、其余 8 分类 `unrun` ⇒ **不作证据**（该轮的 docs 阶段本身 PASS）。
- 对照（未修复态、合并后的 main）：`6ac813f` 干净树同配方两跑均 `exit=-1073741819`＋`CrashHandlerException: Program crashed with signal 11`（`FK step 40` 决定落盘后即无 `FK SESSION … commits=` 收尾行；身份头 `head=6ac813ff3eb767b9f202ffa9cae2ea92c88f36d8`＋`dirty=0`＋`card_face.gd sha256=38B0580D…`），日志 `C:\1\tmp\magic-spire-wt-mainverify\spire-godot\build\fact-kinds\mainverify-run{1,2}.log`（同目录 `seed7-trade.control.json`：`commits=39 steps=39 final_version=40 partial=true`）。未修复的合并态仍崩、修复态 60／60＋exit 0，两侧同配方、同驱动哈希，日志身份头自证。
- 与源线 `bece4ed` 的差异（blob 级核对）：`ui/card_face.gd`（`26b1f389…`）、`tests/display_ui_cases.gd`（`409db0c1…`）、`tests/interface_ui_cases.gd`（`4ab5e39f…`）三者 `bece4ed:<路径>` 与 `HEAD:<路径>` 逐一同哈希＝**0 行差**；`docs/` 侧差异全在 main 侧——`docs/spec/hand-refresh-dependencies.md` 三处（计划临时路径改指 `docs/spec/response-pipeline.md`；`PRESENT_ADJACENCY` 行「必须保持」列补共享手牌辅助函数入表口径；新增 `tests/architecture_cases.gd::PRESENT_EXTERNAL_OWNERS` 行）、`docs/record/verification.md` 与 `docs/record/changelog.md` 的 main 侧节、`docs/record/proposals/present-adjacency-completeness-floor.md`（main 有、源线无）。本线的修复字节、判据与口径零丢失。
- 未跑：`-Suite all` 完整回归；UI 十分类以外的窗口分类（route／home／pressure／enemies／guard／baseline／normal_play 等）；`-Suite runner -VerifyRunner`（规则与测试器未改）；**E2**（三类池在图鉴／牌库／离狱滚动子树内的翻面压力）；安卓真机；打包、标签、推送。
- 证据位置：本树 `spire-godot/build/checks/20261005T094721686-32312`／`20261005T095533175-5864`／`20261005T093130506-34704`、`spire-godot/build/fact-kinds/fixonmain-run1.log`／`fixonmain-run2.log`；对照树 `C:\1\tmp\magic-spire-wt-mainverify\spire-godot\build\fact-kinds\mainverify-run1.log`／`mainverify-run2.log`／`seed7-trade.control.json`。本条只追加 `docs/record/verification.md`（不在源码指纹与规则文档扫描面内），不改历史条目。

## 2026-10-05 多 harness 操作卡与反馈片两条判据
- 域：`.zcode/skills/repo-ops/SKILL.md`（多 harness 操作卡）、`tests/architecture_cases.gd::feedback_save_cap_pinned`、`tests/architecture_cases.gd::slice_dependency_directions`（新增 feedback-service 零依赖扫描）、`ui/feedback_report.gd::MAX_SAVE_BYTES`、`tools/feedback-service/Code.gs`。
- 命令：`tools/check.ps1 -Suite architecture -TimeoutSeconds 2400`（本轮`GODOT_BIN`显式指向`Godot_v4.7.2-stable_win64_console.exe`；本机`GODOT_BIN`已坏，见操作卡；轮内 docs 阶段同跑）。运行目录在`spire-godot/build/checks/<运行号>/`，随本工作树拆除。
- 突变1（`ui/feedback_report.gd`把`MAX_SAVE_BYTES`改为`1*1024*1024`）`20261005T094604810-40532`：architecture FAIL、1/4479断言，唯一失败`DEP feedback_save_cap_pinned: ui/feedback_report.gd declares the 2 MiB attachment cap as const MAX_SAVE_BYTES=2*1024*1024`；还原后在突变2轮转为通过。
- 突变2（`tools/feedback-service/Code.gs`加一行`// mutation probe: res://core/save_store.gd`）`20261005T094715495-33364`：architecture FAIL、1/4479断言，唯一失败`DEP slice_dependency_directions: tools/feedback-service never references game source paths (res://core, res://ui, res://data): ["tools/feedback-service/Code.gs references res://core"]`；同轮`feedback_save_cap_pinned`通过，还原后该检查为绿。
- 终态`20261005T094833470-38060`：`SUITE RESULT: architecture PASS`、4479断言（较既有基线4477增加2条）、exit=0、`status=passed`、`before==after`、无`SOURCE CHANGED`；同轮`DOCS RESULT: PASS`。独立`tools/check-docs.ps1`：`DOCS PASS: 35 rule-class document(s), 2109 reference(s) checked, allowlist 3 entrie(s)`，exit=0；操作卡提交前同一门禁为35文件／2109引用PASS。
- 未跑项：未跑`-Suite all`与UI回归、未跑codex／opencode多路独立审查、未复跑操作卡中带†的codex沙箱与opencode XDG条目（卡内标待核实）；未打包、未推送、未改版本。

## 2026-10-05 记录守恒修复与 check-record-conservation.ps1

域：`docs/record/verification.md`（8 个丢失标识的逐字恢复）、`.zcode/skills/spire-docs/SKILL.md`（记录生命周期行统一＋保留白名单）、`.zcode/skills/repo-ops/SKILL.md`（操作卡登记）、`spire-godot/tools/check-record-conservation.ps1`（新增，迁移期脚本）。基线 `8e83876`；本地提交 `89e4611`（本条目另批），未推送、未 tag、未改版本。

- 恢复的 8 个标识：ZIP `8212e594af0d4e511fff70b550469c5075f8799f9d0870716fc83fadaf7d479d`（143545728 B）、`80abcd71c99225e51916d163f5e9ae6c5372d402`、`08b2caf57b312797a965cb020ed193145f8e87c3`、`63993badc0a6c1425a5a0ca38432188c2fffc0a3`、`683feefe5353ee8d79b7acd18d18c50206241130`、`02ea62262a1a89d8abc0e7b7364ba2885f37c934`、`B0D8D6353F805A8D7AB6F5EFC2A31D3D27629F5C7345FB342C21755A149E2901`、`FAA51D56B8D626959A828D93DB7EE67D7D026D57E34D85C46B3F6E8D0CE8755E`。5 句按原卷逐字放回原条目，未改写、未摘要：打包 `| 哈希 | …` 行；PR#4/#5 来源句（主分支基线＋两 PR head）；PR#6 的 head 与整合前 main 句；v0.18.1 规则初轮 before/after 句；卡牌施法条件冻结门禁 before/after 句。
- 保留白名单（写入 `spire-docs` 记录诚实节）：任何分隔写法的 before/after、小写 failed、「哈希」／SHA256／checksum 行、40／64 位十六进制、运行号、`build/`／`outputs/` 路径、失败／未跑／未验证／不作证原句、标题／日期／域行。
- 新增 `tools/check-record-conservation.ps1 -Base <rev>`（默认 `8e83876`）对三卷输出四类差集，非空即非零退出。终态复跑：identifiers=0、non_verbatim=0、headings/dates/domains=0、markers=0，allowlist 1 条（已用：2026-09-18 卷首被 2026-10-05 改编排的散句），exit=0。敏感性实测：临时删哈希行＋改写一句＋改域行 → identifiers=1、non_verbatim=1、domains=1、exit=1；按 sha256 还原（`8b87c02a…`）后复跑 PASS。
- 文档门禁 `tools/check-docs.ps1`：`DOCS PASS: 35 rule-class document(s), 2114 reference(s) checked, allowlist 3 entrie(s)`，exit=0。
- 规则门 `tools/check.ps1 -Suite architecture -TimeoutSeconds 2400`（`GODOT_BIN` 显式指向 `Godot_v4.7.2-stable_win64_console.exe`）：`20261005T095758440-36784`、`SUITE RESULT: architecture PASS`、4479 断言、40.38s、exit=0、`status=passed`、before==after==`D6A46B2138062C5EDE0DEF17F288CB52876DB30989B7467233DBDF7B1EFF7E32`、无 `SOURCE CHANGED`、无 cert-store 行，轮内 docs 阶段同为 PASS。起前 `Get-Process Godot*` 见非本会话进程（PID 9592／35032），等到为空才起，本轮引擎串行、无并跑。
- 未跑项：未跑 `-Suite all` 与 UI 回归、未跑 `tools/check-content.ps1`（未改 `content/packs/`）、未跑打包与安卓真机、未推送、未改版本。

## 2026-10-05 长时程真实输入配方纳入常规门禁
- 域：`spire-godot/tests/recipe_driver.gd`（新增驱动）、`spire-godot/tools/check.ps1`（新增 `-Suite recipe` 阶段、`summary.json` 的 `recipe` 字段与 `-RerunFailed` 续跑）、`.zcode/skills/repo-ops/SKILL.md`（操作卡登记）。基线 `15f9582`；代码与操作卡提交 `fd99eb4`，本条目另批。
- 配方＝种子 7／`--cap=60`／`--style=trade`，窗口 1600×900、非 headless，经 `spire-godot/tests/ui_smoke.gd` 的真实点击／拖拽与 `spire-godot/tests/normal_play_cases.gd::choose` 推进；驱动只依赖仓库内既有夹具，不依赖 `build/` 下任何 gitignored 文件。收尾行 `RECIPE seed=7 commits=60 steps=60 stop=cap`；`check-recipe.log` 头为 `RUN IDENTITY`（`head`／`dirty`／5 个关键文件 sha256）、末尾 `exit=<code>`。
- 终态绿 `20261005T101538435-9748`：`RECIPE seed=7 commits=60 steps=60 stop=cap`、`UI PASS: 65 assertions`、`CHECK recipe: 47.65s, exit=0`、`summary.json` 的 `status=passed`、`recipe.passed=["recipe"]`、before==after、轮内 `DOCS RESULT: PASS`；`RUN IDENTITY` 为 `head=fd99eb4…`、`dirty=0`、`ui/card_face.gd` sha256 `9F31A7EC…`。检出 `.import` 行尾整批改写后按索引内容还原，复跑 `git status --short` 干净。
- 敏感性（临时 detached 树 `C:\1\tmp\magic-spire-wt-norms-pooled`＝`6ac813f`，其 `ui/card_face.gd::_content_slot` 为池化版、sha256 `38B0580D…`；同一驱动与 `check.ps1` 拷入该树）：`20261005T101406161-9012` 配方红——第 40 步驱动中引擎崩溃（#39 提交已落、version=40），`check-recipe.log` 第 93 行 `exit=-1073741819`、stderr 段 `CrashHandlerException: Program crashed with signal 11`、无 `RECIPE` 收尾行；整轮 exit=1、`status=failed`、`recipe.failed=["recipe"]`。临时树已 `git worktree remove --force` 拆除、`git worktree list` 无残留；该红轮日志与摘要副本在 `spire-godot/build/pooled-sensitivity-20261005T101406161-9012/`（gitignored，随本工作树拆除）。
- 续跑与自检：`-RerunFailed` 指向该红轮摘要 `20261005T101831459-25596` 只续跑 `recipe` 并转绿（`rules.selected=[]`、`recipe.passed=["recipe"]`、exit=0、before==after）；`tools/check.ps1 -Suite runner -VerifyRunner -TimeoutSeconds 2400`（`20261005T101756508-4028`）runner 541 断言 PASS、7 条负例探针全部按预期拒绝、exit=0；`tools/check.ps1 -Suite architecture -TimeoutSeconds 2400`（`20261005T101642469-36812`）`SUITE RESULT: architecture PASS`、4479 断言、42.18s、exit=0、`status=passed`、before==after==`9BDF1E48…`、无 `SOURCE CHANGED`、轮内 docs PASS；单跑 `tools/check-docs.ps1` 输出 `DOCS PASS: 35 rule-class document(s), 2116 reference(s) checked, allowlist 3 entrie(s)`、exit=0。
- 时间预算：配方阶段实测 47.65s／50.80s／50.01s（引擎 `UI TIME` 41.7—42.5s），整轮含 docs 阶段约 55s，未超 3 分钟、不缩短 cap；默认不并入 `all`（先观察稳定性），操作卡写明预发布与交付前必跑。
- 失败与不作证据轮：临时树首次运行 `20261005T101316642-30120` 因新树首次导入未完成，`check-import` 报 `assets/fonts/NotoSansCJKsc-Regular.otf` 加载 ERROR 而 exit=1，非配方结论；同树复跑取得上述红轮。各轮起前 `Get-Process Godot*` 均为空，引擎串行、无并跑。
- 未跑项：未跑 `-Suite all` 与 UI 回归、未跑 `tools/check-content.ps1`（未改 `content/packs/`）、未跑打包与安卓真机、未推送、未 tag、未改版本。

## 2026-10-05 docs/spec 判据散文→检查（B2）

- 域：`docs/spec/**` 其余 14 文件（B1 已处理的 4 份 `*-dependencies.md` 不动）；新增判据落点全部在 `tests/architecture_cases.gd`（9 个具名 check、15 条断言）。
- 处理面：整份重写＝`docs/spec/candidate-removal.md`（迁移前测绘／分批／Gherkin 合同／DoD／算未完成／假设／波及清单删；kind 键面与 TRANSITIONS 冻结名单搬进检查）、`response-pipeline.md`（未落地的 commit／present_rejection 设计与未排期方向删；保留现行接缝与节键）、`event-pipeline.md`（过程与 rg 清单删；接口与 schema 保留）、`equipment-query-seam.md`（分批与 oracle 过程删；作用域进出点、禁止边搬进检查）、`run-review.md`（场景 A–J 与验收程序删；判据留具名 check 索引）、`transition-pipeline.md`（红集历史清单删）、`save-fixed-points.md`、`seed-identity.md`（点名的机检条目改为检查索引）、`packaging.md`（两条流水线去重）、`project-map.md`、`feedback-deployment.md`。保守例外（玩家可见取用与文案口径）＝`ondemand-copy.md`、`release-interface.md`、`card-terms.md`：只加检查索引行，语义条目一条未删（不可机检项清单在 B2 报告「待你过目」）。
- 新 check 与突变（相反语义 → 红 → 还原；每轮 `-Suite architecture`）：`equipment_scope_sites`（豁免函数内开作用域）`20261005T103000069-28236`；`equipment_targets_walk_is_one_path`（`targets_at` 直呼 `physical_pieces`）`20261005T103044675-38308`；`transition_kind_set_pinned`（TRANSITIONS 加一条 kind）`20261005T103129858-34192`；`command_params_keys_pinned`（COMMAND_KEYS 给 `end` 加键）`20261005T103236278-14172`；`get_view_call_sites_are_pinned`（第 5 个调用点）`20261005T103335101-38384`；`ondemand_copy_consumer_boundary`（ui 出现 `copy_router`）`20261005T103428823-38628`；`production_source_never_preloads_tests`（core 出现 `res://tests/`）`20261005T103518342-39020`；`run_review_is_read_only_source`（run_review 出现 `_save_progress`）`20261005T103600800-9616`；`target_queries_stay_stateless`（target_queries 触 `game.state`）`20261005T103640298-37912`。九轮均 `SUITE RESULT: architecture FAIL`，唯一／首个失败断言即目标 check，还原后复绿。
- 失败与不作证据轮：首轮 `20261005T102550994-39600` 为新 check 自身缺陷（函数体切分含签名行，`_visit_targets_at` 误报）1/4494 断言红，不作任何判据；修正后 `20261005T102641005-24912` 全绿 4494 断言。
- 终态 `20261005T104146305-14884`：`-Suite architecture -TimeoutSeconds 2400`（`GODOT_BIN` 指向 `Godot_v4.7.2-stable_win64_console.exe`）`SUITE RESULT: architecture PASS`、4494 断言、45.42s、exit=0、`status=passed`、before==after、无 `SOURCE CHANGED`、无 cert-store 行；轮内 `DOCS RESULT: PASS`。独立 `tools/check-docs.ps1`：`DOCS PASS: 35 rule-class document(s), 1433 reference(s) checked, allowlist 3 entrie(s)`、exit=0；三条 declared-missing 已无人引用（DOC NOTE，allowlist 未增未删）。
- 守卫阳性对照（`docs/spec/seed-identity.md`，随后删除该行）：注入 `` `core/game.gd::b2_no_such_symbol` `` → `DOC FAIL: … symbol is not declared in the anchored file`、`DOCS FAIL: 1 unresolved`；注入 `` `tools/b2_no_such_tool.ps1` `` → 两条 `DOC FAIL`（坏锚点在位）、`DOCS FAIL: 2 unresolved`；两行删除后 `DOCS PASS`。
- 不变式自证：`git diff --stat` 只含 `docs/spec/*` 14 份与 `spire-godot/tests/architecture_cases.gd`；`docs/design/**`、`spire-godot/assets/**`、根 `AGENTS.md`、`.zcode/skills/**` 零改动；未新增 `check-docs` 允许清单条目；未改 `core`／`ui`／`data` 语义。
- 未跑项：未跑 `-Suite all` 与 UI 回归、未跑 `tools/check-content.ps1`（未改 `content/packs/`）、未跑打包与安卓真机、未推送、未 tag、未改版本；引擎起前 `Get-Process Godot*` 为空、轮内串行，跑后 `git status` 无 `.import` 行尾改写。

## 2026-10-05 B2 保守例外按代码基线处置（B2b）

- 域：`docs/spec/ondemand-copy.md`（冲突句改写＋过期符号/基线/成本段删除）、`docs/spec/release-interface.md`（ActionIndex 引用改为 `ui/target_queries.gd::first_usable`／`view.display_facts`）、`docs/spec/run-review.md`（引用检查名与断言原文一致）、`.zcode/skills/spire-docs/SKILL.md`（新增「文档以当前架构为基线」约束句）、`spire-godot/tests/architecture_cases.gd`（`ondemand_copy_consumer_boundary` 增卡面投影直读点白名单；新增 `ui_never_reads_game_state`）。本地提交 `ac5d543`，未推送、未 tag、未改版本。
- 人裁：契约与实现冲突以当前架构为准（文档跟随代码、不绕行）；B2 保守例外的取舍判据＝以当前代码为基线（活约束留、能机检的搬检查、过期删、判不清列入待审）；B3 只出清单不改 `AGENTS.md`。
- 命令与结果（`GODOT_BIN` 显式指向 `Godot_v4.7.2-stable_win64_console.exe`；每轮起前 `Get-Process Godot*` 为空，串行单引擎）：
  - `tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` 基线绿 `20261005T125837517-32032`：`SUITE RESULT: architecture PASS`、4496 断言（较既有 4494 增加 2 条）、exit=0、`status=passed`、`before==after`、无 `SOURCE CHANGED`；轮内 `DOCS PASS: 35 rule-class document(s), 1478 reference(s) checked, allowlist 3 entrie(s)`。
  - 独立 `tools/check-docs.ps1`：`DOCS PASS: 35 document(s), 1478 reference(s), allowlist 3`，exit=0（三条 declared-missing 仍无人引用，清单未增未删）。
- 突变（相反语义 → 红 → 还原）：
  - 突变 1（`ui/deck_browser.gd::setup` 加一行直读 `ui.view.card_texts`）`20261005T125938734-26028`：architecture FAIL、1/4496，唯一失败即新白名单断言 `CP ondemand_copy_consumer_boundary: card_texts and card_instances are read only by ui/main.gd::card_entry/_card/_hand_presentation_key`（多出 `ui/deck_browser.gd::setup`）；按字节备份还原后复绿。
  - 突变 2（`ui/arena.gd::configure_hero` 加一行 `ui.game.state` 读）`20261005T130033590-38988`：architecture FAIL、1/4496，唯一失败 `RL ui_never_reads_game_state: ui/ never reads or writes game.state: ["ui/arena.gd::configure_hero"]`；按字节备份还原后复绿。
- 终态 `20261005T130118119-39532`：`SUITE RESULT: architecture PASS`、4496 断言、exit=0、`status=passed`、before==after、无 `SOURCE CHANGED`；轮内 `DOCS RESULT: PASS`；跑后 `git status --short` 干净，本轮无 `.import` 行尾改写。
- 处置证据要点：`view.card_texts`／`view.card_instances` 的 UI 直读点实测仅 `ui/main.gd::card_entry`／`::_card`／`::_hand_presentation_key`；候选 `detail` 直读点仅 `ui/event_screen.gd`（event 组）与 `ui/main.gd::_drawer_presentation_key`（item 组节键），card 组只经 `ui/main.gd::detail_of`；`_candidate(out,…)`／`target_candidate`／`paid_candidate`／`ActionIndex`／`old_action`／`copy_display_points_have_no_misses`／`copy_full_entry_equals_baseline`／`copy_ghost_fallback_recorded` 在当前代码中均不存在（分别由 `core/game.gd::_fact`／`core/room_services.gd::paid_fact`／`ui/target_queries.gd::first_usable`／`copy_single_entry_matches_projection`／`copy_missing_key_never_crashes` 取代）。
- 待你过目（不自行选边）：`ondemand-copy.md` 的「分批（B0→R0…R6→B1…B3）」段与「收口阶段交接约束／算未完成」——代码仍有直传字符串生产者（如 `core/card_effects.gd` 的 chain 事实），无法从代码判定收口批是否结束；B3 逐条清单在计划区 `C:\1\tmp\agb3-list.md`（未入库、未改 `AGENTS.md`）。
- 未跑项：未跑 `-Suite all` 与 UI 回归、未跑 `tools/check-content.ps1`（未改 `content/packs/`）、未跑打包与安卓真机、未推送、未 tag、未改版本。

## 2026-10-05 推翻重写 AGENTS.md 与 ondemand-copy 收尾删改（B3'）

- 域：根 `AGENTS.md`（整份重写，212 → 101 行：红线／本仓特有约束／Godot 技术栈与 GDScript 代码规范正文／实现规约（审查）／检查力度与报告四态／最小索引；节点名 `禁区`／`实现规约`／`代码规范`／`文档入口` 保留，使既有文档指针仍可解析；删与全局 AGENTS 重复句、历史叙述、「引用代码不写行号」、可在检查里表达的判据复述）、`docs/spec/ondemand-copy.md`（删「分批」段与收口交接约束及「算未完成」内同源两小句；「三个只读入口」改「只读入口」；删与当前路由不符的 8 个 detail 构建函数点名）、`spire-godot/core/copy_router.gd`（头部注释 `_candidate` → `_fact_core`，未改代码语义）。本地提交 `6880a6b`，未推送、未 tag、未改版本。
- 人裁：不做逐条修剪、推翻重写；文档以当前架构为基线；全局文档＝引用并信任（不复制其正文）；`AGENTS.md` 必须写入 Godot 代码规范正文（不引 TS 栈 500／800 行数阈值，按职责拆不按行数硬拆）。B2b 上一条「待你过目」的分批段与收口交接约束本次裁定删除，删除对象仅限该两段及其同源复述，契约其余语义条目未动。
- 命令与结果（`GODOT_BIN` 显式指向 `Godot_v4.7.2-stable_win64_console.exe`；起前 `Get-Process Godot*` 为空、跑后仍为空，串行单引擎）：
  - `tools/check.ps1 -Suite architecture -TimeoutSeconds 2400`，运行 `20261005T131757062-37960`：`DOCS RESULT: PASS`、`RULE SCOPE: architecture`、`SUITE RESULT: architecture PASS`、`PASS: 4496 assertions`、`CHECK rules: 28.19s`、exit=0、`status=passed`、before==after==`66B6C5B55AD225BE8A38CE2E0352EDF7972D433ABCDE7C0A6205D10EA0B5DC91`、无 `SOURCE CHANGED`、无 cert-store 行；`summary.json` 的 `docs.status=passed`（35 文件、1444 引用、0 problem、allowlist 3）、`rules.complete=true`、`ui.selected=[]`。
  - 独立 `tools/check-docs.ps1`：`DOCS PASS: 35 rule-class document(s), 1444 reference(s) checked, allowlist 3 entrie(s)`、exit=0；三条 declared-missing 仍无人引用（DOC NOTE），清单未增未删。
- 新版 `AGENTS.md` 索引自查：文档入口表 18 行与 5 个项目 skill 的点名路径逐条实测存在（`docs/design/*` 8 份、`docs/spec/*` 6 份、`docs/guide/*` 2 份、`docs/record/verification.md`／`changelog.md`、`spire-godot/assets/art/ART-NOTES.md`／`spire-godot/assets/vendor/CREDITS.md`、`.zcode/skills/*/SKILL.md`）；引用由本轮文档门禁全量复验（1444 条、0 problem）。
- 跑后 `git status --short` 干净：本轮 `.godot` 已存在，未触发 import 阶段，无 `.import` 行尾改写需还原。
- 未跑项：未跑 `-Suite all` 与 UI 回归（未改行为面，仅注释改动一处）、未跑 `tools/check-content.ps1`（未改 `content/packs/`）、未跑打包与安卓真机、未推送、未 tag、未改版本。

## 2026-10-05 B3' 前言措辞收尾与终态复跑

- 域：根 `AGENTS.md`（前言改用「全局 AGENTS 的红线照旧生效」原句，1 行；语义与节结构不变）。本地提交 `20a49a2`。
- 命令与结果（`GODOT_BIN` 显式指向 `Godot_v4.7.2-stable_win64_console.exe`；起前 `Get-Process Godot*` 为空、跑后仍为空，串行单引擎）：`tools/check.ps1 -Suite architecture -TimeoutSeconds 2400`，运行 `20261005T132034618-27544`：`DOCS RESULT: PASS`、`SUITE RESULT: architecture PASS`、`PASS: 4496 assertions`、`CHECK rules: 40.79s`、exit=0、`status=passed`、before==after==`EC87A84A8DBF9BFC4AF1A554CB40CE6ED2ACADFAEE78348A476C59CFCBF49293`、无 `SOURCE CHANGED`、无 cert-store 行；独立 `tools/check-docs.ps1`：`DOCS PASS: 35 rule-class document(s), 1444 reference(s) checked, allowlist 3 entrie(s)`、exit=0。跑后 `git status --short` 干净，无 `.import` 行尾改写。
- 上一轮 `20261005T131757062-37960`（提交 `6880a6b`）因本句措辞改动被取代，不作终态证据。
- 未跑项：未跑 `-Suite all` 与 UI 回归、未跑 `tools/check-content.ps1`（未改 `content/packs/`）、未跑打包与安卓真机、未推送、未 tag、未改版本。

## 2026-10-06 AGENTS 收尾三处、突变证据表与两处烂引用（B3''）

- 域：根 `AGENTS.md`（红线「Push、tag、Release、PR 或部署」条加例外句；`代码规范（GDScript）` 删注释语言的英文要求；`检查力度与报告四态` 增一条敏感性规则）、`docs/spec/project-map.md`（`AGENTS.md` 行的职责描述改为现状四类）、`.zcode/skills/repo-ops/SKILL.md`（登记 `tools/check-mutation.ps1` 的用法、串行纪律与证据落点）、`spire-godot/tests/mutations.json`（新增声明表）、`spire-godot/tools/check-mutation.ps1`（新增执行器）、`spire-godot/tests/architecture_cases.gd`（新增 `mutation_evidence_is_total` 并入 `run`）、`spire-godot/core/**` 与 `spire-godot/ui/**` 共 17 文件 38 处注释（`docs/ondemand-copy.md §11.x／§1.x` 等已不存在的编号改为该契约现行节名，仅注释、无语义改动）。本地提交 `a1230e1`，未推送、未 tag、未改版本。
- 人裁（2026-10-06）：自动推送改「大版本完成且门禁通过后准备好推送并问一次」；注释语言要求删；「校验」条换正面描述并建立有效验证；「高频路径只增不减」条不写回；两处烂引用一起修。本批按行执行，未自行扩张范围。
- 覆盖面：`tests/mutations.json` 共 16 条＝本轮规范重写线新增的 15 条判据（`slice_dependency_directions`／`run_identity_single_writer`／`feedback_save_single_serializer`／`card_terms_single_source`／`feedback_save_cap_pinned`／`equipment_scope_sites`／`equipment_targets_walk_is_one_path`／`transition_kind_set_pinned`／`command_params_keys_pinned`／`get_view_call_sites_are_pinned`／`production_source_never_preloads_tests`／`ondemand_copy_consumer_boundary`／`run_review_is_read_only_source`／`target_queries_stay_stateless`／`ui_never_reads_game_state`）＋ `mutation_evidence_is_total` 自证条。`known_gaps` 39 条＝ `tests/architecture_cases.gd` 判据全集（54 条，判据＝函数体自带断言行的顶层函数，`run` 是入口、下划线助手随父判据）里尚未补证据者，理由写在表内 `known_gaps_reason`；`mutation_evidence_is_total` 的 ③ 保证 54 == 16 ∪ 39 且两边不相交，新增判据不得登记为缺口。
- 新判据三向核对：① 表里每条检查名必须在其声明的套件脚本里真实存在（防幽灵条目）；② 本轮 15 条必须逐条在表里（不得靠 `known_gaps` 逃逸）；③ 判据全集 == 表 ∪ `known_gaps`（不许默默缺席）。
- 敏感性（新判据自身，先于本批提交取得）：表内条 `mutation_evidence_is_total`（把 `run_identity_single_writer` 条目改名为幽灵名）运行 `20261005T134154745-40464`——三条断言同时红：`["mutation_probe_ghost_check@architecture"]`／本轮缺证据 `["run_identity_single_writer"]`／`silent=["run_identity_single_writer"]`，还原逐字节。手动探针「删掉表里一条」（`build/probe-delete-entry.ps1`，删除 `run_identity_single_writer` 条目）运行 `20261005T134241853-delete`：②③ 红、表 sha256 `13E3D381157E` 突变前／还原后一致、恢复值为 `F4BD7503A0AB`，`SUITE RESULT: architecture FAIL`、exit=1。
- `tools/check-mutation.ps1 -All` 终态运行 `20261005T135320444-36616`：16/16 条「改相反语义→该判据变红→逐字节还原」，`MUTATION SUMMARY: 16/16 … restored byte-for-byte; worktree unchanged=True`、exit=0、实测 461s（单条约 24—30s）；逐条首个失败断言即目标 check：`slice_dependency_directions`→`["core/game.gd"]`、`run_identity_single_writer`→`["ui/main.gd::_mutation_probe_clipboard"]`、`feedback_save_single_serializer`→多出 `ui/deck_browser.gd::_mutation_probe_save`、`card_terms_single_source`→`["data/card_text.gd","ui/deck_browser.gd"]`、`feedback_save_cap_pinned`→cap 常量不符、`equipment_scope_sites`→`extra=["core/game.gd::_mutation_probe_scope"]`、`equipment_targets_walk_is_one_path`→`["physical_pieces("]`、`transition_kind_set_pinned`→`extra=["mutation_probe_kind"]`、`command_params_keys_pinned`→`manual:declared ["mutation_probe","target"]`、`get_view_call_sites_are_pinned`→多出 `ui/deck_browser.gd::_mutation_probe_view`、`ondemand_copy_consumer_boundary`→多出 `card_texts` 读点、`production_source_never_preloads_tests`→`["ui/deck_browser.gd::<file>"]`、`run_review_is_read_only_source`→`["_save_progress"]`、`target_queries_stay_stateless`→`["game.", ".state"]`、`ui_never_reads_game_state`→`["ui/deck_browser.gd::_mutation_probe_state"]`、`mutation_evidence_is_total`→幽灵名。日志在 `build/mutations/20261005T135320444-36616/`（gitignored）。
- 作废轮与并发处置：`20261005T134344761-25464`（首轮 `-All`）逐条结果同样是 16/16 红且逐字节还原，但运行期另一条批（文案解歧批）在同一工作树写了 `AGENTS.md`／`.zcode/skills/**`／`docs/spec/**` 与 `spire-godot/tools/check-mutation.ps1`，脚本收尾比对 `git status --porcelain` 前后不一致、自报 `MUTATION RESIDUE` 并 exit 1 ⇒ **该轮不作证据**。并发批撤出后（`git status --short` 为空、`git diff --exit-code -- spire-godot/ui/target_queries.gd` 为 0、HEAD 仍为 `a1230e1`）在干净树重跑取得上述终态 `20261005T135320444-36616`。重跑前起后 `Get-Process Godot*` 均为空、无并跑；本轮 `check.ps1` 轮次未出现 `SOURCE CHANGED`。
- 门禁（`GODOT_BIN` 显式指向 `Godot_v4.7.2-stable_win64_console.exe`；环境变量原值指向不存在的 `C:\1\Tools\Godot\v4.7-stable\Godot_v4.7-stable_win64.exe`，故按进程覆盖）：`tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` 运行 `20261005T140139379-41092`：`DOCS RESULT: PASS`（35 文件／1448 引用／0 problem／allowlist 3）、`SUITE RESULT: architecture PASS`、`PASS: 4503 assertions`、`CHECK rules: 25.20s`、exit=0、`summary.json` `status=passed`、before==after==`A6C89C4441A0BF46F8EFD022BA9F8EB0007FA27A4E5E9C5D30B50576AD2822C9`、无 `SOURCE CHANGED`、无 cert-store 行。独立 `tools/check-docs.ps1`：`DOCS PASS: 35 rule-class document(s), 1448 reference(s) checked, allowlist 3 entrie(s)`、exit=0；三条 declared-missing 仍无人引用（DOC NOTE），清单未增未删。跑后 `git status --short` 干净、无 `.import` 行尾改写。
- 遗留发现（不在本批点名范围，交回协调者裁量）：本批只清 `docs/ondemand-copy.md` 的编号引用（代码中该类引用现存 0 处，md／skill 中 0 处）；同一类失效引用在 `core/`＋`ui/`（78 行）与 `tests/`（20 行）共 98 行仍指向其它已去编号契约（`docs/spec/candidate-removal.md` 47 行为主，另有 `transition-pipeline.md`／`save-fixed-points.md`／`docs/design/prison.md` 与无路径的裸 §），本次未动。
- 未跑项：未跑 `-Suite all` 与 UI 回归、未跑 `tools/check-content.ps1`（未改 `content/packs/`）、未跑打包与安卓真机、未推送、未 tag、未改版本。

## 2026-10-06 规范句解歧（文案解歧批）

- 域：`AGENTS.md`（推送例外条、「不引入 lint／format」条、门禁入口条、审查豁免条、检查强度条）、`.zcode/skills/repo-ops/SKILL.md`（工作树删除条、敏感性证据条、审查协议 FAIL 判定）、`.zcode/skills/spire-docs/SKILL.md`（改动同步条去代词＋新增「规范句写作约束」）、`docs/spec/` 本轮改写的 18 份中 12 份有改动（`candidate-removal.md`／`candidate-removal-dependencies.md`／`card-terms-dependencies.md`／`equipment-query-seam.md`／`event-pipeline.md`／`ondemand-copy.md`／`packaging.md`／`project-map.md`／`run-review.md`／`save-fixed-points.md`／`seed-feedback-dependencies.md`／`transition-pipeline.md`；其余 6 份逐句审读后无需改）、`spire-godot/tools/check-mutation.ps1`（头部注释）。本地提交 `d0d39dd`，未推送、未 tag、未改版本。
- 审查口径：规范句＝含 必须／不得／须／一律／只／仅／应／禁止／例外 的句子；按强词（必须／不得／须／一律／禁止／例外）计 257 条、含弱词（只／仅／应）计 672 条，逐条判读。判据 A 极性自足／B 主体与范围自足／C 禁令点到具体对象／D 术语一义／E 代词所指；只改写法、不改规则语义；语义存疑句不改，列「待你过目」（见下）。
- 改动：29 处规范句就地改写（判据 A—E 均有命中，一句可命中多条；逐句处置表见本批报告）＋ `spire-docs` 新增 1 条「规范句写作约束」。未改语义、未动规则；`docs/record/**` 本轮条目的规范句经扫描均为证据行，未改。
- 门禁（起前 `Get-Process Godot*` 为空、串行单引擎；`GODOT_BIN` 显式指向 `Godot_v4.7.2-stable_win64_console.exe`）：`tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` 运行 `20261005T141253138-41808`：`DOCS PASS: 35 rule-class document(s), 1449 reference(s) checked, allowlist 3 entrie(s)`、`DOCS RESULT: PASS`、`SUITE RESULT: architecture PASS`、`PASS: 4503 assertions`、`CHECK rules: 27.61s`、exit=0、`summary.json` `status=passed`、before==after==`84FF40C607C0B6C05945A373927D01A9CDCCAE46B0E7F52FC509530DD7B12A9C`、无 `SOURCE CHANGED`、无 cert-store 行；独立 `tools/check-docs.ps1`：`DOCS PASS: 35 rule-class document(s), 1449 reference(s) checked, allowlist 3 entrie(s)`、exit=0。跑后 `git status --short` 干净、无 `.import` 行尾改写。
- 与 B3''（`f378416` 条目）的并发时间线：判「落完」00:43:34（HEAD `a1230e1`）→ 00:50:18 发现 `spire-godot/ui/target_queries.gd` 被注入突变探针、00:50:48 见对方引擎进程 → 00:52:50 本批 WIP 撤出（`git stash`，底稿 `C:\1\tmp\disambig-wip.patch`；撤出时 `git status --short` 为空、`git diff --exit-code -- spire-godot/ui/target_queries.gd` 为 0）→ 01:03:32 对方收口提交 `f378416` → 连续 3 分钟无新运行目录、无引擎、树干净后 01:12:10 恢复写入（`git stash pop`，基线 `f378416`）→ 01:12:43 本批提交 `d0d39dd` → 01:12:53 起门禁。对方首轮 `-All` 因本批并发写入作废并已在 `f378416` 条目记录、干净树重跑。
- 待你过目（本批未改，交协调者或人定）：① `docs/spec/event-pipeline.md`「三者都不得改序、改次数、改判据」的「三者」所指（前句点名四个随机关键词与 `RelicRewards.offer`）；② `docs/spec/card-terms.md`「（见未决问题）」悬空指针（该文件从无此节）；③ `.zcode/skills/repo-ops/SKILL.md`「必要时加 codex」的触发条件；④ `AGENTS.md`「大版本」已按 `docs/history/root-agent-contract-2026-09-14.md` 补限定语「用户确认的版本里程碑」，需人确认；⑤ `AGENTS.md`「按完成的逻辑批次派一次独立子代理审查」中「逻辑批次」的批次边界。
- 未跑项：未跑 `-Suite all` 与 UI 回归（只改文档与注释）、未跑 `tools/check-content.ps1`（未改 `content/packs/`）、未跑 `tools/check-mutation.ps1`（未改行为）、未跑打包与安卓真机、未推送、未 tag、未改版本。

## 2026-10-06 清 §-引用残留与工作树并发纪律操作卡（收尾批）

- 域：`spire-godot/core/**`＋`spire-godot/ui/**` 78 行与 `spire-godot/tests/**` 20 行中的失效 `§编号` 引用（含 1 行合法保留）、`.zcode/skills/repo-ops/SKILL.md`（新增「工作树并发纪律」节）。本地提交 `2382637`，未推送、未 tag、未改版本。
- 残留计数：改前 `core/`＋`ui/` 78 行、`tests/` 20 行，共 98 行；其中 97 行改写失效引用，另 1 行（`core/game.gd` 的注释续行）随同句改写；改后 `core/`＋`ui/`＋`tests/`＋`tools/` 仅剩 1 行：`tests/prison_cases.gd:823` 的 `docs/design/prison.md §2`（该文档仍有编号节，按规则保留）。`docs/`、`.zcode/` 其余 `§` 未触碰（`docs/design/**` 互引与 `docs/spec/seed-identity.md`→`docs/design/content.md` §3 的编号节仍有效；`docs/record/**` 只追加、`docs/history/**` 只读）。
- 逐类改法：① 目标文档已无编号节 ⇒ 改现行节名或具名 check：`docs/spec/candidate-removal.md「接口／输入域／失败语义」`（T5／T8／T9 边、唯一合法性判定、类型化指令、指令路由、分类子路由、提交入口、显示消费；验收项 G1—G9 改点名的 check `behavior_baseline_equivalence`／`removal_end_state`／`single_eligibility_implementation`／`instruction_router_single_entry`／`instruction_route_table_is_total`／`r3_display_points_do_not_read_rows`／`r4_display_points_do_not_read_rows`／`r5_display_facts_match_determination`，均实测存在于 `tests/`）、`docs/spec/event-pipeline.md「事件链／接口／输入域／求值顺序（顺序是判据的一部分）／叠加求值／节点级字段／存档表示／trace（debug 开关）／结果词汇与具名 gate」`、`docs/spec/transition-pipeline.md「接口」`、`docs/spec/save-fixed-points.md「接口／域」`、`docs/spec/equipment-query-seam.md「接口（接口清单与语义）／作用域进出点（冻结名单）／失败语义」`；② 无对应节名 ⇒ 去掉编号（`core/room_events.gd::_freeze_staged` 的 `§7.1`）；③ 目标文档仍有编号节 ⇒ 保留（`tests/prison_cases.gd:823`）。
- 无逻辑改动自证：对 27 个被改 `.gd` 文件逐行截断 `#` 之后的内容并与 `HEAD` 版本比对，结果 `comment-stripped differences: (none)`；`git diff -U0` 计 98 insertions／98 deletions，逐行为注释行。
- 门禁（起前 `Get-Process Godot*` 为空、串行单引擎；`GODOT_BIN` 显式指向 `Godot_v4.7.2-stable_win64_console.exe`）：`tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` 运行 `20261005T142653358-33944`：`DOCS PASS: 35 rule-class document(s), 1451 reference(s) checked, allowlist 3 entrie(s)`、`DOCS RESULT: PASS`、`SUITE RESULT: architecture PASS`、`PASS: 4503 assertions`、`CHECK rules: 23.73s`、exit=0、`summary.json` `status=passed`、before==after==`CA934414730F418C738DD82A63FBB02A21B15900B98B948893C72A54CB45E299`、`rules.complete=true`、`unrun=[]`、无 `SOURCE CHANGED`、无 cert-store 行。独立 `tools/check-docs.ps1`：`DOCS PASS: 35 rule-class document(s), 1451 reference(s) checked, allowlist 3 entrie(s)`、exit=0；三条 declared-missing 仍无人引用（DOC NOTE），清单未增未删。跑后 `git status --short` 无 `.import` 行尾改写。
- 操作卡新增条文（原文）：「每个工作树同一时间只允许一个写者；派工前确认该树没有其它会话在写。」「等待判据（全部满足才算对方收工）：① `Get-Process Godot*` 为空；② `spire-godot/build/checks/` 下连续 3 分钟无新运行目录；③ `git status --short` 为空；④ HEAD 稳定。」「**提交 ≠ 收工**：门禁与突变脚本运行期会临时改文件（`tools/check-mutation.ps1` 跑前跑后比对工作区，残留即自报 `MUTATION_RESIDUE` 并非零退出）；等待按上一条判据，不按"有没有提交"。」「引擎与突变脚本：同一时间一个引擎进程；`tools/check-mutation.ps1` 运行期不得有其它写者。」
- 无法判定而保留的条目：① `tests/prison_cases.gd:823`（目标 `docs/design/prison.md` 仍有编号节）；② `docs/record/**` 历史条目的 `§` 引用（记录只追加，不改写历史）；③ `docs/history/submit-dedup-2026-09-17.md`（只读归档）；④ `docs/design/*.md` 互引编号节与 `docs/spec/seed-identity.md` 对 `docs/design/content.md` §3 的引用（目标文档仍有编号节）。
- 未跑项：未跑 `-Suite all` 与 UI 回归（只改注释与技能操作卡）、未跑 `tools/check-content.ps1`（未改 `content/packs/`）、未跑 `tools/check-mutation.ps1`（未改行为面）、未跑打包与安卓真机、未推送、未 tag、未改版本。

## 2026-10-06 项目 skill 正文迁根 skills/ 与 ZCode 发现用薄桩（多 harness 批）

- 域：`skills/**`（五个技能正文，`git mv` 自 `.zcode/skills/`）、`.zcode/skills/*/SKILL.md`（新建发现用薄桩：frontmatter＋一行指针，无正文副本）、`.gitignore`（白名单新增 `!/skills/`）、`AGENTS.md`（3 处引用＋「项目 skill」索引一句）、`README.md`（1 处）、`docs/spec/*` 7 份、`docs/design/*` 6 份、`docs/guide/localization.md`（引用改 `skills/…`）、`spire-godot/tools/doc-scan-scope.ps1`／`check-docs.ps1`／`check.ps1`／`check-record-conservation.ps1`（扫描范围、根前缀与注释同步）。`docs/record/**` 历史条目里的旧路径按只追加不改（22 处）。
- 移动与桩：`git ls-files skills` = 五份正文（`repo-ops`／`spire-docs`／`spire-architecture`／`spire-ui-content`／`spire-validation-release`）；`git ls-files .zcode` = 五份薄桩；`git check-ignore -v skills/repo-ops/SKILL.md` 无命中、退出码 1（未被忽略）。桩与正文的 frontmatter 逐字节一致（`cmp` 五份全等；frontmatter 行数 6—7）。
- 正文逐字节自证（基线 `46ec08c`）：`spire-architecture`（`80eda9a5…`）、`spire-ui-content`（`899c635c…`）、`spire-validation-release`（`ffb74ea1…`）三份，把旧 blob 经 `.zcode/skills/`→`skills/` 替换后哈希等于现 blob ⇒ 除引用行外全文逐字节不变；`repo-ops`（+4/−4＝行 74／77／78／120）与 `spire-docs`（+3/−2＝行 60—62 折行）逐词差分显示改动内容全部是引用行（另加「含 `.zcode/skills` 薄桩」说明子句），无其它文本改动。
- 引用更新计数：改前 `rg -n "\.zcode/skills" -g '!build'` 实测 59 处（派工载荷记 39 处）——37 处改为 `skills/…`（五个正文 9、`AGENTS.md` 3、`README.md` 1、`docs/spec` 10、`docs/design` 7、`docs/guide` 1、工具注释 6），22 处 `docs/record/**`（3＋19）不动。改后（写本条目前实测）剩 30 处：薄桩说明 5（`AGENTS.md` 1、`docs/spec/project-map.md` 1、`skills/repo-ops` 2、`skills/spire-docs` 1）、薄桩留在扫描范围与指纹面的声明 3（`tools/doc-scan-scope.ps1` 2、`tools/check.ps1` 1）、`docs/record/**` 历史 22。
- 工具面改动：`doc-scan-scope.ps1::$RuleDocumentDirectoryRoots` 加 `'skills'` 且保留 `'.zcode/skills'`（理由：桩也留在规则类扫描内，桩指向不存在的正文会变红）；`check-docs.ps1` 的 `$repositoryPrefixes`／`$rootDirectoryNames`／`$rootAlternation` 加 `skills`（`.zcode` 保留），第 9 行根前缀注释与第 99 行通配示例随改；`check.ps1` 第 37／78／89 行注释；`check-record-conservation.ps1` 第 12 行注释。
- 门禁（起前跑后 `Get-Process Godot*` 为空、串行单引擎；`GODOT_BIN` 显式指向 `Godot_v4.7.2-stable_win64_console.exe`）：① 独立 `tools/check-docs.ps1`（改完即跑，引擎无关）`DOCS PASS: 40 rule-class document(s), 1466 reference(s) checked, allowlist 3 entrie(s)`、exit=0（改前 35 份／1451 条）。② `tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` 首轮 `20261005T232906158-40808`：`SUITE RESULT: architecture PASS`／`PASS: 4503 assertions`／`DOCS RESULT: PASS`，但 `status=source_changed`（before `14C7AB14…`≠after `8064009C…`）⇒ **不作证据**：运行期本实现者改了 `spire-godot/tools/check-record-conservation.ps1` 的行尾（LF→CRLF），该文件在源码指纹内。③ 冻结后重跑 `20261005T233055283-15900`：`SUITE RESULT: architecture PASS`、`PASS: 4503 assertions`、`CHECK rules: 46.36s`、exit=0、`status=passed`、before==after==`8064009C8E107E15522EA11C45E02725BA2518A82B3CE68F2A6F45CAA04ABB5C`、`docs.status=passed`（40 份／1466 条／0 problem／allowlist 3）、`unrun=[]`、无 `SOURCE CHANGED`、无 cert-store 行；未选 `ui`／`recipe`。重跑 `before` 等于首轮 `after` ⇒ 首轮期间的唯一变化就是上述行尾改写，此后无第三方写入。④ 冻结后独立 `tools/check-docs.ps1` 复跑 `DOCS PASS: 40 … 1466 …`、exit=0；三条 declared-missing 仍无人引用（DOC NOTE），清单未增未删。跑后 `git status --short` 无 `.import` 行尾改写（本轮未触导入）。
- 并发事件（交协调者判）：开工时 `git status --short` 为空、HEAD==`46ec08c`；10:26:29（+1100）另一会话在同一工作树提交 `d322e6c`（只改 `docs/spec/card-terms.md`、`docs/spec/event-pipeline.md`），与本批文件面无交集且落在首轮门禁开始之前 ⇒ 本批证据不受影响，但该树当时并非独占，派工假设与实际不符，登记备查。
- 未跑项：未跑 `-Suite all` 与 UI 回归（未改规则／界面代码）、`-Suite recipe`、`tools/check-content.ps1`（未改 `content/packs/`）、`tools/check-mutation.ps1`（未改行为面）、oracle／像素判据、性能测量、打包与安卓真机。本批改动与记录同提交（`chore(skills): move the project skills to root skills/ with ZCode discovery stubs`）；未推送、未 tag、未改版本、未开 PR。

## 2026-10-06 规范重写线重放到 PR #14 枝：整批并集（枝 `norms-on-main`，实现者）

- 域：`skills/**`＋`.zcode/skills/**`（正文迁根与 ZCode 薄桩两线并集）、根 `AGENTS.md`（重写线落点）、`docs/spec/response-pipeline.md`／`release-interface.md`／`ondemand-copy.md`（重写线裁剪与 PR #14 增量并集）、`docs/record/verification*.md`（两侧并集）、`spire-godot/tests/architecture_cases.gd`（两侧判据并集＋一处改钉）、`spire-godot/tests/mutations.json`（known_gaps 增补）、`spire-godot/core/**`＋`ui/**`（仅注释，28 文件）。
- 前置与重放：源枝 `chore/norms-rewrite` 在 `C:\1\tmp\magic-spire-wt-norms` 静止后开工（`git status --short` 空、无 Godot 进程、`build/checks/` 连续 3 分钟无新目录、HEAD 稳定）；`C:\1\tmp\magic-spire-wt-fix-on-main` 只读未动。`git rebase --onto 5d6bdc6 8e83876 chore/norms-rewrite`：源尖端 `4807bf6` 的 23 条逐条在位（主题与顺序逐条相同；`5d6bdc6..norms-on-main`＝23，`8e83876..norms-on-main`＝41＝23＋PR #14 基线 18）。两条中间提交曾把一处 `<<<<<<< HEAD` 行带入库，已用 `git filter-branch --tree-filter` 重写该范围（尖端树 `113c3121…`、`docs/record/verification.md` blob 与重写前逐字节相同）。
- 冲突（4 文件／11 处）：`.zcode/skills/spire-docs/SKILL.md`（并集：规范句约束／依赖约束索引／改动点名＋PR #13 管线邻接表段；迁移提交把正文落到 `skills/spire-docs/SKILL.md`、`.zcode` 改薄桩，桩 frontmatter 与正文 `cmp` 相同）；`AGENTS.md`（重写线落点，文档入口表三行随重写线删除）；`docs/record/verification.md`（追加并集：main 侧 161 行全留＋重写线新增条，零丢失）；`docs/spec/response-pipeline.md`（重写线逐块落点＋PR #12/#13 的 9 行手牌增量保留；被重写线整段删除的「待实现具名 check 设计」表内一行 `section_key_hit_skips_rebuild` 增补随之删除，同判据 `present_hand_incremental` 仍登记在 `docs/spec/hand-refresh-dependencies.md`）。`display_ui_cases.gd`／`ui/main.gd`／`release-interface.md` 自动合并，代码面／唯一改动行与 main 侧一致。
- 判据并集自证：`tests/architecture_cases.gd` 函数集 main 侧 95＋本线 111 全部在位（尖端 120）；`mutation_judgment_universe()` 实算判据 56 条。
- 产品面自证（剥注释比代码）：`spire-godot/core`＋`spire-godot/ui` 101 文件——28 个「注释外代码逐字节同 `5d6bdc6`」、73 个逐字节全同、0 个差异；`ui/card_face.gd`（`26b1f389…`）与 `tests/interface_ui_cases.gd`（`4ab5e39f…`）与 `5d6bdc6` blob 全同，崩溃修复与其判据字节未动。
- mutations.json：只增 `present_adjacency_graph_is_pinned`（PR #13 邻接表判据，无突变证据）入 `known_gaps`（39→40），已有条目零删除；静默／双列／幽灵均空；表内 16 条证据未动。
- 并集暴露的一处判据失配（本批修复，提交 `0f20b80`）：`ondemand_copy_consumer_boundary` 白名单含 `ui/main.gd::_hand_presentation_key`，而 PR #12/#13 手牌刷新后该节键已不直读 `card_texts`／`card_instances` ⇒ 首轮 `20261006T000942335-13228` architecture FAIL（1／4509，`ERROR: CP ondemand_copy_consumer_boundary`）；按并集改钉为 `card_entry`／`_card` 两处（等式钉不变，第三处读点仍红），`docs/spec/ondemand-copy.md` 同步两处。
- 门禁（`spire-godot/`；起前 `Get-Process Godot*` 为 0、串行单引擎；`GODOT_BIN` 显式指向 `C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；首跑前 `--headless --editor --quit` 建导入缓存，跑后 `*.import` 逐字节还原）：
  - `& tools/check-mutation.ps1 -All` → `build/mutations/20261006T001454845-43252`：16／16「RED exit-red=True restored=True」＋逐条 SHA256，`MUTATION SUMMARY: 16/16 entr(ies) reddened the named check and restored byte-for-byte; worktree unchanged=True; elapsed 893.1s`，exit 0。（前一轮 `20261006T235510599-43292` 16/16、732s 跑在改钉前的树上，不作本批结论。）
  - `& tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` → `20261006T001229735-15316`：`SUITE RESULT: architecture PASS`、`PASS: 4509 assertions`、`status=passed`、`before==after=07201B19…`、`failed=[]`、`unrun=[]`、同轮 docs 阶段 PASS（41 文件／1663 引用／允许清单 3）、exit 0。
  - `& tools/check-docs.ps1` 单跑 → `DOCS PASS: 41 rule-class document(s), 1663 reference(s) checked, allowlist 3 entrie(s)`，exit 0（不占引擎）。
  - `& tools/check-record-conservation.ps1`（迁移期脚本，不占引擎）→ `CONSERVE PASS`：三卷 identifiers=0、non_verbatim=0、headings／dates／domains=0、markers=0，允许清单 1；`verification.md` 的 20 个追加节按只追加放行。
- 未跑项：`-Suite all` 完整回归；UI 窗口分类（本批未改界面代码面与文案）；`-Suite recipe`；`tools/check-content.ps1`（未改 `content/packs/`）；安卓真机；打包、标签、推送。**本批只提交到本地 `norms-on-main`（尖端 `0f20b80`，本条记录另为一次只追加提交），未推送**；推送由协调者执行。

## 2026-10-06 回填两条索引行（`docs/spec/response-pipeline.md`，实现者）

- 域：`docs/spec/response-pipeline.md`「证据入口」索引区（+2/−0，两条索引行）；`AGENTS.md` 零改动。
- 人裁与落点判定：原载荷要求回填根 `AGENTS.md` 文档入口表一行（`手牌卡增量刷新 → docs/spec/hand-refresh-dependencies.md`），人裁**作废该处**；协调者更正指定优先落 `docs/spec/project-map.md` 的既有规格／目录清单，无合适清单时落 `docs/spec/response-pipeline.md` 的判据索引一带（与任务 2 那条并排）。判定＝`project-map.md` 的「接口（目录与入口）」表按**目录**列职责（`docs/spec/` 只有整目录一行，无逐文件清单），其「输入域」自述只收「目录职责、模块边界、相邻项目边界、文档入口的所在位置」⇒ 无合适清单可挂；改落 `response-pipeline.md`——它也是该依赖文件自述的父契约（`docs/spec/hand-refresh-dependencies.md` 开头：「当前实现与失效条件见 `docs/spec/response-pipeline.md`」），写法与该线既有依赖索引同形（对照 `docs/spec/seed-identity.md` 的「依赖约束（cleaner 可核对）见 `docs/spec/seed-feedback-dependencies.md`。」）。
- 改前（`docs/spec/response-pipeline.md`「证据入口」原有索引，原文）：`- 现行反馈检查见 `tests/impact_feedback_ui_cases.gd`；接缝 A 的调用点白名单、指令键面与单一提交入口的机读判据见 `docs/spec/candidate-removal.md` 的「判据真源」行。`
- 改后（同一处之下紧接追加两行）：`- 手牌卡增量刷新的依赖约束（cleaner 可核对）见 `docs/spec/hand-refresh-dependencies.md`。` 与 `- 手牌增量刷新的具名判据＝`tests/display_ui_cases.gd::present_hand_incremental`。`；未恢复被规范重写线删掉的「待实现具名 check 设计」整表，编号场景 1–9 未回填，无解释段。
- 行数自证：`git diff --numstat -- docs/spec/response-pipeline.md` ＝ `2 0`（只增行、零删行）；工作区自开工至门禁结束始终不含 `AGENTS.md`（`git diff --name-only` 未命中该文件，该文件逐字节未动）；本条记录只追加（同批提交 `git diff --numstat HEAD~1 HEAD` ＝ `12 0`＋`2 0`）。
- 引用存在性：`docs/spec/hand-refresh-dependencies.md` 在库；`tests/display_ui_cases.gd::present_hand_incremental` 已声明（`static func present_hand_incremental(t) -> void:`）；同轮 `check-docs` 由改前 1663 条引用（运行 `20261006T001229735-15316`）变为 1667 条、problems=0。
- 门禁（`spire-godot/`；起前 `Get-Process Godot*` 为 0、串行单引擎；`GODOT_BIN` 显式指向 `C:\\1\\Tools\\Godot\\v4.7.2-stable\\Godot_v4.7.2-stable_win64_console.exe`）：`& tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` → 运行 `20261006T012605565-19976`：`DOCS PASS: 41 rule-class document(s), 1667 reference(s) checked, allowlist 3 entrie(s)`、`DOCS RESULT: PASS`、`SUITE RESULT: architecture PASS`、`PASS: 4509 assertions`、exit 0、`summary.json` `status=passed`、`before==after=3EEC9D2A97769680EF3B315FAECBC8CF5E8C49C80E38BEA8087F5D7C51FF6E6C`、`rules.failed=[]`／`unrun=[]`／`retry=[]`／`complete=true`、无 `SOURCE CHANGED`、无 cert-store 行；随后独立 `& tools/check-docs.ps1` → 同计数、exit 0（三条 declared-missing 仍无人引用，清单未增未删）。跑后 `git status --short` 仅 `M docs/spec/response-pipeline.md`，无 `.import` 行尾改写。
- 作废的一次调用（不作证据）：首个 `tools/check.ps1` 调用在引擎定位阶段抛出 `Godot 4 was not found`（会话 `GODOT_BIN` 指向不存在的 `C:\\1\\Tools\\Godot\\v4.7-stable\\Godot_v4.7-stable_win64.exe`），未生成运行目录、未产出任何分类结果；随后显式指向 4.7.2 `*_console.exe` 重跑。
- 未跑项：`-Suite all` 完整回归；UI 窗口分类（本批零产品代码、零文案改动）；`-Suite recipe`；`tools/check-content.ps1`（未改 `content/packs/`）；`tools/check-mutation.ps1`（未改行为面）；打包与安卓真机。本地提交，未推送、未 tag、未改版本、未开 PR。

## 2026-10-04｜fact-lookup S1：登记表骨架＋判据反转

- 域：`spire-godot/core/command_registry.gd`（新建；唯一汇编点、零模块 preload）、`spire-godot/core/game.gd::_kind_facts`／`spire-godot/core/game.gd::_command_fact_row` 与登记表 table 形 arm 函数、`spire-godot/tests/architecture_cases.gd::command_registry_is_total`／`pipeline_lookup_inspect`／`command_fact_kind_lookup`、`docs/spec/fact-lookup-dependencies.md`（新建）、`docs/spec/candidate-removal.md` §2.1 T4。基线 `8544275`（PR #13 未合并）；契约见该依赖规约与 [候选层移除](../spec/candidate-removal.md) T4。
- 行为：39 条 kind 全量登记；15 条已接线 kind 逐条保留原臂与守卫（`_attack_kind_facts` 含 `target!=""` 整表分支），24 条整表语义 kind 显式点名 `_whole_table_kind_facts`，接管整表项显式点名 `command_facts`；`_kind_facts` 删 `_:` 兜底臂，未登记 kind fail-closed；`command_fact` 可行动期经 `core/command_registry.gd::point` → `_kind_facts` → 登记项来源，接管期经登记表表级项扫 `command_facts()`。不新增写入、不改文案／顺序／接管语义、不动 `REVISION`／存档／随机域。
- 检查（冻结于本次工作区，前后指纹同为 `26EC49396FBA16844116BE95C81F171178390ED648D6C997C3160B26E093A6B2`）：`tools/check.ps1 -Suite architecture` `20261004T124827859-48324`（architecture PASS 5244 断言、docs PASS、exit 0）；`tools/check.ps1 -Suite core -Impact -TimeoutSeconds 1800` `20261004T123804754-52020`（18 分类全 PASS、18029 断言、145.34s、exit 0）；`tools/check.ps1 -UIOnly -UISuite display,targeting,body_layout -KeepGoing` `20261004T124046353-46516`（display／body_layout／targeting PASS、UI PASS 1385 断言、152.39s、exit 0）；`tools/check-docs.ps1`（36 规则文档 2614 引用、允许清单 6 条不变、exit 0；以上各轮内亦 PASS）。各轮 `summary.json` `status=passed` 且 `before==after`，无 `SOURCE CHANGED`。
- 行等价覆盖：`T4 ROW EQUIVALENCE cells=7 rows=894 kinds=15`（战斗 0／12／26／44、整备 0、休息 0、接管 0），删去原 `T4_WIRED_KINDS` 过滤后逐行比对，接管单元经登记表表级项取行。
- 首轮 `20261004T123654311-34932` 的规则阶段 PASS（5244），但 docs 阶段 FAIL：新依赖规约里的 `tests/architecture_cases.gd::FactSourceCountingGame` 是 GDScript 内层 `class`，`tools/check-docs.ps1` 只识别 `class_name`／func／var／const／signal／enum 声明，故该锚点判为未声明。改为非锚点写法（路径＋纯文本名）后按原范围重跑；该轮不作冻结证据，指纹相等但 `status=failed`。
- 敏感性证明（每次为一次性变异→红，还原后复跑绿；源码 md5 还原前后一致：`core/game.gd` `5e95a09fdd7f8c42f8654c5399f046f4`、`core/command_registry.gd` `6a1f301183e3cb3e95b3b21ddaace02d`）：①删登记项 `card` → `command_registry_is_total` 红 `20261004T124343687-3436`（missing=["card"]；同轮 619/5244），还原绿 `20261004T124421125-9716`；②恢复 `_kind_facts` 的 `_:` 兜底臂 → 「无兜底」两条源码断言红 `20261004T124512228-28236`（该变异不改变行为，唯源码文本断言可抓），还原绿 `20261004T124602063-33144`；③临时给 `COMMAND_KEYS` 加 `no_such_new_kind` → 三条 `command_registry_is_total` 断言红 `20261004T124651601-53296`，还原绿 `20261004T124741247-59724`。
- 依赖表文件面与实际改动逐文件一致：`core/command_registry.gd`（含引擎生成的旁文件 `core/command_registry.gd.uid`）、`core/game.gd`、`tests/architecture_cases.gd`、`docs/spec/fact-lookup-dependencies.md`、`docs/spec/candidate-removal.md`、`docs/record/verification.md`。
- 未验证：S5／S2／S3／S4 未开工（`POINT_KINDS` 为空集，39 条全 table 形）；`-Suite all` 完整回归、`-VerifyRunner`、其余 UI 模块、安卓真机、打包与发布未跑。`docs/spec/candidate-removal-dependencies.md` 的 T4 旧措辞（「未接线 kind 仍走 `_fact_source`」）与 §1.6 D-4 行不在本批授权文件面内，未改，交协调者。独立审查与清洁不在本记录内。

## 2026-10-05｜fact-lookup S1 清洁：文档同步；整轮门禁未通过

- 域：对象 `3b81479`、基线 `8544275` 的事实出口登记表、具名 table 来源与 S1 判据；本批仅改 `docs/spec/fact-lookup-dependencies.md`、`docs/spec/candidate-removal.md` §1.6 D-4／§2.1 T4、`docs/spec/candidate-removal-dependencies.md` 的核心面 T4 措辞，并追加本记录。最新清洁任务已授权两处旧措辞并入 S1，优先于临时计划中的旧 S5 裁定。规划文件未改。
- 实现核对：15 条原臂逐条对照 diff，attack 的非空 target 整表分支、各阶段／域守卫及来源顺序保持；五个既有函数体（flask／flow／item_use／phase_action_tail／fact_source_domain）文本相同。39 项全为 table，24 项统一指向 whole_table 来源；忽略参数用于统一调用签名，无 kind 特例或仅为单个 kind 设置的死参数。登记表无模块 preload、Callable 对象或 state 写入。未发现需要修改产品代码的结构缺陷。
- 可维护性证据：函数体分支词数（if／for／match，去注释）`_kind_facts` 11→1，`_command_fact_row` 7→6；此为文本代理度量，不作 CRAP 或完整复杂度门禁宣称。项目未选定本片专用复杂度阈值检查器。临时检查脚本在工作区 `tmp/s1-cleaner-inspect.py`。
- 判据核对：C1 覆盖双向 missing／extra、39 数量、显式 form、g 方法存在性、同差集函数合成自检；POINT_KINDS 空、table_kinds 运行期派生。旧 15 kind／t4_wired_row 过滤由所有夹具行等价替代，保留 G2／G6；unwired_keys 与兜底断言由全量登记、无兜底、运行期 fail-closed 替代。L-point／L-table 两边及其余查找断言自洽，接管与 relic_bundle／departure 显式点名。当前运行仍报 7 cells／894 rows／15 kinds；未称覆盖所有状态下全部 39 kind。三次 S1 敏感性实验复用上一条实现记录，本批不修改判据、不重做突变。
- 文档修正理由：依赖表漏列 `core/command_registry.gd.uid`，补入；补入本批新授权文档面；替换 D-4 的候选 id 旧语义及依赖表「未接线 kind」旧措辞；T4 明写接管整表例外。均为描述实际源码与文件面，无运行行为变化。实际 S1 增量面共 8 文件（相对 8544275，含 UID 旁文件与本批新增修改的候选依赖表）。独立只读 agent `s1_docs_review` 对三份契约文档 diff 与指定源码接口审查 PASS，无缺陷；未启动第二个引擎。
- 串行检查：使用 Godot 4.7.2 console，起下一轮前确认 Get-Process Godot* 为空。`tools/check.ps1 -Suite architecture`，运行 `20261004T130021447-45260`：architecture PASS 5244；`tools/check.ps1 -Suite core -Impact -TimeoutSeconds 1800`，运行 `20261004T130134668-36668`：18 分类全 PASS、18029 断言。两轮 docs PASS，before==after，无 SOURCE CHANGED；但两轮均出现 `ERROR: Failed to read the root certificate store.`，脚本退出码 1、summary status=failed（引擎 exit=0），不得记为整轮通过。`tools/check-docs.ps1` 单跑 exit 0，36 文档／2619 引用／允许清单 6 条不变。日志保留于上述 build/checks 运行目录。
- 未决／未建：证书环境失败超出清洁授权面，交回协调者处理后重取整轮证据；既有 COMMAND_KEYS（参数形状）与 UI ROUTES（前端路由）各列 39 kind，未新增第二份事实生产者映射，但若“无第二份 39 kind 名单”按字面也禁止这两表，则与本批契约及 UI 禁改边界冲突，须协调者裁定。完整依赖表文件面、登记表零 preload／只读限制及所有登记来源邻接边逐边敏感性的专用机械检查未建；现有 C1／pipeline_lookup_inspect 只守卫其具名子集，本批文本核对不能代替完整检查器。
- 未验证：本批未跑 UI、all、VerifyRunner、安卓真机、打包或发布；S5／S2／S3／S4 未开工。不宣布本职能完成。

- 本地提交阻挡：git add exit 128，无法创建主仓库 .git/worktrees/magic-spire-wt-fact-lookup/index.lock（Permission denied）；当前沙箱未授予该 git 元数据目录写权限，未提权、未绕过。本批四份文档修改未暂存／未提交，HEAD 仍为 3b81479。

## 2026-10-05｜fact-lookup S1 收尾：非沙箱整轮复跑、文档面提交、来源身份判据与接管变异取证

- 域：事实出口登记表与 S1 判据（`core/command_registry.gd`、`core/game.gd::_kind_facts`／`core/game.gd::_command_fact_row`、`tests/architecture_cases.gd`、`docs/spec/fact-lookup-dependencies.md`）。本批只改 `spire-godot/tests/architecture_cases.gd`（R4 补件）并追加本记录；产品源码逐字节未改（`core/game.gd` md5 `5e95a09fdd7f8c42f8654c5399f046f4`、`core/command_registry.gd` md5 `6a1f301183e3cb3e95b3b21ddaace02d`，与 S1 实现记录的还原值一致）。
- R2 非沙箱复跑（普通 shell，非 codex 沙箱；`GODOT_BIN` 指向 Godot 4.7.2 `*_console.exe`；每轮起前 `Get-Process Godot*` 为空，同一时间只跑一个引擎进程）：`tools/check.ps1 -Suite architecture` 运行 `20261004T130826726-63348`，architecture PASS 5244、exit 0、`summary.json status=passed`、`before==after`、无 `SOURCE CHANGED`、日志无 `Failed to read the root certificate store.`；`tools/check.ps1 -Suite core -Impact -TimeoutSeconds 1800` 运行 `20261004T130917045-28336`，18 分类全 PASS、18029 断言、exit 0、`status=passed`、`before==after`、无 `SOURCE CHANGED`、无证书错误；`tools/check-docs.ps1` 单跑 exit 0（36 文档／2619 引用／允许清单 6 条不变）。⇒ 沙箱两轮（`20261004T130021447-45260`／`20261004T130134668-36668`）的证书错误确认为执行环境产物，S1 整轮证据以本行为准。
- 文档面提交 `0636918`（`docs(spec): sync the fact-lookup dependency face and stale lookup wording`；`docs/spec/fact-lookup-dependencies.md`、`docs/spec/candidate-removal.md`、`docs/spec/candidate-removal-dependencies.md`、`docs/record/verification.md` 共 4 文件）；提交前 `git diff --name-only` 仅这 4 份，依赖规约文件面与实际改动逐文件一致。
- R4 补件（`tests/architecture_cases.gd`，登记进 `run`）：新增具名 check `fact_source_map_is_pinned`——39 条 kind → table `source` 的期望侧以字面表 `FROZEN_TABLE_SOURCES` 写在测试内（不取自 `CommandRegistry`／`core/game.gd`，防自证），逐条与登记项相等，missing／extra 双向报；另钉 `FROZEN_TAKEOVER_SOURCE="command_facts"`。`POINT_KINDS` 仍为空集，本批只校 39 条 table 形；S2／S3 转 point 形时按批从该表移除该 kind。断言计数 5244 → 5247。
- 敏感性证明（一次性变异→具名红，还原后复跑绿；产品源码 md5 还原前后一致）：①把 `core/command_registry.gd` 里 `flask` 的 `source` 临时改成 `_whole_table_kind_facts` → 运行 `20261004T131331560-42520`，`fact_source_map_is_pinned` 红（`["flask=table/_whole_table_kind_facts want=table/_flask_kind_facts"]`）＋ `T4 flask command_fact still scans the full table` 红（2/5247 断言）；还原后运行 `20261004T131418947-50692` 全绿 5247。②C9 空白项：把 `core/game.gd::_command_fact_row` 的接管分支改走 point 形（绕开接管整表扫描）→ 运行 `20261004T131512221-54400`，82/5247 断言红：`pipeline_lookup_inspect: the takeover branch takes its table item from the registry` ＋ 81 条 `T4 command_fact matches the full-table row … fixture=takeover:0`（接管标注 automated／control_next 丢失）；该变异只改点查询、不改 `command_facts()` 表，故 G6 不红；`FirstTurnControl.select` 标注顺序变异未做（本批取接管分支一例）。还原后运行 `20261004T131605103-52772` 全绿 5247。
- 收尾复跑（测试面改动后）：`tools/check.ps1 -Suite core -Impact -TimeoutSeconds 1800` 运行 `20261004T131650898-9464`，18 分类全 PASS、18032 断言、exit 0、`status=passed`、`before==after`、无 `SOURCE CHANGED`、无证书错误；`tools/check-docs.ps1` 单跑 exit 0（36／2619／6 不变，未新增允许清单条目）。
- 未验证：S5／S2／S3／S4 未开工（`POINT_KINDS` 为空集）；`-Suite all` 完整回归、`-VerifyRunner`、UI 模块、安卓真机、打包与发布未跑。独立审查与清洁不在本记录内。

## 2026-10-05｜fact-lookup S5：每提交只查一次事实出口（dispatch 直出判定行）

- 域：`spire-godot/core/game.gd::dispatch`（成功结果新增 `fact`＝本次提交的判定行／display fact；失败与未判定为 `{}`）、`spire-godot/ui/main.gd::_submit`（删除提交前的 `command_fact(cmd)`，改读 `result.get("fact",{})` 取 `payload`；`payload` 取用点不变）、`spire-godot/tests/architecture_cases.gd`（C5／C10 判据、计数子类 `SubmitLookupCountingGame`、`r1_build` 可选 `game_class` 参数、G6 冻结值重算）、`docs/spec/candidate-removal.md` §3.1 M-III、`docs/spec/response-pipeline.md` 接缝 A、`docs/spec/fact-lookup-dependencies.md`、本记录。O7 由人批准（协调者 2026-10-04 裁定）。
- 行为：`dispatch` 五条预检顺序、`error` 文案、版本比对、事务副本与全回滚、`version` 自增、执行分支、`get_view` 调用点白名单逐字不变；成功键面 `{ok, version, resource_feedback, card_feedback, music_feedback, checkpoint, spell_failed, fact}`（`fact` 为新增；`spell_failed` 为清单原本漏写的既有键，S5 同批补齐文档），失败键面 `{ok, error, fact:{}}`。`ui/main.gd::_submit` 体内不再出现 `command_fact(`。
- 前置核实（超出计划的发现，按“先报告再动”交协调者裁）：`tests/architecture_cases.gd::r1_record` 的 `submit_keys`＝成功 `dispatch` 结果键面摘要，计入 `r1_record_digest` 与 G6 冻结 `<record>`，故 plan §5“预计 0 处迁移”与 O7 的“无返回键面断言”证据不完整；其余 `.dispatch(` 调用点只读 `.ok` 与具名字段，`tests/` 其余文件 0 处迁移。裁定（2026-10-05）：允许显式重算 `submit_keys` 与派生 `<record>`（26 cell），mask 不变。
- 检查（串行单引擎，`GODOT_BIN` 指向 Godot 4.7.2 `*_console.exe`，起下一条前 `Get-Process Godot*` 为空；冻结源码指纹 `3A20BE2A47895000069ABE97273D000985249F90C9BF0CF495878B634AC0CF87`）：`tools/check.ps1 -Suite architecture` 运行 `20261004T133650050-17120`（architecture PASS 5327、docs PASS、exit 0）；`tools/check.ps1 -Suite core,persistence -Impact -TimeoutSeconds 1800` 运行 `20261004T133847011-9004`（38 分类全 PASS、26901 断言、556.98s、exit 0）；`tools/check.ps1 -UIOnly -UISuite display,targeting,keyboard,home -KeepGoing -TimeoutSeconds 1800` 运行 `20261004T135403277-52288`（display／keyboard／home／targeting PASS、UI PASS 1392、214.47s、exit 0）；`tools/check-docs.ps1` 单跑 exit 0（36 规则文档／2621 引用／允许清单 6 条不变，未新增条目）。三轮 `summary.json` 均 `status=passed` 且 `before==after`，无 `SOURCE CHANGED`，日志无 `Failed to read the root certificate store.`。
- C5 计数（用例打印，见 architecture 日志）：12 次真实成功提交（夹具 battle:0／battle:12／prepare:12／prison:12 × kind end／wall_move／posture／card／prison）均 `S5 SINGLE LOOKUP ... command_fact: dispatch=1 submit=0`（`submit`＝`ui/main.gd::_submit` 源码级调用数）；成功结果键面打印 `S5 DISPATCH KEYS before=["ok","version","resource_feedback","card_feedback","music_feedback","checkpoint","spell_failed"] after=[… ,"fact"]`。失败路径：陈旧 version 0 次（文案＝冻结基线 `reject_stale`）、形状不合法（未登记 kind／声明外参数键）0 次、判定不通过 1 次且文案＝基线 `reject_invalid`（「已经贴墙。」／「姿态必须依次经过坐姿，不能直接跨越。」），三者 `export_snapshot()` 相等且结果键面＝`{ok,error,fact}`。
- C10 呈现输入：`S5 PRESENTED FACT compared=6`——同一夹具双份构造，旧行为（提交前 `command_fact`）的行与 `dispatch` 返回的 `fact` 逐字段相等、`JSON.stringify` 逐字节相等、两次提交结果字典相等、`export_snapshot()` 相等；另锁 `ui/first_turn_presenter.gd::outcome`：按签名取第四参数名并断言其函数体不出现该标识符（body 提取自源码、去注释）。
- G6 显式重算（原因＝O7 批准的 `fact` 键；范围＝仅 `submit_keys`／派生 `<record>`，26 cell；mask 与其余记录字段、其余断言不变）：取值轮 `20261004T132858869-47944`（首次 26 cell 全红，均 `<record>` 路径），自证轮 `20261004T133011360-19112` 打印 `record_with_old_key_face`，与旧冻结值逐 cell 相等（26／26）⇒ 差异只来自新增的一个键；重算值写入 `tests/architecture_cases.gd::R5_BASELINE` 并加声明注释；自证打印为一次性临时码，冻结轮前已移除。冻结轮 `20261004T133650050-17120` 起 G6 全绿。plan §5 的“预计 0 处迁移”作废（协调者 2026-10-05 裁定）。
- 敏感性证明：把 `ui/main.gd::_submit` 的提交前 `command_fact(cmd)` 恢复（并把 `row` 取回预查询值）→ 运行 `20261004T133447298-50404`，C5 两条源码级判据红（`has no pre-submit command_fact( call have=1`、`takes the judgement row from the dispatch result`），打印变为 `command_fact: dispatch=1 submit=1`；还原（`ui/main.gd` md5 `42ab989c60b879dd9261e926940be3b5`，与变异前快照一致）→ 运行 `20261004T133650050-17120` 全绿 5327。运行期计数由测试侧子类承担（生产源码不带计数器）；architecture 分类无 UI 驱动，`_submit` 侧计数以源码级判定为准，UI 真实提交路径由 display 模块既有用例覆盖。
- 依赖表文件面与实际改动逐文件一致：`core/game.gd`、`ui/main.gd`、`tests/architecture_cases.gd`、`docs/spec/candidate-removal.md`、`docs/spec/response-pipeline.md`、`docs/spec/fact-lookup-dependencies.md`、本记录。产品源码 md5：`core/game.gd` `ff62e686506b54d08b0c8e94ad506af1`、`ui/main.gd` `42ab989c60b879dd9261e926940be3b5`、`tests/architecture_cases.gd` `c88a6621e2dccc85477a51a5b244deda`。
- 失败轮与不作证据的轮：`20261004T132858869-47944`／`20261004T133011360-19112`（重算取值与自证，G6 未重算前必红，且带一次性打印）；`20261004T134832114-54184` 为 UI 首轮，默认 300s 超时于 home 前中断（display／keyboard 已 PASS），按原范围加 `-TimeoutSeconds 1800` 重跑，超时轮不作整轮证据；`20261004T133158305-47872` 是文档面改动前的 architecture 绿轮，不作最终冻结证据。
- 未验证：`-Suite all` 完整回归、`-VerifyRunner`、UI 其余模块、`normal_play`、安卓真机、打包与发布未跑；S2／S3／S4 未开工（`POINT_KINDS` 仍空集）。独立审查与清洁不在本记录内。

## 2026-10-05｜fact-lookup S2：attack 直出＋双向等价 harness

- 域：`spire-godot/core/game.gd`（攻击域 point 登记项与 View 生产者）、`spire-godot/core/witch_character.gd`（巫女单行构造）、`spire-godot/core/command_registry.gd`（point 分支）、`spire-godot/tests/architecture_cases.gd`（C3／C4／C6／C7 判据）、`docs/spec/fact-lookup-dependencies.md`、本记录。契约：该依赖规约＋切片计划 §3／§5 S2 行；O3 照裁（`keys(g)` 是该 kind 候选键的唯一枚举实现）。
- 行为：新增 `core/game.gd::attack_point_keys`（三家族＝基础／巫女／装备自解，顺序＝转换前 `attack_facts`＋`equipment_spell_facts` 的表序，不重排）、`core/game.gd::attack_point_fact`（把 params 解析到该家族具体键并复用既有单行构造，非成员返回 `{}`）、`core/game.gd::attack_point_member`；`attack_facts`／`equipment_spell_facts` 体内改为同登记项 keys × build 的家族取用（`target` 空／非空），装备自解循环体提为 `core/game.gd::_equipment_spell_fact(target,factor,usage)`，巫女循环体提为 `core/witch_character.gd::attack_offer_fact(g,enemy,part,form)`；`attack` 转 point 形后 `_attack_kind_facts` 删除；`core/command_registry.gd::point` 增 point 分支（member 为真再 build）。不写 `state`、不产事件、不推进随机、不改 `version`；无第二套枚举或构造；未动 `ui/`／`data/`／`tools/`。
- 登记面：`POINT_KINDS=["attack"]`；`FROZEN_TABLE_SOURCES` 只删 `attack` 一行（38 条 table）；新增 `FROZEN_POINT_METHODS`（期望侧写在测试内）钉 `attack` 的 `keys`／`build`／`member` 三个方法名，`fact_source_map_is_pinned` 扩到 point 形并双向报 missing／extra；打印 `FACT SOURCE MAP PINNED kinds=38 takeover=command_facts point=1`。
- 检查（串行单引擎，`GODOT_BIN` 指向 Godot 4.7.2 `*_console.exe`，起前 `Get-Process Godot*` 为空；冻结源码指纹 `84ED12CC5DE702EA65A493AF810C7DFC11E9FD07FF0E34B03770C46D56842B3A`）：`tools/check.ps1 -Suite architecture` 运行 `20261004T150158000-29212`（architecture PASS 9743、docs PASS、exit 0）；`tools/check.ps1 -Suite basic_attacks,witch_character -Impact -TimeoutSeconds 1800` 运行 `20261004T150308190-37368`（witch_character／card_expansion／card_splash／basic_attacks／status／enemies 全 PASS、5377 断言、69.14s、exit 0）；`tools/check.ps1 -UIOnly -UISuite display,basic_attacks,casting,body_layout -KeepGoing -TimeoutSeconds 1800` 运行 `20261004T150430175-61824`（display／basic_attacks／casting／body_layout PASS、UI PASS 1526、192.91s、exit 0）；`tools/check-docs.ps1` 单跑 exit 0（36 规则文档／2623 引用／允许清单 6 条不变，未新增条目）。三轮 `summary.json` 均 `status=passed` 且 `before==after`，无 `SOURCE CHANGED`，日志无 `Failed to read the root certificate store.`。S1／S5 既有判据仍全绿：G2、G6、全 kind T4 行等价（`T4 ROW EQUIVALENCE cells=7 rows=894 kinds=15`）与 `S5 SINGLE LOOKUP … dispatch=1 submit=0`／`S5 PRESENTED FACT compared=6` 均在本轮 PASS。
- C3／C4（双向等价 harness，`tests/architecture_cases.gd::fact_lookup_equivalence`，期望侧独立：方向①只取该状态 `command_facts()` 的表行，方向②只做表内归一化成员扫描；变异语料由测试侧按字段级替换独立构造）：30 个夹具＝r1_cells 全矩阵（26）＋`t4_dense_51`＋非战斗阶段（prepare:12＋装备自解 buff）＋巫女角色夹具＋显式重复夹具；合计 `dir1_rows=163`、`dir2_mutations=1793`、`keys=154`、`member=1956`；逐家族覆盖 `{ basic:135, self_release:12, witch:16 }`（三类均 > 0，为 0 即红）。方向②的变异语料覆盖不存在 id／未注册 type／越界 form／布尔取反／清空必填／x 与 charge_action 组合，接受与否与表内成员关系逐条同真同假。显式重复夹具（把第二个存活敌人的 id 换成第一个）枚举出 9 条重复归一化 params，方向①按「枚举序首条」比对通过；注：`build` 是 params 的纯函数（按 id 解析到首个对象），攻击域重复 params 必然收敛到同一行内容，故该夹具证明的是「返回首条」而非内容可区分。
- C6（`attack_point_lookup_reads_one_row`，源码文本＋计数子类 `AttackLookupCountingGame`，生产源码不带计数器）：`attack_point_fact`／`attack_point_member` 体内无 `_fact_source(`／`attack_facts(`／`equipment_spell_facts(`／`attack_point_keys(`；三个家族夹具各取一条真实 attack 行做点查询，打印 `ATTACK POINT LOOKUP fixture=battle:0|prepare:12+self_release|witch:battle whole_table_calls attack_facts=0 equipment_spell_facts=0 _fact_source=0`。
- C7（gherkin S2-3）：该 kind 的表行序列逐项等于 `keys` 的点构造投影（接管期表行带 `select` 标注，跳过该步）；仅一致性检查，不替代 C3／C4，两侧同时改坏的抓取面仍是 G6。
- 冻结表 diff：`FROZEN_TABLE_SOURCES` 仅移除 `"attack":"_attack_kind_facts"` 一行；`POINT_KINDS` 仅由空集改为 `["attack"]`；另新增 `FROZEN_POINT_METHODS`（三字段名，字面写在测试内）。
- 敏感性证明（每次一次性变异→红，还原后复跑绿；产品源码 md5 还原前后一致：`core/game.gd` `58E2A2C6827AB36279F0DBE9A8CAEC14`、`core/witch_character.gd` `27FA492696DB3DBBFAECECE0026A88ED`、`core/command_registry.gd` `89ff7477a4dad3dec55ce2e32c1417ad`、`tests/architecture_cases.gd` `0e3bf758ac49b818118a166aed0a2080`）：①让 attack 点路径回落整表（`attack_point_member` 内改为对 `_fact_source()` 全表扫描）→ 运行 `20261004T143711291-56708`，C6 四条断言红（1 条源码文本＋3 条运行期计数），还原后运行 `20261004T144423883-52020` 全绿 7950。②把 build 的显示字段改错（`attack_point_fact` 内置 `row.brief`）→ 运行 `20261004T144642022-33436`，G6 `behavior_baseline_equivalence` 红（1 条，首个差异 battle:0 的 `<record>`／`facts_text`）；**方向①在本结构下不红**——View 生产者已由同一 build 派生，`build` 改错会同时移动表与点查询两侧，这正是 acceptance §1.1 第 3 条预告的盲区，抓它的是 C8 冻结摘要；还原后运行 `20261004T144901459-43260` 全绿 7950。为证方向①有判别力，另做两件：②b 让 build 忽略请求的 enemy id → 运行 `20261004T145120279-27244`，harness「每个枚举键都在表里」62 条＋T4 行数 4 条＋G6 1 条共 67 条红；随后 ②c 让 View 生产者旁路改坏显示字段（`equipment_spell_facts` 内 `row.brief`）→ 运行 `20261004T145408172-21664`，方向①（12 条）＋方向②投影（12 条）＋C7 一致性（1 条）＋C6 运行期（1 条）共 26 条红；两件一并还原后运行 `20261004T145627483-35104` 全绿 7950；③让 `member` 接受不存在的 id（`enemy=="missing_enemy"` 直接返回 true）→ 首次在旧 harness 下运行 `20261004T145815673-33436` **全绿**：`point` 由 member∧build 组成，build 会掩盖过宽的 member，故 harness 补强——对每个变异向量直接问 `member` 并断言其等于 `keys` 的归一化集合（plan §3 不变量 5），补强后绿轮 `20261004T145948798-45628`（9743 断言），重做该变异运行 `20261004T150051446-57080`，151 条 `member equals the keys set on the mutation` 红；还原后运行 `20261004T150158000-29212` 全绿 9743。
- 失败轮与不作证据的轮：`20261004T141413199-45368`（首轮，依赖文档尚引用 `_attack_kind_facts` 故 docs FAIL，且重复夹具断言口径未定）、`20261004T142400235-47700`（首个回落变异写成 `attack_point_fact` 调 `attack_facts()`，与 View 生产者互相递归致栈溢出，隔离级失败，非判据证据）、`20261004T145815673-33436`（③在补强前的绿轮，暴露 harness 盲区，列为证据的一部分而非通过）。
- 依赖表文件面与实际改动逐文件一致：`core/command_registry.gd`、`core/game.gd`、`core/witch_character.gd`、`tests/architecture_cases.gd`、`docs/spec/fact-lookup-dependencies.md`、本记录。产品源码 md5：`core/game.gd` `58E2A2C6827AB36279F0DBE9A8CAEC14`、`core/witch_character.gd` `27FA492696DB3DBBFAECECE0026A88ED`、`core/command_registry.gd` `89ff7477a4dad3dec55ce2e32c1417ad`、`tests/architecture_cases.gd` `0e3bf758ac49b818118a166aed0a2080`。
- 未验证：S3／S4 未开工（`POINT_KINDS` 只含 `attack`）；`-Suite all` 完整回归、`-VerifyRunner`、UI 其余模块、`normal_play`、安卓真机、打包与发布未跑。独立审查与清洁不在本记录内。

## 2026-10-04｜fact-lookup S3：card 直出＋双向等价 harness

- 域：`spire-godot/core/card_effects.gd`（card 域 point 登记项与 View 生产者）、`spire-godot/core/command_registry.gd`（`card` 转 point 形）、`spire-godot/core/game.gd`（三个登记面转发）、`spire-godot/tests/architecture_cases.gd`（C3／C4／C6／C7 与分支覆盖判据）、`docs/spec/fact-lookup-dependencies.md`、本记录。契约：该依赖规约＋切片计划 §3／§5 S3 行；O2／O3 照裁（`keys(g)` 是该 kind 候选键的唯一枚举实现；`SPECS` 不放 Callable）。协调者 S3 定向要求（member 独立谓词、守卫逐条对应、重复收敛不过度声明）随本批落地。
- 行为：新增 `core/card_effects.gd::card_point_keys`（该 kind 候选键的唯一枚举：`free_slots` 前缀不早退 → `self_faces`／`single_face` 早退 → 捕缚家族（`can_target_bind`＋`CaptureBind.has_bind`）→ 槽位走查；顺序与去重逐条复现转换前 `core/card_effects.gd::card_facts`）、`core/card_effects.gd::_card_point_sites`（逐分支族条件与跳过条件的唯一落点）、`core/card_effects.gd::card_point_fact`（点构造：解析到该族唯一 payload 并复用既有单行构造）、`core/card_effects.gd::card_point_member`（独立谓词：阶段守卫＋候选键成员判断，体内不调用 `card_point_fact`／`_target_fact`／`g._fact`，点查询只构造一次行）、`core/card_effects.gd::_card_slot_walk`（槽位走查：声明外槽位不查询、`seen_special` 跨槽去重、空目标补位、`bound_modes` 无目标跳过、自由面与 `free_slots` 互斥）、`core/card_effects.gd::_target_choices`／`core/card_effects.gd::_target_fact`（exhaust_hand 选择展开与单行构造，`core/card_effects.gd::target_facts` 改为经二者复用，签名与产出不变）；`card_facts` 改为同一枚举（该手牌切片）× 同一 build。按卡取切片而非整手 keys：既有 `tests/architecture_cases.gd::card_facts_keyword_min_query` 的 strong_elbow 断言要求按卡取行时不得查询其他手牌槽位，整手 keys 形态会使该断言变红，故候选键与 View 生产者共用 `core/card_effects.gd::_card_point_card_keys` 一处实现。`core/game.gd` 新增 `card_point_keys`／`card_point_fact`／`card_point_member` 三个登记面转发（登记项只存 `g` 上的方法名，唯一实现在 `core/card_effects.gd`，转发不含逻辑）；`core/command_registry.gd` 的 `card` 改 `{"form":"point","keys":"card_point_keys","build":"card_point_fact","member":"card_point_member"}`。不写 `state`、不产事件、不推进随机、不改 `version`；未动 `ui/`／`data/`／`tools/`，未改任何数值与文案；`_phase_facts` 手牌循环调用点保留（行序与条数同转换前）。
- 登记面：`POINT_KINDS=["attack","card"]`；`FROZEN_TABLE_SOURCES` 只删 `card` 一行；`FROZEN_POINT_METHODS` 加 `card` 的 keys／build／member（期望侧字面写在测试内、不取自登记表）；打印 `FACT SOURCE MAP PINNED kinds=37 takeover=command_facts point=2`。冻结表 diff 仅这三处。
- 检查（串行单引擎，`GODOT_BIN` 指向 Godot 4.7.2 `*_console.exe`，每轮起前 `Get-Process Godot*` 为空；冻结源码指纹 `3D01315A7A3FEA910C664D475B7DBF418243C319D6A9E6D9555DE698F4AD9ABF`）：`tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` 运行 `20261004T161815375-58948`（architecture PASS 80159、docs PASS、exit 0）；`tools/check.ps1 -Suite card_power,card_growth,casting,consumables -Impact -TimeoutSeconds 2400` 运行 `20261004T162101496-54608`（23 分类全 PASS：witch_character／card_power／card_expansion／relics／card_splash／card_growth／consumables／basic_attacks／architecture／curses／encyclopedia／exploration／slip_motion／casting／special_equipment／action_copy／status／rewards／core／prison／pressure／enemies／trader，96981 断言，411.59s，exit 0）；`tools/check.ps1 -UIOnly -UISuite display,targeting,body_layout,hand_assist -KeepGoing` 运行 `20261004T162822535-22884`（display／hand_assist／body_layout／targeting PASS、UI PASS 1394、179.80s、exit 0）；`tools/check-docs.ps1` 单跑 exit 0（36 规则文档／2644 引用／允许清单 6 条不变，未新增条目）。三轮 `summary.json` 均 `status=passed` 且 `before==after`，无 `SOURCE CHANGED`，日志无 `Failed to read the root certificate store.`。既有判据仍全绿：G2、G6、全 kind T4 行等价（`T4 ROW EQUIVALENCE cells=7 rows=894 kinds=15`）、S5 计数与 `S5 PRESENTED FACT compared=6`、`ATTACK FACT LOOKUP` 家族覆盖不变。
- C3／C4（`tests/architecture_cases.gd::fact_lookup_equivalence`，期望侧独立：方向①只取该状态表行、方向②只做表内归一化成员扫描；变异语料由测试侧按字段级替换独立构造）：20 个 card 夹具＝0／12／26／44 件 × 战斗／监狱／整备（12）＋分支族（battle:26、prison:26）＋`exhaust_fallback`（breath_control 顶层／ready_to_strike 面级）＋捕缚（drone_solo 真实捕缚流程）＋特殊装备跨槽＋空目标补位＋重复归一化 params；合计 `dir1_rows=2502`、`dir2_mutations=28932`、`keys=2490`、`member=31434`、`duplicates=12`、`distinct=0`。逐分支族覆盖（为 0 即红）`CARD FACT LOOKUP … branches={ target_slots:2426, free_slots:21, exhaust_hand_select:580, self_faces:46, bound_modes:106, x_cost:4, single_face:2, exhaust_hand_fallback:15, bind:7 }`——七个声明字段族（free_slots／self_faces／single_face／bound_modes／target_slots／exhaust_hand／x_cost）全部 > 0，`bind` 分支与 exhaust_hand 选择／回退两个正例亦 > 0。声明外槽位不产生行：分支夹具的 strong_elbow 键面全部落在 `target_slots` 内（`tests/architecture_cases.gd::card_facts_declared_slots`／`card_facts_keyword_min_query` 原断言同轮仍绿）；特殊装备跨槽夹具（crotch_rope_low 同一实例占 special_3_a／special_3_b）只保留走查序首槽 `special_3_a` 一项，后一槽向量被 `command_fact` 与 member 同时拒绝；空目标补位夹具（单侧手掌）同槽枚举实件与补位空目标，两个收敛夹具表内 `(kind,params)` 唯一。重复归一化 params 夹具（同 uid 第二张手牌）`duplicates=12`／`distinct=0`：build 是 params 的纯函数，故该夹具证明的是「点查询返回枚举序首条」这一引用性，不声称内容收敛。
- C6／C7：`tests/architecture_cases.gd::card_point_lookup_reads_one_row` 源码文本（`core/card_effects.gd::card_point_fact`／`core/card_effects.gd::card_point_member` 体内无 `card_facts(`／`_fact_source(`／`card_point_keys(`；member 体内无 `card_point_fact(`／`_target_fact(`／`_fact(`）＋运行期计数（测试侧子类 `FactSourceCountingGame`；`core/card_effects.gd::card_facts` 是静态函数、运行时无法经 g 计数，故该函数由源码文本判据覆盖）打印 `CARD POINT LOOKUP fixture=battle:12|branch:prison:26|exhaust_fallback:breath_control whole_table_calls _fact_source=0`；C7 一致性「表行 = keys × build」在 20 个夹具逐项通过。`core/card_effects.gd` 的源码提取新增测试侧 `tests/architecture_cases.gd::source_static_func_body_code`（既有 `source_func_text` 只认行首 `\nfunc `，对全 static 的文件会取到文件尾，导致 C6 文本判据假红）。
- 敏感性证明（每次一次性变异→具名红，还原后复跑绿；`core/card_effects.gd` md5 还原前后一致 `ccf325409b9d8ab0ac6a9bba839d766c`）：①点路径回落整表（member 内扫 `_fact_source()`＋build 内扫 `card_point_keys()`）→ 运行 `20261004T160246678-62748`，C6 三条红（build 源码文本、member 源码文本、运行期 `_fact_source` 计数＝exhaust_fallback 样本）3/80159，还原后运行 `20261004T160656010-6896` 全绿 80159；把 `_fact_source()` 注入 build 的首版使 `_fact_source → card_facts → card_point_fact` 互相递归、隔离级失败（运行 `20261004T154559494-31576` 被中止，6.1GB 日志已删，不作证据），与 S2 记录的同类现象一致。②解析错键（`card_point_fact` 槽位分支改取走查首项、忽略请求槽位／目标）→ 运行 `20261004T160959505-63860`，方向①「每个枚举键都在表里」2363 条红（该轮 16372 断言时中止）；如实记录：该变异被方向①抓到。③View 侧旁路改坏显示字段（`card_facts` 内 `row.brief="旁路"`）→ 运行 `20261004T161143850-42596`，方向①「direction 1 returns the enumerated row」与方向②投影共 5644/80159 红；**直接改 build 的显示字段不会红方向①**（两侧同源，判它的是 G6 冻结摘要）——方向①的判别力由本件与②件证明。④member 接受不存在的 id（`_card_point_site` 在手牌缺失时按 params 伪造同名卡）→ 运行 `20261004T161441732-54520`，方向② member⟺keys 变异断言 9948/80159 红（uid 变异 missing_enemy／missing_target／missing_uid／空）；还原（与备份 diff 相同）后运行 `20261004T161815375-58948` 全绿 80159（②③④的还原同由该轮与 md5 校验覆盖）。
- 依赖表文件面与实际改动逐文件一致：`core/card_effects.gd`、`core/game.gd`、`core/command_registry.gd`、`tests/architecture_cases.gd`、`docs/spec/fact-lookup-dependencies.md`、本记录。产品源码 md5：`core/card_effects.gd` `ccf325409b9d8ab0ac6a9bba839d766c`、`core/game.gd` `f19aef33517fdf3fa5b7253a5b77ca3a`、`core/command_registry.gd` `c15173ba85126639eb5a160183ad20d8`、`tests/architecture_cases.gd` `ae702ba53adfa2d233d37fed43a38954`。
- 失败轮与不作证据的轮：`20261004T154559494-31576`（①的递归首版，被中止，日志已删）；`20261004T152214378-27496`（首轮：C6 对 static 函数的源码提取口径失效、跨槽夹具状态不合法、点路径缺阶段守卫，16/79792 红，仅作过程记录）；`20261004T152812287-60588`／`20261004T153258032-28788`／`20261004T153544511-57244`（加入 `core/card_effects.gd::card_point_fact` fail-closed 守卫前的绿轮，指纹 `72E60BA9182207E1B75521007B2ED9F0DD489B735D8079527166239D5C0FEAAD`，不作最终冻结证据）。
- 未验证：S4 未开工（`POINT_KINDS` 只含 `attack`／`card`，其余 37 kind 仍为显式 table 形）；`-Suite all` 完整回归、`-VerifyRunner`、UI 其余模块、`normal_play`、安卓真机、打包与发布未跑。独立审查与清洁不在本记录内。

## 2026-10-05｜fact-lookup S2 补件：L1 守卫对齐、L4 死枚举删除、member 独立谓词、C6 helper 扫描与负例判据（R8；R10 并入）

- 域：`spire-godot/core/game.gd`（基础／巫女守卫 `_attack_battle_families_ready`、`attack_point_fact`／`attack_point_member` 与新增 `_equipment_point_member`／`_attack_point_release_target`／`_basic_attack_point_key`／`_witch_attack_point_key`）、`spire-godot/core/witch_character.gd`（删除 `attack_facts`）、`spire-godot/core/card_effects.gd`（R10：删除 `_hand_card`，`card_point_fact`／`_card_point_site` 的手牌定位改经 `core/game.gd::_card`）、`spire-godot/tests/architecture_cases.gd`（C6 源码文本判据扩展、非战斗负例判据、重复收敛口径）、`docs/spec/fact-lookup-dependencies.md`、`docs/spec/candidate-removal-dependencies.md`、本记录。依据 `C:\1\tmp\fact-lookup-plan\open-items.md` R8（1–8）＋R7＋R10（协调者追加，S3 第二路审计唯一 [应修]）。契约面 `plan.md`／`acceptance.md`／`gherkin.md`（临时规划区，不入库）同批措辞更正（H5）。
- 行为：基础／巫女家族的阶段守卫收敛为 `core/game.gd::_attack_battle_families_ready`（`_phase_action_tail` ∧ `phase=="battle"`，keys／build／member 共用同一函数，两处各写一份的守卫由此不再可能分歧）；`attack_point_fact` 的基础／巫女分支在非战斗阶段 fail-closed，对齐转换前 `core/game.gd::attack_facts` 的 `state.phase!="battle"` 早退（L1）。`attack_point_member` 改独立谓词：守卫＋家族解析（敌人按 id 在场且未 gone；`part∈Character.PARTS`／`form∈[0,1]`／`type=="witch_"+part`，或 `BasicAttacks.TYPES`／form 在 `forms()` 内）＋归一化键面比对，体内不调 `attack_point_fact`／`_attack_offer_fact`／`core/witch_character.gd::attack_offer_fact`／`_equipment_spell_fact`（L2）；键面派生（all＝声明字段／火球术 `spell_power`／附件强制全体；x＝声明 `x_cost` 时的 cost，kick 无 postures 分支经 `kick_profile` 与构造器同源）与 `_attack_offer_fact` 的 payload 派生逐条对应。删除 `core/witch_character.gd::attack_facts`（无调用方；候选键枚举唯一实现在 `core/game.gd::attack_point_keys`，L4）。R10：`core/card_effects.gd::_hand_card` 删除，两处调用改经 `core/game.gd::_card`，行为零变化。不写 `state`、不产事件、不推进随机、不改 `version`、不改文案与顺序；未动 `ui/`／`data/`／`tools/`。
- 检查（串行单引擎，`GODOT_BIN` 指向 Godot 4.7.2 `*_console.exe`，每轮起前 `Get-Process Godot*` 为空；冻结源码指纹 `2A3A13863E14D2ADB6808EA4B06A6B452AE93EDFDABDE77F524AA0146DBD53FE`）：`tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` 运行 `20261004T172535330-55368`（architecture PASS 80240、docs PASS、exit 0；同代码字节的前一轮 `20261004T172041944-26392` 同为 PASS 80240，其后只修 `docs/spec/fact-lookup-dependencies.md` 被合并写坏的一句措辞，四个源码文件 md5 均未变）；`tools/check.ps1 -Suite core -Impact -TimeoutSeconds 1800` 运行 `20261004T172932660-28068`（18 分类全 PASS：witch_character／card_power／card_expansion／relics／card_splash／card_growth／consumables／basic_attacks／battle_saturation／architecture／installation_priority／casting／action_copy／status／rewards／core／pressure／iron_man，93025 断言、exit 0、docs PASS）；`tools/check-docs.ps1` 单跑 exit 0（36 规则文档／2665 引用／允许清单 6 条不变，未新增条目；当轮 architecture 与 core -Impact 内 docs 阶段亦 PASS）。各轮 `summary.json` 均 `status=passed` 且 `before==after`，无 `SOURCE CHANGED`，日志无 `Failed to read the root certificate store.`。
- S3 判据在本提交上重建仍全绿（`architecture` 轮，本批同时重建 S3 证据）：`CARD FACT LOOKUP … dir1_rows=2502 dir2_mutations=28932 keys=2490 member=31434 duplicates=12 distinct=0`，九分支覆盖 `branches={ target_slots:2426, free_slots:21, exhaust_hand_select:580, self_faces:46, bound_modes:106, x_cost:4, single_face:2, exhaust_hand_fallback:15, bind:7 }`（七申报字段族＋bind＋exhaust_hand 选择／回退全部 > 0）；`ATTACK FACT LOOKUP fixtures=30 dir1_rows=163 dir2_mutations=1793 families={ basic:135, self_release:12, witch:16 }`、`T4 ROW EQUIVALENCE cells=7 rows=894 kinds=15`、`S5 SINGLE LOOKUP … dispatch=1 submit=0`／`S5 PRESENTED FACT compared=6`、`FACT SOURCE MAP PINNED kinds=37 takeover=command_facts point=2` 同轮仍绿。
- L1 新判据（本批核心交付）：`tests/architecture_cases.gd::attack_point_rejects_nonbattle_families`——夹具 `attack_nonbattle_enemy_fixture`（`r1_build("battle",12)` 保留真实存活敌人后把阶段切到 prepare）与 `attack_nonbattle_witch_fixture`（角色2 战斗夹具切 prepare）；逐例先断言「非战斗阶段 ∧ `_phase_action_tail()` ∧ ≥1 存活敌人」，再断言请求的 attack params 三处同假：不在表内（`command_facts()` 无同 kind 同归一化 params 的行）、点查询为空、`attack_point_member` 为假；打印 `ATTACK NONBATTLE POINT family=basic phase=prepare living=2 in_table=false accepted=false member=false`（witch 同）。夹具移除 L1 依赖的隐含前提「非战斗阶段没有存活敌人」，故缺阶段守卫必红。
- 敏感性证明 A（L1／R8-4；删除型）：临时删掉 `core/game.gd::_attack_battle_families_ready` 的 `and String(g.state.phase)=="battle"` 合取 → 运行 `20261004T171625409-49004`：`attack_point_rejects_nonbattle_families` 两条断言红（basic／witch 均 `in_table=true accepted=true member=true`，2/80240；G6 不红——冻结矩阵的非战斗 cell 无存活敌人，正是 L1 未被既有判据抓到的原因；该轮 `before==after`、无 `SOURCE CHANGED`）。还原（`core/game.gd` md5 `2764A3FDF8D9F179B11E7BD3A549C6C2`，与变异前一致）→ 复跑绿 `20261004T172535330-55368`。
- 敏感性证明 B（C6／R8-7；删除型，一次运行两处文本级变异、行为等价）：①`attack_point_member` 恢复 pre-L2 委托形态（`return not g.attack_point_fact(g,params).is_empty()`）→ 新断言「member 独立于请求行构造器」红；②`_equipment_spell_fact` 内插入惰性整表引用（`var _single_row_guard=equipment_spell_facts() if false else []`，不执行）→ 新 helper 白名单扫描红 → 运行 `20261004T165913283-41660`：恰 2/80240 红（无其他断言受影响；`before==after`、无 `SOURCE CHANGED`），证明扩面后的文本判据对「整表回落」与「member 回退成 build 别名」各有判别力；还原后由 `20261004T172535330-55368` 复跑绿覆盖。
- C6 扩面（`attack_point_lookup_reads_one_row`，gherkin S2-2；H4）：被调单行 helper 白名单 `ATTACK_POINT_HELPERS`（10 项＝`_attack_battle_families_ready`／`_attack_point_release_target`／`_equipment_point_member`／`_equipment_point_fact`／`_equipment_spell_fact`／`_basic_attack_point_key`／`_witch_attack_point_key`／`_attack_offer_fact`／`kick_profile`／`core/witch_character.gd::attack_offer_fact`，期望侧写在测试内，改名致提取为空即红）＋整表生产者名扫描（4 名）＋间接调用扫描（`.call(`／`Callable(`）＋member 独立于 5 个请求行构造器名；打印 `ATTACK POINT LOOKUP SOURCE SCAN bodies=12 helpers=10 whole_table_names=4 indirect_names=2`。运行期计数（测试侧子类）三条家族样本仍 `whole_table_calls attack_facts=0 equipment_spell_facts=0 _fact_source=0`。
- L9／措辞与口径同步：`docs/spec/fact-lookup-dependencies.md` 的 `core/game.gd` 行「必须保持」新增——**point 形构造器与成员谓词的阶段／家族守卫必须与转换前生产者逐条对应**（写明两家族守卫与判据点名）；`core/witch_character.gd` 行改为「删除第二份候选键枚举」；`core/card_effects.gd` 行补 R10，并写明「`card_facts` 无阶段守卫而 `card_point_keys` 有——非行为差异（View 侧阶段条件在 `_phase_facts` 尾段控制流里，转换前亦然）」的函数级不对称。`docs/spec/candidate-removal-dependencies.md` 的 `core/witch_character.gd` 行锚点 `core/witch_character.gd::attack_facts` 随符号删除改纯文本历史名（否则 `check-docs` 判未声明：首轮 `20261004T164313131-51104` 即因此 docs FAIL，rules 阶段 PASS 80240，该轮不作证据）。H5：`acceptance.md` C3 敏感性改为「显示平移（View＝keys×build 同源）→ G6 红；分歧类（解析错键／View 侧旁路）→ 方向①红」，`gherkin.md` 敏感性场景与 `plan.md` §7 新增 A1b 同批更正。L7：`attack_duplicate_params_fixture` 注释改为只主张「点查询返回枚举序首条」（引用性）；内容面（首条与后续条可区分）在攻击域结构性不可达（build 是 params 的纯函数），不作内容收敛声明、`distinct_duplicates==0` 不作正面证据；S2 记录中「攻击域重复 params 必然收敛到同一行内容」据此降为结构推断、不作判据（历史条目按只追加不改，更正见本条）。
- L4／记录口径更正：S2 记录「无第二套枚举或构造」在 S2 提交时不成立（`core/witch_character.gd::attack_facts` 当时无调用方但仍在源码里）；本批删除后该表述与源码相符。全仓引用核对：`Character.attack_facts` 零引用（`grep -rn "Character.attack_facts\|witch_character.gd::attack_facts" core/ tests/ ui/ data/` 无命中）；`attack_facts(` 的其余命中＝`core/game.gd::attack_facts`（基础攻击 View 生产者，保留）与其测试侧调用（`tests/architecture_cases.gd` 计数子类的 `super.attack_facts()`、`tests/relic_mana_cases.gd`／`tests/relic_revision_cases.gd` 的 `g.attack_facts()`）。
- R10 口径：注释语言按模块惯例执行（既有以中文为主，不批量改写；根 `AGENTS.md`「注释英文」条与现状的差异已在裁定 R10 记录）。
- 依赖表文件面与实际改动逐文件一致：`core/game.gd`、`core/witch_character.gd`、`core/card_effects.gd`、`tests/architecture_cases.gd`、`docs/spec/fact-lookup-dependencies.md`、`docs/spec/candidate-removal-dependencies.md`、本记录。产品源码 md5：`core/game.gd` `2764A3FDF8D9F179B11E7BD3A549C6C2`、`core/witch_character.gd` `C3541F4BF7F8FD37A0D5FB24E0D24929`、`core/card_effects.gd` `3374418EE56BF3E44CC528856719D09E`、`tests/architecture_cases.gd` `57B45D75A628EB749DABE7C61C3C2DD7`（变异前后逐字节一致；`core/command_registry.gd` 未改，`C15173BA85126639EB5A160183AD20D8`）。
- 失败轮与不作证据的轮：`20261004T164313131-51104`（rules PASS 80240，docs 因已删符号锚点 FAIL）；`20261004T164646907-51224`（判据修正前的绿轮：夹具命令构造缺 `kind` 致 accepted 恒假，被修正后的判据取代）；`20261004T164946441-63604`（修正前判据下的同一变异轮，仅 1 条红）；`20261004T165514112-45240`（变异 A 首轮，运行期间 R10 编辑致 `source_changed`，不作证据；该变异由 `20261004T171625409-49004` 重做）；`20261004T172041944-26392`／`20261004T170319631-47044`（同代码字节的绿轮，其后 `docs/spec/fact-lookup-dependencies.md` 被合并写坏的一句措辞修正使指纹失效而按原范围重取，不作最终冻结证据）。
- 未验证：`-Suite all` 完整回归、`-VerifyRunner`、UI 模块、`normal_play`、安卓真机、打包与发布未跑；R8 登记不修的 L3（View 路径每条攻击行构造约 3 次）／L5（装备自解家族无冻结摘要对照）／L6（阶段条件性行为在 prepare／rest／shop／event／prison 未逐阶段验证）保持现状；S4 未开工。

## 2026-10-05｜fact-lookup 收尾批：B1 记录更正、B2 G6 自证永久化、B4 失败计数收紧；全量回归

- 域：`spire-godot/tests/architecture_cases.gd`（B2 具名 check `submit_key_face_rebaseline_self_proof` 与两个字面摘要常量；B4 收紧 `rejected_submit_lookup_counts` 的陈旧 version／判定不通过两条计数断言）、`docs/record/verification.md`（本条更正与登记）。依据＝`C:\1\tmp\fact-lookup-plan\open-items.md` R11（收尾批裁定）与 `morning-issues.md` B1／B2／B4。产品源码未改（`core/`／`ui/`／`data/`／`tools/` 逐字节未动）；冻结基线未改（`R1_BASELINE`／`R5_BASELINE`／`S5_SUBMIT_KEYS_BEFORE`／`S5_SUBMIT_KEYS_AFTER` 原样），既有断言未删未弱：新增 2 条、收紧 2 条。
- B1 记录更正（只追加，不改历史条目）：
  ① S5 条把**夹具名** `prison` 写成了采样 kind；实际采样 kind 为 end／wall_move／posture／card。冻结轮 `20261004T133650050-17120` 的 12 次成功提交＝battle:0／battle:12／prepare:12 各 end／posture／wall_move ＋ prison:12 的 end／posture／card；`prison` 只是该单元格的夹具名（`kind=prison` 仅取值轮采到过）。
  ② 早先裁定文字里的「27 cell」应为 **26** 个 cell：26＝6 个非接管阶段 × 4 个装件数（0／12／26／44）＋ takeover×2（0／12），即 `tests/architecture_cases.gd::r1_cells` 与 `R1_PHASES`／`R1_COUNTS`／`R1_TAKEOVER_COUNTS`；S5 重算无遗漏（自证轮 26／26 `<record>` 与旧冻结值相等），本卷写作 26 处正确。
  ③ 取值轮 `20261004T132858869-47944` 的 2 条红＝①S5 采样断言（`several real fixtures and kinds … kinds=["wall_move","posture","attack","card","prison"]`，当时采样无 `end`）＋②G6 `behavior_baseline_equivalence`（`submit_keys` 重算前必红）；采样码补齐 `end` 后冻结轮转绿（同轮 `S5 DISPATCH KEYS` 打印见该轮日志）。
  ④ md5 口径：本卷 md5 是对**检出原始字节**的摘要，对 EOL 敏感——同一逻辑内容按 CRLF／LF 书写会得到不同摘要。本仓 `core/*.gd` 为 CRLF、`tests/architecture_cases.gd` 为 LF；跨机复核须用原始字节（`git show` 或直接读文件），不要拿做过文本模式转码的副本对账。
  ⑤ 证据日志位置：各轮日志在职能工作树 `spire-godot/build/checks/<运行号>/`（`build/` 被 git 忽略、不入库），随工作树生命周期；工作树删除后运行号不可再查，跨运行对账以逐分类计数与具名 check 为准。
- B2（G6 自证永久化，R6 第 9 条②）：新增具名 check `submit_key_face_rebaseline_self_proof`（登记进 `run`，置 `submit_presented_fact_is_unchanged` 之后）：`r1_digest(JSON.stringify(S5_SUBMIT_KEYS_BEFORE))=="93a45a7bba1ccfdae5f52a2e82831d5e"`（S5 之前的冻结 `submit_keys`）与 `r1_digest(JSON.stringify(S5_SUBMIT_KEYS_AFTER))=="5e6001580b5d714c2a081120d4019532"`（S5 重算后写进 `R5_BASELINE.<record>` 的值；与自证轮 `20261004T133011360-19112` 打印的 `S5 REBASELINE submit_keys=` 逐字符相同）。期望侧为测试内字面常量、不由实现派生；不替换任何既有断言；断言计数 80240 → 80242。
- B4（失败计数收紧，muse F2）：`rejected_submit_lookup_counts` 的陈旧 version 与判定不通过两条由 `g.fact_calls<=1` 改为精确值——陈旧 version **0**、形状不合法 **0**（原本已精确）、判定不通过 **1**；与冻结轮实测一致（`20261004T133650050-17120`：battle:0／prison:12 逐例 `S5 REJECT stale … command_fact=0`／`S5 REJECT invalid … command_fact=1`），未改断言迁就实测；本批两轮实测仍为 0／0／1。
- 检查（串行单引擎，`GODOT_BIN`＝Godot 4.7.2 `*_console.exe`，每轮起前 `Get-Process Godot*` 为空；冻结源码指纹 `F23E4C911E207D59C70A8B84BF0D8317B8127E576E9C66C30A80F33433DC0C2D`）：`tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` 运行 `20261004T175850353-63992`（architecture PASS **80242**、docs PASS、exit 0）；`tools/check.ps1 -Suite all -UI -UISuite all -KeepGoing -TimeoutSeconds 3600` 运行 `20261004T190603837-61392`（rules 52/52 全 PASS、**111837** 断言；UI 47/47 全 PASS、**7666** 断言；docs PASS、exit 0；`exhaustive=true`）；`tools/check.ps1 -Suite runner -VerifyRunner` 运行 `20261004T202508170-45748`（runner PASS 541、七项负例探针全过、exit 0；宿主口径见下条）；`tools/check-docs.ps1` 单跑 exit 0（36 规则文档／2665 引用／允许清单 6 条不变，未新增条目）。各轮 `summary.json` 均 `status=passed`、`before==after`、无 `SOURCE CHANGED`、日志无 `Failed to read the root certificate store.`。
- VerifyRunner 宿主口径（复用既有记录）：Windows PowerShell 5.1 下选择探针假红——运行 `20261004T202418767-50676` 的 runner 套件本体 PASS 541，但父进程把子进程探针的 throw 打成终止错误，`status=failed`、exit 1（与 2026-09-24 记录同因）；改用 **pwsh 7.6.6** 重跑得 `20261004T202508170-45748`，`status=passed`、`verify_runner=true`、`negative-*` 七项全过、exit 0。该 5.1 轮不作通过证据。
- 全量回归首跑被打断（不作证据）：`20261004T180435189-58592`（rules 52/52 PASS 111837、docs PASS，UI 阶段进行到 37 个模块时后台任务被宿主终止，无 `summary.json`），故按原范围重跑得 `20261004T190603837-61392`；两轮指纹相同。
- B2 敏感性证明（一次性变异→具名红→还原；`tests/architecture_cases.gd` md5 还原前后一致 `A4D1315B9B6273D3AF30F4FA06450D8A`，EOL＝LF）：把 `S5_SUBMIT_KEYS_BEFORE_DIGEST` 末位 `e` 改 `f` → 运行 `20261004T180144856-51928`，恰 **1/80242** 红（`S5 submit_key_face_rebaseline_self_proof: the pre-fact key face hashes to the pre-S5 frozen value have=93a45a7bba1ccfdae5f52a2e82831d5e want=93a45a7bba1ccfdae5f52a2e82831d5f`，无其它断言受影响）；还原后由 `20261004T190603837-61392` 的 architecture PASS 复跑覆盖（同指纹）。
- 未跑：安卓真机、打包与发布、`-Exhaustive` 单独指定（`all` 已自动启用）、`-Impact` 交叉面（本批只改测试与记录，无跨系统联动）；S4 未开工（按裁定）。
- 本批只提交测试与文档；未推送、未打标签、未改版本号、未打包。

## 2026-10-05｜fact-lookup C1 收尾：判定行只读契约＋两条判据；O2／O3／O4 文档缺口；M3 覆盖面注记

- 域：`spire-godot/tests/architecture_cases.gd`（新增 `dispatch_fact_row_is_readonly`／`payload_write_sites_are_pinned` 与常量 `FACT_ROW_WRITE_PATTERN`／`PAYLOAD_WRITE_CALLS`／`PAYLOAD_INDEX_WRITE_PATTERN`／`PAYLOAD_WRITE_WHITELIST`，登记进 `run`）；`docs/spec/candidate-removal.md` §2.1「事实行只读」；`docs/spec/fact-lookup-dependencies.md`（禁止项：判定行／`payload` 只读＋白名单＋残余逃逸面；`core/game.gd` 行 O2 守卫等价论证；`core/card_effects.gd` 行 O3 符号补全；测试面行 C1 判据与 `source_static_func_body_code`）；本记录（M3 注记＋本批）。依据＝`C:\1\tmp\fact-lookup-plan\open-items.md` R6 第 9 条（C1 [存疑]）与 R9／R11 登记的文档缺口（O2／O3／O4）。产品行为未改：`core/`／`data/`／`ui/`／`tools/` 逐字节未动（`core/game.gd` md5 `2764A3FDF8D9F179B11E7BD3A549C6C2`、`core/prison.gd` `18590684D09083099638B8931D08BE83`，与 S2 补件记录的还原值一致，两轮变异后逐字节还原）。
- C1 判据①（`dispatch_fact_row_is_readonly`）：`core/game.gd::dispatch` 函数体（去注释，`source_func_body_code`）内扫局部 `chosen` 的成员／索引赋值——正则 `\bchosen(?:\.[A-Za-z_][A-Za-z0-9_]*|\[[^\]]*\])+\s*[-+*/%&|^]?=(?!=)`，排除 `==`／`!=`／`<`／`>` 比较与 `FirstTurnControl.commit(self,chosen)` 一类传参；空体即红（防改名静默）。绿轮打印 `FACT ROW READONLY SCAN hits=0 domain=core/game.gd::dispatch`。
- C1 判据②（`payload_write_sites_are_pinned`）：扫 `res://core`＋`res://data` 全部 `.gd`（本轮 77 文件；`script_files` 递归枚举、逐行去注释、按最近 `func` 声明归属函数名），模式＝`payload.merge(`／`payload[<非空>] =`（正则，排除比较）／`payload.erase(`／`payload.clear(`；断言集合**恰等于**字面白名单 `PAYLOAD_WRITE_WHITELIST=["res://core/prison.gd::add"]`（多一处、少一处、同一函数内多写一处都红）。绿轮打印 `PAYLOAD WRITE SCAN files=77 sites=1 ["res://core/prison.gd::add"]`。残余逃逸面（把 `chosen.payload` 传给 helper、由 helper 去写）已在依赖规约禁止项写明：源码文本判据扫不到，补偿＝白名单计数变化即红＋审查。两条新判据合计 +4 断言（80242 → 80246）。
- 敏感性证明①（`dispatch` 判定行写点；`core/game.gd` 变异后逐字节还原）：在 `if not chosen.valid` 之后临时插 `chosen.payload["probe"]=1` → 运行 `20261004T221301153-21720`：`FACT ROW READONLY SCAN hits=1`（报出 `chosen.payload["probe"]=`），14/80246 红＝本判据 1 条＋`payload_write_sites_are_pinned` 1 条（该变异同时是一处 payload 写点，白名单转红 `have=["res://core/game.gd::dispatch","res://core/prison.gd::add"]`）＋既有 C10 `submit_presented_fact_is_unchanged` 12 条（判定行真实被写会被既有提交路径判据抓到）；docs PASS、无证书错误。还原后复跑绿（见下）。
- 敏感性证明②（全仓 payload 白名单计数；`core/prison.gd` 变异后逐字节还原）：在白名单函数之外（`core/prison.gd::enter_detail` 内）临时加 `var payload={"probe":0}`＋`payload["probe"]=1` → 运行 `20261004T222111916-24500`：**恰 1/80246 红**即 `payload_write_sites_are_pinned`（`have=["res://core/prison.gd::add","res://core/prison.gd::enter_detail"] want=["res://core/prison.gd::add"]`），其余断言全绿（证明扫描精确、变异行为中立）；docs PASS。还原后复跑绿（见下）。
- 检查（串行单引擎，`GODOT_BIN`＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`，每轮起前 `Get-Process Godot*` 为空；冻结源码指纹 `8E768CCE4E3D597F8B141C8A2925B6FC9B3F372FE3CF0A50D1B959CF0F0282E9`）：`tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` 运行 `20261004T222540192-14376`（architecture PASS **80246**、docs PASS、232.25s、exit 0）；`tools/check.ps1 -Suite core -Impact -TimeoutSeconds 1800` 运行 `20261004T222959777-12588`（18 分类全 PASS：witch_character／card_power／card_expansion／relics／card_splash／card_growth／consumables／basic_attacks／battle_saturation／architecture／installation_priority／casting／action_copy／status／rewards／core／pressure／iron_man，**93031** 断言、602.42s、exit 0）；`tools/check-docs.ps1` 单跑 exit 0（2026-10-05 09:40:30，36 规则文档／2702 引用／允许清单 6 条不变，未新增条目）。两轮 `summary.json` 均 `status=passed`、`before==after`、无 `SOURCE CHANGED`、日志无 `Failed to read the root certificate store.`。
- O2（守卫等价论证入契约）：`docs/spec/fact-lookup-dependencies.md` 的 `core/game.gd` 行「必须保持」补——`attack_facts`／`equipment_spell_facts` 的到达守卫由转换前的 `base_action_block()` 换成经 `attack_point_keys` 的 `_phase_action_tail()`，**在 View 路径上等价**：差异只在 `_phase_facts` 提前返回的状态（`event`／`captured`／`inspection`／`prison_end` 等非战斗早退，以及 overloaded＋战斗／`card_chain` 非空／`pending_retain` 三态早退），尾段攻击生产者在这两类状态不可达；View 之外的唯一直呼者 `tests/relic_mana_cases.gd`／`tests/relic_revision_cases.gd` 均为普通战斗态。
- O3（符号枚举补全入契约）：同文件 `core/card_effects.gd` 行补点名 `_card_point_card_keys`／`_card_point_site`／`_card_point_choice`／`_card_slot_key`／`_card_slot_fact`；测试面行补点名 `source_static_func_body_code`（S3 引入的 static 函数体提取器，C6 文本判据工具）。
- O4（M3 覆盖面注记，R9 登记、非 [应修]，只入记录、不改源码）：①`shoulder` 槽「不补空目标」例外无显式夹具——G6 与分支覆盖计数都抓不住；②未声明槽 × `special`／`bound_modes`／`occupied` 组合未穷举（`card_facts_declared_slots` 一族只覆 `strong_elbow`／`palm`／`strain`）；③`assist_profiles` 由逐行缓存改为逐行现算、`face_costs`／`face_payments` 由缓存改为现算——今日纯读故与缓存等价，若将来出现写状态即漂移且无判据锁。
- 不作证据的轮：`20261004T220840263-15456`（预验证轮：architecture PASS 80246，但首稿把白名单锚点写成 `res://core/prison.gd::add`，`check-docs` 锚点正则解析为 `//core/prison.gd` → docs FAIL exit 1；该轮运行中修文档并另带 `SOURCE CHANGED`，不作证据）。两轮敏感性红轮按惯例只作变异证据，不作通过。
- 依赖表文件面与实际改动逐文件一致：`tests/architecture_cases.gd`（md5 `AFF9DBB3CBD65112E4D6D98A4BB0EBFE`，LF）、`docs/spec/candidate-removal.md`（`4F926EEE857BA08DBBAF2460B002DCE2`）、`docs/spec/fact-lookup-dependencies.md`（`09B248E6B1DE3DDC497A27A8BF7AE634`）、本记录。未新增 `check-docs` 允许清单条目。
- 未验证／未跑：`-Suite all` 完整回归、`-VerifyRunner`、UI 模块、`normal_play`、安卓真机、打包与发布未跑；S4 未开工（`POINT_KINDS` 仍只含 `attack`／`card`）；残余逃逸面（helper 写 `chosen.payload`）无机械判据，靠白名单计数变化＋审查。独立审查与清洁不在本记录内。
- 本批只提交测试与文档；未推送、未打标签、未改版本号、未打包。

## 2026-10-05｜fact-lookup C1 修正批（R14）：payload 写点扫描放宽到成员形；白名单按实际重钉；契约措辞收窄

- 域：`spire-godot/tests/architecture_cases.gd`（删 `PAYLOAD_WRITE_CALLS`／`PAYLOAD_INDEX_WRITE_PATTERN`，改为 `PAYLOAD_WRITE_PATTERN`／`PAYLOAD_MUTATOR_CALL_PATTERN`；`payload_write_sites` 改逐次登记；`PAYLOAD_WRITE_WHITELIST` 重钉为 3 条；注释「接收者名里含 `payload`」改为「接收者**末段**恰为 `payload`」）；`docs/spec/candidate-removal.md` §2.1（补「判据的射程（不是「共享行只读」的证明）」段）；`docs/spec/fact-lookup-dependencies.md`（禁止项：判据射程＋四条已知逃逸面；测试面行与两处文档面行同步）；本记录。依据＝`C:\1\tmp\fact-lookup-plan\open-items.md` R14（A1／A2／A4）。**产品行为未改**（`core/`／`data/`／`ui/`／`tools/` 未提交任何改动）。
- 放宽后的模式集：接收者**末段**恰为 `payload`（段边界 `\b`：前一字符不是 `[A-Za-z0-9_]`）的成员赋值 `.field=`（含 `+=` 等复合赋值）与索引赋值 `[…]=`，外加改字典内容的 `payload.merge(`／`payload.erase(`／`payload.clear(`；`chosen.payload.probe=`／`chosen.payload["x"]=` 计入；`attack_payload.x=`／`target_payload[…]` 不计（末段是 `attack_payload`／`target_payload`，不是本判据语域的载荷）。白名单按写点**出现次数**逐条登记（同一函数内的第二处写——即使同一行——也变红）。
- 白名单重算前后：前＝`["res://core/prison.gd::add"]`（旧模式绿轮 `PAYLOAD WRITE SCAN files=77 sites=1`）；后＝`["res://core/card_effects.gd::card_point_fact","res://core/card_effects.gd::card_point_fact","res://core/prison.gd::add"]`（`sites=3`）。新增＝`core/card_effects.gd::card_point_fact` 的两处既有生产者侧写点（同一行的 `payload.kind="card"` 与 `payload.uid=card.uid`：`target_payload(...)` 刚构造的本地载荷，随后交给 `_card_point_choice`）；`core/game.gd` 的 `attack_payload.x=cost`／`attack_payload.mana_attachment=true` 按末段规则不计。
- 敏感性①（`dispatch` 内成员形写；`core/game.gd` 变异后逐字节还原）：在 `if not chosen.valid` 后插 `chosen.payload.probe=1` → 运行 `20261005T031942460-8528`：`FACT ROW READONLY SCAN hits=1`（报出 `chosen.payload.probe=`）＋`PAYLOAD WRITE SCAN files=77 sites=4`（多出 `res://core/game.gd::dispatch`）⇒ **14/80246** 红＝`dispatch_fact_row_is_readonly` 1＋`payload_write_sites_are_pinned` 1＋既有 C10 `submit_presented_fact_is_unchanged` 12（判定行真实被写）；docs PASS、无证书错误、exit 1。
- 敏感性②（非白名单生产者插成员形写；`core/room_services.gd` 变异后逐字节还原）：在 `core/room_services.gd::facts`（`service` 表形来源）的 `var payload={"kind":"service","op":"take","index":index}` 后插 `payload.probe=1` → 运行 `20261005T032502533-23828`：**2/80246** 红＝`payload_write_sites_are_pinned`（`have=[card_point_fact×2, prison.gd::add, room_services.gd::facts]`，恰多 1 处——**这是本轮核心新覆盖：该成员形写在旧模式扫不到**）＋G6 `behavior_baseline_equivalence`（该键真进入 `service` 事实载荷，`shop:0.<record>` 首差）；同时 `dispatch` 判据保持 `hits=0`（变异在 dispatch 之外）；docs PASS、exit 1。
- 检查（串行单引擎，`GODOT_BIN`＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`，每轮起前 `Get-Process Godot*` 为空；冻结源码指纹 `03E5DB78B680607181864F5A471903B7602CACC26F776F49EAA2EEC21637023B`）：`tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` 运行 `20261005T033125568-28984`（architecture PASS **80246**、docs PASS、276.67s、exit 0；绿轮打印 `PAYLOAD WRITE SCAN files=77 sites=3` 恰等于新白名单）；`tools/check.ps1 -Suite core -Impact -TimeoutSeconds 1800` 运行 `20261005T033842141-1984`（18 分类全 PASS：witch_character／card_power／card_expansion／relics／card_splash／card_growth／consumables／basic_attacks／battle_saturation／architecture／installation_priority／casting／action_copy／status／rewards／core／pressure／iron_man，**93031** 断言、796.85s、exit 0）；`tools/check-docs.ps1` 单跑 exit 0（36 规则文档／2720 引用／允许清单 6 条不变，未新增条目）。两轮 `summary.json` 均 `status=passed`、`before==after==03E5DB78…`、无 `SOURCE CHANGED`、日志无 `Failed to read the root certificate store.`。
- 不作证据的轮：首次后台任务因 bash 变量展开出错（`:GODOT_BIN=…` 未被 PowerShell 识别）**未启动任何检查**，不计；两轮敏感性红轮按惯例只作变异证据，不作通过。
- 契约措辞收窄点：`docs/spec/candidate-removal.md` §2.1 明写「两条判据都是源码文本的写点计数钉，不是「共享行只读」的证明」；`docs/spec/fact-lookup-dependencies.md` 禁止项列四条已知逃逸面——①`dispatch` 外的 `chosen` 成员形写（含别名 `c=chosen`）；②UI 侧写入（扫描面不含 `ui/`，`ui/` 里 `payload` 另有拖放载荷含义，扩面会大面积误报，故不扩，靠架构边界与审查）；③函数内局部别名（`var p=chosen.payload; p["x"]=1`；生产者侧同类如 `card_point_fact` 的 `bind.kind=`／`bind.uid=`）；④把 `chosen.payload` 传给 helper 由 helper 写。
- 依赖表文件面与实际改动逐文件一致：`tests/architecture_cases.gd`（md5 `A27C9F7D7A73471A6614104BB4E2EB57`，LF）、`docs/spec/candidate-removal.md`（`CAF0AF5A6BCFE02A068375F9E3B5D5E9`）、`docs/spec/fact-lookup-dependencies.md`（`C9FF271D99113B6BEB4A4EF6DDCDF606`）、本记录。产品源码逐字节未动（`core/game.gd` md5 `2764A3FDF8D9F179B11E7BD3A549C6C2`、`core/room_services.gd` `2F8BD0338C743A0EEE5AA14E2B98098C`，两轮变异后还原值与变异前一致）。
- 未验证／未跑：`-Suite all` 完整回归、`-VerifyRunner`、UI 模块、`normal_play`、安卓真机、打包与发布未跑；S4 未开工；四条逃逸面无机械判据，靠白名单计数变化＋审查。独立审查与清洁不在本记录内。
- 本批只提交测试与文档；未推送、未打标签、未改版本号、未打包。

## 2026-10-06｜fact-lookup 重放并集收尾：契约索引化、known_gaps 登记与门禁取证（接手批；上一会话中途停止）

- 域：`docs/spec/fact-lookup-dependencies.md`（相对本树 HEAD `73f2a04`：+53/−85，整篇改写为「判据 → 检查」索引＋「仍靠人审」）、`docs/spec/response-pipeline.md`（+5/−0：证据入口索引两行）、`spire-godot/tests/mutations.json`（+16/−2：`known_gaps` 40→54、`known_gaps_reason` 增例外句）、本记录。产品源码／测试源码／内容包逐字节未动。
- 上一会话遗留（同一工作树 `C:\1\tmp\magic-spire-wt-fact-on-norms`，枝 `fact-lookup-on-norms`，尖端 `73f2a04`＝`008e505` 上的 10 条重放提交）：未提交面＝上述三文件＋成片 `.import` 行尾改写；`git checkout -- spire-godot/assets` 已还原（还原后 `git diff --numstat -- spire-godot/assets` 为空，无实质差异）；无 `_mutation_probe` 残留、无 Godot 进程；上一会话未提交、未报告、未写本记录。
- 不作证据的轮：上一会话在本树留下 `spire-godot/build/mutations/20261006T023408295-2384/`（16 条 .log、本地 13:38–15:28，无 stdout 摘要，完成度与残留检查不可自证），本批不以它为证据、按 16 条全量重跑（新运行号见下）。
- 未提交面判定（逐块）：`fact-lookup-dependencies.md` 的改写块＝①按 `skills/spire-docs/SKILL.md`「判据优先」把判据散文改成索引（与 `seed-feedback`／`run-review`／`card-terms` 三个依赖索引同形）；无②；③补两处——`fact_source_map_is_pinned` 行原写「39 条映射」与源码不符（实测 `tests/architecture_cases.gd::FROZEN_TABLE_SOURCES`＝37 条 table、`FROZEN_POINT_METHODS`＝2 条 point 另钉），改为 37 条并补回这两个符号名；`payload_write_sites_are_pinned` 行补回白名单符号名 `tests/architecture_cases.gd::PAYLOAD_WRITE_WHITELIST` 与扫描面「`core/`＋`data/` 全部 `.gd`」。`response-pipeline.md`＝①（纯增 5 行，指向依赖文件与 6 个具名 check，`git diff --numstat`＝`5 0`）。
- 判据名与计数核对（对照源码）：14 个既有具名 check 全部保留（`command_registry_is_total`／`fact_source_map_is_pinned`／`fact_lookup_equivalence`／`attack_fact_direct_lookup`／`attack_point_lookup_reads_one_row`／`attack_point_rejects_nonbattle_families`／`card_fact_direct_lookup`／`card_point_lookup_reads_one_row`／`single_fact_lookup_per_submit`／`rejected_submit_lookup_counts`／`submit_presented_fact_is_unchanged`／`submit_key_face_rebaseline_self_proof`／`dispatch_fact_row_is_readonly`／`payload_write_sites_are_pinned`）；计数 39／39（`CommandRegistry.kinds()`＝39、`POINT_KINDS`＝`["attack","card"]`）、37 条 table、0／12／26／44 件、白名单两处＋一处（3 条）、三家族均在；未跑项「S4 未开工」保留在「仍靠人审」节。判为可删的原句与理由（不构成丢失）：授权期允许改动表整表（`skills/spire-docs`「依赖约束索引」：允许改动表随授权期结束删除）、迁移期复算命令与自检清单（开工当日口径）、审查轮号（R10／L4／L1／L9／R14／O7 与 G6「26 cell」）——轮号与失败轮逐条在本记录既有 S2 补件／S5／C1 条内（本文件自述「不写执行结果」）；「人审与模块切分批准：2026-10-04」一行随授权期标题删除（其余三个依赖索引同形，批准在协调者记录）。
- `tests/mutations.json` 判定：重放线新增 14 个 architecture 判据未随批附突变证据；静态复算（复刻 `tests/architecture_cases.gd::mutation_judgment_universe` 的判据逻辑）＝HEAD 表下 `silent` 恰为这 14 条本线判据 ⇒ 不登记即令 `mutation_evidence_is_total` 红（本整合引入）。上批按「既有语义偏差登记」逐条列入 `known_gaps`（40→54），`known_gaps_reason` 收窄为例外只对「写于本表存在之前的重放线判据」、此后新增判据仍须随批附证据。登记后静态核对：universe＝70、silent＝0、both＝[]、unknown＝[]，`NORM_REWRITE_CHECKS` 15 条全在 `mutations`；该判据本身在列（表中 `mutation_evidence_is_total` 条目）并已随本轮 -All 取得敏感性证据。
- 门禁（`spire-godot/`；起前 `Get-Process Godot*`＝0、串行单引擎；`GODOT_BIN` 显式指向 `C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`）：
  - `tools/check-mutation.ps1 -All` → 运行 `20261006T051926407-20372`：`MUTATION SUMMARY: 16/16 entr(ies) reddened the named check and restored byte-for-byte; worktree unchanged=True; elapsed 2984.2s`，exit 0，无 `MUTATION RESIDUE`；日志 `build/mutations/20261006T051926407-20372/`（16 个 .log）；逐条 `RED exit-red=True restored=True`。
  - `tools/check.ps1 -Suite architecture -TimeoutSeconds 2400` → 运行 `20261006T061425803-11148`：`DOCS PASS: 42 rule-class document(s), 1810 reference(s) checked, allowlist 3 entrie(s)`／`DOCS RESULT: PASS`／`SUITE RESULT: architecture PASS`／`PASS: 80281 assertions`（rules 186.56s）、exit 0；`summary.json` `status=passed`、`before==after=78A7BB7F88A52AB2532CD6A05D66C363403EF4EA44128B83CA5BABFB11038374`、`rules.failed=[]`／`unrun=[]`／`retry=[]`／`complete=true`、`docs.problems=0`；`check-rules.log`／`check-docs.log` 无 `SOURCE CHANGED`、无 `Failed to read the root certificate store.`；三条 DOC NOTE（declared-missing 已无人引用）与允许清单 3 条均未增删。
  - `tools/check-docs.ps1` 单跑 → `DOCS PASS: 42 rule-class document(s), 1810 reference(s) checked, allowlist 3 entrie(s)`，exit 0。
  - `tools/check-record-conservation.ps1`（迁移期脚本，不占引擎，`-Base 8e83876`）→ `CONSERVE PASS`：三卷 identifiers=0／non_verbatim=0／headings／dates／domains=0／markers=0，本记录追加节按只追加放行，允许清单 1。
- 未跑项：`-Suite all` 完整回归；UI 窗口分类（本批未改界面代码面与文案）；`-VerifyRunner`；`-Suite recipe`；`tools/check-content.ps1`（未改 `content/packs/`）；安卓真机；打包、标签、推送。S4 未开工；`payload` 写点判据的四条逃逸面无机械判据、靠白名单计数变化＋审查（沿旧口径）。
- 本批只提交文档与证据面声明（未改产品代码）；未推送、未 tag、未改版本、未开 PR。

## 2026-10-06｜事实表「面 / 点」收口 A 批（K0 分支词表＋K1 单元表）：零移动重构＋三条新判据＋缺口冻结清单

- 域：`spire-godot/core/game.gd`（新增 `core/game.gd::_phase_branch`；`core/game.gd::_fact_source`／`core/game.gd::_phase_facts` 改按单元表连接；新增连接通道 `core/game.gd::_join_fact_units`／`core/game.gd::_phase_branch_units` 与 29 个单元生产者 `_unit_*`（含逐手牌切片的 `core/game.gd::_unit_hand_cards`）；行内容、守卫与文案一字未改）、`spire-godot/core/command_registry.gd`（新增 `core/command_registry.gd::FACT_UNITS` 36 项＋`core/command_registry.gd::FACT_PREFIX_OWNERS`＋`core/command_registry.gd::fact_source_units`／`core/command_registry.gd::phase_units`：纯数据与静态函数，零 preload 不变）、`spire-godot/tests/architecture_cases.gd`（新增 `tests/architecture_cases.gd::fact_units_cover_fact_source`／`tests/architecture_cases.gd::phase_branch_vocabulary_is_total`／`tests/architecture_cases.gd::baseline_constants_are_unchanged`＋字面期望 `tests/architecture_cases.gd::PHASE_BRANCH_VOCABULARY`／`tests/architecture_cases.gd::FACT_UNIT_EXPECTATION`／`tests/architecture_cases.gd::R5_BASELINE_PRE_DIGEST` 一族与夹具／`tests/architecture_cases.gd::mutation_evidence_is_total` 增缺口冻结核对）、`spire-godot/tests/mutations.json`（+3 条突变证据；新增 `known_gaps_frozen` 54 项＝A 批冻结清单）、`docs/spec/fact-table-dependencies.md`（新建：判据索引＋唯一入口表＋允许依赖方向＋不可独立增量＋仍靠人审）、`docs/spec/response-pipeline.md`（判据索引区 +3 行，与 hand-refresh／fact-lookup 两条同形；未动根 `AGENTS.md`）、本记录。依据＝`C:\1\tmp\view-projection-plan\`（design.md §K0／§K1、plan.md §3 A 行／§4.0／§5.1／§6、gherkin.md A 段、acceptance.md §1 A 段／§4 A／§5.1／§5.4、open-items.md 人裁 2026-10-06 四条）。**本批不做 B（23 个 kind 的来源）／C（一次构造）／D（批内复用）／E／F／G；不改 UI、不改 View 键、不改提交事务与判定。**
- K0 落点：`core/game.gd::_phase_branch` 返回 17 个具名 id（顺序＝改动前 `_fact_source` 的三个前缀早退 relic_bundle／departure／domain_blocked ＋ `core/game.gd::_phase_facts` 的 14 条早退，逐条对应）；`core/game.gd::_phase_facts` 改为 `match _phase_branch():` 的 14 条臂（四个前缀／尾段标签共用一条，`prison_end`／`map` 空表），体内无条件链、无追加点。只读（不写 state、不推进随机、不改 version）。
- K1 落点：单元表＝`core/command_registry.gd::FACT_UNITS`（{id, order, owner, producer, groups, input}；owner∈{relic_bundle, departure, main}∪分支 id；order＝owner 内 1..N；producer＝`core/game.gd` 上 `(facts: Array) -> Array` 的方法名；groups＝实测 group 值域；input＝读累积表的跨单元前置）；表项 36＝`_fact_source` 14（F1–F14）＋分支 22。连接唯一入口＝`core/game.gd::_join_fact_units`（按表序 `call(producer, facts)`，累积表前传）。两条跨单元数据前置显式登记：`noncombat_consumables`（三个前缀／主序列各一份）的 `input` 指向前缀单元，`core/command_registry.gd::FACT_UNITS` 的 `route` 行 `input="phase"`（读累积表出口行＋现算 `core/game.gd::room_entry_reason`）；不可独立增量清单（三个 `*_consumables`、`route`、`relic_effects`／`hand_cards`／`prison`／`events`／`services`）写进单元表注释与 `docs/spec/fact-table-dependencies.md`。
- C-A-1（`tests/architecture_cases.gd::fact_units_cover_fact_source`）：①单元表 ↔ 测试内字面期望双向全量（owner 序／id／producer／input）＋`core/command_registry.gd::FACT_PREFIX_OWNERS` 与字面表相等；②order 列＝owner 内 1..N 连续、input 指向同 owner 更早单元；③每个 producer 在 `GameCore` 上存在、每单元 groups 非空；④连接通道唯一（源码文本：`_fact_source` 仅一次 `_join_fact_units(`、无 `if `；`_phase_facts` 14 条臂各 `return _phase_branch_units(`、恰一次 `_phase_branch(`；连接体内不出现任何 producer 名）；⑤83 个夹具（26 cell＋13 相位×4 变体＋六个状态标志）上测试侧重放与 `core/game.gd::_fact_source`／`core/game.gd::_phase_facts` 逐字节相等；⑥组列双向：逐单元实测 group 值域 ⊆ 声明，声明 ⊆ 实测并集（`tests/architecture_cases.gd::FACT_UNIT_GROUP_UNCOVERED` 逐条登记观测不到的 (单元:组) 对——本批＝`phase:chain`／`chain:chain`（需牌链夹具）；列出却观测到即红）。绿轮打印 `FACT UNITS declared=36 states=83 uncovered=["phase:chain", "chain:chain"]`。
- C-A-2（`tests/architecture_cases.gd::phase_branch_vocabulary_is_total`）：字面词表 ↔ `core/game.gd::_phase_branch` 的 return 点 ↔ `core/game.gd::_phase_facts` 的 match 标签三处双向全量、无重复；`_phase_facts` 体内无 `if `／无 `append`；`_phase_branch` 体内无赋值（只读）。绿轮打印 `PHASE BRANCH VOCABULARY declared=17 returns=17 labels=17`。
- C-A-3（G-1 零移动）：`tests/architecture_cases.gd::baseline_constants_are_unchanged` 以动工前摘要冻结 `R5_BASELINE`／`R3_VIEW_MASK`／`R5_VIEW_MASK`／`R5_RECORD_MASK`／`R5_RECORD_ADDED`／`R5_RECOMPUTED`（绿轮 `BASELINE CONSTANTS FROZEN pairs=6`）；`tests/architecture_cases.gd::behavior_baseline_equivalence`（G6 26 cell）与既有 `command_registry_is_total`／`fact_source_map_is_pinned`／`fact_lookup_equivalence`／`command_fact_kind_lookup`／`get_view_call_sites_are_pinned` 全绿——四个 mask 常量与 `R5_BASELINE` 一字未改（本批无任何重冻）。
- 缺口拆架条件①（plan §4.0；acceptance.md §5.4）：`tests/mutations.json::known_gaps_frozen` 落盘 A 批冻结清单 54 项，`tests/architecture_cases.gd::mutation_evidence_is_total` 增「只许缩短」双向核对（新增条目即红）。绿轮打印 `MUTATION GAP FREEZE frozen=54 current=54 shrunk=0`；新增的三条判据全部进 `mutations` 表、未进缺口。
- 零移动差分探针（build-only，不随提交；`spire-godot/build/probe_a_batch.gd`）：90 个状态（26 cell＋16 相位×4 变体）逐状态取 `command_facts` 行面摘要（key／valid／reason／group／label／cost／mana）＋`get_view().display_facts` 条数＋`room_entry_reason`（无出口行动，直呼）摘要，与改动前逐字节比对：**表出口面 90/90 状态逐字节相等**（含三个前缀状态与 domain_blocked）。差异仅 6 个状态——`rest_choice`／`reward`／`travel` × `relic_bundle`／`domain_blocked` 的**直呼** `core/game.gd::_phase_facts`（前缀臂落回尾段；改动前的链在该状态命中相位分支）。可达面：前缀由 `core/game.gd::_fact_source` 先行解析，`core/game.gd::_flow_kind_facts` 带域守卫，`core/game.gd::_depart` 在前缀表上不可达，路线理由只消费出口行 ⇒ 均不在生产调用路径上；已写进 `docs/spec/fact-table-dependencies.md`「仍靠人审」。
- 敏感性证据（`tools/check-mutation.ps1`，每条＝改源码→跑 `architecture`→要求该判据红→逐字节还原，串行单引擎）：运行 `20261006T071832416-33244`，`MUTATION SUMMARY: 3/3 entr(ies) reddened the named check and restored byte-for-byte; worktree unchanged=True; elapsed 488.7s`，exit 0。逐条：`phase_branch_vocabulary_is_total`（`core/game.gd` 把 `cleared` 分支临时改名 `cleared_probe`，sha256 `5A765C7E84CD`）→ `ERROR: K0 phase_branch_vocabulary_is_total: … (missing=["cleared"] extra=["cleared_probe"])`；`fact_units_cover_fact_source`（`core/command_registry.gd` 把 `manual` 单元的 producer 临时改为 `_unit_manual_probe`，sha256 `391DC6D7DDB7`）→ `ERROR: K1 fact_units_cover_fact_source: the declared unit table is two-way total …`＋`… every declared producer exists on g: ["_unit_manual_probe"]`；`baseline_constants_are_unchanged`（`tests/architecture_cases.gd` 把 `R5_RECOMPUTED` 临时改为 `["record"]`，sha256 `DD1D5A26413C`）→ `ERROR: G1 baseline_constants_are_unchanged: … ["R5_RECOMPUTED"]`。日志 `spire-godot/build/mutations/20261006T071832416-33244/`。缺口冻结核对本身的敏感性（该断言不占 `mutations` 表的第二条条目）另作实测：临时向 `known_gaps` 插 `mutation_probe_new_gap` → 运行 `20261006T070124372-11176` 红（`ERROR: MT mutation_evidence_is_total: the frozen gap list only shrinks (new entries are red): ["mutation_probe_new_gap"]`），随后按字节副本还原并核 sha256＝`D6808F274A7C`（与改动前一致）。
- 门禁（`spire-godot/`；起前 `Get-Process Godot*` 为空、串行单引擎；`GODOT_BIN` 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`）：范围预检 `tools/check.ps1 -Suite architecture -Impact -ListOnly` 运行 `20261006T070604305-5164`（`RULE SCOPE: architecture`，展开面＝仅 architecture 一条，`PLAN ONLY`）；主轮 `tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 2400` 运行 `20261006T071222898-37928`（`DOCS PASS: 43 rule-class document(s), 1892 reference(s) checked, allowlist 3 entrie(s)`／`DOCS RESULT: PASS`／`SUITE RESULT: architecture PASS`／`PASS: 80300 assertions`，rules 209.97s，exit 0；`summary.json` `status=passed`、`before==after=5F06C868D5E40ACEF3A34BCCB2B5E8556D12CFA83910320F9675FFB6AFBAB1B6`、`rules.failed=[]`／`unrun=[]`／`retry=[]`／`complete=true`、`docs.problems=0`）；零移动 UI 轮 `tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 2400` 运行 `20261006T071606009-6940`（`SUITE RESULT: display PASS`／`UI PASS: 1096 assertions`，130.93s，exit 0；同一指纹 `before==after=5F06C868…`）；`tools/check-docs.ps1` 单跑 exit 0（43 规则文档／1892 引用／允许清单 3 条，未新增条目）。两轮 `check-*.log` 无 `SOURCE CHANGED`、无 `Failed to read the root certificate store.`。运行号目录 `spire-godot/build/checks/<运行号>/`。
- 不作证据的轮（源在轮后被改，按纪律作废）：`20261006T070619616-4320`（architecture PASS 80300）与 `20261006T070926857-35724`（display PASS 1096）——两轮之后 `core/game.gd::_phase_facts` 的文档注释按实测残差改写一行（注释、无行为），故最终指纹 `5F06C868…` 的证据取上一条的重跑轮；`20261006T065420135-12460`（mutations 3/3，同一批声明在注释改写前）同理已被 `20261006T071832416-33244` 取代。更早的三轮中间轮（`…064054807-6368` 3 红、`…064540502-32436` 1 红、`…065021055-38228` 全绿）为夹具与组列落盘期的迭代，只作过程记录、不作通过证据。
- 未验证／未跑：`-Suite all` 完整回归；`-Suite recipe`（本批未改真实输入路径的规则面）；`-VerifyRunner`；其余 UI 窗口分类（`interface`／`body_layout`／`targeting`／`route`／`services`／`prison`／`items`／`home`／`normal_play` 未跑；本批不改 UI 文件，display 轮作零移动的证据面）；`tools/check-content.ps1`（未改 `content/packs/`）；安卓真机；打包、标签、推送。S4 未开工（`tests/architecture_cases.gd::POINT_KINDS` 仍为 `["attack","card"]`）；`tests/architecture_cases.gd::FACT_UNIT_GROUP_UNCOVERED` 两对组的观测面与「单元表完备性」的无机械判据部分见依赖索引「仍靠人审」；三条判据均为行为／源码文本判据，覆盖输入域＝26 cell＋相位扫描夹具与源码文本，域外不宣称（例如单张牌链夹具、真实配方、UI 交互读集不在本批判据面）。独立子代理审查与清洁不在本记录内（按根 `AGENTS.md` 另派）。
- 本批只提交 core 的实现与测试／文档；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-06｜事实表「面 / 点」收口 B 批（K2 点查询的限定生产者）：39 kind 域臂、39 项双向等价、前缀/分支态冻结

- 域：`spire-godot/core/command_registry.gd::ENTRIES`（23 项 table 形 kind 的 `source`：`_whole_table_kind_facts` → 各自的域臂；`TAKEOVER_SOURCE`／39 条 kind／point|table 形不变）；`spire-godot/core/game.gd`（删除 `_whole_table_kind_facts`；新增 16 个域臂：`_chain_kind_facts`／`_manual_kind_facts`／`_hook_kind_facts`／`_item_action_kind_facts`／`_retain_kind_facts`／`_rest_choice_kind_facts`／`_services_kind_facts`／`_events_kind_facts`／`_prison_kind_facts`／`_depart_kind_facts`／`_reward_kind_facts`／`_relic_bundle_kind_facts`／`_departure_kind_facts`／`_travel_step_kind_facts`／`_demo_exit_kind_facts`／`_relic_control_done_kind_facts`；`_item_use_kind_facts` 去掉 `_fact_source()` 回落）；`spire-godot/tests/architecture_cases.gd`（新增 `fact_lookup_all_kinds`／`domain_arm_guards_call_phase_branch`／`point_sources_are_kind_limited`／`point_query_builds_no_table`／`prefix_branch_tables_are_frozen`＋计数子类 `PointLookupCountingGame`＋`branch_sweep_states` 抽为共享夹具声明＋`FROZEN_TABLE_SOURCES` 23 项 rebase＋`FACT_UNIT_GROUP_UNCOVERED` 缩为空）；`spire-godot/tests/mutations.json`（5 条新判据的突变条目）；`docs/spec/fact-table-dependencies.md`、`docs/spec/response-pipeline.md`（索引区）、本记录。**表出口面（`command_facts`／`get_view`）本批一字未动**：`tests/architecture_cases.gd::baseline_constants_are_unchanged` 六个常量摘要未动、G6 26 cell 逐字段全等、分支/前缀 63 态行面冻结零移动。
- 23 个 kind 的域臂落点（守卫分支 id → 生产者）：`chain`→`card_chain`→`Cards.chain_display_facts`；`manual`→`action_tail`→`manual_facts`；`hook`→`action_tail`→`hook_facts`（自带 `phase=="rest"` 守卫）；`item_install`／`item_retrieve`→`action_tail`∨`pack`→`item_action_facts`；`retain`／`retain_skip`→`pending_retain`→`retain_facts`；`rest_rare`／`rest_card`／`rest_flask`／`rest_begin`→`rest_choice`→`_unit_rest_choice`；`service`→`shop_treasure`→`Services.facts`；`event`→`event`→`Events.facts`；`prison`→`captured_inspection`∨`action_tail`→`Prison.facts`；`depart`→`shop_treasure`／`event`／`action_tail`／`pack`→`_route_facts(该分支的出口行生产者)`（三个前缀分支直接空表：前缀 owner 不含 route 单元）；`reward`／`reward_skip`→`reward`→`_unit_reward`；`relic_bundle`→`relic_bundle`→`RelicBundle.facts`；`departure`→`departure`→`Departure.facts`；`travel_step`→`travel`→`_unit_travel_step`；`demo_end`／`demo_continue`→`cleared`→`DemoExit.facts`；`relic_control_done`→恒空臂（行只由 `core/first_turn_control.gd::select` 注入，接管期取行仍走 `TAKEOVER_SOURCE` 整表扫描）。守卫一律经 `core/game.gd::_phase_branch()`，不抄早退链。
- 先测后改（C-B-1；gherkin B-1）：扩展后的 39 kind 双向等价 harness 先在**未改源码**（HEAD `7fcc817`＋测试侧改动）上跑一轮＝`20261006T083809039-7136`，`SUITE RESULT: architecture FAIL`，`FAIL: 3/117758 assertions`；三条红项**全部归「本批必修」**（无一条判为既有语义偏差）：①`fact_units_cover_fact_source` 报 `stale uncovered entry phase:chain／chain:chain`——新加的牌链夹具使 A 批豁免项获得覆盖，豁免清单同批缩为空；②`fact_lookup_all_kinds` 报 5 个 kind 从未在表里出现（`item_retrieve`／`rest_card`／`reward_skip`／`relic_toggle`／`relic_discharge`）——夹具矩阵缺项，同批补（装备安装道具／休息候选牌／奖励候选／遗物两行）；③同判据报 6 个 kind 只由一个夹具覆盖——「至少两个夹具」这条自定门槛改为「23 项逐项必须被矩阵覆盖」＋全 kind 出现断言。规划者预警的四条候选逐条核实：`item_use` 去重＝**本批必修**（`_item_use_kind_facts` 的回落改为 `item_action_facts`，非 buff／escape 操作只由道具操作块产行）；`depart` 跨表输入＝**本批必修**（出口行按分支取生产者；三个前缀分支空表——探针实测前缀态确实无 route 单元）；`relic_control_done` 只在接管期注入＝**设计内**（恒空臂＋恒空臂体断言，非偏差）；`_item_use_kind_facts` 残留 `_fact_source()`＝**本批必修**（同批清除，文本判据覆盖）。
- C-B-2／C-B-3／C-B-4／C-B-5 判据（落点与实测）：`tests/architecture_cases.gd::fact_lookup_all_kinds` 三层——方向①（点查询＝该 kind 表内首条 params 命中行）／方向②（变异 params 接受集＝表成员集，表形 kind 跳 keys／member）／跨夹具成员语料＋域臂行集 ⊆ 表行集；绿轮 `FACT LOOKUP ALL KINDS fixtures=76 pairs=2964 dir1_rows=2297 dir2_mutations=16275 keys=1413 member=15591 cross=3670 arm_rows=833 kinds_with_rows=38`。`tests/architecture_cases.gd::point_query_builds_no_table`：75 个可行动期夹具上每个 table 形 kind 的一次 `command_fact` 的 `_fact_source`／`command_facts` 计数＝0（`POINT QUERY NO TABLE fixtures=75 kinds_answered=328 rebased_covered=22 takeover_builds=1`）；接管期声明豁免＝1（`FirstTurnControl.select` 标注的那一步），`relic_control_done` 的点查询恒空。`tests/architecture_cases.gd::point_sources_are_kind_limited`：登记表文本无 `_whole_table_kind_facts`；37 个 table 臂体无 `_fact_source()`／`command_facts()`；`_kind_facts`／`_item_use_kind_facts` 无整表回落；23 项绑定各自域臂。`tests/architecture_cases.gd::domain_arm_guards_call_phase_branch`：16 个域臂体一律调用 `_phase_branch()`，9 个 K0 前的窄来源与 1 个恒空臂逐条豁免、双向核对（豁免不能腐烂；恒空臂体必须恰为 `return []`）。`tests/architecture_cases.gd::prefix_branch_tables_are_frozen`：63 个分支/前缀态的行面摘要（13 相位 × plain／relic_bundle／departure／domain_blocked ＋ 11 个状态标志分支）与动工前实测值逐条相等，状态集合双向核对（`PREFIX BRANCH TABLES FROZEN states=63 moved=0`）——A 批审查缺口 1「前缀零移动仓库内不可重放」由此关闭。
- 门禁（R21；全部在最终字节上，跑前跑后 `Get-Process Godot*` 为空；判读＝退出码＋`SUITE RESULT: … PASS`／`UI PASS`＋`summary.json status=passed` 且 `before==after`＋无 `SOURCE CHANGED`）：①`tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 2400` → 运行号 `20261006T093725244-36280`，`SUITE RESULT: architecture PASS`，`PASS: 120652 assertions`，`SUITE architecture: 120652 assertions, 230554 ms`，exit=0（另：`-Impact` 对 `architecture` 不展开——`tests/suite_selection.gd::CROSS_AREAS` 里没有以 architecture 为交叉域的键，`RULE SCOPE: architecture` 即实际范围）；②`pwsh -NoProfile -File tools/check.ps1 -Suite recipe -TimeoutSeconds 1800` → 运行号 `20261006T094124917-2488`，收尾行 `RECIPE seed=7 commits=60 steps=60 stop=cap`、`UI PASS: 65 assertions`、`exit=0`、`stop=cap`（**注**：同一命令在 Windows PowerShell 5.1 下因环境缺陷报 `exit=`（空）并判失败——实测最小复现 `Start-Process cmd -ArgumentList '/c exit 3' -PassThru` 的 `.ExitCode` 为 Null（PSVersion 5.1.26100.9444），而 `pwsh` 7.6.6 返回 3；与本批改动无关）；③`tools/check-docs.ps1` → `DOCS RESULT: PASS`（43 份规则类文档、1940 引用、允许清单 3 条），exit=0；④`tools/check.ps1 -UIOnly -UISuite display` → 运行号 `20261006T094220610-36280`，`SUITE RESULT: display PASS`、`UI PASS: 1096 assertions`，exit=0（零移动面）；⑤`tools/check-mutation.ps1 -Check fact_lookup_all_kinds,domain_arm_guards_call_phase_branch,point_sources_are_kind_limited,point_query_builds_no_table,prefix_branch_tables_are_frozen` → 运行号 `20261006T094437252-36280`，`MUTATION SUMMARY: 5/5 entr(ies) reddened the named check and restored byte-for-byte; worktree unchanged=True`，逐条：`fact_lookup_all_kinds`（`_manual_kind_facts` 去守卫 → 域臂行集层＋跨夹具语料层红，`hash=1AFA055BFB84`）、`domain_arm_guards_call_phase_branch`（`_hook_kind_facts` 去 `_phase_branch()` → 域臂守卫红）、`point_sources_are_kind_limited`（`manual` 的 `source` 指回 `_flow_kind_facts` → 23 项绑定红）、`point_query_builds_no_table`（`_manual_kind_facts` 改回 `_fact_source()` → 整表构建计数红）、`prefix_branch_tables_are_frozen`（`_unit_flask_full` 去掉 `true` → 前缀态行面红）；5 条新判据一律不进 `known_gaps`（实跑 `MUTATION GAP FREEZE frozen=54 current=54 shrunk=0`，清单只许缩短）。
- 四态：**已测**＝上列五轮门禁 + 先测轮；**未跑**＝`-Suite all -UI -UISuite all`（H 批范围）、`-Exhaustive`、`-VerifyRunner`、`acceptance.md` §4 B 的第二条命令（`-Suite architecture,services,prison,events,rewards -UI -UISuite interface,items,services,route`——本批按派工载荷的 R21 列表执行，只跑 `display` 作零移动面；本批不改 `ui/` 与 `data/`，逐字未动）、其余 UI 窗口分类（`interface`／`body_layout`／`targeting`／`route`／`services`／`prison`／`items`／`home`／`normal_play`）、`tools/check-content.ps1`（未改 `content/packs/`）、安卓真机、打包与发布；**被跳过**＝无；**假设**＝无（`-Impact` 不展开已在①注明，非假设）。
- 中间迭代运行（只作过程记录、不作通过证据）：`20261006T085401909-7992`（`point_query_builds_no_table` 的夹具形状写错，1 处引擎错误）与 `build/probe-h-*`／`build/probe-d-*`／`build/probe-b-*` 探针轮（夹具成型、冻结值实测、变异预演）。
- 本批只提交 core 的实现与测试／文档；未推送、未 tag、未改版本号、未开 PR、未打包。批内两处过程说明（不作通过依据）：①`branch_sweep_states` 的 domain_blocked 夹具补了实例 `id`（该夹具此前只走 `_fact_source`，B 批起也走 `command_facts`，`action_targets()` 的 id 边要求每个目标有 id；类型仍是未注册值，域仍被阻断）；②冻结基线中的 63 个值在**未改源码**上实测（临时 `git stash` 核心改动后跑探针，stash 前后 `core/game.gd` sha256 一致＝`1afa055bfb84…`）。

## 2026-10-06｜事实表「面 / 点」收口 B 批补证：acceptance §4 B 全组五条命令在 `880c6f5` 上复跑（含首轮漏跑的第二条）

- 域：`spire-godot/core/command_registry.gd::ENTRIES` 的 23 项 table 形 kind 来源与 `spire-godot/core/game.gd` 对应域臂（`_*_kind_facts`；acceptance.md §2 的 B 域）；显形分类面＝规则 `architecture`／`services`／`prison`／`events`／`rewards` 与 UI `interface`／`items`／`services`／`route`（`ui/main.gd` 显示路径）＋`-Suite recipe`（seed=7／cap=60／style=trade 的真实提交链）。**本批不改任何源码／测试／文档语义，只追加本记录**：跑前跑后 `git status --short` 为空，五轮全部在 B 批提交 `880c6f5`（工作区干净）的字节上完成。
- 补证缘起（如实登记）：B 批首轮按派工载荷只跑了 `-Suite architecture -Impact`（`20261006T093725244-36280`）＋`-Suite recipe`（`20261006T094124917-2488`）＋`-UIOnly -UISuite display`（`20261006T094220610-36280`）＋五条突变检查（`20261006T094437252-36280`）与 `check-docs`，**漏跑 acceptance.md §4 B 的第二条命令**（`-Suite architecture,services,prison,events,rewards -UI -UISuite interface,items,services,route`——23 个 kind 的行为正是在这些分类里显形；该漏跑已在 B 批条目的「未跑」项如实登记）；本批把 §4 B 五条命令逐条跑齐，补齐该面证据。
- 执行口径：工作树 `C:\1\tmp\magic-spire-wt-fact-on-norms`，HEAD `880c6f5`；`GODOT_BIN` 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；串行单引擎（起前、每轮之间与全部结束后 `Get-Process Godot*` 均为空）；五条命令均经 `pwsh -NoProfile -File`（7.6.6；recipe 沿 B 批口径，Windows PowerShell 5.1 的 `Start-Process .ExitCode` 环境缺陷会使其假红）。
- 逐条命令与结果：
  - ①`tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 900` → 运行 `20261006T101305595-1352`：`DOCS RESULT: PASS`（43 规则文档／1940 引用／允许清单 3）＋`RULE SCOPE: architecture`（`CROSS_AREAS` 未展开）＋`SUITE RESULT: architecture PASS`＋`PASS: 120652 assertions`，`CHECK rules: 238.10s`，exit 0。
  - ②`tools/check.ps1 -Suite architecture,services,prison,events,rewards -UI -UISuite interface,items,services,route -TimeoutSeconds 1800`（**首轮漏跑项**）→ 运行 `20261006T101719242-41788`：`RULE SCOPE: architecture,services,rewards,events,prison`，五分类全 `SUITE RESULT: … PASS`——architecture 120652 断言／240280 ms、services 643／5749 ms、rewards 1290／12686 ms、events 901／2521 ms、prison 1411／82603 ms，`PASS: 124897 assertions`，`CHECK rules: 345.29s`；`UI SCOPE: items,route,services,interface`，四分类全 `SUITE RESULT: … PASS`——items 46 断言／5449 ms、route 255／29774 ms、services 288／18862 ms、interface 473／36964 ms，`UI PASS: 1062 assertions`，`CHECK ui: 103.45s`；exit 0。该轮 architecture 分类内 B 批五条判据的绿行：`FACT LOOKUP ALL KINDS fixtures=76 pairs=2964 dir1_rows=2297 dir2_mutations=16275 keys=1413 member=15591 corpus_kinds=38 cross=3670 arm_rows=833 kinds_with_rows=38`、`DOMAIN ARM GUARDS arms=16 exempt=9 guardless=1 unguarded=0`、`POINT SOURCES KIND LIMITED kinds=37 arms=16 known=23`、`POINT QUERY NO TABLE fixtures=75 kinds_answered=328 rebased_covered=22 takeover_builds=1`、`PREFIX BRANCH TABLES FROZEN states=63 moved=0`。
  - ③`pwsh -NoProfile -File tools/check.ps1 -Suite recipe -TimeoutSeconds 1800` → 运行 `20261006T102506199-31960`：`RUN IDENTITY head=880c6f5d9dc23f4f2c9e225627e4dc4c9eac61a9 dirty=0`，`FK SESSION seed7-trade commits=60 steps=60 stop=cap`，收尾行 `RECIPE seed=7 commits=60 steps=60 stop=cap`、`UI PASS: 65 assertions`、`CHECK recipe: 45.39s, exit=0`，exit 0。
  - ④`tools/check-mutation.ps1 -Check point_query_builds_no_table` → 运行 `20261006T102613450-23360`：`MUTATION point_query_builds_no_table [core/game.gd]: RED exit-red=True restored=True sha256=1AFA055BFB84 535.9s`；突变轮内具名判据红——`ERROR: point_query_builds_no_table: one command_fact answers from the kind arm without building the table: ["battle:12:manual fact_source=1 command_facts=0 equal=true", …]`（同一突变顺带红 `domain_arm_guards_call_phase_branch`／`point_sources_are_kind_limited`，同因）；`MUTATION SUMMARY: 1/1 entr(ies) reddened the named check and restored byte-for-byte; worktree unchanged=True`，exit 0。
  - ⑤`tools/check-mutation.ps1 -Check point_sources_are_kind_limited` → 运行 `20261006T103517801-42400`：`MUTATION point_sources_are_kind_limited [core/command_registry.gd]: RED exit-red=True restored=True sha256=7718B744ED1C 221.6s`；突变轮内具名判据红——`ERROR: point_sources_are_kind_limited: the 23 rebased kinds stay on their domain arms have=22 ["chain", …]`（缺 `manual`，22 项）；`MUTATION SUMMARY: 1/1 entr(ies) reddened the named check and restored byte-for-byte; worktree unchanged=True`，exit 0。
- 判读（五条全部满足）：退出码 0×5；各分类 `SUITE RESULT: … PASS`（规则 5＋UI 4）与 recipe `exit=0`、收尾 `stop=cap`；三轮 `summary.json` `status=passed` 且 `before==after=6E1518EE6CC168E3578FA3928EADE6096F37AEB1C68FC685839D95821A4350F3`（同一次运行内的守卫；与该批首轮同指纹，architecture 120652 与 recipe 60/60 两项与首轮逐项一致）；全部 `check-*.log`／`check-recipe.log` 无 `SOURCE CHANGED`、无 `Failed to read the root certificate store.`；两轮突变 `worktree unchanged=True`、逐字节还原并哈希自证。**本轮无红项、无既有语义偏差**；④⑤的红只发生在突变轮内、按设计发生，还原后工作区回到 `880c6f5` 的干净字节。
- 产物：`spire-godot/build/checks/20261006T101305595-1352/`、`spire-godot/build/checks/20261006T101719242-41788/`、`spire-godot/build/checks/20261006T102506199-31960/`、`spire-godot/build/mutations/20261006T102613450-23360/`、`spire-godot/build/mutations/20261006T103517801-42400/`（本工作树 build/，gitignored、不入库）。跑完 `git status --short` 为空：本轮未发生 `.import` 行尾改写（工作树已预导入），无需还原。
- 四态：**已测**＝上列五条命令（acceptance §4 B 列出的全部命令已逐条覆盖，首轮漏跑项补齐；B 批首轮 ①③④⑤ 的证据仍有效，本批为同 HEAD、同指纹的复跑，逐分类计数一致）；**未跑**＝`-Suite all -UI -UISuite all`（H 批范围）、`-Exhaustive`、`-VerifyRunner`、其余 UI 窗口分类（`display` 已由 B 批首轮 `20261006T094220610-36280` 作零移动证据；`body_layout`／`targeting` 按批次分工未跑；`home`／`normal_play` 按 acceptance §4 取舍只在 F／H 跑）、其余 22 条突变条目、`tools/check-content.ps1`（未改 `content/packs/`）、安卓真机、打包与发布；**被跳过**＝无；**假设**＝无。
- 本批只追加本记录并提交到本地 `.git`（无源码／测试／文档语义改动）；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-06｜事实表「面 / 点」收口 C 批（K3 点形家族一次构造）＋ B 批审查四条加固

- 域：`spire-godot/core/game.gd::attack_facts`／`equipment_spell_facts`／`attack_point_keys`／`attack_point_walk`（新）／`_attack_point_walk_cached`（新）／`_attack_point_pair`（新）；`spire-godot/core/card_effects.gd::card_facts`／`_card_point_rows`（新）／`_card_point_row`（新，由 `card_point_fact` 的家族分派提出）／`_card_point_site_choices`（新）／`_card_point_card_keys`（改为取同一枚举）；域内测试 `tests/architecture_cases.gd` 与 `tests/mutations.json`。输入域＝`r1_cells()`（26 cell）／`branch_sweep_states()`（63 态）／四个点形家族夹具（`attack_self_release_fixture`／`card_branch_fixture` 一族／`card_exhaust_fallback_fixture`／巫女 `witch` 初始化／接管夹具）。依据＝`docs/spec/fact-table-dependencies.md`（K3 与四个唯一入口）、`docs/spec/response-pipeline.md` 判据索引区；契约＝`docs/spec/` 内两份 + 本片设计 K3／plan §3 C 行／acceptance.md §1 C 段与 §4 C 命令清单。
- 落点（C 本体＝三个函数「走查一次直接产行」）：①`core/game.gd::attack_point_walk(g)` 是新的一次走查（产出 `{params, row}` 成对结果；`core/game.gd::_attack_point_pair` 做 `command_params` 归一，重复归一化 params 复用首条行——与 `attack_point_fact` 按 id 解析到首个对象的内容面同序）；`attack_point_keys` 改为取走查项的 params（唯一枚举不变），`attack_facts`／`equipment_spell_facts` 改为按 `params.target` 直接取两半的行（不再「keys × build」，也不再两半各走一遍）。②`core/game.gd::_attack_point_walk_cached(g)` 是批内复用入口：形态同 `core/game_view.gd::equipment_entry` 的 `equipment_views`——只在本读取批次（`core/game.gd::_begin_equipment_read` 的寿命）内复用、出批即弃、不按键判等、不挂 `self`；命中即深拷，批次外调用每次现算（退化等同改动前）。③`core/card_effects.gd::card_facts` 改为一次走查（`_card_point_rows`）直接产行，并在读取批次内按手牌 uid 复用（批内条目 `card_point_rows`）；`_card_point_row` 是新提的唯一单行构造（点查询与表 pass 共用），`_card_point_site_choices` 是 site × `_target_choices` 的唯一枚举（keys 与表 pass 共用）。
- 计数证据（测试侧计数子类＝包装 `core/game.gd::_fact`（事实的唯一构造点）与 `attack_point_walk`；同一只读探针脚本在两棵树上各跑一次，探针不入库、跑完即删）：**逐家族构造次数／行数**——`battle:12`：attack 改前 54／18（×3）→ 改后 18／18（×1），card 60／60（两树同）；`prepare:12+self_release`：equipment_spell 改前 36／12（×3）→ 改后 12／12（×1）；`witch:battle`：witch 改前 48／16（×3）→ 改后 16／16（×1）。**全表 `_fact` 调用数／返回行数**：`battle:12` 136→100（＝行数）、`prepare:12+self_release` 120→96（＝行数）、`witch:battle` 108→76（＝行数）。**card 走查次数**（单卡手牌 `strong_elbow`：`_card_slot_walk` → `core/game.gd::has_targets_at` 的问询面）＝改前 6 次（2 个声明槽 × 3 次走查＝1 次 keys ＋ 2 次按键重解析）→ 改后 2 次（每槽恰一次＝一卡一次走查）。探针自证：改前树上的 live 计数与「两步形态」重构逐值相同（attack 54／equipment 36／witch 48），且三处行集逐字节相等（attack／equipment／card 各 `true`）⇒ 重构忠实、两树可比。
- 新判据（随批给突变，一律不进 `known_gaps`；`MUTATION GAP FREEZE frozen=54 current=54 shrunk=0`）：`tests/architecture_cases.gd::table_rows_constructed_once`（C-C-1：每行恰构造一次，计数子类按 payload 逐家族对照返回行集；单卡槽位问询面钉「一卡一次走查」；28 夹具 3884 行 / attack=108 witch=16 equipment_spell=12 card=2483）、`tests/architecture_cases.gd::table_walk_single_entry`（C-C-2：三处生产者体内走查入口各恰一次且无「先取键再构造」两步形态，走查／keys／build／member 各一处实现）、`tests/architecture_cases.gd::point_family_rows_respect_read_scope`（C-C-3：测试侧持批时三处调用与无批次逐字节相等、攻击走查恰一次；出批后改状态再调用必须按新状态给值）。G6 零移动：`R5_BASELINE` 与四个 mask 常量一字未改（`tests/architecture_cases.gd::baseline_constants_are_unchanged` 绿）；唯一移动的测试内字面面＝`tests/architecture_cases.gd::PAYLOAD_WRITE_WHITELIST`（card 单行构造的两处 payload 写点随 `core/card_effects.gd::_card_point_row` 移动，条数与函数面不变）。
- B 批审查四条加固（逐条落点）：①计数判据扩面——`tests/architecture_cases.gd::point_query_builds_no_table` 的计数子类加到 `_join_fact_units`／`_phase_branch_units`／`_phase_facts` 直调，样本从「每 kind 首行」改为覆盖每条（去重后）表行（75 夹具 × 823 行＝823 个去重 params），恒假子句 `if kind in BATCH_ARM_SOURCES` 改为按 `ENTRIES[kind].source` 判；唯一一处相位单元豁免 `tests/architecture_cases.gd::POINT_LOOKUP_PHASE_UNIT_EXEMPT`（`end`×`overload_climax`＝该臂按设计返回本分支单元）逐条断言恰 1 次且必须被观测到（运行期打印 `phase_unit_exempt=["end"]`）。②文本判据加固——`tests/architecture_cases.gd::point_sources_are_kind_limited` 把 kinds=37／arms=16／total=25 由打印改为断言（`POINT_SOURCE_TABLE_KINDS`／`POINT_SOURCE_DOMAIN_ARMS`／`POINT_SOURCE_ARMS_TOTAL`），文本扫描扩到被调 helper（`TABLE_ARM_HELPERS` 22 项白名单：改名致提取为空即红；臂体调用未登记的本地函数即红；整表形态面 `TABLE_ARM_WHOLE_TABLE_CALLS` 含 `_join_fact_units(`／`_phase_branch_units(`；`_phase_facts` 单条声明豁免且必须仍被臂调用）。③可自证——`tests/architecture_cases.gd::PREFIX_BRANCH_TABLE_SOURCE_SHA256`（＝B 批实测时 `core/game.gd` 的 sha256，随判据打印）＋`tests/architecture_cases.gd::PREFIX_BRANCH_TABLE_STATE_COUNT=63`，比较由 `compared>=48` 改为「扫描＝基线＝字面状态数」三处相等（删一态并同步删基线即红）。④守卫等价——新增 `tests/architecture_cases.gd::domain_arm_branch_ids_are_pinned`：文本层双向（每臂体点名的分支 id 字面恰等于 `DOMAIN_ARM_BRANCH_IDS`，两臂互换守卫即红）＋运行期「臂行 ⇒ 分支 ∈ `DOMAIN_ARM_ROW_BRANCHES`」＋逐分支必须被观测到行或登记进 `DOMAIN_ARM_ROW_BRANCHES_UNOBSERVED`（双向）；覆盖不到的两条（`_depart_kind_facts` × `shop_treasure`／`event`，需要「服务／事件已产出离开行」的夹具）与 9 个 domain 合成守卫来源（`DOMAIN_ARM_DOMAIN_GUARDED`）已逐条登记进依赖索引的「仍靠人审」节。
- 突变（`tools/check-mutation.ps1 -Check …`；逐条 RED＋逐字节还原、`worktree unchanged=True`）：`table_rows_constructed_once`（`20261006T111136015-32472`，217.2s；突变＝`attack_facts` 改回 `attack_point_keys` × `attack_point_fact` 两步 → 红行 `attack constructed=36 rows=18`）、`table_walk_single_entry`（`20261006T111514004-19944`，246.5s；突变＝`card_facts` 改回 `_card_point_card_keys` × `card_point_fact` → 红行 `card_facts: walk entry appears 0 times` 等三处）；`point_family_rows_respect_read_scope`／`domain_arm_branch_ids_are_pinned`／`point_query_builds_no_table`／`point_sources_are_kind_limited`／`prefix_branch_tables_are_frozen` 同轮（`20261006T111921167-32752`，199／215.4／279.2／212.2／216.5s，`MUTATION SUMMARY: 5/5 entr(ies) reddened the named check and restored byte-for-byte; worktree unchanged=True`）——依次为：跨批次常驻缓存（红行 `the walk result outlives its read batch`）、`_chain_kind_facts` 守卫字面换成 `action_tail`（红行 `guard never names card_chain` + `guards on undeclared branch action_tail`）、臂内 `_join_fact_units(_phase_branch_units("action_tail"))`（红行 `join=2 branch_units=1`）、`manual_facts` 内加 `_join_fact_units(_phase_branch_units("prison_end"))`（红行 `manual_facts->_join_fact_units(`／`->_phase_branch_units(`）、状态数字面 63→62（红行 `compared=63 baseline=63 declared=62`）。
- 门禁（R21；全部在最终字节上，跑前跑后 `Get-Process Godot*` 为空＝单引擎串行；判读＝退出码＋`SUITE RESULT: … PASS`／`UI PASS`＋`summary.json status=passed` 且 `before==after`＋无 `SOURCE CHANGED`＋无证书错误）：①`tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 2400` → 运行号 `20261006T113953328-17412`：`DOCS RESULT: PASS`（43 规则文档／2028 引用／允许清单 3）＋`RULE SCOPE: architecture`（`-Impact` 未展开；`tests/suite_selection.gd::CROSS_AREAS` 无以 architecture 为交叉域的键）＋`SUITE RESULT: architecture PASS`＋`PASS: 120677 assertions`，`CHECK rules: 249.42s`，exit 0；`before==after=DC5B5C7A1A8C34869CFA60C06BC91D3B781F9B26CFC57410E12B3091C09BD61F`。②`tools/check.ps1 -UI -UISuite display,interface,body_layout,targeting -TimeoutSeconds 1800` → 运行号 `20261006T114410447-28240`：规则 `architecture`＋`runner` 均 PASS（`PASS: 121218 assertions`，`CHECK rules: 242.21s`），UI 四模块 `display`／`body_layout`／`targeting`／`interface` 全 PASS（`UI PASS: 1967 assertions`，`CHECK ui: 224.92s`），exit 0，同指纹。③`tools/check-docs.ps1` → `DOCS PASS: 43 rule-class document(s), 2028 reference(s) checked, allowlist 3 entrie(s)`，exit 0（与①内联阶段一致）。④本批判据的突变七条（上）。本轮 architecture 分类内本批判据的绿行：`POINT QUERY NO TABLE fixtures=75 rows=823 distinct_answered=823 rebased_covered=22 phase_unit_exempt=["end"] takeover_builds=1`、`PREFIX BRANCH TABLES FROZEN states=63 moved=0 source_sha256=1AFA055BFB84119B6B8BA34B46C67C62BDBF6ADB9E77BDF9B7F1F2A71B8DE76A`、`DOMAIN ARM BRANCH IDS arms=25 fixtures=75 arm_rows=424 runtime_problems=0 unobserved=0`、`POINT FAMILY ONCE fixtures=28 rows=3884 attack=108 witch=16 equipment_spell=12 card=2483 walk_slots=2`、`TABLE WALK SINGLE ENTRY producers=3 unique_defs=8`、`POINT FAMILY READ SCOPE fixtures=2 stale_checked=1`、`MUTATION GAP FREEZE frozen=54 current=54 shrunk=0`。**acceptance.md §4 C 的四条命令逐条覆盖**（架构 `-Impact`／UI 四模块／`-Check table_rows_constructed_once`／`-Check table_walk_single_entry`），另按派工载荷补：同一架构命令的 `-TimeoutSeconds 2400`、其余五条本批判据的 mutation（同②轮外的专用轮）、`tools/check-docs.ps1`。
- 四态：**已测**＝上列四组（架构 -Impact、UI 四模块、check-docs、七条突变）；**未跑**＝`-Suite all -UI -UISuite all`（H 批范围）、`-Exhaustive`、`-VerifyRunner`、`-Suite recipe`（acceptance §4 C 未列；本批不改提交事务、随机与 `ui/` 提交路径）、其余 UI 窗口分类（`route`／`services`／`prison`／`items`／`home`／`normal_play`）、其余 21 条突变条目、`tools/check-content.ps1`（未改 `content/packs/`）、安卓真机、打包与发布；**被跳过**＝无；**假设**＝无。中间迭代轮（只作过程记录、不作通过证据）：`20261006T104837659-908`（`-Suite runner` 语法烟测，PASS）、`20261006T104851267-28948`（首轮红＝`payload_write_sites_are_pinned`：card 单行构造的 payload 写点位次随本批移动）、`20261006T105455872-41000`（次轮红＝新判据三处自身口径：走查次数断言、期望表口径、样本计数）、`20261006T110018481-26112`（三轮红＝`table_rows_constructed_once` 的走查次数断言与 `walk_calls` 期望）、`20261006T110445976-43472`（转绿轮），另加只读计数探针两轮（本工作树＋`C:/1/tmp/magic-spire-wt-c-probe` 探针树，用后删除）。
- 产物：`spire-godot/build/checks/20261006T113953328-17412/`、`spire-godot/build/checks/20261006T114410447-28240/`、`spire-godot/build/mutations/20261006T111136015-32472/`、`spire-godot/build/mutations/20261006T111514004-19944/`、`spire-godot/build/mutations/20261006T111921167-32752/`（本工作树 build/，gitignored、不入库）；探针树 `C:/1/tmp/magic-spire-wt-c-probe` 用后 `git worktree remove --force` 删除。跑完 `git status --short` 只含本批四个受控文件（`core/game.gd`／`core/card_effects.gd`／`tests/architecture_cases.gd`／`tests/mutations.json`）与两份 `docs/spec` 索引文档，无 `.import` 行尾改写、无调试残留。
- 本批只提交本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-06｜事实表「面 / 点」收口 D 批（K1-D 批内复用的唯一机制）＋ C 批审查两条加固

- 域：`spire-godot/core/game.gd::_batch_rows`（新＝唯一机制）／`BATCH_ROW_ENTRIES`／`BATCH_TABLE`／`BATCH_ATTACK_WALK`／`BATCH_CARD_ROWS`（新常量）／`command_facts`（整表条目＋构建体内联到该出口）／`attack_point_keys`／`attack_facts`／`equipment_spell_facts`（改经机制取用，空行过滤＝改动前语义）／`_attack_point_pair`（重复归一化 params 改取独立副本）；`spire-godot/core/card_effects.gd::card_facts`／`_card_point_rows`（同机制取用＋独立副本）；测试 `spire-godot/tests/batch_reuse_recorder.gd`（新，记录器夹具）／`spire-godot/tests/architecture_cases.gd`（五条新判据＋两处 C 批文本标记 rebase）／`spire-godot/tests/recipe_driver.gd`（D-5 报告＋夹具类改为记录器）／`spire-godot/tests/mutations.json`（五条新条目＋三条 A／B／C 批锚点 rebase）；文档 `docs/spec/fact-table-dependencies.md`／`docs/spec/response-pipeline.md`。输入域＝`r1_cells()`（26 cell）／点形家族夹具（装备自解／巫女／重复 params／逐卡分支族）／真实输入配方（seed=7／cap=60／style=trade，与 `tests/recipe_driver.gd` 同一策略）。依据＝`docs/spec/fact-table-dependencies.md`（批内复用）与 `docs/spec/response-pipeline.md` 判据索引区；契约＝设计 §K1-D／§5.0 D 行、plan §3 D 行、gherkin D-1…D-5、acceptance §1 C-D-1…C-D-5 与 §4 D 命令清单。
- 落点①（D 本体＝一条机制取代两处各自实现）：`core/game.gd::_batch_rows(entry, build)` 是批内复用的**唯一入口**——形态同 `core/game_view.gd::equipment_entry` 的 `equipment_views`，条目只落在 `core/game.gd::_begin_equipment_read` 的批次字典（`BATCH_ROW_ENTRIES` 子字典）上，**寿命＝读取批次**、出批即弃、不按键判等、不跨提交、不挂 `self`；**单一深拷贝语义**＝命中与首算都返回深拷贝（批次内存量只经深拷外出）。三条条目取代的旧实现：①整表＝`command_facts` 内的 `BATCH_TABLE` 条目（此前每次调用都重建整表）；②攻击走查＝`attack_facts`／`attack_point_keys`／`equipment_spell_facts` 共用的 `BATCH_ATTACK_WALK` 条目（取代 C 批的 `core/game.gd::_attack_point_walk_cached`，该函数删除）；③逐卡行＝`core/card_effects.gd::card_facts` 的 `BATCH_CARD_ROWS:<uid>` 条目（取代 C 批 `card_facts` 体内联的 `card_point_rows` 字典）。批次外调用每次现算，与无批次调用逐字节相等。
- 落点②（四条守卫，§K1-D）：①寿命边界＝批次（测试侧可观测）＝`tests/architecture_cases.gd::fact_table_reuse_within_batch`：测试侧持批时同一批次内三次 `get_view()` ＋一次 `command_facts()` 只构建一次（`reuse_requests=3/4`、`reuse_builds=1/1`、`_fact_source` 调用=1），三次 `display_facts` 与同类的从零实例逐字节相等，出批后下一次读取必重建（builds=2），读期间快照不变；②静默点不变量＝`tests/architecture_cases.gd::fact_table_cache_lifetime_is_pinned`（文本层）：条目容器只被 `core/game.gd::_batch_rows` 读写、机制体不见 `self`／`set_meta`／`get_meta`／`is_same`／`version`／`state`、三个条目名各只出现在声明的调用点、`command_facts()` 的生产调用点只有 `core/game_view.gd::build`、`core/game.gd::dispatch` 的投影取用（`command_fact(cmd)`）位于 `state=state.duplicate(true)` **之前**且事务窗口内无投影调用、接管臂仍点名整表出口、`get_view()` 仍是四点白名单（同批复跑既有 `tests/architecture_cases.gd::get_view_call_sites_are_pinned`）；③独立实例 oracle＝`tests/architecture_cases.gd::table_reuse_matches_fresh_projection`：真实配方 60 提交逐次（每次新建从零实例＋`export_snapshot`→`restore_snapshot`）比对表面逐字节相等（`commits=60 steps=60 stop=cap`，含批内两次取用），oracle 自检＝restore 后除 `core/game.gd::restore_snapshot` 声明的版本推进外 state 逐字节相等；④配方 60 提交端到端＝`-Suite recipe`（`RECIPE seed=7 commits=60 steps=60 stop=cap`）。成功路径零移动：G6 26 cell、`R5_BASELINE` 与四个 mask 常量一字未改；`PREFIX BRANCH TABLES FROZEN states=63 moved=0`、39 kind 双向 harness（`FACT LOOKUP ALL KINDS fixtures=76 pairs=2964 dir1_rows=2297 dir2_mutations=16275 keys=1413 member=15591`）、`T4 ROW EQUIVALENCE cells=7 rows=894 kinds=15` 全绿且逐值与 C 批相同。
- 落点③（C 批审查两条加固）：**加固 1（批内别名）**＝取用边界不可污染：`core/game.gd::_batch_rows` 命中即深拷（C 批 card 首算路径「把活数组存批又原样返回」的形态被删除），`core/game.gd::_attack_point_pair` 与 `core/card_effects.gd::_card_point_rows` 的重复归一化 params 改取首条行的 `duplicate(true)`（改前是同一引用的两行，旧两步路径是两个独立等值字典）；判据＝`tests/architecture_cases.gd::batch_reuse_never_aliases_callers`（①三条条目逐条「批内取回的行被调用方就地改写后，同批第二次取用仍等于从零路径」，夹具＝battle／prepare／prison × 12 件；②attack 重复 params 夹具 9 组行「等值但不同一」，写一行不漏到另一行）。代价＝每条目每次取用一次深拷（整表 pass 每次一条；走查／逐卡条目的重复项各一次；不改随机、不改判定、不改事务）。**加固 2（空行静默面）**＝按旧语义恢复过滤 **且** 加机械判据：`attack_facts`／`equipment_spell_facts` 取行前恢复改动前的 `is_empty` 过滤（未来任一家族回 `{}` 与改动前逐字节等价），并新增 `tests/architecture_cases.gd::walk_rows_are_never_empty` 同时钉「两半的取行都保留该过滤（文本＋顺序）」与「`core/game.gd::attack_point_walk` 在 29 个夹具上产出的 163 条 row 全非空（`families={ "basic": 135, "witch": 16, "self_release": 12 }`）」。理由：只做过滤会把家族缺陷变成静默少一行，只做判据则矩阵外的家族仍可静默回 `{}`；两条同时落，过滤今天不吞任何行、且将来先红。
- 触及 A／B／C 批产物（留痕，均为 D 的必然连带）：①`tests/architecture_cases.gd::TABLE_WALK_ENTRIES` 的两行标记由已删除的 `_attack_point_walk_cached(` 改为走查本身 `attack_point_walk(`（同判据语义不变，条目名改由 D-3 文本判据钉）；②`tests/architecture_cases.gd::table_walk_single_entry` 体内 `keys_body` 断言同一改法；③`tests/mutations.json` 三条锚点 rebase（`table_rows_constructed_once` 的 `attack_facts` 体、`table_walk_single_entry` 的 `card_facts` 体、`point_family_rows_respect_read_scope` 的跨批常驻缓存变异改锚到 `_batch_rows` 的批次分支）——三条均在最终字节上重跑并逐字节还原（见下）。`PIPELINE_LOOKUP_EDGES`／`FROZEN_TABLE_SOURCES`／`PAYLOAD_WRITE_WHITELIST`／`R5_BASELINE`／四个 mask 常量／`known_gaps`（54）一字未改。
- 新增文件：`spire-godot/tests/batch_reuse_recorder.gd`（测试侧记录器夹具＝`tests/game_fixture.gd` ＋ 机制入口包装计数；`tests/recipe_driver.gd` 的 `game_class` 字段随之写为 `tests/batch_reuse_recorder.gd`）。生产源码不带计数器（`core/` 无计数、无开关、无计时钩子）。
- D-5 计数报告（记录器口径＝`core/game.gd::_batch_rows` 的请求次数与真实构建次数之差＝同一批次内的重复取用次数；只进报告、不作判据、不写提速；`-Suite recipe` 运行 `20261006T134046991-10556`）：`TABLE REUSE entry=attack_walk requests=152 builds=78 repeated=74`、`entry=card_rows requests=362 builds=362 repeated=0`、`entry=table requests=100 builds=100 repeated=0`、`total entries=3 requests=614 builds=540 repeated=74`——真实 UI 路径上唯一被批内条目挡下的重复构建是攻击走查两半共享同一次走查（74 次），整表条目在 UI 路径上重复为 0（每次 `get_view`／`command_fact` 各开自己的批次）。
- 门禁（R21；全部在最终字节上，跑前跑后 `Get-Process Godot*` 为空＝单引擎串行；判读＝退出码＋`SUITE RESULT: … PASS`／`UI PASS`＋`summary.json status=passed` 且 `before==after`＋无 `SOURCE CHANGED`＋无证书错误）：①`tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 900` → 运行号 `20261006T133645306-29292`：`DOCS RESULT: PASS`（43 规则文档／2096 引用／允许清单 3）＋`RULE SCOPE: architecture`（`CROSS_AREAS` 无以 architecture 为交叉域的键）＋`SUITE RESULT: architecture PASS`＋`PASS: 120703 assertions`（＝C 批 120677 ＋ 本批 26 条新断言），`CHECK rules: 223.14s`，exit 0；`before==after=D0296D02EE016D31E9F61F3C377DF4E3C3DE31A144B439F750F676A30AF5B017`。②`tools/check.ps1 -Suite recipe -TimeoutSeconds 1800` → 运行号 `20261006T134046991-10556`：`RUN IDENTITY head=2637199904124b76491d6698b6edb9b2279f00c3 dirty=8`、`RECIPE seed=7 commits=60 steps=60 stop=cap`、`UI PASS: 65 assertions`、`CHECK recipe: 44.81s, exit=0`，exit 0，同指纹。③`tools/check-docs.ps1` → `DOCS PASS: 43 rule-class document(s), 2096 reference(s) checked, allowlist 3 entrie(s)`，exit 0（与①内联阶段一致）。④突变（`tools/check-mutation.ps1`；四轮：`20261006T134152767-31672`／`20261006T134945705-39348`／`20261006T135709635-35140`／`20261006T140415946-10468`；8 条全 RED＋逐字节还原＋`worktree unchanged=True`）：`fact_table_reuse_within_batch`（242.3s；突变＝删批内条目「每次现算」→ 红行 `requests=3/4 builds=3/4 fact_source=3`、`after the batch ended the next read must rebuild the table (builds=5)`）、`fact_table_cache_lifetime_is_pinned`（224.3s；突变＝机制体内加 `self` 元数据常驻 → 红行 `never stores on self, never keys by identity or version and never reads state: ["set_meta("]`）、`table_reuse_matches_fresh_projection`（203.7s；突变＝条目改挂实例元数据跨批存活 → 红行 `commit 1 kind=attack version=2: reused table differs from the from-zero table …` ＋ `the recipe committed 60 times before its natural end have=2`）、`batch_reuse_never_aliases_callers`（233.6s；突变＝命中不深拷「返回存量」→ 红行 `… a caller writing into the rows it got back changed the batch entry (first_equal=true second_equal=false)`）、`walk_rows_are_never_empty`（206.7s；突变＝删去 `attack_facts` 的空行过滤行 → 红行 `attack_facts: guard=-1 append=166`）、`table_rows_constructed_once`（213.4s，C 批锚点 rebase 后重跑；突变＝`attack_facts` 改回 `keys`×`build` 两步 → 红行 `attack constructed=36 rows=18`）、`table_walk_single_entry`（246.7s，rebase 后重跑；突变＝`card_facts` 改回两步 → 红行 `card_facts: walk entry appears 0 times`）、`point_family_rows_respect_read_scope`（211.8s，rebase 后重跑；突变＝跨批常驻缓存 → 红行 `the walk result is reused inside one read batch and dropped when the batch ends`）；本批新判据五条**一律不进** `known_gaps`（`MUTATION GAP FREEZE frozen=54 current=54 shrunk=0`）。本轮 architecture 分类内本批判据的绿行：`TABLE REUSE WITHIN BATCH fixtures=3 rejected=2`、`BATCH CACHE LIFETIME entries=3 container=["core/game.gd::_batch_rows"]`、`TABLE REUSE FRESH ORACLE commits=60 steps=60 stop=cap phases=["battle", "reward", "prepare", "travel", "event", "map", "captured", "prison"]`、`BATCH REUSE ALIAS cells=3 duplicate_groups=9`、`WALK ROWS NONEMPTY fixtures=29 pairs=163 families={ "basic": 135, "witch": 16, "self_release": 12 }`；C 批与本片既有判据逐值不变（`POINT FAMILY ONCE fixtures=28 rows=3884 attack=108 witch=16 equipment_spell=12 card=2483 walk_slots=2`、`TABLE WALK SINGLE ENTRY producers=3 unique_defs=8`、`POINT FAMILY READ SCOPE fixtures=2 stale_checked=1`、`PREFIX BRANCH TABLES FROZEN states=63 moved=0`、`POINT QUERY NO TABLE fixtures=75 rows=823 distinct_answered=823 rebased_covered=22 phase_unit_exempt=["end"] takeover_builds=1`、`FACT LOOKUP ALL KINDS fixtures=76 pairs=2964 …`、`DOMAIN ARM BRANCH IDS arms=25 fixtures=75 arm_rows=424 runtime_problems=0 unobserved=0`、`T4 ROW EQUIVALENCE cells=7 rows=894 kinds=15`）。**acceptance.md §4 D 的四条命令逐条覆盖**（架构 `-Impact`／`-Suite recipe`／`-Check fact_table_reuse_within_batch`／`-Check fact_table_cache_lifetime_is_pinned`），另按派工载荷补：另三条新判据与三条 A／B／C 批 rebase 锚点的突变重跑、`tools/check-docs.ps1`，**无漏跑**。
- 产物：`spire-godot/build/checks/20261006T133645306-29292/`、`spire-godot/build/checks/20261006T134046991-10556/`、`spire-godot/build/mutations/20261006T134152767-31672/`、`spire-godot/build/mutations/20261006T134945705-39348/`、`spire-godot/build/mutations/20261006T135709635-35140/`、`spire-godot/build/mutations/20261006T140415946-10468/`（本工作树 `build/`，gitignored、不入库）。跑完 `git status --short` 只含本批七个受控文件＋一个新测试文件；无 `.import` 行尾改写、无调试残留（探针只落在 `build/` 且已删除）。中间迭代轮（只作过程记录、不作通过证据）：开发期跑过架构分类数轮（含三处自身口径红：`get_view` 与 `command_facts` 返回形状混用、跨类夹具状态不可比、oracle 两侧对称读同一陈旧值）与突变数轮（含两处口径红：`walk_rows` 的「空行」突变打断整轮、oracle 突变未落在批次路径上），全部在最终字节前修完并按最终字节重跑。
- 四态：**已测**＝上列四组（架构 `-Impact`、recipe、check-docs、8 条突变）；**未跑**＝`-Suite all -UI -UISuite all`（H 批范围）、`-Exhaustive`、`-VerifyRunner`、全部 UI 窗口分类（本批未改 `ui/`——UI 侧唯一改动是 `tests/recipe_driver.gd` 的夹具类与报告行，已由 recipe 轮覆盖）、其余 25 条突变条目、`tools/check-content.ps1`（未改 `content/packs/`）、安卓真机、打包与发布；**被跳过**＝无；**假设**＝无。
- 本批只提交本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-06｜事实表「面 / 点」收口 D 批补证：门禁证据绑到提交字节（操作卡条文）＋ D 批两轮在提交后的干净树上补跑

- 域：`skills/repo-ops/SKILL.md`（「工作树并发纪律」节 +3 条：门禁证据绑到提交字节、`RUN IDENTITY` 的 `head`／`dirty` 判读、指纹只是运行内护栏）；`docs/record/verification.md`（本条目）。**产品源码／测试／内容包逐字节未动**；补跑两轮的源码指纹 `6D5D47ED513333498B11403EE33D53927B6996E9D9624B2C49D074D3D5EF33C7`（与 D 批 `D0296D02…` 不同——本批改了规则类文档 `skills/repo-ops/SKILL.md`，它在指纹内）。
- 作废登记（独立审查的唯一 [应修]，如实）：D 批的 `tools/check.ps1 -Suite architecture -Impact` 运行 `20261006T133645306-29292` 与 `tools/check.ps1 -Suite recipe` 运行 `20261006T134046991-10556` 都在**提交前**取证——recipe 轮 `RUN IDENTITY head=2637199904124b76491d6698b6edb9b2279f00c3 dirty=8`（head 指基线 C 批），architecture 轮无独立身份行，两轮与提交 `e258bce` 无字节对应 ⇒ 不再作为 `e258bce` 的通过证据，由本批在提交 `1770fe8`（操作卡）后的干净树上补跑取代（新运行号见下）。
- 条文原文（`skills/repo-ops/SKILL.md`「工作树并发纪律」节末）：①「**门禁证据必须绑到提交字节**：门禁只在**已提交的干净树**（`git status --short` 为空）上取；若因故必须在提交前跑，则**提交后须在同一命令上补跑一轮**并记录新运行号。」②「`RUN IDENTITY` 的 `head` 必须等于被验证的提交、`dirty` 必须为 0；`dirty≠0` 或 `head` 指基线时，该轮**不作证据**。」③「指纹（`before==after`）是**运行内的护栏**，不是"这段日志属于哪个提交"的身份——身份只由 `head`＋`dirty`＋**所载文件哈希**给。」本条目即按该条文执行：补跑前 `git status --short` 为空、HEAD＝`1770fe8`。
- 执行口径：工作树 `C:\1\tmp\magic-spire-wt-fact-on-norms`，枝 `fact-lookup-on-norms`；`GODOT_BIN` 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；串行单引擎（跑前、每轮之间、全部结束后 `Get-Process Godot*` 为空）；三条命令经 `pwsh -NoProfile -File`（7.6.6）执行。
- 补跑逐条：
  - ①`tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 900` → 运行 `20261006T142252156-47272`：`DOCS RESULT: PASS`（43 规则文档／2096 引用／允许清单 3）＋`RULE SCOPE: architecture`（`CROSS_AREAS` 未展开）＋`SUITE RESULT: architecture PASS`＋`PASS: 120703 assertions`，`CHECK rules: 259.71s`，exit 0；`summary.json` `status=passed`、`before==after=6D5D47ED…`、`rules.failed=[]`／`unrun=[]`／`retry=[]`／`complete=true`、`docs.status=passed`。
  - ②`tools/check.ps1 -Suite recipe -TimeoutSeconds 1800` → 运行 `20261006T142727464-45800`：`RUN IDENTITY`＝`head=1770fe8dabb6e95a680736dd7b17c34a2d40fcbd`、`started=2026-10-07T01:27:35+11:00`、`dirty=0`，所载文件哈希 `spire-godot/ui/card_face.gd` `9FB2161DF2B3675EF6933B10C7537F33357D214EC9A1879C607FCD45B232CFBB`／`spire-godot/tests/recipe_driver.gd` `5B2E53AA17E5FF67EF4F89805AFA0D1FB340AA48801C4499E96114DDD1BB3D83`／`spire-godot/tests/ui_smoke.gd` `40C503951394ACC2318B056328A82DF3DB5C6888D394C2CC59AA903C65A7EA64`／`spire-godot/tests/normal_play_cases.gd` `0F0B5E50D556B5E8A45813686825F2B2885F29D2711B1A3AAD45345B477F2AB3`／`spire-godot/tests/game_fixture.gd` `CF37327284D1087E2888A0534AEA8D8C7E787E249284ED537868724C717FB0E6`；`RECIPE seed=7 commits=60 steps=60 stop=cap`、`UI PASS: 65 assertions`、`CHECK recipe: 47.78s, exit=0`，exit 0；`summary.json` `status=passed`、同指纹、`recipe.passed=["recipe"]`／`stop=cap`／`exit=0`、`docs.status=passed`。
  - ③`tools/check-docs.ps1` 单跑 → `DOCS PASS: 43 rule-class document(s), 2096 reference(s) checked, allowlist 3 entrie(s)`，exit 0（与①②内联阶段一致）。
- 判读（全部满足）：退出码 0×3；`SUITE RESULT: architecture PASS`＋recipe 收尾行 `stop=cap`＋`UI PASS: 65 assertions`；两轮 `summary.json` `status=passed` 且 `before==after=6D5D47ED…`（指纹＝同一次运行内的护栏）；**身份由 `head=1770fe8…`＋`dirty=0`＋所载文件哈希给出**；两轮全部日志无 `SOURCE CHANGED`、无 `Failed to read the root certificate store.`。**本轮无红项、无既有语义偏差**。
- 产物：`spire-godot/build/checks/20261006T142252156-47272/`、`spire-godot/build/checks/20261006T142727464-45800/`（本工作树 `build/`，gitignored、不入库）。跑完 `git status --short` 为空：未发生 `.import` 行尾改写（工作树已预导入），无需还原。
- 四态：**已测**＝上列三条命令（D 批被作废的两轮已由同命令、同源码面在提交后取代）；**未跑**＝`-Suite all -UI -UISuite all`（H 批范围）、`-Exhaustive`、`-VerifyRunner`、全部 UI 窗口分类（本批未改 `ui/`）、`tools/check-mutation.ps1`（本批不改源码与判据；D 批 8 条突变证据按原样保留在本文件 D 批条目，本批不复跑）、其余遗留项同 D 批（`tools/check-content.ps1` 未改 `content/packs/`、安卓真机、打包与发布）；**被跳过**＝无；**假设**＝无。
- 本批只提交本地 `.git`（操作卡条文＋本记录）；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-07｜事实表「面 / 点」收口 E 批（K4 需求机制＋K7 提交后两标量＋两字段面同批重冻）：实现提交 `7b6f594`＋本补证提交闭合门禁证据

- 域：`spire-godot/core/game.gd::get_view`／`fact_demand_groups`／`_join_fact_units`／`_fact_rows_in_scope`／`dispatch` 成功返回；`spire-godot/core/command_registry.gd::VIEW_FACT_GROUPS`／`fact_groups`／`fact_scope`／`fact_units_in_scope`；`spire-godot/core/game_view.gd::build`／`display_fact_scope`；`spire-godot/core/pressure.gd::overloaded`；测试 `spire-godot/tests/architecture_cases.gd`（六条新判据）／`spire-godot/tests/mutations.json`（六条新条目）／`spire-godot/tests/frozen-baselines.json`（新）；文档 `docs/spec/response-pipeline.md`／`docs/spec/fact-table-dependencies.md`。输入域＝`r1_cells()`（26 cell × 6 画像）＋真实输入配方（seed=7／cap=60／style=trade）＋接管夹具。契约＝`C:/1/tmp/view-projection-plan/acceptance.md` §1 C-E-1…C-E-7 与 §4 E 命令清单。**本补证提交不改任何产品代码／测试／内容包，只追加本记录**；实现本体＝`7b6f594`（上一实现会话在收尾阶段被外部额度 429 打断：报告与四项门禁证据缺位，由本会话闭合）。
- 范围与两标量字面顺序：`dispatch` 成功结果键面（含顺序）== `tests/architecture_cases.gd::E_SUBMIT_KEYS` 字面表 `["ok","version","resource_feedback","card_feedback","music_feedback","checkpoint","spell_failed","fact","phase","overloaded"]`——`"phase"`／`"overloaded"` 追加在成功结果**末尾**（`core/game.gd` 内字面 `…"fact":chosen,"phase":state.phase,"overloaded":Pressure.overloaded(self)`），取值只来自提交后 `state.phase` 与 `core/pressure.gd::overloaded`（与 `core/game_view.gd::build` 的 `phase`／`pressure.overloaded` 同源同值；不由 `payload.kind` 或裸 `state.overloaded` 反推）；失败结果键面 `{ok,error,fact}` 一字不动（`S5_REJECT_KEYS` 断言仍绿）。`get_view(demand := [])` 缺省与显式全组是同一语义、同一条路径；需求闭包唯一实现＝`core/game.gd::fact_demand_groups`（需求＋投影承接组下限 `core/command_registry.gd::VIEW_FACT_GROUPS`＋接管／`card_chain`／`pending_retain` 入口守卫）；行过滤唯一丢弃点＝`core/game.gd::_fact_rows_in_scope`，`display_facts` 恒为全组行的纯子序列。
- 两字段面 × 26 cell 同批重冻（C-E-7）：**前值冻结**＝`tests/frozen-baselines.json::baseline_pre_cells`（26 cell 的 `facts_text`／`facts_verdicts`／`record`／`view`／`view_display_facts` 五字段摘要，锚定提交 `448ba11`）；**逐 cell 声明差异**＝`tests/architecture_cases.gd::E_DECLARED_DIFF` 恰 26 条，每 cell 只声明 `record` 一个字段，原因只有一类＝`E_SUBMIT_KEYS_REASON`（已声明的新增键 phase／overloaded ⇒ `submit_keys` 变更 ⇒ 派生 `<record>` 变更）；实测绿行 `E BASELINE DIFF declared=26 moved=26`——26 cell 的 `record` 摘要逐 cell 移动，其余四字段（`facts_text`／`facts_verdicts`／`view`／`view_display_facts`）逐 cell 逐字节不动，差异只落在已声明的 `submit_keys` 与派生 `<record>` 两面；键面摘要两态：`S5 KEY FACE SELF PROOF before=93a45a7bba1ccfdae5f52a2e82831d5e after=5e6001580b5d714c2a081120d4019532`（旧面＝`S5_SUBMIT_KEYS_AFTER_DIGEST` 冻结值，新面＝`E_SUBMIT_KEYS` 的摘要）。**自证**＝前值可由后值按声明反推：把 post 记录的 `submit_keys` 行换回旧键面摘要重算，逐 cell 等于冻结前值；判据 `tests/architecture_cases.gd::baseline_diff_is_declared` 双向断言（移动 ⊆ 声明且声明 ⊆ 移动；漏进 `view`／`facts_text`／`facts_verdicts`／`view_display_facts` 任一即红）。
- `tests/frozen-baselines.json` 外部锚定落点（A 批审查缺口 3／4 闭合）：`baseline_pre_digests`（六常量 `R5_BASELINE`／`R3_VIEW_MASK`／`R5_VIEW_MASK`／`R5_RECORD_MASK`／`R5_RECORD_ADDED`／`R5_RECOMPUTED` 的动工前摘要）锚定提交 `7fcc817`＋`spire-godot/tests/architecture_cases.gd` sha256 `9F837193BEA2C8E7…`；`known_gaps_frozen`（54 条冻结缺口清单）锚定同提交＋`spire-godot/tests/mutations.json` sha256 `6303C906B8E686F5…`；`baseline_pre_cells` 锚定提交 `448ba11`＋同测试文件 sha256 `F4A76B18C1D43969…`。前值与被校验常量不再同文件，「同批改常量＋同步改前值」的白名单化路径被切断。
- 「默认全组、不接线」证据：`ui/main.gd` 四个 `get_view` 调用点（`_resume_snapshot`／`render`／`_submit`／`restart`，既有四点白名单）全部仍为无参调用（缺省＝全组），UI 行为与接线前相同；UI 行为不变由同字节 UI 轮证明（下③）。
- 门禁（全部在已提交的干净树上取：HEAD＝`7b6f594`、`git status --short` 为空（dirty=0），每轮前重验；`GODOT_BIN` 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；串行单引擎，跑前与每轮之间 `Get-Process Godot*` 为空；命令经 `pwsh -NoProfile` 执行；判读＝退出码＋`SUITE RESULT: … PASS`＋完成标记＋`summary.json` `status=passed` 且 `before==after`＋无 `SOURCE CHANGED`＋无证书错误）：
  - ①`tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 900` → 运行号 `20261007T061729431-20224`：`DOCS RESULT: PASS`（43 规则文档／2187 引用／允许清单 3）＋`RULE SCOPE: architecture`＋`SUITE RESULT: architecture PASS`＋`PASS: 120734 assertions`，`CHECK rules: 401.85s`，exit 0；`summary.json` `status=passed`、`impact=true`（E 批上一轮缺 `-Impact` 的口径缺口由此闭合）、`before==after=8C4E88AD6AE8821B…`、`rules.failed=[]`／`unrun=[]`／`retry=[]`／`complete=true`。本批新判据绿行：`E DEFAULT PROJECTION cells=26`、`E LAZY PROFILES compared=440 commits=60 coverage={ "hand": 72, "items": 1, "bodies": 1, "route": 50, "reward": 4, "texts": 84 }`（phases 8 相位）、`E FACT GROUPS declared=26 states=89`、`E SUBMIT SCALARS submits=4`、`E BASELINE DIFF declared=26 moved=26`。
  - ②`tools/check.ps1 -Suite recipe -TimeoutSeconds 1800` → 运行号 `20261007T062511167-15156`：`RUN IDENTITY` 全文＝`head=7b6f594a655f896b1680efd66234c9473f5e6811`／`started=2026-10-07T17:25:20+11:00`／`dirty=0`，所载文件哈希五条：`spire-godot/ui/card_face.gd 9FB2161DF2B3675E…`／`spire-godot/tests/recipe_driver.gd 5B2E53AA17E5FF67…`／`spire-godot/tests/ui_smoke.gd 40C503951394ACC2…`／`spire-godot/tests/normal_play_cases.gd 0F0B5E50D556B5E8…`／`spire-godot/tests/game_fixture.gd A265139887B0B0AD…`；`RECIPE seed=7 commits=60 steps=60 stop=cap`、`UI PASS: 65 assertions`、`CHECK recipe: 51.66s, exit=0`，exit 0。本片唯一带 `RUN IDENTITY` 的一轮：身份由 `head=7b6f594…`＋`dirty=0`＋所载文件哈希给出。
  - ③UI（已过不重跑，按派工授权引用既有运行）：`tools/check.ps1 -UI -UISuite display,interface,body_layout,targeting` → 运行号 `20261006T152249208-48920`（`7b6f594` 提交后、同字节、`before==after=8C4E88AD…`）：`SUITE RESULT: display PASS`／`body_layout PASS`／`targeting PASS`／`interface PASS`、`UI PASS: 1967 assertions`、`summary.json` `status=passed`。
  - ④突变 ×4（`tools/check-mutation.ps1 -Check <名>`；四个名字先 `grep` 核对在 `tests/mutations.json`；判读＝每条 `RED` 且 `restored=True`、`MUTATION SUMMARY` 全绿、无 `MUTATION RESIDUE`、每轮跑后 `git status --short` 仍为空）：`default_projection_is_unchanged` → 运行号 `20261007T062634046-45892`（375.3s；日志 `spire-godot/build/mutations/20261007T062634046-45892/default_projection_is_unchanged.log`；突变后 `FAIL: 329/112610 assertions`）、`lazy_projection_invariant` → `20261007T063259946-21692`（395.4s；日志同目录 `lazy_projection_invariant.log`；红 `3/120734`）、`submit_result_scalars_are_pinned` → `20261007T063946569-26452`（396.6s；日志同目录 `submit_result_scalars_are_pinned.log`；红 `3/120734`）、`baseline_diff_is_declared` → `20261007T064632755-17076`（390.7s；日志同目录 `baseline_diff_is_declared.log`；红 `2/120734`）；四条全部 `exit-red=True restored=True`、逐字节还原。**口径（协调者裁定 R-T1）**：`check-mutation.ps1` 不写 `RUN IDENTITY`，其 `worktree unchanged=True` 只表示「跑前跑后未变」、**不代表跑前干净** ⇒ 本条目对四条突变轮**只列运行号与日志路径**，不写「突变轮已绑到提交字节」；身份回填归 F 批。
  - ⑤`tools/check-docs.ps1`（本记录条目落盘并提交前）→ `DOCS PASS: 43 rule-class document(s), 2187 reference(s) checked, allowlist 3 entrie(s)`，exit 0（该脚本无落盘产物；与①②内联阶段一致）。本记录提交后再跑一次确认仍 `DOCS PASS`。
- 如实写明（历史不一致，不改写历史）：`7b6f594` 提交信息末句「Gate evidence for the committed bytes is recorded in docs/record/verification.md」**在当时不成立**——该提交未触碰 `docs/record/verification.md`（记录文件最后一次改动是 D 批提交 `448ba11`），E 批门禁证据由本补证提交闭合。中间红轮留痕：`spire-godot/build/checks/20261006T150826973-2012`（提交前：architecture `FAIL: 2/120734 assertions; 2 engine errors`，红项＝`pipeline_lookup_inspect` 对 `command_facts` 体的文本判据与 `slice_dependency_directions` 的 core/data→ui 依赖方向，各带一条 push_error），两处在提交前已修（最终字节轮 `20261007T061729431-20224` 零 ERROR、零红断言），红轮只作过程记录、不作通过证据。
- 清点出入（如实）：`7b6f594` 提交信息称 "six mutation entries"——文件实况六条新条目（§4 E 命令清单的四个名字＋`fact_groups_are_total`＋`whole_table_branches_force_full_demand`），与文件一致；后两条本批**未跑**突变（未列入 §4 E 命令清单），判据本身已由①的架构轮绿覆盖。提交信息称 "six new checks (C-E-1..C-E-7)"——实况六个判据函数覆盖七个判据编号（C-E-2／C-E-3 合于 `lazy_projection_invariant` 的行面／值面两部分）。
- 产物：`spire-godot/build/checks/20261007T061729431-20224/`、`spire-godot/build/checks/20261007T062511167-15156/`、`spire-godot/build/mutations/20261007T062634046-45892/`、`spire-godot/build/mutations/20261007T063259946-21692/`、`spire-godot/build/mutations/20261007T063946569-26452/`、`spire-godot/build/mutations/20261007T064632755-17076/`（本工作树 `build/`，gitignored、不入库）。跑完 `git status --short` 为空：无 `.import` 行尾改写、无突变残留、无调试残留。
- 四态：**已测**＝①architecture `-Impact`（新运行号）、②recipe（含 `RUN IDENTITY` 全文）、③UI 四类（引用既有运行号 `20261006T152249208-48920`，不重跑）、④四条突变（运行号＋日志路径）、⑤`tools/check-docs.ps1` 两次（本记录落盘前与提交后）；**未跑**＝`-Suite all -UI -UISuite all`（H 批范围）、`-Exhaustive`、`-VerifyRunner`、其余 UI 窗口分类（`home`／`normal_play`／`route`／`services`／`prison`／`items`／`hero_art`／`equipment_art` 等，归 F／H 批）、E 批六条新突变条目中未列入 §4 E 命令清单的两条（`fact_groups_are_total`／`whole_table_branches_force_full_demand`）、其余既有突变条目、`tools/check-content.ps1`（未改 `content/packs/`）、安卓真机、打包与发布；**被跳过**＝无（UI 四类属「已过不重跑、按派工授权引用既有运行」，不记跳过）；**假设**＝无。
- 本补证提交只含 `docs/record/verification.md` 一个文件；只提交本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-07｜事实表「面 / 点」收口 E 批记录追加（突变补证与审查处置）

- 域：`docs/record/verification.md` 追加节（接上一 E 批节末尾）；证据＝两条突变运行日志（`spire-godot/build/mutations/<运行号>/`）＋提交时间与运行号生成器两处核实＋两份独立审查报告（全文在计划区 `C:/1/tmp/view-projection-plan/`）。本追加提交不改任何产品代码、测试与内容包，只追加本文件；上一节清点句「`fact_groups_are_total`／`whole_table_branches_force_full_demand` 两条本批未跑突变」由本节闭合。
- 突变补证 ×2（`tools/check-mutation.ps1 -Check <名>`；两名字先核对在 `tests/mutations.json`；判读＝目标判据 RED、`restored=True`、逐字节还原、每轮跑后 `git status --short` 为空）：
  - `fact_groups_are_total` → 运行号 `20261007T071335106-48284`：RED（目标判据自身红：突变后 registry 出现 `manual_probe`，日志 `K4 fact_groups_are_total` 报错把 `manual_probe` 列入声明全集、`FACT UNIT GROUPS manual=["manual_probe"] … unobserved=["manual_probe"]`；`FAIL: 6/120734 assertions`）、restored=True、410.3s、退出码 0；日志 `spire-godot/build/mutations/20261007T071335106-48284/fact_groups_are_total.log`。
  - `whole_table_branches_force_full_demand` → 运行号 `20261007T072026463-31400`：RED（恰两处：`flag:card_chain`／`flag:pending_retain`，各报 `a narrow demand changed a whole-table branch`；`FAIL: 1/120734 assertions`）、restored=True、401.5s、退出码 0；日志 `spire-godot/build/mutations/20261007T072026463-31400/whole_table_branches_force_full_demand.log`。
  - 两轮均在已提交的干净树上跑：HEAD＝`c1084c1`、`dirty=0`；该提交的 `spire-godot/**` 字节与 `7b6f594` 相同（`c1084c1` 只动 `docs/record`）。**口径（R-T1 句照抄）**：`check-mutation.ps1` 不写 `RUN IDENTITY`，其 `worktree unchanged=True` 只表示「跑前跑后未变」、不代表跑前干净 ⇒ 本节对突变轮只列运行号与日志路径，不写「已绑到提交字节」；身份回填归 T 批（协调者裁定 R-T6 已把该项从 F 批移到 T 批）。
- [存疑] 时区核实（审查者曾疑「UI 轮 `20261006T152249208-48920` 早于提交」；逐字给命令与结论）：`git show -s --format=%cI 7b6f594` ＝ `2026-10-07T02:17:55+11:00`（即 UTC 15:17:55）；该运行号由 `[DateTime]::UtcNow` 生成（`spire-godot/tools/check.ps1` 的 `$checkRunId`）＝UTC 15:22:49 ⇒ 运行**晚于提交 5 分钟**，上一节③「提交后」措辞成立，该存疑闭合。
- 两份独立审查的处置登记（一句话级；报告全文在计划区，不复制进仓库记录）：muse（`C:/1/tmp/view-projection-plan/audit-batchE-muse.md`）VERDICT FAIL，唯一 [应修]＝两条新判据未实测，已由上文两条补证运行闭合；两条 [存疑]（时区项见上句；build 产物 gitignored 只读不可复验属固有限制，不改）。ZCode 子代理（报告在会话记录）VERDICT PASS，其 [存疑]（两条突变运行未登记）由本节闭合。
- 两份审查共同指出的残留（不进本节判读，只登记去向）：①`command_facts` 的 `scope.size()==fact_groups().size()` size 启发式须在 F 批接线前改为内容等值（协调者裁定 R-T8）；②需求路径画像未盖 `relic_bundle`／`domain_blocked` 前缀态，F 批扩面；③锚自检判据落 T 批（R-T5）。
- 四态（本追加节）：**已测**＝两条突变（运行号＋日志路径，restored=True、退出码 0）＋`tools/check-docs.ps1`（本节提交后一次，控制台 `DOCS PASS`）；**未跑**＝删去「`fact_groups_are_total`／`whole_table_branches_force_full_demand` 两条突变」后其余不变——`-Suite all -UI -UISuite all`（H 批范围）、`-Exhaustive`、`-VerifyRunner`、其余 UI 窗口分类（归 F／H 批）、其余既有突变条目、`tools/check-content.ps1`（未改 `content/packs/`）、安卓真机、打包与发布；**被跳过**＝无；**假设**＝无。
- 本追加提交只含 `docs/record/verification.md` 一个文件；只提交本地 `.git`；未推送、未 tag、未改版本号、未开 PR。

## 2026-10-07｜事实表「面 / 点」收口 T 批（R-T1 修订版＋R-T5，core 零改）：突变轮身份落盘＋锚自检判据＋8 轮身份回填

- 域：`spire-godot/tools/check-mutation.ps1`（每轮 `RUN IDENTITY` 身份块——`head`／`started`／`dirty` 条目数＋run 起点 porcelain 逐行快照，形态同 `tools/check.ps1` 的 recipe 相位——落盘 `build/mutations/<运行号>/identity.txt`；`MUTATION SUMMARY` 的 `worktree unchanged=` 行同时打印前置脏度 `(pre-dirty=N)`；既有退出语义不变）；`skills/repo-ops/SKILL.md`（《工作树并发纪律》节末恰补一句）；`spire-godot/tests/architecture_cases.gd`（新判据 `frozen_anchor_files_match_git`＋两个下划线助手）；`spire-godot/tests/mutations.json`（新条目 1 条，`known_gaps` 不动＝54）。输入域＝`tests/frozen-baselines.json` 的 3 处锚（baseline_pre_digests／known_gaps_frozen／baseline_pre_cells）与既有 8 条突变条目；域外不宣称（产品代码、锚定面与基线常量、根 `AGENTS.md` 零改动）。契约＝plan §3 T 行与 §5.1 T 行、gherkin T-1…T-4、acceptance §1 C-T-1…C-T-5 与 §4 T 命令清单、open-items R-T1（修订版）／R-T5／R-T6。实现提交＝`bc53352`（四文件一次提交，amend 后的最终哈希）。
- 锚自检的重算通道（T-3 实现口径，接口事实）：`OS.execute` 直接捕获 `git show` 的 stdout 会按**系统代码页**解码（本机 GBK，含中文的 blob 被搅碎、字符串哈希必错——探针实测）⇒ 字节通道改为 `OS.execute("cmd",["/c","git","-C",<仓库根>,"show",<提交>:<文件>,">",<临时文件>])`（cmd 重定向字节透明）把 blob 直写 `build/` 下临时文件，再以 `HashingContext` SHA-256 分块重算、即用即删（`build/` 忽略目录，无 git 残留）。git 不可用（execute 退出 -1）／锚对象缺失（git 非零退出，如 `deadbeef` 探针 exit=128）／哈希不符都产生哨兵值进入比对 ⇒ 红（fail-closed）。期望侧只在两处外部：JSON 声明与 git 对象库的历史 blob（E 批审查找漏洞 d 的闭合面）；落点名 `tests/architecture_cases.gd::frozen_anchor_files_match_git`＋助手 `_anchor_show_sha256`／`_sha256_file`。
- 中间过程（如实，不作证据）：初始提交 `f0a6330` 跑过一轮 architecture `-Impact`（运行 `20261007T111143208-56864`，PASS）与一次锚突变尝试（运行 `20261007T111629244-47832`：`List[string].AddRange` 收 `Object[]` 在 pwsh 7 抛转换异常、身份落盘前中止，未发生任何突变）。修一行（`$statusEntries` 显式转 `[string[]]`）后 `--amend` 进同一提交 ⇒ **`bc53352`**（与 `f0a6330` 的字节差＝`check-mutation.ps1` 一行）；amend 后旧哈希不复存在，上两轮按「head 无对应提交」作废，§4 T 的全部证据在 `bc53352` 干净树上重取（下）。
- 门禁（acceptance §4 T 全部 11 条命令；全部在已提交的干净树上取：HEAD＝`bc53352`、每轮之间 `git status --short` 为空；`GODOT_BIN` 每 shell 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；串行单引擎，跑前与每轮之间 `Get-Process Godot*` 为空；命令经 `pwsh -NoProfile` 执行；突变轮判读＝RED＋restored=True＋无 `MUTATION RESIDUE`＋该轮 `identity.txt` 存在且 `head=bc53352…`、`dirty=0`、摘要行 `worktree unchanged=True (pre-dirty=0)`）：
  - ①`tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 900` → 运行号 `20261007T111736406-11580`：`DOCS RESULT: PASS`（43 规则文档／2187 引用／允许清单 3）＋`RULE SCOPE: architecture`（`CROSS_AREAS` 未展开）＋`SUITE RESULT: architecture PASS`＋`PASS: 120736 assertions`（＝E 批 120734＋锚自检 2 条），`CHECK rules: 255.78s`，exit 0；`summary.json` `status=passed`、`before==after=A1C655164EC8CB64…`、`impact=true`、`rules.failed=[]`／`unrun=[]`。锚自检绿行＝`FROZEN ANCHORS: 3 anchor(s) recomputed from git blobs, 3 matched`（3 处锚重算与所载 sha256 逐字节相等，大小写不敏感）；`MUTATION GAP FREEZE frozen=54 current=54 shrunk=0`。
  - ②锚突变轮 `tools/check-mutation.ps1 -Check frozen_anchor_files_match_git` → 运行号 `20261007T112227770-53176`：RED＋restored=True（256.5s）；红行恰落在被改锚——`FB frozen_anchor_files_match_git: … ["baseline_pre_digests (7fcc817:spire-godot/tests/architecture_cases.gd): recomputed=9F83…F47760 declared=9F83…F47761"]`；`MUTATION SUMMARY: 1/1 … worktree unchanged=True (pre-dirty=0)`；无 `MUTATION RESIDUE`。该轮 `identity.txt` 实例全文：`RUN IDENTITY`／`head=bc533524dddb34efdc67c42cddb06434e649431c`／`started=2026-10-07T22:22:28+11:00`／`dirty=0`（本轮 dirty=0 ⇒ porcelain 快照为空）。
  - ③…⑩（D 两条＋E 六条身份回填，共 8 轮，逐轮 RED＋restored=True＋无残留＋`identity.txt` 齐＋`pre-dirty=0`）：
    - `fact_table_reuse_within_batch` → `20261007T112707807-16868`（248.2s）：红行 `requests=3/4 builds=3/4 … after the batch ended the next read must rebuild the table (builds=5)`
    - `fact_table_cache_lifetime_is_pinned` → `20261007T113127041-55380`（257.1s）：红行 `the batch entry never stores on self … ["set_meta("]`
    - `default_projection_is_unchanged` → `20261007T113558436-56812`（233.0s）：红行 `default != explicit full group`（逐 cell）
    - `lazy_projection_invariant` → `20261007T114000731-54048`（253.6s）：红行 `display_facts is not the declared subsequence of the full rows`
    - `fact_groups_are_total` → `20261007T114422450-8340`（255.2s）：红行声明全集混入 `manual_probe`
    - `whole_table_branches_force_full_demand` → `20261007T114846637-33264`（256.7s）：红行 `flag:card_chain`／`flag:pending_retain: a narrow demand changed a whole-table branch`
    - `submit_result_scalars_are_pinned` → `20261007T115312988-40888`（331.2s）：红行 `the overloaded scalar keeps the combat-phase guard (a bare state flag differs here)`
    - `baseline_diff_is_declared` → `20261007T115853308-49736`（404.9s）：红行 `every moved cell field is declared … ["battle:0.record"]`
  - ⑪`tools/check-docs.ps1` 单跑 → `DOCS PASS: 43 rule-class document(s), 2187 reference(s) checked, allowlist 3 entrie(s)`，exit 0（与①内联阶段一致；本记录提交后再跑一次确认）。
- identity.txt 的可解析性（C-T-1 证据面）：上述 9 轮的 `identity.txt` 全部落盘于 `build/mutations/<运行号>/identity.txt`，块形同 recipe 相位（`RUN IDENTITY`／`head=` 全 40 位／`started=`／`dirty=`＋run 起点 porcelain 逐行快照）；`MUTATION SUMMARY` 行同时打印 `(pre-dirty=0)`——「未变」与「干净」自此分开判读（身份只由 head＋dirty＋所载哈希给）。
- 旧轮作废（「无提交对应」；只追加，不改旧条目）：以下 8 条突变轮全部先于本批身份机制（无 identity 行、`worktree unchanged` 无前置脏度），按 R-T1 修订版口径不再作为其声称判据的提交字节绑定证据，由上文③…⑩回填轮取代：E 批四条实测轮 `20261007T062634046-45892`（default_projection_is_unchanged）／`20261007T063259946-21692`（lazy_projection_invariant）／`20261007T063946569-26452`（submit_result_scalars_are_pinned）／`20261007T064632755-17076`（baseline_diff_is_declared）；R-T3 两条补证轮 `20261007T071335106-48284`（fact_groups_are_total）／`20261007T072026463-31400`（whole_table_branches_force_full_demand）；D 批两条旧轮 `20261006T134152767-31672`（fact_table_reuse_within_batch）／`20261006T134945705-39348`（fact_table_cache_lifetime_is_pinned）。各轮 RED／逐字节还原的事实本身不变，作废的只是「绑定到提交」的资格。
- 面守恒（C-T-5）：`known_gaps` 仍 54（`frozen=54 current=54 shrunk=0`，新判据未进缺口）；`AGENTS.md` 不在 T 的 diff 内（`git diff 7e6722a..bc53352 --stat`＝恰四个文件）；`R5_BASELINE`／四个 mask 常量／`frozen-baselines.json` 的三处锚（commit／file／sha256）一字未改（①的 `baseline_constants_are_unchanged`／`behavior_baseline_equivalence`／G6 26 cell 全绿＋锚自检 3/3）。
- 操作卡条文（C-T-2）：`skills/repo-ops/SKILL.md`《工作树并发纪律》节末恰补一句「突变轮的绑定形式同 recipe——身份行必须落盘；`head` 未记或 `dirty≠0` 时该轮不作证据。」与该节既有三条（证据绑提交字节／`RUN IDENTITY` 判读／指纹非身份）不重复，是收紧证据口径、不是新的豁免面；根 `AGENTS.md` 零改动。
- 四态：**已测**＝①architecture `-Impact`（含锚自检绿与 G6 零移动）、②锚突变轮、③…⑩回填 8 轮、⑪`check-docs` 单跑；**未跑**＝`-Suite recipe` 与全部 UI 窗口分类（T 不改产品代码：recipe 身份块所载 5 个文件与全部 UI 路径都不在 T 的改动面内，T 的提交字节绑定由突变轮 `RUN IDENTITY` 直接给出、architecture 轮与之同工作树同指纹构成同一提交的推断链——acceptance §4 T 已载此结论与理由）、`-Suite all -UI -UISuite all`（H 批范围）、`-Exhaustive`、`-VerifyRunner`、其余 30 条既有突变条目（`-All` 归 G／H）、`tools/check-content.ps1`（未改 `content/packs/`）、安卓真机、打包与发布；**被跳过**＝无；**假设**＝无。
- 产物：`spire-godot/build/checks/20261007T111736406-11580/` 与 9 个 `spire-godot/build/mutations/<运行号>/`（各含 `identity.txt`＋`<判据名>.log`；本工作树 `build/`，gitignored、不入库）。每轮之间与全部结束后 `git status --short` 为空。
- 本批实现提交＝`bc53352`（恰四文件：check-mutation.ps1／repo-ops SKILL.md／architecture_cases.gd／mutations.json）；本节只追加 `docs/record/verification.md` 一个文件、单独提交；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-11｜事实表「面 / 点」收口 F 批收口（修复批＋实现字节入册）：§4 F 正式门禁、九条突变正式取证、无引擎负例

- 域：`spire-godot/ui/target_queries.gd::debug_exchange_read_observer`／`_debug_observe_read`（R-FR1 唯一观察接缝，debug-only 两叶通知）；`spire-godot/tests/recipe_driver.gd::_run_recipe`（R-FR2 记录生命周期挂载）／`spire-godot/tests/ui_smoke.gd::module_checks`／`finish_checks`（兜底清理）；`spire-godot/core/game.gd::command_facts`（R-T8 槽位准入＝内容等值）；`spire-godot/tools/check-mutation.ps1`（R-FR4 execution=rules|ui|recipe 委派 check.ps1 唯一阶段路由）；`skills/spire-architecture/SKILL.md`（只读投影与提交边界索引）。本节为收口取证与登记；实现本体＝修复批两提交 `d42577b`（G1 归属单一真源／G4 计数域收窄）＋`65e1c08`（G2 需求声明分表／G3 突变条目改名 `section_read_sets_are_pinned` 并撞键取代 WIP 旧条目／G7 core 节名泄漏扫描扩 11 节／G8 `F_PREFIX_PROFILES` 唯一驱动），实现字节入册提交＝`346198b`（一次收口提交，6 文件＝上述域文件；派工清单点名 `tests/target_queries.gd`，实际落点 `spire-godot/ui/target_queries.gd`，basename 一致、无预期外文件）。合同＝`C:/1/tmp/view-projection-plan/acceptance.md` §4 F 与 §5.5（顺序偏差放行条件＝本节）、design §K5、open-items R-FR1…R-FR4b／R-T8。
- 执行口径：工作树 `C:\1\tmp\magic-spire-wt-fact-on-norms`，枝 `fact-lookup-on-norms`，HEAD＝`346198bfc3b72d6305bb13ae8ce6d271b553467a`（提交后 `git status --short` 为空、`git diff --check` 净，全部各轮在该已提交干净树上串行执行）；`GODOT_BIN` 每 shell 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；pwsh 7.6.6；单引擎串行（每轮跑前跑后 `Get-Process Godot*` 为 0）；命令经 `pwsh -NoProfile -File` 脚本（工作树 `tmp/`，UTF-8 无 BOM）。判读通用＝退出码＋完成标记＋`summary.json` `status`／`before==after`＋无 `SOURCE CHANGED`＋无证书错误；突变轮另＝目标判据具名 ERROR＋目标阶段完成标记＋`restored=True`＋无 `MUTATION RESIDUE`＋外层 identity 开局 `dirty=0` 且轮后 `git status --short` 为空。
- 门禁（§4 F 前三条＋check-docs 单跑）：
  - ①`tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 900` → 运行 `20261011T052943671-209468`：`DOCS RESULT: PASS`（43 规则文档／2369 引用／允许清单 3）＋`RULE SCOPE: architecture`（`-Impact` 未展开）＋`SUITE RESULT: architecture PASS`＋`PASS: 120803 assertions`，`CHECK rules: 224.88s`，exit 0；`summary.json` `status=passed`、`before==after`、`impact=true`、`rules.complete=true`。本批判据绿行：`F1 DEMAND TABLES sections=15 groups=25 declared=9 scope=24 fallback_phases=17`（C-F-1 修复批口径：声明⊆读集、U∪VIEW⊊全组、冻结差集非空）、`F2 SECTION READ SETS sections=15 groups=25`（C-F-2）、`F8 SLOT ADMISSION cells=2 crafted_size=26 full_size=26`（C-F-8）、`E LAZY PROFILES compared=450 commits=60 prefix=2`（C-F-9，前缀夹具经 `F_PREFIX_PROFILES` 声明表驱动）、`E FACT GROUPS declared=26 states=89`、`E BASELINE DIFF declared=26 moved=26`（C-F-7 常驻：E 历史域声明照旧）、`BASELINE CONSTANTS FROZEN pairs=5`（C-F-6 落地后：`R3_VIEW_MASK` 转为「PRE=`["display_facts"]`＋新增 `["display_fact_scope"]`」单项增量自证、有效直接比对对数 5，C-F-6 判据随轮绿）、`E DEFAULT PROJECTION cells=26`、`S5 KEY FACE SELF PROOF` 前后摘要与 E 批冻结值一致、`E SUBMIT SCALARS submits=4`、`FROZEN ANCHORS: 3 anchor(s) recomputed from git blobs, 3 matched`、`MUTATION GAP FREEZE frozen=54 current=53 shrunk=1`（清单只缩短）。
  - ②`tools/check.ps1 -UIOnly -UISuite display,interface,body_layout,targeting,route,services,prison,items,home,normal_play -KeepGoing -TimeoutSeconds 3600` → 运行 `20261011T053411259-136880`：十分类逐行 `SUITE RESULT: <名> PASS`（display／items／home／route／services／body_layout／targeting／interface／normal_play／prison）＋`UI PASS: 4075 assertions`，`CHECK ui: 616.17s`，exit 0；`summary.json` `status=passed`、`before==after`、`ui.complete=true`、`ui.failed=[]`。display 轮内记录器证据：15×`F3 OBSERVER RESTORED true`、`F3 ACTUAL READS` 覆盖 local（relics/actions/resources/posture/drawers/body_details/scene_instances/hand/body_bar）＋interaction（target_drag）＋page 三域、无 unknown 归属。
  - ③`tools/check.ps1 -Suite recipe -TimeoutSeconds 1800` → 运行 `20261011T054510203-181976`：`RUN IDENTITY head=346198bfc3b72d6305bb13ae8ce6d271b553467a dirty=0`；`RECIPE DRIVER engine=4.7.2-stable (official) seed=7 cap=60 style=trade window=1600x900`；收尾 `RECIPE seed=7 commits=60 steps=60 stop=cap`＋`UI PASS: 194 assertions`（＝E 批 65＋记录器 129 条实读判据）＋`CHECK recipe: 49.43s, exit=0`，exit 0；`summary.json` `status=passed`、`before==after`、`recipe.seed=7 commits=60 stop=cap exit=0`。`check-recipe.log`：`F3 OBSERVER RESTORED true`；`F3 ACTUAL READS events=2747 nonempty=1679 versions=61 roles={key:1362, rebuild:1385} coverage={local:{relics,actions,resources,posture,drawers,body_details,scene_instances}, page:{reward,route,event,prison}, interaction:{target_drag}}`——真实 60 提交相位上记录器全量核过、空返回组与交互域独立计数，未由声明重放替代。
  - ④`tools/check-docs.ps1` 单跑 → `DOCS PASS: 43 rule-class document(s), 2369 reference(s) checked, allowlist 3 entrie(s)`，exit 0（与①内联阶段一致）。
- 突变正式取证（§4 F 九条，逐条 `tools/check-mutation.ps1 -Check <名> -TimeoutSeconds 1800`；总 stdout/stderr 归档工作树 `tmp/F-hardener-mutation-<名>.log`，紧随命令的 `$LASTEXITCODE` 逐条列明；九条全部 RED＋`restored=True`＋逐字节还原＋`worktree unchanged=True (pre-dirty=0)`＋轮后 `git status --short` 为空＋无 `MUTATION RESIDUE`＋目标日志无 `SOURCE CHANGED`／无 `ObjectDB instances were leaked`／无 `resources still in use`（修复批判读补充 G5/G6 的两条 fail-closed 分栏在本批未触发，无 FAILED 轮）＋外层 exit 0）：
  - 1 `present_demand_recorder`（execution=recipe，真 60 提交相位）→ 突变轮 `20261011T054803927-74336`，子 check `20261011T054804504-175620`（execution=recipe；子轮人工突变后 dirty=1 属预期）：sha256 `681F30754A41`，54.5s；目标阶段完成标记 `RECIPE seed=7 commits=60 steps=60 stop=cap`＋`UI FAIL: 72 assertions`＋`F3 OBSERVER RESTORED true`；具名 ERROR＝`F3 present_demand_recorder: actual UI leaf observations are nonempty (disabled notifications are red): events=0 nonempty=0`（关通知→非空观察覆盖红，acceptance C-F-3 敏感性原句）；子 `summary.json` `status=failed`、`before==after`、`recipe.failed=[recipe]`。归档 `tmp/F-hardener-mutation-present_demand_recorder.log`，`$LASTEXITCODE=0`。
  - 2 `section_read_sets_are_pinned`（rules，G3 改名条目）→ `20261011T054928990-148496`，子 `20261011T054929607-172548`：sha256 `4546DB0C6D11`，239.2s；`SUITE RESULT: architecture FAIL`；具名 ERROR 两条（`F2 section_read_sets_are_pinned: extra anchors normalize once, preserve all 35 legacy main entries, …`／`… begin and the dedicated focus_bodies query chain share one independent interaction declaration, …`）；子 `status=failed`、`before==after`、`rules.failed=[architecture]`。归档 `tmp/F-hardener-mutation-section_read_sets_are_pinned.log`，`$LASTEXITCODE=0`。
  - 3 `bound_click_focus_owner`（ui/display）→ `20261011T055423989-30932`，子 `20261011T055424672-80208`：sha256 `4546DB0C6D11`，141.8s；`SUITE RESULT: display FAIL`＋`UI FAIL: 1305 assertions`；具名 ERROR＝`F2 bound_click_focus_owner: the real bound-click prison leaf, even when empty, belongs to the nearest dedicated interaction/target_drag entry, not outer hand`。归档 `tmp/F-hardener-mutation-bound_click_focus_owner.log`，`$LASTEXITCODE=0`。
  - 4 `submit_full_fallback_uses_source`（ui/display）→ `20261011T055702688-199476`，子 `20261011T055703274-198640`：sha256 `AD5240C0E252`，143.3s；`SUITE RESULT: display FAIL`＋`UI FAIL: 1313 assertions`；具名 ERROR＝`F4 submit_full_fallback_uses_source: nonempty dirty reads overload from source, not the previous View`。归档 `tmp/F-hardener-mutation-submit_full_fallback_uses_source.log`，`$LASTEXITCODE=0`。
  - 5 `read_observer_boundaries`（ui/display）→ `20261011T055945497-223872`，子 `20261011T055946079-255392`：sha256 `681F30754A41`，144.1s；`SUITE RESULT: display FAIL`＋`UI FAIL: 1313 assertions`；具名 ERROR＝`F3 read_observer_boundaries: changing isolated event rows/scope cannot change the live projection`。归档 `tmp/F-hardener-mutation-read_observer_boundaries.log`，`$LASTEXITCODE=0`。
  - 6 `fact_groups_are_total`（rules）→ `20261011T060230135-244136`，子 `20261011T060230721-214540`：sha256 `0EB6F5DB0379`，243.6s；`SUITE RESULT: architecture FAIL`；具名 ERROR＝`K4 fact_groups_are_total: the declared universe equals the unit table's group union …`（突变后声明全集混入 `manual_probe`）。归档 `tmp/F-hardener-mutation-fact_groups_are_total.log`，`$LASTEXITCODE=0`。
  - 7 `demand_declarations_are_total`（rules）→ `20261011T060658727-19888`，子 `20261011T060659322-233416`：sha256 `AD5240C0E252`，244.8s；`SUITE RESULT: architecture FAIL`；具名 ERROR 四条（`F1 demand_declarations_are_total: … ["relics declares unread relic_probe"]`／`… ["relics.relic_probe"]`／`… ["relics.relic undeclared without a registered reason"]`／`… frozen non-empty difference {chain, demo_exit} … ["chain", "demo_exit", "relic"]`）。归档 `tmp/F-hardener-mutation-demand_declarations_are_total.log`，`$LASTEXITCODE=0`。
  - 8 `command_facts_full_scope_is_content_equal`（rules，R-T8）→ `20261011T061135165-129612`，子 `20261011T061135753-222464`：sha256 `E6B3FC908384`，233.4s；`SUITE RESULT: architecture FAIL`；具名 ERROR 三条（`F8 … the size heuristic is gone from the slot admission`／`… the slot admission is the content equality against the truth-source full group`／`… ["battle:0 the equal-size non-full demand occupied the batch slot (builds=1)", "battle:0 the same-batch full-group read was polluted by the earlier non-full demand", "battle:12 …"]`——等 size 非全组 demand 在旧 size 启发式下占槽位并污染同批全组读取，R-T8 敏感性原句）。归档 `tmp/F-hardener-mutation-command_facts_full_scope_is_content_equal.log`，`$LASTEXITCODE=0`。
  - 9 `lazy_projection_invariant`（rules，扩面前缀态）→ `20261011T061549387-276876`，子 `20261011T061550091-19524`：sha256 `0EB6F5DB0379`，254.3s；`SUITE RESULT: architecture FAIL`；具名 ERROR 三条（行面纯子序列／`display_fact_scope` 三方互核／LPI 值面，红样例落前缀态画像 `rest:0@relics_open`／`rest:0@body_details`／`rest:12@relics_open.items` 等）。归档 `tmp/F-hardener-mutation-lazy_projection_invariant.log`，`$LASTEXITCODE=0`。
  - 九轮 identity：各轮 `build/mutations/<突变轮运行号>/identity.txt` 落盘，`head=346198bfc3b72d6305bb13ae8ce6d271b553467a`、开局 `dirty=0`；子 check 的 `RUN IDENTITY` 显示 `dirty=1`（人工突变在身，属预期，不作产品通过身份）；外层归档日志同轮保存 `MUTATION EXIT=0`。
- 无引擎负例（R-FR4；可执行产物只在工作树 `tmp/`）：runner sha256＝`7AD26664CF69FD34EBB123A4C3F1D73BA6105A5FE85659BB93131887D7EF7338`（收口提交后的当前字节）；脚本 `tmp/F-runner-selection-negative.ps1`（隔离拷贝 runner 字节＋`find-godot` 替身指向不可启动路径＋最小 mutations 表）。两例：`unknown`（execution=`no_such_execution`）→ 子 runner exit=1、原错误 `Unknown mutation execution: no_such_execution` 命中、非 RED、无引擎启动、无二次异常；`missing`（合法 execution=rules＋不存在 target file）→ exit=1、`target file not found: does-not-exist.gd` 命中、同样 fail-closed。聚合 exit 0，runner sha256 与 `git status --porcelain` 前后不变。逐例日志 `tmp/F-runner-negative-20261011T062044675/unknown.log`／`missing.log`，汇总归档 `tmp/F-hardener-negative.log`。
- 判读（acceptance §4 F）：C-F-1…C-F-9 的绿证据＝①的 architecture 轮（含 `contract_text_is_updated_verbatim`／`baseline_constants_are_unchanged`／`behavior_baseline_equivalence` 随轮绿；`R3_VIEW_MASK` 单项增量按 C-F-6 唯一口径自证；F 增量域相对 `32ca5bb` 零移动由 `E BASELINE DIFF declared=26 moved=26` 常驻声明与 G6 零移动覆盖）＋②的十模块 UI 轮＋③的 recipe 轮（C-F-3 核心证据来自原 60 提交相位，非声明重放、非 UI 十次采样）；敏感性证据＝九条突变轮逐条具名 RED＋逐字节还原。`relics` 节键覆盖 `relic` 组（③的 coverage `relics:{relic:720}`＋② display 各轮 `relics:{relic:N}`）；全屏 page 不迫使局部取全组（page 域独立计数）。**任一「读了但不在投影」＝0**（recipe 与 display 记录器零缺组、零未知版本、零 unknown 归属）。
- 四态：**已测**＝①②③④门禁四轮＋九条突变轮＋无引擎负例两例（运行号、identity、归档路径如上）；**未跑**＝`-Suite all -UI -UISuite all`（H 批范围）、`-Exhaustive`、`-VerifyRunner`、其余既有突变条目（`-All` 归 G/H）、`tools/check-content.ps1`（未改 `content/packs/`）、安卓真机、打包与发布、独立子代理审查（实现完成后按根 `AGENTS.md` 另派，不在本槽位）；**被跳过**＝无；**假设**＝无。修复批过程报告（三轮窄诊断、G1–G8 逐条落点）见工作树 `tmp/F-clean-report.md`／`tmp/F-implfix-report.md`（不入库）。
- 本节只追加 `docs/record/verification.md` 一个文件、单独提交；全部提交仅在本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-11｜事实表「面 / 点」收口 F 批收口（RF-1 加固追加）：十条突变正式取证、无引擎负例、check-docs；套件面由同 head 的 H 轮充当

- 域：`spire-godot/tests/architecture_cases.gd::prison_page_row_order_is_pinned`（RF-1 监狱页组合行序判据）；`spire-godot/tests/mutations.json::prison_page_row_order_is_pinned`（突变条目，本批未改）；`spire-godot/tools/check-mutation.ps1`（runner，sha256 `7AD26664CF69FD34EBB123A4C3F1D73BA6105A5FE85659BB93131887D7EF7338` 全程未变）。合同＝`C:/1/tmp/view-projection-plan/acceptance.md` §4 F（突变＋负例＋check-docs 面）、§4 H、§5.5（最终干净树全套重取＝本批两节）。step-5 独立审查报告＝`C:/1/Voidforge/tmp/ffix-step5/work/out/dsp-20261011T062842Z-f742/report.json`（其唯一应修项 RF-1 已由实现批 `88a6934` 修复；本节为该修复的加固者取证，审查复核由协调者另派）。
- 执行口径：工作树 `C:\1\tmp\magic-spire-wt-fact-on-norms`，枝 `fact-lookup-on-norms`；`GODOT_BIN` 每 shell 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；pwsh 7.6.6；单引擎串行（每轮跑前跑后 `Get-Process Godot*` 为 0）；命令经 `pwsh -NoProfile -File` 脚本（工作树 `tmp/`，UTF-8 无 BOM）；心跳 `tmp/agent-F-hardener2.log`。
- **加固者发现与修复（2026-10-11）**：RF-1 修复提交 `88a6934`（fix(ui): restore prison page row order…）上首轮突变取证中，`prison_page_row_order_is_pinned` 突变轮（运行 `20261011T080458388-146084`，identity `head=88a6934ff797db52de4bd03b1198909bc2568f5c`、开局 dirty=0；子 check `20261011T080459275-217656`）**判 FAILED 非 RED**：突变（`page_rows.append_array(prison)` → `prison+page_rows`，即 65e1c08 的 prepend 回归形态）已应用且逐字节还原（restored=True），但 architecture 套件整轮 PASS（120806 断言）——具名判据未红。根因＝判据只锚两条读取表达式 `TargetQueries.facts(view,"item")`／`TargetQueries.facts(view,"prison")`，而该改写保留两锚及其文本先后序，源文本断言抓不到拼接算子的翻转。处置＝加固者最小修复（授权面内：判据敏感性补齐，不动产品源码）→ **`e809bc9`** `fix(tests): anchor the prison append line so the declared RF-1 mutation reddens`：`prison_read` 锚升级为完整 append 行 `page_rows.append_array(TargetQueries.facts(view,"prison"))`（函数体内恰一次），prepend 改写删行即锚全量检查红；注释同步写明①②与锚选择理由。`ui/main.gd`、`mutations.json`、runner 均未改。以下全部取证改在**最终 head＝`e809bc99961aab9d44c3aa8bbc81009df333dbe7`**（含 `88a6934`）的干净树（`git status --short` 为空）上重取。
- 突变正式取证（十条＝`prison_page_row_order_is_pinned`＋既有九条，逐条 `tools/check-mutation.ps1 -Check <名> -TimeoutSeconds 1800`；总 stdout/stderr 归档 `tmp/F-hardener2-mutation-<名>.log`，紧随命令 `$LASTEXITCODE` 逐条为 0；十条全部 RED＋`restored=True`＋逐字节还原＋外层 identity 开局 `dirty=0` 且轮后 `git status --short` 为空＋无 `MUTATION RESIDUE`＋子 check `summary.json` `status=failed`、`before==after`＋目标日志无 `SOURCE CHANGED`／无 `ObjectDB instances were leaked`／无 `resources still in use`（G5/G6 fail-closed 分栏未触发）＋外层 exit 0；子轮人工突变后 dirty=1 属预期，不作产品身份）：
  - 1 `prison_page_row_order_is_pinned`（rules）→ 突变轮 `20261011T081248977-141084`，子 `20261011T081249771-120300`：sha256 `F8EFD8DB6CAE`，239.9s；`SUITE RESULT: architecture FAIL`；具名 ERROR＝`RF1 prison_page_row_order_is_pinned: every row-order anchor occurs exactly once in _prison_location_details (a phantom or ambiguous anchor is red): ["page_rows.append_array(TargetQueries.facts(view,\"prison\"))"]`（prepend 改写删锚即红，本批修复的敏感性证明）。归档 `tmp/F-hardener2-mutation-prison_page_row_order_is_pinned.log`。
  - 2 `present_demand_recorder`（execution=recipe，真 60 提交相位）→ `20261011T081721093-153752`，子 `20261011T081721846-40800`：sha256 `681F30754A41`，57.3s；`RECIPE seed=7 commits=60 steps=60 stop=cap`＋`UI FAIL: 72 assertions`＋`F3 OBSERVER RESTORED true`；具名 ERROR＝`F3 present_demand_recorder: actual UI leaf observations are nonempty (disabled notifications are red): events=0 nonempty=0`（子轮原日志）。归档 `tmp/F-hardener2-mutation-present_demand_recorder.log`。
  - 3 `section_read_sets_are_pinned`（rules）→ `20261011T081848101-274192`，子 `20261011T081848905-127436`：sha256 `29CAF1F6B04B`，240.9s；`SUITE RESULT: architecture FAIL`；具名 ERROR 两条（`F2 … extra anchors normalize once, preserve all 35 legacy main entries, …`／`F2 … focus_bodies query chain share one independent interaction declaration, …`）。归档 `tmp/F-hardener2-mutation-section_read_sets_are_pinned.log`。
  - 4 `bound_click_focus_owner`（ui/display）→ `20261011T082259395-66500`，子 `20261011T082300128-72784`：sha256 `29CAF1F6B04B`，143.2s；`SUITE RESULT: display FAIL`＋`UI FAIL: 1305 assertions`；具名 ERROR＝`F2 bound_click_focus_owner: the real bound-click prison leaf, even when empty, belongs to the nearest dedicated interaction/target_drag entry, not outer hand`。归档 `tmp/F-hardener2-mutation-bound_click_focus_owner.log`。
  - 5 `submit_full_fallback_uses_source`（ui/display）→ `20261011T082531769-161216`，子 `20261011T082532505-107544`：sha256 `F8EFD8DB6CAE`，144.9s；`SUITE RESULT: display FAIL`＋`UI FAIL: 1313 assertions`；具名 ERROR＝`F4 submit_full_fallback_uses_source: nonempty dirty reads overload from source, not the previous View`。归档 `tmp/F-hardener2-mutation-submit_full_fallback_uses_source.log`。
  - 6 `read_observer_boundaries`（ui/display）→ `20261011T082805291-101588`，子 `20261011T082806146-55476`：sha256 `681F30754A41`，145.2s；`SUITE RESULT: display FAIL`＋`UI FAIL: 1313 assertions`；具名 ERROR＝`F3 read_observer_boundaries: changing isolated event rows/scope cannot change the live projection`。归档 `tmp/F-hardener2-mutation-read_observer_boundaries.log`。
  - 7 `fact_groups_are_total`（rules）→ `20261011T083039368-208648`，子 `20261011T083040201-82752`：sha256 `0EB6F5DB0379`，244.4s；`SUITE RESULT: architecture FAIL`；具名 ERROR＝`K4 fact_groups_are_total: the declared universe equals the unit table's group union (one vocabulary, two faces): […"manual_probe"…]`（子轮原日志）。归档 `tmp/F-hardener2-mutation-fact_groups_are_total.log`。
  - 8 `demand_declarations_are_total`（rules）→ `20261011T083532920-131804`，子 `20261011T083533805-167028`：sha256 `F8EFD8DB6CAE`，242.4s；`SUITE RESULT: architecture FAIL`；具名 ERROR 四条（`F1 … ["relics declares unread relic_probe"]`／`… ["relics.relic_probe"]`／`… ["relics.relic undeclared without a registered reason"]`／`… frozen non-empty difference {chain, demo_exit} … ["chain", "demo_exit", "relic"]`）。归档 `tmp/F-hardener2-mutation-demand_declarations_are_total.log`。
  - 9 `command_facts_full_scope_is_content_equal`（rules，R-T8）→ `20261011T083959074-230184`，子 `20261011T083959820-229716`：sha256 `E6B3FC908384`，243.3s；`SUITE RESULT: architecture FAIL`；具名 ERROR 三条（`F8 … size heuristic is gone`／`… content equality against the truth-source full group`／`… ["battle:0 the equal-size non-full demand occupied the batch slot (builds=1)", "battle:0 the same-batch full-group read was polluted by the earlier non-full demand", "battle:12 …"]`）。归档 `tmp/F-hardener2-mutation-command_facts_full_scope_is_content_equal.log`。
  - 10 `lazy_projection_invariant`（rules，前缀态扩面）→ `20261011T084411312-226704`，子 `20261011T084412035-39496`：sha256 `0EB6F5DB0379`，237.7s；`SUITE RESULT: architecture FAIL`；具名 ERROR 三条（行面子序列／scope 三方互核／LPI 值面，红样例落 `rest:0@relics_open`／`rest:0@body_details`／`rest:0@route_only`／`rest:12@relics_open.items` 等前缀态画像）。归档 `tmp/F-hardener2-mutation-lazy_projection_invariant.log`。
  - 十轮 identity：各轮 `build/mutations/<突变轮运行号>/identity.txt` 落盘，`head=e809bc99961aab9d44c3aa8bbc81009df333dbe7`、开局 `dirty=0`。
- 无引擎负例（R-FR4；可执行产物只在工作树 `tmp/`）：runner sha256＝`7AD26664CF69FD34EBB123A4C3F1D73BA6105A5FE85659BB93131887D7EF7338`（＝`e809bc9` 的当前字节，与上一批 346198b 相同——runner 未改）。脚本 `tmp/F-runner-selection-negative.ps1`（隔离拷贝 runner 字节＋`find-godot` 替身指向不可启动路径＋最小 mutations 表）。两例：`unknown`（execution=`no_such_execution`）→ 子 runner exit=1、原错误 `Unknown mutation execution: no_such_execution` 命中、非 RED、无引擎启动、无二次异常；`missing`（合法 execution=rules＋不存在 target file）→ exit=1、`target file not found: does-not-exist.gd` 命中、同样 fail-closed。聚合 exit 0，runner sha256 与 `git status --porcelain` 前后不变。逐例日志 `tmp/F-runner-negative-20261011T084831768/unknown.log`／`missing.log`，汇总归档 `tmp/F-hardener2-negative.log`。
- `tools/check-docs.ps1` 单跑（`e809bc9`）→ `DOCS PASS: 43 rule-class document(s), 2369 reference(s) checked, allowlist 3 entrie(s)`，exit 0；归档 `tmp/F-hardener2-check-docs.log`。
- **§4 F 套件面由同 head 的 H 轮充当**：`88a6934` 相对 `346198b`（上一批已全量取证，见前节）只动 `ui/main.gd`（拼接序恢复表序、emission 不变、注释）、`tests/architecture_cases.gd`（新增同名单条判据）、`tests/mutations.json`（新增同名单条目）＋记录册；`e809bc9` 只动 `tests/architecture_cases.gd` 的同名单条判据锚。§4 F 的三条套件命令（architecture -Impact／UI 十模块／recipe）不再在本 head 重复重跑，其绿证据由本 head 的 H 里程碑全量回归充当（见下一节；H 的 rules 阶段含 architecture 分类、UI 阶段含十模块全量、recipe 阶段同命令同判读），避免同一 head 重复三套重套件。
- 缺口清单登记（§5.4 C 口径）：`GAP FREEZE frozen=54 current=53`（较冻结净减 1，只许缩短方向成立）；剩余 53 条逐条登记在 `tests/mutations.json::known_gaps`（谁欠谁补＝既有重放线判据，非本片新增；本片判据均随批附带突变证据，未新增缺口）。
- 四态：**已测**＝十条突变轮＋无引擎负例两例＋check-docs 单跑（运行号、identity、归档路径如上）＋H 里程碑两轮（下一节）；**未跑**＝`-Exhaustive` 独立取轮（`-Suite all` 已自动启用完整随机样本，随 H 轮覆盖）、`-VerifyRunner`（测试器自身未改，runner 判读面由十条突变轮＋负例覆盖）、`-All` 其余既有条目（归 G，未进入 G）、`tools/check-content.ps1`（未改 `content/packs/`）、安卓真机、打包与发布、step-5 报告的复核受影响范围（协调者另派）；**被跳过**＝无；**假设**＝无。无效轮如实登记：一次 H 启动因 `-TimeoutSeconds 7200` 超出 runner `ValidateRange(1,3600)` 被参数校验拒绝（脚本未执行任何阶段、无运行目录、exit 0 但无 SUITE 输出；证据 `tmp/F-hardener2-H-all-timeout7200-rejected.log`），改按既有 H 先例（2026-10-04 `…190603837` 同命令形）取 3600 重跑；该轮不作证据。
- 本节只追加 `docs/record/verification.md` 一个文件、与 H 节同批单独提交；全部提交仅在本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-11｜事实表「面 / 点」收口 H 里程碑：全量回归（-Suite all -UI -UISuite all）＋长时程配方（-Suite recipe）

- 域：`spire-godot/tests/test_game.gd::SUITES`（规则 52 分类）／`spire-godot/tests/ui_smoke.gd::UI_MODULES`（UI 47 模块）／`spire-godot/tests/recipe_driver.gd::_run_recipe`（配方种子 7）。合同＝`C:/1/tmp/view-projection-plan/acceptance.md` §4 H（完整回归只在里程碑跑一次；`-RerunFailed` 不能代替原选范围复验）＋ §5.5（最终干净树全套重取＝本批）。本节兼作 F 批 §4 F 的套件面证据（同 head＝`e809bc99961aab9d44c3aa8bbc81009df333dbe7`，见上一节「套件面由同 head 的 H 轮充当」）：rules 52 分类含 architecture，UI 47 模块含 F 批十模块，display 相位内记录器证据随轮覆盖。
- 执行口径：同上一节（工作树、枝、`GODOT_BIN`、pwsh 7.6.6、单引擎串行、每轮跑前跑后 `Get-Process Godot*` 为 0、心跳 `tmp/agent-F-hardener2.log`）。
- 命令面偏差（如实登记）：acceptance §4 H 写 `-TimeoutSeconds 7200`，当前 `tools/check.ps1` 的 `TimeoutSeconds` 为 `ValidateRange(1,3600)`，7200 被参数校验拒绝（脚本未执行任何阶段、无运行目录、exit 0 但无 SUITE 输出；证据 `tmp/F-hardener2-H-all-timeout7200-rejected.log`）；按既有 H 先例（2026-10-04 全量 `…190603837` 同命令形）取上限 3600 重跑，范围与判读不变。
- ①`tools/check.ps1 -Suite all -UI -UISuite all -TimeoutSeconds 3600` → 运行 `20261011T085125987-100592`：`RUN IDENTITY head=e809bc99961aab9d44c3aa8bbc81009df333dbe7 dirty=0`；`RULE SAMPLING: exhaustive`（`-Suite all` 自动启用完整随机样本，`exhaustive=true`）＋`DOCS RESULT: PASS`（43 规则文档／2369 引用／允许清单 3）；rules 52/52 分类逐行 `SUITE RESULT: <名> PASS`＋`PASS: 152401 assertions`＋`CHECK rules: 1,189.74s`；UI 47/47 模块逐行 `SUITE RESULT: <名> PASS`＋`UI PASS: 8030 assertions`＋`CHECK ui: 1,841.48s`；exit 0；`summary.json` `status=passed`、`before==after`、`rules.failed=[]`／`ui.failed=[]`、两阶段 `complete=true`、无 `SOURCE CHANGED`。随轮绿行：`FROZEN ANCHORS: 3 anchor(s) recomputed from git blobs, 3 matched`、`MUTATION GAP FREEZE frozen=54 current=53 shrunk=1`（§5.4 C 口径：较冻结净减 1，只许缩短成立）、`F1 DEMAND TABLES sections=15 groups=25 declared=9 scope=24 fallback_phases=17`、`F2 SECTION READ SETS sections=15 groups=25`、`F8 SLOT ADMISSION cells=2 crafted_size=26 full_size=26`、`E LAZY PROFILES compared=450 commits=60 prefix=2`、`E BASELINE DIFF declared=26 moved=26`、`BASELINE CONSTANTS FROZEN pairs=5`。display 相位记录器证据：15×`F3 OBSERVER RESTORED true`＋`F3 ACTUAL READS` 逐轮覆盖 local／interaction／page 三域。归档 `tmp/F-hardener2-H-all.log`。
- ②`tools/check.ps1 -Suite recipe -TimeoutSeconds 1800` → 运行 `20261011T094353584-139616`：`RUN IDENTITY head=e809bc99961aab9d44c3aa8bbc81009df333dbe7 dirty=0`；`RECIPE DRIVER engine=4.7.2-stable (official) seed=7 cap=60 style=trade window=1600x900`；收尾 `RECIPE seed=7 commits=60 steps=60 stop=cap`＋`UI PASS: 194 assertions`＋`CHECK recipe: 51.10s, exit=0`，exit 0；`summary.json` `status=passed`、`before==after`、`recipe.seed=7 commits=60 stop=cap exit=0`。`check-recipe.log`：`F3 OBSERVER RESTORED true`＋`F3 ACTUAL READS events=2747 nonempty=1679 versions=61 roles={key:1362, rebuild:1385} coverage={local:{relics:{relic:720}, actions, resources, posture, drawers, body_details, scene_instances}, page:{reward:32, route:23, event:5, prison:181}, interaction:{target_drag:{card:42, prison:42}}}`。归档 `tmp/F-hardener2-H-recipe.log`。
- 四态：**已测**＝①②（运行号、identity、逐分类结果、完成标记、指纹如上）；**未跑**＝安卓真机、打包与发布、`-VerifyRunner`（测试器自身未改；判读面由十条突变轮＋无引擎负例覆盖，见上一节）、`-All` 其余既有条目（归 G，未进入 G）、`tools/check-content.ps1`（未改 `content/packs/`）、step-5 报告的复核受影响范围（协调者另派）；**被跳过**＝无；**假设**＝无。推送／打包不在本片授权面（acceptance §4 H）。
- 本节只追加 `docs/record/verification.md` 一个文件、与 F 追加节同批单独提交；全部提交仅在本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-12｜投影收口片闭合：修复批双独立审查 PASS＋G 段处置＋切片闭合（协调者代批，自主模式）

- 域：本节（`docs/record/verification.md` 只追加）；对象＝修复批提交链 `32ca5bb..80de52b`（`d42577b` 清洁者 G1/G4 → `65e1c08` 实现者 G2/G3/G7/G8 → `346198b` 加固者入册 → `9a76439` 记录 → `88a6934` RF-1 修复 → `e809bc9` 突变锚修正 → `80de52b` 记录）。
- 修复批双独立审查（人令：免费档故障跳过等待、审查改会话模型双子代理、不再走 voidforge；审查会话与各批执行会话均独立）：**A（裁定落地面）**＝G1 单归属源（`INTERACTION_READ_OWNERS` 全仓零残留、legacy==35 人工复核、`_read_owner` 只消费 EXTERNAL_READ_OWNERS＋f_main_owners）、G2 独立复算 raw 并集 9＋VIEW_FACT_GROUPS 15＝24⊊fact_groups()=26 且差集恰 {chain,demo_exit}、G3 键碰撞追认（52 条无重复键，被取代的 _relic_row face 无独立判据——mutation_judgment_universe 派生方式实核）、RF-1 行序对照 `git show 32ca5bb` 实证恢复（不信注释）、幻影名零残留、面守恒（R3_VIEW_MASK 单项增量＝acceptance C-F-6 明文授权，实测合规）；**B（证据面）**＝十轮突变 identity 逐一 head=e809bc99961a… dirty=0、H 断言 152401/8030 全量求和精确吻合、88a6934 存活轮→e809bc9 锚修正→RED 复证链完整、负例 runner sha256=7AD26664CF69FD34EBB123A4C3F1D73BA6105A5FE85659BB93131887D7EF7338 自算与当前字节一致、记录两节纯追加无夹带。两报告均 `VERDICT: PASS`，全文存计划区（仓外）`audit-ffix-A-rulings.md`／`audit-ffix-B-evidence.md`；两条残余在报告中如实登记（行序锚不防「装配后新增排序代码」类新写法，低风险；ui 轮级联红少列非虚报）。
- G 段（`-All` 其余既有条目）：**按 O-3 裁定未进入**，本组未跑、不作通过（对应上节四态「未跑」行）。
- 切片闭合声明：《紧缚尖塔》投影收口片（单元表 A→域臂 B→单次构造 C→批内复用 D→需求声明与两标量 E→工具与锚 T→接线 F→修复批→RF-1→H 里程碑）全链闭合于 `80de52b`；验收者职能由 ffix 三份免费池报告（其发现 RF-1 已被 `88a6934`/`e809bc9` 消解，并由本节 A/B 双审覆盖）与 A/B 双审承担。
- 四态：**已测**＝本节登记之双审查（读面＝git 对象＋落盘证据产物，未跑引擎）；**未跑**＝推送／PR／合并（待人点名）、安卓真机、打包发布、免费档恢复后的可选 muse/step-5 补审；**被跳过**＝无；**假设**＝无。
- 本节只追加本文件一个文件；单独提交；未推送、未 tag、未改版本号、未开 PR。

## 2026-10-13｜片①（每点击完整性检查收口）加固批：合同命令清单、三条突变 RED、A-PC-9 语料敏感性两轮、A-PC-10 计时、H 里程碑

- 域：`spire-godot/core/game.gd`（`debug_checks_enabled`／`set_debug_checks_enabled`／`_debug_check`／`command_domain_ready`／`dispatch` 两段门）、`spire-godot/core/room_events.gd::probe_result` 的整状态一半、`spire-godot/tests/architecture_cases.gd`（三条新判据＋`branch_sweep_states` 的 domain_blocked 夹具）、`spire-godot/tests/mutations.json`（三条新条目）；本节只追加本文件。合同＝`C:\1\tmp\check-routing-plan\acceptance.md` §2（A-PC-1..10 含敏感性口径）、§4 片①命令清单、§1/§6（每条结论写明命令／运行号／退出码或 status／断言计数／红集／before==after；四态）。实现＝`369569b`（`refactor(core): gate per-click integrity checks behind the debug switch`，4 文件 +286/−16）；清洁者零改动报告＝工作树 `tmp/clickclean-report.md`（已核对：六项结论＋零改动，未提交）。加固者修复＝`31c0ffe`（`fix(tests): complete the domain_blocked sweep fixture so gate-off runs stay script-error free`，`tests/architecture_cases.gd` +10/−6）。
- 执行口径：工作树 `C:\1\tmp\magic-spire-wt-click-check`，枝 `worker/click-check-gating`；`GODOT_BIN` 每 shell 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；pwsh 7.6.6；单引擎串行（每轮跑前跑后 `Get-Process Godot*` 为 0）；长命令经 `pwsh -NoProfile -File` 脚本（工作树 `tmp/`，UTF-8 无 BOM）；心跳与逐轮起止 `tmp/agent-clickharden.log`。判读通用＝退出码或 `status`＋`SUITE RESULT` 行＋完成标记＋`summary.json` 的 `before==after`；无 `SOURCE CHANGED`。
- 命令清单（acceptance §4 片①；`head=369569b` 与修复后 `head=31c0ffe` 分列，后者为受影响域的最终证据）：
  - ①`tools/check.ps1 -Suite architecture -TimeoutSeconds 900` → `369569b`：运行 `20261013T005153815-29052`，exit 0，`SUITE RESULT: architecture PASS`，`PASS: 120909 assertions`，红集＝[]、`unrun=[]`、`before==after`，docs PASS（43 规则文档／2369 引用／允许清单 3），`CHECK rules: 260.07s`；`head=31c0ffe` 重取：运行 `20261013T012830190-33708`，exit 0，`PASS: 120909 assertions`，红集＝[]、`before==after`，docs PASS，263.25s（同树同计数；夹具修复未移动任何冻结行）。
  - ②`tools/check.ps1 -Suite architecture,events,event_flow,core,runner -Impact -KeepGoing -TimeoutSeconds 1200` → `369569b`：运行 `20261013T005644447-28420`，exit 0，28/28 分类 PASS，`PASS: 137263 assertions`，`impact=true`、红集＝[]、`before==after`，docs PASS，398.17s；`head=31c0ffe` 重取：运行 `20261013T013318529-40132`，exit 0，28/28 PASS，`PASS: 137263 assertions`，415.92s。
  - ③`tools/check.ps1 -Suite recipe -TimeoutSeconds 1800` → 运行 `20261013T010343715-22188`（`369569b`）：`RUN IDENTITY head=369569b… dirty=0`；`RECIPE DRIVER engine=4.7.2-stable (official) seed=7 cap=60 style=trade window=1600x900`；收尾 `RECIPE seed=7 commits=60 steps=60 stop=cap`＋`UI PASS: 194 assertions`＋`CHECK recipe: 49.13s, exit=0`，exit 0，`before==after`。夹具修复不改 recipe 身份块所载 5 文件（`ui/card_face.gd`／`tests/recipe_driver.gd`／`tests/ui_smoke.gd`／`tests/normal_play_cases.gd`／`tests/game_fixture.gd` 逐字节未动）故该轮不必重取。
  - ④`tools/check.ps1 -UIOnly -UISuite home -TimeoutSeconds 900` → 运行 `20261013T010454574-40312`（`369569b`）：`SUITE RESULT: home PASS`＋`UI PASS: 140 assertions`＋`CHECK ui: 34.92s`，exit 0，`before==after`，docs PASS。`ui_smoke` 不加载 `tests/architecture_cases.gd`，夹具修复不在其域内。
  - ⑤突变三条；⑥A-PC-9；⑦A-PC-10；⑧H 里程碑；`tools/check-docs.ps1` 单跑（逐条证据见下）。
- 突变取证（acceptance §2 A-PC-1/2/4/7 的机械口径；判读＝目标判据具名 ERROR＋逐字节还原＋identity `dirty=0`＋无 `MUTATION RESIDUE`＋外层 exit 0）：
  - 首轮在 `369569b` 上跑同一命令，结果 2/3（归档 `tmp/clickharden-5-mutations.log`；突变运行 `build/mutations/20261013T010603229-39460`，identity `head=369569b6a210ca0a8ab6b99ca105069ab6718f28`、开局 `dirty=0`）：`per_click_checks_are_debug_only` 判 FAILED（`Target phase contains a source/environment/loading/runtime failure, not a judgment RED`）；根因＝突变体让开关恒 false 后，`branch_sweep_states` 的 domain_blocked 夹具（旧 `no_such_special` 占位：类型未登记且缺 `durability`）在门控关闭时进入 `worn_count` 与 `TYPES` 直取，该子轮出现 1989 条 `SCRIPT ERROR`，`check-mutation.ps1` 的 runtime-error 分栏按设计拒绝其为 RED；另两条同轮 RED（266.2s／267.1s，`restored=True`）。根因在授权面（夹具记录不完整，与 plan §6.5「坏状态夹具必须保持记录结构完整」同类）→ 加固者最小修复 `31c0ffe`：domain_blocked 夹具改用正式安装工厂（`_install_special("shaft_ring_low","special_2_a")`）＋重复家族孪生，记录完整、域仍被阻断；先以探针 `build/click-fix-probe/probe.gd` 证冻结面零移动（63/63 sweep 行与 `PREFIX_BRANCH_TABLE_BASELINE` 相等、门控关命令面 0 脚本错误）。不 amend；受影响轮（① ② ⑤ ⑥ ⑦ ⑧）全部在 `31c0ffe` 重取。
  - 正式轮 `tools/check-mutation.ps1 -Check per_click_checks_are_debug_only,per_click_diagnostics_stay_out_of_the_game,projection_integrity_gate_is_declared_once -TimeoutSeconds 1800` → 突变运行 `build/mutations/20261013T014039553-34896`，`RUN IDENTITY head=31c0ffe3af823e0a3ab3ab3ac603c018436a2490`、开局 `dirty=0`；**3/3 RED**＋逐条 `restored=True`（sha256 `85B78FF3C8D5A12105A6DBF09027DE54C1E53D1DFC0A68F0AE7BA8B878001D26`）＋`worktree unchanged=True (pre-dirty=0)`＋无 `MUTATION RESIDUE`＋elapsed 830.8s＋exit 0；三条子轮 0 `SCRIPT ERROR`：
    - `per_click_checks_are_debug_only` → 子 `20261013T014040161-40044`：`SUITE RESULT: architecture FAIL`，`FAIL: 28/126582 assertions`，281.2s；红行＝本判据「开关开」侧断言（`a debug build enables the checks by default`／五道 `switch on, the gated check keeps its own rejection wording`／五道诊断落点／`the override turns it back on`／`the build type is the switch's only source`／探针整状态一半两条）。
    - `per_click_diagnostics_stay_out_of_the_game` → 子 `20261013T014521367-43576`：`FAIL: 18/120909 assertions`，282.3s；10 条具名红（`the diagnostics never enter state or the save`／`no sink carries the diagnostics`，逐坏状态）。
    - `projection_integrity_gate_is_declared_once` → 子 `20261013T015003754-37884`：`FAIL: 9/120909 assertions`，267.3s；红行＝`the domain predicate is declared exactly once in core/game.gd: 2`／`base_action_block reuses the gate instead of inlining the predicate`／`keeps the phase guard before reusing the gate`／`switch off, the projection gate is not evaluated`。
    - 归档：`tmp/clickharden-mutation-<条目名>-31c0ffe.log`（逐条划分）＋`tmp/clickharden-5-mutations-r2.log`（整轮）；子轮原始日志 `spire-godot/build/checks/<子运行号>/`（gitignored）。
- A-PC-9 语料敏感性（当前语料重测；F2 旧结论只作方向）：临时改写＝`core/game.gd::debug_checks_enabled()` 末行 `return true` → `return false`（唯一锚 count＝1；改写前 sha256 `85B78FF3C8D5A12105A6DBF09027DE54C1E53D1DFC0A68F0AE7BA8B878001D26`，改写后 `1F2BA0C630493D458EDF01F6DDE6883CEC5767C8B1B579B2850EF912078CAF49`；备份 `tmp/clickharden-apc9-backup/`）。不为此新增突变条目。
  - 合同命令 `tools/check.ps1 -Suite all -KeepGoing -TimeoutSeconds 3600` 实跑一次，运行 `20261013T015616308-40440`：在第 3600s（`check.ps1` 的 `ValidateRange(1,3600)` 上限）被超时终止——已完成 35 分类（`architecture FAIL`＋34 分类 PASS、0 `SCRIPT ERROR`，`normal_play` 未完结），无 `summary.json`；该轮登记为未完成，不作通过口径。
  - 同口径拆两轮覆盖同一 52 分类（分界＝实现者 run5/run6 的原分界：前 14＝`witch_character…architecture`，其余 38）：
    - 轮 A（前 14 分类）→ 运行 `20261013T030027365-41240`：`architecture FAIL`，`FAIL: 23/135560 assertions`（23 条 ERROR、0 `SCRIPT ERROR`），13 分类 PASS，`before==after`，docs PASS，627.5s，exit 1。红项＝三条新判据的「开关开」侧断言（默认关后不再成立）＋`K4 lazy_projection_invariant` 的 `prefix:domain_blocked` 两条＋`prefix_branch_tables_are_frozen` 的 `sweep:*|domain_blocked` 行面（`have=["rest_choice","8",…] want=["domain_blocked","0",…]`）。
    - 轮 B（其余 38 分类）→ 运行 `20261013T031130653-22544`：37 分类 PASS＋`events FAIL`，`FAIL: 1/18166 assertions`（`EVENT GATE a state that fails the game validator reports validate_failed: {"gate":"","reason":""}`），`before==after`，docs PASS，1763.3s，exit 1。
    - 逐套件红项（52/52 全覆盖）：仅 `architecture`（23 断言）与 `events`（1 断言）变红；`event_flow`／`core` 及其余 50 分类全绿；两轮合计 0 `SCRIPT ERROR`。与 F2 的旧方向一致（探针整状态一半＝events 的唯一红项；门控未带走非探针面）。口径如实登记：实现者 A-PC-9 轮登记的批量 `durability` 脚本错误（其 run5 日志实为 1989 条）在夹具补全后不再出现（本批两轮均 0 条）。
  - 还原与逐字节证明：以备份还原后 `core/game.gd sha256=85B78FF3C8D5A12105A6DBF09027DE54C1E53D1DFC0A68F0AE7BA8B878001D26`（＝改写前）、`core/room_events.gd sha256=8062382A6CCC36156C6AC511CAAFAB27AA7787F110E057E9C8140F67605B0964`（改写前即该值，未参与改写）；`git status --porcelain` 0 行（与 `31c0ffe` 逐字节一致）。日志 `tmp/clickharden-6a-apc9-runA.log`（超时轮）／`tmp/clickharden-6-apc9-roundA.log`／`tmp/clickharden-6-apc9-roundB.log`。
- A-PC-10 开销取证（无判值阈值；只记计数与两组墙钟原始数据）：驱动 `spire-godot/build/click-perf-apc10/bench.gd`（gitignored，不入库）；夹具＝`tests/architecture_cases.gd::r1_build("battle", tier)`（0/12/26 件，逐样本断言 `physical_pieces().size()==tier`、`validate()==""`）；两组＝开关默认（debug 开）／`set_debug_checks_enabled(false)`，按样本交错同机同轮；每组每档 2 热身＋15 有效（中位数）；`dispatch`＝该夹具合法结束回合指令的一次 `dispatch`（新夹具构造与指令查找不计时），投影＝一次 `get_view()`；原始数据 `tmp/clickharden-apc10-paired.json`（运行号 `20261013T034255108-28564`，`problems=0`；块序对照轮 `20261013T034131064-24008` 存 `tmp/clickharden-apc10-paired-blockrun.json`）。
  - 计数：0/12/26 三档 × 2 组 × 17 样本（2 热身＋15 有效）；每组每档 `dispatch`／投影各 15 个有效样本；每样本提交后状态已推进且 `validate()==""`。
  - `dispatch` 中位（µs，开→关）：0 件 `21212→16375`；12 件 `23984→20107`；26 件 `59189→51785`；逐对（关/开）比值中位 `0.8271`／`0.8384`／`0.8811`。
  - 一次投影中位（µs，开→关）：0 件 `33798→35261`；12 件 `51083→51766`；26 件 `128120→130281`；逐对比值中位 `1.0245`／`1.0645`／`0.9952`。
  - 判据口径（关组不得出现随装备件数增长更快）：`dispatch` 面关组每档都更快且 0→26 绝对增量更小（关 +35.4ms ＜ 开 +38.0ms；`12→26` 关 +31.7ms ＜ 开 +35.2ms）；投影面 0→26 增量 关 +95.0ms ≈ 开 +94.3ms（差 0.7ms，且块序对照轮为关 +81.1ms ＜ 开 +88.1ms——两次同机轮方向翻转，量级 34–130ms 下属噪声）。关组未出现随件数增长更快的稳定信号。毫秒只报告，不作他判据。
- 判据→证据映射（acceptance §1 的逐条口径）：`A-PC-1/2/3/5/6` ＝ 突变 `per_click_checks_are_debug_only` RED（五道「开关开」文案拒绝、诊断落点、探针两半的具名红）＋命令 ①② 绿＋recipe 真窗口 60 提交；`A-PC-4` ＝ 突变 `projection_integrity_gate_is_declared_once` RED（表达式计数 2／复用与阶段守卫的具名红）＋①② 里该判据绿；`A-PC-7` ＝ 突变 `per_click_diagnostics_stay_out_of_the_game` RED（10 条具名红）；`A-PC-8` ＝ ①② 与里程碑的既有冻结判据绿（`E BASELINE DIFF declared=26 moved=26`／`BASELINE CONSTANTS FROZEN pairs=5`／26 cell 零移动，随 architecture 轮）；`A-PC-9` ＝ 上述两轮红集与 sha256 复原；`A-PC-10` ＝ 计时轮两组三档原始数据。
- H 里程碑（协调者裁定跑，沿用上批 H 先例＝同命令形 `-TimeoutSeconds 3600`）：`tools/check.ps1 -Suite all -UI -UISuite all -TimeoutSeconds 3600`
  - 该单命令在 `31c0ffe` 上先被环境打断两次（均非检查失败，无 `summary.json`、无 `CHECK EXIT`，登记为被中断轮、不作证据）：首轮运行 `20261013T034355922-31728` 于 04:08:48Z 后停写（主机本地 15:08:50 进入 Modern Standby、原因 Lid）；次轮运行 `20261013T051131564-35292` 规则相位 52/52 已记 `PASS: 152504 assertions`，随后界面相位在 `basic_attacks` 停写（后台任务约 60 分钟上限与主机低功耗窗口叠加）。现场归档 `tmp/clickharden-milestone-interrupted-run/`、`tmp/clickharden-8-milestone-r2-interrupted.log`。
  - 正式轮（同命令、同干净 head，脱离后台任务托管并监控，串行单引擎）：运行 `20261013T061413770-31656`，`head=31c0ffe`、开局 `dirty=0`；`RULE SAMPLING: exhaustive`＋`DOCS RESULT: PASS`（43／2369／3）；规则 52/52 分类逐行 `SUITE RESULT: <名> PASS`＋`PASS: 152504 assertions`（`CHECK rules: 1,901.88s`，红集＝[]、`unrun=[]`）；界面 47/47 模块逐行 `SUITE RESULT: <名> PASS`＋`UI PASS: 8030 assertions`（`CHECK ui: 1,810.51s`，红集＝[]）；exit 0（整命令 3724.2s，两相位各自在 3600s 上限内）；`summary.json` `status=passed`、`before==after`、`rules.complete=true`／`ui.complete=true`、`exhaustive=true`。随轮绿行：`FROZEN ANCHORS: 3 anchor(s) recomputed from git blobs, 3 matched`／`MUTATION GAP FREEZE frozen=54 current=53 shrunk=1`／`E BASELINE DIFF declared=26 moved=26`／`BASELINE CONSTANTS FROZEN pairs=5 source=tests/frozen-baselines.json`／界面记录器 `F3 OBSERVER RESTORED true`。归档 `tmp/clickharden-8-milestone-r3.log`。
- `tools/check-docs.ps1` 单跑 → `DOCS PASS: 43 rule-class document(s), 2369 reference(s) checked, allowlist 3 entrie(s)`，exit 0；归档 `tmp/clickharden-9-docs.log`。
- 四态：**已测**＝①（两 head）②（两 head）③④＋突变正式轮 3/3＋A-PC-9 两轮＋A-PC-10（运行号与归档如上）＋H 里程碑正式轮＋check-docs 单跑；**未跑**＝片②（检查路由；另片）、安卓真机、打包与发布、独立审查（协调者另派新会话）；**被跳过**＝无；**假设**＝无。被中断轮与无 summary 的轮（A-PC-9 单命令超时轮、里程碑前两轮）均如实登记为未完成，不写成通过。
- 本节只追加本文件一个文件、单独提交（docs-only）；全部提交仅在本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。

### 片①记录补登（2026-10-13，协调者代批；独立审查两条 [存疑] 的收口）

- 域：本节；依据＝独立审查（会话模型子代理，对象 `e565cb9..f116b10`，VERDICT PASS）第 1／2 条 [存疑]。
- **plan §7-① 处置A证据②③补登**：①**聚合兜底面**＝`dispatch` 尾部聚合校验＋`"行动未提交："` 回滚逐字节未动（判据 A-PC-3／A-PC-6 在案，见片①加固节）；②**release 差异登记**＝`debug_checks_enabled()` 在非 debug 构建恒 false ⇒ release 下五道检查与探针整状态半不跑、`_debug_check` 不写诊断；早拦损失由提交后聚合验证兜底并回滚（上批既定口径）。测试语料均在 debug 构建下运行、仍走检查面 ⇒ **测试不覆盖 release 差异本身**；release 产物行为差未跑验证（打包面），如实登记为未验证。
- **探针日志澄清句**：片①加固节所称「命令面 0 脚本错误」成立；审查另测得门控关闭轮 get_view 面存在 37 条与开关无关的脚本错误（relic_bundle/prison 夹具面），两者不矛盾，不作片①红集。
- 其余一条 [存疑]（判据消费者扫描面限 `res://core`；`dispatch` 次序无机械判据；切分归档只留前 3 条 ERROR）**登记为仍靠人审／已接受残余**，交后续片或 H 收尾处理。

### 片①验收一轮登记（2026-10-13，验收者；协调者代批收口其三条记录建议）

- 域：本节；对象 `e565cb9..8a4d832`（产品面 `31c0ffe`）。**判定＝验收通过**。
- 验收者自跑证据（自有运行号）：`-Suite architecture`＝`20261013T073604491-40288`（exit 0，`PASS: 120909`，红集 `[]`，before==after）；突变三条＝`build/mutations/20261013T074012321-29300`（identity `head=8a4d832 dirty=0`，**3/3 RED**，子轮 28/126582、18/120909、9/120909，逐条 restored、收工 4 文件 sha256 逐字节相同）；`check-docs.ps1`＝`DOCS PASS 43/2369/3`。G-PC-1..8 逐场景通过；A-PC-1..10 记录六项口径逐条在场（7 个 `build/checks` 运行号与突变目录、归档在盘并抽验一致）。
- 三条记录补全（本节执行）：①片①加固节 ③ recipe 与 ④ home 两行**红集＝`[]`**（补明）；②突变归档只保留每子轮前 3 条 ERROR，**完整红行回查路径＝`build/checks/<子运行号>/check-rules.log`**（点名）；③四态「未跑」再次点名 A-PC-9 超时轮 **`20261013T015616308-40440`**（无 `summary.json`，由两轮 14+38=52 等价覆盖，保留为未完成登记）。
- 未跑（未写成通过）：真 release 二进制行为（仅源码面锚定）；本轮未重跑 recipe 与 H 里程碑（评记录证据）；片②不在本轮域。

## 2026-10-13｜片②（检查路由）加固批：合同命令清单、八条突变 RED、三条判据补证与判据守卫修复

- 域：`spire-godot/tests/{check_index.gd,check_index_edges.gd,check_index.json,route_plan.gd,runner_cases.gd,mutations.json}`、`spire-godot/tools/{build_check_index.gd,check-index.ps1,check.ps1}` 的路由面、`docs/spec/check-routing.md`、`docs/spec/check-routing-dependencies.md`、`.zcode/skills/repo-ops/SKILL.md`；本节只追加本文件。合同＝`C:\1\tmp\check-routing-plan\acceptance.md` §3（A-RT-1..12）、§4 片②命令清单、§1/§6（每条结论写明命令／运行号／退出码或 status／断言计数／红集／before==after；四态同用）。
- 提交：切片链 `bdc8009`（feat）→`e050a5f`（docs）→`f08c4de`（clean）；加固批 `b68eeca`（`test(tests): evidence the three routed index judgements and register the review gaps`：`tests/mutations.json` +18、`docs/spec/check-routing-dependencies.md` +8）与修复 `7d7f4a3`（`fix(tests): report an unreadable frozen index instead of indexing an empty plan`：`tests/runner_cases.gd` +7、`tests/check_index.json` 同批重冻 1 行）。判据证据面绑定 `7d7f4a3`（本批最终源码）；本节单独提交（docs-only）。**仅本地 `.git`，未推送、未打 tag、未开 PR。**
- 现场事故（如实登记）：会话中途工作树 `C:\1\tmp\magic-spire-wt-check-routing` 与计划目录 `C:\1\tmp\check-routing-plan` 被外部进程删除（两次；目录消失、`git worktree list` 转 `prunable`），枝 `worker/check-routing` 与全部提交在主检出 `C:\1\magic-spire` 完好；按 `repo-ops` 以 `git worktree add -f <路径> worker/check-routing` 同枝重建（HEAD `f08c4de`、`git status` 空）。原 `tmp/`（实现者／清洁者报告与原始日志）与 `build/` 随目录删除 ⇒ 实现批运行号（如 `20261013T084428862-31912`）原物不可回查，按 spire-docs 写明「随临时 worktree 删除」；本轮全部运行号在盘。重建后首次强制导入（缺 `.godot`）把 516 个 tracked `*.import` 重写为 LF（`git diff --ignore-cr-at-eol` 为空、内容等价），按既有惯例 `git checkout -- spire-godot/assets` 还原；导入同时重建基底既有未跟踪缺口 `spire-godot/tests/batch_reuse_recorder.gd.uid`，保留在树内、不提交 ⇒ 本轮树为 `dirty=1`（突变 identity 与 `-Changed` 计划按此登记）。
- 执行口径：`GODOT_BIN` 每 shell 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；pwsh 7.6.6；单引擎串行（每轮跑前跑后 `Get-Process Godot*` 为 0）；长命令经 `pwsh -NoProfile -File` 脚本（工作树 `tmp/`，UTF-8 无 BOM）；心跳与逐轮起止 `tmp/agent-routingharden.log`；判读＝退出码或 `status`＋`SUITE RESULT` 行＋完成标记＋`summary.json` 的 `before==after`；无 `SOURCE CHANGED`。
- **本批发现与修复（根因在授权面 ⇒ 新提交＋受影响轮全部重取）**：首轮八条突变 7/8 RED，`index_matches_regeneration`（`tests/check_index.json` 的 `"schema": 1,`→`2`）虽让目标判据具名变红，却同时产生 `SCRIPT ERROR: Invalid access of index '0' on a base object of type: 'Array'`——冻结物不可读时 `suites_for` 返回空 `rows`，新判据 `index_route_examples_are_pinned` 直取 `rows[0]` 崩溃；`tools/check-mutation.ps1` 按设计把脚本错误判为「非判据 RED」，该条目无法取证。最小修复＝该判据先检 `Index.frozen_error()` 并早退（`tests/runner_cases.gd`），失败回到具名 ERROR；`tests/runner_cases.gd` 是扫描输入 ⇒ 同批 `tools/check-index.ps1 -Write` 重冻（派生体不变：`digest 8efe105c…`；`generated_from` `062ca8a2…`→`dc452ed8…`）。受影响轮（①索引面／②③判据与探针面／④计划面／⑤路由实跑／⑥兼容面／⑦突变）在 `7d7f4a3` 全部重取（runner 断言计数因守卫 +1：1731→1732、122640→122641、147720→147721）；实现批首轮（`b68eeca`）的对应运行号登记为**已被修复取代**，不再作通过口径。
- 命令清单（acceptance §4 片②；`head=7d7f4a3`，除标注外）：
  - ①索引面 `tools/check-index.ps1`（零漂移）→ 日志 `build/check-index-20261013T105003300.log`，exit 0，`CHECK INDEX PASS: frozen index equals the derivation (digest 8efe105ccfa5a587…)`；修复时的 `-Write` → 日志 `build/check-index-20261013T104918057.log`（`case_files=220`／`suite_edges=521`／`blind=3`／`inputs=353`）。
  - ②`tools/check.ps1 -Suite runner -TimeoutSeconds 900` → 运行 `20261013T105004127-54496`，exit 0，`SUITE RESULT: runner PASS`，`PASS: 1732 assertions`，docs PASS（45 规则文档／2517 引用／允许清单 3），红集＝[]、`before==after`；首轮 `20261013T092744468-36856`＝1731（已被取代）。
  - ③`tools/check.ps1 -Suite runner,architecture -TimeoutSeconds 900` → 运行 `20261013T105114250-47568`，exit 0，两分类逐行 PASS，`PASS: 122641 assertions`，`CHECK rules: 195.29s`，红集＝[]、`before==after`；首轮 `20261013T092918004-48108`＝122640（已被取代）。
  - ④`tools/check.ps1 -Suite runner -VerifyRunner -TimeoutSeconds 900` → 运行 `20261013T105436263-47568`，exit 0：既有七条 `negative-*`（ui-only-rule-scope／inactive-ui-scope／timeout／rules／ui／stop／continue）＋新增八条 `route-*`（ui-only／content／save／snapshot-domain／blind-closure／unmapped-fail-closed／declared-none／scope-matches）全部 PASS，`route-scope-matches` 证明计划＝执行；探针日志 `build/checks/20261013T105436263-47568/check-negative-*.log`／`check-route-*.log`；首轮 `20261013T093631199-51828` 同结论（已被取代）。
  - ⑤计划面（**不算通过**）`tools/check.ps1 -Changed -ListOnly` → 运行 `20261013T105013117-54496`，`status=plan`（exit 0）：变更集＝1 文件（未跟踪的 `spire-godot/tests/batch_reuse_recorder.gd.uid`）→ `ROUTE DEFAULT` 测试层闭包 `all-dev`＋`all-dev-ui`；`tools/check.ps1 -ChangedList tmp/route-list-hardening.txt -ListOnly` → 运行 `20261013T105020344-54496`，`status=plan`：7 文件逐行 `ROUTE NONE`（declared-none）／`ROUTE ROW`（`core/save_store.gd` 带 `core-append`）／`ROUTE UNMAPPED`（fail-closed）／`ROUTE DEFAULT`（`project.godot` 模块根、`tests/`、`tools/` 闭包）／`ui/main.gd` `signals=symbol_ui` 且扣除 `normal_play`。首轮 `20261013T093954621-62684`／`20261013T094004833-62684` 同结论（已被取代）。
  - ⑥兼容面 `tools/check.ps1 -Suite persistence -Impact -ListOnly` → 运行 `20261013T105027633-54496`，`status=plan`、`rules.selected=34`、`impact=true`；`tools/check.ps1 -UIOnly -UISuite home,persistence -ListOnly` → 运行 `20261013T105035978-54496`，`status=plan`、`ui.selected=2`、`UI SCOPE: home,persistence` 不展开；与片前基线 `60f7ab1` 只读钉树同命令逐字对照见 A-RT-8。
  - ⑦本片变更集实跑（A-RT-10）`tools/check.ps1 -Changed -Since 60f7ab1`：**首轮（合同字面参数 `-TimeoutSeconds 1200`，`head=b68eeca`）** → 运行 `20261013T094126090-63532`，exit 1、`status=failed`（`Godot check exceeded 1200s`：规则相位 51/51 全绿、`PASS: 147720 assertions`、`CHECK rules: 465.33s`，UI 相位 39/45 后被 1200s 上限终止），`ui.retry=prison,tower_progression,events,consumables,rewards,persistence`、`before==after`；**登记为未完成／不作通过**，并如实记录合同参数对本片变更集（tests/** 闭包 ⇒ `all-dev`＋`all-dev-ui`）的 UI 相位不足（该相位需 ≈24 分钟）；**重取轮（`-TimeoutSeconds 3600`）** → 运行 `20261013T110227096-26156`，exit 0、`status=passed`、`before==after`、规则 51/51 PASS（`147721 assertions`、`CHECK rules: 418.18s`）＋UI 45/45 PASS（`6816 assertions`、`CHECK ui: 1,425.68s`），`route.mode=changed`、`files=17`（`files_sha256=4c99d4c28052…`、`index_digest=8efe105ccfa5…`）、`declared_none=3`、`default_files=13`、`unmapped=0`、`widen=0`、`widen_candidates=0`、`defect_hits=0`、`gates=(none)`、`milestone=(none)`；该轮即 A-RT-10 的绿色证据。
  - ⑧续跑语义 `tools/check.ps1 -RerunFailed build/checks/20261013T094126090-63532 -TimeoutSeconds 900` → 运行 `20261013T113423946-14156`，exit 0：`RERUN: failed/unfinished suites only`，`UI SCOPE: prison,tower_progression,events,consumables,rewards,persistence`（恰为 ⑦首轮的失败与未完成分类），六行 `SUITE RESULT: <模块> PASS`、`UI PASS: 997 assertions`、`before==after`。**口径**：调度器删除了前批 `build/`，本轮不存在「既有多分类运行号」；以本批 ⑦首轮的宽集失败轮为续跑目标（多分类：51 规则分类＋45 界面模块），比单一分类续跑更贴近 acceptance 的「多分类」口径；错误分类的 stop／continue／retry 语义另由 ④ 的 `negative-stop`／`negative-continue` 探针在同一轮内核对。
  - ⑨文档面 `tools/check-docs.ps1` 单跑 → `DOCS PASS: 45 rule-class document(s), 2517 reference(s) checked, allowlist 3 entrie(s)`，exit 0；每轮 `check.ps1` 内的 docs 阶段同为 PASS（A-RT-12 的后半）。
- A-RT-8 兼容面逐字对照（片前基线 `60f7ab1` 只读钉树 `C:\1\tmp\magic-spire-wt-check-routing-base`，拷入导入缓存后同命令实跑；钉树已在对照后拆除）：
  - `-Suite persistence -Impact -ListOnly`：基线运行 `20261013T114048368-24216`（exit 0），HEAD 运行 `20261013T105027633-54496`；比对行（`RULE SCOPE`／`RULE SAMPLING`／`PLAN ONLY`／每个列表项）基线 38 行 vs HEAD 38 行、`Compare-Object` 差集＝0（逐字相同）。
  - `-UIOnly -UISuite home,persistence -ListOnly`：基线运行 `20261013T114056438-24216`（exit 0），HEAD 运行 `20261013T105035978-54496`；比对行（`UI SCOPE`／`PLAN ONLY`／每个列表项）5 vs 5、差集＝0。
  - `summary.json` 键面：两轮均为基线 12 键 → HEAD 13 键，**added=[route]、removed=[]**（既有键名与数量不动）。
- 突变取证（原五条＋按协调者裁定①补的三条，同一命令；`tests/mutations.json` 三条新条目＝`b68eeca` 落字，anchors 经工具 `IndexOf` 复核唯一）：
  - 首轮（`head=b68eeca`，修复前）运行目录 `build/mutations/20261013T104330145-40932`：**7/8**——`index_matches_regeneration` 判为 FAILED（`Target phase contains a source/environment/loading/runtime failure, not a judgment RED`，子轮 `20261013T104330662-52968` 有 `SCRIPT ERROR: Invalid access of index '0' …`），其余七条 RED＋逐条还原。该轮促成上述修复提交 `7d7f4a3`。
  - 正式轮（`head=7d7f4a39970ae3ffb61c316748b020d880eac923`）`tools/check-mutation.ps1 -Check index_matches_regeneration,index_skips_no_source_file,index_declared_domains_exist,index_suites_are_all_reachable,index_route_examples_are_pinned,index_covers_every_case_file,index_targets_exist,index_defects_stay_closed -TimeoutSeconds 1800` → 运行目录 `build/mutations/20261013T110036493-53204`，`RUN IDENTITY head=7d7f4a3…`、开局 `dirty=1`（未跟踪 uid）；**8/8 RED**、逐条 `restored=True`、`worktree unchanged=True`、无 `MUTATION RESIDUE`、elapsed 69.8s、exit 0：
    - `index_matches_regeneration`（`tests/check_index.json`，sha256 `370582BCF59B…`）→ 子轮 `20261013T110037009-22136`：`SUITE RESULT: runner FAIL`、`FAIL: 3/1731`；具名 ERROR＝`frozen tests/check_index.json is readable with schema 1: frozen index schema is not 1` 与 `frozen index equals the derivation; first difference: root.schema (1 vs 2.0)`（守卫 ERROR 同现，无脚本错误）。
    - `index_skips_no_source_file`（`tests/check_index_edges.gd`，`6C1DB3580808…`）→ 子轮 `20261013T110045706-31384`：`FAIL: 3/1730`；ERROR＝`spire-godot/core/tool_rules.gd is blind and carries a BLIND_BY_DESIGN reason`。
    - `index_declared_domains_exist`（`tests/check_index_edges.gd`）→ 子轮 `20261013T110054378-17284`：`FAIL: 3/1733`；ERROR＝`DOMAINS word SAVEX (spire-godot/core/snapshot.gd) is used by the corpus`。
    - `index_suites_are_all_reachable`（`tests/test_game.gd`，`F90DDB9D74CD…`）→ 子轮 `20261013T110103052-59556`：`FAIL: 6/1732`；ERROR＝`rule:mutation_probe_suite has derived edges or a documented exemption`。
    - `index_route_examples_are_pinned`（`tests/check_index.gd`，`714E679A1C9F…`）→ 子轮 `20261013T110111924-32812`：`FAIL: 39/1704`；ERROR＝`save_store rule scope is architecture,runner,persistence` 等 39 条。
    - `index_covers_every_case_file`（`tests/test_game.gd`）→ 子轮 `20261013T110120736-17152`：`FAIL: 4/1735`；ERROR＝`executable test file has a registered owner: adaptability_cases.gd／binding_enthusiast_cases.gd／card_music_cases.gd`（`card_power` 注册被置 null ⇒ 该注册根下整组用例文件失去 owner）。
    - `index_targets_exist`（`tests/check_index_edges.gd`）→ 子轮 `20261013T110129614-60084`：`FAIL: 3/1732`；ERROR＝`spire-godot/core/mutation_probe_ghost.gd`（DOMAINS 幻影路径进派生主表）。
    - `index_defects_stay_closed`（`tests/check_index_edges.gd`）→ 子轮 `20261013T110138265-48512`：`FAIL: 3/1732`；ERROR＝`every INDEX_DEFECTS entry still carries its added edge or domain`（`added` 为空的缺陷条目 ⇒ 空表不再恒真）。
  - 归档：整轮 `tmp/routingharden-mutation-r2.log`（含每条子轮 stdout／stderr）＋逐条切片 `tmp/routingharden-mutation-<条目名>.log`；子轮原始日志 `spire-godot/build/checks/<子运行号>/`、突变身份 `spire-godot/build/mutations/20261013T110036493-53204/identity.txt`（gitignored）。
- 裁定落点（本批执行口径）：
  - **裁定①（三条判据缺突变证据）**：三条条目全文见 `tests/mutations.json`（`b68eeca`）：`index_covers_every_case_file`＝`tests/test_game.gd` 的 `"card_power":"res://tests/card_power_cases.gd",`→`"card_power":null,`（owner 注册面；该判据只读派生面与注册表，`check_index_edges.gd` 与冻结物都喂不到它，故锚在注册表本体）；`index_targets_exist`＝`check_index_edges.gd::DOMAINS` 增补 `spire-godot/core/mutation_probe_ghost.gd` 幻影路径（既有 `snapshot.gd` 锚唯一，`count=1`）；`index_defects_stay_closed`＝`INDEX_DEFECTS` 表增补 `added:""` 条目。三条均实测 RED＋逐字节还原（见上），无降级、无删除。
  - **裁定②（邻接表判据未建）**：`docs/spec/check-routing-dependencies.md` 末尾新增「仍靠人审（无机械判据，本批保留）」节，逐条登记：允许／禁止边列表（片②允许面不含 `tests/architecture_cases.gd`，未落机械判据；分项现状＝`production_source_never_preloads_tests`、指纹与零漂移比对已覆盖的两条、其余无断言）、路由窄度（`ROUTE *` 与 `-Suite <区域> -Impact` 对照，A-RT-11 的审查面）、declared-none 两份文本的同步义务、手写层条目存活（`WIDEN`／`EXCLUDE`／`CLOSURE`／`ORACLE_NOTES`／`SUITE_EXEMPT` 无存在性判据）。
  - **裁定③（declared-none-only 变更集）**：本批**不改行为**；登记为 `check.ps1` 行为独立审查必查项——纯 declared-none 变更集（如只改 docs）真跑 `-Changed` 时 `$Suite=[]` ⇒ `$UIOnly=true`、`$UISuite=[]`，UI 阶段仍被 `($UI -or $UIOnly)` 触发并以空 `--ui-suite=` 起 `tests/ui_smoke.gd`，`_run` 对空选择强制 `check(false,"Unknown or empty UI check suite")` → `UI FAIL`、exit 1（fail-closed、非假绿，但失败信息与路由无关）。本批未实跑该形态（清洁者结论为代码阅读面）。
  - **裁定④（里程碑裁定＝不跑全量）**：`-Suite all -UI -UISuite all` 本批**未跑、不作通过**；理由＝片②产品代码零改动（硬非目标，A-RT-12 判据钉住），本片套件证据＝②③（runner／runner,architecture）＋⑦（路由实跑覆盖 51 规则分类＋45 界面模块）＋④（`-VerifyRunner` 7＋8 探针）＋兼容面逐字对照；路由结果**不代替**里程碑通过，发版／打包前仍须全量。
- 判据→证据映射（acceptance §3）：A-RT-1＝①＋突变 `index_matches_regeneration` RED（schema 不符＋首差 `root.schema`）；A-RT-2＝②③（五条覆盖与存在性判据随 runner 全绿）＋突变 `index_skips_no_source_file`／`index_declared_domains_exist`／`index_targets_exist`／`index_covers_every_case_file` RED；A-RT-3＝突变 `index_defects_stay_closed` RED（空表判据不再空转）；A-RT-4／5＝②③ 的正反例判据全绿＋⑤⑥ 逐行 `ROUTE`（正例 `save_store` 带 `core-append`、反例 `ui/main.gd` 规则侧仅 `architecture`、内容包闭包＋内容门、未映射 fail-closed）＋突变 `index_route_examples_are_pinned` RED；A-RT-6＝⑤⑥⑦ 每次打印 `ROUTE MILESTONE`、路由结果不含 `normal_play`／`baseline`（⑦两轮 `milestone=(none)`／扣除行）＋④ 的互斥与探针面；A-RT-7＝④ `route-scope-matches`（计划＝执行）＋⑦ `route.rules/ui` 与执行 `rules/ui.selected` 在 `summary.json` 内相等；A-RT-8＝⑧（`-RerunFailed` 续跑仅失败/未完成分类）＋上述基线逐字对照（输出差集 0；`summary.json` 键面 12→13、只增 `route`）＋⑦ 的 `status`／`source_changed` 语义（两轮均无 `SOURCE CHANGED`）；A-RT-9＝④ 全部探针 PASS（探针日志落盘）＋**突变×`-VerifyRunner` 敏感性轮**：临时应用 `index_route_examples_are_pinned` 的锚（`tests/check_index.gd` 的 `CORE_APPEND` 清空；sha256 前/后同为 `714E679A1C9FD57CBCDAA179445B763E40689293AAD68B26C262DAD8D23E5D67`），以 `-UIOnly -UISuite home -VerifyRunner -TimeoutSeconds 900` 实跑（首试 `-Suite runner -VerifyRunner` 会因规则相位先红而中止、探针未跑，故把规则相位换成只跑 home 的界面相位）→ 运行 `20261013T114400473-58504`：七条 `negative-*` 与 `route-ui-only`／`route-content` PASS，`route-save` 具名变红（`Route probe missed an expected plan line: route-save / (?m)^ROUTE CORE APPEND: …`）、exit 1；还原后 sha256 逐字节相同、`git status` 无残留（归档 `tmp/routingharden-mutation-verifyrunner.log`）；A-RT-10＝⑦；A-RT-11＝⑤⑥ 的逐行对照＋依赖表「仍靠人审」节（人审面）；A-RT-12＝本批 `git diff --stat 60f7ab1..7d7f4a3 -- spire-godot/core spire-godot/data spire-godot/ui spire-godot/content spire-godot/assets` 为空、两份新文档过 ⑨。
- 四态：**已测**＝①零漂移（`-Write`＋`-verify`）②③④⑤⑥⑦（两轮）⑧⑨＋突变正式轮 8/8 RED＋A-RT-9 突变×`-VerifyRunner` 敏感性轮＋A-RT-8 基线逐字对照（运行号与归档如上）；**失败**＝⑦首轮 `20261013T094126090-63532`（UI 相位超 1200s，归属＝合同参数／宽集规模，非产品与判据缺陷；已重取 3600 轮）与首轮突变 7/8（归属＝片内判据守卫缺陷，已由 `7d7f4a3` 修复并重取）；**未跑**＝安卓真机、打包与发布、`-Suite all -UI -UISuite all` 里程碑（协调者裁定④）、`check.ps1` 行为独立审查（协调者另派，含裁定③登记项）、验收者一轮（协调者另派）、独立审查（协调者另派新会话）；**被跳过**＝无；**假设**＝无。清洁者交回项 (a)（邻接表判据）落字于裁定②、(b)（三条判据突变证据）落于裁定①、(c)（declared-none-only 失败形态）落于裁定③、(d)（正式门禁全套与独立审查）按裁定④与四态登记。
- 本节只追加本文件一个文件、单独提交（docs-only）；全部提交仅在本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-13｜片②（检查路由）干净树补证批：基底 uid 缺口修复＋全部证据在干净 head 重取（上一批 dirty=1 全轮作废）

- 域：`spire-godot/tests/{batch_reuse_recorder.gd.uid,check_index.gd,check_index_edges.gd,check_index.json,route_plan.gd,runner_cases.gd,test_game.gd,mutations.json}`、`spire-godot/tools/{build_check_index.gd,check-index.ps1,check.ps1}` 的路由面、`docs/spec/check-routing.md`／`check-routing-dependencies.md`；本节只追加本文件。合同＝`C:\1\tmp\check-routing-plan\acceptance.md` §4 片②清单＋§1/§3/§6（每条结论写明命令／运行号／退出码或 `status`／断言计数／红集／`before==after`；四态同用）。上一批（记录 `42bce72`、判据证据面 `7d7f4a3`，见上节）的全部运行都在 `dirty=1` 下取得、无干净提交与之对应，按操作卡「dirty≠0 该轮不作证据」本批整批作废并在干净 head 重取；作废保留（运行号见「作废清单」节），不再作通过口径。
- 基底缺口修复＝`dd8d75b`：`chore(tests): track the recorder uid missed by the D batch`（`spire-godot/tests/batch_reuse_recorder.gd.uid`，内容 `uid://d0wv7n1avtvxp`，1 文件 +1）。判定依据：该文件与仓内既有 tracked `*.uid` 同类（`git ls-files '*.uid'`＝367 条、其中 `spire-godot/tests/*.uid`＝233 条），路径不被忽略（`git check-ignore` 无命中）；其对应源文件 `spire-godot/tests/batch_reuse_recorder.gd` 已跟踪。提交后 `git status --short` 为 0 行 ⇒ 本批所有运行在 `dirty=0` 下取得。
- 本批判据证据绑定 `head=dd8d75beb7f70246af861713731e6b84c06e4054`；`-Changed -Since 60f7ab1` 的变更集因此由 17 文件变为 18 文件（新增该 uid）。记录提交在证据之后（docs-only，不改判据证据所绑定的字节）。
- 执行口径：与上一批同形——工作树 `C:\1\tmp\magic-spire-wt-check-routing`、枝 `worker/check-routing`；`GODOT_BIN` 每 shell 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；pwsh 7.6.6；单引擎串行（每轮跑前跑后 `Get-Process Godot*` 为 0，运行中仅 console＋子进程各 1）；长命令经 `pwsh -NoProfile -File`（脚本 `tmp/rr-*.ps1`，UTF-8 无 BOM）；心跳与逐轮起止 `tmp/agent-routingre-evidence.log`；判读＝退出码或 `status`＋`SUITE RESULT` 行＋完成标记＋`summary.json` 的 `before==after`；全程无 `SOURCE CHANGED`。

### 作废清单（上一批在 `dirty=1` 下取得；逐轮具名，作废保留）

- 索引面①：`-verify` 日志 `build/check-index-20261013T105003300.log`、重冻 `-Write` 日志 `build/check-index-20261013T104918057.log`。
- 判据面②③④：`20261013T105004127-54496`（runner 1732）／`20261013T105114250-47568`（runner,architecture 122641）／`20261013T105436263-47568`（`-VerifyRunner`）。
- 计划面⑤：`20261013T105013117-54496`（`-Changed -ListOnly`，当时变更集＝未跟踪 uid 1 文件）／`20261013T105020344-54496`（`-ChangedList … -ListOnly`，7 文件）。
- 兼容面⑥：`20261013T105027633-54496`／`20261013T105035978-54496`；父提交逐字对照的基线钉树两轮 `20261013T114048368-24216`／`20261013T114056438-24216` 连同该对照一并作废（钉树 `C:\1\tmp\magic-spire-wt-check-routing-base` 已被外部清理，不再存在）。
- 实跑⑦及其续跑⑧：`20261013T110227096-26156`（3600s 宽集轮，17 文件）／`20261013T113423946-14156`（`-RerunFailed`）；合同字面参数的未完成轮 `20261013T094126090-63532`（1200s 超时）同时在列。
- 突变正式轮：`build/mutations/20261013T110036493-53204`（8/8 RED，identity 开局 `dirty=1`）；首轮 `build/mutations/20261013T104330145-40932`（7/8）。
- A-RT-9 敏感性轮：`20261013T114400473-58504`（`CORE_APPEND` 清空 × `-UIOnly -UISuite home -VerifyRunner`）。
- 文档⑨：`tools/check-docs.ps1` 单跑（日志 `tmp/routingharden-9-docs.log`）。
- 首轮（`b68eeca`，上一批已标「被 `7d7f4a3` 取代」者）：`20261013T092744468-36856`／`20261013T092918004-48108`／`20261013T093631199-51828`／`20261013T093954621-62684`／`20261013T094004833-62684`。
- 统一作废理由＝运行时工作树含基底遗留未跟踪 `spire-godot/tests/batch_reuse_recorder.gd.uid`（`dirty=1`）；该缺口已由 `dd8d75b` 收口，故上一批各轮即便重跑也不再复现同一状态。

### 干净 head 重取（acceptance §4 片②清单；`head=dd8d75b`、全程 `dirty=0`）

- ①索引面 `tools/check-index.ps1`（零漂移，exit 0）：`CHECK INDEX PASS: frozen index equals the derivation (digest 8efe105ccfa5a587d94e4a013593653e03b4587f684d837eab37d14cc0bbf316)`；日志 `build/check-index-20261013T115256851.log`。**未跑 `-Write`**：新增的 tracked uid 不是索引派生输入（零漂移一次成立、摘要与上一批相同 `8efe105c…`），故无重冻、无二次冻结面。
- ②`tools/check.ps1 -Suite runner -TimeoutSeconds 900` → 运行 `20261013T115316039-64124`，exit 0，`SUITE RESULT: runner PASS`，`PASS: 1732 assertions`，`CHECK rules: 1.72s`，红集＝[]、`unrun=[]`、`before==after`＝`BC13EBF246A5566367690FF5983FCD18707C06BC199F0BCDE09F8689B0410F97`；随轮 docs PASS（45 规则文档／2517 引用／允许清单 3）；`summary.json` 13 键（`route` 键在场）。
- ③`tools/check.ps1 -Suite runner,architecture -TimeoutSeconds 900` → 运行 `20261013T115325404-15832`，exit 0，两分类逐行 PASS，`PASS: 122641 assertions`，`CHECK rules: 196.02s`，红集＝[]、`before==after`（同上指纹）。
- ④`tools/check.ps1 -Suite runner -VerifyRunner -TimeoutSeconds 900` → 运行 `20261013T115649166-8836`，exit 0：`runner PASS`／`PASS: 1732 assertions`；既有七条 `negative-*`（`ui-only-rule-scope`／`inactive-ui-scope`／`timeout`／`rules`／`ui`／`stop`／`continue`）＋新增八条 `route-*`（`ui-only`／`content`／`save`／`snapshot-domain`／`blind-closure`／`unmapped-fail-closed`／`declared-none`／`scope-matches`）全部 `CHECK … verified`，其中 `route-scope-matches: the planned scope equals the executed scope` 证明计划＝执行；探针日志 `build/checks/20261013T115649166-8836/` 下 `check-negative-*.log`×7 与 `check-route-*.log`×8（route 面另存 `probe-route-*.txt`×8）。
- ⑤计划面（**不算通过**；A-RT-4/5/6/11 的行面）：
  - `tools/check.ps1 -Changed -ListOnly`：干净树上默认基线为 HEAD ⇒ 变更集为空，被 `tools/check.ps1:95` 的 `The change set is empty; committed changes need -Changed -Since <ref> (default base is HEAD).` 拒绝（exit 1、**起引擎前**拒绝、无 `build/checks/` 运行目录）。这正是 acceptance §5-2 要求的「空清单被拒一次」形态（fail-closed，非假绿）；归档 `tmp/rr-05a-changed-listonly.log`。与上一批不同处如实登记：上一批该命令输出的是「未跟踪 uid 1 文件」的 `ROUTE DEFAULT`，该 uid 现已入册，其等价行改由 ⑦ 的 18 文件实跑与 ⑤b 的画面呈现。
  - `tools/check.ps1 -ChangedList tmp/route-list-hardening.txt -ListOnly` → 运行 `20261013T123406627-27956`，exit 0、`status=plan`：`ROUTE FILES: 7`（`files_sha256=1271dd9b9ca8…`、`index_digest=8efe105ccfa5…`）；逐行 = `ROUTE NONE`（`docs/spec/check-routing-dependencies.md`，declared-none）／`ROUTE ROW: spire-godot/core/save_store.gd -> rules=architecture,persistence,runner ui=… [signals=preload,core-append]` 与 `ROUTE CORE APPEND: spire-godot/core/save_store.gd += architecture,persistence,runner`／`ROUTE UNMAPPED: spire-godot/newdir/x.gd`（fail-closed 到 all-dev＋all-dev-ui）／`ROUTE DEFAULT`×3（`project.godot` 模块根闭包、`tests/check_index_edges.gd` tests 闭包、`tools/check.ps1` tools 闭包）／`ROUTE ROW: spire-godot/ui/main.gd -> rules=architecture ui=… [signals=symbol_ui]`；`ROUTE MILESTONE` 扣除 `normal_play`；`PLAN ONLY: no game tests executed`。
- ⑥兼容面（A-RT-8；均 `status=plan`、exit 0）：`tools/check.ps1 -Suite persistence -Impact -ListOnly` → 运行 `20261013T115841079-60588`（`impact=true`、`RULE SCOPE` 34 项、`PLAN ONLY`）；`tools/check.ps1 -UIOnly -UISuite home,persistence -ListOnly` → 运行 `20261013T115848880-60588`（`UI SCOPE: home,persistence`、2 项、`PLAN ONLY`、`ui.selected=2`、不展开）。
- ⑦本片变更集实跑（A-RT-10）`tools/check.ps1 -Changed -Since 60f7ab1 -TimeoutSeconds 3600` → 运行 `20261013T115858886-56260`，exit 0、`status=passed`、`before==after`：`ROUTE MODE: changed`、`ROUTE FILES: 18`（`files_sha256=f202077fb92b9110c322b268481c811ff07bd14798beee5ade4504c51f9481ac`、`index_digest=8efe105ccfa5…`）、`declared_none=4`（两片新文档＋`repo-ops` skill＋本记录）、`default_files=13`（含新入册的 `spire-godot/tests/batch_reuse_recorder.gd.uid` → tests 闭包）、`unmapped=[]`、`widen=[]`、`widen_candidates=[]`、`defect_hits=[]`、`gates=[]`、`milestone=[]`；规则 51/51 逐行 PASS＋`PASS: 147721 assertions`（`CHECK rules: 425.79s`），界面 45/45 逐行 PASS＋`UI PASS: 6816 assertions`（`CHECK ui: 1,427.80s`），docs PASS（45／2517／3）。**`-TimeoutSeconds` 用 3600 的理由（在记录注明）**：合同字面 1200 对本变更集（`tests/**` 闭包 ⇒ `all-dev`＋`all-dev-ui`，界面相位需 ≈24 分钟）必超时，上一批已实测（1200 轮登记为未完成）；本批不再制造该未完成轮。
- ⑧续跑语义 `tools/check.ps1 -RerunFailed build/checks/<运行号>`：**本批未跑**（见四态；理由＝本批唯一的宽集轮 ⑦ 为 `passed`，工具按设计拒绝 `status=passed` 的上轮结果，干净树上无失败／未完成的多分类轮可作目标）。
- 突变取证（A-RT-1/2/3/4 的机械口径；判读＝目标判据具名 ERROR＋逐字节还原＋identity `dirty=0`＋无 `MUTATION RESIDUE`＋外层 exit 0）：
  - 命令 `tools/check-mutation.ps1 -Check index_matches_regeneration,index_skips_no_source_file,index_declared_domains_exist,index_suites_are_all_reachable,index_route_examples_are_pinned,index_covers_every_case_file,index_targets_exist,index_defects_stay_closed -TimeoutSeconds 1800` → 运行目录 `build/mutations/20261013T123414421-49476`；identity 文件＝`head=dd8d75b…`、`started=2026-10-13T23:34:14+11:00`、`dirty=0`；**8/8 RED**（逐条 `exit-red=True restored=True`）＋`MUTATION SUMMARY: 8/8 entr(ies) reddened the named check and restored byte-for-byte; worktree unchanged=True (pre-dirty=0); elapsed 74.1s`；无 `MUTATION RESIDUE`（对运行目录 `grep -ri RESIDUE` 无命中）；exit 0。
  - 逐条（子轮 FAIL 行读自该子轮 `check-rules.log`；具名 ERROR 抽验与条目语义一致）：`index_matches_regeneration`（`tests/check_index.json` schema 1→2，sha256 `370582BCF59B…`）→ 子轮 `20261013T123414941-12544`：`FAIL: 3/1711`，ERROR＝`frozen tests/check_index.json is readable with schema 1`／`first difference: root.schema (1 vs 2.0)`／`index_route_examples_are_pinned: the frozen index is readable before …`；`index_skips_no_source_file`（`tests/check_index_edges.gd`，`6C1DB3580808…`）→ `20261013T123423946-50392`：`FAIL: 3/1731`；`index_declared_domains_exist`（同文件）→ `20261013T123433260-63264`：`FAIL: 3/1730`；`index_suites_are_all_reachable`（`tests/test_game.gd`，`F90DDB9D74CD…`）→ `20261013T123442522-39956`：`FAIL: 3/1733`；`index_route_examples_are_pinned`（`tests/check_index.gd` `CORE_APPEND` 清空，`714E679A1C9F…`）→ `20261013T123451881-46340`：`FAIL: 6/1732`，ERROR＝`save_store rule scope is architecture,runner,persistence`／`the plan prints the core append line for save_store`／`the SAVE domain resolves the blind snapshot file`／`the IRON domain resolves core/iron_man.gd`（＋ `index_matches_regeneration` 的 `generated_from` 首差与 `index_regeneration_is_the_only_writer` 级联）；`index_covers_every_case_file`（`tests/test_game.gd` `card_power` 注册置 null）→ `20261013T123501443-63328`：`FAIL: 39/1704`，ERROR＝`executable test file has a registered owner: adaptability_cases.gd／binding_enthusiast_cases.gd／card_music_cases.gd／card_power_cases.gd／card_text_cases.gd …`；`index_targets_exist`（`tests/check_index_edges.gd` 幻影 `spire-godot/core/mutation_probe_ghost.gd`）→ `20261013T123510558-59588`：`FAIL: 4/1735`，ERROR＝`index_targets_exist: spire-godot/core/mutation_probe_ghost.gd`（＋ `missing on right` 首差与 `index_regeneration_is_the_only_writer`）；`index_defects_stay_closed`（`INDEX_DEFECTS` 增补 `added:""`）→ `20261013T123519884-44052`：`FAIL: 3/1732`。
  - 归档：`tmp/routingre-mutation.log`（本轮汇总，逐条含子轮目录与 ERROR 摘录）＋原始 `tmp/rr-07-mutation.log`；子轮日志 `spire-godot/build/checks/<子运行号>/`、identity `spire-godot/build/mutations/20261013T123414421-49476/identity.txt`（均在 gitignored 面内、在盘）。**注**：上一批记录里的逐条计数（3/1731、3/1730、3/1733、6/1732、39/1704、4/1735、3/1732、3/1732）与本批实测（上列）在个别条目上不同；本批一律以本轮工具自印的「条目名↔子轮目录」配对与其子轮日志为准，不复用上一批数字（上一批该轮已作废）。
- A-RT-9 敏感性轮（新增探针的敏感性＝同一突变在 `-VerifyRunner` 下打红）：临时清空 `tests/check_index.gd::CORE_APPEND`（锚 `const CORE_APPEND=["architecture","persistence","runner"]`，全树 count＝1；改写前 sha256 `714E679A1C9FD57CBCDAA179445B763E40689293AAD68B26C262DAD8D23E5D67`，备份 `tmp/rr-08-verifyrunner-sensitivity.backup`），以 `tools/check.ps1 -UIOnly -UISuite home -VerifyRunner -TimeoutSeconds 900` 实跑 → 运行 `20261013T123529428-58616`：界面 `SUITE RESULT: home PASS`＋`UI PASS: 140 assertions`；七条 `negative-*` 与 `route-ui-only`／`route-content` PASS；**`route-save` 具名变红**（`Route probe missed an expected plan line: route-save / (?m)^ROUTE CORE APPEND: spire-godot/core/save_store\.gd \+= architecture,persistence,runner`）；exit 1（红＝敏感性成立）。**该轮运行中工作树带 1 处临时改写（ 属故意突变，非基底缺口；本轮 wrapper 的身份行即记录此态）**；还原后 sha256 逐字节相同（`714E679A1C9F…`＝改写前）、`git status --porcelain` 0 行、`dirty=0`；归档 `tmp/rr-08-verifyrunner-sensitivity.log`，探针日志 `build/checks/20261013T123529428-58616/check-route-save.log`。
- ⑨文档面 `tools/check-docs.ps1` 单跑 → `DOCS PASS: 45 rule-class document(s), 2517 reference(s) checked, allowlist 3 entrie(s)`，exit 0（A-RT-12 后半）；A-RT-12 前半实跑：`git diff --stat 60f7ab1..dd8d75b -- spire-godot/core spire-godot/data spire-godot/ui spire-godot/content spire-godot/assets` 输出为空（产品代码零改动），全片差异＝18 文件 `+5070/−6`（全在 `tests/`／`tools/`／`docs/`／`.zcode/skills/` 面）。
- A-RT-8 兼容面逐字对照（**补取**：acceptance §5-4-6 的口径；同一两命令在父提交 `60f7ab1` 的只读钉树上实跑后比对，钉树用后即拆）：钉树 `C:\1\tmp\magic-spire-wt-routingre-base`（`git worktree add --detach … 60f7ab1`，拷入导入缓存）→ 基线 `-Suite persistence -Impact -ListOnly` 运行 `20261013T123656154-29216`、基线 `-UIOnly -UISuite home,persistence -ListOnly` 运行 `20261013T123704591-29216`，均 exit 0；与 ⑥ 的本轮运行比对：比对行（`RULE SCOPE`／`RULE SAMPLING`／`UI SCOPE`／`PLAN ONLY`／每个列表项／`DOCS RESULT`）分别 38 vs 38 与 5 vs 5，`Compare-Object` 差集＝**0**（逐字相同）；`summary.json` 键面 12→13，**added=[route]、removed=[]**。归档 `tmp/rr-11a-base-persistence-impact-listonly.log`／`tmp/rr-11b-base-uionly-home-persistence-listonly.log` 与比对输出。
- 判据→证据映射（acceptance §3）：A-RT-1＝①零漂移（摘要不变）＋突变 `index_matches_regeneration` RED（schema 守卫＋首差 `root.schema`）；A-RT-2＝②③ 五条覆盖与存在性判据全绿＋突变 `index_skips_no_source_file`／`index_declared_domains_exist`／`index_targets_exist`／`index_covers_every_case_file` RED；A-RT-3＝突变 `index_defects_stay_closed` RED；A-RT-4／5＝②③ 正反例全绿＋⑤b 的行面（`save_store` 含 `core-append`、`newdir/x.gd` fail-closed、模块根与 tests／tools 闭包、`ui/main.gd` 规则侧仅 `architecture`）＋突变 `index_route_examples_are_pinned` RED；A-RT-6＝⑤b⑥⑦ 每次打印 `ROUTE MILESTONE`、路由结果不含 `normal_play`／`baseline`（⑦ `milestone=[]`、扣除行）＋④ 互斥与探针面；A-RT-7＝④ `route-scope-matches`（计划＝执行）＋⑦ `route.rules/ui` 与执行 `rules/ui.selected` 在 `summary.json` 内相等（51／45）；A-RT-8＝⑥＋逐字对照（差集 0、键面只增 `route`）＋⑦ `status`／`source_changed` 语义（无 `SOURCE CHANGED`）；A-RT-9＝④ 全部探针 PASS＋上述突变×`-VerifyRunner` 轮（`route-save` 红、逐字节还原）；A-RT-10＝⑦；A-RT-11＝⑤b⑥ 逐行＋依赖表「仍靠人审」节（人审面）；A-RT-12＝本批 `git diff --stat` 为空＋⑨。

### 四态

- **已测**＝①零漂移（摘要 `8efe105c…`，无重冻）②③④⑤b⑥⑦⑨＋突变正式轮 8/8 RED（`build/mutations/20261013T123414421-49476`，identity `head=dd8d75b`、`dirty=0`、无 RESIDUE）＋A-RT-9 敏感性轮（`20261013T123529428-58616`，`route-save` 红、逐字节还原）＋A-RT-8 父提交逐字对照（差集 0、键面 12→13 只增 `route`）＋⑤a 空清单 fail-closed 拒绝。全部运行号、归档与 `before==after` 指纹如上（本轮公共指纹 `BC13EBF246A5566367690FF5983FCD18707C06BC199F0BCDE09F8689B0410F97`）。
- **失败**＝无（本批所有命令按预期判定：⑤a 的空清单拒绝为设计内 fail-closed；突变轮 8/8 RED 为目标结果；A-RT-9 轮的 exit 1 为敏感性成立；无未完成轮、无 `SOURCE CHANGED`）。
- **未跑**＝⑧`-RerunFailed` 续跑语义（本批无失败／未完成的多分类轮可作目标，`status=passed` 上轮被工具拒绝；如需取证须另造一轮失败宽集 ≈20 分钟，待协调者裁定）；`-Suite all -UI -UISuite all` 里程碑（沿用上一批协调者裁定④：片②产品代码零改动，路由结果不代替里程碑通过；发版／打包前仍须全量）；安卓真机、打包与发布（待点名）；`check.ps1` 行为独立审查、验收者一轮、独立审查（协调者另派新会话）。
- **被跳过**＝无。**假设**＝无。
- 补记：上一批「实现批运行号原物随临时 worktree 删除、不可回查」的状态不变（本批不复查那些运行号）；本批全部运行号、探针日志与突变子轮目录在盘，关键结论同时落本节与 `tmp/routingre-mutation.log`（`C:\1\tmp` 有被外部清理的历史，运行号与结论以本节正文为准）。
- 本节只追加本文件一个文件、单独提交（docs-only）；全部提交仅在本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。

### 片②验收一轮登记（2026-10-14，验收者；协调者落账）＋本刀闭合

- 域：本节；对象 `60f7ab1..7a58edd`（产品面零改动；工具/索引面 `bdc8009` 系）。**判定＝验收通过（未满足条目＝无）**。
- 验收者自跑证据（自有运行号，均在盘）：索引零漂移（日志 `build/check-index-20261013T125456289.log`，`CHECK INDEX PASS digest 8efe105c…`；等价只读驱动二次派生逐字节相同）；`-Suite runner`＝`20261013T125457060-48312`（1732 断言，红集 []，before==after）；`-Suite runner,architecture`＝`20261013T130718480-48328`（122641）；`-Suite runner -VerifyRunner`＝`20261013T125526066-50136`（7 `negative-*`＋8 `route-*` 全 PASS）；**八条突变**＝`build/mutations/20261013T125718000-19656`（identity `head=7a58edd dirty=0`，8/8 RED＋逐字节还原，无 RESIDUE）；**⑧ `-RerunFailed`（协调者裁定并入本轮）**＝`20261013T125839018-2720`（对既有 1200s 超时轮 `20261013T094126090-63532`，UI SCOPE 恰 6 个失败/未完成分类，`UI PASS: 997`，exit 0）；**A-RT-8 默认形逐字对照**＝HEAD `20261013T130609934-48508`/`130619159`、BASE（`60f7ab1` 只读钉树）`20261013T130629297`/`130641023`，`Compare-Object` 差集 0，summary 键面 12→13（added=[route]）；拒绝面 12/12 起引擎前拒绝；ui-only 清单真跑＝`20261013T131133488-53512`（`ROUTE UI SCOPE: events`）。
- 三条（及验收者 R2/R5/R6）存疑处置：①⑧ 裁定＝并入本轮，**已执行**（上段运行号）；②空 `--ui-suite=` 显式拒绝建议与③无 `static func run(` 用例文件的静默面，连同 R2 合同正文同步、R5 不可读目标文案、R6 人审面＝**登记为 follow-up**，见 `docs/record/proposals/check-routing-followups.md`（本批同提交落盘）。
- 本刀（避免全量检查：片①每点击检查收口＋片②检查路由）**两片全链闭合**：片① `60f7ab1`、片② `7a58edd`（各自实现→清洁→加固→独立审查 PASS→验收通过）；产品代码零改动面由片②判据钉住；未跑＝全量里程碑（片②裁定④）、安卓真机、打包发布；未推送。

## 2026-10-14｜P5（状态字段读者声明）加固批：合同命令清单、三条突变 RED、裁定 A 落字与裁定 B 登记

- 域：`spire-godot/tests/{architecture_cases.gd,state_reader_scan.gd,state_readers.json,mutations.json,check_index.json}`、`spire-godot/tools/build_state_readers.gd`、`docs/spec/state-readers.md`／`state-readers-dependencies.md`；本节只追加本文件。合同＝`C:\1\tmp\state-readers-plan\acceptance.md`（C-SR-1..10＋§3 命令清单＋§4 验收流程＋§5 四态）与同目录 `gherkin.md`（G-SR-1..8）；清洁报告＝工作树 `tmp/srclean-report.md`。每条结论写明命令／运行号／退出码或 `status`／断言计数／红集／`before==after`。
- 提交：切片链 `b887d28` →`54d777d`（实现 `feat(tests): declare the state-field readers and pin them bidirectionally`）→`8301818`（清洁：读形态收口＋死分支删除）→`5f53ce1`（本批加固：裁定 A 落字＋`tests/check_index.json` 同批重冻）。本节单独提交（docs-only）。**仅本地 `.git`，未推送、未 tag、未改版本号、未开 PR、未打包。**
- 执行口径：工作树 `C:\1\tmp\magic-spire-wt-state-readers`、枝 `worker/state-readers`（`wt-check-routing` 未触碰）；`GODOT_BIN` 每 shell 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；pwsh 7；单引擎串行（每轮跑前跑后 `Get-Process Godot*` 为 0）；长命令经 `pwsh -NoProfile -File`（脚本 `tmp/srharden-*.ps1`，UTF-8 无 BOM）；心跳 `tmp/agent-srharden.log`；判读＝退出码或 `status`＋`SUITE RESULT` 行＋完成标记＋`summary.json` 的 `before==after`；全程无 `SOURCE CHANGED`；本批全部运行在 `head=5f53ce1`、`dirty=0` 下取得（突变 identity 逐轮同上；记录提交在证据之后，不改判据证据所绑定的字节）。
- **裁定 A 落点（恒真半边，本批执行，属加固面）**：`tests/architecture_cases.gd::state_read_scan_reaches_every_source` 覆盖断言前新增 6 行注释、断言消息改为「…(a field nobody reads must be declared unread; the missing= half is structurally always empty and is NOT a bidirectional guard -- that guard is state_read_sites_are_pinned + state_read_registrations_are_pinned)…」；判据行为不变（仍断言 `missing.is_empty() and extra.is_empty()`）。理由：`unread_fields`＝登记表 −（直读∪别名∪模式串），`covered ⊇ registry` 由构造保证；双向保护由 `state_read_sites_are_pinned`（派生＝冻结，表外／缺读两侧）与 `state_read_registrations_are_pinned`（三表双向）承担，`extra=` 半边经 `schema_strings`（唯一不按登记表过滤的面）保留牙口。因 `tests/architecture_cases.gd` 是索引派生输入文本，`tests/check_index.json` 同批 `-Write` 重冻（派生体不变：`digest 8efe105c…`；`generated_from` `5c05e9bc…`→`fe6ebfae…`；`case_files 220`／`suite_edges 521`／`blind 3`／`inputs 353` 与片②基线同值），与 `5f53ce1` 同提交。
- **裁定 B 落点（扫描原语不合并，接受、无需再动）**：允许面理由已在 `docs/spec/state-readers-dependencies.md`「依赖方向」→「扫描原语边界」段写明（`tools/build_state_readers.gd` 须独立 headless 加载本模块、反向引用成环、第三共享文件超允许文件面）；本批②轮实跑与之一致（`--verify` 经该独立通路成功）。
- **裁定③（别名／模式串半边并入既有条目）**：C-SR-5／6 的别名侧与模式串侧无专条突变，按协调者裁定并入 `state_read_registrations_are_pinned` 的既有条目——该判据对 `aliases`／`schema_strings` 以 canonical 全等断言双向（多写／少写都红），本批实跑该条 RED（见下）；三条全部打红，无需最小修复复证，无新提交。
- 命令清单（acceptance §3；`head=5f53ce1`、`dirty=0`）：
  - ①索引面 `tools/check-index.ps1`（verify）→ 日志 `build/check-index-20261013T155257163.log`，exit 0，`CHECK INDEX PASS: frozen index equals the derivation (digest 8efe105ccfa5a587d94e4a013593653e03b4587f684d837eab37d14cc0bbf316)`；重冻轮 `-Write` → 日志 `build/check-index-20261013T155210917.log`。
  - ②冻结物 `tools/build_state_readers.gd --verify`（headless）→ exit 0，`STATE READERS PASS: frozen table equals the derivation (sha256 a4048167914a2fb4fbb17321b4d40135e46e105ffa38883e30c0701ef7617db6)`；打印 `STATE READERS files=129 fields=121 cells=1264 sites=2075 whole_state=52 ui_reads=0`、`unknown=0`、unread=2（`dexterity`／`strength`）、别名 6 函数 81 字段、模式串 4 函数 15 字段、`STATE FAILURE FACE fields=117 cells=878 kinds=39 sites=1387`＋逐 kind 行；与实现者／清洁者报告的基线对照值全部相符（未触 `core|ui|data` ⇒ 冻结物与清洁批零字节差，`inputs_sha256=504e0a54…`）。
  - ③判据面 C-SR-1..7 `tools/check.ps1 -Suite architecture -TimeoutSeconds 900` → 运行 `20261013T155259991-53924`，exit 0，`SUITE RESULT: architecture PASS`，`PASS: 120919 assertions`，红集＝[]、`before==after`＝`B54D69B0B01E8C9BDBAC763F36241F6B4A9B25485A15B358DFDD626CACDD13DC`，docs 阶段 PASS（47 规则文档／2723 引用／3）；清洁批同数（120919）⇒ 裁定 A 不动断言面。
  - ④C-SR-9 `tools/check.ps1 -Suite architecture,runner -TimeoutSeconds 900` → 运行 `20261013T155630982-53924`，exit 0，两分类逐行 PASS，`PASS: 122651 assertions`（与清洁批同数），红集＝[]、`before==after`（同指纹）；`index_matches_regeneration` 随 runner 绿。
  - ⑤计划面（**不算通过**）：`tools/check.ps1 -Changed -ListOnly`（合同字面、默认基线 `HEAD`、干净树）→ exit 1、起引擎前拒绝＝`The change set is empty; committed changes need -Changed -Since <ref> (default base is HEAD).`（fail-closed；与片②干净树同形）；`tools/check.ps1 -Changed -Since b887d28 -ListOnly` → 运行 `20261013T160018289-41608`，exit 0、`status=plan`、`ROUTE FILES: 11`（`files_sha256=7e1ef4d2d7a9`、`index_digest=8efe105ccfa5`），逐行＝`ROUTE NONE`×5（`AGENTS.md`／`docs/spec/response-pipeline.md`／`docs/spec/state-readers.md`／`docs/spec/state-readers-dependencies.md`／`skills/repo-ops/SKILL.md`，declared-none）＋`ROUTE ROW: spire-godot/tests/architecture_cases.gd -> rules=architecture ui=(none) [signals=owner]`＋`ROUTE DEFAULT`（blind，`closure=spire-godot/tests/`）＝`tests/check_index.json`／`tests/mutations.json`／`tests/state_reader_scan.gd`／`tests/state_readers.json`＋`ROUTE DEFAULT`（`closure=spire-godot/tools/`）＝`tools/build_state_readers.gd -> rules=runner`；`ROUTE MILESTONE COVERAGE: 5 closure/fallback file(s) need the milestone full run`＋`PLAN ONLY: no game tests executed`。
  - ⑥本片变更集实跑 `tools/check.ps1 -Changed -Since b887d28 -TimeoutSeconds 3600` → 运行 `20261013T160050229-5096`，exit 0、`status=passed`、`before==after`（同指纹）、`route.mode=changed`／`route.since=b887d28`／`route.files_count=11`（`files_sha256=7e1ef4d2d7a928289524228761545fc607222bd785c19291c7462634f6a58ffc`、`index_digest=8efe105ccfa5…`）、`unmapped=[]`／`defect_hits=[]`／`widen=[]`／`milestone=[]`、`rules.failed=[]`／`ui.failed=[]`／`retry=[]`；规则 51/51 逐行 PASS＋`PASS: 147731 assertions`（`CHECK rules: 413.18s`），界面 45/45 逐行 PASS＋`UI PASS: 6816 assertions`（`CHECK ui: 1,435.72s`），docs PASS（47／2723／3）。**`-TimeoutSeconds` 用 3600 的理由（如实登记）**：本变更集经路由落到 `all-dev`＋`all-dev-ui`（5 个 blind 闭包文件＋`tools/` 闭包），合同字面 900s 必不足（片② 2026-10-13 对同形变更集实测 1200s 超时；同片 UI 相位需 ≈24 分钟），本批不再制造未完成轮。
  - ⑦文档面 `tools/check-docs.ps1` 单跑 → exit 0，`DOCS PASS: 47 rule-class document(s), 2723 reference(s) checked, allowlist 3 entrie(s)`（归档 `tmp/srharden-docs.log`；三条套件轮的 docs 阶段同为 PASS）。
- 突变取证（C-SR-1/2/4/5/6 的机械口径；三条条目锚经 `IndexOf` 复核全文件唯一＝1；判读＝目标判据具名 ERROR＋逐字节还原＋identity `head=5f53ce1 dirty=0`＋无 `MUTATION RESIDUE`＋外层 exit 0）：
  - `state_read_sites_are_pinned`（`core/game.gd::item_action_block` 签名行插恒假探针）→ 运行目录 `build/mutations/20261013T163232803-37296`（identity `head=5f53ce11dd64f9024abb40cf524f8addd6b7858f`、`dirty=0`），子轮 `20261013T163233485-40356`：`SUITE RESULT: architecture FAIL`、`FAIL: 1/120919 assertions; 1 engine errors`，ERROR＝`STATEREAD state_read_sites_are_pinned: the derivation equals the frozen table …; first difference at root.generated_from.cells (1265 vs 1264.0)`；`MUTATION …: RED exit-red=True restored=True sha256=85B78FF3C8D5 209.8s`；`MUTATION SUMMARY: 1/1 … worktree unchanged=True (pre-dirty=0)`；exit 0。
  - `state_read_scan_reaches_every_source`（`ui/main.gd::_submit` 的 dispatch 行后插 `var _probe_state_read=game.state.phase`）→ 运行目录 `20261013T163604018-29528`（identity 同上），子轮 `20261013T163604842-64324`：`FAIL: 3/120919 assertions; 3 engine errors`，ERROR＝`STATEREAD state_read_scan_reaches_every_source: ui/ never reads a registered state field directly: ["ui/main.gd::_submit:phase"]`＋级联 `state_read_sites_are_pinned`（`root.generated_from.inputs_sha256` 504e0a54…）与既有 `RL ui_never_reads_game_state`（同一读点）；`RED … restored=True sha256=F8EFD8DB6CAE 206.1s`；1/1、exit 0。
  - `state_read_registrations_are_pinned`（`core/game.gd::command_issue` 体首插 `state.duplicate(true)`）→ 运行目录 `20261013T163931284-49352`（identity 同上），子轮 `20261013T163931998-64916`：`FAIL: 2/120919 assertions; 2 engine errors`，ERROR＝`STATEREAD state_read_registrations_are_pinned: whole_state is a per (file,function,kind,count) declaration …: missing=[] extra=["core/game.gd|command_issue|duplicate|1"]`＋级联 `state_read_sites_are_pinned`（`inputs_sha256` 3e4a3857…）；`RED … restored=True sha256=85B78FF3C8D5 201s`；1/1、exit 0。
  - 归档：逐条 `tmp/srharden-mutation-<条目名>.log`（含子轮 stdout/stderr 与 SUMMARY）；子轮原始日志 `spire-godot/build/checks/<子运行号>/`、突变身份 `spire-godot/build/mutations/<运行号>/identity.txt`（均 gitignored、在盘）；三轮 `grep -c RESIDUE` 均为 0，每轮收尾 `GODOT PROCS AFTER: 0`／`DIRTY AFTER: 0`。
- 清洁六项口径的本批处置：①单一路径＝裁定 B 登记（扫描原语不合并，deps 文档已写明；三条判据只消费同一派生模块，本批③④实跑复核）；②冻结物性质＝②零字节差＋`--verify` sha256 `a4048167…`（本批未重跑 `build_state_readers.gd --write`，理由＝读面未变、冻结物非空且与清洁批逐字节相同）；③三判据强度＝裁定 A 落字（正例如实写明 `missing=` 半边结构性恒空、非双向守卫）；④裁定落字＝行数线已裁（清洁者）＋本批裁定 A／B／③；⑤索引重冻正当性＝①（`digest` 不变、仅 `generated_from` 移动一行）；⑥幻影名与存在性＝②③④⑥ 实跑覆盖（`--verify`／两条套件／路由实跑）。
- 判据→证据映射：C-SR-1＝②③＋突变 `state_read_sites_are_pinned` RED；C-SR-2＝③＋突变 `state_read_scan_reaches_every_source` RED；C-SR-3＝③（口径反例；纯写不计读由 C-SR-1 表外红承担）；C-SR-4＝③＋突变 `state_read_registrations_are_pinned` RED（整字典侧）；C-SR-5／6＝③ 的别名（6 函数 81 字段）与模式串（4 函数 15 字段）canonical 全等断言＋按裁定③并入同一突变条目；C-SR-7＝②③ 的 `STATE FAILURE FACE …` 打印行（报告面，非判据；数字不得写成实测读集）；C-SR-8＝三条条目在场、`known_gaps` 不增、`mutation_evidence_is_total` 随 ③④ 绿；C-SR-9＝①＋④＋`5f53ce1` 同批重冻；C-SR-10＝⑤⑥⑦＋`git diff --stat -- spire-godot/core spire-godot/ui spire-godot/data spire-godot/content spire-godot/assets` 为空（工作树与 `b887d28..HEAD` 双口径均空）。
- 四态：**已测**＝①..⑦＋突变三条（运行号与归档如上）；**失败**＝无（三条突变的目标 RED 为预期结果；无未完成轮、无 `SOURCE CHANGED`）；**未跑**＝`-Suite all -UI -UISuite all` 里程碑（合同列为里程碑项、协调者未在本批授权；⑤⑥ 的逐文件 `ROUTE` 与宽集实跑**不代替**里程碑通过——`ROUTE MILESTONE COVERAGE` 明示 5 个闭包文件须里程碑全量、开发路由不跑 milestone 套件）、安卓真机、打包与发布、独立审查与验收（协调者另派新会话）；**被跳过**＝无；**假设**＝无。
- 登记口径（G-SR-8）：**本片不产出 release 运行期面**；判据只在 debug/headless 套件运行，release 二进制无对应行为差异，也无「release 已验证」结论。
- 本节只追加本文件一个文件、单独提交（docs-only）；全部提交仅在本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。

### P5 独立审查与验收一轮登记（2026-10-14，协调者落账；补审查结论落点）

- 域：本节；对象 `b887d28..45f5ae4`（实现 `54d777d`→清洁 `8301818`→裁定A `5f53ce1`→记录 `50d7fef`→审查返修 `45f5ae4`）。
- **独立审查（会话模型子代理，只读）**：九项＋找漏洞；结论 **VERDICT: FAIL，但仅两条文档 [应修]**（机制面全部 [已核对]，含独立 Python 重写口径复算 files=129/registry=124/cells=1264/sites=2075/whole=52/ui_reads=0 与冻结物逐键全等）：①`state-readers-dependencies.md` 行数线「净增 77 行」与 `numstat` 不符（实 83）；②`state-readers.md` 残差「变量键读只以 get_variable 形态登记」失真（该类读**不进任何表**，实测纯读 ≥11 处）。返修 `45f5ae4`（两文档 6+/3−）交原审查者只复核受影响差异：**两条 [已核对]、VERDICT: PASS**。
- **验收一轮（验收者，自跑运行号）**：索引零漂移（digest `8efe105c…`）；冻结物 `--verify` exit 0（sha `a4048167…`，files=129/fields=121/cells=1264/sites=2075；failure face 117/878/39/1387）；`-Suite architecture`＝`20261013T170121418-58764`（120919 断言、红集 []、`before==after`）；三条突变＝`build/mutations/20261013T170520753-54020`（identity `head=45f5ae4 dirty=0`，3/3 RED＋逐字节还原，无 RESIDUE）；check-docs 47/2725/3。C-SR-1..10 记录面齐、G-SR-1..8 逐场景通过。**判定＝验收通过（未满足条目＝无）**。
- 四态：已测＝上列＋加固批全部；未跑＝全量里程碑、安卓真机、打包发布（本片不产出 release 运行期面，按口径登记）；被跳过＝无；假设＝无。

### 2026-10-14｜v0.18.2.fix 打包（Windows＋Android 自签）登记

- 域：`tools/package.ps1`／`tools/package-android.ps1` 及其成品探针；源＝枝 `worker/state-readers` HEAD `8f091eb`（含 `version/code=15`）。
- **Windows**：`20261014-sr`（首版）与 **`20261014-sr2`（当前，含改后包内说明）**；`check-package.ps1` 均 `PACKAGE CHECK PASS`（PCK 探针＋发布 EXE 启动＋12 相邻内容包）；sr2 ZIP 219,684,953 B，SHA256 `d8f1f8bf9ce4424276831e26113fada544fb8cda9a77a2e27758304c5177f7c5`，解压复验 24/24；EXE/PCK 哈希与 sr 完全相同（差异仅在说明与 manifest）。旧 sr 保留留档。
- **Android（本地自签测试包）**：本机自建工具链（官方 4.7.2 模板，SHA256 与 `docs/spec/packaging.md` 载值逐字节相符；SDK build-tools 35.0.1＋platform 36；JDK17 归位 `build/android-tools/`）；原发布签名密钥已遗失，经人令用本地自签密钥（密码仅存 keystore＋DPAPI，明文未落盘）——**APK 为自签测试包，不能覆盖安装正式签名版本**，包内附 `自签测试说明.txt`。APK 239,118,104 B，SHA256 `129e8e3d592ce44a4ec1a9b425ebaa143d1351c610f385e9adba771516ddccfd`：`APK RESOURCE PROBE PASS`、aapt 证 `versionCode=15/versionName=0.18.2.fix/targetSdk=36/arm64+armv7/仅 INTERNET`、apksigner v2+v3 验签通过、zipalign 校验通过、包内无禁入文件。Android ZIP（含说明与许可）234,968,510 B，SHA256 `ec07319e4fab607d81c0576f9fda3befec71eb6d4ef44172035acc7c8f07789f`，解压 12/12 复验。
- 包内说明改文（`cd214a7`）：两份 release-notes 由「未生成安装包」改为事实版（Win 包＋Android 自签测试包及其限制）；uid 边车补提交（`8f091eb`）。
- **按人令不发加密 7z**（「没有这么需要加密」）：已生成的半成品双层归档与含口令临时脚本均已删除，全树口令零残留；契约中的「双层加密 7z」交付项本轮不执行。
- 四态：已测＝上列导出与两平台包探针；未跑＝**安卓真机／模拟器安装与启动**（桌面探针不能替代真机验收）、发布/Tag/上传（未授权）；被跳过＝加密 7z（人令）；假设＝无。环境变更＝Godot 编辑器 Android SDK/JDK 路径指向本工作树自建工具链（备份见 `build/android-tools/`），换树打包须重新指向。

## 2026-10-19｜P7 present 邻接表完整性下限（A 档）落地：11 行／14 边、C1–C5 判据、5 条突变 RED、两份生成物同批重冻

- 域：`spire-godot/ui/main.gd::PRESENT_ADJACENCY`（仅声明表与表头注释）、`spire-godot/tests/architecture_cases.gd`（C1–C5 与解析助手、常量）、`spire-godot/tests/mutations.json`（5 条）、`spire-godot/tests/state_readers.json`／`check_index.json`（同批重冻）、`skills/spire-docs/SKILL.md` 第五类、`docs/record/proposals/present-adjacency-completeness-floor.md`；本节只追加本文件。合同＝`C:\1\tmp\magic-spire-wt-state-readers\tmp\p7-plan\{design,plan,gherkin,acceptance}.md`（G-PA-1..8／C-PA-1..10）与协调者裁定（A 档下限、C5=108、小锚突变、生成物同批）。每条结论写明命令／运行号／退出码或 `status`／断言计数／红集／`before==after`。
- 提交：实现 `e4dd123`（`feat(tests): pin the present pipeline completeness floor`，7 个授权文件）；本节单独提交（docs-only）。**仅本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。**
- 执行口径：工作树 `C:\1\tmp\magic-spire-wt-p7`、枝 `worker/p7-floor`；`GODOT_BIN` 每 shell 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；pwsh 7；单引擎串行（每轮跑前跑后 `Get-Process Godot*` 为 0）；判读＝退出码＋`SUITE RESULT` 行＋完成标记＋`summary.json` 的 `before==after`；全程无 `SOURCE CHANGED`。全部判据与突变证据在 `head=e4dd123cb464d16eb5507efe79373f517e5720e0`、`dirty=0` 下取得；记录提交在证据之后，不改判据证据所绑定的字节。
- 落地内容：表补 11 行（9 个 `_*_key_hit`＋`_unload_posture_section`／`_unload_resource_section`）＋14 条边，符号 97→108；表头改写为完整性契约。判据常量＝唯一机械真源：`PRESENT_PIPELINE_SHAPES`（7 个正则）、`PRESENT_PIPELINE_EXACT`（`render`／`_present_needs_full_render`）、`PRESENT_SYMBOL_FLOOR=108`；表头与 `skills/spire-docs/SKILL.md` 第五类只作规范描述，未复制函数名册；根 `AGENTS.md` 未改。C1–C5 均已注册进 `run()`，且各含单空格缩进的 `t.check(` 断言（`mutation_judgment_universe()` 可枚举）。
- 命令清单（`head=e4dd123`、`dirty=0`）：
  - ①基线 `tools/check.ps1 -Suite architecture -TimeoutSeconds 900` → 运行 `20261019T122751023-23172`，exit 0，`SUITE RESULT: architecture PASS`，`PASS: 120932 assertions`，红集＝[]，`before==after`＝`361BFF286EC6A3542985E059D046AE4C447C21D1428ABC5A7C8BE13C17FEB7CE`，docs 阶段 PASS（47 规则文档／2724 引用／3）；日志打印 `PRESENT ADJACENCY rows=108 symbols=108 arms=14` 与 `F2 SECTION READ SETS sections=15 groups=25`，无 ERROR（`section_read_sets_are_pinned` 实跑零移动，未改 `SECTION_READ_SETS`）。
  - ②`tools/check.ps1 -Suite architecture,runner -TimeoutSeconds 1200` → 运行 `20261019T130625202-48320`，exit 0，两分类逐行 PASS，`PASS: 122664 assertions`，红集＝[]，`before==after`（同指纹），docs PASS；`index_matches_regeneration` 随 runner 绿。
  - ③索引面 `tools/check-index.ps1`（verify）→ exit 0，`CHECK INDEX PASS … (digest 8efe105ccfa5a587d94e4a013593653e03b4587f684d837eab37d14cc0bbf316)`；`-Write` → exit 0，写后 `git status --porcelain` 为空（零漂移），再 verify 仍 exit 0。
  - ④冻结物 `tools/build_state_readers.gd --verify`（headless）→ exit 0，`STATE READERS PASS … (sha256 a6088892f268c1ecfda9cc98964ea18a36a1083722a6af2c1d04780a768b2ea1)`，`files=129 fields=121 cells=1264 sites=2075 whole_state=52 ui_reads=0`、`unknown=0`、`inputs_sha256=21c19388…`；`--write` 连跑两轮均 exit 0，写前／两轮写后 `tests/state_readers.json` 的 sha256 均为 `540176b2aebafedc7e414261241ef38b2cae8e69edcfa1e7fb053326e4475a53`（逐字节同，且等于已提交字节），`git status --porcelain` 为空。
  - ⑤文档面 `tools/check-docs.ps1` 单跑 → exit 0，`DOCS PASS: 47 rule-class document(s), 2724 reference(s) checked, allowlist 3 entrie(s)`（各套件轮的 docs 阶段同为 PASS）。
- 突变取证（外层运行 `build/mutations/20261019T123242036-17636`；`RUN IDENTITY head=e4dd123… dirty=0`；判读＝具名判据 ERROR＋逐字节还原＋无 `MUTATION RESIDUE`＋外层 exit 0；`MUTATION SUMMARY: 5/5 … restored byte-for-byte; worktree unchanged=True (pre-dirty=0); elapsed 1359.1s`）：
  - `present_adjacency_rows_are_complete`（删 `"_enemy_hp_text":[]` 行）→ 子轮 `build/checks/20261019T123242797-18956`：`FAIL: 2/120932`，ERROR＝`ARCH present_adjacency_rows_are_complete: every table symbol has its own row: ["_enemy_hp_text"]`；`RED … restored=True sha256=AC53EFFC2069 273.5s`。
  - `present_section_dispatch_is_total`（`relics` 臂改为 `pass`）→ 子轮 `build/checks/20261019T123716462-5244`：`FAIL: 3/120932`，ERROR＝`ARCH present_section_dispatch_is_total: … ["relics -> "]`＋既有 `every declared edge has a direct call … ["present -> _relic_row"]`；`RED … restored=True sha256=AC53EFFC2069 273.5s`。
  - `present_pipeline_routines_are_registered`（插入 `_sync_mutation_probe_stage`）→ 子轮 `build/checks/20261019T124149771-46336`：`FAIL: 2/120932`，ERROR＝`ARCH present_pipeline_routines_are_registered: … ["_sync_mutation_probe_stage"]`；`RED … restored=True sha256=AC53EFFC2069 266.4s`。
  - `present_full_render_fallback_is_pinned`（从 `present` 行删 `"render"`）→ 子轮 `build/checks/20261019T124616309-47476`：`FAIL: 3/120932`，ERROR＝`ARCH present_full_render_fallback_is_pinned: … ["render is not declared on the present row"]`＋既有 `a table symbol a registered parent calls directly is declared: ["present calls render()"]`；`RED … restored=True sha256=AC53EFFC2069 290.3s`。
  - `present_adjacency_symbol_floor_is_pinned`（删 `_menu_drawer` 行与其在 `_refresh_drawer_section` 的边）→ 子轮 `build/checks/20261019T125106532-30528`：`FAIL: 3/120932`，ERROR＝`ARCH present_adjacency_symbol_floor_is_pinned: … symbols=107`＋级联 `F2 section_read_sets_are_pinned: adjacency bodies are reachable … ["drawers/_menu_drawer"]` 与 `STATEREAD state_read_sites_are_pinned`（输入指纹因临时改写变化）；`RED … restored=True sha256=AC53EFFC2069 255.3s`。目标判据 C5 红，C1 保持绿（删行同时删边，符号集无悬空引用）。
  - 各条临时改写都会级联 `state_read_sites_are_pinned`（`ui/main.gd` 文本在冻结输入指纹内），属预期副作用；目标判据均按名出现。
- 空表手工反例（协调者裁定：不入 `mutations.json`，由验收者复核）：备份 `ui/main.gd`（sha256 `ac53effc20695dd4cb1d277770fc4a4be11914127eb5a37baf3afab6e6fae908`），把整段 `PRESENT_ADJACENCY` 字面临时替换为 `{"present":[]}`（sha256 `b9a0eb09…`）→ `-Suite architecture` 运行 `20261019T125630437-46896`，exit 1，`FAIL: 6/120932`，ERROR＝C2／C3／C4／C5（`symbols=1`）＋`F2 section_read_sets_are_pinned`＋`STATEREAD state_read_sites_are_pinned`；逐字节还原备份后 sha256 仍为 `ac53effc…`、`git status --porcelain` 为空；同命令复跑运行 `20261019T130057465-34172`，exit 0，`PASS: 120932`。
- 边界核对：`git diff -U0 e4dd123^ e4dd123 -- spire-godot/ui/main.gd` 无新增／删除的 `func` 行与 `present(`／`render(` 逻辑行（改动只在 `PRESENT_ADJACENCY` 字面与表头注释）；实现提交只触及 7 个授权文件（`git show --stat`：proposal、`skills/spire-docs/SKILL.md`、`tests/architecture_cases.gd`、`check_index.json`、`mutations.json`、`state_readers.json`、`ui/main.gd`）。静态复核：表 `rows=108`／`symbols=108`、11 个新行全部在场、14 条新边全部声明、45 个形状命中全部入表、5 条突变的 `find` 在实现后字节中唯一出现 1 次。
- 四态：**已测**＝①..⑤＋5 条突变＋空表反例＋还原后复跑（运行号如上）；**失败**＝无（突变与空表的目标 RED 为预期结果；无未完成轮、无 `SOURCE CHANGED`）；**未跑**＝`-Suite all -UI -UISuite all` 里程碑与 UI 窗口套件／recipe／打包／双平台（本片无窗口与产物面，协调者留待里程碑／验收另计）、独立审查与验收（协调者另派新会话）、`-Changed` 路由（本片未授权按变更集路由）；**被跳过**＝无；**假设**＝无。
- 本节只追加本文件一个文件、单独提交（docs-only）；全部提交仅在本地 `.git`；未推送、未 tag、未改版本号、未开 PR、未打包。

## 2026-10-20｜P7 present 邻接表下限：加固（低档）复取证据（HEAD `0e3aba7`）

- 域：§上节同域的判据面与突变面——`spire-godot/tests/architecture_cases.gd`（C1–C5）、`spire-godot/tests/mutations.json`（5 条）、`spire-godot/ui/main.gd::PRESENT_ADJACENCY`、`tests/check_index.json`／`tests/state_readers.json`（生成物 verify）、`spire-godot/tools/check-docs.ps1`；本节只追加本文件。
- 字节基线：被验证提交 `0e3aba765668711322379b1b0bd1c6d798858cbf`（`docs(record): register the present adjacency completeness floor`）；`git diff --name-only e4dd123 0e3aba7` 只含 `docs/record/verification.md`，`git diff e4dd123 0e3aba7 -- spire-godot` 为 0 字节 ⇒ **产品字节与上节实现证据 `e4dd123` 相同**，上节运行号（`20261019T122751023-23172`／`20261019T130625202-48320`／`20261019T123242036-17636` 等）在案；本轮为低档加固的独立复跑。
- 执行口径：工作树 `C:\1\tmp\magic-spire-wt-p7`、枝 `worker/p7-floor`；`GODOT_BIN` 每 shell 显式＝`C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`；pwsh 7.6.7；单引擎串行（各轮跑前跑后 `Get-Process Godot*` 为 0）；全部命令在 `head=0e3aba7…`、`dirty=0` 的干净树上执行，全程无 `SOURCE CHANGED`。
- 判据面（`spire-godot/` 下）：
  - `tools/check.ps1 -Suite architecture -TimeoutSeconds 900` → 运行 `20261019T132448840-20972`，exit 0，`SUITE RESULT: architecture PASS`，`PASS: 120932 assertions`，红集＝[]，`status=passed`，`before==after`＝`361BFF286EC6A3542985E059D046AE4C447C21D1428ABC5A7C8BE13C17FEB7CE`；docs 阶段 PASS（47 规则文档／2724 引用／3 允许项）；日志打印 `PRESENT ADJACENCY rows=108 symbols=108 arms=14`，无 ERROR。
  - `tools/check.ps1 -Suite architecture,runner -TimeoutSeconds 1200` → 运行 `20261019T132918148-42236`，exit 0，两行 `SUITE RESULT: architecture PASS`／`SUITE RESULT: runner PASS`，`PASS: 122664 assertions`，红集＝[]，`status=passed`，`before==after`（同指纹）；`runner` 的 `index_matches_regeneration` 随分类绿。
- 突变取证（外层运行 `build/mutations/20261019T133417422-31296`；`RUN IDENTITY head=0e3aba765668711322379b1b0bd1c6d798858cbf`、`dirty=0`；外层 exit 0；`MUTATION SUMMARY: 5/5 entr(ies) reddened the named check and restored byte-for-byte; worktree unchanged=True (pre-dirty=0); elapsed 1509.8s`；无 `MUTATION RESIDUE`）：
  - `present_adjacency_rows_are_complete` → 子轮 `20261019T133418267-47076`，exit 1，`FAIL: 2/120932`，ERROR＝`ARCH present_adjacency_rows_are_complete: every table symbol has its own row: ["_enemy_hp_text"]`（＋预期级联 `STATEREAD state_read_sites_are_pinned` 输入指纹差）；`restored=True sha256=AC53EFFC2069`。
  - `present_section_dispatch_is_total` → 子轮 `20261019T133846789-44572`，exit 1，`FAIL: 3/120932`，ERROR＝`ARCH present_section_dispatch_is_total: … ["relics -> "]`＋既有 `every declared edge has a direct call … ["present -> _relic_row"]`；`restored=True sha256=AC53EFFC2069`。
  - `present_pipeline_routines_are_registered` → 子轮 `20261019T134332786-20748`，exit 1，`FAIL: 2/120932`，ERROR＝`ARCH present_pipeline_routines_are_registered: every pipeline-shaped routine is a table row: ["_sync_mutation_probe_stage"]`；`restored=True sha256=AC53EFFC2069`。
  - `present_full_render_fallback_is_pinned` → 子轮 `20261019T134843838-11236`，exit 1，`FAIL: 3/120932`，ERROR＝`ARCH present_full_render_fallback_is_pinned: … ["render is not declared on the present row"]`＋既有 `a table symbol a registered parent calls directly is declared: ["present calls render()"]`；`restored=True sha256=AC53EFFC2069`。
  - `present_adjacency_symbol_floor_is_pinned` → 子轮 `20261019T135356686-43800`，exit 1，`FAIL: 3/120932`，ERROR＝`ARCH present_adjacency_symbol_floor_is_pinned: … symbols=107`＋级联 `F2 section_read_sets_are_pinned … ["drawers/_menu_drawer"]`／`STATEREAD state_read_sites_are_pinned`；`restored=True sha256=AC53EFFC2069`。
  - 还原后 `ui/main.gd` 实测 sha256＝`ac53effc20695dd4cb1d277770fc4a4be11914127eb5a37baf3afab6e6fae908`（与实现节备份一致），`git status --porcelain` 为空。
- 生成物零漂移（`head=0e3aba7`、`dirty=0`）：
  - `tools/check-index.ps1`（verify）→ exit 0，`CHECK INDEX PASS: frozen index equals the derivation (digest 8efe105ccfa5a587d94e4a013593653e03b4587f684d837eab37d14cc0bbf316)`，日志 `build/check-index-20261019T133402420.log`；未跑 `-Write`（本轮无源码文本变化，重冻非必要）。
  - `build_state_readers.gd -- --verify`（headless）→ exit 0，`STATE READERS PASS … (sha256 a6088892f268c1ecfda9cc98964ea18a36a1083722a6af2c1d04780a768b2ea1)`，`files=129 fields=121 cells=1264 sites=2075 whole_state=52 ui_reads=0`、`unknown=0`；未跑 `--write`（同上）。
- 文档面：`tools/check-docs.ps1` 单跑 → exit 0，`DOCS PASS: 47 rule-class document(s), 2724 reference(s) checked, allowlist 3 entrie(s)`。
- 四态：**已测**＝architecture／architecture,runner／5 条突变（RED＋逐字节还原＋identity `head=0e3aba7 dirty=0`＋无 RESIDUE）／两份生成物 verify／check-docs（运行号如上）；**失败**＝无；**未验证**＝`-Suite all -UI -UISuite all` 里程碑、UI 窗口套件、recipe、打包与双平台、`-Changed` 路由、空表反例本轮未重做（上节已测，非本档范围）、独立审查与验收（非加固职能）；**被跳过**＝无；**假设**＝无。
- 本节只追加本文件一节、单独提交（docs-only）；仅本地 `.git`，未推送、未 tag、未改版本号、未开 PR、未打包。

### 2026-10-19｜P7 独立审查与验收登记（协调者落账）

- 域：本节；对象 `e5723b2..38e6d8f`（实现 `e4dd123`、记录 `0e3aba7`、加固 `38e6d8f`；枝 `worker/p7-floor`）。
- **独立审查**（`dsp-20261019T140237Z-7606`，只读、未跑引擎）：**VERDICT PASS，零 [应修]**。逐项核对：改动面仅 8 个授权文件、禁止面零改动、`ui/main.gd` 无逻辑行（表为纯声明）；表实为 108 行/符号、11 行/14 边全在场；形状表与 `design.md` 冻结表逐字一致且只在判据常量一处；C1–C5 按契约实现并注册；五条突变锚唯一、RED 均落在具名判据、`known_gaps` 未增；两份生成物只动指纹行；文档与全部运行号载体在案。六条 [存疑] 留案（C4 与旧断言部分重叠、C3 可达性依赖 3b、C2 仅识别规范臂形态且不钉节→例程身份、形状字符类对非 snake_case 及 `_build_*`／`_sync_*` 边界、表解析折叠重复键、C5 可被补偿），不构成应修。
- **验收一轮**（`dsp-20261019T141339Z-52f9`）：自跑 architecture PASS **120932**（run `20261019T141441089-6088`，status=passed，before==after，`rows=108 symbols=108 arms=14`）；五条突变 **5/5 具名 RED＋逐字节还原**（run `20261019T142120218-24224`，identity `head=38e6d8f dirty=0`，无 RESIDUE）；两份生成物 verify 零漂移；check-docs PASS（47/2724/3）；**独立复做整表掏空反例**：临时替换为 `{"present":[]}` → FAIL 6/120932（红集＝C2／C3／C4／C5＋`section_read_sets_are_pinned`＋`state_read_sites_are_pinned`，C1 保持绿，与设计一致）→ 逐字节还原（sha256 回到 `ac53effc…`、树净）→ 同命令复跑 PASS 120932（run `20261019T145608667-40796`）。C-PA-1..10 逐条满足；**总判定＝验收通过**。
- 未跑（如实，不作通过）：全量里程碑／UI 窗口套件／recipe／打包与双平台／`-Changed`（授权面外；本片无窗口与产物面）。
- P7「present 邻接表完整性下限」切片闭合：提案状态已改为已落地（`0e3aba7` 批内）。


## 2026-10-30｜PR #14／#15 集成与前端文案指导

- 范围：以 PR #15 的 `b4f19ab907481736c7c4047eb78c0ea501e88bd7` 接入事实查询、按需投影、检查路由、状态读者表与呈现邻接表；`008e5054f9ef549fdbfa921fb3ce6af1d163696e`（PR #14）是其祖先，手牌内容标签回插修复一并接入。保留用户当前 AGENTS 规则、原验证册全文与本机发布签名约定，项目技能正文归入 `skills/`，移除作者机器路径与重复审查流程。公开版本仍为 `0.18.2.fix`；本批只同步源码，不打包、不打标签、不创建 Release。
- 新指导：玩家可见文字禁止过度防御化与过度描写；根 AGENTS 和界面技能指向 `docs/guide/action-copy-guide.md` 的“前端文字表达”。保留费用、概率、限制、失败原因、必要提醒、人物语气与必要场景信息；不改变正式运行时校验。
- 干净候选：`7d9aed966ee87ccf858f887e95aae237eae0a969`，准备分支 `codex/pr15-integration-20261030`；验证指纹 `1C4B6685A1D08EC495179A28344BB2915CAEA64CB4387AFCD7279DF0DC64D018`。`20261030T094940904-24348`：architecture／runner 共 122664 断言通过；recipe 为 seed=7、60 提交／60 步、stop=cap、194 断言、exit=0；15 项测试器负例与路由探针通过，summary=passed、before==after。文档门禁 47 份／2761 引用通过。
- 全分类尝试 `20261030T095535320-52288`：已完成的 33 个规则分类共 14501 断言通过，完整随机采样；normal_play 在 seed=20260906 的高装备量流程中长时间无新进度，人工停止任务所属引擎，整轮 exit=-1、summary=failed、该分类未完成，不能称完整回归通过。通过分类保留证据，不重复运行。
- 耗时对照：保留第 950 步检查点，独立分段驱动定位至第 969 步 battle/end 的 dispatch 未返回。旧主线 `6ac813ff3eb767b9f202ffa9cae2ea92c88f36d8` 加载相同输入亦停在同点，45 秒到界后终止。输入校验和：检查点 `eb42eda2a23d840ecd13871453ce82d45ac62e5406109e6c534f78e281dd270b`，驱动 `2c68b5e578db9007a29b4b87d53fba29e4bfeede0f1ce737d4e4b0e3ed4514d0`；证据在准备树与对照树的 `spire-godot/build/pr15-prep-20261030/`。仅证明旧源码也存在同点长耗时，未确认最终根因，未改变游戏规则或删除失败判据。
- 续跑 `20261030T100829774-2508`：剩余 16 个规则分类共 15030 断言通过；敌人行动循环 16／16、敌池 24／24、塔图 201／201 种子覆盖。连同首轮，共 51／52 规则分类通过；未完成项为上述 headless normal_play。
- 记录守恒：`check-record-conservation.ps1 -Base origin/main` 对三卷原文、标识、标题／日期／域及失败标记的差集全为 0；现行卷仅追加 PR 的 45 个新章节。独立只读审查沿用 `review_pr15_integration`（Astra low），运行时边界、政策适配和本地冲突合并无阻断发现。
- UI 全分类证据：`20261030T100829774-2508` 达到 1500 秒执行时限，summary=failed，但 41 分类／7033 断言已完成；只用 `-RerunFailed` 续跑六个未完成分类，`20261030T103618411-30556` 为 997 断言、exit0、summary=passed。两轮 before==after，且与上述候选指纹相同；合计 47／47 UI 分类、8030 断言通过。UI normal_play（seed=7）945 断言通过并到达出狱路线地图；不与未完成的 headless normal_play（seed=20260906）混同。桌面触屏事件模拟不等于安卓真机验收。


## 2026-10-30｜PR 集成补检：休息选择页读组声明

- 主工作区在 `20261030T104257979-51440` 期间并行加入附魔改动，整轮 source_changed，不作为冻结通过证据。原 121 项在途输入按备份／三方合并结果在隔离树恢复，非记录源码逐文件对应并发前的哈希清单，未复制附魔在途变更，也未回退主工作区的并行改动。
- 稳定复现 `20261030T104803346-35712`：本地融合快照的 display／basic_attacks／card_interaction 共 1650 断言通过；recipe 虽完成 60 提交，但在休息选择页触发 F3 `undeclared-group=rest_service`，exit1，整轮 failed 且 before==after。已有正式页面需求包含该组，缺口位于检查器的独立 `PAGE_READ_GROUPS`，不是游戏规则缺失。
- 修正 `tests/display_ui_cases.gd::PAGE_READ_GROUPS`，补入 `rest_service`；`present_demand_recorder` 沿现有夹具、正式休息入口和实际页面渲染，显式覆盖非练习的 rest_choice，并断言阶段前提。独立全组 oracle 与原判据保持，`tests/check_index.json` 用官方生成器同步。
- 新夹具配旧声明的针对性负例：`20261030T105352364-49584` display 1324 断言，唯一错误为真实 `reward_screen::row` 读取触发的 F3 漏组，before==after。补声明后的干净候选 `20261030T105636230-52404`：runner 1732、display 1324 断言通过，exit0、summary=passed、before==after。
- 本地融合快照的同配方复验 `20261030T105915207-52456`：seed=7、60 提交／60 步、stop=cap，实际经过 rest_choice／rest／treasure，155 断言、exit0、summary=passed、before==after。与反例相比只改显示校验及其派生索引，复用上述三个 UI 分类的未受影响交互证据；并行附魔功能不在本批验收内。
- 同一独立审查者 `review_pr15_integration`（Astra low）核对实际差异、非练习阶段前提与具名反例，无阻断意见。其余通过分类沿用同日记录的有效证据；旧 headless 长流程耗时、本地 K4／G6 基线失配保持登记，未宣称完整回归全绿。公开版本与发布边界不变。
