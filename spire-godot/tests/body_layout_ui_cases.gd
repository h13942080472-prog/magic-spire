extends RefCounted
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var display=preload("res://tests/display_ui_cases.gd")
 display.r4_display_points_do_not_read_rows(t)
 display.r4_display_facts_match_determination(t)
 var ui=t.ui
 await nipple_region(t)
 var portrait=ui.find_child("EquipmentPortrait",true,false)
 var panel=ui.find_child("BodyEquipmentPanel",true,false)
 t.check(portrait.texture.get_image().detect_alpha()!=Image.ALPHA_NONE and portrait.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"BODY transparent original portrait keeps aspect ratio")
 var slots=["region_head","region_upper","region_intimate","region_lower"]
 var previous=0.0
 for slot in slots:
  var rect=ui.body_buttons[slot].get_global_rect()
  t.check(rect.position.y>previous and panel.get_global_rect().encloses(rect) and rect.position.x>=portrait.get_global_rect().end.x,"BODY four anatomical region entries fit beside portrait: "+slot)
  previous=rect.position.y
 t.check(ui.find_child("EquipmentDetails",true,false)==null,"BODY compact sidebar starts without large details overlay")
 await t.capture("ui-83-portrait-equipment-sidebar.png")
 var before=ui.game.export_snapshot()
 await t.inspect_body("toes")
 t.check(ui.game.export_snapshot()==before and t.visible_text(ui.find_child("EquipmentDetails",true,false)).contains("脚趾"),"BODY inspecting lowest free slot spends no resources or turn")
 await Pointer.press(t,ui.find_child("CloseEquipmentDetails",true,false))
 t.check(ui.find_child("EquipmentDetails",true,false)==null and ui.view.body_groups.size()==14,"BODY closing details preserves all body targets")
 await t.start_practice("Practice_head_harness")
 before=ui.game.export_snapshot()
 await t.inspect_body("eyes")
 t.check(ui.game.export_snapshot()==before and t.visible_text(ui.find_child("EquipmentDetails",true,false)).contains("眼罩"),"BODY head details show actual equipment without action")
 var cards=ui.find_child("EquipmentDetails",true,false).find_children("EquipmentCard_*","PanelContainer",true,false)
 t.check(cards.size()==2 and cards[0].get_parent() is GridContainer and cards[0].get_parent().columns==1,"BODY masks use one readable vertical layer sequence")
 var first_rect=cards[0].get_global_rect()
 var second_rect=cards[1].get_global_rect()
 t.check(first_rect.end.y<=second_rect.position.y and is_equal_approx(first_rect.position.x,second_rect.position.x),"BODY layer rows follow vertically without overlap")
 var toggle=cards[0].find_child("EquipmentCardDetailsToggle",true,false)
 t.check(cards.all(func(card):return card.find_child("EquipmentActions",true,false).get_child_count()==0),"BODY collapsed equipment does not build hidden action trees")
 await Pointer.press(t,toggle)
 t.check(toggle.text.contains("收起") and cards[0].find_child("EquipmentActions",true,false).visible and ui.game.export_snapshot()==before,"BODY expanding equipment reveals methods without state changes")
 var action_panel=cards[0].find_child("EquipmentActions",true,false)
 var retained_children=action_panel.get_children()
 toggle.pressed.emit();toggle.pressed.emit();await t.frames()
 t.check(action_panel.get_children()==retained_children and ui.game.export_snapshot()==before,"BODY reopening details reuses their controls without duplicating actions or spending resources")
 await Pointer.press(t,toggle)
 t.check(toggle.text.contains("查看") and not t.visible_text(cards[0]).contains("视觉受阻") and ui.game.export_snapshot()==before,"BODY closing card details stays local and preserves gameplay")
 await t.capture("ui-84-body-equipment-details.png")
 var uid=ui.view.hand.filter(func(c):return c.type=="slip")[0].uid
 await t.start_drag(uid,"eyes")
 t.check(ui.find_child("EquipmentPortrait",true,false).is_visible_in_tree(),"BODY existing portrait stays visible while dragging to equipment")
 await t.capture("ui-85-body-card-drop.png")
 await t.mouse_button(Vector2(1100,90),MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.export_snapshot()==before,"BODY cancelling drag out of target spends nothing")
 await t.start_practice("Practice_jacket")
 await t.inspect_body("hands")
 var detail=ui.find_child("EquipmentDetails",true,false)
 cards=detail.find_children("EquipmentCard_*","PanelContainer",true,false)
 t.check(cards.size()==1 and t.visible_text(cards[0]).contains("左手掌、右手掌"),"BODY shared jacket appears once with both palm locations")
 t.check(cards[0].size.x>300 and cards[0].get_parent().columns==1,"BODY single card uses available width instead of leaving an empty column")
 t.check(cards[0].find_child("EquipmentActions",true,false).visible,"BODY shared physical equipment opens actions once despite covering several subslots")
 await t.capture("ui-109-compact-jacket-card.png")
 ui.game=preload("res://tests/game_fixture.gd").new(42)
 ui.game.add_fixture("palm",4)
 ui.game.add_fixture("fingers",4)
 ui.render();await t.frames();await t.inspect_body("hands")
 detail=ui.find_child("EquipmentDetails",true,false)
 cards=detail.find_children("EquipmentCard_*","PanelContainer",true,false)
 t.check(cards.size()==2 and cards[0].get_parent()==cards[1].get_parent() and cards[0].position.y<cards[1].position.y,"BODY different hand subslots keep separate labeled rows")
 t.check(t.visible_text(cards[0]).contains("手掌") and t.visible_text(cards[1]).contains("手指"),"BODY packed cards retain their exact subslot labels")
 await t.capture("ui-110-compact-cross-slot-cards.png")
 await shared_hand_target(t)
 await selection_focus(t)
 await single_click_play(t)
 await release_preview(t)
 await adaptive_regions(t)
 await applied_regions(t)
 await portrait_zoom(t)

static func nipple_region(t) -> void:
 var ui=t.ui
 ui.restart(42)
 ui.game._install_special("nipple_clamp_low","special_1_a")
 ui.render();await t.frames()
 var upper=ui.view.body_regions.filter(func(region):return region.id=="region_upper")[0]
 var intimate=ui.view.body_regions.filter(func(region):return region.id=="region_intimate")[0]
 var nipple=ui.view.body_groups.filter(func(body):return body.id=="special_1")[0]
 t.check(not upper.members.any(func(body):return body.id=="special_1") and intimate.members.map(func(body):return body.id)==["special_1","special_2","special_3"],"BODY nipple group belongs to genital region")
 t.check(intimate.targets.keys()==nipple.targets.keys() and not upper.targets.keys().any(func(id):return nipple.targets.has(id)),"BODY nipple equipment and release targets project only through genital region")
 await t.inspect_body("special_1")
 t.check("region_intimate" in ui.expanded_body_regions and "region_upper" not in ui.expanded_body_regions,"BODY nipple inspection opens genital region")
 ui.restart(42);await t.frames()

static func portrait_zoom(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 var panel=ui.layout.body
 var portrait=panel.get_node("Canvas/EquipmentPortrait")
 var button=panel.get_node("Canvas/ExpandPortrait")
 var compact=panel.get_global_rect()
 var original=portrait.get_global_rect()
 var regions=ui.expanded_body_regions.duplicate()
 var before=ui.game.export_snapshot()
 t.check(original.encloses(button.get_global_rect()),"PORTRAIT zoom button fits inside original portrait area")
 await t.capture("ui-portrait-zoom-button.png")
 await Pointer.press(t,button)
 t.check(panel.portrait_expanded and is_equal_approx(panel.get_global_rect().end.y,900) and portrait.size.x>original.size.x and portrait.size.y>original.size.y,"PORTRAIT pointer opens full-height left column")
 t.check(not panel.get_node("Canvas/Slots").visible and not button.visible and portrait.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"PORTRAIT enlarged image keeps full aspect and hides body controls")
 t.check(panel.z_index>ui.find_child("ManaFlask",true,false).z_index,"PORTRAIT expanded panel covers elevated flask controls")
 t.check(panel.get_node("Canvas/PortraitBackdrop").visible and panel.get_node("Canvas/PortraitBackdrop").color.a==1.0,"PORTRAIT opaque backdrop prevents old resource controls showing through")
 ui.render(ui.view);await t.frames()
 t.check(ui.layout.body==panel and panel.get_node("Canvas/EquipmentPortrait")==portrait and panel.portrait_expanded and ui.expanded_body_regions==regions,"PORTRAIT refresh reuses image and preserves original region expansion")
 await t.capture("ui-portrait-expanded.png")
 var inside=panel.get_global_rect().get_center()
 await t.mouse_button(inside,MOUSE_BUTTON_LEFT,true);await t.mouse_button(inside,MOUSE_BUTTON_LEFT,false)
 t.check(panel.portrait_expanded and ui.game.export_snapshot()==before,"PORTRAIT left column click keeps inspection without actions")
 var outside=ui.end_button.get_global_rect().get_center()
 await t.mouse_button(outside,MOUSE_BUTTON_LEFT,true);await t.mouse_button(outside,MOUSE_BUTTON_LEFT,false)
 t.check(not panel.portrait_expanded and panel.get_global_rect()==compact and portrait.get_global_rect()==original and ui.game.export_snapshot()==before,"PORTRAIT outside action click restores exact layout without click-through")
 await Pointer.press(t,button)
 var touch=InputEventScreenTouch.new();touch.position=outside;touch.pressed=true
 t.root.push_input(touch,true);await t.frames()
 t.check(not panel.portrait_expanded,"PORTRAIT native touch press dismisses immediately before release")
 touch=InputEventScreenTouch.new();touch.position=outside;touch.pressed=false
 t.root.push_input(touch,true);await t.frames()
 t.check(not panel.portrait_expanded and ui.game.export_snapshot()==before,"PORTRAIT outside touch dismisses without gameplay changes")
 var keys=preload("res://tests/keyboard_ui_cases.gd")
 ui.keyboard_input.settings.hold_end=true
 await keys.key(t,KEY_E)
 t.check(not ui.keyboard_input.end_hold.is_empty(),"PORTRAIT fixture arms actual end-turn hold")
 await Pointer.press(t,button)
 await keys.key(t,KEY_E,false)
 await t.create_timer(0.6).timeout;await t.frames()
 t.check(ui.keyboard_input.end_hold.is_empty() and ui.keyboard_input.held_keys.is_empty() and ui.game.export_snapshot()==before,"PORTRAIT inspection cancels pending hold and clears held shortcuts")
 await keys.tap(t,KEY_ESCAPE)
 t.check(not panel.portrait_expanded,"PORTRAIT Escape restores compact layout")
 await keys.key(t,KEY_E)
 t.check(not ui.keyboard_input.end_hold.is_empty(),"PORTRAIT released shortcut works again after inspection")
 await keys.key(t,KEY_E,false)
 ui.keyboard_input.settings.hold_end=false
 await Pointer.press(t,button)
 ui.restart(42);await t.frames()
 t.check(not ui.layout.body.portrait_expanded and ui.layout.body.get_global_rect()==compact,"PORTRAIT new session restores compact sidebar")
 ui.layout.scale=Vector2(0.85,0.85);ui.layout.position=Vector2(35,25);await t.frames()
 var touch_input=preload("res://tests/touch_ui_cases.gd")
 await touch_input.tap(t,ui.layout.body.get_node("Canvas/ExpandPortrait"))
 panel=ui.layout.body
 t.check(panel.portrait_expanded,"PORTRAIT touch opens enlargement in scaled layout")
 inside=panel.get_global_rect().get_center()
 await touch_input.finger(t,inside,true);await touch_input.finger(t,inside,false)
 t.check(panel.portrait_expanded,"PORTRAIT scaled left-column touch remains inside inspection")
 outside=panel.get_global_rect().end+Vector2(8,-100)
 await touch_input.finger(t,outside,true);await touch_input.finger(t,outside,false)
 t.check(not panel.portrait_expanded and ui.game.export_snapshot()==before,"PORTRAIT scaled outside touch restores without actions")
 ui.layout.scale=Vector2.ONE;ui.layout.position=Vector2.ZERO
 ui.restart(42);await t.frames()

static func applied_regions(t) -> void:
 var ui=t.ui
 ui.game=preload("res://tests/enemy_cases.gd").encounter("double_rope")
 ui._reset_interface(ui.game.get_view());ui.render();await t.frames()
 t.check(ui.expanded_body_regions.is_empty(),"AUTO REGION new battle does not expand starting equipment")
 var before=ui.game.export_snapshot()
 ui.command_router.emit(String(Queries.find(ui.view,"flow",{"kind":"end"}).payload.get("kind","")),Queries.find(ui.view,"flow",{"kind":"end"}),ui.view.version-1);await t.frames()
 t.check(ui.expanded_body_regions.is_empty() and ui.game.export_snapshot()==before,"AUTO REGION rejected action never opens a region or changes state")
 t.check(await t.click("end"),"AUTO REGION enemy application uses actual end-turn submission")
 var affected=ui.view.body_regions.filter(func(region):return not region.targets.is_empty())
 t.check(not affected.is_empty() and affected.all(func(region):return region.id in ui.expanded_body_regions),"AUTO REGION new enemy restraints open their projected regions")
 t.check(not ui.show_body and ui.find_child("EquipmentDetails",true,false)==null,"AUTO REGION does not force an inspection overlay")
 var region_id=affected.back().id
 await Pointer.press(t,ui.body_buttons[region_id])
 before=ui.game.export_snapshot()
 ui.render();await t.frames()
 t.check(region_id not in ui.expanded_body_regions and ui.game.export_snapshot()==before,"AUTO REGION manual close survives redraw without gameplay changes")
 t.check(await t.click("end") and region_id not in ui.expanded_body_regions,"AUTO REGION reinforcement of existing equipment does not reopen the region")
 # Equal-count replacement must compare IDs, not aggregate region counts.
 var old=ui.game.get_view()
 var item=ui.game.state.equipment[0]
 item.id="auto_region_replacement"
 var updated=ui.game.get_view()
 var sidebar=preload("res://ui/shell/body_sidebar.gd")
 before=ui.game.export_snapshot()
 sidebar.expand_applied(ui,old,updated);ui.render(updated);await t.frames()
 t.check(region_id in ui.expanded_body_regions and ui.game.export_snapshot()==before,"AUTO REGION equal-count replacement opens the region using read-only projection")
 ui.expanded_body_regions.clear()
 old.phase="rest"
 sidebar.expand_applied(ui,old,updated)
 t.check(ui.expanded_body_regions.is_empty(),"AUTO REGION nonbattle actions do not force expansion")
 ui.restart(42);await t.frames()

static func adaptive_regions(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 var panel=ui.find_child("BodyEquipmentPanel",true,false)
 var before=ui.game.export_snapshot()
 t.check(panel.position==Vector2(0,64) and panel.size==Vector2(375,531) and ui.body_buttons.region_head.size.x==128,"REGIONS body frame fills the left border below the header")
 var resources=ui.find_child("MainResourcePanel",true,false)
 var tools_panel=ui.find_child("ResourceToolsPanel",true,false)
 t.check(resources.position.x==panel.position.x and tools_panel.position.x==panel.position.x and resources.size.x==panel.size.x and tools_panel.size.x==panel.size.x,"REGIONS body resources and tools align across the full left column")
 t.check(resources.position.y-panel.get_rect().end.y==4 and tools_panel.position.y-resources.get_rect().end.y==4 and tools_panel.get_rect().end.y==900,"REGIONS narrow separators and tools reaching the bottom leave no outer black gutter")
 await Pointer.press(t,ui.body_buttons.region_head)
 await Pointer.press(t,ui.body_buttons.region_lower)
 t.check(ui.expanded_body_regions==["region_head","region_lower"],"REGIONS retain two expanded groups when their measured rows fit")
 t.check(ui.body_buttons.thigh.get_theme_font_size("font_size")==14,"REGIONS precise body labels use enlarged font")
 var last=panel.find_child("BodyRegionContent_region_lower",true,false)
 var exact=last.position.y+last.size.y+panel.GAP+panel.BOTTOM+panel.get_theme_stylebox("panel").get_minimum_size().y
 panel.size.y=exact;await t.frames(5)
 t.check(ui.expanded_body_regions==["region_head","region_lower"],"REGIONS exact-height boundary retains both groups")
 panel.size.y=exact-1;await t.frames(5)
 t.check(ui.expanded_body_regions==["region_lower"],"REGIONS one-pixel overflow evicts the oldest group only")
 panel.size.y=512;await t.frames(5)
 await Pointer.press(t,ui.body_buttons.region_intimate)
 await Pointer.press(t,ui.body_buttons.region_upper)
 t.check(ui.expanded_body_regions==["region_intimate","region_upper"],"REGIONS opening newest group evicts only enough older groups to fit")
 for button in ui.body_buttons.values():
  if button.is_visible_in_tree(): t.check(panel.get_global_rect().encloses(button.get_global_rect()),"REGIONS every visible button stays within its frame")
 ui.render(ui.view);await t.frames()
 t.check(ui.expanded_body_regions==["region_intimate","region_upper"] and ui.game.export_snapshot()==before,"REGIONS refresh preserves expansion order without changing gameplay")
 await Pointer.press(t,ui.body_buttons.region_upper)
 t.check(ui.expanded_body_regions==["region_intimate"],"REGIONS manual close does not collapse another group")
 await Pointer.press(t,ui.body_buttons.region_upper)
 panel.size.y=300;await t.frames(5)
 var scroll=panel.find_child("BodyRegionContent_region_upper",true,false)
 t.check(ui.expanded_body_regions==["region_upper"] and scroll.get_v_scroll_bar().max_value>scroll.size.y,"REGIONS an individually oversized newest group uses local scrolling")
 panel.size.y=512;await t.frames(5)
 ui.game.state.equipment.clear();ui.game.state.composites.clear();ui.game.state.links.clear()
 ui.game.add_fixture("upper_arm",4,10)
 ui.selected_slot="region_upper";ui.show_body=true;ui.render();await t.frames()
 var severity=ui.view.body_regions.filter(func(region):return region.id=="region_upper")[0].severity
 t.check(severity.value==ui.game.restraint_degree("arms") and severity.value==0.5,"REGIONS severity preserves authoritative fractional degree instead of rounded level")
 t.check(t.visible_text(ui.find_child("RegionSeverity",true,false)).contains("0.50 / 4"),"REGIONS current degree appears beside its visible meter")
 t.check(ui.view.body_regions.filter(func(region):return region.id in ["region_head","region_intimate"]).all(func(region):return region.severity.is_empty()),"REGIONS no invented overall degree for head or special equipment")
 await Pointer.press(t,ui.body_buttons.region_intimate)
 await Pointer.press(t,ui.body_buttons.upper_arm)
 await capture_panel(t,"ui-release-adaptive-panel.png")

static func release_preview(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.equipment.clear();ui.game._discard_end()
 ui.game.state.wall="normal"
 var target=ui.game.add_fixture("wrist",10,10)
 target.locked=true
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"strain")
 ui.game.add_fixture("ankle",4,10)
 var before=ui.game.export_snapshot()
 ui.selected_card=card.uid;ui.card_faces[card.uid]=false;ui.selected_slot="wrist";ui.show_body=true
 ui.render();await t.frames()
 var c=Queries.find(ui.view,"card",{"uid":card.uid,"target":target.id,"free":false})
 var result=c.release_preview
 t.check(c.valid and result.modifiers.any(func(text):return text.contains("锁具 ×0.5")),"RELEASE reduced damage identifies the actual lock factor")
 t.check(ui.game.export_snapshot()==before and result.before==10 and is_equal_approx(result.after,10-c.payload.preview.damage),"RELEASE projected numbers match authoritative damage without mutating resources/RNG")
 var details=ui.find_child("EquipmentDetails",true,false)
 var text=t.visible_text(details)
 t.check(text.contains(result.headline) and not text.contains("手部辅助）") and details.find_child("ReleasePreview",true,false)!=null,"RELEASE numeric before/after replaces default formula text")
 await t.capture("ui-release-numeric-preview.png")
 await capture_panel(t,"ui-release-numeric-panel.png")
 var commit=ui.find_child("PlaySelectedCard",true,false)
 t.check(details.get_global_rect().encloses(commit.get_global_rect()) and commit.get_parent()==details.get_child(0),"RELEASE confirm stays in the fixed footer outside scrolling effects")
 await Pointer.press(t,commit)
 t.check(is_equal_approx(ui.game._equipment(target.id).durability,result.after) and ui.game.state.energy==before.energy-c.cost,"RELEASE actual commit equals numeric prediction and charges exactly once")
 # Display order follows physical layers, not action eligibility: a highest-tightness
 # inner piece can still be a legitimate strain target under the original rules.
 ui.game.state.equipment.clear();ui.game._discard_end()
 var inner=ui.game.add_fixture("wrist",8,10);inner.layer=0
 var outer=ui.game.add_fixture("wrist",4,10);outer.layer=1
 before=ui.game.export_snapshot();ui.selected_card="";ui.show_body=true;ui.selected_slot="region_upper"
 ui.render();await t.frames()
 var body=ui._body_at("wrist")
 t.check(body.sections[0].equipment[0].id==outer.id and body.targets[inner.id].covers==[ui.game._equipment_name(outer)],"RELEASE same-point layer order and covering label use actual equipment facts")
 t.check(ui.game.export_snapshot()==before and ui.view.body_regions.size()==4,"RELEASE region inspection remains read-only and preserves all four entrances")
 await t.capture("ui-release-region-layers.png")
 await capture_panel(t,"ui-release-region-panel.png")

static func capture_panel(t, filename: String) -> void:
 if filename not in t.screenshots: return
 await RenderingServer.frame_post_draw
 var x=t.ui.body_buttons.region_head.get_global_rect().position.x-8
 var details=t.ui.find_child("EquipmentDetails",true,false).get_global_rect()
 var sidebar=t.ui.find_child("BodyEquipmentPanel",true,false).get_global_rect()
 var rect=Rect2i(int(x),int(sidebar.position.y),int(details.end.x-x+4),int(sidebar.size.y))
 t.check(t.root.get_texture().get_image().get_region(rect).save_png("res://build/"+filename)==OK,"RELEASE focused UI screenshot "+filename)

static func single_click_play(t) -> void:
 var ui=t.ui
 # A click on the hand card chooses the only physical restraint, even when
 # the previously inspected body slot is unrelated. Never infer a new action.
 for type in ["strain","concentration"]:
  ui.restart(42);ui.game.state.equipment.clear();ui.game._discard_end()
  ui.game.state.wall="normal"
  var target=ui.game.add_fixture("ankle",400,1000)
  var card=preload("res://tests/curse_cases.gd").give(ui.game,type)
  ui.selected_slot="wrist";ui.card_faces[card.uid]=type=="concentration"
  ui.render();await t.frames()
  var before=ui.game.export_snapshot()
  var c=Queries.find(ui.view,"card",{"uid":card.uid,"target":target.id,"free":ui.card_faces[card.uid]})
  await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
  t.check(c.valid and ui.game.state.version==before.version+1 and ui.game.state.energy==before.energy-c.cost,"SINGLE CLICK native hand click pays once using the current face: "+type)
  t.check(not ui.card_buttons.has(card.uid) and is_equal_approx(ui.game._equipment(target.id).durability,400-c.payload.preview.damage),"SINGLE CLICK removes the played card and applies exactly the formal preview: "+type)
  t.check(ui.selected_card=="" and ui.find_child("EquipmentDetails",true,false)==null and ui.find_child("PlaySelectedCard",true,false)==null,"SINGLE CLICK has no second target or play confirmation: "+type)
 ui.restart(42);ui.game.state.equipment.clear();ui.game._discard_end()
 var target=ui.game.add_fixture("ankle",400,1000)
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"strain")
 ui.game.state.energy=0;ui.selected_slot="eyes";ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 var blocked=Queries.find(ui.view,"card",{"uid":card.uid,"target":target.id,"free":false})
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
 t.check(ui.game.state==before and ui.card_buttons.has(card.uid),"SINGLE CLICK insufficient energy preserves card, resources and random state")
 t.check(not blocked.valid and t.visible_text(ui.find_child("EquipmentDetails",true,false)).contains(blocked.reason),"SINGLE CLICK blocked unique target shows its actual reason at the correct body slot")
 await t.close_information()
 ui.game.state.energy=3;ui.game.add_fixture("wrist",4,10);ui.render();await t.frames()
 before=ui.game.export_snapshot()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
 t.check(ui.game.state==before and ui.selected_card==card.uid,"SINGLE CLICK multiple physical restraints continue to require target selection")
 await t.close_information()
 ui.game.state.equipment=ui.game.state.equipment.filter(func(e):return e.id==target.id)
 ui.render();await t.frames()
 ui.game.state.version+=1
 before=ui.game.export_snapshot()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
 t.check(ui.game.state==before and ui.card_buttons.has(card.uid) and ui.notice.contains("状态已更新"),"SINGLE CLICK stale view cannot spend a card through automatic targeting")
 await t.start_practice("Practice_guard")
 ui.game.state.equipment.clear();ui.game.state.links.clear();ui.game.state.composites.clear()
 ui.game._discard_end();ui.game.add_fixture("wrist",4,10)
 ui.game.CaptureBind.apply_bind(ui.game,ui.game.state.enemies[0])
 card=preload("res://tests/curse_cases.gd").give(ui.game,"strain")
 ui.render();await t.frames();before=ui.game.export_snapshot()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
 t.check(not ui.view.guard_bind.is_empty() and ui.game.state==before and ui.selected_card==card.uid,"SINGLE CLICK capture bar plus one restraint preserves explicit choice")

static func selection_focus(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.equipment.clear();ui.game._discard_end()
 ui.game.state.wall="normal";ui.game.state.wall_distance=0
 var ankle=ui.game.add_fixture("ankle",4,10)
 ui.game.add_fixture("wrist",4,10)
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"crossed_legs")
 ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.selected_card==card.uid and ui.game.export_snapshot()==before,"FOCUS native card selection does not execute an action")
 t.check(ui.body_buttons.ankle.get_meta("target_selectable",false) and not ui.body_buttons.wrist.get_meta("target_selectable",true),"FOCUS leg-only card highlights a usable leg and dims occupied but ineligible wrists")
 t.check(ui.body_buttons.ankle.modulate.r>ui.body_buttons.wrist.modulate.r,"FOCUS valid and invalid body targets differ visibly")
 await Pointer.press(t,ui.body_buttons.ankle)
 var candidate=Queries.find(ui.view,"card",{"uid":card.uid,"target":ankle.id,"free":false})
 t.check(candidate.valid and ui.selected_candidate==String(candidate.get("key","")) and ui.find_child("PlaySelectedCard",true,false)!=null and ui.find_child("CardTarget_"+ankle.id,true,false)==null,"FOCUS single restraint skips selection and exposes the formal play action")
 t.check(ui.game.export_snapshot()==before,"FOCUS opening single target preserves resources, card and random state")
 await t.capture("ui-card-target-focus.png")
 var hand_id=ui.card_buttons[card.uid].get_instance_id()
 await t.flip(card.uid)
 for body in ui.view.body_groups:
  var available=preload("res://ui/drag_targets.gd").choices(ui,{"card_uid":card.uid,"free":true,"version":ui.view.version})
  var usable=available.any(func(c):return c.payload.get("slot","") in body.slots or body.targets.has(c.payload.get("target","")))
  t.check(ui.body_buttons[body.id].get_meta("target_selectable")==usable,"FOCUS face flip refreshes formal availability: "+body.id)
 t.check(ui.card_buttons[card.uid].get_instance_id()==hand_id and ui.game.export_snapshot()==before,"FOCUS face flip retains the hand control and gameplay state")
 await t.flip(card.uid)
 ui.game.state.energy=0;ui.render();await t.frames()
 t.check(not ui.body_buttons.ankle.get_meta("target_selectable",true) and ui.find_child("PlaySelectedCard",true,false)==null,"FOCUS insufficient energy dims the otherwise valid target and prevents play")
 candidate=Queries.find(ui.view,"card",{"uid":card.uid,"target":ankle.id,"free":false})
 t.check(t.visible_text(ui.find_child("EquipmentDetails",true,false)).contains(candidate.reason),"FOCUS auto-selected blocked equipment keeps its exact unavailable reason")
 await Pointer.press(t,ui.find_child("CloseEquipmentDetails",true,false))
 t.check(not ui.body_buttons.ankle.has_meta("target_selectable") and ui.body_buttons.ankle.modulate==Color.WHITE,"FOCUS cancel restores ordinary body appearance")
 ui.game.state.energy=3
 ui.game.add_fixture("ankle",4,10)
 ui.render();await t.frames()
 before=ui.game.export_snapshot()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.selected_candidate=="" and ui.find_child("PlaySelectedCard",true,false)==null,"FOCUS multiple physical restraints retain target selection")
 var buttons=ui.find_child("EquipmentDetails",true,false).find_children("CardTarget_*","Button",true,false)
 t.check(buttons.size()==2,"FOCUS multiple restraints each have a selectable or dimmed entry")
 for button in buttons:
  t.check(button.get_meta("target_selectable")==not button.disabled,"FOCUS item brightness follows the actual candidate")
 var valid=ui._body_card_actions("ankle",card.uid).filter(func(c):return c.payload.free==false and c.valid)[0]
 await Pointer.press(t,ui.find_child("CardTarget_"+valid.payload.target,true,false))
 t.check(ui.selected_candidate==preload("res://ui/target_queries.gd").fact_key(valid) and ui.game.export_snapshot()==before,"FOCUS selecting one of several targets spends nothing")
 await Pointer.press(t,ui.find_child("PlaySelectedCard",true,false))
 t.check(ui.view.energy==before.energy-valid.cost and not ui.card_buttons.has(card.uid),"FOCUS play submits exactly the selected formal candidate once")

static func shared_hand_target(t) -> void:
 var ui=t.ui
 ui.game=preload("res://tests/game_fixture.gd").new(42)
 var tape=ui.game._install_template("tape","fingers",12.8,16,false,"fixture",2)
 var root=ui.game._install_assembly("glove","long","fixture",2,2)
 var body=ui.game._composite_body(root)
 var wrist=ui.game._install_template("belt","wrist",4,10,false,"fixture")
 ui.render();await t.frames()
 var uid=ui.view.hand.filter(func(c):return c.type=="slip")[0].uid
 if ui.card_faces.get(uid,false): await t.flip(uid)
 var before=ui.game.export_snapshot()
 var choices=ui._body_card_actions("hands",uid)
 var shell=choices.filter(func(c):return c.payload.target==body.id)[0]
 var inner=choices.filter(func(c):return c.payload.target==tape.id)[0]
 var queries=preload("res://ui/target_queries.gd")
 var shell_id=queries.fact_key(shell);var inner_id=queries.fact_key(inner)
 await t.start_drag(uid,"hands")
 t.check(choices.size()==2 and ui.drop_targets.size()==2 and ui.drop_targets.has(shell_id) and ui.drop_targets.has(inner_id),"BODY aimed hand shows its two physical pieces including blocked entries, without other regions")
 if not ui.drop_targets.has(inner_id):
  await t.mouse_button(Vector2(1500,70),MOUSE_BUTTON_LEFT,false)
  return
 t.check(ui.drop_targets.values().all(func(button):return not button.get_meta("target_selectable") and button.get_parent().modulate.r<0.5),"BODY blocked hand pieces are visible at low brightness")
 await t.release_target(await t.reveal_drop_target(inner_id))
 t.check(ui.game.export_snapshot()==before and ui.drop_targets.is_empty(),"BODY releasing over dimmed equipment rejects the action without payment or state changes")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,uid)
 await t.inspect_body("hands")
 var details=ui.find_child("EquipmentDetails",true,false)
 t.check(shell.reason.contains("肩带") and not shell.reason.contains("最外层") and t.visible_text(details).contains(shell.reason),"BODY glove entry names the shoulder restriction instead of labeling every hand target inner")
 t.check(inner.reason.contains(body.name) and inner.reason.contains("覆盖") and t.visible_text(details).contains(inner.reason),"BODY inner tape entry identifies the glove covering it")
 var blocked=ui.find_child("CardTarget_"+tape.id,true,false)
 t.check(blocked.disabled and not blocked.get_meta("target_selectable",true),"BODY blocked inner equipment remains visible and dimmed")
 await Pointer.press(t,blocked)
 t.check(ui.game.export_snapshot()==before,"BODY rejected inner-tape click does not spend energy, consume card or change RNG")
 await Pointer.press(t,ui.find_child("CloseEquipmentDetails",true,false))
 # Clear actual blockers through the existing damage/cleanup path, then use
 # the same deduplicated candidate in a real card drop.
 ui.game._apply_equipment_damage(root.components.filter(func(e):return e.part=="left")[0],100,"cut")
 ui.game._apply_equipment_damage(wrist,100,"cut");ui.game._cleanup()
 ui.render();await t.frames()
 choices=ui._body_card_actions("hands",uid)
 shell=choices.filter(func(c):return c.payload.target==body.id)[0]
 var inner_again=choices.filter(func(c):return c.payload.target==tape.id)[0]
 shell_id=queries.fact_key(shell);inner_id=queries.fact_key(inner_again)
 t.check(shell.valid and not inner_again.valid,"BODY removing shoulder and wrist cover enables only the outer glove")
 var durability=body.durability;var damage=shell.payload.preview.damage;var energy=ui.view.energy
 await t.start_drag(uid,"hands")
 t.check(ui.drop_targets[shell_id].get_meta("target_selectable") and ui.drop_targets[shell_id].get_parent().modulate==Color.WHITE and not ui.drop_targets[inner_id].get_meta("target_selectable") and ui.drop_targets[inner_id].get_parent().modulate.r<0.5,"BODY same region distinguishes selectable outer piece from dimmed blocked inner piece")
 await t.capture("ui-body-target-brightness.png")
 await t.release_target(await t.reveal_drop_target(shell_id))
 t.check(is_equal_approx(ui.game._equipment(body.id).get("durability",0),maxf(0,durability-damage)) and ui.view.energy==energy-shell.cost,"BODY deduplicated glove target still commits the original candidate once")
