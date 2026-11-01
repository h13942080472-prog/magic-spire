extends RefCounted
const Voice=preload("res://ui/hero_voice.gd")
const Profile=preload("res://data/girl_sound_profile.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var expected={"edge":[25,24],"hit":[45,37],"orgasm":[21,14],"struggle":[8,12]}
 for family in expected:
  for gagged in [false,true]:
   var cue=Profile.cue(family,gagged);var pool=Profile.pool(cue)
   t.check(pool.size()==expected[family][1 if gagged else 0] and pool.all(func(path):return ResourceLoader.exists(path)),"VOICE imported pool is complete: "+cue)
 var ui=t.ui;ui.restart(42);await t.frames()
 var player=ui.hero_voice;player.rng.seed=42
 t.check(player.max_polyphony==1 and player.volume_db==-9.0,"VOICE uses one quiet playback voice")
 player.consume([]);player.consume(["rope_leather_tension"])
 t.check(not player.playing,"VOICE unrelated receipts are silent")
 for family in expected:
  for gagged in [false,true]:
   var cue=Profile.cue(family,gagged)
   player.consume([cue])
   t.check(player.playing and player.stream is AudioStreamOggVorbis and not player.stream.loop and player.last_cue==cue and player.last_path in Profile.pool(cue),"VOICE cue randomly selects one finite clip: "+cue)
   player.stop()
 player.consume([Profile.cue("edge",false),Profile.cue("hit",false),Profile.cue("struggle",false),Profile.cue("orgasm",false)])
 t.check(player.last_cue==Profile.cue("orgasm",false),"VOICE simultaneous families choose orgasm priority once")
 var playback=player.get_stream_playback();var path=player.last_path;var position=player.get_playback_position()
 player.consume([Profile.cue("edge",true)]);player.consume([Profile.cue("hit",true)])
 t.check(player.playing and player.last_path==path and player.get_stream_playback()==playback and player.get_playback_position()>=position,"VOICE overlap neither layers nor restarts or redraws")
 var deadline=Time.get_ticks_msec()+int((player.stream.get_length()+1.0)*1000)
 while player.playing and Time.get_ticks_msec()<deadline: await t.process_frame
 t.check(not player.playing and player.last_path==path,"VOICE ignored overlaps never queue a second clip")
 var selected={}
 for i in range(12):
  player.consume([Profile.cue("edge",false)]);selected[player.last_path]=true;player.stop()
 t.check(selected.size()>1,"VOICE presentation RNG selects different clips without touching gameplay RNG")
 var target=ui.game.add_fixture("ankle",8)
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"strain")
 ui.render();await t.frames()
 var candidate=Queries.find(ui.view,"card",{"uid":card.uid,"target":target.id,"free":false})
 t.check(candidate.valid,"VOICE real UI card damage is usable")
 if not candidate.valid: return
 ui.command_router.emit("card",candidate)
 t.check(player.playing and player.last_cue==Profile.cue("struggle",false),"VOICE successful UI submission plays the committed struggle cue")
 player.stop();ui.render(ui.view);await t.frames()
 t.check(not player.playing,"VOICE redraw does not replay the last receipt")
 player.consume([Profile.cue("edge",false)]);ui.restart(42);await t.frames()
 t.check(not player.playing,"VOICE restart stops the previous clip")
 player.consume([Profile.cue("edge",false)]);var home_before=ui.game.export_snapshot();ui._return_home();await t.frames()
 t.check(not player.playing and ui.game.export_snapshot()==home_before,"VOICE returning home stops playback without retaining an audio queue or changing game state")
