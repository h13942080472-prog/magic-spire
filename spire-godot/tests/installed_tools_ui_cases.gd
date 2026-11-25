extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 await read_only_details(t)
 var ui=t.ui
 ui.restart(42)
 var fixture=preload("res://tests/link_cases.gd").precise_tool_fixture(ui.game)
 ui.render();await t.frames()
 await Navigation.press(t,"OpenItems")
 t.check(await t.click("item_use",{"item":fixture.tool}),"TOOL UI linked-target knife enters the hand")
 await t.close_information()
 var card=ui.game.state.hand.back()
 var before=ui.game.export_snapshot()
 await t.start_drag(card.uid,"thigh")
 var target=await t.reveal_drop_target(fixture.link)
 t.check(ui.game.state==before,"TOOL UI exposed knee link previews without mutation")
 await t.release_target(target)
 t.check(ui.game._equipment(fixture.link).durability==3 and ui.game.Cards.instance(ui.game,card.uid).remove_left==2 and ui.view.energy==before.energy,"TOOL UI hand-held cut spends one charge on the selected link")
 ui.restart(42);await t.frames()
 t.check(ui.active_drag.is_empty() and ui.view.display_facts.map(func(entry):return Queries.fact_key(entry))==ui.game.command_facts().map(func(entry):return Queries.fact_key(entry)),"TOOL UI restarting after a target drag rebuilds facts without reading removed equipment")

static func read_only_details(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.items.clear();ui.game._gain_tool("saw")
 ui.game.state.phase="map";ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await Navigation.press(t,"OpenItems")
 var text=t.visible_text(ui.layout)
 t.check(text.contains("7点真实伤害") and text.contains("移除2") and ui.game.Tools.TYPES.saw.materials.all(func(material):return text.contains(ui.game.Equipment.MATERIAL_NAMES[material])),"TOOL inventory card shows saw damage, remove keyword and every supported material")
 t.check(ui.find_child("ItemToHand_"+ui.view.items[0].id,true,false).text=="使用","TOOL backpack offers Use for a cutter with no targets")
 t.check(ui.game.export_snapshot()==before,"TOOL inspecting full effects never uses a charge or mutates gameplay")
 await t.capture("ui-tool-effect-details.png")
 var shop=preload("res://core/room_services.gd").detail(ui.game,{"kind":"tool","type":"saw"})
 t.check(shop.contains("7点真实伤害") and shop.contains("共2次使用") and shop.contains("适用材料"),"TOOL shop reuses actual tool effects instead of a count-only description")
 var item_id=ui.view.items[0].id
 t.check(await t.click("item_discard",{"item":item_id}) and ui.view.items.is_empty(),"TOOL map inventory discards through the real candidate")
 t.check(ui.game.state.phase==before.phase and ui.game.state.tick==before.tick and ui.game.state.energy==before.energy and ui.game.state.mana==before.mana,"TOOL map discard costs no resources or turns")
 await t.close_information()
