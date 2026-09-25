extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const F=preload("res://tests/follow_through_cases.gd")

static func run(t) -> void:
 var g=F.fresh()
 var spec=g.Cards.Rules.SPECS.leverage
 t.check(spec.cost==1 and spec.rarity=="common" and spec.card_type=="skill" and "leverage" in g.Cards.Rules.COMMON and g.Cards.Rules.definition_reason(spec)=="","LEVERAGE registered common one-energy skill")
 var card=Give.give(g,"leverage")
 t.check(g.Cards.base_damage(g,"leverage")==0,"LEVERAGE empty equipment gives zero printed damage")
 var special=g._install_special("vaginal_egg_low","special_3_a")
 t.check(not special.is_empty() and g.Cards.base_damage(g,"leverage")==0 and g.Cards.worn_count(g)==1,"LEVERAGE excludes special equipment without changing existing power counts")
 var target=F.piece(g,"thigh","thigh_root",80,100)
 var composite=g._install_assembly("glove","short","fixture",2,1)
 t.check(not composite.is_empty() and g.Cards.base_damage(g,"leverage")==4,"LEVERAGE ordinary and composite each count once despite composite coverage")
 composite.components.filter(func(piece):return piece.part=="body")[0].durability=0
 t.check(g.Cards.base_damage(g,"leverage")==2,"LEVERAGE inactive composite stops counting immediately")
 g._cleanup()
 var peer=F.piece(g,"thigh","thigh_root",60,100)
 var c=t.find_action(g,"card",{"uid":card.uid,"free":false,"target":target.id},true)
 var before=g.export_snapshot()
 var splash=g.Cards.Splash.select(g,c.payload)
 t.check(c.valid and c.cost==1 and c.mana==0 and c.payload.preview.base==4 and splash.size()==1 and splash[0].preview.base==2,"LEVERAGE preview and splash use the current ordinary count")
 t.check(g.get_view().hand.filter(func(item):return item.uid==card.uid)[0].bound.contains("当前4") and g.state==before,"LEVERAGE card text reads dynamic base without mutating state")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"LEVERAGE stale target play has no effects")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(target.id).durability,80-c.payload.preview.damage) and is_equal_approx(g._equipment(peer.id).durability,60-splash[0].preview.damage),"LEVERAGE real damage and collateral match their independent multipliers")
 t.check(g.state.energy==before.energy-1 and g.state.mana==before.mana and g.state.rng.magic==before.rng.magic and g.state.discard.any(func(item):return item.uid==card.uid),"LEVERAGE pays once, makes no spell roll and discards normally")
 free_face(t)
 var bad=spec.duplicate(true);bad.worn_damage.per_item=0
 t.check(g.Cards.Rules.definition_reason(bad)!="","LEVERAGE rejects invalid dynamic damage data")

static func free_face(t) -> void:
 var g=F.fresh();var card=Give.give(g,"leverage")
 g.add_fixture("ankle",4)
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true},true)
 var before=g.export_snapshot()
 t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.evasion==1 and g.state.charge==1,"LEVERAGE free face grants evasion and charge despite leg restraints")
 t.check(g.state.energy==before.energy-1 and g.state.mana==before.mana and g.state.rng.magic==before.rng.magic,"LEVERAGE free face costs no mana and makes no spell roll")
 var blocked=g.add_fixture("wrist",4);card=Give.give(g,"leverage")
 c=t.find_action(g,"card",{"uid":card.uid,"free":true});before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("上身") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"LEVERAGE upper restriction rejects free face atomically with a concrete reason")
 blocked.durability=0;g._cleanup();g.state.energy=0
 c=t.find_action(g,"card",{"uid":card.uid,"free":true});before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"LEVERAGE insufficient energy cannot grant either buff")
 g.state.energy=2
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.evasion==2 and g.state.charge==2,"LEVERAGE removal restores eligibility and both buffs accumulate")
