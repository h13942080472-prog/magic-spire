extends RefCounted

# Encounter-local summon and hit reaction; installation and damage stay on Game's
# existing transaction paths. The prepared payload is equipment, not a second actor inventory.
static func owned(g, master: Dictionary) -> Dictionary:
 for enemy in g.state.enemies:
  if not enemy.gone and enemy.get("puppet_owner","")==master.id: return enemy
 return {}

static func plan(e: Dictionary) -> Dictionary:
 var kind="puppet_awaken" if e.stage==1 else ["puppet_composite","puppet_special","puppet_mend"][(e.stage-2)%3]
 return {"kind":kind,"text":{"puppet_awaken":"引敌缚咒","puppet_mend":"缝补玩偶","puppet_composite":"复合装束","puppet_special":"暗藏机关"}[kind],"delayed":false}

static func summon(g, master: Dictionary) -> void:
 if not owned(g,master).is_empty(): return
 var doll=g._append_enemies([{"type":"puppet","grade":2}])[0]
 doll.puppet_security_bonus=g.Prison.health_bonus(g,g.state)
 doll.puppet_owner=master.id;doll.puppet_awakened=false;doll.puppet_prepared={};doll.puppet_mends=0
 doll.puppet_capacity_lost=0
 doll.puppet_stock=capacity(g,doll)
 doll.acted_round=g.state.round;doll.intent=g._plan(doll)
 g._emit("event",master.name+"带着一个%s点生命的玩偶登场。" % g.number(doll.hp),{"summoned":{"enemy":doll.id,"owner":master.id}})

static func execute(g, master: Dictionary, intent: Dictionary) -> void:
 var doll=owned(g,master)
 if doll.is_empty():
  g._emit("event",master.name+"的玩偶已经离场，这次动作落空。")
  return
 match intent.kind:
  "puppet_awaken":
   doll.puppet_awakened=true
   g._emit("event",master.name+"赋予玩偶「引敌缚咒」。",{"puppet_awakened":doll.id})
  "puppet_mend":
   var previous=doll.max_hp
   # Old saves may have reached zero; mending still adds one to today's floor.
   var spec=g.Enemies.TYPES[doll.type]
   doll.puppet_capacity_lost=mini(doll.get("puppet_capacity_lost",0),spec.reaction_capacity+spec.capacity_per_mend*doll.puppet_mends-g.Enemies.PUPPET_MIN_CAPACITY)
   doll.puppet_mends+=1;doll.max_hp+=g.Enemies.TYPES[doll.type].health_per_mend;doll.hp=doll.max_hp
   doll.puppet_stock=capacity(g,doll)
   g._emit("event",master.name+"缝补玩偶，生命上限%s→%s，并恢复至满血；普通反击容量上限增至%d，补充至满。" % [g.number(previous),g.number(doll.max_hp),doll.puppet_stock],{"puppet_mend":{"enemy":doll.id,"before":previous,"maximum":doll.max_hp,"stock":doll.puppet_stock}})
  "puppet_special","puppet_composite":
   var special=intent.kind=="puppet_special"
   var selected
   if special:
    var probe={"pool":"special","templates":g.Enemies.TYPES[master.type].special_pool,"grade":2,"tier":3,"count":1,"replace":true}
    var concrete=g.Application.choose(g,probe,master.id,"enemy")
    if concrete.is_empty():
     g._emit("event",master.name+"没有找到还能佩戴的额外装束，这次准备落空。")
     return
    selected=concrete.type
   else:
    var choices=g.EquipmentOffers.assembly_specs().filter(func(row):return g.Composites.spec(row.family,row.variant,row.straps).minimum<=2)
    selected=choices[g._random_index("enemy",choices.size())]
   var prepared={"kind":"apply","pool":"special" if special else "composite","templates":[selected],"grade":2,"tier":3 if special else 2,"count":1,"replace":true,"locked":false,"final":false,"delayed":false,"text":"玩偶的额外装束"}
   doll.puppet_prepared[prepared.pool]=prepared
   g._emit("event",master.name+"为玩偶准备了"+prepared_name(g,prepared)+"。",{"puppet_prepared":{"enemy":doll.id,"pool":prepared.pool}})

static func prepared_name(g, prepared: Dictionary) -> String:
 var selected=prepared.templates[0]
 var name=g.SpecialEquipment.TYPES[selected].name if prepared.pool=="special" else g.Composites.spec(selected.family,selected.variant,selected.straps).name
 return "中级%d档%s" % [prepared.tier,name]

static func capacity(g, doll: Dictionary) -> int:
 var spec=g.Enemies.TYPES[doll.type]
 return maxi(g.Enemies.PUPPET_MIN_CAPACITY,spec.reaction_capacity+spec.capacity_per_mend*doll.puppet_mends-doll.get("puppet_capacity_lost",0))

static func barrier_trigger(g, master: Dictionary, damage_group: Dictionary) -> void:
 if damage_group.has(master.id): return
 damage_group[master.id]=true
 var doll=owned(g,master)
 if doll.is_empty(): return
 var before=capacity(g,doll)
 if before<=g.Enemies.PUPPET_MIN_CAPACITY: return
 doll.puppet_capacity_lost=int(doll.get("puppet_capacity_lost",0))+1
 var maximum=capacity(g,doll)
 doll.puppet_stock=mini(doll.puppet_stock,maximum)
 g._emit("event",master.name+"的护身屏障触发，玩偶普通反击容量上限%s→%s。" % [before,maximum],{"puppet_capacity":{"enemy":doll.id,"owner":master.id,"before":before,"maximum":maximum,"remaining":doll.puppet_stock}})

static func ordinary(g) -> Dictionary:
 var request=g.EnemyPlans.application(g.Enemies.TYPES.puppet.install_pool,1,2,1,false,3)
 request.replace=true;request.shoulders=true
 return request

static func taunt_reason(g, target: Dictionary, all_targets: bool) -> String:
 if all_targets or target.get("puppet_awakened",false): return ""
 for doll in g.state.enemies:
  if not doll.gone and doll.get("puppet_awakened",false): return "玩偶正在嘲讽，单体攻击必须选择玩偶。"
 return ""

static func damage(g, doll: Dictionary, dealt: float, damage_type: String, label: String, details: Dictionary, damage_group: Dictionary) -> bool:
 if not doll.has("puppet_owner"): return false
 var master=g._enemy(doll.puppet_owner)
 if master.is_empty() or master.gone: return false
 if dealt<=0: return true
 var absorbed=minf(dealt,maxf(0,doll.hp-1))
 var transfer=dealt-absorbed
 doll.hp-=absorbed
 var record={"damage":dealt,"damage_type":damage_type,"enemy":doll.id,"puppet_damage":{"absorbed":absorbed,"transferred":transfer,"owner":master.id}}
 record.merge(details)
 g._emit("mechanical","%s命中%s，承受%s伤害，剩余%s；%s点溢出伤害转给%s。" % [label,doll.name,g.number(dealt),g.number(doll.hp),g.number(transfer),master.name],record)
 if doll.puppet_awakened and doll.puppet_stock>0:
  doll.puppet_stock-=1
  g._enemy_operation(doll,ordinary(g))
  g._emit("event","玩偶发动普通反击，剩余%d/%d次。" % [doll.puppet_stock,capacity(g,doll)],{"puppet_stock":{"enemy":doll.id,"remaining":doll.puppet_stock,"maximum":capacity(g,doll)}})
 if details.get("attack",false):
  var prepared=doll.puppet_prepared.values().duplicate(true)
  doll.puppet_prepared.clear()
  for request in prepared:
   g._emit("event","玩偶的"+prepared_name(g,request)+"被触发。")
   g._enemy_operation(doll,request)
 # The transferred amount has already been calculated: no second damage multiplier.
 if transfer>0: g._damage_enemy(master,transfer,"fixed","玩偶转移",{"puppet_transfer":doll.id},damage_group)
 return true

static func dismiss(g, master: Dictionary) -> void:
 for doll in g.state.enemies:
  if doll.gone or doll.get("puppet_owner","")!=master.id: continue
  doll.gone=true;doll.hp=0;doll.intent={};doll.puppet_awakened=false;doll.puppet_prepared.clear()
  g._emit("event",master.name+"倒下，失去操纵的玩偶也随之散落。",{"puppet_dismissed":doll.id})

static func description(g, doll: Dictionary) -> String:
 var text="生命最低为1，溢出伤害转给玩偶师，再受其护身屏障限制。"
 if doll.get("puppet_awakened",false): text+="单体攻击必须选择玩偶；每次受到正数伤害消耗1次普通反击，尝试施加一件初级2档拘束具，多段逐段触发。"
 text+="普通反击剩余%d/%d次，用尽后停止；发动即扣次数。每次缝补容量上限增加%d并补满；额外装束单独计次。" % [doll.puppet_stock,capacity(g,doll),g.Enemies.TYPES[doll.type].capacity_per_mend]
 for prepared in doll.get("puppet_prepared",{}).values(): text+="下一次攻击额外施加"+prepared_name(g,prepared)+"。"
 return text

static func validate(g, enemies: Array, health_scale: float=1.0) -> String:
 var owners=[]
 for doll in enemies:
  if g.Enemies.TYPES[doll.type].has("damage_cap"):
   if not g.Snapshot.fields(doll,"barrier_damage:n") or doll.barrier_damage<0 or doll.barrier_damage>g.Enemies.barrier_limit(doll,health_scale): return "护身屏障的本回合伤害记录有误。"
  var is_doll=g.Enemies.TYPES[doll.type].behavior=="puppet"
  if not is_doll:
   for key in ["puppet_owner","puppet_awakened","puppet_prepared","puppet_mends","puppet_stock","puppet_capacity_lost"]:
    if doll.has(key): return "该敌人的玩偶记录应为空。"
   continue
  if not g.Snapshot.fields(doll,"puppet_owner:s puppet_awakened:b puppet_prepared:d puppet_mends:i puppet_stock:i"): return "玩偶记录缺损。"
  var masters=enemies.filter(func(e):return e.id==doll.puppet_owner and g.Enemies.TYPES[e.type].behavior=="puppeteer")
  if masters.size()!=1 or doll.puppet_owner in owners: return "玩偶的操纵者或召唤数量有误。"
  owners.append(doll.puppet_owner)
  var bonus=doll.get("puppet_security_bonus",0.0)
  if not (bonus is float or bonus is int) or not is_finite(float(bonus)) or bonus<0 or bonus>120: return "玩偶的安全等级生命加成有误。"
  var spec=g.Enemies.TYPES[doll.type]
  var capacity_lost=doll.get("puppet_capacity_lost",0)
  if not capacity_lost is int or capacity_lost<0 or capacity_lost>spec.reaction_capacity+spec.capacity_per_mend*doll.puppet_mends: return "玩偶的普通反击容量扣减记录有误。"
  if doll.puppet_mends<0 or doll.max_hp!=spec.hp*health_scale+bonus+spec.health_per_mend*doll.puppet_mends: return "玩偶的缝补生命上限有误。"
  if doll.puppet_stock<0 or doll.puppet_stock>capacity(g,doll): return "玩偶的普通反击余量有误。"
  if not doll.gone and (masters[0].gone or doll.hp<1): return "玩偶的保护或操纵者状态有误。"
  if doll.gone and (doll.puppet_awakened or not doll.puppet_prepared.is_empty()): return "离场玩偶的生效装束需要清空。"
  for pool in doll.puppet_prepared:
   var p=doll.puppet_prepared[pool]
   if pool not in ["special","composite"] or not g.Snapshot.intent(p,g) or p.kind!="apply" or p.pool!=pool or p.grade!=2 or p.tier!=(3 if pool=="special" else 2) or p.count!=1 or not p.get("replace",false) or p.templates.size()!=1: return "玩偶准备的装备规格有误。"
   if pool=="special" and p.templates[0] not in g.Enemies.TYPES[masters[0].type].special_pool: return "玩偶准备的特殊装备需要来自中级池。"
   if pool=="composite" and (not p.templates[0] is Dictionary or p.templates[0] not in g.EquipmentOffers.assembly_specs()): return "玩偶准备的复合装备缺失。"
 return ""
