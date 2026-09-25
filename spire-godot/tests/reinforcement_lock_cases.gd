extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func run(t) -> void:
 for durability in [8.0,9.0,10.0]:
  var g=Game.new(42,true,"binding_box_solo")
  g.state.equipment.clear()
  var item=g.add_fixture("ankle",durability,10,false,0,"belt")
  var enemy=g.state.enemies[0]
  t.check(g._can_tighten(item) and g.EnemyPlans.targets(g,enemy,"tighten").has(item),"REINFORCE lockable leather remains a target")
  g.EnemyPlans.execute_tighten_budget(g,enemy,{"budget":1})
  t.check(item.locked==(durability>8) and item.durability==item.maximum,"REINFORCE one budget either raises tier or locks and restores full durability")
  if durability==8:
   g.EnemyPlans.execute_tighten_budget(g,enemy,{"budget":1})
   t.check(item.locked,"REINFORCE next budget locks after reaching tier three")
  if durability==10:
   t.check(not g._can_tighten(item) and g.EnemyPlans.targets(g,enemy,"tighten").is_empty(),"REINFORCE full locked item cannot repeatedly consume lock budget")
 var g=Game.new(42,true,"binding_box_solo")
 g.state.equipment.clear()
 var tape=g.add_fixture("ankle",10,10,false,0,"tape")
 t.check(not g._reinforcement_locks(tape) and not g._can_tighten(tape),"REINFORCE non-lockable full tape has no extra reinforcement")
 g=Game.new(42,true,"guard")
 var item=g.add_fixture("ankle",10,10,false,0,"belt")
 var enemy=g.state.enemies[0]
 enemy.stage=4;enemy.intent={"kind":"tighten","target":item.id,"text":"加固拘束具","delayed":false}
 var candidate=t.find_action(g,"end")
 var before=g.export_snapshot()
 t.check(not g.dispatch(g.command(candidate.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"REINFORCE stale turn cannot lock equipment")
 t.check(g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok and g._equipment(item.id).locked,"REINFORCE formal enemy turn locks tier-three equipment")
