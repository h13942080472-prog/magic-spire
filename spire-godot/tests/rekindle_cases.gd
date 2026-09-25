extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func run(t) -> void:
 for free in [false,true]:
  var g=Game.new(42);g._discard_end();g.state.energy=20
  for e in g.state.enemies: e.hp=200;e.max_hp=200
  if free:
   var power=Cards.give(g,"flame_flourish")
   t.action(g,"card",{"uid":power.uid,"free":true})
  var limit=3 if free else 2
  for i in range(limit): t.check(t.action(g,"attack",{"type":"fireball"}).ok,"REKINDLE spend actual current fireball allowance")
  t.check(not t.find_action(g,"attack",{"type":"fireball"}).valid,"REKINDLE exhausted allowance blocks further casting")
  var card=Cards.give(g,"rekindle")
  var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
  var before=g.export_snapshot()
  t.check(c.valid and c.cost==1 and c.mana==10 and g.candidate_detail(c).contains("0／%d" % limit),"REKINDLE both faces show correct payment and remaining uses")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"REKINDLE stale submission cannot refresh or spend")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==before.energy-1 and g.state.mana==before.mana-10 and g.BasicAttacks.usage(g,"fireball").remaining==limit and g.state.discard.any(func(x):return x.uid==card.uid),"REKINDLE succeeds, restores current limit and normally discards")
  t.check(t.action(g,"attack",{"type":"fireball"}).ok and g.BasicAttacks.usage(g,"fireball").remaining==limit-1,"REKINDLE restored counter enables a real same-turn fireball")
 var g=Game.new(42);g._discard_end()
 var card=Cards.give(g,"rekindle");g.add_fixture("fingers",8)
 for free in [false,true]:
  var c=t.find_action(g,"card",{"uid":card.uid,"free":free},false)
  var before=g.export_snapshot()
  t.check(not c.valid and c.reason.contains("手") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"REKINDLE hand requirement blocks either face without payment")
 g=Game.new(42);g._discard_end();g.state.pressure=75;g.state.combat.attack_uses.fireball=2
 card=Cards.give(g,"rekindle")
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var rng=g.state.rng.magic
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"rekindle")).winning_rolls: rng=g.state.rng.magic
 g.state.rng.magic=rng
 var before=g.export_snapshot()
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and g.state.combat.attack_uses.fireball==2 and is_equal_approx(g.state.mana,before.mana-c.mana*0.5) and g.state.energy==before.energy-1 and g.state.hand.any(func(x):return x.uid==card.uid),"REKINDLE failed hand spell pays adjusted mana and keeps card without refresh")
 var bad=g.Cards.Rules.SPECS.rekindle.duplicate(true);bad.self_faces.free.refresh_spell="missing"
 t.check(g.Cards.Rules.definition_reason(bad)!="","REKINDLE definition rejects unregistered spell refresh")
