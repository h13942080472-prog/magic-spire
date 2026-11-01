extends RefCounted

const E=preload("res://data/equipment.gd")
const GENERATION=[["glove","short","straight"],["glove","short","cross"],["glove","long","straight"],["glove","long","cross"],["leg","upper","straight"],["leg","lower","straight"],["leg","ankle","straight"],["leg","toes","straight"],["jacket","standard","straight"],["wrap","left","straight"],["wrap","right","straight"]]
const VARIANTS={"short":["upper_arm","forearm","wrist"],"long":["upper_arm","forearm","wrist","palm","fingers"]}
const STRAPS={"straight":["left","right"],"cross":["left","right"]}
const LEGS={"upper":["thigh"],"lower":["calf","ankle"],"ankle":["thigh","calf","ankle"],"toes":["thigh","calf","ankle","foot","toes"]}
const LEG_BANDS={"thigh_root":["大腿根外带","thigh"],"above_knee":["膝上外带","thigh"],"below_knee":["膝下外带","calf"],"ankle":["脚踝外带","ankle"]}
const PART_NAMES={"body":"套体","left":"左肩带","right":"右肩带","cross":"交叉肩带"}

const WEAR_TEXTS={
 "glove":"她将「{name}」从你的手指一路套上双臂，理平套体后逐条收紧肩带。双臂被牢牢包在一起，连手指也只能隔着紧绷的材质徒劳蜷动。",
 "leg":"她把「{name}」套上你的双腿，沿着大腿、小腿一路收紧外带。两条腿被整件拘束具并在一起，只能勉强挪动。",
 "jacket":"她把「{name}」套到你身上，将双臂折进封闭的袖筒，再扣紧衣身与下摆。你的手被压在身后，肩膀也难以抬起。",
 "wrap":"她合拢你的手掌与手指，用「{name}」一层层裹紧。整只手被包得严严实实，指节再也无法分开。"
}

static func name_for(variant: String) -> String:
 return ("长型" if variant=="long" else "短型")+"单手套"

static func wear_text(root: Dictionary) -> String:
 var name=str(root.get("name","复合拘束具"))
 return str(WEAR_TEXTS.get(root.get("kind",""),"她把「{name}」套到你身上，逐一收紧外侧的固定带，将覆盖的部位牢牢拘束起来。")).replace("{name}",name)

static func spec(kind: String, variant: String, straps: String="straight") -> Dictionary:
 var result={"kind":kind,"variant":variant,"straps":straps,"name":"","coverage":[],"closed":[],"parts":{},"minimum":2}
 if kind=="glove" and VARIANTS.has(variant) and STRAPS.has(straps):
  result.name=name_for(variant); result.coverage=VARIANTS[variant]
  result.closed=["palm","fingers"] if variant=="long" else []
  result.parts.body=part("套体","glove_body",result.coverage,result.coverage)
  for key in STRAPS[straps]:
   result.parts[key]=part(PART_NAMES[key],"glove_strap",[],["shoulder"])
   result.parts[key].side=key
 elif kind=="leg" and LEGS.has(variant):
  result.name={"upper":"短上段单腿套","lower":"短下段单腿套","ankle":"长至脚踝单腿套","toes":"长至脚趾单腿套"}[variant]
  result.coverage=LEGS[variant]; result.closed=["foot","toes"] if variant=="toes" else []
  result.parts.body=part("套体","leg_body",result.coverage,result.coverage)
  for key in LEG_BANDS:
   var band=LEG_BANDS[key]
   if band[1] not in result.coverage: continue
   result.parts[key]=part(band[0],"leg_band",[band[1]],[band[1]],true)
   result.parts[key].points=[key]
 elif kind=="jacket" and variant=="standard":
  result.name="拘束衣"; result.coverage=E.B.ARM_SLOTS; result.closed=E.B.ARM_SLOTS
  result.parts.body=part("衣身","jacket_body",result.coverage,result.coverage)
  result.parts.sleeves=part("袖部连接","jacket_sleeves",[],["wrist"])
  result.parts.hem=part("下摆固定","jacket_hem",[],["upper_arm"])
 elif kind=="wrap" and variant in ["left","right"]:
  result.name=("左" if variant=="left" else "右")+"手胶带包裹"; result.minimum=1; result.coverage=["palm","fingers"]
  result.parts.body=part("包裹","hand_wrap",result.coverage,result.coverage)
  result.parts.body.side=variant
 elif kind=="head" and variant=="harness":
  result.name="头部马具"; result.coverage=["mouth","eyes"]
  result.parts.body=part("固定结构","head_harness",[],["mouth"])
 else: return {}
 return result

static func part(label: String, template: String, coverage: Array, contact: Array, independent: bool=false) -> Dictionary:
 return {"label":label,"template":template,"coverage":coverage,"contact":contact,"independent":independent,"side":""}

static func active(root: Dictionary) -> bool:
 return root.components.any(func(e):return e.part=="body" and e.durability>0)

static func definition(root: Dictionary) -> Dictionary:
 return spec(root.kind,root.variant,root.straps)

static func has_open_strap(root: Dictionary) -> bool:
 return root.kind=="glove" and root.components.filter(func(e):return e.part!="body").size()<STRAPS[root.straps].size()

static func validate(root: Dictionary) -> String:
 var layout=spec(root.get("kind",""),root.get("variant",""),root.get("straps","straight"))
 if layout.is_empty() or root.get("name","")!=layout.name or root.get("layer",-1)<0: return "复合装备结构或层级有误。"
 var parts: Array=[]
 for e in root.get("components",[]):
  if not layout.parts.has(e.get("part","")) or e.part in parts: return "复合组件重复或归属有误。"
  parts.append(e.part)
  var p=layout.parts[e.part]
  if e.get("root_id","")!=root.id or e.id!=root.id+"_"+e.part or e.name!=root.name+" · "+p.label: return "复合组件归属存在差异。"
  if e.template!=p.template or e.get("coverage",[])!=p.coverage or e.get("contact_slots",[])!=p.contact or e.slot!=p.contact[0]: return "复合组件覆盖或接触位置有误。"
  if e.get("side","")!=p.side or e.get("independent",false)!=p.independent or e.get("points",[])!=p.get("points",[]): return "复合组件的侧别或独立固定结构有误。"
  if e.layer!=(0 if e.template=="glove_strap" else root.layer+(1 if p.independent else 0)): return "复合组件层级有误。"
  var physical=E.physical_reason(e)
  if physical!="": return physical
 if parts.is_empty() or ("body" not in parts and root.kind!="leg"): return "复合装备缺少主体。"
 return ""
