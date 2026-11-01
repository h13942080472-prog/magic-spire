extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")

static func click_card(t, uid: String) -> void:
 await t.close_information()
 await t.move_mouse(t.card_point(uid))
 var point=t.card_point(uid)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42)
 ui.game.state.phase="prepare";ui.game.state.prepare_left=3;ui.game.state.wall="normal"
 # Keep a small fixture hand so both cards are directly visible and clickable.
 ui.game._discard_end()
 var panic=Cards.give(ui.game,"panic").uid;var sensitive=Cards.give(ui.game,"sensitive").uid
 ui.render();await t.frames()
 t.check(ui.view.hand.size()==2 and ui.view.hand[0].cost=="1" and ui.view.hand[1].cost=="—","CURSE UI cost and unplayable cost mark")
 var text=t.visible_text(ui.card_buttons[sensitive])
 t.check(text.contains("保留") and text.contains("被动牌") and text.contains("1.2"),"CURSE UI sensitive complete card text")
 await t.capture("ui-curse-cards.png")
 var before=ui.game.export_snapshot()
 await t.flip(sensitive)
 t.check(not ui.card_buttons[sensitive].free_face and ui.game.export_snapshot()==before,"CURSE UI single-faced curse does not offer free-face bypass")
 await click_card(t,sensitive)
 t.check(ui.game.export_snapshot()==before and not ui.show_body and not ui.player_pick,"CURSE UI unplayable click opens no equipment picker and spends nothing")
 await click_card(t,panic)
 t.check(ui.view.energy==2 and ui.game.state.exhaust.any(func(c):return c.uid==panic) and not ui.player_pick,"CURSE UI direct click pays once and exhausts without choosing a body target")
 t.check(ui.view.hand.size()==1 and ui.view.hand[0].uid==sensitive,"CURSE UI sensitive remains in hand")
 panic=Cards.give(ui.game,"panic").uid;ui.game.state.energy=0
 ui.render();await t.frames();before=ui.game.export_snapshot()
 t.check(t.visible_text(ui.card_buttons[panic]).contains("能量"),"CURSE UI insufficient energy shown on card")
 await click_card(t,panic)
 t.check(ui.game.export_snapshot()==before,"CURSE UI unavailable click cannot consume card")
 ui.game.state.energy=3;ui.render();await t.frames()
 await t.move_mouse(t.card_point(panic));var point=t.card_point(panic)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 t.check(t.root.gui_is_dragging(),"CURSE UI native targetless card drag starts")
 point=ui.actor_targets.hero.get_global_rect().get_center()
 await t.move_mouse(point,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.view.energy==2 and ui.game.state.exhaust.any(func(c):return c.uid==panic) and not ui.player_pick,"CURSE UI native player drop directly commits same card candidate")
