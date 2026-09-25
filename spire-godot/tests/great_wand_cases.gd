extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func setup():
 var g=Game.new(42);g._discard_end();g.state.relics=[];g.state.energy=100;g.state.mana=40
 g.RelicEffects.gain(g,"great_wand")
 return g

static func run(t) -> void:
 var g=setup()
 t.check(g.Relics.TYPES.great_wand.rarity=="uncommon" and "great_wand" in g.Relics.REWARDS and g.RelicEffects.counter(g,"great_wand").text=="0","WAND uncommon reward relic starts with visible zero counter")
 var c=t.find_action(g,"relic_discharge",{"relic":"great_wand"});var before=g.export_snapshot()
 t.check(g.candidate_detail(c)==g.Relics.TYPES.great_wand.detail and g.copy_router_failures.is_empty(),"WAND candidate copy uses its registered relic route without fallback failure")
 t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"WAND zero points cannot create a free action")
 for n in range(14):
  t.check(Cards.play(t,g,"strain",true).ok and g.state.relic_counters.great_wand==n+1 and g.state.mana==40,"WAND each successful skill adds exactly one point without early recovery")
 before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and g.RelicEffects.counter(g,"great_wand").value==14,"WAND queries and counter view cannot mutate progress")
 c=t.find_action(g,"relic_discharge",{"relic":"great_wand"})
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"WAND stale exchange leaves counter and mana intact")
 var restored=Save.roundtrip(t,g,"great wand at fourteen")
 if restored!=null: t.check(restored.state.relic_counters.great_wand==14,"WAND current save keeps charge")
 t.check(Cards.play(t,g,"strain",true).ok and g.state.relic_counters.great_wand==0 and g.state.mana==55,"WAND fifteenth skill automatically restores fifteen mana and clears points")
 t.check(g.state.logs.back().data.has("player_action") and g.state.logs.any(func(x):return x.data.get("relic_discharge",{}).get("points",0)==15),"WAND automatic exchange emits actual relic feedback")
 for n in range(3): Cards.play(t,g,"strain",true)
 var energy=g.state.energy;var tick=g.state.tick;var round_number=g.state.round;var mana=g.state.mana
 t.check(t.action(g,"relic_discharge",{"relic":"great_wand"}).ok and g.state.mana==mana+3 and g.state.relic_counters.great_wand==0,"WAND manual exchange restores current points and clears once")
 t.check(g.state.energy==energy and g.state.tick==tick and g.state.round==round_number,"WAND manual exchange spends no energy or turn")
 before=g.export_snapshot()
 t.check(not t.action(g,"relic_discharge",{"relic":"great_wand"}).ok and g.state==before,"WAND repeated exchange at zero is atomically refused")
 g=setup();g.state.mana=99
 for n in range(15): Cards.play(t,g,"strain",true)
 t.check(g.state.mana==100 and g.state.relic_counters.great_wand==0,"WAND automatic exchange respects mana cap and consumes all points")
 Cards.play(t,g,"strain",true)
 t.check(t.action(g,"relic_discharge",{"relic":"great_wand"}).ok and g.state.mana==100 and g.state.relic_counters.great_wand==0,"WAND deliberate exchange at full mana also clears points")
 g=setup();Cards.play(t,g,"siphon",false);Cards.play(t,g,"formation",false)
 t.check(g.state.relic_counters.get("great_wand",0)==0,"WAND magic and power cards do not charge")
 Cards.play(t,g,"echo_cast",false)
 var target=g.add_fixture("wrist",10)
 var card=Cards.give(g,"strain")
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id,"free":false}).ok and g.state.relic_counters.great_wand==2,"WAND original skill counts once despite effect replay")
 card=Cards.give(g,"pot_of_greed");g.state.energy=0
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.relic_counters.great_wand==3,"WAND zero-energy skill also counts")
 card=Cards.give(g,"strain");before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"WAND insufficient energy cannot add points")
 g=setup();Cards.play(t,g,"strain",true)
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.relic_counters.great_wand==1,"WAND charge survives player turn boundary")
 g.RelicEffects.end_combat(g);g.RelicEffects.begin_combat(g)
 t.check(g.state.relic_counters.great_wand==1,"WAND charge survives scene cleanup and new combat")
 g=setup()
 for invalid in [-1,15,16,"2"]:
  var saved=g.export_snapshot();saved.relic_counters.great_wand=invalid;before=g.export_snapshot()
  t.check(not g.restore_snapshot(saved).ok and g.state==before,"WAND malformed or unsettled counter is rejected on restore")
 g.state.relic_counters.great_wand=2;g.state.relics.erase("great_wand")
 t.check(g.RelicEffects.validate(g)!="" and not g.command_facts().any(func(x):return x.payload.kind=="relic_discharge"),"WAND no owned relic means no action and no valid counter")
