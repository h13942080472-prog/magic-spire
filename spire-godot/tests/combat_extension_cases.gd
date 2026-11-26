extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Cards=preload("res://tests/card_expansion_cases.gd")

static func run(t) -> void:
 for free in [false,true]:
  var g=Game.new(42);var card=Cards.give(t,g,"henshin")
  var cost=4 if free else 3
  g.state.energy=cost-1
  var before=g.export_snapshot()
  t.check(not t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.state==before,"EXTENSION henshin rejects below the selected face cost atomically")
  g.state.energy=cost
  t.check(t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.state.energy==0 and g.state.mana==60,"EXTENSION henshin charges three bound or four free energy and forty mana")
 var g=Game.new(42);g.state.relics=["ember","marble","small_sigil","small_gem"]
 g.state.energy=10
 t.check(Cards.cast(t,g,"resonance",true).ok and Cards.cast(t,g,"henshin",true).ok,"EXTENSION actual powers and henshin activate")
 g._gain_temporary_card("tease");g.state.sure_cast=true;g.state.evasion=2
 g.state.mana=20;g.state.charge=7;g.state.temporary_mana=45
 var before=g.export_snapshot()
 g._finish_battle()
 t.check(g.state.phase=="reward" and g.state.combat==before.combat and g.state.energy==before.energy and g.state.mana==20,"EXTENSION victory does not end or restart the active session or pay ending relics")
 for field in ["hand","draw","discard","exhaust","powers","deck","charge","temporary_mana","card_buffs","evasion","sure_cast"]:
  t.check(g.state[field]==before[field],"EXTENSION reward screen preserves "+field)
 Save.roundtrip(t,g,"active battle buffs and piles awaiting preparation")
 var serial=g.state.combat.serial;var turn=g.state.combat.turn
 var exhaust=g.state.exhaust.duplicate(true);var powers=g.state.powers.duplicate(true)
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare" and g.state.combat.serial==serial and g.state.combat.turn==turn+1,"EXTENSION preparation starts next turn in same session")
 t.check(g.state.mana==20 and g.state.energy==g.max_energy() and g.state.charge==7 and g.state.evasion>=1 and g.state.temporary_mana==45 and g.state.sure_cast,"EXTENSION opening relics do not repeat; existing turn-start power still triggers")
 t.check(g.state.powers==powers and g.state.exhaust==exhaust and "henshin_free" in g.state.card_buffs and g.state.hand.size()==g.B.DRAW,"EXTENSION normal fresh hand uses original piles and abilities")
 Save.roundtrip(t,g,"preparation continues active powers")
 t.check(t.action(g,"finish_prepare").ok and g.state.phase=="map" and g.state.mana==50,"EXTENSION ending preparation pays low-mana and normal ending relics once")
 t.check(g.state.powers.is_empty() and "henshin_free" not in g.state.card_buffs and g.state.evasion==0 and not g.state.sure_cast and not g.state.deck.any(func(c):return c.type=="tease"),"EXTENSION final cleanup removes combat powers, temporary cards and buffs")
 before=g.export_snapshot();g._finish_preparation()
 t.check(g.state.mana==before.mana and g.state.charge==before.charge and g.state.temporary_mana==before.temporary_mana,"EXTENSION repeated finish cannot repeat ending rewards")
 for early in [false,true]:
  g=Game.new(42,true,"equipment");g.state.relics=["ember","marble"];g.state.mana=20
  if not early: g.state.rest_left=1
  t.check(t.action(g,"finish_rest" if early else "end").ok and g.state.mana==20 and not g.state.combat.active,"EXTENSION rest departure cleans up without battle-ending relics")
 energy(t)
 g=Game.new(42);g.state.relics=[];g.state.weakness_turns=1
 g.Pressure.gain(g,100,"fixture")
 g._finish_battle()
 t.check(g.validate()=="" and g.state.overloaded and g.state.overload_energy>0,"EXTENSION victory preserves pending next-turn penalty")
 Save.roundtrip(t,g,"victory with remaining weakness and next-turn penalty")
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare" and not g.state.overloaded and g.state.energy==g.max_energy()-g.B.OVERLOAD_ENERGY,"EXTENSION reward remains actionable and next preparation turn consumes penalty once")

static func energy(t) -> void:
 for shell in [false,true]:
  for donut in [false,true]:
   for amounts in [[0,0],[1,0],[0,9],[2,2],[20,15]]:
    var g=Game.new(42);g.state.relics=[]
    if shell: g.state.relics.append("turtle_shell")
    if donut: g.state.relics.append("donut")
    g.state.next_energy=amounts[0];g.state.energy=amounts[1]
    var expected=mini(3 if shell else 1,amounts[0]+(amounts[1] if donut else 0))
    var before=g.export_snapshot()
    t.check(g.retained_energy()==expected and g.state==before,"EXTENSION energy carry is a read-only shared cap, with and without donut/shell")
    g._finish_battle()
    t.check(g.state.next_energy==amounts[0] and g.state.energy==amounts[1],"EXTENSION victory does not cap energy within the continuing session")
    t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.energy==g.max_energy()+amounts[0]+(amounts[1] if donut else 0),"EXTENSION preparation refill consumes full same-session energy")
    g.state.next_energy=amounts[0];g.state.energy=amounts[1]
    t.check(t.action(g,"finish_prepare").ok and g.state.next_energy==expected and g.state.energy==0,"EXTENSION preparation exit caps only next battle bonus")
    g._start_battle()
    t.check(g.state.energy==g.max_energy()+expected and g.state.next_energy==0,"EXTENSION next real combat receives capped bonus exactly once")
 for early in [false,true]:
  var g=Game.new(42);g.state.relics=["ember","donut","turtle_shell"]
  g._finish_battle();t.action(g,"reward",{"type":"skip"});g.state.mana=20;g.state.energy=7;g.state.next_energy=2
  if not early: g.state.prepare_left=1
  t.check(t.action(g,"finish_prepare" if early else "end").ok and g.state.mana==30 and g.state.next_energy==3,"EXTENSION natural and early ending share one payout and carry cap without double counting donut")
 var g=Game.new(42,true,"guard");g.state.relics=["donut","turtle_shell"];g.state.energy=9;g.state.next_energy=5
 g.Guard.capture(g,g.state.enemies[0])
 t.check(g.state.next_energy==0 and g.state.energy==0,"EXTENSION capture clears bonus energy even with donut and turtle")
