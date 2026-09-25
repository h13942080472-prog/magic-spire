extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Book=preload("res://data/encyclopedia.gd")

static func setup(t, free: bool):
 var g=Game.new(42);g._discard_end();g.state.energy=30
 t.check(Cards.play(t,g,"practiced",free).ok,"PRACTICED activates either face without casting or mana")
 return g

static func force_failure(g, type: String) -> void:
 var rng=g.state.rng.get("magic",0)
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,type)).winning_rolls: rng=g.state.rng.magic
 g.state.rng.magic=rng

static func run(t) -> void:
 var rules=preload("res://data/card_rules.gd")
 t.check("practiced" in rules.RARE and rules.energy_cost("practiced",false)==2 and rules.energy_cost("practiced",true)==2,"PRACTICED rare reward and shop pool, both faces cost two")
 var page=Book.card("practiced")
 t.check(page.face_keywords.free.any(func(x):return x.name=="唯一") and page.face_keywords.bound.any(func(x):return x.name=="牵扯"),"PRACTICED encyclopedia explains both keywords")
 t.check(rules.unique_face("henshin",true) and not rules.unique_face("flame_flourish",true) and rules.unique_face("flame_flourish",false),"UNIQUE follows existing face stacking rules")
 var g=setup(t,true);g.state.pressure=75
 t.check(g.state.powers[0].power_cast_count==0 and is_equal_approx(g.cast_view().chance,0.25),"PRACTICED activation does not count itself")
 var card=Cards.give(g,"strain");var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"PRACTICED queries and stale actions do not grow chance")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.powers[0].power_cast_count==1 and is_equal_approx(g.cast_view().chance,0.28),"PRACTICED successful card adds three percentage points after multipliers")
 g.state.powers[0].power_cast_count=40
 t.check(g.cast_view().chance==1,"PRACTICED chance caps at one hundred percent")
 g.state.powers[0].power_cast_count=1
 var copy=Game.new(0);t.check(copy.restore_snapshot(g.export_snapshot()).ok and is_equal_approx(copy.cast_view().chance,0.28),"PRACTICED snapshot preserves current turn bonus")
 var bad=g.export_snapshot();bad.powers[0].power_cast_count=-1;before=copy.export_snapshot()
 t.check(not copy.restore_snapshot(bad).ok and copy.state==before,"PRACTICED corrupted progress rejected atomically")
 g._begin_player_turn();t.check(g.state.powers[0].power_cast_count==0,"PRACTICED new player turn resets counter")
 g=setup(t,true);g.state.pressure=75;card=Cards.give(g,"mana_surge");force_failure(g,"mana_surge")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g._magic_failed and g.state.powers[0].power_cast_count==0,"PRACTICED failed magic left in hand is not a played card")
 g=setup(t,false);g.state.pressure=90
 t.check(is_equal_approx(g.cast_view().chance,0.75),"PRACTICED floor applies after pressure multiplier")
 var mouth=g.add_fixture("mouth",8);mouth.grade=3
 t.check(is_equal_approx(g.cast_view().chance,0.75),"PRACTICED floor applies even when mouth multiplier is zero")
 g.state.equipment.clear();g.add_fixture("palm",8)
 t.check(g.cast_view({"parts":["hand"],"multiplier":1.0}).chance==0,"PRACTICED floor does not bypass blocked hand route")
 g.state.equipment.clear();g.state.pressure=0
 t.check(g.cast_view().chance==1,"PRACTICED floor never lowers a higher chance")
 t.check(Cards.play(t,g,"practiced",true).ok and g.state.powers.size()==2,"PRACTICED two different faces coexist")
 for free in [false,true]:
  card=Cards.give(g,"practiced");before=g.export_snapshot()
  t.check(not t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.state==before,"PRACTICED same face rejects duplicate atomically")
 g=Game.new(42);g._discard_end();g.state.energy=30
 Cards.play(t,g,"echo_cast",false)
 t.check(Cards.play(t,g,"practiced",false).ok and g.Cards.buff_stacks(g,"practiced_bound")==1,"UNIQUE replay cannot double the power")
 traction(t)
 traction_sources(t)

static func traction(t) -> void:
 for type in ["ease","mana_invocation","mana_surge"]:
  for failed in [false,true]:
   if type=="ease" and failed: continue
   var g=setup(t,false);Cards.give(g,"lewd_mark")
   var card=Cards.give(g,type);g.state.pressure=75 if failed else 0
   if failed: force_failure(g,type)
   var c=t.find_action(g,"card",{"uid":card.uid,"free":type=="ease"})
   var before=g.export_snapshot();var start=g.state.logs.size()
   t.check(c.valid and g.candidate_detail(c).contains("额外牵扯"),"TRACTION zero-cost and paid magic facts explain extra pulse")
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed==failed,"TRACTION commits successful and failed magic cards")
   t.check(is_equal_approx(g.state.pressure,before.pressure+4*(2 if c.cost>0 else 1)) and g.state.energy==before.energy-c.cost,"TRACTION one extra one-energy pulse without extra payment")
   t.check(g.state.logs.slice(start).filter(func(x):return x.data.has("traction")).size()==1,"TRACTION extra pulse logged once per card")
 var g=setup(t,false);Cards.give(g,"lewd_mark")
 var before=g.state.pressure
 t.check(Cards.play(t,g,"strain",true).ok and g.state.pressure==before+4,"TRACTION skill cards only trigger ordinary payment")
 g.state.pressure=0
 t.check(t.action(g,"attack",{"type":"fireball"}).ok and g.state.pressure==4,"TRACTION fixed fireball is not a magic card")

static func traction_sources(t) -> void:
 var g=setup(t,false)
 var rod=g._install_special("urethral_rod_low","special_2_d")
 t.check(not rod.is_empty() and Cards.play(t,g,"mana_invocation",false).ok and g.state.pressure==12,"TRACTION paid card triggers equipment once normally and once extra")
 var before=g.state.pressure
 t.check(Cards.play(t,g,"mana_surge",false).ok and g.state.pressure==before+6,"TRACTION zero-cost magic still triggers equipment once")
 g=Game.new(42,true,"drone_solo");g._discard_end();g.state.energy=30
 Cards.play(t,g,"practiced",false);g.CaptureBind.apply_bind(g,g.state.enemies[0])
 var count=g.state.equipment.size();var progress=g.state.guard_bind.progress
 t.check(Cards.play(t,g,"mana_surge",false).ok and g.state.guard_bind.sources.drone.energy==1,"TRACTION zero-cost card advances drone by exactly one virtual energy")
 t.check(Cards.play(t,g,"mana_surge",false).ok and g.state.guard_bind.sources.drone.energy==0 and g.state.guard_bind.progress==progress+10 and g.state.equipment.size()>count,"TRACTION two pulses use original drone threshold and equipment transaction")
 g=Game.new(42,true,"guard");g._discard_end();g.state.energy=30
 Cards.play(t,g,"practiced",false);g.CaptureBind.apply_bind(g,g.state.enemies[0]);var rng=g.state.rng.get("capture_bind",0)
 t.check(Cards.play(t,g,"mana_surge",false).ok and g.state.rng.get("capture_bind",0)==rng+1 and g.state.pressure>0,"TRACTION extra pulse reaches guard sensitivity through original handler")
 g=setup(t,true);g.state.pressure=75;g.state.powers[0].power_cast_count=1;g.state.card_buffs.append("fire_dynamics_bound")
 t.check(is_equal_approx(g.cast_view(g.Cards.cast_profile(g,"fireball")).chance,0.58),"PRACTICED independent bonus adds after multiplier alongside existing spell bonus")
 g.state.card_buffs.erase("fire_dynamics_bound")
 g.Cards.end_powers(g)
 t.check(g.state.powers.is_empty() and not g.state.discard.any(func(card):return card.has("power_cast_count")) and is_equal_approx(g.cast_view().chance,0.25),"PRACTICED ending the scene clears bonus and card counter")
