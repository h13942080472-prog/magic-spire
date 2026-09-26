extends RefCounted
const Rules=preload("res://data/card_rules.gd")
const Splash=preload("res://core/card_splash.gd")
const Hannya=preload("res://core/hannya.gd")
const SelfBinding=preload("res://core/self_binding.gd")
const ZONES=["draw","hand","play","discard","exhaust","powers"]

static func active_buffs(g, include_disabled: bool=false) -> Array:
 var result=g.state.card_buffs.duplicate()
 for card in g.state.powers:
  if not include_disabled and not card.get("power_enabled",true): continue
  var id=Rules.SPECS[card.type].self_faces[card.power_face].buff
  if id not in result: result.append(id)
 return result

# 状态开关的显示事实（批 R5：行生产转发改显示事实构建，docs/spec/candidate-removal.md §2.1 T5／T8）。
static func toggle_facts(g) -> Array:
 var out=[]
 if g.state.overloaded or g.state.phase in ["cleared","prison_end"]: return out
 for card in g.state.powers:
  var id=Rules.SPECS[card.type].self_faces[card.power_face].buff
  if not Rules.BUFFS[id].get("toggleable",false): continue
  var enabled=not card.get("power_enabled",true)
  var args={"power_name":Rules.BUFFS[id].name,"enabled":enabled}
  out.append(g._fact({"kind":"status_toggle","status":"power_"+id,"uid":card.uid,"enabled":enabled},("开启" if enabled else "关闭")+args.power_name,{"kind":"game.status_toggle","args":args,"fallback":g.copy_status_toggle(g,args)},0,0.0,"","","status_toggle"))
 return out

static func toggle_power(g, p: Dictionary) -> void:
 for card in g.state.powers:
  if card.uid==p.uid: card.power_enabled=p.enabled;return

static func physical_attachment(g, attack: String) -> Dictionary:
 if attack not in ["strike","heavy","kick"]: return {}
 for id in active_buffs(g):
  var effect=Rules.BUFFS[id].get("physical_attachment",{})
  if not effect.is_empty() and g.state.mana+g.state.temporary_mana>=effect.mana: return effect
 return {}

static func buff_stacks(g, id: String) -> int:
 if Rules.BUFFS[id].has("attributes") and Rules.BUFFS[id].get("stack_uses",false): return int(g.state.card_buff_uses.get(id,0))
 var total=0
 for card in g.state.powers:
  if Rules.SPECS[card.type].self_faces[card.power_face].buff==id: total+=card.get("power_stacks",1)
 return maxi(1,total)

static func first_magic(g, type: String, free: Variant=null) -> Dictionary:
 var result={"energy_discount":0,"cast_minimum":0.0,"minimum_sources":[]}
 if not Rules.SPECS.has(type) or "magic" not in Rules.type_tags(type,free): return result
 for card in g.state.powers:
  var buff=Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff]
  var effect=buff.get("first_magic",{})
  var remaining=int(card.get("power_magic_remaining",0))
  if remaining<=0: continue
  result.energy_discount+=int(effect.get("energy_discount",0))*remaining
  if effect.get("cast_minimum",0.0)>0:
   result.cast_minimum=maxf(result.cast_minimum,effect.cast_minimum)
   if buff.name not in result.minimum_sources: result.minimum_sources.append(buff.name)
 return result

# One submitted card spends every discount stack but only one guaranteed-cast use.
# Runs before resolution/replay, including zero-cost and failed attempts.
static func consume_first_magic(g, p: Dictionary) -> void:
 if "magic" not in Rules.type_tags(p.type,p.free): return
 var guaranteed=false
 for card in g.state.powers:
  var effect=Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff].get("first_magic",{})
  if card.get("power_magic_remaining",0)<=0: continue
  if effect.has("energy_discount"): card.power_magic_remaining=0
  elif effect.has("cast_minimum") and not guaranteed:
   card.power_magic_remaining-=1
   guaranteed=true

static func casting_modifiers(g, profile: Dictionary={}) -> Dictionary:
 var result={"bonus":0.0,"minimum":0.0,"minimum_sources":[]}
 for id in active_buffs(g): result.minimum=maxf(result.minimum,float(Rules.BUFFS[id].get("cast_minimum",0.0)))
 for id in active_buffs(g):
  if result.minimum>0 and float(Rules.BUFFS[id].get("cast_minimum",0.0))==result.minimum: result.minimum_sources.append(Rules.BUFFS[id].name)
 for card in g.state.powers:
  var buff=Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff]
  result.bonus+=float(buff.get("card_cast_bonus",0.0))*card.get("power_cast_count",0)
 if profile.get("magic_card",false):
  var first=first_magic(g,profile.card_type,profile.get("card_free"))
  if first.cast_minimum>result.minimum:
   result.minimum=first.cast_minimum
   result.minimum_sources=first.minimum_sources
  elif first.cast_minimum==result.minimum and first.cast_minimum>0:
   result.minimum_sources.append_array(first.minimum_sources)
 return result

static func buff_requirement(g, buff: Dictionary) -> String:
 var reasons=[]
 if buff.get("no_restraints",false) and not restraint_roots(g,buff.get("include_special",true),true).is_empty(): reasons.append("仍有非特殊装备的拘束具")
 if buff.has("max_degree_any"):
  var limits=buff.max_degree_any
  if not limits.keys().any(func(region):return g.restraint_degree(region)<=limits[region]):
   reasons.append("需要"+"或".join(limits.keys().map(func(region):return ("上身" if region=="arms" else "腿部")+"严密度≤"+g.number(limits[region])))+"。")
 for region in buff.get("min_levels",{}):
  var limit=int(buff.min_levels[region])
  if g.level(region)<limit:
   reasons.append("%s束缚等级需≥%d，当前为%d" % ["上身" if region=="arms" else "腿部",limit,g.level(region)])
 return "；".join(reasons)

static func failure_refund_rates(g) -> Dictionary:
 return {"mana":g.B.CAST_FAILURE_REFUND,"temporary_mana":g.B.CAST_FAILURE_REFUND}

static func failure_unlimited(g, buff: Dictionary) -> bool:
 var worn=buff.failure_conversion.get("unlimited_worn",{})
 return not worn.is_empty() and worn_count(g,worn.include_special,worn.min_tier)>=worn.count

# Read-only: inspect the actual committed payment and final energy cost. Called
# only for a failed, non-replayed cast; counters are committed by the caller.
static func failure_outcome(g, c: Dictionary) -> Dictionary:
 var result={"rates":failure_refund_rates(g),"energy":0,"power_uid":"","zero_cost":false}
 if c.payload.get("replay",false): return result
 for card in g.state.powers:
  var buff=Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff]
  if not buff.has("failure_conversion") or buff_requirement(g,buff)!="": continue
  var effect=buff.failure_conversion
  if effect.get("temporary_only",false) and (c.mana_payment.temporary_mana<=0 or c.mana_payment.mana>0): continue
  var zero=c.payload.has("uid") and c.cost==0
  if zero and not failure_unlimited(g,buff) and card.get("power_failure_count",0)>=effect.zero_cost_limit: continue
  result={"rates":{"mana":effect.refund,"temporary_mana":effect.refund},"energy":effect.energy,"power_uid":card.uid,"zero_cost":zero}
  break
 return result

static func commit_failure(g, outcome: Dictionary) -> void:
 if outcome.power_uid=="": return
 outcome.energy=g._gain_energy(outcome.energy)
 if not outcome.zero_cost: return
 for card in g.state.powers:
  if card.uid==outcome.power_uid:
   var buff=Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff]
   # Count even while unlimited so losing the upgrade cannot refresh quota.
   card.power_failure_count=mini(buff.failure_conversion.zero_cost_limit,card.get("power_failure_count",0)+1)
   return

static func failure_refund_detail(g) -> String:
 var lines=["失败默认返还本次耗魔的50%，自身与临时魔力各退回原池"]
 for id in active_buffs(g):
  if Rules.BUFFS[id].has("failure_conversion"):
   lines.append(Rules.BUFFS[id].detail+"当前："+progress_text(g,id)+"。次数用完后恢复普通50%返还")
 return "；".join(lines)

static func magic_card_traction(g, payload: Dictionary) -> int:
 if payload.get("kind","") not in ["card","prison"] or not payload.has("uid") or "magic" not in Rules.type_tags(payload.type,payload.get("free",false)): return 0
 var amount=0
 for id in active_buffs(g): amount+=int(Rules.BUFFS[id].get("magic_card_traction",0))*buff_stacks(g,id)
 return amount

static func worn_count(g, include_special: bool=true, min_tier: int=0) -> int:
 var qualifies=func(item):return item.durability>0 and (min_tier==0 or g.tier(item.durability,item.maximum)>=min_tier)
 var ordinary=g.state.equipment.filter(func(item):return qualifies.call(item) and not g.Equipment.lock_only(item)).size()
 # A composite counts once, using its active body rather than its straps.
 var composites=g.state.composites.filter(func(root):return g.Composites.active(root) and qualifies.call(g._composite_body(root))).size()
 var special=g.state.special_equipment.filter(qualifies).size() if include_special else 0
 return ordinary+composites+(special if include_special else 0)

static func occupied_body_count(g) -> int:
 # Presence, not freedom: one occupied hand side already counts its sidebar group.
 var previous=g._begin_equipment_read()
 var count=0
 for group in g.Equipment.panel_groups():
  # Shoulder attachments have no capacity coverage, but occupy the neck/shoulder display group.
  if not group.special and group.slots.any(func(slot):return not (g.targets_at(slot) if slot=="shoulder" else g.equipment_at(slot)).is_empty()): count+=1
 g._equipment_read=previous
 return count

static func body_count_context(g, type: String) -> Variant:
 return occupied_body_count(g) if Rules.SPECS[type].get("self_faces",{}).values().any(func(face):return face.has("body_draw_divisor")) else null

static func mana_cost_multiplier(g) -> float:
 var reduction=0.0
 for id in active_buffs(g): reduction+=float(Rules.BUFFS[id].get("worn_mana_reduction",0.0))*buff_stacks(g,id)
 return maxf(0.0,1.0-worn_count(g)*reduction)

static func power_attribute_modifier(g, attribute: String) -> float:
 var total=0.0
 var count=worn_count(g)
 for id in active_buffs(g):
  total+=(float(Rules.BUFFS[id].get("worn_attributes",{}).get(attribute,0))*count+float(Rules.BUFFS[id].get("attributes",{}).get(attribute,0)))*buff_stacks(g,id)
 return total

static func begin_turn(g) -> void:
 expire_turn_buffs(g,true)
 if g.state.phase not in g.RelicEffects.COMBAT_PHASES or not g.state.combat.active: return
 for card in g.state.powers:
  if card.has("power_magic_remaining"): card.power_magic_remaining=card.get("power_stacks",1)
  if card.has("power_cast_count"): card.power_cast_count=0
  if card.has("power_failure_count"): card.power_failure_count=0
  if not card.has("power_next_draw"): continue
  var amount=card.power_next_draw
  card.power_next_draw=0
  if amount>0: _power_draw(g,card,amount)
 for id in active_buffs(g):
  var buff=Rules.BUFFS[id]
  if buff_requirement(g,buff.get("turn_start_requirements",{}))!="": continue
  for repeat in range(buff_stacks(g,id)): apply_effects(g,buff.get("turn_start_effects",[]),{},buff.name)

# Count physical roots, not the multiple body slots/components used to display them.
# Keep depleted roots until cleanup removes them, so the transition is observed once.
static func restraint_roots(g, include_special: bool=true, include_lock_only: bool=false) -> Array:
 var ids=[]
 for field in ["equipment","composites","special_equipment","links"]:
  if field=="special_equipment" and not include_special: continue
  for item in g.state[field]:
   if include_lock_only or not g.Equipment.lock_only(item): ids.append(item.id)
 for piece in g.Shoulders.pieces(g): ids.append(piece.id)
 return ids

static func restraint_changed(g, event: String, count: int=1) -> void:
 if count<=0 or not g.state.combat.active or g.state.phase not in g.RelicEffects.COMBAT_PHASES: return
 for card in g.state.powers:
  var id=Rules.SPECS[card.type].self_faces[card.power_face].buff
  var trigger=Rules.BUFFS[id].get("restraint_draw",{})
  if trigger.get("event","")!=event: continue
  var amount=count*trigger.amount*card.get("power_stacks",1)
  if trigger.next_turn:
   card.power_next_draw+=amount
   g._emit("event",Rules.BUFFS[id].name+"：下回合多抽%d张牌。" % amount,{"power_trigger":{"id":id,"uid":card.uid},"restraint_draw":{"event":event,"count":count,"next_turn":true,"amount":amount}})
  else: _power_draw(g,card,amount)
  # Energy uses the same physical-root count and power stacks as card draw,
  # even when no card fits in hand.
  if trigger.get("energy",0)>0:
   var energy=g._gain_energy(count*trigger.energy*card.get("power_stacks",1))
   g._emit("event",Rules.BUFFS[id].name+"：恢复%d能量。" % energy,{"power_trigger":{"id":id,"uid":card.uid},"restraint_energy":{"event":event,"count":count,"amount":energy}})

static func _power_draw(g, card: Dictionary, amount: int) -> void:
 var id=Rules.SPECS[card.type].self_faces[card.power_face].buff
 var before=g.state.hand.size()
 g._draw(amount)
 g._emit("event",Rules.BUFFS[id].name+"：抽%d张牌。" % (g.state.hand.size()-before),{"power_trigger":{"id":id,"uid":card.uid},"power_draw":{"requested":amount,"drawn":g.state.hand.size()-before}})

static func expire_turn_buffs(g, at_start: bool=false) -> void:
 var next_buffs=[]
 var expired_effects=[]
 if g.state.turn_strength>0:
  var amount=g.state.turn_strength;g.state.turn_strength=0
  g._emit("event","本回合力量加成结束。",{"expired_turn_strength":amount})
 for id in g.state.card_buffs.duplicate():
  if Rules.BUFFS[id].duration=="turn" or (at_start and Rules.BUFFS[id].duration=="next_turn_start"):
   for repeat in range(int(g.state.card_buff_uses.get(id,1))):
    if Rules.BUFFS[id].has("on_expire_effects"): expired_effects.append({"effects":Rules.BUFFS[id].on_expire_effects,"name":Rules.BUFFS[id].name})
    if Rules.BUFFS[id].has("on_expire_buff"): next_buffs.append(Rules.BUFFS[id].on_expire_buff)
   g.state.card_buffs.erase(id)
   g.state.card_buff_uses.erase(id)
   if not Rules.BUFFS[id].has("on_expire_buff"): g._emit("event",Rules.BUFFS[id].name+"的本回合效果结束。",{"expired_card_buff":id})
 for id in next_buffs: grant_buff(g,id)
 for pending in expired_effects: apply_effects(g,pending.effects,{},pending.name)

static func spell_used(g, spell: String) -> void:
 for id in active_buffs(g):
  var buff=Rules.BUFFS[id]
  if buff.get("spell","")==spell:
   for repeat in range(buff_stacks(g,id)): apply_effects(g,buff.get("spell_use_effects",[]),{},buff.name)

const METER_FIELDS={"mana_spent":"power_mana_progress","pressure_gained":"power_pressure_progress"}

static func record_meter(g, key: String, amount: float) -> void:
 if amount<=0 or not g.state.combat.active or g.state.phase not in g.RelicEffects.COMBAT_PHASES: return
 for card in g.state.powers:
  var id=Rules.SPECS[card.type].self_faces[card.power_face].buff
  if not Rules.BUFFS[id].has(key): continue
  card[METER_FIELDS[key]]=float(card.get(METER_FIELDS[key],0.0))+amount

static func mana_spent(g, amount: float) -> void:
 record_meter(g,"mana_spent",amount)

static func pressure_gained(g, amount: float) -> void:
 record_meter(g,"pressure_gained",amount)
 flush_meter(g,"pressure_gained")

static func flush_mana_powers(g) -> bool:
 return flush_meter(g,"mana_spent")

static func flush_meter(g, key: String) -> bool:
 var triggered=false
 for card in g.state.powers.duplicate():
  var id=Rules.SPECS[card.type].self_faces[card.power_face].buff
  var meter=Rules.BUFFS[id].get(key,{})
  if meter.is_empty(): continue
  var field=METER_FIELDS[key]
  var progress=float(card.get(field,0.0))
  var count=int(floor((progress+0.000001)/meter.step))
  card[field]=maxf(0.0,progress-count*meter.step)
  if count<=0: continue
  triggered=true
  var effects=meter.effects.duplicate(true)
  for effect in effects: effect.amount=Rules.amount(effect,{})*count*card.get("power_stacks",1)
  var results=apply_effects(g,effects,{})
  var record={"power_trigger":{"id":id,"uid":card.uid}}
  record["mana_trigger" if key=="mana_spent" else "pressure_trigger"]={"times":count,"remaining":card[field]}
  g._emit("event",Rules.BUFFS[id].name+"："+"，".join(results)+"。",record)
 return triggered

static func record_play(g, type: String, free: bool=false, played_uid: String="") -> void:
 g.RelicEffects.card_played(g,type,free)
 if "skill" in Rules.type_tags(type,free):
  for id in active_buffs(g):
   var effect=Rules.BUFFS[id].get("skill_charge",{})
   if effect.is_empty(): continue
   var payment=g._mana_payment({"kind":"card"},effect.mana)
   if g.state.mana<payment.mana: continue
   g._pay_mana(payment)
   apply_effects(g,[{"op":"charge","amount":effect.amount}],{})
   g._emit("event","魔力附着：消耗%s魔力，获得%d层蓄力。" % [g.number(effect.mana),effect.amount],{"skill_charge":{"buff":id,"uid":played_uid,"payment":payment,"amount":effect.amount}})
 for card in g.state.powers:
  if card.has("power_cast_count") and card.uid!=played_uid:
   card.power_cast_count+=1
   g._emit("event","熟练而已：本回合施法成功率额外＋%s%%。" % g.number(casting_modifiers(g).bonus*100),{"casting_growth":{"uid":card.uid,"cards":card.power_cast_count,"bonus":casting_modifiers(g).bonus}})
 for card in g.state.powers:
  var effect=Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff].get("periodic",{})
  if not effect.is_empty() and effect.card_type in Rules.type_tags(type): card.power_progress+=1
 # `free` selects the second face. Cards with two restraint faces use true here
 # as well, so only the shared free-effect classifier can exclude real free faces.
 if Rules.free_effect(type,free): return
 for card in g.state.powers:
  if card.uid==played_uid: continue
  var id=Rules.SPECS[card.type].self_faces[card.power_face].buff
  var amount=float(Rules.BUFFS[id].get("bound_card_pressure",0))*card.get("power_stacks",1)
  if amount>0: g.Pressure.gain(g,amount,Rules.BUFFS[id].name+"的拘束面刺激",true)

static func progress_text(g, id: String) -> String:
 if Rules.BUFFS[id].duration=="next_turn_start" and Rules.BUFFS[id].has("on_expire_buff") and not Rules.BUFFS[id].has("attributes"): return "下回合生效"
 if Rules.BUFFS[id].get("toggleable",false): return "已开启 · 右键关闭" if id in active_buffs(g) else "已关闭 · 右键开启"
 if Rules.BUFFS[id].has("turn_start_requirements"):
  var issue=buff_requirement(g,Rules.BUFFS[id].turn_start_requirements)
  return "下回合开始时生效" if issue=="" else issue
 if Rules.BUFFS[id].has("first_magic"):
  var remaining=0
  for card in g.state.powers:
   if Rules.SPECS[card.type].self_faces[card.power_face].buff==id: remaining+=card.power_magic_remaining
  if remaining==0: return "本回合已触发"
  return "首张魔法牌能量－%d" % remaining if Rules.BUFFS[id].first_magic.has("energy_discount") else "必定成功剩余%d张" % remaining
 if Rules.BUFFS[id].has("failure_conversion"):
  var buff=Rules.BUFFS[id]
  var issue=buff_requirement(g,buff)
  if issue!="": return "未生效："+issue
  var count=0
  for card in g.state.powers:
   if Rules.SPECS[card.type].self_faces[card.power_face].buff==id: count=card.get("power_failure_count",0)
  var quota="0费不限次数" if failure_unlimited(g,buff) else "0费剩余%d次" % maxi(0,buff.failure_conversion.zero_cost_limit-count)
  return ("全临时耗魔失败：能量＋1" if buff.failure_conversion.get("temporary_only",false) else "失败返还100% · 能量＋1")+" · "+quota
 if Rules.BUFFS[id].has("worn_mana_reduction"): return "%d件 · 耗魔－%s%%" % [worn_count(g),g.number(snappedf((1.0-mana_cost_multiplier(g))*100,0.01))]
 if Rules.BUFFS[id].has("card_cast_bonus"): return "本回合＋%s%%" % g.number(casting_modifiers(g).bonus*100)
 if Rules.BUFFS[id].has("cast_minimum"): return "最低%s%%" % g.number(Rules.BUFFS[id].cast_minimum*100)
 if Rules.BUFFS[id].has("hannya_level"): return "%d级" % Rules.BUFFS[id].hannya_level
 if Rules.BUFFS[id].has("attributes"):
  var labels={"strength":"力量","dexterity":"灵巧"}
  return "／".join(Rules.BUFFS[id].attributes.keys().map(func(key):return labels[key]+"＋"+g.number(Rules.BUFFS[id].attributes[key]*buff_stacks(g,id))))
 if Rules.BUFFS[id].has("replay"): return "复放%d次" % g.state.card_buff_uses.get(id,0)
 if Rules.BUFFS[id].has("attack_uses") or Rules.BUFFS[id].get("next_action_freedom",false): return "剩余%d次" % g.state.card_buff_uses.get(id,0)
 if Rules.BUFFS[id].has("card_damage_type"): return "下一次滑脱×%s" % g.number(Rules.BUFFS[id].damage_multiplier)
 if Rules.BUFFS[id].get("restraint_draw",{}).get("next_turn",false):
  return "下回合抽牌＋%d" % pending_draw(g,id)
 if Rules.BUFFS[id].get("restraint_draw",{}).has("energy"):
  var trigger=Rules.BUFFS[id].restraint_draw
  return "每件抽%d张 · 能量＋%d" % [trigger.amount*buff_stacks(g,id),trigger.energy*buff_stacks(g,id)]
 if Rules.BUFFS[id].get("interrupt",false): return "打断1层"
 if Rules.BUFFS[id].has("worn_attributes"):
  var count=worn_count(g)
  return "%d件 · 力量／灵巧＋%d" % [count,int(power_attribute_modifier(g,"strength"))]
 for key in METER_FIELDS:
  if not Rules.BUFFS[id].has(key): continue
  var values=[]
  for card in g.state.powers:
   if Rules.SPECS[card.type].self_faces[card.power_face].buff==id: values.append(g.number(card[METER_FIELDS[key]])+"／"+str(Rules.BUFFS[id][key].step))
  return ("%d重 · 耗魔%s" if key=="mana_spent" else "%d重 · 快感%s") % [buff_stacks(g,id),"、".join(values)]
 var progress=[]
 for card in g.state.powers:
  if Rules.SPECS[card.type].self_faces[card.power_face].buff==id and card.has("power_progress"):
   progress.append("%d／%d" % [card.power_progress,Rules.BUFFS[id].periodic.count])
 if not progress.is_empty(): return "、".join(progress)+"张"
 return "%d重效果" % buff_stacks(g,id) if buff_stacks(g,id)>1 else "生效中"

static func pending_draw(g, id: String) -> int:
 var pending=0
 for card in g.state.powers:
  if Rules.SPECS[card.type].self_faces[card.power_face].buff==id: pending+=card.get("power_next_draw",0)
 return pending

# Resolve after every hit of the played card; continuations never count as more cards.
static func flush_powers(g) -> bool:
 var triggered=flush_mana_powers(g)
 for card in g.state.powers:
  var id=Rules.SPECS[card.type].self_faces[card.power_face].buff
  var effect=Rules.BUFFS[id].get("periodic",{})
  if effect.is_empty() or card.power_progress<effect.count: continue
  card.power_progress-=effect.count
  triggered=true
  var label=Rules.BUFFS[id].name
  g._emit("event",label+"触发。",{"power_trigger":{"id":id,"uid":card.uid}})
  if effect.target=="enemies":
   var targets=g.state.enemies.filter(func(enemy):return not enemy.gone).map(func(enemy):return enemy.id)
   var damage=effect.base*card.get("power_stacks",1)*damage_multiplier(g,"card_effect")
   var damage_group={}
   for target in targets: g._damage_enemy(g._enemy(target),damage,effect.damage_type,label,{},damage_group)
  else:
   # Freeze targets AND multipliers before any removal reveals an inner layer.
   var hits=[]
   for target in g.action_targets():
    if target.durability<=0 or not g._outer(target): continue
    hits.append({"id":target.id,"preview":g.escape_preview(target,effect.damage_type,effect.base*card.get("power_stacks",1),[],false,true)})
   for hit in hits:
    var target=g._equipment(hit.id)
    if target.is_empty() or target.durability<=0: continue
    var before=target.durability
    g._apply_equipment_damage(target,hit.preview.damage,effect.damage_type,true)
    g._emit("mechanical",label+"："+target.name+"，"+g._formula(hit.preview)+"；耐久 %s → %s。" % [g.number(before),g.number(target.durability)],{"action_result":g.ActionCopy.equipment_result(label,target.name,before,target.durability,effect.damage_type),"power_damage":{"id":id,"target":hit.id,"before":before,"after":target.durability,"preview":hit.preview}})
 return triggered

static func spell_power(g, spell: String) -> Dictionary:
 var result={}
 for id in active_buffs(g):
  var effect=Rules.BUFFS[id]
  if effect.get("spell","")==spell:
   for key in effect:
    if key in ["extra_uses","chance_bonus","base_bonus","equipment_damage_factor"]: result[key]=result.get(key,0)+effect[key]*buff_stacks(g,id)
    else: result[key]=effect[key]
 return result

static func damage_multiplier(g, attack: String) -> float:
 var result=1.0
 for id in active_buffs(g):
  var effect=Rules.BUFFS[id]
  if effect.get("attack","") in ["all",attack]: result*=pow(effect.get("damage_multiplier",1.0),buff_stacks(g,id))
 return result

static func matches_attack(effect: Dictionary, attack: String) -> bool:
 return effect.get("attack","") in ["all",attack] or attack in effect.get("attacks",[])

static func card_damage_multiplier(g, mode: String) -> float:
 var result=1.0
 for id in active_buffs(g):
  var buff=Rules.BUFFS[id]
  if buff.get("card_damage_type","")=="slip" and mode in ["slip","magic_slip"]: result*=buff.damage_multiplier
 return result

static func scale_card_preview(g, preview: Dictionary, mode: String) -> void:
 var multiplier=card_damage_multiplier(g,mode)
 for key in ["damage","scaled_damage","environment_true"]:
  if preview.has(key): preview[key]*=multiplier
 preview.damage_buff_multiplier=preview.get("damage_buff_multiplier",1.0)*multiplier

static func consume_card_damage(g, mode: String, damage: float) -> void:
 if damage<=0 or mode not in ["slip","magic_slip"]: return
 for id in g.state.card_buffs.duplicate():
  if Rules.BUFFS[id].get("card_damage_type","")=="slip":
   g.state.card_buffs.erase(id)
   g._emit("event",Rules.BUFFS[id].name+"的滑脱伤害加成已使用。",{"card_damage_buff_used":id})

static func attack_cost(g, attack: String, base: int) -> int:
 var discount=0
 for id in active_buffs(g):
  var effect=Rules.BUFFS[id]
  if matches_attack(effect,attack): discount+=int(effect.get("energy_discount",0))*buff_stacks(g,id)
 return maxi(0,base-discount)

static func attack_interrupt(g, attack: String) -> bool:
 for id in active_buffs(g):
  var buff=Rules.BUFFS[id]
  if buff.get("interrupt",false) and matches_attack(buff,attack): return true
 return false

static func grant_buff(g, id: String) -> void:
 if id not in g.state.card_buffs: g.state.card_buffs.append(id)
 var buff=Rules.BUFFS[id]
 if buff.get("stack_uses",false): g.state.card_buff_uses[id]=int(g.state.card_buff_uses.get(id,0))+int(buff.get("attack_uses",1))
 elif buff.has("attack_uses"): g.state.card_buff_uses[id]=buff.attack_uses

static func attack_ignores_restraints(g, attack: String) -> bool:
 if basic_attack_freedom(g) or action_ignores_restraints(g): return true
 for id in active_buffs(g):
  var buff=Rules.BUFFS[id]
  if buff.get("unrestricted_basics",false): continue
  if matches_attack(buff,attack) and buff.get("ignore_restraints",false): return true
 return false

static func action_ignores_restraints(g) -> bool:
 return active_buffs(g).any(func(id):return Rules.BUFFS[id].get("next_action_freedom",false))

static func is_card_action(p: Dictionary) -> bool:
 return p.kind=="card" or (p.kind=="prison" and p.has("uid"))

static func action_buff_ids(g) -> Array:
 return active_buffs(g).filter(func(id):return Rules.BUFFS[id].get("next_action_freedom",false))

static func consume_action_buffs(g, ids: Array) -> void:
 for id in ids:
  if not g.state.card_buff_uses.has(id): continue
  g.state.card_buff_uses[id]-=1
  if g.state.card_buff_uses[id]<=0:
   g.state.card_buff_uses.erase(id)
   g.state.card_buffs.erase(id)
  g._emit("event",Rules.BUFFS[id].name+"：已用于本次出牌或基础动作。",{"action_buff_used":id})

static func basic_attack_freedom(g) -> bool:
 return g.state.phase=="battle" and active_buffs(g).any(func(id):return Rules.BUFFS[id].get("unrestricted_basics",false))

static func consume_attack_buffs(g, attack: String) -> void:
 for id in g.state.card_buff_uses.keys():
  if not matches_attack(Rules.BUFFS[id],attack): continue
  g.state.card_buff_uses[id]-=1
  var remaining=g.state.card_buff_uses[id]
  if remaining==0:
   g.state.card_buff_uses.erase(id)
   g.state.card_buffs.erase(id)
  g._emit("event","%s：本次体术按自由态发动，剩余%d次。" % [Rules.BUFFS[id].name,remaining],{"attack_buff_used":id,"remaining":remaining})
 g.state.card_buffs=g.state.card_buffs.filter(func(id):return not (Rules.BUFFS[id].duration=="next_attack" and matches_attack(Rules.BUFFS[id],attack)))

static func uses_magic(p: Dictionary) -> bool:
 return Rules.face_casts(p.type,p.get("free",not Rules.SPECS[p.type].has("self_faces")))

static func energy_cost(g, type: String, free: bool=false) -> int:
 if Rules.SPECS[type].get("x_cost",false): return maxi(0,g.state.energy-g.Character.Expansion.skill_discount(g,type,free))
 var base=Hannya.energy_cost(g) if Rules.SPECS[type].get("drinking",false) else Rules.energy_cost(type,free)
 if Rules.SPECS[type].has("zero_cost_strength") and g.RelicEffects.attribute(g,"strength")>=Rules.SPECS[type].zero_cost_strength: base=0
 return maxi(0,base-first_magic(g,type,free).energy_discount-g.Character.Expansion.skill_discount(g,type,free))

static func energy_label(g, type: String, free: bool=false) -> String:
 return "X" if Rules.SPECS[type].get("x_cost",false) else str(energy_cost(g,type,free))

static func face_mana(g, type: String, free: bool) -> float:
 var spec=Rules.SPECS[type]
 var cost=Rules.face_mana_base(type,free,g.B.SPELL_COST)
 if spec.has("all_mana_minimum"): return g.state.mana+g.state.temporary_mana
 if Rules.face_casts(type,free) and not spec.get("fixed_mana_cost",false): cost=g._mana_cost(cost)
 if "magic" in Rules.type_tags(type,free): cost-=g.relic_value("card_mana_discount")
 return maxf(0.0,cost)

static func face_text(g, type: String, free: bool, uid: String="") -> String:
 if uid!="" and Rules.SPECS[type].has("hannya_stage"):
  var text=Hannya.detail(g,Rules.SPECS[type].hannya_stage,free)+Rules.SPECS[type].get("play_music_text","")+"消耗。"
  return ("固有。" if g.B.CARD_TRAITS.get(type,{}).get("innate",false) else "")+text
 return g.B.card_info(type,g.number(face_mana(g,type,free)),face_damage_values(g,type,uid),true,worn_count(g),body_count_context(g,type))[2 if free else 1]

static func face_texts(g, type: String, uid: String="") -> Dictionary:
 if uid!="" and Rules.SPECS[type].has("hannya_stage"):
  return {"bound":face_text(g,type,false,uid),"free":face_text(g,type,true,uid)}
 var costs={"bound":g.number(face_mana(g,type,false)),"free":g.number(face_mana(g,type,true))}
 var info=g.B.card_info(type,costs,face_damage_values(g,type,uid),true,worn_count(g),body_count_context(g,type))
 return {"bound":info[1],"free":info[2]}

static func instance(g, uid: String) -> Dictionary:
 if uid!="":
  for zone in ZONES:
   for card in g.state[zone]:
    if card.uid==uid: return card
 return {}

static func metadata(g, type: String, uid: String="") -> Dictionary:
 var costs={"bound":face_mana(g,type,false),"free":face_mana(g,type,true)}
 var values=face_damage_values(g,type,uid)
 var result=g.B.card_metadata(type,costs,values,worn_count(g),body_count_context(g,type))
 result.face_damage=values
 if uid!="" and Rules.SPECS[type].has("witch_training_stage"):
  result.note=g.B.CARD_INFO[type][3]+"\n"+g.Character.Expansion.training_progress(instance(g,uid))
 result.face_casting={}
 for side in ["bound","free"]:
  if Rules.face_casts(type,side=="free"):
   result.face_casting[side]=g.cast_view(cast_profile(g,type,costs[side]>0,side=="free"))
 if uid!="" and Rules.SPECS[type].has("hannya_stage"):
  result.face_effects=face_texts(g,type,uid)
  if Hannya.next_level(g,Rules.SPECS[type].hannya_stage)==0:
   for side in ["bound","free"]: result.face_mana[side]=result.face_mana[side].filter(func(entry):return entry.kind!="gain")
 return result

# 界面固有卡面文案的唯一生成函数（docs/ondemand-copy.md §1.1）：实时路径的四个步骤在此一处。
# 输入按牌型与实例 uid，输出全新 Dictionary，只读且不影响判定、随机与存档。
static func text_entry(g, type: String, uid: String="") -> Dictionary:
 var entry=face_texts(g,type,uid)
 entry.face_costs={"bound":"—" if g.B.CARD_TRAITS.get(type,{}).get("unplayable",false) else g.Cards.energy_label(g,type,false),"free":"—" if g.B.CARD_TRAITS.get(type,{}).get("unplayable",false) else g.Cards.energy_label(g,type,true)}
 entry.merge(metadata(g,type,uid))
 if not Rules.cast_profile(type).is_empty(): entry.casting=g.cast_view(cast_profile(g,type))
 return entry

static func base_damage(g, type: String, uid: String="") -> float:
 var spec=Rules.SPECS[type]
 var scaling=spec.get("worn_damage",{})
 var dynamic_bonus=0.0 if scaling.is_empty() else worn_count(g,scaling.include_special)*scaling.per_item
 return float(spec.get("base",0.0))+dynamic_bonus+g.Relics.card_base_bonus(g.state.relics,type,g.state.get("ditto_form",""))+instance(g,uid).get("damage_bonus",0)

# Numeric face values, not parsed copy. Empty faces have no escape damage.
# Target-specific bonuses, assistance and multipliers belong to target previews.
static func face_damage_values(g, type: String, uid: String="") -> Dictionary:
 var values={"bound":[],"free":[]}
 if not Rules.damage(type): return values
 var base=base_damage(g,type,uid)
 for second in [false,true]:
  if Rules.free_effect(type,second): continue
  var side="free" if second else "bound"
  for hit_index in range(Rules.SPECS[type].get("hits",1)):
   values[side].append(g.escape_values(Rules.face_mode(type,second),base,{},false,hit_index).raw)
 return values

static func grow(g, type: String, uid: String) -> void:
 var amount=Rules.SPECS[type].get("damage_growth",0)
 var card=instance(g,uid)
 if amount<=0 or card.is_empty(): return
 card.damage_bonus=card.get("damage_bonus",0)+amount
 g._emit("event","「%s」本场两面基础伤害＋%d，当前%s。" % [g.B.CARD_NAMES[type],amount,g.number(base_damage(g,type,uid))],{"card_growth":{"uid":uid,"amount":amount,"bonus":card.damage_bonus}})

static func cast_profile(g, type: String, paid: bool=true, free: Variant=null) -> Dictionary:
 var profile=Rules.cast_profile(type).duplicate(true)
 if g.Character.active(g) and type in ["witch_hand","witch_mouth","witch_legs","witch_mind"]: profile=g.Character.profile(g,type.trim_prefix("witch_"))
 profile.paid_cast=paid
 profile.magic_card=Rules.SPECS.has(type) and "magic" in Rules.type_tags(type,free)
 profile.card_type=type
 profile.desire_curve=Rules.lewd_magic(type)
 profile.card_free=free
 if action_ignores_restraints(g):
  profile.body_free=true
  profile.ignore_restraints=true
 var power=spell_power(g,type)
 if power.get("ignore_body",false):
  profile.parts=["none"]
  profile.body_free=true
 if power.has("chance_bonus"): profile.chance_bonus=power.chance_bonus
 if Rules.FIXED_MAGIC.has(type) and basic_attack_freedom(g):
  profile.body_free=true
  profile.unrestricted_basic=true
  profile.multiplier=1.0
 return profile

static func end_powers(g) -> void:
 expire_turn_buffs(g)
 g.state.evasion=0
 flush_mana_powers(g)
 g.Character.retain_focus(g)
 for zone in ZONES:
  for card in g.state[zone]: card.erase("damage_bonus")
 for card in g.state.powers:
  card.erase("power_face")
  card.erase("power_enabled")
  card.erase("power_progress")
  card.erase("power_cast_count")
  card.erase("power_magic_remaining")
  card.erase("power_failure_count")
  for field in METER_FIELDS.values(): card.erase(field)
  card.erase("power_next_draw")
  card.erase("power_stacks")
  g.state.discard.append(card)
 g.state.powers.clear()
 g.state.card_buffs=g.state.card_buffs.filter(func(id):return Rules.BUFFS[id].duration not in ["battle","next_turn_start"] and not Rules.BUFFS[id].get("witch_session",false))
 g.state.card_buff_uses.clear()

static func end_hand(g) -> void:
 if g.state.phase not in ["battle","prepare"]: return
 for card in g.state.hand:
  var amount=float(Rules.SPECS[card.type].get("end_turn_pressure",0.0))
  if amount>0:
   g.Pressure.gain(g,amount,"「"+g.B.CARD_NAMES[card.type]+"」的回合末效果")

static func purge_temporary(g) -> void:
 var ids={}
 for card in g.state.deck:
  if g.B.CARD_TRAITS.get(card.type,{}).get("temporary",false): ids[card.uid]=true
 if ids.is_empty(): return
 for zone in ["deck"]+ZONES:
  g.state[zone]=g.state[zone].filter(func(card):return not ids.has(card.uid))

# Permanent removal must update the physical copy in whichever pile holds it.
# Callers own payment and narrative; this remains an internal transaction helper.
static func remove_permanent(g, uid: String) -> String:
 var cards=g.state.deck.filter(func(card):return card.uid==uid)
 if cards.size()!=1: return ""
 var type=cards[0].type
 for zone in ["deck"]+ZONES:
  g.state[zone]=g.state[zone].filter(func(card):return card.uid!=uid)
 return type

static func replace_permanent(g, uid: String, type: String) -> void:
 for zone in ["deck"]+ZONES:
  for card in g.state[zone]:
   if card.uid==uid: card.type=type

# Capture eligibility is shared by orientation, display facts and commit checks.
static func can_target_bind(type: String) -> bool:
 var spec=Rules.SPECS[type]
 return spec.mode=="lower" or (Rules.damage(type) and (not spec.has("target_slots") or spec.has("witch_training_stage")))

# Draw orientation ignores energy/mana shortages; only a real escape route matters.
static func has_escape_target(g, type: String) -> bool:
 if Rules.SPECS[type].has("bound_modes"): return true
 if Rules.single_face(type) or Rules.SPECS[type].has("self_faces"): return true
 if g.B.CARD_TRAITS.get(type,{}).get("unplayable",false): return true
 if can_target_bind(type) and g.CaptureBind.has_bind(g): return true
 for target in g.action_targets():
  var p=target_payload(g,type,target.slot,target)
  if reason(g,p)!="": continue
  if p.has("preview") and p.preview.damage<=0 and not p.preview.release: continue
  return true
 return false

static func body_reason(g, type: String) -> String:
 return g.cast_view(cast_profile(g,type)).reason if Rules.SPECS[type].has("casting") else ""

# Per-face usability consumes the determination results of this card's command shapes (批 R3：显示事实，
# 不再取候选行). Curse styling is explicitly exempt.
static func availability(g, card: Dictionary, free: bool, facts: Array) -> Dictionary:
 if g.B.CARD_TRAITS.get(card.type,{}).get("unplayable",false): return {"usable":false,"dim":false,"text":""}
 var options=facts.filter(func(f):return Rules.single_face(card.type) or f.payload.get("free",false)==free)
 if options.any(func(f):return f.valid): return {"usable":true,"dim":false,"text":"可用"}
 var issue=body_reason(g,card.type)
 if g.state.overloaded: issue="本回合正在高潮"
 elif not g.state.card_chain.is_empty(): issue="请先完成当前连续效果"
 elif g.state.pending_retain: issue="请先完成保留选择"
 elif g.state.phase not in ["battle","prepare","rest","prison"]: issue="当前阶段不能出牌"
 if issue=="":
  if options.is_empty(): issue="没有可用的自由部位" if Rules.free_effect(card.type,free) else "没有可处理的拘束具"
  else:
   # Prefer a structurally eligible target's resource shortage over another target's lock/cover reason.
   var eligible=options.filter(func(f):return f.source_reason=="")
   issue=eligible[0].reason if not eligible.is_empty() else options[0].reason
 return {"usable":false,"dim":true,"text":"（"+issue.trim_suffix("。")+"）"}

static func target_payload(g, type: String, slot: String, target: Dictionary, assist_profiles: Array=[], uid: String="", second: bool=false, force_continuation: bool=false) -> Dictionary:
 var spec=Rules.SPECS[type]
 var p={"type":type,"slot":slot,"target":target.get("id",""),"free":second if spec.has("bound_modes") else target.is_empty(),"mode":Rules.face_mode(type,second)}
 if not target.is_empty():
  if Rules.damage(type):
   var continuing=force_continuation or (spec.get("follow_through",false) and g.state.card_chain.get("type","")==type)
   p.preview=g.escape_preview(target,p.mode,base_damage(g,type,uid),assist_profiles,false,false,continuing,false,spec.get("ignore_tightness_reduction",false))
   p.preview.face_value=face_damage_values(g,type,uid)["free" if p.free else "bound"][0]
   scale_card_preview(g,p.preview,p.mode)
   p.tool_bonus=g.InstalledTools.preview(g,target,Rules.damage_type(type,p.free),p.preview)
   if g.SpecialEquipment.is_reinforcement(target):
    p.preview.damage=0.0;p.preview.scaled_damage=0.0;p.preview.environment_true=0.0;p.preview.immune=false
  elif spec.mode=="lower": p.after=g.lower_durability(target.durability,target.maximum)
 return p

static func bind_payload(g, type: String, uid: String="", second: bool=false) -> Dictionary:
 var mode=Rules.face_mode(type,second)
 var fixed=mode=="lower"
 var buff_multiplier=1.0 if fixed else damage_multiplier(g,"equipment")*card_damage_multiplier(g,mode)*g.Character.damage_multiplier(g)
 var guard_multiplier=1.0 if fixed else g.CaptureBind.damage_multiplier(g)
 var multiplier=guard_multiplier*buff_multiplier
 var base=g.CaptureBind.LOWER_DAMAGE if fixed else base_damage(g,type,uid)
 var values={"bonus":0.0,"charge":0.0,"raw":base} if fixed else g.escape_values(mode,base)
 var raw=values.raw
 return {"type":type,"slot":g.CaptureBind.BIND_TARGET,"target":g.CaptureBind.BIND_TARGET,"free":second,"mode":mode,
  "preview":{"guard_multiplier":guard_multiplier,"damage_buff_multiplier":buff_multiplier,"base":base,"bonus":values.bonus,"charge":values.charge,"raw":raw,"face_value":raw,"multiplier":multiplier,"damage":raw*multiplier,"environment_true":0.0}}

static func reason(g, p: Dictionary) -> String:
 if not action_ignores_restraints(g) and p.type=="henshin" and g.state.equipment.any(func(e):return g.Equipment.lock_only(e)):
  return "佩戴限制项圈时不能使用 henshin；品相完美版不受影响。"
 var spec=Rules.SPECS[p.type]
 if spec.mode=="power":
  var selected=Rules.BUFFS[spec.self_faces["free" if p.free else "bound"].buff]
  var group=selected.get("exclusive_group","")
  if group!="" and active_buffs(g).any(func(id):return Rules.BUFFS[id].get("exclusive_group","")==group):
   return "两面互斥：本场已启用「%s」，不能再次启用任一面。" % g.B.CARD_NAMES[p.type]
 # Phase restrictions apply before self-targeted cards return without equipment checks.
 if g.state.phase=="rest" and Rules.free_effect(p.type,p.free): return "休息房禁止卡牌自由效果。"
 if spec.has("select_exhaust") and selection_cards(g,p.get("uid","")).size()<spec.select_exhaust: return "需要至少3张可消耗的牌。"
 var pressure=0.0 if p.get("replay",false) else Rules.face_pressure_cost(p.type,p.free)
 if g.state.pressure<pressure: return "需要至少%s点快感。" % g.number(pressure)
 if spec.has("all_mana_minimum") and g.state.mana+g.state.temporary_mana<spec.all_mana_minimum: return "自身与临时魔力合计至少需要%s点。" % g.number(spec.all_mana_minimum)
 var witch_issue=g.Character.Expansion.reason(g,p)
 if witch_issue!="": return witch_issue
 if spec.get("drinking",false):
  var drinking_issue=Hannya.reason(g)
  if drinking_issue!="": return drinking_issue
 if spec.get("exhaust_hand",false) and p.get("kind","")=="card" and not p.get("replay",false):
  if not g.state.hand.any(func(card):return card.uid!=p.uid and card.uid==p.get("hand_uid","")): return "需要选择另一张当前手牌来消耗。"
 if Rules.free_effect(p.type,p.free):
  if spec.get("free_effects",[]).any(func(effect):return effect.op=="self_toy") and not g.Application.can_apply(g,SelfBinding.toy_spec(g),p.type): return "没有位置佩戴新的初级性玩具。"
  var blocked=spec.get("free_slots",[]).filter(func(slot):return g.targets_at(slot).any(func(target):return g.tier(target.durability,target.maximum)>0))
  if not action_ignores_restraints(g) and not blocked.is_empty(): return "需要%s无拘束。" % "、".join(blocked.map(func(slot):return g.B.SLOT_NAMES[slot]))
  for region in spec.get("free_max_levels",{}):
   var limit=spec.free_max_levels[region]
   if not action_ignores_restraints(g) and g.level(region)>limit: return "需要%s束缚等级≤%d，当前为%d。" % ["腿部" if region=="legs" else "上身",limit,g.level(region)]
 if spec.has("self_faces"):
  var face=spec.self_faces["free" if p.free else "bound"]
  if face.has("self_install") and SelfBinding.install_options(g,face.self_install.grade,face.self_install.tier).is_empty(): return "没有位置佩戴新的拘束具。"
  if face.has("requires_posture") and g.state.posture!=face.requires_posture: return "仅限%s使用。" % g.B.POSE_NAMES[face.requires_posture]
  if face.has("posture"):
   var posture_issue=g.CaptureBind.posture_reason(g,face.posture)
   if posture_issue!="": return posture_issue
  if face.has("requires_successful_spell") and face.requires_successful_spell not in g.state.combat.successful_spells:
   return "本回合尚未成功使用%s。" % g.BasicAttacks.TYPES[face.requires_successful_spell][0].name
  if face.get("requires_hand",false) and not action_ignores_restraints(g):
   var hand_issue=g.hand_cast_reason()
   if hand_issue!="": return hand_issue
  if face.get("exhaust_hand",false):
   if not g.state.hand.any(func(card):return card.uid!=p.get("uid","") and card.uid==p.get("hand_uid","")): return "需要选择另一张当前手牌来消耗。"
  var blocked=face.get("free_slots",[]).filter(func(slot):return g.targets_at(slot).any(func(target):return g.tier(target.durability,target.maximum)>0))
  if not action_ignores_restraints(g) and not blocked.is_empty(): return "需要%s无拘束。" % "、".join(blocked.map(func(slot):return g.B.SLOT_NAMES[slot]))
  if face.has("buff"):
   var buff_issue="" if action_ignores_restraints(g) else buff_requirement(g,Rules.BUFFS[face.buff])
   if buff_issue!="": return buff_issue
   if Rules.BUFFS[face.buff].duration=="battle" and g.state.phase not in g.RelicEffects.COMBAT_PHASES: return "这项增益只能在战斗中使用。"
   if face.buff in active_buffs(g,true) and not Rules.BUFFS[face.buff].get("stackable",false) and not Rules.BUFFS[face.buff].get("stack_uses",false): return "唯一："+Rules.BUFFS[face.buff].name+"已生效，不能重复叠加。"
 var issue=body_reason(g,p.type)
 if issue!="": return issue
 if spec.has("self_binding"): return SelfBinding.reason(g,p)
 if p.get("self_target",false): return ""
 if Rules.free_effect(p.type,p.free): return ""
 if spec.has("target_slots") and p.slot not in spec.target_slots and p.target!=g.CaptureBind.BIND_TARGET: return "只能处理%s的拘束具。" % "、".join(spec.target_slots.map(func(slot):return g.B.SLOT_NAMES[slot]))
 if p.target==g.CaptureBind.BIND_TARGET: return "" if g.CaptureBind.has_bind(g) and can_target_bind(p.type) else "捕缚已经解除。"
 var target=g._equipment(p.target)
 if target.is_empty(): return "原目标已经解除。"
 if g.Equipment.lock_only(target) and p.mode!="unlock": return g.Equipment.LOCK_ONLY_REASON
 if g.SpecialEquipment.is_special(target):
  issue=g.SpecialEquipment.escape_reason(g,target,p.mode,g.HandAssist.preview(g,target).hands)
  if issue!="": return issue
 if p.has("preview"): return p.preview.reason
 if p.mode=="lower": return g._slip_reason(target,p.mode)
 if p.mode=="unlock":
  if not target.locked: return "这件装备没有上锁，不能使用开锁效果。"
  if not g._outer(target): return "锁定目标被外层覆盖，无法处理。"
 return ""

static func detail(g, p: Dictionary) -> String:
 if p.get("self_target",false):
  if Rules.SPECS[p.type].has("hannya_stage"): return Hannya.detail(g,Rules.SPECS[p.type].hannya_stage,p.free)+Rules.SPECS[p.type].get("play_music_text","")
  var face_args={"type":p.type,"free":p.free,"uid":""}
  var text=g.CopyRouter.text(g,{"kind":"card.face_text","args":face_args,"fallback":face_text_detail(g,face_args)})
  if Rules.SPECS[p.type].has("self_binding"): text+="\n"+SelfBinding.detail(g,p)
  if p.get("hand_uid","")!="":
   var chosen=g._card(p.hand_uid)
   if not chosen.is_empty(): text+="本次消耗「%s」。" % g.B.CARD_NAMES[chosen.type]
  var face=Rules.SPECS[p.type].get("self_faces",{}).get("free" if p.free else "bound",{})
  if face.has("pressure_energy"): text+="本次获得%d能量。" % int(g.state.pressure/face.pressure_energy)
  if face.get("balance_mana_pressure",false): text+="当前均分值：%s。" % g.number((g.state.mana+g.state.pressure)/2.0)
  if face.has("refresh_spell"):
   var usage=g.BasicAttacks.usage(g,face.refresh_spell)
   text+="当前剩余%d／%d次。" % [usage.remaining,usage.limit]
  if face.has("spell_base_bonus"):
   var bonus=face.spell_base_bonus
   text+="当前永久加伤＋%d，使用后＋%d。" % [g.state.spell_base_bonuses.get(bonus.spell,0),g.state.spell_base_bonuses.get(bonus.spell,0)+bonus.amount]
  return text
 if Rules.free_effect(p.type,p.free): return g.B.card_info(p.type)[2]
 if p.target==g.CaptureBind.BIND_TARGET:
  var preview=p.preview
  if p.mode=="lower": return "每层降紧固定削减%s点捕缚；不受属性、蓄力或伤害倍率影响，不消耗蓄力。" % g.number(preview.damage)+Rules.effect_details(Rules.SPECS[p.type])
  var detail="对捕缚造成%s点%s伤害。牌面基础、属性与蓄力全额计入；不计算紧度、堆叠、锁和环境加成。" % [g.number(preview.damage),"挣扎" if p.mode=="strain" else "滑脱"]
  if preview.guard_multiplier>1.0: detail+="\n当前除眼罩、口球外没有其他拘束具，伤害×2。"
  if preview.damage_buff_multiplier>1.0: detail+="\n卡牌伤害增益×%s。" % g.number(preview.damage_buff_multiplier)
  detail+="\n（%s基础＋%s属性＋%s蓄力）×%s = %s" % [g.number(preview.base),g.number(preview.bonus),g.number(preview.charge),g.number(preview.multiplier),g.number(preview.damage)]
  return detail+Rules.effect_details(Rules.SPECS[p.type])
 var target=g._equipment(p.target)
 if p.has("preview"):
  var text="对%s造成%s点%s伤害。" % [g._equipment_name(target),g.number(p.preview.get("scaled_damage",p.preview.damage)),"挣扎" if p.mode=="strain" else "滑脱"]
  if p.preview.get("environment_true",0)>0: text+="另加%s点粗糙墙面真实伤害。" % g.number(p.preview.environment_true)
  text+="\n"+g._formula(p.preview)
  text+="\n"+p.preview.assist.detail
  if p.preview.get("link_factor",1.0)>1.0: text+="\n这件装备仅向下连接，滑脱伤害×%s（已计入）。" % g.number(p.preview.link_factor)
  if not p.get("tool_bonus",{}).is_empty(): text+="\n借助%s的%s：另加%s固定切割，消耗1次工具；同张牌不重复触发。" % [p.tool_bonus.mount,p.tool_bonus.name,g.number(p.tool_bonus.damage)]
  if p.preview.release: text+="\n条件已满足：本次挣扎直接脱下整件单手套。"
  text+=Rules.effect_details(Rules.SPECS[p.type])
  text+=Splash.detail(g,p)
  if Rules.SPECS[p.type].get("follow_through",false): text+="\n"+(Rules.SUPER_FOLLOW_THROUGH_TEXT if Rules.SPECS[p.type].get("follow_through_scope","region")=="body" else Rules.FOLLOW_THROUGH_TEXT)
  elif Rules.SPECS[p.type].get("hits",1)>1: text+="\n只付一次费用，每段可重新选择目标；没有可选目标时结束。"
  return text
 if p.mode=="unlock":
  var remaining=g.state.card_chain.remaining if p.get("kind","")=="chain" else Rules.SPECS[p.type].get("hits",1)
  var continuation_text="这次完成后至多还可处理%d把外露锁，不再付费。" % (remaining-1) if remaining>1 else ("这是最后一把锁，不再付费。" if p.get("kind","")=="chain" else "")
  if g.Equipment.lock_only(target): return "打开限制项圈的锁；双臂自由后可取下。"+continuation_text
  return "解除%s的锁，耐久和紧度不变。%s" % [target.name,continuation_text]
 if target.has("parent_id"): return "%s耐久 %s → %s，仅削减连接耐久，原装备紧度不变。" % [target.name,g.number(target.durability),g.number(p.after)]
 var lower_text="%s耐久 %s → %s，降紧1档。" % [target.name,g.number(target.durability),g.number(p.after)]
 if Rules.SPECS[p.type].get("follow_through",false): lower_text+="总计降紧%d档，目标解除后%s。" % [Rules.SPECS[p.type].hits,"超级顺延" if Rules.SPECS[p.type].get("follow_through_scope","region")=="body" else "顺延"]
 return lower_text

# 卡牌事实（手牌域，docs/spec/candidate-removal.md §2.1 T5／T8；批 R3）：行与显示事实的唯一来源。
# 返回事实列表（payload／label／copy／cost／mana／reason／risk／group），判定与 detail 由 Game 的事实入口给出。
static func target_facts(g, p: Dictionary, label: String, cost: int, mana: float, risk: String="") -> Array:
 var facts=[]
 var choices=[p]
 if Rules.SPECS[p.type].get("exhaust_hand",false):
  choices=[]
  for card in g.state.hand:
   if card.uid==p.uid: continue
   var selected=p.duplicate();selected.hand_uid=card.uid;choices.append(selected)
  if choices.is_empty():
   p.hand_uid="";choices.append(p)
 for choice in choices:
  # B3（docs/ondemand-copy.md §1.5）：descriptor 只留类别与参数，detail 由 Game.candidate_detail 现算。
  facts.append(g._fact(choice,label,{"kind":"card.target","args":{"payload":choice}},cost,mana,reason(g,choice),risk,"card"))
 return facts

# R3（docs/ondemand-copy.md §11.5）：转发包装的文案参数改走路由，签名与产出保持不变。
# R6（docs/ondemand-copy.md §11.5）：单面卡面正文的 builder，正文留在本模块。
static func face_text_detail(g, args: Dictionary) -> String:
 return face_text(g,String(args.get("type","")),bool(args.get("free",false)),String(args.get("uid","")))

static func target_detail(g, args: Dictionary) -> String:
 var payload=args.get("payload",{})
 var text=detail(g,payload)
 if payload.get("hand_uid","")!="": text+="\n本次消耗「%s」。" % g.B.CARD_NAMES[g._card(payload.hand_uid).type]
 return text

static func card_facts(g, card: Dictionary) -> Array:
 var facts=[]
 if g.B.CARD_TRAITS.get(card.type,{}).get("unplayable",false): return facts
 var spec=Rules.SPECS[card.type]
 if spec.has("free_slots"):
  var free_payload={"kind":"card","uid":card.uid,"type":card.type,"slot":spec.free_slots[0],"target":"","free":true,"mode":spec.mode}
  facts.append_array(target_facts(g,free_payload,"自由 · "+g.B.CARD_NAMES[card.type],energy_cost(g,card.type,true),face_mana(g,card.type,true)))
 if spec.has("self_faces"):
  for side in ["bound","free"]:
   var p={"kind":"card","uid":card.uid,"type":card.type,"slot":"","target":"self","free":side=="free","mode":spec.mode,"self_target":true}
   if spec.get("x_cost",false): p.x=energy_cost(g,card.type,side=="free")
   var choices=[p]
   if spec.self_faces[side].get("exhaust_hand",false):
    choices=[]
    for chosen in g.state.hand:
     if chosen.uid==card.uid: continue
     var selection=p.duplicate();selection.hand_uid=chosen.uid;choices.append(selection)
    if choices.is_empty():
     p.hand_uid="";choices.append(p)
   for choice in choices:
    var face_label=Rules.face_name(card.type,choice.free)+"面" if spec.has("bound_modes") else ("自由面" if choice.free else "挣脱面")
    facts.append(g._fact(choice,"打出「"+g.B.CARD_NAMES[card.type]+"」 · "+face_label,{"kind":"card.target","args":{"payload":choice}},energy_cost(g,card.type,choice.free),face_mana(g,card.type,choice.free),reason(g,choice),"","card"))
  return facts
 if Rules.single_face(card.type):
  var p={"kind":"card","uid":card.uid,"type":card.type,"slot":"","target":"self","free":false,"mode":spec.mode,"self_target":true}
  facts.append(g._fact(p,"打出「"+g.B.CARD_NAMES[card.type]+"」",{"kind":"card.target","args":{"payload":p}},energy_cost(g,card.type),0.0,reason(g,p),"","card"))
  return facts
 if can_target_bind(card.type) and g.CaptureBind.has_bind(g):
  for second in ([false,true] if spec.has("bound_modes") else [false]):
   var bind=bind_payload(g,card.type,card.uid,second)
   bind.kind="card";bind.uid=card.uid
   var mana=face_mana(g,card.type,second)
   facts.append_array(target_facts(g,bind,"冲开捕缚 · %s伤害" % g.number(bind.preview.damage),energy_cost(g,card.type),mana))
 var assist_profiles=g.HandAssist.profiles(g)
 var seen_special=[]
 var face_costs={}
 var face_payments={}
 var slots=g.B.SLOTS+["neck","shoulder"]+g.SpecialEquipment.slots()
 for slot in spec.get("target_slots",[]):
  if slot not in slots: slots.append(slot)
 for slot in slots:
  var special=slot in ["neck","shoulder"] or slot in g.SpecialEquipment.slots()
  var declared=not spec.has("target_slots") or slot in spec.target_slots
  var targets
  if not declared:
   if special or spec.has("bound_modes") or g.occupied(slot): continue
   targets=[{}]
  else:
   targets=g.targets_at(slot)
   if special:
    if targets.is_empty(): continue
   elif targets.is_empty(): targets=[{}]
   elif slot!="shoulder" and not g.occupied(slot): targets.append({})
  for target in targets:
   if target.is_empty() and spec.has("bound_modes"): continue
   if not target.is_empty() and g.SpecialEquipment.is_special(target):
    if target.id in seen_special: continue
    seen_special.append(target.id)
   for second in ([false,true] if spec.has("bound_modes") else [false]):
    var p=target_payload(g,card.type,slot,target,assist_profiles,card.uid,second)
    if p.free and spec.has("free_slots"): continue
    p.kind="card";p.uid=card.uid
    if not face_costs.has(p.free):
     face_costs[p.free]=energy_cost(g,card.type,p.free)
     face_payments[p.free]=face_mana(g,card.type,p.free)
    var cost=face_costs[p.free]
    var mana=face_payments[p.free]
    var risk=("三档免疫普通滑脱，仅造成%s点墙面真实伤害。" % g.number(p.preview.environment_true) if p.preview.get("environment_true",0)>0 else "三档免疫普通滑脱：本次伤害为0，仍消耗能量与卡牌。") if p.has("preview") and p.preview.immune else ""
    var label="自由 · "+g.B.SLOT_NAMES[slot] if Rules.free_effect(card.type,p.free) else "解除 · "+g._equipment_name(target)
    if Rules.free_effect(card.type,p.free) and slot in ["palm","fingers"] and not g.equipment_at(slot).is_empty(): label="自由 · "+("右" if g.hand_blocked(slot,"left") else "左")+g.B.SLOT_NAMES[slot]
    if spec.has("bound_modes"): label=Rules.face_name(card.type,p.free)+" · "+g._equipment_name(target)
    facts.append_array(target_facts(g,p,label,cost,mana,risk))
 return facts

static func can_select_retain(g, card: Dictionary) -> bool:
 return card.retain_until<0 and not g.B.CARD_TRAITS.get(card.type,{}).get("retain",false)

static func request_retain(g, count: int, draw_after: int=0) -> void:
 g.state.retain_left=count
 g.state.retain_draw_after=draw_after
 g.state.pending_retain=g.state.hand.any(func(c):return can_select_retain(g,c))
 if not g.state.pending_retain: finish_retain(g)

static func finish_retain(g) -> void:
 var draw_after=g.state.retain_draw_after
 g.state.pending_retain=false;g.state.retain_left=0;g.state.retain_draw_after=0
 if draw_after>0: g._draw(draw_after)

static func retain(g, uid: String) -> void:
 var card=g._card(uid)
 card.retain_until=g.state.tick+1
 g._card_motion("retain",card)
 g.state.retain_left-=1
 g._emit("event","「"+g.B.CARD_NAMES[card.type]+"」保留至下回合结束。")
 if g.state.retain_left<=0 or not g.state.hand.any(func(c):return can_select_retain(g,c)): finish_retain(g)

# A played skill stays outside the draw/discard cycle until every segment and
# replayed effect has resolved. The play zone is internal and holds at most one
# physical card while a manual continuation is pending.
static func settle_played_card(g) -> void:
 if g.state.play.is_empty(): return
 var card=g.state.play.pop_back()
 g.Character.Expansion.evolve(g,card)
 var exhaust=g.B.CARD_TRAITS.get(card.type,{}).get("exhaust",false) or card.get("exhaust_after_play",false)
 card.erase("exhaust_after_play")
 g._card_motion("play_exhaust" if exhaust else "play",card)
 if exhaust: g.state.exhaust.append(card)
 else: g.state.discard.append(card)

static func cancel_chain(g) -> void:
 var ids=g.state.card_chain.get("action_buffs",[])
 g.state.card_chain={}
 settle_played_card(g)
 consume_action_buffs(g,ids)

static func play(g, c: Dictionary) -> void:
 var p=c.payload
 var card=g._card(p.uid)
 # Casting settles before any physical card movement, including door spells.
 var success=not uses_magic(p) or g._cast_magic(c)
 consume_first_magic(g,p)
 if g.Character.Expansion.skill_discount(g,p.type,p.free)>0: g.Character.consume_buff(g,"witch_circle_skills")
 if not success: return
 var pressure=0.0 if p.get("replay",false) else Rules.face_pressure_cost(p.type,p.free)
 if pressure>0:
  g.Pressure.lose(g,pressure)
  g._emit("event","「%s」消耗%s快感。" % [g.B.CARD_NAMES[p.type],g.number(pressure)],{"pressure_payment":{"uid":p.uid,"amount":pressure}})
 if Rules.SPECS[p.type].get("exhaust_hand",false):
  var chosen=g._card(p.hand_uid)
  g.state.hand.erase(chosen);chosen.retain_until=-1
  g.state.exhaust.append(chosen);g._card_motion("exhaust",chosen)
  g._emit("event","「%s」消耗了「%s」。" % [g.B.CARD_NAMES[p.type],g.B.CARD_NAMES[chosen.type]],{"card_cost":{"uid":p.uid,"exhausted_uid":chosen.uid}})
 var replay=g.Replay.take(g,"card",p.type,p.free)
 g.state.hand.erase(card);card.retain_until=-1
 if Rules.SPECS[card.type].card_type=="power":
  card.power_face="free" if p.free else "bound"
  if Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff].has("periodic"): card.power_progress=0
  for key in METER_FIELDS:
   if Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff].has(key): card[METER_FIELDS[key]]=0.0
  if Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff].get("restraint_draw",{}).get("next_turn",false): card.power_next_draw=0
  if Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff].has("card_cast_bonus"): card.power_cast_count=0
  if Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff].has("failure_conversion"): card.power_failure_count=0
  if replay and not Rules.unique_face(card.type,p.free): card.power_stacks=1+replay
  if Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff].has("first_magic"): card.power_magic_remaining=card.get("power_stacks",1)
  g.state.powers.append(card)
  g._card_motion("play_power",card)
  var buff=Rules.BUFFS[Rules.SPECS[card.type].self_faces[card.power_face].buff]
  g._emit("event","获得「"+buff.name+"」。",{"power":p.type,"face":card.power_face})
  apply_effects(g,Rules.SPECS[card.type].self_faces[card.power_face].get("effects",[]),Rules.SPECS[card.type])
  g.Character.Expansion.resolve(g,p)
  if replay: g._emit("event","唯一：这张能力不会重复生效。" if Rules.unique_face(card.type,p.free) else ("余势复演：这张能力牌的效果额外生效%d次。" % replay),{"replay":{"type":p.type,"skipped":Rules.unique_face(card.type,p.free)}})
  return
 if Rules.exhausts(p.type,p.free,g.B.CARD_TRAITS.get(p.type,{})): card.exhaust_after_play=true
 g.state.play.append(card)
 if Rules.SPECS[p.type].has("select_exhaust"):
  g.state.card_chain={"type":p.type,"slot":"","mode":"select_exhaust","remaining":Rules.SPECS[p.type].select_exhaust,"free":p.free}
  return
 var used=resolve(g,p)
 grow(g,p.type,p.uid)
 if not Rules.free_effect(p.type,p.free) and not p.get("self_target",false) and Rules.SPECS[p.type].get("hits",1)>1:
  g.state.card_chain={"type":p.type,"slot":p.slot,"remaining":Rules.SPECS[p.type].hits-1,"mode":p.mode,"tools_used":[] if used=="" else [used]}
  if Rules.SPECS[p.type].has("bound_modes"): g.state.card_chain.free=p.free
  if Rules.SPECS[p.type].get("follow_through",false):
   g.state.card_chain.region=Rules.follow_through_region(p.slot)
   g.state.card_chain.target=p.target
   g.state.card_chain.points=continuation_points(g,g._equipment(p.target),p.slot)
  if replay:
   g.state.card_chain.replay_targets=[g.Replay.target(p)]
   g.state.card_chain.replay_count=replay
 elif replay:
  g._cleanup()
  g.Replay.cards(g,p.type,[g.Replay.target(p)],[] if used=="" else [used],replay)
  settle_played_card(g)
 else: settle_played_card(g)

static func resolve(g, p: Dictionary) -> String:
 if p.get("self_target",false):
  var spec=Rules.SPECS[p.type]
  if spec.has("self_binding"):
   SelfBinding.resolve(g,p)
   return ""
  if spec.has("hannya_stage"):
   Hannya.resolve(g,p)
   return ""
  var face=spec.get("self_faces",{}).get("free" if p.free else "bound",{})
  if face.has("posture"): g.change_posture(face.posture)
  var installed=[]
  if face.has("self_install"):
   var choices=SelfBinding.install_options(g,face.self_install.grade,face.self_install.tier)
   if choices.is_empty(): return "没有位置佩戴新的拘束具。"
   var outcome=SelfBinding.install(g,choices[g._random_index("equipment",choices.size())],p.type)
   if not outcome.ok: return outcome.reason
   installed=outcome.installed
  g.Character.Expansion.resolve(g,p)
  var exhausted={}
  if face.get("exhaust_hand",false):
   exhausted=g._card(p.hand_uid)
   g.state.hand.erase(exhausted);exhausted.retain_until=-1
   g.state.exhaust.append(exhausted);g._card_motion("exhaust",exhausted)
  var energy=int(face.get("energy_gain",0))
  if face.has("pressure_energy"): energy+=int(g.state.pressure/face.pressure_energy)
  energy=g._gain_energy(energy)
  var mana_before=g.state.mana
  g.state.mana=minf(g.state.mana_max,g.state.mana+face.get("mana_gain",0.0))
  if face.has("spell_base_bonus"):
   var bonus=face.spell_base_bonus
   g.state.spell_base_bonuses[bonus.spell]=int(g.state.spell_base_bonuses.get(bonus.spell,0))+bonus.amount
  if face.has("buff"): grant_buff(g,face.buff)
  var worn_count_before=worn_count(g)
  var worn_gain=Rules.worn_gain(face,worn_count_before)
  if face.has("worn_resource"):
   if face.worn_resource.resource=="mana": g.state.mana=minf(g.state.mana_max,g.state.mana+worn_gain)
   elif face.worn_resource.resource=="charge": g._gain_charge(worn_gain)
   elif face.worn_resource.resource=="strength":
    for stack in range(worn_gain): grant_buff(g,face.worn_resource.buff)
   else: g.state.turn_strength+=worn_gain
  var face_effects=face.get("effects",[]).duplicate(true)
  var body_count=occupied_body_count(g) if face.has("body_draw_divisor") else 0
  if face.has("body_draw_divisor"): face_effects.append({"op":"draw","amount":int(body_count/face.body_draw_divisor)})
  var effect_results=apply_effects(g,face_effects,spec)
  if not installed.is_empty(): effect_results.push_front("佩戴「%s」" % installed[0].name)
  if face.has("worn_resource"):
   var gain_copy={"mana":"恢复%s魔力","turn_strength":"本回合力量＋%s","strength":"力量＋%s","charge":"获得%s层蓄力"}[face.worn_resource.resource]
   effect_results.append(gain_copy % g.number(g.state.mana-mana_before if face.worn_resource.resource=="mana" else worn_gain))
  var batch_cards=[]
  if face.has("exhaust_hand_batch"):
   var batch=face.exhaust_hand_batch
   # Freeze the eligible physical hand cards before applying any per-card reward.
   var selected=g.state.hand.filter(func(card):return card.uid!=p.uid and Rules.hand_batch_matches(card.type,batch))
   for card in selected:
    g.state.hand.erase(card);card.retain_until=-1
    g.state.exhaust.append(card);g._card_motion("exhaust",card)
    batch_cards.append(card.uid)
   var batch_mana_before=g.state.mana
   g.state.mana=minf(g.state.mana_max,g.state.mana+batch.get("mana_gain",0.0)*batch_cards.size())
   var effects=batch.get("effects",[]).duplicate(true)
   for effect in effects: effect.amount=Rules.amount(effect,spec)*batch_cards.size()
   if not batch_cards.is_empty(): effect_results.append_array(apply_effects(g,effects,spec))
   if batch.has("mana_gain"): effect_results.append("恢复%s魔力" % g.number(g.state.mana-batch_mana_before))
  if face.has("energy_gain") or face.has("pressure_energy"): effect_results.append("获得%d能量" % energy)
  if face.has("mana_gain"): effect_results.append("恢复%s魔力" % g.number(g.state.mana-mana_before))
  if face.has("buff"): effect_results.append("获得「"+Rules.BUFFS[face.buff].name+"」")
  if face.has("spell_base_bonus"):
   var bonus=face.spell_base_bonus
   effect_results.append("%s基础伤害永久＋%d" % [g.BasicAttacks.TYPES[bonus.spell][0].name,bonus.amount])
  if p.type=="hannya_henshin":
   for target in g.state.equipment:
    if g.Equipment.lock_only(target): g._apply_manual_release(target,0.0,true)
  if face.get("release_all",false):
   g.CaptureBind.clear_bind(g)
   for target in g.action_targets():
    if g.cursed_eyes(target) or g.cursed_plate(target): continue
    if g.Equipment.lock_only(target):
     continue
    target.locked=false
    g._apply_manual_release(target,0.0)
  var record={"card":p.type,"free":p.free,"energy_gain":energy}
  if not installed.is_empty(): record.self_install=installed.map(func(item):return item.id)
  if face.has("body_draw_divisor"): record.body_draw={"count":body_count,"requested":int(body_count/face.body_draw_divisor)}
  if face.has("worn_resource"): record.worn_resource={"count":worn_count_before,"resource":face.worn_resource.resource,"amount":worn_gain,"actual":g.state.mana-mana_before if face.worn_resource.resource=="mana" else worn_gain}
  if face.get("balance_mana_pressure",false): g.Pressure.balance_mana(g)
  var result_text="，".join(effect_results)+"。" if not effect_results.is_empty() else ""
  if face.has("exhaust_hand_batch"):
   record.exhausted_cards=batch_cards
   result_text="消耗%d张%s牌%s" % [batch_cards.size(),Rules.hand_batch_type_text(face.exhaust_hand_batch),"。" if result_text=="" else "，"+result_text]
  if not exhausted.is_empty():
   record.exhausted_card=exhausted.uid
   result_text="消耗「%s」，%s。" % [g.B.CARD_NAMES[exhausted.type],"，".join(effect_results)]
  if face.has("optional_draw"):
   var extra=face.optional_draw
   var payment=g._mana_payment(p,0.0 if p.get("replay",false) else float(extra.mana_cost))
   if g.state.mana>=payment.mana:
    g._pay_mana(payment)
    var before_draw=g.state.hand.size()
    g._draw(extra.count)
    var drawn=g.state.hand.size()-before_draw
    record.optional_draw={"payment":payment,"drawn":drawn}
    result_text+=("免费追加抽到%d张牌。" % drawn if p.get("replay",false) else "额外支付%s魔力（临时魔力%s、自身魔力%s），追加抽到%d张牌。" % [g.number(extra.mana_cost),g.number(payment.temporary_mana),g.number(payment.mana),drawn])
   else:
    record.optional_draw={"payment":{},"drawn":0}
    result_text+="剩余魔力不足%s，未追加抽牌。" % g.number(extra.mana_cost)
  if face.has("refresh_spell"):
   var spell=face.refresh_spell
   var usage=g.BasicAttacks.usage(g,spell)
   g.state.combat.attack_uses[spell]=0
   record.refreshed_spell={"spell":spell,"before":usage.remaining,"after":usage.limit}
   result_text="%s剩余次数：%d → %d。" % [g.BasicAttacks.TYPES[spell][0].name,usage.remaining,usage.limit]
  g._emit("event",("额外释放「" if p.get("replay",false) else "打出「")+g.B.CARD_NAMES[p.type]+"」。"+result_text,record)
  return ""
 if Rules.free_effect(p.type,p.free):
  var results=apply_effects(g,Rules.SPECS[p.type].get("free_effects",[]),Rules.SPECS[p.type])
  g._emit("event","对自由的%s使用「%s」。%s" % [g.B.SLOT_NAMES[p.slot],g.B.CARD_NAMES[p.type],"，".join(results)+"。" if not results.is_empty() else ""])
  return ""
 return hit(g,p)

static func hit(g, p: Dictionary) -> String:
 if p.target=="prison_door":
  g.state.prison.door_open=true
  g._emit("event","施法打开了牢门锁。")
  return ""
 if p.target==g.CaptureBind.BIND_TARGET:
  if p.mode!="lower": g._consume_charge()
  g.CaptureBind.damage_bind(g,p.preview.damage,"「"+g.B.CARD_NAMES[p.type]+"」")
  if p.mode!="lower": consume_card_damage(g,p.mode,p.preview.damage)
  apply_effects(g,Rules.SPECS[p.type].get("hit_effects",[]),Rules.SPECS[p.type])
  return ""
 var target=g._equipment(p.target)
 if g.cursed_eyes(target): return "诅咒眼罩封闭了眼部装备操作。"
 if g.cursed_plate(target): return g.SpecialEquipment.CURSED_PLATE_REASON
 if p.mode=="unlock":
  target.locked=false
  g._emit("event","「"+g.B.CARD_NAMES[p.type]+"」解除了"+target.name+"的锁。")
 elif p.mode=="lower":
  var before=target.durability;target.durability=p.after
  var name=g.B.CARD_NAMES[p.type]
  var record={"action_result":g.ActionCopy.equipment_result(name,target.name,before,target.durability),"lower_steps":1}
  if Rules.SPECS[p.type].get("follow_through",false): record.follow_through_hit={"target":target.id,"slot":p.slot,"hit":Rules.SPECS[p.type].hits-g.state.card_chain.remaining+1 if not g.state.card_chain.is_empty() else 1,"before":before,"after":target.durability}
  g._emit("mechanical","%s：%s耐久 %s → %s。" % [name,target.name,g.number(before),g.number(target.durability)],record)
 else:
  var before_tier=g.tier(target.durability,target.maximum)
  var old=target.durability
  var splashes=Splash.select(g,p)
  g._apply_equipment_damage(target,p.preview.damage,Rules.damage_type(p.type,p.free))
  var record=p.preview.duplicate(true)
  record.action_result=g.ActionCopy.equipment_result("「%s」" % g.B.CARD_NAMES[p.type],target.name,old,target.durability,Rules.damage_type(p.type,p.free))
  if Rules.SPECS[p.type].get("follow_through",false): record.follow_through_hit={"target":target.id,"slot":p.slot,"hit":Rules.SPECS[p.type].hits-g.state.card_chain.remaining+1 if not g.state.card_chain.is_empty() else 1,"before":old,"after":target.durability}
  g._emit("mechanical","「%s」处理%s：%s。耐久 %s → %s。" % [g.B.CARD_NAMES[p.type],target.name,g._formula(p.preview),g.number(old),g.number(target.durability)],record)
  if p.mode!="strain": g.RelicEffects.card_slipped(g,before_tier,target)
  if p.preview.immune: g._emit("event","三档紧度挡住了普通滑脱，粗糙墙面仍磨去%s点耐久。" % g.number(minf(old,p.preview.environment_true)) if p.preview.get("environment_true",0)>0 else "三档紧度阻止了这次滑脱，装备没有松开。")
  if target.durability>0 and g.tier(target.durability,target.maximum)<before_tier:
   apply_effects(g,Rules.SPECS[p.type].get("lowered_effects",[]),Rules.SPECS[p.type],g.B.CARD_NAMES[p.type])
  if target.durability<=0:
   apply_effects(g,Rules.SPECS[p.type].get("destroyed_effects",[]),Rules.SPECS[p.type],g.B.CARD_NAMES[p.type])
  Splash.apply(g,p,splashes)
  var actual_damage=minf(old,p.preview.damage)
  for splash in splashes: actual_damage+=splash.preview.damage
  consume_card_damage(g,p.mode,actual_damage)
 apply_effects(g,Rules.SPECS[p.type].get("hit_effects",[]),Rules.SPECS[p.type])
 return g.InstalledTools.apply(g,target,p.get("tool_bonus",{}))

static func continuation_points(g, target: Dictionary, slot: String) -> Array:
 if target.is_empty(): return []
 if g.Equipment.is_shoulder(target): return ["shoulder_"+target.get("side",target.get("part",""))]
 var slots=g.Equipment.points(slot)
 return g.Equipment.physical_points(target).filter(func(point):return point in slots)

static func continuation_part(g, slot: String) -> Array:
 for group in g.Equipment.PANEL_GROUPS:
  if group is Array and slot in group: return group
 return [slot]

# Select within the current physical point, then body part, then original region.
# Queries never roll; normalize chooses once during the enclosing transaction.
static func follow_through_facts(g) -> Array:
 var chain=g.state.card_chain
 var whole_body=Rules.SPECS[chain.type].get("follow_through_scope","region")=="body"
 var out=[]
 var current=g._equipment(chain.target)
 var profiles=g.HandAssist.profiles(g)
 if not current.is_empty():
  var p=target_payload(g,chain.type,chain.slot,current,profiles,"",chain.get("free",false))
  if reason(g,p)=="":
   p.kind="chain";p.action="hit"
   out.append(g._fact(p,"继续 · "+g._equipment_name(current),detail(g,p),0,0.0,"","","chain"))
  if not out.is_empty() or not whole_body: return out
 var region=Rules.FOLLOW_THROUGH_REGIONS[Rules.follow_through_region(chain.slot) if whole_body else chain.region]
 var part=continuation_part(g,chain.slot).filter(func(slot):return slot in region)
 var slots=[chain.slot]+part.filter(func(slot):return slot!=chain.slot)+region.filter(func(slot):return slot not in part)
 if whole_body: slots.append_array(Rules.FOLLOW_THROUGH_SLOTS.filter(func(slot):return slot not in region))
 var seen=[]
 var best=4
 var best_priority=-1
 for slot in slots:
  for target in g.targets_at(slot):
   if target.id in seen or not g._outer(target): continue
   seen.append(target.id)
   var p=target_payload(g,chain.type,slot,target,profiles,"",chain.get("free",false))
   if reason(g,p)!="": continue
   var rank=2 if slot in region else 3
   if slot in part:
    rank=0 if continuation_points(g,target,slot).any(func(point):return point in chain.points) else 1
   if rank>best: continue
   if rank<best: out.clear();best=rank;best_priority=-1
   if rank==3:
    var priority=g.Equipment.slot_priority(slot)
    if priority<best_priority: continue
    if priority>best_priority: out.clear();best_priority=priority
   p.kind="chain";p.action="hit"
   out.append(g._fact(p,("超级顺延 · " if whole_body else "顺延 · ")+g._equipment_name(target),detail(g,p),0,0.0,"","","chain"))
 return out

static func selection_cards(g, exclude_uid: String="") -> Array:
 var cards=[]
 for zone in ["draw","hand","discard"]:
  for card in g.state[zone]:
   if card.uid!=exclude_uid: cards.append({"zone":zone,"card":card})
 return cards

static func select_exhaust(g, p: Dictionary) -> void:
 for entry in selection_cards(g):
  if entry.card.uid!=p.selected_uid: continue
  g.state[entry.zone].erase(entry.card)
  entry.card.retain_until=-1
  g.state.exhaust.append(entry.card)
  g._card_motion("exhaust",entry.card)
  g._emit("event","消耗「%s」。" % g.B.CARD_NAMES[entry.card.type],{"selected_exhaust":entry.card.uid})
  break
 g.state.card_chain.remaining-=1
 if g.state.card_chain.remaining>0: return
 finish_chain(g)
 g._draw(3)
 g.Pressure.gain(g,30,"强制高潮")
 g.Pressure.forced_climax(g,"强制高潮")

# 连锁继续（批 R4：行与显示事实的唯一来源，docs/spec/candidate-removal.md §2.1 T5／T8）。
static func chain_facts(g) -> Array:
 var out=[]
 var chain=g.state.card_chain
 if chain.is_empty(): return out
 if chain.mode=="select_exhaust":
  for entry in selection_cards(g):
   var zone_name={"draw":"抽牌堆","hand":"手牌","discard":"弃牌堆"}[entry.zone]
   out.append(g._fact({"kind":"chain","action":"select_exhaust","type":chain.type,"free":chain.free,"selected_uid":entry.card.uid},"消耗 · "+g.B.CARD_NAMES[entry.card.type]+" · "+zone_name,"仅在本场消耗这张牌。",0,0.0,"","","chain"))
  return out
 if Rules.SPECS[chain.type].get("follow_through",false) and chain.slot!=g.CaptureBind.BIND_TARGET: return follow_through_facts(g)
 var assist_profiles=g.HandAssist.profiles(g)
 var targets=g.action_targets() if chain.mode=="unlock" else ([{"id":g.CaptureBind.BIND_TARGET}] if chain.slot==g.CaptureBind.BIND_TARGET and g.CaptureBind.has_bind(g) else g.targets_at(chain.slot))
 var seen=[]
 for target in targets:
  if target.id!=g.CaptureBind.BIND_TARGET and g.SpecialEquipment.is_special(target):
   if target.id in seen: continue
   seen.append(target.id)
  var p=bind_payload(g,chain.type,"",chain.get("free",false)) if target.id==g.CaptureBind.BIND_TARGET else target_payload(g,chain.type,chain.slot,target,assist_profiles,"",chain.get("free",false))
  if reason(g,p)!="": continue
  p.kind="chain";p.action="hit"
  out.append(g._fact(p,"继续 · "+("捕缚" if target.id==g.CaptureBind.BIND_TARGET else g._equipment_name(target)),detail(g,p),0,0.0,"","","chain"))
 if chain.mode=="unlock" and g.state.phase=="prison" and not g.state.prison.door_open and body_reason(g,chain.type)=="":
  out.append(g._fact({"kind":"chain","action":"hit","type":chain.type,"target":"prison_door","mode":"unlock","free":false},"继续 · 牢门锁","打开牢门锁，不额外消耗能量或魔力；离开时仍检查速度。",0,0.0,"需要先到牢门前。" if not g.Prison.Space.at(g,"door") else "","","chain"))
 return out

# 「结束连续开锁」的收尾行（只在 unlock 连锁中存在）：行与显示事实唯一来源。
static func chain_stop_fact(g) -> Dictionary:
 if g.state.card_chain.is_empty() or g.state.card_chain.mode!="unlock": return {}
 return g._fact({"kind":"chain","action":"stop","type":g.state.card_chain.type,"free":false,"mode":"unlock"},"结束连续开锁","保留已完成效果与已支付费用。",0,0.0,"","","chain")

# 连锁显示事实（批 R4 起、R5 收口）：连锁继续事实＋收尾事实（显示侧唯一来源）。
static func chain_display_facts(g) -> Array:
 if not g.chain_rows_active(): return []
 var out=chain_facts(g)
 var stop=chain_stop_fact(g)
 if not stop.is_empty(): out.append(stop)
 return out

static func continue_card(g, p: Dictionary) -> void:
 if p.action=="select_exhaust":
  select_exhaust(g,p)
  return
 if p.action=="stop":
  finish_chain(g)
  g._emit("event","连续开锁结束。")
  return
 if Rules.SPECS[p.type].get("follow_through",false) and p.target!=g.CaptureBind.BIND_TARGET:
  var chain=g.state.card_chain
  if chain.target!=p.target: g._emit("event",("超级顺延至" if Rules.SPECS[p.type].get("follow_through_scope","region")=="body" else "顺延至")+g.B.SLOT_NAMES[p.slot]+"的"+g._equipment_name(g._equipment(p.target))+"。",{"follow_through":{"from":chain.target,"target":p.target,"slot":p.slot,"hit":Rules.SPECS[p.type].hits-chain.remaining+1}})
  chain.target=p.target;chain.slot=p.slot
  chain.points=continuation_points(g,g._equipment(p.target),p.slot)
 if g.state.card_chain.has("replay_targets"): g.state.card_chain.replay_targets.append(g.Replay.target(p))
 var used=hit(g,p)
 if used!="":
  if not g.state.card_chain.has("tools_used"): g.state.card_chain.tools_used=[]
  g.state.card_chain.tools_used.append(used)
 g.state.card_chain.remaining-=1
 if g.state.card_chain.remaining<=0: finish_chain(g)

static func finish_chain(g) -> void:
 var chain=g.state.card_chain
 g.state.card_chain={}
 if chain.has("replay_targets"):
  g._cleanup()
  g.Replay.cards(g,chain.type,chain.replay_targets,chain.get("tools_used",[]),chain.replay_count)
 settle_played_card(g)
 consume_action_buffs(g,chain.get("action_buffs",[]))

static func normalize(g) -> void:
 # Recompute after cleanup, never reuse first-hit targets or damage.
 while not g.state.card_chain.is_empty():
  var choices=chain_facts(g)
  if choices.is_empty():
   finish_chain(g)
   g._emit("event","没有可继续处理的目标，连续行动结束。")
  elif Rules.SPECS[g.state.card_chain.type].get("follow_through",false):
   var index=g._random_index("card_target",choices.size()) if choices.size()>1 else 0
   continue_card(g,choices[index].payload)
   g._cleanup()
  elif choices.size()==1 and g.state.card_chain.mode not in ["unlock","select_exhaust"]:
   continue_card(g,choices[0].payload)
   g._cleanup()
  else: break

static func validate(g) -> String:
 if not g.state.get("turn_strength") is int or g.state.turn_strength<0: return "本回合力量加值不正确。"
 if g.state.turn_strength>0 and not g.RelicEffects.keeps_combat_state(g): return "本回合力量不能保留到本场以外。"
 if not g.state.get("evasion") is int or g.state.evasion<0: return "闪避层数不正确。"
 if g.state.evasion>0 and not g.RelicEffects.keeps_combat_state(g): return "闪避不能保留到本场以外。"
 if not g.state.get("spell_base_bonuses") is Dictionary: return "永久法术加伤记录不完整。"
 for spell in g.state.spell_base_bonuses:
  var amount=g.state.spell_base_bonuses[spell]
  if spell not in Rules.FIXED_MAGIC or not amount is int or amount<1: return "永久法术加伤记录不正确。"
 var permanent={};var live={}
 for zone in ["deck"]+ZONES:
  var collection=permanent if zone=="deck" else live
  for card in g.state[zone]:
   if collection.has(card.uid): return "同一张牌出现在卡组或多个牌堆中。"
   if not Rules.SPECS.has(card.type): return "卡牌类型不存在。"
   if OS.is_debug_build() and card.has("power_enabled"):
    var power_face=Rules.SPECS[card.type].get("self_faces",{}).get(card.get("power_face",""),{})
    if zone!="powers" or not card.power_enabled is bool or not Rules.BUFFS.get(power_face.get("buff",""),{}).get("toggleable",false): return "能力牌的开关记录不正确。"
   if card.has("power_failure_count") and (zone!="powers" or not card.power_failure_count is int or card.power_failure_count<0): return "能力牌的本回合失败计数不正确。"
   if card.has("power_cast_count") and (zone!="powers" or not card.power_cast_count is int or card.power_cast_count<0): return "能力牌的本回合出牌计数不正确。"
   if card.has("power_magic_remaining") and (zone!="powers" or not card.power_magic_remaining is int or card.power_magic_remaining<0): return "能力牌的首张魔法剩余次数不正确。"
   if card.has("damage_bonus"):
    var growth=Rules.SPECS[card.type].get("damage_growth",0)
    if zone=="deck" or growth<=0 or not card.damage_bonus is int or card.damage_bonus<0 or card.damage_bonus%growth!=0: return "卡牌的本场伤害成长不正确。"
   if card.has("power_next_draw") and (zone!="powers" or not card.power_next_draw is int or card.power_next_draw<0): return "能力牌的待抽牌数量不正确。"
   var practice_issue=g.Character.Expansion.validate_card(g,card)
   if practice_issue!="": return practice_issue
   collection[card.uid]=[card.type,card.get("practice_plays",0)] if Rules.SPECS[card.type].has("witch_training_stage") else card.type
 if permanent!=live: return "牌堆与卡组不一致。"
 if not g.state.powers.is_empty() and not g.RelicEffects.keeps_combat_state(g): return "战斗外不能保留已生效的能力。"
 var active=[]
 var exclusive=[]
 for card in g.state.powers:
  if Rules.SPECS[card.type].card_type!="power" or card.get("power_face","") not in ["bound","free"]: return "能力区的卡牌或牌面不正确。"
  var id=Rules.SPECS[card.type].self_faces[card.power_face].buff
  var buff=Rules.BUFFS[id]
  var group=buff.get("exclusive_group","")
  if group!="":
   if group in exclusive: return "互斥的能力牌不能同时生效。"
   exclusive.append(group)
  if buff.has("failure_conversion"):
   var count=card.get("power_failure_count",0)
   if not count is int or count<0 or count>buff.failure_conversion.zero_cost_limit: return "能力牌的本回合失败计数不正确。"
  elif card.has("power_failure_count"): return "这张能力没有失败次数限制。"
  if card.has("power_stacks") and (not card.power_stacks is int or card.power_stacks<2): return "能力牌的额外生效次数不正确。"
  if id in active and not Rules.BUFFS[id].get("stackable",false): return "同一来源的能力重复生效。"
  if Rules.BUFFS[id].has("card_cast_bonus"):
   if not card.get("power_cast_count") is int or card.power_cast_count<0: return "能力牌缺少本回合出牌计数。"
  elif card.has("power_cast_count"): return "这张能力不累计本回合出牌。"
  if buff.has("first_magic"):
   if not card.has("power_magic_remaining") or card.power_magic_remaining>card.get("power_stacks",1): return "能力牌的首张魔法剩余次数不正确。"
  elif card.has("power_magic_remaining"): return "这张能力没有首张魔法效果。"
  if Rules.unique_face(card.type,card.power_face=="free") and card.get("power_stacks",1)>1: return "唯一能力不能重复生效。"
  for key in METER_FIELDS:
   var field=METER_FIELDS[key]
   if Rules.BUFFS[id].has(key):
    var progress=card.get(field)
    if not (progress is float or progress is int) or not is_finite(float(progress)) or progress<0 or (progress>=Rules.BUFFS[id][key].step and g.state.card_chain.is_empty()): return "能力牌的累计资源进度不正确。"
   elif card.has(field): return "这张能力没有对应的累计资源效果。"
  if Rules.BUFFS[id].get("restraint_draw",{}).get("next_turn",false):
   if not card.get("power_next_draw") is int or card.power_next_draw<0: return "能力牌缺少下回合抽牌数量。"
  elif card.has("power_next_draw"): return "这张能力没有下回合抽牌效果。"
  if Rules.BUFFS[id].has("periodic"):
   if not card.get("power_progress") is int or card.power_progress<0 or card.power_progress>Rules.BUFFS[id].periodic.count: return "能力牌的累计出牌计数不正确。"
   if card.power_progress==Rules.BUFFS[id].periodic.count and g.state.card_chain.is_empty(): return "能力牌的触发尚未结算。"
  active.append(id)
 if not g.state.card_buffs is Array or not g.state.get("card_buff_uses") is Dictionary: return "卡牌增益记录不完整。"
 for id in g.state.card_buff_uses:
  var remaining=g.state.card_buff_uses[id]
  if id not in g.state.card_buffs or not Rules.BUFFS.has(id) or not remaining is int or remaining<1 or (not Rules.BUFFS[id].get("stack_uses",false) and remaining>Rules.BUFFS[id].get("attack_uses",0)): return "卡牌增益剩余次数不正确。"
 for id in g.state.card_buffs:
  if id not in Rules.BUFFS or id in active or Rules.SPECS.values().any(func(spec):return spec.mode=="power" and spec.self_faces.values().any(func(face):return face.buff==id)): return "卡牌增益来源不正确或重复。"
  if (Rules.BUFFS[id].has("attack_uses") or Rules.BUFFS[id].get("stack_uses",false)) and not g.state.card_buff_uses.has(id): return "卡牌增益缺少剩余次数。"
  if Rules.BUFFS[id].duration=="battle" and not g.RelicEffects.keeps_combat_state(g): return "战斗增益不能保留到战斗外。"
  active.append(id)
 var hannya_issue=Hannya.validate(g)
 if hannya_issue!="": return hannya_issue
 if g.state.hand.size()>g.B.HAND_LIMIT: return "手牌不能超过%d张。" % g.B.HAND_LIMIT
 for card in g.state.deck:
  if g.B.CARD_TRAITS.get(card.type,{}).get("temporary",false) and not g.RelicEffects.keeps_combat_state(g): return "临时卡牌不能保留到战斗外。"
 var chain=g.state.card_chain
 if g.state.play.size()>1: return "使用中的卡牌数量不正确。"
 if chain.is_empty()!=g.state.play.is_empty(): return "使用中的卡牌与连续效果不一致。"
 if not chain.is_empty():
  var type=chain.get("type","")
  if not Rules.SPECS.has(type): return "连续卡牌类型不存在。"
  if g.state.play[0].type!=type: return "使用中的卡牌类型与连续效果不一致。"
  if chain.has("action_buffs") and (not chain.action_buffs is Array or chain.action_buffs.any(func(id):return not id is String or id not in action_buff_ids(g) or chain.action_buffs.count(id)!=1)): return "连续卡牌的行动增益记录不正确。"
  if Rules.SPECS[type].get("follow_through",false): return "顺延必须在出牌时完整执行，不能保留未完成段数。"
  if chain.get("mode","")=="select_exhaust":
   if Rules.SPECS[type].get("select_exhaust",0)!=3 or not chain.get("remaining") is int or chain.remaining<1 or chain.remaining>3 or not chain.get("free") is bool: return "选牌消耗进度不正确。"
   if selection_cards(g).size()<chain.remaining or g.state.overloaded or g.state.phase not in ["battle","prepare","rest","prison"]: return "当前不能继续选牌消耗。"
  else:
   var hits=Rules.SPECS[type].get("hits",1)
   var remaining=chain.get("remaining",0)
   if not remaining is int or remaining<1 or remaining>=hits: return "卡牌剩余段数不合法。"
   var used=chain.get("tools_used",[])
   if chain.has("replay_targets"):
    if not chain.get("replay_count") is int or chain.replay_count<1: return "连续卡牌的复放次数不正确。"
    var targets=chain.replay_targets
    if not targets is Array or targets.size()!=hits-remaining or targets.any(func(p):return not p is Dictionary or p.size()!=3 or not p.get("slot") is String or not p.get("target") is String or p.get("self_target")!=false): return "连续卡牌的原目标记录不正确。"
   if not used is Array or used.any(func(id):return not id is String or not id.begins_with("item_") or used.count(id)!=1) or used.size()>hits-remaining: return "连续卡牌的工具使用记录不正确。"
   if chain.has("free") and not chain.free is bool: return "连续卡牌的牌面记录不正确。"
   if chain.get("mode","")!=Rules.face_mode(chain.type,chain.get("free",false)) or chain.get("slot","") not in g.B.SLOTS+["neck","shoulder",g.CaptureBind.BIND_TARGET]+g.SpecialEquipment.slots(): return "连续卡牌的部位或方法不合法。"
   if g.state.phase not in ["battle","prepare","rest","prison"] or g.state.overloaded: return "当前阶段不能继续卡牌效果。"
 if g.state.pending_retain and (not g.state.retain_left is int or g.state.retain_left<1 or not g.state.retain_draw_after is int or g.state.retain_draw_after<0): return "保留手牌的数量不合法。"
 for type in Rules.SPECS:
  var issue=Rules.definition_reason(Rules.SPECS[type])
  if issue!="": return issue
  if not g.B.CARD_NAMES.has(type) or not g.B.CARD_INFO.has(type): return "卡牌定义缺少显示信息。"
 return ""

static func apply_effects(g, effects: Array, spec: Dictionary, source: String="") -> Array:
 var results=[]
 for effect in effects:
  var value=Rules.amount(effect,spec)
  var description=Rules.effect_text(effect,spec)
  match effect.op:
   "pressure_loss":
    var loss=g.Pressure.lose(g,value)
    description="失去%s快感" % g.number(loss)
   "self_toy":
    var request=g.Application.choose(g,SelfBinding.toy_spec(g),source,"equipment")
    var outcome=g.Application.execute_concrete(g,request,source,false,[],true)
    if outcome.ok: description="佩戴了"+outcome.installed[0].name
    else: description=outcome.reason
   "buff":
    grant_buff(g,effect.buff)
    description="获得「"+Rules.BUFFS[effect.buff].name+"」"
    if Rules.BUFFS[effect.buff].has("attack_uses"): description+="，"+Rules.effect_text(effect,spec,true)
   "draw":
    var hand_size=g.state.hand.size()
    g._draw(value,effect.get("filter",{}))
    description="抽%d张%s" % [g.state.hand.size()-hand_size,Rules.draw_label(effect.get("filter",{}))]
    if effect.has("filter") and source=="": g._emit("event",description+"。",{"filtered_draw":{"filter":effect.filter,"requested":value,"drawn":g.state.hand.size()-hand_size}})
   "retain":
    if effect.get("all",false):
     for card in g.state.hand:
      card.retain_until=maxi(card.retain_until,g.state.tick+1)
      g._card_motion("retain",card)
     if effect.get("draw_after",0)>0: g._draw(effect.draw_after)
    else: request_retain(g,value,effect.get("draw_after",0))
   "reserve_mana": g.state.temporary_mana+=value*Rules.RESERVE_MANA_VALUE
   "energy":
    var received=effect.duplicate()
    received.amount=g._gain_energy(value)
    description=Rules.effect_text(received,{})
   "charge": g._gain_charge(value)
   "mana":
    var before=g.state.mana
    g.state.mana=minf(g.state.mana_max,before+value)
    description="恢复%s魔力" % g.number(g.state.mana-before)
   "pressure":
    g.Pressure.gain(g,value,source)
    results.append(description)
    continue
   _: g.state[effect.op]+=value
  if source!="": g._emit("event",source+"生效："+description+"。")
  results.append(description)
 return results

static func hand_modifier(g, attribute: String) -> float:
 var result=0.0
 for card in g.state.hand: result+=Rules.SPECS[card.type].get("hand_modifiers",{}).get(attribute,0.0)
 return result

static func hand_multiplier(g, attribute: String) -> float:
 var result=1.0
 for card in g.state.hand: result*=Rules.SPECS[card.type].get("hand_modifiers",{}).get(attribute,1.0)
 return result
