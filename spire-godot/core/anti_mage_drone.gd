extends RefCounted

const TYPE="anti_mage_drone"
const FIT="drone_fit"
const WEAKEN="drone_weaken"
const Actions=[FIT,WEAKEN]

static func count(g, enemy: Dictionary) -> int:
 return 1+int(g.state.combat.get("mana_listeners",{}).get(enemy.id,0)/2)

static func description(move: String, amount: int) -> String:
 return "皮带连射 · 施加%d件紧度2的皮革拘束具" % amount if move==FIT else "无力化 · 2层虚弱，随机收紧并上锁%d件" % amount

static func plan(g, enemy: Dictionary) -> Dictionary:
 if g.CaptureBind.capture_ready(g.state): return {"kind":"capture","text":"执行收押","delayed":false}
 if enemy.stage==1: return {"kind":"bind_apply","text":"封口捕缚 · 强制替换口球，开启魔力监听","delayed":false}
 var move=FIT if enemy.stage%2==0 else WEAKEN
 return {"kind":move,"text":description(move,count(g,enemy)),"delayed":false}

static func ordinary(g, amount: int, reaction: bool=false) -> Dictionary:
 var spec=g.EnemyPlans.application(g.Enemies.TYPES[TYPE].install_pool,2,2,amount,false,4 if reaction else 0)
 spec.allow_links=false
 return spec

static func opening(g, enemy: Dictionary) -> void:
 var capture=g.state.guard_bind.sources[TYPE]
 capture.spells=0
 capture.fitted={}
 var result=g.Application.Replacement.force_mouth_gag(g,enemy.id)
 if result.ok: g._emit("event",enemy.name+"将中级假阳具口球扣紧并上锁。",{"equipment":result.installed[0].id})
 if not g.state.combat.has("mana_listeners"): g.state.combat.mana_listeners={}
 g.state.combat.mana_listeners[enemy.id]=0

static func mana_changed(g) -> void:
 if g.state.phase!="battle": return
 var listeners=g.state.combat.get("mana_listeners",{})
 for id in listeners: listeners[id]+=1

static func consume(g, enemy: Dictionary) -> int:
 var amount=count(g,enemy)
 var listeners=g.state.combat.get("mana_listeners",{})
 if listeners.has(enemy.id): listeners[enemy.id]%=2
 return amount

static func execute(g, enemy: Dictionary, move: String) -> void:
 var amount=consume(g,enemy)
 if move==FIT:
  g._enemy_operation(enemy,ordinary(g,amount))
  return
 g.Cards.add_weakness(g,enemy.name)
 var choices=g.EnemyPlans.targets(g,enemy,"tighten").filter(func(item):return g.Equipment.allows(item,"lock") and (g.equipment_tier(item)<3 or not item.locked))
 for i in mini(amount,choices.size()):
  var target=choices.pop_at(g._random_index("enemy",choices.size()))
  g._enemy_operation(enemy,{"kind":"tighten","target":target.id,"delayed":false,"text":"收紧拘束具"})
  if not target.locked: g._enemy_operation(enemy,{"kind":"lock","target":target.id,"delayed":false,"text":"上锁"})

static func magic_played(g) -> void:
 if not g.CaptureBind.has_bind(g,TYPE): return
 var source=g.state.guard_bind.sources[TYPE]
 source.spells=1-int(source.spells)
 g.CaptureBind.gain_bind(g,2.0,"魔法牌")
 if source.spells==0:
  var enemy=g._enemy(source.enemy)
  g._enemy_operation(enemy,ordinary(g,consume(g,enemy),true))
