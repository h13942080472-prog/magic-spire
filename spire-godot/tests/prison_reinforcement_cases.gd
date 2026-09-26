extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func start(t, security: int=1):
 var g=Game.new(42,true,"guard")
 g.state.security=security-1;g.Guard.capture(g,g.state.enemies[0])
 t.check(t.action(g,"prison",{"action":"enter"}).ok,"REINFORCEMENTS formal prison entry")
 for i in range(g.state.prison.left): t.action(g,"end")
 quiet(g);g.state.posture="stand"
 t.check(t.action(g,"prison",{"action":"resist"}).ok,"REINFORCEMENTS formal patrol resistance")
 return g

static func quiet(g) -> void:
 g.state.pressure=0;g.state.guard_bind={}
 g.state.equipment.clear();g.state.composites.clear();g.state.links.clear();g.state.special_equipment.clear()
 for enemy in g.state.enemies:
  if not enemy.gone: enemy.intent={"kind":"idle","text":"停顿","delayed":true}

static func run(t) -> void:
 for security in [1,2,4]:
  var g=start(t,security)
  var before=g.export_snapshot()
  var status=g.get_view().statuses.filter(func(row):return row.id=="prison_reinforcements")
  t.check(status.size()==1 and status[0].value.contains("4回合") and status[0].category=="environment" and g.state==before,"REINFORCEMENTS begins at four and projection is read-only")
  var original=g.state.enemies[0].id
  for completed in range(1,4*(security+2)+1):
   quiet(g)
   var expected=mini(security+1,int(completed/4))
   t.check(t.action(g,"end").ok,"REINFORCEMENTS real completed round "+str(completed))
   t.check(g.state.enemies.size()==1+expected and g.state.prison.reinforcements==expected,"REINFORCEMENTS fourth-round boundary and shared encounter cap")
   if completed==4:
    var child=g.state.enemies.back()
    t.check(child.type=="guard" and child.grade==2 and child.hp==child.max_hp and child.max_hp==90 and child.stage==1 and child.acted_round==4 and child.intent.kind=="guard_sequence","REINFORCEMENTS factory and no action in birth round")
    var clone=Save.roundtrip(t,g,"reinforcement before next countdown")
    t.check(clone.state.prison.reinforcements==1,"REINFORCEMENTS save retains shared count")
    g._damage_enemy(g._enemy(original),10000,"magic","测试")
   if completed==5: t.check(g.state.phase=="battle" and g.state.enemies[0].gone,"REINFORCEMENTS field persists after original guard defeat")
  t.check(g.get_view().statuses.any(func(row):return row.id=="prison_reinforcements" and row.value=="已达上限"),"REINFORCEMENTS visibly stops at cap")
  before=g.export_snapshot()
  for corrupt in [-1,security+2,"1"]:
   var bad=before.duplicate(true);bad.prison.reinforcements=corrupt
   t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==before,"REINFORCEMENTS corrupt count restore is atomic")
 var g=start(t)
 quiet(g);g.state.posture="lie"
 for i in range(3):
  quiet(g);t.check(t.action(g,"end").ok,"REINFORCEMENTS enemy-first full turn")
 t.check(g.state.round==4 and g.state.enemies.size()==1,"REINFORCEMENTS enemy-first fourth round opening is too early")
 quiet(g);t.check(t.action(g,"end").ok and g.state.enemies.size()==2,"REINFORCEMENTS enemy-first fourth completion summons once")
 g=start(t);quiet(g)
 for i in range(3):
  quiet(g);t.action(g,"end")
 quiet(g);g.state.enemies[0].hp=1;g.state.posture="stand"
 t.check(t.action(g,"attack",{"type":"strike","enemy":g.state.enemies[0].id}).ok and g.state.phase=="reward","REINFORCEMENTS victory before due time uses actual attack")
 t.check(not g.state.prison.has("reinforcements") and not g.get_view().statuses.any(func(row):return row.id=="prison_reinforcements"),"REINFORCEMENTS victory clears pending arrivals immediately")
 t.action(g,"reward",{"type":"skip"});t.action(g,"finish_prepare")
 t.check(g.state.phase=="prison" and g.state.enemies.is_empty() and not g.state.logs.any(func(row):return row.data.has("prison_reinforcements")),"REINFORCEMENTS reward and preparation never summon")
 var practice=Game.new(42,true,"guard")
 t.check(not practice.Prison.reinforcements_active(practice),"REINFORCEMENTS ordinary guard practice excluded")
 g=start(t)
 for i in range(3):
  quiet(g);t.action(g,"end")
 quiet(g)
 var before=g.export_snapshot()
 var candidate=t.find_action(g,"end")
 t.check(not g.dispatch(g.command(candidate.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"REINFORCEMENTS stale end cannot advance or summon")
 var clone=Save.roundtrip(t,g,"one turn before reinforcements")
 Save.step_both(t,g,clone,"end")
 t.check(g.state.prison.reinforcements==1 and g.state.enemies.size()==2,"REINFORCEMENTS restored fourth turn spawns exactly once")
 var count=g.state.enemies.size();g.Prison.tick_reinforcements(g)
 t.check(g.state.enemies.size()==count,"REINFORCEMENTS repeated boundary check cannot duplicate arrival")
 before=g.export_snapshot()
 var bad=before.duplicate(true);bad.prison.erase("reinforcements")
 t.check(not g.restore_snapshot(bad).ok and g.state==before,"REINFORCEMENTS missing battle count rejected atomically")
 bad=before.duplicate(true);bad.enemies.back().reinforcement_round=3
 t.check(not g.restore_snapshot(bad).ok and g.state==before,"REINFORCEMENTS invalid arrival round rejected atomically")
 g.Guard.capture(g,g.state.enemies[0])
 t.check(g.state.phase=="captured" and g.state.prison.is_empty() and not g.Prison.reinforcements_active(g),"REINFORCEMENTS recapture clears old field")
