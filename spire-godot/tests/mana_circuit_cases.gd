extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")
const TYPE="mana_circuit"

static func fresh():
 var g=Game.new(42);g._discard_end();g.state.energy=50;g.state.mana_max=300;g.state.mana=300
 return g

static func activate(t,g,free: bool) -> Dictionary:
 var card=Cards.give(g,TYPE)
 t.check(t.action(g,"card",{"uid":card.uid,"free":free}).ok,"CIRCUIT ability activation")
 return card

static func spend(t,g) -> Dictionary:
 var card=Cards.give(g,"rekindle")
 return t.action(g,"card",{"uid":card.uid,"free":false})

static func run(t) -> void:
 var g=fresh();activate(t,g,true);activate(t,g,true);activate(t,g,false)
 var energy=g.state.energy
 t.check(g.Cards.buff_stacks(g,"mana_circuit_free")==2 and TYPE in g.Cards.Rules.RARE and g.validate()=="","CIRCUIT two free copies and bound copy coexist as valid rare powers")
 for i in range(3): t.check(spend(t,g).ok,"CIRCUIT actual ten-mana spell")
 t.check(g.state.energy==energy-3+2 and g.state.charge==1 and g.state.powers.map(func(c):return c.power_mana_progress)==[0.0,0.0,10.0],"CIRCUIT each free copy refunds at thirty and bound copy grants charge at twenty")
 var restored=Save.roundtrip(t,g,"stacked mana circuit remainders")
 if restored!=null:
  t.check(spend(t,g).ok and spend(t,restored).ok and g.state.powers==restored.state.powers and g.state.charge==2 and restored.state.charge==2,"CIRCUIT restored remainder produces identical next threshold")
 # Each later copy starts counting from its own activation.
 g=fresh();activate(t,g,true);spend(t,g);activate(t,g,true)
 energy=g.state.energy;spend(t,g);spend(t,g)
 t.check(g.state.energy==energy-2+1 and g.state.powers.map(func(c):return c.power_mana_progress)==[0.0,20.0],"CIRCUIT later copy does not inherit earlier mana spending")
 t.check(t.action(g,"end").ok and g.state.powers.map(func(c):return c.power_mana_progress)==[0.0,20.0],"CIRCUIT mana remainder survives an actual turn boundary")
 # Temporary mana belongs to this ability's meter, not the ear-ring's self-mana meter.
 g=fresh();activate(t,g,true);activate(t,g,false);g.state.relics.append("mana_earring");g.state.mana=10;g.state.temporary_mana=20
 energy=g.state.energy
 for i in range(3): spend(t,g)
 t.check(g.state.mana==0 and g.state.temporary_mana==0 and g.state.energy==energy-2 and g.state.charge==1 and g.state.combat.mana_spent==10,"CIRCUIT counts both paid mana pools while existing relic counts only personal mana")
 # Free-face admission uses the existing two region levels; later bindings do not disable it.
 g=fresh();g.add_fixture("eyes",10);g.add_fixture("mouth",10);activate(t,g,true)
 g.add_fixture("wrist",10);var card=Cards.give(g,TYPE);var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"CIRCUIT head-only equipment permits free face, arm restriction refuses another copy atomically")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok,"CIRCUIT bound face remains usable with restricted arms")
 g=fresh();g.add_fixture("ankle",1);card=Cards.give(g,TYPE);before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"CIRCUIT any nonzero lower-body level blocks free activation")
 # Failed spells still paid; no energy or mana payment means no progress.
 g=fresh();activate(t,g,false);g.state.pressure=99;card=Cards.give(g,"rekindle")
 var c=t.find_action(g,"card",{"uid":card.uid,"free":false});var rng=g.state.rng.magic
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"rekindle")).winning_rolls: rng=g.state.rng.magic
 g.state.rng.magic=rng
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and g.state.powers[0].power_mana_progress==c.mana,"CIRCUIT failed spell counts actual charged mana")
 g.state.energy=0;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state==before,"CIRCUIT cannot use future refunds to pay an unaffordable spell")
 # Existing optional extra mana payment also reaches the same meter.
 g=fresh();t.action(g,"attack",{"type":"fireball"});activate(t,g,true);spend(t,g);spend(t,g);card=Cards.give(g,"embers");energy=g.state.energy
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.powers[0].power_mana_progress==2 and g.state.energy==energy+1,"CIRCUIT six plus six payment crosses thirty and preserves remainder")
 g.Cards.end_powers(g)
 t.check(g.state.powers.is_empty() and g.state.discard.all(func(c):return not c.has("power_mana_progress")) and g.validate()=="","CIRCUIT battle cleanup removes each counter from physical cards")
 # Replay doubles one cast's effect, ordinary duplicates each keep their own meter.
 g=fresh();g.Cards.grant_buff(g,"echo_cast_bound");activate(t,g,false);spend(t,g);spend(t,g)
 t.check(g.state.powers[0].power_stacks==2 and g.state.charge==2,"CIRCUIT existing ability replay stacks once on one meter")
 var bad=g.export_snapshot();bad.powers[0].power_mana_progress=20
 t.check(not g.restore_snapshot(bad).ok,"CIRCUIT snapshot rejects an unsettled threshold")

 # The spell that crosses the threshold must not consume its newly awarded charge.
 g=fresh();activate(t,g,false);spend(t,g);g.state.wall="normal"
 var target=g.add_fixture("ankle",30,60);card=Cards.give(g,"magic_slip")
 c=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false})
 var damage=c.payload.preview.damage
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.charge==1 and is_equal_approx(g._equipment(target.id).durability,30-damage),"CIRCUIT triggering spell deals its preview damage and leaves new charge for the next action")
 # Existing powers keep working after the body condition changes.
 g=fresh();activate(t,g,true);g.add_fixture("wrist",10)
 energy=g.state.energy
 for i in range(3):
  card=Cards.give(g,"mana_conversion")
  t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok,"CIRCUIT unrestricted conversion pays mana after arms become restricted")
 t.check(g.state.energy==energy+8 and g.state.powers[0].power_mana_progress==0,"CIRCUIT body restriction only applies when activating the free face")

 # A multi-step card pays once; its award waits until the continuation finishes.
 g=fresh();activate(t,g,false);spend(t,g)
 var first=g.add_fixture("thigh",4,10,true);var second=g.add_fixture("ankle",4,10,true)
 card=Cards.give(g,"double_unlock")
 t.check(t.action(g,"card",{"uid":card.uid,"target":first.id,"free":false}).ok and not g.state.card_chain.is_empty() and g.state.charge==0 and g.state.powers[0].power_mana_progress==20 and g.validate()=="","CIRCUIT multi-step payment queues reward until whole card completes")
 t.check(t.action(g,"chain",{"target":second.id}).ok and g.state.card_chain.is_empty() and g.state.charge==1 and g.state.powers[0].power_mana_progress==0,"CIRCUIT continuation awards charge once without paying or counting mana twice")

 g=fresh();activate(t,g,false);g.state.mana=10;g.state.temporary_mana=30
 card=Cards.give(g,"henshin")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.mana==0 and g.state.temporary_mana==0 and g.state.charge==2 and g.state.powers[0].power_mana_progress==0,"CIRCUIT one forty-mana payment crosses two thresholds across both mana pools")
