extends RefCounted

# Shared bar and source effects. Enemy action cycles remain in their own planners.
const BIND_TARGET="guard_bind"
const BIND_MAXIMUM=100.0
const BIND_GAIN=10.0
const LOWER_DAMAGE=8.0

static func kind(g, enemy: Dictionary) -> String:
 return g.Enemies.TYPES[enemy.type].get("capture_kind","")

static func energy_threshold(g, source_kind) -> int:
 return {"iron_man":g.IronMan.ENERGY_THRESHOLD,"iron_drone":g.IronMan.DRONE_ENERGY_THRESHOLD,"drone":2}.get(source_kind,1)

static func initial_value(g, enemy: Dictionary) -> float:
 if enemy.type=="iron_man": return g.IronMan.capture_start(enemy)
 return float(g.Enemies.encounter_member(g.state,enemy.type).get("capture_start",g.Enemies.TYPES[enemy.type].capture_start))

static func gain_amount(g, enemy: Dictionary) -> float:
 return float(g.Enemies.encounter_member(g.state,enemy.type).get("capture_gain",BIND_GAIN))

static func has_bind(g, source_kind: String="") -> bool:
 return g.state.phase=="battle" and not g.state.guard_bind.is_empty() and (source_kind=="" or g.state.guard_bind.sources.has(source_kind))

static func capture_ready(state: Dictionary) -> bool:
 return state.phase=="battle" and state.get("guard_bind",{}).get("progress",0.0)>=BIND_MAXIMUM

static func movement_reason(g) -> String:
 return "被捕缚时无法移动，先解除捕缚。" if has_bind(g) else ""

static func fixed_posture(g) -> String:
 var allowed=allowed_postures(g)
 if allowed.size()==1 or (not allowed.is_empty() and g.state.posture not in allowed): return allowed[0]
 return ""

static func allowed_postures(g) -> Array:
 if g.RopeArt.hogtied(g): return ["lie"]
 if not has_bind(g): return []
 var allowed=["stand","sit","lie"]
 for source in g.state.guard_bind.sources.values():
  var spec=g.Enemies.TYPES[g._enemy(source.enemy).type]
  var poses=spec.get("capture_poses",[])
  if poses.is_empty() and spec.get("capture_pose","")!="": poses=[spec.capture_pose]
  if not poses.is_empty(): allowed=allowed.filter(func(pose):return pose in poses)
 return allowed

static func posture_reason(g, destination: String) -> String:
 var allowed=allowed_postures(g)
 if not allowed.is_empty() and destination not in allowed: return "捕缚只允许保持%s，先解除捕缚。" % "或".join(allowed.map(func(pose):return g.B.POSE_NAMES[pose]))
 var fixed=fixed_posture(g)
 if fixed!="" and destination!=fixed: return "捕缚将你固定为%s，先解除捕缚。" % g.B.POSE_NAMES[fixed]
 if has_bind(g,"guard") and g.state.posture+">"+destination not in ["lie>sit","sit>stand"]: return "捕缚生效时，姿态切换顺序为躺姿→坐姿→站姿。"
 return ""

static func clear_bind(g, battle_ended: bool=false) -> void:
 # In-battle immunity must not retain a battle-only status during teardown.
 if not battle_ended and g.RopeArt.bound(g): return
 g.state.guard_bind={}
 for enemy in g.state.enemies:
  if kind(g,enemy)!="": enemy.guard.bind_ready=false

static func apply_bind(g, enemy: Dictionary) -> void:
 var source_kind=kind(g,enemy)
 enemy.guard.bind_ready=false
 if has_bind(g,source_kind):
  g._emit("event",enemy.name+"的同类捕缚已经生效，没有重复叠加。")
  return
 var initial=initial_value(g,enemy)
 var amount=initial*0.5 if has_bind(g) else initial
 if not has_bind(g): g.state.guard_bind={"progress":0.0,"sources":{}}
 g.state.guard_bind.sources[source_kind]={"enemy":enemy.id,"energy":0}
 # Enemy-first application already happens after this player turn's upkeep.
 if g.Enemies.TYPES[enemy.type].get("capture_turn_install",false): g.state.guard_bind.sources[source_kind].skip_turn_start=g.state.order=="first"
 enemy.guard.cycle_step=0
 var before=float(g.state.guard_bind.progress)
 g.state.guard_bind.progress=minf(BIND_MAXIMUM,before+amount)
 var fixed=fixed_posture(g)
 if fixed!="": g.state.posture=fixed
 # Requery after correction: multiple legal poses do not mean a fixed posture.
 fixed=fixed_posture(g)
 var pose_text="你被固定为%s。" % g.B.POSE_NAMES[fixed] if fixed!="" else ""
 g._emit("event",enemy.name+"施加捕缚，进度增加%s，现为%s/100。" % [g.number(g.state.guard_bind.progress-before),g.number(g.state.guard_bind.progress)]+pose_text,{"guard_bind":{"action":"apply","source":enemy.id,"before":before,"value":g.state.guard_bind.progress}})
 if source_kind=="iron_man": g.IronMan.apply_capture_equipment(g,enemy)
 observe(g)

static func gain_bind(g, amount: float, source: String) -> void:
 if not has_bind(g) or amount<=0: return
 var before=float(g.state.guard_bind.progress)
 g.state.guard_bind.progress=minf(BIND_MAXIMUM,before+amount)
 g._emit("event",source+"使捕缚进度增加%s，现为%s/100。" % [g.number(g.state.guard_bind.progress-before),g.number(g.state.guard_bind.progress)],{"guard_bind":{"action":"gain","before":before,"value":g.state.guard_bind.progress}})
 observe(g)

static func damage_bind(g, amount: float, source: String) -> void:
 if g.RopeArt.bound(g): return
 if not has_bind(g) or amount<=0: return
 var before=float(g.state.guard_bind.progress)
 var dealt=minf(before,amount)
 g.state.guard_bind.progress=maxf(0.0,before-amount)
 g._emit("mechanical",source+"削减%s点捕缚进度：%s → %s。" % [g.number(dealt),g.number(before),g.number(g.state.guard_bind.progress)],{"guard_bind":{"action":"damage","before":before,"damage":dealt,"value":g.state.guard_bind.progress}})
 if g.state.guard_bind.progress<=0:
  var iron_removed=has_bind(g,"iron_man")
  clear_bind(g)
  g._emit("event","捕缚已挣开。")
  if iron_removed: g.IronMan.capture_removed(g)
 observe(g)

static func damage_multiplier(g) -> float:
 for item in g.action_targets():
  if g.SpecialEquipment.is_special(item) or g.Equipment.coverage(item).any(func(slot):return slot not in ["eyes","mouth"]): return 1.0
 return 2.0

static func energy_spent(g, amount: int, guard_effect: bool=false) -> void:
 if amount<=0: return
 if guard_effect: g.Guard.energy_spent(g)
 for source_kind in g.state.guard_bind.get("sources",{}).keys():
  if energy_threshold(g,source_kind)<=1: continue
  if not has_bind(g,source_kind): continue
  var source=g.state.guard_bind.sources[source_kind]
  source.energy+=amount
  var enemy=g._enemy(source.enemy)
  var threshold=energy_threshold(g,source_kind)
  while source.energy>=threshold:
   source.energy-=threshold
   if source_kind=="iron_man": g.IronMan.energy_trigger(g,enemy)
   elif source_kind=="iron_drone": g.IronMan.drone_energy_trigger(g,enemy)
   else:
    g._enemy_operation(enemy,g.EnemyPlans.application(g.Enemies.TYPES[enemy.type].install_pool,1,2,1,false,3))
    gain_bind(g,BIND_GAIN,enemy.name+"的捕缚")

static func overload(g, count: int) -> void:
 if count>0 and has_bind(g,"guard"): gain_bind(g,float(count)*BIND_GAIN,"高潮")

static func turn_start(g) -> void:
 if not has_bind(g): return
 for source in g.state.guard_bind.sources.values():
  var enemy=g._enemy(source.enemy)
  var spec=g.Enemies.TYPES[enemy.type]
  if not enemy.gone and spec.get("capture_turn_install",false):
   # A newly applied capture starts its recurring effect after one player turn.
   if source.get("skip_turn_start",false):
    source.skip_turn_start=false
    continue
   g._enemy_operation(enemy,g.EnemyPlans.application(spec.capture_pool,2,2,1,false,4))
   gain_bind(g,gain_amount(g,enemy),enemy.name+"的捕缚")

# Empty means keep the already announced ordinary intent (and its interruption).
static func required_intent(g, enemy: Dictionary) -> String:
 var source_kind=kind(g,enemy)
 if source_kind==g.RopeArt.MASTER: return ""
 if source_kind=="": return ""
 if capture_ready(g.state) and g.EnemyPlans.can_arrest(g,enemy): return "capture"
 if source_kind=="iron_man":
  # Keep a still-required opening capture, including its delayed flag.
  return "bind_apply" if g.IronMan.intent_facts(enemy,g.state).kind=="bind_apply" else ""
 if source_kind=="guard" and enemy.stage==1: return "guard_sequence"
 if not has_bind(g,source_kind):
  return "bind_apply" if enemy.guard.bind_ready or (source_kind!="guard" and enemy.stage==1) else "bind_prepare"
 return ""

static func observe(g) -> void:
 if g.state.phase!="battle": return
 g.RopeArt.observe(g)
 if has_bind(g):
  for source_kind in g.state.guard_bind.sources.keys():
   var source=g.state.guard_bind.sources[source_kind]
   var enemy=g._enemy(source.enemy)
   if not enemy.is_empty() and enemy.gone:
    g.state.guard_bind.sources.erase(source_kind)
    g._emit("event",enemy.name+"离场，它的捕缚效果随之解除。")
  if g.state.guard_bind.sources.is_empty(): clear_bind(g)
 var fixed=fixed_posture(g)
 if fixed!="": g.state.posture=fixed
 for enemy in g.state.enemies:
  if enemy.gone or kind(g,enemy)=="": continue
  var expected=required_intent(g,enemy)
  var current=enemy.intent.get("kind","")
  if (expected!="" and current!=expected) or (expected=="" and current in ["bind_prepare","bind_apply","capture"]): enemy.intent=g._plan(enemy)

static func view(g) -> Dictionary:
 if not has_bind(g): return {}
 var descriptions=[];var names=[]
 if has_bind(g,"guard"): descriptions.append("警卫捕缚：只能躺姿→坐姿→站姿，每次切换使捕缚＋10；花能量和快感达到上限时触发警卫效果。")
 if has_bind(g,"drone"): descriptions.append("无人机捕缚：固定为站姿；每累计消耗2能量，施加1件初级2档胶带并使捕缚＋10。当前累计%d/2能量。" % g.state.guard_bind.sources.drone.energy)
 if has_bind(g,"iron_man"): descriptions.append("铁男捕缚：只允许坐姿或躺姿；每累计消耗%d能量，触发全部主动刺激型特殊装备。当前累计%d/%d能量。" % [energy_threshold(g,"iron_man"),g.state.guard_bind.sources.iron_man.energy,energy_threshold(g,"iron_man")])
 if has_bind(g,"iron_drone"): descriptions.append("凑数型无人机捕缚：每累计消耗%d能量，施加1件初级2档胶带、捕缚＋5，遥控1件主动刺激型特殊装备并消耗1电量，再随机上锁1件拘束具。当前累计%d/%d能量。" % [energy_threshold(g,"iron_drone"),g.state.guard_bind.sources.iron_drone.energy,energy_threshold(g,"iron_drone")])
 if has_bind(g,"binding_box"): descriptions.append("拘束盒捕缚：固定为坐姿；施加后从第二个玩家回合起，每个玩家回合开始施加1件中级2档皮革拘束具，并使捕缚＋%s。" % g.number(gain_amount(g,g._enemy(g.state.guard_bind.sources.binding_box.enemy))))
 for source in g.state.guard_bind.sources.values(): names.append(g._enemy(source.enemy).name)
 var detail="被捕缚时无法移动，先解除捕缚。挣扎／滑脱牌可直接削减进度；除眼罩、口球外没有其他拘束具时伤害翻倍，环境加成为0。上身受限至少按1级计算。同种捕缚仅生效一次；新种类增加其初始值的一半。降至0全部解除，达到100后下一敌方回合执行收押。\n降紧每层固定削减8点捕缚，使用固定数值，蓄力保留。"
 if g.RopeArt.bound(g): detail="进度为当前绳索拘束值之和。不能直接解除捕缚；拆除或松解绳索可降低进度，降至0时附魔暂停。达到100后执行收押。"
 return {"name":"捕缚","value":g.state.guard_bind.progress,"maximum":BIND_MAXIMUM,"source":"、".join(names),"text":"捕缚进度 %s/100" % g.number(g.state.guard_bind.progress),"detail":detail+"\n"+"\n".join(descriptions)}

static func validate(g) -> String:
 var bind=g.state.guard_bind
 if bind.is_empty(): return ""
 if not g.Snapshot.fields(bind,"progress:n sources:d") or g.state.phase!="battle" or bind.progress<0 or (bind.progress==0 and not bind.sources.has(g.RopeArt.MASTER)) or bind.progress>BIND_MAXIMUM or bind.sources.is_empty(): return "捕缚进度记录缺损。"
 for source_kind in bind.sources:
  var source=bind.sources[source_kind]
  var threshold=energy_threshold(g,source_kind)
  if not g.Snapshot.fields(source,"enemy:s energy:i") or source.energy<0 or source.energy>=threshold: return "捕缚能量记录有误。"
  var enemy=g._enemy(source.enemy)
  if enemy.is_empty() or enemy.gone or kind(g,enemy)!=source_kind: return "捕缚缺少存活的对应来源。"
 var allowed=allowed_postures(g)
 if not allowed.is_empty() and g.state.posture not in allowed: return "固定捕缚与当前姿态存在差异。"
 return ""
