extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func run(t) -> void:
 var weak=Game.new(42,true,"small_circle_solo")
 var weak_id=weak.state.enemies[0].id
 t.check(weak._enemy(weak_id).hp==30 and weak.Enemies.TYPES.small_circle.strength==1 and weak.Enemies.FirstFloor.candidates(weak).any(func(m):return m.type=="small_circle"),"RITUAL weak variant has thirty HP and enters the normal weak draw")
 t.action(weak,"end");t.action(weak,"end")
 t.check(weak.equipment_targets().size()==4 and weak._enemy(weak_id).application_bonus==6,"RITUAL weak variant reuses the complete ritual behavior")
 var g=Game.new(42,true,"ominous_circle_solo")
 var id=g.state.enemies[0].id
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and g._enemy(id).ritual==0 and g._enemy(id).application_bonus==0,"RITUAL declaration is readonly and inactive until performed")
 t.check(t.action(g,"end").ok and g.physical_pieces().is_empty() and g._enemy(id).ritual==3 and g._enemy(id).application_bonus==3,"RITUAL acquisition ticks at the end of its own first turn")
 var twin=Save.roundtrip(t,g,"ritual active before first application")
 Save.step_both(t,g,twin,"end")
 t.check(g.equipment_targets().size()==4 and g._enemy(id).application_bonus==6,"RITUAL first application installs four then grows to six")
 Save.step_both(t,g,twin,"end")
 var pieces=g.equipment_targets()
 t.check(pieces.size()==11 and g._enemy(id).application_bonus==9,"RITUAL second application installs seven without consuming bonus")
 t.check(pieces.all(func(x):return x.source==id and ((x.grade==1 and g.tier(x.durability,x.maximum)==2) or (x.grade==2 and g.tier(x.durability,x.maximum)==1))) and pieces.any(func(x):return x.grade==1) and pieces.any(func(x):return x.grade==2),"RITUAL actual equipment uses both legal grade/tightness pairs")
 t.check(g.validate()=="" and g.state.composites.is_empty() and g.state.special_equipment.is_empty(),"RITUAL ordinary source never generates composite or special equipment")
 # Fill remaining legal positions through the same installer, then exercise a full turn.
 var fill=g._enemy(id).intent.duplicate(true);fill.count=1000
 g.Application.execute(g,fill,id)
 before=g.export_snapshot()
 t.check(not g.Application.can_apply(g,fill,id) and not g.state.links.is_empty() and g.EnemyPlans.can_affect_equipment(g,g._enemy(id)),"RITUAL legal links are filled too; remaining reinforcement keeps encounter active")
 t.check(t.action(g,"end").ok and g.state.phase=="battle" and g.state.reward_count==before.reward_count and g._enemy(id).application_bonus==12,"RITUAL full installation switches remaining quota to reinforcement, without premature reward")
 t.check(g.state.equipment.map(func(x):return x.id)==before.equipment.map(func(x):return x.id) and g.state.equipment.any(func(x):return x.durability>before.equipment.filter(func(old):return old.id==x.id)[0].durability) and g.state.logs.any(func(log):return log.text.contains("改为加固")),"RITUAL fallback tightens actual existing equipment without replacement and reports the result")
 # Saturate reinforcement using its real operation, then reopen exactly one link
 # and one ordinary reinforcement to verify the within-batch boundary.
 for i in range(200):
  var targets=g.EnemyPlans.targets(g,g._enemy(id),"tighten")
  if targets.is_empty(): break
  g._enemy_operation(g._enemy(id),{"kind":"tighten","target":targets[0].id,"tier":3,"text":"加固拘束具","delayed":false})
 g.Application.execute(g,fill,id)
 var removed_link=g.state.links.pop_back()
 var foot=g.state.equipment.filter(func(x):return x.slot=="foot")[0]
 foot.durability=foot.maximum*0.8
 g._enemy(id).application_bonus=1
 before=g.export_snapshot()
 twin=Save.roundtrip(t,g,"ritual one link space then one reinforcement")
 Save.step_both(t,g,twin,"end")
 t.check(g.state.links.size()==before.links.size()+1 and not g.state.links.any(func(link):return link.id==removed_link.id) and g._equipment(foot.id).durability==foot.maximum,"RITUAL fills remaining real link space before spending one missing application on normal reinforcement")
 t.check(g.state.equipment.map(func(x):return x.id)==before.equipment.map(func(x):return x.id) and g.state.phase=="reward" and g.state.reward_count==before.reward_count+1,"RITUAL only complete installation and reinforcement exhaustion ends battle once")

 g=Game.new(42,true,"ominous_circle_solo");id=g.state.enemies[0].id
 g.state.round=2
 g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.action(g,"attack",{"type":"kick","form":2,"enemy":id});t.action(g,"end")
 t.check(g._enemy(id).stage==1 and g._enemy(id).ritual==0 and g._enemy(id).application_bonus==0,"RITUAL interrupting acquisition prevents activation and growth")
 t.action(g,"end")
 t.check(g._enemy(id).ritual==3 and g._enemy(id).application_bonus==3,"RITUAL delayed acquisition activates only when executed")

 g=Game.new(42,true,"ominous_circle_solo");id=g.state.enemies[0].id
 g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.action(g,"end");t.action(g,"attack",{"type":"kick","form":2,"enemy":id});t.action(g,"end")
 t.check(g.physical_pieces().is_empty() and g._enemy(id).stage==2 and g._enemy(id).application_bonus==6,"RITUAL active effect grows even when its application is interrupted")
 twin=Save.roundtrip(t,g,"ritual after interrupted application")
 Save.step_both(t,g,twin,"end")
 t.check(g.equipment_targets().size()==7 and g._enemy(id).application_bonus==9,"RITUAL resumed application uses current bonus rather than old declared quantity")
 before=g.export_snapshot()
 var broken=before.duplicate(true);broken.enemies[0].application_bonus=-1
 t.check(not g.restore_snapshot(broken).ok and g.export_snapshot()==before,"RITUAL invalid saved bonus rejects atomically")
 broken=before.duplicate(true);broken.enemies[0].intent.profiles[0].tier=4
 t.check(not g.restore_snapshot(broken).ok and g.export_snapshot()==before,"RITUAL invalid saved application profile rejects atomically")
 broken=before.duplicate(true);broken.enemies[0].intent.tighten_missing="yes"
 t.check(not g.restore_snapshot(broken).ok and g.export_snapshot()==before,"RITUAL malformed fallback flag rejects atomically")

 g=Game.new(42,true,"ominous_circle_solo");id=g.state.enemies[0].id
 t.action(g,"end");g._enemy(id).hp=1
 t.action(g,"attack",{"type":"strike","enemy":id})
 t.check(g.state.phase=="reward" and g._enemy(id).application_bonus==3 and not g.get_view().statuses.any(func(s):return s.id=="ritual_"+id),"RITUAL death stops growth and removes active status")

 g=Game.new(42,true,"ominous_circle_solo")
 g.state.posture="lie";g._start_battle();id=g.state.enemies[0].id
 t.check(g.state.order=="last" and g._enemy(id).application_bonus==3,"RITUAL enemy-first order resolves first own turn normally")
 t.action(g,"end")
 t.check(g._enemy(id).application_bonus==6 and g.equipment_targets().size()==4,"RITUAL enemy-first order ticks once per own turn")
