extends RefCounted
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")
const Interaction=preload("res://tests/card_interaction_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 await t.start_practice("Practice_rest")
 t.check(ui.view.practice and ui.view.practice_kind=="rest" and ui.view.phase=="rest_choice","CAMPFIRE UI practice button opens the real campfire chooser")
 var before=ui.game.export_snapshot()
 await Pointer.press(t,ui.find_child("Reward_enchant_enchant",true,false))
 t.check(ui.find_child("EnchantmentScreen",true,false)!=null and ui.game.state==before,"ENCHANT UI opens without mutation")
 var offers=ui.view.reward_panel.enchantments.offers
 t.check(offers.size()==3 and offers.all(func(offer):return ui.find_child("EnchantmentOffer_"+offer.id,true,false)!=null),"ENCHANT UI exposes all three frozen offers")
 for offer in offers:
  var button=ui.find_child("EnchantmentOffer_"+offer.id,true,false)
  t.check(ui.get_viewport_rect().encloses(button.get_global_rect()) and t.visible_text(button).contains(str(offer.turns)+"回合"),"ENCHANT UI offer fits and shows actual turn cost")
 await t.capture("ui-enchantment-offers.png")
 var offer=offers.filter(func(entry):return entry.rarity=="common")[0]
 await Pointer.press(t,ui.find_child("EnchantmentOffer_"+offer.id,true,false))
 var card=offer.cards[0]
 t.check(ui.find_child("EnchantmentCard_"+card.uid,true,false)!=null and ui.game.state==before,"ENCHANT UI offers eligible physical cards without payment")
 await Pointer.press(t,ui.find_child("EnchantmentBack",true,false))
 t.check(ui.game.state==before and ui.selected_enchantment=="","ENCHANT UI back keeps resources and offers")
 await Pointer.press(t,ui.find_child("EnchantmentRefresh_self",true,false))
 t.check(ui.game.state.mana==before.mana-10 and ui.game.state.rest_left==6 and ui.game.room_data("rest").enchantments.refreshes==1,"ENCHANT UI refresh submits one own-mana payment and retains screen")
 t.check(ui.find_child("EnchantmentScreen",true,false)!=null,"ENCHANT UI refresh stays in chooser")
 offer=ui.view.reward_panel.enchantments.offers.filter(func(entry):return entry.rarity=="common")[0]
 await Pointer.press(t,ui.find_child("EnchantmentOffer_"+offer.id,true,false))
 card=offer.cards[0]
 await Pointer.press(t,ui.find_child("EnchantmentCard_"+card.uid,true,false))
 t.check(ui.game.Cards.instance(ui.game,card.uid).enchantment==offer.id and ui.game.state.rest_left==4,"ENCHANT UI chosen physical card commits selected affix")
 t.check(ui.find_child("EnchantmentScreen",true,false)==null and ui.find_child("Reward_enchant_enchant",true,false).disabled,"ENCHANT UI completion returns to campfire and disables used service")
 t.check(await t.click("rest_flask") and ui.game.state.rest_left==1,"ENCHANT UI ordinary service can follow enchantment")
 await Pointer.press(t,ui.find_child("RewardContinue",true,false))
 t.check(ui.game.state.phase=="rest" and ui.game.state.rest_left==1,"ENCHANT UI continue starts remaining rest")
 t.check(await t.click("finish_rest") and ui.game.state.phase=="cleared","CAMPFIRE UI ending rest completes the practice")
 await card_keywords(t)
 ui.restart(42);await t.frames()

static func card_keywords(t) -> void:
 var ui=t.ui
 var Cases=preload("res://tests/enchantment_cases.gd")
 for entry in [["strain","nimble","灵动"],["strain","powerful","强力"],["strain","recycle2","回收2"],["pot_of_greed","exhaust","消耗2"]]:
  ui.restart(42);ui.game._discard_end();ui.game.state.energy=30;ui.game.state.relics=[]
  var card=Cases.give(ui.game,entry[0],entry[1])
  ui.render();await t.frames()
  t.check(t.visible_text(ui.card_buttons[card.uid]).contains(entry[2]),"ENCHANT UI real hand renders affix "+entry[1])
  await t.flip(card.uid)
  t.check(t.visible_text(ui.card_buttons[card.uid]).contains(entry[2]),"ENCHANT UI flip retains shared affix "+entry[1])
  if entry[1]=="exhaust":
   await t.create_timer(0.35).timeout;await t.move_mouse(Vector2(80,80));await t.frames()
   await t.capture("ui-enchantment-exhaust2.png")
   await Interaction.start(t,card.uid);await t.release_target()
   t.check(ui.game.Cards.instance(ui.game,card.uid).enchant_used==1,"ENCHANT UI actual card play spends shared first use")
   var current=ui.game.Cards.instance(ui.game,card.uid)
   ui.game.state.discard.erase(current);ui.game._put_card_in_hand(current);ui.render();await t.frames()
   t.check(t.visible_text(ui.card_buttons[card.uid]).contains("消耗") and not t.visible_text(ui.card_buttons[card.uid]).contains("消耗2"),"ENCHANT UI first use updates actual hand from exhaust two to exhaust")
  elif entry[1]=="recycle2":
   var current=ui.game.Cards.instance(ui.game,card.uid);current.enchant_used=2;ui.render();await t.frames()
   t.check(not t.visible_text(ui.card_buttons[card.uid]).contains("回收"),"ENCHANT UI spent recycle disappears from actual card")
