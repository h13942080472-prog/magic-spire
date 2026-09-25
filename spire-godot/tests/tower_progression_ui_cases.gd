extends RefCounted
const Cases=preload("res://tests/tower_progression_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func enter_room(t, target: String) -> void:
 Cases.before_room(t.ui.game,target)
 t.ui.render();await t.frames()
 if t.ui.view.phase=="rest": t.check(await t.click("finish_rest"),"SUMMIT UI real rest service opens onward route")
 t.check(t.ui.view.phase=="map","SUMMIT UI completed parent offers actual next room")
 t.check(await t.click("depart",{"room":target}),"SUMMIT UI actual adjacent travel "+target)
 var guard=0
 while t.ui.view.phase=="travel" and guard<12:
  t.check(await t.click("travel_step"),"SUMMIT UI real travel advances")
  guard+=1

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 await t.finish_ui_room()
 ui.map_overview=true;ui.render();await t.frames()
 t.check(ui.view.route.any(func(r):return r.icon=="elite") and ui.view.route.filter(func(r):return r.icon=="boss").size()==1,"SUMMIT UI map projects two optional elites and unique boss")
 t.check(ui.find_child("TowerRoute",true,false).rooms.any(func(r):return r.icon=="boss"),"SUMMIT UI map draws registered boss icon")
 var before=JSON.stringify(ui.game.state)
 var graph=ui.find_child("TowerRoute",true,false)
 var point=graph.buttons.summit.get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.route_focus=="summit" and JSON.stringify(ui.game.state)==before and ui.notice==ui.view.route.filter(func(room):return room.id=="summit")[0].entry_reason and ui.notice!="","SUMMIT UI future summit click shows actual route rejection without jumping rooms")
 await t.capture("ui-41-elite-summit-map.png")
 ui.map_overview=false
 var elite=ui.view.route.filter(func(r):return r.icon=="elite")[0].id
 # This interaction checks the guard; the elite pool can also select other families.
 ui.game.room_data(elite).encounter="guard_solo"
 ui.game.state.room_encounters[elite]="guard_solo"
 await enter_room(t,elite)
 t.check(not ui.view.practice and ui.view.enemies.size()==1 and ui.view.enemies[0].template=="guard" and ui.view.enemies[0].maximum==90 and ui.view.room_name==ui.game.room_data(elite).name,"SUMMIT UI guard now belongs to a real tower room")
 # Travel's passive slip can remove the opening ankle restraint; establish this attack's fixture explicitly.
 if not ui.game._bound_feet(): ui.game.add_fixture("ankle",8)
 ui.render();await t.frames()
 await t.capture("ui-42-tower-elite.png")
 var enemy=ui.view.enemies[0].id
 var kick=ui.view.display_facts.filter(func(c):return c.payload.kind=="attack" and c.payload.type=="kick" and c.payload.form==0 and c.payload.enemy==enemy)[0]
 var enemy_health=ui.game._enemy(enemy).hp
 await t.drag_control_to(t.action_button("kick"),enemy)
 t.check(kick.valid and ui.game._enemy(enemy).hp==enemy_health-kick.payload.damage and ui.game._enemy(enemy).intent.delayed and ui.game.state.posture=="lie","SUMMIT UI actual leg restraint enables binding kick with offered damage, interrupt and fall cost")
 await t.finish_ui_room()
 t.check(ui.view.phase=="map" and ui.game.state.completed_rooms.has(elite),"SUMMIT UI elite victory returns to actual connected tower routes")

 ui.restart(43);await t.frames()
 ui.game.state.room_encounters.summit="iron_man_solo";ui.game.room_data("summit").encounter="iron_man_solo";ui.game.room_data("summit").name="塔顶 · 铁男"
 await enter_room(t,"summit")
 var iron_members={}
 for member in ui.view.enemies: iron_members[member.template]=member.maximum
 t.check(iron_members=={"iron_man":140.0,"binding_box":40.0,"iron_drone":40.0} and ui.view.room_name=="塔顶 · 铁男","SUMMIT UI Iron Man boss room displays the boss and both approved supports")
 var iron_id=ui.view.enemies.filter(func(e):return e.template=="iron_man")[0].id
 var iron_art=ui.find_child("EnemyArt_"+iron_id,true,false)
 t.check(iron_art.mode=="iron_man" and is_instance_valid(iron_art.enemy_sprite) and iron_art.enemy_sprite.texture.resource_path.ends_with("/iron_man.svg") and iron_art.enemy_sprite.texture.get_image().detect_alpha()!=Image.ALPHA_NONE,"SUMMIT ART actual Iron Man boss resolves its own transparent mechanical portrait")
 await t.capture("ui-iron-man-battle.png")

 ui.restart(42);await t.frames()
 ui.game.state.room_encounters.summit="six_bind_solo";ui.game.room_data("summit").encounter="six_bind_solo";ui.game.room_data("summit").name="塔顶 · 六缚"
 await enter_room(t,"summit")
 t.check(not ui.view.practice and ui.view.enemies.size()==1 and ui.view.enemies[0].template=="six_bind" and ui.view.enemies[0].maximum==200 and ui.view.room_name=="塔顶 · 六缚","SUMMIT UI final room starts the real boss battle")
 await t.capture("ui-43-summit-battle.png")
 var boss=ui.view.enemies[0].id
 await t.drag_control_to(t.action_button("kick"),boss)
 t.check(ui.view.enemies[0].hp<200,"SUMMIT UI direct drag damages the actual boss")
 for e in ui.game.state.enemies:
  e.intent={"kind":"capture","text":"执行收押","delayed":false}
 ui.render();await t.frames()
 t.check(await t.click("end") and ui.view.phase=="captured" and ui.view.security==1 and ui.view.reward_count==0,"SUMMIT UI capture exits final battle once without winning")
 t.check(t.visible_text(ui.layout).contains("重新开始") and not t.visible_text(ui.layout).contains("再次挑战"),"SUMMIT UI run loss offers the current new-run action instead of equipment practice")
 await t.capture("ui-44-summit-capture.png")
 t.check(await t.click("prison",{"action":"enter"}) and ui.view.phase=="prison" and not ui.view.practice,"SUMMIT UI loss continues through shared real prison mode")

 ui.restart(42);await t.frames()
 ui.game.state.room_encounters.summit="six_bind_solo";ui.game.room_data("summit").encounter="six_bind_solo";ui.game.room_data("summit").name="塔顶 · 六缚"
 await enter_room(t,"summit")
 await t.finish_ui_room()
 t.check(ui.view.phase=="map" and ui.game.state.completed_rooms.has("summit") and Queries.find(ui.view,"route",{"room":"exit"}).valid,"SUMMIT UI actual victory/reward/preparation opens exit")
 var reward=ui.view.reward_count;var mana=ui.view.mana
 t.check(await t.click("depart",{"room":"exit"}),"SUMMIT UI depart through newly unlocked exit")
 while ui.view.phase=="travel": t.check(await t.click("travel_step"),"SUMMIT UI final movement commits")
 t.check(ui.view.phase=="cleared" and ui.view.reward_count==reward and ui.view.mana==mana and t.visible_text(ui.layout).contains("第一阶段完成"),"SUMMIT UI clears after 六缚 without extra rewards or healing")
 await t.capture("ui-45-summit-cleared.png")
 t.check(t.visible_text(ui.layout).contains("感谢游玩这次demo") and Queries.select(ui.view,"demo_exit").any(func(c):return c.payload.kind=="demo_continue" and c.valid),"EXIT UI thanks player and offers continuation")
 ui.game.state.pressure=75.0;ui.game.state.posture="lie";ui.render();await t.frames()
 t.check(t.visible_text(ui.layout).contains("快感降低40") and t.visible_text(ui.layout).contains("姿势变为站立"),"EXIT UI continuation explains its recovery before clicking")
 t.check(await t.click("demo_continue") and ui.view.demo_cycle==1 and ui.view.phase=="map" and ui.view.mana==ui.game.state.mana_max and ui.game.action_targets().is_empty(),"EXIT UI continue rebuilds tower and clears equipment")
 t.check(ui.view.pressure.value==35.0 and ui.view.posture=="stand" and ui.game.state.logs.any(func(log):return log.text.contains("快感降低40，姿势变为站立")),"EXIT UI real continuation shows reduced pressure, standing and matching log")
 ui.game.state.room_encounters.summit="six_bind_solo";ui.game.room_data("summit").encounter="six_bind_solo";ui.game.room_data("summit").name="塔顶 · 六缚"
 await enter_room(t,"summit")
 t.check(ui.view.enemies[0].maximum==300,"EXIT UI next tower displays scaled boss health")
 # Final-cycle boundary only; skip replaying the already-covered full battle path.
 ui.game.state.demo_cycle=2
 preload("res://tests/demo_exit_cases.gd").exit_fixture(ui.game)
 ui.render();await t.frames()
 t.check(Queries.select(ui.view,"demo_exit").size()==1 and Queries.select(ui.view,"demo_exit")[0].payload.kind=="demo_end","EXIT UI final cycle has no continue button")
 t.check(await t.click("demo_end") and ui.game.state.demo_finished and ui.find_child("HomeContinue",true,false).disabled,"EXIT UI end returns to menu with finished run unavailable")
