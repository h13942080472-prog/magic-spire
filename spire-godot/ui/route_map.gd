extends Control


signal room_selected(id: String)
var rooms: Array=[]
var selected=""
var hovered=""
var buttons={}
var compact=false
var region_name="塔路"
var press_origin=Vector2.ZERO
var press_scroll=0
var pointer_down=false
var panning=false
# UI-only marks use graph coordinates, so scrolling/overview never displace routes.
var strokes: Array=[]
var drawing=false
var active_stroke=-1
const PENCIL=Color("933e46")

func clear_strokes() -> void:
 strokes.clear();drawing=false;active_stroke=-1;queue_redraw()

func ink_position(point: Vector2) -> Vector2:
 var padding=32.0 if compact else 95.0
 return Vector2(115.0+point.x*(size.x-230.0),padding+point.y*(size.y-padding*2.0))

func _mark(pointer: Vector2) -> void:
 var local=get_global_transform().affine_inverse()*pointer
 var padding=32.0 if compact else 95.0
 var point=Vector2((local.x-115.0)/(size.x-230.0),(local.y-padding)/(size.y-padding*2.0))
 if active_stroke<0:
  strokes.append(PackedVector2Array([point]));active_stroke=strokes.size()-1
 else:
  var line: PackedVector2Array=strokes[active_stroke]
  if ink_position(line[line.size()-1]).distance_to(local)<2.0: return
  line.append(point);strokes[active_stroke]=line
 queue_redraw()

func _over_map() -> bool:
 var control=get_viewport().gui_get_hovered_control()
 return control==self or (control!=null and is_ancestor_of(control))

func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT or (what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree()):
  drawing=false;active_stroke=-1;pointer_down=false;panning=false

func _input(event: InputEvent) -> void:
 var scroll=get_parent() as ScrollContainer
 if scroll==null or not is_visible_in_tree(): return
 if not event is InputEventMouse: return
 var pointer=get_canvas_transform().affine_inverse()*event.position
 var area=scroll.get_global_rect()
 area.size.x-=scroll.get_v_scroll_bar().size.x
 var on_map=area.has_point(pointer) and _over_map()
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
  if event.pressed:
   drawing=on_map;active_stroke=-1
   if drawing:
    pointer_down=false;panning=false
    for button in buttons.values(): button.set_pressed_no_signal(false)
    _mark(pointer);get_viewport().set_input_as_handled()
  elif drawing:
   if on_map: _mark(pointer)
   drawing=false;active_stroke=-1;get_viewport().set_input_as_handled()
  return
 if drawing:
  if event is InputEventMouseMotion:
   if on_map: _mark(pointer)
   else: active_stroke=-1
  if on_map or event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
   get_viewport().set_input_as_handled()
  return
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed:
   pointer_down=area.has_point(pointer)
   panning=false
   press_origin=pointer;press_scroll=scroll.scroll_vertical
  elif pointer_down:
   pointer_down=false
   if panning:
    for button in buttons.values(): button.set_pressed_no_signal(false)
    get_viewport().set_input_as_handled()
   panning=false
 elif event is InputEventMouseMotion and pointer_down:
  if pointer.distance_to(press_origin)>8: panning=true
  if panning:
   scroll.scroll_vertical=press_scroll-int(pointer.y-press_origin.y)
   get_viewport().set_input_as_handled()
# Original generated assets; color modulation darkens only the paper, not the icons.
const PAPER_TEXTURE=preload("res://assets/art/map-parts-v2/paper-base.png")
const LEFT_TOWER=preload("res://assets/art/map-parts-v2/tower-left.png")
const RIGHT_ARCADE=preload("res://assets/art/map-parts-v2/arcade-right.png")
const CURRENT_MARKER=preload("res://assets/art/map-parts-v2/current-marker.png")
const AVAILABLE_RING=preload("res://assets/art/map-parts-v2/available-ring.png")
const COMPLETED_CHECK=preload("res://assets/art/map-parts-v2/completed-check.png")
const ICONS={
 "battle":preload("res://assets/art/map-icons-v1/battle.png"),
 "elite":preload("res://assets/art/map-icons-v1/elite.png"),
 "boss":preload("res://assets/art/map-icons-v1/boss.png"),
 "event":preload("res://assets/art/map-icons-v1/event.png"),
 "shop":preload("res://assets/art/map-icons-v1/shop.png"),
 "treasure":preload("res://assets/art/map-icons-v1/treasure.png"),
 "rest":preload("res://assets/art/map-icons-v1/rest.png"),
 "entry":preload("res://assets/art/map-parts-v2/entrance.png"),
 "exit":preload("res://assets/art/map-icons-v1/exit.png")}
const PAPER_TINT=Color(0.78,0.78,0.78,1.0)
const INK=Color("26303e")
const FADED=Color("656362")
const ACTIVE=Color("29646c")
const GOLD=Color("81612e")

const STATUS={"completed":"已走过","current":"当前","available":"可前往","destination":"正在前往","skipped":"未选择","ahead":"未到达"}

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_PASS
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 var scroll=get_parent() as ScrollContainer
 if scroll!=null: scroll.get_v_scroll_bar().value_changed.connect(func(_value): active_stroke=-1;queue_redraw())
 for room in rooms:
  var button=preload("res://ui/elements/route_node.tscn").instantiate()
  button.name="RouteNode_"+room.id
  for style in ["normal","hover","pressed","focus","disabled"]: button.add_theme_stylebox_override(style,StyleBoxEmpty.new())
  if room.status=="available":
   button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
   button.pressed.connect(func():room_selected.emit(room.id))
   button.mouse_entered.connect(func():hovered=room.id; queue_redraw())
   button.mouse_exited.connect(func():hovered=""; queue_redraw())
   button.focus_entered.connect(func():hovered=room.id; queue_redraw())
   button.focus_exited.connect(func():hovered=""; queue_redraw())
  else:
   # Godot still emits mouse_entered on a disabled button, so illegal rooms drop the highlight wiring entirely.
   button.disabled=true
   button.mouse_default_cursor_shape=Control.CURSOR_ARROW
  add_child(button); buttons[room.id]=button
 resized.connect(_layout_nodes)
 _layout_nodes()

func point_for(room: Dictionary) -> Vector2:
 var last=1
 var first=0
 for r in rooms:
  last=maxi(last,r.floor); first=mini(first,r.floor)
 var padding=32 if compact else 95
 return Vector2(115+(size.x-230)*room.lane,size.y-padding-(size.y-padding*2)*float(room.floor-first)/(last-first))

func _layout_nodes() -> void:
 for room in rooms:
  var button=buttons[room.id]
  var width=minf(56.0 if compact else 128.0,(size.x-230)/6.0-4.0)
  button.position=point_for(room)-Vector2(width/2,15 if compact else 38)
  button.size=Vector2(width,30 if compact else 98)
 queue_redraw()

func _path(a: Vector2,b: Vector2,color: Color,solid: bool) -> void:
 var delta=b-a
 var radius=13 if compact else 35
 var start=a+delta.normalized()*radius
 var end=b-delta.normalized()*radius
 var count=maxi(1,int(start.distance_to(end)/8))
 var bend=Vector2(12 if a.x<b.x else -12,0)
 var previous=start
 for i in range(1,count+1):
  var t=float(i)/count
  var point=start.lerp(end,t)+bend*sin(t*PI)
  if solid or i%3!=0: draw_line(previous,point,color,3 if solid else 1.6,true)
  previous=point

func _icon(point: Vector2,kind: String,opacity: float=1.0) -> void:
 var key="battle" if kind in ["weak","strong"] else kind
 var extent=30.0 if compact else 64.0
 draw_texture_rect(ICONS[key],Rect2(point-Vector2.ONE*extent/2,Vector2.ONE*extent),false,Color(1,1,1,opacity))

func _background() -> void:
 # Keep the paper and side art at viewport proportions while only the graph scrolls.
 var scroll=get_parent() as ScrollContainer
 var visible=Rect2(Vector2.ZERO,size)
 if scroll!=null:
  visible=Rect2(Vector2(0,scroll.scroll_vertical),Vector2(size.x,minf(size.y,scroll.size.y)))
 var scale=maxf(visible.size.x/PAPER_TEXTURE.get_width(),visible.size.y/PAPER_TEXTURE.get_height())
 var source_size=visible.size/scale
 var source=Rect2((PAPER_TEXTURE.get_size()-source_size)/2,source_size)
 draw_texture_rect_region(PAPER_TEXTURE,visible,source,PAPER_TINT)
 var art_height=visible.size.y*0.94
 var art_size=Vector2(art_height*2.0/3.0,art_height)
 draw_texture_rect(LEFT_TOWER,Rect2(Vector2(-art_size.x*0.32,visible.end.y-art_height),art_size),false,Color(1,1,1,0.23))
 var right_size=art_size*0.8
 draw_texture_rect(RIGHT_ARCADE,Rect2(Vector2(size.x-right_size.x*0.57,visible.end.y-right_size.y),right_size),false,Color(1,1,1,0.18))
 draw_rect(visible.grow(-8),Color("8d7957"),false,1)

func _draw() -> void:
 _background()
 var points={}
 for room in rooms: points[room.id]=point_for(room)
 for room in rooms:
  for path in room.paths:
   var chosen=path.status in ["travelled","travelling"]
   var color=GOLD if chosen else (ACTIVE if path.status=="available" else Color(FADED,0.65))
   if hovered==path.to and path.status=="available": color=ACTIVE
   _path(points[room.id],points[path.to],color,chosen)
 var font=get_theme_default_font()
 var drawn_floors=[]
 for room in rooms:
  if drawn_floors.has(room.floor): continue
  drawn_floors.append(room.floor)
  var y=points[room.id].y
  draw_string(font,Vector2(20,y+5),("塔底" if room.floor<0 else "%02d" % [room.floor+1]),HORIZONTAL_ALIGNMENT_LEFT,-1,14,FADED)
 for room in rooms:
  var point=points[room.id]
  var opacity=0.42 if room.status=="skipped" else 1.0
  var color=FADED if room.status=="skipped" else INK
  var marker_size=42.0 if compact else 98.0
  if room.current:
   draw_texture_rect(CURRENT_MARKER,Rect2(point-Vector2.ONE*marker_size/2,Vector2.ONE*marker_size),false)
  elif room.status in ["available","destination"]:
   var extent=35.0 if compact else 82.0
   draw_texture_rect(AVAILABLE_RING,Rect2(point-Vector2.ONE*extent/2,Vector2.ONE*extent),false)
  if room.status=="available" and (selected==room.id or hovered==room.id):
   draw_arc(point,18 if compact else 39,0,TAU,48,ACTIVE,1.5,true)
  _icon(point,room.icon,opacity)
  if room.status=="completed":
   var extent=16.0 if compact else 26.0
   draw_texture_rect(COMPLETED_CHECK,Rect2(point+Vector2(9,5) if compact else point+Vector2(20,13),Vector2.ONE*extent),false)
  if compact: continue
  var title={"battle":"战斗","weak":"战斗","strong":"战斗 · 强敌","elite":"精英","boss":"塔顶 · 六缚","event":"事件","rest":"休息","shop":"商店","treasure":"宝箱","entry":"塔底入口","exit":"出口"}[room.icon]
  if region_name=="监狱": title=room.name
  var width=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
  draw_string(font,point+Vector2(-width/2,53),title,HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
  var status="当前所在" if room.current else STATUS[room.status]
  var sw=font.get_string_size(status,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
  var status_color=GOLD if room.current or room.status=="completed" else (ACTIVE if room.status in ["available","destination"] else FADED)
  draw_string(font,point+Vector2(-sw/2,70),status,HORIZONTAL_ALIGNMENT_LEFT,-1,12,status_color)

 # Draw above route artwork; invisible node buttons still own left-click navigation.
 for stroke in strokes:
  if stroke.is_empty(): continue
  var points_on_map=PackedVector2Array()
  for point in stroke: points_on_map.append(ink_position(point))
  if points_on_map.size()>1: draw_polyline(points_on_map,PENCIL,2.5,true)
  draw_circle(points_on_map[0],1.25,PENCIL)
  draw_circle(points_on_map[points_on_map.size()-1],1.25,PENCIL)
