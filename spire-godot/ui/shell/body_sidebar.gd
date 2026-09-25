extends PanelContainer

const Palette=preload("res://ui/visual_theme.gd")
const TOP=34.0
const BOTTOM=12.0
const GAP=7.0
const CHILD_GAP=4.0
const COLUMN_X=223.0
const COLUMN_WIDTH=128.0
const REGION_ORDER={"region_head":0,"region_upper":1,"region_intimate":2,"region_lower":3}
@export var expanded_height=836.0
var portrait_expanded=false
var _compact_rect: Rect2
var _compact_portrait_rect: Rect2
var _compact_z=20
var _ui
var _last_height=-1.0
var _last_focus=""
var _last_detail_visible=false
var _slots_key: Array=[]
var _button_index: Dictionary={}

static func expand_applied(ui, before: Dictionary, after: Dictionary) -> void:
 # Only committed battle actions call this. Compare projected physical IDs,
 # so equal-count replacement and shared/link components are not missed.
 if before.phase!="battle" or after.phase not in ["battle","prepare","reward"]: return
 var previous={}
 for region in before.body_regions: previous[region.id]=region.targets
 for region in after.body_regions:
  var known=previous.get(region.id,{})
  if region.targets.keys().any(func(id):return not known.has(id)):
   ui.expanded_body_regions.erase(region.id)
   ui.expanded_body_regions.append(region.id)

func _ready() -> void:
 add_theme_stylebox_override("panel",Palette.window_frame())
 for state in ["normal","hover","pressed","focus","disabled"]:
  var style=Palette.button_style(state,Palette.CYAN)
  for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_content_margin(side,4)
  $Canvas/ExpandPortrait.add_theme_stylebox_override(state,style)
 $Canvas/ExpandPortrait.pressed.connect(_expand_portrait)
 resized.connect(func():call_deferred("_resize_regions"))

func _resize_regions() -> void:
 if portrait_expanded: return
 if is_instance_valid(_ui) and not is_equal_approx(size.y,_last_height): configure(_ui)

func _expand_portrait() -> void:
 set_portrait_expanded(true)
 _ui.show_body=false
 _ui._hide_term()
 _ui.render(_ui.view)

func set_portrait_expanded(expanded: bool) -> void:
 if portrait_expanded==expanded: return
 portrait_expanded=expanded
 $Canvas/PortraitBackdrop.visible=expanded
 var portrait=$Canvas/EquipmentPortrait
 if expanded:
  _ui.keyboard_input.clear(true)
  _compact_z=z_index;z_index=225
  _compact_rect=Rect2(position,size)
  _compact_portrait_rect=Rect2(portrait.position,portrait.size)
  size.y=expanded_height
  portrait.position=Vector2.ZERO
  portrait.size=size-get_theme_stylebox("panel").get_minimum_size()
 else:
  z_index=_compact_z
  position=_compact_rect.position;size=_compact_rect.size
  portrait.position=_compact_portrait_rect.position;portrait.size=_compact_portrait_rect.size
 for node in [$Canvas/Title,$Canvas/Divider,$Canvas/Slots,$Canvas/ExpandPortrait]: node.visible=not expanded

func handle_portrait_input(event: InputEvent) -> bool:
 if not portrait_expanded: return false
 if event.is_action_pressed("ui_cancel"):
  set_portrait_expanded(false)
 elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]:
  if not get_global_rect().has_point(event.position): set_portrait_expanded(false)
 elif event is InputEventScreenTouch and event.pressed:
  if not get_global_rect().has_point(event.position): set_portrait_expanded(false)
 # Inspection consumes input before shortcuts or underlying action controls.
 return true

func _toggle(ui, id: String) -> void:
 if id in ui.expanded_body_regions:
  ui.expanded_body_regions.erase(id)
  if _region_for(ui,ui.selected_slot)==id: ui.show_body=false
 else:
  ui.expanded_body_regions.append(id)
  ui.selected_slot=id;ui.selected_candidate="";ui.player_pick=false;ui.show_body=true
 ui.render(ui.view)

func _region_for(ui, slot: String) -> String:
 var body=ui._body_at(slot)
 for region in ui.view.body_regions:
  if region.id==body.id or region.members.any(func(member):return member.id==body.id): return region.id
 return ""

func _drop_callbacks(ui, button, id: String) -> void:
 button.set_meta("body_id",id);button.accepted_kind="any"
 button.hover_card=func(data):ui._show_drop_targets(id,data)
 button.accept_card=func(data):
  var candidate=ui._free_player_candidate(data,id)
  return not candidate.is_empty() and candidate.valid
 button.receive_card=func(data):
  var candidate=ui._free_player_candidate(data,id)
  if not candidate.is_empty() and candidate.valid:ui.command_router.emit_deferred(String(candidate.payload.get("kind","")),candidate,int(data.version))

func _presentation_key(ui) -> Array:
 # Only rendered facts: never retain an old View, candidate, or equipment graph.
 var regions=[]
 for region in ui.view.body_regions:
  var members=[]
  for body in region.members:
   members.append([body.id,body.name,body.count,body.occupied,not body.links.is_empty(),body.can_release,body.slots.duplicate()])
  regions.append([region.id,region.name,region.count,members])
 return [size.y,ui.localization.locale,ui._body_at(ui.selected_slot).id,ui.expanded_body_regions.duplicate(),regions]

func configure(ui) -> void:
 _ui=ui;_last_height=size.y
 $Canvas/Title.text=ui.localization.display("身体与拘束具")
 $Canvas/Title.add_theme_color_override("font_color",ui.GOLD)
 $Canvas/Divider.color=ui.GOLD.darkened(0.65)
 $Canvas/EquipmentPortrait.configure(ui.view,ui.EquipmentPortrait.uses_fixed_portrait(ui.view,ui.display_settings.fixed_hero_portrait))
 $Canvas/ExpandPortrait.tooltip_text=ui.localization.text("ui.portrait.expand","放大立绘")
 if portrait_expanded:
  ui.body_buttons.merge(_button_index,true)
  return
 var focus=_region_for(ui,ui.selected_slot)
 # Only an explicit change of inspection opens a region. A routine refresh
 # must not reopen a region previously evicted by the height budget.
 if ui.show_body and (focus!=_last_focus or not _last_detail_visible) and focus!="" and focus not in ui.expanded_body_regions:
  ui.expanded_body_regions.append(focus)
 _last_focus=focus;_last_detail_visible=ui.show_body
 if _slots_key==_presentation_key(ui):
  ui.body_buttons.merge(_button_index,true)
  return
 var slots=$Canvas/Slots
 _button_index.clear()
 for child in slots.get_children():
  slots.remove_child(child);child.queue_free()
 var rows={};var base_height=0.0
 var ordered_regions=ui.view.body_regions.duplicate()
 ordered_regions.sort_custom(func(a,b):return REGION_ORDER.get(a.id,99)<REGION_ORDER.get(b.id,99))
 for region in ordered_regions:
  var region_id=region.id
  var header=ui._button(region.name+"  "+str(region.count)+"  ›",func():_toggle(ui,region_id),ui.GOLD,true)
  header.name="BodyRegion_"+region.id;header.custom_minimum_size=Vector2(COLUMN_WIDTH,40)
  header.clip_text=true
  header.add_theme_font_size_override("font_size",11 if header.text.length()>14 else 16)
  _drop_callbacks(ui,header,region.id);slots.add_child(header)
  var scroller=ScrollContainer.new();scroller.name="BodyRegionContent_"+region.id
  scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
  slots.add_child(scroller)
  var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  column.add_theme_constant_override("separation",3);scroller.add_child(column)
  var children=[]
  for body in region.members:
   var body_id=body.id
   var button=ui._button(body.name+("  "+str(body.count) if body.occupied else "")+("·链" if not body.links.is_empty() else ""),func():
    ui.show_body=not ui.show_body if ui._body_at(ui.selected_slot).id==body_id else true
    ui.selected_slot=body_id;ui.selected_candidate="";ui.player_pick=false;ui.render(ui.view),ui.CYAN if body.id==ui._body_at(ui.selected_slot).id else (ui.GOLD if body.occupied else ui.MUTED.darkened(0.5)),true)
   button.name="BodySlot_"+body.id;button.custom_minimum_size=Vector2(0,32);button.clip_text=true
   button.add_theme_font_size_override("font_size",14)
   for state in ["normal","hover","pressed","focus","disabled"]:
    var style=button.get_theme_stylebox(state).duplicate()
    style.content_margin_top=4;style.content_margin_bottom=4
    style.content_margin_left=6;style.content_margin_right=6
    button.add_theme_stylebox_override(state,style)
   button.tooltip_text=body.name+(" · %d件" % body.count if body.occupied else " · 自由")
   if body.can_release:
    var style=button.get_theme_stylebox("normal").duplicate()
    style.bg_color=Color("254b50");style.border_color=ui.CYAN
    button.add_theme_stylebox_override("normal",style);button.tooltip_text+=" · 可一键解除"
   button.set_meta("can_release",body.can_release)
   _drop_callbacks(ui,button,body.id);column.add_child(button)
   children.append({"body":body,"button":button})
  rows[region.id]={"region":region,"header":header,"scroller":scroller,"children":children,"height":column.get_combined_minimum_size().y,"header_height":header.get_combined_minimum_size().y}
  base_height+=rows[region.id].header_height+GAP
 ui.expanded_body_regions=ui.expanded_body_regions.filter(func(id):return rows.has(id))
 var available=size.y-get_theme_stylebox("panel").get_minimum_size().y-TOP-BOTTOM
 var required=base_height
 for id in ui.expanded_body_regions: required+=rows[id].height+CHILD_GAP
 while required>available+0.01 and ui.expanded_body_regions.size()>1:
  var oldest=ui.expanded_body_regions.pop_front()
  required-=rows[oldest].height+CHILD_GAP
 var y=TOP
 for id in rows:
  var row=rows[id];var active=id in ui.expanded_body_regions
  var header=row.header
  header.text=ui.localization.display(row.region.name+"  "+str(row.region.count)+("  −" if active else "  ›"))
  if active: header.add_theme_stylebox_override("normal",Palette.button_style("normal",ui.CYAN))
  header.position=Vector2(COLUMN_X,y);header.size=Vector2(COLUMN_WIDTH,row.header_height)
  ui.body_buttons[id]=header;y+=row.header_height
  row.scroller.visible=active
  if active:
   # Very short panels scroll inside the newest region instead of clipping it.
   var height=minf(row.height,maxf(1.0,available-base_height-CHILD_GAP)) if ui.expanded_body_regions.size()==1 else row.height
   y+=CHILD_GAP;row.scroller.position=Vector2(COLUMN_X+4,y)
   row.scroller.size=Vector2(COLUMN_WIDTH-4,height);y+=height
  y+=GAP
  for child in row.children:
   var body=child.body
   ui.body_buttons[body.id]=child.button if active else header
   for alias in body.slots:ui.body_buttons[alias]=ui.body_buttons[body.id]
 _button_index=ui.body_buttons.duplicate()
 _slots_key=_presentation_key(ui)
