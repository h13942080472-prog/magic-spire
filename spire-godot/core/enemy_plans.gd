extends RefCounted
const Equipment=preload("res://data/equipment.gd")
const B=preload("res://data/balance.gd")
const SIX_CYCLE_LENGTH=8

# Intent declarations hold scope and costs, not targets. Concrete choices happen on execution.
static func application(templates: Array, grade: int=1, tightness: int=2, count: int=1, final: bool=false) -> Dictionary:
 if final:
  grade=B.ENEMY_DEPARTURE_GRADE;tightness=B.ENEMY_DEPARTURE_TIER
 return {"kind":"apply","pool":"ordinary","templates":templates.duplicate(),"grade":grade,"tier":tightness,"count":count,"locked":false,"final":final,"replace":false,"text":"施加拘束具"+("，随后离场" if final else ""),"delayed":false}

static func special_application(g, e: Dictionary) -> Dictionary:
 return {"kind":"apply","pool":"special","templates":g.Enemies.TYPES[e.type].special_pool.duplicate(),"grade":1,"tier":2,"count":1,"locked":false,"final":false,"replace":false,"text":"佩戴特殊装备","delayed":false}

static func installation_intents(g, e: Dictionary) -> Array:
 var spec=g.Enemies.TYPES[e.type]
 if spec.has("weighted_moves"): return spec.weighted_moves.values().filter(func(m):return m.plan.kind=="apply").map(func(m):return m.plan.duplicate(true))
 match spec.behavior:
  "lock": return [spec.chastity_departure.duplicate(true)] if g.state.chastity_locks_enabled else []
  "six_bind": return [six_ordinary(spec,2,2,1,true),six_composite(2,2,true),six_special(spec,1,1,true),six_special(spec,2,1,true)]
  "iron_man": return g.IronMan.installation_intents(g,e)
  "iron_drone": return []
  "puppeteer":
   var ordinary=g.Puppets.ordinary(g)
   var special=special_application(g,e);special.grade=2;special.tier=3;special.replace=true
   return [ordinary,six_composite(2,2,true),special]
  "puppet": return [g.Puppets.ordinary(g)]+e.get("puppet_prepared",{}).values().duplicate(true)
  "sequence": return spec.repeat_cycle.filter(func(p):return p.kind=="apply").duplicate(true)
  "humanoid": return spec.opening.filter(func(p):return p.kind=="apply").duplicate(true)
  "drone": return [application(spec.install_pool,1,1,2)]
  "binding_box": return [application(spec.install_pool,2,g.Enemies.encounter_member(g.state,e.type).get("application_tier",2),2)]+carried_intents(g,e)
  "guard":
   var ordinary=application(g.Guard.ordinary_templates(),2)
   ordinary.replace=true
   ordinary.shoulders=true
   var composite={"kind":"apply","pool":"composite","grade":2,"tier":2,"count":1,"replace":true,"locked":false,"final":false,"text":"施加复合拘束具","delayed":false}
   return [ordinary,composite]
  "dispenser": return [special_application(g,e)]
  "attachment": return [application(spec.attachment_pool,1,2,1,true)]
  "restraint":
   if spec.has("cycle"):
    return [application(spec.install_pool,spec.get("install_grade",2),2,spec.get("install_count",2 if spec.cycle.has("install_pair") else 1))]
   return [application(spec.install_pool,1),application(spec.final_pool,2,2,1,true)]
 return []

static func fallback_install(g, e: Dictionary) -> Dictionary:
 var choices=installation_intents(g,e)
 if choices.is_empty(): return {"kind":"idle","text":"没有可执行的施加行动。","delayed":false}
 return choices[g._random_index("enemy",choices.size())].duplicate(true)

# Whole source repertoire, independent of this turn's charge, delay or chosen intent.
static func can_affect_equipment(g, e: Dictionary) -> bool:
 if e.gone: return false
 var definition=g.Enemies.TYPES[e.type]
 var behavior=definition.behavior
 var cycle=definition.get("cycle",[])
 var declared=definition.get("opening",[])+definition.get("repeat_cycle",[])
 var tightens=behavior in ["guard","six_bind","iron_man","binding_box","drone"] or (behavior=="restraint" and (cycle.is_empty() or cycle.any(func(kind):return kind in ["tighten","tighten_pair","random_strike"]))) or declared.any(func(p):return p.kind in ["tighten","versatile_control"] or p.get("tighten_missing",false))
 if (tightens or definition.get("weighted_moves",{}).values().any(func(m):return m.plan.get("tighten_after",false))) and not targets(g,e,"tighten").is_empty(): return true
 var locks=behavior in ["guard","iron_man","lock"] or declared.any(func(p):return p.kind in ["lock","versatile_control"])
 if locks and not targets(g,e,"lock").is_empty(): return true
 var plans=installation_intents(g,e)
 # Include passive and burst specifications without adding them to reinforcement fallback.
 if definition.has("turn_install_effect"): plans.append(application(definition.install_pool,1))
 if definition.has("capture_pool"): plans.append(application(definition.capture_pool,2))
 if "split_burst" in cycle: plans.append(application(definition.final_pool,2,3))
 for p in declared:
  if p.kind=="apply" and p not in plans: plans.append(p.duplicate(true))
 for plan in plans:
  var spec=application_spec(g,e,plan)
  # A declared preparation gain can enable a later three-tier replacement.
  if declared.any(func(p):return p.get("ready_gain",0)>0): spec.ready_layers=maxi(1,spec.ready_layers)
  if g.Application.can_apply(g,spec,e.id): return true
 return false

static func can_arrest(g, e: Dictionary) -> bool:
 var spec=g.Enemies.TYPES[e.type]
 return not e.gone and spec.get("can_arrest",spec.get("humanoid",false) or spec.get("mechanical",false))

static func has_equipment_space(g) -> bool:
 return g.state.enemies.any(func(enemy):return can_affect_equipment(g,enemy))

static func long_battle_limit(g) -> bool:
 if g.state.phase!="battle" or g.state.round<g.B.ENEMY_LONG_BATTLE_ROUND: return false
 if g.room_data(g.state.room).get("boss",false) or g.Enemies.ENCOUNTERS.get(g.state.room_encounters.get(g.state.room,""),{}).get("rank","")=="boss": return false
 if g.Cards.worn_count(g)>=g.B.ENEMY_LONG_BATTLE_COUNT: return true
 # Sum tiers using the same whole-item membership as the existing worn counter.
 var tightness=0
 for tier in [1,2,3]: tightness+=g.Cards.worn_count(g,true,tier)
 return tightness>=g.B.ENEMY_LONG_BATTLE_TIGHTNESS

static func application_spec(g, e: Dictionary, intent: Dictionary) -> Dictionary:
 var spec=intent.duplicate(true)
 spec.count+=e.get("application_bonus",0)
 var definition=g.Enemies.TYPES[e.type]
 spec.replace=(spec.get("replace",false) and definition.get("humanoid",false)) or (spec.pool=="composite" and definition.get("mechanical",false))
 spec.ready_layers=e.get("ready_layers",0)
 return spec

static func reinforce(g, e: Dictionary, count: int=1, tightness: int=0) -> Dictionary:
 if targets(g,e,"tighten").is_empty(): return fallback_install(g,e)
 if count>1: return batch(g,e,count,2,tightness,true,g.Enemies.TYPES[e.type].install_pool)
 var p={"kind":"tighten","text":"加固拘束具","delayed":false}
 if tightness>0: p.tier=tightness
 return p

static func versatile_control(g, e: Dictionary) -> Dictionary:
 var options=[]
 if not targets(g,e,"lock").is_empty():
  options.append({"kind":"lock","text":"为一件拘束具上锁","random_target":true,"delayed":false})
 if not targets(g,e,"tighten").is_empty():
  var plan=batch(g,e,2,2,3,true,g.Enemies.TYPES[e.type].install_pool)
  plan.text="加固两件拘束具"
  options.append(plan)
 if options.is_empty():
  var fallback=fallback_install(g,e)
  fallback.text="没有可上锁或加固的目标，改为安装性玩具。"
  return fallback
 return options[g._random_index("enemy",options.size())]

static func six_ordinary(spec: Dictionary, grade: int, tightness: int, count: int=1, replace: bool=false) -> Dictionary:
 var plan=application(spec.install_pool,grade,tightness,count)
 plan.replace=replace
 return plan

static func six_composite(grade: int=2, tightness: int=2, replace: bool=true) -> Dictionary:
 return {"kind":"apply","pool":"composite","templates":[],"grade":grade,"tier":tightness,"count":1,"locked":false,"final":false,"replace":replace,"text":"施加复合拘束具","delayed":false}

static func six_special(spec: Dictionary, grade: int, count: int, replace: bool=true) -> Dictionary:
 return {"kind":"apply","pool":"special","templates":spec.special_pools[grade].duplicate(),"grade":grade,"tier":2,"count":count,"locked":false,"final":false,"replace":replace,"text":"佩戴性玩具","delayed":false}

static func six_areas() -> Array:
 return [
  {"name":"眼部","slots":["eyes"]},
  {"name":"口部","slots":["mouth"]},
  {"name":"双臂","slots":["upper_arm","forearm"]},
  {"name":"手腕与手部","slots":["wrist","palm","fingers"]},
  {"name":"大腿","slots":["thigh"]},
  {"name":"小腿与足部","slots":["calf","ankle","foot","toes"]}]

static func six_area_targets(g, e: Dictionary, slots: Array) -> Array:
 return targets(g,e,"tighten").filter(func(item):return Equipment.coverage(item).any(func(slot):return slot in slots))

static func six_plan(g, e: Dictionary) -> Dictionary:
 if e.stage==1: return {"kind":"six_prepare","text":"展开六缚阵","delayed":false}
 if e.stage==2: return {"kind":"six_opening","text":"六重束装","delayed":false}
 match (e.stage-3)%SIX_CYCLE_LENGTH:
  0,3: return {"kind":"six_tease","text":"戏弄封缚","delayed":false}
  1:
   var plan=six_ordinary(g.Enemies.TYPES[e.type],2,2,2,true)
   plan.tighten_missing=true;plan.text="双重束缚"
   return plan
  2,5:
   var completed_cycles=maxi(0,int((e.stage-3)/SIX_CYCLE_LENGTH))
   return {"kind":"six_tune","text":"调教升温","delayed":false,"count":1+int(e.constriction),"grade":1 if completed_cycles==0 else 2}
  4: return {"kind":"six_composite","text":"复合束装","delayed":false}
  6: return {"kind":"six_finale","text":"六缚齐收","delayed":false}
  _: return {"kind":"idle","text":"六缚暂不行动。","delayed":false}

static func lock_departure_pending(g, e: Dictionary) -> bool:
 return not e.gone and g.state.chastity_locks_enabled and g.Enemies.TYPES[e.type].has("chastity_departure") and targets(g,e,"lock").is_empty()

static func build(g, e: Dictionary) -> Dictionary:
 var spec=g.Enemies.TYPES[e.type]
 if spec.get("humanoid",false) and g.CaptureBind.kind(g,e)=="" and long_battle_limit(g):
  return {"kind":"capture","text":"准备逮捕","delayed":false}
 if spec.behavior=="six_bind" and g.state.overload_total>=e.next_climax_capture:
  return {"kind":"capture","text":"准备逮捕","delayed":false,"cancel_on_interrupt":true,"climax_threshold":e.next_climax_capture}
 if can_arrest(g,e) and not has_equipment_space(g): return {"kind":"capture","text":"执行逮捕","delayed":false}
 if spec.behavior=="guard": return g.Guard.build(g,e)
 if spec.behavior=="six_bind": return six_plan(g,e)
 if spec.behavior=="iron_man": return g.IronMan.plan(g,e)
 if spec.behavior in ["iron_drone","drone","binding_box"]:
  var required=g.CaptureBind.required_intent(g,e)
  if required!="": return {"kind":required,"text":{"capture":"执行收押","bind_apply":"施加捕缚 · 初始%s/100" % g.number(g.CaptureBind.initial_value(g,e)),"bind_prepare":"准备捕缚"}[required],"delayed":false}
 if spec.behavior=="iron_drone": return {"kind":"idle","text":"维持捕缚 · 每累计%d能量触发" % g.CaptureBind.energy_threshold(g,"iron_drone"),"delayed":false}
 if spec.behavior=="puppeteer": return g.Puppets.plan(e)
 if spec.behavior=="puppet": return {"kind":"idle","text":"玩偶不会行动","delayed":false}
 if spec.has("weighted_moves"):
  var move="scatter"
  if e.stage>1:
   var options=spec.weighted_moves.keys().filter(func(key):return key!=e.last_move or e.move_streak<spec.weighted_moves[key].limit)
   var weight=options.reduce(func(total,key):return total+spec.weighted_moves[key].weight,0)
   var draw=g._random_index("enemy",weight)
   for key in options:
    draw-=spec.weighted_moves[key].weight
    if draw<0: move=key;break
  var plan=spec.weighted_moves[move].plan.duplicate(true);plan.move=move
  return plan
 var material=spec.get("restraint_name","绳索")
 match spec.behavior:
  "drone","binding_box":
   var box=spec.behavior=="binding_box"
   var member=g.Enemies.encounter_member(g.state,e.type)
   match e.guard.cycle_step:
    0:
     if not targets(g,e,"tighten").is_empty() and g._random_index("enemy",2)==1:
      return {"kind":"tighten_budget","budget":member.get("reinforce_budget",4) if box else 2,"text":"收紧皮革拘束具 · 累计%d档" % member.get("reinforce_budget",4) if box else "收紧胶带 · 累计2档","delayed":false}
     return application(spec.install_pool,2 if box else 1,member.get("application_tier",2) if box else 1,2)
    1: return {"kind":"charge" if box else "bind_gain","text":"准备施加复合装备" if box else "捕缚进度＋10","delayed":false}
    _:
     if box: return {"kind":"bind_gain" if e.carried_indices.is_empty() else "carried_apply","text":"捕缚进度＋%s" % g.number(g.CaptureBind.gain_amount(g,e)) if e.carried_indices.is_empty() else "施加一件盒内复合装备","delayed":false}
     return {"kind":"idle","text":"发呆","delayed":false}
  "humanoid","sequence":
   var index=e.stage-1
   var plan={}
   if index<spec.opening.size(): plan=spec.opening[index].duplicate(true)
   else:
    index-=spec.opening.size()
    if spec.has("repeat_count") and index>=spec.repeat_cycle.size()*spec.repeat_count: return {"kind":"capture","text":"执行逮捕","delayed":false}
    plan=spec.repeat_cycle[index%spec.repeat_cycle.size()].duplicate(true)
   return versatile_control(g,e) if plan.kind=="versatile_control" else plan
  "lock":
   if lock_departure_pending(g,e): return spec.chastity_departure.duplicate(true)
   if e.stage%2==0: return {"kind":"lock","text":"上锁","delayed":false}
   return {"kind":"charge","text":"预告上锁","delayed":false}
  "dispenser":
   match (e.stage-1)%3:
    0: return {"kind":"charge","text":"准备佩戴装备","delayed":false}
    1: return special_application(g,e)
    _: return {"kind":"pause","text":"停顿","delayed":false}
  "attachment":
   if e.stage<3: return {"kind":"charge","text":"蓄力 %d/2" % e.stage,"delayed":false}
   var p=application(spec.attachment_pool,1,2,1,true)
   p.preferred_slots=[spec.attachment_slot]
   return p
 if spec.has("cycle"):
  match spec.cycle[(e.stage-1)%spec.cycle.size()]:
   "turn_install": return {"kind":"turn_install","text":spec.turn_install_effect.name,"delayed":false}
   "random_strike":
    if g._random_index("enemy",2)==0:
     var plan=reinforce(g,e,1,3)
     if plan.kind=="tighten": plan.random_target=true;plan.text="收紧"
     else: plan.text="甩缚"
     return plan
    var plan=application(spec.install_pool,1,2,2);plan.text="甩缚"
    return plan
   "prepare": return {"kind":"charge","text":"准备施加","delayed":false}
   "install_pair": return batch(g,e,2,2,2,false,spec.install_pool)
   "tighten_pair": return reinforce(g,e,2,3)
   "prepare_burst": return {"kind":"charge","text":"蓄力","delayed":false}
   "split_burst": return {"kind":"split_burst","text":"全身施加并分裂","delayed":false}
   "prepare_install": return {"kind":"charge","text":"准备施加拘束具","delayed":false}
   "install_prepared": return application(spec.install_pool,spec.install_grade)
   "tighten": return reinforce(g,e)
 if e.stage==1: return application(spec.install_pool)
 if e.stage==2: return reinforce(g,e)
 if e.stage==3: return {"kind":"charge","text":"准备附着","delayed":false}
 return application(spec.final_pool,2,2,1,true)

static func end_turn(g, e: Dictionary) -> void:
 if g.state.phase!="battle" or e.gone or e.get("ritual",0)<=0: return
 e.application_bonus+=e.ritual
 g._emit("event",e.name+"的仪式生效，施加数量加成增加%d件，现为＋%d件。" % [e.ritual,e.application_bonus],{"ritual":{"enemy":e.id,"gain":e.ritual,"bonus":e.application_bonus}})

static func activate_install(g, e: Dictionary) -> void:
 var effect=g.Enemies.TYPES[e.type].turn_install_effect
 e.turn_install_layers=e.get("turn_install_layers",0)+1 if effect.stack else 1
 g._emit("event",e.name+"施加「%s」，现有%d层。" % [effect.name,e.turn_install_layers],{"turn_install":{"enemy":e.id,"layers":e.turn_install_layers,"timing":effect.timing}})

static func tick_install(g, timing: String) -> void:
 if g.state.phase!="battle": return
 for e in g.state.enemies:
  if e.gone or e.get("turn_install_layers",0)<=0: continue
  var spec=g.Enemies.TYPES[e.type]
  if spec.turn_install_effect.timing!=timing: continue
  g._enemy_operation(e,application(spec.install_pool,1,2,e.turn_install_layers))

static func targets(g, e: Dictionary, kind: String, required_slots: Array=[]) -> Array:
 # docs/spec/equipment-query-seam.md「作用域进出点（冻结名单）」: one read scope per call; the enemy plan only reads equipment.
 var previous=g._begin_equipment_read()
 var choices=g.physical_pieces().filter(func(x):return g._can_tighten(x) if kind=="tighten" else Equipment.allows(x,"lock") and not x.locked)
 if kind=="tighten" and e.type=="iron_man": choices=choices.filter(func(x):return g.state.equipment.has(x))
 if not required_slots.is_empty():
  choices=choices.filter(func(x):return Equipment.coverage(x).any(func(slot):return slot in required_slots))
 var definition=g.Enemies.TYPES[e.type]
 if kind=="tighten" and definition.has("reinforce_material"):
  choices=choices.filter(func(x):return x.material==definition.reinforce_material and (g.tier(x.durability,x.maximum)<3 or g._reinforcement_locks(x)))
 if kind=="tighten" and g.Enemies.behavior(e.type) in ["restraint","drone"]: choices=choices.filter(func(x):return x.template in g.Enemies.TYPES[e.type].install_pool)
 choices.sort_custom(func(a,b):
  var own_a=1 if a.source==e.id else 0
  var own_b=1 if b.source==e.id else 0
  if own_a!=own_b: return own_a>own_b
  if a.durability/a.maximum!=b.durability/b.maximum: return a.durability/a.maximum<b.durability/b.maximum
  return a.id.naturalnocasecmp_to(b.id)<0)
 g._equipment_read=previous
 return choices

static func resolve(g, e: Dictionary, original: Dictionary) -> Dictionary:
 var p=original.duplicate(true)
 if p.kind in ["tighten","lock"]:
  var choices=targets(g,e,p.kind,p.get("required_slots",[]))
  if p.has("target"):
   # Explicit target declarations do not silently become unspecified actions.
   if choices.any(func(x):return x.id==p.target): return p
  elif not choices.is_empty():
   p.target=choices[g._random_index("enemy",choices.size()) if p.get("random_target",false) else 0].id
   return p
  return {"kind":"idle","text":"没有可以加固的拘束具，这次动作落空。" if p.kind=="tighten" else "没有可以上锁的拘束具，这次动作落空。","delayed":false}
 return p

static func positions(g, p: Dictionary) -> Array:
 if p.kind=="link": return p.contact_points
 if p.kind=="tighten":
  var target=g._equipment(p.get("target",""))
  return [] if target.is_empty() else Equipment.physical_points(target)
 if p.kind=="install": return g._installation_points(p.slot,p.get("point",""))
 return []

static func batch_choice(g, e: Dictionary, grade: int, tightness: int, tighten: bool, pool: Array, used: Array) -> Dictionary:
 if tighten:
  var pieces=targets(g,e,"tighten").filter(func(x):return not Equipment.physical_points(x).any(func(point):return point in used))
  if pieces.is_empty(): return {}
  var target=pieces[g._random_index("enemy",pieces.size())]
  return {"kind":"tighten","target":target.id,"tier":tightness,"text":"加固拘束具","delayed":false}
 var choices=g.EquipmentOffers.preferred(g,g.EquipmentOffers.for_pool(g,grade,pool).filter(func(p):return not positions(g,p).any(func(point):return point in used)))
 if choices.is_empty(): return {}
 return g._install_choice(choices[g._random_index("enemy",choices.size())],e.id,grade,tightness)

static func batch(_g, _e: Dictionary, count: int, grade: int, tightness: int, tighten: bool, pool: Array) -> Dictionary:
 return {"kind":"equipment_batch","count":count,"grade":grade,"tier":tightness,"tighten":tighten,"templates":pool.duplicate(),"operations":[],"delayed":false,"text":"加固拘束具" if tighten else "施加拘束具"}

static func execute_batch(g, e: Dictionary, p: Dictionary) -> void:
 var used=[];var completed=0
 # Count zero means one operation per available precise position, not an unlimited refill.
 while p.count==0 or completed<p.count:
  var op=batch_choice(g,e,p.grade,p.tier,p.tighten,p.templates,used)
  if op.is_empty(): break
  var points=positions(g,op).duplicate()
  if points.is_empty(): break
  var evasion_before=g.state.evasion
  g._enemy_operation(e,op)
  if g.state.evasion==evasion_before: used.append_array(points)
  completed+=1
 if completed==0:
  g._emit("event",e.name+("没有可以加固的拘束具，这次动作落空。" if p.tighten else "没有可以施加的位置，这次动作落空。"))
 elif p.count>0 and completed<p.count:
  g._emit("event",e.name+"完成%d次%s，其余动作没有合法目标而落空。" % [completed,"加固" if p.tighten else "施加"])

static func execute_tighten_budget(g, e: Dictionary, p: Dictionary) -> void:
 var completed=0
 for i in range(p.budget):
  var choices=targets(g,e,"tighten")
  if choices.is_empty(): break
  var target=choices[g._random_index("enemy",choices.size())]
  g._enemy_operation(e,{"kind":"tighten","target":target.id,"text":"收紧拘束具","delayed":false})
  completed+=1
 if completed<p.budget: g._emit("event",e.name+"加固了%d档拘束具，剩余%d档没有可用目标。" % [completed,p.budget-completed])

static func carried_intents(g, e: Dictionary) -> Array:
 var definitions=g.Enemies.TYPES[e.type].carried_composites
 var options=[]
 for index in e.carried_indices:
  var plan={"kind":"apply","pool":"composite","templates":[definitions[index].duplicate(true)],"grade":2,"tier":2,"count":1,"carried_index":index,"text":"施加盒内复合装备","delayed":false}
  options.append(plan)
 return options

static func carried_application(g, e: Dictionary) -> Dictionary:
 var options=carried_intents(g,e).filter(func(plan):return g.Application.can_apply(g,application_spec(g,e,plan),e.id))
 return {} if options.is_empty() else options[g._random_index("enemy",options.size())]

static func carried_reason(g, e: Dictionary) -> String:
 var definition=g.Enemies.TYPES[e.type]
 if not definition.has("carried_composites"): return "" if not e.has("carried_indices") else "该敌人没有备用复合装备。"
 if not e.get("carried_indices") is Array: return "敌人的备用装备清单不完整。"
 var seen=[]
 for index in e.carried_indices:
  if not index is int or index<0 or index>=definition.carried_composites.size() or index in seen: return "敌人的备用装备清单不合法。"
  seen.append(index)
 return ""
