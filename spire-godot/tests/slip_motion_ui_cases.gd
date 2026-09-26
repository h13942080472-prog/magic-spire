extends RefCounted
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")
static func run(t) -> void:
 var ui=t.ui
 ui.game.state.wall="normal";ui.game.state.wall_distance=4
 var e=ui.game._install_template("belt","thigh",4,10,false,"fixture",1,0,0,"thigh_root")
 ui.render();await t.frames()
 var card=ui.game.command_facts().filter(func(c):return c.payload.get("target","")==e.id and c.payload.get("mode","")=="slip")[0]
 t.check(card.payload.preview.position.factor==1.5,"MOTION UI active candidate carries factor")
 var before=ui.game.state.version
 await Pointer.press(t,ui.find_child("WallMove_toward",true,false))
 t.check(ui.game.state.version==before+1 and is_equal_approx(ui.game._equipment(e.id).durability,2.5),"MOTION UI real movement applies passive once")
 var panel=ui.find_child("PlayerActionFeedback",true,false)
 t.check(panel!=null and t.visible_text(panel).contains("2.5"),"MOTION UI existing feedback displays actual loss")
 t.check(ui.view.logs.any(func(log):return log.data.has("passive_slip")),"MOTION UI visible logs retain structured explanation")
 t.check(not ui.view.summary.contains("倍率") and ui.view.summary.contains("耐久－1.5"),"MOTION UI main summary stays short while formulas remain in logs")
 t.check(preload("res://ui/combat_feedback.gd").movement_changes(ui.view,ui.view).is_empty(),"MOTION UI redraw cannot replay historical movement damage")
 await t.capture("ui-112-slip-motion.png")

 ui.restart(42,true,"links");await t.frames()
 var target=ui.game.equipment_at("calf")[0]
 var uid=ui.view.hand.filter(func(c):return c.type=="slip")[0].uid
 if ui.card_faces.get(uid,false): await t.flip(uid)
 card=Queries.find(ui.view,"card",{"uid":uid,"target":target.id})
 var durability=target.durability;var damage=card.payload.preview.damage
 t.check(card.valid and card.payload.preview.link_factor==1.25,"LOWER LINK UI reads shared preview")
 await t.start_drag(uid,"calf")
 await t.reveal_drop_target(card.key)
 var shown=t.visible_text(ui.term_popup)
 t.check(shown.contains(ui.game.number(damage)+"点滑脱伤害") and not shown.contains("×1.25") and not shown.contains("能量"),"LOWER LINK UI shows final slip damage with the link bonus already included")
 await t.capture("ui-lower-link-slip.png")
 await t.release_target(await t.reveal_drop_target(card.key))
 t.check((ui.game._equipment(target.id).is_empty() if damage>=durability else is_equal_approx(ui.game._equipment(target.id).durability,durability-damage)),"LOWER LINK UI native drag matches preview")
