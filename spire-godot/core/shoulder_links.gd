extends RefCounted

const E=preload("res://data/equipment.gd")
const BASES=["rope","cord","belt","fine_belt","tape","cable_tie"]
const SIDES=["left","right"]

static func eligible(e: Dictionary) -> bool:
 return e.get("slot","")=="upper_arm" and E.base_template(e.get("template","")) in BASES and not e.has("root_id") and not e.has("shoulder_host")

static func pieces(g) -> Array:
 var result=[]
 for e in g.state.equipment:
  if e.has("shoulders"): result.append_array(e.shoulders.pieces)
 return result

static func attached(g, host: Dictionary) -> Array:
 if host.get("template","")=="glove_body":
  return g._composite(host.root_id).components.filter(func(e):return E.is_shoulder(e) and e.durability>0.000001)
 return host.get("shoulders",{}).get("pieces",[]).filter(func(e):return e.durability>0.000001)

static func missing(g, host: Dictionary) -> bool:
 return eligible(host) and attached(g,host).size()<2

static func label(template: String, side: String) -> String:
 return ("左肩" if side=="left" else "右肩")+{"rope":"绳","belt":"皮带"}.get(template,E.TEMPLATES[template].name)

static func install_reason(g, host: Dictionary, template: String, grade: int) -> String:
 if not eligible(host): return "肩部链接需要连接大臂上侧或手肘上方的普通拘束具。"
 if E.base_template(template) not in BASES or grade not in E.GRADES: return "肩部拘束的基础类型或品质缺失。"
 if not g._outer(host) or g._sealed_reason("upper_arm")!="": return "需要先露出大臂上的连接位置。"
 if not attached(g,host).is_empty(): return "这件装备已经附有肩部拘束，每件最多一对。"
 return ""

static func install(g, host: Dictionary, template: String, grade: int, source: String) -> bool:
 if install_reason(g,host,template,grade)!="": return false
 host.shoulders={"template":template,"grade":grade,"variant":0,"source":source,"pieces":[]}
 fill(g,host)
 return true

static func fill(g, host: Dictionary) -> void:
 var pair=host.shoulders
 pair.pieces=pair.pieces.filter(func(e):return e.durability>0.000001)
 for side in SIDES:
  if pair.pieces.any(func(e):return e.side==side and e.durability>0.000001): continue
  var maximum=E.maximum(pair.grade)
  pair.pieces.append({"id":host.id+"_shoulder_"+side,"shoulder_host":host.id,"template":pair.template,"name":label(pair.template,side),"slot":"shoulder","side":side,"coverage":[],"contact_slots":["shoulder"],"layer":0,"grade":pair.grade,"variant":pair.variant,"material":E.TEMPLATES[pair.template].material,"locked":false,"maximum":maximum,"durability":maximum*[0.0,0.4,0.8,1.0][pair.grade],"source":pair.source,"crossed":pair.grade==3})
  g._equipment_feedback(pair.pieces.back(),pair.pieces.back().durability,true)
  g._emit("event",label(pair.template,side)+"已连到"+g._equipment_name(host)+"，紧度%d档。" % pair.grade,{"shoulder":{"host":host.id,"side":side,"installed":true}})
  g.Cards.restraint_changed(g,"worn")

static func refresh(g, host: Dictionary) -> void:
 update_cross(g,host)
 if g.tier(host.durability,host.maximum)!=3: return
 if eligible(host):
  if not host.has("shoulders"):
   host.shoulders={"template":host.template,"grade":host.grade,"variant":host.variant,"source":host.source,"pieces":[]}
  fill(g,host)

static func update_cross(g, e: Dictionary) -> void:
 if not E.is_shoulder(e) or e.durability<=0.000001: return
 var old=e.get("crossed",false)
 var tier=g.tier(e.durability,e.maximum)
 if tier==3: e.crossed=true
 elif tier==1: e.crossed=false
 if old!=e.crossed: g._emit("event",e.name+("已收成交叉型。" if e.crossed else "已松到一档，交叉固定解除。"),{"shoulder":{"target":e.id,"crossed":e.crossed}})

static func cleanup(g) -> void:
 for e in g.physical_pieces(): update_cross(g,e)
 for host in g.state.equipment:
  if not host.has("shoulders"): continue
  for e in host.shoulders.pieces.duplicate():
   if e.durability<=0.000001 or host.durability<=0.000001:
    host.shoulders.pieces.erase(e)
    g._emit("event",e.name+("随原拘束具一起解除。" if host.durability<=0.000001 else "已解除，另一侧独立保留。"),{"shoulder":{"host":host.id,"side":e.side,"removed":true}})

static func slip_reason(g, e: Dictionary) -> String:
 if E.is_shoulder(e) and e.get("crossed",false): return "交叉肩带无法滑脱，需先松到1档。"
 if attached(g,e).size()==2: return "两侧肩带仍固定着本体，无法滑脱；先解除至少一侧肩带。"
 return ""

static func factor(g, e: Dictionary) -> float:
 return 0.5 if attached(g,e).size()==1 else 1.0

static func text(g, e: Dictionary) -> String:
 if E.is_shoulder(e):
  return "独立耐久与紧度 · 无法挣扎\n"+("交叉型：需先松到一档，恢复滑脱。" if e.crossed else "非交叉固定：按自身条件滑脱。")
 var count=attached(g,e).size()
 if count==0: return ""
 return "肩带%d条：" % count+("本体无法滑脱。" if count==2 else "本体滑脱效果×0.5。")

static func crossed_issue(g, e: Dictionary) -> String:
 if not e.get("crossed") is bool: return "肩带缺少交叉状态，请重新开始旧版肩带练习。"
 var tier=g.tier(e.durability,e.maximum)
 if (tier==3 and not e.crossed) or (tier==1 and e.crossed): return "肩带紧度与交叉状态存在差异。"
 return ""

static func validate_host(g, host: Dictionary) -> String:
 if not host.has("shoulders"): return ""
 if not eligible(host): return "肩部链接的原装备有误。"
 var pair=host.shoulders
 if not g.Snapshot.fields(pair,"template:s grade:i variant:i source:s pieces:a"): return "肩部链接记录缺损。"
 if E.base_template(pair.template) not in BASES or pair.grade not in E.GRADES or pair.variant<0 or pair.variant>=E.MATERIALS[E.TEMPLATES[pair.template].material][pair.grade].size(): return "肩部链接基础类型或品质有误。"
 if pair.pieces.size()>2: return "每件原装备最多一对肩部拘束。"
 var sides=[]
 for e in pair.pieces:
  if not g.Snapshot.fields(e,g.Snapshot.PIECE+" shoulder_host:s side:s layer:i coverage:z contact_slots:z crossed:b"): return "左右肩部拘束记录缺损。"
  if e.side not in SIDES or e.side in sides: return "肩部拘束侧别重复或有误。"
  sides.append(e.side)
  if e.id!=host.id+"_shoulder_"+e.side or e.shoulder_host!=host.id or e.name!=label(pair.template,e.side) or e.slot!="shoulder" or e.layer!=0 or e.coverage!=[] or e.contact_slots!=["shoulder"]: return "肩部拘束连接或位置有误。"
  if e.has("root_id") or e.has("parent_id") or e.has("binding") or e.has("shoulders") or e.has("points"): return "肩部拘束仅可使用自身结构。"
  for field in ["template","grade","variant","source"]:
   if e[field]!=pair[field]: return "肩部拘束与该对配置存在差异。"
  if e.maximum!=E.maximum(pair.grade): return "肩部拘束耐久上限与品质存在差异。"
  var issue=E.physical_reason(e)
  if issue!="": return issue
  issue=crossed_issue(g,e)
  if issue!="": return issue
 return ""

static func validate(g) -> String:
 for host in g.state.equipment:
  var issue=validate_host(g,host)
  if issue!="": return issue
 for root in g.state.composites:
  for e in root.components:
   if e.template=="glove_strap":
    var issue=crossed_issue(g,e)
    if issue!="": return issue
 return ""
