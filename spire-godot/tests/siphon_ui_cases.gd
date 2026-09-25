extends RefCounted
const Give=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.mana=40
 var card=Give.give(ui.game,"siphon");ui.card_faces[card.uid]=false
 ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(t.visible_text(face).contains("汲取") and face.rarity=="uncommon" and t.visible_text(face.get_node("CardMana/Mana_gain")).strip_edges()=="+5" and Queries.find(ui.view,"card",{"uid":card.uid,"free":false}).cost==0,"SIPHON UI bound face displays name rarity zero energy and five mana")
 var before=ui.game.export_snapshot();await t.flip(card.uid)
 face=ui.card_buttons[card.uid]
 var row=ui.view.hand.filter(func(x):return x.uid==card.uid)[0]
 t.check(ui.game.state==before and row.cast_faces.free and not row.cast_faces.bound and row.face_requirements.free.any(func(text):return text.contains("腿部") and text.contains("0")),"SIPHON UI flip shows free-only chant and leg requirement without changing state")
 t.check(t.visible_text(face).contains("抽牌2") and t.visible_text(face.get_node("CardMana/Mana_gain")).strip_edges()=="+10" and Queries.find(ui.view,"card",{"uid":card.uid,"free":true}).cost==1,"SIPHON UI free face shows one energy ten mana and draw two")
 await t.capture("ui-siphon.png")
 await Click.click_card(t,card.uid);await t.frames()
 t.check(ui.game.state.mana==50 and ui.game.state.energy==2 and ui.game.state.hand.size()==before.hand.size()+1,"SIPHON UI real click applies free-face recovery and two-card draw")
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.add_fixture("ankle",4)
 card=Give.give(ui.game,"siphon");ui.render();await t.frames();await t.flip(card.uid)
 row=ui.view.hand.filter(func(x):return x.uid==card.uid)[0]
 t.check(not row.availability.free.usable and row.availability.bound.usable,"SIPHON UI restricts only free face when legs are restrained")
 ui.restart(42);await t.frames()
 ui.game._start_rest();ui.game._begin_rest();ui.game._discard_end();ui.game.state.mana=40
 card=Give.give(ui.game,"siphon");ui.render();await t.frames();await t.flip(card.uid)
 face=ui.card_buttons[card.uid];before=ui.game.export_snapshot()
 row=ui.view.hand.filter(func(x):return x.uid==card.uid)[0]
 t.check(not row.availability.free.usable and row.availability.free.dim and t.visible_text(face).contains("休息房禁止卡牌自由效果"),"SIPHON UI rest free face shows the actual prohibition on the card")
 await t.capture("ui-siphon-rest-blocked.png")
 await Click.click_card(t,card.uid);await t.frames()
 t.check(ui.game.export_snapshot()==before,"SIPHON UI forbidden free-face click cannot heal, draw, spend or cast")
 await t.flip(card.uid);await Click.click_card(t,card.uid);await t.frames()
 t.check(ui.game.state.mana==45 and ui.game.state.energy==before.energy,"SIPHON UI rest bound face remains normally playable")
