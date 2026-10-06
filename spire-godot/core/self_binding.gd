extends RefCounted

static func toy_spec(g) -> Dictionary:
 return {"pool":"special","templates":g.SpecialEquipment.RANDOM_POOLS[1],"grade":1,"tier":2,"count":1,"replace":false}

# Internal X-card effect. Installation and tightening retain the existing factories.
const Rules=preload("res://data/card_rules.gd")

static func spec(type: String) -> Dictionary:
 return Rules.SPECS[type].self_binding

static func options(g, type: String, x: int) -> Array:
 var result=[]
 var rule=spec(type)
 for grade in g.Equipment.GRADES:
  var tier=rule.tighten_per_x*x-int(grade)
  if tier not in [1,2,3]: continue
  result.append_array(install_options(g,grade,tier,rule.slots,rule.templates))
 return result

static func install_options(g, grade: int, tier: int, slots: Array=[], templates: Array=[]) -> Array:
 var result=[]
 for request in g.EquipmentOffers.ordinary(g,grade,false,templates):
  if not slots.is_empty() and request.slot not in slots: continue
  request.grade=grade;request.tier=tier;request.locked=false;request.variant=0
  result.append(request)
 return result

static func install(g, request: Dictionary, source: String) -> Dictionary:
 var variants=g.Equipment.MATERIALS[g.Equipment.TEMPLATES[request.template].material][request.grade]
 request.variant=g._random_index("equipment",variants.size())
 return g.Application.execute_concrete(g,request,source,false,[],true)

# Only accept first choices that leave room for the second. Preview uses no random
# selection, and restores state plus feedback before returning detached requests.
static func installation_plan(g, type: String, x: int, randomize: bool=false) -> Array:
 var choices=options(g,type,x)
 while not choices.is_empty():
  var first=choices.pop_at(g._random_index("equipment",choices.size()) if randomize else 0)
  var original=g.state
  var feedback=g._resource_feedback
  g.state=original.duplicate(true);g._resource_feedback=null
  var outcome=g.Application.execute_concrete(g,first,type,false,[],true)
  var remaining=options(g,type,x) if outcome.ok else []
  g.state=original;g._resource_feedback=feedback
  if not remaining.is_empty():
   var second=remaining[g._random_index("equipment",remaining.size()) if randomize else 0]
   return [first.duplicate(true),second.duplicate(true)]
 return []

# docs/spec/equipment-query-seam.md「作用域进出点（冻结名单）」: both leaves read through one scope; speculation swaps state, so the identity
# check in _equipment_read_active() bypasses the batch by itself.
static func tighten_targets(g) -> Array:
 var previous=g._begin_equipment_read()
 var targets=g.physical_pieces().filter(func(item):return item.durability>0 and g.tier(item.durability,item.maximum)<3 and g._can_tighten(item))
 g._equipment_read=previous
 return targets

static func capacity(g) -> int:
 var previous=g._begin_equipment_read()
 var result=0
 for item in tighten_targets(g): result+=3-g.tier(item.durability,item.maximum)
 g._equipment_read=previous
 return result

static func reason(g, p: Dictionary) -> String:
 var x=int(p.get("x",0))
 var required=spec(p.type).tighten_per_x*x
 if p.free:
  if required<2 or required>6: return "当前X＝%d，没有品质＋紧度＝%d的拘束具。" % [x,required]
  if installation_plan(g,p.type,x).is_empty(): return "腿部没有足够位置完整佩戴2件符合要求的拘束具。"
 else:
  var available=capacity(g)
  if available<required: return "需要收紧%d档，当前最多只能收紧%d档；无法完整执行。" % [required,available]
 return ""

static func detail(g, p: Dictionary) -> String:
 var x=int(p.get("x",0))
 return "当前X＝%d：%s随后恢复%d自身魔力。" % [x,("每件品质＋紧度＝%d。" % (spec(p.type).tighten_per_x*x)) if p.free else ("随机收紧共%d档，不上锁。" % (spec(p.type).tighten_per_x*x)),spec(p.type).mana_per_x*x]

static func resolve(g, p: Dictionary) -> void:
 var x=int(p.x)
 var rule=spec(p.type)
 var changes=[]
 if p.free:
  var plan=installation_plan(g,p.type,x,true)
  assert(plan.size()==2,"Self-binding must have a complete legal pair before payment")
  for request in plan:
   var applied=install(g,request,p.type)
   assert(applied.ok and applied.count==1,"Self-binding installation changed inside its transaction")
   var item=applied.installed[0]
   changes.append({"id":item.id,"grade":item.grade,"tier":g.tier(item.durability,item.maximum)})
   g._emit("event","自缚：在%s佩戴%s（%s，紧度%d档）。" % [g.B.SLOT_NAMES[item.slot],item.name,g.Equipment.GRADES[item.grade],g.tier(item.durability,item.maximum)],{"self_binding_install":changes.back()})
 else:
  for step in range(rule.tighten_per_x*x):
   var targets=tighten_targets(g)
   assert(not targets.is_empty(),"Self-binding requires the entire tightening capacity")
   var item=targets[g._random_index("equipment",targets.size())]
   var before=g.tier(item.durability,item.maximum)
   g._reinforce_equipment(item)
   changes.append({"id":item.id,"before":before,"after":g.tier(item.durability,item.maximum)})
   g._emit("event","自缚：%s紧度%d → %d档。" % [item.name,before,g.tier(item.durability,item.maximum)],{"self_binding_tighten":changes.back()})
 var mana_before=g.state.mana
 g.state.mana=minf(g.state.mana_max,g.state.mana+rule.mana_per_x*x)
 g._emit("event","自缚：X＝%d，恢复%s自身魔力。" % [x,g.number(g.state.mana-mana_before)],{"card":p.type,"free":p.free,"x":x,"mana_gain":g.state.mana-mana_before,"self_binding":changes})
