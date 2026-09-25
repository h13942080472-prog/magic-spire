extends SceneTree

# Run with the editor executable and --main-pack pointing at the release PCK.
# Official templates disable script overrides; the actual release gets a separate startup test.
var failures: Array[String]=[]

func check(ok: bool, message: String) -> void:
 if not ok:
  failures.append(message)
  push_error(message)

func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 check(not FileAccess.file_exists("res://project.godot"),"Probe must load exported project.binary, not source files")
 var expected_version=OS.get_environment("SPIRE_PROBE_VERSION")
 if expected_version=="": expected_version="0.16"
 check(ProjectSettings.get_setting("application/config/version","")==expected_version,"Release version must match package manifest")
 check(not ResourceLoader.exists("res://tests/test_game.gd") and not ResourceLoader.exists("res://tools/check_content.gd"),"Development scripts must not be exported")
 var scene=load("res://main.tscn")
 check(scene!=null,"Main scene must be present in PCK")
 if scene==null:
  finish();return
 var catalog=load("res://core/content_catalog.gd")
 var game_class=load("res://core/game.gd")
 var fixture=game_class.new(42)
 if catalog.report.directory!=OS.get_environment("SPIRE_PROBE_CONTENT"):
  catalog.loaded=false
  catalog.ensure(fixture,OS.get_environment("SPIRE_PROBE_CONTENT"))
 var ui=scene.instantiate()
 ui.persistence_enabled=false
 root.add_child(ui)
 await process_frame
 await process_frame
 check(ui.show_home,"Standalone release opens its home screen")
 check(catalog.report.ok and catalog.report.files==12,"Standalone release loads all 12 distributed content packs")
 if not catalog.report.ok: print("RELEASE CONTENT ERRORS: ",catalog.report.errors)
 check(catalog.report.directory==OS.get_environment("SPIRE_PROBE_CONTENT"),"Content must come from the verified distribution path")
 var layer_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/equipment-leg-layers.json"))
 check(layer_data is Array and not layer_data.is_empty(),"Dynamic equipment layer metadata must be included")
 if layer_data is Array:
  for entry in layer_data:
   check(load(entry.texture)!=null and load(entry.free_texture)!=null,"Dynamic equipment texture missing: "+str(entry.id))
 ui.restart(42)
 await process_frame
 await process_frame
 check(ui.game.validate()=="" and not ui.game.command_facts().is_empty(),"New game has valid state and formal actions")
 var store=load("res://core/save_store.gd").new(OS.get_environment("SPIRE_PROBE_SAVES"))
 check(store.directory!="","Smoke saves need an explicit isolated directory")
 if store.directory!="":
  var saved=store.write_game(ui.game)
  check(saved.ok,"Exported release can save a scene checkpoint")
  var restored=store.read_slot(ui.game.state.save_slot)
  check(restored.ok,"Exported release can read its saved checkpoint")
  if restored.ok:
   var game=load("res://core/game.gd").new(7)
   check(game.restore_snapshot(restored.snapshot).ok and game.validate()=="","Exported release can restore its saved checkpoint")
 ui.restart(42,true,"equipment")
 await process_frame
 check(ui.view.practice and ui.game.validate()=="","Exported practice loads equipment and real action rules")
 check(ui.find_child("CharacterSelect",true,false)!=null or ui.selected_character=="original","Character selection controller is included")
 ui.selected_character="witch";ui.restart(42)
 await process_frame
 await process_frame
 check(ui.game.Character.active(ui.game) and ui.game.state.deck.size()==11 and ui.game.validate()=="","Exported role two has its eleven-card starter and valid state")
 var spec=ui.game.Cards.Rules.SPECS.witch_magic_hand
 if OS.get_environment("SPIRE_PROBE_WITCH_BALANCE")=="1":
  var g=ui.game
  check(g.state.mana_max==75 and g.state.mana==75 and g.Pressure.maximum(g)==75 and g.state.flask_mana==50 and g.state.relics==["witch_amulet"],"Balanced release includes revised role-two starting resources")
  check(spec.free_effects==[{"op":"evasion","amount":2}] and spec.mana_cost==30 and spec.hits==4,"Balanced release includes revised magic hand faces")
  check(load("res://assets/ui/relics/witch_amulet.svg")!=null and load("res://assets/ui/relics/witch_noodles.svg")!=null,"Balanced release includes both new relic icons")
  check(g.Relics.TYPES.witch_noodles.rarity=="common" and not g.Character.allowed_card(g,"ease"),"Balanced release includes exclusive relic and card restrictions")
 check(spec.free_effects[0].get("buff","")=="witch_hand_freedom" or (spec.free_effects==[{"op":"evasion","amount":2}] and spec.mana_cost==30.0),"Exported magic hand has role-two free effect")
 var packed=store.pack(ui.game.export_snapshot())
 var decoded=store.unpack(packed)
 check(decoded.ok,"Exported role-two snapshot serializes")
 if decoded.ok:
  var resumed=game_class.new(7)
  check(resumed.restore_snapshot(decoded.snapshot).ok and resumed.Character.active(resumed),"Exported role-two save restores its character")
 if OS.get_environment("SPIRE_PROBE_CHARGE_ALL")=="1":
  probe_charge_all(game_class)
 print("RELEASE CONTENT PACKS: ",catalog.report.files)
 ui.queue_free()
 await process_frame
 finish()

func probe_charge_all(game_class) -> void:
 var g=game_class.new(42,false,"equipment",true,false,25,false,false,"witch")
 var room=g.room_data(g.state.room)
 room.kind="battle";room.encounter="belt_tie"
 room.erase("encounter_choices");room.erase("encounter_selected")
 g.state.room_encounters[room.id]="belt_tie"
 g._start_battle()
 g.state.energy=20;g.state.mana=g.state.mana_max;g.state.pressure=0
 for enemy in g.state.enemies:
  enemy.hp=1000.0;enemy.max_hp=1000.0
 for part in ["hand","mouth","mind"]:
  g.state.witch_charges={"hand":3,"mouth":3,"legs":4,"mind":3}
  var expected=g.state.witch_charges.duplicate();expected[part]=0
  var actions=g.command_facts().filter(func(c):return c.payload.get("type")=="witch_"+part and c.payload.get("form")==1)
  check(not actions.is_empty(),"Patch release candidate exists: "+part)
  if actions.is_empty(): continue
  var action=actions[0]
  check(action.valid and action.payload.hits==4,"Patch uses pre-release charge count: "+part)
  check(g.dispatch(g.command(action.payload,g.state.version),g.state.version).ok and g.state.witch_charges==expected,"Patch consumes all and only selected charges: "+part)
  actions=g.command_facts().filter(func(c):return c.payload.get("type")=="witch_"+part and c.payload.get("form")==1)
  check(not actions.is_empty() and actions[0].payload.hits==1,"Patch next release has one hit: "+part)
 print("CHARGE ALL PROBE COMPLETE")

func finish() -> void:
 if failures.is_empty(): print("RELEASE PROBE PASS")
 else: print("RELEASE PROBE FAIL: ",failures.size())
 quit(0 if failures.is_empty() else 1)
