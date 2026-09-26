extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Motion=preload("res://core/slip_motion.gd")
const PrisonCases=preload("res://tests/prison_cases.gd")

static func fresh(seed: int=42):
 var g=Game.new(seed)
 g.state.wall="normal";g.state.wall_distance=4
 return g

static func piece(g, point: String, d: float=4.0, layer: int=0) -> Dictionary:
 if point=="shoulder":
  var root=g._install_assembly("glove","short","fixture",2,1,{"left":{"tier":1}},"cross")
  var shoulder=root.components.filter(func(e):return e.part=="left")[0]
  # Isolate the position multiplier at the same neutral 40% ratio as other fixtures.
  shoulder.durability=shoulder.maximum*0.4
  return shoulder
 var slot="thigh" if point in ["thigh_root","mid_thigh","above_knee"] else ("calf" if point in ["below_knee","mid_calf"] else point)
 return g._install_template("fine_belt" if point=="toes" else "belt",slot,d,10.0,false,"fixture",1,layer,0,point if point in g.Equipment.SEGMENTS.get(slot,[]) else "")

static func batches(g) -> Array:
 return g.state.logs.filter(func(log):return log.data.has("passive_slip"))

static func run(t) -> void:
 for pose in Motion.POSES:
  for point in Motion.FACTORS:
   var g=fresh();g.state.posture=pose
   var e=piece(g,point)
   var a=g.escape_preview(e,"slip",5)
   var m=g.escape_preview(e,"magic_slip",5)
   var b=g.escape_preview(e,"strain",5)
   t.check(a.position.factor==Motion.factor(point,pose) and m.position.factor==a.position.factor and b.position.factor==1.0,"MOTION shared position table "+point+pose)
   t.check(is_equal_approx(a.damage,(5.0+a.bonus+a.assist.bonus)*a.position.factor),"MOTION active uses one position multiplier "+point+pose)
   if point in ["foot","toes"]: t.check(a.position.factor==(1.0 if pose=="stand" else 1.2),"MOTION confirmed foot values "+point+pose)
 for pose in Motion.POSES:
  var shoulder_game=fresh();shoulder_game.state.posture=pose
  var shoulder=piece(shoulder_game,"shoulder")
  var body=shoulder_game.state.composites[0].components[0]
  var before=shoulder.durability;var body_before=body.durability
  t.check(t.action(shoulder_game,"wall_move",{"direction":"toward"}).ok,"MOTION shoulder movement "+pose)
  t.check(is_equal_approx(shoulder_game._equipment(shoulder.id).durability,before) and body.durability==body_before,"MOTION shoulder no longer supports strain so movement skips it "+pose)
  t.check(batches(shoulder_game).is_empty() and shoulder_game.Equipment.capacity_points(shoulder).is_empty(),"MOTION shoulder does not add capacity or target sleeve")
 var g=fresh();var e=piece(g,"thigh_root");var id=e.id
 g.state.dexterity=1;g.state.charge=2
 var state=JSON.stringify(g.state)
 g.get_view();g.command_facts()
 t.check(JSON.stringify(g.state)==state,"MOTION readonly previews do not choose targets")
 var c=t.find_action(g,"wall_move",{"direction":"toward"})
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and JSON.stringify(g.state)==state,"MOTION stale input changes nothing")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"MOTION paid movement commits")
 t.check(is_equal_approx(g._equipment(id).durability,1.5) and g.state.energy==1 and g.state.wall_distance==2,"MOTION base 1.5 plus dexterity once per move, no assist/focus additions")
 t.check(g.state.charge==2 and g.state.rng.magic==0,"MOTION passive preserves preparation and does not cast")
 t.check(batches(g).size()==1 and batches(g)[0].data.passive_slip.results.size()==1,"MOTION one structured batch")
 var clone=fresh();t.check(clone.restore_snapshot(g.export_snapshot()).ok,"MOTION random progress restores")
 g.state.energy=3;clone.state.energy=3
 t.check(t.action(g,"wall_move",{"direction":"toward"}).ok and t.action(clone,"wall_move",{"direction":"toward"}).ok,"MOTION resumed next action")
 t.check(g.state.rng==clone.state.rng and g.state.equipment==clone.state.equipment,"MOTION resumed target and damage reproduce")
 var first_ids={}
 for seed in range(12):
  g=fresh(seed);var a=piece(g,"mid_thigh");var b=piece(g,"mid_thigh")
  t.check(t.action(g,"wall_move",{"direction":"toward"}).ok,"MOTION random legal same-layer choice")
  var hits=batches(g)[0].data.passive_slip.results
  t.check(hits.size()==1 and ((g._equipment(a.id).durability==4.0)!=(g._equipment(b.id).durability==4.0)),"MOTION only chosen instance damaged")
  first_ids[hits[0].target]=true
 t.check(first_ids.size()==2,"MOTION seeded selection exercises both peers")
 var selected_looser=false
 for seed in range(8):
  g=fresh(seed);e=piece(g,"mid_thigh");piece(g,"mid_thigh",6)
  t.check(t.action(g,"wall_move",{"direction":"toward"}).ok,"MOTION differing tightness does not block paid move")
  var hit=batches(g)[0].data.passive_slip.results[0]
  if hit.target==e.id:
   selected_looser=true
   t.check(is_equal_approx(hit.damage,0.65),"MOTION random looser target keeps same-layer half damage")
 t.check(selected_looser,"MOTION passive does not reuse highest-tightness strain priority")
 g=fresh();var inner=piece(g,"thigh_root");var outer=piece(g,"thigh_root",0.2,1)
 t.check(t.action(g,"wall_move",{"direction":"toward"}).ok and g._equipment(outer.id).is_empty() and g._equipment(inner.id).durability==4.0,"MOTION never continues through removed outer layer")
 g=fresh();e=piece(g,"thigh_root",10)
 t.check(t.action(g,"wall_move",{"direction":"toward"}).ok and g._equipment(e.id).durability==10 and batches(g)[0].data.passive_slip.results[0].preview.immune,"MOTION third tier remains immune without retry")
 g=fresh();e=piece(g,"thigh_root");e.slip_allowed=false
 t.check(t.action(g,"wall_move",{"direction":"toward"}).ok and g._equipment(e.id).durability==4 and batches(g)[0].data.passive_slip.results[0].reason!="","MOTION structural no-slip remains blocked")
 g=fresh();var root=g._install_assembly("leg","toes","fixture",2,1)
 root.components=root.components.filter(func(part):return part.part=="body")
 var body=root.components[0];var old=body.durability
 t.check(t.action(g,"wall_move",{"direction":"toward"}).ok,"MOTION shared compound movement")
 var result=batches(g)[0].data.passive_slip.results
 t.check(result.size()==1 and result[0].points.size()==7 and result[0].coefficient==1.5 and is_equal_approx(g._equipment(body.id).durability,old-1.5),"MOTION compound dedup uses highest selected factor once")
 for value in [0.0,90.0]:
  g=fresh();e=piece(g,"thigh_root");g.state.pressure=value
  t.check(t.action(g,"wall_move",{"direction":"toward"}).ok and is_equal_approx(g._equipment(e.id).durability,2.5),"MOTION overload value does not alter passive damage")
 g=fresh();e=piece(g,"ankle");g.state.energy=0;state=JSON.stringify(g.state)
 t.check(not t.action(g,"wall_move",{"direction":"toward"}).ok and JSON.stringify(g.state)==state,"MOTION insufficient energy atomic")
 g.state.energy=3
 t.check(t.action(g,"wall_move",{"direction":"toward"}).ok and batches(g).is_empty() and g._equipment(e.id).durability==4,"MOTION ankle excluded even on movement")
 g=fresh();e=piece(g,"thigh_root");g.state.mana=101;state=JSON.stringify(g.state)
 c=t.find_action(g,"wall_move",{"direction":"toward"})
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and JSON.stringify(g.state)==state,"MOTION late validation rolls back damage random ids and logs")
 g=fresh();e=piece(g,"thigh_root")
 t.check(t.action(g,"posture",{"dest":"sit","wall":false}).ok and batches(g).is_empty() and g._equipment(e.id).durability==4,"MOTION posture alone is not movement")
 g=PrisonCases.intake(t);PrisonCases.clear_fixture(g)
 var payload=preload("res://tests/exploration_fixture.gd").approach(g,"shard")
 e=piece(g,"thigh_root");var found=g.state.prison.found.size();var left=g.state.prison.left
 t.check(t.find_action(g,"prison",payload).cost>0,"MOTION restrained exploration uses normal cost")
 t.check(t.action(g,"prison",payload).ok and g.state.prison.found.size()==found+1 and g.state.prison.left==left,"MOTION explore completes without extra turn")
 t.check(batches(g).size()==1 and g._equipment(e.id).durability<4,"MOTION exploration applies passive once after real movement")
 g=PrisonCases.intake(t);PrisonCases.clear_fixture(g);g.state.energy=0
 payload=preload("res://tests/exploration_fixture.gd").approach(g,"shard");state=JSON.stringify(g.state)
 t.check(t.find_action(g,"prison",payload).cost>0 and not t.action(g,"prison",payload).ok,"MOTION no free exploration at zero energy")
 t.check(JSON.stringify(g.state)==state and g.state.rng.motion==0 and batches(g).is_empty(),"MOTION blocked movement spends no random draws or resources")
 g=fresh();e=g._install_template("belt","foot",40,100,false,"fixture");id=e.id
 g.state.phase="map";g.state.completed_rooms=[g.state.room]
 t.check(t.action(g,"depart",{"room":"east"}).ok and batches(g).is_empty() and g.state.journey.total==5,"MOTION departure does not damage or change frozen travel time")
 for i in range(5): t.check(t.action(g,"travel_step").ok,"MOTION actual travel tick "+str(i))
 t.check(batches(g).size()==5 and g.state.room=="east" and g.state.phase=="battle","MOTION last step settles before arrival with no extra pulse")
 for log in batches(g): t.check(log.data.has("travel") and log.data.passive_slip.results[0].target==id,"MOTION route log retains passive outcome and old target")
 var tutorial=preload("res://data/tutorial.gd").entries().filter(func(row):return row.id=="slip_position")[0].text
 t.check(tutorial.contains("肩部：站×1.20／坐×1.20／躺×1.20") and tutorial.contains("脚趾：站×1.00／坐×1.20／躺×1.20"),"MOTION tutorial reads actual authored values")
