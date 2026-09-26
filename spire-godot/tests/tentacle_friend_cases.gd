extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Installed=preload("res://tests/installed_tools_cases.gd")

static func grant(g) -> void:
 g.RelicEffects.gain(g,"tentacle_friend")

static func run(t) -> void:
 var g=Game.new(42)
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="tentacle_friend")
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,"rare",excluded)=="tentacle_friend","FRIEND real rare reward pool")
 g.add_fixture("fingers",8);g.add_fixture("toes",8);g.add_fixture("wrist",8)
 g._install_template("mouth_band","mouth",12.8,16,false,"fixture",2)
 g.state.mana=40;g._gain_tool("mana_potion");var item=g.state.items.back().id
 t.check(not t.find_action(g,"item_use",{"item":item}).valid,"FRIEND blocked potion before pickup")
 grant(g)
 t.check(not g.hands_can_hold() and g.hand_blocked("fingers","left"),"FRIEND item assistance does not free actual hands")
 t.check(t.action(g,"item_use",{"item":item}).ok and g.state.mana==50 and g._item(item).is_empty(),"FRIEND standing bound drink retains mouth half effect and single use")
 t.check(g.Consumables.potion_amount(g,3)==2,"FRIEND severity four still rounds upward")
 var mouth=g.equipment_at("mouth")[0];mouth.grade=3;mouth.durability=mouth.maximum
 t.check(g.Consumables.potion_amount(g,3)==1,"FRIEND greater severity still rounds downward")
 mouth.grade=2;mouth.durability=12.8
 g._gain_tool("mana_scroll");item=g.state.items.back().id
 t.check(t.action(g,"item_use",{"item":item}).ok and g.state.temporary_mana==10 and g._item(item).is_empty(),"FRIEND bound fingers and toes can consume scroll")
 g.state.flask_mana=10;g.state.mana=40
 t.check(t.action(g,"flask",{"op":"withdraw"}).ok and g.state.flask_mana==0 and g.state.mana==45,"FRIEND flask uses shared potion permission but keeps mouth loss")
 g._gain_tool("mana_potion");g.state.mana=g.state.mana_max
 t.check(not t.find_action(g,"item_use",{"item":g.state.items.back().id}).valid,"FRIEND full mana still has no valid potion effect")
 g=Installed.fresh();g.state.wall="none";g.state.wall_distance=3
 var target=g.add_fixture("wrist",80,100,true);g._gain_tool("shard");item=g.state.items[0].id
 t.check(g.InstalledTools.select(g,target,"strain").is_empty(),"FRIEND carried cutter originally has no passive")
 grant(g)
 var before=g.export_snapshot();var view=g.get_view();g.command_facts()
 t.check(g.state==before and view.items[0].installed and view.items[0].mount=="触手固定" and view.items[0].contact_text.contains("全身"),"FRIEND virtual fixing is a read-only projection")
 t.check(not t.find_action(g,"item_install",{"item":item}).valid and not t.find_action(g,"item_use",{"item":item,"target":target.id}).valid,"FRIEND fixed carry follows passive rather than direct cutting")
 var c=t.find_action(g,"card",{"uid":t.hand_card(g,"strain").uid,"target":target.id,"free":false})
 t.check(c.valid and c.payload.tool_bonus.damage==5,"FRIEND no wall needed for real passive preview")
 var expected=target.durability-c.payload.preview.damage-5
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(target.id).durability,expected) and g._item(item).uses==2 and g._item(item).mount=="carry","FRIEND real card applies fixed damage and consumes one use while remaining carried")
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,before.version-1),before.version-1).ok and g.state==before,"FRIEND stale card cannot repeat tool proc")
 g._leave_mounted_tools()
 t.check(not g._item(item).is_empty() and g.carried_items()==1,"FRIEND virtual fixed tool travels and occupies inventory")
 t.check(["neck","shoulder"].all(func(point):return point in g.Tools.reach(g,g._item(item))),"FRIEND range also includes neck and shoulder attachment points")
 for slot in ["eyes","mouth","upper_arm","forearm","wrist","palm","fingers","thigh","calf","ankle","foot","toes"]:
  g=Installed.fresh();grant(g);target=g.add_fixture(slot,8);g._gain_tool("shard")
  t.check(not target.is_empty() and g.Tools.contact_reason(g,target,g.state.items[0])=="","FRIEND full body contact: "+slot)
 # Actual head target, not only lower-body range projection.
 g=Installed.fresh();grant(g);g.state.wall="none";g.state.wall_distance=3
 target=g.add_fixture("eyes",80,100,false,0,"eye_tape");g._gain_tool("shard")
 t.check(Installed.play(t,g,target,"slip").ok and g.state.items[0].uses==2,"FRIEND eye equipment receives real fixed cutter bonus")
 g=Installed.fresh();grant(g);target=g._install_template("cable_tie","wrist",8,10,false,"fixture");g._gain_tool("shard")
 t.check(g.InstalledTools.select(g,target,"strain").is_empty(),"FRIEND material mismatch still blocks cutter")
 g._gain_tool("saw");g.state.items[1].uses=0
 t.check(g.InstalledTools.select(g,target,"strain").is_empty(),"FRIEND exhausted compatible cutter cannot proc")
 g=Installed.fresh();grant(g);target=g.add_fixture("wrist",8);g.add_fixture("wrist",8,10,false,1);g._gain_tool("shard")
 t.check(g.InstalledTools.select(g,target,"strain").is_empty(),"FRIEND outer layer still protects covered target")
 g=Installed.fresh();grant(g);g.add_fixture("fingers",8);g.add_fixture("wrist",8);g.state.posture="lie"
 target=g.add_fixture("ankle",8,10,true);g._gain_tool("picks");item=g.state.items.back().id
 t.check(g.get_view().items[0].target_groups.any(func(row):return row.id=="ankle"),"FRIEND unrestricted unlock exposes actual target group")
 t.check(t.action(g,"item_use",{"item":item,"target":target.id}).ok and not g._equipment(target.id).locked and g._item(item).uses==1,"FRIEND locked lower body can be unlocked with bound hands")
 t.check(not t.find_action(g,"item_use",{"item":item,"target":target.id}).valid,"FRIEND unlocked equipment is not a valid lock target")
 g=Installed.fresh();g.state.posture="lie";g.state.wall_distance=3
 g._gain_tool("saw");item=g.state.items[0].id;g.state.items[0].mount="high_wall"
 t.check(not t.find_action(g,"item_retrieve",{"item":item}).valid,"FRIEND normal unreachable installed tool cannot be retrieved")
 grant(g)
 t.check(t.action(g,"item_retrieve",{"item":item}).ok and g._item(item).mount=="carry" and g._item(item).uses==2,"FRIEND retrieves existing fixed tool without posture or reach restriction")
 g=Installed.fresh();grant(g);g.state.wall="none";g.state.wall_distance=3
 target=g._install_special("nipple_ring_low","special_1_a");g._gain_tool("shard")
 t.check(g.SpecialEquipment.environment_contact(g,target,"sharp") and g.InstalledTools.reason(g,g.state.items[0],target)=="","FRIEND compatible special equipment uses carried sharp environment")
