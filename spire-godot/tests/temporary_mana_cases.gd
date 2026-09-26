extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func fire(t,g) -> Dictionary:
 return t.find_action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id},false)

static func run(t) -> void:
 unlock_preparation(t)
 ease_preparation(t)
 var g=Game.new(42)
 g.Cards.apply_effects(g,[{"op":"reserve_mana","amount":201}],{})
 t.check(g.state.temporary_mana==1005 and g.state.mana==100 and g.validate()=="","TEMP each stack grants five to an uncapped independent pool")
 var c=fire(t,g);var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(c.valid and c.mana==10 and c.mana_payment.temporary_mana==10 and c.mana_payment.mana==0 and before==g.state,"TEMP candidate and view show gross cost and split payment without mutation")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and before==g.state,"TEMP stale payment leaves both pools unchanged")
 g.state.relics.append("mana_earring")
 var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.temporary_mana==995 and g.state.mana==100 and not g.state.combat.mana_used and g.state.combat.mana_spent==0,"TEMP full offset keeps permanent mana and real-spend relic counters")
 t.check(result.resource_feedback.any(func(e):return e.field=="temporary_mana" and e.before==1005 and e.after==995),"TEMP payment has independent floating-number receipt")
 var record=g.state.logs.filter(func(e):return e.data.has("player_action"))[0].data.player_action
 t.check(record.temporary_mana==10 and record.mana==0,"TEMP log records both actual payment sources")
 g=Game.new(42);g.state.temporary_mana=7.5;g.state.mana=2
 c=fire(t,g);before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("2.5") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"TEMP insufficient combined balance rejects atomically")
 g.state.mana=2.5;c=fire(t,g)
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==0 and g.state.temporary_mana==0 and g.state.combat.mana_used,"TEMP fractional remainder pays exact remaining permanent mana")
 g=Game.new(42);g.state.temporary_mana=15;g.state.mana=50
 t.check(g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version).ok and g.state.temporary_mana==5 and g.state.mana==50,"TEMP unused point balance remains after first spell")
 t.check(g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version).ok and g.state.temporary_mana==0 and g.state.mana==45,"TEMP second spell consumes leftover points before permanent mana")
 g=Game.new(42);g.state.temporary_mana=100;g.state.mana=0;g.state.pressure=99
 c=fire(t,g)
 t.check(c.mana==10 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and is_equal_approx(g.state.temporary_mana,100-c.mana*0.5) and g.state.mana==0,"TEMP failed high-pressure spell pays base cost then refunds half to temporary pool")
 g=Game.new(42);g.state.temporary_mana=123.5
 t.check(t.action(g,"end").ok and g.state.temporary_mana==123.5,"TEMP balance survives a normal turn boundary")
 var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"temporary mana fractions")
 t.check(restored!=null and restored.state.temporary_mana==123.5,"TEMP current snapshot preserves exact independent balance")
 for phase in g.RelicEffects.COMBAT_PHASES:
  g=Game.new(42);g.state.phase=phase;g.state.relics=[];g.state.temporary_mana=50;g.state.mana=40
  g.RelicEffects.end_combat(g)
  t.check(g.state.temporary_mana==20 and g.state.mana==40,"TEMP every normal or special combat ending applies retention cap: "+phase)
 g=Game.new(42);g.state.temporary_mana=50
 for enemy in g.state.enemies: enemy.hp=1 if enemy==g.state.enemies[0] else 0;enemy.gone=enemy!=g.state.enemies[0]
 result=g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.phase=="reward" and g.state.temporary_mana==40,"TEMP lethal final spell pays ten and preserves the rest through rewards")
 var feedback=result.resource_feedback.filter(func(e):return e.field=="temporary_mana")
 t.check(feedback.size()==1 and feedback[0].before==50 and feedback[0].after==40,"TEMP lethal action animates only its actual payment")
 result=t.action(g,"reward",{"type":"skip"})
 t.check(result.ok and g.state.phase=="prepare" and g.state.temporary_mana==40 and not result.resource_feedback.any(func(e):return e.field=="temporary_mana"),"TEMP preparation continues the same balance without a cleanup animation")
 result=t.action(g,"finish_prepare")
 feedback=result.resource_feedback.filter(func(e):return e.field=="temporary_mana")
 t.check(result.ok and g.state.phase=="map" and g.state.temporary_mana==20 and feedback.size()==1 and feedback[0].before==40 and feedback[0].after==20,"TEMP actual preparation end applies and animates the retention cap once")
 g=Game.new(42);g.state.temporary_mana=1000;g.state.mana=0
 c=t.find_action(g,"flask",{"op":"deposit"},false);before=g.export_snapshot()
 t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"TEMP cannot deposit independent pool")
 g.state.temporary_mana=-0.1
 t.check(g.validate()!="","TEMP negative balance rejected")

static func unlock_preparation(t) -> void:
 for pressure in [0,99]:
  var g=Game.new(42);g.state.pressure=pressure;g.state.mana=40;g.state.temporary_mana=7.5
  var card=t.grant_fixture_card(g,"unlock")
  var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(c.valid and c.cost==1 and c.mana==0 and g.state==before,"UNLOCK preparation previews two stacks with original one-energy cost and no mana cost")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"UNLOCK stale preparation rejects without resource changes")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.temporary_mana==17.5 and g.state.mana==40 and g.state.energy==before.energy-1 and g.state.rng==before.rng,"UNLOCK two preparation stacks add ten temporary points without casting even at high pressure")
  t.check(g.state.discard.any(func(row):return row.uid==card.uid) and g._card(card.uid).is_empty(),"UNLOCK preparation discards the played card normally")
 var g=Game.new(42);var card=t.grant_fixture_card(g,"unlock");g.add_fixture("palm",4)
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true});var before=g.export_snapshot()
 t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"UNLOCK two stacks do not bypass blocked hand requirements")
 t.check(g.Cards.Rules.SPECS.double_unlock.free_effects==[{"op":"reserve_mana","amount":1}],"UNLOCK double unlock keeps its original one-stack free effect")

static func ease_preparation(t) -> void:
 var g=Game.new(42);g.state.mana=100;g.state.temporary_mana=17.5;g.state.pressure=99
 g._install_template("mouth_band","mouth",24.0,24.0,false,"fixture",3,0)
 var card=t.hand_card(g,"ease");var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var before=g.export_snapshot();var face=g.get_view().hand.filter(func(row):return row.uid==card.uid)[0]
 t.check(c.valid and c.cost==1 and c.mana==0 and face.free.contains("2") and face.face_mana.free.any(func(badge):return badge.kind=="temporary" and badge.text.contains("10")),"EASE two-stack preparation and ten-point badge come from the same definition")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"EASE stale preparation leaves all state unchanged")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.temporary_mana==27.5 and g.state.mana==100 and g.state.energy==before.energy-1 and g.state.rng==before.rng,"EASE two stacks add ten uncapped temporary points without a mouth roll")
 t.check(g.state.discard.any(func(row):return row.uid==card.uid),"EASE preparation still discards normally")
