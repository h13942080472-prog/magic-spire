extends Control

var origin=Vector2.ZERO
var target=Vector2.ZERO
var progress=0.0
var reduced=false

func play(from: Vector2, to: Vector2, reduced_motion: bool) -> void:
 origin=from;target=to;reduced=reduced_motion
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 z_index=190
 var tween=create_tween()
 tween.tween_method(_advance,0.0,1.0,0.35 if reduced else 0.9)
 tween.tween_callback(queue_free)

func _advance(value: float) -> void:
 progress=value
 queue_redraw()

func _draw() -> void:
 var ink=Color("344656")
 var silver=Color("d5e5ed")
 var blue=Color("86d7dc")
 var reach=1.0 if reduced else ease(clampf(progress/0.34,0,1),0.65)
 if not reduced and progress<0.62:
  var tip=origin.lerp(target,reach)
  var trail=origin.lerp(target,clampf((progress-0.34)/0.28,0,1))
  draw_line(trail,tip,ink,5,true)
  draw_line(trail,tip,silver,2,true)
  draw_circle(tip,4,blue,true,-1,true)
 if reach<1: return
 var cinch=1.0 if reduced else smoothstep(0.34,0.69,progress)
 var alpha=1.0-smoothstep(0.72,1.0,progress)
 for band in [-1.0,1.0]:
  var points=PackedVector2Array()
  for step in range(41):
   var angle=TAU*step/40
   var x=cos(angle)*lerpf(69,38,cinch)
   points.append(target+Vector2(x,sin(angle)*10+band*(10+x*0.19)))
  draw_polyline(points,Color(ink,alpha),5,true)
  draw_polyline(points,Color(silver,alpha),2.5,true)
 draw_circle(target+Vector2(0,9),4,Color(blue,alpha),true,-1,true)
