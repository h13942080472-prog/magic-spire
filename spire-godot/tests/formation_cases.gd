extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Practiced=preload("res://tests/practiced_cases.gd")

static func setup():
 var g=Game.new(42);g._discard_end();g.state.energy=30;g.state.relics=[]
 for enemy in g.state.enemies: enemy.hp=300;enemy.max_hp=300
 return g

static func activate(t,g,free: bool) -> void:
 t.check(Cards.play(t,g,"formation",free).ok,"FORMATION activates requested face through formal card action")

static func run(t) -> void:
 var g=setup();var rules=g.Cards.Rules
 t.check("formation" in rules.UNCOMMON and rules.SPECS.formation.card_type=="power" and rules.SPECS.formation.rarity=="uncommon" and rules.definition_reason(rules.SPECS.formation)=="","FORMATION uncommon power belongs to acquisition pool")
 for free in [false,true]:
  t.check(rules.energy_cost("formation",free)==2 and not rules.unique_face("formation",free) and not rules.face_casts("formation",free),"FORMATION both faces cost two without casting and allow stacking")
 requirements(t)
 free_face(t)
 bound_face(t)
 lifecycle(t)
 replay(t)

static func requirements(t) -> void:
 # Both body regions are tested separately; an OR must not become an AND.
 for arms in [false,true]:
  for legs in [false,true]:
   var g=setup()
   if arms: g.add_fixture("wrist",8)
   if legs: g.add_fixture("ankle",8)
   var card=Cards.give(g,"formation")
   t.check((g.restraint_degree("arms")>1)==arms and (g.restraint_degree("legs")>1)==legs,"FORMATION fixture straddles strictness threshold")
   for free in [false,true]:
    var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
    var expected=not arms if free else not (arms and legs)
    t.check(c.valid==expected,"FORMATION free upper limit and bound upper-or-legs limit")
    if not expected:
     var before=g.export_snapshot()
     t.check(c.reason.contains("严密度") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"FORMATION blocked requirement cannot spend resources or activate power")
 var g=setup();g.add_fixture("upper_arm",8);g.add_fixture("forearm",8)
 t.check(g.restraint_degree("arms")==1,"FORMATION exact upper threshold fixture")
 activate(t,g,true)
 g.add_fixture("wrist",8)
 t.check(g.Cards.energy_cost(g,"ease",true)==0,"FORMATION requirements are checked on activation, not continuously")

static func free_face(t) -> void:
 var g=setup();activate(t,g,true)
 var card=Cards.give(g,"ease");var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(c.valid and c.cost==0 and g.Cards.text_entry(g,"ease").face_costs.free=="0" and g.state==before,"FORMATION immediate discount agrees with candidate and card face without mutating queries")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"FORMATION stale request cannot consume the buff")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==before.energy and g.Cards.energy_cost(g,"ease",true)==1,"FORMATION one-energy card actually pays zero then loses discount")
 activate(t,g,true)
 t.check(g.Cards.energy_cost(g,"ease",true)==0,"FORMATION newly played copy grants a use even after earlier magic this turn")
 activate(t,g,true)
 t.check(g.Cards.energy_cost(g,"henshin",true)==2,"FORMATION free copies add reductions on the same next magic card")
 card=Cards.give(g,"mana_surge");c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 t.check(c.cost==0 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.Cards.energy_cost(g,"henshin",true)==4,"FORMATION naturally zero-cost magic consumes all discount stacks without refund")
 g=setup();activate(t,g,true);g.state.pressure=75
 card=Cards.give(g,"mana_surge");Practiced.force_failure(g,"mana_surge");c=t.find_action(g,"card",{"uid":card.uid,"free":false});before=g.export_snapshot()
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and g.state.hand.any(func(x):return x.uid==card.uid) and g.Cards.energy_cost(g,"ease",true)==1 and g.state.energy==before.energy,"FORMATION failed zero-cost cast still consumes buff and keeps card in hand")

static func bound_face(t) -> void:
 var g=setup();activate(t,g,false);activate(t,g,false);activate(t,g,true);g.state.pressure=75
 t.check(g.cast_view().chance<1 and g.cast_view(g.Cards.cast_profile(g,"fireball")).chance<1 and g.cast_view(g.Cards.cast_profile(g,"mana_surge")).chance==1,"FORMATION guarantees magic cards only, not global or fixed spell views")
 var before=g.export_snapshot()
 t.check(Cards.play(t,g,"strain",true).ok and g.state.powers.map(func(x):return x.power_magic_remaining)==[1,1,1],"FORMATION skills do not spend either face")
 for n in range(2):
  var card=Cards.give(g,"mana_surge");var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
  var rng=g.state.rng.magic
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and not g._magic_failed and g.state.rng.magic==rng,"FORMATION stacked guaranteed zero-cost cards do not roll RNG")
  t.check(g.state.powers[0].power_magic_remaining==0 and g.state.powers[1].power_magic_remaining==1-n and g.state.powers[2].power_magic_remaining==0,"FORMATION guarantee consumes one stack per card while free face consumes all")
 t.check(g.cast_view(g.Cards.cast_profile(g,"mana_surge")).chance<1,"FORMATION third card returns to ordinary chance")
 g=setup();activate(t,g,false);g.add_fixture("palm",8)
 var card=Cards.give(g,"siphon_strength");var c=t.find_action(g,"card",{"uid":card.uid,"free":false});before=g.export_snapshot()
 t.check(not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before and g.state.powers[0].power_magic_remaining==1,"FORMATION guarantee does not bypass a blocked hand casting route")
 g=setup();activate(t,g,false);activate(t,g,true)
 t.check(Cards.play(t,g,"siphon",false).ok and g.state.powers.all(func(x):return x.power_magic_remaining==0),"FORMATION zero-cost non-casting magic face consumes both buffs")
 g=setup();activate(t,g,false);activate(t,g,true)
 t.check(t.action(g,"attack",{"type":"fireball"}).ok and g.state.powers.all(func(x):return x.power_magic_remaining==1),"FORMATION using fixed fireball spends neither buff")
 var insufficient=Cards.give(g,"henshin");g.state.mana=0;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":insufficient.uid,"free":true}).ok and g.state==before,"FORMATION insufficient mana rejects atomically without spending charges")

static func lifecycle(t) -> void:
 var g=setup();activate(t,g,false);activate(t,g,true)
 Cards.play(t,g,"siphon",false)
 var restored=Save.roundtrip(t,g,"formation exhausted this turn")
 if restored!=null: t.check(restored.state.powers.all(func(x):return x.power_magic_remaining==0) and restored.Cards.energy_cost(restored,"ease",true)==1,"FORMATION save preserves exhausted quotas")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.powers.all(func(x):return x.power_magic_remaining==1),"FORMATION real next player turn refreshes both faces")
 for invalid in [-1,2,"1",null]:
  var bad=g.export_snapshot();bad.powers[0].power_magic_remaining=invalid
  var copy=setup();var before=copy.export_snapshot()
  t.check(not copy.restore_snapshot(bad).ok and copy.state==before,"FORMATION malformed saved quota is rejected atomically")
 var missing=g.export_snapshot();missing.powers[0].erase("power_magic_remaining")
 t.check(not setup().restore_snapshot(missing).ok,"FORMATION missing saved quota cannot refresh a used buff")
 g.Cards.end_powers(g)
 t.check(g.state.powers.is_empty() and g.state.discard.all(func(x):return not x.has("power_magic_remaining")) and g.Cards.energy_cost(g,"ease",true)==1,"FORMATION scene cleanup removes quotas from physical cards")

static func replay(t) -> void:
 var g=setup();Cards.play(t,g,"echo_cast",false);activate(t,g,false)
 t.check(g.state.powers.size()==1 and g.state.powers[0].power_stacks==2 and g.state.powers[0].power_magic_remaining==2,"FORMATION replayed activation grants stacked guaranteed uses")
 Cards.play(t,g,"echo_cast",false);g.state.pressure=75
 var card=Cards.give(g,"mana_surge");var start=g.state.logs.size()
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.powers[0].power_magic_remaining==1,"FORMATION replayed magic spends only original card quota")
 var spells=g.state.logs.slice(start).filter(func(x):return x.data.has("spell"))
 t.check(spells.size()==2 and spells[0].data.spell.chance==1 and spells[1].data.spell.chance<1,"FORMATION replay does not inherit the next-card guarantee")
 g=setup();Cards.play(t,g,"echo_cast",false);activate(t,g,true)
 # Free powers are not replayed by the bound-card replay effect.
 t.check(g.state.powers[0].power_magic_remaining==1,"FORMATION replay respects the selected face")
