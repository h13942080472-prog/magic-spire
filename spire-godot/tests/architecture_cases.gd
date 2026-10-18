extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const GameCore=preload("res://core/game.gd")
const CommandRegistry=preload("res://core/command_registry.gd")
const Rewards=preload("res://tests/reward_cases.gd")
const Guard=preload("res://core/guard.gd")
const FirstTurnControl=preload("res://core/first_turn_control.gd")
const Store=preload("res://core/save_store.gd")
const EventCases=preload("res://tests/event_cases.gd")

# docs/spec/ondemand-copy.md「oracle 三条（必须换判据）」: frozen hashes recomputed with
# unmodified source on 2026-09-15 (candidates_sha256, view_sha256) for copy_baseline_fixture.
const COPY_BASELINE={
 "battle:0":["bf8d97d58f3be03b42cb65ee5b36afebca335f25e496fbb3301db3285fcc46fe","e2b375c5019c2ccae9d088a5050b9ee445d199f74c0e524e9e63cd2bc6ccfb4a"],
 "battle:12":["c07e59259326f1ec2e380bcc1d7f2ed8e9b05e8442f16b3bb288133ff2b9a6df","81f7796e55826b580131762445db711651815b83b7bb0a9ab89560971ccb2f32"],
 "battle:26":["361c37774a2901bb985926fe0ce4dd9bb4f1c2e7b349d6fb39dca2a9f59d91d8","f7401077920a93d96b699052708a19597ffaa02496c0925b4578aee61469fc06"],
 "departure:0":["74b735a41f761e8bae611d38bffc58b103c40f1d534ba086f00bc30f2dd9fc3c","472f1bd7efbd2271be1e720ffff59d284d43081eb4a41362fe49d0a2362933cd"],
 "departure:12":["74b735a41f761e8bae611d38bffc58b103c40f1d534ba086f00bc30f2dd9fc3c","c0d28042a3cfefcf74c4ec3a6df1b28ccad66dee8ab9e576ccee83ca832dc150"],
 "departure:26":["74b735a41f761e8bae611d38bffc58b103c40f1d534ba086f00bc30f2dd9fc3c","92ce21c9462bcdb8cdbd8b78793d78f61f398a3260fb1a0fe5c1701e94b336a7"],
}

static func ids_for(values: Array) -> Array:
 return values.map(func(e):return e.get("id",""))

# docs/spec/transition-pipeline.md「证据入口」：读进程内迁移日志（生产代码不带计数器）。
static func transition_log(g) -> Array:
 var log=g.get("_transition_log")
 return log.duplicate() if log is Array else []

static func transition_delta(g, before: Array) -> Array:
 var log=transition_log(g)
 return log.slice(before.size()) if log.size()>=before.size() else log

static func transition_kinds(delta: Array, prefix: String) -> Array:
 return delta.filter(func(kind):return String(kind).begins_with(prefix))

# docs/spec/transition-pipeline.md「证据入口」：闭环 check 的扫描面。四组模式各自的正则；注释按 `#` 之后截断，
# `==` 以 `[^=]` 排除。返回 {counts: {"文件|函数|组": 次数}, sites: {key: ["文件:行:函数", ...]}}。
const TRANSITION_PATTERNS={
 "room":"(?:g\\.)?state\\.room\\s*=[^=]",
 "phase":"(?:g\\.)?state\\.phase\\s*=[^=]",
 "battle_end":"_finish_battle\\(|_finish_if_saturated\\(|_battle_end_reason\\(",
 "tower_restart":"_restart_tower\\(",
}

# Every source file below a res:// directory matching one of the declared extensions (default
# .gd), sorted; the single enumerator for source scans.
static func script_files(root: String, extensions: Array=[".gd"]) -> Array:
 var result=[]
 var pending=[root]
 while not pending.is_empty():
  var directory=String(pending.pop_back())
  var handle=DirAccess.open(directory)
  if handle==null: continue
  for name in handle.get_files():
   for extension in extensions:
    if String(name).ends_with(extension):
     result.append(directory+"/"+name)
     break
  for name in handle.get_directories(): pending.append(directory+"/"+name)
 result.sort()
 return result

static func transition_core_files() -> Array:
 return script_files("res://core")

static func transition_scan() -> Dictionary:
 var compiled={}
 for group in TRANSITION_PATTERNS:
  var regex=RegEx.new()
  regex.compile(TRANSITION_PATTERNS[group])
  compiled[group]=regex
 var counts={};var sites={}
 var declaration=RegEx.new()
 declaration.compile("^\\s*(?:static\\s+)?func\\s+([A-Za-z_][A-Za-z0-9_]*)")
 for path in transition_core_files():
  var file=FileAccess.open(path,FileAccess.READ)
  if file==null: continue
  var lines=file.get_as_text().split("\n")
  var current="<file>"
  for index in range(lines.size()):
   var raw=String(lines[index])
   var code=raw.split("#")[0]
   var declared=declaration.search(code)
   if declared!=null: current=declared.get_string(1)
   for group in compiled:
    for hit in compiled[group].search_all(code):
     var key=path+"|"+current+"|"+group
     counts[key]=int(counts.get(key,0))+1
     if not sites.has(key): sites[key]=[]
     sites[key].append(path+":"+str(index+1)+":"+current)
 return {"counts":counts,"sites":sites}

# docs/spec/transition-pipeline.md「证据入口」：写入点双向比对——扫描集 ⊆ 声明表 且 表内每一点都被
# 扫到；表外或未命中都打印 `文件:行:函数`。表内每项＝(文件, 函数, 组, 行数)。
# ③ 的 8 个函数＝迁移声明表中的"8 个语义入口"（13 个引用点保留为同一批函数；收束后一个位点由
# "判定一行＋执行一行"两行承载，故行数大于 13，函数集不变）。
const TRANSITION_SITES=[
 {"file":"res://core/game.gd","func":"_apply_transition","group":"room","count":1},
 {"file":"res://core/game.gd","func":"_apply_transition","group":"phase","count":1},
 {"file":"res://core/game.gd","func":"_battle_end_reason","group":"battle_end","count":1},
 {"file":"res://core/game.gd","func":"_finish_battle","group":"battle_end","count":1},
 {"file":"res://core/game.gd","func":"_finish_if_saturated","group":"battle_end","count":4},
 {"file":"res://core/game.gd","func":"_start_round","group":"battle_end","count":2},
 {"file":"res://core/game.gd","func":"_enemy_phase","group":"battle_end","count":4},
 {"file":"res://core/game.gd","func":"dispatch","group":"battle_end","count":3},
 {"file":"res://core/game.gd","func":"_execute","group":"battle_end","count":2},
 {"file":"res://core/game.gd","func":"_end_turn","group":"battle_end","count":2},
 {"file":"res://core/game.gd","func":"_restart_tower","group":"tower_restart","count":1},
 {"file":"res://core/demo_exit.gd","func":"continue_run","group":"tower_restart","count":1},
 {"file":"res://core/prison.gd","func":"return_to_tower","group":"tower_restart","count":1},
 {"file":"res://core/prison.gd","func":"completed_turn","group":"tower_restart","count":1},
]
const TRANSITION_BATTLE_END_FUNCTIONS=["_battle_end_reason","_end_turn","_enemy_phase","_execute","_finish_battle","_finish_if_saturated","_start_round","dispatch"]

static func transition_write_sites_are_pinned(t) -> void:
 var scan=transition_scan()
 var counts=scan.counts
 var sites=scan.sites
 var table={}
 for entry in TRANSITION_SITES:
  table[String(entry.file)+"|"+String(entry.func)+"|"+String(entry.group)]=int(entry.count)
 var keys=counts.keys()
 keys.sort()
 var outside=[]
 for key in keys:
  if not table.has(key): outside.append(str(sites[key]))
 t.check(outside.is_empty(),"ARCH transition scan finds no write site outside the pinned table: "+str(outside))
 var missing=[]
 for key in table:
  var found=int(counts.get(key,0))
  if found!=table[key]: missing.append(key+" expected "+str(table[key])+" found "+str(found)+" "+str(sites.get(key,[])))
 t.check(missing.is_empty(),"ARCH every pinned transition write site is scanned at its declared size: "+str(missing))
 var owners=[]
 for key in keys:
  if not String(key).ends_with("|battle_end"): continue
  var owner=String(key).split("|")[1]
  if owner not in owners: owners.append(owner)
 owners.sort()
 t.check(owners==TRANSITION_BATTLE_END_FUNCTIONS,"ARCH every battle-end decision lives in the eight declared entries: "+str(owners))
 t.check(int(counts.get("res://core/game.gd|_apply_transition|room",0))==1 and int(counts.get("res://core/game.gd|_apply_transition|phase",0))==1,"ARCH state.phase and state.room have exactly one write site each: "+str([counts.get("res://core/game.gd|_apply_transition|room",0),counts.get("res://core/game.gd|_apply_transition|phase",0)]))

# docs/spec/save-fixed-points.md「证据入口」：进度固定点集合＝声明表里标了 checkpoint 列的 kind（固定清单，
# 多标一个或少标一个都红），且每个 checkpoint 名字都必须出现在 CHECKPOINT_PRIORITY 里。
const SAVE_CHECKPOINT_KINDS={
 "battle_end_captured":"battle_end",
 "battle_end_saturated":"battle_end",
 "battle_end_victory":"battle_end",
 "floor_enter":"floor",
 "prepare_end":"prepare_end",
}

static func save_checkpoint_kinds_are_pinned(t) -> void:
 var declared={}
 var wrong=[]
 for kind in GameCore.TRANSITIONS:
  var point=String(GameCore.TRANSITIONS[kind].get("checkpoint",""))
  if point=="": continue
  declared[kind]=point
  if point not in ["battle_end","prepare_end","floor"]: wrong.append(kind+"->"+point)
 t.check(wrong.is_empty(),"ARCH every declared fixed point uses a legal checkpoint name: "+str(wrong))
 var missing=[]
 for kind in SAVE_CHECKPOINT_KINDS:
  if not declared.has(kind) or declared[kind]!=SAVE_CHECKPOINT_KINDS[kind]: missing.append(kind+"->"+str(declared.get(kind,"<missing>")))
 var extra=[]
 for kind in declared:
  if not SAVE_CHECKPOINT_KINDS.has(kind): extra.append(kind+"->"+declared[kind])
 t.check(missing.is_empty(),"ARCH every pinned fixed-point kind stays declared with its own checkpoint name: "+str(missing))
 t.check(extra.is_empty(),"ARCH no transition kind beyond the three fixed points is marked as one: "+str(extra))
 t.check(declared.size()==SAVE_CHECKPOINT_KINDS.size(),"ARCH the fixed-point declaration set keeps the pinned size: "+str(declared.size()))
 var names=[]
 for kind in declared:
  if not names.has(declared[kind]): names.append(declared[kind])
 names.sort()
 var priority=Array(GameCore.CHECKPOINT_PRIORITY).duplicate()
 priority.sort()
 t.check(names==priority,"ARCH the simultaneous-hit priority resolves exactly the declared checkpoint names: "+str(names)+"/"+str(priority))

# docs/spec/event-pipeline.md「依赖规范」: the event modules preload exactly the
# declared registry edges; one edge more or less fails, and no core file may reach ui/.
static func event_dependency_edges_pinned(t) -> void:
 var expected={"res://core/room_events.gd":["res://data/room_events.gd","res://data/relics.gd"],"res://core/content_catalog.gd":[],"res://core/snapshot.gd":["res://data/phases.gd"]}
 var pattern=RegEx.new()
 pattern.compile("preload\\(\"res://[^\"]+\"\\)")
 for path in expected:
  var file=FileAccess.open(path,FileAccess.READ)
  t.check(file!=null,"ARCH event module is readable for its dependency edges "+path)
  if file==null: continue
  var found=[]
  for hit in pattern.search_all(file.get_as_text()):
   var target=hit.get_string().trim_prefix("preload(\"").trim_suffix("\")")
   if target not in found: found.append(target)
  found.sort()
  var want=expected[path].duplicate();want.sort()
  t.check(found==want,"ARCH event dependency edges pinned "+path+": "+str(found))
 var ui_pattern=RegEx.new()
 ui_pattern.compile("ui/")
 for path in expected:
  var file=FileAccess.open(path,FileAccess.READ)
  if file==null: continue
  t.check(ui_pattern.search(file.get_as_text())==null,"ARCH core event module never names ui/ "+path)

# The pack root is one constant behind one accessor: the decision must not regain a build-type
# branch or the deleted switch／probe／cache, and no other product file computes a packs path.
static func content_pack_root_has_no_build_feature_branch(t) -> void:
 var file=FileAccess.open("res://core/content_catalog.gd",FileAccess.READ)
 t.check(file!=null,"ARCH content catalog is readable for the pack-root scan")
 if file==null: return
 var source=file.get_as_text()
 for feature in ["has_feature(\"editor\")","has_feature(\"android\")"]:
  t.check(not source.contains(feature),"ARCH the pack root carries no build-feature branch: "+feature)
 t.check(source.contains("const PACKS_ROOT := \"res://content/packs\"") and source.contains("static func packs_root()"),"ARCH the pack root is one constant behind the single packs_root entry")
 for removed in ["packs_root_switch","resolve_packs_root","packs_root_cache"]:
  t.check(not source.contains(removed),"ARCH the pack root keeps no runtime switch, probe or cache: "+removed)
 var strays=[]
 for path in script_files("res://core")+script_files("res://ui")+script_files("res://data"):
  if path=="res://core/content_catalog.gd": continue
  var handle=FileAccess.open(path,FileAccess.READ)
  if handle!=null and handle.get_as_text().contains("content/packs"): strays.append(path)
 t.check(strays.is_empty(),"ARCH only core/content_catalog.gd computes a content packs path: "+str(strays))

# The present pipeline adjacency table (ui/main.gd::PRESENT_ADJACENCY) is guarded here. Its
# membership rule is the table header comment; this gate holds three mechanical checks:
#  1. every declared edge has a direct call in its parent body;
#  2. a table symbol a registered parent calls directly is declared;
#  3. no dead entry: no phantom symbol, no orphan or unreachable row.
# The completeness floor added below is a separate group of criteria: every table symbol has a
# row, PRESENT_SECTIONS matches the present() dispatch arms, every pipeline-shaped routine is a
# row, the full-render fallback stays declared, and the symbol count stays at or above the
# frozen floor. The table header and skills/spire-docs/SKILL.md describe the same contract.
# Parent bodies are read from ui/main.gd, except the external owners declared below (the only
# cross-file parent body read is header.configure, for its header._presentation_key child).
const PRESENT_SOURCE="res://ui/main.gd"
const PRESENT_ROOT="present"
# Pipeline naming shapes: the single mechanical declaration of which routine names must be rows.
# These are shapes, not a function-name roster; the prose lives in the table header.
const PRESENT_PIPELINE_SHAPES=[
 "^_refresh_[a-z0-9_]+_section$",
 "^_sync_[a-z0-9_]+$",
 "^_build_[a-z0-9_]+$",
 "^[a-z0-9_]+_presentation_key$",
 "^_[a-z0-9_]+_key_hit$",
 "^_unload_[a-z0-9_]+_section$",
 "^_[a-z0-9_]+_need_full$",
]
const PRESENT_PIPELINE_EXACT=["render","_present_needs_full_render"]
# Frozen lower bound for the table symbol count (keys and children). It only goes up; lowering it
# requires an explicit same-batch reason in the commit message.
const PRESENT_SYMBOL_FLOOR=108
# External boundary symbols: owner prefix (dotted symbol) or bare name -> source file.
const PRESENT_EXTERNAL_OWNERS={
 "header":"res://ui/shell/header.gd",
 "layout":"res://ui/shell/game_layout.gd",
 "EquipmentPortrait":"res://ui/equipment_portrait.gd",
 "CardFace":"res://ui/card_face.gd",
 "configure_enemy":"res://ui/arena.gd",
}

static func present_source_text(path: String) -> String:
 var handle=FileAccess.open(path,FileAccess.READ)
 return "" if handle==null else handle.get_as_text()

# Top-level function bodies of one file: name -> body (comments kept; callers strip them).
static func present_function_bodies(path: String) -> Dictionary:
 var declaration=RegEx.new()
 declaration.compile("^\\s*(?:static\\s+)?func\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")
 var bodies={}
 var current=""
 var buffer=[]
 for line in present_source_text(path).split("\n"):
  var declared=declaration.search(line)
  if declared!=null:
   if current!="": bodies[current]="\n".join(buffer)
   current=declared.get_string(1)
   buffer=[]
  elif current!="":
   buffer.append(line)
 if current!="": bodies[current]="\n".join(buffer)
 return bodies

static func present_code(body: String) -> String:
 var lines=[]
 for line in body.split("\n"): lines.append(String(line).split("#")[0])
 return "\n".join(lines)

# A direct call of `leaf`: bare `leaf(` or member `.leaf(`, not preceded by a word character or dot.
static func present_called(body: String, leaf: String) -> bool:
 var code=present_code(body)
 var bare=RegEx.new()
 bare.compile("(?:^|[^A-Za-z0-9_.])"+leaf+"\\s*\\(")
 if bare.search(code)!=null: return true
 var member=RegEx.new()
 member.compile("\\."+leaf+"\\s*\\(")
 return member.search(code)!=null

# Parse the PRESENT_ADJACENCY literal straight from the source text (entry order preserved).
static func present_adjacency_table() -> Dictionary:
 var source=present_source_text(PRESENT_SOURCE)
 var start=source.find("const PRESENT_ADJACENCY=")
 if start<0: return {}
 var open=source.find("{",start)
 if open<0: return {}
 var depth=0
 var close=-1
 for index in range(open,source.length()):
  var character=source[index]
  if character=="{": depth+=1
  elif character=="}":
   depth-=1
   if depth==0:
    close=index
    break
 if close<0: return {}
 var literal=source.substr(open,close-open+1)
 var entries={}
 var entry=RegEx.new()
 entry.compile("\"([^\"]+)\"\\s*:\\s*\\[([^\\]]*)\\]")
 var child=RegEx.new()
 child.compile("\"([^\"]+)\"")
 for hit in entry.search_all(literal):
  var children=[]
  for item in child.search_all(hit.get_string(2)): children.append(item.get_string(1))
  entries[hit.get_string(1)]=children
 return entries

# Resolve a table symbol to [bodies: Dictionary, leaf: String]; [] when its owner is undeclared.
static func present_symbol_body(symbol: String, main_bodies: Dictionary, external: Dictionary) -> Array:
 if symbol.contains("."):
  var parts=symbol.split(".")
  var owner=String(parts[0])
  if not PRESENT_EXTERNAL_OWNERS.has(owner): return []
  if not external.has(owner): external[owner]=present_function_bodies(String(PRESENT_EXTERNAL_OWNERS[owner]))
  return [external[owner],String(parts[parts.size()-1])]
 if PRESENT_EXTERNAL_OWNERS.has(symbol):
  if not external.has(symbol): external[symbol]=present_function_bodies(String(PRESENT_EXTERNAL_OWNERS[symbol]))
  return [external[symbol],symbol]
 return [main_bodies,symbol]

static func present_body_of(symbol: String, main_bodies: Dictionary, external: Dictionary) -> String:
 var resolved=present_symbol_body(symbol,main_bodies,external)
 if resolved.is_empty(): return ""
 var bodies=resolved[0] as Dictionary
 var leaf=String(resolved[1])
 return "" if not bodies.has(leaf) else String(bodies[leaf])

static func present_symbol_resolves(symbol: String, main_bodies: Dictionary, external: Dictionary) -> bool:
 var resolved=present_symbol_body(symbol,main_bodies,external)
 if resolved.is_empty(): return false
 return (resolved[0] as Dictionary).has(String(resolved[1]))

static func present_adjacency_graph_is_pinned(t) -> void:
 var table=present_adjacency_table()
 t.check(not table.is_empty(),"ARCH present_adjacency_graph_is_pinned: ui/main.gd::PRESENT_ADJACENCY is readable")
 if table.is_empty(): return
 var main_bodies=present_function_bodies(PRESENT_SOURCE)
 var external={}
 # 1) Every declared edge is a direct call in its parent body (lambdas and chained calls included).
 var missing=[]
 for parent in table:
  var body=present_body_of(String(parent),main_bodies,external)
  if body=="":
   missing.append(String(parent)+" has no readable body")
   continue
  for child in table[parent]:
   if not present_called(body,String(child).split(".")[-1]): missing.append(String(parent)+" -> "+String(child))
 t.check(missing.is_empty(),"ARCH present_adjacency_graph_is_pinned: every declared edge has a direct call in its parent body: "+str(missing))
 # 2) A table symbol a registered ui/main.gd parent calls directly must be declared.
 var tracked=[]
 for parent in table:
  for symbol in table[parent]:
   if not String(symbol).contains(".") and String(symbol) not in tracked: tracked.append(String(symbol))
  if not String(parent).contains(".") and String(parent) not in tracked: tracked.append(String(parent))
 var undeclared=[]
 for parent in table:
  if not main_bodies.has(parent): continue
  var declared=[]
  for child in table[parent]: declared.append(String(child).split(".")[-1])
  for name in tracked:
   if name==String(parent) or name in declared: continue
   if present_called(String(main_bodies[parent]),name): undeclared.append(String(parent)+" calls "+name+"()")
 t.check(undeclared.is_empty(),"ARCH present_adjacency_graph_is_pinned: a table symbol a registered parent calls directly is declared: "+str(undeclared))
 # 3a) No orphan row: every row but the root has a declared incoming edge.
 var incoming={}
 for parent in table:
  for child in table[parent]:
   if not incoming.has(child): incoming[child]=[]
   incoming[child].append(parent)
 var orphan=[]
 for key in table:
  if String(key)!=PRESENT_ROOT and not incoming.has(key): orphan.append(String(key))
 t.check(orphan.is_empty(),"ARCH present_adjacency_graph_is_pinned: every row but the root has an incoming edge: "+str(orphan))
 # 3b) Every row is reachable from the root by declared edges.
 var reached=[]
 var pending=[PRESENT_ROOT]
 while not pending.is_empty():
  var node=String(pending.pop_back())
  if node in reached: continue
  reached.append(node)
  for child in table.get(node,[]):
   if String(child) not in reached: pending.append(String(child))
 var unreachable=[]
 for key in table:
  if String(key) not in reached: unreachable.append(String(key))
 t.check(unreachable.is_empty(),"ARCH present_adjacency_graph_is_pinned: every row is reachable from the root: "+str(unreachable))
 # 3c) No phantom symbol: every key and child resolves to a declared function in its owning file.
 var phantom=[]
 for parent in table:
  if not present_symbol_resolves(String(parent),main_bodies,external): phantom.append(String(parent))
  for child in table[parent]:
   if not present_symbol_resolves(String(child),main_bodies,external): phantom.append(String(parent)+" -> "+String(child))
 t.check(phantom.is_empty(),"ARCH present_adjacency_graph_is_pinned: every table symbol resolves to a declared function: "+str(phantom))

static func present_symbol_set(table: Dictionary) -> Array:
 var symbols=[]
 for parent in table:
  if String(parent) not in symbols: symbols.append(String(parent))
  for child in table[parent]:
   if String(child) not in symbols: symbols.append(String(child))
 return symbols

# The sections declared by ui/main.gd::PRESENT_SECTIONS (entry order preserved).
static func present_sections() -> Array:
 var source=present_source_text(PRESENT_SOURCE)
 var start=source.find("const PRESENT_SECTIONS")
 if start<0: return []
 var equals=source.find("=",start)
 if equals<0: return []
 var open=source.find("[",equals)
 var close=source.find("]",open)
 if open<0 or close<0: return []
 var sections=[]
 var item=RegEx.new()
 item.compile("\"([^\"]+)\"")
 for hit in item.search_all(source.substr(open,close-open+1)): sections.append(hit.get_string(1))
 return sections

# Normalized arm target: header.configure, layout.body_sidebar or a bare local routine. Any other
# arm body (e.g. `pass`) yields an empty target so the caller marks the section red.
static func present_arm_target(line: String) -> String:
 if line.begins_with("layout.get_node(\"GameHeader\").configure("): return "header.configure"
 var member=RegEx.new()
 member.compile("^layout\\.([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")
 var hit=member.search(line)
 if hit!=null: return "layout."+hit.get_string(1)
 var bare=RegEx.new()
 bare.compile("^([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")
 hit=bare.search(line)
 if hit!=null: return hit.get_string(1)
 return ""

# Section -> normalized arm target from the present() body. A repeated arm is kept as a
# "<duplicate>" target so the caller can name it in the failure sample.
static func present_dispatch_arms(body: String) -> Dictionary:
 var arms={}
 var seen={}
 var declaration=RegEx.new()
 declaration.compile("^(\\s*)(?:if|elif)\\s+section\\s*==\\s*\"([^\"]+)\"\\s*:\\s*$")
 var lines=body.split("\n")
 for index in range(lines.size()):
  var hit=declaration.search(String(lines[index]))
  if hit==null: continue
  var indent=hit.get_string(1).length()
  var section=hit.get_string(2)
  var target=""
  for next in range(index+1,lines.size()):
   var line=String(lines[next])
   var stripped=line.strip_edges()
   if stripped=="" or stripped.begins_with("#"): continue
   var line_indent=line.length()-line.strip_edges(true,false).length()
   if line_indent<=indent: break
   target=present_arm_target(stripped)
   break
  if seen.has(section):
   arms[section]="<duplicate>"
  else:
   seen[section]=true
   arms[section]=target
 return arms

# C1: every symbol named anywhere in the table (key or child) has its own row.
static func present_adjacency_rows_are_complete(t) -> void:
 var table=present_adjacency_table()
 t.check(not table.is_empty(),"ARCH present_adjacency_rows_are_complete: ui/main.gd::PRESENT_ADJACENCY is readable")
 if table.is_empty(): return
 var missing=[]
 for symbol in present_symbol_set(table):
  if not table.has(symbol): missing.append(String(symbol))
 t.check(missing.is_empty(),"ARCH present_adjacency_rows_are_complete: every table symbol has its own row: "+str(missing.slice(0,4)))

# C2: PRESENT_SECTIONS and the present() dispatch arms are one-to-one (page excepted).
static func present_section_dispatch_is_total(t) -> void:
 var table=present_adjacency_table()
 var sections=present_sections()
 var body=String(present_function_bodies(PRESENT_SOURCE).get("present",""))
 t.check(not table.is_empty() and not sections.is_empty() and body!="","ARCH present_section_dispatch_is_total: the table, PRESENT_SECTIONS and the present() body are readable")
 if table.is_empty() or sections.is_empty() or body=="": return
 var arms=present_dispatch_arms(body)
 var unknown=[]
 var duplicate=[]
 for section in arms:
  if String(section) not in sections: unknown.append(String(section))
  if String(arms[section])=="<duplicate>": duplicate.append(String(section))
 t.check(unknown.is_empty(),"ARCH present_section_dispatch_is_total: every arm routes a declared section: "+str(unknown.slice(0,4)))
 t.check(duplicate.is_empty(),"ARCH present_section_dispatch_is_total: no section has more than one arm: "+str(duplicate.slice(0,4)))
 var declared=[]
 for child in table.get(PRESENT_ROOT,[]): declared.append(String(child))
 var broken=[]
 for section in sections:
  if String(section)=="page":
   if arms.has(section): broken.append("page -> "+String(arms[section]))
   continue
  if not arms.has(section):
   broken.append(String(section)+" -> <missing>")
   continue
  var target=String(arms[section])
  if target=="" or target=="<duplicate>" or target not in declared: broken.append(String(section)+" -> "+target)
 t.check(broken.is_empty(),"ARCH present_section_dispatch_is_total: every section except page has one arm whose normalized target is declared on the present row: "+str(broken.slice(0,4)))

# C3: every ui/main.gd routine matching a frozen pipeline shape is a table row (and therefore,
# by present_adjacency_graph_is_pinned's reachability check, reachable from present).
static func present_pipeline_routines_are_registered(t) -> void:
 var table=present_adjacency_table()
 var bodies=present_function_bodies(PRESENT_SOURCE)
 t.check(not table.is_empty() and not bodies.is_empty(),"ARCH present_pipeline_routines_are_registered: the table and ui/main.gd function bodies are readable")
 if table.is_empty() or bodies.is_empty(): return
 var shapes=[]
 var broken_shapes=[]
 for pattern in PRESENT_PIPELINE_SHAPES:
  var regex=RegEx.new()
  if regex.compile(String(pattern))!=OK: broken_shapes.append(String(pattern))
  else: shapes.append(regex)
 t.check(broken_shapes.is_empty(),"ARCH present_pipeline_routines_are_registered: every frozen pipeline shape compiles: "+str(broken_shapes))
 var unregistered=[]
 for name in bodies:
  var matched=String(name) in PRESENT_PIPELINE_EXACT
  if not matched:
   for regex in shapes:
    if regex.search(String(name))!=null:
     matched=true
     break
  if matched and not table.has(String(name)): unregistered.append(String(name))
 t.check(unregistered.is_empty(),"ARCH present_pipeline_routines_are_registered: every pipeline-shaped routine is a table row: "+str(unregistered.slice(0,4)))

# C4: present declares and directly calls both the predicate and the full render fallback.
static func present_full_render_fallback_is_pinned(t) -> void:
 var table=present_adjacency_table()
 var body=String(present_function_bodies(PRESENT_SOURCE).get("present",""))
 t.check(not table.is_empty() and body!="","ARCH present_full_render_fallback_is_pinned: the table and the present() body are readable")
 if table.is_empty() or body=="": return
 var declared=[]
 for child in table.get(PRESENT_ROOT,[]): declared.append(String(child))
 var broken=[]
 for name in ["_present_needs_full_render","render"]:
  if name not in declared: broken.append(name+" is not declared on the present row")
  if not table.has(name): broken.append(name+" has no row")
  elif not present_called(body,name): broken.append(name+" is not called directly by present()")
 t.check(broken.is_empty(),"ARCH present_full_render_fallback_is_pinned: the full-render fallback stays declared, owned and called: "+str(broken.slice(0,4)))

# C5: the table symbol count never falls below the frozen floor (catches row+edge deletion and
# whole-table emptying, which C1 alone cannot see).
static func present_adjacency_symbol_floor_is_pinned(t) -> void:
 var table=present_adjacency_table()
 t.check(not table.is_empty(),"ARCH present_adjacency_symbol_floor_is_pinned: ui/main.gd::PRESENT_ADJACENCY is readable")
 if table.is_empty(): return
 var symbols=present_symbol_set(table)
 var arms=present_dispatch_arms(String(present_function_bodies(PRESENT_SOURCE).get("present","")))
 print("PRESENT ADJACENCY rows=%d symbols=%d arms=%d" % [table.size(),symbols.size(),arms.size()])
 t.check(symbols.size()>=PRESENT_SYMBOL_FLOOR,"ARCH present_adjacency_symbol_floor_is_pinned: the table symbol count stays at or above the frozen floor "+str(PRESENT_SYMBOL_FLOOR)+": symbols="+str(symbols.size()))

# docs/spec/event-pipeline.md「依赖规范」: nodes and options are reachable only through
# definition／node／node_ids; legacy keys return empty instead of raising.
static func event_definition_accessors_only(t) -> void:
 var g=Game.new(42)
 var events=g.Events
 var legacy_keys=["stages","start_stage","choices"]
 t.check(events.definition("no_such_event_for_accessor_check").is_empty() and events.definition("").is_empty(),"ARCH definition accessor returns empty for unknown ids")
 t.check(events.node({},"choice").is_empty() and events.node_ids({}).is_empty(),"ARCH node accessors tolerate an empty definition")
 t.check(not events.definition("floating_belt_cluster").is_empty(),"ARCH definition accessor resolves a shipped event")
 for id in g.Events.Data.TYPES:
  var spec=events.definition(id)
  t.check(spec==g.Events.Data.TYPES[id] and spec.has("start_node") and spec.nodes is Array and not spec.nodes.is_empty(),"ARCH definition accessor returns the authored node form "+id)
  for legacy in legacy_keys:
   t.check(spec.get(legacy)==null,"ARCH compiled definition exposes no legacy key "+legacy+" "+id)
   t.check(events.node(spec,legacy).is_empty(),"ARCH node accessor returns empty for the legacy key "+legacy+" "+id)
  var ids=events.node_ids(spec)
  t.check(ids.size()==spec.nodes.size() and spec.start_node in ids and ids.all(func(node_id):return node_id is String and node_id!=""),"ARCH node_ids enumerates every authored node "+id)
  for node_id in ids:
   var entry=events.node(spec,node_id)
   t.check(not entry.is_empty() and entry.id==node_id and entry.choices is Array and not entry.choices.is_empty(),"ARCH node accessor returns the authored node "+id+"/"+node_id)
  t.check(events.node(spec,"no_such_node_"+id).is_empty(),"ARCH node accessor returns empty for an unknown node id "+id)

class UncachedGame extends "res://tests/game_fixture.gd":
 func _begin_equipment_read() -> Dictionary:
  return {}

class PreviewCountingGame extends "res://tests/game_fixture.gd":
 var escape_builds=0
 var cast_builds=0
 func _build_escape_preview(target: Dictionary, mode: String, base: float, assist_profiles: Array=[], passive: bool=false, area_effect: bool=false, continuation: bool=false, splash: bool=false, ignore_tightness_reduction: bool=false) -> Dictionary:
  escape_builds+=1
  return super._build_escape_preview(target,mode,base,assist_profiles,passive,area_effect,continuation,splash,ignore_tightness_reduction)
 func _build_cast_view(profile: Dictionary) -> Dictionary:
  cast_builds+=1
  return super._build_cast_view(profile)

# Test-side counters for "each edge materializes at most once per scope"; production has none.
class IndexCountingGame extends "res://tests/game_fixture.gd":
 var piece_builds=0
 var slot_builds=0
 var id_builds=0
 var capacity_builds=0
 var physical_builds=0
 var target_builds=0
 var walk_calls=0
 var physical_queries=0
 var equipment_at_queries=0
 var composite_root_queries=0
 var links_at_queries=0
 func _materialize_physical_pieces() -> Array:
  piece_builds+=1
  return super._materialize_physical_pieces()
 func _materialize_slot_edge(pieces: Array) -> Dictionary:
  slot_builds+=1
  return super._materialize_slot_edge(pieces)
 func _materialize_id_edge() -> Dictionary:
  id_builds+=1
  return super._materialize_id_edge()
 func _materialize_capacity_points(pieces: Array) -> Dictionary:
  capacity_builds+=1
  return super._materialize_capacity_points(pieces)
 func _materialize_physical_points(pieces: Array) -> Dictionary:
  physical_builds+=1
  return super._materialize_physical_points(pieces)
 func _materialize_slot_target_edge() -> Dictionary:
  target_builds+=1
  return super._materialize_slot_target_edge()
 func _visit_targets_at(slot: String, found: Array, stop_on_first: bool) -> bool:
  walk_calls+=1
  return super._visit_targets_at(slot,found,stop_on_first)
 func physical_pieces() -> Array:
  physical_queries+=1
  return super.physical_pieces()
 func equipment_at(slot: String) -> Array:
  equipment_at_queries+=1
  return super.equipment_at(slot)
 func _composite_roots() -> Array:
  composite_root_queries+=1
  return super._composite_roots()
 func links_at(slot: String) -> Array:
  links_at_queries+=1
  return super.links_at(slot)

static func index_target_slots(g) -> Array:
 var keys={"missing_slot":true}
 for slot in g.B.SLOT_NAMES.keys(): keys[slot]=true
 for slot in g.B.SLOTS: keys[slot]=true
 keys["shoulder"]=true
 for slot in g.SpecialEquipment.slots(): keys[slot]=true
 for e in g.state.equipment:
  for slot in g.Equipment.coverage(e): keys[slot]=true
  if e.has("shoulders"):
   for piece in e.shoulders.pieces:
    for slot in g.Equipment.coverage(piece): keys[slot]=true
 for root in g.state.composites:
  for slot in g.Composites.definition(root).coverage: keys[slot]=true
  for e in root.components:
   for slot in g.Equipment.coverage(e): keys[slot]=true
 for link in g.state.links:
  for slot in link.slots: keys[slot]=true
 for e in g.Binding.connections(g):
  var slot=str(e.get("slot",""))
  if slot!="": keys[slot]=true
 if g._equipment_read_active() and g._equipment_read.has("slot_targets"):
  for slot in g._equipment_read.slot_targets.keys(): keys[slot]=true
  if g._equipment_read.has("slots"):
   for slot in g._equipment_read.slots.keys(): keys[slot]=true
  if g._equipment_read.has("links"):
   for slot in g._equipment_read.links.keys(): keys[slot]=true
 return keys.keys()

# Test-side counter: production card_facts must not call Game.targets_at for undeclared slots.
class TargetsAtCountingGame extends "res://tests/game_fixture.gd":
 var targets_at_slots=[]
 func targets_at(slot: String) -> Array:
  targets_at_slots.append(slot)
  return super.targets_at(slot)

# Test-side counter: an unregistered kind must not reach the whole-table producer (C2 fail-closed).
class FactSourceCountingGame extends "res://tests/game_fixture.gd":
 var fact_source_calls=0
 func _fact_source(groups: Array = []) -> Array:
  fact_source_calls+=1
  return super._fact_source(groups)

# B 批（K2）测试侧计数：一次可行动期的命令事实查询不得建整表；生产源码不带计数器。
# 2026-10-06 B 批审查条目 1（归 C 批）：计数面扩到整表连接的三个入口（_join_fact_units／
# _phase_branch_units／_phase_facts 直调），使「臂内经 helper 重建整表」也在计数面内。
class PointLookupCountingGame extends "res://tests/game_fixture.gd":
 var fact_source_calls=0
 var command_facts_calls=0
 var join_units_calls=0
 var branch_units_calls=0
 var phase_facts_calls=0
 func _fact_source(groups: Array = []) -> Array:
  fact_source_calls+=1
  return super._fact_source(groups)
 func command_facts(groups: Array = []) -> Array:
  command_facts_calls+=1
  return super.command_facts(groups)
 func _join_fact_units(units: Array, groups: Array = []) -> Array:
  join_units_calls+=1
  return super._join_fact_units(units,groups)
 func _phase_branch_units(branch: String, groups: Array = []) -> Array:
  branch_units_calls+=1
  return super._phase_branch_units(branch,groups)
 func _phase_facts(groups: Array = []) -> Array:
  phase_facts_calls+=1
  return super._phase_facts(groups)
 func reset_point_lookup_counts() -> void:
  fact_source_calls=0
  command_facts_calls=0
  join_units_calls=0
  branch_units_calls=0
  phase_facts_calls=0

# C 批（K3）测试侧计数：表 pass 每行恰构造一次、每个读取批次只走查一次。计数口径＝core/game.gd::_fact
# 的调用（事实的唯一构造点）＋走查入口 core/game.gd::attack_point_walk 的调用；期望侧＝该次调用返回的行集
# （不取自实现）。生产源码不带计数器。
class PointFamilyCountingGame extends "res://tests/game_fixture.gd":
 var fact_calls=0
 var fact_payloads=[]
 var walk_calls=0
 func _fact(payload: Dictionary, label: String, copy, cost, mana, reason: String, risk: String, group: String) -> Dictionary:
  fact_calls+=1
  fact_payloads.append(payload.duplicate())
  return super._fact(payload,label,copy,cost,mana,reason,risk,group)
 func attack_point_walk(g) -> Array:
  walk_calls+=1
  return super.attack_point_walk(g)
 func reset_point_family_counts() -> void:
  fact_calls=0
  fact_payloads.clear()
  walk_calls=0

# 逐家族构造次数（被测侧）；期望侧＝该夹具的返回行集（见 table_rows_constructed_once）。
static func point_family_constructed(g) -> Dictionary:
 var out={"attack":0,"witch":0,"equipment_spell":0,"card":0}
 for payload in g.fact_payloads:
  var kind=String(payload.get("kind",""))
  if kind=="attack":
   if String(payload.get("target",""))!="": out.equipment_spell=int(out.equipment_spell)+1
   elif String(payload.get("type","")).begins_with("witch_"): out.witch=int(out.witch)+1
   else: out.attack=int(out.attack)+1
  elif kind=="card": out.card=int(out.card)+1
 return out

static func point_family_rows(rows: Array) -> Dictionary:
 var out={"attack":0,"witch":0,"equipment_spell":0,"card":0}
 for row in rows:
  var payload=row.payload
  var kind=String(payload.get("kind",""))
  if kind=="attack":
   if String(payload.get("target",""))!="": out.equipment_spell=int(out.equipment_spell)+1
   elif String(payload.get("type","")).begins_with("witch_"): out.witch=int(out.witch)+1
   else: out.attack=int(out.attack)+1
  elif kind=="card": out.card=int(out.card)+1
 return out

# S2 test-side counter: the point-query path must compute the requested row only, so these three
# whole-table producers stay at zero calls. Production carries no counters.
class AttackLookupCountingGame extends "res://tests/game_fixture.gd":
 var attack_facts_calls=0
 var equipment_spell_calls=0
 var fact_source_calls=0
 func attack_facts() -> Array:
  attack_facts_calls+=1
  return super.attack_facts()
 func equipment_spell_facts() -> Array:
  equipment_spell_calls+=1
  return super.equipment_spell_facts()
 func _fact_source(groups: Array = []) -> Array:
  fact_source_calls+=1
  return super._fact_source(groups)
 func reset_attack_lookup_counts() -> void:
  attack_facts_calls=0
  equipment_spell_calls=0
  fact_source_calls=0

# S5 test-side counter: production carries no counters; every command_fact reached through
# dispatch (and any pre-submit lookup the UI used to make) lands here.
class SubmitLookupCountingGame extends "res://tests/game_fixture.gd":
 var fact_calls=0
 func command_fact(cmd: Dictionary) -> Dictionary:
  fact_calls+=1
  return super.command_fact(cmd)

# Test-side later-source counters for has_targets_at early-exit; production has none.
class TargetWalkCountingGame extends TargetsAtCountingGame:
 var composite_root_calls=0
 var links_at_calls=0
 func _composite_roots() -> Array:
  composite_root_calls+=1
  return super._composite_roots()
 func links_at(slot: String) -> Array:
  links_at_calls+=1
  return super.links_at(slot)
 func reset_walk_counts() -> void:
  targets_at_slots.clear()
  composite_root_calls=0
  links_at_calls=0

static func containers(value, path: String, out: Array) -> void:
 if value is Dictionary:
  out.append({"value":value,"path":path})
  for key in value: containers(value[key],path+"."+str(key),out)
 elif value is Array:
  out.append({"value":value,"path":path})
  for i in range(value.size()): containers(value[i],path+"["+str(i)+"]",out)

static func shared(view: Dictionary, authority: Dictionary) -> String:
 var visible=[];var sources=[]
 containers(view,"view",visible);containers(authority,"authority",sources)
 for entry in visible:
  for source in sources:
   if is_same(entry.value,source.value): return entry.path+" -> "+source.path
 return ""

# docs/spec/event-pipeline.md「证据入口」: the state
# condition kinds come from one declaration, and the three consumers agree on them.
static func event_condition_kinds_share_one_declaration(t) -> void:
 var g=Game.new(42)
 var events=g.Events
 var kinds=events.condition_kinds()
 t.check(kinds.size()==2 and "has_relic" in kinds and "no_chastity_lock" in kinds,"EVENT KINDS declaration table lists the supported state conditions")
 for kind in kinds:
  var entry={"kind":kind,"reason":"条件不成立。"}
  if kind=="has_relic": entry.type="softened_buckle"
  t.check(events.condition_issue(g,entry,{"relic":g.Relics.TYPES})=="","EVENT KINDS content validation accepts the declared fields: "+kind)
  t.check(events.condition_saved_fields(kind)==["kind","reason"]+Array(events.CONDITIONS[kind].required),"EVENT KINDS save key set derives from the declaration: "+kind)
  var probe=events.condition_probe(g,entry)
  t.check(probe is bool,"EVENT KINDS runtime evaluation answers every declared kind: "+kind)
 var unknown={"kind":"unknown_condition","reason":"条件不成立。"}
 t.check(events.condition_issue(g,unknown,{"relic":g.Relics.TYPES})!="","EVENT KINDS content validation rejects an unknown kind")
 var saved=g.state.room_event.duplicate(true)
 g.state.room_event={"id":"binding_cleric","stage":"service","options":[{"id":"probe","label":"夹具","detail":"","reward":"none","effects":[],"conditions":[{"kind":"unknown_condition","reason":"条件不成立。","mode":"optional"}]}],"refs":{},"values":{},"report":"","reward":[],"winner":-1,"relic":"","flow":true,"held":{},"cleanup_effects":[],"next_stage":"","result_status":"neutral"}
 t.check(g.validate()!="" or g.Snapshot.check(g.export_snapshot(),g)!="","EVENT KINDS save validation rejects an unknown kind")
 g.state.room_event=saved

# docs/spec/event-pipeline.md「证据入口」: every read path is read-only.
static func event_probe_and_projection_readonly(t) -> void:
 for id in ["floating_belt_cluster","binding_cleric","succubus_three_games"]:
  var g=Game.new(42)
  g.Events.start(g,id)
  var before=g.export_snapshot()
  var rng=g.state.rng.duplicate(true)
  var logs=g.state.logs.size()
  var version=g.state.version
  g.get_view();g.command_facts()
  for option in g.state.room_event.options:
   g.Events.evaluate_option(g,g.Events.request_for(g,option,"candidate"))
   g.Events.evaluate_option(g,g.Events.request_for(g,option,"probe"))
  g.Events.selector_values(g,{"kind":"restraint"})
  g.Events.selector_values(g,{"kind":"card"})
  t.check(g.export_snapshot()==before and g.state.rng==rng and g.state.logs.size()==logs and g.state.version==version,"EVENT READONLY projection and evaluation do not mutate: "+id)

# docs/spec/event-pipeline.md「依赖规范」: one evaluation entry owns the decisions, so
# re-reading facts never re-freezes and matches a direct entry call.
static func event_single_evaluation_entry(t) -> void:
 for id in ["floating_belt_cluster","binding_cleric","succubus_three_games","mysterious_woman_statue","enchanters_empty_studio"]:
  var g=Game.new(42)
  g.Events.start(g,id)
  if g.state.room_event.stage=="result": continue
  var before=g.export_snapshot()
  var facts=g.command_facts().filter(func(c):return c.payload.get("action","")=="choose")
  t.check(g.export_snapshot()==before,"EVENT ENTRY candidate support never freezes or consumes random: "+id)
  for candidate in facts:
   var option=g.state.room_event.options.filter(func(o):return o.id==candidate.payload.get("choice",""))
   if option.is_empty(): continue
   var result=g.Events.evaluate_option(g,g.Events.request_for(g,option[0],"candidate"))
   t.check(candidate.valid==(result.decision=="generated") and (result.reason=="" or candidate.get("reason","")!=""),"EVENT ENTRY candidate support matches the single entry: "+id+"/"+str(candidate.payload.get("choice","")))

# ==== 每点击完整性检查的 debug 门控（docs/record/proposals/check-routing-and-per-click-checks.md「二」）====
# 人裁定：五道提交检查、投影面（经 command_domain_ready）与事件探针的整状态一半在正常流程下从不失败，
# 按构建类型判定运行；诊断只活在实例上（不进 state／存档／View／玩家可见日志／返回字典）。release 侧的
# 早拦损失由 dispatch 尾部、写档前、读档后的聚合校验兜底并回滚——F4 面（版本新鲜度、聚合校验、事件与替换
# 的规则用途、探针效果可行性一半）不得随门控改动。三条具名判据：per_click_checks_are_debug_only／
# per_click_diagnostics_stay_out_of_the_game／projection_integrity_gate_is_declared_once。

static func per_click_damaged_rows() -> Array:
 return [
  {"check":"Consumables.validate_buffs","reason":"同一部位的药剂效果重复。"},
  {"check":"Binding.state_issue","reason":"连接式固缚耐久不正确。"},
  {"check":"SpecialEquipment.validate","reason":"同一种性玩具不能重复佩戴。"},
  {"check":"Cards.validate","reason":"本回合力量加值不正确。"},
  {"check":"RelicEffects.validate","reason":"累计进度对应的遗物未持有。"},
 ]

# 五份坏状态各只破坏一道检查，且记录结构保持完整（重复作用位置／越界耐久／重复家族／负数回合加值／
# 孤儿累计进度）——release 侧跳过检查后候选构建与提交执行本身不会崩，这正是登记的取舍。
static func per_click_damaged_game(check: String):
 match check:
  "Consumables.validate_buffs":
   var buffs=Game.new(42)
   buffs.state.body_buffs=[{"type":"lubricant_potion","group":"thigh"},{"type":"lubricant_potion","group":"thigh"}]
   return buffs
  "Binding.state_issue":
   for seed in range(1,100):
    var bound=Game.new(seed,true,"torso_binding")
    if bound.state.equipment.is_empty(): continue
    var piece=bound.state.equipment[0]
    if not piece.has("binding") or str(piece.binding.get("kind",""))!="linked": continue
    piece.binding.durability=piece.binding.maximum+1.0
    return bound
   return null
  "SpecialEquipment.validate":
   var special=Game.new(42)
   special._install_special("shaft_ring_low","special_2_a")
   var twin=special.state.special_equipment[0].duplicate(true)
   twin.id="special_9_z"
   special.state.special_equipment.append(twin)
   return special
  "Cards.validate":
   var cards=Game.new(42)
   cards.state.turn_strength=-1
   return cards
  "RelicEffects.validate":
   var relics=Game.new(42)
   relics.state.relic_counters={"nonexistent_relic":1}
   return relics
 return null

# 坏状态下仍存在一个合法提交（结束回合）：开关关时它走到执行与 dispatch 尾部聚合校验；开关开时它先被
# 门控检查拒绝。找不到时返回空，由调用方断言。
static func per_click_legal_command(g) -> Dictionary:
 for row in g.command_facts():
  if String(row.payload.get("kind",""))=="end" and row.valid: return g.command(row.payload,g.state.version)
 return {}

static func per_click_checks_are_debug_only(t) -> void:
 var rows=per_click_damaged_rows()
 t.check(rows.size()==5,"PERCLICK per_click_checks_are_debug_only: the five gated per-click checks each have a damaged fixture: "+str(rows.size()))
 # G-PC-1：默认只有构建类型；覆盖入口只在 debug 生效；不存在存档／命令行／环境变量开启途径。
 var surface=Game.new(42)
 t.check(surface.debug_checks_enabled(),"PERCLICK per_click_checks_are_debug_only: a debug build enables the checks by default")
 surface.set_debug_checks_enabled(false)
 t.check(not surface.debug_checks_enabled(),"PERCLICK per_click_checks_are_debug_only: the override turns the switch off")
 surface.set_debug_checks_enabled(true)
 t.check(surface.debug_checks_enabled(),"PERCLICK per_click_checks_are_debug_only: the override turns it back on")
 var enabled_body=source_func_body_code("res://core/game.gd","debug_checks_enabled")
 var setter_body=source_func_body_code("res://core/game.gd","set_debug_checks_enabled")
 t.check(enabled_body.contains("OS.is_debug_build()") and setter_body.contains("OS.is_debug_build()"),"PERCLICK per_click_checks_are_debug_only: the build type is the switch's only source: "+enabled_body.strip_edges()+setter_body.strip_edges())
 var opening_paths=["get_environment","has_environment","get_cmdline","FileAccess","user://"]
 var reachable=opening_paths.filter(func(token):return (enabled_body+setter_body).contains(token))
 t.check(reachable.is_empty(),"PERCLICK per_click_checks_are_debug_only: no runtime path opens the switch: "+str(reachable))
 # 被门控清单穷举：开关只被两个声明文件消费（game.gd 的提交／投影面与 room_events.gd 的探针面）。
 var consumers=[]
 for path in script_files("res://core"):
  if source_text(path.trim_prefix("res://")).contains("debug_checks_enabled("): consumers.append(path.trim_prefix("res://"))
 t.check(consumers==["core/game.gd","core/room_events.gd"],"PERCLICK per_click_checks_are_debug_only: the switch has exactly the two declared consumers: "+str(consumers))
 # G-PC-2／G-PC-3：同一坏状态与同一合法提交在两种开关下——开＝本检查文案拒绝＋诊断＋快照不动；
 # 关＝该检查不跑，改由 dispatch 尾部聚合校验以「行动未提交：」拒绝并逐字节回滚。
 for row in rows:
  var on_game=per_click_damaged_game(row.check)
  var off_game=per_click_damaged_game(row.check)
  if on_game==null or off_game==null:
   t.check(false,"PERCLICK per_click_checks_are_debug_only: the damaged fixture exists: "+row.check)
   continue
  off_game.set_debug_checks_enabled(false)
  var cmd=per_click_legal_command(off_game)
  t.check(not cmd.is_empty(),"PERCLICK per_click_checks_are_debug_only: the damaged fixture still exposes a legal command: "+row.check)
  var on_before=on_game.export_snapshot()
  var on_result=on_game.dispatch(cmd,int(on_game.state.version))
  t.check(not on_result.ok and String(on_result.error)==str(row.reason),"PERCLICK per_click_checks_are_debug_only: switch on, the gated check keeps its own rejection wording "+row.check+": "+str(on_result))
  var logged=on_game.debug_check_failures.back() if not on_game.debug_check_failures.is_empty() else {}
  t.check(str(logged.get("check",""))==row.check and str(logged.get("reason",""))==str(row.reason) and str(logged.get("location",""))=="game.dispatch","PERCLICK per_click_checks_are_debug_only: switch on, a failure records check, reason and game.dispatch in the diagnostics "+row.check+": "+str(on_game.debug_check_failures))
  t.check(on_game.export_snapshot()==on_before,"PERCLICK per_click_checks_are_debug_only: switch on, the early rejection leaves the snapshot byte-identical "+row.check)
  var off_before=off_game.export_snapshot()
  var off_result=off_game.dispatch(cmd,int(off_game.state.version))
  t.check(not off_result.ok and String(off_result.error)=="行动未提交："+str(row.reason),"PERCLICK per_click_checks_are_debug_only: switch off, the dispatch-tail aggregate refuses the same damaged state "+row.check+": "+str(off_result))
  t.check(off_game.export_snapshot()==off_before,"PERCLICK per_click_checks_are_debug_only: switch off, the tail rejection rolls back byte-for-byte "+row.check)
  t.check(off_game.debug_check_failures.is_empty(),"PERCLICK per_click_checks_are_debug_only: switch off, a skipped check writes no diagnostics "+row.check+": "+str(off_game.debug_check_failures))
 # G-PC-3：只被聚合校验抓住的坏状态在两种开关下都走尾部拒绝（开关不影响聚合兜底）。
 for mode in [true,false]:
  var label="on" if mode else "off"
  var tail=Game.new(42)
  tail.set_debug_checks_enabled(mode)
  tail.state.wall_distance=7
  var tail_before=tail.export_snapshot()
  var tail_result=tail.dispatch(per_click_legal_command(tail),int(tail.state.version))
  t.check(not tail_result.ok and String(tail_result.error)=="行动未提交：距墙距离必须是0至4的整数。" and tail.export_snapshot()==tail_before,"PERCLICK per_click_checks_are_debug_only: switch "+label+", the dispatch-tail aggregate still refuses an aggregate-only damaged state and rolls back: "+str(tail_result))
 # G-PC-6 的 F4 面（逐条）：版本新鲜度、写档前／读档后的聚合校验在两种开关下逐字相同。
 for mode in [true,false]:
  var label="on" if mode else "off"
  var stale=Game.new(42)
  stale.set_debug_checks_enabled(mode)
  var stale_result=stale.dispatch(per_click_legal_command(stale),stale.state.version-1)
  t.check(not stale_result.ok and String(stale_result.error)=="状态已更新，请重新选择行动。","PERCLICK per_click_checks_are_debug_only: switch "+label+", staleness stays checked in every build: "+str(stale_result))
  var save_game=per_click_damaged_game("Cards.validate")
  save_game.set_debug_checks_enabled(mode)
  t.check(save_game.Snapshot.check(save_game.export_snapshot(),save_game)=="","PERCLICK per_click_checks_are_debug_only: switch "+label+", the save fixture passes the field check so only the aggregate can refuse it")
  var store=Store.new("res://build/per-click-checks-"+label+"-"+str(Time.get_ticks_usec()))
  var written=store.write_game(save_game)
  t.check(not written.ok and String(written.error)=="保存失败：本回合力量加值不正确。","PERCLICK per_click_checks_are_debug_only: switch "+label+", writing keeps the pre-save aggregate validation: "+str(written))
  t.check(not FileAccess.file_exists(store.path(save_game.state.save_slot)),"PERCLICK per_click_checks_are_debug_only: switch "+label+", a refused write leaves no file behind")
  var loaded=Game.new(42)
  loaded.set_debug_checks_enabled(mode)
  var restored=loaded.restore_snapshot(save_game.export_snapshot())
  t.check(not restored.ok and String(restored.error)=="无法继续这份存档：本回合力量加值不正确。","PERCLICK per_click_checks_are_debug_only: switch "+label+", loading keeps the post-load aggregate validation: "+str(restored))
  var clean=Game.new(42)
  clean.set_debug_checks_enabled(mode)
  t.check(clean.restore_snapshot(Game.new(42).export_snapshot()).ok,"PERCLICK per_click_checks_are_debug_only: switch "+label+", a valid snapshot still loads")
  var replacement=Game.new(42)
  replacement.set_debug_checks_enabled(mode)
  replacement._install_special("shaft_ring_low","special_2_a")
  replacement.state.special_equipment[0].remaining=-1
  var forced=replacement.IronMan.Replacement.force_special(replacement,"corona_ring_low",1,"per-click-probe")
  t.check(not forced.ok and String(forced.reason)=="替换后的特殊装备结构不合法。","PERCLICK per_click_checks_are_debug_only: switch "+label+", the replacement structural recheck is not gated: "+str(forced))
  var event_game=Game.new(42)
  event_game.set_debug_checks_enabled(mode)
  event_game._install_special("shaft_ring_low","special_2_a")
  EventCases.arrive(event_game,"binding_cleric")
  var held=event_game.Events.apply_effects(event_game,[{"op":"hold_special","key":"pending","slots":["special_2_a"]}],event_game.state.room_event.refs,false)
  t.check(held=="","PERCLICK per_click_checks_are_debug_only: switch "+label+", the event fixture holds the special item: "+held)
  if held=="":
   var held_twin=event_game.state.room_event.held["pending"][0].duplicate(true)
   held_twin.id="special_9_z"
   event_game.state.special_equipment.append(held_twin)
   var put_back=event_game.Events.apply_effects(event_game,[{"op":"restore_held","key":"pending"}],event_game.state.room_event.refs,false)
   t.check(put_back=="无法原样装回暂存装备：同一种性玩具不能重复佩戴。","PERCLICK per_click_checks_are_debug_only: switch "+label+", the event rule use of SpecialEquipment.validate is not gated: "+put_back)
   t.check(event_game.validate()=="事件暂存装备不合法：同一种性玩具不能重复佩戴。","PERCLICK per_click_checks_are_debug_only: switch "+label+", the aggregate event validation keeps running: "+event_game.validate())
 # G-PC-5：探针整状态一半随开关，效果可行性一半在两种开关下都保留。
 for mode in [true,false]:
  var label="on" if mode else "off"
  var values=Game.new(42)
  values.set_debug_checks_enabled(mode)
  EventCases.arrive(values,"binding_cleric")
  values.state.room_event.values={"seen":-1}
  var state_half=values.Events.probe_result(values,[],{})
  t.check(String(state_half.gate)==("validate_failed" if mode else ""),"PERCLICK per_click_checks_are_debug_only: switch "+label+", the probe's whole-state half follows the switch: "+str(state_half))
  if mode:
   t.check(String(state_half.reason)=="事件计数记录不正确。","PERCLICK per_click_checks_are_debug_only: switch on, the probe half reports the aggregate reason: "+str(state_half))
   t.check(values.debug_check_failures.any(func(row):return str(row.check)=="Game.validate" and str(row.location)=="room_events.probe_result"),"PERCLICK per_click_checks_are_debug_only: switch on, the probe's failing whole-state half writes its diagnostic: "+str(values.debug_check_failures))
  else:
   t.check(values.debug_check_failures.is_empty(),"PERCLICK per_click_checks_are_debug_only: switch off, the skipped probe half writes no diagnostics: "+str(values.debug_check_failures))
  var effects=Game.new(42)
  effects.set_debug_checks_enabled(mode)
  EventCases.arrive(effects,"binding_cleric")
  var effects_half=effects.Events.probe_result(effects,[{"op":"mana_loss","amount":99999}],{})
  t.check(String(effects_half.gate)=="probe_failed" and str(effects_half.reason)=="剩余魔力不足以支付已公开的费用。","PERCLICK per_click_checks_are_debug_only: switch "+label+", the probe's effects half stays a rule judgement: "+str(effects_half))

# G-PC-7：诊断只活在实例上——不进 state（含玩家可见日志）、不进存档、不进 View、不进拒绝结果。
# push_warning 是唯一过程输出（"DEBUG CHECK" 前缀只可能出现在引擎告警里）。
static func per_click_diagnostics_stay_out_of_the_game(t) -> void:
 for row in per_click_damaged_rows():
  var g=per_click_damaged_game(row.check)
  if g==null:
   t.check(false,"PERCLICK per_click_diagnostics_stay_out_of_the_game: the damaged fixture exists: "+row.check)
   continue
  var twin=per_click_damaged_game(row.check)
  twin.set_debug_checks_enabled(false)
  var cmd=per_click_legal_command(twin)
  var before=g.export_snapshot()
  var result=g.dispatch(cmd,int(g.state.version))
  t.check(not g.debug_check_failures.is_empty(),"PERCLICK per_click_diagnostics_stay_out_of_the_game: a gated failure writes the in-process diagnostics: "+row.check)
  t.check(result.keys()==S5_REJECT_KEYS,"PERCLICK per_click_diagnostics_stay_out_of_the_game: the rejection keeps the declared key face: "+row.check+": "+str(result.keys()))
  t.check(g.export_snapshot()==before,"PERCLICK per_click_diagnostics_stay_out_of_the_game: the diagnostics never enter state or the save: "+row.check)
  var sinks=[JSON.stringify(g.state),JSON.stringify(g.state.logs),JSON.stringify(g.get_view()),JSON.stringify(result),JSON.stringify(g.export_snapshot())]
  var leaked=sinks.filter(func(text):return text.contains("debug_check_failures") or text.contains("DEBUG CHECK"))
  t.check(leaked.is_empty(),"PERCLICK per_click_diagnostics_stay_out_of_the_game: no sink carries the diagnostics: "+row.check+": "+str(leaked))

# G-PC-4：投影闸的唯一声明点是 command_domain_ready（base_action_block 在阶段守卫后复用），
# 两种开关下的投影行为可辨。
static func projection_integrity_gate_is_declared_once(t) -> void:
 var expression='Binding.state_issue(self)=="" and SpecialEquipment.validate(state.get("special_equipment"))==""'
 var total=source_text("core/game.gd").count(expression)
 t.check(total==1,"PERCLICK projection_integrity_gate_is_declared_once: the domain predicate is declared exactly once in core/game.gd: "+str(total))
 var ready_body=source_func_body_code("res://core/game.gd","command_domain_ready")
 t.check(ready_body.contains(expression),"PERCLICK projection_integrity_gate_is_declared_once: the single declaration lives in command_domain_ready: "+ready_body.strip_edges())
 var block_body=source_func_body_code("res://core/game.gd","base_action_block")
 t.check(block_body.contains("return command_domain_ready()") and not block_body.contains(expression),"PERCLICK projection_integrity_gate_is_declared_once: base_action_block reuses the gate instead of inlining the predicate: "+block_body.strip_edges())
 t.check(block_body.find("BASE_ABSENT_PHASES")>=0 and block_body.find("BASE_ABSENT_PHASES")<block_body.find("return command_domain_ready()"),"PERCLICK projection_integrity_gate_is_declared_once: base_action_block keeps its phase guard before reusing the gate")
 for check in ["Binding.state_issue","SpecialEquipment.validate"]:
  var on_game=per_click_damaged_game(check)
  t.check(on_game!=null and not on_game.command_domain_ready() and not on_game.base_action_block(),"PERCLICK projection_integrity_gate_is_declared_once: switch on, the projection gate reports the damaged domain: "+check)
  t.check(on_game!=null and on_game.command_facts().is_empty(),"PERCLICK projection_integrity_gate_is_declared_once: switch on, no fact row is built through the blocked domain: "+check)
  var off_game=per_click_damaged_game(check)
  if off_game==null:
   t.check(false,"PERCLICK projection_integrity_gate_is_declared_once: the projection fixture exists: "+check)
   continue
  off_game.set_debug_checks_enabled(false)
  t.check(off_game.command_domain_ready() and off_game.base_action_block(),"PERCLICK projection_integrity_gate_is_declared_once: switch off, the projection gate is not evaluated: "+check)
  t.check(not off_game.command_facts().is_empty() and not off_game.get_view().is_empty(),"PERCLICK projection_integrity_gate_is_declared_once: switch off, the fact table and the view are built from the same damaged state: "+check)

static func run(t) -> void:
 event_dependency_edges_pinned(t)
 content_pack_root_has_no_build_feature_branch(t)
 present_adjacency_graph_is_pinned(t)
 present_adjacency_rows_are_complete(t)
 present_section_dispatch_is_total(t)
 present_pipeline_routines_are_registered(t)
 present_full_render_fallback_is_pinned(t)
 present_adjacency_symbol_floor_is_pinned(t)
 transition_write_sites_are_pinned(t)
 save_checkpoint_kinds_are_pinned(t)
 event_condition_kinds_share_one_declaration(t)
 event_probe_and_projection_readonly(t)
 event_single_evaluation_entry(t)
 per_click_checks_are_debug_only(t)
 projection_integrity_gate_is_declared_once(t)
 per_click_diagnostics_stay_out_of_the_game(t)
 event_definition_accessors_only(t)
 tool_registry_boundary(t)
 equipment_read_batches(t)
 index_materializes_once_per_scope(t)
 index_id_edge_parity(t)
 index_predicate_parity(t)
 has_targets_at_parity(t)
 index_entry_parity(t)
 index_self_check_falls_back(t)
 copy_projection_masked_baseline(t)
 single_eligibility_implementation(t)
 instruction_router_single_entry(t)
 instruction_route_table_is_total(t)
 command_registry_is_total(t)
 fact_source_map_is_pinned(t)
 fact_units_cover_fact_source(t)
 phase_branch_vocabulary_is_total(t)
 baseline_constants_are_unchanged(t)
 default_projection_is_unchanged(t)
 lazy_projection_invariant(t)
 fact_groups_are_total(t)
 whole_table_branches_force_full_demand(t)
 attack_fact_direct_lookup(t)
 attack_point_lookup_reads_one_row(t)
 attack_point_rejects_nonbattle_families(t)
 card_fact_direct_lookup(t)
 card_point_lookup_reads_one_row(t)
 fact_lookup_all_kinds(t)
 domain_arm_guards_call_phase_branch(t)
 point_sources_are_kind_limited(t)
 point_query_builds_no_table(t)
 prefix_branch_tables_are_frozen(t)
 domain_arm_branch_ids_are_pinned(t)
 table_rows_constructed_once(t)
 table_walk_single_entry(t)
 point_family_rows_respect_read_scope(t)
 fact_table_reuse_within_batch(t)
 fact_table_cache_lifetime_is_pinned(t)
 table_reuse_matches_fresh_projection(t)
 batch_reuse_never_aliases_callers(t)
 walk_rows_are_never_empty(t)
 command_fact_kind_lookup(t)
 single_fact_lookup_per_submit(t)
 rejected_submit_lookup_counts(t)
 submit_presented_fact_is_unchanged(t)
 submit_key_face_rebaseline_self_proof(t)
 submit_result_scalars_are_pinned(t)
 baseline_diff_is_declared(t)
 demand_declarations_are_total(t)
 section_read_sets_are_pinned(t)
 prison_page_row_order_is_pinned(t)
 submit_demand_call_sites_are_pinned(t)
 command_facts_full_scope_is_content_equal(t)
 contract_text_is_updated_verbatim(t)
 target_queries_read_observer_is_debug_only(t)
 frozen_anchor_files_match_git(t)
 dispatch_fact_row_is_readonly(t)
 payload_write_sites_are_pinned(t)
 state_read_sites_are_pinned(t)
 state_read_scan_reaches_every_source(t)
 state_read_registrations_are_pinned(t)
 card_facts_declared_slots(t)
 card_facts_consumes_has_targets_at(t)
 card_facts_keyword_min_query(t)
 slice_dependency_directions(t)
 run_identity_single_writer(t)
 feedback_save_single_serializer(t)
 feedback_save_cap_pinned(t)
 card_terms_single_source(t)
 equipment_scope_sites(t)
 equipment_targets_walk_is_one_path(t)
 transition_kind_set_pinned(t)
 command_params_keys_pinned(t)
 get_view_call_sites_are_pinned(t)
 production_source_never_preloads_tests(t)
 ondemand_copy_consumer_boundary(t)
 run_review_is_read_only_source(t)
 target_queries_stay_stateless(t)
 ui_never_reads_game_state(t)
 mutation_evidence_is_total(t)
 behavior_baseline_equivalence(t)
 removal_end_state(t)
 copy_single_entry_matches_projection(t)
 copy_route_bytes_unchanged(t)
 var images=preload("res://data/equipment_images.gd")
 var missing=[]
 for family in images.MATERIALS:
  for file in images.MATERIALS[family]:
   if not ResourceLoader.exists("res://assets/ui/equipment/"+file+".png"): missing.append(file)
 for file in images.TEMPLATES.values():
  if not ResourceLoader.exists("res://assets/ui/equipment/"+file+".png"): missing.append(file)
 t.check(missing.is_empty(),"ARCH all registered legacy equipment images exist: "+str(missing))
 var initial=Game.new(42,false,"equipment",false)
 t.check(initial.state.rng.size()==initial.B.RNG_SALTS.size() and initial.B.RNG_SALTS.keys().all(func(domain):return initial.state.rng.get(domain)==0),"ARCH initialization creates exactly the registered random domains with zero counters")
 card_identity(t)
 current_effect_boundaries(t)
 instance_effect_boundaries(t)
 for kind in ["equipment","component_links","prison_test","succubus_three_games","trader_solo","drone_solo","binding_box_solo","doubao"]:
  var g=Game.new(42,true,kind)
  if kind in ["drone_solo","binding_box_solo"]:
   t.check(t.action(g,"end").ok and g.CaptureBind.has_bind(g),"ARCH formal enemy turn establishes source-bound capture "+kind)
  projection_contract(t,g,kind)
 var g=Rewards.setup()
 var target=g.add_fixture("thigh",4)
 var id=target.id
 var focus=Rewards.give(t,g,"focus")
 t.check(Rewards.play(t,g,focus,"thigh",id).ok and g.state.charge==1,"ARCH real focus card grants shared charge")
 var before=g.export_snapshot()
 t.check(t.action(g,"manual",{"target":id}).ok,"ARCH release uses formal candidate")
 t.check(g._equipment(id).is_empty() and g.state.charge==1,"ARCH deleted ordinary target preserves unrelated charge")
 t.check(g.state.energy==before.energy-1 and g.state.mana==before.mana and g.state.rng==before.rng,"ARCH manual cleanup pays once and preserves unrelated resource and random domains")
 var settled=g.export_snapshot()
 g._cleanup()
 t.check(g.export_snapshot()==settled,"ARCH cleanup reaches a fixed point without repeated events")

static func tool_registry_boundary(t) -> void:
 var catalog=preload("res://data/field_tools.gd")
 var tools=Game.Tools
 for field in ["TYPES","DROP_POOL","HEIGHTS","OPERATOR_HEIGHTS","POINT_HEIGHTS"]:
  t.check(is_same(tools[field],catalog[field]),"ARCH tool rules inherit the original registry without a mutable duplicate: "+field)
 var names=catalog.new().get_method_list().map(func(method):return method.name)
 t.check(not "install_reason" in names and not "target_contact" in names and not "description" in names,"ARCH item catalog does not expose state-dependent tool queries")
 t.check(catalog.HEIGHTS.is_read_only() and tools.HEIGHTS.is_read_only() and catalog.HEIGHTS.keys().all(func(mount):return tools.mount_label(mount)==catalog.mount_label(mount)),"ARCH inherited height definitions stay read-only and expose the same labels")

static func card_identity(t) -> void:
 for damage in ["type","orphan","duplicate"]:
  var g=Rewards.setup()
  var candidate=g.command_facts().filter(func(c):return c.valid)[0]
  var clean=g.export_snapshot()
  match damage:
   "type": g.state.deck[0].type="panic" if g.state.deck[0].type!="panic" else "sensitive"
   "orphan": g.state.deck[0].uid="card_missing"
   "duplicate": g.state.deck[0]=g.state.deck[1].duplicate(true)
  var damaged=g.export_snapshot()
  t.check(g.validate()!="","ARCH equal card counts cannot hide mismatched physical identity "+damage)
  t.check(not g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok and g.export_snapshot()==damaged,"ARCH invalid card identity rejects action before payment "+damage)
  g.state=clean
  t.check(not g.restore_snapshot(damaged).ok and g.export_snapshot()==clean,"ARCH same card invariant rejects restore atomically "+damage)

static func projection_contract(t, g, label: String) -> void:
 var before=g.state.duplicate(true)
 var view=g.get_view()
 var facts=g.command_facts()
 var targets=g.action_targets();var target_ids={}
 for target in targets: target_ids[target.id]=true
 t.check(target_ids.size()==targets.size() and targets.all(func(target):return is_same(target,g._equipment(target.id))),"ARCH action target identities are unique and resolve to canonical objects "+label)
 var reference=UncachedGame.new(42)
 reference.state=before.duplicate(true)
 t.check(view==reference.get_view() and facts==reference.command_facts(),"ARCH indexed and live equipment queries produce identical full projections "+label)
 t.check(g._equipment_read.is_empty(),"ARCH read batch releases all equipment references "+label)
 t.check(g.state==before,"ARCH preview preserves all state and random domains "+label)
 var alias=shared(view,{"state":g.state,"equipment":g.Equipment.TEMPLATES,"special":g.SpecialEquipment.TYPES,"regions":g.SpecialEquipment.REGIONS,"cards":g.Cards.Rules.SPECS,"buffs":g.Cards.Rules.BUFFS,"relics":g.Relics.TYPES,"enemies":g.Enemies.TYPES,"attacks":g.BasicAttacks.TYPES,"body_groups":g.Equipment.PANEL_GROUPS,"shop_copy":g.Services.ShopCopy.PERFORMANCES})
 t.check(alias=="","ARCH view has no writable references to state or registries "+label+": "+alias)
 var ids={}
 for candidate in facts: ids[candidate.key]=true
 t.check(ids.size()==facts.size() and facts.map(func(c):return c.key)==view.display_facts.map(func(c):return c.key),"ARCH distinct stable display identities survive repeat projection "+label)

static func equipment_read_batches(t) -> void:
 equipment_projection_batches(t)
 preview_read_batches(t)
 var g=Game.new(42)
 g.state.equipment.clear()
 for i in range(3):
  for slot in g.B.SLOTS: g.add_fixture(slot,7,10)
 var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
 var before=g.export_snapshot()
 t.check(g.validate()=="" and g.physical_pieces().size()>20,"ARCH dense equipment fixture respects formal capacities")
 t.check(g.get_view()==reference.get_view() and g.command_facts()==reference.command_facts(),"ARCH dense indexed queries preserve every candidate, value and visible text")
 t.check(g.state==before and g._equipment_read.is_empty(),"ARCH dense reads leave state, random cursors and query lifetime unchanged")
 var target=g.equipment_at("wrist")[0]
 target.durability=2
 reference.state=g.state.duplicate(true)
 t.check(g.get_view()==reference.get_view(),"ARCH new read observes changed equipment even without a version increment")
 var previous=g._begin_equipment_read()
 var members=g.equipment_at("wrist");members.clear()
 t.check(not g.equipment_at("wrist").is_empty(),"ARCH sorting or clearing a returned query array cannot corrupt the index")
 var original=g.state;g.state=original.duplicate(true);g.state.equipment.clear()
 t.check(g.equipment_at("wrist").is_empty() and g._equipment(target.id).is_empty(),"ARCH speculative replacement state bypasses the outer read index")
 g.state=original
 t.check(g._equipment(target.id)==target and not g.equipment_at("wrist").is_empty(),"ARCH returning from speculation restores the original query context")
 g._equipment_read=previous
 g=Game.new(42);g._discard_end();g.state.energy=2
 preload("res://tests/curse_cases.gd").give(g,"self_binding")
 projection_contract(t,g,"self-binding speculative installation")

# docs/spec/equipment-query-seam.md「证据入口」: each edge materializes at most once per scope and never outside one.
static func index_materializes_once_per_scope(t) -> void:
 var g=IndexCountingGame.new(42)
 g.state.equipment.clear()
 for slot in g.B.SLOTS: g.add_fixture(slot,7,10)
 var before=g.export_snapshot()
 # Count only this window: earlier read-only entries (plan/offer/contact calls) legitimately
 # opened and released scopes of their own during construction.
 g.piece_builds=0;g.slot_builds=0;g.id_builds=0;g.capacity_builds=0;g.physical_builds=0
 g.target_builds=0;g.walk_calls=0
 g.physical_queries=0;g.equipment_at_queries=0;g.composite_root_queries=0;g.links_at_queries=0
 var previous=g._begin_equipment_read()
 t.check(g.piece_builds==1 and g.slot_builds==1 and g.id_builds==1 and g.capacity_builds==1 and g.physical_builds==1 and g.target_builds==1,"INDEX entry materializes the piece set and every edge once per scope")
 var walk_calls=g.walk_calls
 var physical_queries=g.physical_queries
 var equipment_at_queries=g.equipment_at_queries
 var composite_root_queries=g.composite_root_queries
 var links_at_queries=g.links_at_queries
 var slots=index_target_slots(g)
 for step in range(2):
  for slot in slots: g.targets_at(slot)
 t.check(g.target_builds==1 and g.walk_calls==walk_calls and g.physical_queries==physical_queries and g.equipment_at_queries==equipment_at_queries and g.composite_root_queries==composite_root_queries and g.links_at_queries==links_at_queries,"INDEX repeated targets_at queries inside one scope never rebuild or reassemble the slot-target edge")
 for slot in slots:
  g.targets_at(slot);g.equipment_at(slot);g.occupied(slot)
 t.check(g.slot_builds==1 and g.piece_builds==1,"INDEX equipment_at and occupied stay on the slot edge")
 for slot in g.B.SLOTS: g.equipment_at(slot)
 for step in range(3): g.physical_pieces()
 var ids=g.physical_pieces().map(func(e):return e.id)
 for id in ids: g._equipment(id)
 for slot in g.B.SLOTS: g.capacity_used(slot)
 for point in g.Equipment.ANATOMY: g._point_count(point)
 t.check(g.piece_builds==1 and g.slot_builds==1 and g.id_builds==1 and g.capacity_builds==1 and g.physical_builds==1,"INDEX repeated slot, id and point queries inside one scope never rebuild an edge")
 var members=g.equipment_at("wrist");members.clear();members.append({})
 t.check(not g.equipment_at("wrist").is_empty(),"INDEX clearing a materialized slot answer cannot corrupt the edge")
 var listed=g.targets_at("wrist")
 var listed_size=listed.size()
 listed.sort_custom(func(a,b):return str(a.get("id",""))<str(b.get("id","")))
 listed.clear();listed.append({})
 t.check(g.targets_at("wrist").size()==listed_size and not g.equipment_at("wrist").is_empty(),"INDEX clearing a materialized targets_at answer cannot corrupt later slot or target queries")
 var built=g.piece_builds;var slot_builds=g.slot_builds;var id_builds=g.id_builds
 var capacity_builds=g.capacity_builds;var physical_builds=g.physical_builds
 var target_builds=g.target_builds
 g._equipment_read=previous
 t.check(g._equipment_read.is_empty(),"INDEX read scope releases its materialized edges")
 for step in range(3):
  g.equipment_at("wrist");g.physical_pieces();g.targets_at("wrist")
 for id in ids: g._equipment(id)
 for slot in g.B.SLOTS: g.capacity_used(slot)
 for point in g.Equipment.ANATOMY: g._point_count(point)
 t.check(g.piece_builds==built and g.slot_builds==slot_builds and g.id_builds==id_builds and g.capacity_builds==capacity_builds and g.physical_builds==physical_builds and g.target_builds==target_builds,"INDEX queries without a scope never build an edge table")
 t.check(g.export_snapshot()==before,"INDEX materialization leaves state, logs and random cursors unchanged")

# docs/spec/equipment-query-seam.md「证据入口」: an inconsistent graph voids the whole scope, records one named issue
# and answers every later query in that scope from the live path.
static func index_self_check_falls_back(t) -> void:
 var root=Game.new(42,true,"component_links")
 root.state.composites[0].components[0].root_id=root.state.composites[1].id
 var host=Game.new(42,true,"shoulder_links")
 var special=host._install_special("nipple_clamp_medium","special_1_a")
 host.state.equipment[0].shoulders.pieces[0].shoulder_host=special.id
 var twin=Game.new(42,true,"shoulder_links")
 twin.state.equipment.append(twin.state.equipment[0].duplicate(true))
 for damage in [{"label":"component root mismatch","game":root,"check":1},{"label":"shoulder host outside the piece set","game":host,"check":2},{"label":"two instances sharing one id","game":twin,"check":3}]:
  var g=damage.game
  var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var recorded=g._equipment_index_issues.size()
  var view=g.get_view()
  var facts=g.command_facts()
  t.check(view==reference.get_view() and facts==reference.command_facts(),"INDEX damaged graph answers exactly like the live reference "+damage.label)
  var issues=g._equipment_index_issues
  t.check(issues.size()==recorded+2 and issues[-1].check==damage.check and issues[-1].edge!="" and issues[-1].id!="","INDEX one named record per voided scope "+damage.label+": "+str(issues))
  t.check(g._equipment_read.is_empty() and g.export_snapshot()==before,"INDEX fallback leaves no scope, state, log or save change "+damage.label)
 var dangling=Game.new(42,true,"shoulder_links")
 var piece=dangling.state.equipment[0].shoulders.pieces[0]
 piece.shoulder_host="missing_host"
 var live_reference=UncachedGame.new(42);live_reference.state=dangling.state.duplicate(true)
 var dangling_before=dangling.export_snapshot()
 var recorded=dangling._equipment_index_issues.size()
 var dangling_scope=dangling._begin_equipment_read()
 # The live projection aborts on a dangling shoulder host, so this fixture compares leaf queries only.
 var parity=dangling.physical_pieces()==live_reference.physical_pieces() and dangling.equipment_at(piece.slot)==live_reference.equipment_at(piece.slot) and dangling._equipment_name(piece)==live_reference._equipment_name(live_reference._equipment(piece.id))
 t.check(parity and dangling._equipment_index_issues.size()==recorded+1 and dangling._equipment_index_issues[-1].check==2,"INDEX dangling shoulder host voids the scope before display code reads it")
 dangling._equipment_read=dangling_scope
 t.check(dangling._equipment_read.is_empty() and dangling.export_snapshot()==dangling_before,"INDEX dangling host fallback leaves no scope or state change")

# docs/spec/equipment-query-seam.md「证据入口」: the materialized id edge answers like the live lookup over every target
# family and keeps the authoritative instance reference.
static func index_id_edge_parity(t) -> void:
 for kind in ["plain","component_links","shoulder_links","torso_binding","special_equipment"]:
  var g=Game.new(42,true,kind) if kind!="plain" else Game.new(42)
  if kind=="plain":
   for slot in ["wrist","ankle","thigh"]: g.add_fixture(slot,7,10)
  var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var targets=reference.action_targets()
  var previous=g._begin_equipment_read()
  var indexed={}
  for target in targets: indexed[target.id]=g._equipment(target.id)
  var parity=not targets.is_empty()
  for target in targets:
   parity=parity and not indexed[target.id].is_empty() and indexed[target.id]==target
  parity=parity and g._equipment("missing_id").is_empty()
  g._equipment_read=previous
  for target in targets:
   parity=parity and is_same(indexed[target.id],g._equipment(target.id))
  t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX id edge parity with the live path "+kind)
 var plain=Game.new(42)
 var piece=plain.add_fixture("thigh",7,10)
 var scope=plain._begin_equipment_read()
 plain._equipment(piece.id).durability=3
 plain._equipment_read=scope
 t.check(plain.state.equipment.filter(func(e):return e.id==piece.id)[0].durability==3,"INDEX id edge writes through to the authoritative instance, never to a copy")

# docs/spec/equipment-query-seam.md「证据入口」: presence and count predicates keep their live-query values on the indexed
# read path, including the hand truth table and the non-authoritative capacity argument.
static func index_predicate_parity(t) -> void:
 var cases=[]
 var single=Game.new(42)
 single.state.equipment.clear()
 single.add_fixture("palm",4,10).side="left"
 cases.append({"label":"single-sided palm","game":single,"slot":"palm","occupied":false,"left":true,"right":false})
 var both=Game.new(42)
 both.state.equipment.clear()
 both.add_fixture("palm",4,10).side="left"
 both.add_fixture("fingers",4,10).side="right"
 cases.append({"label":"separate hand sides","game":both,"slot":"palm","occupied":false,"left":true,"right":false})
 var sideless=Game.new(42)
 sideless.state.equipment.clear()
 sideless.add_fixture("fingers",4,10)
 cases.append({"label":"side-less hand piece","game":sideless,"slot":"fingers","occupied":true,"left":true,"right":true})
 for kind in ["component_links","special_equipment","shoulder_links"]:
  cases.append({"label":kind,"game":Game.new(42,true,kind)})
 for entry in cases:
  var g=entry.game
  var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var previous=g._begin_equipment_read()
  var parity=true
  for slot in g.B.SLOTS:
   parity=parity and g.occupied(slot)==reference.occupied(slot)
   for side in ["left","right"]: parity=parity and g.hand_blocked(slot,side)==reference.hand_blocked(slot,side)
   parity=parity and g.capacity_used(slot)==reference.capacity_used(slot)
  for point in g.Equipment.ANATOMY: parity=parity and g._point_count(point)==reference._point_count(point)
  parity=parity and g._capacity_issue(g.physical_pieces())==reference._capacity_issue(reference.physical_pieces())
  parity=parity and g._capacity_issue(g.physical_pieces()+g.state.equipment.duplicate())==reference._capacity_issue(reference.physical_pieces()+reference.state.equipment.duplicate())
  parity=parity and g._capacity_issue(g.state.equipment.slice(0,1))==reference._capacity_issue(reference.state.equipment.slice(0,1))
  if entry.has("slot"):
   parity=parity and g.occupied(entry.slot)==entry.occupied and g.hand_blocked(entry.slot,"left")==entry.left and g.hand_blocked(entry.slot,"right")==entry.right
  g._equipment_read=previous
  t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX predicate parity with the live path "+entry.label)
 var dense=Game.new(42)
 dense.state.equipment.clear()
 for slot in dense.B.SLOTS: dense.add_fixture(slot,7,10)
 var dense_reference=UncachedGame.new(42);dense_reference.state=dense.state.duplicate(true)
 var dense_scope=dense._begin_equipment_read()
 var doubled=dense._capacity_issue(dense.physical_pieces()+dense.state.equipment.duplicate())
 t.check(doubled!="" and doubled==dense_reference._capacity_issue(dense_reference.physical_pieces()+dense_reference.state.equipment.duplicate()),"INDEX non-authoritative capacity argument keeps its live reason text: "+doubled)
 t.check(dense.capacity_used("wrist")==dense_reference.capacity_used("wrist") and dense.occupied("wrist") and dense.hand_blocked("wrist","left"),"INDEX dense counts and presence match the live path")
 dense._equipment_read=dense_scope

static func _has_targets_slots(g) -> Array:
 var slots=g.B.SLOTS.duplicate()
 slots.append("shoulder")
 slots.append_array(g.SpecialEquipment.slots())
 return slots

static func _clear_gear(g) -> void:
 g.state.equipment.clear()
 g.state.composites.clear()
 g.state.links.clear()
 g.state.special_equipment.clear()

static func _link_slot_without_equipment(g) -> String:
 for slot in g.B.SLOTS:
  if g.equipment_at(slot).is_empty() and not g.links_at(slot).is_empty(): return slot
 return ""

static func _composite_contact_outside_equipment(g, jacket) -> Array:
 var coverage=g.Composites.definition(jacket).coverage
 var result=[]
 for slot in coverage:
  var hosted=ids_for(g.equipment_at(slot))
  for e in jacket.components:
   if not hosted.has(e.id): result.append({"slot":slot,"id":e.id})
 return result

static func _check_has_targets_at_once(t, g, label: String, early_slot: String="") -> Dictionary:
 var slots=_has_targets_slots(g)
 var snap=g.export_snapshot()
 var rng=g.state.rng.duplicate(true)
 var baselines={}
 for slot in slots:
  baselines[slot]=g.targets_at(slot)
 var oracles={}
 for slot in slots:
  oracles[slot]=not baselines[slot].is_empty()
 var predicted={}
 for slot in slots:
  g.reset_walk_counts()
  predicted[slot]=g.has_targets_at(slot)
  t.check(g.targets_at_slots.is_empty(),"has_targets_at_parity: predicate does not call targets_at "+label+" "+slot)
  t.check(predicted[slot]==oracles[slot],"has_targets_at_parity: bool equals oracle "+label+" "+slot+" have="+str(predicted[slot])+" oracle="+str(oracles[slot]))
  if slot==early_slot:
   t.check(g.composite_root_calls==0 and g.links_at_calls==0,"has_targets_at_parity: first hit skips later sources "+label+" "+slot+" roots="+str(g.composite_root_calls)+" links="+str(g.links_at_calls))
  var after=g.targets_at(slot)
  t.check(after==baselines[slot] and ids_for(after)==ids_for(baselines[slot]),"has_targets_at_parity: targets_at order and ids unchanged "+label+" "+slot)
  for i in range(after.size()):
   t.check(is_same(after[i],baselines[slot][i]),"has_targets_at_parity: targets_at instance identity "+label+" "+slot)
 t.check(g.export_snapshot()==snap and g.state.rng==rng,"has_targets_at_parity: snapshot and rng frozen "+label)
 return predicted

static func _check_has_targets_at_modes(t, g, label: String, early_slot: String="") -> void:
 var live=_check_has_targets_at_once(t,g,label+"/live",early_slot)
 var snap=g.export_snapshot()
 var previous=g._begin_equipment_read()
 var scoped=_check_has_targets_at_once(t,g,label+"/scope",early_slot)
 for slot in live:
  t.check(live[slot]==scoped[slot],"has_targets_at_parity: live equals scope "+label+" "+slot)
 g._equipment_read=previous
 t.check(g._equipment_read.is_empty() and g.export_snapshot()==snap,"has_targets_at_parity: scope released "+label)
 var invalid_previous=g._begin_equipment_read()
 g._equipment_read.invalid=true
 var fallback=_check_has_targets_at_once(t,g,label+"/invalid-fallback",early_slot)
 for slot in live:
  t.check(live[slot]==fallback[slot],"has_targets_at_parity: invalid index live fallback "+label+" "+slot)
 g._equipment_read=invalid_previous
 t.check(g._equipment_read.is_empty(),"has_targets_at_parity: invalid fallback released "+label)

# docs/spec/equipment-query-seam.md: has_targets_at shares the targets_at per-slot walk.
static func has_targets_at_parity(t) -> void:
 var empty=TargetWalkCountingGame.new(42)
 _clear_gear(empty)
 _check_has_targets_at_modes(t,empty,"empty")
 for slot in _has_targets_slots(empty):
  t.check(empty.targets_at(slot).is_empty(),"has_targets_at_parity: empty fixture oracle is empty "+slot)
 var palm=TargetWalkCountingGame.new(42)
 _clear_gear(palm)
 var palm_piece=palm.add_fixture("palm",4,10)
 palm_piece.side="left"
 _check_has_targets_at_modes(t,palm,"one-sided palm","palm")
 t.check(not palm.occupied("palm"),"has_targets_at_parity: one-sided palm occupied stays false")
 t.check(palm.has_targets_at("palm") and ids_for(palm.targets_at("palm")).has(palm_piece.id),"has_targets_at_parity: one-sided palm id in targets_at")
 var fingers=TargetWalkCountingGame.new(42)
 _clear_gear(fingers)
 var fingers_piece=fingers.add_fixture("fingers",4,10)
 fingers_piece.side="left"
 _check_has_targets_at_modes(t,fingers,"one-sided fingers","fingers")
 t.check(not fingers.occupied("fingers"),"has_targets_at_parity: one-sided fingers occupied stays false")
 t.check(fingers.has_targets_at("fingers") and ids_for(fingers.targets_at("fingers")).has(fingers_piece.id),"has_targets_at_parity: one-sided fingers id in targets_at")
 var link_g=TargetWalkCountingGame.new(42)
 _clear_gear(link_g)
 var root=link_g._install_assembly("leg","upper","fixture",2,2)
 var body=root.components.filter(func(e):return e.part=="body")[0]
 var band=link_g._install_template("rope",link_g.Links.point_slot("below_knee"),8,10,false,"fixture",1,-1,0,"below_knee")
 var rope=link_g._install_link(body.id,band.id,8,"fixture",1,[],["thigh","calf"],["above_knee","below_knee"])
 t.check(not rope.is_empty(),"has_targets_at_parity: live link fixture")
 _check_has_targets_at_modes(t,link_g,"live link","thigh")
 var link_only=TargetWalkCountingGame.new(42)
 _clear_gear(link_only)
 var only_root=link_only._install_assembly("leg","upper","fixture",2,2)
 var only_body=only_root.components.filter(func(e):return e.part=="body")[0]
 var only_band=link_only._install_template("rope",link_only.Links.point_slot("below_knee"),8,10,false,"fixture",1,-1,0,"below_knee")
 var only_rope=link_only._install_link(only_body.id,only_band.id,8,"fixture",1,[],["thigh","calf"],["above_knee","below_knee"])
 t.check(not only_rope.is_empty(),"has_targets_at_parity: link-only fixture")
 for slot in ["thigh","calf"]:
  for e in link_only.equipment_at(slot): e.durability=0
 var link_slot=_link_slot_without_equipment(link_only)
 t.check(link_slot!="","has_targets_at_parity: live link covers empty equipment_at")
 if link_slot!="":
  t.check(link_only.has_targets_at(link_slot) and ids_for(link_only.links_at(link_slot)).has(only_rope.id),"has_targets_at_parity: live link covers empty equipment_at "+link_slot)
  t.check(ids_for(link_only.targets_at(link_slot)).has(only_rope.id),"has_targets_at_parity: live link id in targets_at "+link_slot)
  only_rope.durability=0
  t.check(not link_only.has_targets_at(link_slot) and link_only.links_at(link_slot).is_empty(),"has_targets_at_parity: dead link empty equipment_at is false "+link_slot)
 rope.durability=0
 _check_has_targets_at_modes(t,link_g,"dead link","thigh")
 t.check(link_g.links_at("thigh").is_empty() and link_g.links_at("calf").is_empty(),"has_targets_at_parity: dead link leaves links_at")
 var glove_g=TargetWalkCountingGame.new(42)
 _clear_gear(glove_g)
 var glove=glove_g._install_assembly("glove","short","fixture",2,2)
 t.check(not glove.is_empty() and glove_g.Composites.active(glove),"has_targets_at_parity: active composite fixture")
 _check_has_targets_at_modes(t,glove_g,"active composite","upper_arm")
 var glove_body=glove.components.filter(func(e):return e.part=="body")[0]
 glove_body.durability=0
 t.check(not glove_g.Composites.active(glove),"has_targets_at_parity: disabled composite inactive")
 _check_has_targets_at_modes(t,glove_g,"disabled composite")
 var jacket_g=TargetWalkCountingGame.new(42)
 _clear_gear(jacket_g)
 var jacket=jacket_g._install_assembly("jacket","standard","fixture",2,2)
 t.check(not jacket.is_empty() and jacket_g.Composites.active(jacket),"has_targets_at_parity: jacket composite fixture")
 _check_has_targets_at_modes(t,jacket_g,"active jacket","upper_arm")
 var outside=_composite_contact_outside_equipment(jacket_g,jacket)
 t.check(not outside.is_empty(),"has_targets_at_parity: composite contact outside equipment_at")
 var sleeve=jacket.components.filter(func(e):return e.part=="sleeves")
 var hem=jacket.components.filter(func(e):return e.part=="hem")
 t.check(not sleeve.is_empty() and outside.any(func(c):return c.id==sleeve[0].id),"has_targets_at_parity: sleeves contact outside equipment_at")
 t.check(not hem.is_empty() and outside.any(func(c):return c.id==hem[0].id),"has_targets_at_parity: hem contact outside equipment_at")
 for contact in outside:
  t.check(jacket_g.has_targets_at(contact.slot) and ids_for(jacket_g.targets_at(contact.slot)).has(contact.id),"has_targets_at_parity: composite contact id in targets_at "+contact.slot+" "+str(contact.id))
 var jacket_body=jacket.components.filter(func(e):return e.part=="body")[0]
 jacket_body.durability=0
 t.check(not jacket_g.Composites.active(jacket),"has_targets_at_parity: disabled jacket inactive")
 for contact in outside:
  t.check(not jacket_g.has_targets_at(contact.slot),"has_targets_at_parity: disabled jacket slot follows composite "+contact.slot)
 _check_has_targets_at_modes(t,jacket_g,"disabled jacket")
 var sh=TargetWalkCountingGame.new(42)
 _clear_gear(sh)
 sh._install_template("rope","upper_arm",sh.Equipment.maximum(2),sh.Equipment.maximum(2),false,"fixture",2)
 _check_has_targets_at_modes(t,sh,"shoulder")
 t.check(sh.has_targets_at("shoulder") and sh.equipment_at("shoulder").is_empty(),"has_targets_at_parity: shoulder has targets without equipment_at")
 t.check(sh.targets_at("shoulder").any(func(e):return sh.Equipment.is_shoulder(e)),"has_targets_at_parity: shoulder hit is_shoulder")
 var sp=TargetWalkCountingGame.new(42)
 _clear_gear(sp)
 var clamp=sp._install_special("nipple_clamp_low","special_1_a")
 t.check(not clamp.is_empty(),"has_targets_at_parity: special fixture")
 _check_has_targets_at_modes(t,sp,"special")
 var special_slots=sp.SpecialEquipment.occupied_slots(clamp)
 t.check(not special_slots.is_empty() and special_slots.all(func(slot):return sp.has_targets_at(slot)),"has_targets_at_parity: special slot has targets")
 t.check(not special_slots.is_empty() and ids_for(sp.state.special_equipment).has(clamp.id) and ids_for(sp.targets_at(special_slots[0])).has(clamp.id),"has_targets_at_parity: special id in special_equipment and targets_at")
 var crotch_g=TargetWalkCountingGame.new(42)
 _clear_gear(crotch_g)
 var crotch=crotch_g._install_special("crotch_rope_low","special_3_a")
 var crotch_link=crotch_g._install_link(crotch.id,crotch_g.add_fixture("wrist",8).id,8,"fixture")
 t.check(not crotch.is_empty() and not crotch_link.is_empty(),"has_targets_at_parity: crotch link fixture")
 _check_has_targets_at_modes(t,crotch_g,"crotch link","wrist")
 t.check(crotch_g.has_targets_at("special_3_a") and (ids_for(crotch_g.state.special_equipment).has(crotch.id) or ids_for(crotch_g.links_at("special_3_a")).has(crotch_link.id)),"has_targets_at_parity: special slot from special_equipment or links_at")
 t.check(ids_for(crotch_g.targets_at("special_3_a")).has(crotch.id),"has_targets_at_parity: crotch special id in targets_at")
 var bind_g=null
 for seed in range(1,100):
  var candidate=TargetWalkCountingGame.new(seed,true,"torso_binding")
  if candidate.state.equipment[0].binding.kind=="linked":
   bind_g=candidate
   break
 t.check(bind_g!=null,"has_targets_at_parity: linked torso binding fixture")
 if bind_g!=null:
  var host=bind_g.state.equipment[0]
  _check_has_targets_at_modes(t,bind_g,"connection",host.slot)
  var conns=bind_g.Binding.connections(bind_g)
  t.check(not conns.is_empty(),"has_targets_at_parity: Binding.connections contribute")
  if not conns.is_empty():
   var conn=conns[0]
   t.check(bind_g.has_targets_at(conn.slot) and ids_for(bind_g.targets_at(conn.slot)).has(conn.id),"has_targets_at_parity: connection id in targets_at "+conn.slot)
   t.check(not ids_for(bind_g.equipment_at(conn.slot)).has(conn.id),"has_targets_at_parity: connection not from equipment_at "+conn.slot)

# docs/spec/equipment-query-seam.md「证据入口」: every declared outer entry opens and releases its own scope and answers
# exactly like the index-off reference; entries that swap state still leave no scope behind.
static func index_entry_parity(t) -> void:
 var g=IndexCountingGame.new(42)
 g.add_fixture("wrist",4,10)
 g.add_fixture("thigh",8,10)
 var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
 var before=g.export_snapshot()
 var enemy=reference.state.enemies[0]
 # Each entry opens exactly one scope and releases it before returning.
 var opened=g.piece_builds
 var parity=ids_for(g.EnemyPlans.targets(g,enemy,"tighten"))==ids_for(reference.EnemyPlans.targets(reference,enemy,"tighten")) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and ids_for(g.EnemyPlans.targets(g,enemy,"lock"))==ids_for(reference.EnemyPlans.targets(reference,enemy,"lock")) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.Contact.workspace(g,"cut")==reference.Contact.workspace(reference,"cut") and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.Contact.workspace(g,"manual")==reference.Contact.workspace(reference,"manual") and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 var options=g.EquipmentOffers.ordinary(g)
 parity=parity and options==reference.EquipmentOffers.ordinary(reference) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.EquipmentOffers.preferred(g,options)==reference.EquipmentOffers.preferred(reference,options) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.EquipmentOffers.for_pool(g,2,["rope","belt"])==reference.EquipmentOffers.for_pool(reference,2,["rope","belt"]) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.EquipmentOffers.links(g,2)==reference.EquipmentOffers.links(reference,2) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and ids_for(g.Cards.SelfBinding.tighten_targets(g))==ids_for(reference.Cards.SelfBinding.tighten_targets(reference)) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.Cards.SelfBinding.capacity(g)==reference.Cards.SelfBinding.capacity(reference) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.Events.selector_values(g,{"kind":"restraint"})==reference.Events.selector_values(reference,{"kind":"restraint"}) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.Events.selector_values(g,{"kind":"card"})==reference.Events.selector_values(reference,{"kind":"card"}) and g._equipment_read.is_empty() and g.piece_builds==opened
 opened=g.piece_builds
 parity=parity and g._prepare_assembly("glove","short","fixture")==reference._prepare_assembly("glove","short","fixture") and g._equipment_read.is_empty() and g.piece_builds==opened+1
 t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX read-only entries answer like the live reference, open one scope each and release it")
 var compiled=g.Events.compile(g,"tighten_or_medium")
 var compiled_reference=reference.Events.compile(reference,"tighten_or_medium")
 t.check(compiled==compiled_reference and g.export_snapshot()==reference.export_snapshot() and g._equipment_read.is_empty(),"INDEX event compilation advances the same random domain and releases its scope")
 var captured=Game.new(42,true,"guard")
 captured.state.security=5
 Guard.capture(captured,captured.state.enemies[0])
 var prison_reference=UncachedGame.new(42);prison_reference.state=captured.state.duplicate(true)
 var opened_prison=captured._equipment_read
 var entered=captured.Prison.enter(captured)
 var entered_reference=prison_reference.Prison.enter(prison_reference)
 t.check(entered==entered_reference and captured.export_snapshot()==prison_reference.export_snapshot() and captured._equipment_read.is_empty() and is_same(opened_prison,captured._equipment_read), "INDEX security-five prison entry matches the live reference without opening a tail scope")
 var prison_validate=captured.validate()
 var prison_validate_reference=prison_reference.validate()
 t.check(prison_validate==prison_validate_reference and captured.Prison.validate(captured)==prison_reference.Prison.validate(prison_reference) and captured._equipment_read.is_empty(),"INDEX nested prison validation agrees with the live reference")

static func equipment_projection_batches(t) -> void:
 var g=Game.new(42,true,"jacket")
 var target=g.physical_pieces().filter(func(e):return e.template=="jacket_body")[0]
 var slots=g.Equipment.coverage(target)
 var before=g.export_snapshot()
 var previous=g._begin_equipment_read()
 var first=g.View.equipment_entry(g,target,slots[0])
 first.description="changed";first.slot="changed";first.extra={"changed":true}
 var second=g.View.equipment_entry(g,target,slots[-1])
 var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
 t.check(second==reference.View.equipment_entry(reference,reference._equipment(target.id),slots[-1]),"ARCH shared equipment description retains the requested body slot without leaked annotations")
 t.check(g._equipment_read.equipment_views.size()==1 and not second.has("extra"),"ARCH cross-slot equipment projection builds one isolated base row")
 var copied=target.duplicate(true);copied.durability=1
 t.check(g.View.equipment_entry(g,copied,slots[0])==reference.View.equipment_entry(reference,copied,slots[0]),"ARCH copied equipment object bypasses canonical display reuse")
 var original=g.state;g.state=original.duplicate(true);g._equipment(target.id).durability=1
 reference.state=g.state.duplicate(true)
 t.check(g.View.equipment_entry(g,g._equipment(target.id),slots[0])==reference.View.equipment_entry(reference,reference._equipment(target.id),slots[0]),"ARCH temporary state cannot reuse the outer equipment description")
 g.state=original;g._equipment_read=previous
 t.check(g.export_snapshot()==before and g._equipment_read.is_empty(),"ARCH equipment display batch does not retain state references or mutate gameplay")
 target.durability=1
 reference.state=g.state.duplicate(true)
 t.check(g.get_view()==reference.get_view(),"ARCH subsequent full projection observes changed durability without a version increment")

static func preview_read_batches(t) -> void:
 var g=PreviewCountingGame.new(42)
 g.state.equipment.clear();g.state.relics=[]
 var target=g.add_fixture("thigh",7,10)
 g.add_fixture("thigh",5,10)
 var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
 var before=g.export_snapshot()
 var previous=g._begin_equipment_read()
 var profiles=g.HandAssist.profiles(g)
 var equivalent=true
 for mode in ["strain","slip","magic_slip"]:
  for base in [7.0,7.000000000001]:
   for flags in range(16):
    var arguments=[target,mode,base,profiles,bool(flags&1),bool(flags&2),bool(flags&4),bool(flags&8)]
    var expected=reference.escape_preview(reference._equipment(target.id),mode,base,profiles,bool(flags&1),bool(flags&2),bool(flags&4),bool(flags&8))
    equivalent=equivalent and g.callv("escape_preview",arguments)==expected and g.callv("escape_preview",arguments)==expected
 t.check(equivalent,"ARCH preview reuse preserves mode, full precision base and every passive/area/continuation/splash combination")
 t.check(g.escape_builds==96,"ARCH identical full-argument previews calculate once within the read batch")
 var preview=g.escape_preview(target,"strain",7,profiles)
 preview.assist.hands.clear();preview.assist.bonus=-999;preview.position.factor=-999
 t.check(g.escape_preview(target,"strain",7,profiles)==reference.escape_preview(reference._equipment(target.id),"strain",7,profiles),"ARCH nested result edits cannot poison a reused escape preview")
 var original_profiles=profiles.duplicate(true)
 profiles[0].points.clear();profiles[0].assist_factor=0.25
 t.check(g.escape_preview(target,"strain",7,profiles)==reference.escape_preview(reference._equipment(target.id),"strain",7,profiles),"ARCH changed nested hand profiles do not reuse earlier assistance")
 t.check(g.escape_preview(target,"strain",7,original_profiles)==reference.escape_preview(reference._equipment(target.id),"strain",7,original_profiles),"ARCH reused input arrays cannot rewrite an earlier preview key")
 var copy=target.duplicate(true);copy.durability=1
 t.check(g.escape_preview(copy,"slip",7)==reference.escape_preview(copy,"slip",7),"ARCH copied target with the same ID bypasses canonical preview reuse")
 var cast_profiles=[{"parts":["mouth"],"multiplier":1.0},{"parts":["hand","mouth"],"multiplier":1.0},{"parts":["hand"],"multiplier":1.0,"body_free":true},{"parts":["mouth"],"multiplier":0.5},{"parts":["mouth"],"multiplier":1.0,"chance_bonus":0.1},{"parts":["mouth"],"multiplier":1.0,"paid_cast":false}]
 equivalent=true
 for profile in cast_profiles:
  equivalent=equivalent and g.cast_view(profile)==reference.cast_view(profile) and g.cast_view(profile)==reference.cast_view(profile)
 t.check(equivalent and g.cast_builds==cast_profiles.size(),"ARCH casting reuses only equal complete profiles including routes, free-body, multiplier, bonus and payment")
 var casting=g.cast_view(cast_profiles[0]);casting.factors.append({"invalid":true});casting.chance=-1
 cast_profiles[0].parts.append("hand")
 t.check(g.cast_view(cast_profiles[0])==reference.cast_view(cast_profiles[0]) and g.cast_view()==reference.cast_view(),"ARCH casting input and output mutations cannot poison another route")
 var original=g.state;g.state=original.duplicate(true);g.state.pressure=80;g._equipment(target.id).durability=1
 reference.state=g.state.duplicate(true)
 var temporary=g._begin_equipment_read()
 t.check(g.cast_view()==reference.cast_view() and g.escape_preview(g._equipment(target.id),"slip",7)==reference.escape_preview(reference._equipment(target.id),"slip",7),"ARCH nested speculative state gets its own cast and escape previews")
 g._equipment_read=temporary;g.state=original;reference.state=original.duplicate(true)
 t.check(g.cast_view()==reference.cast_view() and g.escape_preview(target,"strain",7,original_profiles)==reference.escape_preview(reference._equipment(target.id),"strain",7,original_profiles),"ARCH original previews survive temporary state restoration")
 g._equipment_read=previous
 t.check(g.export_snapshot()==before and g._equipment_read.is_empty(),"ARCH preview batch leaves no state/RNG writes or retained results")
 g.state.pressure=80;target.durability=1;reference.state=g.state.duplicate(true)
 t.check(g.cast_view()==reference.cast_view() and g.escape_preview(target,"slip",7)==reference.escape_preview(reference._equipment(target.id),"slip",7),"ARCH subsequent live read observes resource and durability changes without version increment")
 for kind in ["component_links","shoulder_links","torso_binding","special_equipment"]:
  g=PreviewCountingGame.new(42,true,kind)
  reference.state=g.state.duplicate(true)
  t.check(g.get_view()==reference.get_view(),"ARCH preview reuse preserves composite/link/special projection "+kind)
  for step in range(2):
   var available=g.command_facts().filter(func(c):return c.valid and c.payload.kind=="card")
   if available.is_empty(): break
   var candidate=available[0]
   var outcome=g.dispatch(g.command(candidate.payload,g.state.version),g.state.version)
   var expected=reference.dispatch(reference.command(candidate.payload,reference.state.version),reference.state.version)
   t.check(outcome==expected and outcome.ok and g.export_snapshot()==reference.export_snapshot(),"ARCH preview reuse preserves actual payment, RNG and cleanup across sequential card commits "+kind+"/"+str(step))

static func current_effect_boundaries(t) -> void:
 var g=Game.new(42)
 g._discard_end();g.state.energy=30;g.state.relics=[];g.state.flask_mana=20
 for entry in [["echo_cast",false],["adaptability",false],["fire_control",false],["echo_cast",true]]:
  var card=preload("res://tests/curse_cases.gd").give(g,entry[0])
  t.check(t.action(g,"card",{"uid":card.uid,"free":entry[1]}).ok,"ARCH current effect uses formal card transaction "+entry[0])
 t.check(g.state.powers.size()==1 and g.state.powers[0].power_stacks==2 and g.state.temporary_mana==10 and "echo_cast_free" in g.state.card_buffs and g.validate()=="","ARCH fixture combines doubled power, temporary mana and pending replay")
 projection_contract(t,g,"active powers and split payment")
 g.RelicEffects.end_combat(g)
 g._start_rest()
 t.check(g.state.phase=="rest_choice" and not g.state.combat.active and g.state.temporary_mana==10 and g.state.powers.is_empty() and g.state.card_buffs.is_empty(),"ARCH rest choice retains temporary mana while clearing abilities and pending replay")
 projection_contract(t,g,"frozen rest choices")
 t.check(t.action(g,"rest_begin").ok and g.state.combat.active,"ARCH rest begins through its formal command")
 projection_contract(t,g,"new rest session")

static func instance_effect_boundaries(t) -> void:
 var control=preload("res://tests/first_turn_control_cases.gd").enter(t,"battle",1)
 projection_contract(t,control,"manual zero-energy first turn")
 var attachment=preload("res://tests/mana_attachment_cases.gd")
 var powered=attachment.setup()
 attachment.activate(t,powered,false);attachment.activate(t,powered,true)
 projection_contract(t,powered,"independent active power faces")
 t.check(attachment.toggle(t,powered,true).ok,"ARCH power switch uses the common status command")
 projection_contract(t,powered,"one disabled power face")
 var f=preload("res://tests/concentration_cases.gd").setup()
 var g=f.g
 t.check(t.action(g,"card",{"uid":f.card.uid,"target":f.target.id,"free":true}).ok,"ARCH second bound face grows through the formal action")
 projection_contract(t,g,"physical card growth on second bound face")
 var checkpoint=g.restart_snapshot()
 var before=g.export_snapshot()
 var exposed=g.restart_snapshot()
 exposed.hand.clear();exposed.rng.clear()
 t.check(g.restart_snapshot()==checkpoint and g.export_snapshot()==before,"ARCH external restart snapshot cannot alter checkpoint or current state")
 g=Rewards.setup()
 var card=Rewards.give(t,g,"strain")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.charge==1,"ARCH preparation grants charge through the real card")
 t.check(t.action(g,"status_toggle",{"status":"charge","enabled":true}).ok,"ARCH charge mode uses the common command boundary")
 projection_contract(t,g,"prepared charge and all-stack mode")

 g=Game.new(42,true,"shop")
 t.check(t.action(g,"service",{"op":"take","index":0,"payment":"self"}).ok,"ARCH shop transaction freezes its actual payment source")
 projection_contract(t,g,"shop result and presentation registry")

# docs/spec/ondemand-copy.md「证据入口」: the six fixture sequence, constructed by name in this file.
static func copy_baseline_fixture(phase: String, count: int):
 var g=Game.new(42) if phase=="battle" else GameCore.new(42)
 if count>=12:
  for slot in g.B.SLOTS: g.add_fixture(slot,7,10)
 if count==26:
  for slot in g.B.SLOTS: g.add_fixture(slot,7,10)
  for slot in ["upper_arm","wrist","thigh"]: g.add_fixture(slot,7,10)
 return g

# Projection mask: delete only the declared keys, and report what was actually removed so the caller
# can demand "exactly the declared set, no more and no fewer".
static func copy_masked_projection(view: Dictionary, facts: Array, declared: Dictionary) -> Dictionary:
 var removed={"card_texts":[],"card_instances":[],"candidate_detail":[]}
 for key in declared.card_texts:
  if view.card_texts.has(key): view.card_texts.erase(key);removed.card_texts.append(key)
 for key in declared.card_instances:
  if view.card_instances.has(key): view.card_instances.erase(key);removed.card_instances.append(key)
 for candidate in facts:
  if declared.candidate_detail.has(String(candidate.get("key",""))) and candidate.has("detail"):
   candidate.erase("detail");removed.candidate_detail.append(String(candidate.get("key","")))
 return removed

# Projection mask protocol in its on-demand form: the declared display set is recomputed here from the
# declared display entrances (independent of View.build), and the narrowed projection must contain
# exactly that set, in registry order, with unchanged entries. The byte-for-byte comparison against the
# frozen baseline JSON stays in the build-directory oracle, which is the only place that has it.
static func copy_projection_masked_baseline(t) -> void:
 print("COPY MASK DECLARATION "+JSON.stringify({"card_texts":"S complement","card_instances":"non-hand uids","candidate_detail":"card group","view_keys":["deck_list"]}))
 for phase in ["battle","departure"]:
  for count in [0,12,26]:
   var key="%s:%d" % [phase,count]
   var g=copy_baseline_fixture(phase,count)
   var pieces=g.physical_pieces().size()
   t.check(pieces==count and g.state.equipment.size()==count and g.state.links.is_empty() and g.state.composites.is_empty() and g.state.special_equipment.is_empty() and g.validate()=="","COPY baseline fixture sequence holds for "+key)
   var facts=g.command_facts()
   var view=g.get_view()
   var shown=copy_display_set(g,facts)
   var missing=shown.keys().filter(func(type):return not view.card_texts.has(type))
   var extra=view.card_texts.keys().filter(func(type):return not shown.has(type))
   t.check(missing.is_empty() and extra.is_empty(),"COPY card_texts holds exactly the display set S "+key+": missing="+str(missing.slice(0,3))+" extra="+str(extra.slice(0,3)))
   var registry=g.Cards.Rules.SPECS.keys()
   var order=view.card_texts.keys()
   var positions=order.map(func(type):return registry.find(type))
   var sorted_positions=positions.duplicate()
   sorted_positions.sort()
   t.check(positions==sorted_positions and view.card_texts.size()<registry.size(),"COPY narrowed card_texts keeps registry key order without every type "+key)
   var entry_mismatch=order.filter(func(type):return view.card_texts[type]!=g.live_card_text(type))
   t.check(entry_mismatch.is_empty(),"COPY narrowed entries still equal the single read entry "+key+": "+str(entry_mismatch.slice(0,3)))
   var hand_uids=g.state.hand.map(func(card):return card.uid)
   var foreign=view.card_instances.keys().filter(func(uid):return not hand_uids.has(uid))
   t.check(foreign.is_empty(),"COPY card_instances only carries hand uids "+key+": "+str(foreign.slice(0,3)))
   t.check(not view.has("deck_list"),"COPY deck_list left the View "+key)

# 独立重算 S（契约声明的显示入口），供 mask 声明与 View 断言比对。
static func copy_display_set(g, facts: Array) -> Dictionary:
 var shown={}
 for card in g.state.hand: shown[card.type]=true
 for type in g.state.reward_options: shown[type]=true
 for type in g.state.rest_cards: shown[type]=true
 for candidate in facts:
  var type=String(candidate.payload.get("type",""))
  if g.Cards.Rules.SPECS.has(type): shown[type]=true
 for row in g.Services.view(g).get("stock",[]):
  if row.get("kind","")=="card": shown[String(row.get("type",""))]=true
 for selection in g.Events.view(g).get("selections",[]):
  if selection.get("kind","")!="card": continue
  for option in selection.get("options",[]):
   var selected=option.get("selected",{})
   var type=String(selected.get("type",option.get("type","")))
   if g.Cards.Rules.SPECS.has(type): shown[type]=true
 return shown

# The display set projects only visible types; for every projected type, the
# single entry equals that projection field by field, the hand instance rows answer the same way and
# each call hands back an isolated container without touching state or the turn version.
static func copy_single_entry_matches_projection(t) -> void:
 var g=copy_baseline_fixture("battle",12)
 preload("res://tests/curse_cases.gd").give(g,"hannya_1")
 var before=g.state.duplicate(true)
 var view=g.get_view()
 var mismatched=[]
 for type in g.Cards.Rules.SPECS:
  if view.card_texts.has(type) and g.live_card_text(type)!=view.card_texts[type]: mismatched.append(type)
 t.check(mismatched.is_empty() and not view.card_texts.is_empty(),"COPY single entry equals the projected card text for every displayed type: "+str(mismatched.slice(0,5)))
 # 按需 == 全量：全部注册牌型在三个入口上逐字段相等；S 内的键必须在视图里，S 外的键不得出现。
 var full_mismatch=[]
 var shown=copy_display_set(g,g.command_facts())
 for type in g.Cards.Rules.SPECS:
  var single=g.live_card_text(type)
  if single!=g.live_card_text_set([{"type":type}]).texts.get(type,{}): full_mismatch.append("set "+type)
  if view.card_texts.has(type)!=shown.has(type): full_mismatch.append("scope "+type)
  elif shown.has(type) and view.card_texts[type]!=single: full_mismatch.append("value "+type)
 t.check(full_mismatch.is_empty(),"COPY single entry, full entry and the projected entry agree for every registered type: "+str(full_mismatch.slice(0,5)))
 var instances=[];var extra={}
 for card in g.state.hand:
  if not view.card_instances.has(card.uid): continue
  var entry=g.live_card_text(card.type,card.uid)
  var stored=view.card_instances[card.uid]
  for key in stored:
   if not entry.has(key) or entry[key]!=stored[key]: instances.append(card.uid+"#"+str(key))
  var added=entry.keys().filter(func(key):return not stored.has(key))
  added.sort()
  extra[card.uid]=added
  # The projected instance row carries the two-step pair; the single entry is the four-step entry
  # so its only additions may be the face costs and, for casting cards, the cast block.
  if not ("face_costs" in added) or not added.all(func(key):return key in ["casting","face_costs"]): instances.append(card.uid+"#extra"+str(added))
 t.check(instances.is_empty() and not view.card_instances.is_empty(),"COPY single entry keeps every projected instance field and adds only the face costs and casting of its own four-step entry: "+str(instances.slice(0,3))+" "+str(extra))
 var fresh=g.live_card_text("strain")
 fresh.face_effects.bound="changed"
 t.check(g.live_card_text("strain").face_effects.bound!="changed","COPY single entry returns a fresh container on every call")
 t.check(g.state==before and g.state.version==view.version,"COPY single entry leaves state, random domains and turn version unchanged")

# docs/spec/ondemand-copy.md「文案路由（收口阶段）」: the direct
# string channel must return every producer string byte for byte, the candidate entry must equal the
# projected detail, the registered kinds must render exactly like their own builders, and the router
# must record nothing until something really is unknown.
static func copy_route_bytes_unchanged(t) -> void:
 var router=preload("res://core/copy_router.gd")
 var catalog=preload("res://data/encyclopedia.gd")
 t.check(router.categories()==["card.catalog","card.face","card.face_text","card.target","card.two_face","consumables.description","demo_exit.continue","demo_exit.end","departure.description","departure.finish","departure.skip","event.choice","event.prepare","event.reward_skip","game.attack","game.attack_release","game.calm","game.depart","game.end_climax","game.end_turn","game.finish_pack","game.finish_prepare","game.finish_rest","game.hook","game.item_cut","game.item_discard","game.item_door_lock","game.item_escape","game.item_install","game.item_retrieve","game.item_unlock","game.manual_collar","game.manual_release","game.manual_retrieve","game.posture","game.posture_wall","game.rest_begin","game.rest_card","game.rest_flask","game.rest_rare","game.retain","game.retain_skip","game.reward_flask","game.reward_item","game.reward_item_skip","game.reward_other","game.reward_relic","game.reward_skip","game.reward_skip_category","game.status_toggle","game.surrender","game.travel_step","game.wall_move","mana_flask.deposit","mana_flask.withdraw","prison.door_exit","prison.enter","prison.inspection","prison.key","prison.resist","prison.unlock_door","prison.vent_exit","prison.vent_kick","prison_space.explore_blind","prison_space.explore_site","relic.control_done","relic.control_toggle","relic.discharge","relic_bundle.claim","relic_bundle.finish","relic_bundle.skip","service.leave","service.offer","service.refresh","service.release_job","service.remove_card","witch.attack","witch.card_log"],"COPY ROUTER enumerates its registered categories: "+str(router.categories()))
 for phase in ["battle","departure"]:
  for count in [0,12,26]:
   var key="%s:%d" % [phase,count]
   var g=copy_baseline_fixture(phase,count)
   var before=g.state.duplicate(true)
   var facts=g.command_facts()
   var direct=[];var projected=[]
   for candidate in facts:
    # B3: the card group carries no detail; the on-demand entry is the value to compare everywhere.
    var detail=g.candidate_detail(candidate)
    if router.text(g,detail)!=detail: direct.append(candidate.payload.get("kind","")+"#"+String(candidate.get("key","")))
    if candidate.payload.get("kind","")=="card":
     if candidate.has("detail"): projected.append("stray "+String(candidate.get("key","")))
    elif detail!=candidate.detail: projected.append(candidate.payload.get("kind","")+"#"+String(candidate.get("key","")))
   t.check(direct.is_empty(),"COPY direct string channel returns the producer text unchanged "+key+": "+str(direct.slice(0,3)))
   t.check(projected.is_empty(),"COPY candidate_detail returns the projected detail for every candidate "+key+": "+str(projected.slice(0,3)))
   t.check(g.copy_router_failures.is_empty() and g.state==before,"COPY routing records no failure and changes no state "+key)
 var sample=copy_baseline_fixture("battle",12)
 var reference=sample.command_facts()
 var stripped=reference.duplicate(true)
 var card_group=0
 var recomputed=[]
 for i in range(stripped.size()):
  if reference[i].payload.get("kind","")!="card": continue
  card_group+=1
  if reference[i].has("detail"): recomputed.append("stray "+String(reference[i].get("key","")))
  if sample.candidate_detail(reference[i])=="": recomputed.append("empty "+String(reference[i].get("key","")))
 t.check(card_group>0 and recomputed.is_empty(),"COPY card facts recompute on demand and carry no projected detail: "+str(recomputed.slice(0,3)))
 var g2=copy_baseline_fixture("battle",12)
 var g2_before=g2.state.duplicate(true)
 var kind_mismatch=[];var fragment_mismatch=[]
 for type in g2.Cards.Rules.SPECS:
  var args={"type":type}
  if router.entry(g2,{"kind":"card.face","args":args,"fallback":{}})!=g2.Cards.text_entry(g2,type): kind_mismatch.append("card.face "+type)
  if router.entry(g2,{"kind":"card.catalog","args":args,"fallback":{}})!=catalog.card(type): kind_mismatch.append("card.catalog "+type)
  if router.two_face(g2,type)!=g2.Cards.face_text(g2,type,false)+"\n"+g2.Cards.face_text(g2,type,true): fragment_mismatch.append(type)
 t.check(kind_mismatch.is_empty(),"COPY ROUTER registered kinds render exactly like their own builders: "+str(kind_mismatch.slice(0,3)))
 t.check(fragment_mismatch.is_empty(),"COPY ROUTER two_face fragment equals the producer expression: "+str(fragment_mismatch.slice(0,3)))
 var failures=g2.copy_router_failures.size()
 var fallback=router.text(g2,{"kind":"missing.kind","args":{},"fallback":"保留原文案"})
 t.check(fallback=="保留原文案" and g2.copy_router_failures.size()==failures+1 and g2.copy_router_failures[-1].kind=="missing.kind","COPY ROUTER unknown kind returns its fallback and records it")
 var blank=router.text(g2,{"kind":"missing.kind","args":{}})
 t.check(blank=="" and g2.copy_router_failures.size()==failures+2,"COPY ROUTER unknown kind without a fallback returns an empty string and still records it")
 var refused=router.text(g2,{"kind":"card.face","args":{"type":"strain"},"fallback":"回退"})
 t.check(refused=="回退" and g2.copy_router_failures.size()==failures+3 and g2.copy_router_failures[-1].stage=="result","COPY ROUTER refuses a dictionary result on the string entry and records it")
 t.check(router.failures(g2).size()==failures+3 and g2.state==g2_before,"COPY ROUTER diagnostics stay on the instance and never touch state")
 copy_migrated_kinds(t,router)

# docs/spec/ondemand-copy.md「文案路由（收口阶段）」: every migrated kind must render exactly like the producer expression it replaced.
# The descriptor carries a sentinel fallback, so a fallback return (unknown kind, invalid builder or a
# wrong result type) shows up as a mismatch instead of hiding behind identical text.
static func copy_migrated_kinds(t,router) -> void:
 var sentinel="COPY-SENTINEL"
 var flask=copy_baseline_fixture("battle",0)
 flask.state.mana=50.0;flask.state.flask_mana=8.0;flask.state.flask_deposits=1
 t.check(router.text(flask,{"kind":"mana_flask.deposit","args":{"amount":10.0,"remaining":2,"limited":true},"fallback":sentinel})==copy_candidate(flask,"flask","deposit").get("detail",""),"COPY R1 mana_flask.deposit renders like the deposit candidate")
 t.check(router.text(flask,{"kind":"mana_flask.withdraw","args":{"drawn":8.0,"restored":8.0,"remaining":3,"limited":true},"fallback":sentinel})==copy_candidate(flask,"flask","withdraw").get("detail",""),"COPY R1 mana_flask.withdraw renders like the withdraw candidate")
 var exit_game=copy_baseline_fixture("battle",0)
 preload("res://tests/demo_exit_cases.gd").exit_fixture(exit_game)
 t.check(router.text(exit_game,{"kind":"demo_exit.end","args":{},"fallback":sentinel})==copy_candidate(exit_game,"demo_end","").get("detail",""),"COPY R1 demo_exit.end renders like the exit candidate")
 t.check(router.text(exit_game,{"kind":"demo_exit.continue","args":{"next_cycle":1},"fallback":sentinel})==copy_candidate(exit_game,"demo_continue","").get("detail",""),"COPY R1 demo_exit.continue renders like the continuation candidate")
 t.check(flask.copy_router_failures.is_empty() and exit_game.copy_router_failures.is_empty(),"COPY R1 migrated kinds are all registered and record no failure")
 # R2: 三处两面拼接改走共享片段，产出的候选必须逐字节等于 two_face。
 var reward_game=copy_baseline_fixture("battle",0)
 reward_game.state.phase="reward";reward_game.state.reward_options=["strain","brace"];reward_game.state.reward_claimed={}
 var event_game=copy_baseline_fixture("battle",0)
 event_game.state.phase="event"
 preload("res://core/room_events.gd").start(event_game,preload("res://data/room_events.gd").pool()[0])
 event_game.state.room_event.stage="reward";event_game.state.room_event.reward=["strain","brace"]
 var shop_game=GameCore.new(42,true,"shop")
 var stock=shop_game.room_data(shop_game.state.room).stock
 stock.append({"kind":"card","type":"strain","price":40,"taken":false})
 var two_face_mismatch=[];var two_face_seen={"reward":0,"event":0,"service":0}
 for candidate in reward_game.command_facts():
  if candidate.payload.get("kind","")!="reward" or candidate.payload.get("category","")!="card": continue
  two_face_seen.reward+=1
  if candidate.detail!=router.two_face(reward_game,String(candidate.payload.type)): two_face_mismatch.append("reward "+String(candidate.get("key","")))
 for candidate in event_game.command_facts():
  if candidate.payload.get("kind","")!="event" or candidate.payload.get("action","")!="reward" or candidate.payload.get("type","")=="skip": continue
  two_face_seen.event+=1
  if candidate.detail!=router.two_face(event_game,String(candidate.payload.type)): two_face_mismatch.append("event "+String(candidate.get("key","")))
 for candidate in shop_game.command_facts():
  if candidate.payload.get("kind","")!="service" or candidate.payload.get("op","")!="take": continue
  var offer=stock[int(candidate.payload.index)]
  if offer.kind!="card": continue
  two_face_seen.service+=1
  if candidate.detail!=router.two_face(shop_game,String(offer.type)): two_face_mismatch.append("service "+String(candidate.get("key","")))
 t.check(two_face_seen.reward>0 and two_face_seen.event>0 and two_face_seen.service>0 and two_face_mismatch.is_empty(),"COPY R2 reward, event and shop card texts use the shared two-face fragment: "+JSON.stringify(two_face_seen)+" "+str(two_face_mismatch.slice(0,3)))
 # R3a: card 目标候选经路由的渲染加上共用组装，必须逐字节等于包装产出的值。
 var target_game=copy_baseline_fixture("battle",12)
 var target_mismatch=[];var target_seen=0
 for candidate in target_game.command_facts():
  if candidate.payload.get("kind","")!="card": continue
  target_seen+=1
  var base=router.text(target_game,{"kind":"card.target","args":{"payload":candidate.payload},"fallback":sentinel})
  var assembled=target_game._candidate_detail(base,candidate.payload,target_game.Cards.magic_card_traction(target_game,candidate.payload),candidate.mana_payment)
  if assembled!=target_game.candidate_detail(candidate): target_mismatch.append(String(candidate.get("key","")))
 t.check(target_seen>0 and target_mismatch.is_empty() and target_game.copy_router_failures.is_empty(),"COPY R3a card.target renders like the wrapper for every card candidate: "+str(target_seen)+" "+str(target_mismatch.slice(0,3)))
 # R3b: paid facts must render through their registered builders without fallback.
 var paid_mismatch=[];var paid_seen={"offer":0,"release":0,"remove":0,"refresh":0}
 for candidate in shop_game.command_facts():
  if candidate.payload.get("kind","")!="service" or candidate.payload.get("op","")!="take": continue
  paid_seen.offer+=1
  if router.text(shop_game,{"kind":"service.offer","args":{"offer":stock[int(candidate.payload.index)]},"fallback":sentinel})!=candidate.detail: paid_mismatch.append("offer "+String(candidate.get("key","")))
 var release_game=GameCore.new(42,true,"shop")
 release_game.add_fixture("wrist",8,10)
 var release_jobs=release_game.Services.release_jobs(release_game)
 var release_candidate=copy_candidate(release_game,"service","release")
 paid_seen.release+=1
 if release_jobs.is_empty() or router.text(release_game,{"kind":"service.release_job","args":{"job":release_jobs[0]},"fallback":sentinel})!=release_candidate.get("detail",""): paid_mismatch.append("release")
 var remove_game=GameCore.new(42,true,"shop")
 remove_game.state.shop_removals=3
 var remove_candidate=copy_candidate(remove_game,"service","remove")
 paid_seen.remove+=1
 if remove_candidate.is_empty() or router.text(remove_game,{"kind":"service.remove_card","args":{},"fallback":sentinel})!=remove_candidate.get("detail",""): paid_mismatch.append("remove")
 var refresh_before=shop_game.export_snapshot()
 var refresh_candidate=copy_candidate(shop_game,"service","refresh")
 paid_seen.refresh+=1
 if refresh_candidate.is_empty() or router.text(shop_game,{"kind":"service.refresh","args":{},"fallback":sentinel})!=refresh_candidate.get("detail",""): paid_mismatch.append("refresh")
 t.check(shop_game.state==refresh_before,"COPY R3b refresh detail leaves stock, payment and randomness unchanged")
 t.check(paid_seen.offer>0 and paid_mismatch.is_empty(),"COPY R3b service.offer, refresh, release_job and remove_card render like the paid facts: "+JSON.stringify(paid_seen)+" "+str(paid_mismatch.slice(0,3)))
 # R3c: Prison.add 的九个站点经路由渲染必须逐字节等于候选值。
 var prison_mismatch=[];var prison_seen=0
 for entry in [["captured","prison.enter","enter",{}],["inspection","prison.inspection","inspect",{}],["inspection","prison.resist","resist",{}],["room","prison.vent_kick","vent_kick",{}],["room","prison.vent_exit","vent_exit",{}],["room","prison.key","key",{}],["room","prison.door_exit","door_exit",{}],["blind","prison_space.explore_blind","explore",{}]]:
  var g=copy_baseline_fixture("battle",0)
  g.state.security=2
  match entry[0]:
   "captured": g.state.phase="captured"
   "inspection": g.state.phase="inspection";g.state.prison.stage="arrival"
   "room": g=GameCore.new(42,true,"prison_test")
   "blind": g=GameCore.new(42,true,"prison_test");g.add_fixture("eyes",4)
  var candidate=copy_candidate(g,"prison",entry[2])
  prison_seen+=1
  var args=entry[3]
  match entry[1]:
   "prison.enter": args={"security":g.state.security}
   "prison.inspection": args={"stage":g.state.prison.stage}
   "prison_space.explore_site": args={"distance":g.wall_movement_profile().distance,"cost":g.wall_movement_profile().cost}
  if candidate.is_empty() or router.text(g,{"kind":entry[1],"args":args,"fallback":sentinel})!=candidate.get("detail",""): prison_mismatch.append(entry[1]+"/"+entry[0])
 var explore_game=GameCore.new(42,true,"prison_test")
 var explore_candidate=copy_candidate(explore_game,"prison","explore")
 prison_seen+=1
 var explore_args={"distance":explore_game.wall_movement_profile().distance,"cost":explore_game.wall_movement_profile().cost}
 if explore_candidate.is_empty() or router.text(explore_game,{"kind":"prison_space.explore_site","args":explore_args,"fallback":sentinel})!=explore_candidate.get("detail",""): prison_mismatch.append("prison_space.explore_site/room")
 t.check(prison_seen==9 and prison_mismatch.is_empty(),"COPY R3c all nine Prison.add sites render like their facts: "+str(prison_mismatch.slice(0,3)))
 copy_r4_sites(t,router,sentinel)
 copy_r6_sites(t,router,sentinel)
 copy_candidate_detail_on_demand(t)

# docs/spec/ondemand-copy.md「文案路由（收口阶段）」: the direct call sites of the remaining modules render through the router as well.
static func copy_r4_sites(t,router,sentinel: String) -> void:
 var r4_mismatch=[];var r4_seen=0
 var choose=GameCore.new(42)
 var choose_candidate=copy_candidate(choose,"departure","choose")
 r4_seen+=1
 if choose_candidate.is_empty() or router.text(choose,{"kind":"departure.description","args":{"entry_id":String(choose_candidate.payload.get("option",""))},"fallback":sentinel})!=choose_candidate.get("detail",""): r4_mismatch.append("departure.description")
 r4_seen+=1
 if router.text(choose,{"kind":"departure.skip","args":{},"fallback":sentinel})!=copy_candidate(choose,"departure","skip").get("detail",""): r4_mismatch.append("departure.skip")
 r4_seen+=1
 if router.text(choose,{"kind":"departure.finish","args":{},"fallback":sentinel})!="选择第一层的入口。": r4_mismatch.append("departure.finish")
 var event_game=copy_baseline_fixture("battle",0)
 event_game.state.phase="event"
 preload("res://core/room_events.gd").start(event_game,preload("res://data/room_events.gd").pool()[0])
 var event_candidate=copy_candidate(event_game,"event","choose")
 r4_seen+=1
 if event_candidate.is_empty() or router.text(event_game,{"kind":"event.choice","args":{"option_id":String(event_candidate.payload.get("choice",""))},"fallback":sentinel})!=event_candidate.get("detail",""): r4_mismatch.append("event.choice")
 event_game.state.room_event.stage="result"
 var prepare_args={"prepare":bool(event_game.state.room_event.get("prepare_pending",false))}
 r4_seen+=1
 if router.text(event_game,{"kind":"event.prepare","args":prepare_args,"fallback":sentinel})!=copy_candidate(event_game,"event","leave").get("detail",""): r4_mismatch.append("event.prepare")
 var bundle_game=copy_baseline_fixture("battle",0)
 preload("res://core/relic_bundle.gd").start(bundle_game,"reward")
 var bundle_claim=copy_candidate(bundle_game,"relic_bundle","claim")
 r4_seen+=1
 if bundle_claim.is_empty() or router.text(bundle_game,{"kind":"relic_bundle.claim","args":{"relic_id":String(bundle_game.state.relic_bundle.entries[0].type)},"fallback":sentinel})!=bundle_claim.get("detail",""): r4_mismatch.append("relic_bundle.claim")
 r4_seen+=1
 if router.text(bundle_game,{"kind":"relic_bundle.skip","args":{},"fallback":sentinel})!=copy_candidate(bundle_game,"relic_bundle","skip").get("detail",""): r4_mismatch.append("relic_bundle.skip")
 r4_seen+=1
 if router.text(bundle_game,{"kind":"relic_bundle.finish","args":{},"fallback":sentinel})!=copy_candidate(bundle_game,"relic_bundle","finish").get("detail",""): r4_mismatch.append("relic_bundle.finish")
 var treasure_game=GameCore.new(42,true,"shop")
 treasure_game.room_data(treasure_game.state.room).kind="treasure"
 var treasure_stock=treasure_game.room_data(treasure_game.state.room).stock
 var treasure_candidate=copy_candidate(treasure_game,"service","take")
 var treasure_offer=treasure_stock[int(treasure_candidate.get("payload",{}).get("index",-1))] if not treasure_candidate.is_empty() else {}
 r4_seen+=1
 if treasure_candidate.is_empty() or router.text(treasure_game,{"kind":"service.offer","args":{"offer":treasure_offer},"fallback":sentinel})!=treasure_candidate.get("detail",""): r4_mismatch.append("service.offer/treasure")
 r4_seen+=1
 if router.text(treasure_game,{"kind":"service.leave","args":{},"fallback":sentinel})!=copy_candidate(treasure_game,"service","leave").get("detail",""): r4_mismatch.append("service.leave")
 var item_game=copy_baseline_fixture("battle",0)
 item_game.state.equipment.clear();item_game.add_fixture("wrist",8,10)
 item_game._gain_tool("mana_potion")
 var use_candidate={}
 for candidate in item_game.command_facts():
  if candidate.payload.get("kind","")=="item_use" and candidate.payload.get("target","")=="hero": use_candidate=candidate;break
 r4_seen+=1
 if use_candidate.is_empty() or router.text(item_game,{"kind":"consumables.description","args":{"item_type":String(item_game._item(String(use_candidate.payload.get("item",""))).type)},"fallback":sentinel})!=use_candidate.get("detail",""): r4_mismatch.append("consumables.description")
 var witch_game=Game.new(42,false,"equipment",true,false,25,false,false,"witch")
 var witch_candidate={}
 for candidate in witch_game.command_facts():
  if candidate.payload.get("kind","")=="attack" and candidate.payload.get("charge_action",false): witch_candidate=candidate;break
 r4_seen+=1
 if witch_candidate.is_empty():
  r4_mismatch.append("witch.attack")
 else:
  var witch_args={"part":witch_candidate.payload.get("part",""),"charge":true,"stacks":int(witch_game.state.witch_charges[String(witch_candidate.payload.get("part",""))]),"damage":float(witch_candidate.payload.get("damage",0.0)),"hits":int(witch_candidate.payload.get("hits",1)),"all_targets":bool(witch_candidate.payload.get("all",false)),"focus":0}
  var witch_assembled=witch_game._candidate_detail(router.text(witch_game,{"kind":"witch.attack","args":witch_args,"fallback":sentinel}),witch_candidate.payload,witch_game.Cards.magic_card_traction(witch_game,witch_candidate.payload),witch_candidate.mana_payment)
  if witch_assembled!=witch_candidate.detail: r4_mismatch.append("witch.attack")
 var door_game=GameCore.new(42,true,"prison_test")
 preload("res://tests/curse_cases.gd").give(door_game,"unlock")
 var door_candidate=copy_candidate(door_game,"prison","unlock")
 r4_seen+=1
 if door_candidate.is_empty() or router.text(door_game,{"kind":"prison.unlock_door","args":{"type":String(door_candidate.payload.get("type",""))},"fallback":sentinel})!=door_candidate.get("detail",""): r4_mismatch.append("prison.unlock_door")
 t.check(r4_seen==13 and r4_mismatch.is_empty(),"COPY R4 the remaining direct call sites render like their facts: "+str(r4_mismatch.slice(0,4)))

# docs/spec/ondemand-copy.md「文案路由（收口阶段）」: the two producers outside the View route their text through the router as well.
static func copy_r6_sites(t,router,sentinel: String) -> void:
 var cards=copy_baseline_fixture("battle",0)
 var face_mismatch=[];var face_seen=0
 for type in cards.Cards.Rules.SPECS:
  for side in [false,true]:
   face_seen+=1
   var args={"type":type,"free":side,"uid":""}
   if router.text(cards,{"kind":"card.face_text","args":args,"fallback":sentinel})!=cards.Cards.face_text(cards,type,side): face_mismatch.append(type+"#"+str(side))
 t.check(face_seen>0 and face_mismatch.is_empty(),"COPY R6 card.face_text renders like the module expression for every type and face: "+str(face_mismatch.slice(0,3)))
 var witch=Game.new(42,false,"equipment",true,false,25,false,false,"witch")
 preload("res://tests/curse_cases.gd").give(witch,"witch_patience")
 for candidate in witch.command_facts():
  if String(candidate.payload.get("type",""))=="witch_patience" and candidate.valid:
   witch.dispatch(witch.command(candidate.payload,witch.state.version),witch.state.version)
   break
 var logged=""
 for row in witch.state.logs:
  if String(row.get("data",{}).get("witch_card",""))!="": logged=String(row.get("text",""))
 var log_matched=false
 for type in witch.Cards.Rules.SPECS:
  for side in [false,true]:
   var log_args={"type":type,"free":side}
   if router.text(witch,{"kind":"witch.card_log","args":log_args,"fallback":sentinel})==logged and logged!="": log_matched=true
 t.check(log_matched,"COPY R6 witch.card_log renders like the emitted card log: "+logged)

# docs/spec/ondemand-copy.md「证据入口」：card 组不带 detail、按需入口
# 逐字节等于包装产出的值，其余组保持预生成；候选 ID 仍由 payload 决定，写路径不受影响。
static func copy_candidate_detail_on_demand(t) -> void:
 var g=copy_baseline_fixture("battle",12)
 var before=g.state.duplicate(true)
 var facts=g.command_facts()
 var mismatch=[];var card_group=0
 for candidate in facts:
  var detail=g.candidate_detail(candidate)
  if candidate.payload.get("kind","")=="card":
   card_group+=1
   if candidate.has("detail"): mismatch.append("stray "+String(candidate.get("key","")))
   if detail=="": mismatch.append("empty "+String(candidate.get("key","")))
  elif detail!=candidate.detail: mismatch.append("eager "+candidate.payload.get("kind","")+"#"+String(candidate.get("key","")))
  if String(candidate.get("key",""))!=JSON.stringify(candidate.payload).sha256_text().substr(0,24) and String(candidate.get("key",""))=="": mismatch.append("key "+String(candidate.get("key","")))
 t.check(card_group>0 and mismatch.is_empty(),"COPY scenario 5 card details are on demand and ids stay payload derived: "+str(mismatch.slice(0,3)))
 var played=0
 for candidate in facts:
  if candidate.payload.get("kind","")!="card" or not candidate.valid: continue
  t.check(g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok and g.state.version>0,"COPY scenario 5 a card candidate still commits through dispatch")
  played+=1
  break
 t.check(played==1 and g.state!=before,"COPY scenario 5 write path unaffected by on-demand detail")

# docs/spec/candidate-removal.md「接口」判据真源（behavior_baseline_equivalence；批 R1）：行为基线等价。切片开始时用未改源码复算 26 个夹具单元
# （0／12／26／44 件 × 战斗／整备／休息／商店／事件／监狱＋豆包接管，同种子 42）并逐路径比对通过
# （1508 条路径，首个差异＝无；全量值与逐字段比对器在批 R1 的 build 目录 oracle 内，用完删除）。
# 这里保留冻结的单元级记录：键集合必须与冻结路径逐一相符（R1 的 mask 为空），命名路径逐字段相等；
# 不一致以复算值为准并记录，不得改基线迁就实现。
const R1_RECORD_PATHS=["composites","energy","equipment","first_turn","first_turn_locked","first_turn_name","fixture","flask_mana","hand","items","links","logs","mana","mana_max","order","overloaded","phase","pieces","pieces_ok","post_phase","post_version","posture","pressure","reject_forged","reject_invalid","reject_stale","relics","rng","rng_total","round","rows","rows_labels","rows_payloads","rows_valid","rows_verdicts","snapshot","special","submit_checkpoint","submit_error","submit_keys","submit_kind","submit_ok","takeover_automated","takeover_blocked","takeover_reason","takeover_step","temporary_mana","tick","validate","validate_after","version","view","view_available","view_candidates","view_card_texts","view_hand","wall","wall_distance"]
const R1_BASELINE={
 "battle:0":{"rows_verdicts":"aedcb0675b24df473a98c3a28bc3f6bf","view":"f40ab34c6bca484c276364892c0561e1","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"3be5dc45ec07b61690681faf06edd849","rng":"69fe2877535b0ddfe95879adcd14cdff","record":"16127b9ab6e5a976fa557e722adbeab4"},
 "battle:12":{"rows_verdicts":"ab4ece314aa036180ea32a705ed34226","view":"2f24f5b5a20edfeea42f09610e9fc2cb","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"c7b88242b8ba3611a5d09ce33bead959","rng":"69fe2877535b0ddfe95879adcd14cdff","record":"74e1aa14d69f27d7a0ddebe2f9e76496"},
 "battle:26":{"rows_verdicts":"d80309647df35bef7c86728c26ca19f9","view":"fd85092b195a8ca5fccf71b52edef276","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"07d0cbf0effe193f53bdc6ec017d5a5f","rng":"1ffe4fa2490ef1b5801a9be4d5179a86","record":"22d4201ddaf1e807ede5cc9c1055fc13"},
 "battle:44":{"rows_verdicts":"279b0a0a462ed16cd1bd788ee5a8f3b8","view":"acfb943a7453d9f25544377e4e5efccf","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"794b6db532fadb6182696a45026271fc","rng":"2ca204b40493eae8d1bcadd47154f364","record":"638bc2d08c601245ac16f7b88aae787e"},
 "event:0":{"rows_verdicts":"f9d94b13926d4c2d9baaf1f685a4aa84","view":"fda761dc8558525830858f8353130b8a","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"魔瓶中没有魔力。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"6941a4d704f61d440f9396731c702673","rng":"6b6206a8bd7b425112c7c27da18cb61d","record":"d34b2844f6ee65f09dbbb093c06b3746"},
 "event:12":{"rows_verdicts":"f9d94b13926d4c2d9baaf1f685a4aa84","view":"f8be00fe6579c23c59deb1819e059193","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"魔瓶中没有魔力。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"48c70955de62dbdbe7a1f88d4837338d","rng":"6b6206a8bd7b425112c7c27da18cb61d","record":"32f02ac38446c212f02a9838eea67c56"},
 "event:26":{"rows_verdicts":"f9d94b13926d4c2d9baaf1f685a4aa84","view":"e4ec077ca048e394f281798705aaadf7","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"魔瓶中没有魔力。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"b33a156316591c3f6101056cdd4b7233","rng":"6b6206a8bd7b425112c7c27da18cb61d","record":"ffa20fc918c7f448319a49e91028b38a"},
 "event:44":{"rows_verdicts":"f9d94b13926d4c2d9baaf1f685a4aa84","view":"2df49f7ff9977701d6caa9b87b18d016","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"魔瓶中没有魔力。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"ae47e07c5a43643445e5cc35979c265c","rng":"6b6206a8bd7b425112c7c27da18cb61d","record":"2b2306c02ec83bafaaf21d643d043f37"},
 "prepare:0":{"rows_verdicts":"f3fffd5305b9d3882a7aab7fac4b396d","view":"b04553a3051d7c17d079c61705152acd","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"4fa1aed31afb5b15e68b3b8560f9a8d6","rng":"72f017d8c1a02a0462125f9f95b1234c","record":"9daeb8fd51a7baa6022510c3940eb1d4"},
 "prepare:12":{"rows_verdicts":"4d73f39f03b388c679978d7858e655b0","view":"776d14bb68301527e513f3b113f7574e","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"d4d51b44474e4112743fec3f75b68490","rng":"72f017d8c1a02a0462125f9f95b1234c","record":"d0b66dd5736aa87e04800eb892a75d44"},
 "prepare:26":{"rows_verdicts":"7d5172a58e1d157d12f858bf076c4555","view":"7fc74ecf66ea0b03ee6ef56d89c61d45","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"ac79ad945997d2be6911626e0a7af398","rng":"6466fd9d067695dfae7e509914f46446","record":"19af8460542440aa9daf85810012dfe2"},
 "prepare:44":{"rows_verdicts":"f4cd97a736dfeb28659f1a39fe37be16","view":"75eaa97b00bad2eba8683d36760c5606","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"301d505530d6bb304fd9ccec23f99f0f","rng":"ee7475a559e2df34597d8af1a5faf748","record":"3a3306f254ba8ecbc89ed1df4959c90a"},
 "prison:0":{"rows_verdicts":"dad9bd2cbe21b0962de7bc47c490287f","view":"682cc4c3be2baf1e423e184a47a8202b","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"243652b42d36a11b64a10806cc045956","rng":"c2ac01a230cee954c7f8af2f9320abd5","record":"56e1c4f7e3bd34642d9275f13a566629"},
 "prison:12":{"rows_verdicts":"9e1405cbec45c720cae6fc3ecc883ef7","view":"433a9b89c0e5ea2bdedd48d28ef472fa","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"姿态必须依次经过坐姿，不能直接跨越。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"459628f527d12c367a827b19f27f03ba","rng":"c2ac01a230cee954c7f8af2f9320abd5","record":"c499bb613311c32e08be76affb5c92ae"},
 "prison:26":{"rows_verdicts":"9c28aac2d94f44ae9f848a0d386e9b3b","view":"649b085814a6478e5bb16816db90d183","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"姿态必须依次经过坐姿，不能直接跨越。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"d53f72b58f580160887a72cc1ced3bd9","rng":"c2ac01a230cee954c7f8af2f9320abd5","record":"d812c759711e3c5c185d7e174cf7ea60"},
 "prison:44":{"rows_verdicts":"baf64cc9644fe759ebdf8d8115e3dcc5","view":"11b46e6be1dadb832d4d60a64fe5c420","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"姿态必须依次经过坐姿，不能直接跨越。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"2dfc3408c3ae6554634760160e31d1d8","rng":"c2ac01a230cee954c7f8af2f9320abd5","record":"98bbb26eae5eb1ccfab0b12b20f0f521"},
 "rest:0":{"rows_verdicts":"10adfad99c876ae2c41ef8bb672ab87d","view":"e6343a15027daabccb0b88cd609b24af","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"06d9621d27e89b558e5302c62738bba7","rng":"696657cdcc914fe3b6ce575b02d4a695","record":"b122e6783d6903ca6d37b3c93cf21609"},
 "rest:12":{"rows_verdicts":"d130f92fbba25c6f8dca35f7f9112cf3","view":"ee9a33f39a28178c9eb15db3e089b737","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"15d4c0c5f7f9f325c3b6497a41e31bbb","rng":"696657cdcc914fe3b6ce575b02d4a695","record":"d64b444e352471ac9dac5fe97078860b"},
 "rest:26":{"rows_verdicts":"152227659247381af3fe41aeee7d8ab6","view":"fbf1773fa2d292dccee41dcb74a25326","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"7a3cdf6e13641854d5080096106499d1","rng":"1d20f6070f294fadc1355c7c231c0b82","record":"7b4586dffe44e1e353bee3b6cebff6e5"},
 "rest:44":{"rows_verdicts":"4e249f0c5cbe016cdfb6bb1fd1688494","view":"619cc695890d18a531a5d3dfa3080032","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"已经贴墙。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"c1d37cbf00cce35e2ed83c2df3b075d6","rng":"89896d136942b5f3cd60897741ce77c8","record":"3609c6dc39c4c8c0aa66589a484a1a76"},
 "shop:0":{"rows_verdicts":"1ecdd866c95dcbcb0c5d8a5ee9140abf","view":"940ab425952944b7678757b7a496bf0d","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"需要20魔瓶魔力，当前只有0。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"7c895914d49611530754388f21cb7ba2","rng":"69fe2877535b0ddfe95879adcd14cdff","record":"578383355a79606b7b8ba20a3c27cd56"},
 "shop:12":{"rows_verdicts":"333f9a3ab9b7bb09839d51ae8769c7f4","view":"e1f8a873c4e68ea6e12295cfa3949d84","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"需要20魔瓶魔力，当前只有0。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"f3511dfe416a54c4427b64e1f9ffe891","rng":"69fe2877535b0ddfe95879adcd14cdff","record":"8566ff61020b53c9e68dacfb94d56d2f"},
 "shop:26":{"rows_verdicts":"fff70a1e263c15804273295bdb1a6421","view":"774e2162ff44ccc35a9ffbed381425db","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"需要20魔瓶魔力，当前只有0。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"d772baf528476018b5ff7e61359d081e","rng":"69fe2877535b0ddfe95879adcd14cdff","record":"2fc647ff1086ea3b084fa04aaa24f6b6"},
 "shop:44":{"rows_verdicts":"c3db8cff9e34afefd64dc5c68772076f","view":"7a91e679e37270f829807b29341f00c1","first_turn":"44136fa355b3678a1146ad16f7e8649e","takeover_blocked":"0","reject_invalid":"需要20魔瓶魔力，当前只有0。","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"c1ed09ae0c65d0f7a9428436069d78a3","rng":"69fe2877535b0ddfe95879adcd14cdff","record":"9872ca3dfdb8cfcda3dea4e7e91dd1f7"},
 "takeover:0":{"rows_verdicts":"8b88015972a0cb75906b9f82708ff9d9","view":"ac82b09ee0f2d09cbaf6af0681cfbeb9","first_turn":"1145a045952e2ed3581845b472d18e4c","takeover_blocked":"79","reject_invalid":"豆包接管中","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"df10e42ed0a5025904819f7305927378","rng":"40b94bbe37133bccfba7f40817336145","record":"b8667b9c010c2f63f30d41822f6dad5e"},
 "takeover:12":{"rows_verdicts":"10af2bc0810bcd45acc17a3ee7bc5bdb","view":"cfb86e34755a5cba0cf0257a58413acd","first_turn":"78e416224ca7952eaab23886199830ab","takeover_blocked":"91","reject_invalid":"豆包接管中","reject_stale":"状态已更新，请重新选择行动。","submit_error":"","snapshot":"3588a272324b5f9b7253b0cabf28cb13","rng":"40b94bbe37133bccfba7f40817336145","record":"eeab5ffe0658d190d5eaec674e1cc425"},
}
# R1 不删除任何记录键（候选行／view.display_facts／提交身份 id 的删除在批 R5 才发生，届时 mask 显式声明）。
const R1_MASK=[]
# 批 R3 的显式 mask：本批唯一新增的视图键（显示事实投影，T5／T8）。行读边（D13 对应行）在本批从 ui/ 删除，
# 但 view 的键不因此减少（候选行载体与 view.display_facts 键到 R5 才删），故 mask 只声明新增键、不声明删除键。
# view 摘要按 mask 删键后必须与 R1 冻结值逐字节相等；键集合另按 R3_VIEW_KEYS_BASE 逐条核对（防静默增删）。
# F 批（C-F-6）：E 批的过渡声明 E_VIEW_MASK_ADDED 并入本表后原表删除——有效排除集重新只是一张 mask 表；
# 这是全片唯一被授权的 mask 变更（design.md §5.2 G-2 的声明落点），其余 mask 常量与 R5_BASELINE 一字未改。
const R3_VIEW_MASK=["display_facts","display_fact_scope"]
# 批 R5 的显式 mask（docs/spec/candidate-removal.md「接口」判据真源：behavior_baseline_equivalence／removal_end_state）：本批删除的载体逐条声明，多一条少一条即红。
#  R5_VIEW_MASK＝视图键：候选行表（view.candidates）。
#  R5_RECORD_MASK＝记录路径：候选行的提交身份 id（rows_verdicts）与 view.candidates（view_candidates）。
#  R5_RECORD_ADDED＝随删除重算的记录路径：判定投影改显示键（facts_verdicts）、显示点全量文本基线（facts_text）、
#  显示事实条数（view_display_facts）。
#  R5_RECOMPUTED＝按 mask 删键后重算的冻结路径（view／record 摘要：候选行表不再参与）。
const R5_VIEW_MASK=["candidates"]
const R5_RECORD_MASK=["rows_verdicts","view_candidates"]
const R5_RECORD_ADDED=["facts_text","facts_verdicts","view_display_facts"]
const R5_RECOMPUTED=["record","view"]
# E 批（K4）唯一新增 View 键 display_fact_scope 在返回字典里的位置＝末尾（core/game_view.gd::build 的最后一个键），删它不移动
# 其余键的次序，故 view／record 摘要除已声明的两字段面外逐字节不动。E 批的过渡排除表已按 C-F-6 并入 R3_VIEW_MASK 后删除。
# 动工前常量副本（A 批审查缺口 4）：不在本文件，见 tests/frozen-baselines.json（外部锚定＋锚定提交 sha256）。
const FROZEN_BASELINES_JSON="tests/frozen-baselines.json"

static func frozen_baselines() -> Dictionary:
 var parsed=JSON.parse_string(source_text(FROZEN_BASELINES_JSON))
 return parsed if parsed is Dictionary else {}
# 接管单元（takeover:0／takeover:12）的 first_turn_control 摘要：接管步骤由行改为显示事实（同一形状与判定，
# 字段面不同），在 R5 提交字节上复算冻结。
const R5_FIRST_TURN={"takeover:0":"8bf0e226191edacd337b525691d9e36a","takeover:12":"ff12a17c57f7d8e7e7023ac7e7c15280"}
# 带 mask 复算后的冻结值（在 R5 提交字节上复算，不从实现反推）：覆盖 R5_RECORD_ADDED 与 R5_RECOMPUTED。
# S5 的显式重算（协调者裁定，2026-10-05；人批的 O7）：dispatch 成功结果新增 fact 键后，冻结记录里的
# submit_keys（成功结果键面摘要）与由其派生的 <record> 摘要随之变化；本批只重算这两个面，mask 不变
# （R5_VIEW_MASK／R5_RECORD_MASK／R5_RECORD_ADDED 原值），其余记录字段与 G6 其余断言逐字不变。
# 差异只来自该键的自证在 docs/record/verification.md：旧键面复算摘要与旧冻结值逐 cell 相等。
const R5_BASELINE={"battle:0":{"facts_text":"ac39ae864b6c5be2953f41bf47a1a5f0","facts_verdicts":"e16b774323b27feb0e1ec4a2de711bef","record":"a91a38c0efbb91657d53f80e4612dc58","view":"98491d612f1a34d0a2c7624612655ab3","view_display_facts":"88"},"battle:12":{"facts_text":"4ff202e54cc276992613cfa15dd4483d","facts_verdicts":"fc4651ba295f7c196efa42ca3504093d","record":"534c04ff0b14b4b0b625910ad5b0bac8","view":"d5dacaf06675cc544c1b14d13a7fdda9","view_display_facts":"100"},"battle:26":{"facts_text":"6563e2f5d257f4d404fbbb84b14d4b76","facts_verdicts":"861fd22798a16f77cf6351cde3011d60","record":"ba0f2abc0e0da39fe7c0b6fe2fbdcea0","view":"ca211857952a5a4e6692be61c21531bc","view_display_facts":"184"},"battle:44":{"facts_text":"e1e9ae1c2ea1bf1cca274561d4c2e833","facts_verdicts":"8b73a596d24eadb28bcc9f4ed2b80c7c","record":"eb91794005dbc248a21d510d5c840009","view":"10f9aa4599f499e20755ed61bb282dfb","view_display_facts":"292"},"event:0":{"facts_text":"cfea8c6499b002900cc399479c98fbc7","facts_verdicts":"301c30de8e315e52e768df1a8bc52564","record":"bf7222442366073db6d1322a470d6f18","view":"541595ca13f5e73ca9de0f2b64f3ce46","view_display_facts":"3"},"event:12":{"facts_text":"cfea8c6499b002900cc399479c98fbc7","facts_verdicts":"301c30de8e315e52e768df1a8bc52564","record":"7206323fff489063319a2e71bafd78c6","view":"3fc2ab7b618ab92a94d4b251eb9135da","view_display_facts":"3"},"event:26":{"facts_text":"cfea8c6499b002900cc399479c98fbc7","facts_verdicts":"301c30de8e315e52e768df1a8bc52564","record":"9229033847caec6f3fa2ab219b6624ba","view":"3f64d8883f83cae0aa864c885fc71ad0","view_display_facts":"3"},"event:44":{"facts_text":"cfea8c6499b002900cc399479c98fbc7","facts_verdicts":"301c30de8e315e52e768df1a8bc52564","record":"86f69fcd04331a3b7855b521f264e6db","view":"6c2356440bcd43f4a82510528dc173a1","view_display_facts":"3"},"prepare:0":{"facts_text":"f7104838af279e342ab5aed44cb20a57","facts_verdicts":"0f60a5032db2d92fd89a88272f10dc1f","record":"f2bfd8369e45f7fdf00b8f6316ad3901","view":"0a1924ba193cacb79a01ecbc05800bc1","view_display_facts":"72"},"prepare:12":{"facts_text":"8d4a1d3d5424b2652da0e42a5a7cab74","facts_verdicts":"330ac05bfcc503da1d5c2f5c58e28ef4","record":"1953df20705b0aa21c07d824bd125d1d","view":"19a684ffdeded96a26a50558885c8eca","view_display_facts":"84"},"prepare:26":{"facts_text":"31db9e6906e9e6edc2df544f6c58a495","facts_verdicts":"af704235553476a09ee81bd9a2b4faca","record":"d59596d73b375820ea8bbddd1ee8e58b","view":"a8208d05993dea9ac36e7fad8ecdeef7","view_display_facts":"168"},"prepare:44":{"facts_text":"6fd1ccecf8d6b337985d1e7065034e63","facts_verdicts":"5088345798f3561021d5322f9eb91a77","record":"c8e44c7aef7dcfc131918289ff0b832d","view":"daf76ace88fec073a7743db2de0f3d7c","view_display_facts":"276"},"prison:0":{"facts_text":"063d3fb839831b1a5e2dfade29050cf7","facts_verdicts":"dd8c0a7b5470dbe8df9b7e872539ccd1","record":"40f93706363b0b70f5303be1f82817c9","view":"61a5029d16c6913146698a3dd5bf48a5","view_display_facts":"79"},"prison:12":{"facts_text":"9d598659ba79454d46cf7796096b2727","facts_verdicts":"b321f1b18a82fb524db374cc81f0b877","record":"f33e1202e045a8992ee6ac548aeea802","view":"d3d8296745b0d9a375f7bd6caab592fb","view_display_facts":"88"},"prison:26":{"facts_text":"c25701787eae5067e2254bf2afa85448","facts_verdicts":"2bfa1bada5517a2857df809a2eb0d550","record":"e4e33732a3f16ac528b7b5075b48d6d4","view":"71034fb99f96a73b64544341b2fa8a3c","view_display_facts":"172"},"prison:44":{"facts_text":"ee32f17b1ee01a503c778db400fc26df","facts_verdicts":"f951eb35e09671769be056a22bac31a0","record":"d42326ffbea435fbc02988b4ae268677","view":"dc82941a16fbd013239bbfe38b81d451","view_display_facts":"280"},"rest:0":{"facts_text":"e0e212f3475e1f9dcd244fe2564fdbd9","facts_verdicts":"ec4343c1370f8acfe92526873650aa36","record":"cf063a5569eed7c62617ab47db08adf0","view":"a9d1770b00e77d7d37107effe368b4c3","view_display_facts":"78"},"rest:12":{"facts_text":"a952cbe4b46679882ae30ee8e00cbbfc","facts_verdicts":"5bb8fcea01ee73d4c5be74d960430e7d","record":"575c7c657fe4fc364095f72a05d2410f","view":"0f3e2db33facaf7d0cac349c8b68035f","view_display_facts":"126"},"rest:26":{"facts_text":"299c00b335e6a86c74c5017c32985a07","facts_verdicts":"3796be82638559efd08c14f35a4b24f7","record":"4c5d644fcbc39554d639aeb67d550a16","view":"cab287418335d07b0d6b03abe199242a","view_display_facts":"252"},"rest:44":{"facts_text":"e1e4b83a24971f84477b9c1e0d59a6b1","facts_verdicts":"a7e66ae91adfbda41a18d60d9b71e9c3","record":"0e6d12f15caf1e0f3b3b731f762ea461","view":"6a518514aef15bea1585bac114284bec","view_display_facts":"414"},"shop:0":{"facts_text":"608cfefe469084cd7a5322122eccff44","facts_verdicts":"b35ecaa120573ce7221efb885cdce1de","record":"0f41d8836cb1ba7ada61e9b53877cd67","view":"5933d35bb57aaf0743e7f1b8a7b5bdfa","view_display_facts":"49"},"shop:12":{"facts_text":"c7e231624b76db3e4caa04bc8df79e4d","facts_verdicts":"898b1cbf0d1f2c82f95564aae9b204d9","record":"fc76295ecfd61df0f454194ce8ae8ab5","view":"cabc92f5d7f563aaef710bad1ee4f4ca","view_display_facts":"73"},"shop:26":{"facts_text":"4e4f209ed0c13bf3eb6d050e628f9e30","facts_verdicts":"9dd6c6caf8d3ee28bab06f2815f5777d","record":"08d4e4d38cd5c0dd085edb1a4de6d21e","view":"dfda2802902de5f0c5a952a32c383ebb","view_display_facts":"101"},"shop:44":{"facts_text":"1cb65cb87d85ca843d8d94f7f318bacd","facts_verdicts":"45f3c9972f3720db6475312a9d28ad5b","record":"129a55371c9d28996e8375cce7c91f7e","view":"ab7e905c2af157a9d85cb1c6559b796a","view_display_facts":"137"},"takeover:0":{"facts_text":"c75421de9b2720481ea31d8002e23e26","facts_verdicts":"9fa43250337736f6c5d7b90df6fc0899","record":"f441cc05a72a355be4dd1a5965c1b602","view":"10892969a87b17ecf070b09c3bbecfd0","view_display_facts":"80"},"takeover:12":{"facts_text":"975d3c9922d0af94cc4848181df82ddb","facts_verdicts":"322274a2e387906c10f7a2deade40792","record":"9ad58a8aedf0b8c95f7fea1c7275c77b","view":"c6ecc09c5dbc07cc14523e51b7795090","view_display_facts":"92"}}
const R3_VIEW_KEYS_BASE=["action_log","arms","battle_item_drop","battle_relic_drop","battle_rewards","bodies","body_coverage","body_groups","body_regions","candidates","capacity","capture","card_chain","card_costs","card_instances","card_texts","carried_items","casting","character_id","climax","composite_portrait_layers","content_status","deck_cards","deck_count","demo_cycle","demo_exit","demo_finished","discard_cards","discard_count","draw_cards","draw_count","encounter","end_turn_locked","enemies","energy","energy_max","equipment_fireball_unlocked","equipment_portrait_layers","first_turn_control","guard_bind","hand","has_restraint_level","hook_contact","hook_environment_name","hook_location","hook_uses","initial_seed","items","journey","legs","logs","mana","mana_flask","mana_max","map_name","map_region","movement","npc_speech","order","pending_retain","phase","phase_caption","pose_name","posture","powers","practice","practice_description","practice_focus","practice_hint","practice_kind","practice_options","preparation_turns","prepare_left","pressure","prison","relics","rest_left","retain_left","reward_count","reward_destination","reward_panel","reward_title","room_event","room_name","rooms_completed","round","route","run_header","security","seed","shop","speech","statuses","summary","temporary_mana","tower_generation","tower_start_pending","travel_log","travel_turns","version","wall","wall_position","wall_text"]

const R1_TAKEOVER_COUNTS=[0,12]
const R1_COUNTS=[0,12,26,44]
const R1_PHASES=["battle","prepare","rest","shop","event","prison","takeover"]
const R1_TEMPLATES=["","rope","belt","tape","cable_tie","fine_belt","eye_cloth","eye_tape","mouth_tape","gag"]

static func r1_cells() -> Array:
 var result=[]
 for phase in R1_PHASES:
  for count in R1_COUNTS:
   if phase=="takeover" and count not in R1_TAKEOVER_COUNTS: continue
   result.append([phase,count])
 return result

static func r1_install_equipment(g, count: int) -> void:
 if count>=12:
  for slot in g.B.SLOTS: g.add_fixture(slot,7,10)
 if count>=26:
  for slot in g.B.SLOTS: g.add_fixture(slot,7,10)
  for slot in ["upper_arm","wrist","thigh"]: g.add_fixture(slot,7,10)
 for layer in range(0,4):
  for slot in g.B.SLOTS:
   for template in R1_TEMPLATES:
    if g.physical_pieces().size()>=count: return
    g.add_fixture(slot,7,10,false,layer,template)

static func r1_end_turn(g) -> void:
 for c in g.command_facts():
  if c.payload.kind=="end" and c.valid:
   g.dispatch(g.command(c.payload,g.state.version),g.state.version)
   return

static func r1_build(phase: String, count: int, game_class=null):
 # Frozen matrix uses the two canonical classes; a caller may substitute a test-side subclass
 # (S5 counting) without touching the fixture itself. Omitted -> byte-identical construction.
 var BattleClass=Game if game_class==null else game_class
 var CoreClass=GameCore if game_class==null else game_class
 var g=null
 match phase:
  "battle":
   g=BattleClass.new(42)
  "takeover":
   g=CoreClass.new(42,true,"doubao")
  "prepare":
   g=BattleClass.new(42)
   var guard=0
   while g.state.phase=="battle" and guard<12:
    guard+=1
    r1_end_turn(g)
   for c in g.command_facts():
    if c.payload.kind=="reward" and c.payload.get("type","")=="skip" and c.valid:
     g.dispatch(g.command(c.payload,g.state.version),g.state.version)
     break
  "rest":
   g=CoreClass.new(42,true,"equipment")
  "shop":
   g=CoreClass.new(42,true,"shop")
  "event":
   g=CoreClass.new(42,true,"abandoned_storeroom")
  "prison":
   g=CoreClass.new(42,true,"prison_test")
 g.state.equipment.clear()
 g.state.links.clear()
 g.state.composites.clear()
 if g.state.capture is Dictionary and g.state.capture.has("retained"):
  g.state.capture.retained=[]
  g.state.capture.baseline=[]
  g.state.capture.links=[]
 if count>0: r1_install_equipment(g,count)
 return g

static func r1_digest(value: String) -> String:
 return value.sha256_text().substr(0,32)

# 记录面与批 R1 oracle 的同名记录一致：标量转字符串、大块取摘要、路径名固定。
static func r1_record(g, phase: String, count: int) -> Dictionary:
 var out={}
 out["fixture"]=phase+":"+str(count)
 out["phase"]=str(g.state.phase)
 out["pieces"]=str(g.physical_pieces().size())
 out["pieces_ok"]=str(g.physical_pieces().size()==count and g.state.equipment.size()==count)
 out["equipment"]=str(g.state.equipment.size())
 out["links"]=str(g.state.links.size())
 out["composites"]=str(g.state.composites.size())
 out["special"]=str(g.state.special_equipment.size())
 out["validate"]=str(g.validate())
 out["version"]=str(g.state.version)
 out["energy"]=str(g.state.energy)
 out["mana"]=str(g.state.mana)
 out["temporary_mana"]=str(g.state.temporary_mana)
 out["mana_max"]=str(g.state.mana_max)
 out["flask_mana"]=str(g.state.flask_mana)
 out["pressure"]=str(g.state.pressure)
 out["overloaded"]=str(g.state.overloaded)
 out["posture"]=str(g.state.posture)
 out["wall"]=str(g.state.wall)
 out["wall_distance"]=str(g.state.wall_distance)
 out["order"]=str(g.state.order)
 out["round"]=str(g.state.round)
 out["tick"]=str(g.state.tick)
 out["hand"]=str(g.state.hand.size())
 out["items"]=str(g.state.items.size())
 out["relics"]=str(g.state.relics.size())
 # 行＝接管标注后的投影事实（＝改动前 candidates() 的等价物：同一顺序、同一判定结论）。
 var rows=g.command_facts()
 var view=g.get_view()
 out["rows"]=str(rows.size())
 out["rows_valid"]=str(rows.filter(func(c):return c.valid).size())
 # R5：候选行的提交身份 id 随行载体删除；判定投影的身份改为显示键（形状键）。
 out["facts_verdicts"]=r1_digest(JSON.stringify(rows.map(func(c):return [c.key,c.valid,c.reason,c.risk,c.cost,c.mana,c.mana_payment])))
 out["rows_payloads"]=r1_digest(JSON.stringify(rows.map(func(c):return c.payload)))
 out["rows_labels"]=r1_digest(JSON.stringify(rows.map(func(c):return c.label)))
 out["facts_text"]=r1_digest(JSON.stringify(rows.map(func(c):return [c.key,String(c.get("group","action")),c.label,c.cost,c.mana,c.valid,c.reason,c.risk,String(c.get("brief","")),String(c.get("brief_tags","")),String(c.get("body_part","")),String(c.get("detail",""))])))
 out["view"]=r1_digest(JSON.stringify(r1_view_without_mask(view)))
 out["view_display_facts"]=str(view.display_facts.size())
 out["view_card_texts"]=str(view.card_texts.size())
 out["view_hand"]=str(view.hand.size())
 out["view_available"]=r1_digest(JSON.stringify(view.hand.map(func(card):return [card.uid,card.availability])))
 out["first_turn"]=r1_digest(JSON.stringify(view.get("first_turn_control",{})))
 out["first_turn_name"]=str(view.get("first_turn_control",{}).get("name",""))
 out["first_turn_locked"]=str(view.get("first_turn_control",{}).get("locked",false))
 var blocked=rows.filter(func(c):return c.reason=="豆包接管中")
 out["takeover_blocked"]=str(blocked.size())
 out["takeover_reason"]="豆包接管中" if blocked.size()>0 else ""
 var automated=rows.filter(func(c):return c.get("automated",false))
 out["takeover_automated"]=str(automated.size())
 out["takeover_step"]=r1_digest(JSON.stringify(automated.map(func(c):return c.payload)))
 var version=int(g.state.version)
 out["reject_forged"]=str(g.dispatch(g.command({"kind":"card","uid":"forged_id"},version),version).get("error",""))
 var first_invalid={}
 for c in rows:
  if not c.valid: first_invalid=c;break
 out["reject_invalid"]="<none>" if first_invalid.is_empty() else str(g.dispatch(g.command(first_invalid.payload,version),version).get("error",""))
 out["reject_stale"]="<none>" if rows.is_empty() else str(g.dispatch(g.command(rows[0].payload,version-1),version-1).get("error",""))
 var usable={}
 for c in rows:
  if c.valid: usable=c;break
 if usable.is_empty():
  out["submit_ok"]="<none>"
  out["submit_error"]="<none>"
  out["submit_kind"]="<none>"
  out["submit_keys"]="<none>"
  out["submit_checkpoint"]="<none>"
 else:
  var result=g.dispatch(g.command(usable.payload,g.state.version),g.state.version)
  out["submit_ok"]=str(result.ok)
  out["submit_error"]=str(result.get("error",""))
  out["submit_kind"]=str(usable.payload.get("kind",""))
  out["submit_keys"]=r1_digest(JSON.stringify(result.keys()))
  out["submit_checkpoint"]=str(result.get("checkpoint",""))
 out["post_phase"]=str(g.state.phase)
 out["post_version"]=str(g.state.version)
 out["snapshot"]=r1_digest(JSON.stringify(g.export_snapshot()))
 out["rng"]=r1_digest(JSON.stringify(g.state.rng))
 out["rng_total"]=str(g.state.rng.values().reduce(func(a,b):return int(a)+int(b),0))
 out["logs"]=str(g.state.logs.size())
 out["validate_after"]=str(g.validate())
 return out

# view 摘要按批 R3 的显式 mask 删键（docs/spec/candidate-removal.md「接口」判据真源 behavior_baseline_equivalence 的 mask 语义：显式声明、不得静默）。
static func r1_view_without_mask(view: Dictionary) -> Dictionary:
 var masked={}
 for key in view:
  if key in R3_VIEW_MASK: continue
  if key in R5_VIEW_MASK: continue
  masked[key]=view[key]
 return masked

static func r1_record_digest(record: Dictionary) -> String:
 var paths=record.keys()
 paths.sort()
 var lines=[]
 for path in paths: lines.append(str(path)+"="+str(record[path]))
 return r1_digest("\n".join(lines))

# docs/spec/candidate-removal.md「接口」判据真源（removal_end_state；批 R5）：终态断言。扫描面＝core/、ui/、tests/ 的源码文本
# （tools/ 与 data/ 不进面：tools 的允许清单条目按契约只点名不动手，data 的规则池不属候选层）。
# 模式串按片段拼接，避免扫描器命中本检查自身的声明文本。
static func r5_removed_patterns() -> Array:
 var bs=String.chr(92)
 return [
  [bs+"bfunc"+bs+"s+cand"+"idates"+bs+"s*"+bs+"(","候选层入口 candidates()"],
  [bs+"bfunc"+bs+"s+_cand"+"idate"+bs+"s*"+bs+"(","行工厂 _candidate()"],
  [bs+"bfunc"+bs+"s+_build_cand"+"idates"+bs+"s*"+bs+"(","行表构建 _build_candidates()"],
  [bs+"bfunc"+bs+"s+_phase_cand"+"idates"+bs+"s*"+bs+"(","阶段行构建 _phase_candidates()"],
  ["[^A-Za-z0-9_]_cand"+"idate"+bs+"(","行工厂调用 _candidate("],
  [bs+".cand"+"idates"+bs+"("+bs+")","候选层调用 .candidates()"],
  ["view"+bs+".cand"+"idates"+bs+"b","候选行表键 view.candidates"],
  ["Action"+"Index","行索引类 ActionIndex"],
  ["fact_by_"+"id","按提交身份 id 的取行复核"],
 ]


static func removal_end_state(t) -> void:
 var offenders=[]
 var files=[]
 for root in ["res://core","res://ui","res://tests"]:
  for path in script_files(root):
   # 扫描器不扫自身（本文件的声明文本与描述文本含有被扫的符号名，会自命中）。
   if path=="res://tests/architecture_cases.gd": continue
   var handle=FileAccess.open(path,FileAccess.READ)
   if handle==null: continue
   var text=handle.get_as_text()
   files.append(path)
   for entry in r5_removed_patterns():
    var regex=RegEx.new()
    if regex.compile(String(entry[0]))!=OK:
     offenders.append(path+" :: uncompiled "+String(entry[1]))
     continue
    if regex.search(text)!=null: offenders.append(path.trim_prefix("res://")+" :: "+String(entry[1]))
 t.check(offenders.is_empty(),"G7 removal_end_state: the removed carrier symbols, the row index class and id-based row lookups are absent from the source: "+str(offenders.slice(0,4)))
 t.check(files.size()>150,"G7 removal_end_state: the scan covered the source face: "+str(files.size()))
 t.check(not FileAccess.file_exists("res://ui/action_index.gd"),"G7 removal_end_state: ui/action_index.gd is deleted")
 t.check(not FileAccess.file_exists("res://core/candidate_deps.gd") and not FileAccess.file_exists("res://ui/candidate_delta.gd"),"G7 removal_end_state: the superseded candidate-layer helpers stay absent")

static func behavior_baseline_equivalence(t) -> void:
 var frozen_cells=R1_BASELINE.keys()
 frozen_cells.sort()
 var cells=r1_cells()
 var expected=cells.map(func(cell):return "%s:%d" % [cell[0],cell[1]])
 expected.sort()
 t.check(expected==frozen_cells,"G6 behavior_baseline_equivalence: the fixture matrix matches the frozen baseline cells: "+str(expected)+" vs "+str(frozen_cells))
 # 记录路径＝R1 冻结路径 － 显式声明的删除集合（R5_RECORD_MASK）＋ 显式声明的重算路径（R5_RECORD_ADDED）。
 var declared=R1_RECORD_PATHS.filter(func(path):return not path in R5_RECORD_MASK)
 declared.append_array(R5_RECORD_ADDED)
 declared.sort()
 # 视图键基面＝R1 冻结键面 － 显式声明的删除集合（R5_VIEW_MASK）。
 var key_base=R3_VIEW_KEYS_BASE.filter(func(name):return not name in R5_VIEW_MASK)
 var path_problems=[]
 var value_problems=[]
 var key_problems=[]
 var mask_problems=[]
 var removed_problems=[]
 for cell in cells:
  var phase=String(cell[0])
  var count=int(cell[1])
  var key="%s:%d" % [phase,count]
  var built=r1_build(phase,count)
  var view_keys=built.get_view().keys()
  var kept=view_keys.filter(func(name):return name in key_base)
  var added=view_keys.filter(func(name):return not name in R3_VIEW_KEYS_BASE)
  var removed=R5_VIEW_MASK.filter(func(name):return name in view_keys)
  if kept.size()!=key_base.size():
   key_problems.append(key+" kept="+str(kept.size())+" frozen="+str(key_base.size())+" missing="+str(key_base.filter(func(name):return not name in view_keys).slice(0,3)))
  added.sort()
  var declared_mask=["display_facts","display_fact_scope"]
  declared_mask.sort()
  if added!=declared_mask: mask_problems.append(key+" added="+str(added)+" declared="+str(declared_mask))
  if not removed.is_empty(): removed_problems.append(key+" removed="+str(removed))
  var record=r1_record(built,phase,count)
  var paths=record.keys()
  paths.sort()
  if paths!=declared:
   var extra=paths.filter(func(path):return not declared.has(path))
   var missing=declared.filter(func(path):return not paths.has(path))
   path_problems.append(key+" extra="+str(extra)+" missing="+str(missing))
   continue
  var frozen=R1_BASELINE.get(key,{})
  var recomputed=R5_BASELINE.get(key,{})
  for path in frozen:
   if path in ["record","view"] or path in R5_RECORD_MASK: continue
   if R5_FIRST_TURN.has(key) and path=="first_turn": continue
   var current=str(record[path])
   if current!=frozen[path]: value_problems.append(key+"."+path+" baseline="+frozen[path]+" current="+current)
  if R5_FIRST_TURN.has(key) and str(record.get("first_turn",""))!=String(R5_FIRST_TURN[key]): value_problems.append(key+".first_turn baseline="+String(R5_FIRST_TURN[key])+" current="+str(record.get("first_turn","")))
  for path in R5_RECORD_ADDED:
   var current_added=str(record[path])
   var added_baseline=str(recomputed.get(path,"<missing>"))
   if current_added!=added_baseline: value_problems.append(key+"."+path+" baseline="+added_baseline+" current="+current_added)
  var masked_view=str(recomputed.get("view","<missing>"))
  if str(record.get("view",""))!=masked_view: value_problems.append(key+".view baseline="+masked_view+" current="+str(record.get("view","")))
  var record_digest=r1_record_digest(record)
  var frozen_record=str(recomputed.get("record",frozen.get("record","")))
  if record_digest!=frozen_record: value_problems.append(key+".<record> baseline="+frozen_record+" current="+record_digest)
  if str(record.pieces_ok)!="true": value_problems.append(key+".pieces_ok current="+str(record.pieces_ok))
 var undeclared=R1_MASK.filter(func(path):return not declared.has(path))
 t.check(path_problems.is_empty() and undeclared.is_empty(),"G6 behavior_baseline_equivalence: every cell keeps exactly the frozen record paths minus the declared deletions plus the declared recomputed paths: "+str(path_problems.slice(0,3)))
 value_problems.sort()
 t.check(value_problems.is_empty(),"G6 behavior_baseline_equivalence: every field equals the unmodified-source baseline (declared masks applied); first difference "+str(value_problems.slice(0,3)))
 t.check(key_problems.is_empty(),"G6 behavior_baseline_equivalence: every cell keeps exactly the frozen view keys minus the declared deletions: "+str(key_problems.slice(0,3)))
 t.check(mask_problems.is_empty(),"G6 behavior_baseline_equivalence: the added view keys are exactly the declared mask: "+str(mask_problems.slice(0,3)))
 t.check(removed_problems.is_empty() and not FileAccess.file_exists("res://ui/action_index.gd"),"G6 behavior_baseline_equivalence: the declared deletion set is gone from the projection and the row index file is deleted: "+str(removed_problems.slice(0,3)))

# docs/spec/candidate-removal.md「接口」判据真源（single_eligibility_implementation；批 R1；R2 前置补正：写点扫描面加宽，销 R1 复核缺口①）。
# 扫描面＝core/ 与 ui/ 的源码文本（tests／data 不进面）；写点四种形态——字段赋值（.valid=／.reason=）、
# 字典键（"valid":／"reason":）、括号赋值（["valid"]=／["reason"]=）、括号字典键（["valid"]:／["reason"]:）；
# 读取式（x.valid／x.reason 作为值）不计。判定落点＝core/game.gd 的 eligibility／eligibility_takeover。
const VERDICT_PRODUCERS={"core/game.gd":["eligibility","eligibility_takeover"]}
# 非判定载体（逐函数声明）：这些模块的 reason 字段是各自域内的原因文本（装备施加结果、接触可达、事件闸门、
# 奖励行、工具操作者、施法路线、快照预览、每点击检查的调试诊断等），不是资格结论；表外任何 reason 写点即红
# （加宽后的 stray 面）。双向核对：表外写点即红，表内每项仍须被扫到（防表腐烂）。
const VERDICT_REASON_CARRIERS=[
 "core/contact.gd::evaluate",
 "core/contact.gd::profile",
 "core/equipment_application.gd::_evaded",
 "core/equipment_application.gd::_failure",
 "core/equipment_application.gd::_result",
 "core/equipment_application.gd::execute",
 "core/equipment_replacement.gd::_fail",
 "core/equipment_replacement.gd::_force_special_live",
 "core/equipment_replacement.gd::_trial",
 "core/equipment_replacement.gd::execute",
 "core/game.gd::_build_cast_view",
 "core/game.gd::_build_escape_preview",
 "core/game.gd::_cast_path",
 "core/game.gd::_debug_check",
 "core/game.gd::_prepare_installation",
 "core/game.gd::kick_profile",
 "core/game_view.gd::battle_rewards",
 "core/game_view.gd::reward_card_row",
 "core/game_view.gd::reward_panel",
 "core/pressure.gd::calm",
 "core/relic_bundle.gd::panel",
 "core/room_events.gd::_freeze_in_place",
 "core/room_events.gd::_freeze_staged",
 "core/room_events.gd::condition_entries",
 "core/room_events.gd::evaluate_option",
 "core/room_events.gd::feasibility_gate",
 "core/room_events.gd::probe_result",
 "core/room_events.gd::trace_entry",
 "core/room_services.gd::_job",
 "core/slip_motion.gd::apply",
 "core/tool_rules.gd::operator_profile",
]

static func verdict_write_scan() -> Dictionary:
 var valid=RegEx.new()
 valid.compile("(\\.valid\\s*=[^=])|(\\[\"valid\"\\]\\s*=)|(\"valid\"\\s*:\\s*(?!\\w+\\.valid))|(\\[\"valid\"\\]\\s*:\\s*(?!\\w+\\.valid))")
 var reason=RegEx.new()
 reason.compile("(\\.reason\\s*=[^=])|(\\[\"reason\"\\]\\s*=)|(\"reason\"\\s*:\\s*(?!\\w+\\.reason))|(\\[\"reason\"\\]\\s*:\\s*(?!\\w+\\.reason))")
 var declaration=RegEx.new()
 declaration.compile("^\\s*(?:static\\s+)?func\\s+([A-Za-z_][A-Za-z0-9_]*)")
 var hits=[]
 var functions={}
 for root in ["res://core","res://ui"]:
  for path in script_files(root):
   var handle=FileAccess.open(path,FileAccess.READ)
   if handle==null: continue
   var lines=handle.get_as_text().split("\n")
   var current="<file>"
   for index in range(lines.size()):
    var code=String(lines[index]).split("#")[0]
    var declared=declaration.search(code)
    if declared!=null: current=declared.get_string(1)
    var writes_valid=valid.search(code)!=null
    var writes_reason=reason.search(code)!=null
    if not writes_valid and not writes_reason: continue
    var relative=path.trim_prefix("res://")
    hits.append({"file":relative,"function":current,"line":index+1,"valid":writes_valid,"reason":writes_reason,"text":code.strip_edges()})
    if not functions.has(relative): functions[relative]={}
    var row=functions[relative].get(current,{"valid":false,"reason":false})
    row.valid=row.valid or writes_valid
    row.reason=row.reason or writes_reason
    functions[relative][current]=row
 return {"hits":hits,"functions":functions}

static func verdict_site(hit: Dictionary) -> String:
 return String(hit.file)+"::"+String(hit.function)+":"+str(hit.line)+" "+String(hit.text)

static func single_eligibility_implementation(t) -> void:
 var scan=verdict_write_scan()
 # 1) valid 键只由判定产出：其它位置的写点即红（第二份判定／接管路径自写）。
 var stray_valid=scan.hits.filter(func(hit):return hit.valid and not VERDICT_PRODUCERS.get(hit.file,[]).has(hit.function))
 t.check(stray_valid.is_empty(),"G4 single_eligibility_implementation: valid is written only by the declared determination: "+str(stray_valid.map(func(hit):return verdict_site(hit))))
 # 2) reason 键只由判定产出或已声明的非判定载体产出：表外的 reason 写点即红（销 R1 复核缺口①：只写 reason 的
 #    第二判定必须变红）。
 var stray_reason=scan.hits.filter(func(hit):return hit.reason and not VERDICT_PRODUCERS.get(hit.file,[]).has(hit.function) and not VERDICT_REASON_CARRIERS.has(String(hit.file)+"::"+String(hit.function)))
 t.check(stray_reason.is_empty(),"G4 single_eligibility_implementation: reason is written only by the declared determination or a declared non-verdict carrier: "+str(stray_reason.map(func(hit):return verdict_site(hit))))
 # 3) 声明的非判定载体全部仍在位（表内每项都被扫到，表腐烂即红）。
 var missing_carriers=[]
 for site in VERDICT_REASON_CARRIERS:
  var parts=String(site).split("::")
  var row=scan.functions.get(parts[0],{}).get(parts[1],{})
  if not row.get("reason",false): missing_carriers.append(site)
 t.check(missing_carriers.is_empty(),"G4 single_eligibility_implementation: every declared non-verdict carrier still writes reason: "+str(missing_carriers))
 # 4) 判定落点自身在位，且两个入口都产出 valid 与 reason（删掉判定即红）。
 var missing_production=[]
 for file in VERDICT_PRODUCERS:
  for function in VERDICT_PRODUCERS[file]:
   var row=scan.functions.get(file,{}).get(function,{})
   if not row.get("valid",false) or not row.get("reason",false): missing_production.append(file+"::"+function)
 t.check(missing_production.is_empty(),"G4 single_eligibility_implementation: every declared determination entry produces both valid and reason: "+str(missing_production))
 # 5) 同一函数同时产出 valid 与 reason 的第二实现即红。
 var second=[]
 for file in scan.functions:
  for function in scan.functions[file]:
   var row=scan.functions[file][function]
   if row.valid and row.reason and not VERDICT_PRODUCERS.get(file,[]).has(function): second.append(file+"::"+function)
 t.check(second.is_empty(),"G4 single_eligibility_implementation: no second verdict producer: "+str(second))
 # 6) UI 与接管路径所在文件不得自写判定（销 DUP2）。
 var ui_writes=scan.hits.filter(func(hit):return String(hit.file).begins_with("ui/"))
 var takeover_writes=scan.hits.filter(func(hit):return String(hit.file)=="core/first_turn_control.gd")
 t.check(ui_writes.is_empty() and takeover_writes.is_empty(),"G4 single_eligibility_implementation: ui/ and the takeover path only consume the determination: ui="+str(ui_writes.map(func(hit):return verdict_site(hit)))+" takeover="+str(takeover_writes.map(func(hit):return verdict_site(hit))))

# docs/spec/candidate-removal.md「接口」判据真源（instruction_router_single_entry／instruction_route_table_is_total；批 R2）：指令路由单入口＋分类表全量。
# kind 全集与逐域＝契约（docs/spec/candidate-removal.md「输入域」）（39 条）；本表是核对面，不是第二真源（真源是 ui/command_router.gd 的 ROUTES）。
# 域列与 ROUTES 逐条相等（R2 复核低项：end／calm／surrender 曾与 ROUTES 不一致且未被断言使用）。
const COMMAND_KINDS={
 "card":"battle","chain":"battle","attack":"battle","status_toggle":"battle","posture":"battle",
 "wall_move":"battle","manual":"battle","hook":"battle","end":"flow","calm":"battle","surrender":"flow",
 "item_use":"item","item_install":"item","item_retrieve":"item","item_discard":"item",
 "finish_prepare":"flow","finish_rest":"flow","finish_pack":"flow","retain":"flow","retain_skip":"flow",
 "rest_rare":"rest","rest_card":"rest","rest_flask":"rest","rest_begin":"rest",
 "service":"shop","event":"event","prison":"prison","depart":"route","travel_step":"route",
 "reward":"reward","reward_skip":"reward","relic_bundle":"reward","departure":"departure",
 "flask":"relic","relic_toggle":"relic","relic_discharge":"relic","relic_control_done":"relic",
 "demo_end":"demo","demo_continue":"demo"}

# docs/spec/candidate-removal.md「接口」判据真源 instruction_route_table_is_total 的逐域覆盖面（战斗／整备／休息／商店／事件／监狱／路线／奖励／出发／demo）。
const COMMAND_DOMAINS=["battle","flow","rest","shop","event","prison","route","reward","departure","demo"]

# 子路由的实现面：command_routes.gd::assemble 的 match 分支名（唯一分类点的落地检查）。
static func command_route_branches() -> Array:
 var handle=FileAccess.open("res://ui/command_routes.gd",FileAccess.READ)
 if handle==null: return []
 var regex=RegEx.new()
 regex.compile("^\\s*((?:\"[a-z_]+\"\\s*,\\s*)*\"[a-z_]+\")\\s*:")
 var result=[]
 for line in handle.get_as_text().split("\n"):
  var hit=regex.search(line)
  if hit==null: continue
  for token in hit.get_string(1).split(","):
   var name=token.strip_edges().trim_prefix("\"").trim_suffix("\"")
   if name!="" and name not in result: result.append(name)
 return result

static func instruction_router_single_entry(t) -> void:
 var submit_pattern=RegEx.new()
 submit_pattern.compile("(?:^|[^_A-Za-z0-9])_submit\\s*\\(")
 var dispatch_pattern=RegEx.new()
 dispatch_pattern.compile("\\.dispatch\\s*\\(")
 var emit_pattern=RegEx.new()
 emit_pattern.compile("command_router\\.emit(?:_deferred)?\\s*\\(")
 var deferred_pattern=RegEx.new()
 deferred_pattern.compile("call_deferred\\(\\s*\"_submit\"")
 var submit_sites=[];var dispatch_sites=[];var deferred_sites=[];var emit_sites={}
 for path in script_files("res://ui"):
  var handle=FileAccess.open(path,FileAccess.READ)
  if handle==null: continue
  var relative=path.trim_prefix("res://")
  var lines=handle.get_as_text().split("\n")
  for index in range(lines.size()):
   var code=String(lines[index]).split("#")[0]
   var stripped=code.strip_edges()
   if submit_pattern.search(code)!=null and not stripped.begins_with("func "):
    submit_sites.append(relative+":"+str(index+1)+" "+stripped)
   if dispatch_pattern.search(code)!=null: dispatch_sites.append(relative+":"+str(index+1)+" "+stripped)
   if emit_pattern.search(code)!=null: emit_sites[relative]=int(emit_sites.get(relative,0))+1
   if deferred_pattern.search(code)!=null: deferred_sites.append(relative+":"+str(index+1)+" "+stripped)
 # 1) 提交执行段只由指令路由调用（A1–A60 形态的直连 0 条）。
 var direct=submit_sites.filter(func(site):return not String(site).begins_with("ui/command_router.gd:"))
 t.check(submit_sites.size()==1 and direct.is_empty() and deferred_sites.is_empty(),"G1 instruction_router_single_entry: the execution segment is called only by the router: "+str(submit_sites)+" direct="+str(direct)+" deferred="+str(deferred_sites))
 # 2) UI 侧 dispatch 调用点唯一（在 ui/main.gd::_submit 内）。
 t.check(dispatch_sites.size()==1 and String(dispatch_sites[0]).begins_with("ui/main.gd:"),"G1 instruction_router_single_entry: ui/ has exactly one dispatch call site: "+str(dispatch_sites))
 # 3) 控件回调经同一入口 emit；自动接管与键盘都在其中（takeover 参数语义不变）。
 var keyboard=int(emit_sites.get("ui/keyboard_input.gd",0))
 var presenter=int(emit_sites.get("ui/first_turn_presenter.gd",0))
 t.check(int(emit_sites.get("ui/main.gd",0))>0 and keyboard==3 and presenter==1 and int(emit_sites.get("ui/shop_screen.gd",0))>0,"G1 instruction_router_single_entry: every UI source emits through the router: main="+str(emit_sites.get("ui/main.gd",0))+" keyboard="+str(keyboard)+" takeover="+str(presenter))
 var presenter_text=""
 var presenter_handle=FileAccess.open("res://ui/first_turn_presenter.gd",FileAccess.READ)
 if presenter_handle!=null: presenter_text=presenter_handle.get_as_text()
 t.check(presenter_text.contains("emit(") and presenter_text.contains(",true)"),"G1 instruction_router_single_entry: the automated takeover keeps its takeover flag on the same entry")
 # 4) 新文件在位且不 preload core（依赖方向）。
 for name in ["ui/command_router.gd","ui/command_routes.gd"]:
  var handle=FileAccess.open("res://"+name,FileAccess.READ)
  var text="" if handle==null else handle.get_as_text()
  t.check(text!="" and not text.contains("res://core"),"G1 instruction_router_single_entry: "+name+" exists and does not preload core")

static func instruction_route_table_is_total(t) -> void:
 var router=preload("res://ui/command_router.gd")
 var routes=router.ROUTES
 # 1) kind 全集＝契约（docs/spec/candidate-removal.md「输入域」）的 39 条（多一条少一条即红）。
 var missing=[];var extra=[]
 for kind in COMMAND_KINDS:
  if not routes.has(kind): missing.append(kind)
 for kind in routes:
  if not COMMAND_KINDS.has(kind): extra.append(kind)
 t.check(missing.is_empty() and extra.is_empty() and routes.size()==COMMAND_KINDS.size(),"G2 instruction_route_table_is_total: the table holds exactly the 39 declared kinds: missing="+str(missing)+" extra="+str(extra)+" size="+str(routes.size()))
 # 1b) 夹具域列与真源 ROUTES 逐条相等（夹具守卫：防域列再次漂移而无人察觉）。
 var drifted=[]
 for kind in COMMAND_KINDS:
  if routes.has(kind) and String(routes[kind])!=String(COMMAND_KINDS[kind]): drifted.append(kind+" fixture="+String(COMMAND_KINDS[kind])+" routes="+String(routes[kind]))
 t.check(drifted.is_empty(),"G2 instruction_route_table_is_total: the fixture domain column matches the route table: "+str(drifted))
 # 2) 每个 kind 恰有一条子路由，且子路由名在 command_routes.gd 有实现。
 var branches=command_route_branches()
 var dangling=[];var used=[]
 for kind in routes:
  var route=String(routes[kind])
  if route not in branches: dangling.append(kind+"->"+route)
  if route not in used: used.append(route)
 var orphans=branches.filter(func(name):return name not in used)
 t.check(dangling.is_empty() and orphans.is_empty(),"G2 instruction_route_table_is_total: every kind resolves to a declared subroute and no subroute is orphaned: dangling="+str(dangling)+" orphans="+str(orphans))
 # 3) 覆盖优先：契约点名的域都在表内。
 var domains=[]
 for kind in routes:
  if String(routes[kind]) not in domains: domains.append(String(routes[kind]))
 var uncovered=COMMAND_DOMAINS.filter(func(name):return name not in domains)
 t.check(uncovered.is_empty(),"G2 instruction_route_table_is_total: the named domains are covered: "+str(uncovered)+" of "+str(domains))
 # 4) 表外 kind fail-closed：拒绝、留一条记录、不静默、不崩。
 var probe=router.new(null)
 var outcome=probe.emit("no_such_command",{})
 t.check(not outcome.ok and not outcome.submitted and probe.rejections.size()==1 and String(probe.rejections[0].kind)=="no_such_command","G2 instruction_route_table_is_total: an unknown kind is refused and recorded: "+str(outcome)+" "+str(probe.rejections))
 # 5) 提交侧按形状复核的前提：夹具里每个 (kind, params) 恰有一条候选行。
 var duplicates=[]
 for cell in r1_cells():
  var g=r1_build(cell[0],cell[1])
  if g==null: continue
  var seen={}
  for c in g.command_facts():
   var key=String(c.payload.get("kind",""))+"|"+JSON.stringify(g.command_params(c.payload.kind,c.payload))
   if seen.has(key): duplicates.append(str(cell)+" "+key+" rows="+str(seen[key])+"/"+String(c.label))
   seen[key]=String(c.label)
 t.check(duplicates.is_empty(),"G2 instruction_route_table_is_total: every command shape resolves to exactly one row: "+str(duplicates.slice(0,3)))

# Fact-lookup kind sets: POINT_KINDS lists the kinds converted to point form (S1 empty; S2 added
# attack, S3 added card). Table kinds are derived from COMMAND_KEYS minus POINT_KINDS, never written out.
const POINT_KINDS=["attack","card"]
const T4_EQUIVALENCE_CELLS=[["battle",0],["battle",12],["battle",26],["battle",44],["prepare",0],["rest",0],["takeover",0]]

static func table_kinds() -> Array:
 var out=[]
 for kind in GameCore.COMMAND_KEYS:
  if kind not in POINT_KINDS: out.append(kind)
 return out

# R4: the kind -> table source identity is frozen with a literal expected side written here, independent
# of CommandRegistry and core/game.gd, so pointing a kind at another existing g method (or swapping the
# takeover source) is caught even though command_registry_is_total and the row-equality checks stay
# green. Never derive this table from the registry. Update it in the same batch that changes a form
# (S2 moved attack to point form and dropped it here; S3 dropped card).
# B 批（K2）rebase：23 项从 _whole_table_kind_facts 改为各自的域臂，old -> new 逐条如下——
#   chain: _whole_table_kind_facts -> _chain_kind_facts
#   demo_continue: _whole_table_kind_facts -> _demo_exit_kind_facts
#   demo_end: _whole_table_kind_facts -> _demo_exit_kind_facts
#   depart: _whole_table_kind_facts -> _depart_kind_facts
#   departure: _whole_table_kind_facts -> _departure_kind_facts
#   event: _whole_table_kind_facts -> _events_kind_facts
#   hook: _whole_table_kind_facts -> _hook_kind_facts
#   item_install: _whole_table_kind_facts -> _item_action_kind_facts
#   item_retrieve: _whole_table_kind_facts -> _item_action_kind_facts
#   manual: _whole_table_kind_facts -> _manual_kind_facts
#   prison: _whole_table_kind_facts -> _prison_kind_facts
#   relic_bundle: _whole_table_kind_facts -> _relic_bundle_kind_facts
#   relic_control_done: _whole_table_kind_facts -> _relic_control_done_kind_facts
#   rest_begin: _whole_table_kind_facts -> _rest_choice_kind_facts
#   rest_card: _whole_table_kind_facts -> _rest_choice_kind_facts
#   rest_flask: _whole_table_kind_facts -> _rest_choice_kind_facts
#   rest_rare: _whole_table_kind_facts -> _rest_choice_kind_facts
#   retain: _whole_table_kind_facts -> _retain_kind_facts
#   retain_skip: _whole_table_kind_facts -> _retain_kind_facts
#   reward: _whole_table_kind_facts -> _reward_kind_facts
#   reward_skip: _whole_table_kind_facts -> _reward_kind_facts
#   service: _whole_table_kind_facts -> _services_kind_facts
#   travel_step: _whole_table_kind_facts -> _travel_step_kind_facts
const FROZEN_TABLE_SOURCES={
 "chain":"_chain_kind_facts",
 "status_toggle":"_status_toggle_kind_facts",
 "posture":"_posture_kind_facts",
 "wall_move":"_wall_move_kind_facts",
 "manual":"_manual_kind_facts",
 "hook":"_hook_kind_facts",
 "end":"_flow_kind_facts",
 "calm":"_flow_kind_facts",
 "surrender":"_surrender_kind_facts",
 "item_use":"_item_use_kind_facts",
 "item_install":"_item_action_kind_facts",
 "item_retrieve":"_item_action_kind_facts",
 "item_discard":"_item_discard_kind_facts",
 "finish_prepare":"_flow_kind_facts",
 "finish_rest":"_flow_kind_facts",
 "finish_pack":"_flow_kind_facts",
 "retain":"_retain_kind_facts",
 "retain_skip":"_retain_kind_facts",
 "rest_rare":"_rest_choice_kind_facts",
 "rest_card":"_rest_choice_kind_facts",
 "rest_flask":"_rest_choice_kind_facts",
 "rest_begin":"_rest_choice_kind_facts",
 "service":"_services_kind_facts",
 "event":"_events_kind_facts",
 "prison":"_prison_kind_facts",
 "depart":"_depart_kind_facts",
 "travel_step":"_travel_step_kind_facts",
 "reward":"_reward_kind_facts",
 "reward_skip":"_reward_kind_facts",
 "relic_bundle":"_relic_bundle_kind_facts",
 "departure":"_departure_kind_facts",
 "flask":"_flask_kind_facts",
 "relic_toggle":"_relic_kind_facts",
 "relic_discharge":"_relic_kind_facts",
 "relic_control_done":"_relic_control_done_kind_facts",
 "demo_end":"_demo_exit_kind_facts",
 "demo_continue":"_demo_exit_kind_facts",
}
const FROZEN_TAKEOVER_SOURCE="command_facts"

# S2/S3: the point-form method names get the same literal freeze (expected side written here, never derived
# from CommandRegistry). Missing/mismatched = a point kind lost its declared builder; extra = a point kind
# without a frozen expectation. The card trio forwards to core/card_effects.gd, where the single
# enumeration and constructor live.
const FROZEN_POINT_METHODS={
 "attack":{"keys":"attack_point_keys","build":"attack_point_fact","member":"attack_point_member"},
 "card":{"keys":"card_point_keys","build":"card_point_fact","member":"card_point_member"},
}

# C1 diff: kinds present in the given set but missing from the registry. The totality check and the
# synthetic self-check below run this same function, so a gap cannot be hidden by a second comparison.
static func command_registry_missing(kinds: Array) -> Array:
 var missing=[]
 for kind in kinds:
  if CommandRegistry.entry(kind).is_empty(): missing.append(kind)
 return missing

static func command_registry_extra() -> Array:
 var extra=[]
 for kind in CommandRegistry.kinds():
  if not GameCore.COMMAND_KEYS.has(kind): extra.append(kind)
 return extra

static func t4_median(samples: Array) -> int:
 var ordered=samples.duplicate()
 ordered.sort()
 return int(ordered[int(ordered.size()/2)])

static func t4_dense_51():
 var g=r1_build("battle",80)
 var added=0
 for e in g.state.equipment:
  if added>=3: break
  if g.Shoulders.install(g,e,"rope",3,"fixture"): added+=1
 return g

const PIPELINE_LOOKUP_FUNCS=["command_fact","_command_fact_row","_kind_facts","command_facts"]
const PIPELINE_LOOKUP_EDGES=[
 {"id":"L-point","from":"core/game.gd::command_fact","to":"core/game.gd::display_fact","type":"call","path":"nontakeover _command_fact_row -> CommandRegistry.point -> registry entry source (S2/S3: keys/build/member) -> display_fact"},
 {"id":"L-table","from":"core/game.gd::command_facts","to":"core/game.gd::_fact_source","type":"call","path":"command_facts for-loop: _fact_source() then display_fact"},
]
const PIPELINE_P2_EDGES=[
 {"id":"T4","from":"core/game.gd::dispatch","to":"core/game.gd::eligibility","type":"call"},
 {"id":"T5","from":"core/game_view.gd::build","to":"core/game.gd::eligibility","type":"call"},
]

static func pipeline_lookup_edges() -> Array:
 return PIPELINE_LOOKUP_EDGES.duplicate()

static func pipeline_lookup_func_name(anchor: String) -> String:
 var parts=String(anchor).split("::")
 return "" if parts.is_empty() else String(parts[parts.size()-1])

static func pipeline_lookup_func_body(name: String) -> String:
 if name not in PIPELINE_LOOKUP_FUNCS: return ""
 var handle=FileAccess.open("res://core/game.gd",FileAccess.READ)
 if handle==null: return ""
 var source=handle.get_as_text()
 var start=source.find("func "+name+"(")
 if start<0: return ""
 var rest=source.substr(start)
 var nxt=rest.find("\nfunc ",1)
 var body=rest if nxt<0 else rest.substr(0,nxt)
 var code=""
 for line in body.split("\n"): code+=String(line).split("#")[0]+"\n"
 return code

static func pipeline_lookup_call_count(body: String, name: String) -> int:
 var needle=name+"("
 var count=0
 var from=0
 while true:
  var at=body.find(needle,from)
  if at<0: break
  count+=1
  from=at+needle.length()
 return count

static func pipeline_lookup_nontakeover_row(body: String) -> String:
 var in_takeover=false
 var out=""
 for line in body.split("\n"):
  var text=String(line)
  if text.find("FirstTurnControl.active")>=0:
   in_takeover=true
   continue
  if in_takeover:
   if text.strip_edges()=="": continue
   if text.begins_with("  "): continue
   in_takeover=false
  out+=text+"\n"
 return out

static func pipeline_lookup_default_arm(body: String) -> String:
 var at=body.find("  _:")
 if at<0: return ""
 return body.substr(at)

# C1（plan §3 契约 1；docs/spec/fact-lookup-dependencies.md「自检清单」）：登记表与 COMMAND_KEYS 逐条相等
# （39／39，missing／extra 双向），form 显式，table 形 source 与 point 形 keys／build／member 都是 g 上
# 存在的方法名；POINT_KINDS 声明与登记形态一致（S1 空集，S2／S3 起增项）。
static func command_registry_is_total(t) -> void:
 var g=GameCore.new(42)
 var missing=command_registry_missing(GameCore.COMMAND_KEYS.keys())
 var extra=command_registry_extra()
 t.check(missing.is_empty() and extra.is_empty(),"command_registry_is_total: kinds() equals COMMAND_KEYS (39/39) missing="+str(missing)+" extra="+str(extra))
 t.check(CommandRegistry.kinds().size()==39,"command_registry_is_total: the registry declares exactly 39 kinds have="+str(CommandRegistry.kinds().size()))
 var bad_form=[]
 var bad_source=[]
 var bad_point=[]
 for kind in CommandRegistry.kinds():
  var item=CommandRegistry.entry(kind)
  var form=String(item.get("form",""))
  if form not in ["point","table"]:
   bad_form.append(kind+"="+form)
  elif form=="table":
   var source=String(item.get("source",""))
   if source.is_empty() or not g.has_method(source): bad_source.append(kind+"="+source)
  else:
   for field in ["keys","build","member"]:
    var name=String(item.get(field,""))
    if name.is_empty() or not g.has_method(name): bad_point.append(kind+"."+field+"="+name)
 t.check(bad_form.is_empty(),"command_registry_is_total: every entry declares form point|table: "+str(bad_form))
 t.check(bad_source.is_empty(),"command_registry_is_total: every table entry names an existing g source: "+str(bad_source))
 t.check(bad_point.is_empty(),"command_registry_is_total: every point entry names keys/build/member on g: "+str(bad_point))
 # 合成自检：同一差集函数必须报出未登记 kind，判据自身可检出缺口（实机一次变异见验证记录）。
 var synthetic=GameCore.COMMAND_KEYS.keys()
 synthetic.append("no_such_new_kind")
 t.check(command_registry_missing(synthetic)==["no_such_new_kind"],"command_registry_is_total: the same diff reports an unregistered kind: "+str(command_registry_missing(synthetic)))
 var wrong_form=[]
 for kind in POINT_KINDS:
  if not GameCore.COMMAND_KEYS.has(kind): wrong_form.append(kind+"!COMMAND_KEYS")
  elif String(CommandRegistry.entry(kind).get("form",""))!="point": wrong_form.append(kind+"!point")
 for kind in table_kinds():
  if String(CommandRegistry.entry(kind).get("form",""))!="table": wrong_form.append(kind+"!table")
 t.check(wrong_form.is_empty(),"command_registry_is_total: POINT_KINDS matches the entry forms: "+str(wrong_form))

# R4（审查补件）：kind → table 来源的身份用本文件字面表 FROZEN_TABLE_SOURCES 钉住（期望侧不取自
# CommandRegistry，防自证）。missing＝冻结项被改名／换源／换形或与 POINT_KINDS 冲突；extra＝登记表
# 有而冻结表没有的 table kind（双向都报）。接管整表来源名同样钉住。S1 的 POINT_KINDS 为空集，故本批
# 校 39 条 table 形；S2 起按批从本表移除该 kind，并由 FROZEN_POINT_METHODS 钉住 point 形的
# keys／build／member 三个方法名（期望侧同样写在测试内）。
static func fact_source_map_is_pinned(t) -> void:
 var missing=[]
 for kind in FROZEN_TABLE_SOURCES:
  if kind in POINT_KINDS:
   missing.append(kind+"!frozen-but-point")
   continue
  var item=CommandRegistry.entry(kind)
  var form=String(item.get("form",""))
  var source=String(item.get("source",""))
  if form!="table" or source!=FROZEN_TABLE_SOURCES[kind]:
   missing.append(kind+"="+form+"/"+source+" want=table/"+FROZEN_TABLE_SOURCES[kind])
 var extra=[]
 for kind in table_kinds():
  if not FROZEN_TABLE_SOURCES.has(kind): extra.append(kind)
 t.check(missing.is_empty(),"fact_source_map_is_pinned: every frozen kind keeps its pinned table source (missing or mismatched): "+str(missing))
 t.check(extra.is_empty(),"fact_source_map_is_pinned: every table kind has a frozen source expectation (extra): "+str(extra))
 t.check(CommandRegistry.takeover_source()==FROZEN_TAKEOVER_SOURCE,"fact_source_map_is_pinned: takeover source is pinned: have="+CommandRegistry.takeover_source()+" want="+FROZEN_TAKEOVER_SOURCE)
 var wrong_point=[]
 for kind in FROZEN_POINT_METHODS:
  if kind not in POINT_KINDS: wrong_point.append(kind+"!frozen-but-not-point-kind")
  var item=CommandRegistry.entry(kind)
  if String(item.get("form",""))!="point": wrong_point.append(kind+"="+String(item.get("form",""))+" want=point")
  for field in ["keys","build","member"]:
   var have=String(item.get(field,""))
   var want=String(FROZEN_POINT_METHODS[kind][field])
   if have!=want: wrong_point.append(kind+"."+field+"="+have+" want="+want)
 var extra_point=[]
 for kind in POINT_KINDS:
  if not FROZEN_POINT_METHODS.has(kind): extra_point.append(kind)
 t.check(wrong_point.is_empty(),"fact_source_map_is_pinned: every frozen point kind keeps its pinned keys/build/member: "+str(wrong_point))
 t.check(extra_point.is_empty(),"fact_source_map_is_pinned: every point kind has a frozen method expectation (extra): "+str(extra_point))
 print("FACT SOURCE MAP PINNED kinds=%d takeover=%s point=%d" % [FROZEN_TABLE_SOURCES.size(),FROZEN_TAKEOVER_SOURCE,FROZEN_POINT_METHODS.size()])

# ==== A 批（K0＋K1；plan §3 A 段；docs/spec/fact-table-dependencies.md）====
# 期望侧全部写在本文件（不取自登记表／投影实现；acceptance.md §3「oracle 独立性」④）：
#  PHASE_BRANCH_VOCABULARY＝_phase_branch 的分支 id 词表；PHASE_EMPTY_BRANCHES＝有分支 id、无单元的空表分支；
#  FACT_UNIT_EXPECTATION＝单元表 owner → 有序 [id, producer, input]（order 由序位给出，1 起）；
#  R5_*_PRE_DIGEST＝A 批动工前六个基线常量的副本摘要（值面；G-1 零移动）。
# 变体（被测侧的对照）：core/game.gd 的源码文本（_phase_branch 的 return 点、_phase_facts 的 return 点）。
const PHASE_BRANCH_VOCABULARY=["relic_bundle","departure","domain_blocked","rest_choice","shop_treasure","event","captured_inspection","prison_end","overload_climax","card_chain","pending_retain","reward","map","travel","cleared","pack","action_tail"]
const PHASE_EMPTY_BRANCHES=["map","prison_end"]
# _fact_source 的三个前缀 owner（登记表 FACT_PREFIX_OWNERS 的期望侧）；_phase_facts 的臂数（四个前缀／尾段标签共用一条臂）。
const FACT_SOURCE_PREFIX_BRANCHES=["relic_bundle","departure","domain_blocked"]
const PHASE_FACTS_ARMS=14
const FACT_UNIT_EXPECTATION={
 "relic_bundle":[["relic_bundle_prefix","_unit_relic_bundle",""],["relic_bundle_consumables","_unit_noncombat_consumables","relic_bundle_prefix"],["relic_bundle_flask","_unit_flask_full",""]],
 "departure":[["departure_prefix","_unit_departure",""],["departure_consumables","_unit_noncombat_consumables","departure_prefix"],["departure_flask","_unit_flask_full",""]],
 "main":[["phase","_unit_phase",""],["noncombat_consumables","_unit_noncombat_consumables","phase"],["route","_unit_route","phase"],["surrender","_unit_surrender",""],["item_discard","_unit_item_discard",""],["flask","_unit_flask",""],["relic_effects","_unit_relic_effects",""],["status_toggle","_unit_status_toggle",""]],
 "rest_choice":[["rest_choice_block","_unit_rest_choice",""]],
 "shop_treasure":[["services","_unit_services",""]],
 "event":[["events","_unit_events",""]],
 "captured_inspection":[["prison","_unit_prison",""]],
 "overload_climax":[["climax_end","_unit_climax_end",""]],
 "card_chain":[["chain","_unit_chain",""]],
 "pending_retain":[["retain","_unit_retain",""]],
 "reward":[["reward","_unit_reward",""]],
 "travel":[["travel_step","_unit_travel_step",""]],
 "cleared":[["demo_exit","_unit_demo_exit",""]],
 "pack":[["pack_items","_unit_item_action",""],["pack_flow","_unit_flow",""]],
 "action_tail":[["wall_move","_unit_wall_move",""],["posture","_unit_posture",""],["attack","_unit_attack",""],["equipment_spell","_unit_equipment_spell",""],["hand_cards","_unit_hand_cards",""],["manual","_unit_manual",""],["item_action","_unit_item_action",""],["hook","_unit_hook",""],["prison_tail","_unit_prison",""],["flow","_unit_flow",""]],
}
# 组列在夹具矩阵里观测不到的 (单元:组) 对（逐条给出理由）；判据双向核对：列出的必须真的观测不到
# （能观测到即红＝不能腐烂的豁免），未列的必须逐组观测到。
# B 批起为空：牌链夹具（flag:card_chain）落地后 phase 与 chain 的 chain 组已可观测，豁免逐条缩短为无。
const FACT_UNIT_GROUP_UNCOVERED=[]
# 动工前常量副本（*_PRE_DIGEST）与 R5_BASELINE 的动工前内容已外部化到 tests/frozen-baselines.json
# （A 批审查缺口 4：前值不得与被校验常量同文件，否则「同步改常量＋同步改前值」能白名单化）；
# 该文件逐项锚定到提交哈希，可由 git show <commit>:<file> 复算 sha256。

static func phase_branch_returns() -> Array:
 var body=source_func_body_code("res://core/game.gd","_phase_branch")
 var pattern=RegEx.new()
 if pattern.compile("return \"([a-z_]+)\"")!=OK: return []
 var out=[]
 for found in pattern.search_all(body): out.append(found.get_string(1))
 return out

static func phase_facts_labels() -> Array:
 var body=source_func_body_code("res://core/game.gd","_phase_facts")
 var pattern=RegEx.new()
 if pattern.compile("\"([a-z_]+)\"")!=OK: return []
 var out=[]
 for line in body.split("\n"):
  var text=String(line).strip_edges()
  if not text.begins_with("\""): continue
  var at=text.find(":")
  if at<0: continue
  for found in pattern.search_all(text.substr(0,at)): out.append(found.get_string(1))
 return out

# C-A-2（K0；gherkin A-2；acceptance.md §1 A 段）：分支词表 ↔ _phase_branch 的 return 点 ↔ _phase_facts 的 return 点
# 三处双向全量（期望侧＝本文件字面词表；被测侧＝源码文本，非运行时反射）。敏感性：新增一个早退分支不登记 → missing；
# 词表留一个死分支／改一个 return 字面 → extra／missing。
static func phase_branch_vocabulary_is_total(t) -> void:
 var returns=phase_branch_returns()
 var labels=phase_facts_labels()
 var declared=PHASE_BRANCH_VOCABULARY
 var missing=declared.filter(func(name):return name not in returns)
 var extra=returns.filter(func(name):return name not in declared)
 t.check(missing.is_empty() and extra.is_empty(),"K0 phase_branch_vocabulary_is_total: every declared branch id is returned by _phase_branch and nothing else is (missing="+str(missing)+" extra="+str(extra)+")")
 var missing_labels=declared.filter(func(name):return name not in labels)
 var extra_labels=labels.filter(func(name):return name not in declared)
 t.check(missing_labels.is_empty() and extra_labels.is_empty(),"K0 phase_branch_vocabulary_is_total: _phase_facts keeps exactly one return point per declared branch (missing="+str(missing_labels)+" extra="+str(extra_labels)+")")
 t.check(returns.size()==declared.size() and labels.size()==declared.size(),"K0 phase_branch_vocabulary_is_total: no branch id is declared, returned or listed twice (returns="+str(returns.size())+" labels="+str(labels.size())+" declared="+str(declared.size())+")")
 var facts_body=source_func_body_code("res://core/game.gd","_phase_facts")
 t.check(facts_body.find("_phase_branch(")>=0 and facts_body.find("if ")<0 and facts_body.find("append")<0,"K0 phase_branch_vocabulary_is_total: _phase_facts decides branches only through _phase_branch (no second condition chain and no append point in its body): if="+str(facts_body.find("if "))+" append="+str(facts_body.find("append")))
 var branch_body=source_func_body_code("res://core/game.gd","_phase_branch")
 var assignment=RegEx.new()
 var assignment_ok=assignment.compile("(?<![=!<>])=(?!=)")==OK
 t.check(not branch_body.strip_edges().is_empty() and assignment_ok and assignment.search(branch_body)==null,"K0 phase_branch_vocabulary_is_total: _phase_branch is read-only (no assignment in its body)")
 print("PHASE BRANCH VOCABULARY declared=%d returns=%d labels=%d" % [declared.size(),returns.size(),labels.size()])

# 单元表的登记侧副本（被测实现；期望侧是上面的字面表）。
static func fact_units_declared() -> Array:
 var out=[]
 for unit in CommandRegistry.FACT_UNITS:
  out.append({"id":String(unit.get("id","")),"order":int(unit.get("order",0)),"owner":String(unit.get("owner","")),"producer":String(unit.get("producer","")),"groups":unit.get("groups",[]),"input":String(unit.get("input",""))})
 return out

static func fact_units_by_owner() -> Dictionary:
 var out={}
 for unit in fact_units_declared():
  var owner=String(unit.owner)
  if not out.has(owner): out[owner]=[]
  out[owner].append(unit)
 return out

# 单元观测夹具（K1 组列与连接等价）：26 cell（含 shop／treasure／event／prison 相位）＋ 相位扫描（含三个前缀状态）
# ＋ 六处状态标志。每个条目＝{"label":..., "game":..., "phase_join":bool}；domain_blocked 条目只做 _fact_source 面
# （单元表对它是空表；其相位面落回尾段，组列无单元须覆盖，见 PHASE_EMPTY_BRANCHES 与单元表注释）。
static func fact_unit_enrich(g) -> void:
 # 覆盖 item／flask／status_toggle／item_discard 组列的状态垫片（不改规则，只改夹具输入）。
 g.state.items.append({"id":"item_probe","type":"mana_potion","uses":1,"mount":"carry"})
 g.state.items.append({"id":"tool_probe","type":"saw","uses":2,"mount":"hand_wall"})
 g.state.flask_mana=40.0
 g.state.charge=2

static func fact_unit_states() -> Array:
 var out=[]
 for cell in r1_cells():
  out.append({"label":"cell:%s:%d" % [cell[0],cell[1]],"game":r1_build(cell[0],cell[1]),"phase_join":true})
 out.append_array(branch_sweep_states())
 return out

# 相位 × 前缀扫描 ＋ 六个状态标志分支（B 批的等价 harness 与冻结矩阵、A 批的组列观测共用这一份声明：
# 一处声明，两个判据消费；条目＝{"label","game","phase_join"}，domain_blocked 只做 _fact_source 面）。
static func branch_sweep_states(game_class=null) -> Array:
 var out=[]
 for phase in ["departure","rest_choice","reward","map","travel","cleared","pack","prison_end","captured","inspection","battle","prepare","rest"]:
  for variant in ["plain","relic_bundle","departure","domain_blocked"]:
   var g=r1_build("battle",0,game_class)
   fact_unit_enrich(g)
   match variant:
    "relic_bundle": preload("res://core/relic_bundle.gd").start(g,"reward")
    "departure": preload("res://core/departure.gd").start(g)
    # domain_blocked：同一种性玩具重复佩戴使 SpecialEquipment.validate 非空 ⇒ command_domain_ready() 为假
    # （B 批起本夹具也走 command_facts()，故实例必须带 id——action_targets() 的 id 边要求每个目标有 id）。
    # 记录完整（正式安装工厂＋重复家族）：门控关掉时本级的 command_facts 面照常构建，不会命中未登记类型的
    # TYPES 直取或缺 durability 的 worn_count（旧的 no_such_special 占位只在门控开时安全，故换掉）。
    "domain_blocked":
     g._install_special("shaft_ring_low","special_2_a")
     var twin=g.state.special_equipment[0].duplicate(true)
     twin.id="special_9_z"
     g.state.special_equipment.append(twin)
   if phase=="departure" and g.state.departure.is_empty(): preload("res://core/departure.gd").start(g)
   g.state.phase=phase
   if phase=="travel":
    var ids=g.state.rooms.map(func(room):return String(room.id))
    g.state.journey={"from":String(g.state.room),"target":String(ids[0]),"total":2,"remaining":2,"speed":1,"mode":"步行"}
   if phase=="inspection": g.state.prison={"stage":"arrival"}
   out.append({"label":"sweep:%s|%s" % [phase,variant],"game":g,"phase_join":variant!="domain_blocked"})
 var overloaded=r1_build("battle",0,game_class)
 fact_unit_enrich(overloaded)
 overloaded.state.overloaded=true
 out.append({"label":"flag:overload_climax","game":overloaded,"phase_join":true})
 var retain=r1_build("battle",0,game_class)
 fact_unit_enrich(retain)
 retain.state.pending_retain=true
 out.append({"label":"flag:pending_retain","game":retain,"phase_join":true})
 var spell=r1_build("battle",12,game_class)
 fact_unit_enrich(spell)
 spell.state.card_buffs.append("flame_flourish_bound")
 out.append({"label":"flag:equipment_spell","game":spell,"phase_join":true})
 var rest_hook=r1_build("rest",0,game_class)
 fact_unit_enrich(rest_hook)
 rest_hook.state.hook_uses=3
 out.append({"label":"flag:hook","game":rest_hook,"phase_join":true})
 var demo=r1_build("battle",0,game_class)
 fact_unit_enrich(demo)
 demo.room_data(demo.state.room).kind="exit"
 demo.state.phase="cleared"
 out.append({"label":"flag:demo_exit","game":demo,"phase_join":true})
 var chain_g=r1_build("battle",12,game_class)
 fact_unit_enrich(chain_g)
 chain_g.state.card_chain={"type":"unlock","slot":"","remaining":1,"mode":"unlock","free":false}
 out.append({"label":"flag:card_chain","game":chain_g,"phase_join":true})
 var rest_card=r1_build("rest",0,game_class)
 fact_unit_enrich(rest_card)
 rest_card.state.phase="rest_choice"
 rest_card.state.rest_cards=["focus"]
 out.append({"label":"flag:rest_card","game":rest_card,"phase_join":true})
 var reward_skip=r1_build("battle",0,game_class)
 fact_unit_enrich(reward_skip)
 reward_skip.state.phase="reward"
 reward_skip.state.reward_options=["focus"]
 out.append({"label":"flag:reward_skip","game":reward_skip,"phase_join":true})
 var relic_rows=r1_build("battle",12,game_class)
 fact_unit_enrich(relic_rows)
 relic_rows.state.relics.append("great_wand")
 relic_rows.state.relics.append("doubao")
 out.append({"label":"flag:relic_rows","game":relic_rows,"phase_join":true})
 # 前缀分支带装备的两态：前缀分支只跑三／一个前缀单元，而臂的守卫若被写坏（漏了前缀排除）在有目标时会多产行——
 # 这一对夹具是「域臂行集 ⊆ 表行集」这一层的唯一触发面（其余前缀态没有装备目标）。
 var relics_equipped=r1_build("battle",12,game_class)
 fact_unit_enrich(relics_equipped)
 preload("res://core/relic_bundle.gd").start(relics_equipped,"reward")
 out.append({"label":"flag:relic_bundle_equipped","game":relics_equipped,"phase_join":true})
 var departure_equipped=r1_build("battle",12,game_class)
 fact_unit_enrich(departure_equipped)
 preload("res://core/departure.gd").start(departure_equipped)
 departure_equipped.state.phase="departure"
 out.append({"label":"flag:departure_equipped","game":departure_equipped,"phase_join":true})
 return out

# 测试侧连接重放（与 core/game.gd::_join_fact_units 同一通道语义：按表序调每个 producer，累积表前传）。
static func fact_unit_replay(g, units: Array, observed: Dictionary) -> Array:
 var facts: Array=[]
 for unit in units:
  var id=String(unit.get("id",""))
  var rows=g.call(String(unit.get("producer","")),facts)
  if not observed.has(id): observed[id]={}
  for row in rows: observed[id][String(row.get("group",""))]=true
  facts.append_array(rows)
 return facts

# C-A-1（K1；gherkin A-1；acceptance.md §1 A 段）：单元表 ↔ 本文件字面期望（owner 序／id／producer／input／order）
# 与空表分支双向全量；生产者都在 g 上存在；连接通道唯一（源码文本）；每单元 input 指向同 owner 更早的单元；
# 组列与实测行 group 值域双向一致；测试侧重放与 _fact_source／_phase_facts 逐字节相等。
static func fact_units_cover_fact_source(t) -> void:
 var declared=fact_units_by_owner()
 var missing=[]
 var extra=[]
 for owner in FACT_UNIT_EXPECTATION:
  var want=FACT_UNIT_EXPECTATION[owner]
  var have=declared.get(owner,[])
  for index in range(want.size()):
   var row=want[index]
   if index>=have.size():
    missing.append(owner+":"+String(row[0]))
    continue
   var unit=have[index]
   if String(unit.id)!=String(row[0]) or String(unit.producer)!=String(row[1]) or String(unit.input)!=String(row[2]):
    missing.append(owner+":"+String(row[0])+" want="+str(row)+" have=["+String(unit.id)+","+String(unit.producer)+","+String(unit.input)+"]")
  for index in range(want.size(),have.size()): extra.append(owner+":"+String(have[index].id))
 for owner in declared:
  if not FACT_UNIT_EXPECTATION.has(owner): extra.append("owner:"+owner)
 var empty_extra=PHASE_EMPTY_BRANCHES.filter(func(branch):return declared.has(branch))
 var undeclared=PHASE_BRANCH_VOCABULARY.filter(func(branch):return not declared.has(branch) and branch not in PHASE_EMPTY_BRANCHES and branch not in FACT_SOURCE_PREFIX_BRANCHES)
 t.check(missing.is_empty() and extra.is_empty() and empty_extra.is_empty() and undeclared.is_empty(),"K1 fact_units_cover_fact_source: the declared unit table is two-way total against the literal expectation (missing="+str(missing)+" extra="+str(extra)+" empty_extra="+str(empty_extra)+" undeclared_branch="+str(undeclared)+")")
 t.check(CommandRegistry.FACT_PREFIX_OWNERS==FACT_SOURCE_PREFIX_BRANCHES,"K1 fact_units_cover_fact_source: the registry prefix-owner vocabulary equals the literal expectation: "+str(CommandRegistry.FACT_PREFIX_OWNERS))
 var order_problems=[]
 var input_problems=[]
 var producers=[]
 for owner in declared:
  var seen={}
  for index in range(declared[owner].size()):
   var unit=declared[owner][index]
   producers.append(String(unit.producer))
   if int(unit.order)!=index+1: order_problems.append(owner+":"+String(unit.id)+"="+str(unit.order))
   if String(unit.input)!="" and not seen.has(String(unit.input)): input_problems.append(owner+":"+String(unit.id)+"<-"+String(unit.input))
   seen[String(unit.id)]=true
 t.check(order_problems.is_empty(),"K1 fact_units_cover_fact_source: the order column is the unit's position in its owner sequence (1..N, no gaps): "+str(order_problems))
 t.check(input_problems.is_empty(),"K1 fact_units_cover_fact_source: every input names an earlier unit of the same owner (accumulated-table prerequisites are explicit): "+str(input_problems))
 var probe=GameCore.new(42)
 var bad_producers=producers.filter(func(name):return name.is_empty() or not probe.has_method(name))
 var bad_groups=[]
 for unit in fact_units_declared():
  if not (unit.groups is Array) or unit.groups.is_empty(): bad_groups.append(String(unit.id))
 t.check(bad_producers.is_empty(),"K1 fact_units_cover_fact_source: every declared producer exists on g: "+str(bad_producers))
 t.check(bad_groups.is_empty(),"K1 fact_units_cover_fact_source: every unit declares a non-empty group set: "+str(bad_groups))
 # 连接通道唯一（源码文本）：_fact_source 只有一次连接；_phase_facts 的每条臂都经 _phase_branch_units；连接通道内
 # 不出现任何 producer 名（表外第二处追加点／第二份条件链即红）。
 var source_body=source_func_body_code("res://core/game.gd","_fact_source")
 var phase_body=source_func_body_code("res://core/game.gd","_phase_facts")
 var join_body=source_func_body_code("res://core/game.gd","_join_fact_units")
 var bad_source=[]
 if pipeline_lookup_call_count(source_body,"_join_fact_units")!=1: bad_source.append("_fact_source:join="+str(pipeline_lookup_call_count(source_body,"_join_fact_units")))
 if source_body.find("CommandRegistry.fact_source_units(")<0 or source_body.find("_phase_branch()")<0 or source_body.find("if ")>=0: bad_source.append("_fact_source:no-single-table-join")
 var arms=0
 var arm_problems=[]
 for line in phase_body.split("\n"):
  var text=String(line)
  if not text.strip_edges().begins_with("\""): continue
  arms+=1
  if text.find("return _phase_branch_units(")<0: arm_problems.append(text.strip_edges())
 if arms!=PHASE_FACTS_ARMS or not arm_problems.is_empty(): bad_source.append("_phase_facts:arms="+str(arms)+" "+str(arm_problems.slice(0,2)))
 if pipeline_lookup_call_count(phase_body,"_phase_branch")!=1: bad_source.append("_phase_facts:branch="+str(pipeline_lookup_call_count(phase_body,"_phase_branch")))
 if pipeline_lookup_call_count(join_body,"call")!=1 or pipeline_lookup_call_count(join_body,"append_array")!=1: bad_source.append("join:shape")
 for name in producers:
  if join_body.find(name)>=0: bad_source.append("join:producer "+name)
 t.check(bad_source.is_empty(),"K1 fact_units_cover_fact_source: the table join is the only append path (source text): "+str(bad_source))
 # 运行期：测试侧重放与两个入口逐字节相等；逐单元观测 group 值域。
 var observed={}
 var join_problems=[]
 var compared=0
 for entry in fact_unit_states():
  var label=String(entry.label)
  var g=entry.game
  var branch=g._phase_branch()
  var units=CommandRegistry.fact_source_units(branch)
  if JSON.stringify(fact_unit_replay(g,units,observed))!=JSON.stringify(g._fact_source()): join_problems.append(label+":fact_source")
  if bool(entry.phase_join):
   var phase_branch=branch
   if phase_branch in ["relic_bundle","departure","domain_blocked"]: phase_branch="action_tail"
   if JSON.stringify(fact_unit_replay(g,CommandRegistry.phase_units(phase_branch),observed))!=JSON.stringify(g._phase_facts()): join_problems.append(label+":phase_facts")
  compared+=1
 t.check(join_problems.is_empty(),"K1 fact_units_cover_fact_source: the declared units replay byte-for-byte into _fact_source and _phase_facts on every fixture: "+str(join_problems.slice(0,4)))
 t.check(compared>=60,"K1 fact_units_cover_fact_source: the fixture matrix covered the unit table (coverage floor): "+str(compared))
 var group_problems=[]
 var coverage_report=[]
 for unit in fact_units_declared():
  var id=String(unit.id)
  var seen_groups=observed.get(id,{})
  var declared_groups=unit.groups
  for group in seen_groups:
   if group not in declared_groups: group_problems.append(id+": undeclared observed group "+String(group))
  var unobserved=declared_groups.filter(func(group):return not seen_groups.has(group))
  coverage_report.append(id+"="+str(declared_groups)+" observed="+str(seen_groups.keys())+" unobserved="+str(unobserved))
  for group in unobserved:
   if id+":"+String(group) not in FACT_UNIT_GROUP_UNCOVERED: group_problems.append(id+": declared but never observed "+String(group))
 for pair in FACT_UNIT_GROUP_UNCOVERED:
  var parts=String(pair).split(":")
  var declared_pair=[]
  for unit in fact_units_declared():
   if String(unit.id)==parts[0]: declared_pair=unit.groups
  var seen_pair=observed.get(parts[0],{})
  if parts.size()!=2 or parts[1] not in declared_pair or seen_pair.has(parts[1]): group_problems.append("stale uncovered entry "+String(pair))
 t.check(group_problems.is_empty(),"K1 fact_units_cover_fact_source: every unit's declared group set equals the observed row group range (two-way): "+str(group_problems))
 print("FACT UNITS declared=%d states=%d uncovered=%s" % [fact_units_declared().size(),compared,str(FACT_UNIT_GROUP_UNCOVERED)])
 for line in coverage_report: print("FACT UNIT GROUPS "+String(line))

# C-A-3／C-E-1／C-F-6: masks retain historical PRE except R3's sole declared append, proved reversibly below.
# 动工前值冻结在**独立文件** tests/frozen-baselines.json（A 批审查缺口 4：前值不得与被校验常量同文件，否则
# 「同步改常量＋同步改前值」能白名单化）。R5_BASELINE 在 E 批按已声明重冻了两个字段面（submit_keys／派生
# <record>，C-E-7），故它不在此比对，由 tests/architecture_cases.gd::baseline_diff_is_declared 双向核对。
static func baseline_constants_are_unchanged(t) -> void:
 var frozen_digests=frozen_baselines().get("baseline_pre_digests",{})
 t.check(frozen_digests is Dictionary and not (frozen_digests as Dictionary).is_empty(),"G1 baseline_constants_are_unchanged: the frozen pre-batch digests live in the external file "+FROZEN_BASELINES_JSON)
 # F: preserve the external historical PRE; prove the sole authorized append in both directions.
 var pre=["display_facts"]
 var addition=["display_fact_scope"]
 var post=pre.duplicate()
 post.append_array(addition)
 var inverse=R3_VIEW_MASK.filter(func(key):return key not in addition)
 var historical=String(frozen_digests.get("R3_VIEW_MASK",""))
 t.check(R3_VIEW_MASK==post,"F6 baseline_constants_are_unchanged: POST is exactly independent PRE plus the unique declared append, without deletion, reordering or duplicates")
 t.check(r1_digest(JSON.stringify(pre))==historical and r1_digest(JSON.stringify(inverse))==historical,"F6 baseline_constants_are_unchanged: independent PRE and reverse-removal of the sole append reproduce the unmodified external historical digest")
 var pairs=[["R3_VIEW_MASK",JSON.stringify(inverse)],["R5_VIEW_MASK",JSON.stringify(R5_VIEW_MASK)],["R5_RECORD_MASK",JSON.stringify(R5_RECORD_MASK)],["R5_RECORD_ADDED",JSON.stringify(R5_RECORD_ADDED)],["R5_RECOMPUTED",JSON.stringify(R5_RECOMPUTED)]]
 var moved=[]
 var missing=[]
 for pair in pairs:
  var want=String((frozen_digests as Dictionary).get(String(pair[0]),""))
  if want=="": missing.append(String(pair[0]))
  elif r1_digest(String(pair[1]))!=want: moved.append(String(pair[0]))
 t.check(missing.is_empty(),"G1 baseline_constants_are_unchanged: every frozen constant has its pre-batch digest in the external file: "+str(missing))
 t.check(moved.is_empty(),"G1 baseline_constants_are_unchanged: the mask constants keep the frozen pre-batch digest (a move is a rebaseline, never a silent edit): "+str(moved))
 t.check(r1_digest(JSON.stringify(["a"]))!=r1_digest(JSON.stringify(["b"])),"G1 baseline_constants_are_unchanged: the frozen-digest comparison is sensitive to a value change")
 print("BASELINE CONSTANTS FROZEN pairs=%d source=%s" % [pairs.size(),FROZEN_BASELINES_JSON])

# 组全集（测试内字面期望）：需求闭包的「全组」取值；双向等于 core/command_registry.gd::FACT_UNITS 的组列并集。
const E_FACT_GROUPS=["attack","card","chain","demo_exit","event","flask","flow","hook","item","manual","posture","pressure","prison","relic","rest_service","retain","reward","route","service","service_flow","service_refresh","service_release","service_remove","status_toggle","surrender","wall_move"]
# 投影承接组（测试内字面期望）：core/game_view.gd::build 除 display_facts／display_fact_scope 外的键消费的组，
# 即需求闭包下限（core/command_registry.gd::VIEW_FACT_GROUPS）。
const E_VIEW_FACT_GROUPS=["card","event","flow","item","manual","posture","prison","rest_service","reward","route","service","service_flow","service_refresh","service_release","service_remove"]
# 需求画像矩阵（字面需求 → 期望闭包＝需求 ∪ 承接组）：全组是它的普通取值之一（不是特权路径）。
const E_DEMAND_PROFILES=[
 ["full",E_FACT_GROUPS],
 ["drawers_closed",["item","service","service_flow"]],
 ["relics_open",["relic","reward"]],
 ["body_details",["manual","attack","card","posture","pressure"]],
 ["route_only",["route","flow","event"]],
]
# 成功结果键面（E-6；字面表，含顺序）。S5 的旧键面 S5_SUBMIT_KEYS_AFTER 与其自证常量保留不动（历史冻结，
# tests/architecture_cases.gd::submit_key_face_rebaseline_self_proof 常驻核）。
const E_SUBMIT_KEYS=["ok","version","resource_feedback","card_feedback","music_feedback","checkpoint","spell_failed","fact","phase","overloaded"]
# 战斗相位词表（测试内字面期望）：guarded 过载态＝state.overloaded ∧ phase ∈ 本表（core/game.gd::dispatch 的
# overloaded 必须与它同值——这条期望不取自实现）。
const E_COMBAT_PHASES=["battle","prepare","rest","prison"]
# C-E-7 的声明差异集（G-2 第 2 步；逐 cell 逐字段一条原因）：原因只有一类——已声明的新增键 ⇒ submit_keys
# （＝result.keys() 摘要）变更 ⇒ 由它派生的 <record> 摘要随之变更。表外任何差异＝红（尤其 view／facts_text／
# view_display_facts 任一移动）。
const E_SUBMIT_KEYS_REASON="已声明的新增键：dispatch 成功结果追加 phase／overloaded（K7；C-E-6）⇒ submit_keys 变更 ⇒ 派生 <record> 变更"
const E_DECLARED_DIFF={
 "battle:0":{"record":E_SUBMIT_KEYS_REASON},
 "battle:12":{"record":E_SUBMIT_KEYS_REASON},
 "battle:26":{"record":E_SUBMIT_KEYS_REASON},
 "battle:44":{"record":E_SUBMIT_KEYS_REASON},
 "prepare:0":{"record":E_SUBMIT_KEYS_REASON},
 "prepare:12":{"record":E_SUBMIT_KEYS_REASON},
 "prepare:26":{"record":E_SUBMIT_KEYS_REASON},
 "prepare:44":{"record":E_SUBMIT_KEYS_REASON},
 "rest:0":{"record":E_SUBMIT_KEYS_REASON},
 "rest:12":{"record":E_SUBMIT_KEYS_REASON},
 "rest:26":{"record":E_SUBMIT_KEYS_REASON},
 "rest:44":{"record":E_SUBMIT_KEYS_REASON},
 "shop:0":{"record":E_SUBMIT_KEYS_REASON},
 "shop:12":{"record":E_SUBMIT_KEYS_REASON},
 "shop:26":{"record":E_SUBMIT_KEYS_REASON},
 "shop:44":{"record":E_SUBMIT_KEYS_REASON},
 "event:0":{"record":E_SUBMIT_KEYS_REASON},
 "event:12":{"record":E_SUBMIT_KEYS_REASON},
 "event:26":{"record":E_SUBMIT_KEYS_REASON},
 "event:44":{"record":E_SUBMIT_KEYS_REASON},
 "prison:0":{"record":E_SUBMIT_KEYS_REASON},
 "prison:12":{"record":E_SUBMIT_KEYS_REASON},
 "prison:26":{"record":E_SUBMIT_KEYS_REASON},
 "prison:44":{"record":E_SUBMIT_KEYS_REASON},
 "takeover:0":{"record":E_SUBMIT_KEYS_REASON},
 "takeover:12":{"record":E_SUBMIT_KEYS_REASON},
}

# 期望闭包（由测试内字面表推导，不取自被测闭包实现）：demand ∪ 投影承接组，排序去重。
static func e_expected_scope(demand: Array) -> Array:
 var scope=[]
 for group in E_VIEW_FACT_GROUPS:
  if String(group) not in scope: scope.append(String(group))
 for group in demand:
  if String(group) not in scope: scope.append(String(group))
 scope.sort()
 return scope

static func e_row_groups(rows: Array) -> Array:
 var seen={}
 for row in rows: seen[String(row.get("group",""))]=true
 var out=seen.keys()
 out.sort()
 return out

# 入口守卫（design.md §K4 需求值一览表；C-E-5 单独钉住）：接管／card_chain／pending_retain ⇒ 需求＝全组
# （这三支可在提交内由无变有，调用方在 get_view 之前预知不到）。矩阵的期望侧据此取全组。
static func e_demand_forced_full(g) -> bool:
 return g.FirstTurnControl.active(g) or not g.state.card_chain.is_empty() or g.state.pending_retain

# 画像矩阵 × 一个夹具：行面（纯子序列）／scope 面（与行面双向一致）／值面（LPI）。期望侧＝同一实例的全组构建
# 行（不新建 Game；acceptance.md §3.4 的第二对照）。返回本轮比对的画像数，并累加被比较字段的覆盖计数。
static func e_profile_matrix(g, label: String, row_problems: Array, scope_problems: Array, value_problems: Array, coverage: Dictionary) -> int:
 var full=g.get_view()
 var full_rows=full.display_facts
 var full_groups=e_row_groups(full_rows)
 var forced=e_demand_forced_full(g)
 var full_face={}
 for key in full.keys():
  if key in ["display_facts","display_fact_scope"]: continue
  full_face[key]=full[key]
 var reachable=false
 for card in full.hand:
  if not card.availability.is_empty(): reachable=true
 if reachable: coverage["hand"]=int(coverage["hand"])+1
 reachable=false
 for item in full.items:
  if not item.get("target_groups",[]).is_empty(): reachable=true
 if reachable: coverage["items"]=int(coverage["items"])+1
 reachable=false
 for body in full.body_groups:
  if bool(body.get("can_release",false)): reachable=true
 if reachable: coverage["bodies"]=int(coverage["bodies"])+1
 if not full.route.is_empty(): coverage["route"]=int(coverage["route"])+1
 if not full.reward_panel.get("rows",[]).is_empty(): coverage["reward"]=int(coverage["reward"])+1
 if not full.card_texts.is_empty(): coverage["texts"]=int(coverage["texts"])+1
 for profile in E_DEMAND_PROFILES:
  var name=String(profile[0])
  var demand=profile[1]
  var cut=g.get_view(demand)
  var scope=E_FACT_GROUPS.duplicate() if forced else e_expected_scope(demand)
  var wanted=[]
  for row in full_rows:
   if String(row.get("group","")) in scope: wanted.append(row)
  if JSON.stringify(cut.display_facts)!=JSON.stringify(wanted): row_problems.append(label+"@"+name+": display_facts is not the declared subsequence of the full rows")
  var expected_scope=full_groups.filter(func(group):return group in scope)
  if JSON.stringify(cut.display_fact_scope)!=JSON.stringify(expected_scope) or JSON.stringify(e_row_groups(cut.display_facts))!=JSON.stringify(cut.display_fact_scope):
   scope_problems.append(label+"@"+name+": scope="+str(cut.display_fact_scope)+" declared="+str(expected_scope))
  var cut_face={}
  for key in cut.keys():
   if key in ["display_facts","display_fact_scope"]: continue
   cut_face[key]=cut[key]
  if JSON.stringify(full_face)!=JSON.stringify(cut_face):
   for key in full_face:
    if JSON.stringify(full_face[key])!=JSON.stringify(cut_face[key]): value_problems.append(label+"@"+name+"."+String(key))
 return E_DEMAND_PROFILES.size()

# C-E-1（gherkin E-1；acceptance.md §1 E 段）：缺省（无参）路径逐字节不变——无参 == 显式全组（同一语义、同一条
# 路径）；display_fact_scope 在每个 cell 都在；mask 常量与 R5_BASELINE 的其余字段分别由
# baseline_constants_are_unchanged／baseline_diff_is_declared 核对。敏感性：把缺省也裁剪 → 两次调用不等。
static func default_projection_is_unchanged(t) -> void:
 var problems=[]
 var scope_missing=[]
 var key_problems=[]
 var pre_keys=R3_VIEW_KEYS_BASE.filter(func(key):return key not in R5_VIEW_MASK)
 pre_keys.append("display_facts")
 var entry_keys=pre_keys.duplicate()
 entry_keys.append("display_fact_scope")
 var compared=0
 for cell in r1_cells():
  var key="%s:%d" % [cell[0],cell[1]]
  var g=r1_build(cell[0],cell[1])
  var plain=g.get_view()
  var explicit=g.get_view(E_FACT_GROUPS)
  if JSON.stringify(plain)!=JSON.stringify(explicit): problems.append(key+": default != explicit full group")
  if not plain.has("display_fact_scope"): scope_missing.append(key)
  var keys=plain.keys()
  var cumulative_added=keys.filter(func(name):return name not in pre_keys)
  var cumulative_removed=pre_keys.filter(func(name):return name not in keys)
  var incremental_added=keys.filter(func(name):return name not in entry_keys)
  var incremental_removed=entry_keys.filter(func(name):return name not in keys)
  if cumulative_added!=["display_fact_scope"] or not cumulative_removed.is_empty() or not incremental_added.is_empty() or not incremental_removed.is_empty():
   key_problems.append(key+" cumulative="+str(cumulative_added)+"/"+str(cumulative_removed)+" F-entry="+str(incremental_added)+"/"+str(incremental_removed))
  compared+=1
 t.check(problems.is_empty(),"K4 default_projection_is_unchanged: the no-argument projection equals the explicit full-group projection byte for byte: "+str(problems.slice(0,3)))
 t.check(scope_missing.is_empty() and compared==r1_cells().size(),"K4 default_projection_is_unchanged: every frozen cell carries the one new view key display_fact_scope: "+str(scope_missing))
 t.check(key_problems.is_empty(),"F6 default_projection_is_unchanged: cumulative added=[display_fact_scope]/removed=[] and F relative to 32ca5bb added=[]/removed=[] from independent literal key faces: "+str(key_problems.slice(0,3)))
 var params=source_func_params("res://core/game.gd","get_view")
 t.check(params==["demand"],"K4 default_projection_is_unchanged: core/game.gd::get_view takes exactly one demand parameter (default [] = full group; UI demand values are pinned by the F call-site check): "+str(params))
 print("E DEFAULT PROJECTION cells=%d" % compared)

# C-E-2／C-E-3（gherkin E-2／E-3；acceptance.md §1 E 段与 §3.4／§3.5）：行面＝纯子序列（逐行逐字节、顺序一致、
# 无增无减）；display_fact_scope 与行面双向一致；除 display_facts／display_fact_scope 外每个 View 键与全组构建
# 逐字节相等（LPI）。本判据不新建 Game：期望侧取自同状态的全组构建。覆盖＝26 cell ＋ 配方 60 提交
# （seed 7／cap 60／style trade，与 tests/recipe_driver.gd 同一策略与种子）。
static func lazy_projection_invariant(t) -> void:
 var row_problems=[]
 var scope_problems=[]
 var value_problems=[]
 var coverage={"hand":0,"items":0,"bodies":0,"route":0,"reward":0,"texts":0}
 var compared=0
 for cell in r1_cells():
  compared+=e_profile_matrix(r1_build(cell[0],cell[1]),"%s:%d" % [cell[0],cell[1]],row_problems,scope_problems,value_problems,coverage)
 # 覆盖夹具（两条，逐条给出被覆盖的字段；字段无值即上面的覆盖断言红）：可用的 item_use 行（items[] 目标组）
 # 与可解开的普通装备（body_groups[].can_release）都不在 26 cell 的默认装备状态里。
 var item_fixture=r1_build("battle",0)
 fact_unit_enrich(item_fixture)
 item_fixture.state.mana=0
 compared+=e_profile_matrix(item_fixture,"coverage:items",row_problems,scope_problems,value_problems,coverage)
 var release_fixture=r1_build("battle",0)
 release_fixture.add_fixture("thigh",4)
 compared+=e_profile_matrix(release_fixture,"coverage:release",row_problems,scope_problems,value_problems,coverage)
 # C-F-9 前缀态夹具（修复批 G8：F_PREFIX_PROFILES 是前缀夹具运行的唯一驱动，循环按声明表迭代并
 # 记录实际执行集，执行集／声明集双向对账；配方偶遇不再作为前缀态的覆盖来源）：累积表去重变弱
 # 一类纯子序列偏差只在前缀态可达——登记前缀态 × E_DEMAND_PROFILES 全部画像，行面／值面／
 # display_fact_scope 三方互核同上。夹具取 View 可重放的形态：nesting_doll 套娃包（source 必须是
 # 实持遗物，panel 直取 TYPES[source]）；空躯干固缚记录使 Binding.state_issue 非空 ⇒
 # command_domain_ready()==false，而 present() 对空记录为假，View 构建无错误）。
 var prefix_declared=[]
 var prefix_profiles={}
 for profile in F_PREFIX_PROFILES:
  var label=String(profile[0])
  var kind=String(profile[1])
  prefix_declared.append(label)
  var fixture=r1_build("battle",0)
  fact_unit_enrich(fixture)
  if kind=="relic_bundle":
   fixture.state.relics.append("nesting_doll")
   preload("res://core/relic_bundle.gd").start(fixture,"nesting_doll")
  elif kind=="domain_blocked":
   fixture.add_fixture("wrist",4)
   fixture.state.equipment[0].binding={}
  var active: bool=false
  if kind=="relic_bundle": active=not fixture.state.relic_bundle.is_empty() and fixture._phase_branch()==kind
  elif kind=="domain_blocked": active=not fixture.command_domain_ready() and fixture._phase_branch()==kind
  t.check(active,"K4 lazy_projection_invariant: the registered "+label+" prefix is actually active before every declared demand profile")
  if not active: continue
  prefix_profiles[label]=e_profile_matrix(fixture,label,row_problems,scope_problems,value_problems,coverage)
  compared+=int(prefix_profiles[label])
 # 执行集／声明集双向对账：登记未实现（声明 ⊃ 执行）与未登记实现（执行 ⊃ 声明）都红；
 # 每个登记前缀还必须真的跑满 E_DEMAND_PROFILES 全部画像。
 var prefix_missing=prefix_declared.filter(func(label):return not prefix_profiles.has(label))
 var prefix_extra=prefix_profiles.keys().filter(func(label):return label not in prefix_declared)
 var prefix_counts_ok=true
 for label in prefix_declared:
  if int(prefix_profiles.get(label,0))!=E_DEMAND_PROFILES.size(): prefix_counts_ok=false
 t.check(prefix_missing.is_empty() and prefix_extra.is_empty() and prefix_counts_ok,"K4 lazy_projection_invariant: the executed prefix fixtures and the F_PREFIX_PROFILES registration agree both ways and every registered prefix ran every demand profile: missing="+str(prefix_missing)+" extra="+str(prefix_extra))
 var live=Game.new(7)
 var navigation={}
 var commits=0
 var steps=0
 var stop_reason="cap"
 var phases=[]
 while commits<60 and steps<900:
  steps+=1
  var probe=live.get_view()
  var phase=String(probe.phase)
  if not phases.has(phase): phases.append(phase)
  if phase in ["cleared","prison_end"]:
   stop_reason="end_phase:"+phase
   break
  var choice=NormalPlay.choose(probe,"trade",navigation)
  if choice.is_empty():
   stop_reason="no_legal_step"
   break
  var result=live.dispatch(live.command(choice.payload,live.state.version),live.state.version)
  if not result.ok: continue
  commits+=1
  NormalPlay.remember(probe,choice,navigation)
  compared+=e_profile_matrix(live,"recipe:"+str(commits),row_problems,scope_problems,value_problems,coverage)
 t.check(row_problems.is_empty(),"K4 lazy_projection_invariant: every display_facts is exactly the full row list filtered by the declared closure (byte for byte, order kept): "+str(row_problems.slice(0,3)))
 t.check(scope_problems.is_empty(),"K4 lazy_projection_invariant: display_fact_scope equals the declared closure restricted to the observed row groups and equals the row face group range: "+str(scope_problems.slice(0,3)))
 t.check(value_problems.is_empty(),"K4 lazy_projection_invariant: apart from display_facts and display_fact_scope every view key equals the full-group build (LPI): "+str(value_problems.slice(0,3)))
 var uncovered=coverage.keys().filter(func(key):return int(coverage[key])==0)
 t.check(uncovered.is_empty(),"K4 lazy_projection_invariant: the compared cells cover the fact-fed view fields (the comparison is not vacuous): uncovered="+str(uncovered)+" coverage="+str(coverage))
 t.check(commits==60 and stop_reason=="cap","K4 lazy_projection_invariant: the declared recipe committed 60 times before its natural end have="+str(commits)+" stop="+stop_reason)
 print("E LAZY PROFILES compared=%d commits=%d prefix=%d coverage=%s phases=%s" % [compared,commits,F_PREFIX_PROFILES.size(),str(coverage),str(phases)])

# C-E-4（gherkin E-4；acceptance.md §1 E 段）：组清点双向全量——build 实际产出的行 group 值域 == 声明组全集，
# 且（同一词汇表的第二面）等于单元表的组列并集；每个声明组都能被至少一个单元覆盖。行面取表出口
# core/game.gd::command_facts（＝core/game_view.gd::build 取的那张表；前缀扫描态上 View 的奖励面板另有
# §K1 实测残差，不在本判据的域内）。敏感性：某单元少声明一个组（行仍在）或声明一个不存在的组 → 双向红。
static func fact_groups_are_total(t) -> void:
 var observed={}
 var states=fact_unit_states()
 for entry in states:
  for row in entry.game.command_facts(): observed[String(row.get("group",""))]=true
 var seen=observed.keys()
 seen.sort()
 var declared=E_FACT_GROUPS.duplicate()
 declared.sort()
 var registry=CommandRegistry.fact_groups()
 registry.sort()
 var missing=declared.filter(func(group):return group not in seen)
 var extra=seen.filter(func(group):return group not in declared)
 t.check(missing.is_empty() and extra.is_empty(),"K4 fact_groups_are_total: the observed row group range equals the declared group universe (two-way): missing="+str(missing)+" extra="+str(extra))
 t.check(registry==declared,"K4 fact_groups_are_total: the declared universe equals the unit table's group union (one vocabulary, two faces): "+str(registry))
 var uncovered=declared.filter(func(group):return not CommandRegistry.FACT_UNITS.any(func(unit):return group in unit.get("groups",[])))
 t.check(uncovered.is_empty(),"K4 fact_groups_are_total: every declared group is produced by at least one unit: "+str(uncovered))
 var outside=E_VIEW_FACT_GROUPS.filter(func(group):return group not in declared)
 t.check(outside.is_empty(),"K4 fact_groups_are_total: the projection lower bound stays inside the declared universe: "+str(outside))
 print("E FACT GROUPS declared=%d states=%d" % [declared.size(),states.size()])

# C-E-5（gherkin E-5）：接管／card_chain／pending_retain 的需求＝全组——三支可在提交内由无变有（调用方在
# get_view 之前预知不到），由 core/game.gd::fact_demand_groups 的入口守卫取同一个全组值。裁一个窄需求也必须
# 拿到与全组构建逐字节相同的 View；接管注入行（FirstTurnControl.select 的 automated 行）仍在投影内，
# R5_FIRST_TURN 的逐 cell 摘要不变。
static func whole_table_branches_force_full_demand(t) -> void:
 var sweep={}
 for entry in branch_sweep_states():
  var label=String(entry.label)
  if label in ["flag:card_chain","flag:pending_retain"]: sweep[label]=entry.game
 var cases=[["takeover:0",r1_build("takeover",0)],["takeover:12",r1_build("takeover",12)],["flag:card_chain",sweep.get("flag:card_chain",null)],["flag:pending_retain",sweep.get("flag:pending_retain",null)]]
 var problems=[]
 var compared=0
 for entry in cases:
  var label=String(entry[0])
  if entry[1]==null:
   problems.append(label+": fixture missing")
   continue
  var g=entry[1]
  var full=g.get_view()
  var narrow=g.get_view(["relic"])
  if JSON.stringify(full)!=JSON.stringify(narrow): problems.append(label+": a narrow demand changed a whole-table branch")
  var automated=full.display_facts.filter(func(row):return bool(row.get("automated",false)))
  if label.begins_with("takeover") and automated.size()!=1: problems.append(label+": the takeover step row is missing automated="+str(automated.size()))
  compared+=1
 t.check(problems.is_empty() and compared==cases.size(),"K4 whole_table_branches_force_full_demand: takeover, card_chain and pending_retain always take the full group value: "+str(problems))
 var takeover=r1_build("takeover",0)
 var takeover_view=takeover.get_view(["relic"])
 var frozen_turn=r1_digest(JSON.stringify(takeover_view.first_turn_control))
 t.check(frozen_turn==String(R5_FIRST_TURN["takeover:0"]),"K4 whole_table_branches_force_full_demand: the takeover step face keeps its frozen digest under a narrow demand: "+frozen_turn)
 print("E WHOLE TABLE BRANCHES cases=%d" % compared)

# C-E-6（gherkin E-6；acceptance.md §1 E 段）：成功结果两键——键面（含顺序）等于字面表；phase == 提交后
# state.phase；overloaded == 同实例 get_view().pressure.overloaded（与 View.build 同源同值，不由 payload.kind
# 反推）；失败结果键面不动。敏感性：把 overloaded 换成裸 state.overloaded（丢战斗相位守卫）→ 下面的 reward
# 相位夹具（keeps_combat_state 仍真、相位不在 COMBAT_PHASES）即红。
static func submit_result_scalars_are_pinned(t) -> void:
 var key_problems=[]
 var value_problems=[]
 var submits=0
 for cell in [["battle",0],["battle",12],["prepare",12],["prison",12]]:
  var g=r1_build(cell[0],cell[1])
  var picked={}
  for row in g.command_facts():
   if row.valid:
    picked=row
    break
  if picked.is_empty(): continue
  var result=g.dispatch(g.command(picked.payload,g.state.version),g.state.version)
  if not result.ok: continue
  submits+=1
  if result.keys()!=E_SUBMIT_KEYS: key_problems.append("%s:%d kind=%s have=%s" % [cell[0],cell[1],String(picked.payload.get("kind","")),str(result.keys())])
  if String(result.get("phase",""))!=String(g.state.phase): value_problems.append("%s:%d phase %s != %s" % [cell[0],cell[1],String(result.get("phase","")),String(g.state.phase)])
  if bool(result.get("overloaded",false))!=bool(g.get_view().pressure.overloaded): value_problems.append("%s:%d overloaded != view pressure.overloaded" % [cell[0],cell[1]])
  if bool(result.get("overloaded",false))!=bool(g.state.overloaded and g.state.phase in E_COMBAT_PHASES): value_problems.append("%s:%d overloaded != guarded state flag" % [cell[0],cell[1]])
 var guarded=r1_build("battle",0)
 fact_unit_enrich(guarded)
 guarded.state.phase="reward"
 guarded.state.reward_options=["focus"]
 guarded.state.overloaded=true
 guarded.state.energy=0
 var guard_row={}
 for row in guarded.command_facts():
  if row.valid and String(row.payload.get("kind",""))=="reward":
   guard_row=row
   break
 var guard_result=guarded.dispatch(guarded.command(guard_row.payload,guarded.state.version),guarded.state.version)
 t.check(not guard_row.is_empty() and bool(guard_result.get("ok",false)),"K4 submit_result_scalars_are_pinned: the combat-phase guard fixture submits a reward row: "+String(guard_result.get("error","")))
 t.check(guard_result.keys()==E_SUBMIT_KEYS and String(guard_result.get("phase",""))==String(guarded.state.phase),"K4 submit_result_scalars_are_pinned: the success result keeps the declared key face and the post-commit phase: "+str(guard_result.keys()))
 t.check(bool(guarded.state.overloaded) and not bool(guard_result.get("overloaded",true)),"K4 submit_result_scalars_are_pinned: the overloaded scalar keeps the combat-phase guard (a bare state flag differs here): state="+str(guarded.state.overloaded)+" result="+str(guard_result.get("overloaded",null)))
 t.check(bool(guard_result.get("overloaded",true))==bool(guarded.get_view().pressure.overloaded),"K4 submit_result_scalars_are_pinned: the scalar equals the same instance's view pressure.overloaded")
 var stale=r1_build("battle",0)
 var stale_version=int(stale.state.version)
 var stale_result=stale.dispatch(stale.command({"kind":"card","uid":"forged_id"},stale_version-1),stale_version-1)
 t.check(stale_result.keys()==S5_REJECT_KEYS and not bool(stale_result.get("ok",true)),"K4 submit_result_scalars_are_pinned: a rejected submit keeps the frozen failure key face "+str(S5_REJECT_KEYS)+" have="+str(stale_result.keys()))
 var body=source_func_body_code("res://core/game.gd","dispatch")
 var at=body.rfind("return {\"ok\":true")
 var tail="" if at<0 else body.substr(at)
 t.check(tail.contains("\"phase\":state.phase") and tail.contains("Pressure.overloaded(self)") and not tail.contains("state.overloaded"),"K4 submit_result_scalars_are_pinned: the success result reads state.phase and the single pressure derivation (never a bare state flag, never the payload kind): "+tail.strip_edges().substr(0,160))
 t.check(submits>=3 and key_problems.is_empty() and value_problems.is_empty(),"K4 submit_result_scalars_are_pinned: every sampled submit carries both scalars with the declared values: submits="+str(submits)+" keys="+str(key_problems.slice(0,2))+" values="+str(value_problems.slice(0,2)))
 print("E SUBMIT SCALARS submits=%d" % submits)

# C-E-7（gherkin E-7；acceptance.md §1 E 段；G-2 五步程序）：同批重冻——submit_keys（＝result.keys() 摘要）与
# 派生 <record> 两个字段面 × 26 cell 的差异 ⊆ 声明且声明 ⊆ 差异（双向；差异漏进 view／facts_text／
# facts_verdicts／view_display_facts 即红——它们不在声明里）；自证＝前值可由后值按声明反推（把 post 记录里
# submit_keys 一行的值换回旧键面摘要后重算，逐 cell 等于前值）；前值来自外部锚定文件 tests/frozen-baselines.json。
static func baseline_diff_is_declared(t) -> void:
 var pre_cells=frozen_baselines().get("baseline_pre_cells",{})
 t.check(pre_cells is Dictionary and not (pre_cells as Dictionary).is_empty(),"K4 baseline_diff_is_declared: the pre-batch cell face lives in the external file "+FROZEN_BASELINES_JSON)
 var pre_face=String(S5_SUBMIT_KEYS_AFTER_DIGEST)
 var post_face=r1_digest(JSON.stringify(E_SUBMIT_KEYS))
 t.check(r1_digest(JSON.stringify(S5_SUBMIT_KEYS_AFTER))==pre_face,"K4 baseline_diff_is_declared: the pre-batch submit key face still hashes to the frozen S5 digest")
 t.check(post_face!=pre_face,"K4 baseline_diff_is_declared: the two key faces differ (the rebaseline is real, not a copied value)")
 var diff={}
 var self_proof=[]
 var problems=[]
 for cell in r1_cells():
  var key="%s:%d" % [cell[0],cell[1]]
  var record=r1_record(r1_build(cell[0],cell[1]),cell[0],cell[1])
  var pre=pre_cells.get(key,{})
  if pre.is_empty():
   problems.append(key+": no frozen pre face")
   continue
  var paths=record.keys()
  paths.sort()
  var lines=[]
  for path in paths:
   var value=str(record[path])
   if path=="submit_keys" and value!="<none>": value=pre_face
   lines.append(str(path)+"="+value)
  if r1_digest("\n".join(lines))!=String(pre.get("record","")): self_proof.append(key+": the pre <record> is not derivable from the post one")
  if str(record["submit_keys"])!=post_face: problems.append(key+": the submit key face digest is not the declared one have="+str(record["submit_keys"]))
  var moved={}
  var post_face_values={"facts_text":str(record["facts_text"]),"facts_verdicts":str(record["facts_verdicts"]),"record":r1_record_digest(record),"view":str(record["view"]),"view_display_facts":str(record["view_display_facts"])}
  for field in post_face_values:
   if String(post_face_values[field])!=String(pre.get(field,"")): moved[field]=E_SUBMIT_KEYS_REASON
  diff[key]=moved
 var undeclared=[]
 var missing_move=[]
 var moved_cells=0
 for key in diff:
  for field in diff[key]:
   if not (E_DECLARED_DIFF.has(key) and E_DECLARED_DIFF[key].has(field)): undeclared.append(key+"."+field)
  if not diff[key].is_empty(): moved_cells+=1
 for key in E_DECLARED_DIFF:
  for field in E_DECLARED_DIFF[key]:
   if not (diff.has(key) and diff[key].has(field)): missing_move.append(key+"."+field)
 t.check(problems.is_empty() and self_proof.is_empty(),"K4 baseline_diff_is_declared: the two field faces move exactly as declared and the pre face is derivable from the post face: "+str(problems.slice(0,3))+" "+str(self_proof.slice(0,3)))
 t.check(undeclared.is_empty(),"K4 baseline_diff_is_declared: every moved cell field is declared (a move outside submit_keys／<record> is red): "+str(undeclared.slice(0,4)))
 t.check(missing_move.is_empty(),"K4 baseline_diff_is_declared: every declared move happened (a declaration without a move is red): "+str(missing_move.slice(0,4)))
 t.check(E_DECLARED_DIFF.size()==r1_cells().size() and moved_cells==E_DECLARED_DIFF.size(),"K4 baseline_diff_is_declared: the declaration covers the frozen cells one by one have="+str(E_DECLARED_DIFF.size())+" moved="+str(moved_cells))
 print("E BASELINE DIFF declared=%d moved=%d" % [E_DECLARED_DIFF.size(),moved_cells])

# ==== F 批（K5 接线；plan §3 F 行；acceptance.md §1 F 段与 §4 F 命令清单）====
# 顺序（acceptance.md §5 第 5 条）：C-F-1／2／3／8／9 先绿，才进 C-F-6（契约文本与 mask）；C-F-7 常驻、期望零移动。

# C-F-2 的声明侧冻结（测试内字面表；期望值不取自被测扫描）：节 → 该节节体与节键读取的组集合。
# 归属依据＝ui/main.gd::PRESENT_ADJACENCY 的父子关系（SECTION_BODIES 的 adj 列必须从该节构建器经邻接
# 边可达）＋ SECTION_BODIES 的 extra 列（交互回调与邻接表未登记的体，逐条声明）＋ QUERY_WRAPPER_GROUPS
# （组字面在外部 ui 文件里的包装调用）。与 ui/main.gd::PRESENT_DEMAND 双向全量（C-F-1）；
# 运行期读集由 tests/display_ui_cases.gd 的记录器比对（同一张表的第二面）。
# 残差（登记进 docs/spec/fact-table-dependencies.md「仍靠人审」）：拖放候选回调（_free_player_candidate
# 等数据驱动读取）不按组字面进扫描——它们读取的组（card／posture）已由其它节的声明覆盖，且其行来自
# 投影本身（拖起的行已在投影内）；商店／事件等外屏的字面在 render 的整帧路径读取，那些路径需求取全组。
const SECTION_READ_SETS={
 "header":[],
 "relics":["relic"],
 "hand":["card"],
 "actions":["attack","pressure"],
 "posture":["posture","wall_move"],
 "resources":["flow","surrender","flask"],
 "show_log":[],
 "body_bar":["card"],
 "body_details":["attack","card","manual","retain"],
 "pickers":[],
 "speech":[],
 "notice":[],
 "drawers":["hook","item","status_toggle"],
 "page":["chain","demo_exit","flow","item","prison","route"],
 "scene_instances":["attack","status_toggle"],
}
# 修复批 G2（acceptance.md C-F-1）：未声明读组的登记理由（测试内字面表）。PRESENT_DEMAND 是需求声明
# 不是读集名册：SECTION_READ_SETS[section] 中未进 PRESENT_DEMAND[section] 的组必须逐组在此登记——
# 理由=VIEW ⇒ 组 ∈ core/command_registry.gd::VIEW_FACT_GROUPS（投影承接组恒在闭包 scope 内，
# 声明与否不改变裁剪结果）；理由=page ⇒ 节=page（page 渲染走完整谓词全组回落，声明行不承载）。
# 理由与事实不符、漏登记、或登记了实际已声明／未读的组（陈旧登记）都由 demand_declarations_are_total 判红。
const F_DEMAND_EXCLUSIONS={
 "hand":{"card":"VIEW"},
 "posture":{"posture":"VIEW"},
 "resources":{"flow":"VIEW"},
 "body_bar":{"card":"VIEW"},
 "body_details":{"card":"VIEW","manual":"VIEW"},
 "drawers":{"item":"VIEW"},
 "page":{"chain":"page","demo_exit":"page","flow":"page","item":"page","prison":"page","route":"page"},
}
# 修复批 G2：裁剪可达的冻结差集。有效 scope＝raw 声明并集 ∪ VIEW_FACT_GROUPS 必须是 fact_groups()
# 的真子集，且差集恰为此非空字面（{chain,demo_exit} 由 page 域全组回落承载）——差集为空
# （声明∪承接覆盖全组）⇒ 裁剪机制空转，当场红；新组进 fact_groups() 而未被有效 scope 覆盖也红。
const F_DEMAND_SCOPE_DIFFERENCE=["chain","demo_exit"]
# 每节的声明体：adj＝必须经 PRESENT_ADJACENCY 从该节构建器可达；extra＝邻接表未登记的体（键命中、
# 交互回调、整帧页分支），存在性由判据核对。节键函数（*_presentation_key 及其 key_hit）逐节在列。
const SECTION_BODIES={
 "header":{"adj":[],"extra":[]},
 "relics":{"adj":["_relic_row","_relic_presentation_key"],"extra":[]},
 "hand":{"adj":["_hand","_hand_presentation_key","_hand_card_key","_hand_choice"],"extra":["_player_drag_preview","_activate_card"]},
 "actions":{"adj":["_build_action_rail","_action_presentation_key"],"extra":[]},
 "posture":{"adj":["_refresh_posture_section","_posture_presentation_key","_wall_controls","_posture_controls"],"extra":["_posture_key_hit","_posture_layout","_self_action"]},
 "resources":{"adj":["_refresh_resource_section","_resource_presentation_key","_build_resource_bar"],"extra":["_resource_key_hit"]},
 "show_log":{"adj":[],"extra":[]},
 "body_bar":{"adj":[],"extra":["_free_player_candidate","_can_drop_on_player"]},
 "body_details":{"adj":["_refresh_body_details_section","_body_details_presentation_key","_body_details"],"extra":["_refresh_body_details","_body_card_actions","_single_body_card_action","_single_restraint_card_action","_player_picker","_equipment_tile","_equipment_actions","quick_release_source","_card_target"]},
 "pickers":{"adj":[],"extra":["_hand_target_picker"]},
 "speech":{"adj":[],"extra":[]},
 "notice":{"adj":[],"extra":[]},
 "drawers":{"adj":["_refresh_drawer_section","_drawer_presentation_key","_menu_drawer","_items_drawer"],"extra":["_item_details","_hook_drawer","_pressure_drawer","_status_control"]},
 "page":{"adj":[],"extra":["_capture_screen","_inspection_screen","_route_screen","_practice_screen","_chain_screen","_demo_exit_screen","_prison_controls","_prison_location_details","_door_candidate","_queue_map_step","_select_route_room"]},
 "scene_instances":{"adj":["_refresh_scene_instances_section","_status_strip","_sync_enemy_stage","_sync_enemy_select","_configure_enemy_drop","_attack_drop_candidate"],"extra":["_status_control"]},
 "target_drag":{"adj":[],"extra":["_begin_target_drag",{"file":"ui/drag_targets.gd","function":"focus_bodies"}]},
}
# 组字面在外部 ui 文件里的包装调用（判据侧声明；包装体本身在 ui/main.gd 内无组字面）。
const QUERY_WRAPPER_GROUPS={"_build_resource_bar":["flask"]}
# 各节构建器（PRESENT_ADJACENCY 的归属根；header／body_bar 的构建器在 ui/shell/ 外部文件，本表只扫 main.gd）。
const SECTION_BUILDERS={
 "relics":"_relic_row","hand":"_hand","actions":"_build_action_rail","posture":"_refresh_posture_section",
 "resources":"_refresh_resource_section","show_log":"_refresh_log_section","body_details":"_refresh_body_details_section",
 "pickers":"_refresh_picker_section","speech":"_refresh_speech_section","notice":"_refresh_notice_section",
 "drawers":"_refresh_drawer_section","scene_instances":"_refresh_scene_instances_section",
}
# PHASE_OPEN_DEMAND 的相位词表（退化表的键域；测试内字面期望）。
const F_PHASE_OPEN_EXPECTED={
 "battle":["attack","pressure"],"prepare":["attack","pressure"],"rest":["hook"],"prison":["item","prison"],
 "pack":["item"],"map":["route"],"travel":["route"],"reward":["reward"],"rest_choice":["rest_service"],
 "shop":["service","service_flow","service_refresh","service_release","service_remove"],"treasure":["service"],
 "event":["event"],"captured":["item","prison"],"inspection":["item","prison"],"departure":["reward"],
 "cleared":["demo_exit"],"prison_end":[],
}
# C-F-9 的前缀态夹具登记（修复批 G8：前缀夹具运行的唯一驱动——lazy_projection_invariant 的运行循环
# 按本表迭代并记录实际执行集，执行集／声明集双向对账；配方偶遇不再作为前缀态的覆盖来源）。
const F_PREFIX_PROFILES=[["prefix:relic_bundle","relic_bundle"],["prefix:domain_blocked","domain_blocked"]]

# main.gd 的函数体切分（1 空格缩进的顶层 func；与本文件其它源码扫描判据同一形态）。
static func f_main_bodies() -> Dictionary:
 var declaration=RegEx.new()
 if declaration.compile("^func ([A-Za-z_][A-Za-z0-9_]*)")!=OK: return {}
 var bodies={}
 var current=""
 var buffer=[]
 for line in source_text("ui/main.gd").split("\n"):
  var code=String(line).split("#")[0]
  var found=declaration.search(code)
  if found!=null:
   if current!="": bodies[current]="\n".join(buffer)
   current=found.get_string(1)
   buffer=[]
  elif current!="":
   buffer.append(code)
 if current!="": bodies[current]="\n".join(buffer)
 return bodies

# ui/main.gd::PRESENT_ADJACENCY 的可达闭包（从节构建器出发；与 present_adjacency_graph_is_pinned 同一声明表）。
static func f_extra_anchor(entry) -> Dictionary:
 if entry is String: return {"file":"ui/main.gd","function":String(entry)}
 if not entry is Dictionary or entry.size()!=2 or not entry.get("file") is String or not entry.get("function") is String: return {}
 var file=String(entry.file)
 var name=String(entry.function)
 if not file.begins_with("ui/") or not file.ends_with(".gd") or file.contains("\\") or file.contains("..") or file.contains(":") or file.simplify_path()!=file or name.is_empty(): return {}
 return {"file":file,"function":name}

static func f_main_owners(name: String, file: String="ui/main.gd") -> Array:
 var owners=[]
 for section in SECTION_BODIES:
  var owns=file=="ui/main.gd" and (name in SECTION_BODIES[section].adj or SECTION_BUILDERS.get(section,"")==name)
  for entry in SECTION_BODIES[section].extra:
   if f_extra_anchor(entry)=={"file":file,"function":name}: owns=true
  if owns: owners.append(section)
 return owners

static func f_adjacency_reachable(builder: String, adjacency: Dictionary, bodies: Dictionary, section: String="") -> Array:
 var seen={}
 var queue=[builder]
 while not queue.is_empty():
  var name=String(queue.pop_front())
  if seen.has(name): continue
  seen[name]=true
  for child in adjacency.get(name,[]):
   # Full-render fallback owns a full demand, not the local section's read set.
   if String(child) in ["render","present"]: continue
   var owners=f_main_owners(String(child))
   if section!="" and owners.size()==1 and owners[0]!=section: continue
   if bodies.has(String(child)) and not seen.has(String(child)): queue.append(String(child))
 return seen.keys()

# 一个节的扫描读集：声明体（adj＋extra）∪ 包装调用 ⇒ 组字面并集。
static func f_section_scan(section: String, bodies: Dictionary, adjacency: Dictionary) -> Array:
 var declared=SECTION_BODIES[section]
 var names=[]
 names.append_array(declared.adj)
 for entry in declared.extra:
  var anchor=f_extra_anchor(entry)
  if anchor.get("file","")=="ui/main.gd": names.append(anchor.function)
 if SECTION_BUILDERS.has(section):
  for name in f_adjacency_reachable(SECTION_BUILDERS[section],adjacency,bodies,section):
   if name not in names: names.append(name)
 var groups={}
 for name in names:
  var body=String(bodies.get(String(name),""))
  var found=RegEx.new()
  if found.compile("TargetQueries\\.(?:facts|select|find|fact_by_key)\\(\\s*view\\s*,\\s*\"([a-z_]+)\"")!=OK: continue
  for hit in found.search_all(body): groups[String(hit.get_string(1))]=true
  for group in QUERY_WRAPPER_GROUPS.get(String(name),[]): groups[String(group)]=true
 var out=groups.keys()
 out.sort()
 return out

# C-F-1（gherkin F-1；acceptance.md C-F-1；修复批 G2/G7）：需求声明受钉——PRESENT_DEMAND 是需求声明
# 不是读集名册：每节声明行 ⊆ SECTION_READ_SETS 同节行（幻影声明红），未声明的读组逐组带登记理由
# （F_DEMAND_EXCLUSIONS：理由=VIEW ⇒ 组 ∈ CommandRegistry.VIEW_FACT_GROUPS；理由=page ⇒ 节=page），
# 逐节相等检查作废；全节 raw 并集 U 与 VIEW_FACT_GROUPS 的并集是 fact_groups() 的真子集且差集为
# 冻结字面 {chain,demo_exit}（差集为空 ⇒ 裁剪机制空转，当场红）；raw 并集不含 item ⇒ _present_demand
# 的 opens.open_items 分支真实可达（删分支＝源文本红）；PHASE_OPEN_DEMAND 键域与值域受钉（失败兜底，
# G2 不改）；每个声明组都存在于单元表的组列（组→单元，同一张表不另立）；闭包只有一处实现
# （core/game.gd::fact_demand_groups）；core 不读 UI 节名（G7：扫描面扩到全部可机械扫描的节名，
# 残差见 docs/spec/fact-table-dependencies.md「仍靠人审」）。
# 敏感性：把声明改回读集名册（如给 hand 加回 card）→ 陈旧登记红；给声明并集加组使差集变空 → 冻结差集红；
# 新增未声明读组无登记理由 → 理由红；core 出现扫描面内节名 → 红；删 opens.open_items 分支 → 源文本红。
static func demand_core_source_is_nonempty(t) -> String:
 var texts=[]
 for path in ["core/game.gd","core/command_registry.gd","core/game_view.gd"]:
  var text=source_text(path)
  t.check(not text.is_empty(),"F1 demand_core_source_is_nonempty / demand_declarations_are_total: the core vocabulary boundary reads real source at "+path+", not an empty or doubly-prefixed path")
  texts.append(text)
 return "\n".join(texts)

# 修复批 RF-1（step-5 独立审查）：监狱地点页（ui/main.gd::_prison_location_details）的组合行序钉死，双向。
# ① 拼接序＝单元表序：page_rows 先读 item 组，prison 组经 append_array 并接在已建 page_rows
#    之后——FACT_UNITS action_tail 段 item_action order=7 先于 prison_tail order=9，本页渲染相位
#    （phase=="prison"，页路由唯一入口）的表内两组相对序即此。prison 组 prepend 到 page_rows
#    之前（65e1c08 的 RF-1 回归形态＝mutations.json 同名条目的改写 `prison+page_rows`）会删掉
#    append 行，故 prison 侧锚取完整 append 行：prepend 即锚消失，锚全量检查红。
# ② 呈现序＝牢门行 → 非 item_use 的 compact 行 → item_use 落点网格；任两段对调即红。
# 锚＝函数体内恰好出现一次的子串（幽灵锚、多义锚与被突变删掉的锚都红）。
static func prison_page_row_order_is_pinned(t) -> void:
 var body=source_func_body_code("res://ui/main.gd","_prison_location_details")
 var item_read="TargetQueries.facts(view,\"item\")"
 var prison_read="page_rows.append_array(TargetQueries.facts(view,\"prison\"))"
 var door_row="scroll.add_child(door)"
 var compact_loop="if c.payload.kind!=\"item_use\": _compact_action(scroll,c)"
 var grid_loop="for c in targets: _tool_target_card(grid,c)"
 var broken=[]
 for anchor in [item_read,prison_read,door_row,compact_loop,grid_loop]:
  if body.count(anchor)!=1: broken.append(anchor)
 t.check(broken.is_empty(),"RF1 prison_page_row_order_is_pinned: every row-order anchor occurs exactly once in _prison_location_details (a phantom or ambiguous anchor is red): "+str(broken))
 if not broken.is_empty(): return
 t.check(body.find(item_read)<body.find(prison_read),"RF1 prison_page_row_order_is_pinned: the page assembles the item group rows before the prison group rows (the unit-table order of the two groups on this page; swapping the two reads is red)")
 t.check(body.find(door_row)<body.find(compact_loop) and body.find(compact_loop)<body.find(grid_loop),"RF1 prison_page_row_order_is_pinned: the combined emission stays door row, then compact rows, then the item_use target grid (swapping any two segments is red)")

static func demand_declarations_are_total(t) -> void:
 var ui_script=load("res://ui/main.gd")
 var present: Dictionary=ui_script.PRESENT_DEMAND
 var sections=[]
 for section in ui_script.PRESENT_SECTIONS: sections.append(String(section))
 var missing=[]
 var extra=[]
 for section in sections:
  if not present.has(section): missing.append(section)
 for section in present:
  if not sections.has(String(section)): extra.append(String(section))
 t.check(missing.is_empty() and extra.is_empty(),"F1 demand_declarations_are_total: every presentable section declares its demand row and nothing else: missing="+str(missing)+" extra="+str(extra))
 var universe=CommandRegistry.fact_groups()
 var view_backed=[]
 for group in CommandRegistry.VIEW_FACT_GROUPS: view_backed.append(String(group))
 var declared_problems=[]
 var face_problems=[]
 var reason_problems=[]
 var raw_union=[]
 for section in sections:
  var row=[]
  for group in present.get(section,[]): row.append(String(group))
  row.sort()
  var frozen=[]
  for group in SECTION_READ_SETS[section]: frozen.append(String(group))
  frozen.sort()
  for group in row:
   if group not in frozen: face_problems.append(section+" declares unread "+group)
   if group not in universe: declared_problems.append(section+"."+group)
   if group not in raw_union: raw_union.append(group)
  for group in frozen:
   if group in row: continue
   var reason=String(F_DEMAND_EXCLUSIONS.get(section,{}).get(group,""))
   if reason=="": reason_problems.append(section+"."+group+" undeclared without a registered reason");continue
   if reason=="VIEW" and group not in view_backed: reason_problems.append(section+"."+group+" reason=VIEW but the group is not a projection-backed group")
   if reason=="page" and section!="page": reason_problems.append(section+"."+group+" reason=page outside the page section")
 for section in F_DEMAND_EXCLUSIONS:
  if not sections.has(String(section)): reason_problems.append(String(section)+" is not a presentable section");continue
  for group in F_DEMAND_EXCLUSIONS[section]:
   var frozen=[]
   for read in SECTION_READ_SETS[section]: frozen.append(String(read))
   var row=[]
   for group2 in present.get(section,[]): row.append(String(group2))
   if String(group) in row or String(group) not in frozen: reason_problems.append(section+"."+String(group)+" registers a stale exclusion (declared or not read)")
 t.check(face_problems.is_empty(),"F1 demand_declarations_are_total: every declared group is a real read of its section (a phantom declaration is red): "+str(face_problems.slice(0,3)))
 t.check(declared_problems.is_empty(),"F1 demand_declarations_are_total: every declared group exists in the unit table's group union (a phantom group is red): "+str(declared_problems))
 t.check(reason_problems.is_empty(),"F1 demand_declarations_are_total: every undeclared read group carries a registered exclusion reason (VIEW-backed or page domain) and no stale registration survives: "+str(reason_problems.slice(0,3)))
 var effective=raw_union.duplicate()
 for group in view_backed:
  if group not in effective: effective.append(group)
 var difference=[]
 for group in universe:
  if String(group) not in effective: difference.append(String(group))
 t.check(difference==F_DEMAND_SCOPE_DIFFERENCE,"F1 demand_declarations_are_total: the effective scope (raw declaration union plus projection-backed groups) stays a proper subset of the fact universe with the frozen non-empty difference {chain, demo_exit} carried by the page full-group fallback (an empty difference means the crop mechanism is dead): "+str(difference))
 t.check(not raw_union.has("item"),"F1 demand_declarations_are_total: the raw declaration union does not declare item (the opens.open_items branch stays reachable; the declaration is not a read-set roster): "+str(raw_union))
 var open_demand: Dictionary=ui_script.PHASE_OPEN_DEMAND
 var phase_problems=[]
 for phase in open_demand:
  if not F_PHASE_OPEN_EXPECTED.has(String(phase)): phase_problems.append("phase "+String(phase))
  elif open_demand[phase]!=F_PHASE_OPEN_EXPECTED[phase]: phase_problems.append("row "+String(phase))
  for group in open_demand[phase]:
   if String(group) not in universe: phase_problems.append(String(phase)+"."+String(group))
 for phase in F_PHASE_OPEN_EXPECTED:
  if not open_demand.has(phase): phase_problems.append("missing "+phase)
 t.check(phase_problems.is_empty(),"F1 demand_declarations_are_total: the fallback table stays inside the declared phase vocabulary and the group universe, and covers every phase: "+str(phase_problems.slice(0,3)))
 var demand_body=source_func_body_code("res://ui/main.gd","_present_demand")
 t.check(demand_body.contains("PRESENT_DEMAND.get(section") and demand_body.contains("_submit_opens(") and demand_body.contains("PHASE_OPEN_DEMAND.get(phase"),"F1 demand_declarations_are_total: _present_demand is the single demand entry reading the two declared tables and the shared open/close implementation")
 t.check(demand_body.contains("if opens.open_items and \"item\" not in groups"),"F1 demand_declarations_are_total: _present_demand keeps the opens.open_items branch that carries the pack-opened item group (deleting the branch is red)")
 var core_texts=demand_core_source_is_nonempty(t)
 var closure=source_func_body_code("res://core/game.gd","fact_demand_groups")
 t.check(closure.contains("CommandRegistry.fact_scope(demand)") and closure.count("fact_scope(")==1,"F1 demand_declarations_are_total: demand reaches the existing single core closure entry")
 # G7 core 节名泄漏扫描面＝15 节中可机械扫描者（quoted 字面不与 core 自身词汇撞形）：
 # posture 与组名同形、relics／hand／speech 与 core 自身 state／View 键词汇同形——四处残差登记
 # docs/spec/fact-table-dependencies.md「仍靠人审」，不进机械扫描面（扫描即误报，基线变红）。
 var leaked=[]
 for name in ["header","actions","resources","notice","page","show_log","body_bar","body_details","pickers","drawers","scene_instances"]:
  if core_texts.contains("\""+name+"\""): leaked.append(name)
 t.check(not core_texts.contains("PRESENT_DEMAND") and not core_texts.contains("PHASE_OPEN_DEMAND") and not core_texts.contains("PRESENT_SECTIONS") and leaked.is_empty(),"F1 demand_declarations_are_total: core never reads the UI section vocabulary (one-way declaration; the swept face and its residuals are registered in fact-table-dependencies.md): "+str(leaked))
 var groups=0
 for section in sections: groups+=SECTION_READ_SETS[section].size()
 print("F1 DEMAND TABLES sections=%d groups=%d declared=%d scope=%d fallback_phases=%d" % [sections.size(),groups,raw_union.size(),effective.size(),F_PHASE_OPEN_EXPECTED.size()])

# C-F-2（gherkin F-2；acceptance.md C-F-2）：逐节读集冻结——源码扫描双向（含节键函数与 extra 体），
# adj 体必须经 PRESENT_ADJACENCY 从节构建器可达，extra 体必须存在；relics 节键覆盖 relic 组
# （O-7 修掉，无例外文本——_relic_presentation_key 必须含 TargetQueries 的 relic 组字面）。
# 运行期读集由 tests/display_ui_cases.gd::section_read_sets_runtime 与本表比对（同表第二面）。
# 敏感性：某节体新增读一个组而没进表 → 扫描红；声明写了没人读 → 反向红。
static func section_read_sets_are_pinned(t) -> void:
 var bodies=f_main_bodies()
 var adjacency=load("res://ui/main.gd").PRESENT_ADJACENCY
 var missing=[]
 var unreachable=[]
 var forward=[]
 var backward=[]
 var extra_seen={}
 var extra_problems=[]
 var legacy=0
 for section in SECTION_BODIES:
  for entry in SECTION_BODIES[section].extra:
   var anchor=f_extra_anchor(entry)
   if anchor.is_empty(): extra_problems.append(section+" invalid extra="+str(entry));continue
   var label=String(anchor.file)+"::"+String(anchor.function)
   var registration=String(section)+"/"+label
   if extra_seen.has(registration): extra_problems.append("duplicate "+registration)
   extra_seen[registration]=true
   var body=String(bodies.get(anchor.function,"")) if anchor.file=="ui/main.gd" else source_static_func_body_code("res://"+String(anchor.file),String(anchor.function))
   if not FileAccess.file_exists("res://"+String(anchor.file)) or body.strip_edges().is_empty() or section not in f_main_owners(String(anchor.function),String(anchor.file)): extra_problems.append("unresolved "+label)
   if entry is String:
    legacy+=1
    if anchor!={"file":"ui/main.gd","function":String(entry)}: extra_problems.append("legacy changed "+label)
 t.check(extra_problems.is_empty() and legacy==35,"F2 section_read_sets_are_pinned: extra anchors normalize once, preserve all 35 legacy main entries, and name real file/function bodies without duplicate registrations: "+str(extra_problems))
 for section in SECTION_READ_SETS:
  var declared=SECTION_BODIES[section]
  for name in declared.adj:
   if not bodies.has(String(name)): missing.append(section+"/"+String(name))
  for entry in declared.extra:
   var anchor=f_extra_anchor(entry)
   if anchor.get("file","")=="ui/main.gd" and not bodies.has(String(anchor.function)): missing.append(section+"/"+String(anchor.function)+"(extra)")
  if SECTION_BUILDERS.has(section):
   var reachable=f_adjacency_reachable(SECTION_BUILDERS[section],adjacency,bodies,section)
   for name in declared.adj:
    if not reachable.has(String(name)): unreachable.append(section+"/"+String(name))
  var scan=f_section_scan(section,bodies,adjacency)
  var frozen=[]
  for group in SECTION_READ_SETS[section]: frozen.append(String(group))
  frozen.sort()
  for group in scan:
   if group not in frozen: forward.append(section+"."+group)
  for group in frozen:
   if group not in scan: backward.append(section+"."+group)
 t.check(missing.is_empty(),"F2 section_read_sets_are_pinned: every declared body is a real ui/main.gd function: "+str(missing.slice(0,4)))
 t.check(unreachable.is_empty(),"F2 section_read_sets_are_pinned: adjacency bodies are reachable from their section builder through PRESENT_ADJACENCY: "+str(unreachable.slice(0,4)))
 t.check(forward.is_empty(),"F2 section_read_sets_are_pinned: every group literal in a declared section body is in that section's frozen set (a new read is red): "+str(forward.slice(0,4)))
 t.check(backward.is_empty(),"F2 section_read_sets_are_pinned: every declared group is read by a declared section body (a declared-but-unread group is red): "+str(backward.slice(0,4)))
 var relic_key=String(bodies.get("_relic_presentation_key",""))
 t.check(relic_key.contains("TargetQueries.find(view,\"relic\""),"F2 section_read_sets_are_pinned: the relics section key covers the relic group its rebuild reads (O-7 fixed; no declared exception)")
 t.check(f_main_owners("_refresh_body_details")==["body_details"] and f_main_owners("_body_details")==["body_details"] and not f_adjacency_reachable("_hand",adjacency,bodies,"hand").has("_body_details"),"F2 section_read_sets_are_pinned: the same ownership declaration stops hand callbacks at body_details and owns both destination entries")
 var focus=source_static_func_body_code("res://ui/drag_targets.gd","focus_bodies")
 var choices=source_static_func_body_code("res://ui/drag_targets.gd","choices")
 var offers=source_static_func_body_code("res://ui/drag_targets.gd","offers")
 t.check(SECTION_BODIES.get("target_drag",{})=={"adj":[],"extra":["_begin_target_drag",{"file":"ui/drag_targets.gd","function":"focus_bodies"}]} and f_main_owners("_begin_target_drag")==["target_drag"] and f_main_owners("focus_bodies","ui/drag_targets.gd")==["target_drag"] and String(bodies.get("_begin_target_drag","")).contains("DragTargets.begin(self,data)") and focus.contains("choices(ui,data)") and choices.contains("offers(ui,data)") and offers.contains("Queries.drag_facts(ui.view,data,ui.view.version)") and not SECTION_READ_SETS.has("target_drag"),"F2 section_read_sets_are_pinned: begin and the dedicated focus_bodies query chain share one independent interaction declaration, not a present section or a guessed group owner")
 var covered=0
 for section in SECTION_READ_SETS: covered+=SECTION_READ_SETS[section].size()
 print("F2 SECTION READ SETS sections=%d groups=%d" % [SECTION_READ_SETS.size(),covered])

# C-F-3 actual reads are observed only by the display lifecycle in the original recipe window path.
# No headless declaration replay is accepted as actual rendering evidence.

# C-F-4＋C-F-5（gherkin F-4／F-5；acceptance.md C-F-4／C-F-5）：调用点与需求取值受钉——get_view 四点
# 白名单内的需求表达式逐点核对：_submit 的局部重建分支（前后均 battle 且节键可用）传 _present_demand
# （精确开合经 _submit_opens 与归一化段共用同一实现；PHASE_OPEN_DEMAND 只在 result.ok==false 兜底），
# 其余路径（含 render(updated) 回落与存档恢复）传全组；_prison_location_details 不再直读整表、
# prison／item 组走组查询。敏感性：改掉需求表达式或另写一份开合条件式 → 文本判据红。
static func submit_demand_call_sites_are_pinned(t) -> void:
 var submit=source_func_body_code("res://ui/main.gd","_submit")
 t.check(submit.contains("var local_rebuild: bool=String(previous.get(\"phase\",\"\"))==\"battle\" and not previous_keys.is_empty() and (String(result.get(\"phase\",\"\"))==\"battle\" if bool(result.get(\"ok\",false)) else true)"),"F4 submit_demand_call_sites_are_pinned: the local-rebuild branch is decided from the post-commit scalars (battle on both sides and usable section keys)")
 t.check(submit.contains("game.get_view(_present_demand(result) if local_rebuild else [])"),"F4 submit_demand_call_sites_are_pinned: the possible-local-rebuild submit passes the declared demand; every other path keeps the default full group")
 t.check(submit.contains("var opens=_submit_opens(result,previous)") and submit.contains("if opens.close_drawers: _close_drawers()") and submit.contains("if opens.open_items: show_items=true"),"F4 submit_demand_call_sites_are_pinned: the normalization segment executes the one shared open/close implementation")
 t.check(submit.contains("if local_rebuild: updated=game.get_view()") and submit.contains("if not _present_needs_full_render(dirty,updated):"),"F4 submit_demand_call_sites_are_pinned: every complete fallback after dirty evaluation re-projects full group through the existing second statement")
 var presenter=source_func_body_code("res://ui/main.gd","present")
 t.check(presenter.contains("if _present_needs_full_render(dirty,next):") and not presenter.contains("dirty.has(\"speech\")") and not presenter.contains("get_view("),"F4 submit_demand_call_sites_are_pinned: present consumes the same full predicate without a second condition chain or a projection call")
 var statement_counts=[]
 for name in ["_resume_snapshot","render","_submit","restart"]: statement_counts.append(source_func_body_code("res://ui/main.gd",name).count("game.get_view("))
 t.check(statement_counts==[1,1,2,1],"F4 submit_demand_call_sites_are_pinned: the four owners retain the five existing projection statements 1/1/2/1: "+str(statement_counts))
 var fallback=source_func_body_code("res://ui/main.gd","_present_needs_full_render")
 var fallback_sections=[]
 var matcher=RegEx.new()
 matcher.compile("section==\"([a-z_]+)\"")
 for hit in matcher.search_all(fallback):
  if hit.get_string(1) not in fallback_sections: fallback_sections.append(hit.get_string(1))
 var expected_sections=["*","page","hand","header","actions","posture","resources","show_log","body_details","pickers","speech","notice","drawers","scene_instances"]
 fallback_sections.sort();expected_sections.sort()
 # The wildcard is tested separately because the identifier regex intentionally excludes '*'.
 expected_sections.erase("*")
 t.check(fallback_sections==expected_sections and fallback.contains("section==\"*\"") and fallback.contains("dirty.is_empty()") and fallback.contains("var next=view if source.is_empty() else source") and not fallback.contains("get_view("),"F4 submit_demand_call_sites_are_pinned: the one full-render predicate keeps all frozen structural/section branches and uses the selected source")
 t.check(submit.count("game.get_view(")==2,"F4 submit_demand_call_sites_are_pinned: _submit fetches the view exactly twice at most (demand projection and the full-group fallback)")
 var present=source_func_body_code("res://ui/main.gd","_present_demand").replace("\r","")
 t.check(present.contains("if not bool(result.get(\"ok\",false)):\n  var phase=String(view.get(\"phase\",\"\"))\n  for group in PHASE_OPEN_DEMAND.get(phase,[]):") and present.count("PHASE_OPEN_DEMAND.get(")==1,"F4 submit_demand_call_sites_are_pinned: only ok=false reads the fallback table; successful results never enter that fallback")
 var opens_body=source_func_body_code("res://ui/main.gd","_submit_opens")
 t.check(opens_body.contains("if not bool(result.get(\"ok\",false))") and not present.contains("close_drawers\":") and not submit.contains("updated.phase!=view.phase") and not submit.contains("updated.pressure.overloaded"),"F4 submit_demand_call_sites_are_pinned: open/close decisions have one implementation, not a second normalization condition")
 var host=load("res://ui/main.gd").new()
 host.view={"phase":"battle"}
 t.check(host._submit_opens({"ok":false},host.view)=={"close_drawers":false,"open_items":false},"F4 submit_demand_call_sites_are_pinned: failed submits leave section opening unchanged")
 t.check(host._submit_opens({"ok":true,"phase":"pack","overloaded":false},host.view)=={"close_drawers":true,"open_items":true},"F4 submit_demand_call_sites_are_pinned: post-commit pack closes old drawers then opens items")
 t.check(host._submit_opens({"ok":true,"phase":"battle","overloaded":true},host.view)=={"close_drawers":true,"open_items":false},"F4 submit_demand_call_sites_are_pinned: post-commit overload closes drawers")
 var closed=host._present_demand({"ok":true,"phase":"battle","overloaded":false})
 host.show_items=true;host.show_menu=true;host.show_body=true
 t.check(host._present_demand({"ok":true,"phase":"battle","overloaded":false})==closed,"F4 submit_demand_call_sites_are_pinned: declaration demand does not depend on transient drawer opening")
 host.free()
 var opens_refs=source_text("ui/main.gd").count("_submit_opens(")
 t.check(opens_refs==3,"F4 submit_demand_call_sites_are_pinned: _submit_opens has exactly two consumers (normalization and the demand entry) beside its declaration have=%d"%opens_refs)
 for name in ["render","_resume_snapshot","restart"]:
  var body=source_func_body_code("res://ui/main.gd",name)
  t.check(body.contains("game.get_view()") and not body.contains("game.get_view(["),"F4 submit_demand_call_sites_are_pinned: "+name+" keeps the default full-group projection")
 var prison=source_func_body_code("res://ui/main.gd","_prison_location_details")
 t.check(not prison.contains("view.display_facts"),"F5 submit_demand_call_sites_are_pinned: _prison_location_details no longer reads the whole projection")
 t.check(prison.contains("TargetQueries.facts(view,\"prison\")") and prison.contains("TargetQueries.select(view,\"item\""),"F5 submit_demand_call_sites_are_pinned: the prison page reads the prison and item groups through the one query face")
 var groups=0
 for section in SECTION_READ_SETS: groups+=SECTION_READ_SETS[section].size()
 t.check(SECTION_READ_SETS["page"].has("prison") and SECTION_READ_SETS["page"].has("item"),"F5 submit_demand_call_sites_are_pinned: the prison page's groups are declared in its section demand")
 print("F4 DEMAND CALL SITES sections=%d groups=%d" % [SECTION_READ_SETS.size(),groups])

# C-F-8（gherkin F-8；acceptance.md C-F-8；R-T8，design.md §K1-D 末段）：全组槽位准入＝内容等值——
# 源码文本无 size 比较；「等 size 非全组」demand（全部真实组去一＋加一未登记组）不占批内槽位，
# 同批后续全组读取不被污染（两段各自与从零实例逐字节相等）。敏感性：把判定改回 size 启发式
# （突变条目 command_facts_full_scope_is_content_equal）→ 该 demand 命中 size 判定占用整表槽位 ⇒
# 同批后续全组读取含裁剪行，红。
static func command_facts_full_scope_is_content_equal(t) -> void:
 var body=source_func_body_code("res://core/game.gd","command_facts")
 t.check(not body.contains(".size()=="),"F8 command_facts_full_scope_is_content_equal: the size heuristic is gone from the slot admission")
 t.check(body.contains("if scope==CommandRegistry.fact_groups() else build.call()"),"F8 command_facts_full_scope_is_content_equal: the slot admission is the content equality against the truth-source full group")
 t.check(body.count("fact_groups()")==1,"F8 command_facts_full_scope_is_content_equal: exactly one full-group condition guards the batch slot (no second admission path)")
 var groups: Array=CommandRegistry.fact_groups()
 var crafted=[]
 for group in groups:
  if group!="relic": crafted.append(group)
 crafted.append("no_such_group")
 var problems=[]
 for cell in [["battle",0],["battle",12]]:
  var g=r1_build(cell[0],cell[1],ReuseRecorder)
  fact_unit_enrich(g)
  g.state.relics=["great_wand"]
  var snapshot=g.export_snapshot()
  var reference=ReuseRecorder.new(42)
  t.check(reference.restore_snapshot(snapshot).ok,"F8 command_facts_full_scope_is_content_equal: the independent empty-cache instance restores the fixture")
  var restored=reference.export_snapshot()
  var mismatched=snapshot.keys().filter(func(key):return key!="version" and JSON.stringify(restored.get(key))!=JSON.stringify(snapshot[key]))
  t.check(mismatched.is_empty() and int(restored.version)>int(snapshot.version),"F8 command_facts_full_scope_is_content_equal: the oracle state matches the snapshot except the declared restore version advance: "+str(mismatched))
  var crafted_scope=g.fact_demand_groups(crafted)
  t.check(crafted_scope.size()==groups.size() and "relic" not in crafted_scope and "no_such_group" in crafted_scope,"F8 command_facts_full_scope_is_content_equal: the adversarial closure truly has equal size but different content")
  var reference_rows=reference.command_facts()
  t.check(reference_rows.any(func(row):return String(row.get("group",""))=="relic"),"F8 command_facts_full_scope_is_content_equal: the removed group has real rows, so the pollution comparison is non-vacuous")
  var previous=g._begin_equipment_read()
  g.reset_reuse_counts()
  var cropped=g.command_facts(crafted)
  var builds_after_cropped=g.reuse_builds_of("table")
  var full=g.command_facts()
  var builds_after_full=g.reuse_builds_of("table")
  g._equipment_read=previous
  var want=[]
  for row in reference_rows:
   if String(row.get("group",""))!="relic": want.append(row)
  if builds_after_cropped!=0: problems.append("%s:%d the equal-size non-full demand occupied the batch slot (builds=%d)" % [cell[0],cell[1],builds_after_cropped])
  if builds_after_full!=1: problems.append("%s:%d the following full-group read did not build the table once (builds=%d)" % [cell[0],cell[1],builds_after_full])
  if JSON.stringify(cropped)!=JSON.stringify(want): problems.append("%s:%d the cropped result is not the declared subsequence of the from-zero full rows" % [cell[0],cell[1]])
  if JSON.stringify(full)!=JSON.stringify(reference_rows): problems.append("%s:%d the same-batch full-group read was polluted by the earlier non-full demand" % [cell[0],cell[1]])
 t.check(problems.is_empty(),"F8 command_facts_full_scope_is_content_equal: the equal-size non-full demand never occupies the batch slot and the same-batch full read stays byte-identical to the from-zero projection: "+str(problems.slice(0,3)))
 print("F8 SLOT ADMISSION cells=2 crafted_size=%d full_size=%d" % [crafted.size(),groups.size()])


static func target_queries_read_observer_is_debug_only(t) -> void:
 var observe=source_static_func_body_code("res://ui/target_queries.gd","_debug_observe_read")
 var guard=observe.find("if not OS.is_debug_build() or not _debug_read_observer.is_valid(): return")
 t.check(guard>=0 and observe.find("get_stack()")>guard and observe.find("duplicate(true)")>guard,"F3 target_queries_read_observer_is_debug_only: release/uninstalled paths return before stack capture, event copying or notification")
 var exchange=source_static_func_body_code("res://ui/target_queries.gd","debug_exchange_read_observer")
 t.check(exchange.contains("if not OS.is_debug_build(): return Callable()") and exchange.contains("return previous"),"F3 target_queries_read_observer_is_debug_only: exchange preserves the old Callable and never installs on release")
 var facts=source_static_func_body_code("res://ui/target_queries.gd","facts")
 var key=source_static_func_body_code("res://ui/target_queries.gd","fact_by_key")
 t.check(facts.count("_debug_observe_read(")==1 and key.count("_debug_observe_read(")==1 and key.find("if key==\"\": return {}")<key.find("_debug_observe_read("),"F3 target_queries_read_observer_is_debug_only: exactly the original group/key leaf results notify once; empty-key early return is unchanged")
 var bypass=source_write_sites(["res://ui"],"(?:all_facts\\s*\\(|[.\\[]display_facts\\b|get\\(\\\"display_facts\\\")")
 var stray=write_site_names(bypass).filter(func(name):return name not in ["ui/target_queries.gd::all_facts","ui/target_queries.gd::facts","ui/target_queries.gd::fact_by_key"])
 t.check(stray.is_empty(),"F3 target_queries_read_observer_is_debug_only: external UI cannot bypass the observed leaves with all_facts or direct display_facts: "+str(stray))

# C-F-6: exact human wording; the mask's historical PRE proof stays in the existing frozen interface.
static func contract_text_is_updated_verbatim(t) -> void:
 var contract=source_text("../docs/spec/response-pipeline.md")
 var rows=Array(contract.split("\n")).filter(func(line):return String(line).begins_with("| `game.get_view(demand := [])` |"))
 t.check(rows.size()==1 and String(rows[0]).contains("`view.version` 等于投影来源的已提交 `state.version`；**在不改变实际呈现效果的情况下，尽量降低单次成本**；投影结果不得当规则判定来源"),"F6 contract_text_is_updated_verbatim: the get_view contract adopts the human sentence verbatim exactly once")
 var own=source_text("tests/architecture_cases.gd")
 t.check(not own.contains("const E_VIEW_MASK_"+"ADDED="),"F6 contract_text_is_updated_verbatim: the transitional exclusion table is removed; only the merged R3 mask remains effective")

# ==== S2 双向等价 harness（C3／C4；acceptance.md §2；S3 复用同一函数）====
# 期望侧独立（防自证）：方向①只取该状态 command_facts() 的表行；方向②只做表内归一化 params 的成员扫描，
# 变异语料由本文件按字段级替换独立构造。只有步骤 3（member⟺keys，acceptance §2 明列）向登记项询 keys。
const FACT_LOOKUP_MUTATION_IDS=["missing_enemy","missing_target","missing_uid"]
const FACT_LOOKUP_ID_FIELDS=["enemy","target","uid","relic","item"]

static func fact_lookup_family(g, kind: String, params: Dictionary) -> String:
 if kind=="card":
  var type=String(params.get("type",""))
  var spec=g.Cards.Rules.SPECS.get(type,{})
  if spec.is_empty(): return "unknown"
  if spec.has("free_slots") and String(params.get("target",""))=="" and bool(params.get("free",false)): return "free_slots"
  if spec.has("self_faces") and bool(params.get("self_target",false)): return "self_faces"
  if g.Cards.Rules.single_face(type): return "single_face"
  if String(params.get("target",""))==g.CaptureBind.BIND_TARGET: return "bind"
  return "target_slots"
 if String(params.get("target",""))!="": return "self_release"
 return "witch" if String(params.get("type","")).begins_with("witch_") else "basic"

# S3 card branch flags (plan §7 A1 field families; expected side = SPECS declarations + row params only,
# never the registry). One row can belong to several families; every listed family needs a positive count.
const CARD_BRANCH_FAMILIES=["free_slots","self_faces","single_face","bound_modes","target_slots","x_cost","exhaust_hand_select","exhaust_hand_fallback","bind"]

static func card_branch_flags(g, params: Dictionary) -> Array:
 var flags=[]
 var type=String(params.get("type",""))
 var spec=g.Cards.Rules.SPECS.get(type,{})
 if spec.is_empty(): return flags
 var target=String(params.get("target",""))
 var free=bool(params.get("free",false))
 var self_target=bool(params.get("self_target",false))
 var hand_uid=String(params.get("hand_uid",""))
 var face=spec.get("self_faces",{}).get("free" if free else "bound",{})
 var exhaust=spec.get("exhaust_hand",false) or face.get("exhaust_hand",false)
 if spec.has("free_slots") and target=="" and free: flags.append("free_slots")
 if spec.has("self_faces") and self_target: flags.append("self_faces")
 if g.Cards.Rules.single_face(type): flags.append("single_face")
 if spec.has("bound_modes"): flags.append("bound_modes")
 if target==g.CaptureBind.BIND_TARGET:
  flags.append("bind")
 elif not self_target and not (spec.has("free_slots") and target=="" and free):
  flags.append("target_slots")
 if exhaust and hand_uid!="": flags.append("exhaust_hand_select")
 if exhaust and hand_uid=="": flags.append("exhaust_hand_fallback")
 if spec.get("x_cost",false) and self_target: flags.append("x_cost")
 return flags

# 变异语料＝字段级替换：不存在的 id／未注册 type／清空必填／越界 form／布尔取反／x 与 charge_action 组合。
static func fact_lookup_mutations(kind: String, params: Dictionary, mutation_ids: Array) -> Array:
 var declared=GameCore.COMMAND_KEYS.get(kind,{})
 var out=[]
 for field in FACT_LOOKUP_ID_FIELDS:
  if not declared.has(field) or String(params.get(field,""))=="": continue
  for id in mutation_ids:
   var replaced=params.duplicate(); replaced[field]=id; out.append(replaced)
  var cleared=params.duplicate(); cleared[field]=""; out.append(cleared)
 if declared.has("type"):
  var unregistered=params.duplicate(); unregistered.type="no_such_type"; out.append(unregistered)
  var blank=params.duplicate(); blank.type=""; out.append(blank)
 if declared.has("form"):
  var beyond=params.duplicate(); beyond.form=int(params.get("form",0))+97; out.append(beyond)
 for field in ["all","charge_action","free","enabled"]:
  if not declared.has(field) or typeof(declared[field])!=TYPE_BOOL: continue
  var flipped=params.duplicate(); flipped[field]=not bool(params.get(field,false)); out.append(flipped)
 if declared.has("x"):
  var raised=params.duplicate(); raised.x=int(params.get("x",0))+1; out.append(raised)
  if declared.has("charge_action"):
   var combo=raised.duplicate(); combo.charge_action=not bool(params.get("charge_action",false)); out.append(combo)
 return out

static func fact_lookup_equivalence(t, g, kind: String, mutation_ids: Array, fixture: String, announce: bool=true, table: Variant=null) -> Dictionary:
 # table 可传入调用方已取的整表（同一夹具多 kind 复用时避免重复建表；缺省＝本函数自取，语义不变）。
 var rows=(g.command_facts() if table==null else table).filter(func(row):return String(row.payload.get("kind",""))==kind)
 # 步骤 3 的期望集合（acceptance §2：只此一步询 keys；方向①／②的期望仍只取表与变异语料）。
 # 表形 kind 的登记项没有 keys／build／member（K2 后来源是各域臂），故 B 批起跳过该步。
 var entry=CommandRegistry.entry(kind)
 var point_form=String(entry.get("form",""))=="point"
 var member_name=String(entry.get("member",""))
 var key_set={}
 for candidate in (g.call(String(entry.get("keys","")),g) if point_form else []):
  key_set[JSON.stringify(g.command_params(kind,candidate))]=true
 var coverage={"dir1":0,"dir2":0,"keys":0,"member":0,"duplicates":0,"distinct_duplicates":0,"families":{},"mutation_families":{},"branches":{}}
 var first_of={}
 for index in range(rows.size()):
  var key=JSON.stringify(g.command_params(kind,rows[index].payload))
  if not first_of.has(key): first_of[key]=index
 for index in range(rows.size()):
  var row=rows[index]
  var params=g.command_params(kind,row.payload)
  var key=JSON.stringify(params)
  var first=rows[int(first_of[key])]
  var point=CommandRegistry.point(g,kind,params)
  var found=g.command_fact(g.command(row.payload,g.state.version))
  t.check(found==first and JSON.stringify(found)==JSON.stringify(first),"fact_lookup_equivalence[%s]: direction 1 returns the enumerated row kind=%s index=%d params=%s" % [fixture,kind,index,key])
  t.check(not point.is_empty(),"fact_lookup_equivalence[%s]: direction 2 accepts the table member kind=%s index=%d params=%s" % [fixture,kind,index,key])
  if not point.is_empty() and not FirstTurnControl.active(g):
   t.check(g.display_fact(point)==first,"fact_lookup_equivalence[%s]: direction 2 projects the first table row kind=%s index=%d params=%s" % [fixture,kind,index,key])
  coverage.dir1+=1
  var family=fact_lookup_family(g,kind,params)
  coverage.families[family]=int(coverage.families.get(family,0))+1
  if kind=="card":
   for flag in card_branch_flags(g,params): coverage.branches[flag]=int(coverage.branches.get(flag,0))+1
  if int(first_of[key])!=index:
   coverage.duplicates+=1
   if JSON.stringify(row)!=JSON.stringify(first): coverage.distinct_duplicates+=1
  # 步骤 3（acceptance §2；plan §3 不变量 5）：member 谓词对表行与每个变异向量都必须等于 keys 的归一化集合
  # ——point 由 member∧build 组成，build 会掩盖过宽的 member，故在此直接问谓词。表形 kind 无 member，跳过。
  if point_form:
   t.check(bool(g.call(member_name,g,params))==key_set.has(key),"fact_lookup_equivalence[%s]: member equals the keys set kind=%s params=%s" % [fixture,kind,key])
   coverage.member+=1
  for mutation in fact_lookup_mutations(kind,params,mutation_ids):
   var mutated=g.command_params(kind,mutation)
   var mutated_key=JSON.stringify(mutated)
   var in_table=false
   for other in rows:
    if g.command_params(kind,other.payload)==mutated: in_table=true; break
   var accepted=not CommandRegistry.point(g,kind,mutated).is_empty()
   t.check(accepted==in_table,"fact_lookup_equivalence[%s]: direction 2 mutation agrees with the table kind=%s accepted=%s in_table=%s params=%s" % [fixture,kind,str(accepted),str(in_table),mutated_key])
   if point_form:
    t.check(bool(g.call(member_name,g,mutated))==key_set.has(mutated_key),"fact_lookup_equivalence[%s]: member equals the keys set on the mutation kind=%s params=%s" % [fixture,kind,mutated_key])
    coverage.member+=1
   coverage.dir2+=1
   var mutation_family=fact_lookup_family(g,kind,mutated)
   coverage.mutation_families[mutation_family]=int(coverage.mutation_families.get(mutation_family,0))+1
 # 每个枚举键都必须出现在该状态的表里（防「View 从未提供、直出却接受」）。
 for key in key_set:
  var in_table=false
  for other in rows:
   if JSON.stringify(g.command_params(kind,other.payload))==key: in_table=true; break
  t.check(in_table,"fact_lookup_equivalence[%s]: every enumerated key appears in the table kind=%s params=%s" % [fixture,kind,key])
  coverage.keys+=1
 # C7（gherkin S2-3；两侧都取自登记项，只做「View 生产者 = keys × build」一致性，不替代方向①／②）：
 # 该 kind 的表行序列（含家族顺序）逐项等于 keys 的点构造投影。接管期表行带 select 标注，跳过该步。
 # 表形 kind 没有 keys 枚举，跳过（其唯一枚举是表自身，见 C-B-2 的跨夹具语料层）。
 if point_form and not FirstTurnControl.active(g):
  var built=[]
  for candidate in g.call(String(entry.get("keys","")),g):
   var raw=CommandRegistry.point(g,kind,candidate)
   if not raw.is_empty(): built.append(g.display_fact(raw))
  t.check(built==rows,"fact_lookup_equivalence[%s]: the view rows equal keys times build kind=%s" % [fixture,kind])
 if announce:
  print("FACT LOOKUP fixture=%s kind=%s dir1_rows=%d dir2_mutations=%d keys=%d member=%d duplicates=%d distinct=%d dir1_families=%s dir2_families=%s branches=%s" % [fixture,kind,coverage.dir1,coverage.dir2,coverage.keys,coverage.member,coverage.duplicates,coverage.distinct_duplicates,str(coverage.families),str(coverage.mutation_families),str(coverage.branches)])
 return coverage

# ==== B 批（K2；plan §3 B 段）====
# 全 39 kind 的双向等价 harness（C-B-2；gherkin B-1／B-2）两层：
#  ①逐夹具逐 kind：方向①（点查询 == 该 kind 表内首条 params 命中行）／方向②（变异 params 的接受集 == 表成员集）
#    与点形 kind 的 keys／member 步骤；表形 kind 跳过 keys／member（登记项没有这三个字段，K2 后来源是域臂）。
#  ②跨夹具成员语料：任何夹具里出现过的 params，在该夹具内必须「被接受 ⟺ 是表成员」——逐夹具的变异语料
#    抓不到过宽臂（只在某分支产行的 kind 若在该分支之外仍被接受，在这一层即红）。
# 期望侧独立（acceptance §3）：两个方向的期望都只取自该状态的 command_facts() 行与表行 params，
# 不取自登记项、域臂实现或 keys 枚举。接管夹具不进本矩阵（接管期取行经 TAKEOVER_SOURCE 整表扫描，
# 由 point_query_builds_no_table 的声明豁免与 command_fact_kind_lookup 的接管行等价另证）。
const TABLE_KIND_TAKEOVER_ONLY=["relic_control_done"]
# 跨夹具成员语料：每个 kind 最多保留 CROSS_FIXTURE_CORPUS_CAP 个来自不同夹具的归一化 params（打印实际条数，
# 不静默截断）；阶段②对每个夹具每 kind 至多探测 CROSS_FIXTURE_PROBES_PER_KIND 条「来自别的分支」的语料。
const CROSS_FIXTURE_CORPUS_CAP=16
const CROSS_FIXTURE_PROBES_PER_KIND=2
# r1_cells 的装配件数维度：本 harness 取 0／12 两档，稠密档由 t4_dense_51()（51 件、334 行）承担
# ——表形 kind 的行数与分支面在这两处已覆盖，26／44 档由 attack／card 的点形 harness 与 G6 基线各自覆盖。
const FACT_LOOKUP_ALL_KIND_COUNTS=[0,12]

static func fact_lookup_all_kind_fixtures() -> Array:
 var out=[]
 for cell in r1_cells():
  if cell[0]=="takeover" or cell[1] not in FACT_LOOKUP_ALL_KIND_COUNTS: continue
  out.append(["%s:%d" % [cell[0],cell[1]],r1_build(cell[0],cell[1])])
 out.append(["dense_51",t4_dense_51()])
 for entry in branch_sweep_states(): out.append([String(entry.label),entry.game])
 return out

# 该状态下该 kind 的表成员集（归一化 params 的集合；期望侧只取表行）。
static func fact_lookup_table_keys(g, kind: String, table: Variant=null) -> Dictionary:
 var out={}
 var rows=(g.command_facts() if table==null else table)
 for row in rows:
  if String(row.payload.get("kind",""))!=kind: continue
  out[JSON.stringify(g.command_params(kind,row.payload))]=g.command_params(kind,row.payload)
 return out

static func fact_lookup_all_kinds(t) -> void:
 var fixtures=fact_lookup_all_kind_fixtures()
 var tables=[]
 for entry in fixtures: tables.append(entry[1].command_facts())
 var corpus={}
 var corpus_total={}
 var presence={}
 for index in range(fixtures.size()):
  var g=fixtures[index][1]
  var branch=g._phase_branch()
  for kind in GameCore.COMMAND_KEYS:
   var keys=fact_lookup_table_keys(g,kind,tables[index])
   if not keys.is_empty(): presence[kind]=int(presence.get(kind,0))+1
   for key in keys:
    corpus_total[kind]=int(corpus_total.get(kind,0))+1
    var list=corpus.get(kind,[])
    var duplicated=list.any(func(row):return JSON.stringify(row.params)==key)
    if not duplicated and list.size()<CROSS_FIXTURE_CORPUS_CAP: list.append({"branch":branch,"params":keys[key]})
    corpus[kind]=list
 var totals={"dir1":0,"dir2":0,"keys":0,"member":0,"duplicates":0}
 var compared=0
 for index in range(fixtures.size()):
  var g=fixtures[index][1]
  for kind in GameCore.COMMAND_KEYS:
   var coverage=fact_lookup_equivalence(t,g,kind,FACT_LOOKUP_MUTATION_IDS,String(fixtures[index][0]),false,tables[index])
   for field in totals: totals[field]=int(totals[field])+int(coverage[field])
   compared+=1
 t.check(compared==fixtures.size()*GameCore.COMMAND_KEYS.size(),"fact_lookup_all_kinds: every fixture x kind pair was compared have="+str(compared)+" want="+str(fixtures.size()*GameCore.COMMAND_KEYS.size()))
 t.check(int(totals.dir1)>0 and int(totals.dir2)>0 and int(totals.keys)>0 and int(totals.member)>0,"fact_lookup_all_kinds: the harness compared rows, mutations, enumerated keys and member predicates: "+str(totals))
 # 覆盖非空（缺夹具即红）：除只由接管注入的 kind 外，每个 kind 必须在某个夹具的表里产行。
 var empty=[]
 for kind in GameCore.COMMAND_KEYS:
  if int(presence.get(kind,0))==0 and kind not in TABLE_KIND_TAKEOVER_ONLY: empty.append(kind)
 t.check(empty.is_empty(),"fact_lookup_all_kinds: every kind except the takeover-only one appears in the table matrix (missing fixtures): "+str(empty))
 var batch_gaps=batch_kind_sources().keys().filter(func(kind):return not presence.has(kind) and kind not in TABLE_KIND_TAKEOVER_ONLY)
 t.check(batch_gaps.is_empty(),"fact_lookup_all_kinds: every one of the 23 rebased kinds is exercised by the matrix: "+str(batch_gaps))
 t.check(presence.size()>=38,"fact_lookup_all_kinds: the fixture matrix exercises every kind but the takeover-only one have="+str(presence.size()))
 # ②跨夹具成员语料（抓过宽臂）：每个夹具 × 每个 kind 用「来自别的分支」的语料向量探测至多 CROSS_FIXTURE_PROBES_PER_KIND 条，
 # 断言「接受 ⟺ 是表成员」。语料条数与探测数逐项打印，不静默截断。
 var cross_problems=[]
 var cross_compared=0
 for index in range(fixtures.size()):
  var g=fixtures[index][1]
  var branch=g._phase_branch()
  var member={}
  for kind in GameCore.COMMAND_KEYS: member[kind]=fact_lookup_table_keys(g,kind,tables[index])
  for kind in GameCore.COMMAND_KEYS:
   var probes=corpus.get(kind,[]).filter(func(row):return String(row.branch)!=branch)
   var used=0
   for row in probes:
    if used>=CROSS_FIXTURE_PROBES_PER_KIND: break
    used+=1
    var normalized=g.command_params(kind,row.params)
    var accepted=not CommandRegistry.point(g,kind,normalized).is_empty()
    cross_compared+=1
    if accepted!=member[kind].has(JSON.stringify(normalized)): cross_problems.append("%s:%s accepted=%s in_table=%s params=%s" % [String(fixtures[index][0]),kind,str(accepted),str(member[kind].has(JSON.stringify(normalized))),JSON.stringify(normalized)])
 t.check(cross_problems.is_empty(),"fact_lookup_all_kinds: the cross-fixture member corpus agrees with the table (over-wide arms redden here): "+str(cross_problems.slice(0,6)))
 t.check(cross_compared>0,"fact_lookup_all_kinds: the cross-fixture corpus compared at least one vector per exercised kind have="+str(cross_compared))
 # ③域臂行集 ⊆ 该夹具的表行集：参数无关的臂（state 派生行）在它不该产行的分支里若仍产行即红——逐夹具的变异语料
 # 抓不到这一类（跨夹具 params 在本夹具里天然不命中），故单列一层，每夹具每 kind 只调一次臂。
 var arm_problems=[]
 var arm_compared=0
 for index in range(fixtures.size()):
  var g=fixtures[index][1]
  for kind in GameCore.COMMAND_KEYS:
   var source=String(CommandRegistry.entry(kind).get("source",""))
   if source.is_empty(): continue
   var vector=corpus.get(kind,[])
   var canonical=g.command_params(kind,{} if vector.is_empty() else vector[0].params)
   var table_params=fact_lookup_table_keys(g,kind,tables[index])
   for raw in g.call(source,kind,canonical):
    if String(raw.payload.get("kind",""))!=kind: continue
    var normalized=g.command_params(kind,raw.payload)
    arm_compared+=1
    if not table_params.has(JSON.stringify(normalized)): arm_problems.append("%s:%s arm row outside the table params=%s" % [String(fixtures[index][0]),kind,JSON.stringify(normalized)])
 t.check(arm_problems.is_empty(),"fact_lookup_all_kinds: every domain arm row is a table row of the same fixture (a state-derived arm that ignores its branch reddens here): "+str(arm_problems.slice(0,6)))
 t.check(arm_compared>0,"fact_lookup_all_kinds: the arm row-set layer compared at least one arm row have="+str(arm_compared))
 print("FACT LOOKUP ALL KINDS fixtures=%d pairs=%d dir1_rows=%d dir2_mutations=%d keys=%d member=%d corpus_kinds=%d cross=%d arm_rows=%d kinds_with_rows=%d" % [fixtures.size(),compared,totals.dir1,totals.dir2,totals.keys,totals.member,corpus_total.size(),cross_compared,arm_compared,presence.size()])

# ==== B 批（K2）判据：域臂守卫、点查询不建整表、分支/前缀态冻结 ====
# 域臂守卫的期望侧（缺口 2；A 批审查归 B 批）：23 项新域臂（16 个方法）必须经 _phase_branch() 取分支——
# 判据扫的是域臂体（不只 _phase_facts 体），所以「在臂里各抄一份早退链」拿不到绿灯。9 个 K0 之前的窄来源
# 用 domain 合成守卫（command_domain_ready／command_tail／相位守卫），逐条豁免并双向核对：列了却没豁免、
# 没列却豁免都红（豁免不能腐烂）。期望侧写在本文件，不取自登记表。
const BATCH_ARM_SOURCES=["_chain_kind_facts","_manual_kind_facts","_hook_kind_facts","_item_action_kind_facts","_retain_kind_facts","_rest_choice_kind_facts","_services_kind_facts","_events_kind_facts","_prison_kind_facts","_depart_kind_facts","_reward_kind_facts","_relic_bundle_kind_facts","_departure_kind_facts","_travel_step_kind_facts","_demo_exit_kind_facts","_relic_control_done_kind_facts"]
const PHASE_BRANCH_ARM_EXEMPT=["_flow_kind_facts","_relic_kind_facts","_wall_move_kind_facts","_surrender_kind_facts","_status_toggle_kind_facts","_posture_kind_facts","_item_use_kind_facts","_item_discard_kind_facts","_flask_kind_facts"]
# 恒空臂（不选分支故不该有守卫）：接管结束行只由 FirstTurnControl.select 注入，非接管期的整表里没有这个 kind
# 的行——"它在任何分支都不产行"由 fact_lookup_all_kinds 的 TABLE_KIND_TAKEOVER_ONLY 覆盖断言证明。
const BATCH_ARM_GUARDLESS=["_relic_control_done_kind_facts"]

# kind → 域臂（被测实现；身份由 domain_arm_guards_call_phase_branch 的双向核对与 FROZEN_TABLE_SOURCES 钉住）。
static func batch_kind_sources() -> Dictionary:
 var out={}
 for kind in table_kinds():
  var source=String(CommandRegistry.entry(kind).get("source",""))
  if source in BATCH_ARM_SOURCES: out[kind]=source
 return out

# 全部 table 形 kind 的来源臂（去重；含 9 个 K0 之前的窄来源），顺序＝kind 声明序。
static func table_arm_sources() -> Array:
 var out=[]
 for kind in table_kinds():
  var source=String(CommandRegistry.entry(kind).get("source",""))
  if source!="" and source not in out: out.append(source)
 return out

# 文件里的函数名全集（源码文本：行首 func／static func；供「臂体调用了哪些本地函数」的双向核对）。
static func source_func_names(relative: String) -> Array:
 var pattern=RegEx.new()
 var names=[]
 if pattern.compile("(?m)^(?:static\\s+)?func\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")!=OK: return names
 for found in pattern.search_all(source_text(relative)): names.append(found.get_string(1))
 return names

# 缺口 2（归 B 批）：每个域臂的守卫必须调用 _phase_branch()（域臂体，不只 _phase_facts 体）。
static func domain_arm_guards_call_phase_branch(t) -> void:
 var sources={}
 for kind in table_kinds(): sources[String(CommandRegistry.entry(kind).get("source",""))]=kind
 var missing=BATCH_ARM_SOURCES.filter(func(name):return not sources.has(name))
 var extra=sources.keys().filter(func(name):return name not in BATCH_ARM_SOURCES and name not in PHASE_BRANCH_ARM_EXEMPT)
 t.check(missing.is_empty() and extra.is_empty(),"domain_arm_guards_call_phase_branch: every table entry is either a declared domain arm or a named pre-K0 exemption (two-way): missing="+str(missing)+" extra="+str(extra))
 var unguarded=[]
 var guardless_with_branch=[]
 for name in BATCH_ARM_SOURCES:
  if not sources.has(name): continue
  var body=source_func_body_code("res://core/game.gd",name)
  var guarded=body.find("_phase_branch(")>=0
  if not guarded and name not in BATCH_ARM_GUARDLESS: unguarded.append(name)
  if guarded and name in BATCH_ARM_GUARDLESS: guardless_with_branch.append(name)
 t.check(unguarded.is_empty(),"domain_arm_guards_call_phase_branch: every domain arm takes its branch from _phase_branch() (a copied early-return chain is never the guard): "+str(unguarded))
 t.check(guardless_with_branch.is_empty(),"domain_arm_guards_call_phase_branch: the declared branchless (always empty) arm cannot rot: "+str(guardless_with_branch))
 for name in BATCH_ARM_GUARDLESS:
  var body=source_func_body_code("res://core/game.gd",name)
  t.check(body.strip_edges()=="return []","domain_arm_guards_call_phase_branch: the branchless arm stays a constant empty answer (no branch, no producer): "+name+" body="+body.strip_edges())
 var stale=PHASE_BRANCH_ARM_EXEMPT.filter(func(name):return sources.has(name) and source_func_body_code("res://core/game.gd",name).find("_phase_branch(")>=0)
 t.check(stale.is_empty(),"domain_arm_guards_call_phase_branch: the exemption list cannot rot (an exempt arm that starts guarding is red): "+str(stale))
 t.check(BATCH_ARM_SOURCES.size()==16 and PHASE_BRANCH_ARM_EXEMPT.size()==9 and BATCH_ARM_GUARDLESS.size()==1,"domain_arm_guards_call_phase_branch: the declared arm sets keep their size (16 domain arms + 9 pre-K0 exemptions + 1 branchless arm)")
 print("DOMAIN ARM GUARDS arms=%d exempt=%d guardless=%d unguarded=0" % [BATCH_ARM_SOURCES.size(),PHASE_BRANCH_ARM_EXEMPT.size(),BATCH_ARM_GUARDLESS.size()])

# C-B-4（K2；gherkin B-4）：整表来源不再是点查询的答案——登记表文本不再出现整表来源名；每个 table kind 的
# 臂体不调 _fact_source()／command_facts()；_kind_facts 与 _item_use_kind_facts 无整表回落；23 项把 source
# 指回自己的域臂（少改／多改都红）。FROZEN_TABLE_SOURCES 的 23 项同批 rebase（old→new 见其注释）。
# B 批审查条目 2（归 C 批）加固：kinds=37／arms=16 由打印改为断言；文本扫描扩到被调 helper（白名单双向
# 核对：臂体新调一个本地函数而没进表 ＝ 未扫描的间接调用，即红；改名致 helper 体提取为空 ＝ 红）。
const POINT_SOURCE_TABLE_KINDS=37
const POINT_SOURCE_DOMAIN_ARMS=16
const POINT_SOURCE_ARMS_TOTAL=25
const TABLE_ARM_HELPERS=["_fact","_fact_source_domain","_item","_phase_action_tail","_phase_branch","_phase_facts","_route_facts","_status_toggle_facts","_unit_rest_choice","_unit_reward","_unit_travel_step","command_domain_ready","flow_facts","hook_facts","item_action_block","item_action_facts","item_discard_facts","manual_facts","posture_facts","retain_facts","surrender_fact","wall_move_facts"]
const TABLE_ARM_WHOLE_TABLE_CALLS=["_fact_source(","command_facts(","_join_fact_units(","_phase_branch_units("]
# 声明豁免：_flow_kind_facts 的 overload_climax 分支按设计返回该分支自己的单元生产者（_phase_facts）——
# 它不是整表出口，且运行期由 point_query_builds_no_table 的计数豁免（恰 1 次）钉住（豁免不能腐烂：无臂调用即红）。
const TABLE_ARM_HELPER_EXEMPT=["_phase_facts"]

static func point_sources_are_kind_limited(t) -> void:
 var registry=source_text("core/command_registry.gd")
 t.check(not registry.contains("_whole_table_kind_facts"),"point_sources_are_kind_limited: no registry entry names the whole-table source any more")
 var bad=[]
 for kind in table_kinds():
  var source=String(CommandRegistry.entry(kind).get("source",""))
  if source.is_empty():
   bad.append(kind+"=<empty>")
   continue
  var body=source_func_body_code("res://core/game.gd",source)
  if body.strip_edges().is_empty(): bad.append(kind+":"+source+"=<no body>")
  elif body.find("_fact_source(")>=0 or body.find("command_facts(")>=0: bad.append(kind+":"+source+"=whole-table call")
 t.check(bad.is_empty(),"point_sources_are_kind_limited: every table arm answers from its own producer (no whole-table call in the point path): "+str(bad))
 var kind_body=source_func_body_code("res://core/game.gd","_kind_facts")
 t.check(not kind_body.strip_edges().is_empty() and kind_body.find("_fact_source(")<0,"point_sources_are_kind_limited: _kind_facts never falls back to _fact_source()")
 var item_use_body=source_func_body_code("res://core/game.gd","_item_use_kind_facts")
 t.check(not item_use_body.strip_edges().is_empty() and item_use_body.find("_fact_source(")<0,"point_sources_are_kind_limited: the item_use arm keeps no whole-table residual")
 var batch=batch_kind_sources()
 var arms=table_arm_sources()
 t.check(batch.size()==23,"point_sources_are_kind_limited: the 23 rebased kinds stay on their domain arms have="+str(batch.size()))
 t.check(table_kinds().size()==POINT_SOURCE_TABLE_KINDS and BATCH_ARM_SOURCES.size()==POINT_SOURCE_DOMAIN_ARMS and arms.size()==POINT_SOURCE_ARMS_TOTAL,"point_sources_are_kind_limited: the table-kind count, the domain-arm set and the total arm set keep their frozen sizes: kinds="+str(table_kinds().size())+" domain_arms="+str(BATCH_ARM_SOURCES.size())+" arms="+str(arms.size())+" want="+str([POINT_SOURCE_TABLE_KINDS,POINT_SOURCE_DOMAIN_ARMS,POINT_SOURCE_ARMS_TOTAL]))
 var bodies={}
 var missing_helpers=[]
 for name in TABLE_ARM_HELPERS:
  var body=source_func_body_code("res://core/game.gd",name)
  bodies[name]=body
  if body.strip_edges().is_empty(): missing_helpers.append(name)
 t.check(missing_helpers.is_empty(),"point_sources_are_kind_limited: every whitelisted arm helper body is extracted (a rename must not silently empty the scan): "+str(missing_helpers))
 var indirect=[]
 for name in bodies:
  if name in TABLE_ARM_HELPER_EXEMPT: continue
  for needle in TABLE_ARM_WHOLE_TABLE_CALLS:
   if String(bodies[name]).find(needle)>=0: indirect.append(name+"->"+needle)
 t.check(indirect.is_empty(),"point_sources_are_kind_limited: no arm helper reaches a whole-table form (an indirect whole-table call is red): "+str(indirect))
 var declared_names=source_func_names("core/game.gd")
 var unlisted=[]
 for arm in arms:
  var body=source_func_body_code("res://core/game.gd",arm)
  for candidate in declared_names:
   if candidate==arm or arm.ends_with(candidate) or candidate in TABLE_ARM_HELPERS: continue
   if body.find(candidate+"(")>=0: unlisted.append(arm+"->"+candidate)
 t.check(unlisted.is_empty(),"point_sources_are_kind_limited: every local function an arm calls is on the scanned helper list (an unlisted indirection would escape the whole-table scan): "+str(unlisted))
 var stale_exempt=TABLE_ARM_HELPER_EXEMPT.filter(func(name):return not arms.any(func(arm):return source_func_body_code("res://core/game.gd",arm).find(name+"(")>=0))
 t.check(stale_exempt.is_empty(),"point_sources_are_kind_limited: the declared helper exemption cannot rot (an exempt helper no arm calls is red): "+str(stale_exempt))
 print("POINT SOURCES KIND LIMITED kinds=%d arms=%d known=%d helpers=%d exempt=%d" % [table_kinds().size(),BATCH_ARM_SOURCES.size(),batch.size(),TABLE_ARM_HELPERS.size(),TABLE_ARM_HELPER_EXEMPT.size()])

# 域臂守卫的分支 id 正确性（B 批审查条目 2／4）：两层判据——
# ① 文本层（双向）：每个域臂体点名的分支 id 字面恰等于声明的守卫集合（缺一个／多一个都红；两个臂互换守卫
#    在此层即红，因为各自会点名对方的分支 id）；
# ② 运行期：夹具矩阵上臂产出的行必须落在该臂声明的**运行期**分支集合内（行 ⇒ 分支 ∈ 声明），且逐臂逐分支
#    都必须在矩阵里被观测到行（声明不能腐烂）。
# 两处集合只有一处差异（已声明）：_depart_kind_facts 的 map 行由 match 的兜底臂给出（_route_facts 在 map
# 相位对空输入也产行），故运行期集合把守卫字面里的 action_tail 换成 map。声明侧都是本文件字面期望。
const DOMAIN_ARM_BRANCH_IDS={
 "_chain_kind_facts":["card_chain"],
 "_manual_kind_facts":["action_tail"],
 "_hook_kind_facts":["action_tail"],
 "_item_action_kind_facts":["action_tail","pack"],
 "_retain_kind_facts":["pending_retain"],
 "_rest_choice_kind_facts":["rest_choice"],
 "_services_kind_facts":["shop_treasure"],
 "_events_kind_facts":["event"],
 "_prison_kind_facts":["captured_inspection","action_tail"],
 "_depart_kind_facts":["shop_treasure","event","action_tail","pack"],
 "_reward_kind_facts":["reward"],
 "_relic_bundle_kind_facts":["relic_bundle"],
 "_departure_kind_facts":["departure"],
 "_travel_step_kind_facts":["travel"],
 "_demo_exit_kind_facts":["cleared"],
 "_relic_control_done_kind_facts":[],
}
const DOMAIN_ARM_ROW_BRANCHES={
 "_chain_kind_facts":["card_chain"],
 "_manual_kind_facts":["action_tail"],
 "_hook_kind_facts":["action_tail"],
 "_item_action_kind_facts":["action_tail","pack"],
 "_retain_kind_facts":["pending_retain"],
 "_rest_choice_kind_facts":["rest_choice"],
 "_services_kind_facts":["shop_treasure"],
 "_events_kind_facts":["event"],
 "_prison_kind_facts":["captured_inspection","action_tail"],
 "_depart_kind_facts":["map","shop_treasure","event","action_tail","pack"],
 "_reward_kind_facts":["reward"],
 "_relic_bundle_kind_facts":["relic_bundle"],
 "_departure_kind_facts":["departure"],
 "_travel_step_kind_facts":["travel"],
 "_demo_exit_kind_facts":["cleared"],
 "_relic_control_done_kind_facts":[],
}
# 9 个 K0 之前的窄来源用 domain 合成守卫（不是分支守卫）：本判据不含分支 id 期望，逐条在此声明并与
# domain_arm_guards_call_phase_branch 的豁免面同集合（任一侧漏列／多列即红）；其残差登记进依赖索引的「仍靠人审」。
const DOMAIN_ARM_DOMAIN_GUARDED=PHASE_BRANCH_ARM_EXEMPT
# 已在夹具矩阵里观测不到行的声明分支（逐条登记，双向核对）：_depart_kind_facts 的 shop／event 出口行需要
# 「服务／事件已产出离开行」的夹具，本矩阵（26 cell 的 0／12 ＋ 63 个分支态）里没有这样的商店／事件——
# 该臂在这两个分支的行面因此无机械证据，登记为「仍靠人审」（观测到即表示本行过期，红）。
const DOMAIN_ARM_ROW_BRANCHES_UNOBSERVED=["_depart_kind_facts@shop_treasure","_depart_kind_facts@event"]
# 运行期矩阵：26 cell 的 0／12 两档（含 shop／treasure／event／prison 相位）＋ branch_sweep_states() 的
# 全部相位/前缀/标志态（与 B 批冻结矩阵同一份声明）。
static func arm_branch_fixtures() -> Array:
 var out=[]
 for cell in r1_cells():
  if cell[0]=="takeover" or cell[1] not in FACT_LOOKUP_ALL_KIND_COUNTS: continue
  out.append(["%s:%d" % [cell[0],cell[1]],r1_build(cell[0],cell[1])])
 for sweep in branch_sweep_states(): out.append([String(sweep.label),sweep.game])
 return out

static func domain_arm_branch_ids_are_pinned(t) -> void:
 var arms=table_arm_sources()
 var missing=DOMAIN_ARM_BRANCH_IDS.keys().filter(func(name):return name not in arms)
 var extra=arms.filter(func(name):return not DOMAIN_ARM_BRANCH_IDS.has(name) and name not in DOMAIN_ARM_DOMAIN_GUARDED)
 t.check(missing.is_empty() and extra.is_empty(),"domain_arm_branch_ids_are_pinned: every table arm is either branch-guarded with a declared branch-id expectation or a declared domain-guarded exemption (two-way): missing="+str(missing)+" extra="+str(extra))
 t.check(DOMAIN_ARM_BRANCH_IDS.size()==POINT_SOURCE_DOMAIN_ARMS and DOMAIN_ARM_ROW_BRANCHES.size()==POINT_SOURCE_DOMAIN_ARMS and arms.size()==POINT_SOURCE_ARMS_TOTAL,"domain_arm_branch_ids_are_pinned: both expectation tables cover every branch-guarded arm and the arm sets keep their sizes: "+str(DOMAIN_ARM_BRANCH_IDS.size())+"/"+str(DOMAIN_ARM_ROW_BRANCHES.size())+" arms="+str(arms.size()))
 var text=[]
 for name in DOMAIN_ARM_BRANCH_IDS:
  if name not in arms: continue
  var body=source_func_body_code("res://core/game.gd",name)
  if body.strip_edges().is_empty(): text.append(name+"=<no body>"); continue
  for branch in DOMAIN_ARM_BRANCH_IDS[name]:
   if body.find("\""+String(branch)+"\"")<0: text.append(name+": guard never names "+String(branch))
  for branch in PHASE_BRANCH_VOCABULARY:
   if branch in DOMAIN_ARM_BRANCH_IDS[name]: continue
   if body.find("\""+String(branch)+"\"")>=0: text.append(name+": guards on undeclared branch "+String(branch))
 t.check(text.is_empty(),"domain_arm_branch_ids_are_pinned: each arm's guard names exactly its declared branch ids (two-way, source text): "+str(text.slice(0,6)))
 var fixtures=arm_branch_fixtures()
 var observed={}
 var runtime=[]
 var arm_rows=0
 for entry in fixtures:
  var g=entry[1]
  var branch=g._phase_branch()
  for kind in table_kinds():
   var source=String(CommandRegistry.entry(kind).get("source",""))
   if source.is_empty() or not DOMAIN_ARM_BRANCH_IDS.has(source): continue
   var canonical=g.command_params(kind,{})
   for raw in g.call(source,kind,canonical):
    if String(raw.payload.get("kind",""))!=kind: continue
    arm_rows+=1
    if not observed.has(source): observed[source]={}
    observed[source][branch]=true
    if branch not in DOMAIN_ARM_ROW_BRANCHES[source]: runtime.append("%s:%s branch=%s" % [String(entry[0]),source,String(branch)])
 t.check(runtime.is_empty(),"domain_arm_branch_ids_are_pinned: every arm row appears in one of its declared branches (a wrong branch id is red at runtime): "+str(runtime.slice(0,6)))
 t.check(arm_rows>0,"domain_arm_branch_ids_are_pinned: the runtime layer compared at least one arm row have="+str(arm_rows))
 var unobserved=[]
 var registered=DOMAIN_ARM_ROW_BRANCHES_UNOBSERVED
 for name in DOMAIN_ARM_ROW_BRANCHES:
  for branch in DOMAIN_ARM_ROW_BRANCHES[name]:
   var pair=name+"@"+String(branch)
   var seen=observed.get(name,{}).has(branch)
   if not seen and pair not in registered: unobserved.append(pair)
   if seen and pair in registered: unobserved.append(pair+"=<registered but observed>")
 t.check(unobserved.is_empty(),"domain_arm_branch_ids_are_pinned: every declared runtime branch is observed with rows in the fixture matrix or registered as unobservable (the declaration cannot rot, two-way): "+str(unobserved))
 var stale_arms=[]
 for pair in DOMAIN_ARM_ROW_BRANCHES_UNOBSERVED:
  var parts=String(pair).split("@")
  if parts.size()!=2 or not DOMAIN_ARM_ROW_BRANCHES.has(parts[0]) or parts[1] not in DOMAIN_ARM_ROW_BRANCHES[parts[0]]: stale_arms.append(String(pair))
 t.check(stale_arms.is_empty(),"domain_arm_branch_ids_are_pinned: every unobserved registration names a declared arm/branch pair: "+str(stale_arms))
 var branchless=DOMAIN_ARM_ROW_BRANCHES.keys().filter(func(name):return DOMAIN_ARM_ROW_BRANCHES[name].is_empty())
 t.check(branchless==BATCH_ARM_GUARDLESS and not observed.has("_relic_control_done_kind_facts"),"domain_arm_branch_ids_are_pinned: the declared branchless arm stays row-free everywhere: "+str(branchless))
 print("DOMAIN ARM BRANCH IDS arms=%d fixtures=%d arm_rows=%d runtime_problems=%d unobserved=%d" % [arms.size(),fixtures.size(),arm_rows,runtime.size(),unobserved.size()])

# C-B-3（K2；gherkin B-3）：点查询不建整表——测试侧计数子类逐次统计整表出口与其三个连接入口
# （_fact_source／command_facts／_join_fact_units／_phase_branch_units／_phase_facts 直调）；可行动期
# 每个 table 形 kind 的**每条**表行都做一次 command_fact，五路计数必须全为 0；接管期按声明豁免
# （走 TAKEOVER_SOURCE 整表扫描＝1，与今天相同）；覆盖非空：23 项新域臂里至少 POINT_LOOKUP_COVERAGE_FLOOR
# 项在夹具矩阵上命中非空行（全 0 即红）。
# B 批审查条目 1（归 C 批）加固：计数面扩到三个连接入口、样本改为覆盖每 kind 的全部行、修掉恒假子句；
# 唯一一处相位单元计数豁免＝_flow_kind_facts 在 overload_climax 分支对 kind=="end" 返回该分支自己的单元
# （_phase_facts＝该分支的单元连接），逐条断言恰为 1 且必须被观测到（豁免不能腐烂）。
const POINT_LOOKUP_COVERAGE_FLOOR=15
const POINT_LOOKUP_PHASE_UNIT_EXEMPT={"end":"overload_climax"}

static func point_query_builds_no_table(t) -> void:
 var fixtures=[]
 for cell in r1_cells():
  if cell[0]=="takeover" or cell[1] not in FACT_LOOKUP_ALL_KIND_COUNTS: continue
  fixtures.append(["%s:%d" % [cell[0],cell[1]],r1_build(cell[0],cell[1],PointLookupCountingGame)])
 for sweep in branch_sweep_states(PointLookupCountingGame): fixtures.append([String(sweep.label),sweep.game])
 var kinds=table_kinds()
 var hits={}
 var exempt_hits={}
 var compared=0
 var rows_seen=0
 var problems=[]
 for entry in fixtures:
  var g=entry[1]
  var table=g.command_facts()
  var tested={}
  for row in table:
   var kind=String(row.payload.get("kind",""))
   if kind not in kinds: continue
   rows_seen+=1
   var key=kind+"|"+JSON.stringify(g.command_params(kind,row.payload))
   if tested.has(key): continue
   tested[key]=true
   var branch=g._phase_branch()
   var exempt=String(POINT_LOOKUP_PHASE_UNIT_EXEMPT.get(kind,""))==branch
   if exempt: exempt_hits[kind]=true
   g.reset_point_lookup_counts()
   var found=g.command_fact(g.command(row.payload,g.state.version))
   compared+=1
   if String(CommandRegistry.entry(kind).get("source","")) in BATCH_ARM_SOURCES: hits[kind]=true
   var want=1 if exempt else 0
   if not (found==row and g.fact_source_calls==0 and g.command_facts_calls==0 and g.join_units_calls==want and g.branch_units_calls==want and g.phase_facts_calls==want):
    problems.append("%s:%s branch=%s fact_source=%d command_facts=%d join=%d branch_units=%d phase_facts=%d equal=%s" % [String(entry[0]),kind,branch,g.fact_source_calls,g.command_facts_calls,g.join_units_calls,g.branch_units_calls,g.phase_facts_calls,str(found==row)])
 t.check(problems.is_empty(),"point_query_builds_no_table: one command_fact answers from the kind arm without building the table or its units (the only declared phase-unit exemption is exactly one build): "+str(problems.slice(0,6)))
 t.check(compared>0 and rows_seen>=compared,"point_query_builds_no_table: the fixture matrix answered every distinct table row of every kind have="+str(compared)+" rows="+str(rows_seen))
 var covered=hits.keys().filter(func(kind):return batch_kind_sources().has(kind))
 t.check(covered.size()>=POINT_LOOKUP_COVERAGE_FLOOR,"point_query_builds_no_table: at least "+str(POINT_LOOKUP_COVERAGE_FLOOR)+" of the 23 rebased kinds hit a non-empty row have="+str(covered.size())+" "+str(covered))
 var stale_exempt=POINT_LOOKUP_PHASE_UNIT_EXEMPT.keys().filter(func(kind):return not exempt_hits.has(kind))
 t.check(stale_exempt.is_empty(),"point_query_builds_no_table: the declared phase-unit exemption is observed in the matrix (an unused exemption is red): "+str(stale_exempt))
 # 接管期声明豁免：select 标注的那一步仍经 TAKEOVER_SOURCE 的整表扫描一次（与改动前相同）；relic_control_done
 # 的行只由 FirstTurnControl.select 注入，点查询路径对它恒为空（臂体恒空，见 domain_arm_guards_call_phase_branch）。
 var takeover=r1_build("takeover",0,PointLookupCountingGame)
 var automated={}
 for candidate in takeover.command_facts():
  if bool(candidate.get("automated",false)): automated=candidate; break
 t.check(not automated.is_empty(),"point_query_builds_no_table: the takeover fixture carries the step selected by FirstTurnControl.select")
 t.check(CommandRegistry.point(takeover,"relic_control_done",{}).is_empty(),"point_query_builds_no_table: the relic_control_done arm stays empty (the injected row is never answered by the point path)")
 takeover.reset_point_lookup_counts()
 var found=takeover.command_fact(takeover.command(automated.payload,takeover.state.version))
 t.check(found==automated,"point_query_builds_no_table: the takeover phase answers the selected row")
 t.check(takeover.command_facts_calls==1 and takeover.fact_source_calls==1,"point_query_builds_no_table: the takeover exemption is exactly one declared whole-table build: command_facts="+str(takeover.command_facts_calls)+" fact_source="+str(takeover.fact_source_calls))
 print("POINT QUERY NO TABLE fixtures=%d rows=%d distinct_answered=%d rebased_covered=%d phase_unit_exempt=%s takeover_builds=1" % [fixtures.size(),rows_seen,compared,covered.size(),str(exempt_hits.keys())])

# 缺口 1（A 批审查归 B 批）：冻结矩阵扩到前缀/分支态。26 cell 不含前缀态（relic_bundle／departure／
# domain_blocked）与 rest_choice／reward／travel／map／cleared／pack 等分支，前缀零移动此前只有 build/ 的
# 差分探针能证（仓库内不可重放）。本判据把 branch_sweep_states() 的每个状态逐条冻结成行面摘要：
# 期望侧＝B 批动工前实测值（写在测试内，不取自实现）；状态集合与规模双向核对（缺一个／多一个都红）。
# 出处自证（B 批审查条目 3）：下表在本批动工前的 core/game.gd 字节上实测，其 sha256 见
# PREFIX_BRANCH_TABLE_SOURCE_SHA256；复核者按同一 sha256 的源码重跑 branch_sweep_states() 即可重算。
const PREFIX_BRANCH_TABLE_SOURCE_SHA256="1AFA055BFB84119B6B8BA34B46C67C62BDBF6ADB9E77BDF9B7F1F2A71B8DE76A"
# 状态数（字面）：branch_sweep_states() 与下表都必须恰为这个数——「删一态＋同步删基线」在此红。
const PREFIX_BRANCH_TABLE_STATE_COUNT=63
const PREFIX_BRANCH_TABLE_BASELINE={
 "sweep:departure|plain":["departure","8","0a2f9d0dde945abd70b6d831f6e00ea0"],
 "sweep:departure|relic_bundle":["relic_bundle","9","db85dae4e279769ca6bbe9a1daa3a82d"],
 "sweep:departure|departure":["departure","8","0a2f9d0dde945abd70b6d831f6e00ea0"],
 "sweep:departure|domain_blocked":["departure","8","0a2f9d0dde945abd70b6d831f6e00ea0"],
 "sweep:rest_choice|plain":["rest_choice","8","98abf02bd8fdb98609908f6b14442e6a"],
 "sweep:rest_choice|relic_bundle":["relic_bundle","9","db85dae4e279769ca6bbe9a1daa3a82d"],
 "sweep:rest_choice|departure":["rest_choice","8","98abf02bd8fdb98609908f6b14442e6a"],
 "sweep:rest_choice|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "sweep:reward|plain":["reward","7","14c4306fcbef8a2e93b2ed5bf401432d"],
 "sweep:reward|relic_bundle":["relic_bundle","9","db85dae4e279769ca6bbe9a1daa3a82d"],
 "sweep:reward|departure":["reward","7","14c4306fcbef8a2e93b2ed5bf401432d"],
 "sweep:reward|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "sweep:map|plain":["map","8","a507c6c80ccbb62052b1371922fb8f1e"],
 "sweep:map|relic_bundle":["relic_bundle","9","db85dae4e279769ca6bbe9a1daa3a82d"],
 "sweep:map|departure":["map","8","a507c6c80ccbb62052b1371922fb8f1e"],
 "sweep:map|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "sweep:travel|plain":["travel","7","be781114facff18ea4f28a93ba56746c"],
 "sweep:travel|relic_bundle":["relic_bundle","9","db85dae4e279769ca6bbe9a1daa3a82d"],
 "sweep:travel|departure":["travel","7","be781114facff18ea4f28a93ba56746c"],
 "sweep:travel|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "sweep:cleared|plain":["cleared","2","d87610942815b24e6660de917451defe"],
 "sweep:cleared|relic_bundle":["relic_bundle","7","e09edecb14b88418e58a6d14523ac0b8"],
 "sweep:cleared|departure":["cleared","2","d87610942815b24e6660de917451defe"],
 "sweep:cleared|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "sweep:pack|plain":["pack","10","98237f175a56ee564dfff2cf1d9ad562"],
 "sweep:pack|relic_bundle":["relic_bundle","9","db85dae4e279769ca6bbe9a1daa3a82d"],
 "sweep:pack|departure":["pack","10","98237f175a56ee564dfff2cf1d9ad562"],
 "sweep:pack|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "sweep:prison_end|plain":["prison_end","2","d87610942815b24e6660de917451defe"],
 "sweep:prison_end|relic_bundle":["relic_bundle","7","e09edecb14b88418e58a6d14523ac0b8"],
 "sweep:prison_end|departure":["prison_end","2","d87610942815b24e6660de917451defe"],
 "sweep:prison_end|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "sweep:captured|plain":["captured_inspection","7","25b29176db3b31f05af7311596afc648"],
 "sweep:captured|relic_bundle":["relic_bundle","9","db85dae4e279769ca6bbe9a1daa3a82d"],
 "sweep:captured|departure":["captured_inspection","7","25b29176db3b31f05af7311596afc648"],
 "sweep:captured|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "sweep:inspection|plain":["captured_inspection","8","c170407313358f9de4c81f218f34267c"],
 "sweep:inspection|relic_bundle":["relic_bundle","9","db85dae4e279769ca6bbe9a1daa3a82d"],
 "sweep:inspection|departure":["captured_inspection","8","c170407313358f9de4c81f218f34267c"],
 "sweep:inspection|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "sweep:battle|plain":["action_tail","93","d96ae17e030d62e74c18a203fd4d320e"],
 "sweep:battle|relic_bundle":["relic_bundle","8","609bfddb170311c1bb37d8b7048e22ac"],
 "sweep:battle|departure":["action_tail","93","d96ae17e030d62e74c18a203fd4d320e"],
 "sweep:battle|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "sweep:prepare|plain":["action_tail","77","b07f66d574b1dba809c46d5fb9584cb1"],
 "sweep:prepare|relic_bundle":["relic_bundle","9","db85dae4e279769ca6bbe9a1daa3a82d"],
 "sweep:prepare|departure":["action_tail","77","b07f66d574b1dba809c46d5fb9584cb1"],
 "sweep:prepare|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "sweep:rest|plain":["action_tail","77","3d12980be9bc26285e3042ca3afe2b63"],
 "sweep:rest|relic_bundle":["relic_bundle","9","db85dae4e279769ca6bbe9a1daa3a82d"],
 "sweep:rest|departure":["action_tail","77","3d12980be9bc26285e3042ca3afe2b63"],
 "sweep:rest|domain_blocked":["domain_blocked","0","4f53cda18c2baa0c0354bb5f9a3ecbe5"],
 "flag:overload_climax":["overload_climax","6","63ef64aa6bfbda1da4da1baeb6a906da"],
 "flag:pending_retain":["pending_retain","12","690c89746a256c4edb8faec68cc3a51e"],
 "flag:equipment_spell":["action_tail","117","3083d4f26a695223cb874ce9ac0489bd"],
 "flag:hook":["action_tail","83","c394592c05218962ab1cdc265694e160"],
 "flag:demo_exit":["cleared","4","0df86713c77f877b4564e49107737275"],
 "flag:card_chain":["card_chain","7","682afed1b5f48406d4122b3d0218375a"],
 "flag:rest_card":["rest_choice","11","91a85d569516914243cea1d080feee90"],
 "flag:reward_skip":["reward","9","c5658346f0bba2c8e302c725e3f2ebb1"],
 "flag:relic_rows":["action_tail","107","ed5f98fb08d19501e8b2976317cb26ea"],
 "flag:relic_bundle_equipped":["relic_bundle","8","e7dccde4536f9d304e05b8c58ef03857"],
 "flag:departure_equipped":["departure","8","0a2f9d0dde945abd70b6d831f6e00ea0"],
}

static func prefix_branch_table_face(g) -> String:
 var rows=g.command_facts()
 return r1_digest(JSON.stringify(rows.map(func(row):return [String(row.get("key","")),bool(row.get("valid",false)),String(row.get("reason","")),String(row.get("group","")),row.get("payload",{})])))

static func prefix_branch_tables_are_frozen(t) -> void:
 var states=branch_sweep_states()
 var declared=PREFIX_BRANCH_TABLE_BASELINE.keys()
 var missing=[]
 var moved=[]
 var compared=0
 for entry in states:
  var label=String(entry.label)
  declared=declared.filter(func(name):return String(name)!=label)
  if not PREFIX_BRANCH_TABLE_BASELINE.has(label):
   missing.append(label)
   continue
  var g=entry.game
  var rows=g.command_facts()
  var have=[g._phase_branch(),str(rows.size()),prefix_branch_table_face(g)]
  var want=PREFIX_BRANCH_TABLE_BASELINE[label]
  compared+=1
  if JSON.stringify(have)!=JSON.stringify(want): moved.append(label+" have="+JSON.stringify(have)+" want="+JSON.stringify(want))
 t.check(missing.is_empty() and declared.is_empty(),"prefix_branch_tables_are_frozen: the fixture sweep and the frozen table are two-way total (missing="+str(missing)+" extra="+str(declared)+")")
 t.check(moved.is_empty(),"prefix_branch_tables_are_frozen: every branch/prefix state keeps its frozen table face (a prefix move is red, never a silent edit): "+str(moved.slice(0,4)))
 # 规模双向（B 批审查条目 3）：三处（扫描／基线表／字面状态数）必须相等——删一态并同步删基线行在此红。
 t.check(compared==PREFIX_BRANCH_TABLE_BASELINE.size() and compared==PREFIX_BRANCH_TABLE_STATE_COUNT,"prefix_branch_tables_are_frozen: the sweep size equals the frozen table size equals the literal state count (a deleted state, with or without its baseline row, is red): compared="+str(compared)+" baseline="+str(PREFIX_BRANCH_TABLE_BASELINE.size())+" declared="+str(PREFIX_BRANCH_TABLE_STATE_COUNT))
 print("PREFIX BRANCH TABLES FROZEN states=%d moved=%d source_sha256=%s" % [compared,moved.size(),PREFIX_BRANCH_TABLE_SOURCE_SHA256])


# 装备自解家族夹具（非战斗阶段正例；S2 出口判据要求至少一个非战斗阶段实跑）。
static func attack_self_release_fixture(phase: String, count: int, game_class=null):
 var g=r1_build(phase,count,game_class)
 if "flame_flourish_bound" not in g.state.card_buffs: g.state.card_buffs.append("flame_flourish_bound")
 return g

# 显式重复夹具（acceptance §1.1 第 6 条）：把第二个存活敌人的 id 换成第一个的 id 并换成机械系类型，制造同
# 归一化 params 的两条枚举项。合法夹具受 G2 唯一性约束不产生重复，故显式构造。本夹具只主张引用性性质
# 「点查询返回枚举序首条」（不变量 6 的位置面）；内容面（首条与后续条可区分）在攻击域结构性不可达——
# build 按 id 解析到首个对象、是 params 的纯函数，故不作内容收敛声明，distinct_duplicates 恒 0 也不作正面证据。
static func attack_duplicate_params_fixture():
 var g=r1_build("battle",12)
 var source={}
 for e in g.state.enemies:
  if e.gone: continue
  source=e
  break
 if source.is_empty(): return g
 var duplicate=source.duplicate(true)
 duplicate.id=String(source.id)
 for type in g.Enemies.TYPES:
  if String(type)==String(source.type): continue
  if not bool(g.Enemies.TYPES[type].get("mechanical",false)): continue
  duplicate.type=String(type)
  break
 g.state.enemies.append(duplicate)
 return g

# C3／C4（S2 出口判据①；gherkin S2-1）：attack 双向等价在冻结矩阵、51 件稠密夹具、非战斗阶段（整备＋
# 装备自解 buff）与巫女角色夹具上各跑一次；逐家族覆盖计数为 0 即红。
static func attack_fact_direct_lookup(t) -> void:
 var fixtures=[]
 for cell in r1_cells(): fixtures.append(["%s:%d" % [cell[0],cell[1]],r1_build(cell[0],cell[1])])
 fixtures.append(["dense_51",t4_dense_51()])
 fixtures.append(["prepare:12+self_release",attack_self_release_fixture("prepare",12)])
 fixtures.append(["witch:battle",Game.new(42,false,"equipment",true,false,25,false,false,"witch")])
 fixtures.append(["duplicate_params",attack_duplicate_params_fixture()])
 var totals={"dir1":0,"dir2":0,"keys":0,"member":0,"duplicates":0,"distinct_duplicates":0}
 var families={}
 for entry in fixtures:
  var coverage=fact_lookup_equivalence(t,entry[1],"attack",FACT_LOOKUP_MUTATION_IDS,entry[0])
  for key in totals: totals[key]=int(totals[key])+int(coverage[key])
  for family in coverage.families: families[family]=int(families.get(family,0))+int(coverage.families[family])
 t.check(int(families.get("basic",0))>0 and int(families.get("witch",0))>0 and int(families.get("self_release",0))>0,"attack_fact_direct_lookup: every attack family is covered by direction 1: "+str(families))
 t.check(int(totals.keys)>0 and int(totals.dir2)>0 and int(totals.member)>0,"attack_fact_direct_lookup: the harness compared enumerated keys, mutations and member predicates: "+str(totals))
 t.check(int(totals.duplicates)>0,"attack_fact_direct_lookup: the duplicate fixture enumerates duplicate normalized params: "+str(totals))
 print("ATTACK FACT LOOKUP fixtures=%d dir1_rows=%d dir2_mutations=%d keys=%d member=%d duplicates=%d distinct=%d families=%s" % [fixtures.size(),totals.dir1,totals.dir2,totals.keys,totals.member,totals.duplicates,totals.distinct_duplicates,str(families)])

# C6（S2 出口判据②；gherkin S2-2；S2 补件 H4 扩展）：point 形点查询只算一行——不调用
# attack_facts()／equipment_spell_facts()／_fact_source()／attack_point_keys()。源码文本判据不再只看两个
# 函数体：逐个体扫被调单行 helper 白名单（名单写在测试内，改名／漏提取即红），并扫描间接调用形态
# （g.call(／Callable(，二者会绕过子串判据）；member 另须独立于请求行的构造器。运行期计数仍由测试侧
# 子类承担（生产源码不带计数器）。
const ATTACK_POINT_WHOLE_TABLE_CALLS=["attack_facts(","equipment_spell_facts(","_fact_source(","attack_point_keys("]
const ATTACK_POINT_INDIRECT_CALLS=[".call(","Callable("]
const ATTACK_POINT_ROW_CONSTRUCTORS=["attack_point_fact(","_attack_offer_fact(","attack_offer_fact(","_equipment_spell_fact(","_equipment_point_fact("]
# (file, style, name)：point 构造／谓词可到达的单行 helper（白名单）；每项的函数体都进整表生产者扫描。
const ATTACK_POINT_HELPERS=[
 ["res://core/game.gd","func","_attack_battle_families_ready"],
 ["res://core/game.gd","func","_attack_point_release_target"],
 ["res://core/game.gd","func","_equipment_point_member"],
 ["res://core/game.gd","func","_equipment_point_fact"],
 ["res://core/game.gd","func","_equipment_spell_fact"],
 ["res://core/game.gd","func","_basic_attack_point_key"],
 ["res://core/game.gd","func","_witch_attack_point_key"],
 ["res://core/game.gd","func","_attack_offer_fact"],
 ["res://core/game.gd","func","kick_profile"],
 ["res://core/witch_character.gd","static","attack_offer_fact"],
]

static func attack_point_helper_body(file: String, style: String, name: String) -> String:
 return source_static_func_body_code(file,name) if style=="static" else source_func_body_code(file,name)

static func attack_point_lookup_reads_one_row(t) -> void:
 var builder=source_func_body_code("res://core/game.gd","attack_point_fact")
 var member=source_func_body_code("res://core/game.gd","attack_point_member")
 t.check(not builder.strip_edges().is_empty() and not member.strip_edges().is_empty(),"attack_point_lookup_reads_one_row: both point bodies are extracted have_builder="+str(builder.length())+" have_member="+str(member.length()))
 var bodies={"attack_point_fact":builder,"attack_point_member":member}
 var missing=[]
 for row in ATTACK_POINT_HELPERS:
  var name=String(row[2])
  var body=attack_point_helper_body(String(row[0]),String(row[1]),name)
  bodies[name]=body
  if body.strip_edges().is_empty(): missing.append(String(row[0])+"::"+name)
 t.check(missing.is_empty(),"attack_point_lookup_reads_one_row: every whitelisted helper body is extracted (a rename must not silently empty the scan): "+str(missing))
 for name in bodies:
  var body=String(bodies[name])
  for needle in ATTACK_POINT_WHOLE_TABLE_CALLS:
   t.check(body.find(needle)<0,"attack_point_lookup_reads_one_row: "+name+" never calls the whole-table producer "+needle+": "+body)
  for needle in ATTACK_POINT_INDIRECT_CALLS:
   t.check(body.find(needle)<0,"attack_point_lookup_reads_one_row: "+name+" has no indirect call form "+needle+": "+body)
 for needle in ATTACK_POINT_ROW_CONSTRUCTORS:
  t.check(member.find(needle)<0,"attack_point_lookup_reads_one_row: the member predicate is independent of the row constructor "+needle+": "+member)
 print("ATTACK POINT LOOKUP SOURCE SCAN bodies=%d helpers=%d whole_table_names=%d indirect_names=%d" % [bodies.size(),ATTACK_POINT_HELPERS.size(),ATTACK_POINT_WHOLE_TABLE_CALLS.size(),ATTACK_POINT_INDIRECT_CALLS.size()])
 var samples=[["battle:0",r1_build("battle",0,AttackLookupCountingGame)],["prepare:12+self_release",attack_self_release_fixture("prepare",12,AttackLookupCountingGame)],["witch:battle",AttackLookupCountingGame.new(42,false,"equipment",true,false,25,false,false,"witch")]]
 var compared=0
 for entry in samples:
  var g=entry[1]
  var row={}
  for candidate in g.command_facts():
   if String(candidate.payload.get("kind",""))=="attack": row=candidate; break
  t.check(not row.is_empty(),"attack_point_lookup_reads_one_row: the fixture exposes an attack row: "+String(entry[0]))
  if row.is_empty(): continue
  g.reset_attack_lookup_counts()
  var found=g.command_fact(g.command(row.payload,g.state.version))
  print("ATTACK POINT LOOKUP fixture=%s whole_table_calls attack_facts=%d equipment_spell_facts=%d _fact_source=%d" % [entry[0],g.attack_facts_calls,g.equipment_spell_calls,g.fact_source_calls])
  t.check(found==row and g.attack_facts_calls==0 and g.equipment_spell_calls==0 and g.fact_source_calls==0,"attack_point_lookup_reads_one_row: one row is answered without a whole-table producer: "+String(entry[0]))
  compared+=1
 t.check(compared==samples.size(),"attack_point_lookup_reads_one_row: every family sample was compared have="+str(compared))

# S2 补件（L1 判据；R8-4）：非战斗阶段＋存活敌人的负例——转换前 core/game.gd::attack_facts 的基础／巫女
# 家族在 `state.phase!="battle"` 时 fail-closed（生产者为空），故点查询必须为空且该 params 不在该状态的表内
# （同真同假）。夹具保留真实存活敌人并把阶段切到 prepare，并显式断言尾段到达条件成立：L1 的隐含前提
# 「非战斗阶段没有存活敌人」被移除，删掉两家族的阶段守卫（_attack_battle_families_ready 的合取项）即红。
static func attack_nonbattle_enemy_fixture():
 var g=r1_build("battle",12)
 g.state.phase="prepare"
 return g

static func attack_nonbattle_witch_fixture():
 var g=Game.new(42,false,"equipment",true,false,25,false,false,"witch")
 g.state.phase="prepare"
 return g

static func attack_point_rejects_nonbattle_families(t) -> void:
 # 每例＝（家族，夹具，type，声明键补充）：巫女预备行（form 0）的 charge_action 声明为 true，其余键取声明默认值。
 var cases=[["basic",attack_nonbattle_enemy_fixture(),"strike",{}],["witch",attack_nonbattle_witch_fixture(),"witch_hand",{"part":"hand","charge_action":true}]]
 for entry in cases:
  var family=String(entry[0])
  var g=entry[1]
  var living=g.state.enemies.filter(func(e):return not e.gone)
  t.check(String(g.state.phase)!="battle" and g._phase_action_tail() and not living.is_empty(),"attack_point_rejects_nonbattle_families: the fixture is a non-battle phase with a living enemy and a reachable action tail "+family+" phase="+String(g.state.phase)+" living="+str(living.size()))
  if living.is_empty(): continue
  var params={"kind":"attack","type":String(entry[2]),"form":0,"enemy":living[0].id}
  for key in entry[3]: params[key]=entry[3][key]
  var normalized=g.command_params("attack",params)
  var in_table=false
  for row in g.command_facts():
   if String(row.payload.get("kind",""))=="attack" and g.command_params("attack",row.payload)==normalized: in_table=true
  var accepted=not g.command_fact(g.command(params,g.state.version)).is_empty()
  var is_member=bool(g.attack_point_member(g,normalized))
  t.check(not in_table and not accepted and not is_member,"attack_point_rejects_nonbattle_families: base and witch attacks are fail-closed outside battle "+family+" phase="+String(g.state.phase)+" in_table="+str(in_table)+" accepted="+str(accepted)+" member="+str(is_member))
  print("ATTACK NONBATTLE POINT family=%s phase=%s living=%d in_table=%s accepted=%s member=%s" % [family,String(g.state.phase),living.size(),str(in_table),str(accepted),str(is_member)])

# ==== S3 card 双向等价、分支覆盖与重复收敛（C3／C4／C6／C7；gherkin S3-1／S3-2／S3-3）====
# 分支族夹具（gherkin S3-2）：把字段族代表卡型放进手牌。breath_control 顶层 exhaust_hand＋free_slots；
# ready_to_strike 面级 exhaust_hand；concentration 声明 bound_modes；self_binding 为 x_cost 自身卡；
# panic 是可打出的单面卡（mode=none）；strong_elbow 声明 target_slots。
const CARD_BRANCH_TYPES=["breath_control","ready_to_strike","concentration","self_binding","panic","strong_elbow"]

static func card_branch_fixture(t, phase: String, count: int, game_class=null):
 var g=r1_build(phase,count,game_class)
 for type in CARD_BRANCH_TYPES: Rewards.give(t,g,type)
 return g

# exhaust_hand 回退正例（gherkin S3-2）：手牌只留这一张卡，选择展开必须回退为 hand_uid 置空。
static func card_exhaust_fallback_fixture(t, type: String, game_class=null):
 var g=r1_build("battle",12,game_class)
 var card=Rewards.give(t,g,type)
 g.state.hand=[card]
 return g

# 捕缚家族正例（gherkin S3-2 的组合分支；沿用既有 ARCH 的 drone_solo 真实捕缚流程）。
static func card_bind_fixture(t, type: String):
 var g=Game.new(42,true,"drone_solo")
 t.action(g,"end")
 Rewards.give(t,g,type)
 return g

# 特殊装备跨槽（gherkin S3-3）：crotch_rope_low 的声明槽位＝special_3_a＋special_3_b，同一实例在两个
# 槽位都可被 targets_at 取到；seen_special 必须只保留走查序首槽（special_3_a）的那一项，后一槽不得成为
# 候选键。夹具走 _install_special，状态保持 validate 通过。
static func card_special_cross_slot_fixture(t, card_type: String):
 var g=r1_build("battle",12)
 var item=g._install_special("crotch_rope_low","special_3_a")
 g.state.hand=[Rewards.give(t,g,card_type)]
 return [g,item]

# 空目标补位（gherkin S3-3）：清空装备后只在手掌装一件单侧件：occupied 为 false 而 targets_at 非空，
# 走查必须补一个空目标项（沿用 card_facts_consumes_has_targets_at 的单侧手掌语义）。
static func card_empty_target_fixture(t, card_type: String, game_class=null):
 var g=r1_build("battle",12,game_class)
 _clear_gear(g)
 var piece=g.add_fixture("palm",4,10)
 piece.side="left"
 g.state.hand=[Rewards.give(t,g,card_type)]
 return [g,piece.id]

# 重复归一化 params（沿用 attack_duplicate_params_fixture 的读法）：同 uid 的第二张手牌产生同 params 的
# 两条枚举项；build 是 params 的纯函数，故本夹具证明「点查询返回枚举序首条」而非内容可区分。
static func card_duplicate_params_fixture(t, card_type: String, game_class=null):
 var g=r1_build("battle",12,game_class)
 var card=Rewards.give(t,g,card_type)
 g.state.hand=[card,card.duplicate(true)]
 return g

# 点查询集合（登记项 keys）的唯一取用面：测试侧只经登记项方法名取枚举，不复制枚举语义。
static func point_keys_for(g, kind: String) -> Array:
 var entry=CommandRegistry.entry(kind)
 return g.call(String(entry.get("keys","")),g)

# C3／C4／C6／C7（S3 出口判据①②③）：card 在 0／12／26／44 件 × 战斗／监狱／整备夹具与分支族夹具上
# 各跑一次方向①／②；逐分支族覆盖计数为 0 即红；exhaust_hand 的选择与回退各有正例；重复收敛夹具
# （特殊装备跨槽、空目标补位）显式构造。
static func card_fact_direct_lookup(t) -> void:
 var fixtures=[]
 for phase in ["battle","prepare","prison"]:
  for count in [0,12,26,44]:
   fixtures.append(["%s:%d" % [phase,count],r1_build(phase,count)])
 var branch_battle=card_branch_fixture(t,"battle",26)
 fixtures.append(["branch:battle:26",branch_battle])
 fixtures.append(["branch:prison:26",card_branch_fixture(t,"prison",26)])
 fixtures.append(["exhaust_fallback:breath_control",card_exhaust_fallback_fixture(t,"breath_control")])
 fixtures.append(["exhaust_fallback:ready_to_strike",card_exhaust_fallback_fixture(t,"ready_to_strike")])
 var bind=card_bind_fixture(t,"concentration")
 t.check(bind.CaptureBind.has_bind(bind),"card_fact_direct_lookup: the bind fixture establishes a real capture bind")
 if bind.CaptureBind.has_bind(bind): fixtures.append(["bind:concentration",bind])
 var cross=card_special_cross_slot_fixture(t,"strain")
 t.check(not cross[1].is_empty(),"card_fact_direct_lookup: the cross-slot special fixture installs a special item")
 if not cross[1].is_empty(): fixtures.append(["special_cross_slot",cross[0]])
 var pad=card_empty_target_fixture(t,"strain")
 t.check(pad[0].state.equipment.size()==1 and not pad[0].occupied("palm") and not pad[0].targets_at("palm").is_empty(),"card_fact_direct_lookup: the empty-target fixture holds one unoccupied palm piece")
 fixtures.append(["empty_target_padding",pad[0]])
 var duplicate=card_duplicate_params_fixture(t,"strain")
 fixtures.append(["duplicate_params",duplicate])
 var totals={"dir1":0,"dir2":0,"keys":0,"member":0,"duplicates":0,"distinct_duplicates":0}
 var families={}
 var branches={}
 for entry in fixtures:
  var coverage=fact_lookup_equivalence(t,entry[1],"card",FACT_LOOKUP_MUTATION_IDS,entry[0])
  for key in totals: totals[key]=int(totals[key])+int(coverage[key])
  for family in coverage.families: families[family]=int(families.get(family,0))+int(coverage.families[family])
  for flag in coverage.branches: branches[flag]=int(branches.get(flag,0))+int(coverage.branches[flag])
 for flag in CARD_BRANCH_FAMILIES:
  t.check(int(branches.get(flag,0))>0,"card_fact_direct_lookup: every card branch family is covered by direction 1 missing="+flag+" have="+str(branches))
 t.check(int(totals.keys)>0 and int(totals.dir2)>0 and int(totals.member)>0,"card_fact_direct_lookup: the harness compared enumerated keys, mutations and member predicates: "+str(totals))
 t.check(int(totals.duplicates)>0,"card_fact_direct_lookup: the duplicate fixture enumerates duplicate normalized params: "+str(totals))
 # gherkin S3-2：声明外槽位不产生行（点侧沿用 card_facts_declared_slots 语义）。
 var elbow_card={}
 for card in branch_battle.state.hand:
  if card.type=="strong_elbow": elbow_card=card
 t.check(not elbow_card.is_empty(),"card_fact_direct_lookup: the branch fixture holds strong_elbow")
 var elbow_spec=branch_battle.Cards.Rules.SPECS.get("strong_elbow",{})
 var elbow_keys=point_keys_for(branch_battle,"card").filter(func(k):return String(k.get("uid",""))==String(elbow_card.get("uid","")))
 t.check(not elbow_keys.is_empty() and elbow_keys.all(func(k):return String(k.get("slot","")) in elbow_spec.get("target_slots",[])),"card_fact_direct_lookup: declared-slot cards keep every point key inside target_slots: "+str(elbow_keys.map(func(k):return k.get("slot",""))))
 # gherkin S3-3：特殊装备跨槽——同一实例只保留走查序首槽；后一槽的向量必须被点查询与 member 同时拒绝。
 var cross_g=cross[0]
 var cross_id=String(cross[1].get("id",""))
 t.check(cross_g.targets_at("special_3_a").size()==1 and cross_g.targets_at("special_3_b").size()==1 and String(cross_g.targets_at("special_3_a")[0].id)==String(cross_g.targets_at("special_3_b")[0].id),"card_fact_direct_lookup: the cross-slot fixture reaches the same instance from both declared slots: "+cross_id)
 var cross_keys=point_keys_for(cross_g,"card").filter(func(k):return String(k.get("target",""))==cross_id)
 t.check(cross_keys.size()==1 and String(cross_keys[0].get("slot",""))=="special_3_a","card_fact_direct_lookup: a special instance spanning slots stays on its first walked slot: "+str(cross_keys))
 var later=cross_g.command_params("card",{"kind":"card","uid":cross_g.state.hand[0].uid,"type":"strain","slot":"special_3_b","target":cross_id})
 t.check(cross_g.command_fact(cross_g.command(later,cross_g.state.version)).is_empty(),"card_fact_direct_lookup: the later slot of the same special id is not a member")
 t.check(not bool(cross_g.call("card_point_member",cross_g,later)),"card_fact_direct_lookup: the member predicate rejects the later slot of the same special id")
 # gherkin S3-3：空目标补位——同一槽位同时枚举实件与补位空目标，且表内 (kind, params) 唯一。
 var pad_g=pad[0]
 var pad_id=String(pad[1])
 var palm_keys=point_keys_for(pad_g,"card").filter(func(k):return String(k.get("slot",""))=="palm")
 t.check(palm_keys.any(func(k):return String(k.get("target",""))==pad_id) and palm_keys.any(func(k):return String(k.get("target",""))==""),"card_fact_direct_lookup: the padded slot enumerates the piece and the empty target: "+str(palm_keys))
 for convergent in [["special_cross_slot",cross_g],["empty_target_padding",pad_g]]:
  var seen={}
  var repeated=[]
  for row in convergent[1].command_facts():
   var row_key=String(row.payload.get("kind",""))+"|"+JSON.stringify(convergent[1].command_params(row.payload.kind,row.payload))
   if seen.has(row_key): repeated.append(row_key)
   seen[row_key]=true
  t.check(repeated.is_empty(),"card_fact_direct_lookup: the convergence fixture keeps (kind, params) unique "+String(convergent[0])+": "+str(repeated.slice(0,3)))
 print("CARD FACT LOOKUP fixtures=%d dir1_rows=%d dir2_mutations=%d keys=%d member=%d duplicates=%d distinct=%d families=%s branches=%s" % [fixtures.size(),totals.dir1,totals.dir2,totals.keys,totals.member,totals.duplicates,totals.distinct_duplicates,str(families),str(branches)])

# core/card_effects.gd 的函数全是 `static func`：source_func_text 只认行首的 `\nfunc `，会一直取到文件
# 尾；本提取器在下一个 `\nstatic func `／`\nfunc ` 处截断（只用于该文件的源码级判据）。
static func source_static_func_body_code(path: String, name: String) -> String:
 var handle=FileAccess.open(path,FileAccess.READ)
 if handle==null: return ""
 var source=handle.get_as_text()
 var start=source.find("\nstatic func "+name+"(")
 if start<0: return ""
 var rest=source.substr(start+1)
 var nxt=-1
 for cut in [rest.find("\nstatic func ",1),rest.find("\nfunc ",1)]:
  if cut>=0 and (nxt<0 or cut<nxt): nxt=cut
 var text=rest if nxt<0 else rest.substr(0,nxt)
 var code=""
 for line in text.split("\n"): code+=String(line).split("#")[0]+"\n"
 return code

# C6（S3 出口判据③；gherkin S3-1／S3-2）：card 点查询只算一行——不调用整表生产者
# （core/game.gd::_fact_source／core/card_effects.gd::card_facts）或该域整表枚举
# （core/card_effects.gd::card_point_keys）；成员谓词是独立谓词，不经请求行的构造
# （不调用 card_point_fact／_target_fact）。core/card_effects.gd::card_facts 是静态函数，运行时无法经
# g 计数，故该条证据为源码文本；运行期计数（测试侧子类）覆盖 _fact_source。
static func card_point_lookup_reads_one_row(t) -> void:
 var builder=source_static_func_body_code("res://core/card_effects.gd","card_point_fact")
 var member=source_static_func_body_code("res://core/card_effects.gd","card_point_member")
 t.check(not builder.strip_edges().is_empty() and not member.strip_edges().is_empty(),"card_point_lookup_reads_one_row: both card point bodies are extracted have_builder="+str(builder.length())+" have_member="+str(member.length()))
 t.check(builder.find("card_facts(")<0 and builder.find("_fact_source(")<0 and builder.find("card_point_keys(")<0,"card_point_lookup_reads_one_row: the point builder never calls a whole-table producer: "+builder)
 t.check(member.find("card_facts(")<0 and member.find("_fact_source(")<0 and member.find("card_point_keys(")<0,"card_point_lookup_reads_one_row: the member predicate never calls a whole-table producer: "+member)
 t.check(member.find("card_point_fact(")<0 and member.find("_target_fact(")<0 and member.find("_fact(")<0,"card_point_lookup_reads_one_row: the member predicate is independent of the row constructor: "+member)
 var samples=[["battle:12",r1_build("battle",12,FactSourceCountingGame)],["branch:prison:26",card_branch_fixture(t,"prison",26,FactSourceCountingGame)],["exhaust_fallback:breath_control",card_exhaust_fallback_fixture(t,"breath_control",FactSourceCountingGame)]]
 var compared=0
 for entry in samples:
  var g=entry[1]
  var row={}
  for candidate in g.command_facts():
   if String(candidate.payload.get("kind",""))=="card": row=candidate; break
  t.check(not row.is_empty(),"card_point_lookup_reads_one_row: the fixture exposes a card row: "+String(entry[0]))
  if row.is_empty(): continue
  g.fact_source_calls=0
  var found=g.command_fact(g.command(row.payload,g.state.version))
  print("CARD POINT LOOKUP fixture=%s whole_table_calls _fact_source=%d" % [entry[0],g.fact_source_calls])
  t.check(found==row and g.fact_source_calls==0,"card_point_lookup_reads_one_row: one row is answered without a whole-table producer: "+String(entry[0]))
  compared+=1
 t.check(compared==samples.size(),"card_point_lookup_reads_one_row: every family sample was compared have="+str(compared))

# ==== C 批（K3 一次构造；plan §3 C 段；acceptance.md §1 C 段）====

# C 批（K3）走查次数代理：core/card_effects.gd::_card_slot_walk 对每个声明槽位问一次
# core/game.gd::has_targets_at（core 内唯一调用点），故「单卡手牌夹具上每个槽位至多被问一次」
# 即「该手牌的表 pass 只走查一次」。生产源码不带计数器。
class SlotWalkCountingGame extends "res://tests/game_fixture.gd":
 var slot_walk_slots=[]
 func has_targets_at(slot: String) -> bool:
  slot_walk_slots.append(slot)
  return super.has_targets_at(slot)

# C-C-1（K3；gherkin C-1／C-2）：点形家族的表 pass 每行恰构造一次。被测侧＝测试侧计数子类（按 payload
# 逐家族统计 core/game.gd::_fact 的调用）；期望侧＝该次 command_facts() 返回的行集（不取自实现）。
# 敏感性：把任一表生产者改回「取键＋构造」两步 ⇒ 构造次数翻倍（构造数 ≠ 行数）即红；
# card 的走查次数由单卡夹具的槽位问询面钉住（两步形态 ⇒ 每个槽位被问 1+keys 次）。
static func table_rows_constructed_once(t) -> void:
 var fixtures=[]
 for cell in r1_cells():
  if cell[0]=="takeover": continue
  fixtures.append(["%s:%d" % [cell[0],cell[1]],r1_build(cell[0],cell[1],PointFamilyCountingGame)])
 fixtures.append(["prepare:12+self_release",attack_self_release_fixture("prepare",12,PointFamilyCountingGame)])
 fixtures.append(["witch:battle",PointFamilyCountingGame.new(42,false,"equipment",true,false,25,false,false,"witch")])
 fixtures.append(["branch:battle:26",card_branch_fixture(t,"battle",26,PointFamilyCountingGame)])
 fixtures.append(["exhaust_fallback:breath_control",card_exhaust_fallback_fixture(t,"breath_control",PointFamilyCountingGame)])
 var problems=[]
 var totals={"attack":0,"witch":0,"equipment_spell":0,"card":0}
 var rows_total=0
 for entry in fixtures:
  var g=entry[1]
  g.reset_point_family_counts()
  var rows=g.command_facts()
  var expected=point_family_rows(rows)
  var constructed=point_family_constructed(g)
  if g.fact_calls!=rows.size(): problems.append("%s: fact_calls=%d rows=%d" % [String(entry[0]),g.fact_calls,rows.size()])
  for family in expected:
   if int(constructed[family])!=int(expected[family]): problems.append("%s: %s constructed=%d rows=%d" % [String(entry[0]),family,constructed[family],expected[family]])
   totals[family]=int(totals[family])+int(expected[family])
  rows_total+=rows.size()
  # 两半共用同一次走查：一次表 pass 至多一次（两次＝两半各走一遍；行存在则必然 ≥1）。
  if g.walk_calls>1: problems.append("%s: attack walk_calls=%d" % [String(entry[0]),g.walk_calls])
 t.check(problems.is_empty(),"table_rows_constructed_once: every point-family row is constructed exactly once per table pass (no keys-then-build round trip): "+str(problems.slice(0,6)))
 t.check(problems.is_empty() and totals.attack>0 and totals.witch>0 and totals.equipment_spell>0 and totals.card>0 and rows_total>0,"table_rows_constructed_once: every point family is covered by the fixture matrix (attack/witch/equipment_spell/card): "+str(totals)+" rows="+str(rows_total))
 var single=card_exhaust_fallback_fixture(t,"strong_elbow",SlotWalkCountingGame)
 t.check(single.state.hand.size()==1,"table_rows_constructed_once: the single-card fixture holds exactly one card")
 single.slot_walk_slots.clear()
 var single_rows=single.command_facts()
 var slots=single.slot_walk_slots.duplicate()
 var repeated=[]
 for slot in single.slot_walk_slots:
  if single.slot_walk_slots.count(slot)>1 and slot not in repeated: repeated.append(slot)
 t.check(not slots.is_empty() and repeated.is_empty(),"table_rows_constructed_once: one card is walked once per table pass (a slot asked twice means the walk ran again): repeated="+str(repeated)+" slots="+str(slots))
 t.check(single_rows.any(func(row):return String(row.payload.get("kind",""))=="card"),"table_rows_constructed_once: the single-card fixture exposes card rows")
 print("POINT FAMILY ONCE fixtures=%d rows=%d attack=%d witch=%d equipment_spell=%d card=%d walk_slots=%d" % [fixtures.size(),rows_total,totals.attack,totals.witch,totals.equipment_spell,totals.card,slots.size()])

# C-C-2（K3；gherkin C-3）：点形家族的表生产者只有一个走查入口（源码文本）——三个生产者体内各恰出现走查
# 入口一次，且不出现「先取键再构造」的两步形态；走查与单行构造各只有一处实现（keys／build／member 仍各自
# 独立，attack 侧沿用既有 ATTACK_POINT_HELPERS／ATTACK_POINT_INDIRECT_CALLS 口径）。
# D 批（K1-D）后 walk 入口经批内复用机制取用：标记仍是走查本身（`core/game.gd::attack_point_walk`／
# `core/card_effects.gd::_card_point_rows`），批内条目名由 D-3 的文本判据单独钉住。
const TABLE_WALK_ENTRIES=[
 ["res://core/game.gd","attack_facts","attack_point_walk(","attack_point_keys(","attack_point_fact("],
 ["res://core/game.gd","equipment_spell_facts","attack_point_walk(","attack_point_keys(","attack_point_fact("],
 ["res://core/card_effects.gd","card_facts","_card_point_rows(","_card_point_card_keys(","card_point_fact("],
]
# 走查与单行构造的唯一定义点（[file, style, name]；style=static 用 core/card_effects.gd 的静态提取器）。
const TABLE_WALK_UNIQUE_DEFS=[
 ["res://core/game.gd","func","attack_point_walk"],
 ["res://core/game.gd","func","attack_point_keys"],
 ["res://core/game.gd","func","attack_point_fact"],
 ["res://core/game.gd","func","attack_point_member"],
 ["res://core/card_effects.gd","static","_card_point_rows"],
 ["res://core/card_effects.gd","static","card_point_fact"],
 ["res://core/card_effects.gd","static","card_point_member"],
 ["res://core/card_effects.gd","static","card_point_keys"],
]

static func table_walk_entry_body(file: String, name: String) -> String:
 return source_static_func_body_code(file,name) if file.ends_with("card_effects.gd") else source_func_body_code(file,name)

static func table_walk_single_entry(t) -> void:
 var bodies={}
 var missing=[]
 for row in TABLE_WALK_ENTRIES:
  var file=String(row[0])
  var name=String(row[1])
  var body=table_walk_entry_body(file,name)
  bodies[name]=body
  if body.strip_edges().is_empty(): missing.append(file+"::"+name)
 t.check(missing.is_empty(),"table_walk_single_entry: every table producer body is extracted (a rename must not silently empty the scan): "+str(missing))
 var problems=[]
 for row in TABLE_WALK_ENTRIES:
  var name=String(row[1])
  var body=String(bodies.get(name,""))
  var entries=0
  var at=0
  while true:
   var found=body.find(String(row[2]),at)
   if found<0: break
   entries+=1
   at=found+1
  if entries!=1: problems.append(name+": walk entry appears "+str(entries)+" times")
  if body.find(String(row[3]))>=0: problems.append(name+": still enumerates keys ("+String(row[3])+")")
  if body.find(String(row[4]))>=0: problems.append(name+": still rebuilds rows ("+String(row[4])+")")
 t.check(problems.is_empty(),"table_walk_single_entry: each table producer takes its rows from the one walk (no keys-then-build two-step form): "+str(problems))
 var defs=[]
 for row in TABLE_WALK_UNIQUE_DEFS:
  var file=String(row[0])
  var style=String(row[1])
  var name=String(row[2])
  var body=attack_point_helper_body(file,style,name)
  if body.strip_edges().is_empty(): defs.append(file+"::"+name+"=<no body>")
  if source_text(file.trim_prefix("res://")).find(("\nstatic func " if style=="static" else "\nfunc ")+name+"(")<0: defs.append(file+"::"+name+"=<no definition>")
 t.check(defs.is_empty(),"table_walk_single_entry: the walk, keys, build and member each keep exactly one implementation: "+str(defs))
 var keys_body=source_func_body_code("res://core/game.gd","attack_point_keys")
 var card_keys_body=source_static_func_body_code("res://core/card_effects.gd","card_point_keys")
 t.check(keys_body.find("attack_point_walk(")>=0 and keys_body.find("attack_point_fact(")<0 and card_keys_body.find("_card_point_card_keys(")>=0,"table_walk_single_entry: keys enumerates the same walk and never builds rows")
 print("TABLE WALK SINGLE ENTRY producers=%d unique_defs=%d" % [TABLE_WALK_ENTRIES.size(),TABLE_WALK_UNIQUE_DEFS.size()])

# C-C-3（K3；gherkin C-4；design.md §5.0 C 行）：批次语义——①测试侧持批（把 _begin_equipment_read 的 previous
# 留在测试里）时三个点形生产者与无批次逐字节相等，且攻击走查只发生一次；②出批即弃：出批后改状态再调用，
# 结果必须按新状态给出（批次内条目不再被复用 ⇒ 不陈旧）。敏感性：让走查跨批次存活（挂 self 或按键）⇒
# ②的比较红（after 与批内结果相同）。
static func point_family_rows_respect_read_scope(t) -> void:
 var fixtures=[
  ["battle:12",r1_build("battle",12,PointFamilyCountingGame)],
  ["prepare:12+self_release",attack_self_release_fixture("prepare",12,PointFamilyCountingGame)],
 ]
 var problems=[]
 var stale_checked=0
 for entry in fixtures:
  var g=entry[1]
  var expected=[g.attack_facts(),g.equipment_spell_facts(),g.state.hand.map(func(card):return g.Cards.card_facts(g,card))]
  g.reset_point_family_counts()
  var previous=g._begin_equipment_read()
  var batched=[g.attack_facts(),g.equipment_spell_facts(),g.state.hand.map(func(card):return g.Cards.card_facts(g,card))]
  g._equipment_read=previous
  if batched!=expected: problems.append(String(entry[0])+": batch-held calls differ from batch-free calls")
  if g.walk_calls!=1: problems.append(String(entry[0])+": attack walk_calls="+str(g.walk_calls))
  var before=g.attack_facts()
  var previous_inner=g._begin_equipment_read()
  var during=g.attack_facts()
  g._equipment_read=previous_inner
  var enemies=g.state.enemies
  g.state.enemies=[]
  var after=g.attack_facts()
  g.state.enemies=enemies
  if not before.is_empty():
   stale_checked+=1
   if during!=before: problems.append(String(entry[0])+": the batch-held attack rows differ from the batch-free rows")
   if after.size()>=during.size() and JSON.stringify(after)==JSON.stringify(during): problems.append(String(entry[0])+": the walk result outlives its read batch (stale rows after the state changed)")
 t.check(problems.is_empty(),"point_family_rows_respect_read_scope: the walk result is reused inside one read batch and dropped when the batch ends: "+str(problems))
 t.check(stale_checked>0,"point_family_rows_respect_read_scope: at least one fixture exercised the stale check have="+str(stale_checked))
 print("POINT FAMILY READ SCOPE fixtures=%d stale_checked=%d" % [fixtures.size(),stale_checked])

# ==== D 批（K1-D）：批内复用的唯一机制 ＝ core/game.gd::_batch_rows ====
# 契约：docs/spec/fact-table-dependencies.md「批内复用」（gherkin D-1…D-5；acceptance.md §1 C-D-1…C-D-5）。
# 形态与寿命照 core/game_view.gd::equipment_entry 的 equipment_views：条目只落在 core/game.gd::_begin_equipment_read
# 建立的批次字典上，出批即弃；单一入口／单一寿命规则／单一深拷贝语义（命中与首算都返回深拷贝）。
# 测试侧记录器＝tests/batch_reuse_recorder.gd（包装机制入口计数；生产源码不带计数器）。
const ReuseRecorder=preload("res://tests/batch_reuse_recorder.gd")
const NormalPlay=preload("res://tests/normal_play_cases.gd")
# 批内条目名 → 唯一允许出现它的生产函数（D-3 文本判据；声明行另计一次）。
const BATCH_ENTRY_KINDS={
 "BATCH_TABLE":["core/game.gd::command_facts"],
 "BATCH_ATTACK_WALK":["core/game.gd::attack_facts","core/game.gd::attack_point_keys","core/game.gd::equipment_spell_facts"],
 "BATCH_CARD_ROWS":["core/card_effects.gd::card_facts"],
}
const BATCH_ENTRY_FORBIDDEN=["set_meta(","get_meta(","self","is_same(",".version","state.","_cache"]

# D-1／D-2（gherkin D-1／D-2；acceptance.md §1 C-D-1／C-D-2）：整表在一个读取批次内只构建一次、出批即弃；
# 失败提交不享受复用。测试侧持批＝把 core/game.gd::_begin_equipment_read 返回的 previous 留在测试里；
# 计数口径＝机制的请求次数／真实构建次数（测试侧记录器）＋core/game.gd::_fact_source 的调用次数（＝单元
# 生产者被跑的次数，全 0 即第二、三次取用没有重新连接任何单元）。
static func fact_table_reuse_within_batch(t) -> void:
 var cells=[["battle",12],["prepare",12],["takeover",0]]
 var problems=[]
 var compared=0
 for cell in cells:
  var label="%s:%d" % [cell[0],cell[1]]
  var g=r1_build(cell[0],cell[1],ReuseRecorder)
  # 从零参考＝同类的第二个实例（同类同种子 ⇒ 同状态；批次外调用每次现算；状态不等即红而不是静默对比）。
  var reference=r1_build(cell[0],cell[1],ReuseRecorder)
  g.reset_reuse_counts()
  var before=g.export_snapshot()
  var previous=g._begin_equipment_read()
  var held=[g.get_view(),g.get_view(),g.get_view()]
  var held_requests=g.reuse_requests_of("table")
  var held_builds=g.reuse_builds_of("table")
  var held_sources=g.fact_source_calls
  # 表的唯一出口在同一批次内也必须命中同一批内条目（第四次请求，仍是 1 次构建）。
  var held_table=JSON.stringify(g.command_facts())
  var held_table_requests=g.reuse_requests_of("table")
  var held_table_builds=g.reuse_builds_of("table")
  g._equipment_read=previous
  g.get_view()
  var released_builds=g.reuse_builds_of("table")
  var held_equal=JSON.stringify(held[0].display_facts)==JSON.stringify(held[1].display_facts) and JSON.stringify(held[1].display_facts)==JSON.stringify(held[2].display_facts)
  var free_equal=JSON.stringify(g.export_snapshot())==JSON.stringify(reference.export_snapshot()) and JSON.stringify(held[0].display_facts)==JSON.stringify(reference.get_view().display_facts) and held_table==JSON.stringify(reference.command_facts())
  if held_requests!=3 or held_table_requests!=4 or held_builds!=1 or held_table_builds!=1 or held_sources!=1 or not held_equal or not free_equal:
   problems.append("%s: requests=%d/%d builds=%d/%d fact_source=%d held_equal=%s batch_free_equal=%s" % [label,held_requests,held_table_requests,held_builds,held_table_builds,held_sources,str(held_equal),str(free_equal)])
  if released_builds!=2:
   problems.append("%s: after the batch ended the next read must rebuild the table (builds=%d)" % [label,released_builds])
  if g.export_snapshot()!=before:
   problems.append(label+": batch-held reads changed the snapshot")
  compared+=1
 t.check(problems.is_empty(),"fact_table_reuse_within_batch: one read batch builds the table once, drops it when the batch ends and leaves state untouched: "+str(problems))
 t.check(compared==cells.size() and problems.is_empty(),"fact_table_reuse_within_batch: every fixture cell held its own batch (three views and the table exit inside one batch build it once, the next read rebuilds): "+str(compared))
 # D-2：失败提交不享受复用——被拒的提交不留任何可复用条目，紧接着的投影按新批重建且与从零路径逐字节相等；
 # 拒绝文案取自冻结基线 R1_BASELINE（期望侧不由实现派生）；UI 侧失败提示仍是提交结果 error 的逐字副本。
 var rejected_checked=0
 for cell in [["battle",0],["prison",12]]:
  var key="%s:%d" % [cell[0],cell[1]]
  var template=r1_build(cell[0],cell[1],ReuseRecorder)
  var usable={}
  for row in template.command_facts():
   if usable.is_empty() and row.valid: usable=row
  if usable.is_empty(): continue
  var g=r1_build(cell[0],cell[1],ReuseRecorder)
  var version=int(g.state.version)
  var before_reject=g.export_snapshot()
  g.reset_reuse_counts()
  var rejected=g.dispatch(g.command(usable.payload,version-1),version-1)
  var reject_builds=g.reuse_builds_of("table")
  var updated=g.get_view()
  var view_builds=g.reuse_builds_of("table")
  t.check(not rejected.ok and String(rejected.get("error",""))==String(R1_BASELINE[key].reject_stale),"fact_table_reuse_within_batch: a stale submit keeps the frozen rejection text ("+key+"): "+str(rejected.get("error","")))
  t.check(reject_builds==0 and view_builds==1 and int(g.state.version)==version,"fact_table_reuse_within_batch: the rejected submit leaves no reusable batch entry, so the next projection rebuilds once ("+key+"): rejected_builds="+str(reject_builds)+" view_builds="+str(view_builds))
  t.check(g.export_snapshot()==before_reject and JSON.stringify(g.export_snapshot())==JSON.stringify(template.export_snapshot()) and JSON.stringify(updated.display_facts)==JSON.stringify(template.get_view().display_facts),"fact_table_reuse_within_batch: the rejected submit leaves the snapshot and the projection equal to the from-zero path ("+key+")")
  rejected_checked+=1
 t.check(rejected_checked==2,"fact_table_reuse_within_batch: both rejection fixtures were exercised have="+str(rejected_checked))
 var submit_code=source_func_body_code("res://ui/main.gd","_submit")
 t.check(submit_code.find("notice=\"\" if result.ok else result.error")>=0 and submit_code.find("game.get_view()")>=0,"fact_table_reuse_within_batch: ui/main.gd::_submit shows the dispatch error verbatim and takes its projection after the submit")
 print("TABLE REUSE WITHIN BATCH fixtures=%d rejected=%d" % [compared,rejected_checked])

# D-3（gherkin D-3；acceptance.md §1 C-D-3）：缓存寿命＝读取批次、单一入口、不挂 self、不按键判等；
# 投影不跨就地改写窗口（core/game.gd::dispatch 内的投影取用在 state=state.duplicate(true) 之前，
# core/game.gd::get_view 仍是四点白名单）。全部为源码文本判据（生产源码）。
static func fact_table_cache_lifetime_is_pinned(t) -> void:
 var body=game_function_body("_batch_rows")
 t.check(not body.strip_edges().is_empty() and body.find("_equipment_read_active()")>=0 and body.find("BATCH_ROW_ENTRIES")>=0 and body.find("duplicate(true)")>=0,"fact_table_cache_lifetime_is_pinned: core/game.gd::_batch_rows is the one batch entry (batch check + container + deep copy): "+body.strip_edges().substr(0,120))
 var forbidden=[]
 for token in BATCH_ENTRY_FORBIDDEN:
  if body.contains(token): forbidden.append(token)
 t.check(not body.strip_edges().is_empty() and forbidden.is_empty(),"fact_table_cache_lifetime_is_pinned: the batch entry never stores on self, never keys by identity or version and never reads state: "+str(forbidden))
 var container=declaration_text(source_write_sites(["res://core","res://data","res://ui"],"BATCH_ROW_ENTRIES"),"const ")
 t.check(write_site_names(container)==["core/game.gd::_batch_rows"],"fact_table_cache_lifetime_is_pinned: the entry container is read and written only inside core/game.gd::_batch_rows: "+str(write_site_names(container)))
 var problems=[]
 for name in BATCH_ENTRY_KINDS:
  var hits=source_write_sites(["res://core","res://data","res://ui"],name)
  var uses=declaration_text(hits,"const ")
  var names=write_site_names(uses)
  var want=BATCH_ENTRY_KINDS[name].duplicate()
  want.sort()
  if names!=want or hits.size()!=want.size()+1:
   problems.append(name+": uses="+str(names)+" declarations="+str(hits.size()-uses.size()))
 t.check(problems.is_empty(),"fact_table_cache_lifetime_is_pinned: every entry name is declared once and used only at its declared call sites: "+str(problems))
 var table_sites=write_site_names(source_write_sites(["res://core","res://data","res://ui"],"(?<![A-Za-z0-9_])command_facts\\s*\\("))
 t.check(table_sites==["core/game.gd::command_facts","core/game_view.gd::build"],"fact_table_cache_lifetime_is_pinned: command_facts() is called only by core/game_view.gd::build outside any transaction (the other hit is its definition; the takeover arm names it through core/command_registry.gd::TAKEOVER_SOURCE): "+str(table_sites))
 var dispatch_body=source_func_body_code("res://core/game.gd","dispatch")
 var transaction=dispatch_body.find("state=state.duplicate(true)")
 var early=[]
 var late=[]
 for token in ["command_fact(","command_facts(","get_view("]:
  var at=dispatch_body.find(token)
  if at<0: continue
  if transaction>0 and at<transaction: early.append(token)
  else: late.append(token)
 t.check(transaction>0 and early==["command_fact("] and late.is_empty(),"fact_table_cache_lifetime_is_pinned: core/game.gd::dispatch takes its projection row before the in-place transaction window and never projects after it (state=state.duplicate(true) at "+str(transaction)+"): early="+str(early)+" late="+str(late))
 t.check(CommandRegistry.takeover_source()==FROZEN_TAKEOVER_SOURCE and FROZEN_TAKEOVER_SOURCE=="command_facts","fact_table_cache_lifetime_is_pinned: the takeover arm names the table exit (the whole-table read inside command_fact runs in its own batch): "+CommandRegistry.takeover_source())
 get_view_call_sites_are_pinned(t)
 print("BATCH CACHE LIFETIME entries=%d container=%s" % [BATCH_ENTRY_KINDS.size(),str(write_site_names(container))])

# D-4（gherkin D-4；acceptance.md §1 C-D-4；design.md §5.0 D 行）：复用路径 == 从零路径。真实输入配方
# （seed=7／cap=60／style=trade，与 tests/recipe_driver.gd 同一策略与种子）逐提交比对：live 实例（全程经
# 批内复用）与从零实例（每次比对前新建 Game ＋ export_snapshot → restore_snapshot，批内条目必空）在每次
# 提交后逐字节相等（含 key 面与顺序）。从零实例**每次重建**是关键：任一批内条目在批次边界之外存活
# （挂 self／挂实例元数据）都会让 live 侧留在上次的状态而上报红——否则两侧会一起读到同一个陈旧值。
# 类级（`static`）常驻缓存不受本 oracle 约束（两侧会一起读到它）：那一条由
# tests/architecture_cases.gd::fact_table_reuse_within_batch 的「出批必重建」与
# tests/architecture_cases.gd::point_family_rows_respect_read_scope 的跨批次变异各自钉住。
# oracle 自检：restore 后除 core/game.gd::restore_snapshot 声明的版本推进外，state 与快照逐字节相等
# （其余任一键不等即按红处理）。
static func table_reuse_matches_fresh_projection(t) -> void:
 var live=Game.new(7)
 var navigation={}
 var problems=[]
 var commits=0
 var steps=0
 var stop_reason="cap"
 var phases=[]
 while commits<60 and steps<900:
  steps+=1
  var view=live.get_view()
  var phase=String(view.phase)
  if not phases.has(phase): phases.append(phase)
  if phase in ["cleared","prison_end"]:
   stop_reason="end_phase:"+phase
   break
  var choice=NormalPlay.choose(view,"trade",navigation)
  if choice.is_empty():
   stop_reason="no_legal_step"
   break
  var before_version=int(live.state.version)
  var result=live.dispatch(live.command(choice.payload,live.state.version),live.state.version)
  if not result.ok or int(live.state.version)<=before_version: continue
  commits+=1
  NormalPlay.remember(view,choice,navigation)
  var fresh=Game.new(7)
  if not fresh._equipment_read.is_empty(): problems.append("commit "+str(commits)+": the from-zero instance held a read batch before the comparison")
  var snapshot=live.export_snapshot()
  var restored=fresh.restore_snapshot(snapshot)
  if not restored.get("ok",false):
   problems.append("commit "+str(commits)+": the from-zero instance refused the snapshot: "+str(restored.get("error","")))
   break
  var fresh_snapshot=fresh.export_snapshot()
  var state_diff=[]
  for state_key in snapshot:
   if JSON.stringify(fresh_snapshot.get(state_key))!=JSON.stringify(snapshot[state_key]): state_diff.append(String(state_key))
  if state_diff!=["version"]:
   problems.append("commit "+str(commits)+": the restored state differs beyond the declared version bump: "+str(state_diff))
  if int(fresh.state.version)<=int(snapshot.version):
   problems.append("commit "+str(commits)+": restore_snapshot did not advance the version have="+str(fresh.state.version)+" snapshot="+str(snapshot.version))
  var live_face=prefix_branch_table_face(live)
  var fresh_face=prefix_branch_table_face(fresh)
  if live_face!=fresh_face:
   var live_rows=live.command_facts()
   problems.append("commit "+str(commits)+" kind="+String(choice.payload.kind)+" version="+str(live.state.version)+": reused table differs from the from-zero table live="+live_face+" fresh="+fresh_face+" rows="+str(live_rows.size()))
  var held_batch=live._begin_equipment_read()
  var held_first=prefix_branch_table_face(live)
  var held_second=prefix_branch_table_face(live)
  live._equipment_read=held_batch
  if held_first!=fresh_face or held_second!=fresh_face:
   problems.append("commit "+str(commits)+": the batch-held table differs from the from-zero table live="+held_first+"/"+held_second+" fresh="+fresh_face)
 t.check(problems.is_empty(),"table_reuse_matches_fresh_projection: every commit projects byte-identically through the batch entry and from a from-zero instance: "+str(problems.slice(0,3)))
 t.check(commits==60 and stop_reason=="cap","table_reuse_matches_fresh_projection: the recipe committed 60 times before its natural end have="+str(commits)+" stop="+stop_reason)
 print("TABLE REUSE FRESH ORACLE commits=%d steps=%d stop=%s phases=%s" % [commits,steps,stop_reason,str(phases)])

# D 批审查加固 1（K1-D 的「批内污染」面）：复用／取用的边界不可污染——① 批内取回的条目被调用方就地改写
# （core/game_view.gd::build 的 release_preview 写点同形：改行 ＋ 增删容器项）后，同批内的第二次取用仍必须
# 与从零路径逐字节相等；三条批内条目逐条核（整表／攻击走查／逐卡行——C 批的 card 首算路径曾把活数组存批
# 又原样返回，同批内第二次同 uid 读会读到被第一个调用方污染的值）；
# ② 同一张表里重复归一化 params 的两行必须是互不别名的独立等值字典（改动前两步路径逐项构造；同一引用
# 两行会让调用方写一行改两行）。
static func batch_reuse_never_aliases_callers(t) -> void:
 var problems=[]
 var compared=0
 for cell in [["battle",12],["prepare",12],["prison",12]]:
  var label="%s:%d" % [cell[0],cell[1]]
  var g=r1_build(cell[0],cell[1],ReuseRecorder)
  var reference=r1_build(cell[0],cell[1],ReuseRecorder)
  var expected={}
  var first={}
  expected["table"]=JSON.stringify(reference.command_facts())
  expected["attack_walk"]=JSON.stringify(reference.attack_facts())
  expected["equipment_spell"]=JSON.stringify(reference.equipment_spell_facts())
  var previous=g._begin_equipment_read()
  first["table"]=JSON.stringify(g.command_facts())
  first["attack_walk"]=JSON.stringify(g.attack_facts())
  first["equipment_spell"]=JSON.stringify(g.equipment_spell_facts())
  for card in reference.state.hand:
   var key="card:"+String(card.uid)
   expected[key]=JSON.stringify(reference.Cards.card_facts(reference,card))
   first[key]=JSON.stringify(g.Cards.card_facts(g,card))
  # 调用方就地改写（release_preview 写点同形：写成员 ＋ 增删容器项），批次内条目必须毫发无损。
  for row in g.command_facts(): row.release_preview={"probe":true}
  for pair in g.attack_facts(): pair.probe=true
  for pair in g.equipment_spell_facts(): pair.probe=true
  for card in g.state.hand:
   var rows=g.Cards.card_facts(g,card)
   for row in rows: row.release_preview={"probe":true}
   rows.append({"probe":true})
  var second={}
  second["table"]=JSON.stringify(g.command_facts())
  second["attack_walk"]=JSON.stringify(g.attack_facts())
  second["equipment_spell"]=JSON.stringify(g.equipment_spell_facts())
  for card in g.state.hand: second["card:"+String(card.uid)]=JSON.stringify(g.Cards.card_facts(g,card))
  g._equipment_read=previous
  for key in expected:
   if first.get(key,"")!=expected[key] or second.get(key,"")!=expected[key]:
    problems.append(label+" "+key+": a caller writing into the rows it got back changed the batch entry (first_equal="+str(first.get(key,"")==expected[key])+" second_equal="+str(second.get(key,"")==expected[key])+")")
  compared+=1
 t.check(problems.is_empty(),"batch_reuse_never_aliases_callers: every batch entry only hands out deep copies, so an in-batch writer cannot pollute the table, the walk or the card rows: "+str(problems))
 t.check(compared==3,"batch_reuse_never_aliases_callers: every fixture cell exercised the in-batch writer on all three entries have="+str(compared))
 # ② 重复归一化 params 的两行：等值但不同一（attack 走查的两条 pair row——重复夹具由既有
 # attack_duplicate_params_fixture 给出，按归一化 params 成组）。
 var duplicate_groups=0
 var g=attack_duplicate_params_fixture()
 var by_params={}
 for pair in g.attack_point_walk(g):
  var key=JSON.stringify(pair.params)
  if not by_params.has(key): by_params[key]=[]
  by_params[key].append(pair.row)
 for key in by_params:
  var group=by_params[key]
  if group.size()<2: continue
  duplicate_groups+=1
  for index in range(1,group.size()):
   if is_same(group[0],group[index]):
    problems.append("attack: duplicate normalized params share one row object")
    continue
   if JSON.stringify(group[0])!=JSON.stringify(group[index]):
    problems.append("attack: duplicate normalized params are not equal rows")
    continue
   group[0].probe_marker=true
   if group[index].has("probe_marker"): problems.append("attack: writing one duplicate row leaked into the other")
   group[0].erase("probe_marker")
 t.check(duplicate_groups>0 and problems.is_empty(),"batch_reuse_never_aliases_callers: duplicate normalized params yield independent equal rows (the pre-change two-step path built one dictionary per enumeration item): groups="+str(duplicate_groups)+" "+str(problems))
 print("BATCH REUSE ALIAS cells=%d duplicate_groups=%d" % [compared,duplicate_groups])

# D 批审查加固 2（K1-D 的「空行静默面」）：走查产出的行永不空。D 前的两条表生产者有 is_empty 过滤，C 批
# 改走查后改为无条件取行——今天等价，将来任一家族回 {} 就会静默多一条空行（与改动前不等价）。落点＝
# **两条同时做**、理由是它们各补一半：① 恢复改动前的空行过滤（语义面：任何未来家族回 {} 都与改动前逐字节
# 等价，不再多一条空行）；② 机械判据「走查产出的每一条 row 都非空」＋「两条生产者的取行都有该过滤」
# （文本面：过滤今天不吞任何行，将来家族回 {} 时本判据先红，过滤不会退化成静默少一行）。只做②时，
# 矩阵外的家族仍可静默回 {}；只做①时，家族缺陷会被静默吞掉。覆盖＝r1_cells()（除接管）＋装备自解／巫女／
# 重复 params／逐卡分支族夹具；家族覆盖计数全 0 即红。
static func walk_rows_are_never_empty(t) -> void:
 var guarded=[]
 for row in TABLE_WALK_ENTRIES:
  if not String(row[0]).ends_with("core/game.gd"): continue
  var body=table_walk_entry_body(String(row[0]),String(row[1]))
  var guard=body.find("if pair.row.is_empty(): continue")
  var take=body.find("facts.append(pair.row)")
  if guard<0 or take<0 or guard>take: guarded.append(String(row[1])+": guard="+str(guard)+" append="+str(take))
 t.check(guarded.is_empty(),"walk_rows_are_never_empty: both table halves keep the pre-change empty-row guard before taking the walk row (a family returning {} must not add a silent empty row): "+str(guarded))
 var fixtures=[]
 for cell in r1_cells():
  if cell[0]=="takeover": continue
  fixtures.append(["%s:%d" % [cell[0],cell[1]],r1_build(cell[0],cell[1])])
 fixtures.append(["prepare:12+self_release",attack_self_release_fixture("prepare",12)])
 fixtures.append(["witch:battle",Game.new(42,false,"equipment",true,false,25,false,false,"witch")])
 fixtures.append(["duplicate_params",attack_duplicate_params_fixture()])
 fixtures.append(["branch:battle:26",card_branch_fixture(t,"battle",26)])
 fixtures.append(["exhaust_fallback:strong_elbow",card_exhaust_fallback_fixture(t,"strong_elbow")])
 var families={"basic":0,"witch":0,"self_release":0}
 var problems=[]
 var pairs_seen=0
 for entry in fixtures:
  var label=String(entry[0])
  var g=entry[1]
  for pair in g.attack_point_walk(g):
   pairs_seen+=1
   var row=pair.get("row",null)
   if not (row is Dictionary) or (row as Dictionary).is_empty():
    problems.append(label+": the walk produced an empty row for params "+JSON.stringify(pair.get("params",{})))
    continue
   var family="self_release"
   if String(pair.params.get("target",""))=="":
    family="witch" if String(pair.params.get("type","")).begins_with("witch_") else "basic"
   families[family]=int(families[family])+1
 t.check(problems.is_empty(),"walk_rows_are_never_empty: every row the walk produces is a complete fact row (the guard above never fires today, so a family returning {} is caught here before it becomes a silent dropped row): "+str(problems.slice(0,4)))
 t.check(pairs_seen>0 and int(families["basic"])>0 and int(families["witch"])>0 and int(families["self_release"])>0,"walk_rows_are_never_empty: the fixture matrix covers every walk family: "+str(families)+" pairs="+str(pairs_seen))
 print("WALK ROWS NONEMPTY fixtures=%d pairs=%d families=%s" % [fixtures.size(),pairs_seen,str(families)])

static func pipeline_lookup_inspect(t) -> void:
 var edges=pipeline_lookup_edges()
 t.check(edges.size()==2,"pipeline_lookup_inspect: PIPELINE_LOOKUP_EDGES is exactly two lookup edges have="+str(edges.size()))
 var by_id={}
 var signatures=[]
 for edge in edges:
  var id=String(edge.get("id",""))
  var from_fn=pipeline_lookup_func_name(edge.get("from",""))
  var signature=String(edge.get("from",""))+" -> "+String(edge.get("to",""))+" / "+String(edge.get("type",""))
  t.check(id!="" and not by_id.has(id) and signature not in signatures,"pipeline_lookup_inspect: L-point and L-table must be distinct id/from/to: "+id+" "+signature)
  t.check(String(edge.get("type",""))=="call" and from_fn in PIPELINE_LOOKUP_FUNCS,"pipeline_lookup_inspect: lookup edge is a call from an extracted func: "+id+" "+from_fn)
  by_id[id]=edge
  signatures.append(signature)
 t.check(by_id.has("L-point") and by_id.has("L-table"),"pipeline_lookup_inspect: table ids are L-point / L-table")
 var bodies={}
 for name in PIPELINE_LOOKUP_FUNCS:
  bodies[name]=pipeline_lookup_func_body(name)
  t.check(not String(bodies[name]).strip_edges().is_empty(),"pipeline_lookup_inspect: extracted body is non-empty for "+name)
 var command_fact_body=bodies["command_fact"]
 var point_to=pipeline_lookup_func_name(by_id["L-point"].to)
 var table_to=pipeline_lookup_func_name(by_id["L-table"].to)
 t.check(pipeline_lookup_call_count(command_fact_body,"command_facts")==0,"pipeline_lookup_inspect: command_fact body has no command_facts(")
 t.check(pipeline_lookup_call_count(command_fact_body,"_command_fact_row")==1 and pipeline_lookup_call_count(command_fact_body,point_to)==0 and pipeline_lookup_call_count(command_fact_body,table_to)==0,"pipeline_lookup_inspect: L-point unique path starts at exactly one _command_fact_row(")
 var nontakeover=pipeline_lookup_nontakeover_row(bodies["_command_fact_row"])
 t.check(not nontakeover.strip_edges().is_empty() and pipeline_lookup_call_count(nontakeover,"CommandRegistry.point")==1 and pipeline_lookup_call_count(nontakeover,point_to)==1,"pipeline_lookup_inspect: nontakeover _command_fact_row has CommandRegistry.point( and display_fact(")
 t.check(pipeline_lookup_call_count(nontakeover,table_to)==0 and pipeline_lookup_call_count(nontakeover,"command_facts")==0,"pipeline_lookup_inspect: nontakeover _command_fact_row is a single path (no _fact_source( / command_facts()")
 var kind_body=bodies["_kind_facts"]
 t.check(pipeline_lookup_default_arm(kind_body).is_empty(),"pipeline_lookup_inspect: _kind_facts has no _: fallback arm")
 t.check(kind_body.find("CommandRegistry.entry(")>=0 and kind_body.find("_fact_source")<0,"pipeline_lookup_inspect: _kind_facts reads the registry entry and never falls back to _fact_source()")
 var row_body=bodies["_command_fact_row"]
 t.check(pipeline_lookup_call_count(row_body,"CommandRegistry.takeover_source")==1,"pipeline_lookup_inspect: the takeover branch takes its table item from the registry")
 var g=GameCore.new(42)
 var takeover_source=CommandRegistry.takeover_source()
 t.check(not takeover_source.is_empty() and g.has_method(takeover_source),"pipeline_lookup_inspect: the takeover table item names an existing g source: "+takeover_source)
 var unnamed=[]
 for kind in ["relic_bundle","departure"]:
  var item=CommandRegistry.entry(kind)
  if String(item.get("form",""))!="table" or String(item.get("source",""))=="": unnamed.append(kind)
 t.check(unnamed.is_empty(),"pipeline_lookup_inspect: relic_bundle and departure carry an explicit table source: "+str(unnamed))
 # C2 运行期：未登记 kind fail-closed（空行，且不触达 _fact_source）。
 var probe=FactSourceCountingGame.new(42)
 probe.fact_source_calls=0
 var unknown=probe.command_fact({"kind":"no_such_kind","params":{},"expected_version":probe.state.version})
 t.check(unknown.is_empty(),"pipeline_lookup_inspect: an unregistered kind yields an empty row")
 t.check(probe.fact_source_calls==0,"pipeline_lookup_inspect: an unregistered kind never reaches _fact_source (calls="+str(probe.fact_source_calls)+")")
 var table_body=bodies["command_facts"]
 t.check(pipeline_lookup_func_name(by_id["L-table"].from)!="command_fact" and pipeline_lookup_call_count(table_body,table_to)==1 and pipeline_lookup_call_count(table_body,"display_fact")==1,"pipeline_lookup_inspect: command_facts body has _fact_source( and display_fact(")
 var p2_ids=[]
 var p2_froms=[]
 for edge in PIPELINE_P2_EDGES:
  p2_ids.append(String(edge.get("id","")))
  p2_froms.append(String(edge.get("from","")))
  t.check(String(edge.get("to",""))=="core/game.gd::eligibility" and String(edge.get("type",""))=="call","pipeline_lookup_inspect: P2 call edge to=eligibility: "+String(edge.get("id","")))
 t.check(PIPELINE_P2_EDGES.size()==2 and p2_ids.has("T4") and p2_ids.has("T5") and p2_froms.size()==2 and p2_froms[0]!=p2_froms[1],"pipeline_lookup_inspect: P2 declares T4/T5 call edges to eligibility")
 t.check(VERDICT_PRODUCERS.get("core/game.gd",[]).has("eligibility"),"pipeline_lookup_inspect: P2 write sites stay on G4 VERDICT_PRODUCERS (no second write scan)")

# docs/spec/candidate-removal.md T4：command_fact 经登记项取行（table 形首条 params 命中），不经全表。
static func command_fact_kind_lookup(t) -> void:
 pipeline_lookup_inspect(t)
 var compared=0
 var kinds_covered={}
 for cell in T4_EQUIVALENCE_CELLS:
  var g=r1_build(cell[0],cell[1])
  var key="%s:%d" % [cell[0],cell[1]]
  var facts=g.command_facts()
  var view=g.get_view()
  t.check(facts.size()==int(R5_BASELINE[key].view_display_facts),"T4 command_facts count matches the pre-slice snapshot "+key+" have="+str(facts.size())+" want="+str(R5_BASELINE[key].view_display_facts))
  t.check(view.display_facts.size()==facts.size(),"T4 get_view display_facts count stays aligned with command_facts "+key)
  for fact in facts:
   var found=g.command_fact(g.command(fact.payload,g.state.version))
   t.check(found==fact,"T4 command_fact matches the full-table row kind="+String(fact.payload.kind)+" key="+String(fact.get("key",""))+" fixture="+key)
   compared+=1
   kinds_covered[String(fact.payload.get("kind",""))]=true
 print("T4 ROW EQUIVALENCE cells=%d rows=%d kinds=%d" % [T4_EQUIVALENCE_CELLS.size(),compared,kinds_covered.size()])
 t.check(compared>0 and kinds_covered.has("card") and kinds_covered.has("flask"),"T4 command_fact compared every table row of the fixture matrix (card and flask covered)")
 var miss=r1_build("battle",0)
 t.check(miss.command_fact({"kind":"flask","params":{"op":"no_such"},"expected_version":miss.state.version}).is_empty(),"T4 command_fact miss is an empty dictionary")
 var body=pipeline_lookup_func_body("command_fact")
 t.check(body!="" and pipeline_lookup_call_count(body,"command_facts")==0,"T4 command_fact does not scan command_facts(); turning this off still leaves the row-equality checks")
 var dense=t4_dense_51()
 t.check(dense.physical_pieces().size()==51 and dense.validate()=="","T4 51-piece lookup fixture")
 var table=dense.command_facts()
 var flask_cmd={}
 var attack_cmd={}
 for fact in table:
  if flask_cmd.is_empty() and String(fact.payload.get("kind",""))=="flask": flask_cmd=dense.command(fact.payload,dense.state.version)
  if attack_cmd.is_empty() and String(fact.payload.get("kind",""))=="attack" and String(fact.payload.get("target",""))=="": attack_cmd=dense.command(fact.payload,dense.state.version)
  if not flask_cmd.is_empty() and not attack_cmd.is_empty(): break
 t.check(not flask_cmd.is_empty() and not attack_cmd.is_empty(),"T4 51-piece fixture exposes flask and attack commands")
 dense.command_fact(flask_cmd)
 dense.command_fact(attack_cmd)
 var flask_samples=[];var attack_samples=[];var table_samples=[]
 for i in range(7):
  var a=Time.get_ticks_usec()
  dense.command_fact(flask_cmd)
  flask_samples.append(Time.get_ticks_usec()-a)
  a=Time.get_ticks_usec()
  dense.command_fact(attack_cmd)
  attack_samples.append(Time.get_ticks_usec()-a)
 for i in range(3):
  var a=Time.get_ticks_usec()
  dense.command_facts()
  table_samples.append(Time.get_ticks_usec()-a)
 var flask_med=t4_median(flask_samples)
 var attack_med=t4_median(attack_samples)
 var table_med=t4_median(table_samples)
 print("T4 LOOKUP MEDIAN flask_us=%d attack_us=%d command_facts_us=%d pieces=51" % [flask_med,attack_med,table_med])
 t.check(flask_med*3<table_med,"T4 flask command_fact still scans the full table if this timing assertion fails flask_us="+str(flask_med)+" command_facts_us="+str(table_med))

# S5（plan §5 S5 出口判据①②；gherkin S5-1／S5-2）：每提交只查一次事实出口，提交前预查询删除，
# 呈现输入与改动前「提交前查询」逐字段相等。旧键面与旧行为期望在测试侧独立写出，不由实现派生。
const S5_SUBMIT_KEYS_BEFORE=["ok","version","resource_feedback","card_feedback","music_feedback","checkpoint","spell_failed"]
const S5_SUBMIT_KEYS_AFTER=["ok","version","resource_feedback","card_feedback","music_feedback","checkpoint","spell_failed","fact"]
const S5_REJECT_KEYS=["ok","error","fact"]
# B2（切片收尾批）：S5 重算 `submit_keys` 的理由常驻可复跑。旧键面（`S5_SUBMIT_KEYS_BEFORE`）的摘要
# 必须等于 S5 之前的冻结值，新键面（`S5_SUBMIT_KEYS_AFTER`）的摘要即重算后写进 `R5_BASELINE.<record>`
# 的那一个值；两者都取自 S5 自证轮 `20261004T133011360-19112`（该轮打印的 `submit_keys` 与旧冻结
# `<record>` 的推导，同法复核过：新键面摘要与该轮 `S5 REBASELINE submit_keys=` 逐字符相同）。
const S5_SUBMIT_KEYS_BEFORE_DIGEST="93a45a7bba1ccfdae5f52a2e82831d5e"
const S5_SUBMIT_KEYS_AFTER_DIGEST="5e6001580b5d714c2a081120d4019532"

# 源码文本助手（S5 用；既有 pipeline_lookup_func_body 只覆盖 core/game.gd 的四个锚点）。
static func source_func_text(path: String, name: String) -> String:
 var handle=FileAccess.open(path,FileAccess.READ)
 if handle==null: return ""
 var source=handle.get_as_text()
 var start=source.find("func "+name+"(")
 if start<0: return ""
 var rest=source.substr(start)
 var nxt=rest.find("\nfunc ",1)
 return rest if nxt<0 else rest.substr(0,nxt)

static func source_func_code(path: String, name: String) -> String:
 var code=""
 for line in source_func_text(path,name).split("\n"): code+=String(line).split("#")[0]+"\n"
 return code

static func source_func_body_code(path: String, name: String) -> String:
 var code=source_func_code(path,name)
 var at=code.find("\n")
 return "" if at<0 else code.substr(at+1)

static func source_func_params(path: String, name: String) -> Array:
 var text=source_func_text(path,name)
 var open=text.find("(")
 var close=text.find(")",open)
 var names=[]
 if open<0 or close<0: return names
 for part in text.substr(open+1,close-open-1).split(",",false):
  var head=String(part).strip_edges().split(":")
  var param=String(head[0]).strip_edges()
  if param!="": names.append(param)
 return names

# C5（S5 出口判据①）：一次成功提交只发生一次 command_fact（dispatch 内），ui/main.gd::_submit 内 0 次
# （源码级：提交执行段是 UI 侧唯一提交路径）。每次提交打印计数。
static func single_fact_lookup_per_submit(t) -> void:
 var submit_code=source_func_body_code("res://ui/main.gd","_submit")
 t.check(submit_code.find("dispatch(")>=0,"S5 single_fact_lookup_per_submit: ui/main.gd::_submit body is extracted with its dispatch call")
 var submit_calls=pipeline_lookup_call_count(submit_code,"command_fact")
 t.check(submit_calls==0,"S5 single_fact_lookup_per_submit: ui/main.gd::_submit has no pre-submit command_fact( call have="+str(submit_calls))
 t.check(submit_code.find("result.get(\"fact\",{})")>=0,"S5 single_fact_lookup_per_submit: ui/main.gd::_submit takes the judgement row from the dispatch result")
 t.check(pipeline_lookup_call_count(submit_code,"dispatch")==1,"S5 single_fact_lookup_per_submit: ui/main.gd::_submit keeps exactly one dispatch call")
 var submissions=0
 var kinds={}
 var keys_printed=false
 for cell in [["battle",0],["battle",12],["prepare",12],["prison",12]]:
  var picked=[]
  var table=r1_build(cell[0],cell[1]).command_facts()
  if table.any(func(row):return row.valid and String(row.payload.get("kind",""))=="end"): picked.append("end")
  for row in table:
   if not row.valid or picked.size()>=3: continue
   var row_kind=String(row.payload.get("kind",""))
   if row_kind in picked: continue
   picked.append(row_kind)
  for kind in picked:
   var g=r1_build(cell[0],cell[1],SubmitLookupCountingGame)
   var cmd={}
   for row in g.command_facts():
    if row.valid and String(row.payload.get("kind",""))==kind:
     cmd=g.command(row.payload,g.state.version)
     break
   if cmd.is_empty(): continue
   g.fact_calls=0
   var result=g.dispatch(cmd,g.state.version)
   var calls=g.fact_calls
   print("S5 SINGLE LOOKUP fixture=%s:%d kind=%s command_fact: dispatch=%d submit=%d" % [cell[0],cell[1],kind,calls,submit_calls])
   t.check(result.ok and calls==1,"S5 single_fact_lookup_per_submit: one successful submit performs exactly one command_fact inside dispatch fixture=%s:%d kind=%s calls=%d" % [cell[0],cell[1],kind,calls])
   if result.ok:
    if not keys_printed:
     keys_printed=true
     print("S5 DISPATCH KEYS before=%s after=%s" % [str(S5_SUBMIT_KEYS_BEFORE),str(result.keys())])
    t.check(result.keys()==E_SUBMIT_KEYS,"S5 single_fact_lookup_per_submit: the success result carries the declared post-E key face (S5_SUBMIT_KEYS_AFTER stays as the frozen self-proof face) fixture=%s:%d kind=%s have=%s" % [cell[0],cell[1],kind,str(result.keys())])
   submissions+=1
   kinds[kind]=true
 t.check(submissions>=4 and kinds.has("end"),"S5 single_fact_lookup_per_submit: several real fixtures and kinds were sampled submits="+str(submissions)+" kinds="+str(kinds.keys()))

# 失败路径（gherkin S5-1 第二场景）：陈旧 version／形状不合法／判定不通过各自按精确次数查询
# （陈旧 version 0 次、形状不合法 0 次、判定不通过 1 次；B4 收尾批按冻结轮实测收紧，不再用 ≤1），
# 拒绝文案逐字不变、export_snapshot() 相等、失败结果不带判定行。期望文案取自冻结基线 R1_BASELINE 的
# reject_stale／reject_invalid 与形状复核既有文案，不由被测实现派生。
static func rejected_submit_lookup_counts(t) -> void:
 for cell in [["battle",0],["prison",12]]:
  var key="%s:%d" % [cell[0],cell[1]]
  var template=r1_build(cell[0],cell[1])
  var usable={}
  var invalid={}
  for row in template.command_facts():
   if usable.is_empty() and row.valid: usable=row
   if invalid.is_empty() and not row.valid: invalid=row
  t.check(not usable.is_empty() and not invalid.is_empty(),"S5 rejected_submit_lookup_counts: fixture exposes a valid and an invalid row "+key)
  var stale_text=String(R1_BASELINE[key].get("reject_stale",""))
  var invalid_text=String(R1_BASELINE[key].get("reject_invalid",""))
  # 陈旧 expected_version：版本比对在判定之前，零次查询。
  var g=r1_build(cell[0],cell[1],SubmitLookupCountingGame)
  var version=int(g.state.version)
  var before=g.export_snapshot()
  g.fact_calls=0
  var stale=g.dispatch(g.command(usable.payload,version-1),version-1)
  print("S5 REJECT stale fixture=%s command_fact=%d error=%s" % [key,g.fact_calls,str(stale.get("error",""))])
  t.check(not stale.ok and String(stale.get("error",""))==stale_text,"S5 rejected_submit_lookup_counts: stale version keeps the verbatim rejection "+key+" have="+str(stale.get("error","")))
  t.check(g.fact_calls==0 and g.export_snapshot()==before,"S5 rejected_submit_lookup_counts: stale rejection performs no lookup and leaves the snapshot equal "+key+" calls="+str(g.fact_calls))
  t.check(stale.keys()==S5_REJECT_KEYS and stale.get("fact",{}).is_empty(),"S5 rejected_submit_lookup_counts: a rejection result carries an empty fact and the declared keys "+key+" have="+str(stale.keys()))
  # 形状不合法：未登记 kind 与声明外参数键都在形状复核早退，零次查询。
  g=r1_build(cell[0],cell[1],SubmitLookupCountingGame)
  version=int(g.state.version)
  before=g.export_snapshot()
  g.fact_calls=0
  var unknown=g.dispatch({"kind":"no_such_kind","params":{},"expected_version":version},version)
  var forged=g.dispatch({"kind":"end","params":{"no_such_param":1},"expected_version":version},version)
  t.check(not unknown.ok and not forged.ok and String(unknown.get("error",""))=="该行动已经失效，请重新选择。" and String(forged.get("error",""))=="该行动已经失效，请重新选择。" and g.fact_calls==0,"S5 rejected_submit_lookup_counts: an invalid shape is refused before any lookup "+key+" calls="+str(g.fact_calls))
  t.check(g.export_snapshot()==before,"S5 rejected_submit_lookup_counts: shape rejections leave the snapshot equal "+key)
  # 判定不通过（valid=false）：走到判定恰一次，error 为 reason 原文。
  g=r1_build(cell[0],cell[1],SubmitLookupCountingGame)
  version=int(g.state.version)
  before=g.export_snapshot()
  g.fact_calls=0
  var judged=g.dispatch(g.command(invalid.payload,version),version)
  print("S5 REJECT invalid fixture=%s command_fact=%d error=%s" % [key,g.fact_calls,str(judged.get("error",""))])
  t.check(not judged.ok and String(judged.get("error",""))==invalid_text,"S5 rejected_submit_lookup_counts: an invalid row keeps the verbatim reason "+key+" have="+str(judged.get("error","")))
  t.check(g.fact_calls==1 and g.export_snapshot()==before,"S5 rejected_submit_lookup_counts: an invalid row looks up exactly once and leaves the snapshot equal "+key+" calls="+str(g.fact_calls))
  t.check(judged.keys()==S5_REJECT_KEYS and judged.get("fact",{}).is_empty(),"S5 rejected_submit_lookup_counts: a judged rejection carries an empty fact "+key+" have="+str(judged.keys()))

# C10（S5 出口判据②；gherkin S5-2）：ok 路径的呈现输入＝改动前提交前查询的结果（逐字段与逐字节）；
# 失败路径不读该行（ui/first_turn_presenter.gd::outcome 第四参数）。
static func submit_presented_fact_is_unchanged(t) -> void:
 var compared=0
 for cell in [["battle",12],["prepare",12],["prison",12]]:
  var picked=[]
  for row in r1_build(cell[0],cell[1]).command_facts():
   if not row.valid: continue
   var row_kind=String(row.payload.get("kind",""))
   if row_kind in picked or picked.size()>=2: continue
   picked.append(row_kind)
  for kind in picked:
   var old_g=r1_build(cell[0],cell[1])
   var new_g=r1_build(cell[0],cell[1])
   var cmd={}
   for row in old_g.command_facts():
    if row.valid and String(row.payload.get("kind",""))==kind:
     cmd=old_g.command(row.payload,old_g.state.version)
     break
   if cmd.is_empty(): continue
   # 旧行为：ui/main.gd::_submit 提交前的命令事实查询（S5 已从提交执行段删除，本用例在测试侧复现取值）。
   var old_row=old_g.command_fact(cmd)
   var old_result=old_g.dispatch(cmd,old_g.state.version)
   var new_result=new_g.dispatch(new_g.command(old_row.payload,new_g.state.version),new_g.state.version)
   t.check(old_result.ok and new_result.ok,"S5 submit_presented_fact_is_unchanged: the sample submit commits on both sides fixture=%s:%d kind=%s" % [cell[0],cell[1],kind])
   t.check(new_result.fact==old_row,"S5 submit_presented_fact_is_unchanged: the dispatch fact equals the pre-submit lookup row field-for-field fixture=%s:%d kind=%s" % [cell[0],cell[1],kind])
   t.check(JSON.stringify(new_result.fact)==JSON.stringify(old_row),"S5 submit_presented_fact_is_unchanged: payload and display fields stay byte-equal to the pre-submit lookup fixture=%s:%d kind=%s" % [cell[0],cell[1],kind])
   t.check(old_result==new_result,"S5 submit_presented_fact_is_unchanged: the submission result is identical with and without the pre-submit lookup fixture=%s:%d kind=%s" % [cell[0],cell[1],kind])
   t.check(old_g.export_snapshot()==new_g.export_snapshot(),"S5 submit_presented_fact_is_unchanged: the pre-submit lookup never perturbs the committed state fixture=%s:%d kind=%s" % [cell[0],cell[1],kind])
   compared+=1
 print("S5 PRESENTED FACT compared=%d" % compared)
 t.check(compared>=3,"S5 submit_presented_fact_is_unchanged: several real submits compared rows="+str(compared))
 var outcome_params=source_func_params("res://ui/first_turn_presenter.gd","outcome")
 var outcome_body=source_func_body_code("res://ui/first_turn_presenter.gd","outcome")
 t.check(outcome_params.size()==4 and outcome_body.find("cue")>=0,"S5 submit_presented_fact_is_unchanged: first_turn_presenter.outcome body and its four parameters are extracted have="+str(outcome_params))
 var payload_param="c" if outcome_params.size()!=4 else String(outcome_params[3])
 var uses_payload=RegEx.new()
 uses_payload.compile("\\b"+payload_param+"\\b")
 t.check(uses_payload.search(outcome_body)==null,"S5 submit_presented_fact_is_unchanged: first_turn_presenter.outcome never reads its fourth argument ("+payload_param+")")

# B2（R6 第 9 条②）：G6 自证永久化——去掉 `fact` 的键面摘要 == S5 前的冻结值，使「S5 为何重算基线」
# 随时可复跑自证，而不是只存在于已移除的一次性临时码日志里。期望侧字面常量见上方
# `S5_SUBMIT_KEYS_*_DIGEST`，不由实现派生；`r1_digest` 与 `r1_record` 的 `submit_keys` 同一算法。
static func submit_key_face_rebaseline_self_proof(t) -> void:
 var before=r1_digest(JSON.stringify(S5_SUBMIT_KEYS_BEFORE))
 var after=r1_digest(JSON.stringify(S5_SUBMIT_KEYS_AFTER))
 print("S5 KEY FACE SELF PROOF before=%s after=%s" % [before,after])
 t.check(before==S5_SUBMIT_KEYS_BEFORE_DIGEST,"S5 submit_key_face_rebaseline_self_proof: the pre-fact key face hashes to the pre-S5 frozen value have="+before+" want="+S5_SUBMIT_KEYS_BEFORE_DIGEST)
 t.check(after==S5_SUBMIT_KEYS_AFTER_DIGEST,"S5 submit_key_face_rebaseline_self_proof: the post-fact key face hashes to the rebaselined value have="+after+" want="+S5_SUBMIT_KEYS_AFTER_DIGEST)

# ==== C1（切片收尾批，R6 C1／S5 审查 [存疑] 的硬化；R14 修正批放宽写形态）：判定行只读与 payload 写点白名单 ====
# docs/spec/candidate-removal.md §2.1「事实行只读」：判定行与其 payload 自产出起只读；UI 与执行共享
# 同一对象（不拷贝），故 dispatch 的执行段只写 state（经既有 action_copy／logs／feedback 机制），不得写
# 判定行或其 payload；将来「执行时要记结算结果」的落点是 state，不是事实行。
# 口径：core/game.gd::dispatch 体内对局部 `chosen` 的成员／索引赋值（`chosen.<字段> …=`、`chosen["…"] …=`、
# `chosen.payload…=`）；`==`／`!=`／`<`／`>` 比较与只读取用、以及 `FirstTurnControl.commit(self,chosen)`
# 这类传参不算。源码文本去注释沿用既有的 `#` 截断。
const FACT_ROW_WRITE_PATTERN="\\bchosen(?:\\.[A-Za-z_][A-Za-z0-9_]*|\\[[^\\]]*\\])+\\s*[-+*/%&|^]?=(?!=)"

# 全仓 payload 写点扫描（C1 第二半；口径与逃逸面见 docs/spec/fact-lookup-dependencies.md 禁止项）：
# 写形态＝「接收者**末段**恰为 `payload`」的成员赋值 `.field=`（含 `+=` 等复合赋值）与索引赋值 `[…]=`，
# 外加改字典内容的 `payload.merge(`／`payload.erase(`／`payload.clear(`。段边界用 `\b`（前一字符不是
# [A-Za-z0-9_]）：`chosen.payload.probe=`／`chosen.payload["x"]=` 计入（末段是 payload）；
# `attack_payload.x=`／`target_payload[0]=` 不计（末段是 attack_payload／target_payload，不是本判据语域的载荷）。
const PAYLOAD_WRITE_PATTERN="\\bpayload(?:\\s*(?:\\.[A-Za-z_][A-Za-z0-9_]*|\\[[^\\]]*\\]))+\\s*[-+*/%&|^]?=(?!=)"
const PAYLOAD_MUTATOR_CALL_PATTERN="\\bpayload\\s*\\.\\s*(?:merge|erase|clear)\\s*\\("

# 白名单按写点**出现次数**逐条登记（R14：同一函数内的第二处写——即使在同一行——也会多出一条并使集合断言红）；
# 集合断言＝多一处或少一处都红。这不是「共享行只读」的证明，只是 core/＋data/ 全部 .gd 内的写点计数钉；
# 已知逃逸面（dispatch 外的 `chosen` 成员形写、ui/ 侧写入、局部别名、把 payload 传给 helper 由 helper 写）
# 逐条登记在 docs/spec/fact-lookup-dependencies.md 禁止项。
# C 批（K3）：card 单行构造的 payload 收尾写入从 core/card_effects.gd::card_point_fact 移到唯一单行构造器
# core/card_effects.gd::_card_point_row（point 构造与表 pass 共用），写点条数与位置面只此一处移动。
const PAYLOAD_WRITE_WHITELIST=["res://core/card_effects.gd::_card_point_row","res://core/card_effects.gd::_card_point_row","res://core/prison.gd::add"]

static func dispatch_fact_row_is_readonly(t) -> void:
 var body=source_func_body_code("res://core/game.gd","dispatch")
 t.check(not body.strip_edges().is_empty() and body.find("command_fact(cmd)")>=0,"ARCH dispatch_fact_row_is_readonly (core/game.gd::dispatch): the body is extracted with its judgement lookup have="+str(body.length()))
 var row_write=RegEx.new()
 row_write.compile(FACT_ROW_WRITE_PATTERN)
 var hits=[]
 for hit in row_write.search_all(body): hits.append(hit.get_string())
 print("FACT ROW READONLY SCAN hits=%d domain=core/game.gd::dispatch" % hits.size())
 t.check(hits.is_empty(),"ARCH dispatch_fact_row_is_readonly (core/game.gd::dispatch): the judgement row and its payload are only read after command_fact produces them (UI and execution share the same object, so a write here would leak into the UI); writes="+str(hits))

static func payload_write_sites() -> Dictionary:
 var write=RegEx.new()
 write.compile(PAYLOAD_WRITE_PATTERN)
 var mutator=RegEx.new()
 mutator.compile(PAYLOAD_MUTATOR_CALL_PATTERN)
 var declaration=RegEx.new()
 declaration.compile("^\\s*(?:static\\s+)?func\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")
 var sites=[]
 var files=0
 for file in script_files("res://core")+script_files("res://data"):
  var handle=FileAccess.open(file,FileAccess.READ)
  if handle==null: continue
  files+=1
  var current="?"
  for line in handle.get_as_text().split("\n"):
   var code=String(line).split("#")[0]
   var decl=declaration.search(code)
   if decl!=null: current=decl.get_string(1)
   # 逐次登记：同一行两处写算两条（集合断言因此对「同一函数内再加一处」敏感，含同一行）。
   var count=write.search_all(code).size()+mutator.search_all(code).size()
   for _occurrence in count: sites.append(file+"::"+current)
 sites.sort()
 return {"files":files,"sites":sites}

static func payload_write_sites_are_pinned(t) -> void:
 var scan=payload_write_sites()
 var want=PAYLOAD_WRITE_WHITELIST.duplicate()
 want.sort()
 print("PAYLOAD WRITE SCAN files=%d sites=%d %s" % [scan.files,scan.sites.size(),str(scan.sites)])
 t.check(scan.files>0,"ARCH payload_write_sites_are_pinned (core/ + data/): the source scan reached the script roots files="+str(scan.files))
 t.check(scan.sites==want,"ARCH payload_write_sites_are_pinned (core/ + data/): every payload write occurrence (receiver segment exactly `payload`: member/index assignment or mutating call) is the declared producer-side construction whitelist (a new write, a second write inside a whitelisted function or a removed write turns this red); have="+str(scan.sites)+" want="+str(want))

# Pre-cut card_facts slot walk: union B.SLOTS then skip undeclared occupied before target_payload.
static func card_facts_union_slot_oracle(g, card: Dictionary) -> Array:
 var facts=[]
 var spec=g.Cards.Rules.SPECS[card.type]
 var cards=g.Cards
 var assist_profiles=g.HandAssist.profiles(g)
 var seen_special=[]
 var face_costs={}
 var face_payments={}
 var slots=g.B.SLOTS+["neck","shoulder"]+g.SpecialEquipment.slots()
 for slot in spec.get("target_slots",[]):
  if slot not in slots: slots.append(slot)
 for slot in slots:
  var targets=g.targets_at(slot)
  if slot in ["neck","shoulder"] or slot in g.SpecialEquipment.slots():
   if targets.is_empty(): continue
  elif targets.is_empty(): targets=[{}]
  elif slot!="shoulder" and not g.occupied(slot): targets.append({})
  for target in targets:
   if target.is_empty() and spec.has("bound_modes"): continue
   if not target.is_empty() and spec.has("target_slots") and slot not in spec.target_slots: continue
   if not target.is_empty() and g.SpecialEquipment.is_special(target):
    if target.id in seen_special: continue
    seen_special.append(target.id)
   for second in ([false,true] if spec.has("bound_modes") else [false]):
    var p=cards.target_payload(g,card.type,slot,target,assist_profiles,card.uid,second)
    if p.free and spec.has("free_slots"): continue
    p.kind="card";p.uid=card.uid
    if not face_costs.has(p.free):
     face_costs[p.free]=cards.energy_cost(g,card.type,p.free)
     face_payments[p.free]=cards.face_mana(g,card.type,p.free)
    var cost=face_costs[p.free]
    var mana=face_payments[p.free]
    var risk=("三档免疫普通滑脱，仅造成%s点墙面真实伤害。" % g.number(p.preview.environment_true) if p.preview.get("environment_true",0)>0 else "三档免疫普通滑脱：本次伤害为0，仍消耗能量与卡牌。") if p.has("preview") and p.preview.immune else ""
    var label="自由 · "+g.B.SLOT_NAMES[slot] if cards.Rules.free_effect(card.type,p.free) else "解除 · "+g._equipment_name(target)
    if cards.Rules.free_effect(card.type,p.free) and slot in ["palm","fingers"] and not g.equipment_at(slot).is_empty(): label="自由 · "+("右" if g.hand_blocked(slot,"left") else "左")+g.B.SLOT_NAMES[slot]
    if spec.has("bound_modes"): label=cards.Rules.face_name(card.type,p.free)+" · "+g._equipment_name(target)
    facts.append_array(cards.target_facts(g,p,label,cost,mana,risk))
 return facts

# card_facts_declared_slots: declared-slot cards do not query undeclared occupancy via targets_at.
static func card_facts_declared_slots(t) -> void:
 var g=TargetsAtCountingGame.new(42)
 t.check(g.state.phase=="battle","card_facts_declared_slots: battle fixture")
 g.state.equipment.clear()
 g.state.links.clear()
 g.state.composites.clear()
 var undeclared=g.add_fixture("ankle",40,100)
 g.add_fixture("upper_arm",40,100)
 var card=Rewards.give(t,g,"strong_elbow")
 var spec=g.Cards.Rules.SPECS[card.type]
 t.check(spec.has("target_slots") and "ankle" not in spec.target_slots and "upper_arm" in spec.target_slots,"card_facts_declared_slots: strong_elbow declares arms not ankle")
 var before=card_facts_union_slot_oracle(g,card)
 g.targets_at_slots.clear()
 var facts=g.Cards.card_facts(g,card)
 t.check(not facts.any(func(f):return String(f.payload.get("target",""))==undeclared.id),"card_facts_declared_slots: no release row for undeclared occupied id")
 t.check(facts==before,"card_facts_declared_slots: facts equal the pre-cut union-then-skip rows field-for-field")
 var undeclared_queries=g.targets_at_slots.filter(func(slot):return slot not in spec.target_slots)
 t.check(undeclared_queries.is_empty(),"card_facts_declared_slots: targets_at on undeclared slots is 0 have="+str(undeclared_queries))

# card_facts_consumes_has_targets_at: declared slots ask has_targets_at before targets_at; empty slots skip collect.
static func _card_facts_consume_slots(g, spec: Dictionary) -> Array:
 var slots=g.B.SLOTS+["neck","shoulder"]+g.SpecialEquipment.slots()
 for slot in spec.get("target_slots",[]):
  if slot not in slots: slots.append(slot)
 return slots

static func _assert_card_facts_consumes_has_targets_at(t, g, card: Dictionary, label: String, expected_ids: Array=[]) -> void:
 var spec=g.Cards.Rules.SPECS[card.type]
 t.check(not spec.has("target_slots"),"card_facts_consumes_has_targets_at: no target_slots "+label+" "+card.type)
 var snap=g.export_snapshot()
 var rng=g.state.rng.duplicate(true)
 var oracle=card_facts_union_slot_oracle(g,card)
 t.check(g.export_snapshot()==snap and g.state.rng==rng,"card_facts_consumes_has_targets_at: oracle frozen "+label+" "+card.type)
 g.targets_at_slots.clear()
 var facts=g.Cards.card_facts(g,card)
 t.check(facts==oracle,"card_facts_consumes_has_targets_at: facts equal oracle "+label+" "+card.type)
 var queried=g.targets_at_slots.duplicate()
 for slot in _card_facts_consume_slots(g,spec):
  if g.has_targets_at(slot):
   t.check(queried.has(slot),"card_facts_consumes_has_targets_at: occupied slot still queries targets_at "+label+" "+card.type+" "+slot)
  else:
   t.check(not queried.has(slot),"card_facts_consumes_has_targets_at: empty slot does not query targets_at "+label+" "+card.type+" "+slot+" have="+str(queried))
 for id in expected_ids:
  t.check(facts.any(func(f):return String(f.payload.get("target",""))==id),"card_facts_consumes_has_targets_at: facts contain id "+label+" "+card.type+" "+str(id))
 t.check(g.export_snapshot()==snap and g.state.rng==rng,"card_facts_consumes_has_targets_at: snapshot and rng frozen "+label+" "+card.type)

static func _check_card_facts_consumes_cards(t, g, label: String, expected_ids: Array=[]) -> void:
 t.check(g.state.phase=="battle" or g.state.practice,"card_facts_consumes_has_targets_at: battle or practice fixture "+label)
 var strain=Rewards.give(t,g,"strain")
 var slip=Rewards.give(t,g,"slip")
 _assert_card_facts_consumes_has_targets_at(t,g,strain,label,expected_ids)
 _assert_card_facts_consumes_has_targets_at(t,g,slip,label,expected_ids)

static func card_facts_consumes_has_targets_at(t) -> void:
 var empty=TargetsAtCountingGame.new(42)
 t.check(empty.state.phase=="battle","card_facts_consumes_has_targets_at: battle fixture")
 _clear_gear(empty)
 _check_card_facts_consumes_cards(t,empty,"empty")
 var empty_strain=empty.state.hand.filter(func(c):return c.type=="strain")[0]
 var empty_facts=empty.Cards.card_facts(empty,empty_strain)
 t.check(empty_facts.any(func(f):return String(f.payload.get("target",""))==""),"card_facts_consumes_has_targets_at: empty ordinary slot free face")
 var palm=TargetsAtCountingGame.new(42)
 _clear_gear(palm)
 var palm_piece=palm.add_fixture("palm",4,10)
 palm_piece.side="left"
 t.check(not palm.occupied("palm"),"card_facts_consumes_has_targets_at: one-sided palm occupied stays false")
 _check_card_facts_consumes_cards(t,palm,"one-sided palm",[palm_piece.id])
 t.check(not palm.occupied("palm"),"card_facts_consumes_has_targets_at: one-sided palm occupied after facts")
 var fingers=TargetsAtCountingGame.new(42)
 _clear_gear(fingers)
 var fingers_piece=fingers.add_fixture("fingers",4,10)
 fingers_piece.side="left"
 t.check(not fingers.occupied("fingers"),"card_facts_consumes_has_targets_at: one-sided fingers occupied stays false")
 _check_card_facts_consumes_cards(t,fingers,"one-sided fingers",[fingers_piece.id])
 t.check(not fingers.occupied("fingers"),"card_facts_consumes_has_targets_at: one-sided fingers occupied after facts")
 var link_only=TargetsAtCountingGame.new(42)
 _clear_gear(link_only)
 var only_root=link_only._install_assembly("leg","upper","fixture",2,2)
 var only_body=only_root.components.filter(func(e):return e.part=="body")[0]
 var only_band=link_only._install_template("rope",link_only.Links.point_slot("below_knee"),8,10,false,"fixture",1,-1,0,"below_knee")
 var only_rope=link_only._install_link(only_body.id,only_band.id,8,"fixture",1,[],["thigh","calf"],["above_knee","below_knee"])
 t.check(not only_rope.is_empty(),"card_facts_consumes_has_targets_at: live link fixture")
 for slot in ["thigh","calf"]:
  for e in link_only.equipment_at(slot): e.durability=0
 var link_slot=_link_slot_without_equipment(link_only)
 t.check(link_slot!="","card_facts_consumes_has_targets_at: live link covers empty equipment_at")
 _check_card_facts_consumes_cards(t,link_only,"live link",[only_rope.id])
 only_rope.durability=0
 t.check(link_slot=="" or not link_only.has_targets_at(link_slot),"card_facts_consumes_has_targets_at: dead link empty equipment_at is false")
 _check_card_facts_consumes_cards(t,link_only,"dead link")
 var glove_g=TargetsAtCountingGame.new(42)
 _clear_gear(glove_g)
 var glove=glove_g._install_assembly("glove","short","fixture",2,2)
 t.check(not glove.is_empty() and glove_g.Composites.active(glove),"card_facts_consumes_has_targets_at: active composite fixture")
 var glove_ids=ids_for(glove.components)
 _check_card_facts_consumes_cards(t,glove_g,"active composite",glove_ids)
 var glove_body=glove.components.filter(func(e):return e.part=="body")[0]
 glove_body.durability=0
 t.check(not glove_g.Composites.active(glove),"card_facts_consumes_has_targets_at: disabled composite inactive")
 _check_card_facts_consumes_cards(t,glove_g,"disabled composite")
 var jacket_g=TargetsAtCountingGame.new(42)
 _clear_gear(jacket_g)
 var jacket=jacket_g._install_assembly("jacket","standard","fixture",2,2)
 t.check(not jacket.is_empty() and jacket_g.Composites.active(jacket),"card_facts_consumes_has_targets_at: jacket composite fixture")
 var outside=_composite_contact_outside_equipment(jacket_g,jacket)
 t.check(not outside.is_empty(),"card_facts_consumes_has_targets_at: composite contact outside equipment_at")
 var contact_ids=[]
 for contact in outside:
  if contact.id not in contact_ids: contact_ids.append(contact.id)
 _check_card_facts_consumes_cards(t,jacket_g,"active jacket",contact_ids)
 var jacket_body=jacket.components.filter(func(e):return e.part=="body")[0]
 jacket_body.durability=0
 t.check(not jacket_g.Composites.active(jacket),"card_facts_consumes_has_targets_at: disabled jacket inactive")
 _check_card_facts_consumes_cards(t,jacket_g,"disabled jacket")
 var bind_g=null
 for seed in range(1,100):
  var candidate=TargetsAtCountingGame.new(seed,true,"torso_binding")
  if candidate.state.equipment[0].binding.kind=="linked":
   bind_g=candidate
   break
 t.check(bind_g!=null,"card_facts_consumes_has_targets_at: linked torso binding fixture")
 if bind_g!=null:
  var conns=bind_g.Binding.connections(bind_g)
  t.check(not conns.is_empty(),"card_facts_consumes_has_targets_at: Binding.connections contribute")
  var conn_ids=[]
  for conn in conns:
   if conn.id not in conn_ids: conn_ids.append(conn.id)
  _check_card_facts_consumes_cards(t,bind_g,"connection",conn_ids)

# Pre-cut card_facts own-face rows for self_faces / single_face (no slot walk).
static func card_facts_own_face_oracle(g, card: Dictionary) -> Array:
 var facts=[]
 var spec=g.Cards.Rules.SPECS[card.type]
 var cards=g.Cards
 if spec.has("self_faces"):
  for side in ["bound","free"]:
   var p={"kind":"card","uid":card.uid,"type":card.type,"slot":"","target":"self","free":side=="free","mode":spec.mode,"self_target":true}
   if spec.get("x_cost",false): p.x=cards.energy_cost(g,card.type,side=="free")
   var choices=[p]
   if spec.self_faces[side].get("exhaust_hand",false):
    choices=[]
    for chosen in g.state.hand:
     if chosen.uid==card.uid: continue
     var selection=p.duplicate();selection.hand_uid=chosen.uid;choices.append(selection)
    if choices.is_empty():
     p.hand_uid="";choices.append(p)
   for choice in choices:
    var face_label=cards.Rules.face_name(card.type,choice.free)+"面" if spec.has("bound_modes") else ("自由面" if choice.free else "挣脱面")
    facts.append(g._fact(choice,"打出「"+g.B.CARD_NAMES[card.type]+"」 · "+face_label,{"kind":"card.target","args":{"payload":choice}},cards.energy_cost(g,card.type,choice.free),cards.face_mana(g,card.type,choice.free),cards.reason(g,choice),"","card"))
  return facts
 if cards.Rules.single_face(card.type):
  var p={"kind":"card","uid":card.uid,"type":card.type,"slot":"","target":"self","free":false,"mode":spec.mode,"self_target":true}
  facts.append(g._fact(p,"打出「"+g.B.CARD_NAMES[card.type]+"」",{"kind":"card.target","args":{"payload":p}},cards.energy_cost(g,card.type),0.0,cards.reason(g,p),"","card"))
 return facts

# card_facts_keyword_min_query: slot collect is gated by keyword_ids ∩ equipment-collect keys, not term.name.
static func card_facts_keyword_min_query(t) -> void:
 var collect_keys=["strain","slip","magic_slip","lower","unlock","follow_through"]
 var empty=TargetsAtCountingGame.new(42)
 t.check(empty.state.phase=="battle","card_facts_keyword_min_query: battle fixture")
 _clear_gear(empty)
 var strain=Rewards.give(t,empty,"strain")
 t.check(not empty.Cards.Rules.SPECS[strain.type].has("target_slots"),"card_facts_keyword_min_query: strain has no target_slots")
 t.check("strain" in empty.B.keyword_ids(strain.type,false),"card_facts_keyword_min_query: strain bound ids contain strain")
 var empty_snap=empty.export_snapshot()
 var empty_rng=empty.state.rng.duplicate(true)
 var empty_oracle=card_facts_union_slot_oracle(empty,strain)
 t.check(empty.export_snapshot()==empty_snap and empty.state.rng==empty_rng,"card_facts_keyword_min_query: empty strain oracle frozen")
 empty.targets_at_slots.clear()
 var empty_facts=empty.Cards.card_facts(empty,strain)
 t.check(empty.targets_at_slots.is_empty(),"card_facts_keyword_min_query: empty strain does not query targets_at")
 t.check(empty_facts.any(func(f):return String(f.payload.get("target",""))==""),"card_facts_keyword_min_query: empty ordinary slot free face")
 t.check(empty_facts==empty_oracle,"card_facts_keyword_min_query: empty strain facts equal oracle")
 t.check(empty.export_snapshot()==empty_snap and empty.state.rng==empty_rng,"card_facts_keyword_min_query: empty strain snapshot rng")
 var palm=TargetsAtCountingGame.new(42)
 _clear_gear(palm)
 var palm_piece=palm.add_fixture("palm",4,10)
 palm_piece.side="left"
 t.check(not palm.occupied("palm"),"card_facts_keyword_min_query: one-sided palm occupied stays false")
 var palm_strain=Rewards.give(t,palm,"strain")
 var palm_snap=palm.export_snapshot()
 var palm_rng=palm.state.rng.duplicate(true)
 var palm_oracle=card_facts_union_slot_oracle(palm,palm_strain)
 t.check(palm.export_snapshot()==palm_snap and palm.state.rng==palm_rng,"card_facts_keyword_min_query: palm oracle frozen")
 palm.targets_at_slots.clear()
 var palm_facts=palm.Cards.card_facts(palm,palm_strain)
 var palm_slots=palm.targets_at_slots.duplicate()
 t.check(palm_slots.has("palm"),"card_facts_keyword_min_query: one-sided palm still queries targets_at")
 t.check(palm_facts.any(func(f):return String(f.payload.get("target",""))==palm_piece.id),"card_facts_keyword_min_query: facts contain palm piece")
 t.check(palm_facts==palm_oracle,"card_facts_keyword_min_query: palm strain facts equal oracle")
 t.check(palm.export_snapshot()==palm_snap and palm.state.rng==palm_rng,"card_facts_keyword_min_query: palm snapshot rng")
 var elbow=TargetsAtCountingGame.new(42)
 t.check(elbow.state.phase=="battle","card_facts_keyword_min_query: elbow battle fixture")
 _clear_gear(elbow)
 var undeclared=elbow.add_fixture("ankle",40,100)
 elbow.add_fixture("upper_arm",40,100)
 var elbow_card=Rewards.give(t,elbow,"strong_elbow")
 var elbow_spec=elbow.Cards.Rules.SPECS[elbow_card.type]
 t.check(elbow_spec.has("target_slots") and "ankle" not in elbow_spec.target_slots and "upper_arm" in elbow_spec.target_slots,"card_facts_keyword_min_query: strong_elbow declares arms not ankle")
 var elbow_snap=elbow.export_snapshot()
 var elbow_rng=elbow.state.rng.duplicate(true)
 var elbow_oracle=card_facts_union_slot_oracle(elbow,elbow_card)
 t.check(elbow.export_snapshot()==elbow_snap and elbow.state.rng==elbow_rng,"card_facts_keyword_min_query: elbow oracle frozen")
 elbow.targets_at_slots.clear()
 var elbow_facts=elbow.Cards.card_facts(elbow,elbow_card)
 var elbow_slots=elbow.targets_at_slots.duplicate()
 t.check(elbow_slots.all(func(slot):return slot in elbow_spec.target_slots),"card_facts_keyword_min_query: strong_elbow targets_at stays in target_slots have="+str(elbow_slots))
 t.check(not elbow_facts.any(func(f):return String(f.payload.get("target",""))==undeclared.id),"card_facts_keyword_min_query: no release row for undeclared occupied id")
 t.check(elbow_facts==elbow_oracle,"card_facts_keyword_min_query: strong_elbow facts equal oracle")
 t.check(elbow.export_snapshot()==elbow_snap and elbow.state.rng==elbow_rng,"card_facts_keyword_min_query: elbow snapshot rng")
 var occupied=TargetsAtCountingGame.new(42)
 t.check(occupied.state.phase=="battle","card_facts_keyword_min_query: occupied battle fixture")
 _clear_gear(occupied)
 for slot in occupied.B.SLOTS: occupied.add_fixture(slot,7,10)
 var pot=Rewards.give(t,occupied,"pot_of_greed")
 var search=Rewards.give(t,occupied,"mana_search")
 for type in ["pot_of_greed","mana_search"]:
  t.check(not occupied.Cards.Rules.SPECS[type].has("target_slots"),"card_facts_keyword_min_query: no target_slots "+type)
  var ids=occupied.B.keyword_ids(type,false)+occupied.B.keyword_ids(type,true)
  t.check(ids.all(func(id):return id not in collect_keys),"card_facts_keyword_min_query: ids omit equipment-collect keys "+type+" have="+str(ids))
 var occupied_snap=occupied.export_snapshot()
 var occupied_rng=occupied.state.rng.duplicate(true)
 var pot_oracle=card_facts_own_face_oracle(occupied,pot)
 var search_oracle=card_facts_own_face_oracle(occupied,search)
 t.check(occupied.export_snapshot()==occupied_snap and occupied.state.rng==occupied_rng,"card_facts_keyword_min_query: occupied oracle frozen")
 occupied.targets_at_slots.clear()
 var pot_facts=occupied.Cards.card_facts(occupied,pot)
 t.check(occupied.targets_at_slots.is_empty(),"card_facts_keyword_min_query: pot_of_greed does not query targets_at on occupied")
 t.check(pot_facts==pot_oracle,"card_facts_keyword_min_query: pot_of_greed facts equal own-face oracle")
 t.check(pot_facts.all(func(f):return String(f.payload.get("target",""))=="self"),"card_facts_keyword_min_query: pot_of_greed has no slot release or free-slot rows")
 occupied.targets_at_slots.clear()
 var search_facts=occupied.Cards.card_facts(occupied,search)
 t.check(occupied.targets_at_slots.is_empty(),"card_facts_keyword_min_query: mana_search does not query targets_at on occupied")
 t.check(search_facts==search_oracle,"card_facts_keyword_min_query: mana_search facts equal own-face oracle")
 t.check(search_facts.all(func(f):return String(f.payload.get("target",""))=="self"),"card_facts_keyword_min_query: mana_search has no slot release or free-slot rows")
 t.check(occupied.export_snapshot()==occupied_snap and occupied.state.rng==occupied_rng,"card_facts_keyword_min_query: occupied snapshot rng")
 var terms=preload("res://data/card_text.gd").TERMS
 var original_name=terms.strain.name
 terms.strain.name="__mutated_strain__"
 empty.targets_at_slots.clear()
 empty.Cards.card_facts(empty,strain)
 var mutated_empty=empty.targets_at_slots.duplicate()
 palm.targets_at_slots.clear()
 palm.Cards.card_facts(palm,palm_strain)
 var mutated_palm=palm.targets_at_slots.duplicate()
 elbow.targets_at_slots.clear()
 elbow.Cards.card_facts(elbow,elbow_card)
 var mutated_elbow=elbow.targets_at_slots.duplicate()
 occupied.targets_at_slots.clear()
 occupied.Cards.card_facts(occupied,pot)
 occupied.Cards.card_facts(occupied,search)
 var mutated_occupied=occupied.targets_at_slots.duplicate()
 terms.strain.name=original_name
 t.check(mutated_empty.is_empty() and mutated_palm==palm_slots and mutated_elbow==elbow_slots and mutated_occupied.is_empty(),"card_facts_keyword_min_query: collect set unchanged after TERMS.strain.name mutate")
 t.check(empty.export_snapshot()==empty_snap and empty.state.rng==empty_rng and palm.export_snapshot()==palm_snap and palm.state.rng==palm_rng and elbow.export_snapshot()==elbow_snap and elbow.state.rng==elbow_rng and occupied.export_snapshot()==occupied_snap and occupied.state.rng==occupied_rng,"card_facts_keyword_min_query: snapshot rng after TERMS mutate")

static func copy_candidate(g, kind: String, op: String) -> Dictionary:
 for candidate in g.command_facts():
  if candidate.payload.get("kind","")!=kind: continue
  if op!="" and candidate.payload.get("action",candidate.payload.get("op",""))!=op: continue
  return candidate
 return {}

# docs/spec/*-dependencies.md（已落地三片：种子标识／反馈存档、本局回顾、卡面词条）。
# 依赖表散文退化为索引后，可机检的判据落在这里：跨层方向、唯一复制实现、唯一条存档序列化、
# 词条单一来源。改写这三片的散文前先读本节的断言消息，它们就是"必须保持"的真源。
static func source_text(relative: String) -> String:
 var handle=FileAccess.open("res://"+relative,FileAccess.READ)
 return "" if handle==null else handle.get_as_text()

# 指向 ui 模块的引用：`res://ui/…` 或 `…ui/<name>.gd`。资源路径（`assets/ui/…`）与文档路径不算跨层引用。
static func names_ui_module(text: String) -> bool:
 var regex=RegEx.new()
 if regex.compile("(res://ui/|(?<![A-Za-z0-9_/])ui/[A-Za-z0-9_]+\\.gd)")!=OK: return true
 return regex.search(text)!=null

# 写点扫描（函数归属跟踪同 verdict_write_scan）：roots 下的 .gd 文本里匹配 pattern 的行。
static func source_write_sites(roots: Array, pattern: String) -> Array:
 var regex=RegEx.new()
 if regex.compile(pattern)!=OK: return []
 var declaration=RegEx.new()
 declaration.compile("^\\s*(?:static\\s+)?func\\s+([A-Za-z_][A-Za-z0-9_]*)")
 var hits=[]
 for root in roots:
  for path in script_files(root):
   var lines=source_text(path.trim_prefix("res://")).split("\n")
   var current="<file>"
   for index in range(lines.size()):
    var code=String(lines[index]).split("#")[0]
    var declared=declaration.search(code)
    if declared!=null: current=declared.get_string(1)
    if regex.search(code)==null: continue
    hits.append({"file":path.trim_prefix("res://"),"function":current,"line":index+1,"text":code.strip_edges()})
 return hits

static func write_site_names(hits: Array) -> Array:
 var names=[]
 for hit in hits:
  var name=String(hit.file)+"::"+String(hit.function)
  if name not in names: names.append(name)
 names.sort()
 return names

static func declaration_text(hits: Array, token: String) -> Array:
 return hits.filter(func(hit):return not String(hit.text).contains(token))

static func slice_dependency_directions(t) -> void:
 var inherited=[]
 for root in ["res://core","res://data"]:
  for path in script_files(root):
   if names_ui_module(source_text(path.trim_prefix("res://"))): inherited.append(path.trim_prefix("res://"))
 t.check(inherited.is_empty(),"DEP slice_dependency_directions: core/data never reference the ui module: "+str(inherited))
 var core_preloaders=[]
 for path in script_files("res://ui"):
  if source_text(path.trim_prefix("res://")).contains("preload(\"res://core"): core_preloaders.append(path.trim_prefix("res://"))
 t.check(core_preloaders==["ui/main.gd"],"DEP slice_dependency_directions: ui/main.gd is the only ui file that preloads core: "+str(core_preloaders))
 # The feedback service runs outside the game: it never references game source paths.
 var service_references=[]
 for path in script_files("res://tools/feedback-service",[".gs",".cjs",".js"]):
  for token in ["res://core","res://ui","res://data"]:
   if source_text(path.trim_prefix("res://")).contains(token): service_references.append(path.trim_prefix("res://")+" references "+token)
 t.check(service_references.is_empty(),"DEP slice_dependency_directions: tools/feedback-service never references game source paths (res://core, res://ui, res://data): "+str(service_references))

static func run_identity_single_writer(t) -> void:
 var clipboard=write_site_names(source_write_sites(["res://core","res://data","res://ui"],"DisplayServer\\.clipboard_set\\s*\\("))
 t.check(clipboard==["ui/main.gd::copy_seed"],"DEP run_identity_single_writer: the only clipboard write is ui/main.gd::copy_seed: "+str(clipboard))
 var deadline=write_site_names(declaration_text(source_write_sites(["res://ui"],"seed_copied_until\\s*=[^=]"),"var seed_copied_until"))
 t.check(deadline==["ui/main.gd::_refresh_seed_chip","ui/main.gd::copy_seed"],"DEP run_identity_single_writer: the 1.2s window is owned by copy_seed/_refresh_seed_chip only: "+str(deadline))
 var views=write_site_names(source_write_sites(["res://ui"],"(seed_chip|run_review_copy)\\.text\\s*="))
 t.check(views==["ui/main.gd::_refresh_seed_chip"],"DEP run_identity_single_writer: both run-identity views are rewritten only by _refresh_seed_chip: "+str(views))

static func feedback_save_single_serializer(t) -> void:
 var serializers=write_site_names(source_write_sites(["res://ui"],"fixed_point_text\\s*\\("))
 t.check(serializers==["ui/feedback_report.gd::_capture_save"],"DEP feedback_save_single_serializer: the attachment is read only through SaveStore.fixed_point_text in ui/feedback_report.gd::_capture_save: "+str(serializers))
 var carriers=[]
 for path in script_files("res://ui"):
  if source_text(path.trim_prefix("res://")).contains("save_attachment"): carriers.append(path.trim_prefix("res://"))
 t.check(carriers==["ui/feedback_report.gd"],"DEP feedback_save_single_serializer: ui/feedback_report.gd is the only ui file that carries the attachment: "+str(carriers))

# docs/spec/feedback-deployment.md「存档附件」: the attachment cap is one constant declared in
# ui/feedback_report.gd (not core/save_store.gd); declaration and value are pinned as source text.
static func feedback_save_cap_pinned(t) -> void:
 var source=source_text("ui/feedback_report.gd")
 t.check(source.contains("const MAX_SAVE_BYTES=2*1024*1024"),"DEP feedback_save_cap_pinned: ui/feedback_report.gd declares the 2 MiB attachment cap as const MAX_SAVE_BYTES=2*1024*1024")

static func card_terms_single_source(t) -> void:
 var readers=[]
 var term_pattern=RegEx.new()
 term_pattern.compile("(?<![A-Za-z0-9_])TERMS(?![A-Za-z0-9_])")
 for root in ["res://core","res://ui"]:
  for path in script_files(root):
   if term_pattern.search(source_text(path.trim_prefix("res://")))!=null: readers.append(path.trim_prefix("res://"))
 t.check(readers.is_empty(),"DEP card_terms_single_source: the term table is never read from core/ui: "+str(readers))
 var definition=RegEx.new()
 definition.compile("(?m)^\\s*(?:static\\s+)?func\\s+keywords\\s*\\(")
 var defined=[]
 for root in ["res://core","res://data","res://ui"]:
  for path in script_files(root):
   if definition.search(source_text(path.trim_prefix("res://")))!=null: defined.append(path.trim_prefix("res://"))
 t.check(defined==["data/card_text.gd"],"DEP card_terms_single_source: exactly one keywords() implementation exists, in data/card_text.gd: "+str(defined))

# docs/spec/equipment-query-seam.md：作用域进出点是冻结名单。下面两个常量是「必须新开作用域的入口」与
# 「明确豁免」的唯一机读副本；散文表只保留索引。
const SCOPE_ENTRY_SITES=["core/contact.gd::workspace","core/enemy_plans.gd::targets","core/equipment_offers.gd::ordinary","core/equipment_offers.gd::for_pool","core/equipment_offers.gd::preferred","core/equipment_offers.gd::links","core/self_binding.gd::tighten_targets","core/self_binding.gd::capacity","core/room_events.gd::selector_values","core/room_events.gd::compile","core/card_effects.gd::occupied_body_count","core/game.gd::command_fact","core/game.gd::command_facts","core/game.gd::_prepare_assembly","core/game.gd::get_view"]
const SCOPE_EXEMPTIONS=["core/prison.gd::intake_equipment","core/slip_motion.gd::apply","core/room_events.gd::freeze_effects","core/shoulder_links.gd::cleanup","core/game.gd::validate","data/first_floor_enemy_pools.gd::eligible"]

static func scope_open_sites() -> Array:
 var hits=source_write_sites(["res://core","res://data"],"_begin_equipment_read\\s*\\(\\s*\\)")
 return write_site_names(hits.filter(func(hit):return not String(hit.text).begins_with("func ")))

static func equipment_scope_sites(t) -> void:
 var names=scope_open_sites()
 var missing=SCOPE_ENTRY_SITES.filter(func(site):return site not in names)
 var extra=names.filter(func(site):return site not in SCOPE_ENTRY_SITES)
 t.check(missing.is_empty() and extra.is_empty(),"EQ equipment_scope_sites: scope open points are the pinned entry list: missing="+str(missing)+" extra="+str(extra))
 var opened=[]
 var all_hits=source_write_sites(["res://core","res://data"],"_begin_equipment_read\\s*\\(\\s*\\)")
 for site in SCOPE_EXEMPTIONS:
  var parts=String(site).split("::")
  var hit=all_hits.filter(func(row):return String(row.file)==String(parts[0]) and String(row.function)==String(parts[1]) and not String(row.text).begins_with("func "))
  if not hit.is_empty(): opened.append(site)
 t.check(opened.is_empty(),"EQ equipment_scope_sites: exemptions never open a read scope: "+str(opened))

static func game_function_body(name: String) -> String:
 # Signature line excluded so a call cannot be confused with the function's own name.
 var source=source_text("core/game.gd")
 var start=source.find("func "+name+"(")
 if start<0: return ""
 var rest=source.substr(start)
 var signature_end=rest.find("\n")
 if signature_end<0: return ""
 var body=rest.substr(signature_end+1)
 var nxt=body.find("\nfunc ")
 return body if nxt<0 else body.substr(0,nxt)

static func equipment_targets_walk_is_one_path(t) -> void:
 var targets_body=game_function_body("targets_at")
 var forbidden=["physical_pieces(","equipment_at(","_composite_roots(","links_at(","connections(","special_equipment.filter"]
 var direct=[]
 for token in forbidden:
  if targets_body.contains(token): direct.append(token)
 t.check(not targets_body.is_empty() and direct.is_empty(),"EQ equipment_targets_walk_is_one_path: targets_at never reaches a source container directly: "+str(direct))
 var visit_body=game_function_body("_visit_targets_at")
 var backwards=[]
 for token in ["targets_at(","slot_targets"]:
  if visit_body.contains(token): backwards.append(token)
 t.check(not visit_body.is_empty() and backwards.is_empty(),"EQ equipment_targets_walk_is_one_path: _visit_targets_at never calls back into targets_at or reads slot_targets: "+str(backwards))

# docs/spec/transition-pipeline.md：TRANSITIONS 的 kind 全集与 checkpoint 列（缺省＝不是固定点）。
const TRANSITION_KINDS=["setup_init","tower_restart","practice_init","prison_cell_init","prison_gate_init","battle_start","battle_end_victory","battle_end_saturated","battle_end_captured","prepare_start","prepare_end","rest_start","room_enter","floor_enter","travel_start","prison_cell_enter","inspection_start","prison_exit_battle_start","prison_escape","event_enter","event_leave_empty","event_item_rewards","shop_enter","departure_start","departure_end","demo_end"]
const TRANSITION_CHECKPOINTS={"battle_end_victory":"battle_end","battle_end_saturated":"battle_end","battle_end_captured":"battle_end","prepare_end":"prepare_end","floor_enter":"floor"}

static func transition_kind_set_pinned(t) -> void:
 var table=GameCore.TRANSITIONS
 var missing=TRANSITION_KINDS.filter(func(kind):return not table.has(kind))
 var extra=[]
 for kind in table:
  if kind not in TRANSITION_KINDS: extra.append(kind)
 t.check(missing.is_empty() and extra.is_empty() and table.size()==TRANSITION_KINDS.size(),"TRANS transition_kind_set_pinned: the declared kind set is closed: missing="+str(missing)+" extra="+str(extra))
 var bad=[]
 for kind in table:
  var entry=table[kind]
  if typeof(entry)!=TYPE_DICTIONARY or not entry.has("phases") or not entry.has("room") or not entry.has("tx") or not entry.has("owners"):
   bad.append(kind+":shape"); continue
  if not entry.phases is Array or not entry.owners is Array or entry.owners.is_empty(): bad.append(kind+":arrays")
  var point=String(entry.get("checkpoint",""))
  if point!="" and point not in ["floor","battle_end","prepare_end"]: bad.append(kind+":checkpoint="+point)
  if point!=String(TRANSITION_CHECKPOINTS.get(kind,"")): bad.append(kind+":checkpoint-mismatch")
 t.check(bad.is_empty(),"TRANS transition_kind_set_pinned: every kind declares shape, owners and the pinned checkpoint column: "+str(bad))

# docs/spec/candidate-removal.md「输入域」：kind 的 params 键面（COMMAND_KEYS）是闭集；散文表只保留索引。
const COMMAND_KEY_SETS={
 "card":["uid","type","slot","target","free","mode","self_target","x","hand_uid"],
 "chain":["action","type","target","slot","free","mode","selected_uid"],
 "attack":["type","form","enemy","all","target","x","part","charge_action"],
 "status_toggle":["status","enabled","uid"],
 "posture":["dest","wall"],
 "wall_move":["direction"],
 "manual":["target"],
 "hook":["target"],
 "end":[],
 "calm":[],
 "surrender":[],
 "item_use":["item","target"],
 "item_install":["item","mount","operator"],
 "item_retrieve":["item","mount","operator"],
 "item_discard":["item"],
 "finish_prepare":[],
 "finish_rest":[],
 "finish_pack":[],
 "retain":["uid"],
 "retain_skip":[],
 "rest_rare":[],
 "rest_card":["type"],
 "rest_flask":[],
 "rest_begin":[],
 "service":["op","index","target","uid","payment"],
 "event":["action","choice","type"],
 "prison":["action","site","direction","steps","uid","type","target","slot","mode","free"],
 "depart":["room"],
 "travel_step":[],
 "reward":["category","type","reward_id"],
 "reward_skip":["category"],
 "relic_bundle":["op","index","uid","type"],
 "departure":["op","option","uid","type"],
 "flask":["op"],
 "relic_toggle":["relic"],
 "relic_discharge":["relic"],
 "relic_control_done":[],
 "demo_end":[],
 "demo_continue":[],
}

static func command_params_keys_pinned(t) -> void:
 var declared=GameCore.COMMAND_KEYS
 var probe=Game.new(42)
 var bad=[]
 for kind in COMMAND_KEY_SETS:
  if not declared.has(kind): bad.append(kind+":missing"); continue
  var actual=declared[kind].keys().map(func(key):return String(key)); actual.sort()
  var expected=COMMAND_KEY_SETS[kind].duplicate(); expected.sort()
  if actual!=expected: bad.append(kind+":declared "+str(actual)+" != "+str(expected))
  var projected=probe.command_params(kind,{}).keys().map(func(key):return String(key)); projected.sort()
  if projected!=expected: bad.append(kind+":params "+str(projected))
 t.check(bad.is_empty() and declared.size()==COMMAND_KEY_SETS.size(),"CR command_params_keys_pinned: the command key face is closed per kind: "+str(bad))

# docs/spec/response-pipeline.md 接缝 A：get_view 的调用点白名单（_resume_snapshot／render／_submit／restart）。
static func get_view_call_sites_are_pinned(t) -> void:
 var hits=source_write_sites(["res://ui"],"(?<![A-Za-z0-9_])game\\.get_view\\s*\\(")
 var sites=write_site_names(hits)
 t.check(sites==["ui/main.gd::_resume_snapshot","ui/main.gd::_submit","ui/main.gd::render","ui/main.gd::restart"],"RP get_view_call_sites_are_pinned: only the four whitelisted UI functions call get_view: "+str(sites))

# docs/spec/event-pipeline.md 依赖规范 6：生产代码（core／data／ui）不得引用 res://tests/**。
static func production_source_never_preloads_tests(t) -> void:
 var hits=source_write_sites(["res://core","res://data","res://ui"],"res://tests/")
 t.check(hits.is_empty(),"DEP production_source_never_preloads_tests: production source never references res://tests/: "+str(write_site_names(hits)))

# docs/spec/ondemand-copy.md：UI 只经 Game 只读入口与两个 helper 取用文案；UI 不直连 core/copy_router。
static func ondemand_copy_consumer_boundary(t) -> void:
 var router=source_write_sites(["res://ui"],"copy_router")
 t.check(router.is_empty(),"CP ondemand_copy_consumer_boundary: ui/ never references core/copy_router: "+str(write_site_names(router)))
 # 卡面投影的直读点白名单（docs/spec/ondemand-copy.md「显示侧取用 helper」）：改两处之外的读取即红。
 # 手牌节键不再直读（2026-09-28 手牌卡增量刷新：每卡窄键只读该卡自身的透传字段与本地显示态）。
 var projection_sites=["ui/main.gd::_card","ui/main.gd::card_entry"]
 var texts=write_site_names(source_write_sites(["res://ui"],"(?<![A-Za-z0-9_])card_texts\\b"))
 var instances=write_site_names(source_write_sites(["res://ui"],"(?<![A-Za-z0-9_])card_instances\\b"))
 t.check(texts==projection_sites and instances==projection_sites,"CP ondemand_copy_consumer_boundary: card_texts and card_instances are read only by ui/main.gd::card_entry/_card: "+str(texts)+" "+str(instances))
 var candidates=write_site_names(source_write_sites(["res://ui"],"(?<![A-Za-z0-9_])candidate_detail\\s*\\("))
 t.check(candidates==["ui/main.gd::detail_of"],"CP ondemand_copy_consumer_boundary: candidate_detail is consumed only by ui/main.gd::detail_of: "+str(candidates))
 var sets=write_site_names(source_write_sites(["res://ui"],"(?<![A-Za-z0-9_])live_card_text_set\\s*\\("))
 t.check(sets==["ui/deck_browser.gd::setup","ui/shop_screen.gd::services"],"CP ondemand_copy_consumer_boundary: live_card_text_set is consumed only by the deck browser and shop removal: "+str(sets))
 var live=write_site_names(source_write_sites(["res://ui"],"(?<![A-Za-z0-9_])live_card_text\\s*\\("))
 t.check(live==["ui/main.gd::card_entry"],"CP ondemand_copy_consumer_boundary: live_card_text is consumed only by ui/main.gd::card_entry: "+str(live))

# docs/spec/run-review.md 只读保证：ui/run_review.gd 唯一写动作是复制按钮 → ui.copy_seed()。
static func run_review_is_read_only_source(t) -> void:
 var text=source_text("ui/run_review.gd")
 var code=""
 for line in text.split("\n"): code+=String(line).split("#")[0]+"\n"
 var forbidden=["ui.game.","DisplayServer.clipboard_set","_save_progress",".dispatch(","seed_copied_until="]
 var bad=[]
 for token in forbidden:
  if code.contains(token): bad.append(token)
 t.check(not text.is_empty() and code.contains("ui.copy_seed") and bad.is_empty(),"RR run_review_is_read_only_source: ui/run_review.gd copies through ui.copy_seed only: "+str(bad))

# docs/spec/release-interface.md 输入域：共享查询只吃 View／ActionIndex／载荷，不接收 Game、不写状态。
static func target_queries_stay_stateless(t) -> void:
 var text=source_text("ui/target_queries.gd")
 var code=""
 for line in text.split("\n"): code+=String(line).split("#")[0]+"\n"
 var forbidden=["game.","Game.","ui.game",".state","dispatch(","_submit("]
 var bad=[]
 for token in forbidden:
  if code.contains(token): bad.append(token)
 t.check(not text.is_empty() and bad.is_empty(),"RL target_queries_stay_stateless: ui/target_queries.gd consumes only View/ActionIndex/payload: "+str(bad))

# docs/spec/release-interface.md 失败语义：界面不读不写 game.state（core 是唯一状态与事务入口）。
static func ui_never_reads_game_state(t) -> void:
 var hits=source_write_sites(["res://ui"],"(?<![A-Za-z0-9_])game\\.state\\b")
 t.check(hits.is_empty(),"RL ui_never_reads_game_state: ui/ never reads or writes game.state: "+str(write_site_names(hits)))

# docs/spec/state-readers.md／state-readers-dependencies.md：state 字段读者面的静态真源
# tests/state_readers.json（只由 tools/build_state_readers.gd --write 覆盖）＋三条双向判据。
# tests/state_reader_scan.gd 是唯一扫描实现（本文件不另起第二套），判据只读派生与冻结物；
# 判据不写死基线数字：派生＝冻结才是判据，打印行的数字是当前派生值（改读面后随重生成移动）。
const StateReaderScan=preload("res://tests/state_reader_scan.gd")

static func state_read_sites_are_pinned(t) -> void:
 var derived=StateReaderScan.scan()
 var stats=derived.stats
 print("STATE READERS files=%d fields=%d cells=%d sites=%d whole_state=%d ui_reads=%d digest=%s" % [stats.files,stats.fields,stats.cells,stats.sites,stats.whole_state,stats.ui_reads,StateReaderScan.canonical(derived).sha256_text().substr(0,12)])
 var failure=StateReaderScan.frozen_error()
 t.check(failure=="","STATEREAD state_read_sites_are_pinned: tests/state_readers.json is readable and schema 1: "+failure)
 if failure!="": return
 var comparison=StateReaderScan.compare(derived,StateReaderScan.frozen())
 t.check(comparison.ok,"STATEREAD state_read_sites_are_pinned: the derivation equals the frozen table -- an extra read, a missing read and a changed (owner,field) count are all red; first difference at "+comparison.first_diff)
 var face=StateReaderScan.failure_face()
 print("STATE FAILURE FACE fields=%d cells=%d kinds=%d sites=%d" % [face.fields,face.cells,face.kinds,face.sites])
 for row in face.rows:
  if String(row[0])=="all": continue
  print("STATE FAILURE FACE kind=%s fields=%d cells=%d sites=%d" % [row[0],row[1].fields,row[1].cells,row[1].sites])

static func state_read_scan_reaches_every_source(t) -> void:
 var derived=StateReaderScan.scan()
 var unknown=derived.unknown
 var unread=derived.unread_fields
 var registry=StateReaderScan.field_registry()
 print("STATE READERS unknown=%d unread=%s registry=%d" % [unknown.size(),str(unread),registry.size()])
 t.check(unknown.is_empty(),"STATEREAD state_read_scan_reaches_every_source: every read field name is registered (an unknown name carries its 文件::函数:行): "+str(unknown.slice(0,5)))
 t.check(derived.ui_reads.is_empty(),"STATEREAD state_read_scan_reaches_every_source: ui/ never reads a registered state field directly: "+str(derived.ui_reads))
 var unreachable=[]
 for site in derived.owners.keys():
  var parts=String(site).split("::")
  if StateReaderScan.function_body(String(parts[0]),String(parts[1])).strip_edges()=="": unreachable.append(site)
 t.check(derived.generated_from.files>0 and unreachable.is_empty(),"STATEREAD state_read_scan_reaches_every_source: every owner resolves to a non-empty declared body over %d file(s): %s" % [derived.generated_from.files,str(unreachable.slice(0,5))])
 var covered={}
 for site in derived.owners.keys():
  for field in derived.owners[site].keys(): covered[field]=true
 for site in derived.aliases.keys():
  for field in derived.aliases[site].fields: covered[field]=true
 for site in derived.schema_strings.keys():
  for field in derived.schema_strings[site].fields: covered[field]=true
 for field in unread: covered[field]=true
 # Coordinator ruling A (2026-10-14, P5 hardening): the missing= half is structurally always empty --
 # unread_fields is derived as registry minus the three read faces, so covered already holds every
 # registered field and this half is not a bidirectional guard. The bidirectional protection lives in
 # state_read_sites_are_pinned (derived == frozen, an extra or missing read is red) and
 # state_read_registrations_are_pinned (whole_state / aliases / schema_strings, both directions); the
 # extra= half keeps its teeth through schema_strings, the only face here not filtered by the registry.
 var missing=registry.filter(func(field):return not covered.has(field))
 var extra=covered.keys().filter(func(field):return field not in registry)
 t.check(missing.is_empty() and extra.is_empty(),"STATEREAD state_read_scan_reaches_every_source: the registry, the three read faces and unread_fields cover each other (a field nobody reads must be declared unread; the missing= half is structurally always empty and is NOT a bidirectional guard -- that guard is state_read_sites_are_pinned + state_read_registrations_are_pinned): missing="+str(missing)+" extra="+str(extra))

static func state_read_registrations_are_pinned(t) -> void:
 var failure=StateReaderScan.frozen_error()
 t.check(failure=="","STATEREAD state_read_registrations_are_pinned: tests/state_readers.json is readable and schema 1: "+failure)
 if failure!="": return
 var derived=StateReaderScan.scan()
 var frozen=StateReaderScan.frozen()
 var alias_fields=0
 for key in derived.aliases.keys(): alias_fields+=int(derived.aliases[key].fields.size())
 var schema_fields=0
 for key in derived.schema_strings.keys(): schema_fields+=int(derived.schema_strings[key].fields.size())
 print("STATE READERS REGISTRATIONS whole_state=%d whole_records=%d aliases=%d alias_fields=%d schema_owners=%d schema_fields=%d" % [derived.generated_from.whole_state,derived.whole_state.size(),derived.aliases.size(),alias_fields,derived.schema_strings.size(),schema_fields])
 var whole_missing=[]
 var whole_extra=[]
 var mine={}
 var theirs={}
 for row in derived.whole_state: mine["%s|%s|%s|%d" % [row.file,row.function,row.kind,row.count]]=true
 for row in frozen.whole_state: theirs["%s|%s|%s|%d" % [row.file,row.function,row.kind,row.count]]=true
 for key in theirs.keys():
  if not mine.has(key): whole_missing.append(key)
 for key in mine.keys():
  if not theirs.has(key): whole_extra.append(key)
 t.check(whole_missing.is_empty() and whole_extra.is_empty(),"STATEREAD state_read_registrations_are_pinned: whole_state is a per (file,function,kind,count) declaration -- a new, removed or re-counted whole-dictionary read is red: missing="+str(whole_missing.slice(0,3))+" extra="+str(whole_extra.slice(0,3)))
 var empty=[]
 for key in derived.aliases.keys():
  if derived.aliases[key].fields.is_empty(): empty.append(key)
 t.check(StateReaderScan.canonical(derived.aliases)==StateReaderScan.canonical(frozen.aliases) and empty.is_empty(),"STATEREAD state_read_registrations_are_pinned: the declared alias receivers match the frozen per-function field sets and every alias resolves to a non-empty body: unresolved="+str(empty))
 t.check(StateReaderScan.canonical(derived.schema_strings)==StateReaderScan.canonical(frozen.schema_strings),"STATEREAD state_read_registrations_are_pinned: the Snapshot.fields(state|g.state, spec) spec union matches the frozen schema_strings table")

# 检查力度的证据面（根 AGENTS.md「检查力度与报告四态」）：tests/mutations.json 是「判据名 → 临时突变」的
# 唯一声明表，执行器 tools/check-mutation.ps1（改源代码→跑声明的套件→要求该判据变红→逐字节还原）。
# 本判据双向核对：① 表里不得有幽灵条目（声明的套件里没有这个判据）；② 本轮规范重写线新增的判据
# 必须逐条有证据（不得靠 known_gaps 逃逸）；③ 本文件的判据全集必须等于 表 ∪ known_gaps，两边都不许默默缺席。
# 判据全集＝本文件里函数体自带断言的顶层函数：断言调用自成一行（`t.check(` 起行），
# 于是取源／扫描类助手不计入，run 是入口、下划线助手随父判据。断言形态变化时本条随之失效。
const MUTATION_TABLE="tests/mutations.json"
const NORM_REWRITE_CHECKS=["slice_dependency_directions","run_identity_single_writer","feedback_save_single_serializer","card_terms_single_source","feedback_save_cap_pinned","equipment_scope_sites","equipment_targets_walk_is_one_path","transition_kind_set_pinned","command_params_keys_pinned","get_view_call_sites_are_pinned","production_source_never_preloads_tests","ondemand_copy_consumer_boundary","run_review_is_read_only_source","target_queries_stay_stateless","ui_never_reads_game_state"]

static func mutation_judgment_universe() -> Array:
 var names=[]
 var current=""
 var body=""
 var declaration=RegEx.new()
 var assertion=RegEx.new()
 if declaration.compile("^(?:static\\s+)?func\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")!=OK: return names
 if assertion.compile("(?m)^ +t\\.check\\(")!=OK: return names
 for line in source_text("tests/architecture_cases.gd").split("\n"):
  var found=declaration.search(line)
  if found!=null:
   if current!="" and current!="run" and not current.begins_with("_") and assertion.search(body)!=null: names.append(current)
   current=found.get_string(1)
   body=""
  elif current!="":
   body+=line+"\n"
 if current!="" and current!="run" and not current.begins_with("_") and assertion.search(body)!=null: names.append(current)
 names.sort()
 return names

# 套件名 → 它的 case 文件；SUITES 的唯一声明在 tests/test_game.gd（core 直接跑 test_game.gd）。
static func suite_script(test_game: String, suite: String) -> String:
 if suite=="core": return "tests/test_game.gd"
 var pattern=RegEx.new()
 if pattern.compile("\""+suite+"\":\"res://([^\"]+)\"")!=OK: return ""
 var found=pattern.search(test_game)
 return "" if found==null else found.get_string(1)

static func mutation_evidence_is_total(t) -> void:
 var parsed=JSON.parse_string(source_text(MUTATION_TABLE))
 t.check(parsed is Dictionary,"MT mutation_evidence_is_total: "+MUTATION_TABLE+" parses as a JSON object")
 if not parsed is Dictionary: return
 var entries=parsed.get("mutations",null)
 var gaps=parsed.get("known_gaps",null)
 # 缺口冻结清单在**独立文件**（A 批审查缺口 3：外部锚定，不得与被核对的 known_gaps 同文件——否则同批
 # 加一条并同步改冻结清单即可白名单化）；表里残留该键即红（两处声明同一事实＝第二份真源）。
 var frozen=frozen_baselines().get("known_gaps_frozen",null)
 t.check(entries is Dictionary and not (entries as Dictionary).is_empty(),"MT mutation_evidence_is_total: mutations is a non-empty declaration table")
 t.check(gaps is Array,"MT mutation_evidence_is_total: known_gaps is an explicit list (no silent absence)")
 t.check(not parsed.has("known_gaps_frozen"),"MT mutation_evidence_is_total: the frozen gap list lives in the external file "+FROZEN_BASELINES_JSON+", not in the declaration table it governs")
 t.check(frozen is Array and not (frozen as Array).is_empty(),"MT mutation_evidence_is_total: known_gaps_frozen is the A-batch snapshot (the gap list only shrinks from here), anchored in "+FROZEN_BASELINES_JSON)
 if not entries is Dictionary or not gaps is Array or not frozen is Array: return
 var grown=gaps.map(func(key):return String(key)).filter(func(name):return name not in frozen)
 t.check(grown.is_empty(),"MT mutation_evidence_is_total: the frozen gap list only shrinks (new entries are red): "+str(grown))
 print("MUTATION GAP FREEZE frozen=%d current=%d shrunk=%d" % [frozen.size(),gaps.size(),frozen.filter(func(name):return name not in gaps).size()])
 var universe=mutation_judgment_universe()
 t.check(not universe.is_empty(),"MT mutation_evidence_is_total: the judgment universe is non-empty")
 var test_game=source_text("tests/test_game.gd")
 var ghosts=[]
 for name in entries:
  var row=entries[name]
  if not row is Dictionary: ghosts.append(String(name)+":shape"); continue
  var suite=String((row as Dictionary).get("suite",""))
  var execution=String((row as Dictionary).get("execution","rules"))
  var script=""
  if execution=="rules": script=suite_script(test_game,suite)
  elif execution=="ui": script=suite_script(source_text("tests/ui_smoke.gd"),suite)
  elif execution=="recipe" and suite=="recipe":
   script=suite_script(source_text("tests/ui_smoke.gd"),"display")
   var recipe=source_func_body_code("res://tests/recipe_driver.gd","_run_recipe")
   if not recipe.contains("load(UI_MODULES[\"display\"])") or not recipe.contains("present_demand_recorder_begin") or not recipe.contains("present_demand_recorder_end"): script=""
  if script=="" or not source_text(script).contains("func "+String(name)+"("): ghosts.append(String(name)+"@"+execution+":"+suite)
 t.check(ghosts.is_empty(),"MT mutation_evidence_is_total: every table entry names a real check of its declared suite: "+str(ghosts))
 var uncovered=NORM_REWRITE_CHECKS.filter(func(name):return not (entries as Dictionary).has(name))
 t.check(uncovered.is_empty(),"MT mutation_evidence_is_total: the checks added by this rewrite line all carry mutation evidence: "+str(uncovered))
 var covered=entries.keys().map(func(key):return String(key))
 var declared_gaps=gaps.map(func(key):return String(key))
 var silent=universe.filter(func(name):return name not in covered and name not in declared_gaps)
 var both=covered.filter(func(name):return name in declared_gaps)
 var unknown=declared_gaps.filter(func(name):return name not in universe)
 t.check(silent.is_empty() and both.is_empty() and unknown.is_empty(),"MT mutation_evidence_is_total: each judgment is either evidenced or named in known_gaps: silent="+str(silent)+" both="+str(both)+" unknown="+str(unknown))

# T 批（R-T5）锚自检：对 tests/frozen-baselines.json 的每处锚重算 `git show <锚提交>:<文件>` 的 sha256，
# 与所载 anchor.sha256 逐字节比对（大小写不敏感）。期望侧只在两处外部——JSON 声明与 git 对象库的历史
# blobs. This check proves only declared historical blob identity; PRE value conservation is proved separately
# by baseline_constants_are_unchanged / baseline_diff_is_declared. git 不可用（execute 退出 -1）／锚对象缺失（git 非零退出）／哈希不符
# 都按红处理（fail-closed），不静默绿。
# 字节通道：git show 经 cmd 重定向把 blob 字节直写 build/ 下的临时文件（OS.execute 捕获 stdout 时按
# 系统代码页解码，非字节保真，不能直接哈希字符串），再以 HashingContext SHA-256 分块重算；build/ 是
# 忽略目录，临时文件即用即删，不产生 git 残留。
const ANCHOR_SHOW_TMP="res://build/anchor-show.tmp"

static func _sha256_file(path: String) -> String:
 var handle=FileAccess.open(path,FileAccess.READ)
 if handle==null: return "<file-open-failed>"
 var context=HashingContext.new()
 context.start(HashingContext.HASH_SHA256)
 while handle.get_position()<handle.get_length():
  context.update(handle.get_buffer(65536))
 return context.finish().hex_encode()

static func _anchor_show_sha256(repo_root: String, spec: String) -> String:
 var tmp=ProjectSettings.globalize_path(ANCHOR_SHOW_TMP)
 var output=[]
 var exit_code=OS.execute("cmd",["/c","git","-C",repo_root,"show",spec,">",tmp],output,false)
 if exit_code!=0:
  DirAccess.remove_absolute(tmp)
  return "<git-show-exit-"+str(exit_code)+">"
 var digest=_sha256_file(tmp)
 DirAccess.remove_absolute(tmp)
 return digest

static func frozen_anchor_files_match_git(t) -> void:
 var anchors=frozen_baselines().get("anchor",{})
 t.check(anchors is Dictionary and not (anchors as Dictionary).is_empty(),"FB frozen_anchor_files_match_git: "+FROZEN_BASELINES_JSON+" declares an anchor object")
 if not anchors is Dictionary or (anchors as Dictionary).is_empty(): return
 var repo_root=ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()
 var mismatches=[]
 for key in anchors:
  var entry=anchors[key]
  if not entry is Dictionary:
   mismatches.append(String(key)+": not an anchor object")
   continue
  var commit=String((entry as Dictionary).get("commit",""))
  var file=String((entry as Dictionary).get("file",""))
  var declared=String((entry as Dictionary).get("sha256","")).to_upper()
  if commit=="" or file=="" or declared=="":
   mismatches.append(String(key)+": missing commit/file/sha256 fields")
   continue
  var recomputed=_anchor_show_sha256(repo_root,commit+":"+file).to_upper()
  if recomputed!=declared:
   mismatches.append(String(key)+" ("+commit+":"+file+"): recomputed="+recomputed+" declared="+declared)
 t.check(mismatches.is_empty(),"FB frozen_anchor_files_match_git: every anchor blob hash equals its declared sha256 (git unavailable, object missing and hash mismatch all fail closed): "+str(mismatches))
 print("FROZEN ANCHORS: %d anchor(s) recomputed from git blobs, %d matched" % [anchors.size(),anchors.size()-mismatches.size()])

