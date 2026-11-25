extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 for free in [false,true]:
  ui.restart(42);ui.game._discard_end();ui.game.state.mana=35
  if free: ui.game._install_template("restriction_collar","neck",1,1,true,"fixture",3)
  var card=Cards.give(ui.game,"sympathetic_form");ui.render();await t.frames()
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var face=ui.card_buttons[card.uid]
  t.check(face.rarity=="rare" and face.get_node("CardCost").text=="3" and face.get_node("CardIllustration").texture!=null and t.visible_text(face).contains("交感形态"),"SYMPATHETIC UI rare card cost and dedicated illustration")
  t.check(t.visible_text(face).contains("回合结束时，若未佩戴拘束具" if free else "获得2层魔力预备和" + preload("res://ui/card_energy_text.gd").ICON),"SYMPATHETIC UI selected face describes the registered turn trigger")
  if free: t.check(t.visible_text(face).contains("力量＋1、灵巧＋1、火球术伤害＋2"),"SYMPATHETIC UI free face displays all three combat gains")
  await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
  t.check(ui.view.energy==0 and ui.view.mana==35 and ui.view.temporary_mana==0 and ui.view.powers.any(func(v):return v.uid==card.uid),"SYMPATHETIC UI real click activates power without immediate resource grant")
  for enemy in ui.game.state.enemies: enemy.intent.delayed=true
  ui.render();await t.frames()
  t.check(await t.click("end"),"SYMPATHETIC UI end turn uses original command")
  t.check(ui.view.mana==55 if free else ui.view.temporary_mana==10 and ui.view.energy==4,"SYMPATHETIC UI next turn projects actual mana or temporary mana and energy")
