extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")

static func toes(g, grade: int=1, tightness: int=2) -> Dictionary:
 var maximum=g.Equipment.maximum(grade)
 return g._install_template("cord","toes",maximum*{1:0.2,2:0.6,3:1.0}[tightness],maximum,false,"fixture",grade)

static func run(t) -> void:
 var g=Game.new(42)
 var palm=g.add_fixture("palm",4);palm.side="left"
 var target=g.add_fixture("ankle",8,10,true)
 var card=Give.give(g,"unlock")
 t.check(not t.find_action(g,"card",{"uid":card.uid,"target":target.id}).valid,"SECRET absent relic does not enable toe casting")
 g.RelicEffects.gain(g,"secret_weapon")
 g.state.pressure=75
 var profile={"parts":["hand"],"multiplier":1.0}
 var route=g.cast_view(profile)
 var before=g.export_snapshot()
 g.get_view();g.command_facts()
 t.check(route.reason=="" and route.source_part=="toes" and route.chance==0.25 and g.state==before,"SECRET best legal toe route shares pressure curve and preview is readonly")
 var bound=toes(g)
 g.state.sure_cast=true
 g.Cards.apply_effects(g,[{"op":"buff","buff":"prepared_chant"}],{})
 route=g.cast_view(profile)
 var blocked=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 before=g.export_snapshot()
 t.check(route.chance==0 and route.reason.contains("脚趾") and not g.dispatch(g.command(blocked.payload,g.state.version),g.state.version).ok and g.state==before,"SECRET bound toes and blocked hands reject even guaranteed casting without paying")
 g.state.equipment.erase(palm)
 t.check(g.cast_view(profile).source_part=="hand" and g.cast_view(profile).chance==1.0,"SECRET bound toes do not disable a legal hand route")
 g.state.equipment.erase(bound)
 g.state.card_buffs.clear();g.state.sure_cast=false
 palm=g.add_fixture("palm",4);palm.side="left"
 g.state.pressure=0
 var pick=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(pick.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SECRET stale toe spell changes no resources or equipment")
 t.check(g.dispatch(g.command(pick.payload,g.state.version),g.state.version).ok and not g._equipment(target.id).locked and g.state.mana==before.mana-pick.mana,"SECRET actual hand spell casts with toes and unlocks its target")
 t.check(g.state.logs.any(func(row):return row.data.get("spell",{}).get("source_part","")=="toes"),"SECRET spell receipt records actual toe route")
 var clone=Game.new(13)
 t.check(clone.restore_snapshot(g.export_snapshot()).ok and clone.hand_cast_reason()=="","SECRET relic survives snapshot with toe casting immediately active")
 t.check(g.Relics.TYPES.secret_weapon.rarity=="rare" and "secret_weapon" in g.Relics.REWARDS and "secret_weapon" in g.Relics.shop_pool(),"SECRET rare relic enters ordinary reward and shop pools")
 priority(t)
 traction(t)

static func priority(t) -> void:
 var g=Game.new(42)
 var pool=["rope","cord","mouth_tape"]
 g.RelicEffects.gain(g,"secret_weapon")
 var options=g.EquipmentOffers.preferred(g,g.EquipmentOffers.for_pool(g,1,pool))
 t.check(options.all(func(o):return o.slot=="wrist"),"SECRET wrist remains first priority")
 g.add_fixture("wrist",8)
 options=g.EquipmentOffers.preferred(g,g.EquipmentOffers.for_pool(g,1,pool))
 t.check(options.any(func(o):return o.slot=="toes") and options.any(func(o):return o.slot=="mouth") and options.all(func(o):return o.slot in ["mouth","fingers","toes"]),"SECRET empty toes share mouth and finger priority below wrists")
 var toe=toes(g)
 t.check(g._priority("toes")==1,"SECRET occupied toes return to shared later installation band")
 g.state.equipment.erase(toe);g.state.relics.erase("secret_weapon")
 t.check(g._priority("toes")==1,"SECRET removing relic restores ordinary toe priority")
 g.RelicEffects.gain(g,"secret_weapon")
 var denied=g.Application.choose(g,{"templates":["rope"],"grade":1},"fixture")
 t.check(denied.is_empty() or denied.slot!="toes","SECRET toe priority never widens a source that cannot bind toes")
 var result=g.Application.execute(g,{"pool":"ordinary","templates":["cord"],"grade":1,"tier":2,"count":1,"required_slots":["toes"]},"fixture")
 t.check(result.ok and g.occupied("toes") and g.RelicEffects.toe_traction(g).base==2,"SECRET actual application immediately enables derived toe traction")

static func traction(t) -> void:
 for grade in [1,2,3]:
  for tightness in [1,2,3]:
   var g=Game.new(42)
   var piece=toes(g,grade,tightness)
   t.check(not piece.is_empty() and g.RelicEffects.toe_traction(g).base==0,"SECRET no relic means no extra traction")
   g.RelicEffects.gain(g,"secret_weapon")
   var expected={2:1.0,3:2.0,4:3.0,5:4.0,6:6.0}[grade+tightness]
   t.check(g.RelicEffects.toe_traction(g).base==expected,"SECRET toe traction grade and current tier table "+str([grade,tightness]))
   g.state.pressure=0;g._apply_traction(2,false,0)
   t.check(g.state.pressure==expected,"SECRET traction triggers once per paid action, not once per energy unit")
   g.state.relics.append("marble_stone");g.state.pressure=0
   g._apply_traction(1,false,0)
   t.check(is_equal_approx(g.state.pressure,expected*0.6),"SECRET toe traction uses existing pleasure multipliers")
 var g=Game.new(42);g.RelicEffects.gain(g,"secret_weapon")
 var first=toes(g,2,3);var second=toes(g,1,2)
 t.check(not second.is_empty() and g.RelicEffects.toe_traction(g).base==6,"SECRET multiple physical toe pieces add once each")
 first.durability=first.maximum*0.2
 t.check(g.RelicEffects.toe_traction(g).base==4,"SECRET loosened toe gear updates traction immediately")
 g.state.equipment.erase(first);g.state.equipment.erase(second)
 t.check(g.RelicEffects.toe_traction(g).base==0 and not g.get_view().statuses.any(func(s):return s.id=="secret_weapon_traction"),"SECRET removal clears derived debuff without stale saved state")
 var assembly=g._install_assembly("leg","toes","fixture",2,2)
 t.check(not assembly.is_empty() and g.occupied("toes") and g.RelicEffects.toe_traction(g).sources.size()==g.equipment_at("toes").size(),"SECRET compound coverage also blocks toe casting and participates once per physical part")
 g=Game.new(42);g.RelicEffects.gain(g,"secret_weapon");toes(g,2,2)
 var card=Give.give(g,"chain")
 var pick=t.find_action(g,"card",{"uid":card.uid,"free":true})
 t.check(pick.valid and pick.risk.contains("脚趾牵扯"),"SECRET paid action previews toe traction")
 var before=g.export_snapshot()
 t.check(g.dispatch(g.command(pick.payload,g.state.version),g.state.version).ok and g.state.energy==before.energy-2,"SECRET ordinary paid action remains an actual two-energy transaction")
 var pulses=g.state.logs.slice(before.logs.size()).filter(func(row):return row.data.get("source","")=="秘密武器·脚趾牵扯")
 t.check(pulses.size()==1 and pulses[0].data.base_gain==3,"SECRET paid transaction emits exactly one real toe traction gain")
 card=Give.give(g,"mana_conversion")
 before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.pressure==before.pressure,"SECRET zero-energy action does not produce ordinary traction")
