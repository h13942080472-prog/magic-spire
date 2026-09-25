extends RefCounted

# Read-only card wording, derived from the same face effects and eligibility data.
const Rules=preload("res://data/card_rules.gd")
static var TERMS={
 "mouth_clear":{"name":"嘴部无拘束","detail":"嘴部不能佩戴任何拘束具；提高施法成功率不能绕过此条件。"},
 "mind":{"name":"精神施法","detail":"无需手部或嘴部动作，仍受快感及施法成功率加成影响。"},
 "legs":{"name":"腿部施法预备","detail":"成功率受快感和腿部受限等级影响。"},
 "witch_focus":{"name":"精神集中","detail":"下次对敌人造成伤害的魔法每段伤害增加对应层数，整次施放消耗全部层数；魔力松缚不受加成，也不消耗层数。施法失败或高潮时失去1层。跨战斗最多保留2层，乌龟壳提高至4层。"},
 "unique":{"name":"唯一","detail":"重复使用或复放同一效果不会叠加；不同牌面的效果可以同时生效。"},
 "traction":{"name":"牵扯","detail":"触发花费能量引起的装备刺激、手牌刺激与捕缚效果。额外牵扯1次按1能量判定，不实际扣能量。"},
 "innate":{"name":"固有","detail":"每场开始时，优先进入起始手牌。"},
 "ethereal":{"name":"虚无","detail":"回合结束仍在手牌时消耗，优先于保留效果。"},
 "drinking":{"name":"饮用","detail":"嘴部装备等级＋紧度取最高：0—2为1费，3—4为2费，5为3费，6无法饮用。上身严密度大于0时需要坐姿或躺姿；不判施法。"},
 "hannya":{"name":"般若汤","detail":"当前等级不高于牌上等级时升1级，最高4级；同等级也升级。每级奖励本场只领一次。低级或满级时仅生成好汤。等级、属性及衍生牌保留至本场整备结束。复放不重复升级。"},

 "evasion":{"name":"闪避","detail":"即将被施加拘束具时，消耗1层抵消1件。本场结束时清除。"},
 "interrupt":{"name":"打断","detail":"使目标尚未执行的意图延后1回合。多段只打断一次，不与自带打断叠加。"},
 "mouth":{"name":"嘴部施法","detail":"成功率受快感与口部拘束影响。"},
 "hand":{"name":"手部施法","detail":"双手的手掌、手指须自由；施法动作教程可放宽为单手。"},
 "hand_use":{"name":"手部使用条件","detail":"双手的手掌、手指须自由；施法动作教程可放宽为单手。"},
 "none":{"name":"无部位要求","detail":"仅按快感值判定施法成功率。"},
 "strain":{"name":"挣扎","detail":"受力量、蓄力和挣扎倍率影响。卡牌以卡面伤害的50%波及同位置其他拘束具，各自计算倍率。"},
 "slip":{"name":"滑脱","detail":"受灵巧、蓄力和滑脱倍率影响；三档免疫。卡牌波及同大部位其他位置：各选最松的可滑脱装备1件，并列随机；基础为卡面伤害的50%，各自计算倍率。"},
 "magic_slip":{"name":"魔法滑脱","detail":"无视三档滑脱免疫，仍受外层、肩带及链接限制。波及范围和选取方式同普通滑脱。"},
 "charge":{"name":"蓄力","detail":"每层使一次主动挣扎、滑脱或体术基础伤害＋3。右键图标切换为下一次触发消耗全部层数。跨回合保留，本场结束最多保留2层；入狱清除。"},
 "reserve_mana":{"name":"魔力预备","detail":"每层立即获得5点临时魔力，优先抵扣耗魔；整备结束最多保留20点，乌龟壳提高至30点；不能存瓶或购物，入狱清除。"},
 "search":{"name":"检索","detail":"从抽牌堆抽取指定类型的牌。"},
 "retain":{"name":"保留","detail":"本回合结束时，保留的手牌不会丢弃。"},
 "auto_retain":{"name":"保留","detail":"回合结束不弃置。"},
 "exhaust":{"name":"消耗","detail":"成功使用后，本场不再抽到。"},
 "exhaust_hand":{"name":"消耗手牌","detail":"选择另一张手牌，本场不再抽到；不移除永久卡组中的牌。"},
 "lower":{"name":"降紧","detail":"降低目标紧度，按比例减少耐久。"},
 "unlock":{"name":"开锁","detail":"解除外露的锁，不减少耐久；连续开锁只付费、施法一次。"},
 "follow_through":{"name":"顺延","detail":"目标解除后，剩余段数依次转向同部位→同大部位→同区域的最外层拘束具；同级随机，不跨区。"},
 "replay":{"name":"复放","detail":"每层对原目标免费追加一次；次数可累计，下次触发时全部使用。魔法独立判定，不占火球次数，目标失效则跳过。"},
 "power":{"name":"能力","detail":"持续至本场结束。"},
 "levels":{"name":"束缚等级","detail":"上身或腿部综合受限程度（0—4级）。0级不等于各部位自由。"},
 "upper_clear":{"name":"各部位紧度＝0","detail":"头部、颈肩、双臂双手均无拘束。"}
}

static func requirements(type: String, free: bool, names: Dictionary) -> Array:
 var spec=Rules.SPECS[type]
 var result=[]
 var requirement=spec.get("witch_requirements",{}).get("free" if free else "bound","")
 if requirement!="": result.append({"mouth_grade":"嘴部拘束等级＜3","mouth_score":"嘴部拘束等级＋紧度＜4","tightness":"各部位拘束总紧度≤3"}[requirement])
 if spec.get("drinking",false): result.append("饮用：受嘴部与姿势限制")
 if spec.get("self_faces",{}).get("free" if free else "bound",{}).get("requires_hand",false): result.append("手部自由")
 if Rules.face_casts(type,free): result.append("施法："+"或".join(spec.casting.parts.map(func(part):return Rules.CAST_PART_NAMES[part])))
 elif spec.get("casting",{}).get("parts",[])==["hand"]: result.append("使用：手部")
 if not free and spec.has("target_slots") and spec.target_slots!=Rules.FOLLOW_THROUGH_SLOTS:
  var slots=spec.target_slots
  var label="腿部" if slots==Rules.FOLLOW_THROUGH_REGIONS.legs else "／".join(slots.map(func(slot):return names[slot]))
  result.append("目标："+label)
 if free:
  if spec.has("free_slots"): result.append("／".join(spec.free_slots.map(func(slot):return names[slot]))+"自由")
  for region in spec.get("free_max_levels",{}):
   var limit=spec.free_max_levels[region]
   result.append(("上身" if region=="arms" else "腿部")+"束缚等级"+("＝0" if limit==0 else "≤"+str(limit)))
 if spec.has("self_faces"):
  var posture=spec.self_faces["free" if free else "bound"].get("requires_posture","")
  if posture!="": result.append({"stand":"站姿限定","sit":"坐姿限定","lie":"躺姿限定"}[posture])
  var buff=Rules.BUFFS.get(spec.self_faces["free" if free else "bound"].get("buff",""),{})
  if buff.has("max_degree_any"):
   result.append("或".join(buff.max_degree_any.keys().map(func(region):return ("上身" if region=="arms" else "腿部")+"严密度≤"+str(buff.max_degree_any[region]))))
  for region in buff.get("min_levels",{}):
   result.append(("上身" if region=="arms" else "腿部")+"束缚等级≥"+str(buff.min_levels[region]))
  var slots=spec.self_faces["free" if free else "bound"].get("free_slots",[])
  if slots==["mouth"]: result.append("嘴部无拘束")
  elif not slots.is_empty(): result.append(("上身各部位" if slots==Rules.UPPER_BODY_SLOTS else "／".join(slots.map(func(slot):return names[slot])))+"紧度＝0")
 return result

static func _effect_terms(ids: Array, effects: Array) -> void:
 for effect in effects:
  var op=effect.op
  if op=="buff": _buff_terms(ids,Rules.BUFFS[effect.buff])
  elif op=="draw" and effect.has("filter"): ids.append("search")
  elif TERMS.has(op): ids.append(op)

static func _buff_terms(ids: Array, buff: Dictionary) -> void:
 if buff.has("magic_card_traction"): ids.append("traction")
 if buff.get("interrupt",false): ids.append("interrupt")
 if buff.has("replay"): ids.append("replay")
 for key in ["turn_start_effects","spell_use_effects"]: _effect_terms(ids,buff.get(key,[]))
 _effect_terms(ids,buff.get("mana_spent",{}).get("effects",[]))

static func keyword_ids(type: String, free: bool, traits: Dictionary) -> Array:
 var spec=Rules.SPECS[type]
 var ids=[]
 if Rules.unique_face(type,free): ids.append("unique")
 if spec.get("hand_modifiers",{}).get("energy_pressure",0)>0: ids.append("traction")
 if spec.get("drinking",false): ids.append("drinking")
 if spec.has("hannya_stage"): ids.append("hannya")
 for trait_id in ["innate","ethereal"]:
  if traits.get(trait_id,false): ids.append(trait_id)
 if spec.get("exhaust_hand",false): ids.append("exhaust_hand")
 if Rules.face_casts(type,free): ids.append_array(spec.casting.parts)
 elif spec.get("casting",{}).get("parts",[])==["hand"]: ids.append("hand_use")
 if not Rules.free_effect(type,free) and TERMS.has(Rules.face_mode(type,free)): ids.append(Rules.face_mode(type,free))
 if not Rules.free_effect(type,free) and spec.get("follow_through",false): ids.append("follow_through")
 if spec.has("self_faces"):
  var face=spec.self_faces["free" if free else "bound"]
  if face.get("requires_hand",false): ids.append("hand_use")
  _effect_terms(ids,face.get("effects",[]))
  if face.get("worn_resource",{}).get("resource","")=="charge": ids.append("charge")
  if face.has("buff"): _buff_terms(ids,Rules.BUFFS[face.buff])
  if face.get("exhaust_hand",false): ids.append("exhaust")
  if face.get("free_slots",[])==["mouth"]: ids.append("mouth_clear")
  elif not face.get("free_slots",[]).is_empty(): ids.append("upper_clear")
 else:
  for key in (["free_effects"] if free else ["hit_effects","lowered_effects","destroyed_effects"]): _effect_terms(ids,spec.get(key,[]))
 if spec.card_type=="power": ids.append("power")
 if Rules.exhausts(type,free,traits): ids.append("exhaust")
 if traits.get("retain",false): ids.append("auto_retain")
 if free and spec.has("free_max_levels"): ids.append("levels")
 var unique=[];var seen=[]
 for id in ids:
  if id not in seen:
   seen.append(id)
   unique.append(id)
 return unique

static func keywords(type: String, free: bool, traits: Dictionary) -> Array:
 var spec=Rules.SPECS[type]
 var result=[]
 for id in keyword_ids(type,free,traits):
  var term=TERMS[id].duplicate(true)
  if id=="follow_through" and spec.get("follow_through_scope","region")=="body":
   term.name="超级顺延"
   term.detail=Rules.SUPER_FOLLOW_THROUGH_TEXT
  result.append(term)
 return result

static func mana_entries(type: String, free: bool, cost: float, worn_count: Variant=null) -> Array:
 var spec=Rules.SPECS[type]
 var face=spec.get("self_faces",{}).get("free" if free else "bound",{})
 var temporary=0.0
 var effects=face.get("effects",[]) if spec.has("self_faces") else (spec.get("free_effects",[]) if free else [])
 for effect in effects:
  if effect.op=="reserve_mana": temporary+=Rules.amount(effect,spec)*Rules.RESERVE_MANA_VALUE
 var gain=Rules.HANNYA_MANA_GAIN if spec.has("hannya_stage") else float(face.get("mana_gain",0))
 var entries=[]
 var pressure=Rules.face_pressure_cost(type,free)
 if pressure>0 or Rules.lewd_magic(type):
  entries.append({"kind":"pressure","amount":pressure,"text":"−"+str(int(pressure)) if pressure>0 else "","detail":"消耗%s快感；施法失败全部返还。" % str(int(pressure)) if pressure>0 and Rules.face_casts(type,free) else ("消耗%s快感，不判施法。" % str(int(pressure)) if pressure>0 else "淫魔法：使用变换后的快感施法成功率。")})
 if spec.has("all_mana_minimum"):
  return [{"kind":"cost","amount":cost,"text":"-X","detail":"耗尽自身与临时魔力，合计至少需要%s点；不使用魔瓶魔力。" % str(spec.all_mana_minimum)}]
 for item in [{"kind":"cost","amount":cost},{"kind":"gain","amount":gain},{"kind":"temporary","amount":temporary}]:
  if item.amount<=0: continue
  var value=String.num(item.amount,2).trim_suffix(".0")
  item.text=("−" if item.kind=="cost" else "+")+value
  item.detail=("消耗"+value+"魔力，优先抵扣临时魔力。") if item.kind=="cost" else (("获得"+value+"点临时魔力。") if item.kind=="temporary" else "恢复"+value+"魔力，不超过上限。")
  if item.kind=="gain" and spec.has("hannya_stage"): item.detail="般若汤升级时恢复"+value+"魔力，不超过上限。"
  entries.append(item)
 if face.get("worn_resource",{}).get("resource","")=="mana":
  var amount=0 if worn_count==null else Rules.worn_gain(face,int(worn_count))
  entries.append({"kind":"gain","amount":float(amount),"text":"+X" if worn_count==null else "+"+str(amount),"detail":"每佩戴%d件拘束具，恢复%d魔力，不超过上限。" % [face.worn_resource.divisor,face.worn_resource.get("amount",1)]})
 var per_card=float(face.get("exhaust_hand_batch",{}).get("mana_gain",0))
 if per_card>0:
  var value=String.num(per_card,2).trim_suffix(".0")
  entries.append({"kind":"gain","amount":per_card,"text":"+"+value+"×","detail":"每消耗1张手牌，恢复"+value+"魔力，不超过上限。"})
 return entries

static func metadata(type: String, traits: Dictionary, names: Dictionary, mana_costs: Dictionary, worn_count: Variant=null) -> Dictionary:
 var result={"face_requirements":{},"face_keywords":{},"cast_faces":{},"face_mana":{},"face_names":{},"free_faces":{}}
 result.face_type_names={};result.face_warnings={}
 for side in ["bound","free"]:
  result.face_type_names[side]="／".join(Rules.type_tags(type,side=="free").map(func(tag):return "淫魔法" if tag=="magic" and Rules.lewd_magic(type) else Rules.TYPES[tag]))
  result.face_warnings[side]=Rules.SPECS[type].get("warning","")
  result.face_names[side]=Rules.face_name(type,side=="free")
  result.free_faces[side]=Rules.free_effect(type,side=="free")
  result.face_requirements[side]=requirements(type,side=="free",names)
  result.face_keywords[side]=keywords(type,side=="free",traits)
  result.cast_faces[side]=Rules.face_casts(type,side=="free")
  result.face_mana[side]=mana_entries(type,side=="free",mana_costs[side],worn_count)
 return result
