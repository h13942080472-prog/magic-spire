extends RefCounted
const Events=preload("res://tests/event_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 t.check(ui.find_child("HeroSpeech",true,false)==null and ui.find_child("OpenActionLog",true,false)==null,"COPY UI no scene log entry or untriggered speech")
 var hero=ui.find_child("HeroArt",true,false)
 t.check(hero.get_rect().is_equal_approx(ui.HERO_STAGE_RECT) and hero.get_rect().end.y<553,"COPY UI hero remains in its display area above action bar")
 var foe=ui.view.enemies[0].id
 await t.drag_control_to(t.action_button("strike"),foe)
 t.check(ui.find_child("HeroSpeech",true,false)!=null and ui.view.speech.cue=="hero.attack.upper.low.clear" and ui.view.speech.name=="魔法少女","COPY UI real attack drag opens character bubble")
 var strip=ui.find_child("RelicStrip",true,false)
 var bubble=ui.find_child("HeroSpeech",true,false)
 t.check(ui.find_child("HeroSpeechPortrait",true,false)!=null and ui.find_child("HeroSpeechText",true,false)!=null and not t.visible_text(bubble).contains(ui.view.speech.name),"COPY UI character bubble keeps portrait and spoken line without rendering a speaker name")
 t.check(strip.position==Vector2(405,78) and strip.get_global_rect().intersects(bubble.get_global_rect()) and ui.speech_group.z_index>strip.z_index,"COPY UI relics start at scene top-left beneath speech")
 var deadline=ui.speech_deadline
 var unchanged=ui.game.export_snapshot()
 var relic=strip.find_child("RelicShortcut_*",true,false)
 await t.move_mouse(relic.get_global_rect().get_center());await t.frames()
 t.check(is_instance_valid(ui.term_popup) and ui.speech_group.visible,"COPY UI read-only speech leaves relic hover reachable without dismissing dialogue")
 await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_RIGHT,true);await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_RIGHT,false)
 t.check(ui.speech_group.visible and ui.speech_deadline==deadline,"COPY UI right click does not dismiss speech")
 await preload("res://tests/target_sidebar_ui_cases.gd").press(t,bubble)
 t.check(not ui.speech_group.visible and ui.game.export_snapshot()==unchanged,"COPY UI left click inside speech hides bubble and tail without gameplay changes")
 ui.render();await t.frames()
 t.check(ui.find_child("HeroSpeech",true,false)==null,"COPY UI ordinary repaint cannot revive dismissed speech")
 t.check(ui.view.action_log.any(func(row):return row.actor=="魔法少女" and row.text.contains("造成")),"COPY UI own attack result enters sidebar immediately")
 await t.open_menu();await preload("res://tests/interface_ui_cases.gd").press(t,"OpenLog")
 t.check(t.visible_text(ui.find_child("InformationDrawer",true,false)).contains("消耗1能量"),"COPY UI paid cost and outcome visible in player log")
 await t.close_information()
 t.check(await t.click("end") and not ui.view.action_log.is_empty(),"COPY UI actual enemy actions enter sidebar")
 t.check(ui.find_child("HeroSpeech",true,false)==null,"COPY UI zero-cost end does not restore removed legacy dialogue")
 await t.drag_control_to(t.action_button("","posture","sit"),"hero")
 t.check(ui.view.posture=="sit" and ui.view.speech.cue=="hero.posture.low.clear","COPY UI next authored paid action opens dialogue after prior dismissal")
 t.check(is_instance_valid(ui.speech_group) and ui.speech_group.is_visible_in_tree(),"COPY UI fresh authored dialogue is visible")
 await t.capture("ui-77-dialogue-action-log.png")
 deadline=ui.speech_deadline
 await t.create_timer(2.0).timeout
 var before=ui.game.export_snapshot();ui.render();await t.frames()
 t.check(ui.game.export_snapshot()==before and ui.speech_deadline==deadline and ui.speech_group.visible,"COPY UI rerender preserves remaining dialogue lifetime and gameplay")
 await t.create_timer(maxf(0.01,(deadline-Time.get_ticks_msec())/1000.0+0.1)).timeout
 t.check(not ui.speech_group.visible and ui.speech_deadline==0 and ui.game.export_snapshot()==before,"COPY UI speech and tail automatically disappear after five real seconds without gameplay changes")
 var shortcut=ui.find_child("RelicRow",true,false).get_child(0)
 await t.move_mouse(shortcut.get_global_rect().get_center());await t.frames()
 t.check(is_instance_valid(ui.term_popup),"COPY UI timed-out speech exposes underlying relic hover")
 await t.capture("ui-relics-after-dialogue.png")
 await t.drag_control_to(t.action_button("","posture","stand"),"hero")
 t.check(ui.view.posture=="stand" and ui.view.speech.cue=="hero.posture.low.clear","COPY UI moved player target still accepts actual posture drag")
 t.check(ui.speech_group.visible,"COPY UI next action presents fresh speech after timeout")
 await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_LEFT,true);await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_LEFT,false)
 t.check(not ui.speech_group.visible,"COPY UI left click outside speech also dismisses it")
 await Events.arrive(t,"binding_cleric")
 t.check(await t.click("event",{"action":"choose","choice":"leave_free"}),"COPY UI actual event choice")
 t.check(ui.view.action_log.back().cue=="event.binding_cleric.choose" and ui.find_child("OpenActionLog",true,false)==null,"COPY UI event result remains in shared log without scene entry")
 t.check(ui.find_child("HeroSpeech",true,false)==null,"COPY UI events use authored prose without a separate character dialogue interface")
 await concise_log(t)
 await stale_prison_speech(t)

static func stale_prison_speech(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 # Reproduce a loaded old preparation warning, then reach a new preparation formally.
 ui.game.state.logs.append({"kind":"event","text":"历史检查结果。","round":1,"phase":"prepare","data":{"npc_copy":{"cue":"prison.guard.release_fail","visual":"guard_brown"}}})
 for enemy in ui.game.state.enemies: enemy.hp=1
 ui.render();await t.frames()
 var kick_point=ui.find_child("BasicAttack_kick",true,false).get_global_rect().get_center()
 await t.mouse_button(kick_point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(kick_point,MOUSE_BUTTON_RIGHT,false)
 t.check(await t.click("attack",{"type":"kick","form":1,"enemy":ui.view.enemies[0].id}) and ui.view.phase=="reward","COPY UI real area attack reaches reward with an old prison warning in history")
 t.check(await t.click("reward",{"type":"skip"}) and ui.view.phase=="prepare","COPY UI reward reaches a later preparation with the same historical phase")
 var before=ui.game.export_snapshot()
 ui.render();await t.frames()
 t.check(ui.view.npc_speech.is_empty() and ui.find_child("NpcSpeech",true,false)==null and ui.game.export_snapshot()==before,"COPY UI later preparation hides old prison warning without changing saved state")
 var restored=preload("res://tests/game_fixture.gd").new(9)
 t.check(restored.restore_snapshot(before).ok,"COPY UI old warning snapshot remains loadable")
 ui.game=restored;ui._reset_interface(ui.game.get_view());ui.render();await t.frames()
 t.check(ui.view.npc_speech.is_empty() and ui.find_child("NpcSpeech",true,false)==null,"COPY UI reload cannot revive the old prison warning")

static func concise_log(t) -> void:
 var ui=t.ui
 ui.restart(42)
 preload("res://tests/action_log_cases.gd").prepare_failure(ui.game)
 ui.render();await t.frames()
 var choice=ui.game.command_facts().filter(func(c):return c.valid and c.payload.kind=="attack" and c.payload.type=="fireball")[0]
 var before=ui.game.export_snapshot()
 await t.drag_control_to(t.action_button("fireball"),choice.payload.enemy)
 await t.open_menu();await preload("res://tests/interface_ui_cases.gd").press(t,"OpenLog")
 var text=t.visible_text(ui.find_child("InformationDrawer",true,false))
 var formatted=ui.game.ActionCopy.number(choice.mana_payment.mana)
 t.check(ui.game._magic_failed and text.contains("施法失败") and text.contains("%s魔力" % formatted) and text.contains("消耗%d能量" % choice.cost) and ui.game.state.energy==before.energy-choice.cost,"LOG UI real failed first fireball displays failure and both exact-source costs")
 t.check(not text.contains("未产生法术效果") and not text.contains("不退回") and not text.contains("卡牌留在手中") and is_equal_approx(ui.game.state.mana,before.mana-choice.mana_payment.mana*(1.0-ui.game.B.CAST_FAILURE_REFUND)),"LOG UI failure preserves exact mana after the current failure refund and never invents a card")
