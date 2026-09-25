extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func fresh() -> RefCounted:
 var g=Game.new(42);g.state.relics=["ember_crystal"];g.state.pressure=75;g.state.energy=10
 for enemy in g.state.enemies: enemy.hp=200;enemy.max_hp=200
 return g

static func run(t) -> void:
 var g=fresh();var shot=t.find_action(g,"attack",{"type":"fireball"})
 var before=g.export_snapshot();var random=g.state.rng.magic
 t.check(shot.valid and g.cast_view(g.Cards.cast_profile(g,"fireball")).chance==1,"CRYSTAL first paid cast previews guaranteed success")
 g.get_view();g.command_facts()
 t.check(g.state==before and not g.dispatch(g.command(shot.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"CRYSTAL preview and rejected cast preserve opportunity and payment")
 t.check(g.dispatch(g.command(shot.payload,g.state.version),g.state.version).ok and not g._magic_failed and g.state.rng.magic==random and g.state.mana==before.mana-shot.mana and g.RelicEffects.used(g,"ember_crystal"),"CRYSTAL first paid cast succeeds at full cost without rolling")
 t.check(g.cast_view(g.Cards.cast_profile(g,"fireball")).chance<1,"CRYSTAL second cast returns to ordinary success chance")
 var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"used crystal")
 t.check(restored!=null and restored.RelicEffects.used(restored,"ember_crystal"),"CRYSTAL saving does not refresh current-turn use")
 t.check(t.action(g,"end").ok and not g.RelicEffects.used(g,"ember_crystal") and g.cast_view(g.Cards.cast_profile(g,"fireball")).chance==1,"CRYSTAL next real player turn refreshes opportunity")

 g=fresh();var card=Cards.give(g,"ease")
 t.check(t.action(g,"card",{"uid":card.uid,"slot":"thigh"}).ok and not g.RelicEffects.used(g,"ember_crystal"),"CRYSTAL free preparation keeps first paid cast")
 g.state.temporary_mana=100;g.state.sure_cast=true
 shot=t.find_action(g,"attack",{"type":"fireball"});var mana=g.state.mana
 t.check(g.dispatch(g.command(shot.payload,g.state.version),g.state.version).ok and g.state.mana==mana and g.RelicEffects.used(g,"ember_crystal") and g.state.sure_cast,"CRYSTAL temporary mana counts as payment and preserves the scroll guarantee")
 t.check(t.action(g,"attack",{"type":"fireball"}).ok and not g.state.sure_cast and not g._magic_failed,"CRYSTAL later cast can consume the separate scroll guarantee")
 g=fresh();g.add_fixture("fingers",8);card=Cards.give(g,"rekindle")
 var blocked=t.find_action(g,"card",{"uid":card.uid,"free":false},false)
 before=g.export_snapshot()
 t.check(not blocked.valid and not g.dispatch(g.command(blocked.payload,g.state.version),g.state.version).ok and g.state==before,"CRYSTAL does not bypass required body conditions")

 for phase in ["battle","prepare","rest","prison"]:
  g=Game.new(42,true,"prison_test") if phase=="prison" else Game.new(42)
  g.state.relics=["ember_crystal"];g.RelicEffects.end_combat(g)
  match phase:
   "battle": g._start_battle()
   "prepare": g._start_preparation()
   "rest": g._start_rest();t.action(g,"rest_begin")
   "prison": g.Prison.enter(g)
  g._discard_end();g.state.pressure=75;card=Cards.give(g,"mana_surge")
  var spell=t.find_action(g,"card",{"uid":card.uid,"free":false})
  before=g.export_snapshot()
  t.check(g.dispatch(g.command(spell.payload,g.state.version),g.state.version).ok and g.state.mana==before.mana-spell.mana and g.state.charge>=2 and g.RelicEffects.used(g,"ember_crystal"),"CRYSTAL paid card guaranteed in "+phase)
 g=fresh();card=Cards.give(g,"mana_conversion")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.RelicEffects.used(g,"ember_crystal"),"CRYSTAL fixed-price conversion also consumes first paid cast")
