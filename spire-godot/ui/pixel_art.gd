extends RefCounted

# Source atlases stay unchanged; the view selects regions without touching game state.
const DUNGEON=preload("res://assets/vendor/0x72/dungeon.png")
const HERO_POSES={
 "stand":preload("res://assets/art/hero-stand-cutout-v2.png"),
 "sit":preload("res://assets/art/hero-sit-cutout-v2.png"),
 "lie":preload("res://assets/art/hero-lie-cutout-v2.png")}
const WITCH_POSES={
 "stand":preload("res://assets/art/witch-stand-cutout-v1.png"),
 "sit":preload("res://assets/art/witch-sit-cutout-v1.png"),
 "lie":preload("res://assets/art/witch-lie-cutout-v1.png")}
const HERO_RESTRAINED_POSES={
 "sit":preload("res://assets/art/hero-restrained-sit-v1.png"),
 "lie":preload("res://assets/art/hero-restrained-lie-v1.png")}
const HERO_SPECIAL_POSES={
 "hogtie":preload("res://assets/art/hero-hogtie-pose-cutout-v1.png")}
# Independent source canvases use calibrated apparent heights, never stretched axes.
const HERO_HEIGHTS={"stand":1.0,"sit":0.73,"lie":0.68}
const HERO_FACE=Rect2(344,164,260,260)
const BACKGROUND=preload("res://assets/art/moonlit-gallery-v1.png")
const GUARD_PORTRAITS={
 "guard_purple":preload("res://assets/art/enemy-guards-v1/guard-purple-v1.png"),
 "guard_brown":preload("res://assets/art/enemy-guards-v1/guard-brown-v1.png")}
const SUCCUBUS_GUARD_PORTRAITS={
 "guard_purple":preload("res://assets/art/enemy-succubus-guards-v1/succubus-purple-v1.png"),
 "guard_brown":preload("res://assets/art/enemy-succubus-guards-v1/succubus-brown-v1.png")}
static func hero_texture(pose: String, has_restraint_level: bool=false, character_id: String="original") -> Texture2D:
 if character_id=="witch": return WITCH_POSES[pose]
 if has_restraint_level and HERO_RESTRAINED_POSES.has(pose): return HERO_RESTRAINED_POSES[pose]
 return HERO_POSES[pose]
const REGIONS={
 "wall":Rect2(32,16,16,16),"wall_top":Rect2(32,0,16,16),
 "floor":Rect2(16,64,16,16),"floor_crack":Rect2(32,64,16,16),
 "column":Rect2(80,80,16,48),"banner":Rect2(32,32,16,16),
 "door":Rect2(32,224,32,48),"skull":Rect2(293,439,6,6),
 "flask":Rect2(304,352,16,16)}

static func draw(canvas: CanvasItem, key: String, rect: Rect2, tint: Color=Color.WHITE) -> void:
 canvas.draw_texture_rect_region(DUNGEON,rect,REGIONS[key],tint)
