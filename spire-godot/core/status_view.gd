extends RefCounted

# Read-only catalogue of current effects, not a second rule/trigger system.
const B=preload("res://data/balance.gd")

static func entry(out: Array, id: String, category: String, name: String, value: String, detail: String, source: String, duration: String, tone: String="neutral") -> void:
 out.append({"id":id,"category":category,"name":name,"value":value,"detail":detail,"source":source,"duration":duration,"tone":tone,"icon":"info","badge":"","owner":"hero","active":false})

static func mark(out: Array, icon: String, badge: String="", active: bool=true, owner: String="hero") -> void:
 out.back().merge({"icon":icon,"badge":badge,"active":active,"owner":owner},true)
 if owner!="hero": out.back().category="enemy"

# Fixed cutters have no direct-use display point; their formal card bonus identifies them.
static func append_usable_items(out: Array, items: Array, facts: Array) -> void:
 var usable={}
 for action in facts:
  if not action.valid: continue
  var payload=action.payload
  var bonus=payload.get("tool_bonus",{})
  if not bonus.is_empty(): usable[bonus.item]=true
 for item in items:
  if not item.installed or item.uses<=0 or not usable.has(item.id): continue
  var detail=item.passive_text
  if item.contact_text!="": detail+="\n"+item.contact_text
  entry(out,"usable_item_"+item.id,"environment",item.name,"剩余%d次" % item.uses,detail,item.mount,"随使用次数和可用条件变化更新","good")
  mark(out,"item",str(item.uses))
  out.back().item_id=item.id
  out.back().item_type=item.type

static func power_art(g, id: String) -> Dictionary:
 if g.Cards.Rules.BUFFS[id].has("hannya_level"): return {"card_type":"hannya_%d" % g.Cards.Rules.BUFFS[id].hannya_level,"face":"free"}
 for type in g.Cards.Rules.SPECS:
  for effect in g.Cards.Rules.SPECS[type].get("free_effects",[]):
   if effect.get("buff","")==id: return {"card_type":type,"face":"free"}
  var faces=g.Cards.Rules.SPECS[type].get("self_faces",{})
  for face in faces:
   if faces[face].get("buff","")==id: return {"card_type":type,"face":face}
 return {}

static func sources(g, slots: Array, side: String="", joint_only: bool=false) -> String:
 var names: Array=[]
 for slot in slots:
  for e in g.equipment_at(slot):
   if joint_only and e.get("side","")!="" and slot not in ["palm","fingers"]: continue
   if side!="" and e.get("side","") not in ["",side]: continue
   var name=g._equipment_name(e)
   if name not in names: names.append(name)
 return "、".join(names) if not names.is_empty() else "当前身体状态"

static func build(g, special_regions: Array, pressure: Dictionary) -> Array:
 var out: Array=[]
 var s=g.state
 var toe=g.RelicEffects.toe_traction(g)
 if toe.base>0:
  var details: Array[String]=[]
  for source in toe.sources: details.append("%s：%s、紧度%d档，基础快感＋%s。" % [source.name,g.Equipment.GRADES[source.grade],source.tier,g.number(source.base)])
  entry(out,"secret_weapon_traction","limit","脚趾牵扯","＋%s快感" % g.number(toe.gain),"每次消耗能量时触发一次；额外牵扯也会触发。\n"+"\n".join(details)+"\n脚趾施法成功率×0%；解除脚趾拘束后停止。","秘密武器","脚趾被拘束时","bad")
  mark(out,"foot",g.number(toe.gain))
 if g.Character.active(g):
  for part in g.Character.PARTS:
   var count=s.witch_charges[part]
   var detail="至少4层可使用魔女飞踹：伤害1，打断，消耗全部腿部施法预备。" if part=="legs" else "释放时每层额外触发一次法术效果，消耗该部位全部施法预备；失败保留。"
   detail+="每回合预备次数不限；各部位每回合只能成功释放1次。"
   if g.Character.Expansion.protects_preparation(g): detail+="耐心耐心～生效：施法预备不会减少（主动释放除外），也不抵挡拘束。"
   if part!="mind": detail+="对应部位被施加拘束时可消耗2层抵挡；不足2层不能抵挡。"
   entry(out,"witch_charge_"+part,"benefit",g.Character.NAMES[part]+"施法预备","%d层" % count,detail,"基础动作","本场整备结束或高潮时清空","good")
   mark(out,{"hand":"hand","mouth":"mouth","legs":"foot","mind":"ritual"}[part],str(count))
  if s.witch_focus>0:
   entry(out,"witch_focus","benefit","精神集中","%d层" % s.witch_focus,"下次对敌人造成伤害的魔法每段伤害＋%d，整次施放消耗全部层数；魔力松缚不受加成，也不消耗层数。施法失败或高潮时失去1层。" % s.witch_focus,"卡牌／遗物","使用后清除；跨战斗最多保留%d层" % (2+g.combat_retention_bonus()),"good")
   mark(out,"ritual",str(s.witch_focus))
 for buff in s.body_buffs:
  var spec=g.Tools.TYPES[buff.type]
  var group=g.Equipment.panel_groups().filter(func(p):return p.id==buff.group)[0]
  entry(out,"body_buff_"+buff.type+"_"+buff.group,"benefit",spec.name+" · "+group.name,"滑脱×%d" % spec.amount,g.Consumables.description(g,buff.type),spec.name,"本场战斗或整备结束前","good")
  mark(out,"dexterity")
 for spell in s.spell_base_bonuses:
  var label=g.BasicAttacks.TYPES[spell][0].name
  entry(out,"permanent_spell_"+spell,"benefit",label+"强化","＋%d" % s.spell_base_bonuses[spell],label+"基础伤害永久增加%d点，先加基础再计算伤害倍率。" % s.spell_base_bonuses[spell],"卡牌效果","本局永久","good")
  mark(out,"flame",str(s.spell_base_bonuses[spell]))
 if s.get("weakness_turns",0)>0:
  entry(out,"weakness","limit","无力化","%d个玩家回合" % s.weakness_turns,"肘击、近身短打和踢击禁用；火球、卡牌魔法不受无力化影响，仍需满足各自施法条件。","敌人施加的无力化","本玩家回合结束后解除","bad")
  mark(out,"weakness",str(s.weakness_turns))
 if g.CaptureBind.has_bind(g):
  var bind=g.CaptureBind.view(g)
  entry(out,"guard_bind","limit","捕缚","%s / %s" % [g.number(bind.value),g.number(bind.maximum)],bind.detail,bind.source,"进度归零解除；达到100后下一敌方回合收押","bad")
  mark(out,"bind",g.number(bind.value))
 if s.phase=="battle":
  if g.Prison.reinforcements_active(g):
   var count=s.prison.reinforcements;var limit=1+s.security
   var left=g.Prison.reinforcements_left(g)
   entry(out,"prison_reinforcements","environment","援军","已达上限" if count>=limit else "%d回合后抵达" % left,"每4回合召来1名警卫。已召来%d / %d名；战斗胜利后停止。" % [count,limit],"监狱警卫战","本场战斗结束时消失","bad")
   mark(out,"stock","✓" if count>=limit else str(left),true)
  for enemy in s.enemies:
   var definition=g.Enemies.TYPES[enemy.type]
   if not enemy.gone and (definition.has("defeat_spawns") or definition.has("split_threshold")):
    var detail="被击败时会分裂出其他敌人。" if definition.has("defeat_spawns") else "生命值降至%s%%时会分裂；最后一次全身施加后也会分裂。" % g.number(definition.split_threshold*100)
    entry(out,"split_"+enemy.id,"enemy","分裂 · "+enemy.name,"被击败时" if definition.has("defeat_spawns") else "生命≤%s%%" % g.number(definition.split_threshold*100),detail,enemy.name,"该敌人存活期间")
    mark(out,"split","",true,enemy.id)
   if not enemy.gone and g.Enemies.TYPES[enemy.type].has("carried_composites"):
    var stock=g.Enemies.TYPES[enemy.type].carried_composites
    var names=enemy.carried_indices.map(func(index):return g.Composites.spec(stock[index].family,stock[index].variant,stock[index].straps).name)
    entry(out,"carried_"+enemy.id,"limit","备用装备 · "+enemy.name,"%d件" % names.size(),("、".join(names)+"；均为中级2档。成功佩戴才消耗，无法佩戴时留在盒内。" if not names.is_empty() else "备用装备已用完，原施加步骤改为捕缚＋10。"),enemy.name,"本场战斗内消耗")
    mark(out,"stock",str(names.size()),true,enemy.id)
   if not enemy.gone and g.Enemies.TYPES[enemy.type].get("mechanical",false):
    var multiplier=g.Enemies.damage_multiplier(g,enemy.type,"physical")
    entry(out,"hard_"+enemy.id,"limit","坚硬 · "+enemy.name,"非魔法减伤%s%%" % g.number((1.0-multiplier)*100),"该机械敌人受到的非魔法伤害×%s；魔法与固定伤害正常。" % g.number(multiplier),enemy.name,"该敌人存活期间","bad")
    mark(out,"shield","",true,enemy.id)
   if not enemy.gone and g.Enemies.TYPES[enemy.type].has("quantity_gain") and enemy.get("application_bonus",0)>0:
    entry(out,"quantity_"+enemy.id,"limit","狂躁 · "+enemy.name,"%d层" % enemy.application_bonus,"每次施加额外增加%d件拘束具，不消耗层数，也不增加加固次数。" % enemy.application_bonus,enemy.name,"来源存活期间","bad")
    mark(out,"charge",str(enemy.application_bonus),true,enemy.id)
   if not enemy.gone and enemy.get("ritual",0)>0:
    entry(out,"ritual_"+enemy.id,"limit","仪式 · "+enemy.name,"%d点 · 数量＋%d" % [enemy.ritual,enemy.application_bonus],"每个自身回合结束时，施加数量加成增加%d件。已有加成不会消耗；施加行动被打断仍会增长。" % enemy.ritual,enemy.name,"该敌人存活期间","bad")
    mark(out,"ritual",str(enemy.ritual),true,enemy.id)
   if not enemy.gone and enemy.get("ready_layers",0)>0:
    entry(out,"ready_"+enemy.id,"limit","准备就绪 · "+enemy.name,"%d层" % enemy.ready_layers,"该敌人每成功施加或替换一件拘束具消耗1层，使该件紧度为3档；无目标、失败或被打断时保留，可继续叠层。",enemy.name,"逐件成功时消耗；来源离场后不再生效","bad")
    mark(out,"ready",str(enemy.ready_layers),true,enemy.id)
   if not enemy.gone and enemy.get("turn_install_layers",0)>0:
    var effect=g.Enemies.TYPES[enemy.type].turn_install_effect
    var timing="结束" if effect.timing=="turn_end" else "开始"
    entry(out,"turn_install_"+enemy.id,"limit",effect.name,"%d层 · 每回合%d件" % [enemy.turn_install_layers,enemy.turn_install_layers],"每个玩家回合%s时，每层新增一件初级2档%s类装备。" % [timing,g.Enemies.TYPES[enemy.type].restraint_name],enemy.name,"来源被击败或分裂后立即停止","bad")
    mark(out,"bind",str(enemy.turn_install_layers))
 for enemy in s.enemies:
  var definition=g.Enemies.TYPES[enemy.type]
  if not enemy.gone and definition.has("damage_cap"):
   var health_scale=g.DemoExit.health_multiplier(s)
   var remaining=g.number(g.Enemies.barrier_remaining(enemy,health_scale))
   entry(out,"damage_barrier_"+enemy.id,"enemy","护身屏障","本回合还能受到%s点伤害" % remaining,"每回合受到的最终伤害合计最多%s点，多次攻击、多段及玩偶转移伤害共用额度；下一回合恢复。" % g.number(g.Enemies.barrier_limit(enemy,health_scale))+"\n"+g.Enemies.BARRIER_CAPACITY_DESCRIPTION,enemy.name,"战斗期间持续生效","bad")
   mark(out,"shield",remaining,true,enemy.id)
  if not enemy.gone and enemy.has("puppet_owner"):
   entry(out,"puppet_"+enemy.id,"limit","引敌缚咒" if enemy.puppet_awakened else "牵线保护","%s/%s生命" % [g.number(enemy.hp),g.number(enemy.max_hp)],g.Puppets.description(g,enemy),g._enemy(enemy.puppet_owner).name,"玩偶师被击败后，玩偶与这些效果一同消失","bad")
   mark(out,"puppet","",true,enemy.id)
   entry(out,"puppet_stock_"+enemy.id,"enemy","普通反击容量","%d/%d" % [enemy.puppet_stock,g.Puppets.capacity(g,enemy)],"每次普通反击消耗1次，用尽后停止；缝补时上限＋%d并补满。复合装束和暗藏机关不消耗此容量。" % definition.capacity_per_mend,enemy.name,"缝补时补充","bad")
   mark(out,"stock",str(enemy.puppet_stock),true,enemy.id)
 for region in ["arms","legs"]:
  var level=g.level(region)
  var arms=region=="arms"
  var detail="肘击与近身短打伤害×%s（含力量和蓄力）；三级起无法使用这两种攻击。" % g.number(B.BODY_DAMAGE[level]) if arms else "腿部体术伤害×%s（含力量和蓄力）。站着踢要求0级；坐着踢4级起不可用。并腿踢击沿用此伤害倍率。姿态费用与移动速度随腿部限制变化。" % g.number(B.BODY_DAMAGE[level])
  if arms and g.Cards.attack_ignores_restraints(g,"strike"): detail+="魔术手生效期间，手部体术暂时忽略这些拘束限制与减益。"
  if arms: detail+="切换姿态"+("减少1能量，最低0。" if level<=1 else "不获得双臂灵活的能量减免。")
  entry(out,region,"body","上身束缚等级" if arms else "腿部束缚等级","%d / 4级" % level,detail,sources(g,B.ARM_SLOTS if arms else B.LEG_SLOTS,"",true),"随真实拘束部位变化", "bad" if level>0 else "neutral")
  mark(out,region,str(level),level>0)
 for side in ["left","right"]:
  var fingers=g.hand_blocked("fingers",side)
  var palm=g.hand_blocked("palm",side)
  var name=("左" if side=="left" else "右")+"手"
  entry(out,"hand_"+side,"body",name,"手指受限" if fingers else ("手掌受限" if palm else "自由"),"手掌：%s；手指：%s。手势和握持按具体动作条件检查。" % ["受限" if palm else "自由","受限" if fingers else "自由"],sources(g,["palm","fingers"],side),"随该侧手部装备变化","bad" if fingers or palm else "neutral")
  mark(out,"hand","左" if side=="left" else "右",fingers or palm)
 entry(out,"hand_assist","body","手部辅助",g.HandAssist.summary(g),g.HandAssist.description(g),"当前手指、手掌、手腕与触及范围","每次挣扎／滑脱按实际目标重新检查")
 mark(out,"hand","",false)
 var toes=g.occupied("toes")
 entry(out,"toes","body","脚趾","受限" if toes else "自由","不能用脚趾安装工具。" if toes else "满足脚趾操作条件；工具安装还需检查腿部等级、姿态与墙面。",sources(g,["toes"]),"随脚趾装备变化","bad" if toes else "neutral")
 mark(out,"foot","",toes)
 var blind=not g.can_observe_intents()
 entry(out,"vision","body","视觉","受阻" if blind else "清晰","无法观察敌人意图；解除最后一件眼部装备后立即恢复。" if blind else "可以观察敌人当前公开意图。",sources(g,["eyes"]),"随眼部装备变化","bad" if blind else "neutral")
 mark(out,"eye","",blind)
 var mouth=g.occupied("mouth")
 var casting=g.cast_view()
 entry(out,"speech","body","口部与咏唱","受限" if mouth else "自由",("嘴部施法成功率："+casting.percent+"。\n"+casting.detail),sources(g,["mouth"]),"随口部装备与快感变化","bad" if mouth else "neutral")
 mark(out,"mouth","",mouth)
 var movement=g.movement_profile()
 var order=("玩家先手" if s.order=="first" else "玩家后手") if s.phase=="battle" else "当前非战斗"
 entry(out,"posture","body","姿态与行动",B.POSE_NAMES[s.posture]+" · "+movement.mode,"相邻房间移动需要%d回合；途中不抽牌、不补能。\n%s；回合中换姿不改变本回合的先后手。" % [movement.turns,order],"当前姿态与腿部活动能力","随姿态和腿部状态变化")
 mark(out,"movement","",false)
 var upper=1 if g.level("arms")>=3 or g.occupied("fingers") else 0
 var lower=1 if g.level("legs")>=3 else 0
 var extra=int(g.relic_value("capacity"))
 entry(out,"capacity","body","随身容量","%d / %d格" % [g.carried_items(),g.item_capacity()],"基础3格＋遗物%d－上肢%d－下肢%d；双手手指同时受限与上肢扣减不叠加。" % [extra,upper,lower],"身体限制与随身遗物","超出容量时使用或放下多余道具","bad" if g.carried_items()>g.item_capacity() else "neutral")
 for attribute in ["strength","dexterity"]:
  var name="力量" if attribute=="strength" else "灵巧"
  var value=g.RelicEffects.attribute(g,attribute)
  var modifier=g.Cards.hand_modifier(g,attribute)
  var power_modifier=g.Cards.power_attribute_modifier(g,attribute)
  var detail="在倍率计算前增加%s基础值。" % ("挣扎及全部体术每段伤害" if attribute=="strength" else "主动与被动滑脱")
  detail+="\n人物%s · 遗物%s · 手牌%s · 能力%s。" % [g.number(s[attribute]),g.number(g.relic_value(attribute)),g.number(modifier),g.number(power_modifier)]
  if attribute=="strength" and s.turn_strength>0: detail+="\n临时力量＋%d，本回合结束清除。" % s.turn_strength
  if modifier!=0: detail+="手牌加值不用于移动被动滑脱；离开手牌立即失效。"
  if power_modifier!=0: detail+="增益加值按当前卡牌效果计算；般若汤持续至本场整备结束。"
  entry(out,attribute,"benefit",name,g.number(value),detail,"人物、遗物、手牌与能力","随人物属性、手牌与当前装备变化","bad" if modifier<0 else "good")
  mark(out,attribute,g.number(value),value!=0 or modifier!=0 or power_modifier!=0)
 if g.state.sure_cast: entry(out,"sure_cast","benefit","定咒","1次","下一次合法施法成功率100%，费用照常。","定咒卷轴","下次施法或本场整备结束","good")
 if g.state.sure_cast: mark(out,"sure_cast","1")
 for id in g.Cards.active_buffs(g,true):
  var buff=g.Cards.Rules.BUFFS[id]
  if buff.get("hidden",false): continue
  var stacks=g.Cards.buff_stacks(g,id)
  var detail=buff.detail+("\n当前共%d重效果，各自按原触发条件生效。" % stacks if stacks>1 else "")
  if buff.get("restraint_draw",{}).has("energy"): detail=buff.detail+"\n当前%s。" % g.Cards.progress_text(g,id)
  if buff.has("hannya_level"): detail=g.Cards.Hannya.status_detail(g)
  entry(out,"power_"+id,"benefit",buff.name,g.Cards.progress_text(g,id),detail,"卡牌增益","触发或本场整备结束" if buff.has("replay") else ("本场整备结束" if buff.duration=="battle" else ("本回合结束" if buff.duration=="turn" else "下一次对应攻击成功后")),"good")
  mark(out,"power",str(buff.get("hannya_level",stacks)))
  if buff.has("attack_uses") or buff.get("stack_uses",false): out.back().badge=str(g.state.card_buff_uses.get(id,0))
  if buff.get("restraint_draw",{}).get("next_turn",false): out.back().badge=str(g.Cards.pending_draw(g,id))
  out.back().merge(power_art(g,id))
  if buff.duration=="next_turn_start": out.back().duration=buff.get("duration_text","下回合开始")
  if buff.get("toggleable",false):
   var enabled=id in g.Cards.active_buffs(g)
   out.back().merge({"toggle":true,"emphasized":enabled,"disabled":not enabled,"badge":"开" if enabled else "关"},true)
 if s.temporary_mana>0: entry(out,"temporary_mana","benefit","临时魔力",g.number(s.temporary_mana)+"点","优先抵扣法术和卡牌耗魔，不受魔力上限限制；不能存入魔瓶或用于购物。","预备魔力","可跨回合并延续至整备；整备结束最多保留%s点到下场；入狱清除。" % g.number(g.B.TEMPORARY_MANA_RETENTION+g.combat_retention_bonus()*5),"good")
 if s.temporary_mana>0: mark(out,"mana",g.number(s.temporary_mana))
 if s.charge>0:
  var detail="下一次主动挣扎、滑脱或体术基础伤害＋%s；%s" % [g.number(g.charge_bonus()),"消耗全部%d层，随后恢复普通模式。右键切回普通蓄力。" % s.charge if s.charge_all else "每次触发消耗1层。右键切换为全量蓄力。"]
  var duration="可跨回合并延续至整备；整备结束最多保留%d层到下场；入狱清除。每次高潮后蓄力减半，剩余层数向下取整。" % (g.B.CHARGE_RETENTION+g.combat_retention_bonus())
  entry(out,"charge","benefit","全量蓄力" if s.charge_all else "蓄力","%d层" % s.charge,detail,"卡牌、道具或已触发遗物",duration,"good")
  mark(out,"charge",str(s.charge))
  out.back().merge({"toggle":true,"emphasized":s.charge_all})
 if s.next_energy>0: entry(out,"next_energy","benefit","预备能量","＋%d" % s.next_energy,"下一玩家回合增加能量，届时一次消耗。","深呼吸、卡牌自由效果","保留至下一玩家回合；跨战最多保留%d点；入狱清除" % (g.B.ENERGY_RETENTION+g.combat_retention_bonus()),"good")
 if s.next_energy>0: mark(out,"energy",str(s.next_energy))
 var mark_pressure=g.Cards.hand_modifier(g,"energy_pressure")
 if mark_pressure>0: entry(out,"hand_energy_pressure","pressure","淫纹刺激","每次花费能量＋"+g.number(mark_pressure)+"快感","牵扯：每次花费能量的行动完成后触发一次；一次行动无论花费几点都只触发一次。额外牵扯也会触发。","手牌中的诅咒「淫纹」","离开手牌后立即失效","bad")
 if mark_pressure>0: mark(out,"pressure",g.number(mark_pressure))
 entry(out,"pressure","pressure","快感","%s / %s" % [g.number(pressure.value),g.number(pressure.maximum)],pressure.detail,"身体受到的刺激","快感跨战保留；可通过深呼吸降低","bad" if pressure.stage>=2 else "neutral")
 if s.overloaded: entry(out,"overload","pressure","高潮","本回合%d次" % s.overload_count,"身体暂时失去力气，剩余行动已跳过，只能继续回合。","快感达到100","本玩家回合结束后解除","bad")
 if s.overloaded: mark(out,"weakness",str(s.overload_count))
 if s.overload_energy>0: entry(out,"overload_energy","pressure","高潮后的乏力","－%d能量" % s.overload_energy,"下一玩家回合能量减少；连续高潮会叠加。","高潮","下一玩家回合消耗；整备结束不继承","bad")
 if s.overload_energy>0: mark(out,"energy","−"+str(s.overload_energy))
 if s.slip_ejaculation_turns>0: entry(out,"slip_ejaculation","pressure","滑精","后续%d回合：能量－1、魔力－%s" % [s.slip_ejaculation_turns,g.number(g.B.SLIP_EJACULATION_MANA)],"期间高潮不立即损失魔力；后续%d个玩家回合开始时各损失%s魔力、减少1点能量。" % [s.slip_ejaculation_turns,g.number(g.B.SLIP_EJACULATION_MANA)]+("下一玩家回合固定后手。" if s.slip_ejaculation_force_last else ""),"平板锁与马眼装备共同触发高潮","经过对应玩家回合后解除；重复触发刷新为2回合","bad")
 if s.slip_ejaculation_turns>0: mark(out,"energy","−1")
 var pressure_groups={}
 for source in s.pressure_sources:
  if not g.Pressure.active(g,source): continue
  var key=source.get("definition",source.id)+":"+source.timing
  if not pressure_groups.has(key): pressure_groups[key]=[]
  pressure_groups[key].append(source)
 for key in pressure_groups:
  var group=pressure_groups[key]
  var details=[]
  for source in group: details.append(source.name+"："+g.Pressure.describe(g,source))
  var name=g.Pressure.Data.TYPES.get(group[0].get("definition",""),{}).get("name",group[0].name)
  entry(out,"pressure_"+key,"pressure",name,"%d个来源" % group.size(),"\n".join(details),g.Pressure.TIMINGS[group[0].timing],"各来源分别计时，解除或离开后停止","bad")
  mark(out,"pressure",str(group.size()))
 var wall=g.wall_view()
 if not wall.at_wall: entry(out,"wall","environment","环境",wall.name+(" · "+wall.environment_name if wall.environment_name!="" else ""),wall.detail,"当前房间","随位置和姿态变化更新","good" if g._wall_bonus()>0 else "neutral")
 if wall.at_wall: entry(out,"against_wall","benefit","贴墙",wall.status,wall.detail,wall.source,wall.duration,"good")
 if wall.at_wall: mark(out,"wall")
 if s.phase=="battle":
  if s.heavy_used: entry(out,"heavy_used","limit","近身短打","本回合已使用","本回合不能再次发动近身短打。","已执行的攻击","下个玩家回合恢复","bad")
  var cooldown=g.BasicAttacks.kick_cooldown(g)
  if cooldown>0:
   entry(out,"kick_cooldown","limit","踢击冷却","%d回合后恢复" % cooldown,"坐姿踢击与并腿踢击共用冷却。般若汤强化后的正义飞踢也共用冷却；普通正义飞踢、横扫和站着踢／坐着踢不受影响。","已使用的踢击动作","随战斗回合推进恢复，切换姿势不刷新","bad")
 var retained=[]
 for card in s.hand:
  if B.CARD_TRAITS.get(card.type,{}).get("retain",false): retained.append(B.CARD_NAMES[card.type]+"：自带保留。")
  elif card.retain_until>s.tick: retained.append(B.CARD_NAMES[card.type]+"：至第%d个后续玩家回合结束。" % (card.retain_until-s.tick))
 if not retained.is_empty():
  entry(out,"retained","benefit","保留","%d张" % retained.size(),"回合结束暂不弃置；虚无优先进入消耗区。\n"+"\n".join(retained),"当前手牌","各张牌分别按自己的保留期限结束")
  mark(out,"cards",str(retained.size()))
 if s.pending_retain: entry(out,"retain_pending","benefit","等待选择保留牌","至多%d张" % s.retain_left,"当前需要完成保留选择后再继续其他行动。","已打出的卡牌","完成选择后结束")
 if not s.card_chain.is_empty(): entry(out,"chain","benefit","连续行动","剩余%d段" % s.card_chain.remaining,"继续选择合法目标；费用已支付，不重复扣除。",B.CARD_NAMES[s.card_chain.type],"完成剩余段或失去合法目标后结束")
 if s.evasion>0:
  entry(out,"evasion","benefit","闪避","%d层" % s.evasion,"即将被施加拘束具时，消耗1层抵消1件。","卡牌","本场整备结束时清除","good")
  mark(out,"slip",str(s.evasion))
 var curses=s.deck.filter(func(card):return B.CARD_TRAITS.get(card.type,{}).get("curse",false))
 if not curses.is_empty():
  entry(out,"curse","limit","诅咒牌","%d张" % curses.size(),"混入卡组，占用抽牌机会；能否打出与保留按各自牌面说明。","当前卡组","按各自卡牌规则保留","bad")
 var status_cards=s.deck.filter(func(card):return B.CARD_TRAITS.get(card.type,{}).get("status",false))
 if not status_cards.is_empty():
  entry(out,"status_cards","limit","状态牌","%d张" % status_cards.size(),"混入本场牌堆，占用抽牌机会；效果按各自牌面说明。","本场牌堆","本场整备结束或被收押时消失","bad")
 if pressure.gain_multiplier!=1.0: entry(out,"hand_pleasure","pressure","快感增长倍率","×"+g.number(pressure.gain_multiplier),"手牌与遗物的快感倍率相乘；固定快感仅受遗物倍率影响。","当前手牌与遗物","随手牌与持有遗物变化","bad" if pressure.gain_multiplier>1.0 else "good")
 if pressure.gain_multiplier!=1.0: mark(out,"pressure","×"+g.number(pressure.gain_multiplier))
 if s.phase=="rest": entry(out,"rest","environment","休息房规则","剩余%d回合" % s.rest_left,"禁止卡牌自由效果，不自动回魔；挂钩剩余%d次。" % s.hook_uses,"当前休息房","离开房间后结束")
 if s.phase=="prepare": entry(out,"prepare","environment","战后整备","剩余%d回合" % s.prepare_left,"可以继续挣脱或积攒自由效果。","战斗结束与整备类遗物","整备结束后结束")
 if s.security>0: entry(out,"security","environment","监狱警戒度","%d / 5级" % s.security,g.Prison.intake_label(g)+"3级起固定佩戴限制项圈，不占件数。","累计入狱记录","携带卡组与遗物继续游玩仍累计；新开游戏归零","bad")
 if s.prison.get("active",false) and s.phase!="prison_end":
  var prison=g.Prison.view(g)
  entry(out,"inspection","environment","狱警巡视","已暂停" if prison.paused else "剩余%d回合" % prison.left,"持有监门钥匙或正在反抗时暂停巡视。拘束具或性玩具缺件会分别触发补装；每次完整检查最后补满性玩具电池。\n"+prison.sentence,"当前牢房与警戒度","随牢房回合和巡视进度变化")
 if s.phase=="prison_end": entry(out,"terminal","limit","高安全监室","本局结束","无法继续回合或使用逃离道具；可以查看当前装备与状态。","五级警戒度","本局终局","bad")
 var special_status_ids=[]
 var special_details=[]
 for region in special_regions:
  for item in region.items:
   for equipment in item.equipment:
    if equipment.id in special_status_ids: continue
    special_status_ids.append(equipment.id)
    special_details.append(equipment.name+" · "+g.SpecialEquipment.location_name(g._equipment(equipment.id))+"\n"+equipment.text)
 if not special_details.is_empty():
  entry(out,"equipment_stimulation","pressure","装备刺激","%d件" % special_details.size(),"\n\n".join(special_details),"当前穿戴装备","解除后停止；电量耗尽只停止自动刺激，装备仍会保留","bad")
  mark(out,"pressure",str(special_details.size()))
 return out
