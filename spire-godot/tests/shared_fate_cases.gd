extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")

static func run(t) -> void:
 for free in [false,true]:
  for values in [[80.0,20.0],[10.0,71.0],[0.0,0.0]]:
   var g=Game.new(42);g.state.mana=values[0];g.state.pressure=values[1];g.state.energy=0
   g.state.temporary_mana=15;g.add_fixture("wrist",8);g.add_fixture("ankle",8)
   var card=Give.give(g,"shared_fate")
   var action=t.find_action(g,"card",{"uid":card.uid,"free":free})
   var before=g.export_snapshot();g.get_view();g.command_facts()
   t.check(action.valid and action.cost==0 and action.mana==0 and g.state==before,"FATE both faces are readonly, zero cost and have no body requirement")
   t.check(not g.dispatch(g.command(action.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"FATE rejected stale play preserves resources and card")
   var average=(values[0]+values[1])/2.0
   t.check(g.dispatch(g.command(action.payload,g.state.version),g.state.version).ok and g.state.mana==average and g.state.pressure==average,"FATE exact mean preserves fractional values on either face")
   t.check(g.state.energy==0 and g.state.temporary_mana==15 and g.state.equipment==before.equipment and g.state.tick==before.tick and g.state.discard.any(func(c):return c.uid==card.uid),"FATE normal discard leaves unrelated resources, equipment and turn unchanged")
 var g=Game.new(42)
 t.check("shared_fate" in g.Cards.Rules.RARE and "shared_fate" not in g.Cards.Rules.UNCOMMON and g.Cards.Rules.SPECS.shared_fate.rarity=="rare" and not g.Cards.Rules.distinct_faces("shared_fate") and g.B.card_info("shared_fate")[1]==g.B.card_info("shared_fate")[2],"FATE rare pool and identical face text use shared definition")
 Give.play(t,g,"mana_circuit",false)
 g.state.mana=90;g.state.pressure=10;g.state.relics=["marble_stone","mana_earring"]
 Give.give(g,"sensitive")
 var before=g.export_snapshot()
 t.check(Give.play(t,g,"shared_fate",false).ok and g.state.mana==50 and g.state.pressure==50,"FATE direct redistribution is not multiplied by gain modifiers")
 t.check(g.state.energy==before.energy and g.state.combat.mana_spent==before.combat.mana_spent and g.state.charge==before.charge,"FATE redistribution is not spell expenditure")
 g=Game.new(42);g.state.mana_max=40;g.state.mana=40;g.state.pressure=90
 t.check(Give.play(t,g,"shared_fate",true).ok and g.state.mana==40 and g.state.pressure==65,"FATE mean is computed before mana cap without transferring capped excess")
 g=Game.new(42);g.state.mana_max=150;g.state.mana=150;g.state.pressure=50
 t.check(Give.play(t,g,"shared_fate",false).ok and g.state.pressure==0 and g.state.mana==100-g.B.OVERLOAD_MANA and g.state.overload_total==1 and g.state.energy==0,"FATE reaching threshold invokes normal overload once after averaging")
 g=Game.new(42);g.state.mana_max=200;g.state.mana=200;g.state.pressure=50;g.state.relics=["green_bird"]
 g._install_special("negative_plate_lock_medium","special_2_a",2)
 t.check(Give.play(t,g,"shared_fate",true).ok and g.state.mana==125 and g.state.pressure==119 and g.state.overload_total==0,"FATE dynamic pressure cap prevents overflow after averaging")
