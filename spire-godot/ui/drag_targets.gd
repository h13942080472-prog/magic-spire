extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

# Presentation only: every target is an existing display fact of this view/version.
static func choices(ui, data: Dictionary) -> Array:
 return offers(ui,data).filter(func(c):return c.valid)

static func offers(ui, data: Dictionary) -> Array:
 return Queries.drag_facts(ui.view,data,ui.view.version)

static func targeted(c: Dictionary) -> bool:
 return c.payload.get("target","")!="" and c.payload.kind in ["item_use","hook","chain","release","attack"]

# 拖放意图装配（N2；批 R4）：把行／显示事实落成稳定 ID 形状的拖放数据——组名＋族键＋版本，
# 不含提交身份 id、不含候选行（原 siblings 的字段面）。落点族由 Queries.family_facts 按同一声明键面取回。
static func source(ui, button: Button, c: Dictionary) -> void:
 button.drag_payload=intent(c,ui.view.version)
 button.drag_label=c.label

static func intent(c: Dictionary, version: int) -> Dictionary:
 var data={"group":String(c.get("group","action")),"version":version}
 for key in Queries.FAMILY_FIELDS:
  if c.payload.has(key): data[key]=c.payload[key]
 return data

static func equipment_choices(ui, data: Dictionary, body: Dictionary) -> Array:
 return Queries.equipment_choices(ui.view,data,ui.view.version,body)

static func clear(ui, refresh_quick: bool=true) -> void:
 for entry in ui.drag_hints:
  if is_instance_valid(entry): entry.hide();entry.queue_free()
 ui.drag_hints.clear()
 for entry in ui.drag_hidden:
  if is_instance_valid(entry): entry.show()
 ui.drag_hidden.clear()
 for actor in ui.actor_targets.values()+ui.body_buttons.values()+[ui.find_child("SidebarGuardBindTarget",true,false)]:
  if is_instance_valid(actor) and actor.has_meta("idle_normal"):
   actor.add_theme_stylebox_override("normal",actor.get_meta("idle_normal"))
   actor.add_theme_stylebox_override("hover",actor.get_meta("idle_hover"))
   actor.add_theme_stylebox_override("disabled",actor.get_meta("idle_disabled"))
   actor.modulate=actor.get_meta("idle_modulate",Color.WHITE)
   if actor.has_meta("target_selectable"): actor.remove_meta("target_selectable")
   actor.remove_meta("idle_disabled")
   actor.remove_meta("idle_modulate")
   actor.remove_meta("idle_normal");actor.remove_meta("idle_hover")
 ui.active_drag={}
 if refresh_quick:
  preload("res://ui/quick_release_bar.gd").refresh(ui,preload("res://ui/quick_release_bar.gd").selected_data(ui))

static func begin(ui, data: Dictionary) -> void:
 clear(ui);ui._clear_drop_targets();ui._hide_term()
 ui.active_drag=data.duplicate(true)
 var available=choices(ui,data)
 focus_bodies(ui,data)
 if available.is_empty(): return
 # Menus remain intact and return after cancel; only their visible layer is hidden.
 if is_instance_valid(ui.drawer_layer) and ui.drawer_layer.visible:
  ui.drag_hidden.append(ui.drawer_layer);ui.drawer_layer.hide()
 var actors={};var hands={}
 for c in available:
  var p=c.payload
  if p.kind=="prison" and p.get("action","")=="unlock":
   var panel=hint(ui,"prison_door","牢门","开锁",Rect2(960,180,160,60))
   receiver(ui,panel,"DoorDragTarget",c,data)
  elif p.has("hand_uid") and p.get("self_target",false):
   hands[p.hand_uid]=c
  elif p.has("enemy") and ui.actor_targets.has(p.enemy): actors[p.enemy]=c
  elif p.get("target","")=="guard_bind": actors.guard_bind=c
  elif p.get("self_target",false) or data.has("self_action_key") or (p.kind=="card" and ui._card_is_free(p.uid,p.get("free",false))): actors.hero=c
 for id in actors:
  if not ui.actor_targets.has(id): continue
  var actor=ui.actor_targets[id];var c=actors[id]
  highlight(ui,actor)
  var title="希凛" if id=="hero" else "捕缚" if id=="guard_bind" else ""
  for enemy in ui.view.enemies:
   if enemy.id==id: title=enemy.name
  var detail=c.get("brief","")
  if not c.has("brief"): detail=ui.detail_of(c)
  if id=="guard_bind" and c.payload.has("preview"): detail=ui.game.number(c.payload.preview.damage)+"点伤害"
  if id=="guard_bind":
   var sidebar=ui.find_child("SidebarGuardBindTarget",true,false)
   if sidebar!=null:
    highlight(ui,sidebar)
    var rect=ui.layout.get_global_transform().affine_inverse()*sidebar.get_global_rect()
    hint(ui,"guard_bind_sidebar",title,detail,Rect2(rect.position.x,rect.end.y+4,rect.size.x,52))
  var bounds=ui.layout.get_global_transform().affine_inverse()*actor.get_global_rect()
  hint(ui,id,title,detail,Rect2(bounds.position.x,bounds.end.y+6,maxf(150,minf(230,bounds.size.x)),52))
 for uid in hands:
  if not ui.card_buttons.has(uid): continue
  var button=ui.card_buttons[uid];var c=hands[uid]
  var bounds=ui.layout.get_global_transform().affine_inverse()*button.get_global_rect()
  var panel=hint(ui,"hand_"+uid,button.display_name,"消耗这张牌",Rect2(bounds.position.x,530,142,60))
  receiver(ui,panel,"HandDragTarget_"+uid,c,data)

static func focus_bodies(ui, data: Dictionary) -> void:
 preload("res://ui/quick_release_bar.gd").refresh(ui,data)
 var available=choices(ui,data)
 for body in ui.view.body_groups+ui.view.body_regions:
  if not ui.body_buttons.has(body.id): continue
  var usable=available.any(func(c):return c.payload.get("slot","") in body.slots or body.targets.has(c.payload.get("target","")))
  focus(ui,ui.body_buttons[body.id],usable)

static func focus(ui, control: Control, selectable: bool) -> void:
 highlight(ui,control)
 control.set_meta("target_selectable",selectable)
 control.modulate=control.get_meta("idle_modulate") if selectable else Color(0.48,0.48,0.48,1)
 var style=ui._style(Color("254b50"),ui.CYAN,8) if selectable else ui._style(Color("14202a"),ui.MUTED.darkened(0.55),8)
 preserve_margins(style,control.get_meta("idle_normal"))
 for key in ["normal","hover","disabled"]: control.add_theme_stylebox_override(key,style)

static func highlight(ui, control: Control) -> void:
 if control.has_meta("idle_normal"): return
 control.set_meta("idle_normal",control.get_theme_stylebox("normal"));control.set_meta("idle_hover",control.get_theme_stylebox("hover"))
 control.set_meta("idle_modulate",control.modulate)
 control.set_meta("idle_disabled",control.get_theme_stylebox("disabled"))
 var style=ui._style(Color(0.15,0.55,0.6,0.10),ui.CYAN,12)
 preserve_margins(style,control.get_meta("idle_normal"))
 control.add_theme_stylebox_override("normal",style);control.add_theme_stylebox_override("hover",style)

static func preserve_margins(style: StyleBox, original: StyleBox) -> void:
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_content_margin(side,original.get_margin(side))

static func receiver(ui, panel: Control, name: String, c: Dictionary, data: Dictionary) -> void:
 var target=ui.DropTarget.new();target.accepted_kind="any";target.name=name
 panel.add_child(target)
 target.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for key in ["normal","hover","pressed","focus"]: target.add_theme_stylebox_override(key,StyleBoxEmpty.new())
 target.accept_card=func(incoming):return incoming==data and ui.view.version==data.version
 target.receive_card=func(incoming):ui.command_router.emit_deferred(String(c.payload.get("kind","")),c,int(incoming.version))

static func hint(ui, id: String, title: String, detail: String, rect: Rect2) -> PanelContainer:
 var panel=PanelContainer.new();panel.name="DragTargetHint_"+id;panel.z_index=220
 panel.set_meta("target_id",id)
 var style=ui._style(Color("101e29"),ui.CYAN.darkened(0.25),8);style.shadow_size=3
 panel.add_theme_stylebox_override("panel",style)
 ui._place(panel,Rect2(rect.position,Vector2(rect.size.x,0)))
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",3);panel.add_child(column)
 column.add_child(ui._label(title,14,ui.CYAN));column.add_child(ui._label(detail,12,ui.TEXT))
 ui._ignore_mouse(panel);ui.drag_hints.append(panel)
 panel.minimum_size_changed.connect(func(): fit_hint.call_deferred(panel,rect))
 fit_hint.call_deferred(panel,rect)
 return panel

static func fit_hint(panel: PanelContainer, rect: Rect2) -> void:
 if not is_instance_valid(panel) or panel.is_queued_for_deletion(): return
 # Wrapped labels can first report a tall minimum before receiving their width.
 # Containers grow automatically, but must be resized to shrink after wrapping.
 panel.size=Vector2(rect.size.x,panel.get_combined_minimum_size().y)
 panel.position=Vector2(clampf(rect.position.x,20,maxf(20,1580-panel.size.x)),clampf(rect.position.y,74,maxf(74,886-panel.size.y)))
