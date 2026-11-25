extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.relics=["pocket_knife"]
 ui.game._start_battle();ui.render();await t.frames()
 var knife=ui.game.state.hand.filter(func(c):return c.type=="pocket_knife")[0]
 var victim=ui.game.state.enemies.back()
 var hp=victim.hp
 await t.drop_card_on_actor(knife.uid,victim.id);await t.frames()
 t.check(ui.game._enemy(victim.id).hp==hp-8 and ui.game._card(knife.uid).is_empty(),"KNIFE native drag damages the selected enemy")
 ui.game._gain_card("pocket_knife",{},true);ui.render();await t.frames()
 knife=ui.game.state.hand.back()
 ui.card_buttons[knife.uid].pressed.emit();await t.frames()
 ui.actor_targets[victim.id].pressed.emit();await t.frames()
 t.check(ui.game._enemy(victim.id).hp==hp-16 and ui.game._card(knife.uid).is_empty(),"KNIFE card click and enemy click play the held item")
 ui.restart(42);ui.game.state.items.clear();ui.game._gain_tool("shard")
 ui.game.state.phase="map";ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await Navigation.press(t,"OpenItems")
 var item=ui.view.items[0]
 var drawer=ui.find_child("InformationDrawer",true,false)
 var glyph=ui.find_child("ToolIcon_"+item.id,true,false)
 t.check(glyph!=null and glyph.symbol=="shard" and glyph.kind=="tool","INVENTORY knife uses the existing shard artwork")
 var list_text=t.visible_text(ui.find_child("InventoryList",true,false))
 var initial_face=drawer.find_child("DisplayCard_inventory_"+item.id,true,false)
 t.check(initial_face!=null and t.visible_text(initial_face).contains("切割") and list_text.contains("使用") and not list_text.contains("剩余") and not list_text.contains("切割") and not list_text.contains("加入手牌"),"INVENTORY first card opens beside a list of names and actions")
 t.check(drawer.size.x<=625 and drawer.size.y<=450 and ui.game.state==before,"INVENTORY compact initial drawer fits its bounds and browsing stays read-only")
 await t.capture("ui-inventory-compact.png")
 ui.game.RelicEffects.gain(ui.game,"toolbox");ui.game._gain_tool("mana_potion");ui.game._gain_tool("saw")
 ui.game.state.mana=60;ui.render();await t.frames()
 for row in ui.view.items:
  var icon=ui.find_child("ToolIcon_"+row.id,true,false)
  var line=ui.find_child("InventoryRow_"+row.id,true,false)
  t.check(icon!=null and icon.symbol==row.type and line!=null and line.find_child("ItemToHand_"+row.id,true,false)!=null and line.find_child("ItemDiscard_"+row.id,true,false)!=null,"INVENTORY each physical item shows its icon and both actions on one row")
 var selected=ui.view.items.back().id;before=ui.game.export_snapshot()
 var pick=ui.find_child("ToolItem_"+selected,true,false)
 var icon_point=pick.find_child("ToolIcon_"+selected,true,false).get_global_rect().get_center()
 await t.move_mouse(icon_point);await t.mouse_button(icon_point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(icon_point,MOUSE_BUTTON_LEFT,false);await t.frames()
 var face=ui.find_child("DisplayCard_inventory_"+selected,true,false)
 t.check(face!=null and face.symbol=="saw" and pick.button_pressed,"INVENTORY pressing the thumbnail selects the physical saw")
 await Navigation.press(t,"InventoryFlip");await t.frames(12)
 t.check(face!=null and face.free_face and face.get_node("CardCost").text=="1" and face.get_node("CardIllustration").texture.resource_path.ends_with("/saw_wall.svg") and ui.game.state==before,"INVENTORY flip previews the wall face and cost without playing the card")
 t.check(face!=null and not face.text_overflow and not face.get_node("CardText").get_v_scroll_bar().visible,"INVENTORY wall cutter materials and current posture fit the detail card together")
 await t.move_mouse(Vector2(52,112));await t.capture("ui-inventory-tools.png")
 await Navigation.press(t,"ItemDiscard_"+selected)
 t.check(ui.game._item(selected).is_empty() and ui.game.state.items.size()==before.items.size()-1 and ui.game.state.energy==before.energy and ui.game.state.tick==before.tick,"INVENTORY compact discard submits the actual chosen item once and costs no turn")
 t.check(ui.find_child("DisplayCard_inventory_"+item.id,true,false)!=null and ui.find_child("DisplayCard_inventory_"+selected,true,false)==null,"INVENTORY removing the selected item moves the preview to the first remaining card")
 var potion=ui.view.items.back()
 await Navigation.press(t,"ToolItem_"+potion.id)
 t.check(ui.find_child("DisplayCard_inventory_"+potion.id,true,false)!=null and not ui.find_child("InventoryFlip",true,false).visible,"INVENTORY selecting a single-faced potion by name shows only its playable face")
 await Navigation.press(t,"ItemToHand_"+potion.id)
 var potion_card=ui.game.state.hand.back()
 t.check(potion_card.type=="mana_potion" and ui.game.state.mana==before.mana,"INVENTORY Use adds the potion to the hand without drinking it")
 t.check(await t.click("card",{"uid":potion_card.uid,"target":"self"}) and ui.game.state.mana>before.mana,"INVENTORY out-of-battle mana potion can then be played from the drawer")
 await t.close_information()

 await knife_drag(t)
 await overflow_runtime(t)
 await duplicate_items_with_full_hand(t)

static func duplicate_items_with_full_hand(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.items.clear()
 ui.game._gain_tool("saw");ui.game._gain_tool("saw")
 ui.game.state.items.back().uses=1
 while ui.game.state.hand.size()<ui.game.B.HAND_LIMIT:
  preload("res://tests/curse_cases.gd").give(ui.game,"strain")
 ui.render();await t.frames();await Navigation.press(t,"OpenItems")
 var first=ui.view.items[0].id;var second=ui.view.items[1].id
 await Navigation.press(t,"ToolItem_"+second)
 var terms=ui.find_child("DisplayCard_inventory_"+second,true,false).get_node("CardText/Content/CardKeywords")
 t.check(t.visible_text(terms).strip_edges()=="移除","INVENTORY identical cutters preview the selected copy's removal keyword")
 await Navigation.press(t,"ToolItem_"+first)
 terms=ui.find_child("DisplayCard_inventory_"+first,true,false).get_node("CardText/Content/CardKeywords")
 t.check(t.visible_text(terms).strip_edges()=="移除2","INVENTORY switching to the fresh sibling restores its own removal keyword")
 var blocked=ui.find_child("ItemToHand_"+second,true,false)
 var before=ui.game.export_snapshot()
 await preload("res://tests/target_sidebar_ui_cases.gd").press(t,blocked);await t.frames()
 t.check(blocked.disabled and blocked.text=="使用" and blocked.tooltip_text.contains("手牌已满") and t.visible_text(ui.drawer_layer).contains("手牌已满") and ui.game.state==before,"INVENTORY full hand keeps Use disabled with a visible reason and preserves inventory")
 await Navigation.press(t,"ItemDiscard_"+second)
 t.check(ui.game._item(second).is_empty() and not ui.game._item(first).is_empty(),"INVENTORY discarding one of two identical items keeps its sibling")
 await t.close_information()

static func knife_drag(t) -> void:
 var ui=t.ui
 ui.restart(42,true,"equipment")
 var item=ui.game.state.items.filter(func(i):return i.type=="saw")[0]
 ui.render();await t.frames()
 await Navigation.press(t,"OpenItems")
 await preload("res://tests/target_sidebar_ui_cases.gd").press(t,ui.find_child("ItemToHand_"+item.id,true,false));await t.frames()
 t.check(ui.game._item(item.id).is_empty() and ui.game.state.hand.back().type=="saw","ITEM CARD UI real button converts the named row directly")
 await t.close_information()
 var card=ui.game.state.hand.back()
 var target=ui.game.state.equipment.filter(func(piece):return piece.template=="cable_tie")[0]
 var before=ui.game.state.energy
 t.check(t.visible_text(ui.card_buttons[card.uid].get_node("CardText/Content/CardRequirements")).contains("手指自由"),"ITEM CARD UI hand-held face shows its grip condition")
 await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid].get_node("CardText/Content/CardRequirements")).contains("目标外露") and not t.visible_text(ui.card_buttons[card.uid].get_node("CardText/Content/CardRequirements")).contains("手指自由"),"ITEM CARD UI wall face replaces grip with posture and exposure")
 await t.start_drag(card.uid,"thigh")
 var preview=ui.find_child("CardDragPreview",true,false).get_child(0).get_node("CardIllustration")
 t.check(preview.texture!=null and preview.texture.resource_path.ends_with("/items/saw_wall.svg"),"ITEM CARD UI dragged cutter preserves the wall illustration")
 await t.release_target(await t.reveal_drop_target(target.id))
 await t.frames()
 t.check(ui.game._equipment(target.id).is_empty() and ui.game.state.energy==before-1 and ui.game.Cards.instance(ui.game,card.uid).remove_left==1,"ITEM CARD UI drag flipped saw onto the selected restraint")

static func overflow_runtime(t) -> void:
 var ui=t.ui
 ui.restart(42,true,"equipment");ui.game.state.items.clear()
 for type in ["shard","saw","mana_potion"]: ui.game._gain_tool(type)
 ui.render();await t.frames()
 t.check(await t.click("finish_rest") and ui.view.phase=="pack" and ui.show_items and ui.view.carried_items==ui.view.capacity+1,"INVENTORY actual room exit with one excess item automatically opens packing drawer")
 var before=ui.game.export_snapshot();var scene=ui.layout
 var drawer=ui.drawer_layer;var list=ui.find_child("InventoryList",true,false)
 var item=ui.view.items[1];var button=ui.find_child("ItemDiscard_"+item.id,true,false)
 button.grab_focus();await t.frames()
 t.check(is_instance_valid(list) and ui.layout==scene and ui.drawer_layer==drawer and ui.game.state==before and button.get_parent().name=="InventoryRow_"+item.id,"INVENTORY browsing an overflow row preserves the scene, list and state")
 # Park the pointer on the dismiss surface before counting idle nodes; hovering a button can open an engine tooltip.
 var dismiss=drawer.find_child("DismissDrawer",true,false)
 await t.move_mouse(dismiss.get_global_rect().position+Vector2(12,12))
 var nodes=t.get_node_count()
 await t.frames(12)
 t.check(t.get_node_count()==nodes,"INVENTORY idle overflow node count stays stable: %d -> %d" % [nodes,t.get_node_count()])
 t.check(ui.candidate_buttons.values().all(func(control):return is_instance_valid(control) and control.is_inside_tree()),"INVENTORY overflow actions stay attached to the scene")
 await Navigation.press(t,button.name)
 t.check(ui.game._item(item.id).is_empty() and ui.view.carried_items==ui.view.capacity and ui.view.version==before.version+1 and ui.game.state.tick==before.tick,"INVENTORY overflow discard removes selected item once without advancing turn")
 await t.close_information()
 t.check(await t.click("finish_pack") and ui.view.phase=="cleared","INVENTORY exact capacity permits formal packing completion")
 ui._open_drawer("show_items");await t.frames()
 for remaining in ui.view.items.duplicate(true):
  await Navigation.press(t,"ItemDiscard_"+remaining.id)
 t.check(ui.view.items.is_empty() and ui.find_child("InventoryList",true,false)==null and t.visible_text(ui.drawer_layer).contains("道具栏为空"),"INVENTORY discarding the final item rebuilds a clean empty state")
 await t.close_information()
