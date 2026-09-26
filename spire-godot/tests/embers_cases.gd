extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func play(t,g,type: String,free: bool) -> Dictionary:
 var card=Cards.give(g,type)
 return t.action(g,"card",{"uid":card.uid,"free":free})

static func primed(t):
 var g=Game.new(42)
 for enemy in g.state.enemies: enemy.hp=200;enemy.max_hp=200
 t.check(t.action(g,"attack",{"type":"fireball"}).ok and not g._magic_failed,"EMBERS prerequisite uses a real successful fireball")
 g._discard_end()
 return g

static func prerequisite(t) -> void:
 var g=Game.new(42);g.state.energy=20
 var card=Cards.give(g,"embers");var before=g.export_snapshot()
 var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
 t.check(not c.valid and c.reason.contains("尚未成功使用火球术") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"EMBERS bound prerequisite rejects atomically before any fireball")
 g.state.pressure=99;c=t.find_action(g,"attack",{"type":"fireball"})
 var rng=g.state.rng.magic
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"fireball")).winning_rolls: rng=g.state.rng.magic
 g.state.rng.magic=rng
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and not t.find_action(g,"card",{"uid":card.uid,"free":false}).valid,"EMBERS failed fireball does not unlock bound face")
 g=primed(t);g.state.energy=20
 t.check(play(t,g,"rekindle",false).ok and g.state.combat.attack_uses.fireball==0,"EMBERS refresh clears use limit")
 card=Cards.give(g,"embers")
 t.check(t.find_action(g,"card",{"uid":card.uid,"free":false}).valid,"EMBERS refresh keeps actual success history")
 var restored=Save.roundtrip(t,g,"EMBERS successful cast in current turn")
 if restored!=null: t.check(t.find_action(restored,"card",{"uid":card.uid,"free":false}).valid,"EMBERS restored success still permits bound face")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.combat.successful_spells.is_empty(),"EMBERS success history resets at next player turn")
 card=Cards.give(g,"embers")
 t.check(not t.find_action(g,"card",{"uid":card.uid,"free":false}).valid,"EMBERS previous turn fireball cannot unlock this turn")

static func run(t) -> void:
 prerequisite(t)
 for sample in [[6.0,1,0.0],[11.9,1,5.9],[12.0,2,0.0]]:
  var g=primed(t);g.state.mana=sample[0];g.state.energy=0
  var card=Cards.give(g,"embers")
  var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
  var before=g.export_snapshot();g.get_view()
  t.check(c.cost==0 and c.mana==6 and g.state==before,"EMBERS preview only requires base payment and does not draw")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.hand.size()==sample[1] and is_equal_approx(g.state.mana,sample[2]) and g.state.energy==0,"EMBERS optional fixed payment follows remaining balance including fractional boundary")
 var g=primed(t);g.state.mana=6;g.state.temporary_mana=6;g.state.energy=0
 g.RelicEffects.gain(g,"mana_earring");g.state.combat.mana_spent=25
 t.check(play(t,g,"embers",false).ok and g.state.hand.size()==2 and g.state.mana==0 and g.state.temporary_mana==0 and g.state.energy==1,"EMBERS temporary mana pays first; extra self payment triggers existing mana relic")
 g=Game.new(42);g._discard_end();g.state.energy=20
 for enemy in g.state.enemies: enemy.hp=200;enemy.max_hp=200
 t.check(play(t,g,"fire_mastery",true).ok and play(t,g,"fire_dynamics",true).ok and play(t,g,"embers",true).ok,"EMBERS fire damage and area powers combine")
 var enhanced=g.BasicAttacks.fireball_damage(g)
 t.check(enhanced==(g.B.FIREBALL_ASSISTED+4)*2 and g.get_view().statuses.any(func(s):return s.name=="余火"),"EMBERS adds before multiplication and exposes a real status")
 var duplicate=Cards.give(g,"embers");var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":duplicate.uid,"free":true}).ok and g.state==before,"EMBERS duplicate same-source preparation rejects without payment")
 g.state.pressure=99
 var c=t.find_action(g,"attack",{"type":"fireball"})
 var rng=g.state.rng.magic
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"fireball")).winning_rolls: rng=g.state.rng.magic
 g.state.rng.magic=rng
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and "embers_free" in g.state.card_buffs,"EMBERS failed fireball preserves preparation")
 g.state.pressure=0
 for repeat in range(2):
  var hp=g.state.enemies.map(func(e):return e.hp)
  t.check(t.action(g,"attack",{"type":"fireball"}).ok and range(hp.size()).all(func(i):return g.state.enemies[i].hp==hp[i]-enhanced) and "embers_free" in g.state.card_buffs,"EMBERS every successful area cast this turn keeps full bonus")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and "embers_free" not in g.state.card_buffs and g.BasicAttacks.fireball_damage(g)==g.B.FIREBALL_ASSISTED*2,"EMBERS turn end expires bonus without removing battle powers")
 g=Game.new(42);g._discard_end();g.state.energy=20
 play(t,g,"flame_flourish",false);play(t,g,"embers",true)
 var target=g.add_fixture("thigh",60,60,true)
 c=t.find_action(g,"attack",{"type":"fireball","target":target.id})
 t.check(c.payload.damage==(g.B.FIREBALL_ASSISTED+4)*0.5 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and "embers_free" in g.state.card_buffs and "fireball" in g.state.combat.successful_spells,"EMBERS equipment fireball uses half enhanced damage, keeps turn bonus and records success")
 for free in [false,true]:
  g=Game.new(42) if free else primed(t);g._discard_end();g.state.pressure=99
  var card=Cards.give(g,"embers")
  c=t.find_action(g,"card",{"uid":card.uid,"free":free})
  rng=g.state.rng.magic
  while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"embers")).winning_rolls: rng=g.state.rng.magic
  g.state.rng.magic=rng;before=g.export_snapshot()
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and g.state.hand==before.hand and is_equal_approx(g.state.mana,before.mana-c.mana*0.5) and g.state.card_buffs==before.card_buffs,"EMBERS failed either face keeps card and grants no draw, extra payment or damage preparation")
