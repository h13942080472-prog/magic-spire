extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func run(t) -> void:
 var g=Game.new(42);var card=Cards.give(g,"adaptability")
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(c.valid and c.cost==1 and c.mana==0 and g.state==before,"ADAPT one-energy uncommon power previews without side effects")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"ADAPT stale activation leaves card and resources intact")
 g.state.energy=0;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"ADAPT insufficient energy rejects without activation")
 g.state.energy=3
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.temporary_mana==0 and g.state.energy==2 and g.state.powers[0].uid==card.uid,"ADAPT activation waits until next turn and enters power zone")
 g.state.temporary_mana=100
 var result=t.action(g,"end")
 t.check(result.ok and g.state.temporary_mana==105 and g.state.mana==100,"ADAPT first real turn start grants five to uncapped pool")
 t.check(result.resource_feedback.any(func(e):return e.field=="temporary_mana" and e.after-e.before==5),"ADAPT turn grant uses resource animation receipt")
 card=Cards.give(g,"adaptability");before=g.export_snapshot()
 c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 t.check(c.valid and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"ADAPT repeat is available but stale activation preserves state")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.charge==0 and g.state.powers.size()==2,"ADAPT opposite face coexists without immediate charge")
 var twin=Save.roundtrip(t,g,"both adaptability faces")
 if twin!=null: Save.step_both(t,g,twin,"end")
 t.check(g.state.temporary_mana==110 and g.state.charge==1,"ADAPT each active face triggers exactly once at next turn")
 before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and g.get_view().statuses.any(func(row):return row.id=="power_adaptability_free" and row.detail.contains("5点")),"ADAPT repeated projection never grants resources and status shows amount")
 g.RelicEffects.end_combat(g)
 t.check(g.state.powers.is_empty() and g.state.temporary_mana==20 and g.state.charge==1,"ADAPT cleanup removes abilities and retains granted resources within caps")
 g.RelicEffects.begin_combat(g);g._begin_player_turn()
 t.check(g.state.temporary_mana==20 and g.state.charge==1,"ADAPT next battle retains resources without retriggering removed recurring abilities")
 for fixture in [Game.new(42,true,"equipment"),Game.new(42,true,"pressure"),preload("res://tests/prison_cases.gd").intake(t)]:
  card=Cards.give(fixture,"adaptability")
  var phase=fixture.state.phase;var charge=fixture.state.charge
  t.check(t.action(fixture,"card",{"uid":card.uid,"free":false}).ok and fixture.state.charge==charge,"ADAPT special battle activation waits: "+phase)
  t.check(t.action(fixture,"end").ok and fixture.state.charge==charge+1,"ADAPT special battle shares actual turn-start hook: "+phase)
