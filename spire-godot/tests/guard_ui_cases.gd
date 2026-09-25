extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 await sidebar_drag(t)
 var ui=t.ui
 await t.start_practice("Practice_guard")
 t.check(ui.view.phase=="battle" and ui.view.enemies.size()==1 and ui.view.enemies[0].type=="guard" and ui.view.enemies[0].maximum==90,"GUARD UI practice starts real succubus guard")
 var enemy=ui.view.enemies[0].id
 var picture=ui.find_child("EnemyArt_"+enemy,true,false)
 var expected_path="res://assets/art/enemy-succubus-guards-v1/succubus-purple-v1.png" if picture.variant=="guard_purple" else "res://assets/art/enemy-succubus-guards-v1/succubus-brown-v1.png"
 t.check(picture.variant==ui.view.enemies[0].visual_variant and picture.enemy_sprite.texture.resource_path==expected_path and picture.enemy_sprite.texture!=ui.Arena.Art.GUARD_PORTRAITS[picture.variant],"GUARD UI uses the original succubus portrait variant without borrowing the prison guard art")
 var group=ui.find_child("EnemyGroup_"+enemy,true,false)
 var select=ui.find_child("EnemySelect_"+enemy,true,false)
 t.check(is_equal_approx(group.position.x+group.size.x/2.0,ui.ENEMY_STAGE_LEFT+ui.ENEMY_STAGE_WIDTH/2.0),"GUARD UI single enemy uses the full stage width without reserving action-log space")
 t.check(absf(picture.get_global_rect().get_center().x-select.get_global_rect().get_center().x)<1.0,"GUARD UI portrait is centered over its name, health and ground marker")
 var initial=ui.game.export_snapshot()
 t.check(ui.find_child("IntentIcon_"+enemy+"_bind",true,false)!=null and ui.find_child("IntentIcon_"+enemy+"_deadline",true,false)==null,"GUARD UI opening shows actual binding intent without removed deadline")
 t.check(ui.find_child("HeroGuardBind",true,false)==null and ui.game.export_snapshot()==initial,"GUARD UI bind meter stays hidden before application and projection is read-only")
 await t.capture("ui-34-guard-intent.png")

 t.check(await t.click("end") and ui.game._enemy(enemy).intent.kind=="bind_prepare","GUARD UI opening resolves before bind preparation")
 t.check(await t.click("end") and ui.game._enemy(enemy).intent.kind=="bind_apply","GUARD UI preparation occupies one enemy action")
 t.check(await t.click("end") and ui.view.guard_bind.value==50.0,"GUARD UI bind application starts at fifty")
 var move=ui.find_child("WallMove_toward",true,false)
 t.check(move!=null and move.disabled and move.text.contains("被捕缚时无法移动"),"GUARD UI capture visibly disables movement with its concrete reason")
 var move_rect=move.get_global_rect()
 var posture_choices=ui.find_child("PostureChoices",true,false)
 t.check(posture_choices==null or move_rect.end.y<=posture_choices.get_global_rect().position.y,"GUARD UI disabled capture movement does not overlap posture choices")
 t.check(ui.find_child("HeroGuardBind",true,false)!=null and ui.find_child("HeroGuardBindValue",true,false).text=="50/100" and ui.actor_targets.has("guard_bind"),"GUARD UI compact bind meter appears below mana and accepts card targeting")
 t.check(ui.view.statuses.any(func(status):return status.id=="guard_bind"),"GUARD UI status panel receives the bind rules")
 var bind_bar=ui.find_child("HeroGuardBind",true,false)
 var bind_rect=bind_bar.get_global_rect()
 var snapshot=ui.game.export_snapshot()
 var navigation=preload("res://tests/interface_ui_cases.gd")
 await navigation.press(t,"OpenStatus")
 await preload("res://tests/status_ui_cases.gd").inspect(t,"guard_bind")
 var drawer=ui.find_child("InformationDrawer",true,false)
 t.check(drawer.get_global_rect().encloses(bind_rect),"GUARD UI status window covers the battlefield capture meter in the regression scenario")
 for id in ["HeroGuardBindCaption","HeroGuardBind","HeroGuardBindValue","GuardBindTarget"]:
  var control=ui.find_child(id,true,false)
  t.check(control.z_index<drawer.z_index and not drawer.is_ancestor_of(control),"GUARD UI capture control stays below the status window: "+id)
 var point=ui.actor_targets.guard_bind.get_global_rect().get_center()
 await t.move_mouse(point)
 var hovered=t.root.gui_get_hovered_control()
 t.check(hovered!=null and (hovered==drawer or drawer.is_ancestor_of(hovered)),"GUARD UI covered capture target cannot intercept status-window input")
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.show_pressure and ui.game.export_snapshot()==snapshot and bind_bar.get_global_rect()==bind_rect,"GUARD UI reading over the capture meter changes neither its position nor game state")
 await t.move_mouse(Vector2(1550,60));await t.capture("ui-guard-status-layer.png")
 await navigation.press(t,"CloseDrawer")
 await t.move_mouse(point)
 t.check(t.root.gui_get_hovered_control()==ui.actor_targets.guard_bind and ui.find_child("HeroGuardBind",true,false)==bind_bar,"GUARD UI closing status restores the original capture drop target without rebuilding it")

 var cards=ui.view.hand.filter(func(card):return card.type=="strain")
 t.check(not cards.is_empty(),"GUARD UI has a real strain card for bind interaction")
 if not cards.is_empty():
  var before=float(ui.view.guard_bind.value)
  await t.drop_card_on_actor(cards[0].uid,"guard_bind")
  t.check(ui.view.guard_bind.value<before and ui.view.pressure.value>0,"GUARD UI native card drop damages bind and resolves paid-energy stimulation")
 await t.capture("ui-35-guard-bind.png")

 ui.game.state.guard_bind.progress=100.0
 ui.game._enemy(enemy).intent={"kind":"capture","text":"执行收押","delayed":false}
 ui.render();await t.frames()
 var mana=ui.view.mana
 var deck=ui.view.deck_count
 t.check(await t.click("end") and ui.view.phase=="captured" and ui.view.security==1 and ui.view.reward_count==0 and ui.view.mana==maxf(0.0,mana-20.0) and ui.view.deck_count==deck,"GUARD UI next enemy action captures, milks once and grants no battle reward")
 t.check(ui.find_child("PrisonIntakePanel",true,false)!=null and ui.find_child("PrisonGuardPortrait",true,false).texture==ui.Arena.Art.GUARD_PORTRAITS.guard_brown and t.visible_text(ui.layout).contains("监狱收押") and t.visible_text(ui.layout).contains("榨取魔力 20") and t.visible_text(ui.layout).contains("登记台前") and not t.visible_text(ui.layout).contains("本次没有战后恢复"),"GUARD UI capture uses the current senior prison guard and one-time intake page with its real mana loss")

 await t.start_practice("Practice_double_guard")
 t.check(ui.view.enemies.size()==2 and ui.view.enemies[0].id!=ui.view.enemies[1].id,"GUARD UI double guards retain independent ids")
 for guard in ui.view.enemies:
  picture=ui.find_child("EnemyArt_"+guard.id,true,false)
  t.check(picture.variant==guard.visual_variant and guard.visual_variant in ["guard_purple","guard_brown"] and picture.enemy_sprite.texture==ui.Arena.Art.SUCCUBUS_GUARD_PORTRAITS[guard.visual_variant],"GUARD UI paired guard keeps its own original succubus portrait "+guard.id)
 var first_group=ui.find_child("EnemyGroup_"+ui.view.enemies[0].id,true,false)
 var last_group=ui.find_child("EnemyGroup_"+ui.view.enemies[-1].id,true,false)
 var row_right=last_group.position.x+last_group.size.x*last_group.scale.x
 t.check(is_equal_approx(first_group.position.x-ui.ENEMY_STAGE_LEFT,ui.ENEMY_STAGE_LEFT+ui.ENEMY_STAGE_WIDTH-row_right) and ui.find_child("ActionSidebar",true,false)==null,"GUARD UI enemy row stays centered across the stage with no scene action log overlay")
 var first=ui.view.enemies[0].id
 var second=ui.view.enemies[1].id
 var kick=ui.view.display_facts.filter(func(c):return c.payload.kind=="attack" and c.payload.type=="kick" and c.payload.form==0 and c.payload.enemy==second)[0]
 var second_health=ui.game._enemy(second).hp
 await t.drag_control_to(t.action_button("kick"),second)
 t.check(kick.valid and ui.game._enemy(first).hp==90 and ui.game._enemy(second).hp==second_health-kick.payload.damage and not ui.game._enemy(first).intent.delayed and ui.game._enemy(second).intent.delayed==kick.payload.interrupt,"GUARD UI direct attack applies the offered damage and interrupt only to the chosen guard")
 await t.capture("ui-36-double-guard.png")

 var brown_found=false
 for seed in range(12):
  ui.restart(seed,true,"guard");await t.frames()
  if ui.view.enemies[0].visual_variant=="guard_brown":
   picture=ui.find_child("EnemyArt_"+ui.view.enemies[0].id,true,false)
   brown_found=picture.enemy_sprite.texture.resource_path=="res://assets/art/enemy-succubus-guards-v1/succubus-brown-v1.png"
   await t.capture("ui-guard-brown-portrait.png")
   break
 t.check(brown_found,"GUARD UI registered brown portrait is reachable through formal seeded generation")
 await reinforcements(t)

static func reinforcements(t) -> void:
 var ui=t.ui
 await preload("res://tests/prison_ui_cases.gd").enter(t)
 var g=ui.game
 for i in range(g.state.prison.left): t.check(await t.click("end"),"REINFORCEMENTS UI reach patrol through completed turns")
 preload("res://tests/prison_reinforcement_cases.gd").quiet(g);g.state.posture="stand"
 ui.render();await t.frames()
 t.check(await t.click("prison",{"action":"resist"}),"REINFORCEMENTS UI formal resistance starts field")
 var icon=ui.find_child("StatusIcon_prison_reinforcements",true,false)
 t.check(icon!=null and ui.view.statuses.any(func(row):return row.id=="prison_reinforcements" and row.value=="4回合后抵达"),"REINFORCEMENTS UI visible field badge at battle start")
 for i in range(4):
  preload("res://tests/prison_reinforcement_cases.gd").quiet(g);ui.render();await t.frames()
  t.check(await t.click("end"),"REINFORCEMENTS UI actual end button advances field")
 var reinforcement=g.state.enemies.back()
 var reinforcement_picture=ui.find_child("EnemyArt_"+reinforcement.id,true,false)
 t.check(ui.view.enemies.size()==2 and ui.actor_targets.has(reinforcement.id) and reinforcement_picture.enemy_sprite.texture==ui.Arena.Art.SUCCUBUS_GUARD_PORTRAITS[reinforcement.visual_variant] and ui.view.statuses.any(func(row):return row.id=="prison_reinforcements" and row.detail.contains("1 / 2")),"REINFORCEMENTS UI new guard is targetable, uses the original succubus art and updates the shared count")


static func sidebar_drag(t) -> void:
 var ui=t.ui
 ui.restart(42,true,"guard")
 preload("res://tests/guard_cases.gd").bind(ui.game,ui.game.state.enemies[0],36.0)
 ui.game.state.energy=5
 ui.game.state.draw.append_array(ui.game.state.hand);ui.game.state.hand.clear()
 for type in ["strain","slip","ease","unlock"]:preload("res://tests/curse_cases.gd").give(ui.game,type)
 ui.render();await t.frames()
 var sidebar=ui.find_child("SidebarGuardBindTarget",true,false)
 t.check(sidebar!=null and sidebar.get_global_rect().encloses(ui.find_child("MainGuardBind",true,false).get_global_rect()) and sidebar.get_global_rect().encloses(ui.find_child("MainGuardBindCaption",true,false).get_global_rect()),"GUARD sidebar whole capture row accepts drops including caption and meter")
 t.check(not sidebar.get_global_rect().intersects(ui.find_child("FlaskDeposit",true,false).get_global_rect()),"GUARD sidebar receiver does not overlap flask controls")
 for type in ["strain","slip","ease"]:
  var card=ui.view.hand.filter(func(entry):return entry.type==type)[0]
  if ui.card_faces.get(card.uid,false):await t.flip(card.uid)
  var c=Queries.find(ui.view,"card",{"uid":card.uid,"target":"guard_bind","free":false})
  t.check(c.valid,"GUARD sidebar uses existing capture escape candidate "+type)
  var frozen=ui.game.export_snapshot()
  var point=t.card_point(card.uid)
  await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
  sidebar=ui.find_child("SidebarGuardBindTarget",true,false)
  t.check(t.root.gui_is_dragging() and sidebar.has_meta("idle_normal") and ui.find_child("GuardBindTarget",true,false).has_meta("idle_normal"),"GUARD both capture meters highlight for the same dragged card")
  point=sidebar.get_global_rect().position+Vector2(24,sidebar.size.y/2) if type=="strain" else sidebar.get_global_rect().get_center()
  await t.move_mouse(point,true)
  t.check(t.root.gui_get_hovered_control()==sidebar,"GUARD drag actually reaches sidebar: "+str(t.root.gui_get_hovered_control()))
  t.check(ui.game.export_snapshot()==frozen,"GUARD sidebar hover does not pay or change capture")
  await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
  t.check(is_equal_approx(ui.view.guard_bind.value,frozen.guard_bind.progress-c.payload.preview.damage) and ui.view.energy==frozen.energy-c.cost and not ui.view.hand.any(func(entry):return entry.uid==card.uid),"GUARD native drop on sidebar applies formal damage and cost exactly once "+type+" "+str([ui.notice,ui.view.guard_bind.value,ui.view.energy,c.payload.preview.damage]))
 sidebar=ui.find_child("SidebarGuardBindTarget",true,false)
 var card=ui.view.hand[0]
 if ui.card_faces.get(card.uid,false):await t.flip(card.uid)
 sidebar=ui.find_child("SidebarGuardBindTarget",true,false)
 var frozen=ui.game.export_snapshot()
 var point=t.card_point(card.uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 point=sidebar.get_global_rect().get_center();await t.move_mouse(point,true)
 t.check(is_instance_valid(ui.term_popup) and t.visible_text(ui.term_popup).contains("这张牌不能处理捕缚"),"GUARD invalid sidebar drag explains the actual incompatible target")
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.export_snapshot()==frozen,"GUARD invalid sidebar drop does not use card or resources")
 var data={"card_uid":card.uid,"free":false,"version":ui.view.version-1}
 sidebar=ui.find_child("SidebarGuardBindTarget",true,false)
 t.check(not sidebar.accept_card.call(data),"GUARD sidebar rejects stale drag versions")
 sidebar.receive_card.call(data);await t.frames()
 t.check(ui.game.export_snapshot()==frozen,"GUARD stale receiver cannot bypass submission checks")
 ui.game.state.guard_bind={};ui.render();await t.frames()
 t.check(ui.find_child("SidebarGuardBindTarget",true,false)==null and ui.find_child("GuardBindTarget",true,false)==null,"GUARD both drop receivers disappear when capture is removed")
