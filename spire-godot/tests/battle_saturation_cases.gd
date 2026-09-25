extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func run(t) -> void:
 long_battle_cases(t)
 arrest_next_turn(t)
 var g=Game.new(42)
 var before=g.state.duplicate(true)
 t.check(g.EnemyPlans.can_affect_equipment(g,g.state.enemies[0]),"SATURATION free capacity keeps a charging enemy relevant")
 t.check(g.state==before,"SATURATION availability leaves state and random counters unchanged")
 # Fill one actual enemy's complete pool using the shared installer.
 g.state.enemies.clear()
 g._spawn_enemies("rope_solo")
 var enemy=g.state.enemies[0]
 var spec=g.EnemyPlans.application(g.Enemies.TYPES.rope.install_pool,2,3)
 for i in range(200):
  if not g.Application.execute(g,spec,enemy.id).ok: break
 var piece=g.physical_pieces().filter(func(p):return p.template=="rope")[0]
 piece.durability=piece.maximum*0.7
 before=g.state.duplicate(true)
 t.check(not g.Application.can_apply(g,spec,enemy.id),"SATURATION fixture has no remaining installation positions")
 t.check(g.EnemyPlans.can_affect_equipment(g,enemy) and not g._finish_if_saturated(),"SATURATION reinforcement alone keeps battle running")
 t.check(g.state==before,"SATURATION reinforcement check is read-only")
 # Complete every legal reinforcement (including dependent shoulder restoration).
 for i in range(200):
  var targets=g.EnemyPlans.targets(g,enemy,"tighten")
  if targets.is_empty(): break
  g._enemy_operation(enemy,{"kind":"tighten","target":targets[0].id,"tier":3,"text":"加固"})
 t.check(not g.EnemyPlans.can_affect_equipment(g,enemy),"SATURATION fully installed and reinforced source has no remaining operation")
 var count=g.state.reward_count
 var hp=enemy.hp
 t.check(g._finish_if_saturated() and g.state.phase=="reward","SATURATION complete saturation enters reward")
 t.check(enemy.gone and not enemy.defeated and enemy.hp==hp,"SATURATION departure is not a defeat or damage")
 t.check(g.state.reward_count==count+1 and not g._finish_if_saturated() and g.state.reward_count==count+1,"SATURATION reward is issued only once")
 t.check(g.state.logs.back().data.get("battle_end","")=="saturated" and g.validate()=="","SATURATION result copy and final state are valid")
 # Locks use their own legal targets; unrelated low-tightness equipment does not count as reinforcement.
 g=Game.new(42)
 g.state.enemies.clear();g._spawn_enemies("lock_solo")
 enemy=g.state.enemies[0]
 piece=g._install_template("belt","wrist",4,10,false,"fixture")
 t.check(g.EnemyPlans.can_affect_equipment(g,enemy),"SATURATION an unlocked target keeps a lock enemy active")
 piece.locked=true
 t.check(not g.EnemyPlans.can_affect_equipment(g,enemy),"SATURATION lock source cannot borrow reinforcement capability")
 g._append_enemies([{"type":"rope","grade":1}])
 t.check(g.state.enemies.size()==2 and not g._finish_if_saturated(),"SATURATION another living enemy's capacity keeps the encounter running")
 g.state.enemies.back().gone=true
 enemy.intent={"kind":"lock","text":"上锁","delayed":false}
 before=g.state.duplicate(true)
 t.check(not g.dispatch(g.command({"kind":"card","uid":"forged"},g.state.version),g.state.version).ok and g.state==before,"SATURATION rejected commands cannot end battles")
 t.check(t.action(g,"end").ok and g.state.phase=="reward","SATURATION formal turn boundary ends battle before a targetless enemy action")
 # Saturated initial encounters finish without pretending a lock has been defeated.
 g=Game.new(42)
 g.state.room_encounters.entrance="lock_solo"
 g._start_battle()
 t.check(g.state.phase=="reward" and not g.state.enemies[0].defeated,"SATURATION encounter entry checks the current enemy roster")

static func exhaust(g, enemy: Dictionary) -> void:
 # Use the same real installation/replacement and reinforcement operations.
 # The bound is a test guard, never a rule or a scripted arrest threshold.
 for step in range(400):
  var progressed=false
  for plan in g.EnemyPlans.installation_intents(g,enemy):
   var spec=g.EnemyPlans.application_spec(g,enemy,plan)
   if not g.Application.can_apply(g,spec,enemy.id): continue
   g._enemy_operation(enemy,plan);progressed=true
  var targets=g.EnemyPlans.targets(g,enemy,"tighten")
  # Only sources that really reinforce use this helper's reinforcement pass.
  if g.Enemies.behavior(enemy.type) in ["six_bind","guard","drone","binding_box"] and not targets.is_empty():
   g._enemy_operation(enemy,{"kind":"tighten","target":targets[0].id,"tier":3,"text":"加固","delayed":false});progressed=true
  if not progressed: return

static func long_battle_fixture(t, count: int=20, tier: int=1, type: String="rope"):
 var g=Game.new(42)
 g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[]
 var spec=g.EnemyPlans.application(["rope","belt","tape","cable_tie"],1,tier)
 for i in range(count+20):
  if g.Cards.worn_count(g)>=count: break
  t.check(g.Application.execute(g,spec,"fixture").ok,"LONG BATTLE builds legal equipment through the shared installer")
 t.check(g.Cards.worn_count(g)==count,"LONG BATTLE fixture counts whole worn items")
 g.state.enemies=[];g._append_enemies([{"type":type,"grade":1}])
 g.state.round=15;g.state.order="first"
 for enemy in g.state.enemies: enemy.intent={"kind":"idle","text":"停顿","delayed":false}
 return g

static func long_battle_cases(t) -> void:
 var g=long_battle_fixture(t)
 g.state.round=14
 var before=g.export_snapshot()
 t.check(not g._finish_if_saturated() and g.state==before,"LONG BATTLE round fourteen does not withdraw even with twenty items")
 t.check(t.action(g,"end").ok and g.state.round==15 and g.state.phase=="reward","LONG BATTLE real round transition withdraws at fifteen")
 t.check(g.state.enemies.all(func(e):return e.gone and not e.defeated and e.hp==e.max_hp) and g.state.reward_count==1,"LONG BATTLE departure awards one victory without damage, defeat or split children")
 t.check(not g._finish_if_saturated() and g.state.reward_count==1,"LONG BATTLE victory cannot award twice")

 g=long_battle_fixture(t,19)
 t.check(not g.EnemyPlans.long_battle_limit(g) and not g._finish_if_saturated(),"LONG BATTLE nineteen low-tier items do not meet either equipment threshold")
 g=long_battle_fixture(t,13,3)
 t.check(not g.EnemyPlans.long_battle_limit(g),"LONG BATTLE total tightness thirty-nine is below threshold")
 t.check(g.Application.execute(g,g.EnemyPlans.application(["rope","belt","tape"],1,1),"fixture").ok,"LONG BATTLE adds one tier-one piece at the tightness boundary")
 t.check(g.Cards.worn_count(g)==14 and g.EnemyPlans.long_battle_limit(g) and g._finish_if_saturated(),"LONG BATTLE forty tightness wins even below twenty items")

 # Every registered nonhuman type, including machines and splitters, shares the rule.
 for type in Game.Enemies.TYPES:
  if Game.Enemies.TYPES[type].get("humanoid",false): continue
  g=long_battle_fixture(t,20,1,type)
  var amount=g.state.enemies.size()
  var actor=g.state.enemies[0]
  if g.CaptureBind.kind(g,actor)!="": g.CaptureBind.apply_bind(g,actor)
  t.check(g._finish_if_saturated() and g.state.phase=="reward" and g.state.enemies.size()==amount and g.state.enemies.all(func(e):return e.gone and not e.defeated) and g.state.guard_bind.is_empty(),"LONG BATTLE every nonhuman leaves without defeat spawns and releases capture: "+type)

 for encounter in ["six_bind_solo","iron_man_solo"]:
  g=long_battle_fixture(t)
  g.state.room_encounters[g.state.room]=encounter;g._spawn_enemies(encounter)
  before=g.export_snapshot()
  t.check(not g.EnemyPlans.long_battle_limit(g) and not g._finish_if_saturated() and g.state==before,"LONG BATTLE boss encounter exempts boss and all support units: "+encounter)
 g=long_battle_fixture(t)
 g.room_data(g.state.room).boss=true
 t.check(not g.EnemyPlans.long_battle_limit(g),"LONG BATTLE room-level boss flag excludes custom boss rosters")

 g=long_battle_fixture(t,20,1,"versatile")
 var human=g.state.enemies[0]
 human.intent.delayed=true
 var machine=g._append_enemies([{"type":"drone","grade":1}])[0]
 machine.intent=g._plan(machine);g.state.pressure=20
 before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"LONG BATTLE reading facts and view cannot trigger departure or arrest")
 t.check(not g.dispatch(g.command({"kind":"card","uid":"forged"},g.state.version),g.state.version).ok and g.state==before,"LONG BATTLE rejected action cannot trigger the limit")
 human=g._enemy(human.id);machine=g._enemy(machine.id)
 var result=t.action(g,"calm")
 human=g._enemy(human.id);machine=g._enemy(machine.id)
 t.check(result.ok and g.state.phase=="battle" and machine.gone and not human.gone and human.intent.kind=="capture" and g.state.guard_bind.is_empty(),"LONG BATTLE mixed roster keeps human fight active and prepares arrest without applying capture: "+str(result))
 t.check(human.intent.delayed,"LONG BATTLE first arrest preparation preserves an already interrupted ordinary intent")
 var twin=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"long battle arrest preparation")
 t.check(twin.state.enemies[0].intent.kind=="capture","LONG BATTLE announced arrest survives save and load")
 for attempt in range(2):
  # Freeze an actual interrupted intent; ordinary turn execution must honor it each time.
  human.intent.delayed=true
  t.check(not g._finish_if_saturated() and human.intent.delayed,"LONG BATTLE repeated threshold does not erase this turn's interruption")
  result=t.action(g,"end")
  human=g._enemy(human.id)
  t.check(result.ok and g.state.phase=="battle" and human.intent.kind=="capture" and not human.intent.delayed,"LONG BATTLE interrupted arrest prepares again on each later turn: "+str(result))
 result=t.action(g,"end")
 t.check(result.ok and g.state.phase=="captured" and g.state.reward_count==0,"LONG BATTLE next uninterrupted enemy action performs normal imprisonment: "+str(result))

 g=long_battle_fixture(t,20,1,"guard")
 human=g.state.enemies[0];human.intent=g._plan(human)
 before=human.intent.duplicate(true)
 t.check(not g._finish_if_saturated() and human.intent==before and human.intent.kind!="capture","LONG BATTLE existing humanoid capture mechanism keeps its original opening")

static func arrest_next_turn(t) -> void:
 var g=Game.new(42)
 g.state.enemies.clear();g._spawn_enemies("drone_solo")
 var enemy=g.state.enemies[0]
 exhaust(g,enemy)
 t.check(not g.EnemyPlans.can_affect_equipment(g,enemy),"ARREST drone fixture exhausts real installation and reinforcement capacity")
 var before=g.export_snapshot()
 t.check(not g._finish_if_saturated() and g.state==before,"ARREST mechanical saturation never grants victory or immediately captures")
 var target=g.state.equipment.filter(func(e):return e.template=="tape")[0]
 target.durability=target.maximum*0.8
 enemy.intent={"kind":"tighten","target":target.id,"tier":3,"text":"加固","delayed":false}
 t.check(g.EnemyPlans.can_affect_equipment(g,enemy),"ARREST a final real reinforcement still delays arrest")
 var round=g.state.round;var rewards=g.state.reward_count
 t.check(t.action(g,"end").ok and g.state.phase=="battle" and g.state.round==round+1,"ARREST completing the last reinforcement gives the next player turn")
 enemy=g._enemy(enemy.id)
 t.check(enemy.intent.kind=="capture" and not g.CaptureBind.has_bind(g),"ARREST announces capture without requiring an existing capture bar")
 before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"ARREST reading the capture announcement is pure")
 var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"saturated capture announcement")
 t.check(restored.state.enemies[0].intent.kind=="capture","ARREST current snapshot preserves the announced action")
 t.check(t.action(g,"end").ok and g.state.phase=="captured" and g.state.reward_count==rewards,"ARREST next enemy turn follows real imprisonment without rewards")
 t.check(g.state.capture.by==enemy.name and g.validate()=="","ARREST records the actual captor and valid prison result")
 g=Game.new(42);g.state.enemies.clear();g._spawn_enemies("drone_solo")
 enemy=g.state.enemies[0];exhaust(g,enemy)
 var ally=g._append_enemies([{"type":"rope","grade":1}])[0]
 before=g.export_snapshot()
 t.check(g.EnemyPlans.can_affect_equipment(g,ally) and g._plan(enemy).kind!="capture","ARREST another living enemy's actual equipment space postpones arrest")
 t.check(g.state.equipment==before.equipment,"ARREST planning cannot install equipment")
 ally.gone=true
 t.check(g._plan(enemy).kind=="capture","ARREST gone allies do not keep a saturated battle open")
 var box=Game.new(42);box.state.enemies.clear();box._append_enemies([{"type":"binding_box","grade":2}])
 var source=box.state.enemies[0]
 var plans=box.EnemyPlans.installation_intents(box,source)
 t.check(plans.filter(func(p):return p.pool=="composite").size()==source.carried_indices.size(),"ARREST box repertoire includes actual remaining carried composites")
 source.carried_indices.clear()
 t.check(box.EnemyPlans.installation_intents(box,source).all(func(p):return p.pool!="composite"),"ARREST consumed box inventory does not create phantom replacement capacity")
