extends RefCounted

const Value=preload("res://data/restraint_value.gd")
const Enchantments=preload("res://core/equipment_enchantments.gd")
const TYPE="reinforced_rope"
const Moves=["single","scatter","strengthen"]
const ActionSpecs={"single":{"count":1,"value":4,"name":"凝绳缚"},"scatter":{"count":3,"value":2,"name":"分绳缚"}}
const MAX_VALUE=6
const DEPARTURE_AT=3

static func initialize(e: Dictionary) -> void:
 e.rope_previous=""
 e.rope_strength=0

static func selectable(e: Dictionary) -> Array:
 return ["depart"] if e.rope_strength==DEPARTURE_AT else Moves.filter(func(move):return move!=e.rope_previous)

static func plan(g, e: Dictionary) -> Dictionary:
 var options=selectable(e)
 return declaration(g,e,options[0] if options.size()==1 else options[g._random_index("enemy",options.size())])

static func application(g, count: int, value: int, final: bool=false) -> Dictionary:
 var pool=g.Enemies.TYPES[TYPE].install_pool
 return g.EnemyPlans.application(pool,1,1,count,final,value)

static func declaration(g, e: Dictionary, move: String) -> Dictionary:
 var result={"kind":"charge","text":"强化绳索","delayed":false}
 if ActionSpecs.has(move):
  var base=ActionSpecs[move]
  var value=base.value+e.rope_strength
  var count=base.count+maxi(0,value-MAX_VALUE)
  result=application(g,count,mini(value,MAX_VALUE))
  var profiles=result.profiles.map(func(p):return "%s%d档" % [g.Equipment.GRADES[p.grade],p.tier])
  result.text="%s · %d件拘束具 · %s" % [base.name,count,"／".join(profiles)]
 elif move=="depart": result={"kind":"leave","text":"附加收紧绳索并离场","delayed":false}
 elif e.rope_strength==DEPARTURE_AT-1: result.text="准备附着离场"
 result.rope_move=move
 return result

static func installations(g, e: Dictionary) -> Array:
 return [declaration(g,e,"single"),declaration(g,e,"scatter"),application(g,1,MAX_VALUE,true)]

static func resolve(g, e: Dictionary, intent: Dictionary) -> void:
 e.rope_previous=intent.rope_move
 if intent.rope_move=="strengthen":
  e.rope_strength+=1
  g._enemy_preparation(e,"准备附着离场。" if e.rope_strength==DEPARTURE_AT else "强化了绳索。")

static func fallback(g) -> Dictionary:
 var best={}
 var best_value=-1
 var best_priority=-1
 for item in g.state.equipment:
  if not Enchantments.eligible(g,item): continue
  var value=Value.from_profile(item.grade,g.equipment_tier(item))
  var priority=g.Equipment.slot_priority(item.slot)
  if value>best_value or (value==best_value and priority>best_priority):
   best=item
   best_value=value
   best_priority=priority
 return best

static func depart(g, e: Dictionary) -> void:
 var spec=g.EnemyPlans.application_spec(g,e,application(g,1,MAX_VALUE,true))
 var result=g.Application.execute(g,spec,e.id)
 var item={}
 if result.ok:
  item=g._equipment(result.installed[0].id)
  g._emit("event",e.name+"施加了"+item.name+"。",{"equipment":item.id,"installed_name":item.name})
 elif result.evaded==0:
  item=fallback(g)
 Enchantments.attach(g,item,Enchantments.TIGHTEN,e.name)

static func issue(g, e: Dictionary) -> String:
 if e.type!=TYPE:
  return "敌人没有强化绳索记录。" if e.has("rope_strength") or e.has("rope_previous") or e.intent.has("rope_move") else ""
 if not e.get("rope_strength") is int or e.rope_strength<0 or e.rope_strength>DEPARTURE_AT or not e.get("rope_previous") is String: return "强化绳索记录有误。"
 if e.rope_previous not in ["","depart"]+Moves or (e.rope_previous=="depart" and not e.gone): return "强化绳索行动记录有误。"
 if e.intent.is_empty(): return ""
 var move=e.intent.get("rope_move","")
 if move not in selectable(e): return "强化绳索预告行动有误。"
 var expected=declaration(g,e,move)
 expected.delayed=e.intent.get("delayed",false)
 return "" if e.intent==expected else "强化绳索预告规格有误。"
