extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func fresh() -> RefCounted:
 var g=Game.new(42);g.state.equipment.clear();g.state.composites.clear();g.state.links.clear();g.state.items.clear();g.state.strength=0;g.state.dexterity=0;g.state.wall="normal"
 return g

static func play(t,g,target,type: String="strain") -> Dictionary:
 if not g.state.deck.any(func(c):return c.type==type): g._gain_card(type)
 var card=t.hand_card(g,type)
 return t.action(g,"card",{"uid":card.uid,"target":target.id,"free":false})

static func run(t) -> void:
 for posture in ["stand","sit","lie"]:
  for slot in ["upper_arm","thigh","calf","foot"]:
   var g=fresh();g.state.posture=posture;g.state.wall="none";g.state.wall_distance=3
   var target=g.add_fixture(slot,8,10,true)
   var knife=t.take_item_card(g,"shard")
   var permitted=slot in {"stand":["upper_arm","thigh"],"sit":["thigh","calf","foot"],"lie":["upper_arm","calf","foot"]}[posture]
   var fields={"uid":knife,"target":target.id,"free":true}
   var choice=t.find_action(g,"card",fields)
   var before=g.export_snapshot()
   t.check(choice.valid==permitted and t.action(g,"card",fields).ok==permitted,"TOOL wall-side reach follows posture: "+posture+slot)
   if permitted:
    t.check(g.state.energy==before.energy-1 and g._equipment(target.id).durability==3 and g.Cards.instance(g,knife).remove_left==2,"TOOL successful wall-side play pays once and ignores lock reduction")
   else:
    t.check(g.state==before,"TOOL wrong posture is atomic")
 var g=fresh();var target=g.add_fixture("wrist",8,10,true)
 var knife=t.take_item_card(g,"shard")
 t.check(play(t,g,target).ok and g.Cards.instance(g,knife).remove_left==3,"TOOL ordinary struggle spends no cutter uses")
 g=fresh();target=g._install_template("cable_tie","thigh",8,10,false,"fixture")
 knife=t.take_item_card(g,"shard");var saw=t.take_item_card(g,"saw")
 t.check(not t.find_action(g,"card",{"uid":knife,"target":target.id}).valid and t.find_action(g,"card",{"uid":saw,"target":target.id}).valid,"TOOL stone and saw keep their original material restrictions")
 var snapshot=g.export_snapshot()
 var read=g.get_view()
 t.check(g.state==snapshot and not read.statuses.any(func(row):return row.has("item_id")),"TOOL card preview never creates a passive environment status")
