extends RefCounted
const Spatial=preload("res://tests/exploration_fixture.gd")
const Space=preload("res://core/prison_space.gd")

static func run(t) -> void:
 await distance_and_installed(t)
 var ui=t.ui
 await t.start_practice("Practice_prison_test")
 var panel=ui.find_child("PrisonExploration",true,false)
 t.check(panel!=null and t.visible_text(panel).contains("前往") and not t.visible_text(panel).contains("摸索"),"EXP UI sighted has destination choices only")
 t.check(t.visible_text(panel).contains("方") and t.visible_text(panel).contains("离墙") and t.visible_text(panel).contains("格"),"EXP UI real bearings and distances on destinations")
 t.check(ui.find_child("PrisonRemaining",true,false).size.y<30,"EXP UI count stays on one compact line")
 var original=ui.game.export_snapshot();var dest=ui.view.prison.space.sites.filter(func(site):return not site.here and site.label!="？？？")[0]
 var candidate=ui.view.display_facts.filter(func(c):return c.payload.kind=="prison" and c.payload.get("site","")==dest.id)[0]
 # Reveal the actual destination control, then click it through pointer input.
 var button=ui.candidate_buttons[candidate.key]
 var scroll=panel.get_parent() as ScrollContainer
 if scroll!=null: scroll.ensure_control_visible(button)
 await t.frames()
 var point=button.get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false);await t.frames()
 t.check(ui.game.state.prison.space.position!=original.prison.space.position and ui.game.state.energy==original.energy-candidate.cost,"EXP UI native destination click commits real movement")
 t.check(ui.view.prison.left==16 and ui.view.prison.space.sites.filter(func(site):return site.id==dest.id)[0].distance<dest.distance,"EXP UI remaining shortest route updates without advancing patrol")
 await t.capture("ui-114-prison-destinations.png")

 await t.start_practice("Practice_prison_blind")
 panel=ui.find_child("PrisonExploration",true,false)
 t.check(t.visible_text(panel).contains("摸索") and t.visible_text(panel).contains("？？？"),"EXP UI blind has hidden locations and directional movement")
 t.check(not t.visible_text(panel).contains("牢门") and not t.visible_text(panel).contains("离墙") and not t.visible_text(panel).contains("右前方"),"EXP UI blind location list hides names and distances")
 Spatial.position(ui.game,[2,3]);Spatial.site(ui.game,"shard").position=[3,3]
 ui.game.state.energy=3;ui.render();await t.frames()
 var near=ui.find_child("PrisonSite_place_2",true,false)
 t.check(near!=null and t.visible_text(near).contains("？？？") and t.visible_text(near).contains("两格以内"),"EXP UI blind proximity highlights without disclosing direction")
 t.check(await t.click("prison",{"action":"explore","direction":"east","steps":1}),"EXP UI blind directional button moves")
 panel=ui.find_child("PrisonExploration",true,false)
 t.check(ui.game.state.prison.space.position==[3,3] and t.visible_text(panel).contains("尖锐的小石片 · 当前") and ui.view.prison.found.has("shard"),"EXP UI stepping on tile reveals actual object")
 await t.capture("ui-115-prison-blind.png")
 await open_details(t,"place_2")
 var tool_text=t.visible_text(ui.find_child("PrisonLocationDetails",true,false))
 t.check(not tool_text.contains("牢门") and not tool_text.contains("通风口") and tool_text.contains("能量"),"EXP UI discovered tool opens only its own actual actions")
 ui.find_child("PrisonDetailsBack",true,false).pressed.emit();await t.frames()
 var eyes=ui.game.equipment_at("eyes")[0];eyes.durability=0;ui.game._cleanup();ui.render();await t.frames()
 t.check(t.visible_text(ui.find_child("PrisonExploration",true,false)).contains("前往") and not ui.view.prison.space.blind,"EXP UI removing blindfold immediately restores destinations")

 # Remote-use presentation requires an available key route, not a random unlock draw.
 ui.game.state.prison.key=true;ui.render();await t.frames()
 await open_details(t,"place_1")
 t.check(ui.actor_targets.has("prison_door") and ui.find_child("PrisonLocationDetails",true,false)!=null and ui.find_child("PrisonExploration",true,false)==null,"EXP UI door only appears in its secondary page")
 var text=t.visible_text(ui.find_child("PrisonLocationDetails",true,false))
 t.check(text.contains("需要先到牢门前") and not text.contains("通风口"),"EXP UI secondary actions retain exact remote-use reason without other facility clutter")
 await t.capture("ui-117-prison-door-details.png")
 ui.find_child("PrisonDetailsBack",true,false).pressed.emit();await t.frames()
 t.check(not ui.actor_targets.has("prison_door") and not t.visible_text(ui.find_child("PrisonControls",true,false)).contains("踢击通风口"),"EXP UI return clears secondary targets")

static func open_details(t,id: String) -> void:
 var button=t.ui.find_child("InspectPrison_"+id,true,false)
 t.check(button!=null,"EXP UI visible place has secondary entry "+id)
 if button==null:return
 var before=t.ui.game.export_snapshot()
 var ancestor=button.get_parent()
 while ancestor!=null and not ancestor is ScrollContainer: ancestor=ancestor.get_parent()
 if ancestor is ScrollContainer: ancestor.ensure_control_visible(button)
 await t.frames()
 var point=button.get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false);await t.frames()
 t.check(t.ui.game.export_snapshot()==before,"EXP UI inspecting place spends no resources or turn")
 t.check(t.ui.prison_detail==id and t.ui.find_child("PrisonLocationDetails",true,false)!=null,"EXP UI native inspect opens the selected secondary page")

static func distance_and_installed(t) -> void:
 await t.start_practice("Practice_prison_test")
 var ui=t.ui
 Spatial.position(ui.game,[0,3]);ui.game._gain_tool("shard");ui.game.state.energy=3
 var item=ui.game.state.items[0]
 ui.show_items=true;ui.selected_item=item.id;ui.render();await t.frames()
 t.check(await t.click("item_install",{"item":item.id,"mount":"foot_wall"}),"EXP UI tool installs through the existing item action")
 await t.close_information()
 var tile=ui.find_child("PrisonSite_tool_"+item.id,true,false)
 t.check(tile!=null and t.visible_text(tile).contains(preload("res://data/field_tools.gd").mount_label("foot_wall")) and t.visible_text(tile).contains("剩余3次"),"EXP UI installation immediately creates a named destination with mount and charges")
 Spatial.position(ui.game,[6,6]);ui.render();await t.frames()
 var meter=ui.find_child("PrisonDistance_tool_"+item.id,true,false)
 t.check(meter!=null and meter.get_node("Overflow").value>meter.get_node("Normal").value,"EXP UI exposes red overflow beyond original distance")
 t.check(meter.get_node("Overflow").get_theme_stylebox("fill").bg_color==ui.RED and meter.get_node("Normal").value==3,"EXP UI overflow is red and normal portion retains the baseline")
 t.check(meter.size.y<=26,"EXP UI distance meter stays compact")
 await t.capture("ui-119-prison-distance-tool.png")
 Spatial.position(ui.game,[0,3]);ui.render();await t.frames()
 # A site on the interior produces a departure warning before any action is taken.
 Spatial.site(ui.game,"shard").position=[2,3];ui.render();await t.frames()
 tile=ui.find_child("PrisonSite_place_2",true,false)
 t.check(t.visible_text(tile).contains("本次移动后将离墙"),"EXP UI departure warning appears beside the destination before moving")
 await open_details(t,"tool_"+item.id)
 t.check(await t.click("item_retrieve",{"item":item.id}),"EXP UI retrieval uses actual secondary action")
 t.check(ui.find_child("PrisonSite_tool_"+item.id,true,false)==null and ui.prison_detail=="","EXP UI retrieval removes mounted card and returns to locations")
 await t.start_practice("Practice_prison_blind")
 Spatial.position(ui.game,[0,3]);ui.render();await t.frames()
 t.check(ui.find_children("PrisonDistance_*","",true,false).is_empty(),"EXP UI blind mode never displays numeric distance bars")
 t.check(t.visible_text(ui.find_child("PrisonExploration",true,false)).contains("本次移动后将离墙"),"EXP UI blind directional choices give departure warning")
 await t.capture("ui-120-prison-blind-wall-warning.png")
