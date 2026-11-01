extends Control
const CardFace=preload("res://ui/card_face.gd")
# Ghost cards animate committed transfers; they never own cards or block input.
var host
var running: Array=[]
var pending_draws: Dictionary={}
const DRAW=Vector2(249.5,856)
const DISCARD=Vector2(1368,810)
const EXHAUST=Vector2(1240,550)
const POWER=Vector2(249.5,808)

static func positions(ui) -> Dictionary:
 var out={}
 for uid in ui.card_buttons:
  var card=ui.card_buttons[uid]
  out[uid]={"position":card.position,"size":card.size,"rotation":card.resting_angle,"free":card.free_face}
 return out

func _ready() -> void:
 name="CardMotion";mouse_filter=Control.MOUSE_FILTER_IGNORE;z_index=225

func clear() -> void:
 for uid in pending_draws:
  if host.card_buttons.has(uid): host.card_buttons[uid].show()
 pending_draws.clear()
 for tween in running:
  if tween.is_valid(): tween.kill()
 running.clear()
 for child in get_children(): child.queue_free()

func _process(_delta: float) -> void:
 if host.show_home:
  clear();return
 position=host.layout.position;scale=host.layout.scale

func enqueue(events: Array, before: Dictionary) -> void:
 if events.is_empty(): return
 if host.display_settings.reduced_card_motion:
  clear();return
 events=events.duplicate(true)
 for uid in pending_draws:
  if host.card_buttons.has(uid) and not events.any(func(event):return event.uid==uid and event.kind=="draw"):
   events.push_front(pending_draws[uid])
 clear()
 var after=positions(host)
 for event in events:
  if event.kind=="draw" and after.has(event.uid):
   pending_draws[event.uid]=event
   host.card_buttons[event.uid].hide()
 var delay=0.0
 for event in events:
  if event.kind=="retain":
   if host.card_buttons.has(event.uid):
    var card=host.card_buttons[event.uid]
    var pulse=card.create_tween()
    pulse.tween_property(card,"self_modulate",Color("9eeedb"),0.15)
    pulse.tween_property(card,"self_modulate",Color.WHITE,0.35)
   continue
  if event.kind=="shuffle":
   for i in range(3): fly_back(DISCARD+Vector2(i*5,-i*4),DRAW,delay+i*0.05)
   delay+=0.22
   continue
  var draws=event.kind=="draw"
  var fallback={"position":Vector2(760,660),"size":CardFace.dimensions(252)}
  var origin=before.get(event.uid,fallback)
  var destination=after.get(event.uid,fallback)
  var start=DRAW if draws else origin.position+origin.size/2
  var end=destination.position+destination.size/2 if draws else (POWER if event.kind=="play_power" else (EXHAUST if "exhaust" in event.kind else DISCARD))
  var face_key="display_motion_"+event.uid+"_"+event.type
  host.card_faces[face_key]=after.get(event.uid,before.get(event.uid,{})).get("free",false)
  var ghost=host._display_card(event.type,self,Callable(),"motion_"+event.uid,Vector2(184,252),event.uid)
  host.card_faces.erase(face_key)
  ghost.name="CardMotion_"+event.kind+"_"+event.uid
  host._ignore_mouse(ghost)
  ghost.pivot_offset=ghost.size/2
  ghost.position=start-ghost.pivot_offset
  ghost.scale=Vector2.ONE*(0.22 if draws else 1.0)
  ghost.modulate.a=0
  var tween=create_tween();running.append(tween)
  tween.tween_interval(delay)
  tween.tween_property(ghost,"modulate:a",1.0,0.04)
  if event.kind.begins_with("play"):
   tween.tween_property(ghost,"position",Vector2(740,390),0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
   tween.tween_property(ghost,"self_modulate",Color("c9fff3") if ghost.effect_free else Color("ffe1a2"),0.09)
   tween.tween_property(ghost,"self_modulate",Color.WHITE,0.08)
  tween.set_parallel(true)
  tween.tween_property(ghost,"position",end-ghost.pivot_offset,0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  tween.tween_property(ghost,"scale",Vector2.ONE*(1.0 if draws else 0.18),0.42)
  tween.tween_property(ghost,"rotation",after.get(event.uid,{}).get("rotation",0.0) if draws else -0.22,0.42)
  if "exhaust" in event.kind:
   tween.tween_property(ghost,"modulate",Color(1.0,0.4,0.15,0.0),0.42)
  elif not draws: tween.tween_property(ghost,"modulate:a",0.0,0.12).set_delay(0.32)
  tween.chain().tween_callback(func():
   if draws:
    pending_draws.erase(event.uid)
    if host.card_buttons.has(event.uid): host.card_buttons[event.uid].show()
   ghost.queue_free())
  delay+=0.18 if draws else 0.06
 for uid in after:
  if not before.has(uid) or events.any(func(event):return event.uid==uid): continue
  var card=host.card_buttons[uid]
  var destination=card.position
  card.position=before[uid].position
  var settle=card.create_tween()
  settle.tween_property(card,"position",destination,0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func fly_back(start: Vector2, end: Vector2, delay: float) -> void:
 var back=Panel.new();back.mouse_filter=Control.MOUSE_FILTER_IGNORE
 back.add_theme_stylebox_override("panel",host._style(Color("213c47"),host.GOLD))
 add_child(back);back.size=CardFace.dimensions(54);back.position=start-back.size/2;back.rotation=-0.12
 var tween=create_tween();running.append(tween)
 tween.tween_interval(delay)
 tween.tween_property(back,"position",end-back.size/2,0.3).set_trans(Tween.TRANS_QUAD)
 tween.tween_callback(back.queue_free)
