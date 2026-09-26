extends RefCounted
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 var original_store=ui.saves;var original_persistence=ui.persistence_enabled
 var store=ui.SaveStore.new("res://build/map-drawings-"+str(Time.get_ticks_usec()))
 ui.saves=store;ui.persistence_enabled=true
 t.check(await t.click("departure",{"op":"skip"}) and ui.view.phase=="map","ROUTE leaves the real opening choice before testing the map")
 var graph=ui.find_child("TowerRoute",true,false)
 var scroll=ui.find_child("TowerMapScroll",true,false)
 var before=ui.game.export_snapshot()
 var summit=ui.view.route.filter(func(room):return room.icon=="boss")[0]
 var boss_preview=ui.find_child("TowerBossPreview",true,false)
 t.check(boss_preview!=null and boss_preview.text==summit.name and boss_preview.is_visible_in_tree(),"ROUTE actual frozen boss is visible from the bottom of the map")
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
 t.check(ui.find_child("TowerBossPreview",true,false).text==summit.name,"ROUTE overview keeps the same boss visible without rerolling")
 t.check(graph.strokes==stored_ink and graph.ink_position(stored_ink[0][0]).distance_to(graph.point_for(drawing_room))<1.0,"ROUTE overview keeps marks aligned to their original room")
 await t.capture("ui-118-map-art-overview.png")
 await Pointer.press(t,ui.find_child("MapLocate",true,false))
 graph=ui.find_child("TowerRoute",true,false)
 scroll=ui.find_child("TowerMapScroll",true,false)
 t.check(not graph.compact and scroll.scroll_vertical>0 and ui.game.export_snapshot()==before,"ROUTE locate restores detailed art without submitting a move")
 t.check(graph.strokes==stored_ink,"ROUTE rebuild and locate preserve drawings")
 var saved=ui.SaveStore.new(store.directory).read_slot("tower")
 var checkpoint=ui.game.restart_snapshot()
 t.check(saved.ok and saved.map_drawings==ui.map_drawings and saved.snapshot==checkpoint,"ROUTE completed strokes persist with the original scene checkpoint")
 await t.open_menu();await Pointer.press(t,ui.find_child("QuickSL",true,false))
 graph=ui.find_child("TowerRoute",true,false)
 t.check(graph!=null and graph.strokes==stored_ink and preload("res://tests/persistence_cases.gd").same(ui.game.state,checkpoint),"ROUTE native quick SL retains annotations while restoring gameplay")
 ui.map_drawings={};ui.saves=ui.SaveStore.new(store.directory);ui._continue_save("tower");await t.frames()
 graph=ui.find_child("TowerRoute",true,false)
 t.check(graph!=null and graph.strokes==stored_ink,"ROUTE disk load restores drawings without any in-memory cache")
 before=ui.game.export_snapshot()
 ui.show_tutorial=true;ui.render();await t.frames()
 graph=ui.find_child("TowerRoute",true,false)
 await t.move_mouse(ink_start);await t.mouse_button(ink_start,MOUSE_BUTTON_RIGHT,true)
 await draw_motion(t,ink_start+Vector2(20,10));await t.mouse_button(ink_start+Vector2(20,10),MOUSE_BUTTON_RIGHT,false)
 t.check(graph.strokes==stored_ink,"ROUTE tutorial overlay blocks drawing on the map below")
 ui.show_tutorial=false;ui.render();await t.frames()
 graph=ui.find_child("TowerRoute",true,false);scroll=ui.find_child("TowerMapScroll",true,false)
 await Pointer.press(t,ui.find_child("MapClearDrawing",true,false))
 t.check(graph.strokes.is_empty() and ui.game.export_snapshot()==before,"ROUTE clear removes only annotations")
 t.check(ui.saves.read_slot("tower").map_drawings.values().all(func(lines):return lines.is_empty()),"ROUTE clearing marks also persists to disk")
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
 t.check(ui.find_child("TowerRoute",true,false).strokes.is_empty() and ui.saves.read_slot("tower").map_drawings.values().all(func(lines):return lines.is_empty()),"ROUTE new run with the same seed starts and saves a clean map")
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
 t.check(ui.game.export_snapshot()==before and t.visible_text(ui.layout).contains("没有地图连线"),"ROUTE native adjacent disconnected room click explains rejection without moving")

 await merged_departure(t)
 await seed_chip(t)
 await run_review(t)
 ui.persistence_enabled=original_persistence;ui.saves=original_store

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

# docs/spec/seed-identity.md「证据入口」：地图角落的本局标识控件（唯一查看与复制入口）。
static func seed_chip(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 t.check(await t.click("departure",{"op":"skip"}) and ui.view.phase=="map","ROUTE seed chip fixture enters the real map")
 var identity=int(ui.game.state.initial_seed)
 var chip=ui.find_child("SeedChip",true,false)
 var panel=ui.find_child("RouteMessages",true,false)
 t.check(chip!=null and chip.text.contains("初始种子 %d" % identity) and chip.text.contains("第 1 次塔路"),"ROUTE seed chip shows initial seed and tower iteration: "+str(chip.text if chip!=null else "missing"))
 t.check(chip!=null and chip.get_global_rect().size.x>0 and panel.get_global_rect().encloses(chip.get_global_rect()),"ROUTE seed chip shows initial seed and tower iteration: the control sits inside RouteMessages")
 var clear=chip!=null
 for name in ["TowerMapScroll","TowerRoute","MapOverview","MapLocate","MapClearDrawing"]:
  var other=ui.find_child(name,true,false)
  if other==null or chip.get_global_rect().intersects(other.get_global_rect()): clear=false
 t.check(clear,"ROUTE seed chip shows initial seed and tower iteration: no overlap with the map area or existing controls")

 var store=ui.saves
 var file=store.path("tower")
 var before=ui.game.export_snapshot()
 var file_bytes=preload("res://tests/persistence_cases.gd").text_at(file)
 var file_time=preload("res://tests/persistence_cases.gd").modified(file)
 var logs=ui.game.state.logs.size()
 await Pointer.press(t,chip)
 var copied=DisplayServer.clipboard_get() if DisplayServer.get_name()!="headless" else ""
 t.check(DisplayServer.get_name()!="headless" and copied==ui.seed_report_text(),"ROUTE seed chip copies the labelled identity: the clipboard holds the report text")
 var report=ui.seed_report_text()
 t.check(report.contains("紧缚尖塔") and report.contains("初始种子 %d" % identity) and report.contains("第 1 次塔路") and report.contains("当前塔路种子 %d" % int(ui.view.seed)),"ROUTE seed chip copies the labelled identity: all four parts are present: "+report)
 t.check(chip.text=="已复制","ROUTE seed chip copies the labelled identity: the chip shows the copy caption right after the click")
 await t.create_timer(1.3).timeout
 t.check(chip.text.contains("初始种子 %d" % identity) and ui.seed_copied_until==0,"ROUTE seed chip copies the labelled identity: the caption returns after 1.2 s")
 t.check(ui.game.export_snapshot()==before and ui.game.state.logs.size()==logs and ui.view.version==before.version,"ROUTE seed chip is not part of rules, facts or randomness: clicking changes no state, log or version")
 t.check(preload("res://tests/persistence_cases.gd").text_at(file)==file_bytes and preload("res://tests/persistence_cases.gd").modified(file)==file_time,"ROUTE seed chip is not part of rules, facts or randomness: the click never writes the save")

 preload("res://tests/demo_exit_cases.gd").exit_fixture(ui.game)
 ui.show_route=false
 ui.render(ui.game.get_view());await t.frames()
 var continuation=Queries.select(ui.view,"demo_exit").filter(func(c):return c.payload.kind=="demo_continue")
 var continuation_key=String(continuation[0].get("key","")) if not continuation.is_empty() else ""
 t.check(continuation.size()==1 and continuation[0].valid and ui.candidate_buttons.has(continuation_key),"ROUTE seed chip follows a rebuilt tower: the exit screen offers the real continuation")
 if not continuation.is_empty() and ui.candidate_buttons.has(continuation_key):
  await Pointer.press(t,ui.candidate_buttons[continuation_key])
  await t.frames()
  chip=ui.find_child("SeedChip",true,false)
  t.check(ui.view.tower_generation==1 and int(ui.view.initial_seed)==identity,"ROUTE seed chip follows a rebuilt tower: the run rebuilt its tower on the same identity")
  t.check(chip!=null and chip.text.contains("第 2 次塔路") and chip.text.contains("初始种子 %d" % identity),"ROUTE seed chip follows a rebuilt tower: the chip names the second tower and the unchanged seed: "+str(chip.text if chip!=null else "missing"))
  t.check(ui.seed_report_text().contains("第 2 次塔路") and ui.seed_report_text().contains("当前塔路种子 %d" % int(ui.view.seed)),"ROUTE seed chip follows a rebuilt tower: the copy text follows the rebuilt tower seed")

 ui.game=preload("res://tests/game_fixture.gd").new(42)
 ui._reset_interface(ui.game.get_view());ui.render();await t.frames()
 t.check(ui.view.phase=="battle" and ui.find_children("SeedChip","",true,false).is_empty(),"ROUTE seed chip is bound to the route screen: the ordinary battle screen carries none")
 ui.restart(42,true,"equipment");await t.frames()
 ui.game.state.phase="cleared";ui.render();await t.frames()
 t.check(ui.view.practice and t.visible_text(ui.layout).contains("装备练习") and ui.find_children("SeedChip","",true,false).is_empty(),"ROUTE seed chip is bound to the route screen: the practice screen carries none")
 for phase in ["prepare","rest","shop","treasure","event","pack"]:
  ui.game=preload("res://tests/tower_cases.gd").departure_fixture(phase)
  ui._reset_interface(ui.game.get_view());ui.render();await t.frames()
  await Pointer.press(t,ui.find_child("OpenMap",true,false))
  t.check(ui.find_child("TowerRoute",true,false).is_visible_in_tree() and ui.find_children("SeedChip","",true,false).size()==1,"ROUTE seed chip is bound to the route screen: exactly one chip in phase "+phase)
 ui.restart(42);await t.frames()

# docs/spec/run-review.md「场景与判据（Gherkin）」：A–J 全部落在本函数与其助手内，
# 复用既有真实指针助手（Pointer）、真实开局与既有夹具；每条判据的敏感性证明见验证记录。
static func run_review(t) -> void:
 await review_is_read_only(t)
 await review_node_click_never_departs(t)
 await review_map_matches_projection(t)
 await review_progress_counts_walked_nodes(t)
 await review_deck_lists_every_card(t)
 await review_identity_reuses_report(t)
 await review_entries_follow_route(t)
 await review_behaves_like_the_shared_drawer(t)
 await review_copy_exists_in_both_languages(t)
 await review_copy_shares_the_chip(t)

# 真实开局到路线屏（塔底入口，未走过任何节点）。
static func fresh_route_screen(t) -> bool:
 var ui=t.ui
 ui.restart(42);await t.frames()
 return await t.click("departure",{"op":"skip"}) and ui.view.phase=="map"

static func open_review(t) -> void:
 var ui=t.ui
 var entry=ui.find_child("OpenRunReview",true,false)
 t.check(entry!=null,"ROUTE run review entry exists before opening it")
 if entry==null: return
 await Pointer.press(t,entry)
 t.check(ui.show_run_review and ui.find_child("InformationDrawer",true,false)!=null,"ROUTE run review entry opens the shared drawer")

static func close_review(t, where: String="") -> void:
 var ui=t.ui
 if not ui.show_run_review: return
 await Pointer.press(t,ui.find_child("CloseDrawer",true,false))
 t.check(not ui.show_run_review and ui.find_child("InformationDrawer",true,false)==null,"ROUTE run review closes through the shared close control "+where)

# 回顾地图的父节点是滚动列内的 VBoxContainer；这里同时给出可见唯一的地图控件。
static func review_map(t):
 return t.ui.find_child("RunReviewMap",true,false)

# 权威进度：completed_rooms ∪ 当前房间（= 投影里 completed／current 两个 status 的房间），
# 层号取这些房间的最大 floor ＋1；节点数是已走过房间数。面板必须与该来源逐项相同。
static func authoritative_progress(ui) -> Dictionary:
 var ids=ui.game.state.completed_rooms.duplicate()
 if ui.game.state.room not in ids: ids.append(ui.game.state.room)
 var floor=-1
 for id in ids:
  var room=ui.game.room_data(id)
  if not room.is_empty(): floor=maxi(floor,int(room.floor))
 return {"floor":maxi(0,floor+1),"nodes":ui.game.state.completed_rooms.size()}

static func projected_travelled_edges(ui) -> Array:
 var edges=[]
 for room in ui.view.route:
  for path in room.paths:
   if path.status in ["travelled","travelling"]: edges.append([room.id,path.to])
 return edges

static func panel_children_fit(panel: Control) -> bool:
 var bounds=panel.get_global_rect()
 for node in panel.find_children("*","Control",true,false):
  if not node is Control or not node.is_visible_in_tree(): continue
  if not bounds.encloses(node.get_global_rect()): return false
 return true

# 场景 A｜打开回顾屏并在面板内滚动、筛选、点击地图与复制按钮都不动规则、候选、随机与存档。
static func review_is_read_only(t) -> void:
 var ui=t.ui
 t.check(await fresh_route_screen(t),"ROUTE run review fixture enters the real map")
 var store=ui.saves
 var before=ui.game.export_snapshot()
 var facts=ui.view.display_facts.duplicate(true)
 var version=ui.view.version
 var stamp=preload("res://tests/persistence_cases.gd").stamp(store,"tower")
 await open_review(t)
 var panel=ui.find_child("InformationDrawer",true,false)
 var content_scroll=ui.find_child("RunReviewMap",true,false).get_parent().get_parent() as ScrollContainer
 content_scroll.scroll_vertical=int(content_scroll.get_v_scroll_bar().max_value);await t.frames()
 var scrolled=content_scroll.scroll_vertical
 content_scroll.scroll_vertical=0;await t.frames()
 t.check(scrolled>0,"ROUTE run review is not part of rules, facts or randomness: the panel content scrolls to the deck block")
 var costs=ui.find_child("DeckCostFilter",true,false)
 costs.select(2);costs.item_selected.emit(2);await t.frames()
 costs.select(0);costs.item_selected.emit(0);await t.frames()
 var graph=review_map(t)
 var room=ui.view.route.filter(func(r):return r.status=="available")[0]
 var point=graph.get_global_transform()*graph.point_for(room)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true)
 await draw_motion(t,point+Vector2(40,-16))
 await t.mouse_button(point+Vector2(40,-16),MOUSE_BUTTON_RIGHT,false)
 await Pointer.press(t,ui.find_child("RunReviewCopy",true,false))
 preload("res://tests/persistence_cases.gd").unchanged(t,stamp,preload("res://tests/persistence_cases.gd").stamp(store,"tower"),"run review in-panel interaction")
 t.check(ui.view.version==version and ui.view.display_facts==facts and ui.game.export_snapshot()==before,"ROUTE run review is not part of rules, facts or randomness")
 t.check(graph.strokes.is_empty(),"ROUTE run review is not part of rules, facts or randomness: the review map keeps no pencil stroke")

# 场景 B｜在回顾屏点地图节点不出发（本片最重要的反例）。
static func review_node_click_never_departs(t) -> void:
 var ui=t.ui
 t.check(ui.show_run_review and ui.view.phase=="map","ROUTE run review node click starts from the open map-phase panel")
 var available=ui.view.route.filter(func(r):return r.status=="available")
 t.check(not available.is_empty(),"ROUTE run review node click has a real departure node behind the panel")
 if available.is_empty(): return
 var before=ui.game.export_snapshot()
 var version=ui.view.version
 var completed=ui.view.rooms_completed
 var journey=ui.view.journey.duplicate(true)
 var room=ui.game.state.room
 var graph=review_map(t)
 var point=graph.get_global_transform()*graph.point_for(available[0])
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.view.phase=="map" and ui.view.rooms_completed==completed and ui.view.journey==journey and ui.view.version==version and ui.game.state.room==room and ui.game.export_snapshot()==before,"ROUTE run review node click never departs")
 t.check(graph.read_only==true and graph.buttons.is_empty(),"ROUTE run review node click never departs: the review map has no room hit target")

# 场景 C｜节点地图与 view.route 同源，已走过路径随真实行进。
static func review_map_matches_projection(t) -> void:
 var ui=t.ui
 await close_review(t,"(scenario C)")
 t.check(await fresh_route_screen(t),"ROUTE run review map fixture starts a fresh tower")
 t.check(ui.game.state.traversed_edges.is_empty(),"ROUTE run review map fixture has walked no edge yet")
 await open_review(t)
 var graph=review_map(t)
 var travelled=projected_travelled_edges(ui)
 t.check(graph.rooms==ui.view.route and travelled.is_empty() and ui.game.state.traversed_edges.is_empty(),"ROUTE run review map matches the projected route: a fresh tower keeps every room and no golden path")
 await close_review(t,"(scenario C departure)")
 var available=ui.view.route.filter(func(r):return r.status=="available")[0].id
 var route_graph=ui.find_child("TowerRoute",true,false)
 var scroll=ui.find_child("TowerMapScroll",true,false)
 scroll.ensure_control_visible(route_graph.buttons[available]);await t.frames()
 await Pointer.press(t,route_graph.buttons[available])
 ui.map_auto_travel=false
 var guard=0
 while ui.view.phase=="travel" and guard<12:
  guard+=1
  await t.click("travel_step")
 t.check(ui.view.phase=="battle" and ui.game.state.room==available and ui.game.state.traversed_edges.size()==1,"ROUTE run review map fixture walks one real edge")
 ui.show_route=true;ui.render();await t.frames()
 await open_review(t)
 graph=review_map(t)
 travelled=projected_travelled_edges(ui)
 var walked=ui.game.state.traversed_edges
 t.check(graph.rooms==ui.view.route and travelled.size()==1 and travelled[0]==walked[0] and walked.size()==1,"ROUTE run review map matches the projected route: the walked edge is the only golden path and equals state.traversed_edges")

# 场景 D｜进度行取自同一投影并与权威状态一致。
static func review_progress_counts_walked_nodes(t) -> void:
 var ui=t.ui
 await close_review(t,"(scenario D)")
 t.check(await fresh_route_screen(t),"ROUTE run review progress fixture starts a fresh tower")
 t.check(ui.game.state.room=="entrance" and ui.game.state.completed_rooms.is_empty(),"ROUTE run review progress fixture stands on the tower bottom with no walked room")
 await open_review(t)
 var progress=ui.find_child("RunReviewProgress",true,false)
 var expected=authoritative_progress(ui)
 t.check(progress.text==ui._text("ui.run_review.progress","已到达第 {floor} 层 · 已走过 {nodes} 个节点",expected) and expected=={"floor":0,"nodes":0} and ui.view.run_header.location=="第0层","ROUTE run review progress counts the walked nodes: "+str(progress.text))
 await close_review(t,"(scenario D departure)")
 var available=ui.view.route.filter(func(r):return r.status=="available")[0].id
 var route_graph=ui.find_child("TowerRoute",true,false)
 var scroll=ui.find_child("TowerMapScroll",true,false)
 scroll.ensure_control_visible(route_graph.buttons[available]);await t.frames()
 await Pointer.press(t,route_graph.buttons[available])
 ui.map_auto_travel=false
 var guard=0
 while ui.view.phase=="travel" and guard<12:
  guard+=1
  await t.click("travel_step")
 ui.show_route=true;ui.render();await t.frames()
 await open_review(t)
 progress=ui.find_child("RunReviewProgress",true,false)
 expected=authoritative_progress(ui)
 # The tower bottom never enters completed_rooms, so after one real edge the floor moves 0 -> 1
 # while the walked-node count still equals state.completed_rooms.size().
 t.check(progress.text==ui._text("ui.run_review.progress","已到达第 {floor} 层 · 已走过 {nodes} 个节点",expected) and expected.nodes==ui.game.state.completed_rooms.size() and expected.floor==1 and ui.view.run_header.location=="第1层","ROUTE run review progress counts the walked nodes: after the real departure it follows the authoritative count: "+str(progress.text))

# 场景 E｜卡组条数等于 view.deck_cards.size()。
static func review_deck_lists_every_card(t) -> void:
 var ui=t.ui
 t.check(ui.show_run_review,"ROUTE run review deck probe runs with the panel open")
 var deck=ui.find_child("RunReviewDeck",true,false)
 var grid=ui.find_child("DeckGrid",true,false)
 var counter=ui.find_child("DeckCount",true,false)
 t.check(deck!=null and grid!=null and counter!=null,"ROUTE run review deck lists every physical card: the shared browser is in the panel")
 if deck==null or grid==null or counter==null: return
 var total=int(counter.text.split("/")[1].strip_edges().split(" ")[0])
 t.check(deck.cards.size()==ui.view.deck_cards.size() and grid.get_child_count()==ui.view.deck_cards.size() and total==ui.view.deck_cards.size(),"ROUTE run review deck lists every physical card: "+str(counter.text))
 var search=ui.find_child("DeckSearch",true,false)
 search.text="没有这张卡";search.text_changed.emit(search.text);await t.frames()
 var filtered=int(counter.text.split("/")[1].strip_edges().split(" ")[0])
 t.check(grid.get_child_count()==0 and filtered==ui.view.deck_cards.size(),"ROUTE run review deck lists every physical card: the search narrows the numerator and keeps the denominator")
 search.text="";search.text_changed.emit("");await t.frames()

# 场景 F｜种子文本与 seed_report_text() 同源，并随真实重建的塔路变化。
static func review_identity_reuses_report(t) -> void:
 var ui=t.ui
 var identity=ui.find_child("RunReviewIdentity",true,false)
 var copy=ui.find_child("RunReviewCopy",true,false)
 var generation=ui.view.tower_generation
 t.check(identity!=null and copy!=null and identity.text==ui.seed_report_text(),"ROUTE run review identity reuses the run report text: "+str(identity.text))
 t.check(copy!=null and copy.text==ui._text("ui.run_review.copy","复制本局标识"),"ROUTE run review identity reuses the run report text: the copy button carries the registered caption")
 await close_review(t,"(scenario F)")
 preload("res://tests/demo_exit_cases.gd").exit_fixture(ui.game)
 ui.show_route=false
 ui.render(ui.game.get_view());await t.frames()
 var continuation=Queries.select(ui.view,"demo_exit").filter(func(c):return c.payload.kind=="demo_continue")
 var continuation_key=String(continuation[0].get("key","")) if not continuation.is_empty() else ""
 t.check(continuation.size()==1 and continuation[0].valid and ui.candidate_buttons.has(continuation_key),"ROUTE run review identity reuses the run report text: the exit screen offers the real continuation")
 if continuation.is_empty() or not ui.candidate_buttons.has(continuation_key): return
 await Pointer.press(t,ui.candidate_buttons[continuation_key])
 await t.frames()
 t.check(ui.view.tower_generation==generation+1,"ROUTE run review identity reuses the run report text: the run rebuilt its tower")
 await open_review(t)
 identity=ui.find_child("RunReviewIdentity",true,false)
 t.check(identity.text==ui.seed_report_text() and ui.view.tower_generation==generation+1,"ROUTE run review identity reuses the run report text: the rebuilt tower keeps the report text source")

# 场景 G｜入口可见性跟随路线数据（练习局与牢房不摆空壳，两屏各恰好一个）。
static func review_entries_follow_route(t) -> void:
 var ui=t.ui
 await close_review(t,"(scenario G)")
 ui.restart(42,true,"equipment");await t.frames()
 t.check(ui.view.route.is_empty() and ui.find_children("OpenRunReview","",true,false).is_empty(),"ROUTE run review entries follow the route data: a practice run shows no entry")
 await preload("res://tests/prison_ui_cases.gd").enter(t)
 t.check(ui.view.phase=="prison" and ui.view.route.is_empty() and ui.find_children("OpenRunReview","",true,false).is_empty(),"ROUTE run review entries follow the route data: the prison cell shows no entry")
 t.check(await fresh_route_screen(t),"ROUTE run review entries follow the route data: the route screen fixture is real")
 var entries=ui.find_children("OpenRunReview","",true,false)
 var workspace=ui.find_child("RouteWorkspace",true,false)
 var clear_of_others=true
 if entries.size()==1:
  for name in ["TowerMapScroll","TowerRoute","MapOverview","MapLocate","MapClearDrawing","SeedChip"]:
   var other=ui.find_child(name,true,false)
   if other==null or entries[0].get_global_rect().intersects(other.get_global_rect()): clear_of_others=false
 t.check(entries.size()==1 and workspace.get_global_rect().encloses(entries[0].get_global_rect()) and clear_of_others,"ROUTE run review entries follow the route data: exactly one entry inside RouteWorkspace without overlapping the existing map controls")
 preload("res://tests/demo_exit_cases.gd").exit_fixture(ui.game)
 ui.show_route=false
 ui.render(ui.game.get_view());await t.frames()
 var panel=ui.find_child("DemoExitPanel",true,false)
 entries=ui.find_children("OpenRunReview","",true,false)
 t.check(entries.size()==1 and panel.get_global_rect().encloses(entries[0].get_global_rect()),"ROUTE run review entries follow the route data: the exit screen shows one entry inside its panel")
 t.check(panel_children_fit(panel) and panel.get_global_rect().size==Vector2(680,520),"ROUTE run review entries follow the route data: the exit screen panel holds every visible control: "+str(panel.get_global_rect()))
 ui.game.state.demo_finished=true;ui.render();await t.frames()
 panel=ui.find_child("DemoExitPanel",true,false)
 entries=ui.find_children("OpenRunReview","",true,false)
 t.check(entries.size()==1 and t.visible_text(panel).contains("返回菜单") and panel_children_fit(panel) and panel.get_global_rect().size==Vector2(680,520),"ROUTE run review entries follow the route data: the finished exit screen keeps one entry inside the panel: "+str(panel.get_global_rect())+" "+str(entries.size()))

# 场景 H｜抽屉机制与既有面板一致，点击不穿透。
static func review_behaves_like_the_shared_drawer(t) -> void:
 var ui=t.ui
 await close_review(t,"(scenario H)")
 t.check(await fresh_route_screen(t),"ROUTE run review drawer fixture enters the real map")
 t.check(ui.view.route.any(func(r):return r.status=="available"),"ROUTE run review drawer fixture keeps a clickable node behind the panel")
 await open_review(t)
 var before=ui.game.export_snapshot()
 var dismiss=ui.find_child("DismissDrawer",true,false)
 var panel=ui.find_child("InformationDrawer",true,false)
 t.check(dismiss.get_global_rect()==Rect2(0,0,1600,900),"ROUTE run review behaves like the shared drawer: the dismiss surface covers the whole viewport")
 var mask_point=Vector2(24,panel.get_global_rect().get_center().y)
 await t.move_mouse(mask_point);await t.mouse_button(mask_point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(mask_point,MOUSE_BUTTON_LEFT,false)
 t.check(not ui.show_run_review and ui.find_child("InformationDrawer",true,false)==null and ui.game.export_snapshot()==before,"ROUTE run review behaves like the shared drawer: the mask closes without passing the click through")
 await open_review(t)
 await Pointer.press(t,ui.find_child("CloseDrawer",true,false))
 t.check(not ui.show_run_review and ui.find_child("InformationDrawer",true,false)==null and ui.game.export_snapshot()==before,"ROUTE run review behaves like the shared drawer: the close control closes without passing the click through")
 await open_review(t)
 var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;t.root.push_input(escape,true)
 escape=escape.duplicate();escape.pressed=false;t.root.push_input(escape,true);await t.frames()
 t.check(not ui.show_run_review and ui.find_child("InformationDrawer",true,false)==null and ui.game.export_snapshot()==before,"ROUTE run review behaves like the shared drawer: Escape closes it")
 await open_review(t)
 panel=ui.find_child("InformationDrawer",true,false)
 var inside=review_map(t).get_global_rect().get_center()
 await t.move_mouse(inside);await t.mouse_button(inside,MOUSE_BUTTON_LEFT,true);await t.mouse_button(inside,MOUSE_BUTTON_LEFT,false)
 t.check(ui.show_run_review and ui.game.export_snapshot()==before,"ROUTE run review behaves like the shared drawer: a click inside the panel neither closes it nor reaches the action behind")

# 场景 I｜两种语言都有文案，无缺译诊断，无投影缺失。
static func review_copy_exists_in_both_languages(t) -> void:
 var ui=t.ui
 await close_review(t,"(scenario I)")
 t.check(await fresh_route_screen(t),"ROUTE run review language fixture enters the real map")
 await open_review(t)
 t.check(ui.localization.diagnostics().is_empty(),"ROUTE run review copy exists in both languages and records no miss: the zh_CN panel records no diagnostic")
 var chinese=preload("res://tests/localization_ui_cases.gd").chinese_runs
 ui._set_language("en_US");await t.frames()
 var panel=ui.find_child("InformationDrawer",true,false)
 var keys=[["ui.run_review.title","本局回顾"],["ui.run_review.identity","本局标识"],["ui.run_review.route","节点概况"],["ui.run_review.deck","卡组"],["ui.run_review.progress","已到达第 {floor} 层 · 已走过 {nodes} 个节点"],["ui.run_review.no_route","没有可回顾的路线数据。"],["ui.run_review.deck_empty","卡组为空。"],["ui.run_review.copy","复制本局标识"]]
 var unresolved=[]
 for entry in keys:
  # 进度行带参数：缺参调用会记 call_parameters 并回退到中文错误文案，这里按真实调用形状取文案。
  var params={"floor":0,"nodes":0} if entry[0]=="ui.run_review.progress" else {}
  if chinese.call(ui._text(entry[0],entry[1],params)).size()>0: unresolved.append(entry[0])
 t.check(unresolved.is_empty(),"ROUTE run review copy exists in both languages and records no miss: every registered caption resolves in English: "+str(unresolved))
 panel=ui.find_child("InformationDrawer",true,false)
 var identity=ui.find_child("RunReviewIdentity",true,false)
 var identity_runs=chinese.call(identity.text)
 var leftovers=chinese.call(t.visible_text(panel)).filter(func(run):return run not in identity_runs)
 t.check(leftovers.is_empty(),"ROUTE run review copy exists in both languages and records no miss: the English panel keeps no Chinese outside the identity report: "+str(leftovers))
 t.check(ui.projection_misses.is_empty(),"ROUTE run review copy exists in both languages and records no miss: the panel reads no display-set card entry")
 ui._set_language("zh_CN");await t.frames()
 t.check(ui.find_child("RunReviewProgress",true,false).text.begins_with("已到达第"),"ROUTE run review copy exists in both languages and records no miss: switching back restores the Chinese caption")

# 场景 J｜面板复制与路线屏角标共用同一个复制入口与显示态。
static func review_copy_shares_the_chip(t) -> void:
 var ui=t.ui
 await close_review(t,"(scenario J)")
 t.check(await fresh_route_screen(t),"ROUTE run review copy fixture enters the real map")
 await open_review(t)
 var store=ui.saves
 var copy=ui.find_child("RunReviewCopy",true,false)
 var chip=ui.find_child("SeedChip",true,false)
 var before=ui.game.export_snapshot()
 var facts=ui.view.display_facts.duplicate(true)
 var version=ui.view.version
 var stamp=preload("res://tests/persistence_cases.gd").stamp(store,"tower")
 t.check(copy!=null and chip!=null,"ROUTE run review copy shares the chip display state: both views are on screen")
 await Pointer.press(t,copy)
 var copied=DisplayServer.clipboard_get() if DisplayServer.get_name()!="headless" else ""
 t.check(DisplayServer.get_name()!="headless" and copied==ui.seed_report_text(),"ROUTE run review copy shares the chip display state: the panel button copies the labelled identity")
 t.check(ui.seed_copied_until>Time.get_ticks_msec() and chip.text==ui._text("ui.map.seed_copied","已复制") and copy.text==ui._text("ui.map.seed_copied","已复制"),"ROUTE run review copy shares the chip display state: both views show the copy caption in the same window")
 preload("res://tests/persistence_cases.gd").unchanged(t,stamp,preload("res://tests/persistence_cases.gd").stamp(store,"tower"),"run review copy")
 t.check(ui.view.version==version and ui.view.display_facts==facts and ui.game.export_snapshot()==before,"ROUTE run review copy shares the chip display state: the click changes no rules, candidate or save")
 await t.create_timer(1.3).timeout
 t.check(chip.text==ui._seed_chip_text() and copy.text==ui._text("ui.run_review.copy","复制本局标识") and ui.seed_copied_until==0,"ROUTE run review copy shares the chip display state: both views restore together after 1.2 s")
 await Pointer.press(t,copy)
 await close_review(t,"(scenario J after copy)")
 await t.create_timer(1.3).timeout
 t.check(ui.find_child("SeedChip",true,false).text==ui._seed_chip_text() and ui.seed_copied_until==0,"ROUTE run review copy shares the chip display state: the closed panel leaves the chip caption restoring on its own")

static func draw_motion(t,point: Vector2) -> void:
 var event=InputEventMouseMotion.new()
 event.position=point;event.global_position=point
 event.relative=point-t.mouse_position;t.mouse_position=point
 event.button_mask=MOUSE_BUTTON_MASK_RIGHT
 t.root.push_input(event,true);await t.frames()
