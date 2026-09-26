extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func use(t,g,type: String) -> Dictionary:
 g._gain_tool(type)
 return t.action(g,"item_use",{"item":g.state.items.back().id})

static func run(t) -> void:
 preload("res://tests/mana_recovery_cases.gd").run(t)
 preload("res://tests/body_consumable_cases.gd").run(t)
 preload("res://tests/tentacle_friend_cases.gd").run(t)
 preload("res://tests/mana_flask_cases.gd").run(t)
 var wrapped=Game.new(42);wrapped.state.mana=50
 wrapped._install_assembly("wrap","left","fixture",1,1);wrapped._gain_tool("mana_potion")
 var wrapped_item=wrapped.state.items.back().id
 t.check(wrapped.hands_can_hold() and not t.find_action(wrapped,"item_use",{"item":wrapped_item}).valid,"POTION one-sided hand restraint reaches posture threshold despite free opposite grip")
 wrapped.state.posture="sit"
 t.check(t.action(wrapped,"item_use",{"item":wrapped_item}).ok and wrapped.state.mana==70,"POTION one-sided hand restraint permits actual seated use")
 for type in ["mana_potion","energy_potion","charge_potion"]:
  var trial=Game.new(42);trial.state.mana=50;trial._gain_tool(type)
  var item_id=trial.state.items.back().id
  t.check(t.find_action(trial,"item_use",{"item":item_id}).valid,"POTION full effect remains usable standing: "+type)
  trial.add_fixture("upper_arm",4)
  t.check(trial.restraint_degree("arms")==0.5 and t.find_action(trial,"item_use",{"item":item_id}).valid,"POTION half-degree arm restraint permits standing: "+type)
  trial.add_fixture("forearm",4)
  var candidate=t.find_action(trial,"item_use",{"item":item_id})
  var snapshot=trial.export_snapshot()
  t.check(trial.restraint_degree("arms")==1 and not candidate.valid and candidate.reason.contains("坐下或躺下") and not t.action(trial,"item_use",{"item":item_id}).ok and trial.state==snapshot,"POTION degree-one arms standing rejects without consuming resources: "+type)
  t.check(trial.get_view().items.filter(func(item):return item.id==item_id)[0].description.contains("0.5也可"),"POTION item description explains fractional posture threshold: "+type)
  trial.add_fixture("fingers",8)
  trial.state.posture="sit"
  var seated_before=trial.state[trial.Tools.TYPES[type].effect]
  t.check(not trial.hands_can_hold() and t.action(trial,"item_use",{"item":item_id}).ok and trial.state[trial.Tools.TYPES[type].effect]==seated_before+trial.Tools.TYPES[type].amount,"POTION seated drinks full amount without either hand gripping: "+type)
  trial._gain_tool(type);item_id=trial.state.items.back().id
  trial._install_template("mouth_band","mouth",12.8,16,false,"fixture",2)
  trial.state.posture="lie"
  var previous=trial.state[trial.Tools.TYPES[type].effect]
  var expected=trial.Consumables.amount(trial,type)
  t.check(not trial.hands_can_hold() and t.action(trial,"item_use",{"item":item_id}).ok and trial.state[trial.Tools.TYPES[type].effect]==previous+expected and trial.state.items.is_empty(),"POTION lying bypasses grip but preserves mouth reduction and single consumption: "+type)
 var g=Game.new(42)
 t.check(g.Tools.DROP_POOL.size()==9 and g.Tools.DROP_POOL.has("lubricant_potion") and g.Tools.DROP_POOL.has("shard") and g.Tools.DROP_POOL.has("saw") and not g.Tools.DROP_POOL.has("picks"),"ITEM pool contains seven consumables and two original cutters")
 g.state.mana=80
 var energy=g.state.energy
 t.check(use(t,g,"mana_potion").ok and g.state.mana==100 and g.state.energy==energy and g.state.items.is_empty(),"ITEM mana potion restores twenty for no energy and is consumed")
 t.check(use(t,g,"energy_potion").ok and g.state.energy==energy+2,"ITEM energy potion immediately adds two")
 t.check(use(t,g,"charge_potion").ok and g.state.charge==2,"ITEM charge potion reuses charge stacks")
 var mouth=g._install_template("mouth_band","mouth",12.8,16,false,"fixture",2)
 t.check(g.Consumables.amount(g,"charge_potion",3)==2,"ITEM sum four rounds halved odd amount upward")
 mouth.durability=mouth.maximum
 t.check(g.Consumables.amount(g,"charge_potion",3)==1,"ITEM sum above four rounds halved odd amount downward")
 g.state.mana=80
 t.check(g.level("arms")==0 and g.state.posture=="stand" and use(t,g,"mana_potion").ok and g.state.mana==90,"ITEM mouth-only restraint permits standing and halves actual potion recovery")
 t.check(use(t,g,"charge_potion").ok and g.state.charge==3,"ITEM occupied mouth halves actual charge stacks")
 g.add_fixture("fingers",8)
 g.state.posture="stand"
 t.check(use(t,g,"mana_scroll").ok and g.state.temporary_mana==10,"ITEM free toes allow scroll with both fingers and mouth bound")
 g.add_fixture("toes",8)
 g.state.posture="sit"
 g._gain_tool("draw_scroll")
 var id=g.state.items.back().id
 var before=g.export_snapshot()
 t.check(not t.action(g,"item_use",{"item":id}).ok and g.state==before,"ITEM all finger and toe sites bound rejects scroll atomically")
 g=Game.new(42)
 g._draw(4)
 var result=use(t,g,"draw_scroll")
 t.check(result.ok and g.state.hand.size()==10 and result.card_feedback.filter(func(e):return e.kind=="draw").size()==1,"ITEM scroll stops at ten and emits only actual draw animation")
 g._gain_tool("draw_scroll");before=g.export_snapshot()
 t.check(not t.action(g,"item_use",{"item":g.state.items.back().id}).ok and g.state==before,"ITEM full hand does not consume scroll")
 g=Game.new(42)
 g._install_template("mouth_band","mouth",24,24,false,"fixture",3)
 t.check(g.cast_view().chance==0 and use(t,g,"casting_scroll").ok and g.cast_view().chance==1,"ITEM guarantee modifies actual cast preview despite mouth penalty")
 var h=Save.roundtrip(t,g,"guaranteed next cast")
 var mana=g.state.mana
 t.check(t.action(g,"attack",{"type":"fireball"}).ok and g.state.mana==mana-10 and not g.state.sure_cast and g.cast_view().chance==0,"ITEM actual spell pays normal cost consumes guarantee once then restores chance")
 t.check(h.state.sure_cast and h.cast_view().chance==1,"ITEM guarantee survives current-version save without consumption")
 h._finish_battle()
 t.check(h.state.sure_cast,"ITEM unused guarantee remains through victory")
 t.check(t.action(h,"reward",{"type":"skip"}).ok and h.state.phase=="prepare" and h.state.sure_cast,"ITEM unused guarantee remains through the first preparation turn")
 t.check(t.action(h,"finish_prepare").ok and not h.state.sure_cast,"ITEM unused guarantee expires when preparation ends the session")
 # Every battle resolves one drop roll; views and reward acknowledgement never roll.
 g=Game.new(42);g.state.item_drop_chance=0
 var draws=g.state.rng.item_drop
 g._finish_battle()
 t.check(g.state.item_drop_chance==10 and g.state.battle_item_drop=="" and g.state.rng.item_drop==draws+1,"DROP zero percent misses and increases by ten")
 before=g.export_snapshot();g.get_view();g.command_facts();g._finish_battle()
 t.check(g.state==before,"DROP views and duplicate finish cannot reroll")
 g=Game.new(42);g.state.item_drop_chance=100
 for i in range(4):g._gain_tool("shard")
 g._finish_battle()
 t.check(g.state.item_drop_chance==90 and g.state.items.size()==4 and g.state.battle_item_drop in g.Tools.DROP_POOL,"DROP guaranteed hit freezes a pending reward without auto pickup")
 var dropped=g.state.battle_item_drop
 t.check(t.action(g,"reward",{"category":"item","type":dropped}).ok and g.state.items.size()==5,"DROP explicit pickup keeps reward when over capacity")
 h=Save.roundtrip(t,g,"frozen item reward")
 t.check(h.state.battle_item_drop==dropped and h.state.items==g.state.items,"DROP item result and chance survive save")
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.items==h.state.items and g.state.item_drop_chance==90,"DROP skipping card reward retains item and does not reroll")
 var seen={}
 for seed_value in range(64):
  var trial=Game.new(seed_value);trial.state.item_drop_chance=100;trial._finish_battle()
  seen[trial.state.battle_item_drop]=true
 t.check(seen.size()==g.Tools.DROP_POOL.size(),"DROP deterministic seed matrix reaches every registered item")
 before=h.export_snapshot();var corrupt=before.duplicate(true);corrupt.item_drop_chance=101
 t.check(not h.restore_snapshot(corrupt).ok and h.state==before,"DROP invalid persisted probability rejects atomically")
