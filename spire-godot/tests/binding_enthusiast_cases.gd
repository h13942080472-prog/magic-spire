extends RefCounted

const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Replace=preload("res://tests/replacement_cases.gd")

static func status(g, id: String) -> Dictionary:
 var rows=g.get_view().statuses.filter(func(row):return row.id==id)
 return {} if rows.is_empty() else rows[0]

static func run(t) -> void:
 var g=Game.new(42)
 var spec=g.Cards.Rules.SPECS.binding_enthusiast
 t.check(spec.cost==3 and spec.card_type=="power" and spec.rarity=="rare" and spec.self_faces.bound==spec.self_faces.free and "binding_enthusiast" in g.Cards.Rules.RARE and g.Cards.Rules.definition_reason(spec)=="","BINDING ENTHUSIAST is a valid three-energy rare power with matching faces")
 var ordinary=g.add_fixture("eyes",8.0)
 var composite=g._install_assembly("glove","short","fixture",2,1)
 var special=g._install_special("vaginal_egg_low","special_3_a")
 t.check(not ordinary.is_empty() and not composite.is_empty() and not special.is_empty() and composite.components.size()>1 and g.Cards.worn_count(g)==3,"BINDING ENTHUSIAST counts ordinary, one composite root and one sex toy once each")
 var card=Cards.give(g,"binding_enthusiast")
 var before=g.export_snapshot()
 var candidate=t.find_action(g,"card",{"uid":card.uid,"free":false})
 t.check(candidate.valid and candidate.cost==3 and not g.dispatch(g.command(candidate.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"BINDING ENTHUSIAST stale activation preserves resources and equipment")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.energy==0 and g.state.pressure==0 and g.Cards.power_attribute_modifier(g,"strength")==3 and g.Cards.power_attribute_modifier(g,"dexterity")==3,"BINDING ENTHUSIAST activation pays three and does not trigger itself")
 t.check(g.RelicEffects.attribute(g,"strength")==3 and g.RelicEffects.attribute(g,"dexterity",{},true)==3,"BINDING ENTHUSIAST supplies formal active and passive attributes")
 t.check(status(g,"strength").value=="3" and status(g,"dexterity").value=="3" and status(g,"power_binding_enthusiast").value.contains("3件"),"BINDING ENTHUSIAST status shows current dynamic count and both attributes")

 var added=g.add_fixture("ankle",8.0)
 t.check(g.Cards.worn_count(g)==4 and g.RelicEffects.attribute(g,"strength")==4,"BINDING ENTHUSIAST newly equipped restraint raises attributes immediately")
 added.durability=0
 t.check(g.Cards.worn_count(g)==3 and g.RelicEffects.attribute(g,"dexterity")==3,"BINDING ENTHUSIAST broken restraint lowers attributes immediately without a new activation")
 var linked=Game.new(42);linked.state.energy=6
 var linked_power=Cards.give(linked,"binding_enthusiast")
 t.action(linked,"card",{"uid":linked_power.uid,"free":true})
 var forearm=Replace.install(linked,Replace.request("forearm",1,1,"mid_forearm"))
 var wrist=Replace.install(linked,Replace.request("wrist",1,1))
 var count_before_link=linked.Cards.worn_count(linked)
 var link=linked._install_link(forearm.id,wrist.id,8.0,"fixture",1,[],["forearm","wrist"],["mid_forearm","wrist"])
 t.check(not link.is_empty() and linked.Cards.worn_count(linked)==count_before_link and linked.RelicEffects.attribute(linked,"strength")==count_before_link,"BINDING ENTHUSIAST excludes connection ropes from equipped-item count")

 var sensitive=Cards.give(g,"sensitive")
 var bound=Cards.give(g,"pleasure_conversion")
 g.state.energy=3
 t.check(t.action(g,"card",{"uid":bound.uid,"free":false}).ok and g.state.pressure==10,"BINDING ENTHUSIAST bound-face trigger is fixed ten despite Sensitive multiplier")
 t.check(g.state.logs.any(func(log):return log.data.get("fixed_gain",false) and log.data.get("base_gain",0)==10),"BINDING ENTHUSIAST fixed trigger is recorded structurally")
 var free_card=Cards.give(g,"pleasure_conversion")
 t.check(t.action(g,"card",{"uid":free_card.uid,"free":true}).ok and g.state.pressure==10 and sensitive in g.state.hand,"BINDING ENTHUSIAST free face does not add pleasure")
 var second_bound=Cards.give(g,"concentration");g.state.energy=3
 t.check(t.action(g,"card",{"uid":second_bound.uid,"target":ordinary.id,"free":true}).ok and g.state.pressure==20,"BINDING ENTHUSIAST second face of a two-restraint-face card still triggers fixed pleasure")

 var restored=Save.roundtrip(t,g,"dynamic binding enthusiast power")
 if restored!=null:
  t.check(restored.Cards.worn_count(restored)==g.Cards.worn_count(g) and restored.RelicEffects.attribute(restored,"strength")==g.RelicEffects.attribute(g,"strength"),"BINDING ENTHUSIAST restored power recomputes from restored equipment")
 composite.components.filter(func(piece):return piece.part=="body")[0].durability=0
 t.check(g.RelicEffects.attribute(g,"strength")==g.Cards.worn_count(g),"BINDING ENTHUSIAST composite stops counting as soon as its body is no longer active")
 g.Cards.end_powers(g)
 t.check(g.Cards.power_attribute_modifier(g,"strength")==0 and g.Cards.power_attribute_modifier(g,"dexterity")==0,"BINDING ENTHUSIAST ends with combat powers")
