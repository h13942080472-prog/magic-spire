extends Control
# Presentation clock is independent from the already committed game state.
var host
var pending=[]
var shown={}
var active={}
var elapsed=0.0
var duration=1.15
var anchor=Vector2(560,250)
var floating: Label

func _ready() -> void:
 name="ResourceFeedback";mouse_filter=Control.MOUSE_FILTER_IGNORE;z_index=270

func enqueue(events: Array, point: Vector2, instant_fields: Array=[]) -> void:
 anchor=point
 # Keep earlier action/relic floats, but stop them replaying an outdated balance.
 for field in instant_fields: shown.erase(field)
 for event in pending+[active]:
  if instant_fields.has(event.get("field","")): event.interpolate=false
 for event in events:
  if instant_fields.has(event.field): continue
  pending.append(event.duplicate(true))
  if event.field!="" and not shown.has(event.field): shown[event.field]=float(event.before)
 update_numbers()

func _process(delta: float) -> void:
 if host.show_home:
  queue_free()
  return
 if active.is_empty() and not pending.is_empty(): start_next()
 if not active.is_empty():
  elapsed=minf(duration,elapsed+delta)
  var progress=elapsed/duration
  if active.field!="" and active.get("interpolate",true): shown[active.field]=lerpf(float(active.before),float(active.after),smoothstep(0.0,1.0,progress))
  floating.position.y=anchor.y-20-65*progress
  floating.modulate.a=1.0-clampf((progress-0.72)/0.28,0.0,1.0)
  if elapsed>=duration:
   floating.queue_free();floating=null;active={}
   if pending.is_empty(): shown.clear()
 update_numbers()

func start_next() -> void:
 active=pending.pop_front();elapsed=0.0
 floating=Label.new();floating.name="ResourceFloat"
 floating.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var text=active.label+"触发"
 var color=host.GOLD
 if active.field!="":
  var difference=float(active.after)-float(active.before)
  text=active.label+(" +" if difference>0 else " −")+str(snappedf(absf(difference),0.01)).trim_suffix(".0")
  if active.source!="": text=active.source+"\n"+text
  color=host.CYAN if difference>0 else Color("f0b68f")
 floating.text=text;floating.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 floating.add_theme_font_size_override("font_size",26)
 floating.add_theme_color_override("font_color",color)
 floating.add_theme_color_override("font_outline_color",Color("101723"))
 floating.add_theme_constant_override("outline_size",6)
 floating.position=Vector2(clampf(anchor.x-180,15,1220),anchor.y-20);floating.size.x=360
 add_child(floating)
 if active.source!="":
  var relic=host.find_child("RelicRow",true,false)
  if relic!=null:
   relic.modulate=Color("ffdc83")
   relic.create_tween().tween_property(relic,"modulate",Color.WHITE,0.8)

func update_numbers() -> void:
 if host==null or not is_instance_valid(host.layout): return
 var mana=shown.get("mana",host.view.mana)
 var flask=host.layout.find_child("FlaskManaValue",true,false)
 if flask!=null: flask.text=host.game.number(host.view.mana_flask.mana)
 for id in ["MainMana","HeroMana"]:
  var bar=host.layout.find_child(id,true,false)
  var label=host.layout.find_child(id+"Value",true,false)
  if bar!=null: bar.value=mana
  if label!=null:
   label.text="%s/%s" % [host.game.number(host.view.mana),host.game.number(host.view.mana_max)]
   var temporary=host.view.temporary_mana
   if temporary>0: label.text+=" · 临时"+host.game.number(snappedf(temporary,0.1))
