extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")

static func fresh(seed_value: int=42):
 var g=Game.new(seed_value);g._discard_end();g.state.mana=40
 return g

static func run(t) -> void:
 rest_restriction(t)
 var g=fresh();var spec=g.Cards.Rules.SPECS.siphon
 t.check(spec.rarity=="uncommon" and "siphon" in g.Cards.Rules.UNCOMMON and "siphon" not in g.Cards.Rules.COMMON and g.Cards.Rules.definition_reason(spec)=="" and not g.B.CARD_TRAITS.get("siphon",{}).get("exhaust",false),"SIPHON uncommon reusable spell joins the existing reward and shop pool")
 for mana in [40,98,100]:
  g=fresh();g.state.mana=mana;g.state.energy=0;g.state.pressure=99
  g.add_fixture("ankle",4);g.add_fixture("mouth",10)
  var card=Give.give(g,"siphon")
  var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(c.valid and c.cost==0 and c.mana==0 and not g.Cards.uses_magic(c.payload) and g.state==before,"SIPHON bound face has no leg, mouth or casting gate and preview is read-only")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==mini(mana+5,100) and g.state.energy==0 and g.state.rng.magic==before.rng.magic and g.state.hand.size()==before.hand.size()-1,"SIPHON bound restores five up to cap without draw or cast roll")
  t.check(g.state.discard.any(func(x):return x.uid==card.uid) and not g.state.exhaust.any(func(x):return x.uid==card.uid),"SIPHON successful bound use discards normally")
 g=fresh();var card=Give.give(g,"siphon")
 g.add_fixture("ankle",4)
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true});var before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("腿部") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"SIPHON free face rejects nonzero leg severity atomically")
 g=fresh();card=Give.give(g,"siphon");g.state.energy=0
 c=t.find_action(g,"card",{"uid":card.uid,"free":true});before=g.export_snapshot()
 t.check(not c.valid and c.cost==1 and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"SIPHON free face still requires one energy at zero mana cost")
 var outcomes={}
 for seed_value in range(8):
  g=fresh(seed_value);card=Give.give(g,"siphon");g.state.pressure=75
  c=t.find_action(g,"card",{"uid":card.uid,"free":true});before=g.export_snapshot()
  var twin=fresh();t.check(twin.restore_snapshot(before).ok,"SIPHON current snapshot preserves the new card")
  t.check(c.valid and c.cost==1 and c.mana==0 and g.Cards.uses_magic(c.payload) and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SIPHON free casting profile and stale-version protection")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and twin.dispatch(twin.command(c.payload,twin.state.version),twin.state.version).ok,"SIPHON both matching snapshots commit the same spell")
  var result=g.state.logs.filter(func(row):return row.data.has("spell")).back().data.spell
  outcomes[result.success]=true
  var actual=g.export_snapshot();var restored=twin.export_snapshot()
  actual.erase("version");restored.erase("version")
  t.check(actual==restored and twin.state.version==g.state.version+1 and g.state.energy==before.energy-1 and g.state.rng.magic==before.rng.magic+1,"SIPHON cast reproduces all gameplay state while restore advances the submission version")
  t.check(g.state.mana==(50 if result.success else 40) and g.state.hand.size()==before.hand.size()+(1 if result.success else 0),"SIPHON only successful chant restores ten and draws two; failure retains card and grants nothing")
 t.check(outcomes.has(true) and outcomes.has(false),"SIPHON sample covers both chant outcomes")
 g=fresh();card=Give.give(g,"siphon");g.state.mana=98
 c=t.find_action(g,"card",{"uid":card.uid,"free":true});before=g.export_snapshot()
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==100 and g.state.hand.size()==before.hand.size()+1,"SIPHON free restoration caps without reducing two-card draw")
 g=fresh();card=Give.give(g,"siphon");g.state.pressure=50
 var rate=g.cast_view(g.Cards.cast_profile(g,"siphon")).chance
 g.add_fixture("mouth",10)
 t.check(g.cast_view(g.Cards.cast_profile(g,"siphon")).chance<rate,"SIPHON free chant includes actual mouth restraint penalty")

static func rest_restriction(t) -> void:
 var g=fresh();var card=Give.give(g,"siphon")
 var battle=t.find_action(g,"card",{"uid":card.uid,"free":true})
 g._start_rest();g._begin_rest();g._discard_end();g.state.mana=40
 # Return this existing physical card to hand; no second permanent copy.
 for zone in g.Cards.ZONES: g.state[zone]=g.state[zone].filter(func(c):return c.uid!=card.uid)
 g.state.hand.append(card)
 var before=g.export_snapshot()
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var view=g.get_view().hand.filter(func(row):return row.uid==card.uid)[0]
 t.check(not c.valid and c.reason=="休息房禁止卡牌自由效果。" and not view.availability.free.usable and view.availability.free.dim and view.availability.free.text.contains("休息房禁止"),"SIPHON rest free face is rejected and visibly dimmed with precise reason")
 t.check(not g.dispatch(g.command(battle.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"SIPHON even a cached battle candidate cannot bypass rest or spend energy, draw, heal, roll RNG or change logs")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.mana==45 and g.state.energy==before.energy and g.state.hand.size()==before.hand.size()-1,"SIPHON rest bound face keeps its legal zero-cost five-mana recovery")
 for type in g.Cards.Rules.SPECS:
  if not g.Cards.Rules.SPECS[type].has("self_faces"): continue
  var p={"kind":"card","type":type,"uid":"probe","free":true,"self_target":true}
  t.check((g.Cards.reason(g,p)=="休息房禁止卡牌自由效果。")==g.Cards.Rules.free_effect(type,true),"REST self-targeted faces follow their declared bound or free classification: "+type)
 g=fresh();g._start_rest();g._begin_rest();g._discard_end()
 var target=g.add_fixture("wrist",4)
 card=Give.give(g,"concentration")
 t.check(t.find_action(g,"card",{"uid":card.uid,"free":true,"target":target.id}).valid,"REST second bound face is not mistaken for a forbidden free effect")
 g=fresh();g._start_preparation();g._discard_end();g.state.mana=40;card=Give.give(g,"siphon")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.mana==50,"SIPHON preparation still permits its free effect")
