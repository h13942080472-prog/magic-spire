extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func attack(t,g,type: String,form: int) -> Dictionary:
 return t.find_action(g,"attack",{"type":type,"form":form,"enemy":g.state.enemies[0].id})

static func run(t) -> void:
 body_part_projection(t)
 zero_energy_fireball(t)

 ordinary_kicks(t)
 continuous_kick(t)
 justice_opening(t)
 interrupt_cooldown(t)
 bound_kick_cooldown(t)
 bound_kick_scaling(t)
 body_damage_scaling(t)
 for item in [["strike",0,8.0,1,1],["strike",1,4.0,2,1],["heavy",0,18.0,1,2],["heavy",1,6.0,3,2]]:
  var g=Game.new(42)
  var c=attack(t,g,item[0],item[1]);var id=g.state.enemies[0].id
  var hp=g._enemy(id).hp;var energy=g.state.energy;var count=g.state.logs.size()
  t.check(c.valid and c.payload.damage==item[2] and c.payload.hits==item[3] and c.cost==item[4],"BASIC each form exposes correct cost and per-hit damage")
  t.check(c.brief==g.number(item[2])+(" × %d" % item[3] if item[3]>1 else "")+" 伤害","BASIC compact preview preserves per-hit values and hit count")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._enemy(id).hp==hp-item[2]*item[3] and g.state.energy==energy-item[4],"BASIC multi-hit pays once and applies each hit")
  t.check(g.state.logs.slice(count).filter(func(log):return log.data.has("hit")).size()==item[3],"BASIC multi-hit emits separate damage events")
 var g=Game.new(42)
 g.add_fixture("wrist",4)
 var elbow=attack(t,g,"strike",0);var heavy=attack(t,g,"heavy",0)
 t.check(heavy.valid and is_equal_approx(heavy.payload.damage/18.0,elbow.payload.damage/8.0),"BASIC restricted arms scale both attacks equally")
 g.add_fixture("ankle",4)
 t.check(not attack(t,g,"heavy",0).valid and not attack(t,g,"heavy",1).valid,"BASIC leg restraint blocks both short-strike forms")
 g=Game.new(42);g.state.kick_last=g.state.round
 var hp=g.state.enemies.map(func(e):return e.hp)
 var sweep=attack(t,g,"kick",1)
 t.check(sweep.valid and sweep.payload.damage==5.0 and sweep.cost==1 and sweep.payload.all and not sweep.payload.interrupt,"BASIC sweep remains reusable after interrupt kick")
 for i in range(2):
  sweep=attack(t,g,"kick",1)
  t.check(g.dispatch(g.command(sweep.payload,g.state.version),g.state.version).ok,"BASIC sweep can repeat with enough energy")
 for i in range(g.state.enemies.size()):
  t.check(g.state.enemies[i].hp==hp[i]-10 and not g.state.enemies[i].intent.get("delayed",false),"BASIC sweep hits every original living target without interrupt")
 g=Game.new(42);g.state.enemies[0].hp=1
 var other_hp=g.state.enemies[1].hp
 var c=attack(t,g,"strike",1);var start=g.state.logs.size()
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.enemies[0].gone and g.state.enemies[1].hp==other_hp and g.state.logs.slice(start).filter(func(log):return log.data.has("hit")).size()==1,"BASIC early kill stops remaining hits without retargeting")
 var before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,before.version-1),before.version-1).ok and g.state==before,"BASIC stale form submission rolls back")

static func zero_energy_fireball(t) -> void:
 var g=Game.new(42);g.state.energy=0
 var target=g.state.enemies[0];target.hp=100;target.max_hp=100
 var c=attack(t,g,"fireball",0);var before=g.export_snapshot()
 g.get_view();g.command_facts()
 t.check(not c.valid and c.cost==1 and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"FIREBALL first use requires one energy and rejected previews cannot consume it")
 g.state.energy=1
 for used in range(2):
  c=attack(t,g,"fireball",0);before=g.export_snapshot()
  t.check(c.valid and c.cost==(1 if used==0 else 0) and c.mana==10,"FIREBALL first costs one then zero, retaining mana cost")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"FIREBALL stale submission cannot consume first-use record")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==0 and g.state.mana==before.mana-10 and g._enemy(target.id).hp==before.enemies[0].hp-c.payload.damage and g.BasicAttacks.usage(g,"fireball").used==used+1,"FIREBALL correct payment, damage and shared use count")
 c=attack(t,g,"fireball",0);before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("次数") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"FIREBALL zero later cost cannot bypass turn limit")
 var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"fireball first use paid")
 t.check(restored!=null and attack(t,restored,"fireball",0).cost==0,"FIREBALL snapshot retains paid first use")
 g.state.energy=2
 t.check(preload("res://tests/curse_cases.gd").play(t,g,"rekindle",true).ok and attack(t,g,"fireball",0).cost==0,"FIREBALL refreshing uses does not charge first use again")
 t.check(t.action(g,"end").ok and attack(t,g,"fireball",0).cost==1,"FIREBALL next real turn resets first-use fee")
 g._start_battle()
 t.check(attack(t,g,"fireball",0).cost==1,"FIREBALL new battle starts with first-use fee")
 g=Game.new(42);g.state.energy=1;g.state.mana=9
 c=attack(t,g,"fireball",0);before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("魔力") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"FIREBALL insufficient mana does not consume first use")
 g=Game.new(42)
 t.check(preload("res://tests/card_expansion_cases.gd").cast(t,g,"flame_flourish",false).ok,"FIREBALL enable equipment casting through actual ability")
 var restraint=g.add_fixture("thigh",60.0,60.0,true);g.state.energy=1
 c=t.find_action(g,"attack",{"target":restraint.id});before=g.export_snapshot()
 t.check(c.valid and c.cost==1 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==0 and g.state.mana==before.mana-c.mana and g._equipment(restraint.id).durability==60.0-c.payload.damage and attack(t,g,"fireball",0).cost==0,"FIREBALL equipment first cast pays once and shares enemy first-use state")

static func ordinary_kicks(t) -> void:
 var restraints=[[],["thigh"],["ankle"],["ankle","foot"],["thigh","calf","ankle","foot","toes"]]
 for posture in ["stand","sit","lie"]:
  for severity in range(restraints.size()):
   var g=Game.new(42);g.state.posture=posture
   for slot in restraints[severity]: g.add_fixture(slot,4)
   t.check(g.level("legs")==severity,"KICK fixture uses actual leg severity")
   var c=attack(t,g,"kick",2)
   var allowed=(posture=="stand" and severity==0) or (posture=="sit" and severity<4)
   t.check(c.valid==allowed and c.cost==1 and not c.payload.interrupt and not c.payload.fall and not c.payload.all,"KICK third form checks stance-specific severity without interrupt or fall")
   var before=g.export_snapshot()
   if allowed:
    var expected=(8.0 if posture=="stand" else 6.0)*[1.0,1.0,0.8,0.6][severity]
    t.check(is_equal_approx(c.payload.damage,expected) and c.label==("站着踢" if posture=="stand" else "坐着踢"),"KICK stance name and reduced damage match actual severity")
    var hp=g.state.enemies[0].hp;var other=g.state.enemies[1].hp
    t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g.state.enemies[0].hp,hp-expected) and g.state.enemies[1].hp==other,"KICK third form applies actual single-target physical damage")
    t.check(g.state.energy==before.energy-1 and g.state.kick_last==before.kick_last and g.state.posture==posture and not g.state.enemies[0].intent.get("delayed",false),"KICK ordinary use pays energy without changing interrupt cooldown, posture or enemy intent")
    t.check(g.dispatch(g.command(attack(t,g,"kick",2).payload,g.state.version),g.state.version).ok,"KICK ordinary form can repeat in the same turn")
   else:
    t.check(c.reason!="" and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"KICK unavailable stance or severity rejects without resource changes")
 var g=Game.new(42);g.state.posture="sit";g.add_fixture("ankle",4);g.add_fixture("foot",4)
 g.state.strength=2;g.state.charge=1
 var c=attack(t,g,"kick",2)
 t.check(is_equal_approx(c.payload.damage,6.6) and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.charge==0,"KICK level-three damage includes strength and consumes shared charge once")

static func continuous_kick(t) -> void:
 for energy in [0,1,2,3,5]:
  var g=Game.new(42);g.state.posture="sit";g.state.energy=energy;g.state.kick_last=g.state.round
  g.state.enemies[0].hp=200;g.state.enemies[0].max_hp=200
  var before=g.export_snapshot();var c=attack(t,g,"kick",3)
  t.check(c.valid==(energy>=1) and c.cost==energy and c.payload.x==energy and c.payload.hits==energy+1 and c.payload.damage==3 and c.payload.fall==(energy>=3),"CONTINUOUS KICK X boundary controls cost hit count and fall")
  g.get_view();g.command_facts()
  t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"CONTINUOUS KICK previews and stale submissions preserve all state")
  if energy==0:
   t.check(c.reason.contains("至少需要1") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"CONTINUOUS KICK zero energy cannot buy the bonus hit")
   continue
  t.check(c.brief=="3 × %d 伤害" % (energy+1) and g.candidate_detail(c).contains("共%d次" % (energy+1)),"CONTINUOUS KICK short and detailed previews agree on every hit")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==0 and g.state.enemies[0].hp==200-3*(energy+1) and g.state.enemies[1].hp==before.enemies[1].hp,"CONTINUOUS KICK spends all energy once and hits only the chosen enemy")
  var events=g.state.logs.slice(before.logs.size())
  var hits=events.filter(func(log):return log.data.has("hit"))
  t.check(hits.size()==energy+1 and g.state.posture==("lie" if energy>=3 else "sit") and g.state.kick_last==before.kick_last and not g.state.enemies[0].intent.delayed,"CONTINUOUS KICK has separate hits no innate interrupt and no shared cooldown")
  if energy>=3:
   t.check(events.find(hits[-1])<events.find(events.filter(func(log):return log.text=="攻击结束后，你转为躺姿。")[0]),"CONTINUOUS KICK falls only after the last damage event")
 for posture in ["stand","lie"]:
  var g=Game.new(42);g.state.posture=posture
  var c=attack(t,g,"kick",3);var before=g.export_snapshot()
  t.check(not c.valid and c.reason.contains("需要坐姿") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"CONTINUOUS KICK requires a seated posture")
 for severity in range(5):
  var g=Game.new(42);g.state.posture="sit";g.state.energy=2;g.state.strength=2;g.state.charge=1
  var restraints=[[],["thigh"],["ankle"],["ankle","foot"],["thigh","calf","ankle","foot","toes"]]
  for slot in restraints[severity]: g.add_fixture(slot,4)
  var c=attack(t,g,"kick",3);var before=g.export_snapshot()
  t.check(c.valid==(severity<4) and is_equal_approx(c.payload.damage,8*[1.0,1.0,0.8,0.6,0.4][severity]),"CONTINUOUS KICK applies strength charge and leg restrictions to every hit")
  if severity<4:
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g.state.enemies[0].hp,before.enemies[0].hp-3*c.payload.damage) and g.state.charge==0,"CONTINUOUS KICK consumes charge once for the full combo")
  else:
   t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"CONTINUOUS KICK fully restrained legs reject without payment")
 var g=Game.new(42);g.state.posture="sit";g.state.energy=3;g.state.enemies[0].hp=1
 var other_hp=g.state.enemies[1].hp
 t.check(g.dispatch(g.command(attack(t,g,"kick",3).payload,g.state.version),g.state.version).ok and g.state.enemies[0].gone and g.state.enemies[1].hp==other_hp and g.state.posture=="lie" and g.state.energy==0,"CONTINUOUS KICK early kill stops hits without retargeting or waiving payment and fall")
 g=Game.new(42);g.state.posture="sit";g.state.energy=2;g.Cards.grant_buff(g,"ready_to_strike_free")
 var c=attack(t,g,"kick",3)
 t.check(c.cost==2 and c.payload.hits==3 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==0,"CONTINUOUS KICK X payment remains all remaining energy under physical discounts")
 g=Game.new(42,true,"binding_box_solo");g.CaptureBind.apply_bind(g,g.state.enemies[0]);g.state.energy=3
 c=attack(t,g,"kick",3);var before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("无法在踢击后躺下") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"CONTINUOUS KICK capture cannot waive the mandatory fall")
 g.state.energy=2;c=attack(t,g,"kick",3)
 t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.posture=="sit","CONTINUOUS KICK captured seated player can use a non-falling combo")
 g=Game.new(42);g.state.posture="lie";g.state.energy=2;g.Cards.grant_buff(g,"kip_up_free")
 c=attack(t,g,"kick",3)
 t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.posture=="lie" and "kip_up_free" not in g.state.card_buffs,"CONTINUOUS KICK shared posture waiver permits the seated form and is consumed once")

static func interrupt_cooldown(t) -> void:
 var g=Game.new(42);g.state.energy=8
 g.state.enemies[0].hp=100;g.state.enemies[0].max_hp=100
 g.state.kick_last=1
 for i in range(3):
  var kick=attack(t,g,"kick",0);var before=g.export_snapshot()
  t.check(kick.valid and kick.label=="正义飞踢" and kick.cost==2 and kick.payload.damage==18 and not kick.payload.interrupt and not kick.payload.fall,"JUSTICE costs two deals eighteen and has no innate interrupt")
  t.check(not g.dispatch(g.command(kick.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"JUSTICE stale attack is atomic")
  t.check(g.dispatch(g.command(kick.payload,g.state.version),g.state.version).ok and g.state.energy==before.energy-2 and g.state.enemies[0].hp==before.enemies[0].hp-18 and not g.state.enemies[0].intent.delayed and g.state.kick_last==1,"JUSTICE repeats in first round without reading or extending shared cooldown")
 g.state.energy=1;var before=g.export_snapshot()
 t.check(not g.dispatch(g.command(attack(t,g,"kick",0).payload,g.state.version),g.state.version).ok and g.state==before,"JUSTICE still requires its actual energy cost")

static func justice_opening(t) -> void:
 var g=Game.new(42)
 t.check(g.state.round==1 and attack(t,g,"kick",0).valid,"JUSTICE no opening-round restriction")
 g.add_fixture("thigh",4)
 var c=attack(t,g,"kick",0);var before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("双腿活动自由") and not attack(t,g,"kick",2).valid,"JUSTICE uses the standing ordinary kick leg requirement")
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"JUSTICE restricted legs cannot bypass the candidate")
 g=Game.new(43);g._start_battle()
 t.check(attack(t,g,"kick",0).valid,"JUSTICE fresh battles do not create a cooldown or turn gate")
static func bound_kick_cooldown(t) -> void:
 for posture in ["stand","sit"]:
  var g=Game.new(42);g.state.posture=posture;g.add_fixture("ankle",4)
  g.state.relics.append("turn_ribbon");g.state.energy=20
  var c=attack(t,g,"kick",0);var before=g.export_snapshot()
  t.check(c.valid and c.cost==1 and c.payload.fall and c.payload.damage==(8 if posture=="stand" else 4) and c.payload.interrupt==(posture=="stand") and c.risk.contains("躺下"),"BOUND KICK both poses preview reduced damage with the original fall and interrupt distinction")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"BOUND KICK stale submission preserves posture cooldown and resources")
  var hp=g.state.enemies[0].hp
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.posture=="lie" and g.state.energy==19 and g.state.enemies[0].hp==hp-c.payload.damage and g.BasicAttacks.kick_cooldown(g)==3,"BOUND KICK either pose falls and starts the shared three-round cooldown")
  t.check(g.state.ribbon_tick==g.state.tick and t.action(g,"posture",{"dest":"sit","wall":false}).ok,"BOUND KICK real fall triggers ribbon and allows formal recovery")
  for elapsed in range(3):
   c=attack(t,g,"kick",0);before=g.export_snapshot()
   t.check(not c.valid and c.reason.contains("冷却") and g.BasicAttacks.kick_cooldown(g)==3-elapsed and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"BOUND KICK sitting cannot bypass cooldown or consume resources")
   t.check(t.action(g,"end").ok,"BOUND KICK real turn advances shared cooldown")
  t.check(attack(t,g,"kick",0).valid and g.BasicAttacks.kick_cooldown(g)==0,"BOUND KICK first-round use recovers on fourth round")
 var g=Game.new(42)
 g.state.round=2
 t.action(g,"attack",{"type":"kick","form":0})
 g.add_fixture("ankle",4)
 t.check(t.action(g,"posture",{"dest":"sit","wall":false}).ok,"BOUND KICK uses formal sit after ordinary justice kick")
 t.check(attack(t,g,"kick",0).valid and g.state.kick_last==-10,"BOUND KICK justice use does not start cooldown for bound variants")
 g=Game.new(42,true,"binding_box_solo");g.add_fixture("ankle",4)
 g.CaptureBind.apply_bind(g,g.state.enemies[0])
 var c=attack(t,g,"kick",0);var before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("无法在踢击后躺下") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"BOUND KICK cannot waive mandatory fall when capture fixes the sitting posture")

static func bound_kick_scaling(t) -> void:
 var fixtures=[["calf"],["ankle"],["thigh","calf","ankle"],["thigh","calf","ankle","foot","toes"]]
 for posture in ["stand","sit"]:
  for index in range(fixtures.size()):
   var g=Game.new(42);g.state.posture=posture;g.state.strength=2;g.state.charge=1
   for slot in fixtures[index]: g.add_fixture(slot,4)
   t.check(g.level("legs")==index+1 and g._bound_feet(),"BOUND KICK fixture provides actual shared leg restriction")
   var expected=([15.0,12.0,9.0,6.0] if posture=="stand" else [10.0,8.0,6.0,4.0])[index]
   var before=g.export_snapshot();var c=attack(t,g,"kick",0)
   t.check(c.valid and is_equal_approx(c.payload.damage,expected) and g.state==before,"BOUND KICK leg multiplier includes base strength and charge without preview mutation")
   t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"BOUND KICK stale scaled attack preserves all resources")
   var hp=g.state.enemies[0].hp
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g.state.enemies[0].hp,hp-expected) and g.state.charge==0 and g.state.energy==before.energy-1 and g.state.posture=="lie","BOUND KICK actual damage includes the level-four multiplier and consumes charge once")

static func body_damage_scaling(t) -> void:
 var arms=[[],["upper_arm"],["wrist"],["wrist","palm"],["upper_arm","forearm","wrist","palm","fingers"]]
 for severity in range(5):
  for form in [["strike",0,8.0,1],["strike",1,4.0,2],["heavy",0,18.0,1],["heavy",1,6.0,3]]:
   for all_charge in [false,true]:
    var g=Game.new(42)
    if form[0]=="heavy":
     t.check(preload("res://tests/curse_cases.gd").play(t,g,"hannya_1",true).ok,"BODY SCALING base bonus comes from an actual Hannya play")
    g.state.energy=3;g.state.strength=2;g.state.turn_strength=1;g.state.charge=2;g.state.charge_all=all_charge
    g.state.enemies[0].hp=500;g.state.enemies[0].max_hp=500
    for slot in arms[severity]: g.add_fixture(slot,4)
    var c=attack(t,g,form[0],form[1]);var before=g.export_snapshot()
    var base_bonus=(2 if form[1]==0 else 1) if form[0]=="heavy" else 0
    var expected=(form[2]+base_bonus+(4 if form[0]=="heavy" else 3)+(6 if all_charge else 3))*[1.0,1.0,0.8,0.6,0.4][severity]
    t.check(g.level("arms")==severity and c.valid==(severity<3) and is_equal_approx(c.payload.damage,expected),"BODY SCALING arm forms include total strength and normal/all charge before body reduction")
    t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"BODY SCALING stale preview cannot spend charge")
    if severity<3:
     t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g.state.enemies[0].hp,500-expected*form[3]) and g.state.charge==(0 if all_charge else 1),"BODY SCALING every combo hit receives frozen bonus while charge is consumed once")
    else:
     t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"BODY SCALING positive damage cannot bypass blocked arm actions")
 var g=Game.new(42);g.state.strength=2;g.state.charge=1;g.add_fixture("wrist",4)
 g.Cards.grant_buff(g,"strong_elbow_free");g.Cards.grant_buff(g,"henshin_free")
 var enemy=g._append_enemies([{"type":"drone","grade":1}])[0];enemy.hp=500;enemy.max_hp=500
 var c=t.find_action(g,"attack",{"type":"strike","form":1,"enemy":enemy.id})
 t.check(is_equal_approx(c.payload.damage,28.8) and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g._enemy(enemy.id).hp,471.2) and g.state.charge==0,"BODY SCALING bonuses receive body restriction, both attack multipliers and mechanical reduction on each hit")
 g=Game.new(42);g.state.strength=2;g.state.charge=1;g.add_fixture("thigh",4)
 var sweep=attack(t,g,"kick",1);var hp=g.state.enemies.map(func(e):return e.hp)
 t.check(sweep.valid and sweep.payload.damage==10 and g.dispatch(g.command(sweep.payload,g.state.version),g.state.version).ok and g.state.charge==0,"BODY SCALING sweep shares the body scaling formula and pays charge once")
 for i in range(hp.size()): t.check(g.state.enemies[i].hp==hp[i]-10,"BODY SCALING sweep applies the full bonus to each target")
 var legs=[[],["thigh"],["ankle"],["ankle","foot"],["thigh","calf","ankle","foot","toes"]]
 for severity in range(5):
  g=preload("res://tests/witch_character_cases.gd").fresh()
  for slot in legs[severity]: g.add_fixture(slot,4)
  t.check(g.Character.profile(g,"legs").multiplier==[1.0,0.8,0.6,0.4,0.0][severity],"BODY SCALING physical balance does not change witch leg casting chance")

static func body_part_projection(t) -> void:
 var g=Game.new(42)
 var before=g.export_snapshot()
 var view=g.get_view()
 var expected={"strike":"双臂","heavy":"双臂／双腿","kick":"双腿","fireball":"嘴部"}
 for type in expected:
  var offers=view.display_facts.filter(func(c):return c.payload.kind=="attack" and c.payload.type==type)
  t.check(not offers.is_empty() and offers.all(func(c):return c.body_part==expected[type]),"BASIC body-part projection follows every attack form "+type)
 var calm=view.display_facts.filter(func(c):return c.payload.kind=="calm")[0]
 t.check(calm.body_part=="嘴部" and calm.brief.contains(g.number(g.Pressure.calm(g).reduction)) and g.state==before,"BASIC breathing body and compact effect projection are read-only")
