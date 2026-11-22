extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Exploration=preload("res://tests/exploration_cases.gd")
const SpaceFixture=preload("res://tests/exploration_fixture.gd")

static func run(t) -> void:
 for mount in Game.Tools.HEIGHTS:
  t.check(Game.Tools.mount_label(mount)=="离地%s米的墙缝" % str(Game.Tools.HEIGHTS[mount].height),"HEIGHT mount labels use the fixed world height: "+mount)
 var g=Game.new(42,true);g.state.equipment.clear();g.state.posture="lie"
 var calf=g._install_template("rope","calf",8,10,false,"fixture",1,-1,0,"mid_calf")
 var thigh=g.add_fixture("thigh",8)
 t.check(not t.find_action(g,"hook",{"target":thigh.id}).valid,"HEIGHT lying thigh cannot use mid hook")
 var before=g.export_snapshot()
 t.check(t.action(g,"hook",{"target":calf.id}).ok and g.state.hook_uses==before.hook_uses-1 and g.state.energy==before.energy and g._equipment(calf.id).durability<8,"HEIGHT raised calf uses mid hook with original charge and effect")
 g.state.wall_distance=1;before=g.export_snapshot()
 t.check(not t.action(g,"hook",{"target":calf.id}).ok and g.export_snapshot()==before,"HEIGHT hook still needs wall contact")
