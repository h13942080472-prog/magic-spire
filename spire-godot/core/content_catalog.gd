extends RefCounted

# Bootstrap only. Content compiles into the existing registries, never a second rules engine.
static var loaded=false
static var report={"ok":true,"files":0,"errors":[],"directory":""}
const KINDS=["restraint","special_equipment","event","relic","enemy"]
const BASES=["rope","cord","belt","fine_belt","tape","cable_tie"]
const ENEMY_BASES=["rope","belt","tape","cable_tie","gag","toybox","lock"]
# Development value: editor runs, headless tests and the Android package read the project copy.
# The release value is "adjacent" (content packs sit next to the executable, outside the PCK);
# packaging must flip this constant to "adjacent" and flip it back afterwards. See
# docs/spec/packaging.md.
const PACKS_ROOT := "res://content/packs"

# Single read point for the pack root: consumers import this and no other file computes a packs
# path. "adjacent" is the packaging value; every other value is the path itself.
static func packs_root() -> String:
 if PACKS_ROOT=="adjacent": return OS.get_executable_path().get_base_dir().path_join("content/packs")
 return PACKS_ROOT

static func ensure(g, root: String="") -> void:
 if loaded: return
 loaded=true
 var path=packs_root() if root=="" else root
 var result=read_directory(path)
 if result.errors.is_empty():
  var compiled=compile(g,result.documents)
  result.errors=compiled.errors
  if compiled.ok: commit(g,compiled.tables)
 report={"ok":result.errors.is_empty(),"files":result.documents.size(),"errors":result.errors,"directory":path}

static func tables(g) -> Dictionary:
 return {"restraint":g.Equipment.TEMPLATES.duplicate(true),"special_equipment":g.SpecialEquipment.TYPES.duplicate(true),"designs":g.SpecialEquipment.DESIGNS.duplicate(true),"event":g.Events.Data.TYPES.duplicate(true),"relic":g.Relics.TYPES.duplicate(true),"rewards":g.Relics.REWARDS.duplicate(),"enemy":g.Enemies.TYPES.duplicate(true),"encounters":g.Enemies.ENCOUNTERS.duplicate(true),"pools":g.Enemies.FirstFloor.POOLS.duplicate(true)}

static func commit(g, data: Dictionary) -> void:
 g.Equipment.TEMPLATES=data.restraint
 g.SpecialEquipment.TYPES=data.special_equipment;g.SpecialEquipment.DESIGNS=data.designs
 g.Events.Data.TYPES=data.event;g.Relics.TYPES=data.relic;g.Relics.REWARDS=data.rewards
 g.Enemies.TYPES=data.enemy;g.Enemies.ENCOUNTERS=data.encounters;g.Enemies.FirstFloor.POOLS=data.pools

static func read_directory(path: String) -> Dictionary:
 var result={"documents":[],"errors":[]}
 if not DirAccess.dir_exists_absolute(path): return result
 _read(path,result,0)
 return result

static func _read(path: String, result: Dictionary, depth: int) -> void:
 if depth>8:
  result.errors.append(path+": 文件夹嵌套不能超过8层。");return
 var folder=DirAccess.open(path)
 if folder==null:
  result.errors.append(path+": 无法读取文件夹。");return
 var files=folder.get_files();files.sort()
 for file in files:
  if file.get_extension().to_lower()!="json": continue
  var full=path.path_join(file)
  if result.documents.size()>=256:
   result.errors.append(full+": 内容文件不能超过256个。");return
  var input=FileAccess.open(full,FileAccess.READ)
  if input==null:
   result.errors.append(full+": 无法读取文件。");continue
  if input.get_length()>1048576:
   result.errors.append(full+": 单个文件不能超过1MB。");continue
  var parser=JSON.new()
  if parser.parse(input.get_as_text())!=OK:
   result.errors.append(full+": 第%d行：%s" % [parser.get_error_line(),parser.get_error_message()]);continue
  result.documents.append({"file":full,"data":parser.data})
 var folders=folder.get_directories();folders.sort()
 for sub in folders:
  if not sub.begins_with("."): _read(path.path_join(sub),result,depth+1)

static func shape(value, required: String, optional: String="") -> String:
 if not value is Dictionary: return "必须是对象。"
 var fields=Array(required.split(" ",false));var allowed=fields+Array(optional.split(" ",false))
 for key in fields:
  if not value.has(key): return "缺少字段 "+key+"。"
 for key in value:
  if key not in allowed: return "不支持字段 "+str(key)+"。"
 return ""

static func number(value, low: float, high: float, integer: bool=false) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and value>=low and value<=high and (not integer or value==floor(value))

static func words(value, maximum: int=1200) -> bool:
 return value is String and not value.strip_edges().is_empty() and value.length()<=maximum and not "[" in value and not "]" in value

static func identifier(value) -> bool:
 if not value is String: return false
 var regex=RegEx.new();regex.compile("^[a-z][a-z0-9_]{2,63}$")
 return regex.search(value)!=null

static func subset(value, allowed: Array, empty: bool=false) -> bool:
 if not value is Array or (value.is_empty() and not empty): return false
 var seen=[]
 for entry in value:
  if not entry is String or entry not in allowed or entry in seen: return false
  seen.append(entry)
 return true

static func compile(g, documents: Array) -> Dictionary:
 var data=tables(g);var errors=[];var records=[]
 for document in documents:
  var entry=document.data
  # Events carry the unified node form, so only they use schema 2.
  var expected_version=2 if entry is Dictionary and entry.get("kind") is String and entry.get("kind")=="event" else 1
  if not entry is Dictionary or not entry.get("kind") in KINDS or not identifier(entry.get("id")) or not number(entry.get("schema_version"),expected_version,expected_version,true):
   errors.append(document.file+": 需要 schema_version: %d、受支持的 kind 和英文小写 id。" % expected_version);continue
  if data[entry.kind].has(entry.id):
   errors.append(document.file+": id 与已有内容重复："+entry.id);continue
  var issue=_definition(g,entry,data)
  if issue!="": errors.append(document.file+": "+issue)
  else: records.append(document)
 # References resolve only after all definitions, independent of filenames.
 if errors.is_empty():
  for document in records:
   var issue=_references(g,document.data,data)
   if issue!="": errors.append(document.file+": "+issue)
 return {"ok":errors.is_empty(),"errors":errors,"tables":data if errors.is_empty() else {}}

static func _definition(g, e: Dictionary, data: Dictionary) -> String:
 var common="schema_version kind id name"
 var fields={"restraint":"base_template slots enemy_sources","special_equipment":"base_type energy_gain turn_gain duration wear_text acquisition","relic":"detail modifiers rarity","enemy":"base_enemy hp order strength encounter","event":"intro choices"}
 var required=common+" "+fields[e.kind]
 var optional="design" if e.kind=="special_equipment" else ("trigger card_base_bonuses collectible shop_only shop_payment pickup_cards" if e.kind=="relic" else "")
 if e.kind=="event":
  required=common+" intro start_node nodes"
  optional="cleanup_effects pool"
 var issue=shape(e,required,optional)
 if issue!="": return issue
 if not words(e.name,60): return "name 需要1—60字的普通文本，不能包含富文本标签。"
 match e.kind:
  "restraint":
   if e.base_template not in BASES: return "base_template 只支持普通绳索、细绳、皮带、细皮带、胶带、扎带。"
   var spec=data.restraint[e.base_template].duplicate(true)
   if not subset(e.slots,spec.slots): return "slots 必须是基础模板支持的部位，且不能重复。"
   if not e.enemy_sources is Array or e.enemy_sources.is_empty() or not e.enemy_sources.all(func(id):return identifier(id)): return "enemy_sources 需要至少一个敌人模板 id。"
   spec.name=e.name;spec.slots=e.slots.duplicate();spec.base_template=e.base_template;data.restraint[e.id]=spec
  "special_equipment":
   if not e.base_type is String or not data.special_equipment.has(e.base_type): return "base_type 需要填写现有性玩具类型。"
   if not words(e.wear_text,400) or e.wear_text.count("{name}")!=1: return "wear_text 需要1—400字的佩戴正文，并且恰好包含一次 {name}。"
   if not number(e.energy_gain,0,100) or not number(e.turn_gain,0,100) or not number(e.duration,0,100,true): return "增长量范围0—100，duration 必须是0—100的整数。"
   if e.energy_gain+e.turn_gain<=0 or (e.turn_gain>0)!=(e.duration>0): return "至少有一种增长效果；有回合增长时必须有持续次数，没有时次数必须为0。"
   var spec=data.designs[e.base_type].duplicate(true)
   if e.has("design"):
    issue=shape(e.design,"","grade maximum ratio slots methods tools environments damage_factor")
    if issue!="": return "design: "+issue
    spec.merge(e.design,true)
   if not number(spec.grade,1,3,true) or not number(spec.maximum,1,1000) or not number(spec.ratio,0.01,1) or not number(spec.damage_factor,0.01,10): return "design 的等级1—3、耐久1—1000、初始比例0.01—1、伤害倍率0.01—10。"
   if not subset(spec.slots,g.SpecialEquipment.slots()) or not subset(spec.methods,["strain","slip","magic_slip","lower","manual"]) or not subset(spec.tools,["shard","saw"],true) or not subset(spec.environments,g.SpecialEquipment.ALL_ENVIRONMENTS,true): return "design 部位或解除方法不受支持，或数组有重复项。"
   issue=shape(e.acquisition,"name intro label slot")
   if issue!="": return "acquisition: "+issue
   if not words(e.acquisition.name,60) or not words(e.acquisition.intro) or not words(e.acquisition.label,80) or e.acquisition.slot not in spec.slots: return "acquisition 需要事件名称、介绍、选项文案和允许安装的 slot。"
   var event_id=e.id+"_arrival"
   if data.event.has(event_id): return "附带事件 id 重复："+event_id
   spec.grade=int(spec.grade)
   var type_spec=data.special_equipment[e.base_type].duplicate(true)
   type_spec.name=e.name;type_spec.energy_gain=float(e.energy_gain);type_spec.turn_gain=float(e.turn_gain);type_spec.duration=int(e.duration);type_spec.wear_text=e.wear_text.replace("{name}",e.name)
   data.special_equipment[e.id]=type_spec
   data.designs[e.id]=spec
   # Generated arrival event uses the same single-node form as authored content; the paid
   # refusal is declared explicitly because a node carries no allow_refuse default.
   data.event[event_id]={"name":e.acquisition.name,"intro":e.acquisition.intro,"start_node":"choice","nodes":[{"id":"choice","allow_refuse":true,"unavailable":"disable","relic_gate":"pool","random_freeze":"generators","outcome_draw":"option","frozen_form":"in_place","empty_node":"allow","choices":[{"id":"equip","label":e.acquisition.label,"reward":"none","effects":[{"op":"special_install","type":e.id,"slot":e.acquisition.slot}]}]}]}
  "relic":
   if e.rarity not in ["common","uncommon","rare","special"]: return "rarity 必须为 common、uncommon、rare 或 special。"
   issue=shape(e.modifiers,""," ".join(g.Relics.MODIFIER_LIMITS.keys()))
   if issue!="": return "modifiers: "+issue
   issue=g.Relics.collectible_reason(e)
   if issue!="": return issue
   issue=g.Relics.shop_reason(e)
   if issue!="": return issue
   if e.has("pickup_cards"):
    issue=g.Relics.pickup_cards_reason(e.pickup_cards,g.Cards.Rules.SPECS)
    if issue!="": return issue
   if (e.modifiers.is_empty() and not e.has("trigger") and not e.has("card_base_bonuses") and not e.has("pickup_cards") and not e.get("collectible",false)) or not words(e.detail): return "遗物需要说明和至少一种已支持的加成或触发效果。"
   for key in e.modifiers:
    if not number(e.modifiers[key],1,g.Relics.MODIFIER_LIMITS[key],key!="battle_mana"): return "modifiers."+key+" 数值超出范围或不是整数。"
   data.relic[e.id]={"rarity":e.rarity,"name":e.name,"detail":e.detail,"modifiers":e.modifiers.duplicate()}
   if e.has("pickup_cards"): data.relic[e.id].pickup_cards=e.pickup_cards.duplicate()
   if e.has("collectible"): data.relic[e.id].collectible=e.collectible
   for field in ["shop_only","shop_payment"]:
    if e.has(field): data.relic[e.id][field]=e[field]
   if e.rarity!="special" and not e.get("shop_only",false): data.rewards.append(e.id)
   if e.has("card_base_bonuses"):
    issue=g.Relics.card_bonuses_reason(e.card_base_bonuses,g.Cards.Rules.SPECS)
    if issue!="": return issue
    data.relic[e.id].card_base_bonuses=e.card_base_bonuses.duplicate()
   if e.has("trigger"):
    if not e.trigger is Dictionary: return "trigger 必须是效果对象。"
    var trigger=e.trigger.duplicate(true)
    for key in ["amount","from_tier","to_tier","round"]:
     if trigger.has(key):
      if not number(trigger[key],1,100,true): return "trigger."+key+" 必须是1—100整数。"
      trigger[key]=int(trigger[key])
    issue=g.Relics.trigger_reason(trigger)
    if issue!="": return "trigger: "+issue
    data.relic[e.id].trigger=trigger
  "enemy":
   if e.base_enemy not in ENEMY_BASES or not number(e.hp,1,1000,true) or not number(e.order,0,1000,true): return "base_enemy 不受支持，或 hp/order 不是范围内的整数。"
   issue=shape(e.encounter,"rank grade")
   if issue!="": return "encounter: "+issue
   if e.encounter.rank not in ["weak","strong"] or not number(e.encounter.grade,1,2,true): return "encounter 只支持 weak/strong，装备等级为1或2。"
   if not number(e.strength,1,1000,true) or (e.encounter.rank=="weak" and e.strength>g.Enemies.FirstFloor.WEAK_STRENGTH): return "strength 必须是正整数，弱怪不能超过弱怪池总强度预算。"
   var spec=data.enemy[e.base_enemy].duplicate(true)
   spec.name=e.name;spec.hp=int(e.hp);spec.order=int(e.order);spec.strength=int(e.strength);data.enemy[e.id]=spec
   var encounter_id=e.id+"_encounter"
   if data.encounters.has(encounter_id): return "遭遇 id 重复："+encounter_id
   data.encounters[encounter_id]={"group":"弱怪" if e.encounter.rank=="weak" else "强怪","rank":e.encounter.rank,"members":[{"type":e.id,"grade":int(e.encounter.grade)}]}
   data.pools[e.encounter.rank].append(encounter_id)
  "event":
   if not words(e.intro): return "事件介绍不能为空或过长。"
   if not e.get("pool",true) is bool: return "事件 pool 必须为布尔值。"
   if not identifier(e.get("start_node")): return "事件必须填写 start_node。"
   if not e.nodes is Array or e.nodes.is_empty() or e.nodes.size()>12: return "事件需要1—12个节点。"
   var compiled={"name":e.name,"intro":e.intro,"start_node":e.start_node,"nodes":e.nodes.duplicate(true),"pool":e.get("pool",true)}
   if e.has("cleanup_effects"):
    if not e.cleanup_effects is Array or e.cleanup_effects.size()>8: return "cleanup_effects 最多8项。"
    compiled.cleanup_effects=e.cleanup_effects.duplicate(true)
   data.event[e.id]=compiled
 return ""

static func _references(g, e: Dictionary, data: Dictionary) -> String:
 if e.kind=="restraint":
  for id in e.enemy_sources:
   if not data.enemy.has(id) or data.enemy[id].behavior!="restraint": return "enemy_sources 的 "+str(id)+" 必须是使用普通装备施加行为敌人。"
   for pool in ["install_pool","final_pool"]:
    if e.id not in data.enemy[id][pool]: data.enemy[id][pool].append(e.id)
 if e.kind!="event": return ""
 return _event_references(g,e,data)

static func _item_rewards(groups, g) -> String:
 if not groups is Array or groups.is_empty() or groups.size()>6: return "item_rewards 需要1—6个奖励分组。"
 var ids=[]
 for group in groups:
  var issue=shape(group,"id pool","")
  if issue!="" or not identifier(group.get("id")) or group.id in ids: return "奖励分组需要互不重复的稳定 id。"
  if not group.pool is Array or group.pool.is_empty() or group.pool.size()>12 or group.pool.any(func(type):return not type is String or not g.Tools.TYPES.has(type) or group.pool.count(type)!=1): return "奖励分组必须引用1—12件互不重复的现有道具。"
  ids.append(group.id)
 return ""

static func _encounter(spec, g, data: Dictionary) -> String:
 if not spec is Dictionary: return "encounter 需要对象。"
 var issue=shape(spec,"id requires_defeat victory_effects victory_report result_status")
 if issue!="": return issue
 if not spec.id is String or not data.encounters.has(spec.id): return "战斗遭遇不存在。"
 if not spec.requires_defeat is bool: return "requires_defeat 必须是布尔值。"
 if not spec.victory_effects is Array or spec.victory_effects.is_empty() or spec.victory_effects.size()>8: return "victory_effects 需要1—8个效果。"
 if not words(spec.victory_report) or spec.result_status not in g.Events.RESULT_STATUSES: return "胜利结果文案或结果标记不正确。"
 for effect in spec.victory_effects:
  issue=_effect(g,effect,data,false)
  if issue!="": return "victory_effects: "+issue
 return ""

static func _event_references(g, e: Dictionary, data: Dictionary) -> String:
 var event=data.event[e.id]
 var stage_ids=g.Events.node_ids(event)
 var single=stage_ids.size()==1
 var seen_ids=[]
 for node_index in range(stage_ids.size()):
  var stage=g.Events.node(event,stage_ids[node_index])
  var issue=shape(stage,"id allow_refuse unavailable relic_gate random_freeze outcome_draw frozen_form empty_node choices","title intro")
  if issue!="": return "nodes: "+issue
  if not identifier(stage.id) or stage.id in seen_ids: return "节点 id 无效或重复。"
  seen_ids.append(stage.id)
  if single and stage.id!="choice": return "单节点事件的节点 id 必须为 choice。"
  if single and (stage.has("title") or stage.has("intro")): return "单节点事件不得填写 title 或 intro。"
  if not single and stage.id in ["choice","reward","result","battle","loot","keys"]: return "节点 id 使用了保留字："+stage.id
  if not single and (not words(stage.title,60) or not words(stage.intro)): return "节点标题或介绍不正确。"
  if not stage.allow_refuse is bool: return "节点必须填写 allow_refuse 布尔值。"
  if stage.unavailable not in ["hide","disable"] or stage.relic_gate not in ["pool","claimed"] or stage.random_freeze not in ["generators","always"] or stage.outcome_draw not in ["option","selection"] or stage.frozen_form not in ["in_place","staged"] or stage.empty_node not in ["allow","fail"]: return "节点的声明取值不正确。"
  if not stage.choices is Array or stage.choices.is_empty() or stage.choices.size()>6: return "节点需要1—6个选项。"
 if event.start_node not in stage_ids: return "start_node 必须引用已有节点。"
 var start=g.Events.node(event,event.start_node)
 # Union of the pre-merge rules: the free-exit requirement belongs to the staged form
 # only, because authored single-node events may be mandatory (no refusal present).
 if not single and not start.allow_refuse and not _has_free_exit(start): return "起始阶段必须允许拒绝，或提供一个无条件、无代价的离开选项。"
 for cleanup in event.get("cleanup_effects",[]):
  var issue=_effect(g,cleanup,data,false)
  if issue!="" or cleanup.op!="restore_held": return "cleanup_effects 目前只接受 restore_held："+issue
 var held_keys=[]
 for stage_index in range(stage_ids.size()):
  var stage=g.Events.node(event,stage_ids[stage_index]);var choice_ids=["refuse"]
  for choice in stage.choices:
   var issue=shape(choice,"id label reward","recipe effects outcomes next report report_variants detail selector when result_status show_pressure_sources availability conditions unavailable hide_when_unavailable encounter item_rewards")
   if issue!="": return "nodes."+stage.id+".choices: "+issue
   if choice.get("result_status","neutral") not in g.Events.RESULT_STATUSES: return "选项 result_status 必须为 neutral、success 或 failure。"
   if choice.has("show_pressure_sources") and not choice.show_pressure_sources is bool: return "show_pressure_sources 必须为布尔值。"
   if choice.has("hide_when_unavailable") and not choice.hide_when_unavailable is bool: return "hide_when_unavailable 必须为布尔值。"
   if choice.has("availability") and choice.has("conditions"): return "选项不能同时填写 availability 与 conditions。"
   if choice.has("availability"):
    issue=_availability(g,choice.availability,data)
    if issue!="": return "nodes."+stage.id+"."+choice.get("id","")+".availability: "+issue
   if choice.has("conditions"):
    if not choice.conditions is Array or choice.conditions.is_empty() or choice.conditions.size()>8: return "conditions 需要1—8条条件。"
    for entry in choice.conditions:
     issue=g.Events.condition_issue(g,entry,data)
     if issue!="": return "nodes."+stage.id+"."+choice.get("id","")+".conditions: "+issue
   if choice.has("unavailable") and choice.unavailable not in ["hide","disable"]: return "选项 unavailable 只支持 hide 或 disable。"
   if choice.has("unavailable") and choice.has("hide_when_unavailable"): return "选项不能同时填写 unavailable 与 hide_when_unavailable。"
   if not identifier(choice.id) or choice.id in choice_ids or not words(choice.label,80) or choice.reward not in ["none","common","uncommon","rare","relic"]: return "选项 id、文案或奖励不正确。"
   choice_ids.append(choice.id)
   if choice.has("recipe") and choice.has("effects"): return "选项不能同时填写 recipe 与 effects。"
   if not choice.has("recipe") and not choice.has("effects") and not choice.has("outcomes"): return "选项至少需要 effects、recipe 或 outcomes。"
   if choice.has("recipe") and (not choice.recipe is String or choice.recipe not in ["free_basic","tighten_or_medium","locked_assembly"]): return "选项使用了未知 recipe。"
   if choice.has("effects") and (not choice.effects is Array or choice.effects.size()>12): return "选项 effects 最多12项。"
   if choice.get("reward","none")!="none" and not _next_ends_event(choice.get("next","result")): return "带奖励的选项必须结束事件，不能在领奖后继续下一阶段。"
   issue=_flow_next(choice.get("next","result"),stage_index,stage_ids,e.id,data)
   if issue!="": return "nodes."+stage.id+"."+choice.id+": "+issue
   if choice.has("report") and not words(choice.report): return "选项结果文案不正确。"
   if choice.has("report_variants"):
    issue=_copy_variants(choice.report_variants,data,1200)
    if issue!="": return "nodes."+stage.id+"."+choice.id+".report_variants: "+issue
   if choice.has("detail") and not (choice.detail is String and (choice.detail=="" or words(choice.detail))): return "选项预告文案不正确。"
   if choice.has("selector"):
    issue=_selector(choice.selector,true)
    if issue!="": return "选项选择器："+issue
   if choice.has("when"):
    issue=shape(choice.when,"","counter selector equals minimum maximum")
    var sources=int(choice.when.has("counter"))+int(choice.when.has("selector"))
    if issue!="" or sources!=1 or not ["equals","minimum","maximum"].any(func(key):return choice.when.has(key)): return "选项条件需要恰好一个事件计数或选择来源，以及 equals/minimum/maximum。"
    if choice.when.has("counter") and not identifier(choice.when.counter): return "选项条件的事件计数名无效。"
    if choice.when.has("selector"):
     issue=_selector(choice.when.selector,false)
     if issue!="": return "选项条件的选择来源："+issue
    for key in ["equals","minimum","maximum"]:
     if choice.when.has(key) and not number(choice.when[key],0,100,true): return "选项条件计数必须是0—100整数。"
   if choice.has("encounter"):
    if choice.reward!="none": return "事件战斗使用胜利效果发放奖励，不能再叠加普通 reward。"
    issue=_encounter(choice.encounter,g,data)
    if issue!="": return "nodes."+stage.id+"."+choice.id+".encounter: "+issue
   if choice.has("item_rewards"):
    if choice.reward!="none" or choice.has("encounter") or choice.has("selector"): return "道具奖励不能叠加卡牌／遗物奖励、战斗或目标选择器。"
    issue=_item_rewards(choice.item_rewards,g)
    if issue!="": return "nodes."+stage.id+"."+choice.id+".item_rewards: "+issue
   var shown_pressure_effects=[]
   for effect in choice.get("effects",[]):
    issue=_effect(g,effect,data,true)
    if issue!="": return "nodes."+stage.id+"."+choice.id+".effects: "+issue
    if effect.op=="pressure": shown_pressure_effects.append(effect)
    if effect.op=="hold_special":
     if effect.key in held_keys: return "同一个暂存 key 只能建立一次。"
     held_keys.append(effect.key)
   if choice.has("outcomes"):
    if not choice.outcomes is Array or choice.outcomes.size()<2 or choice.outcomes.size()>8 or not words(choice.get("detail","")): return "随机结果需要2—8项，并提供不泄露实际结果的 detail。"
    for outcome in choice.outcomes:
     issue=shape(outcome,"weight effects","next reward report report_variants result_status")
     if issue!="" or not number(outcome.weight,1,10000,true) or not outcome.effects is Array or outcome.effects.size()>12: return "随机结果的权重或效果列表不正确。"
     if outcome.get("result_status","neutral") not in g.Events.RESULT_STATUSES: return "随机结果 result_status 必须为 neutral、success 或 failure。"
     if outcome.get("reward",choice.reward) not in ["none","common","uncommon","rare","relic"]: return "随机结果奖励不受支持。"
     var next=outcome.get("next",choice.get("next","result"))
     issue=_flow_next(next,stage_index,stage_ids,e.id,data)
     if issue!="": return "随机结果："+issue
     if outcome.get("reward",choice.reward)!="none" and not _next_ends_event(next): return "带奖励的随机结果目前必须结束事件。"
     if outcome.has("report") and not words(outcome.report): return "随机结果文案不正确。"
     if outcome.has("report_variants"):
      issue=_copy_variants(outcome.report_variants,data,1200)
      if issue!="": return "随机结果 report_variants: "+issue
     for effect in outcome.effects:
      issue=_effect(g,effect,data,true)
      if issue!="": return "随机结果 effects: "+issue
      if effect.op=="pressure": shown_pressure_effects.append(effect)
      if effect.op=="hold_special":
       if effect.key in held_keys: return "同一个暂存 key 只能建立一次。"
       held_keys.append(effect.key)
   if choice.get("show_pressure_sources",false) and (shown_pressure_effects.is_empty() or shown_pressure_effects.any(func(effect):return not effect.has("source"))): return "show_pressure_sources 需要至少一个带 source 的快感效果。"
 for cleanup in event.get("cleanup_effects",[]):
  if cleanup.key not in held_keys: return "cleanup_effects 引用了从未建立的暂存 key。"
 for key in held_keys:
  if not event.get("cleanup_effects",[]).any(func(effect):return effect.key==key): return "暂存装备必须在 cleanup_effects 中原样归还。"
 # docs/spec/event-pipeline.md「事件链」(A33): a jump keeps the source holds, so a hold key has to stay unique along the whole
 # chain, not only inside one definition. The path walk below covers every jump path of this
 # definition; cleanup_effects staying inside its own key set is already enforced above.
 return _chain_hold_key_issue(g,data,e.id)

# The jump graph is walked once per definition with the keys already in use on the current
# path. Cycles cannot run (the runtime refuses them), but a crafted package still terminates:
# a definition repeated on the same path is left to the runtime's chain guard.
static func _chain_hold_key_issue(g, data: Dictionary, event_id: String, used: Array=[], path: Array=[]) -> String:
 var event=data.get("event",{}).get(event_id,{})
 if event.is_empty() or event_id in path: return ""
 var keys=_hold_keys(event)
 for key in keys:
  if key in used: return "事件链上重复使用了暂存 key："+str(key)+"（"+event_id+"）。"
 var accumulated=used.duplicate()+keys
 var closed=path.duplicate()
 closed.append(event_id)
 for target in _jump_targets(g,event):
  if target in closed: continue
  var issue=_chain_hold_key_issue(g,data,target,accumulated,closed)
  if issue!="": return issue
 return ""

static func _hold_keys(event: Dictionary) -> Array:
 var keys=[]
 for node_entry in event.get("nodes",[]):
  for choice in node_entry.get("choices",[]):
   for effects in _choice_effect_lists(choice):
    for effect in effects:
     if effect.get("op","")!="hold_special": continue
     if effect.get("key","") not in keys: keys.append(effect.get("key",""))
 return keys

static func _choice_effect_lists(choice: Dictionary) -> Array:
 var lists=[choice.get("effects",[])]
 for outcome in choice.get("outcomes",[]): lists.append(outcome.get("effects",[]))
 return lists

static func _jump_targets(g, event: Dictionary) -> Array:
 var targets=[]
 for node_entry in event.get("nodes",[]):
  for choice in node_entry.get("choices",[]):
   var nexts=[choice.get("next","result")]
   for outcome in choice.get("outcomes",[]): nexts.append(outcome.get("next",choice.get("next","result")))
   for next in nexts:
    # The authored shape is interpreted by its single interpreter, never re-read here.
    var target=g.Events.next_target(next)
    if target.kind=="event" and target.event!="" and target.event not in targets: targets.append(target.event)
 return targets

# A declared next ends the event only as the "result" sentinel; the cross-event object form
# never does, and comparing that object with a String would raise at runtime.
static func _next_ends_event(next) -> bool:
 return not next is String or next=="result"

# docs/spec/event-pipeline.md「事件链」: next is "result", a later node of this definition, or {"event","node"} — a jump to
# another registered event's node. The in-definition form keeps the forward-only rule; the
# cross-event form resolves against the compiled batch and refuses a self-reference.
static func _flow_next(next, current: int, stage_ids: Array, event_id: String, data: Dictionary) -> String:
 if next is Dictionary:
  var issue=shape(next,"event node")
  if issue!="": return "跨事件跳转需要 event 与 node。"
  if not next.event is String or not next.node is String: return "跨事件跳转需要 event 与 node。"
  if next.event==event_id: return "跨事件跳转不能引用事件自身。"
  if not data.get("event",{}).has(next.event): return "跨事件跳转引用了尚未登记的事件。"
  var targets=data.event[next.event].get("nodes",[]).map(func(entry):return str(entry.get("id","")))
  if next.node not in targets: return "跨事件跳转引用了不存在的节点。"
  return ""
 if not next is String or (next!="result" and next not in stage_ids): return "next 必须引用后续阶段或 result。"
 if next!="result" and stage_ids.find(next)<=current: return "多阶段事件不能倒退或形成循环。"
 return ""

static func _has_free_exit(stage: Dictionary) -> bool:
 for choice in stage.get("choices",[]):
  var effects=choice.get("effects",null)
  if choice.get("reward","")!="none" or not _next_ends_event(choice.get("next","result")): continue
  if choice.has("selector") or choice.has("when") or choice.has("recipe") or choice.has("outcomes"): continue
  if effects is Array and effects.is_empty(): return true
 return false

static func _selector(selector, allow_count: bool) -> String:
 if not selector is Dictionary: return "选择器需要对象。"
 var optional="exclude_curses include_special"+(" count" if allow_count else "")
 var issue=shape(selector,"kind",optional)
 if issue!="" or selector.kind not in ["card","restraint"]: return "只支持卡牌或拘束具。"
 if selector.has("exclude_curses") and (selector.kind!="card" or not selector.exclude_curses is bool): return "只有卡牌选择器可以声明 exclude_curses。"
 if selector.has("include_special") and (selector.kind!="restraint" or not selector.include_special is bool): return "只有拘束具选择器可以声明 include_special。"
 if selector.has("count") and not number(selector.count,1,4,true): return "count 必须是1—4的整数。"
 return ""

static func _availability(g, availability, data: Dictionary={}) -> String:
 if not availability is Dictionary: return "需要条件对象。"
 var issue=shape(availability,"kind reason","type")
 if issue!="": return issue
 # Kinds and their required fields live in Events.CONDITIONS, never in a second list here.
 return g.Events.condition_issue(g,availability,data)

static func _copy_variants(variants, data: Dictionary, maximum: int) -> String:
 if not variants is Array or variants.is_empty() or variants.size()>8: return "需要1—8项条件文案。"
 var seen=[]
 for variant in variants:
  var issue=shape(variant,"when text")
  if issue!="": return issue
  if not variant.when is Dictionary: return "when 需要条件对象。"
  issue=shape(variant.when,"kind value")
  if issue!="": return issue
  if variant.when.kind!="equipped_special_family": return "尚未支持这种文案条件。"
  if not variant.when.value is String or variant.when.value in seen: return "特殊装备族条件必须有效且不能重复。"
  var known=false
  for type in data.special_equipment.values():
   if type.get("family","")==variant.when.value:
    known=true
    break
  if not known: return "文案条件引用了不存在的特殊装备族。"
  if not words(variant.text,maximum): return "条件文案为空或过长。"
  seen.append(variant.when.value)
 return ""

static func _effect(g, e, data: Dictionary, generators: bool=false) -> String:
 if not e is Dictionary or not e.get("op") is String: return "需要效果对象和 op。"
 var fields={"install":"template slot grade tier locked","assembly":"family variant straps part name coverage part_name","special_install":"type slot","mana_loss":"amount","mana_gain":"amount","mana_restore_full":"","mana_max_loss":"amount","flask_mana_gain":"amount","pressure":"amount","card":"type","tool":"type","relic":"type","hold_special":"key slots","restore_held":"key","transform_card":"target type","remove_card":"target","remove_restraints":"targets","ease_restraint":"target","counter":"key amount"}
 if generators:
  fields.install_random="templates count grade tier locked"
  fields.tighten_random="count to_tier"
  fields.special_install_random="types"
  fields.random_amount="effect minimum maximum"
 if not fields.has(e.op): return "尚未支持效果 "+e.op+"。"
 var optional="templates" if e.op=="tighten_random" else ("source source_variants" if e.op=="pressure" else ("name" if e.op in ["transform_card","remove_card","remove_restraints","ease_restraint"] else ""))
 if e.op in ["install","assembly","special_install"]: optional="replace"+(" wear_style" if e.op=="install" else "")
 if e.op=="install_random": optional="replace allow_links wear_style"
 if e.op=="special_install_random": optional="replace fallback"
 if e.op=="random_amount": optional="source"
 var issue=shape(e,"op "+fields[e.op],optional)
 if issue!="": return issue
 if e.has("replace") and not e.replace is bool: return "replace 必须明确填写 true 或 false。"
 if e.has("wear_style") and (not e.wear_style is String or e.wear_style not in g.Equipment.WEAR_STYLES): return "wear_style 必须是 assisted 或 animated。"
 match e.op:
  "install":
   if not e.template is String or not data.restraint.has(e.template): return "装备 template 不存在。"
   var spec=data.restraint[e.template]
   if e.slot not in spec.slots or not number(e.grade,spec.get("min_grade",1),3,true) or not number(e.tier,1,3,true) or not e.locked is bool or (e.locked and not spec.lock): return "装备部位、等级、紧度或锁不符合模板。"
   e.grade=int(e.grade);e.tier=int(e.tier)
  "special_install":
   if not e.type is String or not data.special_equipment.has(e.type) or e.slot not in data.designs[e.type].slots: return "性玩具或安装部位不存在。"
  "assembly":
   if not e.family is String or not e.variant is String or not e.straps is String or not e.part is String: return "复合装备需要有效的类型、款式、肩带和上锁组件。"
   var spec=g.Composites.spec(e.family,e.variant,e.straps)
   if spec.is_empty() or not spec.parts.has(e.part) or not data.restraint[spec.parts[e.part].template].lock: return "复合装备结构或上锁组件不正确。"
   if e.name!=spec.name or e.coverage!=spec.coverage or e.part_name!=spec.name+" · "+spec.parts[e.part].label: return "复合装备说明必须对应实际名称、覆盖部位和上锁组件。"
  "mana_loss","mana_gain","flask_mana_gain","pressure":
   if not number(e.amount,0,100): return "amount 必须是0—100的有限数值。"
   if e.has("source") and not words(e.source,120): return "pressure.source 需要普通结果文字。"
   if e.has("source_variants"):
    var variant_issue=_copy_variants(e.source_variants,data,120)
    if variant_issue!="": return "pressure.source_variants: "+variant_issue
  "random_amount":
   if e.effect not in ["mana_loss","mana_gain","flask_mana_gain","pressure"]: return "随机数值只支持现有的魔力、魔瓶魔力或快感效果。"
   if not number(e.minimum,0,100,true) or not number(e.maximum,0,100,true) or e.minimum>e.maximum: return "随机数值上下限必须是0—100的整数，且下限不能高于上限。"
   if e.has("source") and (e.effect!="pressure" or not words(e.source,120)): return "只有随机快感效果可以填写普通来源文字。"
   e.minimum=int(e.minimum);e.maximum=int(e.maximum)
  "mana_restore_full": pass
  "mana_max_loss":
   if not number(e.amount,1,100,true): return "最大魔力降低值必须是1—100的整数。"
   e.amount=int(e.amount)
  "card":
   if not e.type is String or not g.B.CARD_NAMES.has(e.type): return "卡牌 type 不存在。"
  "tool":
   if not e.type is String or not g.Tools.TYPES.has(e.type): return "道具 type 不存在。"
  "relic":
   if not e.type is String or not data.relic.has(e.type): return "遗物 type 不存在。"
  "transform_card":
   if e.target!="$selected" or not e.type is String or not g.B.CARD_NAMES.has(e.type): return "换牌效果需要使用选择器目标和有效卡牌 type。"
  "remove_card":
   if e.target!="$selected": return "删牌效果需要使用选择器目标。"
  "remove_restraints":
   if not e.targets is String or e.targets!="$selected": return "批量解除拘束具需要使用选择器目标。"
  "ease_restraint":
   if e.target!="$selected": return "松开拘束具需要使用选择器目标。"
  "counter":
   if not identifier(e.key) or not number(e.amount,-100,100,true) or e.amount==0: return "事件计数需要有效 key 和非零整数变化量。"
  "install_random":
   if not subset(e.templates,data.restraint.keys()) or not number(e.count,1,4,true) or not number(e.grade,1,3,true) or not number(e.tier,1,3,true) or not e.locked is bool or (e.has("allow_links") and not e.allow_links is bool): return "随机安装的模板、数量、等级、紧度、锁或链接范围不正确。"
   for template in e.templates:
    var spec=data.restraint[template]
    if e.grade<spec.get("min_grade",1) or (e.locked and not spec.lock): return "随机安装包含不支持该等级或锁的模板。"
   e.count=int(e.count);e.grade=int(e.grade);e.tier=int(e.tier)
  "tighten_random":
   var extra=shape(e,"op count to_tier","templates")
   if extra!="" or not number(e.count,1,4,true) or not number(e.to_tier,2,3,true) or (e.has("templates") and not subset(e.templates,data.restraint.keys(),true)): return "随机收紧的数量、目标档位或模板过滤不正确。"
   e.count=int(e.count);e.to_tier=int(e.to_tier)
  "special_install_random":
   var fallback_effects=e.get("fallback",[])
   if not subset(e.types,data.special_equipment.keys()) or not fallback_effects is Array or fallback_effects.size()>4: return "随机性玩具池或无合法位置时的后备效果不正确。"
   for fallback in fallback_effects:
    var fallback_issue=_effect(g,fallback,data,false)
    if fallback_issue!="": return "随机性玩具后备效果："+fallback_issue
  "hold_special":
   if not identifier(e.key) or not subset(e.slots,g.SpecialEquipment.slots()): return "暂存 key 或性玩具位置不正确。"
  "restore_held":
   if not identifier(e.key): return "归还暂存装备需要有效 key。"
 return ""
