extends RefCounted
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 t.check(await t.click("departure",{"op":"skip"}) and ui.view.phase=="map","ROUTE leaves the real opening choice before testing the map")
 var graph=ui.find_child("TowerRoute",true,false)
 var scroll=ui.find_child("TowerMapScroll",true,false)
 var before=ui.game.export_snapshot()
 var workspace=ui.find_child("RouteWorkspace",true,false)
 var messages_panel=ui.find_child("RouteMessages",true,false)
 var relics=ui.find_child("RelicStrip",true,false)
 t.check(workspace.get_global_rect()==Rect2(376,68,1212,820),"ROUTE fills main area below header to bottom edge")
 t.check(messages_panel.size.x<=240 and scroll.size.x>900 and scroll.size.y>720,"ROUTE map receives width and height while messages remain narrow")
 t.check(relics.get_parent()==scroll.get_parent() and relics.get_global_rect().position.x==scroll.get_global_rect().position.x and relics.get_global_rect().end.y<=scroll.get_global_rect().position.y,"ROUTE relics share map upper-left without overlapping its nodes")
 var relic=relics.find_child("RelicShortcut_*",true,false)
 await t.move_mouse(relic.get_global_rect().get_center());await t.frames()
 t.check(is_instance_valid(ui.term_popup) and ui.game.export_snapshot()==before,"ROUTE relocated relic retains hover details without changing state")
 await t.capture("ui-map-expanded.png")

 # Native right drag draws over even a live node, without moving or spending.
 var drawing_room=ui.view.route.filter(func(room):return room.status=="available")[0]
 var ink_start=graph.get_global_transform()*graph.point_for(drawing_room)
 await t.move_mouse(ink_start);await t.mouse_button(ink_start,MOUSE_BUTTON_RIGHT,true)
 await draw_motion(t,ink_start+Vector2(35,-20))
 await draw_motion(t,ink_start+Vector2(70,10))
 await t.mouse_button(ink_start+Vector2(70,10),MOUSE_BUTTON_RIGHT,false)
 var stored_ink=graph.strokes.duplicate(true)
 t.check(stored_ink.size()==1 and stored_ink[0].size()>=3 and not graph.drawing,"ROUTE right drag creates and finishes a freehand stroke over a room")
 t.check(ui.game.export_snapshot()==before,"ROUTE drawing never departs, spends resources, logs or changes randomness")
 var ink_scroll=scroll.scroll_vertical
 scroll.scroll_vertical=maxi(0,ink_scroll-100);await t.frames()
 t.check(graph.strokes==stored_ink and absf((graph.get_global_transform()*graph.ink_position(stored_ink[0][0])).y-ink_start.y-(ink_scroll-scroll.scroll_vertical))<1.0,"ROUTE marks scroll with the graph")
 scroll.scroll_vertical=ink_scroll;await t.frames()
 # Leaving the paper lifts the pencil instead of connecting across the side panel.
 var outside=scroll.get_global_rect().end+Vector2(80,-40)
 await t.move_mouse(ink_start);await t.mouse_button(ink_start,MOUSE_BUTTON_RIGHT,true)
 await draw_motion(t,outside);await draw_motion(t,ink_start+Vector2(10,-10))
 t.check(graph.strokes.size()==3,"ROUTE leaving and reentering the map starts a separate segment")
 await t.mouse_button(outside,MOUSE_BUTTON_RIGHT,false)
 var ended=graph.strokes.duplicate(true)
 await t.move_mouse(ink_start)
 t.check(not graph.drawing and graph.strokes==ended,"ROUTE release outside the map cannot leave the pencil stuck")
 await t.move_mouse(outside);await t.mouse_button(outside,MOUSE_BUTTON_RIGHT,true)
 await draw_motion(t,ink_start);await t.mouse_button(ink_start,MOUSE_BUTTON_RIGHT,false)
 t.check(graph.strokes==ended,"ROUTE right drag starting outside the map does not draw")
 stored_ink=graph.strokes.duplicate(true)
 await t.capture("ui-map-freehand.png")
 # The art is presentation only: both sizes retain the real route and controls.
 await t.capture("ui-117-map-art-detail.png")
 for room in ui.view.route:
  t.check(graph.buttons.has(room.id) and graph.buttons[room.id].get_global_rect().has_point(graph.get_global_transform()*graph.point_for(room)),"ROUTE artwork and actual room hit target align "+room.id)
 t.check(graph.buttons.values().all(func(button):return button.tooltip_text.is_empty()),"ROUTE every room kind has no hover popup")
 var hover_room=ui.view.route.filter(func(room):return room.status=="available")[0].id
 await t.move_mouse(graph.buttons[hover_room].get_global_rect().get_center())
 await t.create_timer(float(ProjectSettings.get_setting("gui/timers/tooltip_delay_sec",0.5))+0.1).timeout
 t.check(graph.hovered==hover_room and not is_instance_valid(ui.term_popup) and t.root.get_children().all(func(child):return not child is PopupPanel) and ui.game.export_snapshot()==before,"ROUTE native hover only highlights node, opens no popup and leaves state untouched")
 await t.capture("ui-map-hover-no-popup.png")
 await Pointer.press(t,ui.find_child("MapOverview",true,false))
 graph=ui.find_child("TowerRoute",true,false)
 t.check(graph.compact and graph.buttons.size()==ui.view.route.size() and ui.game.export_snapshot()==before,"ROUTE art overview preserves rooms, rules and randomness")
 t.check(graph.strokes==stored_ink and graph.ink_position(stored_ink[0][0]).distance_to(graph.point_for(drawing_room))<1.0,"ROUTE overview keeps marks aligned to their original room")
 await t.capture("ui-118-map-art-overview.png")
 await Pointer.press(t,ui.find_child("MapLocate",true,false))
 graph=ui.find_child("TowerRoute",true,false)
 scroll=ui.find_child("TowerMapScroll",true,false)
 t.check(not graph.compact and scroll.scroll_vertical>0 and ui.game.export_snapshot()==before,"ROUTE locate restores detailed art without submitting a move")
 t.check(graph.strokes==stored_ink,"ROUTE rebuild and locate preserve drawings")
 ui.show_tutorial=true;ui.render();await t.frames()
 graph=ui.find_child("TowerRoute",true,false)
 await t.move_mouse(ink_start);await t.mouse_button(ink_start,MOUSE_BUTTON_RIGHT,true)
 await draw_motion(t,ink_start+Vector2(20,10));await t.mouse_button(ink_start+Vector2(20,10),MOUSE_BUTTON_RIGHT,false)
 t.check(graph.strokes==stored_ink,"ROUTE tutorial overlay blocks drawing on the map below")
 ui.show_tutorial=false;ui.render();await t.frames()
 graph=ui.find_child("TowerRoute",true,false);scroll=ui.find_child("TowerMapScroll",true,false)
 await Pointer.press(t,ui.find_child("MapClearDrawing",true,false))
 t.check(graph.strokes.is_empty() and ui.game.export_snapshot()==before,"ROUTE clear removes only annotations")
 var available=ui.view.route.filter(func(r):return r.status=="available")[0].id
 var point=graph.buttons[available].get_global_rect().get_center()
 var offset=scroll.scroll_vertical
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await t.move_mouse(point+Vector2(0,140),true)
 await t.mouse_button(point+Vector2(0,140),MOUSE_BUTTON_LEFT,false)
 t.check(ui.view.phase=="map" and ui.game.export_snapshot()==before,"ROUTE dragging an available node never departs")
 t.check(scroll.scroll_vertical<offset,"ROUTE hold left mouse pans the map")
 # Wheel remains available; future room click cannot create a departure.
 scroll.scroll_vertical=0;await t.frames()
 point=graph.buttons.exit.get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.export_snapshot()==before,"ROUTE unreachable node cannot advance")
 await Pointer.press(t,ui.find_child("MapLocate",true,false))
 graph=ui.find_child("TowerRoute",true,false)
 t.check(ui.find_child("TravelMessageScroll",true,false)!=null,"ROUTE right column is a movement message scroller")
 t.check(not t.visible_text(ui.layout).contains("前往01"),"ROUTE no duplicate destination button list")
 # Multi-turn input fixture: real departure and per-turn commands remain authoritative.
 ui.game.add_fixture("ankle",4)
 ui.render();await t.frames()
 graph=ui.find_child("TowerRoute",true,false)
 point=graph.buttons[available].get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.view.phase=="travel" and ui.view.journey.target==available and ui.view.journey.total==5,"ROUTE native node click starts exact five-turn journey")
 await Pointer.press(t,ui.find_child("TravelToggle",true,false))
 var turns=ui.view.travel_turns
 await t.create_timer(0.55).timeout
 t.check(ui.view.travel_turns==turns,"ROUTE pause stops queued automatic movement")
 await t.capture("ui-98-map-messages.png")
 await Pointer.press(t,ui.find_child("TravelToggle",true,false))
 var deadline=Time.get_ticks_msec()+5000
 while ui.view.phase=="travel" and Time.get_ticks_msec()<deadline: await t.frames()
 t.check(ui.view.phase=="battle" and ui.game.state.room==available and ui.view.travel_turns==5,"ROUTE automatic travel commits all five turns exactly once")
 t.check(ui.view.travel_log.size()>=6 and ui.view.travel_log.back().turn==5,"ROUTE message feed includes departure, movement and arrival")
 ui.show_route=true;ui.render();await t.frames()
 await t.capture("ui-99-map-arrival.png")
 # A timer from a replaced run must not advance the new run.
 graph=ui.find_child("TowerRoute",true,false)
 graph.strokes.append(PackedVector2Array([Vector2(0.5,0.5)]))
 ui.restart(42);await t.frames()
 t.check(await t.click("departure",{"op":"skip"}),"ROUTE restarted game completes its own opening choice")
 t.check(ui.find_child("TowerRoute",true,false).strokes.is_empty(),"ROUTE new run starts with a clean map")
 graph=ui.find_child("TowerRoute",true,false)
 available=ui.view.route.filter(func(r):return r.status=="available")[0].id
 graph.buttons[available].pressed.emit();await t.frames()
 ui.restart(43);await t.frames()
 before=ui.game.export_snapshot()
 await t.create_timer(0.55).timeout
 t.check(ui.game.export_snapshot()==before,"ROUTE replacing a run invalidates pending movement")

 # Adjacent floor is insufficient: only visible outgoing edges can be used.
 t.check(await t.click("departure",{"op":"skip"}),"ROUTE replacement game enters its own map after the stale timer is rejected")
 var source=ui.game.state.rooms.filter(func(r):return r.floor==0)[0]
 ui.game.state.room=source.id;ui.game.state.phase="map";ui.game.state.completed_rooms=[source.id];ui.game.state.energy=0
 ui.render();await t.frames()
 graph=ui.find_child("TowerRoute",true,false)
 var disconnected=ui.view.route.filter(func(r):return r.floor==source.floor+1 and r.id not in source.next)[0]
 var connected=ui.view.route.filter(func(r):return r.id==source.id)[0].paths.filter(func(p):return p.status=="available").map(func(p):return p.to)
 t.check(connected==source.next and disconnected.status!="available","ROUTE only actual outgoing paths light up")
 scroll=ui.find_child("TowerMapScroll",true,false)
 scroll.ensure_control_visible(graph.buttons[disconnected.id]);await t.frames()
 before=ui.game.export_snapshot()
 await Pointer.press(t,graph.buttons[disconnected.id])
 t.check(ui.game.export_snapshot()==before and graph.buttons[disconnected.id].disabled and graph.buttons[disconnected.id].mouse_default_cursor_shape==Control.CURSOR_ARROW,"ROUTE native adjacent disconnected room is a disabled node that never moves")

 await merged_departure(t)

static func merged_departure(t) -> void:
 var ui=t.ui
 for phase in ["prepare","rest","shop","treasure","event","pack"]:
  ui.game=preload("res://tests/tower_cases.gd").departure_fixture(phase)
  ui._reset_interface(ui.game.get_view());ui.render();await t.frames()
  var before=ui.game.export_snapshot()
  await Pointer.press(t,ui.find_child("OpenMap",true,false))
  t.check(ui.find_child("TowerRoute",true,false).is_visible_in_tree() and ui.game.export_snapshot()==before,"ROUTE opening map never prematurely exits room: "+phase)
  var target=ui.game.room_data(before.room).next[0]
  var graph=ui.find_child("TowerRoute",true,false)
  var scroll=ui.find_child("TowerMapScroll",true,false)
  scroll.ensure_control_visible(graph.buttons[target]);await t.frames()
  t.check(ui.view.route.filter(func(r):return r.id==target)[0].status=="available","ROUTE next node is active without an exit-button click: "+phase)
  await Pointer.press(t,graph.buttons[target])
  ui.map_auto_travel=false
  t.check(ui.view.phase=="travel" and ui.view.journey.target==target and ui.view.version==before.version+1 and ui.game.state.completed_rooms.has(before.room),"ROUTE one native node click finishes room and departs: "+phase)
  t.check(ui.view.travel_turns==before.travel_turns,"ROUTE selected departure does not invent a movement turn: "+phase)

static func draw_motion(t,point: Vector2) -> void:
 var event=InputEventMouseMotion.new()
 event.position=point;event.global_position=point
 event.relative=point-t.mouse_position;t.mouse_position=point
 event.button_mask=MOUSE_BUTTON_MASK_RIGHT
 t.root.push_input(event,true);await t.frames()
