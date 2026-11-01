extends RefCounted

const B=preload("res://data/balance.gd")

static func slot_priority(slot: String) -> int:
 if slot=="wrist": return 3
 if slot in ["mouth","fingers"]: return 2
 return 1

const Special=preload("res://data/special_equipment.gd")
const BODY_SLOTS=B.ARM_SLOTS+B.LEG_SLOTS
const PANEL_GROUPS=[["eyes"],["mouth"],["neck","shoulder"],["upper_arm"],"special_1",["forearm"],["wrist"],["palm","fingers"],"special_2","special_3",["thigh"],["calf"],["ankle"],["foot","toes"]]
const LARGE_SLOTS=["upper_arm","forearm","wrist","palm","thigh","calf","ankle","foot"]
const SMALL_SLOTS=["palm","fingers","foot","toes"]
const SHACKLES=["handcuffs","ankle_cuffs","finger_cuffs","toe_cuffs"]
const SHACKLE_RESTRAINT_VALUE=4
const SHACKLE_MAXIMUM=999.0

static func is_shackle(e: Dictionary) -> bool:
 return TEMPLATES.get(e.get("template",""),{}).get("shackle",false)

const GRADES={1:"初级",2:"中级",3:"高级"}

const SEGMENTS={"upper_arm":["upper_arm_top","above_elbow"],"forearm":["below_elbow","mid_forearm"],"thigh":["thigh_root","mid_thigh","above_knee"],"calf":["below_knee","mid_calf"]}
const POINT_NAMES={"upper_arm_top":"大臂上侧","above_elbow":"手肘上方","below_elbow":"手肘下方","mid_forearm":"小臂中间","thigh_root":"大腿根","mid_thigh":"大腿中部","above_knee":"膝盖上方","below_knee":"膝盖下方","mid_calf":"小腿中间","palm_left":"左手掌","palm_right":"右手掌","fingers_left":"左手指","fingers_right":"右手指"}
const ANATOMY=["eyes","mouth","neck","shoulder","upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist","palm_left","palm_right","fingers_left","fingers_right","thigh_root","mid_thigh","above_knee","below_knee","mid_calf","ankle","foot","toes"]
const MATERIAL_NAMES={"rope":"绳索","leather":"皮革","tape":"胶带","plastic":"塑料","cloth":"布料","metal":"金属"}
const WEAR_TEXTS={
 "eyes":"她将「{name}」严严实实地覆上你的双眼，沿着眼眶仔细压平。最后一点光亮也被遮住，眼前顿时只剩漆黑。",
 "mouth":"她把「{name}」戴到你的嘴上，扶正后慢慢收紧。你的嘴被牢牢拘束住，再开口时只能发出含混的呜咽。",
 "neck":"她把「{name}」贴着颈侧绕好，一点点收紧到合适的位置。你刚想偏过脑袋，绷紧的拘束具便在颈侧留下清晰的压迫感。",
 "upper_arm":"她将你的双臂压回身侧，把「{name}」紧紧绑在大臂外侧。上臂被迫贴着身体，肩膀只能抬起一点。",
 "forearm":"她把你的两条小臂并在一起，用「{name}」一圈圈绑紧。你试着向两侧挣开，小臂间的拘束具立刻被动作绷得笔直。",
 "wrist":"她合拢你的双腕，把「{name}」绕上去仔细绑紧。两只手腕牢牢贴在一起，无论怎么转动，另一只手都会被一同带动。",
 "palm":"她将你的双手掌面对面压拢，再用「{name}」缠过掌心。手掌被紧紧拘束在一起，连翻腕和抓握都变得笨拙起来。",
 "fingers":"她捏拢你的十根手指，把「{name}」细细缠过指节。手指被挤得严丝合缝，十指紧紧并拢。",
 "thigh":"她将你的双腿用力并拢，把「{name}」绑上大腿逐渐收紧。两侧大腿紧紧贴合，你刚想把腿分开，拘束具便被动作拉得更紧。",
 "calf":"她合拢你的两条小腿，将「{name}」贴着腿侧绑好。小腿被拘束得无法左右分开，只能僵硬地随着双腿一同挪动。",
 "ankle":"她把你的两只脚踝并到一起，用「{name}」牢牢绑住。脚踝几乎紧贴，站立时只能并着双腿一点点跳动。",
 "foot":"她将你的两只脚掌并拢，把「{name}」绕过脚掌和足弓紧紧绑好。两只脚掌被迫贴在一起，脚尖稍微转开，足弓间的拘束具便会被动作拉紧。",
 "toes":"她并拢你的双脚，把「{name}」仔细缠上两只大脚趾。两根大脚趾被紧紧绑在一起，双脚稍微分开，拉扯感便会立刻传到趾根。"
}
const ANIMATED_WEAR_TEXTS={
 "eyes":"「{name}」从暗处弹起，紧贴着罩住你的双眼。束带自行向后一收，眼前顿时只剩漆黑。",
 "mouth":"「{name}」猛地扣上你的嘴，绕到脑后的束带随即收紧。你再开口时，只剩含混的呜咽。",
 "neck":"「{name}」贴着你的颈侧绕了一圈，像活物般自行收紧。你刚想偏头，颈侧便传来清晰的勒束感。",
 "upper_arm":"「{name}」攀上你的两条大臂，将双臂紧紧压回身侧。肩膀才抬起一点，绷紧的拘束具便把动作拦了下来。",
 "forearm":"「{name}」缠住你的两条小臂，一圈圈自行束紧。你试着向两侧挣开，绷直的拘束具立刻将小臂拉了回去。",
 "wrist":"「{name}」卷上你的双腕，飞快收紧。两只手腕被牢牢并在一起，稍一转动，另一只手也会被一同带走。",
 "palm":"「{name}」从掌侧钻过，将你的双手面对面缠紧。掌心被牢牢贴在一起，翻腕和抓握都变得笨拙。",
 "fingers":"「{name}」沿着指缝窜过，转眼便把十根手指缠在一起。指节被挤得严丝合缝，连一根手指也难以单独蜷起。",
 "thigh":"「{name}」绕上你的大腿，猛地将双腿拉拢。两侧大腿紧贴在一起，稍想分开，束带便自行勒得更紧。",
 "calf":"「{name}」贴着腿侧缠住两条小腿，迅速收紧。双腿再难左右分开，只能僵硬地一同挪动。",
 "ankle":"「{name}」从脚边窜起，绕住你的双踝牢牢收紧。两只脚踝几乎紧贴，步子顿时被锁在一起。",
 "foot":"「{name}」缠上两只脚掌，沿着足弓一圈圈收紧。脚掌被迫并在一起，脚尖稍一错开，足弓间便传来拉扯感。",
 "toes":"「{name}」贴地窜来，转眼缠紧两只大脚趾。双脚稍微分开，细带便立刻扯住趾根。"
}
const WEAR_STYLES=["assisted","animated"]

# Generation classes share material identity; physical templates retain their slot rules.
static func generation_class(template: String) -> String:
 return TEMPLATES[template].material
const MATERIALS={
 "metal":{1:["铁制镣铐"],3:["监牢合金"]},
 "rope":{1:["粗劣麻绳","柔软棉绳"],2:["尼龙绳","加强棉绳"],3:["魔导纤维绳"]},
 "leather":{1:["老化薄皮革","柔软皮革"],2:["厚牛皮","加强皮革"],3:["魔导皮革"]},
 "tape":{1:["纸质胶带","普通布胶带"],2:["布基胶带","纤维加强胶带"],3:["魔导封印胶带"]},
 "plastic":{1:["劣质塑料扎带","标准尼龙扎带"],2:["工业尼龙扎带","加强树脂扎带"],3:["魔导树脂扎带"]},
 "cloth":{1:["普通遮光布带"],2:["加厚遮光布带"],3:["加强遮光布带"]}
}
static var TEMPLATES={
 "art_hogtie":{"name":"驷马缚","material":"rope","slots":["wrist"],"strain":true,"slip":false,"manual":true,"lock":false,"generated":false},
 "handcuffs":{"name":"手铐","material":"metal","slots":["wrist"],"strain":true,"slip":true,"manual":false,"lock":true,"max_grade":1,"shackle":true,"generated":false,"damage_factor":0.1},
 "ankle_cuffs":{"name":"脚铐","material":"metal","slots":["ankle"],"strain":true,"slip":true,"manual":false,"lock":true,"max_grade":1,"shackle":true,"generated":false,"damage_factor":0.1},
 "finger_cuffs":{"name":"指铐","material":"metal","slots":["fingers"],"strain":true,"slip":true,"manual":false,"lock":true,"max_grade":1,"shackle":true,"generated":false,"damage_factor":0.1},
 "toe_cuffs":{"name":"趾铐","material":"metal","slots":["toes"],"strain":true,"slip":true,"manual":false,"lock":true,"max_grade":1,"shackle":true,"generated":false,"damage_factor":0.1},

 "restriction_collar":{"name":"限制项圈","material":"metal","slots":["neck"],"strain":false,"slip":false,"manual":true,"lock":true,"min_grade":3,"lock_only":true,"generated":false,"damage_factor":0.0},
 "torso_connection":{"name":"连接式固缚","material":"rope","slots":[],"strain":true,"slip":true,"manual":false,"lock":false},
 "special":{"name":"性玩具","material":"leather","slots":[],"strain":true,"slip":true,"manual":false,"lock":false},
 "leg_body":{"name":"单腿套套体","material":"leather","slots":[],"strain":true,"slip":true,"manual":false,"lock":true,"min_grade":2},
 "leg_band":{"name":"单腿套外带","material":"leather","slots":[],"strain":true,"slip":true,"manual":true,"lock":true,"min_grade":2},
 "jacket_body":{"name":"拘束衣衣身","material":"leather","slots":[],"strain":true,"slip":true,"manual":false,"lock":true,"min_grade":2},
 "jacket_sleeves":{"name":"袖部连接","material":"leather","slots":[],"strain":true,"slip":false,"manual":true,"lock":true,"min_grade":2},
 "jacket_hem":{"name":"下摆固定","material":"leather","slots":[],"strain":true,"slip":true,"manual":true,"lock":true,"min_grade":2},
 "hand_wrap":{"name":"单侧手部包裹","material":"tape","slots":[],"strain":true,"slip":true,"manual":false,"lock":false},
 "head_harness":{"name":"头部马具","material":"leather","slots":[],"strain":true,"slip":false,"manual":true,"lock":true,"min_grade":2},
 "eye_tape":{"name":"胶带眼罩","material":"tape","slots":["eyes"],"strain":false,"slip":true,"manual":false,"lock":false},
 "mouth_tape":{"name":"堵嘴胶带","material":"tape","slots":["mouth"],"strain":true,"slip":true,"manual":false,"lock":false},
 "glove_body":{"name":"单手套套体","material":"leather","slots":[],"strain":true,"slip":true,"manual":false,"lock":true,"min_grade":2},
 "glove_strap":{"name":"单手套肩带","material":"leather","slots":[],"strain":false,"slip":true,"manual":true,"lock":true,"min_grade":2},
 # Links share material/method definitions, but require the separate two-target factory.
 "link_rope":{"name":"链接绳","material":"rope","slots":[],"strain":true,"slip":false,"manual":true,"lock":false},
 "rope":{"name":"绳索","material":"rope","slots":LARGE_SLOTS,"strain":true,"slip":true,"manual":true,"lock":false},
 "cord":{"name":"细绳","material":"rope","slots":SMALL_SLOTS,"strain":true,"slip":true,"manual":true,"lock":false},
 "belt":{"name":"皮带","material":"leather","slots":LARGE_SLOTS,"strain":true,"slip":true,"manual":true,"lock":true},
 "fine_belt":{"name":"细皮带","material":"leather","slots":SMALL_SLOTS,"strain":true,"slip":true,"manual":true,"lock":true},
 "tape":{"name":"胶带","material":"tape","slots":BODY_SLOTS,"strain":true,"slip":true,"manual":false,"lock":false},
 "cable_tie":{"name":"扎带","material":"plastic","slots":BODY_SLOTS,"strain":true,"slip":true,"manual":false,"lock":false},
 # Head fixtures use dedicated definitions; ordinary limb templates never cover the head.
 "eye_cloth":{"name":"布带眼罩","material":"cloth","slots":["eyes"],"strain":false,"slip":true,"manual":true,"lock":false},
 "eye_leather":{"name":"皮革眼罩","material":"leather","slots":["eyes"],"strain":false,"slip":true,"manual":true,"lock":true,"min_grade":2},
 "mouth_band":{"name":"口球","material":"leather","slots":["mouth"],"strain":true,"slip":true,"manual":true,"lock":true}
}

static func maximum(grade: int) -> float:
 return {1:B.BASIC_DURABILITY,2:B.MEDIUM_DURABILITY,3:B.HIGH_DURABILITY}.get(grade,0.0)

static func capacity(slot: String, template: String="") -> int:
 if slot=="mouth" and template!="" and TEMPLATES[template].material!="tape": return 1
 return 2 if slot in ["eyes","mouth"] or slot in SMALL_SLOTS else 3

static func default_template(slot: String) -> String:
 if slot=="eyes": return "eye_cloth"
 if slot=="mouth": return "mouth_band"
 return "fine_belt" if slot in SMALL_SLOTS else "belt"

# Imported ordinary variants retain family-specific rules keyed by their base.
static func base_template(template: String) -> String:
 return TEMPLATES.get(template,{}).get("base_template",template)

static func definition_reason(template: String, slot: String, grade: int, locked: bool=false) -> String:
 if not TEMPLATES.has(template): return "该装备待加入本次试炼。"
 if not GRADES.has(grade): return "装备等级必须为初级、中级或高级。"
 var spec=TEMPLATES[template]
 if grade<spec.get("min_grade",1) or grade>spec.get("max_grade",3): return "请选择已开放的装备等级。"
 if not spec.slots.has(slot): return spec.name+"请选择装备适用部位。"
 if locked and not spec.lock: return spec.name+"没有可上锁的位置。"
 return ""

static func mouth_combination(grade: int, variant: int=0) -> Dictionary:
 # The existing variant index selects the two middle-grade combinations.
 # Grade one material variants both use the ordinary combination.
 var harness=grade==3 or (grade==2 and variant==0)
 var insert=grade==3 or (grade==2 and variant==1)
 return {"harness":harness,"insert":insert,"name":("马具" if harness else "普通")+("假阳具口球" if insert else "口球")}

static func has_mouth_harness(e: Dictionary) -> bool:
 return base_template(e.get("template",""))=="mouth_band" and mouth_combination(e.grade,e.variant).harness

static func name_for(template: String, slot: String, grade: int=1, variant: int=0) -> String:
 if TEMPLATES[template].get("lock_only",false) or TEMPLATES[template].get("shackle",false): return TEMPLATES[template].name
 if template=="art_hogtie": return "驷马缚"
 if template=="mouth_band": return mouth_combination(grade,variant).name
 return ("" if slot in ["eyes","mouth"] else B.SLOT_NAMES[slot])+TEMPLATES[template].name

static func wear_text(name: String, slot: String, style: String="assisted") -> String:
 var texts=ANIMATED_WEAR_TEXTS if style=="animated" else WEAR_TEXTS
 var fallback="「{name}」突然缠上身体，自行收紧。你的动作随即受到拘束。" if style=="animated" else "她把「{name}」戴到相应部位，仔细调整后逐渐收紧。你的动作随即受到拘束。"
 return texts.get(slot,fallback).replace("{name}",name).strip_edges()

static func material_name(e: Dictionary) -> String:
 if Special.is_special(e): return Special.material_name(e)
 if e.template=="torso_connection": return MATERIALS[e.material][e.grade][e.variant]
 return MATERIALS[TEMPLATES[e.template].material][e.grade][e.variant]

static func is_shoulder(e: Dictionary) -> bool:
 return e.has("shoulder_host") or e.get("template","")=="glove_strap"

static func allows(e: Dictionary, method: String) -> bool:
 if method=="slip" and has_mouth_harness(e): return false
 if is_shoulder(e) and method=="strain": return false
 if Special.is_special(e): return Special.allows(e,method)
 return TEMPLATES[e.template][method] and (method!="slip" or e.get("slip_allowed",true))

static func method_text(e: Dictionary) -> String:
 if is_shackle(e): return "开锁即取下 / 挣扎 / 滑脱 · 固定减伤90%"
 if lock_only(e): return "先开锁，双臂自由后取下"
 var available: Array[String]=[]
 for pair in [["strain","挣扎"],["slip","滑脱"],["manual","徒手"]]:
  if allows(e,pair[0]): available.append(pair[1])
 return " / ".join(available)+(" · 可上锁" if allows(e,"lock") else " · 锁孔：无")

static func coverage(e: Dictionary) -> Array:
 if e.get("template","")=="art_hogtie": return ["wrist","ankle"]
 return e.get("coverage",[e.slot])

# Lock-only pieces use a constant lifecycle marker, never a damageable meter.
static func lock_only(e: Dictionary) -> bool:
 return TEMPLATES.get(e.get("template",""),{}).get("lock_only",false)

const LOCK_ONLY_REASON="限制项圈没有耐久，须先开锁，再在双臂自由时取下；品相完美版 henshin 可直接解除。"

static func contact_slots(e: Dictionary) -> Array:
 return e.get("contact_slots",coverage(e))

# Shared sidebar anatomy for regional effects and read-only presentation.
static func panel_groups() -> Array:
 var out=[]
 for definition in PANEL_GROUPS:
  if definition is String:
   var region=Special.REGIONS.filter(func(r):return r.id==definition)[0]
   out.append({"id":region.id,"name":region.name,"slots":region.slots.duplicate(),"special":true})
  else:
   var id="hands" if "palm" in definition else ("feet" if "foot" in definition else definition[0])
   out.append({"id":id,"name":{"neck":"颈肩","hands":"手部","feet":"足部"}.get(id,B.SLOT_NAMES.get(id,"")),"slots":definition.duplicate(),"special":false})
 return out

static func points(slot: String, side: String="") -> Array:
 if slot in ["palm","fingers"]: return [slot+"_"+side] if side!="" else [slot+"_left",slot+"_right"]
 if SEGMENTS.has(slot): return SEGMENTS[slot].duplicate()
 return [slot]

static func point_name(point: String) -> String:
 if point in Special.slots(): return Special.slot_name(point)
 return POINT_NAMES.get(point,B.SLOT_NAMES.get(point,"肩部"))

# Display attachment locations never add capacity or change action reach.
static func display_points(e: Dictionary) -> Array:
 if is_shoulder(e): return ["shoulder"]
 if e.template=="link_rope":
  return e.contact_points.duplicate()
 var result=physical_points(e)
 if result.is_empty():
  for slot in contact_slots(e): result.append_array(points(slot))
 return result

static func position_text(e: Dictionary) -> String:
 if is_shoulder(e): return {"left":"左肩","right":"右肩"}.get(e.get("side",e.get("part","")),"肩部")
 var locations=physical_points(e)
 if e.template=="link_rope": locations=e.contact_points
 var text="、".join(locations.map(func(p):return point_name(p)))
 return text

static func anatomical_order(e: Dictionary) -> int:
 if is_shoulder(e): return ANATOMY.find("shoulder")
 var order=ANATOMY.size()
 for point in physical_points(e):
  var index=ANATOMY.find(point)
  if index>=0: order=mini(order,index)
 return order

static func physical_points(e: Dictionary) -> Array:
 if e.template=="link_rope": return e.contact_points.duplicate()
 if e.has("points"): return e.points
 var result: Array=[]
 for slot in coverage(e): result.append_array(points(slot,e.get("side","")))
 return result

# Slip anatomy includes shoulder straps without adding body coverage or capacity.
static func slip_points(e: Dictionary) -> Array:
 if is_shoulder(e): return ["shoulder"]
 return physical_points(e)

static func capacity_points(e: Dictionary) -> Array:
 if e.get("template","")=="art_hogtie": return []
 return [] if e.template in ["link_rope","leg_body","glove_strap","jacket_sleeves","jacket_hem","head_harness"] else physical_points(e)

static func overlaps(a: Dictionary, b: Dictionary) -> bool:
 var bp=physical_points(b)
 return physical_points(a).any(func(p):return p in bp)

static func physical_reason(e: Dictionary) -> String:
 if not TEMPLATES.has(e.get("template","")) or not GRADES.has(e.get("grade",0)): return "装备模板或等级缺失。"
 var spec=TEMPLATES[e.template]
 if e.grade<spec.get("min_grade",1) or e.grade>spec.get("max_grade",3): return "请选择已开放的装备等级。"
 if e.get("material","")!=spec.material: return "装备材质与模板存在差异。"
 if e.get("locked",false) and not spec.lock: return "锁孔：无。"
 if not e.has("variant") or e.variant<0 or e.variant>=MATERIALS[spec.material][e.grade].size(): return "装备材质版本缺失。"
 if not e.has("maximum") or not e.has("durability") or not is_finite(e.maximum) or not is_finite(e.durability) or e.maximum<=0 or e.durability<=0 or e.durability>e.maximum+0.00001: return "装备耐久有误。"
 if is_shackle(e) and (e.maximum!=SHACKLE_MAXIMUM or not e.get("locked",false)): return "镣铐必须使用固定耐久并保持上锁；开锁后应移除。"
 if lock_only(e) and (e.maximum!=1.0 or e.durability!=1.0): return "限制项圈需要先开锁，再由自由双臂取下。"
 return ""

static func validate(e: Dictionary) -> String:
 var reason=definition_reason(e.get("template",""),e.get("slot",""),e.get("grade",0),e.get("locked",false))
 if reason!="": return reason
 reason=physical_reason(e)
 if reason!="": return reason
 if e.get("name","")!=name_for(e.template,e.slot,e.grade,e.variant): return "装备内容与模板存在差异"
 if not e.has("layer") or e.layer<0: return "装备层级有误"
 if e.has("coverage") or e.has("root_id") or e.has("parent_id") or e.has("shoulder_host"): return "普通装备仅可使用自身覆盖与连接结构。"
 var actual=e.get("points",[])
 if SEGMENTS.has(e.slot):
  if actual.size()!=1 or actual[0] not in SEGMENTS[e.slot]: return "普通装备必须占据本区域的一个具体位置。"
 elif e.template=="art_hogtie":
  if actual!=["wrist","ankle"]: return "驷马缚必须同时连接手腕与脚踝。"
 elif actual!=points(e.slot): return "装备的具体位置与身体部位存在差异。"
 return ""
