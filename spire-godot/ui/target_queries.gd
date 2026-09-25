extends RefCounted

# 显示查询（docs/spec/candidate-removal.md §2.1 T9；批 R4 落地、批 R5 收口）：只读一个 View 的显示事实。
# 无节点、无游戏、无跨刷新缓存——每次调用都从传入的 View 取事实。行动行索引（历史名 action_index.gd）已在 R5 删除。
# 事实表是扁平数组（core/game_view.gd::build 的 view.display_facts）：组取用按事实自带的 group 字段过滤，
# 显示点身份按事实自带的 key（形状键）取用——组名与显示键都只有一套命名，不再有行组→View 键的映射表。
# 纯显示查询（body_at／equipment_entries）语义不变。
const RELEASE_MODES=["strain","slip","magic_slip","lower","unlock"]
# 拖放族键面（同一拖起语义的落点族）：与改动前 siblings 的字段面逐条一致。
const FAMILY_FIELDS=["kind","type","item","mode","action","free","form"]

static func body_at(view: Dictionary, slot: String) -> Dictionary:
 for region in view.body_regions:
  if region.id==slot: return region
 for body in view.body_groups:
  if body.id==slot or slot in body.slots: return body
 return view.body_groups[0]

static func equipment_entries(body: Dictionary) -> Dictionary:
 var entries={}
 for section in body.sections:
  for e in section.equipment:
   if not entries.has(e.id): entries[e.id]={"equipment":e,"locations":[]}
   entries[e.id].locations.append(section.name)
 return entries

# 事实表（view.display_facts 的唯一读法）：非数组的旧式分组建投影视为空表。
static func all_facts(view: Dictionary) -> Array:
 var entries=view.get("display_facts",[])
 return entries if entries is Array else []

# 组取用（组名＝事实的 group 字段，与改动前的行组名同值）：取不到的组返回空表。
static func facts(view: Dictionary, group: String) -> Array:
 return all_facts(view).filter(func(f):return String(f.get("group","action"))==group)

# 显示键的唯一取值点（事实自带的形状键；不含提交身份 id）。
static func fact_key(c: Dictionary) -> String:
 return String(c.get("key",""))

static func fact_by_key(view: Dictionary, key: String) -> Dictionary:
 if key=="": return {}
 for f in all_facts(view):
  if fact_key(f)==key: return f
 return {}

# 组查询（显示侧）：字段按 payload 比较，语义与改动前的显示查询一致。
static func select(view: Dictionary, group: String, fields: Dictionary={}) -> Array:
 var result: Array=[]
 for f in facts(view,group):
  var matches=true
  for field in fields:
   if f.payload.get(field)!=fields[field]:
    matches=false
    break
  if matches: result.append(f)
 return result

static func find(view: Dictionary, group: String, fields: Dictionary={}) -> Dictionary:
 var matches=select(view,group,fields)
 return matches[0] if not matches.is_empty() else {}

# 首个可用项的唯一通道（销 DUP4，docs/spec/candidate-removal.md §2.3）：回退策略显式声明，不静默统一——
#  "first"＝快捷解除／身体详情／自由面：无可用时保留**首条**拒绝（改动前 target_queries.first_usable 的行为）；
#  "last"＝行动栏取项（改动前行动行索引 first_usable 的末条拒绝行为，R5 随行索引删除后由本参数承载）。
static func first_usable(offers: Array, fallback: String="first") -> Dictionary:
 for c in offers:
  if c.valid: return c
 if offers.is_empty(): return {}
 return offers[0] if fallback=="first" else offers.back()

# 拖放落点族：同组＋同族键（data 里出现的 FAMILY_FIELDS 键逐条相等）且 target 非空的显示事实。
# data 由 ui/drag_targets.gd::intent 按同一声明键面装配（原 siblings 的字段面）。
static func family_facts(view: Dictionary, data: Dictionary) -> Array:
 var group=String(data.get("group",""))
 if group=="": return []
 return facts(view,group).filter(func(f):
  if f.payload.get("target","")=="": return false
  for key in FAMILY_FIELDS:
   if data.has(key) and f.payload.get(key)!=data[key]: return false
  return true)

static func body_cards(view: Dictionary, body: Dictionary, uid: String) -> Array:
 var includes_neck=body.id=="neck" or body.get("members",[]).any(func(member):return member.id=="neck")
 var choices=select(view,"card",{"uid":uid}).filter(func(c):return c.payload.slot in body.slots or (includes_neck and body.targets.has(c.payload.target)))
 var seen={};var unique=[]
 for c in choices:
  # Merge a physical target per face, preferring a usable candidate without reordering it.
  var key=(c.payload.target if c.payload.target!="" or body.id=="neck" else c.payload.slot)+str(c.payload.free)
  if not seen.has(key):
   seen[key]=unique.size();unique.append(c)
  elif c.valid and not unique[seen[key]].valid:
   unique[seen[key]]=c
 var order=equipment_entries(body).keys()
 unique.sort_custom(func(a,b):return order.find(a.payload.target)<order.find(b.payload.target))
 return unique

static func single_body_card(view: Dictionary, body: Dictionary, uid: String, free: bool) -> Dictionary:
 var entries=equipment_entries(body)
 if entries.size()!=1:return {}
 var choices=body_cards(view,body,uid).filter(func(c):return c.payload.free==free)
 if choices.size()!=1 or not entries.has(choices[0].payload.target):return {}
 return choices[0]

static func single_equipment_card(view: Dictionary, bodies: Array, uid: String, free: bool) -> Dictionary:
 var entries={}
 for body in bodies:entries.merge(equipment_entries(body))
 if entries.size()!=1:return {}
 var target=entries.keys()[0]
 var fields={"uid":uid,"free":free}
 var choices=select(view,"card",fields).filter(func(c):return c.payload.get("target","")!="")
 # Other explicit targets (including capture) still require a player choice.
 if choices.is_empty() or choices.any(func(c):return c.payload.target!=target):return {}
 fields.target=target
 # 行动栏取项的过渡调用面：末条拒绝回退（first_usable 的声明策略）。
 return first_usable(select(view,"card",fields),"last")

# 拖放候选（批 R4）：卡面按 uid／自由面、动作按类型／形态、已解析动作按拖放族取显示事实。
static func drag_facts(view: Dictionary, data: Dictionary, version: int) -> Array:
 if data.get("version",-1)!=version:return []
 if data.has("card_uid"):
  var out=select(view,"card",{"uid":data.card_uid,"free":data.get("free",false)})
  if not data.get("free",false):out.append_array(select(view,"prison",{"action":"unlock","uid":data.card_uid}))
  var seen=[]
  return out.filter(func(c):
   if not c.payload.has("hand_uid") or c.payload.get("self_target",false):return true
   var key=[c.payload.target,c.payload.slot]
   if key in seen:return false
   seen.append(key);return true)
 if data.has("action_type"):
  return select(view,"attack",{"type":data.action_type,"form":data.get("form",0)})
 # Legacy drag payloads list display keys (first-turn equipment strips, explicit key lists).
 # Resolve them against display facts in caller order, keeping duplicates and dropping misses.
 if data.has("fact_keys") or data.has("self_action_key"):
  var keys: Array=data.get("fact_keys",[])
  if keys.is_empty() and data.has("self_action_key"): keys=[data.self_action_key]
  var found=[]
  for key in keys:
   var fact=fact_by_key(view,String(key))
   if not fact.is_empty(): found.append(fact)
  return found
 return family_facts(view,data)

static func equipment_choices(view: Dictionary, data: Dictionary, version: int, body: Dictionary) -> Array:
 var out=[];var seen=[]
 for c in drag_facts(view,data,version):
  var target=c.payload.get("target","")
  if target in seen or not body.targets.has(target):continue
  seen.append(target);out.append(c)
 return out

static func release_choices(view: Dictionary, body: Dictionary, data: Dictionary, version: int) -> Array:
 if not data.has("card_uid") or data.get("version",-1)!=version:return []
 return body_cards(view,body,data.card_uid).filter(func(c):
  return c.payload.get("mode","") in RELEASE_MODES and c.payload.free==data.get("free",false) and body.targets.has(c.payload.target))

static func release_candidate(view: Dictionary, body: Dictionary, target: String, data: Dictionary, version: int) -> Dictionary:
 if data.get("action_type","")=="fireball" and data.get("version",-1)==version:
  return first_usable(select(view,"attack",{"type":"fireball","target":target}))
 return first_usable(release_choices(view,body,data,version).filter(func(c):return c.payload.target==target))
