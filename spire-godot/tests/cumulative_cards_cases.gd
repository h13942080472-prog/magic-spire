extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const Book=preload("res://data/encyclopedia.gd")

static func setup():
 var g=Game.new(42);g._discard_end();g.state.energy=30
 for e in g.state.enemies: e.hp=200;e.max_hp=200
 return g

static func run(t) -> void:
 var rules=preload("res://data/card_rules.gd")
 for type in ["magic_hand","magic_hand_gift","echo_cast"]:
  for free in [false,true]:
   t.check(not rules.unique_face(type,free) and not Book.card(type).face_keywords["free" if free else "bound"].any(func(x):return x.name=="唯一"),"CUMULATIVE cards no longer display unique")
 t.check("double_unlock" not in rules.REWARDS and rules.SPECS.double_unlock.encyclopedia_hidden and rules.SPECS.double_unlock.reward_excluded,"REMOVED double unlock excluded from random rewards, shop and encyclopedia")
 var g=setup()
 for n in range(3): t.check(Give.play(t,g,"echo_cast",true).ok and g.state.card_buff_uses.echo_cast_free==n+1,"ECHO free face accumulates one replay per play")
 var before=g.export_snapshot();var shot=t.find_action(g,"attack",{"type":"fireball"});var hp=g.state.enemies[0].hp
 t.check(g.dispatch(g.command(shot.payload,g.state.version),g.state.version).ok and g.state.enemies[0].hp==hp-shot.payload.damage*4 and g.state.mana==before.mana-shot.mana and g.BasicAttacks.usage(g,"fireball").used==1,"ECHO three stacks create three extra hits with one payment and use")
 t.check(not g.state.card_buff_uses.has("echo_cast_free") and not g.state.card_buffs.has("echo_cast_free"),"ECHO consumes all matching stacks together")
 g=setup()
 for n in range(3): t.check(Give.play(t,g,"echo_cast",false).ok and g.state.card_buff_uses.echo_cast_bound==n+1,"ECHO bound face accumulates despite replaying its own preparation")
 var copy=Game.new(0);t.check(copy.restore_snapshot(g.export_snapshot()).ok and copy.state.card_buff_uses.echo_cast_bound==3,"ECHO stacked count survives snapshot")
 t.check(Give.play(t,g,"adaptability",false).ok and g.state.powers[0].power_stacks==4,"ECHO stacked replay applies repeatable power four times")
 t.check(t.action(g,"end").ok and g.state.charge==4,"ECHO repeated power uses actual stack count at turn start")
 g=setup();Give.play(t,g,"echo_cast",false)
 t.check(rules.distinct_faces("mana_surge") and Give.play(t,g,"mana_surge",false).ok and g.state.charge==4 and not g.state.card_buffs.has("echo_cast_bound"),"SURGE different faces now qualify for bound replay")
 g=setup();var card=Give.give(g,"mana_surge");var c=t.find_action(g,"card",{"uid":card.uid,"free":true});before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SURGE stale request preserves both mana pools")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.temporary_mana==10 and g.state.charge==0 and g.state.exhaust.any(func(x):return x.uid==card.uid),"SURGE free face grants two layers of reserve mana and exhausts")
 var face=Book.card("mana_surge").face_mana.free
 t.check(face.size()==1 and face[0].kind=="temporary" and face[0].amount==10,"SURGE free badge shows only ten temporary mana and no cost")
 var embers=Book.card("embers")
 t.check(embers.face_mana.bound[0].amount==6 and embers.face_mana.free[0].amount==6 and embers.face_effects.bound.contains("再耗6魔力"),"EMBERS printed cost and optional cost both read six from rules")
