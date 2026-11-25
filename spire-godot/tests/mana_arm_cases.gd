extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")

static func run(t) -> void:
 var g=Game.new(42);g.state.energy=20
 var id=g.state.enemies[0].id
 g.state.enemies[0].hp=500;g.state.enemies[0].max_hp=500
 t.check(Give.play(t,g,"finesse",true).ok and Give.play(t,g,"finesse",true).ok and g.state.energy==16,"FINESSE free powers stack at two energy apiece")
 t.check(Give.play(t,g,"mana_arm",true).ok and Give.play(t,g,"mana_arm",true).ok,"MANA ARM free skill stacks")
 g.state.temporary_mana=6;g.state.mana=4
 var c=t.find_action(g,"attack",{"type":"strike","enemy":id,"form":1})
 var before=g.export_snapshot()
 t.check(c.valid and c.mana==10 and c.payload.hits==2 and c.payload.damage==18 and g.state==before,"MANA ARM multi-hit preview includes two seven-point charge layers")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.charge==0 and g.state.enemies[0].hp==464 and g.state.mana==0 and g.state.temporary_mana==0,"MANA ARM multi-hit pays and consumes only once")
 c=t.find_action(g,"attack",{"type":"strike","enemy":id,"form":0})
 t.check(c.valid and c.mana==0 and c.payload.damage==8,"MANA ARM insufficient mana falls back to normal attack")
 t.check(Give.play(t,g,"mana_arm",false).ok and not Give.play(t,g,"mana_arm",false).ok,"MANA ARM bound is unique this turn")
 g.state.posture="lie";g.add_fixture("wrist",8);g.add_fixture("forearm",8);g.add_fixture("upper_arm",8)
 g.state.mana=4.9
 c=t.find_action(g,"attack",{"type":"strike","enemy":id})
 t.check(not c.valid and c.mana==0,"MANA ARM unpaid bound face keeps actual restrictions")
 g.state.mana=10
 c=t.find_action(g,"attack",{"type":"strike","enemy":id,"form":0})
 t.check(c.valid and c.payload.damage==15 and c.mana==10 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==0 and g.state.posture=="lie","MANA ARM funds bound freedom then one free layer without changing posture")
 g.state.mana=5
 c=t.find_action(g,"attack",{"type":"kick","enemy":id,"form":1})
 t.check(not c.valid and c.mana==5,"MANA ARM legs keep posture limits")
 g.state.posture="stand"
 c=t.find_action(g,"attack",{"type":"kick","enemy":id,"form":1})
 t.check(c.valid and c.mana==5 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==0,"MANA ARM bound surcharge applies once to a sweep")
 t.check(Give.play(t,g,"finesse",false).ok and not Give.play(t,g,"finesse",false).ok,"FINESSE bound power is unique")
 t.check(g.state.charge==0 and t.action(g,"status_toggle",{"status":"charge"}).ok and not g.charge_uses_all(),"FINESSE can preselect one at zero charge")
 t.action(g,"status_toggle",{"status":"charge"})
 g._gain_charge(3)
 t.check(g.charge_bonus()==21 and t.action(g,"status_toggle",{"status":"charge"}).ok and g.charge_bonus()==7,"FINESSE switches enhanced charge between all and one")
 var copy=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"finesse and stacked mana arm")
 t.check(copy!=null and not copy.charge_uses_all() and copy.Cards.buff_stacks(copy,"mana_arm_free")==2,"FINESSE keeps selected mode on restore")
 t.check(t.action(g,"end").ok and "mana_arm_free" not in g.state.card_buffs and "mana_arm_bound" not in g.state.card_buffs and not g.charge_uses_all(),"MANA ARM expires at turn boundary, finesse persists")
 g=Game.new(42);g.state.energy=20
 for enemy in g.state.enemies: enemy.hp=300;enemy.max_hp=300
 t.check(Give.play(t,g,"mana_attachment",true).ok and Give.play(t,g,"mana_arm",true).ok and Give.play(t,g,"mana_arm",false).ok,"MANA ARM combines both faces with attachment")
 g.state.charge=0;g.state.temporary_mana=0
 for budget in [15,20]:
  g.state.mana=budget
  c=t.find_action(g,"attack",{"type":"strike","enemy":g.state.enemies[0].id})
  var area=budget==20
  t.check(c.valid and c.payload.all==area and c.payload.arm_freedom and c.payload.attack_charge==1 and c.payload.damage==(5.5 if area else 11.0),"MANA ARM combined preview allocates arm costs before area damage")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==(0 if area else 5) and g.state.charge==0,"MANA ARM combined payment charges only the funded effects")
