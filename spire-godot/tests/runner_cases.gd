extends RefCounted
const Selection=preload("res://tests/suite_selection.gd")
const Index=preload("res://tests/check_index.gd")
const IndexEdges=preload("res://tests/check_index_edges.gd")

static func run(t) -> void:
 ownership(t)
 index(t)
 t.check(Selection.stage("home_persistence").begins_with("deferred") and Selection.stage("normal_play").begins_with("milestone"),"RUNNER deferred saves and long playthroughs remain explicitly scheduled")
 for name in ["card_power","card_expansion","relics"]:
  t.check(Selection.resolve(t.SUITES.keys(),[name]).selected==[name],"RUNNER current feature has its own complete scope "+name)
  for area in Selection.CROSS_AREAS.rewards:
   if area not in ["card_power","card_expansion","relics"]:
    t.check(name in Selection.resolve(t.SUITES.keys(),[area],true).selected,"RUNNER extracted feature keeps its former reward integration coverage: "+name+" / "+area)
 t.check(t.SUITES.values().all(func(suite):return suite==null or suite is String),"RUNNER registries contain resource paths so unselected suites are never preloaded")
 var names=t.SUITES.keys()
 t.check("application" in Selection.resolve(names,["prison"],true).selected,"RUNNER prison mixed profiles include shared installer coverage")
 for area in ["card_power","card_expansion","relics","witch_character","persistence"]:
  t.check("basic_attacks" in Selection.resolve(names,[area],true).selected,"RUNNER basic attacks retain card, relic, character and first-use persistence integration: "+area)
 for area in ["relics","card_power","card_growth","witch_character"]:
  t.check("card_splash" in Selection.resolve(names,[area],true).selected,"RUNNER live card values and splash follow attribute, growth and character changes: "+area)
 for area in ["card_power","card_expansion","relics","special_equipment"]:
  t.check("pressure" in Selection.resolve(names,[area],true).selected,"RUNNER interruption and energy-refund interactions follow changes to "+area)
 for area in ["core","guard"]:
  t.check("iron_man" in Selection.resolve(names,[area],true).selected,"RUNNER shared capture readiness changes include Iron Man: "+area)
 t.check(Selection.resolve(names,["witch_character"]).selected==["witch_character"],"RUNNER witch character rules have an executable complete scope")
 t.check("enemies" in Selection.resolve(names,["witch_character"],true).selected,"RUNNER witch attacks include shared multi-hit enemy barrier checks")
 for area in ["card_power","relics"]:
  t.check("enemies" in Selection.resolve(names,[area],true).selected,"RUNNER area damage sources include shared enemy barrier checks: "+area)
 for area in Selection.CROSS_AREAS.witch_character:
  t.check("witch_character" in Selection.resolve(names,[area],true).selected,"RUNNER witch character follows its affected boundary "+area)
 for area in ["core","services","casting","card_power","persistence"]:
  t.check("enchantments" in Selection.resolve(names,[area],true).selected,"RUNNER enchantments follow affected upstream: "+area)
 t.check(["services","card_power","card_splash","casting","architecture"].all(func(name):return name in Selection.resolve(names,["enchantments"],true).selected),"RUNNER enchantment changes include affected integration suites")
 var direct=Selection.resolve(names,["casting","casting"])
 t.check(direct.ok and direct.selected==["casting"] and direct.reasons.casting=="requested","RUNNER focus mode executes only the named complete suite once")
 t.check(not Selection.resolve(names,["contact"]).ok and Selection.resolve(names,["contact"],true).ok,"RUNNER synthetic areas require explicit impact expansion")
 t.check(Selection.resolve(names,["runner","architecture"]).selected.size()==2,"RUNNER default fast checks never expand into gameplay or long runs")
 var saved=Selection.resolve(names,["persistence"],true).selected
 t.check("persistence" in saved and "special_equipment" in saved and "prison" in saved and "tower_progression" in saved and "normal_play" not in saved,"RUNNER save checks include prison and continued-run persistence without recursive expansion")
 var casting=Selection.resolve(names,["casting"],true).selected
 t.check("prison" in casting and "status" in casting and "rewards" in casting and "tower_progression" not in casting,"RUNNER related cross coverage included without recursive expansion")
 var a=Selection.resolve(names,["contact"],true).selected
 var b=Selection.resolve(names,["casting"],true).selected
 var merged=Selection.resolve(names,["contact","casting","contact"],true).selected
 t.check(merged.size()==merged.reduce(func(acc,x):acc[x]=true;return acc,{}).size() and (a+b).all(func(x):return x in merged),"RUNNER overlapping scopes execute every related suite exactly once")
 t.check(Selection.resolve(names,["all"],true).selected==names and not Selection.resolve(names,["all","typo"],true).ok and not Selection.resolve(names,[],true).ok,"RUNNER full coverage preserved and invalid selection rejected")
 var plan=Selection.resolve(names,["enemies"],true)
 t.check(plan.reasons.enemies=="requested" and plan.reasons.content=="cross: enemies" and plan.selected==plan.reasons.keys(),"RUNNER plan explains every selected module without changing scope")
 for area in ["core","enemies","equipment"]:
  var selected=Selection.resolve(names,[area],true).selected
  t.check("basic_attacks" in selected and "battle_saturation" in selected,"RUNNER attack and battle completion checks follow their affected area "+area)
 t.check("battle_saturation" in Selection.resolve(names,["application"],true).selected,"RUNNER installation changes include battle saturation coverage")
 var combined=Selection.resolve(names,["core","enemies","application"],true).selected
 t.check(combined.count("basic_attacks")==1 and combined.count("battle_saturation")==1,"RUNNER shared battle cases execute once across overlapping scopes")
 for id in Selection.SEED_SETS:
  var spec=Selection.SEED_SETS[id]
  var full=Selection.seeds(id,true);var daily=Selection.seeds(id,false)
  t.check(full==range(spec.count)+spec.get("extra",[]) and daily.size()>0 and daily.size()<full.size(),"RUNNER complete historical seed matrix retained "+id)
  t.check(daily.all(func(seed):return seed in full) and daily.size()==daily.reduce(func(acc,x):acc[x]=true;return acc,{}).size(),"RUNNER daily seeds form a deterministic unique subset "+id)
  var original=daily.duplicate();daily.clear()
  t.check(Selection.seeds(id,false)==original,"RUNNER sample calls cannot mutate the registry "+id)

# Follow actual run calls, not helper imports. A case must have exactly one owner.
static func ownership(t) -> void:
 var paths=t.SUITES.values().filter(func(path):return path is String)
 # Inline core/UI cases also own run(self) calls; shared runner probes are not cases.
 paths.append_array(["res://tests/test_game.gd","res://tests/ui_smoke.gd"])
 var ui=FileAccess.get_file_as_string("res://tests/ui_smoke.gd").split("func module_checks")[0]
 var registry=RegEx.new();registry.compile('"[^"\\n]+":\\s*"(res://tests/[^"\\n]+)"')
 for entry in registry.search_all(ui): paths.append(entry.get_string(1))
 var calls=RegEx.new();calls.compile(r'preload\("(res://tests/[^"]+_cases\.gd)"\)\.run\((?:t|self)(?:,|\))')
 var owners={}
 for path in paths: visit(t,path,path,owners,calls)
 var directory=DirAccess.open("res://tests")
 for file in directory.get_files():
  if file.ends_with("_cases.gd"):
   var path="res://tests/"+file
   if FileAccess.get_file_as_string(path).contains("static func run("):
    t.check(owners.has(path),"RUNNER executable test file has a registered owner: "+file)

static func visit(t,path: String,owner: String,owners: Dictionary,calls: RegEx) -> void:
 t.check(not owners.has(path),"RUNNER test executes only once across all categories: "+path)
 if owners.has(path): return
 owners[path]=owner
 for call in calls.search_all(FileAccess.get_file_as_string(path)):
  visit(t,call.get_string(1),owner,owners,calls)

# Derived check index self-check (docs/spec/check-routing.md §3.4 i-viii and §6-G3). One
# derive() call feeds every judgement below, so the coverage scan, the zero-drift
# comparison and the route examples share one pass over the corpus. Every message's second
# word is the judgement name: tools/check-mutation.ps1 matches ERROR lines by that name.
static func index(t) -> void:
 var derived=Index.derive()
 var frozen=Index.frozen()
 index_covers_every_case_file(t,derived)
 index_targets_exist(t,derived)
 index_matches_regeneration(t,derived,frozen)
 index_regeneration_is_the_only_writer(t,derived,frozen)
 index_suites_are_all_reachable(t,derived)
 index_skips_no_source_file(t,derived)
 index_declared_domains_exist(t,derived)
 index_defects_stay_closed(t,derived)
 index_route_examples_are_pinned(t)

# i: every executable case file is in case_files with an owner that is a registered suite.
static func index_covers_every_case_file(t,derived: Dictionary) -> void:
 var directory=DirAccess.open("res://tests")
 if directory==null:
  t.check(false,"RUNNER index_covers_every_case_file: res://tests is not readable")
  return
 for file in directory.get_files():
  if not file.ends_with("_cases.gd"): continue
  if not FileAccess.get_file_as_string("res://tests/"+file).contains("static func run("): continue
  var key="spire-godot/tests/"+file
  t.check(derived.case_files.has(key),"RUNNER index_covers_every_case_file: "+file+" is in the frozen index")
  if not derived.case_files.has(key): continue
  var owner=String(derived.case_files[key].owner)
  var parts=owner.split(":")
  var registered=parts.size()==2 and Array(derived.registries.get(parts[0],[])).has(parts[1])
  t.check(registered,"RUNNER index_covers_every_case_file: %s has owner %s from the registries" % [file,owner])

# ii: every edge target exists on disk (a stale target is a phantom edge).
static func index_targets_exist(t,derived: Dictionary) -> void:
 for suite in derived.suite_files.keys():
  for target in derived.suite_files[suite].keys():
   t.check(_index_target_exists(String(target)),"RUNNER index_targets_exist: "+String(target))

# iii: the frozen file equals a fresh derivation (zero drift), schema 1.
static func index_matches_regeneration(t,derived: Dictionary, frozen: Dictionary) -> void:
 var failure=Index.frozen_error()
 t.check(failure=="","RUNNER index_matches_regeneration: frozen tests/check_index.json is readable with schema 1: "+failure)
 var comparison=Index.compare(derived,frozen)
 t.check(comparison.ok,"RUNNER index_matches_regeneration: frozen index equals the derivation; first difference: "+comparison.first_diff)

# viii: digest and generated_from are the machine-readable form of iii; only the generator writes.
static func index_regeneration_is_the_only_writer(t,derived: Dictionary, frozen: Dictionary) -> void:
 t.check(derived.generated_from==String(frozen.get("generated_from","")) and derived.digest==String(frozen.get("digest","")),"RUNNER index_regeneration_is_the_only_writer: digest and generated_from match the current inputs")

# iv: every registered suite has derived edges or a documented exemption (no island).
static func index_suites_are_all_reachable(t,derived: Dictionary) -> void:
 var exempt={}
 for entry in IndexEdges.SUITE_EXEMPT: exempt[String(entry.suite)]=true
 for kind in ["rule","ui"]:
  for name in derived.registries.get(kind,[]):
   var key=kind+":"+String(name)
   var reachable=derived.suite_files.has(key) and not derived.suite_files[key].is_empty()
   t.check(reachable or exempt.has(key),"RUNNER index_suites_are_all_reachable: "+key+" has derived edges or a documented exemption")

# v: no source file is silently unclassified: blind files carry a BLIND_BY_DESIGN reason,
# and no declaration is stale (both directions, so the reason list cannot rot).
static func index_skips_no_source_file(t,derived: Dictionary) -> void:
 var declared={}
 for entry in IndexEdges.BLIND_BY_DESIGN: declared[String(entry.path)]=true
 for path in derived.blind:
  t.check(declared.has(path),"RUNNER index_skips_no_source_file: "+path+" is blind and carries a BLIND_BY_DESIGN reason")
 for path in declared.keys():
  t.check(Array(derived.blind).has(path),"RUNNER index_skips_no_source_file: BLIND_BY_DESIGN entry is still blind: "+String(path))

# vi: every DOMAINS word is used by the corpus; every WIDEN impact area is registered.
static func index_declared_domains_exist(t,derived: Dictionary) -> void:
 for entry in IndexEdges.DOMAINS:
  for word in entry.domains:
   t.check(derived.domain_words.has(word) and derived.domain_words[word].size()>0,"RUNNER index_declared_domains_exist: DOMAINS word %s (%s) is used by the corpus" % [word,entry.path])
 for entry in IndexEdges.WIDEN:
  if not String(entry.add).begins_with("impact:"): continue
  var area=String(entry.add).trim_prefix("impact:")
  t.check(t.SUITES.has(area) or Selection.CROSS_AREAS.has(area) or area=="contact","RUNNER index_declared_domains_exist: WIDEN impact area is registered: "+area)

# vii: a closed defect keeps its added edge or domain (the gap list may only shrink).
static func index_defects_stay_closed(t,derived: Dictionary) -> void:
 var closed=true
 for entry in IndexEdges.INDEX_DEFECTS:
  closed=closed and String(entry.get("added",""))!="" and derived.domains.has(String(entry.path))
 t.check(closed,"RUNNER index_defects_stay_closed: every INDEX_DEFECTS entry still carries its added edge or domain")

# §6-G3, pinned to the measured derivation. These are the routing contract's examples, so a
# re-freeze that changes one of these shapes must update this judgement in the same commit.
# An unreadable or wrong-schema frozen index makes every plan unusable (suites_for returns an
# empty rows array), so report that state here and stop instead of indexing an empty plan: the
# failure stays a named judgement ERROR, never a runtime script error (tools/check-mutation.ps1
# reads a script error as "not a judgement RED").
static func index_route_examples_are_pinned(t) -> void:
 var frozen_failure=Index.frozen_error()
 t.check(frozen_failure=="","RUNNER index_route_examples_are_pinned: the frozen index is readable before the routing examples are pinned: "+frozen_failure)
 if frozen_failure!="": return
 var save=Index.suites_for(["spire-godot/core/save_store.gd"])
 t.check(save.ok and save.rules==["architecture","runner","persistence"],"RUNNER index_route_examples_are_pinned: save_store rule scope is architecture,runner,persistence")
 t.check(save.ui==["encyclopedia","home_persistence","home","interface","persistence"],"RUNNER index_route_examples_are_pinned: save_store UI scope is encyclopedia,home_persistence,home,interface,persistence")
 t.check(save.rows[0].signals.has("preload") and save.rows[0].signals.has("core-append"),"RUNNER index_route_examples_are_pinned: save_store records preload plus core-append")
 t.check(save.lines.any(func(line):return String(line).begins_with("ROUTE CORE APPEND: spire-godot/core/save_store.gd += architecture,persistence,runner")),"RUNNER index_route_examples_are_pinned: the plan prints the core append line for save_store")
 var ui_only=Index.suites_for(["spire-godot/ui/main.gd"])
 t.check(ui_only.ok and ui_only.rules==["architecture"] and ui_only.ui.size()>=40,"RUNNER index_route_examples_are_pinned: ui/main.gd routes the architecture rule suite and the UI modules")
 t.check(not ui_only.rules.has("normal_play") and not ui_only.ui.has("normal_play") and ui_only.milestone==["normal_play"],"RUNNER index_route_examples_are_pinned: a milestone edge is deducted and listed in the plan")
 var pack=Index.suites_for(["spire-godot/content/packs/abandoned_storeroom.json"])
 t.check(pack.ok and pack.rules==["installation_priority","event_flow","curses","encyclopedia","shop_release","content","events"] and pack.ui.is_empty() and pack.gates==["content"] and pack.default_files.has("spire-godot/content/packs/abandoned_storeroom.json"),"RUNNER index_route_examples_are_pinned: a content pack takes the closure, the content gate and no UI module")
 var owner=Index.suites_for(["spire-godot/tests/runner_cases.gd"])
 t.check(owner.ok and owner.rules==["runner"],"RUNNER index_route_examples_are_pinned: a case file routes to its owning suite")
 var domain=Index.suites_for(["spire-godot/core/snapshot.gd"])
 t.check(domain.ok and domain.rules==["architecture","runner","persistence"] and domain.rows[0].signals.has("domain"),"RUNNER index_route_examples_are_pinned: the SAVE domain resolves the blind snapshot file")
 var all_dev=Index.suites_for(["spire-godot/project.godot"])
 var blind=Index.suites_for(["spire-godot/core/tool_rules.gd"])
 t.check(blind.ok and blind.default_files.has("spire-godot/core/tool_rules.gd") and blind.rules==all_dev.rules and blind.ui.is_empty(),"RUNNER index_route_examples_are_pinned: a BLIND_BY_DESIGN file falls to the core closure with every rule suite and no UI module")
 t.check(not all_dev.ui.is_empty() and all_dev.ui==Index.suites_for(["spire-godot/newdir/x.gd"]).ui,"RUNNER index_route_examples_are_pinned: the module-root catch-all also selects all-dev-ui")
 var unmapped=Index.suites_for(["spire-godot/newdir/x.gd"])
 t.check(unmapped.ok and unmapped.unmapped.has("spire-godot/newdir/x.gd") and unmapped.rules==all_dev.rules and not unmapped.ui.is_empty() and not unmapped.rules.has("normal_play"),"RUNNER index_route_examples_are_pinned: an unknown directory is unmapped and fail-closed to all-dev plus all-dev-ui")
 var docs=Index.suites_for(["docs/spec/check-routing.md"])
 t.check(docs.ok and docs.rules.is_empty() and docs.ui.is_empty() and docs.declared_none==["docs/spec/check-routing.md"],"RUNNER index_route_examples_are_pinned: a declared-none document selects no suite and is never a pass")
 var outside=Index.suites_for(["outputs/build.zip"])
 t.check(not outside.ok and outside.error!="","RUNNER index_route_examples_are_pinned: a path outside spire-godot/ is refused")
 t.check(not Index.suites_for([]).ok,"RUNNER index_route_examples_are_pinned: an empty change set is refused instead of running nothing")
 t.check(Index.suites_for(["skills/repo-ops/SKILL.md"]).declared_none.size()==1,"RUNNER index_route_examples_are_pinned: operation-card edits are declared-none, not source")
 var iron=Index.suites_for(["spire-godot/core/iron_man.gd"])
 t.check(iron.rules==["architecture","runner","persistence","iron_man"] and iron.ui==["home"],"RUNNER index_route_examples_are_pinned: the IRON domain resolves core/iron_man.gd")
 t.check(Index.suites_for(["spire-godot/ui/art_inspection.gd"]).ui==["encyclopedia","display","hero_art","enemies"],"RUNNER index_route_examples_are_pinned: the ART domain resolves ui/art_inspection.gd")
 t.check(Index.suites_for(["spire-godot/ui/command_routes.gd"]).ui==["display"],"RUNNER index_route_examples_are_pinned: the DISPLAY domain resolves ui/command_routes.gd")
 t.check(Index.suites_for(["spire-godot/ui/first_turn_presenter.gd"]).ui==["card_power","status"],"RUNNER index_route_examples_are_pinned: the CONTROL domain resolves ui/first_turn_presenter.gd")
 t.check(Index.suites_for(["spire-godot/ui/run_review.gd"]).ui==["casting","route"],"RUNNER index_route_examples_are_pinned: the ROUTE domain resolves ui/run_review.gd")

static func _index_target_exists(target: String) -> bool:
 return FileAccess.file_exists("res://"+target.trim_prefix("spire-godot/"))
