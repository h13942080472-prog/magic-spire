extends SceneTree

const Game = preload("res://tests/game_fixture.gd")
var count = 0
var failures: Array[String] = []
var exhaustive=false
var reported_seed_sets={}
var engine_errors=preload("res://tests/error_collector.gd").new()
const Selection=preload("res://tests/suite_selection.gd")
const SUITES={"witch_character":"res://tests/witch_character_cases.gd","localization":"res://tests/localization_cases.gd","card_power":"res://tests/card_power_cases.gd","card_expansion":"res://tests/card_expansion_cases.gd","relics":"res://tests/relic_revision_cases.gd","card_splash":"res://tests/card_splash_cases.gd","card_growth":"res://tests/concentration_cases.gd","item_discard":"res://tests/item_discard_cases.gd","consumables":"res://tests/consumable_cases.gd","basic_attacks":"res://tests/basic_attack_cases.gd","battle_saturation":"res://tests/battle_saturation_cases.gd","replacement":"res://tests/replacement_cases.gd","application":"res://tests/application_cases.gd","architecture":"res://tests/architecture_cases.gd","installation_priority":"res://tests/installation_priority_cases.gd","event_flow":"res://tests/event_flow_cases.gd","curses":"res://tests/curse_cases.gd","encyclopedia":"res://tests/encyclopedia_cases.gd","shop_release":"res://tests/shop_release_cases.gd","content":"res://tests/content_cases.gd","installed_tools":"res://tests/installed_tools_cases.gd","environment_height":"res://tests/environment_height_cases.gd","exploration":"res://tests/exploration_cases.gd","shoulder":"res://tests/shoulder_cases.gd","slip_motion":"res://tests/slip_motion_cases.gd","torso_binding":"res://tests/torso_binding_cases.gd","runner":"res://tests/runner_cases.gd","hand_assist":"res://tests/hand_assist_cases.gd","casting":"res://tests/casting_cases.gd","wall":"res://tests/wall_cases.gd","special_equipment":"res://tests/special_equipment_cases.gd","services":"res://tests/service_cases.gd","intent":"res://tests/intent_cases.gd","action_copy":"res://tests/action_copy_cases.gd","status":"res://tests/status_cases.gd","normal_play":"res://tests/normal_play_cases.gd","persistence":"res://tests/persistence_cases.gd","rewards":"res://tests/reward_cases.gd","events":"res://tests/event_cases.gd","core":null,"equipment":"res://tests/equipment_cases.gd","links":"res://tests/link_cases.gd","composites":"res://tests/composite_cases.gd","equipment_complete":"res://tests/equipment_complete_cases.gd","prison":"res://tests/prison_cases.gd","guard":"res://tests/guard_cases.gd","pressure":"res://tests/pressure_cases.gd","enemies":"res://tests/enemy_cases.gd","iron_man":"res://tests/iron_man_cases.gd","trader":"res://tests/trader_cases.gd","tower":"res://tests/tower_cases.gd","tower_progression":"res://tests/tower_progression_cases.gd"}


func check(ok: bool, message: String) -> void:
 count += 1
 if not ok:
  failures.append(message)
  push_error(message)

func action(g, kind: String, extra: Dictionary = {}) -> Dictionary:
 var c=find_action(g,kind,extra,true)
 if c.valid: return g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 return {"ok":false, "error":"测试没有找到动作：" + kind}

func seed_values(id: String) -> Array:
 var values=Selection.seeds(id,exhaustive)
 if not reported_seed_sets.has(id):
  reported_seed_sets[id]=true
  print("SAMPLES %s: %d/%d seeds" % [id,values.size(),Selection.seeds(id,true).size()])
 return values

func _initialize() -> void:
 OS.add_logger(engine_errors)
 if "--probe-runtime-error" in OS.get_cmdline_user_args():
  preload("res://tests/runtime_error_probe.gd").run()
  print("FAIL: initialization runtime error")
  quit(1);return
 var requested: Array=["runner","architecture"]
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--suite="): requested=Array(arg.trim_prefix("--suite=").split(",",false))
 var selection=Selection.resolve(SUITES.keys(),requested,"--impact" in OS.get_cmdline_user_args())
 if not selection.ok:
  push_error(selection.error);quit(1);return
 var selected=selection.selected
 exhaustive="all" in requested or "--exhaustive" in OS.get_cmdline_user_args()
 print("RULE SCOPE: "+",".join(selected))
 print("RULE SAMPLING: "+("exhaustive" if exhaustive else "daily; use --exhaustive for the complete seed matrix"))
 if "--list-only" in OS.get_cmdline_user_args():
  for name in selected: print("  %s [%s; %s]" % [name,selection.reasons[name],Selection.stage(name)])
  print("PLAN ONLY: no rule tests executed")
  quit(0);return
 for name in SUITES:
  if name not in selected: continue
  print("SUITE START: "+name)
  var started=Time.get_ticks_msec()
  var previous=count
  var previous_failures=failures.size();var previous_errors=engine_errors.count()
  if name=="core": _core_cases()
  else:
   var suite=load(SUITES[name])
   if suite==null or not suite.can_instantiate():
    push_error("Cannot load selected rule suite: "+name);quit(1);return
   suite.run(self)
  if "--probe-suite-failure" in OS.get_cmdline_user_args() and name==selected[0]: check(false,"deliberate_suite_failure")
  print("SUITE %s: %d assertions, %d ms" % [name,count-previous,Time.get_ticks_msec()-started])
  var failed=failures.size()>previous_failures or engine_errors.count()>previous_errors
  print("SUITE RESULT: %s %s" % [name,"FAIL" if failed else "PASS"])
  var runtime_error=engine_errors.count()-previous_errors>failures.size()-previous_failures
  if failed and (runtime_error or "--keep-going" not in OS.get_cmdline_user_args()): break
 if failures.is_empty() and engine_errors.count()==0:
  print("PASS: %d assertions" % count)
  quit(0)
 else:
  print("FAIL: %d/%d assertions; %d engine errors" % [failures.size(),count,engine_errors.count()])
  quit(1)

func _core_cases() -> void:
 var g = Game.new(42)
 check(g.state.hand.size() == 5, "TC-CORE-0001 initial draw")
 check(g.state.deck.size() == 10, "TC-CORE-0001 ten cards")
 var before = JSON.stringify(g.state)
 g.get_view()
 g.command_facts()
 check(JSON.stringify(g.state) == before, "TC-REPLAY-0001 previews do not mutate")
 check(not g.dispatch(g.command({"kind":"card","uid":"not-real"},g.state.version),g.state.version).ok, "TC-CORE-0002 reject forged candidate")
 check(JSON.stringify(g.state) == before, "TC-CORE-0002 rejection atomic")
 var c = g.command_facts()[0]
 check(not g.dispatch(g.command(c.payload,g.state.version - 1),g.state.version - 1).ok, "TC-CORE-0003 reject stale version")
 check(JSON.stringify(g.state) == before, "TC-CORE-0003 stale unchanged")
 check(g.tier(4.0,10.0) == 1 and g.tier(8.0,10.0) == 2, "TC-RESTRAINT-0001 thresholds")
 check(is_equal_approx(g.lower_durability(9.0,10.0),6.0), "TC-RESTRAINT-0002 proportional downgrade")
 check(is_equal_approx(g.lower_durability(6.0,10.0),2.0), "TC-RESTRAINT-0002 tier2 downgrade")
 check(g.lower_durability(2.0,10.0) == 0.0, "TC-RESTRAINT-0002 tier1 removal")
 var a = g.add_fixture("ankle", 8.0, 10.0, true)
 var calc = g.escape_preview(a, "strain", 5.0)
 check(calc.divisor == 1.0, "TC-RESTRAINT-0003 single item has no stack divisor")
 check(calc.lock_multiplier == 0.5, "TC-RESTRAINT-0003 locked strain half")
 check(g.escape_preview(a,"slip",5.0).lock_multiplier == 1.0, "TC-RESTRAINT-0003 lock does not affect slip")
 var other = g.add_fixture("ankle",10.0,10.0,false)
 check(g.escape_preview(a,"strain",5.0).reason != "", "TC-RESTRAINT-0004 force highest target")
 check(is_equal_approx(g.escape_preview(other,"strain",5.0).divisor,1.5), "TC-RESTRAINT-0004 stack divisor")
 check(g.escape_preview(other,"slip",5.0).scaled_damage == 0.0, "TC-RESTRAINT-0005 tier3 slip multiplier damage immune")
 check(g.escape_preview(other,"magic_slip",5.0).damage > 0.0, "TC-RESTRAINT-0005 special slip works")
 _more_tests()
 _architecture_tests()

func _more_tests() -> void:
 var g=Game.new(123)
 var twin=Game.new(123)
 # Lock retention is independent of the new weak enemies, which do not apply locks.
 g.add_fixture("ankle",8,10,true)
 twin.add_fixture("ankle",8,10,true)
 for i in range(4):
  check(JSON.stringify(g.get_view())==JSON.stringify(twin.get_view()),"TC-REPLAY-0002 identical seeded trajectory")
  check(action(g,"end").ok and action(twin,"end").ok,"TC-FLOW-0001 enemy round commits")
 check(g.state.phase=="reward" and g.state.reward_count==1,"TC-FLOW-0001 both departures one reward")
 check(g.state.equipment.size()>=2 and g.state.equipment.any(func(e): return e.locked),"TC-FLOW-0001 equipment and locks persist")
 var retained=g.state.equipment.duplicate(true)
 var motion_log_start=g.state.logs.size()
 check(action(g,"reward",{"type":g.state.reward_options[0]}).ok,"TC-FLOW-0002 reward choice")
 check(action(g,"reward",{"type":"skip"}).ok,"TC-FLOW-0002 continue after pickup")
 check(g.state.deck.size()==11 and g.state.phase=="prepare" and g.state.prepare_left==3,"TC-FLOW-0002 reward enters preparation")
 check(not action(g,"reward",{"type":"brace"}).ok,"TC-FLOW-0002 no duplicate reward")
 g._gain_charge(2)
 g.state.temporary_mana=5
 g.state.mana=73
 for i in range(3): check(action(g,"end").ok,"TC-FLOW-0003 preparation round")
 check(g.state.phase=="map" and g.state.prepare_left==0,"TC-FLOW-0003 three turns then map")
 check(action(g,"depart",{"room":"west"}).ok,"TC-FLOW-0004 select next room")
 while g.state.phase=="travel": check(action(g,"travel_step").ok,"TC-FLOW-0004 travel")
 # Travel retains equipment; any durability changes must come from recorded motion slip.
 for entry in g.state.logs.slice(motion_log_start):
  for hit in entry.get("data",{}).get("passive_slip",{}).get("results",[]):
   for item in retained:
    if item.id==hit.target: item.durability=hit.after
 retained=retained.filter(func(e):return e.durability>0)
 check(g.state.equipment.size()==retained.size(),"TC-FLOW-0004 only logged motion can remove retained equipment")
 for item in retained:
  var current=g._equipment(item.id)
  check(not current.is_empty() and current.template==item.template and current.locked==item.locked and is_equal_approx(current.durability,item.durability),"TC-FLOW-0004 retained identity, lock and logged durability")
 check(g.state.charge==2 and g.state.temporary_mana==5 and g.state.mana==83,"TC-FLOW-0004 preparation end heals once and retains charge and temporary mana within caps")
 check(g.state.deck.size()==11 and g.validate()=="","TC-FLOW-0004 rebuild deck without loss")

 g=Game.new(42)
 for enemy in g.state.enemies:
  var plan=enemy.intent
  check(plan.kind=="apply" and plan.grade==1 and plan.tier==2 and plan.templates==g.Enemies.TYPES[enemy.type].install_pool,"TC-ENEMY-0001 initial declaration preserves allowed source and specification")
 var frozen=g.state.enemies[0].intent.duplicate(true)
 g.state.round=2
 g.state.card_buffs.append("infusion_bound")
 check(action(g,"attack",{"type":"kick","form":2,"enemy":"enemy_1"}).ok,"TC-ENEMY-0002 infused kick interrupt")
 check(action(g,"end").ok,"TC-ENEMY-0002 end interrupted round")
 check(g.state.enemies[0].stage==1 and g.state.enemies[0].intent==frozen,"TC-ENEMY-0002 delayed declaration not rerolled")
 check(not find_action(g,"attack",{"type":"kick","form":2,"enemy":"enemy_1"}).payload.interrupt,"TC-ENEMY-0002 consumed infusion does not grant consecutive interrupt")
 check(action(g,"end").ok and g.state.enemies[0].stage==2,"TC-ENEMY-0002 delayed action executes next round")

 g=Game.new(44)
 check(action(g,"posture",{"dest":"sit","wall":false}).ok,"TC-POSE-0001 sit")
 check(g.state.energy==3 and g.state.order=="first","TC-POSE-0001 free arms discount order fixed")
 check(action(g,"posture",{"dest":"stand","wall":true}).ok,"TC-POSE-0002 wall rising")
 check(g.state.round==1 and g.state.enemies[0].stage==1 and g.state.enemies[1].stage==1,"TC-POSE-0002 wall ascent does not execute enemy phase")
 g=Game.new(44)
 check(action(g,"posture",{"dest":"sit","wall":false}).ok and action(g,"posture",{"dest":"lie","wall":false}).ok,"TC-POSE-0003 adjacent descent")
 check(g.state.order=="first","TC-POSE-0003 lying does not reorder current turn")
 check(action(g,"end").ok and g.state.order=="last" and g.state.round==2,"TC-POSE-0003 next turn late")
 check(g.state.enemies[0].stage==3,"TC-POSE-0003 enemies execute old and new turn")
 check(action(g,"posture",{"dest":"sit","wall":true}).ok,"TC-POSE-0004 late wall rising")
 check(g.state.round==2 and g.state.order=="last" and g.state.enemies[0].stage==3,"TC-POSE-0004 wall ascent preserves late order and enemy progress")

 g=Game.new()
 var e=g.add_fixture("ankle",10)
 check(g.level("legs")==2,"TC-BODY-0001 ankle weight")
 g.add_fixture("ankle",4)
 check(g.level("legs")==2,"TC-BODY-0001 no level from stack")
 for slot in ["thigh","calf","foot"]: g.add_fixture(slot,4)
 check(g.level("legs")==3,"TC-BODY-0002 not all body parts at most three")
 g.add_fixture("toes",4)
 check(g.level("legs")==4,"TC-BODY-0002 full region four")
 check(action(g,"attack",{"type":"kick","enemy":"enemy_1"}).ok and g.state.posture=="lie" and g.state.order=="first","TC-BODY-0003 bound kick fall no reorder")

 g=Game.new()
 # Isolate zero-damage card payment from the rough wall's separate true damage.
 g.state.wall="normal"
 e=g.add_fixture("ankle",10)
 var card=hand_card(g,"slip")
 var energy=g.state.energy
 check(action(g,"card",{"uid":card.uid,"target":e.id}).ok,"TC-CARD-0001 immune slip allowed")
 check(g._equipment(e.id).durability==10 and g.state.energy==energy-1 and g._card(card.uid).is_empty(),"TC-CARD-0001 zero damage still spends card and energy")
 card=hand_card(g,"strain")
 check(action(g,"card",{"uid":card.uid,"slot":"wrist","free":true}).ok and g.state.charge==1,"TC-CARD-0002 free other part builds charge")
 card=hand_card(g,"strain")
 check(action(g,"card",{"uid":card.uid,"target":e.id}).ok and g.state.charge==0 and g._equipment(e.id).durability<10,"TC-CARD-0002 strain consumes charge")

 g=Game.new()
 e=g.add_fixture("eyes",4)
 card=hand_card(g,"strain")
 var unavailable=find_action(g,"card",{"uid":card.uid,"slot":"eyes"})
 var before=JSON.stringify(g.state)
 check(not unavailable.valid and not unavailable.payload.free,"TC-CARD-0003 no route does not mean free")
 check(not g.dispatch(g.command(unavailable.payload,g.state.version),g.state.version).ok and JSON.stringify(g.state)==before,"TC-CARD-0003 disabled rejection atomic")
 check(g.escape_preview(e,"slip",5).reason=="","TC-CARD-0003 eyes allow slip")
 g.add_fixture("mouth",4)
 card=hand_card(g,"ease")
 check(find_action(g,"card",{"uid":card.uid,"slot":"thigh"}).valid,"TC-MAGIC-0001 free preparation ignores mouth penalty")
 check(find_action(g,"attack",{"type":"fireball","enemy":"enemy_1"}).valid and g.cast_view().chance==0.75,"TC-MAGIC-0001 fireball applies mouth chance")
 g.add_fixture("fingers",4)
 card=grant_fixture_card(g,"unlock")
 check(not find_action(g,"card",{"uid":card.uid,"slot":"thigh"}).valid,"TC-MAGIC-0001 unlock needs fingers")

 g=Game.new()
 e=g.add_fixture("ankle",8,10,true)
 card=hand_card(g,"ease")
 check(action(g,"card",{"uid":card.uid,"slot":"thigh","free":true}).ok and g.state.mana==100 and g.state.temporary_mana==10,"TC-MAGIC-0002 reserve without spending mana")
 card=grant_fixture_card(g,"unlock")
 check(action(g,"card",{"uid":card.uid,"target":e.id}).ok,"TC-MAGIC-0003 unlock")
 check(not g._equipment(e.id).locked and g._equipment(e.id).durability==8 and g.state.mana==100 and g.state.energy==2 and g.state.temporary_mana==0,"TC-MAGIC-0003 unlock only changes lock and pays temporary mana with zero energy")

 g=Game.new()
 e=g.add_fixture("ankle",10,10,false,0)
 var outer=g.add_fixture("ankle",2,10,false,1)
 check(g.escape_preview(outer,"slip",5).immune and g.escape_preview(outer,"slip",5).ratio==1,"TC-STACK-0001 outer inherits tightness")
 check(g.escape_preview(e,"slip",5).reason!="","TC-STACK-0001 inner slip blocked")
 check(g.escape_preview(e,"strain",5).reason=="" and g.escape_preview(outer,"strain",5).reason!="","TC-STACK-0001 strain highest inner")
 g=Game.new()
 e=g.add_fixture("ankle",8)
 outer=g.add_fixture("ankle",8)
 check(g.escape_preview(e,"strain",5).reason=="" and g.escape_preview(outer,"strain",5).reason=="","TC-STACK-0002 same-layer tied choices")
 outer.durability=4
 check(g.escape_preview(outer,"slip",5).penalty==0.5,"TC-STACK-0002 nonmaximum slip half")
 outer.slip_allowed=false
 check(g.escape_preview(outer,"magic_slip",5).reason!="","TC-STACK-0003 magic does not bypass structure")

 g=Game.new()
 e=g.add_fixture("ankle",4)
 check(not find_action(g,"manual",{"target":e.id}).valid,"TC-MANUAL-0001 standing cannot reach ankle")
 check(action(g,"posture",{"dest":"sit","wall":false}).ok and action(g,"manual",{"target":e.id}).ok,"TC-MANUAL-0001 sitting remove with free arms")
 check(g._equipment(e.id).is_empty() and g.level("legs")==0,"TC-MANUAL-0001 remove refreshes body")

 g=Game.new()
 g.state.enemies[0].hp=1
 g.state.enemies[1].hp=1
 g.state.mana=80
 check(action(g,"attack",{"type":"strike","enemy":"enemy_1"}).ok and g.state.phase=="battle","TC-FLOW-0005 first kill no reward")
 check(action(g,"attack",{"type":"strike","enemy":"enemy_2"}).ok and g.state.phase=="reward" and g.state.reward_count==1 and g.state.mana==80,"TC-FLOW-0005 last kill gives reward but defers ending relic")
 g.state.reward_options=["inch","brace","magic_slip"] # Specific retain-card fixture; still uses real reward command.
 check(action(g,"reward",{"type":"inch"}).ok,"TC-RETAIN-0001 obtain retain card")
 check(action(g,"reward",{"type":"skip"}).ok,"TC-RETAIN-0001 continue after pickup")
 card=hand_card(g,"inch")
 check(action(g,"card",{"uid":card.uid,"slot":"thigh"}).ok and g.state.pending_retain,"TC-RETAIN-0001 choose retain after drawing")
 var kept=g.state.hand[0].uid
 check(action(g,"retain",{"uid":kept}).ok,"TC-RETAIN-0001 retain selection")
 check(action(g,"end").ok and not g._card(kept).is_empty(),"TC-RETAIN-0002 retained into next turn")
 # A normal next-turn draw can reshuffle the discard. Stop at the last preparation end to observe it.
 g.state.prepare_left=1
 check(action(g,"end").ok and g.state.discard.any(func(x): return x.uid==kept and x.retain_until==-1),"TC-RETAIN-0002 discarded at next end")

 for seed_value in range(20):
  g=Game.new(seed_value)
  for i in range(4): action(g,"end")
  check(g.state.phase=="reward" and g.validate()=="","TC-SIM-0001 multi-seed passive encounter %d" % seed_value)

 g=Game.new()
 g.add_fixture("wrist",4)
 g.state.charge=1
 var strike=find_action(g,"attack",{"type":"strike","enemy":"enemy_1"})
 check(g.level("arms")==2 and is_equal_approx(strike.payload.damage,8.8),"TC-CHARGE-0001 base and charge bonus use level-two body restriction")
 check(action(g,"attack",{"type":"strike","enemy":"enemy_1"}).ok and g.state.charge==0,"TC-CHARGE-0001 one charge consumed")

 g=Game.new()
 g.state.enemies[0].gone=true
 var final_enemy=g.state.enemies[1]
 final_enemy.stage=3;final_enemy.intent=g._plan(final_enemy)
 check(final_enemy.intent.kind=="charge","TC-ENEMY-0003 final preparation announces charge")
 check(action(g,"end").ok and g.state.enemies[1].intent.kind=="apply" and g.state.enemies[1].intent.grade==2 and g.state.enemies[1].intent.tier==3,"TC-ENEMY-0003 preparation advances to middle-grade tier-three final application")
 check(action(g,"end").ok and g.state.phase=="reward","TC-ENEMY-0003 final attachment leaves once")
 var alternative

 g=Game.new()
 e=g.add_fixture("wrist",4)
 alternative=g.add_fixture("wrist",4)
 var wrist_view=g.get_view().bodies.filter(func(b): return b.id=="wrist")[0]
 check(wrist_view.equipment[0].name!=wrist_view.equipment[1].name,"TC-UI-0001 same-slot equipment distinguished")
 _route_tests()
 _rest_tests()

# Boundary fixture isolates rest/travel from the full climb tested below.
func enter_rest(g) -> void:
 var target="rest"
 var parent=g.state.rooms.filter(func(r):return target in r.next)[0]
 g._discard_end();g.state.room=parent.id;g.state.phase="map";g.state.completed_rooms=[parent.id]
 action(g,"depart",{"room":target})
 while g.state.phase=="travel": action(g,"travel_step")
 action(g,"rest_begin")

func _rest_tests() -> void:
 var g=Game.new()
 enter_rest(g)
 check(g.state.phase=="rest" and g.state.rest_left==6 and g.state.hook_uses==3,"REST reachable from genuine route")
 check(g.state.reward_count==0 and g.state.enemies.is_empty(),"REST no battle reward or enemies")
 g.state.mana=43
 var exhausted=g.state.hand.pop_back()
 g.state.exhaust.append(exhausted)
 for c in g.command_facts():
  if c.group=="card" and c.payload.free: check(not c.valid,"REST all free branches blocked")
 for i in range(6): check(action(g,"end").ok,"REST finite turn advances")
 check(g.state.phase=="map" and g.state.rest_left==0 and g.state.mana==43,"REST exactly six turns without battle-ending recovery")
 check(g.state.exhaust.any(func(c):return c.uid==exhausted.uid),"REST exhausted cards not restored")
 check(not action(g,"rest_flask").ok,"REST choices are unavailable after exit")

 g=Game.new()
 g.state.room="rest"
 g._start_rest();action(g,"rest_begin")
 var target=g.add_fixture("wrist",10,10,true)
 var energy=g.state.energy
 check(action(g,"hook",{"target":target.id}).ok,"HOOK tier three can be reduced")
 check(is_equal_approx(g._equipment(target.id).durability,8) and g._equipment(target.id).locked and g.state.energy==energy,"HOOK one tier proportional no energy or lock removal")
 check(action(g,"hook",{"target":target.id}).ok and is_equal_approx(g._equipment(target.id).durability,4),"HOOK tier two to one")
 check(action(g,"hook",{"target":target.id}).ok and g._equipment(target.id).is_empty() and g.state.hook_uses==0,"HOOK tier one removed third use")
 check(action(g,"end").ok and g.state.hook_uses==0,"HOOK charges do not refresh per turn")
 g._gain_card("brace") # Isolate the existing bound-face secondary effect.


 target=g.add_fixture("wrist",10)
 var brace=hand_card(g,"brace")
 check(action(g,"card",{"uid":brace.uid,"target":target.id}).ok and g.state.charge==1,"REST bound card secondary buff allowed")

 g=Game.new()
 g.state.room="rest"; g._start_rest();action(g,"rest_begin")
 target=g.add_fixture("eyes",4)
 target.slip_allowed=false
 var before=JSON.stringify(g.state)
 check(not action(g,"hook",{"target":target.id}).ok and JSON.stringify(g.state)==before,"HOOK structural prohibition costs nothing")
 target.slip_allowed=true
 g.state.posture="sit"
 check(find_action(g,"hook",{"target":target.id}).valid,"HOOK seated eyes reach fixed mid-height hook")
 g.state.posture="lie"
 check(not find_action(g,"hook",{"target":target.id}).valid,"HOOK lying cannot reach eyes")
 var foot=g.add_fixture("ankle",9)
 check(action(g,"hook",{"target":foot.id}).ok and is_equal_approx(g._equipment(foot.id).durability,6),"HOOK lying ankle preserves position within tier")
 var outer=g.add_fixture("ankle",4,10,false,1)
 check(not find_action(g,"hook",{"target":foot.id}).valid,"HOOK cannot bypass outer layer")

 g=Game.new()
 g.state.room="rest"; g._start_rest();action(g,"rest_begin")
 target=g.add_fixture("wrist",10,10,true)
 g._gain_tool("shard")
 var item=g.state.items[0]
 check(not find_action(g,"item_use",{"item":item.id,"target":target.id}).valid,"TOOL carried tool cannot cut shared wrist restraint")
 check(action(g,"item_install",{"item":item.id,"mount":"hand_wall"}).ok and g.state.energy==2,"TOOL installation costs one energy")
 check(g._item(item.id).uses==3 and g.carried_items()==0,"TOOL installation neither uses charge nor carry slot")
 var tool_card=hand_card(g,"strain")
 var tool_action=find_action(g,"card",{"uid":tool_card.uid,"target":target.id})
 var card_damage=tool_action.payload.preview.damage
 check(g.dispatch(g.command(tool_action.payload,g.state.version),g.state.version).ok,"TOOL installed cut requires a card")
 check(is_equal_approx(g._equipment(target.id).durability,10-card_damage-5) and g._equipment(target.id).locked and g._item(item.id).uses==2 and g.state.energy==1,"TOOL fixed bonus ignores lock and tightness")
 tool_card=hand_card(g,"strain")
 check(action(g,"card",{"uid":tool_card.uid,"target":target.id}).ok and g._equipment(target.id).is_empty(),"TOOL next card removes target")
 check(not action(g,"rest_card",{"type":"brace"}).ok,"SERVICE cannot claim card after tool and escape")
 check(action(g,"item_retrieve",{"item":item.id}).ok and g.carried_items()==1 and g._item(item.id).uses==1,"TOOL retrieve preserves remaining charge")
 check(action(g,"finish_rest").ok and action(g,"depart",{"room":g.room_data("rest").next[0]}).ok,"REST early departure")
 while g.state.phase=="travel": action(g,"travel_step")
 check(g.state.phase=="battle" and g._item(item.id).uses==1,"TOOL carried uses persist into battle")
 check(g.validate()=="","REST tool state valid")

 g=Game.new(); g.state.room="rest"; g._start_rest();action(g,"rest_begin")
 target=g.add_fixture("thigh",10)
 g._gain_tool("saw")
 item=g.state.items[0]
 check(action(g,"item_use",{"item":item.id,"target":target.id}).ok and g._equipment(target.id).durability==3,"TOOL saw has own fixed amount")
 check(action(g,"item_use",{"item":item.id,"target":target.id}).ok and g.state.items.is_empty(),"TOOL used up removed")

 g=Game.new(); g.state.room="rest"; g._start_rest();action(g,"rest_begin")
 target=g.add_fixture("thigh",10)
 g._gain_tool("shard")
 item=g.state.items[0]
 action(g,"item_install",{"item":item.id,"mount":"hand_wall"})
 action(g,"finish_rest")
 action(g,"depart",{"room":g.room_data("rest").next[0]})
 check(g.state.items.is_empty(),"TOOL mounted tool left behind on departure")

 g=Game.new(); g.state.room="rest"; g._start_rest();action(g,"rest_begin")
 g.add_fixture("fingers",4)
 for slot in ["ankle","foot"]: g.add_fixture(slot,4)
 g.state.items=[{"id":"a","type":"shard","mount":"carry","uses":3},{"id":"b","type":"saw","mount":"carry","uses":2}]
 check(g.item_capacity()==1 and action(g,"finish_rest").ok and g.state.phase=="pack","PACK over capacity opens choice")
 check(not action(g,"finish_pack").ok,"PACK cannot leave overloaded")
 check(action(g,"item_discard",{"item":"a"}).ok and action(g,"finish_pack").ok and g.state.phase=="map","PACK choose allowed items then leave")

func _route_tests() -> void:
 var g=Game.new()
 check(g.movement_profile().speed==5 and g.movement_profile().turns==1,"TRAVEL free standing")
 g.add_fixture("thigh",4)
 check(g.level("legs")==1 and g.movement_profile().turns==2,"TRAVEL thigh two turns")
 g.state.equipment.clear()
 g.add_fixture("calf",4)
 check(g.level("legs")==1 and g.movement_profile().turns==3,"TRAVEL calf differs despite same level")
 g.add_fixture("ankle",4)
 check(g.movement_profile().turns==5,"TRAVEL ankle five turns")
 for pose in ["sit","lie"]:
  g.state.posture=pose
  check(g.movement_profile().turns==10,"TRAVEL nonstanding always moves")
 g.state.posture="stand"
 for slot in ["thigh","foot","toes"]: g.add_fixture(slot,4)
 check(g.level("legs")==4 and g.movement_profile().speed==1,"TRAVEL full leg restriction never blocks")

 g=Game.new()
 # Arrival boundary fixture chooses a battle, independent of random room distribution.
 var east=g.room_data("east");east.kind="battle";east.pool="ordinary";east.wall="normal"
 east.encounter_choices={"weak":"rope_solo","strong":"double_rope"};g.state.room_encounters.east="rope_solo"
 finish_room(g)
 # Isolate travel timing from the separately tested passive slip mechanism.
 # Ankles have no movement-slip coefficient; the lock must survive transit.
 g.state.equipment.clear()
 g.add_fixture("ankle",8,10,true)
 g.state.posture="lie"
 g.state.next_energy=2
 g.state.charge=3
 g.state.temporary_mana=10
 g.state.mana=67
 var cards=JSON.stringify([g.state.draw,g.state.hand,g.state.discard,g.state.exhaust])
 var tick=g.state.tick
 var random_state=JSON.stringify(g.state.rng)
 var equipment=JSON.stringify(g.state.equipment)
 check(action(g,"depart",{"room":"east"}).ok and g.state.journey.total==10,"TRAVEL locks duration on departure")
 var before=JSON.stringify(g.state)
 check(not action(g,"depart",{"room":"west"}).ok and not action(g,"posture",{"dest":"sit"}).ok,"TRAVEL cannot change destination or act")
 check(JSON.stringify(g.state)==before,"TRAVEL invalid action unchanged")
 for i in range(9): check(action(g,"travel_step").ok,"TRAVEL step advances")
 check(g.state.travel_turns==9 and g.state.tick==tick and g.state.energy==0 and g.state.next_energy==2,"TRAVEL not a player turn")
 check(g.state.mana==67 and g.state.charge==3 and g.state.temporary_mana==10 and JSON.stringify(g.state.equipment)==equipment,"TRAVEL does not alter resources or equipment")
 check(JSON.stringify([g.state.draw,g.state.hand,g.state.discard,g.state.exhaust])==cards and JSON.stringify(g.state.rng)==random_state,"TRAVEL no draw shuffle or random")
 check(action(g,"travel_step").ok and g.state.room=="east" and g.state.phase=="battle" and g.state.wall==g.room_data("east").wall,"TRAVEL enters configured single-enemy room")
 check(g.state.energy==5 and g.state.next_energy==0 and g.state.order=="last","TRAVEL arrival starts genuine player round")
 check(g._wall_bonus()==0,"TRAVEL lying never gets wall stat bonus")

 for branch in ["east","west"]:
  g=Game.new(77)
  finish_room(g)
  var snapshot=JSON.stringify(g.state)
  check(not action(g,"depart",{"room":g.room_data("rest").next[0]}).ok and JSON.stringify(g.state)==snapshot,"ROUTE cannot skip room")
  for destination in [branch]:
   check(action(g,"depart",{"room":destination}).ok,"ROUTE valid edge "+destination)
   while g.state.phase=="travel": action(g,"travel_step")
   finish_room(g)
  while g.state.phase=="map":
   var next=g.room_data(g.state.room).next
   var destination=next[0] if branch=="east" else next[-1]
   check(action(g,"depart",{"room":destination}).ok,"ROUTE long tower valid edge")
   while g.state.phase=="travel": action(g,"travel_step")
   if g.state.phase=="rest_choice": action(g,"rest_begin")
   if g.state.phase=="rest": action(g,"finish_rest")
   else: finish_room(g)
   finish_packing(g)
  var outcome={"branch":branch,"phase":g.state.phase,"room":g.state.room,"round":g.state.round,"mana":g.state.mana,"energy":g.state.energy,"posture":g.state.posture,"rooms":g.state.completed_rooms.size(),"encounters":g.state.encounter,"rewards":g.state.reward_count,"enemies":g.state.enemies.map(func(e):return {"type":e.type,"hp":e.hp,"gone":e.gone,"stage":e.stage})}
  check(g.state.phase=="cleared" and g.state.reward_count==g.state.encounter and g.state.encounter+g.state.completed_rooms.filter(func(id):return g.room_data(id).kind=="event").size()>=8,"ROUTE long run completes with one reward per fight "+JSON.stringify(outcome))
  check(g.state.completed_rooms.size()==17 and g.command_facts().all(func(c):return c.payload.kind in ["demo_end","demo_continue","item_discard"]),"ROUTE no repeat rewards or rooms including summit")
  check(g.validate()=="","ROUTE final state valid")

func finish_room(g) -> void:
 if g.state.phase=="departure": action(g,"departure",{"op":"skip"})
 if g.state.phase=="rest_choice": action(g,"rest_begin")
 if g.state.phase in ["shop","treasure"]:
  check(action(g,"service",{"op":"leave"}).ok,"ROUTE service room permits departure without purchase")
 if g.state.phase=="rest": action(g,"finish_rest")
 if g.state.phase=="event":
  for step in range(30):
   if g.state.phase!="event": break
   var next=preload("res://tests/route_driver.gd").event_action(g.command_facts())
   check(not next.is_empty(),"ROUTE event has an available step, including events without refusal")
   if next.is_empty(): break
   check(g.dispatch(g.command(next.payload,g.state.version),g.state.version).ok,"ROUTE submits the event's real step and cost")
  check(g.state.phase!="event","ROUTE event resolves before travel")
 var guard=0
 while g.state.phase=="battle" and guard<30:
  guard+=1
  if g.state.energy==0:
   check(action(g,"end").ok,"ROUTE exhausted energy advances through a real turn")
   continue
  if preload("res://tests/route_driver.gd").shorten_persistent_enemies(g):
   var attack=preload("res://tests/route_driver.gd").attack(g)
   if attack.is_empty():
    check(action(g,"end").ok,"ROUTE exhausted usable attacks advance a real turn even with energy left")
    continue
   check(g.dispatch(g.command(attack.payload,g.state.version),g.state.version).ok,"ROUTE actual attack defeats persistent enemy fixture")
  else: action(g,"end")
 if g.state.phase=="reward":
  for category in ["item","relic"]:
   var pickup=find_action(g,"reward",{"category":category},true)
   if pickup.has("id"): check(g.dispatch(g.command(pickup.payload,g.state.version),g.state.version).ok,"ROUTE collects dropped loot through its real reward candidate")
  if not g.state.relic_bundle.is_empty():
   check(action(g,"relic_bundle",{"op":"finish"}).ok,"ROUTE resolves nested relic choices before continuing the parent reward")
  check(action(g,"reward",{"type":"skip"}).ok,"ROUTE continues the parent reward through its real command")
 for i in range(20):
  var preparation=preload("res://tests/route_driver.gd").prepare_action(g)
  if preparation.is_empty(): break
  check(g.dispatch(g.command(preparation.payload,g.state.version),g.state.version).ok,"ROUTE uses real preparation to clear mouth for later encounters")
 if g.state.phase=="prepare": action(g,"finish_prepare")
 finish_packing(g)

func finish_packing(g) -> void:
 while g.state.phase=="pack":
  var choice=preload("res://tests/route_driver.gd").packing_action(g)
  check(not choice.is_empty(),"ROUTE packing has a legal next action")
  if choice.is_empty(): return
  var result=g.dispatch(g.command(choice.payload,g.state.version),g.state.version)
  check(result.ok,"ROUTE discards excess drops through the real packing action" if choice.payload.kind=="item_discard" else "ROUTE completes actual item packing before travel")
  if not result.ok: return

func find_action(g, kind: String, extra: Dictionary = {}, usable_only: bool=false) -> Dictionary:
 for c in g.command_facts():
  if c.payload.kind!=kind or (usable_only and not c.valid): continue
  var matches=true
  for k in extra:
   if c.payload.get(k)!=extra[k]: matches=false
  if matches: return c
 return {"valid":false,"payload":{}}

func _architecture_tests() -> void:
 var g=Game.new(71)
 g.add_fixture("wrist",4)
 # Deep read-only/alias coverage belongs to architecture_cases.projection_contract.
 var strike=find_action(g,"attack",{"type":"strike","enemy":"enemy_1"})
 var damage=strike.payload.damage
 strike.payload.damage=999
 strike.cost=0
 var hp=g._enemy("enemy_1").hp
 check(g.dispatch(g.command(strike.payload,g.state.version),g.state.version).ok and is_equal_approx(g._enemy("enemy_1").hp,hp-damage),"VIEW modified display payload cannot override committed damage")
 check(g.state.energy==2,"VIEW modified display cost cannot override resource charge")
 for phase in ["battle","prepare","rest"]:
  g=Game.new(42)
  if phase=="prepare":
   while g.state.phase=="battle": action(g,"end")
   action(g,"reward",{"type":"skip"})
  elif phase=="rest": enter_rest(g)
  g.state.next_energy=2
  g.state.mana=43
  var tick=g.state.tick
  var rounds=g.state.round
  var timer=g.state.prepare_left if phase=="prepare" else g.state.rest_left
  check(action(g,"end").ok,"TURN shared boundary accepts end in "+phase)
  check(g.state.tick==tick+1 and g.state.energy==5 and g.state.next_energy==0,"TURN bonus consumed once in "+phase)
  check(g.state.mana==43,"TURN does not restore mana in "+phase)
  if phase=="battle": check(g.state.round==rounds+1,"TURN battle advances combat counter")
  else: check((g.state.prepare_left if phase=="prepare" else g.state.rest_left)==timer-1 and g.state.round==rounds,"TURN preparation timer independent of combat in "+phase)
  check(action(g,"end").ok and g.state.energy==3,"TURN next round does not repeat bonus in "+phase)
  check(g.validate()=="","TURN card conservation after shared boundary in "+phase)

func grant_fixture_card(g, type: String) -> Dictionary:
 # Tests of non-starter cards declare the extra fixture explicitly.
 if not g.state.deck.any(func(card):return card.type==type): g._gain_card(type)
 return hand_card(g,type)

func hand_card(g, type: String) -> Dictionary:
 for c in g.state.hand:
  if c.type==type: return c
 for zone in ["draw","discard","exhaust"]:
  for c in g.state[zone]:
   if c.type==type:
    g.state[zone].erase(c)
    g.state.hand.append(c)
    return c
 push_error("Missing fixture card "+type)
 return {}
