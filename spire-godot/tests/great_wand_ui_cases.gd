extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=50;ui.game.state.mana=40
 ui.game.RelicEffects.gain(ui.game,"great_wand");ui.render();await t.frames()
 var control=ui.find_child("RelicShortcut_great_wand",true,false)
 t.check(control!=null and control.find_child("RelicCounter",true,false).text=="0" and preload("res://ui/relic_icon.gd").ART.has("great_wand"),"WAND UI dedicated relic art starts with visible zero counter")
 var card=Cards.give(ui.game,"strain");ui.card_faces[card.uid]=true;ui.render();await t.frames()
 await Click.click_card(t,card.uid)
 control=ui.find_child("RelicShortcut_great_wand",true,false)
 t.check(control.find_child("RelicCounter",true,false).text=="1","WAND UI actual skill click updates relic counter")
 var point=control.get_global_rect().get_center()
 await t.move_mouse(point)
 var hovered=ui.get_viewport().gui_get_hovered_control()
 t.check(hovered==control or (hovered!=null and control.is_ancestor_of(hovered)),"WAND UI relic icon receives pointer input; hovered="+(str(hovered.get_path())+str(hovered.get_global_rect()) if hovered!=null else "null"))
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.state.relic_counters.great_wand==1 and ui.game.state.mana==40,"WAND UI left click does not accidentally spend points")
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false);await t.frames()
 t.check(ui.game.state.relic_counters.great_wand==0 and ui.game.state.mana==41 and ui.find_child("RelicShortcut_great_wand",true,false).find_child("RelicCounter",true,false).text=="0","WAND UI native right click exchanges through formal action and refreshes counter")
 for n in range(14):
  var skill=Cards.give(ui.game,"strain")
  var choice=ui.game.command_facts().filter(func(x):return x.payload.get("uid","")==skill.uid and x.payload.get("free",false))[0]
  t.check(ui.game.dispatch(ui.game.command(choice.payload,ui.game.state.version),ui.game.state.version).ok,"WAND UI threshold setup uses formal skill actions")
 card=Cards.give(ui.game,"strain");ui.card_faces[card.uid]=true;ui.render();await t.frames()
 t.check(ui.find_child("RelicShortcut_great_wand",true,false).find_child("RelicCounter",true,false).text=="14","WAND UI shows charged meter before automatic threshold")
 await Click.click_card(t,card.uid)
 t.check(ui.game.state.mana==56 and ui.find_child("RelicShortcut_great_wand",true,false).find_child("RelicCounter",true,false).text=="0","WAND UI fifteenth skill auto-recovers and clears display")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("大魔棒")=="Great Wand" and ui.localization.display("已积攒3／15点；右键兑换等量魔力，满点自动兑换并清空。").contains("3/15"),"WAND UI English dynamic counter preserves values")
 ui.localization.set_locale("zh_CN")
