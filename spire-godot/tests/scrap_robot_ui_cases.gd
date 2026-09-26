extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game.state.enemies=[];ui.game.state.energy=20
 var id=ui.game._append_enemies([{"type":"drone","grade":1}])[0].id
 for enemy in ui.game.state.enemies: enemy.intent=ui.game._plan(enemy)
 ui.game.RelicEffects.gain(ui.game,"scrap_robot");ui.render();await t.frames()
 var icon=ui.find_child("RelicShortcut_scrap_robot",true,false)
 t.check(icon!=null and preload("res://ui/relic_icon.gd").ART.has("scrap_robot"),"SCRAP UI shows dedicated relic icon")
 await t.move_mouse(icon.get_global_rect().get_center());await t.frames()
 t.check(ui.term_popup!=null and t.visible_text(ui.term_popup).contains("破铜烂铁机器人") and t.visible_text(ui.term_popup).contains("25%"),"SCRAP UI relic hover explains twenty-five percent reduction")
 var attack=Queries.find(ui.view,"attack",{"type":"strike","form":0,"enemy":id})
 t.check(attack.brief=="6 伤害" and ui.view.statuses.any(func(s):return s.id=="hard_"+id and s.value.contains("25%")),"SCRAP UI physical preview and hard status show effective values")
 var hp=ui.game._enemy(id).hp
 await t.drag_control_to(t.action_button("strike"),id)
 t.check(ui.game._enemy(id).hp==hp-6,"SCRAP UI actual attack drag deals the displayed six damage")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("破铜烂铁机器人")=="Scrap Robot" and ui.localization.display("非魔法减伤25%").contains("25%"),"SCRAP UI relic and dynamic armor text have English copy")
 ui.localization.set_locale("zh_CN")
