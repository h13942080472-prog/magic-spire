extends Control
const Scenery=preload("res://ui/shop_scenery.gd")
const Glyph=preload("res://ui/shop_glyph.gd")
const ShopCopy=preload("res://data/shop_copy.gd")
const PAYMENT_ART={
 "self":preload("res://assets/art/shop-payment-self-v1.png"),
 "sleeve":preload("res://assets/art/shop-payment-sleeve-v1.png"),
 "hand":preload("res://assets/art/shop-payment-hand-v1.png"),
 "foot":preload("res://assets/art/shop-payment-foot-v1.png")
}
var ui

func _ready() -> void:
 var background=Scenery.new();ui._place(background,Rect2(Vector2.ZERO,size),self)
 var portrait=TextureRect.new();portrait.name="ShopkeeperPortrait"
 portrait.texture=preload("res://assets/characters/shopkeeper.png")
 portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui._place(portrait,Rect2(20,78,336,686),self)
 var canopy=Scenery.new();canopy.foreground=true;canopy.name="ShopCanopy"
 ui._place(canopy,Rect2(Vector2.ZERO,size),self)
 _text("月灯杂货铺",Rect2(25,23,210,36),23,ui.TEXT)
 for source in ["self","flask"]:
  var balance=ui.view.mana if source=="self" else ui.view.mana_flask.mana
  var label=("自身魔力 " if source=="self" else "魔瓶魔力 ")+ui.game.number(balance)
  var button=ui._button(label,func():ui.shop_payment=source;ui.render(ui.view),ui.CYAN if ui.shop_payment==source else ui.MUTED)
  button.name="ShopPayment_"+source;button.button_pressed=ui.shop_payment==source;button.toggle_mode=true
  ui._place(button,Rect2(1088 if source=="self" else 1315,20,207,38),self)
 _text("店主",Rect2(36,605,159,26),18,ui.GOLD)
 var bubble=PanelContainer.new();bubble.name="ShopkeeperSpeech"
 bubble.add_theme_stylebox_override("panel",ui._style(Color("24322f"),ui.GOLD.darkened(0.55)))
 ui._place(bubble,Rect2(32,632,312,128),self)
 var speech=ui._label(ui.view.shop.greeting,14,ui.TEXT);speech.name="ShopkeeperSpeechText"
 bubble.add_child(speech);ui._ignore_mouse(bubble);ui.speech_group=bubble
 bubble.visible=ui.view.shop.greeting!="" and ui._speech_visible(ui.view.shop.greeting_id)
 var cards=ui.view.shop.stock.filter(func(o):return o.kind=="card")
 for i in range(cards.size()): _card_offer(cards[i],Rect2(380+i*230,95,218,332))
 for kind in ["tool","relic"]:
  var goods=ui.view.shop.stock.filter(func(o):return o.kind==kind)
  var slots=4 if kind=="tool" else 3
  var goods_width=(1138.0-12.0*(slots-1))/slots
  var top=428 if kind=="tool" else 566
  for i in range(goods.size()): _offer(goods[i],Rect2(380+i*(goods_width+12),top,goods_width,116))
  if goods.is_empty(): _text("没有新的遗物可出售",Rect2(380,top+35,450,30),17,ui.MUTED)
 var release=_service_button("拘束解除", "release",Rect2(380,718,275,46));release.name="ShopRelease"
 var remove=_service_button("删牌服务 · 本店一次", "remove",Rect2(667,718,275,46));remove.name="ShopRemove"
 remove.disabled=ui.view.shop.remove_used
 if remove.disabled: remove.text="删牌服务 · 已使用"
 var tidy=_service_button("整理道具", "discard",Rect2(954,718,275,46));tidy.name="ShopInventory"
 var leave=ui.actions.select("service_flow")[0]
 var button=ui._button("继续旅程 →",func():ui._submit(leave),ui.CYAN);button.name="ShopLeave"
 ui.candidate_buttons[leave.id]=button;ui._place(button,Rect2(1241,718,277,46),self)

func _text(text: String, rect: Rect2, font: int, color: Color) -> Label:
 var label=ui._label(text,font,color);ui._place(label,rect,self);return label

func _service_button(label: String, mode: String, rect: Rect2) -> Button:
 var button=ui._button(label,func():
  ui.shop_service_mode=mode
  ui._open_drawer("show_shop_service"),ui.GOLD)
 ui._place(button,rect,self)
 return button

func _card_offer(offer: Dictionary, rect: Rect2) -> void:
 var candidate=ui.actions.find("service",{"op":"take","index":offer.index,"payment":ui.shop_payment})
 var box=Control.new();ui._place(box,rect,self)
 var card_size=Vector2(196,196*1.32)
 var button=ui._display_card(offer.type,box,func():
  if not candidate.is_empty(): ui._submit(candidate),"shop_"+str(offer.index),card_size)
 button.position.x=(rect.size.x-card_size.x)/2
 button.name="ShopOffer%d" % offer.index
 button.disabled=offer.taken or not candidate.get("valid",false)
 if not offer.taken: ui.candidate_buttons[candidate.id]=button
 if not offer.taken: _connect_chatter(button,candidate)
 button.modulate=Color(0.6,0.6,0.6) if button.disabled else Color.WHITE
 var price=ui._label("售罄" if offer.taken else "%s 魔力" % ui.game.number(offer.price),18,ui.GOLD)
 price.name="ShopPrice%d" % offer.index;price.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 price.autowrap_mode=TextServer.AUTOWRAP_OFF
 ui._place(price,Rect2(0,card_size.y+10,rect.size.x,26),box)
 if not offer.taken and not candidate.valid:
  var reason=ui._label(candidate.reason,12,ui.RED)
  reason.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  ui._place(reason,Rect2(0,card_size.y+37,rect.size.x,20),box)

func _offer(offer: Dictionary, rect: Rect2) -> void:
 var candidate=ui.actions.find("service",{"op":"take","index":offer.index,"payment":ui.shop_payment})
 var button=preload("res://ui/elements/shop_offer.tscn").instantiate()
 ui._style_button(button,"",func():
  if not candidate.is_empty(): ui._submit(candidate),ui.GOLD if offer.kind=="card" else ui.CYAN)
 button.name="ShopOffer%d" % offer.index
 button.disabled=offer.taken or not candidate.get("valid",false)
 button.tooltip_text=offer.name+"\n"+offer.detail+("" if candidate.get("valid",false) else "\n"+candidate.get("reason","已售罄"))
 self.add_child(button);button.position=rect.position;button.size=rect.size
 if not offer.taken: ui.candidate_buttons[candidate.id]=button
 if not offer.taken: _connect_chatter(button,candidate)
 var name_label=ui._style_label(button.name_label(),offer.name,16,ui.TEXT if not offer.taken else ui.MUTED)
 name_label.position=Vector2(80,10);name_label.size=Vector2(rect.size.x-90,43)
 var glyph: Control
 if offer.kind=="relic":
  glyph=preload("res://ui/relic_icon.gd").new();glyph.relic={"id":offer.type}
 else:
  glyph=Glyph.new();glyph.kind=offer.kind;glyph.symbol=offer.type
 if offer.kind=="relic":
  var rarity=ui._label(offer.rarity_name,12,ui.CardFace.RARITY_COLORS[offer.rarity])
  rarity.name="RelicRarity"
  ui._place(rarity,Rect2(80,48,rect.size.x-90,18),button);button.move_child(rarity,1)
 ui._place(glyph,Rect2(8,22,64,64),button);button.move_child(glyph,2 if offer.kind=="relic" else 1)
 var currency="魔瓶魔力" if offer.get("required_payment","")=="flask" else "魔力"
 var price=ui._style_label(button.price_label(),"售罄" if offer.taken else "%s %s" % [ui.game.number(offer.price),currency],17,ui.MUTED if offer.taken else (ui.CYAN if candidate.valid else ui.RED))
 price.position=Vector2(80,68);price.size=Vector2(rect.size.x-90,25)
 if not offer.taken and not candidate.valid:
  var reason=ui._label(candidate.reason,10,ui.RED);reason.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  ui._place(reason,Rect2(6,94,rect.size.x-12,20),button)
 if offer.taken: button.modulate=Color(0.66,0.64,0.59)
 else:
  button.pivot_offset=rect.size/2
  button.mouse_entered.connect(func():button.create_tween().tween_property(button,"scale",Vector2(1.025,1.025),0.10))
  button.mouse_exited.connect(func():button.create_tween().tween_property(button,"scale",Vector2.ONE,0.10))

func _connect_chatter(control: Control, candidate: Dictionary) -> void:
 control.mouse_entered.connect(func():ui._shop_chatter(_chatter_pool(ui,candidate)))

static func _chatter_pool(ui, candidate: Dictionary) -> Array:
 var payment=str(candidate.payload.get("payment",ui.shop_payment))
 var required=float(candidate.mana_payment.flask_mana if payment=="flask" else candidate.mana_payment.mana)
 var balance=float(ui.view.mana_flask.mana if payment=="flask" else ui.view.mana)
 return ShopCopy.chatter_pool(payment,int(ui.view.arms),balance<required,str(candidate.get("copy_context","")))

static func services(ui, parent: VBoxContainer) -> void:
 var group={"release":"service_release","remove":"service_remove","discard":"item"}[ui.shop_service_mode]
 var candidates=ui.actions.select(group).filter(func(c):return c.payload.get("payment",ui.shop_payment)==ui.shop_payment)
 if ui.shop_service_mode=="discard": candidates=ui.actions.select("item",{"kind":"item_discard"})
 if ui.shop_service_mode=="release":
  parent.add_child(ui._label("选择一件交给店主。开锁与复合处理会在价格中列明。",16,ui.CYAN))
 elif ui.shop_service_mode=="remove": parent.add_child(ui._label("永久移除一张牌，本店仅一次。",16,ui.CYAN))
 var scroll=ui._scroll(parent)
 if candidates.is_empty():
  scroll.add_child(ui._label({"release":"目前没有需要卸下的拘束具。","remove":"本店的删牌服务已使用。","discard":"没有需要整理的随身道具。"}[ui.shop_service_mode],18,ui.MUTED));return
 if ui.shop_service_mode=="remove":
  var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",18);scroll.add_child(grid)
  for c in candidates:
   var entry=ui.view.deck_cards.filter(func(e):return e.uid==c.payload.uid)[0]
   var box=VBoxContainer.new();grid.add_child(box)
   var face=ui._display_card(entry.type,box,func():ui._submit(c),"remove_"+entry.uid)
   face.disabled=not c.valid;ui.candidate_buttons[c.id]=face
   face.mouse_entered.connect(func():ui._shop_chatter(_chatter_pool(ui,c)))
   box.add_child(ui._label(ui.game.number(c.mana)+("魔瓶魔力" if ui.shop_payment=="flask" else "魔力"),16,ui.GOLD))
   if not c.valid: box.add_child(ui._label(c.reason,13,ui.RED))
  return
 for c in candidates:
  var card=PanelContainer.new();card.add_theme_stylebox_override("panel",ui._style(Color("172633"),ui.GOLD.darkened(0.4)))
  scroll.add_child(card)
  var body=VBoxContainer.new();body.add_theme_constant_override("separation",7);card.add_child(body)
  if ui.shop_service_mode=="release":
   var jobs=ui.view.shop.release_jobs.filter(func(j):return j.id==c.payload.target)
   if not jobs.is_empty(): body.add_child(ui._label(jobs[0].location,14,ui.CYAN))
  ui._action_row(body,c)
  var action=ui.candidate_buttons.get(c.id)
  if is_instance_valid(action): action.mouse_entered.connect(func():ui._shop_chatter(_chatter_pool(ui,c)))

static func payment_overlay(ui) -> void:
 var scene=ui.view.shop.get("performance",{})
 if scene.is_empty() or scene.get("id","")==ui.shop_performance_seen: return
 var method=str(scene.get("method",""))
 if not PAYMENT_ART.has(method): return
 var overlay=Control.new();overlay.name="ShopPaymentPerformance";overlay.z_index=280
 overlay.mouse_filter=Control.MOUSE_FILTER_STOP
 ui._place(overlay,Rect2(0,0,1600,900),ui.layout)
 var shade=ColorRect.new();shade.color=Color(0.01,0.015,0.025,0.82);shade.mouse_filter=Control.MOUSE_FILTER_STOP
 ui._place(shade,Rect2(0,0,1600,900),overlay)
 var panel=PanelContainer.new();panel.name="ShopPaymentPerformancePanel"
 panel.add_theme_stylebox_override("panel",ui._style(Color("111b25"),ui.GOLD))
 ui._place(panel,Rect2(315,125,970,650),overlay)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",24);panel.add_child(row)
 var art=TextureRect.new();art.name="ShopPaymentPerformanceArt";art.texture=PAYMENT_ART[method]
 art.custom_minimum_size=Vector2(500,600);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(art)
 var copy=VBoxContainer.new();copy.add_theme_constant_override("separation",18);copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(copy)
 var title=ui._label(scene.get("title","付款"),27,ui.GOLD);title.name="ShopPaymentPerformanceTitle";copy.add_child(title)
 copy.add_child(HSeparator.new())
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;copy.add_child(scroll)
 var text=ui._label(scene.get("text",""),17,ui.TEXT);text.name="ShopPaymentPerformanceText"
 text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(text)
 var id=str(scene.id)
 var close=ui._button(scene.get("button","收下商品"),func():ui.shop_performance_seen=id;ui.render(ui.view),ui.CYAN)
 close.name="ShopPaymentContinue";copy.add_child(close)
