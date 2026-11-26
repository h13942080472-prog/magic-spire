extends RefCounted

const TYPE="drone_operator"
const DRONE="operator_drone"
const SUMMON="operator_summon"
const REPAIR="operator_repair"
const TOOLS="operator_tools"
const BINDING="operator_binding"
const SHIELD="operator_shield"
const SALVO="operator_salvo"
const Upgrades=[TOOLS,BINDING,SHIELD]
const Actions=[SUMMON,REPAIR,TOOLS,BINDING,SHIELD,SALVO]
const ToyMoves=["bind_prepare","bind_apply",SALVO]
const Names={SUMMON:"召唤无人机",REPAIR:"维修精进",TOOLS:"道具强化",BINDING:"拘束强化",SHIELD:"防护强化",SALVO:"胶带齐射"}
const ARMOR=8.0

static func initialize(e: Dictionary) -> void:
 e.mech_armor=0.0
 if e.type==TYPE:
  e.drone_unit=""
  e.drone_queue=[]
  e.drone_tools=0
  e.drone_power=0
  e.drone_repairs=0
  e.drone_progress=0.0

# Freeze each group on an executed action. Rendering and interruptions never draw RNG.
static func refill(g, owner: Dictionary) -> void:
 var remaining=Upgrades.duplicate()
 while not remaining.is_empty(): owner.drone_queue.append(remaining.pop_at(g._random_index("enemy",remaining.size())))

static func tape(g, owner: Dictionary, passive: bool=false) -> Dictionary:
 var count=(1 if passive else 2)+owner.drone_repairs
 var value=mini(6,(3 if passive else 2)+owner.drone_power)
 var request=g.EnemyPlans.application(g.Enemies.TYPES[DRONE].install_pool,1,1,count,false,value)
 request.allow_links=false
 return request

static func toys(g, owner: Dictionary) -> Dictionary:
 var request=g.EnemyPlans.special_application(g,{"type":DRONE})
 request.count=owner.drone_tools
 request.profiles=g.RestraintValue.profiles(mini(6,2+owner.drone_power))
 return request

static func installations(g, e: Dictionary) -> Array:
 var owner=g._enemy(e.drone_owner)
 var result=[tape(g,owner),tape(g,owner,true)]
 if owner.drone_tools>0: result.append(toys(g,owner))
 return result

static func owner_plan(g, owner: Dictionary) -> Dictionary:
 var move=SUMMON
 if owner.drone_unit!="":
  move=REPAIR if g._enemy(owner.drone_unit).gone else owner.drone_queue.front()
 var text=Names[move]
 if move==REPAIR and owner.drone_progress>0: text="%s · 恢复%s捕缚" % [text,g.number(owner.drone_progress)]
 if move==SHIELD: text="%s · 双方获得8护甲" % text
 return {"kind":move,"text":text,"delayed":false}

static func salvo(g, e: Dictionary) -> Dictionary:
 var owner=g._enemy(e.drone_owner)
 return {"kind":SALVO,"text":"胶带齐射 · %d件胶带，捕缚＋10" % (2+owner.drone_repairs),"delayed":false}

static func summon(g, owner: Dictionary, repairing: bool) -> void:
 if repairing: owner.drone_repairs+=1
 else: refill(g,owner)
 var drone=g._append_enemies([{"type":DRONE,"grade":1}])[0]
 drone.guard.bind_ready=true
 drone.drone_owner=owner.id
 owner.drone_unit=drone.id
 drone.acted_round=g.state.round
 var progress=owner.drone_progress
 owner.drone_progress=0.0
 if progress>0: g.CaptureBind.apply_bind(g,drone,progress)
 drone.intent=g._plan(drone)
 g._emit("event",Names[REPAIR if repairing else SUMMON]+" · "+drone.name,{"summoned":{"enemy":drone.id,"owner":owner.id}})

static func execute(g, e: Dictionary, move: String) -> void:
 if move in [SUMMON,REPAIR]:
  summon(g,e,move==REPAIR)
 elif move==SALVO:
  g._enemy_operation(e,tape(g,g._enemy(e.drone_owner)))
  g.CaptureBind.gain_bind(g,10,e.name)
 else:
  var drone=g._enemy(e.drone_unit)
  match move:
   TOOLS: e.drone_tools+=1
   BINDING: e.drone_power+=1
   SHIELD:
    e.mech_armor+=ARMOR
    drone.mech_armor+=ARMOR
  e.drone_queue.pop_front()
  if e.drone_queue.is_empty(): refill(g,e)
  g._emit("event",Names[move],{"operator_upgrade":move})

static func after_drone_action(g, drone: Dictionary, move: String) -> void:
 if move not in ToyMoves: return
 var owner=g._enemy(drone.drone_owner)
 if owner.drone_tools>0: g._enemy_operation(drone,toys(g,owner),move=="bind_apply")

static func begin_turn(g, owner: Dictionary) -> void:
 owner.mech_armor=0.0
 var drone=g._enemy(owner.drone_unit)
 if not drone.is_empty(): drone.mech_armor=0.0

static func defeat(g, e: Dictionary) -> void:
 if e.type==DRONE:
  var owner=g._enemy(e.drone_owner)
  var bind=g.state.guard_bind
  if bind.get("sources",{}).get("drone",{}).get("enemy","")==e.id and bind.sources.size()==1:
   owner.drone_progress=bind.progress
  if not owner.gone and not g.EnemyPlans.long_battle_limit(g):
   var delayed=owner.intent.get("delayed",false)
   owner.intent=owner_plan(g,owner)
   owner.intent.delayed=delayed
 elif e.type==TYPE:
  var drone=g._enemy(e.drone_unit)
  if not drone.is_empty() and not drone.gone:
   drone.hp=0.0;drone.gone=true;drone.intent={}
  e.drone_progress=0.0

static func issue(g, s: Dictionary) -> String:
 var owners={}
 var drones={}
 for e in s.enemies:
  if e.type==TYPE: owners[e.id]=e
  elif e.type==DRONE: drones[e.id]=e
  elif e.intent.get("kind","") in Actions or e.has("drone_owner") or e.has("drone_unit"): return "无人机行动来源有误。"
 for e in owners.values()+drones.values():
  if not g.Snapshot.fields(e,"mech_armor:n") or not is_finite(e.mech_armor) or e.mech_armor<0 or e.mech_armor>ARMOR: return "操作员小队生命或护甲有误。"
 for owner in owners.values():
  if not g.Snapshot.fields(owner,"drone_unit:s drone_queue:z drone_tools:i drone_power:i drone_repairs:i drone_progress:n"): return "操作员强化记录缺损。"
  if mini(owner.drone_tools,mini(owner.drone_power,owner.drone_repairs))<0 or not is_finite(owner.drone_progress) or owner.drone_progress<0 or owner.drone_progress>100: return "操作员强化数值有误。"
  var queue=owner.drone_queue
  if queue.size()>3 or queue.any(func(move):return move not in Upgrades or queue.count(move)!=1): return "操作员强化次序有误。"
  var move=owner.intent.get("kind","")
  if owner.drone_unit=="":
   if not queue.is_empty() or owner.drone_repairs+owner.drone_tools+owner.drone_power+owner.drone_progress>0 or move not in ["","capture",SUMMON]: return "操作员召唤记录有误。"
  else:
   var drone=drones.get(owner.drone_unit,{})
   if drone.get("drone_owner","")!=owner.id or queue.is_empty() or (owner.drone_progress>0 and not drone.gone): return "操作员维修记录有误。"
   var fitted=drones.values().filter(func(unit):return unit.get("drone_owner","")==owner.id)
   var used=owner.stage-2-owner.drone_repairs
   if fitted.size()!=owner.drone_repairs+1 or fitted.back().id!=drone.id or used<0 or queue.size()!=3-used%3: return "操作员维修或行动次数有误。"
   var sets=floori(used/3.0)
   if owner.drone_power!=sets+int(BINDING not in queue) or owner.drone_tools!=sets+int(TOOLS not in queue): return "操作员强化次数有误。"
   if move not in ["","capture",REPAIR if drone.gone else queue.front()]: return "操作员行动预告有误。"
 for drone in drones.values():
  var owner=owners.get(drone.get("drone_owner",""),{})
  if owner.is_empty() or (not drone.gone and (owner.gone or owner.drone_unit!=drone.id)): return "召唤无人机缺少操作员。"
  if drone.intent.get("kind","") not in ["","bind_prepare","bind_apply","capture",SALVO]: return "召唤无人机行动有误。"
 return ""
