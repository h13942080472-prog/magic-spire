extends RefCounted

const TYPE="mana_smuggler"
const ENCOUNTER="mana_smuggler_pair"
const TAKE=10.0
const Actions={
 "smuggler_steal":"顺手摸瓶 · 偷取最多10点魔瓶魔力并施加拘束",
 "smuggler_prepare":"找好退路",
 "smuggler_leave":"带货溜走",
}

static func initialize(e: Dictionary, limit: int) -> void:
 e.theft_limit=limit
 e.stolen_mana=0.0

static func active(e: Dictionary) -> bool:
 return not e.gone and e.type==TYPE

static func plan(g, e: Dictionary) -> Dictionary:
 var move="smuggler_steal"
 if e.stage==e.theft_limit+1: move="smuggler_prepare"
 elif e.stage>e.theft_limit+1: move="smuggler_leave"
 var text=Actions[move]
 if move=="smuggler_leave": text="带货溜走 · 将带走%s魔力" % g.number(e.stolen_mana)
 return {"kind":move,"text":text,"delayed":false}

static func restraints(g, count: int) -> Dictionary:
 var spec=g.EnemyPlans.application(g.Enemies.TYPES[TYPE].install_pool,1,3,count,false,4)
 spec.allow_links=false
 spec.replace=true
 spec.tighten_missing=true
 return spec

static func execute(g, e: Dictionary, move: String) -> void:
 match move:
  "smuggler_steal":
   var stolen=-g.ManaFlask.change(g,-TAKE)
   e.stolen_mana+=stolen
   if stolen>0.0:
    g._emit("event","%s从魔瓶偷走了%s魔力。" % [e.name,g.number(stolen)],{"flask_theft":{"enemy":e.id,"amount":stolen,"carried":e.stolen_mana}})
   else: g._emit("event","%s摸了个空，转而多施加一件拘束具。" % e.name)
   g._enemy_operation(e,restraints(g,1 if stolen>0.0 else 2))
  "smuggler_prepare": g._enemy_preparation(e,"找好退路，下一次行动将带走携带的魔力。")
  "smuggler_leave": g._depart_enemy(e)

static func recover(g, e: Dictionary) -> void:
 var amount=e.stolen_mana
 e.stolen_mana=0.0
 if amount<=0.0: return
 g.ManaFlask.change(g,amount)
 g._emit("event","从%s身上追回%s魔力，已归还魔瓶。" % [e.name,g.number(amount)],{"flask_recovery":{"enemy":e.id,"amount":amount}})

static func depart(g, e: Dictionary) -> void:
 g._emit("event","%s带着%s魔力离场。" % [e.name,g.number(e.stolen_mana)],{"flask_escape":{"enemy":e.id,"amount":e.stolen_mana}})

static func issue(g, e: Dictionary) -> String:
 var move=e.intent.get("kind","")
 if e.type!=TYPE:
  return "该敌人没有魔力走私记录。" if e.has("theft_limit") or e.has("stolen_mana") or Actions.has(move) else ""
 var limits=g.Enemies.ENCOUNTERS[ENCOUNTER].members.map(func(member):return member.thefts)
 if not e.get("theft_limit") is int or e.theft_limit not in limits or e.stage<1 or e.stage>e.theft_limit+(3 if e.gone else 2):
  return "魔力走私者出场或行动记录有误。"
 if not g.Snapshot.fields(e,"stolen_mana:n") or e.stolen_mana<0.0 or e.stolen_mana>TAKE*mini(e.stage-1,e.theft_limit) or (e.defeated and e.stolen_mana!=0.0):
  return "走私者携带的魔力记录有误。"
 if e.intent.is_empty(): return ""
 if move=="capture" and e.intent.size()==3: return ""
 var expected=plan(g,e)
 expected.delayed=e.intent.get("delayed",false)
 return "" if e.intent==expected else "魔力走私者预告有误。"
