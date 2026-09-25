extends RefCounted
const Give=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 # A frozen boss reward fixture still claims through the real reward UI/command.
 preload("res://tests/boss_relic_cases.gd").boss_reward(ui.game)
 ui.game.state.boss_relic_options=["gourd_flask","binding_pyramid","shining_lamp"]
 ui.render();await t.frames()
 ui.find_child("Reward_relic",true,false).pressed.emit();await t.frames()
 var button=ui.find_child("BossRelicChoice_gourd_flask",true,false)
 t.check(button!=null and button.is_visible_in_tree() and t.visible_text(button).contains("般若汤-其一"),"HANNYA UI boss reward displays named gift and gourd art")
 await t.move_mouse(button.get_global_rect().get_center())
 await t.mouse_button(button.get_global_rect().get_center(),MOUSE_BUTTON_LEFT,true)
 await t.mouse_button(button.get_global_rect().get_center(),MOUSE_BUTTON_LEFT,false)
 await t.frames()
 t.check("gourd_flask" in ui.game.state.relics and ui.game.state.deck.any(func(c):return c.type=="hannya_1"),"HANNYA UI native boss claim adds permanent first stage")
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=12;ui.game.state.mana=30
 var card=Give.give(ui.game,"hannya_1");ui.card_faces[card.uid]=true
 ui.render();await t.frames()
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("固有") and ui.card_buttons[card.uid].get_node("CardIllustration").texture!=null,"HANNYA UI first stage shows innate and finished artwork")
 for free in [false,true]:
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var face=ui.card_buttons[card.uid]
  t.check(t.visible_text(face.get_node("CardMana/Mana_gain")).strip_edges()=="+5" and t.visible_text(face).contains("技能") and not t.visible_text(face).contains("魔法 ·"),"HANNYA UI both faces show plus five while remaining skills")
 await Click.click_card(t,card.uid);await t.frames()
 t.check(ui.game.Cards.Hannya.level(ui.game)==1 and ui.find_child("StatusIcon_power_hannya_level_1",true,false)!=null and ui.game.live_card_text("hannya_2").face_costs.free=="1","HANNYA UI actual click upgrades and shows level badge")
 card=ui.game.state.discard.filter(func(c):return c.type=="hannya_2")[0]
 ui.game.state.discard.erase(card);ui.game.state.hand.append(card);ui.card_faces[card.uid]=false
 ui.render();await t.frames();await Click.click_card(t,card.uid);await t.frames()
 var gift=ui.game.state.hand.filter(func(c):return c.type=="hannya_swallow")
 t.check(gift.size()==1 and t.visible_text(ui.card_buttons[gift[0].uid]).contains("虚无") and ui.game.live_card_text("hannya_swallow").face_costs.free=="0","HANNYA UI second stage visibly adds zero-cost ethereal gift")
 var lower=Give.give(ui.game,"hannya_1");ui.render();await t.frames()
 var lower_text=t.visible_text(ui.card_buttons[lower.uid])
 t.check(lower_text.contains("仅将一张") and lower_text.contains("好汤喝够") and not lower_text.contains("力量＋1"),"HANNYA UI physical lower-stage card shows actual soup-only outcome")
 t.check(not ui.card_buttons[lower.uid].get_node("CardMana").visible,"HANNYA UI lower-level soup-only play does not promise a mana gain")
 var infused=Give.give(ui.game,"hannya_infusion");ui.render();await t.frames()
 for free in [false,true]:
  if ui.card_faces.get(infused.uid,false)!=free: await t.flip(infused.uid)
  t.check(t.visible_text(ui.card_buttons[infused.uid].get_node("CardMana/Mana_cost")).strip_edges()=="−10","HANNYA UI generated infusion shows minus ten on both faces")
 var soup=Give.give(ui.game,"good_soup")
 var mouth=ui.game._install_template("mouth_band","mouth",20,30,false,"fixture",2,0)
 ui.render();await t.frames()
 t.check(ui.card_buttons[soup.uid].get_node("CardCost").text=="2" and Queries.find(ui.view,"card",{"uid":soup.uid,"free":false}).cost==2,"HANNYA UI mouth penalty changes displayed and paid energy together")
 mouth.grade=3;mouth.durability=20;ui.render();await t.frames()
 t.check(ui.card_buttons[soup.uid].get_node("CardCost").text=="3","HANNYA UI score five displays three energy")
 mouth.durability=30;ui.render();await t.frames()
 t.check(not Queries.find(ui.view,"card",{"uid":soup.uid,"free":false}).valid and ui.view.hand.filter(func(c):return c.uid==soup.uid)[0].availability.bound.text.contains("无法饮用"),"HANNYA UI complete mouth blockage exposes specific reason")
 ui.game.state.equipment.clear();ui.game._finish_battle();ui.render();await t.frames()
 t.check(await t.click("reward",{"type":"skip"}) and ui.game.Cards.Hannya.level(ui.game)==2,"HANNYA UI rewards preserve level into preparation")
 t.check(await t.click("finish_prepare") and ui.game.Cards.Hannya.level(ui.game)==0 and not ui.game.state.deck.any(func(c):return c.type=="hannya_swallow"),"HANNYA UI preparation exit removes temporary gift and level")
