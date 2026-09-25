extends RefCounted
const Give=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.game=preload("res://tests/mana_attachment_cases.gd").setup()
 ui._reset_interface(ui.game.get_view())
 var card=Give.give(ui.game,"mana_attachment")
 ui.card_faces[card.uid]=false;ui.render();await t.frames()
 await t.flip(card.uid)
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="uncommon" and face.ILLUSTRATIONS.has("mana_attachment") and face.get_node("CardCost").text=="1" and t.visible_text(face).contains("威力减半"),"ATTACHMENT UI new uncommon magic power shows cost, illustration and free effect")
 await Click.click_card(t,card.uid)
 var status_name="StatusIcon_power_mana_attachment_free"
 var button=ui.find_child(status_name,true,false)
 t.check(button!=null and ui.game.state.powers.size()==1 and ui.game.state.charge==1,"ATTACHMENT UI native play activates status and grants initial charge")
 if button==null: return
 var attack=Queries.find(ui.view,"attack",{"type":"strike"})
 t.check(attack.payload.all and attack.mana==10,"ATTACHMENT UI attack facts show paid AOE immediately")
 var point=button.get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 attack=Queries.find(ui.view,"attack",{"type":"strike"})
 t.check(not attack.payload.all and attack.mana==0 and ui.find_child(status_name,true,false)!=null and not ui.show_pressure,"ATTACHMENT UI right click disables without opening a drawer and retains icon")
 var mana=ui.game.state.mana
 button=ui.find_child(status_name,true,false);point=button.get_global_rect().get_center()
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(Queries.find(ui.view,"attack",{"type":"strike"}).payload.all and ui.game.state.mana==mana,"ATTACHMENT UI second right click resumes AOE without payment")
 card=Give.give(ui.game,"mana_attachment");ui.card_faces[card.uid]=false;ui.render();await t.frames()
 await Click.click_card(t,card.uid)
 t.check(ui.find_child("StatusIcon_power_mana_attachment_bound",true,false)!=null and ui.find_child(status_name,true,false)!=null,"ATTACHMENT UI both faces have independent status icons")
 await t.frames(90)
 await t.capture("ui-mana-attachment.png")
 card=Give.give(ui.game,"pot_of_greed");ui.card_faces[card.uid]=false;ui.render();await t.frames()
 mana=ui.game.state.mana;var charge=ui.game.state.charge
 await Click.click_card(t,card.uid)
 t.check(ui.game.state.mana==mana-5 and ui.game.state.charge==charge+1,"ATTACHMENT UI skill play resolves extra payment and charge through normal submission")
 ui.game.state.mana=9;ui.game.state.temporary_mana=0;ui.render();await t.frames()
 attack=Queries.find(ui.view,"attack",{"type":"strike"})
 t.check(attack.valid and not attack.payload.all and attack.mana==0,"ATTACHMENT UI insufficient mana leaves original attack selectable")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("魔力附着")=="Mana Attachment" and ui.localization.display("已关闭 · 右键开启")=="Disabled · Right-click to enable","ATTACHMENT UI English card and switch copy resolves")
 ui.localization.set_locale("zh_CN")
