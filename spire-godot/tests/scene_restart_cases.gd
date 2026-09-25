extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Store=preload("res://core/save_store.gd")

static func run(t, equal: Callable) -> void:
 rest_entry(t,equal)
 var g=Game.new(42);var start=g.export_snapshot()
 var c=t.find_action(g,"attack",{"type":"strike","form":0,"enemy":g.state.enemies[0].id})
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"SL real attack commits")
 var played=g.export_snapshot()
 t.check(g.restart_snapshot()==start,"SL paid attack cannot overwrite first-turn checkpoint")
 t.check(t.action(g,"end").ok and g.state.round==2 and g.restart_snapshot()==start,"SL later rounds preserve original hand enemies resources and RNG")
 var before=g.export_snapshot();var checkpoint=g.restart_snapshot()
 t.check(not g.dispatch(g.command(c.payload,0),0).ok and g.state==before and g.restart_snapshot()==checkpoint,"SL rejected action leaves both live state and checkpoint unchanged")
 t.check(g.restore_snapshot(g.restart_snapshot()).ok and equal.call(g.state,start) and g.state.version>before.version,"SL returns to first turn with monotonic command version")
 t.check(t.action(g,"attack",{"type":"strike","form":0,"enemy":g.state.enemies[0].id}).ok and equal.call(g.state,played),"SL same action reproduces the original result and random state")
 var store=Store.new("res://build/scene-restart-"+str(Time.get_ticks_usec()))
 t.check(store.write_game(g).ok and store.read_slot("tower").snapshot==g.restart_snapshot(),"SL disk save stores the scene start rather than live combat")
 var resumed=Game.new(77)
 t.check(resumed.restore_snapshot(store.read_slot("tower").snapshot).ok and equal.call(resumed.state,start),"SL process recreation resumes first turn")
 # Scene transitions commit gains; shop purchases roll back together with payment.
 g=Game.new(42);g.state.room=g.state.rooms.filter(func(r):return r.kind=="shop")[0].id;g.Services.start(g)
 start=g.export_snapshot();c=t.find_action(g,"service",{"op":"take","index":0,"payment":"self"})
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.restart_snapshot()==start,"SL shop checkpoint precedes the first purchase")
 var purchased=g.state.deck.size()
 t.check(g.restore_snapshot(g.restart_snapshot()).ok and g.state.deck.size()==purchased-1 and g.state.mana==start.mana and not g.room_data(g.state.room).stock[0].taken,"SL shop resets price payment stock and inventory atomically")
 t.action(g,"service",{"op":"take","index":0,"payment":"self"});t.action(g,"service",{"op":"leave"})
 t.check(g.restart_snapshot().phase=="map" and g.restart_snapshot().deck.size()==purchased,"SL leaving the shop checkpoints completed purchases")
 g=preload("res://tests/prison_cases.gd").intake(t);start=g.export_snapshot()
 t.check(t.action(g,"end").ok and g.restart_snapshot()==start,"SL prison uses its entry turn checkpoint")
 g=Game.new(42)
 for enemy in g.state.enemies: enemy.hp=1
 t.action(g,"attack",{"type":"kick","form":1,"enemy":g.state.enemies[0].id})
 t.check(g.state.phase=="reward" and g.restart_snapshot()==g.state,"SL victory checkpoints frozen rewards instead of replaying a finished battle")

static func rest_entry(t, equal: Callable) -> void:
 for kind in ["rest_card","rest_rare","rest_flask","rest_begin"]:
  var g=Game.new(42);g.state.room="rest";g._start_rest()
  var start=g.export_snapshot()
  var payload={"type":g.state.rest_cards[0]} if kind=="rest_card" else {}
  var choice=t.find_action(g,kind,payload)
  t.check(g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and g.state.phase=="rest","SL rest enters its playable turn after "+kind)
  var selected=g.export_snapshot()
  t.check(g.restart_snapshot()==start,"SL reward choice and rest share the original entry checkpoint: "+kind)
  t.check(t.action(g,"end").ok and g.restart_snapshot()==start,"SL rest actions and later turns preserve the pre-reward entry: "+kind)
  var live=g.export_snapshot()
  t.check(not g.dispatch(g.command(choice.payload,start.version),start.version).ok and g.state==live and g.restart_snapshot()==start,"SL stale rest choice cannot change either state or entry")
  var store=Store.new("res://build/rest-restart-"+kind+"-"+str(Time.get_ticks_usec()))
  t.check(store.write_game(g).ok and store.read_slot("tower").snapshot==start,"SL disk save includes neither the rest reward nor its cost")
  var resumed=Game.new(77)
  t.check(resumed.restore_snapshot(store.read_slot("tower").snapshot).ok and equal.call(resumed.state,start),"SL relaunch restores offers, deck, resources, equipment, turn and RNG together")
  t.check(g.restore_snapshot(g.restart_snapshot()).ok and equal.call(g.state,start),"SL returns to the original rest reward menu")
  t.check(t.action(g,kind,payload).ok and equal.call(g.state,selected),"SL replay gives the same reward and opening effects exactly once")
  for step in range(g.B.REST_TURNS+1):
   if g.state.phase!="rest": break
   t.check(t.action(g,"end").ok,"SL rest can finish normally")
  t.check(g.state.phase=="map" and g.restart_snapshot()==g.state,"SL leaving rest establishes a new checkpoint with completed benefits")
