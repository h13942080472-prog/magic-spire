extends RefCounted
const Click=preload("res://tests/interface_ui_cases.gd")
const Cases=preload("res://tests/departure_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.game_factory=preload("res://core/game.gd");ui.restart(42);await t.frames()
 var before=ui.game.export_snapshot()
 preload("res://tests/relic_bundle_ui_cases.gd").check_backdrop(t,ui.find_child("BattleRewards",true,false))
 t.check(ui.view.phase=="departure" and ui.find_child("HeaderFloor",true,false).text=="第0层" and ui.find_child("DepartureOption_4",true,false)!=null,"OPENING UI shows floor zero and five categories")
 var fourth=ui.find_child("DepartureOption_3",true,false).get_global_rect()
 var fifth=ui.find_child("DepartureOption_4",true,false).get_global_rect()
 t.check(is_equal_approx(fourth.position.x,fifth.position.x) and fifth.position.y>fourth.end.y and fifth.end.y<ui.find_child("DepartureContinue",true,false).get_global_rect().position.y,"OPENING UI fifth swap sits below fourth without overlapping continue")
 t.check(ui.view.reward_panel.entries[3].detail.contains("Boss") and ui.view.reward_panel.entries[3].label=="初始遗物交换","OPENING UI fourth slot always describes starter exchange")
 await t.capture("ui-departure.png")
 await Click.press(t,"OpenMap")
 t.check(ui.show_route and ui.find_child("TowerRoute",true,false)!=null and ui.game.export_snapshot()==before,"OPENING UI map preview has no cost or reroll")
 await Click.press(t,"OpenMap")
 t.check(not ui.show_route and ui.find_child("DepartureOption_0",true,false)!=null and ui.game.export_snapshot()==before,"OPENING UI map returns to same five options")
 await Click.press(t,"DepartureOption_4")
 t.check(ui.game.state.relics==["return_seal","desire_cube_pro_max"] and ui.view.reward_panel.stage=="done" and ui.game.state.pressure==50,"OPENING UI fifth button exchanges the starter, keeps the return seal and grants pressure")
 t.check(await t.click("departure",{"op":"finish"}) and ui.view.phase=="map","OPENING UI confirmation enters actual route")
 ui.game=Cases.fixture("transform");ui._reset_interface(ui.game.get_view());ui.render();await t.frames()
 t.check(await t.click("departure",{"op":"choose","option":"transform"}) and ui.find_child("DepartureCards",true,false)!=null and ui.find_child("DepartureContinue",true,false)==null,"OPENING UI transform opens card picker with no skip")
 await t.capture("ui-departure-cards.png")
 t.check(await t.click("departure",{"op":"card"}) and ui.game.state.departure.stage=="done" and ui.view.reward_panel.destination.contains("变化为"),"OPENING UI card click performs actual transformation and shows result")
 t.check(await t.click("departure",{"op":"finish"}) and ui.view.phase=="map","OPENING UI result confirmation leaves opening")
 ui.game=Cases.fixture("wrist");ui._reset_interface(ui.game.get_view());ui.render();await t.frames()
 t.check(await t.click("departure",{"op":"choose","option":"wrist"}) and ui.game.state.equipment.size()==1 and ui.view.reward_panel.destination.contains("中级、紧度3、无锁"),"OPENING UI wrist option installs medium unlocked tier-three rope")
 ui.game=preload("res://core/game.gd").new(42,false,"equipment",true,false,25,false,false,"witch")
 ui._reset_interface(ui.game.get_view());ui.render();await t.frames()
 t.check(ui.find_child("DepartureOption_4",true,false)==null and ui.find_child("DepartureOption_3",true,false)!=null and ui.view.reward_panel.destination.contains("四选一"),"OPENING UI witch retains four options without original-only swap")
 await cube_boss_pickup(t)
 ui.game_factory=preload("res://tests/game_fixture.gd")

static func cube_boss_pickup(t) -> void:
 var ui=t.ui;var type="desire_cube_pro_max"
 for role in ["original","witch"]:
  ui.game=preload("res://core/game.gd").new(42,false,"equipment",true,false,25,false,false,role)
  var g=ui.game
  g.state.room="summit";g._start_battle();g._finish_battle();g.state.pressure=0.0
  for attempt in range(32):
   if type in g.state.boss_relic_options: break
   g.RelicRewards.battle_drop(g)
  ui._reset_interface(g.get_view());ui.render();await t.frames()
  var before=g.export_snapshot()
  t.check(await t.click("reward",{"category":"relic","type":type}) and type in g.state.relics and g.state.deck.size()==before.deck.size()+2,"DESIRE UI actual boss selection grants permanent bonus cards: "+role)
  var heart=g.state.hand.filter(func(card):return card.type==g.Character.card_id(g,"itching_heart"))
  t.check(heart.size()==1 and g.state.relics.filter(func(id):return g.Relics.TYPES[id].get("required_relic","")==type).size()==1,"DESIRE UI bonus heart enters hand and one themed relic is owned: "+role)
  t.check(await t.click("reward",{"type":"skip"}) and ui.view.phase=="prepare" and ui.card_buttons.has(heart[0].uid),"DESIRE UI bonus heart is usable in preparation after leaving rewards: "+role)
