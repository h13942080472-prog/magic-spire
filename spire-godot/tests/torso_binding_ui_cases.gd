extends RefCounted
const Cases=preload("res://tests/torso_binding_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 await t.start_practice("Practice_torso_binding")
 var ui=t.ui
 t.check(ui.view.practice_kind=="torso_binding","BIND UI practice uses registry and normal initialization")
 ui.game=Cases.sample("linked");ui.render();await t.frames()
 var host=ui.game.state.equipment[0]
 var target=host.binding.id
 await t.inspect_body("forearm")
 var details=ui.find_child("EquipmentDetails",true,false)
 t.check(t.visible_text(details).contains("躯干固缚") and t.visible_text(details).contains("独立连接耐久"),"BIND UI attachment and independent durability are visible")
 await t.capture("ui-111-torso-binding-cards.png")
 var uid=ui.view.hand.filter(func(c):return c.type=="strain")[0].uid
 if ui.card_faces.get(uid,false): await t.flip(uid)
 var candidate=Queries.find(ui.view,"card",{"uid":uid,"target":target,"free":false})
 var splash=ui.game.Cards.Splash.options(ui.game,candidate.payload)
 t.check(splash.size()==1 and splash[0].size()==1 and splash[0][0].target==host.id,"BIND UI shared preview identifies same-point splash to the host")
 if splash.size()!=1 or splash[0].size()!=1: return
 var host_after=host.durability-splash[0][0].preview.damage
 var connection_after=host.binding.durability-candidate.payload.preview.damage
 var before=ui.game.export_snapshot()
 await t.start_drag(uid,"forearm")
 t.check(ui.drop_targets.has(candidate.key),"BIND UI connection has its own formal drop target")
 await t.release_target(await t.reveal_drop_target(candidate.key))
 t.check(is_equal_approx(ui.game._equipment(host.id).durability,host_after) and is_equal_approx(ui.game._equipment(target).durability,connection_after) and ui.game.state.energy==before.energy-candidate.cost,"BIND UI native drag applies the previewed connection and host splash damage and pays once")
