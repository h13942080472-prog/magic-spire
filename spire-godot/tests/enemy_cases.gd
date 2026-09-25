extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Enemies=preload("res://data/enemies.gd")
const Save=preload("res://tests/persistence_cases.gd")
static func encounter(id: String, seed_value: int=42):
 var g=Game.new(seed_value);g.state.room_encounters.entrance=id;g._start_battle();return g

static func run(t) -> void:
 humanoid_equipment_audit(t)
 preload("res://tests/enemy_health_cases.gd").run(t)
 preload("res://tests/reinforcement_lock_cases.gd").run(t)
 preload("res://tests/puppeteer_cases.gd").run(t)
 preload("res://tests/six_bind_cases.gd").run(t)
 preload("res://tests/binding_box_cases.gd").run(t)
 preload("res://tests/drone_cases.gd").run(t)
 preload("res://tests/enemy_versatile_cases.gd").run(t)
 preload("res://tests/enemy_mixed_cases.gd").run(t)
 preload("res://tests/enemy_ritual_cases.gd").run(t)
 preload("res://tests/enemy_serpent_cases.gd").run(t)
 preload("res://tests/enemy_split_cases.gd").run(t)
 preload("res://tests/enemy_heap_cases.gd").run(t)
 library_cases(t);ordinary_cases(t);toybox_cases(t);vision_cases(t);mouth_cases(t);lock_cases(t);weak_group_cases(t);strong_group_cases(t)
 var g
 g=encounter("double_rope")
 var first=g.state.enemies[0].id
 var second=g.state.enemies[1].id
 t.check(first!=second and g.state.enemies[0].name!=g.state.enemies[1].name,"DOUBLE identities and visible names distinct")
 var intent=g._enemy(first).intent.duplicate(true)
 g.state.round=2
 g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.action(g,"attack",{"type":"kick","form":2,"enemy":second})
 t.check(g._enemy(first).hp==30 and g._enemy(second).hp==22 and not g._enemy(first).intent.delayed and g._enemy(second).intent.delayed,"DOUBLE infused ordinary kick deals eight and delays only chosen second enemy")
 t.action(g,"end")
 t.check(g._enemy(first).stage==2 and g._enemy(second).stage==1 and g.state.equipment[0].source==first,"DOUBLE stages and equipment ownership independent")
 t.check(g.state.equipment[0].template in intent.templates and g.state.equipment[0].grade==intent.grade,"DOUBLE first enemy installs from its declared pool and grade")
 g._enemy(first).hp=1; g._enemy(second).hp=1
 t.action(g,"attack",{"type":"strike","enemy":first})
 t.check(g.state.phase=="battle" and g.state.reward_count==0,"DOUBLE first defeat gives no reward")
 t.action(g,"attack",{"type":"strike","enemy":second})
 t.check(g.state.phase=="reward" and g.state.reward_count==1,"DOUBLE last defeat gives one reward")

 g=Game.new(42)
 var old=g.state.enemies.map(func(e):return e.id)
 t.finish_room(g)
 t.action(g,"depart",{"room":"west"})
 while g.state.phase=="travel": t.action(g,"travel_step")
 t.check(g.state.enemies.all(func(e):return not old.has(e.id)),"IDENTITY enemy ids not reused across rooms")
 t.check(not t.action(g,"attack",{"type":"strike","enemy":old[0]}).ok,"IDENTITY old room enemy cannot receive new attacks")
 t.check(g.state.traversed_edges==[["entrance","west"]],"MAP records actual traversed edge")
 var route=g.get_view().route
 var entrance=route.filter(func(r):return r.id=="entrance")[0]
 t.check(entrance.paths.filter(func(p):return p.to=="west")[0].status=="travelled" and entrance.paths.filter(func(p):return p.to=="east")[0].status=="skipped","MAP unchosen edge is not highlighted as travelled")
 t.check(route.filter(func(r):return r.id=="west")[0].icon=="strong" and route.filter(func(r):return r.id=="east")[0].icon=="weak","MAP room icons follow actual encounter classification")
 var before=JSON.stringify(g.state)
 g.get_view(); g.route_view()
 t.check(JSON.stringify(g.state)==before,"MAP repeated projections preserve progress and randomness")
 t.finish_room(g)
 var next_room=g.room_data("west").next[0]
 t.action(g,"depart",{"room":next_room})
 route=g.get_view().route
 t.check(route.filter(func(r):return r.id=="west")[0].paths.filter(func(p):return p.to==next_room)[0].status=="travelling","MAP current journey edge distinct before arrival")
 while g.state.phase=="travel": t.action(g,"travel_step")
 t.check(g.state.traversed_edges==[["entrance","west"],["west",next_room]],"MAP optional rest preserves exact route history")
 t.check(g.validate()=="","IDENTITY final state valid")

static func mouth_cases(t) -> void:
 var Save=preload("res://tests/persistence_cases.gd")
 var templates={}
 for seed_value in t.seed_values("enemy_cycle"):
  var g=encounter("gag_solo",seed_value)
  var e=g.state.enemies[0]
  var rng=g.state.rng.duplicate(true)
  var before=g.state.duplicate(true)
  g.get_view();g.command_facts()
  t.check(g.state==before and e.intent.kind=="charge","MOUTH charge preview is readonly")
  t.check(t.action(g,"end").ok and g.state.equipment.is_empty() and g.state.enemies[0].stage==2,"MOUTH first turn only charges")
  t.check(t.action(g,"end").ok and g.state.equipment.is_empty() and g.state.enemies[0].intent.kind=="apply","MOUTH second turn only charges then announces application")
  t.check(g.state.rng.enemy==rng.enemy and g.state.rng.equipment==rng.equipment,"MOUTH charges defer equipment selection; normal deck shuffle stays independent")
  t.check(t.action(g,"end").ok and g.state.phase=="reward" and g.state.reward_count==1,"MOUTH third action departs and rewards once")
  var applied=g.equipment_at("mouth")[0]
  templates[applied.template]=true
  t.check(applied.template in Enemies.TYPES.gag.attachment_pool and applied.grade==2 and g.tier(applied.durability,applied.maximum)==3 and g.state.pressure==0,"MOUTH departure installs medium tier three without hidden pressure")
  t.check(g.state.composites.is_empty(),"MOUTH ordinary attachment does not add harness")
 t.check(templates.keys()==["mouth_band"],"MOUTH only the dedicated ball gag generates")
 for stage in [1,2,3]:
  var g=encounter("gag_solo")
  var id=g.state.enemies[0].id
  for i in range(stage-1): t.action(g,"end")
  var declared=g.state.enemies[0].intent.duplicate(true)
  g.state.round=maxi(g.state.round,2)
  g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
  t.check(t.action(g,"attack",{"type":"kick","form":2,"enemy":id}).ok,"MOUTH each published stage interruptible")
  var h=Save.roundtrip(t,g,"mouth delayed stage "+str(stage))
  Save.step_both(t,g,h,"end")
  t.check(g.state.enemies[0].stage==stage and g.state.enemies[0].intent==declared and g.state.equipment.is_empty(),"MOUTH interrupted stage retains declaration without attachment")
  Save.step_both(t,g,h,"end")
  t.check(g.state.enemies[0].stage==stage+1 and (g.state.equipment.size()==1 if stage==3 else g.state.equipment.is_empty()),"MOUTH resume advances once and installs only at the final step")
 var g=encounter("gag_solo")
 var id=g.state.enemies[0].id
 g.state.enemies[0].hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":id}).ok and g.state.phase=="reward" and g.state.equipment.is_empty(),"MOUTH early defeat prevents attachment")
 g=encounter("gag_solo")
 g.add_fixture("mouth",4)
 t.check(t.action(g,"manual",{"target":g.state.equipment[0].id}).ok,"MOUTH can clear occupied mouth during charge")
 t.action(g,"end")
 t.action(g,"end")
 t.check(g.state.enemies[0].intent.kind=="apply","MOUTH final stage announces application after mouth is cleared")
 g.add_fixture("mouth",4)
 var old=g.state.equipment.duplicate(true)
 t.check(t.action(g,"end").ok and g.state.phase=="reward" and g.state.equipment==old,"MOUTH newly occupied slot fails without overwriting or redirecting")
 g=encounter("gag_solo")
 g.add_fixture("mouth",4)
 old=g.state.equipment.duplicate(true)
 t.check(t.action(g,"end").ok,"MOUTH full slot completes saturated encounter")
 t.check(g.state.equipment==old and g.state.phase=="reward" and g.state.logs.any(func(l):return l.data.get("battle_end","")=="saturated"),"MOUTH occupied slot ends battle without overwriting equipment")

 g=encounter("belt_gag")
 g.state.posture="lie"
 t.action(g,"end");t.action(g,"end")
 t.check(g.state.phase=="battle" and g.state.order=="last" and g.occupied("mouth") and g.state.enemies[1].gone and g.state.reward_count==0,"MOUTH enemy-first application immediately affects ongoing mixed battle")
 var spell=t.find_action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})
 t.check(spell.valid and g.cast_view().chance>0 and g.cast_view().chance<g.cast_view().base,"MOUTH actual same-turn fireball receives mouth probability multiplier")
 var gesture=t.grant_fixture_card(g,"unlock")
 t.check(t.find_action(g,"card",{"uid":gesture.uid,"free":true}).valid,"MOUTH free preparation still usable while mouth chance is reduced")
 var target=g.equipment_at("mouth")[0]
 t.check(target.grade==2 and g.tier(target.durability,target.maximum)==3,"MOUTH combined encounter installs medium tier-three mouth equipment")
 t.check(g.escape_preview(target,"strain",5).reason=="","MOUTH ordinary oral equipment retains formal strain route")
 var h=Save.roundtrip(t,g,"mouth enemy-first attachment")
 Save.step_both(t,g,h,"end")
 t.check(g.state.reward_count==1 and g.occupied("mouth"),"MOUTH remaining enemy departure gives one reward and keeps equipment")

static func vision_cases(t) -> void:
 var g=Game.new(42)
 var frozen=g.state.enemies.duplicate(true)
 var first=g.add_fixture("eyes",4)
 var second=g.add_fixture("eyes",4)
 var before=g.state.duplicate(true)
 var v=g.get_view()
 t.check(v.enemies.all(func(e):return not e.intent_visible and e.stage==0 and e.intent_icons.size()==1 and e.intent_icons[0].kind=="hidden"),"VISION all live enemies concealed at any eye tightness")
 t.check(g.state==before and g.state.enemies==frozen,"VISION viewing does not change frozen plans, resources or random")
 t.check(v.display_facts.any(func(c):return c.payload.kind=="attack" and c.valid),"VISION ordinary attacks remain usable")
 t.check(t.action(g,"manual",{"target":second.id}).ok and not g.can_observe_intents(),"VISION removing one of stacked masks does not restore sight")
 var remaining=g.state.enemies.duplicate(true)
 t.check(t.action(g,"manual",{"target":first.id}).ok and g.get_view().enemies.all(func(e):return e.intent_visible) and g.state.enemies==remaining,"VISION last mask removal restores same plans immediately")
 # Partial durability loss leaves vision blocked until the last covering item is removed.
 g=Game.new(42)
 var mask=g._install_template("eye_cloth","eyes",8,10,false,"fixture")
 var unlock=g.state.deck.filter(func(c):return c.type=="slip")[0]
 g.state.hand.erase(unlock);g.state.draw.erase(unlock);g.state.hand.append(unlock)
 t.check(t.action(g,"card",{"uid":unlock.uid,"target":mask.id}).ok and not g.can_observe_intents(),"VISION partial slip damage never reveals intent")
 var h=Game.new(1)
 t.check(h.restore_snapshot(g.export_snapshot()).ok and not h.get_view().enemies[0].intent_visible and h.state.enemies==g.state.enemies,"VISION restore conceals without reroll")
 g.state.round=maxi(g.state.round,2)
 g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.check(t.action(g,"attack",{"type":"kick","form":2,"enemy":g.state.enemies[0].id}).ok and g.state.enemies[0].intent.delayed and not g.get_view().enemies[0].intent_visible,"VISION blind interruption still delays frozen action")
 # No newly generated charge/preparation log may reveal hidden future operations.
 g=encounter("gag_solo");g.add_fixture("eyes",4)
 t.action(g,"end")
 t.check(g.state.logs.any(func(log):return log.text.contains("未能看清")) and g.state.summary.contains("无法观察敌人意图") and not g.state.logs.any(func(log):return log.text.contains("准备施加")),"VISION attachment charge log conceals planned equipment")
 g=Game.new(42,true,"guard");g.add_fixture("eyes",4)
 var guard=g.state.enemies[0];guard.stage=2;guard.guard.bind_ready=false;guard.intent={"kind":"bind_prepare","text":"准备捕缚","delayed":false}
 t.action(g,"end")
 t.check(g.state.enemies[0].guard.bind_ready and not g.get_view().enemies[0].intent_visible and not g.state.logs.any(func(log):return log.text.contains("准备捕缚")),"VISION bind preparation stays functional but concealed")

static func library_cases(t) -> void:
 for type in Enemies.Library.CLASSIFICATIONS.weak:
  var g=encounter(type+"_solo")
  t.check(Enemies.TYPES[type].strength in [1,2] and not g.get_view().enemies[0].has("strength"),"WEAK independent strength within budget "+type)
  t.check(g.state.enemies[0].hp==Enemies.TYPES[type].hp and g.state.enemies[0].grade==1,"WEAK strength does not scale HP or grade "+type)
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(g.state==before,"WEAK projection does not reroll "+type)
  Save.roundtrip(t,g,"new weak "+type)
 for seed_value in t.seed_values("enemy_pool"):
  var g=preload("res://core/game.gd").new(seed_value)
  var twin=preload("res://core/game.gd").new(seed_value)
  t.check(g.state.room_encounters==twin.state.room_encounters,"WEAK reproducible undecided room plans")
  for r in g.state.rooms:
   if r.has("encounter_choices"):
    t.check(r.encounter_choices.weak=="weak_group" and r.encounter_choices.strong=="" and not r.has("enemy_members"),"WEAK rooms defer member draw until arrival")
 var original_pool=Enemies.FirstFloor.POOLS.weak.duplicate()
 var detached=Enemies.FirstFloor.choices("weak");detached.clear()
 t.check(Enemies.FirstFloor.POOLS.weak==original_pool,"WEAK pool view detached")

static func ordinary_cases(t) -> void:
 for type in ["rope","belt","tape","cable_tie"]:
  for seed_value in t.seed_values("enemy_cycle"):
   var g=encounter(type+"_solo",seed_value);var id=g.state.enemies[0].id
   var first=g._enemy(id).intent.duplicate(true)
   t.check(first.kind=="apply" and first.grade==1 and first.tier==2,"WEAK initial application declares basic tier two")
   t.action(g,"end")
   t.check(g.state.equipment.size()==1 and g.state.equipment[0].source==id and g.state.equipment[0].template in Enemies.TYPES[type].install_pool and g.state.equipment[0].grade==1 and g.tier(g.state.equipment[0].durability,g.state.equipment[0].maximum)==2,"WEAK sampled first install uses own material, basic grade and tier two")
   t.check(g._enemy(id).intent.kind=="tighten","WEAK second action reinforces same material")
   t.action(g,"end")
   t.check(g._enemy(id).stage==3 and g._enemy(id).intent.kind=="charge","WEAK third action prepares")
   var h=Save.roundtrip(t,g,"final charge "+type)
   Save.step_both(t,g,h,"end")
   t.check(g._enemy(id).intent.kind=="apply" and g._enemy(id).intent.final and g._enemy(id).intent.grade==2 and g._enemy(id).intent.tier==3,"WEAK preparation advances to final middle-grade tier-three application")
   Save.step_both(t,g,h,"end")
   t.check(g.state.phase=="reward" and g.state.reward_count==1 and g._enemy(id).gone,"WEAK final leaves with one reward")
   t.check(g.state.equipment.any(func(e):return e.source==id and e.template in Enemies.TYPES[type].final_pool and e.grade==2 and g.tier(e.durability,e.maximum)==3),"WEAK sampled final equipment remains from final pool at medium tier three")
 var head=encounter("tape_solo")
 head.add_fixture("wrist",8);head.add_fixture("fingers",8,10,false,0,"cord")
 t.check(head.Application.choose(head,{"templates":Enemies.TYPES.tape.install_pool,"grade":1},"test").template=="mouth_tape","WEAK tape chooses empty mouth before third-band eyes")
 t.check(head.Application.choose(head,{"templates":["eye_tape"],"grade":1},"test").slot=="eyes" and head.Application.choose(head,{"templates":["eye_leather"],"grade":1},"test").is_empty(),"WEAK restricted head source respects minimum grade")
 # Reinforcement chooses from equipment present when it acts, preferring its own source.
 var g=encounter("rope_solo");t.action(g,"end")
 var id=g.state.enemies[0].id;var original=g.state.equipment[0].id
 var other=g._install_template("cord","toes",4,10,false,"fixture")
 var unrelated=g._install_template("belt","ankle",1,10,false,id)
 t.action(g,"end")
 t.check(g._equipment(original).durability==10 and g._equipment(other.id).durability==4 and g._equipment(unrelated.id).durability==1,"WEAK reinforcement prioritizes its own material and source over a looser foreign piece")
 g=encounter("rope_solo");t.action(g,"end")
 original=g.state.equipment[0].id
 other=g._install_template("cord","toes",4,10,false,"fixture")
 g._equipment(original).durability=0;g._cleanup()
 t.action(g,"end")
 t.check(g._equipment(other.id).durability==8,"WEAK reinforcement chooses the remaining same-material piece at execution")
 g=encounter("rope_solo");t.action(g,"end");id=g.state.enemies[0].id
 g.state.equipment[0].durability=0;g._cleanup()
 var h=Save.roundtrip(t,g,"reinforcement after last piece removed")
 Save.step_both(t,g,h,"end")
 t.check(g.physical_pieces().is_empty() and g._enemy(id).stage==3 and g.state.logs.any(func(l):return l.text.contains("没有可以加固")),"WEAK targetless execution consumes its step and reports the missed reinforcement")
 # With no target at generation, the monster draws one of its existing apply actions.
 for seed_value in t.seed_values("enemy_cycle"):
  g=encounter("rope_solo",seed_value);id=g.state.enemies[0].id
  g._enemy(id).stage=2;g._enemy(id).intent=g._plan(g._enemy(id))
  var declared=g._enemy(id).intent.duplicate(true)
  t.check(declared.kind=="apply" and declared.grade in [1,2],"WEAK empty reinforcement generation draws an existing application")
  t.check(t.action(g,"end").ok and g.state.equipment.size()==1,"WEAK substitute declaration executes exactly one installation")
  var installed=g.state.equipment[0]
  var pool=Enemies.TYPES.rope.final_pool if declared.final else Enemies.TYPES.rope.install_pool
  t.check(installed.template in pool and installed.grade==(2 if declared.final else 1) and g.tier(installed.durability,installed.maximum)==(3 if declared.final else 2) and g._enemy(id).gone==declared.final,"WEAK only departure upgrades tier; normal application keeps its original grade and tier")
 # Fill wrists after the final declaration; execution selects the now-empty mouth.
 g=encounter("tape_solo");t.action(g,"end");t.action(g,"end");t.action(g,"end")
 for i in range(5):g._install_template("tape","wrist",4,10,false,"fixture")
 var count=g.state.equipment.size();t.action(g,"end")
 t.check(g.state.phase=="reward" and g.state.equipment.size()==count+1 and g.equipment_at("mouth").size()==1 and g.equipment_at("mouth")[0].grade==2,"WEAK final execution chooses current legal priority and leaves after one installation")

static func toybox_cases(t) -> void:
 for stage in [1,2,3]:
  var g=encounter("toybox_solo");var id=g.state.enemies[0].id
  for i in range(stage-1):t.action(g,"end")
  var before=g.state.special_equipment.size();var declared=g._enemy(id).intent.duplicate(true)
  g.state.round=maxi(g.state.round,2)
  g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
  t.check(t.action(g,"attack",{"type":"kick","form":2,"enemy":id}).ok,"BOX every step interruptible")
  var h=Save.roundtrip(t,g,"box delayed "+str(stage))
  Save.step_both(t,g,h,"end")
  t.check(g._enemy(id).stage==stage and g.state.special_equipment.size()==before and g._enemy(id).intent==declared,"BOX interrupt retains the step and declaration until execution")
  Save.step_both(t,g,h,"end")
  t.check(g._enemy(id).stage==stage+1 and not g._enemy(id).gone,"BOX resumes one step")
 var g=encounter("toybox_solo");var id=g.state.enemies[0].id
 t.action(g,"end")
 t.check(g.state.special_equipment.is_empty() and g._enemy(id).intent.kind=="apply","BOX preparation advances to application without installing")
 t.action(g,"end")
 t.check(g.state.special_equipment.size()==1 and g.state.special_equipment[0].type in Enemies.TYPES.toybox.special_pool and g._enemy(id).intent.kind=="pause","BOX second action installs one legal pool item")
 var h=Save.roundtrip(t,g,"box pause");Save.step_both(t,g,h,"end")
 t.check(g.state.special_equipment.size()==1 and g._enemy(id).stage==4 and g._enemy(id).intent.kind=="charge" and g.state.reward_count==0,"BOX third action pauses then new cycle begins")
 t.action(g,"end");t.action(g,"end")
 t.check(g.state.special_equipment.size()==2 and not g._enemy(id).gone,"BOX second cycle adds exactly one and remains")
 # Only one type is still legal after the announcement; it must be selected at execution.
 g=encounter("toybox_solo");id=g.state.enemies[0].id
 t.action(g,"end")
 var available=Enemies.TYPES.toybox.special_pool[-1]
 for type in Enemies.TYPES.toybox.special_pool:
  if type!=available:g._install_special(type,g.SpecialEquipment.DESIGNS[type].slots[0])
 var equipment=g.state.special_equipment.map(func(item):return item.id)
 h=Save.roundtrip(t,g,"box legal pool changed before execution")
 Save.step_both(t,g,h,"end")
 var added=g.state.special_equipment.filter(func(item):return item.id not in equipment)
 t.check(added.size()==1 and added[0].type==available and g.state.phase=="reward","BOX last legal installation completes the saturated encounter")
 # A different living source keeps battle active; reopening the pool still works.
 g=encounter("toybox_solo");id=g.state.enemies[0].id
 g._append_enemies([{"type":"rope","grade":1}]);g.state.enemies.back().intent=g._plan(g.state.enemies.back())
 for type in Enemies.TYPES.toybox.special_pool:g._install_special(type,g.SpecialEquipment.DESIGNS[type].slots[0])
 equipment=g.state.special_equipment.map(func(item):return item.id)
 t.action(g,"end")
 h=Save.roundtrip(t,g,"box full pool before execution")
 Save.step_both(t,g,h,"end")
 t.check(g.state.special_equipment.map(func(item):return item.id)==equipment and g._enemy(id).intent.kind=="pause" and g.state.logs.any(func(l):return l.text.contains("没有合法位置")),"BOX full pool preserves existing pieces and reports the missed application")
 t.action(g,"end")
 t.check(g._enemy(id).stage==4 and g._enemy(id).intent.kind=="charge" and not g._enemy(id).gone and g.state.reward_count==0,"BOX full pool still completes its cycle and stays in battle")
 var reopened=g.state.special_equipment[-1].type
 g.state.special_equipment[-1].durability=0;g._cleanup()
 equipment=g.state.special_equipment.map(func(item):return item.id)
 t.action(g,"end");t.action(g,"end")
 added=g.state.special_equipment.filter(func(item):return item.id not in equipment)
 t.check(added.size()==1 and added[0].type==reopened,"BOX next execution uses the reopened pool choice")
 g=encounter("toybox_solo");id=g.state.enemies[0].id;g._enemy(id).hp=1
 t.action(g,"attack",{"type":"strike","enemy":id})
 t.check(g.state.special_equipment.is_empty() and g.state.phase=="reward","BOX defeat cancels pending equipment")
 # Corrupt the current application declaration, preserving atomic restore coverage.
 g=encounter("toybox_solo");t.action(g,"end")
 var save=g.export_snapshot();save.enemies[0].intent.count=-1
 var before=g.export_snapshot();t.check(not g.restore_snapshot(save).ok and g.state==before,"BOX invalid application count restore atomic")

 # Enemy-first pause may finish with no next plan yet; save resumes into next preparation.
 g=encounter("toybox_solo");g.state.posture="lie"
 for i in range(3):
  t.check(t.action(g,"end").ok,"BOX enemy-first end")
  Save.roundtrip(t,g,"box enemy-first "+str(i))


static func lock_battle():
 var g=Game.new(42)
 g._install_template("belt","wrist",8,10,false,"fixture")
 g._install_template("belt","forearm",4,10,false,"fixture")
 g.state.room_encounters.entrance="lock_solo";g._start_battle()
 return g

static func lock_cases(t) -> void:
 lock_departure_cases(t)
 var g=lock_battle();var e=g.state.enemies[0]
 for cycle in range(2):
  var before=g.state.equipment.duplicate(true)
  t.check(g.state.enemies[0].intent.kind=="charge" and g.state.enemies[0].intent.text.contains("预告上锁"),"LOCK announces each cycle")
  t.check(t.action(g,"end").ok and g.state.equipment==before and g.state.enemies[0].intent.kind=="lock","LOCK announcement changes no equipment")
  var target=g.state.equipment.filter(func(item):return not item.locked)[0].id if cycle==1 else g.state.equipment[1].id
  for item in before:
   if item.id==target:item.locked=true
  t.check(t.action(g,"end").ok and g.state.equipment==before and g.state.phase==("battle" if cycle==0 else "reward") and g.state.reward_count==cycle,"LOCK continues while targets remain and rewards after locking the last target")
 for stage in [1,2]:
  g=lock_battle();e=g.state.enemies[0]
  if stage==2:t.action(g,"end")
  var before=g.state.equipment.duplicate(true);var declared=g.state.enemies[0].intent.duplicate(true)
  g.state.round=maxi(g.state.round,2)
  g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
  t.check(t.action(g,"attack",{"type":"kick","form":2,"enemy":e.id}).ok,"LOCK interrupt remains legal")
  var h=Save.roundtrip(t,g,"lock delayed "+str(stage))
  Save.step_both(t,g,h,"end")
  t.check(g.state.enemies[0].stage==stage and g.state.enemies[0].intent==declared and g.state.equipment==before,"LOCK interrupted step preserves declaration and equipment")
  Save.step_both(t,g,h,"end")
  t.check(g.state.enemies[0].stage==stage+1 and not g.state.enemies[0].gone,"LOCK interrupted step resumes once")
 g=lock_battle();e=g.state.enemies[0];t.action(g,"end")
 var removed=g.state.equipment[1].id
 g._equipment(removed).durability=0;g._cleanup()
 var other=g.state.equipment[0];var before=other.duplicate(true);before.locked=true
 t.check(t.action(g,"end").ok and g._equipment(other.id)==before and g.state.equipment.size()==1 and g.state.phase=="reward","LOCK execution chooses the remaining actual target and finishes")
 g=lock_battle();t.action(g,"end")
 for item in g.state.equipment:item.locked=true
 before=g.state.equipment.duplicate(true)
 var h=Save.roundtrip(t,g,"lock all pieces already locked")
 Save.step_both(t,g,h,"end")
 t.check(g.state.equipment==before and g.state.phase=="reward" and g.state.logs.any(func(l):return l.data.get("battle_end","")=="saturated"),"LOCK no current target ends the encounter without applying another action")
 g=lock_battle();e=g.state.enemies[0];e.hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":e.id}).ok and g.state.phase=="reward" and g.state.reward_count==1 and g.state.equipment.all(func(item):return not item.locked),"LOCK defeat cancels pending lock and rewards normally")
 # Enemy-first cadence still restores after a completed lock and before the next announcement.
 g=lock_battle();g.state.posture="lie"
 for step in range(2):
  t.check(t.action(g,"end").ok,"LOCK enemy-first step")
  Save.roundtrip(t,g,"lock enemy-first "+str(step))


static func lock_departure_cases(t) -> void:
 for chance in [5,100]:
  var g=lock_battle();g.state.chastity_locks_enabled=true;g.state.chastity_lock_chance=chance
  var id=g.state.enemies[0].id
  for turn in range(4): t.check(t.action(g,"end").ok,"LOCK DEPARTURE ordinary locking cycle commits")
  t.check(g.state.phase=="battle" and g._enemy(id).intent.final and g._enemy(id).intent.templates==["negative_plate_lock_medium"],"LOCK DEPARTURE exhaustion announces fixed medium plate without early victory")
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(g.state==before,"LOCK DEPARTURE preview does not install or reroll")
  g.state.card_buffs.append("infusion_bound")
  t.check(t.action(g,"attack",{"type":"kick","form":2,"enemy":id}).ok,"LOCK DEPARTURE final attachment can be interrupted")
  var twin=Save.roundtrip(t,g,"lock fixed departure")
  Save.step_both(t,g,twin,"end")
  t.check(g.state.special_equipment.is_empty() and not g._enemy(id).gone,"LOCK DEPARTURE interruption postpones attachment and departure together")
  Save.step_both(t,g,twin,"end")
  var locks=g.state.special_equipment.filter(g.SpecialEquipment.is_chastity)
  t.check(locks.size()==1 and locks[0].type=="negative_plate_lock_medium" and locks[0].grade==2 and g.tier(locks[0].durability,locks[0].maximum)==3 and locks[0].locked,"LOCK DEPARTURE both probability bounds install the fixed locked medium tier-three plate")
  t.check(g.state.special_equipment.any(func(item):return item.type=="chastity_reinforcement_medium"),"LOCK DEPARTURE tier three uses the normal automatic reinforcement-band rule")
  t.check(g._enemy(id).gone and g.state.phase=="reward" and g.state.reward_count==1,"LOCK DEPARTURE applies before leaving and rewards once")
 for existing in ["negative_plate_lock_medium","negative_vibrator_lock_catheter_high"]:
  var g=lock_battle();g.state.chastity_locks_enabled=true
  g._install_special(existing,"special_2_a",2)
  for item in g.state.equipment: item.locked=true
  var e=g.state.enemies[0];e.intent=g._plan(e)
  var before=g.state.special_equipment.duplicate(true)
  t.check(t.action(g,"end").ok and g.state.phase=="reward" and g._enemy(e.id).gone and g.state.special_equipment==before,"LOCK DEPARTURE blocked attachment leaves without duplicating or downgrading an existing plate")
 var g=lock_battle();g.state.chastity_locks_enabled=true
 for item in g.state.equipment: item.locked=true
 var e=g.state.enemies[0];e.intent=g._plan(e);e.hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":e.id}).ok and g.state.phase=="reward" and g.state.special_equipment.is_empty(),"LOCK DEPARTURE defeat cancels the pending attachment")

static func weak_group_cases(t) -> void:
 var LiveGame=preload("res://core/game.gd")
 var seen={};var duplicated=false
 for seed_value in t.seed_values("enemy_pool"):
  var g=LiveGame.new(seed_value)
  t.check(t.action(g,"departure",{"op":"skip"}).ok,"POOL finish floor-zero departure before route sampling")
  g._install_template("belt","wrist",8,10,false,"fixture")
  var before=g.export_snapshot();var options=Enemies.FirstFloor.candidates(g)
  t.check(g.state==before and options.size()==Enemies.Library.CLASSIFICATIONS.weak.size(),"POOL admission reads all registered eligible types without mutation")
  var next=g.room_data(g.state.room).next[0]
  t.check(t.action(g,"depart",{"room":next}).ok,"POOL enter through real route")
  while g.state.phase=="travel":t.action(g,"travel_step")
  var room=g.room_data(g.state.room)
  t.check(g.state.enemies.size() in [1,2] and room.enemy_members.reduce(func(total,m):return total+Enemies.TYPES[m.type].strength,0)==2,"POOL exact strength two from actual arrival")
  for type in ["gag","lock"]:
   t.check(g.state.enemies.filter(func(e):return e.type==type).size()<=1,"POOL real arrival never duplicates limited monster: "+type)
  for e in g.state.enemies:seen[e.type]=true
  duplicated=duplicated or (g.state.enemies.size()==2 and g.state.enemies[0].type==g.state.enemies[1].type)
  before=g.export_snapshot();g.get_view();g.route_view();g.command_facts()
  t.check(g.state==before,"POOL previews preserve frozen room roster and random counters")
 if t.exhaustive:
  # Route seeds cover entry; direct pool draws cover an extensible roster without
  # rebuilding whole towers just to observe a rare member.
  var sampling=LiveGame.new(41)
  sampling._install_template("belt","wrist",8,10,false,"fixture")
  for i in range(256):
   if seen.size()==Enemies.Library.CLASSIFICATIONS.weak.size() and duplicated: break
   var rolled=Enemies.FirstFloor.roll(sampling)
   for member in rolled: seen[member.type]=true
   duplicated=duplicated or (rolled.size()==2 and rolled[0].type==rolled[1].type)
  t.check(seen.size()==Enemies.Library.CLASSIFICATIONS.weak.size() and duplicated,"POOL all registered types and repeated-type groups reachable")
 var g=LiveGame.new(41)
 t.check(t.action(g,"departure",{"op":"skip"}).ok,"POOL finish floor-zero departure before conditional route sampling")
 g._install_template("mouth_band","mouth",4,10,true,"fixture")
 var belt=g._install_template("belt","wrist",8,10,true,"fixture")
 for i in range(8):
  var members=Enemies.FirstFloor.roll(g)
  t.check(members.reduce(func(total,m):return total+Enemies.TYPES[m.type].strength,0)==2 and members.all(func(m):return m.type not in ["gag","lock"]),"POOL occupied mouth and no unlocked lockable gear exclude both types")
 g._equipment(belt.id).locked=false
 t.check(Enemies.FirstFloor.candidates(g).any(func(m):return m.type=="lock"),"POOL unlocking existing gear restores lock eligibility")
 var next=g.room_data(g.state.room).next[0];t.action(g,"depart",{"room":next})
 while g.state.phase=="travel":t.action(g,"travel_step")
 var h=Save.roundtrip(t,g,"budgeted conditional weak group")
 Save.step_both(t,g,h,"end")
 var bad=g.export_snapshot();bad.rooms.filter(func(r):return r.id==bad.room)[0].enemy_members.pop_back()
 var old=g.export_snapshot()
 t.check(not g.restore_snapshot(bad).ok and g.state==old,"POOL incomplete saved roster rejected atomically")
 # All strict candidates excluded: relax only non-mouth/non-lock eligibility.
 var pool=Enemies.FirstFloor.POOLS.weak.duplicate()
 g=LiveGame.new(2);g._install_template("mouth_band","mouth",4,10,true,"fixture")
 for id in Enemies.TYPES.toybox.special_pool:g._install_special(id,g.SpecialEquipment.DESIGNS[id].slots[0])
 Enemies.FirstFloor.POOLS.weak=["gag_solo","lock_solo","toybox_solo"]
 t.check(Enemies.FirstFloor.candidates(g).is_empty(),"POOL fallback fixture has no strict candidate")
 var fallback=Enemies.FirstFloor.roll(g)
 t.check(fallback.size()==2 and fallback.all(func(m):return m.type=="toybox"),"POOL fallback never reinstates excluded mouth or lock")
 Enemies.FirstFloor.POOLS.weak=pool
 # Count follows the budget rather than a hard-coded two-enemy loop.
 var strength=Enemies.TYPES.rope.strength;Enemies.TYPES.rope.strength=2;Enemies.FirstFloor.POOLS.weak=["rope_solo"]
 var single=Enemies.FirstFloor.roll(LiveGame.new(3))
 t.check(single.size()==1 and single[0].type=="rope","POOL budget controls count for future strengths")
 Enemies.TYPES.rope.strength=strength;Enemies.FirstFloor.POOLS.weak=pool
 limited_group_cases(t)

static func limited_group_cases(t) -> void:
 var g=preload("res://core/game.gd").new(42)
 g._install_template("belt","wrist",8,10,false,"fixture")
 var original=Enemies.FirstFloor.POOLS.weak.duplicate()
 for type in ["gag","lock"]:
  Enemies.FirstFloor.POOLS.weak=[type+"_solo"]
  var before=g.export_snapshot()
  t.check(Enemies.FirstFloor.roll(g).is_empty() and g.state==before,"POOL unique monster alone cannot fill two points or consume RNG: "+type)
  var single=Enemies.FirstFloor.roll(g,1)
  t.check(single.size()==1 and single[0].type==type,"POOL unique monster remains eligible alone: "+type)
  Enemies.FirstFloor.POOLS.weak=[type+"_solo","rope_solo"]
  var seen_limited=false;var seen_pair=false
  for i in range(32):
   var roster=Enemies.FirstFloor.roll(g)
   var amount=roster.filter(func(m):return m.type==type).size()
   seen_limited=seen_limited or amount==1;seen_pair=seen_pair or amount==0
   t.check(roster.size()==2 and amount<=1,"POOL same-type limit preserves exact budget: "+type)
  t.check(seen_limited and seen_pair,"POOL mixed partner and repeatable rope pair both remain reachable: "+type)
 Enemies.FirstFloor.POOLS.weak=["gag_solo","lock_solo"]
 var pair=Enemies.FirstFloor.roll(g)
 t.check(pair.size()==2 and pair.any(func(m):return m.type=="gag") and pair.any(func(m):return m.type=="lock"),"POOL one gag and one lock can share an encounter")
 var before=g.export_snapshot()
 t.check(Enemies.FirstFloor.roll(g,3).is_empty() and g.state==before,"POOL two limited types cannot fill a larger budget by duplication")
 Enemies.FirstFloor.POOLS.weak=["gag_solo","toybox_solo"]
 for id in Enemies.TYPES.toybox.special_pool:g._install_special(id,g.SpecialEquipment.DESIGNS[id].slots[0])
 var strict=Enemies.FirstFloor.candidates(g)
 t.check(strict.size()==1 and strict[0].type=="gag","POOL strict supply contains only the eligible unique gag")
 var relaxed=Enemies.FirstFloor.roll(g)
 t.check(relaxed.size()==2 and relaxed.filter(func(m):return m.type=="gag").size()<=1 and relaxed.any(func(m):return m.type=="toybox"),"POOL nonempty but insufficient unique supply relaxes other eligibility to complete budget")
 Enemies.FirstFloor.POOLS.weak=original

static func strong_group_cases(t) -> void:
 var LiveGame=preload("res://core/game.gd")
 for recipe in ["drone_pair","ominous_circle_pair","serpent_weak","versatile_trader"]:
  var battle=LiveGame.new(42)
  var room=battle.state.rooms.filter(func(r):return r.get("pool","")=="ordinary")[0]
  room.erase("encounter_choices")
  battle.state.room=room.id;battle.state.room_encounters[room.id]=recipe
  battle._start_battle()
  var types=battle.state.enemies.map(func(e):return e.type)
  var expected=Enemies.ENCOUNTERS[recipe].fixed_members.map(func(m):return m.type)
  t.check(recipe in Enemies.FirstFloor.choices("strong") and types.size()==2 and expected.all(func(type):return types.count(type)==expected.count(type)) and types.reduce(func(total,type):return total+Enemies.TYPES[type].strength,0)==4,"STRONG registered new recipe spawns its exact members and strength: "+recipe)
  if recipe=="serpent_weak":
   var weak_members=types.filter(func(type):return type in Enemies.Library.CLASSIFICATIONS.weak and Enemies.TYPES[type].strength==1)
   t.check(Enemies.TYPES.rope_serpent.strength==3 and weak_members.size()==1,"STRONG serpent fills only one strength-one weak slot")
 var seen={};var skins={};var weak_types={};var checked_duplicate=false
 for seed_value in t.seed_values("enemy_pool"):
  var g=LiveGame.new(seed_value)
  # Three completed ordinary fights: the next real entry selects a strong recipe.
  var rooms=g.state.rooms.filter(func(r):return r.get("pool","")=="ordinary")
  g.state.completed_rooms=rooms.slice(0,3).map(func(r):return r.id)
  g._install_template("belt","wrist",8,10,false,"fixture")
  for index in range(3,5):
   var room=rooms[index];var previous=g.state.last_strong_group
   g.state.room=room.id;g._start_battle()
   var group=g.state.room_encounters[room.id];seen[group]=true
   t.check(group in Enemies.FirstFloor.choices("strong") and group!=previous and g.state.last_strong_group==group,"STRONG draws registered recipe excluding previous actual group")
   var roster=room.enemy_members
   t.check(roster.reduce(func(total,m):return total+Enemies.TYPES[m.type].strength,0)==4,"STRONG actual roster exact strength four")
   for type in ["gag","lock"]:
    t.check(roster.filter(func(m):return m.type==type).size()<=1,"STRONG mixed roster never duplicates limited monster: "+type)
   var masses=roster.filter(func(m):return Enemies.TYPES[m.type].get("family","")=="mass_family")
   var weak=roster.filter(func(m):return Enemies.TYPES[m.type].strength==1)
   var recipe_matches=roster==Enemies.ENCOUNTERS[group].get("fixed_members",[])
   if group=="mass_weak": recipe_matches=roster.size()==2 and masses.size()==1 and weak.size()==1
   elif group=="four_weak": recipe_matches=roster.size()==4 and weak.size()==4 and roster.all(func(m):return roster.filter(func(other):return other.type==m.type).size()==1)
   elif group=="serpent_weak": recipe_matches=roster.size()==2 and roster[0].type=="rope_serpent" and weak.size()==1
   t.check(recipe_matches,"STRONG selected recipe controls composition")
   for m in masses:skins[m.type]=true
   for m in weak:weak_types[m.type]=true
   if group=="four_weak" and not checked_duplicate:
    var original=g.export_snapshot();var broken=original.duplicate(true)
    var bad_room=broken.rooms.filter(func(r):return r.id==broken.room)[0]
    bad_room.enemy_members[-1]=bad_room.enemy_members[0].duplicate(true)
    t.check(not g.restore_snapshot(broken).ok and g.state==original,"STRONG same-strength duplicate type in four-weak roster rejects atomically")
    checked_duplicate=true
   var before=g.export_snapshot();g.get_view();g.route_view();g.command_facts()
   t.check(g.state==before,"STRONG preview preserves members, variant and no-repeat history")
   g.state.completed_rooms.append(room.id)
 if t.exhaustive:
  t.check(seen.size()==Enemies.FirstFloor.choices("strong").size() and skins.size()==2 and weak_types.size()==Enemies.Library.CLASSIFICATIONS.weak.filter(func(type):return Enemies.TYPES[type].strength==1).size() and checked_duplicate,"STRONG all recipes material variants and eligible unique weak types reached")
 # Exact supply boundary: draw all four distinct types, never repeat to fill a shortage.
 var sampling=LiveGame.new(42);var original_pool=Enemies.FirstFloor.POOLS.weak
 Enemies.FirstFloor.POOLS.weak=["rope_solo","belt_solo","tape_solo","cable_tie_solo"]
 var exact=Enemies.FirstFloor.roll(sampling,4,1,true)
 t.check(exact.size()==4 and exact.all(func(m):return exact.filter(func(other):return other.type==m.type).size()==1),"STRONG four available types yield exactly four different monsters")
 Enemies.FirstFloor.POOLS.weak=["rope_solo","belt_solo","tape_solo"]
 var unchanged=sampling.export_snapshot()
 t.check(Enemies.FirstFloor.roll(sampling,4,1,true).is_empty() and sampling.state==unchanged,"STRONG insufficient distinct types produce no partial draw or random consumption")
 Enemies.FirstFloor.POOLS.weak=original_pool
 # Save the actual recipe/roster, resume its turn, then choose the next strong group.
 var g=LiveGame.new(41)
 g._install_template("mouth_band","mouth",4,10,true,"fixture")
 var rooms=g.state.rooms.filter(func(r):return r.get("pool","")=="ordinary")
 g.state.completed_rooms=rooms.slice(0,3).map(func(r):return r.id)
 g.state.room=rooms[3].id;g._start_battle()
 var h=Save.roundtrip(t,g,"strong recipe and frozen roster")
 Save.step_both(t,g,h,"attack",{"type":"strike","enemy":g.state.enemies[0].id})
 var last=g.state.last_strong_group
 # An intervening rest room does not clear strong encounter history.
 for live in [g,h]:
  live.state.room=live.state.rooms.filter(func(r):return r.kind=="rest")[0].id
  live.state.phase="rest";live.state.rest_left=5
 var resumed=LiveGame.new(0,false,"equipment",false)
 t.check(resumed.restore_snapshot(Save.Store.unpack(Save.Store.pack(h.export_snapshot())).snapshot).ok,"STRONG history restores across rest using production entry rules")
 for live in [g,resumed]:
  live.state.room=rooms[4].id;live._start_battle()
 t.check(Save.same(g.state,resumed.state) and g.state.last_strong_group!=last,"STRONG saved history produces same next different recipe after rest")
 t.check(g.room_data(g.state.room).enemy_members.all(func(m):return m.type not in ["gag","lock"]),"STRONG weak members reuse occupied-mouth and no-unlocked-lockable-gear exclusion")
 var before=g.export_snapshot()
 for corrupt in ["missing_member","wrong_recipe","history"]:
  var bad=before.duplicate(true);var room=bad.rooms.filter(func(r):return r.id==bad.room)[0]
  if corrupt=="missing_member": room.enemy_members.pop_back()
  elif corrupt=="wrong_recipe": room.enemy_members=[{"type":"rope_mass","grade":2},{"type":"rope","grade":1}] if bad.room_encounters[room.id]=="four_weak" else [{"type":"rope","grade":1},{"type":"rope","grade":1},{"type":"rope","grade":1},{"type":"rope","grade":1}]
  else: bad.last_strong_group="missing"
  t.check(not g.restore_snapshot(bad).ok and g.state==before,"STRONG corrupt saved "+corrupt+" rejected atomically")

# Audit source permissions separately from factory behavior. Named action specs
# are narrowed only inside fixtures to force their real full-slot branch.
static func humanoid_equipment_audit(t) -> void:
 var R=preload("res://tests/replacement_cases.gd")
 var humans=Enemies.TYPES.keys().filter(func(id):return Enemies.TYPES[id].get("humanoid",false))
 for type in humans:
  var g=Game.new(42,true,"puppeteer_solo" if type=="puppet" else ("guard" if type=="guard" else type+"_solo"))
  if type=="six_bind": g=preload("res://tests/six_bind_cases.gd").encounter()
  if type=="iron_man":
   g=Game.new(42);g.state.room_encounters.entrance="iron_man_solo";g._start_battle()
  var actors=g.state.enemies.filter(func(enemy):return enemy.type==type)
  t.check(actors.size()==1,"HUMAN AUDIT real encounter contains registered actor: "+type)
  if actors.is_empty(): continue
  var e=actors[0]
  var before=g.export_snapshot()
  var plans=g.EnemyPlans.installation_intents(g,e)
  t.check(not plans.is_empty() and plans.all(func(plan):return plan.get("replace",false) and g.EnemyPlans.application_spec(g,e,plan).replace),"HUMAN AUDIT every declared installation retains replacement permission: "+type)
  t.check(g.export_snapshot()==before,"HUMAN AUDIT repertoire inspection is read-only: "+type)
  var ordinary=plans.filter(func(plan):return plan.pool=="ordinary" and "belt" in plan.templates)
  if ordinary.is_empty(): continue
  g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
  var existing=R.fill(g,"wrist",1,1)
  var outside=R.install(g,R.request("ankle",3,2)).duplicate(true)
  var plan=ordinary[0].duplicate(true)
  plan.count=1;plan.templates=["belt"];plan.required_slots=["wrist"];plan.allow_links=false;plan.shoulders=false
  g._enemy_operation(e,plan)
  t.check(existing.filter(func(item):return g._equipment(item.id).is_empty()).size()==1 and g.equipment_at("wrist").any(func(item):return item.grade==plan.grade and item.template=="belt"),"HUMAN AUDIT real operation replaces one weaker full-slot item: "+type)
  t.check(g._equipment(outside.id)==outside and g.state.logs.any(func(log):return not log.data.get("replaced",[]).is_empty()),"HUMAN AUDIT replacement reports actual removal and preserves unrelated equipment: "+type)
 # One occupied mouth slot still admits outer tape; fallback starts at full capacity.
 for grade in [1,2]:
  var g=preload("res://tests/six_bind_cases.gd").encounter(41)
  var mouth=R.install(g,R.request("mouth",3,2))
  var before=mouth.duplicate(true)
  g._six_area_sweep(g.state.enemies[0],grade,2)
  var pieces=g.equipment_at("mouth")
  var added=pieces.filter(func(item):return item.id!=mouth.id)
  t.check(pieces.size()==2 and added.size()==1 and added[0].template=="mouth_tape" and added[0].grade==grade and added[0].layer>mouth.layer and g._equipment(mouth.id)==before,"HUMAN AUDIT six-bind appends legal outer tape before tightening an occupied mouth at grade "+str(grade))
  g=preload("res://tests/six_bind_cases.gd").encounter(41)
  mouth=R.install(g,R.request("mouth",3,2));before=mouth.duplicate(true)
  var tape_request=R.request("mouth",3,2);tape_request.template="mouth_tape"
  var tape=R.install(g,tape_request);var tape_id=tape.id
  t.check(not tape.is_empty() and g.equipment_at("mouth").size()==2 and g.validate()=="","HUMAN AUDIT fallback fixture fills mouth capacity with stronger legal outer tape")
  g._six_area_sweep(g.state.enemies[0],grade,2)
  t.check(g.equipment_at("mouth").size()==2 and not g._equipment(tape_id).is_empty() and g.tier(g._equipment(tape_id).durability,g._equipment(tape_id).maximum)==3 and g._equipment(mouth.id)==before,"HUMAN AUDIT six-bind full mouth rejects weaker replacement and tightens only its exposed outer tape at grade "+str(grade))
 # Multi-target control uses the same tier-three locking + durability recovery.
 var g=Game.new(42,true,"versatile_solo")
 g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
 var ids=[]
 for slot in ["wrist","ankle"]:
  var request=R.request(slot,3,3);request.template="belt"
  var item=R.install(g,request);item.durability=item.maximum*0.9;g._refresh_equipment(item);ids.append(item.id)
 var e=g.state.enemies[0]
 var plan=g.EnemyPlans.batch(g,e,2,2,3,true,g.Enemies.TYPES[e.type].install_pool)
 g._enemy_operation(e,plan)
 t.check(ids.all(func(id):return g._equipment(id).locked and g._equipment(id).durability==g._equipment(id).maximum),"HUMAN AUDIT versatile two-item reinforcement locks and fully repairs both tier-three targets")
 var before=g.export_snapshot()
 g._enemy_operation(e,plan)
 t.check(g.state.equipment==before.equipment and g.state.rng.enemy==before.rng.enemy,"HUMAN AUDIT exhausted reinforcement does not replace equipment or consume target randomness")
