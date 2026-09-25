extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const LiveGame=preload("res://core/game.gd")
const Catalog=preload("res://core/content_catalog.gd")
const Events=preload("res://tests/event_cases.gd")
const EnemyCases=preload("res://tests/enemy_cases.gd")
const SaveCases=preload("res://tests/persistence_cases.gd")

static func template_document(id: String) -> Dictionary:
 # The staged template stays disabled on disk, so both files are read explicitly.
 for path in ["res://content/templates/event.json","res://content/templates/event_multistage.json.disabled"]:
  var handle=FileAccess.open(path,FileAccess.READ)
  if handle==null: continue
  var data=JSON.parse_string(handle.get_as_text())
  if data is Dictionary and data.get("id","")==id: return {"file":path,"data":data}
 return {}

# docs/spec/event-pipeline.md「证据入口」: a staged node option may declare a
# registered-relic availability condition; malformed conditions stay rejected.
static func event_stage_available_condition_validates(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var document=template_document("example_multistage_challenge")
 t.check(not document.is_empty() and document.data.nodes.size()==3,"EVENT CONDITION staged template is available")
 if document.is_empty(): return
 document.data.nodes[1].choices[0].availability={"kind":"has_relic","type":"softened_buckle","reason":"你还没有拿到那件扣环。"}
 t.check(Catalog.compile(g,[document]).ok,"EVENT CONDITION staged option accepts a registered-relic condition")
 for invalid in [{"kind":"has_relic","reason":"条件不成立。"},{"kind":"has_relic","type":"unregistered_relic","reason":"条件不成立。"},{"kind":"has_relic","type":"softened_buckle","reason":"条件不成立。","extra":true},{"kind":"unknown","reason":"条件不成立。"},{"kind":"no_chastity_lock","reason":""}]:
  var bad=document.duplicate(true)
  bad.data.nodes[1].choices[0].availability=invalid
  t.check(not Catalog.compile(g,[bad]).ok,"EVENT CONDITION staged option rejects a malformed condition "+str(invalid))
 t.check(Catalog.tables(g)==baseline,"EVENT CONDITION validation leaves the registries untouched")

# docs/spec/event-pipeline.md「证据入口」: the legacy shape and incomplete node
# declarations are rejected as one batch without registering anything.
static func event_definition_form_rejects_legacy_shape(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var concise=template_document("example_travel_cache")
 var staged=template_document("example_multistage_challenge")
 t.check(not concise.is_empty() and not staged.is_empty(),"EVENT FORM templates are available")
 if concise.is_empty() or staged.is_empty(): return
 var rejected=[]
 var legacy=concise.duplicate(true)
 legacy.data["choices"]=[{"id":"old","label":"旧形态选项","reward":"none","effects":[]}]
 legacy.data["stages"]=staged.data.nodes
 rejected.append(["choices and stages together",legacy])
 var legacy_only=concise.duplicate(true)
 legacy_only.data.erase("start_node");legacy_only.data.erase("nodes")
 legacy_only.data["choices"]=[{"id":"old","label":"旧形态选项","reward":"none","effects":[]}]
 rejected.append(["legacy document without nodes",legacy_only])
 var no_start=concise.duplicate(true);no_start.data.erase("start_node")
 rejected.append(["missing start_node",no_start])
 for key in ["allow_refuse","unavailable","relic_gate","random_freeze","outcome_draw","frozen_form","empty_node"]:
  var missing=staged.duplicate(true);missing.data.nodes[0].erase(key)
  rejected.append(["node without "+key,missing])
 for reserved in ["battle","loot"]:
  var reserved_id=staged.duplicate(true);reserved_id.data.nodes[1].id=reserved
  rejected.append(["reserved node id "+reserved,reserved_id])
 var both=staged.duplicate(true)
 both.data.nodes[0].choices[0].recipe="free_basic"
 rejected.append(["recipe and effects together",both])
 for entry in rejected:
  var failed=Catalog.compile(g,[entry[1]])
  t.check(not failed.ok and failed.tables.is_empty() and Catalog.tables(g)==baseline,"EVENT FORM rejected without registering: "+entry[0])

# docs/spec/event-pipeline.md「证据入口」: the shipped content declares at most
# one state condition per option and keeps the authored compatibility spelling verbatim.
static func event_stacked_conditions_keep_current_content(t) -> void:
 var g=Game.new(42)
 var availability_sites=[]
 var when_sites=0
 var hidden_sites=0
 for id in g.Events.Data.TYPES.keys():
  var spec=g.Events.Data.TYPES[id]
  for entry in spec.nodes:
   t.check(entry.has("relic_gate") and entry.has("unavailable"),"EVENT CONDITION node keeps the declared eligibility policy "+id+"/"+str(entry.id))
   for choice in entry.choices:
    var declared=int(choice.has("availability"))+int(choice.has("when"))
    t.check(declared<=1,"EVENT CONDITION authored option declares at most one state condition "+id+"/"+str(entry.id)+"/"+str(choice.id))
    if choice.has("availability"): availability_sites.append(id+"/"+str(choice.id))
    if choice.has("when"): when_sites+=1
    if choice.get("hide_when_unavailable",false): hidden_sites+=1
 t.check(availability_sites==["floating_belt_cluster/leave","mysterious_woman_statue/use_sleeve"],"EVENT CONDITION exactly the two authored availability conditions remain")
 t.check(when_sites==11 and hidden_sites==6,"EVENT CONDITION authored instance conditions and hidden probes stay unchanged")
 var frozen_conditions=0
 for id in g.Events.Data.TYPES.keys():
  var walk=Game.new(42)
  Events.arrive(walk,id)
  var spec=walk.Events.Data.TYPES[id]
  for option in walk.state.room_event.get("options",[]):
   if not option.has("availability"): continue
   frozen_conditions+=1
   var source=str(option.get("source_choice",option.get("id","")))
   var authored=walk.Events.node(spec,spec.start_node).choices.filter(func(choice):return choice.id==source)
   t.check(authored.size()==1 and option.availability==authored[0].availability,"EVENT CONDITION frozen option keeps the authored condition "+id+"/"+source)
 t.check(frozen_conditions==1,"EVENT CONDITION the held-relic event freezes its authored condition")

# docs/spec/event-pipeline.md「证据入口」: the author manual must list the fields the
# validator actually accepts, keep pointing at the shipped templates, and never teach the
# retired definition shape.
static func event_author_manual_lists_current_fields(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var file=FileAccess.open("res://content/README.md",FileAccess.READ)
 t.check(file!=null,"EVENT MANUAL author manual is readable")
 if file==null: return
 var lines=file.get_as_text().split("\n")
 var start=-1;var end=-1
 for index in range(lines.size()):
  if lines[index].begins_with("## 3. 事件"): start=index
  elif start>=0 and lines[index].begins_with("## 4. 遗物"): end=index;break
 t.check(start>=0 and end>start,"EVENT MANUAL event section is present")
 if start<0 or end<=start: return
 var section="\n".join(lines.slice(start,end))
 t.check(not section.contains("start_stage") and not section.contains("`stages`") and not section.contains("顶层`choices`"),"EVENT MANUAL event section teaches no retired definition shape")
 t.check(section.contains("templates/event.json") and section.contains("templates/event_multistage.json.disabled"),"EVENT MANUAL event section points at both shipped templates")
 t.check(not section.contains("B2 起生效") and not section.contains("待 B2") and not section.contains("尚不可用"),"EVENT MANUAL documents no landing ability as still pending")
 # B5: the cross-event chain is current behaviour, so the manual documents its object form and
 # semantics instead of carrying a batch marker.
 t.check(section.contains('{"event"') and section.contains('"node"'),"EVENT MANUAL the cross-event next object form is documented")
 t.check(section.contains("事件链") and section.contains("`chain`") and section.contains("并集"),"EVENT MANUAL the chain semantics name the chain key and the cleanup union")
 t.check(section.contains("环") and section.contains("不能再回头"),"EVENT MANUAL the refused chain loop keeps its reason text")
 t.check(not section.contains("B4 起生效") and not section.contains("当前不接受"),"EVENT MANUAL the event-chain wording carries no pending-batch marker")
 t.check(section.contains("conditions") and section.contains("unavailable") and section.contains("mode"),"EVENT MANUAL canonical spellings are documented")
 t.check(section.contains("optional") and section.contains("hidden"),"EVENT MANUAL both condition modes are documented")
 t.check(section.contains("声明顺序"),"EVENT MANUAL reason joining follows the declaration order")
 # The manual's own tables, one entry per documented field or value token.
 var vocabulary=["allow_refuse","availability","card","choices","cleanup_effects","conditions","counter","detail","disable","ease_restraint","effects","empty_node","encounter","has_relic","hide","hidden","kind","mode","no_chastity_lock","optional","reason","type","unavailable","flask_mana_gain","free_basic","frozen_form","hide_when_unavailable","id","install","install_random","intro","item_rewards","kind","locked_assembly","mana_gain","mana_loss","mana_max_loss","mana_restore_full","name","next","nodes","op","outcome_draw","outcomes","pool","pressure","random_amount","random_freeze","recipe","relic","relic_gate","remove_card","remove_restraints","report","report_variants","result_status","schema_version","selector","show_pressure_sources","special_install","special_install_random","start_node","tighten_or_medium","tighten_random","title","tool","transform_card","unavailable","when"]
 var documented={"allow_refuse":["true","false"],"unavailable":["hide","disable"],"relic_gate":["pool","claimed"],"random_freeze":["generators","always"],"outcome_draw":["option","selection"],"frozen_form":["in_place","staged"],"empty_node":["allow","fail"]}
 var rows={}
 var tokens=[]
 for line in lines.slice(start,end):
  if not line.begins_with("| `"): continue
  var cells=line.split("|")
  if cells.size()<3: return
  var key_tokens=[];var value_tokens=[]
  for hit in RegEx.create_from_string("`([^`]+)`").search_all(cells[1]): key_tokens.append(hit.get_string(1))
  for hit in RegEx.create_from_string("`([^`]+)`").search_all(cells[2]): value_tokens.append(hit.get_string(1))
  for token in key_tokens: tokens.append(token)
  if key_tokens.size()==1: rows[key_tokens[0]]=value_tokens
 t.check(tokens.all(func(token):return token in vocabulary),"EVENT MANUAL documented fields stay inside the accepted vocabulary: "+str(tokens.filter(func(token):return token not in vocabulary)))
 for key in documented:
  t.check(rows.has(key) and rows[key]==documented[key],"EVENT MANUAL node declaration documents every accepted value: "+key+" "+str(rows.get(key)))
  for value in documented[key]:
   # Probe on the second node: the start node additionally has to stay leavable.
   var accepted=template_document("example_multistage_challenge")
   accepted.data.nodes[1][key]=value=="true" if key=="allow_refuse" else value
   t.check(Catalog.compile(g,[accepted]).ok,"EVENT MANUAL documented value is accepted by the validator: "+key+"="+value)
  var rejected=template_document("example_multistage_challenge")
  rejected.data.nodes[1][key]="retired_value"
  t.check(not Catalog.compile(g,[rejected]).ok,"EVENT MANUAL undocumented value is rejected by the validator: "+key)
 t.check(Catalog.tables(g)==baseline,"EVENT MANUAL manual review leaves the registries untouched")

# docs/spec/event-pipeline.md「证据入口」: each merged allowance keeps what
# both structures previously accepted, and nothing that used to be rejected is accepted.
static func event_union_validation_rules(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var concise=template_document("example_travel_cache")
 var staged=template_document("example_multistage_challenge")
 t.check(not concise.is_empty() and not staged.is_empty(),"EVENT UNION templates are available")
 if concise.is_empty() or staged.is_empty(): return
 var twelve=concise.duplicate(true)
 twelve.data.nodes[0].choices[0].effects=[]
 for _index in range(12): twelve.data.nodes[0].choices[0].effects.append({"op":"pressure","amount":1,"source":"夹具来源"})
 t.check(Catalog.compile(g,[twelve]).ok,"EVENT UNION twelve effects accepted on a single node")
 var thirteen=twelve.duplicate(true)
 thirteen.data.nodes[0].choices[0].effects.append({"op":"pressure","amount":1,"source":"夹具来源"})
 t.check(not Catalog.compile(g,[thirteen]).ok,"EVENT UNION thirteen effects rejected on a single node")
 var empty_effects=staged.duplicate(true)
 empty_effects.data.nodes[2].choices[0].effects=[];empty_effects.data.nodes[2].choices[0].reward="common"
 t.check(Catalog.compile(g,[empty_effects]).ok,"EVENT UNION empty effects with a card reward accepted on a staged node")
 var only_outcomes=staged.duplicate(true)
 only_outcomes.data.nodes[1].choices[0].erase("effects")
 only_outcomes.data.nodes[1].choices[0].detail="两种公开结果之一。"
 only_outcomes.data.nodes[1].choices[0].outcomes=[{"weight":1,"effects":[{"op":"pressure","amount":1,"source":"夹具来源"}]},{"weight":1,"effects":[{"op":"pressure","amount":2,"source":"夹具来源"}]}]
 t.check(Catalog.compile(g,[only_outcomes]).ok,"EVENT UNION outcomes without effects or recipe accepted")
 var held=concise.duplicate(true)
 held.data.nodes[0].choices[0].effects=[{"op":"hold_special","key":"packed_toys","slots":["special_2_a"]}]
 held.data.cleanup_effects=[{"op":"restore_held","key":"packed_toys"}]
 t.check(Catalog.compile(g,[held]).ok,"EVENT UNION single node may hold and restore special equipment when cleanup balances")
 var unpaired=concise.duplicate(true)
 unpaired.data.nodes[0].choices[0].effects=[{"op":"hold_special","key":"packed_toys","slots":["special_2_a"]}]
 t.check(not Catalog.compile(g,[unpaired]).ok,"EVENT UNION single node holding without cleanup is rejected")
 var wrong_id=concise.duplicate(true);wrong_id.data.nodes[0].id="room";wrong_id.data.start_node="room"
 t.check(not Catalog.compile(g,[wrong_id]).ok,"EVENT UNION a single node must use the choice sentinel id")
 var rewarded_next=staged.duplicate(true)
 rewarded_next.data.nodes[1].choices[0].reward="common";rewarded_next.data.nodes[1].choices[0].next="finish"
 t.check(not Catalog.compile(g,[rewarded_next]).ok,"EVENT UNION a rewarded option must end the event")
 t.check(Catalog.tables(g)==baseline,"EVENT UNION validation leaves the registries untouched")

# docs/spec/event-pipeline.md「证据入口」: a cross-event next has to name
# a registered event and one of its real nodes, and may never reference its own event.
static func event_chain_references_fail_closed(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var source=template_document("example_multistage_challenge")
 t.check(not source.is_empty() and source.data.nodes.size()==3,"EVENT CHAIN templates are available")
 if source.is_empty(): return
 var target=source.duplicate(true)
 target.data.id="example_chain_target"
 # A33: hold keys are unique on the whole chain, so the duplicated definition declares a key
 # of its own instead of reusing the source's.
 target.data.nodes[0].choices[0].effects[0].key="removed_gear_target"
 target.data.cleanup_effects=[{"op":"restore_held","key":"removed_gear_target"}]
 source.data.nodes[1].choices[0].next={"event":"example_chain_target","node":"entry"}
 var accepted=Catalog.compile(g,[source,target])
 t.check(accepted.ok,"EVENT CHAIN a registered event node is accepted: "+str(accepted.errors))
 var rejected=[]
 var self_reference=source.duplicate(true)
 self_reference.data.nodes[1].choices[0].next={"event":"example_multistage_challenge","node":"finish"}
 rejected.append(["self reference",self_reference])
 var unknown_event=source.duplicate(true)
 unknown_event.data.nodes[1].choices[0].next={"event":"no_such_event","node":"entry"}
 rejected.append(["unregistered event",unknown_event])
 var unknown_node=source.duplicate(true)
 unknown_node.data.nodes[1].choices[0].next={"event":"example_chain_target","node":"no_such_node"}
 rejected.append(["missing target node",unknown_node])
 var short_form=source.duplicate(true)
 short_form.data.nodes[1].choices[0].next={"event":"example_chain_target"}
 rejected.append(["missing node field",short_form])
 var extra_key=source.duplicate(true)
 extra_key.data.nodes[1].choices[0].next={"event":"example_chain_target","node":"entry","stage":"penalty"}
 rejected.append(["extra field",extra_key])
 var wrong_type=source.duplicate(true)
 wrong_type.data.nodes[1].choices[0].next={"event":"example_chain_target","node":42}
 rejected.append(["non-string node",wrong_type])
 for entry in rejected:
  var failed=Catalog.compile(g,[entry[1],target])
  t.check(not failed.ok and failed.tables.is_empty() and Catalog.tables(g)==baseline,"EVENT CHAIN rejected without registering: "+entry[0])
 t.check(Catalog.tables(g)==baseline,"EVENT CHAIN static validation leaves the registries untouched")

# docs/spec/event-pipeline.md「证据入口」: a hold key has to stay unique along the
# whole chain, so a package whose jump path reuses a key — or whose cleanup names another
# definition's key — is rejected as one batch before anything is registered. The runtime guard
# ("同一保管位置不能重复使用。") stays untouched as the second line of defence.
static func event_chain_hold_keys_fail_closed(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var source=template_document("example_multistage_challenge")
 t.check(not source.is_empty() and source.data.nodes.size()==3,"EVENT CHAIN HOLD templates are available")
 if source.is_empty(): return
 # The target is duplicated before the source gains its jump, so the target keeps no jump of
 # its own and the package never trips the self-reference rule.
 var target=source.duplicate(true)
 target.data.id="example_chain_hold_target"
 target.data.nodes[0].choices[0].effects[0].key="target_only_gear"
 target.data.cleanup_effects=[{"op":"restore_held","key":"target_only_gear"}]
 source.data.nodes[1].choices[0].next={"event":"example_chain_hold_target","node":"entry"}
 var accepted=Catalog.compile(g,[source,target])
 t.check(accepted.ok,"EVENT CHAIN HOLD one key per definition along the jump is accepted: "+str(accepted.errors))
 var clash=target.duplicate(true)
 clash.data.nodes[0].choices[0].effects[0].key="removed_gear"
 clash.data.cleanup_effects=[{"op":"restore_held","key":"removed_gear"}]
 var reused=Catalog.compile(g,[source,clash])
 t.check(not reused.ok and reused.tables.is_empty() and str(reused.errors).contains("事件链上重复使用了暂存 key") and Catalog.tables(g)==baseline,"EVENT CHAIN HOLD a key reused across the jump is rejected as one batch: "+str(reused.errors))
 var foreign=target.duplicate(true)
 foreign.data.nodes[0].choices[0].effects=[]
 foreign.data.cleanup_effects=[{"op":"restore_held","key":"removed_gear"}]
 var borrowed=Catalog.compile(g,[source,foreign])
 t.check(not borrowed.ok and borrowed.tables.is_empty() and str(borrowed.errors).contains("cleanup_effects 引用了从未建立的暂存 key") and Catalog.tables(g)==baseline,"EVENT CHAIN HOLD a cleanup naming another definition's key is rejected as one batch: "+str(borrowed.errors))
 t.check(Catalog.tables(g)==baseline,"EVENT CHAIN HOLD static validation leaves the registries untouched")

# The pack root is one constant behind one accessor: the development value is the project path,
# the release value "adjacent" resolves beside the executable. The release branch cannot be
# entered while the constant holds the development value, so its shape is pinned in the source.
static func packs_root_single_switch(t) -> void:
 t.check(Catalog.PACKS_ROOT=="res://content/packs","PACK ROOT the constant keeps the development value res://content/packs")
 t.check(Catalog.packs_root()==Catalog.PACKS_ROOT,"PACK ROOT a value other than adjacent is used as the pack root itself: "+Catalog.packs_root())
 var file=FileAccess.open("res://core/content_catalog.gd",FileAccess.READ)
 t.check(file!=null,"PACK ROOT the content catalog is readable for the release-branch scan")
 if file==null: return
 var source=file.get_as_text()
 t.check(source.contains("PACKS_ROOT==\"adjacent\"") and source.contains("OS.get_executable_path().get_base_dir().path_join(\"content/packs\")"),"PACK ROOT adjacent resolves to content/packs beside the executable")

static func run(t) -> void:
 packs_root_single_switch(t)
 event_author_manual_lists_current_fields(t)
 event_chain_references_fail_closed(t)
 event_chain_hold_keys_fail_closed(t)
 event_stage_available_condition_validates(t)
 event_definition_form_rejects_legacy_shape(t)
 event_stacked_conditions_keep_current_content(t)
 event_union_validation_rules(t)
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var input=Catalog.read_directory("res://content/templates")
 t.check(input.errors.is_empty() and input.documents.size()==5,"PACK five on-disk UTF8 JSON templates")
 if input.documents.size()!=5: return
 for document in input.documents:
  var single=Catalog.compile(g,[document])
  t.check(single.ok,"PACK each template works alone: "+document.file+" "+str(single.errors))
 var result=Catalog.compile(g,input.documents)
 t.check(result.ok and Catalog.tables(g)==baseline,"PACK staging is read-only and templates resolve: "+str(result.errors))
 if not result.ok: return
 var shuffled=input.documents.duplicate(true);shuffled.reverse()
 t.check(Catalog.compile(g,shuffled).tables==result.tables,"PACK file order does not change definitions")
 var invalids=[]
 var concise_event=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 concise_event.data.nodes[0].choices[0].detail=""
 var concise_result=Catalog.compile(g,[concise_event])
 t.check(concise_result.ok and concise_result.tables.event[concise_event.data.id].nodes[0].choices[0].detail=="" and Catalog.tables(g)==baseline,"PACK explicit empty event detail survives loading without changing rules or registries")
 var conditional_event=concise_event.duplicate(true)
 conditional_event.data.nodes[0].choices[0].availability={"kind":"no_chastity_lock","reason":"平板锁封住了肉棒，无法使用这项服务。"}
 var conditional_result=Catalog.compile(g,[conditional_event])
 t.check(conditional_result.ok and conditional_result.tables.event[conditional_event.data.id].nodes[0].choices[0].availability==conditional_event.data.nodes[0].choices[0].availability and Catalog.tables(g)==baseline,"PACK event choice accepts one validated state-dependent availability condition")
 var relic_condition=concise_event.duplicate(true)
 relic_condition.data.nodes[0].choices[0].availability={"kind":"has_relic","type":"softened_buckle","reason":"你还没有拿到那件扣环。"}
 var relic_result=Catalog.compile(g,[relic_condition])
 t.check(relic_result.ok and relic_result.tables.event[relic_condition.data.id].nodes[0].choices[0].availability==relic_condition.data.nodes[0].choices[0].availability and Catalog.tables(g)==baseline,"PACK event choice accepts a registered-relic availability condition")
 for invalid_availability in [null,{},false,{"kind":"unknown","reason":"无法选择。"},{"kind":"no_chastity_lock","reason":""},{"kind":"no_chastity_lock","reason":"[invalid]"},{"kind":"no_chastity_lock","reason":"无法选择。","extra":true},{"kind":"has_relic","reason":"无法选择。"},{"kind":"has_relic","type":"unregistered_relic","reason":"无法选择。"},{"kind":"has_relic","type":"softened_buckle","reason":"无法选择。","extra":true}]:
  var bad=concise_event.duplicate(true);bad.data.nodes[0].choices[0].availability=invalid_availability;invalids.append(bad)
 var animated_event=concise_event.duplicate(true)
 animated_event.data.nodes[0].choices[0].effects=[{"op":"install_random","templates":["rope"],"count":1,"grade":1,"tier":2,"locked":false,"allow_links":false,"wear_style":"animated"}]
 t.check(Catalog.compile(g,[animated_event]).ok and Catalog.tables(g)==baseline,"PACK random restraint installation accepts the reusable animated wear style")
 for invalid_style in ["unknown",0,false]:
  var bad=animated_event.duplicate(true);bad.data.nodes[0].choices[0].effects[0].wear_style=invalid_style;invalids.append(bad)
 for invalid_detail in [null,0,false,"   ","[invalid]","x".repeat(1201)]:
  var bad=concise_event.duplicate(true);bad.data.nodes[0].choices[0].detail=invalid_detail;invalids.append(bad)
 var unspent=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 unspent.data.modifiers={"unspent_turn_mana":8}
 t.check(Catalog.compile(g,[unspent]).ok,"PACK unspent-turn mana hook supported")
 unspent.data.modifiers.unspent_turn_mana=101
 t.check(not Catalog.compile(g,[unspent]).ok,"PACK unspent-turn mana hook is bounded")
 var helper=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 var gift_relic=helper.duplicate(true)
 gift_relic.data.modifiers={};gift_relic.data.pickup_cards=["magic_hand_gift"]
 var gift_result=Catalog.compile(g,[gift_relic])
 t.check(gift_result.ok and gift_result.tables.relic[gift_relic.data.id].pickup_cards==["magic_hand_gift"] and Catalog.tables(g)==baseline,"PACK pickup gift cards compile without altering current tables")
 for cards in [[],"magic_hand_gift",["missing_card"],["tease"],[false]]:
  var bad=gift_relic.duplicate(true);bad.data.pickup_cards=cards;invalids.append(bad)
 var shop_relic=helper.duplicate(true)
 shop_relic.data.rarity="uncommon";shop_relic.data.shop_only=true;shop_relic.data.shop_payment="flask"
 shop_relic.data.modifiers={"pickup_mana_max":10,"pickup_mana_full":1}
 var shop_result=Catalog.compile(g,[shop_relic])
 t.check(shop_result.ok and shop_result.tables.relic[shop_relic.data.id].shop_payment=="flask" and shop_relic.data.id not in shop_result.tables.rewards,"PACK shop-exclusive payment and full-mana pickup preserve their source restriction")
 for changes in [{"shop_only":"true"},{"shop_payment":"both"},{"shop_only":false},{"modifiers":{"pickup_mana_full":2}}]:
  var bad=shop_relic.duplicate(true);bad.data.merge(changes,true);invalids.append(bad)
 helper.data.modifiers={"unrestricted_items":1}
 t.check(Catalog.compile(g,[helper]).ok,"PACK unrestricted item flag supported")
 helper.data.modifiers.unrestricted_items=2
 t.check(not Catalog.compile(g,[helper]).ok,"PACK unrestricted item flag rejects non-boolean magnitude")
 var flyer=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 flyer.data.modifiers={"shop_flask_mana":20}
 t.check(Catalog.compile(g,[flyer]).ok,"PACK generic shop flask mana modifier accepted")
 flyer.data.modifiers.shop_flask_mana=101
 t.check(not Catalog.compile(g,[flyer]).ok,"PACK shop flask mana rejects out-of-range amount")
 var collectible=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 collectible.data.modifiers={};collectible.data.rarity="special";collectible.data.collectible=true
 var collectible_result=Catalog.compile(g,[collectible])
 t.check(collectible_result.ok and collectible_result.tables.relic[collectible.data.id].collectible and collectible.data.id not in collectible_result.tables.rewards,"PACK special no-effect collectibles use shared loader without entering normal pool")
 var cloak=collectible.duplicate(true);cloak.data.rarity="common";cloak.data.modifiers={"card_mana_discount":1}
 var cloak_result=Catalog.compile(g,[cloak])
 t.check(cloak_result.ok and cloak_result.tables.relic[cloak.data.id].collectible and cloak.data.id in cloak_result.tables.rewards,"PACK common mana-discount collectible uses the shared counted contract")
 var bad_cloak=cloak.duplicate(true);bad_cloak.data.modifiers.card_mana_discount=2;invalids.append(bad_cloak)
 for changes in [{"collectible":"true"},{"rarity":"common"},{"modifiers":{"strength":1}},{"card_base_bonuses":{"strain":4}}]:
  var bad=collectible.duplicate(true);bad.data.merge(changes,true);invalids.append(bad)
 var card_relic=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 card_relic.data.modifiers={};card_relic.data.card_base_bonuses={"strain":4,"slip":4}
 var card_result=Catalog.compile(g,[card_relic])
 t.check(card_result.ok and card_result.tables.relic[card_relic.data.id].card_base_bonuses=={"strain":4,"slip":4} and Catalog.tables(g)==baseline,"PACK targeted card-base relic uses shared read-only loader")
 for bonuses in [{},{"missing":4},{"panic":4},{"strain":0},{"strain":101},{"strain":1.5},{"strain":"4"},[]]:
  var bad=card_relic.duplicate(true);bad.data.card_base_bonuses=bonuses;invalids.append(bad)
 var triggered=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 triggered.data.modifiers={}
 triggered.data.trigger={"event":"magic_paid","scope":"battle","phase":"battle","op":"mana","ratio":0.25}
 var compiled_trigger=Catalog.compile(g,[triggered])
 t.check(compiled_trigger.ok and compiled_trigger.tables.relic[triggered.data.id].trigger.ratio==0.25 and Catalog.tables(g)==baseline,"PACK generic relic trigger compiles without mutation")
 t.check(compiled_trigger.tables.relic[triggered.data.id].rarity==triggered.data.rarity,"PACK relic rarity survives compilation")
 var missing_rarity=triggered.duplicate(true);missing_rarity.data.erase("rarity");invalids.append(missing_rarity)
 var volley=triggered.duplicate(true)
 volley.data.trigger={"event":"turn_end","scope":"battle","phase":"battle","round":7.0,"op":"fixed_enemy_damage","amount":77.0}
 var volley_result=Catalog.compile(g,[volley])
 t.check(volley_result.ok and volley_result.tables.relic[volley.data.id].trigger.round==7 and Catalog.tables(g)==baseline,"PACK configured seventh-turn fixed damage compiles through existing relic template")
 for changes in [{"round":0},{"round":7.5},{"scope":"turn"},{"phase":"rest"},{"event":"fell"}]:
  var bad=volley.duplicate(true);bad.data.trigger.merge(changes,true);invalids.append(bad)
 var bad_rarity=triggered.duplicate(true);bad_rarity.data.rarity="legendary";invalids.append(bad_rarity)
 for changes in [{"op":"unknown"},{"ratio":1.5},{"extra":true},{"event":"unknown"},{"amount":2}]:
  var bad=triggered.duplicate(true);bad.data.trigger.merge(changes,true);invalids.append(bad)
 for document in input.documents:
  var bad=document.duplicate(true);bad.data.extra_unsupported=true;invalids.append(bad)
 var duplicate=input.documents[0].duplicate(true)
 var duplicates=input.documents.duplicate(true);duplicates.append(duplicate)
 t.check(not Catalog.compile(g,duplicates).ok and Catalog.tables(g)==baseline,"PACK duplicate rejects entire batch without registry mutation")
 for changes in [{"enemy_sources":["missing_enemy"]},{"slots":["mouth"]},{"slots":["wrist","wrist"]},{"base_template":"glove_body"}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="restraint")[0].duplicate(true)
  bad.data.merge(changes,true);invalids.append(bad)
 for changes in [{"energy_gain":-1},{"duration":1.5},{"turn_gain":0},{"design":{"grade":4}},{"design":{"slots":["wrist"]}}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="special_equipment")[0].duplicate(true)
  bad.data.merge(changes,true);invalids.append(bad)
 var missing_wear=input.documents.filter(func(d):return d.data.kind=="special_equipment")[0].duplicate(true)
 missing_wear.data.erase("wear_text");invalids.append(missing_wear)
 var unnamed_wear=input.documents.filter(func(d):return d.data.kind=="special_equipment")[0].duplicate(true)
 unnamed_wear.data.wear_text="把这件玩具戴好。";invalids.append(unnamed_wear)
 for changes in [{"modifiers":{"magic_refund":0.5}},{"modifiers":{"capacity":1.5}},{"modifiers":{}}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
  bad.data.merge(changes,true);invalids.append(bad)
 for changes in [{"strength":0},{"strength":3},{"strength":1.5},{"hp":0},{"hp":3.5},{"encounter":{"rank":"elite","grade":1}},{"strength":1,"base_enemy":"invented"}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="enemy")[0].duplicate(true)
  bad.data.merge(changes,true);invalids.append(bad)
 for effect in [{"op":"arbitrary_script"},{"op":"relic","type":"missing"},{"op":"flask_mana_gain","amount":101},{"op":"random_amount","effect":"flask_mana_gain","minimum":60,"maximum":30},{"op":"random_amount","effect":"relic","minimum":30,"maximum":60},{"op":"mana_max_loss","amount":0},{"op":"mana_restore_full","amount":1},{"op":"install","template":"rope","slot":"wrist","grade":1.5,"tier":1,"locked":false},{"op":"tool","type":"saw","ignored":true},{"op":"special_install","type":"shaft_ring_low","slot":"wrist"}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
  bad.data.nodes[0].choices[0].effects=[effect];invalids.append(bad)
 var bad_encounter=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_encounter.data.nodes[0].choices[0].effects=[]
 bad_encounter.data.nodes[0].choices[0].encounter={"id":"missing_encounter","requires_defeat":true,"victory_effects":[{"op":"card","type":"panic"}],"victory_report":"战斗结束。","result_status":"success"}
 invalids.append(bad_encounter)
 var bad_victory_effect=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_victory_effect.data.nodes[0].choices[0].effects=[]
 bad_victory_effect.data.nodes[0].choices[0].encounter={"id":"belt_solo","requires_defeat":true,"victory_effects":[{"op":"arbitrary_script"}],"victory_report":"战斗结束。","result_status":"success"}
 invalids.append(bad_victory_effect)
 var bad_item_rewards=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_item_rewards.data.nodes[0].choices[0].effects=[]
 bad_item_rewards.data.nodes[0].choices[0].item_rewards=[{"id":"potion","pool":["missing_item"]}]
 invalids.append(bad_item_rewards)
 var duplicate_item_groups=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 duplicate_item_groups.data.nodes[0].choices[0].effects=[]
 duplicate_item_groups.data.nodes[0].choices[0].item_rewards=[{"id":"same","pool":["mana_potion"]},{"id":"same","pool":["draw_scroll"]}]
 invalids.append(duplicate_item_groups)
 var bad_refusal=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_refusal.data.nodes[0].allow_refuse="false";invalids.append(bad_refusal)
 var bad_hidden=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_hidden.data.nodes[0].choices[0].hide_when_unavailable="true";invalids.append(bad_hidden)
 for selector in [{"kind":"restraint","count":0},{"kind":"card","include_special":false},{"kind":"restraint","exclude_curses":true}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
  bad.data.nodes[0].choices[0].selector=selector
  bad.data.nodes[0].choices[0].effects=[{"op":"remove_restraints","targets":"$selected"}]
  invalids.append(bad)
 var bad_multi_effect=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_multi_effect.data.nodes[0].choices[0].selector={"kind":"restraint","count":2}
 bad_multi_effect.data.nodes[0].choices[0].effects=[{"op":"remove_restraints","targets":["invented"]}]
 invalids.append(bad_multi_effect)
 for document in input.documents:
  for field in document.data:
   for invalid_value in [null,[],{},true]:
    var bad=document.duplicate(true);bad.data[field]=invalid_value
    # Empty design is a valid optional override; templates do not supply it.
    var rejected=Catalog.compile(g,[bad])
    t.check(not rejected.ok and Catalog.tables(g)==baseline,"PACK wrong field type: "+document.data.kind+"."+field+" "+str(invalid_value))
 for bad in invalids:
  var failed=Catalog.compile(g,[bad])
  t.check(not failed.ok and failed.tables.is_empty() and str(failed.errors).contains(bad.file) and Catalog.tables(g)==baseline,"PACK invalid field/reference fails closed: "+str(bad.data))
 # Corrupt JSON and nested file ordering exercise the same disk reader used at startup.
 var folder="user://content_case_"+str(Time.get_ticks_usec())
 DirAccess.make_dir_recursive_absolute(folder+"/nested")
 var file=FileAccess.open(folder+"/broken.json",FileAccess.WRITE);file.store_string("{ broken");file.close()
 var disk=Catalog.read_directory(folder)
 t.check(disk.errors.size()==1 and str(disk.errors).contains("broken.json"),"PACK malformed JSON reports filename/line")
 DirAccess.remove_absolute(folder+"/broken.json")
 file=FileAccess.open(folder+"/nested/good.json",FileAccess.WRITE);file.store_string(JSON.stringify(input.documents[0].data));file.close()
 disk=Catalog.read_directory(folder)
 t.check(disk.errors.is_empty() and disk.documents.size()==1 and Catalog.compile(g,disk.documents).ok,"PACK nested drop-in file reads and validates")
 var old_report=Catalog.report.duplicate(true);var old_loaded=Catalog.loaded
 Catalog.loaded=false;Catalog.ensure(g,folder)
 t.check(Catalog.report.ok and Catalog.report.files==1 and Catalog.tables(g)!=baseline,"PACK bootstrap reads and atomically installs actual files")
 var bootstrapped=Catalog.tables(g);Catalog.ensure(g,folder)
 t.check(Catalog.tables(g)==bootstrapped,"PACK repeated Game creation never registers duplicates")
 Catalog.commit(g,baseline)
 file=FileAccess.open(folder+"/broken.json",FileAccess.WRITE);file.store_string("{}");file.close()
 Catalog.loaded=false;Catalog.ensure(g,folder)
 t.check(not Catalog.report.ok and Catalog.tables(g)==baseline,"PACK one malformed record prevents entire bootstrap batch")
 DirAccess.remove_absolute(folder+"/broken.json")
 Catalog.report=old_report;Catalog.loaded=old_loaded
 DirAccess.remove_absolute(folder+"/nested/good.json");DirAccess.remove_absolute(folder+"/nested");DirAccess.remove_absolute(folder)

 # Independent content references resolve after the entire batch is staged.
 var documents=input.documents.duplicate(true)
 var event=documents.filter(func(d):return d.data.kind=="event")[0].data
 event.nodes[0].choices[0].effects.append({"op":"relic","type":"example_spare_pocket"})
 event.nodes[0].choices[0].effects.append({"op":"install","template":"example_soft_belt","slot":"ankle","grade":1,"tier":1,"locked":false})
 var restraint=documents.filter(func(d):return d.data.kind=="restraint")[0].data
 restraint.enemy_sources.append("example_patrol_rope")
 restraint.slots.append("upper_arm")
 event.nodes[0].choices.append({"id":"arm_fit","label":"安装大臂皮带","reward":"none","effects":[{"op":"install","template":"example_soft_belt","slot":"upper_arm","grade":3,"tier":3,"locked":false}]})
 result=Catalog.compile(g,documents)
 t.check(result.ok,"PACK cross-file references compile without ordering requirements")
 if not result.ok: return
 Catalog.commit(g,result.tables)
 var found_event=false;var found_enemy=false;var found_special=false
 for seed_value in range(24):
  var live=LiveGame.new(seed_value)
  t.check(live.state.rooms==LiveGame.new(seed_value).state.rooms,"PACK normal tower remains seeded deterministic")
  for room in live.state.rooms:
   if room.kind!="event": continue
   live.state.room=room.id
   live.Events.start(live)
   found_event=found_event or room.event=="example_travel_cache"
   found_special=found_special or room.event=="example_vibration_ring_arrival"
  found_enemy=found_enemy or live.Enemies.FirstFloor.roll(live).any(func(m):return m.type=="example_patrol_rope")
 t.check(found_event and found_special and found_enemy,"PACK authored events and special sources occur on arrival; enemies join real encounters")
 t.check("example_spare_pocket" in g.Relics.REWARDS and "example_soft_belt" in g.Enemies.TYPES.belt.install_pool,"PACK sources join real reward and enemy pools")

 g=Game.new(42);Events.arrive(g,"example_travel_cache")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"PACK imported event previews do not mutate state/RNG")
 var c=t.find_action(g,"event",{"action":"choose","choice":"take_tool"})
 t.check(c.valid and c.detail.contains("支付5") and c.detail.contains("备用口袋"),"PACK all costs/rewards projected before choosing")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"PACK stale event command is atomic")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"PACK imported event executes through formal transaction")
 t.check(g.state.mana==95 and g.state.items[0].type=="saw" and "example_spare_pocket" in g.state.relics and g.state.equipment[0].template=="example_soft_belt","PACK event actually pays/grants/installs")
 t.check(g.item_capacity()==4 and g.escape_preview(g.state.equipment[0],"strain",5).damage>0,"PACK relic modifier and restraint escape participate in rules")
 SaveCases.roundtrip(t,g,"imported event, equipment and relic")
 var saved=g.export_snapshot()
 Catalog.commit(g,baseline)
 var without=Game.new(42);before=without.export_snapshot()
 t.check(not without.restore_snapshot(saved).ok and without.state==before,"PACK missing definitions reject restore without dropping equipment")
 Catalog.commit(g,result.tables)
 g=Game.new(42);g.state.mana=4;Events.arrive(g,"example_travel_cache");before=g.export_snapshot()
 c=t.find_action(g,"event",{"action":"choose","choice":"take_tool"})
 t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"PACK insufficient payment prevents all rewards atomically")

 g=Game.new(42);Events.arrive(g,"example_vibration_ring_arrival")
 t.check(t.action(g,"event",{"action":"choose","choice":"equip"}).ok and g.state.special_equipment.size()==1,"PACK special acquired by normal event command")
 t.check(g.state.room_event.report.contains("试制硅胶柱身震动环") and g.state.room_event.report.contains("沿着龟头缓缓套到柱身中段") and g.state.special_equipment[0].remaining==3,"PACK special acquisition uses authored reusable wear prose and accurate duration")
 SaveCases.roundtrip(t,g,"imported special event effect")
 g.state.room="entrance";g._start_battle()
 t.check(g.state.special_equipment[0].remaining==2 and is_equal_approx(g.state.pressure,1.2),"PACK special applies inherited shaft sensitivity on real player turn start")
 t.check(t.action(g,"attack",{"type":"heavy"}).ok and is_equal_approx(g.state.pressure,3.0),"PACK special energy effect triggers once for multi-energy action")
 t.action(g,"end");t.action(g,"end")
 t.check(g.state.special_equipment.size()==1 and g.state.special_equipment[0].remaining==0,"PACK powered special remains installed after its battery expires")
 before=g.export_snapshot();var amount=g.state.pressure
 g._tick_special("energy")
 t.check(g.state.pressure==amount,"PACK expired imported special no longer applies an energy-paid pulse")
 g.state=before
 Events.arrive(g,"example_vibration_ring_arrival");before=g.export_snapshot()
 c=t.find_action(g,"event",{"action":"choose","choice":"equip"})
 t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"PACK special occupied slot rejects duplicate without mutation")
 SaveCases.roundtrip(t,g,"expired imported special")

 g=Game.new(42);Events.arrive(g,"example_travel_cache")
 t.check(t.action(g,"event",{"action":"choose","choice":"arm_fit"}).ok,"PACK high-tier arm variant installs by formal event")
 t.check(g.state.equipment[0].shoulders.pieces.size()==2 and g.Shoulders.eligible(g.state.equipment[0]) and g.Binding.present(g.state.equipment[0]),"PACK ordinary variant inherits shoulder pair and torso attachment rules")
 t.check(g.Shoulders.slip_reason(g,g.state.equipment[0])!="" and g.validate()=="","PACK imported shoulder pair blocks body slip through original rules")
 SaveCases.roundtrip(t,g,"imported arm restraint and automatic shoulders")
 var installed=false
 for seed_value in range(16):
  g=EnemyCases.encounter("example_patrol_rope_encounter",seed_value)
  t.check(g.state.enemies[0].name=="巡游绳索" and g.state.enemies[0].hp==16,"PACK enemy uses authored name and health")
  t.check(t.action(g,"end").ok and g.state.equipment.size()==1,"PACK new enemy executes inherited behavior")
  installed=installed or g.state.equipment[0].template=="example_soft_belt"
 t.check(installed,"PACK new enemy actually installs new restraint from authored pool")
 SaveCases.roundtrip(t,g,"imported enemy intent")
 Catalog.commit(g,baseline)
 t.check(Catalog.tables(g)==baseline,"PACK tests restore all registries")
