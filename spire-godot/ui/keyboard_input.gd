extends Node

var host
var settings=preload("res://ui/key_bindings.gd").new()
var capture_id=""
var capture_slot=0
var binding_message=""
var held_keys={}
var selection={}
var choices: Array=[]
var choice_index=0
var end_hold={}
var target_panel: Control

func _ready() -> void:
 settings.initialize(host.persistence_enabled)

func blocked() -> bool:
 return popup_region()!=null or host.show_reward_cards or host.show_reward_relics or is_instance_valid(host.enemy_feedback) or host.view.pressure.overloaded

func popup_region() -> Control:
 var modal=host.modal_region()
 if modal!=null: return modal
 if host.DRAWERS.any(func(id):return host.get(id)): return host.drawer_layer
 if host.show_home: return host.layout
 var rewards=host.layout.find_child("BattleRewards",true,false) if is_instance_valid(host.layout) else null
 if rewards==null and is_instance_valid(host.layout): rewards=host.layout.find_child("RelicBundleRewards",true,false)
 return rewards if rewards!=null and rewards.is_visible_in_tree() and not rewards.is_queued_for_deletion() else null

func text_entry() -> bool:
 var focus=get_viewport().gui_get_focus_owner()
 return focus is LineEdit or focus is TextEdit

func handle(event: InputEvent) -> bool:
 if OS.has_feature("android"): return false
 if not event is InputEventKey: return false
 var base=int(event.keycode if event.keycode!=0 else event.physical_keycode)
 if base==0: return false
 var key=base|int(event.get_modifiers_mask())
 if not event.pressed:
  held_keys.erase(base)
  if not end_hold.is_empty() and end_hold.key==base: end_hold={}
  return false
 if capture_id=="" and base!=KEY_ESCAPE and text_entry(): return false
 if event.echo or held_keys.has(base): return settings.match_key(key)!="" or base==KEY_ESCAPE or capture_id!=""
 held_keys[base]=true
 if capture_id!="":
  if not host.show_options or host.options_tab!="keys": capture_id=""
  elif base==KEY_ESCAPE:
   capture_id="";binding_message="";host._refresh_drawers();return true
  elif base not in [KEY_SHIFT,KEY_CTRL,KEY_ALT,KEY_META]:
   if settings.assign(capture_id,capture_slot,key):
    capture_id="";binding_message="";refresh_hints.call_deferred()
   else: binding_message=settings.error
   host._refresh_drawers();return true
  else: return true
 if host.modal_region()!=null:
  var modal_action=settings.match_key(key)
  if not text_entry() and modal_action in ["confirm","next","previous"]: popup_navigation(modal_action)
  return true
 if base==KEY_ESCAPE:
  cancel();return true
 if text_entry(): return false
 var action=settings.match_key(key)
 if action=="": return not selection.is_empty() and base in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER,KEY_TAB]
 if blocked():
  var zones={"draw":"draw","discard":"discard","deck":"deck","powers":"powers"}
  if action in zones and host.show_deck and host.deck_zone==zones[action]:
   host._close_drawers();host._refresh_drawers();return true
  if (action=="items" and host.show_items) or (action=="status" and host.show_pressure) or (action=="log" and host.show_log):
   host._close_drawers();host._refresh_drawers();return true
  if action=="flip":
   var region=popup_region()
   var hover=get_viewport().gui_get_hovered_control()
   if region!=null and hover!=null and region.is_ancestor_of(hover): flip()
   return true
  if action in ["confirm","next","previous"]: popup_navigation(action)
  return true
 if action in ["next","previous"] and selection.is_empty(): return false
 if action=="confirm" and selection.is_empty(): return false
 if host._selecting_hand():
  if action.begins_with("card_"):
   var hand_index=int(action.trim_prefix("card_"))-1
   if hand_index<host.view.hand.size(): host._activate_card(host.view.hand[hand_index].uid)
  return true
 if action.begins_with("card_"):
  var index=int(action.trim_prefix("card_"))-1
  if index<host.view.hand.size(): select_card(host.view.hand[index].uid)
 elif action in ["strike","heavy","kick","fireball"]: select_attack(action)
 elif action=="flip": flip()
 elif action=="confirm": confirm()
 elif action in ["next","previous"]: cycle(-1 if action=="previous" else 1)
 elif action=="end":
  var c=host.actions.find("flow",{"kind":"end"})
  if not c.is_empty() and c.valid and is_instance_valid(host.end_button) and host.end_button.is_visible_in_tree():
   if settings.hold_end: end_hold={"candidate":c,"version":host.view.version,"key":base,"elapsed":0.0}
   else: clear();host._submit(c,host.view.version)
 else: navigate(action)
 return true

func select_card(uid: String) -> void:
 if host.show_route or not host.card_buttons.has(uid) or not host.card_buttons[uid].is_visible_in_tree(): return
 clear();host._clear_player_picker();host._clear_drop_targets()
 var self_card=host.actions.find("card",{"uid":uid,"self_target":true,"free":host.card_faces.get(uid,false)})
 if self_card.get("payload",{}).has("hand_uid"):
  host._activate_card(uid);return
 host.selected_card=uid;host.selected_candidate="";host.show_body=false
 selection={"kind":"card","uid":uid,"version":host.view.version}
 host.render(host.view);refresh_choices()

func select_attack(type: String) -> void:
 var button=host.find_child("BasicAttack_"+type,true,false)
 if button==null or not button.is_visible_in_tree(): return
 clear();host.selected_card="";host.show_body=false;host._clear_player_picker()
 selection={"kind":"attack","type":type,"version":host.view.version}
 refresh_choices()

func refresh_choices() -> void:
 if selection.is_empty(): return
 var matches=host.actions.select("card",{"uid":selection.uid,"free":host.card_faces.get(selection.uid,false)}) if selection.kind=="card" else host.actions.select("attack",{"type":selection.type,"form":host.attack_forms.get(selection.type,0)})
 choices=host.DragTargets.choices(host,selection_data())
 choice_index=0
 host.selected_candidate=""
 if choices.is_empty():
  var anchor=host.card_buttons.get(selection.get("uid",""),host.find_child("BasicAttack_"+selection.get("type",""),true,false))
  if anchor!=null: host._show_term(anchor,{"label":"","detail":matches[0].reason if not matches.is_empty() else "当前阶段不能使用。"})
 draw_targets()

func selection_data() -> Dictionary:
 if selection.is_empty(): return {}
 if selection.kind=="card": return {"card_uid":selection.uid,"free":host.card_faces.get(selection.uid,false),"version":selection.version}
 return {"action_type":selection.type,"form":host.attack_forms.get(selection.type,0),"version":selection.version}

func cycle(direction: int) -> void:
 if choices.is_empty(): return
 choice_index=posmod(choice_index+direction,choices.size())
 if selection.kind=="card": host.selected_candidate=choices[choice_index].id
 draw_targets()

func target_name(c: Dictionary) -> String:
 if c.payload.has("enemy"):
  for enemy in host.view.enemies:
   if enemy.id==c.payload.enemy: return enemy.name
 if c.payload.get("hand_uid","")!="" and c.payload.get("self_target",false):
  for card in host.view.hand:
   if card.uid==c.payload.hand_uid: return card.name
 return c.label

func draw_targets() -> void:
 if is_instance_valid(target_panel): target_panel.queue_free();target_panel.hide()
 if selection.is_empty() or choices.is_empty(): return
 var c=choices[choice_index]
 host.DragTargets.focus_bodies(host,selection_data())
 for choice in choices:
  var id=choice.payload.get("enemy",choice.payload.get("target","hero"))
  var anchor=host.actor_targets.get("hero" if id=="self" else id)
  if anchor!=null: host.DragTargets.highlight(host,anchor)
 target_panel=host._panel(Rect2(770,486,790,58));target_panel.name="KeyboardTargets";target_panel.z_index=216
 var row=HBoxContainer.new();target_panel.add_child(row)
 var prev=host._button("‹",func():cycle(-1));prev.name="KeyboardPrevious";row.add_child(prev)
 var button=host._button(target_name(c)+"  ·  "+settings.caption("confirm"),confirm,host.CYAN);button.name="KeyboardConfirm";button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(button)
 button.mouse_entered.connect(func():host._show_term(button,{"label":c.label,"detail":c.detail}))
 var next=host._button("›",func():cycle(1));next.name="KeyboardNext";row.add_child(next)
 row.add_child(host._label("%d/%d" % [choice_index+1,choices.size()],13,host.MUTED))
 for id in host.actor_targets:
  var actor=host.actor_targets[id]
  if not actor.has_meta("keyboard_receive"):
   actor.set_meta("keyboard_receive",true)
   actor.pressed.connect(func():mouse_target(id))
 var card_button=host.card_buttons.get(selection.get("uid",""))
 if card_button!=null: card_button.mouse_entered.emit()

func mouse_target(id: String) -> void:
 if selection.is_empty() or blocked(): return
 if selection.version!=host.view.version:
  clear();return
 var matching=choices.filter(func(c):return c.payload.get("enemy","")==id or c.payload.get("target","")==id or (id=="hero" and c.payload.get("self_target",false)))
 if matching.size()==1:
  choice_index=choices.find(matching[0]);confirm()

func confirm() -> void:
 if selection.is_empty() or choices.is_empty() or blocked(): return
 if selection.kind=="card" and host.selected_candidate!="":
  var index=choices.find(host.actions.by_id.get(host.selected_candidate,{}))
  if index<0: return
  choice_index=index
 var version=int(selection.version);var c=choices[choice_index]
 clear();host._submit(c,version)

func flip() -> void:
 var button: Control
 if not selection.is_empty():
  button=host.card_buttons.get(selection.uid) if selection.kind=="card" else host.find_child("BasicAttack_"+selection.type,true,false)
 elif host.selected_card!="": button=host.card_buttons.get(host.selected_card)
 else:
  button=get_viewport().gui_get_hovered_control()
  while button!=null and not (button is Button): button=button.get_parent() as Control
 if button==null: return
 var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_RIGHT;event.pressed=true
 if button.get_script()==preload("res://ui/elements/card_face.gd"): button._gui_input(event)
 else: button.gui_input.emit(event)
 if not selection.is_empty(): refresh_choices()

func navigate(action: String) -> void:
 var body_was_open=host.show_body
 clear()
 host.selected_card="";host.selected_candidate="";host.show_body=false;host._refresh_body_details()
 for button in host.card_buttons.values(): button.chosen=false;button.queue_redraw()
 if action in ["draw","discard","deck","powers"]:
  var node={"draw":"DrawPileButton","discard":"DiscardPileButton","deck":"OpenDeck","powers":"OpenPowers"}[action]
  press(node)
 elif action in ["items","status","map"]: press({"items":"OpenItems","status":"OpenStatus","map":"OpenMap"}[action])
 elif action=="body":
  host.show_body=not body_was_open;host.selected_card="";host._refresh_body_details()
 elif action=="log":
  if is_instance_valid(host.action_log_panel) and host.action_log_panel.is_visible_in_tree(): press("CloseActionLog")
  elif is_instance_valid(host.action_log_toggle) and host.action_log_toggle.is_visible_in_tree(): press("OpenActionLog")
  else: host._open_drawer("show_log")

func press(name: String) -> void:
 var button=host.find_child(name,true,false)
 if button is BaseButton and button.is_visible_in_tree() and not button.disabled: button.pressed.emit()

func popup_navigation(action: String) -> void:
 var region=popup_region()
 if region==null: return
 var focus=get_viewport().gui_get_focus_owner()
 if action=="confirm":
  if focus is BaseButton and region.is_ancestor_of(focus) and focus.is_visible_in_tree() and not focus.disabled:
   for down in [true,false]:
    var event=InputEventAction.new();event.action="ui_accept";event.pressed=down;get_viewport().push_input(event,true)
  return
 var controls: Array=[]
 collect_focus(region,controls)
 if controls.is_empty(): return
 var index=controls.find(focus)
 index=posmod(index+(-1 if action=="previous" else 1),controls.size()) if index>=0 else (controls.size()-1 if action=="previous" else 0)
 controls[index].grab_focus()

func collect_focus(node: Node, controls: Array) -> void:
 for child in node.get_children():
  if child is Control and child.name!="DismissDrawer" and child.is_visible_in_tree() and child.focus_mode!=Control.FOCUS_NONE and (not child is BaseButton or not child.disabled): controls.append(child)
  collect_focus(child,controls)

func cancel() -> void:
 end_hold={}
 if not selection.is_empty() or host.selected_card!="" or host.player_pick:
  clear();host.selected_card="";host.selected_candidate="";host._clear_player_picker();host._clear_drop_targets();host.render(host.view);return
 if host.DRAWERS.any(func(id):return host.get(id)):
  host._close_drawers();host._refresh_drawers();return
 if host.show_reward_cards or host.show_reward_relics: host.show_reward_cards=false;host.show_reward_relics=false;host.render(host.view);return
 if host.show_body or host.show_route:
  host.show_body=false;host.show_route=false;host.render(host.view);return
 if not host.show_home: host._open_drawer("show_menu")

func clear() -> void:
 if not selection.is_empty() and host.active_drag.is_empty(): host.DragTargets.clear(host)
 selection={};choices=[];end_hold={}
 if is_instance_valid(target_panel): target_panel.hide();target_panel.queue_free()

func _process(delta: float) -> void:
 if not selection.is_empty():
  var changed_card=host.selected_card!=selection.get("uid","")
  if selection.version!=host.view.version or blocked() or changed_card or get_viewport().gui_is_dragging(): clear()
  elif selection.kind=="card" and host.selected_candidate!="":
   var index=choices.find(host.actions.by_id.get(host.selected_candidate,{}))
   if index>=0 and index!=choice_index: choice_index=index;draw_targets()
 if end_hold.is_empty(): return
 if blocked() or text_entry() or end_hold.version!=host.view.version:
  end_hold={};return
 end_hold.elapsed+=delta
 if end_hold.elapsed>=0.5:
  var c=end_hold.candidate;var version=int(end_hold.version);clear();host._submit(c,version)

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
  held_keys.clear();end_hold={}

func refresh_hints() -> void:
 if OS.has_feature("android"): return
 var nodes={"draw":"DrawPileButton","discard":"DiscardPileButton","deck":"OpenDeck","powers":"OpenPowers","items":"OpenItems","status":"OpenStatus","map":"OpenMap","strike":"BasicAttack_strike","heavy":"BasicAttack_heavy","kick":"BasicAttack_kick","fireball":"BasicAttack_fireball"}
 for id in nodes:
  var button=host.find_child(nodes[id],true,false)
  if button!=null: hint(button,settings.caption(id))
 if is_instance_valid(host.end_button): hint(host.end_button,settings.caption("end"))
 for index in range(host.view.hand.size()):
  var button=host.card_buttons.get(host.view.hand[index].uid)
  if button!=null and index<10: hint(button,settings.caption("card_"+str(index+1)),true)

func hint(button: Control, text: String, card: bool=false) -> void:
 var label=button.get_node_or_null("KeyboardHint")
 if label==null:
  label=host._label("",11,host.GOLD);label.name="KeyboardHint";label.autowrap_mode=TextServer.AUTOWRAP_OFF;button.add_child(label)
 label.text=text
 label.position=Vector2(8,43) if card else Vector2(maxf(2,button.size.x-label.get_minimum_size().x-6),maxf(0,button.size.y-13))
