extends RefCounted

const TYPE="succubus_detective"
const PACK="detective_pack"
const CUFF="detective_cuff"
const RESTRAIN="detective_restrain"
const TIGHTEN="detective_tighten"
const STATUS="detective_provoke"
const HOGTIE="zip_hogtie"
const Actions=[PACK,CUFF,RESTRAIN,TIGHTEN]
const Cuffs={"handcuffs":"wrist","ankle_cuffs":"ankle"}
const HAND_LOCK="捕缚锁住了这张手牌。"

static func move_kind(enemy: Dictionary) -> String:
 if enemy.stage==1: return "bind_apply"
 match (enemy.stage-2)%3:
  0: return CUFF if enemy.detective_cuffs.is_empty() else PACK
  1: return RESTRAIN
  _: return TIGHTEN

static func plan(s: Dictionary, enemy: Dictionary) -> Dictionary:
 var move=move_kind(enemy)
 if s.guard_bind.get("progress",0)>=100: move="capture"
 var text=""
 match move:
  "capture": text="执行收押"
  "bind_apply": text="逮捕 · 捕缚40，戴上手铐与脚铐"
  PACK: text="打包～ · 施加%d件扎带" % (2+s.security)
  CUFF: text="铐紧 · 戴上手铐与脚铐，每件捕缚＋10"
  RESTRAIN: text="反抗禁止 · %d件玩具、口球，捕缚＋20" % (1+s.security)
  TIGHTEN: text="禁止反抗！ · 全身收紧，混入%d张挑弄" % (1+s.security)
 return {"kind":move,"text":text,"delayed":false}

static func ordinary(g, templates: Array, count: int, score: int) -> Dictionary:
 var spec=g.EnemyPlans.application(templates,1,1,count,false,score)
 spec.allow_links=false
 spec.replace=true
 return spec

static func toy_spec(g, count: int, score: int) -> Dictionary:
 var spec=g.EnemyPlans.special_application(g,{"type":TYPE})
 spec.count=count
 spec.profiles=g.RestraintValue.profiles(score)
 spec.replace=true
 return spec

static func fit_cuffs(g, enemy: Dictionary, opening: bool) -> void:
 for template in Cuffs:
  var spec=ordinary(g,[template],1,g.Equipment.SHACKLE_RESTRAINT_VALUE)
  g._enemy_operation(enemy,spec,opening)

static func advance_capture(g, enemy: Dictionary, amount: float) -> void:
 if g.CaptureBind.has_bind(g,TYPE): g.CaptureBind.gain_bind(g,amount,enemy.name)
 else: g.CaptureBind.apply_bind(g,enemy,amount)

static func execute(g, enemy: Dictionary, move: String) -> void:
 var n=1+g.state.security
 var score=maxi(2,n)
 match move:
  CUFF: fit_cuffs(g,enemy,false)
  PACK: g._enemy_operation(enemy,ordinary(g,["cable_tie"],n+1,score))
  RESTRAIN:
   advance_capture(g,enemy,20)
   g._enemy_operation(enemy,toy_spec(g,n,score))
   g._enemy_operation(enemy,ordinary(g,["mouth_band"],1,score))
   if g.worn_hogtie().is_empty() and g.occupied("wrist") and g.occupied("ankle"):
    var bands=g.RestraintValue.profiles(score)
    var profile=bands[g._random_index("enemy",bands.size())]
    g._enemy_operation(enemy,{"kind":"install","template":HOGTIE,"slot":"wrist","point":"","grade":profile.grade,"tier":profile.tier,"variant":0,"locked":false,"source":enemy.id,"delayed":false,"text":"施加驷马缚扎带"})
  TIGHTEN:
   for item in g.action_targets():
    if item.durability<=0 or g.equipment_tier(item)>=3 or g.Equipment.is_shackle(item) or g.Equipment.lock_only(item) or g.cursed_eyes(item) or g.cursed_plate(item) or g.SpecialEquipment.is_reinforcement(item): continue
    g._reinforce_equipment(item)
   for i in n: g._gain_temporary_card(STATUS,true)
   g._emit("event","全身拘束具收紧一档，%d张「挑弄」混入抽牌堆。" % n)

# Remember physical cuffs even if the shared capture bar is broken by a card.
static func fitted_cuff(g, item: Dictionary) -> bool:
 if not Cuffs.has(item.template): return false
 var enemy=g._enemy(item.get("source",""))
 if enemy.is_empty() or enemy.type!=TYPE or enemy.gone: return false
 var slot=Cuffs[item.template]
 if enemy.detective_cuffs.get(slot,"")==item.id: return true
 enemy.detective_cuffs[slot]=item.id
 if not g._capture_onset_equipment: advance_capture(g,enemy,10)
 return true

static func removed_cuff(g, id: String, released: bool) -> void:
 for enemy in g.state.enemies:
  if enemy.type!=TYPE or enemy.gone: continue
  var slot=enemy.detective_cuffs.find_key(id)
  if slot==null: continue
  enemy.detective_cuffs.erase(slot)
  if released and g.CaptureBind.has_bind(g,TYPE): g.CaptureBind.damage_bind(g,20,enemy.name)
  g.CaptureBind.observe(g)
  return

static func chained(g, uid: String) -> bool:
 if uid=="" or not g.CaptureBind.has_bind(g,TYPE) or g.state.hand.is_empty(): return false
 var cuffs=g._enemy(g.state.guard_bind.sources[TYPE].enemy).detective_cuffs
 return (cuffs.has("wrist") and g.state.hand.front().uid==uid) or (cuffs.has("ankle") and g.state.hand.back().uid==uid)

static func provoke(g) -> void:
 g.Pressure.gain(g,10.0,"挑弄")
 g._apply_traction(0,false,0.0)
 g._emit("event","挑弄触发一次牵扯。",{"provoke_traction":true})

static func issue(g, s: Dictionary, enemy: Dictionary) -> String:
 var move=enemy.intent.get("kind","")
 if enemy.type!=TYPE: return "侦探行动来源有误。" if enemy.has("detective_cuffs") or move in Actions else ""
 if enemy.stage<1 or not enemy.get("detective_cuffs") is Dictionary: return "侦探状态有误。"
 if enemy.detective_cuffs.size()>2: return "侦探镣铐记录有误。"
 if s.phase=="battle" and not enemy.gone:
  var expected_cuffs={}
  for item in s.equipment:
   if item is Dictionary and item.get("source","")==enemy.id and Cuffs.has(item.get("template","")):
    expected_cuffs[Cuffs[item.template]]=item.id
  if enemy.detective_cuffs!=expected_cuffs: return "侦探镣铐来源有误。"
 if s.phase=="battle" and not enemy.intent.is_empty():
  var expected=plan(s,enemy)
  if move!=expected.kind or enemy.intent.get("text","")!=expected.text: return "侦探行动顺序有误。"
 return ""
