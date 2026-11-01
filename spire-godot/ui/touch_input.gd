extends Node

# Translate one finger into the existing GUI mouse routes. No game-state writes.
const HOLD_SECONDS=0.5
const MOVE_THRESHOLD=12.0
const CARD_SWIPE_DISTANCE=42.0
var host
var finger=-1
var origin=Vector2.ZERO
var point=Vector2.ZERO
var elapsed=0.0
var held=false
var dragging=false
var scrolling: ScrollContainer
var pressed_control: WeakRef
var details_allowed=false
var popup_context=false
var active_popup: WeakRef
var pressed_card: WeakRef
var card_swiping=false
var press_version=-1

func card_at(control: Node) -> Control:
 var node=control
 while node!=null:
  if node.get_script()==preload("res://ui/card_face.gd"): return node
  node=node.get_parent()
 return null

func _ready() -> void:
 Input.emulate_mouse_from_touch=false
 popup_context=get_viewport() is PopupMenu
 if popup_context:
  get_viewport().popup_hide.connect(cancel)
 else:
  get_tree().node_added.connect(_popup_added)
  _scan_popups(host)

func _scan_popups(node: Node) -> void:
 if node is PopupMenu: _popup_added(node)
 for child in node.get_children(true): _scan_popups(child)

func _popup_added(node: Node) -> void:
 if node is PopupMenu: _attach_popup.call_deferred(weakref(node))

func _attach_popup(reference: WeakRef) -> void:
 var popup=reference.get_ref()
 if not is_instance_valid(popup) or not host.is_ancestor_of(popup) or popup.has_node("TouchInput"): return
 # A PopupMenu owns a separate viewport. Root-window input does not reach it.
 var bridge=get_script().new();bridge.name="TouchInput";bridge.host=host
 popup.add_child(bridge)
 popup.about_to_popup.connect(func():active_popup=reference)

func dismiss_popup() -> bool:
 var popup=active_popup.get_ref() if active_popup!=null else null
 if not is_instance_valid(popup) or not popup.visible: return false
 popup.hide()
 return true

func _popup_scroller(node: Node) -> ScrollContainer:
 for child in node.get_children(true):
  if child is ScrollContainer: return child
  var result=_popup_scroller(child)
  if result!=null: return result
 return null

func _input(event: InputEvent) -> void:
 if host._takeover_locked():
  get_viewport().set_input_as_handled();cancel();return
 if not popup_context and (event is InputEventScreenTouch or event is InputEventScreenDrag) and host.handle_portrait_input(event):
  get_viewport().set_input_as_handled();cancel();return
 if event is InputEventScreenTouch:
  get_viewport().set_input_as_handled()
  if event.pressed:
   if finger!=-1: return
   finger=event.index;origin=event.position;point=origin;elapsed=0;held=false;dragging=false;card_swiping=false
   press_version=host.view.get("version",-1)
   details_allowed=false;host._hide_term();host._dismiss_speech()
   motion(point)
   var control=get_viewport().gui_get_hovered_control()
   pressed_control=weakref(control) if control!=null else null
   var card=card_at(control)
   pressed_card=weakref(card) if card!=null else null
   scrolling=null
   var parent=control
   while parent!=null:
    if parent is ScrollContainer:
     scrolling=parent;break
    parent=parent.get_parent()
   if card!=null and not card.drag_payload.is_empty(): scrolling=null
   elif control!=null and "drag_payload" in control and not control.drag_payload.is_empty(): scrolling=null
   if popup_context and scrolling==null: scrolling=_popup_scroller(get_viewport())
  elif event.index==finger:
   if event.canceled: cancel()
   else: release(event.position)
 elif event is InputEventScreenDrag:
  get_viewport().set_input_as_handled()
  if event.index!=finger: return
  var previous=point;point=event.position
  if card_swiping: return
  if held:
   motion(point,point-previous,0 if pressed_card!=null else MOUSE_BUTTON_MASK_RIGHT)
  elif dragging:
   move_drag(previous)
  elif point.distance_to(origin)>MOVE_THRESHOLD:
   var displacement=point-origin
   if pressed_card!=null and displacement.y>absf(displacement.x)*1.25:
    card_swiping=true;return
   dragging=true
   if not popup_context and not is_instance_valid(scrolling):
    motion(origin);button(origin,MOUSE_BUTTON_LEFT,true)
   move_drag(previous)

func _process(delta: float) -> void:
 if popup_context: return
 if finger<0 or held or dragging or card_swiping: return
 elapsed+=delta
 if elapsed<HOLD_SECONDS: return
 var control=pressed_control.get_ref() if pressed_control!=null else null
 if not is_instance_valid(control) or not control.is_visible_in_tree():
  cancel();return
 held=true;details_allowed=true
 motion(point)
 if pressed_card==null: button(point,MOUSE_BUTTON_RIGHT,true)
 show_details.call_deferred()

func show_details() -> void:
 if not held: return
 motion(point+Vector2(0.01,0))
 var control=get_viewport().gui_get_hovered_control()
 if control==null: return
 var parent=control
 while parent!=null:
  if parent.get_script()==preload("res://ui/card_face.gd"):
   control=parent;break
  parent=parent.get_parent()
 control.mouse_entered.emit()
 if not is_instance_valid(host.term_popup) and control.tooltip_text!="":
  host._show_term(control,{"label":"","detail":control.tooltip_text})

func move_drag(previous: Vector2) -> void:
 if is_instance_valid(scrolling):
  scrolling.scroll_vertical-=roundi(point.y-previous.y)
  scrolling.scroll_horizontal-=roundi(point.x-previous.x)
 else:
  motion(point,point-previous,MOUSE_BUTTON_MASK_LEFT)

func release(position: Vector2) -> void:
 if card_swiping:
  var card=pressed_card.get_ref() if pressed_card!=null else null
  var displacement=position-origin
  var distance=CARD_SWIPE_DISTANCE*host.layout.scale.y
  if is_instance_valid(card) and card.is_visible_in_tree() and host.view.get("version",-1)==press_version and displacement.y>=distance and displacement.y>absf(displacement.x)*1.25:
   var center=card.get_global_rect().get_center()
   motion(center);button(center,MOUSE_BUTTON_RIGHT,true);button(center,MOUSE_BUTTON_RIGHT,false)
 elif held:
  if pressed_card==null: button(position,MOUSE_BUTTON_RIGHT,false)
 elif dragging:
  if not popup_context and not is_instance_valid(scrolling): button(position,MOUSE_BUTTON_LEFT,false)
 else:
  var control=pressed_control.get_ref() if pressed_control!=null else null
  if (popup_context and get_viewport().visible) or (is_instance_valid(control) and control.is_visible_in_tree()):
   motion(position);button(position,MOUSE_BUTTON_LEFT,true)
   var opened=active_popup.get_ref() if active_popup!=null else null
   # A tall menu can overlap its opener. The opening tap must not select a row.
   if popup_context or not is_instance_valid(opened) or not opened.visible:
    button(position,MOUSE_BUTTON_LEFT,false)
 finger=-1;held=false;dragging=false;scrolling=null;pressed_control=null;pressed_card=null;card_swiping=false

func cancel() -> void:
 if finger<0: return
 motion(Vector2(-1000,-1000))
 if held and pressed_card==null: button(Vector2(-1000,-1000),MOUSE_BUTTON_RIGHT,false)
 elif dragging and not popup_context and not is_instance_valid(scrolling): button(Vector2(-1000,-1000),MOUSE_BUTTON_LEFT,false)
 finger=-1;held=false;dragging=false;scrolling=null;pressed_control=null;details_allowed=false;pressed_card=null;card_swiping=false
 host._hide_term()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: cancel()

func motion(position: Vector2, relative: Vector2=Vector2.ZERO, mask: int=0) -> void:
 var event=InputEventMouseMotion.new()
 event.position=position;event.global_position=position;event.relative=relative;event.button_mask=mask
 dispatch_mouse(event)

func button(position: Vector2, index: int, down: bool) -> void:
 var event=InputEventMouseButton.new()
 event.position=position;event.global_position=position;event.button_index=index;event.pressed=down
 event.button_mask=(MOUSE_BUTTON_MASK_LEFT if index==MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT) if down else 0
 dispatch_mouse(event)

func dispatch_mouse(event: InputEventMouse) -> void:
 var viewport=get_viewport()
 if popup_context:
  # PopupMenu handles selection at the Window input boundary, before push_input.
  # Route through its embedding viewport so Godot enters that native boundary.
  if viewport.is_embedded():
   event.position+=Vector2(viewport.position);event.global_position=event.position
   viewport.get_parent().get_viewport().push_input(event,true)
  else:
   event.window_id=viewport.get_window_id()
   Input.parse_input_event(event)
 else:
  viewport.push_input(event,true)
