extends RefCounted

static func definition(g, id: String) -> Dictionary:
 return g.Relics.definition(id,g.state.get("ditto_form",""))

static func transform_pool(g) -> Array:
 return g.Relics.TYPES.keys().filter(func(id):return g.Relics.transformable(id) and g.Character.relic_allowed(g,id))

static func transform(g) -> void:
 if "ditto" not in g.state.relics: return
 var pool=transform_pool(g)
 g.state.ditto_form=pool[g._random_index("relic",pool.size())]
 g.state.relic_counters.erase("ditto")
 g.state.relic_pending.erase("ditto")
 for key in g.state.relic_used.keys():
  if String(key).begins_with("ditto:"): g.state.relic_used.erase(key)
 g._emit("event","百变怪变成了「%s」。" % definition(g,"ditto").name,{"relic_trigger":{"id":"ditto","name":"百变怪"},"relic_transform":{"type":g.state.ditto_form}})

const COMBAT_PHASES=["battle","prepare","rest","prison"]

static func keeps_combat_state(g) -> bool:
 if g.state.phase in COMBAT_PHASES+["inspection"]: return true
 return g.state.combat.active and (g.state.phase=="reward" or (g.state.phase=="event" and g.state.room_event.get("prepare_pending",false)))

static func phase_matches(g, phase: String) -> bool:
 return g.state.phase in COMBAT_PHASES if phase=="battle" else phase==g.state.phase

static func gain(g, id: String, source: String="") -> void:
 if not g.Relics.can_gain(g.state.relics,id): return
 if gain_reason(g,id)!="": return
 if id=="cursed_blindfold":
  for target in g.action_targets():
   if target.slot=="eyes": g._apply_manual_release(target,0.0)
  g._cleanup()
  var maximum=g.Equipment.maximum(3)
  g._install_template("eye_leather","eyes",maximum,maximum,true,"relic:cursed_blindfold",3)
 var owned=id in g.state.relics
 if g.Relics.TYPES[id].get("collectible",false): g.state.relic_counters[id]=int(g.state.relic_counters.get(id,1 if owned else 0))+1
 if not owned: g.state.relics.append(id)
 match id:
  "cursed_plate_lock":
   g._install_special("cursed_plate_lock","special_2_a",3)
  "tattoo_sticker":
   for i in range(2): g._gain_card("lewd_mark")
  "shining_lamp":
   g.state.mana_max-=50
   g.state.mana=minf(g.state.mana,g.state.mana_max)
 if g.Relics.TYPES[id].get("pickup_bundle",false): g.RelicBundle.start(g,id)
 for type in g.Relics.TYPES[id].get("pickup_cards",[]): g._gain_card(type)
 var spec=g.Relics.TYPES[id].modifiers
 var increase=float(spec.get("pickup_mana_max",0.0))
 g.state.mana_max+=increase
 var recovered=g.state.mana_max-g.state.mana if spec.get("pickup_mana_full",0)>0 else minf(float(spec.get("pickup_mana",0.0)),g.state.mana_max-g.state.mana)
 g.state.mana+=recovered
 var detail="获得"+g.Relics.TYPES[id].name+"。"
 for type in g.Relics.TYPES[id].get("pickup_cards",[]): detail+="「%s」已加入卡组。%s" % [g.B.CARD_NAMES[type],g.B.card_info(type)[3]]
 if spec.get("max_energy",0)>0: detail+="最大能量变为%d。" % g.max_energy()
 if id=="tattoo_sticker": detail+="2张「淫纹」已加入卡组。"
 if id=="shining_lamp": detail+="魔力上限降低50，当前魔力%s/%s。" % [g.number(g.state.mana),g.number(g.state.mana_max)]
 if id=="cursed_blindfold": detail+="永久佩戴高级、3档的上锁眼罩。"
 if g.Relics.TYPES[id].get("collectible",false): detail+="持有%d件。" % g.state.relic_counters[id]
 if increase>0: detail+="魔力上限永久＋%s，恢复%s魔力。" % [g.number(increase),g.number(recovered)]
 var marker="relic_pickup" if g.Relics.TYPES[id].get("collectible",false) else "relic_trigger"
 g._emit("event",detail,{marker:{"id":id,"name":g.Relics.TYPES[id].name}})
 var pressure=float(spec.get("pickup_pressure",0))
 if pressure>0: g.Pressure.gain(g,pressure,g.Relics.TYPES[id].name)
 g.state.pressure=cap_pressure(g,g.state.pressure)
 if id=="desire_cube_pro_max" and source=="boss":
  g._gain_card("itching_heart",{},true)
  var relic=g.RelicRewards.offer(g,"normal",null,[],id)
  gain(g,relic)
  var cards=g.reward_offer(g.Cards.Rules.RARE,"fixed",null,1,"lewd_magic")
  for type in cards:
   g._gain_card(type)
   g._emit("event","欲望魔方 Pro Max：获得「%s」。" % g.B.CARD_NAMES[type])
  if cards.is_empty(): g._emit("event","欲望魔方 Pro Max：没有可获得的淫魔法稀有卡。")

static func gain_reason(g, id: String) -> String:
 if not g.Character.relic_allowed(g,id): return "该遗物不适用于当前角色。"
 if g.Character.active(g):
  if id=="cursed_plate_lock": return "该角色没有此遗物所需的身体部位。"
  if g.Relics.TYPES[id].get("pickup_cards",[]).any(func(type):return not g.Character.allowed_card(g,type)): return "该遗物提供的卡牌不适用于当前角色。"
 if id=="shining_lamp" and g.state.mana_max-50<g.B.MANA_MAX_FLOOR: return "魔力上限不足以降低50点。"
 return ""

static func boss_key(g, saturated: bool) -> void:
 if saturated or not g._all_gone() or not g.room_data(g.state.room).get("boss",false) or g.Prison.is_exit_battle(g): return
 if not g.state.enemies.any(func(enemy):return enemy.get("defeated",false)): return
 if "cursed_plate_lock" not in g.state.relics or g.state.cursed_plate_released: return
 var locks=g.state.special_equipment.filter(g.SpecialEquipment.is_cursed_plate)
 if locks.size()!=1: return
 var lock=locks[0]
 # Dedicated-key resolution removes the physical root; cleanup cascades its strap.
 g.state.cursed_plate_released=true
 lock.locked=false
 lock.durability=0.0
 g._cleanup()
 g._emit("event","获得专属钥匙，诅咒平板锁已解锁并整件取下。",{"cursed_plate_key":{"used":true,"target":lock.id},"relic_trigger":{"id":"cursed_plate_lock","name":"诅咒平板锁"}})

static func attribute(g, key: String, target: Dictionary={}, passive: bool=false) -> float:
 var total=float(g.state[key])+g.relic_value(key)+g.Cards.power_attribute_modifier(g,key)
 if key=="strength" and g.occupied("wrist"):
  for id in g.state.relics:
   if id=="wrist_bracer" or (id=="ditto" and g.state.get("ditto_form","")=="wrist_bracer"): total+=g.Relics.WRIST_BRACER_STRENGTH
 if key=="strength": total+=g.state.turn_strength
 if not passive: total+=g.Cards.hand_modifier(g,key)
 if key=="dexterity" and not target.is_empty():
  var points=g.Equipment.slip_points(target)
  if points.any(func(point):return point in g.Equipment.points("thigh")+g.Equipment.points("calf")+g.Equipment.points("ankle")+g.Equipment.points("foot")+g.Equipment.points("toes")):
   total+=g.relic_value("leg_dexterity")
 return maxf(0.0,total)

static func begin_combat(g, destination: String="") -> void:
 if destination=="": destination=g.state.phase
 transform(g)
 g.state.combat={"serial":g.state.combat.serial+1,"active":true,"first_turn":true,"turn":0,"energy":0,"mana_spent":0.0,"mana_used":false,"attack_uses":{},"attack_started":{},"successful_spells":[]}
 g.state.pressure=cap_pressure(g,g.state.pressure)
 g.state.energy=0
 _mana_hook(g,"opening_mana","战斗开始")
 for id in g.state.relics:
  if g.Character.active(g) and destination=="battle":
   var focus=int(definition(g,id).modifiers.get("battle_opening_focus",0))
   if focus>0:
    g.state.witch_focus+=focus
    g._emit("event",definition(g,id).name+"：精神集中＋%d。" % focus,{"relic_trigger":{"id":id,"name":definition(g,id).name}})
  var amount=int(definition(g,id).modifiers.get("opening_charge",0))
  if amount<=0: continue
  g._gain_charge(amount)
  g._emit("event",definition(g,id).name+"：本场开始，获得%d层蓄力。" % amount,{"relic_trigger":{"id":id,"name":definition(g,id).name},"charge_gain":amount})

static func end_combat(g) -> void:
 g.state.body_buffs.clear()
 if not g.state.combat.active: return
 g.Cards.flush_mana_powers(g)
 flush(g)
 # A paused prison session also ends here when inspection turns into combat.
 var eligible=g.state.phase in ["battle","prepare","reward","prison"] or (g.state.phase=="inspection" and g.state.prison.get("active",false))
 if eligible and g.state.mana<=g.state.mana_max*0.5:
  _mana_hook(g,"low_mana_end_restore","牢房探索结束" if g.state.phase in ["prison","inspection"] else "战斗结束")
 if eligible: _mana_hook(g,"battle_mana","战斗结束")
 # Preparation closes the battle session; rest and prison are separate sessions.
 if g.state.phase in ["battle","prepare","reward"]:
  for id in g.state.relics:
   var spec=definition(g,id)
   var pressure=float(spec.modifiers.get("battle_end_pressure",0))
   if pressure>0: g.Pressure.gain(g,pressure,spec.name)
 flush(g)
 g.state.next_energy=g.retained_energy()
 g._discard_end(true)
 g.state.combat.active=false
 g.state.combat.turn=0
 g.state.combat.first_turn=false
 g.state.combat.energy=0
 g.state.combat.mana_spent=0.0
 if "ditto" in g.state.relics and definition(g,"ditto").modifiers.get("mana_energy_step",0)>0: g.state.relic_counters.erase("ditto")
 g.state.combat.mana_used=false
 g.state.combat.attack_uses={}
 g.state.combat.attack_started={}
 g.state.combat.successful_spells=[]
 g.state.energy=0
 g.Cards.end_powers(g)
 g.Cards.purge_temporary(g)
 g.state.temporary_mana=g.retained_temporary_mana()
 g._clear_charge(true)
 g.state.sure_cast=false

static func climax(g, count: int) -> void:
 _mana_hook(g,"climax_flask_mana","高潮后","flask_mana",count)
 for id in g.state.relics:
  var amount=int(definition(g,id).modifiers.get("climax_next_draw",0))*count
  if amount<=0: continue
  g.state.relic_counters[id]=int(g.state.relic_counters.get(id,0))+amount
  g._emit("event",definition(g,id).name+"：下回合多抽%d张牌。" % amount,{"relic_trigger":{"id":id,"name":definition(g,id).name}})

static func _mana_hook(g, hook: String, timing: String, destination: String="mana", count: int=1) -> void:
 for id in g.state.relics:
  var amount=definition(g,id).modifiers.get(hook,0.0)*count
  if amount<=0: continue
  if destination=="mana": amount=minf(amount,g.state.mana_max-g.state.mana)
  g.state[destination]+=amount
  var result="魔瓶补充%s魔力。" if destination=="flask_mana" else "恢复%s魔力。"
  g._emit("event",definition(g,id).name+"："+timing+"，"+result % g.number(amount),{"relic_trigger":{"id":id,"name":definition(g,id).name}})

static func pressure_tick(g, timing: String) -> void:
 if timing not in ["turn_start","turn_end"] or g.state.phase not in COMBAT_PHASES or not g.state.combat.active: return
 for id in g.state.relics:
  var spec=definition(g,id)
  if timing=="turn_start":
   var gain=float(spec.modifiers.get("turn_start_pressure",0))
   if gain>0: g.Pressure.gain(g,gain,spec.name)
  else:
   var loss=minf(g.state.pressure,float(spec.modifiers.get("turn_end_pressure_loss",0)))
   if loss<=0: continue
   var before=g.state.pressure
   g.Pressure.lose(g,loss)
   g._emit("event",spec.name+"：回合结束，快感降低%s点。" % g.number(loss),{"relic_trigger":{"id":id,"name":spec.name},"pressure_before":before,"loss":loss})

static func end_turn(g) -> void:
 g.state.combat.energy=g.state.energy if g.relic_value("retain_energy")>0 else 0
 if g.state.phase=="prepare" and g.state.combat.active: _mana_hook(g,"preparation_turn_mana","整备回合结束")
 if g.state.phase in COMBAT_PHASES and g.state.combat.active and not g.state.combat.mana_used:
  _mana_hook(g,"unspent_turn_mana","本回合未消耗魔力")
 if g.state.phase=="battle" and g.state.combat.active: trigger(g,"turn_end")

static func begin_turn(g) -> void:
 if g.state.phase not in COMBAT_PHASES or not g.state.combat.active: return
 g.state.combat.turn+=1
 g.state.combat.attack_uses={}
 g.state.combat.attack_started={}
 g.state.combat.successful_spells=[]
 g.state.combat.mana_used=false
 for id in g.state.relics:
  if g.Character.active(g) and g.state.phase=="battle":
   var reserve=int(definition(g,id).modifiers.get("battle_turn_reserve",0))
   if reserve>0:
    g.state.temporary_mana+=reserve*5.0
    g._emit("event",definition(g,id).name+"：获得%d层魔力预备。" % reserve,{"relic_trigger":{"id":id,"name":definition(g,id).name}})
  var charge=int(definition(g,id).modifiers.get("turn_charge",0))
  if charge>0:
   g._gain_charge(charge)
   g._emit("event",definition(g,id).name+"：获得%d层蓄力。" % charge,{"relic_trigger":{"id":id,"name":definition(g,id).name}})
  var opening=int(definition(g,id).modifiers.get("opening_energy",0))
  if g.state.combat.first_turn and opening>0:
   opening=g._gain_energy(opening)
   g._emit("event",definition(g,id).name+"：本场第一回合，获得%d能量。" % opening,{"relic_trigger":{"id":id,"name":definition(g,id).name},"energy_gain":opening})
  var step=int(definition(g,id).modifiers.get("turn_energy_step",0))
  if step<=0: continue
  var progress=int(g.state.relic_counters.get(id,0))+1
  g.state.relic_counters[id]=progress%step
  if progress<step: continue
  if g._gain_energy(1)==0: continue
  g._emit("event",definition(g,id).name+"：累计%d回合，获得1能量。" % step,{"relic_trigger":{"id":id,"name":definition(g,id).name},"energy_gain":1})

static func shuffled(g) -> void:
 for id in g.state.relics:
  var step=int(definition(g,id).modifiers.get("shuffle_energy_step",0))
  if step<=0: continue
  var progress=int(g.state.relic_counters.get(id,0))+1
  g.state.relic_counters[id]=progress%step
  if progress<step: continue
  var gain=g._gain_energy(g.Relics.SHUFFLE_ENERGY_GAIN)
  g._emit("event",definition(g,id).name+"：累计%d次洗牌，获得%d能量。" % [step,gain],{"relic_trigger":{"id":id,"name":definition(g,id).name},"energy_gain":gain})

static func pressure_guard(g) -> String:
 if not g.state.combat.active: return ""
 for id in g.state.relics:
  var turns=int(definition(g,id).modifiers.get("pressure_guard_turns",0))
  if turns>0 and g.state.combat.turn<=turns: return id
 return ""

static func cap_pressure(g, value: float, settlement: Dictionary={}) -> float:
 var id=pressure_guard(g)
 var limit=g.Pressure.maximum(g)-1.0
 if id!="" and value>limit:
  g._emit("event",definition(g,id).name+"：快感值保持在%s，多出部分已抵消。" % g.number(limit),{"relic_trigger":{"id":id,"name":definition(g,id).name},"pressure_prevented":value-limit})
  value=limit
 # Numeric guards settle before threshold reactions; scripted climaxes bypass both.
 settlement.value=value
 if g.state.combat.active: trigger(g,"pressure_threshold",settlement)
 settlement.reduction=value-settlement.value
 return settlement.value

static func counter(g, id: String) -> Dictionary:
 if definition(g,id).modifiers.get("climax_next_draw",0)>0:
  var pending=int(g.state.relic_counters.get(id,0))
  return {"value":pending,"goal":0,"text":str(pending),"detail":"下回合额外抽牌：%d张。" % pending}
 var shuffles=int(definition(g,id).modifiers.get("shuffle_energy_step",0))
 if shuffles>0:
  var value=int(g.state.relic_counters.get(id,0))
  return {"value":value,"goal":shuffles,"text":str(value),"detail":"已累计%d／%d次洗牌；计数跨战斗保留。" % [value,shuffles]}
 var capacity=int(definition(g,id).modifiers.get("skill_mana_cap",0))
 if capacity>0:
  var points=int(g.state.relic_counters.get(id,0))
  return {"value":points,"goal":capacity,"text":str(points),"detail":"已积攒%d／%d点；右键兑换等量魔力，满点自动兑换并清空。" % [points,capacity]}
 var turns=int(definition(g,id).modifiers.get("pressure_guard_turns",0))
 if turns>0:
  var remaining=maxi(0,turns-maxi(1,g.state.combat.turn)+1) if g.state.combat.active else 0
  var detail="本场第%d回合，快感最多%s；保护还包括%d个回合。" % [maxi(1,g.state.combat.turn),g.number(g.Pressure.maximum(g)-1.0),remaining] if remaining>0 else ("本场保护已结束。" if g.state.combat.active else "下一场开始时重新获得%d回合保护。" % turns)
  return {"value":remaining,"goal":turns,"text":str(remaining),"detail":detail}
 var spec=g.Relics.trigger(id,g.state.get("ditto_form",""))
 if spec.get("event","")=="pressure_threshold":
  var remaining=0 if g.state.combat.active and used(g,id) else 1
  return {"value":remaining,"goal":1,"text":str(remaining),"detail":"本场已触发；下场类战斗恢复1次。" if remaining==0 else "下次快感达到上限时触发；每场类战斗1次。"}
 if spec.get("event","")=="turn_end" and spec.has("round"):
  var active=g.state.phase=="battle" and g.state.combat.active
  var spent=active and used(g,id)
  var value=mini(g.state.round,int(spec.round)) if active else 0
  var detail="本场已触发；下场战斗重新计数。" if spent else ("当前第%d回合；第%d个玩家回合结束时触发。" % [g.state.round,spec.round] if active else "进入战斗后计数，第%d个玩家回合结束时触发。" % spec.round)
  if active and not spent and g.state.round>spec.round: detail="本场已过触发回合；下场战斗重新计数。"
  return {"value":value,"goal":spec.round,"text":"✓" if spent else str(value),"detail":detail}
 if id!="ditto" and definition(g,id).get("collectible",false):
  var count=int(g.state.relic_counters.get(id,1))
  return {"value":count,"goal":0,"text":str(count),"detail":"持有%d件。" % count}
 var modifiers=definition(g,id).modifiers
 var step=int(modifiers.get("turn_energy_step",0))
 if step>0:
  var value=int(g.state.relic_counters.get(id,0))
  return {"value":value,"goal":step,"text":str(value),"detail":"已累计%d／%d回合；再过%d个玩家回合获得1能量。进度跨战斗保留。" % [value,step,step-value]}
 # Spending relics reuse their existing authoritative remainder.
 var mana_step=float(modifiers.get("mana_energy_step",0))
 if mana_step>0:
  var value=g.state.relic_counters.get("ditto",0.0) if id=="ditto" else g.state.combat.mana_spent
  return {"value":value,"goal":mana_step,"text":g.number(value),"detail":"已累计消耗%s／%s魔力；本场结束清零。" % [g.number(value),g.number(mana_step)]}
 return {}

static func view(g) -> Array:
 var rows=g.Relics.view(g.state.relics)
 for row in rows:
  if row.id=="doubao":
   var mode=g.FirstTurnControl.mode(g)
   row.name=mode.name;row.detail=mode.detail;row.icon=mode.icon
  if row.id=="ditto" and g.state.get("ditto_form","")!="":
   row.name="百变怪 · "+definition(g,row.id).name
   row.detail=definition(g,row.id).detail;row.icon=g.state.ditto_form
  row.counter=counter(g,row.id)
  row.current=""
  if row.id=="cursed_plate_lock": row.current="已用专属钥匙取下；能量上限＋1保留。" if g.state.cursed_plate_released else "等待击败下一个Boss，获得专属钥匙后自动取下。"
  if definition(g,row.id).modifiers.get("combat_retention_layers",0)>0:
   row.current="当前可保留%d点额外能量、%d层蓄力、%s点临时魔力。" % [g.retained_energy(),g.retained_charge(),g.number(g.retained_temporary_mana())]
  var spec=g.Relics.trigger(row.id,g.state.get("ditto_form",""))
  if not spec.is_empty() and spec.scope!="repeat":
   row.current=("本次机会已使用。" if used(g,row.id) else "本次机会未使用。")+("每场战斗刷新。" if spec.scope=="battle" else "每玩家回合刷新。")
   if spec.get("op","")=="posture_discount" and row.id in posture_sources(g,spec.to):
    row.current+="\n本回合下次从%s转为%s少花%d能量。" % [g.B.POSE_NAMES[spec.from],g.B.POSE_NAMES[spec.to],spec.amount]
  if row.id=="ditto" and g.state.get("ditto_form","")!="":
   row.current+=("\n" if row.current!="" else "")+"下场开始时重新变形，百变怪自身的累计进度清零。"
 return rows

static func opening_draw(g) -> int:
 if not g.state.combat.first_turn: return 0
 g.state.combat.first_turn=false
 var count=int(g.relic_value("opening_draw"))
 if count>0: g._emit("event","准备背包：本场首次抽牌额外＋%d张。" % count)
 return count

static func turn_draw(g) -> int:
 var total=0
 for id in g.state.relics:
  var count=int(definition(g,id).modifiers.get("turn_draw",0))
  if definition(g,id).modifiers.get("climax_next_draw",0)>0:
   count+=int(g.state.relic_counters.get(id,0))
   g.state.relic_counters.erase(id)
  if count<=0: continue
  total+=count
  g._emit("event",definition(g,id).name+"：本回合额外抽%d张牌。" % count,{"relic_trigger":{"id":id,"name":definition(g,id).name}})
 return total

static func toe_traction(g) -> Dictionary:
 var result={"base":0.0,"gain":0.0,"sources":[]}
 if g.relic_value("toe_cast")<=0: return result
 for piece in g.equipment_at("toes"):
  var tightness=g.tier(piece.durability,piece.maximum)
  var value=float(g.Relics.SECRET_WEAPON_TRACTION.get(int(piece.grade)+tightness,0.0))
  value*=g.relic_value("toe_cast")
  result.base+=value
  result.sources.append({"id":piece.id,"name":g._equipment_name(piece),"grade":piece.grade,"tier":tightness,"base":value})
 result.gain=result.base*g.Pressure.source_multiplier(g,["toes"])
 return result

static func mana_lost(g, amount: float, temporary: float=0.0) -> void:
 g.Cards.mana_spent(g,amount+temporary)
 if amount<=0 or g.state.phase not in COMBAT_PHASES: return
 g.state.combat.mana_used=true
 for id in ["mana_earring","ditto"]:
  if id=="ditto" and id not in g.state.relics: continue
  var step=float(definition(g,id).modifiers.get("mana_energy_step",0)) if id=="ditto" else g.Relics.value(g.state.relics,"mana_energy_step")
  if step<=0: continue
  var remainder=(g.state.relic_counters.get(id,0.0) if id=="ditto" else g.state.combat.mana_spent)+amount
  var energy=int(floor((remainder+0.000001)/step))
  remainder=maxf(0.0,remainder-energy*step)
  if id=="ditto": g.state.relic_counters[id]=remainder
  else: g.state.combat.mana_spent=remainder
  if energy<=0: continue
  energy=g._gain_energy(energy)
  g._emit("event",definition(g,id).name+"：累计消耗魔力，获得%d能量。" % energy,{"relic_trigger":{"id":id,"name":definition(g,id).name}})

static func card_played(g, type: String, free: bool) -> void:
 if "skill" not in g.Cards.Rules.type_tags(type,free): return
 for id in g.state.relics:
  var capacity=int(definition(g,id).modifiers.get("skill_mana_cap",0))
  if capacity<=0: continue
  g.state.relic_counters[id]=int(g.state.relic_counters.get(id,0))+1
  if g.state.relic_counters[id]>=capacity: discharge(g,id)

# Both right-click and the full-meter trigger settle through this one writer.
static func discharge(g, id: String) -> void:
 var points=int(g.state.relic_counters.get(id,0))
 var recovered=minf(points,g.state.mana_max-g.state.mana)
 g.state.relic_counters[id]=0
 g.state.mana+=recovered
 g._emit("event",definition(g,id).name+"：消耗%d点，恢复%s魔力。" % [points,g.number(recovered)],{"relic_trigger":{"id":id,"name":definition(g,id).name},"relic_discharge":{"points":points,"mana":recovered}})

# 接管结束的显示点事实（唯一来源：接管路径无法自行结束回合时合成；批 R5）。与其余显示点同一投影。
static func control_done_fact(g) -> Dictionary:
 return g.display_fact(g._fact({"kind":"relic_control_done"},"接管结束",{"kind":"relic.control_done","args":{}},0,0.0,"","","relic"))

# 遗物显示事实（批 R5：行生产转发改显示事实构建，docs/spec/candidate-removal.md §2.1 T5／T8）。
static func facts(g) -> Array:
 var out=[]
 if g.state.phase in ["cleared","prison_end","captured","inspection"] or g.state.overloaded or not g.state.card_chain.is_empty() or g.state.pending_retain: return out
 for id in g.state.relics:
  if id=="doubao":
   var toggle_reason="战斗、战后整备、休息及监狱中不能切换模式。" if g.state.phase in COMBAT_PHASES else ""
   out.append(g._fact({"kind":"relic_toggle","relic":id},"切换为"+("DeepSeek" if g.state.relic_counters.get(id,0)==0 else "豆包"),{"kind":"relic.control_toggle","args":{}},0,0.0,toggle_reason,"","relic"))
  if definition(g,id).modifiers.get("skill_mana_cap",0)<=0: continue
  var reason="尚未积攒点数。" if g.state.relic_counters.get(id,0)<=0 else ""
  out.append(g._fact({"kind":"relic_discharge","relic":id},definition(g,id).name+" · 兑换魔力",{"kind":"relic.discharge","args":{"id":id}},0,0.0,reason,"","relic"))
 return out

static func validate(g) -> String:
 var form_issue=g.Relics.form_issue(g.state)
 if form_issue!="": return form_issue
 if g.state.get("ditto_form","")!="" and not g.Character.relic_allowed(g,g.state.ditto_form): return "百变怪形态来源不正确。"
 if not g.state.get("cursed_plate_released") is bool: return "诅咒平板锁的解除记录不完整。"
 var cursed=g.state.special_equipment.filter(g.SpecialEquipment.is_cursed_plate)
 var pending="cursed_plate_lock" in g.state.relics and not g.state.cursed_plate_released
 if cursed.size()!=(1 if pending else 0): return "诅咒平板锁的佩戴记录不正确。"
 if g.state.cursed_plate_released and "cursed_plate_lock" not in g.state.relics: return "专属钥匙记录缺少对应遗物。"
 if pending and (not cursed[0].locked or cursed[0].durability!=cursed[0].maximum or cursed[0].remaining!=0): return "诅咒平板锁必须保持三档、上锁且无限持续。"
 var bundle_issue=g.RelicBundle.validate(g,g.state)
 if bundle_issue!="": return bundle_issue
 if "cursed_blindfold" in g.state.relics:
  var masks=g.state.equipment.filter(func(e):return e.get("source","")=="relic:cursed_blindfold")
  if masks.size()!=1: return "诅咒眼罩的永久佩戴记录损坏。"
  var mask=masks[0]
  if mask.template!="eye_leather" or mask.slot!="eyes" or mask.grade!=3 or not mask.locked or mask.durability!=mask.maximum: return "诅咒眼罩必须保持高级、三档且上锁。"
 if not g.state.get("relic_counters") is Dictionary: return "遗物累计进度不完整。"
 for id in g.state.relic_counters:
  if id not in g.state.relics: return "累计进度对应的遗物未持有。"
  var step=int(definition(g,id).get("modifiers",{}).get("turn_energy_step",0))
  step=maxi(step,int(definition(g,id).get("modifiers",{}).get("shuffle_energy_step",0)))
  step=maxi(step,int(definition(g,id).get("modifiers",{}).get("skill_mana_cap",0)))
  if id=="doubao": step=g.Relics.FIRST_TURN_MODES.size()
  var value=g.state.relic_counters[id]
  if definition(g,id).modifiers.get("climax_next_draw",0)>0:
   if not value is int or value<0: return "遗物待抽牌数量不正确。"
   continue
  if id=="ditto" and definition(g,id).modifiers.get("mana_energy_step",0)>0:
   if not g.Snapshot.typed(value,"n") or value<0 or value>=definition(g,id).modifiers.mana_energy_step: return "百变怪累计魔力不正确。"
   continue
  if id!="ditto" and definition(g,id).get("collectible",false):
   if not value is int or value<1: return "收藏遗物数量必须为正整数。"
   continue
  if not value is int or value<0 or step<=0 or value>=step: return "遗物累计回合进度不正确。"
 if not g.Snapshot.fields(g.state.get("combat"),"serial:i active:b first_turn:b turn:i energy:i mana_spent:n mana_used:b"): return "战斗触发进度不完整。"
 var control_issue=g.FirstTurnControl.validate(g)
 if control_issue!="": return control_issue
 var combat=g.state.combat
 if not combat.get("attack_started") is Dictionary: return "本回合首次攻击记录不完整。"
 for type in combat.attack_started:
  if not g.BasicAttacks.TYPES.has(type) or not g.BasicAttacks.TYPES[type][0].has("first_use_cost") or combat.attack_started[type] != true or not combat.attack_started[type] is bool: return "本回合首次攻击记录不正确。"
 if not combat.active and not combat.attack_started.is_empty(): return "场次结束后不能保留首次攻击记录。"
 if not combat.get("attack_uses") is Dictionary: return "本回合攻击次数记录不完整。"
 for type in combat.attack_uses:
  if g.Character.active(g) and type.trim_prefix("witch_") in g.Character.PARTS and type.begins_with("witch_"):
   if not combat.attack_uses[type] is int or combat.attack_uses[type]!=1: return "本回合部位法术释放次数不正确。"
   continue
  if not g.BasicAttacks.TYPES.has(type) or not g.BasicAttacks.TYPES[type][0].has("uses_per_turn") or not combat.attack_uses[type] is int or combat.attack_uses[type]<0: return "本回合攻击次数记录不正确。"
 if not g.Snapshot.fields(combat,"successful_spells:z") or combat.successful_spells.any(func(spell):return spell not in g.Cards.Rules.FIXED_MAGIC or combat.successful_spells.count(spell)!=1): return "本回合成功施法记录不正确。"
 if not combat.active and not combat.successful_spells.is_empty(): return "场次结束后不能保留成功施法记录。"
 if not combat.active and not combat.attack_uses.is_empty(): return "场次结束后不能保留攻击次数。"
 if combat.serial<0 or combat.turn<0 or combat.energy<0 or combat.mana_spent<0: return "战斗触发进度不能为负数。"
 if g.state.relics.any(func(id):return not g.Relics.TYPES.has(id)): return "持有遗物的定义不存在。"
 var step=g.Relics.value(g.state.relics,"mana_energy_step")
 if step>0 and combat.mana_spent>=step: return "耳坠累计魔力尚未完整结算。"
 if not combat.active and (combat.first_turn or combat.energy!=0 or combat.mana_spent!=0 or combat.mana_used): return "战斗结束后不能保留本场触发进度。"
 for id in g.Relics.TYPES:
  var shop_issue=g.Relics.shop_reason(g.Relics.TYPES[id])
  if shop_issue!="": return shop_issue
  var collectible_issue=g.Relics.collectible_reason(g.Relics.TYPES[id])
  if collectible_issue!="": return collectible_issue
  if g.Relics.TYPES[id].has("card_base_bonuses"):
   var issue=g.Relics.card_bonuses_reason(g.Relics.TYPES[id].card_base_bonuses,g.Cards.Rules.SPECS)
   if issue!="": return issue
  if g.Relics.TYPES[id].get("rarity","") not in g.Relics.RARITIES: return "遗物需要普通、罕见或稀有分类。"
  if g.Relics.TYPES[id].has("trigger"):
   var issue=g.Relics.trigger_reason(g.Relics.TYPES[id].trigger)
   if issue!="": return issue
 return ""

static func used(g, id: String) -> bool:
 var spec=g.Relics.trigger(id,g.state.get("ditto_form",""))
 if spec.is_empty() or spec.scope=="repeat": return false
 return g.state.relic_used.get(id+":"+spec.scope,-1)==(g.state.combat.serial if spec.scope=="battle" else g.state.tick)

static func cast_guarantee(g) -> String:
 if g.state.phase not in COMBAT_PHASES or not g.state.combat.active: return ""
 for id in g.state.relics:
  var spec=g.Relics.trigger(id,g.state.get("ditto_form",""))
  if spec.get("event","")=="paid_cast" and spec.get("op","")=="guarantee" and not used(g,id) and (not spec.has("phase") or phase_matches(g,spec.phase)): return id
 return ""

static func trigger(g, event: String, context: Dictionary={}) -> void:
 for id in g.state.relics:
  var spec=g.Relics.trigger(id,g.state.get("ditto_form",""))
  if spec.is_empty() or spec.event!=event or used(g,id): continue
  if spec.has("phase") and not phase_matches(g,spec.phase): continue
  if spec.has("round") and spec.round!=g.state.round: continue
  if spec.has("from_tier") and spec.from_tier!=context.get("from_tier",0): continue
  if spec.has("to_tier") and spec.to_tier!=context.get("to_tier",0): continue
  if event=="pressure_threshold" and (not g.state.combat.active or g.Pressure.overloads_at(g,context.get("value",0.0))==0): continue
  if spec.scope!="repeat": g.state.relic_used[id+":"+spec.scope]=g.state.combat.serial if spec.scope=="battle" else g.state.tick
  if spec.op=="pressure":
   var amount=int(spec.amount)*int(context.get("count",1))
   if amount>0: g.state.relic_pending[id]={"op":"pressure","amount":g.state.relic_pending.get(id,{}).get("amount",0)+amount}
  elif spec.op=="halve_pressure_charge":
   var before=context.value
   context.value*=0.5
   trigger(g,"pressure_lost")
   g._gain_charge(spec.amount)
   g._emit("event",definition(g,id).name+"：快感%s → %s，获得%d层蓄力。" % [g.number(before),g.number(context.value),spec.amount],{"relic_trigger":{"id":id,"name":definition(g,id).name},"pressure_before":before,"pressure_after":context.value,"charge_gain":spec.amount})
  elif spec.op=="guarantee":
   g._emit("event",definition(g,id).name+"：本次施法必定成功。",{"relic_trigger":{"id":id,"name":definition(g,id).name}})
  elif spec.op=="posture_discount":
   g.state.ribbon_tick=g.state.tick
   g._emit("event",definition(g,id).name+"生效。",{"relic_trigger":{"id":id,"name":definition(g,id).name}})
  elif spec.op=="fixed_enemy_damage":
   var targets=g.state.enemies.filter(func(enemy):return not enemy.gone).map(func(enemy):return enemy.id)
   var damage_group={}
   for enemy_id in targets:
    g._damage_enemy(g._enemy(enemy_id),spec.amount,"fixed",definition(g,id).name,{"relic_trigger":{"id":id,"name":definition(g,id).name}},damage_group)
  else:
   var amount=context.get("amount",0.0)*spec.ratio if spec.has("ratio") else spec.amount
   g.state.relic_pending[id]={"op":spec.op,"amount":amount}

static func strain_destroyed(g) -> void:
 trigger(g,"strain_destroyed")

static func card_slipped(g, before: int, target: Dictionary) -> void:
 var after=g.tier(target.durability,target.maximum) if target.durability>0 else 0
 if after<before: trigger(g,"card_slipped",{"from_tier":before,"to_tier":after})

static func magic_paid(g, amount: float) -> void:
 if amount>0: trigger(g,"magic_paid",{"amount":amount})

static func fell(g) -> void:
 trigger(g,"fell")

static func posture_sources(g, dest: String) -> Array:
 var result=[]
 if g.state.ribbon_tick!=g.state.tick: return result
 for id in g.state.relics:
  var spec=g.Relics.trigger(id,g.state.get("ditto_form",""))
  if spec.get("op","")!="posture_discount" or not used(g,id): continue
  if phase_matches(g,spec.get("phase",g.state.phase)) and spec.from==g.state.posture and spec.to==dest: result.append(id)
 return result

static func posture_discount(g, dest: String) -> int:
 var total=0
 for id in posture_sources(g,dest): total+=g.Relics.trigger(id,g.state.get("ditto_form","")).amount
 return total

static func posture_detail(g, dest: String) -> String:
 var sources=posture_sources(g,dest)
 if sources.is_empty(): return ""
 return "、".join(sources.map(func(id):return definition(g,id).name))+"已减免%d能量。" % posture_discount(g,dest)

static func flush(g) -> void:
 while not g.state.relic_pending.is_empty():
  var pending=g.state.relic_pending
  g.state.relic_pending={}
  # Preserve the existing charge, draw, then mana settlement order.
  for op in ["charge","draw","mana","pressure"]:
   for id in pending:
    var effect=pending[id]
    if effect.op!=op: continue
    var amount=effect.amount
    var detail=""
    match op:
     "pressure":
      var unit=int(g.Relics.trigger(id,g.state.get("ditto_form","")).amount)
      for occurrence in range(int(amount)/unit): g.Pressure.gain(g,unit,definition(g,id).name)
      continue
     "charge":
      g._gain_charge(int(amount))
      detail="获得%d层蓄力" % amount
     "draw":
      g._draw(int(amount))
      detail="抽%d张牌" % amount
     "mana":
      amount=minf(amount,g.state.mana_max-g.state.mana)
      g.state.mana+=amount
      detail="返还%s魔力" % g.number(amount)
    g._emit("event",definition(g,id).name+"："+detail+"。",{"relic_trigger":{"id":id,"name":definition(g,id).name}})

static func clear_temporary(g) -> void:
 g.state.body_buffs.clear()
 g.state.ribbon_tick=-1
 g.Cards.cancel_chain(g)
 g.state.relic_pending={}
