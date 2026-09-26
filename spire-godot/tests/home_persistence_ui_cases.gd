extends RefCounted
const Store=preload("res://core/save_store.gd")
const Click=preload("res://tests/interface_ui_cases.gd")

const Home=preload("res://tests/home_ui_cases.gd")

static func run(t) -> void:
 var store=Store.new("res://build/home-ui-"+str(Time.get_ticks_usec()))
 await Home.boot(t,store)
 var ui=t.ui
 var initial=ui.game.export_snapshot()
 await Click.press(t,"HomeNewGame")
 t.check(not ui.show_home and ui.view.phase=="departure" and store.read_slot("tower").ok and store.read_slot("tower").snapshot.phase=="departure","HOME new game saves the actual opening-reward phase before entering the map")
 var saved=ui.game.export_snapshot()
 await t.open_menu();await Click.press(t,"ReturnHome")
 t.check(ui.show_home and ui.game.export_snapshot()==saved and not ui.map_auto_travel,"HOME returning pauses navigation without changing game")
 var legal=ui.view.display_facts.filter(func(c):return c.valid)
 if not legal.is_empty(): ui.command_router.emit(String(legal[0].payload.get("kind","")),legal[0])
 t.check(ui.game.export_snapshot()==saved,"HOME hidden gameplay submissions cannot advance the run")
 await Click.press(t,"HomeContinue")
 t.check(not ui.show_home and preload("res://tests/persistence_cases.gd").same(ui.game.state,saved),"HOME same-session continue restores the scene checkpoint")
 var bytes=FileAccess.get_file_as_string(store.path("tower"))
 await Home.boot(t,store);ui=t.ui
 t.check(ui.show_home and not ui.session_started and not ui.find_child("HomeContinue",true,false).disabled and FileAccess.get_file_as_string(store.path("tower"))==bytes,"HOME existing save is inspected without auto loading or overwriting")
 await Click.press(t,"HomeContinue")
 t.check(not ui.show_home and preload("res://tests/persistence_cases.gd").same(saved,ui.game.state),"HOME continue restores exact saved progress")
 await t.open_menu();await Click.press(t,"ReturnHome")
 t.root.size=Vector2i(1280,720);await t.frames()
 var home=ui.find_child("GameHome",true,false)
 t.check(home.get_children().all(func(n):return not n is Control or home.get_global_rect().encloses(n.get_global_rect())),"HOME controls remain in logical 16:9 frame after resize")
 var unchanged=ui.game.export_snapshot()
 ui.display_settings.save_error="显示设置保存失败：测试写入错误。"
 ui.render();await t.frames()
 home=ui.find_child("GameHome",true,false)
 var notice=ui.find_child("HomeSettingsSaveNotice",true,false)
 var disclaimer=ui.find_child("HomeDisclaimer",true,false)
 t.check(notice!=null and notice.is_visible_in_tree() and notice.text==ui.display_settings.save_error and home.get_global_rect().encloses(notice.get_global_rect()) and notice.get_global_rect().end.y<=disclaimer.get_global_rect().position.y,"HOME nonempty settings save error stays inside the frame above the disclaimer")
 t.check(ui.game.export_snapshot()==unchanged,"HOME displaying a settings-save failure does not change gameplay")
 ui.display_settings.save_error="";ui.render();await t.frames()
 await t.capture("ui-103-home-continue.png")
 t.root.size=Vector2i(1600,900);await t.frames()
 ui.persistence_enabled=false;ui.feedback_duration=0.04
 await service_resume(t)

static func service_resume(t) -> void:
 var store=Store.new("res://build/home-service-ui-"+str(Time.get_ticks_usec()))
 for kind in ["shop","treasure"]:
  var g=preload("res://core/game.gd").new(42)
  g.state.room=g.state.rooms.filter(func(room):return room.kind==kind)[0].id
  g.Services.start(g)
  if kind=="shop":
   var offer=g.command_facts().filter(func(c):return c.group=="service" and c.valid)[0]
   t.check(g.dispatch(g.command(offer.payload,g.state.version),g.state.version).ok,"HOME shop fixture includes already-purchased stock")
  t.check(store.write_game(g).ok,"HOME service-room progress saved")
  var before=g.restart_snapshot()
  var bytes=FileAccess.get_file_as_string(store.path("tower"))
  await Home.boot(t,store)
  var ui=t.ui
  for name in ["HomeContinue","HomeNewGame","HomeTutorial","HomePractice","HomeOptions","HomeQuit","HomeSaves"]:
   var button=ui.find_child(name,true,false)
   t.check(button!=null and button.is_visible_in_tree(),"HOME service save cannot interrupt creation of "+name)
  t.check(not ui.find_child("HomeContinue",true,false).disabled and t.visible_text(ui).contains("魔力商店" if kind=="shop" else "遗物宝箱"),"HOME service save summary readable with enabled continue")
  t.check(FileAccess.get_file_as_string(store.path("tower"))==bytes,"HOME reading service save leaves disk untouched")
  if kind=="shop": await t.capture("ui-home-shop-save-fixed.png")
  await Click.press(t,"HomeContinue")
  t.check(not ui.show_home and ui.view.phase==kind and preload("res://tests/persistence_cases.gd").same(before,ui.game.state),"HOME native continue restores exact room, mana and sold stock")
  if kind=="shop":
   var leave=ui.find_child("ShopLeave",true,false)
   t.check(ui.find_child("RoomServicePanel",true,false)!=null and leave!=null and not leave.disabled,"HOME restored shop keeps its actual service controls")
   await Click.press(t,"ShopLeave")
  else:
   var next=ui.find_child("RewardContinue",true,false)
   t.check(ui.view.reward_panel.active and ui.find_child("BattleRewards",true,false)!=null and next!=null and not next.disabled,"HOME restored treasure keeps its actual reward controls")
   await Click.press(t,"RewardContinue")
  t.check(ui.view.phase!=kind and ui.game.state.completed_rooms.has(before.room),"HOME restored room can be completed through a real UI command: "+kind)
 t.ui.persistence_enabled=false;t.ui.feedback_duration=0.04
 var finished=preload("res://core/game.gd").new(42)
 preload("res://tests/demo_exit_cases.gd").exit_fixture(finished)
 finished.state.demo_finished=true
 t.check(store.write_game(finished).ok,"HOME saves finished demo")
 await Home.boot(t,store)
 t.check(t.ui.find_child("HomeContinue",true,false).disabled and not t.ui.save_failed and not t.ui.save_suspended and t.visible_text(t.ui).contains("本次demo已结束"),"HOME finished save is unavailable without being treated as corruption")
 await Click.press(t,"HomeNewGame")
 t.check(t.ui.view.demo_cycle==0 and not t.ui.view.demo_finished and not t.ui.show_home,"HOME new game after completion starts normal first cycle")
 t.ui.persistence_enabled=false;t.ui.feedback_duration=0.04
