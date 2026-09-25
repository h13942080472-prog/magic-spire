extends RefCounted
const Cases=preload("res://tests/universal_scanner_cases.gd")
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game=Cases.shop()
 t.check(ui.game!=null,"SCANNER UI seeded store contains relic")
 if ui.game==null: return
 ui.game.state.mana=100;ui.shop_payment="self"
 ui.game._gain_card("endless_war_goddess")
 for i in range(30): ui.game._gain_card("inch")
 ui.render();await t.frames()
 var offer=ui.view.shop.stock.filter(func(row):return row.type==Cases.TYPE)[0]
 var count=ui.game.state.deck.size()
 await Pointer.press(t,ui.find_child("ShopOffer%d" % offer.index,true,false))
 var payment=ui.find_child("ShopPaymentContinue",true,false)
 if payment!=null: await Pointer.press(t,payment)
 t.check(ui.view.reward_panel.get("selection","")=="card_copy" and ui.view.mana==30 and ui.game.state.deck.size()==count,"SCANNER UI paid pickup opens choice without granting a random card")
 var browser=ui.find_child("DeckBrowser",true,false)
 t.check(browser!=null and browser.cards.all(func(card):return card.type!="endless_war_goddess" and ui.game.Cards.Rules.SPECS[card.type].rarity!="basic"),"SCANNER UI excludes basics and double-unique power")
 var before=ui.game.export_snapshot()
 var search=browser.find_child("DeckSearch",true,false);search.text="一点点抽出";search.text_changed.emit(search.text);await t.frames()
 var button=browser.grid.get_child(0)
 var uid=button.get_meta("physical_uid")
 browser.scroll.ensure_control_visible(button);await t.frames()
 var point=button.get_global_rect().get_center()
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(ui.game.export_snapshot()==before and button.free_face,"SCANNER UI filtering and flipping remain read only")
 search.text="";search.text_changed.emit(search.text);await t.frames()
 t.check(browser.grid.get_child_count()==browser.cards.size() and Queries.select(ui.view,"reward").filter(func(c):return c.payload.get("op","")=="copy").all(func(c):return ui.candidate_buttons.has(c.key) and is_instance_valid(ui.candidate_buttons[c.key])),"SCANNER UI clearing filter restores every card and candidate button")
 button=browser.grid.get_child(browser.grid.get_child_count()-1)
 uid=button.get_meta("physical_uid")
 var selected_type=ui.game.state.deck.filter(func(card):return card.uid==uid)[0].type
 browser.scroll.ensure_control_visible(button);await t.frames()
 t.check(browser.scroll.scroll_vertical>0,"SCANNER UI can reach the final row of a long deck")
 await Pointer.press(t,button)
 t.check(ui.game.state.deck.size()==count+1 and ui.game.state.deck.back().type==selected_type and ui.game.state.deck.back().uid!=uid and ui.game.state.relic_bundle.is_empty() and ui.find_child("RelicBundleRewards",true,false)==null,"SCANNER UI actual card click creates one copy and returns to merchant")
 t.check(ui.view.mana==30 and ui.find_child("RelicShortcut_"+Cases.TYPE,true,false)!=null,"SCANNER UI retains pickup icon and does not charge for selection")
 ui.restart(42);ui.game=Cases.shop()
 for zone in ["deck"]+ui.game.Cards.ZONES: ui.game.state[zone]=[]
 ui.game._gain_card("endless_war_goddess");ui.game.RelicEffects.gain(ui.game,Cases.TYPE)
 ui.render();await t.frames()
 t.check(ui.find_child("DeckBrowser",true,false).cards.is_empty() and t.visible_text(ui.find_child("RelicBundleRewards",true,false)).contains("没有可复制"),"SCANNER UI explains an all-ineligible deck")
 await Pointer.press(t,ui.find_child("BundleContinue",true,false))
 t.check(ui.game.state.relic_bundle.is_empty() and ui.game.state.deck.size()==1,"SCANNER UI actual skip returns without copying an ineligible card")
 ui.restart(42);await t.frames()
