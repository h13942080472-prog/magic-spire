extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Exploration=preload("res://tests/exploration_cases.gd")
const SpaceFixture=preload("res://tests/exploration_fixture.gd")

static func run(t) -> void:
 for mount in Game.Tools.HEIGHTS:
  t.check(Game.Tools.mount_label(mount)=="离地%s米的墙缝" % str(Game.Tools.HEIGHTS[mount].height),"HEIGHT mount labels use the fixed world height: "+mount)
 # Lifting the lower legs must not bring the thighs or covered inner layers along.
 var g=Game.new(42);g.state.equipment.clear();g.state.posture="lie";g._gain_tool("shard")
 var tool=g.state.items[0];tool.mount="high_wall"
 var calf=g._install_template("rope","calf",4,10,false,"fixture",1,-1,0,"mid_calf")
 var foot=g.add_fixture("foot",4);var thigh=g.add_fixture("thigh",4)
 t.check(not (g.InstalledTools.reason(g,tool,calf)==""),"HEIGHT lying calf cannot reach high wall")
 t.check(g.InstalledTools.reason(g,tool,foot)=="" and not t.find_action(g,"item_use",{"item":tool.id,"target":foot.id}).valid,"HEIGHT lying foot can contact high passive tool without an active cut entry")
 g._item(tool.id).mount="hand_wall"
 t.check((g.InstalledTools.reason(g,tool,calf)=="") and not (g.InstalledTools.reason(g,tool,thigh)==""),"HEIGHT mid wall separates raised calf from thigh")
 var outer=g._install_template("rope","calf",4,10,false,"fixture",1,1,0,"mid_calf")
 var before=g.export_snapshot()
 t.check(not t.action(g,"item_use",{"item":tool.id,"target":calf.id}).ok and g.export_snapshot()==before,"HEIGHT raised calf still cannot cut covered inner target")
 t.check((g.InstalledTools.reason(g,tool,outer)==""),"HEIGHT outer target remains accessible")
 # Precise elbow points straddle bands; grouping them must not widen the target.
 g=Game.new(42);g.state.equipment.clear();g._gain_tool("saw");tool=g.state.items[0];tool.mount="hand_wall"
 var upper=g._install_template("rope","upper_arm",4,10,false,"fixture",1,-1,0,"upper_arm_top")
 var elbow=g._install_template("rope","upper_arm",4,10,false,"fixture",1,-1,0,"above_elbow")
 t.check(not (g.InstalledTools.reason(g,tool,upper)=="") and (g.InstalledTools.reason(g,tool,elbow)==""),"HEIGHT arm group does not expand exact upper point into mid wall")
 # Toe installation and retrieval use the same actual height and constraints.
 g=Game.new(42);g.state.equipment.clear();g.state.posture="lie";g._gain_tool("shard");tool=g.state.items[0]
 var c=t.find_action(g,"item_install",{"item":tool.id,"mount":"high_wall"})
 t.check(c.valid and c.payload.operator=="foot","HEIGHT lying toes can lift tool to high mount")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==2,"HEIGHT toe high installation pays once")
 g.add_fixture("toes",4);before=g.export_snapshot()
 t.check(not t.action(g,"item_retrieve",{"item":tool.id}).ok and g.export_snapshot()==before,"HEIGHT toe restraint prevents high retrieval without losing tool")
 for e in g.equipment_at("toes"): e.durability=0
 g._cleanup()
 t.check(t.action(g,"item_retrieve",{"item":tool.id}).ok and g._item(tool.id).mount=="carry" and g.state.energy==2 and g._item(tool.id).uses==3,"HEIGHT restored toe capability retrieves for zero energy and no charge")
 # Mouth route remains independent of hands; the fixed mount never follows posture.
 g=Game.new(42);g.state.equipment.clear();g.add_fixture("fingers",4);g.add_fixture("toes",4);g._gain_tool("saw");tool=g.state.items[0]
 t.check(t.action(g,"item_install",{"item":tool.id,"mount":"high_wall"}).ok,"HEIGHT standing mouth installs high")
 g.state.posture="sit"
 t.check(not t.find_action(g,"item_retrieve",{"item":tool.id}).valid and g._item(tool.id).mount=="high_wall","HEIGHT sitting cannot bring a fixed high mount down")
 g.state.posture="stand"
 t.check(t.action(g,"item_retrieve",{"item":tool.id}).ok and g.state.logs.back().data.has("retrieval"),"HEIGHT mouth retrieval is a logged formal action")
 # Two distinct walls can hold the same height; duplicate physical occupation is rejected.
 g=Exploration.fresh();g.state.energy=3;g._gain_tool("shard");g._gain_tool("saw")
 var first=g.state.items[0].id;var second=g.state.items[1].id
 t.check(t.action(g,"item_install",{"item":first,"mount":"hand_wall"}).ok,"HEIGHT first concrete point installed")
 before=g.export_snapshot()
 t.check(not t.action(g,"item_install",{"item":second,"mount":"hand_wall"}).ok and g.export_snapshot()==before,"HEIGHT same concrete point rejects second tool atomically")
 SpaceFixture.position(g,[0,3])
 t.check(t.action(g,"item_install",{"item":second,"mount":"hand_wall"}).ok,"HEIGHT same height on another wall cell is independent")
 t.check(not t.find_action(g,"item_retrieve",{"item":first}).valid,"HEIGHT distant same-height tool cannot be retrieved here")
 var saved=g.export_snapshot();var copy=Game.new(9)
 t.check(copy.restore_snapshot(saved).ok,"HEIGHT both distinct mount positions survive save restore")
 saved.items[1].prison_position=saved.items[0].prison_position.duplicate()
 before=copy.export_snapshot()
 t.check(not copy.restore_snapshot(saved).ok and copy.export_snapshot()==before,"HEIGHT duplicate mount snapshot is rejected atomically")
 # A mid-height hook uses the same geometry, including seated shoulders and raised calves.
 g=Game.new(42,true);g.state.equipment.clear();g.state.posture="lie"
 calf=g._install_template("rope","calf",8,10,false,"fixture",1,-1,0,"mid_calf")
 thigh=g.add_fixture("thigh",8)
 t.check(not t.find_action(g,"hook",{"target":thigh.id}).valid,"HEIGHT lying thigh cannot use mid hook")
 before=g.export_snapshot()
 t.check(t.action(g,"hook",{"target":calf.id}).ok and g.state.hook_uses==before.hook_uses-1 and g.state.energy==before.energy and g._equipment(calf.id).durability<8,"HEIGHT raised calf uses mid hook with original charge and effect")
 g.state.wall_distance=1;before=g.export_snapshot()
 t.check(not t.action(g,"hook",{"target":calf.id}).ok and g.export_snapshot()==before,"HEIGHT hook still needs wall contact")
