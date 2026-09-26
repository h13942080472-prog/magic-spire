extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._discard_end()
 var card=Cards.give(ui.game,"endless_war_goddess")
 ui.game.state.mana=35;ui.game.state.temporary_mana=15
 ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="rare" and t.visible_text(face).contains("无尽魔法少女战神") and face.get_node("CardIllustration").texture!=null,"WAR GODDESS UI shows rare card and configured illustration")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
 t.check(ui.view.mana==0 and ui.view.temporary_mana==0 and ui.view.energy==0 and ui.view.powers.any(func(v):return v.uid==card.uid) and ui.view.speech.text=="无尽战神,出来!","WAR GODDESS UI real card click spends all mana and presents dedicated line")
 preload("res://tests/endless_war_goddess_cases.gd").restrain(ui.game)
 ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 var choices=Queries.select(ui.view,"attack",{"type":"kick","enemy":ui.selected_enemy})
 t.check(not choices.is_empty(),"WAR GODDESS UI has kick facts to cycle")
 if choices.is_empty(): return
 for choice in choices:
  var form=choice.payload.form
  var button=ui.find_child("BasicAttack_kick",true,false)
  t.check(not button.disabled and button.drag_payload.form==form and t.visible_text(button).contains(choice.label),"WAR GODDESS UI each kick form uses its real available candidate")
  var point=button.get_global_rect().get_center()
  await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(ui.attack_forms.kick==choices[0].payload.form and ui.game.export_snapshot()==before,"WAR GODDESS UI complete candidate cycle is read only")
 t.check(not ui.find_child("BasicAttack_fireball",true,false).disabled and Queries.find(ui.view,"attack",{"type":"fireball","enemy":ui.selected_enemy}).casting.chance==1,"WAR GODDESS UI fireball stays usable with mouth restraint and high pressure")
 ui.attack_forms.kick=choices[-1].payload.form
 ui.game._finish_battle();ui.game.RelicEffects.end_combat(ui.game);ui.game._start_battle()
 ui.render();await t.frames()
 t.check(ui.attack_forms.kick==0 and ui.find_child("BasicAttack_kick",true,false)!=null,"WAR GODDESS UI expired extra form resets to an available form next battle")
