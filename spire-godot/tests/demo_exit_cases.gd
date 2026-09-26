extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

# Start at the already-cleared summit boundary; all choices use formal dispatch.
static func exit_fixture(g) -> void:
 g.state.phase="cleared";g.state.room="exit"
 g.state.completed_rooms=["summit","exit"];g.state.enemies=[];g.state.energy=0

static func run(t) -> void:
 continuation_recovery(t)
 var g=Game.new(42)
 g.state.shop_removals=3
 g.state.security=2
 exit_fixture(g)
 var a=preload("res://tests/link_cases.gd").at(g,"thigh_root")
 var b=preload("res://tests/link_cases.gd").at(g,"mid_thigh")
 g._install_link(a.id,b.id,8,"fixture")
 g._install_assembly("arm","long","fixture",2,2)
 g._install_special("crotch_rope_low","special_3_a")
 g.state.mana_max=150.0;g.state.mana=13.0
 var deck=g.state.deck.duplicate(true);var relics=g.state.relics.duplicate()
 var saved=g.export_snapshot();var twin=Game.new(7)
 t.check(twin.restore_snapshot(saved).ok,"DEMO exit snapshot restores pending choices")
 var old_seed=g.state.seed
 var c=t.find_action(g,"demo_continue")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==saved,"DEMO stale continuation rolls back without clearing equipment")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and t.action(twin,"demo_continue").ok,"DEMO continue commits through original command pipeline")
 t.check(g.state.security==2 and twin.state.security==2,"DEMO continuation preserves cumulative prison security after restore")
 var actual=g.export_snapshot();var restored=twin.export_snapshot()
 actual.erase("version");restored.erase("version")
 t.check(actual==restored and g.state.seed!=old_seed and g.state.room=="tower_bottom" and g.state.demo_cycle==1 and g.state.shop_removals==3 and g.Services.Data.removal_price(g.state.shop_removals)==90,"DEMO continuation creates reproducible tower while retaining progressive removal price")
 t.check(g.state.deck==deck and g.state.relics==relics and g.state.mana==150 and g.state.mana_max==150 and g.action_targets().is_empty() and g.state.composites.is_empty() and g.state.links.is_empty() and g.state.special_equipment.is_empty(),"DEMO preserves progression, removes all equipment structures and fills actual mana maximum")
 t.check(g.validate()=="" and twin.restore_snapshot(g.export_snapshot()).ok,"DEMO continued run validates and restores")
 var before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,saved.version),saved.version).ok and g.state==before,"DEMO continuation cannot be replayed")
 for cycle in [1,2]:
  if cycle==2:
   exit_fixture(g)
   t.check(t.action(g,"demo_continue").ok and g.state.shop_removals==3,"DEMO second continuation opens final cycle without clearing removal count")
   t.check(g.state.security==2,"DEMO second continuation also retains cumulative security")
  var scale=1.5 if cycle==1 else 2.0
  # This fixture retains security 2 and generates enemies at the ordinary tower entry:
  # the current rule adds 10 HP after cycle scaling, including custom HP and summons.
  var security_bonus=10.0
  t.check(g.state.security==2 and g.state.map_region=="tower" and g.state.room=="tower_bottom","DEMO health fixture retains security two at the new tower entry")
  g.state.enemies=[]
  var boss=g._append_enemies([{"type":"six_bind","grade":2}])[0]
  t.check(boss.hp==200*scale+security_bonus and boss.max_hp==200*scale+security_bonus,"DEMO boss health scales its base before adding retained security health")
  var heap=g._append_enemies([{"type":"rope_heap","grade":2}])[0]
  var basis=heap.hp/2
  g._split_enemy(heap,basis)
  var children=g.state.enemies.filter(func(e):return e.get("spawned_from","")==heap.id)
  t.check(children.size()==3 and children[0].max_hp==basis and children[1].max_hp==ceilf(basis/2),"DEMO split inheritance is not scaled twice")
  var custom=g._append_enemies([{"type":"rope","grade":1,"hp":10}])[0]
  t.check(custom.max_hp==10*scale+security_bonus,"DEMO custom encounter health scales before adding retained security health")
  var master=g._append_enemies([{"type":"puppeteer","grade":2}])[0]
  var doll=g.Puppets.owned(g,master)
  g.Puppets.execute(g,master,{"kind":"puppet_mend"})
  t.check(doll.max_hp==15*scale+security_bonus+5 and g.Puppets.validate(g,g.state.enemies,scale)=="","DEMO summon base scales, security applies once and fixed healing remains five")
 exit_fixture(g)
 t.check(g.command_facts().filter(func(c):return c.payload.kind!="item_discard").size()==1 and g.command_facts()[0].payload.kind=="demo_end","DEMO third exit offers only end")
 t.check(not t.action(g,"demo_continue").ok and t.action(g,"demo_end").ok and g.state.demo_finished and g.command_facts().is_empty(),"DEMO final end closes run without a fourth cycle")
 var result=twin.restore_snapshot(g.export_snapshot())
 t.check(result.ok,"DEMO finished run persists: "+str(result))
 before=twin.export_snapshot()
 for cycle in [-1,3,1.5]:
  var bad=before.duplicate(true);bad.demo_cycle=cycle
  t.check(not twin.restore_snapshot(bad).ok and twin.state==before,"DEMO corrupt cycle rejected atomically")

 g=Game.new(42)
 t.check(g.state.security==0,"DEMO genuinely new game resets cumulative prison security")
 g.state.relic_seen=g.Relics.REWARDS.duplicate()
 var relic=g.RelicRewards.offer(g,"boss")
 t.check(g.Relics.TYPES[relic].rarity=="boss" and relic not in g.state.relics,"DEMO boss draws only its own unowned relic pool")
 g.state.relics=g.Relics.BOSS_POOL.duplicate()
 t.check(g.RelicRewards.offer(g,"boss")==g.Relics.FALLBACK,"DEMO exhausted boss pool uses rolling log")

static func continuation_recovery(t) -> void:
 for posture in ["stand","sit","lie"]:
  for pressure in [0.0,25.0,40.0,80.0]:
   var g=Game.new(42);exit_fixture(g)
   g.state.posture=posture;g.state.pressure=pressure
   var before=g.export_snapshot();var c=t.find_action(g,"demo_continue")
   t.check(c.valid and c.detail.contains("快感降低40") and c.detail.contains("站立"),"DEMO continuation explains pressure relief and standing")
   t.check(g.state==before,"DEMO preview does not apply continuation recovery")
   t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"DEMO rejected continuation preserves pressure and posture")
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.pressure==maxf(0.0,pressure-40.0) and g.state.posture=="stand","DEMO continuing from every posture reduces pressure once with a zero floor")
   t.check(g.state.tick==before.tick and g.state.deck==before.deck and g.state.relics==before.relics,"DEMO recovery adds no turn and keeps deck and relics")
   var entry=g.export_snapshot()
   var result=g.restore_snapshot(g.restart_snapshot());var resumed=g.export_snapshot()
   entry.erase("version");resumed.erase("version")
   t.check(result.ok and resumed==entry,"DEMO new-stage SL keeps recovery without applying it again")
 var end=Game.new(42);exit_fixture(end);end.state.pressure=80.0;end.state.posture="lie"
 t.check(t.action(end,"demo_end").ok and end.state.pressure==80.0 and end.state.posture=="lie","DEMO ending at the exit does not receive continuation recovery")
