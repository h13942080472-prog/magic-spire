extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

const ARTWORK={
 "succubus_three_games":preload("res://assets/art/event-fortune-teller-v1.png"),
 "abandoned_storeroom":preload("res://assets/art/event-abandoned-storeroom-v1.png"),
 "floating_belt_cluster":preload("res://assets/art/event-floating-belt-cluster-v1.png"),
 "maze_survey_team":preload("res://assets/art/event-maze-survey-team-v1.png"),
 "smuggled_mana_potions":preload("res://assets/art/event-smuggled-mana-potions-v1.png"),
 "enchanters_empty_studio":preload("res://assets/art/event-enchanters-empty-studio-v1.png"),
 "alchemist_tasting_stall":preload("res://assets/art/event-alchemist-tasting-stall-v1.png"),
 "binding_cleric":preload("res://assets/art/event-binding-cleric-v1.png"),
 "bound_adventurer_relic":preload("res://assets/art/event-bound-adventurer-relic-v1.png"),
 "bound_dream_guest_room":preload("res://assets/art/event-bound-dream-guest-room-v1.png"),
 "mysterious_woman_statue":preload("res://assets/art/event-mysterious-woman-statue-v1.png"),
 "succubus_magic_pawnshop":preload("res://assets/art/event-succubus-magic-pawnshop-v1.png")
}

# Presentation only: selector groups reference the public display facts.
# Opening, closing and browsing never dispatch a command or refresh random data.
static func build(ui) -> void:
 var event=ui.view.room_event
 var result_pending=event.report!="" and event.stage!="result" and ui.event_read_page!=event.page_id
 var panel=ui._panel(Rect2(405,158,895,652));panel.name="EventPanel"
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",24);panel.add_child(row)
 var left=VBoxContainer.new();left.custom_minimum_size.x=300;row.add_child(left)
 var artwork=PanelContainer.new();artwork.name="EventArtwork";artwork.custom_minimum_size=Vector2(300,360)
 artwork.add_theme_stylebox_override("panel",ui._style(Color("111923"),ui.GOLD.darkened(0.5)));left.add_child(artwork)
 if ARTWORK.has(event.id):
  artwork.custom_minimum_size.y=450
  var portrait=TextureRect.new();portrait.name="EventPortrait";portrait.texture=ARTWORK[event.id]
  portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  portrait.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
  artwork.add_child(portrait)
 else:
  var art_center=CenterContainer.new();artwork.add_child(art_center)
  var emblem=TextureRect.new();emblem.texture=preload("res://assets/ui/crest.svg");emblem.custom_minimum_size=Vector2(168,168)
  emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;emblem.mouse_filter=Control.MOUSE_FILTER_IGNORE;art_center.add_child(emblem)
 var right=VBoxContainer.new();right.name="EventContent";right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",14);row.add_child(right)
 right.add_child(ui._label(event.name,25,ui.GOLD))
 if result_pending or event.stage=="result":
  var status=event.result_status
  var tone=Color("8fdfba") if status=="success" else (Color("ff8797") if status=="failure" else ui.GOLD)
  var banner=PanelContainer.new();banner.name="EventResultBanner";banner.custom_minimum_size.y=70
  banner.set_meta("result_status",status)
  banner.add_theme_stylebox_override("panel",ui._style(Color(tone.r*0.14,tone.g*0.14,tone.b*0.14,1),tone))
  right.add_child(banner)
  var label=ui._label("✓  成功" if status=="success" else ("×  失败" if status=="failure" else "◇  已完成"),34,tone)
  label.name="EventResultLabel";label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;banner.add_child(label)
 var prose=ui._scroll(right);prose.name="EventNarrative";prose.get_parent().name="EventNarrativeScroll"
 if result_pending or event.stage=="result":
  prose.add_child(ui._label(event.report,18,ui.TEXT))
 elif event.stage!="reward":
  prose.add_child(ui._label(event.intro,18,ui.TEXT))
 right.add_child(HSeparator.new())
 var options=VBoxContainer.new();options.name="EventChoices";options.add_theme_constant_override("separation",10);right.add_child(options)
 if result_pending:
  var page_id=event.page_id
  var next=ui._button("继续",func():
   if ui.view.phase!="event" or ui.view.room_event.page_id!=page_id: return
   ui.event_read_page=page_id
   ui.render(ui.view))
  next.name="EventContinue";next.custom_minimum_size.y=44;options.add_child(next)
  return
 var offers=Queries.select(ui.view,"event")
 var grouped=[]
 for group in event.selections:
  var members=offers.filter(func(c):return group.options.any(func(option):return option.choice==c.payload.get("choice","")))
  if members.is_empty(): continue
  for c in members: grouped.append(Queries.fact_key(c))
  selector_button(ui,options,group.id,group.label,group.kind,members,group.options,group.get("count",1))
 for c in offers:
  if Queries.fact_key(c) not in grouped: action(ui,options,c)

static func selector_button(ui, parent: Node, id: String, label: String, kind: String, offers: Array, options: Array, count: int=1) -> void:
 var button=ui._button(label+"  ›",func():
  ui.event_selection={"id":id,"title":label,"kind":kind,"count":count,"selected_ids":[],"offers":offers,"options":options,"version":ui.view.version}
  ui._open_drawer("show_event_selection"))
 button.name="EventOpen_"+id;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.y=44
 parent.add_child(button)
 # One shared public preview, while target-specific details remain beside each
 # actual choice inside the modal. No secret winning result is projected.
 var preview=offers[0].detail if id!="reward" else ""
 if preview!="" and offers.all(func(c):return c.detail==preview): parent.add_child(ui._label(preview,14,ui.MUTED))

static func action(ui, parent: Node, c: Dictionary, version: int=-1, show_detail: bool=true) -> Button:
 var fee=(" · %s能量" % c.cost if c.cost>0 else "")+(" · %s魔力" % c.mana if c.mana>0 else "")
 var button=ui._button(c.label+fee,func():ui.command_router.emit(String(c.payload.get("kind","")),c,version),ui.RED if c.risk!="" else ui.GOLD)
 button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.y=42;button.disabled=not c.valid
 parent.add_child(button);ui.candidate_buttons[c.key]=button
 var secondary_reason=not c.valid and c.get("reason_surface","")=="secondary"
 if secondary_reason:
  button.mouse_default_cursor_shape=Control.CURSOR_HELP
  var entry={"label":c.label,"detail":c.reason}
  button.mouse_entered.connect(func():ui._show_term(button,entry));button.mouse_exited.connect(ui._hide_term)
  button.focus_entered.connect(func():ui._show_term(button,entry));button.focus_exited.connect(ui._hide_term)
 if (show_detail and c.detail!="") or (not c.valid and not secondary_reason): parent.add_child(ui._label(c.detail if c.valid else c.reason,14,ui.MUTED if c.valid else ui.RED))
 if c.risk!="" and c.valid: parent.add_child(ui._label(c.risk,14,ui.RED))
 return button

static func drawer(ui) -> void:
 var selection=ui.event_selection
 var content=ui._drawer_shell(selection.title,Rect2(60,78,1480,780),ui.GOLD)
 var shared_detail=selection.offers[0].detail
 if not selection.offers.all(func(c):return c.detail==shared_detail): shared_detail=""
 if shared_detail!="": content.add_child(ui._label(shared_detail,15,ui.GOLD))
 var scroll=ui._scroll(content);scroll.get_parent().name="EventSelectionScroll"
 var grid=GridContainer.new();grid.name="EventSelectionGrid";grid.columns=6 if selection.kind=="card" else 3
 grid.add_theme_constant_override("h_separation",22);grid.add_theme_constant_override("v_separation",22);scroll.add_child(grid)
 if int(selection.get("count",1))>1:
  multi_restraint_selector(ui,content,grid,selection)
  return
 for c in selection.offers:
  var tile=VBoxContainer.new();tile.custom_minimum_size.x=216 if selection.kind=="card" else 450;grid.add_child(tile)
  var matches=selection.options.filter(func(option):return option.choice==c.payload.get("choice",""))
  var selected={} if matches.is_empty() else matches[0].selected
  if selection.kind=="card":
   var type=selected.type if not selected.is_empty() else c.payload.type
   var face=ui._display_card(type,tile,func():ui.command_router.emit(String(c.payload.get("kind","")),c,selection.version),"event_"+Queries.fact_key(c),Vector2(216,286))
   face.disabled=not c.valid;face.set_meta("physical_uid",selected.get("id",""));ui.candidate_buttons[c.key]=face
   tile.add_child(ui._label(c.label,16,ui.GOLD))
   if shared_detail=="" or not c.valid: tile.add_child(ui._label(c.detail if c.valid else c.reason,14,ui.MUTED if c.valid else ui.RED))
   if c.risk!="" and c.valid: tile.add_child(ui._label(c.risk,14,ui.RED))
  else:
   var box=PanelContainer.new();box.add_theme_stylebox_override("panel",ui._style(ui.INK));tile.add_child(box)
   var body=VBoxContainer.new();box.add_child(body)
   body.add_child(ui._label(selected.name,20,ui.GOLD))
   body.add_child(ui._label(selected.slot,16,ui.MUTED))
   if selected.has("durability"):
    body.add_child(ui._bar(selected.durability,selected.maximum,ui.CYAN))
    var condition=HBoxContainer.new();body.add_child(condition)
    var numbers=ui._label("耐久 %s / %s  ·  紧度%d" % [selected.durability,selected.maximum,selected.tier],16,ui.TEXT)
    numbers.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    condition.add_child(numbers)
    ui._equipment_lock(condition,selected.locked,selected.id,selected.lockable)
   action(ui,body,c,selection.version,shared_detail=="")

static func restraint_box(ui, parent: Node, selected: Dictionary) -> VBoxContainer:
 var tile=VBoxContainer.new();tile.custom_minimum_size.x=420;parent.add_child(tile)
 var box=PanelContainer.new();box.add_theme_stylebox_override("panel",ui._style(ui.INK));tile.add_child(box)
 var body=VBoxContainer.new();box.add_child(body)
 body.add_child(ui._label(selected.name,20,ui.GOLD))
 body.add_child(ui._label(selected.slot,16,ui.MUTED))
 if selected.has("durability"):
  body.add_child(ui._bar(selected.durability,selected.maximum,ui.CYAN))
  var condition=HBoxContainer.new();body.add_child(condition)
  var numbers=ui._label("耐久 %s / %s  ·  紧度%d" % [selected.durability,selected.maximum,selected.tier],16,ui.TEXT)
  numbers.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  condition.add_child(numbers)
  ui._equipment_lock(condition,selected.locked,selected.id,selected.lockable)
 return body

static func multi_restraint_selector(ui, content: VBoxContainer, grid: GridContainer, selection: Dictionary) -> void:
 var by_id={}
 for option in selection.options:
  if not option.selected is Array: continue
  for selected in option.selected:
   if not by_id.has(selected.id): by_id[selected.id]=selected
 var chosen: Array=selection.get("selected_ids",[]).duplicate()
 var required=int(selection.count)
 for id in by_id:
  var selected=by_id[id]
  var body=restraint_box(ui,grid,selected)
  var selected_now=id in chosen
  var toggle_action=func(target_id):
   var ids: Array=ui.event_selection.get("selected_ids",[]).duplicate()
   if target_id in ids: ids.erase(target_id)
   elif ids.size()<required: ids.append(target_id)
   ui.event_selection.selected_ids=ids
   ui.render(ui.view)
  var toggle=ui._button("取消选择" if selected_now else "选择",toggle_action.bind(id),ui.CYAN if selected_now else ui.GOLD)
  toggle.name="EventToggle_"+id;body.add_child(toggle)
 var count_label=ui._label("已选择 %d / %d 件拘束具" % [chosen.size(),required],16,ui.MUTED if chosen.size()!=required else ui.CYAN)
 count_label.name="EventSelectionCount";content.add_child(count_label)
 var matched={}
 if chosen.size()==required:
  var sorted_chosen=chosen.duplicate();sorted_chosen.sort()
  for option in selection.options:
   if not option.selected is Array: continue
   var ids=option.selected.map(func(row):return row.id);ids.sort()
   if ids==sorted_chosen:
    var offers=selection.offers.filter(func(candidate):return candidate.payload.get("choice","")==option.choice)
    if not offers.is_empty(): matched=offers[0]
    break
 var confirm_action=func():
  if not matched.is_empty(): ui.command_router.emit(String(matched.payload.get("kind","")),matched,selection.version)
 var confirm=ui._button("解除所选拘束具",confirm_action,ui.GOLD)
 confirm.name="EventConfirmSelection";confirm.disabled=matched.is_empty() or not matched.valid;content.add_child(confirm)
 if not matched.is_empty(): ui.candidate_buttons[matched.key]=confirm
