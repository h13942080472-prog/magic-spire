extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const A=preload("res://core/equipment_application.gd")
const O=preload("res://core/equipment_offers.gd")
const E=preload("res://data/equipment.gd")

static func unchanged_replacement(t) -> void:
 var g=Game.new(42)
 var old=g._install_template("mouth_band","mouth",E.maximum(1)*0.8,E.maximum(1),false,"fixture",1,-1,0)
 var spec={"pool":"ordinary","templates":["mouth_band"],"grade":1,"tier":2,"count":1,"replace":true,"variant":0}
 var before=g.export_snapshot()
 t.check(not A.can_apply(g,spec,"another_enemy") and g.state==before,"APPLY identical fixed variant is unavailable without changing state or random counters")
 spec.erase("variant")
 t.check(A.can_apply(g,spec,"another_enemy") and g.state==before,"APPLY a genuinely different allowed variant remains available without a random draw")
 var result=A.execute(g,spec,"another_enemy")
 t.check(result.ok and g._equipment(old.id).is_empty() and g.state.equipment[0].variant!=0,"APPLY variant draw uses only legal replacements and cannot select the identical old copy")
 t.check(g.validate()=="","APPLY nonidentical variant replacement keeps the full state valid")

class LinkProbe extends Game:
 var anchor_queries=0
 func link_anchors() -> Array:
  anchor_queries+=1
  return super.link_anchors()

static func excluded_links(t) -> void:
 var g=LinkProbe.new(42)
 g.add_fixture("wrist",4)
 g._install_template("rope","forearm",4,10,false,"fixture",1,-1,0,"mid_forearm")
 var spec={"pool":"ordinary","templates":["rope"],"grade":1,"tier":2,"count":1}
 var before=g.export_snapshot()
 var all_choices=A._raw(g,spec,"fixture")
 t.check(not all_choices.any(func(p):return p.kind=="link"),"APPLY ordinary pool excludes links even with compatible anchors")
 var expected=all_choices.filter(func(p):return p.kind!="link")
 g.anchor_queries=0;spec.allow_links=false
 var actual=A._raw(g,spec,"fixture")
 t.check(actual==expected and g.state==before,"APPLY excluding links preserves every ordinary request, order and random state")
 t.check(g.anchor_queries==0,"APPLY explicitly excluded links never enumerate physical anchors")

# D16: the existence-only query must agree with the complete band enumeration.
# The short circuit may stop early, but the answered question stays the same.
static func existence_matches_full_bands(t) -> void:
 var g=Game.new(47)
 g._install_template("mouth_band","mouth",E.maximum(1)*0.8,E.maximum(1),false,"fixture",1,-1,0)
 var before=g.state.duplicate(true)
 var mixed={"pool":"ordinary","templates":["mouth_band"],"composites":[{"family":"glove","variant":"short","straps":"straight"}],"count":2,"grade":2,"tier":2,"replace":true,"variants":{"mouth_band":0}}
 var specs=[]
 specs.append({"pool":"ordinary","templates":["mouth_band"],"grade":1,"tier":2,"count":1,"replace":true,"variant":0,"profiles":[{"grade":1,"tier":1},{"grade":2,"tier":2}]})
 specs.append({"pool":"ordinary","templates":["mouth_band"],"grade":1,"tier":1,"count":1,"replace":true,"variant":0})
 specs.append({"pool":"ordinary","templates":["rope","cord"],"grade":2,"tier":2,"count":1,"replace":true})
 specs.append({"pool":"special","templates":["nipple_clamp_low"],"count":1,"replace":true})
 specs.append(mixed)
 for spec in specs:
  t.check(A.can_apply(g,spec,"another_enemy")==(not A._choice_bands(g,spec,"another_enemy").is_empty()),"APPLY existence query matches the full band enumeration: "+str(spec.get("templates",[])))
 t.check(A.can_apply(g,specs[0],"another_enemy"),"APPLY a later legal profile stays reachable through the short circuit")
 t.check(not A.can_apply(g,specs[1],"another_enemy"),"APPLY the weaker single profile is still refused")
 t.check(g.state==before,"APPLY existence query leaves state, ids, logs and random counters untouched")
 g=Game.new(51)
 var points={"upper_arm":["upper_arm_top","above_elbow"],"forearm":["below_elbow","mid_forearm"],"wrist":[""]}
 for slot in points:
  for point in points[slot]:
   for i in range(2): g._install_template("belt",slot,4,10,false,"fixture",1,-1,0,point)
 g._install_assembly("glove","short","fixture",2,1)
 var batch={"pool":"ordinary","templates":["tape"],"slots":["upper_arm","forearm","wrist"],"preferred_slots":["wrist"],"count":4,"grade":3,"tier":3,"replace":true,"variants":{"tape":0},"ready_layers":4}
 t.check(A.can_apply(g,batch,"fixture")==(not A._choice_bands(g,batch,"fixture").is_empty()) and not A.can_apply(g,batch,"fixture"),"APPLY an incomplete covering group is refused on both paths")
 batch.count=5;batch.ready_layers=5
 t.check(A.can_apply(g,batch,"fixture") and not A._choice_bands(g,batch,"fixture").is_empty(),"APPLY a complete covering group stays reachable through the short circuit")

# Counts calls per domain for fixture legibility only; call counts are deliberately
# not compared between paths (see _lazy_choose_matches).
class DrawProbe extends Game:
 var draws={}
 func _random_index(domain: String, count: int) -> int:
  draws[domain]=draws.get(domain,0)+1
  return super._random_index(domain,count)

# Pre-D16 reference: complete band enumeration, pools classified from band[0].kind,
# then the original per-level draws. Kept only as the oracle for the lazy path.
static func _complete_choose(g, spec: Dictionary, source: String, domain: String="enemy") -> Dictionary:
 var bands=A._choice_bands(g,spec,source,"full")
 if bands.is_empty(): return {}
 if not spec.get("composites",[]).is_empty() and spec.has("profiles"):
  var pools=[]
  for composite in [false,true]:
   var pool=bands.filter(func(band):return (band[0].kind=="assembly")==composite)
   if not pool.is_empty(): pools.append(pool)
  bands=pools[g._random_index(domain,pools.size())]
 var primary=bands[g._random_index(domain,bands.size())]
 if spec.get("pool","ordinary")=="ordinary":
  var families={}
  for request in primary:
   var family=E.generation_class(request.template) if request.has("template") else request.kind
   if not families.has(family): families[family]=[]
   families[family].append(request)
  primary=families[families.keys()[g._random_index(domain,families.size())]]
  var positions={}
  for request in primary:
   var position=JSON.stringify([request.kind,request.get("slot",""),request.get("point",""),request.get("ends",[]),request.get("contact_points",[]),request.get("target","")])
   if not positions.has(position): positions[position]=[]
   positions[position].append(request)
  primary=positions[positions.keys()[g._random_index(domain,positions.size())]]
 elif spec.get("pool","ordinary")=="special" and g.state.get("chastity_locks_enabled",false):
  var lock_choices=primary.filter(func(request):return g.SpecialEquipment.is_chastity_type(request.get("type","")))
  var toy_choices=primary.filter(func(request):return not g.SpecialEquipment.is_chastity_type(request.get("type","")))
  if not lock_choices.is_empty() and not toy_choices.is_empty():
   primary=lock_choices if g._random_index(domain,100)<int(g.state.get("chastity_lock_chance",25)) else toy_choices
  elif not lock_choices.is_empty(): primary=lock_choices
  else: primary=toy_choices
 var selected=primary[g._random_index(domain,primary.size())].duplicate(true)
 if selected.get("kind","")=="application_group":
  for request in selected.requests: A._freeze_variant(g,request)
 else: A._freeze_variant(g,selected)
 return selected

# The lazy band path only promises what survives its discarded trials: the chosen
# request, every LIVE rng counter, and the commit. Trial-local draws run on a state
# copy and may differ in count/order, so call counts are never compared.
static func _lazy_choose_matches(t,reference,lazy,spec: Dictionary,label: String) -> void:
 var before=reference.state.rng.duplicate(true)
 var expected=_complete_choose(reference,spec,"enemy")
 var actual=A.choose(lazy,spec,"enemy")
 t.check(actual==expected,"APPLY lazy band selection matches the complete path: "+label)
 var deltas_match=true
 for domain in reference.state.rng:
  if reference.state.rng[domain]-before[domain]!=lazy.state.rng[domain]-before[domain]: deltas_match=false
 t.check(deltas_match and reference.state.rng==lazy.state.rng,"APPLY lazy band path advances every live random domain exactly as the complete path: "+label)

static func _lazy_execute_matches(t,reference,lazy,spec: Dictionary,label: String) -> Dictionary:
 var expected=A.execute(reference,spec,"enemy")
 var actual=A.execute(lazy,spec,"enemy")
 t.check(actual.ok==expected.ok and actual.count==expected.count and actual.ready_used==expected.ready_used and actual.installed==expected.installed and actual.removed==expected.removed and actual.lost_links==expected.lost_links,"APPLY lazy band path commits the same execution result: "+label)
 t.check([lazy.state.equipment,lazy.state.composites,lazy.state.special_equipment,lazy.state.links]==[reference.state.equipment,reference.state.composites,reference.state.special_equipment,reference.state.links],"APPLY lazy band path leaves the same live equipment domain: "+label)
 return expected

# A full outer glove over two inner pieces at every arm point forces whole-group
# replacement trials; tier three makes every trial install draw on the binding domain.
static func _binding_trial_fixture(seed_value: int):
 var g=DrawProbe.new(seed_value,false,"equipment",true,true,100)
 var points={"upper_arm":["upper_arm_top","above_elbow"],"forearm":["below_elbow","mid_forearm"],"wrist":[""]}
 for slot in points:
  for point in points[slot]:
   for i in range(2): g._install_template("belt",slot,4,10,false,"fixture",1,-1,0,point)
 g._install_assembly("glove","short","fixture",2,1)
 return g

static func lazy_bands_match_complete_selection(t) -> void:
 var g=Game.new(42)
 var specs=[
  {"pool":"ordinary","templates":["rope","belt"],"grade":1,"tier":2,"count":1},
  {"pool":"ordinary","templates":["rope","belt"],"grade":2,"tier":1,"count":1,"preferred_slots":["mouth","eyes"]},
  {"pool":"ordinary","templates":["mouth_band"],"grade":1,"tier":1,"count":1,"variant":0},
  {"pool":"ordinary","templates":["rope"],"composites":["glove"],"grade":2,"tier":2,"profiles":g.RestraintValue.profiles(4),"count":1,"variant":0},
  {"pool":"ordinary","templates":["rope","belt"],"grade":2,"tier":2,"profiles":[{"grade":1,"tier":2},{"grade":2,"tier":2},{"grade":3,"tier":1}],"count":1},
  {"pool":"special","templates":["negative_plate_lock_medium","nipple_ring_medium"],"grade":2,"tier":2,"count":1,"replace":true}
 ]
 var labels=["ordinary","ordinary preferred","single band","mixed pools","multi band","special chance"]
 for i in range(specs.size()):
  var reference=DrawProbe.new(42,false,"equipment",true,true,100)
  var lazy=DrawProbe.new(42,false,"equipment",true,true,100)
  _lazy_choose_matches(t,reference,lazy,specs[i],labels[i])
  _lazy_execute_matches(t,reference,lazy,specs[i],labels[i])
 t.check(not specs.is_empty(),"APPLY lazy band comparison covers declared spec shapes")
 var body={"pool":"ordinary","templates":["tape"],"slots":["upper_arm","forearm","wrist"],"preferred_slots":["wrist"],"count":5,"grade":3,"tier":3,"replace":true,"variants":{"tape":0},"ready_layers":5}
 var reference=_binding_trial_fixture(51)
 var lazy=_binding_trial_fixture(51)
 var live_binding=lazy.state.rng.binding
 _lazy_choose_matches(t,reference,lazy,body,"binding trial draws")
 t.check(lazy.draws.get("binding",0)>0 and reference.draws.get("binding",0)>0,"APPLY the binding fixture really draws on the binding domain while choosing")
 t.check(lazy.state.rng.binding==live_binding and reference.state.rng.binding==live_binding,"APPLY binding trial draws stay in the discarded copy and never advance the live binding counter")
 var committed=_lazy_execute_matches(t,reference,lazy,body,"binding trial draws")
 t.check(committed.ok and committed.count==5 and lazy.state.composites.is_empty(),"APPLY the binding fixture commits a real five-piece covering replacement")

static func run(t) -> void:
 preload("res://tests/girl_sound_cases.gd").run(t)
 preload("res://tests/equipment_audio_cases.gd").run(t)
 preload("res://tests/restraint_rollout_cases.gd").run(t)
 unchanged_replacement(t)
 excluded_links(t)
 existence_matches_full_bands(t)
 lazy_bands_match_complete_selection(t)
 var materials={}
 for seed_value in t.seed_values("enemy_cycle"):
  var first=Game.new(seed_value);var second=Game.new(seed_value)
  var base={"pool":"ordinary","templates":["rope","belt"],"slot":"palm","grade":1,"tier":2,"count":1}
  var extended=base.duplicate(true);extended.templates=["rope","cord","belt"]
  var a=A.choose(first,base,"fixture");var b=A.choose(second,extended,"fixture")
  t.check(not a.is_empty() and not b.is_empty() and E.generation_class(a.template)==E.generation_class(b.template),"APPLY extra rope style does not change the material draw")
  materials[E.generation_class(b.template)]=true
 t.check(materials.size()==2,"APPLY material grouping keeps both permitted materials reachable")
 var g=Game.new(42)
 var before=g.state.duplicate(true)
 t.check(O.options(g).all(func(p):return p.kind in ["install","shoulder"]),"APPLY default offers never include assemblies")
 t.check(not O.assemblies(g).is_empty() and O.assemblies(g).all(func(p):return p.kind=="assembly"),"APPLY explicit composite generation pool")
 t.check(O.assemblies(g,2,["head"]).is_empty() and O.assemblies(g,1,["glove"]).is_empty(),"APPLY composite whitelist cannot expand generation or minimum grade")
 t.check(O.assemblies(g,2,[{"family":"glove","variant":"short","straps":"cross"}]).size()==1,"APPLY precise assembly whitelist")
 t.check(O.ordinary(g,2,false,["unknown","glove","special"]).is_empty() and g.state==before,"APPLY mixed invalid template lookup readonly")
 t.check(A.choose(g,{"kind":"apply","pool":"ordinary","templates":[]},"fixture").is_empty() and g.state==before,"APPLY empty ordinary source never widens or draws RNG")

 var spec={"kind":"apply","pool":"ordinary","templates":["belt","mouth_band","eye_leather"],"count":1,"grade":2,"tier":1,"preferred_slots":["mouth","eyes"],"variants":{"mouth_band":0}}
 var rng=g.state.rng.equipment
 var chosen=A.choose(g,spec,"fixture")
 t.check(chosen.get("slot","")=="mouth" and chosen.get("variant",-1)==0 and g.state.rng.equipment==rng,"APPLY preferred mouth and explicit harness variant do not draw material RNG")
 var resources=_resources(g)
 var result=A.execute(g,spec,"fixture")
 t.check(result.ok and result.count==1 and result.installed[0].template=="mouth_band" and result.installed[0].variant==0 and g.state.composites.is_empty(),"APPLY medium harness ball remains one ordinary root")
 t.check(_resources(g)==resources,"APPLY helper does not spend player resources or advance turns")
 spec.templates=["mouth_band"];spec.fallback_templates=["eye_leather"];spec.ready_layers=2;spec.count=4
 result=A.execute(g,spec,"fixture")
 t.check(result.count==2 and result.ready_used==2 and result.installed.all(func(e):return e.slot=="eyes"),"APPLY fallback respects two shared eye slots; failed surplus spends no readiness")
 t.check(result.installed.all(func(e):return g.tier(e.durability,e.maximum)==3),"APPLY readiness evaluated separately for each actual installation")

 g=Game.new(43)
 result=A.execute(g,{"pool":"ordinary","templates":["rope"],"count":1,"grade":2,"tier":2,"locked":true,"fallback_templates":["mouth_band"],"variants":{"mouth_band":0}},"fixture")
 t.check(result.count==1 and result.installed[0].locked and result.installed[0].template=="mouth_band","APPLY required lock cannot silently disappear during fallback")
 before=g.state.duplicate(true)
 result=A.execute_concrete(g,{"kind":"install","template":"mouth_band","slot":"mouth","grade":2,"tier":3,"variant":0},"event:fixture")
 t.check(not result.ok and g.state==before and result.reason!="","APPLY frozen concrete occupied target fails without retargeting")

 g=Game.new(44)
 result=A.execute(g,{"pool":"composite","templates":[{"family":"glove","variant":"short","straps":"straight"}],"count":1,"grade":2,"tier":2,"locked":true},"fixture")
 t.check(result.ok and result.count==1 and result.installed[0].components.size()==3 and result.installed[0].components.all(func(e):return e.locked),"APPLY composite installs real root through original assembly factory")

 g=Game.new(45)
 result=A.execute(g,{"pool":"special","templates":["nipple_clamp_low"],"count":2,"grade":3,"tier":3,"ready_layers":1},"fixture")
 t.check(result.ok and result.count==1 and result.installed[0].grade==1 and result.ready_used==1,"APPLY special design keeps its own grade and one family limit")
 before=g.state.duplicate(true)
 result=A.execute(g,{"pool":"special","templates":["nipple_clamp_low"],"count":1,"locked":true,"replace":true},"fixture")
 t.check(not result.ok and g.state==before,"APPLY replacement authorization does not grant special locking or replacement")

 g=Game.new(46)
 g._install_template("rope","forearm",8,10,false,"fixture",1,-1,0,"mid_forearm")
 g.add_fixture("wrist",8)
 result=A.execute(g,{"pool":"ordinary","templates":["link_rope"],"count":1,"grade":2,"tier":2},"fixture")
 t.check(not result.ok and result.count==0 and g.state.links.is_empty(),"APPLY retired link source produces no equipment")
 _replacement_cases(t)
 _batch_cases(t)
 _mixed_pool_cases(t)
 _enemy_commit_cases(t)
 g=Game.new(54)
 g._install_template("rope","upper_arm",8,10,false,"fixture",1,-1,0,"upper_arm_top")
 result=A.execute(g,{"pool":"ordinary","templates":["rope"],"count":1,"grade":2,"tier":2,"slot":"shoulder","shoulders":true},"fixture")
 t.check(result.ok and result.count==1 and result.installed.size()==2 and result.installed.all(func(item):return E.is_shoulder(item)),"APPLY one declared shoulder-pair operation keeps both real components without consuming two operations")

static func _mixed_pool_cases(t) -> void:
 var spec={"pool":"ordinary","templates":["mouth_band"],"composites":[{"family":"glove","variant":"short","straps":"straight"}],"grade":2,"tier":2,"count":2,"replace":true}
 var seen={}
 for seed_value in [0,1,7,15]:
  var g=Game.new(seed_value)
  var before=g.state.duplicate(true)
  t.check(A.can_apply(g,spec,"fixture") and g.state==before,"APPLY mixed legality query never draws randomness or installs")
  var chosen=A.choose(g,spec,"fixture")
  seen[chosen.kind]=true
 t.check(seen.has("install") and seen.has("assembly"),"APPLY both explicitly permitted pools remain reachable")
 var g=Game.new(42)
 var old=g._install_template("mouth_band","mouth",4,10,false,"fixture")
 var paired=spec.duplicate(true)
 paired.composites.append({"family":"leg","variant":"upper","straps":"straight"})
 var result=A.execute(g,paired,"fixture")
 t.check(result.count==2 and result.installed.all(func(e):return e.has("components")) and not g._equipment(old.id).is_empty(),"APPLY free composite positions take priority over replacing an occupied ordinary position")
 t.check(result.installed.map(func(e):return e.id)==g.state.composites.map(func(e):return e.id) and g.validate()=="","APPLY two composite roots consume two quotas and remain intact in one batch")
 g=Game.new(43)
 g._install_assembly("jacket","standard","fixture",3,3)
 result=A.execute(g,spec,"fixture")
 t.check(result.count==1 and result.installed[0].template=="mouth_band" and result.removed.is_empty(),"APPLY unavailable composite pool falls back to ordinary without bypassing closure or recycling the new item")
 var before=g.state.duplicate(true)
 var invalid=spec.duplicate(true);invalid.pool="special"
 t.check(not A.execute(g,invalid,"fixture").ok and g.state==before,"APPLY composite inclusion cannot silently expand a special source")

static func _enemy_commit_cases(t) -> void:
 var Save=preload("res://tests/persistence_cases.gd")
 for human in [true,false]:
  var g=Game.new(42,true,"guard") if human else Game.new(42)
  if not human:
   g.state.room_encounters.entrance="rope_solo";g._start_battle()
  var e=g.state.enemies[0]
  for i in range(g._capacity("wrist")): g._install_template("rope","wrist",4,10,false,"fixture")
  var old=g.state.equipment.map(func(item):return item.id)
  var intent=g.EnemyPlans.application(["rope"],2,2)
  intent.slot="wrist";intent.replace=true
  e.intent={"kind":"guard_sequence","operations":[intent],"priority":false,"text":"施加装备","delayed":false} if human else intent
  var h=Save.roundtrip(t,g,"application source permission")
  Save.step_both(t,g,h,"end")
  var installed=g.state.equipment.filter(func(item):return item.id not in old)
  t.check(g.state.equipment.size()==old.size() and installed.size()==(1 if human else 0),"APPLY real enemy turn enforces humanoid replacement permission")
  t.check(g._enemy(e.id).stage==2 and g.validate()=="","APPLY replacement commit preserves enemy stage and valid state")
  if human:
   t.check(g.state.logs.any(func(l):return l.data.get("enemy_action",{}).get("slots",[])==["wrist"] and l.data.get("equipment","")==installed[0].id),"APPLY feedback reports actual replacement location and item")

 var g=Game.new(53)
 var old=g._install_special("vaginal_egg_low","special_3_a")
 var result=A.execute(g,{"pool":"special","templates":["external_wand_low"],"replace":true},"event:fixture")
 t.check(result.ok and result.removed==[old.id] and g.validate()=="","APPLY explicitly permitted special replacement preserves its own capacity and method rules")

static func _resources(g) -> Dictionary:
 var result={}
 for key in ["energy","mana","health","round","phase","version","pressure"]:
  if g.state.has(key): result[key]=g.state[key]
 return result

static func _replacement_cases(t) -> void:
 var g=Game.new(47)
 var old=g._install_template("mouth_band","mouth",4,10,false,"fixture",1,-1,0)
 var before=g.state.duplicate(true)
 var request={"kind":"install","template":"mouth_band","slot":"mouth","grade":2,"tier":2,"variant":0}
 t.check(not A.execute_concrete(g,request,"fixture").ok and g.state==before,"APPLY replacement requires explicit authorization")
 var spec={"pool":"ordinary","templates":["mouth_band"],"grade":2,"tier":2,"replace":true,"variants":{"mouth_band":0}}
 var chosen=A.choose(g,spec,"fixture")
 t.check(not chosen.is_empty() and g.state.equipment.size()==1 and g.state.equipment[0].id==old.id,"APPLY replacement selection does not remove old equipment")
 var result=A.execute_concrete(g,request,"fixture",true)
 t.check(result.ok and result.count==1 and old.id in result.removed and result.installed[0] is Dictionary,"APPLY authorized concrete replacement returns actual item and removed IDs")
 t.check(g.validate()=="","APPLY replacement result passes original invariant validation")

 g=Game.new(48)
 old=g._install_template("mouth_band","mouth",4,10,false,"fixture",1,-1,0)
 spec={"pool":"ordinary","templates":["mouth_band","belt"],"fallback_templates":["eye_leather"],"preferred_slots":["mouth","eyes"],"grade":2,"tier":2,"replace":true,"variants":{"mouth_band":0}}
 var rng=g.state.rng.duplicate(true)
 chosen=A.choose(g,spec,"fixture")
 t.check(chosen.get("slot","")=="mouth" and g.state.rng.equipment==rng.equipment,"APPLY preferred mouth replacement precedes other slots and fallback")
 var live_enemy=g.state.enemies[0]
 live_enemy.ready_layers=4
 result=A.execute(g,spec,"fixture")
 live_enemy.ready_layers=3
 t.check(result.ok and old.id in result.removed and g.state.enemies[0].ready_layers==3,"APPLY replacement preserves live enemy references held by Game")

 g=Game.new(49)
 old=g._install_template("mouth_band","mouth",E.maximum(3),E.maximum(3),true,"fixture",3,-1,0)
 before=g.state.duplicate(true)
 chosen=A.choose(g,{"pool":"ordinary","templates":["mouth_band"],"grade":1,"tier":1,"replace":true},"fixture")
 t.check(chosen.is_empty() and g.state==before,"APPLY failed replacement probes preserve state, logs, IDs and every RNG domain")

static func _batch_cases(t) -> void:
 var g=Game.new(50)
 var spec={"pool":"ordinary","templates":["eye_leather"],"count":2,"grade":2,"tier":1,"tiers":[2,3],"variants":{"eye_leather":0}}
 var result=A.execute(g,spec,"fixture")
 t.check(result.count==2 and result.ready_used==0 and g.tier(result.installed[0].durability,result.installed[0].maximum)==2 and g.tier(result.installed[1].durability,result.installed[1].maximum)==3,"APPLY explicit per-item tiers remain ordered")
 var before=g.state.duplicate(true)
 t.check(A.choose(g,{"pool":"ordinary","templates":["belt"],"count":0},"fixture").is_empty() and g.state==before,"APPLY empty batch does not select or draw RNG")

 # The short glove has five real points; two inner ordinary pieces at each point
 # make the glove itself the only removable outer object. A full five-item group
 # must be planned before a single new wrist/body item can be installed.
 g=Game.new(51)
 var points={"upper_arm":["upper_arm_top","above_elbow"],"forearm":["below_elbow","mid_forearm"],"wrist":[""]}
 for slot in points:
  for point in points[slot]:
   for i in range(2): g._install_template("belt",slot,4,10,false,"fixture",1,-1,0,point)
 var root=g._install_assembly("glove","short","fixture",2,1)
 t.check(not root.is_empty(),"APPLY complete-coverage fixture creates a real outer composite")
 before=g.state.duplicate(true)
 # Tape isolates whole-cover replacement; rope/belt sources now use legal links first.
 spec={"pool":"ordinary","templates":["tape"],"slots":["upper_arm","forearm","wrist"],"preferred_slots":["wrist"],"count":4,"grade":3,"tier":3,"replace":true,"variants":{"tape":0},"ready_layers":4}
 result=A.execute(g,spec,"fixture")
 t.check(not result.ok and result.ready_used==0 and g.state==before,"APPLY insufficient covering batch cannot remove or partially install over old composite")
 spec.count=5;spec.ready_layers=5
 result=A.execute(g,spec,"fixture")
 t.check(result.ok and result.count==5 and result.ready_used==5 and g._composite(root.id).is_empty(),"APPLY full covering batch replaces old composite in one atomic plan")
 t.check(g.validate()=="","APPLY complete covering batch leaves valid physical structures")

 # A complete medium batch still cannot beat the real upper-arm value while
 # two attached straps would be lost. Check before expanding all material pairs.
 g=Game.new(56)
 for slot in points:
  for point in points[slot]:
   for i in range(2): g._install_template("belt",slot,4,10,false,"fixture",1,-1,0,point)
 root=g._install_assembly("glove","short","fixture",2,2)
 spec={"pool":"ordinary","templates":["tape"],"slots":["upper_arm","forearm","wrist"],"count":5,"grade":2,"tier":3,"replace":true}
 before=g.state.duplicate(true)
 result=A.execute(g,spec,"prison")
 t.check(not result.ok and g.state==before,"APPLY complete coverage still respects component strength and unavoidable shoulder loss without partial removals")

 g=Game.new(55)
 var old=g._install_template("mouth_tape","mouth",4,10,false,"fixture")
 result=A.execute(g,{"pool":"ordinary","templates":["mouth_tape"],"grade":2,"tier":3,"count":3,"replace":true},"prison")
 t.check(result.count==2 and result.removed==[old.id] and result.installed.size()==2 and result.installed.all(func(item):return not g._equipment(item.id).is_empty()) and g.equipment_at("mouth").size()==2,"APPLY tape fills the second mouth slot then replaces only the old item; new batch items remain protected")

 # Explicit grouping is also available to frozen events; a bad last request must
 # not leave the first install behind even when its target was originally empty.
 g=Game.new(52)
 before=g.state.duplicate(true)
 var requests=[{"kind":"install","template":"belt","slot":"wrist","grade":2,"tier":2,"variant":0},{"kind":"install","template":"mouth_band","slot":"ankle","grade":2,"tier":2,"variant":0}]
 result=A.execute_concrete(g,{"kind":"application_group","requests":requests},"event:fixture",true)
 t.check(not result.ok and g.state==before,"APPLY frozen atomic group rejects invalid last request without partial installation")
