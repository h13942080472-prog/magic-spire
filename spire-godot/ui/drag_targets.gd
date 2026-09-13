extends RefCounted

const DragHintScene=preload("res://ui/elements/drag_hint.tscn")
const Palette=preload("res://ui/visual_theme.gd")

# Drag sources leave a disabled body in place until the drag ends; the registry survives render() and
# skips entries whose node was rebuilt, so no source can stay stuck in the dragged state.
static var drag_sources: Array=[]

static func register_source(node: Control) -> void:
 if drag_sources.any(func(entry):return entry.node==node): return
 var was_disabled=false
 var button=node as BaseButton
 if button!=null: was_disabled=button.disabled
 drag_sources.append({"node":node,"disabled":was_disabled,"modulate":node.modulate})
 Palette.apply_state(node,"disabled")

static func restore_sources() -> void:
 for entry in drag_sources:
  var node=entry.node
  if not is_instance_valid(node): continue
  node.modulate=entry.modulate
  var button=node as BaseButton
  if button!=null: button.disabled=entry.disabled
 drag_sources.clear()

# Presentation only: every target is an existing candidate from this view/version.
static func choices(ui, data: Dictionary) -> Array:
 return candidates(ui,data).filter(func(c):return c.valid)

static func candidates(ui, data: Dictionary) -> Array:
 if data.get("version",-1)!=ui.view.version: return []
 if data.has("card_uid"):
  var out=ui.actions.select("card",{"uid":data.card_uid,"free":data.get("free",false)})
  if not data.get("free",false): out.append_array(ui.actions.select("prison",{"action":"unlock","uid":data.card_uid}))
  var seen=[]
  return out.filter(func(c):
   if not c.payload.has("hand_uid") or c.payload.get("self_target",false): return true
   var key=[c.payload.target,c.payload.slot]
   if key in seen: return false
   seen.append(key);return true)
 if data.has("action_type"):
  return ui.actions.select("attack",{"type":data.action_type,"form":data.get("form",0)})
 var ids=data.get("candidate_ids",[data.self_action_id] if data.has("self_action_id") else [])
 return ids.filter(func(id):return ui.actions.by_id.has(id)).map(func(id):return ui.actions.by_id[id])

static func targeted(c: Dictionary) -> bool:
 return c.payload.get("target","")!="" and c.payload.kind in ["item_use","hook","chain","release","attack"]

static func source(ui, button: Button, c: Dictionary) -> void:
 button.drag_payload={"candidate_ids":siblings(ui,c).map(func(choice):return choice.id),"version":ui.view.version}
 button.drag_label=c.label

static func siblings(ui, source: Dictionary) -> Array:
 var fields={}
 for key in ["kind","type","item","mode","action","free","form"]:
  if source.payload.has(key): fields[key]=source.payload[key]
 return ui.actions.select(source.group,fields).filter(func(c):return c.payload.get("target","")!="")

static func equipment_choices(ui, data: Dictionary, body: Dictionary) -> Array:
 var out=[];var seen=[]
 for c in candidates(ui,data):
  var target=c.payload.get("target","")
  if target in seen or not body.targets.has(target): continue
  seen.append(target);out.append(c)
 return out

static func clear(ui) -> void:
 for entry in ui.drag_hints:
  if is_instance_valid(entry): entry.hide();entry.queue_free()
 ui.drag_hints.clear()
 for entry in ui.drag_hidden:
  if is_instance_valid(entry): entry.show()
 ui.drag_hidden.clear()
 for actor in ui.actor_targets.values()+ui.body_buttons.values():
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
  elif p.get("self_target",false) or data.has("self_action_id") or (p.kind=="card" and ui._card_is_free(p.uid,p.get("free",false))): actors.hero=c
 for id in actors:
  if not ui.actor_targets.has(id): continue
  var actor=ui.actor_targets[id];var c=actors[id]
  highlight(ui,actor)
  var title="希凛" if id=="hero" else "捕缚" if id=="guard_bind" else ""
  for enemy in ui.view.enemies:
   if enemy.id==id: title=enemy.name
  var detail=c.get("brief",c.detail)
  if id=="guard_bind" and c.payload.has("preview"): detail=ui.game.number(c.payload.preview.damage)+"点伤害"
  var bounds=ui.layout.get_global_transform().affine_inverse()*actor.get_global_rect()
  hint(ui,id,title,detail,Rect2(bounds.position.x,bounds.end.y+6,maxf(150,minf(230,bounds.size.x)),52))
 for uid in hands:
  if not ui.card_buttons.has(uid): continue
  var button=ui.card_buttons[uid];var c=hands[uid]
  var bounds=ui.layout.get_global_transform().affine_inverse()*button.get_global_rect()
  var panel=hint(ui,"hand_"+uid,button.display_name,"消耗这张牌",Rect2(bounds.position.x,530,142,60))
  receiver(ui,panel,"HandDragTarget_"+uid,c,data)

static func focus_bodies(ui, data: Dictionary) -> void:
 var available=choices(ui,data)
 for body in ui.view.body_groups:
  if not ui.body_buttons.has(body.id): continue
  var usable=available.any(func(c):return c.payload.get("slot","") in body.slots or body.targets.has(c.payload.get("target","")))
  focus(ui,ui.body_buttons[body.id],usable)

static func focus(ui, control: Control, selectable: bool) -> void:
 highlight(ui,control)
 control.set_meta("target_selectable",selectable)
 control.modulate=control.get_meta("idle_modulate") if selectable else Color(0.48,0.48,0.48,1)
 var style=ui._style(Color("14202a"),ui.MUTED.darkened(0.55),8)
 for key in ["normal","hover","disabled"]: control.add_theme_stylebox_override(key,ui.Palette.slot_style(key,false,true) if selectable else style)

static func highlight(ui, control: Control) -> void:
 if control.has_meta("idle_normal"): return
 control.set_meta("idle_normal",control.get_theme_stylebox("normal"));control.set_meta("idle_hover",control.get_theme_stylebox("hover"))
 control.set_meta("idle_modulate",control.modulate)
 control.set_meta("idle_disabled",control.get_theme_stylebox("disabled"))
 var style=ui._style(Color(0.15,0.55,0.6,0.10),ui.CYAN,12)
 control.add_theme_stylebox_override("normal",style);control.add_theme_stylebox_override("hover",style)

static func receiver(ui, panel: Control, name: String, c: Dictionary, data: Dictionary) -> void:
 var target=ui.DropTargetScene.instantiate();target.accepted_kind="any";target.name=name
 panel.add_child(target)
 target.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for key in ["normal","hover","pressed","focus"]: target.add_theme_stylebox_override(key,StyleBoxEmpty.new())
 target.accept_card=func(incoming):return incoming==data and ui.view.version==data.version
 target.receive_card=func(incoming):ui.call_deferred("_submit",c,int(incoming.version))

static func hint(ui, id: String, title: String, detail: String, rect: Rect2) -> PanelContainer:
 var panel=DragHintScene.instantiate();panel.name="DragTargetHint_"+id;panel.z_index=220
 panel.set_meta("target_id",id)
 var style=ui._style(Color("101e29"),ui.CYAN.darkened(0.25),8);style.shadow_size=3
 panel.add_theme_stylebox_override("panel",style)
 ui._place(panel,Rect2(rect.position,Vector2(rect.size.x,0)))
 panel.column().add_theme_constant_override("separation",3)
 ui._style_label(panel.title_label(),title,14,ui.CYAN)
 ui._style_label(panel.detail_label(),detail,12,ui.TEXT)
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
