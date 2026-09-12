extends Control
var kind="wait"
var highlighted=false
const GOLD=Color("e8c47b")
const CYAN=Color("8cdbdc")

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_STOP
 mouse_default_cursor_shape=Control.CURSOR_HELP
 focus_mode=Control.FOCUS_ALL
 mouse_entered.connect(func():highlighted=true;queue_redraw())
 mouse_exited.connect(func():highlighted=false;queue_redraw())

func set_ui_state(state: String) -> void:
 highlighted=state=="hover" or state=="pressed"
 queue_redraw()

func line(points: Array, color: Color=GOLD) -> void:
 draw_polyline(PackedVector2Array(points),color,3,true)

func _draw() -> void:
 draw_circle(Vector2(27,25),23,Color(0.04,0.06,0.1,0.9))
 if highlighted: draw_arc(Vector2(27,25),24,0,TAU,48,CYAN,2,true)
 match kind:
  "debuff":
   var spiral=PackedVector2Array()
   for i in range(65):
    var angle=float(i)/64*TAU*1.65
    spiral.append(Vector2(27,25)+Vector2(cos(angle),sin(angle))*(2.0+float(i)/64*13))
   draw_polyline(spiral,Color("d9a5f3"),3,true)
   for center in [Vector2(9,9),Vector2(45,9),Vector2(45,42)]:
    line([center-Vector2(4,0),center+Vector2(4,0)])
    line([center-Vector2(0,4),center+Vector2(0,4)])
  "bind":
   draw_arc(Vector2(20,23),10,0,TAU,32,GOLD,3,true)
   draw_arc(Vector2(34,23),10,0,TAU,32,GOLD,3,true)
   line([Vector2(24,31),Vector2(17,42)])
   line([Vector2(30,31),Vector2(38,42)])
  "tighten":
   line([Vector2(6,25),Vector2(21,25),Vector2(15,18)])
   line([Vector2(21,25),Vector2(15,32)])
   line([Vector2(48,25),Vector2(33,25),Vector2(39,18)])
   line([Vector2(33,25),Vector2(39,32)])
  "lock":
   draw_arc(Vector2(27,20),9,PI,TAU,20,GOLD,3,true)
   draw_rect(Rect2(14,21,26,21),GOLD,false,3)
   draw_circle(Vector2(27,30),3,GOLD)
  "wait":
   for x in [14,27,40]: draw_circle(Vector2(x,25),3,CYAN)
  "capture":
   draw_rect(Rect2(12,10,30,31),GOLD,false,3)
   for x in [22,32]: line([Vector2(x,10),Vector2(x,41)])
  "leave":
   line([Vector2(23,10),Vector2(12,10),Vector2(12,40),Vector2(23,40)])
   line([Vector2(22,25),Vector2(44,25),Vector2(35,16)],CYAN)
   line([Vector2(44,25),Vector2(35,34)],CYAN)
  "delayed":
   line([Vector2(20,12),Vector2(20,38)],CYAN)
   line([Vector2(34,12),Vector2(34,38)],CYAN)
  "hidden":
   draw_arc(Vector2(27,19),9,PI,TAU+PI/2,24,CYAN,3,true)
   line([Vector2(27,28),Vector2(27,32)],CYAN)
   draw_circle(Vector2(27,39),2,CYAN)
