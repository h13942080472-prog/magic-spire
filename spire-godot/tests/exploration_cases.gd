extends RefCounted
const Game=preload("res://core/game.gd")
const Space=preload("res://core/prison_space.gd")
const Fixture=preload("res://tests/exploration_fixture.gd")
const PrisonCases=preload("res://tests/prison_cases.gd")

static func fresh(blind: bool=false):
 var g=Game.new(42,true,"prison_blind" if blind else "prison_test")
 PrisonCases.clear_fixture(g)
 if blind: g._install_template("eye_cloth","eyes",4,10,false,"fixture")
 g.state.posture="stand"
 return g

static func falls(g) -> Array:
 return g.state.logs.filter(func(log):return log.data.has("exploration_fall"))

static func set_legs(g, level: int) -> void:
 for slot in (["foot"] if level==1 else (["ankle"] if level==2 else (["ankle","foot"] if level==3 else ["thigh","calf","ankle","foot","toes"]))):
  g._install_template(g.Equipment.default_template(slot),slot,10,10,false,"fixture")

static func aim_roll(g, threshold: int) -> void:
 for counter in range(1000):
  var rng=RandomNumberGenerator.new();rng.seed=g.state.seed+g.B.RNG_SALTS.fall+counter*104729
  if rng.randi_range(0,9999)<threshold: g.state.rng.fall=counter;return

static func walk_to(t,g,id: String) -> void:
 var guard=0
 while not Space.site_path(g,id).is_empty() and guard<40:
  guard+=1
  if g.state.phase=="inspection":
   for action in ["inspect","accept","resume"]: t.check(t.action(g,"prison",{"action":action}).ok,"EXP patrol boundary stays formal")
  if g.state.energy<g.wall_movement_profile().cost: t.check(t.action(g,"end").ok,"EXP long walk replenishes on actual end turn");continue
  var payload={"action":"explore","site":id}
  if g.occupied("eyes"):
   var next=Space.site_path(g,id)[0];var here=g.state.prison.space.position
   for d in Space.DIRECTIONS:
    if [next[0]-here[0],next[1]-here[1]]==Space.DIRECTIONS[d]: payload={"action":"explore","direction":d,"steps":1}
  t.check(t.action(g,"prison",payload).ok,"EXP continuous actual travel")
 t.check(Space.site_path(g,id).is_empty(),"EXP destination reached within bounded real travel")

static func run(t) -> void:
 distance_and_warning(t)
 for blind in [false,true]:
  var g=fresh(blind);var other=fresh(blind)
  t.check(g.state.prison.space==other.state.prison.space,"EXP layout seeded once")
  var frozen=g.export_snapshot();var v=Space.view(g)
  for i in range(3): g.get_view();g.command_facts()
  t.check(g.export_snapshot()==frozen,"EXP preview does not move discover or roll")
  t.check(v.blind==blind and not v.has("position") and not v.has("blocked"),"EXP frontend never receives hidden geometry")
  for site in v.sites:
   t.check(not site.has("position") and not site.has("discovery"),"EXP no site coordinate or item identity leak")
   if blind:
    t.check(site.here or site.interaction.is_empty(),"EXP blind remote sites disclose no facility or item interaction")
    t.check(not site.has("bearing") and not site.has("distance") and not site.has("wall_distance") and (site.here or site.label=="？？？"),"EXP blind labels reveal only current location or proximity")
   else: t.check(site.has("bearing") and site.has("distance") and site.has("wall_distance"),"EXP sighted destination bears range and wall information")
  if not blind:
   t.check(v.sites.filter(func(site):return site.id=="place_1")[0].interaction=={"kind":"door"},"EXP visible door maps only to door secondary context")
   t.check(v.sites.filter(func(site):return site.id=="place_4")[0].interaction.is_empty(),"EXP undiscovered vent has no interaction metadata")
  var actions=g.command_facts().filter(func(c):return c.payload.kind=="prison" and c.payload.action=="explore")
  t.check(actions.all(func(c):return c.payload.has("direction")==blind and c.payload.has("site")!=blind),"EXP mode dictates actual candidate inputs")
  walk_to(t,g,"place_2");walk_to(t,g,"place_3");walk_to(t,g,"place_4")
  t.check(g.state.prison.found.size()==3 and g.state.items.size()==2,"EXP complete travel yields two tools and vent once")
  var current=Space.view(g).sites.filter(func(site):return site.here)[0]
  t.check(current.interaction=={"kind":"vent"},"EXP discovered current vent exposes its own secondary context")
  var items=g.state.items.duplicate(true)
  walk_to(t,g,"place_0");walk_to(t,g,"place_2")
  t.check(g.state.items==items and g.state.prison.found.size()==3,"EXP revisits never farm tools")
  var copy=Game.new(9);t.check(copy.restore_snapshot(g.export_snapshot()).ok and copy.state.prison.space==g.state.prison.space,"EXP saved position discoveries and layout roundtrip")

 var g=fresh();var s=g.state.prison.space
 Fixture.position(g,[0,4])
 t.check(Space.path(s,[0,4],[2,4]).size()==4,"EXP shortest path detours around furniture")
 t.check(Space.bearing([0,4],[2,4])=="右方","EXP bearing is target bearing not first route step")
 g._install_template("eye_cloth","eyes",4,10,false,"fixture")
 var before=g.export_snapshot()
 t.check(not t.action(g,"prison",{"action":"explore","direction":"east","steps":1}).ok and g.export_snapshot()==before,"EXP blocked direction atomic")
 Fixture.position(g,[2,4]);before=g.export_snapshot()
 t.check(t.action(g,"prison",{"action":"explore","direction":"north","steps":1}).ok and g.state.prison.space.position==[2,3] and g.state.rng.fall==before.rng.fall,"EXP blind actual movement never has old random zero failure")
 Fixture.position(g,[3,2]);before=g.export_snapshot()
 t.check(not t.action(g,"prison",{"action":"explore","direction":"east","steps":1}).ok and g.export_snapshot()==before,"EXP furniture blocks without spending")
 Fixture.position(g,[3,1]);t.check(t.action(g,"prison",{"action":"explore","direction":"north","steps":2}).ok and g.state.prison.space.position==[3,0] and g.at_wall(),"EXP blind step clamps at real boundary")
 t.check(g.command_facts().all(func(c):return c.payload.kind!="wall_move"),"EXP blind cannot bypass directions with homing wall control")

 g=fresh();Fixture.position(g,[3,3]);g.state.posture="lie"
 var c=t.find_action(g,"wall_move",{"direction":"toward"});before=g.export_snapshot()
 t.check(t.action(g,"wall_move",{"direction":"toward"}).ok and Space.wall_distance(g.state.prison.space.position)==g.state.wall_distance and g.state.prison.space.position!=before.prison.space.position,"EXP wall command moves same grid")
 t.check(g.state.energy==before.energy-c.cost and g.state.prison.left==before.prison.left,"EXP movement fee does not advance patrol timer")
 for pose in ["stand","sit","lie"]:
  g=fresh();g.state.posture=pose
  for a in g.command_facts().filter(func(a):return a.payload.kind=="prison" and a.payload.action=="explore"):
   t.check(a.cost==g.wall_movement_profile().cost,"EXP same wall cost for every posture")

 for level in range(1,5):
  g=fresh();set_legs(g,level);Fixture.position(g,[3,3])
  t.check(g.level("legs")==level and is_equal_approx(Space.fall_profile(g).chance,Space.FALL[level]),"EXP correct base fall rate "+str(level))
  g.state.pressure=75
  t.check(is_equal_approx(Space.fall_profile(g).chance,minf(1.0,Space.FALL[level]*1.75)),"EXP inverse base casting curve "+str(level))
  g._install_template("eye_cloth","eyes",4,10,false,"fixture")
  t.check(is_equal_approx(Space.fall_profile(g).chance,minf(1.0,Space.FALL[level]*1.75+0.2)),"EXP blind independent percentage points capped")
  g.state.pressure=0;aim_roll(g,int((Space.FALL[level]+0.2)*10000))
  before=g.export_snapshot()
  t.check(t.action(g,"prison",{"action":"explore","direction":"west","steps":1}).ok,"EXP standing move resolves once")
  t.check(g.state.posture==("sit" if level<=2 else "lie") and g.state.prison.space.position==[2,3] and falls(g).size()==1,"EXP fall keeps movement and selects correct posture")
  t.check(g.state.rng.fall==before.rng.fall+1 and g.state.prison.left==before.prison.left and g.state.phase=="prison","EXP one roll no forced turn")

 g=fresh(true);set_legs(g,2);Fixture.position(g,[3,0]);aim_roll(g,6000)
 before=g.export_snapshot()
 t.check(t.action(g,"prison",{"action":"explore","direction":"south","steps":1}).ok and g.state.prison.space.position==[3,1] and g.state.posture=="stand" and g.state.rng.fall==before.rng.fall,"EXP starting at wall protects only this action")
 g.state.energy=3
 t.check(t.action(g,"prison",{"action":"explore","direction":"south","steps":1}).ok and g.state.posture=="sit" and falls(g).size()==1,"EXP next action in SAME TURN off wall can fall")
 g=fresh(true);set_legs(g,2);Fixture.position(g,[3,1]);before=g.export_snapshot()
 t.check(t.action(g,"prison",{"action":"explore","direction":"north","steps":1}).ok and g.at_wall() and g.state.posture=="stand" and g.state.rng.fall==before.rng.fall,"EXP arrival wall protects immediately")
 g=fresh(true);Fixture.position(g,[3,3]);var foot=g._install_template("belt","foot",0.01,10,false,"fixture")
 before=g.export_snapshot();t.action(g,"prison",{"action":"explore","direction":"west","steps":1})
 t.check(g._equipment(foot.id).is_empty() and g.level("legs")==0 and g.state.posture=="stand" and g.state.rng.fall==before.rng.fall,"EXP passive release recomputes legs before roll")
 t.check(g.state.logs.filter(func(log):return log.data.has("passive_slip")).size()==1,"EXP passive once per action not per step")
 for pose in ["sit","lie"]:
  g=fresh(true);set_legs(g,4);Fixture.position(g,[3,3]);g.state.posture=pose;before=g.export_snapshot()
  t.action(g,"prison",{"action":"explore","direction":"west","steps":1})
  t.check(g.state.posture==pose and g.state.rng.fall==before.rng.fall,"EXP seated or lying cannot fall")

 for wall in [false,true]:
  g=fresh();g.state.posture="sit"
  var plain=t.find_action(g,"posture",{"dest":"stand","wall":wall}).cost
  g._install_template("eye_cloth","eyes",4,10,false,"fixture")
  t.check(t.find_action(g,"posture",{"dest":"stand","wall":wall}).cost==plain+1,"EXP blind sit stand extra after discounts")
  t.check(t.find_action(g,"posture",{"dest":"lie","wall":false}).cost==0,"EXP blind other posture no extra fee")

 g=fresh();g._gain_tool("shard");var item=g.state.items[0]
 t.check(t.action(g,"item_install",{"item":item.id,"mount":"hand_wall"}).ok,"EXP install records physical location")
 var mounted=g._item(item.id).prison_position.duplicate();Fixture.position(g,[6,6])
 t.check(not t.find_action(g,"item_retrieve",{"item":item.id}).valid,"EXP another wall is not mounted tool location")
 t.check(Space.view(g).sites.any(func(site):return site.id=="tool_"+item.id),"EXP installed tool has return destination")
 Fixture.position(g,mounted)
 t.check(t.action(g,"item_retrieve",{"item":item.id}).ok and not g._item(item.id).has("prison_position"),"EXP retrieval clears spatial attachment")

 g=fresh(true);Fixture.position(g,[3,2]);g._install_template("belt","thigh",10,10,false,"fixture")
 aim_roll(g,4000);before=g.export_snapshot()
 t.check(g.wall_movement_profile().distance==2 and t.action(g,"prison",{"action":"explore","direction":"south","steps":2}).ok,"EXP two-grid action is one paid movement")
 t.check(g.state.prison.space.position==[3,4] and g.state.rng.fall==before.rng.fall+1 and falls(g).size()==1 and g.state.logs.filter(func(log):return log.data.has("passive_slip")).size()==1,"EXP two grids still produce one passive batch and one fall roll")

 # Equipment-only double unlock cannot bypass distance via its second target.
 g=fresh();Fixture.position(g,[3,3]);g._gain_card("double_unlock")
 var rope=g._install_template("belt","ankle",4,10,true,"fixture")
 var card=t.hand_card(g,"double_unlock")
 t.check(t.action(g,"card",{"uid":card.uid,"target":rope.id}).ok,"EXP first lock uses ordinary card")
 before=g.export_snapshot()
 t.check(not t.action(g,"chain",{"target":"prison_door"}).ok and g.export_snapshot()==before,"EXP second magic target cannot open remote door")
 g=fresh();g._gain_tool("picks")
 t.check(not t.find_action(g,"item_use",{"target":"prison_door"}).valid,"EXP lockpick cannot open remote door")

 # The eye surcharge applies to the existing posture actions outside exploration too.
 g=Game.new(42,true,"guard");g.state.posture="sit";g.state.wall_distance=0
 var plain=t.find_action(g,"posture",{"dest":"stand","wall":true}).cost
 g._install_template("eye_cloth","eyes",4,10,false,"fixture")
 t.check(t.find_action(g,"posture",{"dest":"stand","wall":true}).cost==plain+1,"EXP combat wall rise shares blind surcharge")

 # Prison battle tools retain a concrete location when returning to exploration.
 g=fresh();Fixture.position(g,[3,3]);g.state.prison.left=1;t.action(g,"end")
 t.check(t.action(g,"prison",{"action":"resist"}).ok,"EXP actual resistance keeps exploration position paused")
 g.state.wall_distance=0;g._gain_tool("shard");item=g.state.items[0]
 t.check(t.action(g,"item_install",{"item":item.id,"mount":"hand_wall"}).ok,"EXP prison battle tool installs through normal command")
 mounted=g._item(item.id).prison_position
 t.check(Space.wall_distance(mounted)==0 and g.validate()=="","EXP prison combat tool anchors to real reachable exploration wall")
 g.state.enemies[0].hp=1;g.state.energy=3;t.action(g,"attack",{"type":"strike","enemy":g.state.enemies[0].id})
 t.action(g,"reward",{"type":"skip"});t.action(g,"finish_prepare")
 t.check(g.state.phase=="prison" and g.state.prison.space.position==[3,3] and g.state.wall_distance==3 and not t.find_action(g,"item_retrieve",{"item":item.id}).valid,"EXP return restores position and spatial tool reach")

 g=fresh();var original=g.export_snapshot();var invalid=[]
 var bad=original.duplicate(true);bad.prison.erase("space");invalid.append(bad)
 bad=original.duplicate(true);bad.prison.space.position=[99,3];invalid.append(bad)
 bad=original.duplicate(true);bad.prison.space.sites[2].visited=true;invalid.append(bad)
 bad=original.duplicate(true);bad.prison.space.sites[2].position=bad.prison.space.sites[1].position;invalid.append(bad)
 bad=original.duplicate(true);bad.wall_distance=2;invalid.append(bad)
 for value in invalid:
  t.check(not g.restore_snapshot(value).ok and g.export_snapshot()==original,"EXP bad spatial snapshot rolls back")
 c=t.find_action(g,"prison",{"action":"explore","site":"place_1"})
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==original,"EXP stale destination fully atomic")
 g.state.mana=101;before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"EXP failed final validation rolls back position discovery rng and costs")

static func distance_and_warning(t) -> void:
 var g=fresh();var original=Space.view(g)
 var initial=original.sites.filter(func(site):return site.id=="place_1")[0].initial_distance
 t.check(original.sites.all(func(site):return site.distance==site.initial_distance),"EXP initial bars use the entry-to-site shortest distance")
 Fixture.position(g,[6,6]);var v=Space.view(g)
 t.check(v.sites.filter(func(site):return site.id=="place_1")[0].initial_distance==initial,"EXP moving never rebases initial distance")
 t.check(v.sites.filter(func(site):return site.id=="place_0")[0].initial_distance==0 and v.sites.filter(func(site):return site.id=="place_0")[0].distance>0,"EXP zero initial distance supports returning to the entry")
 Fixture.position(g,[0,6])
 t.check(Space.wall_warning(g,[[1,6],[2,6],[2,5]])=="","EXP later departure beyond this action gives no premature warning")
 t.check(Space.wall_warning(g,[[0,5],[0,4]])=="","EXP travel along wall does not warn")
 Fixture.position(g,[0,3])
 t.check(Space.wall_warning(g,[[1,3],[2,3]])!="","EXP departure inside this action warns")
 Fixture.position(g,[0,1])
 t.check(Space.wall_warning(g,[[1,1],[1,0]]).contains("结束时回到墙边"),"EXP detour warns even if action returns to wall")
 Fixture.position(g,[2,1])
 t.check(Space.wall_warning(g,[[2,2],[2,3]])=="","EXP already away is not a new wall departure")
 g=fresh(true);Fixture.position(g,[0,3])
 var before=g.export_snapshot();var actions=g.command_facts()
 t.check(actions.any(func(c):return c.payload.kind=="prison" and c.payload.get("direction","")=="east" and c.payload.get("wall_warning","")!=""),"EXP blind direction warns before leaving wall")
 t.check(Space.view(g).sites.all(func(site):return not site.has("initial_distance") and not site.has("distance") and not site.has("installed")),"EXP blind bars and installed metadata do not disclose remote geometry")
 t.check(g.export_snapshot()==before,"EXP distance and wall warnings never roll or mutate state")
 g=fresh();Fixture.position(g,[0,3]);g._gain_tool("shard");var item=g.state.items[0]
 t.check(t.action(g,"item_install",{"item":item.id,"mount":"hand_wall"}).ok,"EXP tool location uses real installation")
 var installed=Space.view(g).sites.filter(func(site):return site.id=="tool_"+item.id)[0]
 t.check(installed.here and installed.installed.uses==3 and installed.installed.mount==g.Tools.mount_label("hand_wall") and installed.interaction.item==item.id,"EXP mounted card identifies the actual tool and mount")
 Fixture.position(g,[6,6]);installed=Space.view(g).sites.filter(func(site):return site.id=="tool_"+item.id)[0]
 t.check(installed.distance>installed.initial_distance and installed.initial_distance==3,"EXP mounted distance can exceed fixed entry baseline")
 var saved=g.export_snapshot();var copy=Game.new(9)
 t.check(copy.restore_snapshot(saved).ok and Space.view(copy).sites.filter(func(site):return site.id=="tool_"+item.id)[0].initial_distance==3,"EXP mounted baseline remains stable after restore")
 g._install_template("eye_cloth","eyes",4,10,false,"fixture")
 installed=Space.view(g).sites.filter(func(site):return site.id=="tool_"+item.id)[0]
 t.check(installed.label=="？？？" and not installed.has("installed") and installed.interaction.is_empty(),"EXP blind remote mounted tool remains unknown")
 Fixture.position(g,[0,3]);installed=Space.view(g).sites.filter(func(site):return site.id=="tool_"+item.id)[0]
 t.check(installed.has("installed") and installed.interaction.item==item.id and not installed.has("distance"),"EXP blind arrival shows tool without revealing distance")
 t.check(t.action(g,"item_retrieve",{"item":item.id}).ok and not Space.view(g).sites.any(func(site):return site.id=="tool_"+item.id),"EXP retrieval removes extra mounted destination")
