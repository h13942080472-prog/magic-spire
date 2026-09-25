extends RefCounted
const Feedback=preload("res://ui/combat_feedback.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 await player_interactions(t)
 var ui=t.ui
 ui.restart(42);await t.frames()
 var before=ui.view
 var end=Queries.find(ui.view,"flow",{"kind":"end"})
 if end.is_empty(): end=ui.view.display_facts.filter(func(c):return c.payload.kind=="end")[0]
 ui.feedback_duration=0.2
 ui.command_router.emit(String(end.payload.get("kind","")),end)
 var committed=ui.game.export_snapshot()
 var presenter=ui.enemy_feedback
 t.check(is_instance_valid(presenter),"FEEDBACK enemy operation opens presentation")
 var steps=Feedback.steps(before,ui.view)
 t.check(steps.any(func(step):return step.kind=="apply" and step.title=="施加装备" and not step.slots.is_empty()),"FEEDBACK unified application retains its title and actual affected positions")
 t.check(steps.size()>=2 and steps[0].enemy_id!=steps[-1].enemy_id,"FEEDBACK different enemy instances shown in actual order")
 t.check(presenter.current.enemy_id==steps[0].enemy_id and presenter.detail.text!="","FEEDBACK first enemy and actual result immediately readable")
 t.check(not presenter.highlights.is_empty(),"FEEDBACK active enemy and affected body have visual anchors")
 var next=ui.view.display_facts.filter(func(c):return c.valid)[0]
 ui.command_router.emit(String(next.payload.get("kind","")),next)
 t.check(ui.game.export_snapshot()==committed,"FEEDBACK clicks cannot submit gameplay during presentation")
 await t.capture("ui-100-enemy-action.png")
 await t.frames()
 t.check(not is_instance_valid(ui.enemy_feedback) and ui.game.export_snapshot()==committed,"FEEDBACK sequence finishes without any extra game effect")
 t.check(Feedback.steps(ui.view,ui.view).is_empty(),"FEEDBACK re-render/save snapshot cannot replay history")
 before=ui.view
 end=ui.view.display_facts.filter(func(c):return c.payload.kind=="end")[0]
 ui.command_router.emit(String(end.payload.get("kind","")),end)
 committed=ui.game.export_snapshot()
 presenter=ui.enemy_feedback
 if is_instance_valid(presenter):
  presenter.find_child("SkipEnemyFeedback",true,false).pressed.emit()
 t.check(not is_instance_valid(ui.enemy_feedback) and ui.game.export_snapshot()==committed,"FEEDBACK skip affects display only")
 # Hidden preparation must remain hidden in the new overlay too.
 ui.restart(42);await t.frames()
 ui.game.add_fixture("eyes",4)
 for e in ui.game.state.enemies: e.stage=3;e.intent=ui.game._plan(e)
 ui.render();before=ui.view
 end=ui.view.display_facts.filter(func(c):return c.payload.kind=="end")[0]
 ui.command_router.emit(String(end.payload.get("kind","")),end)
 steps=Feedback.steps(before,ui.view)
 t.check(not steps.is_empty() and steps.all(func(step):return step.kind=="unseen"),"FEEDBACK blind preparation does not leak its action kind")
 ui.restart(43)
 t.check(not is_instance_valid(ui.enemy_feedback),"FEEDBACK new run clears old presentation")
 # Two operations from one guard stay separate, including a retargeted second lock.
 ui.restart(42,true,"guard");await t.frames()
 var a=ui.game.add_fixture("thigh",4);var b=ui.game.add_fixture("forearm",4)
 ui.game.state.enemies[0].intent={"kind":"guard_sequence","priority":false,"delayed":false,"text":"连续上锁","operations":[{"kind":"lock","target":a.id,"text":"上锁","delayed":false},{"kind":"lock","target":b.id,"text":"上锁","delayed":false}]}
 ui.render();before=ui.view
 ui.command_router.emit(String(ui.view.display_facts.filter(func(c):return c.payload.kind=="end")[0].payload.get("kind","")),ui.view.display_facts.filter(func(c):return c.payload.kind=="end")[0])
 steps=Feedback.steps(before,ui.view)
 t.check(steps.size()==2 and steps[0].enemy_id==steps[1].enemy_id and steps[0].key!=steps[1].key,"FEEDBACK guard's two operations retain separate sequence positions")
 t.check(steps[0].slots==["thigh"] and steps[1].slots==["forearm"],"FEEDBACK each operation points to its actual affected body part")
 await t.frames()
 # One formal batch must highlight every actual installation, not only its first log.
 await t.start_practice("Practice_trader_solo")
 before=ui.view
 ui.command_router.emit(String(ui.view.display_facts.filter(func(c):return c.payload.kind=="end")[0].payload.get("kind","")),ui.view.display_facts.filter(func(c):return c.payload.kind=="end")[0])
 steps=Feedback.steps(before,ui.view)
 var expected=[]
 for log in ui.view.logs.slice(before.logs.size()):
  for slot in log.data.get("enemy_action",{}).get("slots",[]):
   if slot not in expected: expected.append(slot)
 presenter=ui.enemy_feedback
 committed=ui.game.export_snapshot()
 t.check(expected.size()>=2 and steps.size()==1 and steps[0].slots==expected,"FEEDBACK one batch merges all actual affected body locations")
 t.check(is_instance_valid(presenter) and presenter.current.slots==expected and expected.all(func(slot):return ui.body_buttons.has(slot) and ui.body_buttons[slot].get_global_rect().grow(3) in presenter.highlights),"FEEDBACK batch highlights every committed body location")
 await t.frames()
 t.check(not is_instance_valid(ui.enemy_feedback) and ui.game.export_snapshot()==committed,"FEEDBACK batch presentation preserves committed state")
 ui.feedback_duration=0.04
 await t.frames()

static func press(t, name: String) -> void:
 var button=t.ui.find_child(name,true,false)
 t.check(button!=null,"INTERACTION visible entry "+name)
 if button==null: return
 var point=button.get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)

static func player_interactions(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 t.check(ui.view.hand.all(func(c):return ui.card_buttons[c.uid].free_face),"DRAW UI empty body draws cards free-side")
 var card=ui.game.state.hand.filter(func(c):return c.type=="slip")[0]
 var uid=card.uid
 await t.flip(uid);ui.render();await t.frames()
 t.check(not ui.card_buttons[uid].free_face,"DRAW UI right-click choice survives ordinary redraw")
 var target=ui.game.add_fixture("ankle",4)
 ui.game.state.hand.erase(card);ui.game.state.draw.append(card);ui.game._draw(1)
 ui.render();await t.frames()
 t.check(not ui.card_buttons[uid].free_face,"DRAW UI actual redraw chooses bound face when escape target exists")
 var previous=ui.view
 var c=Queries.select(ui.view,"card",{"uid":uid,"target":target.id})[0]
 await t.start_drag(uid,"ankle");await t.release_target(await t.reveal_drop_target(c.key))
 t.check(ui.find_child("PlayerActionFeedback",true,false)!=null and Feedback.equipment_changes(previous,ui.view).any(func(row):return row.text=="已解除"),"FEEDBACK actual escape drag immediately reports removal")
 var committed=ui.game.export_snapshot();ui.render();await t.frames()
 t.check(ui.find_child("PlayerActionFeedback",true,false)==null and ui.game.export_snapshot()==committed,"FEEDBACK redraw neither replays old player feedback nor changes state")
 ui.restart(42,true,"equipment");await t.frames()
 ui.game.state.equipment=[]
 target=ui.game.add_fixture("forearm",10,10,false,0,"tape")
 ui.render();await t.frames()
 var item=ui.view.items[0].id
 ui.selected_item=item;ui._open_drawer("show_items");await t.frames()
 t.check(await t.click("item_install",{"item":item,"mount":"hand_wall"}),"TOOL installs through actual candidate")
 await t.close_information()
 t.check(await t.click("posture",{"dest":"sit","wall":false}) and await t.click("posture",{"dest":"lie","wall":false}),"TOOL close drawer and change posture through formal actions")
 if not ui.quick_release_open: await press(t,"ActionRailToggle")
 await press(t,"InstalledTool_"+item)
 t.check(ui.show_items and ui.selected_item==item and ui.game.InstalledTools.reason(ui.game,ui.game._item(item),target)!="" and Queries.select(ui.view,"item",{"item":item,"target":target.id}).is_empty(),"TOOL installed entry reopens even with currently unreachable target")
 await t.close_information()
 t.check(await t.click("posture",{"dest":"sit","wall":false}),"TOOL restore legal posture")
 await press(t,"InstalledTool_"+item)
 t.check(await t.trigger_installed_tool(target.id,item),"TOOL reopened installed tool really cuts target and spends use")
 await t.close_information()
 t.check(ui.find_child("InstalledTool_"+item,true,false)!=null,"TOOL entry remains for remaining uses")
 var ordinary=ui.find_child("Posture_stand",true,false)
 var wall=ui.find_child("Posture_stand_wall",true,false)
 t.check(wall!=null and wall.position.x>ordinary.position.x and wall.position.y==ordinary.position.y,"POSTURE rest wall ascent appears beside matching normal option")
 var left=ui.view.rest_left
 await press(t,"Posture_stand_wall")
 t.check(ui.view.posture=="stand" and ui.view.rest_left==left,"POSTURE rest wall ascent preserves the current rest turn")
 await t.capture("ui-101-installed-tool-and-feedback.png")
 ui.restart(42);await t.frames()
