extends RefCounted

# One authored table for active slip multipliers and post-movement passive bases.
# No preview calls may select targets or advance the motion random domain.
const FACTORS={
 "shoulder":[1.20,1.20,1.20],
 "thigh_root":[1.50,1.20,1.20],"mid_thigh":[1.30,1.10,1.10],
 "above_knee":[1.20,1.05,1.05],"below_knee":[1.30,1.10,1.10],
 "mid_calf":[1.20,1.05,1.05],"foot":[1.0,1.20,1.20],"toes":[1.0,1.20,1.20]}
const POSES=["stand","sit","lie"]

static func factor(point: String, posture: String) -> float:
 return FACTORS[point][POSES.find(posture)] if FACTORS.has(point) else 1.0

static func profile(g, target: Dictionary) -> Dictionary:
 var result={"point":"","factor":1.0}
 for point in g.Equipment.slip_points(target):
  if FACTORS.has(point) and (result.point=="" or factor(point,g.state.posture)>result.factor):
   result={"point":point,"factor":factor(point,g.state.posture)}
 return result

static func hint() -> String:
 return "行动完成后，各适用部位免费随机滑脱一件最外层装备；同一件只处理一次。"

# Called only inside the owning action transaction, before entering a new room.
static func apply(g, trigger: String) -> void:
 var chosen={}
 var pieces=g.physical_pieces().filter(func(e):return e.durability>0 and g.Equipment.allows(e,"strain") and g._outer(e))
 pieces.sort_custom(func(a,b):return a.id<b.id)
 for point in FACTORS:
  var eligible=pieces.filter(func(e):return point in g.Equipment.slip_points(e))
  if eligible.is_empty(): continue
  var target=eligible[g._random_index("motion",eligible.size())]
  var value=factor(point,g.state.posture)
  if not chosen.has(target.id): chosen[target.id]={"point":point,"factor":value,"points":[point]}
  else:
   chosen[target.id].points.append(point)
   if value>chosen[target.id].factor:
    chosen[target.id].point=point;chosen[target.id].factor=value
 var results=[];var changed=[]
 for id in chosen:
  var target=g._equipment(id)
  if target.is_empty() or target.durability<=0: continue
  var selection=chosen[id]
  var preview=g.escape_preview(target,"slip",selection.factor,[],true)
  var old=target.durability
  g._apply_equipment_damage(target,preview.damage,"passive_slip")
  var reason=preview.reason
  if reason=="" and preview.immune: reason="三档紧度阻止普通滑脱。"
  var result={"target":id,"name":target.name,"slot":target.slot,"position":g.Equipment.point_name(selection.point),"point":selection.point,"points":selection.points,"coefficient":selection.factor,"before":old,"after":target.durability,"damage":old-target.durability,"reason":reason,"formula":g._formula(preview),"preview":preview}
  results.append(result)
  if result.damage>0: changed.append(target.name+"耐久－"+g.ActionCopy.number(result.damage))
  # Clean removed roots/references, but do not select newly exposed inner pieces.
  g._cleanup()
 if results.is_empty(): return
 var text=("探索" if trigger=="explore" else "移动")+"时，"
 text+=("、".join(changed)+"。") if not changed.is_empty() else "身上的装备没有松动。"
 var details=[]
 for r in results:
  details.append(r.name+" · "+g.Equipment.point_name(r.point)+"："+r.formula+"；耐久 "+g.number(r.before)+" → "+g.number(r.after)+("；"+r.reason if r.reason!="" else ""))
 g._emit("mechanical",text+"\n"+"\n".join(details),{"passive_slip":{"trigger":trigger,"posture":g.state.posture,"summary":text,"results":results}})
