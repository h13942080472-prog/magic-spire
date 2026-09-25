extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func setup(x: int=1, witch: bool=false):
 var g=Game.new(42,false,"equipment",true,false,25,false,false,"witch" if witch else "original")
 g._discard_end();g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[]
 g.state.relics=[];g.state.mana=0;g.state.energy=x
 return g

static func run(t) -> void:
 var g=setup()
 t.check("self_binding" in g.Cards.Rules.UNCOMMON and "self_binding" in g.Cards.Rules.REWARDS and g.Cards.Rules.SPECS.self_binding.card_type=="skill","SELF BIND registered as an uncommon skill in rewards and shop pool")
 t.check(g.Cards.Rules.energy_label("self_binding")=="X" and g.Cards.Rules.distinct_faces("self_binding"),"SELF BIND static cost is X, not zero, and its different effects support replay")
 for x in [1,2,3]:
  g=setup(x);g.state.evasion=2
  var card=Give.give(g,"self_binding")
  var before=g.export_snapshot()
  var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
  t.check(c.valid and c.cost==x and c.payload.x==x,"SELF BIND free legal grade sums for X="+str(x))
  g.get_view();g.command_facts()
  t.check(g.export_snapshot()==before,"SELF BIND preview changes no resources, random streams, cards or equipment")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==before,"SELF BIND stale submission is atomic")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"SELF BIND free executes through dispatch")
  t.check(g.state.equipment.size()==2 and g.state.equipment.all(func(item):return item.slot in g.B.LEG_SLOTS and item.grade+g.tier(item.durability,item.maximum)==2*x and not item.locked),"SELF BIND both real leg items meet the individual sum and stay unlocked")
  t.check(g.state.energy==0 and g.state.mana==15*x and g.state.evasion==2 and g.state.discard.any(func(item):return item.uid==card.uid),"SELF BIND pays all energy, restores mana and discards; voluntary cost cannot be dodged")
  var restored=Save.roundtrip(t,g,"self-binding X="+str(x))
  if restored!=null: t.check(restored.state.equipment==g.state.equipment and restored.state.mana==g.state.mana,"SELF BIND restored equipment and mana are not applied again")
 for x in [0,4]:
  g=setup(x);var card=Give.give(g,"self_binding");var before=g.export_snapshot()
  var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
  t.check(not c.valid and c.reason.contains("品质＋紧度") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"SELF BIND impossible grade sum refuses without effects")
 g=setup();var card=Give.give(g,"self_binding")
 for slot in g.B.LEG_SLOTS:
  for point in (g.Equipment.points(slot) if g.Equipment.SEGMENTS.has(slot) else [""]):
   for n in range(g._capacity(slot)):
    g._install_template("tape",slot,4,10,false,"fixture",1,-1,0,point)
 var removed=g.state.equipment.pop_back()
 var before=g.export_snapshot()
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 t.check(not c.valid and c.reason.contains("足够位置") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"SELF BIND only one slot refuses the whole two-item cost and refund")
 g.state.equipment.pop_back();c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var old_ids=g.state.equipment.map(func(item):return item.id)
 t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.equipment.size()==old_ids.size()+2 and old_ids.all(func(id):return not g._equipment(id).is_empty()),"SELF BIND exact two-slot boundary succeeds without replacing existing equipment")
 t.check(g._equipment(removed.id).is_empty(),"SELF BIND removed fixture is not recreated")
 for x in [0,1,4]:
  g=setup(x);card=Give.give(g,"self_binding")
  for n in range(x): g._install_template("tape","thigh",4,10,false,"fixture",1,n,0,"mid_thigh")
  # X=4 needs four distinct physical positions rather than exceeding local capacity.
  if x==4:
   g.state.equipment=[]
   for slot in ["thigh","calf","ankle","foot"]: g.add_fixture(slot,4)
  var locked=g._install_template("belt","wrist",10,10,false,"fixture")
  before=g.export_snapshot();c=t.find_action(g,"card",{"uid":card.uid,"free":false})
  t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"SELF BIND complete bound capacity succeeds for X="+str(x))
  t.check(g.state.equipment.all(func(item):return g.tier(item.durability,item.maximum)==3 and not item.locked) and not g._equipment(locked.id).locked,"SELF BIND only tightens; a tier-three lockable item stays unlocked")
  t.check(g.state.energy==0 and g.state.mana==15*x,"SELF BIND X=0 has no gain; bound X above three uses the full original energy")
 g=setup(2);card=Give.give(g,"self_binding");g.add_fixture("ankle",4)
 before=g.export_snapshot();c=t.find_action(g,"card",{"uid":card.uid,"free":false})
 t.check(not c.valid and c.reason.contains("需要收紧4档") and c.reason.contains("只能收紧2档") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"SELF BIND insufficient tightening never partially tightens or grants mana")
 g=setup(1);card=Give.give(g,"self_binding");g.add_fixture("ankle",4);g.add_fixture("foot",4)
 g.Cards.grant_buff(g,"echo_cast_bound")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.energy==0 and g.state.mana==30 and g.state.equipment.all(func(item):return g.tier(item.durability,item.maximum)==3),"SELF BIND replay retains original X after payment and tightens another two tiers")
 g=setup(1);card=Give.give(g,"self_binding");g.add_fixture("ankle",4);g.Cards.grant_buff(g,"echo_cast_bound")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.mana==15 and g.state.logs.any(func(log):return log.data.get("replay",{}).get("skipped",false)),"SELF BIND replay with insufficient remaining capacity is skipped without extra mana")
 g=setup(1);g.state.mana=95;card=Give.give(g,"self_binding");g.add_fixture("ankle",4)
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.mana==100,"SELF BIND mana recovery respects the existing maximum")
 g=setup(1,true);g.state.witch_charges.legs=4;card=Give.give(g,"self_binding")
 t.check(g.Character.allowed_card(g,"self_binding") and t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.equipment.size()==2 and g.state.witch_charges.legs==4,"SELF BIND both characters can obtain the card; voluntary equipping cannot consume charge to avoid its cost")
 g=setup(1);card=Give.give(g,"self_binding")
 g.state.phase="rest";g.state.rest_left=3
 before=g.export_snapshot();c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 t.check(not c.valid and c.reason=="休息房禁止卡牌自由效果。" and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.export_snapshot()==before,"SELF BIND original rest-room free-face restriction still takes priority")
