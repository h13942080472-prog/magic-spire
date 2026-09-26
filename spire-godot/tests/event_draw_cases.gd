extends RefCounted
const Game=preload("res://core/game.gd")
const Save=preload("res://tests/persistence_cases.gd")

# Room-boundary fixture avoids replaying unrelated fights; departure and arrival
# still use the real movement transaction and seeded event selection.
static func before_room(g, target: String) -> void:
 var parent=g.state.rooms.filter(func(room):return target in room.next)[0]
 g._discard_end();g.RelicEffects.end_combat(g)
 g.state.room=parent.id;g.state.phase="map";g.state.energy=0
 g.state.enemies=[];g.state.room_event={}
 if parent.id not in g.state.completed_rooms: g.state.completed_rooms.append(parent.id)

static func arrive(t,g) -> void:
 while g.state.phase=="travel":
  t.check(t.action(g,"travel_step").ok,"EVENT DRAW formal arrival commits")

static func run(t) -> void:
 var g=Game.new(42)
 var rooms=g.state.rooms.filter(func(room):return room.kind=="event")
 t.check(rooms.size()>=3 and rooms.all(func(room):return not room.has("event")) and g.state.event_seen.is_empty(),"EVENT DRAW new tower contains only unknown event rooms")
 var remaining=["smuggled_mana_potions","abandoned_storeroom"]
 g.state.event_seen=g.Events.Data.pool().filter(func(id):return id not in remaining)
 before_room(g,rooms[0].id)
 var before=g.export_snapshot()
 g.route_view();g.get_view();g.command_facts();g.room_description(rooms[0])
 t.check(g.state==before and not rooms[0].has("event"),"EVENT DRAW map and previews do not select or consume events")
 t.check(t.action(g,"depart",{"room":rooms[0].id}).ok and not rooms[0].has("event") and g.state.event_seen==before.event_seen,"EVENT DRAW departure does not select an event")
 var twin=Save.roundtrip(t,g,"before event arrival")
 arrive(t,g);arrive(t,twin)
 t.check(Save.same(g.state,twin.state) and g.state.room_event.id in remaining and g.state.event_seen.count(g.state.room_event.id)==1,"EVENT DRAW arrival selects an unseen event and restore reproduces it")
 var first=g.state.room_event.id
 Save.roundtrip(t,g,"after event arrival")
 before_room(g,rooms[1].id)
 t.action(g,"depart",{"room":rooms[1].id});arrive(t,g)
 t.check(g.state.room_event.id in remaining and g.state.room_event.id!=first and remaining.all(func(id):return id in g.state.event_seen),"EVENT DRAW another room cannot repeat an already encountered event")
 before_room(g,rooms[2].id)
 var history=g.state.event_seen.duplicate();var mana=g.state.mana;var deck=g.state.deck.duplicate(true)
 t.action(g,"depart",{"room":rooms[2].id});arrive(t,g)
 t.check(g.state.phase=="map" and g.state.completed_rooms.has(rooms[2].id) and g.state.room_event.is_empty() and g.room_data(g.state.room).event=="" and g.state.event_seen==history and g.state.mana==mana and g.state.deck==deck,"EVENT DRAW exhausted pool leaves a passable empty room without rewards or healing")
 Save.roundtrip(t,g,"empty event room")
 var good=g.export_snapshot()
 for invalid in [history+[history[0]],["missing_event"]]:
  var bad=good.duplicate(true);bad.event_seen=invalid
  t.check(not g.restore_snapshot(bad).ok and g.state==good,"EVENT DRAW corrupt history rejected without mutation")
 var bad=good.duplicate(true)
 var resolved=bad.rooms.filter(func(room):return room.kind=="event" and room.get("event","")!="")
 resolved[1].event=resolved[0].event
 t.check(not g.restore_snapshot(bad).ok and g.state==good,"EVENT DRAW duplicate resolved rooms rejected")
 g.Prison.return_to_tower(g)
 t.check(g.state.event_seen.is_empty() and g.state.rooms.filter(func(room):return room.kind=="event").all(func(room):return not room.has("event")),"EVENT DRAW prison tower regeneration resets history and event rooms")
 g.state.event_seen=history.duplicate()
 preload("res://tests/demo_exit_cases.gd").exit_fixture(g)
 t.check(t.action(g,"demo_continue").ok and g.state.event_seen.is_empty(),"EVENT DRAW continued stage resets event history")
 t.check(Game.new(42).state.event_seen.is_empty(),"EVENT DRAW new game clears history")
