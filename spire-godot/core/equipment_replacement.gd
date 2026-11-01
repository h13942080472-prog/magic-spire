extends RefCounted

# Game-internal, synchronous atomic group. The caller owns permission, costs,
# ready-stack consumption, action feedback and the enclosing version increment.
# Never persist a plan or expose its snapshots as a player command.
static func plan(g, requests: Array, source: String, protected_ids: Array=[]) -> Dictionary:
 var original=g.state
 var art_trial=g._rope_trial;g._rope_trial=true
 var feedback=g._resource_feedback
 g._resource_feedback=null
 g.state=original.duplicate(true)
 var result=_plan(g,requests,source,protected_ids)
 # Factories can displace equipment without explicit removal units in a direct plan.
 if result.ok and (result.removed+result.lost_links).any(func(id):return id in protected_ids):
  result=_fail("刚安装的装备与附属件在本批次保留。")
 g.state=original
 g._rope_trial=art_trial
 g._resource_feedback=feedback
 result.expectedVersion=original.version
 if result.ok:
  result.requests=result.requests.duplicate(true)
  result.source=source
  result.protected_ids=protected_ids.duplicate()
  result._before=original.duplicate(true)
 return result

static func execute(g, prepared: Dictionary) -> Dictionary:
 if not prepared.get("ok",false): return _fail(prepared.get("reason","替换方案没有通过检查。"))
 if prepared.get("expectedVersion",-1)!=g.state.version or prepared.get("_before",{})!=g.state:
  return _fail("装备或行动状态已更新，需要重新检查替换方案。")
 if not prepared.get("requests") is Array or not prepared.get("source") is String:
  return _fail("替换方案缺少安装规格或来源。")
 # Recompute rather than trusting a mutable preview or a caller-supplied state.
 var fresh=plan(g,prepared.requests,prepared.source,prepared.get("protected_ids",[]))
 if not fresh.ok: return _fail(fresh.reason)
 for key in ["_after","removed","installed","lost_links","comparisons"]:
  if fresh.get(key)!=prepared.get(key): return _fail("替换方案的预演结果已改变，需要重新检查。")
 _commit_changes(g,fresh._after)
 g.RopeArt.replaced(g,fresh)
 return {"ok":true,"reason":"","removed":fresh.removed.duplicate(),"installed":fresh.installed.duplicate(true),"lost_links":fresh.lost_links.duplicate(),"comparisons":fresh.comparisons.duplicate(true)}

# Some captures explicitly replace every removable special item covered by one
# prescribed device. This remains a replacement transaction: cursed items are
# an absolute boundary, cleanup owns dependent pieces and links, and the normal
# special factory owns the incoming item.
static func force_special(g, type: String, tier: int, source: String) -> Dictionary:
 if not g.SpecialEquipment.DESIGNS.has(type) or tier not in [1,2,3]: return _fail("指定的特殊装备有误。")
 var original=g.state
 var art_trial=g._rope_trial;g._rope_trial=true
 var feedback=g._resource_feedback
 g._resource_feedback=null
 g.state=original.duplicate(true)
 var result=_force_special_live(g,type,tier,source)
 var after=g.state.duplicate(true) if result.ok else {}
 g.state=original
 g._rope_trial=art_trial
 g._resource_feedback=feedback
 if not result.ok: return result
 _commit_changes(g,after)
 g.RopeArt.replaced(g,result)
 return result

# Both replacement policies commit only changed fields. Keep unchanged enclosing
# enemy/event references alive and never expose trial containers as authority.
static func _commit_changes(g, after: Dictionary) -> void:
 for key in after:
  if g.state.get(key)!=after[key]:
   var value=after[key]
   g.state[key]=value.duplicate(true) if value is Array or value is Dictionary else value

static func _force_special_live(g, type: String, tier: int, source: String) -> Dictionary:
 var coverage=g.SpecialEquipment.DESIGNS[type].slots
 var blocking=g.state.special_equipment.filter(func(item):return not g.SpecialEquipment.is_reinforcement(item) and g.SpecialEquipment.occupied_slots(item).any(func(slot):return slot in coverage))
 if blocking.any(g.SpecialEquipment.is_cursed_plate): return _fail(g.SpecialEquipment.CURSED_PLATE_REASON)
 var old_targets=g.action_targets().duplicate(true)
 for item in blocking:
  item.durability=0.0
 if not blocking.is_empty(): g._cleanup(false)
 var installed=g._install_special(type,coverage[0],tier)
 if installed.is_empty(): return _fail("清理可替换装备后仍无法佩戴指定装备。")
 if g.SpecialEquipment.validate(g.state.special_equipment)!="" or g._capacity_issue(g.physical_pieces())!="": return _fail("替换后的特殊装备结构有误。")
 var live=g.action_targets().map(func(item):return item.id)
 var removed=old_targets.filter(func(item):return item.id not in live and item.template!="link_rope").map(func(item):return item.id)
 var lost_links=old_targets.filter(func(item):return item.id not in live and item.template=="link_rope").map(func(item):return item.id)
 return {"ok":true,"reason":"","removed":removed,"installed":[installed],"lost_links":lost_links,"comparisons":[]}

static func _fail(reason: String) -> Dictionary:
 return {"ok":false,"reason":reason,"removed":[],"installed":[],"lost_links":[],"comparisons":[]}

static func _normalize(g, requests: Array) -> Dictionary:
 if requests.is_empty(): return _fail("本次没有指定要安装的装备。")
 var normalized=[]
 for input in requests:
  if not input is Dictionary: return _fail("每件装备都需要具体安装规格。")
  var r=input.duplicate(true)
  if r.get("kind","") not in ["install","assembly","special_install"]: return _fail("本次操作需要装备安装指令。")
  for key in ["grade","tier","layer"]:
   if r.has(key) and not r[key] is int: return _fail("品质、紧度和层级必须使用整数。")
  if r.has("locked") and not r.locked is bool: return _fail("上锁要求必须明确为是或否。")
  for key in ["template","slot","point","family","type","straps","attached_to"]:
   if r.has(key) and not r[key] is String: return _fail("安装类型和具体位置必须使用名称。")
  if r.kind=="install":
   r.grade=r.get("grade",1);r.tier=r.get("tier",2);r.locked=r.get("locked",false);r.variant=r.get("variant",0)
   if not r.variant is int or r.variant<0: return _fail("装备材质版本有误。")
   var placement=g._prepare_installation(r.get("template",""),r.get("slot",""),r.grade,r.locked,r.get("point",""),r.get("layer",-1))
   if placement.reason!="" and not placement.get("capacity_full",false): return _fail(placement.reason)
   if r.tier not in [1,2,3]: return _fail("安装紧度必须为一至三档。")
   if r.variant>=g.Equipment.MATERIALS[g.Equipment.TEMPLATES[r.template].material][r.grade].size(): return _fail("装备材质版本有误。")
   var points=placement.points
   r.point=points[0] if g.Equipment.SEGMENTS.has(r.slot) else r.slot
  elif r.kind=="assembly":
   r.family=r.get("family","");r.variant=r.get("variant","");r.straps=r.get("straps","straight")
   if not r.variant is String: return _fail("复合装备需要明确款式。")
   r.grade=r.get("grade",2);r.tier=r.get("tier",2);r.parts=r.get("parts",{}).duplicate(true) if r.get("parts",{}) is Dictionary else null
   if r.parts==null: return _fail("复合组件规格必须按组件列出。")
   var layout=g.Composites.spec(r.family,r.variant,r.straps)
   if layout.is_empty(): return _fail("复合装备款式待定义。")
   var issue=g._assembly_reason(layout,r.get("attached_to",""))
   if issue!="": return _fail(issue)
   if r.grade not in g.Equipment.GRADES or r.grade<layout.minimum or r.tier not in [1,2,3]: return _fail("请使用符合安装要求的品质与紧度。")
   for key in r.parts:
    if key not in layout.parts or not r.parts[key] is Dictionary: return _fail("组件规格需归属于当前装备。")
    if r.parts[key].has("tier") and (not r.parts[key].tier is int or r.parts[key].tier not in [1,2,3]): return _fail("组件紧度必须为一至三档。")
    if r.parts[key].has("locked") and not r.parts[key].locked is bool: return _fail("组件上锁要求有误。")
   if r.get("locked",false):
    for key in layout.parts:
     if not r.parts.has(key): r.parts[key]={}
     r.parts[key].locked=true
  else:
   r.type=r.get("type",r.get("template",""))
   if not g.SpecialEquipment.DESIGNS.has(r.type): return _fail("这件特殊装备待定义。")
   var design=g.SpecialEquipment.DESIGNS[r.type]
   r.slot=r.get("slot",design.slots[0])
   if r.slot!=design.slots[0]: return _fail("请选择该装备支持的位置。")
   if r.get("locked",false) or (r.has("grade") and r.grade!=design.grade) or r.get("tier",2) not in [1,2,3] or r.get("variant",0)!=0:
    return _fail("这件特殊装备的品质和固定方式由自身款式决定。")
  normalized.append(r)
 return {"ok":true,"requests":normalized}

static func _install(g, r: Dictionary, source: String) -> Dictionary:
 match r.kind:
  "install":
   var maximum=g.Equipment.maximum(r.grade)
   return g._install_template(r.template,r.slot,maximum*[0.0,0.4,0.8,1.0][r.tier],maximum,r.locked,source,r.grade,r.get("layer",-1),r.variant,r.point)
  "assembly": return g._install_assembly(r.family,r.variant,source,r.grade,r.tier,r.parts,r.straps,r.get("attached_to",""))
  "special_install": return g._install_special(r.type,r.slot,r.get("tier",0))
 return {}

static func _pieces(item: Dictionary) -> Array:
 return item.components if item.has("components") else [item]

static func _loadout_records(snapshot: Dictionary) -> Array:
 var records=[]
 for item in snapshot.equipment+snapshot.special_equipment+snapshot.links+snapshot.composites:
  var record=item.duplicate(true)
  records.append_array(record.get("components",[]))
  record.erase("components")
  if record.get("binding",{}).has("id"):
   records.append(record.binding)
   record.binding={"kind":record.binding.kind}
  if record.has("shoulders"):
   records.append_array(record.shoulders.pieces)
   record.shoulders.erase("pieces")
   record.shoulders.erase("source")
  records.append(record)
 return records

static func _record_facts(record: Dictionary) -> Dictionary:
 var facts=record.duplicate(true)
 # Identity and provenance alone do not make a fresh copy different equipment.
 for key in ["id","source","root_id","parent_id","shoulder_host","attached_to","ends"]: facts.erase(key)
 return facts

static func _same_loadout(before: Dictionary, after: Dictionary) -> bool:
 var old_records=_loadout_records(before)
 var new_records=_loadout_records(after)
 if old_records.size()!=new_records.size(): return false
 var unmatched=old_records.duplicate()
 var identity={}
 for record in new_records:
  var facts=_record_facts(record)
  var index=unmatched.find_custom(func(old):return _record_facts(old)==facts)
  if index<0: return false
  identity[record.id]=unmatched[index].id
  unmatched.remove_at(index)
 # Keep the complete attachment/link graph, normalizing only regenerated IDs.
 var expected=old_records.duplicate(true)
 for record in expected: record.erase("source")
 for record in new_records:
  record.erase("source")
  for key in ["id","root_id","parent_id","shoulder_host","attached_to"]:
   if record.has(key): record[key]=identity.get(record[key],record[key])
  if record.has("ends"): record.ends=record.ends.map(func(id):return identity.get(id,id))
  var index=expected.find(record)
  if index<0: return false
  expected.remove_at(index)
 return true

static func _capacity_points(g, piece: Dictionary) -> Array:
 if g.SpecialEquipment.is_special(piece):
  return g.SpecialEquipment.occupied_slots(piece) if g.SpecialEquipment.capacity_cost(piece)>0 else []
 return g.Equipment.capacity_points(piece)

static func _physical_points(g, piece: Dictionary) -> Array:
 return g.SpecialEquipment.occupied_slots(piece) if g.SpecialEquipment.is_special(piece) else g.Equipment.physical_points(piece)

static func _counts(g, pieces: Array) -> Dictionary:
 var result={}
 for piece in pieces:
  var amount=g.SpecialEquipment.capacity_cost(piece) if g.SpecialEquipment.is_special(piece) else 1
  for point in _capacity_points(g,piece): result[point]=result.get(point,0)+amount
 return result

static func _plan(g, requests: Array, source: String, protected_ids: Array) -> Dictionary:
 var normalized=_normalize(g,requests)
 if not normalized.ok: return normalized
 var specs=normalized.requests
 var before=g.state.duplicate(true)
 var mandatory=[]
 var mandatory_ids=[]
 for request in specs:
  if request.kind!="special_install": continue
  var family=g.SpecialEquipment.exclusive_family(request.type)
  for item in before.special_equipment:
   if g.SpecialEquipment.exclusive_family(item.type)!=family or item.id in mandatory_ids: continue
   if g.RopeArt.locked(g,item): return _fail("本场战斗中，绳索拘束具不能解除。")
   if g.cursed_plate(item): return _fail(g.SpecialEquipment.CURSED_PLATE_REASON)
   if item.id in protected_ids: return _fail("同批次新装特殊装备保留。")
   mandatory.append({"id":item.id,"pieces":[item.duplicate(true)],"counts":_counts(g,[item]),"composite":false})
   mandatory_ids.append(item.id)
 var direct=_trial(g,before,specs,source,[]) if mandatory.is_empty() else _fail("同族旧装备需要先完成替换。")
 if direct.ok: return direct
 # Factory-made prototypes, solely for capacity demand and comparison geometry.
 # This scratch state is discarded, including any factory RNG and emitted text.
 g.state=before.duplicate(true)
 g.state.equipment=[];g.state.composites=[];g.state.special_equipment=[];g.state.links=[]
 var new_pieces=[]
 var prototypes=[]
 for r in specs:
  var item=_install(g,r,source)
  if item.is_empty(): return _fail("本组安装规格本身有误，或新装备之间存在冲突。")
  new_pieces.append_array(_pieces(item))
  prototypes.append(item)
 for unit in mandatory:
  var old=unit.pieces[0]
  var family=g.SpecialEquipment.exclusive_family(old.type)
  var incoming=new_pieces.filter(func(piece):return g.SpecialEquipment.is_special(piece) and g.SpecialEquipment.exclusive_family(piece.type)==family)
  if incoming.is_empty() or replacement_value(g,incoming[0])<replacement_value(g,old): return _fail("替换需要更高品质的同族新装备。")
 var demand=_counts(g,new_pieces)
 g.state=before.duplicate(true)
 var existing=_counts(g,g.physical_pieces()+g.state.special_equipment)
 var mandatory_counts={}
 for unit in mandatory:
  for point in unit.counts: mandatory_counts[point]=mandatory_counts.get(point,0)+unit.counts[point]
 var deficit={}
 for point in demand:
  var capacity=g.SpecialEquipment.capacity(point) if point in g.SpecialEquipment.slots() else g._capacity(g.Links.point_slot(point))
  for piece in new_pieces:
   if point not in g.SpecialEquipment.slots() and point in g.Equipment.capacity_points(piece):
    capacity=mini(capacity,g.Equipment.capacity(g.Links.point_slot(point),piece.template)+demand[point]-1)
  var extra=existing.get(point,0)-mandatory_counts.get(point,0)+demand[point]-capacity
  if extra>0: deficit[point]=extra
 var units=_units(g,deficit)
 units=units.filter(func(unit):return not unit.pieces.any(func(piece):return g.cursed_eyes(piece) or g.cursed_plate(piece) or g.RopeArt.locked(g,piece) or piece.id in protected_ids or piece.id in mandatory_ids))
 # Even the weakest eligible values, with no lost-link penalty or whole-root
 # restriction, must pass the SAME assignment rule. This is only an optimistic
 # rejection bound; actual minimal sets and complete trials remain authoritative.
 if not _comparison_possible(g,units+mandatory,deficit,prototypes):
  return _fail("最外层没有满足本次容量、强度比较和完整覆盖要求的替换方案。")
 var search={"minimum":units.size()+1,"sets":[],"seen":{}}
 _sets(units,deficit,[],search)
 var best={}
 for chosen in search.sets:
  var selected=mandatory.duplicate(true)
  for i in chosen: selected.append(units[i])
  if not best.is_empty():
   var minimum_score=0
   for unit in selected:
    for piece in unit.pieces:
     minimum_score+=replacement_value(g,piece)*_capacity_points(g,piece).filter(func(point):return point in deficit).size()
   # Losing links can only add to this score. Equal scores retain the first
   # complete plan, exactly as before, so these sets cannot improve the result.
   if minimum_score>=best.score: continue
  var attempt=_trial(g,before,specs,source,selected,deficit)
  if attempt.ok and (attempt.removed+attempt.lost_links).any(func(id):return id in protected_ids): continue
  if attempt.ok and (best.is_empty() or attempt.score<best.score): best=attempt
 return best if not best.is_empty() else _fail("最外层没有满足本次容量、强度比较和完整覆盖要求的替换方案。")

static func _comparison_possible(g, units: Array, deficit: Dictionary, installed: Array) -> bool:
 var rows=[]
 for point in deficit:
  var values=[]
  for unit in units:
   for piece in unit.pieces:
    if point in _capacity_points(g,piece): values.append(replacement_value(g,piece))
  values.sort()
  if values.size()<deficit[point]: return false
  for i in range(deficit[point]): rows.append({"point":point,"old_value":values[i],"composite":false})
 return _assign(g,rows,installed,{},0,{},{},[]).ok

static func _units(g, deficit: Dictionary) -> Array:
 var result=[]
 for piece in g.state.equipment+g.state.special_equipment:
  if g.Equipment.lock_only(piece): continue
  if g.SpecialEquipment.is_chastity(piece) or g.SpecialEquipment.is_reinforcement(piece): continue
  if not g._outer(piece): continue
  var counts=_counts(g,[piece])
  if counts.keys().any(func(p):return p in deficit): result.append({"id":piece.id,"pieces":[piece.duplicate(true)],"counts":counts,"composite":false})
 for root in g.state.composites:
  var dependent=root.components.filter(func(e):return not e.get("independent",false))
  var body=g._composite_body(root)
  if not body.is_empty() and dependent.all(func(e):return g._outer(e)):
   var counts=_counts(g,dependent)
   if counts.keys().any(func(p):return p in deficit): result.append({"id":body.id,"pieces":dependent.duplicate(true),"counts":counts,"composite":true})
  for piece in root.components:
   if not piece.get("independent",false) or not g._outer(piece): continue
   var counts=_counts(g,[piece])
   if counts.keys().any(func(p):return p in deficit): result.append({"id":piece.id,"pieces":[piece.duplicate(true)],"counts":counts,"composite":false})
 return result

# Branch only on a still-full position. Never peel a layer exposed by an earlier
# removal, or add an unrelated weak item to manufacture a majority.
static func _sets(units: Array, remaining: Dictionary, chosen: Array, search: Dictionary) -> void:
 var key=chosen.duplicate();key.sort()
 var signature=str(key)
 if search.seen.has(signature): return
 search.seen[signature]=true
 var point=""
 for p in remaining:
  if remaining[p]>0: point=p;break
 if point=="":
  if chosen.size()<search.minimum: search.minimum=chosen.size();search.sets=[]
  if chosen.size()==search.minimum: search.sets.append(key)
  return
 if chosen.size()>=search.minimum: return
 for i in range(units.size()):
  if i in chosen or units[i].counts.get(point,0)==0: continue
  var next=remaining.duplicate()
  for p in next: next[p]-=units[i].counts.get(p,0)
  _sets(units,next,chosen+[i],search)

static func _trial(g, before: Dictionary, specs: Array, source: String, units: Array, deficit: Dictionary={}) -> Dictionary:
 g.state=before.duplicate(true)
 var old_targets=g.action_targets().duplicate(true)
 var removed_ids=[]
 for unit in units:
  for piece in unit.pieces: removed_ids.append(piece.id)
  var target=g._equipment(unit.id)
  for shoulder in g.Shoulders.attached(g,target):
   if shoulder.id not in removed_ids: removed_ids.append(shoulder.id)
 var impacted=before.links.filter(func(link):return link.ends.any(func(id):return id in removed_ids))
 # Temporarily park affected links so cleanup cannot falsely announce a loss
 # for a link that the complete replacement will legally retain.
 g.state.links=g.state.links.filter(func(link):return not impacted.any(func(old):return old.id==link.id))
 for unit in units: g._equipment(unit.id).durability=0.0
 if not units.is_empty(): g._cleanup(false)
 var installed=[]
 for r in specs:
  var item=_install(g,r,source)
  if item.is_empty(): return _fail("请检查安装位置、容量与装备结构。")
  installed.append(item)
 var new_anchors=[]
 for item in installed: new_anchors.append_array(_pieces(item))
 var transfers=_transfer(g,impacted,new_anchors)
 var shoulder_losses=[]
 var live=g.action_targets().map(func(e):return e.id)
 var removed=old_targets.filter(func(e):return e.id not in live and e.template!="link_rope").map(func(e):return e.id)
 # Shoulder ids embed their owner under the current authoritative validator.
 # They cannot legally move to a new owner while retaining identity.
 for e in old_targets:
  if e.id in removed and g.Equipment.is_shoulder(e): shoulder_losses.append(e.id)
 var transfer={};var comparison={}
 for option in transfers:
  var checked=_compare(g,units,installed,deficit,before,option.lost+shoulder_losses)
  if checked.ok and (comparison.is_empty() or checked.score<comparison.score):
   transfer=option;comparison=checked
 if comparison.is_empty(): return _fail("新装备需满足替换强度与完整覆盖条件。")
 var lost=transfer.lost+shoulder_losses
 g.state.links.append_array(transfer.kept)
 for link in impacted:
  if link.id in lost: g._emit("event",link.name+"无法接到新装备，随替换解除。",{"replacement_link":link.id})
 g._cleanup(false)
 # Validate the equipment domain without requiring an enclosing enemy/event
 # action to have finished updating its own transient phase state.
 for e in g.state.equipment:
  if g.Equipment.validate(e)!="" or g.Binding.validate(g,e)!="": return _fail("替换后的普通装备结构校验失败。")
 for root in g.state.composites:
  if g.Composites.validate(root)!="": return _fail("替换后的复合装备结构校验失败。")
 if g.Shoulders.validate(g)!="" or g.SpecialEquipment.validate(g.state.special_equipment)!="" or g._capacity_issue(g.physical_pieces())!="": return _fail("替换后的装备占位或依附关系校验失败。")
 for link in g.state.links:
  if g.Links.validate(link,g.link_anchors(),g.state.links)!="": return _fail("替换后的链接结构校验失败。")
 if not units.is_empty() and _same_loadout(before,g.state): return _fail("替换后装备没有变化。")
 return {"ok":true,"reason":"","requests":specs,"removed":removed,"installed":installed.duplicate(true),"lost_links":lost,"comparisons":comparison.rows,"score":comparison.score,"_after":g.state.duplicate(true)}

static func _transfer(g, links: Array, anchors: Array) -> Array:
 var options=[]
 for link in links:
  var choices=[]
  var ends=[]
  for i in range(2):
   var old=g._equipment(link.ends[i])
   ends.append([old] if not old.is_empty() else anchors.filter(func(e):return link.contact_points[i] in g.Links.anchor_points(e,link.slots[i])))
  if link.slots.all(func(slot):return g._sealed_reason(slot)==""):
   for a in ends[0]:
    for b in ends[1]:
     var candidate=link.duplicate(true)
     candidate.ends=[a.id,b.id]
     candidate.blocked_slip=link.blocked_slip.map(func(id):return candidate.ends[link.ends.find(id)])
     if g.Links.validate(candidate,g.link_anchors(),g.state.links)=="": choices.append(candidate)
  options.append(choices)
 var best={"count":-1,"solutions":[],"seen":{}}
 _transfer_search(g,links,options,0,[],[],best)
 return best.solutions

static func _transfer_search(g, links: Array, options: Array, index: int, kept: Array, lost: Array, best: Dictionary) -> void:
 # Empty option lists are unavoidable losses. If reaching the current best
 # requires keeping every other link, its loss set is already determined.
 # A previously found assignment for that set has the same comparison score.
 if best.count==links.size(): return
 var potential=kept.size()
 var fixed_losses=lost.duplicate()
 for remaining in range(index,links.size()):
  if options[remaining].is_empty(): fixed_losses.append(links[remaining].id)
  else: potential+=1
 if potential<best.count or (potential==best.count and best.seen.has(str(fixed_losses))): return
 if index==links.size():
  if kept.size()>best.count: best.count=kept.size();best.solutions=[];best.seen={}
  var signature=str(lost)
  if kept.size()==best.count and not best.seen.has(signature):
   best.seen[signature]=true
   best.solutions.append({"kept":kept.duplicate(true),"lost":lost.duplicate()})
  return
 for candidate in options[index]:
  if g.Links.validate(candidate,g.link_anchors(),g.state.links+kept)=="":
   _transfer_search(g,links,options,index+1,kept+[candidate],lost,best)
 _transfer_search(g,links,options,index+1,kept,lost+[links[index].id],best)

static func replacement_value(g, piece: Dictionary) -> int:
 if g.Equipment.is_shackle(piece): return g.Equipment.SHACKLE_RESTRAINT_VALUE
 # Special durability drives its own damage rules, not an ordinary tightness.
 var tightness=0
 if not g.SpecialEquipment.is_special(piece):
  tightness=piece.tier if piece.has("tier") else g.tier(piece.durability,piece.maximum)
 return g.RestraintValue.from_profile(piece.grade,tightness)+(1 if piece.get("locked",false) else 0)

static func _loss(g, piece: Dictionary, point: String, unit: Dictionary, before: Dictionary, lost: Array) -> int:
 var ids={}
 for link in before.links:
  if link.id not in lost: continue
  for i in range(2):
   if link.ends[i]==piece.id and link.contact_points[i]==point: ids[link.id]=true
 if point=="upper_arm_top":
  var shoulders=piece.get("shoulders",{}).get("pieces",[])
  if unit.composite: shoulders=unit.pieces.filter(func(e):return g.Equipment.is_shoulder(e))
  for strap in shoulders:
   if strap.id in lost: ids[strap.id]=true
 return ids.size()

static func _compare(g, units: Array, installed: Array, deficit: Dictionary, before: Dictionary, lost: Array) -> Dictionary:
 var rows=[]
 var strict_roots={}
 for unit in units:
  if unit.composite:
   var points=[]
   for piece in unit.pieces:
    for point in _physical_points(g,piece):
     if point not in points: points.append(point)
   var singles=installed.filter(func(item):return not item.has("components") and _physical_points(g,item).any(func(p):return p in points))
   var strict=singles.size()>=points.size()
   for point in points:
    var locals=unit.pieces.filter(func(piece):return point in _physical_points(g,piece))
    var incoming=singles.filter(func(piece):return point in _physical_points(g,piece))
    if incoming.is_empty(): strict=false
    for old in locals:
     if incoming.any(func(piece):return replacement_value(g,piece)<=replacement_value(g,old)+_loss(g,old,point,unit,before,lost)): strict=false
   strict_roots[unit.id]=strict
  for piece in unit.pieces:
   for point in _capacity_points(g,piece):
    if point not in deficit: continue
    rows.append({"old_id":piece.id,"unit":unit.id,"point":point,"old_value":replacement_value(g,piece)+_loss(g,piece,point,unit,before,lost),"lost_link_bonus":_loss(g,piece,point,unit,before,lost),"composite":unit.composite})
 # Incidental overlap from removing a whole root is not an extra voting ticket.
 rows.sort_custom(func(a,b):return a.old_value>b.old_value)
 var needed={};var selected=[]
 for row in rows:
  if needed.get(row.point,0)>=deficit[row.point]: continue
  needed[row.point]=needed.get(row.point,0)+1;selected.append(row)
 var assigned=_assign(g,selected,installed,strict_roots,0,{}, {},[])
 var score=0
 for row in rows: score+=row.old_value
 return {"ok":assigned.ok,"rows":assigned.get("rows",[]),"score":score}

static func _assign(g, rows: Array, installed: Array, strict_roots: Dictionary, index: int, used: Dictionary, votes: Dictionary, results: Array) -> Dictionary:
 if index==rows.size():
  for tally in votes.values():
   if tally.low<=tally.high: return {"ok":false}
  return {"ok":true,"rows":results}
 var row=rows[index]
 for i in range(installed.size()):
  var item=installed[i]
  var composite=item.has("components")
  if not composite and row.composite and not strict_roots.get(row.unit,false): continue
  for piece in _pieces(item):
   var key=piece.id+":"+row.point
   if used.has(key) or row.point not in _capacity_points(g,piece): continue
   var value=replacement_value(g,piece)
   if not composite and value<row.old_value: continue
   var next_used=used.duplicate();next_used[key]=true
   var next_votes=votes.duplicate(true)
   if composite:
    if not next_votes.has(i): next_votes[i]={"low":0,"high":0}
    next_votes[i]["low" if row.old_value<=value else "high"]+=1
   var result=row.duplicate();result.new_id=piece.id;result.new_value=value;result.request=i
   var attempt=_assign(g,rows,installed,strict_roots,index+1,next_used,next_votes,results+[result])
   if attempt.ok: return attempt
 return {"ok":false}
