extends RefCounted
const Data=preload("res://data/room_events.gd")
const Relics=preload("res://data/relics.gd")
const RESULT_STATUSES=["neutral","success","failure"]
# §3.3: the player-visible reason of the chain-loop gate, declared once.
const CHAIN_LOOP_REASON="这段事件已经走过，不能再回头。"

# Internal phase helper, called only through Game.dispatch. Choices contain frozen
# effects, not functions or localized identifiers. Probes always restore state.
static func start(g, id: String="") -> void:
 var room=g.room_data(g.state.room)
 if not g.state.practice:
  if id=="":
   if room.has("event"): id=room.event
   else:
    var pool=Data.pool().filter(func(type):return type not in g.state.event_seen)
    if not pool.is_empty(): id=pool[g._random_index("event",pool.size())]
  room.event=id
  room.name="%02d · %s" % [room.floor+1,Data.TYPES[id].name if id!="" else "空房间"]
  if id!="" and id not in g.state.event_seen: g.state.event_seen.append(id)
 if id=="":
  g._apply_transition("event_leave_empty",{"phase":"map"});g.state.wall=room.wall;g.state.energy=0
  g.state.enemies=[];g.state.room_event={}
  if g.state.room not in g.state.completed_rooms: g.state.completed_rooms.append(g.state.room)
  g._emit("event","房间里没有新的发现，可以继续前进。")
  return
 clear_trace(g)
 g._apply_transition("event_enter",{"phase":"event"})
 g.state.wall=g.room_data(g.state.room).wall
 g.state.enemies=[]
 g.state.energy=0
 var spec=definition(id)
 # One definition form: a single node keeps the in-place layout, several nodes keep the
 # staged layout. B2 replaces this node-count branch with the declared node policies.
 var flow=node_ids(spec).size()>1
 var event={"id":id,"stage":"choice","options":[],"refs":{},"values":{},"report":"","reward":[],"winner":-1,"relic":offer_relic(g,spec),"flow":flow,"held":{},"cleanup_effects":spec.get("cleanup_effects",[]).duplicate(true),"next_stage":""}
 g.state.room_event=event
 event.result_status="neutral"
 var issue=enter_node(g,spec.get("start_node",""))
 if issue!="":
  event.stage="result";event.report="事件无法开始："+issue
  event.result_status="failure"
 g._emit("event","进入"+Data.TYPES[id].name+"。")

# §3.3 (A32): the relic an instance may grant belongs to the definition that owns the instance,
# so an arrival and a chain jump compute it the same way: a definition whose options offer a
# relic reward with a non-empty pool spends exactly one draw, every other definition stays
# empty. Recomputing after a jump is what keeps the target from naming the source's relic.
static func offer_relic(g, spec: Dictionary) -> String:
 var choices=[]
 for author_node in spec.get("nodes",[]): choices.append_array(author_node.get("choices",[]))
 var offers_relic=choices.any(func(choice):return choice.get("reward","")=="relic" or choice.get("outcomes",[]).any(func(outcome):return outcome.get("reward","")=="relic"))
 if not offers_relic or g.RelicRewards.available(g).is_empty(): return ""
 return g.RelicRewards.offer(g)

static func refusal(g) -> Dictionary:
 return {"id":"refuse","label":"支付费用，离开","reward":"none","effects":[{"op":"mana_loss","amount":minf(g.state.mana,Data.REFUSAL_MANA)}],"detail":"支付%s魔力。" % g.number(minf(g.state.mana,Data.REFUSAL_MANA)),"next":"result","report":"你转身离开。"}

# The compiled registry entry is the author form, so these three accessors are the only
# way to reach nodes and their options; a missing id yields an empty result, not an error.
static func definition(id: String) -> Dictionary:
 return Data.TYPES.get(id,{})

static func node(spec: Dictionary, node_id: String) -> Dictionary:
 for entry in spec.get("nodes",[]):
  if entry.get("id","")==node_id: return entry
 return {}

static func node_ids(spec: Dictionary) -> Array:
 var ids=[]
 for entry in spec.get("nodes",[]): ids.append(entry.get("id",""))
 return ids

# §3.2: the single interpreter of a declared next target: the "result" sentinel that ends the
# event (also the missing value), another node of this definition, or {"event","node"} — a
# jump to another registered event. Callers never read the authored shape themselves.
static func next_target(next) -> Dictionary:
 if next is Dictionary: return {"kind":"event","event":str(next.get("event","")),"node":str(next.get("node",""))}
 if next is String and next!="result": return {"kind":"node","node":next,"event":""}
 return {"kind":"result","node":"","event":""}

# §3.3: the chain cleanup is the union of every cleanup step of the chain, one entry per key,
# source definition first. Leaving runs each step once, so a key must never repeat.
static func chain_cleanup(current: Array, target: Array) -> Array:
 var result=current.duplicate(true)
 for entry in target:
  if result.any(func(other):return str(other.get("key",""))==str(entry.get("key",""))): continue
  result.append(entry.duplicate(true))
 return result

# §3.2／§3.3: the single advance entry for a resolved target; a node target reuses the node
# pipeline, an event target rewrites this instance into the chain first. "arrival" is the
# real advance, "next_probe" is the caller-owned look-ahead of probe_result (A31).
static func enter_target(g, target: Dictionary, purpose: String="arrival") -> Dictionary:
 if target.get("kind","")=="event": return _enter_chain(g,target,purpose)
 # A "result" target ends the event and owns no node: the caller sets the result stage.
 if target.get("kind","")=="result": return {"issue":"","gate":"","detail":""}
 return enter_node_result(g,str(target.get("node","")),purpose)

# A real cross-event jump keeps one instance (§3.3): the target becomes the current
# definition, counters and holds continue, cleanup becomes the chain union, the relic is
# recomputed from the target definition (A32), event_seen gains the target, the flow mirror
# follows the new definition, and chain records the events already left behind — the key
# appears only here, never on arrival.
static func _enter_chain(g, target: Dictionary, purpose: String) -> Dictionary:
 var event=g.state.room_event
 var spec=definition(target.event)
 if not target.event in g.state.event_seen: g.state.event_seen.append(target.event)
 var chain=event.get("chain",[])
 if not chain is Array: chain=[]
 var left=chain.duplicate()
 left.append(str(event.get("id","")))
 event.chain=left
 event.id=target.event
 event.relic=offer_relic(g,spec)
 event.cleanup_effects=chain_cleanup(event.get("cleanup_effects",[]),spec.get("cleanup_effects",[]))
 event.flow=node_ids(spec).size()>1
 return enter_node_result(g,target.node,purpose)

# One declaration for every state condition. Adding a condition means adding one row here:
# content validation, runtime evaluation, the save key set and the trace naming all derive
# from it, so the three consumers can never drift apart again.
# required/optional list the author fields; check(g, entry, data) validates one entry;
# probe(g, entry) reports whether the entry is HIT (unsatisfied) for the current game.
static var CONDITIONS={
 "no_chastity_lock":{
  "required":[],
  "optional":[],
  "check":func(_g,_entry,_data):return "",
  "probe":func(g,_entry):return g.state.special_equipment.any(func(item):return item.get("durability",0)>0 and g.SpecialEquipment.is_chastity(item))},
 "has_relic":{
  "required":["type"],
  "optional":[],
  "check":func(_g,entry,data):
   if not entry.get("type") is String or not data.relic.has(entry.type): return "has_relic 需要已注册的遗物 id。"
   return "",
  "probe":func(g,entry):return not g.state.relics.has(String(entry.get("type","")))},
}

static func condition_kinds() -> Array:
 return CONDITIONS.keys()

# The save key set of an entry: the kind, its reason and every declared kind field.
static func condition_saved_fields(kind: String) -> Array:
 var spec=CONDITIONS.get(kind,{})
 return ["kind","reason"]+Array(spec.get("required",[]))

# Author spelling plus node policy become canonical entries in declaration order.
# Only state conditions live here; instance conditions (when), the relic gate and the
# feasibility probe stay at their fixed evaluation steps (§4.3).
static func condition_entries(node: Dictionary, choice: Dictionary) -> Array:
 var entries=[]
 var declared=choice.get("conditions",[])
 if declared is Array and not declared.is_empty():
  for entry in declared:
   if not entry is Dictionary: continue
   var canonical={"kind":entry.get("kind",""),"mode":entry.get("mode","")}
   canonical.reason=entry.get("reason","")
   for field in Array(CONDITIONS.get(entry.get("kind",""),{}).get("required",[])):
    if entry.has(field): canonical[field]=entry[field]
   if canonical.mode=="": canonical.mode="optional"
   entries.append(canonical)
  return entries
 if choice.has("availability"):
  var availability=choice.availability
  var canonical={"kind":"","mode":"","reason":""}
  if availability is Dictionary:
   canonical.kind=availability.get("kind","")
   canonical.reason=availability.get("reason","")
   for field in Array(CONDITIONS.get(canonical.kind,{}).get("required",[])):
    if availability.has(field): canonical[field]=availability[field]
  canonical.mode=_state_mode(node,choice)
  entries.append(canonical)
 return entries

# Mode resolution for a compatibility state condition (§5.3 priority 2 and 3).
static func _state_mode(node: Dictionary, choice: Dictionary) -> String:
 if choice.get("unavailable","")=="hide": return "hidden"
 if choice.get("unavailable","")=="disable": return "optional"
 if choice.get("hide_when_unavailable",false): return "hidden"
 return "optional"

# One entry, validated against its own declared kind. Messages stay those the author
# already sees for the compatibility spelling.
static func condition_issue(g, entry: Dictionary, data: Dictionary) -> String:
 if not entry is Dictionary: return "需要条件对象。"
 var spec=CONDITIONS.get(entry.get("kind",""),{})
 if spec.is_empty(): return "尚未支持这种状态条件。"
 var allowed=Array(spec.get("required",[]))+Array(spec.get("optional",[]))
 for key in entry:
  if key in ["kind","reason","mode"]: continue
  if key not in allowed: return "不支持字段 "+str(key)+"。"
 for key in Array(spec.get("required",[])):
  if not entry.has(key): return "缺少字段 "+key+"。"
 var mode=entry.get("mode","optional")
 if mode not in ["optional","hidden"]: return "条件模式只支持 optional 或 hidden。"
 if not words_like_reason(entry.get("reason","")): return "reason 需要1—240字的普通说明。"
 return spec.check.call(g,entry,data)

# The author-facing reason text keeps the same length and format rules as before.
static func words_like_reason(value) -> bool:
 return value is String and not value.strip_edges().is_empty() and value.length()<=240 and not "[" in value and not "]" in value

static func condition_probe(g, entry: Dictionary) -> bool:
 var spec=CONDITIONS.get(entry.get("kind",""),{})
 if spec.is_empty(): return false
 return spec.probe.call(g,entry)

# The single evaluation entry: every "what can this option do right now" question goes
# through here, and every hit is recorded as its own gate entry in evaluation order.
# request={"definition","node","choice","selected","purpose","outcome"?,"frozen"?}
#   selected=<empty|Dictionary|Array>, purpose=arrival|candidate|probe|execute
#   outcome=<pre-drawn weighted result>; only the caller that owns one draw per choice
#   passes it, so outcome_draw=="option" stays one draw for the whole choice.
#   frozen=<the already frozen option> for candidate／probe／execute, which never re-freeze
#   and never consume random.
# Returns {"decision","gates","gate","reason","option"}; read-only for every purpose except
# arrival, which returns the option the node pipeline writes into the state.
static func evaluate_option(g, request: Dictionary) -> Dictionary:
 var node_entry=request.get("node",{})
 var choice=request.get("choice",{})
 var purpose=request.get("purpose","candidate")
 var selected=request.get("selected",{})
 var outcome=request.get("outcome",{})
 var gates=[]
 # 0) instance conditions (when) — declared mode is hidden
 if choice.has("when") and not condition_met(g,choice.when):
  var detail=str(choice.when.get("counter","")) if choice.when.has("counter") else str(choice.when.get("selector",{}).get("kind",""))
  gates.append({"gate":"condition_unmet","kind":"selector_count" if choice.when.has("selector") else "counter","mode":"hidden","index":0,"detail":detail,"reason":""})
 # 1) relic pool gate, before freezing (the node declares relic_gate="pool")
 if not _structural(gates) and node_entry.get("relic_gate","")=="pool" and choice.get("reward","")=="relic" and g.RelicRewards.available(g).is_empty():
  gates.append({"gate":"relic_pool_empty","kind":"relic_pool","mode":"hidden","index":0,"detail":"","reason":""})
 var options=[]
 if not _structural(gates):
  if purpose=="arrival":
   var selections=selections_for(g,choice,selected)
   if selections.is_empty():
    gates.append({"gate":"selector_empty","kind":"selector","mode":"hidden","index":0,"detail":str(choice.get("selector",{}).get("kind","")),"reason":""})
   else:
    for selection in selections:
     var frozen=freeze_one(g,node_entry,choice,selection,outcome)
     if not frozen.ok:
      gates.append({"gate":frozen.gate,"kind":"feasibility","mode":"hidden","index":0,"detail":str(choice.get("id","")),"reason":frozen.reason})
     elif node_entry.get("relic_gate","")=="claimed" and frozen.option.reward=="relic" and g.state.room_event.get("relic","")=="":
      gates.append({"gate":"relic_already_offered","kind":"relic_offered","mode":"hidden","index":0,"detail":"","reason":""})
     else: options.append(frozen.option)
  else:
   var given=request.get("frozen",{})
   if not given.is_empty(): options.append(given)
 # 4) state conditions, then the feasibility probe
 if not _structural(gates) and options.size()==1:
  var entries=condition_entries(node_entry,choice)
  var index=0
  for entry in entries:
   var mode=entry.get("mode","optional")
   if condition_probe(g,entry) and (purpose!="execute" or mode=="optional"):
    gates.append({"gate":"availability_unmet","kind":entry.get("kind",""),"mode":mode,"index":index,"detail":"","reason":str(entry.get("reason",""))})
   index+=1
  # §3.3: the chain may not return to an event it already left. The option stays visible but
  # disabled, so the loop is refused at the candidate stage instead of silently disappearing.
  var chain_target=next_target(options[0].get("next","result"))
  if purpose!="execute" and chain_target.kind=="event" and chain_target.event in Array(g.state.room_event.get("chain",[])):
   gates.append({"gate":"chain_loop","kind":"chain","mode":"optional","index":index,"detail":chain_target.event,"reason":CHAIN_LOOP_REASON})
  if purpose!="execute" and (purpose!="arrival" or choice.get("hide_when_unavailable",false)):
   var feasibility=feasibility_gate(g,options[0])
   if not feasibility.is_empty():
    feasibility.mode=_feasibility_mode(node_entry,choice)
    feasibility.index=index
    gates.append(feasibility)
 var decision=_decision(gates)
 var authored_id=str(choice.get("id",""))
 var frozen_id="" if options.is_empty() else str(options[0].get("id",""))
 if frozen_id=="": frozen_id=authored_id
 for hit in gates:
  trace_entry(g,{"source_choice":authored_id,"option_id":frozen_id,"decision":decision,"gate":hit.gate,"kind":hit.get("kind",""),"mode":hit.get("mode",""),"index":hit.get("index",0),"reason":hit.get("reason",""),"purpose":purpose})
 if gates.is_empty():
  trace_entry(g,{"source_choice":authored_id,"option_id":frozen_id,"decision":decision,"purpose":purpose})
 return {"decision":decision,"gates":gates,"gate":"" if gates.is_empty() else str(gates[0].gate),"reason":_joined_reason(gates),"option":{} if options.is_empty() else options[0]}

static func _structural(gates: Array) -> bool:
 return gates.any(func(hit):return hit.gate in ["condition_unmet","relic_pool_empty","selector_empty","recipe_empty","freeze_failed"])

static func _decision(gates: Array) -> String:
 if _structural(gates): return "dropped"
 if gates.any(func(hit):return hit.mode=="hidden"): return "hidden"
 if not gates.is_empty(): return "disabled"
 return "generated"

# One hit keeps its authored wording; several optional hits are joined in declaration
# order with newlines (§5.3). A feasibility hit keeps its probe wording as before.
static func _joined_reason(gates: Array) -> String:
 var reasons=gates.map(func(hit):return str(hit.get("reason",""))).filter(func(text):return text!="")
 return "\n".join(reasons)

static func _feasibility_mode(node_entry: Dictionary, choice: Dictionary) -> String:
 if choice.get("unavailable","")=="hide": return "hidden"
 if choice.get("unavailable","")=="disable": return "optional"
 if choice.get("hide_when_unavailable",false): return "hidden"
 return "optional" if node_entry.get("unavailable","disable")=="disable" else "hidden"

# The feasibility probe: the same checks and wording as before, reported as a named gate.
static func feasibility_gate(g, option: Dictionary) -> Dictionary:
 var probe_state=probe_result(g,option.effects,option)
 if probe_state.reason!="": return {"gate":probe_state.gate,"kind":"feasibility","detail":str(option.get("id","")),"reason":probe_state.reason}
 if option.has("encounter"):
  var issue=battle_spec_issue(g,option.encounter)
  if issue=="": issue=probe_result(g,option.encounter.victory_effects,{}).reason
  if issue!="": return {"gate":"encounter_invalid","kind":"feasibility","detail":str(option.get("id","")),"reason":issue}
 return {}

# Evaluations of one authored choice: the frozen selection when re-checking a frozen
# option, one selection per selector value when arriving.
static func selections_for(g, choice: Dictionary, selected={}) -> Array:
 if not selection_rows(selected).is_empty(): return [selected]
 if not choice.has("selector"): return [{}]
 return selector_selections(g,choice.selector)

# The authored choice behind a frozen option; in-place options are the author object itself.
static func authored_choice(g, option: Dictionary) -> Dictionary:
 var spec=definition(g.state.room_event.get("id",""))
 var node_entry=node(spec,g.state.room_event.get("stage",""))
 var wanted=str(option.get("source_choice",option.get("id","")))
 for choice in node_entry.get("choices",[]):
  if choice.get("id","")==wanted: return choice
 return option

# Request for an already frozen option (candidate support, probe, execute).
static func request_for(g, option: Dictionary, purpose: String) -> Dictionary:
 var spec=definition(g.state.room_event.get("id",""))
 return {"definition":spec,"node":node(spec,g.state.room_event.get("stage","")),"choice":authored_choice(g,option),"selected":option.get("selected",{}),"purpose":purpose,"frozen":option}

# Freeze one authored choice (or one selection of it) into a concrete option.
static func freeze_one(g, node_entry: Dictionary, choice: Dictionary, selected={}, outcome: Dictionary={}) -> Dictionary:
 # A selector option has always been frozen through the shared staged builder (§1.1 P2),
 # so the layout follows the selector as well as the declared form.
 if node_entry.get("frozen_form","in_place")=="in_place" and not choice.has("selector"): return _freeze_in_place(g,node_entry,choice,selected,outcome)
 return _freeze_staged(g,node_entry,choice,selected,outcome)

# The in-place layout: the author object is the frozen option, updated in place, so its key
# set and key order stay exactly what the author wrote (§0.2 digest constraint).
static func _freeze_in_place(g, node_entry: Dictionary, choice: Dictionary, selected={}, outcome: Dictionary={}) -> Dictionary:
 var drawn=outcome
 if drawn.is_empty() and choice.has("outcomes"): drawn=weighted(g,choice.outcomes)
 var declared=choice.get("effects",[]).duplicate(true) if choice.has("effects") else compile(g,choice.get("recipe",""))
 if declared.is_empty() and not choice.has("effects") and not drawn.is_empty(): declared=drawn.get("effects",[]).duplicate(true)
 if not chosen_effects(choice,declared): return {"ok":false,"gate":"recipe_empty","reason":""}
 if not selection_rows(selected).is_empty(): declared=selected_value(declared,selected)
 # remove_restraints is the shared atomic removal effect. Keep its frozen target shape
 # consistently array-based even when an authored selector asks for one.
 for effect in declared:
  if effect.get("op","")=="remove_restraints" and effect.get("targets") is String: effect.targets=[effect.targets]
 var effects=declared.map(func(effect):return resolve_effect_copy(g,effect))
 var option=choice.duplicate(true)
 if not drawn.is_empty():
  option.reward=drawn.get("reward",option.get("reward","none"))
  option.next=drawn.get("next",option.get("next","result"))
  option.result_status=drawn.get("result_status",option.get("result_status","neutral"))
  if drawn.has("report"): option.report=drawn.report
  if drawn.has("report_variants"): option.report_variants=drawn.report_variants
 option.report=conditional_copy(g,option.get("report",option.label),option.get("report_variants",[]))
 if effects.any(func(effect):return effect.op in ["install_random","tighten_random","special_install_random","random_amount"]):
  var frozen=freeze_effects(g,effects)
  if frozen.issue!="": return {"ok":false,"gate":"freeze_failed","reason":frozen.issue}
  option.effects=frozen.effects
 else: option.effects=effects
 if choice.has("item_rewards"): option.item_rewards=freeze_item_rewards(g,choice.item_rewards)
 option.detail=choice.get("detail",(describe(g,effects)+"\n"+reward_text(option.reward,g)).strip_edges())
 if not selection_rows(selected).is_empty(): option.selected=selected.duplicate(true)
 return {"ok":true,"option":option}

# A declared empty effect list is an authored choice; without one the choice needs a recipe
# or a drawn result that carries effects.
static func chosen_effects(choice: Dictionary, declared: Array) -> bool:
 return choice.has("effects") or not declared.is_empty()

# The staged layout: a fixed field order that never echoes the author object.
static func _freeze_staged(g, node_entry: Dictionary, choice: Dictionary, selected={}, outcome: Dictionary={}) -> Dictionary:
 var drawn=outcome
 if drawn.is_empty() and choice.has("outcomes"): drawn=weighted(g,choice.outcomes)
 var declared=choice.get("effects",[]).duplicate(true)+drawn.get("effects",[]).duplicate(true)
 var selected_rows=selection_rows(selected)
 if not selected_rows.is_empty(): declared=selected_value(declared,selected)
 for effect in declared:
  if effect.get("op","")=="remove_restraints" and effect.get("targets") is String: effect.targets=[effect.targets]
 if choice.has("recipe"):
  var compiled=compile(g,choice.recipe)
  if compiled.is_empty(): return {"ok":false,"gate":"recipe_empty","reason":""}
  declared=compiled+declared
 var frozen=freeze_effects(g,declared)
 if frozen.issue!="": return {"ok":false,"gate":"freeze_failed","reason":frozen.issue}
 var selected_suffix=""
 if not selected_rows.is_empty(): selected_suffix="__"+"__".join(selected_rows.map(func(row):return row.id))
 var report=drawn.get("report",choice.get("report",choice.label))
 var report_variants=drawn.get("report_variants",choice.get("report_variants",[]))
 report=conditional_copy(g,report,report_variants)
 var option={"id":choice.id+selected_suffix,"source_choice":choice.id,"label":selected_text(choice.label,selected),"reward":drawn.get("reward",choice.get("reward","none")),"effects":frozen.effects,"next":drawn.get("next",choice.get("next","result")),"report":selected_text(report,selected)}
 if choice.get("show_pressure_sources",false): option.show_pressure_sources=true
 if choice.has("availability"): option.availability=choice.availability.duplicate(true)
 if choice.has("conditions"): option.conditions=choice.conditions.duplicate(true)
 if choice.has("item_rewards"): option.item_rewards=freeze_item_rewards(g,choice.item_rewards)
 option.detail=selected_text(choice.get("detail",(describe(g,option.get("effects",[]))+"\n"+reward_text(option.reward,g)).strip_edges()),selected)
 option.result_status=drawn.get("result_status",choice.get("result_status","neutral"))
 if not selected_rows.is_empty(): option.selected=selected.duplicate(true)
 return {"ok":true,"option":option}

# Kept entry point for callers that freeze an authored choice without a node (§7.1).
static func freeze_choice(g, definition: Dictionary, selected={}, fixed_outcome: Dictionary={}) -> Dictionary:
 var frozen=_freeze_staged(g,{"outcome_draw":"option","frozen_form":"staged"},definition,selected,fixed_outcome)
 return {} if not frozen.ok else frozen.option

# One node pipeline for both definition shapes. Every declared policy is read here:
# allow_refuse, unavailable, relic_gate, random_freeze, outcome_draw, frozen_form, empty_node.
# The node count no longer decides anything.
static func enter_node(g, id: String) -> String:
 return str(enter_node_result(g,id,"arrival").get("issue",""))

# One implementation of the node pipeline; the string form above is its issue projection.
# The purpose is the caller's declaration: a real advance uses "arrival", the next-node
# look-ahead of probe_result passes "next_probe" (§4.5 A31).
static func enter_node_result(g, id: String, purpose: String="arrival") -> Dictionary:
 var spec=definition(g.state.room_event.get("id",""))
 var node_entry=node(spec,id)
 if node_entry.is_empty():
  # A30: a missing node writes the same node-entry failure row as an empty one.
  trace_entry(g,{"node":id,"decision":"dropped","gate":"stage_missing","detail":id,"purpose":purpose})
  return {"issue":"下一阶段不存在。","gate":"stage_missing","detail":id}
 var options=[]
 for choice in node_entry.get("choices",[]):
  var selections=selections_for(g,choice)
  if selections.is_empty():
   # A selector that expands to nothing still goes through the entry, so the
   # selector_empty gate and its trace row exist (§4.2／§10 scenario 03).
   evaluate_option(g,{"definition":spec,"node":node_entry,"choice":choice,"selected":{},"purpose":"arrival","outcome":{}})
   continue
  # outcome_draw=="option" spends exactly one draw for the whole choice, then copies it.
  var shared={}
  if choice.has("outcomes") and node_entry.get("outcome_draw","option")=="option": shared=weighted(g,choice.outcomes)
  for selection in selections:
   var result=evaluate_option(g,{"definition":spec,"node":node_entry,"choice":choice,"selected":selection,"purpose":"arrival","outcome":shared})
   if result.decision in ["generated","disabled"]: options.append(result.option)

 if node_entry.get("allow_refuse",false): options.append(refusal(g))
 if options.is_empty() and node_entry.get("empty_node","fail")=="fail":
  trace_entry(g,{"node":id,"decision":"dropped","gate":"node_empty","detail":id,"purpose":purpose})
  return {"issue":"这一阶段没有能够执行的选项。","gate":"node_empty","detail":id}
 g.state.room_event.stage=id
 g.state.room_event.options=options
 return {"issue":"","gate":"","detail":""}


# Debug-only trace (§4.5): a switch plus an array on the game instance, never in state,
# never in a View, never saved, never rendered. They live in object metadata because
# core/game.gd is outside this batch; the names are the contract's.
static func trace_enabled(g) -> bool:
 return g.get_meta("event_trace_enabled",false)==true

static func clear_trace(g) -> void:
 if not trace_enabled(g): return
 g.set_meta("event_trace",[])

static func event_trace(g) -> Array:
 var rows=g.get_meta("event_trace",[])
 if not rows is Array:
  rows=[]
  g.set_meta("event_trace",rows)
 return rows

static func trace_entry(g, fields: Dictionary) -> void:
 if not trace_enabled(g): return
 var room_event=g.state.room_event
 var option_id=str(fields.get("option_id",""))
 var row={"event":str(room_event.get("id","")),"node":str(room_event.get("stage","")),"source_choice":str(fields.get("source_choice",option_id)),"option_id":option_id,"decision":str(fields.get("decision","")),"gate":str(fields.get("gate","")),"kind":str(fields.get("kind","")),"mode":str(fields.get("mode","")),"index":int(fields.get("index",0)),"reason":str(fields.get("reason","")),"purpose":str(fields.get("purpose",""))}
 if str(fields.get("node",""))!="": row.node=str(fields.node)
 if option_id=="":
  # A31: node-level rows (node_empty／stage_missing) keep one row per (event, purpose, node,
  # gate) inside this instance — the first writer wins, so frozen instances never repeat the
  # same target row and a probe row stays distinguishable from the arrival row.
  for other in event_trace(g):
   if str(other.get("option_id",""))=="" and str(other.get("event",""))==row.event and str(other.get("purpose",""))==row.purpose and str(other.get("node",""))==row.node and str(other.get("gate",""))==row.gate: return
 event_trace(g).append(row)

static func weighted(g, outcomes: Array) -> Dictionary:
 var total=0
 for outcome in outcomes: total+=int(outcome.weight)
 var roll=g._random_index("event",total)
 for outcome in outcomes:
  roll-=int(outcome.weight)
  if roll<0: return outcome
 return outcomes[-1]

static func copy_condition_met(g, when: Dictionary) -> bool:
 match when.get("kind",""):
  "equipped_special_family":
   return g.state.special_equipment.any(func(item):
    if item.get("durability",0)<=0: return false
    var type=g.SpecialEquipment.TYPES.get(item.get("type",""),{})
    return type.get("family","")==when.get("value","")
   )
 return false

static func conditional_copy(g, fallback: String, variants: Array) -> String:
 for variant in variants:
  if copy_condition_met(g,variant.when): return variant.text
 return fallback

static func resolve_effect_copy(g, effect: Dictionary) -> Dictionary:
 var resolved=effect.duplicate(true)
 if resolved.get("op","")=="pressure" and resolved.has("source_variants"):
  resolved.source=conditional_copy(g,resolved.get("source",""),resolved.source_variants)
  resolved.erase("source_variants")
 return resolved

static func freeze_effects(g, declared: Array) -> Dictionary:
 var original=g.state
 # Simulated costs may emit logs, but must never reach the live UI receipt.
 var feedback=g._resource_feedback
 g._resource_feedback=null
 g.state=original.duplicate(true)
 var frozen=[];var issue=""
 for authored_effect in declared:
  var declared_effect=resolve_effect_copy(g,authored_effect)
  if declared_effect.op=="install_random":
   for _index in range(declared_effect.count):
    var spec={"pool":"ordinary","templates":declared_effect.templates,"count":1,"grade":declared_effect.grade,"tier":declared_effect.tier,"locked":declared_effect.locked,"replace":declared_effect.get("replace",false)}
    spec.allow_links=declared_effect.get("allow_links",true)
    # Existing events promise the factory's default material variant. Do not
    # introduce equipment-domain draws while freezing an event choice.
    spec.variants={}
    for template in declared_effect.templates: spec.variants[template]=0
    var concrete=g.Application.choose(g,spec,"event:"+g.state.room,"event")
    if concrete.is_empty() or concrete.kind not in ["install","link"]:
     issue="没有足够的合法位置安装随机拘束具。";break
    concrete.op=concrete.kind;concrete.erase("kind")
    if declared_effect.has("replace"): concrete.replace=declared_effect.replace
    if declared_effect.has("wear_style"): concrete.wear_style=declared_effect.wear_style
    issue=apply_effects(g,[concrete],g.state.room_event.refs,false)
    if issue!="": break
    frozen.append(concrete)
  elif declared_effect.op=="tighten_random":
   for _index in range(declared_effect.count):
    var targets=g.physical_pieces().filter(func(item):return g._can_tighten(item) and g.tier(item.durability,item.maximum)<declared_effect.to_tier and (declared_effect.get("templates",[]).is_empty() or item.template in declared_effect.templates))
    if targets.is_empty():
     issue="没有足够的拘束具可以收紧到指定档位。";break
    var target=targets[g._random_index("event",targets.size())]
    var concrete={"op":"tighten_to","target":target.id,"tier":declared_effect.to_tier}
    issue=apply_effects(g,[concrete],g.state.room_event.refs,false)
    if issue!="": break
    frozen.append(concrete)
  elif declared_effect.op=="special_install_random":
   var legal=[]
   for type in declared_effect.types:
    var before=g.state.duplicate(true)
    var concrete=g.Application.choose(g,{"pool":"special","templates":[type],"replace":declared_effect.get("replace",false)},"event:"+g.state.room,"event")
    if not concrete.is_empty():
     concrete.op=concrete.kind;concrete.erase("kind")
     if declared_effect.has("replace"): concrete.replace=declared_effect.replace
     if apply_effects(g,[concrete],g.state.room_event.refs,false)=="": legal.append(concrete)
    g.state=before
   if legal.is_empty():
    if declared_effect.has("fallback"):
     var fallback=freeze_effects(g,declared_effect.fallback)
     issue=fallback.issue
     frozen.append_array(fallback.effects)
    else:
     issue="没有空余位置佩戴这件性玩具。"
   else:
    var concrete=legal[g._random_index("event",legal.size())]
    issue=apply_effects(g,[concrete],g.state.room_event.refs,false)
    if issue=="": frozen.append(concrete)
  elif declared_effect.op=="random_amount":
   var concrete={"op":declared_effect.effect,"amount":int(declared_effect.minimum)+g._random_index("event",int(declared_effect.maximum)-int(declared_effect.minimum)+1)}
   if declared_effect.has("source"): concrete.source=declared_effect.source
   issue=apply_effects(g,[concrete],g.state.room_event.refs,false)
   if issue=="": frozen.append(concrete)
  else:
   var concrete=declared_effect.duplicate(true)
   if concrete.op=="counter": concrete.amount=int(concrete.amount)
   issue=apply_effects(g,[concrete],g.state.room_event.refs,false)
   if issue!="": break
   frozen.append(concrete)
  if issue!="": break
 var event_counter=g.state.rng.event
 g.state=original
 g.state.rng.event=event_counter
 g._resource_feedback=feedback
 return {"effects":frozen,"issue":issue}

static func selection_rows(selected) -> Array:
 return selected if selected is Array else ([selected] if selected is Dictionary and not selected.is_empty() else [])

static func selected_text(value: String, selected) -> String:
 var rows=selection_rows(selected)
 var names=rows.map(func(row):return row.get("name",""))
 var slots=rows.map(func(row):return row.get("slot",""))
 var types=rows.map(func(row):return row.get("type",row.get("kind","")))
 return value.replace("{name}","与".join(names)).replace("{slot}","与".join(slots)).replace("{type}","与".join(types))

static func selected_value(value, selected):
 if value is String:
  if value=="$selected":
   var rows=selection_rows(selected)
   return rows.map(func(row):return row.id) if selected is Array else selected.id
  return selected_text(value,selected)
 if value is Array: return value.map(func(entry):return selected_value(entry,selected))
 if value is Dictionary:
  var result={}
  for key in value: result[key]=selected_value(value[key],selected)
  return result
 return value

static func selector_values(g, selector: Dictionary) -> Array:
 var result=[]
 match selector.kind:
  "card":
   for card in g.state.deck:
    if selector.get("exclude_curses",false) and g.B.CARD_TRAITS.get(card.type,{}).get("curse",false): continue
    result.append({"id":card.uid,"name":g.B.CARD_NAMES[card.type],"type":card.type,"kind":"card","slot":"卡组"})
  "restraint":
   # §3.1 item 6: only this display branch reads equipment; the card branch reads the deck.
   var previous=g._begin_equipment_read()
   for item in g.physical_pieces():
    if item.durability<=0: continue
    result.append({"id":item.id,"name":g._equipment_name(item),"type":item.template,"kind":"restraint","slot":g.B.SLOT_NAMES[item.slot]})
   for item in g.state.special_equipment:
     if not selector.get("include_special",true): continue
     if item.durability<=0 or not g.SpecialEquipment.allows(item,"lower"): continue
     result.append({"id":item.id,"name":g._equipment_name(item),"type":item.type,"kind":"restraint","slot":g.SpecialEquipment.slot_name(item.slot)})
   g._equipment_read=previous
 return result

static func selector_combinations(values: Array, count: int, start: int=0, prefix: Array=[]) -> Array:
 if prefix.size()==count: return [prefix.duplicate(true)]
 var result=[]
 var remaining=count-prefix.size()
 for index in range(start,values.size()-remaining+1):
  var next=prefix.duplicate(true)
  next.append(values[index])
  result.append_array(selector_combinations(values,count,index+1,next))
 return result

static func selector_selections(g, selector: Dictionary) -> Array:
 var values=selector_values(g,selector)
 var count=int(selector.get("count",1))
 return values if count==1 else selector_combinations(values,count)

static func condition_met(g, condition: Dictionary) -> bool:
 if condition.is_empty(): return true
 var value=selector_values(g,condition.selector).size() if condition.has("selector") else int(g.state.room_event.values.get(condition.counter,0))
 if condition.has("equals"): return value==int(condition.equals)
 return value>=int(condition.get("minimum",0)) and value<=int(condition.get("maximum",2147483647))

static func freeze_item_rewards(g, groups: Array) -> Array:
 var result=[]
 for group in groups:
  var pool=group.pool
  result.append({"id":group.id,"type":pool[g._random_index("event",pool.size())]})
 return result

static func item_rewards_issue(g, rows, allow_claimed: bool=false) -> String:
 if not rows is Array or rows.is_empty() or rows.size()>6: return "事件道具奖励记录不完整。"
 var ids=[]
 for row in rows:
  if not row is Dictionary or not row.get("id") is String or not row.get("type") is String or row.id in ids or not g.Tools.TYPES.has(row.type): return "事件道具奖励记录不完整。"
  if allow_claimed:
   if not row.get("claimed") is bool: return "事件道具领取记录不完整。"
  elif row.has("claimed"): return "尚未领取的冻结奖励带有错误状态。"
  ids.append(row.id)
 return ""

static func pick(g, options: Array) -> Dictionary:
 if options.is_empty(): return {}
 var preferred=g.EquipmentOffers.preferred(g,options)
 return preferred[g._random_index("event",preferred.size())].duplicate(true)

static func ordinary(g, grade: int, free: bool, templates: Array, locked: bool=false) -> Array:
 var result=[]
 for option in g.EquipmentOffers.for_pool(g,grade,templates,locked):
  if option.kind=="install" and free and g.occupied(option.slot): continue
  var effect=option.duplicate(true)
  effect.op=effect.kind;effect.erase("kind")
  effect.grade=grade;effect.tier=1 if grade==1 else 2;effect.locked=locked
  result.append(effect)
 return result

static func compile(g, recipe: String) -> Array:
 match recipe:
  "free_basic":
   var effect=pick(g,ordinary(g,1,true,["rope","belt"]))
   return [] if effect.is_empty() else [effect]
  "tighten_or_medium":
   # §3.1 item 7: only this filter expression is a read scope; the locked_assembly branch
   # below swaps state, so the function itself must not be wrapped.
   var previous=g._begin_equipment_read()
   var targets=g.physical_pieces().filter(func(e):return g._can_tighten(e))
   g._equipment_read=previous
   if not targets.is_empty():
    var target=targets[g._random_index("event",targets.size())]
    return [{"op":"tighten","target":target.id}]
   var effect=pick(g,ordinary(g,2,false,["rope","belt"]))
   return [] if effect.is_empty() else [effect]
  "locked_assembly":
   var options=g.EquipmentOffers.assemblies(g,2,["glove","leg","jacket"])
   var option=pick(g,options)
   if option.is_empty(): return []
   var original=g.state
   g.state=original.duplicate(true)
   var request=option.duplicate(true);request.grade=2;request.tier=2
   var applied=g.Application.execute_concrete(g,request,"event:"+g.state.room,false)
   var root={} if not applied.ok else applied.installed[0]
   if root.is_empty():
    g.state=original
    return []
   var parts=root.components.filter(func(e):return g.Equipment.allows(e,"lock"))
   var part="" if parts.is_empty() else parts[0].part
   g.state=original
   if part=="": return []
   return [{"op":"assembly","family":option.family,"variant":option.variant,"straps":option.straps,"part":part,"name":root.name,"coverage":g.Composites.definition(root).coverage,"part_name":parts[0].name}]
 return []

static func reward_text(kind: String, g=null) -> String:
 var count=3 if g==null else 3+int(g.relic_value("reward_card_options"))
 match Data.card_reward_kind(kind):
  "common": return "普通牌%d选1。" % count
  "uncommon": return "罕见牌%d选1。" % count
  "rare": return "稀有牌%d选1。" % count
  "relic": return "获得一件随机遗物。"
 return ""

static func describe(g, effects: Array) -> String:
 var lines: Array[String]=[]
 for e in effects:
  match e.op:
   "special_install": lines.append("佩戴%s（%s）。" % [g.SpecialEquipment.TYPES[e.type].name,g.SpecialEquipment.slot_name(e.slot)])
   "mana_loss": lines.append("支付%s魔力。" % g.number(e.amount))
   "mana_gain": lines.append("恢复%s魔力。" % g.number(e.amount))
   "mana_restore_full": lines.append("将当前魔力恢复至上限。")
   "mana_max_loss": lines.append("永久失去%s点最大魔力。" % g.number(e.amount))
   "flask_mana_gain": lines.append("贴身魔瓶获得%s魔力。" % g.number(e.amount))
   "card": lines.append("获得卡牌「"+g.B.CARD_NAMES[e.type]+"」。")
   "tool": lines.append("获得"+g.Tools.TYPES[e.type].name+"。")
   "relic": lines.append("获得%s遗物「%s」。" % [Relics.RARITIES[Relics.TYPES[e.type].rarity],Relics.TYPES[e.type].name])
   "pressure": lines.append("快感增加%s。" % g.number(e.amount))
   "install": lines.append("施加%s%s：%s，%d档%s。" % [g.Equipment.GRADES[e.grade],g.Equipment.name_for(e.template,"mouth",e.grade) if e.template=="mouth_band" else g.Equipment.TEMPLATES[e.template].name,g.B.SLOT_NAMES[e.slot],e.tier,"并上锁" if e.locked else ""])
   "link": lines.append("施加%s链接绳：%s，%d档。" % [g.Equipment.GRADES[e.grade]," ↔ ".join(e.contact_points.map(g.Equipment.point_name)),e.tier])
   "tighten":
    var target=g._equipment(e.target)
    lines.append("加固%s：%s，%d档 → %d档。" % [g._equipment_name(target),g.B.SLOT_NAMES[target.slot],g.tier(target.durability,target.maximum),mini(3,g.tier(target.durability,target.maximum)+1)])
   "tighten_to":
    var target=g._equipment(e.target)
    if g.Equipment.lock_only(target): return g.Equipment.LOCK_ONLY_REASON
    lines.append("收紧%s：%s，%d档 → %d档。" % [g._equipment_name(target),g.B.SLOT_NAMES[target.slot],g.tier(target.durability,target.maximum),e.tier])
   "hold_special": lines.append("暂时取下指定位置的性玩具，结束后装回。")
   "restore_held": lines.append("把事件期间代为保管的装备原样装回。")
   "transform_card": lines.append("若赌局失败，押上的「%s」会变为诅咒「%s」。" % [e.get("name","这张牌"),g.B.CARD_NAMES[e.type]])
   "remove_card": lines.append("移除「%s」。" % e.get("name","所选卡牌"))
   "remove_restraints": lines.append("完全解除%s。" % e.get("name","所选拘束具"))
   "ease_restraint": lines.append("若赌局获胜，解除所选拘束具上的锁，并将它松开一档；一档拘束具会直接解除。")
   "counter": pass
   "assembly": lines.append("施加中级%s：覆盖%s；全部组件2档，并锁住%s。" % [e.name,"、".join(e.coverage.map(func(s):return g.B.SLOT_NAMES[s])),e.part_name])
  if e.get("replace",false): lines.append("位置已满时可能替换原装备。")
 return "\n".join(lines)

static func apply_effects(g, effects: Array, refs: Dictionary, emit_logs: bool=true) -> String:
 for e in effects:
  var target=g._equipment(refs.get(e.get("ref_target",""),e.get("target","")))
  var installed={}
  if e.op in ["install","assembly","special_install","link"]:
   if e.has("replace") and not e.replace is bool: return "安装效果的替换权限必须明确为允许或不允许。"
   var request=e.duplicate(true);request.kind=e.op;request.erase("op")
   # The event's assembly bargain remains exactly medium / tier two, with its
   # declared component lock included before any replacement comparison.
   if e.op=="assembly":
    request.grade=2;request.tier=2;request.overrides={e.part:{"locked":true}}
   var applied=g.Application.execute_concrete(g,request,"event:"+g.state.room,e.get("replace",false))
   if applied.get("evaded",0)>0: continue
   if not applied.ok: return applied.reason
   installed=applied.installed[0]
   if e.has("ref"): refs[e.ref]=installed.id
  match e.op:
   "special_install":
    var held=[]
    for key in g.state.room_event.held: held.append_array(g.state.room_event.held[key])
    if g.SpecialEquipment.validate(g.state.special_equipment+held)!="": return "原定位置需要留给暂存装备，无法安装这件特殊装备。"
    if emit_logs: g._emit("event","装上"+installed.name+"，位置："+g.SpecialEquipment.slot_name(installed.slot)+"。")
   "pressure": g.Pressure.gain(g,e.amount,e.get("source",Data.TYPES[g.state.room_event.id].name))
   "install":
    target=installed
    if emit_logs: g._emit("event","装上"+target.name+"，紧度%d档%s。" % [e.tier,"，并已上锁" if e.locked else ""])
   "link":
    if emit_logs: g._emit("event","在%s之间装上%s链接绳，紧度%d档。" % ["与".join(installed.contact_points.map(g.Equipment.point_name)),g.Equipment.GRADES[e.grade],e.tier],{"equipment":installed.id,"contact_points":installed.contact_points.duplicate()})
   "assembly":
    var root=installed
    var parts=root.components.filter(func(p):return p.part==e.part and g.Equipment.allows(p,"lock"))
    if parts.is_empty(): return "原定上锁组件不存在或不能上锁。"
    if not parts[0].locked: return "原定组件没有按约定上锁。"
    if emit_logs: g._emit("event","装上"+root.name+"，全部组件2档；"+parts[0].name+"已上锁。")
   "tighten":
    if target.is_empty() or g.SpecialEquipment.is_special(target) or not g._can_tighten(target): return "原定加固目标不存在、不支持普通加固或已经完全收紧。"
    var change=g._reinforce_equipment(target)
    if emit_logs: g._emit("event",target.name+"被"+change+"。")
   "tighten_to":
    if target.is_empty() or g.SpecialEquipment.is_special(target) or e.tier not in [1,2,3] or g.tier(target.durability,target.maximum)>=e.tier: return "原定目标不存在、不支持普通加固或已经达到指定紧度。"
    target.durability=target.maximum*[0.0,0.4,0.8,1.0][e.tier]
    g._refresh_equipment(target)
    if emit_logs: g._emit("event",target.name+"被收紧到%d档。" % e.tier)
   "unlock":
    if g.cursed_plate(target): return g.SpecialEquipment.CURSED_PLATE_REASON
    if target.is_empty() or not target.locked: return "原定锁已经不存在。"
    target.locked=false
    if emit_logs: g._emit("event","解除了"+target.name+"的锁，装备本身保留。")
   "mana_loss":
    if g.state.mana<e.amount: return "剩余魔力不足以支付已公开的费用。"
    g.state.mana-=e.amount
    if emit_logs: g._emit("event","支付%s魔力。" % g.number(e.amount))
   "mana_gain":
    var mana_before=g.state.mana
    g.state.mana=minf(g.state.mana_max,g.state.mana+e.amount)
    if emit_logs: g._emit("event","恢复%s魔力，当前魔力%s/%s。" % [g.number(g.state.mana-mana_before),g.number(g.state.mana),g.number(g.state.mana_max)])
   "mana_restore_full":
    var full_mana_before=g.state.mana
    g.state.mana=g.state.mana_max
    if emit_logs: g._emit("event","恢复%s魔力，当前魔力%s/%s。" % [g.number(g.state.mana-full_mana_before),g.number(g.state.mana),g.number(g.state.mana_max)])
   "mana_max_loss":
    if g.state.mana_max-e.amount<g.B.MANA_MAX_FLOOR: return "最大魔力不足以承受这项永久代价。"
    g.state.mana_max-=e.amount
    g.state.mana=minf(g.state.mana,g.state.mana_max)
    if emit_logs: g._emit("event","最大魔力永久降低%s点，当前魔力%s/%s。" % [g.number(e.amount),g.number(g.state.mana),g.number(g.state.mana_max)])
   "flask_mana_gain":
    g.state.flask_mana+=e.amount
    if emit_logs: g._emit("event","贴身魔瓶获得%s魔力，当前储量%s。" % [g.number(e.amount),g.number(g.state.flask_mana)])
   "card":
    if not g.B.CARD_NAMES.has(e.type): return "奖励牌没有有效定义。"
    g._gain_card(e.type)
    if emit_logs: g._emit("event","「"+g.B.CARD_NAMES[e.type]+"」加入卡组。")
   "transform_card":
    var cards=g.state.deck.filter(func(card):return card.uid==e.target)
    if cards.size()!=1: return "押上的卡牌已经不在卡组中。"
    var old=cards[0].type
    cards[0].type=e.type
    for zone in g.Cards.ZONES:
     for card in g.state[zone]:
      if card.uid==e.target: card.type=e.type
    if emit_logs: g._emit("event","「"+g.B.CARD_NAMES[old]+"」变成了诅咒「"+g.B.CARD_NAMES[e.type]+"」。")
   "remove_card":
    var old=g.Cards.remove_permanent(g,e.target)
    if old=="": return "所选卡牌已经不在卡组中。"
    if emit_logs: g._emit("event","从卡组移除了「"+g.B.CARD_NAMES[old]+"」。")
   "remove_restraints":
    var targets=[]
    for id in e.targets:
     var restraint=g._equipment(id)
     if restraint.is_empty() or restraint.durability<=0: return "所选拘束具已经不存在。"
     if g.cursed_eyes(restraint): return "诅咒眼罩无法解除。"
     if g.Equipment.lock_only(restraint): return g.Equipment.LOCK_ONLY_REASON
     if g.cursed_plate(restraint): return g.SpecialEquipment.CURSED_PLATE_REASON
     targets.append(restraint)
    for restraint in targets:
     restraint.locked=false
     restraint.durability=0.0
     g._refresh_equipment(restraint)
    if emit_logs: g._emit("event",e.get("name","所选拘束具")+"已经解除。")
    g._cleanup()
   "ease_restraint":
    if g.Equipment.lock_only(target): return g.Equipment.LOCK_ONLY_REASON
    if g.cursed_plate(target): return g.SpecialEquipment.CURSED_PLATE_REASON
    if g.cursed_eyes(target): return "诅咒眼罩无法松解。"
    if target.is_empty() or target.durability<=0: return "押上的拘束具已经不存在。"
    if g.SpecialEquipment.is_special(target) and not g.SpecialEquipment.allows(target,"lower"): return "这件特殊装备不能通过松开一档来解除。"
    var before_tier=g.tier(target.durability,target.maximum)
    target.locked=false
    target.durability=g.lower_durability(target.durability,target.maximum)
    g._refresh_equipment(target)
    if emit_logs: g._emit("event",target.name+("已经解除。" if target.durability<=0 else "已经松到%d档。" % g.tier(target.durability,target.maximum)))
    g._cleanup()
   "counter":
    var value=int(g.state.room_event.values.get(e.key,0))+int(e.amount)
    if value<0: return "事件计数不能降到零以下。"
    g.state.room_event.values[e.key]=value
   "tool":
    if not g.Tools.TYPES.has(e.type): return "道具没有有效定义。"
    g._gain_tool(e.type)
    if emit_logs: g._emit("event","获得"+g.Tools.TYPES[e.type].name+"。")
   "relic":
    if not Relics.TYPES.has(e.type): return "遗物没有有效定义。"
    if not g.Relics.can_gain(g.state.relics,e.type): return "已经持有这件遗物，不能重复领取。"
    g.RelicEffects.gain(g,e.type)
   "hold_special":
    if g.state.room_event.held.has(e.key): return "同一保管位置不能重复使用。"
    var held=[]
    for item in g.state.special_equipment.duplicate():
     if not item.coverage.any(func(slot):return slot in e.slots): continue
     if g.cursed_plate(item): return g.SpecialEquipment.CURSED_PLATE_REASON
     if g.state.links.any(func(link):return item.id in link.ends): return item.name+"仍连接着其他拘束具，不能暂时取下。"
     held.append(item.duplicate(true));g.state.special_equipment.erase(item)
    g.state.room_event.held[e.key]=held
    if emit_logs: g._emit("event","暂时取下并保管了%d件性玩具；事件结束时原样装回。" % held.size())
   "restore_held":
    # Cleanup is deliberately idempotent: a branch may leave before anything was
    # held, while another branch of the same authored event uses the same cleanup.
    if not g.state.room_event.held.has(e.key): continue
    var held=g.state.room_event.held[e.key]
    var combined=g.state.special_equipment+held
    var held_issue=g.SpecialEquipment.validate(combined)
    if held_issue!="": return "无法原样装回暂存装备："+held_issue
    g.state.special_equipment.append_array(held)
    g.state.room_event.held.erase(e.key)
    if emit_logs: g._emit("event","代为保管的%d件性玩具已经原样装回。" % held.size())
   _: return "事件包含尚未支持的效果。"
 return ""

# Structured form of the effects probe: one implementation, and probe() stays the
# string-shaped entry point used by the rest of the pipeline.
static func probe_result(g, effects: Array, option: Dictionary={}, cleanup: bool=false) -> Dictionary:
 var original=g.state
 var feedback=g._resource_feedback
 g._resource_feedback=null
 g.state=original.duplicate(true)
 var issue=apply_effects(g,effects,g.state.room_event.refs,option.is_empty() and not cleanup)
 var gate="probe_failed"
 var next=next_target(option.get("next","result")) if option.has("next") else {"kind":"result"}
 if issue=="" and not option.is_empty() and next.kind!="result" and option.reward=="none":
  var next_result=enter_target(g,next,"next_probe")
  issue=next_result.issue
  gate=str(next_result.get("gate","probe_failed"))
 if issue=="" and cleanup and not g.state.room_event.held.is_empty():
  issue="事件仍有尚未归还的装备。"
  gate="held_pending"
 if issue=="" and gate!="held_pending":
  issue=g.validate()
  if issue!="": gate="validate_failed"
 g.state=original
 g._resource_feedback=feedback
 return {"gate":"" if issue=="" else gate,"reason":issue}

static func probe(g, effects: Array, option: Dictionary={}, cleanup: bool=false) -> String:
 return str(probe_result(g,effects,option,cleanup).get("reason",""))

static func probe_choice(g, option: Dictionary) -> String:
 var issue=availability_issue(g,option)
 if issue=="": issue=str(feasibility_gate(g,option).get("reason",""))
 return issue

# The state-condition part of the entry, keeping the authored reason text unchanged.
static func availability_issue(g, option: Dictionary) -> String:
 if option.has("availability"):
  var availability=option.availability
  if not availability is Dictionary or not availability.get("reason") is String: return "事件选项的状态条件不完整。"
 var request=request_for(g,option,"candidate")
 for entry in condition_entries(request.node,request.choice):
  if CONDITIONS.get(entry.get("kind",""),{}).is_empty(): return "事件选项的状态条件无法识别。"
  if condition_probe(g,entry): return str(entry.get("reason",""))
 return ""

static func append_choice_fact(g, out: Array, option: Dictionary) -> void:
 var result=evaluate_option(g,request_for(g,option,"candidate"))
 var reason=result.reason
 var choice_args={"option_id":option.id}
 out.append(g._fact({"kind":"event","action":"choose","choice":option.id},option.label,{"kind":"event.choice","args":choice_args,"fallback":choice_detail(g,choice_args)},0,0.0,reason,"","event"))
 if result.decision=="disabled" and not result.gates.is_empty() and result.gates.all(func(hit):return CONDITIONS.has(hit.kind)): out.back().reason_surface="secondary"

# R4（docs/ondemand-copy.md §11.5）：直呼点文案改走路由，正文留在本模块。
static func choice_detail(g, args: Dictionary) -> String:
 var option_id=String(args.get("option_id",""))
 for option in g.state.room_event.get("options",[]):
  if option.get("id","")==option_id: return String(option.get("detail",""))
 return ""

static func reward_skip_detail(_g, _args: Dictionary) -> String:
 return ""

static func prepare_detail(g, args: Dictionary) -> String:
 return "进行%d回合整备。" % g.preparation_turns() if bool(args.get("prepare",false)) else ""

static func probe_cleanup(g) -> String:
 return probe(g,g.state.room_event.get("cleanup_effects",[]),{},true)

# 事件显示事实（批 R5：行生产转发改显示事实构建，docs/spec/candidate-removal.md §2.1 T5／T8）。
static func facts(g) -> Array:
 var out=[]
 var event=g.state.room_event
 match event.stage:
  "choice":
   for option in event.options:
    append_choice_fact(g,out,option)
  "reward":
   for type in event.reward:
    out.append(g._fact({"kind":"event","action":"reward","type":type},"领取「"+g.B.CARD_NAMES[type]+"」",g.CopyRouter.two_face(g,type),0,0.0,"","","event"))
   out.append(g._fact({"kind":"event","action":"reward","type":"skip"},"跳过选牌",{"kind":"event.reward_skip","args":{},"fallback":reward_skip_detail(g,{})},0,0.0,"","","event"))
  "result":
   var prepare=event.get("prepare_pending",false)
   var prepare_args={"prepare":prepare}
   out.append(g._fact({"kind":"event","action":"leave"},"开始整备" if prepare else "离开",{"kind":"event.prepare","args":prepare_args,"fallback":prepare_detail(g,prepare_args)},0,0.0,probe_cleanup(g),"","event"))
  _:
   if not node(definition(event.id),event.stage).is_empty():
    for option in event.options:
     append_choice_fact(g,out,option)
 return out

static func execute(g, c: Dictionary) -> String:
 var event=g.state.room_event
 var p=c.payload
 var issue=""
 match p.action:
  "choose":
   var option=event.options.filter(func(o):return o.id==p.choice)[0]
   issue=evaluate_option(g,request_for(g,option,"execute")).reason
   if issue=="": issue=apply_effects(g,option.effects,event.refs)
   if issue!="": return issue
   var result_text=describe_result(g,option.effects)
   event.result_status=option.get("result_status","neutral")
   var report_text=option.get("report",option.label)
   var source_text=pressure_source_report(option.effects) if option.get("show_pressure_sources",false) else ""
   # Each result page belongs to this committed choice. Previous results already
   # live in the event log and must not be replayed before every later stage.
   if result_text=="" and not report_text.ends_with("。"): report_text+="。"
   event.report="\n\n".join([source_text,report_text,result_text].filter(func(text):return text!=""))
   if option.has("item_rewards"):
    g._emit("event",event.report)
    return begin_item_rewards(g,option.item_rewards)
   if option.has("encounter"):
    event.result_status="neutral"
    g._emit("event",event.report)
    return begin_battle(g,option.encounter)
   if Data.is_card_reward(option.reward):
    event.stage="reward";event.reward=g.reward_offer(Data.card_pool(option.reward))
   else:
    if option.reward=="relic":
     issue=apply_effects(g,[{"op":"relic","type":event.relic}],event.refs)
     event.report+="\n获得"+Relics.TYPES[event.relic].name+"。"
    var target=next_target(option.get("next","result"))
    if target.kind=="result": event.stage="result"
    else: issue=enter_target(g,target).issue
   g._emit("event",event.report)
  "reward":
   if p.type!="skip": issue=apply_effects(g,[{"op":"card","type":p.type}],event.refs)
   event.result_status="neutral"
   event.report="你放弃了这份报酬。" if p.type=="skip" else "获得「"+g.B.CARD_NAMES[p.type]+"」。"
   if event.next_stage!="": issue=enter_node(g,event.next_stage)
   else: event.stage="result"
  "leave":
   issue=apply_effects(g,event.get("cleanup_effects",[]),event.refs)
   if issue=="" and not event.held.is_empty(): issue="事件仍有尚未归还的装备。"
   if issue=="":
    if event.get("prepare_pending",false):
     event.erase("prepare_pending")
     g._start_preparation()
    else: g._finish_preparation()
 return issue

static func begin_item_rewards(g, rows: Array) -> String:
 var issue=item_rewards_issue(g,rows)
 if issue!="": return issue
 g.state.room_event.loot=[]
 for row in rows:
  var frozen=row.duplicate(true);frozen.claimed=false
  g.state.room_event.loot.append(frozen)
 g.state.room_event.stage="loot"
 g.state.reward_options=[]
 g.state.battle_item_drop=""
 g.state.battle_relic_drop=""
 g.state.boss_relic_options=[]
 g.state.reward_claimed={}
 g._apply_transition("event_item_rewards",{"phase":"reward"})
 return ""

static func active_item_rewards(g) -> bool:
 return g.state.phase=="reward" and g.state.room_event.get("stage","")=="loot" and g.state.room_event.has("loot")

static func item_reward_rows(g) -> Array:
 return g.state.room_event.loot if active_item_rewards(g) else []

static func claim_item_reward(g, id: String) -> String:
 if not active_item_rewards(g): return "当前没有可以领取的事件道具。"
 var rows=g.state.room_event.loot.filter(func(row):return row.id==id)
 if rows.size()!=1 or rows[0].claimed: return "这件事件道具已经无法领取。"
 if g.carried_items()>=g.item_capacity(): return "随身道具栏已满，无法拾取这件道具。"
 rows[0].claimed=true
 g._gain_tool(rows[0].type)
 return ""

static func finish_item_rewards(g) -> String:
 if not active_item_rewards(g): return "当前没有等待确认的事件道具。"
 g.state.room_event.stage="result"
 g.state.room_event.erase("loot")
 g.state.reward_claimed={}
 g._finish_preparation()
 return ""

static func battle_spec_issue(g, spec) -> String:
 if not spec is Dictionary: return "事件战斗记录不完整。"
 var required=["id","requires_defeat","victory_effects","victory_report","result_status"]
 if required.any(func(key):return not spec.has(key)): return "事件战斗记录不完整。"
 if not spec.id is String or not g.Enemies.ENCOUNTERS.has(spec.id): return "事件指定的战斗不存在。"
 if not spec.requires_defeat is bool or not spec.victory_effects is Array or spec.victory_effects.is_empty() or spec.victory_effects.size()>8: return "事件战斗的胜利条件或奖励记录不完整。"
 if not spec.victory_report is String or spec.victory_report.strip_edges()=="" or spec.result_status not in RESULT_STATUSES: return "事件战斗的胜利文案或结果标记不完整。"
 if not spec.victory_effects.all(func(effect):return g.Snapshot.effect(effect,g)): return "事件战斗包含无法恢复的胜利效果。"
 return ""

static func begin_battle(g, spec: Dictionary) -> String:
 var issue=battle_spec_issue(g,spec)
 if issue!="": return issue
 g.state.room_event.battle=spec.duplicate(true)
 g.state.room_event.battle.active=true
 g.state.room_event.stage="battle"
 g.state.room_encounters[g.state.room]=spec.id
 g._start_battle()
 return ""

static func active_battle(g) -> bool:
 return g.state.phase=="battle" and g.state.room_event.get("stage","")=="battle" and g.state.room_event.get("battle",{}).get("active",false)

static func battle_requires_defeat(g) -> bool:
 return active_battle(g) and g.state.room_event.battle.requires_defeat

static func finish_battle(g, saturated: bool=false) -> String:
 if not active_battle(g) and not (g.state.phase=="event" and g.state.room_event.get("stage","")=="battle" and g.state.room_event.get("battle",{}).get("active",false)): return "当前没有等待结算的事件战斗。"
 var event=g.state.room_event
 var battle=event.battle
 if saturated and battle.requires_defeat: return "这场战斗必须击败全部敌人。"
 var issue=apply_effects(g,battle.victory_effects,event.refs)
 if issue!="": return issue
 var result_text=describe_result(g,battle.victory_effects)
 event.stage="result"
 event.result_status=battle.result_status
 event.report=battle.victory_report+("\n\n"+result_text if result_text!="" else "")
 event.erase("battle")
 event.prepare_pending=true
 g._emit("event",event.report,{"event_battle":{"encounter":battle.id,"result":"victory"}})
 return ""

static func describe_result(g, effects: Array) -> String:
 var lines: Array[String]=[]
 for e in effects:
  match e.op:
   "special_install": lines.append(g.SpecialEquipment.wear_text(e.type))
   "pressure": lines.append("（快感+%s）" % g.number(e.amount))
   "card": lines.append("「"+g.B.CARD_NAMES[e.type]+"」已加入卡组。")
   "tool": lines.append("获得"+g.Tools.TYPES[e.type].name+"。")
   "relic": lines.append("获得"+Relics.TYPES[e.type].name+"。")
   "mana_loss": lines.append("已支付%s魔力。" % g.number(e.amount))
   "mana_gain": lines.append("魔力恢复至%s/%s。" % [g.number(g.state.mana),g.number(g.state.mana_max)])
   "mana_restore_full": lines.append("魔力恢复至%s/%s。" % [g.number(g.state.mana),g.number(g.state.mana_max)])
   "mana_max_loss": lines.append("最大魔力永久降低%s点，当前为%s；当前魔力为%s/%s。" % [g.number(e.amount),g.number(g.state.mana_max),g.number(g.state.mana),g.number(g.state.mana_max)])
   "flask_mana_gain": lines.append("贴身魔瓶获得%s魔力，当前储量%s。" % [g.number(e.amount),g.number(g.state.flask_mana)])
   "unlock": lines.append("解除了"+g._equipment(e.target).name+"的锁。")
   "tighten":
    var target=g._equipment(g.state.room_event.refs.get(e.get("ref_target",""),e.get("target","")))
    lines.append(target.name+"已加固至%d档%s。" % [g.tier(target.durability,target.maximum),"，已上锁" if target.locked else ""])
   "tighten_to":
    var target=g._equipment(e.target)
    lines.append(target.name+"已收紧至%d档。" % g.tier(target.durability,target.maximum))
   "hold_special": lines.append("指定位置原有的性玩具已暂时取下并妥善保管。")
   "restore_held": lines.append("暂存的性玩具已经原样装回。")
   # Authored selection reports already name these completed changes.
   "transform_card","remove_card","remove_restraints": pass
   "ease_restraint":
    var target=g._equipment(e.target)
    lines.append((e.get("name","所选拘束具")+"已经解除。") if target.is_empty() else (target.name+"已经松到%d档。" % g.tier(target.durability,target.maximum)))
   "counter": pass
   "install":
    var name=g.Equipment.name_for(e.template,e.slot,e.grade,e.get("variant",0))
    lines.append(g.Equipment.wear_text(name,e.slot,e.get("wear_style","assisted")))
   "assembly": lines.append(e.name+"已装好，各组件2档，"+e.part_name+"已锁。")
 return "\n".join(lines)

static func pressure_source_report(effects: Array) -> String:
 var lines: Array[String]=[]
 for effect in effects:
  if effect.get("op","")!="pressure": continue
  var line=str(effect.get("source","")).strip_edges()
  if line=="": continue
  if not line.ends_with("。"): line+="。"
  lines.append(line)
 return "\n\n".join(lines)

static func view(g) -> Dictionary:
 var e=g.state.room_event
 if e.is_empty() or g.state.phase!="event": return {}
 var spec=definition(e.id)
 var stage=node(spec,e.stage) if e.stage!="result" and node(spec,e.stage).has("title") else {}
 var name=spec.name+(" · "+stage.title if not stage.is_empty() else "")
 var intro=stage.intro if not stage.is_empty() else spec.intro
 if not stage.is_empty() and e.stage==spec.get("start_node",""): intro=spec.intro+"\n\n"+stage.intro
 # Expose selection identity, never frozen outcomes/effects. UI groups by authored
 # source choice, while every physical card/equipment keeps its original command.
 var selections=[]
 var definitions=stage.choices if not stage.is_empty() else (node(spec,e.stage).get("choices",[]) if e.stage=="choice" else [])
 if not definitions.is_empty():
  for definition in definitions:
   if not definition.has("selector"): continue
   var options=[]
   for option in e.options:
    if option.get("source_choice","")!=definition.id or not option.has("selected"): continue
    var selected=option.selected.duplicate(true)
    var selected_rows=selection_rows(selected)
    for selected_row in selected_rows:
     if selected_row.kind=="restraint":
      var item=g._equipment(selected_row.id)
      if not item.is_empty():
       selected_row.merge({"durability":item.durability,"maximum":item.maximum,"tier":g.tier(item.durability,item.maximum),"locked":item.locked,"lockable":g.Equipment.allows(item,"lock")})
    options.append({"choice":option.id,"selected":selected})
   if options.is_empty(): continue
   var kind=definition.selector.kind
   var noun="一张卡牌" if kind=="card" else "一件拘束具"
   var label=selected_text(definition.label.replace("「{name}」",noun),{"name":noun,"slot":"身上"})
   selections.append({"id":definition.id,"kind":kind,"count":int(definition.selector.get("count",1)),"label":label,"options":options})
 return {"id":e.id,"name":name,"intro":intro,"stage":e.stage,"report":e.report,"hint":"","selections":selections,"page_id":g.state.room+":"+e.id+":"+e.stage,"result_status":e.get("result_status","neutral")}

static func history_issue(state: Dictionary) -> String:
 if not state.get("event_seen") is Array or state.event_seen.any(func(id):return not id is String or id not in Data.TYPES or state.event_seen.count(id)!=1): return "已出现的事件记录不正确。"
 if state.practice: return ""
 var assigned=[]
 for room in state.rooms:
  if room.kind!="event" or not room.has("event"): continue
  if not room.event is String: return "事件房记录不正确。"
  if room.event=="": continue
  if room.event not in state.event_seen or room.event in assigned: return "事件房与已出现的事件记录不一致。"
  assigned.append(room.event)
 return ""

static func validate(g) -> String:
 var history=history_issue(g.state)
 if history!="": return history
 if not g.state.relics.all(func(id):return Relics.TYPES.has(id) and g.state.relics.count(id)==1): return "遗物重复或定义不存在。"
 if g.state.room_event.get("battle_issue","")!="": return g.state.room_event.battle_issue
 if g.state.room_event.has("prepare_pending"):
  var pending=g.state.room_event.prepare_pending
  if not pending is bool or not pending or g.state.phase!="event" or g.state.room_event.get("stage","")!="result": return "事件战后的整备进度不正确。"
 if g.state.room_event.get("stage","")=="loot":
  if not active_item_rewards(g): return "事件道具奖励阶段与当前界面不一致。"
  var loot_issue=item_rewards_issue(g,g.state.room_event.get("loot",[]),true)
  if loot_issue!="": return loot_issue
  if not g.state.reward_options.is_empty() or not g.state.boss_relic_options.is_empty() or g.state.battle_item_drop!="" or g.state.battle_relic_drop!="" or not g.state.reward_claimed.is_empty(): return "事件道具奖励混入了战斗奖励记录。"
  return ""
 if g.state.room_event.get("stage","")=="battle":
  if not active_battle(g): return "事件战斗阶段与当前行动阶段不一致。"
  var battle_issue=battle_spec_issue(g,g.state.room_event.get("battle",{}))
  if battle_issue!="": return battle_issue
  return ""
 if g.state.phase!="event": return ""
 var e=g.state.room_event
 if e.is_empty() or not Data.TYPES.has(e.get("id","")): return "事件阶段不合法。"
 if e.get("result_status","neutral") not in RESULT_STATUSES or e.options.any(func(option):return option.get("result_status","neutral") not in RESULT_STATUSES): return "事件结果标记不合法。"
 var stages=node_ids(definition(e.id))
 if e.get("stage","") not in (["reward","result"]+stages): return "事件阶段不合法。"
 if e.winner!=-1 or (e.relic!="" and not Relics.is_reward(e.relic)): return "事件结果未正确冻结。"
 if not e.get("held",{}) is Dictionary or not e.get("values",{}) is Dictionary or not e.get("cleanup_effects",[]) is Array: return "事件的暂存装备、计数或收尾效果记录不完整。"
 if e.values.keys().any(func(key):return not key is String or not e.values[key] is int or e.values[key]<0): return "事件计数记录不正确。"
 var held=[]
 for key in e.held:
  if not key is String or not e.held[key] is Array: return "事件的暂存装备记录不正确。"
  held.append_array(e.held[key])
 var held_issue=g.SpecialEquipment.validate(g.state.special_equipment+held)
 if held_issue!="": return "事件暂存装备不合法："+held_issue
 return ""

