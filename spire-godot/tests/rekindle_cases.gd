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
  var printed=preload("res://data/encyclopedia.gd").card("rekindle")
  t.check(["bound","free"].all(func(side):return printed.face_keywords[side].any(func(k):return k.name=="消耗2") and printed.face_effects[side].contains("消耗2")),"REKINDLE both catalog faces show native Exhaust 2")
  var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
  var before=g.export_snapshot()
  t.check(c.valid and c.cost==1 and c.mana==10 and g.candidate_detail(c).contains("0／%d" % limit),"REKINDLE both faces show correct payment and remaining uses")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"REKINDLE stale submission cannot refresh or spend")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==before.energy-1 and g.state.mana==before.mana-10 and g.BasicAttacks.usage(g,"fireball").remaining==limit and g.state.discard.any(func(x):return x.uid==card.uid),"REKINDLE succeeds, restores current limit and normally discards")
  t.check(t.action(g,"attack",{"type":"fireball"}).ok and g.BasicAttacks.usage(g,"fireball").remaining==limit-1,"REKINDLE restored counter enables a real same-turn fireball")
  var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"Rekindle after its first cast")
  if restored==null: continue
  var spent=restored.Cards.instance(restored,card.uid)
  var meta=restored.Cards.metadata(restored,"rekindle",card.uid)
  t.check(spent.get("exhaust_spent")==1 and ["bound","free"].all(func(side):return meta.face_keywords[side].any(func(k):return k.name=="消耗") and not meta.face_effects[side].contains("消耗2")),"REKINDLE restored instance shows one shared use on either face")
  var snapshot=restored.export_snapshot();var bad_count=snapshot.duplicate(true)
  for copy in bad_count.discard:
   if copy.uid==card.uid: copy.exhaust_spent=2
  t.check(not restored.restore_snapshot(bad_count).ok and restored.export_snapshot()==snapshot,"REKINDLE invalid stored use count rolls back")
  restored.state.discard.erase(spent);restored.state.hand.append(spent)
  t.check(t.action(restored,"card",{"uid":card.uid,"free":not free}).ok and restored.state.exhaust.any(func(x):return x.uid==card.uid),"REKINDLE second successful play on the opposite face exhausts the same card")
  restored._reset_piles()
  t.check(not restored.Cards.instance(restored,card.uid).has("exhaust_spent") and restored.Cards.face_text(restored,card.type,free,card.uid).contains("消耗2"),"REKINDLE next encounter starts the same deck card with both uses")
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
 t.check(not g.Cards.instance(g,card.uid).has("exhaust_spent"),"REKINDLE failed cast keeps both uses")
 var invalid=g.Cards.Rules.SPECS.rekindle.duplicate(true);invalid.exhaust_uses=0
 t.check(g.Cards.Rules.definition_reason(invalid)!="","REKINDLE invalid exhaust count is rejected")
 var bad=g.Cards.Rules.SPECS.rekindle.duplicate(true);bad.self_faces.free.refresh_spell="missing"
 t.check(g.Cards.Rules.definition_reason(bad)!="","REKINDLE definition rejects unregistered spell refresh")
