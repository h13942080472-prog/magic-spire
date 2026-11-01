extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.items.clear();ui.game._gain_tool("return_seal")
 ui.game.state.phase="map";ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await Navigation.press(t,"OpenItems")
 var item=ui.view.items[0]
 var drawer=ui.find_child("InformationDrawer",true,false)
 var glyph=ui.find_child("ToolIcon_"+item.id,true,false)
 t.check(glyph!=null and glyph.symbol=="return_scroll" and glyph.kind=="tool","INVENTORY return seal uses the existing scroll artwork")
 var text=t.visible_text(drawer)
 t.check(text.contains("监狱外部路线") and text.contains("剩余1次") and not text.contains("每次消耗1次使用次数") and not text.contains("0能量"),"INVENTORY default view keeps effect and count without repetitive costs")
 t.check(ui.find_child("ItemHelpContent",true,false)==null and drawer.size.y<500 and ui.game.state==before,"INVENTORY compact initial drawer and browsing are read-only")
 await t.capture("ui-inventory-compact.png")
 await Navigation.press(t,"ItemHelpToggle")
 t.check(t.visible_text(ui.find_child("ItemHelpContent",true,false)).contains("手指或脚趾") and ui.game.state==before,"INVENTORY detailed rules remain available on demand without gameplay changes")
 await Navigation.press(t,"ItemHelpToggle")
 ui.game.RelicEffects.gain(ui.game,"toolbox");ui.game._gain_tool("mana_potion");ui.game._gain_tool("saw")
 ui.game.state.mana=60;ui.render();await t.frames()
 for row in ui.view.items:
  await Navigation.press(t,"ToolItem_"+row.id)
  var icon=ui.find_child("ToolIcon_"+row.id,true,false)
  t.check(icon!=null and icon.symbol==("return_scroll" if row.type=="return_seal" else row.type),"INVENTORY every actual item retains its own stable icon mapping")
  t.check(ui.find_child("ItemHelpContent",true,false)==null,"INVENTORY changing selection closes the previous item rules")
 await t.capture("ui-inventory-tools.png")
 var selected=ui.selected_item;before=ui.game.export_snapshot()
 await Navigation.press(t,"ItemHelpToggle")
 await Navigation.press(t,"ItemDiscard")
 t.check(ui.game._item(selected).is_empty() and ui.game.state.items.size()==before.items.size()-1 and ui.game.state.energy==before.energy and ui.game.state.tick==before.tick,"INVENTORY compact discard submits the actual chosen item once and costs no turn")
 t.check(ui.find_child("ItemHelpContent",true,false)==null,"INVENTORY removing the selection collapses rules for the replacement item")
 await t.close_information()

 await overflow_runtime(t)

static func overflow_runtime(t) -> void:
 var ui=t.ui
 ui.restart(42,true,"equipment");ui.game.state.items.clear()
 for type in ["shard","saw","mana_potion"]: ui.game._gain_tool(type)
 ui.render();await t.frames()
 t.check(await t.click("finish_rest") and ui.view.phase=="pack" and ui.show_items and ui.view.carried_items==ui.view.capacity+1,"INVENTORY actual room exit with one excess item automatically opens packing drawer")
 var before=ui.game.export_snapshot();var scene=ui.layout
 var drawer=ui.drawer_layer;var list=ui.find_child("InventoryList",true,false)
 var item=ui.view.items[1];var button=ui.find_child("ToolItem_"+item.id,true,false)
 var scroll=list.get_parent();scroll.scroll_vertical=20
 await t.frames()
 var scroll_position=scroll.scroll_vertical
 await Navigation.press(t,button.name)
 await Navigation.press(t,"ItemHelpToggle")
 t.check(is_instance_valid(list) and is_instance_valid(button) and ui.layout==scene and ui.drawer_layer==drawer and ui.find_child("InventoryList",true,false)==list,"INVENTORY selection and help preserve scene, drawer and inventory list instances")
 t.check(ui.selected_item==item.id and t.visible_text(ui.find_child("InventoryDetail",true,false)).contains(item.name) and ui.game.state==before,"INVENTORY partial details match selection without changing authoritative state")
 t.check(is_instance_valid(scroll) and scroll.scroll_vertical==scroll_position,"INVENTORY detail updates preserve the item list scroll position")
 for i in range(8):
  await Navigation.press(t,"ItemHelpToggle")
 var nodes=t.get_node_count()
 await t.frames(12)
 t.check(t.get_node_count()==nodes and ui.candidate_buttons.values().all(func(control):return is_instance_valid(control) and control.is_inside_tree()),"INVENTORY settled overflow has stable node count and no detached action controls")
 await Navigation.press(t,"ItemDiscard")
 t.check(ui.game._item(item.id).is_empty() and ui.view.carried_items==ui.view.capacity and ui.view.version==before.version+1 and ui.game.state.tick==before.tick,"INVENTORY overflow discard removes selected item once without advancing turn")
 await t.close_information()
 t.check(await t.click("finish_pack") and ui.view.phase=="cleared","INVENTORY exact capacity permits formal packing completion")
 ui._open_drawer("show_items");await t.frames()
 for remaining in ui.view.items.duplicate(true):
  await Navigation.press(t,"ToolItem_"+remaining.id)
  await Navigation.press(t,"ItemDiscard")
 t.check(ui.view.items.is_empty() and ui.find_child("ItemDiscard",true,false)==null and t.visible_text(ui.drawer_layer).contains("道具栏为空"),"INVENTORY discarding the final item rebuilds a clean empty state")
 await t.close_information()
