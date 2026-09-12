extends RefCounted
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")
const Cases=preload("res://tests/service_cases.gd")
const ShopCopy=preload("res://data/shop_copy.gd")

static func run(t) -> void:
 await m_donalds(t)
 await t.start_practice("Practice_shop")
 var shop_view=t.ui.view
 var portrait=t.ui.find_child("ShopkeeperPortrait",true,false)
 t.check(shop_view.phase=="shop" and shop_view.practice and shop_view.shop.stock.size()==12,"SHOP practice entry opens the real twelve-slot store")
 t.check(portrait!=null and portrait.texture.resource_path=="res://assets/characters/shopkeeper.png" and portrait.size.x>=330,"SHOP uses supplied merchant portrait with enlarged visual column")
 t.check(t.ui.find_child("BodyEquipmentPanel",true,false)==null and t.ui.find_child("MainMana",true,false)==null and t.ui.find_child("ManaFlask",true,false).position.y<150,"SHOP merchant is unobstructed and flask stays available in header")
 await t.capture("ui-shopkeeper-new.png")
 await shop_presentation(t)
 var practice_offer=t.ui.actions.select("service").filter(func(c):return c.payload.get("op","")=="take" and c.payload.get("payment","")=="self" and c.valid)[0]
 var practice_mana=t.ui.game.state.mana
 await Pointer.press(t,t.ui.candidate_buttons[practice_offer.id])
 t.check(t.ui.game.state.mana<practice_mana and t.ui.view.shop.stock[practice_offer.payload.index].taken,"SHOP test entry purchases via formal stock and payment")
 var performance=t.ui.find_child("ShopPaymentPerformance",true,false)
 t.check(performance!=null and t.ui.view.shop.performance.method=="self" and t.ui.find_child("ShopPaymentPerformanceArt",true,false).texture.resource_path=="res://assets/art/shop-payment-self-v1.png","SHOP free upper body opens the supplied self-payment performance")
 var after_purchase=t.ui.game.export_snapshot()
 await Pointer.press(t,t.ui.find_child("ShopPaymentContinue",true,false))
 t.check(t.ui.find_child("ShopPaymentPerformance",true,false)==null and t.ui.game.export_snapshot()==after_purchase,"SHOP performance confirmation only closes the presentation")
 t.check(await t.click("service",{"op":"leave"}) and t.ui.view.phase=="cleared","SHOP test entry leaves via normal service candidate")
 var ui=t.ui
 ui.restart(42);await t.frames()
 t.check(await t.click("departure",{"op":"skip"}),"SERVICE UI completes the opening choice through its real button")
 t.check(ui.view.phase=="map" and ui.view.enemies.is_empty(),"SERVICE UI real random opening displays map")
 var graph=ui.find_child("TowerRoute",true,false)
 t.check(graph!=null and ui.view.route.any(func(r):return r.icon=="shop") and ui.view.route.any(func(r):return r.icon=="treasure"),"SERVICE UI shop and treasure appear on genuine map")
 ui.map_overview=true;ui.render();await t.frames()
 await t.capture("ui-96-random-tower.png")
 for kind in ["shop","treasure"]:
  ui.restart(42)
  ui.game.RelicEffects.gain(ui.game,"flyer")
  Cases.arrive(ui.game,kind)
  ui.render();await t.frames()
  var id=ui.game.room_data(ui.game.state.room).next.filter(func(next):return ui.game.room_data(next).kind==kind)[0]
  t.check(await t.click("depart",{"room":id}),"SERVICE UI actual adjacent departure")
  while ui.view.phase=="travel":t.check(await t.click("travel_step"),"SERVICE UI travel enters service room")
  t.check(ui.find_child("RoomServicePanel" if kind=="shop" else "BattleRewards",true,false)!=null and ui.view.phase==kind,"SERVICE UI shop keeps its panel and treasure uses common rewards")
  t.check(ui.game.state.flask_mana==(20 if kind=="shop" else 0),"FLYER UI real arrival credits only shop")
  var flyer=ui.view.relics.filter(func(row):return row.id=="flyer")[0]
  t.check(flyer.rarity_name=="普通" and flyer.detail.contains("魔瓶补充20") and ui.find_child("RelicShortcut_flyer",true,false)!=null,"FLYER UI shared icon and ordinary description")
  if kind=="shop":
   check_stock_layout(t)
   var before_log=ui.game.export_snapshot()
   await Pointer.press(t,ui.find_child("OpenActionLog",true,false));await t.frames()
   t.check(ui.show_log and ui.game.state==before_log,"SHOP UI log uses read-only drawer without covering stock by default")
   await t.close_information()
   var card_offer=ui.view.shop.stock.filter(func(o):return o.kind=="card")[0]
   var face=ui.find_child("ShopOffer%d" % card_offer.index,true,false)
   t.check(face.get_script()==preload("res://ui/elements/card_face.gd") and face.drag_payload.is_empty(),"SHOP uses hand face without gameplay drag")
   var relic_offer=ui.view.shop.stock.filter(func(o):return o.kind=="relic")[0]
   var relic_button=ui.find_child("ShopOffer%d" % relic_offer.index,true,false)
   t.check(t.visible_text(relic_button).contains(relic_offer.rarity_name) and relic_offer.detail.begins_with(relic_offer.rarity_name+"遗物"),"RELIC shop displays rarity in both stock and details")
  var offer=ui.actions.select("service")[0]
  var stock=ui.view.shop.stock[offer.payload.index]
  var pickup=ui.game.Relics.TYPES[stock.type].modifiers.get("pickup_mana",0.0) if stock.kind=="relic" else 0.0
  var button=ui.candidate_buttons[offer.id]
  await Pointer.press(t,button)
  t.check(ui.view.mana==100-offer.mana+pickup and not ui.candidate_buttons.has(offer.id),"SERVICE UI native purchase spends exact mana and removes offer")
  if kind=="shop": await dismiss_payment(t)
  await t.capture("ui-97-"+kind+".png")
  t.check(await t.click("service",{"op":"leave"}) and ui.view.phase=="map","SERVICE UI leaves without extra turns")
 await release_service(t)
 await payment_dialogues(t)
 ui.restart(42,true,"equipment");await t.frames()
 await t.inspect_body("wrist")
 var text=t.visible_text(ui.find_child("EquipmentDetails",true,false))
 t.check(text.contains("耐久 4 / 10") and text.contains("紧度 1档"),"BODY UI equipment keeps explicit basic labels")
 var single=ui.view.bodies.filter(func(body):return body.id=="wrist")[0].equipment[0].id
 var blocked=ui.actions.find("manual",{"target":single})
 t.check(not blocked.valid and text.contains(blocked.reason) and ui.candidate_buttons[blocked.id].disabled,"BODY UI single equipment opens its unavailable action and exact reason")
 # A free-handed legal target exposes the same formal command.
 ui.restart(42,true,"equipment")
 ui.game.state.equipment=[];ui.game.add_fixture("thigh",4)
 ui.render();await t.frames();await t.inspect_body("thigh")
 var target=ui.view.bodies.filter(func(b):return b.id=="thigh")[0].equipment[0].id
 var c=ui.actions.find("manual",{"target":target})
 t.check(c.valid and ui.candidate_buttons.has(c.id),"BODY UI eligible manual command stays visible")
 await Pointer.press(t,ui.find_child("EquipmentCardDetailsToggle",true,false))
 await Pointer.press(t,ui.candidate_buttons[c.id])
 t.check(ui.game._equipment(target).is_empty() and ui.view.energy==2,"BODY UI visible quick release pays and removes actual target")

static func dismiss_payment(t) -> void:
 var button=t.ui.find_child("ShopPaymentContinue",true,false)
 if button!=null: await Pointer.press(t,button)

static func payment_dialogues(t) -> void:
 var ui=t.ui
 ui.restart(42,true,"shop");ui.game.state.flask_mana=500;ui.render();await t.frames()
 await Pointer.press(t,ui.find_child("ShopPayment_flask",true,false))
 var offer=ui.actions.select("service").filter(func(c):return c.payload.get("op","")=="take" and c.payload.get("payment","")=="flask" and c.valid)[0]
 await Pointer.press(t,ui.candidate_buttons[offer.id])
 var body=ui.find_child("ShopkeeperSpeechText",true,false)
 t.check(ui.find_child("ShopPaymentPerformance",true,false)==null and ui.speech_group.visible and body.text==ShopCopy.FLASK_PAYMENT,"SHOP flask payment stays in the ordinary merchant dialogue bubble")
 ui.restart(42,true,"shop");await t.frames()
 var browse=ui.actions.select("service").filter(func(c):return c.payload.get("op","")=="take" and c.payload.get("payment","")=="self" and c.valid)[0]
 var before=ui.game.export_snapshot();ui.candidate_buttons[browse.id].mouse_entered.emit()
 t.check(ShopCopy.BROWSE.has(ui.find_child("ShopkeeperSpeechText",true,false).text) and ui.game.export_snapshot()==before,"SHOP hovering an affordable product plays read-only random browsing dialogue")
 ui.game.state.mana=0;ui.render();await t.frames()
 var poor=ui.actions.select("service").filter(func(c):return c.payload.get("op","")=="take" and c.payload.get("payment","")=="self")[0]
 before=ui.game.export_snapshot();ui.candidate_buttons[poor.id].mouse_entered.emit()
 t.check(ShopCopy.INSUFFICIENT_SELF_FREE.has(ui.find_child("ShopkeeperSpeechText",true,false).text) and ui.game.export_snapshot()==before,"SHOP insufficient self payment has free-upper-body dialogue without changing state")
 ui.game.add_fixture("wrist",4);ui.render();await t.frames()
 poor=ui.actions.select("service").filter(func(c):return c.payload.get("op","")=="take" and c.payload.get("payment","")=="self")[0]
 before=ui.game.export_snapshot();ui.candidate_buttons[poor.id].mouse_entered.emit()
 t.check(ShopCopy.INSUFFICIENT_SELF_BOUND.has(ui.find_child("ShopkeeperSpeechText",true,false).text) and ui.game.export_snapshot()==before,"SHOP insufficient self payment has restrained-upper-body dialogue without changing state")
 await Pointer.press(t,ui.find_child("ShopPayment_flask",true,false))
 var flask_poor=ui.actions.select("service").filter(func(c):return c.payload.get("op","")=="take" and c.payload.get("payment","")=="flask")[0]
 before=ui.game.export_snapshot();ui.candidate_buttons[flask_poor.id].mouse_entered.emit()
 t.check(ShopCopy.INSUFFICIENT_FLASK.has(ui.find_child("ShopkeeperSpeechText",true,false).text) and ui.game.export_snapshot()==before,"SHOP insufficient flask payment has its own ordinary merchant dialogue without changing state")
 ui.restart(42,true,"shop");await t.frames()
 var lock=ui.game._install_special("negative_plate_lock_medium","special_2_a",2);ui.render();await t.frames()
 var plate_offer=ui.actions.select("service").filter(func(c):return c.payload.get("op","")=="take" and c.payload.get("payment","")=="self")[0]
 before=ui.game.export_snapshot();ui.candidate_buttons[plate_offer.id].mouse_entered.emit()
 body=ui.find_child("ShopkeeperSpeechText",true,false)
 t.check(not plate_offer.valid and ui.candidate_buttons[plate_offer.id].disabled and body.text==ShopCopy.PLATE_SELF_BROWSE[0] and t.visible_text(ui.candidate_buttons[plate_offer.id].get_parent()).contains(ShopCopy.PLATE_SELF_BLOCK_REASON) and ui.game.export_snapshot()==before,"SHOP flat-lock product hover shows the dedicated zako refusal without mutating state")
 await Pointer.press(t,ui.find_child("ShopRelease",true,false))
 var release=ui.actions.find("service_release",{"op":"release","target":lock.id,"payment":"self"})
 await Pointer.press(t,ui.candidate_buttons[release.id])
 var scene=ui.view.shop.performance
 t.check(scene.method=="self" and ui.find_child("ShopPaymentPerformanceArt",true,false).texture.resource_path=="res://assets/art/shop-payment-self-v1.png" and ui.find_child("ShopPaymentPerformanceText",true,false).text==ShopCopy.PLATE_RELEASE_PERFORMANCES.self.text and ui.find_child("ShopPaymentContinue",true,false).text=="完成付款","SHOP flat-lock release keeps the supplied image and shows its dedicated payment copy")
 await dismiss_payment(t);await t.close_information()

static func release_service(t) -> void:
 var ui=t.ui
 ui.restart(42)
 ui.game=preload("res://tests/shop_release_cases.gd").shop()
 var root=ui.game._install_assembly("glove","long","fixture",2,2,{},"cross")
 root.components[1].locked=true
 var kept=ui.game.add_fixture("ankle",8)
 ui.render();await t.frames()
 var snapshot=ui.game.export_snapshot()
 await Pointer.press(t,ui.find_child("ShopRelease",true,false))
 t.check(ui.show_shop_service and ui.game.export_snapshot()==snapshot,"SHOP UI opening service consumes nothing")
 var panel=ui.find_child("InformationDrawer",true,false)
 var text=t.visible_text(panel)
 t.check(text.contains("复合处理15") and text.contains("开锁10") and text.contains("45魔力"),"SHOP UI displays complete quote and additive surcharges")
 await t.capture("ui-shop-release.png")
 var c=ui.actions.find("service_release",{"op":"release","target":root.id})
 await Pointer.press(t,ui.candidate_buttons[c.id])
 t.check(ui.view.mana==55 and ui.game.state.composites.is_empty() and ui.game._equipment(kept.id)==kept,"SHOP UI native click removes whole locked composite and preserves independent equipment")
 t.check(not ui.view.shop.release_jobs.any(func(job):return job.id==root.id),"SHOP UI purchased target disappears from updated jobs")
 var scene=ui.view.shop.performance
 var art=ui.find_child("ShopPaymentPerformanceArt",true,false)
 t.check(scene.method in ["sleeve","hand","foot"] and art!=null and art.texture.resource_path=="res://assets/art/shop-payment-%s-v1.png" % scene.method,"SHOP restrained release opens the matching supplied assisted-payment art")
 await dismiss_payment(t)
 await t.close_information()
 var remove=ui.find_child("ShopRemove",true,false)
 await Pointer.press(t,remove)
 var card=ui.actions.select("service_remove")[0]
 var deck=ui.view.deck_count
 t.check(ui.candidate_buttons[card.id].get_script()==preload("res://ui/elements/card_face.gd"),"REMOVE service uses selectable hand card face")
 await Pointer.press(t,ui.candidate_buttons[card.id]);await dismiss_payment(t);await t.close_information()
 t.check(ui.view.deck_count==deck-1 and ui.find_child("ShopRemove",true,false).disabled,"SHOP UI original single-use card removal remains usable")
 ui.game.state.mana=19;ui.render();await t.frames()
 await Pointer.press(t,ui.find_child("ShopRelease",true,false))
 c=ui.actions.find("service_release",{"op":"release","target":kept.id})
 var low_before=ui.game.export_snapshot();ui.candidate_buttons[c.id].mouse_entered.emit()
 t.check(ShopCopy.INSUFFICIENT_SELF_FREE.has(ui.find_child("ShopkeeperSpeechText",true,false).text) and ui.game.export_snapshot()==low_before,"SHOP disabled release plays the matching insufficient-payment dialogue")
 t.check(not c.valid and ui.candidate_buttons[c.id].disabled and t.visible_text(ui.find_child("InformationDrawer",true,false)).contains(c.reason),"SHOP UI insufficient balance visibly explains disabled removal")
 await t.close_information()
 await t.capture("ui-shop-low-mana.png")
 ui.game.state.mana=20;ui.render();await t.frames()
 await Pointer.press(t,ui.find_child("ShopRelease",true,false))
 c=ui.actions.find("service_release",{"op":"release","target":kept.id})
 await Pointer.press(t,ui.candidate_buttons[c.id])
 await dismiss_payment(t)
 t.check(t.visible_text(ui.find_child("InformationDrawer",true,false)).contains("目前没有需要卸下"),"SHOP UI empty list after final removal")
 await t.close_information()
 var shop=ui.find_child("RoomServicePanel",true,false)
 var rect=shop.get_global_rect()
 t.check(rect.end.y<=ui.get_viewport_rect().size.y and rect.size.y>600,"SHOP UI shop stays inside desktop viewport")
 t.root.size=Vector2i(1280,720);await t.frames()
 check_stock_layout(t)
 await Pointer.press(t,ui.find_child("ShopRelease",true,false))
 t.check(ui.show_shop_service,"SHOP UI service remains clickable at 1280 by 720")
 await t.close_information()
 await t.capture("ui-shop-1280.png")
 t.root.size=Vector2i(1600,900);await t.frames()

static func check_stock_layout(t) -> void:
 var ui=t.ui
 var shop=ui.find_child("RoomServicePanel",true,false)
 var rectangles=[]
 t.check(ui.view.shop.stock.size()==12,"SHOP UI displays all twelve frozen offers")
 for offer in ui.view.shop.stock:
  var button=ui.find_child("ShopOffer%d" % offer.index,true,false)
  if offer.kind in ["card","relic"]:
   var rarity=ui.game.Cards.Rules.SPECS[offer.type].rarity if offer.kind=="card" else ui.game.Relics.TYPES[offer.type].rarity
   var prices=ui.game.Services.Data.CARD_PRICES if offer.kind=="card" else ui.game.Services.Data.RELIC_PRICES
   var price_nodes=button.get_parent().get_children() if offer.kind=="card" else button.get_children()
   t.check(offer.price==prices[rarity] and price_nodes.any(func(node):return node is Label and node.text==("售罄" if offer.taken else ui.game.number(offer.price)+" 魔力")),"SHOP UI printed price matches product rarity and frozen offer")
  var rect=button.get_global_rect()
  if offer.kind=="card":
   var price=ui.find_child("ShopPrice%d" % offer.index,true,false)
   var price_rect=price.get_global_rect()
   t.check(button.size.x==196 and price.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER and absf(price_rect.get_center().x-rect.get_center().x)<1 and price_rect.position.y>rect.end.y,"SHOP smaller card and price share a center with a clear vertical gap")
   t.check(price.position.y+price.size.y+button.get_parent().position.y<416,"SHOP price stays above the wooden shelf")
  t.check(button.is_visible_in_tree() and shop.get_global_rect().encloses(rect) and ui.get_viewport_rect().encloses(rect),"SHOP UI every product remains inside shop and viewport: "+str(offer.index))
  t.check(rectangles.all(func(other):return not other.intersects(rect)),"SHOP UI product hit areas never overlap: "+str(offer.index))
  rectangles.append(rect)

static func shop_presentation(t) -> void:
 var ui=t.ui
 var snapshot=ui.game.export_snapshot()
 var portrait=ui.find_child("ShopkeeperPortrait",true,false)
 var canopy=ui.find_child("ShopCanopy",true,false)
 t.check(canopy.get_index()>portrait.get_index() and canopy.foreground and canopy.mouse_filter==Control.MOUSE_FILTER_IGNORE,"SHOP canopy covers portrait without intercepting controls")
 var bubble=ui.find_child("ShopkeeperSpeech",true,false)
 var deadline=ui.speech_deadline
 t.check(bubble!=null and bubble.is_visible_in_tree() and deadline>Time.get_ticks_msec() and deadline<=Time.get_ticks_msec()+5000,"SHOP greeting starts with a five-second lifetime")
 await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_RIGHT,true);await t.mouse_button(Vector2(650,60),MOUSE_BUTTON_RIGHT,false)
 ui.render();await t.frames()
 t.check(ui.speech_group.is_visible_in_tree() and ui.speech_deadline==deadline,"SHOP right click and repaint preserve original greeting deadline")
 await t.create_timer(maxf(0.01,(deadline-Time.get_ticks_msec())/1000.0+0.1)).timeout
 t.check(not ui.speech_group.visible and ui.speech_deadline==0 and ui.game.export_snapshot()==snapshot,"SHOP greeting expires naturally without changing gameplay")
 await Pointer.press(t,ui.find_child("ShopSidebarToggle",true,false))
 t.check(ui.shop_sidebar_open and ui.find_child("BodyEquipmentPanel",true,false)!=null and ui.find_child("MainMana",true,false)!=null,"SHOP sidebar can expand to inspect body and resources")
 t.check(ui.find_children("ManaFlask","",true,false).size()==1 and ui.find_child("ManaFlask",true,false).position.y<150,"SHOP expanding sidebar keeps one functional flask in the header")
 check_stock_layout(t)
 t.root.size=Vector2i(1280,720);await t.frames()
 check_stock_layout(t)
 await t.capture("ui-shop-sidebar.png")
 await t.inspect_body("wrist")
 t.check(ui.find_child("EquipmentDetails",true,false)!=null,"SHOP expanded sidebar opens existing body details")
 await Pointer.press(t,ui.find_child("ShopSidebarToggle",true,false))
 t.check(not ui.shop_sidebar_open and ui.find_child("BodyEquipmentPanel",true,false)==null and ui.find_child("EquipmentDetails",true,false)==null,"SHOP edge toggle collapses sidebar and its open details")
 await Pointer.press(t,ui.find_child("ShopPayment_flask",true,false))
 t.check(ui.shop_payment=="flask" and not ui.find_child("ShopkeeperSpeech",true,false).visible and ui.game.export_snapshot()==snapshot,"SHOP sidebar and payment toggles cannot revive dismissed speech or alter game state")
 await Pointer.press(t,ui.find_child("ShopPayment_self",true,false))
 t.root.size=Vector2i(1600,900);await t.frames()

static func m_donalds(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game=Cases.m_donalds_shop()
 t.check(ui.game!=null,"M UI actual shop fixture contains the exclusive relic")
 if ui.game==null: return
 ui.game.state.mana=40;ui.game.state.flask_mana=65;ui.shop_payment="self";ui.render();await t.frames()
 var offer=ui.view.shop.stock.filter(func(row):return row.type=="m_donalds")[0]
 var button=ui.find_child("ShopOffer%d" % offer.index,true,false)
 t.check(button.disabled and t.visible_text(button).contains("仅可使用魔瓶购买") and t.visible_text(button).contains("65 魔瓶魔力") and t.visible_text(button).contains("罕见"),"M UI self selection displays exact restriction and bottle price on the product")
 await Pointer.press(t,ui.find_child("ShopPayment_flask",true,false))
 t.check(not ui.find_child("ShopOffer%d" % offer.index,true,false).disabled,"M UI switching to bottle enables the actual purchase button")
 await Pointer.press(t,ui.find_child("ShopOffer%d" % offer.index,true,false))
 t.check(ui.view.mana==110 and ui.view.mana_max==110 and ui.view.mana_flask.mana==0 and ui.find_child("RelicShortcut_m_donalds",true,false)!=null,"M UI purchase refreshes actual maximum, full mana, bottle and owned icon")
 t.check(ui.find_child("ShopOffer%d" % offer.index,true,false).disabled and t.visible_text(ui.find_child("ShopOffer%d" % offer.index,true,false)).contains("售罄"),"M UI purchased relic is visibly sold out")
 await t.capture("ui-m-donalds.png")
 ui.restart(42);await t.frames()
