extends Control

var _key=[]

func _presentation_key(ui) -> Array:
 # Only rendered facts: never retain an old View, candidate, or equipment graph.
 var view=ui.view
 return [String(view.run_header.location),String(view.run_header.turn),String(view.run_header.order),bool(view.run_header.last),int(view.security),String(view.wall),int(view.wall_position.distance),bool(view.pressure.overloaded),int(view.carried_items),int(view.capacity),int(view.deck_count),bool(view.prison.get("active",false)),String(view.phase),bool(view.practice),bool(ui.show_route),bool(ui.save_failed),String(ui.localization.locale)]

func _clear_buttons() -> void:
 var buttons=[]
 for child in get_children():
  if child is Button: buttons.append(child)
 for button in buttons:
  remove_child(button);button.queue_free()

func configure(ui) -> void:
 if _key==_presentation_key(ui):
  return
 var view=ui.view
 $Trim.color=ui.Palette.HAIRLINE
 $Strip.color=ui.Palette.HUD
 var info_style=StyleBoxEmpty.new()
 $HeaderInfo.add_theme_stylebox_override("panel",info_style)
 var location_style=ui.Palette.button_style("pressed",ui.GOLD,"quiet")
 $HeaderInfo/Location.add_theme_stylebox_override("panel",location_style)
 var tone=ui.RED if view.run_header.last else ui.CYAN
 var order_style=ui._style(Color(0,0,0,0),tone.darkened(0.62),3);order_style.shadow_size=0;order_style.set_border_width_all(0)
 $HeaderInfo/HeaderOrderBadge.add_theme_stylebox_override("panel",order_style)
 for entry in [["HeaderFloor",view.run_header.location,ui.GOLD],["HeaderRound",view.run_header.turn,ui.TEXT],["HeaderOrder",view.run_header.order,tone],["HeaderSecurity","警戒度%d级" % view.security,ui.GOLD],["WallPosition","距墙%d格" % view.wall_position.distance,ui.MUTED]]:
  var label=get_node("HeaderInfo/"+entry[0])
  label.text=entry[1];label.add_theme_color_override("font_color",entry[2])
 $HeaderInfo/WallPosition.visible=view.wall!="none"
 _clear_buttons()
 var book=ui._button("教程书",func():ui._open_tutorial(),ui.GOLD)
 book.name="OpenTutorial"
 ui.Palette.style_button(book,ui.GOLD,"quiet")
 book.add_theme_color_override("font_color",ui.GOLD)
 ui._place(book,Rect2(714,12,100,38),self)
 var status=ui._button("状态 !" if view.pressure.overloaded else "状态",func():ui._open_drawer("show_pressure"),ui.RED if view.pressure.overloaded else ui.CYAN)
 status.name="OpenStatus";ui._place(status,Rect2(830,12,144,38),self)
 var items=ui._button("道具 %d / %d" % [view.carried_items,view.capacity],func():ui._open_drawer("show_items"))
 items.name="OpenItems";ui._place(items,Rect2(990,12,154,38),self)
 var deck=ui._button("卡组 %d" % view.deck_count,func():ui._open_drawer("show_deck"))
 deck.name="OpenDeck";ui._place(deck,Rect2(1160,12,118,38),self)
 var in_prison=view.prison.get("active",false) or view.phase in ["captured","prison_end"]
 var map=ui._button("牢房说明" if in_prison else "返回房间" if ui.show_route and view.phase in ["battle","prepare","reward","rest","event","shop","treasure","departure"] else ("练习说明" if view.practice else "塔路"),func():
  if in_prison:ui._open_tutorial("prison")
  elif ui.view.phase in ["battle","prepare","reward","rest","event","shop","treasure","departure"]:
   ui.show_route=not ui.show_route;ui._close_drawers()
   ui.selected_card="";ui.show_body=false
   ui.render(ui.view),ui.CYAN)
 map.name="OpenPrisonTutorial" if in_prison else "OpenMap"
 ui._place(map,Rect2(1294,12,118,38),self)
 var menu=ui._button("菜单 !" if ui.save_failed else "菜单 ≡",func():ui._open_drawer("show_menu"),ui.RED if ui.save_failed else ui.MUTED)
 menu.name="OpenMenu";ui._place(menu,Rect2(1428,12,136,38),self)
 for button in [status,items,deck,map,menu]: ui.Palette.style_button(button,ui.CYAN,"quiet")
 if view.pressure.overloaded: status.add_theme_color_override("font_color",ui.RED)
 if ui.save_failed: menu.add_theme_color_override("font_color",ui.RED)
 _key=_presentation_key(ui)
