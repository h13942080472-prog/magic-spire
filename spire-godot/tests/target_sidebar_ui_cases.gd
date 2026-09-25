extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

# 合成事实进同一个扁平 display_facts 表（组名＝事实自带的 group 字段，R5 起无行组→View 键映射表）。
static func fact_view(rows: Array) -> Dictionary:
 return {"display_facts":rows.duplicate(true)}

static func query_contract(t) -> void:
 var queries=preload("res://ui/target_queries.gd")
 var make=func(id,slot,free,valid):return {"id":id,"key":id,"group":"card","valid":valid,"reason":id,"payload":{"kind":"card","uid":"card","slot":slot,"target":"gear","free":free,"mode":"strain"}}
 var left=make.call("left-blocked","left",false,false)
 var right=make.call("right-ready","right",false,true)
 var second=make.call("second-face","left",true,true)
 var gear={"id":"gear"}
 var body={"id":"hands","slots":["left","right"],"targets":{"gear":gear},"sections":[{"name":"左手","equipment":[gear]},{"name":"右手","equipment":[gear]}]}
 var facts=[left,right,second];var view=fact_view(facts)
 var before=facts.duplicate(true);var body_before=body.duplicate(true)
 var data={"card_uid":"card","free":false,"version":7}
 var grouped=queries.body_cards(view,body,"card")
 t.check(grouped==[right,second] and grouped[0]==right,"TARGET QUERY body merge keeps both faces and the original usable candidate for one physical target")
 t.check(queries.single_body_card(view,body,"card",false)==right and queries.single_equipment_card(view,[body],"card",false)==right,"TARGET QUERY single-equipment click uses the same physical target as body selection")
 t.check(queries.release_candidate(view,body,"gear",data,7)==right,"TARGET QUERY quick release selects the same original bound candidate")
 var free=data.duplicate();free.free=true
 t.check(queries.release_candidate(view,body,"gear",free,7)==second and queries.drag_facts(view,free,7)==[second],"TARGET QUERY face switch is reflected without a new version")
 t.check(queries.release_candidate(view,body,"other",data,7).is_empty(),"TARGET QUERY missing explicit target cannot fall back to another equipment")
 t.check(queries.equipment_choices(view,data,7,body)==[left],"TARGET QUERY generic drag preserves its first-per-target rejection policy")
 var entries=queries.equipment_entries(body);entries.gear.locations.clear();entries.clear();grouped.clear()
 t.check(queries.equipment_entries(body).gear.locations==["左手","右手"] and facts==before and body==body_before,"TARGET QUERY result containers do not mutate source facts or body sections")
 for version in [6,8]:
  t.check(queries.drag_facts(view,data,version).is_empty() and queries.release_choices(view,body,data,version).is_empty(),"TARGET QUERY mismatched version blocks drag and quick selection: "+str(version))
 var missing=data.duplicate();missing.erase("version")
 t.check(queries.drag_facts(view,missing,7).is_empty() and queries.release_candidate(view,body,"gear",missing,7).is_empty(),"TARGET QUERY missing version cannot acquire an action")
 var blocked=right.duplicate(true);blocked.valid=false
 t.check(queries.first_usable([left,blocked])==left and queries.first_usable([left,blocked],"last")==blocked,"TARGET QUERY first and last rejection policies remain distinct")
 var capture=right.duplicate(true);capture.id="capture";capture.payload.target="guard_bind"
 t.check(queries.single_equipment_card(fact_view([right,capture]),[body],"card",false).is_empty(),"TARGET QUERY capture alongside one equipment still requires explicit choice")
 var hand_a=left.duplicate(true);hand_a.payload.hand_uid="hand-a";hand_a.key="hand-a"
 var hand_b=hand_a.duplicate(true);hand_b.id="hand-b";hand_b.key="hand-b";hand_b.payload.hand_uid="hand-b";hand_b.valid=true
 var self_card=hand_b.duplicate(true);self_card.id="self";self_card.key="self";self_card.payload.self_target=true
 var door={"id":"door","key":"door","group":"prison","valid":true,"payload":{"kind":"prison","action":"unlock","uid":"card"}}
 var drag_view=fact_view([hand_a,hand_b,self_card,second,door])
 t.check(queries.drag_facts(drag_view,data,7)==[hand_a,self_card,door],"TARGET QUERY hand-target dedup keeps first choice and retains self-target and prison unlock entries")
 t.check(queries.drag_facts(drag_view,free,7)==[second],"TARGET QUERY the other face cannot acquire a prison unlock action")
 var ids={"fact_keys":["missing","second-face","door","second-face"],"version":7}
 t.check(queries.drag_facts(drag_view,ids,7)==[second,door,second],"TARGET QUERY explicit IDs retain caller order and duplicates while dropping missing IDs")
 var fire={"id":"fire","group":"attack","valid":true,"payload":{"kind":"attack","type":"fireball","form":0,"target":"gear"}}
 var attacks=fact_view([fire]);var fire_data={"action_type":"fireball","version":7}
 t.check(queries.drag_facts(attacks,fire_data,7)==[fire] and queries.release_candidate(attacks,body,"gear",fire_data,7)==fire,"TARGET QUERY fireball drag and exact equipment selection share the formal action")
 t.check(queries.release_candidate(attacks,body,"gear",fire_data,8).is_empty(),"TARGET QUERY stale fireball cannot retain a previously usable action")

static func press(t, control: Control) -> void:
 var point=control.get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)

# Real pointer drag onto a body region: returns every drop strip entry, every drag hint text and
# the hint ids, so a missing projection can be compared against the complete one.
static func copy_drag_text(t, uid: String, slot: String) -> Dictionary:
 var ui=t.ui
 var point=t.card_point(uid)
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await t.move_mouse(point+Vector2(0,-42),true)
 await t.move_mouse(ui.body_buttons[slot].get_global_rect().get_center(),true)
 var strip=""
 for target in ui.drop_targets.values(): strip+=str(target.get_meta("preview_detail",""))+"\n"
 var hints=""
 for hint in ui.drag_hints: hints+=t.visible_text(hint)
 var ids=ui.drag_hints.map(func(hint):return hint.get_meta("target_id",""))
 await t.move_mouse(Vector2(1550,70),true)
 await t.mouse_button(Vector2(1550,70),MOUSE_BUTTON_LEFT,false)
 return {"strip":strip,"hints":hints,"ids":ids}

# docs/spec/ondemand-copy.md「证据入口」: a test-side copy of the View with a deleted
# card_texts key or without the card group's detail must render the drag sections without an
# engine error, keep the recomputed text and leave a named record instead of a silent blank.
static func copy_missing_key_never_crashes(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.wall="normal"
 ui.game.add_fixture("wrist",4,10,false);ui.game.add_fixture("wrist",4,10,false)
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"strain")
 ui.render();await t.frames()
 var free_detail=ui.game.candidate_detail(Queries.find(ui.view,"card",{"uid":card.uid,"free":true}))
 var before=ui.game.export_snapshot()
 var baseline={}
 for free_face in [false,true]:
  ui.card_faces[card.uid]=free_face
  ui.render();await t.frames()
  baseline[free_face]=await copy_drag_text(t,card.uid,"thigh")
 t.check(baseline[false].strip.contains("请右键切换到"),"COPY bound-face drag renders the drop strip face hint")
 t.check(baseline[true].ids.has("hero") and baseline[true].hints.contains(free_detail),"COPY free-face drag renders the hover hint with the candidate detail")
 t.check(ui.game.export_snapshot()==before and ui.projection_misses.is_empty(),"COPY complete projection renders no miss record and pays nothing")
 var copy=ui.game.get_view().duplicate(true)
 copy.card_texts.erase(card.type)
 var erased_misses=[]
 for free_face in [false,true]:
  ui.card_faces[card.uid]=free_face
  ui.render(copy);await t.frames()
  var erased=await copy_drag_text(t,card.uid,"thigh")
  erased_misses.append_array(ui.projection_misses)
  t.check(erased==baseline[free_face],"COPY deleted card_texts key keeps the drop strip and hint text identical for face "+str(free_face))
 t.check(erased_misses.any(func(entry):return entry.point=="card_entry" and entry.key.begins_with(card.type)),"COPY deleted card key is recomputed through the single entry and recorded: "+str(erased_misses))
 var detail_copy=ui.game.get_view().duplicate(true)
 var removed=0
 for candidate in detail_copy.display_facts:
  if candidate.payload.get("kind","")=="card": candidate.erase("detail");removed+=1
 t.check(removed>0,"COPY fixture removes detail from the card candidate group")
 for free_face in [false,true]:
  ui.card_faces[card.uid]=free_face
  ui.render(detail_copy);await t.frames()
  var recomputed=await copy_drag_text(t,card.uid,"thigh")
  t.check(recomputed==baseline[free_face],"COPY removed candidate detail is recomputed byte-identically for face "+str(free_face))
 # B3：card 目标候选组本就不带 detail，现算是正常路径；此处断言它不再被当作缺失记录。
 t.check(ui.projection_misses.all(func(entry):return entry.point!="detail_of"),"COPY on-demand card details are no longer recorded as misses: "+str(ui.projection_misses))
 t.check(ui.projection_misses.all(func(entry):return entry.view_version==ui.view.version),"COPY miss records name the render they belong to")
 t.check(ui.game.export_snapshot()==before,"COPY missing-key rendering never changes state or random cursors")

static func _cancel_drag(t) -> void:
 await t.move_mouse(Vector2(1550,70),true)
 await t.mouse_button(Vector2(1550,70),MOUSE_BUTTON_LEFT,false)

static func _drag_card(t, uid: String) -> void:
 var origin=t.card_point(uid)
 await t.move_mouse(origin)
 await t.mouse_button(origin,MOUSE_BUTTON_LEFT,true)
 await t.move_mouse(origin+Vector2(0,-42),true)

# Real pointer: body bar, self, capture bar, empty space, then quick-release region then card.
static func r4_pointer_paths(t) -> void:
 var ui=t.ui
 var queries=preload("res://ui/target_queries.gd")
 var quick=preload("res://ui/quick_release_bar.gd")
 ui.restart(42)
 ui.game.state.equipment.clear()
 ui.game.state.energy=0
 var ankle=ui.game.add_fixture("ankle",80,100)
 ui.render();await t.frames()
 var uid=ui.view.hand.filter(func(c):return c.type=="strain")[0].uid
 if ui.card_faces.get(uid,false): await t.flip(uid)
 var before=ui.game.export_snapshot()
 var fact=queries.find(ui.view,"card",{"uid":uid,"target":ankle.id,"free":false})
 await t.start_drag(uid,"ankle")
 var body_valid=queries.body_cards(ui.view,ui._body_at("ankle"),uid).any(func(c):return c.valid and c.payload.free==false)
 t.check(not fact.is_empty() and not fact.valid and String(fact.reason)!="","R4 body drag fixture has an invalid determination with a reason")
 t.check(bool(ui.body_buttons.ankle.get_meta("target_selectable",false))==body_valid,"R4 body-bar highlight matches determination availability")
 t.check(ui.drop_targets.has(queries.fact_key(fact)),"R4 body drag exposes the determination fact")
 var drop=ui.drop_targets[queries.fact_key(fact)]
 t.check(bool(drop.get_meta("target_selectable",false))==bool(fact.valid),"R4 body drop highlight matches the determination")
 t.check(String(drop.get_meta("preview_detail","")).contains(String(fact.reason)),"R4 body drag shows the determination reason verbatim")
 await _cancel_drag(t)
 t.check(ui.drop_targets.is_empty() and ui.active_drag.is_empty() and ui.game.export_snapshot()==before,"R4 releasing over empty space commits nothing")
 await _drag_card(t,uid)
 await t.move_mouse(ui.actor_targets.hero.get_global_rect().get_center(),true)
 var self_fact=queries.find(ui.view,"card",{"uid":uid,"self_target":true,"free":false})
 var self_lit=ui.actor_targets.hero.has_meta("idle_normal")
 if self_fact.is_empty():
  t.check(not self_lit,"R4 self has no availability highlight when the card has no self-target fact")
  var invented=is_instance_valid(ui.term_popup) and ui.term_popup.has_meta("drag_reason") and String(ui.term_popup.get_meta("drag_reason",""))!=""
  t.check(not invented,"R4 self drag does not invent a rejection")
 else:
  t.check(self_lit==bool(self_fact.valid),"R4 self highlight matches the self-target fact")
  if not self_fact.valid:
   t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains(String(self_fact.reason)),"R4 self drag shows the determination reason verbatim")
 await _cancel_drag(t)
 t.check(ui.game.export_snapshot()==before,"R4 cancelling a self drag commits nothing")
 var toggle=ui.find_child("ActionRailToggle",true,false)
 if not ui.quick_release_open: await press(t,toggle)
 await press(t,ui.find_child("QuickRelease_region_lower",true,false))
 ui.selected_card=uid
 ui.card_faces[uid]=false
 ui.game.state.energy=0
 ui.render();await t.frames()
 var offer=quick.candidate(ui,"region_lower",{"card_uid":uid,"free":false,"version":ui.view.version})
 var region=ui.find_child("QuickRelease_region_lower",true,false)
 t.check(not offer.is_empty() and not offer.valid and region.get_node("Reason").text==String(offer.reason),"R4 quick-release tile shows the determination reason verbatim")
 t.check(bool(region.get_meta("target_selectable",false))==bool(offer.valid),"R4 quick-release tile highlight matches the determination")
 ui.game.state.energy=3
 ui.selected_card=""
 ui.render();await t.frames()
 offer=quick.candidate(ui,"region_lower",{"card_uid":uid,"free":false,"version":ui.view.version})
 var target_id=String(offer.get("payload",{}).get("target",""))
 var spent=ui.game._equipment(target_id).durability if target_id!="" else 0
 var energy=ui.view.energy
 t.check(offer.get("valid",false),"R4 quick release fixture produced a usable strain offer")
 if offer.get("valid",false):
  var play=t.card_point(uid)
  await t.move_mouse(play)
  await t.mouse_button(play,MOUSE_BUTTON_LEFT,true)
  await t.mouse_button(play,MOUSE_BUTTON_LEFT,false)
  t.check(not ui.view.hand.any(func(c):return c.uid==uid) and ui.view.energy==energy-int(offer.cost),"R4 quick release selects a region then plays the card once")
  t.check(ui.game._equipment(target_id).durability<spent,"R4 quick release applies the selected region's equipment")
 ui.restart(42,true,"guard")
 preload("res://tests/guard_cases.gd").bind(ui.game,ui.game.state.enemies[0],36.0)
 ui.game.state.energy=3
 var strain=ui.game.state.hand.filter(func(c):return c.type=="strain")
 if strain.is_empty(): strain=[preload("res://tests/curse_cases.gd").give(ui.game,"strain")]
 ui.render();await t.frames()
 uid=strain[0].uid
 if ui.card_faces.get(uid,false): await t.flip(uid)
 before=ui.game.export_snapshot()
 var bind=queries.find(ui.view,"card",{"uid":uid,"target":"guard_bind","free":false})
 await _drag_card(t,uid)
 t.check(ui.actor_targets.has("guard_bind") and not bind.is_empty(),"R4 capture bar is a real drop actor for a determination fact")
 t.check(ui.actor_targets.guard_bind.has_meta("idle_normal")==bool(bind.get("valid",false)),"R4 capture-bar highlight matches the determination")
 await _cancel_drag(t)
 t.check(ui.game.export_snapshot()==before,"R4 cancelling a capture drag commits nothing")
 ui.game.state.energy=0
 var rejected=preload("res://tests/curse_cases.gd").give(ui.game,"unlock")
 ui.render();await t.frames()
 var rejected_uid=rejected.uid
 t.check(queries.find(ui.view,"card",{"uid":rejected_uid,"target":"guard_bind","free":false}).is_empty(),"R4 unlock has no capture fact in the determination")
 if rejected_uid!="":
  if ui.card_faces.get(rejected_uid,false): await t.flip(rejected_uid)
  before=ui.game.export_snapshot()
  await _drag_card(t,rejected_uid)
  var sidebar=ui.find_child("SidebarGuardBindTarget",true,false)
  var hit=sidebar if sidebar!=null else ui.actor_targets.guard_bind
  var point=hit.get_global_rect().position+Vector2(24,hit.size.y/2.0)
  await t.move_mouse(point,true)
  t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains("这张牌不能处理捕缚。"),"R4 capture-bar drag shows the original rejection")
  await _cancel_drag(t)
  t.check(ui.game.export_snapshot()==before,"R4 cancelling a rejected capture drag commits nothing")

static func run(t) -> void:
 var display=preload("res://tests/display_ui_cases.gd")
 display.r4_display_points_do_not_read_rows(t)
 display.r4_display_facts_match_determination(t)
 query_contract(t)
 await r4_pointer_paths(t)
 await unavailable_body_hint(t)
 await bound_face_hint(t)
 await automatic_targets(t)
 await hand_targets(t)
 await copy_missing_key_never_crashes(t)
 var ui=t.ui
 ui.restart(42);await t.frames()
 t.check(not ui.show_log and ui.find_child("OpenActionLog",true,false)==null and ui.find_child("ActionSidebar",true,false)==null,"LOG starts inside menu without a separate scene panel")
 var before=ui.game.export_snapshot()
 var second=ui.view.enemies[1].id
 var layout_id=ui.layout.get_instance_id();var card_id=ui.card_buttons.values()[0].get_instance_id()
 var reads=ui.game.view_reads
 await press(t,ui.actor_targets[second])
 t.check(ui.selected_enemy==second and ui.game.export_snapshot()==before,"TARGET sprite click selects enemy without action or random change")
 t.check(ui.layout.get_instance_id()==layout_id and ui.card_buttons.values()[0].get_instance_id()==card_id and ui.game.view_reads==reads,"TARGET selection updates attacks without rebuilding scene/cards or reprojecting rules")
 var attacks=ui.view.display_facts.filter(func(c):return c.group=="attack" and ui.candidate_buttons.has(ui.display_key(c.payload)))
 t.check(attacks.size()==4 and attacks.all(func(c):return c.payload.enemy==second),"TARGET all four rendered attacks now reference clicked enemy")
 await t.open_menu();await Navigation.press(t,"OpenLog")
 t.check(ui.show_log and not ui.show_menu,"LOG menu opens one shared log drawer")
 await Navigation.press(t,"LogDetails")
 t.check(ui.find_child("LogDetailRows",true,false).is_visible_in_tree() and (ui.view.logs.is_empty() or t.visible_text(ui.find_child("LogDetailRows",true,false)).contains(ui.view.logs.back().text)),"LOG expanded details retain the latest underlying record")
 await Navigation.press(t,"LogBackToMenu")
 t.check(ui.show_menu and not ui.show_log,"LOG return restores menu without overlapping drawers")
 await Navigation.press(t,"OpenLog")
 await press(t,t.action_button("strike"))
 t.check(not ui.show_log and ui.game.export_snapshot()==before,"LOG outside click dismisses without executing the underlying attack")
 t.check(ui.layout.get_instance_id()==layout_id and ui.card_buttons.values()[0].get_instance_id()==card_id,"LOG navigation preserves scene and hand instances")
 await press(t,t.action_button("strike"))
 t.check(ui.view.energy==2,"TARGET attack executes once after log dismissal")
 for type in ["strike","heavy","kick","fireball"]:
  ui.restart(42);ui.game.state.round=2;ui.render();await t.frames()
  second=ui.view.enemies[1].id
  await press(t,ui.actor_targets[second])
  var first_hp=ui.view.enemies[0].hp;var second_hp=ui.view.enemies[1].hp
  await press(t,t.action_button(type))
  t.check(ui.view.enemies[0].hp==first_hp and ui.view.enemies[1].hp<second_hp,"TARGET clicked "+type+" attacks only selected enemy")
 # A name click switches the same selection back; a subsequent drag can still aim elsewhere.
 await Navigation.press(t,"EnemySelect_"+ui.view.enemies[0].id)
 t.check(ui.selected_enemy==ui.view.enemies[0].id,"TARGET name and sprite share selection")
 var old=ui.view.enemies[1].hp
 await t.drag_control_to(t.action_button("strike"),second)
 t.check(ui.view.enemies[1].hp<old,"TARGET drag retains actual drop target after menu log closes")
 await Navigation.press(t,"EnemySelect_"+second)
 await t.capture("ui-81-menu-log-selected-target.png")
 await press(t,ui.actor_targets[second])
 await t.capture("ui-82-collapsed-action-log.png")
 # Rejections stay beside the hovered target; legal actor hints appear together.
 ui.restart(42);await t.frames()
 before=ui.game.export_snapshot()
 second=ui.view.enemies[1].id
 for stale in [true,false]:
  var button=t.action_button("fireball")
  button.drag_payload.version=ui.view.version-1 if stale else ui.view.version
  var point=button.get_global_rect().get_center()
  await t.move_mouse(point)
  await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
  await t.move_mouse(point+Vector2(0,-42),true)
  await t.move_mouse(ui.actor_targets[second].get_global_rect().get_center(),true)
  t.check(t.root.gui_is_dragging(),"TARGET fireball uses native drag for current and expired requests")
  t.check(ui.drag_hints.size()==(0 if stale else ui.view.enemies.filter(func(e):return not e.gone).size()),"TARGET all and only legal enemy hints are visible together")
  if stale:
   t.check(is_instance_valid(ui.term_popup) and ui.term_anchor==ui.actor_targets[second] and t.visible_text(ui.term_popup).contains("行动已失效"),"TARGET expired drag shows rejection beside its actual target")
   var popup_id=ui.term_popup.get_instance_id() if is_instance_valid(ui.term_popup) else 0
   await t.frames()
   t.check(is_instance_valid(ui.term_popup) and ui.term_popup.get_instance_id()==popup_id,"TARGET repeated drag validation reuses rejection popup")
   point=Vector2(770,200)
   await t.move_mouse(point,true)
   await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
   t.check(not is_instance_valid(ui.term_popup) or (not ui.term_popup.has_meta("drag_reason") and ui.term_anchor!=ui.actor_targets[second]),"TARGET leaving and cancelling expired drag clears its target rejection; unrelated hover tips remain allowed")
   t.check(ui.game.export_snapshot()==before,"TARGET cancelling expired drag spends nothing")
  else:
   t.check(not is_instance_valid(ui.term_popup) and ui.game.export_snapshot()==before,"TARGET valid drag has no repeated battlefield explanation and no advance payment")
   t.check(ui.drag_hints.all(func(hint):return hint.size.y<=90 and is_equal_approx(hint.size.y,hint.get_combined_minimum_size().y)),"TARGET short enemy hints shrink to wrapped content instead of retaining initial tall layout")
   await t.capture("ui-drag-clean-battlefield.png")
   var health=ui.view.enemies[1].hp;var mana=ui.view.mana;var energy=ui.view.energy
   var attack=Queries.find(ui.view,"attack",{"type":"fireball","enemy":second})
   await t.mouse_button(ui.actor_targets[second].get_global_rect().get_center(),MOUSE_BUTTON_LEFT,false)
   t.check(ui.view.enemies[1].hp<health and ui.view.mana==mana-attack.mana_payment.mana and ui.view.energy==energy-attack.cost,"TARGET clean fireball drop still damages the actual target and pays its current cost once")

static func bound_face_hint(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._discard_end();ui.game.state.equipment.clear()
 var target=ui.game.add_fixture("ankle",300,1000)
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"concentration")
 ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var before=ui.game.export_snapshot();var point=t.card_point(card.uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 await t.move_mouse(ui.body_buttons.ankle.get_global_rect().get_center(),true)
 t.check(t.root.gui_is_dragging() and ui.active_drag.get("free",false) and ui.drop_targets.keys().any(func(id):return Queries.fact_by_key(ui.view,id).payload.target==target.id),"TARGET second bound face exposes its real equipment target")
 t.check(not ui.drag_hints.any(func(hint):return hint.get_meta("target_id","")=="hero"),"TARGET second bound face never labels equipment damage as a self effect")
 await t.move_mouse(Vector2(1550,70),true);await t.mouse_button(Vector2(1550,70),MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.export_snapshot()==before and ui.drag_hints.is_empty(),"TARGET cancelling second-bound-face drag preserves the full state")

static func automatic_targets(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.wall="normal"
 var wrist=ui.game.add_fixture("wrist",8);var ankle=ui.game.add_fixture("ankle",8)
 ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await t.move_mouse(ui.actor_targets.hero.get_global_rect().get_center())
 t.check(ui.actor_targets.hero.get_theme_stylebox("hover") is StyleBoxEmpty and ui.drop_targets.is_empty() and ui.drag_hints.is_empty(),"TARGET idle hero has no noninteractive highlight or target window")
 await t.move_mouse(ui.body_buttons.wrist.get_global_rect().get_center())
 t.check(ui.drop_targets.is_empty() and ui.game.export_snapshot()==before,"TARGET ordinary body hover does not open action targets")
 var card=ui.view.hand.filter(func(c):return c.type=="strain")[0]
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var point=t.card_point(card.uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 t.check(t.root.gui_is_dragging() and ui.drop_targets.is_empty(),"TARGET dragging does not open a combined equipment strip")
 for slot in ["wrist","ankle","wrist"]:
  await t.move_mouse(ui.body_buttons[slot].get_global_rect().get_center(),true)
  var ids=ui.drop_targets.keys().map(func(id):return Queries.fact_by_key(ui.view,id).payload.target)
  var expected=wrist.id if slot=="wrist" else ankle.id
  var anchor=ui.layout.get_global_transform().affine_inverse()*ui.body_buttons[slot].get_global_rect()
  t.check(ids==[expected] and ui.drop_panel.get_meta("body_id")==ui.body_buttons[slot].get_meta("body_id"),"TARGET aiming at a different region replaces the strip without other regions")
  t.check(is_equal_approx(ui.drop_panel.position.x,anchor.end.x+3) and is_equal_approx(ui.drop_panel.position.y,anchor.position.y),"TARGET strip aligns beside the aimed body in canvas coordinates")
 t.check(ui.game.export_snapshot()==before,"TARGET aiming and changing body groups never pays or changes RNG")
 await t.capture("ui-body-local-drag-targets.png")
 await t.move_mouse(Vector2(1550,70),true);await t.mouse_button(Vector2(1550,70),MOUSE_BUTTON_LEFT,false)
 t.check(ui.drop_targets.is_empty() and ui.active_drag.is_empty() and ui.drag_hints.is_empty() and ui.game.export_snapshot()==before,"TARGET cancel removes every target window without changing state")
 # Existing targeted option rows expose sibling facts, retaining the original item.
 ui.game.state.equipment.clear();wrist=ui.game.add_fixture("thigh",8)
 ui.game._gain_tool("shard");ui.render();await t.frames()
 var tool=ui.game.state.items.back().id
 await Navigation.press(t,"OpenItems");await Navigation.press(t,"ToolItem_"+tool);await Navigation.press(t,"ToolSlot_thigh")
 var choice=Queries.find(ui.view,"item",{"kind":"item_use","item":tool,"target":wrist.id})
 var button=ui.candidate_buttons[choice.key]
 point=button.get_global_rect().get_center();before=ui.game.export_snapshot()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 t.check(ui.drop_targets.is_empty(),"TARGET item drag also waits for a body region instead of merging equipment")
 await t.move_mouse(ui.body_buttons.thigh.get_global_rect().get_center(),true)
 t.check(t.root.gui_is_dragging() and ui.drop_targets.has(choice.key) and ui.game.export_snapshot()==before,"TARGET native item option drag opens its legal target without spending a use")
 var amount=ui.game._equipment(wrist.id).durability;var uses=ui.game._item(tool).uses
 await t.release_target(await t.reveal_drop_target(choice.key))
 t.check(ui.game._equipment(wrist.id).durability<amount and ui.game._item(tool).uses==uses-1 and ui.active_drag.is_empty(),"TARGET option drop submits original item candidate once and clears windows")

static func hand_targets(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 var cards=preload("res://tests/curse_cases.gd")
 var source=cards.give(ui.game,"ready_to_strike");var chosen=cards.give(ui.game,"sensitive");var peer=cards.give(ui.game,"sensitive")
 ui.render();await t.frames()
 var before=ui.game.export_snapshot();var point=t.card_point(source.uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 var first=ui.find_child("HandDragTarget_"+chosen.uid,true,false);var second=ui.find_child("HandDragTarget_"+peer.uid,true,false)
 t.check(first!=null and second!=null and ui.find_child("HandDragTarget_"+source.uid,true,false)==null and ui.game.export_snapshot()==before,"TARGET hand choice shows both legal physical cards and excludes source without payment")
 if first==null:
  await t.mouse_button(Vector2(1550,70),MOUSE_BUTTON_LEFT,false);return
 point=first.get_global_rect().get_center();await t.move_mouse(point,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.state.exhaust.any(func(c):return c.uid==chosen.uid) and ui.game.state.hand.any(func(c):return c.uid==peer.uid) and ui.view.energy==2 and ui.view.mana==90 and ui.drag_hints.is_empty(),"TARGET native hand target drop exhausts exactly the selected card and pays once")

static func unavailable_body_hint(t) -> void:
 var ui=t.ui
 for scaled in [false,true]:
  ui.restart(42);ui.game.state.equipment.clear();ui.game.state.composites.clear();ui.game.state.links.clear()
  for enemy in ui.game.state.enemies: enemy.hp=0;enemy.gone=true
  ui.game._finish_battle();ui.render();await t.frames()
  t.check(await t.click("reward",{"type":"skip"}),"TARGET unavailable-body fixture enters real preparation")
  ui.game._discard_end()
  var card=preload("res://tests/curse_cases.gd").give(ui.game,"strain")
  ui.render();await t.frames()
  if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
  if scaled:
   ui.layout.scale=Vector2(0.85,0.85);ui.layout.position=Vector2(35,25);await t.frames()
  var unavailable=ui.view.body_regions.filter(func(body):return ui._body_card_actions(body.id,card.uid).is_empty())
  var available=ui.view.body_regions.filter(func(body):return ui._body_card_actions(body.id,card.uid).any(func(c):return c.valid and c.payload.free))
  t.check(not unavailable.is_empty() and not available.is_empty(),"TARGET fixture has both unavailable and legal free region targets")
  if unavailable.is_empty() or available.is_empty(): continue
  var before=ui.game.export_snapshot();var point=t.card_point(card.uid)
  await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
  var ghost=t.root.find_child("CardDragPreview",true,false)
  t.check(ghost!=null and ghost.z_index>ui.find_child("BodyEquipmentPanel",true,false).z_index and ghost.mouse_filter==Control.MOUSE_FILTER_IGNORE and t.visible_text(ghost).contains("自由"),"TARGET card drag preview stays above body sidebar and does not intercept drops")
  for body in unavailable.slice(0,2):
   var anchor=ui.body_buttons[body.id]
   await t.move_mouse(anchor.get_global_rect().get_center(),true)
   var popup=ui.term_popup
   t.check(t.root.gui_is_dragging() and not anchor.get_meta("target_selectable",true) and ui.drop_panel==null and ui.drop_targets.is_empty(),"TARGET unavailable region remains dim and never creates an empty equipment grid")
   t.check(is_instance_valid(popup) and t.visible_text(popup).strip_edges()=="这张牌不能用于%s。" % body.name and popup.size.x>=140 and popup.size.y<90,"TARGET rejection wraps horizontally with complete body-specific reason and no scroll strip")
   if is_instance_valid(popup):
    var local_anchor=ui.layout.get_global_transform().affine_inverse()*anchor.get_global_rect()
    t.check(is_equal_approx(popup.position.x,local_anchor.end.x+12) and is_equal_approx(popup.position.y,local_anchor.position.y),"TARGET rejection uses the same canvas coordinates as its body anchor, including scaled layouts")
    var popup_id=popup.get_instance_id()
    await t.move_mouse(anchor.get_global_rect().get_center(),true)
    t.check(ui.term_popup.get_instance_id()==popup_id,"TARGET stationary invalid hover reuses one popup")
  if not scaled: await t.capture("ui-unavailable-body-drag.png")
  var legal=ui.body_buttons[available[0].id]
  await t.move_mouse(legal.get_global_rect().get_center(),true)
  t.check(ui.drop_panel!=null and not ui.drop_targets.is_empty() and (not is_instance_valid(ui.term_popup) or not ui.term_popup.has_meta("drag_reason")),"TARGET moving to a legal region replaces rejection with real targets")
  await t.move_mouse(ui.body_buttons[unavailable[0].id].get_global_rect().get_center(),true)
  t.check(ui.drop_panel==null and is_instance_valid(ui.term_popup),"TARGET returning to unavailable region removes previous legal strip and restores reason")
  await t.mouse_button(ui.body_buttons[unavailable[0].id].get_global_rect().get_center(),MOUSE_BUTTON_LEFT,false)
  t.check(ui.game.export_snapshot()==before and ui.drop_panel==null and ui.drop_targets.is_empty() and (not is_instance_valid(ui.term_popup) or not ui.term_popup.has_meta("drag_reason")),"TARGET rejected drop clears hints without spending cards, energy, turns or RNG")
 ui.layout.scale=Vector2.ONE;ui.layout.position=Vector2.ZERO
 ui.restart(42);await t.frames()
