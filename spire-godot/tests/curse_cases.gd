extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const P=preload("res://core/pressure.gd")

static func give(g, type: String) -> Dictionary:
 g._gain_card(type)
 var card=g.state.discard.pop_back()
 g.state.hand.append(card)
 return card

static func play(t,g,type: String,free: bool,extra: Dictionary={}) -> Dictionary:
 var card=give(g,type)
 var payload={"uid":card.uid,"free":free};payload.merge(extra,true)
 return t.action(g,"card",payload)

static func run(t) -> void:
 var g=Game.new(42)
 var card=give(g,"panic")
 var choices=g.command_facts().filter(func(c):return c.payload.get("uid","")==card.uid)
 t.check(choices.size()==1 and choices[0].valid and choices[0].cost==1 and choices[0].payload.self_target,"CURSE panic has one targetless one-energy candidate")
 var before=g.export_snapshot()
 t.check(not g.dispatch(g.command(choices[0].payload,g.state.version-1),g.state.version-1).ok and g.state==before,"CURSE stale play cannot spend or exhaust")
 g.state.energy=0;before=g.export_snapshot()
 t.check(not g.dispatch(g.command(choices[0].payload,g.state.version),g.state.version).ok and g.state==before,"CURSE unaffordable play leaves everything unchanged")
 g.state.energy=3
 var equipment=JSON.stringify(g.state.equipment);var tick=g.state.tick;var mana=g.state.mana
 t.check(t.action(g,"card",{"uid":card.uid}).ok and g.state.energy==2 and g.state.exhaust.any(func(c):return c.uid==card.uid),"CURSE panic pays once and exhausts on play")
 t.check(JSON.stringify(g.state.equipment)==equipment and g.state.tick==tick and g.state.mana==mana and g.state.deck.size()==11,"CURSE no effect on equipment, turn, mana or permanent ownership")
 t.check(not t.action(g,"card",{"uid":card.uid}).ok,"CURSE exhausted card cannot replay")
 g._reset_piles()
 t.check(g.state.draw.any(func(c):return c.uid==card.uid) and g.state.exhaust.is_empty(),"CURSE next battle restores exhausted panic")
 card=give(g,"panic");g._discard_end()
 t.check(g.state.discard.any(func(c):return c.uid==card.uid) and g.state.exhaust.is_empty(),"CURSE unplayed panic discards, never ethereal")
 g=Game.new(42,true,"equipment");card=give(g,"panic")
 t.check(t.action(g,"card",{"uid":card.uid}).ok and g.state.energy==2,"CURSE targetless play allowed in rest despite free-effect ban")
 g=Game.new(42);g._install_assembly("wrap","left","fixture",1,1);g._install_assembly("wrap","right","fixture",1,1);card=give(g,"panic")
 t.check(t.action(g,"card",{"uid":card.uid}).ok,"CURSE panic does not require free hands or equipment targets")

 g=Game.new(42);card=give(g,"sensitive")
 t.check(not g.command_facts().any(func(c):return c.payload.get("uid","")==card.uid),"CURSE sensitive is unplayable")
 before=g.export_snapshot();var view=g.get_view()
 t.check(g.state==before and is_equal_approx(view.pressure.gain_multiplier,1.2) and view.statuses.any(func(s):return s.id=="hand_pleasure"),"CURSE readonly view derives current multiplier and status")
 t.check(view.hand.filter(func(c):return c.uid==card.uid)[0].retained,"CURSE innate retain shown immediately")
 P.gain(g,40,"测试来源")
 t.check(is_equal_approx(g.state.pressure,48) and g.state.logs.back().data.base_gain==40 and is_equal_approx(g.state.logs.back().data.gain_multiplier,1.2),"CURSE shared gain scales once and records base plus actual amount")
 t.check(t.action(g,"calm").ok and is_equal_approx(g.state.pressure,28),"CURSE lowering pressure is not multiplied")
 var copy=give(g,"sensitive")
 P.gain(g,10,"另一来源")
 t.check(is_equal_approx(g.state.pressure,42.4),"CURSE two actual hand copies multiply to 1.44")
 g.state.hand.erase(copy);g.state.discard.append(copy)
 t.check(is_equal_approx(g.Cards.hand_multiplier(g,"pleasure_multiplier"),1.2),"CURSE discarded copy immediately stops effect")
 g.state.hand.erase(card);g.state.exhaust.append(card)
 t.check(g.Cards.hand_multiplier(g,"pleasure_multiplier")==1,"CURSE deck and exhaust do not supply hand effect")

 g=Game.new(42);card=give(g,"sensitive");g._discard_end()
 t.check(g.state.hand.size()==1 and g.state.hand[0].uid==card.uid,"CURSE innate retain survives end-of-hand boundary")
 g.Cards.request_retain(g,2)
 t.check(not g.state.pending_retain,"CURSE innate retained card does not consume optional retain selection")
 g.state.phase="prepare";g.state.prepare_left=3
 t.check(t.action(g,"end").ok and g.state.hand.any(func(c):return c.uid==card.uid),"CURSE innate retain survives formal turn transition")
 g.state.pressure=30
 var saved=g.export_snapshot();var restored=Game.new(8)
 t.check(restored.restore_snapshot(saved).ok and is_equal_approx(restored.Cards.hand_multiplier(restored,"pleasure_multiplier"),1.2),"CURSE save restore derives modifier from hand without cached state")
 t.check(t.action(g,"calm").ok and t.action(restored,"calm").ok and is_equal_approx(g.state.pressure,restored.state.pressure) and g.state.energy==restored.state.energy,"CURSE restored game can commit equivalent next action")
 g.state.pressure=90;P.gain(g,10,"边界来源")
 var overload_actions=g.command_facts().filter(func(candidate):return candidate.payload.kind not in ["flask","item_discard"])
 t.check(g.state.overloaded and is_equal_approx(g.state.pressure,2) and g.state.hand.any(func(c):return c.uid==card.uid) and overload_actions.size()==1 and overload_actions[0].payload.kind=="end","CURSE multiplied gain crosses threshold while retained card grants no extra actions")
 P.gain(g,10,"后续来源")
 t.check(is_equal_approx(g.state.pressure,14),"CURSE retained card still affects later sources after overload")

 g=Game.new(42);card=give(g,"sensitive")
 g.state.pressure_sources=[preload("res://tests/pressure_cases.gd").source("curse_end","turn_end",10)]
 t.check(g.Pressure.action_risk(g,{"kind":"end"}).contains("12"),"CURSE turn-end preview includes hand multiplier")
 t.check(t.action(g,"end").ok and is_equal_approx(g.state.pressure,10),"CURSE formal turn-end source multiplies gain before fixed free cooling")
 g=Game.new(42);card=give(g,"sensitive")
 var type=g.SpecialEquipment.TYPES.keys().filter(func(id):return g.SpecialEquipment.TYPES[id].energy_gain>0)[0]
 var item=g._install_special(type,g.SpecialEquipment.DESIGNS[type].slots[0])
 var expected=g.SpecialEquipment.gain(item,"energy")*1.2
 var panic=give(g,"panic")
 t.check(t.action(g,"card",{"uid":panic.uid}).ok and is_equal_approx(g.state.pressure,expected),"CURSE panic energy payment triggers equipment exactly once through global multiplier")
 t.check(g.state.exhaust.any(func(c):return c.uid==panic.uid) and g.state.hand.any(func(c):return c.uid==card.uid),"CURSE payment stimulus preserves correct card destinations")
 for bad in [0,-1,INF,NAN,"1.2"]:
  t.check(g.Cards.Rules.definition_reason({"hand_modifiers":{"pleasure_multiplier":bad}})!="","CURSE invalid multiplier rejected")
 t.check("sensitive" not in g.Cards.Rules.REWARDS and "panic" not in g.Cards.Rules.REWARDS,"CURSE curses do not enter ordinary rewards")

 g=Game.new(42);var mark=give(g,"lewd_mark");var paid=give(g,"panic")
 t.check(not g.command_facts().any(func(c):return c.payload.get("uid","")==mark.uid),"CURSE lewd mark is unplayable")
 var mark_view=g.get_view()
 t.check(mark_view.statuses.any(func(status):return status.id=="hand_energy_pressure" and status.value.contains("4")),"CURSE lewd mark exposes its current paid-energy pressure in status view")
 var mark_before=g.export_snapshot()
 t.check(not g.dispatch(g.command({"kind":"card","uid":"missing"},g.state.version),g.state.version).ok and g.state==mark_before and g.state.pressure==0,"CURSE rejected action never triggers lewd mark")
 t.check(t.action(g,"card",{"uid":paid.uid}).ok and g.state.pressure==4,"CURSE one-energy action triggers one lewd-mark gain after commit")

 g=Game.new(42);mark=give(g,"lewd_mark");give(g,"lewd_mark");var target=g.add_fixture("ankle",10);paid=give(g,"tear")
 t.check(t.action(g,"card",{"uid":paid.uid,"target":target.id}).ok and g.state.pressure==8,"CURSE two lewd marks each trigger once on a two-energy action")
 g=Game.new(42);mark=give(g,"lewd_mark");give(g,"sensitive");paid=give(g,"panic")
 t.check(t.action(g,"card",{"uid":paid.uid}).ok and is_equal_approx(g.state.pressure,4.8),"CURSE sensitive multiplies lewd-mark pressure through the shared gain path")
 g=Game.new(42);mark=give(g,"lewd_mark")
 t.check(t.action(g,"end").ok and g.state.pressure==0,"CURSE zero-cost turn action does not trigger lewd mark")
 for bad in [0,-1,INF,NAN,"4"]:
  t.check(g.Cards.Rules.definition_reason({"hand_modifiers":{"energy_pressure":bad}})!="","CURSE invalid paid-energy pressure rejected")
 t.check("lewd_mark" not in g.Cards.Rules.REWARDS,"CURSE lewd mark stays outside ordinary rewards")
