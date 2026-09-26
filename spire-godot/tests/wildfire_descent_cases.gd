extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func active(t):
 var g=Game.new(42);g._discard_end();g.state.energy=20
 var card=Cards.give(g,"wildfire_descent")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok,"WILDFIRE activate power through paid mouth spell")
 return g

static func fire(t,g) -> Dictionary:
 return t.find_action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id},false)

static func run(t) -> void:
 var rules=preload("res://data/card_rules.gd")
 t.check(rules.classification("wildfire_descent").rarity=="uncommon" and "wildfire_descent" in rules.UNCOMMON and "wildfire_descent" not in rules.RARE,"WILDFIRE classification and reward/shop pool agree on uncommon rarity")
 for free in [false,true]:
  var g=Game.new(42);g._discard_end();var card=Cards.give(g,"wildfire_descent")
  var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(c.valid and c.cost==1 and c.mana==10 and g.Cards.cast_profile(g,card.type).parts==["mouth"] and g.state==before,"WILDFIRE either face costs one energy and ten base mana with mouth casting")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"WILDFIRE stale activation preserves payment and physical card")
  g.state.mana=9;before=g.export_snapshot()
  t.check(not t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.state==before,"WILDFIRE insufficient mana rejects atomically")
  g.state.mana=10;g.state.sure_cast=true
  t.check(t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.state.mana==0 and g.state.energy==before.energy-1 and g.state.powers[0].uid==card.uid,"WILDFIRE exactly ten mana activates either face and pays once")
  g=Game.new(42);g._discard_end();card=Cards.give(g,"wildfire_descent")
  g.state.mana=100;g._install_template("mouth_band","mouth",24,24,false,"fixture",3)
  before=g.export_snapshot()
  t.check(not t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.state==before,"WILDFIRE zero mouth chance blocks both faces")
  g=Game.new(42);g._discard_end();card=Cards.give(g,"wildfire_descent");g.state.pressure=99
  c=t.find_action(g,"card",{"uid":card.uid,"free":free});before=g.export_snapshot()
  var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
  t.check(result.ok and g._magic_failed and g.state.powers.is_empty() and g.state.hand==before.hand and is_equal_approx(g.state.mana,before.mana-c.mana*0.5) and g.state.energy==before.energy-1 and result.card_feedback.is_empty(),"WILDFIRE failed activation pays pressure-adjusted costs, stays in hand, grants no power")
  g.state.sure_cast=true;g.state.temporary_mana=c.mana
  t.check(t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.state.temporary_mana==0 and g.state.powers[0].uid==card.uid and g.state.hand.is_empty(),"WILDFIRE retry can pay from temporary pool and activation does not draw itself")
 var g=active(t);var before=g.export_snapshot()
 var result=g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.hand.size()==before.hand.size()+1 and result.card_feedback.filter(func(e):return e.kind=="draw").size()==1,"WILDFIRE one successful fireball draws one physical card")
 var duplicate=Cards.give(g,"wildfire_descent");before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":duplicate.uid,"free":true}).ok and g.Cards.buff_stacks(g,"wildfire_descent")==2,"WILDFIRE opposite face adds another layer of the shared effect")
 var twin=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"wildfire power")
 if twin!=null: preload("res://tests/persistence_cases.gd").step_both(t,g,twin,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})
 for layers in [1,2]:
  g=active(t)
  if layers==2:
   duplicate=Cards.give(g,"wildfire_descent")
   t.check(t.action(g,"card",{"uid":duplicate.uid,"free":true}).ok,"WILDFIRE activate stacked failure fixture through opposite face")
  g.state.pressure=99;before=g.export_snapshot()
  result=g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version)
  t.check(result.ok and g._magic_failed and g.state.hand==before.hand and g.state.draw==before.draw and g.state.discard==before.discard and result.card_feedback.all(func(e):return e.kind!="draw" and e.kind!="shuffle") and g.state.enemies.map(func(e):return e.hp)==before.enemies.map(func(e):return e.hp),"WILDFIRE failed fireball leaves all piles unchanged and emits no draw at any stack count")
  g.state.sure_cast=true;before=g.export_snapshot()
  result=g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version)
  t.check(result.ok and not g._magic_failed and g.state.hand.size()==before.hand.size()+layers,"WILDFIRE successful retry draws once per retained layer")
 g=active(t);var card=Cards.give(g,"fire_dynamics")
 t.action(g,"card",{"uid":card.uid,"free":true});before=g.export_snapshot()
 t.check(g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version).ok and g.state.hand.size()==before.hand.size()+1,"WILDFIRE area fireball draws once across multiple targets")
 g=active(t);card=Cards.give(g,"flame_flourish");t.action(g,"card",{"uid":card.uid,"free":false})
 var target=g.add_fixture("thigh",60,60,true);before=g.export_snapshot()
 t.check(t.action(g,"attack",{"type":"fireball","target":target.id}).ok and g.state.hand.size()==before.hand.size()+1,"WILDFIRE equipment-targeted fireball uses same one-draw trigger")
 g=active(t);g._draw(10);before=g.export_snapshot()
 result=g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.hand.size()==10 and result.card_feedback.all(func(e):return e.kind!="draw") and g.state.draw==before.draw and g.state.discard==before.discard,"WILDFIRE full hand preserves piles without overdrawing")
 t.check(g.state.logs.any(func(e):return e.text=="猛火下山生效：抽0张牌。"),"WILDFIRE capped draw log reports actual number")
 g=active(t);g.state.discard.append_array(g.state.draw);g.state.draw=[]
 result=g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.hand.size()==1 and result.card_feedback.any(func(e):return e.kind=="shuffle"),"WILDFIRE empty draw pile uses normal discard shuffle")
 g=active(t)
 for enemy in g.state.enemies: enemy.hp=1 if enemy==g.state.enemies[0] else 0;enemy.gone=enemy!=g.state.enemies[0]
 result=g.dispatch(g.command(fire(t,g).payload,g.state.version),g.state.version)
 t.check(result.ok and g.state.phase=="reward" and not g.state.powers.is_empty() and result.card_feedback.filter(func(e):return e.kind=="draw").size()==1,"WILDFIRE final lethal cast draws and preserves power for preparation")
