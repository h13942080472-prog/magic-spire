extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const O=preload("res://core/drone_operator.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Battle="drone_operator_solo"

static func end(t,g) -> bool:
 var result=t.action(g,"end")
 t.check(result.ok,"OPERATOR real end-turn command commits: "+result.get("error",""))
 return result.ok

static func owner(g) -> Dictionary:
 return g.state.enemies.front()

static func unit(g) -> Dictionary:
 return g._enemy(owner(g).drone_unit)

static func run(t) -> void:
 var orders={}
 for seed in range(1,30):
  var g=Game.new(seed,true,Battle)
  if not end(t,g): return
  var queue=owner(g).drone_queue.duplicate()
  orders[str(queue)]=true
  if orders.size()==6: break
 t.check(orders.size()==6,"OPERATOR seeded triples can take every permutation")
 battle(t)
 interrupted(t)
 stacking(t)
 saturated(t)
 capture(t)

static func battle(t) -> void:
 var g=Game.new(53,true,Battle)
 t.check(owner(g).hp==108 and g.Enemies.TYPES[O.TYPE].humanoid and g.state.enemies.size()==1 and owner(g).intent.kind==O.SUMMON,"OPERATOR solitary 108 HP humanoid announces summon first")
 t.check(Battle in g.Tower.strong_groups(1) and Battle not in g.Tower.strong_groups(0),"OPERATOR only Act II strong pools include the battle")
 end(t,g)
 t.check(unit(g).hp==20 and g.Enemies.TYPES[O.DRONE].mechanical and unit(g).intent.kind=="bind_apply" and g.state.guard_bind.is_empty(),"OPERATOR summon creates a 20 HP machine and gives a full turn of warning")
 t.check(g.EnemyPlans.installation_intents(g,owner(g)).is_empty() and g.EnemyPlans.installation_intents(g,unit(g))==[O.tape(g,owner(g)),O.tape(g,owner(g),true)],"OPERATOR equipment queries belong to the drone that performs them")
 var initial=owner(g).drone_queue.duplicate();var actions=[]
 for i in 3:
  var action=owner(g).intent.kind
  actions.append(action)
  var before=g.export_snapshot()
  g.get_view();g.command_facts()
  t.check(g._plan(owner(g)).kind==action and g.export_snapshot()==before,"OPERATOR previews leave action order and RNG unchanged")
  var drone_view=g.get_view().enemies.filter(func(e):return e.id==unit(g).id)[0]
  var detail=drone_view.intent_icons[0].detail
  if action==O.TOOLS:
   owner(g).intent.delayed=true
   t.check(not g.get_view().enemies.filter(func(e):return e.id==unit(g).id)[0].intent_icons[0].detail.contains("追加"),"OPERATOR interrupted first payload upgrade adds no toy to the preview")
   owner(g).intent.delayed=false
  var previous_toys=g.state.special_equipment.size()
  var previous=g.state.equipment.size()
  end(t,g)
  var added_toys=g.state.special_equipment.size()-previous_toys
  t.check(detail.ends_with("追加%d件玩具" % added_toys) if added_toys>0 else not detail.contains("追加"),"OPERATOR visible intent predicts the toys applied after the handler acts")
  if i==0:
   t.check(g.state.guard_bind.progress==30 and g.CaptureBind.fixed_posture(g)=="stand","OPERATOR first drone action applies the normal standing capture")
  else:
   var new_items=g.state.equipment.slice(previous)
   t.check(new_items.size()==2 and new_items.all(func(e):return e.template in g.Enemies.TYPES[O.DRONE].install_pool and e.grade+g.equipment_tier(e)==2+owner(g).drone_power),"OPERATOR salvo fits two tape items at the upgraded value")
  if action==O.SHIELD:
   t.check(owner(g).mech_armor==8 and unit(g).mech_armor==8,"OPERATOR protection grants eight armor to both actors")
   g._damage_enemy(unit(g),4,"magic","fixture")
   t.check(unit(g).hp==20 and unit(g).mech_armor==4 and owner(g).mech_armor==8,"OPERATOR damage is absorbed by the target's own shield")
 t.check(initial==actions and owner(g).drone_tools==1 and owner(g).drone_power==1 and g.state.special_equipment.size()==1,"OPERATOR each first block gives exactly one of each upgrade and a matching extra toy")
 var toy=g.state.special_equipment.front()
 t.check(toy.grade+g.equipment_tier(toy)==3 and g.state.guard_bind.progress==50,"OPERATOR toy profile matches the current salvo and each salvo added ten capture")
 var next=owner(g).drone_queue.duplicate()
 var first=unit(g).id
 g.CaptureBind.energy_spent(g,1)
 g._damage_enemy(unit(g),999,"magic","fixture")
 t.check(owner(g).intent.kind==O.REPAIR and owner(g).drone_progress==50 and g.state.guard_bind.is_empty() and g.CaptureBind.fixed_posture(g)=="" and g.CaptureBind.movement_reason(g)=="","OPERATOR destruction suspends all capture rules and immediately replaces the announced upgrade")
 var worn=g.state.equipment.size()
 g.CaptureBind.energy_spent(g,2)
 t.check(g.state.equipment.size()==worn and owner(g).drone_progress==50,"OPERATOR energy spent during downtime cannot fit tape or advance progress")
 var restored=Save.roundtrip(t,g,"operator awaiting repair")
 if restored!=null:
  var bad=restored.export_snapshot()
  bad.enemies.front().drone_queue=[O.TOOLS,O.TOOLS,O.TOOLS]
  var before=restored.export_snapshot()
  t.check(not restored.restore_snapshot(bad).ok and restored.export_snapshot()==before,"OPERATOR duplicate upgrade in a saved block fails atomically")
 end(t,g)
 t.check(unit(g).id!=first and unit(g).hp==20 and unit(g).stage==1 and owner(g).drone_queue==next and owner(g).drone_repairs==1 and owner(g).drone_tools==1 and owner(g).drone_power==1,"OPERATOR repair creates a fresh machine and resumes the same upgrade block")
 t.check(g.state.guard_bind.progress==50 and g.state.guard_bind.sources.drone.enemy==unit(g).id and g.state.guard_bind.sources.drone.energy==0 and g.CaptureBind.fixed_posture(g)=="stand","OPERATOR repairs restore only progress and bind the live machine without another opening bonus")
 g.CaptureBind.energy_spent(g,2)
 var passive=g.state.equipment.slice(worn)
 t.check(passive.size()==2 and passive.all(func(e):return e.grade+g.equipment_tier(e)==4) and g.state.guard_bind.progress==60,"OPERATOR repaired capture passive adds two upgraded tapes and ten progress")
 var before=g.state.equipment.size()
 end(t,g)
 t.check(g.state.equipment.size()==before+3 and g.state.guard_bind.progress==70,"OPERATOR repaired salvo fits three tapes and still grants just ten capture")
 g._damage_enemy(unit(g),999,"magic","fixture");end(t,g)
 t.check(unit(g).hp==20 and owner(g).drone_repairs==2 and g.state.guard_bind.progress==70,"OPERATOR successive repairs permanently increase the tape count again")
 Save.roundtrip(t,g,"operator repaired twice")
 owner(g).hp=1;g.state.sure_cast=true
 var target=owner(g).id
 t.check(t.action(g,"attack",{"type":"fireball","enemy":target}).ok and g.state.phase!="battle" and unit(g).gone and g.state.guard_bind.is_empty(),"OPERATOR actual lethal attack on handler wins immediately with a live drone")

static func interrupted(t) -> void:
 var g=Game.new(17,true,Battle)
 owner(g).intent.delayed=true;end(t,g)
 t.check(g.state.enemies.size()==1 and owner(g).intent.kind==O.SUMMON,"OPERATOR interrupted summon waits without consuming the opener")
 end(t,g)
 var queue=owner(g).drone_queue.duplicate()
 owner(g).intent.delayed=true
 g._damage_enemy(unit(g),999,"magic","fixture");end(t,g)
 t.check(unit(g).gone and owner(g).drone_queue==queue and owner(g).intent.kind==O.REPAIR and g.state.guard_bind.is_empty(),"OPERATOR delayed upgrade becomes delayed repair; no new capture before first application")
 end(t,g)
 t.check(unit(g).intent.kind=="bind_apply" and g.state.guard_bind.is_empty(),"OPERATOR fresh drone presents normal capture if predecessor never applied it")
 end(t,g)
 g.CaptureBind.damage_bind(g,100,"fixture")
 t.check(unit(g).intent.kind=="bind_prepare","OPERATOR breaking a live capture changes the next salvo to preparation")
 end(t,g)
 t.check(unit(g).intent.kind=="bind_apply" and g.state.guard_bind.is_empty(),"OPERATOR preparation costs its own action")
 end(t,g)
 t.check(g.state.guard_bind.progress==30 and unit(g).intent.kind==O.SALVO,"OPERATOR released capture reapplies normally before returning to salvo")

static func stacking(t) -> void:
 var g=Game.new(53,true,Battle)
 end(t,g)
 for i in 6:
  end(t,g)
 t.check(owner(g).drone_tools==2 and owner(g).drone_power==2,"OPERATOR two complete shuffled blocks stack each permanent upgrade twice")
 g._damage_enemy(unit(g),999,"magic","fixture")
 end(t,g)
 t.check(owner(g).drone_tools==2 and owner(g).drone_power==2 and owner(g).drone_repairs==1,"OPERATOR rebuilt drone inherits multiple layers and the larger magazine")
 # Reapplication also benefits from the per-action toy upgrade; the energy passive does not.
 g.CaptureBind.damage_bind(g,100,"fixture")
 var previous=g.state.special_equipment.size()
 var tools_before=owner(g).drone_tools+int(owner(g).intent.kind==O.TOOLS)
 end(t,g)
 t.check(g.state.special_equipment.size()==previous+tools_before and unit(g).intent.kind=="bind_apply","OPERATOR even preparing capture fits one toy per current upgrade")
 var request=O.tape(g,owner(g))
 var buffed=owner(g).duplicate(true)
 buffed.drone_power=10
 var high=O.tape(g,buffed)
 t.check(request.count==3 and high.profiles==[{"grade":3,"tier":3}] and O.toys(g,buffed).profiles==high.profiles,"OPERATOR over-cap upgrade values select valid maximum profiles for both equipment pools")

static func saturated(t) -> void:
 var g=Game.new(53,true,Battle)
 var fill=O.tape(g,owner(g))
 fill.count=100
 g.Application.execute(g,fill,"fixture")
 t.check(not g.Application.can_apply(g,fill,"fixture"),"OPERATOR saturated fixture has no legal tape position")
 end(t,g)
 t.check(unit(g).intent.kind=="bind_apply","OPERATOR full tape slots cannot replace initial capture with arrest")
 end(t,g)
 var before=g.state.equipment.size()
 t.check(unit(g).intent.kind==O.SALVO and g.state.guard_bind.progress==30,"OPERATOR full tape slots still announce the only ordinary attack")
 end(t,g)
 t.check(g.state.phase=="battle" and g.state.equipment.size()==before and g.state.guard_bind.progress==40,"OPERATOR missing tape positions cannot turn a low meter into an arrest")

static func capture(t) -> void:
 var g=Game.new(4,true,Battle)
 end(t,g);end(t,g)
 g.CaptureBind.gain_bind(g,70,"fixture")
 t.check(unit(g).intent.kind=="capture","OPERATOR the live drone announces arrest at 100")
 g._damage_enemy(unit(g),999,"magic","fixture")
 end(t,g)
 t.check(g.state.phase=="battle" and unit(g).intent.kind=="capture" and g.state.guard_bind.progress==100,"OPERATOR saving a full capture meter still gives the repaired drone its arrival grace round")
 end(t,g)
 t.check(g.state.phase=="captured","OPERATOR full capture uses the ordinary prison settlement")
