extends AudioStreamPlayer

const Profile=preload("res://data/girl_sound_profile.gd")
var rng=RandomNumberGenerator.new()
var last_cue=""
var last_path=""

func _ready() -> void:
 name="HeroVoice"
 max_polyphony=1
 volume_db=-9.0
 rng.randomize()

func consume(cues: Array) -> void:
 if playing or stream_paused: return
 var selected_cue=Profile.select_cue(cues)
 if selected_cue=="": return
 var pool=Profile.pool(selected_cue)
 if pool.is_empty(): return
 var selected_path=pool[rng.randi_range(0,pool.size()-1)]
 if not ResourceLoader.exists(selected_path): return
 var selected=load(selected_path)
 if not selected is AudioStreamOggVorbis: return
 selected.loop=false
 stream=selected
 last_cue=selected_cue
 last_path=selected_path
 play()
