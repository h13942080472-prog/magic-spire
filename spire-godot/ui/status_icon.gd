extends Control

# Artwork and counters only; the status projection owns all values and lifetimes.
const CardArt=preload("res://ui/elements/card_face.gd")
const KINDS=["info","flame","weakness","bind","stock","shield","charge","ritual","ready","puppet","split","arms","legs","hand","foot","eye","mouth","movement","strength","dexterity","sure_cast","power","mana","energy","pressure","wall","cards"]
var status: Dictionary={}
var ink=Color("d8c18f")
var badge: Label

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 ink=Color("e7a2a7") if status.tone=="bad" else Color("91d6d0") if status.tone=="good" else Color("d8c18f")
 if status.icon=="mana": ink=Color("c5a2ed")
 if status.get("emphasized",false): ink=Color("ffcf65")
 if status.icon=="power" and CardArt.ILLUSTRATIONS.has(status.get("card_type","")):
  var art=TextureRect.new();art.texture=CardArt.ILLUSTRATIONS[status.card_type]
  art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  art.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(art)
  art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  art.offset_left=5;art.offset_top=5;art.offset_right=-5;art.offset_bottom=-5
 if status.badge!="":
  badge=Label.new();badge.name="StatusCount";badge.text=status.badge
  badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
  badge.add_theme_font_size_override("font_size",13);badge.add_theme_color_override("font_color",Color("fff1cd"))
  badge.add_theme_color_override("font_outline_color",Color("09121c"));badge.add_theme_constant_override("outline_size",6)
  add_child(badge)
 resized.connect(_fit);_fit()

func _fit() -> void:
 if is_instance_valid(badge):
  badge.size=badge.get_minimum_size();badge.position=size-badge.size+Vector2(0,2)
 queue_redraw()

func stroke(points: Array, color: Color=Color.TRANSPARENT) -> void:
 draw_polyline(PackedVector2Array(points),ink if color==Color.TRANSPARENT else color,2.6,true)

func _draw() -> void:
 draw_set_transform(Vector2.ZERO,0,size/Vector2(48,48))
 draw_circle(Vector2(24,24),21,Color("111f2a"))
 draw_arc(Vector2(24,24),20,0,TAU,48,ink.darkened(0.55),1.3,true)
 if status.get("emphasized",false): draw_arc(Vector2(24,24),22,0,TAU,48,ink,2.0,true)
 match status.icon:
  "charge","energy":
   var points=PackedVector2Array([Vector2(26,6),Vector2(14,25),Vector2(23,25),Vector2(20,41),Vector2(36,19),Vector2(27,19)])
   draw_colored_polygon(points,ink)
   if status.icon=="charge": draw_arc(Vector2(24,24),16,0.2,2.6,24,ink,2,true)
  "mana","flame":
   var points=PackedVector2Array([Vector2(25,6),Vector2(33,20),Vector2(38,26),Vector2(34,36),Vector2(25,40),Vector2(14,35),Vector2(11,26),Vector2(17,16),Vector2(19,26)])
   draw_colored_polygon(points,ink);draw_circle(Vector2(25,31),5,Color("1c3240"))
  "bind","arms":
   for x in [17,31]: draw_arc(Vector2(x,22),9,0,TAU,32,ink,2.6,true)
   stroke([Vector2(22,28),Vector2(15,38)]);stroke([Vector2(26,28),Vector2(34,38)])
   if status.icon=="arms": stroke([Vector2(11,10),Vector2(37,10)])
  "legs","foot","movement":
   stroke([Vector2(17,10),Vector2(17,27),Vector2(11,36),Vector2(24,36)])
   stroke([Vector2(30,10),Vector2(30,27),Vector2(24,32),Vector2(38,32)])
   if status.icon=="legs": stroke([Vector2(11,20),Vector2(36,20)])
   if status.icon=="movement": stroke([Vector2(5,15),Vector2(11,15)])
  "hand":
   stroke([Vector2(14,36),Vector2(9,24),Vector2(12,20),Vector2(17,25),Vector2(17,12),Vector2(21,12),Vector2(21,23),Vector2(22,8),Vector2(26,8),Vector2(26,23),Vector2(28,11),Vector2(32,12),Vector2(31,25),Vector2(35,18),Vector2(38,20),Vector2(33,36),Vector2(14,36)])
  "eye":
   stroke([Vector2(7,24),Vector2(16,16),Vector2(30,16),Vector2(41,24),Vector2(30,31),Vector2(16,31),Vector2(7,24)])
   draw_circle(Vector2(24,24),5,ink);stroke([Vector2(10,39),Vector2(38,9)],Color("da8c98"))
  "mouth":
   stroke([Vector2(9,25),Vector2(19,18),Vector2(24,21),Vector2(29,18),Vector2(39,25),Vector2(29,32),Vector2(18,32),Vector2(9,25),Vector2(39,25)])
  "strength","weakness":
   stroke([Vector2(10,33),Vector2(17,12),Vector2(26,12),Vector2(29,19),Vector2(24,23),Vector2(20,19),Vector2(19,28),Vector2(33,24),Vector2(39,29),Vector2(34,36),Vector2(10,33)])
   if status.icon=="weakness": stroke([Vector2(9,8),Vector2(39,39)],Color("df939b"))
  "dexterity":
   stroke([Vector2(11,37),Vector2(20,15),Vector2(36,9),Vector2(35,23),Vector2(24,32),Vector2(16,29)])
   stroke([Vector2(16,28),Vector2(31,14)]);stroke([Vector2(21,23),Vector2(20,16)])
  "shield","ready":
   stroke([Vector2(24,8),Vector2(38,14),Vector2(35,31),Vector2(24,40),Vector2(13,31),Vector2(10,14),Vector2(24,8)])
   if status.icon=="ready": stroke([Vector2(16,24),Vector2(22,30),Vector2(33,17)])
  "cards","stock":
   stroke([Vector2(10,30),Vector2(7,13),Vector2(26,9),Vector2(28,14)])
   draw_rect(Rect2(16,17,20,22),ink,false,2.6)
   if status.icon=="stock": stroke([Vector2(17,24),Vector2(35,24)])
  "wall":
   for y in [12,22,32]: stroke([Vector2(9,y),Vector2(37,y)])
   for p in [Vector2(18,12),Vector2(28,22),Vector2(18,32)]: stroke([p,p+Vector2(0,10)])
  "puppet":
   stroke([Vector2(11,9),Vector2(37,9)]);draw_circle(Vector2(24,22),6,ink)
   stroke([Vector2(24,9),Vector2(24,15)]);stroke([Vector2(24,28),Vector2(24,35),Vector2(15,40)])
   stroke([Vector2(14,30),Vector2(34,30)]);stroke([Vector2(24,35),Vector2(33,40)])
  "split":
   stroke([Vector2(24,40),Vector2(24,26),Vector2(12,12),Vector2(12,22)])
   stroke([Vector2(24,26),Vector2(36,12),Vector2(36,22)])
   stroke([Vector2(12,12),Vector2(22,12)]);stroke([Vector2(26,12),Vector2(36,12)])
  "ritual","sure_cast","power":
   draw_arc(Vector2(24,24),14,0,TAU,36,ink,2,true)
   stroke([Vector2(24,8),Vector2(35,32),Vector2(11,32),Vector2(24,8)])
   draw_circle(Vector2(24,24),3,ink)
  "pressure":
   var points=PackedVector2Array()
   for i in range(48):
    var a=i/47.0*TAU*1.7
    points.append(Vector2(24,24)+Vector2(cos(a),sin(a))*(2+i/47.0*14))
   draw_polyline(points,ink,2.6,true)
  _:
   draw_circle(Vector2(24,15),2,ink);stroke([Vector2(22,23),Vector2(25,23),Vector2(25,35)])
 if status.get("face","")=="bound": draw_circle(Vector2(8,8),4,Color("deb78e"))
 elif status.get("face","")=="free": draw_circle(Vector2(8,8),4,Color("8fd8dd"))
