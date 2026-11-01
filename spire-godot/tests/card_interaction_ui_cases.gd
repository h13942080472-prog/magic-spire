extends RefCounted
const Give=preload("res://tests/curse_cases.gd")
const Touch=preload("res://tests/touch_ui_cases.gd")
const Feedback=preload("res://ui/combat_feedback.gd")

static func setup(t, type: String) -> String:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 var card=Give.give(ui.game,type)
 card.draw_free=false
 ui.card_faces[card.uid]=false;ui.render();await t.frames()
 return card.uid

static func start(t, uid: String) -> void:
 await t.move_mouse(t.card_point(uid))
 var point=t.card_point(uid)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await t.move_mouse(point+Vector2(0,-50),true)
 t.check(t.root.gui_is_dragging(),"CARD INPUT native upward drag starts")

static func refreshed_preview(t) -> void:
 var ui=t.ui
 var uid=await setup(t,"panic")
 await t.move_mouse(Vector2(80,80))
 var button=ui.card_buttons[uid]
 var initial_id=button.get_instance_id()
 ui.game.state.energy=0
 var before=ui.game.export_snapshot()
 ui.present(["hand"],ui.game.get_view());await t.frames()
 t.check(ui.card_buttons[uid].get_instance_id()==initial_id,"CARD PREVIEW incremental update retains the interactive card")
 await t.move_mouse(t.card_point(uid));await t.frames()
 var current=button.find_child("CardAvailability",true,false)
 var preview=ui.find_child("CardInspectionPreview",true,false)
 var shown=preview.find_child("CardAvailability",true,false) if preview!=null else null
 t.check(current!=null and not current.text.is_empty(),"CARD PREVIEW zero energy provides a changed availability value")
 t.check(current!=null and shown!=null and shown.text==current.text,"CARD PREVIEW reused card inspection reads current availability rather than its mount snapshot")
 t.check(ui.game.export_snapshot()==before,"CARD PREVIEW refreshed inspection preserves state and RNG")

static func run(t) -> void:
 await refreshed_preview(t)
 var ui=t.ui
 var uid=await setup(t,"strain")
 var before=ui.game.export_snapshot()
 await t.move_mouse(t.card_point(uid));await t.frames()
 var preview=ui.find_child("CardInspectionPreview",true,false)
 t.check(preview!=null and preview.size.y>ui.card_buttons[uid].size.y and preview.get_node("CardCost").text==ui.card_buttons[uid].get_node("CardCost").text,"CARD PREVIEW enlarged card preserves actual face cost")
 t.check(ui.game.export_snapshot()==before,"CARD PREVIEW hover never pays, changes RNG or writes state")
 await t.capture("ui-card-inspection.png")
 await t.flip(uid)
 t.check(ui.card_faces[uid] and ui.game.export_snapshot()==before,"CARD FLIP native right click updates face without a command")
 t.check(ui.find_child("CardFlipOld",true,false)!=null and ui.find_child("CardFlipNew",true,false)!=null,"CARD FLIP both sides participate in the visual turn")
 await t.capture("ui-card-flip.png")
 await t.create_timer(0.35).timeout;await t.frames()
 t.check(ui.card_buttons[uid].modulate.a==1 and ui.find_child("CardFlipOld",true,false)==null,"CARD FLIP restores original interactive card and removes ghosts")
 await t.flip(uid);await t.flip(uid)
 await t.create_timer(0.35).timeout;await t.frames()
 t.check(ui.card_faces[uid] and ui.card_buttons[uid].modulate.a==1 and ui.game.export_snapshot()==before,"CARD FLIP repeated flips preserve parity and restore opacity")
 uid=await setup(t,"strain")
 ui.game.add_fixture("ankle",100,100);ui.render();await t.frames()
 before=ui.game.export_snapshot()
 await start(t,uid)
 t.check(ui.find_child("CardDragPreview",true,false)!=null and ui.card_interaction.targeting,"CARD DRAG targeted card keeps a full card preview and aim decoration")
 var drag_preview=ui.find_child("CardDragPreview",true,false)
 t.check(drag_preview!=null and (drag_preview.get_child(0).get_global_transform()*Vector2(80,75)).distance_to(t.mouse_position)<2,"CARD DRAG keeps the original grabbed point under the cursor: offset="+str(drag_preview.get_child(0).position)+" transform="+str(drag_preview.get_child(0).get_global_transform())+" pointer="+str(t.mouse_position))
 t.check(ui.find_child("SelfCardPlayArea",true,false)==null,"CARD DRAG equipment-targeted card cannot use the self-play surface")
 t.check(ui.card_buttons[uid].modulate.a==0 and ui.find_child("CardInspectionPreview",true,false)==null and ui.find_child("CardFlipOld",true,false)==null,"CARD DRAG hides the source and every inspection or flip duplicate")
 await t.move_mouse(ui.body_buttons.ankle.get_global_rect().get_center(),true)
 t.check(ui.card_interaction.endpoint.distance_to(ui.body_buttons.ankle.get_global_rect().get_center())<100,"CARD AIM tracks synthesized pointer position rather than the OS cursor")
 if not ui.drop_targets.is_empty():
  var target=ui.drop_targets.values()[0]
  await t.move_mouse(target.get_global_rect().get_center(),true)
  t.check(ui.card_interaction.accepted,"CARD AIM uses the native receiver's acceptance result")
 await t.capture("ui-card-targeting.png")
 var cancel_point=Vector2(820,340)
 await t.move_mouse(cancel_point,true);await t.mouse_button(cancel_point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.export_snapshot()==before and ui.active_drag.is_empty() and ui.card_interaction.drag.is_empty(),"CARD CANCEL invalid release clears aim without a command")
 t.check(ui.card_buttons[uid].modulate.a==1 and ui.find_child("CardDragPreview",true,false)==null,"CARD CANCEL restores the hand source and removes the moving card")
 uid=await setup(t,"panic")
 before=ui.game.export_snapshot()
 await start(t,uid)
 var zone=ui.find_child("CardCastZone",true,false)
 t.check(zone!=null and not ui.card_interaction.targeting,"CARD CAST untargeted card exposes a cast zone without a target arc")
 t.check(not ui.drag_hints.any(func(hint):return hint.get_meta("target_id","")=="hero"),"CARD COPY self highlight does not repeat the card effect in a second panel")
 if zone!=null:
  t.check(t.visible_text(zone.get_parent()).strip_edges()=="" and ui.actor_targets.hero.get_theme_stylebox("hover") is StyleBoxEmpty,"CARD COPY self play has no action box or hero frame")
  var destination=Vector2(820,340)
  await t.move_mouse(destination,true)
  await t.capture("ui-card-self-release.png")
  await t.move_mouse(destination,true);await t.mouse_button(destination,MOUSE_BUTTON_LEFT,false)
  t.check(ui.game.state.exhaust.any(func(card):return card.uid==uid) and ui.game.state.version==before.version+1,"CARD CAST native drop consumes exactly one original command")
  t.check(ui.find_child("CardUseResult",true,false)==null,"CARD COPY successful play has no duplicate announcement")
 # Single-face cards and canceled gestures must not accidentally use the card.
 uid=await setup(t,"sensitive")
 before=ui.game.export_snapshot()
 var point=t.card_point(uid)
 await Touch.finger(t,point,true);await Touch.move(t,point+Vector2(0,70));await Touch.finger(t,point+Vector2(0,70),false)
 t.check(not ui.card_faces[uid] and ui.game.export_snapshot()==before,"CARD SWIPE single-face card cannot flip or play")
 uid=await setup(t,"strain")
 ui.display_settings.reduced_card_motion=true
 before=ui.game.export_snapshot()
 await t.flip(uid)
 t.check(ui.card_faces[uid] and ui.card_buttons[uid].modulate.a==1 and ui.find_child("CardFlipOld",true,false)==null and ui.game.export_snapshot()==before,"CARD MOTION reduced mode keeps flip semantics without ghosts")
 ui.display_settings.reduced_card_motion=false

 var window_size=t.root.size
 t.root.size=Vector2i(1280,720);await t.frames()
 await start(t,uid)
 var moving=ui.find_child("CardDragPreview",true,false)
 t.check(moving!=null and moving.get_child(0).get_global_transform().get_scale().is_equal_approx(ui.card_buttons[uid].get_global_transform().get_scale()),"CARD DRAG preview follows actual viewport scale rather than fixed screen pixels")
 t.check(moving!=null and (moving.get_child(0).get_global_transform()*Vector2(80,75)).distance_to(t.mouse_position)<2,"CARD DRAG scaled preview keeps the original grabbed point under the cursor")
 await t.move_mouse(Vector2(10,10),true);await t.mouse_button(Vector2(10,10),MOUSE_BUTTON_LEFT,false)
 t.root.size=window_size;await t.frames()
 await drag_lifecycle(t)
 await self_release(t)
 await damage_records(t)
 await equipment_hits(t)
 await failed_cast(t)

static func self_release(t) -> void:
 var ui=t.ui
 for touch in [false,true]:
  var uid=await setup(t,"panic")
  var before=ui.game.export_snapshot()
  await start(t,uid)
  var back=Vector2(820,790)
  await t.move_mouse(back,true);await t.mouse_button(back,MOUSE_BUTTON_LEFT,false)
  t.check(ui.game.export_snapshot()==before and ui.card_buttons[uid].modulate.a==1,"CARD SELF returning to the hand cancels without paying")
  var target=ui.actor_targets[ui.view.enemies[0].id].get_global_rect().get_center()
  if touch:
   var point=t.card_point(uid)
   await Touch.finger(t,point,true);await Touch.move(t,point+Vector2(0,-50));await Touch.move(t,target);await Touch.finger(t,target,false)
  else:
   await start(t,uid);await t.move_mouse(target,true);await t.mouse_button(target,MOUSE_BUTTON_LEFT,false)
  t.check(ui.game.state.exhaust.any(func(card):return card.uid==uid) and ui.game.state.version==before.version+1,"CARD SELF battlefield release resolves once even above an enemy for mouse and touch")
 var uid=await setup(t,"panic")
 ui.game.state.energy=0;ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await start(t,uid)
 t.check(ui.find_child("SelfCardPlayArea",true,false)==null,"CARD SELF unaffordable card does not enable battlefield release")
 var field=Vector2(820,340)
 await t.move_mouse(field,true);await t.mouse_button(field,MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.export_snapshot()==before and ui.card_buttons[uid].modulate.a==1,"CARD SELF unaffordable release preserves state and restores its source")

static func drag_lifecycle(t) -> void:
 var ui=t.ui
 var uid=await setup(t,"strain")
 var before=ui.game.export_snapshot()
 await t.flip(uid)
 await start(t,uid)
 t.check(ui.card_buttons[uid].modulate.a==0 and ui.find_child("CardFlipOld",true,false)==null,"CARD DRAG starting during a flip leaves only the drag preview")
 await t.move_mouse(Vector2(1520,840),true);await t.mouse_button(Vector2(1520,840),MOUSE_BUTTON_LEFT,false)
 t.check(ui.card_buttons[uid].modulate.a==1 and ui.game.export_snapshot()==before,"CARD DRAG quick flip and cancel restores opacity without payment")
 ui.game.state.energy=0;ui.render();await t.frames()
 before=ui.game.export_snapshot()
 ui.display_settings.reduced_card_motion=true
 await start(t,uid)
 t.check(ui.card_buttons[uid].modulate.a==0 and ui.active_drag.get("card_uid","")==uid,"CARD DRAG unavailable card still lifts its source in reduced-motion mode")
 await t.move_mouse(Vector2(1520,840),true);await t.mouse_button(Vector2(1520,840),MOUSE_BUTTON_LEFT,false)
 t.check(ui.card_buttons[uid].modulate.a==1 and ui.card_buttons[uid].modulate.r<0.7 and ui.game.export_snapshot()==before,"CARD DRAG rejected card returns with its original unavailable tint")
 ui.display_settings.reduced_card_motion=false

static func equipment_hits(t) -> void:
 var ui=t.ui
 var uid=await setup(t,"repeated_strain")
 var target=ui.game.add_fixture("ankle",100,100)
 ui.render();await t.frames()
 var before=ui.view
 var choice=preload("res://ui/target_queries.gd").find(ui.view,"card",{"uid":uid,"free":false,"target":target.id})
 t.check(not choice.is_empty() and choice.valid,"CARD EQUIPMENT actual multihit card has a valid target")
 if choice.is_empty() or not choice.valid: return
 ui.command_router.emit("card",choice);await t.frames(2,false)
 var hits=[]
 for i in range(before.logs.size(),ui.view.logs.size()):
  var record=ui.view.logs[i].data
  if record.has("follow_through_hit"): hits.append(record.follow_through_hit)
 var labels=ui.layout.find_children("EquipmentHitFeedback*","Label",true,false)
 t.check(hits.size()==5 and labels.size()==5,"CARD EQUIPMENT five actual releases produce five hit feedback entries")
 for i in range(mini(labels.size(),hits.size())):
  t.check(labels[i].get_meta("target")==hits[i].target and is_equal_approx(labels[i].get_meta("damage"),maxf(0,hits[i].before-hits[i].after)),"CARD EQUIPMENT hit feedback follows actual target and durability delta")

static func damage_records(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 ui.game.state.energy=4;ui.game.state.posture="sit";ui.game.state.charge=0
 ui.game.state.enemies[0].hp=1000;ui.game.state.enemies[0].max_hp=1000
 ui.render();await t.frames()
 var before=ui.view
 ui.attack_forms.kick=3;ui.render();await t.frames()
 t.check(await t.click("attack",{"type":"kick","form":3,"enemy":ui.game.state.enemies[0].id},false),"CARD HITS actual multi-hit action commits")
 var expected=[]
 for i in range(before.logs.size(),ui.view.logs.size()):
  var data=ui.view.logs[i].data
  if data.has("damage") and data.has("enemy") and ui.actor_targets.has(data.enemy): expected.append(data.damage)
 var labels=ui.layout.find_children("DamageFeedback*","Label",true,false)
 t.check(expected.size()>1 and labels.size()==expected.size(),"CARD HITS creates one feedback per committed hit rather than a summed hit")
 for i in range(mini(labels.size(),expected.size())): t.check(is_equal_approx(labels[i].get_meta("damage"),expected[i]),"CARD HITS uses committed damage including per-hit reductions")
 var snapshot=ui.game.export_snapshot()
 await t.create_timer(2).timeout;await t.frames()
 t.check(ui.game.export_snapshot()==snapshot,"CARD HITS animation does not reapply damage or spend resources")

static func failed_cast(t) -> void:
 var ui=t.ui
 var uid=await setup(t,"henshin")
 ui.game.state.pressure=99;ui.game.state.mana=100;ui.game.state.energy=10
 var profile=ui.game.cast_view(ui.game.Cards.cast_profile(ui.game,"henshin"))
 var rng=ui.game.state.rng.magic
 while ui.game._random_index("magic",ui.game.B.CAST_ROLL_STEPS)<profile.winning_rolls: rng=ui.game.state.rng.magic
 ui.game.state.rng.magic=rng
 ui.render();await t.frames()
 var candidates=preload("res://ui/target_queries.gd").select(ui.view,"card",{"uid":uid,"free":false})
 var choice=candidates.filter(func(c):return c.valid)
 t.check(not choice.is_empty(),"CARD FAILURE fixture exposes a real cast")
 if choice.is_empty(): return
 ui.command_router.emit("card",choice[0]);await t.frames(2,false)
 var notice=ui.find_child("CardUseResult",true,false)
 t.check(notice!=null and t.visible_text(notice).contains("施法失败") and ui.game.state.hand.any(func(card):return card.uid==uid),"CARD FAILURE failed spell remains in hand with a distinct result")
 t.check(ui.find_child("MainManaValue",true,false).text.begins_with(ui.game.number(ui.view.mana)+"/"),"CARD RESOURCE number shows committed mana while the feedback runs")
