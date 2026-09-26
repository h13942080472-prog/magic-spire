extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Special=preload("res://data/special_equipment.gd")

static func run(t) -> void:
 var cup_families=["glans_cup","full_cup","urethral_full_cup","forced_milking_cup"]
 t.check(Special.RANDOM_POOLS[1].all(func(type):return Special.DESIGNS[type].grade==1 and Special.TYPES[type].family not in cup_families and Special.TYPES[type].family!="external_wand"),"VERSATILE initial pool excludes cups and external wand")
 t.check("external_wand_medium" in Special.RANDOM_POOLS[2] and Special.RANDOM_POOLS[2].all(func(type):return Special.DESIGNS[type].grade==2 and Special.TYPES[type].family not in cup_families),"VERSATILE external wand starts in the cup-free medium pool")
 var seen={}
 for seed_value in t.seed_values("enemy_cycle"):
  var g=Game.new(seed_value,true,"versatile_solo");var id=g.state.enemies[0].id
  t.check(g.Enemies.TYPES.versatile.humanoid and g.Enemies.TYPES.versatile.strength==2 and g._enemy(id).hp==60 and g._enemy(id).intent.kind=="idle","VERSATILE registered human strong enemy opens by idling")
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(g.state==before,"VERSATILE published idle is query-stable")
  t.check(t.action(g,"end").ok and g.state.special_equipment.is_empty() and g._enemy(id).intent.kind=="apply","VERSATILE idle advances to special installation")
  var declared=g._enemy(id).intent.duplicate(true)
  t.check(declared.replace and declared.templates==Special.RANDOM_POOLS[1],"VERSATILE special action has human replacement permission and the initial pool")
  t.check(t.action(g,"end").ok and g.state.special_equipment.size()==1,"VERSATILE installs exactly one special item")
  var item=g.state.special_equipment[0]
  t.check(item.type in Special.RANDOM_POOLS[1] and item.grade==1 and g.tier(item.durability,item.maximum)==2,"VERSATILE installed item is initial grade and tier two")
  var control=g._enemy(id).intent.duplicate(true);seen[control.kind]=true
  t.check(control.kind in ["lock","equipment_batch"],"VERSATILE chooses one legal control branch")
  var locked_before=g.state.equipment.filter(func(piece):return piece.locked).size()
  t.check(t.action(g,"end").ok and g._enemy(id).intent.kind=="apply","VERSATILE control returns to special installation")
  if control.kind=="lock":
   t.check(g.state.equipment.filter(func(piece):return piece.locked).size()==locked_before+1,"VERSATILE lock branch locks one actual random target")
  else:
   t.check(g.state.equipment.all(func(piece):return g.tier(piece.durability,piece.maximum)==3),"VERSATILE reinforce branch tightens both available restraints")
  t.check(g.validate()=="","VERSATILE completed cycle validates")
 t.check(seen.keys().has("lock") and seen.keys().has("equipment_batch"),"VERSATILE sampled control branch reaches lock and double reinforcement")

 var lock_only=Game.new(42,true,"versatile_solo")
 for piece in lock_only.state.equipment: piece.durability=piece.maximum
 t.action(lock_only,"end");t.action(lock_only,"end")
 t.check(lock_only.state.enemies[0].intent.kind=="lock","VERSATILE chooses lock when no restraint can be reinforced")
 var tighten_only=Game.new(42,true,"versatile_solo")
 for piece in tighten_only.state.equipment: piece.locked=true
 t.action(tighten_only,"end");t.action(tighten_only,"end")
 t.check(tighten_only.state.enemies[0].intent.kind=="equipment_batch","VERSATILE chooses reinforcement when no restraint can be locked")

 var fallback=Game.new(42,true,"versatile_solo")
 for piece in fallback.state.equipment: piece.durability=0
 fallback._cleanup();t.action(fallback,"end");t.action(fallback,"end")
 t.check(fallback.state.enemies[0].intent.kind=="apply" and fallback.state.enemies[0].intent.text.contains("改为安装性玩具"),"VERSATILE no control target falls back while forming the intent")

 var delayed=Game.new(7,true,"versatile_solo");var delayed_id=delayed.state.enemies[0].id
 t.action(delayed,"end");t.action(delayed,"end")
 var selected=delayed._enemy(delayed_id).intent.duplicate(true)
 delayed.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.action(delayed,"attack",{"type":"kick","form":2,"enemy":delayed_id})
 var twin=Save.roundtrip(t,delayed,"versatile delayed control")
 Save.step_both(t,delayed,twin,"end")
 t.check(delayed._enemy(delayed_id).stage==3 and delayed._enemy(delayed_id).intent==selected,"VERSATILE interruption preserves its announced branch")
 Save.step_both(t,delayed,twin,"end")
 t.check(delayed._enemy(delayed_id).stage==4 and delayed._enemy(delayed_id).intent.kind=="apply","VERSATILE saved branch resumes once and returns to cycle")
