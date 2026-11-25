extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")
static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=10
 var card=Cards.give(ui.game,"practiced");ui.render();await t.frames()
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="rare" and t.visible_text(face).contains("75%") and t.visible_text(face).contains("牵扯") and t.visible_text(face).contains("唯一") and face.ILLUSTRATIONS.has("practiced"),"PRACTICED UI rare bound face displays floor, traction, unique and own icon")
 await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("每成功打出1张其他牌，本回合的施法成功率提高8%"),"PRACTICED UI flips to per-card bonus and turn reset")
 await t.capture("ui-practiced-card.png")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.game.state.powers.size()==1 and ui.game.state.powers[0].power_face=="free","PRACTICED UI activates free power through actual click")
 var other=Cards.give(ui.game,"strain");ui.card_faces[other.uid]=true;ui.render();await t.frames()
 await preload("res://tests/curse_ui_cases.gd").click_card(t,other.uid)
 t.check(ui.game.Cards.progress_text(ui.game,"practiced_free")=="本回合＋8%" and ui.game.cast_view().formula.contains("额外加成"),"PRACTICED UI progress and spell formula use committed card counter")
 await t.capture("ui-practiced-power.png")
