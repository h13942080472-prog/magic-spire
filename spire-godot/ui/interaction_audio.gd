extends Node

# Presentation only: committed receipts and control signals never write game state.
signal played(cue: String)
const CardFace=preload("res://ui/card_face.gd")
const CLIPS={
 "button":preload("res://assets/audio/interaction/button.wav"),
 "tab":preload("res://assets/audio/interaction/tab.wav"),
 "window_open":preload("res://assets/audio/interaction/window_open.wav"),
 "window_close":preload("res://assets/audio/interaction/window_close.wav"),
 "card_pickup":preload("res://assets/audio/interaction/card_pickup.wav"),
 "card_flip":preload("res://assets/audio/interaction/card_flip.wav"),
 "card_play":preload("res://assets/audio/interaction/card_play.wav"),
 "card_draw":preload("res://assets/audio/interaction/card_draw.wav"),
 "spell_success":preload("res://assets/audio/interaction/spell_success.wav"),
 "spell_failure":preload("res://assets/audio/interaction/spell_failure.wav"),
 "turn_end":preload("res://assets/audio/interaction/turn_end.wav"),
 "reward":preload("res://assets/audio/interaction/reward.wav"),
 "hit":preload("res://assets/audio/interaction/hit.wav"),
 "block":preload("res://assets/audio/interaction/block.wav"),
 "card_exhaust":preload("res://assets/audio/interaction/card_exhaust.wav"),
 "cancel":preload("res://assets/audio/interaction/cancel.wav"),
 "fireball":preload("res://assets/audio/interaction/fireball.wav"),
}
const PRIORITY={"button":0,"tab":1,"card_pickup":2,"card_flip":3,"cancel":4,"window_close":5,"window_open":6,"card_draw":7,"card_exhaust":8,"turn_end":9,"card_play":10,"spell_success":11,"hit":12,"block":13,"reward":14,"spell_failure":15,"fireball":16}
var host
var enabled=true
var volume=0.7
var voices: Dictionary={}
var pending: Dictionary={}
var recent: Dictionary={}
var flush_scheduled=false
var windows: Array=[]

func _ready() -> void:
 name="InteractionAudio"
 for lane in ["control","action","pile"]:
  var player=AudioStreamPlayer.new();player.name=lane;player.max_polyphony=1
  add_child(player);voices[lane]=player
 get_tree().node_added.connect(_watch)

func configure(active: bool, level: float) -> void:
 enabled=active;volume=clampf(level,0.0,1.0)
 for lane in voices:
  voices[lane].volume_db=linear_to_db(maxf(volume,0.0001))+(-7.0 if lane=="pile" else 0.0)
 if not enabled or volume==0: stop_all()

func _watch(node: Node) -> void:
 if not host.is_ancestor_of(node): return
 if node is OptionButton:
  node.item_selected.connect(func(_index):request("tab"))
 elif node is BaseButton and not node is CardFace:
  node.pressed.connect(func():
   if not node.disabled: request(String(node.get_meta("audio_cue","tab" if node.toggle_mode else "button"))))

func sync_windows(active: Array) -> void:
 if active==windows: return
 var opening=active.any(func(id):return id not in windows)
 windows=active.duplicate()
 request("window_open" if opening else "window_close")

func request(cue: String) -> void:
 if not enabled or volume==0 or not CLIPS.has(cue): return
 var lane="control" if PRIORITY[cue]<=6 else ("pile" if cue in ["card_draw","card_exhaust"] else "action")
 if not pending.has(lane) or PRIORITY[cue]>PRIORITY[pending[lane]]: pending[lane]=cue
 if flush_scheduled: return
 flush_scheduled=true;_flush.call_deferred()

func _flush() -> void:
 flush_scheduled=false
 var batch=pending;pending={}
 # Specific action feedback replaces a generic click from the same input.
 if batch.has("action") and batch.get("control","") in ["button","tab","card_pickup"]: batch.erase("control")
 for lane in batch:
  var cue=String(batch[lane]);var now=Time.get_ticks_msec()
  if now-int(recent.get(cue,-1000))<75: continue
  recent[cue]=now
  voices[lane].stream=CLIPS[cue];voices[lane].play()
  played.emit(cue)

func consume(result: Dictionary, before: Dictionary, after: Dictionary) -> void:
 if not result.get("ok",false):
  request("cancel");return
 var payload=result.get("fact",{}).get("payload",{})
 var kind=String(payload.get("kind",""))
 if kind=="card" or (kind=="prison" and payload.has("uid")): request("card_play")
 elif kind=="end": request("turn_end")
 elif kind in ["reward","relic_bundle"]: request("reward")
 if result.get("spell_failed",false): request("spell_failure")
 # Only the new structured records are consumed, never the translated log text.
 for index in range(before.logs.size(),after.logs.size()):
  var record=after.logs[index].data
  var spell=record.get("spell",{})
  if not spell.is_empty():
   request(("fireball" if spell.type=="fireball" else "spell_success") if spell.success else "spell_failure")
  if record.has("enemy") and float(record.get("damage",0))>0: request("hit")
  if record.has("evasion"): request("block")

func transfers(events: Array) -> void:
 for event in events:
  if event.kind=="draw": request("card_draw")
  elif "exhaust" in event.kind: request("card_exhaust")

func stop_all() -> void:
 pending.clear();recent.clear()
 for player in voices.values(): player.stop()

func _exit_tree() -> void:
 get_tree().node_added.disconnect(_watch)
