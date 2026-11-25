extends RefCounted

const MINI="mini_restraint_mech"
const SUPPORT="support_restraint_mech"
const ENCOUNTER="restraint_mech_pair"
const MINI_ARMOR=10.0
const EXTRA_ARMOR=10.0
const TOY_ARMOR=6.0
const START_VALUE=3
const MAX_ORDINARY_VALUE=6
const BIND_GAIN=20.0
const SPEECH="enemy.mini_mech.entry"

const Actions={
 "mech_fit":"拳头上膛 · 施加两件拘束具",
 "mech_stun":"破甲眩晕",
 "mech_prepare":"回转蓄势",
 "mech_idle":"待机",
 "mech_extra":"再加一件 · 获得10护甲，下一批普通拘束额外＋1件",
 "mech_toy":"玩具投送 · 获得6护甲，施加一件性玩具",
}
const MiniActions=["mech_fit","mech_stun","mech_prepare"]
const SupportCycle=["mech_idle","mech_extra","mech_toy"]

static func handles(enemy: Dictionary) -> bool:
 return enemy.get("type","") in [MINI,SUPPORT]

static func initialize(enemy: Dictionary) -> void:
 enemy.mech_armor=0.0
 if enemy.type==MINI: enemy.mech_restraint_value=START_VALUE
 else: enemy.mech_extra=false

static func enter(g) -> void:
 for enemy in g.state.enemies:
  if enemy.type==MINI:
   g._emit("event",enemy.name+"：「"+g.ActionCopy.line(SPEECH,{},true)+"」",{"npc_copy":{"cue":SPEECH,"visual":MINI,"encounter":g.state.encounter,"speaker":enemy.id}})
  elif enemy.type==SUPPORT: g.CaptureBind.apply_bind(g,enemy)

static func immune(g, enemy: Dictionary) -> bool:
 return enemy.type==MINI and g.state.phase=="battle" and g.state.round%2==1

static func begin_round(g, enemy: Dictionary) -> void:
 if enemy.type!=MINI or enemy.gone: return
 if g.state.round>1 and g.CaptureBind.has_bind(g,SUPPORT): enemy.mech_restraint_value+=1
 enemy.mech_armor=MINI_ARMOR if immune(g,enemy) else 0.0
 enemy.intent=plan(g,enemy)

static func begin_enemy_turn(enemy: Dictionary) -> void:
 if enemy.type==SUPPORT: enemy.mech_armor=0.0

static func plan(g, enemy: Dictionary) -> Dictionary:
 var move=""
 if enemy.type==MINI:
  if immune(g,enemy): move="mech_fit" if enemy.mech_armor>0.0 else "mech_stun"
  else: move="mech_prepare"
 else:
  var required=g.CaptureBind.required_intent(g,enemy)
  if required=="capture": return {"kind":required,"text":"执行收押","delayed":false}
  if required=="bind_apply": return {"kind":required,"text":"重挂捕缚 · 初始%s/100" % g.number(g.CaptureBind.initial_value(g,enemy)),"delayed":false}
  move=SupportCycle[enemy.guard.cycle_step]
 var text=Actions[move]
 if move=="mech_fit" and enemy.mech_restraint_value>MAX_ORDINARY_VALUE: text="拳头上膛 · 施加两件镣铐"
 return {"kind":move,"text":text,"delayed":false}

static func installations(g, enemy: Dictionary) -> Array:
 if enemy.type==SUPPORT:
  var toy=g.EnemyPlans.special_application(g,enemy)
  toy.grade=2
  return [toy]
 var cuffs=enemy.mech_restraint_value>MAX_ORDINARY_VALUE
 var pool=g.Equipment.SHACKLES if cuffs else g.Enemies.TYPES[MINI].install_pool
 var value=g.Equipment.SHACKLE_RESTRAINT_VALUE if cuffs else enemy.mech_restraint_value
 var spec=g.EnemyPlans.application(pool,1,2,2,false,value)
 spec.allow_links=false
 if not cuffs: spec.enchantment=g.EquipmentEnchantments.TOUGH
 return [spec]

static func execute(g, enemy: Dictionary, move: String) -> void:
 match move:
  "mech_fit": g._enemy_operation(enemy,installations(g,enemy)[0])
  "mech_stun": g._emit("event",enemy.name+"因护甲破裂而眩晕。")
  "mech_prepare": g._enemy_preparation(enemy,"回转蓄势。")
  "mech_extra":
   enemy.mech_armor=EXTRA_ARMOR
   enemy.mech_extra=true
   g._emit("event",enemy.name+"获得10点护甲，并施加「再加一件」。")
  "mech_toy":
   enemy.mech_armor=TOY_ARMOR
   g._emit("event",enemy.name+"获得6点护甲。")
   g._enemy_operation(enemy,installations(g,enemy)[0])
 if enemy.type==SUPPORT: enemy.guard.cycle_step=(enemy.guard.cycle_step+1)%SupportCycle.size()

static func on_application(g, enemy: Dictionary, result: Dictionary) -> void:
 if enemy.type!=MINI or result.installed.is_empty() or not g.CaptureBind.has_bind(g,SUPPORT): return
 g.CaptureBind.gain_bind(g,BIND_GAIN,enemy.name+"的拘束")

static func reinforce_gag(g, enemy: Dictionary) -> void:
 for item in g.EnemyPlans.targets(g,enemy,"tighten",["mouth"]):
  if item.template!="mouth_band": continue
  g._enemy_operation(enemy,{"kind":"tighten","target":item.id,"tier":2,"text":"加固口球","delayed":false})
  return

static func extra_source(g) -> Dictionary:
 if g.state.phase!="battle": return {}
 for enemy in g.state.enemies:
  if enemy.get("mech_extra",false): return enemy
 return {}

static func consume_extra(g, enemy: Dictionary) -> void:
 enemy.mech_extra=false
 g._emit("event","「再加一件」消耗，本批额外尝试施加1件同规格拘束具。")

static func issue(g, enemy: Dictionary, round_number: int) -> String:
 var move=enemy.intent.get("kind","")
 if not handles(enemy):
  return "该敌人没有机甲专属记录。" if (enemy.has("mech_armor") and enemy.type not in [g.TapeMass.TYPE,g.DroneOperator.TYPE,g.DroneOperator.DRONE]) or enemy.has("mech_restraint_value") or enemy.has("mech_extra") or move in Actions else ""
 if not g.Snapshot.fields(enemy,"mech_armor:n") or enemy.mech_armor<0.0 or enemy.mech_armor>MINI_ARMOR:
  return "机甲的生命或护甲记录有误。"
 if enemy.type==MINI:
  if enemy.has("mech_extra") or not g.Snapshot.fields(enemy,"mech_restraint_value:i") or enemy.mech_restraint_value<START_VALUE or enemy.mech_restraint_value>START_VALUE+maxi(0,round_number-1): return "微型机甲的强化记录有误。"
  if not enemy.intent.is_empty() and move not in MiniActions: return "微型机甲的行动预告有误。"
  if move=="mech_fit" and enemy.mech_armor<=0.0: return "微型机甲破甲后的预告有误。"
 else:
  if enemy.has("mech_restraint_value") or not g.Snapshot.fields(enemy,"mech_extra:b"): return "辅助机甲的负面效果记录有误。"
  if not enemy.intent.is_empty() and move not in SupportCycle+["bind_apply","capture"]: return "辅助机甲的行动预告有误。"
 return ""
