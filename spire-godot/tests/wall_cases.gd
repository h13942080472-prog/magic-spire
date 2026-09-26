extends RefCounted
const Game=preload("res://core/game.gd")
const Fixture=preload("res://tests/game_fixture.gd")

static func run(t) -> void:
 capture_blocks_movement(t)
 little_pig(t)
 true_bonus(t)
 mouth_installation(t)
 var distances={}
 for seed_value in range(12):
  var g=Game.new(seed_value,true,"guard")
  distances[g.state.wall_distance]=true
  t.check(g.state.wall_distance in [1,2,3,4] and not g.at_wall() and g._wall_bonus()==0,"WALL battle starts away without environment bonus")
  var before=g.export_snapshot()
  g.get_view();g.command_facts()
  t.check(g.state==before and g.state.rng.position==1,"WALL preview never rerolls initial position")
  var twin=Game.new(seed_value,true,"guard")
  t.check(twin.state.wall_distance==g.state.wall_distance,"WALL seeded initial distance is reproducible")
 t.check(distances.size()==4,"WALL random domain reaches all four initial distances")
 var g=Fixture.new(42)
 g.state.wall_distance=3
 var equipment=g.add_fixture("thigh",4)
 var damage=g.escape_preview(equipment,"strain",5).damage
 # Fixture setups set inputs; all movement uses real facts and payment.
 g.state.equipment.clear()
 var before=g.export_snapshot()
 var c=t.find_action(g,"wall_move",{"direction":"toward"})
 t.check(c.cost==1 and c.payload.distance==2,"WALL free standing takes two steps for one energy")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"WALL stale movement is atomic")
 t.check(t.action(g,"wall_move",{"direction":"toward"}).ok and g.state.wall_distance==1 and g.state.energy==2 and g.state.round==1,"WALL first movement preserves round and posture")
 t.check(t.action(g,"wall_move",{"direction":"toward"}).ok and g.at_wall() and g.state.energy==1,"WALL final partial stride stops exactly at wall")
 t.check(g.get_view().statuses.any(func(x):return x.id=="against_wall") and g._wall_bonus()==2,"WALL derived buff activates actual attributes")
 g.state.equipment.append(equipment)
 t.check(g.escape_preview(equipment,"strain",5).damage>damage,"WALL rough bonus changes actual escape damage")
 g.state.equipment.clear()
 var stop=t.find_action(g,"wall_move",{"direction":"toward"})
 before=g.export_snapshot()
 t.check(not stop.valid and not g.dispatch(g.command(stop.payload,g.state.version),g.state.version).ok and g.state==before,"WALL cannot pay for a zero-distance move")
 t.check(t.action(g,"posture",{"dest":"sit","wall":false}).ok and t.action(g,"posture",{"dest":"stand","wall":true}).ok and g.state.round==1 and g.state.energy==1,"WALL discounted ascent does not end turn")
 t.check(t.action(g,"wall_move",{"direction":"away"}).ok and not g.at_wall() and g._wall_bonus()==0 and g.state.wall_distance==2,"WALL leaving removes contact and bonus immediately")
 t.check(not g.get_view().statuses.any(func(x):return x.id=="against_wall"),"WALL buff is not retained in a second mutable list")
 before=g.export_snapshot()
 t.check(not t.action(g,"wall_move",{"direction":"toward"}).ok and g.state==before,"WALL insufficient energy changes nothing")
 var saved=g.export_snapshot();var restored=Game.new(1)
 t.check(restored.restore_snapshot(saved).ok and restored.state.wall_distance==2 and restored.state.rng==g.state.rng,"WALL save restores position and RNG without reroll")
 saved.wall_distance=1.5
 before=restored.export_snapshot()
 t.check(not restored.restore_snapshot(saved).ok and restored.state==before,"WALL malformed fractional distance rejected atomically")
 for config in [["", "stand",2,1],["thigh","stand",2,2],["calf","stand",1,2],["ankle","stand",1,3],["","sit",1,3],["","lie",1,3]]:
  g=Fixture.new(42);g.state.posture=config[1]
  if config[0]!="": g.add_fixture(config[0],4)
  t.check(g.wall_movement_profile()=={"distance":config[2],"cost":config[3]},"WALL movement capability table: "+str(config))
 g=Game.new(42,true,"equipment")
 t.check(g.at_wall(),"WALL rest starts adjacent")
 var item=g.state.items[0]
 g.state.wall_distance=1
 t.check(not t.find_action(g,"item_install",{"item":item.id}).valid and not t.find_action(g,"hook").valid,"WALL installation and hook require contact")
 g.state.wall_distance=0
 t.check(t.action(g,"item_install",{"item":item.id,"mount":"hand_wall"}).ok,"WALL actual tool can be mounted adjacent")
 g.state.wall_distance=1
 t.check(not t.find_action(g,"item_retrieve",{"item":item.id}).valid and g.command_facts().filter(func(a):return a.payload.kind=="item_use" and a.payload.item==item.id).all(func(a):return not a.valid),"WALL mounted use and retrieval gated after leaving")
 t.check(g.state.items.any(func(i):return i.id==item.id and i.mount=="hand_wall"),"WALL leaving does not delete installed tool")
 g.state.wall_distance=0
 t.check(t.find_action(g,"item_retrieve",{"item":item.id}).valid,"WALL return restores tool interaction")
 g=Game.new(42,true,"guard");g.Guard.capture(g,g.state.enemies[0])
 t.check(t.action(g,"prison",{"action":"enter"}).ok and g.at_wall(),"WALL prison starts adjacent")
 g.state.phase="inspection";g.state.prison.stage="arrival"
 var rolls=g.state.rng.position
 var cell_position=g.state.prison.space.position.duplicate();var distance=g.state.wall_distance
 t.check(t.action(g,"prison",{"action":"resist"}).ok and g.state.prison.space.position==cell_position and g.state.wall_distance==distance and g.state.rng.position==rolls,"WALL prison resistance preserves the cell position and does not reroll wall distance")
 g=Game.new(42,true,"special_equipment")
 g.state.wall_distance=1;g.state.posture="lie"
 var pressure=g.state.pressure;var energy=g.state.energy;var remaining=g.state.special_equipment[1].remaining
 t.check(t.action(g,"wall_move",{"direction":"toward"}).ok and g.state.energy==energy-3 and g.state.pressure==pressure+14 and g.state.special_equipment[1].remaining==remaining,"WALL three-energy movement triggers energy passives once without ticking duration")
 # Physical subsections use real attachment points, not region restraint level.
 g=Fixture.new(42,true,"glove_short")
 var arm_level=g.level("arms")
 var view=g.get_view();var neck=view.body_groups.filter(func(b):return b.id=="neck")[0]
 t.check(neck.sections.map(func(x):return x.name)==["脖颈","肩部"] and neck.sections[0].equipment.is_empty() and neck.sections[1].equipment.size()==2,"BODY neck has empty neck and actual shoulder attachments")
 t.check(g.level("arms")==arm_level and g.level("legs")==0,"BODY neck display adds no activity restriction")
 var thigh=view.body_groups.filter(func(b):return b.id=="thigh")[0]
 t.check(thigh.sections.map(func(x):return x.id)==["thigh_root","mid_thigh","above_knee"] and thigh.sections.all(func(x):return x.equipment.is_empty()),"BODY all empty subpositions remain visible")
 var e=g.add_fixture("thigh",4)
 thigh=g.get_view().body_groups.filter(func(b):return b.id=="thigh")[0]
 t.check(thigh.sections.filter(func(x):return not x.equipment.is_empty()).size()==1 and thigh.sections.filter(func(x):return x.id==e.points[0])[0].equipment[0].id==e.id,"BODY ordinary item appears at only its real point")
 var old=g.export_snapshot();neck.sections[0].name="changed"
 t.check(g.state==old and g.get_view().body_groups.filter(func(b):return b.id=="neck")[0].sections[0].name=="脖颈","BODY projection is detached from state")

static func little_pig(t) -> void:
 var g=Fixture.new(42)
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="little_pig")
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,g.Relics.TYPES.little_pig.rarity,excluded)=="little_pig" and g.Relics.TYPES.little_pig.rarity=="rare","PIG rare relic joins shared reward pool")
 g.state.wall_distance=3;g.state.posture="sit"
 var rng=g.state.rng.duplicate()
 g.RelicEffects.gain(g,"little_pig")
 t.check(g.at_wall() and not g.wall_contact() and g.state.wall_distance==3 and g.state.rng==rng,"PIG immediate support preserves physical position and randomness")
 var before=g.export_snapshot();var shown=g.get_view()
 var buff=shown.statuses.filter(func(row):return row.id=="against_wall")[0]
 t.check(buff.source=="一只小猪" and buff.duration.contains("持有遗物") and shown.wall_position.distance==3 and g.state==before,"PIG read-only wall status explains persistent relic source and real distance")
 var normal=t.find_action(g,"posture",{"dest":"stand","wall":false})
 var supported=t.find_action(g,"posture",{"dest":"stand","wall":true})
 t.check(supported.valid and supported.cost==maxi(0,normal.cost-1) and g.dispatch(g.command(supported.payload,g.state.version),g.state.version).ok and g.state.wall_distance==3,"PIG actual discounted ascent works away from wall")
 t.check(g._wall_bonus()==g.B.WALL_BONUS,"PIG existing rough-wall bonus activates at a distance")
 t.check(t.action(g,"wall_move",{"direction":"away"}).ok and g.state.wall_distance==4 and g.at_wall(),"PIG paid movement changes distance without losing support")
 t.check(g.state.logs.any(func(log):return log.data.has("wall_distance") and log.text.contains("距墙4格") and log.text.contains("仍提供贴墙")),"PIG movement log distinguishes position and effect")
 g.state.wall="none";g.state.posture="lie"
 t.check(g.at_wall() and g._wall_bonus()==0 and t.find_action(g,"posture",{"dest":"sit","wall":true}).valid,"PIG support also works without a room wall but creates no rough surface")
 g=Game.new(42,true,"equipment");g.state.relics=["little_pig"];g.state.wall_distance=1
 var item=g.state.items[0]
 t.check(not t.find_action(g,"item_install",{"item":item.id}).valid and not t.find_action(g,"hook").valid,"PIG cannot reach actual wall tools or hook remotely")
 g.state.wall_distance=0
 t.check(t.action(g,"item_install",{"item":item.id,"mount":"hand_wall"}).ok,"PIG actual wall installation still works")
 g.state.wall_distance=1
 t.check(not t.find_action(g,"item_retrieve",{"item":item.id}).valid and g.InstalledTools.reason(g,g._item(item.id),g.action_targets()[0]).contains("墙边"),"PIG installed use and retrieval retain real contact requirement")
 var Explore=preload("res://tests/exploration_cases.gd")
 var SpaceFixture=preload("res://tests/exploration_fixture.gd")
 g=Explore.fresh(true);Explore.set_legs(g,2);SpaceFixture.position(g,[3,3])
 t.check(g.Prison.Space.fall_profile(g).chance>0,"PIG exploration fixture would normally check a fall")
 g.RelicEffects.gain(g,"little_pig")
 before=g.export_snapshot()
 t.check(t.action(g,"prison",{"action":"explore","direction":"west","steps":1}).ok and g.state.posture=="stand" and g.state.rng.fall==before.rng.fall and g.state.prison.space.position!=before.prison.space.position,"PIG actual blind exploration moves but does not roll a fall")
 SpaceFixture.position(g,[0,3])
 t.check(g.Prison.Space.wall_warning(g,[[1,3],[2,3]]).contains("仍提供贴墙"),"PIG physical departure warning preserves virtual support")

static func mouth_installation(t) -> void:
 for type in ["shard","saw"]:
  for pose in ["stand","sit","lie"]:
   var g=Fixture.new(42);g.state.equipment.clear();g.state.posture=pose
   g.add_fixture("fingers",4);g.add_fixture("toes",4);g._gain_tool(type)
   var target=g.add_fixture("upper_arm",4);var item=g.state.items[0]
   var mount={"stand":"high_wall","sit":"hand_wall","lie":"foot_wall"}[pose]
   var c=t.find_action(g,"item_install",{"item":item.id,"mount":mount})
   var before=g.export_snapshot()
   t.check(c.valid and c.payload.operator=="mouth" and c.detail.contains("嘴部"),"MOUTH each tool has the correct posture-specific mouth route")
   t.check(not t.find_action(g,"item_use",{"item":item.id,"target":target.id}).valid,"MOUTH installation permission does not allow mouth-held cutting")
   t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==before,"MOUTH stale install is atomic")
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==before.energy-1 and g._item(item.id).mount==mount and g._item(item.id).uses==before.items[0].uses,"MOUTH installation pays once and preserves tool charges")
   t.check(g.state.logs.any(func(log):return log.data.get("installation",{}).get("operator","")=="mouth" and log.text.contains("用嘴部")),"MOUTH actual installation operator reaches the log")
   t.check(t.find_action(g,"item_retrieve",{"item":item.id}).valid,"MOUTH height route also allows retrieval")
   g.add_fixture("mouth",4)
   t.check(g.InstalledTools.reason(g,g._item(item.id),target)=="","MOUTH fixed tool contact remains when mouth becomes blocked")
   t.check(not g.Tools.install_operators(g,mount,type).has("mouth"),"MOUTH blocked mouth removes installation route")
 var g=Fixture.new(42);g.state.equipment.clear();g.add_fixture("fingers",4);g.add_fixture("toes",4);g._gain_tool("shard")
 var item=g.state.items[0];var before=g.export_snapshot()
 t.check(not t.action(g,"item_install",{"item":item.id,"mount":"foot_wall"}).ok and g.export_snapshot()==before,"MOUTH standing cannot reach floor slot by mouth")
 for pose in ["sit","lie"]:
  g.state.posture=pose;before=g.export_snapshot()
  var bad="foot_wall" if pose=="sit" else "hand_wall"
  t.check(not t.action(g,"item_install",{"item":item.id,"mount":bad}).ok and g.export_snapshot()==before,"MOUTH wrong installation height cannot be bypassed")
 g.state.posture="stand";g.state.wall_distance=1;before=g.export_snapshot()
 t.check(not t.action(g,"item_install",{"item":item.id,"mount":"high_wall"}).ok and g.export_snapshot()==before,"MOUTH still requires wall contact")
 g.state.wall_distance=0;g.state.energy=0;before=g.export_snapshot()
 t.check(not t.action(g,"item_install",{"item":item.id,"mount":"high_wall"}).ok and g.export_snapshot()==before,"MOUTH insufficient energy leaves all state unchanged")
 g.state.energy=3;g.state.wall="none"
 t.check(not t.find_action(g,"item_install",{"item":item.id,"mount":"high_wall"}).valid,"MOUTH cannot invent a wall slot")
 g.state.wall="rough"
 t.check(g.Tools.install_operators(g,"high_wall","picks").is_empty() and g.Tools.install_operators(g,"high_wall","return_seal").is_empty(),"MOUTH whitelist includes only two declared tools")
 t.check(t.action(g,"item_install",{"item":item.id,"mount":"high_wall"}).ok,"MOUTH real first installation succeeds")
 g._gain_tool("saw");before=g.export_snapshot()
 t.check(not t.action(g,"item_install",{"item":g.state.items[-1].id,"mount":"high_wall"}).ok and g.export_snapshot()==before,"MOUTH existing slot capacity is preserved")
 for e in g.equipment_at("fingers"): e.durability=0
 g._cleanup();g.add_fixture("mouth",4)
 t.check(g.Tools.install_operators(g,"hand_wall","saw")==["hand"],"MOUTH blockage does not close an existing hand route")

static func true_bonus(t) -> void:
 var g=Fixture.new(42)
 g.state.phase="prepare";g.state.prepare_left=3;g.state.wall_distance=0
 var a=g.add_fixture("wrist",8,10,true)
 g.add_fixture("wrist",8,10,true)
 for mode in ["strain","magic_slip"]:
  g.state.wall="normal"
  var ordinary=g.escape_preview(a,mode,5)
  g.state.wall="rough"
  var rough=g.escape_preview(a,mode,5)
  t.check(is_equal_approx(rough.damage-ordinary.damage,2.0) and rough.bonus==ordinary.bonus,"WALL true bonus is outside stack lock and tightness multipliers "+mode)
  t.check(g._formula(rough).contains("＋2粗糙墙面真实加成") and not g._formula(rough).contains("属性与环境"),"WALL formula separates environment true bonus")
 g.state.equipment.clear()
 a=g.add_fixture("ankle",10)
 var preview=g.escape_preview(a,"slip",5)
 t.check(preview.immune and preview.scaled_damage==0 and preview.environment_true==2 and preview.damage==2,"WALL tier-three immunity only blocks ordinary slip")
 var card=t.hand_card(g,"slip")
 t.check(t.action(g,"card",{"uid":card.uid,"slot":"ankle","target":a.id}).ok and g._equipment(a.id).durability==8,"WALL true bonus commits exact damage through ordinary card")
 a=g._equipment(a.id)
 t.check(g.escape_preview(a,"slip",1,[],true).environment_true==0,"WALL passive movement has no added wall damage")
 g.state.posture="lie"
 t.check(g.escape_preview(a,"strain",5).environment_true==0,"WALL lying has no environmental damage")
 g.state.posture="stand";g.state.wall_distance=1
 t.check(g.escape_preview(a,"strain",5).environment_true==0,"WALL distance removes environmental damage")
 g.state.wall_distance=0
 var eye=g.add_fixture("eyes",4)
 var blocked=g.escape_preview(eye,"strain",5)
 t.check(blocked.reason!="" and blocked.damage==0 and blocked.environment_true==0,"WALL true damage does not invent a forbidden method")
 var locked=g.add_fixture("thigh",6,10,true)
 var initial=locked.durability
 g._apply_equipment_damage(locked,5,"cut")
 t.check(locked.durability==maxf(0,initial-5),"WALL cutting stays fixed and never adds wall damage")

static func capture_blocks_movement(t) -> void:
 for type in ["guard","drone","binding_box"]:
  var g=Fixture.new(42);g.state.enemies=[]
  var enemy=g._append_enemies([{"type":type,"grade":2}])[0]
  g.state.wall_distance=2;g.state.energy=10
  var previous=t.find_action(g,"wall_move",{"direction":"toward"})
  t.check(previous.valid,"BIND MOVE unbound movement exists before "+type)
  g.CaptureBind.apply_bind(g,enemy)
  var before=g.export_snapshot()
  for direction in ["toward","away"]:
   var c=t.find_action(g,"wall_move",{"direction":direction})
   t.check(not c.valid and c.reason=="被捕缚时无法移动，先解除捕缚。","BIND MOVE both directions show a precise restriction for "+type)
   t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"BIND MOVE rejection preserves position, energy, turn, RNG and bind")
  t.check(not g.dispatch(g.command(previous.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"BIND MOVE formerly available movement is rechecked at submission")
  t.check(g.CaptureBind.view(g).detail.contains("被捕缚时无法移动"),"BIND MOVE status explains the restriction")
  g.CaptureBind.damage_bind(g,100.0,"测试解除")
  var distance=g.state.wall_distance
  t.check(t.action(g,"wall_move",{"direction":"toward"}).ok and g.state.wall_distance<distance,"BIND MOVE release restores formal movement for "+type)
