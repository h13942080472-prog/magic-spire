extends RefCounted
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")
const Game=preload("res://tests/game_fixture.gd")
const Queries=preload("res://ui/target_queries.gd")

static func expand_description(t, card: Control) -> void:
 if not card.find_child("EquipmentActions",true,false).visible:
  await Pointer.press(t,card.find_child("EquipmentCardDetailsToggle",true,false))
 var toggle=card.find_child("EquipmentDescriptionToggle",true,false)
 var scroller=toggle.get_parent()
 while scroller!=null and not scroller is ScrollContainer: scroller=scroller.get_parent()
 if scroller!=null: scroller.ensure_control_visible(toggle)
 await t.frames();await Pointer.press(t,toggle)

static func run(t) -> void:
 var ui=t.ui
 await t.start_practice("Practice_special_equipment")
 t.check(ui.view.pressure.value==8 and ui.body_buttons.hands==ui.body_buttons.palm and ui.body_buttons.hands==ui.body_buttons.fingers and ui.body_buttons.feet==ui.body_buttons.toes,"SPECIAL UI merged controls preserve physical aliases")
 for id in ["MainOverload","MainMana","HeroOverload","HeroMana"]:
  var bar=ui.find_child(id,true,false)
  t.check(bar!=null and bar.is_visible_in_tree() and bar.value==(8.0 if "Overload" in id else 100.0),"SPECIAL UI real resource meter "+id)
 t.check(ui.find_child("HeroOverloadValue",true,false).text=="8/100" and ui.find_child("HeroManaValue",true,false).text=="100/100","SPECIAL UI compact meters show values without captions")
 t.check(ui.find_child("HeroOverload",true,false).position.y>=ui.find_child("HeroArt",true,false).get_rect().end.y,"SPECIAL UI compact meters sit below hero feet")
 t.check(ui.find_child("MainMana",true,false).get_rect().end.y<697,"SPECIAL UI large meters leave space for installed tools")
 var before=ui.game.export_snapshot()
 await t.inspect_body("special_2")
 var details=ui.find_child("EquipmentDetails",true,false)
 t.check(not t.visible_text(details).contains("6－紧度2－等级2＝2"),"SPECIAL UI formulas are collapsed by default")
 for panel in details.find_children("EquipmentCard_*","PanelContainer",true,false): await expand_description(t,panel)
 t.check(t.visible_text(details).contains("马眼") and t.visible_text(details).contains("8毫米×20厘米硅胶马眼棒") and t.visible_text(details).contains("耐久"),"SPECIAL UI named penis subslots show actual equipment durability")
 t.check(t.visible_text(details).contains("高潮时滑脱伤害") and t.visible_text(details).contains("6－紧度2－等级2＝2") and t.visible_text(details).contains("凸粒隔着肉棒正面清楚鼓起"),"SPECIAL UI urethral rod detail shows current formula and physical stimulation")
 t.check(not t.visible_text(details).contains("专用位置") and not t.visible_text(details).contains("/7"),"SPECIAL UI shares ordinary equipment detail layout without special capacity banner")
 t.check(ui.game.export_snapshot()==before,"SPECIAL UI inspecting sex toys is zero cost")
 await t.capture("ui-104-special-slots-and-meters.png")
 await t.close_information()
 t.check(await t.click("end") and await t.click("end"),"SPECIAL UI advances timed effects through normal end turn")
 await t.inspect_body("special_1")
 t.check(t.visible_text(ui.find_child("EquipmentDetails",true,false)).contains("电量剩余6回合"),"SPECIAL UI displays the real remaining battery after two player turns")
 await t.close_information()
 # Merged hand list keeps concrete equipment targets from both locations.
 ui.game=Game.new(42)
 var palm=ui.game.add_fixture("palm",4)
 var fingers=ui.game.add_fixture("fingers",4)
 ui.render();await t.frames()
 await t.inspect_body("hands")
 details=ui.find_child("EquipmentDetails",true,false)
 t.check(t.visible_text(details).contains("手掌") and t.visible_text(details).contains("手指"),"SPECIAL UI merged detail retains precise positions")
 var uid=ui.view.hand.filter(func(c):return c.type=="strain")[0].uid
 var c=Queries.find(ui.view,"card",{"uid":uid,"slot":"fingers","target":fingers.id,"free":false})
 var old=ui.game._equipment(fingers.id).durability
 if ui.card_faces.get(uid,false): await t.flip(uid)
 await t.start_drag(uid,"hands")
 t.check(ui.drop_targets.has(c.key),"SPECIAL UI merged hand drag exposes physical finger target")
 await t.release_target(await t.reveal_drop_target(c.key))
 t.check(ui.game._equipment(fingers.id).get("durability",0)<old and ui.game._equipment(palm.id).durability==4,"SPECIAL UI drag damages only selected physical part")
 # Full-width resource bars remain readable after a viewport resize.
 ui.get_window().size=Vector2i(1280,720);await t.frames();ui.render();await t.frames()
 for id in ["MainOverload","MainMana","HeroOverload","HeroMana"]:
  t.check(Rect2(Vector2.ZERO,ui.get_viewport_rect().size).encloses(ui.find_child(id,true,false).get_global_rect()),"SPECIAL UI resized meter remains in viewport "+id)
 ui.get_window().size=Vector2i(1600,900);await t.frames()
 var close=ui.find_child("CloseEquipmentDetails",true,false)
 if close!=null: await Pointer.press(t,close)
 await t.capture("ui-105-compact-resource-meters.png")
 # The same drag interface handles each special root, including stacked neighbours.
 ui.game=Game.new(42)
 var first=ui.game._install_special("shaft_ring_low","special_2_a")
 var second=ui.game._install_special("full_cup_medium","special_2_a")
 ui.render();await t.frames()
 await t.inspect_body("special_2")
 details=ui.find_child("EquipmentDetails",true,false)
 t.check(t.visible_text(details).contains("柱身") and t.visible_text(details).contains("自由：马眼") and not t.visible_text(details).contains("/2容量") and not t.visible_text(details).contains("/1容量"),"SPECIAL UI uses ordinary position and free-position display without capacity counters")
 t.check(ui.body_buttons.special_2.text==ui.view.body_groups.filter(func(b):return b.id=="special_2")[0].name+"  2" and not ui.body_buttons.special_1.text.contains("/"),"SPECIAL UI shows actual equipment count and plain empty region name")
 t.check(ui.game.SpecialEquipment.used_capacity(ui.game.state.special_equipment,"special_2_a")==2 and ui.game._install_special("urethral_full_cup_high","special_2_a").is_empty(),"SPECIAL UI simplification preserves formal capacity restrictions")
 await t.close_information()
 uid=ui.view.hand.filter(func(h):return h.type=="strain")[0].uid
 c=Queries.find(ui.view,"card",{"uid":uid,"target":second.id,"free":false})
 if ui.card_faces.get(uid,false): await t.flip(uid)
 await t.start_drag(uid,"special_2")
 t.check(ui.drop_targets.has(c.key),"SPECIAL UI special body drag exposes individual root")
 var collateral=ui.game.Cards.Splash.select(ui.game,c.payload).filter(func(hit):return hit.target==first.id)[0].preview.damage
 await t.capture("ui-108-special-equipment-drag.png")
 await t.release_target(await t.reveal_drop_target(c.key))
 t.check(ui.game._equipment(second.id).durability<12.8 and is_equal_approx(ui.game._equipment(first.id).durability,8-collateral),"SPECIAL UI drag commits the selected root and current same-position splash")

 # Existing crotch equipment supplies a shared link target in both body regions.
 ui.game=Game.new(42);ui.game.state.equipment=[];ui.game.state.composites=[];ui.game.state.links=[]
 var anchor=ui.game._install_special("crotch_rope_low","special_3_a")
 var thigh=ui.game.add_fixture("thigh",8)
 var link=ui.game._install_link(anchor.id,thigh.id,8,"fixture")
 ui.render();await t.frames()
 await t.inspect_body("special_3")
 details=ui.find_child("EquipmentDetails",true,false)
 t.check(t.visible_text(details).contains(link.name) and ui.body_buttons.special_3.text.contains("·链"),"CROTCH LINK UI special region displays existing shared rope")
 await t.close_information()
 uid=ui.view.hand.filter(func(h):return h.type=="strain")[0].uid
 c=Queries.find(ui.view,"card",{"uid":uid,"target":link.id,"slot":"special_3_a"})
 if ui.card_faces.get(uid,false): await t.flip(uid)
 await t.start_drag(uid,"special_3")
 t.check(c.valid and ui.drop_targets.has(c.key),"CROTCH LINK UI special-side drag uses formal rope candidate")
 var damage=c.payload.preview.damage
 collateral=ui.game.Cards.Splash.select(ui.game,c.payload).filter(func(hit):return hit.target==anchor.id)[0].preview.damage
 await t.release_target(await t.reveal_drop_target(c.key))
 t.check(is_equal_approx(ui.game._equipment(link.id).durability,8-damage) and is_equal_approx(ui.game._equipment(anchor.id).durability,8-collateral) and ui.game._equipment(thigh.id).durability==8,"CROTCH LINK UI charges the selected rope, splashes its shared position and preserves the other endpoint")
 await t.inspect_body("thigh")
 t.check(t.visible_text(ui.find_child("EquipmentDetails",true,false)).contains(link.name),"CROTCH LINK UI opposite region displays same surviving rope")

 # Chastity roots and their linked reinforcement remain separate visible targets.
 await t.close_information()
 ui.game=Game.new(42,false,"equipment",true,true,25)
 var lock=ui.game._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 ui.render();await t.frames()
 t.check(ui.view.pressure.maximum==130 and ui.body_buttons.special_2.text.contains("2"),"CHASTITY UI projects the raised climax threshold and counts lock plus reinforcement")
 await t.inspect_body("special_2")
 details=ui.find_child("EquipmentDetails",true,false)
 var lock_card=details.find_child("EquipmentCard_"+lock.id,true,false)
 await Pointer.press(t,lock_card.find_child("EquipmentCardDetailsToggle",true,false))
 await expand_description(t,lock_card)
 var text=t.visible_text(lock_card)
 t.check(t.visible_text(details).contains("高级平板锁加固带") and text.contains("负数跳蛋锁（导尿管）") and text.contains("自动上锁") and text.contains("消耗能量行动") and text.contains("当前系数3＝18") and text.contains("锁内震动系数0.4"),"CHASTITY UI shows the current stimulation and retention formulas")
 var lock_icon=lock_card.find_child("EquipmentLock_"+lock.id,true,false)
 t.check(lock.locked and lock_icon!=null and lock_icon.locked and lock_icon.lockable and text.contains("状态：已上锁") and text.contains("开锁"),"CHASTITY UI shows the auto-locked root with the normal closed-lock icon, explicit state and unlock method")
 await t.capture("ui-118-chastity-lock.png")
 # Unlocked owner with a tighter attached band: selection and damage use real facts.
 ui.game.state.equipment.clear();ui.game.state.composites.clear();ui.game.state.links.clear()
 lock.locked=false;lock.durability=lock.maximum*0.8
 var strap=ui.game.state.special_equipment.filter(func(e):return e.owner_id==lock.id)[0]
 var strain_card=preload("res://tests/curse_cases.gd").give(ui.game,"strain")
 ui.render();await t.frames()
 await t.start_drag(strain_card.uid,"special_2")
 var strain_action=Queries.find(ui.view,"card",{"uid":strain_card.uid,"target":lock.id,"free":false})
 t.check(strain_action.valid and strain_action.release_preview.after==0,"PLATE STRAIN UI previews whole removal with attached band")
 await t.release_target(await t.reveal_drop_target(strain_action.key))
 t.check(ui.game._equipment(lock.id).is_empty() and ui.game._equipment(strap.id).is_empty(),"PLATE STRAIN UI real drag removes owner and its band together")

 # Full-cup fixing bands share the component projection without borrowing lock state.
 await t.close_information()
 ui.game=Game.new(42)
 var cup=ui.game._install_special("urethral_full_cup_medium","special_2_a",3)
 ui.render();await t.frames()
 t.check(ui.body_buttons.special_2.text.contains("2") and not ui.game.SpecialEquipment.portrait_layers(ui.game.state.special_equipment).has("flat_lock_reinforcement"),"CUP BAND UI counts cup and component without showing plate-lock art")
 await t.inspect_body("special_2")
 details=ui.find_child("EquipmentDetails",true,false)
 var cup_card=details.find_child("EquipmentCard_"+cup.id,true,false)
 await Pointer.press(t,cup_card.find_child("EquipmentCardDetailsToggle",true,false))
 await expand_description(t,cup_card)
 text=t.visible_text(details)
 t.check(text.contains("中级马眼全包榨精杯") and text.contains("中级榨精杯固定带") and text.contains("不能滑脱杯体") and not text.contains("状态：已上锁"),"CUP BAND UI shows the real owner, component and removal rule without lock controls")
