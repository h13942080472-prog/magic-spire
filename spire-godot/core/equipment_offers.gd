extends RefCounted
const E=preload("res://data/equipment.gd")
const C=preload("res://data/composites.gd")


# Offers and installation share the same read-only assembly preparation.
static func ordinary(g, grade: int=2, free: bool=false, templates: Array=[], locked: bool=false, legal_only: bool=true) -> Array:
 # docs/spec/equipment-query-seam.md「作用域进出点（冻结名单）」: each offer generator reads through one scope of its own.
 var previous=g._begin_equipment_read()
 var offers=[]
 for template in (E.TEMPLATES.keys() if templates.is_empty() else templates):
  if not E.TEMPLATES.has(template) or not E.TEMPLATES[template].get("generated",true): continue
  for slot in E.TEMPLATES[template].slots:
   if E.definition_reason(template,slot,grade,locked)!="": continue
   if free and g.occupied(slot): continue
   for point in (E.points(slot) if E.SEGMENTS.has(slot) else [""]):
    if not legal_only or g._installation_reason(template,slot,grade,locked,point)=="":
     offers.append({"kind":"install","template":template,"slot":slot,"point":point,"rank":g._priority(slot),"name":E.name_for(template,slot)})
 g._equipment_read=previous
 return offers

static func preferred(g, options: Array) -> Array:
 # docs/spec/equipment-query-seam.md「作用域进出点（冻结名单）」: a pure ordering pass; its ranking reads one scope of equipment.
 var previous=g._begin_equipment_read()
 var rank=-1
 for option in options: rank=maxi(rank,option.get("rank",0))
 var band=options.filter(func(option):return option.get("rank",0)==rank)
 # Preserve all three original bands. Within the winning band, fill uncovered
 # physical points before stacking; no regional-degree or coverage-count weights.
 var occupied={}
 for piece in g.physical_pieces():
  if piece.durability>0:
   for point in E.physical_points(piece): occupied[point]=true
 for piece in g.state.special_equipment:
  for point in g.SpecialEquipment.occupied_slots(piece): occupied[point]=true
 var empty=band.filter(func(option):return _fills_empty(g,option,occupied))
 var result=band if empty.is_empty() else empty
 g._equipment_read=previous
 return result

static func _fills_empty(g, request: Dictionary, occupied: Dictionary) -> bool:
 var points=[]
 match request.get("kind",request.get("op","")):
  "install": points=g._installation_points(request.slot,request.get("point",""))
  "assembly":
   var layout=C.spec(request.family,request.variant,request.get("straps","straight"))
   for definition in layout.get("parts",{}).values():
    var piece=definition.duplicate(true);piece.slot=definition.contact[0]
    points.append_array(E.physical_points(piece))
  "special_install": points=g.SpecialEquipment.DESIGNS[request.type].slots
  "application_group": return request.requests.any(func(p):return _fills_empty(g,p,occupied))
 # Links and attached shoulder straps do not occupy a new body point.
 return points.any(func(point):return not occupied.has(point))

static func links(g, grade: int) -> Array:
 # docs/spec/equipment-query-seam.md「作用域进出点（冻结名单）」: the rope generator reads through one scope as well.
 var previous=g._begin_equipment_read()
 var offers=[]
 var anchors=g.link_anchors()
 var contacts={}
 for anchor in anchors:
  contacts[anchor.id]={}
  for slot in g.Links.anchor_slots(anchor): contacts[anchor.id][slot]=g.Links.anchor_points(anchor,slot)
 for a in anchors:
  for b in anchors:
   if a.id>=b.id: continue
   for sa in contacts[a.id]:
    for sb in contacts[b.id]:
     for pa in contacts[a.id][sa]:
      for pb in contacts[b.id][sb]:
       # Reject impossible geometry before rebuilding a full physical link. The
       # factory still checks actual endpoints, sealed slots, duplicates and quotas.
       if not g.Links.adjacent(pa,pb): continue
       var link=g._prepare_link(a.id,b.id,E.maximum(grade)*0.8,"probe",grade,[],[sa,sb],[pa,pb])
       if not link.is_empty(): offers.append({"kind":"link","template":"link_rope","ends":link.ends,"slots":link.slots,"contact_points":link.contact_points,"name":link.name,"rank":1})
 g._equipment_read=previous
 return offers

# Source whitelist first, then the same priority order for every installer.
static func for_pool(g, grade: int, templates: Array, locked: bool=false, legal_only: bool=true, allow_links: bool=true) -> Array:
 if templates.is_empty(): return []
 var previous=g._begin_equipment_read()
 var offers=ordinary(g,grade,false,templates,locked,legal_only)
 # Rope and belt families grant their shared link structure, including imported
 # derivatives. Gags, composite components and special equipment are not belts.
 if allow_links and not locked and templates.any(func(id):return E.base_template(id) in ["rope","cord","belt","fine_belt","eye_leather","link_rope"]): offers.append_array(links(g,grade))
 g._equipment_read=previous
 return offers

static func options(g) -> Array:
 var options=ordinary(g)
 options.append_array(shoulders(g))
 return options

# Only this explicit source pool grants assembly generation. Whitelists accept a
# family ID, or {family, variant?, straps?}; component template IDs never qualify.
static func assembly_specs(whitelist: Array=[]) -> Array:
 var result=[]
 for a in C.GENERATION:
  var entry={"kind":"assembly","family":a[0],"variant":a[1],"straps":a[2],"attached_to":a[3] if a.size()>3 else ""}
  if not whitelist.is_empty() and not whitelist.any(func(w):return _assembly_matches(entry,w)): continue
  result.append(entry)
 return result

static func _assembly_matches(entry: Dictionary, selector) -> bool:
 if selector is String: return entry.family==selector
 if not selector is Dictionary: return false
 if selector.get("family","")!=entry.family: return false
 for key in ["variant","straps","attached_to"]:
  if selector.has(key) and selector[key]!=entry[key]: return false
 return true

static func assemblies(g, grade: int=2, whitelist: Array=[]) -> Array:
 var options=[]
 for entry in assembly_specs(whitelist):
  var root=g._prepare_assembly(entry.family,entry.variant,"probe",grade,2,{},entry.straps,entry.attached_to)
  if root.is_empty(): continue
  var rank=0
  for slot in C.definition(root).coverage: rank=maxi(rank,g._priority(slot))
  entry.rank=rank;entry.name=root.name
  options.append(entry)
 return options

static func shoulders(g, grade: int=2, templates: Array=[]) -> Array:
 var options=[]
 for host in g.state.equipment:
  for template in g.Shoulders.BASES:
   if not templates.is_empty() and template not in templates: continue
   if g.Shoulders.install_reason(g,host,template,grade)=="": options.append({"kind":"shoulder","target":host.id,"template":template,"rank":g._priority("upper_arm"),"name":"成对"+g.Shoulders.label(template,"left").trim_prefix("左")})
 return options
