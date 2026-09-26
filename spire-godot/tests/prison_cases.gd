extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Guard=preload("res://core/guard.gd")
const Spatial=preload("res://tests/exploration_fixture.gd")
const B=preload("res://data/balance.gd")

static func intake(t, security: int=1):
 var g=Game.new(42,true,"guard")
 g.state.security=security-1
 Guard.capture(g,g.state.enemies[0])
 t.check(t.action(g,"prison",{"action":"enter"}).ok,"PRISON formal enter after actual capture")
 return g

static func clear_fixture(g) -> void:
 g.state.equipment=[]; g.state.composites=[]; g.state.links=[]
 g.state.prison.baseline=[]
 g.state.special_equipment=[];g.state.prison.special_baseline=[]

static func inspect(t,g) -> void:
 var left=g.state.prison.left
 for i in range(left): t.check(t.action(g,"end").ok,"PRISON timer spends a real completed player turn")
 t.check(g.state.phase=="inspection" and g.state.prison.stage=="arrival" and g.state.prison.left==0,"PRISON exact countdown reaches arrival without drawing another hand")

static func exit_to_route(t,g) -> void:
 Spatial.at_site(g,"door");g.state.prison.key=true
 t.action(g,"prison",{"action":"key"})
 t.check(t.action(g,"prison",{"action":"door_exit"}).ok,"PRISON formal door escape opens exterior route")

static func travel_route(t,g,target: String) -> void:
 t.check(t.action(g,"depart",{"room":target}).ok,"PRISON route departure "+target)
 while g.state.phase=="travel": t.check(t.action(g,"travel_step").ok,"PRISON route movement uses ordinary travel")

static func escape_route_cases(t) -> void:
 var Saves=preload("res://tests/persistence_cases.gd")
 for level in range(1,5):
  var g=intake(t,level);clear_fixture(g);g.state.posture="stand"
  # Older saves can contain a due-inspection line emitted during preparation.
  g.state.logs.append({"kind":"event","text":"历史检查结果。","round":1,"phase":"prepare","data":{"npc_copy":{"cue":"prison.guard.release_fail","visual":"guard_brown"}}})
  var original_seed=g.state.seed
  exit_to_route(t,g)
  t.check(g.get_view().npc_speech.is_empty(),"PRISON leaving the cell suppresses historical guard dialogue without deleting logs")
  t.check(g.state.rooms==g.Tower.prison_route(level) and g.state.map_region=="prison" and g.state.seed==original_seed and g.get_view().map_name=="监狱","PRISON exterior is a three-node fixed route and does not reseed early")
  var before=g.export_snapshot()
  var view=g.get_view();g.command_facts()
  t.check(g.state==before and preload("res://tests/architecture_cases.gd").shared(view,{"state":g.state})=="","PRISON route queries preserve state and expose no writable state containers")
  t.check(not t.action(g,"depart",{"room":"prison_gate"}).ok and g.state==before,"PRISON cannot skip rest point")
  if level==2:
   var saved=Saves.roundtrip(t,g,"prison route start")
   Saves.step_both(t,g,saved,"depart",{"room":"prison_rest"})
   saved=Saves.roundtrip(t,g,"prison route mid-travel")
   while g.state.phase=="travel": Saves.step_both(t,g,saved,"travel_step")
  else: travel_route(t,g,"prison_rest")
  t.check(g.state.phase=="rest_choice" and t.action(g,"rest_begin").ok and g.state.rest_left==6 and g.state.hook_uses==B.REST_HOOK_USES,"PRISON route reuses rest selection before six actual turns")
  t.action(g,"finish_rest")
  travel_route(t,g,"prison_gate")
  t.check(g.state.enemies.size()==level and g.state.enemies.all(func(e):return e.type=="guard" and e.hp==90) and g.room_data(g.state.room).requires_defeat,"PRISON final battle uses exactly the current security count of full-health guards")
  t.check(not g.Prison.reinforcements_active(g) and not g.get_view().statuses.any(func(row):return row.id=="prison_reinforcements"),"REINFORCEMENTS prison exit guards have no field countdown")
  if level==2:
   var stable=g.export_snapshot();var invalid=stable.duplicate(true)
   invalid.rooms[-1].encounter_repeats=1
   t.check(not g.restore_snapshot(invalid).ok and g.export_snapshot()==stable,"PRISON snapshot rejects a changed guard count atomically")
   Saves.roundtrip(t,g,"prison exit battle")
  var reward_before=g.state.reward_count
  # Only shorten health; real attacks, action costs and group-victory detection run.
  for enemy in g.state.enemies: enemy.hp=1.0
  while g.state.phase=="battle":
   var attack=preload("res://tests/route_driver.gd").attack(g)
   if attack.is_empty(): t.action(g,"end")
   else: t.check(g.dispatch(g.command(attack.payload,g.state.version),g.state.version).ok,"PRISON route guard defeated with formal attack")
  t.check(g.state.phase=="reward" and g.state.reward_count==reward_before+1 and g.state.seed==original_seed,"PRISON all guards yield one reward and wait before new seed")
  t.check(g.get_view().npc_speech.is_empty(),"PRISON exit-guard victory cannot replay a former cell inspection")
  t.check(g.state.reward_options.size()==3 and g.state.reward_options.all(func(type):return g.Cards.Rules.SPECS[type].rarity=="rare") and g.state.battle_relic_drop!="" and g.state.battle_flask_drop==60,"PRISON guard has rare three-choice, relic and flask rewards")
  var flask_before=g.state.flask_mana
  t.check(t.action(g,"reward",{"category":"flask","type":"boss_mana"}).ok and g.state.flask_mana==flask_before+60,"PRISON claim sixty flask mana")
  var after_flask=g.export_snapshot()
  t.check(not t.action(g,"reward",{"category":"flask","type":"boss_mana"}).ok and after_flask==g.state,"PRISON flask cannot be claimed twice")
  var equipment=g.state.equipment.duplicate(true);var special=g.state.special_equipment.duplicate(true)
  var relics=g.state.relics.duplicate();var mana=g.state.mana;var pressure=g.state.pressure
  var deck_count=g.state.deck.size();var slot=g.state.save_slot
  var drop_chance=g.state.item_drop_chance
  if level==1:
   while g.state.items.size()<=g.item_capacity(): g._gain_tool("shard")
  var pick=t.find_action(g,"reward",{"type":g.state.reward_options[0]})
  var saved=Saves.roundtrip(t,g,"prison exit reward") if level==2 else null
  if saved!=null: Saves.step_both(t,g,saved,"reward",pick.payload)
  else: t.check(g.dispatch(g.command(pick.payload,g.state.version),g.state.version).ok,"PRISON final reward claimed")
  if saved!=null: Saves.step_both(t,g,saved,"reward",{"type":"skip"})
  else: t.check(t.action(g,"reward",{"type":"skip"}).ok,"PRISON continue after final reward")
  if level==1:
   t.check(g.state.phase=="pack" and g.state.seed==original_seed,"PRISON excess inventory is sorted before reseeding")
   while g.carried_items()>g.item_capacity(): t.action(g,"item_discard",{"item":g.state.items[0].id})
   t.action(g,"finish_pack")
  t.check(g.state.phase=="map" and g.state.room=="tower_bottom" and g.state.map_region=="tower" and g.state.seed!=original_seed and g.state.tower_generation==1,"PRISON rewarded victory returns directly to a genuinely new seeded tower")
  t.check(g.get_view().npc_speech.is_empty() and g.state.logs.any(func(log):return log.data.get("npc_copy",{}).get("cue","")=="prison.guard.release_fail"),"PRISON tower return hides the old warning while preserving its history")
  t.check(g.state.rooms.filter(func(room):return room.has("encounter_choices")).all(func(room):return room.pool=="strong"),"PRISON guard victory makes every ordinary encounter strong")
  t.check(g.state.item_drop_chance==drop_chance and g.state.rng.size()==g.B.RNG_SALTS.size() and g.state.rng.values().all(func(value):return value==0),"PRISON same-act reseeding preserves drop chance and resets every registered random domain")
  t.check(g.state.deck.size()==deck_count+1 and g.state.equipment==equipment and g.state.special_equipment==special and g.state.relics==relics and g.state.mana==minf(g.state.mana_max,mana+10) and g.state.pressure==pressure and g.state.security==level and g.state.save_slot==slot,"PRISON exit reward closes battle once, preserving character and save ownership")
  t.check(g.state.completed_rooms.is_empty() and g.state.traversed_edges.is_empty() and g.state.journey.is_empty() and g.state.last_strong_group=="" and g.state.travel_turns==0 and g.validate()=="","PRISON fresh tower clears route progress and strong-pool history")
  before=g.export_snapshot()
  t.check(not g.dispatch(g.command(pick.payload,pick.version if pick.has("version") else 1),pick.version if pick.has("version") else 1).ok and g.state==before,"PRISON repeated reward cannot reseed or grant another card")
  if saved!=null: t.check(g.state.seed==saved.state.seed and g.state.rooms==saved.state.rooms,"PRISON restored reward produces the same new tower")
  Saves.roundtrip(t,g,"new tower after prison")
 # Losing the exterior battle re-enters the ordinary capture loop at higher security.
 var g=intake(t);clear_fixture(g);g.state.posture="stand";exit_to_route(t,g)
 travel_route(t,g,"prison_rest");t.action(g,"rest_begin");t.action(g,"finish_rest");travel_route(t,g,"prison_gate")
 var reward_before=g.state.reward_count
 g.state.guard_bind={"progress":100.0,"sources":{"guard":{"enemy":g.state.enemies[0].id,"energy":0}}}
 g.state.enemies[0].intent={"kind":"capture","text":"执行收押","delayed":false}
 t.action(g,"end")
 t.check(g.state.phase=="captured" and g.state.security==2 and g.state.reward_count==reward_before and g.validate()=="","PRISON route defeat recaptures once with no reward")
 t.action(g,"prison",{"action":"enter"});clear_fixture(g);exit_to_route(t,g)
 t.check(g.state.rooms==g.Tower.prison_route(2) and g.validate()=="","PRISON next escape rebuilds route with the increased guard count")

static func run(t) -> void:
 cup_stack_migration(t)
 preload("res://tests/prison_reinforcement_cases.gd").run(t)
 inspection_climax_cases(t)
 sentence_cases(t)
 battle_pause_cases(t)
 security_health_cases(t)
 for security in [0,4]:
  var surrender_game=Game.new(42)
  surrender_game.state.security=security;surrender_game.state.mana=37
  surrender_game._gain_tool("return_seal")
  var retained_seal=surrender_game.state.items[0].duplicate(true)
  surrender_game._gain_tool("shard")
  var candidate=t.find_action(surrender_game,"surrender")
  var before_surrender=surrender_game.export_snapshot()
  t.check(not surrender_game.dispatch(surrender_game.command(candidate.payload,surrender_game.state.version-1),surrender_game.state.version-1).ok and surrender_game.state==before_surrender,"SURRENDER stale confirmation changes nothing")
  t.check(surrender_game.dispatch(surrender_game.command(candidate.payload,surrender_game.state.version),surrender_game.state.version).ok,"SURRENDER formal candidate commits capture and intake")
  t.check(surrender_game.state.phase=="captured" and surrender_game.state.security==security+1 and surrender_game.state.items==[retained_seal],"SURRENDER reaches the same one-time intake page while preserving the original seal")
  t.check(surrender_game.state.capture.confiscated==1,"SEAL intake count includes only confiscated ordinary tools")
  var retained_save=Game.new(77)
  t.check(retained_save.restore_snapshot(surrender_game.export_snapshot()).ok and retained_save.state.items==[retained_seal],"SEAL prison snapshot preserves identity and remaining uses without duplication")
  t.check(surrender_game.restart_snapshot()==surrender_game.state and not surrender_game.command_facts().any(func(c):return c.payload.kind=="surrender"),"SURRENDER checkpoints intake and cannot repeat outside battle")
  t.check(t.action(surrender_game,"prison",{"action":"enter"}).ok and surrender_game.state.phase=="prison" and surrender_game.state.prison.left==B.PRISON_INTERVALS[surrender_game.state.security-1],"SURRENDER intake page uses the formal prison entry action at every security")
 var fresh=preload("res://core/game.gd").new(42)
 t.check(fresh.state.items.size()==1 and fresh.state.items[0].type=="return_seal" and fresh.state.items[0].uses==1,"SEAL normal new game carries one single-use teleport scroll")
 t.check(fresh.get_view().items[0].name=="传送符" and fresh.get_view().items[0].category=="卷轴","SEAL initial inventory uses renamed scroll presentation")
 t.check(fresh.Tools.description(fresh,"return_seal").contains("进入监狱时不会丢失。") and not fresh.Tools.description(fresh,"shard").contains("进入监狱时不会丢失。"),"SEAL shared item description exposes intake protection only for the seal")
 var restored=preload("res://core/game.gd").new(77)
 t.check(restored.restore_snapshot(fresh.restart_snapshot()).ok and restored.state.items.size()==1,"SEAL scene restore never duplicates initial scroll")
 patrol_period_cases(t)
 escape_route_cases(t)
 security_cases(t)
 intake_floor_cases(t)
 collar_cases(t)
 toy_inspection_cases(t)
 practice_cases(t)

 remaining_routes(t)
 var g=intake(t)
 t.check(g.state.phase=="prison" and g.state.energy==3 and g.state.hand.size()==5 and g.state.prison.left==16 and g.validate()=="","PRISON entry uses normal deck/resource boundary and actual cell")
 var before=JSON.stringify(g.state)
 var view=g.get_view(); view.prison.found.append("vent")
 t.check(JSON.stringify(g.state)==before and not "vent" in g.state.prison.found,"PRISON readonly projection does not expose discovered pool order or aliases")
 t.check(not view.prison.has("discoveries"),"PRISON hidden discovery order is not projected")
 var twin=intake(t)
 t.check(g.state.prison.discoveries==twin.state.prison.discoveries,"PRISON independent discovery shuffle is seed-reproducible")
 var old_rng=g.state.rng.duplicate(true)
 clear_fixture(g)
 Spatial.collect(t,g)
 t.check(g.state.prison.found.size()==3 and g.state.items.size()==2 and g.state.prison.discoveries.is_empty(),"PRISON finite arrival gives each tool once")
 t.check(g.state.rng==old_rng,"PRISON free legs use no fall or slip randomness; layout stays frozen")
 before=JSON.stringify(g.state)
 var here=g.state.prison.space.sites.filter(func(site):return site.position==g.state.prison.space.position)[0]
 t.check(not t.action(g,"prison",{"action":"explore","site":here.id}).ok and JSON.stringify(g.state)==before,"PRISON same-site repeat cannot farm tools or energy")
 var glove=g._install_assembly("glove","short","fixture",2,2)
 t.check(t.find_action(g,"prison",{"action":"explore"}).cost==g.wall_movement_profile().cost,"PRISON arm restrictions use shared wall movement fee")
 g.state.composites=[]
 g._install_template("rope","wrist",4,10,false,"fixture")
 t.check(t.find_action(g,"prison",{"action":"explore"}).cost==g.wall_movement_profile().cost,"PRISON wrist restrictions use shared wall movement fee")
 g._install_assembly("leg","toes","fixture")
 t.check(t.find_action(g,"prison",{"action":"explore"}).cost==g.wall_movement_profile().cost,"PRISON leg restriction fee matches wall movement")

 # Clean inspection preserves damage and carried tools, but exposed installed tools are confiscated.
 g=intake(t); clear_fixture(g)
 var belt=g._install_template("belt","ankle",2,10,true,"fixture")
 g.state.prison.baseline=[belt.id]
 g._gain_tool("shard"); g._gain_tool("saw"); g.state.items[1].mount="foot_wall";g.state.items[1].prison_position=g.state.prison.space.position.duplicate()
 var exhausted=g.state.hand.pop_back(); g.state.exhaust.append(exhausted)
 var energy=g.state.energy; var mana=g.state.mana
 inspect(t,g)
 t.check(g.state.exhaust.size()==1 and g.state.hand.is_empty() and g.state.mana==mana,"PRISON arrival does not restore exhaust or magic or begin a free turn")
 t.check(g.command_facts().filter(func(c):return c.payload.kind not in ["flask","item_discard"]).size()==2 and g.command_facts().all(func(c):return c.payload.kind in ["prison","flask","item_discard"]),"PRISON inspection closes ordinary tools, posture and cards; personal flask remains available")
 t.action(g,"prison",{"action":"inspect"})
 t.check(g.state.prison.missing.is_empty() and g.state.exhaust.size()==1,"PRISON lower durability alone is not a missing item and result does not restore exhaust")
 t.action(g,"prison",{"action":"accept"})
 t.check(g._equipment(belt.id).durability==2 and g._equipment(belt.id).locked and g.state.prison.checks==1,"PRISON clean check does not repair or unlock worn equipment")
 t.check(g.state.items.size()==1 and g.state.items[0].type=="shard" and g.state.exhaust.is_empty() and g.state.discard.any(func(c):return c.uid==exhausted.uid),"PRISON complete check confiscates exposed wall tool and restores each exhausted card to discard")
 before=JSON.stringify(g.state)
 t.check(not t.action(g,"prison",{"action":"accept"}).ok and JSON.stringify(g.state)==before,"PRISON cannot accept punishment or restore cards twice")
 t.action(g,"prison",{"action":"resume"})
 t.check(g.state.phase=="prison" and g.state.prison.left==16 and g.state.hand.size()==5 and g.state.energy==energy,"PRISON next segment starts one fresh player turn")

 # Missing an actual component causes one atomic punishment, while vent progress is preserved.
 g=intake(t,2); clear_fixture(g)
 glove=g._install_assembly("glove","short","fixture",2,2)
 var body=g._composite_body(glove)
 g.state.prison.baseline=g.equipment_targets().map(func(e):return e.id)
 var shoulder=glove.components.filter(func(e):return e.part=="left")[0]
 shoulder.durability=0; g._cleanup()
 g._gain_tool("shard");g._gain_tool("saw")
 Spatial.mark_found(g,"vent");g.state.prison.vent_hits=1
 inspect(t,g)
 t.action(g,"prison",{"action":"inspect"})
 t.check(g.state.prison.missing==[shoulder.id],"PRISON checks physical component identity, not just root count")
 var count=g.state.equipment.size()
 t.action(g,"prison",{"action":"accept"})
 var additions=g.state.equipment.filter(func(e):return e.source=="prison")
 t.check(g._equipment(body.id).durability==body.maximum and g.state.equipment.size()==count+3 and g.state.items.is_empty(),"PRISON one missing component adds three ordinary pieces and confiscates all tools")
 t.check(additions.size()==3 and additions.all(func(e):return e.grade==2 and g.tier(e.durability,e.maximum)==2),"PRISON security two punishment applies medium tier-two ordinary roots")
 t.check(g.state.security==2 and g.state.prison.vent_hits==1 and g.state.prison.baseline==g.equipment_targets().map(func(e):return e.id) and g.validate()=="","PRISON punishment does not increment security or reset vent, and updates actual baseline")
 punishment_cases(t)

 # The three public inspection nodes can each start resistance without hidden restoration.
 for node in ["arrival","result","done"]:
  g=intake(t); clear_fixture(g)
  var card=g.state.hand.pop_back();g.state.exhaust.append(card)
  inspect(t,g)
  if node!="arrival": t.action(g,"prison",{"action":"inspect"})
  if node=="done": t.action(g,"prison",{"action":"accept"})
  var old_tick=g.state.tick
  g.state.posture="stand" # Reward-flow fixture starts player-first, before the guard can equip anything.
  t.check(t.action(g,"prison",{"action":"resist"}).ok and g.state.phase=="battle" and g.state.prison.resisting,"PRISON resistance starts at "+node)
  t.check(g.state.exhaust.size()==(0 if node=="done" else 1) and g.state.tick==old_tick+1 and g.state.prison.left==0,"PRISON resistance pauses timer and preserves exhaust at "+node)
  g.state.posture="stand";g.state.enemies[0].hp=1
  t.action(g,"attack",{"type":"strike","enemy":g.state.enemies[0].id})
  t.check(g.state.phase=="reward" and g.state.prison.key and not g.state.prison.resisting and g.state.reward_count==1,"PRISON resistance victory awards special key and one normal reward")
  t.action(g,"reward",{"type":"skip"})
  t.action(g,"finish_prepare")
  t.check(g.state.phase=="prison" and g.state.prison.key and g.state.prison.left==0,"PRISON preparation returns to cell with patrol paused")
  t.action(g,"end")
  t.check(g.state.phase=="prison" and g.state.prison.left==0,"PRISON defeated patrol never restarts inspections during escape preparation")
  Spatial.at_site(g,"door")
  t.action(g,"prison",{"action":"key"})
  g.state.posture="lie"
  t.check(t.action(g,"prison",{"action":"door_exit"}).ok and g.state.room=="prison_start" and g.state.phase=="map","PRISON key route reaches independent route without a standing gate")

 g=intake(t); inspect(t,g)
 t.action(g,"prison",{"action":"resist"})
 var e=g.state.enemies[0];g.state.guard_bind={"progress":100.0,"sources":{"guard":{"enemy":e.id,"energy":0}}};e.intent={"kind":"capture","text":"收押","delayed":false}
 var original_ids=g.equipment_targets().map(func(x):return x.id)
 t.action(g,"end")
 t.check(g.state.phase=="captured" and g.state.security==2 and g.state.prison.is_empty() and original_ids.all(func(id):return not g._equipment(id).is_empty()),"PRISON failed resistance preserves gear and increases security exactly once")
 t.action(g,"prison",{"action":"enter"})
 t.check(g.state.prison.left==14 and g.state.exhaust.is_empty() and g.state.prison.found.is_empty(),"PRISON reentry resets finite discoveries and restores permanent deck at higher security")

 # Door unlocking consumes the same actual card/reserves; speed is rechecked at exit.
 g=intake(t); clear_fixture(g);Spatial.at_site(g,"door");g.state.posture="stand"
 var card=t.grant_fixture_card(g,"unlock")
 g.state.temporary_mana=5;g.state.pressure=70;g.state.energy=0
 var c=t.find_action(g,"prison",{"action":"unlock"})
 t.check(c.valid and c.cost==0 and c.mana==B.SPELL_COST and c.mana_payment.temporary_mana==5,"PRISON high-pressure door card uses base mana and original temporary reserve payment")
 energy=g.state.energy;mana=g.state.mana
 # Deterministic success fixture; the spell still uses the formal random gate.
 for counter in range(10000):
  var cast_rng=RandomNumberGenerator.new()
  cast_rng.seed=int(g.state.seed)+g.B.RNG_SALTS.magic+counter*104729
  if cast_rng.randi_range(0,g.B.CAST_ROLL_STEPS-1)<3600:
   g.state.rng.magic=counter
   break
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.prison.door_open and g.state.energy==energy and g.state.mana==mana-c.mana_payment.mana and g.state.temporary_mana==0,"PRISON door unlock consumes reserves magic and one real hand card without energy")
 t.check(g.state.discard.any(func(x):return x.uid==card.uid) and not g.state.hand.any(func(x):return x.uid==card.uid),"PRISON door card remains in permanent deck and goes to discard")
 # The following posture/exit scenario needs its own movement energy.
 g.state.energy=2
 var exit_candidate=t.find_action(g,"prison",{"action":"door_exit"})
 var version=g.state.version
 g.state.energy=3 # Door casting above proves zero-energy use; posture checks need their own energy.
 t.action(g,"posture",{"dest":"sit","wall":false})
 before=JSON.stringify(g.state)
 t.check(not t.find_action(g,"prison",{"action":"door_exit"}).valid and not g.dispatch(g.command(exit_candidate.payload,version),version).ok and JSON.stringify(g.state)==before,"PRISON changed posture invalidates stale exit; sitting speed cannot bypass door threshold")
 t.action(g,"posture",{"dest":"stand","wall":false})
 var old_route=JSON.stringify(g.state.rooms)
 g.state.charge=2;g.state.next_energy=1;g.state.mana=51;g.state.pressure=37
 g._gain_tool("shard");g._gain_tool("saw");g.state.items[1].mount="hand_wall";g.state.items[1].prison_position=g.state.prison.space.position.duplicate()
 var original_deck=JSON.stringify(g.state.deck)
 t.check(t.action(g,"prison",{"action":"door_exit"}).ok,"PRISON standing with open door escapes")
 t.check(g.state.phase=="map" and g.state.room=="prison_start" and not g.state.practice and g.state.tower_generation==0 and old_route!=JSON.stringify(g.state.rooms),"PRISON escape opens prison route without prematurely reseeding tower")
 t.check(g.state.mana==61 and g.state.pressure==37 and g.state.security==1 and g.state.charge==2 and g.state.next_energy==1 and JSON.stringify(g.state.deck)==original_deck,"PRISON escape retains prison-earned charge up to the cap while preserving safety, deck and other cross-battle buffs")
 t.check(g.state.items.size()==1 and g.state.items[0].type=="shard" and g.state.completed_rooms.is_empty() and g.state.traversed_edges.is_empty() and g.validate()=="","PRISON escape leaves wall tools and old route history behind")
 t.check(t.action(g,"depart",{"room":"prison_rest"}).ok,"PRISON exit route accepts its adjacent rest point")
 while g.state.phase=="travel": t.action(g,"travel_step")
 t.check(t.action(g,"rest_begin").ok and g.state.phase=="rest" and g.state.security==1 and g.state.energy==4 and g.state.next_energy==0,"PRISON selected rest consumes saved next-turn energy once")

 # Vent uses the same legal seated kick profile, one hit per player turn.
 g=intake(t);clear_fixture(g)
 before=JSON.stringify(g.state)
 t.check(not t.action(g,"prison",{"action":"vent_kick"}).ok and JSON.stringify(g.state)==before,"PRISON unseen vent cannot be kicked")
 Spatial.collect(t,g);Spatial.at_site(g,"vent");g.state.posture="stand"
 t.check(not t.find_action(g,"prison",{"action":"vent_kick"}).valid,"PRISON standing cannot reach vent with required seated kick")
 g._install_template("rope","ankle",4,10,false,"fixture")
 t.action(g,"posture",{"dest":"sit","wall":false})
 t.action(g,"end")
 g.state.charge=1
 for i in range(3):
  t.check(t.action(g,"prison",{"action":"vent_kick"}).ok,"PRISON bound seated legs can kick vent")
  t.check(g.state.prison.vent_hits==i+1 and not t.find_action(g,"prison",{"action":"vent_kick"}).valid,"PRISON each hit records exact progress and cannot repeat same turn")
  if i<2: t.action(g,"end")
 t.check(g.state.charge==0 and g.state.posture=="sit","PRISON environmental kick consumes applicable charge once without inventing posture change")
 g._gain_tool("shard");g._gain_tool("saw")
 t.check(not t.find_action(g,"prison",{"action":"vent_exit"}).valid,"PRISON escape requires excess carried tools to be dealt with")
 while g.carried_items()>g.item_capacity(): t.check(t.action(g,"item_discard",{"item":g.state.items[0].id}).ok,"PRISON drops each excess item before vent exit")
 t.check(t.action(g,"prison",{"action":"vent_exit"}).ok and g.state.posture=="sit" and g.state.room=="prison_start","PRISON opened vent enters prison route without standing gate")

 g=intake(t);clear_fixture(g)
 g.state.prison.left=1;g.state.pressure=90
 g.state.pressure_sources=[{"id":"clock_fixture","name":"牢房干扰","timing":"turn_end","amount":20.0,"room":"prison","equipment":""}]
 t.action(g,"end")
 t.check(g.state.phase=="inspection" and g.state.overload_energy==1 and not g.state.overloaded and g.validate()=="","PRISON overload on final turn reaches inspection once and preserves next-turn penalty")
 t.action(g,"prison",{"action":"inspect"});t.action(g,"prison",{"action":"accept"});t.action(g,"prison",{"action":"resume"})
 t.check(g.state.energy==2 and g.state.overload_energy==0,"PRISON next segment applies pending overload once")
 g.state.pressure=95;g.state.pressure_sources[0].timing="strain"
 var rope=g._install_template("rope","wrist",10,10,false,"fixture")
 card=t.hand_card(g,"strain")
 t.action(g,"card",{"uid":card.uid,"slot":"wrist","target":rope.id})
 var overload_actions=g.command_facts().filter(func(c):return c.payload.kind not in ["flask","item_discard"])
 t.check(g.state.overloaded and overload_actions.size()==1 and overload_actions[0].payload.kind=="end","PRISON mid-turn overload closes exploration, ordinary tools and escapes")

 g=intake(t,5)
 t.check(g.state.phase=="prison" and g.state.prison.left==B.PRISON_INTERVALS[4] and g.state.posture=="lie" and g.command_facts().any(func(c):return c.payload.kind=="prison" and c.payload.action in ["vent_kick","door_exit","key"]) and g.validate()=="","PRISON safety five enters an ordinary cell with patrol and escape facts instead of a terminal")
 for safety in [3,4,5]:
  g=intake(t,safety)
  t.check(g.state.prison.left==B.PRISON_INTERVALS[safety-1],"PRISON higher security retains its shorter inspection interval")
 g=intake(t);clear_fixture(g)
 card=t.grant_fixture_card(g,"unlock")
 var fingers=g._install_template("cord","fingers",4,10,false,"fixture")
 t.check(not fingers.is_empty() and g.occupied("fingers"),"PRISON gesture fixture uses legal fine restraint")
 before=JSON.stringify(g.state)
 t.check(not t.action(g,"prison",{"action":"unlock"}).ok and JSON.stringify(g.state)==before,"PRISON door magic requires actual hand gestures and blocked use spends nothing")
 # Resistance preparation must retain the ordinary capacity gate, including a non-practice run.
 g=intake(t);clear_fixture(g);g.state.practice=false
 inspect(t,g);g.state.posture="stand";t.action(g,"prison",{"action":"resist"})
 g.state.posture="stand";g.state.enemies[0].hp=1
 t.action(g,"attack",{"type":"strike","enemy":g.state.enemies[0].id})
 t.action(g,"reward",{"type":"skip"})
 for i in range(4): g._gain_tool("shard")
 t.action(g,"finish_prepare")
 t.check(g.state.phase=="pack" and g.state.prison.key and g.get_view().route.is_empty(),"PRISON resistance preparation uses capacity packing before resuming cell even outside practice")
 while g.carried_items()>g.item_capacity():
  t.check(t.action(g,"item_discard",{"item":g.state.items.filter(func(item):return item.mount=="carry")[0].id}).ok,"PRISON discards all excess items including actual battle drops")
 t.check(t.action(g,"finish_pack").ok and g.state.phase=="prison" and g.state.prison.key,"PRISON valid packed inventory resumes cell instead of routing through old tower room")
 g=intake(t);g.state.prison.discoveries.append(g.state.prison.discoveries[0])
 before=JSON.stringify(g.state)
 t.check(not t.action(g,"end").ok and JSON.stringify(g.state)==before,"PRISON invalid discovery state rolls back timer, card zones, resources and logs")

static func remaining_routes(t) -> void:
 var g=Game.new(42,true,"guard")
 g.state.security=4
 g._install_assembly("glove","long","fixture",3,3)
 g._install_assembly("leg","toes","fixture",3,3)
 g._install_template("mouth_band","mouth",8,10,true,"fixture")
 var preserved=g.physical_pieces().duplicate(true)
 Guard.capture(g,g.state.enemies[0])
 t.check(g.state.phase=="captured" and not g.state.composites.any(func(r):return r.kind=="security"),"TERMINAL intake first shows retained equipment without premature fixture")
 t.check(g.state.security==5 and t.find_action(g,"prison",{"action":"enter"}).label=="进入牢房" and not g.state.capture.has("terminal_equipment"),"TERMINAL five keeps the ordinary intake label and writes no removed terminal manifest")
 var entered=t.action(g,"prison",{"action":"enter"})
 t.check(entered.ok and g.state.phase=="prison" and g.state.prison.left==B.PRISON_INTERVALS[4] and g.state.prison.turn==1,"TERMINAL formal entry starts the ordinary top-spec cell: "+entered.get("error",""))
 t.check(preserved.all(func(e):return g._equipment(e.id).template==e.template) and g.occupied("mouth"),"TERMINAL prior closed structures retained instead of being rebuilt")
 var added=(g.state.equipment+g.state.composites).filter(func(e):return e.id in g.state.capture.added)
 t.check(added.size()==B.CAPTURE_EXTRA_BASE+5 and added.all(func(e):return (e.grade==3 if not e.has("components") else e.components.all(func(c):return c.grade==3))),"TERMINAL five fills the ordinary quota at the PRISON_SECURITY[5] grade")
 t.check(added.all(func(e):return (g.tier(e.durability,e.maximum)==3 if not e.has("components") else e.components.all(func(c):return g.tier(c.durability,c.maximum)==3))),"TERMINAL five installs its quota at the top tightness instead of tightening old gear")
 t.check(g.state.special_equipment.size()==2 and g.state.special_equipment.all(func(e):return e.grade==3 and g.tier(e.durability,e.maximum)==3),"TERMINAL five adds two high-grade three-tier toys")
 t.check(g.state.equipment.filter(func(e):return g.Equipment.lock_only(e)).size()==1,"TERMINAL five keeps exactly the locked restriction collar")
 t.check(g.validate()=="","TERMINAL ordinary capacity and closure rules still valid")
 t.check(t.action(g,"end").ok and g.state.phase in ["prison","inspection"] and g.validate()=="","TERMINAL ordinary completed turns stay inside the cell loop")
 # A clean fixture isolates the entry path from the composite fixture's intake overload.
 var clean=intake(t,5);clear_fixture(clean)
 var lower=intake(t,4);clear_fixture(lower)
 t.check(clean.state.phase=="prison" and clean.state.prison.left==B.PRISON_INTERVALS[4] and clean.state.posture=="lie" and lower.state.posture=="lie" and clean.state.room==lower.state.room and clean.room_data("prison").name==lower.room_data("prison").name,"TERMINAL five enters the same cell scene and entry path as one to four")
 t.check(clean.command_facts().any(func(c):return c.payload.kind=="prison" and c.payload.action=="vent_kick") and clean.command_facts().any(func(c):return c.payload.kind=="prison" and c.payload.action=="door_exit"),"TERMINAL five exposes the shared patrol and escape facts instead of a terminal list")
 var legacy=g.export_snapshot()
 legacy.capture.terminal_equipment=g.equipment_targets().map(func(e):return e.id)
 var restored=Game.new(1)
 t.check(restored.restore_snapshot(legacy).ok and not restored.state.capture.has("terminal_equipment") and restored.state.phase=="prison","TERMINAL legacy manifest is accepted and dropped on load without touching the cell")
 t.check(t.action(restored,"end").ok and restored.state.phase in ["prison","inspection"] and restored.validate()=="","TERMINAL loaded legacy save still runs the ordinary prison pipeline")
 for seed_value in range(8):
  g=Game.new(seed_value,true,"guard");g.state.security=4
  Guard.capture(g,g.state.enemies[0])
  t.check(t.action(g,"prison",{"action":"enter"}).ok and g.state.phase=="prison" and g.validate()=="" and g.state.prison.left==B.PRISON_INTERVALS[4] and not g.state.capture.has("terminal_equipment"),"TERMINAL five enters the ordinary cell across intake seeds")

 for pose in ["stand","sit","lie"]:
  g=intake(t);clear_fixture(g)
  Spatial.collect(t,g)
  t.check(not g.state.items.any(func(i):return i.type=="return_seal"),"SEAL absent from active discovery generation")
  g._gain_tool("return_seal") # Existing/deferred item fixture, not a generation source.
  var seal=g.state.items.filter(func(i):return i.type=="return_seal")[0]
  g.state.posture=pose;g.state.energy=0;g.state.mana=37;g.state.pressure=41
  var equipment=g.state.equipment.duplicate(true)
  var candidate=t.find_action(g,"item_use",{"item":seal.id,"target":"hero"})
  t.check(candidate.valid and candidate.cost==0 and candidate.mana==0,"SEAL any posture zero-resource use under actual body rules")
  var version=g.state.version
  t.check(g.dispatch(g.command(candidate.payload,version),version).ok and g.state.room=="prison_start" and g.state.phase=="map","SEAL formal use leaves cell but still requires the prison route")
  t.check(g.state.mana==47 and g.state.pressure==41 and g.state.equipment==equipment and g.state.items.size()==2 and g._item(seal.id).is_empty() and g.state.save_slot=="practice","SEAL consumes itself, triggers special-battle end healing and preserves other resources/items/save origin")
  var before=g.state.duplicate(true)
  t.check(not g.dispatch(g.command(candidate.payload,version),version).ok and g.state==before,"SEAL stale repeated use cannot repeat escape or tower generation")
 g=intake(t);clear_fixture(g)
 g._gain_tool("return_seal")
 var seal=g.state.items[0]
 g._install_assembly("wrap","left","fixture",1,1)
 t.check(t.find_action(g,"item_use",{"item":seal.id}).valid,"SEAL one free hand is sufficient")
 g._install_assembly("wrap","right","fixture",1,1)
 t.check(t.find_action(g,"item_use",{"item":seal.id}).valid,"SEAL scroll allows free toes with both hands blocked")
 g.add_fixture("toes",8)
 var before=g.state.duplicate(true)
 t.check(not t.action(g,"item_use",{"item":seal.id}).ok and g.state==before,"SEAL blocked fingers and toes spend no item or resources")
 clear_fixture(g)
 for i in range(4): g._gain_tool("shard")
 t.check(not t.find_action(g,"item_use",{"item":seal.id}).valid,"SEAL remaining inventory over capacity blocks escape")
 t.action(g,"item_discard",{"item":g.state.items[-1].id})
 t.check(g.carried_items()==4 and t.find_action(g,"item_use",{"item":seal.id}).valid,"SEAL capacity checked after consuming its own slot")
 g.Pressure.gain(g,100,"测试干扰")
 t.check(not t.action(g,"item_use",{"item":seal.id}).ok and g._item(seal.id).uses==1,"SEAL no zero-cost overload bypass")
 g=intake(t);clear_fixture(g);g._gain_tool("return_seal")
 seal=g.state.items[0]
 inspect(t,g)
 t.check(not t.action(g,"item_use",{"item":seal.id}).ok and g._item(seal.id).uses==1,"SEAL inspection blocks item use")
 t.action(g,"prison",{"action":"inspect"});t.action(g,"prison",{"action":"accept"})
 t.check(not g._item(seal.id).is_empty(),"SEAL compliant inspection preserves carried seal")
 t.action(g,"prison",{"action":"resist"})
 t.check(not t.find_action(g,"item_use",{"item":seal.id}).valid,"SEAL resistance battle cannot use prison-only exit")
 Guard.capture(g,g.state.enemies[0])
 t.check(g._item(seal.id)==seal and g._item(seal.id).uses==1,"SEAL recapture preserves the existing seal and its remaining use")

static func security_cases(t) -> void:
 var expected=[[1,2],[2,2],[2,3],[3,2],[3,3]]
 var handbook=preload("res://data/tutorial.gd").entries().filter(func(row):return row.id=="prison_security")[0]
 for level in range(1,6):
  var g=Game.new(42,true,"guard")
  g.state.equipment=[];g.state.composites=[];g.state.links=[]
  g.state.security=level-1
  Guard.capture(g,g.state.enemies[0])
  var grade=expected[level-1][0];var tier=expected[level-1][1]
  t.check(handbook.category=="prison" and handbook.text.contains("%d级：%s，%d档，%s。" % [level,g.Equipment.GRADES[grade],tier,"普通或复合" if level>=3 else "仅普通"]),"PRISON handbook explains the actual security equipment table")
  var roots=(g.state.equipment+g.state.composites).filter(func(e):return e.id in g.state.capture.added)
  var intake_quota=B.PRISON_INTAKE[level].floor+B.PRISON_INTAKE[level].extra if level<5 else level+B.CAPTURE_EXTRA_BASE
  t.check(roots.size()==intake_quota and g.state.capture.baseline==g.equipment_targets().map(func(e):return e.id),"PRISON security %d counts roots for intake and physical components for registration" % level)
  t.check(g.equipment_targets().filter(func(e):return not g.Equipment.lock_only(e)).all(func(e):return e.grade==grade and g.tier(e.durability,e.maximum)==(tier if e.template=="link_rope" else (maxi(2,grade) if g.Equipment.is_shoulder(e) and level<5 else (2 if level<5 else (grade if g.Equipment.is_shoulder(e) else tier))))),"PRISON intake uses tier two independently from inspection and link profiles")
  t.check(g.state.equipment.filter(func(e):return g.Equipment.lock_only(e)).size()==(1 if level>=3 else 0),"PRISON restriction collar starts exactly at security three")
  t.check(level>=3 or g.state.composites.is_empty(),"PRISON below security three excludes even basic composite wraps")
  var toy_pool=g.SpecialEquipment.prison_pool(grade,level>=3)
  var crotch_rope="crotch_rope_"+["","low","medium","high"][grade]
  t.check(crotch_rope in toy_pool and toy_pool.all(func(type):return g.SpecialEquipment.DESIGNS[type].grade==grade),"PRISON security %d toy pool keeps crotch ropes and uses the current grade" % level)
  t.check(toy_pool.any(func(type):return g.SpecialEquipment.TYPES[type].family in g.SpecialEquipment.CUP_FAMILIES)==(level>=3),"PRISON cups open exactly from security three")
  t.check(g.state.capture.special_added.size()==(B.PRISON_INTAKE[level].special if level<5 else 2) and g.state.capture.special_baseline==g.state.special_equipment.map(func(e):return e.id) and g.state.special_equipment.all(func(e):return e.type in toy_pool or g.SpecialEquipment.is_reinforcement(e)),"PRISON intake counts special roots separately from their factory-owned bands")
  var before=g.state.duplicate(true)
  var view=g.get_view()
  t.check(view.prison.equipment_rule==g.Prison.equipment_label(g) and view.prison.equipment_rule.contains("复合")== (level>=3) and g.state==before and g.validate()=="","PRISON security profile projection agrees with legal generation and is readonly")
  if level not in [3,4]: continue
  t.action(g,"prison",{"action":"enter"})
  # This case verifies restraint punishment only; suppress unrelated periodic
  # toy pressure while the patrol timer advances.
  for item in g.state.special_equipment: item.remaining=0
  g.state.pressure=0
  var lost=g.equipment_targets()[0]
  lost.durability=0;g._cleanup()
  inspect(t,g);t.action(g,"prison",{"action":"inspect"})
  var quota=g.state.prison.missing.size()+B.PRISON_VIOLATION_EXTRA
  t.check(g.state.prison.report.contains("%d件%s" % [quota,g.Prison.equipment_label(g)]),"PRISON higher security inspection announces its actual pool and quota")
  if level==3:
   var saved=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"mixed inspection")
   preload("res://tests/persistence_cases.gd").step_both(t,g,saved,"prison",{"action":"accept"})
  else: t.action(g,"prison",{"action":"accept"})
  var event=g.state.logs.filter(func(log):return log.data.has("inspection"))[-1].data.inspection
  roots=(g.state.equipment+g.state.composites).filter(func(e):return e.id in event.installed)
  t.check(roots.size()==event.installed.size() and roots.size()<=quota and roots.all(func(root):return root.grade==grade if not root.has("components") else root.components.all(func(e):return e.grade==grade)),"PRISON mixed inspection quota counts actual roots, not component count")
  t.check(roots.all(func(root):return g.tier(root.durability,root.maximum)==tier if not root.has("components") else root.components.all(func(e):return g.tier(e.durability,e.maximum)==(grade if g.Equipment.is_shoulder(e) else tier))),"PRISON fresh inspection equipment keeps its profile instead of being tightened with old gear")
  t.check(g.state.prison.baseline==g.equipment_targets().map(func(e):return e.id) and g.validate()=="","PRISON mixed replacement leaves a complete valid component manifest")

static func intake_floor_cases(t) -> void:
 for amount in [5,6,7]:
  var g=Game.new(42,true,"guard")
  g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[]
  for i in range(amount):
   if i<6: g._install_template("belt","calf",4.0,10.0,false,"fixture",1,-1,0,"mid_calf" if i>=3 else "below_knee")
   else: g.add_fixture("ankle",4.0)
  var old=g.state.equipment.map(func(e):return e.id)
  Guard.capture(g,g.state.enemies[0])
  t.check(g.Cards.worn_count(g,false)==(8 if amount<6 else amount) and g.state.capture.added.size()==(8-amount if amount<6 else 0),"PRISON below/equal/above floor uses whole-piece intake count")
  t.check(old.all(func(id):return not g._equipment(id).is_empty() and g.tier(g._equipment(id).durability,g._equipment(id).maximum)==2),"PRISON intake preserves old identities and applies tier two or one-step tightening")
  t.check(g.validate()=="","PRISON floor boundary leaves legal equipment and capture manifest")
 var g=Game.new(42,true,"guard")
 g.state.security=2
 var collar=g._install_template("restriction_collar","neck",1.0,1.0,false,"fixture",3)
 var old_special=g.state.special_equipment.map(func(e):return e.id)
 Guard.capture(g,g.state.enemies[0])
 t.check(g.state.equipment.filter(func(e):return g.Equipment.lock_only(e)).size()==1 and g._equipment(collar.id).locked,"PRISON reuses and relocks the existing collar without duplication")
 t.check(old_special.all(func(id):return not g._equipment(id).is_empty()),"PRISON special intake never replaces existing equipment")
 g=Game.new(42,true,"guard")
 g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[]
 var host=g.add_fixture("upper_arm",8.0)
 for slot in ["forearm","wrist","thigh","calf","ankle"]: g.add_fixture(slot,10.0)
 Guard.capture(g,g.state.enemies[0])
 t.check(g.state.capture.added.is_empty() and g.tier(g._equipment(host.id).durability,g._equipment(host.id).maximum)==3 and g.physical_pieces().all(func(e):return g.tier(e.durability,e.maximum)>=2),"PRISON sufficient intake caps existing tiers and raises newly created straps to tier two")

static func collar_cases(t) -> void:
 var Cards=preload("res://tests/curse_cases.gd")
 var g=Game.new(42)
 g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[]
 var collar=g._install_template("restriction_collar","neck",1.0,1.0,true,"fixture",3)
 t.check(not collar.is_empty() and g.Cards.worn_count(g)==0 and g.Cards.restraint_roots(g).is_empty(),"COLLAR fixed neck item contributes no worn count or draw-trigger count")
 t.check(not g.EquipmentOffers.ordinary(g,3).any(func(p):return p.template=="restriction_collar"),"COLLAR excluded from random ordinary offers")
 t.check(g._install_template("restriction_collar","neck",1.0,1.0,true,"fixture",3).is_empty(),"COLLAR repeated installation rejected")
 var view=g.View.equipment_entry(g,collar,"neck")
 t.check(view.lock_only and view.description.contains("无耐久") and not view.description.contains("1/1") and view.tier==0 and ResourceLoader.exists(view.image),"COLLAR view has icon and no fabricated durability/tightness")
 for free in [false,true]:
  var normal=Cards.give(g,"henshin")
  var c=t.find_action(g,"card",{"uid":normal.uid,"free":free})
  var before=g.export_snapshot()
  t.check(not c.valid and c.reason.contains("限制项圈") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"COLLAR blocks both normal henshin faces atomically")
 var before=g.export_snapshot()
 t.check(not t.action(g,"manual",{"target":collar.id}).ok and g.state==before,"COLLAR locked manual removal spends nothing")
 for kind in ["strain","slip","magic","cut"]: g._apply_equipment_damage(collar,100.0,kind)
 g._apply_manual_release(collar,0.0)
 t.check(collar.durability==1.0 and collar.locked,"COLLAR ignores damage and generic automatic release")
 var arm=g.add_fixture("upper_arm",8.0)
 var unlock=Cards.give(g,"unlock")
 g.state.sure_cast=true
 t.check(t.action(g,"card",{"uid":unlock.uid,"target":collar.id,"free":false}).ok and not g._equipment(collar.id).locked,"COLLAR unlock spell opens lock before arms are free")
 t.check(not t.find_action(g,"manual",{"target":collar.id}).valid,"COLLAR unlocked still requires both arms free")
 g._apply_manual_release(g._equipment(arm.id),0.0);g._cleanup()
 var twin=Game.new(7)
 t.check(twin.restore_snapshot(g.export_snapshot()).ok and not twin._equipment(collar.id).locked,"COLLAR unlocked intermediate state survives save restoration")
 var release=t.find_action(g,"manual",{"target":collar.id})
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(release.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"COLLAR stale removal leaves lock, equipment and energy unchanged")
 var energy=g.state.energy
 t.check(g.dispatch(g.command(release.payload,g.state.version),g.state.version).ok and g._equipment(collar.id).is_empty() and g.state.energy==energy-1,"COLLAR unlocked and free arms remove whole item for one energy")
 collar=g._install_template("restriction_collar","neck",1.0,1.0,true,"fixture",3)
 g._gain_tool("picks")
 var picks=g.state.items.filter(func(item):return item.type=="picks")[0]
 var uses=picks.uses
 t.check(t.action(g,"item_use",{"item":picks.id,"target":collar.id}).ok and not g._equipment(collar.id).locked and g._item(picks.id).uses==uses-1,"COLLAR ordinary carried unlocking tool opens the neck lock and spends one use")
 for free in [false,true]:
  g=Game.new(42)
  collar=g._install_template("restriction_collar","neck",1.0,1.0,true,"fixture",3)
  g.state.sure_cast=true
  var perfect=Cards.give(g,"hannya_henshin")
  t.check(t.action(g,"card",{"uid":perfect.uid,"free":free}).ok and g._equipment(collar.id).is_empty() and g.validate()=="","COLLAR perfect henshin can play either face and directly remove locked collar")

static func toy_inspection_cases(t) -> void:
 var g=intake(t,1);clear_fixture(g)
 var powered=g._install_special("nipple_clamp_low","special_1_a")
 var rope=g._install_special("crotch_rope_low","special_3_a")
 var powered_id=powered.id
 g.state.prison.special_baseline=[powered.id,rope.id]
 powered.remaining=0;rope.durability=0;g._cleanup()
 g.state.prison.left=1;g.state.pressure=0
 t.action(g,"end");t.action(g,"prison",{"action":"inspect"})
 t.check(g.state.prison.special_missing==[rope.id] and g.state.prison.report.contains("少了1件性玩具") and g.state.prison.report.contains("又拿来了2件初级性玩具"),"PRISON missing toy declares N plus one from the current pool")
 var saved=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"toy inspection")
 preload("res://tests/persistence_cases.gd").step_both(t,g,saved,"prison",{"action":"accept"})
 var event=g.state.logs.filter(func(log):return log.data.has("inspection"))[-1].data.inspection
 t.check(event.special_missing==[rope.id] and event.special_requested==2 and event.special_installed.size()==2,"PRISON toy punishment installs and records the exact missing-plus-one quota")
 powered=g._equipment(powered_id)
 t.check(powered.remaining==g.SpecialEquipment.TYPES[powered.type].duration and event.recharged.has(powered_id),"PRISON punishment refills an existing empty battery after all installations")
 t.check(g.state.prison.special_baseline==g.state.special_equipment.map(func(e):return e.id) and event.special_registered==g.state.special_equipment.size() and g.validate()=="","PRISON toy inspection refreshes the real special-equipment manifest")
 t.action(g,"prison",{"action":"resume"})
 for item in g.state.special_equipment: item.remaining=0
 g.state.pressure=0;g.state.prison.left=1
 t.action(g,"end");t.action(g,"prison",{"action":"inspect"});t.action(g,"prison",{"action":"accept"})
 event=g.state.logs.filter(func(log):return log.data.has("inspection"))[-1].data.inspection
 var powered_ids=g.state.special_equipment.filter(func(item):return g.SpecialEquipment.TYPES[item.type].duration>0).map(func(item):return item.id)
 t.check(event.special_missing.is_empty() and event.special_requested==0 and event.special_installed.is_empty(),"PRISON clean inspection does not invent replacement toys")
 t.check(event.recharged==powered_ids and powered_ids.all(func(id):return g._equipment(id).remaining==g.SpecialEquipment.TYPES[g._equipment(id).type].duration),"PRISON every completed clean inspection also refills all remaining batteries")
 t.check(g.state.special_equipment.filter(func(item):return g.SpecialEquipment.TYPES[item.type].duration==0).all(func(item):return item.remaining==0),"PRISON batteryless toys keep their permanent zero-duration state")

static func punishment_cases(t) -> void:
 var g=intake(t,1);clear_fixture(g)
 var ids=[]
 for slot in ["wrist","ankle","eyes"]:
  var piece=g._install_template(g.Equipment.default_template(slot),slot,4,10,false,"fixture")
  ids.append(piece.id)
 g.state.prison.baseline=ids.duplicate()
 for id in ids: g._equipment(id).durability=0
 g._cleanup()
 inspect(t,g);t.action(g,"prison",{"action":"inspect"})
 t.check(g.state.prison.missing==ids and g.state.prison.report.contains("5件初级二档"),"PRISON three missing physical pieces declare five additions at the current security profile")
 var saved=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"violation quota")
 preload("res://tests/persistence_cases.gd").step_both(t,g,saved,"prison",{"action":"accept"})
 t.check(g.state.equipment.size()==5 and g.state.equipment.all(func(e):return e.grade==1 and g.tier(e.durability,e.maximum)==2),"PRISON restored inspection commits the same five elementary tier-two roots")
 var baseline=g.state.prison.baseline.duplicate()
 t.action(g,"prison",{"action":"resume"});g.state.prison.left=1;inspect(t,g);t.action(g,"prison",{"action":"inspect"})
 t.check(g.state.prison.missing.is_empty() and g.state.prison.baseline==baseline,"PRISON new baseline does not charge again for already replaced or removed items")
 t.action(g,"prison",{"action":"accept"})
 t.check(g.state.prison.baseline==g.equipment_targets().map(func(e):return e.id),"PRISON clean inspection refreshes the same actual registration")
 t.action(g,"prison",{"action":"resume"})
 var one=g.state.equipment.filter(func(e):return e.slot=="wrist")[0]
 one.durability=0;g._cleanup()
 g.state.prison.left=1 # Isolate repeat registration from the independently tested sentence.
 inspect(t,g);t.action(g,"prison",{"action":"inspect"})
 t.check(g.state.prison.missing==[one.id] and g.state.prison.report.contains("3件初级二档"),"PRISON next check counts only the one new loss instead of accumulating previous losses")

 # All ordinary locations are full and stronger than the incoming three-point value,
 # except the single mouth slot. Its new replacement must not be replaced twice.
 g=intake(t);clear_fixture(g)
 var lost=g._install_template("eye_tape","eyes",4,10,false,"fixture")
 g.state.prison.baseline=[lost.id];lost.durability=0;g._cleanup()
 fill_strong(g)
 # Saturation now includes legal links as well as occupied ordinary slots.
 for option in g.EquipmentOffers.links(g,3):
  option.grade=3;option.tier=3
  g.Application.execute_concrete(g,option,"fixture")
 var mouth=g.equipment_at("mouth")[0]
 mouth.grade=1;mouth.maximum=10.0;mouth.durability=4.0;mouth.locked=false;mouth.variant=0;g._refresh_equipment(mouth)
 var old_id=mouth.id
 inspect(t,g);t.action(g,"prison",{"action":"inspect"});t.action(g,"prison",{"action":"accept"})
 var actual=g.state.equipment.filter(func(e):return e.source=="prison")
 t.check(actual.size()==1 and actual[0].slot=="mouth" and g._equipment(old_id).is_empty(),"PRISON saturation replaces one weaker exterior item without recycling its quota")
 var inspection=g.state.logs.filter(func(log):return log.data.has("inspection"))[-1].data.inspection
 t.check(inspection.requested==3 and inspection.installed.size()==1 and g.state.prison.report.contains("拘束具补回1/3件") and g.validate()=="","PRISON reports actual quota shortfall and leaves legal equipment")

 # A damaged short glove covers five points. Missing shoulder components count
 # individually, but cannot authorize taking half a covering group off the body.
 for remove_extra in [false,true]:
  g=intake(t,2);clear_fixture(g)
  for point in ["upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist"]:
   for i in range(2):
    g._install_template("belt",g.Links.point_slot(point),9.6,24,false,"fixture",3,-1,0,point)
  var root=g._install_assembly("glove","short","fixture",2,1)
  var extra=g._install_template("eye_tape","eyes",4,10,false,"fixture")
  g.state.prison.baseline=g.equipment_targets().map(func(e):return e.id)
  for component in root.components:
   if component.part!="body": component.durability=0
  if remove_extra: extra.durability=0
  g._cleanup();fill_strong(g)
  # Keep the nonmissing eye item stronger than incoming gear as well.
  if not remove_extra:
   extra.grade=3;extra.maximum=24.0;extra.durability=24.0;extra.variant=0
  inspect(t,g);t.action(g,"prison",{"action":"inspect"})
  var roots_before=g.state.composites.map(func(e):return e.id)
  t.action(g,"prison",{"action":"accept"})
  actual=g.equipment_targets().filter(func(e):return e.source=="prison")
  t.check(actual.size()==(5 if remove_extra else 4) and actual.all(func(e):return e.template=="link_rope"),"PRISON full ordinary slots consume the declared quota on legal new links first")
  t.check(not g._composite(root.id).is_empty() and g.state.composites.map(func(e):return e.id)==roots_before,"PRISON does not replace a composite while legal link additions remain, even with enough nominal quota")
  t.check(g.state.prison.baseline==g.equipment_targets().map(func(e):return e.id) and g.validate()=="","PRISON post-punishment registration includes surviving components and fresh automatic attachments")

static func fill_strong(g) -> void:
 while true:
  var options=g.EquipmentOffers.ordinary(g,3)
  if options.is_empty(): break
  var option=options[0]
  var locked=g.Equipment.TEMPLATES[option.template].lock
  g._install_template(option.template,option.slot,24,24,locked,"fixture",3,-1,0,option.point)

static func practice_cases(t) -> void:
 for kind in ["prison_test","prison_blind"]:
  var g=preload("res://core/game.gd").new(42,true,kind)
  t.check(g.validate()=="" and g.state.phase=="prison" and g.state.room=="prison" and g.state.posture=="lie" and g.at_wall(),"PRISON practice uses formal cell and lying wall start "+kind)
  t.check(g.state.security==1 and g.state.prison.turn==1 and g.state.prison.left==16 and g.state.hand.size()==5 and g.state.energy==3 and g.state.enemies.is_empty(),"PRISON practice starts normal first player turn "+kind)
  t.check(g.occupied("eyes")==(kind=="prison_blind") and g.state.equipment.size()==(3 if kind=="prison_blind" else 2),"PRISON practice matches declared vision and fixtures "+kind)
  t.check(g.state.save_slot=="practice" and g.state.prison.baseline==g.equipment_targets().map(func(e):return e.id),"PRISON practice has separate save identity and real inspection baseline")
  var before=g.export_snapshot();var clone=preload("res://core/game.gd").new(9)
  var loaded=clone.restore_snapshot(before)
  var restored=clone.export_snapshot();restored.version=before.version
  t.check(loaded.ok and clone.state.version>before.version and restored==before,"PRISON practice restores exact cell with renewed input version")
  var move_payload=Spatial.approach(g,"shard")
  before=g.export_snapshot()
  var c=t.find_action(g,"prison",move_payload)
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==before,"PRISON practice stale action atomic")
  t.check(t.action(g,"prison",move_payload).ok and g.state.prison.found.size()==1 and g.state.energy==3-c.cost and g.state.prison.left==16,"PRISON practice exploration uses existing costs and finite discovery")
  t.check(g.state.logs.any(func(log):return log.data.has("passive_slip")),"PRISON practice exploration still uses shared passive slip")
  t.check(t.action(g,"end").ok and g.state.prison.left==15 and g.state.prison.turn==2,"PRISON practice countdown advances through formal end turn")
  t.check(g.validate()=="","PRISON practice remains valid after actions")

static func inspection_climax_cases(t) -> void:
 var g=intake(t);clear_fixture(g);inspect(t,g)
 t.check(t.action(g,"prison",{"action":"inspect"}).ok,"PRISON MILKING clean patrol reaches result")
 g.state.mana=75;g.state.pressure=23
 var total_before=g.state.overload_total
 t.check(t.action(g,"prison",{"action":"accept"}).ok,"PRISON MILKING accepted patrol commits")
 var event=g.state.logs.filter(func(log):return log.data.has("inspection"))[-1].data.inspection
 var scene=g.state.logs.filter(func(log):return log.data.has("prison_inspection_climax"))[-1].data.prison_inspection_climax
 t.check(g.state.overload_total==total_before+1 and g.state.mana==55 and g.state.pressure==23,"PRISON MILKING patrol causes exactly one scripted climax and immediate twenty mana loss")
 t.check(not g.state.overloaded and g.state.overload_energy==0 and g.state.slip_ejaculation_turns==0,"PRISON MILKING scripted scene does not open combat climax interruption or deferred slip penalty")
 t.check(event.climax==scene and scene.method=="hand" and scene.count==1 and not scene.temporary and not scene.flat_lock and scene.narration_cue=="prison.inspection.milk.normal","PRISON MILKING inspection record owns its exact scene and numbers")
 var stable=g.export_snapshot()
 t.check(not t.action(g,"prison",{"action":"accept"}).ok and g.state==stable,"PRISON MILKING repeated acceptance cannot duplicate climax or mana loss")

 var locked=intake(t);clear_fixture(locked)
 var plate=locked._install_special("negative_plate_lock_catheter_medium","special_2_a",2)
 t.check(not plate.is_empty(),"PRISON MILKING flat-lock fixture installs")
 locked.state.prison.special_baseline=[plate.id]
 inspect(t,locked);t.action(locked,"prison",{"action":"inspect"})
 locked.state.mana=12;locked.state.pressure=9
 total_before=locked.state.overload_total
 t.check(t.action(locked,"prison",{"action":"accept"}).ok,"PRISON MILKING low locked patrol commits")
 scene=locked.state.logs.filter(func(log):return log.data.has("prison_inspection_climax"))[-1].data.prison_inspection_climax
 t.check(locked.state.mana==0 and locked.state.overload_total==total_before+1 and locked.state.slip_ejaculation_turns==0 and scene.flat_lock and scene.low_semen and scene.mana_lost==12,"PRISON MILKING low semen clamps at zero and event-style slip still deducts once immediately")
 t.check(locked.ActionCopy.line(scene.narration_cue,{},true).contains("乳房和小穴") and locked.ActionCopy.line(scene.narration_cue,{},true).contains("从缝隙里断断续续流出"),"PRISON MILKING flat lock uses the approved alternate hand stimulation and flow wording")

static func patrol_period_cases(t) -> void:
 t.check(B.PRISON_INTERVALS==[16,14,12,10,8],"PRISON patrol intervals decrease by two per security level")
 for level in range(1,5):
  var g=intake(t,level);clear_fixture(g)
  var period=18-2*level
  t.check(g.state.prison.left==period,"PRISON fresh intake starts a full cycle at level %d" % level)
  for turn in range(period-1):
   t.check(t.action(g,"end").ok and g.state.phase=="prison" and g.state.prison.left==period-turn-1,"PRISON patrol cannot arrive before cycle boundary")
  var before=g.export_snapshot()
  g.get_view();g.command_facts()
  t.check(g.state==before,"PRISON countdown queries do not consume the last turn")
  t.check(t.action(g,"end").ok and g.state.phase=="inspection" and g.state.prison.left==0,"PRISON last turn reaches inspection exactly")
  for action in ["inspect","accept","resume"]: t.check(t.action(g,"prison",{"action":action}).ok,"PRISON cycle completes through formal inspection")
  t.check(g.state.phase=="prison" and g.state.prison.left==period,"PRISON completed inspection restarts the same full cycle")

static func sentence_cases(t) -> void:
 release_inspection_cases(t)
 for floor in [8,9,10,11,12]:
  for kind in ["battle","event","shop","treasure","rest"]:
   var eligible=floor in [10,11] and kind in ["battle","event","shop"]
   t.check(Game.Prison.start_room({"floor":floor-1,"kind":kind})==eligible,"PRISON displayed starting floors exclude both rest and treasure at all boundaries")
 for level in range(1,5):
  var g=intake(t,level);clear_fixture(g)
  var deadline=[20,30,50,0][level-1]
  var original_boss=g.state.room_encounters.get("summit","")
  t.check(g.Prison.sentence_limit(g)==deadline and g.state.prison.served_turns==0,"PRISON sentence follows security")
  g.state.prison.key=true
  g.state.prison.served_turns=deadline-2 if deadline>0 else 80
  t.check(t.action(g,"end").ok and g.state.phase=="prison","PRISON cannot release before final completed turn")
  var saved=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"sentence boundary")
  if deadline==0:
   t.check(t.action(g,"end").ok and not g.state.tower_start_pending,"PRISON security four has no automatic release")
   continue
  preload("res://tests/persistence_cases.gd").step_both(t,g,saved,"end")
  t.check(g.state.tower_start_pending and g.state.phase=="map" and g.state.security==level,"PRISON deadline releases without raising security")
  t.check(original_boss!="" and g.state.room_encounters.summit==original_boss,"PRISON sentence release retains the original tower boss")
  t.check(g.state.rooms.filter(func(room):return room.has("encounter_choices")).all(func(room):return room.pool=="strong"),"PRISON sentence release makes every ordinary encounter strong")
  var checks=g.state.logs.filter(func(log):return log.data.has("inspection") and log.data.inspection.get("temporary",false))
  t.check(checks.size()==1 and checks[0].data.inspection.sentence_extension==0,"PRISON clean release performs exactly one temporary inspection")
  t.check(g.Cards.worn_count(g,false)>=g.B.PRISON_INTAKE[level].floor,"PRISON release applies ordinary intake equipment rules")
  var available=g.command_facts().filter(func(c):return c.payload.kind=="depart" and c.valid)
  var eligible=g.state.rooms.filter(func(r):return g.Prison.start_room(r))
  t.check(available.size()==eligible.size() and available.size()>0,"PRISON all eligible floors are start choices")
  var before=g.export_snapshot()
  for excluded in g.state.rooms.filter(func(r):return r.floor+1 in [10,11] and r.kind in ["rest","treasure"]):
   t.check(g.room_entry_reason(excluded)!="" and not t.action(g,"depart",{"room":excluded.id}).ok and g.state==before,"PRISON rest and treasure starts are rejected without mutation")
  var invalid=g.state.rooms.filter(func(r):return not g.Prison.start_room(r))[0]
  t.check(not t.action(g,"depart",{"room":invalid.id}).ok and before==g.state,"PRISON invalid start rejects atomically")
  var pick=available[0]
  t.check(not g.dispatch(g.command(pick.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"PRISON stale start rejects atomically")
  t.check(g.dispatch(g.command(pick.payload,g.state.version),g.state.version).ok and not g.state.tower_start_pending and g.state.room==pick.payload.room and g.state.travel_turns==0 and g.state.traversed_edges.is_empty(),"PRISON start uses arrival without artificial travel")
  t.check(g.validate()=="","PRISON selected arrival is valid")
 var clean=intake(t);clear_fixture(clean)
 inspect(t,clean)
 for op in ["inspect","accept"]: t.check(t.action(clean,"prison",{"action":op}).ok,"PRISON clean inspection")
 t.check(clean.state.prison.sentence_extra==0,"PRISON ordinary maintenance does not extend sentence")
 var bad=intake(t)
 bad.state.equipment=[];bad.state.composites=[];bad.state.links=[];bad.state.special_equipment=[]
 bad._gain_tool("shard")
 inspect(t,bad)
 for op in ["inspect","accept"]: t.check(t.action(bad,"prison",{"action":op}).ok,"PRISON combined violations inspection")
 t.check(bad.state.prison.sentence_extra==8 and bad.Prison.sentence_limit(bad)==28,"PRISON multiple violations extend only once")
 var stable=bad.export_snapshot()
 t.check(not t.action(bad,"prison",{"action":"accept"}).ok and bad.state==stable,"PRISON repeat acceptance cannot extend again")
 for kind in ["prison_release","prison_release_violation","prison_gate_exit"]:
  var practice=preload("res://core/game.gd").new(42,true,kind)
  t.check(practice.validate()=="","PRISON exit practice valid "+kind+": "+practice.validate())
  t.check(practice.Cards.worn_count(practice,false)>=B.PRISON_INTAKE[1].floor+B.PRISON_INTAKE[1].extra and practice.state.special_equipment.size()==B.PRISON_INTAKE[1].special and not practice.state.links.is_empty(),"PRISON every exit practice retains real intake equipment and links, including later battle additions")
  if kind=="prison_gate_exit":
   t.check(practice.Prison.is_exit_battle(practice) and practice.state.phase=="battle" and practice.state.enemies.all(func(e):return e.hp==e.max_hp and e.hp==practice.Enemies.TYPES.guard.hp),"PRISON guard practice preserves normal full-health guards")
   continue
  t.check(practice.state.phase=="captured" and practice.state.capture.baseline==practice.equipment_targets().map(func(e):return e.id) and practice.state.capture.special_baseline==practice.state.special_equipment.map(func(e):return e.id),"PRISON release entry shows actual capture with complete nonempty manifests")
  t.check(practice.Cards.worn_count(practice,false)==B.PRISON_INTAKE[1].floor+B.PRISON_INTAKE[1].extra,"PRISON initial capture installs exactly the normal intake quota")
  var before_enter=practice.export_snapshot()
  t.check(not t.action(practice,"end").ok and practice.state==before_enter,"PRISON practice cannot skip intake confirmation with end turn")
  t.check(t.action(practice,"prison",{"action":"enter"}).ok,"PRISON practice player enters through formal intake action")
  t.check(practice.state.prison.served_turns==0 and practice.state.prison.turn==1 and practice.state.prison.left==16 and practice.Prison.sentence_limit(practice)==20 and practice.state.items.is_empty(),"PRISON practice starts first real turn without shortened clocks or planted tools")
  for turn in range(19):
   t.check(t.action(practice,"end").ok and not practice.state.tower_start_pending,"PRISON real practice cannot release before its full sentence")
   if turn==15:
    t.check(practice.state.phase=="inspection" and practice.state.prison.served_turns==16,"PRISON practice reaches the normal sixteenth-turn inspection")
    for op in ["inspect","accept","resume"]: t.check(t.action(practice,"prison",{"action":op}).ok,"PRISON practice retains ordinary patrol decisions")
  if kind=="prison_release_violation":
   # Test-only removal of a real registered item; never alter the prison manifest.
   practice.state.equipment[0].durability=0
   practice._cleanup()
   var lost=practice.state.prison.baseline.filter(func(id):return practice._equipment(id).is_empty())
   t.check(not lost.is_empty(),"PRISON delay regression removes actual intake equipment")
   t.check(t.action(practice,"end").ok and practice.state.phase=="prison" and practice.state.prison.sentence_extra==8 and practice.state.prison.left==12,"PRISON real missing equipment blocks due release and retains patrol timing")
   var inspected=practice.state.logs.filter(func(log):return log.data.has("inspection"))[-1].data.inspection
   t.check(inspected.temporary and not inspected.missing.is_empty() and inspected.installed.size()>0 and practice.state.prison.baseline==practice.equipment_targets().map(func(e):return e.id),"PRISON practice applies normal replacement and updates actual manifest")
   var saved=preload("res://tests/persistence_cases.gd").roundtrip(t,practice,"real-intake delayed practice")
   for remaining in range(8):
    preload("res://tests/persistence_cases.gd").step_both(t,practice,saved,"end")
    t.check(practice.state.tower_start_pending==(remaining==7),"PRISON real-intake practice completes eight actual added turns")
  else:
   t.check(t.action(practice,"end").ok and practice.state.tower_start_pending,"PRISON compliant real-intake practice releases only after twenty turns")
  t.check(practice.state.phase=="map" and practice.validate()=="","PRISON real-intake practice reaches valid new-map selection")

static func release_inspection_cases(t) -> void:
 for left in [1,7]:
  var g=intake(t)
  g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[]
  g.state.prison.served_turns=19;g.state.prison.left=left
  g.state.mana=100
  g._gain_tool("shard")
  var before=g.export_snapshot()
  var end=t.find_action(g,"end")
  t.check(not g.dispatch(g.command(end.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"PRISON stale due turn cannot inspect or punish")
  var saved=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"temporary inspection due")
  preload("res://tests/persistence_cases.gd").step_both(t,g,saved,"end")
  t.check(g.state.prison.served_turns==20 and g.state.prison.sentence_extra==8 and g.state.prison.checks==1 and not g.state.tower_start_pending,"PRISON combined due violations delay release by eight once")
  t.check(g.state.prison.left==left-1 and g.state.phase==("inspection" if left==1 else "prison"),"PRISON temporary inspection preserves normal patrol schedule")
  var event=g.state.logs.filter(func(log):return log.data.has("inspection"))[-1].data.inspection
  t.check(event.temporary and not event.missing.is_empty() and not event.special_missing.is_empty() and event.confiscated>0,"PRISON temporary check reuses all ordinary violation effects")
  t.check(event.climax.temporary and event.climax.count==1 and event.climax.mana_lost==B.OVERLOAD_MANA and g.state.mana==80,"PRISON temporary release inspection also hand-milks exactly once with immediate mana loss")
  t.check(g.validate()=="","PRISON failed release keeps a valid phase")
  if left==1:
   for op in ["inspect","accept","resume"]: t.check(t.action(g,"prison",{"action":op}).ok,"PRISON scheduled patrol still occurs at original boundary")
   t.check(g.state.prison.sentence_extra==8 and g.state.prison.left==16,"PRISON subsequent clean scheduled check does not add another penalty")
  # A second due date with a new violation must extend again, including with a key.
  g.state.prison.key=true;g.state.prison.served_turns=27
  g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[]
  var paused_left=g.state.prison.left
  t.check(t.action(g,"end").ok and g.state.prison.sentence_extra==16 and g.state.prison.served_turns==28 and g.state.prison.left==paused_left,"PRISON repeated due violation adds eight while keyed patrol remains paused")
  clear_fixture(g);g.state.prison.served_turns=35
  var climax_before=g.state.overload_total
  t.check(t.action(g,"end").ok and g.state.tower_start_pending,"PRISON later compliant due check finally releases")
  t.check(g.state.overload_total==climax_before+1 and g.get_view().npc_speech.cue=="prison.guard.release_pass" and g.get_view().npc_speech.visual=="guard_brown","PRISON normal release follows its extra milking with the senior guard dialogue")

static func battle_pause_cases(t) -> void:
 # docs/design/prison.md §2: battle and preparation freeze the whole cell clock
 # (patrol countdown, sentence and due check) and keeps the cell position; the cell
 # resumes from the paused values once the player is back.
 var g=intake(t)
 Spatial.at_site(g,"shard") # Shard sites always sit away from the wall.
 var cell_position=g.state.prison.space.position.duplicate()
 var wall_before=g.state.wall_distance
 t.check(wall_before>0,"PRISON resistance fixture starts away from the wall")
 inspect(t,g)
 var left_before=g.state.prison.left
 t.check(t.action(g,"prison",{"action":"resist"}).ok and g.state.phase=="battle" and g.state.prison.resisting,"PRISON resistance starts a real battle from the cell")
 t.check(g.state.wall_distance==wall_before and g.state.prison.space.position==cell_position,"PRISON battle start keeps the cell wall distance and never repositions the player")
 # The due date is already overdue when the battle starts: no battle round may spend it.
 var due_limit=g.Prison.sentence_limit(g)
 g.state.prison.served_turns=due_limit-1
 for round_index in range(2):
  g.state.posture="stand";g.state.pressure=0
  t.check(t.action(g,"end").ok and g.state.phase=="battle","PRISON battle round %d ends inside the battle" % (round_index+1))
  t.check(g.state.prison.served_turns==due_limit-1 and g.state.prison.left==left_before and g.state.prison.checks==0 and g.state.prison.sentence_extra==0 and not g.state.tower_start_pending,"PRISON battle round %d neither advances the clock nor runs the due release check" % (round_index+1))
 g.state.posture="stand";g.state.enemies[0].hp=0.1
 # The guard has bound the arms by now, so the formal close combat kick ends the battle.
 t.check(t.action(g,"attack",{"type":"kick","enemy":g.state.enemies[0].id}).ok and g.state.phase=="reward" and g.state.prison.key,"PRISON resistance victory keeps the keyed cell")
 t.action(g,"reward",{"type":"skip"})
 var preparation=Game.new(42)
 t.check(preparation.restore_snapshot(g.export_snapshot()).ok and preparation.state.phase=="prepare","PRISON battle-pause boundary restores the real post-battle preparation")
 # Missing registered equipment must not cause a due inspection during preparation.
 preparation.state.equipment=[];preparation.state.composites=[];preparation.state.links=[];preparation.state.special_equipment=[]
 var preparation_turns=preparation.state.prepare_left
 for i in range(preparation_turns):
  t.check(t.action(preparation,"end").ok,"PRISON preparation completes its normal budget")
  t.check(preparation.state.prison.served_turns==due_limit-1 and preparation.state.prison.left==left_before and preparation.state.prison.checks==0 and preparation.state.prison.sentence_extra==0 and preparation.equipment_targets().is_empty() and preparation.state.special_equipment.is_empty(),"PRISON preparation cannot advance sentence inspect or re-equip, including its final turn")
 t.check(preparation.state.phase=="prison" and preparation.state.prison.key and preparation.validate()=="","PRISON natural preparation completion returns to the valid keyed cell")
 var saved=preload("res://tests/persistence_cases.gd").roundtrip(t,preparation,"paused sentence after preparation")
 preload("res://tests/persistence_cases.gd").step_both(t,preparation,saved,"end")
 t.check(preparation.state.prison.served_turns==due_limit and preparation.state.prison.checks==1 and preparation.state.prison.sentence_extra==B.PRISON_SENTENCE_PENALTY and not preparation.equipment_targets().is_empty(),"PRISON first complete cell turn resumes the due inspection and missing-equipment penalty")
 t.action(g,"finish_prepare")
 t.check(g.state.phase=="prison" and g.state.prison.served_turns==due_limit-1 and g.state.prison.space.position==cell_position and g.state.wall_distance==Spatial.Space.wall_distance(cell_position),"PRISON return to the cell reuses the same position, the same paused clock and recomputes its wall distance")
 g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[]
 g.state.posture="stand"
 t.check(t.action(g,"end").ok and g.state.phase=="prison" and g.state.prison.served_turns==due_limit and g.state.prison.sentence_extra==B.PRISON_SENTENCE_PENALTY and g.state.prison.checks==1 and not g.state.tower_start_pending,"PRISON first cell turn after the return runs the due check and its eight-turn delay")
 t.check(g.state.prison.left==left_before and g.state.prison.key,"PRISON keyed patrol stays paused across the delayed due check")
 t.check(g.validate()=="","PRISON battle-pause scenario keeps a valid state")

static func security_health_cases(t) -> void:
 for pair in [["drone_solo",10],["puppeteer_solo",20],["six_bind_solo",30]]:
  var g=Game.new(42,true,"guard")
  g.state.security=3;g.state.demo_cycle=1
  g.state.room_encounters[g.state.room]=pair[0]
  g._spawn_enemies(pair[0])
  var enemy=g.state.enemies[0]
  var expected=float(g.Enemies.TYPES[enemy.type].hp)*1.5+2*pair[1]
  t.check(enemy.hp==expected and enemy.max_hp==expected,"PRISON security health added after carry-over multiplier "+pair[0])
  var inherited=g._append_enemies([{"type":"rope","grade":1,"hp":17.0}],true)[0]
  t.check(inherited.hp==17.0,"PRISON split health is not boosted again")
  if pair[0]=="puppeteer_solo":
   g.Puppets.summon(g,enemy)
   t.check(g.Puppets.validate(g,g.state.enemies,1.5)=="","PRISON summons preserve health validation")
   g.state.room="prison"
   t.check(g.Puppets.validate(g,g.state.enemies,1.5)=="","PRISON summon health remains valid after changing to capture room")
 var g=Game.new(42,true,"guard")
 g.state.security=0;g._spawn_enemies("drone_solo")
 t.check(g.state.enemies[0].hp==g.Enemies.TYPES.drone.hp,"PRISON no negative health at security zero")

# Build a formerly valid two-family save without reopening the current installer.
static func legacy_cup_pair(t, first: String, second: String):
 var g=intake(t,5)
 g.state.special_equipment=[];g.state.relics=["marble_stone"]
 g.state.pressure=0;g.state.overloaded=false;g.state.overload_count=0
 g._install_special(first,g.SpecialEquipment.DESIGNS[first].slots[0],3)
 var donor=Game.new(42)
 donor._install_special(second,donor.SpecialEquipment.DESIGNS[second].slots[0],3)
 var added=donor.state.special_equipment.duplicate(true)
 var ids={}
 for item in added:
  ids[item.id]="special_"+str(g.state.next_equipment);g.state.next_equipment+=1
 for item in added:
  item.id=ids[item.id]
  if item.owner_id!="": item.owner_id=ids[item.owner_id]
 g.state.special_equipment.append_array(added)
 var all_ids=g.state.special_equipment.map(func(item):return item.id)
 g.state.prison.special_baseline=all_ids.duplicate();g.state.prison.special_missing=[]
 g.state.capture.special_baseline=all_ids.duplicate();g.state.capture.special_added=all_ids.duplicate();g.state.capture.retained_special=[]
 g.state.save_revision=g.Snapshot.CUP_STACK_REVISION
 t.check(g.SpecialEquipment.validate(g.state.special_equipment,true)=="","CUP SAVE fixture obeys the previous cross-family and capacity rules")
 return g

static func cup_stack_migration(t) -> void:
 var D=preload("res://data/special_equipment.gd")
 for pair in [["full_cup_medium","forced_milking_cup_high",1],["forced_milking_cup_high","full_cup_high",0],["urethral_full_cup_high","forced_milking_cup_high",0]]:
  var g=legacy_cup_pair(t,pair[0],pair[1])
  var saved=g.export_snapshot()
  var cups=saved.special_equipment.filter(func(item):return D.exclusive_family(item.type)=="cup")
  var keep=cups[pair[2]].id
  var remove=cups[1-pair[2]].id
  var removed=saved.special_equipment.filter(func(item):return item.id==remove or item.owner_id==remove).map(func(item):return item.id)
  var restored=Game.new(77)
  t.check(restored.restore_snapshot(saved).ok and restored.validate()=="" and restored.state.save_revision==restored.Snapshot.REVISION,"CUP SAVE older two-cup prison state migrates to the current revision")
  t.check(restored.state.special_equipment.filter(func(item):return D.exclusive_family(item.type)=="cup").map(func(item):return item.id)==[keep],"CUP SAVE highest grade wins, with earliest equipped as the equal-grade tie breaker")
  t.check(removed.all(func(id):return restored._equipment(id).is_empty() and id not in restored.state.prison.special_baseline and id not in restored.state.capture.special_baseline and id not in restored.state.capture.special_added),"CUP SAVE removed owners and bands leave no inspection violation records")
  t.check(saved==g.state and restored.state.mana==saved.mana and restored.state.relics==saved.relics,"CUP SAVE migration preserves the caller's old save, mana and relics")
  var before=restored.export_snapshot();var forged=saved.duplicate(true);forged.save_revision=restored.Snapshot.REVISION
  t.check(not restored.restore_snapshot(forged).ok and restored.state==before,"CUP SAVE current revision cannot reopen legacy stacking by restoring a forged pair")
  var old52=saved.duplicate(true);old52.save_revision=restored.Snapshot.REINFORCEMENT_STATE_REVISION
  var old_bands=old52.special_equipment.filter(D.is_reinforcement).map(func(item):return item.id)
  old52.special_equipment=old52.special_equipment.filter(func(item):return not D.is_reinforcement(item))
  for item in old52.special_equipment: item.erase("reinforcement_state")
  for record in [old52.capture,old52.prison]:
   for key in ["special_added","special_baseline"]:
    if record.has(key): record[key]=record[key].filter(func(id):return id not in old_bands)
  var restored52=Game.new(19)
  t.check(restored52.restore_snapshot(old52).ok and restored52.validate()=="" and restored52.state.special_equipment.filter(D.is_reinforcement).is_empty(),"CUP SAVE real revision-52 tight cups remain bandless while extra cups are removed")
  t.check(restored52.state.special_equipment.filter(func(item):return D.exclusive_family(item.type)=="cup").map(func(item):return item.id)==[keep],"CUP SAVE revision-52 migration uses the same highest-grade and earliest tie rule")
  if pair[0]!="urethral_full_cup_high": continue
  # Cup balance changes do not alter migration, inspection or recharge invariants.
  var playable=0;var inspections=0
  for step in range(30):
   if restored.state.phase=="inspection":
    var action={"arrival":"inspect","result":"accept","done":"resume"}[restored.state.prison.stage]
    t.check(t.action(restored,"prison",{"action":action}).ok,"CUP PRISON repaired save progresses through real inspections")
    if action=="accept":
     inspections+=1
     t.check(restored.state.prison.special_missing.is_empty(),"CUP PRISON migrated extra cups are not treated as removed contraband")
   else:
    if not restored.state.overloaded and restored.state.energy>0: playable+=1
    t.check(t.action(restored,"end").ok,"CUP PRISON repaired save progresses through real turn boundaries")
   t.check(restored.state.special_equipment.filter(func(item):return D.exclusive_family(item.type)=="cup").size()==1,"CUP PRISON inspections and recharge cannot reintroduce a second cup")
  t.check(playable>0 and inspections>=2,"CUP PRISON repaired fifth-security run retains playable turns across multiple recharge cycles")
