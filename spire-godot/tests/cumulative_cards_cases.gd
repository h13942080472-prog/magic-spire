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
 for n in range(3): t.check(Give.play(t,g,"echo_cast",true).ok and g.state.card_buff_uses.echo_recharge==n+1,"ECHO every free play adds a recharge layer")
 var before=g.export_snapshot()
 var copy=Game.new(0);t.check(copy.restore_snapshot(before).ok and copy.state.card_buff_uses.echo_recharge==3,"ECHO stacked recharge survives restore")
 g.Cards.grant_buff(g,"echo_cast_bound")
 t.check(rules.distinct_faces("mana_surge") and Give.play(t,g,"mana_surge",false).ok and g.state.charge==4 and not g.state.card_buffs.has("echo_cast_bound"),"SURGE different faces qualify for a saved bound replay")
 g=setup();var card=Give.give(g,"mana_surge");var c=t.find_action(g,"card",{"uid":card.uid,"free":true});before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SURGE stale request preserves both mana pools")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.temporary_mana==10 and g.state.charge==0 and g.state.exhaust.any(func(x):return x.uid==card.uid),"SURGE free face grants two layers of reserve mana and exhausts")
 var face=Book.card("mana_surge").face_mana.free
 t.check(face.size()==1 and face[0].kind=="temporary" and face[0].amount==2 and face[0].text=="+2","SURGE free badge shows two reserve mana layers")
 var embers=Book.card("embers")
 t.check(embers.face_mana.bound[0].amount==6 and embers.face_mana.free[0].amount==6 and embers.face_effects.bound.contains("再耗6魔力"),"EMBERS printed cost and optional cost both read six from rules")
