extends RefCounted
const E=preload("res://data/equipment.gd")
const C=preload("res://data/composites.gd")
const O=preload("res://core/equipment_offers.gd")
const Replacement=preload("res://core/equipment_replacement.gd")

# Internal installer for Game/RoomEvents. No player command, costs, readiness state
# mutation, final-departure handling, or future intent construction belongs here.
# choose returns one concrete request, or an atomic application_group with requests.
# Empty ordinary/special whitelists mean no permission; composite is an explicit pool.
static func choose(g, spec: Dictionary, source: String, domain: String="enemy") -> Dictionary:
 var bands=_choice_bands(g,spec,source)
 if bands.is_empty(): return {}
 # Equal weights per legal grade/tightness profile, not per template count.
 var primary=bands[g._random_index(domain,bands.size())]
 if spec.get("pool","ordinary")=="ordinary":
  var families={}
  for request in primary:
   var family=E.generation_class(request.template) if request.has("template") else request.kind
   if not families.has(family): families[family]=[]
   families[family].append(request)
  primary=families[families.keys()[g._random_index(domain,families.size())]]
  var positions={}
  for request in primary:
   var position=JSON.stringify([request.kind,request.get("slot",""),request.get("point",""),request.get("ends",[]),request.get("contact_points",[]),request.get("target","")])
   if not positions.has(position): positions[position]=[]
   positions[position].append(request)
  primary=positions[positions.keys()[g._random_index(domain,positions.size())]]
 elif spec.get("pool","ordinary")=="special" and g.state.get("chastity_locks_enabled",false):
  var lock_choices=primary.filter(func(request):return g.SpecialEquipment.is_chastity_type(request.get("type","")))
  var toy_choices=primary.filter(func(request):return not g.SpecialEquipment.is_chastity_type(request.get("type","")))
  if not lock_choices.is_empty() and not toy_choices.is_empty():
   primary=lock_choices if g._random_index(domain,100)<int(g.state.get("chastity_lock_chance",25)) else toy_choices
  elif not lock_choices.is_empty(): primary=lock_choices
  else: primary=toy_choices
 var selected=primary[g._random_index(domain,primary.size())].duplicate(true)
 if selected.get("kind","")=="application_group":
  for request in selected.requests: _freeze_variant(g,request)
 else: _freeze_variant(g,selected)
 return selected

# Same legality as execution, without selecting or freezing a random outcome.
static func can_apply(g, spec: Dictionary, source: String) -> bool:
 return not _choice_bands(g,spec,source).is_empty()

static func _choice_bands(g, spec: Dictionary, source: String) -> Array:
 if _spec_reason(spec)!="" or spec.get("count",1)==0: return []
 var bands=[]
 var mixed=not spec.get("composites",[]).is_empty()
 # Explicit mixed sources retain separate pools with equal legal-pool weights.
 # Try all permitted empty positions before considering any replacement.
 if mixed and spec.get("replace",false):
  var plain=spec.duplicate(true);plain.replace=false
  bands=_choice_bands(g,plain,source)
  if not bands.is_empty(): return bands
 for profile in spec.get("profiles",[{}]):
  var current=spec.duplicate(true)
  current.merge(profile,true)
  var choices=_choices(g,current,source)
  if choices.is_empty() and not spec.get("fallback_templates",[]).is_empty():
   current.templates=spec.fallback_templates
   choices=_choices(g,current,source)
  if not choices.is_empty(): bands.append(choices)
  if mixed:
   current.pool="composite";current.templates=spec.composites
   choices=_choices(g,current,source)
   if not choices.is_empty(): bands.append(choices)
 return bands

static func execute(g, spec: Dictionary, source: String, domain: String="enemy") -> Dictionary:
 var issue=_spec_reason(spec)
 if issue!="": return _failure(issue)
 var result=_result()
 var attempts=0
 var requested=spec.get("count",1)
 # Count zero is an empty batch, never an implicit unbounded generation pass.
 while attempts<requested:
  var current=spec.duplicate(true)
  # Counted installations must survive the remainder of this batch.
  current.protected_ids=spec.get("protected_ids",[]).duplicate()
  for item in result.installed:
   if item.has("components"):
    for piece in item.components: current.protected_ids.append(piece.id)
   else: current.protected_ids.append(item.id)
  current.count=requested-attempts
  current.ready_layers=maxi(0,int(spec.get("ready_layers",0))-result.ready_used)
  if spec.has("tiers"): current.tiers=spec.tiers.slice(attempts)
  # A dodge does not reserve a body position or consume selection randomness.
  if g.state.evasion>0 and can_apply(g,current,source):
   evade(g,source)
   result.evaded+=1;attempts+=1
   continue
  var request=choose(g,current,source,domain)
  if request.is_empty():
   result.reason="没有符合来源要求的装备或安装位置。"
   break
  var outcome=execute_concrete(g,request,source,spec.get("replace",false),current.protected_ids)
  if not outcome.ok and outcome.evaded==0:
   result.reason=outcome.reason
   break
  var units=request.requests.size() if request.get("kind","")=="application_group" else 1
  attempts+=units
  result.evaded+=outcome.evaded
  result.ready_used+=mini(units,current.ready_layers)
  result.installed.append_array(outcome.installed)
  result.removed.append_array(outcome.removed)
  result.lost_links.append_array(outcome.lost_links)
 result.count=attempts-result.evaded
 result.ok=result.count>0
 return result

# A frozen request never retargets; dodge reactions may generate a separate install.
# Replacement owns all removal,
# link preservation and whole-group commit; the original factories own plain installs.
static func execute_concrete(g, request: Dictionary, source: String, allow_replace: bool=false, protected_ids: Array=[], voluntary: bool=false) -> Dictionary:
 var requests=request.get("requests",[]) if request.get("kind","")=="application_group" else [request]
 if requests.is_empty(): return _failure("本次没有指定要安装的装备。")
 for entry in requests:
  var definition_issue=_request_reason(g,entry,false)
  if definition_issue!="": return _failure(definition_issue)
 var placement_reason=_request_reason(g,requests[0],true,protected_ids) if requests.size()==1 else ""
 if requests.size()==1 and requests[0].get("kind","")=="special_install" and g.SpecialEquipment.is_chastity_type(requests[0].get("type","")) and placement_reason!="":
  return _failure(placement_reason)
 if requests.size()>1 or (allow_replace and placement_reason!=""):
  if not allow_replace: return _failure("本次来源没有整组替换装备的权限。")
  var planned=_replacement_plan(g,requests,source,protected_ids)
  if not planned.get("ok",false): return _failure(planned.get("reason","这组装备无法替换现有装备。"))
  if not voluntary and (evade(g,source) or g.Character.evade(g,requests,source)): return _evaded(requests.size())
  var committed=Replacement.execute(g,planned)
  if not committed.get("ok",false): return _failure(committed.get("reason","装备替换未能完成。"))
  var result=_result()
  result.installed=committed.get("installed",[]).duplicate(true)
  result.removed=committed.get("removed",[]).duplicate()
  result.lost_links=committed.get("lost_links",[]).duplicate()
  result.count=result.installed.size();result.ok=result.count>0
  return result
 var p=requests[0]
 if placement_reason!="": return _failure(placement_reason)
 # Voluntary self-equipping is a card's cost, not an incoming attack to evade.
 if not voluntary and (evade(g,source) or g.Character.evade(g,requests,source)): return _evaded(1)
 var items=[];var removed=[]
 var grade=p.get("grade",2)
 var maximum=E.maximum(grade)
 var durability=maximum*[0.0,0.4,0.8,1.0][p.get("tier",2)]
 match p.kind:
  "install":
   var item=g._install_template(p.template,p.slot,durability,maximum,p.get("locked",false),source,grade,p.get("layer",-1),p.get("variant",0),p.get("point",""))
   if not item.is_empty(): items.append(item)
  "assembly":
   var root=g._install_assembly(p.family,p.variant,source,grade,p.get("tier",2),_overrides(p),p.get("straps","straight"),p.get("attached_to",""))
   if not root.is_empty(): items.append(root)
  "special_install":
   var old_ids=g.state.special_equipment.map(func(old):return old.id)
   var item=g._install_special(p.type,p.slot,p.get("tier",0))
   if not item.is_empty(): items.append(item)
   removed=old_ids.filter(func(id):return not g.state.special_equipment.any(func(current):return current.id==id))
  "link":
   var link=g._install_link(p.ends[0],p.ends[1],durability,source,grade,p.get("blocked_slip",[]),p.get("slots",[]),p.get("contact_points",[]))
   if not link.is_empty(): items.append(link)
  "shoulder":
   var host=g._equipment(p.target)
   if g.Shoulders.install(g,host,p.template,grade,source): items.append_array(g.Shoulders.attached(g,host))
 if items.is_empty(): return _failure("原定位置已不符合这件装备的安装要求。")
 var result=_result()
 result.removed=removed
 result.installed=items.duplicate(true);result.count=1;result.ok=true
 return result

static func _spec_reason(spec: Dictionary) -> String:
 if spec.has("allow_links") and not spec.allow_links is bool: return "链接绳范围必须明确为允许或不允许。"
 if spec.has("profiles"):
  if not spec.profiles is Array or spec.profiles.is_empty(): return "装备规格列表不能为空。"
  for profile in spec.profiles:
   if not profile is Dictionary or profile.size()!=2 or not profile.get("grade") is int or not profile.get("tier") is int: return "装备规格需要整数品质与紧度。"
   if profile.grade not in [1,2,3] or profile.tier not in [1,2,3]: return "装备规格的品质或紧度不合法。"
 if spec.get("pool","ordinary") not in ["ordinary","composite","special"]: return "本次没有指定有效的装备来源池。"
 if not spec.get("templates",[]) is Array or not spec.get("fallback_templates",[]) is Array: return "装备来源名单格式不正确。"
 if not spec.get("composites",[]) is Array or (spec.has("composites") and spec.get("pool","ordinary")!="ordinary"): return "复合追加名单只能由普通装备来源明确声明。"
 if not spec.get("required_slots",[]) is Array or spec.get("required_slots",[]).any(func(slot):return not slot is String): return "指定施加部位格式不正确。"
 if spec.get("count",1)<0 or spec.get("ready_layers",0)<0: return "施加数量和准备层数不能为负数。"
 if not E.GRADES.has(spec.get("grade",2)) or spec.get("tier",2) not in [1,2,3]: return "装备品质或紧度档位不合法。"
 if not spec.get("tiers",[]) is Array or not spec.get("variants",{}) is Dictionary: return "逐件紧度或材质版本要求格式不正确。"
 for value in spec.get("tiers",[]):
  if value not in [1,2,3]: return "逐件紧度必须在一至三档之间。"
 return ""

static func _piece_spec(spec: Dictionary, index: int, ready_used: int) -> Dictionary:
 var result=spec.duplicate(true)
 var tiers=spec.get("tiers",[])
 result.tier=3 if spec.get("ready_layers",0)>ready_used else (tiers[index] if index<tiers.size() else spec.get("tier",2))
 return result

static func _choices(g, spec: Dictionary, source: String) -> Array:
 var raw=_raw(g,spec,source)
 var required_slots=spec.get("required_slots",[])
 if not required_slots.is_empty(): raw=raw.filter(func(request):return _slots(request).all(func(slot):return slot in required_slots) if request.kind=="link" else _slots(request).any(func(slot):return slot in required_slots))
 # An explicit preferred slot is checked for normal and authorized replacement
 # before moving on to the next preferred slot, ordinary priority, or fallback pool.
 var preferred_slots=spec.get("preferred_slots",[])
 for slot in preferred_slots:
  var band=raw.filter(func(p):return slot in _slots(p))
  var found=_legal_choices(g,band,spec,source)
  if found.is_empty() and spec.get("replace",false) and spec.get("count",1)>1 and spec.get("pool","ordinary")=="ordinary":
   found=_groups(g,raw,spec,source).filter(func(group):return group.requests.any(func(p):return slot in _slots(p)))
  if not found.is_empty(): return O.preferred(g,found)
 return O.preferred(g,_legal_choices(g,raw,spec,source))

static func _legal_choices(g, raw: Array, spec: Dictionary, source: String) -> Array:
 var normal=raw.filter(func(p):return _request_reason(g,p,true,spec.get("protected_ids",[]))=="")
 if not normal.is_empty(): return normal
 if not spec.get("replace",false): return []
 var options=[]
 for request in raw:
  if request.kind not in ["install","assembly","special_install"]: continue
  if request.kind=="special_install" and g.SpecialEquipment.is_chastity_type(request.get("type","")): continue
  if request.get("random_variant",false):
   var available=[]
   for variant in E.MATERIALS[E.TEMPLATES[request.template].material][request.grade].size():
    var concrete=request.duplicate(true);concrete.variant=variant
    if _replacement_plan(g,[concrete],source,spec.get("protected_ids",[])).get("ok",false): available.append(variant)
   if not available.is_empty():
    var option=request.duplicate(true);option.variant=available[0];option.variant_choices=available
    options.append(option)
  elif _replacement_plan(g,[request],source,spec.get("protected_ids",[])).get("ok",false): options.append(request)
 if options.is_empty() and spec.get("pool","ordinary")=="ordinary" and spec.get("count",1)>1:
  options.append_array(_groups(g,raw,spec,source))
 return options

static func _raw(g, spec: Dictionary, source: String) -> Array:
 var grade=spec.get("grade",2)
 var templates=spec.get("templates",[])
 var locked=spec.get("locked",false)
 var raw=[]
 match spec.get("pool","ordinary"):
  "ordinary":
   if templates.is_empty(): return []
   raw=O.for_pool(g,grade,templates,locked,false,spec.get("allow_links",true))
   if not locked:
    # Extra shoulder pairs still require an explicit source capability.
    if spec.get("shoulders",false): raw.append_array(O.shoulders(g,grade,templates))
  "composite":
   for entry in O.assembly_specs(templates):
    if spec.get("variants",{}).has(entry.family) and spec.variants[entry.family]!=entry.variant: continue
    var layout=C.spec(entry.family,entry.variant,entry.straps)
    entry.rank=0;entry.name=layout.name
    for slot in layout.coverage: entry.rank=maxi(entry.rank,g._priority(slot))
    raw.append(entry)
  "special":
   if locked: return []
   for type in g.SpecialEquipment.generation_pool(templates,g.state.get("chastity_locks_enabled",false)):
    if not E.Special.DESIGNS.has(type): continue
    var slot=E.Special.DESIGNS[type].slots[0]
    raw.append({"kind":"special_install","type":type,"slot":slot,"rank":g._priority(slot)})
 var result=[]
 for request in raw:
  if request.kind=="link":
   if spec.has("slot") and not request.slots.all(func(slot):return slot==spec.slot): continue
   if spec.has("slots") and not request.slots.all(func(slot):return slot in spec.slots): continue
   if spec.has("point") and not request.contact_points.all(func(point):return point==spec.point): continue
  if spec.has("slot") and spec.slot not in _slots(request): continue
  if spec.has("slots") and not _slots(request).any(func(slot):return slot in spec.slots): continue
  if spec.has("point") and request.get("kind","")=="install" and request.get("point","")!=spec.point: continue
  request.grade=grade;request.tier=_piece_spec(spec,0,0).tier;request.locked=locked;request.source=source
  if request.kind=="install":
   request.variant=spec.get("variants",{}).get(request.template,spec.get("variant",0))
   request.random_variant=not spec.has("variant") and not spec.get("variants",{}).has(request.template)
  elif request.kind=="assembly": request.overrides=spec.get("overrides",{}).duplicate(true)
  elif request.kind=="special_install":
   request.grade=E.Special.DESIGNS[request.type].grade
  if _request_reason(g,request,false)=="": result.append(request)
 return result

static func _slots(request: Dictionary) -> Array:
 match request.kind:
  "assembly": return C.spec(request.family,request.variant,request.get("straps","straight")).get("coverage",[])
  "link": return request.get("slots",[])
  "shoulder": return ["shoulder","upper_arm"]
 return [request.get("slot","")]

static func _freeze_variant(g, request: Dictionary) -> void:
 if request.get("random_variant",false):
  var choices=request.get("variant_choices",range(E.MATERIALS[E.TEMPLATES[request.template].material][request.grade].size()))
  request.variant=choices[g._random_index("equipment",choices.size())]
 request.erase("random_variant")
 request.erase("variant_choices")
 request.erase("rank")

static func _overrides(request: Dictionary) -> Dictionary:
 var result=request.get("parts",request.get("overrides",{})).duplicate(true)
 if request.get("locked",false):
  var layout=C.spec(request.family,request.variant,request.get("straps","straight"))
  for part in layout.get("parts",{}):
   if E.TEMPLATES[layout.parts[part].template].lock:
    if not result.has(part): result[part]={}
    result[part].locked=true
 return result

# Structural legality always delegates to the original factory/preparation APIs.
# The definition-only form supplies blocked requests to Replacement.plan.
static func _request_reason(g, p: Dictionary, placement: bool=true, protected_ids: Array=[]) -> String:
 var grade=p.get("grade",2)
 var tier=p.get("tier",2)
 if not E.GRADES.has(grade) or tier not in [1,2,3]: return "装备品质或紧度档位不合法。"
 match p.get("kind",""):
  "install":
   var template=p.get("template","")
   var issue=E.definition_reason(template,p.get("slot",""),grade,p.get("locked",false))
   if issue!="": return issue
   var variant=p.get("variant",0)
   if not variant is int or variant<0 or variant>=E.MATERIALS[E.TEMPLATES[template].material][grade].size(): return "指定的装备材质版本不存在。"
   if g._installation_points(p.slot,p.get("point","")).is_empty(): return "指定位置不属于这件装备的安装部位。"
   if placement: return g._installation_reason(template,p.slot,grade,p.get("locked",false),p.get("point",""),p.get("layer",-1))
  "assembly":
   var layout=C.spec(p.get("family",""),p.get("variant",""),p.get("straps","straight"))
   if layout.is_empty() or grade<layout.minimum: return "指定复合装备的结构或品质不合法。"
   if p.get("locked",false) and not layout.parts.values().any(func(part):return E.TEMPLATES[part.template].lock): return "这件复合装备没有可上锁的位置。"
   if placement and g._prepare_assembly(p.family,p.variant,p.get("source",""),grade,tier,_overrides(p),p.get("straps","straight"),p.get("attached_to","")).is_empty(): return "现有装备或固定位置不允许安装这件复合装备。"
  "special_install":
   if p.get("locked",false): return "这种特殊装备不支持上锁。"
   if not E.Special.DESIGNS.has(p.get("type","")): return "这种特殊装备尚未定义。"
   if placement:
    var issue=g._special_install_reason(p.type,p.get("slot",""))
    if issue!="": return issue
    if g.SpecialEquipment.is_chastity_type(p.type) and g.state.special_equipment.any(func(item):return item.id in protected_ids and g._chastity_displaces(p.type,item)):
     return "本次不能替换刚安装的装备或附属件。"
  "link":
   if p.get("locked",false): return "链接绳没有可上锁的位置。"
   if p.get("ends",[]).size()!=2: return "链接绳需要两个真实连接位置。"
   if placement and g._prepare_link(p.ends[0],p.ends[1],E.maximum(grade)*[0.0,0.4,0.8,1.0][tier],p.get("source",""),grade,p.get("blocked_slip",[]),p.get("slots",[]),p.get("contact_points",[])).is_empty(): return "原定连接位置已不能建立这条链接绳。"
  "shoulder":
   if p.get("locked",false): return "独立肩部附加不支持直接上锁安装。"
   if tier!=grade: return "独立肩部附加的初始紧度由其品质决定。"
   if placement: return g.Shoulders.install_reason(g,g._equipment(p.get("target","")),p.get("template",""),grade)
  _: return "本次没有指定有效的装备安装方式。"
 return ""

static func _replacement_plan(g, requests: Array, source: String, protected_ids: Array=[]) -> Dictionary:
 # Replacement.plan owns the scratch state and feedback isolation.
 var normalized=requests.duplicate(true)
 for request in normalized:
  if request.kind=="assembly": request.parts=_overrides(request)
 return Replacement.plan(g,normalized,source,protected_ids)

# A composite can require several individually impossible ordinary requests. Build
# its entire real point coverage first and let Replacement decide capacity, strength,
# exterior layers and links. Never delete or install a partial covering group.
static func _groups(g, raw: Array, spec: Dictionary, source: String) -> Array:
 var groups=[]
 for root in g.state.composites:
  if not C.active(root): continue
  if root.components.any(func(piece):return piece.id in spec.get("protected_ids",[])): continue
  var points=[]
  for piece in root.components:
   for point in E.physical_points(piece):
    if point not in points: points.append(point)
  if points.is_empty() or points.size()>spec.get("count",1): continue
  var choices=[]
  for i in range(points.size()):
   var point=points[i]
   var local=_piece_spec(spec,i,mini(i,spec.get("ready_layers",0)))
   # Necessary strength bound before enumerating template combinations. Exact
   # lost-link costs and installation geometry still belong to Replacement.plan.
   var minimum=-1
   for piece in root.components:
    if piece.get("independent",false) or point not in E.physical_points(piece): continue
    var cost=Replacement.comparison_value(g,piece)
    if point=="upper_arm_top": cost+=root.components.filter(func(e):return E.is_shoulder(e)).size()
    minimum=maxi(minimum,cost)
   var requests=[]
   for entry in raw:
    if entry.kind!="install" or point not in g._installation_points(entry.slot,entry.get("point","")): continue
    var request=entry.duplicate(true);request.tier=local.tier
    if Replacement.comparison_value(g,request)<=minimum: continue
    requests.append(request)
   choices.append(requests)
  if choices.any(func(requests):return requests.is_empty()): continue
  var requests=_covering_plan(g,choices,0,[],source,spec.get("protected_ids",[]))
  if requests.is_empty(): continue
  var rank=0
  for request in requests: rank=maxi(rank,request.get("rank",0))
  groups.append({"kind":"application_group","requests":requests,"rank":rank})
 return groups

static func _covering_plan(g, choices: Array, index: int, requests: Array, source: String, protected_ids: Array) -> Array:
 if index==choices.size(): return requests.duplicate(true) if _replacement_plan(g,requests,source,protected_ids).get("ok",false) else []
 for request in choices[index]:
  requests.append(request)
  var complete=_covering_plan(g,choices,index+1,requests,source,protected_ids)
  requests.pop_back()
  if not complete.is_empty(): return complete
 return []

static func _result() -> Dictionary:
 return {"ok":false,"count":0,"evaded":0,"installed":[],"removed":[],"lost_links":[],"ready_used":0,"reason":""}

static func evade(g, source: String) -> bool:
 if g.state.evasion<=0: return false
 g.state.evasion-=1
 g._emit("event","闪避抵消了这次拘束具施加，剩余%d层。" % g.state.evasion,{"evasion":{"source":source,"remaining":g.state.evasion}})
 return true

static func _evaded(count: int) -> Dictionary:
 var result=_result()
 result.evaded=count;result.reason="本次施加被闪避抵消。"
 return result

static func _failure(reason: String) -> Dictionary:
 var result=_result();result.reason=reason
 return result
