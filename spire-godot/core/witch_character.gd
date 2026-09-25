extends RefCounted

# Character-local definitions are registered under distinct ids. Original specs,
# buffs and reward arrays are never rewritten when selecting a character.
const ID="witch"
const Expansion=preload("res://core/witch_expansion.gd")
const PARTS=["hand","mouth","legs","mind"]
const NAMES={"hand":"手部","mouth":"嘴部","legs":"腿部","mind":"精神"}
const CHANGED=["slip","prepared_chant","strain","magic_hand","magic_hand_gift","magic_slip","siphon","ready_to_strike","mana_search","mana_invocation","mana_surge","adaptability","mana_conversion","focus","mana_circuit","pleasure_conversion","itching_heart","self_satisfaction","psychological_suggestion","rally_spirit","desire_rune","forced_edging","forced_climax"]
const REMOVED=["ease","leverage","crossed_legs","repeated_strain","embers","rekindle","fire_control","strong_elbow","brace","echo_cast","wildfire_descent","flame_flourish","unlock","tear","chain","infusion","fire_dynamics","fire_mastery","double_unlock"]
const STARTER=["witch_slip","witch_slip","witch_slip","witch_magic_slip","witch_strain","witch_strain","witch_strain","witch_escape_practice","witch_key","witch_preparation","witch_accumulation"]
static var registered=false

static func active(g) -> bool:
 return g.state.get("character_id","original")==ID

static func initialize(g) -> void:
 g.state.character_id=ID
 g.state.witch_charges={"hand":0,"mouth":0,"legs":0,"mind":0}
 g.state.witch_focus=0
 g.state.mana_max=75.0;g.state.mana=75.0;g.state.flask_mana=50.0
 g.state.relics=["witch_amulet"]

static func register(g) -> void:
 if registered: return
 registered=true
 var rules=g.Cards.Rules
 rules.CAST_PART_NAMES["mind"]="精神"
 rules.CAST_PART_NAMES["legs"]="腿部"
 for part in PARTS:
  rules.FIXED_MAGIC["witch_"+part]={"parts":[part],"multiplier":1.0}
 for original in CHANGED:
  var id="witch_"+original
  var spec=rules.SPECS[original].duplicate(true)
  spec.character_id=ID;spec.art_type=original;spec.encyclopedia_hidden=true;spec.reward_excluded=true
  if spec.has("self_faces"):
   for side in ["bound","free"]:
    var face=spec.self_faces[side]
    if face.has("buff"):
     var buff_id="witch_"+face.buff
     if not rules.BUFFS.has(buff_id): rules.BUFFS[buff_id]=rules.BUFFS[face.buff].duplicate(true)
     face.buff=buff_id
  rules.SPECS[id]=spec
  g.B.CARD_NAMES[id]=g.B.CARD_NAMES[original]
  g.B.CARD_INFO[id]=g.B.CARD_INFO[original].duplicate(true)
  if g.B.CARD_TRAITS.has(original): g.B.CARD_TRAITS[id]=g.B.CARD_TRAITS[original].duplicate(true)
  if spec.get("reward_pool","")=="lewd_magic":
   _adapt_lewd_effects(spec)
   for face in spec.get("self_faces",{}).values():
    if face.has("buff"):
     _adapt_lewd_effects(rules.BUFFS[face.buff])
     rules.BUFFS[face.buff].detail=rules.BUFFS[face.buff].detail.replace("蓄力","精神集中")
   g.B.CARD_INFO[id]=g.B.CARD_INFO[id].map(func(text):return text.replace("蓄力","精神集中"))
 var s=rules.SPECS
 for original in ["slip","siphon","magic_hand","magic_hand_gift","adaptability","pleasure_conversion"]:
  g.B.CARD_NAMES["witch_"+original]=g.B.CARD_NAMES[original]+"（魔女）"
 s.witch_prepared_chant.cost=0
 s.witch_siphon.rarity="common"
 s.witch_strain.free_effects=[{"op":"witch_focus","amount":1}]
 for id in ["witch_magic_hand","witch_magic_hand_gift"]:
  s[id].mana_cost=30.0;s[id].free_mana_cost=30.0;s[id].hits=4
  s[id].free_effects=[{"op":"evasion","amount":2}]
 rules.BUFFS.witch_hand_freedom={"name":"魔术手","duration":"battle","attack_uses":2,"stack_uses":true,"witch_hand":true,"detail":"下2次手部基础动作忽略拘束条件。每次完整动作消耗1次，次数可累计；仍判定施法成功率。"}
 s.witch_magic_slip.free_effects[0].amount=2
 s.witch_siphon.self_faces.bound.mana_gain=10.0
 s.witch_siphon.self_faces.bound.exhaust=true
 s.witch_siphon.self_faces.free.effects=[{"op":"draw","amount":1}]
 s.witch_ready_to_strike.self_faces.bound.effects=[{"op":"witch_focus","amount":3}]
 rules.BUFFS.witch_ready_to_strike_free={"name":"蓄势待发","duration":"battle","attack_uses":1,"witch_discount":2,"detail":"下次基础动作费用－2，最低0。"}
 s.witch_mana_search.cost=0;s.witch_mana_search.card_type="magic"
 s.witch_mana_search.casting={"parts":["mind"],"multiplier":1.0}
 for face in s.witch_mana_search.self_faces.values(): face.cast=true;face.mana_cost=5.0
 g.B.CARD_TRAITS.witch_mana_search={"exhaust":true}
 for face in s.witch_mana_invocation.self_faces.values():
  face.mana_gain=10.0;face.effects=[{"op":"reserve_mana","amount":4}]
 s.witch_mana_surge.self_faces.bound.effects=[{"op":"witch_focus","amount":2}]
 s.witch_mana_surge.self_faces.bound.mana_cost=20.0
 rules.BUFFS.witch_adaptability_bound.turn_start_effects=[{"op":"witch_focus","amount":1}]
 rules.BUFFS.witch_adaptability_bound.detail="回合开始时，精神集中1。可叠加。"
 rules.BUFFS.witch_adaptability_free.turn_start_effects=[{"op":"reserve_mana","amount":2}]
 rules.BUFFS.witch_adaptability_free.detail="回合开始时，获得2层魔力预备。可叠加。"
 s.witch_mana_conversion.self_faces.bound.mana_cost=20.0
 s.witch_mana_conversion.self_faces.bound.energy_gain=2
 s.witch_mana_conversion.self_faces.free.mana_gain=20.0
 s.witch_focus.self_faces.bound.effects[0]={"op":"witch_focus","amount":1}
 rules.BUFFS.witch_mana_circuit_bound.mana_spent.effects=[{"op":"witch_focus","amount":1}]
 rules.BUFFS.witch_mana_circuit_bound.detail="每累计消耗20魔力，精神集中1。计入临时魔力，可叠加。"
 for face in s.witch_pleasure_conversion.self_faces.values(): face.pressure_energy=15
 _basic(g,"witch_key","魔法钥匙",{"card_type":"magic","cost":1,"mode":"unlock","cast_free":true,"free_mana_cost":0.0,"mana_cost":0.0,"casting":{"parts":["mind"],"multiplier":1.0},"free_effects":[{"op":"reserve_mana","amount":4}]},["魔法","开锁1。","{free_effects}",""],"unlock")
 _basic(g,"witch_preparation","施法预备",{"card_type":"magic","cost":1,"mode":"self","casting":{"parts":["mind"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":20.0,"effects":[{"op":"reserve_mana","amount":4},{"op":"witch_focus","amount":2}]},"free":{"cast":true,"mana_cost":20.0,"effects":[{"op":"reserve_mana","amount":4},{"op":"witch_focus","amount":2}]}}},["魔法","{effects}","{effects}",""],"prepared_chant")
 rules.BUFFS.witch_accumulation={"name":"魔力积蓄","duration":"battle","stackable":true,"witch_mana_damage":0.01,"detail":"每有1点魔力，造成的伤害提高1%。计入自身与临时魔力，可叠加。"}
 _basic(g,"witch_accumulation","魔力积蓄",{"card_type":"power","cost":2,"mode":"power","self_faces":{"bound":{"buff":"witch_accumulation"},"free":{"buff":"witch_accumulation"}}},["能力","{buff}","{buff}",""],"mana_circuit")
 # Text stays character-local as well as the execution data.
 for id in ["witch_adaptability","witch_mana_circuit","witch_desire_rune"]:
  g.B.CARD_INFO[id][1]="{bound_buff}";g.B.CARD_INFO[id][2]="{self_free_buff}"
 g.B.CARD_INFO.witch_strain[2]="{free_effects}"
 g.B.CARD_INFO.witch_ready_to_strike[3]="所选手牌仅在施法成功时消耗。基础动作包括各部位施法预备和释放；减费不叠加。"
 g.B.CARD_INFO.witch_mana_conversion[1]="{mana_cost}能量＋2。"
 rules.BUFFS.witch_mana_circuit_bound.name="魔力回路·精神集中"
 g.B.CARD_INFO.witch_mana_search=["魔法","{bound_effects}","{self_free_effects}",""]
 g.B.CARD_INFO.witch_mana_invocation=["魔法","{mana_gain}{bound_effects}","{mana_gain}{self_free_effects}",""]
 g.B.CARD_INFO.witch_pleasure_conversion=["技能","每15快感获得1能量。","每15快感获得1能量。",""]
 Expansion.register(g)

static func _basic(g, id: String, name: String, spec: Dictionary, info: Array, art: String) -> void:
 info[1]=info[1].replace("{effects}","{bound_effects}").replace("{buff}","{bound_buff}")
 info[2]=info[2].replace("{effects}","{self_free_effects}").replace("{buff}","{self_free_buff}")
 spec.rarity="basic";spec.character_id=ID;spec.reward_excluded=true;spec.encyclopedia_hidden=true;spec.art_type=art
 g.Cards.Rules.SPECS[id]=spec;g.B.CARD_NAMES[id]=name;g.B.CARD_INFO[id]=info

static func _adapt_lewd_effects(value: Variant) -> void:
 if value is Array:
  for item in value: _adapt_lewd_effects(item)
 elif value is Dictionary:
  if value.get("op","")=="charge": value.op="witch_focus"
  for item in value.values(): _adapt_lewd_effects(item)

static func card_id(g, type: String) -> String:
 return "witch_"+type if active(g) and type in CHANGED else type

static func incompatible(g, value: Variant) -> bool:
 if value is Array:
  return value.any(func(v):return incompatible(g,v))
 if not value is Dictionary: return false
 if value.has("strength") or value.has("zero_cost_strength") or value.get("resource","")=="turn_strength": return true
 if value.get("op","")=="charge": return true
 if value.has("attacks") or value.has("attack_filters") or value.has("replay") or value.has("spell") or value.has("requires_successful_spell") or value.has("refresh_spell") or value.has("spell_base_bonus"): return true
 if value.has("buff") and incompatible(g,g.Cards.Rules.BUFFS[value.buff]): return true
 return value.values().any(func(v):return incompatible(g,v))

static func allowed_card(g, type: String, character: String="") -> bool:
 var role=g.state.get("character_id","original") if character=="" else character
 var required=g.Cards.Rules.REWARD_POOL_RELICS.get(g.Cards.Rules.SPECS.get(type,{}).get("reward_pool",""),"")
 if required!="" and not relic_allowed(g,required,role): return false
 if role!=ID: return not type.begins_with("witch_")
 var original=type.trim_prefix("witch_")
 if original in REMOVED or original.begins_with("hannya") or original=="good_soup": return false
 var resolved="witch_"+type if type in CHANGED else type
 return g.Cards.Rules.SPECS.has(resolved) and not incompatible(g,g.Cards.Rules.SPECS[resolved])

static func pool(g, types: Array, character: String="") -> Array:
 var role=g.state.get("character_id","original") if character=="" else character
 if role!=ID: return types.filter(func(type):return allowed_card(g,type,role))
 var rarities=[]
 for type in types:
  if type in g.Cards.Rules.REWARDS and g.Cards.Rules.SPECS[type].rarity not in rarities: rarities.append(g.Cards.Rules.SPECS[type].rarity)
 var result=[]
 for type in types:
  var id="witch_"+type if type in CHANGED else type
  if type in g.Cards.Rules.REWARDS and g.Cards.Rules.SPECS[id].rarity not in rarities: continue
  if allowed_card(g,id,role) and id not in result: result.append(id)
 for original in CHANGED:
  var id="witch_"+original
  if original in g.Cards.Rules.REWARDS and g.Cards.Rules.SPECS[id].rarity!=g.Cards.Rules.SPECS[original].rarity and g.Cards.Rules.SPECS[id].rarity in rarities and allowed_card(g,id,role) and id not in result: result.append(id)
 for type in Expansion.REWARDS:
  if g.Cards.Rules.SPECS[type].rarity in rarities and type not in result: result.append(type)
 return result

static func reward_member(g, type: String, character: String="") -> bool:
 var role=g.state.get("character_id","original") if character=="" else character
 if type in Expansion.REWARDS: return role==ID
 var original=type.trim_prefix("witch_")
 if original not in g.Cards.Rules.REWARDS: return false
 if role!=ID: return not type.begins_with("witch_")
 if original in REMOVED or original.begins_with("hannya") or original=="good_soup": return false
 var expected="witch_"+original if original in CHANGED else original
 return type==expected and not incompatible(g,g.Cards.Rules.SPECS[type])

static func has_slot(g, slot: String) -> bool:
 return not active(g) or not slot.begins_with("special_2")

# Casting chance has its own restriction curve, independent of physical damage balance.
const LEG_CAST_MULTIPLIERS=[1.0,0.8,0.6,0.4,0.0]

static func profile(g, part: String) -> Dictionary:
 if part=="hand" and g.state.card_buffs.has("witch_hand_freedom"): return {"parts":["hand"],"multiplier":1.0,"body_free":true}
 return {"parts":[part],"multiplier":LEG_CAST_MULTIPLIERS[g.level("legs")] if part=="legs" else 1.0}

# R4（docs/ondemand-copy.md §11.5）：法术候选文案改走路由，正文留在本模块。
static func attack_detail(g, args: Dictionary) -> String:
 var part=String(args.get("part",""))
 var charge=bool(args.get("charge",false))
 var n=int(args.get("stacks",0))
 var damage=float(args.get("damage",0.0))
 var hits=int(args.get("hits",1))
 var all_targets=bool(args.get("all_targets",false))
 var focus=int(args.get("focus",0))
 var detail="获得1层%s施法预备。当前%d层。每回合预备次数不限。" % [NAMES[part],n] if charge else ("%s伤害%s×%d。%s" % ["全体" if all_targets else "",g.number(damage),hits,"消耗全部%d层%s施法预备。" % [n,NAMES[part]] if n>0 else "当前无施法预备。"])
 if part=="legs" and not charge: detail="伤害1，打断。消耗全部腿部施法预备。"
 if not charge:
  detail+="每个部位每回合只能成功释放1次。"
  if "witch_interrupt_"+part in g.state.card_buffs: detail+="本次附加一次打断。"
 if focus>0: detail+="本次各段魔法伤害＋%d，消耗全部精神集中。" % focus
 return detail

# 角色2 的基础攻击事实（行动域，docs/spec/candidate-removal.md §2.1 T5／T8；批 R3）：行与显示事实的唯一来源。
# brief 依赖本次判定的 mana_payment，故判定先算一次并随事实带走（同一实现、同一输入，不是第二份判定）。
static func attack_facts(g) -> Array:
 var facts=[]
 for enemy in g.state.enemies:
  if enemy.gone: continue
  for part in PARTS:
   var n=int(g.state.witch_charges[part])
   for form in [0,1]:
    var charge=form==0
    var cost=1 if charge or part!="mouth" else 2
    var mana=5.0 if charge or part!="mouth" else 10.0
    if part=="legs" and not charge: mana=0.0
    mana=0.0 if charge and Expansion.free_preparation(g) else g._mana_cost(mana)
    var reason=""
    if not charge and part=="legs" and n<4: reason="需要至少4层腿部施法预备，当前%d层。" % n
    if not charge and g.state.combat.attack_uses.get("witch_"+part,0)>0: reason="本回合已经释放过%s法术，下回合才能再次释放。" % NAMES[part]
    var casting=g.cast_view(g.Cards.cast_profile(g,"witch_"+part,mana>0))
    if casting.reason!="": reason=casting.reason
    elif casting.chance<=0: reason="当前施法成功率为0%。"
    var all_targets=part=="mouth" and not charge
    if not charge and reason=="": reason=g.Puppets.taunt_reason(g,enemy,all_targets)
    var names={"hand":["火焰箭","烈焰箭","炎枪术"],"mouth":["吹雪","冰风","暴风雪"],"mind":["思维侵入","思维扰乱","思维破坏"],"legs":["魔女飞踹！","魔女飞踹！","魔女飞踹！"]}
    var label=NAMES[part]+"施法" if charge else names[part][2 if n>=4 else (1 if n>=2 else 0)]
    var hits=1 if part=="legs" else n+1
    var base={"hand":6.0,"mouth":4.0,"mind":4.0,"legs":1.0}[part]
    var focus=0 if charge or part=="legs" else g.state.witch_focus
    var damage=0.0 if charge else (base+focus)*g.Cards.damage_multiplier(g,"witch_"+part)
    var discount=2 if g.state.card_buffs.has("witch_ready_to_strike_free") else 0
    var p={"kind":"attack","type":"witch_"+part,"part":part,"form":form,"charge_action":charge,"enemy":enemy.id,"all":all_targets,"hits":hits,"damage":damage,"damage_type":"physical" if part=="legs" else "magic","interrupt":part=="legs" and not charge,"fall":false,"witch_action":true}
    var copy_args={"part":part,"charge":charge,"stacks":n,"damage":damage,"hits":hits,"all_targets":all_targets,"focus":focus}
    var cost_value=maxi(0,cost-discount)
    var verdict=g.eligibility(p,cost_value,mana,reason,"")
    var own_after=maxf(0,g.state.mana-verdict.mana_payment.mana)
    var target_multiplier=1.0 if all_targets else g.Enemies.damage_multiplier(g,enemy.type,p.damage_type)
    var brief="预备 %d → %d" % [n,n+1] if charge else ("全体 " if all_targets else "")+g.number(damage*damage_multiplier(g,own_after,maxf(0,g.state.temporary_mana-verdict.mana_payment.temporary_mana))*target_multiplier)+" × %d" % hits
    var fact=g._attack_fact_display(g._fact(p,label,{"kind":"witch.attack","args":copy_args,"fallback":attack_detail(g,copy_args)},cost_value,mana,reason,"","attack"))
    fact.casting=casting
    fact.brief=brief
    fact.brief_tags=""
    fact.verdict=verdict
    facts.append(fact)
 return facts

static func consume_buff(g, id: String) -> void:
 if id not in g.state.card_buffs: return
 g.state.card_buff_uses[id]=int(g.state.card_buff_uses.get(id,1))-1
 if g.state.card_buff_uses[id]<=0:
  g.state.card_buffs.erase(id);g.state.card_buff_uses.erase(id)

static func execute(g, c: Dictionary, damage_group: Dictionary) -> void:
 var p=c.payload
 # The casting profile is frozen in the candidate, before consuming modifiers.
 var success=g._cast_magic(c)
 consume_buff(g,"witch_ready_to_strike_free")
 if p.part=="hand": consume_buff(g,"witch_hand_freedom")
 if not success: return
 if p.charge_action:
  g.state.witch_charges[p.part]+=1
  g._emit("event","%s施法预备＋1，当前%d层。" % [NAMES[p.part],g.state.witch_charges[p.part]],{"witch_charge":{"part":p.part,"amount":1}})
  return
 g.state.combat.attack_uses[p.type]=1
 g.state.witch_charges[p.part]=0
 var interrupt_buff="witch_interrupt_"+p.part
 if interrupt_buff in g.state.card_buffs:
  p=p.duplicate(true);p.interrupt=true
  consume_buff(g,interrupt_buff)
 if p.part!="legs": g.state.witch_focus=0
 var targets=g.state.enemies.filter(func(e):return not e.gone) if p.all else [g._enemy(p.enemy)]
 for hit in range(p.hits):
  for enemy in targets:
   if enemy.is_empty() or enemy.gone: continue
   g._damage_enemy(enemy,p.damage,p.damage_type,c.label,{"hit":hit+1,"hits":p.hits,"attack":true,"witch":true},damage_group)
   if p.interrupt and not enemy.gone and not enemy.intent.is_empty() and not enemy.intent.get("delayed",false):
    enemy.intent.delayed=true
    g._emit("event",enemy.name+"的动作被打断。",{"interrupt":{"enemy":enemy.id,"cancelled":enemy.intent.get("cancel_on_interrupt",false)}})

static func damage_multiplier(g, mana: float=-1.0, temporary: float=-1.0) -> float:
 if not active(g): return 1.0
 var stacks=0
 for card in g.state.powers:
  if card.type=="witch_accumulation": stacks+=int(card.get("power_stacks",1))
 return 1.0+((g.state.mana if mana<0 else mana)+(g.state.temporary_mana if temporary<0 else temporary))*0.01*stacks

static func restraint_part(g, slot: String) -> String:
 return "mouth" if slot=="mouth" else ("hand" if slot in g.B.ARM_SLOTS else ("legs" if slot in g.B.LEG_SLOTS else ""))

static func evade(g, requests: Array, source: String) -> bool:
 if not active(g): return false
 if Expansion.induce(g,requests,source): return true
 if Expansion.protects_preparation(g): return false
 var parts=[]
 for request in requests:
  var slots=g.Application._slots(request)
  for slot in slots:
   var part=restraint_part(g,slot)
   if part!="" and part not in parts: parts.append(part)
 for part in parts:
  if g.state.witch_charges[part]>=2:
   g.state.witch_charges[part]-=2
   g._emit("event","消耗2层%s施法预备，抵消这次拘束。" % NAMES[part],{"witch_evasion":{"part":part,"source":source}})
   return true
 return false

static func clear(g, clear_focus: bool=true, force: bool=false) -> void:
 if not active(g): return
 if force or not Expansion.protects_preparation(g):
  for part in PARTS: g.state.witch_charges[part]=0
 if clear_focus: g.state.witch_focus=0

static func retain_focus(g) -> void:
 if not active(g): return
 clear(g,false,true)
 g.state.witch_focus=mini(g.state.witch_focus,2+g.combat_retention_bonus())

static func lose_focus(g, amount: int, source: String) -> void:
 if not active(g): return
 var lost=mini(g.state.witch_focus,amount)
 if lost<=0: return
 g.state.witch_focus-=lost
 g._emit("event",source+"：精神集中－%d。" % lost,{"witch_focus_lost":lost})

static func relic_allowed(g, id: String, character: String="") -> bool:
 var role=g.state.get("character_id","original") if character=="" else character
 var required=g.Relics.TYPES[id].get("character_id","")
 if required!="" and required!=role: return false
 if role!=ID: return true
 if g.Relics.TYPES[id].modifiers.has("strength"): return false
 return id not in ["shining_lamp","olihakimi","mana_earring","break_bracer","ember","wrist_bracer"]

static func validate(g, s: Dictionary) -> String:
 if not s.get("deck") is Array: return "卡组记录不完整。"
 if s.deck.any(func(card):return not card is Dictionary or not card.get("type") is String): return "卡牌记录不完整。"
 if s.get("character_id","original") not in ["original",ID]: return "角色记录不正确。"
 if s.get("character_id","original")!=ID:
  if s.deck.any(func(card):return str(card.type).begins_with("witch_")): return "卡组中含有其他角色的专属卡牌。"
  return ""
 if not s.get("witch_charges") is Dictionary or s.witch_charges.size()!=4: return "部位蓄力记录不完整。"
 for part in PARTS:
  if not s.witch_charges.get(part) is int or s.witch_charges[part]<0: return "部位蓄力层数不正确。"
 if not s.get("witch_focus") is int or s.witch_focus<0: return "精神集中层数不正确。"
 if not s.get("special_equipment") is Array: return "装备记录不完整。"
 if s.special_equipment.any(func(e):return not e is Dictionary or not e.has("type") or not g.SpecialEquipment.DESIGNS.has(e.type)): return "装备记录不正确。"
 if s.special_equipment.any(func(e):return g.SpecialEquipment.occupied_slots(e).any(func(slot):return slot.begins_with("special_2"))): return "该角色没有这件装备所需的身体部位。"
 return ""
