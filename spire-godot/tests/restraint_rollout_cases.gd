extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const A=preload("res://core/equipment_application.gd")
const Events=preload("res://tests/event_cases.gd")

class PoolProbe extends Game:
 var draws=[]
 var pool_index=0
 func _random_index(domain: String, count: int) -> int:
  if domain!="enemy": return super._random_index(domain,count)
  draws.append(count)
  return mini(pool_index,count-1) if draws.size()==1 else 0

static func run(t) -> void:
 # Three ordinary profiles must not turn a two-pool choice into a 3:1 lottery.
 for selected in [0,1]:
  var g=PoolProbe.new(42)
  var spec={"pool":"ordinary","templates":["rope"],"composites":["glove"],"grade":2,"tier":2,"profiles":g.RestraintValue.profiles(4),"count":1,"variant":0}
  var before=g.export_snapshot();g.pool_index=selected;g.draws=[]
  t.check(A.can_apply(g,spec,"fixture") and g.draws.is_empty() and g.export_snapshot()==before,"ROLLOUT mixed legality reads without RNG or state mutation")
  var request=A.choose(g,spec,"fixture")
  t.check(not request.is_empty() and g.draws[0]==2 and (request.kind=="assembly")==bool(selected),"ROLLOUT ordinary/composite pool weight remains equal despite three ordinary profiles")
  if selected==1: t.check(request.grade==2 and request.tier==2,"ROLLOUT composite pool retains its fixed profile")
  else: t.check(request.grade+request.tier==4,"ROLLOUT ordinary pool selects within the value budget")
  t.check(A.execute_concrete(g,request,"fixture").ok and g.validate()=="","ROLLOUT selected mixed request installs through the formal factory")
 var g=Game.new(42)
 var spec=g.EnemyPlans.application(["rope"],2,2,1,false,4)
 for excluded in [g.Equipment.ANATOMY.duplicate(),["invalid_point"],"wrist"]:
  spec.excluded_points=excluded
  var before=g.export_snapshot()
  t.check(not A.can_apply(g,spec,"fixture") and not A.execute(g,spec,"fixture").ok and g.export_snapshot()==before,"ROLLOUT unavailable or malformed precise exclusion rejects without RNG or state changes")
 spec.erase("excluded_points");spec.free_slots=1
 var invalid_before=g.export_snapshot()
 t.check(not A.execute(g,spec,"fixture").ok and g.export_snapshot()==invalid_before,"ROLLOUT malformed free-slot restriction rejects atomically")
 spec.erase("free_slots")
 spec.excluded_points=["wrist","fingers_left","fingers_right"]
 var request=A.choose(g,spec,"fixture")
 t.check(not request.is_empty() and not g.EnemyPlans.positions(g,request).any(func(point):return point in spec.excluded_points),"ROLLOUT batch selection excludes used precise positions before random selection")
 for level in range(1,6):
  g=Game.new(42);g.state.security=level
  for intake in [false,true]:
   spec=g.Prison.equipment_spec(g,1,false,intake)
   var sum_value=g.B.PRISON_SECURITY[level].grade+(2 if intake and level<5 else g.B.PRISON_SECURITY[level].tier)
   t.check(spec.profiles.all(func(profile):return profile.grade+profile.tier==sum_value and (not intake or profile.tier>=2)),"ROLLOUT prison profile preserves budget and intake minimum tightness")
   var result=A.execute(g,spec,"fixture","prison")
   t.check(result.ok and g.validate()=="","ROLLOUT prison mixed budget executes a legal real installation")
 for seed_value in range(12):
  g=Game.new(seed_value)
  Events.arrive(g,"binding_cleric")
  var before=g.export_snapshot()
  var frozen=g.Events.freeze_effects(g,[{"op":"install_random","templates":["rope"],"count":2,"grade":2,"tier":2,"locked":false,"allow_links":false}])
  t.check(frozen.issue=="" and frozen.effects.size()==2 and frozen.effects.all(func(effect):return effect.grade+effect.tier==4),"ROLLOUT event freezes two concrete equal-budget profiles")
  t.check(g.state.equipment==before.equipment and g.state.rng.equipment==before.rng.equipment,"ROLLOUT freezing restores equipment and never draws a material variant")
  var rng=g.state.rng.duplicate(true)
  t.check(g.Events.apply_effects(g,frozen.effects,g.state.room_event.refs,false)=="" and g.state.rng.event==rng.event,"ROLLOUT committing frozen event effects never rerolls their profiles")
