extends RefCounted
const Audio=preload("res://ui/interaction_audio.gd")
const Settings=preload("res://ui/display_settings.gd")
const Queries=preload("res://ui/target_queries.gd")
const CardInput=preload("res://tests/card_interaction_ui_cases.gd")
const Touch=preload("res://tests/touch_ui_cases.gd")
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui;var audio=ui.interaction_audio;var heard=[]
 var listener=func(cue):heard.append(cue)
 audio.played.connect(listener)
 audio.configure(true,0.7)
 t.check(Audio.CLIPS.size()==17 and Audio.CLIPS.values().all(func(clip):return clip is AudioStreamWAV and clip.loop_mode==AudioStreamWAV.LOOP_DISABLED and clip.get_length()>0 and clip.get_length()<1.3),"SFX all 17 approved clips import as finite non-looping audio")
 audio.stop_all();heard.clear()
 await t.open_menu()
 t.check(heard==["window_open"],"SFX native menu open replaces its generic button click")
 heard.clear();ui.render(ui.view);await t.frames()
 t.check(heard.is_empty(),"SFX rebuilding an open window never replays its sound")
 await t.close_information()
 t.check(heard==["window_close"],"SFX native close emits only the quiet closing clip")
 t.check(audio.voices.control.stream==Audio.CLIPS.window_close,"SFX window close uses the quieter approved asset")

 var uid=await CardInput.setup(t,"strain")
 audio.stop_all();heard.clear();var before=ui.game.export_snapshot()
 await t.flip(uid)
 t.check(heard==["card_flip"] and ui.game.export_snapshot()==before,"SFX desktop flip sounds once without changing gameplay")
 audio.stop_all();heard.clear();ui.display_settings.reduced_card_motion=true
 var point=t.card_point(uid)
 await Touch.finger(t,point,true);await Touch.move(t,point+Vector2(0,70));await Touch.finger(t,point+Vector2(0,70),false)
 t.check(heard==["card_flip"] and ui.game.export_snapshot()==before,"SFX touch downward flip survives reduced animation mode without a click")
 ui.display_settings.reduced_card_motion=false
 audio.stop_all();heard.clear();await CardInput.start(t,uid)
 t.check(heard==["card_pickup"],"SFX real native card drag plays pickup once")
 await t.move_mouse(Vector2(10,10),true);await t.mouse_button(Vector2(10,10),MOUSE_BUTTON_LEFT,false)
 t.check(heard.has("cancel") and ui.game.export_snapshot()==before,"SFX invalid drop gives cancellation without playing a card")

 uid=await CardInput.setup(t,"panic")
 audio.stop_all();heard.clear();await CardInput.start(t,uid)
 var destination=Vector2(820,340)
 await t.move_mouse(destination,true);await t.mouse_button(destination,MOUSE_BUTTON_LEFT,false)
 t.check(heard.has("card_play") and heard.has("card_exhaust") and not heard.has("cancel"),"SFX accepted self-card drop plays and exhausts without cancellation")

 ui.restart(42);await t.frames();audio.stop_all();heard.clear()
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy}),"SFX real fireball action commits")
 t.check(heard==["fireball"],"SFX fireball replaces generic success, impact and button sounds")
 t.check(audio.voices.action.stream==Audio.CLIPS.fireball,"SFX committed fireball starts its actual imported stream")
 heard.clear();ui.render(ui.view);await t.frames()
 t.check(heard.is_empty(),"SFX redraw never repeats the last fireball")
 audio.stop_all();heard.clear()
 var fire=Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy})
 before=ui.game.export_snapshot()
 ui.command_router.emit("attack",fire,ui.view.version+99);await t.frames()
 t.check(heard==["cancel"] and ui.game.export_snapshot()==before,"SFX stale command rejects without success audio or state changes")

 ui.restart(42);ui.game.state.pressure=75
 var rng=ui.game.state.rng.magic
 while ui.game._random_index("magic",ui.game.B.CAST_ROLL_STEPS)<ui.game.cast_view(ui.game.Cards.cast_profile(ui.game,"fireball")).winning_rolls: rng=ui.game.state.rng.magic
 ui.game.state.rng.magic=rng;ui.render();await t.frames();audio.stop_all();heard.clear()
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy}),"SFX payable failed cast commits through real input")
 t.check(heard==["spell_failure"] and ui.game._magic_failed,"SFX failed fireball emits only failure rather than its explosion")

 audio.stop_all();heard.clear()
 for i in range(20): audio.request("button");audio.request("card_draw")
 await t.frames()
 t.check(heard.count("button")==1 and heard.count("card_draw")==1,"SFX repeated cues coalesce within one presentation frame")
 audio.stop_all();heard.clear();audio.request("fireball");audio.configure(false,0.7);await t.frames()
 t.check(heard.is_empty() and audio.voices.values().all(func(player):return not player.playing),"SFX disabling clears pending and active sounds immediately")
 audio.configure(true,0);audio.request("fireball");await t.frames()
 t.check(heard.is_empty(),"SFX zero volume prevents pending playback")
 audio.configure(true,0.7);audio.request("fireball");ui._return_home();await t.frames()
 t.check(not audio.voices.action.playing,"SFX returning home clears the pending action sound")
 await settings(t)
 audio.played.disconnect(listener)

static func settings(t) -> void:
 var ui=t.ui;var audio=ui.interaction_audio
 ui._open_drawer("show_options");await t.frames()
 await Pointer.press(t,ui.find_child("SettingsTab_audio",true,false))
 var toggle=ui.find_child("InteractionAudioEnabled",true,false)
 var slider=ui.find_child("InteractionAudioVolume",true,false)
 t.check(toggle!=null and slider!=null,"SFX settings expose an effect switch and volume slider")
 if toggle==null or slider==null: return
 await Pointer.press(t,toggle)
 t.check(not audio.enabled and not ui.display_settings.interaction_audio_enabled,"SFX native settings toggle controls playback")
 slider.value=37
 t.check(is_equal_approx(audio.volume,0.37) and is_equal_approx(ui.display_settings.interaction_audio_volume,0.37),"SFX settings volume updates the runtime player")
 var path="res://build/sfx-settings-%s.cfg" % Time.get_ticks_usec()
 var saved=Settings.new();saved.path=path;saved.initialize(t.root)
 saved.set_interaction_audio(false,0.37)
 var loaded=Settings.new();loaded.path=path;loaded.initialize(t.root)
 t.check(not loaded.interaction_audio_enabled and is_equal_approx(loaded.interaction_audio_volume,0.37),"SFX effect preferences persist in an isolated settings file")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 ui.display_settings.set_interaction_audio(true,0.7);audio.configure(true,0.7)
 ui._close_drawers();ui._refresh_drawers();await t.frames()
