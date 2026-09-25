extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Data=preload("res://data/room_events.gd")

# Arrival fixture chooses a real event room. All choices use versioned commands.
static func arrive(g, id: String) -> void:
 g._discard_end()
 var room=g.state.rooms.filter(func(r):return r.kind=="event")[0]
 room.event=id;room.name=g.Events.Data.TYPES[id].name
 g.state.room=room.id
 g.Events.start(g,id)

static func choose(t,g,id: String) -> Dictionary:
 return t.action(g,"event",{"action":"choose","choice":id})

# docs/spec/event-pipeline.md「证据入口」: the compiled registry entry is the
# single author form, and the projection keeps the same visible fields as the baseline.
static func event_definition_single_form(t) -> void:
 var g=Game.new(42)
 var declaration_keys=["allow_refuse","unavailable","relic_gate","random_freeze","outcome_draw","frozen_form","empty_node"]
 var visible_keys=["id","name","intro","stage","report","hint","selections","page_id","result_status"]
 t.check(Data.TYPES.size()==12,"EVENT DEFINITION twelve authored events compile into the single node form")
 var single_count=0
 var multi_count=0
 for id in Data.TYPES.keys():
  var spec=Data.TYPES[id]
  t.check(spec.has("start_node") and spec.nodes is Array and not spec.nodes.is_empty(),"EVENT DEFINITION definition exposes start_node and nodes "+id)
  for legacy in ["choices","stages","start_stage","allow_refuse"]:
   t.check(not spec.has(legacy),"EVENT DEFINITION definition drops the legacy key "+legacy+" "+id)
  var nodes=spec.nodes
  if nodes.size()==1: single_count+=1
  else: multi_count+=1
  for entry in nodes:
   t.check(declaration_keys.all(func(key):return entry.has(key)),"EVENT DEFINITION every node declares the full policy set "+id+"/"+str(entry.get("id","")))
   t.check(entry.choices is Array and not entry.choices.is_empty() and entry.choices.size()<=6,"EVENT DEFINITION node keeps1—6 options "+id+"/"+str(entry.get("id","")))
   if nodes.size()==1:
    t.check(entry.id=="choice" and not entry.has("title") and not entry.has("intro"),"EVENT DEFINITION single node uses the sentinel id without stage copy "+id)
   else:
    t.check(entry.id not in ["choice","reward","result","battle","loot","keys"] and entry.has("title") and entry.has("intro"),"EVENT DEFINITION staged node keeps its id and stage copy "+id+"/"+str(entry.get("id","")))
  var view={}
  var walk=Game.new(42)
  arrive(walk,id)
  view=walk.get_view().room_event
  t.check(view.keys().all(func(key):return key in visible_keys) and visible_keys.all(func(key):return view.has(key)),"EVENT DEFINITION projection keeps the frozen visible fields "+id)
  t.check(view.id==id and view.stage==walk.state.room_event.stage and view.name.contains(spec.name),"EVENT DEFINITION projection identity matches the entered definition "+id)
  t.check(view.intro==spec.intro or walk.state.room_event.get("flow",false),"EVENT DEFINITION single-node introduction stays byte-identical "+id)
 t.check(single_count==8 and multi_count==4,"EVENT DEFINITION eight single-node and four multi-node events registered")

# docs/spec/event-pipeline.md「证据入口」: every authored option of
# the entered node leaves a trace row, decisions stay inside the four values, every dropped or
# hidden row carries one of the named gates, a selector keeps the authored source choice apart
# from the frozen instance id, an empty selector still reports selector_empty without entering
# the frozen options, a state condition hits the same row in both purposes (a missing twin is a
# failure), and each node/probe gate of this batch has one real trigger. Rows are matched by the
# A25 filter tuple (purpose, source_choice, option_id, gate|kind, index), never by a total row
# count; the switch stays debug-only and changes nothing.
# The probe fixtures call probe_result from inside an entered event: probe_result reads
# room_event.refs, exactly as probe did before B3, so a game that never entered an event has no
# refs key to duplicate (minimal repro: build/b3-trace-20260916/repro_validate.gd --case=fresh_probe).
static func event_gate_names_are_total(t) -> void:
 var catalog=preload("res://core/content_catalog.gd")
 var decisions=["generated","dropped","hidden","disabled"]
 var named=["condition_unmet","availability_unmet","relic_pool_empty","relic_already_offered","selector_empty","recipe_empty","freeze_failed","probe_failed","encounter_invalid","validate_failed","node_empty","chain_loop"]
 var identity=["event","source_choice","option_id","decision","gate","kind","mode","index","reason"]
 var g=Game.new(42)
 var baseline=catalog.tables(g)
 var kinds=g.Events.condition_kinds()
 for id in Data.TYPES.keys():
  var on=Game.new(42)
  on.set_meta("event_trace_enabled",true)
  arrive(on,id)
  var spec=on.Events.definition(id)
  var start_node=on.Events.node(spec,spec.start_node)
  var arrival=on.Events.event_trace(on).filter(func(row):return row.purpose=="arrival")
  for row in arrival:
   t.check(not str(row.source_choice).contains("__"),"EVENT GATE the source choice stays the authored id without the instance suffix: "+id+"/"+str(row.source_choice))
   if str(row.option_id).contains("__"):
    t.check(str(row.option_id).begins_with(str(row.source_choice)+"__"),"EVENT GATE a selector row names the frozen instance it evaluated: "+id+"/"+str(row.option_id))
   else:
    t.check(str(row.option_id)==str(row.source_choice),"EVENT GATE an unexpanded option keeps one id in both fields: "+id+"/"+str(row.option_id))
  var frozen=on.state.room_event.options.map(func(option):return str(option.get("id","")))
  for choice in start_node.choices:
   var cid=str(choice.id)
   var choice_rows=arrival.filter(func(row):return row.source_choice==cid)
   t.check(not choice_rows.is_empty(),"EVENT GATE every authored option of the entered node has at least one trace row: "+id+"/"+cid)
   var instances=frozen.filter(func(frozen_id):return frozen_id.begins_with(cid+"__"))
   if not instances.is_empty():
    for instance in instances:
     t.check(choice_rows.filter(func(row):return row.option_id==instance).size()==1,"EVENT GATE every frozen instance has exactly one arrival row: "+id+"/"+instance)
    t.check(choice_rows.all(func(row):return str(row.option_id) in instances),"EVENT GATE an expanded selector option never keeps the authored id: "+id+"/"+cid)
   elif frozen.has(cid):
    t.check(choice_rows.size()==1 and str(choice_rows[0].option_id)==cid,"EVENT GATE a plain frozen option has exactly one arrival row: "+id+"/"+cid)
  var facts=on.command_facts()
  var choices=facts.filter(func(candidate):return candidate.payload.get("kind","")=="event" and candidate.payload.get("action","")=="choose").map(func(candidate):return str(candidate.payload.choice))
  for choice in start_node.choices:
   var cid=str(choice.id)
   if frozen.has(cid):
    t.check(choices.has(cid),"EVENT GATE a frozen option is the candidate payload choice: "+id+"/"+cid)
   var instances=frozen.filter(func(frozen_id):return frozen_id.begins_with(cid+"__"))
   if not instances.is_empty():
    var candidate_ids=choices.filter(func(choice_id):return choice_id.begins_with(cid+"__"))
    t.check(candidate_ids.size()==instances.size() and instances.all(func(instance):return candidate_ids.has(instance)),"EVENT GATE the frozen instance ids equal the candidate payload choices: "+id+"/"+cid)
  var all=on.Events.event_trace(on)
  for row in all:
   t.check(row.decision in decisions,"EVENT GATE every trace row stays inside the four decisions: "+id+"/"+str(row.purpose)+"/"+str(row.source_choice)+"/"+str(row.decision))
   if row.decision in ["dropped","hidden"]:
    t.check(str(row.gate) in named,"EVENT GATE every dropped or hidden row carries a named gate from the contract list: "+id+"/"+str(row.source_choice)+"/"+str(row.gate))
  # One evaluation writes one row per hit: the arrival entry, then one candidate evaluation
  # per frozen option. A next-node probe is its own evaluation and appends its own rows, so
  # the arrival set is the rows of the arrival entry only (A25: rows accumulate, never count).
  var seen={}
  for row in arrival:
   var key="%s|%s|%s|%s|%d" % [str(row.source_choice),str(row.option_id),str(row.gate),str(row.kind),int(row.index)]
   t.check(not seen.has(key),"EVENT GATE the arrival entry writes one row per gate hit: "+id+"/"+key)
   seen[key]=true
  seen={}
  for row in all.filter(func(other):return other.purpose=="candidate"):
   var key="%s|%s|%s|%s|%d" % [str(row.node),str(row.option_id),str(row.gate),str(row.kind),int(row.index)]
   t.check(not seen.has(key),"EVENT GATE each candidate evaluation writes one row per gate hit: "+id+"/"+key)
   seen[key]=true
  var candidate_rows=all.filter(func(row):return row.purpose=="candidate")
  for row in all.filter(func(other):return other.purpose=="arrival" and kinds.has(other.kind) and not frozen.has(str(other.option_id))):
   t.check(row.decision in ["dropped","hidden"],"EVENT GATE a state condition row without a candidate twin belongs to an option the arrival dropped: "+id+"/"+str(row.option_id)+"/"+str(row.decision))
  for row in all.filter(func(other):return other.purpose=="arrival" and kinds.has(other.kind) and frozen.has(str(other.option_id))):
   var twins=candidate_rows.filter(func(other):return other.option_id==row.option_id and other.gate==row.gate and other.kind==row.kind and other.index==row.index)
   t.check(twins.size()==1,"EVENT GATE a surviving state condition row appears once in the candidate evaluation (a missing row is a failure): "+id+"/"+str(row.option_id)+"/"+str(row.gate))
   if twins.size()==1:
    for field in identity:
     t.check(twins[0][field]==row[field],"EVENT GATE the state condition row keeps "+field+" across purposes: "+id+"/"+str(row.option_id))
    if spec.nodes.size()==1:
     t.check(str(twins[0].node)==str(row.node),"EVENT GATE a single-node state condition row keeps its node label: "+id+"/"+str(row.option_id))
  for row in candidate_rows.filter(func(other):return kinds.has(other.kind) and frozen.has(str(other.option_id))):
   t.check(all.any(func(other):return other.purpose=="arrival" and other.option_id==row.option_id and other.gate==row.gate and other.index==row.index),"EVENT GATE every candidate state condition row keeps its arrival twin: "+id+"/"+str(row.option_id))
  var off=Game.new(42)
  arrive(off,id)
  var off_facts=off.command_facts()
  t.check(JSON.stringify(off.state.room_event.options)==JSON.stringify(on.state.room_event.options) and JSON.stringify(off_facts)==JSON.stringify(facts),"EVENT GATE the switch changes no frozen option or candidate: "+id)
  t.check(JSON.stringify(off.state.rng)==JSON.stringify(on.state.rng) and JSON.stringify(off.get_view())==JSON.stringify(on.get_view()),"EVENT GATE the switch changes no random domain or view: "+id)
  t.check(not off.Events.trace_enabled(off) and off.Events.event_trace(off).is_empty(),"EVENT GATE the switch off records nothing: "+id)
 # selector_empty: a real authored selector that expands to nothing keeps its gate and no option
 var studio=Game.new(42)
 studio.set_meta("event_trace_enabled",true)
 arrive(studio,"enchanters_empty_studio")
 var studio_rows=studio.Events.event_trace(studio).filter(func(row):return row.source_choice=="temper")
 t.check(studio_rows.size()==1 and str(studio_rows[0].gate)=="selector_empty" and str(studio_rows[0].kind)=="selector" and studio_rows[0].decision=="dropped" and str(studio_rows[0].option_id)=="temper","EVENT GATE an empty selector records selector_empty once without an instance: "+JSON.stringify(studio_rows))
 t.check(not studio.state.room_event.options.any(func(option):return str(option.get("id",""))=="temper") and not studio.command_facts().any(func(candidate):return str(candidate.payload.get("choice","")).begins_with("temper__")),"EVENT GATE an empty selector enters no frozen and no candidate option")
 # stage_missing: the node pipeline names an unknown target node and keeps the current stage
 var missing_result=studio.Events.enter_node_result(studio,"missing")
 t.check(missing_result.gate=="stage_missing" and str(missing_result.detail)=="missing" and missing_result.issue=="下一阶段不存在。","EVENT GATE an unknown node reports stage_missing with its id and its current wording: "+JSON.stringify(missing_result))
 t.check(studio.state.room_event.stage=="choice","EVENT GATE an unknown node leaves the entered stage unchanged")
 # node_empty: the staged fixture closes the only option of its last node
 var staged_document=preload("res://tests/event_flow_cases.gd").document()
 staged_document.data.id="gate_names_staged"
 for choice in staged_document.data.nodes[2].choices: choice.when={"counter":"seen","equals":1}
 var staged_compile=catalog.compile(g,[staged_document])
 t.check(staged_compile.ok,"EVENT GATE the staged fixture compiles: "+str(staged_compile.errors))
 if staged_compile.ok:
  catalog.commit(g,staged_compile.tables)
  var staged=Game.new(42)
  staged.set_meta("event_trace_enabled",true)
  arrive(staged,"gate_names_staged")
  var node_result=staged.Events.enter_node_result(staged,"finale")
  var empty_rows=staged.Events.event_trace(staged).filter(func(row):return str(row.gate)=="node_empty")
  t.check(node_result.gate=="node_empty" and str(node_result.detail)=="finale" and node_result.issue=="这一阶段没有能够执行的选项。","EVENT GATE an empty node reports node_empty with its id and its current wording: "+JSON.stringify(node_result))
  t.check(empty_rows.size()==1 and str(empty_rows[0].node)=="finale" and str(empty_rows[0].option_id)=="" and str(empty_rows[0].source_choice)=="" and empty_rows[0].decision=="dropped","EVENT GATE the node entry failure row carries its gate, its target node and no option: "+JSON.stringify(empty_rows))
  t.check(staged.state.room_event.stage=="entry","EVENT GATE a failed node entry leaves the entered stage unchanged")
  catalog.commit(g,baseline)
 # probe_failed and validate_failed: the real probe names its own stage
 var probe=Game.new(42)
 arrive(probe,"binding_cleric")
 var probe_before=probe.export_snapshot()
 var probe_hit=probe.Events.probe_result(probe,[{"op":"mana_loss","amount":99999}],{})
 t.check(probe_hit.gate=="probe_failed" and str(probe_hit.reason)!="","EVENT GATE an unpayable effect probe reports probe_failed: "+JSON.stringify(probe_hit))
 t.check(probe.export_snapshot()==probe_before,"EVENT GATE the effect probe restores the duplicated state")
 var invalid=Game.new(42)
 arrive(invalid,"binding_cleric")
 invalid.state.room_event.values={"seen":-1}
 var invalid_hit=invalid.Events.probe_result(invalid,[],{})
 t.check(invalid_hit.gate=="validate_failed" and str(invalid_hit.reason)!="","EVENT GATE a state that fails the game validator reports validate_failed: "+JSON.stringify(invalid_hit))
 t.check(invalid.state.room_event.values=={"seen":-1},"EVENT GATE the validation probe restores the duplicated state")
 # held_pending: a real held instance is only a cleanup-probe gate
 var held=Game.new(42)
 held.set_meta("event_trace_enabled",true)
 held._install_special("shaft_ring_low","special_2_a")
 arrive(held,"binding_cleric")
 t.check(held.Events.apply_effects(held,[{"op":"hold_special","key":"pending","slots":["special_2_a"]}],held.state.room_event.refs,false)=="","EVENT GATE the hold fixture leaves a held instance")
 t.check(not held.state.room_event.held.is_empty(),"EVENT GATE the hold fixture records the instance under its key")
 t.check(held.Events.probe_result(held,[],{},true).gate=="held_pending","EVENT GATE an unreleased hold reports held_pending on the cleanup probe")
 var held_plain=held.Events.probe_result(held,[],{})
 t.check(held_plain.gate=="","EVENT GATE the same state passes the ordinary probe: "+JSON.stringify(held_plain))
 # state condition rows across purposes: one optional hit survives arrival, so its candidate row
 # must exist and stay field-identical (the twin check on a short single-node fixture)
 var stacked={"file":"memory://gate_names.json","data":{"schema_version":2,"kind":"event","id":"gate_names_stacked","name":"gate 夹具","intro":"只用于验证具名 gate 的夹具。","start_node":"choice","nodes":[{"id":"choice","allow_refuse":false,"unavailable":"disable","relic_gate":"pool","random_freeze":"generators","outcome_draw":"option","frozen_form":"in_place","empty_node":"allow","choices":[{"id":"stacked","label":"叠加条件","reward":"none","next":"result","detail":"条件决定是否可选。","effects":[{"op":"mana_gain","amount":2}],"conditions":[{"kind":"has_relic","type":"softened_buckle","reason":"条件甲。","mode":"optional"}]}]}]}}
 var stacked_compile=catalog.compile(g,[stacked])
 t.check(stacked_compile.ok,"EVENT GATE the stacked fixture compiles: "+str(stacked_compile.errors))
 if stacked_compile.ok:
  catalog.commit(g,stacked_compile.tables)
  var walk=Game.new(42)
  walk.set_meta("event_trace_enabled",true)
  arrive(walk,"gate_names_stacked")
  var hits=walk.Events.event_trace(walk).filter(func(row):return row.purpose=="arrival" and row.source_choice=="stacked" and row.gate=="availability_unmet")
  walk.command_facts()
  var twins=walk.Events.event_trace(walk).filter(func(row):return row.purpose=="candidate" and row.source_choice=="stacked" and row.gate=="availability_unmet")
  t.check(hits.size()==1 and hits[0].decision=="disabled" and str(hits[0].mode)=="optional" and str(hits[0].reason)=="条件甲。","EVENT GATE an optional state condition is traced once at arrival: "+JSON.stringify(walk.Events.event_trace(walk)))
  t.check(twins.size()==1,"EVENT GATE the optional state condition row is not missing in the candidate evaluation: "+JSON.stringify(walk.Events.event_trace(walk)))
  if hits.size()==1 and twins.size()==1:
   for field in identity:
    t.check(twins[0][field]==hits[0][field],"EVENT GATE the optional state condition row keeps "+field+" across purposes")
  catalog.commit(g,baseline)

static func run(t) -> void:
 preload("res://tests/event_draw_cases.gd").run(t)
 event_definition_single_form(t)
 var g=Game.new(42)
 # Content registrations fail here rather than silently choosing another behavior.
 for id in g.Enemies.TYPES:
  var spec=g.Enemies.TYPES[id]
  t.check(spec.hp>0 and spec.behavior in ["restraint","dispenser","attachment","lock","guard","humanoid","sequence","six_bind","binding_box","drone","puppeteer","puppet","iron_man","iron_drone"] and spec.visual in ["rope","belt","tape","cable_tie","toybox","silencer","lock","guard","rope_mass","rope_heap","belt_mass","belt_heap","trader","versatile","mixed_bundle","rope_serpent","ominous_circle","six_bind","binding_box","drone","puppeteer","puppet","iron_man"],"CONTENT enemy behavior and visual registered "+id)
  if spec.has("special_pool"): t.check(not spec.special_pool.is_empty() and spec.special_pool.all(func(type):return g.SpecialEquipment.DESIGNS.has(type)),"CONTENT enemy special pool resolves "+id)
  if spec.behavior=="attachment": t.check(spec.attachment_slot in ["eyes","mouth"] and spec.attachment_pool.all(func(template):return spec.attachment_slot in g.Equipment.TEMPLATES[template].slots),"CONTENT attachment pool matches declared body region "+id)
  for field in ["install_pool","final_pool","attachment_pool"]:
   if spec.has(field): t.check(not spec[field].is_empty() and spec[field].all(func(template):return g.Equipment.TEMPLATES.has(template)),"CONTENT enemy equipment pools resolve "+id+field)
 for configuration in g.Composites.GENERATION:
  t.check(not g.Composites.spec(configuration[0],configuration[1],configuration[2]).is_empty(),"CONTENT composite generation uses defined structures")
 for encounter in g.Enemies.ENCOUNTERS.values():
  t.check(encounter.members.all(func(m):return g.Enemies.TYPES.has(m.type) and m.grade in [1,2,3]),"CONTENT encounters use real templates and grades")
 for pool in g.Enemies.FirstFloor.POOLS.values(): t.check(pool.all(func(id):return g.Enemies.ENCOUNTERS.has(id)),"CONTENT encounter pool references resolve")
 for spec in Data.TYPES.values():
  if spec.nodes.size()==1:
   var choices=spec.nodes[0].choices
   t.check(spec.start_node=="choice" and choices.all(func(c):return (c.has("effects") or c.get("recipe","") in ["free_basic","tighten_or_medium","locked_assembly"]) and c.reward in ["none","common","uncommon","rare","relic"]),"CONTENT single-node event recipes, effects and rewards registered")
  else:
   t.check(spec.nodes.size()>=2,"CONTENT multi-node event definitions remain registered")
 for pool in Data.CARD_POOLS.values(): t.check(pool.size()>=3 and pool.all(func(id):return g.B.CARD_NAMES.has(id)),"CONTENT event card rewards are playable definitions")
 t.check(Data.CARD_POOLS.common==g.Cards.Rules.COMMON and Data.CARD_POOLS.uncommon==g.Cards.Rules.UNCOMMON and Data.CARD_POOLS.rare==g.Cards.Rules.RARE,"CONTENT event card pools match the three visible rarities")
 t.check(g.Events.reward_text("common").contains("普通牌") and g.Events.reward_text("uncommon").contains("罕见牌") and g.Events.reward_text("rare").contains("稀有牌"),"CONTENT event reward copy names each real rarity")
 for spec in g.Relics.TYPES.values(): t.check(spec.modifiers.keys().all(func(h):return h in g.Relics.MODIFIER_LIMITS),"CONTENT relic hooks registered")

 var active=Data.pool()
 t.check(active.has("binding_cleric") and active.has("succubus_three_games") and active.has("succubus_magic_pawnshop") and active.has("enchanters_empty_studio") and active.has("smuggled_mana_potions") and active.has("floating_belt_cluster") and active.has("alchemist_tasting_stall") and active.has("abandoned_storeroom") and active.has("bound_dream_guest_room") and active.has("mysterious_woman_statue") and active.has("maze_survey_team"),"EVENT current authored events remain in the normal pool")
 for seed_value in range(12):
  g=Game.new(seed_value)
  t.check(g.state.rooms.filter(func(r):return r.kind=="event").all(func(r):return not r.has("event")) and g.state.event_seen.is_empty(),"EVENT generating rooms does not draw or consume event identities")
  var domain=g.state.rng.duplicate(true)
  arrive(g,"binding_cleric")
  var before=JSON.stringify(g.state)
  var view=g.get_view()
  g.command_facts();g.route_view();g.EquipmentOffers.options(g)
  t.check(JSON.stringify(g.state)==before,"EVENT offers, projection and equipment probes do not mutate")
  t.check(g.state.rng.deck==domain.deck and g.state.rng.enemy==domain.enemy and g.state.rng.equipment==domain.equipment,"EVENT random domain remains independent of deck, enemies and equipment")
  t.check(view.room_event.id=="binding_cleric" and g.state.room_event.options.size()==3,"EVENT current authored event exposes its frozen legal choices")

 # A late effect failure rolls back earlier effects, ids, logs and resources.
 g=Game.new(3);arrive(g,"binding_cleric")
 var restore=g.state.room_event.options.filter(func(option):return option.id=="restore")[0]
 var original=restore.effects.duplicate(true)
 restore.effects.append({"op":"unsupported"})
 var rejected=g.export_snapshot()
 t.check(not choose(t,g,"restore").ok and g.export_snapshot()==rejected,"EVENT unsupported late effect rejects the whole transaction")
 restore.effects=original
 var mana_before=g.state.mana
 t.check(choose(t,g,"restore").ok and g.state.mana>=mana_before and g.state.equipment.size()==2,"EVENT valid current choice commits its frozen batch")

 g=Game.new(5);g._gain_card("panic")
 var curse=g.state.discard.pop_back();g.state.hand.append(curse)
 t.check(t.action(g,"card",{"uid":curse.uid}).ok,"EVENT granted panic still plays through the normal candidate")
 t.check(g.state.exhaust.any(func(c):return c.uid==curse.uid) and g.state.deck.size()==11,"EVENT played panic exhausts without permanent deletion")
 g._reset_piles()
 t.check(g.state.exhaust.is_empty() and g.state.draw.any(func(c):return c.uid==curse.uid),"EVENT curse restores next battle")

 g=Game.new(6);g._gain_tool("picks");var tool=g.state.items[0]
 var target=g.add_fixture("thigh",8,10,true)
 var durability=target.durability;var energy=g.state.energy
 t.check(t.action(g,"item_use",{"item":tool.id,"target":target.id}).ok and not g._equipment(target.id).locked and g._equipment(target.id).durability==durability and g.state.energy==energy and g._item(tool.id).uses==1,"EVENT existing picks remain a normal zero-cost unlocking tool")
 t.check(not t.action(g,"item_install",{"item":tool.id}).ok,"EVENT picks cannot install as a cutting tool")
 event_gate_names_are_total(t)
