extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")
const Give=preload("res://tests/curse_cases.gd")
const Settings=preload("res://ui/display_settings.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 t.check(ui.display_settings.card_music_enabled and is_equal_approx(ui.display_settings.card_music_volume,0.2),"MUSIC default enabled at twenty percent")
 var before=ui.game.export_snapshot()
 await t.open_menu();await Navigation.press(t,"OpenOptions");await Navigation.press(t,"SettingsTab_audio")
 var toggle=ui.find_child("CardMusicEnabled",true,false)
 var volume=ui.find_child("CardMusicVolume",true,false)
 t.check(toggle.button_pressed and volume.value==20 and volume.max_value==100,"MUSIC sound tab offers real toggle and percent slider")
 volume.value=35
 t.check(is_equal_approx(ui.card_music.volume_linear,0.35) and ui.find_child("CardMusicVolumeLabel",true,false).text.contains("35%"),"MUSIC volume updates player and percentage immediately")
 await t.capture("ui-card-music-settings.png")
 ui.card_music.configure(true,0.0)
 ui.card_music.play_track("rain_love","battle",true)
 t.check(ui.card_music.playing and ui.card_music.stream.loop and ui.card_music.stream.get_length()>225,"MUSIC full supplied song loads and loops")
 t.check(is_zero_approx(ui.card_music.fade_gain),"MUSIC song starts silent for fade-in")
 await t.frames(12)
 t.check(ui.card_music.fade_gain>0.0 and ui.card_music.fade_gain<1.0,"MUSIC fade-in progressively raises gain")
 await t.create_timer(0.8).timeout
 t.check(is_equal_approx(ui.card_music.fade_gain,1.0),"MUSIC fade-in reaches configured volume")
 var prior=ui.card_music.stream
 ui.card_music.play_track("rain_love","prison",false)
 await t.frames(12)
 t.check(ui.card_music.ending and ui.card_music.stream==prior and ui.card_music.fade_gain>0.0 and ui.card_music.fade_gain<1.0,"MUSIC replacement fades previous song before starting next")
 await t.create_timer(0.8).timeout
 t.check(ui.card_music.playing and ui.card_music.stream!=prior and not ui.card_music.stream.loop,"MUSIC new playback replaces existing song and can switch to one-shot")
 ui.card_music.seek(ui.card_music.stream.get_length()-0.1)
 await t.frames(45)
 t.check(not ui.card_music.playing and ui.card_music.track_id.is_empty(),"MUSIC prison song naturally finishes without looping")
 ui.card_music.play_track("rain_love","battle",true)
 ui.card_music.seek(12.0);await t.frames()
 var paused_stream=ui.card_music.stream
 toggle.button_pressed=false
 # The audio mixer observes the pause on its next block, not on the UI frame.
 await t.frames(4)
 var paused_position=ui.card_music.get_playback_position()
 await t.frames(12)
 t.check(ui.card_music.stream_paused and not ui.display_settings.card_music_enabled and paused_position>=12.0 and is_equal_approx(ui.card_music.get_playback_position(),paused_position),"MUSIC disabling switch pauses audio at its existing position")
 ui.card_music.consume([{"track":"rain_love","phase":"battle","loop":true}],"battle")
 t.check(ui.card_music.stream==paused_stream and ui.card_music.stream_paused and is_equal_approx(ui.card_music.get_playback_position(),paused_position),"MUSIC repeated play while disabled preserves paused song")
 toggle.button_pressed=true
 await t.frames()
 t.check(ui.card_music.playing and not ui.card_music.stream_paused and ui.card_music.stream==paused_stream and ui.card_music.get_playback_position()>=paused_position,"MUSIC reenabling resumes the previous position")
 ui.card_music.configure(false,0.0);ui.card_music.sync_phase("reward")
 ui.card_music.configure(true,0.0)
 t.check(not ui.card_music.playing and ui.card_music.stream==null,"MUSIC battle ending while paused clears resumable playback")
 t.check(ui.game.export_snapshot()==before,"MUSIC settings never change gameplay state")
 await t.close_information();ui.options_tab="display"
 var path="res://build/music-settings-%s.cfg" % OS.get_process_id()
 var prefs=Settings.new();prefs.path=path;prefs.initialize(t.root,false);prefs.persistence_enabled=true
 prefs.set_card_music(false,0.35)
 var restored=Settings.new();restored.path=path;restored.initialize(t.root)
 t.check(not restored.card_music_enabled and is_equal_approx(restored.card_music_volume,0.35),"MUSIC preferences survive reload separately from game save")
 var config=ConfigFile.new();config.set_value("audio","card_music_volume","invalid");config.save(path)
 restored.initialize(t.root)
 t.check(restored.card_music_enabled and is_equal_approx(restored.card_music_volume,0.2),"MUSIC missing or invalid preference safely defaults")
 DirAccess.remove_absolute(path)
 ui.restart(42);await t.frames();ui.game._discard_end()
 ui.game.state.energy=10
 var card=Give.give(ui.game,"hannya_henshin")
 ui.render();await t.frames()
 ui.card_music.configure(true,0.0)
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("打出时播放dj版雨爱"),"MUSIC printed card shows requested short description")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.card_music.playing and ui.card_music.stream.loop,"MUSIC actual perfect henshin click starts battle song")
 var position=ui.card_music.get_playback_position()
 ui.render();await t.frames()
 t.check(ui.card_music.playing and ui.card_music.get_playback_position()>=position,"MUSIC rerender does not restart or duplicate song")
 ui.card_music.seek(20.0);await t.frames()
 var original_stream=ui.card_music.stream
 card=Give.give(ui.game,"henshin");ui.render();await t.frames()
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.exhaust.any(func(c):return c.uid==card.uid) and ui.card_music.stream==original_stream and ui.card_music.get_playback_position()>=20.0,"MUSIC repeated actual play across henshin versions keeps song progress")
 ui.game._finish_battle();ui.render()
 t.check(ui.card_music.playing and ui.card_music.ending,"MUSIC battle end starts fade-out without abruptly cutting song")
 await t.frames(12)
 var fading_gain=ui.card_music.fade_gain
 ui.render()
 t.check(fading_gain>0.0 and fading_gain<1.0 and ui.card_music.fade_gain==fading_gain,"MUSIC repeated phase sync does not restart fade-out")
 await t.create_timer(1.0).timeout
 t.check(ui.card_music.playing and ui.card_music.fade_gain>0.0 and ui.card_music.fade_gain<fading_gain,"MUSIC reward screen keeps the song fading beyond the first second")
 await t.create_timer(3.2).timeout
 t.check(ui.game.state.combat.active and ui.view.phase=="reward" and not ui.card_music.playing,"MUSIC stops on victory before preparation ends")
 ui.card_music.consume([{"track":"rain_love","phase":"battle","loop":true}],"reward")
 t.check(not ui.card_music.playing,"MUSIC a card that leaves battle cannot start a late song")
 ui.restart(42);ui.card_music.play_track("rain_love","battle",true);ui._return_home()
 t.check(not ui.card_music.playing,"MUSIC home stops playback")
 ui.display_settings.set_card_music(true,0.2);ui.card_music.configure(true,0.2)
 await mandarin_duck(t)

static func mandarin_duck(t) -> void:
 var ui=t.ui
 ui.restart(42,true,"henshin")
 # This scenario plays several cards in one turn; do not rely on starter energy.
 ui.game.state.energy=10;ui.render();await t.frames()
 ui.card_music.configure(true,0.0)
 t.check(ui.view.hand.any(func(c):return c.type=="hannya_2"),"DUCK MUSIC practice includes second soup in starting hand")
 var card=ui.view.hand.filter(func(c):return c.type=="henshin")[0]
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 card=ui.view.hand.filter(func(c):return c.type=="hannya_2")[0]
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("打出时自动播放鸳鸯戏"),"DUCK MUSIC visible dynamic card includes song description")
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 # The hand relayouts after the first card leaves it; settle the frames and retry the real click
 # once if the play did not register, so the assertion below always observes an actual play.
 await t.frames(4)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 if ui.view.hand.any(func(c):return c.uid==card.uid):
  await t.frames(4)
  await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 await t.create_timer(0.8).timeout
 t.check(ui.card_music.track_id=="mandarin_duck_play" and ui.card_music.playing and ui.card_music.stream.loop and absf(ui.card_music.stream.get_length()-61.0)<0.01,"DUCK MUSIC actual soup play replaces rain with full 61-second looping clip")
 ui.card_music.seek(10.0);await t.frames()
 ui.card_music.configure(false,0.0);await t.frames(4)
 var paused=ui.card_music.get_playback_position()
 await t.create_timer(0.2).timeout
 t.check(ui.card_music.stream_paused and is_equal_approx(paused,ui.card_music.get_playback_position()),"DUCK MUSIC shares pause and retained position")
 ui.card_music.configure(true,0.0)
 var original=ui.card_music.stream
 card=Give.give(ui.game,"hannya_2");ui.render();await t.frames()
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 t.check(Queries.find(ui.view,"card",{"uid":card.uid,"free":false}).valid,"DUCK MUSIC repeated-play fixture can pay for the next real card")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 var exhausted=ui.game.state.exhaust.any(func(c):return c.uid==card.uid)
 var same_stream=ui.card_music.stream==original
 var resumed_position=ui.card_music.get_playback_position()
 t.check(exhausted and same_stream and resumed_position>=paused,"DUCK MUSIC repeated actual soup play preserves progress: exhausted=%s same_stream=%s position=%s paused=%s" % [exhausted,same_stream,resumed_position,paused])
 ui.card_music.seek(60.8)
 await t.create_timer(0.5).timeout
 t.check(ui.card_music.playing and ui.card_music.get_playback_position()<2.0,"DUCK MUSIC battle loops at trimmed clip boundary")
 card=ui.view.hand.filter(func(c):return c.type=="hannya_henshin")[0]
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 await t.create_timer(0.8).timeout
 t.check(ui.card_music.track_id=="rain_love" and ui.card_music.playing,"DUCK MUSIC subsequent henshin replaces soup song through same channel")
 ui.card_music.play_track("mandarin_duck_play","prison",false)
 await t.create_timer(0.8).timeout
 t.check(not ui.card_music.stream.loop and ui.card_music.track_id=="mandarin_duck_play","DUCK MUSIC prison uses same clip once")
 ui.card_music.seek(60.8)
 await t.create_timer(0.5).timeout
 t.check(not ui.card_music.playing,"DUCK MUSIC prison clip finishes naturally")
 ui._return_home();ui.card_music.configure(ui.display_settings.card_music_enabled,ui.display_settings.card_music_volume)
