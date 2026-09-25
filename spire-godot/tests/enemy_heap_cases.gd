extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func active(g) -> Array:
 return g.get_view().statuses.filter(func(s):return s.id.begins_with("turn_install_"))

static func run(t) -> void:
 skin_cases(t)
 var g=Game.new(42,true,"rope_heap_solo")
 var id=g.state.enemies[0].id
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and g.state.enemies[0].intent.kind=="turn_install" and active(g).is_empty(),"HEAP initial plan is readonly and does not activate effect early")
 var twin=Save.roundtrip(t,g,"heap first intent")
 Save.step_both(t,g,twin,"end")
 t.check(g.state.equipment.size()==1 and g.state.equipment[0].grade==1 and g.state.equipment[0].source==id and g.tier(g.state.equipment[0].durability,g.state.equipment[0].maximum)==2 and active(g).size()==1,"HEAP first pulse at next player start installs one basic tier two item and exposes source")
 Save.step_both(t,g,twin,"end")
 var plan=g._enemy(id).intent.duplicate(true)
 t.check(plan.kind=="equipment_batch" and plan.count==2 and not plan.tighten,"HEAP third action declares two installations")
 var prior_ids=g.physical_pieces().map(func(x):return x.id)
 twin=Save.roundtrip(t,g,"heap pair declaration")
 Save.step_both(t,g,twin,"end")
 t.check(g.state.equipment.size()+g.state.links.size()==5,"HEAP two installations and one separate next-round pulse")
 var pair=g.physical_pieces().filter(func(x):return x.id not in prior_ids and x.grade==2)
 var points=[]
 for piece in pair: points.append_array(g.Equipment.physical_points(piece))
 var unique={}
 for point in points: unique[point]=true
 t.check(pair.size()==2 and pair.all(func(x):return x.source==id and g.tier(x.durability,x.maximum)==2) and unique.size()==points.size(),"HEAP actual pair uses two distinct positions including real link contacts")
 plan=g._enemy(id).intent.duplicate(true)
 t.check(plan.tighten and plan.count==2 and plan.tier==3,"HEAP fourth action declares two reinforcements to tier three")
 # Change equipment after declaration; actual survivors determine both targets.
 for piece in pair: g._equipment(piece.id).durability=0
 g._cleanup()
 var survivors=g.physical_pieces().duplicate(true)
 twin=Save.roundtrip(t,g,"heap equipment removed before reinforcement")
 Save.step_both(t,g,twin,"end")
 var reinforced=survivors.filter(func(x):return g._equipment(x.id).durability>x.durability)
 points=[]
 for piece in reinforced: points.append_array(g.Equipment.physical_points(piece))
 unique={}
 for point in points: unique[point]=true
 t.check(reinforced.size()==2 and reinforced.all(func(x):return g.tier(g._equipment(x.id).durability,x.maximum)==3) and unique.size()==points.size() and g.validate()=="","HEAP reinforcement chooses two distinct surviving positions at execution")

 # A batch with one available reinforcement completes only that operation.
 g=Game.new(42,true,"rope_heap_solo");id=g.state.enemies[0].id
 var piece=g.add_fixture("wrist",4,10,false,0,"rope")
 var e=g._enemy(id)
 e.stage=4;e.intent=g._plan(e)
 twin=Save.roundtrip(t,g,"heap one reinforcement available")
 Save.step_both(t,g,twin,"end")
 t.check(g.tier(g._equipment(piece.id).durability,piece.maximum)==3 and g.physical_pieces().size()==1 and g._enemy(id).stage==5 and g.state.logs.any(func(l):return l.text.contains("完成1次加固")),"HEAP one available piece goes directly to tier three and the remaining attempt misses")
 g=Game.new(42,true,"rope_heap_solo");id=g.state.enemies[0].id
 piece=g.add_fixture("wrist",4,10,false,0,"rope")
 e=g._enemy(id);e.stage=4;e.intent=g._plan(e)
 piece.durability=0;g._cleanup()
 t.check(t.action(g,"end").ok and g.physical_pieces().is_empty() and g._enemy(id).stage==5 and g.state.logs.any(func(l):return l.text.contains("这次动作落空")),"HEAP removing the last piece makes the whole declared reinforcement batch miss")
 g=Game.new(42,true,"rope_heap_solo");id=g.state.enemies[0].id
 e=g._enemy(id);e.stage=4;e.intent=g._plan(e)
 t.check(e.intent.kind=="apply","HEAP no reinforcement target at generation selects its existing pair application")
 t.check(t.action(g,"end").ok and g.physical_pieces().size()==2 and g.physical_pieces().all(func(x):return x.grade==2 and x.template in g.Enemies.TYPES.rope_heap.install_pool and g.tier(x.durability,x.maximum)==2) and g._enemy(id).stage==5,"HEAP generated application preserves two middle-grade tier-two installs")

 # Exact threshold, nearest safe value, rounding, lethal precedence, and saved children.
 g=Game.new(42,true,"rope_heap_solo");id=g.state.enemies[0].id
 var hit=t.find_action(g,"attack",{"type":"strike","enemy":id})
 g._enemy(id).hp=48+hit.payload.damage+1
 t.check(t.action(g,"attack",{"type":"strike","enemy":id}).ok and not g._enemy(id).gone and g._enemy(id).hp==49,"HEAP above-half hit preserves parent")
 g._enemy(id).hp=48+hit.payload.damage
 t.check(t.action(g,"attack",{"type":"strike","enemy":id}).ok and g.state.enemies.size()==4,"HEAP exact half hit splits immediately")
 t.check(g.state.enemies.slice(1).map(func(x):return x.max_hp)==[48.0,24.0,24.0] and g.state.reward_count==0,"HEAP exact half inheritance and no premature reward")
 g=Game.new(42,true,"rope_heap_solo");id=g.state.enemies[0].id
 t.action(g,"end")
 hit=t.find_action(g,"attack",{"type":"strike","enemy":id})
 g._enemy(id).hp=47.5+hit.payload.damage
 var equipment=g.state.equipment.duplicate(true)
 t.check(t.action(g,"attack",{"type":"strike","enemy":id}).ok and g.state.enemies.slice(1).map(func(x):return x.max_hp)==[47.5,24.0,24.0],"HEAP full inherited health preserves fractions and halves round up only for small children")
 t.check(active(g).is_empty() and g.state.equipment==equipment and g.state.enemies.slice(1).all(func(x):return x.hp==x.max_hp and x.acted_round==g.state.round),"HEAP early split removes only source effect, preserves equipment and defers children")
 twin=Save.roundtrip(t,g,"heap split inheritance")
 before=g.export_snapshot()
 var invalid=before.duplicate(true);invalid.enemies[1].max_hp+=1
 t.check(not g.restore_snapshot(invalid).ok and g.state==before,"HEAP altered inherited maximum rejected atomically")
 Save.step_both(t,g,twin,"end")
 t.check(g.state.equipment==equipment and g.state.enemies.slice(1).all(func(x):return x.stage==1),"HEAP no pulse or child action during birth round remainder")
 Save.step_both(t,g,twin,"end")
 t.check(g.state.enemies.slice(1).all(func(x):return x.stage==2),"HEAP children begin their own cycles next round")

 g=Game.new(42,true,"rope_heap_solo");id=g.state.enemies[0].id;g._enemy(id).hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":id}).ok and g.state.enemies.size()==1 and g.state.phase=="reward","HEAP lethal attack skips live split and completes battle")

 # Real six-action timeline, no damage fixture and no scripted enemy operation.
 for seed_value in t.seed_values("enemy_cycle"):
  g=Game.new(seed_value,true,"rope_heap_solo");id=g.state.enemies[0].id
  for i in range(5): t.check(t.action(g,"end").ok,"HEAP reaches sixth action through formal turns")
  t.check(g._enemy(id).intent.kind=="split_burst","HEAP sixth public action is mass install and split")
  var links=g.state.links.duplicate(true)
  var ids=g.state.equipment.map(func(x):return x.id)
  twin=Save.roundtrip(t,g,"heap before automatic split")
  Save.step_both(t,g,twin,"end")
  var added=g.state.equipment.filter(func(x):return x.id not in ids)
  points=[]
  for x in added: points.append_array(g.Equipment.physical_points(x))
  unique={}
  for point in points: unique[point]=true
  # Rope pools include legal links under the shared application rule.
  var new_links=g.state.links.filter(func(x):return not links.any(func(old):return old.id==x.id))
  t.check(not added.is_empty() and added.all(func(x):return x.grade==2 and g.tier(x.durability,x.maximum)==3) and unique.size()==points.size() and links.all(func(x):return x in g.state.links) and new_links.all(func(x):return x.grade==2 and g.tier(x.durability,x.maximum)==3),"HEAP final burst installs middle tier three pieces and eligible links, preserving existing links")
  t.check(g.state.enemies.size()==4 and g.state.enemies.slice(1).map(func(x):return x.max_hp)==[48.0,24.0,24.0] and active(g).is_empty() and g.state.enemies.slice(1).all(func(x):return x.stage==1),"HEAP automatic split uses half maximum, expires source and delays children")
  t.check(g.validate()=="" and g.state.phase=="battle" and g.state.reward_count==0,"HEAP full burst leaves valid ongoing encounter")

 # Child rope mass retains its own death split; reward waits for all descendants.
 g=Game.new(42,true,"rope_heap_solo");id=g.state.enemies[0].id
 hit=t.find_action(g,"attack",{"type":"strike","enemy":id});g._enemy(id).hp=47+hit.payload.damage
 t.action(g,"attack",{"type":"strike","enemy":id})
 var child=g.state.enemies[1];child.hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":child.id}).ok and g.state.enemies.size()==6,"HEAP inherited rope mass still splits on death")
 t.action(g,"end")
 while g.state.phase=="battle":
  var living=g.state.enemies.filter(func(x):return not x.gone)
  if g.state.energy==0: t.action(g,"end");continue
  living[0].hp=1
  if not t.action(g,"attack",{"type":"strike","enemy":living[0].id}).ok: break
 t.check(g.state.phase=="reward" and g.state.reward_count==1,"HEAP all descendants produce one encounter reward")
 Save.roundtrip(t,g,"heap descendants defeated")


static func skin_cases(t) -> void:
 # Material selection happens once after a family encounter was chosen.
 var observed={"mass_family":[],"heap_family":[]}
 for family in observed:
  for seed_value in t.seed_values("enemy_pool"):
   var g=Game.new(seed_value)
   g.state.room_encounters.entrance=family
   var counter=g.state.rng.encounter
   g._start_battle()
   var selected=g.state.room_encounters.entrance
   if selected not in observed[family]: observed[family].append(selected)
   t.check(selected in g.Enemies.ENCOUNTERS[family].variants and g.state.rng.encounter==counter+1 and g.state.enemies.size()==1,"SKIN family resolves once to one individual")
   var before=g.export_snapshot();g.get_view();g.command_facts()
   t.check(g.state==before,"SKIN material cannot reroll through previews")
  t.check(observed[family].size()==2,"SKIN both material variants actually sampled from "+family)
 for size in ["mass","heap"]:
  var g=Game.new(42,true,"belt_"+size+"_solo")
  var id=g.state.enemies[0].id
  var twin=Save.roundtrip(t,g,"belt "+size+" opening")
  Save.step_both(t,g,twin,"end")
  if size=="heap":
   t.check(active(g).size()==1 and active(g)[0].name=="皮带增生" and g.state.equipment[0].template in g.Enemies.TYPES.belt.install_pool,"SKIN source pulse installs actual leather equipment with matching status")
   for i in range(4): t.check(t.action(g,"end").ok,"SKIN leather elite executes shared cycle")
   twin=Save.roundtrip(t,g,"leather elite before final split")
   Save.step_both(t,g,twin,"end")
   t.check(g.state.enemies.slice(1).map(func(e):return e.type)==["belt_mass","belt","belt"] and g.state.enemies.slice(1).map(func(e):return e.max_hp)==[48.0,24.0,24.0],"SKIN automatic split preserves material and inherited health")
   t.check(active(g).is_empty() and g.state.links.all(func(e):return e.template=="link_rope") and g.state.equipment.all(func(e):return e.template in g.Enemies.TYPES.belt.install_pool) and g.validate()=="","SKIN six-stage leather source preserves actual material and valid physical links")
   # Filling vacant points can consume every batch location before a link is drawn.
   # Check the leather pool's real link capability without requiring that random outcome.
   var links=g.EquipmentOffers.for_pool(g,2,g.Enemies.TYPES.belt.install_pool).filter(func(o):return o.kind=="link")
   t.check(not links.is_empty(),"SKIN leather source still supplies legal links after its full-body pass")
   if not links.is_empty():
    var request=links[0].duplicate(true);request.grade=2;request.tier=3
    var count=g.state.links.size()
    var linked=g.Application.execute_concrete(g,request,id)
    t.check(linked.ok and g.state.links.size()==count+1 and g.state.equipment.all(func(e):return e.template in g.Enemies.TYPES.belt.install_pool) and g.validate()=="","SKIN inherited leather link commits through the shared factory without ordinary rope pieces")
  else:
   Save.step_both(t,g,twin,"end")
   t.check(g.state.equipment.size()==1 and g.state.equipment[0].grade==2 and g.state.equipment[0].template in g.Enemies.TYPES.belt.install_pool,"SKIN leather mass uses frozen middle-grade material pool")
   g._enemy(id).hp=1
   t.check(t.action(g,"attack",{"type":"strike","enemy":id}).ok and g.state.enemies.slice(1).all(func(e):return e.type=="belt" and e.hp==g.Enemies.TYPES.belt.hp),"SKIN leather mass death produces two ordinary floating belts")
 var g=Game.new(42,true,"belt_heap_solo")
 var id=g.state.enemies[0].id
 var hit=t.find_action(g,"attack",{"type":"strike","enemy":id})
 g._enemy(id).hp=47.5+hit.payload.damage
 t.check(t.action(g,"attack",{"type":"strike","enemy":id}).ok and g.state.enemies[1].type=="belt_mass" and g.state.enemies[1].hp==47.5,"SKIN damage split keeps leather and fractional inherited health")
 g.state.enemies[1].hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":g.state.enemies[1].id}).ok and g.state.enemies.size()==6 and g.state.enemies.slice(2).all(func(e):return e.type=="belt"),"SKIN second-generation split keeps the original material")
 Save.roundtrip(t,g,"leather family descendants")
 var book=preload("res://data/encyclopedia.gd").entries()
 for type in ["belt_mass","belt_heap"]:
  var row=book.filter(func(e):return e.category=="enemies" and e.id==type)[0]
  t.check(row.text.contains("皮带") and row.text.contains("分裂") and not row.text.contains("一团绳继承"),"SKIN encyclopedia explains actual material and splitting behavior")
