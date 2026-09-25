extends RefCounted

const FACTOR=0.5

static func slot_points(g, slot: String) -> Array:
 return ["shoulder_left","shoulder_right"] if slot=="shoulder" else g.Equipment.points(slot)

static func physical_points(g, target: Dictionary) -> Array:
 if g.SpecialEquipment.is_special(target): return g.SpecialEquipment.occupied_slots(target)
 if g.Equipment.is_shoulder(target): return ["shoulder_"+target.get("side",target.get("part",""))]
 return g.Equipment.physical_points(target)

# Read-only groups; only execution resolves tied targets using card_target RNG.
static func options(g, p: Dictionary) -> Array:
 if p.mode not in ["strain","slip","magic_slip"] or not p.has("preview"): return []
 var source=g._equipment(p.target)
 if source.is_empty(): return []
 var source_points=physical_points(g,source).filter(func(point):return point in slot_points(g,p.slot))
 if source_points.is_empty(): return []
 var groups=[]
 var points=source_points.duplicate()
 if p.mode!="strain":
  points=[]
  var slots=[p.slot]
  for group in g.Equipment.panel_groups():
   if p.slot in group.slots: slots=group.slots;break
  for slot in slots:
   for point in slot_points(g,slot):
    if point not in source_points and point not in points: points.append(point)
 var targets=g.action_targets()
 for point in points:
  var pool=[]
  var lowest=INF
  for target in targets:
   if target.id==p.target or target.durability<=0: continue
   var covered=physical_points(g,target)
   if point not in covered: continue
   var preview=g.escape_preview(target,p.mode,p.preview.face_value*FACTOR,[],false,false,p.mode=="strain",true,p.preview.get("ignore_tightness_reduction",false))
   g.Cards.scale_card_preview(g,preview,p.mode)
   if preview.reason!="" or preview.immune or preview.damage<=0: continue
   if p.mode!="strain":
    var tightness=g._effective_ratio(target)
    if tightness>lowest+0.000001: continue
    if tightness<lowest-0.000001: pool.clear();lowest=tightness
   pool.append({"target":target.id,"name":g._equipment_name(target),"point":point,"preview":preview})
  if not pool.is_empty(): groups.append(pool)
 return groups

static func select(g, p: Dictionary) -> Array:
 var selected=[];var seen=[p.target]
 for pool in options(g,p):
  var choices=pool if p.mode=="strain" else [pool[g._random_index("card_target",pool.size())] if pool.size()>1 else pool[0]]
  for choice in choices:
   if choice.target in seen: continue
   seen.append(choice.target);selected.append(choice)
 return selected

static func apply(g, p: Dictionary, selected: Array) -> void:
 for choice in selected:
  var target=g._equipment(choice.target)
  if target.is_empty() or target.durability<=0: continue
  var before=target.durability;var tier=g.tier(before,target.maximum)
  var kind=g.Cards.Rules.damage_type(p.type,p.get("free",false))
  g._apply_equipment_damage(target,choice.preview.damage,kind,false,false)
  if kind=="slip": g.RelicEffects.card_slipped(g,tier,target)
  var record=choice.preview.duplicate(true)
  record.card_splash={"source":p.target,"target":target.id,"point":choice.point,"base":p.preview.face_value,"factor":FACTOR,"before":before,"after":target.durability}
  record.action_result=g.ActionCopy.equipment_result("波及",target.name,before,target.durability,kind)
  g._emit("mechanical","「%s」波及%s：%s。耐久%s→%s。" % [g.B.CARD_NAMES[p.type],target.name,g._formula(choice.preview),g.number(before),g.number(target.durability)],record)

static func detail(g, p: Dictionary) -> String:
 var groups=options(g,p)
 if groups.is_empty(): return ""
 var parts=[];var seen=[]
 for pool in groups:
  if p.mode=="strain":
   pool=pool.filter(func(c):return c.target not in seen)
   for choice in pool: seen.append(choice.target)
  if pool.is_empty(): continue
  var entries=pool.map(func(c):return c.name+" "+g.number(c.preview.damage)+"伤害")
  parts.append(g.Equipment.point_name(pool[0].point)+"："+("随机1件（"+"／".join(entries)+"）" if p.mode!="strain" and pool.size()>1 else "、".join(entries)))
 return "\n波及："+"；".join(parts)+"。"
