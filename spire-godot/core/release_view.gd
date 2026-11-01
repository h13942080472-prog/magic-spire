extends RefCounted

# Read-only presentation of existing physical layers and action previews.
const REGIONS=[
 {"id":"region_head","name":"头颈","members":["eyes","mouth","neck"]},
 {"id":"region_upper","name":"手胸","members":["upper_arm","forearm","wrist","hands"]},
 {"id":"region_lower","name":"臀腿","members":["thigh","calf","ankle","feet"]},
 {"id":"region_intimate","name":"性器","members":["special_1","special_2","special_3"]}]

static func regions(g, bodies: Array) -> Array:
 var result=[]
 for definition in REGIONS:
  var region=definition.duplicate(true)
  region.severity={}
  if definition.id in ["region_upper","region_lower"]:
   var upper=definition.id=="region_upper"
   region.severity={"label":"上身拘束严密度" if upper else "腿部拘束严密度","value":g.restraint_degree("arms" if upper else "legs"),"maximum":4.0}
  region.slots=[];region.targets={};region.sections=[];region.equipment=[];region.links=[]
  region.members=bodies.filter(func(body):return body.id in definition.members)
  var roots={}
  for body in region.members:
   region.slots.append_array(body.slots);region.targets.merge(body.targets)
   region.sections.append_array(body.sections);region.links.append_array(body.links)
   for e in body.equipment: roots[e.root_id if e.root_id!="" else e.id]=true
  region.equipment=region.targets.values();region.count=roots.size();region.occupied=region.count>0
  region.can_release=region.members.any(func(body):return body.can_release)
  result.append(region)
 return result

static func layers(g, e: Dictionary) -> Dictionary:
 var covers={}
 if not g.SpecialEquipment.is_special(e) and e.template!="link_rope":
  for slot in g.Equipment.contact_slots(e):
   var cover=g._outer_cover_at(e,slot)
   if not cover.is_empty(): covers[cover.id]=g._equipment_name(cover)
 var label="连接" if e.template=="link_rope" or e.has("parent_id") else ("附属" if e.get("part","") not in ["","body"] or e.has("shoulder_host") else ("内层" if not covers.is_empty() else "外层"))
 if g.SpecialEquipment.is_special(e): label="附属" if g.SpecialEquipment.is_reinforcement(e) else "主体"
 return {"is_special":g.SpecialEquipment.is_special(e),"layer":e.get("layer",0),"covers":covers.values(),"layer_label":label}

static func preview(g, c: Dictionary) -> Dictionary:
 var p=c.payload
 var target=g._equipment(p.get("target",""))
 if target.is_empty(): return {}
 var result={"valid":c.valid,"reason":c.reason,"headline":"","change":"","note":"","method":{"strain":"挣扎","slip":"滑脱","magic_slip":"魔法滑脱","lower":"降低紧度"}.get(p.get("mode",""),""),"modifiers":[],"before":target.durability,"after":target.durability}
 if not c.valid: return result
 if p.get("mode","")=="unlock" or p.get("op","")=="unlock" or (p.kind=="item_use" and g.Tools.operation(g._item(p.item).get("type",""))=="unlock"):
  if g.Equipment.is_shackle(target):
   result.headline="开锁 → 整件取下";result.after=0.0
   return result
  result.headline="已上锁 → 已开锁"
  result.note="开锁后，双臂自由时可取下。" if g.Equipment.lock_only(target) else "耐久与紧度保留。"
  return result
 if g.Equipment.lock_only(target):
  if p.kind=="manual": result.headline="整件取下"
  return result
 var damage=0.0
 if p.has("preview"):
  var source=p.preview
  damage=source.damage+p.get("tool_bonus",{}).get("damage",0.0)
  if source.get("immune",false): result.modifiers.append("三档紧度 · 普通滑脱无效")
  for factor in [{"key":"lock_multiplier","label":"锁具"},{"key":"penalty","label":"目标限制"},{"key":"multiplier","label":"紧度"}]:
   var value=source.get(factor.key,1.0)
   if value<1.0: result.modifiers.append(factor.label+" ×"+g.number(value))
  if source.get("divisor",1.0)>1.0: result.modifiers.append("堆叠 ×"+g.number(1.0/source.divisor))
  if source.get("position",{}).get("factor",1.0)<1.0: result.modifiers.append("部位 ×"+g.number(source.position.factor))
  if source.get("release",false):
   var root=g._strain_release_root(target)
   if not root.is_empty():
    if g._composite_body(root).id==target.id: damage=target.durability
    result.note="同时取下"+root.name+"。"
  if damage>0 and g.SpecialEquipment.unlocked_release(target,p.get("mode","")): damage=target.durability
 elif p.has("after"):
  damage=target.durability-p.after
 elif p.has("damage"):
  damage=p.damage
 else: return {}
 result.after=maxf(0,target.durability-damage)
 result.headline="耐久 %s → %s" % [g.number(result.before),g.number(result.after)]
 result.change="−"+g.number(result.before-result.after)
 if result.after==0:
  if result.note=="": result.note="解除连接" if target.template=="link_rope" or target.has("parent_id") else ("解除该部件" if target.get("root_id","")!="" and target.get("part","")!="body" else "整件取下")
 elif not target.has("parent_id") and not g.Equipment.is_shackle(target):
  var before_tier=g.tier(result.before,target.maximum);var after_tier=g.tier(result.after,target.maximum)
  if before_tier!=after_tier: result.note=(result.note+" · " if result.note!="" else "")+"紧度 %d档 → %d档" % [before_tier,after_tier]
 if c.mana>0: result.note=(result.note+" · " if result.note!="" else "")+"施法成功时"
 return result
