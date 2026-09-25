extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

# UI selection only. Targets, damage and availability always come from the current display facts.
const ORDER=["region_head","region_upper","region_intimate","region_lower"]
const SLOT_ACTIONS=["strike","kick","heavy","fireball"]
const ARROW_WIDTH=28.0
const MODES=Queries.RELEASE_MODES

static func message(ui, key: String, fallback: String, params: Dictionary={}) -> String:
 return ui.localization.text("ui.quick_release."+key,fallback,params)

static func selected_data(ui) -> Dictionary:
 return {"card_uid":ui.selected_card,"free":ui.card_faces.get(ui.selected_card,false),"version":ui.view.version} if ui.selected_card!="" else {}

static func choices(ui, body: Dictionary, data: Dictionary) -> Array:
 return Queries.release_choices(ui.view,body,data,ui.view.version)

static func first(offers: Array) -> Dictionary:
 return Queries.first_usable(offers)

static func body_at(ui, region_id: String) -> Dictionary:
 return _selection(ui,region_id,false).body

# Resolve once per interaction; faces and UI selection may change without a new View version.
static func _selection(ui, region_id: String, with_equipment: bool=true) -> Dictionary:
 var region=ui._body_at(region_id)
 var id=ui.quick_release_parts.get(region_id,"")
 var body: Dictionary={}
 var usable: Dictionary={}
 var scanned=false
 for member in region.members:
  if member.id==id:
   body=member;break
 if body.is_empty():
  usable=_usable_targets(ui);scanned=true
  var targets=_ordered_equipment(region,usable)
  if not targets.is_empty():
   for member in region.members:
    if member.targets.has(targets[0].id):
     body=member;break
  if body.is_empty():body=region.members[0] if not region.members.is_empty() else region
 var result={"region":region,"body":body,"equipment":{}}
 if not with_equipment:return result
 var target=ui.quick_release_targets.get(region_id,"")
 if body.targets.has(target):result.equipment=body.targets[target]
 else:
  if not scanned:usable=_usable_targets(ui)
  var entries=_ordered_equipment(body,usable)
  if not entries.is_empty():result.equipment=entries[0]
 return result

static func _usable_targets(ui) -> Dictionary:
 var usable={}
 for c in Queries.facts(ui.view,"card"):
  if c.valid and c.payload.get("mode","")=="strain" and c.payload.free==ui.card_faces.get(c.payload.uid,false):usable[c.payload.target]=true
 return usable

static func ordered_equipment(ui, body: Dictionary) -> Array:
 return _ordered_equipment(body,_usable_targets(ui))

static func _ordered_equipment(body: Dictionary, usable: Dictionary) -> Array:
 var entries=body.targets.values()
 entries.sort_custom(func(a,b):
  var pa=(0 if a.get("covers",[]).is_empty() and usable.has(a.id) else 1 if usable.has(a.id) else 2)
  var pb=(0 if b.get("covers",[]).is_empty() and usable.has(b.id) else 1 if usable.has(b.id) else 2)
  if pa!=pb:return pa<pb
  if a.tier!=b.tier:return a.tier<b.tier
  if not is_equal_approx(a.ratio,b.ratio):return a.ratio<b.ratio
  return a.sort_order<b.sort_order)
 return entries

static func equipment_at(ui, region_id: String) -> Dictionary:
 return _selection(ui,region_id).equipment

static func idle_candidate(ui, body: Dictionary, target: String) -> Dictionary:
 var offers=Queries.facts(ui.view,"card").filter(func(c):return c.payload.get("mode","") in MODES and c.payload.target==target and body.targets.has(target) and c.payload.free==ui.card_faces.get(c.payload.uid,false))
 return first(offers)

static func candidate(ui, region_id: String, data: Dictionary) -> Dictionary:
 var selection=_selection(ui,region_id)
 return _candidate_for(ui,selection.body,selection.equipment,data)

static func _candidate_for(ui, body: Dictionary, equipment: Dictionary, data: Dictionary) -> Dictionary:
 return Queries.release_candidate(ui.view,body,equipment.get("id",""),data,ui.view.version)

static func cycle(ui, region_id: String, direction: int) -> void:
 var region=ui._body_at(region_id)
 var entries=ordered_equipment(ui,region)
 if entries.is_empty():return
 var ids=entries.map(func(e):return e.id)
 var current=equipment_at(ui,region_id).get("id","")
 var index=ids.find(current)
 if index<0:index=0 if direction<0 else -1
 ui.quick_release_targets[region_id]=ids[posmod(index+direction,ids.size())]
 for body in region.members:
  if body.targets.has(ui.quick_release_targets[region_id]):
   ui.quick_release_parts[region_id]=body.id;break
 select(ui,region_id,true)

static func activate(ui, region_id: String) -> void:
 var details=ui.find_child("EquipmentDetails",true,false)
 var close=ui.quick_release_region==region_id and details!=null and details.is_visible_in_tree()
 select(ui,region_id,not close)

static func select(ui, region_id: String, inspect: bool=true) -> void:
 ui.keyboard_input.clear()
 var selection=_selection(ui,region_id)
 ui.quick_release_region=region_id;ui.quick_release_parts[region_id]=selection.body.id
 ui.selected_slot=selection.body.id;ui.selected_card="";ui.selected_candidate="";ui.show_body=inspect
 if inspect:
  ui.quick_release_inspected=selection.equipment.get("id","")
  ui.expanded_body_regions.erase(region_id);ui.expanded_body_regions.append(region_id)
 ui.render(ui.view)
 if inspect:reveal.call_deferred(ui)

static func reveal(ui) -> void:
 var card=ui.find_child("EquipmentCard_"+ui.quick_release_inspected,true,false)
 if card==null:return
 var scroll=card.get_parent()
 while scroll!=null and not scroll is ScrollContainer:scroll=scroll.get_parent()
 if scroll is ScrollContainer:scroll.ensure_control_visible(card)

static func refresh(ui, data: Dictionary={}) -> void:
 for id in ORDER:
  var button=ui.find_child("QuickRelease_"+id,true,false)
  if button!=null: update_tile(ui,button,id,data)

static func update_tile(ui, button: Button, region_id: String, data: Dictionary) -> void:
 var selection=_selection(ui,region_id)
 var body=selection.body
 var equipment=selection.equipment
 var c=_candidate_for(ui,body,equipment,data) if not data.is_empty() else idle_candidate(ui,body,equipment.get("id",""))
 var title=ui.localization.display(selection.region.name)+" · "+ui.localization.display(body.name)
 var detail=message(ui,"empty","没有拘束具") if equipment.is_empty() else ui.localization.display(equipment.name)
 var status=""
 if not equipment.is_empty():
  status=message(ui,"durability","耐久 {current}/{maximum} · 紧度{tier}",{"current":ui.game.number(equipment.durability),"maximum":ui.game.number(equipment.maximum),"tier":equipment.tier})
  if equipment.locked: status+=" · "+ui.localization.display("已上锁")
 var reason=""
 if not data.is_empty():
  if data.get("version",-1)!=ui.view.version: reason=ui.localization.display("行动已失效，请重新选择。")
  elif c.is_empty(): reason=message(ui,"wrong_card","这张牌不能用于当前选中的拘束具")
  elif not c.valid: reason=ui.localization.display(c.reason)
 elif not c.is_empty() and not c.valid: reason=ui.localization.display(c.reason)
 button.get_node("Title").text=title
 button.get_node("Equipment").text=detail
 var durability=button.get_node("DurabilityBar")
 durability.visible=not equipment.is_empty()
 durability.value=equipment.get("ratio",0.0)
 button.get_node("Equipment").size.x=button.size.x-2*(ARROW_WIDTH+4)-(56 if durability.visible else 0)
 button.get_node("Status").text=status
 button.get_node("Reason").text=reason
 button.tooltip_text=title+"\n"+detail+"\n"+status+"\n"+message(ui,"help","先选部位再点牌，或直接拖牌；右键切小部位，左右箭头切换拘束具。")
 if not c.is_empty(): button.tooltip_text+="\n"+ui.localization.display(c.reason if not c.valid else ui.detail_of(c))
 button.modulate=Color(0.55,0.55,0.55,1) if not data.is_empty() and (c.is_empty() or not c.valid) else Color.WHITE
 button.set_meta("body_id",body.id)
 button.set_meta("target_id",equipment.get("id",""))
 button.set_meta("target_selectable",not c.is_empty() and c.valid)
 button.add_theme_stylebox_override("normal",ui._style(Color("254b50") if ui.quick_release_region==region_id else Color("1b2b39"),ui.CYAN if ui.quick_release_region==region_id else ui.GOLD.darkened(0.45),8))

static func build(ui, container: Control, width: float) -> void:
 for i in range(ORDER.size()):
  var id=ORDER[i]
  var button=ui._button("",func():activate(ui,id),ui.CYAN,true)
  button.name="QuickRelease_"+id;button.clip_contents=true
  ui._place(button,Rect2(394+i*(width+8),556,width,60),container)
  for row in [{"name":"Title","y":0,"size":12},{"name":"Equipment","y":15,"size":12},{"name":"Status","y":30,"size":10},{"name":"Reason","y":45,"size":10}]:
   var label=ui._label("",row.size,ui.CYAN if row.name=="Title" else ui.RED if row.name=="Reason" else ui.TEXT)
   label.name=row.name;label.autowrap_mode=TextServer.AUTOWRAP_OFF;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
   ui._place(label,Rect2(ARROW_WIDTH+4,row.y,width-2*(ARROW_WIDTH+4),15),button)
  var durability=ui._bar(0,1,ui.CYAN)
  durability.name="DurabilityBar";durability.step=0.000001;durability.mouse_filter=Control.MOUSE_FILTER_IGNORE
  ui._place(durability,Rect2(width-ARROW_WIDTH-4-48,19,48,8),button)
  button.gui_input.connect(func(event):
   if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
    var region=ui._body_at(id);var current=body_at(ui,id).id
    var ids=region.members.map(func(body):return body.id)
    if not ids.is_empty(): ui.quick_release_parts[id]=ids[(ids.find(current)+1)%ids.size()]
    ui.quick_release_targets.erase(id)
    button.accept_event()
    if not ui.active_drag.is_empty():update_tile(ui,button,id,ui.active_drag)
    else:select(ui,id,true)
  )
  for step in [-1,1]:
   var arrow=ui._button("",func():cycle(ui,id,step),ui.GOLD)
   arrow.name="QuickEquipmentPrevious_"+id if step<0 else "QuickEquipmentNext_"+id
   arrow.custom_minimum_size=Vector2.ZERO
   for state in ["normal","hover","pressed","focus","disabled"]:
    var style=arrow.get_theme_stylebox(state).duplicate()
    style.content_margin_top=0;style.content_margin_bottom=0;style.content_margin_left=0;style.content_margin_right=0
    arrow.add_theme_stylebox_override(state,style)
   arrow.draw.connect(func():
    var points=PackedVector2Array([Vector2(7,30),Vector2(21,12),Vector2(21,48)]) if step<0 else PackedVector2Array([Vector2(21,30),Vector2(7,12),Vector2(7,48)])
    arrow.draw_colored_polygon(points,ui.MUTED.darkened(0.35) if arrow.disabled else ui.GOLD))
   arrow.tooltip_text=message(ui,"previous","上一个拘束具（←）") if step<0 else message(ui,"next","下一个拘束具（→）")
   arrow.disabled=ui._body_at(id).targets.size()<2
   ui._place(arrow,Rect2(0 if step<0 else width-ARROW_WIDTH,0,ARROW_WIDTH,60),button)

  button.accepted_kind="any"
  button.hover_card=func(data):update_tile(ui,button,id,data)
  button.accept_card=func(data):return candidate(ui,id,data).get("valid",false)
  button.receive_card=func(data):
   var c=candidate(ui,id,data)
   if not c.is_empty() and c.valid: ui.command_router.emit_deferred(String(c.payload.get("kind","")),c,int(data.version))
  update_tile(ui,button,id,selected_data(ui))
 var tools=ui._button(message(ui,"tools","道具使用"),func():ui._open_drawer("show_items"),ui.GOLD)
 tools.name="QuickReleaseTools"
 ui._place(tools,Rect2(394+4*(width+8),556,width,60),container)
 if ui.view.items.any(func(item):return item.installed):
  tools.text="";tools.mouse_filter=Control.MOUSE_FILTER_IGNORE
  ui._installed_tools(Rect2(tools.position,tools.size),container)

static func toggle(ui) -> void:
 ui.quick_release_open=not ui.quick_release_open
 ui._hide_term();ui._clear_drop_targets()
 ui._remove_local_panel("AttackActions")
 ui._build_action_rail()
 ui.keyboard_input.refresh_hints.call_deferred()
