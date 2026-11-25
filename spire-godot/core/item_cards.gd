extends RefCounted

const Presentation=preload("res://core/item_presentation.gd")
const WALL_SLOTS={
 "stand":["shoulder","upper_arm","forearm","wrist","palm","fingers","thigh"],
 "sit":["forearm","wrist","palm","fingers","thigh","calf","ankle","foot","toes"],
 "lie":["shoulder","upper_arm","forearm","wrist","palm","fingers","calf","ankle","foot","toes"]}

static func register(g) -> void:
 if g.Cards.Rules.SPECS.has("shard"): return
 for type in g.Tools.TYPES:
  var item=g.Tools.TYPES[type]
  var op=g.Tools.operation(type)
  var cutter=op=="cut"
  var spec={"card_type":"item","rarity":"basic","cost":0,"mode":"tool","reward_excluded":true,"remove_uses":item.uses,"wall_face":cutter}
  if cutter: spec.wall_cost=1
  var terms=[]
  if op=="unlock": terms.append("unlock")
  if item.get("effect","") in ["charge","reserve_mana"]: terms.append(item.effect)
  spec.item_terms=terms
  g.Cards.Rules.SPECS[type]=spec
  g.B.CARD_NAMES[type]=item.name
  var value=Presentation.base_summary(g,type)
  g.B.CARD_INFO[type]=["道具",value,value,""]
  spec.item_conditions={"bound":conditions(item,false),"free":conditions(item,true)}

static func conditions(item: Dictionary, wall: bool, assisted: bool=false, outside: bool=false, posture: String="") -> Array:
 match item.get("operation","cut"):
  "cut":
   if assisted: return ["目标外露"]
   if not wall: return ["手指自由","目标外露且手可触及"]
   var ranges={"stand":"站姿：臂、手或大腿","sit":"坐姿：前臂至手或腿足","lie":"躺姿：臂、手或小腿至足"}
   var lines=[ranges[posture]] if ranges.has(posture) else ranges.values()
   return lines+["目标外露"]
  "unlock":
   return ["目标已上锁"] if assisted else ["腕指自由","目标已上锁且可触及","牢门前站立或坐下"]
 if item.get("unrestricted_use",false): return ["选择部位"]
 var result=[]
 if item.get("effect","")=="mana": result.append("魔力低于上限")
 if item.get("effect","")=="draw": result.append("牌堆有牌可抽")
 if item.get("effect","")=="sure_cast": result.append("行动回合 · 定咒空闲")
 if (outside or assisted) and item.category=="potion" and item.get("mouth_reduction",true): result.append("口部受限时药效减半")
 if assisted or outside: return result
 if item.category=="scroll": result.append("手指或脚趾可用")
 else:
  result.append("坐躺可饮；站姿需握持")
  result.append("站姿上肢拘束＜1")
  if item.get("mouth_reduction",true): result.append("口部受限时药效减半")
 return result

static func face_requirements(g, type: String) -> Dictionary:
 if g.RopeArt.hogtied(g): return {"bound":[g.RopeArt.HOGTIE_REASON],"free":[g.RopeArt.HOGTIE_REASON]}
 var item=g.Tools.TYPES[type]
 var assisted=g.Tools.assisted(g)
 var outside=g.Consumables.outside_battle(g,type)
 return {"bound":conditions(item,false,assisted,outside,g.state.posture),"free":conditions(item,true,assisted,outside,g.state.posture)}

static func outside_turn(g, card: Dictionary) -> bool:
 return not card.is_empty() and g.Tools.TYPES.get(card.type,{}).get("unrestricted_outside_battle",false) and g.state.phase not in ["battle","prepare","rest","prison","cleared","prison_end"] and g.state.card_chain.is_empty() and not g.state.pending_retain and g.command_domain_ready()

static func conversion(g, item: Dictionary) -> Dictionary:
 var reason="手牌已满。" if g.state.hand.size()>=g.B.HAND_LIMIT else ""
 return g._fact({"kind":"item_use","item":item.id,"target":"hand"},"使用","将这件道具加入手牌和卡组。",0,0.0,reason,"","item")

static func enemy_branch(g, spec: Dictionary) -> bool:
 return spec.has("enemy_max_degree") and g.restraint_degree("arms")<=spec.enemy_max_degree

static func sites(g, card: Dictionary) -> Array:
 var spec=g.Cards.Rules.SPECS[card.type]
 var tool=spec.get("cut_tool",card.type)
 var item=g.Tools.TYPES[tool]
 var targets=[]
 var op=g.Tools.operation(tool)
 var attacking=enemy_branch(g,spec)
 if attacking:
  if g.state.phase=="battle":
   for enemy in g.state.enemies:
    if not enemy.gone: targets.append({"id":enemy.id,"slot":""})
 elif op=="buff":
  if item.get("target_scope","")=="body_group":
   for group in g.Equipment.panel_groups(): targets.append({"id":group.id,"slot":group.slots[0]})
  else: targets.append({"id":"self","slot":""})
 else:
  for target in g.action_targets():
   if g.SpecialEquipment.is_special(target) and (op!="cut" or not g.SpecialEquipment.is_reinforcement(target)): continue
   targets.append({"id":target.id,"slot":target.slot})
  if op=="unlock" and g.state.phase=="prison": targets.append({"id":"prison_door","slot":"wrist"})
 var result=[]
 for target in targets:
  for wall in ([false,true] if op=="cut" and not attacking else [false]):
   var p={"kind":"card","uid":card.uid,"type":card.type,"slot":target.slot,"target":target.id,"free":wall,"mode":"unlock" if op=="unlock" else "tool"}
   if attacking: p.mode="enemy"
   if target.id=="self": p.self_target=true
   result.append({"family":"tool","base":p,"item":{},"enabled":false})
 return result

static func reason(g, p: Dictionary) -> String:
 if g.RopeArt.hogtied(g): return g.RopeArt.HOGTIE_REASON
 var spec=g.Cards.Rules.SPECS[p.type]
 if enemy_branch(g,spec):
  var enemy=g._enemy(p.target)
  if g.state.phase!="battle" or p.free or enemy.is_empty() or enemy.gone: return "请选择场上的敌人。"
  return g.enemy_target_reason(enemy,false)
 var tool=spec.get("cut_tool",p.type)
 var op=g.Tools.operation(tool)
 if op=="buff": return g.Consumables.reason(g,p.type)
 if p.target=="prison_door":
  if g.state.prison.door_open: return "牢门已打开。"
  if not g.Tools.assisted(g) and not g.Prison.Space.at(g,"door"): return "请先到牢门前。"
  return g.Tools.unlock_reason(g)
 var target=g._equipment(p.target)
 if target.is_empty() or target.durability<=0: return "请选择仍佩戴的拘束具。"
 if op=="unlock": return g.Tools.unlock_reason(g,target)
 var slots=WALL_SLOTS[g.state.posture]
 if g.SpecialEquipment.is_reinforcement(target):
  if not p.free: return "固定带需要借墙切割。"
  if not g.Tools.assisted(g) and "thigh" not in slots: return "请调整姿势，使固定带贴墙。"
  return "" if g._outer(target) else "请先处理外层装备。"
 if g.Equipment.TEMPLATES.get(target.template,{}).get("damage_factor",1.0)==0.0: return "请选择可切割的拘束具。"
 if target.material not in g.Tools.TYPES[tool].materials: return "请选择适用材料。"
 if p.free and not g.Tools.assisted(g):
  return g.Tools.Contact.evaluate(g,target,{"points":g.Tools.Contact.slot_points(slots)}).reason
 if not g.Tools.assisted(g) and g.occupied("fingers"): return "手持切割需要手指自由。"
 return g.Tools.target_contact(g,target,"cut").reason

static func resolve(g, p: Dictionary) -> void:
 var spec=g.Cards.Rules.SPECS[p.type]
 if enemy_branch(g,spec):
  g._damage_enemy(g._enemy(p.target),spec.tool_damage,"fixed",g.B.CARD_NAMES[p.type])
  return
 var tool=spec.get("cut_tool",p.type)
 match g.Tools.operation(tool):
  "buff": g.Consumables.apply(g,p.type,p.target)
  "unlock":
   if p.target=="prison_door": g.state.prison.door_open=true
   else: g._unlock_equipment(g._equipment(p.target))
   g._emit("event","开锁针打开了锁。")
  "cut":
   var target=g._equipment(p.target)
   var damage=spec.get("tool_damage",g.Tools.TYPES[tool].damage)*g.Cards.damage_multiplier(g,"equipment")
   g._apply_equipment_damage(target,damage,"cut")
   g._emit("event","%s对%s造成%s点切割伤害。" % [g.B.CARD_NAMES[p.type],target.name,g.number(damage)])

# A physical play spends one use after all replayed effects. Deck records and zone
# copies share the UID; a duplicate card has its own UID and lifetime.
static func spend(g, card: Dictionary) -> bool:
 if not card.has("remove_left"): return false
 card.remove_left-=1
 for saved in g.state.deck:
  if saved.uid!=card.uid: continue
  if card.remove_left==0: g.state.deck.erase(saved)
  else: saved.remove_left=card.remove_left
  break
 return card.remove_left==0
