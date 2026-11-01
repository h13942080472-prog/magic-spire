extends "res://data/field_tools.gd"

# State-dependent tool queries. Inherit the single registry, without copies or forwarding methods.
const Contact=preload("res://core/contact.gd")

static func description(g, type: String) -> String:
 if operation(type)=="buff": return g.Consumables.description(g,type)
 return effect_description(type,TYPES[type].damage*g.Cards.damage_multiplier(g,"equipment"),assisted(g))

static func assisted(g) -> bool:
 return g.relic_value("unrestricted_items")>0

static func is_fixed(g, item: Dictionary) -> bool:
 return item.mount!="carry" or (assisted(g) and not TYPES[item.type].get("trigger_damage_types",[]).is_empty())

static func mount_name(g, item: Dictionary) -> String:
 return "触手固定" if item.mount=="carry" and is_fixed(g,item) else mount_label(item.mount)

static func target_contact(g, target: Dictionary, operation_id: String) -> Dictionary:
 if assisted(g):
  return Contact.evaluate(g,target,{"points":reach(g,{"mount":"carry"})})
 return {"reason":Contact.reason(g,target,operation_id),"slots":Contact.usable_slots(g,target,operation_id)}

static func escape_reason(g) -> String:
 if g.state.phase!="prison" or g.state.security>=5: return "传送符仅限一至四级牢房的可行动回合使用。"
 var scroll_reason=g.Consumables.scroll_reason(g)
 if scroll_reason!="": return scroll_reason
 if g.carried_items()-1>g.item_capacity(): return "用掉传送符后，剩余道具仍超出容量；请先使用或放弃多出的道具。"
 return ""

static func unlock_reason(g, target: Dictionary={}) -> String:
 if g.cursed_plate(target): return g.SpecialEquipment.CURSED_PLATE_REASON
 if not assisted(g) and (g.occupied("fingers") or g.occupied("wrist")): return "开锁针需要手腕和手指自由，才能稳定握持并拨动锁芯。"
 if target.is_empty():
  return "拨动牢门锁芯需要站姿或坐姿。" if g.state.posture=="lie" and not assisted(g) else ""
 if not target.locked: return "这件装备没有锁。"
 return target_contact(g,target,"unlock").reason

static func part_names(g, points: Array) -> String:
 var names=[]
 for slot in ["eyes","mouth","neck","shoulder"]+g.B.ARM_SLOTS+g.B.LEG_SLOTS:
  var all_points=Contact.E.points(slot)
  var matching=all_points.filter(func(point):return point in points)
  if matching.is_empty(): continue
  if matching.size()==all_points.size(): names.append(g.B.SLOT_NAMES[slot])
  else:
   for point in matching: names.append(Contact.E.POINT_NAMES.get(point,g.B.SLOT_NAMES[slot]))
 for region in g.SpecialEquipment.REGIONS:
  if region.slots.any(func(point):return point in points): names.append(region.name)
 return "、".join(names)

static func contact_text(g, mount: String, cutting: bool=true) -> String:
 if assisted(g) and cutting: return "可接触部位：全身。"
 var parts=part_names(g,reach(g,{"mount":mount}) if cutting else height_points(g,mount))
 return "当前姿势没有部位能接触这里。" if parts=="" else "可接触部位："+parts+"。"

static func target_parts(g, target: Dictionary) -> String:
 if g.SpecialEquipment.is_special(target): return g.SpecialEquipment.location_name(target)
 var points=[]
 for contact in Contact.target_contacts(g,target): points.append_array([contact.point] if contact.has("point") else Contact.contacts(contact.target,contact.slot))
 return part_names(g,points)

static func contact_reason(g, target: Dictionary, item: Dictionary) -> String:
 if item.mount=="carry" or assisted(g): return target_contact(g,target,"cut").reason
 var result=Contact.evaluate(g,target,{"points":reach(g,item)})
 if result.code=="out_of_reach": return "当前姿势下，"+target_parts(g,target)+"请调整姿势，使目标触及工具。"
 return result.reason

static func reach(g, item: Dictionary) -> Array:
 if assisted(g):
  var points=Contact.E.ANATOMY.duplicate();points.append_array(g.SpecialEquipment.slots());return points
 return height_points(g,item.mount).filter(func(point):return point not in ["eyes","mouth","neck"])

static func height_points(g, mount_id: String) -> Array:
 var result=POINT_HEIGHTS[g.state.posture].get(mount_id,[]).duplicate()
 if mount_id=={"stand":"high_wall","sit":"hand_wall","lie":"foot_wall"}[g.state.posture]: result.append_array(["eyes","mouth","neck"])
 var pose=g.state.posture
 for index in range(3):
  var mount=("high_wall" if index==0 else "hand_wall") if pose=="stand" else ("hand_wall" if pose=="sit" and index==0 else "foot_wall")
  if mount_id==mount: result.append_array(g.SpecialEquipment.REGIONS[index].slots)
 return result

static func operator_profile(g, mount: String, type: String) -> Dictionary:
 var result=[];var issues=[]
 if not HEIGHTS.has(mount): return {"operators":[],"reason":"这里没有对应的工具安装位置。"}
 if assisted(g): return {"operators":["helper"],"reason":""}
 var pose=g.state.posture
 var ranges=OPERATOR_HEIGHTS[pose]
 # Bound arms can still pinch nearby; they cannot raise the hands into the upper band.
 if mount in ranges.hand:
  if g.occupied("fingers"): issues.append("夹取工具需要手指自由")
  elif g.level("arms")!=0 and mount!=("hand_wall" if pose=="stand" else "foot_wall"): issues.append("需要双臂能触及目标")
  else: result.append("hand")
 if mount in ranges.foot:
  if g.occupied("toes"): issues.append("夹取工具需要脚趾自由")
  elif g.level("legs")>2: issues.append("脚趾送取工具需要腿部束缚≤2级")
  else: result.append("foot")
 if mount in ranges.mouth and TYPES.get(type,{}).get("mouth_install",false):
  if g.occupied("mouth"): issues.append("嘴部被占用")
  else: result.append("mouth")
 var reason=""
 if result.is_empty(): reason="请调整姿势以触及目标"+mount_label(mount)+"。" if issues.is_empty() else "；".join(issues)+"。"
 return {"operators":result,"reason":reason}

static func install_operators(g, mount: String, type: String) -> Array:
 return operator_profile(g,mount,type).operators

static func operator_reason(g, mount: String, type: String) -> String:
 return operator_profile(g,mount,type).reason

static func same_installation_point(g, item: Dictionary, mount: String) -> bool:
 if item.mount!=mount: return false
 if g.state.prison.get("active",false): return item.get("prison_position",[])==g.Prison.Space.attachment_position(g)
 return true

static func install_reason(g, mount: String, type: String) -> String:
 if not HEIGHTS.has(mount): return "这里没有对应的工具安装位置。"
 if g.state.wall=="none": return "当前房间没有可安装工具的墙缝。"
 if not g.wall_contact(): return "需要先靠到墙边，才能安装工具。"
 var issue=operator_reason(g,mount,type)
 if issue!="": return issue
 if g.state.items.any(func(i):return same_installation_point(g,i,mount)): return "这条墙缝已经装有工具。"
 return ""

static func retrieve_reason(g, item: Dictionary) -> String:
 if assisted(g): return ""
 var issue=g.Prison.Space.mounted_reason(g,item)
 if issue!="": return issue
 if not g.wall_contact(): return "需要先靠到墙边，才能取回工具。"
 return operator_reason(g,item.mount,item.type)

static func installation_points(g) -> Array:
 var points=[]
 if not g.wall_contact(): return points
 for mount in HEIGHTS:
  var occupants=g.state.items.filter(func(i):return same_installation_point(g,i,mount))
  points.append({"mount":mount,"short_label":mount_label(mount),"occupant":"" if occupants.is_empty() else TYPES[occupants[0].type].name})
 return points
