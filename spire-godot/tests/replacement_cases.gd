extends RefCounted

const Replacement=preload("res://core/equipment_replacement.gd")
const Game=preload("res://tests/game_fixture.gd")
const A=preload("res://core/equipment_application.gd")
const E=preload("res://data/equipment.gd")

# Observe full assembly trials through the original factory, without a timing limit.
class DenseProbe extends Game:
 var anchor_queries=0
 func link_anchors() -> Array:
  anchor_queries+=1
  return super.link_anchors()
 var assembly_calls=0
 func _install_assembly(kind: String, variant: String, source: String, grade: int=2, tightness: int=2, overrides: Dictionary={}, straps: String="straight", attached_to: String="") -> Dictionary:
  assembly_calls+=1
  return super._install_assembly(kind,variant,source,grade,tightness,overrides,straps,attached_to)

# Fail after the real factory has changed equipment, IDs and its random stream.
class SpecialFailureProbe extends Game:
 var reject_special=false
 func _install_special(type: String, slot: String, tightness: int=0) -> Dictionary:
  var item=super._install_special(type,slot,tightness)
  if reject_special:
   _random_index("equipment",2)
   return {}
  return item

static func forced_special_boundaries(t) -> void:
 var g=Game.new(42)
 var plate=g._install_special("negative_plate_lock_medium","special_2_a",3)
 var old_ids=g.state.special_equipment.map(func(item):return item.id)
 t.check(not plate.is_empty() and old_ids.size()==2,"REPLACEMENT forced fixture has a real root and attached reinforcement")
 var original=g.state;var enemies=g.state.enemies;var enemy=g.state.enemies[0];var rng=g.state.rng;var hand=g.state.hand
 var before=g.export_snapshot()
 var result=Replacement.force_special(g,"urethral_full_cup_medium",3,"fixture")
 t.check(result.ok and result.removed.size()==old_ids.size() and old_ids.all(func(id):return id in result.removed) and old_ids.all(func(id):return g._equipment(id).is_empty()),"REPLACEMENT forced result reports every removed physical root and attached component")
 t.check(result.installed.size()==1 and result.installed[0].type=="urethral_full_cup_medium" and g.validate()=="","REPLACEMENT forced commit uses the normal factory and valid dependent structure")
 t.check(is_same(g.state,original) and is_same(g.state.enemies,enemies) and is_same(g.state.enemies[0],enemy) and is_same(g.state.rng,rng) and is_same(g.state.hand,hand),"REPLACEMENT forced commit preserves unchanged enclosing references")
 t.check(g.state.version==before.version and g.state.energy==before.energy and g.state.mana==before.mana and g.state.tick==before.tick,"REPLACEMENT forced commit does not own enclosing payment version or turn")
 var settled=g.export_snapshot()
 result.installed[0].durability=999;result.removed.clear()
 t.check(g.state==settled,"REPLACEMENT forced result contains no authoritative mutable equipment")
 g=Game.new(42);g.RelicEffects.gain(g,"cursed_plate_lock");before=g.export_snapshot()
 result=Replacement.force_special(g,"urethral_full_cup_medium",3,"fixture")
 t.check(not result.ok and result.reason==g.SpecialEquipment.CURSED_PLATE_REASON and g.state==before,"REPLACEMENT forced permission cannot remove a cursed plate")
 g=Game.new(42)
 var rope=g._install_special("crotch_rope_low","special_3_a")
 var wrist=g.add_fixture("wrist",8)
 var link=g._install_link(rope.id,wrist.id,4.8,"fixture")
 t.check(not link.is_empty() and g.validate()=="","REPLACEMENT forced loss fixture has a legal special-to-wrist link")
 result=Replacement.force_special(g,"vaginal_egg_low",2,"fixture")
 t.check(result.ok and result.removed==[rope.id] and result.lost_links==[link.id] and g.state.links.is_empty(),"REPLACEMENT forced result separates removed special roots from detached links")
 t.check(g._equipment(wrist.id)==wrist and g.validate()=="","REPLACEMENT forced link cleanup preserves its unrelated live endpoint")
 g=SpecialFailureProbe.new(42)
 g._install_special("negative_plate_lock_medium","special_2_a",3)
 g._resource_feedback=preload("res://core/resource_feedback.gd").new();g._resource_feedback.capture(g.state)
 var recorder=g._resource_feedback;var events=recorder.events.duplicate(true)
 original=g.state;before=g.export_snapshot();g.reject_special=true
 result=Replacement.force_special(g,"urethral_full_cup_medium",3,"fixture")
 t.check(not result.ok and is_same(g.state,original) and g.state==before,"REPLACEMENT forced late factory failure restores equipment IDs random state and logs atomically")
 t.check(is_same(g._resource_feedback,recorder) and recorder.events==events,"REPLACEMENT forced failure restores the enclosing feedback collector without preview pulses")

static func impossible_dense_replacement(t) -> void:
 var g=DenseProbe.new(42)
 for slot in ["upper_arm","forearm","wrist","palm","fingers"]:
  for point in g.Equipment.SEGMENTS.get(slot,[slot]):
   t.check(fill(g,point,3,2).all(func(item):return not item.is_empty()),"REPLACEMENT dense fixture fills legal outer positions with stronger equipment")
 t.check(g.validate()=="","REPLACEMENT dense fixture is a valid current state")
 var before=g.state.duplicate(true)
 g.assembly_calls=0
 var spec=glove();spec.variant="long"
 var p=Replacement.plan(g,[spec],"fixture")
 t.check(not p.ok and g.state==before,"REPLACEMENT impossible dense majority rejects atomically without changing equipment, random counters or logs")
 t.check(g.assembly_calls<=2,"REPLACEMENT proven impossible comparison stops after direct attempt and geometry prototype, before combinatorial full trials")

static func equal_cost_dense_replacement(t) -> void:
 var g=DenseProbe.new(42)
 for slot in ["upper_arm","forearm","wrist","palm","fingers"]:
  for point in g.Equipment.SEGMENTS.get(slot,[slot]):
   t.check(fill(g,point,1,1).all(func(item):return not item.is_empty()),"REPLACEMENT dense weak fixture fills actual outer capacity")
 var before=g.state.duplicate(true)
 g.assembly_calls=0
 var spec=glove();spec.variant="long"
 var p=Replacement.plan(g,[spec],"fixture")
 t.check(p.ok and g.state==before,"REPLACEMENT dense weak equipment admits a complete read-only replacement plan")
 t.check(g.assembly_calls<=3,"REPLACEMENT equal-cost sets cannot improve the first valid plan and do not repeat full trials")
 t.check(Replacement.execute(g,p).ok and g.validate()=="","REPLACEMENT bounded search still commits through the full atomic replacement checks")

static func equivalent_link_transfers(t) -> void:
 var g=Game.new(42)
 var old=install(g,request("wrist"))
 var upper=install(g,request("forearm",1,2,"mid_forearm"))
 var link=g._install_link(old.id,upper.id,4.8,"fixture",1,[],["wrist","forearm"],["wrist","mid_forearm"])
 t.check(not link.is_empty(),"REPLACEMENT transfer fixture starts with a real link")
 g.state.links.clear();g.state.equipment.erase(old)
 var first=install(g,request("wrist"))
 var second=install(g,request("wrist"))
 var before=g.state.duplicate(true)
 var choices=Replacement._transfer(g,[link],[first,second])
 t.check(choices.size()==1 and choices[0].lost.is_empty() and choices[0].kept[0].ends==[first.id,upper.id],"REPLACEMENT equivalent complete transfers keep the first valid assignment without duplicating loss-free results")
 t.check(g.state==before,"REPLACEMENT transfer search leaves actual links and equipment unchanged")

static func partially_lost_transfers(t) -> void:
 var g=DenseProbe.new(42)
 var wrist=install(g,request("wrist"))
 var upper=install(g,request("forearm",1,2,"mid_forearm"))
 var palm=install(g,request("palm"))
 var ankle=install(g,request("ankle"))
 var foot=install(g,request("foot"))
 var links=[g._install_link(upper.id,wrist.id,4.8,"fixture",1,[],["forearm","wrist"],["mid_forearm","wrist"]),g._install_link(wrist.id,palm.id,4.8,"fixture",1,[],["wrist","palm"],["wrist","palm_left"]),g._install_link(ankle.id,foot.id,4.8,"fixture",1,[],["ankle","foot"],["ankle","foot"])]
 t.check(links.all(func(link):return not link.is_empty()) and g.validate()=="","REPLACEMENT partial transfer fixture has three legal links")
 if links.any(func(link):return link.is_empty()): return
 g.state.links.clear();g.state.equipment.erase(wrist);g.state.equipment.erase(ankle)
 var anchors=[]
 for i in range(3): anchors.append(install(g,request("wrist")))
 var before=g.state.duplicate(true)
 g.anchor_queries=0
 var choices=Replacement._transfer(g,links,anchors)
 var queries=g.anchor_queries
 t.check(choices.size()==1 and choices[0].lost==[links[2].id] and choices[0].kept.map(func(link):return link.id)==[links[0].id,links[1].id],"REPLACEMENT unavailable ankle endpoint loses only that link and retains both wrist directions")
 t.check(choices[0].kept[0].ends[1]==anchors[0].id and choices[0].kept[1].ends[0]==anchors[0].id,"REPLACEMENT partial transfer keeps the original first valid endpoint assignment")
 t.check(queries<=12,"REPLACEMENT inevitable loss prunes repeated equivalent endpoint branches; anchor queries="+str(queries))
 t.check(g.state==before,"REPLACEMENT partial transfer search preserves state and random counters")

static func request(slot: String, grade: int=1, tier: int=2, point: String="", locked: bool=false) -> Dictionary:
 return {"kind":"install","template":"fine_belt" if slot in ["palm","fingers","foot","toes"] else ("mouth_band" if slot=="mouth" else "rope"),"slot":slot,"point":point,"grade":grade,"tier":tier,"locked":locked,"variant":0}

static func install(g, spec: Dictionary) -> Dictionary:
 var maximum=g.Equipment.maximum(spec.grade)
 return g._install_template(spec.template,spec.slot,maximum*[0.0,0.4,0.8,1.0][spec.tier],maximum,spec.locked,"fixture",spec.grade,-1,spec.variant,spec.point)

static func fill(g, point: String, grade: int=1, tier: int=1) -> Array:
 var result=[]
 var slot=g.Links.point_slot(point)
 for i in range(g._capacity(slot)):
  var spec=request(slot,grade,tier,point)
  if slot=="mouth" and i>0: spec.template="mouth_tape"
  result.append(install(g,spec))
 return result

static func glove() -> Dictionary:
 return {"kind":"assembly","family":"glove","variant":"short","grade":2,"tier":2,"straps":"straight"}

static func full_glove():
 var g=Game.new(42)
 for point in ["upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist"]:
  for i in range(2): install(g,request(g.Links.point_slot(point),1,1,point))
 g._install_assembly("glove","short","fixture",2,1,{},"straight")
 return g

static func glove_singles(g) -> Array:
 var result=[]
 for point in ["upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist"]:
  var spec=request(g.Links.point_slot(point),3,3,point,true)
  spec.template="belt"
  result.append(spec)
 return result

static func unchanged(t, g, specs: Array, label: String) -> Dictionary:
 var before=g.state.duplicate(true)
 var recorder=g._resource_feedback
 var p=Replacement.plan(g,specs,"fixture")
 t.check(g.state==before and g._resource_feedback==recorder,"REPLACEMENT pure preview: "+label)
 return p

# D16: the cheap removal floor may only reject requests the full plan also
# rejects; equal values, a cheaper occupant, free capacity and composite
# requests stay admitted.
static func removal_floor_is_necessary(t) -> void:
 var g=Game.new(42)
 var pieces=fill(g,"mouth",3,3)
 var point=g._installation_points("mouth","")[0]
 var limit=g.Equipment.capacity("mouth","mouth_band")
 t.check(pieces.size()>0 and g._capacity_point_count(point)>=limit and not pieces.any(func(piece):return piece.is_empty()),"REPLACEMENT floor fixture fills the real mouth capacity")
 var weak=request("mouth",1,1)
 var floor=Replacement.removal_floor(g,[weak])
 t.check(Replacement.removal_floor_rejects(g,weak,floor),"REPLACEMENT floor rejects a weaker single install at a full point")
 t.check(not Replacement.plan(g,[weak],"fixture").ok,"REPLACEMENT floor never rejects a request the full plan accepts")
 var equal={point:Replacement.replacement_value(g,weak)}
 t.check(not Replacement.removal_floor_rejects(g,weak,equal),"REPLACEMENT floor admits an equal value")
 g=Game.new(42)
 var free=request("mouth",1,1)
 t.check(not Replacement.removal_floor_rejects(g,free,Replacement.removal_floor(g,[free])),"REPLACEMENT floor skips points that still have capacity")
 t.check(not Replacement.removal_floor_rejects(g,glove(),Replacement.removal_floor(g,[glove()])),"REPLACEMENT floor never screens composite requests")
 # Every rejection in a mixed ordinary batch must be a request the full plan
 # refuses; a dropped request would otherwise change the legal choice set.
 g=Game.new(42)
 var slot=g.Links.point_slot("mid_forearm")
 for i in range(g._capacity(slot)): install(g,request(slot,3,3,"mid_forearm"))
 var batch=[request(slot,1,1,"mid_forearm"),request(slot,2,2,"mid_forearm"),request(slot,3,3,"mid_forearm")]
 var mixed=Replacement.removal_floor(g,batch)
 var rejected=batch.filter(func(request):return Replacement.removal_floor_rejects(g,request,mixed))
 t.check(not rejected.is_empty(),"REPLACEMENT floor sweep has at least one real rejection")
 t.check(rejected.all(func(request):return not Replacement.plan(g,[request],"fixture").ok),"REPLACEMENT floor sweep rejects only requests the full plan refuses")

# D16: a trial writes into a draft log array and _after keeps those entries, so
# previews never touch the live log while the commit carries the same wording.
static func trial_log_isolation(t) -> void:
 var g=Game.new(42)
 var old=install(g,request("mouth",1,1))
 g.state.logs.append({"kind":"event","text":"既有日志","round":1,"phase":"battle","data":{}})
 var live=g.state.logs
 var live_size=live.size()
 var before=g.state.duplicate(true)
 var p=Replacement.plan(g,[request("mouth",3,3)],"fixture")
 t.check(p.ok and p.removed==[old.id],"REPLACEMENT log isolation fixture removes one real piece through the plan")
 t.check(g.state==before and is_same(g.state.logs,live),"REPLACEMENT preview keeps the live log array and its entries untouched")
 t.check(p._after.logs.size()>live_size and p._after.logs.slice(0,live_size)==g.state.logs,"REPLACEMENT trial draft extends the live log instead of replacing it")
 t.check(not is_same(p._after.logs,g.state.logs),"REPLACEMENT trial draft owns its own log array")
 Replacement.execute(g,p)
 t.check(g.state.logs.size()>=p._after.logs.size() and g.state.logs.slice(0,p._after.logs.size())==p._after.logs,"REPLACEMENT commit carries the trial draft wording unchanged")
 t.check(g.state.logs.filter(func(row):return str(row.get("text","")).contains("已解除")).size()==1,"REPLACEMENT removal wording is committed exactly once")

# D16 hardening: the cheap removal floor may only drop candidates whose complete
# _replacement_plan also fails. The corpus is built by the real factories and the
# real enemy-turn spec builders over seeded whole-body positions: fully bound,
# near-full, composite, links with shoulders, specials with chastity locks,
# shackles, and rope-art sealed ropes, across grade/tier combinations.
static func floor_prescreen_matches_full_plan(t) -> void:
 var rows=floor_corpus()
 var tally={"screened":0,"plans":0,"violations":[],"dirty":[]}
 for row in rows:
  var g=row.g
  var before=g.state.duplicate(true)
  for spec in floor_specs(g,row.slot):
   for profile in spec.get("profiles",[{}]):
    var current=spec.duplicate(true)
    current.merge(profile,true)
    _floor_band(g,current,tally)
  if g.state!=before: tally.dirty.append(row.name)
 var names=rows.map(func(row):return row.name)
 t.check(rows.size()==7 and names.size()==7 and rows.all(func(row):return row.g._capacity_issue(row.g.physical_pieces())==""),"REPLACEMENT floor corpus builds seven valid real-entry positions: "+str(names))
 t.check(tally.screened>0,"REPLACEMENT floor corpus screens real candidates: "+str(tally.screened))
 t.check(tally.plans>0 and tally.violations.is_empty(),"REPLACEMENT floor screens only candidates the full plan refuses: "+str(tally.violations))
 t.check(tally.dirty.is_empty(),"REPLACEMENT floor corpus plans and queries without changing any position: "+str(tally.dirty))
 # Rope-art seal: sealed ropes are not removable, so the floor must be the cheapest
 # unsealed value. A value-5 request is then screened and refused; admitting it in
 # the floor would require the sealed rope's value 4.
 var sealed=rows.filter(func(row):return row.name=="rope-art-seal")[0].g
 var value_five={"kind":"install","template":"rope","slot":"wrist","point":"","grade":2,"tier":3,"locked":false,"variant":0}
 var sealed_floor=Replacement.removal_floor(sealed,[value_five])
 t.check(Replacement.removal_floor_rejects(sealed,value_five,sealed_floor),"REPLACEMENT sealed ropes are excluded from the floor so a value-5 request is screened: "+str(sealed_floor))
 t.check(not Replacement.plan(sealed,[value_five],"fixture").ok,"REPLACEMENT sealed ropes never let a screened value-5 request complete")

# Full body saturation through the real factories: every anatomy point to its real
# capacity, all special slots, then links until no real link candidate installs.
static func _floor_saturate(g, grade: int, tier: int) -> void:
 var maximum=E.maximum(grade)
 for point in E.ANATOMY:
  var slot=g.Links.point_slot(point)
  var limit=E.capacity(slot,E.default_template(slot))
  var guard=0
  while g._capacity_point_count(point)<limit and guard<8:
   guard+=1
   var template=E.default_template(slot)
   if slot=="eyes" and g._capacity_point_count(point)>0: template="eye_tape"
   if slot=="mouth" and g._capacity_point_count(point)>0: template="mouth_tape"
   if g._install_template(template,slot,maximum*[0.0,0.4,0.8,1.0][tier],maximum,false,"fixture",grade,-1,0,point).is_empty(): break
 for i in range(40):
  var toys=A.execute(g,{"pool":"special","templates":g.SpecialEquipment.DESIGNS.keys(),"count":1,"replace":false},"fixture")
  if not toys.ok or toys.count==0: break
 _floor_links(g)

static func _floor_links(g) -> void:
 for i in range(200):
  var link=A.execute(g,{"pool":"ordinary","templates":["link_rope"],"grade":2,"tier":2,"count":1,"replace":false},"fixture")
  if not link.ok or link.count==0: break

static func floor_corpus() -> Array:
 var rows=[]
 var g=Game.new(42)
 _floor_saturate(g,2,2)
 rows.append({"name":"full-body-g2t2","g":g,"slot":"wrist"})
 g=Game.new(47)
 for i in range(3): install(g,request("wrist",3,3))
 for i in range(2): install(g,request("ankle",2,2))
 rows.append({"name":"near-full-g3t3","g":g,"slot":"wrist"})
 g=Game.new(51)
 for point in ["upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist"]:
  for i in range(2): install(g,request(g.Links.point_slot(point),2,2,point))
 g._install_assembly("glove","short","fixture",2,2)
 _floor_links(g)
 rows.append({"name":"composite-glove","g":g,"slot":"forearm"})
 g=Game.new(53)
 for i in range(3): install(g,request("wrist",2,2))
 var palm=install(g,request("palm",2,2))
 var wrist=g.state.equipment.filter(func(e):return e.slot=="wrist")[0]
 g._install_link(wrist.id,palm.id,4.8,"fixture",1,[],["wrist","palm"],["wrist","palm_left"])
 A.execute(g,{"pool":"ordinary","templates":["rope"],"count":1,"grade":2,"tier":2,"slot":"shoulder","shoulders":true},"fixture")
 rows.append({"name":"links-shoulders","g":g,"slot":"wrist"})
 g=Game.new(56)
 g.state.chastity_locks_enabled=true
 g._install_special("negative_plate_lock_medium","special_2_a",3)
 g._install_special("vaginal_egg_low","special_3_a")
 for i in range(3): install(g,request("ankle",3,3))
 rows.append({"name":"special-chastity","g":g,"slot":"ankle"})
 g=Game.new(58)
 for i in range(2): install(g,request("wrist",3,3))
 g._install_template("handcuffs","wrist",4,10,true,"fixture",1)
 rows.append({"name":"shackles","g":g,"slot":"wrist"})
 g=Game.new(59)
 g.state.room_encounters.entrance="rope_master_solo"
 g._start_battle()
 for i in range(2): install(g,request("wrist",2,2))
 var belt=request("wrist",3,3);belt.template="belt"
 install(g,belt)
 for e in g.state.enemies:
  if e.get("rope_art",null)!=null: e.rope_art.seal=true
 rows.append({"name":"rope-art-seal","g":g,"slot":"wrist"})
 return rows

# Real enemy-turn spec shape: one targeted slot, explicit grade/tier combinations
# plus the RestraintValue profile expansion used by the shipped intents.
static func floor_specs(g, slot: String) -> Array:
 var specs=[]
 for combo in [[1,1],[1,2],[2,1],[2,2],[2,3],[3,1],[3,3]]:
  var spec=g.EnemyPlans.application(["rope","cord","belt","fine_belt"],combo[0],combo[1],1,false,0)
  spec.slot=slot
  spec.replace=true
  specs.append(spec)
 var profiled=g.EnemyPlans.application(["rope","cord","belt","fine_belt"],2,2,1,false,4)
 profiled.slot=slot
 profiled.replace=true
 specs.append(profiled)
 return specs

# Mirrors _legal_choices: a normally installable candidate returns first, so the
# floor only ever sees a band whose every request needs a replacement.
static func _floor_band(g, spec: Dictionary, tally: Dictionary) -> void:
 var raw=A._raw(g,spec,"fixture")
 if raw.is_empty(): return
 var protected=spec.get("protected_ids",[])
 if not raw.filter(func(p):return A._request_reason(g,p,true,protected)=="").is_empty(): return
 if not spec.get("replace",false): return
 var floor=Replacement.removal_floor(g,raw,protected)
 for request in raw:
  if request.kind not in ["install","assembly","special_install"]: continue
  if request.kind=="special_install" and g.SpecialEquipment.is_chastity_type(request.get("type","")): continue
  if not Replacement.removal_floor_rejects(g,request,floor): continue
  tally.screened+=1
  var accepted=false
  if request.get("random_variant",false):
   for variant in E.MATERIALS[E.TEMPLATES[request.template].material][request.grade].size():
    var concrete=request.duplicate(true);concrete.variant=variant
    tally.plans+=1
    if A._replacement_plan(g,[concrete],"fixture",protected).get("ok",false): accepted=true
  else:
   tally.plans+=1
   if A._replacement_plan(g,[request],"fixture",protected).get("ok",false): accepted=true
  if accepted: tally.violations.append(str(request.get("template",request.get("type",request.kind)))+"@"+str(spec.get("slot","")))

# D16 hardening: the trial draft owns its log array and shares entries only because
# it appends. The live log stays byte-identical through choose/plan, and the commit
# appends exactly the draft's new rows once.
static func preview_log_isolation(t) -> void:
 var g=Game.new(42)
 for i in range(3): install(g,request("wrist",2,2))
 g.state.logs.append({"kind":"event","text":"既有日志","round":1,"phase":"battle","data":{}})
 var live=g.state.logs
 var size=live.size()
 var logs_before=live.duplicate(true)
 var choose_spec={"pool":"ordinary","templates":["rope","belt"],"slot":"wrist","grade":3,"tier":3,"count":1,"replace":true}
 var chosen=A.choose(g,choose_spec,"fixture")
 t.check(not chosen.is_empty(),"REPLACEMENT log isolation fixture chooses a real replacement candidate")
 t.check(is_same(g.state.logs,live) and g.state.logs.size()==size and g.state.logs==logs_before,"REPLACEMENT choose keeps the live log array and every entry untouched")
 var before=g.state.duplicate(true)
 var strong=request("wrist",3,3)
 var p=Replacement.plan(g,[strong],"fixture")
 t.check(p.ok,"REPLACEMENT log isolation fixture plans an accepted replacement")
 t.check(g.state==before and is_same(g.state.logs,live) and g.state.logs.size()==size and g.state.logs==before.logs,"REPLACEMENT plan keeps the live log deeply identical")
 t.check(p._after.logs.size()>size and p._after.logs.slice(0,size)==g.state.logs,"REPLACEMENT draft extends the live log history instead of rewriting it")
 t.check(range(size).all(func(i):return is_same(p._after.logs[i],g.state.logs[i])),"REPLACEMENT draft shares history entries it never rewrites")
 Replacement.execute(g,p)
 var committed=g.state.logs
 t.check(committed.size()==p._after.logs.size() and committed.slice(0,size)==before.logs and committed.slice(size)==p._after.logs.slice(size),"REPLACEMENT commit appends exactly the draft's own events once")
 t.check(committed.filter(func(row):return str(row.get("text","")).contains("已解除")).size()==1,"REPLACEMENT removal wording is committed exactly once after a preview")

# U3-1: two behaviour-neutral edges now have a real sensitivity proof.
static func neutral_edges_are_pinned(t) -> void:
 var g=DenseProbe.new(42)
 var wrist=install(g,request("wrist",1,1))
 var forearm=install(g,request("forearm",1,1,"mid_forearm"))
 var palm=install(g,request("palm",1,1))
 var first=g._install_link(forearm.id,wrist.id,4.8,"fixture",1,[],["forearm","wrist"],["mid_forearm","wrist"])
 var second=g._install_link(wrist.id,palm.id,4.8,"fixture",1,[],["wrist","palm"],["wrist","palm_left"])
 t.check(not first.is_empty() and not second.is_empty(),"REPLACEMENT anchor snapshot fixture has two real links")
 g.anchor_queries=0
 Replacement._transfer(g,[first,second],[])
 t.check(g.anchor_queries==1,"REPLACEMENT one transfer reads the anchor pool exactly once: "+str(g.anchor_queries))
 g.anchor_queries=0
 Replacement._transfer(g,[],[])
 t.check(g.anchor_queries==0,"REPLACEMENT a transfer without links never reads the anchor pool: "+str(g.anchor_queries))
 var h=Game.new(42)
 install(h,request("mouth",1,1))
 var before=h.state.duplicate(true)
 var planned=Replacement.plan(h,[request("mouth",3,3)],"fixture")
 t.check(planned.ok and planned._before==before,"REPLACEMENT plan keeps an independent full before snapshot")
 t.check(not is_same(planned._before,h.state) and not is_same(planned._before.equipment,h.state.equipment),"REPLACEMENT before snapshot owns its containers")
 var settled=h.state.equipment[0].durability
 planned._before.equipment[0].durability=0
 t.check(h.state.equipment[0].durability==settled,"REPLACEMENT before snapshot never aliases live equipment")

static func run(t) -> void:
 forced_special_boundaries(t)
 var unchanged_glove=full_glove()
 var same_glove=glove();same_glove.tier=1
 var same_plan=unchanged(t,unchanged_glove,[same_glove],"identical composite replacement")
 t.check(not same_plan.ok,"REPLACEMENT regenerated root and component IDs do not make an identical composite useful")
 impossible_dense_replacement(t)
 equal_cost_dense_replacement(t)
 equivalent_link_transfers(t)
 partially_lost_transfers(t)
 var g=Game.new(42)
 var first=install(g,request("wrist",3,2))
 var p=unchanged(t,g,[request("wrist",1,1)],"normal append")
 t.check(p.ok and p.removed.is_empty() and p.installed.size()==1,"REPLACEMENT prefer empty capacity even with weaker new item")
 var version=g.state.version
 var enemy=g.state.enemies[0]
 var original_state=g.state
 var original_enemies=g.state.enemies
 var original_rng=g.state.rng
 var original_hand=g.state.hand
 var before=g.state.duplicate(true)
 var result=Replacement.execute(g,p)
 t.check(result.ok and g._equipment(first.id)==first and g.state.version==version,"REPLACEMENT normal factory commit preserves old item and enclosing version")
 enemy.hp-=1
 t.check(g.state.enemies[0].hp==enemy.hp,"REPLACEMENT enclosing enemy references remain live")
 t.check(g.state.energy==before.energy and g.state.mana==before.mana and g.state.round==before.round and g.state.rng==before.rng,"REPLACEMENT no implicit costs, turn or random selection")
 t.check(is_same(g.state,original_state) and is_same(g.state.enemies,original_enemies) and is_same(g.state.rng,original_rng) and is_same(g.state.hand,original_hand),"REPLACEMENT unchanged state, enemies, RNG and hand containers retain identity")
 result.installed[0].durability=999
 p._after.equipment[0].durability=888
 t.check(g.state.equipment.all(func(e):return e.durability<=e.maximum),"REPLACEMENT result and plan contain no live mutable equipment")
 t.check(not Replacement.execute(g,p).ok,"REPLACEMENT committed plan cannot replay at unchanged enclosing version")

 g=Game.new(42)
 first=install(g,request("mouth",1,2))
 p=unchanged(t,g,[request("mouth",1,2)],"identical ordinary replacement")
 t.check(not p.ok and not Replacement.execute(g,p).ok,"REPLACEMENT unchanged ordinary copy is neither available nor executable")
 first.durability-=1
 p=unchanged(t,g,[request("mouth",1,2)],"ordinary equal score repair")
 t.check(p.ok and p.removed==[first.id] and p.comparisons[0].old_value==p.comparisons[0].new_value,"REPLACEMENT equal comparison still permits actual durability restoration")
 t.check(Replacement.execute(g,p).ok and g.validate()=="","REPLACEMENT ordinary replacement validates")
 g=Game.new(42);first=install(g,request("mouth",1,2,"",true))
 p=unchanged(t,g,[request("mouth",1,2)],"old lock")
 t.check(not p.ok and p.removed.is_empty(),"REPLACEMENT old lock adds one and rejects weaker replacement")
 first.durability-=1
 p=Replacement.plan(g,[request("mouth",1,2,"",true)],"fixture")
 t.check(p.ok and p.comparisons[0].old_value==4 and p.comparisons[0].new_value==4,"REPLACEMENT explicit new lock contributes once")

 g=Game.new(42)
 first=install(g,request("wrist",1,1))
 install(g,request("wrist",2,2));install(g,request("wrist",3,2))
 p=Replacement.plan(g,[request("wrist",2,2)],"fixture")
 t.check(p.ok and p.removed==[first.id],"REPLACEMENT smallest set then lowest total value")
 g=Game.new(42)
 for layer in range(3): g._install_template("rope","wrist",4,10,false,"fixture",1,layer)
 p=Replacement.plan(g,[request("wrist",2,2),request("wrist",2,2)],"fixture")
 t.check(not p.ok,"REPLACEMENT cannot peel newly exposed layers in one batch")
 p=Replacement.plan(g,[request("wrist",2,2)],"fixture")
 t.check(p.ok and p.removed==[g.state.equipment[2].id],"REPLACEMENT only original outermost layer is eligible")

 g=Game.new(42)
 g._resource_feedback=preload("res://core/resource_feedback.gd").new()
 g._resource_feedback.capture(g.state)
 var feedback_before=g._resource_feedback.events.duplicate(true)
 p=unchanged(t,g,[request("forearm",3,3,"mid_forearm")],"factory binding RNG and feedback")
 t.check(p.ok and g._resource_feedback.events==feedback_before,"REPLACEMENT factories never send preview feedback")
 before=g.state.duplicate(true)
 var tampered=p.duplicate(true);tampered._after.mana=0
 t.check(not Replacement.execute(g,tampered).ok and g.state==before,"REPLACEMENT forged snapshot rejected without mutation")
 tampered=p.duplicate(true);tampered.expectedVersion+=1
 t.check(not Replacement.execute(g,tampered).ok and g.state==before,"REPLACEMENT version mismatch rejected atomically")
 g.state.mana-=1
 t.check(not Replacement.execute(g,p).ok,"REPLACEMENT same-version state drift also invalidates plan")
 g.state=before
 var expected_rng=p._after.rng.duplicate()
 t.check(Replacement.execute(g,p).ok and g.state.rng==expected_rng and g._resource_feedback.events==feedback_before,"REPLACEMENT committed factory RNG equals preview exactly; no resource pulse")
 var invalid=request("wrist",1,2);invalid.variant=99
 p=unchanged(t,g,[request("forearm",3,3,"below_elbow"),invalid],"invalid final factory request")
 t.check(not p.ok and g._resource_feedback.events==feedback_before,"REPLACEMENT second factory failure rolls back first factory RNG, equipment and feedback")

 g=Game.new(42)
 fill(g,"upper_arm_top",1,3)
 p=unchanged(t,g,[request("upper_arm",3,2,"upper_arm_top")],"ordinary shoulder loss penalty")
 t.check(not p.ok,"REPLACEMENT dependent shoulders raise each ordinary host threshold by two")
 p=Replacement.plan(g,[request("upper_arm",3,3,"upper_arm_top")],"fixture")
 t.check(p.ok and p.lost_links.size()==2 and p.comparisons[0].old_value==6 and p.comparisons[0].new_value==6,"REPLACEMENT new automatic shoulders do not silently preserve old shoulder identities")

 g=Game.new(42)
 fill(g,"upper_arm_top",2,2);fill(g,"below_elbow",2,2);fill(g,"wrist",3,2)
 p=unchanged(t,g,[glove()],"two equal low votes, one high")
 t.check(p.ok and p.comparisons.size()==3 and p.comparisons.filter(func(r):return r.old_value<=r.new_value).size()==2,"REPLACEMENT equal is low, strictly greater low count wins")
 t.check(Replacement.execute(g,p).ok and g.state.equipment.size()==6 and g.state.composites.size()==1 and g.validate()=="","REPLACEMENT minority stronger equipment removed as one minimal atomic set")
 g=Game.new(42)
 fill(g,"below_elbow",2,2);fill(g,"wrist",3,2)
 install(g,request("upper_arm",1,1,"upper_arm_top"))
 p=unchanged(t,g,[glove()],"tied majority")
 t.check(not p.ok,"REPLACEMENT tied vote fails; spare weak equipment cannot supply extra votes")
 g=Game.new(42);g._install_assembly("glove","long","fixture",2,2,{},"straight")
 p=unchanged(t,g,[request("fingers",3,3)],"sealed hand")
 t.check(not p.ok,"REPLACEMENT full or sealed structures do not bypass installation rules")
 p=Replacement.plan(g,[glove()],"fixture")
 t.check(not p.ok,"REPLACEMENT assembly mutual exclusion remains authoritative")

 g=full_glove()
 var singles=glove_singles(g)
 var old_root=g.state.composites[0].duplicate(true)
 p=unchanged(t,g,singles.slice(0,4),"incomplete composite replacement")
 t.check(not p.ok,"REPLACEMENT ordinary batch must cover every physical subposition together")
 var equality=singles.duplicate(true);equality[0].tier=1
 p=Replacement.plan(g,equality,"fixture")
 t.check(not p.ok,"REPLACEMENT every ordinary item must strictly beat local composite plus shoulder cost")
 p=unchanged(t,g,singles,"complete composite replacement")
 t.check(p.ok and p.lost_links.size()==2 and p.comparisons.any(func(r):return r.point=="upper_arm_top" and r.lost_link_bonus==2),"REPLACEMENT each shoulder interface costs one only at upper arm top: "+str(p.get("reason"))+" "+str(p.get("lost_links")))
 if p.ok:
  t.check(Replacement.execute(g,p).ok and g._composite(old_root.id).is_empty() and g.state.equipment.size()==15 and g.validate()=="","REPLACEMENT full ordinary group removes root and dependencies atomically")
 g=full_glove()
 var inner=g.state.equipment.filter(func(e):return e.slot=="wrist")[0]
 inner.durability=0;g._cleanup()
 install(g,request("wrist",2,2))
 p=unchanged(t,g,glove_singles(g),"root covered elsewhere")
 t.check(not p.ok,"REPLACEMENT composite cannot be pulled through an original external layer")

 g=Game.new(42)
 for i in range(2): install(g,request("calf",1,1,"below_knee"))
 var leg=g._install_assembly("leg","lower","fixture",2,1)
 var body=g._composite_body(leg).duplicate(true)
 var band=leg.components.filter(func(e):return e.part=="below_knee")[0]
 p=Replacement.plan(g,[request("calf",3,2,"below_knee")],"fixture")
 t.check(p.ok and p.removed==[band.id],"REPLACEMENT independent outer band is one real removable piece")
 if p.ok:
  Replacement.execute(g,p)
  t.check(g._equipment(body.id)==body and g.validate()=="","REPLACEMENT replacing independent band preserves its body and sibling ids")

 g=Game.new(42)
 var wrists=fill(g,"wrist")
 var palm=install(g,request("palm",1,1))
 var link=g._install_link(wrists[0].id,palm.id,4.2,"fixture",1,[wrists[0].id],["wrist","palm"],["wrist","palm_left"])
 var old_link=link.duplicate(true)
 p=unchanged(t,g,[request("wrist",2,2)],"link transfer")
 t.check(p.ok and p.removed==[wrists[0].id] and p.lost_links.is_empty(),"REPLACEMENT legal transfer avoids loss penalty")
 if p.ok:
  Replacement.execute(g,p)
  var actual=g.state.links[0].duplicate(true)
  actual.ends=old_link.ends;actual.blocked_slip=old_link.blocked_slip
  t.check(actual==old_link and g.state.links[0].ends[0]==p.installed[0].id and g.state.links[0].blocked_slip==[p.installed[0].id],"REPLACEMENT link keeps identity, other end, points, durability, lock and source")
  t.check(g._equipment(wrists[0].id).is_empty() and g.validate()=="","REPLACEMENT official cleanup removes replaced target without removing transferred link")

 g=Game.new(42)
 var forearm=install(g,request("forearm",1,1,"mid_forearm"))
 first=install(g,request("wrist",1,1))
 for i in range(2):
  install(g,request("forearm",2,2,"mid_forearm"));install(g,request("wrist",2,2))
 link=g._install_link(forearm.id,first.id,4.8,"fixture",1,[],["forearm","wrist"],["mid_forearm","wrist"])
 p=unchanged(t,g,[glove()],"both lost endpoints")
 t.check(p.ok and p.lost_links==[link.id] and p.comparisons.size()==2 and p.comparisons.all(func(r):return r.lost_link_bonus==1),"REPLACEMENT one lost link charges each old endpoint but is deleted once")
 if p.ok: t.check(Replacement.execute(g,p).ok and g.state.links.is_empty() and g.validate()=="","REPLACEMENT same-root reconnection rejected by official link validator")

 g=Game.new(42)
 var below=install(g,request("forearm",2,2,"below_elbow"))
 var middle=install(g,request("forearm",1,1,"mid_forearm"))
 for i in range(2): install(g,request("forearm",3,2,"below_elbow"))
 var middle_partner=install(g,request("forearm",3,2,"mid_forearm"))
 install(g,request("forearm",3,2,"mid_forearm"))
 var wrist_partner=install(g,request("wrist",1,1))
 var expendable=g._install_link(middle.id,wrist_partner.id,4.8,"fixture",1,[],["forearm","wrist"],["mid_forearm","wrist"])
 var critical=g._install_link(below.id,middle_partner.id,4.2,"fixture",1,[],["forearm","forearm"],["below_elbow","mid_forearm"])
 p=unchanged(t,g,[glove()],"direction-budget alternatives")
 t.check(p.ok and p.lost_links==[expendable.id],"REPLACEMENT searches equal-size legal transfer sets before rejecting local majority")
 if p.ok:
  Replacement.execute(g,p)
  t.check(g.state.links.size()==1 and g.state.links[0].id==critical.id and g.validate()=="","REPLACEMENT merged anchor respects shared direction budget and preserves feasible link")

 g=Game.new(42)
 var special=g._install_special("vaginal_egg_low","special_3_a")
 p=unchanged(t,g,[{"kind":"special_install","type":"external_wand_low","slot":"special_3_a"}],"special capacity")
 t.check(p.ok and p.removed==[special.id] and p.comparisons[0].old_value==1 and p.comparisons[0].new_value==1,"REPLACEMENT special comparison has no invented tightness")
 if p.ok: t.check(Replacement.execute(g,p).ok and g.validate()=="","REPLACEMENT special factory and cleanup retain their own schema")
 p=Replacement.plan(g,[{"kind":"special_install","type":"external_wand_high","slot":"special_3_a"}],"fixture")
 t.check(p.ok and p.removed.size()==1 and p.comparisons.is_empty(),"REPLACEMENT authorized same-family upgrade removes the old special root before installation")
 if p.ok: t.check(Replacement.execute(g,p).ok and g.state.special_equipment.any(func(item):return item.type=="external_wand_high") and g.validate()=="","REPLACEMENT same-family special upgrade commits through the original factory")
 p=unchanged(t,g,[{"kind":"special_install","type":"external_wand_high","slot":"special_3_a"}],"identical special replacement")
 t.check(not p.ok and not Replacement.execute(g,p).ok,"REPLACEMENT unchanged same-family special copy cannot keep an enemy active")
 p=Replacement.plan(g,[{"kind":"special_install","type":"anal_egg_low","slot":"special_3_b","locked":true}],"fixture")
 t.check(not p.ok,"REPLACEMENT special specification never grants implicit ordinary locking")
 p=Replacement.plan(g,[{"kind":"special_install","type":"crotch_rope_low","slot":"special_3_a"}],"fixture")
 t.check(p.ok and p.removed.is_empty(),"REPLACEMENT zero-capacity special source installs normally without clearing occupied positions")
 removal_floor_is_necessary(t)
 trial_log_isolation(t)
 floor_prescreen_matches_full_plan(t)
 preview_log_isolation(t)
 neutral_edges_are_pinned(t)
