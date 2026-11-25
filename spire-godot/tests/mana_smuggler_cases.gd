extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const ShippedGame=preload("res://core/game.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Value=preload("res://data/restraint_value.gd")
const Pair="mana_smuggler_pair"

static func run(t) -> void:
 weak_pool(t)
 catch_and_escape(t)
 empty_bottle(t)
 humanoid_controls(t)

static func weak_pool(t) -> void:
 var pool=["reinforced_rope_trio","binding_box_plus_solo",Pair,"restraint_mech_pair"]
 var sampled={}
 for seed in range(8):
  var g=ShippedGame.new(seed);g.state.demo_cycle=1;g._restart_tower(true)
  var room=g.room_data(g.room_data("tower_bottom").next[0])
  t.check(t.action(g,"depart",{"room":room.id}).ok,"SMUGGLER uses normal tower travel before sampling the weak pool")
  while g.state.phase=="travel": t.action(g,"travel_step")
  var first=g.state.room_encounters[room.id]
  sampled[first]=true
  t.check(first in pool and g.validate()=="","SMUGGLER stage two opening is a valid fixed composition")
  if first=="reinforced_rope_trio":
   t.check(g.state.enemies.size()==3 and g.state.enemies.all(func(e):return e.type==g.ReinforcedRope.TYPE and e.max_hp>=23 and e.max_hp<=28),"SMUGGLER draw preserves the existing rope roster")
  var other=g.state.rooms.filter(func(r):return r.id!=room.id and r.get("pool","")=="ordinary")[0]
  g.state.completed_rooms=[room.id];g.state.room=other.id;g._start_battle()
  var second=g.state.room_encounters[other.id]
  sampled[second]=true
  t.check(other.encounter_selected=="weak" and second in pool and second!=first,"SMUGGLER second weak battle draws a different fixed composition")
 t.check(sampled.size()==pool.size(),"SMUGGLER all fixed groups can be drawn")

static func catch_and_escape(t) -> void:
 var g=Game.new(42,true,Pair)
 g.state.flask_mana=100.0
 var ids=g.state.enemies.map(func(e):return e.id)
 t.check(g.state.enemies.all(func(e):return e.hp==55 and e.max_hp==55) and g.state.enemies.map(func(e):return e.theft_limit)==[3,4],"SMUGGLER both have 55 HP and distinct theft counts")
 var old=g.export_snapshot()
 for enemy in old.enemies:
  enemy.max_hp=45.0;enemy.hp=32.0
 var loaded=Game.new(42,true,Pair)
 t.check(loaded.restore_snapshot(old).ok and loaded.state.enemies.all(func(e):return e.max_hp==45 and e.hp==32),"SMUGGLER existing fights keep their saved health")
 old.enemies[0].max_hp=46.0
 t.check(not loaded.restore_snapshot(old).ok and loaded.state.enemies[0].max_hp==45,"SMUGGLER rejects an unknown historical base health")
 for i in range(3):
  t.check(t.action(g,"end").ok,"SMUGGLER plays a real round with both thieves")
 t.check(g.state.flask_mana==40.0 and g._enemy(ids[0]).intent.kind=="smuggler_prepare" and g._enemy(ids[1]).intent.kind=="smuggler_steal","SMUGGLER short itinerary prepares while the other still steals")
 t.check(t.action(g,"end").ok and g.state.flask_mana==30.0 and g._enemy(ids[0]).stolen_mana==30.0 and g._enemy(ids[1]).stolen_mana==40.0,"SMUGGLER each holds its own exact theft amount")
 t.check(g.get_view().enemies[0].intent_icons.any(func(icon):return icon.detail.contains("将带走30魔力")),"SMUGGLER escape announces the actual amount")
 g._enemy(ids[0]).intent.delayed=true
 var twin=Save.roundtrip(t,g,"smugglers with delimited theft and a delayed escape")
 if twin!=null: Save.step_both(t,g,twin,"end")
 t.check(not g._enemy(ids[0]).gone and g._enemy(ids[0]).intent.kind=="smuggler_leave","SMUGGLER interruption preserves the escape for the following turn")
 var before=g.export_snapshot()
 var bad=before.duplicate(true)
 bad.enemies[0].theft_limit=4
 t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==before,"SMUGGLER rejects a changed member schedule on load")
 g._enemy(ids[0]).hp=1
 g.state.sure_cast=true
 t.check(t.action(g,"attack",{"type":"fireball","enemy":ids[0]}).ok and g._enemy(ids[0]).defeated and g.state.flask_mana==60.0,"SMUGGLER defeating one immediately returns only their stolen mana")
 t.check(t.action(g,"end").ok and g._enemy(ids[1]).gone and not g._enemy(ids[1]).defeated and g.state.flask_mana==60.0,"SMUGGLER other enemy escapes with its mana and no refund")

static func empty_bottle(t) -> void:
 var g=Game.new(42,true,Pair)
 g.state.flask_mana=6.5
 var ids=g.state.enemies.map(func(e):return e.id)
 t.check(t.action(g,"end").ok and g.state.flask_mana==0.0 and g._enemy(ids[0]).stolen_mana==6.5 and g._enemy(ids[1]).stolen_mana==0.0,"SMUGGLER actual balance limits theft without drawing from personal mana")
 var counts=ids.map(func(id):return g.state.equipment.filter(func(item):return item.source==id).size())
 t.check(counts==[1,2] and g.state.equipment.all(func(item):return Value.from_profile(item.grade,g.equipment_tier(item))==4),"SMUGGLER partial theft applies one restraint and a failed theft applies two")

static func humanoid_controls(t) -> void:
 var g=Game.new(42,true,Pair)
 var e=g.state.enemies[0]
 var plan=g.ManaSmuggler.restraints(g,1)
 var spec=g.EnemyPlans.application_spec(g,e,plan)
 t.check(g.Enemies.TYPES[e.type].humanoid and g.EnemyPlans.can_arrest(g,e) and spec.replace and spec.templates.all(func(type):return type not in g.Equipment.SHACKLES),"SMUGGLER humanoid replacement and arrest reuse the equipment pool")
 var fixture=g.EnemyPlans.application(["tape"],3,3)
 for i in range(90):
  if not g.Application.execute(g,fixture,"fixture").ok: break
 var target=g.state.equipment[0]
 target.durability=target.maximum*0.8
 t.check(g.EnemyPlans.can_affect_equipment(g,e) and g._plan(e).kind=="smuggler_steal","SMUGGLER a reinforcement target keeps the theft action available")
 g._enemy_operation(e,plan)
 t.check(g.equipment_tier(target)==3 and not g.EnemyPlans.has_equipment_space(g) and g._plan(e).kind=="capture","SMUGGLER reinforces on full slots and then queues ordinary arrest")
 for actor in g.state.enemies: actor.intent=g._plan(actor)
 e.intent.text="Arrest"
 var before=g.export_snapshot()
 var bad=before.duplicate(true)
 bad.enemies[0].intent.erase("delayed")
 bad.enemies[0].intent.extra=false
 t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==before,"SMUGGLER capture save rejects a missing shared intent field without mutating state")
 var twin=Save.roundtrip(t,g,"smuggler saturation arrest")
 if twin!=null: Save.step_both(t,g,twin,"end")
 t.check(g.state.phase=="captured" and g.state.capture.by==e.name,"SMUGGLER saturated arrest follows normal imprisonment")
 g=Game.new(42,true,Pair)
 for i in range(22):
  if not g.Application.execute(g,fixture,"fixture").ok: break
 e=g.state.enemies[0]
 e.intent.delayed=true
 g.state.round=g.B.ENEMY_LONG_BATTLE_ROUND
 t.check(g.EnemyPlans.long_battle_limit(g) and not g._finish_if_saturated() and not e.gone and e.intent.kind=="capture" and e.intent.delayed,"SMUGGLER long battles keep interruption while announcing humanoid arrest")
