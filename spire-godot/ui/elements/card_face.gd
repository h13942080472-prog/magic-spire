extends Button

const Palette=preload("res://ui/visual_theme.gd")
const DragTargets=preload("res://ui/drag_targets.gd")
const ILLUSTRATIONS={
 "hannya_1":preload("res://assets/ui/cards/hannya_1.svg"),
 "hannya_2":preload("res://assets/ui/cards/hannya_2.svg"),
 "hannya_3":preload("res://assets/ui/cards/hannya_3.svg"),
 "hannya_4":preload("res://assets/ui/cards/hannya_4.svg"),
 "good_soup":preload("res://assets/ui/cards/good_soup.svg"),
 "hannya_swallow":preload("res://assets/ui/cards/light_as_swallow.svg"),
 "hannya_infusion":preload("res://assets/ui/cards/infusion.svg"),
 "hannya_henshin":preload("res://assets/ui/cards/henshin.svg"),

 "siphon_strength":preload("res://assets/ui/cards/siphon_strength.svg"),
 "shared_fate":preload("res://assets/ui/cards/shared_fate.svg"),
 "magic_hand":preload("res://assets/ui/cards/magic_hand.svg"),
 "magic_hand_gift":preload("res://assets/ui/cards/magic_hand.svg"),
 "leverage":preload("res://assets/ui/cards/leverage.svg"),
 "light_as_swallow":preload("res://assets/ui/cards/light_as_swallow.svg"),
 "restraint_embrace":preload("res://assets/ui/cards/restraint_embrace.svg"),
 "infusion":preload("res://assets/ui/cards/infusion.svg"),
 "siphon":preload("res://assets/ui/cards/siphon.svg"),
 "concentration":preload("res://assets/ui/cards/concentration.svg"),
 "mana_circuit":preload("res://assets/ui/cards/mana_circuit.svg"),
 "breath_control":preload("res://assets/ui/cards/breath_control.svg"),
 "ready_to_strike":preload("res://assets/ui/cards/ready_to_strike.svg"),
 "crossed_legs":preload("res://assets/ui/cards/crossed_legs.svg"),
 "mana_search":preload("res://assets/ui/cards/mana_search.svg"),
 "pot_of_greed":preload("res://assets/ui/cards/pot_of_greed.svg"),
 "repeated_strain":preload("res://assets/ui/cards/repeated_strain.svg"),
 "echo_cast":preload("res://assets/ui/cards/echo_cast.svg"),
 "embers":preload("res://assets/ui/cards/embers.svg"),
 "wildfire_descent":preload("res://assets/ui/cards/wildfire_descent.svg"),
 "boar_emperor_blaze":preload("res://assets/ui/cards/boar_emperor_blaze.svg"),
 "adaptability":preload("res://assets/ui/cards/adaptability.svg"),
 "rekindle":preload("res://assets/ui/cards/rekindle.svg"),
 "fire_dynamics":preload("res://assets/ui/cards/fire_dynamics.svg"),
 "flame_flourish":preload("res://assets/ui/cards/flame_flourish.svg"),
 "letter_opener":preload("res://assets/ui/cards/letter_opener.svg"),
 "fire_control":preload("res://assets/ui/cards/fire_control.svg"),
 "mana_invocation":preload("res://assets/ui/cards/mana_invocation.svg"),
 "mana_surge":preload("res://assets/ui/cards/mana_surge.svg"),
 "mana_conversion":preload("res://assets/ui/cards/mana_conversion.svg"),
 "pleasure_conversion":preload("res://assets/ui/cards/pleasure_conversion.svg"),
 "henshin":preload("res://assets/ui/cards/henshin.svg"),
 "fire_mastery":preload("res://assets/ui/cards/fire_mastery.svg"),
 "binding_enthusiast":preload("res://assets/ui/cards/binding_enthusiast.svg"),
 "strong_elbow":preload("res://assets/ui/cards/strong_elbow.svg"),
 "strain":preload("res://assets/ui/cards/strain.svg"),
 "slip":preload("res://assets/ui/cards/slip.svg"),
 "ease":preload("res://assets/ui/cards/ease.svg"),
 "unlock":preload("res://assets/ui/cards/unlock.svg"),
 "brace":preload("res://assets/ui/cards/brace.svg"),
 "inch":preload("res://assets/ui/cards/inch.svg"),
 "magic_slip":preload("res://assets/ui/cards/magic_slip.svg"),
 "focus":preload("res://assets/ui/cards/focus.svg"),
 "tear":preload("res://assets/ui/cards/tear.svg"),
 "chain":preload("res://assets/ui/cards/chain.svg"),
 "peel":preload("res://assets/ui/cards/peel.svg"),
 "double_unlock":preload("res://assets/ui/cards/double_unlock.svg"),
 "panic":preload("res://assets/ui/cards/panic.svg"),
 "sensitive":preload("res://assets/ui/cards/sensitive.svg"),
 "lewd_mark":preload("res://assets/ui/cards/lewd_mark.svg"),
 "tease":preload("res://assets/ui/cards/tease.svg"),
 "tease_plus":preload("res://assets/ui/cards/tease_plus.svg"),
}

signal flip_requested
signal drag_began(data: Dictionary)

const RARITY_COLORS={"special":Color("b7d8ce"),"basic":Color("bec3c8"),"common":Color("bec3c8"),"uncommon":Color("77b8ed"),"rare":Color("d5b86d"),"curse":Color("b091c8"),"status":Color("bec3c8")}
var rarity="basic"
var single_face=false
var symbol="strain"
var art_settings
var home=Vector2.ZERO
var resting_angle=0.0
var chosen=false
var tween: Tween
var drag_payload: Dictionary={}
var display_name=""
var free_face=false
var effect_free=false
var face_name="拘束"
var lift_on_hover=true
var ui_state="normal"

func set_ui_state(state: String) -> void:
 ui_state=state
 queue_redraw()
const ART_HEIGHT_RATIO=2.0/3.0
const ART_HEIGHT_OVERRIDES={"binding_enthusiast":0.58}
var art_bottom=174.0

const MANA_COLORS={"cost":Color("8dd6ef"),"gain":Color("80e0c5"),"temporary":Color("c4a0ef")}

func set_mana(entries: Array) -> void:
 var group=get_node_or_null("CardMana")
 if group==null:
  group=HBoxContainer.new();group.name="CardMana"
  group.add_theme_constant_override("separation",3)
  group.mouse_filter=Control.MOUSE_FILTER_IGNORE
  add_child(group)
 for child in group.get_children(): group.remove_child(child);child.queue_free()
 group.visible=not entries.is_empty()
 for entry in entries:
  var badge=PanelContainer.new();badge.name="Mana_"+entry.kind
  badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
  badge.tooltip_text=entry.detail
  var style=StyleBoxFlat.new()
  style.bg_color=Color("29233e") if entry.kind=="temporary" else Color("143542")
  style.border_color=MANA_COLORS[entry.kind]
  style.set_border_width_all(2);style.set_corner_radius_all(7 if entry.kind=="temporary" else 18)
  style.content_margin_left=6;style.content_margin_right=6
  badge.add_theme_stylebox_override("panel",style)
  var label=Label.new();label.text=entry.text
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  label.add_theme_color_override("font_color",MANA_COLORS[entry.kind])
  var font=label.get_theme_font("font")
  var font_size=21
  while font_size>13 and font.get_string_size(entry.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>49: font_size-=1
  label.add_theme_font_size_override("font_size",font_size)
  badge.custom_minimum_size=Vector2(38,36)
  badge.add_child(label);group.add_child(badge)
 _layout_header()

func _layout_header() -> void:
 var title=get_node_or_null("CardTitle")
 if title==null: return
 var group=get_node_or_null("CardMana")
 var right=size.x-5
 if group!=null and group.visible:
  group.size=group.get_combined_minimum_size()
  group.position=Vector2(size.x-group.size.x-1,1)
  right=group.position.x-4
 var width=maxf(1,right-title.position.x)
 title.clip_text=true
 var full_title=display_name if display_name!="" else title.text.replace("\n","")
 title.text=full_title
 title.autowrap_mode=TextServer.AUTOWRAP_OFF
 title.position.y=10
 var title_height=31.0
 title.add_theme_constant_override("line_spacing",0)
 var font_size=17
 while font_size>11 and title.get_theme_font("font").get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width: font_size-=1
 title.add_theme_font_size_override("font_size",font_size)
 # Long names use the existing header height instead of pushing into mana badges.
 if title.get_theme_font("font").get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:
  var separator=full_title.find("（")
  if separator<0: separator=full_title.find("(")
  if separator>0: title.text=full_title.substr(0,separator)+"\n"+full_title.substr(separator)
  title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  title.position.y=1;title_height=40
 title.size=Vector2(width,title_height)

# The illustration keeps its share even when a face has long requirements.
func _layout_art() -> void:
 art_bottom=6.0+size.y*ART_HEIGHT_OVERRIDES.get(symbol,ART_HEIGHT_RATIO)
 var picture=get_node_or_null("CardIllustration")
 if picture!=null:
  # Existing artwork is mostly landscape: fit both axes, below the header.
  picture.position=Vector2(8,42)
  picture.size=Vector2(maxf(1,size.x-16),maxf(1,art_bottom-42))
 var header=get_node_or_null("CardHeader")
 if header!=null: header.queue_redraw()
 queue_redraw()

func fit_text() -> void:
 _layout_header()
 _layout_art()
 var area=get_node_or_null("CardText")
 if area==null: return
 area.position=Vector2(12,art_bottom+4)
 area.size=Vector2(size.x-24,maxf(1,size.y-area.position.y-8))
 var effect=area.get_node_or_null("Content/CardEffect")
 if effect!=null: effect.add_theme_font_size_override("font_size",13)

func _draw_header() -> void:
 var header=get_node("CardHeader")
 var accent=RARITY_COLORS[rarity]
 header.draw_rect(Rect2(8,6,size.x-16,35),Color("142c36") if effect_free else Color("17222f"))
 header.draw_line(Vector2(8,40),Vector2(size.x-8,40),Color(accent,0.55),1,true)
 header.draw_circle(Vector2(19,19),20,Color("102634") if effect_free else Color("2f2b25"))
 header.draw_arc(Vector2(19,19),19,0,TAU,32,accent,2,true)
 header.draw_arc(Vector2(19,19),15,0,TAU,32,Color(accent,0.4),1,true)

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
  accept_event()
  flip_requested.emit()

func _get_drag_data(_at_position: Vector2) -> Variant:
 if drag_payload.is_empty(): return null
 # load() instead of preload() keeps this element scene out of the script's compile-time dependencies.
 var ghost=load("res://ui/elements/card_face.tscn").instantiate()
 ghost.name="CardDragPreview";ghost.z_index=240;ghost.position=Vector2(18,18)
 ghost.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ghost.lift_on_hover=false;ghost.chosen=false
 ghost.symbol=symbol;ghost.rarity=rarity;ghost.free_face=free_face
 ghost.display_name=display_name;ghost.face_name=face_name;ghost.effect_free=effect_free
 ghost.single_face=single_face
 ghost.size=size
 var ghost_cost=ghost.get_node("CardCost")
 ghost_cost.text=$CardCost.text;ghost_cost.position=$CardCost.position;ghost_cost.size=$CardCost.size
 ghost_cost.horizontal_alignment=$CardCost.horizontal_alignment
 ghost_cost.add_theme_font_size_override("font_size",$CardCost.get_theme_font_size("font_size"))
 ghost_cost.add_theme_color_override("font_color",$CardCost.get_theme_color("font_color"))
 var ghost_title=ghost.get_node("CardTitle")
 ghost_title.text=$CardTitle.text;ghost_title.position=$CardTitle.position;ghost_title.size=$CardTitle.size
 ghost_title.autowrap_mode=$CardTitle.autowrap_mode
 ghost_title.add_theme_font_size_override("font_size",$CardTitle.get_theme_font_size("font_size"))
 ghost_title.add_theme_color_override("font_color",$CardTitle.get_theme_color("font_color"))
 var source_area=$CardText
 var ghost_area=ghost.get_node("CardText")
 ghost_area.position=source_area.position;ghost_area.size=source_area.size
 ghost_area.horizontal_scroll_mode=source_area.horizontal_scroll_mode
 ghost_area.vertical_scroll_mode=source_area.vertical_scroll_mode
 ghost_area.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var ghost_content=ghost.get_node("CardText/Content")
 var source_content=source_area.get_node("Content")
 ghost_content.custom_minimum_size=source_content.custom_minimum_size
 for child in source_content.get_children(): ghost_content.add_child(child.duplicate())
 ghost.modulate=Color(1,1,1,0.9)
 set_drag_preview(ghost)
 drag_began.emit(drag_payload)
 DragTargets.register_source(self)
 return drag_payload

func _ready() -> void:
 mouse_entered.connect(func(): _hover(true))
 mouse_exited.connect(func(): _hover(false))
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var illustration=$CardIllustration
 illustration.texture=ILLUSTRATIONS.get(symbol)
 illustration.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 illustration.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 illustration.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 illustration.clip_contents=true
 illustration.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if art_settings!=null:
  art_settings.art_changed.connect(_art_changed)
  _art_changed("cards",symbol)
 var header=$CardHeader
 header.mouse_filter=Control.MOUSE_FILTER_IGNORE
 header.draw.connect(_draw_header)
 _layout_art()
 resized.connect(fit_text)

func _art_changed(category: String, id: String) -> void:
 if category!="cards" or id!=symbol: return
 var texture=art_settings.art_texture(category,id)
 $CardIllustration.texture=texture if texture!=null else ILLUSTRATIONS.get(symbol)

func _hover(raised: bool) -> void:
 if not lift_on_hover: return
 if is_instance_valid(tween): tween.kill()
 tween=create_tween().set_parallel(true)
 tween.tween_property(self,"position",home+Vector2(0,-44 if raised else 0),0.13)
 tween.tween_property(self,"rotation",0.0 if raised else resting_angle,0.13)
 z_index=100 if raised else (20 if chosen else 0)

func _draw() -> void:
 var accent=RARITY_COLORS[rarity]
 var outline=PackedVector2Array([Vector2(11,0),Vector2(size.x-11,0),Vector2(size.x,11),Vector2(size.x,size.y-11),Vector2(size.x-11,size.y),Vector2(11,size.y),Vector2(0,size.y-11),Vector2(0,11)])
 var shadow=outline.duplicate()
 for i in range(shadow.size()): shadow[i]+=Vector2(3,6)
 draw_colored_polygon(shadow,Color(0.015,0.023,0.03,0.75))
 draw_colored_polygon(outline,Color("193c43") if effect_free else Color("393127"))
 var closed=outline.duplicate();closed.append(outline[0])
 draw_polyline(closed,Palette.CYAN if chosen else accent,2,true)
 draw_rect(Rect2(6,6,size.x-12,size.y-12),Color("142c36") if effect_free else Color("17222f"))
 draw_rect(Rect2(8,6,size.x-16,art_bottom-6),Color("24515a") if effect_free else Color("3b3b37"))
 for i in range(9):
  var alpha=0.08*(1-float(i)/9)
  var band=(art_bottom-43)/9
  draw_rect(Rect2(8,42+i*band,size.x-16,band),Color(accent,alpha))
 draw_line(Vector2(8,art_bottom),Vector2(size.x-8,art_bottom),Color(accent,0.7),1,true)
 # Foil corner brackets distinguish the two faces even with illustration overlap.
 for side in [-1,1]:
  var x=10 if side<0 else size.x-10
  draw_line(Vector2(x,10),Vector2(x,31),accent,1,true)
  draw_line(Vector2(x,size.y-25),Vector2(x,size.y-10),accent,1,true)
  draw_line(Vector2(x,size.y-10),Vector2(x-side*17,size.y-10),accent,1,true)
 # Self-drawn states stay in colour and line weight, so size and position never move.
 if ui_state=="hover" or ui_state=="pressed":
  draw_polyline(closed,Palette.CYAN,3 if ui_state=="pressed" else 2,true)
