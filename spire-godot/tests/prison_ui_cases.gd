extends RefCounted
const Spatial=preload("res://tests/exploration_fixture.gd")
const Queries=preload("res://ui/target_queries.gd")

static func enter(t, security: int=1) -> void:
 await t.start_practice("Practice_guard")
 t.ui.game.state.security=security-1
 # Fast-forward only the enemy's published preparation fixture; all transitions use buttons.
 var e=t.ui.game.state.enemies[0]
 t.ui.game.state.guard_bind={"progress":100.0,"sources":{"guard":{"enemy":e.id,"energy":0}}}
 e.intent={"kind":"capture","text":"执行收押 · 可打断","delayed":false}
 t.ui.render();await t.frames()
 t.check(await t.click("end") and t.ui.view.phase=="captured","PRISON UI actual enemy action reaches intake")
 var scene=t.ui.view.capture.intake_scene
 t.check(t.visible_text(t.ui.layout).contains("警戒度 %d" % security) and not t.visible_text(t.ui.layout).contains("拘束具保底") and not scene.is_empty(),"PRISON UI intake keeps current security and exposes its one-time authored scene")
 t.check(scene.restraints.size()>=t.ui.view.capture.added.size() and scene.links.size()==t.ui.view.capture.links.size() and scene.toys.size()==t.ui.view.capture.special_added.size(),"PRISON UI intake receives concrete reusable prose for every installed equipment category")
 t.check(await t.click("prison",{"action":"enter"}) and t.ui.view.phase=="prison" and t.ui.view.prison.left==t.ui.game.B.PRISON_INTERVALS[t.ui.game.state.security-1],"PRISON UI real intake button starts the configured cell at every security")
 if security<5:
  var speech=t.ui.find_child("NpcSpeech",true,false)
  t.check(speech==null or not speech.visible or not t.visible_text(speech).contains("欢迎入住"),"PRISON UI cell entry does not replay a persistent intake dialogue")

static func run(t) -> void:
 await release_case(t)
 await surrender_case(t)
 var ui=t.ui
 await practice_cases(t)
 await punishment_case(t)
 await enter(t)
 t.check(ui.view.prison.left==16 and ui.card_buttons.size()==5 and ui.actor_targets.has("hero") and not ui.actor_targets.has("prison_door"),"PRISON UI cell has real cards and hero/door drag targets")
 t.check(t.visible_text(ui.layout).contains("巡视剩余 16 回合") and t.visible_text(ui.layout).contains("待探索 3"),"PRISON UI countdown and hidden vent are visible")
 await t.capture("ui-37-prison-cell.png")
 await collect(t)
 t.check(ui.view.prison.remaining==0 and "vent" in ui.view.prison.found and ui.view.items.size()==2,"PRISON UI exploration creates only two tools and vent")
 t.check(await t.click("end"),"PRISON UI replenish energy before changing posture and installing")
 t.check(await t.click("posture",{"dest":"sit","wall":false}),"PRISON UI sit before mounting hand tool")
 var item=ui.view.items.filter(func(i):return i.name=="尖锐的小石片")[0].id
 ui.show_items=true;ui.selected_item=item;ui.render();await t.frames()
 t.check(await t.click("item_install",{"item":item,"mount":"foot_wall"}),"PRISON UI discovered tool installs through same item action")
 ui.show_items=false;ui.render();await t.frames()
 var n=0
 while ui.view.phase=="prison" and n<20:
  t.check(await t.click("end"),"PRISON UI countdown progresses to patrol")
  n+=1
 t.check(ui.view.phase=="inspection" and ui.card_buttons.is_empty() and t.visible_text(ui.layout).contains("例行巡视"),"PRISON UI arrival closes hand and presents the patrol")
 var patrol_portrait=ui.find_child("PrisonGuardPortrait",true,false)
 var patrol_speech=ui.find_child("NpcSpeech",true,false)
 var patrol_event=ui.find_child("PrisonInspectionPanel",true,false)
 t.check(patrol_portrait!=null and patrol_portrait.texture==ui.Arena.Art.GUARD_PORTRAITS.guard_purple and patrol_event!=null and patrol_speech==null and t.visible_text(patrol_event).contains("例行巡视") and not t.visible_text(patrol_event).contains("魅魔警卫"),"PRISON UI patrol uses the purple guard inside its event page without a floating dialogue bubble")
 t.check(not t.visible_text(ui.layout).contains("仅可检查或反抗") and not t.visible_text(ui.layout).contains("处罚一次性执行"),"PRISON UI patrol omits repeated procedure explanations")
 t.check(await t.click("prison",{"action":"inspect"}),"PRISON UI reveal actual check result")
 t.check(t.visible_text(ui.layout).contains("一件也没少") and t.visible_text(ui.layout).contains("还敢在牢房里藏工具") and not t.visible_text(ui.layout).contains("清单齐全"),"PRISON UI mounted-tool finding uses concise in-world wording inside the event page")
 await t.capture("ui-38-prison-inspection.png")
 var mana_before=ui.view.mana
 t.check(await t.click("prison",{"action":"accept"}) and ui.view.items.size()==1 and ui.view.prison.checks==1 and ui.view.mana==maxf(0,mana_before-ui.game.B.OVERLOAD_MANA),"PRISON UI check removes installed tool, milks once and increments check once")
 t.check(ui.view.prison.narrative.contains("量杯") and t.visible_text(ui.layout).contains("精液"),"PRISON UI accepted patrol shows the authored hand-milking scene")
 t.check(await t.click("prison",{"action":"resume"}) and ui.view.prison.left==16,"PRISON UI resumes fresh patrol interval")
 Spatial.at_site(ui.game,"vent");ui.render();await t.frames()
 await preload("res://tests/exploration_ui_cases.gd").open_details(t,"place_4")
 t.check(ui.view.posture=="sit","PRISON UI retains seated posture after inspection")
 for i in range(3):
  t.check(await t.click("prison",{"action":"vent_kick"}),"PRISON UI seated kick advances actual vent")
  if i<2: t.check(await t.click("end"),"PRISON UI separate vent kicks across real turns")
 t.check(ui.view.prison.vent_hits==3 and ui.view.posture=="sit","PRISON UI final kick opens vent without standing requirement")
 await t.capture("ui-39-prison-vent.png")
 t.check(await t.click("prison",{"action":"vent_exit"}) and ui.view.phase=="map" and not ui.view.practice and ui.view.security==1,"PRISON UI vent exit returns to tower, keeping security")
 t.check(ui.view.route.size()==3 and ui.view.route.any(func(r):return r.id=="prison_rest" and r.status=="available") and ui.view.map_name=="监狱" and ui.view.room_name=="出发点","PRISON UI independent map shows the rest point as the sole next room")
 await t.capture("ui-40-prison-return.png")
 await exit_route(t)

 await enter(t)
 # Find the actual unlock draw, without manufacturing a UI-only card.
 # This branch tests successful door drag; casting suites separately test failure costs.
 # Fix the spell's mouth/gesture conditions, independent of randomized intake.
 # Retain actual draws and formal card submission.
 for slot in ["mouth","fingers"]:
  for equipment in ui.game.equipment_at(slot): equipment.durability=0
 ui.game._cleanup();ui.game.state.pressure=0
 Spatial.at_site(ui.game,"door");ui.game.state.posture="stand"
 # The door route needs an acquired uncommon card, not a starter card.
 ui.game._gain_card("unlock")
 ui.render();await t.frames()
 n=0
 while not ui.view.hand.any(func(c):return c.type=="unlock") and n<3:
  t.check(await t.click("end"),"PRISON UI draws through normal cell turns")
  n+=1
 var cards=ui.view.hand.filter(func(c):return c.type=="unlock")
 t.check(not cards.is_empty(),"PRISON UI unlock enters actual hand")
 if cards.is_empty(): return
 await preload("res://tests/exploration_ui_cases.gd").open_details(t,"place_1")
 var uid=cards[0].uid
 var original=JSON.stringify(ui.game.state)
 if not ui.card_faces.get(uid,false): await t.flip(uid)
 await t.drop_card_on_actor(uid,"prison_door")
 t.check(JSON.stringify(ui.game.state)==original,"PRISON UI free face cannot unlock door or silently switch effect")
 await t.flip(uid)
 var mana=ui.view.mana
 var point=t.card_point(uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 var door_hint=ui.find_child("DoorDragTarget",true,false)
 t.check(door_hint!=null and not ui.view.prison.door_open and ui.view.mana==mana,"PRISON UI legal door appears immediately as a drag target without payment")
 point=door_hint.get_global_rect().get_center() if door_hint!=null else ui.actor_targets.prison_door.get_global_rect().get_center()
 await t.move_mouse(point,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.view.prison.door_open and ui.view.mana==mana-10 and not ui.card_buttons.has(uid),"PRISON UI native door drag uses actual bound card and magic once")
 t.check(await t.click("prison",{"action":"door_exit"}) and ui.view.phase=="map","PRISON UI open door at sufficient speed escapes")

 await enter(t)
 await collect(t)
 t.check(not ui.view.items.any(func(i):return i.name=="传送符"),"SEAL UI no active generation")
 ui.game._gain_tool("return_seal") # Deferred/existing inventory fixture only.
 # This is the successful-use branch; actual intake can now restrict the fingers.
 for equipment in ui.game.equipment_at("fingers"): equipment.durability=0
 ui.game._cleanup()
 ui.render();await t.frames()
 var seal=ui.view.items.filter(func(i):return i.name=="传送符")[0]
 ui.show_items=true;ui.selected_item=seal.id;ui.render();await t.frames()
 var use=Queries.find(ui.view,"item",{"kind":"item_use","item":seal.id,"target":"hero"})
 var use_button=ui.candidate_buttons.get(use.key)
 t.check(use_button!=null and not use_button.disabled and use_button.text=="使用","SEAL UI exposes the formal direct-use button")
 t.check(use_button!=null and use.cost==0 and use.mana==0 and use_button.tooltip_text.contains("不耗能量或魔力") and use_button.tooltip_text.contains("手指或脚趾"),"SEAL UI explains zero-cost use and actual body conditions")
 await t.capture("ui-64-return-seal.png")
 var seal_mana=ui.view.mana
 var prison_end_restore=0.0
 if seal_mana<=ui.view.mana_max*0.5:
  for relic in ui.game.state.relics: prison_end_restore+=float(ui.game.Relics.TYPES[relic].modifiers.get("low_mana_end_restore",0.0))
 for relic in ui.game.state.relics: prison_end_restore+=float(ui.game.Relics.TYPES[relic].modifiers.get("battle_mana",0.0))
 var expected_seal_mana=minf(ui.view.mana_max,seal_mana+prison_end_restore)
 t.check(await t.click("item_use",{"item":seal.id,"target":"hero"}) and ui.view.phase=="map" and ui.view.room_name=="出发点" and ui.view.mana==expected_seal_mana,"SEAL UI actual item button leaves the cell and preserves the established low-mana prison-end relic hook")
 t.check(not ui.view.items.any(func(i):return i.id==seal.id),"SEAL UI consumed card disappears")
 await enter(t,5)
 t.check(ui.view.phase=="prison" and ui.view.prison.left==8 and not ui.view.display_facts.is_empty(),"TERMINAL UI five opens the ordinary cell with the shortest patrol and live actions")
 t.check(t.visible_text(ui.layout).contains("巡视剩余 8 回合") and not t.visible_text(ui.layout).contains("本次逃脱失败") and not t.visible_text(ui.layout).contains("高安全监室"),"TERMINAL UI five shows the cell screen without the removed ending")
 await t.capture("ui-65-security-five.png")
 await t.inspect_body("neck")
 var collar=ui._body_at("neck").equipment.filter(func(e):return e.lock_only)[0]
 var tile=ui.find_child("EquipmentCard_"+collar.id,true,false)
 t.check(tile!=null and t.visible_text(tile).contains("无耐久") and not t.visible_text(tile).contains("紧度") and not t.visible_text(tile).contains("耐久 1"),"COLLAR UI neck card shows lock state without numeric durability or tier")
 t.check(tile!=null and tile.find_children("*","ProgressBar",true,false).is_empty(),"COLLAR UI no durability progress bar")

static func practice_cases(t) -> void:
 var ui=t.ui
 for kind in ["prison_test","prison_blind"]:
  await t.start_practice("Practice_"+kind)
  t.check(ui.view.phase=="prison" and ui.view.posture=="lie" and ui.view.wall_position.at_wall and ui.view.prison.left==16,"PRISON UI menu directly opens lying practice "+kind)
  t.check(ui.game.occupied("eyes")==(kind=="prison_blind") and ui.view.practice_kind==kind,"PRISON UI menu selects correct vision setup")
  t.check(not ui.actor_targets.has("prison_door") and ui.card_buttons.size()==5 and ui.view.practice_hint.contains("无眼罩选择目的地"),"PRISON UI describes new playable destination controls")
  var payload=Spatial.approach(ui.game,"shard");ui.render();await t.frames()
  t.check(await t.click("prison",payload) and ui.view.prison.found.size()==1,"PRISON UI practice exploration button really discovers once")
  t.check(await t.click("end") and ui.view.prison.left==15,"PRISON UI practice end turn uses real patrol")
 await t.capture("ui-113-prison-practice.png")

static func exit_route(t) -> void:
 var ui=t.ui
 var original_seed=ui.view.seed
 # Isolate navigation from already-tested equipment restrictions.
 ui.game.state.equipment=[];ui.game.state.composites=[];ui.game.state.links=[];ui.game.state.special_equipment=[]
 ui.game.state.pressure=0;ui.game.state.posture="stand";ui.map_auto_travel=false
 ui.render();await t.frames()
 t.check(t.visible_text(ui.layout).contains("移动消息") and ui.view.map_name=="监狱" and ui.find_child("TowerRoute",true,false).region_name=="监狱","PRISON UI labels the independent map")
 t.check(await t.click("depart",{"room":"prison_rest"}),"PRISON UI selects the real rest node")
 while ui.view.phase=="travel": t.check(await t.click("travel_step"),"PRISON UI advances to rest")
 t.check(ui.view.phase=="rest_choice" and await t.click("rest_begin") and ui.view.rest_left==6,"PRISON UI route selects six-turn rest")
 t.check(await t.click("finish_rest"),"PRISON UI finishes rest through its existing control")
 t.check(await t.click("depart",{"room":"prison_gate"}),"PRISON UI selects the elite exit node")
 while ui.view.phase=="travel": t.check(await t.click("travel_step"),"PRISON UI advances to exit guards")
 t.check(ui.view.enemies.size()==ui.view.security and ui.view.enemies.all(func(e):return e.template=="guard"),"PRISON UI shows the security-sized guard encounter")
 for enemy in ui.game.state.enemies: enemy.hp=1.0
 ui.render();await t.frames()
 var reward_before=ui.view.reward_count
 t.check(await t.click("attack",{"type":"strike","enemy":ui.view.enemies[0].id}) and ui.view.phase=="reward" and ui.view.reward_count==reward_before+1,"PRISON UI guard victory offers one reward")
 t.check(t.visible_text(ui.layout).contains("继续后选择第10—11层") and ui.view.seed==original_seed,"PRISON UI reward explains destination before reseeding")
 t.check(await t.click("reward",{"type":"skip"}),"PRISON UI resolves exit reward once")
 if ui.view.phase=="pack":
  while ui.game.carried_items()>ui.game.item_capacity():
   ui.show_items=true;ui.render();await t.frames()
   t.check(await t.click("item_discard",{"item":ui.view.items[0].id}),"PRISON UI sorts excess reward inventory")
  ui.show_items=false;ui.render();await t.frames();t.check(await t.click("finish_pack"),"PRISON UI completes inventory sorting")
 t.check(ui.view.phase=="map" and ui.view.room_name=="选择出狱起点" and ui.view.tower_start_pending and ui.view.map_name=="塔路" and ui.view.seed!=original_seed and ui.view.route.size()>3,"PRISON UI returns to fresh tower after reward, without preparation")

static func punishment_case(t) -> void:
 await enter(t)
 var g=t.ui.game
 for item in g.state.special_equipment: item.remaining=0
 var lost_toy=g.state.special_equipment[0]
 lost_toy.durability=0;g._cleanup()
 var piece=g.state.equipment.filter(func(e):return e.slot=="wrist")[0]
 piece.durability=0;g._cleanup()
 var current=g.equipment_targets().map(func(e):return e.id)
 var quota=g.state.prison.baseline.filter(func(id):return id not in current).size()+g.B.PRISON_VIOLATION_EXTRA
 t.ui.render();await t.frames()
 while t.ui.view.phase=="prison":
  t.check(await t.click("end"),"PRISON UI violation timer uses actual turns")
 t.check(await t.click("prison",{"action":"inspect"}),"PRISON UI opens missing equipment report")
 t.check(t.visible_text(t.ui.layout).contains("%d件初级二档" % quota) and t.visible_text(t.ui.layout).contains("又拿来了2件初级性玩具") and not t.visible_text(t.ui.layout).contains("检查结束时会补满"),"PRISON UI displays separate missing quotas without reciting the later service steps")
 t.check(await t.click("prison",{"action":"accept"}),"PRISON UI accepts replacement punishment once")
 t.check(t.visible_text(t.ui.layout).contains("拘束具补回%d/%d件" % [quota,quota]) and t.visible_text(t.ui.layout).contains("性玩具补回2/2件") and not t.visible_text(t.ui.layout).contains("重新登记") and g.state.prison.baseline==g.equipment_targets().map(func(e):return e.id) and g.state.prison.special_baseline==g.state.special_equipment.map(func(e):return e.id) and g.state.special_equipment.all(func(item):return item.remaining==g.SpecialEquipment.TYPES[item.type].duration if g.SpecialEquipment.TYPES[item.type].duration>0 else item.remaining==0),"PRISON UI keeps the result concise while the refreshed manifests and batteries remain correct")

static func collect(t) -> void:
 # Arrival fixtures isolate discovery widgets and subsequent patrol/exit workflows.
 for name in t.ui.game.Prison.ACTIVE_DISCOVERIES:
  if name in t.ui.game.state.prison.found: continue
  var payload=Spatial.approach(t.ui.game,name);t.ui.game.state.energy=3
  t.ui.render();await t.frames()
  t.check(await t.click("prison",payload),"PRISON UI arrival discovers through real choice button")

static func surrender_case(t) -> void:
 t.ui.restart(42);await t.frames()
 var before=t.ui.game.export_snapshot()
 var button=t.ui.find_child("SurrenderButton",true,false)
 var end=t.ui.find_child("EndTurnButton",true,false)
 t.check(button!=null and end.size.y>=90 and t.ui.find_child("PostureChoices",true,false).get_children().all(func(control):return control.size.y<=48),"SURRENDER larger end turn and compact posture controls")
 await preload("res://tests/interface_ui_cases.gd").press(t,"SurrenderButton")
 t.check(button.text=="确定要投降吗" and t.ui.game.state==before,"SURRENDER first real click only requests confirmation")
 await t.capture("ui-surrender-confirm.png")
 await preload("res://tests/interface_ui_cases.gd").press(t,"SurrenderButton")
 t.check(t.ui.view.phase=="captured" and t.ui.view.security==1 and t.ui.find_child("PrisonIntakePanel",true,false)!=null and t.ui.find_child("SurrenderButton",true,false)==null,"SURRENDER second real click opens the one-time intake page")
 t.check(await t.click("prison",{"action":"enter"}) and t.ui.view.phase=="prison","SURRENDER intake page enters the cell through its sole formal choice")

static func release_case(t) -> void:
 await t.start_practice("Practice_prison_release_violation")
 var blocked=t.ui.game
 t.check(t.ui.view.phase=="captured" and not blocked.state.capture.baseline.is_empty() and not blocked.state.capture.special_baseline.is_empty(),"PRISON UI delay entry displays actual intake and registered equipment")
 t.check(await t.click("prison",{"action":"enter"}) and t.visible_text(t.ui.layout).contains("已服刑0／20回合"),"PRISON UI delay practice enters the first real prison turn")
 t.check(await t.click("end") and t.ui.view.phase=="prison" and blocked.state.prison.served_turns==1,"PRISON UI first practice turn cannot directly release")
 # Only accelerate this UI boundary case after verifying the real entry.
 # Rules coverage plays the full sentence; retain actual equipment and manifests.
 blocked.state.prison.served_turns=19
 blocked.state.equipment[0].durability=0;blocked._cleanup()
 t.ui.render();await t.frames()
 var patrol_left=blocked.state.prison.left
 t.check(await t.click("end") and t.ui.view.phase=="prison","PRISON UI due violation continues prison instead of opening map")
 t.check(t.visible_text(t.ui.layout).contains("已服刑20／28回合") and t.ui.view.prison.left==patrol_left-1,"PRISON UI displays delayed release with unchanged patrol cycle")
 t.check(blocked.state.prison.baseline==blocked.equipment_targets().map(func(e):return e.id) and not blocked.state.prison.baseline.is_empty(),"PRISON UI failed check retains the real replacement equipment")
 await t.start_practice("Practice_prison_release")
 var ui=t.ui
 t.check(ui.view.phase=="captured" and await t.click("prison",{"action":"enter"}),"PRISON UI release entry requires normal intake confirmation")
 t.check(t.visible_text(ui.layout).contains("已服刑0／20回合") and ui.view.prison.left==16,"PRISON UI shows full sentence and normal patrol at entry")
 for turn in range(20):
  t.check(await t.click("end"),"PRISON UI practice plays every actual sentence turn")
  if turn<19: t.check(not ui.view.tower_start_pending,"PRISON UI no premature practice release")
  if turn==15:
   t.check(ui.view.phase=="inspection","PRISON UI actual periodic check precedes release")
   for op in ["inspect","accept","resume"]: t.check(await t.click("prison",{"action":op}),"PRISON UI practice uses ordinary inspection buttons")
 t.check(ui.view.tower_start_pending,"PRISON UI full sentence and compliant check open start selection")
 var release_speech=ui.find_child("NpcSpeech",true,false)
 var release_portrait=ui.find_child("PrisonGuardPortrait",true,false)
 t.check(release_speech!=null and t.visible_text(release_speech).contains("手续办完了") and release_portrait!=null and release_portrait.texture==ui.Arena.Art.GUARD_PORTRAITS.guard_brown,"PRISON UI normal release opens the senior guard's nameless dialogue bubble")
 var strong_room=ui.game.state.rooms.filter(func(room):return room.get("pool","")=="strong")[0]
 t.check(ui.game.room_description(strong_room)=="普通战斗 · 强怪池。" and ui.view.route.filter(func(room):return room.id==strong_room.id)[0].icon=="battle","PRISON UI strong encounters retain normal battle icons and describe the stronger pool")
 t.check(ui.find_child("PrisonStartTitle",true,false)!=null and t.visible_text(ui.layout).contains("第10—11层非休息、非宝箱区域"),"PRISON UI start range and zero time visible")
 var starts=ui.view.route.filter(func(r):return r.status=="available")
 t.check(not starts.is_empty() and starts.all(func(r):return ui.game.Prison.start_room(ui.game.room_data(r.id))),"PRISON UI highlights all legal start nodes")
 var before=ui.game.export_snapshot()
 ui.render();await t.frames()
 t.check(ui.game.state==before,"PRISON UI route rendering stays read-only")
 t.check(await t.click("depart",{"room":starts[0].id}) and not ui.view.tower_start_pending and ui.game.state.travel_turns==0,"PRISON UI start button enters formal room")
