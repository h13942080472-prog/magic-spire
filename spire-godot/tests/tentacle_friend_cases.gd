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
 g.state.mana=40;var item=t.take_item_card(g,"mana_potion")
 t.check(not t.find_action(g,"card",{"uid":item}).valid,"FRIEND blocked potion before pickup")
 grant(g)
 t.check(not g.hands_can_hold() and g.hand_blocked("fingers","left"),"FRIEND item assistance does not free actual hands")
 t.check(t.action(g,"card",{"uid":item}).ok and g.state.mana==50 and g.Cards.instance(g,item).is_empty(),"FRIEND standing bound drink retains mouth half effect and single use")
 t.check(g.Consumables.potion_amount(g,3)==2,"FRIEND severity four still rounds upward")
 var mouth=g.equipment_at("mouth")[0];mouth.grade=3;mouth.durability=mouth.maximum
 t.check(g.Consumables.potion_amount(g,3)==1,"FRIEND greater severity still rounds downward")
 mouth.grade=2;mouth.durability=12.8
 item=t.take_item_card(g,"mana_scroll")
 t.check(t.action(g,"card",{"uid":item}).ok and g.state.temporary_mana==10 and g.Cards.instance(g,item).is_empty(),"FRIEND bound fingers and toes can consume scroll")
 g.state.flask_mana=10;g.state.mana=40
 t.check(t.action(g,"flask",{"op":"withdraw"}).ok and g.state.flask_mana==0 and g.state.mana==45,"FRIEND flask uses shared potion permission but keeps mouth loss")
 item=t.take_item_card(g,"mana_potion");g.state.mana=g.state.mana_max
 t.check(not t.find_action(g,"card",{"uid":item}).valid,"FRIEND full mana still has no valid potion effect")
 for slot in ["eyes","mouth","upper_arm","forearm","wrist","palm","fingers","thigh","calf","ankle","foot","toes"]:
  g=Installed.fresh();grant(g);g.state.wall="none";g.state.wall_distance=3
  var target=g.add_fixture(slot,8,10,false,0,"eye_tape" if slot=="eyes" else "")
  item=t.take_item_card(g,"shard")
  t.check(t.action(g,"card",{"uid":item,"target":target.id}).ok and g.Cards.instance(g,item).remove_left==2,"FRIEND hand-held cutter can reach "+slot)
 g=Installed.fresh();grant(g)
 var target=g._install_template("cable_tie","wrist",8,10,false,"fixture")
 item=t.take_item_card(g,"shard")
 t.check(not t.find_action(g,"card",{"uid":item,"target":target.id}).valid,"FRIEND material mismatch still blocks cutter")
 g=Installed.fresh();grant(g);target=g.add_fixture("wrist",8);g.add_fixture("wrist",8,10,false,1)
 item=t.take_item_card(g,"shard")
 t.check(not t.find_action(g,"card",{"uid":item,"target":target.id}).valid,"FRIEND outer layer still protects covered target")
 g=Installed.fresh();grant(g);g.add_fixture("fingers",8);g.add_fixture("wrist",8);g.state.posture="lie"
 target=g.add_fixture("ankle",8,10,true);item=t.take_item_card(g,"picks")
 t.check(t.action(g,"card",{"uid":item,"target":target.id}).ok and not g._equipment(target.id).locked and g.Cards.instance(g,item).remove_left==1,"FRIEND locked ankle opens despite bound hands")
