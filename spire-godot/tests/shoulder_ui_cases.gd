extends RefCounted
const Queries=preload("res://ui/target_queries.gd")
static func run(t) -> void:
 await t.start_practice("Practice_shoulder_links")
 var ui=t.ui
 t.check(ui.view.practice_kind=="shoulder_links","SHOULDER UI real practice opens")
 await t.inspect_body("neck")
 var group=ui.view.body_groups.filter(func(b):return b.id=="neck")[0]
 t.check(group.name=="颈肩" and ui.body_buttons.neck.text=="颈肩  2" and group.count==2,"SHOULDER UI grouped title identifies shoulder straps instead of reporting them as neck restraints")
 t.check(group.targets.size()==2 and group.targets.values().all(func(e):return e.slot=="shoulder"),"SHOULDER UI left/right targets really in shoulder")
 var details=ui.find_child("EquipmentDetails",true,false)
 var text=t.visible_text(details)
 t.check(text.contains("左肩皮带") and text.contains("右肩皮带") and text.contains("无法挣扎"),"SHOULDER UI compact cards show side and method")
 await t.capture("ui-113-shoulder-pair.png")
 var host=ui.game.state.equipment[0]
 var left=host.shoulders.pieces[0];var right=host.shoulders.pieces[1].duplicate(true)
 left.durability=1;ui.render();await t.frames()
 var uid=ui.view.hand.filter(func(c):return c.type=="slip")[0].uid
 if ui.card_faces.get(uid,false): await t.flip(uid)
 var candidate=Queries.find(ui.view,"card",{"uid":uid,"target":left.id,"free":false})
 var splash=ui.game.Cards.Splash.options(ui.game,candidate.payload)
 t.check(splash.size()==1 and splash[0].size()==1 and splash[0][0].target==right.id,"SHOULDER UI shared preview identifies the other shoulder as the sole splash target")
 if splash.size()!=1 or splash[0].size()!=1: return
 var right_after=right.duplicate(true)
 right_after.durability-=splash[0][0].preview.damage
 var energy=ui.view.energy
 await t.start_drag(uid,"neck")
 t.check(ui.drop_targets.has(candidate.key),"SHOULDER UI drag opens actual shoulder candidate")
 await t.release_target(await t.reveal_drop_target(candidate.key))
 t.check(ui.game._equipment(left.id).is_empty() and ui.game._equipment(right.id)==right_after and ui.view.energy==energy-candidate.cost,"SHOULDER UI left removal pays once and preserves the right shoulder with its previewed splash damage")
 await t.inspect_body("upper_arm")
 t.check(t.visible_text(ui.find_child("EquipmentDetails",true,false)).contains("×0.5"),"SHOULDER UI host card explains remaining-side penalty")
 await t.start_practice("StartLongGlovePractice")
 await t.inspect_body("neck")
 group=ui.view.body_groups.filter(func(b):return b.id=="neck")[0]
 t.check(group.targets.size()==2 and group.targets.values().all(func(e):return e.card_status.contains("交叉型")),"SHOULDER UI glove crossing separate left/right")
 await t.capture("ui-114-independent-crossed-shoulders.png")
