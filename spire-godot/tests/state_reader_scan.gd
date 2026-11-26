extends RefCounted

# State-field reader face: the static derivation behind tests/state_readers.json
# (docs/spec/state-readers.md carries the full scan口径 and the regeneration rule). One
# implementation is shared by the three STATEREAD judgments in tests/architecture_cases.gd, the
# generator/verifier tools/build_state_readers.gd and the failure-face report; the frozen file
# is only ever written by that generator, in the same commit as a scan change.
#
# 读形态：`state.<field>`／`g.state.<field>`、`state.get("<field>"…)`、`state["<field>"]`；纯写
# 不计读、复合写计一读、子字段写计父字段读；注释按第一个 `#` 截断；整字典形态（core|data）进
# whole_state：pass／duplicate／iterate／has／get_variable。登记表＝`_init` 字面键＋core|data|ui
# 的后续写键＋`state.get("X", …)` 名；别名接收者与模式串调用点各成一表。
# generated_from.inputs_sha256 覆盖 core|ui|data 全部 `.gd` 的归一文本（经 tests/source_text.gd
# 把 CRLF 对折成 LF，指纹因此与检出的行尾无关）：任何文本变化都让判据红，必须同批重生成
# （fail-closed）。
const SourceText=preload("res://tests/source_text.gd")
const FROZEN_PATH="res://tests/state_readers.json"
const SCHEMA=1
const ALL_DIRS=["core","data","ui"]
const REGISTRY_FILE="core/game.gd"
const REGISTRY_ENTRIES="core/command_registry.gd"
const DECLARATION="^\\s*(?:static\\s+)?func\\s+([A-Za-z_][A-Za-z0-9_]*)"
const RESERVED_MEMBERS=["duplicate","get","has"]
const ALIAS_DECLARATIONS=[
 {"file":"core/game.gd","function":"_scene_key","param":"s"},
 {"file":"core/snapshot.gd","function":"is_current","param":"s"},
 {"file":"core/snapshot.gd","function":"check","param":"s"},
 {"file":"core/snapshot.gd","function":"migrate_iron_drone","param":"s"},
 {"file":"core/snapshot.gd","function":"migrate_cup_stacks","param":"s"},
 {"file":"core/prison.gd","function":"reinforcement_issue","param":"s"}]
# Failure-path seeds (report口径): ENTRIES arms + FACT_UNITS producers + the five debug
# verifiers + game.validate() + get_view/GameView.build; closure edges = same-file calls,
# const-prefixed calls, g./self. calls (docs/spec/state-readers.md「失败面」).
const FAILURE_SEEDS=[["core/game.gd","command_fact"],["core/game.gd","_command_fact_row"],["core/game.gd","command_facts"],
 ["core/game.gd","validate"],["core/consumables.gd","validate_buffs"],["core/torso_binding.gd","state_issue"],
 ["data/special_equipment.gd","validate"],["core/card_effects.gd","validate"],["core/relic_effects.gd","validate"],
 ["core/game.gd","get_view"],["core/game_view.gd","build"]]

# ---------------------------------------------------------------- public interface

static func scan() -> Dictionary:
 var tables=_tables()
 var owners=tables.owners
 var aliases={}
 for declaration in ALIAS_DECLARATIONS:
  aliases[String(declaration.file)+"::"+String(declaration.function)]={"param":String(declaration.param),
   "fields":_receiver_fields(String(declaration.file),String(declaration.function),String(declaration.param))}
 var schema=_schema_strings()
 var direct={}
 var cells=0
 var sites=0
 for site in owners.keys():
  cells+=owners[site].size()
  for field in owners[site].keys():
   direct[field]=true
   sites+=int(owners[site][field])
 var read_face=direct.duplicate()
 for key in aliases.keys():
  for field in aliases[key].fields: read_face[field]=true
 for key in schema.keys():
  for field in schema[key].fields: read_face[field]=true
 var unread=[]
 for field in field_registry():
  if not read_face.has(field): unread.append(field)
 var stats={"inputs_sha256":_inputs_sha256(),"files":_rel_files(ALL_DIRS).size(),"fields":direct.size(),
  "cells":cells,"sites":sites,"whole_state":_sum(tables.whole),"ui_reads":tables.ui_reads.size()}
 var out={"schema":SCHEMA,"owners":owners,"ui_reads":tables.ui_reads,"whole_state":_whole_records(tables.whole),
  "aliases":{},"schema_strings":{},"unread_fields":unread,"generated_from":stats,"stats":stats,"unknown":tables.unknown}
 for key in _sorted_keys(aliases): out.aliases[key]={"param":String(aliases[key].param),"fields":aliases[key].fields}
 for key in _sorted_keys(schema): out.schema_strings[key]={"fields":schema[key].fields}
 return out

# The registered field face (sorted): literal `_init` keys plus late keys written in
# core|data|ui plus `state.get("X", …)` names.
static func field_registry() -> Array:
 var registry={}
 for key in _init_literal_keys(_source_text(REGISTRY_FILE)): registry[key]=true
 var patterns=_write_patterns()
 patterns.append(_re("\\bstate\\s*\\.\\s*get\\s*\\(\\s*(?:&\\s*)?\"([A-Za-z_][A-Za-z0-9_]*)\"\\s*,"))
 for rel in _rel_files(ALL_DIRS):
  for line in _source_text(rel).split("\n"):
   var code=String(line).split("#")[0]
   for pattern in patterns:
    for hit in pattern.search_all(code): registry[hit.get_string(1)]=true
 return _sorted_keys(registry)

# Failure-path face report (not a judgment): fields/cells/sites of the reads owned by the
# closure of the declared seeds, plus one row per registered command kind.
static func failure_face() -> Dictionary:
 var owners=_tables().owners
 var graph=_call_graph()
 var seeds={}
 for seed in FAILURE_SEEDS: seeds[String(seed[0])+"::"+String(seed[1])]=true
 var registry=_registry_seeds()
 for name in registry.arms: seeds["core/game.gd::"+name]=true
 var total=_face_row(owners,_closure(seeds.keys(),graph))
 var rows=[["all",total]]
 for kind in _sorted_keys(registry.kinds):
  var kind_seeds={"core/game.gd::command_fact":true,"core/game.gd::_command_fact_row":true}
  for name in registry.kinds[kind]: kind_seeds["core/game.gd::"+String(name)]=true
  rows.append([kind,_face_row(owners,_closure(kind_seeds.keys(),graph))])
 return {"fields":total.fields,"cells":total.cells,"sites":total.sites,"kinds":registry.kinds.size(),"rows":rows}

# The frozen shape of a derivation (report-only keys stripped) and its canonical serialization
# (sorted keys, no timestamps); --write and compare() both go through these.
static func body(value: Dictionary) -> Dictionary:
 var out=value.duplicate(true)
 out.erase("stats")
 out.erase("unknown")
 return out

static func canonical(value) -> String:
 return JSON.stringify(body(value),"",true)

static func compare(derived, frozen) -> Dictionary:
 var failure=frozen_error()
 if failure!="": return {"ok":false,"first_diff":failure}
 var diff=_first_diff(body(derived),body(frozen),"root")
 return {"ok":diff=="","first_diff":diff}

static func frozen() -> Dictionary:
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(FROZEN_PATH))
 return parsed if parsed is Dictionary else {}

static func frozen_error() -> String:
 var text=FileAccess.get_file_as_string(FROZEN_PATH)
 if text=="": return "frozen table is missing or unreadable: "+FROZEN_PATH
 var parsed=JSON.parse_string(text)
 if not (parsed is Dictionary): return "frozen table is not a JSON object: "+FROZEN_PATH
 if int(parsed.get("schema",0))!=SCHEMA: return "frozen table schema is not %d: %s" % [SCHEMA,FROZEN_PATH]
 return ""

# Code body of one declaration without its signature line (comment-truncated). "" when the
# declaration is absent: the reachability judgment needs that distinction.
static func function_body(rel: String, function: String) -> String:
 var text=_source_text(rel)
 var found=_re("(?m)^(?:static\\s+)?func\\s+"+function+"\\s*\\(").search(text)
 if found==null: return ""
 var cut=text.substr(found.get_end()).find("\n")
 if cut<0: return ""
 var rest=text.substr(found.get_end()+cut+1)
 var next=rest.find("\nfunc ")
 var static_next=rest.find("\nstatic func ")
 if static_next>=0 and (next<0 or static_next<next): next=static_next
 var code=""
 for line in (rest if next<0 else rest.substr(0,next)).split("\n"): code+=String(line).split("#")[0]+"\n"
 return code

# ----------------------------------------------------------------------- derivation

# Field counts aggregated by owner (`file::function` -> {field: count}), the ui face, the
# whole-state counts and unknown read names; one pass over every core|data|ui `.gd` line.
static func _tables() -> Dictionary:
 var registry={}
 for field in field_registry(): registry[field]=true
 var reads=_read_patterns("state")
 var whole_patterns={"duplicate":_re("\\bstate\\s*\\.\\s*duplicate\\s*\\("),
  "iterate":_re("\\bfor\\s+[A-Za-z_]\\w*\\s+in\\s+(?:g\\.)?state\\b(?!\\s*[.\\[])"),
  "has":_re("\\bstate\\s*\\.\\s*has\\s*\\("),
  "get_variable":_re("\\bstate\\s*\\.\\s*get\\s*\\(\\s*(?!&?\\s*\")"),
  "pass":_re("\\b(?:return\\s+)?(?:g\\.)?state\\s*[,)]")}
 var compound=_re("\\bstate\\s*\\.\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*[-+*/%&|^]=")
 var declaration=_re(DECLARATION)
 var writes=_write_patterns()
 var owners={}
 var ui_reads={}
 var whole={}
 var unknown=[]
 for rel in _rel_files(ALL_DIRS):
  var current="<file>"
  var ui=rel.begins_with("ui/")
  var lines=_source_text(rel).split("\n")
  for index in range(lines.size()):
   var code=String(lines[index]).split("#")[0]
   var declared=declaration.search(code)
   if declared!=null: current=declared.get_string(1)
   var skip={}
   for pattern in writes:
    for hit in pattern.search_all(code): skip[hit.get_start()]=true
   var hits=[]
   for hit in compound.search_all(code):
    skip[hit.get_start()]=true
    hits.append([hit.get_string(1),false])
   for form in range(reads.size()):
    for hit in reads[form].search_all(code):
     if skip.has(hit.get_start()): continue
     hits.append([hit.get_string(1),hit.get_string(1) in RESERVED_MEMBERS])
   for entry in hits:
    var name=String(entry[0])
    if bool(entry[1]): continue
    if not registry.has(name):
     if not ui: unknown.append(rel+"::"+current+":"+str(index+1)+" "+name)
     continue
    if ui:
     ui_reads[rel+"::"+current+":"+name]=true;continue
    var site=rel+"::"+current
    if not owners.has(site): owners[site]={}
    owners[site][name]=int(owners[site].get(name,0))+1
   if ui: continue
   for kind in whole_patterns.keys():
    # One count per line per kind; the forms are text matches, so a member access whose name is
    # `state` (x.state,) counts like the dictionary being handed over (docs/spec/state-readers.md 残差).
    var found=whole_patterns[kind].search(code)
    if found==null: continue
    var key=rel+"::"+current+"|"+kind
    whole[key]=int(whole.get(key,0))+1
 var sorted_owners={}
 for site in _sorted_keys(owners):
  var row={}
  for field in _sorted_keys(owners[site]): row[field]=int(owners[site][field])
  sorted_owners[site]=row
 return {"owners":sorted_owners,"ui_reads":_sorted_keys(ui_reads),"whole":whole,"unknown":unknown}

# `<param>.<field>` family of one alias declaration (same read forms, receiver replaced).
static func _receiver_fields(rel: String, function: String, param: String) -> Array:
 var body=function_body(rel,function)
 if body=="": return []
 var registry={}
 for field in field_registry(): registry[field]=true
 var patterns=_read_patterns(param)
 var fields={}
 for line in body.split("\n"):
  for pattern in patterns:
   for hit in pattern.search_all(String(line)):
    var name=hit.get_string(1)
    if name not in RESERVED_MEMBERS and registry.has(name): fields[name]=true
 return _sorted_keys(fields)

static func _schema_strings() -> Dictionary:
 var pattern=_re("Snapshot\\.fields\\s*\\(\\s*(?:g\\.)?state\\s*,\\s*\"([^\"]*)\"")
 var declaration=_re(DECLARATION)
 var records={}
 for rel in _rel_files(ALL_DIRS):
  var current="<file>"
  for line in _source_text(rel).split("\n"):
   var code=String(line).split("#")[0]
   var declared=declaration.search(code)
   if declared!=null: current=declared.get_string(1)
   for hit in pattern.search_all(code):
    var key=rel+"::"+current
    if not records.has(key): records[key]={}
    for entry in hit.get_string(1).split(" ",false):
     var name=String(entry).split(":")[0]
     if name!="": records[key][name]=true
 var out={}
 for key in records.keys(): out[key]={"fields":_sorted_keys(records[key])}
 return out

# -------------------------------------------------------------------- call closure

# `{site: [targets]}` over declared functions; bodies are the raw declaration-to-declaration
# text and edges are bare same-file calls, `g.` calls into core/game.gd, const-prefixed calls
# (`Cards.validate(...)` / `g.Cards.validate(...)`) and `self.` calls.
static func _call_graph() -> Dictionary:
 var bodies={}
 var consts={}
 for rel in _rel_files(ALL_DIRS):
  var index=_file_index(rel)
  bodies[rel]=index.bodies
  consts[rel]=index.consts
 var bare=_re("(?<![\\w.])([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")
 var dotted=_re("(?<![\\w.])([A-Za-z_][A-Za-z0-9_]*)\\s*\\.\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")
 var g_const=_re("(?<![\\w.])g\\s*\\.\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*\\.\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")
 var edges={}
 for rel in bodies.keys():
  for function in bodies[rel].keys():
   var body=String(bodies[rel][function])
   var targets={}
   for hit in bare.search_all(body):
    if bodies[rel].has(hit.get_string(1)): targets[rel+"::"+hit.get_string(1)]=true
   for hit in dotted.search_all(body):
    var edge=_edge(rel,hit.get_string(1),hit.get_string(2),bodies,consts)
    if edge!="": targets[edge]=true
   for hit in g_const.search_all(body):
    var edge=_edge("core/game.gd",hit.get_string(1),hit.get_string(2),bodies,consts)
    if edge!="": targets[edge]=true
   edges[rel+"::"+function]=targets.keys()
 return {"edges":edges}

static func _edge(rel: String, head: String, member: String, bodies: Dictionary, consts: Dictionary) -> String:
 if head=="" or head=="self": return rel+"::"+member if bodies.get(rel,{}).has(member) else ""
 if head=="g": return "core/game.gd::"+member if bodies.get("core/game.gd",{}).has(member) else ""
 if consts.get(rel,{}).has(head):
  var target=String(consts[rel][head])
  return target+"::"+member if bodies.get(target,{}).has(member) else ""
 return ""

static func _file_index(rel: String) -> Dictionary:
 var declaration=_re(DECLARATION)
 var const_pattern=_re("^\\s*const\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*preload\\(\"res://([^\"]+)\"\\)")
 var bodies={}
 var consts={}
 var current=""
 var body=""
 for line in _source_text(rel).split("\n"):
  var found=const_pattern.search(String(line))
  if found!=null: consts[found.get_string(1)]=found.get_string(2)
  var declared=declaration.search(String(line))
  if declared==null:
   if current!="": body+=String(line)+"\n"
   continue
  if current!="": bodies[current]=body
  current=declared.get_string(1)
  body=""
 if current!="": bodies[current]=body
 return {"bodies":bodies,"consts":consts}

static func _closure(seeds: Array, graph: Dictionary) -> Dictionary:
 var seen={}
 var frontier=seeds.duplicate()
 while not frontier.is_empty():
  var node=String(frontier.pop_back())
  if seen.has(node) or not graph.edges.has(node): continue
  seen[node]=true
  for target in graph.edges[node]:
   if not seen.has(target): frontier.append(target)
 return seen

# Registry arms: every method named by ENTRIES (source/keys/build/member) and FACT_UNITS
# (producer); per-kind seeds: the point form's keys/build/member or the table form's source.
static func _registry_seeds() -> Dictionary:
 var text=_source_text(REGISTRY_ENTRIES)
 var arms={}
 for hit in _re("\"(?:source|keys|build|member|producer)\":\"([A-Za-z_][A-Za-z0-9_]*)\"").search_all(text): arms[hit.get_string(1)]=true
 var kinds={}
 var point=_re("\"([a-z_]+)\":\\{\"form\":\"point\",\"keys\":\"([A-Za-z_][A-Za-z0-9_]*)\",\"build\":\"([A-Za-z_][A-Za-z0-9_]*)\",\"member\":\"([A-Za-z_][A-Za-z0-9_]*)\"\\}")
 for hit in point.search_all(text): kinds[hit.get_string(1)]=[hit.get_string(2),hit.get_string(3),hit.get_string(4)]
 var table=_re("\"([a-z_]+)\":\\{\"form\":\"table\",\"source\":\"([A-Za-z_][A-Za-z0-9_]*)\"\\}")
 for hit in table.search_all(text):
  if not kinds.has(hit.get_string(1)): kinds[hit.get_string(1)]=[hit.get_string(2)]
 return {"arms":_sorted_keys(arms),"kinds":kinds}

static func _face_row(owners: Dictionary, face: Dictionary) -> Dictionary:
 var fields={}
 var cells=0
 var sites=0
 for site in owners.keys():
  if not face.has(site): continue
  cells+=owners[site].size()
  for field in owners[site].keys():
   fields[field]=true
   sites+=int(owners[site][field])
 return {"fields":fields.size(),"cells":cells,"sites":sites}

# ------------------------------------------------------------------------- helpers

# The three read forms for one receiver name: `<receiver>.<field>`, `<receiver>["<field>"]` and
# `<receiver>.get("<field>"…)`. The state face (receiver `state`) and the alias receivers share this
# single definition, so a read form is added or changed in exactly one place.
static func _read_patterns(receiver: String) -> Array:
 var head="\\b"+receiver.replace("\\","\\\\")
 return [_re(head+"\\s*\\.\\s*([A-Za-z_][A-Za-z0-9_]*)"),
  _re(head+"\\s*\\[\\s*(?:&\\s*)?\"([A-Za-z_][A-Za-z0-9_]*)\"\\s*\\]"),
  _re(head+"\\s*\\.\\s*get\\s*\\(\\s*(?:&\\s*)?\"([A-Za-z_][A-Za-z0-9_]*)\"")]

static func _write_patterns() -> Array:
 return [_re("\\bstate\\s*\\.\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*(?<![=<>!+\\-*/%&|^])=(?!=)"),
  _re("\\bstate\\s*\\[\\s*(?:&\\s*)?\"([A-Za-z_][A-Za-z0-9_]*)\"\\s*\\]\\s*(?<![=<>+\\-*/%&|^])=(?!=)")]

# Depth-1 quoted keys of the `_init` state literal (a key is followed by `:`; nested records
# and string values never are at this level).
static func _init_literal_keys(text: String) -> Array:
 var at=text.find("{",text.find("state = {"))
 if at<0: return []
 var keys=[]
 var depth=0
 var index=at
 while index<text.length():
  var character=text[index]
  if character=="{": depth+=1
  elif character=="}":
   depth-=1
   if depth==0: break
  elif character=="\"":
   var close=text.find("\"",index+1)
   if close<0: break
   if depth==1 and text.substr(close+1).strip_edges().begins_with(":"): keys.append(text.substr(index+1,close-index-1))
   index=close
  index+=1
 return keys

static func _inputs_sha256() -> String:
 var lines=[]
 for rel in _rel_files(ALL_DIRS): lines.append(rel+":"+SourceText.normalized_text_sha256("res://"+rel))
 return "\n".join(lines).sha256_text()

static func _rel_files(dirs: Array) -> Array:
 var out=[]
 for directory in dirs:
  var pending=["res://"+String(directory)]
  while not pending.is_empty():
   var current=String(pending.pop_back())
   var handle=DirAccess.open(current)
   if handle==null: continue
   for name in handle.get_files():
    if String(name).ends_with(".gd"): out.append(current+"/"+name)
   for name in handle.get_directories(): pending.append(current+"/"+name)
 out.sort()
 return out.map(func(path):return String(path).trim_prefix("res://"))

static var _text_cache={}

static func _source_text(rel: String) -> String:
 if _text_cache.has(rel): return String(_text_cache[rel])
 var text=SourceText.normalized_text("res://"+rel)
 _text_cache[rel]=text
 return text

static func _re(pattern: String) -> RegEx:
 var compiled=RegEx.new()
 compiled.compile(pattern)
 return compiled

static func _sorted_keys(values: Dictionary) -> Array:
 var out=values.keys().map(func(key):return String(key))
 out.sort()
 return out

static func _sum(values: Dictionary) -> int:
 var total=0
 for key in values.keys(): total+=int(values[key])
 return total

static func _whole_records(whole: Dictionary) -> Array:
 var records=[]
 for key in _sorted_keys(whole):
  var parts=String(key).split("|")
  var site=String(parts[0]).split("::")
  records.append({"file":site[0],"function":site[1],"kind":String(parts[1]),"count":int(whole[key])})
 return records

static func _first_diff(a, b, at: String) -> String:
 var numeric=(typeof(a)==TYPE_INT or typeof(a)==TYPE_FLOAT) and (typeof(b)==TYPE_INT or typeof(b)==TYPE_FLOAT)
 if numeric: return "" if is_equal_approx(float(a),float(b)) else at+" (%s vs %s)" % [str(a),str(b)]
 if typeof(a)!=typeof(b): return at+" (type)"
 if a is Dictionary:
  var keys={}
  for key in a.keys(): keys[key]=true
  for key in b.keys(): keys[key]=true
  for key in _sorted_keys(keys):
   if not a.has(key): return at+"."+String(key)+" (missing on left)"
   if not b.has(key): return at+"."+String(key)+" (missing on right)"
   var found=_first_diff(a[key],b[key],at+"."+String(key))
   if found!="": return found
  return ""
 if a is Array:
  if a.size()!=b.size(): return at+" (size %d vs %d)" % [a.size(),b.size()]
  for index in range(a.size()):
   var found=_first_diff(a[index],b[index],"%s[%d]" % [at,index])
   if found!="": return found
  return ""
 return "" if a==b else at+" (%s vs %s)" % [str(a),str(b)]
