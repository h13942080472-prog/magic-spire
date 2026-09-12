extends Node

# Translate one finger into the existing GUI mouse routes. No game-state writes.
const HOLD_SECONDS=0.5
const MOVE_THRESHOLD=12.0
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

func _ready() -> void:
 Input.emulate_mouse_from_touch=false

func _input(event: InputEvent) -> void:
 if event is InputEventScreenTouch:
  get_viewport().set_input_as_handled()
  if event.pressed:
   if finger!=-1: return
   finger=event.index;origin=event.position;point=origin;elapsed=0;held=false;dragging=false
   details_allowed=false;host._hide_term();host._dismiss_speech()
   motion(point)
   var control=get_viewport().gui_get_hovered_control()
   pressed_control=weakref(control) if control!=null else null
   scrolling=null
   var parent=control
   while parent!=null:
    if parent is ScrollContainer:
     scrolling=parent;break
    parent=parent.get_parent()
   if control!=null and "drag_payload" in control and not control.drag_payload.is_empty(): scrolling=null
  elif event.index==finger:
   if event.canceled: cancel()
   else: release(event.position)
 elif event is InputEventScreenDrag:
  get_viewport().set_input_as_handled()
  if event.index!=finger: return
  var previous=point;point=event.position
  if held:
   motion(point,point-previous,MOUSE_BUTTON_MASK_RIGHT)
  elif dragging:
   move_drag(previous)
  elif point.distance_to(origin)>MOVE_THRESHOLD:
   dragging=true
   if not is_instance_valid(scrolling):
    motion(origin);button(origin,MOUSE_BUTTON_LEFT,true)
   move_drag(previous)

func _process(delta: float) -> void:
 if finger<0 or held or dragging: return
 elapsed+=delta
 if elapsed<HOLD_SECONDS: return
 var control=pressed_control.get_ref() if pressed_control!=null else null
 if not is_instance_valid(control) or not control.is_visible_in_tree():
  cancel();return
 held=true;details_allowed=true
 motion(point);button(point,MOUSE_BUTTON_RIGHT,true)
 show_details.call_deferred()

func show_details() -> void:
 if not held: return
 motion(point+Vector2(0.01,0))
 var control=get_viewport().gui_get_hovered_control()
 if control==null: return
 var parent=control
 while parent!=null:
  if parent.get_script()==preload("res://ui/elements/card_face.gd"):
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
 if held: button(position,MOUSE_BUTTON_RIGHT,false)
 elif dragging:
  if not is_instance_valid(scrolling): button(position,MOUSE_BUTTON_LEFT,false)
 else:
  var control=pressed_control.get_ref() if pressed_control!=null else null
  if is_instance_valid(control) and control.is_visible_in_tree():
   motion(position);button(position,MOUSE_BUTTON_LEFT,true);button(position,MOUSE_BUTTON_LEFT,false)
 finger=-1;held=false;dragging=false;scrolling=null;pressed_control=null

func cancel() -> void:
 if finger<0: return
 motion(Vector2(-1000,-1000))
 if held: button(Vector2(-1000,-1000),MOUSE_BUTTON_RIGHT,false)
 elif dragging and not is_instance_valid(scrolling): button(Vector2(-1000,-1000),MOUSE_BUTTON_LEFT,false)
 finger=-1;held=false;dragging=false;scrolling=null;pressed_control=null;details_allowed=false
 host._hide_term()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: cancel()

func motion(position: Vector2, relative: Vector2=Vector2.ZERO, mask: int=0) -> void:
 var event=InputEventMouseMotion.new()
 event.position=position;event.global_position=position;event.relative=relative;event.button_mask=mask
 get_viewport().push_input(event,true)

func button(position: Vector2, index: int, down: bool) -> void:
 var event=InputEventMouseButton.new()
 event.position=position;event.global_position=position;event.button_index=index;event.pressed=down
 event.button_mask=(MOUSE_BUTTON_MASK_LEFT if index==MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT) if down else 0
 get_viewport().push_input(event,true)
