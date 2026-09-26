extends RefCounted

const Interface=preload("res://tests/interface_ui_cases.gd")

static func finger(t, position: Vector2, down: bool, index: int=0, canceled: bool=false) -> void:
 var event=InputEventScreenTouch.new();event.position=position;event.pressed=down;event.index=index;event.canceled=canceled
 t.ui.get_viewport().push_input(event,true)
 await t.frames()

static func move(t, position: Vector2, index: int=0) -> void:
 var event=InputEventScreenDrag.new();event.position=position;event.index=index
 t.ui.get_viewport().push_input(event,true)
 await t.frames()

static func tap(t, control: Control) -> void:
 var point=control.get_global_rect().get_center()
 await finger(t,point,true);await finger(t,point,false)

static func hold(t, position: Vector2) -> void:
 await finger(t,position,true)
 await t.create_timer(0.56).timeout
 await t.frames()

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 ui.game.state.wall="normal";ui.game.state.wall_distance=0
 var target=ui.game.add_fixture("ankle",400.0,1000.0)
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"concentration")
 ui.card_faces[card.uid]=false;ui.render();await t.frames()
 var point=t.card_point(card.uid);var before=ui.game.export_snapshot()
 await finger(t,point,true)
 t.check(not ui.card_faces[card.uid] and not is_instance_valid(ui.term_popup),"TOUCH initial press neither flips nor shows details")
 await t.create_timer(0.56).timeout;await t.frames()
 t.check(ui.card_faces[card.uid] and ui.game.state==before,"TOUCH long hold uses the original right-click flip without a play")
 t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains("拘束2"),"TOUCH hold shows details of the new face")
 var effect=ui.card_buttons[card.uid].get_node("CardText/Content/CardEffect").text
 t.check(t.visible_text(ui.term_popup).contains(effect),"TOUCH long-hold details include current card effect even when the printed text fits")
 await t.create_timer(0.6).timeout;await t.frames()
 t.check(ui.card_faces[card.uid],"TOUCH continued hold flips only once")
 await finger(t,point,false)
 t.check(ui.game.state==before and ui.card_buttons.has(card.uid),"TOUCH long-hold release never also clicks or spends the card")
 point=t.card_point(card.uid)
 await finger(t,point,true)
 await move(t,point+Vector2(0,-30))
 var hero=ui.actor_targets.hero.get_global_rect().get_center()
 await move(t,hero);await finger(t,hero,false)
 t.check(ui.player_pick and ui.game.state==before,"TOUCH native drag opens original player target picker")
 if not ui.player_pick: return
 await tap(t,ui.find_child("PlayerPart_ankle",true,false))
 await tap(t,ui.find_child("PlaySelectedCard",true,false))
 t.check(not ui.card_buttons.has(card.uid) and ui.view.energy==before.energy-1 and ui.game._equipment(target.id).durability<400,"TOUCH target taps submit the original action exactly once")
 ui.restart(42);await t.frames()
 var attack=ui.find_child("BasicAttack_strike",true,false)
 point=attack.get_global_rect().get_center();before=ui.game.export_snapshot()
 await hold(t,point);await finger(t,point,false)
 t.check(ui.attack_forms.strike==1 and ui.game.state==before,"TOUCH basic attack switches form without attacking")
 ui.game._gain_charge(3);ui.render();await t.frames()
 var charge=ui.find_child("StatusIcon_charge",true,false)
 if charge==null: charge=ui.find_child("Status_charge",true,false)
 t.check(charge!=null,"TOUCH charge has a real status control")
 if charge!=null:
  before=ui.game.export_snapshot();point=charge.get_global_rect().get_center()
  await hold(t,point);await finger(t,point,false)
  t.check(ui.game.state.charge_all and ui.game.state.charge==3 and ui.view.energy==before.energy,"TOUCH charge hold reuses zero-cost toggle without spending stacks")
 ui.game.state.pressure=40;ui.render();await t.frames();before=ui.game.export_snapshot()
 var breath=ui.find_child("DeepBreath",true,false);point=breath.get_global_rect().get_center()
 await finger(t,point,true);await finger(t,point+Vector2(10,0),true,1)
 await finger(t,point+Vector2(10,0),false,1);await finger(t,point,false)
 t.check(ui.view.energy==before.energy-1,"TOUCH second finger never generates a duplicate click")
 before=ui.game.export_snapshot();point=ui.find_child("DeepBreath",true,false).get_global_rect().get_center()
 await finger(t,point,true);await finger(t,point,false,0,true)
 t.check(ui.game.state==before,"TOUCH canceled contact causes no action")
 # A scroll gesture must not become a tap on the button where it ends.
 var scroller=ScrollContainer.new();scroller.name="TouchScrollProbe"
 scroller.position=Vector2(700,250);scroller.size=Vector2(250,160);scroller.z_index=290
 ui.layout.add_child(scroller)
 var rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroller.add_child(rows)
 var clicks=[0]
 for index in range(16):
  var row=Button.new();row.text="测试行 "+str(index);row.custom_minimum_size=Vector2(220,40)
  row.pressed.connect(func():clicks[0]+=1);rows.add_child(row)
 await t.frames()
 point=scroller.get_global_rect().position+Vector2(100,125)
 await finger(t,point,true);await move(t,point-Vector2(0,90));await finger(t,point-Vector2(0,90),false)
 t.check(scroller.scroll_vertical>0 and clicks[0]==0 and ui.game.state==before,"TOUCH scrolling changes only the viewport and never clicks a row")
 scroller.queue_free();await t.frames()
 ui._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST);await t.frames()
 t.check(ui.show_menu and ui.game.state==before,"TOUCH Android back opens menu without exiting or changing state")
 ui._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST);await t.frames()
 t.check(not ui.show_menu and ui.game.state==before,"TOUCH Android back dismisses the open drawer")
 var settings=ui.display_settings;settings.mobile=true
 ui._open_drawer("show_options");await t.frames()
 t.check(ui.find_child("DisplayMode",true,false)==null and ui.find_child("FeedbackSpeed",true,false)!=null,"TOUCH Android settings omit desktop window controls and retain feedback speed")
 var picker=ui.find_child("FeedbackSpeed",true,false)
 var options_scroll=ui.find_child("DisplayOptionsScroll",true,false)
 options_scroll.ensure_control_visible(picker);await t.frames()
 await tap(t,picker)
 t.check(picker.get_popup().visible,"TOUCH Android tap opens a settings dropdown")
 var popup=picker.get_popup()
 await t.create_timer(0.4).timeout
 var row_height=(popup.size.y-popup.get_theme_stylebox("panel").get_minimum_size().y)/popup.item_count
 var choice=Vector2(popup.size.x/2.0,popup.get_theme_stylebox("panel").get_margin(SIDE_TOP)+row_height*2.5)
 for down in [true,false]:
  await finger(t,Vector2(popup.position)+choice,down)
 t.check(not popup.visible and is_equal_approx(ui.feedback_duration,1.8),"TOUCH selecting a dropdown row applies its value through real popup touch input")
 # Reopen a newly built dropdown: cancellation, a second contact and Android back.
 picker=ui.find_child("FeedbackSpeed",true,false)
 options_scroll=ui.find_child("DisplayOptionsScroll",true,false)
 options_scroll.ensure_control_visible(picker);await t.frames();await tap(t,picker)
 popup=picker.get_popup();await t.frames()
 choice=Vector2(popup.position)+Vector2(popup.size.x/2.0,20)
 await finger(t,choice,true);await finger(t,choice,false,0,true)
 t.check(popup.visible and is_equal_approx(ui.feedback_duration,1.8),"TOUCH canceled popup contact preserves the selection")
 ui._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST);await t.frames()
 t.check(not popup.visible and ui.show_options,"TOUCH Android back closes the dropdown before its settings drawer")
 # Long option lists use the same popup bridge and must scroll without selecting.
 var long_picker=OptionButton.new();long_picker.position=Vector2(650,250);long_picker.size=Vector2(300,50)
 long_picker.z_index=290
 ui.layout.add_child(long_picker)
 for index in range(40): long_picker.add_item("Option "+str(index))
 var choices=[0];long_picker.item_selected.connect(func(_index):choices[0]+=1)
 await t.frames();await tap(t,long_picker);popup=long_picker.get_popup();await t.frames()
 var popup_scroll=popup.get_node("TouchInput")._popup_scroller(popup)
 popup_scroll.scroll_vertical=0;await t.frames()
 point=Vector2(popup.position)+Vector2(100,minf(popup.size.y-30,300))
 await finger(t,point,true);await move(t,point-Vector2(0,90));await finger(t,point-Vector2(0,90),false)
 t.check(popup.visible and popup_scroll.scroll_vertical>0 and choices[0]==0,"TOUCH popup swipe scrolls options without selecting")
 popup.hide();long_picker.queue_free();await t.frames()
 var size=t.root.size;settings.set_mode(0);settings.set_resolution(Vector2i(1280,720))
 t.check(t.root.size==size,"TOUCH mobile settings cannot resize native Android window")
 settings.mobile=false;ui._close_drawers();ui._refresh_drawers();await t.frames()
 # The hold path reaches the same term boxes as the mouse hover on a battle-exterior face
 # (docs/spec/card-terms.md「触发面」).
 ui.restart(42);await t.frames()
 ui._open_drawer("show_encyclopedia");await t.frames()
 var book=ui.find_child("Encyclopedia",true,false)
 book.show_entry(book.rows.filter(func(row):return row.category=="cards" and row.id=="mana_search")[0]);await t.frames()
 var face=ui.find_child("DisplayCard_encyclopedia_mana_search",true,false)
 before=ui.game.export_snapshot()
 await t.move_mouse(Vector2(70,300));await t.frames()
 await hold(t,face.get_global_rect().get_center())
 var side="free" if face.free_face else "bound"
 t.check(Interface.term_boxes(ui.term_popup)==Interface.pinned_terms("mana_search",side),"TOUCH hold shows the same term boxes as hover: "+str(Interface.term_boxes(ui.term_popup)))
 await finger(t,face.get_global_rect().get_center(),false)
 t.check(ui.game.export_snapshot()==before,"TOUCH hold term boxes change no state")
 await t.close_information()
