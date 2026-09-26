extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")
static func run(t) -> void:
 var ui=t.ui
 ui.game.state.posture="sit";ui.game.state.wall_distance=1
 ui.game._install_assembly("wrap","right","fixture",1,1)
 ui.game._install_template("fine_belt","palm",4,10,false,"fixture")
 var target=ui.game.add_fixture("ankle",4)
 ui.render();await t.frames()
 await Navigation.press(t,"OpenStatus")
 var description=await preload("res://tests/status_ui_cases.gd").inspect(t,"hand_assist")
 t.check(description.contains("左手辅助＋0.5") and description.contains("手指受限"),"ASSIST UI status preserves fraction and blocked finger reason")
 await Navigation.press(t,"CloseDrawer")
 var uid=ui.view.hand.filter(func(c):return c.type=="strain")[0].uid
 if ui.card_faces.get(uid,false): await t.flip(uid)
 var candidate=Queries.find(ui.view,"card",{"uid":uid,"target":target.id,"free":false})
 t.check(ui.detail_of(candidate).contains("＋0.5") and ui.detail_of(candidate).contains("手掌不能使用"),"ASSIST UI candidate explains half palm assistance")
 var energy=ui.view.energy
 await t.start_drag(uid,"ankle")
 await t.capture("ui-115-half-hand-assistance.png")
 await t.release_target(await t.reveal_drop_target(candidate.key))
 t.check(ui.game._equipment(target.id).is_empty() and ui.view.energy==energy-1 and ui.view.logs.any(func(e):return e.data.has("assist") and e.data.assist.bonus==0.5),"ASSIST UI formal drag uses half assistance and pays once")
