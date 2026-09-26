extends RefCounted
const Normal=preload("res://tests/normal_play_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.game_factory=preload("res://core/game.gd")
 ui.restart(7);await t.frames()
 t.check(not ui.view.practice and ui.view.deck_count==10 and ui.view.mana==100,"NORMAL UI starts ordinary tower without fixture or modified values")
 await t.capture("ui-68-normal-start.png")
 var captured=false
 var navigation={}
 for i in range(600):
  var v=ui.view
  if v.phase in ["cleared","prison_end"] or (v.phase=="map" and v.security>0): break
  if v.phase=="captured" and not captured:
   captured=true
   await t.capture("ui-69-normal-capture.png")
  var c=Normal.choose(v,"trade",navigation)
  if i%50==0: print("NORMAL UI PROGRESS step=%d phase=%s room=%s action=%s" % [i,v.phase,v.room_name,c.get("label","none")])
  t.check(not c.is_empty(),"NORMAL UI has a formal next step")
  if c.is_empty(): return
  var p=c.payload
  if p.kind=="card":
   if ui.card_faces.get(p.uid,false)!=p.free: await t.flip(p.uid)
   if ui._card_is_free(p.uid,p.free) or p.get("self_target",false):
    ui.card_buttons[p.uid].pressed.emit();await t.frames()
   else:
    await t.start_drag(p.uid,p.slot)
    await t.release_target(await t.reveal_drop_target(c.key))
   if p.has("hand_uid"):
    t.check(ui._selecting_hand() and ui.view.version==v.version,"NORMAL UI opens hand selection before paying for the card")
    if not ui._selecting_hand(): return
    ui.card_buttons[p.hand_uid].pressed.emit();await t.frames()
  else:
   ui.show_items=p.kind.begins_with("item_")
   if ui.show_items and p.has("item"): ui.selected_item=p.item
   ui.show_hook=p.kind=="hook"
   ui.show_pressure=false
   if p.kind=="attack": ui.selected_enemy=p.enemy
   if p.kind in ["manual","retain","retain_skip"]:
    ui.show_body=true;ui.selected_card=""
    if p.has("target"): ui.selected_slot=Normal.target(v,p.target).slot
   ui.render();await t.frames(1)
   if p.kind=="attack":
    var before=ui.game.export_snapshot()
    var forms=v.display_facts.filter(func(option):return option.payload.kind=="attack" and option.payload.type==p.type and option.payload.enemy==p.enemy)
    for attempt in range(forms.size()):
     if ui.attack_forms.get(p.type,0)==p.form: break
     var button=ui.find_child("BasicAttack_"+p.type,true,false)
     if button==null: break
     var point=button.get_global_rect().get_center()
     await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
    t.check(ui.attack_forms.get(p.type,0)==p.form and ui.game.state==before,"NORMAL UI selects the actual attack form without committing a turn")
   if p.kind=="depart" and not ui.candidate_buttons.has(c.key):
    await preload("res://tests/interface_ui_cases.gd").press(t,"OpenMap")
   if p.kind=="event":
    if p.action=="reward" and p.type!="skip":
     await preload("res://tests/event_ui_cases.gd").open_selection(t,"reward")
    else:
     var groups=ui.view.room_event.selections.filter(func(group):return group.options.any(func(option):return option.choice==p.get("choice","")))
     if not groups.is_empty(): await preload("res://tests/event_ui_cases.gd").open_selection(t,groups[0].id)
   if p.kind=="prison":
    if p.action=="explore" and ui.prison_detail!="":
     var back=ui.find_child("PrisonDetailsBack",true,false)
     if back!=null:
      var point=back.get_global_rect().get_center()
      await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
    elif p.action in ["vent_kick","vent_exit","key","door_exit","unlock"]:
     var kind="vent" if p.action.begins_with("vent") else "door"
     var places=ui.view.prison.space.sites.filter(func(site):return site.interaction.get("kind","")==kind)
     if not places.is_empty() and ui.prison_detail!=places[0].id:
      await preload("res://tests/exploration_ui_cases.gd").open_details(t,places[0].id)
   if p.kind=="surrender":
    var before=ui.game.export_snapshot()
    await preload("res://tests/interface_ui_cases.gd").press(t,"SurrenderButton")
    t.check(ui.game.state==before,"NORMAL UI surrender confirmation does not commit an action")
    await preload("res://tests/interface_ui_cases.gd").press(t,"SurrenderButton")
    captured=ui.view.phase=="prison"
   else:
    t.check(await t.click(p.kind,p),"NORMAL UI real button: "+c.label)
  t.check(ui.view.version>v.version,"NORMAL UI chosen action commits once: "+c.label)
  if ui.view.version==v.version: return
  Normal.remember(v,c,navigation)
 var reached_route=captured and ui.view.phase=="map" and ui.view.security>=1 and ui.view.map_region=="prison" and ui.view.room_name=="出发点"
 t.check(reached_route or ui.view.phase in ["cleared","prison_end"],"NORMAL UI bounded ordinary play reaches a completion or prison-route checkpoint")
 t.check(ui.game.validate()=="","NORMAL UI final outcome preserves valid game state")
 print("NORMAL UI OUTCOME: "+JSON.stringify({"seed":7,"phase":ui.view.phase,"security":ui.view.security,"captured":captured,"travel_turns":ui.view.travel_turns}))
 await t.capture("ui-70-normal-outcome.png")
