extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

# Real practice navigation and controls; configuration is owned by trader_cases.
static func run(t) -> void:
 var ui=t.ui
 await t.start_practice("Practice_trader_solo")
 var enemy=ui.game.state.enemies[0]
 var id=enemy.id
 t.check(ui.view.phase=="battle" and ui.view.enemies.size()==1 and ui.view.enemies[0].template=="trader" and ui.view.enemies[0].maximum==56,"TRADER real practice enters fixed encounter")
 t.check(t.visible_text(ui.layout).contains("奴隶贩子") and ui.find_child("EnemyArt_"+id,true,false).mode=="trader","TRADER real name and native human art")
 t.check(ui.view.statuses.all(func(row):return row.id!="weakness" and row.id!="ready_"+id),"TRADER zero effects do not create status rows")
 t.check(await t.click("end"),"TRADER first application through a real turn")
 # Isolate weakness from the randomized opening's hand/eye/mouth restrictions.
 # This fixture changes equipment only; debuff and readiness come from real turns.
 ui.game.state.equipment.clear();ui.game.state.composites.clear();ui.game.state.links.clear()
 var target=ui.game.add_fixture("wrist",8)
 ui.game._cleanup();ui.render();await t.frames()
 t.check(await t.click("end") and ui.game.state.get("weakness_turns",0)==1,"TRADER second real action applies one player turn of weakness")
 for type in ["strike","heavy","kick"]:
  var c=Queries.find(ui.view,"attack",{"type":type,"enemy":id})
  t.check(not c.is_empty(),"TRADER base attack candidate remains visible "+type)
  if c.is_empty(): continue
  var button=ui.candidate_buttons[c.key]
  t.check(not c.valid and c.reason.contains("无力化") and button.disabled,"TRADER weakness disables base attack with explicit reason "+type)
  t.check(button.get_theme_color("font_disabled_color").get_luminance()<button.get_theme_color("font_color").get_luminance(),"TRADER disabled attack uses low brightness "+type)
 t.check(t.visible_text(ui.find_child("AttackActions",true,false)).contains("无力化"),"TRADER attack reason is visible beside controls")
 var before=JSON.stringify(ui.game.state)
 await Navigation.press(t,"OpenStatus")
 var status=ui.find_child("Status_weakness",true,false)
 t.check(status!=null,"TRADER actual status panel includes weakness")
 if status!=null:
  var text=await preload("res://tests/status_ui_cases.gd").inspect(t,"weakness")
  t.check(text.contains("1个玩家回合") and text.contains("火球") and text.contains("卡牌魔法"),"TRADER status states duration and unaffected magic")
 t.check(JSON.stringify(ui.game.state)==before,"TRADER reading status preserves state and random counters")
 await t.close_information()
 t.check(Queries.find(ui.view,"attack",{"type":"fireball","enemy":id}).valid and not t.action_button("fireball").disabled,"TRADER fireball remains available during weakness")
 # Put an existing magic card in hand to inspect and use its real bound face.
 var magic={}
 for zone in ["hand","draw","discard"]:
  for card in ui.game.state[zone]:
   if card.type=="ease": magic=card;break
  if not magic.is_empty(): break
 t.check(not magic.is_empty(),"TRADER practice deck contains magic card")
 if not magic.is_empty():
  for zone in ["draw","discard"]: ui.game.state[zone].erase(magic)
  if not ui.game.state.hand.has(magic): ui.game.state.hand.append(magic)
  ui.card_faces[magic.uid]=false;ui.render();await t.frames()
  var c=Queries.find(ui.view,"card",{"uid":magic.uid,"slot":"wrist","target":target.id,"free":false})
  t.check(not c.is_empty() and c.valid and ui.card_buttons[magic.uid].modulate.r==1,"TRADER magic card remains usable and bright during weakness")
  if not c.is_empty() and c.valid:
   await t.start_drag(magic.uid,"wrist")
   await t.release_target(await t.reveal_drop_target(c.key))
   t.check(ui.game._equipment(target.id).is_empty() or ui.game._equipment(target.id).durability<8,"TRADER real magic card resolves under weakness")
 t.check(await t.click("attack",{"type":"fireball","enemy":id}) and ui.game._enemy(id).hp<56,"TRADER real fireball damages enemy under weakness")
 t.check(await t.click("end") and ui.game.state.get("weakness_turns",0)==0 and ui.game._enemy(id).get("ready_layers",0)==1,"TRADER next real application expires weakness and gains readiness")
 await Navigation.press(t,"OpenStatus")
 t.check(ui.find_child("Status_weakness",true,false)==null and ui.find_child("Status_ready_"+id,true,false)!=null,"TRADER status panel refreshes from actual effects")
 # Display boundary: stacked source value, read-only projection and departure.
 ui.game._enemy(id).ready_layers=3;ui.render();await t.frames()
 before=JSON.stringify(ui.game.state)
 var ready=ui.view.statuses.filter(func(row):return row.id=="ready_"+id)[0]
 t.check(ready.value=="3层" and ready.source==enemy.name and ready.detail.contains("失败") and ready.detail.contains("3档"),"TRADER readiness shows exact source, stack count and consumption rule")
 t.check(t.visible_text(ui.find_child("Status_ready_"+id,true,false)).contains("3层"),"TRADER actual panel renders stacked value")
 ui.game.get_view()
 t.check(JSON.stringify(ui.game.state)==before,"TRADER stacked status projection is read-only")
 ui.game._enemy(id).gone=true;ui.render();await t.frames()
 t.check(ui.find_child("Status_ready_"+id,true,false)==null and ui.view.statuses.all(func(row):return row.id!="ready_"+id),"TRADER departed source leaves no readiness display")
