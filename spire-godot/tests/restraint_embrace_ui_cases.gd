extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=10
 var card=Cards.give(ui.game,"restraint_embrace")
 ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="uncommon" and t.visible_text(face).contains("每挣脱1件拘束具，抽1张牌，恢复1能量。") and t.visible_text(face).contains("抽牌与回能均可叠加。") and Queries.find(ui.view,"card",{"uid":card.uid,"free":true}).cost==2,"EMBRACE UI free face explains stackable draws and energy at two energy")
 await Click.click_card(t,card.uid);await t.frames()
 t.check(ui.game.state.energy==8 and ui.game.state.powers.size()==1,"EMBRACE UI clicking free face activates for this battle")
 card=Cards.give(ui.game,"restraint_embrace");ui.render();await t.frames()
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("每被佩戴1件拘束具，下回合抽1张牌。") and Queries.find(ui.view,"card",{"uid":card.uid,"free":false}).cost==1,"EMBRACE UI bound face explains next-turn draw at one energy")
 await Click.click_card(t,card.uid);await t.frames()
 ui.game.add_fixture("wrist",4);ui.game.add_fixture("ankle",4)
 ui.render();await t.frames()
 var status=ui.view.statuses.filter(func(row):return row.id=="power_restraint_embrace_bound")[0]
 t.check(status.badge=="2" and status.value=="下回合抽牌＋2" and status.duration=="本场整备结束" and status.card_type=="restraint_embrace","EMBRACE UI icon carries pending count and persistent duration")
 await preload("res://tests/target_sidebar_ui_cases.gd").press(t,ui.find_child("OpenPowers",true,false));await t.frames()
 var grid=ui.find_child("DeckGrid",true,false)
 t.check(grid.get_child_count()==2 and t.visible_text(grid).contains("每被佩戴1件拘束具") and not t.visible_text(grid).contains("下回合抽牌＋2"),"EMBRACE UI ability cards retain fixed text; pending count is only on status")
 await t.capture("ui-restraint-embrace.png")
 await t.close_information()
 t.check(await t.click("end") and ui.game.state.powers.size()==2 and ui.game.Cards.pending_draw(ui.game,"restraint_embrace_bound")==0,"EMBRACE UI next-turn draws do not consume the ability")
