extends RefCounted

const Game=preload("res://tests/game_fixture.gd")
const Catalog=preload("res://core/content_catalog.gd")
const Events=preload("res://tests/event_cases.gd")

static func event_mana_cost(t) -> void:
 var offers=[
  ["binding_cleric","purify",1],
  ["mysterious_woman_statue","use_sleeve",1],
  ["succubus_magic_pawnshop","small_trade",1],
  ["succubus_magic_pawnshop","large_trade",2],
  ["succubus_magic_pawnshop","extra_spice",2],
  ["succubus_three_games","begin",0]]
 for offer in offers:
  for remaining_mana in [100.0,15.0,0.0]:
   for deferred_turns in [0,2]:
    var g=Game.new(201)
    Events.arrive(g,offer[0])
    var expected_count=int(offer[2])
    if offer[0]=="succubus_three_games":
     t.check(g.Events.enter_node(g,"wager_semen")=="","EVENT MANA enters the authored third-round stage")
     var frozen=g.state.room_event.options.filter(func(option):return option.source_choice=="begin")[0]
     expected_count=1 if frozen.result_status=="success" else 2
    g.state.mana=remaining_mana;g.state.temporary_mana=30;g.state.flask_mana=40
    g.state.slip_ejaculation_turns=deferred_turns
    var before=g.export_snapshot()
    var action=t.find_action(g,"event",{"action":"choose","choice":offer[1]})
    t.check(g.export_snapshot()==before,"EVENT MANA preview preserves all resources: "+offer[1])
    t.check(g.dispatch(g.command(action.payload,g.state.version),g.state.version).ok,"EVENT MANA option commits: "+offer[1])
    var expected_loss=minf(remaining_mana,20.0*expected_count)
    t.check(g.state.overload_total-before.overload_total==expected_count and is_equal_approx(g.state.mana,remaining_mana-expected_loss),"EVENT MANA each event climax deducts twenty personal mana, clamped at zero: "+offer[1])
    t.check(g.state.temporary_mana==30 and g.state.flask_mana==40 and g.state.slip_ejaculation_turns==deferred_turns,"EVENT MANA leaves temporary mana, flask and pending combat penalty unchanged: "+offer[1])
    var logged_loss=0.0
    for log in g.state.logs.slice(before.logs.size()): logged_loss+=float(log.data.get("mana_lost",0.0))
    t.check(is_equal_approx(logged_loss,expected_loss),"EVENT MANA log reports the actual loss exactly once: "+offer[1])
    var after=g.export_snapshot()
    t.check(not g.dispatch(g.command(action.payload,before.version),before.version).ok and g.export_snapshot()==after,"EVENT MANA stale repeat cannot charge again: "+offer[1])

static func link_installation(t) -> void:
 var g=Game.new(42)
 g._install_template("rope","forearm",8,10,false,"fixture",1,-1,0,"mid_forearm")
 g._install_template("belt","wrist",8,10,false,"fixture")
 Events.arrive(g,"binding_cleric")
 t.check(g.Events.ordinary(g,2,false,["belt"]).any(func(e):return e.op=="link") and g.Events.ordinary(g,2,false,["belt"],true).all(func(e):return e.op=="install"),"EVENT rope/belt recipes include links while explicitly locked recipes preserve lockability")
 var before=g.export_snapshot()
 var frozen=g.Events.freeze_effects(g,[{"op":"install_random","templates":["link_rope"],"count":1,"grade":2,"tier":2,"locked":false}])
 t.check(frozen.issue=="" and frozen.effects.size()==1 and frozen.effects[0].op=="link" and g.state.links.is_empty() and g.state.equipment==before.equipment,"EVENT generated link freezes without installing or rejecting its structure")
 if frozen.issue!="": return
 var effect=frozen.effects[0]
 var detail=g.Events.describe(g,frozen.effects)
 t.check(detail.contains("链接绳") and effect.contact_points.all(func(point):return detail.contains(g.Equipment.point_name(point))),"EVENT link preview names both real body locations")
 # The injected option belongs to a real node: the legal stage set follows the definition.
 g.state.room_event.flow=false;g.state.room_event.stage="service"
 g.state.room_event.options=[{"id":"link_test","label":"接受连接","detail":detail,"reward":"none","effects":[{"op":"mana_loss","amount":3},effect]}]
 var pending=g.export_snapshot()
 var twin=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"event frozen link offer")
 var rng=g.state.rng.duplicate(true)
 t.check(Events.choose(t,g,"link_test").ok and g.state.links.size()==1 and g.state.links[0].ends==effect.ends and g.state.mana==pending.mana-3 and g.state.rng==rng,"EVENT frozen link commits exact endpoints and cost without reroll")
 twin._equipment(effect.ends[0]).durability=0;twin._cleanup()
 before=twin.export_snapshot()
 t.check(not Events.choose(t,twin,"link_test").ok and twin.export_snapshot()==before,"EVENT missing frozen endpoint rejects the entire choice including payment")

static func plate_lock_copy(t) -> void:
 var cleric=Game.new(201)
 t.check(not cleric._install_special("negative_plate_lock_medium","special_2_a").is_empty(),"EVENT COPY fixture equips a real flat lock")
 Events.arrive(cleric,"binding_cleric")
 var purify=cleric.state.room_event.options.filter(func(option):return option.source_choice=="purify")[0]
 var purify_source=purify.effects.filter(func(effect):return effect.op=="pressure")[0].source
 t.check(purify_source.contains("平板锁") and purify_source.contains("乳头") and not purify_source.contains("勃起"),"EVENT COPY cleric freezes the flat-lock stimulation source instead of penis stimulation")
 t.check(purify.report.contains("连这里也锁住了吗") and purify.report.contains("没关系。这样也可以") and purify.report.contains("精液随即从平板锁下"),"EVENT COPY cleric visibly moves from surprise to an alternate climax method")
 var overload_before=cleric.state.overload_total
 t.check(t.action(cleric,"event",{"action":"choose","choice":"purify"}).ok and cleric.state.overload_total==overload_before+1 and cleric.state.room_event.report.contains("揉捏乳头") and not cleric.state.room_event.report.contains("手掌裹紧肉棒"),"EVENT COPY cleric commits unchanged climax mechanics with the frozen flat-lock report")

 var saw_success=false;var saw_failure=false
 for seed_value in range(72):
  var gamble=Game.new(seed_value,true,"succubus_three_games")
  if gamble._install_special("negative_plate_lock_medium","special_2_a").is_empty(): continue
  t.check(gamble.Events.enter_node(gamble,"wager_semen")=="","EVENT COPY opens the real semen-wager stage with a flat lock")
  var option=gamble.state.room_event.options.filter(func(row):return row.source_choice=="begin")[0]
  var sources=option.effects.filter(func(effect):return effect.op=="pressure").map(func(effect):return effect.source)
  t.check(sources.all(func(source):return source.contains("平板锁") or source.contains("锁具下")) and sources.all(func(source):return not source.contains("握住勃起") and not source.contains("足心贴住柱身") and not source.contains("夹进丰满的乳沟")),"EVENT COPY flat-lock gamble removes every incompatible penis-stimulation source")
  var expected_climaxes=1 if option.result_status=="success" else 2
  var before=gamble.state.overload_total
  t.check(t.action(gamble,"event",{"action":"choose","choice":"begin"}).ok and gamble.state.overload_total==before+expected_climaxes,"EVENT COPY flat-lock gamble preserves the frozen one-or-two climax result")
  if option.result_status=="success":
   saw_success=true
   t.check(gamble.state.room_event.report.contains("姐姐连那根杂鱼肉棒都没碰哦") and gamble.state.room_event.report.contains("算你赢"),"EVENT COPY winning flat-lock result includes the approved humiliation and payout")
  else:
   saw_failure=true
   t.check(gamble.state.room_event.report.contains("奶子和小穴一碰却能连着射两次") and gamble.state.room_event.report.contains("你的杂鱼肉棒还真是不争气❤"),"EVENT COPY losing flat-lock result includes the approved two-climax humiliation")
  if saw_success and saw_failure: break
 t.check(saw_success and saw_failure,"EVENT COPY deterministic seeds cover both flat-lock gamble outcomes")

static func document() -> Dictionary:
 return {"file":"memory://event_flow.json","data":{
  "schema_version":2,"kind":"event","id":"flow_test","name":"多阶段事件夹具",
  "intro":"一个只用于验证通用事件接口的多阶段夹具。","start_node":"entry",
  "cleanup_effects":[{"op":"restore_held","key":"selected_gear"}],
  "nodes":[
   {"id":"entry","title":"第一阶段","intro":"进入事件并冻结本阶段的随机结果。","allow_refuse":true,
    "unavailable":"hide","relic_gate":"claimed","random_freeze":"always","outcome_draw":"option","frozen_form":"staged","empty_node":"fail","choices":[
    {"id":"accept","label":"继续","reward":"none","next":"penalty","detail":"暂存指定部位的现有装备，并从公开结果池中确定一项结果。",
     "effects":[{"op":"hold_special","key":"selected_gear","slots":["special_2_a","special_2_b","special_2_c","special_2_d"]}],
     "outcomes":[
      {"weight":1,"effects":[{"op":"card","type":"panic"}],"report":"结果一"},
      {"weight":1,"effects":[{"op":"card","type":"sensitive"}],"report":"结果二"}]}
   ]},
   {"id":"penalty","title":"第二阶段","intro":"从三种公开代价中选择一种。","allow_refuse":false,
    "unavailable":"hide","relic_gate":"claimed","random_freeze":"always","outcome_draw":"option","frozen_form":"staged","empty_node":"fail","choices":[
    {"id":"two_ropes","label":"随机安装两件初级绳索","reward":"none","next":"finale","effects":[{"op":"install_random","templates":["rope"],"count":2,"grade":1,"tier":2,"locked":false}]},
    {"id":"locked_belt","label":"随机安装一件上锁皮带","reward":"none","next":"finale","effects":[{"op":"install_random","templates":["belt"],"count":1,"grade":2,"tier":2,"locked":true}]},
    {"id":"tighten_two","label":"随机收紧两件拘束具","reward":"none","next":"finale","effects":[{"op":"tighten_random","count":2,"to_tier":3}]}
   ]},
   {"id":"finale","title":"第三阶段","intro":"最后一项效果沿用正式快感接口。","allow_refuse":false,
    "unavailable":"hide","relic_gate":"claimed","random_freeze":"always","outcome_draw":"option","frozen_form":"staged","empty_node":"fail","choices":[
    {"id":"finish","label":"完成","reward":"none","next":"result","effects":[{"op":"pressure","amount":100,"source":"事件夹具"}]}
   ]}
  ]
 }}

static func flow(t, seed_value: int=17):
 var g=Game.new(seed_value)
 Events.arrive(g,"flow_test")
 t.check(g.state.room_event.flow and g.state.room_event.stage=="entry","EVENT FLOW starts declared stage")
 return g

# docs/spec/event-pipeline.md「证据入口」: the
# source holds one key and counts once before jumping to the target's entry node; that node
# holds a second key, offers a loop back to the source, and ends at its own finale node.
static func chain_documents() -> Array:
 return [
  {"file":"memory://chain_source.json","data":{
   "schema_version":2,"kind":"event","id":"chain_source_fixture","name":"事件链起点夹具",
   "intro":"只用于验证事件链的起点夹具。","start_node":"choice",
   "cleanup_effects":[{"op":"restore_held","key":"chain_source_gear"}],
   "nodes":[{"id":"choice","allow_refuse":false,"unavailable":"disable","relic_gate":"pool","random_freeze":"generators","outcome_draw":"option","frozen_form":"in_place","empty_node":"allow","choices":[
    {"id":"depart","label":"动身前往下一段事件","reward":"none","next":{"event":"chain_target_fixture","node":"entry"},"detail":"暂时取下指定位置的性玩具，记下一次计数，然后进入另一段事件。",
     "effects":[{"op":"hold_special","key":"chain_source_gear","slots":["special_2_a"]},{"op":"counter","key":"chain_seen","amount":1}]},
    {"id":"stay","label":"留在这里","reward":"none","next":"result","detail":"不进入另一段事件。","effects":[{"op":"mana_gain","amount":1}]}]}]}},
  {"file":"memory://chain_target.json","data":{
   "schema_version":2,"kind":"event","id":"chain_target_fixture","name":"事件链目标夹具",
   "intro":"只用于验证事件链的目标夹具。","start_node":"entry",
   "cleanup_effects":[{"op":"restore_held","key":"chain_target_gear"}],
   "nodes":[
    {"id":"entry","title":"链上第一段","intro":"链上换成了另一份定义。","allow_refuse":false,"unavailable":"hide","relic_gate":"claimed","random_freeze":"always","outcome_draw":"option","frozen_form":"staged","empty_node":"fail","choices":[
     {"id":"proceed","label":"继续链上流程","reward":"none","next":"finale","detail":"暂时取下另一件装备，然后进入链上最后一段。","effects":[{"op":"hold_special","key":"chain_target_gear","slots":["special_2_c"]}]},
     {"id":"proceed_alt","label":"换一种方式继续","reward":"none","next":"finale","detail":"不取下装备，直接进入链上最后一段。","effects":[{"op":"mana_gain","amount":1}]},
     {"id":"loop_back","label":"回到起点事件","reward":"none","next":{"event":"chain_source_fixture","node":"choice"},"detail":"事件链不能回到已经走过的事件。","effects":[{"op":"mana_gain","amount":1}]},
     {"id":"step_out","label":"直接结束这段事件","reward":"none","next":"result","detail":"不继续链上流程。","effects":[]}]},
    {"id":"finale","title":"链上最后一段","intro":"链上事件的收尾。","allow_refuse":false,"unavailable":"hide","relic_gate":"claimed","random_freeze":"always","outcome_draw":"option","frozen_form":"staged","empty_node":"fail","choices":[
     {"id":"settle","label":"结束链上事件","reward":"none","next":"result","detail":"结束这段链上事件。","effects":[{"op":"pressure","amount":2,"source":"事件链夹具"}]}]}]}}]

static func empty_studio(t) -> void:
 var g=Game.new(90,true,"enchanters_empty_studio")
 var temper=g.command_facts().filter(func(c):return c.payload.get("choice","").begins_with("temper__"))
 var selection=g.get_view().room_event.selections.filter(func(group):return group.id=="temper")
 t.check(temper.size()==1 and temper[0].valid and selection.size()==1 and selection[0].count==2 and selection[0].options[0].selected is Array and selection[0].options[0].selected.size()==2,"STUDIO two-restraint option freezes one atomic pair and projects a count-two selector")
 var saved=g.export_snapshot();var resumed=Game.new(90)
 t.check(resumed.restore_snapshot(saved).ok and resumed.state.room_event.options.any(func(option):return option.id==temper[0].payload.choice and option.selected is Array and option.selected.size()==2),"STUDIO pending multi-restraint choice survives snapshot validation")
 var selected=g.state.room_event.options.filter(func(option):return option.id==temper[0].payload.choice)[0].selected
 t.check(g.dispatch(g.command(temper[0].payload,g.state.version),g.state.version).ok and selected.all(func(row):return g._equipment(row.id).is_empty()) and g.state.room_event.report.contains(selected[0].name) and g.state.room_event.report.contains(selected[1].name),"STUDIO temper removes both selected restraints and names both in the result")

 g=Game.new(91,true,"enchanters_empty_studio")
 var deck_before=g.state.deck.size()
 t.check(t.action(g,"event",{"action":"choose","choice":"search"}).ok and "enchanters_needle_case" in g.state.relics and g.state.deck.size()==deck_before+1 and g.state.deck.any(func(card):return card.type=="lewd_mark"),"STUDIO search atomically grants the rare needle case and lewd-mark curse")
 var duplicate=Game.new(92);duplicate.state.relics.append("enchanters_needle_case");Events.arrive(duplicate,"enchanters_empty_studio")
 t.check(not duplicate.command_facts().any(func(c):return c.payload.get("choice","")=="search"),"STUDIO already-owned event relic hides the complete search option")

 var sparse=Game.new(93);sparse.add_fixture("wrist",8);Events.arrive(sparse,"enchanters_empty_studio")
 t.check(not sparse.command_facts().any(func(c):return c.payload.get("choice","").begins_with("temper__")) and sparse.command_facts().any(func(c):return c.payload.get("choice","")=="leave"),"STUDIO fewer than two selectable restraints hides temper and preserves free departure")
 var state_before={"mana":sparse.state.mana,"pressure":sparse.state.pressure,"deck":sparse.state.deck.duplicate(true),"relics":sparse.state.relics.duplicate(true),"equipment":sparse.state.equipment.duplicate(true)}
 t.check(t.action(sparse,"event",{"action":"choose","choice":"leave"}).ok and sparse.state.mana==state_before.mana and sparse.state.pressure==state_before.pressure and sparse.state.deck==state_before.deck and sparse.state.relics==state_before.relics and sparse.state.equipment==state_before.equipment,"STUDIO leave changes no resources, cards, relics or equipment")

 var atomic=Game.new(94,true,"enchanters_empty_studio")
 temper=atomic.command_facts().filter(func(c):return c.payload.get("choice","").begins_with("temper__"))
 selected=atomic.state.room_event.options.filter(func(option):return option.id==temper[0].payload.choice)[0].selected
 atomic._equipment(selected[0].id).durability=0;atomic._cleanup()
 var atomic_before=atomic.export_snapshot()
 t.check(not atomic.dispatch(atomic.command(temper[0].payload,atomic.state.version),atomic.state.version).ok and atomic.export_snapshot()==atomic_before and not atomic._equipment(selected[1].id).is_empty(),"STUDIO missing one frozen target rejects the entire pair without partially removing the other")

static func smuggled_potions(t) -> void:
 var g=Game.new(95,true,"smuggled_mana_potions")
 var choices=g.command_facts().filter(func(candidate):return candidate.payload.get("kind","")=="event" and candidate.payload.get("action","")=="choose")
 t.check(choices.map(func(candidate):return candidate.payload.choice)==["credit","leave"],"SMUGGLER authored credit and free-departure choices are the only event decisions")
 t.check(g.get_view().room_event.intro.contains("“嘘，小声点。我可是偷偷溜进来做生意的。”"),"SMUGGLER uses the confirmed conversational introduction")
 var flask_before=g.state.flask_mana
 var deck_before=g.state.deck.size()
 var deposits_before=g.state.flask_deposits
 var result=t.action(g,"event",{"action":"choose","choice":"credit"})
 var feedback=result.get("resource_feedback",[]).filter(func(row):return row.field=="flask_mana")
 t.check(result.ok and g.state.flask_mana==flask_before+90 and g.state.flask_deposits==deposits_before,"SMUGGLER credit adds ninety directly to the flask without consuming a manual deposit")
 t.check(g.state.deck.size()==deck_before+1 and g.state.deck.any(func(card):return card.type=="sensitive"),"SMUGGLER credit grants exactly the authored Sensitive curse")
 t.check(feedback.size()==1 and feedback[0].before==flask_before and feedback[0].after==flask_before+90,"SMUGGLER flask reward emits one structured resource receipt")
 t.check(g.state.room_event.stage=="result" and g.state.room_event.report.contains("贴身魔瓶") and g.state.room_event.report.contains("敏感"),"SMUGGLER result names the flask transfer and lasting sensitivity")

 g=Game.new(96,true,"smuggled_mana_potions")
 var before={"mana":g.state.mana,"flask_mana":g.state.flask_mana,"flask_deposits":g.state.flask_deposits,"pressure":g.state.pressure,"deck":g.state.deck.duplicate(true),"equipment":g.state.equipment.duplicate(true),"special_equipment":g.state.special_equipment.duplicate(true),"relics":g.state.relics.duplicate(true)}
 t.check(t.action(g,"event",{"action":"choose","choice":"leave"}).ok and g.state.mana==before.mana and g.state.flask_mana==before.flask_mana and g.state.flask_deposits==before.flask_deposits and g.state.pressure==before.pressure and g.state.deck==before.deck and g.state.equipment==before.equipment and g.state.special_equipment==before.special_equipment and g.state.relics==before.relics,"SMUGGLER free departure changes no resource, card, equipment or relic state")

static func floating_belts(t) -> void:
 var g=Game.new(97,true,"floating_belt_cluster")
 var choices=g.command_facts().filter(func(candidate):return candidate.payload.get("kind","")=="event" and candidate.payload.get("action","")=="choose")
 t.check(choices.map(func(candidate):return candidate.payload.choice)==["fight","infusion"],"BELT EVENT exposes only the authored fight and infusion decisions")
 var encounters_before=g.state.encounter
 var rewards_before=g.state.reward_count
 t.check(t.action(g,"event",{"action":"choose","choice":"fight"}).ok and g.state.phase=="battle" and g.state.room_event.stage=="battle","BELT EVENT fight enters a real battle through the generic event encounter transition")
 t.check(g.state.enemies.size()==3 and g.state.enemies.all(func(enemy):return enemy.type=="belt" and enemy.grade==1) and g.state.encounter==encounters_before+1,"BELT EVENT battle spawns exactly three initial floating belts")
 t.check(g.state.room_event.battle.requires_defeat and not g._finish_if_saturated(),"BELT EVENT cannot count equipment saturation as victory")
 for enemy in g.state.enemies: enemy.hp=1.0
 var sweep=t.find_action(g,"attack",{"type":"kick","form":1})
 t.check(sweep.valid and g.dispatch(g.command(sweep.payload,g.state.version),g.state.version).ok,"BELT EVENT final combat action resolves through the ordinary attack transaction")
 t.check(g.state.phase=="event" and g.state.room_event.stage=="result" and "softened_buckle" in g.state.relics and g.state.reward_count==rewards_before+1,"BELT EVENT victory returns to its result and grants the fixed rare relic")
 t.check(g.state.reward_options.is_empty() and g.state.battle_item_drop=="" and g.state.battle_relic_drop=="" and g.state.room_event.report.contains("软化扣环") and g.state.room_event.get("prepare_pending",false),"BELT EVENT victory keeps authored loot and schedules normal preparation after its result")
 var locked=g._install_template("belt","wrist",4,g.Equipment.maximum(1),true,"fixture",1)
 t.check(is_equal_approx(g.escape_preview(locked,"strain",5).lock_multiplier,0.75) and is_equal_approx(g.escape_preview(locked,"slip",5).lock_multiplier,1.0),"BELT EVENT relic changes only the locked strength-struggle multiplier")

 g=Game.new(98,true,"floating_belt_cluster")
 g.state.mana=50
 var deck_before=g.state.deck.size()
 t.check(t.action(g,"event",{"action":"choose","choice":"infusion"}).ok and g.state.mana==75 and g.state.deck.size()==deck_before+1 and g.state.deck.any(func(card):return card.type=="lewd_mark"),"BELT EVENT infusion restores twenty-five personal mana and grants Lewd Mark")
 t.check(g.state.room_event.stage=="result" and g.state.room_event.report.contains("绕住肉棒根部") and g.state.room_event.report.contains("粉红色淫纹"),"BELT EVENT infusion displays the confirmed restraint-focused scene")
 t.check(t.action(g,"event",{"action":"leave"}).ok and g.state.phase=="cleared","BELT EVENT noncombat choice does not grant preparation")

static func battle_preparation(t) -> void:
 for extra in [false,true]:
  var g=Game.new(97,true,"floating_belt_cluster")
  g.state.relics=["small_gem","spicy_rice_noodles"]
  if extra: g.state.relics.append("hourglass")
  t.check(t.action(g,"event",{"action":"choose","choice":"fight"}).ok,"EVENT PREP starts a real event battle")
  for enemy in g.state.enemies: enemy.hp=1.0
  t.check(t.action(g,"attack",{"type":"kick","form":1}).ok and g.state.phase=="event","EVENT PREP final attack preserves the result page")
  var result=g.export_snapshot()
  var restored=Game.new(42)
  t.check(restored.restore_snapshot(result).ok and restored.state.room_event.get("prepare_pending",false),"EVENT PREP result checkpoint preserves pending preparation")
  var broken=result.duplicate(true);broken.room_event.prepare_pending="yes"
  var unchanged=restored.export_snapshot()
  t.check(not restored.restore_snapshot(broken).ok and restored.export_snapshot()==unchanged,"EVENT PREP malformed pending state rejects atomically")
  var leave=t.find_action(g,"event",{"action":"leave"})
  t.check(leave.valid and leave.label=="开始整备" and leave.detail.contains(str(4 if extra else 3)+"回合"),"EVENT PREP result action describes the shared modified turn count")
  var serial=g.state.combat.serial
  var carried_charge=g.state.charge
  var version=g.state.version
  t.check(g.dispatch(g.command(leave.payload,version),version).ok and g.state.phase=="prepare" and g.state.prepare_left==(4 if extra else 3),"EVENT PREP enters normal preparation including hourglass modifier")
  t.check(not g.state.room_event.has("prepare_pending") and g.state.combat.serial==serial and g.state.energy==3 and g.state.charge==carried_charge and not g.state.hand.is_empty(),"EVENT PREP consumes pending flag and continues without repeating opening bonuses")
  unchanged=g.export_snapshot()
  t.check(not g.dispatch(g.command(leave.payload,version),version).ok and g.export_snapshot()==unchanged,"EVENT PREP stale result cannot duplicate opening effects")
  t.check(restored.restore_snapshot(g.restart_snapshot()).ok and restored.state.phase=="prepare" and restored.state.prepare_left==g.preparation_turns(),"EVENT PREP scene SL starts at preparation first turn")
  if extra:
   t.check(t.action(g,"finish_prepare").ok and g.state.phase=="cleared","EVENT PREP can finish early via shared preparation action")
  else:
   for i in range(3): t.check(t.action(g,"end").ok,"EVENT PREP completes a formal preparation round")
   t.check(g.state.phase=="cleared" and g.state.prepare_left==0 and not g.state.combat.active,"EVENT PREP final round completes the practice without reopening the result")
  t.check(g.state.relics.count("softened_buckle")==1,"EVENT PREP never repeats the event reward")

static func alchemist_tasting(t) -> void:
 var g=Game.new(99,true,"alchemist_tasting_stall")
 var authored=JSON.stringify(g.Events.Data.TYPES.alchemist_tasting_stall)
 t.check(not authored.contains("香蕉") and not authored.contains("甜甜圈") and not authored.contains("盒子"),"ALCHEMIST replaces all three source-event props with tower-setting potions")
 var choices=g.command_facts().filter(func(candidate):return candidate.payload.get("kind","")=="event" and candidate.payload.get("action","")=="choose")
 t.check(choices.any(func(candidate):return candidate.payload.choice=="mana_tonic") and choices.any(func(candidate):return candidate.payload.choice=="succubus_mix") and choices.any(func(candidate):return candidate.payload.choice.begins_with("dissolve__")),"ALCHEMIST offers mana tonic, restraint solvent and succubus mix without a departure choice")
 g.state.mana=50
 t.check(t.action(g,"event",{"action":"choose","choice":"mana_tonic"}).ok and g.state.mana==75 and g.state.room_event.result_status=="success","ALCHEMIST mana tonic restores twenty-five personal mana through the shared effect")

 g=Game.new(100,true,"alchemist_tasting_stall")
 var dissolve=g.command_facts().filter(func(candidate):return candidate.payload.get("choice","").begins_with("dissolve__"))
 t.check(dissolve.size()==1 and dissolve[0].valid,"ALCHEMIST one-restraint solvent freezes one valid removal candidate")
 if not dissolve.is_empty():
  var selected=g.state.room_event.options.filter(func(option):return option.id==dissolve[0].payload.choice)[0].selected
  var selected_id=selected.id
  t.check(g.dispatch(g.command(dissolve[0].payload,g.state.version),g.state.version).ok and g._equipment(selected_id).is_empty() and g.state.room_event.report.contains(selected.name),"ALCHEMIST solvent fully removes and names the selected restraint")
 var unbound=Game.new(101);Events.arrive(unbound,"alchemist_tasting_stall")
 t.check(not unbound.command_facts().any(func(candidate):return candidate.payload.get("choice","").begins_with("dissolve__")),"ALCHEMIST hides the solvent choice when there is no restraint to select")

 g=Game.new(102,true,"alchemist_tasting_stall")
 var offered=g.state.room_event.relic
 var deck_before=g.state.deck.size()
 t.check(offered!="" and t.action(g,"event",{"action":"choose","choice":"succubus_mix"}).ok and offered in g.state.relics,"ALCHEMIST succubus mix grants the frozen random relic")
 t.check(g.state.deck.size()==deck_before+1 and g.state.deck.any(func(card):return card.type=="sensitive") and g.state.room_event.report.contains("粉色媚药"),"ALCHEMIST succubus mix also grants Sensitive and describes drinking the aphrodisiac")

static func abandoned_storeroom(t) -> void:
 var g=Game.new(103,true,"abandoned_storeroom")
 var search=g.state.room_event.options.filter(func(option):return option.id=="search")
 t.check(search.size()==1 and g.command_facts().filter(func(candidate):return candidate.payload.get("choice","")=="search").size()==1,"STOREROOM starts with one authored search choice")
 if search.is_empty(): return
 var frozen=search[0].item_rewards
 var by_id={}
 for row in frozen: by_id[row.id]=row.type
 t.check(frozen.size()==3 and by_id.potion in ["mana_potion","energy_potion","charge_potion"] and by_id.scroll in ["draw_scroll","mana_scroll","casting_scroll"] and by_id.tool in ["shard","saw"],"STOREROOM freezes exactly one potion, one scroll and one tool")
 var before=g.export_snapshot();g.get_view();g.command_facts();g.route_view()
 t.check(g.export_snapshot()==before and g.state.room_event.options[0].item_rewards==frozen,"STOREROOM viewing and previewing do not reroll the three items")
 var twin=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"storeroom frozen search rewards")
 t.check(twin.state.room_event.options[0].item_rewards==frozen,"STOREROOM pending grouped rewards survive snapshot validation")
 t.check(t.action(g,"event",{"action":"choose","choice":"search"}).ok and g.state.phase=="reward" and g.state.room_event.stage=="loot","STOREROOM search opens the shared reward phase")
 t.check(g.state.reward_options.is_empty() and g.state.battle_item_drop=="" and g.state.battle_relic_drop=="" and g.get_view().battle_rewards.size()==3,"STOREROOM reward page contains only the three event items")
 var loot_save=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"storeroom item reward page")
 t.check(loot_save.state.room_event.loot==g.state.room_event.loot,"STOREROOM unclaimed item page survives snapshot validation without reroll")
 var count_before=g.state.items.size()
 for row in frozen:
  t.check(t.action(g,"reward",{"category":"item","type":row.type,"reward_id":row.id}).ok,"STOREROOM each frozen item is directly claimable: "+row.id)
 t.check(g.state.items.size()==count_before+3 and g.state.room_event.loot.all(func(row):return row.claimed),"STOREROOM all three direct pickups enter the ordinary item inventory")
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="cleared" and g.state.phase not in ["prepare","pack"],"STOREROOM continue ends practice without preparation or item packing")

 g=Game.new(104)
 g._gain_tool("mana_potion");g._gain_tool("draw_scroll")
 Events.arrive(g,"abandoned_storeroom")
 t.check(t.action(g,"event",{"action":"choose","choice":"search"}).ok,"STOREROOM capacity fixture reaches the reward page")
 var first=g.command_facts().filter(func(candidate):return candidate.payload.get("reward_id","")!="" and candidate.valid)[0]
 t.check(g.dispatch(g.command(first.payload,g.state.version),g.state.version).ok and g.carried_items()==g.item_capacity(),"STOREROOM can claim one item into the final free slot")
 var blocked=g.command_facts().filter(func(candidate):return candidate.payload.get("reward_id","")!="")
 t.check(blocked.size()==2 and blocked.all(func(candidate):return not candidate.valid and candidate.reason.contains("道具栏已满")),"STOREROOM remaining items show a concrete capacity reason instead of entering packing")
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="map" and g.state.completed_rooms.has(g.state.room),"STOREROOM abandoning remaining items returns directly to the tower route")

static func bound_dream_guest_room(t) -> void:
 var sleeper=Game.new(105,true,"bound_dream_guest_room")
 sleeper.state.mana_max=132;sleeper.state.mana=17
 Events.arrive(sleeper,"bound_dream_guest_room")
 var choices=sleeper.command_facts().filter(func(candidate):return candidate.payload.get("action","")=="choose")
 t.check(choices.map(func(candidate):return candidate.payload.choice)==["sleep","take_core"] and choices.all(func(candidate):return candidate.valid),"GUEST ROOM exposes exactly the two authored trades")
 var sleep=sleeper.state.room_event.options.filter(func(option):return option.id=="sleep")[0]
 var installs=sleep.effects.filter(func(effect):return effect.op=="install")
 t.check(sleep.effects.any(func(effect):return effect.op=="mana_restore_full") and installs.size()==3 and installs.all(func(effect):return effect.grade==2 and effect.tier==1 and not effect.locked) and not sleep.effects.any(func(effect):return effect.op=="link"),"GUEST ROOM freezes full restoration and exactly three medium tier-one single restraints")
 var equipment_before=sleeper.state.equipment.size()
 t.check(t.action(sleeper,"event",{"action":"choose","choice":"sleep"}).ok and sleeper.state.mana==sleeper.state.mana_max and sleeper.state.equipment.size()==equipment_before+3,"GUEST ROOM sleep commits full mana and all three restraints atomically")
 t.check(installs.all(func(effect):return sleeper.state.room_event.report.contains(sleeper.Equipment.wear_text(sleeper.Equipment.name_for(effect.template,effect.slot,effect.grade,effect.get("variant",0)),effect.slot,"animated"))) and not sleeper.state.room_event.report.contains("她把") and not sleeper.state.room_event.report.contains("她合拢"),"GUEST ROOM sleep result uses autonomous body-specific wear prose")

 var core=Game.new(106,true,"bound_dream_guest_room")
 core.state.mana=100
 # Isolate the maximum-mana trade from unrelated relic pickup bonuses.
 core.state.relics.append_array(core.Relics.REWARDS.filter(func(id):return id!="small_gem"))
 Events.arrive(core,"bound_dream_guest_room")
 var offered=core.state.room_event.relic
 var relic_count=core.state.relics.size()
 t.check(offered!="" and t.action(core,"event",{"action":"choose","choice":"take_core"}).ok,"GUEST ROOM bed core trade commits through the generic event transaction")
 t.check(core.state.mana_max==92 and core.state.mana==92 and core.state.relics.size()==relic_count+1 and offered in core.state.relics,"GUEST ROOM bed core permanently removes eight maximum mana, clamps current mana and grants the frozen relic")
 t.check(core.state.room_event.report.contains("最大魔力永久降低8点") and core.state.room_event.report.contains(core.Relics.TYPES[offered].name),"GUEST ROOM result states the permanent loss and exact relic")
 var resumed=preload("res://tests/persistence_cases.gd").roundtrip(t,core,"guest room reduced maximum mana")
 t.check(resumed.state.mana_max==92 and resumed.state.mana==92 and offered in resumed.state.relics,"GUEST ROOM reduced maximum and reward survive current snapshot validation")

 var low_current=Game.new(108,true,"bound_dream_guest_room")
 low_current.state.mana=40
 low_current.state.relics.append_array(low_current.Relics.REWARDS.filter(func(id):return id!="small_gem"))
 Events.arrive(low_current,"bound_dream_guest_room")
 t.check(t.action(low_current,"event",{"action":"choose","choice":"take_core"}).ok and low_current.state.mana_max==92 and low_current.state.mana==40,"GUEST ROOM maximum loss preserves current mana when it is already below the new cap")

 var floor_case=Game.new(107,true,"bound_dream_guest_room")
 floor_case.state.mana_max=8;floor_case.state.mana=8
 t.check(floor_case.Events.probe(floor_case,[{"op":"mana_max_loss","amount":8}]).contains("不足以承受") and floor_case.state.mana_max==8 and floor_case.state.mana==8,"GUEST ROOM generic maximum-mana loss refuses crossing the positive floor without mutation")

static func mysterious_woman_statue(t) -> void:
 var g=Game.new(109,true,"mysterious_woman_statue")
 var choices=g.command_facts().filter(func(candidate):return candidate.payload.get("action","")=="choose")
 t.check(choices.map(func(candidate):return candidate.payload.choice)==["use_sleeve","collect_mana","leave"] and choices.all(func(candidate):return candidate.valid),"STATUE exposes exactly the sleeve, flask-mana and free-departure choices")
 var authored=JSON.stringify(g.Events.Data.TYPES.mysterious_woman_statue)
 t.check(authored.contains("神秘") and authored.contains("女人像") and authored.contains("飞机杯") and not authored.contains("翼魔") and not authored.contains("魅魔圣像"),"STATUE presents a mysterious sensual woman statue with the fixed sleeve")
 var use_option=g.state.room_event.options.filter(func(option):return option.id=="use_sleeve")[0]
 t.check(not use_option.report.contains("卡组") and not use_option.report.contains("卡牌") and use_option.report.contains("将勃起的肉棒慢慢插进飞机杯") and use_option.report.contains("把精液尽数射进杯底"),"STATUE ejaculation scene stays physical and does not turn cards into story-world props")
 var deck_before=g.state.deck.size();var climax_before=g.state.overload_total;var mana_before=g.state.mana
 t.check(t.action(g,"event",{"action":"choose","choice":"use_sleeve"}).ok and g.state.room_event.stage=="remove_card","STATUE sleeve scene resolves before opening the shared card selector")
 t.check(g.state.overload_total-climax_before==1 and g.state.mana==mana_before-g.B.OVERLOAD_MANA and g.state.deck.size()==deck_before,"STATUE sleeve causes one ordinary climax and its semen-bound mana loss before removal")
 var selected_uid=g.state.deck[0].uid
 t.check(t.action(g,"event",{"action":"choose","choice":"remove__"+selected_uid}).ok and g.state.deck.size()==deck_before-1 and g.state.deck.all(func(card):return card.uid!=selected_uid),"STATUE removes the selected physical card through the shared selector")

 g=Game.new(110,true,"mysterious_woman_statue")
 var collect=g.state.room_event.options.filter(func(option):return option.id=="collect_mana")[0]
 var gains=collect.effects.filter(func(effect):return effect.op=="flask_mana_gain")
 t.check(gains.size()==1 and gains[0].amount is int and gains[0].amount>=30 and gains[0].amount<=60 and not collect.effects.any(func(effect):return effect.op=="random_amount"),"STATUE freezes the generic random amount into one fixed flask-mana effect")
 var frozen_amount=gains[0].amount
 var frozen_state=g.export_snapshot();g.get_view();g.command_facts();g.route_view()
 t.check(g.export_snapshot()==frozen_state and g.state.room_event.options.filter(func(option):return option.id=="collect_mana")[0].effects[0].amount==frozen_amount,"STATUE viewing and probing do not reroll the frozen amount")
 var flask_before=g.state.flask_mana;var deposits_before=g.state.flask_deposits
 var result=t.action(g,"event",{"action":"choose","choice":"collect_mana"})
 var feedback=result.get("resource_feedback",[]).filter(func(row):return row.field=="flask_mana")
 t.check(result.ok and g.state.flask_mana==flask_before+frozen_amount and g.state.flask_deposits==deposits_before,"STATUE adds the exact frozen amount directly to the flask without using a deposit")
 t.check(feedback.size()==1 and feedback[0].before==flask_before and feedback[0].after==flask_before+frozen_amount and g.state.room_event.report.contains(str(frozen_amount)),"STATUE reports the exact frozen flask gain through the existing result and resource feedback")

 g=Game.new(111,true,"mysterious_woman_statue")
 var leave_before=g.export_snapshot()
 t.check(t.action(g,"event",{"action":"choose","choice":"leave"}).ok and g.state.room_event.stage=="result","STATUE free departure reaches the neutral result")
 t.check(g.state.mana==leave_before.mana and g.state.flask_mana==leave_before.flask_mana and g.state.pressure==leave_before.pressure and g.state.deck==leave_before.deck and g.state.equipment==leave_before.equipment,"STATUE free departure changes no resource, card or equipment state")

 var lock_types=["negative_plate_lock_medium","negative_plate_lock_catheter_medium","negative_vibrator_lock_catheter_high"]
 var blocked_reason="平板锁封住了肉棒，无法插进浅盘上的飞机杯。"
 for index in range(lock_types.size()):
  var blocked=Game.new(112+index,true,"mysterious_woman_statue")
  var lock=blocked._install_special(lock_types[index],"special_2_a",3 if lock_types[index].ends_with("_high") else 2)
  var sleeve=t.find_action(blocked,"event",{"action":"choose","choice":"use_sleeve"})
  var alternatives=blocked.command_facts().filter(func(candidate):return candidate.payload.get("choice","") in ["collect_mana","leave"])
  t.check(not lock.is_empty() and not sleeve.valid and sleeve.get("reason","")==blocked_reason and sleeve.get("reason_surface","")=="secondary" and alternatives.all(func(candidate):return candidate.valid),"STATUE every worn plate-lock model blocks only the sleeve option with its authored explanation: "+lock_types[index]+" | lock="+str(lock)+" sleeve="+str(sleeve)+" validate="+blocked.validate()+" special="+blocked.SpecialEquipment.validate(blocked.state.special_equipment))
  var before=blocked.export_snapshot()
  t.check(not blocked.dispatch(blocked.command(sleeve.payload,blocked.state.version),blocked.state.version).ok and blocked.export_snapshot()==before,"STATUE blocked sleeve submission rolls back every state surface: "+lock_types[index])
  if index==0:
   lock.locked=false
   t.check(not t.find_action(blocked,"event",{"action":"choose","choice":"use_sleeve"}).valid,"STATUE an unlocked but still worn plate lock continues to block sleeve insertion")
   blocked.state.special_equipment.clear();blocked._cleanup()
   t.check(t.find_action(blocked,"event",{"action":"choose","choice":"use_sleeve"}).valid,"STATUE removing the plate lock immediately restores the sleeve option")

 var other_toy=Game.new(116,true,"mysterious_woman_statue")
 t.check(not other_toy._install_special("shaft_ring_medium","special_2_a",2).is_empty() and t.find_action(other_toy,"event",{"action":"choose","choice":"use_sleeve"}).valid,"STATUE other worn sex toys do not inherit the plate-lock-only restriction")

static func maze_survey_team(t) -> void:
 var g=Game.new(112,true,"maze_survey_team")
 var choices=g.command_facts().filter(func(candidate):return candidate.payload.get("action","")=="choose")
 t.check(choices.map(func(candidate):return candidate.payload.choice)==["solo","together"] and choices.all(func(candidate):return candidate.valid),"SURVEY TEAM exposes exactly solo exploration and travelling together")
 var authored=JSON.stringify(g.Events.Data.TYPES.maze_survey_team)
 t.check(not authored.contains("金币") and not authored.contains("生命") and authored.contains("独自探险") and authored.contains("结伴而行"),"SURVEY TEAM replaces source gold and health language with the two confirmed choices")
 var solo=g.state.room_event.options.filter(func(option):return option.id=="solo")[0]
 var installs=solo.effects.filter(func(effect):return effect.op=="install")
 t.check(solo.effects.any(func(effect):return effect.op=="flask_mana_gain" and effect.amount==100) and installs.size()==2 and installs.all(func(effect):return effect.grade==2 and effect.tier==2 and not effect.locked) and not solo.effects.any(func(effect):return effect.op=="link"),"SURVEY TEAM freezes one hundred flask mana and two medium tier-two single restraints")
 var frozen=g.export_snapshot();g.get_view();g.command_facts();g.route_view()
 t.check(g.export_snapshot()==frozen,"SURVEY TEAM viewing and probing do not reroll either restraint")
 var flask_before=g.state.flask_mana;var deposits_before=g.state.flask_deposits;var equipment_before=g.state.equipment.size()
 var result=t.action(g,"event",{"action":"choose","choice":"solo"})
 t.check(result.ok and g.state.flask_mana==flask_before+100 and g.state.flask_deposits==deposits_before and g.state.equipment.size()==equipment_before+2,"SURVEY TEAM solo branch atomically grants flask mana and installs both restraints")
 t.check(installs.all(func(effect):return g.state.room_event.report.contains(g.Equipment.wear_text(g.Equipment.name_for(effect.template,effect.slot,effect.grade,effect.get("variant",0)),effect.slot,"animated"))) and not g.state.room_event.report.contains("她把") and not g.state.room_event.report.contains("她合拢"),"SURVEY TEAM solo result appends both autonomous wear texts")

 g=Game.new(113,true,"maze_survey_team")
 flask_before=g.state.flask_mana;deposits_before=g.state.flask_deposits;equipment_before=g.state.equipment.size()
 result=t.action(g,"event",{"action":"choose","choice":"together"})
 t.check(result.ok and g.state.flask_mana==flask_before+30 and g.state.flask_deposits==deposits_before and g.state.equipment.size()==equipment_before,"SURVEY TEAM together branch grants thirty flask mana without adding restraints")
 t.check(g.state.room_event.stage=="result" and g.state.room_event.report.contains("合作愉快") and g.state.room_event.result_status=="success","SURVEY TEAM together branch reaches a clear successful result")

# docs/spec/event-pipeline.md「证据入口」: every authored node declares the
# policy that reproduces today's behaviour, and options keep the compatibility spelling.
static func event_option_policies_match_current_behaviour(t) -> void:
 var g=Game.new(42)
 var single=["disable","pool","generators","option","in_place","allow"]
 var multi=["hide","claimed","always","option","staged","fail"]
 var single_count=0
 var multi_count=0
 for id in g.Events.Data.TYPES.keys():
  var spec=g.Events.Data.TYPES[id]
  for entry in spec.nodes:
   var expected=multi if spec.nodes.size()>1 else single
   var declared=[entry.unavailable,entry.relic_gate,entry.random_freeze,entry.outcome_draw,entry.frozen_form,entry.empty_node]
   t.check(declared==expected,"EVENT POLICY node declares today's behaviour "+id+"/"+str(entry.id))
   if spec.nodes.size()==1:
    single_count+=1
    t.check(entry.allow_refuse==false,"EVENT POLICY single node keeps its authored refusal "+id)
    t.check(entry.id=="choice" and spec.start_node=="choice","EVENT POLICY single node keeps the sentinel start "+id)
   else:
    multi_count+=1
    var expected_refusal=id=="succubus_three_games" and entry.id=="wager_card"
    t.check(entry.allow_refuse==expected_refusal,"EVENT POLICY staged node keeps its authored refusal "+id+"/"+str(entry.id))
   for choice in entry.choices:
    t.check(not choice.has("conditions") and not choice.has("unavailable"),"EVENT POLICY authored option keeps the compatibility spelling "+id+"/"+str(entry.id)+"/"+str(choice.id))
 t.check(single_count==8 and multi_count==21,"EVENT POLICY all twelve definitions declare their nodes")
 var staged=g.Events.Data.TYPES.succubus_three_games
 t.check(staged.start_node=="wager_card" and staged.nodes.size()==8 and g.Events.node_ids(staged)[7]=="remove_reward","EVENT POLICY staged definition keeps its authored order")
 t.check(g.Events.node(g.Events.Data.TYPES.binding_cleric,"service").choices.size()==3 and g.Events.node(staged,"missing").is_empty(),"EVENT POLICY node lookup resolves real ids and returns empty for unknown ones")

# docs/spec/event-pipeline.md「证据入口」: a single node reads the declared
# next／when／outcomes, and a selector plus outcomes spends exactly one draw per choice.
static func event_single_node_declarations(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var nodes=[{"id":"choice","allow_refuse":false,"unavailable":"disable","relic_gate":"pool","random_freeze":"generators","outcome_draw":"option","frozen_form":"in_place","empty_node":"allow","choices":[
  {"id":"gated","label":"计数达标","reward":"none","next":"result","detail":"计数未达标时不生成。","when":{"counter":"seen","equals":1},"effects":[{"op":"mana_gain","amount":1}]},
  {"id":"rolled","label":"随机结果","reward":"none","next":"result","detail":"从两种公开结果中随机确定一种。","outcomes":[{"weight":1,"effects":[{"op":"mana_gain","amount":3}],"report":"结果甲","result_status":"success"},{"weight":1,"effects":[{"op":"mana_gain","amount":5}],"report":"结果乙","result_status":"failure"}]}]}]
 var document={"file":"memory://single_node.json","data":{"schema_version":2,"kind":"event","id":"single_node_fixture","name":"单节点声明夹具","intro":"只用于验证单节点声明的夹具。","start_node":"choice","nodes":nodes}}
 var compiled=Catalog.compile(g,[document])
 t.check(compiled.ok,"EVENT SINGLE NODE fixture compiles: "+str(compiled.errors))
 if not compiled.ok: return
 Catalog.commit(g,compiled.tables)
 var walk=Game.new(42);Events.arrive(walk,"single_node_fixture")
 t.check(not walk.state.room_event.options.any(func(o):return o.id=="gated"),"EVENT SINGLE NODE unmet when leaves the option out")
 var rolled=walk.state.room_event.options.filter(func(o):return o.id=="rolled")
 t.check(rolled.size()==1 and rolled[0].effects.size()==1 and rolled[0].reward=="none" and rolled[0].next=="result" and rolled[0].report in ["结果甲","结果乙"] and rolled[0].result_status in ["success","failure"],"EVENT SINGLE NODE outcomes freeze into a concrete option")
 walk.state.room_event.values.seen=1
 walk.Events.enter_node(walk,"choice")
 t.check(walk.state.room_event.options.any(func(o):return o.id=="gated"),"EVENT SINGLE NODE met when keeps the option")
 var select_document=document.duplicate(true)
 select_document.data.id="single_node_selector_fixture"
 select_document.data.nodes[0].choices=[{"id":"pair","label":"解除2件","reward":"none","detail":"从公开结果中随机确定一种。","selector":{"kind":"restraint","count":2},"effects":[{"op":"remove_restraints","targets":"$selected"}],"outcomes":[{"weight":1,"effects":[{"op":"mana_gain","amount":4}],"report":"结果一"},{"weight":1,"effects":[{"op":"mana_gain","amount":6}],"report":"结果二"}]}]
 t.check(Catalog.compile(walk,[select_document]).ok,"EVENT SINGLE NODE selector fixture compiles")
 Catalog.commit(walk,Catalog.compile(walk,[select_document]).tables)
 var pair=Game.new(43);pair.add_fixture("wrist",8);pair.add_fixture("ankle",8)
 var rng_before=pair.state.rng.event
 Events.arrive(pair,"single_node_selector_fixture")
 var pair_options=pair.state.room_event.options
 t.check(pair_options.size()==1 and pair_options[0].selected is Array and pair_options[0].selected.size()==2,"EVENT SINGLE NODE selector expands one atomic pair")
 t.check(pair.state.rng.event-rng_before==1,"EVENT SINGLE NODE outcome_draw option spends exactly one draw for the whole choice")
 Catalog.commit(g,baseline)
 var restore=Game.new(42)
 t.check(Catalog.tables(restore)==baseline,"EVENT SINGLE NODE fixture registries restored")

# docs/spec/event-pipeline.md「证据入口」: empty nodes keep their declared policy.
static func event_node_empty_policy_kept(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var empty_node={"id":"choice","allow_refuse":false,"unavailable":"disable","relic_gate":"pool","random_freeze":"generators","outcome_draw":"option","frozen_form":"in_place","empty_node":"allow","choices":[
  {"id":"waiting","label":"尚未开放","reward":"none","next":"result","detail":"计数未达标时不生成。","when":{"counter":"seen","equals":1},"effects":[{"op":"mana_gain","amount":1}]}]}
 var document={"file":"memory://empty_node.json","data":{"schema_version":2,"kind":"event","id":"empty_node_fixture","name":"空节点夹具","intro":"只用于验证空节点策略的夹具。","start_node":"choice","nodes":[empty_node]}}
 t.check(Catalog.compile(g,[document]).ok,"EVENT EMPTY NODE single-node empty fixture compiles")
 Catalog.commit(g,Catalog.compile(g,[document]).tables)
 var walk=Game.new(42);Events.arrive(walk,"empty_node_fixture")
 t.check(walk.state.room_event.options.is_empty() and walk.state.room_event.stage=="choice" and walk.state.room_event.result_status=="neutral","EVENT EMPTY NODE single node keeps zero facts instead of failing")
 t.check(walk.command_facts().filter(func(c):return c.payload.get("kind","")=="event").is_empty(),"EVENT EMPTY NODE zero facts stay consistent")
 t.check(walk.validate()=="","EVENT EMPTY NODE zero facts stay valid")
 var staged=document();staged.data.id="empty_stage_fixture"
 for choice in staged.data.nodes[2].choices: choice.when={"counter":"seen","equals":1}
 var staged_compile=Catalog.compile(g,[staged])
 t.check(staged_compile.ok,"EVENT EMPTY NODE staged empty fixture compiles: "+str(staged_compile.errors))
 if not staged_compile.ok: Catalog.commit(g,baseline); return
 Catalog.commit(g,staged_compile.tables)
 var flow=Game.new(44);Events.arrive(flow,"empty_stage_fixture")
 t.check(flow.Events.enter_node(flow,"finale")=="这一阶段没有能够执行的选项。","EVENT EMPTY NODE staged node reports its named issue")
 var empty_issue=flow.Events.enter_node(flow,"penalty")
 if empty_issue!="": t.check(false,"EVENT EMPTY NODE penalty node stays enterable: "+empty_issue)
 var blocked=flow.command_facts().filter(func(c):return c.payload.get("choice","")=="two_ropes")
 t.check(blocked.size()==1 and not blocked[0].valid and str(blocked[0].get("reason",""))!="","EVENT EMPTY NODE an option whose next node is empty turns invalid: "+str(blocked[0].get("reason","")) if not blocked.is_empty() else "EVENT EMPTY NODE an option whose next node is empty turns invalid")
 var hollow_probe=flow.Events.probe(flow,[],{"id":"two_ropes","label":"安装","reward":"none","next":"finale","effects":[]})
 t.check(hollow_probe=="这一阶段没有能够执行的选项。","EVENT EMPTY NODE the probe path reports the empty next node: "+hollow_probe)
 Catalog.commit(g,baseline)

# docs/spec/event-pipeline.md「证据入口」: a committed cross-event jump keeps one
# instance — the target's id and node, the source in chain, continuing counters and holds, the
# chain union cleanup (one step per key, run once on leaving) and the target in event_seen.
static func event_chain_jumps_to_another_event_node(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var compiled=Catalog.compile(g,chain_documents())
 t.check(compiled.ok,"EVENT CHAIN fixtures compile: "+str(compiled.errors))
 if not compiled.ok: return
 Catalog.commit(g,compiled.tables)
 t.check(g.Events.chain_cleanup([{"op":"restore_held","key":"first"}],[{"op":"restore_held","key":"first"},{"op":"restore_held","key":"second"}]).map(func(entry):return entry.key)==["first","second"],"EVENT CHAIN the cleanup union keeps one step per key, source first")
 var walk=Game.new(42)
 t.check(not walk._install_special("shaft_ring_low","special_2_a").is_empty() and not walk._install_special("corona_ring_low","special_2_c").is_empty(),"EVENT CHAIN the fixture wears two real special items")
 Events.arrive(walk,"chain_source_fixture")
 t.check(walk.state.room_event.options.map(func(option):return option.id)==["depart","stay"] and not walk.state.room_event.has("chain"),"EVENT CHAIN the source node freezes its authored options without a chain key")
 var jump=t.action(walk,"event",{"action":"choose","choice":"depart"})
 t.check(jump.ok,"EVENT CHAIN the source option commits through the formal command: "+str(jump.get("error","")))
 var event=walk.state.room_event
 t.check(event.id=="chain_target_fixture" and event.stage=="entry","EVENT CHAIN the commit rewrites the instance to the target event and its node: "+str(event.id)+"/"+str(event.stage))
 t.check(event.chain==["chain_source_fixture"],"EVENT CHAIN the chain records the events already left behind: "+str(event.chain))
 t.check(event.values.get("chain_seen",0)==1,"EVENT CHAIN counters continue across the chain")
 t.check(event.held.has("chain_source_gear") and event.held.chain_source_gear.size()==1,"EVENT CHAIN holds continue across the chain")
 t.check(event.flow and walk.Events.definition(event.id).nodes.size()==2,"EVENT CHAIN the flow mirror follows the target definition")
 t.check(walk.state.event_seen.count("chain_target_fixture")==1 and walk.state.event_seen.count("chain_source_fixture")==1,"EVENT CHAIN the target joins event_seen exactly once")
 t.check(event.cleanup_effects.map(func(entry):return entry.key)==["chain_source_gear","chain_target_gear"],"EVENT CHAIN cleanup is the chain union with one step per key: "+str(event.cleanup_effects.map(func(entry):return entry.key)))
 t.check(walk.validate()=="","EVENT CHAIN the rewritten instance still validates: "+walk.validate())
 t.check(t.action(walk,"event",{"action":"choose","choice":"proceed"}).ok and walk.state.room_event.stage=="finale","EVENT CHAIN the target event advances through its own nodes")
 t.check(walk.state.room_event.held.keys().size()==2,"EVENT CHAIN both chain holds coexist in one instance")
 t.check(t.action(walk,"event",{"action":"choose","choice":"settle"}).ok and walk.state.room_event.stage=="result","EVENT CHAIN the target event reaches its result")
 var logs_before=walk.state.logs.size()
 t.check(t.action(walk,"event",{"action":"leave"}).ok,"EVENT CHAIN the chain leaves through the formal command")
 var restored=walk.state.logs.slice(logs_before).filter(func(log):return str(log.text).contains("原样装回"))
 t.check(restored.size()==2,"EVENT CHAIN every chain cleanup step runs exactly once: "+str(restored.size()))
 t.check(walk.state.special_equipment.size()==2 and walk.state.room_event.held.is_empty(),"EVENT CHAIN the union restores every held instance")
 Catalog.commit(g,baseline)

# docs/spec/event-pipeline.md「证据入口」: the chain may not return to an event it
# already left — the option stays visible but invalid with gate chain_loop, and evaluating or
# submitting it changes neither the state, the random domains nor the save.
static func event_chain_loop_refused(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var compiled=Catalog.compile(g,chain_documents())
 t.check(compiled.ok,"EVENT CHAIN LOOP fixtures compile: "+str(compiled.errors))
 if not compiled.ok: return
 Catalog.commit(g,compiled.tables)
 var walk=Game.new(42)
 Events.arrive(walk,"chain_source_fixture")
 t.check(t.action(walk,"event",{"action":"choose","choice":"depart"}).ok and walk.state.room_event.chain==["chain_source_fixture"],"EVENT CHAIN LOOP the fixture arrives at the target with the source already left")
 var settled=walk.export_snapshot()
 var domain=walk.state.rng.duplicate(true)
 var loop_option=walk.state.room_event.options.filter(func(option):return option.id=="loop_back")
 t.check(loop_option.size()==1,"EVENT CHAIN LOOP the looping option stays among the frozen options")
 var loop=walk.command_facts().filter(func(candidate):return candidate.payload.get("choice","")=="loop_back")
 t.check(loop.size()==1 and not loop[0].valid,"EVENT CHAIN LOOP the looping option stays visible but invalid: "+str(loop[0].get("reason","")) if not loop.is_empty() else "EVENT CHAIN LOOP the looping option stays visible but invalid")
 var result=walk.Events.evaluate_option(walk,walk.Events.request_for(walk,loop_option[0],"candidate"))
 t.check(result.decision=="disabled" and result.gates.size()==1 and str(result.gates[0].gate)=="chain_loop" and str(result.gates[0].kind)=="chain" and str(result.gates[0].detail)=="chain_source_fixture","EVENT CHAIN LOOP the looping option reports the chain_loop gate: "+JSON.stringify(result.gates))
 t.check(result.reason==walk.Events.CHAIN_LOOP_REASON and result.reason!="","EVENT CHAIN LOOP the disabled option carries its own reason")
 t.check(walk.export_snapshot()==settled and walk.state.rng==domain,"EVENT CHAIN LOOP evaluating the loop leaves the state, the save and the random domains untouched")
 var before_submit=walk.export_snapshot()
 t.check(not t.action(walk,"event",{"action":"choose","choice":"loop_back"}).ok and walk.export_snapshot()==before_submit,"EVENT CHAIN LOOP a looping option cannot commit")
 Catalog.commit(g,baseline)

# docs/spec/event-pipeline.md「证据入口」: both node-entry failures write one
# node-level row with the target node and no option, the next-node look-ahead uses its own
# purpose, and repeated look-aheads of one target never repeat the row.
static func event_chain_trace_rows(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var compiled=Catalog.compile(g,chain_documents())
 t.check(compiled.ok,"EVENT CHAIN TRACE fixtures compile: "+str(compiled.errors))
 if not compiled.ok: return
 Catalog.commit(g,compiled.tables)
 var walk=Game.new(42)
 walk.set_meta("event_trace_enabled",true)
 Events.arrive(walk,"chain_source_fixture")
 walk.Events.enter_node_result(walk,"missing_node")
 walk.Events.enter_node_result(walk,"missing_node")
 walk.Events.enter_node(walk,"other_missing_node")
 var missing=walk.Events.event_trace(walk).filter(func(row):return row.gate=="stage_missing")
 t.check(missing.size()==2 and missing[0].node=="missing_node" and missing[1].node=="other_missing_node","EVENT CHAIN TRACE a missing node writes one node-level row per target: "+JSON.stringify(missing))
 t.check(missing.all(func(row):return str(row.option_id)=="" and str(row.source_choice)=="" and str(row.purpose)=="arrival" and str(row.event)=="chain_source_fixture"),"EVENT CHAIN TRACE the missing-node row carries the target node, no option and the arrival purpose: "+JSON.stringify(missing))
 # A31: the emptied target node is looked ahead by two frozen options, and the identical
 # node-level rows collapse into one carrying purpose next_probe. The registries are restored
 # first, because the compiled event table is shared by every game in this process.
 var blocked=chain_documents()
 blocked[1].data.nodes[1].choices[0].when={"counter":"never_seen","equals":1}
 Catalog.commit(g,baseline)
 var blocked_compile=Catalog.compile(g,blocked)
 t.check(blocked_compile.ok,"EVENT CHAIN TRACE the emptied-target fixtures compile: "+str(blocked_compile.errors))
 if blocked_compile.ok:
  Catalog.commit(g,blocked_compile.tables)
  var probe=Game.new(42)
  probe.set_meta("event_trace_enabled",true)
  Events.arrive(probe,"chain_source_fixture")
  t.check(t.action(probe,"event",{"action":"choose","choice":"depart"}).ok,"EVENT CHAIN TRACE the emptied-target chain still jumps")
  probe.command_facts()
  # Gate node_empty also names the per-option feasibility hit (kind feasibility); the A31 row
  # is the node-level one, identified by its empty option_id.
  var empty=probe.Events.event_trace(probe).filter(func(row):return row.gate=="node_empty" and str(row.option_id)=="")
  t.check(empty.size()==1 and str(empty[0].purpose)=="next_probe" and str(empty[0].node)=="finale","EVENT CHAIN TRACE the look-ahead uses its own purpose and writes one row per target: "+JSON.stringify(empty))
  t.check(empty.all(func(row):return str(row.event)=="chain_target_fixture" and str(row.option_id)=="" and str(row.source_choice)==""),"EVENT CHAIN TRACE the look-ahead row names the probed node and no option")
  t.check(probe.Events.event_trace(probe).filter(func(row):return row.purpose=="next_probe").size()==1,"EVENT CHAIN TRACE frozen instances never repeat the look-ahead row")
 Catalog.commit(g,baseline)

# docs/spec/event-pipeline.md「证据入口」:
# the source optionally offers a relic reward of its own, the target decides whether it offers
# one, and neither end holds special equipment — so the only domains under test are the relic
# draw and the target's own node entry.
static func chain_relic_node(choices: Array) -> Dictionary:
 return {"id":"choice","allow_refuse":false,"unavailable":"disable","relic_gate":"pool","random_freeze":"generators","outcome_draw":"option","frozen_form":"in_place","empty_node":"allow","choices":choices}

static func chain_relic_documents(target_id: String, target_offers_relic: bool, source_offers_relic: bool=false) -> Array:
 var source_choices=[{"id":"depart","label":"动身前往下一段事件","reward":"none","next":{"event":target_id,"node":"choice"},"detail":"带上一项计数进入另一段事件。","effects":[{"op":"counter","key":"chain_seen","amount":1}]}]
 if source_offers_relic: source_choices.append({"id":"carry_relic","label":"先领走本事件冻结的遗物","reward":"relic","next":"result","detail":"领走一件随机遗物。","effects":[]})
 var target_choices=[{"id":"stay","label":"留在本事件","reward":"none","next":"result","detail":"不领取遗物。","effects":[{"op":"mana_gain","amount":1}]}]
 if target_offers_relic: target_choices.append({"id":"grab","label":"领走本事件冻结的遗物","reward":"relic","next":"result","detail":"领走一件随机遗物。","effects":[]})
 return [
  {"file":"memory://chain_relic_source.json","data":{"schema_version":2,"kind":"event","id":"chain_relic_source","name":"遗物重抽起点夹具","intro":"只用于验证跨事件跳转的遗物重抽。","start_node":"choice","nodes":[chain_relic_node(source_choices)]}},
  {"file":"memory://"+target_id+".json","data":{"schema_version":2,"kind":"event","id":target_id,"name":"遗物重抽目标夹具","intro":"只用于验证跨事件跳转的遗物重抽。","start_node":"choice","nodes":[chain_relic_node(target_choices)]}}]

# Per-domain random counters between two readings: a jump that recomputes the relic has to
# spend exactly what the same definition spends on its own arrival.
static func rng_delta(before: Dictionary, after: Dictionary) -> Dictionary:
 var delta={}
 for domain in after: delta[domain]=int(after[domain])-int(before.get(domain,0))
 return delta

# docs/spec/event-pipeline.md「证据入口」: a target that declares a relic
# reward draws once on the jump, the drawn relic belongs to the pool that definition may grant,
# and the event and relic domains spend exactly the single-definition arrival draws.
static func event_chain_relic_drawn_from_target(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var compiled=Catalog.compile(g,chain_relic_documents("chain_relic_gift",true))
 t.check(compiled.ok,"EVENT CHAIN RELIC gift fixtures compile: "+str(compiled.errors))
 if not compiled.ok: return
 Catalog.commit(g,compiled.tables)
 var walk=Game.new(42)
 Events.arrive(walk,"chain_relic_source")
 t.check(walk.state.room_event.relic=="","EVENT CHAIN RELIC the source definition offers no relic reward, so it freezes none")
 var chain_before=walk.state.rng.duplicate()
 t.check(t.action(walk,"event",{"action":"choose","choice":"depart"}).ok,"EVENT CHAIN RELIC the source option commits through the formal command")
 var event=walk.state.room_event
 var chain_delta=rng_delta(chain_before,walk.state.rng)
 t.check(event.id=="chain_relic_gift" and event.relic!="","EVENT CHAIN RELIC the jump draws a relic for the target definition: "+str(event.relic))
 t.check(event.relic in walk.RelicRewards.available(walk) and event.relic not in walk.state.relics,"EVENT CHAIN RELIC the drawn relic belongs to the pool the target may grant: "+str(event.relic))
 var direct=Game.new(42)
 var direct_before=direct.state.rng.duplicate()
 Events.arrive(direct,"chain_relic_gift")
 var direct_delta=rng_delta(direct_before,direct.state.rng)
 t.check(direct.state.room_event.relic==event.relic,"EVENT CHAIN RELIC the jump draws the same relic as a single-definition arrival: "+str(event.relic)+" vs "+str(direct.state.room_event.relic))
 t.check(JSON.stringify(chain_delta)==JSON.stringify(direct_delta) and chain_delta.relic==direct_delta.relic and chain_delta.event==direct_delta.event,"EVENT CHAIN RELIC the jump spends exactly the single-definition draws in the event and relic domains: "+JSON.stringify({"chain":chain_delta,"direct":direct_delta}))
 Catalog.commit(g,baseline)

# docs/spec/event-pipeline.md「证据入口」: a target that declares no relic
# reward clears the source relic instead of carrying it over, and spends no extra draw.
static func event_chain_relic_cleared_without_target_offer(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var compiled=Catalog.compile(g,chain_relic_documents("chain_relic_plain",false,true))
 t.check(compiled.ok,"EVENT CHAIN RELIC plain fixtures compile: "+str(compiled.errors))
 if not compiled.ok: return
 Catalog.commit(g,compiled.tables)
 var walk=Game.new(42)
 Events.arrive(walk,"chain_relic_source")
 t.check(walk.state.room_event.relic!="","EVENT CHAIN RELIC the source definition freezes its own relic: "+str(walk.state.room_event.relic))
 var chain_before=walk.state.rng.duplicate()
 t.check(t.action(walk,"event",{"action":"choose","choice":"depart"}).ok,"EVENT CHAIN RELIC the source option commits through the formal command")
 var event=walk.state.room_event
 var chain_delta=rng_delta(chain_before,walk.state.rng)
 t.check(event.id=="chain_relic_plain" and event.relic=="","EVENT CHAIN RELIC a target without a relic reward clears the source relic: "+str(event.relic))
 t.check(not event.options.any(func(option):return option.reward=="relic"),"EVENT CHAIN RELIC the cleared target exposes no relic reward option")
 var direct=Game.new(42)
 var direct_before=direct.state.rng.duplicate()
 Events.arrive(direct,"chain_relic_plain")
 var direct_delta=rng_delta(direct_before,direct.state.rng)
 t.check(direct.state.room_event.relic=="" and JSON.stringify(chain_delta)==JSON.stringify(direct_delta),"EVENT CHAIN RELIC clearing the source relic spends no extra draw: "+JSON.stringify({"chain":chain_delta,"direct":direct_delta}))
 Catalog.commit(g,baseline)

# docs/spec/event-pipeline.md「证据入口」: a target that declares the relic
# reward still keeps the instance empty while the pool is empty, again without spending a draw.
static func event_chain_relic_cleared_when_pool_empty(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var compiled=Catalog.compile(g,chain_relic_documents("chain_relic_exhausted",true))
 t.check(compiled.ok,"EVENT CHAIN RELIC exhausted fixtures compile: "+str(compiled.errors))
 if not compiled.ok: return
 Catalog.commit(g,compiled.tables)
 var walk=Game.new(42)
 walk.state.relics.append_array(walk.Relics.REWARDS)
 t.check(walk.RelicRewards.available(walk).is_empty(),"EVENT CHAIN RELIC the fixture owns the whole relic pool")
 Events.arrive(walk,"chain_relic_source")
 var chain_before=walk.state.rng.duplicate()
 t.check(t.action(walk,"event",{"action":"choose","choice":"depart"}).ok,"EVENT CHAIN RELIC the source option commits through the formal command")
 var event=walk.state.room_event
 var chain_delta=rng_delta(chain_before,walk.state.rng)
 t.check(event.id=="chain_relic_exhausted" and event.relic=="","EVENT CHAIN RELIC an empty relic pool leaves the target instance without a relic: "+str(event.relic))
 t.check(not event.options.any(func(option):return option.reward=="relic"),"EVENT CHAIN RELIC the empty pool drops the target relic option before freezing")
 var direct=Game.new(42)
 direct.state.relics.append_array(direct.Relics.REWARDS)
 var direct_before=direct.state.rng.duplicate()
 Events.arrive(direct,"chain_relic_exhausted")
 var direct_delta=rng_delta(direct_before,direct.state.rng)
 t.check(direct.state.room_event.relic=="" and JSON.stringify(chain_delta)==JSON.stringify(direct_delta),"EVENT CHAIN RELIC an empty pool spends no draw on either path: "+JSON.stringify({"chain":chain_delta,"direct":direct_delta}))
 Catalog.commit(g,baseline)

# docs/spec/event-pipeline.md「证据入口」: stacked condition modes.
static func event_stacked_conditions(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var entries=[[{"kind":"has_relic","type":"softened_buckle","reason":"你还没有拿到那件扣环。","mode":"optional"}],
              [{"kind":"has_relic","type":"softened_buckle","reason":"你还没有拿到那件扣环。","mode":"hidden"}],
              [{"kind":"has_relic","type":"softened_buckle","reason":"你还没有拿到那件扣环。","mode":"optional"},{"kind":"no_chastity_lock","reason":"平板锁封住了这里。","mode":"hidden"}],
              [{"kind":"has_relic","type":"softened_buckle","reason":"条件甲。","mode":"optional"},{"kind":"has_relic","type":"unregistered_probe","reason":"条件乙。","mode":"optional"}]]
 var documents=[]
 for index in range(entries.size()):
  var conditions=entries[index]
  if index==3:
   conditions=[{"kind":"has_relic","type":"softened_buckle","reason":"条件甲。","mode":"optional"},{"kind":"has_relic","type":"small_gem","reason":"条件乙。","mode":"optional"}]
  var node={"id":"choice","allow_refuse":false,"unavailable":"disable","relic_gate":"pool","random_freeze":"generators","outcome_draw":"option","frozen_form":"in_place","empty_node":"allow","choices":[{"id":"stacked","label":"叠加条件","reward":"none","next":"result","detail":"条件决定是否可选。","effects":[{"op":"mana_gain","amount":2}],"conditions":conditions}]}
  documents.append({"file":"memory://stacked_%d.json" % index,"data":{"schema_version":2,"kind":"event","id":"stacked_fixture_%d" % index,"name":"叠加条件夹具","intro":"只用于验证叠加条件的夹具。","start_node":"choice","nodes":[node]}})
 var compiled=Catalog.compile(g,documents)
 t.check(compiled.ok,"EVENT STACKED fixtures compile: "+str(compiled.errors))
 if not compiled.ok: return
 Catalog.commit(g,compiled.tables)
 var single=Game.new(42);Events.arrive(single,"stacked_fixture_0")
 var option=single.state.room_event.options.filter(func(row):return row.id=="stacked")
 t.check(option.size()==1 and single.command_facts()[0].valid==false and single.command_facts()[0].get("reason","")=="你还没有拿到那件扣环。","EVENT STACKED optional condition keeps the option visible but disabled")
 t.check(single.command_facts()[0].get("reason_surface","")=="secondary","EVENT STACKED disabled option keeps the secondary reason surface")
 var single_result=single.Events.evaluate_option(single,single.Events.request_for(single,option[0],"candidate"))
 t.check(single_result.decision=="disabled" and single_result.gates.size()==1 and single_result.gates[0].mode=="optional" and single_result.reason=="你还没有拿到那件扣环。","EVENT STACKED one optional hit reports one gate with its authored reason")
 var hidden=Game.new(42);Events.arrive(hidden,"stacked_fixture_1")
 t.check(not hidden.state.room_event.options.any(func(row):return row.id=="stacked"),"EVENT STACKED hidden condition keeps the option out of the frozen options")
 t.check(not hidden.command_facts().any(func(c):return c.payload.get("choice","")=="stacked"),"EVENT STACKED hidden condition keeps the option out of the facts")
 var both=Game.new(42)
 both._install_special("negative_plate_lock_medium","special_2_a")
 Events.arrive(both,"stacked_fixture_2")
 t.check(not both.state.room_event.options.any(func(row):return row.id=="stacked"),"EVENT STACKED a hidden hit hides the option even when another mode is declared")
 t.check(not both.command_facts().any(func(c):return c.payload.get("choice","")=="stacked"),"EVENT STACKED a hidden hit keeps the option out of the facts")
 var mixed=Game.new(43);Events.arrive(mixed,"stacked_fixture_2")
 var mixed_option=mixed.state.room_event.options.filter(func(row):return row.id=="stacked")
 t.check(mixed_option.size()==1 and not mixed.command_facts()[0].valid,"EVENT STACKED an unhit hidden entry leaves the option disabled by the optional entry")
 var mixed_result=mixed.Events.evaluate_option(mixed,mixed.Events.request_for(mixed,mixed_option[0],"candidate"))
 t.check(mixed_result.decision=="disabled" and mixed_result.gates.size()==1 and mixed_result.gates[0].mode=="optional","EVENT STACKED only the hitting optional entry reaches the gate list")
 mixed.state.relics.append("softened_buckle")
 mixed.Events.enter_node(mixed,"choice")
 t.check(mixed.state.room_event.options.any(func(row):return row.id=="stacked") and mixed.command_facts()[0].valid,"EVENT STACKED clearing every hit restores the option")
 var many=Game.new(42);Events.arrive(many,"stacked_fixture_3")
 var result=many.Events.evaluate_option(many,many.Events.request_for(many,many.state.room_event.options[0],"candidate"))
 t.check(result.decision=="disabled" and result.gates.size()==2 and result.gates[0].reason=="条件甲。" and result.gates[1].reason=="条件乙。" and result.reason=="条件甲。\n条件乙。","EVENT STACKED every optional hit is listed in declaration order and joined with newlines")
 t.check(result.gates[0].index==0 and result.gates[1].index==1 and result.gates[0].mode=="optional","EVENT STACKED gate entries keep index and mode")
 many.state.relics.append("small_gem")
 result=many.Events.evaluate_option(many,many.Events.request_for(many,many.state.room_event.options[0],"candidate"))
 t.check(result.decision=="disabled" and result.gates.size()==1 and result.gates[0].reason=="条件甲。","EVENT STACKED a passing entry stays out of the gate list")
 Catalog.commit(g,baseline)

# docs/spec/event-pipeline.md「证据入口」: the option hidden by a held relic is
# traced with its own source choice and gate, and the candidate set stays as the baseline.
static func event_hidden_relic_option_traced(t) -> void:
 var g=Game.new(42)
 g.state.relics.append("softened_buckle")
 g.set_meta("event_trace_enabled",true)
 Events.arrive(g,"floating_belt_cluster")
 var rows=g.Events.event_trace(g)
 t.check(rows.any(func(row):return row.source_choice=="fight" and str(row.gate)!="" and row.decision in ["dropped","hidden"]),"EVENT TRACE the hidden fight option is traced with a named gate")
 var choices=g.command_facts().filter(func(c):return c.payload.get("kind","")=="event" and c.payload.get("action","")=="choose")
 t.check(choices.map(func(c):return c.payload.choice)==["infusion","leave"],"EVENT TRACE the held-relic candidate set matches the baseline")
 g.set_meta("event_trace_enabled",false)
 var silent=Game.new(42)
 silent.state.relics.append("softened_buckle")
 Events.arrive(silent,"floating_belt_cluster")
 t.check(JSON.stringify(silent.state.room_event.options)==JSON.stringify(g.state.room_event.options) and JSON.stringify(silent.command_facts())==JSON.stringify(g.command_facts()),"EVENT TRACE the candidate set is identical with the switch off")

# docs/spec/event-pipeline.md「trace（debug 开关）」: stacked hits follow declaration
# order; switching trace off clears rows, and entering an event clears previous rows.
static func event_stacked_condition_trace_and_release(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var node={"id":"choice","allow_refuse":false,"unavailable":"disable","relic_gate":"pool","random_freeze":"generators","outcome_draw":"option","frozen_form":"in_place","empty_node":"allow","choices":[{"id":"stacked","label":"叠加条件","reward":"none","next":"result","detail":"条件决定是否可选。","effects":[{"op":"mana_gain","amount":2}],"conditions":[{"kind":"has_relic","type":"softened_buckle","reason":"条件甲。","mode":"optional"},{"kind":"has_relic","type":"small_gem","reason":"条件乙。","mode":"optional"}]}]}
 var document={"file":"memory://trace_stacked.json","data":{"schema_version":2,"kind":"event","id":"trace_stacked_fixture","name":"trace 叠加夹具","intro":"只用于验证 trace 的夹具。","start_node":"choice","nodes":[node]}}
 var compiled=Catalog.compile(g,[document])
 t.check(compiled.ok,"EVENT TRACE stacked fixture compiles: "+str(compiled.errors))
 if not compiled.ok: return
 Catalog.commit(g,compiled.tables)
 var walk=Game.new(42)
 walk.set_meta("event_trace_enabled",true)
 Events.arrive(walk,"trace_stacked_fixture")
 var arrival=walk.Events.event_trace(walk)
 t.check(arrival.size()==2 and arrival[0].index==0 and arrival[1].index==1,"EVENT TRACE one row per hitting entry, in declaration order: "+JSON.stringify(arrival.map(func(row):return [row.index,row.mode])))
 t.check(arrival[0].reason=="条件甲。" and arrival[1].reason=="条件乙。" and arrival[0].mode=="optional","EVENT TRACE every row keeps its own reason and mode")
 t.check(arrival.all(func(row):return row.gate=="availability_unmet" and row.decision=="disabled" and row.purpose=="arrival"),"EVENT TRACE stacked rows keep the named gate and decision")
 Events.arrive(walk,"trace_stacked_fixture")
 var second=walk.Events.event_trace(walk)
 t.check(second.size()==2 and second[0].index==0 and second[0].purpose=="arrival","EVENT TRACE a new event keeps no stale rows: "+str(second.size()))
 walk.set_meta("event_trace_enabled",false)
 var silent=Game.new(42)
 Events.arrive(silent,"trace_stacked_fixture")
 silent.command_facts()
 t.check(silent.Events.event_trace(silent).is_empty(),"EVENT TRACE release leaves the trace empty")
 t.check(not JSON.stringify(silent.export_snapshot()).contains("event_trace") and not JSON.stringify(silent.get_view()).contains("event_trace"),"EVENT TRACE neither the save nor the view carries trace data")
 Catalog.commit(g,baseline)

static func run(t) -> void:
 event_stacked_condition_trace_and_release(t)
 event_hidden_relic_option_traced(t)
 event_single_node_declarations(t)
 event_node_empty_policy_kept(t)
 event_chain_jumps_to_another_event_node(t)
 event_chain_loop_refused(t)
 event_chain_trace_rows(t)
 event_chain_relic_drawn_from_target(t)
 event_chain_relic_cleared_without_target_offer(t)
 event_chain_relic_cleared_when_pool_empty(t)
 event_stacked_conditions(t)
 event_mana_cost(t)
 event_option_policies_match_current_behaviour(t)
 link_installation(t)
 plate_lock_copy(t)
 empty_studio(t)
 smuggled_potions(t)
 floating_belts(t)
 battle_preparation(t)
 alchemist_tasting(t)
 abandoned_storeroom(t)
 bound_dream_guest_room(t)
 mysterious_woman_statue(t)
 maze_survey_team(t)
 var g=Game.new(17)
 var baseline=Catalog.tables(g)
 application_cases(t,g,baseline)
 var template_file=FileAccess.open("res://content/templates/event_multistage.json.disabled",FileAccess.READ)
 var template_data=JSON.parse_string(template_file.get_as_text()) if template_file!=null else null
 var template_compile=Catalog.compile(g,[{"file":"res://content/templates/event_multistage.json.disabled","data":template_data}]) if template_data is Dictionary else {"ok":false,"errors":["模板无法读取"]}
 t.check(template_compile.ok,"EVENT FLOW shipped disabled template parses and compiles when enabled: "+str(template_compile.errors))
 var compiled=Catalog.compile(g,[document()])
 t.check(compiled.ok,"EVENT FLOW generic staged document compiles: "+str(compiled.errors))
 if not compiled.ok: return
 var concise=document();concise.data.nodes[1].choices[0].detail=""
 var concise_result=Catalog.compile(g,[concise])
 t.check(concise_result.ok and concise_result.tables.event.flow_test.nodes[1].choices[0].detail=="","EVENT FLOW deterministic stages support explicit empty notes")
 concise.data.nodes[0].choices[0].detail=""
 t.check(not Catalog.compile(g,[concise]).ok,"EVENT FLOW random outcomes still require an authored public preview")
 Catalog.commit(g,compiled.tables)

 g=flow(t)
 var item=g._install_special("shaft_ring_low","special_2_a")
 Events.arrive(g,"flow_test")
 var before=g.export_snapshot();var view=g.get_view();g.command_facts();g.route_view()
 t.check(g.state==before,"EVENT FLOW preview and projection do not mutate or reroll")
 t.check(not JSON.stringify(view).contains("结果一") and not JSON.stringify(view).contains("结果二"),"EVENT FLOW frozen hidden outcome is not projected")

 var left=flow(t,19)
 t.check(t.action(left,"event",{"action":"choose","choice":"refuse"}).ok and left.state.room_event.stage=="result","EVENT FLOW initial refusal can bypass optional held equipment")
 t.check(t.action(left,"event",{"action":"leave"}).ok and left.state.phase=="map","EVENT FLOW idempotent cleanup lets an early-exit branch leave")

 t.check(t.action(g,"event",{"action":"choose","choice":"accept"}).ok,"EVENT FLOW first stage commits through normal candidate")
 t.check(g.state.room_event.stage=="penalty" and g.state.special_equipment.is_empty(),"EVENT FLOW advances and temporarily removes selected equipment")
 t.check(g.state.room_event.held.selected_gear.size()==1 and g.state.room_event.held.selected_gear[0]==item,"EVENT FLOW held equipment preserves exact instance")
 t.check(g.state.deck.any(func(card):return card.type in ["panic","sensitive"]),"EVENT FLOW weighted result uses ordinary card effect")
 var saved=g.export_snapshot();var resumed=Game.new(17);var restored=resumed.restore_snapshot(saved)
 var resumed_copy=resumed.state.duplicate(true);resumed_copy.erase("version");var saved_copy=saved.duplicate(true);saved_copy.erase("version")
 t.check(restored.ok and resumed_copy==saved_copy,"EVENT FLOW held equipment and frozen options survive save/load: "+restored.get("error",""))
 g=resumed
 var rope_choice=t.find_action(g,"event",{"action":"choose","choice":"two_ropes"})
 t.check(rope_choice.valid and rope_choice.detail.contains("绳索"),"EVENT FLOW random installation is frozen into a public concrete preview")
 var version=g.state.version;var restored_before=g.export_snapshot()
 t.check(not g.dispatch(g.command(rope_choice.payload,version-1),version-1).ok and g.state==restored_before,"EVENT FLOW staged choice rejects stale version atomically")
 var entered_finale=g.dispatch(g.command(rope_choice.payload,version),version)
 t.check(entered_finale.ok and g.state.room_event.stage=="finale","EVENT FLOW generated effects commit and advance")
 t.check(entered_finale.get("resource_feedback",[]).is_empty() and g.state.mana==restored_before.mana,"EVENT FLOW freezing an unchosen future cost emits no payment or refund receipt")
 t.check(g.state.equipment.size()==2 and g.state.equipment.all(func(e):return e.template=="rope" and g.tier(e.durability,e.maximum)==2),"EVENT FLOW batch random install reuses ordinary equipment factory")
 var finished=t.action(g,"event",{"action":"choose","choice":"finish"})
 t.check(finished.ok and g.state.room_event.stage=="result","EVENT FLOW final stage uses normal pressure effect")
 var payments=finished.get("resource_feedback",[]).filter(func(event):return event.field=="mana")
 t.check(payments.size()==1 and payments[0].before==100 and payments[0].after==80 and g._resource_feedback==null,"EVENT FLOW chosen cost emits exactly one real payment and releases receipt ownership")
 t.check(g.state.mana==80 and g.state.pressure==0,"EVENT FLOW pressure reaches the ordinary climax threshold once")
 t.check(t.action(g,"event",{"action":"leave"}).ok,"EVENT FLOW cleanup and leave are one formal command")
 t.check(g.state.special_equipment.size()==1 and g.state.special_equipment[0]==item,"EVENT FLOW cleanup restores the exact held instance")

 g=flow(t,23)
 g.add_fixture("wrist",4);g.add_fixture("ankle",4)
 Events.arrive(g,"flow_test");t.action(g,"event",{"action":"choose","choice":"accept"})
 t.check(t.action(g,"event",{"action":"choose","choice":"tighten_two"}).ok,"EVENT FLOW batch tighten option is executable")
 t.check(g.state.equipment.size()==2 and g.state.equipment.all(func(e):return g.tier(e.durability,e.maximum)==3),"EVENT FLOW batch tighten freezes distinct eligible targets")

 var bad=document();bad.data.id="flow_cycle";bad.data.nodes[1].choices[0].next="entry"
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW backward stage references fail closed")
 bad=document();bad.data.id="flow_missing_cleanup";bad.data.cleanup_effects=[]
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW held equipment requires declared cleanup")
 bad=document();bad.data.id="flow_no_exit";bad.data.nodes[0].allow_refuse=false
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW initial stage requires a safe refusal")
 bad=document();bad.data.id="flow_script";bad.data.nodes[0].choices[0].effects=[{"op":"run_three_round_gamble"}]
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW event-specific operation names are rejected")
 bad=document();bad.data.id="flow_bad_effects";bad.data.nodes[0].choices[0].effects="not-an-array"
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW malformed nested effects fail closed without a runtime error")
 bad=document();bad.data.id="flow_bad_result";bad.data.nodes[0].choices[0].outcomes[0].result_status="maybe"
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW unknown authored result status is rejected")
 bad=document();bad.data.id="flow_bad_choice_result";bad.data.nodes[0].choices[0].result_status=123
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW non-string result status is rejected")
 bad=document();bad.data.id="flow_bad_pressure_copy";bad.data.nodes[2].choices[0].show_pressure_sources=true;bad.data.nodes[2].choices[0].effects[0].erase("source")
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW visible pressure-source copy requires an authored source")
 bad=document();bad.data.id="flow_bad_copy_family";bad.data.nodes[2].choices[0].report_variants=[{"when":{"kind":"equipped_special_family","value":"missing_family"},"text":"条件正文"}]
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW conditional copy rejects an unknown special-equipment family")
 bad=document();bad.data.id="flow_bad_source_variant";bad.data.nodes[2].choices[0].effects[0].source_variants=[{"when":{"kind":"equipped_special_family","value":"chastity_lock"},"text":"x".repeat(121)}]
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW conditional pressure copy preserves the source length boundary")
 bad=document();bad.data.id="flow_bad_when_sources";bad.data.nodes[1].choices[0].when={"counter":"wins","selector":{"kind":"restraint"},"equals":0}
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW condition cannot mix counter and selector sources")
 bad=document();bad.data.id="flow_bad_when_selector";bad.data.nodes[1].choices[0].when={"selector":{"kind":"enemy"},"equals":0}
 t.check(not Catalog.compile(g,[bad]).ok,"EVENT FLOW selector-count condition rejects unsupported sources")

 # Shipped three-round event and its practice entry use the same authored flow.
 g=Game.new(42,true,"succubus_three_games")
 t.check(g.state.phase=="event" and g.state.room_event.id=="succubus_three_games" and g.state.room_event.stage=="wager_card","GAMBLE practice opens shipped event through formal start")
 t.check(g.state.equipment.size()==2 and g.state.equipment.any(func(e):return e.locked),"GAMBLE practice keeps declared real restraint setup")
 var card_options=g.command_facts().filter(func(c):return c.payload.get("choice","").begins_with("wager_card__"))
 t.check(card_options.size()==10 and card_options.all(func(c):return c.valid),"GAMBLE first round generates one legal wager per non-curse permanent card")
 t.check(g.get_view().room_event.result_status=="neutral" and card_options.all(func(c):return not c.payload.has("result_status")),"EVENT RESULT future frozen win/loss is not exposed by view or facts")
 var frozen_status=g.state.room_event.options.filter(func(option):return option.id==card_options[0].payload.choice)[0].result_status
 var pending_result_save=g.export_snapshot();var result_resume=Game.new(42)
 t.check(result_resume.restore_snapshot(pending_result_save).ok and result_resume.state.room_event.options[0].result_status==g.state.room_event.options[0].result_status,"EVENT RESULT frozen marker survives a pending-selection save")
 var selection_before=g.state.duplicate(true)
 var selection_view=g.get_view().room_event.selections
 t.check(selection_view.size()==1 and selection_view[0].kind=="card" and selection_view[0].options.size()==10,"EVENT VIEW one authored selector projects ten physical choices")
 t.check(selection_view[0].options.all(func(option):return g.state.deck.any(func(card):return card.uid==option.selected.id and card.type==option.selected.type)),"EVENT VIEW card selector retains exact permanent uid and type")
 t.check(selection_view[0].options.all(func(option):return option.keys().size()==2 and not option.has("effects") and not option.has("report")) and g.state==selection_before,"EVENT VIEW selector reveals no frozen result and does not mutate state or random domains")
 var wager_uid=card_options[0].payload.choice.get_slice("__",1)
 var wager_before=g.state.deck.filter(func(card):return card.uid==wager_uid)[0].type
 t.check(g.dispatch(g.command(card_options[0].payload,g.state.version),g.state.version).ok and g.state.room_event.stage=="after_round_one","GAMBLE card wager commits frozen round outcome")
 t.check(g.get_view().room_event.result_status==frozen_status and frozen_status in ["success","failure"],"EVENT RESULT committed page displays its explicit outcome")
 t.check(result_resume.restore_snapshot(g.export_snapshot()).ok and result_resume.get_view().room_event.result_status==frozen_status,"EVENT RESULT committed result survives restore without reroll")
 var damaged_result=g.export_snapshot();damaged_result.room_event.result_status="maybe"
 var intact_result=result_resume.state.duplicate(true)
 t.check(not result_resume.restore_snapshot(damaged_result).ok and result_resume.state==intact_result,"EVENT RESULT corrupt committed status rejects atomically")
 damaged_result=pending_result_save.duplicate(true);damaged_result.room_event.options[0].result_status=[]
 t.check(not result_resume.restore_snapshot(damaged_result).ok and result_resume.state==intact_result,"EVENT RESULT corrupt frozen status rejects atomically")
 var wager_after=g.state.deck.filter(func(card):return card.uid==wager_uid)[0].type
 t.check((wager_after==wager_before and g.state.room_event.values.get("heart_chips",0)==1) or wager_after=="panic","GAMBLE round one either preserves the card and awards a chip or transforms that exact card")
 var prior_report=g.state.room_event.report
 var prior_logs=g.state.logs.duplicate(true)
 var prior_page=g.get_view().room_event.page_id
 t.check(t.action(g,"event",{"action":"choose","choice":"continue"}).ok and g.state.room_event.stage=="wager_restraint","GAMBLE player can continue from first-round cashout stage")
 t.check(g.get_view().room_event.result_status=="neutral","EVENT RESULT ordinary continuation clears previous win/loss")
 t.check(not g.state.room_event.report.contains(prior_report) and g.state.logs.slice(0,prior_logs.size())==prior_logs and g.get_view().room_event.page_id!=prior_page,"EVENT FLOW each forward page has only its own result while historical logs remain intact")
 var restraint_options=g.command_facts().filter(func(c):return c.payload.get("choice","").begins_with("wager_restraint__"))
 t.check(restraint_options.size()>=2 and restraint_options.all(func(c):return c.valid),"GAMBLE second round generates wagers from actual worn restraints")
 var equipment_view=g.get_view().room_event.selections[0]
 t.check(equipment_view.kind=="restraint" and equipment_view.options.all(func(option):return option.selected.durability==g._equipment(option.selected.id).durability and option.selected.locked==g._equipment(option.selected.id).locked),"EVENT VIEW equipment modal receives actual durability and lock facts")
 t.check(g.dispatch(g.command(restraint_options[0].payload,g.state.version),g.state.version).ok,"GAMBLE selected restraint resolves through frozen even odds")
 if g.state.room_event.stage=="restraint_penalty":
  t.check(t.action(g,"event",{"action":"choose","choice":"locked_belt"}).ok,"GAMBLE failed second round executes selected formal penalty")
 t.check(g.state.room_event.stage=="after_round_two","GAMBLE second round reaches its cashout stage")
 var held_item=g._install_special("shaft_ring_low","special_2_a").duplicate(true)
 t.check(t.action(g,"event",{"action":"choose","choice":"continue"}).ok and g.state.room_event.stage=="wager_semen","GAMBLE player can enter third round with existing penis equipment")
 t.check(g.get_view().room_event.intro.contains("一件件解开") and not g.get_view().room_event.intro.contains("实际装备状态") and g.state.room_event.options.all(func(option):return not option.effects.any(func(effect):return effect.op in ["hold_special","restore_held"])),"GAMBLE third-round removal is authored prose and declares no equipment mutation")
 var semen_option=g.state.room_event.options.filter(func(option):return option.source_choice=="begin")[0]
 var semen_sources=semen_option.effects.filter(func(effect):return effect.op=="pressure").map(func(effect):return effect.source)
 var semen_outcome_report=semen_option.report
 var climax_before=g.state.overload_total;var mana_before=g.state.mana
 t.check(t.action(g,"event",{"action":"choose","choice":"begin"}).ok and g.state.room_event.stage=="payout","GAMBLE third round resolves through ordinary pressure and authored outcome")
 var climaxes=g.state.overload_total-climax_before
 t.check(climaxes in [1,2] and is_equal_approx(g.state.mana,maxf(0,mana_before-climaxes*g.B.OVERLOAD_MANA)),"GAMBLE third round causes exactly one or two ordinary climaxes with matching mana loss")
 t.check(semen_sources.size()==climaxes and semen_sources.all(func(source):return g.state.room_event.report.contains(source)) and g.state.room_event.report.find(semen_sources[0])<g.state.room_event.report.find(semen_outcome_report),"GAMBLE payout result shows every committed ejaculation scene before its card outcome copy")
 t.check(g.state.room_event.held.is_empty() and g.state.special_equipment.any(func(item):return item==held_item),"GAMBLE narrative-only removal leaves the exact penis equipment installed throughout the closed scene")
 t.check(g.get_view().room_event.intro.contains("一件件重新戴回原处"),"GAMBLE payout narrates restoring the original toys without a restore effect")
 var payout=g.command_facts().filter(func(candidate):return candidate.payload.get("kind","")=="event")[0]
 t.check(g.dispatch(g.command(payout.payload,g.state.version),g.state.version).ok,"GAMBLE payout follows the actual accumulated chip count")
 if g.state.room_event.stage=="reward": t.check(t.action(g,"event",{"action":"reward","type":"skip"}).ok,"GAMBLE card payout may be skipped through existing reward UI")
 elif g.state.room_event.stage=="remove_reward": t.check(g.dispatch(g.command(g.command_facts()[0].payload,g.state.version),g.state.version).ok,"GAMBLE three-chip payout removes one selected card")
 t.check(g.state.room_event.stage=="result" and t.action(g,"event",{"action":"leave"}).ok,"GAMBLE resolves and leaves through one formal command")
 t.check(g.state.phase=="cleared" and g.state.special_equipment.any(func(item):return item==held_item),"GAMBLE practice completion preserves the exact narrative-only penis equipment instance")

 var saw_loss=false
 for seed in range(40):
  var loss=Game.new(seed,true,"succubus_three_games")
  var option=loss.command_facts().filter(func(c):return c.payload.get("choice","").begins_with("wager_card__"))[0]
  if not option.detail.contains("慌乱"): continue
  # The public detail deliberately shows both outcomes; inspect frozen effects only in this mechanics test.
  var frozen=loss.state.room_event.options.filter(func(o):return o.id==option.payload.choice)[0]
  if not frozen.effects.any(func(e):return e.op=="transform_card"): continue
  var uid=frozen.selected.id
  t.check(loss.dispatch(loss.command(option.payload,loss.state.version),loss.state.version).ok and loss.state.deck.filter(func(card):return card.uid==uid)[0].type=="panic","GAMBLE losing first round transforms the selected permanent card into panic")
  t.check(loss.get_view().room_event.result_status=="failure","EVENT RESULT losing draw explicitly projects failure")
  saw_loss=true;break
 t.check(saw_loss,"GAMBLE deterministic seed set includes first-round loss")

 # Stage fixture uses the authored payout and its normal selector/transaction.
 var removal=Game.new(27,true,"succubus_three_games")
 t.check(removal.Events.enter_node(removal,"remove_reward")=="","EVENT removal fixture opens the authored card payout")
 var selected_uid=removal.state.deck[0].uid
 var removal_choice=t.find_action(removal,"event",{"action":"choose","choice":"remove__"+selected_uid})
 var before_removal=removal.export_snapshot()
 t.check(removal_choice.get("valid",false) and removal.dispatch(removal.command(removal_choice.payload,removal.state.version),removal.state.version).ok,"EVENT removal uses the selected physical card candidate")
 t.check(["deck","draw","hand","discard","exhaust"].all(func(zone):return removal.state[zone]==before_removal[zone].filter(func(card):return card.uid!=selected_uid)),"EVENT removes only selected uid, preserving equal-type cards and pile order")
 t.check(removal.state.mana==before_removal.mana and removal.state.energy==before_removal.energy and removal.state.rng==before_removal.rng and removal.state.items.size()==before_removal.items.size()+1,"EVENT removal pays and grants exactly its declared payout without reroll")
 var completed=removal.export_snapshot()
 t.check(not removal.dispatch(removal.command(removal_choice.payload,removal.state.version),removal.state.version).ok and removal.export_snapshot()==completed,"EVENT paid removal cannot be applied a second time")

 # With no worn restraints the second round must use its authored add-restraint
 # fallback instead of leaving the previous Continue candidate invalid.
 var saw_empty_win=false;var saw_empty_loss=false
 for seed in range(40):
  var empty=Game.new(seed,true,"succubus_three_games")
  empty.state.equipment.clear();empty.state.composites.clear();empty.state.links.clear()
  var first=empty.command_facts().filter(func(c):return c.payload.get("choice","").begins_with("wager_card__"))[0]
  t.check(empty.dispatch(empty.command(first.payload,empty.state.version),empty.state.version).ok,"GAMBLE empty-loadout fixture resolves first wager")
  var advance=t.find_action(empty,"event",{"action":"choose","choice":"continue"})
  t.check(advance.valid and empty.dispatch(empty.command(advance.payload,empty.state.version),empty.state.version).ok,"GAMBLE no-restraint loadout can still enter round two")
  var fallback=t.find_action(empty,"event",{"action":"choose","choice":"wager_without_restraint"})
  t.check(fallback.valid and empty.state.room_event.options.size()==1 and not empty.state.room_event.options[0].has("selected"),"GAMBLE round two substitutes exactly one non-selector fallback")
  var frozen=empty.state.room_event.options[0]
  var frozen_before=empty.state.duplicate(true);empty.get_view();empty.command_facts()
  t.check(empty.state==frozen_before and fallback.detail.contains("添加拘束具"),"GAMBLE fallback preview is readonly and discloses add-restraint loss")
  t.check(empty.dispatch(empty.command(fallback.payload,empty.state.version),empty.state.version).ok,"GAMBLE no-restraint wager uses the normal event transaction")
  if frozen.result_status=="success":
   saw_empty_win=true
   t.check(empty.state.room_event.stage=="after_round_two" and empty.state.room_event.values.heart_chips>=1,"GAMBLE empty-loadout win grants a chip and advances")
  else:
   saw_empty_loss=true
   t.check(empty.state.room_event.stage=="restraint_penalty" and empty.command_facts().size()>=2,"GAMBLE empty-loadout loss opens add-restraint penalties")
  if saw_empty_win and saw_empty_loss: break
 t.check(saw_empty_win and saw_empty_loss,"GAMBLE deterministic seeds cover empty-loadout win and loss")

 # The pawnshop is a mandatory one-choice event. Its premium branch is a
 # two-item atomic offer, never two independent partial installations.
 var shop=Game.new(62,true,"succubus_magic_pawnshop")
 var shop_choices=shop.command_facts().filter(func(c):return c.payload.get("action","")=="choose")
 t.check(shop_choices.map(func(c):return c.payload.choice)==["small_trade","large_trade","extra_spice"] and shop_choices.all(func(c):return c.valid),"PAWNSHOP free loadout exposes exactly three mandatory trades without refusal")
 var old_ring=shop._install_special("shaft_ring_low","special_2_a").duplicate(true)
 var shop_climax_before=shop.state.overload_total
 t.check(t.action(shop,"event",{"action":"choose","choice":"extra_spice"}).ok and shop.state.room_event.stage=="reward","PAWNSHOP extra trade commits through the normal event transaction")
 t.check(shop.state.overload_total-shop_climax_before==2 and shop.state.special_equipment.any(func(item):return item==old_ring),"PAWNSHOP extra trade causes two climaxes and keeps narrative-only existing equipment unchanged")
 t.check(shop.state.special_equipment.any(func(item):return item.type=="nipple_clamp_medium") and shop.state.special_equipment.any(func(item):return item.type=="anal_egg_medium"),"PAWNSHOP extra trade installs both fixed toys")
 t.check(shop.state.room_event.report.contains("中级无线乳夹跳蛋") and shop.state.room_event.report.contains("中级无线后庭跳蛋") and not shop.state.room_event.report.contains("牵引线"),"PAWNSHOP result uses both exact reusable wear texts")

 var blocked=Game.new(63)
 blocked._install_special("anal_egg_low","special_3_b")
 Events.arrive(blocked,"succubus_magic_pawnshop")
 var blocked_choices=blocked.command_facts().filter(func(c):return c.payload.get("action","")=="choose")
 t.check(blocked_choices.map(func(c):return c.payload.choice)==["small_trade","large_trade"] and blocked_choices.all(func(c):return c.valid),"PAWNSHOP one unavailable fixed toy hides the entire extra trade while preserving both normal trades")
 shop_climax_before=blocked.state.overload_total
 t.check(t.action(blocked,"event",{"action":"choose","choice":"large_trade"}).ok and blocked.state.overload_total-shop_climax_before==2 and blocked.state.room_event.stage=="reward","PAWNSHOP large trade remains usable and causes exactly two climaxes")

 for row in [{"id":"small_trade","climaxes":1,"copy":"才揉几下奶子、摸摸小穴就流出来了"},{"id":"large_trade","climaxes":2,"copy":"姐姐还差一瓶呢"},{"id":"extra_spice","climaxes":2,"copy":"你答应的是两次，可不能少哦"}]:
  var locked_shop=Game.new(640+row.climaxes)
  t.check(not locked_shop._install_special("negative_plate_lock_medium","special_2_a").is_empty(),"PAWNSHOP COPY fixture equips a real flat lock for "+row.id)
  Events.arrive(locked_shop,"succubus_magic_pawnshop")
  var locked_option=locked_shop.state.room_event.options.filter(func(option):return option.id==row.id)[0]
  var locked_sources=locked_option.effects.filter(func(effect):return effect.op=="pressure").map(func(effect):return effect.source)
  t.check(locked_sources.size()==row.climaxes and locked_sources.all(func(source):return source.contains("平板锁") and not source.contains("用手榨取") and not source.contains("乳沟榨取")),"PAWNSHOP COPY freezes every climax source to the flat-lock method for "+row.id)
  var locked_before=locked_shop.state.overload_total
  t.check(t.action(locked_shop,"event",{"action":"choose","choice":row.id}).ok and locked_shop.state.overload_total-locked_before==row.climaxes,"PAWNSHOP COPY preserves the authored climax count for "+row.id)
  t.check(locked_shop.state.room_event.report.contains(row.copy) and locked_shop.state.room_event.report.contains("锁板") and not locked_shop.state.room_event.report.contains("掌心裹住肉棒"),"PAWNSHOP COPY displays the approved natural flat-lock prose for "+row.id)
  if row.id=="extra_spice": t.check(locked_shop.state.room_event.report.contains("中级无线乳夹跳蛋") and locked_shop.state.room_event.report.contains("中级无线后庭跳蛋"),"PAWNSHOP COPY premium result still names and equips both fixed toys")

 # The cleric event uses only generic resource, random single-install and card
 # selection effects. Its own free exit replaces the default paid refusal.
 var cleric=Game.new(71,true,"binding_cleric")
 cleric.state.mana=45
 Events.arrive(cleric,"binding_cleric")
 var cleric_choices=cleric.command_facts().filter(func(c):return c.payload.get("action","")=="choose")
 t.check(cleric_choices.map(func(c):return c.payload.choice)==["restore","purify","leave_free"] and cleric_choices.all(func(c):return c.valid),"CLERIC exposes exactly two services and one free exit")
 var restore=cleric.state.room_event.options.filter(func(option):return option.id=="restore")[0]
 var installs=restore.effects.filter(func(effect):return effect.op=="install")
 t.check(installs.size()==2 and restore.effects.any(func(effect):return effect.op=="mana_gain" and effect.amount==20) and installs.all(func(effect):return effect.grade==1 and effect.tier==2 and not effect.locked),"CLERIC freezes two initial tier-two single restraints and twenty mana")
 t.check(not restore.effects.any(func(effect):return effect.op=="link"),"CLERIC explicit ordinary-only range excludes generated links")
 var cleric_restore_before=cleric.export_snapshot()
 t.check(t.action(cleric,"event",{"action":"choose","choice":"restore"}).ok and cleric.state.mana==65 and cleric.state.equipment.size()==2,"CLERIC restoration and both installations commit atomically")
 t.check(installs.all(func(effect):return cleric.state.room_event.report.contains(cleric.Equipment.wear_text(cleric.Equipment.name_for(effect.template,effect.slot,effect.grade,effect.get("variant",0)),effect.slot))),"CLERIC result uses reusable body-specific wear prose with exact names")
 t.check(cleric.state.rng.event==cleric_restore_before.rng.event and cleric.state.room_event.stage=="result","CLERIC committed frozen outcome does not reroll")

 cleric=Game.new(72,true,"binding_cleric")
 Events.arrive(cleric,"binding_cleric")
 var cleric_deck_before=cleric.state.deck.size();var cleric_climax_before=cleric.state.overload_total;var cleric_mana_before=cleric.state.mana
 t.check(t.action(cleric,"event",{"action":"choose","choice":"purify"}).ok and cleric.state.room_event.stage=="remove_card","CLERIC purification causes the declared scene before opening card removal")
 t.check(cleric.state.overload_total-cleric_climax_before==1 and cleric.state.mana==cleric_mana_before-cleric.B.OVERLOAD_MANA,"CLERIC purification uses one ordinary climax and matching mana loss")
 var cleric_uid=cleric.state.deck[0].uid
 t.check(t.action(cleric,"event",{"action":"choose","choice":"remove__"+cleric_uid}).ok and cleric.state.deck.size()==cleric_deck_before-1 and cleric.state.deck.all(func(card):return card.uid!=cleric_uid),"CLERIC removes the selected physical card through the shared selector")

 cleric=Game.new(73,true,"binding_cleric")
 Events.arrive(cleric,"binding_cleric")
 var free_before=cleric.export_snapshot()
 t.check(t.action(cleric,"event",{"action":"choose","choice":"leave_free"}).ok and cleric.state.room_event.stage=="result","CLERIC authored free exit resolves without a paid refusal")
 t.check(cleric.state.mana==free_before.mana and cleric.state.equipment==free_before.equipment and cleric.state.deck==free_before.deck and cleric.state.overload_total==free_before.overload_total,"CLERIC free exit changes no resource, equipment, card or climax state")

 # The bound-adventurer event is a declared nine-step probability ladder. Every
 # actual reach freezes exactly one new ordinary single restraint before success
 # or failure; the captive's equipment is not represented as a transferable pool.
 var trapped=Game.new(81,true,"bound_adventurer_relic")
 var trapped_definition=trapped.Events.Data.TYPES.bound_adventurer_relic
 t.check(trapped_definition.nodes.size()==9 and trapped_definition.start_node=="attempt_1","BOUND ADVENTURER declares the complete nine-attempt ladder")
 var expected_chances=[25,35,45,55,65,75,85,95]
 for index in range(9):
  var stage=trapped_definition.nodes[index]
  var stage_reach=stage.choices.filter(func(choice):return choice.id=="reach")[0]
  var leave=stage.choices.filter(func(choice):return choice.id=="leave")[0]
  var generators=stage_reach.effects.filter(func(effect):return effect.op=="install_random")
  t.check(generators.size()==1 and generators[0].count==1 and generators[0].grade==1 and generators[0].tier==2 and not generators[0].locked and not generators[0].allow_links,"BOUND ADVENTURER every reach adds one initial tier-two ordinary single without links")
  t.check(leave.effects.is_empty() and leave.next=="result","BOUND ADVENTURER every stage retains an authored free exit")
  if index<8:
   var win=stage_reach.outcomes.filter(func(outcome):return outcome.reward=="relic")[0]
   var loss=stage_reach.outcomes.filter(func(outcome):return outcome.reward=="none")[0]
   t.check(win.weight==expected_chances[index] and loss.weight==100-expected_chances[index] and loss.next=="attempt_%d" % (index+2),"BOUND ADVENTURER failure raises the next published chance by ten points")
  else:
   t.check(stage_reach.reward=="relic" and not stage_reach.has("outcomes"),"BOUND ADVENTURER ninth reach is guaranteed instead of rolling above one hundred percent")

 var failed=null
 for seed_value in range(40):
  var fail_sample=Game.new(seed_value,true,"bound_adventurer_relic")
  Events.arrive(fail_sample,"bound_adventurer_relic")
  var fail_reach=fail_sample.state.room_event.options.filter(func(option):return option.id=="reach")[0]
  if fail_reach.next=="attempt_2": failed=fail_sample;break
 t.check(failed!=null,"BOUND ADVENTURER daily seeds include a first-attempt failure")
 if failed!=null:
  var failed_before=failed.state.equipment.size()
  var frozen_install=failed.state.room_event.options.filter(func(option):return option.id=="reach")[0].effects.filter(func(effect):return effect.op=="install")[0]
  var expected_wear=failed.Equipment.wear_text(failed.Equipment.name_for(frozen_install.template,frozen_install.slot,frozen_install.grade,frozen_install.get("variant",0)),frozen_install.slot,"animated")
  t.check(t.action(failed,"event",{"action":"choose","choice":"reach"}).ok and failed.state.room_event.stage=="attempt_2" and failed.state.equipment.size()==failed_before+1,"BOUND ADVENTURER failed reach still installs exactly one frozen restraint before continuing")
  t.check(failed.state.room_event.report.contains(expected_wear) and failed.state.room_event.report.contains("遗物仍") and not failed.state.room_event.report.contains("她把") and not failed.state.room_event.report.contains("她合拢"),"BOUND ADVENTURER failed result uses autonomous wear prose and concise scene result")
  var failed_saved=failed.export_snapshot();var failed_resumed=Game.new(9)
  t.check(failed_resumed.restore_snapshot(failed_saved).ok and failed_resumed.state.room_event.stage=="attempt_2" and failed_resumed.state.equipment==failed.state.equipment,"BOUND ADVENTURER failed attempt and its exact new restraint survive save and restore")

 var succeeded=null
 for seed_value in range(40):
  var success_sample=Game.new(seed_value,true,"bound_adventurer_relic")
  Events.arrive(success_sample,"bound_adventurer_relic")
  if success_sample.state.room_event.options.filter(func(option):return option.id=="reach")[0].reward=="relic": succeeded=success_sample;break
 t.check(succeeded!=null,"BOUND ADVENTURER daily seeds include a first-attempt success")
 if succeeded!=null:
  var equipment_before=succeeded.state.equipment.size();var relics_before=succeeded.state.relics.size()
  t.check(t.action(succeeded,"event",{"action":"choose","choice":"reach"}).ok and succeeded.state.room_event.stage=="result" and succeeded.state.equipment.size()==equipment_before+1 and succeeded.state.relics.size()==relics_before+1,"BOUND ADVENTURER success keeps the attempt restraint and grants one real relic")
  t.check(succeeded.state.room_event.report.contains("她身上的拘束具仍原封不动"),"BOUND ADVENTURER success copy never describes transferring the captive's restraints")

 trapped=Game.new(82,true,"bound_adventurer_relic")
 Events.arrive(trapped,"bound_adventurer_relic")
 var leave_before=trapped.export_snapshot()
 t.check(t.action(trapped,"event",{"action":"choose","choice":"leave"}).ok and trapped.state.room_event.stage=="result","BOUND ADVENTURER can leave from the first stage")
 t.check(trapped.state.equipment==leave_before.equipment and trapped.state.relics==leave_before.relics and trapped.state.mana==leave_before.mana,"BOUND ADVENTURER leaving before a reach changes no equipment, relic or resource")

 var full=Game.new(83)
 var fill_templates=trapped_definition.nodes[0].choices[0].effects[0].templates
 var fill_spec={"pool":"ordinary","templates":fill_templates,"count":1,"grade":1,"tier":2,"locked":false,"replace":false,"allow_links":false,"variants":{}}
 for fill_template in fill_templates: fill_spec.variants[fill_template]=0
 for _index in range(80):
  var fill_concrete=full.Application.choose(full,fill_spec,"fixture:full","event")
  if fill_concrete.is_empty(): break
  var fill_applied=full.Application.execute_concrete(full,fill_concrete,"fixture:full",false)
  if not fill_applied.ok: break
 Events.arrive(full,"bound_adventurer_relic")
 var full_choices=full.command_facts().filter(func(candidate):return candidate.payload.get("action","")=="choose")
 t.check(full_choices.size()==1 and full_choices[0].payload.choice=="leave","BOUND ADVENTURER no legal ordinary position removes the reach choice and preserves the free exit")

 Catalog.commit(g,baseline)
 t.check(Catalog.tables(g)==baseline,"EVENT FLOW tests restore all shared registries")

static func application_cases(t, g, baseline: Dictionary) -> void:
 # Author permission is opt-in and survives generator expansion. Unknown fields
 # and non-boolean permissions must not become implicit replacement authority.
 var declarations=[
  {"op":"install","template":"rope","slot":"wrist","grade":1,"tier":2,"locked":false},
  {"op":"assembly","family":"glove","variant":"short","straps":"straight","part":"body","name":"短型单手套","coverage":["upper_arm","forearm","wrist"],"part_name":"短型单手套 · 套体"},
  {"op":"special_install","type":"shaft_ring_low","slot":"special_2_a"},
  {"op":"install_random","templates":["rope"],"count":2,"grade":1,"tier":2,"locked":false},
  {"op":"special_install_random","types":["shaft_ring_low"],"fallback":[{"op":"mana_loss","amount":3}]}]
 for declaration in declarations:
  for permission in [false,true]:
   var effect=declaration.duplicate(true);effect.replace=permission
   t.check(Catalog._effect(g,effect,baseline,true)=="","EVENT APPLICATION explicit boolean permission accepted for "+effect.op)
   Events.arrive(g,"binding_cleric")
   var before=g.export_snapshot()
   var frozen=g.Events.freeze_effects(g,[effect])
   t.check(frozen.issue=="" and frozen.effects.size()==(2 if effect.op=="install_random" else 1) and frozen.effects.all(func(e):return e.get("replace")==permission),"EVENT APPLICATION freezes exact permission and count for "+effect.op)
   var expected=before.duplicate(true);expected.rng.event=g.state.rng.event
   t.check(g.state==expected,"EVENT APPLICATION freezing leaves all state except event RNG unchanged for "+effect.op)
  var invalid=declaration.duplicate(true);invalid.replace="true"
  t.check(Catalog._effect(g,invalid,baseline,true)!="","EVENT APPLICATION refuses non-boolean replacement for "+declaration.op)
 var unrelated={"op":"mana_loss","amount":3,"replace":true}
 t.check(Catalog._effect(g,unrelated,baseline,true)!="","EVENT APPLICATION replacement permission is not a general effect field")

 # A blocked exact target must not be silently retargeted, replaced, or charged.
 Events.arrive(g,"binding_cleric")
 while g._installation_reason("eye_cloth","eyes",1)=="":
  g._install_template("eye_cloth","eyes",4,10,false,"fixture")
 var original_ids=g.state.equipment.map(func(item):return item.id)
 var fixed={"op":"install","template":"eye_cloth","slot":"eyes","grade":2,"tier":2,"locked":false}
 var before=g.export_snapshot()
 t.check(g.Events.probe(g,[{"op":"mana_loss","amount":3},fixed])!="" and g.state==before,"EVENT APPLICATION blocked default installation rolls back payment, ids, logs and random")
 fixed.replace=true
 t.check(g.Events.probe(g,[fixed])=="" and g.state==before,"EVENT APPLICATION explicit replacement is probed without removing existing equipment")
 g.state.room_event.options=[{"id":"replace_test","label":"试装","detail":"支付3魔力并按指定规格替换眼罩。","reward":"none","effects":[{"op":"mana_loss","amount":3},fixed]}]
 var rng=g.state.rng.duplicate(true)
 t.check(Events.choose(t,g,"replace_test").ok and g.state.mana==before.mana-3,"EVENT APPLICATION authorized replacement commits exactly the declared cost")
 var added=g.state.equipment.filter(func(item):return item.id not in original_ids)
 t.check(added.size()==1 and added[0].grade==2 and g.state.equipment.size()==original_ids.size() and g.state.rng==rng,"EVENT APPLICATION exact replacement uses new physical id without reroll or changing specification")

 # Held equipment reserves its original capacity even while physically absent.
 var held=Game.new(41);Events.arrive(held,"binding_cleric")
 held._install_special("shaft_ring_low","special_2_a")
 held._install_special("full_cup_medium","special_2_a")
 t.check(held.Events.apply_effects(held,[{"op":"hold_special","key":"reserved","slots":["special_2_a"]}],held.state.room_event.refs,false)=="","EVENT APPLICATION held-capacity fixture uses existing hold effect")
 var held_before=held.export_snapshot()
 var fallback=held.Events.freeze_effects(held,[{"op":"special_install_random","types":["shaft_ring_low"],"replace":true,"fallback":[{"op":"mana_loss","amount":3}]}])
 t.check(fallback.issue=="" and fallback.effects==[{"op":"mana_loss","amount":3}],"EVENT APPLICATION unavailable special pool preserves the exact authored fallback")
 var expected=held_before.duplicate(true);expected.rng.event=held.state.rng.event
 t.check(held.state==expected,"EVENT APPLICATION fallback freeze preserves held instances, resources and unrelated RNG")
 var unavailable=held.Events.freeze_effects(held,[{"op":"special_install_random","types":["shaft_ring_low"],"replace":true}])
 t.check(unavailable.effects.is_empty() and unavailable.issue.contains("没有空余位置"),"EVENT APPLICATION unavailable special pool without fallback omits the choice instead of silently changing its effect")
 expected=held_before.duplicate(true);expected.rng.event=held.state.rng.event
 t.check(held.state==expected,"EVENT APPLICATION unavailable no-fallback freeze preserves equipment and resources")
 var choice_one=held.Events.freeze_choice(held,{"id":"small","label":"选择1","reward":"none","effects":[]})
 var choice_two=held.Events.freeze_choice(held,{"id":"large","label":"选择2","reward":"none","effects":[{"op":"special_install_random","types":["shaft_ring_low"],"replace":true}]})
 t.check(not choice_one.is_empty() and choice_two.is_empty(),"EVENT APPLICATION full special capacity keeps choice one and removes choice two")

 var special=Game.new(43);Events.arrive(special,"binding_cleric")
 var eligible=special._install_special("shaft_ring_low","special_2_a")
 var manual=special._install_special("vaginal_egg_low","special_3_a")
 var special_before=special.export_snapshot()
 var selected=special.Events.selector_values(special,{"kind":"restraint"})
 t.check(selected.any(func(item):return item.id==eligible.id and item.type==eligible.type) and not selected.any(func(item):return item.id==manual.id) and special.state==special_before,"EVENT APPLICATION special wager selector uses true lowering eligibility and exact instance id")
 t.check(special.Events.probe(special,[{"op":"ease_restraint","target":manual.id}])!="" and special.state==special_before,"EVENT APPLICATION restraint tag cannot grant a manual-only special an unsupported method")
 t.check(special.Events.probe(special,[{"op":"tighten","target":eligible.id}])!="" and special.state==special_before,"EVENT APPLICATION selectable special does not gain ordinary reinforcement")
 special.state.room_event.options=[{"id":"ease_test","label":"松开","detail":"松开所选装备一档。","reward":"none","effects":[{"op":"ease_restraint","target":eligible.id}]}]
 t.check(Events.choose(t,special,"ease_test").ok and special._equipment(eligible.id).durability==special.lower_durability(eligible.maximum*0.8,eligible.maximum),"EVENT APPLICATION eligible special lowers through the original event transaction")
 t.check(special._equipment(manual.id)==manual and special.state.mana==special_before.mana and special.state.rng==special_before.rng,"EVENT APPLICATION special lowering preserves unrelated equipment, resources and RNG")
