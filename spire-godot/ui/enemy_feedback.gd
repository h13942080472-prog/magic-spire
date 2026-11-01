extends Control

# Presentation only: game state was committed atomically before this node exists.
var ui
var queue: Array=[]
var duration=0.8
var index=-1
var elapsed=0.0
var current={}
var heading: Label
var highlights: Array[Rect2]=[]
var actor: Control
var origin=Vector2.ZERO
var closing=false

func _ready() -> void:
 z_index=250
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 var panel=PanelContainer.new()
 panel.name="EnemyActionBanner"
 panel.position=Vector2(800,118);panel.size=Vector2(380,42)
 var style=StyleBoxFlat.new();style.bg_color=Color(0.05,0.075,0.10,0.93)
 style.border_color=Color("bc9663");style.border_width_bottom=2;style.set_corner_radius_all(4)
 style.content_margin_left=14;style.content_margin_right=14
 style.content_margin_top=6;style.content_margin_bottom=6
 panel.add_theme_stylebox_override("panel",style);add_child(panel)
 heading=ui._label("",20,ui.GOLD);heading.name="EnemyActionTitle"
 heading.autowrap_mode=TextServer.AUTOWRAP_OFF;heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 panel.add_child(heading)
 var skip=ui._button("跳过展示",finish,ui.CYAN)
 skip.name="SkipEnemyFeedback";skip.position=Vector2(1320,525);skip.size=Vector2(200,40);add_child(skip)
 _next()

func _next() -> void:
 _restore_actor()
 index+=1;elapsed=0;highlights.clear()
 if index>=queue.size():
  closing=true;current={}
  heading.text="轮到你行动" if ui.view.phase=="battle" else {"reward":"选择战斗奖励","prepare":"进入战后整备","captured":"进入监狱","prison_end":"本次试炼结束"}.get(ui.view.phase,"敌方行动结束")
  if ui.view.pressure.overloaded: heading.text="高潮 · 先缓过这一回合"
  heading.text=ui.localization.display(heading.text)
  if is_instance_valid(ui.battle_feed): ui.battle_feed.release_remaining()
  queue_redraw();return
 current=queue[index]
 ui.equipment_audio.consume(current.get("sound_feedback",[]))
 heading.text=ui.localization.display(current.actor)+" · "+ui.localization.display(current.title)
 if is_instance_valid(ui.battle_feed): ui.battle_feed.release_step(current.key)
 var id=current.enemy_id
 if ui.actor_targets.has(id): highlights.append(ui.actor_targets[id].get_global_rect().grow(8))
 if current.kind in ["apply","install","assembly","tighten","lock","capture"]:
  if ui.actor_targets.has("hero"): highlights.append(ui.actor_targets.hero.get_global_rect().grow(4))
  for slot in current.slots:
   if ui.body_buttons.has(slot): highlights.append(ui.body_buttons[slot].get_global_rect().grow(3))
 actor=ui.layout.find_child("EnemyArt_"+id,true,false) as Control
 if is_instance_valid(actor): origin=actor.position
 queue_redraw()

func _process(delta: float) -> void:
 elapsed+=delta
 if is_instance_valid(actor):
  var offset=sin(clampf(elapsed/maxf(duration,0.01),0,1)*PI)
  actor.position=origin+Vector2(-18*offset,0)
 queue_redraw()
 if elapsed>=duration*(0.55 if closing else 1.0):
  if closing: finish()
  else: _next()

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color(0.01,0.02,0.04,0.1))
 var color=Color("e9bc77") if current.get("kind","") not in ["charge","unseen"] else Color("91dfd2")
 color.a=0.55+0.3*sin(elapsed*9)
 for rect in highlights: draw_rect(rect,color,false,3,true)
 if highlights.size()>1 and current.get("kind","") in ["apply","install","assembly","tighten","lock","capture"]:
  var a=highlights[0].get_center();var b=highlights[1].get_center()
  var t=clampf(elapsed/maxf(duration*0.55,0.01),0,1)
  draw_line(a,a.lerp(b,t),Color(color,0.5),3,true)
  draw_circle(a.lerp(b,t),6,color,true,-1,true)

func _restore_actor() -> void:
 if is_instance_valid(actor): actor.position=origin
 actor=null

func finish() -> void:
 set_process(false)
 _restore_actor()
 if is_instance_valid(ui.battle_feed): ui.battle_feed.release_remaining()
 if ui.enemy_feedback==self: ui.enemy_feedback=null
 hide();queue_free()
