extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Mechs=preload("res://core/restraint_mechs.gd")

static func run(t) -> void:
 cycle(t)
 defense(t)
 rebind(t)
 persistence(t)

static func worn(g, source: String) -> Array:
 return g.state.equipment.filter(func(item):return item.source==source)

static func cycle(t) -> void:
 var g=Game.new(42,true,Mechs.ENCOUNTER)
 var mini=g.state.enemies[0]
 var support=g.state.enemies[1]
 t.check(mini.type==Mechs.MINI and support.type==Mechs.SUPPORT and mini.hp==32 and support.hp==30 and g.state.guard_bind.progress==40,"MECH opening uses the fixed pair and capture value 40")
 t.check(mini.intent.kind=="mech_fit" and mini.mech_armor==10 and Mechs.immune(g,mini) and support.intent.kind=="mech_idle" and g.get_view().npc_speech.text=="小身材,大拳头！","MECH opening projects shields, intents and the authored speech")
 var ended=t.action(g,"end").ok
 mini=g._enemy(mini.id)
 t.check(ended and g.state.guard_bind.progress==60.0 and g.state.round==2 and mini.intent.kind=="mech_prepare" and mini.mech_armor==0.0,"MECH two successful opening fits advance capture once and charge armor clears next round")
 var first=worn(g,mini.id)
 t.check(first.size()==2 and first.all(func(item):return item.material=="leather" and item.grade+g.equipment_tier(item)==3 and item.tough_durability==8.0 and item.maximum==g.Equipment.maximum(item.grade)),"MECH ordinary opening gear has score 3 with independent toughness")
 ended=t.action(g,"end").ok
 mini=g._enemy(mini.id);support=g._enemy(support.id)
 t.check(ended and mini.mech_restraint_value==5 and support.mech_armor==10.0 and support.mech_extra and g.get_view().statuses.any(func(row):return row.id=="mech_extra"),"MECH round two grants support armor and the one-shot extra fitting")
 ended=t.action(g,"end").ok
 support=g._enemy(support.id)
 t.check(ended and g.state.guard_bind.progress==80.0 and not support.mech_extra and support.mech_armor==6.0,"MECH round three uses the extra fitting and switches support armor")
 var second=worn(g,mini.id).filter(func(item):return item not in first)
 t.check(second.size()==3 and second.all(func(item):return item.grade+g.equipment_tier(item)==5),"MECH each piece in the boosted batch keeps the requested score")
 t.check(g.state.special_equipment.any(func(item):return item.grade==2 and g.equipment_tier(item)==2),"MECH support installs a medium two-tier toy")
 ended=t.action(g,"end").ok
 mini=g._enemy(mini.id)
 t.check(ended and mini.mech_restraint_value==7 and mini.intent.kind=="mech_fit","MECH active capture builds to score 7 in round five")
 ended=t.action(g,"end").ok
 support=g._enemy(support.id)
 t.check(ended and g.state.guard_bind.progress==100.0 and support.intent.kind=="capture" and g.state.phase=="battle","MECH round five fits lock in capture for the next enemy turn")
 t.check(worn(g,mini.id).any(func(item):return g.Equipment.is_shackle(item) and not item.has("enchantment")),"MECH over-cap fitting creates real cuffs without an enchantment")
 t.check(t.action(g,"end").ok and g.state.phase=="captured" and g.state.capture.by==support.name,"MECH full capture enters the shared imprisonment flow")

static func defense(t) -> void:
 var g=Game.new(42,true,Mechs.ENCOUNTER)
 var mini=g.state.enemies[0]
 g.state.sure_cast=true
 var cast=t.action(g,"attack",{"type":"fireball","enemy":mini.id}).ok
 mini=g._enemy(mini.id)
 t.check(cast and mini.hp==32 and mini.mech_armor==10.0,"MECH real fireball is blocked before touching armor in the immune round")
 g._damage_enemy(mini,12.0,"physical","fixture")
 t.check(mini.mech_armor==4.0 and mini.hp==32 and mini.intent.kind=="mech_fit","MECH mechanical reduction precedes armor and partial damage leaves the intent")
 g._damage_enemy(mini,6.0,"fixed","fixture")
 t.check(mini.mech_armor==0.0 and mini.hp==30 and mini.intent.kind=="mech_stun","MECH breaking armor passes overflow to HP and changes the intent to stun")
 var ended=t.action(g,"end").ok
 mini=g._enemy(mini.id)
 t.check(ended and g.state.guard_bind.progress==40.0 and worn(g,mini.id).is_empty() and mini.intent.kind=="mech_prepare" and not Mechs.immune(g,mini),"MECH stun skips fitting and the next round restores the ordinary preparation window")
 g.state.sure_cast=true
 t.check(t.action(g,"attack",{"type":"fireball","enemy":mini.id}).ok and g._enemy(mini.id).hp<30.0,"MECH magic damage reaches HP outside the immune round")

static func rebind(t) -> void:
 var g=Game.new(42,true,Mechs.ENCOUNTER)
 var mini=g.state.enemies[0]
 var support=g.state.enemies[1]
 t.check(g.equipment_at("mouth").is_empty(),"MECH opening capture skips an empty mouth")
 t.action(g,"end")
 support=g._enemy(support.id)
 var gag=g._install_template("mouth_band","mouth",4.0,10.0,false,"fixture")
 g.CaptureBind.damage_bind(g,100.0,"fixture")
 t.check(support.intent.kind=="bind_apply" and support.guard.cycle_step==1,"MECH broken capture immediately replaces the next support action")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==40.0 and g._enemy(support.id).guard.cycle_step==1 and g.equipment_tier(g._equipment(gag.id))>1,"MECH rebind reinforces the existing gag and preserves the interrupted cycle step")
 g=Game.new(42,true,Mechs.ENCOUNTER)
 mini=g.state.enemies[0];support=g.state.enemies[1]
 t.action(g,"end");t.action(g,"end")
 g.state.evasion=2
 var before=worn(g,mini.id).size()
 t.check(t.action(g,"end").ok and g._enemy(support.id).mech_extra and g.state.guard_bind.progress==60.0 and worn(g,mini.id).size()==before,"MECH a completely evaded ordinary batch neither spends the extra fitting nor raises capture")
 mini=g._enemy(mini.id);support=g._enemy(support.id)
 var current=mini.mech_restraint_value
 g._defeat_enemy(support)
 t.check(not g.CaptureBind.has_bind(g) and t.action(g,"end").ok and g._enemy(mini.id).mech_restraint_value==current,"MECH defeating the support removes capture and pauses further growth")

static func persistence(t) -> void:
 var g=Game.new(42,true,Mechs.ENCOUNTER)
 var mini=g.state.enemies[0]
 g._damage_enemy(mini,3.0,"fixed","fixture")
 var twin=Save.roundtrip(t,g,"mech partial armor and opening capture")
 if twin!=null: Save.step_both(t,g,twin,"end")
 var before=g.export_snapshot()
 var bad=before.duplicate(true)
 bad.enemies[0].mech_armor=11.0
 t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==before,"MECH invalid armor snapshot is rejected atomically")
 bad=before.duplicate(true)
 bad.enemies[1].intent.kind="mech_fit"
 t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==before,"MECH crossed actor intent is rejected atomically")
