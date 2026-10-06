# 验证记录归档 · 2026-09-12 及更早（实际范围 2026-09-07 至 2026-09-10，203 条）

> 路径说明：本卷正文保留撰写当时的文件路径（旧 `docs/<名>.md` 现按类归入 `docs/spec|design|guide|record|history/`）；需要定位时按文件名搜索。

归档：仅追溯用，不是现行指令；现行口径见 `docs/record/verification.md`。
**证据索引**（2026-10-05 重写）：格式同现行卷（日期＋标题＋「域」行＋证据句＋未跑项＋失败与不作证据轮）；
叙述性展开已删，保留句逐字未改；文内链接为迁移前相对路径。

## 2026-09-10 顶部警戒等级
域：界面、检查与测试。
- 完整interface窗口分类执行461项，日志build/checks/20260910T135530037-63064/check-ui.log。本批已完成资源导入，未修改无关姿势布局／断言；不得将整组记为通过。

## 2026-09-10 魅魔的魔力典当铺插图接入与配图核对
域：压力与快感、角色与美术。

## 2026-09-10 翘腿无视正式卡图
域：`ui/event_screen.gd`、`data/room_events.gd`。
- ListOnly后执行Import及完整home窗口检查，108项通过，退出0且无引擎错误：build/checks/20260910T134747394-49700/check-ui.log。唯一窗口截图build/ui-crossed-legs-formal.png，人物完整落在原插图区，无白底、座面块或拉伸。
- 用户提供的 `00093-2888790767.png` 原样复制到 `assets/art/event-succubus-magic-pawnshop-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误；日志 `build/checks/20260910T132922635-42664/`。

## 2026-09-10 神秘女人的雕像插图接入
域：角色与美术、界面。
- 用户提供的 `00091-1968829285.png` 原样复制到 `assets/art/event-mysterious-woman-statue-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误；日志 `build/checks/20260910T132535194-42248/`。

## 2026-09-10 缚梦客房插图接入
域：角色与美术、界面。
- 用户提供的 `00090-3863653336.png` 原样复制到 `assets/art/event-bound-dream-guest-room-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误；日志 `build/checks/20260910T132229627-41320/`。

## 2026-09-10 玩偶师与召唤人偶正式立绘
域：角色与美术、界面。
- 沿原召唤案例更新默认图断言，追加人偶独立切换且不改变召唤者图片的检查，不增加规则接口或玩法字段。
- tools/check.ps1 -Import -UIOnly -UISuite home,enemies -Screenshots ui-puppet-formation.png -TimeoutSeconds 300：完整home 103项、enemies 201项，共304项通过，退出0且无引擎错误。日志build/checks/20260910T134431772-58408/check-ui.log。

## 2026-09-10 六缚正式立绘与逐项画风
域：角色与美术、界面。
- 窗口分类display完整21项、home完整103项通过，包含独立保存恢复、图鉴来回切换、缺图提示及状态不变；日志build/checks/20260910T133048055-13712/check-ui.log。该批随后因新增敌人显示案例误用不存在的练习按钮失败，已改为复用现有six_bind_cases遭遇夹具；不增加生产入口。
- 完整enemies窗口分类复验199项通过、退出0且无引擎错误：build/checks/20260910T133248948-18720/check-ui.log。

## 2026-09-10 拘束具堆里的微光插图接入
域：装备与解除、角色与美术。
- 用户提供的 `00089-3699988499.png` 原样复制到 `assets/art/event-bound-adventurer-relic-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误；日志 `build/checks/20260910T131930895-43148/`。

## 2026-09-10 缚疗修女插图接入
域：角色与美术、界面。
- 用户提供的 `00088-549235516.png` 原样复制到 `assets/art/event-binding-cleric-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 纹理导入成功；初验发现原窗口案例将修女固定为无图占位，已将该断言更新为实际贴图路径及等比显示检查，不新增用例或截图。初验日志 `build/checks/20260910T131441267-51972/`。
- 复验 `tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240` 完整events窗口分类163项通过、退出0且无引擎错误；日志 `build/checks/20260910T131647136-62828/`。

## 2026-09-10 女药师的试饮摊插图接入
域：角色与美术、界面。
- 用户提供的 `00087-1686288904.png` 原样复制到 `assets/art/event-alchemist-tasting-stall-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误，日志位于 `build/checks/20260910T131110739-63844/`；复用现有检查，无新增截图。

## 2026-09-10 魅纹师的空房插图接入
域：角色与美术、界面。
- 用户提供的 `00086-4247279898.png` 原样复制到 `assets/art/event-enchanters-empty-studio-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入完成，完整events窗口分类163项通过；日志位于 `build/checks/20260910T130548739-62972/`。

## 2026-09-10 偷渡商人的魔药箱插图接入
域：角色与美术、界面。
- 用户提供的 `00085-558123539.png` 原样复制到 `assets/art/event-smuggled-mana-potions-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误，记录在 `build/checks/20260910T130237552-63248/`；复用现有检查，无新增测试或截图。

## 2026-09-10 迷宫测绘队插图接入
域：`ui/event_screen.gd`。
- 将用户提供的 `00084-4094280623.png` 原样复制为 `assets/art/event-maze-survey-team-v1.png`，源图与项目副本 SHA256 一致；`ui/event_screen.gd::ARTWORK` 以稳定事件ID接入，正式事件与练习共用，沿原画框完整等比显示。
- 先以 `tools/check.ps1 -UIOnly -UISuite events -ListOnly` 核对范围，再执行 `-Import -UIOnly -UISuite events -TimeoutSeconds 240`；纹理导入成功，完整 events 窗口分类通过163项断言、退出0且无引擎错误，日志位于 `build/checks/20260910T125842194-45508/`。

## 2026-09-10 两张事件插图接入
域：`ui/event_screen.gd`。
- 将用户确认的二次元版废弃储物室、减少数量版漂浮皮带群复制到 `assets/art/event-abandoned-storeroom-v1.png` 与 `assets/art/event-floating-belt-cluster-v1.png`，两份原图与项目副本的 SHA256 分别一致。
- 先以 `tools/check.ps1 -UIOnly -UISuite events -ListOnly` 核对范围，再执行 `-Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整 events 窗口分类通过162项断言、退出0且无引擎错误；日志 `build/checks/20260910T125334872-58796/check-import.log` 与 `check-ui.log`。

## 2026-09-10 向墙移动放在坐下上方
域：塔路与地图、界面。
- 先ListOnly确认basic_attacks／wall范围，最终窗口77项通过，退出0、无引擎错误：build/checks/20260910T134930684-56444/check-ui.log。已查看本批唯一代表截图build/ui-basic-action-rail.png，向墙移动位于坐下正上方。

## 2026-09-10 种子标签
域：界面、检查与测试。

## 2026-09-10 专心致志与双拘束面
域：界面、装备与解除。
- 验证非负整数及合法增量，快照拒绝坏成长数据；不迁移旧存档。
- card_growth规则分类覆盖8→12→16、同名UID隔离、两面预览和实际伤害、拒绝不变、同场重抽、快照恢复／非法值、场末清理、休息第二面、无目标、合法免疫0伤、第二面免费复放与失效跳过。
- 已查看唯一代表截图build/ui-concentration.png，两面名称、伤害和独立实体显示正确。
- 最终card_growth／services／content及自动选入的交叉分类通过3969项断言、退出0且无引擎错误：build/checks/20260910T115431448-30572/check-rules.log。商店容量用例改为按实际剩余容量填充，而非假定初始背包为空；施法动作教程窗口断言同步现有的一只手自由文案，不修改遗物规则。完整casting／card_growth窗口复验通过211项、退出0且无引擎错误：build/checks/20260910T120235887-17512/check-ui.log。
- 额外通用UI检查未全通过，不能报告全量绿色：同批interface完成457项且无失败；baseline仍有9项失败，涉及事件固定拒绝／离开遍历（3项）、未展开工具详情的安装及后续损耗（4项）、链接悬停旧共享耐久文案（1项）、单手套挂钩旧结构提示（1项）。记录于build/checks/20260910T115431448-30572/check-ui.log；这批未改动相应事件、工具安装、链接或挂钩规则，需在相应界面维护批次核对。该日志中的另1项施法遗物旧文案断言已由上述211项复验解决。

## 2026-09-10 行动日志文案整理
域：界面、文案与本地化。
- action_log_cases并入action_copy分类，覆盖实际失败施法、费用小数、各魔力来源、微量支出、留手、拒绝不变、只读重复投影、装备伤害短结果／完整公式、恢复历史、真实遗物退款来源和移动摘要。
- 首轮合并检查7550项，唯一失败为新移动日志夹具使用了不参与被动滑脱的脚踝；改用既有大腿根夹具，并移除与该姿态正式候选不符的一格距离限制，只提交实际候选。其余分类未发现错误，日志build/checks/20260910T111034872-32796/check-rules.log。修正夹具后，完整action_copy分类通过60项，真实窗口通过29项，两项均退出0、无引擎错误且有PASS标记，日志build/checks/20260910T111417165-54236/check-rules.log与check-ui.log。

## 2026-09-10 乌龟壳与蓄力保留条件
域：压力与快感。

## 2026-09-10 道具图鉴
域：装备与解除、检查与测试。
- 百科分类关联installed_tools与consumables，既有基础类型收录断言保留。
- 规则检查1054项通过：build/checks/20260910T110430202-49392/check-rules.log。
- 首次窗口检查遇到另一批新遗物SVG尚未完成导入及工具整数展示格式问题；补齐整数格式并导入已落盘资源后，完整重跑home,installed_tools,services，251项通过，退出0且无引擎错误：build/checks/20260910T110610411-42188/check-ui.log。唯一截图build/ui-encyclopedia-items.png已查看，药剂／卷轴／工具筛选和道具详情布局正常，正文在详情滚动区完整显示。
- 终局断言同步既有“所有阶段可丢弃道具”入口，仍断言17个房间完成、每战一次奖励与终局；未改变游戏规则来适配遍历。
- 最终规则分类检查通过6970项断言、退出0且无引擎错误（build/checks/20260910T104933390-59168/check-rules.log）。同批窗口检查仅有一处旧status悬停断言仍要求默认跨战保留；rewards的181项完成且无该分类错误。修正旧预期后，完整status窗口复验通过56项断言、退出0且无引擎错误（build/checks/20260910T105428261-56708/check-ui.log）。已查看唯一代表截图build/ui-charge-all.png，乌龟壳图标、全量模式、伤害预览与3层可保留／4层清除说明一致。

## 2026-09-10 蓄力右键全量释放与整备来源保留
域：压力与快感、界面。
- 失败／过期请求不消耗，纯倍率群体／被动／火球不新增蓄力收益。
- status分类复用charge_cases覆盖7层释放、切回、普通／多段体术、挣扎／滑脱／捕缚、逐段卡牌后续不重用旧蓄力、火球保留、拒绝回滚、整备→地图→战斗、优先消耗与混合份额全量清除、休息／牢房清理；更新灵活变通、牢房出口与原整备夹具的旧保留预期。
- 首轮8512项检查有2处断言失败：新切换测试漏排除正常更新的日志摘要；旧装备练习测试与同批已接入的“随时丢弃道具”候选冲突。
- 最终`tools/check.ps1 -Suite status,basic_attacks,equipment,guard,rewards,prison -TimeoutSeconds 300`通过8515项断言，日志`build/checks/20260910T101331411-23748/check-rules.log`。`-UIOnly -UISuite status -Screenshots ui-charge-all.png`通过54项真实窗口断言，日志`build/checks/20260910T101239468-53588/check-ui.log`。两项退出0、无引擎错误；已查看唯一代表截图`build/ui-charge-all.png`，图标、预览和说明一致。

## 2026-09-10 魔瓶即时存取
域：未在原文标注。

## 2026-09-10 场景SL
域：检查与测试、界面。
scene_restart_cases并入persistence，检查同场景攻击／回合保持检查点、随机重放、过期拒绝、磁盘重开、商店付款与库存整体撤回、离店收益、牢房及战斗奖励边界。原精确快照测试继续保留；文件写入与窗口恢复断言改为场景起点。规则门禁通过7078项断言（build/checks/20260910T101244207-13248/check-rules.log）。首轮UI两项失败来自测试用普通按钮尝试重新打出拖拽牌，已改用真实拖拽重放；完整home/persistence窗口复验通过156项断言，无引擎错误（build/checks/20260910T101748543-37724/check-ui.log）。

## 2026-09-10 分辨率与三种显示模式
域：`ui/display_settings.gd`。
- ui/display_settings.gd通过Godot Window接口控制真实窗口，统一管理三种模式、当前显示器尺寸筛选、窗口居中、全屏返回尺寸与borderless标记。显示偏好使用独立ConfigFile，不修改游戏快照、资源、随机或回合；缺失配置保留默认窗口，越界尺寸按当前屏幕收敛，保存失败在设置内明确提示。
- 引擎接口依据：[Godot DisplayServer文档](https://docs.godotengine.org/en/stable/classes/class_displayserver.html)。
- ListOnly后完整执行display,home窗口分类，105项断言通过，退出0且无引擎错误：build/checks/20260910T100754218-20528/check-ui.log。已查看唯一截图build/ui-display-settings.png，720p下设置完整可见，三个控件与正文正常显示，无裁切或拉伸。

## 2026-09-10 墙缝安装二级菜单
域：装备与解除、界面。
- 日志build/checks/20260910T100105938-38340/check-ui.log。仅生成并查看build/ui-tool-install-menu.png：菜单与低／中选项正常显示，高选项在同一滚动区；说明保留换行，无内容越出窗口。

## 2026-09-10 道具随时丢弃
域：界面、检查与测试。
- 真实地图出发、休息开始、战斗结束、巡视进入、强制回合及多段续打等流程覆盖：候选唯一、查看不变、旧版本拒绝、只移除指定物品、资源／回合／随机／阶段及未完成卡牌保持不变、重复请求原子拒绝，原连续行动仍可完成。旧阶段锁定断言仅放行免费丢弃，原道具使用限制保留。
- ListOnly后运行item_discard规则及installed_tools,services窗口：286项规则、148项UI断言通过，日志build/checks/20260910T094933976-30216/。
- 扩展prison,pressure,services,rewards分类共执行7125项，发现旧工具投影／商店描述与内容覆盖断言尚未匹配当前代码。更新后按失败分类content,installed_tools,services重新ListOnly并完整回归其关联分类，共3883项通过，退出0且无引擎错误：build/checks/20260910T095520277-46984/check-rules.log。
- 已先ListOnly核对范围；`tools/check.ps1 -UIOnly -UISuite consumables,rewards -TimeoutSeconds 300`完成216项窗口断言，退出0且无引擎错误。日志：`build/checks/20260910T094406605-59728/check-ui.log`。

## 2026-09-10 道具详细效果补全
域：装备与解除、界面。
- `tools/check.ps1 -UIOnly -UISuite installed_tools -Screenshots ui-tool-effect-details.png -TimeoutSeconds 300`通过33项，退出码0。日志build/checks/20260910T094102253-20504/。
- 已查看build/ui-tool-effect-details.png：地图上打开锯条也可完整阅读基础与安装效果，正文在右侧正常换行，无空目标分组或截断。

## 2026-09-10 单手套与单腿套旧项目图片恢复
域：存档。

## 2026-09-10 魔力预备卡面正文
域：压力与快感、界面。
先ListOnly核对关联分类，不截图、不改规则或存档；5594项规则断言通过，日志build/checks/20260910T093648989-42784/check-rules.log；casting窗口201项断言通过，日志同目录check-ui.log；均退出0且无引擎错误。
- encyclopedia规则262项与home,equipment_complete窗口182项通过，退出0、无引擎错误：build/checks/20260910T093429173-35384/。

## 2026-09-10 已有装备图片接入与图鉴同步
域：装备与解除、检查与测试。
- Import与初次图鉴检查通过；最终encyclopedia规则262项通过：build/checks/20260910T091512161-38776/check-rules.log。home,equipment_complete窗口183项通过：build/checks/20260910T091618740-58232/check-ui.log，无引擎错误。
- 仅截图build/ui-equipment-book-images.png，已查看列表与详情无越界，图片未拉伸。未运行all、未生成新美术、未发布或导出。

## 2026-09-10 滑脱原因区分与重复套体目标
域：装备与解除、界面。
- 规则ListOnly后composites／links及关联分类1561项通过：build/checks/20260910T091341547-59836/check-rules.log。
- 新增body_layout窗口先发现测试仍读取提交前装备引用，改为提交后真实装备查询后，完整body_layout53项通过：build/checks/20260910T091533993-56544/check-ui.log。检查重复目标消失、真实原因、拒绝不扣费、不改随机、解除阻碍后原生拖牌正确扣费和伤害。

## 2026-09-10 安全等级巡视周期
域：监狱与收押、界面。
- 已有再次入狱、钥匙暂停、巡视反抗及练习断言更新；探索界面验证行动本身不推进计时。
- 正式prison及关联分类3032项通过（build/checks/20260910T090939655-14656/check-rules.log）；练习目录equipment_complete补跑424项通过（build/checks/20260910T091146038-50680/）。
- 首轮窗口仅旧地图标题断言失败：此前布局已把“监狱 · 移动消息”精简为“移动消息”，更新为同时检查当前标题与真实map_name／region_name，未改游戏行为。最终 `tools/check.ps1 -UIOnly -UISuite prison,exploration -TimeoutSeconds 300`通过179项，退出码0，日志build/checks/20260910T091320864-42688/。

## 2026-09-10 阶段完成文案更正
域：文案与本地化。

## 2026-09-10 顶栏运行信息
域：界面、检查与测试。
ListOnly确认architecture规则与interface窗口，保留一张ui-run-header.png检查实际布局；55项规则、455项窗口断言通过，退出0且无引擎错误。日志build/checks/20260910T091120177-11388，截图build/ui-run-header.png已检查三项信息与距墙提示不重叠。
- tower_progression规则141项及实际窗口51项通过：build/checks/20260910T085912640-24064/，退出0，无引擎错误；不重复截图。

## 2026-09-10 出口、三轮续局与首领固定奖励
域：塔路与地图、战斗与敌人。
- tower_progression收录续局、清装、保留成长、实际Boss奖励、分裂／召唤生命、非法版本回滚、快照恢复与第三轮终止；关联tower／prison／rewards／enemies／persistence，继续采用单次联合分类入口。主页三条过时图鉴断言改为登记分类／实际筛选结果，不锁死数量或首条内容。
- 联合分类tower_progression,rewards,enemies,persistence,runner：7641项通过，183.21秒；日志build/checks/20260910T084731409-32240/check-rules.log。最终规则增量复验tower_progression：141项通过，日志build/checks/20260910T085450138-40688/check-rules.log。
- 最终home,tower_progression真实窗口检查133项通过，29.23秒，退出0且无引擎错误：build/checks/20260910T085607624-51156/check-ui.log。仅保留一张出口截图build/ui-45-summit-cleared.png，已查看；移除出口费用尾缀，清理之前的飘字／卡牌动画，标题和按钮无遮挡。

## 2026-09-10 捕缚条穿透状态窗口修复
域：界面、检查与测试。
- ListOnly确认status／guard完整窗口分类；85项通过、退出0且无引擎错误，日志：build/checks/20260910T085507868-47988/check-ui.log。

## 2026-09-10 回合提示魔力小数修复
域：界面、压力与快感。
- 同步清除上一动作遗留tooltip。
- `tools/check.ps1 -UIOnly -UISuite enemy_feedback -TimeoutSeconds 300`通过42项，退出码0；日志`build/checks/20260910T085249043-47604/`。

## 2026-09-10 拖牌目标透明素材与伤害提示
域：角色与美术、界面。
- ListOnly确认installed_tools／slip_motion／equipment_complete完整窗口分类，导入后136项全部通过，退出码0，无引擎错误；日志：build/checks/20260910T084809946-44880/check-ui.log。

## 2026-09-10 准备类行动日志简写
域：界面、检查与测试。
- 最终 `tools/check.ps1 -Suite action_copy,intent -UI -UISuite enemies -TimeoutSeconds 300`：195项规则与196项窗口检查通过，退出码0。日志 `build/checks/20260910T084544654-59108/`。

## 2026-09-10 扩大地图与紧凑消息栏
域：塔路与地图、界面。
- 新增主区域边界、地图宽高、消息栏宽度、遗物归属与不遮挡、悬停说明与状态不变检查；原右键绘画／缩放对齐／清除、左键拖图、正式前进、暂停和无连线拒绝回归通过。
- `tools/check.ps1 -UIOnly -UISuite route -Screenshots ui-map-expanded.png,ui-118-map-art-overview.png,ui-98-map-messages.png -TimeoutSeconds 300`：105项通过、退出码0。日志：`build/checks/20260910T083451182-29300/`。

## 2026-09-10 左下资源按捕缚状态排布
域：压力与快感、界面。
- casting旧空占位断言更新为实际魔力条边界；guard沿正式回合及拖牌验证。
- ListOnly后完整casting/guard/consumables窗口258项通过：build/checks/20260910T083016440-60364/check-ui.log。截图发现自动换行使标签下移，修正短标签并补充对齐检查后，完整consumables窗口33项通过：build/checks/20260910T083325587-57336/check-ui.log。已查看最终build/ui-mana-flask.png与build/ui-mana-flask-capture.png，无规则或存档修改，未跑无关规则或all。

## 2026-09-10 地图右键自由绘画
域：塔路与地图、界面。
- 原合法路线、拖图不移动、拒绝无连线目的地和自动旅行回归继续运行。
- 首轮 `20260910T082832946-48776` 发现总览缩放的横向标记偏移；改为与节点同用115px侧边距的归一化坐标后复跑。最终 `tools/check.ps1 -UIOnly -UISuite route -Screenshots ui-map-freehand.png -TimeoutSeconds 300` 通过99项，退出码0，日志 `build/checks/20260910T082916132-60636/`。
- 已查看 `build/ui-map-freehand.png`：暗红笔画清晰，保持纸内裁切，右下清除按钮完整可用，无额外大说明框。

## 2026-09-10 现有卡图区放大与横向比例
域：检查与测试、界面。
- build/checks/20260910T082536474-62276的casting模块201项完成，无该模块失败；同轮interface新增滚轮案例错误地选用内容已完整容纳的宽卡，导致断言失败。改用真实184×252手牌宽度，并先断言确有溢出，没有修改运行逻辑来迎合案例。
- 最终interface检查：`tools/check.ps1 -UIOnly -UISuite interface -Screenshots ui-72-unified-drawer.png -TimeoutSeconds 180`，447项通过、退出0、无引擎错误；日志build/checks/20260910T082911579-52300/check-ui.log。已查看牌组截图build/ui-72-unified-drawer.png：横向素材完整，牌名／费用／法力及下部文字未重叠。

## 2026-09-10 教程书统一简洁用语
域：界面、文案与本地化。
- 最终运行 `tools/check.ps1 -UIOnly -UISuite interface -TimeoutSeconds 300`，443项通过，退出码0；覆盖条目完整性、分类过滤、肩带搜索与焦点保持、空结果、关闭及浏览不改状态。日志：`build/checks/20260910T080420345-58232/`。

## 2026-09-10 地图取消悬停弹窗
域：塔路与地图、界面。
- 路线窗口沿实际输入等待原生提示延迟，验证所有节点tooltip为空、实际悬停无弹窗、状态和随机不变；原节点对齐、拖图不误出发、合法移动、无连线拒绝、暂停与换局计时检查保留。
- 首次build/checks/20260910T075510548-51720的规则检查有2项旧图鉴断言要求显示怪池“各50%”，因此整轮失败且未进入窗口检查；已改为核验真实皮带材质与分裂说明，保留此前所有实际抽取、分裂和保存边界测试。
- 最终build/checks/20260910T075737891-40672：3203项规则、531项窗口断言通过，退出0且无引擎错误；规则采用原日常随机集合，未运行all或Exhaustive。已查看唯一截图build/ui-map-hover-no-popup.png，悬停可前往节点时无底部长条或二级窗口。

## 2026-09-10 主页仅保留游戏标题
域：界面。

## 2026-09-10 怪物图鉴文案统一
域：战斗与敌人、装备与解除。
验证build/checks/20260910T075334248-52060：257项图鉴规则、443项interface窗口断言通过，退出0且无引擎错误；无截图。
- 更新home现有标题断言，验证左侧控件只有标题、状态不变；启动、开始新局、继续、菜单入口和窗口缩放的检查均通过。完整home窗口分类运行77项，3项图鉴筛选断言未通过（分支全集、能力稀有筛选、遗物稀有度数量），未修改本任务无关的图鉴逻辑，也不报告全分类通过。日志build/checks/20260910T074916996-49700/check-ui.log。

## 2026-09-10 战场及窗口冗余提示清理
域：界面。

## 2026-09-10 商店品质价格
域：卡牌与奖励、检查与测试。
检查通过：2525项规则、114项窗口断言，退出0且无引擎错误；日志build/checks/20260910T074101075-41596/check-rules.log与check-ui.log。
- 错误原因复用TermExplanation，在实际目标旁显示，重复校验不反复建窗，移出／结束拖动清理；提交失败仍能显示notice。
- build/checks/20260910T073239702-30648/check-ui.log中casting有三次旧文案断言失败（强欲之壶两面仍要求无消耗说明、顺延仍找旧措辞），整轮不标通过；其余七分类完成且未报错。保留独立消耗词条与当前三级顺延说明，按现行文案同步断言。
- 最终ListOnly后复查受影响casting/targeting/interface完整分类，677项通过、退出0且无引擎错误：build/checks/20260910T073714127-56296/check-ui.log。其余五类首次完整检查共570项未报错。已查看最终单张代表截图build/ui-drag-clean-battlefield.png，确认有效拖放期间顶部无文字横栏、鼠标旁只有动作名。

## 2026-09-10 玩偶与玩偶师站位
域：未在原文标注。

## 2026-09-10 卡牌悬停去冗
域：卡牌与奖励、检查与测试。
首次规则检查build/checks/20260910T073025039-21976只有henshin备注的固定短语断言失败；已在精简文案中保留明确的“同源不叠加”。同期强欲之壶改为0费消耗，复验073235551-6112中的纯抽牌测试因此需要区分抽牌与独立消耗词条；已保留新效果，并调整只读文案断言。最终复验build/checks/20260910T073539394-46376：5215项规则、200项casting窗口断言通过，退出0且无引擎错误；实际悬停和出牌验证通过，无截图。
- 先ListOnly后运行完整enemies窗口分类，197项通过、退出0且无引擎错误：build/checks/20260910T072123477-47272/check-ui.log。已查看单张截图build/ui-puppet-formation.png。

## 2026-09-10 状态合并与图标
域：界面、检查与测试。
- trader窗口旧“不得进入强怪池”的断言与项目当前versatile_trader强怪组合冲突，改为验证弱池不含、强池包含，未修改敌人池。
- ListOnly：build/checks/20260910T070703520-24580。关联规则status/rewards/intent及交叉18模块5814项通过：build/checks/20260910T070723854-7060/check-rules.log。
- 联动窗口初次1303项检查中两项失败：位置断言误取位于原点的容器而非动作按钮、玩偶说明断言查找未显示的“嘲讽”字样，实际界面分别已有正确位置与“单体攻击必须选择玩偶”。修正断言后，完整targeting/intent/status/enemies分类295项通过，退出0且无引擎错误：build/checks/20260910T071552365-60740/check-ui.log。前批其余trader/hand_assist/casting/wall/interface/pressure/guard/rewards分类未报错，不将初轮整体报告为通过。
- 截图检查补足单行状态总览高度，增加完整卡面不被滚动区域裁切的断言；最终status完整分类47项通过、退出0且无引擎错误：build/checks/20260910T071753435-24836/check-ui.log。已查看build/ui-status-icons-overview.png与build/ui-status-icons-battle.png。
- 初轮规则与窗口报告不计为通过：旧独立状态行预期和测试练习名修正前分别记录于build/checks/20260910T065844692-11396、build/checks/20260910T070108971-23664。

## 2026-09-10 强欲之壶改为0费消耗
域：检查与测试、界面。
- 修改原有规则和窗口案例，覆盖双面费用、零能量仍可打出、实际抽牌及消耗区、满手限制、过期请求原子拒绝、悬停消耗解释及预览无状态变化。初轮旧无关键词预期未通过，已同步为两面仅含消耗解释；同批还出现henshin文案断言失败，单独诊断当前源码符合原断言，未改其规则或断言，完整重跑通过。失败日志保留于build/checks/20260910T073147907-32844/。
- rewards及其完整关联规则分类5215项断言通过，日志build/checks/20260910T073453233-12084/check-rules.log，退出0、无引擎错误。
- casting完整窗口分类200项断言通过，含两面真实点击、卡面0费／消耗说明、悬停与实际消耗区，日志同目录check-ui.log；退出0、无引擎错误，无截图。

## 2026-09-10 拖牌装备图标目标栏
域：`assets/ui/equipment/SOURCE.md`。
- 悬停复用只读候选中的伤害／费用／工具加伤／具体失败原因及现有TermExplanation，保留原DropTarget提交与版本复核；拖动期间隐藏原大详情框，结束恢复。
- architecture追加一项集中资源存在性检查，原投影隔离与随机不变检查继续通过；55项通过，日志build/checks/20260910T064850470-50572/check-rules.log。
- 更新原目标栏相关断言，改为实际悬停后读二级窗口。完整targeting、equipment_complete、installed_tools、slip_motion、special_equipment、shoulder、torso_binding窗口分类204项通过，日志build/checks/20260910T065120953-58776/check-ui.log；精确命中、费用、工具磨损、链接／组件及特殊目标均沿正式操作验证。
- 扩大运行的baseline未通过：事件流程仍假设所有事件可以拒绝，休息工具夹具仍选旧foot_wall安装位置，共7项错误；日志build/checks/20260910T064850470-50572/check-ui.log。该批如实记失败，未改无关玩法或删断言，不将本次报告为全项目回归通过。
- 最后将目标栏高度增加6像素，避免单行出现多余滚动条；重跑equipment_complete完整窗口分类65项通过，无截图，日志build/checks/20260910T065249904-24724/check-ui.log。

## 2026-09-10 玩偶师与玩偶
域：未在原文标注。

## 2026-09-10 基础动作栏重制
域：检查与测试、界面。
首次检查（build/checks/20260910T064548625-56284）规则1332项通过，窗口暴露整数伤害仍带.0及文本测试未去空行两项问题；已修正简洁数值格式与对应读取断言。复验build/checks/20260910T064822318-37092：规则1332项、窗口279项断言通过，退出0且无引擎错误；截图build/ui-basic-action-rail.png已人工检查整行占位、两行内容及手牌间距。
- enemies集中覆盖正式召唤／循环、嘲讽原子拒绝、群攻、逐段伤害、零伤害、非攻击来源、准备消耗、缝补、操纵者死亡、单次奖励、快照校验及恢复后确定性；窗口分类验证独立练习、两种插图、保护／嘲讽图标、实际多段命中及T3回血。
- 只补充该测试夹具的既有类别列表，仍通过正式攻击／奖励／移动命令完成路线，不改变战斗数值或通过删除断言掩盖失败。诊断重跑路线无失败。失败日志保留于20260910T060313142-6664、20260910T060810784-55060及20260910T061428821-60636。
- 美术沿现有SVG注册表，已查看一次两种敌人的实际绘制合图build/puppeteer-preview.png；没有扩展截图回归。
- 最终相关规则分类合并检查通过7350项断言，日志build/checks/20260910T061815922-39068/check-rules.log。该批窗口首次失败是测试未先选择玩偶并翻到两段攻击，已补成真实鼠标操作；仅重跑受影响的enemies完整窗口分类，194项断言通过，退出0，日志build/checks/20260910T062209057-7564/check-ui.log。

## 2026-09-10 卡牌右上角魔力标记
域：卡牌与奖励、压力与快感。
- 首轮窗口数值断言发现默认数字格式带“.0”，已去除；保留了浮点费用精度和所有执行断言。
- 最终窗口 **917项断言通过**，退出0、无引擎错误，包含正式翻面、支付／出牌、卡组、商店、领取与卡牌动画。日志`build/checks/20260910T061714122-45756/check-ui.log`。
- 最终rewards,casting及全部关联规则分类 **6566项断言通过**，退出0、无引擎错误；日志`build/checks/20260910T061815045-60200/check-rules.log`。

## 2026-09-10 卡面关键词与束缚等级
域：检查与测试、卡牌与奖励。
- 毕业证书相关断言更新为“挣扎9／滑脱9”，继续检查遗物加值真实进入手牌与卡组。
- **6550项规则断言通过**，退出0、无引擎错误；日志`build/checks/20260910T054748184-21256/check-rules.log`。
- 首轮旧文案断言、卡组重复信号、界面夹具父节点类型及浮窗名称冲突均曾被门禁拒绝，未记为通过；已逐项修正，失败日志保留。`20260910T055337220-36564`虽完成942项断言，但退出时同步移除浮窗报错，外层门禁正确拒绝；修正为隐藏、改名及延迟释放后再检查。
- 最终casting,services,status,interface,rewards完整窗口分类 **942项断言通过**，包含真实翻面、施法、商店、奖励领取、状态、卡组与退出清理；退出0、无引擎错误。日志`build/checks/20260910T055701413-51700/check-ui.log`，本次不重复截图。
- 本批只截取并查看`build/ui-107-card-casting-tooltip.png`一次，用于确认真实手牌及说明框排版；不为每卡／每分支重复截图。

## 2026-09-10 卡牌数值、腿部目标与准备效果整合
域：卡牌与奖励。

## 2026-09-10 魔力回路
域：压力与快感、检查与测试。
rewards下的mana_circuit_cases覆盖两面并存和同面叠加、分批激活的独立余数、跨回合、两种魔力付款、失败施法、额外付款、一次跨多个阈值、后续身体受限、多段完成时发奖、复演与场次清理。
首次检查build/checks/20260910T045804182-49896因新增测试夹具耐久大于上限而出现脚本错误，未记为通过；已修正为合法耐久及上限，保留原失败日志。修正后同范围穷举规则9555项断言通过，退出0，日志build/checks/20260910T050113296-5620/check-rules.log；casting/interface窗口609项断言通过，退出0，日志同目录check-ui.log；通过真实点击和翻面检查，无截图。
- 先执行ListOnly，再执行rewards,equipment,casting,status,guard及全部关联分类，**7696项规则断言通过**；casting,status真实窗口测试**214项断言通过**。退出0，无引擎错误；日志为build/checks/20260910T044519775-49700/check-rules.log与check-ui.log。

## 2026-09-10 魔路检索总严密等级修正
域：卡牌与奖励、界面。
- rewards案例覆盖总等级0／1、头嘴及下肢反例、单侧大臂三档但总等级0、捕缚最低1、提交前变化的原子拒绝；casting窗口验证眼部有拘束仍可用、总等级1禁用及实际拘束面抽牌。
- 验证完成：先执行ListOnly，再执行rewards完整关联分类，4664项断言通过；casting窗口165项断言通过，含413次真实鼠标事件。日志位于build/checks/20260910T042421637-12720/。

## 2026-09-10 魔路检索与魔法／能力双词条
域：检查与测试、界面。
- mana_search_cases归rewards→card_power_cases唯一执行：普通池与费用、无消耗、双词条能力入手、保留未匹配顺序／随机不动、预览和版本拒绝、缺目标／不足／空堆洗牌／满手牌、精准上半身1档／0档与腿部反例、无魔力高压力下技能照常使用、复演、当前快照及定义拒绝。
- 首轮Exhaustive完整种子检查8244项无断言失败，但零档口部装备夹具尚未走正式清理就枚举候选，产生4个引擎错误，整批记失败。首轮日志：`build/checks/20260910T035954622-52640/check-rules.log`。
- 日志：`build/checks/20260910T040203546-53652/check-rules.log`。
- 本批窗口casting,interface **567项通过**，退出0、无引擎错误；日志：`build/checks/20260910T040203546-53652/check-ui.log`。未生成截图，未运行全项目回归。

## 2026-09-10 当前进度与架构接口跟进
域：架构与接口、检查与测试。
- 新增真实三链接、三替代连接点用例，旧实现21次连接点查询触发性能断言，修正后不超过12次，保留结果、顺序、状态与随机不变。
- 修改前相关24个分类6272项通过，日志build/checks/20260909T194624490-54464/check-rules.log。新增性能用例首次因测试插入位置错误产生语法错误（194817784-54892）；修正后准确复现21次冗余查询并仅性能断言失败（194829500-14704）。修正算法后相关24类6300项通过（194929834-53284）；以上失败日志保留，不记为通过。
- 旧常量清理后，architecture/core/links/pressure/tower及关联28个分类6995项通过，118.13秒，退出0；日志build/checks/20260909T195133543-52656/check-rules.log。
- casting/services/status/interface/rewards五个窗口分类854项通过，退出0、无引擎错误；日志build/checks/20260909T194955105-15928/check-ui.log。
- 追加检查195401885-38044准确发现旧手动续段案例换用peel时误把payload.kind也改为peel，导致候选为空及后续越界；此轮失败，未进入窗口阶段。最终当前定义的rewards及关联13个规则分类4546项通过，无引擎错误，复用共享工作区日志build/checks/20260909T195554335-54280/check-rules.log；同批casting 142项、rewards 179项无断言失败，但该并行任务额外的存档窗口失败导致整轮UI退出失败；本轮没有检查或修改其存档问题，也不把这次整体失败记为PASS。另用仅含casting／rewards的窗口检查独立确认，321项（142＋179）通过，112.69秒、退出0且无引擎错误；日志build/checks/20260909T200009099-12476/check-ui.log。
存档专项继续延期到整个Demo完成后，本轮没有修改存档实现或专项案例。README、AGENTS和内容扩展文档同步；最近两处并行记录错位的章节标题已归位，历史内容与失败记录保留。

## 2026-09-10 四种漂浮敌人插图
域：战斗与敌人、角色与美术。
- 删除旧敌人图集加载、区域映射、裁图函数与无用抠色分支，未删除原资源文件。
- 受影响窗口分类一次验证：`tools/check.ps1 -Import -UIOnly -UISuite enemies,guard,hero_art -TimeoutSeconds 300`，**236项通过**（enemies185、guard27、hero_art24），退出0，无引擎错误。日志：`build/checks/20260909T195419225-47060/check-ui.log`。
- 人工核对单张4敌人总览：`build/floating-enemy-preview.png`，实际arena渲染完整且无裁切。用户警卫原图修改前后SHA256一致：紫色B26789330D06D718CF2C3706263F0858E3EE721AC392DB60BC3B6CEB45E38148；棕色598562AE70145A1A2C882796F9626AA5D0321163E2A9E2861A43A610A217D1D2。

## 2026-09-10 默认卡面插图替换
域：角色与美术、卡牌与奖励。
- `tools/check.ps1 -Import -UIOnly -UISuite interface -TimeoutSeconds 300` 通过：**409项**，退出0、无引擎错误。日志：`build/checks/20260909T194548912-14248/check-ui.log`。
- 仅渲染并人工检查一张24图总览：`build/card-art-preview.png`，各图轮廓、颜色、缩放和中文名称清晰，无裁切。

## 2026-09-10 连续挣
域：界面、检查与测试。
- 本次完整种子检查中新增连续挣案例通过，但并行开发的余势复演出现3项失败，因此整轮失败，见build/checks/20260909T194011928-38112/check-rules.log。随后共享工作区联合规则检查已通过5950项，包含rewards1090项及相关分类且无引擎错误，见build/checks/20260909T194142849-51972/check-rules.log；复用该已完成结果。
- 同期拖牌入口改为候选ID区分同一装备的多个行动选项，窗口助手仍按物理ID查找导致1项报错。修正后本任务单独复查casting窗口136项全部通过，退出码0，无引擎错误；日志build/checks/20260909T194343851-45204/check-ui.log。未生成截图或运行全项目回归。

## 2026-09-10 余势复演
域：`tests/echo_cast_cases.gd`。
- 覆盖费用、原控火保留、两面与排除、预览只读／过期回滚、失败留手、独立施法、猛火下山抽牌、余火消耗后的重算、群体及装备火球、致死跳过、工具每牌一次、技能计数、上下层不改目标、多段与顺延、重复能力回合效果、跨回合／场次清理、连续状态恢复及坏字段拒绝。
- 初轮完整种子检查8093项无断言失败，但新夹具当前耐久30误配默认上限10，产生1个引擎错误，整批失败；第二轮8153项有3个夹具断言失败：自动续段被误当作等待玩家、低紧度外层用了不满足最高紧度资格的挣扎。两轮完整enemy_cycle 16/16、enemy_pool 24/24种子均已跑完；不能把失败批次标成通过。
- 日志：`build/checks/20260909T194142849-51972/check-rules.log`。此前完整种子矩阵日志：`build/checks/20260909T194008465-8004/check-rules.log`；修正只涉及测试夹具，最终无需重复随机矩阵。
- 最终窗口casting **136项通过**，退出0、无引擎错误；日志：`build/checks/20260909T194241262-52652/check-ui.log`。窗口先补导入并行新增的连续挣SVG，再将该用例的拖牌目标参数由装备ID纠正为正式候选ID；余势复演窗口检查无失败。

## 2026-09-10 猪神之皇焚与三级顺延
域：装备与解除、界面。
- follow_through_cases由rewards下card_expansion唯一接入：费用与两面文字、无随机自由面、预览／过期／不足费用原子拒绝、原件五段不转移、指定位置内层显露优先、其余分段先于区域、脚趾纳入腿区、无目标停止、不跨区域、后继只选外层、确定性恢复与独立随机域、单牌工具一次、逐段蓄力、真实手掌／手指与脚掌／脚趾左栏分组。
- 第一轮完整种子矩阵6591项无断言失败，但新测试用普通安装器传入不支持的单侧手指精确点，导致夹具为空而出现1个引擎错误，整轮按失败处理；修正夹具为普通手指正式覆盖，并补齐用户确认的左栏大部位分组。日志build/checks/20260909T192634056-51480/check-rules.log。
- 修正后rewards及全部关联日常分类4413项通过，casting窗口114项通过，退出码0且无引擎错误；日志build/checks/20260909T192948088-54340/check-rules.log和check-ui.log。
- 日志：`build/checks/20260909T192757726-7980/check-rules.log`、`check-ui.log`。

## 2026-09-10 猛火下山
域：卡牌与奖励、检查与测试。
- 能力模板开放原cast／mana_cost字段；统一施法入口先结算，再在成功后移入能力区，失败付费但保留原手牌，临时魔力／快感倍率／定咒及零概率拦截照原流程。
- 群体只触发一次，装备目标也触发，失败使用仍抽牌；其他法术和无效／过期请求不触发。
- 规则覆盖双面费用与嘴部零概率、失败留手、临时池重试、无自触发、普通／群体／失败／装备目标抽牌、同名能力去重、存取后的连续使用、10张上限、空堆重洗及致死清理。UI使用真实翻面、悬停成功率、点击激活与火球术，断言费用、能力区、实际手牌增长和文字高度。
- 首轮扩展检查日志`build/checks/20260909T192601551-55884/check-rules.log`：8025项断言无失败，但关联follow_through测试的手指夹具用了不被普通安装接受的fingers_left参数，访问空对象时报1处引擎错误；未把该轮记为通过。

## 2026-09-10 灵活变通
域：卡牌与奖励、压力与快感。
- 日志：`build/checks/20260909T191927966-48544/check-rules.log`、`check-ui.log`。
- 新规则案例覆盖正式付款、旧版本与资源不足原子拒绝、延迟到下回合、无上限魔力池、飘字收据、同面拒绝、双面同时触发、同版本还原后的后续回合一致性、场次清理以及整备／休息／牢房正式结束回合。

## 2026-09-10 控火与独立临时魔力池
域：压力与快感、界面。
- 最终窗口casting／status／rewards共292项通过，含真实出牌、永久加伤、10点临时魔力、状态寿命、魔力条点数显示与卡面高度：`build/checks/20260909T191236306-52240/check-ui.log`。
- 候选和提交共享付款拆分：卡牌、火球及牢门开锁优先抵扣，再扣自身；固定魔力转换适用，失败照付。
- 控火单独完成时，规则扩展样本7836项、窗口279项通过，日志`build/checks/20260909T190433886-49696/`。随后临时魔力整批扩展检查`build/checks/20260909T191058312-49352/check-rules.log`共9219项，6项失败均为新增临时池测试夹具：未排除开场遗物的结束恢复，以及未清掉第二只敌人；其余分类通过。修正夹具后按casting、consumables及关联完整分类复查3001项全通过：`build/checks/20260909T191236306-52240/check-rules.log`，包含小数、无上限、付款不足原子拒绝、旧版本拒绝、失败施法、固定转换、遗物实际支出、商店及魔瓶隔离、各场次清空与同版本存取。

## 2026-09-10 余火
域：压力与快感、卡牌与奖励。
- free复用next_attack增益并将base_bonus=4接入火球基础伤害计算；同源不叠加，失败保留，整次群攻成功后一次消耗，装备自解分支也消耗。
- 规则用例归入原rewards卡牌扩展，验证5／9.9／10魔力边界、0能量可施法、临时池和耳坠、伤害倍率前加值、群攻整波、同源拒绝、火球失败保留、装备自解半伤和消耗、双面失败扣首次费用并留牌；窗口casting实际点击验证普通卡、手部要求及双次抽牌付款。
- `rewards,casting,basic_attacks`及关联分类5903项全部通过：`build/checks/20260909T193222310-51720/check-rules.log`。
- `basic_attacks,casting`窗口132项通过，脚本退出0、无截图：`build/checks/20260909T193222310-51720/check-ui.log`。

## 2026-09-10 死灰复燃与通用失败留牌
域：界面、检查与测试。
- 用户后续明确修改全部卡牌法术：Cards.play在任何实体牌移动之前统一施法，失败照付、留手、保留原顺序与保留期限，没有离手动画或成功出牌计数；消耗牌亦然。
- 沿既有casting和rewards用例更新失败断言，补充同一实体卡失败留手、无动画、保存恢复与重新成功的覆盖；死灰复燃用例验证耗尽后实际刷新并再次施放、3／4次数上限、两面、1＋10付款、手部阻止、失败不刷新、旧候选拒绝。UI实际点击普通刷新和消耗牌失败后重试，无截图。
- 新卡初版规则5731项通过：`build/checks/20260909T191810321-38608/check-rules.log`；同轮窗口仅首次火球悬停断言失败，补上先移出再移入以真正触发悬停。用户补充通用规则后，首轮3047项仅一处新增多段卡的文字格式断言失败：`build/checks/20260909T192209105-52040/check-rules.log`；将原只接受“6点”的断言扩展为接受准确的“6×5点”，保留真实基础值和段数校验，不改该卡规则。
- 最终规则`casting`及关联分类3047项通过、退出0：`build/checks/20260909T192336459-46380/check-rules.log`。
- 导入后的窗口中，失败留牌／重试和死灰复燃用例均通过；仅并行新增顺延卡测试把物理装备ID当作拖放候选ID，导致定位断言失败（实际后续行动通过）。按现有drop_targets候选键取正式candidate.id修正测试，不改游戏逻辑；日志`build/checks/20260909T192600244-55380/check-ui.log`，basic_attacks 16项已通过并保留结果。
- 最终casting窗口114项全部通过、退出0、无截图：`build/checks/20260909T192744292-51796/check-ui.log`。

## 2026-09-10 火动力学
域：`tests/fire_dynamics_cases.gd`。
- `tests/fire_dynamics_cases.gd`挂在rewards既有能力测试内，覆盖2费、封顶、口部零倍率后的独立加区、其他法术不变、精通共存、双面／去重、当前格式恢复、场次清理、群攻付款及一次使用、魔法对机械全伤、分裂子代不追击、失败全体无伤、炫火单目标。
- 首次运行恰逢并行临时魔力字段迁移，旧reserve_mana读取失败，已停止该次运行。随后`rewards,casting,basic_attacks`及关联分类共5720项，除临时魔力专项6项外其余通过，火动力学无失败；日志`build/checks/20260909T191104468-53092/check-rules.log`。
- 窗口`casting,basic_attacks`共97项通过、退出0，无截图：`build/checks/20260909T191213155-24068/check-ui.log`。
- 修正后`casting`及关联分类3001项全部通过、退出0：`build/checks/20260909T191309169-56024/check-rules.log`。

## 2026-09-10 休息处六回合与入场增益
域：卡牌与奖励、装备与解除。
- 规则覆盖实际卡牌与魔瓶领取、三条时长、原有装备不阻止选择、选择前无开场效果、选择后仅一次抽牌／补能／遗物、绿色小鸟从实际第1回合计数、无快感或回合末补魔的虚假跳过、魔瓶1000→1050且自身魔力不变、查看不重抽、旧版本重复提交拒绝、选择后不能再领、剩余回合耗尽退出。
- 首轮基础／服务／压力／奖励批次5556项中的6项失败来自未更新的路线假设（含1处后续空敌人访问），第二轮物品／部件／核心／路线批次4966项中9项失败来自剩余监狱路线入口假设；各已通过分类保留结果。日志分别`build/checks/20260909T185241943-53564/check-rules.log`、`build/checks/20260909T185508860-47188/check-rules.log`。修正后的prison/tower_progression及关联分类1962项全部通过：`build/checks/20260909T185717360-54536/check-rules.log`。
- 窗口services98项、prison120项通过：`build/checks/20260909T185717360-54536/check-ui.log`。该批仅旧pressure断言把既有魔瓶入口误判为多余操作；按现有规则排除魔瓶，并修正测试内同名局部变量后，pressure41项全通过、脚本退出0：`build/checks/20260909T190124235-53368/check-ui.log`。

## 2026-09-10 炫火、火球次数与火焰精通费用
域：装备与解除、界面。
- 敌人与装备共享次数、施法与付款；失败计次，过期／不可用提交不计次。火焰精通两面统一2费，实际卡面与不足2费拒绝同步验证。
- 新案例flame_flourish_cases由rewards下card_power唯一接入，覆盖两面共存、同面拒绝、三次封顶、回合内加一次、跨目标共用、换回合、场次清理、当前快照、只读与过期回滚、锁定件直接扣耐久、倍率取半、外层遮挡／破坏及付费失败。
- 首轮rewards/casting/content完整种子矩阵7867项中4项失败：两处装备断言读取了事务前引用、一处外层夹具选到了不同精准位置，及扩大卡池后原32种子未覆盖全卡；均修正为提交后按ID取目标、显式同部位夹具、按卡池规模设置有界抽样。该轮其余分类通过，日志build/checks/20260909T190733187-40504/check-rules.log。
- 日志build/checks/20260909T191122603-49452/check-rules.log及check-ui.log。

## 2026-09-10 henshin自由面不可叠加
域：界面、检查与测试。
- 确认原共享增益逻辑已按稳定来源去重，重复自由面在付款前拒绝，保留该实现。
- 沿card_expansion既有实际重复使用、整份状态不变、伤害倍率、战斗结束清理及被动伤害案例补充显示断言。日志`build/checks/20260909T184750323-49332/check-rules.log`与`check-ui.log`。

## 2026-09-10 开信刀play
域：界面、装备与解除。
- 导入成功，ListOnly确认后rewards及关联完整分类以Exhaustive通过6372项，日志`build/checks/20260909T184205458-49588/check-rules.log`。
- 完整窗口casting最终通过63项，日志`build/checks/20260909T184521459-41396/check-ui.log`；status30项及rewards179项已在前一窗口批次完成。

## 2026-09-10 奥利哈基米
域：存档、检查与测试。
- 零费与魔瓶转移不标记，付费失败仍标记，恢复魔力不撤销。
- 新用例覆盖真实结束回合、实际火球付款后饮药、零费准备、魔瓶转移、耳坠阈值归零、付费施法失败、回合中途拾取、恢复封顶、四类回合生命周期、同版本读回及损坏字段原子拒绝。
- 本遗物用例最终无失败；完整status/rewards窗口通过209项，日志`build/checks/20260909T183914781-37496/check-ui.log`，验证悬停品质／条件、真实结束回合恢复8及施法后不恢复。
- 共享奖励分类整合门禁尚未全绿：`build/checks/20260909T183914781-3636/check-rules.log`共6344项，3项断言失败及4条引擎错误均来自并行新增的letter_opener_cases；该轮不能记作通过。

## 2026-09-10 绿色小鸟
域：检查与测试、卡牌与奖励。
- 首轮rewards/pressure关联4970项中9项失败均来自新牢房夹具将倒计时设为非法10，正式行动被拒绝；修正为正式初始倒计时，其余分类通过。首轮日志`build/checks/20260909T183032721-5724/check-rules.log`。修正后rewards及其关联全分类4085项通过：`build/checks/20260909T183239129-50128/check-rules.log`；pressure及其他无变化分类未重复。
- status证据`build/checks/20260909T183447757-22020/check-ui.log`，rewards最终证据`build/checks/20260909T183604714-3784/check-ui.log`。

## 2026-09-10 红烧鱼香茄子
域：界面、检查与测试。
- ListOnly后导入及rewards关联分类首轮4032项，仅同时修改中的触手朋友3项失败；本次新遗物和其他分类通过。日志：`build/checks/20260909T182213323-53140/check-rules.log`。触手朋友夹具更新后单独复查受影响consumables完整分类，120项通过：`build/checks/20260909T182429727-55732/check-rules.log`，本任务未修改其代码或夹具。
- rewards完整窗口166项通过：`build/checks/20260909T182405813-36264/check-ui.log`。

## 2026-09-10 触手朋友
域：装备与解除、界面。
- 初轮consumables/installed_tools/rewards/content及关联Exhaustive执行6294项，3项新案例失败：测试临时改口部装备等级后未恢复结构，以及给不存在的独立颈部模板构造夹具；该轮不视作通过。修正为还原口部结构、以真实颈肩接触点验证范围，consumables先通过117项；再补充真实旧工具取回及手部状态不变案例，并覆盖special_equipment完整分类和关联接口，最终通过2320项，日志`build/checks/20260909T182416401-26048/check-rules.log`。其他未变分类已在`build/checks/20260909T182058439-32992/check-rules.log`完成。
- 完整status/consumables/rewards窗口通过223项，日志`build/checks/20260909T182302963-54600/check-ui.log`。

## 2026-09-10 爆炒麻辣米线
域：卡牌与奖励、检查与测试。
- 首轮3986项中仅客房事件的2项旧测试失败：随机奖励抽到了改变魔力上限的遗物，与该夹具固定92上限的假设冲突；其余分类（包括新遗物完整规则用例）通过。日志：`build/checks/20260909T181633502-14512/check-rules.log`。
- 受影响event_flow分类复查302项全通过：`build/checks/20260909T181832905-53992/check-rules.log`。
- 完整status/rewards窗口检查193项通过：`build/checks/20260909T181832905-53992/check-ui.log`，真实奖励进入整备获得蓄力，遗物横栏图标／悬停与现有状态投影正确。

## 2026-09-10 传单
域：卡牌与奖励、检查与测试。
- rewards/services/content及关联分类以Exhaustive完成首轮，6333项断言无失败，但新商店夹具误调用仅测试Game支持的_gain_relic，出现1条引擎错误，该轮未视作通过。修正为正式RelicEffects.gain后，受影响services及其全部关联consumables/shop_release/rewards分类通过1146项，日志`build/checks/20260909T180728221-42056/check-rules.log`；其他分类已在`build/checks/20260909T180620998-31860/check-rules.log`完成。
- 覆盖真实路线进入商店／宝箱、连续不同商店、1000魔瓶余量继续增加、只读页面、过期进入命令原子拒绝、重开不补发、店内拾取不追溯、普通池实际抽取、可扩展字段及超界拒绝。
- 完整窗口services/status/rewards通过279项，日志`build/checks/20260909T180728221-42056/check-ui.log`。

## 2026-09-10 成王之礼精装修订重置版
域：界面、卡牌与奖励。
- 完整rewards、basic_attacks、content及关联分类通过3750项，日志`build/checks/20260909T180151538-31668/check-rules.log`。
- 窗口basic_attacks通过16项、enemies通过182项，同目录check-ui.log；该批随后加载rewards时因并行新增图标引起ART资源解析失败，未计整批通过。统一重新导入后完整rewards通过157项，日志`build/checks/20260909T180535409-49700/check-ui.log`。未截图或运行存档专项。

## 2026-09-10 滚木
域：卡牌与奖励、界面。
- ListOnly确认范围后，rewards/services/content及关联完整分类以Exhaustive通过6309项，日志`build/checks/20260909T175626751-38324/check-rules.log`。
- 完整窗口services/status/rewards通过271项，日志`build/checks/20260909T175626751-27220/check-ui.log`。真实点击验证奖励重复领取及三个独立商品扣费／售罄，图标数量和悬停说明正确；已查看`build/ui-rolling-log.png`。

## 2026-09-10 大理石
域：界面、卡牌与奖励。
- 完整rewards及关联分类通过3586项，日志`build/checks/20260909T174413035-48612/check-rules.log`。
- 完整status、rewards窗口分类通过169项，日志`build/checks/20260909T174413035-48612/check-ui.log`。未截图、未运行全项目或存档专项。

## 2026-09-10 优秀学员毕业证书
域：卡牌与奖励、检查与测试。
- 既有JSON加载器支持可选card_base_bonuses，校验真实有基础伤害的卡牌ID、非空对象及1—100整数，批次失败不提交。
- ListOnly确认范围后运行Import与rewards/content/services完整分类；修正捕缚测试为正式guard练习的三回合施加流程，并将三档反例分开断言卡牌免疫与环境真实伤害。最终`-Suite rewards -Exhaustive`及关联完整分类通过5767项，日志`build/checks/20260909T174036305-50028/check-rules.log`；生成域完整矩阵保留。
- 完整窗口services/interface/rewards通过598项，日志`build/checks/20260909T173712127-51936/check-ui.log`。真实鼠标操作验证两张手牌及卡组均显示9、遗物悬停显示罕见和＋4、查看不改变游戏状态；已查看`build/ui-graduate-certificate-deck.png`。规则覆盖实际装备／捕缚伤害、原有倍率、三档免疫、锁与堆叠、其他牌不变、自由面不变、重复授予、失效命令原子拒绝、新局不受影响及内容加载正反例。

## 2026-09-10 一只小猪
域：界面、装备与解除。
- 完整rewards、wall及关联分类通过4155项，日志`build/checks/20260909T172813464-4548/check-rules.log`。新案例验证真实折扣起身、离墙仍有效、无墙边界、蒙眼探索不掷摔倒骰、实际位移及远程工具拒绝；沿现有wall分类并登记rewards关联，不另建启动器。
- 完整wall、status、rewards窗口分类通过209项，日志`build/checks/20260909T173112340-47616/check-ui.log`。

## 2026-09-10 遗物靠左与对白自动关闭
域：卡牌与奖励、界面。
- 先ListOnly确认范围，再运行`./tools/check.ps1 -UIOnly -UISuite action_copy,rewards,casting,interface -Screenshots ui-77-dialogue-action-log.png,ui-relics-after-dialogue.png -TimeoutSeconds 240`，577项断言通过。日志`build/checks/20260909T171155900-52752/check-ui.log`。

## 2026-09-10 小宝石
域：界面、检查与测试。
- 完整rewards及关联分类通过3328项，日志`build/checks/20260909T170925732-54160/check-rules.log`；覆盖四类场次首回合、准备背包／预备能量／甜甜圈叠加、真实战后进入整备及过期提交拒绝。
- 完整status、rewards窗口分类通过153项，日志`build/checks/20260909T171249932-11148/check-ui.log`。

## 2026-09-10 场景遗物横栏与顶部精简
域：卡牌与奖励、界面。
- 先ListOnly确认casting、services、interface、rewards窗口范围；Import与上述完整窗口分类通过637项断言。日志：`build/checks/20260909T170204373-40596/check-ui.log`。已查看`build/ui-relic-turn-counter.png`、`build/ui-55-relics-scrolled.png`及`build/ui-97-shop.png`。

## 2026-09-10 欲望魔方
域：装备与解除、卡牌与奖励。
- 替换只在成功提交时计新装备，预演不发放，失败整组回滚。
- `./tools/check.ps1 -Suite rewards,application -TimeoutSeconds 300`及关联分类通过3442项，日志`build/checks/20260909T165702510-53284/check-rules.log`。补充完整replacement及关联分类通过674项，日志`build/checks/20260909T165827838-51036/check-rules.log`。覆盖实际敌人施加、各类安装、奖励池、上限、拒绝安装、预演只读、替换提交、重复提交拒绝和原子回滚；遗物说明与触发日志同步。

## 2026-09-10 开心小fa与累计遗物计数器
域：卡牌与奖励、界面。
- `-Suite rewards,services,content -Exhaustive`及关联分类通过5937项，日志`build/checks/20260909T164804106-48488/check-rules.log`。新增实际结束回合、战斗结束保留2回合进度、领奖进入整备触发第三回合、补能叠加、过期命令拒绝、非玩家回合不计、重复授予不清进度和新局归零检查；新遗物可由真实一般池取得，日志含实际触发与能量收益。
- 完整窗口services、status、rewards分类通过197项，日志`build/checks/20260909T164804106-48488/check-ui.log`。已查看`build/ui-relic-turn-counter.png`和`build/ui-relic-turn-trigger.png`。

## 2026-09-10 商店固定品质货位与扩容
域：卡牌与奖励、界面。
- `-Suite services,rewards -Exhaustive`通过5841项，日志`build/checks/20260909T162241088-53928/check-rules.log`。
- 首轮窗口测试暴露日志侧栏挡住魔瓶付款；改用原日志浮窗后，完整services、consumables窗口分类通过116项，日志`build/checks/20260909T162538765-53212/check-ui.log`。已查看`build/ui-97-shop.png`、`build/ui-shop-1280.png`、`build/ui-shop-flask-payment.png`。早期失败不计通过，未修改存档实现或兼容旧档。

## 2026-09-10 各界面视觉统一
域：界面、卡牌与奖励。
- 完整窗口分类home、interface、body_layout、status、services、events、rewards、route、consumables通过837项，日志`build/checks/20260909T160944841-42100/check-ui.log`。替换遗物旧的按文案查找且可能不执行的滚动检查，改为断言真实持有卡片数量及最后一张可完整滚动到达。
- 底框收紧后重跑完整route、consumables窗口分类，通过112项，日志`build/checks/20260909T161242469-53748/check-ui.log`；已查看`build/ui-shop-flask-payment.png`，确认商店魔瓶紧凑、付款入口保留。

## 2026-09-10 贴身魔瓶、双来源商店付款与左下紧凑布局
域：卡牌与奖励、界面。
`-Import -UIOnly -UISuite consumables,interface`通过394项窗口断言，日志`build/checks/20260909T154300718-51408/check-ui.log`。已查看`build/ui-mana-flask.png`和`build/ui-mana-flask-capture.png`，确认正常／捕缚两种状态下数字、魔瓶与按钮无重叠；未修改规则结算。
完整consumables窗口分类25项通过，日志`build/checks/20260909T153723331-50604/check-ui.log`；已查看更新后的`build/ui-mana-flask.png`，确认魔瓶比按钮醒目，且不遮挡捕缚条、能量和抽牌堆。
数值反馈与抽牌／能力动画位置同步，存档运行代码未扩展。
- `./tools/check.ps1 -Suite consumables,services,core,pressure`及全部关联分类通过2363项规则断言，日志`build/checks/20260909T152118299-55004/check-rules.log`。之后补充嘴部减效下小数缺额补满的边界处理，重跑完整受影响分类`consumables,services,core`通过1222项，日志`build/checks/20260909T152627335-54020/check-rules.log`。
- 覆盖2次上限／实际新回合重置、部分余额与百万储量、取出不限次数、药剂嘴部整数边界、半点缺额、站姿与握持限制、坐姿豁免、领奖和打断阶段可存入、预览只读、过期／重复操作拒绝、存储不触发耗魔遗物、商店全额扣魔瓶且不混付、售罄／余额不足不结算以及删牌／解除服务。
- `./tools/check.ps1 -UIOnly -UISuite consumables,services,casting,rewards`通过182项窗口断言，日志`build/checks/20260909T152335518-46708/check-ui.log`。已查看`build/ui-mana-flask.png`、`build/ui-mana-flask-capture.png`、`build/ui-shop-flask-payment.png`。
- 过程修正：原分段卡牌／巡视／打断断言只允许阶段行动，现保留原限制并允许用户明确要求的全局魔瓶；原“全部遗物”窗口夹具只注入随机奖励池，遗漏新增专属来源遗物，改为注入正式TYPES全集。早期失败不计为通过；未运行全项目all或存档专项。

## 2026-09-10 偷渡商人的魔药箱
域：事件、界面。
- 联合规则门禁`tools/check.ps1 -Suite content,events,event_flow,tower,consumables -TimeoutSeconds 300`覆盖20个关联模块，3771项通过，记录`build/checks/20260909T160440389-17680/`。事件窗口`tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`通过96项，记录`build/checks/20260909T160620555-51340/`。

## 2026-09-10 战后战利品领取界面
域：`ui/reward_screen.gd`。
- 规则：`./tools/check.ps1 -Suite core`及其完整关联分类通过1004项断言，其中rewards为470项。新增battle_reward_cases覆盖三种领取顺序、实际入包、重复与过期拒绝、只读投影、随机不重抽、继续放弃及下一战重置；原容量、阶段与出口案例已按明确领取／继续更新。日志：`build/checks/20260909T143612681-54680/check-rules.log`。
- 窗口：`./tools/check.ps1 -UIOnly -UISuite rewards,consumables,prison`通过196项断言；包含鼠标真实点击奖励行／返回／领取、卡牌右键翻面、灰置已领项和出口继续。日志：`build/checks/20260909T143345630-41204/check-ui.log`。已人工查看`build/ui-reward-list.png`、`build/ui-54-reward-cards.png`和`build/ui-reward-claimed.png`，无文本越界或遮住领取按钮。
- 宽范围检查`core,rewards,tower_progression`并未全绿：日志`build/checks/20260909T143420215-14660/check-rules.log`记录13个断言失败及1个额外脚本错误。事件路线助手原本假定所有事件都能拒绝，现改为提交实际合法事件步骤，上述1004项复核已通过；另有两项关联存档检查仍按“掉落遗物必已入包”的旧假设拒绝未领取奖励，按用户暂缓存档要求未修改存档运行代码。该轮强怪组合案例还出现drone_pair、ominous_circle_pair、serpent_weak及数量索引失败；同目录敌人测试在检查期间有并行修改，本轮未处理或标记其为通过。
- 本批未运行全项目all回归，未启动存档专项、兼容或迁移；没有把宽范围失败当作通过。

## 2026-09-09 全目录架构检查与精简
域：架构与接口、检查与测试。
存档专项按用户最新要求延期；只读依赖扫描经过文件名，不据此认定存档机制已验收。
| 工具、内容与资源 | 4个PowerShell及4个Python工具通过语法检查；实际内容包1份与模板5份通过原内容校验。核对场景、资源路径和脚本UID，未发现缺失静态资源引用或重复UID；60张PNG／SVG无完全相同文件。不重新处理素材，不清理未知动态资源。检查器的故意报错与超时反例均正确拒绝。 |
过程中的失败与复核：
- 首轮全窗口的基础长路线未处理新增掉落带来的pack阶段；最终到达出口断言失败。
- 新塔路说明案例的局部变量与已有变量重名，修正命名后重新执行完整所选分类，没有删断言。
- 替换专项最终671项通过，包含密集强装备提前拒绝、密集弱装备保持合法替换、等价链接转接去重、纯查询不变以及完整原子提交。日志：build/checks/20260909T124325413-54064/check-rules.log。
- runner专项20项通过；故意脚本错误和1秒挂起反例均未误报PASS，日志：build/checks/20260909T122821197-40904/。
- 41个非存档、非正常试玩规则分类使用完整原随机矩阵，10771项断言通过（enemy_cycle 16/16、enemy_pool 24/24、tower_graph 201/201）；日志build/checks/20260909T123752550-46596/check-rules.log。
- 最终42个非存档规则分类一次运行全部通过：12308项断言，1717.56秒，Godot退出码0；完整enemy_cycle 16/16、enemy_pool 24/24、tower_graph 201/201。日志build/checks/20260909T124419823-26252/check-rules.log。normal_play保留原3个种子，共1534项断言：42／cautious执行572步到达prison_end，20260906／elite执行422步通关，7／trade执行531步到达prison_end；全部最终状态校验通过，没有到达1800步上限。
- 34个非存档窗口分类已分批复核，最终合计3922项断言无未处理失败。首轮全窗口3918项仅rewards中1条旧施法断言失败，其余32个分类3810项通过、casting 58项通过；日志build/checks/20260909T124429381-48580/check-ui.log。之后完整rewards＋casting共112项通过（54＋58），日志build/checks/20260909T130227183-51132/check-ui.log。中间一次复核仍引用旧原因句而失败，已改为当前具体手掌／手指条件；失败日志130056704-53684保留。本结论是最终分类结果合计，不把首轮失败运行记为整体PASS。
本轮已减少无效枚举和等价预演，现有功能断言通过也不代表这一性能问题已完全解决。

## 2026-09-09 当前框架与接口复查（首领、施法及捕缚接入后）
域：架构与接口、战斗与敌人。
- 范围收缩前的基线运行：`tools/check.ps1 -Suite architecture,casting,rewards,enemies,persistence,runner -Exhaustive -TimeoutSeconds 600`，7789项通过，150.66秒；日志`build/checks/20260909T115148385-51796/check-rules.log`。
- `tools/check.ps1 -Suite architecture,enemies -UI -UISuite enemies,casting,status -TimeoutSeconds 600`：规则2390项通过（69.97秒），其中architecture 31项；采用原日常抽样，生成算法未修改。日志`build/checks/20260909T115702544-48120/check-rules.log`。
- 同次窗口运行269项中，施法提示悬停1项失败；status 30项与enemies 182项无失败。该案例翻面后直接取卡牌矩形中心，改为沿既有card_point先移出再移入，明确触发原生悬停；保留提示断言，增加实际投影概率与悬停不改变状态的检查，不改运行时施法或UI行为。关联日志为同目录`check-ui.log`，不将这次失败运行记为整体通过。
- `tools/check.ps1 -UIOnly -UISuite casting -TimeoutSeconds 300`复查58项通过，Godot用时18.40秒；日志`build/checks/20260909T120003276-54228/check-ui.log`。最终关联窗口分项合计270项（58＋30＋182）无未处理失败，非一次全窗口运行。

## 2026-09-10 单侧手部区域计分
域：装备与解除、检查与测试。
- `tools/check.ps1 -Suite equipment_complete,consumables,status,hand_assist,basic_attacks -TimeoutSeconds 300`及自动关联分类通过2953项，44.23秒。日志：`build/checks/20260909T155427517-50836/`。

## 2026-09-10 药剂姿势限制
域：塔路与地图、检查与测试。
- 现有consumables分类覆盖三种药剂的0／0.5／1边界、站姿拒绝不扣资源、双手无法握持时坐姿全效和躺姿嘴部半效实际使用、物品说明投影；嘴部单独拘束仍可站着喝，卷轴坐姿仍需原操作部位资格。
- `tools/check.ps1 -Suite consumables -TimeoutSeconds 300`：50项通过，2.50秒；日志`build/checks/20260909T150102495-8036/`。
- 扩大分类`consumables,pressure`未全绿：药剂50项与pressure118项无失败，关联事件检查出现room_events.gd缺少choices字段等错误，最终7/1171断言失败、56引擎错误；日志`build/checks/20260909T150013292-50352/`。同文件行动回滚处两行多余缩进已纠正；此前脚本加载失败已随后续成功运行排除。

## 2026-09-10 强怪组合扩充
域：检查与测试、存档。
- 最终运行 `tools/check.ps1 -Suite enemies -TimeoutSeconds 300`：2394项断言中2393项通过，新增组合及去重检查通过。按用户暂缓存档工作的要求保留失败记录，不改存档、不跳过断言。
- 日志：`build/checks/20260909T143635636-32492/check-rules.log`。此前两轮分别修正旧的奴隶贩子不入池断言、未注册练习夹具及不应依赖战场显示顺序的组合断言。

## 2026-09-09 状态牌分类
域：检查与测试、界面。
- 运行 `tools/check.ps1 -Suite curses,encyclopedia,status -UI -UISuite home -TimeoutSeconds 300`，相关规则2186项、首页界面81项通过；未新增截图检查。
- 日志：`build/checks/20260909T114236030-43232/`。

## 2026-09-09 魔导拘束盒
域：界面、装备与解除。
- 准备后的保存恢复得到相同下一步，重复库存索引原子拒绝。
- 完整受影响检查：`./tools/check.ps1 -Suite guard,enemies,application,replacement,persistence,status -Exhaustive -UI -UISuite enemies,guard,status,persistence -TimeoutSeconds 600`。规则7200项、窗口298项通过；日志`build/checks/20260909T084443155-32688/`，规则205.51秒、窗口107.40秒。
- 测试去重后仅重跑敌人及其关联分类：`./tools/check.ps1 -Suite enemies -Exhaustive -TimeoutSeconds 600`，4595项通过、109.52秒；日志`build/checks/20260909T092525833-47852/`。

## 2026-09-09 魔导无人机与同种去重捕缚
域：界面、装备与解除。
- 新来源结构、残余能量、保存恢复后相同下一步、非法来源与过期动作的原子拒绝通过。
- 最终命令：`tools/check.ps1 -Suite guard,enemies,basic_attacks,persistence,status -Exhaustive -UI -UISuite guard,enemies,status,persistence -TimeoutSeconds 600`。规则 **7059项通过**（126.09秒），窗口 **294项通过**（103.68秒），引擎退出码0且无错误。
- 日志：`build/checks/20260909T081051724-37752/check-rules.log`、`check-ui.log`。此前失败为原抽样集未覆盖扩大的全部弱怪，已由上述定向采样修正并复查。

## 2026-09-09 八件遗物、力量／灵巧与特殊战斗
域：卡牌与奖励、战斗与敌人。
- 魔力耳坠统计实际支付、包含失败和固定兑换；非出牌阶段不累计，余数本场保留。
- Snapshot.REVISION已更新，保存上限、场次进度及已抽遗物，拒绝损坏状态，不迁移旧档。
- 新例收进现有rewards分类，覆盖拾取／恢复／重复拒绝、真实兑换支付、非法动作回滚、四类场次、巡视暂停恢复、放大后的魔力上限、体术变体、部位限定、被动滑脱及掉落分布。
- 最终命令：`tools/check.ps1 -Suite rewards,services,status,basic_attacks,slip_motion,persistence,casting,events,content -Exhaustive -UI -UISuite rewards,services,home,persistence,status -TimeoutSeconds 600`。
- 最终日志：`build/checks/20260909T072723328-33628/check-rules.log`与`check-ui.log`。退出码0、无引擎错误、无截图；未运行全项目all、导出或发布。

## 2026-09-09 遗物核对与三档分类
域：卡牌与奖励、检查与测试。
- 核对实际调用后，将余烬晶石正文从泛指“耗魔行动”修正为首次付费施法返还实际支出50%，失败同样返还、零支付保留机会；设计页去掉过时“比例待定”。
- 内容包rarity为必填，未知／缺失值拒绝，模板与设计示例同步。
- 案例加入现有encyclopedia／content／home／services模块：注册覆盖、初始来源保持、只读视图、内容包字段保存与错误拒绝、首页真实筛选、商店可见标签；未新建测试框架或重复遗物效果测试。
- 先用ListOnly确认范围，再执行`tools/check.ps1 -Suite rewards,content,services,encyclopedia,status -UI -UISuite home,services,rewards -TimeoutSeconds 400`。
- 日志：`build/checks/20260909T062917372-48704/check-rules.log`及`check-ui.log`。最终退出码0，无引擎错误，无截图，未运行全项目all或导出发布。

## 2026-09-09 双面新卡、独立来源增益与稀有度奖励
域：契约 `card-framework.md`。
- 来源ID分别保存／派生，伤害相乘、同源不叠加；真实费用、施法失败、消耗区、多段完成后消耗、完整解除及战斗清理均沿原事务。
- 扩展种子5、10暴露旧heap断言禁止链接，与已冻结的绳索池包含链接规则冲突。诊断确认新增普通件与链接均为中级三档、原链接保留，只修改旧断言，不修改敌人执行逻辑。
- 规则最终：`tools/check.ps1 -Suite rewards,casting,persistence,equipment -Exhaustive -TimeoutSeconds 800`，**8099项通过**，138.10秒，enemy_cycle 16/16、enemy_pool 24/24。日志：`build/checks/20260909T054750186-37468/check-rules.log`。
- 商店分类补充：`-Suite services -Exhaustive -TimeoutSeconds 120`，shop_release／services **182项通过**，1.74秒，日志：`build/checks/20260909T055117955-6960/check-rules.log`。
- 日志：`build/checks/20260909T054303830-14600/check-ui.log`。
- 上述最终进程退出码均为0，无引擎错误。无截图；未运行全项目all，未发布或生成新导出包。

## 2026-09-09 框架与接口复查、随机域与施加反馈修正
域：架构与接口。

## 2026-09-09 卡牌二重分类与火焰精通
域：`data/balance.gd`；契约 `card-framework.md`。
- 能力沿原自身出牌候选与费用事务进入真实powers区；统一牌区守恒、重复能力拒绝、非战斗拒绝、过期版本／费用不足回滚、回合洗牌不回收能力、胜利及收押清理、快照坏数据拒绝和恢复后正式施法均有验证。
- 规则：`tools/check.ps1 -Suite rewards,casting,persistence -TimeoutSeconds 360`，**5079项通过**。日志`build/checks/20260909T042601325-44380/check-rules.log`。
- 窗口：`-UIOnly -UISuite home,casting`，最终紧凑卡面版本**100项通过**，日志`build/checks/20260909T043313475-14576/check-ui.log`；`-UIOnly -UISuite rewards,interface,services`，**415项通过**，日志`build/checks/20260909T043746001-11100/check-ui.log`。共515项窗口断言，真实点击、翻面、能力区、交叉筛选、商店与奖励共用卡面均通过；所有引擎正常退出，无错误，无截图。
- 沿原存档修订策略拒绝旧档，不做迁移。
- 原校验接受未登记域的缺口已由失败案例复现，现在拒绝多余、缺失、非整数与负计数，失败不改当前状态。
- runner旧断言要求persistence排除prison，与新增监狱路线的实际交叉归属冲突。
- 修改前现行功能基线：tools/check.ps1 -Suite architecture,prison,consumables,application,replacement,persistence,tower -Exhaustive -UI -UISuite prison,route,consumables -TimeoutSeconds 240，通过8106项规则、214项窗口断言；85.50秒／62.48秒。日志build/checks/20260908T165038756-50156/，包含enemy_cycle 16/16、enemy_pool 24/24、tower_graph 201/201。
- 新增拒绝案例在旧实现上的复现：-Suite persistence，3910项中1项失败，未登记随机域被恢复；build/checks/20260908T165233635-37348/check-rules.log。
- 首轮全规则回归在11959项中发现3项断言失败及4次引擎错误记录：runner交叉归属过期、两个法阵的sequence白名单遗漏、装备案例访问已废弃的预选slot，build/checks/20260908T165422919-49852/check-rules.log；修正后runner专项20项通过（0.79秒），build/checks/20260908T165610800-31952/check-rules.log。
- 测试改接正式施加后，6480项中复现链接反馈漏报1项，build/checks/20260908T170238146-21860/check-rules.log；修复后-Suite equipment,events,installation_priority,enemies -Exhaustive通过6480项（62.97秒），build/checks/20260908T170717845-46536/check-rules.log。
- enemy_feedback窗口42项中复现批量部位与高亮2项失败，build/checks/20260908T170830214-43124/check-ui.log，保留案例并修正合并逻辑。
- 随机域调整后，-UIOnly -UISuite prison,route,consumables,persistence通过273项窗口断言（78.16秒），build/checks/20260908T165654026-43728/check-ui.log。
- 反馈修正后，-UIOnly -UISuite enemies,enemy_feedback通过211项窗口断言（80.83秒），build/checks/20260908T170924101-9684/check-ui.log；含真实链接双端、批量全部部位高亮、显示播放不修改状态。
最终`tools/check.ps1 -Suite all -TimeoutSeconds 300`完整规则回归通过11970项断言（214.35秒），涵盖全部43个分类，enemy_cycle 16/16、enemy_pool 24/24、tower_graph 201/201完整种子；日志`build/checks/20260908T170849131-41384/check-rules.log`。完成运行均通过退出码、成功标记与引擎错误门禁。
`tools/check.ps1 -UIOnly -UISuite guard,enemies`通过199项窗口断言，单／双警卫截图已复核。
`tools/check.ps1 -Import -UIOnly -UISuite hero_art,equipment_art`通过190项窗口断言，并生成站／坐／卧三张实机截图。

## 2026-09-09 链接池覆盖、魔法阵满位加固与眼部两件上限
域：装备与解除、界面。
本批核对发现：魔法阵旧循环只施加且普通白名单漏了链接；通用事件随机冻结只接受install，也会拒绝生成器返回的link。
事件生成结果可冻结为link，通过原execute_concrete提交，沿已有探测副本与事务实现版本复核、费用和失败回滚；预览、日志显示两个真实位置，快照复用现有链接意图形状验证。
规则分类`tools/check.ps1 -Suite enemies,equipment,events,persistence,links -TimeoutSeconds 360`共5241项通过，日志`build/checks/20260908T174711258-1880/check-rules.log`。窗口分类`tools/check.ps1 -UIOnly -UISuite enemies,intent,equipment_complete,events -TimeoutSeconds 240`共346项通过，日志`build/checks/20260908T174721538-29432/check-ui.log`。均先ListOnly确认范围，未运行all或完整随机矩阵，未生成截图。
新增或修订案例覆盖真实来源池的第三档链接候选与提交、皮带变体实际链接、事件公开两端及同版本恢复、端点消失时连同费用原子拒绝、魔法阵先补最后一条链接再加固、全空间耗尽只结算一次、眼部跨材质共享两格、第三件拒绝、损坏存档拒绝及合法外层替换。

## 2026-09-09 独立监狱路线与领奖后重新攀塔
域：监狱与收押、塔路与地图。
沿prison现有分类验证可继续探索的1—4级警戒对应人数、不可跳过休息点、移动与奖励页恢复、损坏路线原子拒绝、多人战一次奖励、容量整理先于返塔、状态保留和失败后再次收押。
ListOnly确认后执行`tools/check.ps1 -Suite prison,tower,persistence,rewards -TimeoutSeconds 240`，4514项通过，日志`build/checks/20260908T163124463-11204/check-rules.log`。首轮发现普通奖励记录清理范围扩大导致旧塔路案例索引失败，已将清理收窄到监狱出口奖励并完整复跑上述分类。窗口执行`tools/check.ps1 -UIOnly -UISuite prison,route -TimeoutSeconds 240`，205项通过，日志`build/checks/20260908T163627385-45284/check-ui.log`，覆盖地图名称、真实节点进入、五回合休息、出口战及领奖返塔。

## 2026-09-09 魅魔警卫双立绘池
域：`assets/art/enemy-guards-v1/README.md`。
敌人状态和随机域进入快照校验，`Snapshot.REVISION`提升至12，旧档继续按既定策略拒绝而不迁移。
先用 `tools/check.ps1 -Suite guard,persistence -UI -UISuite guard -ListOnly` 查看影响范围。规则最终执行 `tools/check.ps1 -Suite guard,persistence -TimeoutSeconds 240`，相关23个规则模块3846项通过，日志 `build/checks/20260908T154431635-45480/check-rules.log`。
资源导入后执行 `tools/check.ps1 -UIOnly -UISuite guard -Import -Screenshots ui-34-guard-intent.png,ui-36-double-guard.png`，警卫窗口25项通过，日志 `build/checks/20260908T154029134-46088/check-ui.log`。随后工作区并行新增主角姿势资源；重新导入后复跑在既有收押界面读取 `view.prison.toy_rule` 时失败，警卫立绘映射断言此前已通过，失败点与本批敌人美术状态无关，日志 `build/checks/20260908T154649586-29752/check-ui.log`。
并行资源稳定后，尾巴围住的封闭白底由两个明确背景种子清除；最终执行 `tools/check.ps1 -UIOnly -UISuite guard -Screenshots ui-34-guard-intent.png,ui-36-double-guard.png,ui-guard-brown-portrait.png`，27项通过，日志 `build/checks/20260908T155219504-40320/check-ui.log`。三张截图分别覆盖紫发单人、双警卫允许重复和棕发单人；另用 `build/guard-cutout-preview.png` 在深色棋盘底检查两张透明轮廓及白色服装保留。

## 2026-09-08 当前架构复查与分类门禁修正
域：检查与测试、架构与接口。
- 现行接口说明改为敌人出手选择、事件沿自身阶段冻结；当前修订号统一引用Snapshot.REVISION，保留旧档不适配及恢复失败回主页策略。
- 日常奖励分类会带入敌人测试，绳蛇的双分支断言在旧4种子日常样本中失败；完整16种子通过。该定向案例现始终保留完整16种子，不删除断言、不修改随机或正式行动。失败证据：build/checks/20260908T113412957-15468/check-rules.log。
- 卡牌动画窗口案例沿用默认frames/click等待，新增的抽牌落位等待会在断言前消耗完整动画，导致四项中间态检查失败。现有助手增加settle_feedback选项，默认仍等待落位；只有明确观察动画的三个调用只等待真实布局／绘制，保留原生控件提交、全部断言、到达期限与状态不变检查。失败日志build/checks/20260908T114109438-5696/check-ui.log。
- tools/check.ps1 -Suite architecture,application,replacement,core,enemies,persistence -Exhaustive -UI -UISuite enemies,intent,persistence -TimeoutSeconds 240：5554项规则／250项窗口通过，规则96.36秒、窗口84.17秒；日志build/checks/20260908T112855869-12480/。
- tools/check.ps1 -Suite runner,architecture,basic_attacks,battle_saturation：调整后81项规则通过，11.78秒；日志build/checks/20260908T113311483-45500/check-rules.log。
- tools/check.ps1 -Suite rewards,runner -UI -UISuite basic_attacks,rewards,trader -TimeoutSeconds 240：抽样修正后2054项规则通过，27.28秒；日志build/checks/20260908T113543253-42716/check-rules.log。本次窗口在240秒后超时，日志build/checks/20260908T113543253-42716/check-ui.log；不能记为通过。单独基础攻击随后16项通过（10.20秒，build/checks/20260908T114034073-16720/check-ui.log），同组合重跑复现上列四项动画观察失败；初次超时的原因尚未确定，后续未再复现。
- 动画观察接口修正后：tools/check.ps1 -UIOnly -UISuite basic_attacks,rewards,trader -TimeoutSeconds 180，149项窗口通过（基础攻击16、人形敌人82、奖励与动画51），37.89秒；日志build/checks/20260908T114237118-6596/check-ui.log。没有提高原240秒超时上限，没有删除失败案例。
各次范围有重叠，断言数字不相加为独立总覆盖；窗口只进行真实交互和状态核对，无截图。

## 2026-09-08 绳蛇与共用持续施加
域：界面、装备与解除。
状态从旧布尔值改为真实层数，快照修订号升至4，不迁移旧版；同版本读档、非法层数原子拒绝、打断续接已验证。
先通过`-ListOnly`检查范围，再运行`tools/check.ps1 -Suite enemies,persistence,status -Exhaustive -UI -UISuite enemies,status`：规则5213项通过，enemy_cycle 16/16、enemy_pool 24/24，80.18秒，日志`build/checks/20260908T105813099-11140/check-rules.log`。
随后仅重跑`tools/check.ps1 -UIOnly -UISuite enemies,status`：185项通过，63.12秒，日志`build/checks/20260908T110149959-45500/check-ui.log`。

## 2026-09-08 30生命的小型魔法阵进入弱怪池
域：界面、装备与解除。
验证入口先用`-ListOnly`确认，再运行`tools/check.ps1 -Suite enemies,tower -Exhaustive -UI -UISuite enemies`。日志为`build/checks/20260908T104658766-33888/check-rules.log`及`check-ui.log`；规则34.64秒，窗口52.88秒。

## 2026-09-08 魔法阵强怪与仪式
域：检查与测试、界面。
`enemy_ritual_cases.gd`归入已有enemies套件，验证正式行动6／11件增长、两档真实装备、满位落空、启动前／后的打断差异、同版本读档续接、损坏状态原子拒绝、死亡停效和后手一次结算。
最终规则检查：`tools/check.ps1 -Suite enemies,application,persistence,status -Exhaustive -UI -UISuite enemies,intent`，先通过`-ListOnly`核对分类。规则5158项通过，日志`build/checks/20260908T103106880-20672/check-rules.log`，50.59秒；包含关联交叉分类，未运行all。
随后仅重跑`tools/check.ps1 -UIOnly -UISuite enemies,intent`：176项通过，日志`build/checks/20260908T103518321-16088/check-ui.log`，57.95秒，无截图。

## 2026-09-08 施加／替换机制完成接入
域：装备与解除、战斗与敌人。
测试中的旧预备目标已改为实际声明／出手选择；牢房奖励夹具在正式开始战斗前设定先手，避免把敌人实际先手施加后的攻击限制误当作奖励流程失败。
最终验证：`tools/check.ps1 -Suite application,replacement,enemies,guard,events,persistence,core,equipment_complete -Exhaustive -UI -UISuite enemies,intent,enemy_feedback,events,persistence -TimeoutSeconds 240`。
- 默认未截图。
- 日志：`build/checks/20260908T080918830-45084/check-rules.log`与`check-ui.log`；规则48.24秒，窗口21.73秒。
工作区新敌人的完整行动循环不作为本批已验收内容；不把机制通过扩大为全部新内容或最终数值平衡通过。

## 2026-09-08 加固意图生成与执行时机
域：装备与解除、战斗与敌人。
- 范围预检：`tools/check.ps1 -Suite intent -Exhaustive -UI -UISuite intent -ListOnly`。
- 最终验证：`tools/check.ps1 -Suite intent -Exhaustive -UI -UISuite intent`，126项规则断言与29项窗口断言通过；随机样本16/16。日志：`build/checks/20260908T074213035-18580/check-rules.log`及`check-ui.log`。

## 2026-09-08 接触与预检架构清理
域：架构与接口。

## 2026-09-08 整体架构复查收尾
域：契约 `content-extension.md`。
- 普通安装的资格查询与工厂重复计算位置和层级，显式插入复合同层时只有工厂拒绝。
- 多阶段事件在真实提交中预演下一阶段时，状态副本会回滚，但独立的资源反馈记录器没有隔离，导致尚未选择的代价生成“扣费再恢复”的虚假飘字。
失败复现：卡组边界旧实现6项失败见`build/checks/20260908T050546810-43664/check-rules.log`；复合同层查询与工厂不一致的单一失败见`build/checks/20260908T051144245-14216/check-rules.log`；事件预演虚假反馈的单一失败见`build/checks/20260908T051647280-18752/check-rules.log`。
未放宽1800／600步上限、替换失败种子、缩短真实试玩敌人生命或改变正式规则。三条纯正常试玩分别经过354／491／311次正式行动并达到逃离结果；断言总数减少来自不再重复无进展姿势循环。
- `tools/check.ps1 -Suite all -UI -UISuite all -TimeoutSeconds 600`的规则阶段通过全部37个模块、10368项断言，86.67秒；日志`build/checks/20260908T051857613-21580/check-rules.log`。该次窗口因上述旧用例失败，不能计为窗口通过。
- 仅修正窗口用例后，`tools/check.ps1 -UIOnly -UISuite normal_play,guard -TimeoutSeconds 600`通过1046项断言，49.05秒；日志`build/checks/20260908T052337546-43748/check-ui.log`。
- 最终`tools/check.ps1 -UIOnly -UISuite all -TimeoutSeconds 600`通过全部32个窗口模块、2943项断言，138.59秒；日志`build/checks/20260908T052507825-3636/check-ui.log`。
最终两份全量日志均通过退出码、引擎错误和完成标记门禁。无布局／美术变动，未截图；测试存档使用原隔离目录，未触碰玩家存档。现行快照结构与合法状态含义未变，修订号仍为2，继续执行旧存档不适配、恢复失败统一回主界面的约定。

## 2026-09-08 长期维护边界与统一读档失败返回
域：契约 `content-extension.md`。
快照新增集中维护的`Snapshot.REVISION=2`，缺失、错误类型或不同修订号在改写状态前拒绝；文件编码`FORMAT=1`独立保留。启动或运行中恢复失败均回主界面，显示原因并暂停自动保存，原内存与文件保留；只有明确新游戏才替换不兼容档。
历史兼容成功用例移除，改在存档输入边界覆盖缺失池与错误池的原子拒绝；折返符现有道具行为以当前库存夹具继续验证。
先通过真实找准松处卡牌建立效果，再提交正式解除，旧实现出现“目标已删除但效果未清除”的单一失败；证据`build/checks/20260908T044825227-41980/check-rules.log`。
- 验证命令：`tools/check.ps1 -Suite architecture,persistence,equipment,prison,services,content,rewards,enemies,core,guard,pressure,events -UI -UISuite persistence,home,installed_tools,events`。
- 规则通过5440项断言，41.83秒；窗口通过239项断言，16.64秒。日志分别为`build/checks/20260908T045245190-28096/check-rules.log`和`check-ui.log`，无引擎错误。
保留原事务入口、版本复核、费用、材料与结构限制，沿用具体失败原因和正式切割结果文案。
先运行links分类，新增案例在旧实现中仅“合法链接应出现在位置分组”失败（`build/checks/20260908T042716337-6628/`）。修复后覆盖真实连接点遮挡反例、只读预览、过期版本和拒绝回滚、切割只扣共享绳耐久与一次工具次数，并以实际鼠标展开、滚动和点击验证入口。
- `tools/check.ps1 -Suite contact,events,environment_height -UI -UISuite installed_tools,events`的规则阶段通过2447项断言，22.73秒；`build/checks/20260908T043253702-25500/check-rules.log`。该次窗口阶段因新增按钮未滚入视口失败，不算窗口通过。
- 修正窗口案例后，`tools/check.ps1 -UIOnly -UISuite installed_tools,events,baseline,tower_progression,interface`通过749项断言，50.18秒；`build/checks/20260908T043921730-41244/check-ui.log`。包含道具25、基础287、界面313、塔顶44、事件80项；无引擎错误，未截图。
架构说明同步至README与docs/content-extension.md；未安装外部分析工具，未添加新的规则框架或第二套提交接口。

## 2026-09-08 第二局无拘束具后备分支
域：装备与解除、事件。
三局赌牌声明零件后备选项：没有拘束具时第二局直接翻牌，胜率仍为1/2；成功获得1枚心形筹码并进入第二局结算，失败进入原拘束惩罚，由可执行的随机绳索／上锁皮带选项添加拘束具。
- `tools/check.ps1 -Suite event_flow,content,persistence -UI -UISuite events`：1986项规则、80项事件窗口断言通过，无引擎错误，记录`build/checks/20260907T171638805-38588/`。
- `tools/check.ps1 -Suite events`：903项规则断言通过，记录`build/checks/20260907T171741337-25876/`。
- 覆盖零装备进入第二局、后备项唯一且可执行、成功／失败固定种子、成功筹码、失败进入添加拘束具、候选预览不推进随机、有装备时不出现后备项、条件混填／未知选择器拒绝、内容加载、快照及原事件回归。

## 2026-09-08 明显的事件成功／失败提示
域：事件、界面。
结果页标题下新增70像素高的独立横条，34号文字与符号同时显示“✓ 成功”（绿色）、“× 失败”（红色）或“◇ 已完成”（中性金色）。
验证：`tools/check.ps1 -Suite events,content,persistence -UI -UISuite events`，2186项关联规则与72项事件窗口断言通过，无引擎错误。记录`build/checks/20260907T165413027-46232/`。覆盖提交前不泄露、冻结和已提交结果读档、损坏标记拒绝并保留原状态、成功／失败／中性、进入下一页后横条隐藏。该次运行遵循当前共享截图开关，默认没有写图；为核对新增横条，仅定向运行`-UIOnly -UISuite events -Screenshots ui-event-result-page.png`，73项通过（含1项图片保存），记录`build/checks/20260907T165556612-30100/`，只更新并查看1张结果页截图。本次关联规则门禁全绿；前批记录的链接测试失败在当前共享树已不再出现，本任务未修改链接模块。

## 2026-09-08 结果先读、再显示下一阶段
域：`tests/installation_priority_cases.gd`。
- `tools/check.ps1 -UIOnly -UISuite events,action_copy,persistence`通过128项窗口断言，记录`build/checks/20260907T164521658-41764/`。覆盖结果／正文互斥、唯一继续、真实点击无状态改变、重绘保持已读、后续结果不累计、选卡／装备与取消、旧版本拒绝及读档续选。
- 事件截图由原来的多分支截图缩减为两张：`build/ui-event-result-page.png`和`build/ui-event-next-page.png`，已查看。删除事件对白接口对应的重复截图，行为断言保留。
- 三项失败位于未修改的`tests/installation_priority_cases.gd`第27／74／76行，分别为链接安装优先级、失效端点重选与正式回合提交；不属于本次分页改动，未擅自修复。记录`build/checks/20260907T164446738-11636/check-rules.log`，因此不宣称关联门禁全绿。

## 2026-09-08 通用事件布局与二级选择
域：`ui/event_screen.gd`。
- 关联规则：`tools/check.ps1 -Suite events -UI -UISuite events`，853项规则、首轮63项窗口检查通过，记录`build/checks/20260907T163414421-15484/`。
- 最终窗口与事件关联交互：`tools/check.ps1 -UIOnly -UISuite events,action_copy,persistence`，131项窗口检查通过，无引擎错误，记录`build/checks/20260907T163628275-26848/`。
- 覆盖普通／多阶段／练习、奖励二级窗口、十张实体卡不合并、原生鼠标选卡与选装备、翻面、Esc／关闭／遮罩取消、旧版本拒绝、结果日志及存档续选。规则断言还验证投影不改变随机或状态、不包含隐藏效果。
- 已查看`build/ui-46-tailor-choices.png`、`ui-53-succubus-three-games-practice.png`、`ui-54-event-card-selection.png`与`ui-55-event-equipment-selection.png`；主框未越出视口，正文与选项分区，长卡组在弹窗内滚动。仅验证相关分类，不宣称全项目回归。

## 2026-09-07 内容生成规则与 AI 编写模板
域：契约 `content-generation.md`、`content-templates.md`、`content-extension.md`。
记录位于 `build/doc-checks/content-generation-20260907.json`。

## 2026-09-07 五项优化修正
域：`core/contact.gd`。
1. 新增99—100过载附近的边界案例，0%拒绝且不扣卡、能量、魔力或随机次数；保留免费准备、单次多目标判定与存档重放。
3. 窗口测试实际点击／拖放，并断言场景、其他卡牌和日志控件未被重建、规则投影次数未增加。
4. 套件按初始修改范围补齐直接交叉案例，不再递归加载无关依赖；没有删除原套件或断言。规则与窗口共享引擎错误收集器，外层继续复核退出码、日志及完成标记。故意缺失字典键的规则／窗口反例均退出1、输出FAIL、不输出PASS。
最终相关检查：`tools/check.ps1 -Suite contact,casting,persistence,runner -UI -UISuite casting,targeting,interface,rewards,enemy_feedback,special_equipment -VerifyRunner`。
- 2006项规则断言通过，29.39秒；包含当前并行任务的新特殊装备接口与存档交叉案例。
- 400项窗口断言通过，16.35秒；覆盖施法、特殊装备、敌人反馈、选敌、菜单导航与奖励。
- 两个故意报错的反例均被正确拒绝；错误输出为预期的测试输入，不计为正常检查通过。
- 本批最终日志：`build/checks/20260907T044234049-7704/`。早期执行碰到另一任务尚未接完的特殊装备接口，以及新增直接存档覆盖后的旧范围断言；已保留新接口并更新范围断言，最终检查通过。
此次为相关分类回归，不是全项目完整回归或平衡测试；不同批次检查范围不同，不将断言数减少当作等量测试加速。

## 2026-09-07 特殊装备容量、耐久与正式解除
域：装备与解除、存档。
普通挣扎／滑脱复用完整伤害预览与事务，双手不能抓住目标且无可借用环境时拒绝并保持费用、卡牌、随机与状态不变。已验证同槽最高紧度／堆叠除数、逐件损伤与移除、手部辅助、无手环境门槛、工具安装与接触、真实魔法支付、三档普通滑脱免疫、满槽回滚、固定品质拒绝伪造、独立编号与存档恢复。旧无耐久练习档明确拒绝恢复，重新开练习即可。
检查日志分别位于build/checks/20260907T044047891-39412及20260907T044142107-2860。

## 2026-09-07 手部辅助与占位部位触及
域：装备与解除、检查与测试。
窗口special_equipment30项、targeting27项、status21项通过；rewards旧手势原因措辞断言同步后27项通过（4.79秒）。
遗物降档案例从6耐久调整到7，以保持其“二档降一档而非直接解除”的测试前提；断言仍检查真实降档和抽牌，未削弱规则。第一轮检查虽末尾打印PASS，但因脚本错误被共享入口正确判失败，修正后重跑通过。

## 2026-09-07 施法概率、口部倍率与卡牌可用性
域：压力与快感、卡牌与奖励。
原手势资格保留；自由面准备不判失败。失败照常花费但不触发法术效果与连段；0%拒绝且不支付。
随后追加失败魔法滑脱、牢门零概率拒绝和失败支付检查，casting最终193项通过，1.74秒。覆盖9种口部等级×紧度组合、曲线边界与单调性、非嘴部隔离、逐牌额外倍率、成功/失败、随机重放、不变预览、支付、自由面与诅咒例外。旧必成功检查改用明确的成功随机夹具，仍执行正式施放门槛；不删除规则来迎合旧断言。

## 2026-09-07 合并部位、特殊占位装备与资源条
域：装备与解除、压力与快感。
覆盖零费/多点能量、贴墙跨回合、立即过载取消待选连牌但保留首段、到期、存档后继续、独立槽容量与非法状态拒绝。

## 2026-09-07 游戏主页
域：界面、存档。
覆盖实际点击、无存档启动、开始后保存、返回与继续、损坏存档保护、隐藏行动拒绝及1280×720缩放。截图为`build/ui-102-home.png`与`build/ui-103-home-continue.png`。

## 2026-09-07 敌人动作衔接与结果反馈
域：战斗与敌人、监狱与收押。

## 2026-09-07 地图直接进入、左键拖动与移动消息
域：塔路与地图、界面。
依据地图算法逆向作者的第一手说明（设计文档已有链接），不宣称逐种子复制原版。
此前预期必须收押的旧断言已替换为严格的真实终点与状态校验。

## 2026-09-07 随机一幕、魔力商店、宝箱与目标复核
域：`tests/game_fixture.gd`。
services中77项覆盖支付、余额不足、容量、重复领取、全部牌堆删牌、查看/读档不重抽、法术资源不影响购物、非法存档回滚、初始入口、前三场弱池及旧在途恢复。
这些夹具/断言已按新规则修正，未删除正式动作或绕过资格。此前塔路图例断言已改为检查实际首领图标。未把中途失败的全窗口命令标记为通过。
检查入口整合：UI_MODULES是窗口套件唯一注册表，baseline可以单独选或与相关模块合并；保留原退出码、错误日志和完成标记检查。
窗口normal_play的610项断言通过。

## 2026-09-07 教程、日志与腿部分段差分
域：界面、角色与美术。
所有末次检查退出码0，无错误日志；未将专项称为全量回归。
首次关联`equipment_art,body_layout,equipment_complete`通过160项窗口断言（窗口8.893秒、含启动11.02秒）；之后补充真实腿部4→3解除切图和仅眼部佩戴不引入图7中的口部装备，末次equipment_art通过95项（窗口3.907秒、含启动6.43秒）。退出码0、无错误日志、完成标记齐全。
覆盖站/坐/躺1/3/2框、有墙/非战斗、零能量普通起身不可用但贴墙可用、正式贴墙推进回合、原生拖放与面板操作；新增实际按钮边界断言防止双行内容重叠。退出码0，无错误日志。已查看ui-86-posture-choices-seated.png与ui-87-posture-choices-lying.png；未重跑无关长路线或全量规则。
`-UIOnly -UISuite hero_art,interface,action_copy,body_layout`通过108项窗口断言，窗口7.623秒、含启动9.66秒。退出码0、无错误日志、完成标记齐全；未为美术更换重复完整规则/长路线测试。首次检查发现基线仍引用旧HERO常量，已同步修正，失败轮不计通过。
新增`body_layout`28项窗口断言，覆盖透明资源、等比显示、部位顺序及边界、最低部位真实点击、零回合查看、关闭后目标保留、头部真实装备、原生拖牌和取消不消耗。现有装备/链接/整备检查统一通过`inspect_body`实际打开详情，未删除原断言或绕过行动。相关窗口70项通过（含启动6.94秒），随后一次完整窗口通过1539项（窗口72.161秒，含启动73.81秒），退出码0且无错误日志。
最新批次（2026-09-06，日志收起/固定与点击选敌）：`-UIOnly -UISuite targeting,interface,action_copy,intent,guard`通过140项窗口断言，窗口9.673秒、含启动11.43秒，退出码0且无错误日志。只修改界面和交互，未重跑无关规则。
早期检查发现并修复浮窗初始高度、树变更期间清理和void回调问题；报错轮即使打印PASS仍由统一日志门禁拒绝，不计成功。
最新批次（2026-09-06，人物台词与右上行动日志）：`-Suite persistence,action_copy -UI`通过2650项关联规则和1463项完整窗口断言，检查分别11.93秒与69.53秒（含引擎启动）；退出码、错误日志与完成标记均通过。
新案例覆盖实际攻击/结束回合/事件、失败提交回滚、查看不重放/RNG不变、嘴部受限、看不清的准备动作、真实存档恢复和修改文案不改变状态；窗口覆盖下移后攻击与姿态拖放、头像对话框、侧栏与事件选择。第一次窗口检查发现测试姿态按钮参数错误，随后又发现正式posture动作未映射到专用台词cue，两项均修正后取得上述通过结果；失败轮不计通过。
本批规则核心检查320项通过；新增状态专项最终53项通过（52项行为断言＋1项套件名称校验），覆盖全部练习投影、真实解除与增益消耗、只读/RNG不变、隐藏意图不泄露、左右手来源和实际五级终局。
相同109项状态/interface/压力窗口断言的对照：优化前模块总计12.046秒（2.683/4.921/4.442秒），优化后6.763秒（1.636/2.441/2.686秒），本机样本耗时减少43.9%。没有删除断言；共享布局等待由8帧减至2帧，仍等待绘制完成，移除输入助手之后的重复等待。
日常通过既有-Suite/-UISuite选择完整关联模块，依赖去重、未知名称拒绝、零退出码/错误日志/完成标记三项门禁全部保留。
退出码0，无错误日志，完成标记齐全。
已查看1440×810默认窗口及新截图 `build/ui-71-game-menu.png`、`ui-72-unified-drawer.png`、`ui-73-simplified-battle.png`。
早期失败没有计作通过；原自动策略穿过信息面板出牌已修正，未让游戏遮罩透传输入。
此前两次检查长时间未完成而人工终止，不计通过；补充分段进度后的一次完整运行取得正式成功标记及零退出码。
已检查新版默认1440×810窗口、双警卫、奖励和塔路截图：`build/ui-08-default-window.png`、`ui-36-double-guard.png`、`ui-04-reward.png`、`ui-05-map.png`。
结果随选牌/牌序变化，不能估计胜率或把全部失败归因于数值。
实际窗口完整复核种子7，从普通入口到塔顶失败、入狱、出牌解除装备、术式开门、站起并离开，最终魔力17.04、压力60、安全等级1、保留一件装备。
历史批次（2026-09-06，高安全装备修正、延期生成与整局衔接）：`tools/check.ps1 -Suite persistence -UI`中全部14套规则通过2626项；完整窗口发现旧长路线直接跳过整备和休息测试混入施法条件的问题。修正窗口测试流程和帮助文案后，`tools/check.ps1 -UIOnly`完整通过611项，无引擎错误。未把此前失败窗口计为通过，末次仅测试/文案修订未重跑无关规则。
- 验证已穿长套的边界、所有计数部位覆盖、普通容量/封闭资格、终局无行动/重复入狱、完整清单恢复与损坏原子拒绝；8种入狱种子配置均合法。旧固定架生成拒绝，历史已结束记录仍可恢复。
- 警卫生命仍使用既有短战斗夹具，最终数值难度和全部策略组合尚未验证。
- 已查看`build/ui-07-cleared.png`及`build/ui-65-security-five.png`：终点与高安全监室说明、真实24/24耐久、装备列表可读。
验证五级工厂上下文与普通生成池隔离、关闭套体内层完整保留、三组件/1000耐久/极高损伤仍为0、真实身体4级与头部限制、拒绝残缺存档、旧終局原样恢复；折返符四项实际探索获得、三种姿态/一只手/双手禁用、消费后容量、过载/巡视/反抗阻断、正常检查保留/再收押没收、一次性原子逃离及资源与存档归属保持、保存恢复后正式逃离一致。新增发现使旧测试的道具数量增加，改用正式丢弃处理全部超载，而非削弱容量断言。
历史批次（2026-09-06，悬浮口部敌人与遭遇池）：2540项规则断言通过；窗口enemies19/persistence33，共52项专项通过。
修正测试随机断言只比较装备/敌人域，正常回合洗牌不应被误判为重抽装备；长路线测试通过正式整备解除口部，不改胜负或身体规则。
覆盖正式装备工厂/合法警卫池、独立附着与真实解除、降档不停止、跨房保持、玩家回合末触发、警卫意图冻结/打断/持续到期/不同施加者、战斗胜利/收押清理、事件公开代价与一次性过载、保存恢复后下一正式动作一致、错误持续时间原子拒绝。修复先手连动已完成时空意图存档误拒绝，保留当前回合行动记录与上次意图校验。修订等级检查以验证新模板的最低等级拒绝边界。

## 2026-09-07 具体位置、抽牌牌面与行动交互
域：卡牌与奖励、装备与解除。
- 精确位置检查覆盖独立小腿段不互相遮挡/减伤、同段真实外层遮挡、位置容量、无效位置原子拒绝、肩带排序与存档原位恢复；旧15回合预期统一改为5。
- 新字段损坏的存档必须拒绝且不改当前局。

## 2026-09-07 · 贴墙状态、颈部与子位置
域：装备与解除、塔路与地图。
- 新增 `wall` 专项，正式Game验证战斗距墙1—4随机、读档不重抽、预览不改随机；固定输入后验证移动支付、末段停墙、边界拒绝、贴墙属性、起身不结束回合、工具与挂钩接触、入狱及反抗位置。
- 关联规则批次执行4500项，其中两条沿用“贴墙结束回合”的旧断言失败；已按新需求改为保持当前回合／先后手，再执行core全部338项通过。其他关联套件（存档、商店、状态、特殊装备、奖励、事件、装备、链接、复合、监狱、警卫、压力、敌人、塔路）在原批次没有失败，没有无故重复运行。
- 视觉核对 `build/ui-106-neck-and-wall.png`：顶栏仅距墙数字，贴墙Buff在状态栏；右下移动按钮，左侧14组完整可见，颈部位于口部与大臂之间。

## 2026-09-07 左侧装备双列小卡片
域：装备与解除、界面。
新增真实窗口断言验证两卡并排无重叠、点击展开与收起均不改变游戏快照，并保留真实拖牌目标与解除流程。遗留外带及特殊装备到期后的被动状态保留在默认卡面，不因折叠说明被隐藏。
检查记录build/checks/20260907T044820511-22688。

## 2026-09-07 跨子部位自动紧凑排列
域：装备与解除、界面。

## 2026-09-07 躯干固定仅保留身后版本
域：装备与解除、存档。
已移除身前生成选项和六个身前练习；工厂拒绝身前施加，存档拒绝旧身前实例且保持恢复前状态；身后接触与解除规则保留。hand_assist将原身前夹具改为身后夹具，并把原大腿额外范围断言移到装入躯干固定前，继续分别验证真实前置与固定后的限制。
记录build/checks/20260907T045926725-3092。

## 2026-09-07 躯干固缚附加状态（取代上文专用绳／带方案）
域：装备与解除、存档。
附着状态、独立耐久、最外层生效、同层追加、普通外层拒绝、复合施加时原子取消及原件移除级联全部进入正式规则。
失败不清除状态，预览不消耗随机。
torso_binding规则专项覆盖：两种种子结果、三档触发／二档不触发、手指手掌排除、降档保留、真实卡牌仅破坏连接、两种加固刷新、同层／外层、复合成功／失败、原件正式解除、存档恢复／损坏拒绝、已有外层下休眠恢复及教程更新。
关联contact,enemies,guard,events,persistence：2210规则通过，31.07秒；equipment_complete,body_layout：85窗口通过，7.49秒（build/checks/20260907T053457103-13164）。随后补齐连接读取原件整数紧度、教程及连接降耐久说明，最终torso_binding,action_copy：81规则通过，1.13秒；torso_binding：11窗口通过，3.48秒（build/checks/20260907T054312726-43368）。build/ui-111-torso-binding-cards.png已视觉核对，原件与连接目标紧凑并排。

## 2026-09-07 易滑脱倍率与移动被动
域：装备与解除、塔路与地图。
旧Demo存档缺少motion域时拒绝恢复，不做兼容迁移。
slip_motion专项142项：三姿态完整系数表、肩带和套体区分、主动普通／魔法倍率、正式位移只触发一次、辅助与准备不消耗、同层均匀抽取及较松件减半、共享套体去重、外层移除不穿透、结构禁止与三档免疫、过载不影响伤害、脚踝排除、资源不足／过期版本拒绝、晚期校验回滚、存档继续复现、姿态不触发、有装备探索与免费探索、跨房五步和最终入房顺序、教程与数值表一致。
日志：build/checks/20260907T063634994-44976/check-rules.log。
日志：build/checks/20260907T063808279-40668/check-ui.log。build/ui-112-slip-motion.png已核对即时反馈；随后短摘要改动由窗口断言验证，详细公式只留日志。
调整现有检查：跨房组件不再断言耐久完全不变，改为按正式被动结果逐件核对损耗，同时保留全部其他结构／编号；紧凑装备栏检查实际位置文案，不再查已移除的旧子面板节点；牢门成功拖牌案例显式固定无口部阻碍、零过载的施法条件，魔法失败代价仍由casting覆盖；悬停案例先从手牌外移入，消除上一套件鼠标停留同坐标的干扰。

## 2026-09-07 肩部附加拘束定稿写入
域：界面、装备与解除。
第7.2A列出的正常、反例、边界、回滚、存档和窗口案例全部待编写／待执行，不是已通过的测试。

## 2026-09-07 直接进入牢房的练习与探索讨论稿
域：契约 `prison-exploration-proposal.md`。
规则新增20项：两种可见性、躺姿靠墙、正常首回合资源与抽牌、无敌人、真实巡视清单、练习存档身份、恢复后刷新版本但保留其余全部状态、过期行动拒绝、探索发现和支付一次、共享移动被动、正式回合倒计时与完整校验。
最终 prison,persistence,equipment_complete 关联门禁展开8套件，1202项通过（12.06秒），build/checks/20260907T065843094-45396/check-rules.log。窗口prison,equipment_complete共117项通过（12.30秒），build/checks/20260907T065647620-43940/check-ui.log；真实菜单点击两种场景，验证旧探索按钮、巡视、眼罩和对应场景身份，截图build/ui-113-prison-practice.png。

## 2026-09-07 肩部链接与单手套独立肩带实装
域：`core/shoulder_links.gd`。
单手套改left/right两组件，不再使用cross共享组件；交叉历史独立保存，旧组件记录拒绝恢复。警卫的额外肩部施加走正式选装、公开意图、目标复核与执行，保存后不重抽；失败不写入半对。
新增shoulder规则专项最终105项通过：三品质初始档、六种基础材料、左右独立损耗、真实出牌费用、2／1／0侧效果、交叉3→2→1及再升3、历史存档、损坏配对拒绝、加固补缺、原件删除、幸存侧不重置、单手套同规则、焦点增益清理、同肩三对同层、额外警卫意图保存与施加。
- 初次关联contact/guard/enemies/persistence/events/slip_motion共2487项，4项旧断言失败，其余通过：肩部主动倍率夹具原先借套体同步紧度，及旧肩带显示在小臂的断言；已按新规则修正，不更改正式数值。
- 修正后shoulder/slip_motion/equipment及直接交叉套件921项全部通过（5.73秒）；shoulder/body_layout/equipment_complete窗口104项通过（10.44秒），build/checks/20260907T065822663-676。
- 六种材料补充后shoulder最终105项通过（1.25秒），build/checks/20260907T070205356-24864。
- 最终baseline窗口252项通过（38.24秒），覆盖长短单手套真实拖牌、肩部入口、交叉禁挂钩、套体特殊脱下及墙面工具，build/checks/20260907T070446172-43456。
截图build/ui-113-shoulder-pair.png、build/ui-114-independent-crossed-shoulders.png均已视觉核对：紧凑左右卡片独立显示名称、耐久、紧度、交叉与无法挣扎说明。

## 2026-09-07 手指资格与手掌半效辅助
域：`core/contact.gd`、`core/hand_assist.gd`。
记录build/checks/20260907T073610912-27720，截图build/ui-115-half-hand-assistance.png已检查。

## 2026-09-07 后台方格探索与行动级摔倒（已接入）
域：`core/prison_space.gd`。
验证：prison,wall,persistence,casting关联14套件共2034项通过，21.06秒；日志build/checks/20260907T075803506-16104/check-rules.log。随后追加远距连锁开门阻断、外部阶段起身加费、战斗安装工具返回牢房、两格行动只判一次等10项，exploration完整专项171项通过，3.77秒；日志build/checks/20260907T080302790-39228/check-rules.log。
窗口exploration,prison,wall,casting,slip_motion共136项通过，12.51秒；日志build/checks/20260907T075803506-16104/check-ui.log。已查看build/ui-114-prison-destinations.png及build/ui-115-prison-blind.png，蒙眼地点采用紧凑两列，方向动作费用不重复，移动提示同步实际距离与被动结果。
日志：build/checks/20260907T082302181-16496。

## 2026-09-07 牢房二级操作与装备拖牌卡
域：监狱与收押、装备与解除。
规则exploration完整180项通过，包含预览不修改快照、蒙眼远处无交互元信息、已发现脚下通风口上下文，以及原路径／摔倒／移动／存档规则；日志build/checks/20260907T082045619-45016/check-rules.log。窗口exploration、prison、equipment_complete、baseline、body_layout、hand_assist、shoulder、slip_motion共491项通过（49.64秒），日志build/checks/20260907T082452132-47116/check-ui.log。新增高度断言防止标题竖排或装备卡异常撑高。
此前窗口检查发现装备卡高度反馈错误，以及原生查看测试被已展开日志挡住；前者改正常容器布局，后者使用正式收起日志按钮后再点击，并新增确认确实进入二级页的断言，没有绕过拖放或行动校验。已核对build/ui-114-prison-destinations.png、ui-117-prison-door-details.png及ui-118-equipment-drag-card.png，计数横排、主列表精简、门页独立、装备卡耐久条与效果可见。

## 2026-09-07 正式地图美术与纸面降亮
域：`ui/route_map.gd`、`tests/route_ui_cases.gd`。
执行 tools/check.ps1 -Import -UIOnly -UISuite route 导入；修正新测试对Control坐标转换的调用后，tools/check.ps1 -UIOnly -UISuite route 88项通过，无引擎错误。通过日志：build/checks/20260907T082722506-48532/check-ui.log，窗口套件5.355秒。未修改规则，未跑无关全量。
已查看实际窗口 build/ui-117-map-art-detail.png、ui-118-map-art-overview.png、ui-99-map-arrival.png，确认暗纸面、透明图标、详细标题／状态、总览17层与入口、实际已走路线和右侧移动消息正常。
同步意图、术语、教程、练习、文案包及设计说明；当前普通警卫存档可恢复，旧蓄力和优先计划拒绝恢复。新例覆盖全部普通阶段不生成删除项、打断后原计划执行一次且不增压、保存及非法旧行动回滚；窗口从正式警卫入口连续推进验证。检查日志分别为build/checks/20260907T083617364-44724、build/checks/20260907T083710735-46988。

## 2026-09-07 探索距离条、安装地点与离墙预告
域：装备与解除、界面。
记录build/checks/20260907T084650404-47120，规则4.49秒、窗口15.05秒。后续把条体高度调至22以容纳数字，并通过正式收起日志按钮拍摄完整面板；exploration窗口48项再次通过，build/checks/20260907T085000233-46260，6.12秒。
未做旧存档迁移或无关全量测试。

## 2026-09-07 小石片／锯条嘴部安装与高度方案v1
域：契约 `environment-interaction-proposal-v1.md`。
wall关联完整6套件833项通过：新增六种工具×姿势组合的真实提交、嘴部占用、错误高度、远离墙、无墙、空位、能量、过期版本、次数不变、旧手部路线与安装后固定切割；首跑6项断言错误来自测试读取事务提交前旧物品引用，已改为读取提交后的正式实例，未为修测试改动事务。记录build/checks/20260907T090046837-38984/check-rules.log，12.63秒。
exploration／wall／prison窗口164项通过，14.77秒，同目录check-ui.log；手指和脚趾都受限的牢房练习真实使用嘴部安装，验证1能量／次数／新增工具地点和日志，截图ui-121-mouth-installation.png已核对。

## 2026-09-07 固定三档高度、躺姿抬腿与中位挂钩
域：装备与解除、界面。
contact、wall、persistence及直接关联完整套件共2236项断言通过，build/checks/20260907T092319560-9440/check-rules.log（21.69秒）。新增environment_height覆盖具体手肘子位置、高位足部／中位小腿、内外层、嘴／脚趾取回、换姿势保留安装点、费用次数、远处拒绝、同高不同位置、重复占位读档拒绝与挂钩降档。旧挂钩肩部／头部夹具改为坐姿后仍执行原结构断言；没有绕过正式规则放行。
界面exploration、wall、baseline、equipment_complete、prison共484项通过，build/checks/20260907T093420616-44864/check-ui.log（56.82秒）。最终补齐特殊装备卡与非装备目标的排列后，wall、special_equipment、prison共176项通过，build/checks/20260907T093611981-47472/check-ui.log（15.92秒）。

## 2026-09-07 高度仅后台、前台按身体部位说明
域：装备与解除、界面。
environment_height完整22项规则断言、exploration／wall／special_equipment窗口136项通过；build/checks/20260907T094059483-14000，规则1.46秒、窗口11.24秒。
### 2026-09-07 道具二级位置菜单与安装伤害被动
安装工具在原牌伤害后提供固定值，次数、最强选择、多段逐工具一次、末次清理、读档和版本拒绝已接入。
- 规则 core/equipment/rewards/persistence/wall/environment_height 及直接交叉套件2443项通过：build/checks/20260907T095803966-11644/check-rules.log。
- 后续修正合法位置投影后，contact/installed_tools及直接交叉套件1404项通过：build/checks/20260907T100012925-33728/check-rules.log。
- 最终窗口 installed_tools/wall/baseline/equipment_complete/events 共404项通过：同目录check-ui.log。
- 前轮 enemy_feedback/interface/rewards/persistence 窗口各38/256/27/44项无失败；该轮整体因旧交互测试与位置分组缺口失败，不能标记整轮通过。上述失败均由最终404项覆盖修复。
- 并行内容加载器曾短暂缺文件导致编译失败，配套落盘后已重新验证；不删他人改动、不绕过错误门禁。
installed_tools窗口20项通过（build/checks/20260907T100240498-35644/check-ui.log），重新检查ui-120-card-tool-bonus截图。
### 2026-09-07 塔图连线与前进统一
新增规则覆盖视图连线与候选一致、同层上方无连接、跨层／回头原子拒绝、途中边失效无资源变化、非法行程读档。tower及关联2297项通过（build/checks/20260907T100534533-48804/check-rules.log）；route窗口90项通过（build/checks/20260907T100619758-47992/check-ui.log），包括原生点击相邻无连线房间保持状态、显示具体原因，以及既有真实节点出发与逐回合抵达。

## 2026-09-07 五类可加载内容包与普通单件三档边界
域：`content/README.md`、`tools/check-content.ps1`。
- 新增 tools/check-content.ps1 只读检查命令；5个模板独立及整批校验通过。明确仅支持已有机制、重启新局启用、缺少引用拒绝读档，不提供旧包迁移或任意脚本执行。
- content专项最终283项包含磁盘加载、启动一次性登记、错误批次拒绝、重复ID、所有模板根字段的错误类型、跨文件引用、正式塔路出现、新敌人实际行动、新拘束具真实解除、新遗物容量、事件支付和奖励、特殊装备触发/到期、版本拒绝与保存恢复。
- 接入批次 equipment/special_equipment/events/enemies/rewards/persistence/tower 及直接交叉4444项、home/events/special_equipment/enemies窗口130项通过：build/checks/20260907T100435633-46776。
- 最终普通单件/复合边界修改后 content/shoulder/composites 及直接交叉1090项、shoulder窗口19项通过：build/checks/20260907T101743186-31088。此前 content/shoulder/persistence及交叉1209项、special_equipment/home窗口73项通过：build/checks/20260907T101334565-48492。
- 主页最终35项通过：build/checks/20260907T101125870-45416，已目视核对 ui-102-home.png、ui-124-content-error.png，错误正文可读且显示文件与问题，不写游戏状态或存档。

## 2026-09-07 商店陈列重制与整件解除服务
域：`ui/shop_screen.gd`、`core/room_services.gd`。
- 普通20魔力、完整复合加15、所处理部分有锁加10（一次）；先开锁再归零全部组成部分，复用正式事务回滚、徒手解除效果与既有清理。
- 107项新服务断言覆盖普通及含锁报价、复合整件与独立外带、附带肩部／躯干连接／焦点清理、独立装备保留、链接依赖、外层阻挡、余额边界、重复服务、过期提交、最终校验失败回滚与存档恢复。
- 最终 `services,composites,links` 与自动选中的交叉分类共1025项规则断言通过，`services` 原生界面39项通过；日志：`build/checks/20260907T110045362-44804/`。检查器同时核对引擎错误与退出码，没有将中途其他任务测试文件改写时出现的编译失败计为通过。
- 已目视核对 `build/ui-97-shop.png`（售罄）、`build/ui-shop-release.png`（报价）、`build/ui-shop-low-mana.png`（余额不足）、`build/ui-shop-1280.png`（720p）。新商店支持原生购买、删牌、整件解除、空目标与离店；规则与教程同步，未发布或测试导出包。

## 2026-09-07 特殊设备与资源文案独立验收
域：`core/content_catalog.gd`、`ui/main.gd`。
- 更新过期断言：房间来源使用实际源名与 room/equipment 依赖，不再要求中文名包含“房间”；设备练习下回合开始为8→16，只有当前回合型来源触发，不再沿用旧的两个来源20点预期。
- 两种无线设备分别覆盖大臂、手腕、手掌、手指阻止时原子拒绝；全部自由后一次移除、花费1能量且保留无关根。
- 新增事件断言检查裁缝调整和锁匠失败都把对应接触来源写入实际资源变化日志。
- `pressure,content,special_equipment,status` 及自动交叉共1386项通过：`build/checks/20260907T120320444-22160/check-rules.log`。界面 special_equipment 38项、status 32项在 `20260907T120525076-28908` 通过；该轮pressure发现旧预期后，修改并单独重跑47项通过：`20260907T120644104-2728/check-ui.log`。合计117项界面检查通过，未声称此前整轮失败日志为PASS。
- `rg` 扫描 ui/core/data/content 的 `.gd` 与 `.json`，玩家侧旧词“压力／过载／威压／占位装备”无命中。

## 2026-09-07 主页读取商店存档中断修复
域：存档、界面。
用户启动日志证实：`SaveStore.summary` 缺少 shop 显示映射，读取真实商店存档时抛错，后续 summary.available 访问再次失败，主页只创建到内容包按钮。
新增合法快照全部阶段均有摘要名称的契约断言；主页原生测试增加商店已购商品／宝箱分别保存→冷启动→全部主页按钮可见→继续游戏，验证金额、库存、已售状态和存档文件不被启动覆盖。home共63项通过：build/checks/20260907T121112739-33392/check-ui.log，截图build/ui-home-shop-save-fixed.png已目视核对。persistence及自动交叉1432项通过：build/checks/20260907T121153009-44544/check-rules.log。最后通过原启动器重新打开游戏，实际用户目录的启动日志不再报错。
### 2026-09-07 规则书 v0.12 整理
验收补记：用户要求运行测试后，`-Suite equipment_complete,casting,enemies,guard,prison,persistence` 自动合并相关交叉分类，3298项断言全部通过；`-UIOnly -UISuite equipment_complete,casting,enemies,body_layout` 共139项窗口断言全部通过，两个最终进程均退出0且无引擎错误。修正了规则／窗口各一处旧施法夹具：高级口球现在带马具，零成功率案例改用独立手腕目标，避免先被口球结构限制拦截；保留零成功率不支付、不随机、不可提交及界面原因断言，不修改玩法。最终日志分别为 `build/checks/20260907T124423228-48500/check-rules.log` 与 `build/checks/20260907T124542306-51400/check-ui.log`。
equipment_complete增加组合、单目标及存档断言，现有马具用例改为整件口球。旧名称口部装备存档未做迁移，需重新开始。
### 2026-09-07 仅向下普通链接滑脱×1.25
新增方向反序、三姿态、普通与魔法、被动、挣扎不变、多下链、上下链、解除重算、三档免疫、读档、正式出牌及旧请求拒绝。links/slip_motion及关联981项通过；窗口slip_motion通过，日志build/checks/20260907T130658818-29604。

## 2026-09-07 结构审查六项修复与缓存清理限制
域：`data/phases.gd`、`data/environments.gd`、`data/encyclopedia.gd`、`ui/encyclopedia.gd` 等。
- `-VerifyRunner`额外验证挂起进程在1秒后终止，故意运行时报错不能得到PASS。
- 补充空闲／已有复合装备的预检与真实安装一致性、拒绝原子性及引用隔离验证。
- `tools/check.ps1 -Suite runner -VerifyRunner`：规则范围合并及运行时错误／超时负例通过，记录`build/checks/20260907T125135306-49624/`。
- `-Suite all`：全32个规则模块，7016条断言通过，记录`build/checks/20260907T130756551-21040/check-rules.log`。同批窗口全套检查发现上述特殊装备旧调用、牢房选牌空候选及两项旧UI路径断言，未将该批窗口记作PASS。
- 最终受影响分类复验`-Suite status -UI -UISuite special_equipment,normal_play,prison,tower_progression`：178条规则断言、1166条窗口断言通过，无引擎错误，记录`build/checks/20260907T131306807-34444/`。主页截图`build/ui-home-shop-save-fixed.png`可见全部入口并可继续商店进度。
第七项开发产物清理未执行：删除`build/cutout-deps`、旧浏览器预览缓存与过期隔离测试存档的命令被自动审批以“blocked by policy”拒绝；没有提供更细原因。已记录本机抠图依赖的确切版本及重建方法，源码／素材、用户存档和历史验收截图未删除。本次统计assets约36.93MiB、core/data/ui合计约0.54MiB；build约257.71MiB、.godot约27.33MiB，缓存不作为游戏源码体积。
### 2026-09-07 一层怪物库、独立出场池与空强池
Game支持强池为空：不抽空数组、后续普通战斗继续弱池、房间说明明确显示；Snapshot允许空强选项，拒绝错误分类和空强选项被标为已选。规则enemies/tower/persistence及交叉3848项通过（build/checks/20260907T131649485-35144/check-rules.log），含后续普通战斗仍用弱池、独立池影响真实生成、只入库不生成、分类与原子读档。窗口route/services/enemies共165项通过（build/checks/20260907T131828188-30068/check-ui.log）。
### 2026-09-07 股绳作为链接端
- 其他特殊装备、链接自身、同一对重复连接、伪造接触部位均拒绝。
- `tools/check.ps1 -Suite links,special_equipment,guard,persistence`及关联分类：2743断言通过；记录`build/checks/20260907T133139270-3524/check-rules.log`。新增64条链接断言覆盖三级／三姿势方向、拒绝原子性、读档与损坏读档回滚、真实出牌移除股绳、清理与更换不重接、实际股绳接触解绳、入狱配额生成。
- `tools/check.ps1 -UIOnly -UISuite special_equipment,equipment_complete,guard`：128断言通过；记录`build/checks/20260907T133302784-3728/check-ui.log`。
equipment_complete既有全模板／全等级检查覆盖初级拒绝及中高级安装；enemies补充初级排除与中级生成断言。
### 2026-09-07 环境三类统一
- `tools/check.ps1 -Suite special_equipment,environment_height,content -UI -UISuite installed_tools,special_equipment,status`：858条规则断言、101条窗口断言通过，无引擎错误。记录`build/checks/20260907T134319573-48996/`。
### 2026-09-07 特殊部位统一装备显示
验证：`tools/check.ps1 -Suite links,special_equipment -UI -UISuite special_equipment,body_layout,equipment_complete`通过1795条规则断言和141条窗口断言，无引擎错误。记录`build/checks/20260907T134715171-20776/`；覆盖件数／空位文字、无容量横幅、容量拒绝仍有效、子位置、股绳链接双侧显示与实际拖牌。此前窗口检查发现旧手部触及文案断言与股绳侧显示映射缺失，已按新共用布局更新并完整复验。
### 2026-09-08 配置驱动冗余清理
- 新增配置案例验证新ID三段开锁的一次支付与中途读档、保留3张后抽2、手牌属性加值进入／离开／恢复及负值下限、未知效果原子拒绝。新ID遗物验证数值、周期、返还、姿态候选与状态说明；内容包验证合法trigger及错误组合全批拒绝；新ID精英验证普通战斗计数。
- 主关联门禁：tools/check.ps1 -Suite rewards,content,status,persistence,installed_tools,links,slip_motion,enemies,tower -UI -UISuite rewards,status,slip_motion。规则4979项、窗口73项通过，无引擎错误；目录 build/checks/20260907T143433363-31260/。
- 最后补充手牌负加值不得产生负伤害的下限：tools/check.ps1 -Suite rewards,installed_tools,links,slip_motion，1718项通过，无引擎错误；目录 build/checks/20260907T143642448-33708/。
- 存档待发放记录由三项汇总改为按遗物ID记录效果；旧结构按项目不迁移旧版约定拒绝恢复，原存档文件不删除。当前结构的中途连续／保留恢复与损坏数据拒绝均已覆盖。
### 2026-09-08 首页图鉴与统一卡面
- 最终门禁：`tools/check.ps1 -Suite encyclopedia,content,rewards,services -UI -UISuite home,interface,services,rewards`：845项规则断言、411项窗口断言通过，无引擎错误。记录`build/checks/20260907T143816332-31200/`。
- 前一轮的casting窗口11项、normal_play窗口557项通过，seed7正常试玩通关；该轮唯一失败是并行规则批次正在修正的末段开锁提示，修正后已在上述最终门禁完整复验rewards窗口。当前批次未另改连续开锁规则。
- 视觉检查：`build/ui-encyclopedia-curse.png`与`build/ui-97-shop.png`，卡面没有横向拉伸，商店商品与服务区均在视口内。
### 2026-09-08 慌乱与敏感
- `tools/check.ps1 -Suite curses`：35项通过，记录 `build/checks/20260907T145632721-45304/check-rules.log`。覆盖费用／版本拒绝不变、正式自身出牌、休息与双手受限、未打出正常弃置、消耗恢复、手牌倍率／多张／移出、固有保留、保存恢复后继续行动、降低量不变、阈值与连续来源、实际能量支付触发与非法倍率。
- 首次窗口 `-UIOnly -UISuite rewards,home,casting,status`：161项通过、无引擎错误，记录 `build/checks/20260907T145422848-51836/`；含两张牌的真实鼠标点击、原生拖到玩家、不可打出／费用不足、单面、图鉴。视觉检查 `build/ui-curse-cards.png`，两牌完整可见，敏感效果未截断；卡图沿用现有共享资源，未制作新插图。
- 扩展回归没有全绿，不能把本次专项通过写成全项目通过：`20260907T145300402-11296`的3204项中，自己的读档测试误在0快感请求深呼吸已修正；另一失败为高安全监室seed2的高级三档／锁校验。单独复现时仅有原始10牌、倍率1，进入监室事务被正确回滚，未修改该系统。
- 后续共享目录出现新敌人配置变化，`20260907T145502330-17700`扩展回归有内容模板普通敌人行为断言、未观察文案及缺字段错误。`20260907T145632721-45304`的窗口161项断言执行完毕，但因教程读取新增 `special_install` 行为缺少显示映射而门禁失败；保留红灯记录，没有改动这些敌人／模板／教程行为映射或跳过错误检测。
- 最终卡牌／施法／状态窗口专项 `-UIOnly -UISuite rewards,casting,status`：81项通过，无引擎错误，记录 `build/checks/20260907T145818726-26840/`。不包含上述仍红灯的主页教程流程，不宣称其问题已解决。
### 2026-09-08 通用多阶段事件接口
- 初始阶段必须提供默认付费离开，非法循环、缺收尾、专用脚本op与没有下一阶段合法行动的方案均失败关闭。
- 最终联合门禁`tools/check.ps1 -Suite events -UI -UISuite events`：785项规则断言与30项窗口断言通过，无引擎错误，记录`build/checks/20260907T153255956-32932/`。
- 存档分类`tools/check.ps1 -Suite persistence`：1688项规则断言通过，无引擎错误，记录`build/checks/20260907T153348604-51680/check-rules.log`；覆盖暂存中、冻结下一阶段、恢复后继续、损坏去向拒绝和既有装备／链接／特殊装备存档回归。
- 模板与嵌套字段补强后，`tools/check.ps1 -Suite event_flow`通过30项，记录`build/checks/20260907T153555866-39344/check-rules.log`；`tools/check.ps1 -Suite content`通过477项，记录`build/checks/20260907T153610071-24168/check-rules.log`。实际`.disabled`模板会按启用后的格式解析编译，错误的嵌套effects与未知专用op均整包拒绝。
### 2026-09-08 魅魔的三局赌牌
- 第一局从当前非诅咒永久卡牌生成押牌项，胜率2/3；胜利保牌并加1枚心形筹码，失败把所选实例改为「慌乱」。第二局从当前真实拘束具生成押注，胜负各半；胜利解锁并松一档，失败进入“2件初级2档绳索／1件上锁中级2档皮带／2处收到3档”三选一。
- 正式快感接口造成至少一次高潮，失败再造成一次并随机安装一件当前合法的中级性玩具，无合法位置时加入「敏感」。
- `tools/check.ps1 -Suite events -UI -UISuite events`：810项关联规则与35项窗口断言通过，记录`build/checks/20260907T161237633-48164/`；实际从练习菜单打开第一局并截图`build/ui-53-succubus-three-games-practice.png`。`tools/check.ps1 -Suite persistence`：1717项关联规则断言通过，记录`build/checks/20260907T160414865-51280/`。
### 2026-09-08 六类弱怪替换与后台强度
- 玩具箱使用同一特殊装备资格／工厂，准备、佩戴、停顿循环；准备冻结、打断延期、目标占用后失败不换抽，击败取消未执行计划。
- 规则主回归 `tools/check.ps1 -Suite enemies,equipment,persistence,core`：4678项通过，记录 `build/checks/20260907T152308984-32628/check-rules.log`。包含64组材质怪完整循环、准备中存取及打断、随机池复现、失败目标、箱子多循环／满位／后手存取、已损坏保存原子拒绝，以及关联装备与移动测试。
- 窗口最终回归 `tools/check.ps1 -UIOnly -UISuite baseline,enemy_feedback,enemies,home`：446项通过，无引擎错误，记录 `build/checks/20260907T152548122-45884/`。已查看 `build/ui-weak-toybox-prepare.png`：生命条保留，后台强度没有显示。
- 内容与地图补充回归 `tools/check.ps1 -Suite content,tower -UI -UISuite route,intent`：2642项规则断言、104项窗口断言通过，无引擎错误，记录 `build/checks/20260907T152719392-5460/`。包含强度非法值拒绝、图鉴只读、六个弱遭遇生成与正式地图进入。
- 同批检查发现反馈测试直接伪造第三阶段意图而漏掉准备记录，已改由正式计划生成；并行事件工作期间的一处match分支缩进导致编译失败，仅修正该缩进，事件功能属于另一批任务。本页记录最终关联门禁通过，不宣称全项目全量回归。
### 2026-09-08 日常测试范围与随机样本优化
- 未删除定向行为、边界、非法输入、回滚、打断与存档用例，也未修改游戏代码。
- 完整模式断言与既有种子保持不变；日常地图多样性要求7个样本各不相同，完整仍要求超过20种。
- 新增 `-ListOnly`使用同一个分类解析器列出每个模块的直接／交叉选入原因，窗口也使用自身注册表；不执行测试、不打印PASS。原单次关联、去重、动态加载、独立日志、引擎报错与超时门禁保留。
- 同范围实测 `-Suite runner,enemies,tower -Exhaustive -VerifyRunner`：4666项规则通过、20.33秒；故意运行时错误（规则／窗口）和挂起超时均被正确拒绝。目录 `build/checks/20260907T153538073-44828/`。
- 目录 `build/checks/20260907T153707514-6180/`。
- 18项runner断言检查完整原种子集合、日常非空唯一子集、返回值不可污染配置、原因和范围一致，以及既有去重／未知分类拒绝。首次日常样本遗漏胶带嘴部，原断言报错后将种子7换成3，保留原分支断言，完整矩阵未改。
- 列表模式联合规则／窗口验证 `20260907T153749228-27296/`；all列表确认exhaustive且未执行测试 `20260907T153751769-27296/`；未知分类列表正确失败 `20260907T153752688-27296/`；未指定窗口模块的定向-UI在启动引擎前拒绝。
- 规则通过后的纯显示修改只跑对应窗口；修复失败后不重复已经无关的完整流程。用耗时和关键行为衡量检查价值，不为凑断言数添加镜像测试。
### 2026-09-08 漂浮锁与弱怪强度组队
- 扩展关联门禁 `tools/check.ps1 -Suite enemies,content,tower -Exhaustive -UI -UISuite enemies,home,route`：4855项规则通过（20.29秒）、240项窗口通过（18.68秒），记录 `build/checks/20260907T160338290-38284/`。
- 补入正式地图点击进入新组合的原生窗口案例后，`tools/check.ps1 -Suite enemies -UI -UISuite enemies`：1285项规则通过（8.15秒）、73项窗口通过（9.86秒），记录 `build/checks/20260907T160513357-48276/`。已查看 `build/ui-weak-budget-group.png`：两只敌人分别显示生命与意图，无后台强度文字；漂浮锁窗口截图 `build/ui-floating-lock.png`。
- 以上为相关分类验证，不宣称全项目全量回归。
### 2026-09-08 卡组一览卡牌墙
验证：tools/check.ps1 -UIOnly -UISuite interface，315项窗口断言通过，无引擎错误，记录build/checks/20260907T162348165-48356/。截图build/ui-deck-gallery.png、ui-deck-gallery-bottom.png及正常卡组ui-72-unified-drawer.png，已查看整体网格。
### 2026-09-08 三档添加优先级与敌方链接施加
- `tools/check.ps1 -Suite installation_priority,enemies,equipment,links,guard,events,persistence -Exhaustive -UI -UISuite enemies,intent`：5211项规则、92项窗口通过，44.45秒／12.06秒，记录 `build/checks/20260907T163700707-49372/`。截图 `build/ui-enemy-link-intent.png`。
### 2026-09-08 精准部位串联与截图缩减
- 旧的仅有粗分区域的链接快照拒绝恢复，Demo不增迁移层。
- `tools/check.ps1 -Suite links,installation_priority -Exhaustive`：1138项关联规则通过，15.30秒，记录 `build/checks/20260907T164851760-49508/`；包括区域三角串联、双向额度、精确配对、复合组件、容量不变、非法操作回滚和存档拒绝。
- 最终 `tools/check.ps1 -Suite enemies,guard,persistence,rewards,environment_height -Exhaustive -UI -UISuite enemies,equipment_complete`：4520项规则、113项窗口通过，41.71秒／10.47秒，记录 `build/checks/20260907T165716733-46740/`。前次运行唯一失败是警卫夹具把小臂默认位置当作手腕相邻边界，现明确使用小臂中部；保留实际新增链接断言，未放宽规则。
- 窗口默认跳过截图帧等待、图像读回、PNG写入及保存断言；只有 `-Screenshots <文件名>` 明确选择的画面才保存。
### 2026-09-08 清理内部流程文案
删除卡牌自由面的“不判失败”说明，魔法牌自由面不再弹施法成功率；翻面立即隐藏旧浮窗，不依赖浮起后鼠标是否仍落在卡框内。费用、实际效果、失败消耗、条件与具体不可用原因保留；未改战斗或施法规则。
验证：tools/check.ps1 -UIOnly -UISuite casting,interface，317项窗口断言通过，无引擎错误，记录build/checks/20260907T165718286-49288/。既有付费牌成功率及失败原因可见，新增验证实际右键翻到自由面后浮窗消失，界面关闭后的正式交互仍通过。
关联规则门禁tools/check.ps1 -Suite casting,wall,prison,rewards在build/checks/20260907T165545400-31636/记录2579项，其中三项整局路线失败：ROUTE persistent enemy still requires legal real attack、ROUTE long run completes with one reward per fight east、ROUTE no repeat rewards or rooms including summit。
### 2026-09-08 手牌上限10张
10张手牌存档可恢复，11张拒绝且原状态保持。
tools/check.ps1 -Suite rewards,persistence：2182项关联规则断言通过，无引擎错误，记录build/checks/20260907T172012331-18784/。
### 2026-09-08 资源飘字与遗物触发反馈
core/resource_feedback.gd记录成功事务中魔力、能量及四种准备资源的前后值，Game在扣费、事件记录和提交结束捕获；失败不返回反馈，临时记录不进入存档。
tools/check.ps1 -Suite rewards -UI -UISuite rewards：825项关联规则及36项窗口检查通过，build/checks/20260907T172612098-46612/。新增案例：最后一敌1生命、60魔力火球击杀，收据严格保留60→50→60，实际进入奖励阶段，失败行动没有收据。随后加入刷新保留队列和主页清理，tools/check.ps1 -UIOnly -UISuite rewards -Screenshots ui-resource-feedback-spend.png：38项窗口检查通过，build/checks/20260907T172713961-33280/。已查看build/ui-resource-feedback-spend.png，人物头上魔力−10与左侧中间数值同时可见；动画结束回到60/100，完整游戏快照保持不变。
### 2026-09-08 当前能量即时显示
### 2026-09-08 一团绳死亡分裂与练习
- `tools/check.ps1 -Suite enemies,persistence,rewards -Exhaustive -UI -UISuite enemies`：4238项关联规则、76项窗口断言通过，30.66秒／8.85秒，记录 `build/checks/20260908T024149991-31272/`。
- 规则与存档相关检查保留原子拒绝和随机复现；本次没有新建战斗流程、专用攻击接口或第二套装备生成器。
### 2026-09-08 无效与重复测试审计
- 扫描规则／窗口测试中的已删除机制、静态目录断言、重复场景及图像读回，并与实际行为入口核对；只清理确认多余的案例，不将所有否定断言视为无用。
- 一团绳：删除人为调用其不会生成的leave动作再检查不分裂的案例，删除预留强池常量与空池的重复断言。
- 普通计划打断／恢复仍由正式动作验证；未知敌方行动的存档拒绝归入persistence现有损坏输入矩阵，不再绑定已删除guard_charge名。
- 监狱：删除已废弃终局框架工厂的否定案例，以及Demo不要求的旧终局档缺字段兼容案例；当前真实终局装备、容量、完整记录及损坏记录拒绝保留。
- 验证：`tools/check.ps1 -Suite enemies,guard,intent,rewards,persistence,prison,runner -UI -UISuite hero_art,route`通过3382项关联规则与100项窗口断言，33.10秒／8.06秒；记录`build/checks/20260908T025157394-1156/`，窗口`UI SCREENSHOTS: none`。
### 2026-09-08 环境真实加成与三类伤害公式
tools/check.ps1 -Suite wall,hand_assist,slip_motion,installed_tools,rewards -UI -UISuite wall,hand_assist,slip_motion：2775项关联规则、69项窗口断言通过，无引擎错误；记录build/checks/20260908T031644221-25812/。
### 2026-09-08 一堆绳六次行动、来源效果与半血分裂
- 新案例覆盖来源生效时点与消失、公开两处目标不重复、目标解除后的替换、加固不足的补位、1档直接升3档、49点未触发／48点触发、47点子体向上取整、直接击杀跳过分裂、第六次完整正式回合路线、全身施加不生成链接、子体行动时机、后续死亡分裂与单次奖励、存档继续和损坏继承上限原子拒绝。
- 验证命令：`tools/check.ps1 -Suite enemies,status,persistence,tower -Exhaustive -UI -UISuite enemies`。6393项关联规则与82项窗口断言通过，无引擎错误；规则44.69秒，窗口9.05秒。记录`build/checks/20260908T033256238-3796/`。
- 关联链接检查仍把整段伤害乘1.25且假定三档最终伤害为0，与本日已完成的粗糙墙面真实加成变更冲突；调整其断言为乘区伤害×1.25＋不变的环境加成，三档只检查乘区免疫，未修改游戏伤害规则。
- `tools/check.ps1 -Suite enemies,persistence -Exhaustive`再次通过4305项关联规则，无引擎错误，37.39秒，记录`build/checks/20260908T033752874-12464/`。
### 2026-09-08 一团／一堆皮带变体与分组权重
- `tools/check.ps1 -Suite enemies,tower,persistence,status -Exhaustive -UI -UISuite enemies`：6537项关联规则与90项窗口断言通过，无引擎错误，52.62秒／9.77秒。记录`build/checks/20260908T035052000-1236/`。
### 2026-09-08 负面效果意图图标
tools/check.ps1 -Suite intent -UI -UISuite intent -Screenshots ui-debuff-intent.png：12项规则、18项窗口断言通过，无引擎错误；记录build/checks/20260908T040033203-30924/。截图build/ui-debuff-intent.png。
### 2026-09-08 离场清位与连续缩放
未删除敌人状态或改动分裂、继承、行动与奖励规则。
`tools/check.ps1 -UIOnly -UISuite enemies,targeting`通过168项窗口断言，无引擎错误，11.48秒；记录`build/checks/20260908T040214941-24212/`。无规则改动，未重复规则全量；未截图。
intent 定向检查通过18项规则、21项UI（含真实一堆绳练习悬停）；日志 build/checks/20260908T040545279-41608。
20项规则、166项UI检查通过（intent/enemies）；检查目录20260908T040928700-24368，目视复核一堆绳及双警卫两张截图。
2026-09-08 蓄力悬停精简为单句‘敌人正在蓄力’，空标题不渲染；真实一团绳练习悬停断言全文并验证状态不变。intent通过20项规则、27项UI；build/checks/20260908T041353143-16452。
覆盖全部18种意图映射及真实悬停、蒙眼、状态不变；38项规则、27项UI通过，build/checks/20260908T041507525-1768。
定向规则3355项通过（build/checks/20260908T042256588-43924）；意图／敌人／压力UI207项通过（build/checks/20260908T042225099-30852）。无布局变动，未截图。
### 2026-09-08 强怪组合入场抽取
定向样本检查两组、两种一团材质、七类弱怪与同种重复实际可达；验证前三次普通战斗阈值、组合不连续、装备资格过滤、只读预览、保存后经过休息的下一组一致，以及缺成员／错组合／坏历史的原子拒绝。
`tools/check.ps1 -Suite enemies,tower,persistence -Exhaustive -UI -UISuite enemies,route`通过6707项关联规则、227项窗口断言，无引擎错误；35.35秒／12.97秒。记录`build/checks/20260908T042345240-1212/`。
短句／长文／真实悬停UI29项通过（20260908T063221417-31116），已查看ui-intent-fit.png确认短句无大片空白。
2334项规则、131项装备／事件UI通过；闭锁截图已复核，开闭状态有控件断言。规则日志20260908T065153658-8568，最终UI日志20260908T065332348-16500。
真实链接绳验证不可上锁图标，装备／事件UI133项通过；已复核ui-equipment-lock-cross.png，日志20260908T065512453-18896。
### 2026-09-08 人形强怪奴隶贩子
- 准备就绪保存在敌人实例，可叠层；每件成功施加或替换消耗一层并把实际紧度固定为3档，失败或打断不消耗。
- `tools/check.ps1 -Suite trader -Exhaustive -UI -UISuite trader,enemies,intent,status`通过67项规则与283项窗口断言，记录`build/checks/20260908T095315890-42684/`。随后运行关联门禁`tools/check.ps1 -Suite application,replacement,guard,casting,status,persistence,content,enemies,intent -Exhaustive -UI -UISuite trader,enemies,intent,status`，6283项规则与283项窗口断言通过，无引擎错误，记录`build/checks/20260908T095413690-43436/`。
casting规则1724项、UI14项通过；build/checks/20260908T100422987-29816。
414项规则、60项装备UI通过；ui-quick-release.png已复核，日志20260908T101106828-11404。
规则覆盖同UID弃后重抽、顺序、真实张数、失败无回放、消耗和保留；UI覆盖实际结束回合、消耗牌真实点击、跨render、完成后状态不变、重开清理与拖牌。1800项规则通过（20260908T102041581-21528），73项rewards/targeting UI通过（20260908T102136977-34784）。
新增初始全隐藏／重绘／部分已到达／全部到达及状态不变断言。rewards/targeting UI78项通过（20260908T102428663-14512），ui-sequential-deal.png已复核。
core/enemies扩展种子检查4081项通过（20260908T104531844-34408）；basic_attacks/targeting/guard UI85项通过（20260908T104514398-34088），最后按钮字号调整后basic_attacks UI17项通过（20260908T104705315-29836），截图已复核。日常种子首次检查中另一个任务的TIMING双分支覆盖断言失败，本次未改其生成器或采样，扩展16种子覆盖通过。
### 2026-09-08：主角可添加／加固空间耗尽时结束战斗
- 当前意图不作判断依据。
- tests/battle_saturation_cases.gd纳入core，覆盖无随机副作用、仅加固继续、满位结束、锁来源权限、多敌／已离场来源、拒绝命令不结算、入场与一次奖励。
- 已通过：core,enemies完整随机矩阵4130项规则及enemies窗口157项，日志build/checks/20260908T111654874-34600。检查期间其余任务开始修改data/enemies.gd及first_floor_enemy_pools.gd，后续guard,persistence扩展运行受新怪物／遭遇池与旧断言未同步影响，并遇既有daily随机样本覆盖不足；该扩展运行整体失败，不记为绿色。其guard117、persistence386、prison242项本身无失败，完整失败记录build/checks/20260908T111815008-42024。
- 警卫窗口补验：首次运行达到180秒上限（build/checks/20260908T112011433-26556），增大运行上限后实际42.05秒完成，43项通过（build/checks/20260908T112334248-31944）；没有跳过收押或改变测试断言。

## 2026-09-08 杂乱拘束具、材质归类与双池出场
域：装备与解除、界面。
先以`-ListOnly`查看相关范围，再执行`tools/check.ps1 -Suite application,enemies,tower,persistence,content -Exhaustive -UI -UISuite enemies,intent -TimeoutSeconds 240`。日志位于`build/checks/20260908T113748293-11680/`。
中途失败已处理：旧地图案例将弱池预算2写死为两只，改为实际强度；新增混合敌人的数量案例把加固3档产生的附属肩部件当成新施加整件，改为统计装备根。保留实际动作、费用、状态、随机稳定与存档检查，没有修改游戏规则迎合旧断言。

## 2026-09-08 人形强怪多面手与性玩具随机池
域：装备与解除、界面。
先以`tools/check.ps1 -Suite enemies,special_equipment,content,persistence -Exhaustive -UI -UISuite enemies,intent,special_equipment -ListOnly`确认分类范围。日常敌人抽样在`build/checks/20260908T120854523-31836/`通过2155项规则；四个日常种子继续覆盖既有材质、施加档位和多面手控制分支。最终`tools/check.ps1 -Suite enemies,special_equipment,content,persistence -Exhaustive -TimeoutSeconds 240`通过6140项关联规则，完整执行enemy_cycle 16/16及enemy_pool 24/24，日志`build/checks/20260908T121333584-12508/check-rules.log`。`tools/check.ps1 -UIOnly -UISuite enemies,intent,special_equipment -TimeoutSeconds 180`通过243项窗口断言，日志`build/checks/20260908T121538951-15488/check-ui.log`。

## 2026-09-08 警卫更名与现行行动核对
域：契约 `game-design.md`。
先以-ListOnly确认范围，再执行tools/check.ps1 -UIOnly -UISuite guard,tower_progression -TimeoutSeconds 240：87项窗口检查通过，包含43项警卫与44项塔顶流程；无截图。日志build/checks/20260908T122539793-34732/check-ui.log。只调整原有文字断言，不新增镜像测试、不重复规则全量。

## 2026-09-09 魅魔警卫捕缚重制
域：`tests/consumable_cases.gd`、`ui/main.gd`。
- 魔法牌仍先结算原成功率，失败照常支付且不造成捕缚伤害。
最终关联门禁：`tools/check.ps1 -Import -Suite guard,pressure,status,casting,encyclopedia -TimeoutSeconds 300`通过导入及3968项规则断言，日志`build/checks/20260908T141329334-45348/`；`tools/check.ps1 -UIOnly -UISuite guard,status,interface -TimeoutSeconds 240`通过369项窗口断言，日志`build/checks/20260908T141509758-30508/`。移动即时反馈框后再以真实卡牌拖放重验guard窗口21项并生成`build/ui-35-guard-bind.png`，日志`build/checks/20260908T141932867-31364/`。
清理最后一个旧警卫蓄力校验分支后，`tools/check.ps1 -Import -Suite guard -TimeoutSeconds 240`再次通过导入及918项关联断言，日志`build/checks/20260908T142315503-11744/`。
### 2026-09-09：一次性药剂／卷轴与战后道具池
- 规则验证：tests/consumable_cases.gd覆盖全部6件效果、嘴部减半与4/5取整边界、自由脚趾使用、双手／双脚趾受限拒绝、10张手牌截断及动画回执、实际施法付费／定咒只消费一次、定咒保存与战后清除、0/100概率边界、重复结束和预览不重抽、超量仍获道具、跳过牌奖励仍保留、64种子覆盖8种掉落及损坏概率原子拒绝。纳入consumables交叉分类，与casting/rewards/persistence/guard共同运行完整随机矩阵，7037项通过：build/checks/20260908T143238031-38704。
- 初次回归发现3项旧路线／牢房夹具只整理固定数量物品，新掉落后仍超量；已改为通过正式item_discard和finish_pack完整整理，未删除容量门禁或跳过正式行动。
- 窗口验证：consumables,rewards 58项通过（build/checks/20260908T143219316-22020）；最后统一“定咒”到增益分类并补真实过滤入口，status,consumables 41项通过（build/checks/20260908T143534862-36988）。截图build/ui-consumable-items.png和build/ui-item-drop-reward.png已目视核对；未进行全项目all回归。
### 2026-09-09：装备详情显示徒手解除不可用原因
- 65项窗口断言通过，build/checks/20260908T144656252-40552。

## 2026-09-09 巡视补装、外层替换与逐次登记
域：监狱与收押、检查与测试。
最终先以ListOnly确认范围，执行tools/check.ps1 -Suite prison,application,replacement,persistence -TimeoutSeconds 240，23个相关规则模块共3801项通过，110.11秒。日志：build/checks/20260908T145601738-46092/check-rules.log。窗口tools/check.ps1 -UIOnly -UISuite prison -TimeoutSeconds 180通过98项，日志：build/checks/20260908T145311038-46200/check-ui.log；没有生成截图。
首次关联回归中，监狱及替换规则均通过，旧塔顶路线案例因警卫更名后仍匹配“双警卫”、随机掉落后只丢固定一件物品而失败。

## 2026-09-09 警戒度控制入狱与巡视装备规格
域：监狱与收押、装备与解除。
先ListOnly确认范围，执行`tools/check.ps1 -Suite prison,application,guard,pressure,status,persistence -TimeoutSeconds 300`：29个相关模块、4413项全部通过，用时90.94秒。日志：`build/checks/20260908T152306164-5972/check-rules.log`。
窗口执行`tools/check.ps1 -UIOnly -UISuite prison,guard -TimeoutSeconds 240`，123项通过；日志：`build/checks/20260908T152948476-2104/check-ui.log`。

## 2026-09-09 魅魔事件立绘
域：`tests/event_cases.gd`。
先ListOnly确认范围，执行 tools/check.ps1 -UIOnly -UISuite events -Import -Screenshots ui-event-portrait.png，83项通过；日志 build/checks/20260908T150707928-29956/check-ui.log。已人工查看 build/ui-event-portrait.png，立绘完整且未遮挡文字和选项。
关联规则分类先ListOnly后执行 tools/check.ps1 -Suite events，1139项中1137项通过。两项失败为 tests/event_cases.gd:21 对 ominous_circle、small_circle 的行为注册检查：现有数据使用 sequence，断言白名单未包含该行为，与此次立绘及id投影无关，未修改该并行工作。日志 build/checks/20260908T150740529-46304/check-rules.log。

## 2026-09-09 入狱性玩具清单与巡视充电
域：监狱与收押、装备与解除。
专项规则命令`tools/check.ps1 -Suite prison,special_equipment,application,replacement,persistence,status,guard`通过4450项，日志`build/checks/20260908T155415521-29956/check-rules.log`。窗口命令`tools/check.ps1 -UIOnly -UISuite prison,guard`通过132项，日志`build/checks/20260908T160210049-43636/check-ui.log`，未生成截图。
教程书和规则文案同步后，再执行`tools/check.ps1 -Suite content,prison -TimeoutSeconds 240`，1714项通过，日志`build/checks/20260908T161201898-12836/check-rules.log`；执行`tools/check.ps1 -UIOnly -UISuite interface,prison -TimeoutSeconds 180`，433项通过，日志`build/checks/20260908T161255645-40184/check-ui.log`。

## 2026-09-09 普通魔法牌「激发魔力」
域：压力与快感、界面。
`tools/check.ps1 -Suite rewards -UI -UISuite casting`通过2920项关联规则与45项窗口断言。新增验证双面、零魔力、上限、失败消耗、费用不足和过期版本回滚，以及真实点击恢复和卡面标签；日志：`build/checks/20260909T083002632-48588/`。

## 2026-09-09 魔法牌施法部位与自动选路
域：压力与快感、装备与解除。
魔力转换两面加入施法成功／失败，通用`fixed_mana_cost`保持原固定兑换费用及不参与折扣／返还。
更新旧双手条件断言，路线测试的既有持久敌人助手补入无人机／拘束盒，仍提交真实攻击与奖励，不改运行时敌人规则。
覆盖单侧可用、跨左右手不能拼接、全部路径不可用的原子拒绝、最高概率与配置顺序、嘴部回退实际开锁及续段只付费一次、四张无部位牌的双面概率、固定兑换成功／失败与定咒、费用和随机数、复合手部装备、牢门、卡面显示及禁用原因适配。
最终关联规则命令 `tools/check.ps1 -Suite casting,composites -TimeoutSeconds 300` 通过3407项断言，日志 `build/checks/20260909T103604371-2172/check-rules.log`。施法窗口分类通过52项断言，日志 `build/checks/20260909T103317166-13956/check-ui.log`；卡面条件、实际路径切换和带禁用原因的文字高度均已检查。

## 2026-09-09 双手施法与稀有遗物「施法动作教程」
域：压力与快感、卡牌与奖励。
最终命令：tools/check.ps1 -Suite casting,rewards,composites -UI -UISuite casting -TimeoutSeconds 300。通过5324项关联规则断言、57项施法窗口断言；日志：build/checks/20260909T104507074-45700/。

## 2026-09-09 塔顶首领六缚、收束与临时诅咒
域：战斗与敌人、界面。
首轮规则专项发现六缚测试保存了事务提交前的敌人字典引用，正式原子提交后断言仍在读取旧对象；塔顶资源断言也漏算休息作为特殊战斗结束时触发的余烬护符。首轮联合窗口中首页和敌人模块通过，塔顶流程失败是通用快速通关夹具未识别`six_bind`为持续敌人；加入该类型后单独塔顶窗口42项通过，没有更改正式战斗。
最终执行`tools/check.ps1 -Suite enemies,replacement,curses,tower_progression,persistence,content -Exhaustive -TimeoutSeconds 600`，自动合并29个相关规则模块，完整覆盖enemy_cycle 16／16和enemy_pool 24／24种子，共7180项断言通过；日志`build/checks/20260909T113052835-46276/`。窗口执行`tools/check.ps1 -UIOnly -UISuite tower_progression -TimeoutSeconds 300`，42项通过；日志`build/checks/20260909T112943100-8032/`。按截图精简要求未生成截图，也未运行无关的全项目all。

## 2026-09-09 缚疗修女与普通单件佩戴正文
域：事件、装备与解除。
- 多阶段起始页可用一个无条件、无效果、直达结果页的作者选项替代默认收费拒绝；没有这类安全出口时仍拒绝`allow_refuse=false`内容。
- 联合执行`tools/check.ps1 -Suite equipment,events,event_flow,content,tower -UI -UISuite events -TimeoutSeconds 600`：规则5578项、事件窗口77项通过，记录`build/checks/20260909T134124947-51860/`。另执行`tools/check.ps1 -Suite persistence -TimeoutSeconds 600`：关联规则4560项通过，记录`build/checks/20260909T134312208-30556/`。

## 2026-09-10 拘束具堆里的微光
域：装备与解除、界面。
- 第一次成功率25%，失败后逐次提高10%，第九次必定成功；每次尝试无论成败均冻结并原子新增一件初级2档普通单件，排除链接绳、复合与性玩具。
- 成功真实获得一件未持有随机遗物，失败进入下一阶段，结果继续复用真实装备名与身体部位佩戴正文。
- 执行`tools/check.ps1 -Suite content,event_flow,events,tower -Exhaustive -UI -UISuite events -TimeoutSeconds 600`：完整随机矩阵规则7795项、事件窗口82项通过，记录`build/checks/20260909T141800897-51928/`。

## 2026-09-10 魅纹师的空房、淫纹与针匣
域：事件、界面。
- 【回火】在通用二级选择窗口中选满两件普通拘束具后原子解除；任一冻结实例在提交前失效则整项拒绝，不会只解除另一件。
- 每次正式行动实际花费至少1能量且成功提交后，每张淫纹追加4快感；一次行动无论花费几点只触发一次，零费、拒绝与事务回滚均不触发，多张相加并继续经过敏感倍率。
- 联合门禁`tools/check.ps1 -Suite persistence -TimeoutSeconds 300`自动覆盖22个相关规则模块，4752项通过，记录`build/checks/20260909T153818833-54760/`；`tools/check.ps1 -Suite events,status,tower -TimeoutSeconds 300`自动覆盖20个相关模块，4038项通过，记录`build/checks/20260909T154033488-51848/`。事件窗口`tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`通过91项，记录`build/checks/20260909T153140710-9744/`。

## 2026-09-10 漂浮皮带群与事件战斗返回
域：事件、战斗与敌人。
新增事件流程案例覆盖默认／沙漏回合数、开场抽牌／能量／遗物与蓄力来源、结果与整备起点快照、损坏标记和过期提交拒绝、自然完成／提前结束及奖励不重复。event_flow/rewards关联18类规则6173项通过（build/checks/20260910T162934759-66092/check-rules.log）。窗口先修正测试中的横扫右键切换步骤，最终events完整窗口170项通过，无引擎错误（build/checks/20260910T163316133-66204/）；验证正式战斗结果、按钮文案、整备手牌／结束回合及提前结束。
- 先后执行事件流程专项、内容／事件／塔专项及事件窗口专项：234项、3706项和105项全部通过，记录分别为`build/checks/20260909T161941804-41816/`、`build/checks/20260909T162005277-51656/`、`build/checks/20260909T162117909-16260/`。最终执行`tools/check.ps1 -Suite content,events,event_flow,tower,rewards,equipment -TimeoutSeconds 300`，自动覆盖30个相关规则模块，共6026项通过，记录`build/checks/20260909T162320276-38960/`。

## 2026-09-10 女药师的试饮摊
域：事件、装备与解除。
- `remove_restraints`仍是唯一完全解除事务；本批只把单选冻结结果规范成单元素目标数组，使其与2—4件多选继续共用逐目标复核、原子提交和失败回滚，没有增加事件专用拆除、遗物或诅咒分支。
- 事件流程专项`tools/check.ps1 -Suite event_flow -TimeoutSeconds 300`通过242项，记录`build/checks/20260909T163629028-33576/`。事件窗口专项`tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`通过120项，记录`build/checks/20260909T163638824-38624/`。最终合并门禁`tools/check.ps1 -Suite content,events,event_flow,tower,rewards,equipment -TimeoutSeconds 300`覆盖30个相关规则模块，共6038项通过，记录`build/checks/20260909T163719327-36956/`。

## 2026-09-10 废弃储物室与通用事件道具奖励
域：事件、卡牌与奖励。
- `tools/check.ps1 -Suite event_flow -TimeoutSeconds 300`通过266项，记录`build/checks/20260909T165040314-46084/`；事件窗口专项通过128项，记录`build/checks/20260909T165050297-41316/`。最终规则门禁`tools/check.ps1 -Suite content,events,event_flow,tower,rewards -TimeoutSeconds 300`覆盖24个相关模块、4602项通过，记录`build/checks/20260909T165202833-41128/`；联合窗口`tools/check.ps1 -UIOnly -UISuite events,rewards -TimeoutSeconds 300`通过204项，记录`build/checks/20260909T165400587-36476/`。

## 2026-09-10 三局赌牌性玩具演出
域：事件、装备与解除。
- 事件不声明`hold_special`或`restore_held`，原装备实例、位置和状态从头到尾保持不变；失败分支新增一件性玩具的既有正式效果不受影响。

## 2026-09-10 缚梦客房与最大魔力事件效果
域：压力与快感、事件。
- 新增可跨事件使用的`mana_restore_full`与`mana_max_loss`效果，覆盖内容字段校验、执行前后说明、原子回滚、结果正文和快照验证；最大魔力合法下限调整为1。
- 专项`tools/check.ps1 -Suite content,event_flow -TimeoutSeconds 300`通过913项，记录`build/checks/20260909T172011840-54144/`。事件窗口`tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`通过137项，记录`build/checks/20260909T172027055-47760/`。最终联合门禁`tools/check.ps1 -Suite content,events,event_flow,tower,rewards,persistence -TimeoutSeconds 300`覆盖29个相关模块，共5831项通过，记录`build/checks/20260909T172109761-53264/`。

## 2026-09-10 神秘女人的雕像
域：事件、界面。
错误上下限和不支持的包装效果均由内容编译拒绝。
- `tools/check.ps1 -Suite content,event_flow -TimeoutSeconds 300`：939项通过。
- `tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`：151项通过。
- `tools/check.ps1 -Suite content,events,event_flow,tower -TimeoutSeconds 300`：4010项通过。

## 2026-09-10 迷宫测绘队
域：装备与解除、界面。
- `tools/check.ps1 -Suite content,event_flow,tower -TimeoutSeconds 300`：3365项通过。
- `tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`：159项通过。

## 2026-09-10 接连挣动改为滑脱顺延
域：装备与解除、检查与测试。
- 旧手动续段与保存恢复用例改用逐层抽离，继续检查选择冻结、无重复扣费、原子拒绝及延迟遗物触发。
- 验证：`build/checks/20260909T195554335-54280/`的rewards及交叉分类4546条规则断言通过；同批窗口casting 142条、rewards 179条通过。`20260909T195318304-52252`中hand_assist 154条、persistence 486条通过；该初次批次的旧续段测试筛选错误已修正并在4546条规则门禁复验。
- 存档窗口恢复事件选牌的旧用例未打开现有二级窗口，已复用Event UI原生点击辅助打开并选择真实卡牌，额外断言卡组只减少一张；无游戏逻辑改动。最终`build/checks/20260909T200056695-51652/`定向persistence窗口61条通过。所有最终相关分类无断言／引擎错误，未生成截图。

## 2026-09-10 强欲之壶
域：检查与测试、卡牌与奖励。
- 测试：card_expansion检查双面实际抽2、费用、零魔力与身体受限仍可用、普通池及相同双面、过期／缺能量原子拒绝、满手只抽到10；casting窗口验证原生点击两面及抽牌后真实手牌。
- 验证通过：`build/checks/20260910T034929357-61072/`，导入完成；rewards及交叉分类完整随机矩阵6753条规则断言通过，casting、interface窗口557条断言通过（含两面原生点击抽牌及全卡插图／布局检查）。无引擎错误，未生成截图。

## 2026-09-10 翘腿无视
域：界面、装备与解除。
- crossed_legs_cases归入rewards，覆盖实际伤害／抽牌、3档免疫仍抽、整体等级边界、0费可用、条件变动提交复核、缺能量／坏定义拒绝；casting窗口真实拖放两面、1／0费用与等级原因；interface覆盖全卡图与布局。
- 验证通过：`build/checks/20260910T042011685-56556/`。导入完成；rewards、casting及交叉分类完整随机矩阵8310条断言通过；casting、interface窗口580条断言通过。覆盖原生拖放、翻面费用、等级阻止原因和全卡插图／布局，无引擎错误，未生成截图。

## 2026-09-10 蓄势待发
域：`core/action_copy.gd`、`data/action_copy.json`。
- ready_to_strike_cases归入rewards并由casting交叉覆盖：双面实际费用／消耗、同名实体、不可消耗本牌、目标失效与过期提交、失败留两牌、嘴部阻挡、临时魔力付款、消耗区快照、同面不触发复放；casting UI检查原生点击、取消、指定实体和真实结算。
- 验证通过：`build/checks/20260910T043751978-28776/`，导入完成；rewards、casting及交叉分类完整随机矩阵8296条断言通过；casting、interface窗口592条断言通过。包含原生选牌／取消、两面实际施法、消耗目标实体及全卡插图／布局，无引擎错误，未生成截图。
# 2026-09-10：人物付费行动、快感／堵嘴与施法失败对白
- `core/action_copy.gd`只从已提交payload、行动前后快感、真实口部装备与正式施法结果生成稳定cue；`data/action_copy.json`补齐卡牌四类、非卡牌付费行动、三档快感、清晰／含混说话及卡牌／火球失败正文。
- 最终规则门禁`tools/check.ps1 -Suite action_copy,casting -TimeoutSeconds 300`通过4071项断言，记录`build/checks/20260910T093623320-46932/`。最终窗口门禁`tools/check.ps1 -UIOnly -UISuite action_copy,casting -TimeoutSeconds 300`通过227项断言，记录`build/checks/20260910T094033775-39812/`；未生成截图。覆盖稳定文案键完整性、卡牌分类、快感边界、普通口球含混、胶带／假阳具口球完全堵嘴、真实卡牌与固定火球失败差分、付费攻击实际组合、旧cue静默清理以及投影不修改规则状态。

## 2026-09-10 高潮不再自动打开角色状态窗
域：压力与快感、界面。
- 本批只修改界面显隐与对应真实窗口断言，不改变快感累计、高潮次数、魔力损失、下一回合能量惩罚、候选或存档。`tools/check.ps1 -UIOnly -UISuite pressure -TimeoutSeconds 300`通过49项窗口断言，记录`build/checks/20260910T104515157-54396/`；未生成截图。

## 2026-09-10 高潮第二人称旁白与对白分栏
域：压力与快感、界面。
- `tools/check.ps1 -Suite action_copy,pressure -TimeoutSeconds 300`覆盖11个关联规则模块并通过3645项断言，记录`build/checks/20260910T105149254-54208/`。`tools/check.ps1 -UIOnly -UISuite action_copy,pressure -TimeoutSeconds 300`通过77项窗口断言，记录`build/checks/20260910T105225902-53924/`；验证真实拖牌高潮后的手牌区旁白、人物对话框、无自动状态窗及唯一继续入口，未生成截图。

## 2026-09-10 事件抵达抽取与每局去重
域：事件、塔路与地图。
- 拒绝或离开不返池。
- 同步修正既有敌人注册列表及工具说明改动后失效的旧断言，不改对应玩法。
- 窗口：events分类162项通过，真实点击出发和旅行后打开事件；日志build/checks/20260910T095349496-24100/check-ui.log。
- 规则门禁：tools/check.ps1 -Suite events,tower,persistence -TimeoutSeconds 360，通过7847项断言，退出0、无引擎错误；日志build/checks/20260910T095218436-48280/check-rules.log。

## 2026-09-10 火球术基础次数调整
域：`data/basic_attacks.gd`。
- 死灰复燃继续清零已用次数并恢复当前上限，敌人／装备目标共用、失败计次与回合刷新沿原实现。
- basic_attacks,rewards分类合并5927项中只有原charge_cases把玩家行动摘要误列为不可变状态失败；摘要是实际切换结果，修正断言排除summary后，完整status分类及关联检查3606项全部通过（build/checks/20260910T100740650-11924/check-rules.log）。其余分类此前通过，日志build/checks/20260910T100425883-45808/check-rules.log。
- basic_attacks窗口23项、casting窗口201项通过；日志build/checks/20260910T100542370-51376/check-ui.log。
- interface窗口复跑453项通过，退出0且无引擎错误；日志build/checks/20260910T100917899-46364/check-ui.log。

## 2026-09-10 henshin解除捕缚
域：装备与解除、检查与测试。
首轮测试夹具遗漏警卫已完成开场的stage，已修正；复验casting关联分类4039项断言仅剩3项ROUTE路线失败，新增henshin案例及所属rewards的1620项均通过。规则日志build/checks/20260910T104727233-56704/check-rules.log；完整casting窗口201项通过，日志build/checks/20260910T104651715-33796/check-ui.log。路线失败保留记录，不宣称整批门禁通过。

## 2026-09-10 加固额度可用于上锁
域：装备与解除、检查与测试。
新增reinforcement_lock_cases并入enemies，验证2→3再锁、3档内耐久不回复、满耐久已锁与不可上锁反例、正式回合执行及过期拒绝。肩带旧断言同步新规则，同时保持不补回复合肩带。首轮夹具场景ID写错及旧肩带断言失败已修正；完整enemies/events关联分类5501项规则断言及enemies窗口196项断言全部通过，无引擎错误。日志：build/checks/20260910T105820879-13660/。

## 2026-09-10 加固上锁恢复耐久（补正）
域：装备与解除、存档。
reinforcement_lock_cases中的3档受损样本断言改为恢复满耐久；既有加固及肩带、躯干交叉分类完整复验通过5529项断言，无引擎错误（build/checks/20260910T110408889-62276/check-rules.log）。

## 2026-09-10 冰心诀与魔血
域：界面、检查与测试。
- 通过真实回合覆盖4种场次、低于3的边界、力量与伤害、达到上限、保护、存读档、只读与拒绝原子性；图标和悬停在rewards窗口原流程验证。
- Import及rewards,pressure合并分类完成6834项规则断言，退出0、无引擎错误；日志build/checks/20260910T110553546-34164/check-rules.log。
- rewards窗口复跑191项全部通过，退出0、无引擎错误；日志build/checks/20260910T110848695-58044/check-ui.log。

## 2026-09-10 遗物图鉴小图
域：卡牌与奖励、装备与解除。
home完整窗口97项断言通过，稀有筛选、实际纹理、只读浏览均已验证。截图build/ui-encyclopedia-relics.png人工检查通过；最终日志build/checks/20260910T110949767-59448/。

## 2026-09-10 主页提示删除
域：界面、检查与测试。
已先ListOnly核对home范围，完整home窗口检查通过96项断言，退出0且无引擎错误：build/checks/20260910T111759886-49956/check-ui.log。

## 2026-09-10 分辨率列表至4K
域：界面、架构与接口。
display完整窗口19项断言通过，覆盖小屏仍列出1440p/4K、选择4K、重新读取4K偏好及原模式切换；日志build/checks/20260910T112507804-37408/。

## 2026-09-10 删除神秘药剂、精简遗物说明、重制余烬晶石
域：卡牌与奖励、检查与测试。
- 原说明断言同步为精简后的效果，不要求重复规则文字。
- home,rewards窗口290项通过，日志build/checks/20260910T112200375-41248/check-ui.log，退出0且无引擎错误。
- rewards,casting,content及关联分类复跑7429项全部通过，退出0、无引擎错误；日志build/checks/20260910T112402172-32684/check-rules.log。

## 2026-09-10 传送符
域：监狱与收押、检查与测试。
传送符验证：prison/consumables关联分类4255项规则断言、home/prison/consumables窗口269项断言全部通过，无引擎错误；日志build/checks/20260910T113512009-54100/。

## 2026-09-10 回合区与主动投降
域：界面、检查与测试。
新增规则案例验证普通入狱、5级终局、过期拒绝、场景起点和入狱后不可重复；窗口原生点击验证两次确认、布局尺寸与直接入狱。规则prison关联分类3528项断言通过；截图build/ui-surrender-confirm.png检查通过，prison完整窗口142项断言通过，无引擎错误。日志build/checks/20260910T133445517-13700/。

## 2026-09-10 主角显示名
域：界面、检查与测试。
action_copy完整分类60项规则、29项窗口断言通过；日志build/checks/20260910T134904133-65504/。
