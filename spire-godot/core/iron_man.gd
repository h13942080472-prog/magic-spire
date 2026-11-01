extends RefCounted
const RestraintValue=preload("res://data/restraint_value.gd")

const Replacement=preload("res://core/equipment_replacement.gd")
const Bind=preload("res://core/capture_bind.gd")

const CYCLE_LENGTH=5
const ENERGY_THRESHOLD=5
const DRONE_ENERGY_THRESHOLD=3
const CAPTURE_GAIN=10.0
const DRONE_CAPTURE_GAIN=5.0
const LEATHER_POOL=["belt","fine_belt","eye_leather","mouth_band"]
const TAPE_POOL=["tape","eye_tape","mouth_tape"]
const COMPOSITE_POOL=["glove","leg"]
const CUP_STAGES=[
 {"type":"glans_cup_medium","tier":2},
 {"type":"full_cup_medium","tier":2},
 {"type":"full_cup_medium","tier":3},
 {"type":"urethral_full_cup_medium","tier":3},
 {"type":"urethral_full_cup_high","tier":3}]

static func initialize(e: Dictionary) -> void:
 e.iron_enhancements=0
 e.iron_stun_turns=0
 e.iron_armor_break_turns=0
 e.iron_support_ids=[]

static func link_supports(enemies: Array) -> void:
 var bosses=enemies.filter(func(e):return e.type=="iron_man")
 if bosses.is_empty(): return
 var boss=bosses[0]
 boss.iron_support_ids=enemies.filter(func(e):return e.id!=boss.id and e.type in ["iron_drone","binding_box"]).map(func(e):return e.id)

static func capture_start(e: Dictionary) -> float:
 return 30.0+5.0*int(e.get("iron_enhancements",0))

static func cup_spec(e: Dictionary) -> Dictionary:
 return CUP_STAGES[mini(int(e.get("iron_enhancements",0)),CUP_STAGES.size()-1)].duplicate()

static func fallback_spec(e: Dictionary) -> Dictionary:
 var level=int(e.get("iron_enhancements",0))
 return {"grade":3 if level>=3 else 2,"tier":3 if level>=1 else 2,"count":3+(1 if level>=2 else 0)+maxi(0,level-3)}

static func _upgrade_count(total: int, index: int) -> int:
 if total<index: return 0
 return 1+int((total-index)/4)

static func modifiers(e: Dictionary) -> Dictionary:
 var total=int(e.get("iron_enhancements",0))
 var first=_upgrade_count(total,1)
 var second=_upgrade_count(total,2)
 var third=_upgrade_count(total,3)
 var fourth=_upgrade_count(total,4)
 return {
  "grade":second,
  "tier":first,
  "ordinary":first+second+fourth,
  "reinforce":2*(first+second+fourth),
  "special":third+fourth,
  "locks":2*third+fourth}

static func intent_facts(e: Dictionary, state: Dictionary) -> Dictionary:
 if Bind.capture_ready(state): return {"kind":"capture"}
 if e.iron_stun_turns>0: return {"kind":"iron_stunned"}
 if e.stage==1: return {"kind":"bind_apply"}
 var mods=modifiers(e)
 match (e.stage-2)%CYCLE_LENGTH:
  0: return {"kind":"iron_bind_gain"}
  1:
   var count=2+mods.ordinary
   var grade=mini(3,2+mods.grade)
   var tier=mini(3,2+mods.tier)
   return {"kind":"iron_restraints","count":count,"grade":grade,"tier":tier,"reinforce":mods.reinforce}
  2:
   var grade=mini(3,2+mods.grade)
   var tier=mini(3,2+mods.tier)
   return {"kind":"iron_composite","grade":grade,"tier":tier,"special":mods.special,"locks":mods.locks}
  3: return {"kind":"iron_recharge"}
  _: return {"kind":"iron_upgrade"}

static func plan(g, e: Dictionary) -> Dictionary:
 var facts=intent_facts(e,g.state)
 var text=""
 match facts.kind:
  "capture": text="执行收押"
  "iron_stunned": text="机械减伤失效 · 发呆"
  "bind_apply": text="施加捕缚 · 初始%s/100" % g.number(capture_start(e))
  "iron_bind_gain": text="捕缚＋%s" % g.number(CAPTURE_GAIN) if g.CaptureBind.has_bind(g,"iron_man") else "重新施加捕缚 · 初始%s/100" % g.number(capture_start(e))
  "iron_restraints":
   var profiles=RestraintValue.profiles(RestraintValue.from_profile(facts.grade,facts.tier))
   var options=profiles.map(func(p):return "%s%d档" % [g.Equipment.GRADES[p.grade],p.tier])
   text="施加%d件皮革拘束具 · %s" % [facts.count,"／".join(options)]
   if facts.reinforce>0: text+=" · 加固%d档" % facts.reinforce
  "iron_composite": text="施加%s%d档复合皮革拘束具%s%s" % [g.Equipment.GRADES[facts.grade],facts.tier," · 特殊装备×%d" % facts.special if facts.special>0 else ""," · 上锁×%d" % facts.locks if facts.locks>0 else ""]
  "iron_recharge": text="佩戴／替换特殊装备 · 补满电量"
  "iron_upgrade": text="强化捕缚系统"
 facts.text=text;facts.delayed=false
 return facts

static func installation_intents(g, e: Dictionary) -> Array:
 var mods=modifiers(e)
 var grade=mini(3,2+mods.grade)
 var tier=mini(3,2+mods.tier)
 var ordinary=g.EnemyPlans.application(LEATHER_POOL,grade,tier,2+mods.ordinary,false,RestraintValue.from_profile(grade,tier))
 ordinary.replace=true;ordinary.shoulders=true;ordinary.tighten_missing=true
 var composite={"kind":"apply","pool":"composite","templates":COMPOSITE_POOL.duplicate(),"grade":mini(3,2+mods.grade),"tier":mini(3,2+mods.tier),"count":1,"locked":false,"final":false,"replace":true,"text":"施加复合皮革拘束具","delayed":false}
 var result=[ordinary,composite]
 composite.tighten_missing=true
 if mods.special>0:
  result.append({"kind":"apply","pool":"special","templates":g.SpecialEquipment.prison_pool(3,true,false),"grade":3,"tier":3,"count":mods.special,"locked":false,"final":false,"replace":true,"text":"佩戴高级特殊装备","delayed":false})
 return result

static func execute(g, e: Dictionary, intent: Dictionary) -> void:
 match intent.kind:
  "iron_stunned":
   g._emit("event",e.name+"的捕缚系统失灵，本回合停在原地。")
  "iron_bind_gain":
   if g.CaptureBind.has_bind(g,"iron_man"): g.CaptureBind.gain_bind(g,CAPTURE_GAIN,e.name+"的捕缚")
   else: g.CaptureBind.apply_bind(g,e)
  "iron_restraints":
   g._enemy_operation(e,installation_intents(g,e)[0])
   if intent.reinforce>0: g.EnemyPlans.execute_tighten_budget(g,e,{"budget":intent.reinforce})
  "iron_composite":
   var plans=installation_intents(g,e)
   g._enemy_operation(e,plans[1])
   if intent.special>0:
    g._enemy_operation(e,plans[2])
   for i in range(intent.locks): g._enemy_operation(e,{"kind":"lock","text":"随机上锁","random_target":true,"delayed":false})
  "iron_recharge": recharge(g,e)
  "iron_upgrade": upgrade(g,e)

static func apply_capture_equipment(g, e: Dictionary) -> void:
 var cursed=g.state.special_equipment.any(g.SpecialEquipment.is_cursed_plate)
 if g.Character.active(g) or cursed:
  var spec=fallback_spec(e)
  var pool=g.SpecialEquipment.prison_pool(spec.grade,false,false)
  var plan={"kind":"apply","pool":"special","templates":pool,"grade":spec.grade,"tier":spec.tier,"count":spec.count,"locked":false,"final":false,"replace":true,"text":"佩戴／替换特殊装备","delayed":false}
  g._enemy_operation(e,plan)
  return
 var spec=cup_spec(e)
 var replaced=Replacement.force_special(g,spec.type,spec.tier,e.name+"的捕缚")
 if replaced.ok:
  g._emit("event",e.name+"佩戴／替换了"+g.SpecialEquipment.TYPES[spec.type].name+"，紧度%d档。" % spec.tier,{"iron_capture_equipment":{"enemy":e.id,"installed":replaced.installed[0].id,"removed":replaced.removed}})

static func active_special(g) -> Array:
 return g.state.special_equipment.filter(func(item):
  if item.durability<=0 or item.remaining<=0 or g.SpecialEquipment.is_reinforcement(item): return false
  var spec=g.SpecialEquipment.TYPES[item.type]
  return spec.duration>0 and (spec.energy_gain>0 or spec.turn_gain>0))

static func energy_trigger(g, e: Dictionary) -> void:
 for item in active_special(g).duplicate(): g._remote_special(item,e.name+"的捕缚",false)

static func drone_energy_trigger(g, drone: Dictionary) -> void:
 g._enemy_operation(drone,g.EnemyPlans.application(TAPE_POOL,1,2,1,false,3))
 g.CaptureBind.gain_bind(g,DRONE_CAPTURE_GAIN,drone.name+"的捕缚")
 var powered=active_special(g)
 if not powered.is_empty():
  var item=powered[g._random_index("enemy",powered.size())]
  g._remote_special(item,drone.name+"遥控",true)
 g._enemy_operation(drone,{"kind":"lock","text":"随机上锁","random_target":true,"delayed":false})

static func recharge(g, e: Dictionary) -> void:
 apply_capture_equipment(g,e)
 var count=0
 for item in g.state.special_equipment:
  var duration=int(g.SpecialEquipment.TYPES[item.type].duration)
  if duration<=0 or item.remaining>=duration: continue
  item.remaining=duration;count+=1
 g._emit("event",e.name+"补满了%d件特殊装备的电量。" % count)

static func upgrade(g, e: Dictionary) -> void:
 e.iron_enhancements+=1
 var index=(e.iron_enhancements-1)%4+1
 g._emit("event",e.name+"强化升至%d层：此后捕缚值＋5，并获得第%d组强化。" % [e.iron_enhancements,index],{"iron_upgrade":{"enemy":e.id,"total":e.iron_enhancements,"kind":index}})

static func capture_removed(g) -> void:
 for e in g.state.enemies:
  if e.type!="iron_man" or e.gone: continue
  e.iron_enhancements=maxi(0,e.iron_enhancements-1)
  e.iron_stun_turns=maxi(e.iron_stun_turns,1)
  e.iron_armor_break_turns=maxi(e.iron_armor_break_turns,2)
  e.intent=plan(g,e)
  g._emit("event",e.name+"的捕缚系统被破坏：强化降至%d层，机械减伤失效2回合，并将在下一次行动时发呆。" % e.iron_enhancements)

static func begin_enemy_turn(e: Dictionary) -> void:
 if e.type=="iron_man" and e.iron_armor_break_turns>0: e.iron_armor_break_turns-=1

static func finish_turn(e: Dictionary, intent: Dictionary) -> bool:
 if e.type!="iron_man": return true
 if intent.kind=="iron_stunned":
  e.iron_stun_turns=maxi(0,e.iron_stun_turns-1)
  return false
 return true

static func armor_disabled(g, type: String) -> bool:
 if type!="iron_man": return false
 return g.state.enemies.any(func(e):return e.type==type and not e.gone and e.get("iron_armor_break_turns",0)>0)

static func defeat_supports(g, e: Dictionary) -> void:
 if e.type!="iron_man": return
 for id in e.iron_support_ids:
  var support=g._enemy(id)
  if support.is_empty() or support.gone: continue
  support.gone=true;support.defeated=true;support.hp=0;support.intent={}
  g._emit("event",support.name+"随铁男停机。")

static func validate(g, e: Dictionary, enemies: Array=[], snapshot: Dictionary={}) -> String:
 if e.type!="iron_man":
  for key in ["iron_enhancements","iron_stun_turns","iron_armor_break_turns","iron_support_ids"]:
   if e.has(key): return "非铁男敌人带有铁男专属记录。"
  return ""
 if not g.Snapshot.fields(e,"iron_enhancements:i iron_stun_turns:i iron_armor_break_turns:i iron_support_ids:z"): return "铁男强化记录缺损。"
 if e.iron_enhancements<0 or e.iron_stun_turns not in [0,1] or e.iron_armor_break_turns<0 or e.iron_armor_break_turns>2: return "铁男强化或破甲回合有误。"
 var expected_enhancements=0 if e.stage==1 else int((e.stage-2)/CYCLE_LENGTH)
 if e.iron_enhancements>expected_enhancements: return "铁男强化次数与行动阶段存在差异。"
 var roster=g.state.enemies if enemies.is_empty() else enemies
 if e.iron_support_ids.size()!=2 or e.iron_support_ids[0]==e.iron_support_ids[1] or e.iron_support_ids.any(func(id):
  var matches=roster.filter(func(enemy):return enemy.id==id)
  var support={} if matches.is_empty() else matches[0]
  return support.is_empty() or support.type not in ["iron_drone","binding_box"]): return "铁男随行单位记录有误。"
 var support_types=e.iron_support_ids.map(func(id):return roster.filter(func(enemy):return enemy.id==id)[0].type)
 support_types.sort()
 if support_types!=["binding_box","iron_drone"]: return "铁男随行单位类型缺损。"
 var current_state=g.state if snapshot.is_empty() else snapshot
 # Completed battles retain the last announced intent, not a live cycle prediction.
 if current_state.phase=="battle" and not e.gone and not e.intent.is_empty():
  var expected=intent_facts(e,current_state)
  if e.intent.get("kind","")!=expected.get("kind",""): return "铁男意图与当前行动阶段存在差异。"
  for key in ["count","grade","tier","reinforce","special","locks"]:
   if e.intent.has(key)!=expected.has(key) or (expected.has(key) and e.intent[key]!=expected[key]): return "铁男意图数值与当前强化阶段存在差异。"
 return ""
