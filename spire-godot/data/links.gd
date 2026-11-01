extends RefCounted

const E=preload("res://data/equipment.gd")
const Special=preload("res://data/special_equipment.gd")
# A physical crotch rope supplies one canonical contact, without ordinary limb occupancy.
const CROTCH_CONTACT="special_3_a"

static func wear_text(name: String="连接绳") -> String:
 return "她又将「%s」扣在两件拘束具之间，拉紧后才把余绳盘回腰侧。" % name

static func is_crotch_anchor(target: Dictionary) -> bool:
 return Special.is_special(target) and Special.TYPES.get(target.get("type",""),{}).get("family","")=="crotch_rope"

static func anchor_slots(target: Dictionary) -> Array:
 if target.get("template","")=="art_hogtie": return []
 if is_crotch_anchor(target): return [CROTCH_CONTACT]
 return [] if Special.is_special(target) else E.contact_slots(target)


static func point_slot(point: String) -> String:
 for slot in E.SEGMENTS:
  if point in E.SEGMENTS[slot]: return slot
 if point in ["palm_left","palm_right"]: return "palm"
 if point in ["fingers_left","fingers_right"]: return "fingers"
 return point

static func point_chains() -> Array:
 return [E.SEGMENTS.upper_arm+E.SEGMENTS.forearm+["wrist","palm_left","fingers_left"],E.SEGMENTS.upper_arm+E.SEGMENTS.forearm+["wrist","palm_right","fingers_right"],E.SEGMENTS.thigh+E.SEGMENTS.calf+["ankle","foot","toes"]]

static func anchor_points(target: Dictionary, slot: String) -> Array:
 if is_crotch_anchor(target): return [CROTCH_CONTACT] if slot==CROTCH_CONTACT else []
 if slot not in anchor_slots(target): return []
 return E.points(slot,target.get("side","")).filter(func(point):return point in E.physical_points(target))

static func adjacent(a: String, b: String) -> bool:
 if a==b: return false
 if a==CROTCH_CONTACT or b==CROTCH_CONTACT: return (b if a==CROTCH_CONTACT else a) in ["wrist","thigh_root"]
 var slot=point_slot(a)
 if slot==point_slot(b) and E.SEGMENTS.has(slot): return a in E.SEGMENTS[slot] and b in E.SEGMENTS[slot]
 for chain in point_chains():
  if a in chain and b in chain: return absi(chain.find(a)-chain.find(b))==1
 return false

# -1 means toward the upper body, +1 toward the lower body. Stored endpoint order
# and posture never participate. The crotch connector is below wrists, above thighs.
static func direction(a: String, b: String) -> int:
 if a==CROTCH_CONTACT: return -1 if b=="wrist" else 1
 if b==CROTCH_CONTACT: return 1 if a=="wrist" else -1
 for chain in point_chains():
  if a in chain and b in chain: return -1 if chain.find(b)<chain.find(a) else 1
 return 0

static func direction_limit(point: String, toward: int) -> int:
 var slot=point_slot(point)
 if not E.SEGMENTS.has(slot): return 1
 var index=E.SEGMENTS[slot].find(point)
 return maxi(1,index if toward<0 else E.SEGMENTS[slot].size()-index-1)

static func validate(link: Dictionary, equipment: Array, links: Array) -> String:
 if link.get("template","")!="link_rope": return "普通链接只使用链接绳模板。"
 var physical=E.physical_reason(link)
 if physical!="": return physical
 var ends=link.get("ends",[])
 if ends.size()!=2 or ends[0]==ends[1]: return "链接绳需要连接两件各异装备。"
 var targets=equipment.filter(func(e):return e.id in ends and e.durability>0)
 if targets.size()!=2: return "链接绳连接的装备已经缺失。"
 var slots=link.get("slots",[])
 var points=link.get("contact_points",[])
 if slots.size()!=2 or points.size()!=2 or not adjacent(points[0],points[1]): return "链接绳须连接同一区域的各异子部位，或相邻区域的边界位置；股绳可连接手腕或大腿根。"
 for i in range(2):
  var target=targets.filter(func(e):return e.id==ends[i])[0]
  if points[i] not in anchor_points(target,slots[i]): return "所选装备在该具体连接位置没有真实固定处。"
 if link.get("slot","") not in slots or link.get("slot","")==CROTCH_CONTACT: return "链接绳的显示部位与连接位置存在差异。"
 if targets[0].get("root_id",targets[0].id)==targets[1].get("root_id",targets[1].id): return "同一复合装备内部的连接须使用其自身组件。"
 for blocked in link.get("blocked_slip",[]):
  if blocked not in ends: return "链接绳只能限制所连接装备的滑脱。"
 for other in links:
  if other.id==link.id: continue
  if other.ends.has(ends[0]) and other.ends.has(ends[1]): return "这两件装备之间已经有一条链接绳。"
 for i in range(2):
  var toward=direction(points[i],points[1-i])
  var count=1
  var limit=direction_limit(points[i],toward)
  for other in links:
   if other.id==link.id or other.durability<=0 or ends[i] not in other.ends: continue
   var at=other.ends.find(ends[i])
   if direction(other.contact_points[at],other.contact_points[1-at])==toward:
    count+=1
    limit=mini(limit,direction_limit(other.contact_points[at],toward))
  if count>limit: return "这件装备向%s最多连接%d条链接绳，已经达到上限。" % ["上" if toward<0 else "下",limit]
 return ""

const LOWER_ONLY_SLIP_FACTOR=1.25

# Direction follows the limb chain, never posture, screen position, or endpoint array order.
static func slip_factor(g, target: Dictionary) -> float:
 if target.has("root_id") or target.has("parent_id") or target.template=="link_rope" or E.is_shoulder(target) or Special.is_special(target): return 1.0
 var downward=false
 for link in g.state.links:
  if link.durability<=0 or target.id not in link.ends: continue
  var index=link.ends.find(target.id)
  var other=g._equipment(link.ends[1-index])
  if other.is_empty() or other.durability<=0: continue
  if direction(link.contact_points[index],link.contact_points[1-index])<0: return 1.0
  downward=true
 return LOWER_ONLY_SLIP_FACTOR if downward else 1.0
