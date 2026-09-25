extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")
static func setup():
 var g=Game.new(42);g._discard_end();g.state.energy=30
 for enemy in g.state.enemies: enemy.hp=300;enemy.max_hp=300
 return g
static func run(t) -> void:
 var g=setup();var rules=g.Cards.Rules;var spec=rules.SPECS.resonance
 t.check(spec.cost==1 and spec.rarity=="uncommon" and spec.card_type=="power" and "resonance" in rules.UNCOMMON and rules.definition_reason(spec)=="","RESONANCE valid uncommon one-energy ability in random pool")
 for free in [false,true]: t.check(rules.unique_face("resonance",free)==(not free) and not rules.face_casts("resonance",free),"RESONANCE bound unique free stackable and neither casts")
 var card=Give.give(g,"resonance");var c=t.find_action(g,"card",{"uid":card.uid,"free":false});var before=g.export_snapshot()
 t.check(c.valid and c.cost==1 and c.mana==0 and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"RESONANCE stale activation is atomic and costs only one energy")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._mana_cost(10)==10,"RESONANCE no equipment means no discount")
 var ordinary=g.add_fixture("eyes",8)
 var composite=g._install_assembly("glove","short","fixture",2,1)
 var special=g._install_special("vaginal_egg_low","special_3_a")
 t.check(not composite.is_empty() and not special.is_empty() and g.Cards.worn_count(g)==3 and is_equal_approx(g._mana_cost(10),8.5),"RESONANCE ordinary composite root and special each count once")
 before=g.export_snapshot();var duplicate=Give.give(g,"resonance");before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":duplicate.uid,"free":false}).ok and g.state==before,"RESONANCE bound unique rejects duplicate without costs")
 ordinary.durability=0;g._cleanup()
 t.check(g.Cards.worn_count(g)==2 and is_equal_approx(g._mana_cost(10),9),"RESONANCE removal immediately recomputes discount")
 t.check(g.get_view().statuses.any(func(row):return row.id=="power_resonance_bound" and row.value.contains("10%")),"RESONANCE status exposes actual current percentage")
 var restored=Save.roundtrip(t,g,"stacked resonance with equipment")
 if restored!=null: t.check(is_equal_approx(restored._mana_cost(10),9),"RESONANCE restored powers recompute discount")
 g=setup();g.add_fixture("eyes",8);Give.play(t,g,"resonance",false)
 c=t.find_action(g,"attack",{"type":"fireball"});before=g.export_snapshot()
 t.check(is_equal_approx(c.mana,9.5) and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(before.mana-g.state.mana,9.5),"RESONANCE fixed fireball actually pays discounted fractional cost")
 card=Give.give(g,"rekindle");c=t.find_action(g,"card",{"uid":card.uid,"free":false});g.state.temporary_mana=9.5;before=g.export_snapshot()
 t.check(is_equal_approx(c.mana,9.5) and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.temporary_mana==0 and g.state.mana==before.mana,"RESONANCE magic card uses discounted cost and temporary pool first")
 t.check(g.Cards.face_mana(g,"mana_conversion",false)==20,"RESONANCE existing fixed mana conversion remains fixed")
 for slot in g.B.SLOTS:
  for n in range(3): g.add_fixture(slot,8,10,false,n)
 t.check(g.Cards.worn_count(g)>=20 and g._mana_cost(10)==0,"RESONANCE more than one hundred percent never generates negative payment")
 g.Cards.end_powers(g);t.check(g._mana_cost(10)==10,"RESONANCE cleanup removes mana reduction")
 g=setup();g.state.energy=1
 card=Give.give(g,"resonance");c=t.find_action(g,"card",{"uid":card.uid,"free":true});before=g.export_snapshot()
 t.check(c.cost==2 and not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"RESONANCE free face rejects one energy without partial payment")
 g.state.energy=2;c=t.find_action(g,"card",{"uid":card.uid,"free":true});before=g.export_snapshot()
 t.check(c.valid and c.cost==2 and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"RESONANCE free face previews two energy and stale play is atomic")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==0 and g.state.evasion==0,"RESONANCE free face spends exactly two energy without immediate evasion")
 g.state.energy=2
 t.check(Give.play(t,g,"resonance",true).ok and g.state.energy==0,"RESONANCE second free copy also spends two energy")
 t.check(g.state.evasion==0 and g.state.powers.size()==2,"RESONANCE free activation does not immediately evade")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.evasion==2,"RESONANCE next turn gains one evasion per copy")
 before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"RESONANCE rendering cannot grant evasion or change mana")

 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.evasion==4,"RESONANCE free copies trigger again every turn and retain unspent evasion")
 g=setup();g.add_fixture("eyes",8);Give.play(t,g,"resonance",false);g.state.pressure=99
 card=Give.give(g,"rekindle");c=t.find_action(g,"card",{"uid":card.uid,"free":false})
 var rng=g.state.rng.magic
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"rekindle")).winning_rolls: rng=g.state.rng.magic
 g.state.rng.magic=rng;before=g.export_snapshot()
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and is_equal_approx(g.state.mana,before.mana-4.75),"RESONANCE failed cast refunds half the discounted nine point five cost")
