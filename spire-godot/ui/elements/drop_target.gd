extends Button

const DragTargets=preload("res://ui/drag_targets.gd")

var hover_card: Callable
var accept_card: Callable
var receive_card: Callable
var accepted_kind="card"
var drag_payload: Dictionary={}
var drag_label=""

func _get_drag_data(_at_position: Vector2) -> Variant:
 if disabled or drag_payload.is_empty(): return null
 # load() instead of preload() keeps this element scene out of the script's compile-time dependencies.
 var ghost=load("res://ui/elements/drop_target.tscn").instantiate()
 ghost.name="ActionDragPreview";ghost.z_index=240;ghost.position=Vector2(18,18)
 ghost.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ghost.text=drag_label
 ghost.custom_minimum_size=custom_minimum_size
 for state in ["normal","hover","pressed","focus","disabled"]:
  var box=get_theme_stylebox(state)
  if box!=null: ghost.add_theme_stylebox_override(state,box)
 ghost.add_theme_font_size_override("font_size",get_theme_font_size("font_size"))
 ghost.add_theme_color_override("font_color",get_theme_color("font_color"))
 ghost.modulate=Color(1,1,1,0.9)
 set_drag_preview(ghost)
 DragTargets.register_source(self)
 return drag_payload

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
 if not data is Dictionary: return false
 if accepted_kind=="card" and not data.has("card_uid"): return false
 if accepted_kind=="attack" and not data.has("action_type"): return false
 if accepted_kind=="player" and not (data.has("card_uid") or data.has("self_action_id")): return false
 if hover_card.is_valid(): hover_card.call(data)
 return accept_card.is_valid() and accept_card.call(data)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
 if receive_card.is_valid(): receive_card.call(data)
