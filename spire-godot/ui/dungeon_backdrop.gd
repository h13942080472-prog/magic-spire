extends Control

const Art=preload("res://ui/pixel_art.gd")
var rest=false

class Dust extends Control:
 var clock=0.0
 var pending=0.0

 func _process(delta: float) -> void:
  clock+=delta;pending+=delta
  if pending<1.0/30.0: return
  pending=fmod(pending,1.0/30.0)
  queue_redraw()

 func _draw() -> void:
  for i in range(16):
   var point=Vector2(400+fmod(i*173.0+clock*3,1160),160+fmod(i*71.0-clock*4+10000,245))
   draw_circle(point,1.2,Color(0.89,0.83,1.0,0.12+sin(clock+i)*0.06),true,-1,true)

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 var dust=Dust.new();dust.name="AmbientDust"
 dust.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(dust)

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("10101b"))
 # Align the painted floor with the actors, leaving the lower region quiet for cards.
 draw_texture_rect(Art.BACKGROUND,Rect2(0,-100,1600,900),false,Color(0.48,0.59,0.70))
 draw_rect(Rect2(0,0,1600,900),Color(0.025,0.065,0.11,0.16))
 # Quiet borders frame the stage while preserving the original background art.
 draw_rect(Rect2(0,62,376,838),preload("res://ui/visual_theme.gd").HUD)
 draw_line(Vector2(375,62),Vector2(375,900),Color("383b43"),1)
 for i in range(24):
  draw_rect(Rect2(376,475+i*14,1224,14),Color(0.035,0.038,0.05,minf(0.98,float(i)/13.0)))
