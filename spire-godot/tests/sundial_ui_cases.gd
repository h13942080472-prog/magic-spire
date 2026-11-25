extends RefCounted

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 ui.game._reset_piles()
 ui.game.state.discard.append(ui.game.state.draw.pop_back())
 ui.game.state.exhaust.append_array(ui.game.state.draw);ui.game.state.draw.clear()
 ui.game.RelicEffects.gain(ui.game,"sundial");ui.game.state.relic_counters.sundial=1
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"pot_of_greed")
 ui.card_faces[card.uid]=false;ui.render();await t.frames()
 var icon=ui.find_child("RelicShortcut_sundial",true,false)
 t.check(icon!=null and icon.find_child("RelicCounter",true,false).text=="1" and preload("res://ui/relic_icon.gd").ART.has("sundial"),"SUNDIAL UI dedicated icon shows the carried counter")
 var energy=ui.view.energy
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 await t.frames()
 icon=ui.find_child("RelicShortcut_sundial",true,false)
 t.check(ui.view.energy==energy+2 and icon.find_child("RelicCounter",true,false).text=="0","SUNDIAL UI real draw-two click refreshes energy and wrapped count")
 await t.move_mouse(icon.get_global_rect().get_center());await t.frames()
 var hovered=ui.get_viewport().gui_get_hovered_control()
 t.check(ui.term_popup!=null and t.visible_text(ui.term_popup).contains("每洗牌3次，获得2能量。") and t.visible_text(ui.term_popup).contains("次数跨战斗累计"),"SUNDIAL UI hover explains effect and persistence; hovered="+str(hovered.get_path() if hovered!=null else "none"))
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("日晷")=="Sundial" and ui.localization.display(ui.game.RelicEffects.counter(ui.game,"sundial").detail)=="Shuffles: 0/3.","SUNDIAL English dynamic progress preserves values")
 ui.localization.set_locale("zh_CN")
