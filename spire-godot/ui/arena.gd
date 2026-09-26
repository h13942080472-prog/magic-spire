extends Control

const Art=preload("res://ui/pixel_art.gd")
const EquipmentPortrait=preload("res://ui/equipment_portrait.gd")
const ILLUSTRATIONS={
 "iron_man":preload("res://assets/ui/enemies/iron_man.svg"),
 "puppeteer":preload("res://assets/ui/enemies/puppeteer.svg"),
 "puppet":preload("res://assets/ui/enemies/puppet.svg"),
 "rope":preload("res://assets/ui/enemies/rope.svg"),
 "belt":preload("res://assets/ui/enemies/belt.svg"),
 "lock":preload("res://assets/ui/enemies/lock.svg"),
 "silencer":preload("res://assets/ui/enemies/silencer.svg"),
}
var pose="stand"
var mode="hero"
var variant=""
var template=""
var art_settings
var inactive=false
var has_restraint_level=false
var fixed_portrait=false
var character_id="original"
var hero_view: Dictionary={}
var hero_sprite: TextureRect
var enemy_sprite: TextureRect
var appearance: Array=[]

func configure_hero(view: Dictionary, fixed: bool) -> void:
 var next_character=view.get("character_id","original")
 var next_pose="stand" if fixed else view.posture
 var details=[] if fixed or next_character=="witch" else (EquipmentPortrait.visual_facts(view) if next_pose=="stand" else [view.has_restraint_level])
 var next_appearance=[next_character,next_pose,fixed,details]
 if appearance==next_appearance:return
 appearance=next_appearance
 mode="hero";pose=next_pose;fixed_portrait=fixed;character_id=next_character
 has_restraint_level=view.has_restraint_level
 # Retain visual facts only, not the entire game view or its display facts.
 hero_view=EquipmentPortrait.snapshot(view)
 if is_node_ready():_refresh_hero()

func configure_enemy(enemy: Dictionary, settings) -> void:
 var next_appearance=[enemy.type,enemy.visual_variant,enemy.template,enemy.gone]
 var settings_changed=art_settings!=settings
 if appearance==next_appearance and not settings_changed:return
 if settings_changed and art_settings!=null and art_settings.art_changed.is_connected(_art_changed):
  art_settings.art_changed.disconnect(_art_changed)
 appearance=next_appearance
 mode=enemy.type;variant=enemy.visual_variant;template=enemy.template;inactive=enemy.gone
 art_settings=settings
 if is_node_ready():
  _connect_art_settings()
  _refresh_enemy_art()

func _connect_art_settings() -> void:
 if art_settings!=null and not art_settings.art_changed.is_connected(_art_changed):
  art_settings.art_changed.connect(_art_changed)

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 if mode=="hero":
  resized.connect(_place_hero)
  _refresh_hero()
 else:
  _connect_art_settings()
  _refresh_enemy_art()
 set_process(false)

func _refresh_hero() -> void:
 var free_special=hero_view.get("equipment_portrait_layers",[]).any(func(id):return id in ["flat_lock","flat_lock_reinforcement"])
 var layered=character_id!="witch" and not fixed_portrait and pose=="stand" and (has_restraint_level or free_special)
 if is_instance_valid(hero_sprite) and (hero_sprite is EquipmentPortrait)!=layered:
  remove_child(hero_sprite);hero_sprite.queue_free();hero_sprite=null
 if layered:
  if not is_instance_valid(hero_sprite):
   hero_sprite=EquipmentPortrait.new();hero_sprite.name="HeroPose"
   hero_sprite.configure(hero_view,false,true);add_child(hero_sprite)
  else:hero_sprite.configure(hero_view,false,true)
 else:
  if fixed_portrait:pose="stand"
  var image=EquipmentPortrait.FREE if fixed_portrait else Art.hero_texture(pose,has_restraint_level,character_id)
  if not is_instance_valid(hero_sprite):hero_sprite=_sprite(image,"HeroPose")
  elif hero_sprite.texture!=image:hero_sprite.texture=image
 hero_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 _place_hero()
 queue_redraw()

func _art_changed(category: String, id: String) -> void:
 if category=="enemies" and id==template: _refresh_enemy_art()

func _refresh_enemy_art() -> void:
 if is_instance_valid(enemy_sprite):
  remove_child(enemy_sprite);enemy_sprite.queue_free();enemy_sprite=null
 var texture=art_settings.art_texture("enemies",template) if art_settings!=null else null
 if texture==null:
  if mode=="guard": texture=Art.SUCCUBUS_GUARD_PORTRAITS.get(variant,Art.SUCCUBUS_GUARD_PORTRAITS.guard_purple)
  else: texture=ILLUSTRATIONS.get(mode)
 if texture!=null:
  enemy_sprite=_sprite(texture,"EnemySprite")
  enemy_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  enemy_sprite.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  enemy_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  enemy_sprite.self_modulate=Color(0.65,0.7,0.76,0.3) if inactive else Color.WHITE
 queue_redraw()

func _sprite(texture: Texture2D, node_name: String) -> TextureRect:
 var sprite=TextureRect.new()
 sprite.name=node_name;sprite.texture=texture
 sprite.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 sprite.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(sprite)
 return sprite

func _place_hero() -> void:
 if not is_instance_valid(hero_sprite): return
 var source_size=hero_sprite.texture.get_size()
 var scale_factor=minf(size.y*Art.HERO_HEIGHTS[pose]/source_size.y,(size.x-16)/source_size.x)
 hero_sprite.size=source_size*scale_factor
 hero_sprite.position=Vector2((size.x-hero_sprite.size.x)/2,size.y-hero_sprite.size.y)

func _draw() -> void:
 draw_set_transform(Vector2(size.x/2,size.y-4),0,Vector2(1,0.13))
 var radius=42 if mode=="hero" and pose=="stand" else (75 if mode=="hero" and pose=="sit" else 95)
 draw_circle(Vector2.ZERO,radius,Color(0.015,0.025,0.045,0.4),true,-1,true)
 if not inactive:
  draw_arc(Vector2.ZERO,radius+6,0,TAU,64,Color(0.42,0.73,0.75,0.23),2,true)
 draw_set_transform(Vector2.ZERO)
 if is_instance_valid(enemy_sprite): return
 if mode=="binding_box":
  var factor=minf(size.x/220.0,size.y/190.0)
  draw_set_transform(Vector2(size.x/2,size.y/2),0,Vector2.ONE*factor)
  var steel=Color("334b58");var rim=Color("a9bec7");var glow=Color("8bdbd4");var leather=Color("785448")
  if inactive: steel.a=0.3;rim.a=0.3;glow.a=0.3;leather.a=0.3
  draw_rect(Rect2(-70,-34,140,108),steel)
  draw_rect(Rect2(-70,-34,140,108),rim,false,4)
  draw_colored_polygon(PackedVector2Array([Vector2(-77,-41),Vector2(-56,-69),Vector2(56,-69),Vector2(77,-41)]),steel.lightened(0.12))
  draw_polyline(PackedVector2Array([Vector2(-77,-41),Vector2(-56,-69),Vector2(56,-69),Vector2(77,-41),Vector2(-77,-41)]),rim,3,true)
  for x in [-47,36]:
   draw_rect(Rect2(x,-30,11,100),leather)
   draw_rect(Rect2(x-3,20,17,23),Color("cdb780"),false,3)
  draw_arc(Vector2(0,9),25,0,TAU,32,glow,3,true)
  draw_colored_polygon(PackedVector2Array([Vector2(0,-8),Vector2(11,9),Vector2(0,26),Vector2(-11,9)]),glow)
  for x in [-84,84]:
   draw_line(Vector2(x,7),Vector2(x,51),rim,7,true)
   draw_arc(Vector2(x,58),12,-0.4,PI+0.4,24,rim,5,true)
  draw_set_transform(Vector2.ZERO)
  return
 if mode=="drone":
  var factor=minf(size.x/220.0,size.y/180.0)
  draw_set_transform(Vector2(size.x/2,size.y/2),0,Vector2.ONE*factor)
  var metal=Color("566f7b");var rim=Color("cdb780");var glow=Color("8bdbd4")
  if inactive: metal.a=0.3;rim.a=0.3;glow.a=0.3
  for x in [-68,68]:
   draw_line(Vector2(x,-22),Vector2(0,8),metal,12,true)
   draw_arc(Vector2(x,-25),29,0,TAU,32,rim,5,true)
   draw_line(Vector2(x-24,-25),Vector2(x+24,-25),glow,3,true)
   draw_line(Vector2(x,-43),Vector2(x,-7),glow,3,true)
  draw_colored_polygon(PackedVector2Array([Vector2(-43,-16),Vector2(43,-16),Vector2(35,30),Vector2(0,43),Vector2(-35,30)]),metal)
  draw_circle(Vector2(0,8),19,rim)
  draw_circle(Vector2(0,8),13,Color("172d38"))
  draw_circle(Vector2(0,8),7,glow)
  for x in [-22,22]:
   draw_line(Vector2(x,31),Vector2(x,56),metal,7,true)
   draw_arc(Vector2(x,59),10,0,TAU,24,rim,4,true)
  draw_set_transform(Vector2.ZERO)
  return

 if mode=="trader":
  _draw_trader()
  return
 if mode=="versatile":
  _draw_versatile()
  return
 if mode=="six_bind":
  _draw_six_bind()
  return
 if mode=="mixed_bundle":
  var bundle_scale=minf(size.x/220.0,size.y/180.0)
  draw_set_transform(Vector2(size.x/2,size.y/2),0,Vector2.ONE*bundle_scale)
  var colors=[Color("cdb780"),Color("705044"),Color("78928b"),Color("aaa9a0")]
  for i in range(12):
   var points=PackedVector2Array()
   for j in range(41):
    var angle=TAU*j/40.0
    points.append(Vector2(cos(angle)*(32+i*3),sin(angle)*(18+i*2)).rotated(i*0.74)+Vector2(sin(i*2.0)*12,cos(i*1.4)*13))
   var color=colors[i%colors.size()];color.a=0.3 if inactive else 1.0
   draw_polyline(points,color,5+i%4,true)
  draw_rect(Rect2(-31,-15,22,18),Color("cdb780"),false,4)
  draw_rect(Rect2(20,20,20,16),Color("aaa9a0"),false,3)
  draw_set_transform(Vector2.ZERO)
  return
 if mode=="rope_serpent":
  var serpent_scale=minf(size.x/200.0,size.y/180.0)
  draw_set_transform(Vector2(size.x/2,size.y/2),0,Vector2.ONE*serpent_scale)
  var points=PackedVector2Array()
  for i in range(61):
   var y=60-float(i)*2
   points.append(Vector2(sin(float(i)*0.12)*43,y))
  var gold=Color("cdb780");var dark=Color("55462e")
  if inactive: gold.a=0.3;dark.a=0.3
  draw_polyline(points,dark,24,true)
  draw_polyline(points,gold,17,true)
  for i in range(3,58,4): draw_line(points[i]+Vector2(-7,-3),points[i]+Vector2(7,3),dark,2,true)
  var head=points[-1]
  draw_circle(head,15,gold)
  for x in [-6,6]: draw_circle(head+Vector2(x,-4),3,Color("19333b"))
  draw_set_transform(Vector2.ZERO)
  return
 if mode=="ominous_circle":
  var circle_scale=minf(size.x/200.0,size.y/180.0)
  draw_set_transform(Vector2(size.x/2,size.y/2),0,Vector2.ONE*circle_scale)
  var glow=Color("bc81d5");var rim=Color("cdb780")
  if inactive: glow.a=0.3;rim.a=0.3
  draw_circle(Vector2.ZERO,76,Color(0.08,0.03,0.15,0.8))
  for radius_value in [60,70,78]: draw_arc(Vector2.ZERO,radius_value,0,TAU,72,glow,2,true)
  for i in range(6):
   var angle=TAU*i/6-PI/2
   var a=Vector2.from_angle(angle)*60
   draw_line(a,Vector2.from_angle(angle+TAU/3)*60,rim,2,true)
   draw_line(Vector2.from_angle(angle)*70,Vector2.from_angle(angle)*78,rim,4,true)
  draw_arc(Vector2.ZERO,19,0,TAU,36,rim,2,true)
  draw_circle(Vector2.ZERO,7,glow)
  draw_set_transform(Vector2.ZERO)
  return

 # Small code-drawn equipment silhouettes share the arena's scale and inactive state.
 if mode not in ["tape","cable_tie","toybox","rope_mass","rope_heap","belt_mass","belt_heap"]: return
 var scale_value=minf(size.x/220.0,size.y/180.0)
 draw_set_transform(Vector2(size.x/2,size.y/2),0,Vector2.ONE*scale_value)
 var gold=Color("cdb780");var dark=Color("263943");var cyan=Color("8bdbd4")
 if inactive: gold.a=0.3;dark.a=0.3;cyan.a=0.3
 if mode in ["rope_mass","rope_heap","belt_mass","belt_heap"]:
  draw_circle(Vector2(0,5),65,dark,true,-1,true)
  for i in range(11 if mode in ["rope_heap","belt_heap"] else 7):
   var strand=PackedVector2Array()
   for step in range(65):
    var angle=TAU*step/64.0
    strand.append(Vector2(cos(angle)*(62-i*3),sin(angle)*(44+i*2)).rotated(i*0.64)+Vector2(0,5))
   if mode in ["belt_mass","belt_heap"]:
    var leather=Color("684d42");leather.a=gold.a
    draw_polyline(strand,leather,11,true)
    draw_polyline(strand,gold.darkened(0.28),1,true)
    var buckle=strand[(i*7+12)%64]
    draw_rect(Rect2(buckle-Vector2(7,6),Vector2(14,12)),gold,false,2,true)
   else:
    draw_polyline(strand,gold.darkened(0.12*(i%3)),7,true)
    draw_polyline(strand,gold.lightened(0.2),2,true)
  draw_polyline(PackedVector2Array([Vector2(-40,43),Vector2(-74,64),Vector2(-94,47)]),gold,6,true)
  draw_polyline(PackedVector2Array([Vector2(43,42),Vector2(76,64),Vector2(91,39)]),gold,6,true)
  for x in [-18,18]:
   draw_circle(Vector2(x,0),11,dark,true,-1,true)
   draw_circle(Vector2(x,-2),4,cyan,true,-1,true)
 elif mode=="tape":
  draw_circle(Vector2(-10,-10),52,gold,true,-1,true)
  draw_circle(Vector2(-10,-10),27,dark,true,-1,true)
  draw_arc(Vector2(-10,-10),39,0,TAU,64,cyan,2,true)
  draw_colored_polygon(PackedVector2Array([Vector2(26,23),Vector2(77,53),Vector2(63,76),Vector2(8,37)]),gold)
 elif mode=="cable_tie":
  draw_arc(Vector2(-10,0),46,-0.6,TAU-0.9,64,gold,10,true)
  draw_line(Vector2(24,-30),Vector2(88,-57),gold,9,true)
  draw_rect(Rect2(18,-44,26,24),dark);draw_rect(Rect2(18,-44,26,24),cyan,false,3)
  for i in range(6): draw_line(Vector2(44+i*7,-35-i*3),Vector2(47+i*7,-29-i*3),dark,2,true)
 else:
  draw_rect(Rect2(-68,-15,136,80),dark);draw_rect(Rect2(-68,-15,136,80),gold,false,4)
  draw_colored_polygon(PackedVector2Array([Vector2(-76,-22),Vector2(-56,-48),Vector2(65,-48),Vector2(77,-22)]),gold)
  for x in [-45,38]: draw_rect(Rect2(x,-12,9,74),gold)
  draw_rect(Rect2(-13,10,26,28),gold);draw_circle(Vector2(0,20),4,dark)
  draw_line(Vector2(-30,-68),Vector2(-30,-54),cyan,3,true)
  draw_line(Vector2(26,-79),Vector2(26,-59),cyan,3,true)
  draw_line(Vector2(15,-69),Vector2(37,-69),cyan,3,true)
 draw_set_transform(Vector2.ZERO)

# Native human silhouette fits the existing enemy control in battle and catalogue.
func _draw_trader() -> void:
 var scale_value=minf(size.x/130.0,size.y/180.0)
 draw_set_transform(Vector2(size.x/2,size.y-5),0,Vector2.ONE*scale_value)
 var coat=Color("624737");var lining=Color("b78c55");var ink=Color("252830")
 var skin=Color("bd987c");var magic=Color("80ddd1")
 if inactive: coat.a=0.3;lining.a=0.3;ink.a=0.3;skin.a=0.3;magic.a=0.3
 # Boots, split long coat, waistcoat and a broad merchant's hat.
 draw_rect(Rect2(-24,-38,17,35),ink);draw_rect(Rect2(8,-38,17,35),ink)
 draw_rect(Rect2(-30,-10,23,10),ink);draw_rect(Rect2(8,-10,23,10),ink)
 draw_colored_polygon(PackedVector2Array([Vector2(-26,-124),Vector2(25,-124),Vector2(40,-25),Vector2(8,-31),Vector2(0,-48),Vector2(-10,-30),Vector2(-40,-25)]),coat)
 draw_colored_polygon(PackedVector2Array([Vector2(-14,-120),Vector2(14,-120),Vector2(17,-69),Vector2(-15,-69)]),lining)
 draw_line(Vector2(-23,-124),Vector2(-8,-91),ink,5,true)
 draw_line(Vector2(23,-124),Vector2(8,-91),ink,5,true)
 for y in [-100,-89,-78]: draw_circle(Vector2(0,y),2,ink)
 draw_line(Vector2(-27,-119),Vector2(-43,-71),coat,15,true)
 draw_line(Vector2(27,-119),Vector2(43,-73),coat,15,true)
 draw_circle(Vector2(-43,-66),7,skin);draw_circle(Vector2(43,-68),7,skin)
 draw_rect(Rect2(-28,-71,56,8),ink);draw_rect(Rect2(-6,-72,12,10),lining,false,2)
 # Ledger pouch distinguishes the trader from the armed guard.
 draw_rect(Rect2(20,-66,26,33),ink);draw_rect(Rect2(23,-63,20,25),coat)
 draw_rect(Rect2(29,-61,8,6),lining)
 draw_line(Vector2(-22,-119),Vector2(32,-65),lining,4,true)
 draw_rect(Rect2(-7,-132,14,12),skin)
 draw_circle(Vector2(0,-144),17,skin,true,-1,true)
 draw_colored_polygon(PackedVector2Array([Vector2(-17,-146),Vector2(16,-146),Vector2(12,-131),Vector2(0,-124),Vector2(-11,-132)]),ink)
 draw_line(Vector2(-10,-144),Vector2(-3,-144),magic,3,true)
 draw_line(Vector2(3,-144),Vector2(10,-144),magic,3,true)
 draw_rect(Rect2(-20,-169,40,18),coat);draw_rect(Rect2(-20,-157,40,6),lining)
 draw_rect(Rect2(-32,-152,64,5),ink)
 draw_set_transform(Vector2.ZERO)

func _draw_versatile() -> void:
 var scale_value=minf(size.x/130.0,size.y/180.0)
 draw_set_transform(Vector2(size.x/2,size.y-5),0,Vector2.ONE*scale_value)
 var leather=Color("34373f");var wine=Color("713c49");var metal=Color("c2aa72")
 var skin=Color("bd987c");var magic=Color("80ddd1")
 if inactive: leather.a=0.3;wine.a=0.3;metal.a=0.3;skin.a=0.3;magic.a=0.3
 draw_rect(Rect2(-25,-38,18,36),leather);draw_rect(Rect2(8,-38,18,36),leather)
 draw_rect(Rect2(-31,-10,25,9),leather);draw_rect(Rect2(8,-10,25,9),leather)
 draw_colored_polygon(PackedVector2Array([Vector2(-25,-125),Vector2(25,-125),Vector2(35,-36),Vector2(0,-51),Vector2(-35,-36)]),wine)
 draw_colored_polygon(PackedVector2Array([Vector2(-9,-122),Vector2(10,-122),Vector2(16,-53),Vector2(-16,-53)]),leather)
 draw_line(Vector2(-26,-116),Vector2(-43,-70),wine,14,true);draw_line(Vector2(26,-116),Vector2(43,-70),wine,14,true)
 draw_circle(Vector2(-44,-65),7,skin);draw_circle(Vector2(44,-65),7,skin)
 draw_rect(Rect2(-31,-72,62,8),leather);draw_rect(Rect2(-7,-73,14,10),metal,false,2)
 for x in [-27,-12,14,28]:
  draw_rect(Rect2(x-5,-61,10,18),leather);draw_circle(Vector2(x,-47),3,magic)
 draw_line(Vector2(-31,-108),Vector2(29,-49),metal,3,true)
 draw_rect(Rect2(-7,-134,14,12),skin);draw_circle(Vector2(0,-146),17,skin,true,-1,true)
 draw_colored_polygon(PackedVector2Array([Vector2(-18,-149),Vector2(17,-149),Vector2(12,-132),Vector2(-12,-132)]),leather)
 draw_line(Vector2(-10,-145),Vector2(-3,-145),magic,3,true);draw_line(Vector2(3,-145),Vector2(10,-145),magic,3,true)
 draw_arc(Vector2(0,-146),24,-2.8,-0.35,18,metal,4,true)
 draw_set_transform(Vector2.ZERO)

func _draw_six_bind() -> void:
 var scale_value=minf(size.x/170.0,size.y/205.0)
 draw_set_transform(Vector2(size.x/2,size.y-3),0,Vector2.ONE*scale_value)
 var black=Color("24232b");var wine=Color("682d48");var gold=Color("d2b66e")
 var skin=Color("c99c89");var magic=Color("a46fca")
 if inactive: black.a=0.3;wine.a=0.3;gold.a=0.3;skin.a=0.3;magic.a=0.3
 for i in range(6):
  var angle=TAU*float(i)/6.0
  var center=Vector2(cos(angle)*68,-91+sin(angle)*55)
  draw_arc(center,13,0,TAU,24,magic,3,true)
  draw_line(center,center.normalized()*6+Vector2(0,-86),Color(magic,0.38),2,true)
 draw_rect(Rect2(-27,-42,20,40),black);draw_rect(Rect2(8,-42,20,40),black)
 draw_colored_polygon(PackedVector2Array([Vector2(-37,-132),Vector2(36,-132),Vector2(43,-41),Vector2(0,-58),Vector2(-43,-41)]),wine)
 draw_colored_polygon(PackedVector2Array([Vector2(-10,-129),Vector2(11,-129),Vector2(18,-59),Vector2(-18,-59)]),black)
 draw_line(Vector2(-30,-120),Vector2(-48,-70),wine,15,true);draw_line(Vector2(30,-120),Vector2(48,-70),wine,15,true)
 draw_circle(Vector2(-49,-65),7,skin);draw_circle(Vector2(49,-65),7,skin)
 for y in [-112,-96,-80]:
  draw_arc(Vector2(0,y),35,0.18,PI-0.18,28,gold,3,true)
 draw_rect(Rect2(-7,-141,14,13),skin)
 draw_circle(Vector2(0,-154),19,skin,true,-1,true)
 draw_colored_polygon(PackedVector2Array([Vector2(-21,-159),Vector2(18,-171),Vector2(22,-147),Vector2(9,-134),Vector2(-17,-138)]),black)
 draw_line(Vector2(-12,-154),Vector2(-4,-154),magic,4,true);draw_line(Vector2(4,-154),Vector2(12,-154),magic,4,true)
 draw_arc(Vector2(0,-154),27,-2.9,-0.2,20,gold,4,true)
 draw_set_transform(Vector2.ZERO)
