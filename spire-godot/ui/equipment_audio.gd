extends AudioStreamPlayer

# Each committed operation may overlap an earlier tail; no delayed audio queue.
signal played
const CUE="rope_leather_tension"
const CLIP=preload("res://assets/audio/rope-leather-tension.mp3")

func _ready() -> void:
 name="EquipmentAudio"
 stream=CLIP
 max_polyphony=8
 volume_db=-9.0

func consume(cues: Array) -> void:
 if CUE not in cues or stream_paused: return
 play()
 played.emit()
