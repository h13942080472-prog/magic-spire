extends RefCounted

# Hand-written layer of the derived check index (docs/spec/check-routing.md §3.5).
# Only knowledge that cannot be derived from the repository lives here, and every
# entry carries a reason. Data keys:
#   DOMAINS          blind source file -> domain words; a word resolves to every
#                    owned case file whose assertion-message prefix uses it, so the
#                    resolution is a superset (never a guess at the exact suite). A
#                    ui/** path keeps only UI owners: rule suites run headless and
#                    reach ui through explicit preload, which is already an edge.
#   WIDEN            declared amplification of one file's index edge set.
#   EXCLUDE          fixture/host layer that must not produce precise edges.
#   BLIND_BY_DESIGN  files without any usable domain word; the directory closure
#                    named in the reason catches them (fail-closed, never silent).
#   INDEX_DEFECTS    learning loop: a routed run missed a red that a wider run found.
#   CLOSURE          directory rules for files the index does not know (contract §5.3).
#   ORACLE_NOTES     files that additionally need a frozen oracle (contract §10-10).
#   SUITE_EXEMPT     registered suites that legitimately own no source edge.
#
# Paths are repository-root relative. A DOMAINS/WIDEN/CLOSURE path is a source file
# (or directory prefix) inside spire-godot; a path that is not indexed at all is the
# normal case for DOMAINS/BLIND_BY_DESIGN, which is exactly why they exist.
# Size: this file is the human review surface of the routing decisions, so it grows
# with the corpus (docs/spec/check-routing-dependencies.md).

const DOMAINS=[
 {"path":"spire-godot/data/card_enchantments.gd","domains":["ENCHANT"],"reason":"附魔数据经核心注册表间接使用，由附魔行为用例验证"},
 {"path":"spire-godot/ui/enchantment_screen.gd","domains":["ENCHANT"],"reason":"附魔界面经奖励页构建，由真实指针流程验证"},
 {"path":"spire-godot/core/action_replay.gd","domains":["REPEATED","ECHO"],"reason":"X 卡内部复读经门面触发，用例只断言复读结果"},
 {"path":"spire-godot/core/card_effects.gd","domains":["CARD","POWER","CAST"],"reason":"卡牌与施法效果的总实现，无直接 preload"},
 {"path":"spire-godot/core/consumables.gd","domains":["ITEM","POTION","FLASK"],"reason":"消耗品数值经门面查询，用例按 ITEM／POTION 断言"},
 {"path":"spire-godot/core/contact.gd","domains":["CONTACT","HEIGHT"],"reason":"共享接触几何，被接触区与墙缝高度用例间接消费"},
 {"path":"spire-godot/core/demo_exit.gd","domains":["EXIT","DEMO"],"reason":"demo 结束与出口判定由塔进度用例断言"},
 {"path":"spire-godot/core/enemy_plans.gd","domains":["INTENT","REINFORCE"],"reason":"敌人意图声明经门面计划，用例按 INTENT 断言"},
 {"path":"spire-godot/core/hannya.gd","domains":["HANNYA"],"reason":"般若卡增益的会话进度，能力卡用例按 HANNYA 断言"},
 {"path":"spire-godot/core/installed_tools.gd","domains":["PASSIVE","TOOL"],"reason":"安装工具用例经 game_fixture 走门面（契约 §3.5 同例）"},
 {"path":"spire-godot/core/iron_man.gd","domains":["IRON"],"reason":"捕获装备循环由敌人／饱和／塔推进用例经门面消费，无直接 preload"},
 {"path":"spire-godot/core/item_rewards.gd","domains":["LOOT","TOOL","REWARD"],"reason":"战斗掉落工具由奖励用例经真实奖励候选断言"},
 {"path":"spire-godot/core/mana_flask.gd","domains":["FLASK","MANA"],"reason":"魔力小瓶是休息房选择，按 FLASK／MANA 断言"},
 {"path":"spire-godot/core/prison.gd","domains":["PRISON","REINFORCEMENTS"],"reason":"监狱回合与增援经门面推进，用例按 PRISON 断言"},
 {"path":"spire-godot/core/puppet_enemy.gd","domains":["PUPPET"],"reason":"傀儡召唤是遭遇内敌人行为，用例按 PUPPET 断言"},
 {"path":"spire-godot/core/rope_master.gd","domains":["ROPE"],"reason":"绳艺首领规则经游戏门面执行，由 ROPE 前缀专项覆盖库存、阈值、助理与存档"},
 {"path":"spire-godot/core/relic_effects.gd","domains":["RELIC"],"reason":"遗物效果由遗物用例消费，无直接 preload"},
 {"path":"spire-godot/core/relic_rewards.gd","domains":["RELIC","RARITY"],"reason":"遗物稀有度分布由遗物／奖励用例断言"},
 {"path":"spire-godot/core/self_binding.gd","domains":["SELF","BIND"],"reason":"X 卡自缚效果经卡牌与束缚用例间接消费"},
 {"path":"spire-godot/core/shoulder_links.gd","domains":["SHOULDER","LINK"],"reason":"肩带链接由肩部与链接用例断言"},
 {"path":"spire-godot/core/snapshot.gd","domains":["SAVE"],"reason":"存档校验经门面调用，无直接 preload（契约 §3.5 同例）"},
 {"path":"spire-godot/core/status_view.gd","domains":["STATUS","CHARGE"],"reason":"状态目录是只读投影，状态用例按 STATUS 断言"},
 {"path":"spire-godot/core/torso_binding.gd","domains":["BIND"],"reason":"躯干束缚生命周期由躯干与墙用例消费"},
 {"path":"spire-godot/core/witch_character.gd","domains":["WITCH","HENSHIN"],"reason":"角色二定义经门面注册，用例按 WITCH 断言"},
 {"path":"spire-godot/core/witch_expansion.gd","domains":["WITCH","HENSHIN"],"reason":"角色二扩展卡与奖励数组按 WITCH／HENSHIN 断言"},
 {"path":"spire-godot/data/enemy_library.gd","domains":["POOL","CAPTURE"],"reason":"敌人变体库是遭遇池来源，敌人用例按 POOL 断言"},
 {"path":"spire-godot/data/environments.gd","domains":["ENV","HEIGHT"],"reason":"环境标签供接触／高度用例消费"},
 {"path":"spire-godot/data/equipment_catalog.gd","domains":["CATALOG","GRADE","RELEASE"],"reason":"装备目录条目由装备完成度与释放用例断言"},
 {"path":"spire-godot/data/first_floor_enemy_pools.gd","domains":["POOL","PROGRESSION"],"reason":"第一层敌池由塔进度与敌人用例经真实遭遇消费"},
 {"path":"spire-godot/data/glossary.gd","domains":["BOOK"],"reason":"术语表只被图鉴／界面文案消费"},
 {"path":"spire-godot/data/links.gd","domains":["LINK"],"reason":"链接定义由链接／装配用例断言"},
 {"path":"spire-godot/data/pressure_sources.gd","domains":["SOURCE","PRESSURE"],"reason":"压力来源定义由压力／遗物用例断言"},
 {"path":"spire-godot/data/relics.gd","domains":["RELIC"],"reason":"遗物表被图鉴／遗物／奖励／服务用例消费"},
 {"path":"spire-godot/ui/art_inspection.gd","domains":["ART"],"reason":"立绘检查层由图鉴／美术面用例打开的查看层消费，无 ui.<成员> 调用"},
 {"path":"spire-godot/ui/card_interaction.gd","domains":["CARD"],"reason":"卡牌翻面、悬停与拖放由 CARD 前缀的真实输入用例经主界面消费"},
 {"path":"spire-godot/ui/card_motion.gd","domains":["MOTION","REWARD"],"reason":"卡牌搬运动画由奖励／虹吸界面用例观察"},
 {"path":"spire-godot/ui/card_music.gd","domains":["MUSIC"],"reason":"曲目定义由能力卡／显示／首页界面用例消费"},
 {"path":"spire-godot/ui/chinese_collation.gd","domains":["BOOK"],"reason":"中文排序只服务图鉴与卡组浏览"},
 {"path":"spire-godot/ui/command_routes.gd","domains":["DISPLAY"],"reason":"M-I 分类子路由由显示用例的装配表消费（装配经 host.game.command），无 ui.<成员> 调用"},
 {"path":"spire-godot/ui/deck_browser.gd","domains":["DECK","BOOK"],"reason":"卡组浏览器由界面／图鉴用例打开"},
 {"path":"spire-godot/ui/departure_screen.gd","domains":["DEPART","ROUTE"],"reason":"出发界面随真实出发流程出现"},
 {"path":"spire-godot/ui/drop_target.gd","domains":["INTERACTION","DROP"],"reason":"拖放目标供交互／消耗品界面用例消费"},
 {"path":"spire-godot/ui/dungeon_backdrop.gd","domains":["DISPLAY"],"reason":"背景只参与显示模块的布局断言"},
 {"path":"spire-godot/ui/encyclopedia.gd","domains":["BOOK","CATALOG"],"reason":"图鉴界面由图鉴／界面／装备完成度用例打开"},
 {"path":"spire-godot/ui/enemy_feedback.gd","domains":["FEEDBACK","INTERACTION"],"reason":"敌人反馈层由敌人反馈／界面用例观察"},
 {"path":"spire-godot/ui/battle_feed.gd","domains":["FEED"],"reason":"即时记录层由敌人反馈用例验证提交增量、时序、去重与生命周期"},
 {"path":"spire-godot/ui/equipment_lock.gd","domains":["LOCK"],"reason":"锁标记由装备／敌人／装备完成度界面用例消费"},
 {"path":"spire-godot/ui/equipment_target_face.gd","domains":["RELEASE","LOCK"],"reason":"装备目标面版由释放／装备完成度用例打开"},
 {"path":"spire-godot/ui/event_screen.gd","domains":["EVENT"],"reason":"事件界面由事件模块用例经真实事件步骤打开"},
 {"path":"spire-godot/ui/feedback_report.gd","domains":["FEEDBACK"],"reason":"反馈报告草稿由反馈／界面用例消费"},
 {"path":"spire-godot/ui/first_turn_presenter.gd","domains":["CONTROL"],"reason":"首回合接管演出由首回合控制用例（CONTROL UI 前缀）消费，无 ui.<成员> 调用"},
 {"path":"spire-godot/ui/home_screen.gd","domains":["HOME","CUSTOM"],"reason":"首页由首页／首页存档／自定义开局用例断言"},
 {"path":"spire-godot/ui/intent_icon.gd","domains":["INTENT"],"reason":"意图图标由意图模块用例消费"},
 {"path":"spire-godot/ui/mana_flask.gd","domains":["FLASK","MANA"],"reason":"魔力小瓶界面由消耗品／能力卡／施法用例打开"},
 {"path":"spire-godot/ui/release_details.gd","domains":["RELEASE"],"reason":"释放详情由装备与身体布局用例打开"},
 {"path":"spire-godot/ui/relic_bundle_screen.gd","domains":["RELIC","BUNDLE"],"reason":"遗物捆界面由奖励／服务／图鉴用例打开"},
 {"path":"spire-godot/ui/resource_feedback.gd","domains":["FEEDBACK","REWARD"],"reason":"资源反馈由奖励／敌人反馈／界面用例观察"},
 {"path":"spire-godot/ui/reward_backdrop.gd","domains":["REWARD"],"reason":"奖励背板只随奖励面板出现"},
 {"path":"spire-godot/ui/reward_screen.gd","domains":["REWARD"],"reason":"奖励屏由奖励模块用例断言"},
 {"path":"spire-godot/ui/run_review.gd","domains":["ROUTE"],"reason":"本局回顾抽屉由出发路线用例（ROUTE 前缀）打开，无 ui.<成员> 调用"},
 {"path":"spire-godot/ui/shell/game_layout.gd","domains":["DISPLAY","INTERFACE"],"reason":"外壳布局由显示／界面用例断言"},
 {"path":"spire-godot/ui/shell/header.gd","domains":["HEADER","INTERFACE"],"reason":"标题栏由界面用例断言"},
 {"path":"spire-godot/ui/shop_glyph.gd","domains":["SHOP"],"reason":"商店图形由商店／服务用例消费"},
 {"path":"spire-godot/ui/shop_scenery.gd","domains":["SHOP"],"reason":"商店布景由商店／服务用例消费"},
 {"path":"spire-godot/ui/tutorial_book.gd","domains":["BOOK"],"reason":"教程书由图鉴／界面用例打开"},
]

const WIDEN=[

 # Only the hub file carries a declared amplification. save_store/snapshot were
 # considered (the has_relic lesson: a content condition broke save validation) but
 # rejected: impact:persistence expands to ~30 rule suites, which turns a 30-90s
 # development loop into a 15-minute one (contract §5.6). Those files keep their
 # index edges plus the core/** append, and the milestone full run covers the rest.
 {"path":"spire-godot/core/game.gd","add":"impact:persistence","reason":"存档与固定点写盘经 game 的提交路径（契约 §3.5 同例）"},
]

const EXCLUDE=[
 {"path":"spire-godot/tests/game_fixture.gd","reason":"夹具层太粗：多数用例文件预载它，闭包会把所有套件连到 core/game.gd"},
 {"path":"spire-godot/tests/exploration_fixture.gd","reason":"夹具层太粗：探索用例共享的状态构造，不区分套件"},
 {"path":"spire-godot/tests/route_driver.gd","reason":"夹具层太粗：为长流程提供下一步动作，不区分套件"},
 {"path":"spire-godot/tests/error_collector.gd","reason":"夹具层太粗：引擎错误计数被两个宿主共用"},
 {"path":"spire-godot/tests/suite_selection.gd","reason":"夹具层太粗：分类解析与交叉表被全部套件共用"},
 {"path":"spire-godot/tests/test_game.gd","reason":"宿主脚本：注册表与执行循环，不是被测对象"},
 {"path":"spire-godot/tests/ui_smoke.gd","reason":"宿主脚本：界面注册表与执行循环，不是被测对象"},
 {"path":"spire-godot/tests/recipe_driver.gd","reason":"宿主脚本：长时程真实输入配方自己的进程，不是被测对象"},
 {"path":"spire-godot/tests/batch_reuse_recorder.gd","reason":"夹具层：包装机制入口计数，只服务 architecture／recipe 的取证"},
 {"path":"spire-godot/tests/runtime_error_probe.gd","reason":"故意负例夹具：只被 --probe-runtime-error 调用"},
 {"path":"spire-godot/tests/hang_probe.gd","reason":"故意负例夹具：只被 -VerifyRunner 的超时探针调用"},
 {"path":"spire-godot/tests/check_index.gd","reason":"索引实现自身：不是用例文件，改动按 tests/** 闭包兜住"},
 {"path":"spire-godot/tests/check_index_edges.gd","reason":"索引手写层：不是用例文件，改动按 tests/** 闭包兜住"},
 {"path":"spire-godot/tests/check_index.json","reason":"冻结物：手改会同时被指纹与零漂移检查抓住"},
 {"path":"spire-godot/tests/route_plan.gd","reason":"计划宿主：只读冻结物，不触及 core|data|ui"}
]

const BLIND_BY_DESIGN=[
 {"path":"spire-godot/core/tool_rules.gd","reason":"状态相关工具查询经 g.Tools 间接消费，没有专属域词；由 spire-godot/core/ 闭包（all-dev）兜住"},
 {"path":"spire-godot/core/item_presentation.gd","reason":"道具文案是只读投影，无专属域词；由 spire-godot/core/ 闭包（all-dev）兜住"},
 {"path":"spire-godot/data/phases.gd","reason":"阶段定义只被存档校验与文案间接消费，无专属域词；由 spire-godot/data/ 闭包（all-dev）兜住"}
]

const INDEX_DEFECTS=[
 # {"date":"YYYY-MM-DD","path":"...","missed_suites":[...],"found_by":"...","log":"...","added":"..."}
]

const CLOSURE=[
 {"prefix":"spire-godot/core/","rules":"all-dev","reason":"core/game.gd 是所有规则的提交入口与状态机（docs/transition-pipeline.md §2.2）"},
 {"prefix":"spire-godot/data/","rules":"all-dev","reason":"data/*.gd 是 core 的唯一注册表来源（docs/project-map.md）"},
 {"prefix":"spire-godot/ui/","ui":"all-dev-ui","reason":"ui/main.gd 承载全部抽屉与提交入口（docs/ui-scene-refresh.md）"},
 {"prefix":"spire-godot/tests/","rules":"all-dev","ui":"all-dev-ui","reason":"无法归属的测试层文件（夹具／宿主／索引）没有单一套件，按测试层整体兜住"},
 {"prefix":"spire-godot/content/","rules":"content,event_flow,events,encyclopedia,shop_release,installation_priority,curses","gates":"content","reason":"内容消费者与内容门（docs/content-extension.md、tools/check-content.ps1）"},
 {"prefix":"spire-godot/assets/art/","rules":"localization","ui":"localization,hero_art,equipment_art","reason":"美术资源按本地化与立绘模块收窄（assets/art/ART-NOTES.md）"},
 {"prefix":"spire-godot/assets/","rules":"localization","ui":"localization","reason":"其余素材按本地化面收窄（docs/localization.md）"},
 {"prefix":"spire-godot/tools/","rules":"runner","reason":"改 tools/ 至少跑 runner；改 check.ps1 另跑 -VerifyRunner（契约 §7-1）"},
 {"prefix":"spire-godot/","rules":"all-dev","ui":"all-dev-ui","reason":"工程与主场景（project.godot／main.tscn）是全部套件的宿主"},
]

const ORACLE_NOTES=[
 {"path":"spire-godot/core/game.gd","note":"另跑迁移 oracle（build/transition-oracle-20260916）","reason":"状态迁移的唯一写入者与固定点声明都在此"},
 {"path":"spire-godot/core/room_events.gd","note":"另跑事件 oracle（build/event-oracle-20260916）","reason":"事件管线的冻结选项在此解析"},
]

const SUITE_EXEMPT=[
 {"suite":"rule:runner","reason":"runner 用例只检验测试基础设施（suite_selection／check_index），不触及 core|data|ui，故主表无键"},
 {"suite":"rule:core","reason":"SUITES 里的 core 是宿主 _core_cases() 承载的套件，没有用例文件，故无派生边"},
 {"suite":"ui:baseline","reason":"UI_MODULES 里的 baseline 由宿主 _baseline_tests() 承载，没有用例文件，故无派生边"},
]
