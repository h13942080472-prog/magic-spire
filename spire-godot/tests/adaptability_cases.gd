extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func run(t) -> void:
 var g=Game.new(42)
 var spec=g.Cards.Rules.SPECS.adaptability
 var invalid=spec.duplicate(true)
 invalid.self_faces.bound.convert_to="mana"
 t.check(spec.card_type=="skill" and spec.rarity=="uncommon" and g.Cards.Rules.definition_reason(spec)=="" and g.Cards.Rules.definition_reason(invalid)!="","ADAPT skill accepts the two layer pools and rejects an unrelated resource")
 var card=Cards.give(g,"adaptability")
 g.state.temporary_mana=17.5;g.state.charge=2;g.state.energy=0
 var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state==before,"ADAPT unpaid conversion preserves both resources")
 g.state.energy=8
 var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
 before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(c.valid and c.cost==1 and c.mana==0 and g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"ADAPT stale and preview never convert")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.charge==5 and g.state.temporary_mana==2.5 and g.state.mana==before.mana and g.state.discard.back().uid==card.uid and g.state.powers.is_empty(),"ADAPT bound converts only whole reserve layers and discards")
 t.check(Cards.play(t,g,"adaptability",false).ok and g.state.charge==5 and g.state.temporary_mana==2.5,"ADAPT fractional remainder cannot be converted twice")
 g.state.charge_all=true
 t.check(Cards.play(t,g,"adaptability",true).ok and g.state.charge==0 and not g.state.charge_all and g.state.temporary_mana==27.5,"ADAPT free converts all charge and resets all-charge mode")
 t.check(Cards.play(t,g,"adaptability",true).ok and g.state.temporary_mana==27.5,"ADAPT zero source grants zero")
 g.state.relics=["lewd_silk_bodysuit"];g.state.pressure=0;g.state.charge=3
 t.check(Cards.play(t,g,"adaptability",true).ok and g.state.charge==0 and g.state.pressure==15 and g.state.temporary_mana==42.5,"ADAPT normal charge mode spends every layer through relic hooks")
 var old=g.export_snapshot()
 var played=old.discard.pop_back()
 played.power_face="free";played.power_stacks=2;old.powers.append(played)
 old.save_revision=g.Snapshot.ADAPTABILITY_REVISION
 var copy=Game.new(0)
 t.check(copy.restore_snapshot(old).ok and copy.state.powers.is_empty() and copy.state.discard.back().uid==played.uid and not copy.state.discard.back().has("power_face") and copy.state.temporary_mana==g.state.temporary_mana,"ADAPT legacy active power returns to discard without a second payout")
 t.check(old.powers.size()==1 and old.powers[0].power_stacks==2,"ADAPT migration leaves source snapshot intact")
