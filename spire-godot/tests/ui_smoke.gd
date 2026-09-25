extends SceneTree
const Queries=preload("res://ui/target_queries.gd")

var ui
var screenshots: Array=[]
var engine_errors=preload("res://tests/error_collector.gd").new()
var failures: Array[String]=[]
var assertions=0
var started_at=Time.get_ticks_msec()
var external_mouse_events=0
var mouse_position=Vector2.ZERO
var drag_test_slot=""
const UI_MODULES={"localization":"res://tests/localization_ui_cases.gd","card_power":"res://tests/card_power_ui_cases.gd","encyclopedia":"res://tests/encyclopedia_ui_cases.gd","home_persistence":"res://tests/home_persistence_ui_cases.gd","siphon":"res://tests/siphon_ui_cases.gd","card_splash":"res://tests/card_splash_ui_cases.gd","display":"res://tests/display_ui_cases.gd","basic_attacks":"res://tests/basic_attack_ui_cases.gd","trader":"res://tests/trader_ui_cases.gd","installed_tools":"res://tests/installed_tools_ui_cases.gd","exploration":"res://tests/exploration_ui_cases.gd","hand_assist":"res://tests/hand_assist_ui_cases.gd","shoulder":"res://tests/shoulder_ui_cases.gd","slip_motion":"res://tests/slip_motion_ui_cases.gd","torso_binding":"res://tests/torso_binding_ui_cases.gd",
 "items":"res://tests/item_inventory_ui_cases.gd",
 "touch":"res://tests/touch_ui_cases.gd",
 "keyboard":"res://tests/keyboard_ui_cases.gd",
 "casting":"res://tests/casting_ui_cases.gd",
 "card_growth":"res://tests/concentration_ui_cases.gd",
 "wall":"res://tests/wall_ui_cases.gd",
 "special_equipment":"res://tests/special_equipment_ui_cases.gd",
 "baseline":null,
 "home":"res://tests/home_ui_cases.gd",
 "enemy_feedback":"res://tests/enemy_feedback_ui_cases.gd",
 "route":"res://tests/route_ui_cases.gd",
 "services":"res://tests/service_ui_cases.gd",
 "equipment_art":"res://tests/equipment_art_ui_cases.gd",
 "hero_art":"res://tests/hero_art_ui_cases.gd",
 "body_layout":"res://tests/body_layout_ui_cases.gd",
 "targeting":"res://tests/target_sidebar_ui_cases.gd",
 "intent":"res://tests/intent_ui_cases.gd",
 "action_copy":"res://tests/action_copy_ui_cases.gd",
 "status":"res://tests/status_ui_cases.gd",
 "interface":"res://tests/interface_ui_cases.gd",
 "normal_play":"res://tests/normal_play_ui_cases.gd",
 "enemies":"res://tests/enemy_ui_cases.gd",
 "equipment_complete":"res://tests/equipment_ui_cases.gd",
 "pressure":"res://tests/pressure_ui_cases.gd",
 "impact_feedback":"res://tests/impact_feedback_ui_cases.gd",
 "guard":"res://tests/guard_ui_cases.gd",
 "prison":"res://tests/prison_ui_cases.gd",
 "tower_progression":"res://tests/tower_progression_ui_cases.gd",
 "events":"res://tests/event_ui_cases.gd",
 "consumables":"res://tests/consumable_ui_cases.gd",
 "rewards":"res://tests/reward_ui_cases.gd",
 "persistence":"res://tests/persistence_ui_cases.gd"}

func module_checks(selected: Array) -> void:
 for name in UI_MODULES:
  if not "all" in selected and not name in selected: continue
  print("SUITE START: "+name)
  var previous_failures=failures.size();var previous_errors=engine_errors.count()
  ui.game_factory=preload("res://core/game.gd") if name in ["services","normal_play","route"] else preload("res://tests/game_fixture.gd")
  # Ordinary scenarios use a returning player; home tests exercise first launch explicitly.
  ui.display_settings.first_battle_tutorial_seen=true
  ui.restart(20260906 if name=="baseline" else 42);await frames()
  if engine_errors.count()>previous_errors: return
  var started=Time.get_ticks_msec();var before=assertions
  if name=="baseline": await _baseline_tests()
  else:
   var suite=load(UI_MODULES[name])
   if suite==null or not suite.can_instantiate():
    check(false,"Cannot load selected UI suite: "+name);return
   await suite.run(self)
  print("UI SUITE %s: %d assertions, %d ms" % [name,assertions-before,Time.get_ticks_msec()-started])
  var failed=failures.size()>previous_failures or engine_errors.count()>previous_errors
  print("SUITE RESULT: %s %s" % [name,"FAIL" if failed else "PASS"])
  var runtime_error=engine_errors.count()-previous_errors>failures.size()-previous_failures
  if failed and (runtime_error or "--keep-going" not in OS.get_cmdline_user_args()): return

func finish_checks() -> void:
 print("UI TIME: %d ms" % (Time.get_ticks_msec()-started_at))
 print("UI INPUT: ",external_mouse_events," OS mouse events isolated from scripted pointer")
 var passed=failures.is_empty() and engine_errors.count()==0
 print("UI %s: %d assertions" % ["PASS" if passed else "FAIL",assertions])
 if not passed: print("UI ENGINE ERRORS: ",engine_errors.count())
 quit(0 if passed else 1)

func _initialize() -> void:
 OS.add_logger(engine_errors)
 if "--probe-runtime-error" in OS.get_cmdline_user_args():
  preload("res://tests/runtime_error_probe.gd").run()
  finish_checks();return
 _run.call_deferred()

func check(ok: bool, text: String) -> void:
 assertions+=1
 if not ok:
  failures.append(text)
  push_error(text)

func frames(n: int=2, settle_feedback: bool=true) -> void:
 # Animation assertions observe intermediate frames; ordinary input still waits
 # for arrival before accessing the real interactive card controls.
 if settle_feedback and is_instance_valid(ui) and is_instance_valid(ui.enemy_feedback):
  var deadline=Time.get_ticks_msec()+5000
  while is_instance_valid(ui.enemy_feedback) and Time.get_ticks_msec()<deadline: await process_frame
 if settle_feedback and is_instance_valid(ui) and is_instance_valid(ui.card_motion):
  var deadline=Time.get_ticks_msec()+5000
  while is_instance_valid(ui.card_motion) and not ui.card_motion.pending_draws.is_empty() and Time.get_ticks_msec()<deadline: await process_frame
 for i in range(n): await process_frame
 # Wait for the actual resized/scrolled canvas before the next pointer event.
 await RenderingServer.frame_post_draw

func open_menu() -> void:
 if ui.show_menu: return
 await close_information()
 var button=ui.find_child("OpenMenu",true,false)
 var point=button.get_global_rect().get_center()
 await move_mouse(point)
 await mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await mouse_button(point,MOUSE_BUTTON_LEFT,false)
 check(ui.show_menu and ui.find_child("OpenRestart",true,false)!=null,"MENU native click opens secondary actions")

func close_information() -> void:
 var close=ui.find_child("CloseDrawer",true,false)
 if close==null: return
 var point=close.get_global_rect().get_center()
 await move_mouse(point)
 await mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await mouse_button(point,MOUSE_BUTTON_LEFT,false)
 check(ui.find_child("InformationDrawer",true,false)==null,"PANEL close information before returning to cards")

func inspect_body(slot: String) -> void:
 await close_information()
 if ui.show_body and ui._body_at(ui.selected_slot).id==ui._body_at(slot).id: return
 await reveal_body(slot)
 var point=ui.body_buttons[slot].get_global_rect().get_center()
 await move_mouse(point)
 await mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await mouse_button(point,MOUSE_BUTTON_LEFT,false)
 check(ui.show_body and ui._body_at(ui.selected_slot).id==ui._body_at(slot).id and ui.find_child("EquipmentDetails",true,false)!=null,"BODY native click opens selected body details")

func reveal_body(slot: String) -> void:
 var button=ui.body_buttons[slot]
 if button.get_meta("body_id",slot)==ui._body_at(slot).id: return
 var point=button.get_global_rect().get_center()
 await move_mouse(point)
 await mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await mouse_button(point,MOUSE_BUTTON_LEFT,false)

# 显示键（R3 域）优先、行身份键（R4／R5 域）回落：按钮注册键随批迁移，测试语义不变。
func candidate_button(c: Dictionary) -> Button:
 var key=ui.display_key(c.payload)
 if ui.candidate_buttons.has(key): return ui.candidate_buttons[key] as Button
 if ui.candidate_buttons.has(String(c.get("key",""))): return ui.candidate_buttons[String(c.get("key",""))] as Button
 return null

func click(kind: String, extra: Dictionary={}, settle_feedback: bool=true) -> bool:
 # Result acknowledgement is a real UI click, not a rule action or skipped stage.
 if kind=="event":
  var next=ui.find_child("EventContinue",true,false)
  if next!=null:
   var point=next.get_global_rect().get_center()
   await move_mouse(point)
   await mouse_button(point,MOUSE_BUTTON_LEFT,true)
   await mouse_button(point,MOUSE_BUTTON_LEFT,false)
 for c in ui.view.display_facts:
  if c.payload.kind!=kind or not c.valid: continue
  var matches=true
  for k in extra:
   if c.payload.get(k)!=extra[k]: matches=false
  if matches and candidate_button(c)==null and ui.view.reward_panel.active:
   var rows=ui.view.battle_rewards.filter(func(row):return Queries.fact_key(c) in row.action_keys)
   if not rows.is_empty():
    var row=rows[0]
    var opener=ui.find_child("Reward_"+row.category+("_"+row.id if row.id!="" else ""),true,false)
    if opener!=null: opener.pressed.emit();await frames()
  if matches and kind=="event" and candidate_button(c)==null:
   var groups=ui.view.room_event.selections.filter(func(group):return group.options.any(func(option):return option.choice==c.payload.get("choice","")))
   if not groups.is_empty(): await preload("res://tests/event_ui_cases.gd").open_selection(self,groups[0].id)
   elif c.payload.action=="reward" and c.payload.get("type","")!="skip": await preload("res://tests/event_ui_cases.gd").open_selection(self,"reward")
  if matches and kind=="item_use" and candidate_button(c)==null:
   var item=ui.view.items.filter(func(i):return i.id==c.payload.item)[0]
   var groups=item.target_groups.filter(func(group):return Queries.fact_key(c) in group.keys)
   if not groups.is_empty():
    ui.selected_item=item.id;ui.selected_item_slot=""
    if ui.show_items: ui.render(ui.view)
    else: ui._open_drawer("show_items")
    await frames()
    var menu=ui.find_child("ToolSlot_"+groups[0].id,true,false)
    if menu!=null: menu.pressed.emit();await frames()
  if matches and kind=="item_install" and candidate_button(c)==null:
   ui.selected_item=c.payload.item;ui.selected_item_slot=""
   if ui.show_items: ui.render(ui.view)
   else: ui._open_drawer("show_items")
   await frames()
   var install_menu=ui.find_child("ToolInstallMenu",true,false)
   if install_menu!=null: install_menu.pressed.emit();await frames()
  var button=candidate_button(c)
  if matches and button!=null:
   button.pressed.emit()
   await frames(2,settle_feedback)
   return true
 return false

func capture(filename: String) -> void:
 if filename not in screenshots and "*" not in screenshots: return
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://build/"+filename)==OK,"screenshot "+filename)

func move_mouse(point: Vector2, held: bool=false) -> void:
 var event=InputEventMouseMotion.new()
 event.position=point
 event.global_position=point
 event.relative=point-mouse_position
 mouse_position=point
 event.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0
 root.push_input(event,true)
 await frames()

func mouse_button(point: Vector2, button: int, pressed: bool) -> void:
 var event=InputEventMouseButton.new()
 event.position=point
 event.global_position=point
 event.button_index=button
 event.pressed=pressed
 event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed and button==MOUSE_BUTTON_LEFT else 0
 root.push_input(event,true)
 await frames()

func card_point(uid: String) -> Vector2:
 return ui.card_buttons[uid].get_global_transform_with_canvas()*Vector2(80,75)

func flip(uid: String) -> void:
 await close_information()
 await move_mouse(card_point(uid))
 await mouse_button(card_point(uid),MOUSE_BUTTON_RIGHT,true)
 await mouse_button(card_point(uid),MOUSE_BUTTON_RIGHT,false)

func start_drag(uid: String, slot: String) -> void:
 drag_test_slot=slot
 await close_information()
 await reveal_body(slot)
 await move_mouse(card_point(uid))
 var point=card_point(uid)
 await mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await move_mouse(point+Vector2(0,-42),true)
 check(root.gui_is_dragging(),"native card drag starts")
 await move_mouse(ui.body_buttons[slot].get_global_rect().get_center(),true)
 check(ui.active_drag.get("card_uid","")==uid,"native drag keeps its readonly target context across body hover")

func release_target(index: int=-1) -> void:
 if ui.drop_targets.is_empty():
  var destination=Vector2(1050,90)
  if ui.drag_hints.any(func(hint):return hint.get_meta("target_id","")=="hero"):
   destination=ui.actor_targets.hero.get_global_rect().get_center()
  await move_mouse(destination,true)
  await mouse_button(destination,MOUSE_BUTTON_LEFT,false)
  return
 if index<0:
  var body=ui._body_at(drag_test_slot)
  var matching=ui.drop_targets.keys().filter(func(id):return Queries.fact_by_key(ui.view,id).payload.get("slot","") in body.slots)
  index=ui.drop_targets.keys().find(matching[0]) if not matching.is_empty() else 0
 var target=ui.drop_targets.values()[index]
 var point=target.get_global_rect().get_center()
 await move_mouse(point,true)
 await mouse_button(point,MOUSE_BUTTON_LEFT,false)

func reveal_drop_target(id: String) -> int:
 var key=id
 if not ui.drop_targets.has(key):
  var physical=Queries.fact_by_key(ui.view,id).get("payload",{}).get("target",id)
  var matches=ui.drop_targets.keys().filter(func(entry_key):return Queries.fact_by_key(ui.view,entry_key).get("payload",{}).get("target","")==physical)
  if not matches.is_empty(): key=matches[0]
 var index=ui.drop_targets.keys().find(key)
 check(index>=0,"requested physical target appears in drag popout")
 if index<0: return 0
 var button=ui.drop_targets[key]
 var ancestor=button.get_parent()
 while ancestor!=null and not ancestor is ScrollContainer: ancestor=ancestor.get_parent()
 if ancestor!=null: ancestor.ensure_control_visible(button)
 await frames()
 await move_mouse(button.get_global_rect().get_center(),root.gui_is_dragging())
 return index

func start_practice(node_name: String) -> void:
 await open_menu()
 ui.find_child("OpenRestart",true,false).pressed.emit(); await frames()
 var entry=ui.find_child(node_name,true,false)
 check(entry!=null and entry.is_visible_in_tree(),"practice entry visible: "+node_name)
 var ancestor=entry.get_parent()
 while ancestor!=null and not ancestor is ScrollContainer: ancestor=ancestor.get_parent()
 if ancestor!=null: ancestor.ensure_control_visible(entry)
 await frames()
 var point=entry.get_global_rect().get_center()
 await move_mouse(point)
 await mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await mouse_button(point,MOUSE_BUTTON_LEFT,false)

func finish_ui_room() -> void:
 if ui.view.phase in ["shop","treasure"]: check(await click("service",{"op":"leave"}),"UI ROUTE leaves service room through real action")
 if ui.view.phase=="rest_choice": check(await click("rest_begin"),"UI ROUTE selects rest duration")
 if ui.view.phase=="rest": check(await click("finish_rest"),"UI ROUTE leaves rest through real action")
 if ui.view.phase=="event":
  for step in range(30):
   if ui.view.phase!="event": break
   var next=preload("res://tests/route_driver.gd").event_action(ui.view.display_facts)
   check(not next.is_empty(),"UI ROUTE event has an available real step")
   if next.is_empty(): break
   var version=ui.view.version
   var committed=await click("event",next.payload)
   check(committed and ui.view.version>version,"UI ROUTE real event step commits once")
   if not committed or ui.view.version==version: break
  check(ui.view.phase!="event","UI ROUTE event resolves before travel")
 var guard=0
 while ui.view.phase=="battle" and guard<10:
  guard+=1
  if ui.view.energy==0:
   check(await click("end"),"UI ROUTE exhausted energy advances through a real turn")
   continue
  if preload("res://tests/route_driver.gd").shorten_persistent_enemies(ui.game):
   var attack=preload("res://tests/route_driver.gd").attack(ui.game)
   check(not attack.is_empty(),"UI ROUTE shortened guard requires legal real attack")
   if attack.is_empty(): return
   ui.selected_enemy=attack.payload.enemy;ui.render();await frames()
   check(await click("attack",{"type":attack.payload.type,"enemy":attack.payload.enemy}),"UI ROUTE actual attack defeats guard fixture")
  else: check(await click("end"),"end encounter round")
 if ui.view.phase=="reward": check(await click("reward",{"type":"skip"}),"skip optional reward")
 for i in range(20):
  var preparation=preload("res://tests/route_driver.gd").prepare_action(ui.game)
  if preparation.is_empty(): break
  var p=preparation.payload
  if p.kind=="card":
   if ui.card_faces.get(p.uid,false): await flip(p.uid)
   await start_drag(p.uid,p.slot)
   await release_target(await reveal_drop_target(preparation.key))
   check(not ui.card_buttons.has(p.uid),"UI ROUTE preparation consumes actual escape card")
  else:
   if p.kind=="manual":
    ui.selected_card="";await inspect_body("mouth")
   check(await click(p.kind,{"target":p.target} if p.has("target") else {}),"UI ROUTE actual preparation action")
 if ui.view.phase=="prepare": check(await click("finish_prepare"),"finish preparation early")
 while ui.view.phase=="pack":
  var choice=preload("res://tests/route_driver.gd").packing_action(ui.game)
  check(not choice.is_empty(),"UI ROUTE packing has a legal next action")
  if choice.is_empty(): return
  var version=ui.view.version
  var committed=await click(choice.payload.kind,choice.payload)
  check(committed and ui.view.version>version,"UI ROUTE completes actual discard or packing through its visible button")
  if not committed or ui.view.version==version: return

func action_button(type: String, group: String="attack", destination: String="") -> Button:
 for c in ui.view.display_facts:
  if c.group!=group: continue
  if group=="attack" and c.payload.type!=type: continue
  if group=="posture" and (c.payload.dest!=destination or c.payload.wall): continue
  var key=ui.display_key(c.payload)
  if ui.candidate_buttons.has(key): return ui.candidate_buttons[key]
  if ui.candidate_buttons.has(c.key): return ui.candidate_buttons[c.key]
 return null

func drag_control_to(button: Button, actor: String) -> void:
 var point=button.get_global_rect().get_center()
 await move_mouse(point)
 await mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await move_mouse(point+Vector2(0,-42),true)
 check(root.gui_is_dragging(),"fixed action native drag starts")
 point=ui.actor_targets[actor].get_global_rect().get_center()
 await move_mouse(point,true)
 await mouse_button(point,MOUSE_BUTTON_LEFT,false)

func drop_card_on_actor(uid: String, actor: String) -> void:
 await close_information()
 await move_mouse(card_point(uid))
 var point=card_point(uid)
 await mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await move_mouse(point+Vector2(0,-42),true)
 check(root.gui_is_dragging(),"card drag to actor starts")
 point=ui.actor_targets[actor].get_global_rect().get_center()
 await move_mouse(point,true)
 await mouse_button(point,MOUSE_BUTTON_LEFT,false)

func _actor_drag_tests() -> void:
 ui.restart(20260906)
 await frames()
 check(ui.selected_enemy=="enemy_1","initial clicked target belt")
 await drag_control_to(action_button("strike"),"enemy_2")
 check(ui.game._enemy("enemy_1").hp==30 and ui.game._enemy("enemy_2").hp==22 and ui.view.energy==2,"drag targets actual enemy not preselected enemy")
 await drag_control_to(action_button("fireball"),"enemy_2")
 check(ui.game._enemy("enemy_2").hp==10 and ui.view.energy==1 and ui.view.mana==90,"drag first spell pays one energy and its magic once")
 var before=JSON.stringify(ui.game.state)
 await drag_control_to(action_button("strike"),"hero")
 check(JSON.stringify(ui.game.state)==before,"offensive action cannot target player")
 await drag_control_to(action_button("strike"),"enemy_2")
 check(not ui.game._enemy("enemy_2").gone and ui.game._enemy("enemy_2").hp==2 and ui.view.energy==0,"drag damage preserves the strengthened enemy until the final hit")
 await drag_control_to(action_button("fireball"),"enemy_2")
 check(ui.game._enemy("enemy_2").gone and ui.view.phase=="battle" and ui.view.energy==0 and ui.view.mana==80,"drag second spell can defeat selected enemy at zero energy while paying magic")
 await click("end")
 before=JSON.stringify(ui.game.state)
 ui.render();await frames()
 check(not ui.actor_targets.has("enemy_2") and JSON.stringify(ui.game.state)==before,"departed enemy has no drop target and rendering preserves state")
 var energy=ui.view.energy
 var round_number=ui.view.round
 var posture_cost=Queries.select(ui.view,"posture",{"dest":"sit","wall":false})[0].cost
 await drag_control_to(action_button("","posture","sit"),"hero")
 check(ui.view.posture=="sit" and ui.view.energy==energy-posture_cost and ui.view.round==round_number,"posture drag onto player uses normal rules")
 await capture("ui-09-actor-actions.png")

 ui.restart(20260906)
 await frames()
 var uid=ui.view.hand[0].uid
 before=JSON.stringify(ui.game.state)
 await drop_card_on_actor(uid,"enemy_1")
 check(JSON.stringify(ui.game.state)==before and not ui.player_pick,"escape card cannot target enemy")
 if not ui.card_faces.get(uid,false): await flip(uid)
 before=JSON.stringify(ui.game.state)
 await drop_card_on_actor(uid,"hero")
 check(not ui.player_pick and ui.view.energy==2 and ui.game.state.next_energy==1 and not ui.card_buttons.has(uid),"hero free card resolves directly without target selection")
 await click("end")
 uid=ui.view.hand.filter(func(c):return c.type=="strain")[0].uid
 # Target selection checks use explicit equal targets, not a random enemy's chosen slot.
 ui.game.state.equipment=ui.game.state.equipment.filter(func(e):return e.slot!="wrist")
 ui.game.add_fixture("wrist",1);ui.game.add_fixture("wrist",1)
 ui.game._cleanup();ui.render();await frames()
 before=JSON.stringify(ui.game.state)
 await drop_card_on_actor(uid,"hero")
 check(ui.player_pick and JSON.stringify(ui.game.state)==before,"bound hero card awaits target")
 await capture("ui-10-player-picker.png")
 var part=ui.find_child("PlayerPart_wrist",true,false)
 if part:
  part.pressed.emit()
  await frames()
  check(ui.drop_targets.size()==2,"hero wrist picker separates two equipment instances")
  var chosen=ui.game.equipment_at("wrist")[1].id
  ui.drop_targets.values()[1].pressed.emit()
  await frames()
  check(ui.game.equipment_at("wrist").is_empty() and ui.game.state.logs.any(func(row):return row.data.get("card_splash",{}).get("source","")==chosen) and ui.view.energy==3,"hero route processes exact chosen second item and splashes the other low-durability target")

func _instant_free_tests() -> void:
 ui.restart(20260906); await frames()
 var uid=ui.view.hand[0].uid
 if not ui.card_faces.get(uid,false): await flip(uid)
 ui.card_buttons[uid].pressed.emit(); await frames()
 check(ui.view.energy==2 and ui.game.state.next_energy==1 and not ui.player_pick,"click free card instant use")
 ui.restart(20260906); await frames()
 ui.game.add_fixture("mouth",4); ui.render(); await frames()
 uid=ui.view.hand.filter(func(c):return c.type=="ease")[0].uid
 if not ui.card_faces.get(uid,false): await flip(uid)
 var before=JSON.stringify(ui.game.state)
 ui.card_buttons[uid].pressed.emit(); await frames()
 check(ui.game.state.temporary_mana==10 and not ui.card_buttons.has(uid),"instant free preparation does not roll mouth casting")
 ui.restart(20260906);await frames()
 ui.game.add_fixture("fingers",4)
 var gesture=preload("res://tests/curse_cases.gd").give(ui.game,"unlock")
 for zone in ["draw","discard","exhaust"]: ui.game.state[zone]=ui.game.state[zone].filter(func(c):return c.uid!=gesture.uid)
 if not ui.game.state.hand.any(func(c):return c.uid==gesture.uid): ui.game.state.hand.append(gesture)
 ui.render();await frames()
 uid=gesture.uid
 if not ui.card_faces.get(uid,false): await flip(uid)
 before=JSON.stringify(ui.game.state)
 await drop_card_on_actor(uid,"hero")
 check(JSON.stringify(ui.game.state)==before,"invalid free spell drag does not pay")
 ui.restart(20260906); await frames()
 uid=ui.view.hand[0].uid
 if not ui.card_faces.get(uid,false): await flip(uid)
 ui.game.state.energy=0; ui.render(); await frames()
 before=JSON.stringify(ui.game.state)
 ui.card_buttons[uid].pressed.emit(); await frames()
 check(JSON.stringify(ui.game.state)==before,"instant free card still requires energy")

func _rest_ui_tests() -> void:
 ui.restart(20260906); await frames()
 print("UI BASELINE: checking rest-room route and tools")
 # Room boundary fixture keeps this test focused; complete climbs use the route tests.
 var parent=ui.game.state.rooms.filter(func(r):return "rest" in r.next)[0]
 ui.game._discard_end();ui.game.state.room=parent.id;ui.game.state.phase="map";ui.game.state.completed_rooms=[parent.id]
 ui.game.add_fixture("ankle",4);ui.game.add_fixture("forearm",4)
 ui.render();await frames()
 check(await click("depart",{"room":"rest"}),"rest route selectable")
 while ui.view.phase=="travel": await click("travel_step")
 check(await click("rest_begin"),"rest route starts six turns after choosing no bonus")
 check(ui.view.phase=="rest" and ui.view.rest_left==6 and ui.view.hook_uses==3,"rest UI starts six turns and three hooks")
 await capture("ui-11-rest-room.png")
 # Use a physical card so a separate spell-body restriction cannot mask the rest rule.
 var uid=ui.view.hand.filter(func(c):return c.type in ["strain","slip"])[0].uid
 await flip(uid)
 var before=JSON.stringify(ui.game.state)
 ui.card_buttons[uid].pressed.emit(); await frames()
 check(JSON.stringify(ui.game.state)==before and ui.notice.contains("休息房"),"rest UI rejects free effects")
 var hook=ui.find_child("OpenRestHook",true,false)
 hook.pressed.emit(); await frames()
 check(await click("hook"),"real hook action from UI")
 check(ui.view.hook_uses==2,"hook counter updates")
 await capture("ui-12-hook-targets.png")
 ui.show_hook=false; ui.render(); await frames()
 ui.game._gain_tool("saw");ui.render();await frames()
 check(ui.view.items.size()==1,"tool fixture available for installation check")
 await capture("ui-13-field-tool.png")
 # The tool must stay usable through installation; inject only a target for this contact boundary.
 var target=ui.game.add_fixture("thigh",30,30)
 ui.render(); await frames()
 var item=ui.view.items[0].id
 check(await click("item_install",{"item":item,"mount":"foot_wall"}),"install tool at wall-foot slot")
 check(await click("posture",{"dest":"sit","wall":false}),"sit to change contact")
 check(await click("posture",{"dest":"lie","wall":false}),"lie reaches installed tool")
 check(await trigger_installed_tool(target.id,item),"installed saw triggers from actual card damage")
 check(ui.game._equipment(target.id).durability<23 and ui.view.items[0].uses==1,"tool wear and damage visible")
 check(await trigger_installed_tool(target.id,item) and ui.view.items.is_empty(),"second card trigger removes exhausted tool")
 ui.show_items=false; ui.render(); await frames()
 check(await click("finish_rest") and ui.view.phase=="map","leave rest early")
 check(await click("depart",{"room":ui.game.room_data("rest").next[0]}),"rest connects back to tower")
 while ui.view.phase=="travel": await click("travel_step")
 check(ui.view.phase=="battle" and ui.view.encounter==2,"rest did not add fake battle or reward")

func _index_boundary_tests() -> void:
 ui.restart(42)
 await frames()
 var before=JSON.stringify(ui.game.state)
 var old_version=ui.view.version
 var old_action=Queries.find(ui.view,"attack",{"type":"strike","enemy":"enemy_1"})
 check(not old_action.is_empty() and Queries.find(ui.view,"attack",{"enemy":"missing"}).is_empty(),"indexed targets distinguish actual enemy from missing enemy")
 check(Queries.select(ui.view,"item").is_empty(),"empty action group stays empty")
 ui.show_deck=true; ui.render(); await frames()
 check(JSON.stringify(ui.game.state)==before,"UI redraw does not advance rules or random cursors")
 var finish=Queries.find(ui.view,"flow",{"kind":"end"})
 check(ui.game.dispatch(ui.game.command(finish.payload,old_version),old_version).ok,"external turn advances state for stale UI test")
 before=JSON.stringify(ui.game.state)
 ui.command_router.emit(String(old_action.payload.get("kind","")),old_action,old_version)
 await frames()
 check(JSON.stringify(ui.game.state)==before and ui.notice!="","stale displayed action rejected without spending")
 check(ui.view.version==ui.game.state.version and ui.view.energy==ui.game.state.energy,"failed submission refreshes displayed snapshot")
 check(ui._attack_drop_candidate({"version":old_version,"action_type":"strike"},"enemy_1").is_empty(),"old drag rejected after index replacement")
 var current=Queries.find(ui.view,"attack",{"type":"strike","enemy":"enemy_1"})
 check(not current.is_empty() and not Queries.fact_by_key(ui.view,String(current.get("key",""))).is_empty(),"current action index rebuilt after state change")

func visible_text(node: Node) -> String:
 var result=""
 if node is Control and not node.is_visible_in_tree(): return result
 if node is Label or node is Button: result+=node.text+"\n"
 for child in node.get_children(): result+=visible_text(child)
 return result

func _equipment_practice_tests() -> void:
 await open_menu()
 ui.find_child("OpenRestart",true,false).pressed.emit(); await frames()
 var entry=ui.find_child("StartEquipmentPractice",true,false)
 check(entry!=null and entry.is_visible_in_tree(),"practice entry visible in restart menu")
 ui.seed_field.text="invalid"; ui.seed_field.text_changed.emit("invalid"); await frames()
 check(entry.disabled and visible_text(ui.layout).contains("需要填写整数"),"invalid practice seed disables start with explanation")
 ui.seed_field.text="42"; ui.seed_field.text_changed.emit("42"); await frames()
 check(not entry.disabled,"valid seed restores practice entry")
 var point=entry.get_global_rect().get_center()
 await capture("ui-16-practice-menu.png")
 await move_mouse(point)
 await mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await mouse_button(point,MOUSE_BUTTON_LEFT,false)
 await frames()
 check(ui.view.practice and ui.view.phase=="rest" and ui.view.rest_left==6 and ui.view.items.size()==2,"real practice button starts configured room")
 check(ui.view.encounter==0 and ui.view.reward_count==0 and ui.view.route.is_empty(),"practice UI isolated from tower progress")
 await inspect_body("calf")
 check(visible_text(ui.layout).contains("纸质胶带") and visible_text(ui.layout).contains("胶带不能徒手"),"single equipment details retain material and exact unavailable manual reason")
 await capture("ui-14-equipment-practice.png")
 var plastic=ui.game.state.equipment.filter(func(e):return e.template=="cable_tie")[0].id
 var stone=ui.view.items[0].id
 var saw=ui.view.items[1].id
 ui.show_items=true; ui.selected_item=stone; ui.render(); await frames()
 var cut=Queries.find(ui.view,"item",{"kind":"item_use","item":stone,"target":plastic})
 check(not cut.valid and cut.reason.contains("不能切割塑料") and not ui.candidate_buttons.has(cut.key),"incompatible stone target is excluded from valid position menu with formal reason retained")
 await capture("ui-15-material-tools.png")
 ui.selected_item=saw; ui.render(); await frames()
 check(await click("item_use",{"item":saw,"target":plastic}),"saw action cuts plastic from UI")
 check(ui.game._equipment(plastic).durability==1 and ui.view.energy==3,"plastic damage and zero energy charge visible")
 check(await click("item_use",{"item":saw,"target":plastic}) and ui.game._equipment(plastic).is_empty(),"second saw cut removes actual plastic equipment")
 ui.show_items=false; ui.render(); await frames()
 var slip=ui.view.hand.filter(func(c):return c.type=="slip")[0].uid
 await start_drag(slip,"calf")
 await release_target()
 check(ui.game.equipment_at("calf").is_empty() and ui.view.energy==2,"native card drag slips off actual tape")
 ui.find_child("OpenRestHook",true,false).pressed.emit(); await frames()
 var rope=ui.game.equipment_at("wrist")[0].id
 check(await click("hook",{"target":rope}) and ui.game._equipment(rope).is_empty(),"hook removes tier-one rope through normal rule")
 ui.show_hook=false; ui.render(); await frames()
 check(await click("finish_rest") and ui.view.phase=="cleared" and ui.view.reward_count==0,"practice exit ends exercise without awarding combat reward")
 check(visible_text(ui.layout).contains("装备练习结束") and not visible_text(ui.layout).contains("抵达试炼出口"),"practice ending uses its own accurate text")
 ui.restart(42); await frames()
 check(not ui.view.practice and ui.view.phase=="battle" and ui.view.items.is_empty(),"returning to tower resets practice equipment and tools")

func _new_encounter_map_tests() -> void:
 ui.restart(42); await frames()
 await finish_ui_room()
 var graph=ui.find_child("TowerRoute",true,false)
 var scroll=ui.find_child("TowerMapScroll",true,false)
 check(graph!=null and scroll!=null and graph.buttons.size()==ui.view.route.size(),"MAP every room has a clickable icon")
 var before=JSON.stringify(ui.game.state)
 var point=Vector2.ZERO
 graph=ui.find_child("TowerRoute",true,false); scroll=ui.find_child("TowerMapScroll",true,false)
 scroll.scroll_vertical=0; await frames()
 point=graph.buttons.exit.get_global_rect().get_center()
 await move_mouse(point); await mouse_button(point,MOUSE_BUTTON_LEFT,true); await mouse_button(point,MOUSE_BUTTON_LEFT,false)
 check(ui.route_focus=="exit" and JSON.stringify(ui.game.state)==before and Queries.find(ui.view,"route",{"room":"exit"}).is_empty(),"MAP future room inspection never bypasses route eligibility")
 check(ui.find_child("TowerMapScroll",true,false).scroll_vertical==0,"MAP inspecting nodes preserves scroll position")
 await capture("ui-19-spire-map.png")
 var overview=ui.find_child("MapOverview",true,false)
 point=overview.get_global_rect().get_center()
 await move_mouse(point); await mouse_button(point,MOUSE_BUTTON_LEFT,true); await mouse_button(point,MOUSE_BUTTON_LEFT,false)
 graph=ui.find_child("TowerRoute",true,false)
 check(graph.compact and graph.rooms.size()>=25 and JSON.stringify(ui.game.state)==before,"MAP overview fits entire generated tower without changing state")
 await capture("ui-20-full-tower.png")
 var locate=ui.find_child("MapLocate",true,false)
 point=locate.get_global_rect().get_center()
 await move_mouse(point); await mouse_button(point,MOUSE_BUTTON_LEFT,true); await mouse_button(point,MOUSE_BUTTON_LEFT,false)
 graph=ui.find_child("TowerRoute",true,false)
 check(not graph.compact and ui.route_focus=="entrance" and ui.find_child("TowerMapScroll",true,false).scroll_vertical>500,"MAP locate restores detailed current floor after overview")
 check(await click("depart",{"room":"west"}),"MAP node activation directly enters selected branch")
 while ui.view.phase=="travel": await click("travel_step")
 check(ui.view.enemies[0].type=="rope" and ui.view.enemies[1].type=="tape","ENEMY mixed encounter appears on actual route")
 var rope=ui.view.enemies[0].id
 var eyes=ui.view.enemies[1].id
 check(ui.actor_targets.has(rope) and ui.actor_targets.has(eyes) and ui.view.enemies[1].template=="tape","ENEMY new actor targets and public charge visible")
 await capture("ui-17-rope-blindfold.png")
 for i in range(3): await click("end")
 check(ui.view.phase=="battle" and not ui.game._enemy(eyes).gone and not ui.game._enemy(rope).gone and ui.game._enemy(eyes).stage==4,"ENEMY both material enemies reach final attachment after preparation")
 check(ui.view.reward_count==1 and not ui.view.enemies[0].intent_icons.is_empty(),"ENEMY one departure gives no extra reward and keeps public intent")
 await finish_ui_room()
 check(await click("depart",{"room":"landing"}),"ENEMY route reaches double rope encounter")
 while ui.view.phase=="travel": await click("travel_step")
 var first=ui.view.enemies[0].id
 var second=ui.view.enemies[1].id
 check(first!=second and ui.view.enemies[0].type=="rope" and ui.view.enemies[1].type=="rope" and ui.view.enemies[0].name!=ui.view.enemies[1].name,"DOUBLE two ropes visible with distinct identities")
 await capture("ui-18-double-rope.png")
 # Seated kick retains interruption; standing justice kick no longer has it.
 ui.game.state.equipment.clear(); ui.game.state.posture="sit"; ui.render(); await frames()
 var first_hp=ui.game._enemy(first).hp
 await drag_control_to(action_button("kick"),second)
 check(ui.game._enemy(first).hp==first_hp and ui.game._enemy(second).hp<first_hp and not ui.game._enemy(first).intent.delayed and ui.game._enemy(second).intent.delayed,"DOUBLE native drag damages and interrupts exact second rope")
 check(await click("end") and ui.game._enemy(first).stage==2 and ui.game._enemy(second).stage==1,"DOUBLE independent phases remain correct after real drag")
 ui.show_route=true; ui.render(); await frames()
 check(not ui.candidate_buttons.values().any(func(b):return b.text=="结束回合"),"MAP viewing route does not overlay combat controls on paper")
 before=JSON.stringify(ui.game.state)
 graph=ui.find_child("TowerRoute",true,false)
 graph.buttons.rest.pressed.emit(); await frames()
 check(JSON.stringify(ui.game.state)==before and Queries.select(ui.view,"route").is_empty(),"MAP battle inspection cannot move between rooms")

func _run() -> void:
 var selected: Array=["home"]
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--screenshots="): screenshots=Array(arg.trim_prefix("--screenshots=").split(",",false))
  if arg.begins_with("--ui-suite="): selected=Array(arg.trim_prefix("--ui-suite=").split(",",false))
 if selected.is_empty() or selected.any(func(name):return name!="all" and not UI_MODULES.has(name)):
  check(false,"Unknown or empty UI check suite");finish_checks();return
 print("UI SCREENSHOTS: "+("none" if screenshots.is_empty() else ",".join(screenshots)))
 print("UI SCOPE: "+",".join(UI_MODULES.keys().filter(func(name):return "all" in selected or name in selected)))
 if "--list-only" in OS.get_cmdline_user_args():
  for name in UI_MODULES:
   if "all" in selected or name in selected: print("  %s [%s]" % [name,preload("res://tests/suite_selection.gd").stage(name)])
  print("PLAN ONLY: no UI tests executed")
  quit(0);return
 # Test-only isolation: OS cursor traffic must not replace the scripted drag
 # position. All test events still enter the real Viewport/Control input path.
 DisplayServer.window_set_input_event_callback(func(event):
  if event is InputEventMouse: external_mouse_events+=1)
 root.size=Vector2i(1600,900)
 ui=load("res://main.tscn").instantiate()
 ui.persistence_enabled=false
 ui.feedback_duration=0.04
 ui.game_factory=preload("res://tests/game_fixture.gd")
 ui.game=ui.game_factory.new()
 root.add_child(ui)
 await frames()
 if engine_errors.count()>0: finish_checks();return
 DirAccess.make_dir_recursive_absolute("res://build")
 await module_checks(selected)
 finish_checks()

func _baseline_tests() -> void:
 check(ui.card_buttons.size()==5 and ui.view.body_groups.size()==14,"hand and left body slots visible")
 check(ui.body_buttons.wrist.get_global_rect().position.x<355,"equipment on left")
 check(ui.find_child("MoonlitGallery",true,false)!=null and preload("res://ui/pixel_art.gd").HERO_POSES.size()==3,"ART gallery and three supplied pose cutouts are loaded")
 await capture("ui-01-battle.png")
 var uid=ui.view.hand[0].uid
 var before=JSON.stringify(ui.game.state)
 await flip(uid)
 check(not ui.card_faces.get(uid,false),"right click switches drawn free card to bound face")
 await flip(uid)
 check(ui.card_faces.get(uid,false),"right click switches back to free face")
 check(JSON.stringify(ui.game.state)==before,"flipping costs nothing")
 await start_drag(uid,"thigh")
 await capture("ui-02-free-drag.png")
 await release_target()
 check(ui.view.energy==2 and ui.game.state.next_energy==1 and not ui.card_buttons.has(uid),"free drag spends exact card and energy")
 check(await click("end"),"end first turn")
 # Target-frame geometry needs two wrist items; enemies now choose random legal positions.
 ui.game.state.equipment.clear()
 ui.game.add_fixture("wrist",4,10,false)
 ui.game.add_fixture("wrist",4,10,false)
 ui.render(); await frames()
 var strain=ui.view.hand.filter(func(c):return c.type=="strain")[0]
 uid=strain.uid
 await flip(uid)
 before=JSON.stringify(ui.game.state)
 await start_drag(uid,"wrist")
 await mouse_button(ui.body_buttons.wrist.get_global_rect().get_center(),MOUSE_BUTTON_LEFT,false)
 check(JSON.stringify(ui.game.state)==before,"wrong card face drop on occupied body remains rejected unchanged")
 await flip(uid)
 before=JSON.stringify(ui.game.state)
 await start_drag(uid,"wrist")
 check(ui.drop_targets.size()==2,"two equipment frames for two items")
 await capture("ui-03-two-targets.png")
 await move_mouse(Vector2(1090,88),true)
 await mouse_button(Vector2(1090,88),MOUSE_BUTTON_LEFT,false)
 check(JSON.stringify(ui.game.state)==before,"cancel outside target costs nothing")
 await start_drag(uid,"wrist")
 var first_id=ui.game.equipment_at("wrist")[0].id
 await release_target(1)
 check(ui.view.energy==3 and ui.game.equipment_at("wrist").size()==1 and ui.game.equipment_at("wrist")[0].id==first_id and not ui.card_buttons.has(uid),"bound drag removes exact second equipment")
 for i in range(3): check(await click("end"),"advance to reward")
 check(ui.view.phase=="reward","reward appears after all enemies")
 await capture("ui-04-reward.png")
 check(await click("reward",{"type":Queries.select(ui.view,"reward")[0].payload.type}),"choose displayed reward card")
 check(await click("reward",{"type":"skip"}),"continue after card pickup")
 for i in range(3): check(await click("end"),"preparation round")
 check(ui.view.phase=="map" and ui.view.deck_count==11,"preparation opens route")
 await capture("ui-05-map.png")
 check(await click("depart",{"room":"west"}),"choose connected room")
 await capture("ui-06-travel.png")
 while ui.view.phase=="travel": check(await click("travel_step"),"advance travel")
 check(ui.view.encounter==2 and ui.view.enemies.size()==2,"configured room entered")
 await finish_ui_room()
 if ui.view.phase=="map":
  check(await click("depart",{"room":"landing"}),"next route edge")
  while ui.view.phase=="travel": await click("travel_step")
  await finish_ui_room()
 var long_room_guard=0
 while ui.view.phase=="map" and long_room_guard<20:
  var next=Queries.select(ui.view,"route")[0].payload.room
  check(await click("depart",{"room":next}),"long tower next edge")
  while ui.view.phase=="travel": await click("travel_step")
  if ui.view.phase=="rest_choice": await click("rest_begin")
  if ui.view.phase=="rest": await click("finish_rest")
  else: await finish_ui_room()
  long_room_guard+=1
 check(ui.view.phase=="cleared" and ui.view.reward_count==ui.view.encounter and ui.view.encounter+ui.view.route.filter(func(r):return r.icon=="event" and r.status=="completed").size()>=8,"full long route completed once: phase=%s room=%s rewards=%d encounters=%d" % [ui.view.phase,ui.view.room_name,ui.view.reward_count,ui.view.encounter])
 await capture("ui-07-cleared.png")
 ui.restart(20260906)
 await frames()
 root.size=Vector2i(1440,810)
 await frames()
 check(ui.view.encounter==1 and ui.view.deck_count==10,"restart resets run")
 check(ui.layout.get_global_rect().end.y<=901,"logical canvas fits")
 await capture("ui-08-default-window.png")
 print("UI BASELINE: default window captured; checking resize and actor drags")
 root.size=Vector2i(1600,900)
 await frames()
 ui.game.state.wall="normal"
 var immune=ui.game.add_fixture("ankle",10)
 ui.render()
 await frames()
 uid=ui.view.hand.filter(func(c):return c.type=="slip")[0].uid
 if ui.card_faces.get(uid,false): await flip(uid)
 await start_drag(uid,"ankle")
 await release_target()
 check(ui.view.energy==2 and ui.game._equipment(immune.id).durability==10 and not ui.card_buttons.has(uid),"red zero-damage slip target is still a paid legal attempt")
 await _instant_free_tests()
 print("UI BASELINE: free cards complete")
 await _rest_ui_tests()
 await _index_boundary_tests()
 await _equipment_practice_tests()
 await _new_encounter_map_tests()
 await _link_ui_tests()
 await _composite_ui_tests()

func _link_ui_tests() -> void:
 await start_practice("StartLinkPractice")
 check(ui.view.practice_kind=="links" and ui.view.room_name=="链接练习室" and ui.view.rest_left==6,"LINK real entry initializes the configured practice")
 var link=ui.view.bodies.filter(func(b):return b.id=="calf")[0].links[0]
 await inspect_body("calf")
 check(ui.body_buttons.ankle.text.contains("链") and visible_text(ui.layout).contains("链接绳"),"LINK both end buttons and equipment details identify the connection")
 var uid=ui.view.hand.filter(func(c):return c.type=="strain")[0].uid
 var candidate=Queries.find(ui.view,"card",{"uid":uid,"slot":"calf","target":link.id})
 var predicted=candidate.payload.preview.damage
 await start_drag(uid,"calf")
 var index=ui.drop_targets.keys().find(candidate.key)
 index=await reveal_drop_target(candidate.key)
 check(index>=0 and visible_text(ui.term_popup).contains(ui.game.number(predicted)+"点挣扎伤害"),"LINK hovered target explains shared durability")
 await capture("ui-22-link-targets.png")
 await release_target(index)
 check(is_equal_approx(ui.game._equipment(link.id).durability,8-predicted) and ui.view.energy==2 and not ui.card_buttons.has(uid),"LINK native drag applies one shared hit and spends one card")
 check(await click("posture",{"dest":"sit","wall":false}),"LINK seated contact reached through ordinary posture action")
 ui.show_items=true; ui.selected_item=ui.view.items[0].id; ui.render(); await frames()
 check(await click("item_use",{"item":ui.selected_item,"target":link.id}),"LINK tool action is connected to actual rope")
 check(ui.game.state.links.is_empty() and ui.game.state.equipment.size()==2 and ui.view.items[0].uses==2,"LINK cut removes only shared rope, keeps anchors and spends a tool use")
 ui.show_items=false; ui.render(); await frames(); await inspect_body("ankle")
 check(ui.view.bodies.filter(func(b):return b.id=="ankle")[0].links.is_empty() and not ui.body_buttons.ankle.text.contains("链"),"LINK endpoint UI updates after removal")
 await capture("ui-23-link-released.png")

func _composite_ui_tests() -> void:
 await start_practice("StartShortGlovePractice")
 # Fix the hand needed for the two-hit interaction, not the draw algorithm.
 var deck=ui.game.state.deck
 ui.game.state.hand=[deck[0],deck[1],deck[3],deck[8],deck[9]].duplicate(true)
 var ids=ui.game.state.hand.map(func(c):return c.uid)
 ui.game.state.draw=deck.filter(func(c):return c.uid not in ids).duplicate(true)
 ui.game.state.discard=[];ui.game.state.exhaust=[]
 ui.render();await frames()
 check(ui.view.practice_kind=="glove_short" and ui.view.arms==3 and ui.view.rest_left==6,"COMPOSITE real short practice applies arm restriction")
 var body_view=ui.view.bodies.filter(func(b):return b.id=="wrist")[0]
 var body=body_view.targets.values().filter(func(e):return e.part=="body")[0]
 var left=ui.view.body_groups.filter(func(b):return b.id=="neck")[0].targets.values().filter(func(e):return e.part=="left")[0]
 check(body_view.count==1 and body_view.groups.size()==1 and body_view.targets.size()==1,"COMPOSITE sleeve kept in arm and shoulders in neck")
 check(ui.view.bodies.filter(func(b):return b.id=="fingers")[0].occupied==false,"COMPOSITE short practice leaves fingers free")
 var energy_before=ui.view.energy
 var paid=0
 for i in range(2):
  if ui.game._equipment(left.id).is_empty(): break
  var uid=ui.view.hand.filter(func(c):return c.type=="slip")[0].uid
  var c=Queries.find(ui.view,"card",{"uid":uid,"target":left.id,"free":false})
  check(not c.is_empty() and c.valid,"COMPOSITE shoulder has a current formal card candidate")
  if c.is_empty() or not c.valid: return
  var expected=maxf(0.0,ui.game._equipment(left.id).durability-c.payload.preview.damage)
  paid+=c.cost
  await start_drag(uid,"neck")
  var index=await reveal_drop_target(c.key)
  if i==0:
   check(Queries.find(ui.view,"hook",{"target":body.id}).reason.contains("肩带"),"COMPOSITE body target explains actual prerequisite")
   await capture("ui-24-glove-components.png")
  await release_target(index)
  check(is_equal_approx(ui.game._equipment(left.id).get("durability",0.0),expected),"COMPOSITE shoulder drag applies its current previewed damage")
 check(ui.game._equipment(left.id).is_empty() and ui.view.arms==3 and ui.view.energy==energy_before-paid,"COMPOSITE actual slip drags remove the selected shoulder, retain the body and pay only used cards")
 var uid=ui.view.hand.filter(func(c):return c.type=="strain")[0].uid
 var c=Queries.find(ui.view,"card",{"uid":uid,"target":body.id,"free":false})
 check(not c.is_empty() and c.valid,"COMPOSITE body has a current formal card candidate")
 if c.is_empty() or not c.valid: return
 paid+=c.cost
 await start_drag(uid,"forearm")
 var index=await reveal_drop_target(c.key)
 check(visible_text(ui.term_popup).contains("整件脱下"),"COMPOSITE shortcut is previewed before commitment")
 await capture("ui-25-glove-release-preview.png")
 await release_target(index)
 check(ui.view.arms==0 and ui.view.energy==energy_before-paid and ui.game.state.composites.is_empty() and ui.view.capacity==3,"COMPOSITE one formal strain releases assembly and updates abilities/capacity")

 await start_practice("StartLongGlovePractice")
 check(ui.view.practice_kind=="glove_long" and ui.view.arms==4 and ui.view.capacity==2,"COMPOSITE actual long practice closes fingers and applies single capacity penalty")
 body_view=ui.view.bodies.filter(func(b):return b.id=="fingers")[0]
 check(body_view.count==1 and body_view.targets.size()==1,"COMPOSITE long shoulder targets are separate from sleeve")
 body=body_view.targets.values().filter(func(e):return e.part=="body")[0]
 var cross=ui.view.body_groups.filter(func(b):return b.id=="neck")[0].targets.values().filter(func(e):return e.part=="left")[0]
 ui.find_child("OpenRestHook",true,false).pressed.emit(); await frames()
 var blocked=Queries.find(ui.view,"hook",{"target":body.id})
 check(not blocked.valid and blocked.reason!="" and visible_text(ui.layout).contains(blocked.reason),"COMPOSITE hook retains structural reason")
 check(not Queries.find(ui.view,"hook",{"target":cross.id}).valid and ui.view.hook_uses==3,"COMPOSITE crossed shoulder cannot use hook before reaching tier1")
 ui.show_hook=false; ui.show_items=true; ui.selected_item=ui.view.items[0].id; ui.render(); await frames()
 var item=ui.selected_item
 blocked=Queries.find(ui.view,"item",{"kind":"item_use","item":item,"target":body.id})
 check(not blocked.valid and blocked.reason.contains("手指"),"COMPOSITE handheld cutting correctly unavailable")
 check(await click("item_install",{"item":item,"mount":"foot_wall"}),"COMPOSITE toe wall installation remains available")
 ui.show_items=false; ui.render(); await frames()
 check(await click("posture",{"dest":"sit","wall":false}),"COMPOSITE sit through shared posture action")
 check(await click("posture",{"dest":"lie","wall":false}),"COMPOSITE lie through shared posture action")
 ui.show_items=true; ui.selected_item=item; ui.render(); await frames()
 check(await trigger_installed_tool(body.id,item),"COMPOSITE actual damage card triggers installed cutting despite covered hands")
 await capture("ui-26-long-glove-tool.png")

# Fixture resources isolate installed contact tests; execution remains a native card drag.
func trigger_installed_tool(target_id: String, item_id: String) -> bool:
 ui.game.state.energy=3
 if not ui.game.state.hand.any(func(c):return c.type=="strain"):
  var card=ui.game.state.discard.filter(func(c):return c.type=="strain")
  if card.is_empty():
   ui.game._gain_card("strain")
   card=ui.game.state.discard.filter(func(c):return c.type=="strain")
  if card.is_empty(): return false
  ui.game.state.discard.erase(card[0]);ui.game.state.hand.append(card[0])
 ui.show_items=false;ui.render();await frames()
 var target=ui.game._equipment(target_id)
 var uid=ui.view.hand.filter(func(c):return c.type=="strain")[0].uid
 var c=Queries.find(ui.view,"card",{"uid":uid,"target":target_id})
 if c.is_empty() or not c.valid or c.payload.get("tool_bonus",{}).get("item","")!=item_id: return false
 var expected=maxf(0,target.durability-c.payload.preview.damage-c.payload.tool_bonus.damage)
 var uses=ui.game._item(item_id).uses
 await start_drag(uid,c.payload.slot)
 await release_target(await reveal_drop_target(c.key))
 var after=ui.game._equipment(target_id)
 var tool=ui.game._item(item_id)
 return (after.is_empty() if expected==0 else not after.is_empty() and is_equal_approx(after.durability,expected)) and (tool.is_empty() if uses==1 else tool.uses==uses-1) and ui.view.energy==2
