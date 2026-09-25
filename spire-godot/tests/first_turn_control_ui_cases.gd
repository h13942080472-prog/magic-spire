extends RefCounted

static func return_to_map(t) -> void:
 var ui=t.ui;var g=ui.game
 g._finish_battle()
 for i in range(30):
  var choices=g.command_facts()
  var automatic=choices.filter(func(c):return c.get("automated",false))
  var wanted=automatic if not automatic.is_empty() else choices.filter(func(c):return (c.payload.kind=="reward" and c.payload.type=="skip") or c.payload.kind=="finish_prepare")
  if wanted.is_empty(): break
  var result=g.dispatch(g.command(wanted[0].payload,g.state.version),g.state.version)
  t.check(result.ok,"CONTROL UI fixture reaches map through legal reward/preparation commands")
  if not result.ok: break
 ui.render();await t.frames()
 t.check(ui.view.phase=="map","CONTROL UI mode switching is tested in accessible noncombat map")

static func run(t) -> void:
 var ui=t.ui
 var was_muted=AudioServer.is_bus_mute(0);AudioServer.set_bus_mute(0,true)
 await preload("res://tests/doubao_voice_ui_cases.gd").run(t)
 ui.restart(42);await t.frames()
 await return_to_map(t)
 ui.game.RelicEffects.gain(ui.game,"doubao");ui.render();await t.frames()
 var shortcut=ui.find_child("RelicShortcut_doubao",true,false)
 var point=shortcut.get_global_rect().get_center()
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false);await t.frames()
 var relic=ui.view.relics.filter(func(r):return r.id=="doubao")[0]
 t.check(relic.name=="DeepSeek" and relic.icon=="deepseek" and ui.view.energy_max==4,"CONTROL UI right click toggles name, DeepSeek icon and keeps one energy bonus")
 shortcut=ui.find_child("RelicShortcut_doubao",true,false)
 var icon=shortcut.get_child(0)
 t.check(icon.glyph.texture==preload("res://ui/relic_icon.gd").ART.deepseek and icon.glyph.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"CONTROL UI actual rendered texture changes to DeepSeek pixel portrait")
 var before=ui.game.export_snapshot()
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.state==before,"CONTROL UI left click does not toggle or skip")
 ui.game.RelicEffects.gain(ui.game,"ice_heart");ui.game._start_battle();ui.game.state.pressure=30
 for enemy in ui.game.state.enemies: enemy.intent.delayed=true
 var tick=ui.game.state.tick;ui.render();await t.frames()
 t.check(ui.find_child("FirstTurnControlBanner",true,false).text=="大肥鱼吃掉了你的白饭" and ui.view.energy==0 and not ui._takeover_locked(),"CONTROL UI displays zero-energy notice without locking player input")
 await ui.get_tree().create_timer(1.2).timeout;await t.frames()
 t.check(ui.game.state.tick==tick and ui.view.energy==0,"CONTROL UI DeepSeek never automatically ends the first turn")
 t.check(await t.click("flask",{"op":"deposit"}),"CONTROL UI player can use a real zero-energy command during DeepSeek first turn")
 t.check(await t.click("end"),"CONTROL UI player chooses when to end the DeepSeek turn")
 t.check(ui.game.state.tick==tick+1 and ui.view.first_turn_control.is_empty(),"CONTROL UI normal end restores the next turn")
 t.check(ui.game.state.logs.any(func(log):return log.text.contains("冰心诀：回合结束")),"CONTROL UI manual end preserves end effects")
 if is_instance_valid(ui.enemy_feedback): ui.enemy_feedback.finish()
 shortcut=ui.find_child("RelicShortcut_doubao",true,false);point=shortcut.get_global_rect().get_center()
 before=ui.game.export_snapshot()
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false);await t.frames()
 t.check(ui.game.state==before and ui.view.relics.filter(func(r):return r.id=="doubao")[0].icon=="deepseek","CONTROL UI combat right click cannot toggle even after first turn")
 await return_to_map(t)
 shortcut=ui.find_child("RelicShortcut_doubao",true,false);point=shortcut.get_global_rect().get_center()
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false);await t.frames()
 t.check(ui.view.relics.filter(func(r):return r.id=="doubao")[0].icon=="doubao","CONTROL UI right click switches back to bean icon")
 await t.start_practice("StartDoubaoPractice");await t.frames()
 t.check(ui.view.practice and ui.view.practice_kind=="doubao" and ui.view.phase=="battle" and ui._takeover_locked(),"CONTROL UI real practice entry starts Doubao battle")
 var presenter=ui.takeover_presenter
 t.check(presenter.banner.text=="豆包接管中" and presenter.bubble.visible,"CONTROL UI takeover has icon-anchored speech")
 t.check(presenter.voice.playing and presenter.voice.stream.resource_path==preload("res://data/doubao_dialogue.gd").entry("start",presenter.variant).voice,"VOICE real practice introduction plays its matching A/B recording")
 var relic_rect=ui.find_child("RelicShortcut_doubao",true,false).get_global_rect()
 t.check(presenter.bubble.get_global_rect().position.y>=relic_rect.end.y and presenter.bubble.get_global_rect().end.x<=1600,"CONTROL UI dialogue is below relic and within canvas")
 await t.capture("ui-doubao-intro.png")
 var version=ui.view.version
 var selected=ui.view.first_turn_control.candidate
 ui.command_router.emit(String(selected.payload.get("kind","")),selected)
 await t.mouse_button(Vector2(1530,25),MOUSE_BUTTON_LEFT,true);await t.mouse_button(Vector2(1530,25),MOUSE_BUTTON_LEFT,false)
 await preload("res://tests/keyboard_ui_cases.gd").tap(t,KEY_ESCAPE)
 var touch=InputEventScreenTouch.new();touch.index=0;touch.position=Vector2(1500,25);touch.pressed=true
 ui.touch_input._input(touch);touch.pressed=false;ui.touch_input._input(touch)
 t.check(ui.view.version==version and not ui.show_menu and not ui.show_options and ui.touch_input.finger==-1,"CONTROL UI blocks direct button submit, mouse, keyboard and touch while waiting")
 t.check(ui.find_child("RelicShortcut_doubao",true,false).get_child(0).glyph.texture==preload("res://ui/relic_icon.gd").ART.doubao,"CONTROL UI pixel portrait is the rendered relic texture")
 var steps=0;var moved=false;var start_cursor=presenter.cursor;var captured=false
 var hero_speech_seen=false;var hero_silent=true
 while ui._takeover_locked() and steps<900:
  if is_instance_valid(ui.enemy_feedback): ui.enemy_feedback.finish()
  await ui.get_tree().create_timer(0.1).timeout
  hero_speech_seen=hero_speech_seen or not ui.view.speech.is_empty()
  hero_silent=hero_silent and ui.find_child("HeroSpeech",true,false)==null
  moved=moved or presenter.cursor.distance_to(start_cursor)>50
  if moved and presenter.clicking and presenter.cursor.y>presenter.bubble.get_rect().end.y and not captured:
   captured=true;await t.capture("ui-doubao-cursor.png")
  steps+=1
 t.check(steps<900 and ui.view.version>version and not ui._takeover_locked(),"CONTROL UI paced practice completes through actual submissions")
 t.check(moved and steps>=30,"CONTROL UI simulated cursor moves and does not rush the takeover")
 t.check(hero_speech_seen and hero_silent,"CONTROL UI real automated actions retain speech logs without opening hero bubbles")
 ui.render();await t.frames()
 t.check(ui.find_child("HeroSpeech",true,false)==null,"CONTROL UI completed takeover does not replay suppressed hero speech on repaint")
 # Exercise the shared bubble presenter with an NPC projection between hero renders.
 var npc_view=ui.view.duplicate(true)
 npc_view.npc_speech={"id":"suppression-probe","text":"例行巡视","cue":"prison.guard.release_check","visual":"guard_purple","phase":ui.view.phase}
 ui.render(npc_view);await t.frames()
 t.check(ui.find_child("NpcSpeech",true,false)!=null,"CONTROL UI suppressed hero speech leaves NPC bubble available")
 ui.render();await t.frames()
 t.check(ui.find_child("HeroSpeech",true,false)==null,"CONTROL UI NPC bubble cannot revive suppressed takeover speech")
 if is_instance_valid(ui.enemy_feedback): ui.enemy_feedback.finish()
 t.check(presenter.mouse_filter==Control.MOUSE_FILTER_IGNORE,"CONTROL UI input shield is removed on completion")
 ui.game._finish_battle();ui.render();await t.frames()
 t.check(await t.click("reward",{"type":"skip"}),"CONTROL UI player claims reward before preparation")
 t.check(ui.view.phase=="prepare" and not ui._takeover_locked() and ui.view.first_turn_control.is_empty(),"CONTROL UI preparation never reopens Doubao input shield")
 t.check(await t.click("end"),"CONTROL UI player can manually end first preparation turn")
 # Starting another game invalidates a pending intro/animation instead of committing into it.
 ui.restart(42,true,"doubao");await t.frames();ui.restart(43);await t.frames()
 t.check(not presenter.voice.playing and presenter.voice.stream==null,"VOICE replacement game cancels pending intro audio")
 version=ui.view.version
 await ui.get_tree().create_timer(5.5).timeout
 t.check(ui.view.version==version and not ui._takeover_locked(),"CONTROL UI stale takeover cannot act in replacement game")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("豆包接管中")=="Doubao is in control" and ui.localization.display("抖M印记")=="Masochist Mark","CONTROL UI new relic labels have English translations")
 ui.localization.set_locale("zh_CN")
 ui.restart(42);await t.frames()
 AudioServer.set_bus_mute(0,was_muted)
