extends RefCounted

const TYPE="binding_box_plus"
const CURSE="spell_curse"
const DISRUPT="disrupt"
const FATIGUE="disrupt_draw"
const CYCLE=["plus_curse","plus_double","plus_boost","plus_fit","plus_tough"]
const NEXT=[1,2,3,4,1]
const Actions={
 "plus_curse":"喘息咒印 · 施加法术诅咒",
 "plus_double":"贴身双缚 · 施加两件拘束具",
 "plus_boost":"兴致升温 · 强化接下来三个回合的拘束具",
 "plus_fit":"嘴腿都照顾 · 嘴部优先、性玩具、腿部",
 "plus_tough":"绑紧别乱动 · 施加带「坚韧」的拘束具",
}

static func initialize(e: Dictionary) -> void:
 e.plus_step=0
 e.plus_boost_until=0

static func plan(g, e: Dictionary) -> Dictionary:
 var move=CYCLE[e.plus_step]
 if e.plus_step in [1,3,4] and e.plus_boost_until>0 and e.plus_boost_until<g.state.round:
  move="plus_boost"
 return {"kind":move,"text":Actions[move],"delayed":false}

static func boosted(g, e: Dictionary) -> bool:
 return e.plus_boost_until>0 and g.state.round<=e.plus_boost_until

static func boost_left(g, e: Dictionary) -> int:
 return maxi(0,e.plus_boost_until-g.state.round+(0 if e.get("acted_round",-1)==g.state.round else 1)) if e.plus_boost_until>0 else 0

static func ordinary(g, value: int, count: int=1) -> Dictionary:
 var spec=g.EnemyPlans.application(g.Enemies.TYPES[TYPE].install_pool,1,3,count,false,value)
 spec.allow_links=false
 return spec

static func installations(g, e: Dictionary) -> Array:
 return [ordinary(g,4),ordinary(g,5),g.EnemyPlans.special_application(g,e)]

static func execute(g, e: Dictionary, move: String) -> void:
 var value=5 if boosted(g,e) else 4
 if move!="plus_boost" or e.plus_step==2:
  e.plus_step=3 if move=="plus_double" and e.plus_boost_until>0 else NEXT[e.plus_step]
 match move:
  "plus_curse":
   g.Cards.grant_buff(g,CURSE)
   g._emit("event","%s施加了「法术诅咒」。" % e.name,{"spell_curse":e.id})
  "plus_boost":
   e.plus_boost_until=g.state.round+3
   g._enemy_preparation(e,"兴致升温：接下来三个回合强化施加的拘束具。")
  "plus_double": g._enemy_operation(e,ordinary(g,value,2))
  "plus_fit":
   var mouth=ordinary(g,value);mouth.preferred_slots=["mouth"]
   g._enemy_operation(e,mouth)
   var special=g.EnemyPlans.special_application(g,e)
   var available=g.Application.can_apply(g,g.EnemyPlans.application_spec(g,e,special),e.id)
   g._enemy_operation(e,special if available else ordinary(g,value))
   var legs=ordinary(g,value);legs.required_slots=g.B.LEG_SLOTS.duplicate()
   g._enemy_operation(e,legs)
  "plus_tough":
   var spec=ordinary(g,value)
   spec.profiles=[{"grade":value-3,"tier":3}]
   spec.enchantment=g.EquipmentEnchantments.TOUGH
   g._enemy_operation(e,spec)

static func depart(g, e: Dictionary) -> void:
 var previous=g.state.security
 g.Prison.raise_security(g)
 var text="%s吹哨告状，警戒度升至%d级。" % [e.name,g.state.security] if g.state.security>previous else "%s吹哨告状，警戒度已达上限。" % e.name
 g._emit("event",text,{"security_departure":{"enemy":e.id,"from":previous,"to":g.state.security}})

static func valid_intent(p: Dictionary) -> bool:
 return Actions.has(p.kind) and p.text==Actions[p.kind] and p.size()==3

static func issue(e: Dictionary, round_index: int) -> String:
 var kind=e.intent.get("kind","")
 if e.type!=TYPE:
  return "该敌人没有拘束盒 Plus 记录。" if e.has("plus_step") or e.has("plus_boost_until") or Actions.has(kind) else ""
 if not e.get("plus_step") is int or e.plus_step<0 or e.plus_step>=CYCLE.size(): return "拘束盒 Plus 行动记录有误。"
 if not e.get("plus_boost_until") is int or e.plus_boost_until<0 or e.plus_boost_until>round_index+3 or (e.plus_step in [0,2] and e.plus_boost_until!=0) or (e.plus_step in [3,4] and e.plus_boost_until==0): return "拘束盒 Plus 升温记录有误。"
 if e.intent.is_empty(): return ""
 if not valid_intent(e.intent): return "拘束盒 Plus 预告有误。"
 if kind==CYCLE[e.plus_step]: return ""
 if kind=="plus_boost" and e.plus_step in [1,3,4] and e.plus_boost_until>0 and e.plus_boost_until<round_index: return ""
 return "拘束盒 Plus 预告顺序有误。"
