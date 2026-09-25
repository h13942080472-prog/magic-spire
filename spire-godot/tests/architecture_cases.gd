extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const GameCore=preload("res://core/game.gd")
const Rewards=preload("res://tests/reward_cases.gd")
const Guard=preload("res://core/guard.gd")

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

# Every .gd file below a res:// directory, sorted; the single enumerator for source scans.
static func script_files(root: String) -> Array:
 var result=[]
 var pending=[root]
 while not pending.is_empty():
  var directory=String(pending.pop_back())
  var handle=DirAccess.open(directory)
  if handle==null: continue
  for name in handle.get_files():
   if String(name).ends_with(".gd"): result.append(directory+"/"+name)
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

# Test-side counter: production card_facts must not call Game.targets_at for undeclared slots.
class TargetsAtCountingGame extends "res://tests/game_fixture.gd":
 var targets_at_slots=[]
 func targets_at(slot: String) -> Array:
  targets_at_slots.append(slot)
  return super.targets_at(slot)

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

static func run(t) -> void:
 event_dependency_edges_pinned(t)
 content_pack_root_has_no_build_feature_branch(t)
 transition_write_sites_are_pinned(t)
 save_checkpoint_kinds_are_pinned(t)
 event_condition_kinds_share_one_declaration(t)
 event_probe_and_projection_readonly(t)
 event_single_evaluation_entry(t)
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
 command_fact_kind_lookup(t)
 card_facts_declared_slots(t)
 card_facts_consumes_has_targets_at(t)
 card_facts_keyword_min_query(t)
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
 var previous=g._begin_equipment_read()
 t.check(g.piece_builds==1 and g.slot_builds==1 and g.id_builds==1 and g.capacity_builds==1 and g.physical_builds==1,"INDEX entry materializes the piece set and every edge once per scope")
 for slot in g.B.SLOTS: g.equipment_at(slot)
 for step in range(3): g.physical_pieces()
 var ids=g.physical_pieces().map(func(e):return e.id)
 for id in ids: g._equipment(id)
 for slot in g.B.SLOTS: g.capacity_used(slot)
 for point in g.Equipment.ANATOMY: g._point_count(point)
 t.check(g.piece_builds==1 and g.slot_builds==1 and g.id_builds==1 and g.capacity_builds==1 and g.physical_builds==1,"INDEX repeated slot, id and point queries inside one scope never rebuild an edge")
 var members=g.equipment_at("wrist");members.clear();members.append({})
 t.check(not g.equipment_at("wrist").is_empty(),"INDEX clearing a materialized slot answer cannot corrupt the edge")
 var built=g.piece_builds;var slot_builds=g.slot_builds;var id_builds=g.id_builds
 var capacity_builds=g.capacity_builds;var physical_builds=g.physical_builds
 g._equipment_read=previous
 t.check(g._equipment_read.is_empty(),"INDEX read scope releases its materialized edges")
 for step in range(3):
  g.equipment_at("wrist");g.physical_pieces()
 for id in ids: g._equipment(id)
 for slot in g.B.SLOTS: g.capacity_used(slot)
 for point in g.Equipment.ANATOMY: g._point_count(point)
 t.check(g.piece_builds==built and g.slot_builds==slot_builds and g.id_builds==id_builds and g.capacity_builds==capacity_builds and g.physical_builds==physical_builds,"INDEX queries without a scope never build an edge table")
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

# docs/spec/candidate-removal.md §5 G6（批 R1）：行为基线等价。切片开始时用未改源码复算 26 个夹具单元
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
const R3_VIEW_MASK=["display_facts"]
# 批 R5 的显式 mask（docs/spec/candidate-removal.md §5 G6／§2.2 终态断言）：本批删除的载体逐条声明，多一条少一条即红。
#  R5_VIEW_MASK＝视图键：候选行表（view.candidates）。
#  R5_RECORD_MASK＝记录路径：候选行的提交身份 id（rows_verdicts）与 view.candidates（view_candidates）。
#  R5_RECORD_ADDED＝随删除重算的记录路径：判定投影改显示键（facts_verdicts）、显示点全量文本基线（facts_text）、
#  显示事实条数（view_display_facts）。
#  R5_RECOMPUTED＝按 mask 删键后重算的冻结路径（view／record 摘要：候选行表不再参与）。
const R5_VIEW_MASK=["candidates"]
const R5_RECORD_MASK=["rows_verdicts","view_candidates"]
const R5_RECORD_ADDED=["facts_text","facts_verdicts","view_display_facts"]
const R5_RECOMPUTED=["record","view"]
# 接管单元（takeover:0／takeover:12）的 first_turn_control 摘要：接管步骤由行改为显示事实（同一形状与判定，
# 字段面不同），在 R5 提交字节上复算冻结。
const R5_FIRST_TURN={"takeover:0":"8bf0e226191edacd337b525691d9e36a","takeover:12":"ff12a17c57f7d8e7e7023ac7e7c15280"}
# 带 mask 复算后的冻结值（在 R5 提交字节上复算，不从实现反推）：覆盖 R5_RECORD_ADDED 与 R5_RECOMPUTED。
const R5_BASELINE={"battle:0":{"facts_text":"ac39ae864b6c5be2953f41bf47a1a5f0","facts_verdicts":"e16b774323b27feb0e1ec4a2de711bef","record":"74ca5a32d24987729e2d512df5691239","view":"98491d612f1a34d0a2c7624612655ab3","view_display_facts":"88"},"battle:12":{"facts_text":"4ff202e54cc276992613cfa15dd4483d","facts_verdicts":"fc4651ba295f7c196efa42ca3504093d","record":"00583d90980c5854b7fa5875ceefaa88","view":"d5dacaf06675cc544c1b14d13a7fdda9","view_display_facts":"100"},"battle:26":{"facts_text":"6563e2f5d257f4d404fbbb84b14d4b76","facts_verdicts":"861fd22798a16f77cf6351cde3011d60","record":"c839661145542b89679d97cd83977409","view":"ca211857952a5a4e6692be61c21531bc","view_display_facts":"184"},"battle:44":{"facts_text":"e1e9ae1c2ea1bf1cca274561d4c2e833","facts_verdicts":"8b73a596d24eadb28bcc9f4ed2b80c7c","record":"a4b5e1cafbabdaa15876d1b01c638203","view":"10f9aa4599f499e20755ed61bb282dfb","view_display_facts":"292"},"event:0":{"facts_text":"cfea8c6499b002900cc399479c98fbc7","facts_verdicts":"301c30de8e315e52e768df1a8bc52564","record":"b312f7c4b16b7a4d9279c75eb7a9b89d","view":"541595ca13f5e73ca9de0f2b64f3ce46","view_display_facts":"3"},"event:12":{"facts_text":"cfea8c6499b002900cc399479c98fbc7","facts_verdicts":"301c30de8e315e52e768df1a8bc52564","record":"0329089c388a38e75bd3bcd7ae833fb6","view":"3fc2ab7b618ab92a94d4b251eb9135da","view_display_facts":"3"},"event:26":{"facts_text":"cfea8c6499b002900cc399479c98fbc7","facts_verdicts":"301c30de8e315e52e768df1a8bc52564","record":"ab1c0533e933340269d6935bedf02753","view":"3f64d8883f83cae0aa864c885fc71ad0","view_display_facts":"3"},"event:44":{"facts_text":"cfea8c6499b002900cc399479c98fbc7","facts_verdicts":"301c30de8e315e52e768df1a8bc52564","record":"2a81a62cd240a9b40e77d67cc753d869","view":"6c2356440bcd43f4a82510528dc173a1","view_display_facts":"3"},"prepare:0":{"facts_text":"f7104838af279e342ab5aed44cb20a57","facts_verdicts":"0f60a5032db2d92fd89a88272f10dc1f","record":"8d065faf466d09e62383d3f7f6c4ad1e","view":"0a1924ba193cacb79a01ecbc05800bc1","view_display_facts":"72"},"prepare:12":{"facts_text":"8d4a1d3d5424b2652da0e42a5a7cab74","facts_verdicts":"330ac05bfcc503da1d5c2f5c58e28ef4","record":"6fbb207bb22449f7a878acaceda02e66","view":"19a684ffdeded96a26a50558885c8eca","view_display_facts":"84"},"prepare:26":{"facts_text":"31db9e6906e9e6edc2df544f6c58a495","facts_verdicts":"af704235553476a09ee81bd9a2b4faca","record":"8b19a23270dd6c90b2896de9a626d3ef","view":"a8208d05993dea9ac36e7fad8ecdeef7","view_display_facts":"168"},"prepare:44":{"facts_text":"6fd1ccecf8d6b337985d1e7065034e63","facts_verdicts":"5088345798f3561021d5322f9eb91a77","record":"00b045b694af3b8f592c3518bc545d61","view":"daf76ace88fec073a7743db2de0f3d7c","view_display_facts":"276"},"prison:0":{"facts_text":"063d3fb839831b1a5e2dfade29050cf7","facts_verdicts":"dd8c0a7b5470dbe8df9b7e872539ccd1","record":"4c09241017ee75638d7ac9c7a306d3ec","view":"61a5029d16c6913146698a3dd5bf48a5","view_display_facts":"79"},"prison:12":{"facts_text":"9d598659ba79454d46cf7796096b2727","facts_verdicts":"b321f1b18a82fb524db374cc81f0b877","record":"863dbd1664f847936bd812cf590f1459","view":"d3d8296745b0d9a375f7bd6caab592fb","view_display_facts":"88"},"prison:26":{"facts_text":"c25701787eae5067e2254bf2afa85448","facts_verdicts":"2bfa1bada5517a2857df809a2eb0d550","record":"8ba24604f6e68e66ba2f01378d7aafd7","view":"71034fb99f96a73b64544341b2fa8a3c","view_display_facts":"172"},"prison:44":{"facts_text":"ee32f17b1ee01a503c778db400fc26df","facts_verdicts":"f951eb35e09671769be056a22bac31a0","record":"8a0854a3b2c84f6a5c47bb9cd21dbbda","view":"dc82941a16fbd013239bbfe38b81d451","view_display_facts":"280"},"rest:0":{"facts_text":"e0e212f3475e1f9dcd244fe2564fdbd9","facts_verdicts":"ec4343c1370f8acfe92526873650aa36","record":"367ef088c4357eed6a8e80935bc5dc43","view":"a9d1770b00e77d7d37107effe368b4c3","view_display_facts":"78"},"rest:12":{"facts_text":"a952cbe4b46679882ae30ee8e00cbbfc","facts_verdicts":"5bb8fcea01ee73d4c5be74d960430e7d","record":"75c091aaa5e29380f34f7f6227872dec","view":"0f3e2db33facaf7d0cac349c8b68035f","view_display_facts":"126"},"rest:26":{"facts_text":"299c00b335e6a86c74c5017c32985a07","facts_verdicts":"3796be82638559efd08c14f35a4b24f7","record":"80e57e29a72b97a67aebcdbfd6f28487","view":"cab287418335d07b0d6b03abe199242a","view_display_facts":"252"},"rest:44":{"facts_text":"e1e4b83a24971f84477b9c1e0d59a6b1","facts_verdicts":"a7e66ae91adfbda41a18d60d9b71e9c3","record":"25a7263e555cb28bfc7adce0900e7756","view":"6a518514aef15bea1585bac114284bec","view_display_facts":"414"},"shop:0":{"facts_text":"608cfefe469084cd7a5322122eccff44","facts_verdicts":"b35ecaa120573ce7221efb885cdce1de","record":"94fdca283b6f6e6bd019968e561a1a02","view":"5933d35bb57aaf0743e7f1b8a7b5bdfa","view_display_facts":"49"},"shop:12":{"facts_text":"c7e231624b76db3e4caa04bc8df79e4d","facts_verdicts":"898b1cbf0d1f2c82f95564aae9b204d9","record":"93bebbce4d3f78ecae6c41b711ab5179","view":"cabc92f5d7f563aaef710bad1ee4f4ca","view_display_facts":"73"},"shop:26":{"facts_text":"4e4f209ed0c13bf3eb6d050e628f9e30","facts_verdicts":"9dd6c6caf8d3ee28bab06f2815f5777d","record":"ff5b8ecdf6668c342097b12afc1125b3","view":"dfda2802902de5f0c5a952a32c383ebb","view_display_facts":"101"},"shop:44":{"facts_text":"1cb65cb87d85ca843d8d94f7f318bacd","facts_verdicts":"45f3c9972f3720db6475312a9d28ad5b","record":"86bcd3cccabe3c9dac478a3152ecf992","view":"ab7e905c2af157a9d85cb1c6559b796a","view_display_facts":"137"},"takeover:0":{"facts_text":"c75421de9b2720481ea31d8002e23e26","facts_verdicts":"9fa43250337736f6c5d7b90df6fc0899","record":"4f58d058d9a1609a4ba5ffe1fb42f49c","view":"10892969a87b17ecf070b09c3bbecfd0","view_display_facts":"80"},"takeover:12":{"facts_text":"975d3c9922d0af94cc4848181df82ddb","facts_verdicts":"322274a2e387906c10f7a2deade40792","record":"1b8926cd71e59473346e2c2b5ad274e5","view":"c6ecc09c5dbc07cc14523e51b7795090","view_display_facts":"92"}}
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

static func r1_build(phase: String, count: int):
 var g=null
 match phase:
  "battle":
   g=Game.new(42)
  "takeover":
   g=GameCore.new(42,true,"doubao")
  "prepare":
   g=Game.new(42)
   var guard=0
   while g.state.phase=="battle" and guard<12:
    guard+=1
    r1_end_turn(g)
   for c in g.command_facts():
    if c.payload.kind=="reward" and c.payload.get("type","")=="skip" and c.valid:
     g.dispatch(g.command(c.payload,g.state.version),g.state.version)
     break
  "rest":
   g=GameCore.new(42,true,"equipment")
  "shop":
   g=GameCore.new(42,true,"shop")
  "event":
   g=GameCore.new(42,true,"abandoned_storeroom")
  "prison":
   g=GameCore.new(42,true,"prison_test")
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

# view 摘要按批 R3 的显式 mask 删键（docs/spec/candidate-removal.md §5 G6 的 mask 语义：显式声明、不得静默）。
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

# docs/spec/candidate-removal.md §5 G7（批 R5）：终态断言。扫描面＝core/、ui/、tests/ 的源码文本
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
  var declared_mask=R3_VIEW_MASK.duplicate()
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

# docs/spec/candidate-removal.md §5 G4（批 R1；R2 前置补正：写点扫描面加宽，销 R1 复核缺口①）。
# 扫描面＝core/ 与 ui/ 的源码文本（tests／data 不进面）；写点四种形态——字段赋值（.valid=／.reason=）、
# 字典键（"valid":／"reason":）、括号赋值（["valid"]=／["reason"]=）、括号字典键（["valid"]:／["reason"]:）；
# 读取式（x.valid／x.reason 作为值）不计。判定落点＝core/game.gd 的 eligibility／eligibility_takeover。
const VERDICT_PRODUCERS={"core/game.gd":["eligibility","eligibility_takeover"]}
# 非判定载体（逐函数声明）：这些模块的 reason 字段是各自域内的原因文本（装备施加结果、接触可达、事件闸门、
# 奖励行、工具操作者、施法路线、快照预览等），不是资格结论；表外任何 reason 写点即红（加宽后的 stray 面）。
# 双向核对：表外写点即红，表内每项仍须被扫到（防表腐烂）。
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

# docs/spec/candidate-removal.md §5 G1／G2（批 R2）：指令路由单入口＋分类表全量。
# kind 全集与逐域＝契约 §3.3.1（39 条）；本表是核对面，不是第二真源（真源是 ui/command_router.gd 的 ROUTES）。
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

# 契约 §5 G2 的逐域覆盖面（战斗／整备／休息／商店／事件／监狱／路线／奖励／出发／demo）。
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
 # 1) kind 全集＝契约 §3.3.1 的 39 条（多一条少一条即红）。
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

const T4_WIRED_KINDS=["flask","attack","item_discard","item_use","end","calm","finish_prepare","finish_rest","finish_pack","posture","wall_move","status_toggle","relic_toggle","relic_discharge","surrender"]
const T4_EQUIVALENCE_CELLS=[["battle",0],["battle",12],["battle",26],["battle",44],["prepare",0],["rest",0]]

static func t4_wired_row(g, fact: Dictionary) -> bool:
 var kind=String(fact.payload.get("kind",""))
 if kind not in T4_WIRED_KINDS: return false
 if kind=="attack" and String(fact.payload.get("target",""))!="": return false
 if kind=="item_use":
  var item=g._item(String(fact.payload.get("item","")))
  if item.is_empty(): return false
  return g.Tools.operation(item.type) in ["buff","escape"]
 return true

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
 {"id":"L-wired","from":"core/game.gd::command_fact","to":"core/game.gd::display_fact","type":"call","path":"nontakeover _command_fact_row -> _kind_facts -> match-arm producer -> display_fact"},
 {"id":"L-unwired","from":"core/game.gd::command_fact","to":"core/game.gd::_fact_source","type":"call","path":"_kind_facts _: arm: COMMAND_KEYS.has(kind) then _fact_source() else []"},
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

static func pipeline_lookup_inspect(t) -> void:
 var edges=pipeline_lookup_edges()
 t.check(edges.size()==3,"pipeline_lookup_inspect: PIPELINE_LOOKUP_EDGES is exactly three lookup edges have="+str(edges.size()))
 var by_id={}
 var signatures=[]
 for edge in edges:
  var id=String(edge.get("id",""))
  var from_fn=pipeline_lookup_func_name(edge.get("from",""))
  var signature=String(edge.get("from",""))+" -> "+String(edge.get("to",""))+" / "+String(edge.get("type",""))
  t.check(id!="" and not by_id.has(id) and signature not in signatures,"pipeline_lookup_inspect: L-wired, L-unwired, and L-table must be distinct id/from/to: "+id+" "+signature)
  t.check(String(edge.get("type",""))=="call" and from_fn in PIPELINE_LOOKUP_FUNCS,"pipeline_lookup_inspect: lookup edge is a call from an extracted func: "+id+" "+from_fn)
  by_id[id]=edge
  signatures.append(signature)
 t.check(by_id.has("L-wired") and by_id.has("L-unwired") and by_id.has("L-table"),"pipeline_lookup_inspect: table ids are L-wired / L-unwired / L-table")
 var bodies={}
 for name in PIPELINE_LOOKUP_FUNCS:
  bodies[name]=pipeline_lookup_func_body(name)
  t.check(not String(bodies[name]).strip_edges().is_empty(),"pipeline_lookup_inspect: extracted body is non-empty for "+name)
 var command_fact_body=bodies["command_fact"]
 var wired_to=pipeline_lookup_func_name(by_id["L-wired"].to)
 var unwired_to=pipeline_lookup_func_name(by_id["L-unwired"].to)
 var table_to=pipeline_lookup_func_name(by_id["L-table"].to)
 t.check(pipeline_lookup_call_count(command_fact_body,"command_facts")==0,"pipeline_lookup_inspect: command_fact body has no command_facts(")
 t.check(pipeline_lookup_call_count(command_fact_body,"_command_fact_row")==1 and pipeline_lookup_call_count(command_fact_body,wired_to)==0 and pipeline_lookup_call_count(command_fact_body,unwired_to)==0,"pipeline_lookup_inspect: L-wired unique path starts at exactly one _command_fact_row(")
 var nontakeover=pipeline_lookup_nontakeover_row(bodies["_command_fact_row"])
 t.check(not nontakeover.strip_edges().is_empty() and pipeline_lookup_call_count(nontakeover,"_kind_facts")==1 and pipeline_lookup_call_count(nontakeover,wired_to)==1,"pipeline_lookup_inspect: nontakeover _command_fact_row has _kind_facts( and display_fact(")
 t.check(pipeline_lookup_call_count(nontakeover,unwired_to)==0 and pipeline_lookup_call_count(nontakeover,"command_facts")==0,"pipeline_lookup_inspect: nontakeover _command_fact_row is a single path (no _fact_source( / command_facts()")
 var kind_body=bodies["_kind_facts"]
 var default_arm=pipeline_lookup_default_arm(kind_body)
 t.check(not default_arm.is_empty(),"pipeline_lookup_inspect: _kind_facts has a _: arm")
 var match_part=kind_body.trim_suffix(default_arm) if not default_arm.is_empty() else kind_body
 var missing_arms=[]
 for kind in T4_WIRED_KINDS:
  if match_part.find('"'+kind+'"')<0: missing_arms.append(kind)
  if not GameCore.COMMAND_KEYS.has(kind): missing_arms.append(kind+"!COMMAND_KEYS")
 t.check(missing_arms.is_empty(),"pipeline_lookup_inspect: every T4_WIRED_KINDS kind has a match arm and is in COMMAND_KEYS: "+str(missing_arms))
 t.check(pipeline_lookup_call_count(default_arm,unwired_to)==1 and default_arm.find("COMMAND_KEYS.has(")>=0,"pipeline_lookup_inspect: _: arm is COMMAND_KEYS.has(kind) then _fact_source()")
 var unwired_keys=0
 for kind in GameCore.COMMAND_KEYS:
  if kind in T4_WIRED_KINDS: continue
  unwired_keys+=1
 t.check(unwired_keys>0,"pipeline_lookup_inspect: COMMAND_KEYS has kinds that take the _: arm")
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

# docs/spec/candidate-removal.md T4：command_fact 经 kind 调该生产者，不经全表。
static func command_fact_kind_lookup(t) -> void:
 pipeline_lookup_inspect(t)
 var compared=0
 for cell in T4_EQUIVALENCE_CELLS:
  var g=r1_build(cell[0],cell[1])
  var key="%s:%d" % [cell[0],cell[1]]
  var facts=g.command_facts()
  var view=g.get_view()
  t.check(facts.size()==int(R5_BASELINE[key].view_display_facts),"T4 command_facts count matches the pre-slice snapshot "+key+" have="+str(facts.size())+" want="+str(R5_BASELINE[key].view_display_facts))
  t.check(view.display_facts.size()==facts.size(),"T4 get_view display_facts count stays aligned with command_facts "+key)
  for fact in facts:
   if not t4_wired_row(g,fact): continue
   var found=g.command_fact(g.command(fact.payload,g.state.version))
   t.check(found==fact,"T4 command_fact matches the full-table row kind="+String(fact.payload.kind)+" key="+String(fact.get("key",""))+" fixture="+key)
   compared+=1
 t.check(compared>0,"T4 command_fact compared wired rows against the full table")
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
