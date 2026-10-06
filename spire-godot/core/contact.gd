extends RefCounted

# Shared read-only geometry; precise workspaces remain operation-specific.
const E=preload("res://data/equipment.gd")
const Special=preload("res://data/special_equipment.gd")
const SIDES=["left","right"]

static func profile(g, side: String, operation: String="assist") -> Dictionary:
 var reason=""
 var code=""
 if operation=="assist" and g.hand_blocked("fingers",side):
  reason="手指受限，不能提供手部辅助。";code="fingers_blocked"
 elif operation!="cut" and g.hand_blocked("wrist",side):
  reason="手腕受限，不能辅助拉扯。";code="wrist_blocked"
 elif operation!="assist" and g.hand_blocked("palm",side):
  reason="手掌无法握持，不能执行这项操作。";code="grip_blocked"
 if reason!="": return {"side":side,"points":[],"reason":reason,"code":code,"assist_factor":0.0}
 if operation!="assist":
  return {"side":side,"points":workspace(g,operation),"reason":"","code":""}
 var assist_factor=0.5 if g.hand_blocked("palm",side) else 1.0
 var points=[]
 if not g.CaptureBind.has_bind(g) and not g.B.ARM_SLOTS.any(func(slot):return g.jointly_bound(slot)):
  points=E.ANATOMY.duplicate();points.append_array(Special.slots())
 else:
  var slots=limited_slots(g)
  for slot in slots: points.append_array(E.points(slot))
  if "thigh" in slots: points.append_array(Special.REGIONS[2].slots)
  # This explicit reach exception applies in every posture, after ordinary torso limits.
  if not g.hand_blocked("wrist",side):
   points.append("above_elbow")
   for slot in Special.slots():
    if slot not in points: points.append(slot)
 return {"side":side,"points":g.Binding.filter_points(g,points),"reason":"","code":"","assist_factor":assist_factor}

static func profiles(g, operation: String="assist") -> Array:
 return SIDES.map(func(side):return profile(g,side,operation))

static func contacts(target: Dictionary, slot: String) -> Array:
 # A shoulder strap is contacted at the shoulder, not at every upper-arm sub-position.
 if E.is_shoulder(target): return ["shoulder"]
 var actual=E.physical_points(target)
 var points=E.points(slot,target.get("side",""))
 return points.filter(func(point):return actual.is_empty() or point in actual)

static func limited_slots(g) -> Array:
 return ["thigh"] if g.state.posture=="stand" else ["thigh","ankle","foot","toes"]

static func workspace(g, operation: String) -> Array:
 # docs/spec/equipment-query-seam.md「作用域进出点（冻结名单）」: one read scope for the whole workspace table.
 var previous=g._begin_equipment_read()
 var slots=[]
 var stand=g.state.posture=="stand"
 if operation=="cut":
  if g.occupied("forearm"): slots=["thigh"] if stand else ["foot","toes"]
  elif g.occupied("upper_arm"): slots=["thigh"] if stand else ["thigh","ankle","foot","toes"]
  else: slots=["upper_arm","forearm","thigh"] if stand else ["upper_arm","forearm"]+g.B.LEG_SLOTS
  if not g.occupied("wrist") and g.physical_pieces().any(func(e):return e.template=="hand_wrap"): slots.append_array(["palm","fingers"])
 else:
  slots=(g.B.SLOTS+["neck"]).filter(func(slot):return not stand or slot not in ["calf","ankle","foot","toes"])
  if operation=="manual" and g.level("arms")!=0: slots=limited_slots(g)
 var points=g.Binding.filter_points(g,slot_points(slots))
 g._equipment_read=previous
 return points

static func slot_points(slots: Array) -> Array:
 var points=[]
 for slot in slots:
  points.append_array(E.points(slot))
  if slot=="upper_arm": points.append("shoulder")
  if slot=="thigh": points.append_array(Special.REGIONS[2].slots)
 return points

static func target_contacts(g, target: Dictionary) -> Array:
 var result=[]
 if target.template=="link_rope":
  for i in range(2):
   var end=g._equipment(target.ends[i])
   if not end.is_empty(): result.append({"target":end,"slot":target.slots[i],"point":target.contact_points[i]})
 else:
  for slot in E.contact_slots(target): result.append({"target":target,"slot":slot})
 return result

static func evaluate(g, target: Dictionary, reach: Dictionary) -> Dictionary:
 if reach.get("reason","")!="": return {"code":reach.code,"reason":reach.reason,"slots":[]}
 var reachable=false
 var self_only=false
 var slots=[]
 for contact in target_contacts(g,target):
  if reach.get("side","")!="" and contact.slot in ["palm","fingers"] and contact.target.get("side","") in ["",reach.side]:
   self_only=true;continue
  var points=[contact.point] if contact.has("point") else contacts(contact.target,contact.slot)
  if not points.any(func(point):return point in reach.points): continue
  reachable=true
  if g._outer_at(contact.target,contact.slot,contact.get("point","")) and contact.slot not in slots: slots.append(contact.slot)
 if not slots.is_empty(): return {"code":"","reason":"","slots":slots}
 if reachable: return {"code":"covered","reason":"外层仍覆盖目标，只能接触外露的部分。","slots":[]}
 if self_only: return {"code":"same_hand","reason":"这只手不能拉扯自身的手部拘束。","slots":[]}
 return {"code":"out_of_reach","reason":"当前姿态和手臂固定方式够不到目标位置。","slots":[]}

static func reason(g, target: Dictionary, operation: String) -> String:
 var issues=[]
 for reach in profiles(g,operation):
  if g.hand_blocked("fingers",reach.side): continue
  var result=evaluate(g,target,reach)
  if result.code=="": return ""
  issues.append(result.reason)
 return issues[0] if not issues.is_empty() else "手指受限，无法精细操作。"

# Legal direct-use positions; linked targets resolve their actual endpoints.
static func usable_slots(g, target: Dictionary, operation: String) -> Array:
 var result=[]
 for reach in profiles(g,operation):
  if reach.reason!="" or g.hand_blocked("fingers",reach.side): continue
  for slot in evaluate(g,target,reach).slots:
   if slot not in result: result.append(slot)
 return result
