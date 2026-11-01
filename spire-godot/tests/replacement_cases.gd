extends RefCounted

const Replacement=preload("res://core/equipment_replacement.gd")
const Game=preload("res://tests/game_fixture.gd")

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
