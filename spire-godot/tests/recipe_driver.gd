extends "res://tests/ui_smoke.gd"
# Long-horizon real-input recipe driver: one fixed seed played through the real board, drawer and
# popout buttons, step by step, until --cap commits land or the run reaches a natural end. This is
# the shape that caught the hand-render crash deterministic rule assertions missed; it lives here
# so the gate can replay it without the gitignored build/ tree it used to sit in.
#
# Dependencies are shipped helpers only: tests/ui_smoke.gd (frames/move_mouse/mouse_button/click/
# start_drag/release_target/reveal_drop_target/flip/close_information), the play policy
# tests/normal_play_cases.gd::choose, tests/game_fixture.gd as the game class, and the same case
# helpers tests/normal_play_ui_cases.gd uses for drawers, events and prison details. Policy reads
# only the projection the player sees; no state, save or RNG writes.
#
# The shell owns the outer evidence: tools/check.ps1 prepends the RUN IDENTITY header and appends
# the exit=<code> line around this output, so a product crash keeps its engine exit code in-band.
# The closing machine-readable line is `RECIPE seed=<n> commits=<n> steps=<n> stop=<reason>`.
#
# Usage (from spire-godot):
#   Godot_v4.7.2-stable_win64_console.exe --path . --script res://tests/recipe_driver.gd \
#     -- --seed=7 --cap=60 --style=trade

const Normal=preload("res://tests/normal_play_cases.gd")
const EventCases=preload("res://tests/event_ui_cases.gd")
const InterfaceCases=preload("res://tests/interface_ui_cases.gd")
const ExplorationCases=preload("res://tests/exploration_ui_cases.gd")
const Fixture=preload("res://tests/game_fixture.gd")
const OUT_ROOT="res://build/recipe"

var recipe_seed=7
var recipe_cap=60
var recipe_style="trade"

func _initialize() -> void:
 OS.add_logger(engine_errors)
 _run_recipe.call_deferred()

func _write_json(path: String, value: Variant) -> void:
 var file=FileAccess.open(path,FileAccess.WRITE)
 if file==null:
  print("RECIPE WRITE FAILED: "+path);return
 file.store_string(JSON.stringify(value," "))
 file.close()

func _run_recipe() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--seed="): recipe_seed=int(arg.trim_prefix("--seed="))
  elif arg.begins_with("--cap="): recipe_cap=int(arg.trim_prefix("--cap="))
  elif arg.begins_with("--style="): recipe_style=arg.trim_prefix("--style=")
 print("RECIPE DRIVER engine=%s seed=%d cap=%d style=%s window=1600x900" % [Engine.get_version_info().string,recipe_seed,recipe_cap,recipe_style])
 # Test-only isolation shared with tests/ui_smoke.gd: OS cursor traffic must not replace the
 # scripted pointer. All recipe events still enter the real Viewport/Control input path.
 DisplayServer.window_set_input_event_callback(func(event):
  if event is InputEventMouse: external_mouse_events+=1)
 root.size=Vector2i(1600,900)
 ui=load("res://main.tscn").instantiate()
 ui.persistence_enabled=false
 ui.feedback_duration=0.04
 ui.game_factory=Fixture
 ui.game=ui.game_factory.new()
 root.add_child(ui)
 await frames()
 if engine_errors.count()>0:
  print("RECIPE seed=%d commits=0 steps=0 stop=engine_errors" % recipe_seed)
  finish_checks();return
 ui.restart(recipe_seed)
 await frames()
 var label="seed%d-%s" % [recipe_seed,recipe_style]
 var navigation={}
 var commits=0
 var steps=0
 var stale=0
 var stop_reason="cap"
 var phases: Array=[]
 while commits<recipe_cap and steps<900:
  steps+=1
  var v=ui.view
  var phase=String(v.phase)
  if not phases.has(phase): phases.append(phase)
  if phase in ["cleared","prison_end"]:
   stop_reason="end_phase:"+phase
   break
  var c=Normal.choose(v,recipe_style,navigation)
  if c.is_empty():
   stop_reason="no_legal_step"
   break
  var before=int(ui.game.state.version)
  print("FK step %d phase=%s chosen=%s params=%s" % [steps,phase,String(c.get("payload",{}).get("kind","")),JSON.stringify(c.get("payload",{}))])
  await _drive(c,v)
  var after=int(ui.game.state.version)
  if after>before:
   stale=0
   commits+=1
   print("FK %s #%d phase=%s kind=%s version=%d" % [label,commits,phase,String(c.payload.kind),after])
  else:
   stale+=1
   if stale>=12:
    stop_reason="stuck_on:"+String(c.payload.kind)
    break
  Normal.remember(v,c,navigation)
 print("FK SESSION %s commits=%d steps=%d stop=%s phases=%s" % [label,commits,steps,stop_reason,str(phases)])
 DirAccess.make_dir_recursive_absolute(OUT_ROOT)
 _write_json(OUT_ROOT+"/recipe-"+label+".json",{
  "seed":recipe_seed,"cap":recipe_cap,"style":recipe_style,
  "engine":Engine.get_version_info().string,"window":"1600x900",
  "game_class":"tests/game_fixture.gd","persistence":false,"feedback_duration":0.04,
  "commits":commits,"steps":steps,"stop_reason":stop_reason,"phases_seen":phases,
  "final_phase":String(ui.view.phase),"final_version":int(ui.view.version)})
 print("RECIPE seed=%d commits=%d steps=%d stop=%s" % [recipe_seed,commits,steps,stop_reason])
 finish_checks()

# Real-input drive of one chosen visible fact: the same shape as tests/normal_play_ui_cases.gd, so
# the recipe reproduces the submits a human click/drag produces.
func _drive(c: Dictionary, v: Dictionary) -> void:
 var p: Dictionary=c.get("payload",{})
 if p.kind=="card":
  if ui.card_faces.get(p.uid,false)!=p.free: await flip(p.uid)
  if ui._card_is_free(p.uid,p.free) or p.get("self_target",false):
   ui.card_buttons[p.uid].pressed.emit();await frames()
  else:
   await start_drag(p.uid,p.slot)
   await release_target(await reveal_drop_target(c.key))
  if p.has("hand_uid"):
   if not ui._selecting_hand(): return
   ui.card_buttons[p.hand_uid].pressed.emit();await frames()
  return
 ui.show_items=p.kind.begins_with("item_")
 if ui.show_items and p.has("item"): ui.selected_item=p.item
 ui.show_hook=p.kind=="hook"
 ui.show_pressure=false
 if p.kind=="attack": ui.selected_enemy=p.enemy
 if p.kind in ["manual","retain","retain_skip"]:
  ui.show_body=true;ui.selected_card=""
  if p.has("target"):
   var body_target=Normal.target(v,p.target)
   if not body_target.is_empty(): ui.selected_slot=body_target.slot
 ui.render();await frames(1)
 if p.kind=="attack":
  for attempt in range(4):
   if ui.attack_forms.get(p.type,0)==p.form: break
   var button=ui.find_child("BasicAttack_"+p.type,true,false)
   if button==null: break
   var point=button.get_global_rect().get_center()
   await mouse_button(point,MOUSE_BUTTON_RIGHT,true);await mouse_button(point,MOUSE_BUTTON_RIGHT,false)
   if ui.attack_forms.get(p.type,0)==p.form: break
 if p.kind=="depart" and not ui.candidate_buttons.has(c.key):
  await InterfaceCases.press(self,"OpenMap")
 if p.kind=="event":
  if p.action=="reward" and p.get("type","")!="skip":
   await EventCases.open_selection(self,"reward")
  else:
   var groups=ui.view.room_event.selections.filter(func(group):return group.options.any(func(option):return option.choice==p.get("choice","")))
   if not groups.is_empty(): await EventCases.open_selection(self,groups[0].id)
 if p.kind=="prison":
  if p.action=="explore" and ui.prison_detail!="":
   var back=ui.find_child("PrisonDetailsBack",true,false)
   if back!=null:
    var point=back.get_global_rect().get_center()
    await move_mouse(point);await mouse_button(point,MOUSE_BUTTON_LEFT,true);await mouse_button(point,MOUSE_BUTTON_LEFT,false)
  elif p.action in ["vent_kick","vent_exit","key","door_exit","unlock"]:
   var kind="vent" if p.action.begins_with("vent") else "door"
   var places=ui.view.prison.space.sites.filter(func(site):return site.interaction.get("kind","")==kind)
   if not places.is_empty() and ui.prison_detail!=places[0].id:
    await ExplorationCases.open_details(self,places[0].id)
 if p.kind=="surrender":
  await InterfaceCases.press(self,"SurrenderButton")
  await InterfaceCases.press(self,"SurrenderButton")
  return
 await click(p.kind,p)
