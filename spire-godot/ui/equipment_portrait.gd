extends TextureRect

# Display mapping only. Actual coverage comes from the read-only view.
const FREE=preload("res://assets/art/equipment-portrait-cutout-v1.png")
const BATTLE_FREE=preload("res://assets/art/hero-stand-cutout-v2.png")
const WITCH_SIDEBAR=preload("res://assets/art/witch-sidebar-cutout-v1.png")
const BOUND_BASE=preload("res://assets/art/equipment-material-body-plain-rope-free-v1.png")
const BOUND_FLAT_LOCK=preload("res://assets/art/equipment-material-body-flat-lock-rope-free-v1.png")
const BOUND_SINGLE_GLOVE=preload("res://assets/art/equipment-body-single-glove-v1.png")
const BOUND_SINGLE_GLOVE_FLAT_LOCK=preload("res://assets/art/equipment-body-single-glove-flat-lock-v1.png")
const BOUND_BASES={
 "plain":{"free":BOUND_BASE,"bound":preload("res://assets/art/equipment-material-body-plain-rope-bound-v1.png"),"leather_free":preload("res://assets/art/equipment-material-body-plain-leather-free-v1.png"),"leather_bound":preload("res://assets/art/equipment-material-body-plain-leather-bound-v1.png")},
 "flat_lock":{"free":BOUND_FLAT_LOCK,"bound":preload("res://assets/art/equipment-material-body-flat-lock-rope-bound-v1.png"),"leather_free":preload("res://assets/art/equipment-material-body-flat-lock-leather-free-v1.png"),"leather_bound":preload("res://assets/art/equipment-material-body-flat-lock-leather-bound-v1.png")}}
const REINFORCEMENT_WITHOUT_CROTCH_ROPE=preload("res://assets/art/equipment-overlay-flat-lock-reinforcement-no-crotch-rope-v1.png")
const FLAT_LOCK_THIGH={
 "bound":preload("res://assets/art/equipment-material-leg-thigh_root-flat-lock-rope-v1.png"),
 "free":preload("res://assets/art/equipment-material-leg-thigh_root-flat-lock-free-v1.png")}
const SINGLE_GLOVE_THIGH={
 "bound":preload("res://assets/art/equipment-leg-thigh_root-single-glove-v1.png"),
 "free":preload("res://assets/art/equipment-leg-thigh_root-single-glove-free-v1.png"),
 "flat_lock_bound":preload("res://assets/art/equipment-leg-thigh_root-single-glove-flat-lock-v1.png"),
 "flat_lock_free":preload("res://assets/art/equipment-leg-thigh_root-single-glove-flat-lock-free-v1.png")}
const LAYERS={
 "mouth":{"texture":preload("res://assets/art/equipment-overlay-mouth-v1.png"),"origin":Vector2(655,374)},
 "eyes":{"texture":preload("res://assets/art/equipment-overlay-eyes-v1.png"),"origin":Vector2(590,238)}}
const SPECIAL_LAYERS={
 "flat_lock_reinforcement":{"texture":preload("res://assets/art/equipment-overlay-flat-lock-reinforcement-v1.png"),"origin":Vector2(656,928)},
 "urethral_rod":{"texture":preload("res://assets/art/equipment-overlay-urethral-rod-v1.png"),"origin":Vector2(873,1147)}}
const FREE_SPECIAL_LAYERS={
 "flat_lock":{"texture":preload("res://assets/art/hero-overlay-flat-lock-free-v1.png"),"origin":Vector2(774,894)},
 "flat_lock_reinforcement":{"texture":preload("res://assets/art/hero-overlay-flat-lock-reinforcement-free-v1.png"),"origin":Vector2(634,956)}}
const BOUND_CROP=Vector2(390,90)
const FREE_CROP=Vector2(463,164)
const BATTLE_FREE_CROP=Vector2(349,60)
const BOUND_EYE=Vector2(895,329)
const FREE_EYE=Vector2(823,383)
const FREE_FACE_SCALE=0.907
const FREE_FACE_ROTATION=-0.1035
const SINGLE_LEG_DRAW_ORDER=["single_leg_upper","single_leg_lower","single_leg_long"]
var variant=-1
var fixed_portrait=false
var battle_free_portrait=false
var witch_portrait=false
var equipped_mouth=false
var equipped_eyes=false
var active_leg_layers: Array=[]
var active_special_layers: Array=[]
var active_composite_layers: Array=[]
var active_materials: Dictionary={}
static var leg_layers: Dictionary=_load_leg_layers()
static var single_leg_layers: Dictionary=_load_single_leg_layers()
static var single_leg_bases: Dictionary=_load_single_leg_bases()
var appearance: Array=[]

# Shared display policy for the arena and sidebar; never query the live game here.
static func uses_fixed_portrait(view: Dictionary, preferred: bool) -> bool:
 return preferred and view.get("character_id","original")!="witch"

# Owners retain only the fields consumed by this renderer, never actions or full state.
static func snapshot(view: Dictionary) -> Dictionary:
 return {"character_id":view.get("character_id","original"),
  "has_restraint_level":view.has_restraint_level,
  "equipment_portrait_layers":view.get("equipment_portrait_layers",[]).duplicate(),
  "composite_portrait_layers":view.get("composite_portrait_layers",[]).duplicate(),
  "body_coverage":view.body_coverage.duplicate(true),
  "bodies":view.bodies.map(func(body):return {"id":body.id,"occupied":body.occupied})}

static func visual_facts(view: Dictionary) -> Array:
 var legs=[]
 for key in leg_layers:
  var spec=leg_layers[key]
  if spec.value in view.get("body_coverage",{}).get(spec.field,[]):legs.append(key)
 var bodies=view.get("bodies",[])
 return [view.get("has_restraint_level",false),view.get("equipment_portrait_layers",[]).duplicate(),view.get("composite_portrait_layers",[]).duplicate(),legs,view.get("body_coverage",{}).get("materials",{}).duplicate(),
  bodies.any(func(body):return body.id=="mouth" and body.occupied),
  bodies.any(func(body):return body.id=="eyes" and body.occupied)]

static func _load_leg_layers() -> Dictionary:
 var entries=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/equipment-leg-layers.json"))
 var materials=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/equipment-material-layers.json"))
 var result={}
 for entry in entries:
  var material=materials.legs[entry.id]
  var styles={}
  for kind in material.styles:
   styles[kind]={}
   for style in material.styles[kind]:styles[kind][style]=load(material.styles[kind][style])
  result[entry.id]={"texture":styles.plain.rope,"free_texture":styles.plain.free,"styles":styles,"origin":Vector2(material.origin[0],material.origin[1]),"field":entry.field,"value":entry.value,
   "glove_texture":load(entry.texture),"glove_free_texture":load(entry.free_texture),"glove_origin":Vector2(entry.origin[0],entry.origin[1])}
 return result

static func _load_single_leg_layers() -> Dictionary:
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/equipment-single-leg-layers.json"))
 var result={}
 for key in manifest.layers:
  var entry=manifest.layers[key]
  var slices={}
  for slice_id in entry.get("slices",{}):
   slices[slice_id]={}
   for context in entry.slices[slice_id]: slices[slice_id][context]=load(entry.slices[slice_id][context])
  result[key]={"texture":load(entry.texture),"origin":Vector2(entry.origin[0],entry.origin[1]),"slices":slices}
 return result

static func _load_single_leg_bases() -> Dictionary:
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/equipment-single-leg-layers.json"))
 var result={}
 for key in manifest.bases:
  result[key]={}
  for context in manifest.bases[key]:result[key][context]=load(manifest.bases[key][context])
 return result

func _single_leg_for_slice(slice_id: String) -> String:
 var selected=""
 for key in SINGLE_LEG_DRAW_ORDER:
  if key in active_composite_layers and single_leg_layers[key].slices.has(slice_id): selected=key
 return selected

func _single_leg_slice_context(slice_id: String, bound: bool) -> String:
 if "single_glove" in active_composite_layers:
  var glove_prefix="single_glove_"
  if slice_id=="thigh_root" and "flat_lock" in active_special_layers:glove_prefix+="flat_lock_"
  return glove_prefix+("bound" if bound else "free")
 var material=active_materials.get(slice_id,"rope") if bound else "free"
 return ("flat_lock_" if slice_id=="thigh_root" and "flat_lock" in active_special_layers else "")+material

func _single_leg_base_key() -> String:
 if "single_leg_long" in active_composite_layers:return "single_leg_long"
 if "single_leg_upper" in active_composite_layers and "single_leg_lower" in active_composite_layers:return "single_leg_upper_lower"
 if "single_leg_upper" in active_composite_layers:return "single_leg_upper"
 if "single_leg_lower" in active_composite_layers:return "single_leg_lower"
 return ""

func _single_leg_base_context(has_flat_lock: bool, has_single_glove: bool) -> String:
 if has_single_glove:return "single_glove_flat_lock" if has_flat_lock else "single_glove"
 var context="flat_lock_" if has_flat_lock else "plain_"
 if active_materials.get("upper","rope")=="leather":context+="leather_"
 return context+("bound" if "crotch_rope" in active_special_layers else "free")

func configure(view: Dictionary, fixed: bool=false, battle_free: bool=false) -> void:
 var next_witch=view.get("character_id","original")=="witch"
 var next_appearance=[next_witch,fixed,battle_free,[] if fixed or next_witch else visual_facts(view)]
 if appearance==next_appearance:return
 appearance=next_appearance
 fixed_portrait=fixed
 battle_free_portrait=battle_free
 witch_portrait=next_witch
 variant=0 if view.has_restraint_level and not fixed and not witch_portrait else -1
 active_special_layers.assign(view.get("equipment_portrait_layers",[]))
 active_composite_layers.assign(view.get("composite_portrait_layers",[]))
 active_materials=view.body_coverage.get("materials",{}).duplicate()
 var has_flat_lock="flat_lock" in active_special_layers
 var has_single_glove="single_glove" in active_composite_layers
 var base_key="flat_lock" if has_flat_lock else "plain"
 var rope_key="bound" if "crotch_rope" in active_special_layers else "free"
 if active_materials.get("upper","rope")=="leather":rope_key="leather_"+rope_key
 var bound_texture=(BOUND_SINGLE_GLOVE_FLAT_LOCK if has_flat_lock else BOUND_SINGLE_GLOVE) if has_single_glove else BOUND_BASES[base_key][rope_key]
 var leg_base_key=_single_leg_base_key()
 if leg_base_key!="":bound_texture=single_leg_bases[leg_base_key][_single_leg_base_context(has_flat_lock,has_single_glove)]
 texture=WITCH_SIDEBAR if witch_portrait else ((BATTLE_FREE if battle_free_portrait else FREE) if variant<0 else bound_texture)
 active_leg_layers.clear()
 for key in leg_layers:
  var spec=leg_layers[key]
  if spec.value in view.body_coverage[spec.field]: active_leg_layers.append(key)
 equipped_mouth=view.bodies.any(func(b):return b.id=="mouth" and b.occupied)
 equipped_eyes=view.bodies.any(func(b):return b.id=="eyes" and b.occupied)
 expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 if is_node_ready(): _align_layers()

func _add_overlay(key: String, image: Texture2D) -> void:
 # Sprite offsets keep fractional coordinates when the UI snaps Controls to pixels.
 var layer=Sprite2D.new()
 layer.name="Overlay_"+key;layer.centered=false;layer.texture=image
 add_child(layer)

func _ready() -> void:
 if texture==null:texture=FREE
 var layers=LAYERS.merged(leg_layers)
 for key in layers:
  _add_overlay(key,layers[key].texture)
 for key in SPECIAL_LAYERS:
  _add_overlay(key,SPECIAL_LAYERS[key].texture)
 for key in FREE_SPECIAL_LAYERS:
  _add_overlay("free_"+key,FREE_SPECIAL_LAYERS[key].texture)
 # Single-leg sleeves replace the ordinary horizontal leg slices and therefore
 # stay last in draw order; otherwise those slices reopen visible seams.
 for key in SINGLE_LEG_DRAW_ORDER:
  _add_overlay(key,single_leg_layers[key].texture)
 resized.connect(_align_layers);_align_layers()

func _align_layers() -> void:
 # KEEP_ASPECT_CENTERED draws the base into integer dimensions.
 var base_size=Vector2(floorf(texture.get_width()*size.y/texture.get_height()),floorf(size.y))
 if base_size.x>size.x:
  base_size.x=floorf(size.x)
  base_size.y=floorf(texture.get_height()*base_size.x/texture.get_width())
 var factor=base_size/texture.get_size()
 var offset=(size-base_size)/2
 var layers=LAYERS.merged(leg_layers)
 for key in layers:
  var layer=get_node("Overlay_"+key)
  layer.visible=not witch_portrait and not fixed_portrait and not (battle_free_portrait and variant<0) and (equipped_mouth if key=="mouth" else (equipped_eyes if key=="eyes" else variant>=0))
  if key in leg_layers:
   var single_leg=_single_leg_for_slice(key)
   if single_leg!="":
    var context=_single_leg_slice_context(key,key in active_leg_layers)
    layer.texture=single_leg_layers[single_leg].slices[key][context]
   elif key=="thigh_root" and "single_glove" in active_composite_layers:
    var thigh_key=("flat_lock_" if "flat_lock" in active_special_layers else "")+("bound" if key in active_leg_layers else "free")
    layer.texture=SINGLE_GLOVE_THIGH[thigh_key]
   elif "single_glove" in active_composite_layers:
    layer.texture=leg_layers[key].glove_texture if key in active_leg_layers else leg_layers[key].glove_free_texture
   else:
    var kind="flat_lock" if key=="thigh_root" and "flat_lock" in active_special_layers else "plain"
    var material=active_materials.get(key,"rope") if key in active_leg_layers else "free"
    layer.texture=leg_layers[key].styles[kind][material]
  var position_in_source=layers[key].origin-BOUND_CROP
  if key in leg_layers and "single_glove" in active_composite_layers:position_in_source=leg_layers[key].glove_origin-BOUND_CROP
  var layer_factor=1.0;var angle=0.0
  if variant<0 and key in LAYERS:
   position_in_source=FREE_EYE+(LAYERS[key].origin-BOUND_EYE).rotated(FREE_FACE_ROTATION)*FREE_FACE_SCALE-FREE_CROP
   layer_factor=FREE_FACE_SCALE;angle=FREE_FACE_ROTATION
  layer.position=offset+position_in_source*factor
  layer.scale=factor*layer_factor
  # The material torso's last opaque row blends into transparent texels.
  # Extend the matching thigh edge half a source texel, keeping its bottom fixed.
  if key=="thigh_root" and not "single_glove" in active_composite_layers:
   layer.position.y-=0.5*factor.y
   layer.scale.y+=0.5*factor.y/layer.texture.get_height()
  layer.rotation=angle
 for key in SPECIAL_LAYERS:
  var layer=get_node("Overlay_"+key)
  layer.texture=REINFORCEMENT_WITHOUT_CROTCH_ROPE if key=="flat_lock_reinforcement" and not "crotch_rope" in active_special_layers and not "single_glove" in active_composite_layers else SPECIAL_LAYERS[key].texture
  layer.visible=not witch_portrait and variant>=0 and not fixed_portrait and key in active_special_layers
  layer.position=offset+(SPECIAL_LAYERS[key].origin-BOUND_CROP)*factor
  layer.scale=factor
 for key in FREE_SPECIAL_LAYERS:
  var layer=get_node("Overlay_free_"+key)
  layer.visible=not witch_portrait and battle_free_portrait and variant<0 and not fixed_portrait and key in active_special_layers
  layer.position=offset+(FREE_SPECIAL_LAYERS[key].origin-BATTLE_FREE_CROP)*factor
  layer.scale=factor
 for key in SINGLE_LEG_DRAW_ORDER:
  var layer=get_node("Overlay_"+key)
  var hidden_by_long=key!="single_leg_long" and "single_leg_long" in active_composite_layers
  layer.visible=not witch_portrait and variant>=0 and not fixed_portrait and key in active_composite_layers and not hidden_by_long
  layer.position=offset+(single_leg_layers[key].origin-BOUND_CROP)*factor
  layer.scale=factor
