extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

static func build(ui) -> void:
 var panel=ui.view.reward_panel.get("enchantments",{})
 var root=Control.new();root.name="EnchantmentScreen";root.z_index=80;root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui._place(root,Rect2(0,0,1600,900))
 preload("res://ui/reward_backdrop.gd").build(ui,root,0.94)
 var title=ui._label("选择附魔" if ui.selected_enchantment=="" else "选择卡牌",34,ui.GOLD)
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ui._place(title,Rect2(400,112,800,52),root)
 var selected=panel.get("offers",[]).filter(func(offer):return offer.id==ui.selected_enchantment)
 if not selected.is_empty():
  cards(ui,root,selected[0])
 else:
  ui.selected_enchantment=""
  offers(ui,root,panel)
 var back=ui._button("‹ 返回",func():
  if ui.selected_enchantment!="": ui.selected_enchantment=""
  else: ui.show_enchantments=false
  ui.render(ui.view),ui.GOLD)
 back.name="EnchantmentBack";ui._place(back,Rect2(680,802,240,50),root)

static func offers(ui, root: Control, panel: Dictionary) -> void:
 var choices=panel.get("offers",[])
 var left=(1600-choices.size()*330-(choices.size()-1)*28)/2.0
 for i in range(choices.size()):
  var offer=choices[i]
  var accent=ui.GOLD if offer.rarity=="rare" else ui.CYAN
  var button=ui._button("",func():ui.selected_enchantment=offer.id;ui.render(ui.view),accent)
  button.name="EnchantmentOffer_"+offer.id
  button.disabled=not offer.cards.any(func(card):return card.available)
  ui._place(button,Rect2(left+i*358,250,330,360),root)
  var name=ui._label(offer.name,30,accent);name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  ui._place(name,Rect2(16,38,298,48),button)
  var cost=ui._label(("稀有" if offer.rarity=="rare" else "普通")+" · %d回合" % offer.turns,19,ui.MUTED)
  cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;ui._place(cost,Rect2(16,104,298,32),button)
  var detail=ui._label(offer.detail,21,ui.TEXT);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  ui._place(detail,Rect2(28,170,274,145),button)
  for child in button.get_children(): ui._ignore_mouse(child)
 for i in range(panel.get("refresh_keys",[]).size()):
  var fact=Queries.fact_by_key(ui.view,panel.refresh_keys[i])
  var label=("自身魔力" if fact.payload.payment=="self" else "魔瓶魔力")+" · "+fact.label
  var button=ui._button(label,func():ui.command_router.emit("enchant",fact),ui.CYAN)
  button.name="EnchantmentRefresh_"+fact.payload.payment;button.disabled=not fact.valid
  ui._place(button,Rect2(452+i*358,692,338,56),root);ui.candidate_buttons[fact.key]=button
  button.mouse_entered.connect(func():ui._show_term(button,{"label":fact.label,"detail":fact.reason if not fact.valid else fact.detail}))
  button.mouse_exited.connect(ui._hide_term)

static func cards(ui, root: Control, offer: Dictionary) -> void:
 var subtitle=ui._label(offer.name+" · %d回合" % offer.turns,23,ui.CYAN)
 subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;ui._place(subtitle,Rect2(400,174,800,40),root)
 var scroll=ScrollContainer.new();scroll.name="EnchantmentCards"
 ui._place(scroll,Rect2(292,245,1016,516),root)
 var grid=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",22);grid.add_theme_constant_override("v_separation",24)
 scroll.add_child(grid)
 for card in offer.cards:
  var fact=Queries.fact_by_key(ui.view,card.action_key)
  var click=func():
   ui.show_enchantments=false;ui.selected_enchantment=""
   ui.command_router.emit("enchant",fact)
  var button=ui._display_card(card.type,grid,click,"enchant_"+card.uid,Vector2(228,302),card.uid,true,card.text)
  button.name="EnchantmentCard_"+card.uid;button.disabled=not fact.valid
  ui.candidate_buttons[fact.key]=button
