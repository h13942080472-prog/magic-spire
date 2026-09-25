extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.pressure=50
 var card=Cards.give(ui.game,"forced_edging");ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.has_node("CardMana/Mana_pressure") and t.visible_text(face).contains("淫魔法"),"LEWD UI card uses heart and subtype")
 await t.flip(card.uid)
 face=ui.card_buttons[card.uid]
 t.check(face.has_node("CardMana/Mana_pressure") and face.has_node("CardMana/Mana_cost"),"LEWD UI mana-cost free spell keeps heart and blue mana badge")
 await t.capture("ui-lewd-card.png")
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.pressure=50
 card=Cards.give(ui.game,"forced_climax");ui.render();await t.frames()
 await Click.click_card(t,card.uid);await t.frames()
 t.check(not ui.view.card_chain.is_empty() and t.visible_text(ui.layout).contains("选择要消耗的牌"),"LEWD UI actual card click opens selection")
 await t.capture("ui-lewd-selection.png")
 for i in range(3):
  var choices=Queries.select(ui.view,"chain")
  if choices.is_empty():
   t.check(false,"LEWD UI pending selection must show formal choices")
   return
  t.check(await t.click("chain",{"selected_uid":choices[0].payload.selected_uid}),"LEWD UI real click selects a card from offered zone")
 t.check(ui.view.card_chain.is_empty() and ui.game.state.pressure==80 and ui.game.state.overload_total==1,"LEWD UI finishes selection into ordinary climax flow")
