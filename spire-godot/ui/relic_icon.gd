extends Control

# Only renders the counter supplied by the shared relic projection.
const ART={
 "pleading_face":preload("res://assets/ui/relics/pleading_face.svg"),
 "sweat_smile":preload("res://assets/ui/relics/sweat_smile.svg"),
 "weary_face":preload("res://assets/ui/relics/weary_face.svg"),
 "rolling_eyes":preload("res://assets/ui/relics/rolling_eyes.svg"),
 "joy_face":preload("res://assets/ui/relics/joy_face.svg"),
 "fearful_face":preload("res://assets/ui/relics/fearful_face.svg"),
 "money_face":preload("res://assets/ui/relics/money_face.png"),
 "cool_face":preload("res://assets/ui/relics/cool_face.svg"),
 "monocle_face":preload("res://assets/ui/relics/monocle_face.svg"),
 "hot_face":preload("res://assets/ui/relics/hot_face.png"),
 "flint_lighter":preload("res://assets/ui/relics/flint_lighter.svg"),
 "fire_torch":preload("res://assets/ui/relics/fire_torch.svg"),
 "flame_mark":preload("res://assets/ui/relics/flame_mark.svg"),
 "fireball_pamphlet":preload("res://assets/ui/relics/fireball_pamphlet.svg"),
 "hotpot_base":preload("res://assets/ui/relics/hotpot_base.svg"),

 "brainwash_earrings":preload("res://assets/ui/relics/brainwash_earrings.svg"),
 "hypnosis_hairpin":preload("res://assets/ui/relics/hypnosis_hairpin.svg"),
 "lewd_silk_bodysuit":preload("res://assets/ui/relics/lewd_silk_bodysuit.svg"),
 "lewd_silk_gloves":preload("res://assets/ui/relics/lewd_silk_gloves.svg"),

 "lucidity_necklace":preload("res://assets/ui/relics/lucidity_necklace.svg"),
 "edging_seal":preload("res://assets/ui/relics/edging_seal.svg"),
 "pleasure_extractor":preload("res://assets/ui/relics/pleasure_extractor.svg"),
 "desire_cube_pro_max":preload("res://assets/ui/relics/desire_cube_pro_max.svg"),
 "scrap_robot":preload("res://assets/ui/relics/scrap_robot.svg"),
 "ditto":preload("res://assets/ui/relics/ditto.svg"),
 "doubao":preload("res://assets/ui/relics/doubao.png"),
 "deepseek":preload("res://assets/ui/relics/deepseek.png"),
 "masochist_mark":preload("res://assets/ui/relics/masochist_mark.svg"),
 "universal_scanner":preload("res://assets/ui/relics/universal_scanner.svg"),
 "sundial":preload("res://assets/ui/relics/sundial.svg"),
 "membership_card":preload("res://assets/ui/relics/membership_card.svg"),
 "great_wand":preload("res://assets/ui/relics/great_wand.svg"),
 "secret_weapon":preload("res://assets/ui/relics/secret_weapon.svg"),
 "witch_amulet":preload("res://assets/ui/relics/witch_amulet.svg"),
 "witch_noodles":preload("res://assets/ui/relics/witch_noodles.svg"),
 "cursed_plate_lock":preload("res://assets/ui/relics/cursed_plate_lock.svg"),
 "gourd_flask":preload("res://assets/ui/relics/gourd_flask.svg"),
 "shrimp_paste":preload("res://assets/ui/relics/shrimp_paste.svg"),
 "magnifying_glass":preload("res://assets/ui/relics/magnifying_glass.svg"),
 "axe_amulet":preload("res://assets/ui/relics/axe_amulet.svg"),
 "oune_hand":preload("res://assets/ui/relics/oune_hand.svg"),
 "m_donalds":preload("res://assets/ui/relics/m_donalds.svg"),
 "tattoo_sticker":preload("res://assets/ui/relics/tattoo_sticker.svg"),
 "cursed_blindfold":preload("res://assets/ui/relics/cursed_blindfold.svg"),
 "nesting_doll":preload("res://assets/ui/relics/nesting_doll.svg"),
 "binding_pyramid":preload("res://assets/ui/relics/binding_pyramid.svg"),
 "shining_lamp":preload("res://assets/ui/relics/shining_lamp.svg"),

 "ice_heart":preload("res://assets/ui/relics/ice_heart.svg"),
 "magic_blood":preload("res://assets/ui/relics/magic_blood.svg"),
 "power_tonic":preload("res://assets/ui/relics/power_tonic.svg"),
 "turtle_shell":preload("res://assets/ui/relics/turtle_shell.svg"),
 "olihakimi":preload("res://assets/ui/relics/olihakimi.svg"),
 "green_bird":preload("res://assets/ui/relics/green_bird.svg"),
 "braised_eggplant":preload("res://assets/ui/relics/braised_eggplant.svg"),
 "tentacle_friend":preload("res://assets/ui/relics/tentacle_friend.svg"),
 "spicy_rice_noodles":preload("res://assets/ui/relics/spicy_rice_noodles.svg"),
 "flyer":preload("res://assets/ui/relics/flyer.svg"),
 "pocket_knife":preload("res://assets/ui/relics/pocket_knife.svg"),
 "kings_gift_revised":preload("res://assets/ui/relics/kings_gift_revised.svg"),
 "rolling_log":preload("res://assets/ui/relics/rolling_log.svg"),
 "marble":preload("res://assets/ui/relics/broccoli.svg"),
 "marble_stone":preload("res://assets/ui/relics/marble.svg"),
 "graduate_certificate":preload("res://assets/ui/relics/graduate_certificate.svg"),
 "little_pig":preload("res://assets/ui/relics/little_pig.svg"),
 "small_gem":preload("res://assets/ui/relics/small_gem.svg"),
 "happy_fa":preload("res://assets/ui/happy-fa.svg"),
 "desire_cube":preload("res://assets/ui/relics/desire_cube.svg"),
 "casting_manual":preload("res://assets/ui/relics/casting_manual.svg"),
 "enchanters_needle_case":preload("res://assets/ui/relics/enchanters_needle_case.svg"),
 "softened_buckle":preload("res://assets/ui/relics/softened_buckle.svg"),
 "mana_earring":preload("res://assets/ui/relics/mana_earring.svg"),
 "ready_backpack":preload("res://assets/ui/relics/ready_backpack.svg"),
 "smooth_stockings":preload("res://assets/ui/relics/smooth_stockings.svg"),
 "donut":preload("res://assets/ui/relics/donut.svg"),
 "small_sigil":preload("res://assets/ui/relics/small_sigil.svg"),
 "martial_book":preload("res://assets/ui/relics/martial_book.svg"),
 "wrist_bracer":preload("res://assets/ui/relics/wrist_bracer.svg"),
 "wraith_ribbon":preload("res://assets/ui/relics/wraith_ribbon.svg"),
 "ethereal_pendant":preload("res://assets/ui/relics/ethereal_pendant.svg"),
 "intellect_cloak":preload("res://assets/ui/relics/intellect_cloak.svg"),
 "strawberry":preload("res://assets/ui/relics/strawberry.svg"),
 "break_bracer":preload("res://assets/ui/relics/break_bracer.svg"),
 "silk_ring":preload("res://assets/ui/relics/silk_ring.svg"),
 "turn_ribbon":preload("res://assets/ui/relics/turn_ribbon.svg"),
 "ember_crystal":preload("res://assets/ui/relics/ember_crystal.svg"),
 "ember":preload("res://assets/ui/relics/ember.svg"),
 "toolbox":preload("res://assets/ui/relics/toolbox.svg"),
 "incense":preload("res://assets/ui/relics/incense.svg"),
 "hourglass":preload("res://assets/ui/relics/hourglass.svg"),
}
var relic: Dictionary={}
var glyph: Control
var badge: Label

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var art_id=relic.get("icon",relic.get("id",""))
 if ART.has(art_id):
  var picture=TextureRect.new();picture.texture=ART[art_id];picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  if art_id in ["doubao","deepseek"]: picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;glyph=picture
 else:
  glyph=preload("res://ui/shop_glyph.gd").new()
  if art_id=="return_seal": glyph.kind="tool";glyph.symbol="return_scroll"
 glyph.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(glyph)
 if not relic.get("counter",{}).is_empty():
  badge=Label.new();badge.name="RelicCounter";badge.text=relic.counter.text
  badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
  badge.add_theme_font_size_override("font_size",12);badge.add_theme_color_override("font_color",Color("fff0bf"))
  var style=StyleBoxFlat.new();style.bg_color=Color("101924");style.border_color=Color("c9ad79");style.set_border_width_all(1);style.set_corner_radius_all(4)
  style.content_margin_left=3;style.content_margin_right=3
  badge.add_theme_stylebox_override("normal",style);add_child(badge)
 resized.connect(_fit);_fit()

func _fit() -> void:
 glyph.size=Vector2(64,64);glyph.scale=size/64.0
 if is_instance_valid(badge):
  badge.size=Vector2(maxf(22,badge.get_minimum_size().x),18)
  badge.position=size-badge.size
