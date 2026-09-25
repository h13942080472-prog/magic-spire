extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func run(t) -> void:
 var g=Game.new(42)
 for type in ["fire_mastery","fire_dynamics","practiced"]:
  t.check(g.can_offer_card(type) and g.reward_offer([type])==[type],"UNIQUE unowned power remains obtainable "+type)
  var card=Cards.give(g,type)
  var before=g.export_snapshot()
  t.check(not g.can_offer_card(type) and g.reward_offer([type]).is_empty() and g.export_snapshot()==before,"UNIQUE ownership filters without RNG or state writes "+type)
  g.state.energy=10
  t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and not g.can_offer_card(type),"UNIQUE playing into powers does not restore eligibility "+type)
  g.Cards.remove_permanent(g,card.uid)
  t.check(g.can_offer_card(type) and g.reward_offer([type])==[type],"UNIQUE removing last permanent copy restores pool "+type)
 for type in ["resonance","flame_flourish","mana_circuit","magic_hand","henshin"]:
  Cards.give(g,type)
  t.check(g.can_offer_card(type) and g.reward_offer([type])==[type],"UNIQUE single unique face or non-power still repeats "+type)
 var first=Cards.give(g,"practiced");var second=Cards.give(g,"practiced")
 g.Cards.remove_permanent(g,first.uid)
 t.check(not g.can_offer_card("practiced"),"UNIQUE removing one of two copies stays excluded")
 g.Cards.remove_permanent(g,second.uid)
 t.check(g.can_offer_card("practiced"),"UNIQUE removing second copy restores eligibility")
 g=Game.new(42)
 for type in ["fire_mastery","fire_dynamics","practiced"]: Cards.give(g,type)
 for source in ["fixed","normal","elite","boss"]:
  var chosen=g.reward_offer(g.Cards.Rules.REWARDS,source)
  t.check(chosen.size()==3 and chosen.all(func(type):return g.can_offer_card(type)),"UNIQUE every reward source filters owned powers "+source)
 var restored=Game.new(7)
 t.check(restored.restore_snapshot(g.export_snapshot()).ok and not restored.can_offer_card("fire_mastery"),"UNIQUE eligibility is derived after save restore")

static func shop(t) -> void:
 var g=Game.new(42,true,"shop")
 var room=g.room_data(g.state.room)
 room.stock=[{"kind":"card","type":"fire_mastery","price":20.0,"taken":false}]
 var stale=t.find_action(g,"service",{"op":"take","index":0,"payment":"self"})
 var card=Cards.give(g,"fire_mastery")
 var before=g.export_snapshot()
 t.check(g.get_view().shop.stock.is_empty() and not g.command_facts().any(func(c):return c.payload.kind=="service" and c.payload.get("op","")=="take"),"UNIQUE existing unsold shop card hides when owned")
 t.check(not g.dispatch(g.command(stale.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"UNIQUE hidden stale purchase cannot spend resources")
 g.Cards.remove_permanent(g,card.uid)
 t.check(g.get_view().shop.stock.size()==1 and t.find_action(g,"service",{"op":"take","index":0,"payment":"self"}).valid,"UNIQUE unsold stock returns after last copy removed")
