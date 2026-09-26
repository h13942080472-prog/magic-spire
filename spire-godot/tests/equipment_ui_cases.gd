extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

static func target(t, slot: String, part: String) -> Dictionary:
 var body=t.ui.view.bodies.filter(func(b):return b.id==slot)[0]
 return body.targets.values().filter(func(e):return e.part==part)[0]

static func tools_panel(t) -> String:
 var ui=t.ui
 ui.show_hook=false; ui.show_items=true; ui.selected_item=ui.view.items[0].id
 ui.render(); await t.frames()
 return ui.selected_item

static func run(t) -> void:
 var ui=t.ui
 var images=preload("res://data/equipment_images.gd")
 for family in images.MATERIALS:
  for file in images.MATERIALS[family]:
   var texture=load("res://assets/ui/equipment/"+file+".png") as Texture2D
   var pixels=texture.get_image()
   t.check(pixels.detect_alpha()!=Image.ALPHA_NONE and pixels.get_pixel(0,0).a==0 and pixels.get_used_rect().has_area(),"Equipment material icon has a transparent backing and visible art: "+file)
 ui.restart(42)
 var inner=ui.game._install_assembly("leg","upper","fixture",2,3)
 var outer=ui.game._install_assembly("leg","toes","fixture",2,3)
 t.check(not inner.is_empty() and not outer.is_empty(),"RELEASE layered leg sleeves install through normal factories")
 var inner_band=inner.components.filter(func(e):return e.part=="above_knee")[0]
 var outer_band=outer.components.filter(func(e):return e.part=="above_knee")[0]
 ui.render();await t.frames();await t.inspect_body("thigh")
 t.check(ui.find_child("QuickRelease_"+outer_band.id,true,false)!=null and ui.find_child("BodySlot_thigh",true,false).get_meta("can_release"),"RELEASE outer unlocked leg band exposes quick release and thigh highlight")
 var inner_card=ui.find_child("EquipmentCard_"+inner_band.id,true,false)
 inner_card.find_child("EquipmentCardDetailsToggle",true,false).pressed.emit();await t.frames()
 t.check(t.visible_text(inner_card).contains("外层仍覆盖"),"RELEASE covered inner leg band explains actual outer-layer blocker")
 ui.game.state.energy=0;ui.render();await t.frames()
 var outer_card=ui.find_child("EquipmentCard_"+outer_band.id,true,false)
 outer_card.find_child("EquipmentCardDetailsToggle",true,false).pressed.emit();await t.frames()
 t.check(ui.find_child("QuickRelease_"+outer_band.id,true,false)==null and t.visible_text(outer_card).contains("需要1能量"),"RELEASE energy shortage is shown beside the disabled outer-band action")
 ui.restart(42);ui.game.state.equipment.clear()
 var removable=ui.game.add_fixture("mouth",4,10,false,0,"mouth_band")
 ui.render();await t.frames()
 t.check(ui.find_child("BodySlot_mouth",true,false).get_meta("can_release"),"RELEASE free hands highlight removable mouth equipment")
 await t.inspect_body("mouth")
 var release=ui.find_child("QuickRelease_"+removable.id,true,false)
 t.check(release!=null and release.is_visible_in_tree(),"RELEASE one-click action visible without opening further details")
 await t.capture("ui-quick-release.png")
 removable.locked=true;ui.render();await t.frames()
 t.check(not ui.find_child("BodySlot_mouth",true,false).get_meta("can_release") and ui.find_child("QuickRelease_"+removable.id,true,false)==null,"RELEASE locked target has no highlight or quick button")
 t.check(ui.find_child("EquipmentCard_"+removable.id,true,false).find_child("EquipmentActions",true,false).is_visible_in_tree(),"RELEASE single equipment automatically opens its actions")
 t.check(t.visible_text(ui.layout).contains("目标已上锁"),"RELEASE details show actual locked reason instead of hiding the action")
 removable.locked=false;ui.game.state.energy=0;ui.render();await t.frames()
 t.check(not ui.find_child("BodySlot_mouth",true,false).get_meta("can_release"),"RELEASE unavailable energy prevents actionable highlight")
 ui.game.state.energy=3;ui.render();await t.frames()
 var old_energy=ui.game.state.energy
 var old_details=ui.find_child("EquipmentCard_"+removable.id,true,false)
 t.check(await t.click("manual",{"target":removable.id}) and ui.game._equipment(removable.id).is_empty() and ui.game.state.energy==old_energy-1,"RELEASE actual button removes target and pays formal cost")
 await t.frames()
 t.check(not is_instance_valid(old_details) and ui.find_child("EquipmentCard_"+removable.id,true,false)==null,"RELEASE removed restraint releases its old detail nodes")
 t.check(ui.game._equipment_read.is_empty() and ui.candidate_buttons.values().all(func(button):return is_instance_valid(button) and button.is_inside_tree()),"RELEASE no read index or detached action control survives the new state")
 t.check(not ui.find_child("BodySlot_mouth",true,false).get_meta("can_release"),"RELEASE highlight disappears after removal")
 await t.start_practice("Practice_lock_solo")
 var lock_target=ui.game.state.equipment[0]
 await t.inspect_body(lock_target.slot)
 var lock_icon=ui.find_child("EquipmentLock_"+lock_target.id,true,false)
 t.check(lock_icon!=null and not lock_icon.locked,"LOCK ICON unlocked equipment displays open copper lock")
 lock_target.locked=true;ui.render();await t.frames()
 await t.inspect_body(lock_target.slot)
 lock_icon=ui.find_child("EquipmentLock_"+lock_target.id,true,false)
 t.check(lock_icon!=null and lock_icon.locked,"LOCK ICON locked equipment displays closed copper lock")
 await t.capture("ui-equipment-copper-lock.png")
 await t.start_practice("Practice_component_links")
 t.check(ui.view.practice_kind=="component_links","CATALOG scrolled native menu opens exact selected scenario")
 var body=target(t,"thigh","body")
 var band=target(t,"thigh","above_knee")
 var rope=ui.game.state.links[0].duplicate(true)
 await t.inspect_body(rope.slot)
 var blocked_icon=ui.find_child("EquipmentLock_"+rope.id,true,false)
 t.check(blocked_icon!=null and not blocked_icon.lockable,"LOCK ICON non-lockable rope displays crossed copper lock")
 var scroll_parent=blocked_icon.get_parent()
 while scroll_parent!=null and not scroll_parent is ScrollContainer: scroll_parent=scroll_parent.get_parent()
 if scroll_parent!=null: scroll_parent.ensure_control_visible(blocked_icon)
 await t.frames()
 await t.capture("ui-equipment-lock-cross.png")
 var item=await tools_panel(t)
 for i in range(3): t.check(await t.click("item_use",{"item":item,"target":body.id}),"LEG cut actual body from tool drawer")
 t.check(ui.game._equipment(body.id).is_empty() and not ui.game._equipment(band.id).is_empty() and JSON.stringify(ui.game.state.links[0])==JSON.stringify(rope),"LEG displayed independent bands keep their actual link after three real cuts")
 ui.show_items=false; ui.render(); await t.frames(); await t.inspect_body("thigh")
 t.check(t.visible_text(ui.layout).contains("遗留外带"),"LEG remaining bands are described in visible equipment group")
 await t.capture("ui-27-leg-bands-retained.png")
 var uid=ui.view.hand.filter(func(c):return c.type=="strain")[0].uid
 var c=Queries.find(ui.view,"card",{"uid":uid,"slot":"thigh","target":band.id})
 var expected=c.payload.preview.damage
 var before=ui.game._equipment(band.id).durability
 await t.start_drag(uid,"thigh")
 var drop_index=await t.reveal_drop_target(c.key)
 await t.capture("ui-118-equipment-drag-card.png")
 t.check(ui.drop_targets[c.key].size.y<=90 and ui.drop_panel.size.y<=290 and ui.drop_panel.position.x>ui.body_buttons.thigh.get_global_rect().end.x,"Equipment targets remain compact beside their body button")
 var preview_text=t.visible_text(ui.term_popup)
 t.check(preview_text.contains(ui.game.number(expected)+"点挣扎伤害") and not preview_text.contains("能量") and not preview_text.contains("耐久") and ui.drop_targets[c.key].get_parent().find_child("EquipmentTargetImage",true,false)!=null,"Equipment hover shows current typed damage without repeating costs or equipment details")
 await t.release_target(drop_index)
 t.check(is_equal_approx(ui.game._equipment(band.id).durability,before-expected) and ui.view.energy==2,"LEG native drag targets surviving independent band exactly once")

 await t.start_practice("Practice_wrap_left")
 t.check(ui.view.practice_kind=="wrap_left" and ui.view.arms==1 and ui.view.capacity==3,"WRAP one restrained hand counts toward the arm region while retaining one free hand")
 body=target(t,"palm","body")
 item=await tools_panel(t)
 t.check(await t.click("item_use",{"item":item,"target":body.id}) and ui.game.state.composites.is_empty(),"WRAP opposite free hand cuts both covered regions through one actual target")

 await t.start_practice("Practice_jacket")
 t.check(ui.view.practice_kind=="jacket" and ui.view.arms==4,"JACKET real menu starts full arm restriction")
 var sleeves=target(t,"wrist","sleeves")
 body=target(t,"wrist","body")
 ui.find_child("OpenRestHook",true,false).pressed.emit(); await t.frames()
 c=Queries.find(ui.view,"hook",{"target":sleeves.id})
 t.check(not c.valid and ui.candidate_buttons[c.key].disabled and c.reason!="","JACKET structural no-slip target has disabled hook with reason")
 t.check(not Queries.find(ui.view,"hook",{"target":body.id}).valid,"JACKET body hook requires removal of its real attached components")
 await t.capture("ui-28-jacket-structure.png")
 item=await tools_panel(t)
 t.check(await t.click("item_install",{"item":item,"mount":"foot_wall"}),"JACKET free toes can install tool despite closed hands")
 ui.show_items=false; ui.render(); await t.frames()
 t.check(await t.click("posture",{"dest":"sit","wall":false}),"JACKET changes posture with formal cost")
 t.check(await t.click("posture",{"dest":"lie","wall":false}),"JACKET lying posture reaches installed tool")
 ui.show_items=true; ui.selected_item=item; ui.render(); await t.frames()
 t.check(await t.trigger_installed_tool(sleeves.id,item),"JACKET actual wall cutting damages connection while body stays intact")

 await t.start_practice("Practice_head_harness")
 t.check(ui.view.practice_kind=="head_harness","HEAD menu selects harness scenario")
 t.check(await t.click("posture",{"dest":"sit","wall":false}),"HEAD sitting reaches fixed mid-height hook")
 var eyes=ui.game.equipment_at("eyes")
 var cloth=eyes.filter(func(e):return e.template=="eye_cloth")[0]
 var tape=eyes.filter(func(e):return e.template=="eye_tape")[0]
 ui.find_child("OpenRestHook",true,false).pressed.emit(); await t.frames()
 c=Queries.find(ui.view,"hook",{"target":cloth.id})
 t.check(not c.valid and c.reason.contains("更紧") and ui.candidate_buttons[c.key].disabled,"HEAD stricter harness blocks this specific mask visibly")
 t.check(await t.click("hook",{"target":tape.id}) and is_equal_approx(ui.game._equipment(tape.id).durability,4.0),"HEAD equal tightness allows hook and preserves the other mask")
 t.check(ui.game.equipment_at("eyes").size()==2 and ui.game.state.composites.is_empty() and ui.game.Equipment.has_mouth_harness(ui.game.equipment_at("mouth")[0]),"HEAD processing one mask keeps the integrated mouth harness")
 ui.show_hook=false; ui.render(); await t.frames(); await t.inspect_body("eyes")
 await t.capture("ui-29-head-comparison.png")

 await t.start_practice("Practice_advanced")
 t.check(ui.view.practice_kind=="advanced" and ui.game.state.equipment.all(func(e):return e.grade==3),"GRADE bottom menu opens real high-grade equipment")
 await t.inspect_body(ui.selected_slot)
 t.check(t.visible_text(ui.layout).contains("魔导纤维绳"),"GRADE material name is shown in equipment information")
 await t.capture("ui-30-advanced-catalog.png")
