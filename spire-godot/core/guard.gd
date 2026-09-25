extends RefCounted

const E=preload("res://data/equipment.gd")
const B=preload("res://data/balance.gd")

const Bind=preload("res://core/capture_bind.gd")
const Plans=preload("res://core/enemy_plans.gd")
const ENERGY_PLEASURE=10.0

static func initial() -> Dictionary:
 return {"bind_ready":false,"cycle_step":0}

static func energy_spent(g) -> void:
 var slots=g.SpecialEquipment.slots()
 var slot=slots[g._random_index("capture_bind",slots.size())]
 var base=ENERGY_PLEASURE
 var sensitivity=float(g.SpecialEquipment.SENSITIVITY[slot])
 g.Pressure.gain(g,base*sensitivity,"捕缚牵动"+g.SpecialEquipment.slot_name(slot)+"（%s×%s）" % [g.number(base),g.number(sensitivity)])

static func ordinary_templates() -> Array:
 return E.TEMPLATES.keys().filter(func(id):return id!="eye_cloth" and not E.TEMPLATES[id].slots.is_empty())

static func application(templates: Array, count: int=1, required_slots: Array=[]) -> Dictionary:
 var plan=Plans.application(templates,2,2,count)
 plan.replace=true;plan.shoulders=true;plan.text="施加中级拘束具 · 2档"
 if not required_slots.is_empty():
  plan.required_slots=required_slots.duplicate()
  plan.shoulders=false
  plan.tighten_missing=true
 return plan

static func opening() -> Dictionary:
 var ordinary=ordinary_templates()
 return sequence([
  application(ordinary,1,["wrist"]),
  application(["mouth_band","mouth_tape"],1,["mouth"]),
  application(ordinary,1,["ankle"])],"分别束住手腕、口部与脚踝")

static func composite_or_reinforce(g, e: Dictionary) -> Dictionary:
 var composite={"kind":"apply","pool":"composite","templates":[],"grade":2,"tier":2,"count":1,"replace":true,"locked":false,"final":false,"text":"施加一件中级复合拘束具 · 2档","delayed":false}
 if g.Application.can_apply(g,g.EnemyPlans.application_spec(g,e,composite),e.id): return composite
 return reinforcement(g,e)

static func reinforcement(g, e: Dictionary) -> Dictionary:
 var fallback=g.EnemyPlans.batch(g,e,2,2,3,true,ordinary_templates())
 fallback.text="复合拘束无法安装，改为加固两件拘束具至3档"
 return fallback

static func build(g, e: Dictionary) -> Dictionary:
 if Bind.required_intent(g,e)=="capture":
  return {"kind":"capture","text":"执行收押","delayed":false}
 if e.stage==1: return opening()
 if not Bind.has_bind(g,"guard"):
  if e.guard.bind_ready: return {"kind":"bind_apply","text":"施加捕缚 · 初始50/100","delayed":false}
  return {"kind":"bind_prepare","text":"准备捕缚 · 1回合","delayed":false}
 match int(e.guard.cycle_step)%3:
  0:
   var plan=application(ordinary_templates(),2)
   plan.text="随机施加两件中级拘束具 · 2档"
   return plan
  1: return {"kind":"bind_gain","text":"捕缚进度＋10","delayed":false}
  _: return composite_or_reinforce(g,e)

static func sequence(operations: Array, text: String) -> Dictionary:
 return {"kind":"guard_sequence","operations":operations,"priority":false,"text":text,"delayed":false}

static func execute(g, e: Dictionary, intent: Dictionary) -> void:
 match intent.kind:
  "bind_prepare":
   e.guard.bind_ready=true
   g._enemy_preparation(e,"准备捕缚。")
  "bind_apply": Bind.apply_bind(g,e)
  "bind_gain": Bind.gain_bind(g,Bind.BIND_GAIN,e.name)
  "capture": capture(g,e)
  "guard_sequence":
   for operation in intent.operations:
    if g.state.phase!="battle": break
    var current=operation.duplicate(true)
    # Earlier saves may already contain the announced opening without fallback.
    if e.stage==1 and current.kind=="apply" and not current.get("required_slots",[]).is_empty(): current.tighten_missing=true
    g._enemy_operation(e,current)
  _:
   var operation=intent
   if intent.kind=="apply" and intent.get("pool","")=="composite" and not g.Application.can_apply(g,g.EnemyPlans.application_spec(g,e,intent),e.id):
    operation=reinforcement(g,e)
   g._enemy_operation(e,operation)
 if Bind.has_bind(g,"guard") and intent.kind in ["apply","bind_gain","equipment_batch"]:
  e.guard.cycle_step=(int(e.guard.cycle_step)+1)%3

static func capture(g, captor: Dictionary) -> void:
 if g.state.phase!="battle": return
 Bind.clear_bind(g)
 g.state.security=mini(5,g.state.security+1)
 g.state.prison={}
 var retained=g.equipment_targets().map(func(e):return e.id)
 var retained_special=g.state.special_equipment.map(func(e):return e.id)
 var confiscated=g.state.items.size()
 g.state.items=g.state.items.filter(func(item):return g.Tools.TYPES[item.type].get("keep_on_capture",false))
 confiscated-=g.state.items.size()
 for card in g.state.hand: card.retain_until=-1
 g._discard_end()
 g.Cards.purge_temporary(g)
 g._clear_charge()
 for buff in ["temporary_mana","next_energy"]: g.state[buff]=0
 g.state.sure_cast=false
 g.Cards.end_powers(g)
 g.state.card_buffs.clear()
 g.state.card_buff_uses.clear()
 g.Pressure.clear_penalties(g)
 g.RelicEffects.clear_temporary(g)
 g.RelicEffects.end_combat(g)
 g.state.next_energy=0
 g._apply_transition("battle_end_captured",{"phase":"captured"});g.state.energy=0;g.state.weakness_turns=0
 g.state.prepare_left=0;g.state.rest_left=0;g.state.hook_uses=0
 if g.room_data("prison").is_empty():
  g.state.rooms.append({"id":"prison","name":"监狱接收室","kind":"prison","wall":"rough","next":[],"floor":-1,"lane":0.5})
 g._apply_transition("battle_end_captured",{"room":"prison"});g.state.wall="rough";g.state.wall_distance=0
 g.Pressure.cleanup(g)
 var spec=g.Prison.equipment_spec(g,0)
 var intake=g.Prison.intake_equipment(g)
 var added=intake.added
 var special_added=intake.special_added
 var links=[]
 for i in range(mini(3,g.state.security)):
  var pool=g.EquipmentOffers.links(g,spec.grade)
  if pool.is_empty(): break
  var pair=pool[g._random_index("equipment",pool.size())]
  var rope=g._install_link(pair.ends[0],pair.ends[1],E.maximum(spec.grade)*[0.0,0.4,0.8,1.0][spec.tier],"prison",spec.grade,[],pair.slots,pair.contact_points)
  if not rope.is_empty(): links.append(rope.id)
 var installed_links=g.state.links.filter(func(link):return link.id in links)
 var climax=g.Prison.intake_climax(g)
 var scene=g.Prison.intake_scene(g,intake,installed_links,climax)
 g.state.capture={"by":captor.name,"security":g.state.security,"retained":retained,"added":added,"links":links,"retained_special":retained_special,"special_added":special_added,"special_baseline":g.state.special_equipment.map(func(e):return e.id),"confiscated":confiscated,"baseline":g.equipment_targets().map(func(e):return e.id),"intake_scene":scene}
 g._emit("event","收押完成：警戒度%d；没收道具%d件；新增拘束具%d件、连接绳%d条、性玩具%d件；榨取%s魔力。" % [g.state.security,confiscated,added.size(),links.size(),special_added.size(),g.number(climax.mana_lost)]+(" 已戴上限制项圈。" if intake.collar_added else ""),{"prison_intake":intake,"prison_intake_climax":climax})

 g.RelicEffects._mana_hook(g,"prison_entry_mana","进入监狱")

static func validate(g) -> String:
 if g.state.security<0 or g.state.security>5: return "监狱安全等级超出范围。"
 var bind_issue=Bind.validate(g)
 if bind_issue!="": return bind_issue
 for e in g.state.enemies:
  if Bind.kind(g,e)=="": continue
  if not e.has("guard") or not e.guard.get("bind_ready") is bool or not e.guard.get("cycle_step") is int or e.guard.cycle_step not in [0,1,2]: return "魅魔警卫行动进度不合法。"
  if e.intent.get("kind","")=="guard_sequence":
   if e.intent.operations.size() not in [1,2,3]: return "魅魔警卫连续行动数量不合法。"
   for op in e.intent.operations:
    if op.kind not in ["apply","install","assembly","shoulder","tighten","lock","idle"] or op.get("final",false): return "魅魔警卫连续行动只能包含不离场的装备操作。"
 if g.state.phase=="captured":
  if g.state.capture.is_empty() or g.state.capture.security!=g.state.security or g.state.room!="prison" or g.state.items.any(func(item):return not g.Tools.TYPES.get(item.type,{}).get("keep_on_capture",false)) or g.state.energy!=0: return "入狱结算不完整。"
  if g.state.capture.baseline!=g.equipment_targets().map(func(e):return e.id): return "入狱装备基准与实际装备不一致。"
  if g.state.capture.special_baseline!=g.state.special_equipment.map(func(e):return e.id): return "入狱性玩具清单与实际装备不一致。"
 return ""
