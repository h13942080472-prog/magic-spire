extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Rewards=preload("res://tests/reward_cases.gd")
const LogCases=preload("res://tests/rolling_log_cases.gd")

static func run(t) -> void:
 pleasure_extractor(t)
 pendant(t)
 cloak(t)
 fallback(t)

static func pleasure_extractor(t) -> void:
 var P=preload("res://core/pressure.gd")
 var g=Game.new(42);g.state.relics=[];g.state.flask_mana=7
 P.gain(g,100,"fixture",true)
 t.check(g.state.flask_mana==7,"EXTRACTOR climax without the relic never fills the flask")
 g=Game.new(42);g.state.relics=[];g.state.flask_mana=7;g.state.mana=50;g.state.temporary_mana=3;g.state.flask_deposits=2
 g.RelicEffects.gain(g,"pleasure_extractor")
 t.check(g.state.flask_mana==7 and g.Relics.TYPES.pleasure_extractor.rarity=="uncommon","EXTRACTOR uncommon pickup grants no immediate mana")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"EXTRACTOR queries never trigger the reward")
 P.gain(g,99,"fixture",true)
 t.check(g.state.flask_mana==7,"EXTRACTOR pressure below the threshold gives no mana")
 P.gain(g,1,"fixture",true)
 t.check(g.state.flask_mana==17 and g.state.mana==30 and g.state.temporary_mana==3 and g.state.flask_deposits==2,"EXTRACTOR adds ten only to flask, preserving normal loss and deposit quota")
 P.gain(g,200,"fixture",true)
 t.check(g.state.flask_mana==37 and g.state.overload_total==3,"EXTRACTOR batched climaxes grant ten per occurrence")
 var saved=g.export_snapshot();var twin=Game.new(42)
 t.check(twin.restore_snapshot(saved).ok and twin.state.flask_mana==37,"EXTRACTOR restored flask balance does not replay the trigger")
 for phase in ["battle","prepare","rest","prison","event"]:
  g=Game.new(42,true,"prison_test") if phase=="prison" else Game.new(42)
  g.state.phase=phase;g.state.relics=["pleasure_extractor"];g.state.flask_mana=1000;g.state.mana=0
  P.scripted_climax(g,"fixture")
  t.check(g.state.flask_mana==1010 and g.state.mana==0,"EXTRACTOR scripted climax fills flask even above personal cap with zero mana: "+phase)
  t.check(g.state.logs[-1].data.get("overloads",0)==1 and g.state.logs[-1].data.get("scripted_climax",{}).get("source","")=="fixture","EXTRACTOR scripted marker remains on the climax receipt: "+phase)
 g=Game.new(42);g.state.relics=["pleasure_extractor"];g.state.flask_mana=0
 g._install_special("negative_plate_lock_catheter_medium","special_2_a")
 P.gain(g,P.maximum(g),"fixture",true)
 t.check(g.state.slip_ejaculation_turns==2 and g.state.flask_mana==10,"EXTRACTOR deferred-loss climax shares the same trigger")
 g=Game.new(42);g.state.relics=["pleasure_extractor"];g.state.flask_mana=0;g.state.pressure=99
 g.state.pressure_sources=[preload("res://tests/pressure_cases.gd").source("extractor_fixture","turn_end",5)]
 for enemy in g.state.enemies: enemy.intent.delayed=true
 var action=t.find_action(g,"end");var version=g.state.version
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(action.payload,version-1),version-1).ok and g.state==before,"EXTRACTOR rejected turn cannot trigger a reward")
 t.check(g.dispatch(g.command(action.payload,version),version).ok and g.state.flask_mana==10,"EXTRACTOR formal turn commits automatic flask gain")
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(action.payload,version),version).ok and g.state==before,"EXTRACTOR duplicate turn cannot repeat flask gain")
 g=Game.new(42);g.state.relics=[]
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="pleasure_extractor")
 t.check(LogCases.offer_tier(g,"uncommon",excluded)=="pleasure_extractor","EXTRACTOR is available through the shared uncommon reward pool")

static func pendant(t) -> void:
 var g=Rewards.setup();g.state.relics=[];g.state.mana=20
 g.RelicEffects.gain(g,"ethereal_pendant")
 for turn in range(3):
  t.check(t.action(g,"end").ok and g.state.mana==21+turn,"PENDANT every completed preparation turn restores one, including the last")
 g=Rewards.setup();g.state.relics=["ethereal_pendant"];g.state.mana=20
 t.check(t.action(g,"finish_prepare").ok and g.state.mana==20,"PENDANT early finish does not restore unplayed turns")
 g=Rewards.setup();g.state.relics=["ethereal_pendant"];g.state.mana=g.state.mana_max-0.5
 t.check(t.action(g,"end").ok and g.state.mana==g.state.mana_max,"PENDANT ordinary restoration respects the mana cap")
 t.check(t.action(g,"end").ok and g.state.mana==g.state.mana_max,"PENDANT full mana never overflows")
 for phase in ["battle","prison","rest"]:
  g=Game.new(42);g.state.relics=["ethereal_pendant"];g.state.phase=phase;g.state.mana=20
  g.RelicEffects.end_turn(g)
  t.check(g.state.mana==20,"PENDANT other turn phases never trigger: "+phase)

static func cloak(t) -> void:
 var g=Game.new(42);g.state.relics=[]
 var specs=g.Cards.Rules.SPECS
 var baseline={}
 for type in specs:
  for free in [false,true]: baseline[type+str(free)]=g.Cards.face_mana(g,type,free)
 for i in range(2): g.RelicEffects.gain(g,"intellect_cloak")
 t.check(g.state.relics.count("intellect_cloak")==1 and g.RelicEffects.counter(g,"intellect_cloak").value==2,"CLOAK repeated pickup stores two stacks with one icon")
 for type in specs:
  for free in [false,true]:
   var expected=baseline[type+str(free)]
   if "magic" in g.Cards.Rules.type_tags(type,free) and not specs[type].has("all_mana_minimum"): expected=maxf(0,expected-2)
   t.check(is_equal_approx(g.Cards.face_mana(g,type,free),expected),"CLOAK shared face cost covers all magic tags and leaves nonmagic unchanged: "+type+str(free))
 g.state.pressure=75
 t.check(is_equal_approx(g.Cards.face_mana(g,"mana_surge",false),maxf(0,g._mana_cost(5)-2)),"CLOAK flat reduction is applied after existing multipliers")
 g.state.pressure=0;g.state.mana=20;g.state.temporary_mana=1
 var card=Rewards.give(t,g,"mana_surge")
 var action=t.find_action(g,"card",{"uid":card.uid,"free":false})
 t.check(action.valid and action.mana==3 and action.mana_payment.temporary_mana==1 and action.mana_payment.mana==2,"CLOAK candidate payment matches discounted face cost")
 var version=g.state.version
 t.check(g.dispatch(g.command(action.payload,version),version).ok and g.state.mana==18 and g.state.temporary_mana==0,"CLOAK formal card play pays only the discounted total")
 var saved=g.export_snapshot();var twin=Game.new(42)
 t.check(twin.restore_snapshot(saved).ok and twin.Cards.face_mana(twin,"mana_surge",false)==3,"CLOAK stacked reduction survives snapshot restoration")
 t.check(not g.dispatch(g.command(action.payload,version),version).ok and g.state==saved,"CLOAK stale card cannot spend discounted mana twice")
 for i in range(4): g.RelicEffects.gain(g,"intellect_cloak")
 t.check(g.Cards.face_mana(g,"mana_surge",false)==0 and g.Cards.face_mana(g,"mana_surge",true)==0,"CLOAK over-discounted and zero-cost faces remain zero")
 g.state.mana=0;g.state.temporary_mana=0
 card=Rewards.give(t,g,"mana_surge")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.mana==0,"CLOAK zero-mana discounted card is playable without generating mana")
 var attacks=g.attack_facts()
 t.check(attacks.filter(func(c):return c.payload.type=="fireball").all(func(c):return c.mana==g._mana_cost(g.B.SPELL_COST)),"CLOAK basic fireball is not a card and keeps its mana cost")
 var PrisonCases=preload("res://tests/prison_cases.gd")
 g=PrisonCases.intake(t);PrisonCases.clear_fixture(g)
 preload("res://tests/exploration_fixture.gd").at_site(g,"door")
 g.state.posture="stand";g.state.pressure=0;g.state.mana=9;g.state.temporary_mana=0
 g.RelicEffects.gain(g,"intellect_cloak")
 card=t.grant_fixture_card(g,"unlock")
 action=t.find_action(g,"prison",{"action":"unlock","uid":card.uid})
 t.check(action.valid and action.mana==9 and action.mana==g.Cards.face_mana(g,"unlock",false),"CLOAK prison door shares the card cost and allows exact discounted payment")
 t.check(g.dispatch(g.command(action.payload,g.state.version),g.state.version).ok and g.state.prison.door_open and g.state.mana==0,"CLOAK formal prison spell opens the door using discounted mana")

static func fallback(t) -> void:
 var g=Game.new(42)
 g.state.relics=g.Relics.REWARDS.duplicate()
 for i in range(3):
  t.check(LogCases.offer_tier(g,"common")=="intellect_cloak","CLOAK common exhaustion remains repeatable")
  g.RelicEffects.gain(g,"intellect_cloak")
 t.check(g.state.relic_counters.intellect_cloak==4,"CLOAK exhausted pool copies stack on the original copy")
 for tier in ["uncommon","rare"]: t.check(LogCases.offer_tier(g,tier)=="rolling_log","CLOAK does not replace other tiers: "+tier)
 g.RelicEffects.gain(g,"nesting_doll")
 t.check(g.RelicBundle.validate(g,g.state)=="" and g.state.relic_bundle.entries[0].type=="intellect_cloak","CLOAK owned common fallback remains valid in nesting doll")
 t.check(t.action(g,"relic_bundle",{"op":"claim","index":0}).ok and g.state.relic_counters.intellect_cloak==5,"CLOAK nesting doll claims another copy through the formal action")
 var saved=g.export_snapshot();var bad=saved.duplicate(true);bad.relic_counters.intellect_cloak=0
 t.check(not g.restore_snapshot(bad).ok and g.state==saved,"CLOAK invalid stack count is rejected atomically")
