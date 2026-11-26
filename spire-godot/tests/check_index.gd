extends RefCounted

# Derived check index for the spire-godot check entry (docs/spec/check-routing.md §3).
# One implementation is shared by the generator (tools/build_check_index.gd), the
# zero-drift gate (tools/check-index.ps1), the runner self-check (tests/runner_cases.gd)
# and the plan host (tests/route_plan.gd); tests/check_index.json is only ever written
# by the generator.
#
# Extraction rules (any change here is a derivation change and requires
# tools/check-index.ps1 -Write in the same commit):
#  * registry + ownership: `SUITES` in tests/test_game.gd and `UI_MODULES` in
#    tests/ui_smoke.gd are read as text (never preloaded). A registered path is a visit
#    root; nested `preload("res://tests/...").run(t|self)` calls inherit its owner.
#    Owners are qualified `rule:<name>` / `ui:<name>`: a name can be registered in both
#    registries (persistence, events, casting, ...), and only the pair is a suite.
#  * `preload`  : "res://core|data|ui/..." targets inside a case file, exact.
#  * `symbol`   : `(g|game|t.game|ui.game).<member>(` against plain `func <member>(`
#                 declarations in core|data (the receiver is a game instance, never the
#                 UI Control, so ui files never take a rule edge).
#  * `symbol_ui`: `ui.<member>(` inside UI case files against `func <member>(` in ui.
#  * `domain`   : blind files only, through Edges.DOMAINS (assertion-message words).
#  * `static func` declarations are deliberately not indexed (generic helpers declared
#    in many files); their consumers stay covered by DOMAINS/BLIND_BY_DESIGN plus the
#    directory closure (docs/spec/check-routing.md §5.3).
#  * output is canonical: keys sorted, arrays sorted, no timestamps; the frozen file is
#    written with JSON.stringify(body, "  ", true) so its key order is stable.
#  * inputs are all scanned texts, so a comment edit in core|data|ui or tests also
#    invalidates the frozen index until -Write (docs/spec/check-routing.md §3.3).
#  * every scanned text is read through tests/source_text.gd::normalized_text, which folds CRLF
#    pairs to LF: a frozen digest then equals the digest of the git blob and no longer depends on
#    the checkout's line endings; the leaf's own text is one of the hashed inputs
#    (docs/spec/check-routing.md §4).
# Size: derive (scan/compare) and suites_for (route/render) share this module; the
# responsibility boundary is the whole index pipeline, not a line count. The one scanned-text
# primitive lives in the leaf tests/source_text.gd (docs/spec/check-routing-dependencies.md).
const SourceText=preload("res://tests/source_text.gd")
const SOURCE_TEXT_LEAF="res://tests/source_text.gd"
const Edges=preload("res://tests/check_index_edges.gd")
const FROZEN_PATH="res://tests/check_index.json"
const MODULE="spire-godot/"
const SUITE_SELECTION="res://tests/suite_selection.gd"
const HOSTS=["res://tests/test_game.gd","res://tests/ui_smoke.gd"]
const OWN_KINDS=["rule","ui"]
const SOURCE_DIRS=["core","data","ui"]
const ALL_DEV="all-dev"
const ALL_DEV_UI="all-dev-ui"
const CORE_APPEND=["architecture","persistence","runner"]

# ---------------------------------------------------------------- public interface

static func derive() -> Dictionary:
 var scan=_scan()
 var body={"suite_files":scan.suite_files,"case_files":scan.case_files,"domains":scan.domains,
  "blind":scan.blind,"domain_words":scan.domain_words,"registries":scan.registries,"stats":scan.stats}
 var out=body.duplicate(true)
 out.schema=1
 out.generated_from=scan.generated_from
 out.digest=canonical(body).sha256_text()
 return out

static func frozen() -> Dictionary:
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(FROZEN_PATH))
 return parsed if parsed is Dictionary else {}
# "" when the frozen index is readable, otherwise the reason (never silent).

static func frozen_error() -> String:
 var text=FileAccess.get_file_as_string(FROZEN_PATH)
 if text=="": return "frozen index is missing or unreadable: "+FROZEN_PATH
 var parsed=JSON.parse_string(text)
 if not (parsed is Dictionary): return "frozen index is not a JSON object: "+FROZEN_PATH
 if int(parsed.get("schema",0))!=1: return "frozen index schema is not 1: "+FROZEN_PATH
 return ""
# Structural comparison. JSON round-trips numbers as floats, so int/float are the same
# family here; ok is decided by the walk, never by a string fast path.

static func compare(a: Dictionary, b: Dictionary) -> Dictionary:
 var diff=_first_diff(a,b,"")
 return {"ok":diff=="","first_diff":diff}

static func canonical(value) -> String:
 return JSON.stringify(value,"",true)
# Route a change set (repository-root relative paths) to suites. Reads the frozen index
# only; returns rows plus the printable ROUTE lines so callers never re-derive.

static func suites_for(files: Array, mode: String = "changed") -> Dictionary:
 var result={"ok":true,"error":"","mode":mode,"files":[],"files_sha256":"","index_digest":"",
  "rules":[],"ui":[],"gates":[],"rows":[],"default_files":[],"unmapped":[],"blind_files":[],
  "declared_none":[],"widen":[],"widen_candidates":[],"milestone":[],"notes":[],"defect_hits":[],"lines":[]}
 var failure=frozen_error()
 if failure!="":
  result.ok=false;result.error=failure;return result
 var index=frozen()
 var registries=_registries()
 var milestone=_milestone()
 var normalized=_normalize_files(files)
 result.files=normalized
 if normalized.is_empty(): result.ok=false;result.error="empty change set";return result
 result.files_sha256=",".join(normalized).sha256_text()
 result.index_digest=String(index.get("digest",""))
 for path in normalized:
  if path.begins_with(MODULE): continue
  if _declared_none(path): continue
  result.ok=false;result.error="path is outside "+MODULE+": "+path
  return result
 var rules={};var ui={};var gates={}
 # The frozen main table is suite -> {source file -> kinds}; routing needs the reverse
 # (source file -> {suite -> kinds}), built once per plan.
 var reverse=_reverse(index.get("suite_files",{}))
 for path in normalized:
  var row={"path":path,"rules":[],"ui":[],"gates":[],"signals":[],"via":""}
  if _declared_none(path):
   row.via="declared_none"
   result.declared_none.append(path);result.rows.append(row);continue
  _route_one(path,reverse,index.get("case_files",{}),registries,row)
  if row.via=="closure": result.default_files.append(path)
  if row.via=="unmapped": result.default_files.append(path);result.unmapped.append(path)
  if row.via=="domain": result.blind_files.append(path)
  for name in row.rules: rules[name]=true
  for name in row.ui: ui[name]=true
  for name in row.gates: gates[name]=true
  result.rows.append(row)
 for path in normalized:
  for entry in Edges.WIDEN:
   if String(entry.path)!=path: continue
   var widened=_widen_names(String(entry.add),registries)
   for name in widened.rules: rules[name]=true
   for name in widened.ui: ui[name]=true
   result.widen.append({"path":path,"add":entry.add,"rules":widened.rules,"ui":widened.ui})
 var deducted={}
 for name in rules.keys():
  if name in milestone: rules.erase(name);deducted[name]=true
 for name in ui.keys():
  if name in milestone: ui.erase(name);deducted[name]=true
 result.milestone=deducted.keys()
 result.milestone.sort()
 result.rules=_registry_order(rules,registries.rule)
 result.ui=_registry_order(ui,registries.ui)
 if gates.has("content"): result.gates.append("content")
 result.widen_candidates=_widen_candidates(result.rules)
 for entry in Edges.ORACLE_NOTES:
  for path in normalized:
   if path==String(entry.path): result.notes.append({"path":path,"note":entry.note})
 for entry in Edges.INDEX_DEFECTS:
  if normalized.has(String(entry.path)): result.defect_hits.append(String(entry.path))
 result.lines=_render(result,index,milestone)
 return result

# ------------------------------------------------------------------------ internals

static func _reverse(suite_files: Dictionary) -> Dictionary:
 var out={}
 for suite in suite_files.keys():
  for target in suite_files[suite].keys():
   if not out.has(target): out[target]={}
   out[target][suite]=suite_files[suite][target]
 return out

static func _route_one(path: String, reverse: Dictionary, case_files: Dictionary, registries: Dictionary, row: Dictionary) -> void:
 if case_files.has(path):
  row.via="owner"
  _add(row,String(case_files[path].get("owner","")))
  return
 if reverse.has(path):
  row.via="index"
  for suite in reverse[path].keys():
   for kind in reverse[path][suite]: if kind not in row.signals: row.signals.append(kind)
   _add(row,suite)
  row.signals.sort()
  if path.begins_with(MODULE+"core/"):
   # Coordinator ruling §11-4-①: cross-cutting/meta suites ride along on core edits.
   for name in CORE_APPEND:
    if name not in row.rules: row.rules.append(name)
   row.signals.append("core-append")
  return
 var entry=_closure_for(path)
 if entry.is_empty():
  row.via="unmapped"
  row.rules=_names(registries.rule)
  row.ui=_names(registries.ui)
  return
 row.via="closure"
 var rule_spec=String(entry.get("rules",""))
 var ui_spec=String(entry.get("ui",""))
 row.rules=_names(registries.rule) if rule_spec==ALL_DEV else rule_spec.split(",",false)
 row.ui=_names(registries.ui) if ui_spec==ALL_DEV_UI else ui_spec.split(",",false)
 for name in String(entry.get("gates","")).split(",",false):
  if name!="" and name not in row.gates: row.gates.append(name)

static func _add(row: Dictionary, suite: String) -> void:
 var parts=suite.split(":")
 if parts.size()!=2: return
 if parts[0]=="rule" and parts[1] not in row.rules: row.rules.append(parts[1])
 elif parts[0]=="ui" and parts[1] not in row.ui: row.ui.append(parts[1])

static func _widen_names(add: String, registries: Dictionary) -> Dictionary:
 var out={"rules":[],"ui":[]}
 if not add.begins_with("impact:"): return out
 var area=add.trim_prefix("impact:")
 var areas=_cross_areas()
 for name in areas.keys():
  if area not in areas[name]: continue
  if registries.rule.has(name) and name not in out.rules: out.rules.append(name)
  if registries.ui.has(name) and name not in out.ui: out.ui.append(name)
 out.rules=_registry_order(out.rules,registries.rule)
 out.ui=_registry_order(out.ui,registries.ui)
 return out

static func _render(result: Dictionary, index: Dictionary, milestone: Array) -> Array:
 var lines=[]
 lines.append("ROUTE MODE: %s (development feedback only; milestone gates use -Suite all -UI -UISuite all)" % result.mode)
 lines.append("ROUTE FILES: %d (sha256 %s; index digest %s)" % [result.files.size(),result.files_sha256.substr(0,12),result.index_digest.substr(0,12)])
 var domains=index.get("domains",{})
 for row in result.rows:
  var path=String(row.path)
  var scope="rules=%s ui=%s" % [_join(row.rules),_join(row.ui)]
  if row.via=="declared_none": lines.append("ROUTE NONE: %s (outside the source fingerprint; no suites, never a pass)" % path)
  elif row.via=="owner": lines.append("ROUTE ROW: %s -> %s [signals=owner]" % [path,scope])
  elif row.via=="index": lines.append("ROUTE ROW: %s -> %s [signals=%s]" % [path,scope,",".join(row.signals)])
  elif row.via=="domain":
   lines.append("ROUTE ROW: %s -> %s [signals=domain]" % [path,scope])
   lines.append("ROUTE DOMAIN: %s (blind, DOMAINS %s resolved through the corpus to %s)" % [path,_join(domains.get(path,{}).get("domains",[])),_join(domains.get(path,{}).get("suites",[]))])
  elif row.via=="closure":
   lines.append("ROUTE DEFAULT: %s (blind, closure=%s)" % [path,String(_closure_for(path).get("prefix",""))])
   lines.append("ROUTE DEFAULT SCOPE: %s -> %s gates=%s" % [path,scope,_join(row.gates)])
  elif row.via=="unmapped": lines.append("ROUTE UNMAPPED: %s (no index edge and no closure; fail-closed to %s + %s)" % [path,ALL_DEV,ALL_DEV_UI])
  if row.via=="index" and "core-append" in row.signals: lines.append("ROUTE CORE APPEND: %s += %s (coordinator ruling §11-4-①)" % [path,",".join(CORE_APPEND)])
 for entry in result.widen: lines.append("ROUTE WIDEN: %s +%s -> rules=%s ui=%s" % [entry.path,entry.add,_join(entry.rules),_join(entry.ui)])
 for entry in Edges.BLIND_BY_DESIGN:
  if result.default_files.has(String(entry.path)): lines.append("ROUTE BLIND: %s (BLIND_BY_DESIGN: %s)" % [entry.path,entry.reason])
 for candidate in result.widen_candidates:
  lines.append("ROUTE WIDEN CANDIDATE: %s -> %d suite(s) declare that area in CROSS_AREAS and are not selected (not automatic; write WIDEN to widen): %s" % [candidate.area,candidate.others.size(),",".join(candidate.others)])
 for entry in result.notes: lines.append("ROUTE NOTE: %s -> %s" % [entry.path,entry.note])
 for path in result.defect_hits: lines.append("ROUTE KNOWN GAP: %s (INDEX_DEFECTS)" % path)
 lines.append("ROUTE MILESTONE: declared %s; deducted in this plan: %s (development routing never runs milestone suites; the milestone command -Suite all -UI -UISuite all must include them)" % [_join(milestone),_join(result.milestone)])
 if result.default_files.size()>0: lines.append("ROUTE MILESTONE COVERAGE: %d closure/fallback file(s) need the milestone full run: %s" % [result.default_files.size(),_join(result.default_files)])
 if result.gates.size()>0: lines.append("ROUTE GATE: %s (own phase, reported separately; tools/check-content.ps1)" % _join(result.gates))
 lines.append("ROUTE RULE SCOPE: %s" % _join(result.rules))
 lines.append("ROUTE UI SCOPE: %s" % _join(result.ui))
 return lines

static func _widen_candidates(selected: Array) -> Array:
 var areas=_cross_areas()
 var out=[]
 for name in selected:
  var others=[]
  for area in areas.keys():
   if name in areas[area] and area!=name and area not in selected: others.append(area)
  if others.size()>0: out.append({"area":name,"others":others})
 return out

static func _closure_for(path: String) -> Dictionary:
 for entry in Edges.CLOSURE:
  if not path.begins_with(String(entry.prefix)): continue
  # The catch-all covers the module root files (project.godot, main.tscn) only; a new
  # directory below spire-godot/ must stay unmapped (fail-closed, §5.2).
  if String(entry.prefix)==MODULE and path.trim_prefix(MODULE).find("/")!=-1: continue
  return entry
 return {}

static func _join(values) -> String:
 var out=Array(values)
 return ",".join(out) if out.size()>0 else "(none)"

static func _declared_none(path: String) -> bool:
 for prefix in ["docs/","release/",".zcode/","skills/","spire-godot/build/","spire-godot/.godot/"]:
  if path.begins_with(prefix): return true
 if path.find("/")==-1 and path.ends_with(".md"): return true
 return path in ["README.md","AGENTS.md",".gitignore","LICENSE","ASSET_RIGHTS.md"]
# Wins are repository-root relative; the routing tables (frozen + edges) use the
# spire-godot/-prefixed key, so one normalisation feeds both readers.

static func _normalize_files(files: Array) -> Array:
 var out={}
 for raw in files:
  var path=String(raw).replace("\\","/").trim_prefix("./").strip_edges()
  if path=="": continue
  out[path]=true
 return out.keys()
# Result sets follow registry order so two runs of the same input compare literally.
# Accepts a set (Dictionary) or a list (Array) of names.

static func _registry_order(names, registry: Dictionary) -> Array:
 var wanted={}
 if names is Array:
  for name in names: wanted[name]=true
 else:
  for name in names.keys(): wanted[name]=true
 var out=[]
 for name in registry.keys(): if wanted.has(name): out.append(name)
 for name in wanted.keys(): if not registry.has(name) and name not in out: out.append(name)
 return out
# Every registered suite except the milestone long runs, in registry order.

static func _names(registry: Dictionary) -> Array:
 var excluded=_milestone_set()
 var out=[]
 for name in registry.keys(): if not excluded.has(name): out.append(name)
 return out

# -------------------------------------------------------------------- corpus scans

static func _scan() -> Dictionary:
 var registries=_registries()
 var owners=_owners()
 var case_paths=_case_paths()
 var sources=_source_paths()
 var declarations=_declarations(sources)
 var suite_files={}
 var case_files={}
 var word_suites={}
 for case_path in case_paths:
  var key=_key(case_path)
  var text=SourceText.normalized_text(case_path)
  var owner=String(owners.get(case_path,""))
  var signals=_signals(text,declarations)
  case_files[key]={"owner":owner,"signals":signals.size()}
  # Suites without any edge stay out of the main table on purpose: the reachability
  # check then has to consult Edges.SUITE_EXEMPT instead of passing on an empty key.
  if owner=="" or signals.is_empty(): continue
  if not suite_files.has(owner): suite_files[owner]={}
  for target in signals.keys(): _merge(suite_files[owner],target,signals[target])
  for word in _domain_words(text).keys():
   if not word_suites.has(word): word_suites[word]={}
   word_suites[word][owner]=true
 var domains={}
 var used={}
 for entry in Edges.DOMAINS:
  # DOMAINS entries are repository-root relative already (do not pass them to _key).
  var path_key=String(entry.path)
  # A ui/** file is consumed by UI case files only: rule suites run headless and reach
  # ui code through explicit preload, which the derived edge already records. Without
  # this a same-named rule suite would ride along on a pure UI change.
  var allow_rule=not path_key.begins_with(MODULE+"ui/")
  var names={}
  for word in entry.domains:
   used[word]=true
   for owner in word_suites.get(word,{}).keys():
    if not allow_rule and String(owner).begins_with("rule:"): continue
    names[owner]=true
  for owner in names.keys():
   if not suite_files.has(owner): suite_files[owner]={}
   _merge(suite_files[owner],path_key,["domain"])
  domains[path_key]={"domains":_sorted(entry.domains),"suites":_sorted(names.keys())}
 for suite in suite_files.keys():
  for target in suite_files[suite].keys(): suite_files[suite][target]=_sorted(suite_files[suite][target])
 var covered={}
 for suite in suite_files.keys():
  for target in suite_files[suite].keys(): covered[target]=true
 var blind=[]
 for path in sources:
  var key=_key(path)
  if not covered.has(key) and not domains.has(key): blind.append(key)
 blind.sort()
 var edges=0
 for suite in suite_files.keys(): edges+=suite_files[suite].size()
 var domain_words={}
 for word in used.keys(): domain_words[word]=_sorted(word_suites.get(word,{}).keys())
 var inputs=HOSTS+["res://tests/check_index_edges.gd","res://tests/check_index.gd",SOURCE_TEXT_LEAF]+case_paths+sources
 inputs.sort()
 var lines=[]
 for path in inputs: lines.append(_key(path)+":"+SourceText.normalized_text_sha256(path))
 var stats={"rule_suites":registries.rule.size(),"ui_suites":registries.ui.size(),
  "suite_edges":edges,"suites_with_edges":suite_files.size(),"case_files":case_files.size(),
  "source_files":sources.size(),"sources_with_edges":covered.size(),"blind":blind.size(),
  "domains":domains.size(),"domains_declared":Edges.DOMAINS.size(),"excluded":Edges.EXCLUDE.size(),
  "blind_by_design":Edges.BLIND_BY_DESIGN.size(),"widen":Edges.WIDEN.size(),"inputs":inputs.size()}
 return {"suite_files":suite_files,"case_files":case_files,"domains":domains,"blind":blind,
  "domain_words":domain_words,"registries":{"rule":registries.rule.keys(),"ui":registries.ui.keys()},
  "stats":stats,"generated_from":"\n".join(lines).sha256_text()}

static func _registries() -> Dictionary:
 var out={}
 var texts={"rule":SourceText.normalized_text(HOSTS[0]),"ui":SourceText.normalized_text(HOSTS[1])}
 for kind in OWN_KINDS:
  var registry={}
  var marker="const SUITES=" if kind=="rule" else "const UI_MODULES="
  for entry in _dict_entries(texts[kind],marker,kind=="ui"):
   # Null entries (suites carried by a host function) keep an empty path.
   registry[entry.name]="" if entry.file=="" else entry.file
  out[kind]=registry
 return out
# Reads `"name":"res://tests/file.gd"` entries inside one const dictionary literal.
# Null entries (suites carried by a host function) are registered with an empty path.

static func _dict_entries(text: String, marker: String, stop_at_func: bool = false) -> Array:
 var out=[]
 if text.find(marker)==-1: return out
 var body=text.split(marker,true,1)[1]
 if stop_at_func: body=body.split("func ")[0]
 body=body.split("}")[0]
 var re=RegEx.new()
 re.compile("\"([a-z_0-9]+)\":\\s*(\"(res://tests/[^\"]+)\"|null)")
 for match in re.search_all(body):
  out.append({"name":match.get_string(1),"file":match.get_string(3) if match.get_string(3)!=null else ""})
 return out

static func _owners() -> Dictionary:
 var owners={}
 var re=RegEx.new()
 re.compile("preload\\(\"(res://tests/[^\"]+)\"\\)\\.run\\((?:t|self)(?:,|\\))")
 var registries=_registries()
 for kind in OWN_KINDS:
  for name in registries[kind].keys():
   _visit(registries[kind][name],kind+":"+name,owners,re)
 return owners

static func _visit(path: String, owner: String, owners: Dictionary, re: RegEx) -> void:
 if path=="" or owners.has(path): return
 owners[path]=owner
 for match in re.search_all(SourceText.normalized_text(path)):
  _visit(match.get_string(1),owner,owners,re)

static func _case_paths() -> Array:
 var out=[]
 var directory=DirAccess.open("res://tests")
 if directory==null: return out
 for file in directory.get_files():
  if file.ends_with("_cases.gd"): out.append("res://tests/"+file)
 out.sort()
 return out

static func _source_paths() -> Array:
 var out=[]
 for root in SOURCE_DIRS: _collect("res://"+root,out)
 out.sort()
 return out

static func _collect(path: String, out: Array) -> void:
 var directory=DirAccess.open(path)
 if directory==null: return
 for file in directory.get_files():
  if file.ends_with(".gd"): out.append(path+"/"+file)
 for child in directory.get_directories(): _collect(path+"/"+child,out)

static func _declarations(sources: Array) -> Dictionary:
 var out={}
 var re=RegEx.new()
 # (?m) is required: Godot's RegEx is not multiline by default and ^ would only match
 # the start of the whole file.
 re.compile("(?m)^func ([a-z_][a-z0-9_]*)\\(")
 for path in sources:
  for match in re.search_all(SourceText.normalized_text(path)):
   var member=match.get_string(1)
   if not out.has(member): out[member]={}
   out[member][_key(path)]=true
 return out

static func _signals(text: String, declarations: Dictionary) -> Dictionary:
 var out={}
 var preload_re=RegEx.new()
 preload_re.compile("preload\\(\"res://((?:core|data|ui)/[^\"]+)\"\\)")
 for match in preload_re.search_all(text): _merge(out,MODULE+match.get_string(1),["preload"])
 var facade_re=RegEx.new()
 facade_re.compile("(?<![A-Za-z0-9_])(?:g|game|t\\.game|ui\\.game)\\.([a-z_][a-z0-9_]*)\\(")
 for match in facade_re.search_all(text):
  for path in declarations.get(match.get_string(1),{}).keys():
   if path.begins_with(MODULE+"core/") or path.begins_with(MODULE+"data/"): _merge(out,path,["symbol"])
 var ui_re=RegEx.new()
 ui_re.compile("\\bui\\.([a-z_][a-z0-9_]*)\\(")
 for match in ui_re.search_all(text):
  for path in declarations.get(match.get_string(1),{}).keys():
   if path.begins_with(MODULE+"ui/"): _merge(out,path,["symbol_ui"])
 return out

static func _merge(out: Dictionary, path: String, kinds: Array) -> void:
 if not out.has(path): out[path]=[]
 for kind in kinds:
  if kind not in out[path]: out[path].append(kind)

static func _domain_words(text: String) -> Dictionary:
 var out={}
 var re=RegEx.new()
 re.compile("\"([A-Z][A-Z0-9_]{1,})[ :]")
 for match in re.search_all(text): out[match.get_string(1)]=true
 return out
# The milestone declaration lives in tests/suite_selection.gd (LONG_RUNS), read as text so
# the index never preloads a host-side selection script.

static func _milestone() -> Array:
 var out=[]
 var text=SourceText.normalized_text(SUITE_SELECTION)
 var re=RegEx.new()
 re.compile("(?m)^const LONG_RUNS=\\[([^\\]]*)\\]")
 var line=re.search(text)
 if line!=null:
  for match in RegEx.create_from_string("\"([a-z_0-9]+)\"").search_all(line.get_string(1)): out.append(match.get_string(1))
 out.sort()
 return out

static func _milestone_set() -> Dictionary:
 var out={}
 for name in _milestone(): out[name]=true
 return out

static func _cross_areas() -> Dictionary:
 var out={}
 var text=SourceText.normalized_text(SUITE_SELECTION)
 if text.find("const CROSS_AREAS=")==-1: return out
 var body=text.split("const CROSS_AREAS=",true,1)[1].split("}")[0]
 var re=RegEx.new()
 re.compile("\"([a-z_0-9]+)\":\\[([^\\]]*)\\]")
 for match in re.search_all(body):
  var areas=[]
  for item in match.get_string(2).split(","):
   var name=item.strip_edges().trim_prefix("\"").trim_suffix("\"")
   if name!="": areas.append(name)
  out[match.get_string(1)]=areas
 return out

static func _key(path: String) -> String:
 return MODULE+path.trim_prefix("res://")
# duplicate() first: const tables in the edges layer are read-only arrays.

static func _sorted(values: Array) -> Array:
 var out=values.duplicate()
 out.sort()
 return out

static func _first_diff(a, b, prefix: String) -> String:
 var at=prefix if prefix!="" else "root"
 var numeric=(typeof(a)==TYPE_INT or typeof(a)==TYPE_FLOAT) and (typeof(b)==TYPE_INT or typeof(b)==TYPE_FLOAT)
 if numeric: return "" if is_equal_approx(float(a),float(b)) else at+" (%s vs %s)" % [str(a),str(b)]
 if typeof(a)!=typeof(b): return at+" (type)"
 if a is Dictionary:
  var keys={}
  for key in a.keys(): keys[key]=true
  for key in b.keys(): keys[key]=true
  for key in _sorted(keys.keys()):
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
