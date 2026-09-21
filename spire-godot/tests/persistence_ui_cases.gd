extends RefCounted
const Store=preload("res://core/save_store.gd")
const Cases=preload("res://tests/persistence_cases.gd")

static func boot(t,store) -> void:
 var old=t.ui
 t.root.remove_child(old);old.queue_free()
 t.ui=load("res://main.tscn").instantiate()
 t.ui.game_factory=preload("res://tests/game_fixture.gd")
 t.ui.game=t.ui.game_factory.new()
 t.ui.saves=store
 t.root.add_child(t.ui)
 await t.frames()
 # Startup now waits on the home screen; use its explicit entry before save cases.
 if t.ui.save_summaries.tower.available:
  await preload("res://tests/interface_ui_cases.gd").press(t,"HomeContinue")
 elif not store.has_files("tower"):
  await preload("res://tests/interface_ui_cases.gd").press(t,"HomeNewGame")
 else:
  await preload("res://tests/interface_ui_cases.gd").press(t,"HomeSaves")

static func button(t,name: String) -> void:
 if name=="OpenSaves": await t.open_menu()
 var control=t.ui.find_child(name,true,false)
 t.check(control!=null and not control.disabled,"SAVE UI available real button "+name)
 if control==null or control.disabled: return
 var point=control.get_global_rect().get_center()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)

# 存档面板自己的“返回游戏”按钮执行的就是这两步；面板是遮罩，画线/拖动前必须先离开它。
static func close_saves(t) -> void:
 t.ui.show_saves=false
 t.ui._refresh_drawers()
 await t.frames()

# docs/spec/save-fixed-points.md「证据入口」：三条非进度写盘保留（本函数覆盖 T3 新局替换与 T4 手动按钮，
# T2 线稿的真手势覆盖在 route_ui_cases），固定点提交才写盘，非固定点一律不写。
static func explicit_and_checkpoint_writes(t) -> void:
 var ui=t.ui
 var store=ui.saves
 var restarted=store.writes
 ui.restart(42);await t.frames()
 t.check(store.writes==restarted+1 and store.read_slot("tower").ok,"SAVE UI the explicit new run still replaces the save")
 await button(t,"OpenSaves")
 var manual=store.writes
 await button(t,"SaveCurrent")
 t.check(store.writes==manual+1 and store.read_slot("tower").snapshot==ui.game.restart_snapshot(),"SAVE UI the explicit button writes the current scene start")
 t.check(ui.save_summaries.tower.available,"SAVE UI the explicit write keeps a readable summary")
 await close_saves(t)
 var writes=store.writes
 ui.game.state.phase="prepare"
 ui.game.state.prepare_left=3
 ui.game.state.wall="normal"
 ui.render();await t.frames()
 var committed=await t.click("finish_prepare")
 var saved=store.read_slot("tower")
 t.check(committed and String(ui.view.phase)!="prepare","SAVE UI a real preparation finish leaves its phase")
 t.check(store.writes==writes+1,"SAVE UI the checkpoint commit writes exactly once")
 t.check(saved.ok and saved.snapshot==ui.game.restart_snapshot() and String(saved.snapshot.phase)==String(ui.game.state.phase),"SAVE UI the checkpoint commit writes the scene start of its write moment")
 var file_bytes=Cases.text_at(store.path("tower"))
 var file_time=Cases.modified(store.path("tower"))
 var graph=ui.find_child("TowerRoute",true,false)
 var route=ui.view.route.filter(func(room):return room.status=="available")
 t.check(graph!=null and not route.is_empty(),"SAVE UI the post-checkpoint map offers a real destination")
 if graph!=null and not route.is_empty():
  graph.buttons[route[0].id].pressed.emit()
  await t.frames()
  t.check(String(ui.view.phase)=="travel","SAVE UI the post-checkpoint map command commits: "+String(ui.view.phase))
  t.check(store.writes==writes+1 and Cases.text_at(store.path("tower"))==file_bytes and Cases.modified(store.path("tower"))==file_time,"SAVE UI a post-checkpoint non-point commit never writes again")

static func run(t) -> void:
 var store=Cases.WatchStore.new("res://build/save-ui-"+str(Time.get_ticks_usec()))
 await boot(t,store)
 var ui=t.ui
 t.check(store.read_slot("tower").ok and not ui.save_failed,"SAVE UI first startup saves actual initial run")
 var main_bytes=Cases.text_at(store.path("tower"));var main_time=Cases.modified(store.path("tower"))
 var backup_bytes=Cases.text_at(store.path("tower")+".bak");var backup_time=Cases.modified(store.path("tower")+".bak")
 var writes=store.writes
 t.check(await t.click("end") and ui.game.state.phase=="battle","SAVE UI a sampled battle turn commits without leaving the battle")
 t.check(store.writes==writes and Cases.text_at(store.path("tower"))==main_bytes and Cases.modified(store.path("tower"))==main_time,"SAVE UI a non-fixed-point turn never writes the primary")
 t.check(Cases.text_at(store.path("tower")+".bak")==backup_bytes and Cases.modified(store.path("tower")+".bak")==backup_time,"SAVE UI a non-fixed-point turn never writes the backup")
 await t.open_menu();await button(t,"QuickSL")
 t.check(ui.game.state.round==1 and ui.game.state.card_chain.is_empty() and not ui.show_menu and not is_instance_valid(ui.enemy_feedback),"SAVE UI native quick SL restores round one and closes transient UI")
 t.check(store.writes==writes and Cases.text_at(store.path("tower"))==main_bytes,"SAVE UI quick SL never rewrites the disk")
 var saved=ui.game.restart_snapshot();var file_before=FileAccess.get_file_as_string(store.path("tower"))
 await t.flip(ui.view.hand[0].uid)
 ui.render();await t.frames()
 t.check(FileAccess.get_file_as_string(store.path("tower"))==file_before,"SAVE UI flipping and rendering never write save")
 var c=ui.view.candidates[0];ui._submit(c,ui.view.version-1);await t.frames()
 t.check(FileAccess.get_file_as_string(store.path("tower"))==file_before and store.writes==writes,"SAVE UI rejected stale action never overwrites save")
 await boot(t,store);ui=t.ui
 var disk=store.read_slot("tower")
 t.check(disk.ok and Cases.same(ui.game.state,saved) and ui.game.state.version>disk.snapshot.version,"SAVE UI new scene automatically continues the last fixed point without taking turn")
 await button(t,"OpenSaves")
 t.check(t.visible_text(ui.layout).contains("存档与继续游戏") and ui.find_child("ContinuePractice",true,false).disabled,"SAVE UI missing practice slot has visible reason and disabled continue")
 await t.capture("ui-56-save-menu.png")
 await button(t,"ContinueTower")

 ui.restart(42,true,"component_links");await t.frames()
 t.check(FileAccess.get_file_as_string(store.path("tower"))==file_before and store.read_slot("practice").ok,"SAVE UI starting practice preserves tower file")
 var practice=ui.game.export_snapshot()
 await boot(t,store);ui=t.ui
 t.check(not ui.view.practice,"SAVE UI default startup prefers tower over practice")
 await button(t,"OpenSaves");await button(t,"ContinuePractice")
 t.check(Cases.same(practice,ui.game.state) and ui.view.practice,"SAVE UI continue practice restores actual components and equipment")

 ui.restart(42);ui.game.state.phase="prepare";ui.game.state.prepare_left=3;ui.game.state.wall="normal"
 var a=ui.game.add_fixture("wrist",8,10,true);ui.game.add_fixture("wrist",8,10,true);var target=ui.game.add_fixture("wrist",8,10,true)
 ui.game._gain_card("double_unlock");var card=ui.game.state.discard.pop_back();ui.game.state.hand.append(card)
 ui.render();await t.frames()
 saved=ui.game.restart_snapshot()
 var writes_before=store.writes
 await button(t,"OpenSaves");await button(t,"SaveCurrent");await close_saves(t)
 t.check(store.writes==writes_before+1 and store.read_slot("tower").snapshot==saved,"SAVE UI the explicit write freezes the scene entry before the chain")
 c=ui.actions.find("card",{"uid":card.uid,"slot":"wrist","target":a.id})
 await t.start_drag(card.uid,"wrist");await t.release_target(await t.reveal_drop_target(c.id))
 t.check(not ui.view.card_chain.is_empty() and store.writes==writes_before+1 and store.read_slot("tower").snapshot==saved,"SAVE UI a pending continuation is not a progress point and keeps the frozen entry")
 await boot(t,store);ui=t.ui
 t.check(ui.view.card_chain.is_empty() and ui.view.energy==3 and Cases.same(saved,ui.game.state),"SAVE UI partial card is undone when scene restarts")
 c=ui.actions.find("card",{"uid":card.uid,"slot":"wrist","target":a.id})
 await t.start_drag(card.uid,"wrist");await t.release_target(await t.reveal_drop_target(c.id))
 t.check(not ui.view.card_chain.is_empty(),"SAVE UI replay first hit from restored scene")
 await t.capture("ui-57-resumed-card.png")
 t.check(await t.click("chain",{"target":target.id}) and ui.view.card_chain.is_empty() and ui.view.energy==2,"SAVE UI resumed second hit no duplicate charge")

 ui.restart(42);preload("res://tests/event_cases.gd").arrive(ui.game,"binding_cleric");ui.render();await t.frames()
 var event_entry=ui.game.restart_snapshot()
 await button(t,"OpenSaves");await button(t,"SaveCurrent");await close_saves(t)
 t.check(store.read_slot("tower").snapshot==event_entry,"SAVE UI the explicit write freezes the event entry before the choice")
 t.check(await t.click("event",{"action":"choose","choice":"purify"}),"SAVE UI current event enters its card-removal stage")
 saved=ui.game.restart_snapshot()
 t.check(store.read_slot("tower").snapshot==event_entry,"SAVE UI an event choice is not a progress point")
 await boot(t,store);ui=t.ui
 t.check(Cases.same(saved,ui.game.state),"SAVE UI event returns to its entry with original choices")
 t.check(await t.click("event",{"action":"choose","choice":"purify"}),"SAVE UI event choice can be replayed from entry")
 await preload("res://tests/event_ui_cases.gd").open_selection(t,"remove")
 var removal=ui.actions.select("event",{"action":"choose"})[0]
 var deck_before=ui.game.state.deck.size()
 await preload("res://tests/event_ui_cases.gd").press(t,ui.candidate_buttons[removal.id])
 t.check(ui.game.state.deck.size()==deck_before-1 and ui.view.room_event.stage=="result","SAVE UI resumed event removes the selected real card once")
 saved=ui.game.restart_snapshot()
 await boot(t,store);ui=t.ui
 t.check(Cases.same(saved,ui.game.state) and ui.game.state.deck.size()==deck_before,"SAVE UI reloading event undoes card removal with the choice")

 var backup=store.read_file(store.path("tower")+".bak").snapshot
 var file=FileAccess.open(store.path("tower"),FileAccess.WRITE);file.store_string("truncated");file.close()
 await boot(t,store);ui=t.ui
 t.check(Cases.same(backup,ui.game.state) and ui.save_notice.contains("备份"),"SAVE UI damaged primary visibly restores previous backup")
 await button(t,"OpenSaves");await t.capture("ui-58-save-recovery.png")
 var bad=JSON.parse_string(FileAccess.get_file_as_string(store.path("tower")+".bak"));bad.format=999
 file=FileAccess.open(store.path("tower"),FileAccess.WRITE);file.store_string(JSON.stringify(bad));file.close()
 file_before=FileAccess.get_file_as_string(store.path("tower"))
 await boot(t,store);ui=t.ui
 t.check(ui.show_saves and ui.save_failed and ui.save_suspended and ui.find_child("SaveCurrent",true,false).disabled,"SAVE UI incompatible file suspends automatic overwrite and explains it")
 t.check(FileAccess.get_file_as_string(store.path("tower"))==file_before,"SAVE UI failed startup preserves incompatible file")
 await t.capture("ui-59-save-incompatible.png")
 await button(t,"SaveReturnHome")
 t.check(ui.show_home and not await t.click("end") and FileAccess.get_file_as_string(store.path("tower"))==file_before,"SAVE UI failed continue remains on homepage and cannot overwrite incompatible file through hidden gameplay")
 ui.restart(42);await t.frames()
 t.check(not ui.save_suspended and not ui.save_failed and store.read_slot("tower").ok,"SAVE UI explicit restart creates a usable new save after incompatible file")
 # The file may change after an enabled Continue button was drawn. A damaged run identity is a
 # type error, not a missing key: the missing key is the accepted legacy save (persistence_cases).
 for damage in ["revision","structure","run_identity","corrupt"]:
  ui.restart(42);await t.frames()
  await button(t,"OpenSaves")
  saved=ui.game.export_snapshot()
  var invalid=saved.duplicate(true)
  if damage=="revision": invalid.erase("save_revision")
  elif damage=="structure": invalid.erase("mana")
  elif damage=="run_identity": invalid.initial_seed="42"
  var bytes="broken" if damage=="corrupt" else Store.pack(invalid)
  file=FileAccess.open(store.path("tower"),FileAccess.WRITE);file.store_string(bytes);file.close()
  if damage!="revision":
   file=FileAccess.open(store.path("tower")+".bak",FileAccess.WRITE);file.store_string("broken");file.close()
  await button(t,"ContinueTower")
  t.check(ui.show_home and not ui.show_saves and ui.find_child("GameHome",true,false)!=null and ui.save_failed and ui.save_suspended,"SAVE UI every unrecoverable load uses the homepage "+damage)
  t.check(ui.game.export_snapshot()==saved and FileAccess.get_file_as_string(store.path("tower"))==bytes,"SAVE UI failed load preserves both running state and original file "+damage)
  t.check(t.visible_text(ui.layout).contains(ui.save_notice) and ui.find_child("HomeNewGame",true,false)!=null,"SAVE UI homepage explains failure and offers a new game "+damage)
 ui.restart(42);ui.game.state.room="rest";ui.game._start_rest();ui.render();await t.frames()
 var rest_entry=ui.game.export_snapshot()
 await button(t,"OpenSaves");await button(t,"SaveCurrent");await close_saves(t)
 t.check(store.read_slot("tower").snapshot==rest_entry,"SAVE UI the explicit write freezes the rest entry before claiming")
 t.check(await t.click("rest_flask") and await t.click("end"),"SAVE UI uses a rest reward and advances a rest turn")
 await t.open_menu();await button(t,"QuickSL")
 t.check(ui.view.phase=="rest_choice" and Cases.same(ui.game.state,rest_entry),"SAVE UI quick SL restores the original fire reward window and all entry values")
 t.check(await t.click("rest_card",{"type":ui.game.state.rest_cards[0]}),"SAVE UI chooses a different fire reward after SL")
 await boot(t,store);ui=t.ui
 t.check(ui.view.phase=="rest_choice" and Cases.same(ui.game.state,rest_entry),"SAVE UI relaunch also restores the fire before claiming cards")
 await explicit_and_checkpoint_writes(t)
 # Subsequent suites never touch production or this fixture's files.
 ui.persistence_enabled=false;ui.save_suspended=false;ui.save_failed=false;ui.save_notice=""
