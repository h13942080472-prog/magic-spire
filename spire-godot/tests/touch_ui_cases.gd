extends RefCounted

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
 t.check(ui.attack_forms.get("strike",-1)==1 and ui.game.state==before,"TOUCH basic attack switches form without attacking")
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
 var size=t.root.size;settings.set_mode(0);settings.set_resolution(Vector2i(1280,720))
 t.check(t.root.size==size,"TOUCH mobile settings cannot resize native Android window")
 settings.mobile=false;ui._close_drawers();ui._refresh_drawers();await t.frames()
