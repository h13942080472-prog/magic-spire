extends RefCounted

const REWARDS=["witch_magic_circle","witch_binding_lure","witch_mana_transfer","witch_patience","witch_endurance","witch_small_fry","witch_authority"]
const TRAINING=["witch_escape_practice","witch_escape_practice_10","witch_escape_practice_20","witch_escape_practice_30","witch_escape_practice_40","witch_escape_practice_35"]
const LOCK_TEXT="锁定回合结束按钮！"

static func register(g) -> void:
 var rules=g.Cards.Rules
 var buffs={
  "witch_patience":{"name":"耐心耐心～","duration":"next_turn_start","detail":"直到下回合开始，施法预备不会减少（主动释放除外），也不能用来抵挡拘束。"},
  "witch_circle_free":{"name":"绘制法阵·预备","duration":"battle","detail":"基础动作施法预备不消耗魔力；主动释放仍照常消耗魔力。"},
  "witch_circle_bound":{"name":"绘制法阵","duration":"battle","stackable":true,"detail":"打出时，下3张技能牌费用－1，最低0；0费技能牌也消耗次数。"},
  "witch_circle_skills":{"name":"法阵减费","duration":"battle","attack_uses":3,"stack_uses":true,"detail":"下3张技能牌费用－1，最低0；0费技能牌也消耗次数。再次获得时累计次数。"},
  "witch_half_pressure":{"name":"忍耐","duration":"turn","witch_pressure_factor":0.5,"detail":"本回合快感获取量×0.5，命运同担的均分不受影响。"},
  "witch_endurance_two":{"name":"忍耐·本回合及下回合","duration":"turn","witch_pressure_factor":0.5,"on_expire_buff":"witch_half_pressure","detail":"本回合及下回合快感获取量×0.5，命运同担的均分不受影响。"},
  "witch_endurance_next":{"name":"忍耐·下回合","duration":"turn","on_expire_buff":"witch_half_pressure","detail":"下回合快感获取量×0.5，命运同担的均分不受影响。"},
  "witch_authority_lock":{"name":"窃取权柄","duration":"turn","witch_pressure_factor":0.5,"detail":"本回合快感获取量×0.5。锁定回合结束按钮！必须在本回合获胜，否则只能投降。"},
  "witch_authority_power":{"name":"窃取权柄","duration":"battle","stackable":true,"detail":"打出时获得对应牌面的效果。本回合必须获胜，否则只能投降。"}
 }
 for part in ["hand","mouth"]:
  buffs["witch_induction_"+part]={"name":"拘束诱导·"+g.Character.NAMES[part],"duration":"next_turn_start","detail":"直到下回合开始，闪避所有%s拘束；每次成功闪避，其他合法部位随机佩戴一件同等级、同紧度的拘束具。" % g.Character.NAMES[part]}
  buffs["witch_interrupt_"+part]={"name":"杂鱼♡～杂鱼♡～·"+g.Character.NAMES[part],"duration":"battle","attack_uses":1,"detail":"下次成功释放%s基础法术时附加一次打断；同次释放不重复打断。" % g.Character.NAMES[part]}
 for buff in buffs.values(): buff.witch_session=true
 rules.BUFFS.merge(buffs)
 var sensitive=g.Cards.Rules.SPECS.sensitive.duplicate(true)
 sensitive.character_id="witch";sensitive.art_type="sensitive";sensitive.encyclopedia_hidden=true;sensitive.reward_excluded=true
 rules.SPECS.witch_sensitive=sensitive;g.B.CARD_NAMES.witch_sensitive="敏感";g.B.CARD_INFO.witch_sensitive=g.B.CARD_INFO.sensitive.duplicate(true)
 g.B.CARD_TRAITS.witch_sensitive=g.B.CARD_TRAITS.sensitive.duplicate(true);g.B.CARD_TRAITS.witch_sensitive.temporary=true
 for index in range(TRAINING.size()):
  var damage=1 if index<2 else (2 if index==2 else 3)
  var hits=3 if index==0 else 6
  var spec={"card_type":"skill","rarity":"basic","cost":0 if index==5 else 1,"mode":"strain","damage_type":"strain","base":float(damage),"hits":hits,"bound_modes":["strain","slip"],"witch_training_stage":index,"starting_card":true}
  if index>=2: spec.follow_through=true;spec.target_slots=rules.FOLLOW_THROUGH_SLOTS
  if index>=4: spec.follow_through_scope="body"
  var ending="，超级顺延。" if index>=4 else ("，顺延。" if index>=2 else "。")
  add(g,TRAINING[index],"脱缚练习（Lv.%d）" % index,spec,["技能","挣扎{base}×{hits}"+ending,"滑脱{base}×{hits}"+ending,"两面合计打出7／14／21／28／35次后永久进化。本局跨战斗保留；每段分别结算，一张牌只累计1次。"],"repeated_strain")
  rules.SPECS[TRAINING[index]].reward_excluded=true
  rules.SPECS[TRAINING[index]].encyclopedia_hidden=index>0
 add(g,"witch_mana_transfer","魔力抽调",{"card_type":"skill","type_tags":["skill","magic"],"rarity":"common","cost":0,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"witch_actions":{"bound":"flask"},"self_faces":{"bound":{"card_type":"skill"},"free":{"card_type":"magic","cast":true,"energy_cost":1,"effects":[{"op":"reserve_mana","amount":4}]}}},["技能／魔法","至多消耗40魔瓶魔力，为自己恢复等量魔力。","{self_free_effects}","只取恢复所需的魔瓶魔力，不超过自身魔力上限。"],"mana_conversion")
 add(g,"witch_patience","耐心耐心～",{"card_type":"skill","type_tags":["skill","magic"],"rarity":"uncommon","cost":0,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"witch_actions":{"bound":"protect"},"witch_requirements":{"free":"mouth_grade"},"self_faces":{"bound":{"card_type":"skill"},"free":{"card_type":"magic","cast":true,"energy_cost":1,"mana_cost":20.0,"effects":[{"op":"next_energy","amount":3}]}}},["技能／魔法","直到下回合开始，施法预备不会减少（主动释放除外），也不能用来抵挡拘束。","下回合额外获得3能量。",""],"prepared_chant")
 g.B.CARD_TRAITS.witch_patience={"retain":true}
 add(g,"witch_magic_circle","绘制法阵",{"card_type":"power","rarity":"uncommon","cost":1,"mode":"power","free_max_levels":{"arms":3},"self_faces":{"bound":{"buff":"witch_circle_bound","effects":[{"op":"buff","buff":"witch_circle_skills"}]},"free":{"buff":"witch_circle_free"}}},["能力","下3张技能牌消耗－1，最低0。","基础动作施法预备不再消耗魔力。",""],"formation")
 add(g,"witch_endurance","忍耐",{"card_type":"skill","rarity":"uncommon","cost":0,"mode":"self","witch_actions":{"bound":"endure_two","free":"endure_next"},"witch_requirements":{"free":"mouth_score"},"self_faces":{"bound":{"exhaust":true},"free":{"exhaust":true}}},["技能","本回合及下回合快感获取量×0.5（命运同担无效）。将1张敏感加入弃牌堆。","下回合快感获取量×0.5（命运同担无效）。",""],"concentration")
 add(g,"witch_small_fry","杂鱼♡～杂鱼♡～",{"card_type":"magic","rarity":"rare","cost":1,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"witch_actions":{"bound":"interrupt_mouth","free":"interrupt_hand"},"self_faces":{"bound":{"cast":true,"energy_cost":1,"mana_cost":10.0},"free":{"cast":true,"mana_cost":20.0}}},["魔法","下次嘴部法术释放附加一次打断。","下次手部法术释放附加一次打断。","同次释放不重复打断；施法预备动作不消耗此效果。"],"infusion")
 add(g,"witch_authority","窃取权柄",{"card_type":"power","rarity":"rare","cost":0,"mode":"power","witch_actions":{"bound":"authority_release","free":"authority_energy"},"witch_requirements":{"free":"tightness"},"self_faces":{"bound":{"buff":"witch_authority_power","mana_cost":60.0},"free":{"buff":"witch_authority_power","mana_cost":60.0}}},["能力","解除全部拘束与捕缚，清空快感。本回合快感获取量×0.5。"+LOCK_TEXT,"获得3能量、8层魔力预备和3层精神集中，清空快感。本回合快感获取量×0.5。"+LOCK_TEXT,"必须在本回合获胜，否则只能投降。"],"henshin")

 add(g,"witch_binding_lure","拘束诱导",{"card_type":"skill","rarity":"uncommon","cost":0,"mode":"self","bound_modes":["self","self"],"self_faces":{"bound":{"buff":"witch_induction_mouth"},"free":{"buff":"witch_induction_hand"}}},["技能","直到下回合开始，闪避所有嘴部拘束。每次成功闪避，其他部位随机佩戴一件同等级、同紧度的拘束具。","直到下回合开始，闪避所有手部拘束。每次成功闪避，其他部位随机佩戴一件同等级、同紧度的拘束具。","两面效果可共存；同面重复使用不叠加。无其他合法位置时，只闪避。"],"witch_binding_lure")

static func add(g, id: String, name: String, spec: Dictionary, text: Array, art: String) -> void:
 if id=="witch_authority": spec.warning=LOCK_TEXT
 spec.character_id="witch";spec.art_type=art
 g.Cards.Rules.SPECS[id]=spec;g.B.CARD_NAMES[id]=name;g.B.CARD_INFO[id]=text

static func protects_preparation(g) -> bool:
 return g.Character.active(g) and "witch_patience" in g.state.card_buffs

static func free_preparation(g) -> bool:
 return g.Character.active(g) and "witch_circle_free" in g.Cards.active_buffs(g)

static func skill_discount(g, type: String, free: bool) -> int:
 return 1 if g.Character.active(g) and "witch_circle_skills" in g.state.card_buffs and "skill" in g.Cards.Rules.type_tags(type,free) else 0

static func pressure_multiplier(g) -> float:
 var result=1.0
 if g.Character.active(g):
  for id in g.state.card_buffs: result=minf(result,float(g.Cards.Rules.BUFFS[id].get("witch_pressure_factor",1.0)))
 return result

static func end_reason(g) -> String:
 return "窃取权柄：本回合不能结束回合，必须获胜，否则只能投降。" if g.state.phase=="battle" and "witch_authority_lock" in g.state.card_buffs else ""

static func induce(g, requests: Array, source: String) -> bool:
 var protected=["mouth","hand"].filter(func(part):return "witch_induction_"+part in g.state.card_buffs)
 if protected.is_empty(): return false
 for request in requests:
  var occupied=g.Application._slots(request)
  if not occupied.any(func(slot):return g.Character.restraint_part(g,slot) in protected): continue
  var slots=g.B.SLOTS.filter(func(slot):return slot not in occupied and g.Character.restraint_part(g,slot) not in protected)
  var spec={"templates":g.Equipment.TEMPLATES.keys(),"slots":slots,"allow_links":false,"grade":request.get("grade",2),"tier":request.get("tier",2),"replace":false}
  # The redirected cost is voluntary: it must not recurse or consume another dodge.
  var replacement=g.Application.choose(g,spec,source,"equipment")
  var outcome=g.Application.execute_concrete(g,replacement,source,false,[],true) if not replacement.is_empty() else {}
  g._emit("event","拘束诱导：闪避了原定拘束。"+("其他部位已佩戴一件同等级、同紧度的拘束具。" if outcome.get("ok",false) else "没有其他合法佩戴位置。"),{"witch_induction":{"source":source,"grade":spec.grade,"tier":spec.tier,"redirected":outcome.get("ok",false)}})
  return true
 return false

static func training_progress(card: Dictionary) -> String:
 var count=int(card.get("practice_plays",0))
 if count>=35: return "本局累计打出%d次，已完成全部升级。" % count
 var next=(int(count/7)+1)*7
 return "升级进度：%d／%d次；再使用%d次升级。" % [count,next,next-count]

static func reason(g, p: Dictionary) -> String:
 var spec=g.Cards.Rules.SPECS[p.type]
 var condition=spec.get("witch_requirements",{}).get("free" if p.get("free",false) else "bound","")
 var mouth=g.equipment_at("mouth")
 if condition=="mouth_grade" and mouth.any(func(item):return item.grade>=3): return "需要嘴部拘束等级小于3。"
 if condition=="mouth_score" and g.Cards.Hannya.mouth_score(g)>=4: return "需要嘴部拘束等级＋紧度小于4。"
 if condition=="tightness":
  for slot in g.B.SLOTS+g.SpecialEquipment.slots():
   var tightness=0
   for target in g.targets_at(slot):
    if not g.Equipment.lock_only(target): tightness+=g.tier(target.durability,target.maximum)
   if tightness>3: return "需要每个部位的拘束总紧度不超过3。"
 if spec.get("witch_actions",{}).get("free" if p.get("free",false) else "bound","").begins_with("authority") and g.state.phase!="battle": return "窃取权柄只能在战斗中使用。"
 return ""

static func resolve(g, p: Dictionary) -> void:
 var action=g.Cards.Rules.SPECS[p.type].get("witch_actions",{}).get("free" if p.free else "bound","")
 match action:
  "flask":
   var amount=minf(40.0,minf(g.state.flask_mana,maxf(0.0,g.state.mana_max-g.state.mana)))
   g.state.flask_mana-=amount;g.state.mana+=amount
   g._emit("event","魔力抽调：消耗%s魔瓶魔力，恢复%s自身魔力。" % [g.number(amount),g.number(amount)],{"flask_transfer":amount})
  "protect": g.Cards.grant_buff(g,"witch_patience")
  "endure_two":
   g.Cards.grant_buff(g,"witch_endurance_two")
   g._gain_temporary_card("witch_sensitive")
  "endure_next": g.Cards.grant_buff(g,"witch_endurance_next")
  "interrupt_hand","interrupt_mouth": g.Cards.grant_buff(g,"witch_"+action)
  "authority_release","authority_energy":
   if action=="authority_energy":
    g.Cards.apply_effects(g,[{"op":"energy","amount":3},{"op":"reserve_mana","amount":8},{"op":"witch_focus","amount":3}],{},g.B.CARD_NAMES[p.type])
   else:
    g.CaptureBind.clear_bind(g)
    for target in g.action_targets(): g._apply_manual_release(target,0.0,true,true)
    g._cleanup()
   g.Pressure.lose(g,g.state.pressure)
   g.Cards.grant_buff(g,"witch_authority_lock")
 if action!="" and action!="flask":
  var log_args={"type":p.type,"free":p.free}
  g._emit("event",g.CopyRouter.text(g,{"kind":"witch.card_log","args":log_args,"fallback":card_log_detail(g,log_args)}),{"witch_card":action})

# R6（docs/ondemand-copy.md「文案路由（收口阶段）」）：巫女卡牌事件日志文案的 builder，正文留在本模块。
static func card_log_detail(g, args: Dictionary) -> String:
 return g.B.CARD_NAMES[String(args.get("type",""))]+"："+g.Cards.face_text(g,String(args.get("type","")),bool(args.get("free",false)))

static func evolve(g, card: Dictionary) -> void:
 if not g.Cards.Rules.SPECS[card.type].has("witch_training_stage"): return
 var count=int(card.get("practice_plays",0))+1
 var old=card.type
 card.practice_plays=count;card.type=TRAINING[mini(5,count/7)]
 for permanent in g.state.deck:
  if permanent.uid==card.uid: permanent.practice_plays=count;permanent.type=card.type
 g._emit("event","脱缚练习：本局累计打出%d次。" % count+("已永久进化。" if old!=card.type else ""),{"witch_practice":{"uid":card.uid,"plays":count,"evolved":old!=card.type}})

static func validate_card(g, card: Dictionary) -> String:
 var spec=g.Cards.Rules.SPECS[card.type]
 if spec.has("witch_training_stage"):
  var count=card.get("practice_plays",0)
  if not count is int or count<0 or mini(5,count/7)!=spec.witch_training_stage: return "脱缚练习的累计次数与进化阶段不一致。"
 elif card.has("practice_plays"): return "这张牌没有脱缚练习进度。"
 return ""
