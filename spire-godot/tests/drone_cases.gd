extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Bind=preload("res://core/capture_bind.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func run(t) -> void:
 var g=Game.new(42,true,"drone_solo")
 var id=g.state.enemies[0].id
 t.check(g.state.enemies[0].type=="drone" and g.state.enemies[0].intent.kind=="bind_apply" and g.Enemies.FirstFloor.candidates(g).any(func(m):return m.type=="drone"),"DRONE registered weak encounter opens with direct bind")
 var strike=t.find_action(g,"attack",{"type":"strike","enemy":id})
 var hp=g._enemy(id).hp
 t.check(g.dispatch(g.command(strike.payload,g.state.version),g.state.version).ok and g._enemy(id).hp==hp-strike.payload.damage*0.5,"DRONE hard halves physical damage through formal attack")
 g.state.sure_cast=true
 var fire=t.find_action(g,"attack",{"type":"fireball","enemy":id})
 hp=g._enemy(id).hp
 t.check(g.dispatch(g.command(fire.payload,g.state.version),g.state.version).ok and g._enemy(id).hp==hp-fire.payload.damage,"DRONE magic bypasses hard")

 g=Game.new(12,true,"drone_solo");id=g.state.enemies[0].id
 g.state.posture="sit"
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==30.0 and g.state.posture=="stand" and g.level("arms")>=1,"DRONE first action binds at thirty and fixes standing")
 t.check(not t.find_action(g,"posture",{"dest":"sit","wall":false}).valid,"DRONE fixed posture disables voluntary descent")
 var card=t.hand_card(g,"strain")
 var escape_damage=t.find_action(g,"card",{"uid":card.uid,"target":Bind.BIND_TARGET}).payload.preview.damage
 t.check(t.action(g,"card",{"uid":card.uid,"target":Bind.BIND_TARGET}).ok and g.state.guard_bind.sources.drone.energy==1 and g.state.pressure==0,"DRONE one energy is retained without guard-only effects")
 var saved=Save.roundtrip(t,g,"drone partial energy and announced action")
 var clean=g.export_snapshot()
 for invalid in [null,{"enemy":id,"energy":2},{"enemy":"missing","energy":0}]:
  var broken=clean.duplicate(true);broken.guard_bind.sources.drone=invalid
  t.check(not g.restore_snapshot(broken).ok and g.state==clean,"CAPTURE malformed source state rejects restore atomically")
 Save.step_both(t,g,saved,"attack",{"type":"strike","enemy":id})
 t.check(g.state.guard_bind.sources.drone.energy==0 and is_equal_approx(g.state.guard_bind.progress,40.0-escape_damage) and g.state.equipment.any(func(e):return e.source==id and e.grade==1 and g.tier(e.durability,e.maximum)==2),"DRONE second paid energy applies tier-two tape and advances shared bar")
 var before=g.export_snapshot()
 var version=g.state.version
 t.check(not g.dispatch(g.command(strike.payload,version-1),version-1).ok and g.state==before,"DRONE rejected stale action preserves capture counters and random state")
 g.CaptureBind.energy_spent(g,4)
 t.check(is_equal_approx(g.state.guard_bind.progress,60.0-escape_damage) and g.state.guard_bind.sources.drone.energy==0,"DRONE large payment triggers once for each two energy")
 var entry=g.get_view().statuses.filter(func(s):return s.id=="guard_bind")[0]
 t.check(entry.detail.contains("固定为站姿") and g.get_view().statuses.any(func(s):return s.id=="hard_"+id),"DRONE status projects its own capture effect and hard buff")

 # Both orderings use the NEW kind's initial value. Same-kind copies add nothing.
 for drone_first in [true,false]:
  g=Game.new(8,true,"drone_solo")
  var drone=g.state.enemies[0]
  var guard=g._append_enemies([{"type":"guard","grade":2}])[0]
  var first=drone if drone_first else guard
  var second=guard if drone_first else drone
  Bind.apply_bind(g,first);Bind.apply_bind(g,second)
  t.check(g.state.guard_bind.progress==(55.0 if drone_first else 65.0) and g.state.guard_bind.sources.size()==2,"CAPTURE incoming kind contributes half its own initial value "+str(drone_first))
  var duplicate=g._append_enemies([{"type":second.type,"grade":second.grade}])[0]
  var baseline=g.state.guard_bind.duplicate(true)
  Bind.apply_bind(g,second);Bind.apply_bind(g,duplicate)
  t.check(g.state.guard_bind==baseline and g.state.posture=="stand","CAPTURE repeated instance and another same-kind enemy never stack or reset counters")
  Bind.damage_bind(g,100,"测试")
  t.check(g.state.guard_bind.is_empty() and g._enemy(drone.id).intent.kind=="bind_apply","CAPTURE zero clears all source effects and energy counters")

 g=Game.new(15,true,"drone_solo");id=g.state.enemies[0].id
 t.action(g,"end")
 g.state.equipment.clear()
 var enemy=g._enemy(id);enemy.guard.cycle_step=0
 t.check(g.EnemyPlans.build(g,enemy).kind=="apply","DRONE no legal tape target excludes reinforcement at announcement")
 var tape=g._install_template("tape","wrist",4,10,false,"fixture")
 var rope=g._install_template("rope","ankle",4,10,false,"fixture")
 var original_rope=rope.duplicate(true)
 var tightened=false
 for seed_value in t.seed_values("enemy_cycle"):
  g.state.rng.enemy=seed_value
  var plan=g.EnemyPlans.build(g,enemy)
  if plan.kind=="tighten_budget":
   g._enemy_operation(enemy,plan);tightened=true;break
 t.check(tightened and g.tier(tape.durability,tape.maximum)==3 and rope==original_rope,"DRONE reinforcement spends two tiers only on tape, including twice on one piece")
 tape.durability=4.0
 var plan={"kind":"tighten_budget","budget":2,"text":"收紧胶带","delayed":false}
 g.state.equipment.erase(tape)
 var count=g.state.equipment.size()
 g._enemy_operation(enemy,plan)
 t.check(g.state.equipment.size()==count and rope==original_rope,"DRONE announced reinforcement whiffs when tape is removed")
 Bind.damage_bind(g,100,"测试")
 t.check(g._enemy(id).intent.kind=="bind_prepare","DRONE later bind requires preparation after escape")
 t.check(t.action(g,"end").ok and g._enemy(id).intent.kind=="bind_apply" and not Bind.has_bind(g),"DRONE preparation spends one enemy turn")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==30.0,"DRONE prepared reapplication restarts at thirty")
 g._enemy(id).guard.cycle_step=1;g._enemy(id).intent=g._plan(g._enemy(id))
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==40.0 and g._enemy(id).intent.kind=="idle","DRONE advance precedes idle")
 t.check(t.action(g,"end").ok and g._enemy(id).intent.kind in ["apply","tighten_budget"],"DRONE idle returns to tape action")

 # A later enemy must execute its previously announced action, not immediate arrest.
 g=Game.new(17,true,"drone_solo");enemy=g.state.enemies[0]
 var guard=g._append_enemies([{"type":"guard","grade":2}])[0]
 enemy.stage=4;guard.stage=4
 Bind.apply_bind(g,enemy);Bind.apply_bind(g,guard)
 g.state.guard_bind.progress=95.0
 enemy.guard.cycle_step=1;enemy.intent=g._plan(enemy)
 guard.guard.cycle_step=1;guard.intent=g._plan(guard)
 t.check(t.action(g,"end").ok and g.state.phase=="battle" and g.state.guard_bind.progress==100.0 and g.state.enemies.all(func(e):return e.intent.kind=="capture"),"CAPTURE reaching maximum during enemy phase announces arrest for following phase")
 t.check(t.action(g,"end").ok and g.state.phase=="captured" and g.state.capture.by==enemy.name,"CAPTURE drone executes the shared arrest pipeline next turn")

 g=Game.new(18,true,"drone_solo");enemy=g.state.enemies[0]
 Bind.apply_bind(g,enemy);enemy.hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":enemy.id}).ok and g.state.guard_bind.is_empty() and g.state.phase=="reward","DRONE defeated final source clears binding and rewards normally")
