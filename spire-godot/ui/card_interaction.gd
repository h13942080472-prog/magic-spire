extends Control

# Read-only card presentation. Native receivers remain the only drop authority.
var host
var inspected: Control
var preview: Control
var flips: Dictionary={}
var drag: Dictionary={}
var origin=Vector2.ZERO
var endpoint=Vector2.ZERO
var pointer=Vector2.ZERO
var accepted=false
var targeting=true
var elapsed=0.0
var hand_positions: Dictionary={}
var drag_source: Control
var drag_alpha=1.0

func _ready() -> void:
 name="CardInteraction";mouse_filter=Control.MOUSE_FILTER_IGNORE;z_index=230
 align_layout()
 set_process(false)

func align_layout() -> void:
 position=host.layout.position;scale=host.layout.scale

func reduced() -> bool:
 return host.display_settings.reduced_card_motion

func inspect(card: Control) -> void:
 if not drag.is_empty() or host._takeover_locked() or not card.is_visible_in_tree(): return
 close_inspection()
 inspected=card;align_layout()
 preview=card.preview_factory.call(self,336.0)
 preview.name="CardInspectionPreview"
 var bounds=get_global_transform().affine_inverse()*card.get_global_rect()
 preview.position=Vector2(clampf(bounds.get_center().x-preview.size.x/2,320,1350-preview.size.x),maxf(128,bounds.position.y-preview.size.y-16))
 preview.modulate=Color.WHITE
 set_process(true)

func close_inspection(card: Control=null) -> void:
 if card!=null and card!=inspected: return
 if is_instance_valid(preview): preview.hide();preview.queue_free()
 preview=null;inspected=null

func capture_flip(card: Control) -> Control:
 stop_flip(card)
 close_inspection(card)
 host._hide_term()
 if reduced(): return null
 align_layout()
 return copy_at(card)

func copy_at(card: Control) -> Control:
 var ghost=card.preview_factory.call(self,card.size.y)
 var transform=get_global_transform().affine_inverse()*card.get_global_transform()
 ghost.pivot_offset=card.size/2
 ghost.rotation=transform.get_rotation();ghost.scale=transform.get_scale()
 ghost.position=transform.origin-ghost.pivot_offset+transform.basis_xform(ghost.pivot_offset)
 ghost.modulate=card.modulate
 return ghost

func flip(card: Control, old_face: Control) -> void:
 if old_face==null: return
 var next_face=copy_at(card)
 old_face.name="CardFlipOld";next_face.name="CardFlipNew"
 var width=next_face.scale.x
 next_face.scale.x=0.025*width;next_face.hide()
 var alpha=card.modulate.a;card.modulate.a=0
 var motion=create_tween()
 flips[card]={"old":old_face,"next":next_face,"tween":motion,"alpha":alpha}
 motion.tween_property(old_face,"scale:x",width*0.025,0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
 motion.tween_callback(func():old_face.hide();next_face.show())
 motion.tween_property(next_face,"scale:x",width,0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 motion.tween_callback(func():finish_flip(card))
 set_process(true)

func finish_flip(card: Control) -> void:
 stop_flip(card)
 var hovered=get_viewport().gui_get_hovered_control()
 if is_instance_valid(card) and hovered!=null and (hovered==card or card.is_ancestor_of(hovered)):
  card.mouse_entered.emit()

func stop_flip(card) -> void:
 if not flips.has(card): return
 var entry=flips[card];flips.erase(card)
 if entry.tween.is_valid(): entry.tween.kill()
 if is_instance_valid(card): card.modulate.a=entry.alpha
 for ghost in [entry.old,entry.next]:
  if is_instance_valid(ghost): ghost.hide();ghost.queue_free()

func begin_drag(data: Dictionary, has_target: bool) -> void:
 clear()
 if not data.has("card_uid") or not host.card_buttons.has(data.card_uid): return
 host.interaction_audio.request("card_pickup")
 drag=data.duplicate(true);targeting=has_target;elapsed=0;align_layout()
 var source=host.card_buttons[data.card_uid]
 origin=get_global_transform().affine_inverse()*source.get_global_rect().get_center()
 drag_source=source;drag_alpha=source.modulate.a;source.modulate.a=0
 for card in host.card_buttons.values():
  hand_positions[card]=card.position
  if is_instance_valid(card.tween): card.tween.kill()
  if not reduced(): card.position.y=card.home.y+18
 set_process(true)

func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion: pointer=event.position

func clear() -> void:
 close_inspection()
 for card in flips.keys(): stop_flip(card)
 if is_instance_valid(drag_source): drag_source.modulate.a=drag_alpha
 drag_source=null
 for card in hand_positions:
  if is_instance_valid(card): card._hover(false)
 hand_positions.clear();drag={};accepted=false
 queue_redraw();set_process(false)

func _process(delta: float) -> void:
 align_layout()
 for card in flips.keys():
  if not is_instance_valid(card) or not card.is_inside_tree() or not card.is_visible_in_tree(): stop_flip(card)
 if is_instance_valid(inspected):
  if not inspected.is_inside_tree() or not inspected.is_visible_in_tree(): close_inspection()
 elif preview!=null: close_inspection()
 if not drag.is_empty():
  if host.view.version!=drag.version or not get_viewport().gui_is_dragging():
   clear();return
  elapsed+=delta;endpoint=get_global_transform().affine_inverse()*pointer;accepted=false
  var target=get_viewport().gui_get_hovered_control()
  while target!=null:
   if target.get_script()==preload("res://ui/drop_target.gd"):
    accepted=target.drop_accepted and target.checked_drag==drag
    if accepted: endpoint=get_global_transform().affine_inverse()*target.get_global_rect().get_center()
    break
   target=target.get_parent()
  queue_redraw()
 if drag.is_empty() and flips.is_empty() and preview==null: set_process(false)

func _draw() -> void:
 if drag.is_empty(): return
 var color=Color("87ddd8") if accepted else Color("b1a998")
 # Keep input targets stationary. Only the pointer decoration snaps to them.
 if targeting:
  var curve=PackedVector2Array()
  var bend=(origin+endpoint)/2+Vector2(0,-minf(130,origin.distance_to(endpoint)*0.3))
  for step in range(25):
   var weight=float(step)/24
   curve.append(origin.lerp(bend,weight).lerp(bend.lerp(endpoint,weight),weight))
  draw_polyline(curve,color,3,true)
  var radius=20.0 if reduced() else 19.0+4*sin(elapsed*6)
  draw_arc(endpoint,radius,0,TAU,40,color,2,true)
  if accepted: draw_circle(endpoint,4,color)

func _exit_tree() -> void:
 clear()
