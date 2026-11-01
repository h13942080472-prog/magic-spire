extends RefCounted
const E=preload("res://data/equipment.gd")
const C=preload("res://data/composites.gd")
const B=preload("res://data/balance.gd")
const Relics=preload("res://data/relics.gd")
const Cards=preload("res://data/card_rules.gd")
const S=preload("res://data/special_equipment.gd")
const N=preload("res://data/enemies.gd")
const Images=preload("res://data/equipment_images.gd")
const Tools=preload("res://data/field_tools.gd")
const Consumables=preload("res://core/consumables.gd")
const InstalledTools=preload("res://core/installed_tools.gd")
const CATEGORIES={"equipment":"拘束具","cards":"卡牌","special":"特殊装备","enemies":"敌人","relics":"遗物","items":"道具"}
const METHODS={"strain":"挣扎","slip":"滑脱","magic_slip":"魔法滑脱","lower":"降低紧度","manual":"徒手","lock":"上锁","unlock":"开锁"}
const CARD_VARIANTS={"magic_hand":["magic_hand_gift"],"light_as_swallow":["hannya_swallow"],"infusion":["hannya_infusion"],"henshin":["hannya_henshin"]}
const VARIANT_SOURCES={"magic_hand_gift":"欧内的手赠牌","hannya_swallow":"般若汤赠牌","hannya_infusion":"般若汤赠牌","hannya_henshin":"般若汤赠牌"}

static func related_cards(type: String) -> Array:
 if type=="witch_escape_practice": return preload("res://core/witch_expansion.gd").TRAINING.slice(1)
 if type=="witch_endurance": return ["witch_sensitive"]
 if type=="witch_magic_hand": return ["witch_magic_hand_gift"]
 var result=CARD_VARIANTS.get(type,[]).duplicate()
 var stage=int(Cards.SPECS.get(type,{}).get("hannya_stage",0))
 if stage>0:
  for level in range(stage,5):
   var reward=Cards.HANNYA_REWARDS[level]
   for destination in ["hand","discard"]:
    var child=str(reward.get(destination,""))
    if child!="" and child!=type and child not in result: result.append(child)
 return result
const BEHAVIORS={"lock":"行动：预告上锁→上锁，循环。开启平板锁池时，上锁目标耗尽后必定尝试附加中级3档负数平板锁及加固带，随后离场；关闭时，上锁目标耗尽后直接离场。","restraint":"行动：施加初级2档拘束具→加固→准备→施加中级3档或高级2档拘束具，随后离场。","attachment":"行动：准备2回合→尝试施加中级3档口球→离场。施加需要口部空闲。","dispenser":"行动：准备→施加1件已选定的特殊装备→停顿，循环。","guard":"行动：施加拘束具与捕缚。","six_bind":"行动：六处束缚，随后反复施加和加固拘束具。","iron_man":"行动：以捕缚为核心的五回合机械循环。","iron_drone":"行动：独立施加捕缚，每累计3能量触发效果。"}
const TIGHTEN_TIMING="加固：选招时没有目标则改为施加；行动前目标失效则跳过。"
const CAPTURE_RULES="解除捕缚：挣扎／滑脱牌可削减进度，排除环境加成；仅有眼罩、口球或没有拘束具时伤害×2。归零后解除，敌人会准备1回合再施加。\n捕缚规则：被捕缚时无法移动，先解除捕缚。同种仅生效一次；异种共用进度，新种只增加其初始值的一半。达到100后，施加捕缚的敌人在下次行动收押。击败来源解除对应效果，全部来源离场则清空进度。\n降紧每层固定削减8点捕缚，使用固定数值，蓄力保留。"
const GUARD_DESCRIPTION="开场：手腕、口部、脚踝各施加1件拘束具，每件随机为初级3档、中级2档或高级1档；准备1回合后施加捕缚50/100。无法新增或合法替换时，改为加固该处1次；紧度3且可上锁时，上锁并恢复满耐久。\n行动：普通拘束具×2（初级3档／中级2档／高级1档）→捕缚＋10→中级2档复合拘束具×1，循环。复合无法施加时，改为加固至多2件至3档。\n捕缚效果：上身束缚等级至少1；姿态只能躺姿→坐姿→站姿，每次切换捕缚＋10。每次花费能量，使一个随机特殊部位增加10点基础快感（受敏感度影响）；每次高潮捕缚＋10。"
const TRADER_DESCRIPTION="行动：①拘束具×2，每件随机为初级2档或中级1档；②无力化1回合；③拘束具×1，随机为初级3档、中级2档或高级1档，准备就绪＋1；④优先施加中级马具口球或眼罩，无位置时改为其他普通拘束具。\n后续：重复①③④两轮，第11次行动收押。\n无力化：禁用体术，火球与卡牌魔法照常使用。\n准备就绪：每成功施加或替换1件消耗1层，使该件直接达到3档；失败保留。③先用旧层数，再获得新层数。\n范围：普通拘束具与链接绳，仅含此两类；①排除口球。出手时选择装备和位置，满位时可替换。"

static func card(type: String) -> Dictionary:
 var info=B.card_info(type)
 var result={"uid":"catalog_"+type,"type":type,"name":B.CARD_NAMES[type],"cost":"—" if B.CARD_TRAITS.get(type,{}).get("unplayable",false) else Cards.energy_label(type),"tag":info[0],"bound":info[1],"free":info[2],"note":info[3],"single_face":Cards.single_face(type)}
 result.merge(Cards.classification(type))
 result.merge(B.card_metadata(type))
 result.face_costs={}
 for side in ["bound","free"]:
  result.face_costs[side]=result.cost if result.cost in ["X","—"] else str(Cards.energy_cost(type,side=="free"))
 return result

static func row(id: String, category: String, group: String, title: String, text: String, grade: int=0) -> Dictionary:
 return {"id":id,"category":category,"group":group,"title":title,"text":text,"grade":grade}

static func equipment_notes(sample: Dictionary) -> String:
 if E.lock_only(sample): return ""
 if E.is_shackle(sample): return "仅有耐久，固定减伤90%。开锁即取下，也可通过伤害破坏。"
 var spec=E.TEMPLATES[sample.template]
 var lines=[]
 if E.allows(sample,"slip"): lines.append("3档通常免疫普通滑脱；魔法滑脱可突破紧度免疫，但仍受结构限制。")
 if E.allows(sample,"lock"): lines.append("上锁后：挣扎伤害通常×0.5，徒手解除需先开锁；滑脱仍按装备条件判断。")
 if "mouth" in spec.slots:
  var factor=B.MOUTH_CAST_GRADE[sample.grade]
  lines.append("嘴部施法：品质倍率×%s；紧度1／2／3档分别×%s／%s／%s。" % [str(factor),str(B.MOUTH_CAST_TIGHTNESS[1]),str(B.MOUTH_CAST_TIGHTNESS[2]),str(B.MOUTH_CAST_TIGHTNESS[3])])
  lines.append("本件合计倍率（1／2／3档）：×%s／%s／%s；额外成功率与最低成功率另算。" % [str(factor*B.MOUTH_CAST_TIGHTNESS[1]),str(factor*B.MOUTH_CAST_TIGHTNESS[2]),str(factor*B.MOUTH_CAST_TIGHTNESS[3])])
  if E.has_mouth_harness(sample): lines.append("马具结构禁止普通／魔法滑脱；马具比眼罩更紧时，也会阻止该眼罩滑脱。")
 if "eyes" in spec.slots: lines.append("视觉受阻：敌人意图隐藏，全部眼罩解除后恢复。更紧的口球马具会阻止眼罩滑脱。")
 if spec.slots.any(func(slot):return slot in ["upper_arm","forearm","wrist"]): lines.append("大臂／小臂／手腕达到3档时附带躯干固缚；大臂还会附带一对独立肩带。")
 return "\n".join(lines)

static func composite_notes(spec: Dictionary, grade: int) -> String:
 var parts=[]
 for p in spec.parts.values():
  var sample={"template":p.template,"grade":grade,"variant":0}
  parts.append("%s：耐久%s；%s" % [p.label,str(E.maximum(grade)).trim_suffix(".0"),E.method_text(sample)])
 var rules={
  "glove":"肩带剩2条：套体需先解除肩带再滑脱；剩1条：滑脱效果×0.5；全解除：恢复原效果。任意肩带解除后，套体非3档且无外层阻挡，再次挣扎可直接脱下。\n肩带左右独立；达到3档后交叉禁滑脱，降至1档才解除此封锁。套体破坏后肩带一并解除。",
  "leg":"套体整体滑脱须先解除全部外带，并满足外露、连接与紧度条件。套体破坏后，仍有耐久的外带保留。长至脚趾款封闭脚掌和脚趾。",
  "jacket":"袖部连接与下摆固定都解除后，才可整体滑脱衣身。袖部连接需用挣扎或适用工具解除。衣身破坏后，其余组件一并解除；完整衣身封闭双手操作。",
  "wrap":"只包裹对应一侧的手掌和手指，各侧最多1件。无独立锁；3档通常免疫普通滑脱。"}
 return "\n".join(parts)+"\n\n"+rules[spec.kind]

static func entries(g=null, character: String="") -> Array:
 var role=(g.state.get("character_id","original") if g!=null else "original") if character=="" else character
 var out=[]
 for type in Tools.TYPES:
  var spec=Tools.TYPES[type]
  var group={"potion":"药剂","scroll":"卷轴","tool":"工具"}[spec.get("category","tool")]
  var text="使用次数：%d\n" % spec.uses
  text+=Consumables.effect_description(type,spec.amount) if Tools.operation(type)=="buff" else Tools.effect_description(type,spec.damage)
  if not spec.get("trigger_damage_types",[]).is_empty():
   text+="\n安装后："+InstalledTools.effect_description(type,spec.damage)+"需靠近工具，目标须在接触范围内、材料适用且外露。"
  text+="\n随时可免费丢弃，回合保持当前进度。"
  var item=row(type,"items",group,spec.name,text);item.item=type;out.append(item)
 for id in E.TEMPLATES:
  var spec=E.TEMPLATES[id]
  if spec.slots.is_empty(): continue
  for grade in E.GRADES:
   if grade<spec.get("min_grade",1) or grade>spec.get("max_grade",3): continue
   for variant in range(E.MATERIALS[spec.material][grade].size()):
    var sample={"template":id,"grade":grade,"variant":variant}
    var text="部位："+"、".join(spec.slots.map(func(slot):return B.SLOT_NAMES[slot]))+"\n品质："+E.GRADES[grade]+"\n材质："+E.material_name(sample)+"\n最大耐久："+str(E.SHACKLE_MAXIMUM if E.is_shackle(sample) else E.maximum(grade)).trim_suffix(".0")+"\n方法："+E.method_text(sample)
    if E.lock_only(sample): text="3级及以上入狱时固定佩戴，件数统计豁免。\n普通 henshin 需要先解除项圈。\n"+E.LOCK_ONLY_REASON
    if not E.lock_only(sample): text+="\n\n"+equipment_notes(sample)
    out.append(row("equipment_"+id+"_%d_%d" % [grade,variant],"equipment",E.MATERIAL_NAMES[spec.material],(E.name_for(id,spec.slots[0],grade,variant) if id=="mouth_band" else spec.name)+" · "+E.material_name(sample),text,grade))
    out[-1].image=Images.path(sample)
 for layout in C.GENERATION:
  if layout[0]=="wrap" and layout[1]=="right": continue
  var spec=C.spec(layout[0],layout[1],layout[2])
  for grade in E.GRADES:
   if grade<spec.minimum: continue
   var title=("胶带包裹" if spec.kind=="wrap" else spec.name)+(" · "+("交叉肩带" if layout[2]=="cross" else "直肩带") if layout[0]=="glove" else "")
   out.append(row("composite_"+"_".join(layout)+str(grade),"equipment","复合装备",title,"覆盖："+"、".join(spec.coverage.map(func(slot):return B.SLOT_NAMES[slot]))+"\n\n"+composite_notes(spec,grade),grade))
   out[-1].image=Images.path({"template":spec.parts.body.template,"grade":grade,"variant":0})
 out.append(row("link_rope","equipment","链接","链接绳","连接两件装备，两端共享耐久。解除方式：挣扎、徒手或适用工具。锁孔：无。同区域内可连接两个子部位，跨区域只接相邻边界；每对装备最多一条，每方向按区域剩余子部位数限额、最低1。股绳可连接手腕或大腿根装备。"))
 out[-1].image=Images.path({"template":"link_rope","grade":1,"variant":0})
 out[-1].text+="\n普通单件仅有向下链接时，普通／魔法滑脱伤害×1.25，加成限一次。链接绳按原伤害计算，任一必要端解除时一并移除。"
 var card_types=Cards.SPECS.keys().filter(func(type):return not Cards.SPECS[type].get("encyclopedia_hidden",false))
 if g!=null: card_types=g.Character.pool(g,card_types,role)
 else: card_types=card_types.filter(func(type):return Cards.SPECS[type].get("character_id","original")==role)
 if g!=null and role=="witch":
  card_types.append_array(["witch_key","witch_preparation","witch_accumulation"])
 for type in card_types:
  var data=card(type)
  var group=data.type_name+"牌"
  var entry=row(type,"cards",group,data.name,data.face_names.bound+"："+data.bound+"\n"+"；".join(data.face_requirements.bound)+"\n"+data.face_names.free+"："+data.free+"\n"+"；".join(data.face_requirements.free)+"\n"+data.note)
  entry.card=type;entry.rarity=data.rarity;entry.rarity_name=data.rarity_name
  entry.related_cards=related_cards(type)
  entry.search_text="\n".join(entry.related_cards.map(func(child):var info=card(child);return info.name+"\n"+info.bound+"\n"+info.free+"\n"+info.note))
  out.append(entry)
 for relic in Relics.view(Relics.TYPES.keys()):
  if g!=null and not g.Character.relic_allowed(g,relic.id,role): continue
  if g==null and Relics.TYPES[relic.id].get("character_id","") not in ["",role]: continue
  var entry=row(relic.id,"relics","商店限定" if Relics.TYPES[relic.id].get("shop_only",false) else ("Boss遗物" if relic.id in Relics.BOSS_POOL else ("奖励遗物" if relic.id in Relics.REWARDS else "初始遗物")),relic.name,relic.detail)
  if relic.id=="doubao":
   entry.related_relics=[Relics.FIRST_TURN_MODES[1].duplicate(true)]
   entry.search_text=Relics.FIRST_TURN_MODES[1].name+Relics.FIRST_TURN_MODES[1].detail
  entry.rarity=relic.rarity;entry.rarity_name=relic.rarity_name;out.append(entry)
 for type in S.TYPES:
  var spec=S.DESIGNS[type];var definition=S.TYPES[type]
  var regions=S.REGIONS.filter(func(r):return spec.slots.any(func(slot):return slot in r.slots))
  var text="位置："+"、".join(spec.slots.map(S.slot_name))+"\n最大耐久：%s" % spec.maximum
  text+="\n可用方法："+" / ".join(spec.methods.map(func(m):return METHODS[m]))
  text+="\n借力环境："+("无" if spec.environments.is_empty() else "、".join(spec.environments.map(func(e):return S.ENVIRONMENT_NAMES[e])))
  text+="\n牵扯（每次消耗能量）触发的基础值：%s；每回合开始触发的基础值：%s。" % [definition.energy_gain,definition.turn_gain]
  var climax_rule=S.climax_slip_rule(type)
  if climax_rule!="": text+="\n"+climax_rule
  if definition.duration>0: text+="\n持续%d回合。" % definition.duration+"电量耗尽后停止刺激，装备继续佩戴。"
  text+="\n"+special_notes(type)
  out.append(row(type,"special","、".join(regions.map(func(r):return r.name)),definition.name,text,spec.grade))
  out[-1].image=Images.path({"template":"special","type":type})
 for type in N.TYPES:
  var spec=N.TYPES[type];var group="其他"
  if spec.behavior in ["puppet","iron_drone"]: group="随行单位" if spec.behavior=="iron_drone" else "召唤物"
  for rank in N.Library.CLASSIFICATIONS:
   if type in N.Library.CLASSIFICATIONS[rank]: group={"weak":"弱怪","strong":"强怪","elite":"精英","boss":"首领"}[rank]
  var sources=[]
  for rank in ["weak","strong"]:
   for encounter in N.FirstFloor.choices(rank):
    if encounter_contains(encounter,type):
     var label="第一幕弱怪战斗" if rank=="weak" else "第一幕强怪战斗"
     if label not in sources: sources.append(label)
  if N.FirstFloor.ELITE_ENCOUNTERS.any(func(id):return N.ENCOUNTERS[id].get("variants",[id]).any(func(v):return N.ENCOUNTERS[v].members.any(func(m):return m.type==type))): sources.append("精英房")
  if N.FirstFloor.SUMMIT_ENCOUNTERS.any(func(id):return encounter_contains(id,type)): sources.append("塔顶")
  var text="生命：%s\n" % spec.hp+BEHAVIORS.get(spec.behavior,"")
  if type=="puppeteer": text="生命：%s\n开场：自带%s生命玩偶，首回合赋予嘲讽与受伤反击。\n行动：准备中级2档复合拘束具→准备中级3档特殊装备→缝补，循环。缝补使玩偶生命上限＋5并回满，普通反击容量上限＋1并补满。\n护身屏障：每回合最多受到%s点最终伤害，上限随周目生命倍率提高；直接伤害与玩偶转移共用额度，下回合恢复。\n" % [spec.hp,N.TYPES.puppet.hp,spec.damage_cap]+N.BARRIER_CAPACITY_DESCRIPTION+"\n牵线保护：玩偶生命最低为1，溢出伤害转给玩偶师。击败玩偶师，玩偶同时离场。"
  if type=="puppet": text="生命：%s\n行动：由玩偶师操纵。生命最低为1，溢出伤害转给玩偶师。\n引敌缚咒：单体攻击必须选择玩偶，群攻可覆盖全体；每段正数伤害消耗1次普通反击，尝试施加1件普通拘束具，随机为初级2档或中级1档，遗物伤害也会触发。\n普通反击容量初始%d，上限受护身屏障削减，最低1；容量耗尽后停止反击。缝补使上限＋1并补满。\n备装：下一次攻击命中时，额外施加已准备的复合／特殊装备，各1件；多段只触发1次，普通反击容量保留。备装仅由主动攻击触发，位置欠缺时可合法替换。" % [spec.hp,spec.reaction_capacity]
  if spec.has("cycle") and not spec.has("split_threshold"):
   text="生命：%s\n行动：准备→施加1件初级3档／中级2档／高级1档%s类拘束具→加固同类拘束具，循环。" % [spec.hp,spec.restraint_name]
   text+="可施加同类链接绳。"
  if spec.has("split_threshold"):
   text=("生命：%s\n" % spec.hp)+"行动：①{material}增生；②准备；③施加2件{material}类拘束具（初级3档／中级2档／高级1档）；④加固至多2件至3档；⑤蓄力；⑥全身施加中级3档或高级2档拘束具（含链接绳），再以最大生命的50%分裂。\n增生：每个玩家回合开始，施加1件初级2档或中级1档同类拘束具，敌人离场后停止。\n分裂：受击后存活且生命≤50%时提前分裂，分裂要求存活。分裂为1只{large}和2只{small}：大怪继承当前生命，小怪各取其一半、向上取整；下回合开始行动。".format({"material":spec.restraint_name,"large":N.TYPES[spec.split_spawns[0].type].name,"small":N.TYPES[spec.split_spawns[1].type].name})
  if spec.behavior in ["restraint","guard"]: text+="\n"+TIGHTEN_TIMING
  if type=="trader": text="生命：%s\n" % spec.hp+TRADER_DESCRIPTION
  if type=="guard": text="生命：%s\n" % spec.hp+GUARD_DESCRIPTION
  if type=="binding_box":
   var support_hp=N.ENCOUNTERS.iron_man_solo.members.filter(func(member):return member.type=="binding_box")[0].hp
   text="生命：%s；铁男战中的随行实例为%s，小魔女铁男战为%s。\n特性：非魔法伤害减半。\n开场：捕缚40/100，固定坐姿，上身束缚等级至少1。施加后从第二个玩家回合起，每个玩家回合开始施加1件皮革拘束具（初级3档／中级2档／高级1档），捕缚＋10；无位置仍增加进度。\n行动：随机施加2件皮革拘束具／口球（初级3档／中级2档／高级1档），或加固皮革共4档→准备→施加1件备用复合拘束具，循环。没有加固目标时只选施加。\n备装：中级2档短上段单腿套、短下段单腿套、露手直肩带单手套各1件。成功施加才消耗，满位可替换，用尽后改为捕缚＋10；备用数量在开场确定。\n铁男战名称：凑数型拘束盒。初始捕缚改为20/100，循环行动1改为施加2件初级2档或中级1档拘束具或加固共2档；回合开始及备用装备耗尽后的捕缚追加均为＋5，其余效果相同。" % [spec.hp,support_hp,support_hp*1.3]
  if type=="versatile": text="生命：%s\n行动：首次行动停顿，此后循环“施加1件初级2档性玩具→随机上锁1件或加固至多2件至3档”。\n选择：上锁与加固各50%%；只有一项能用时选该项，两项均失效时改为施加性玩具。已预告的行动失去目标后跳过。\n范围：性玩具满位时可替换；范围排除飞机杯与外置震动棒。" % spec.hp
  if type=="drone": text="生命：%s\n特性：非魔法伤害减半。\n开场：捕缚30/100，固定站姿，上身束缚等级至少1。\n行动：随机施加2件初级1档胶带或加固胶带共2档→捕缚＋10→停顿，循环。没有加固目标时只选施加。\n捕缚效果：每累计消耗2能量，施加1件初级2档胶带，捕缚＋10。余数跨回合保留，无位置仍增加进度。胶带包括眼罩和嘴部胶带。" % spec.hp
  if type=="rope_master": text="生命140。绳索开场48/24，成功施加扣除装备品质与紧度之和。开场召唤助理、捕缚、空部位中级一档绳索、两次收紧、补绳；随后编织绳网、附魔、收紧、欣赏作品循环。第三轮末全部绳索无法解除。捕缚按每件绳索的品质与当前紧度之和累计；50／75及重跨90增加醉绳2层；50／重跨80施加驷马缚。助理死亡时悲伤，首次死亡后复活一次。击败大师直接结束战斗。"
  if type=="rope_assistant": text="生命36。召唤后三回合不可单体选中，群攻有效。依次准备、加入强人锁女并施加高级二档口球、空部位初级一档绳索、建立卡牌触发效果，此后每回合结算一次部位基础快感。高潮后下一回合休息，大师补绳时暂停。死亡移除状态牌与不可反抗，并按人形替换规则施加两件品质与紧度之和为4的特殊装备。杯类和平板锁均使对应部位不可用。"
  if type=="six_bind": text="生命：%s\n开场：展开六缚阵→眼部、口部、双臂、手腕与手部、大腿、小腿与足部六区各施加1件初级2档或中级1档拘束具，并施加1件初级性玩具。\n行动：戏弄封缚→双重束缚→调教升温→戏弄封缚→复合束装→调教升温→六缚齐收→空闲，循环。\n戏弄封缚：拘束具×1（初级3档／中级2档／高级1档），加入「玩弄」×1。双重束缚：拘束具×2，每件随机为初级3档、中级2档或高级1档，无法新增的次数改为加固。\n复合束装：中级2档复合拘束具×1，无法施加时改为加固共3档。六缚齐收：再次束缚六区（初级3档／中级2档／高级1档），加入「玩弄+」×3。空闲：本回合休息。\n调教升温：施加、加固性玩具各1＋收束层数次，然后收束＋1。首轮初级，此后中级；满位可替换，范围排除飞机杯。\n状态牌：「玩弄」／「玩弄+」仅作被动生效，回合结束留在手中时快感分别＋5／＋8。\n高潮逮捕：本场战斗累计第%d次高潮时准备逮捕，此后每次高潮都会再次准备。被打断时取消本次逮捕，下一回合恢复原行动。\n收押：普通、复合拘束具均无新增位置且无法加固时，预告收押；收押条件仅看普通与复合装备的新增与加固空间。" % [spec.hp,spec.climax_capture_threshold]
  if type=="iron_man": text="生命：%s；小魔女遭遇时为%s。\n特性：机械减伤。捕缚被挣开后，强化降低1层（最低0），机械减伤失效2回合并发呆1回合；铁男被击败时随行无人机与拘束盒同时停机。\n开场：施加30/100捕缚，限制为坐姿或躺姿；替换普通平板锁并佩戴中级2档龟头榨精杯。诅咒平板锁或小魔女改为3件中级2档其他特殊装备。\n捕缚：每累计消耗5能量，全部主动刺激型特殊装备触发1次。与凑数型无人机分别计数。\n循环：捕缚＋10或重新捕缚→施加普通皮革拘束具并加固→施加复合皮革拘束具及强化附加项→按当前强化层数佩戴／替换杯具或替代特殊装备并补满电量→强化。\n普通皮革：每件随机为初级3档、中级2档或高级1档；紧度或等级首次强化后改为中级3档或高级2档，两项均强化后固定高级3档。\n强化：每次使以后施加捕缚的数值＋5，并按紧度与普通数量／等级与普通数量／高级特殊装备与2把锁／普通与特殊数量及1把锁四组循环累计；第1、2、4组同时使加固量＋2档。无法施加的普通／复合拘束具改为加固。\n杯具升级：1层全包，2层紧度3，3层马眼全包，4层高级；5层起杯具无额外升级。\n无法佩戴杯具时：改为1层紧度3，2层数量＋1，3层升为高级，4层起每层数量＋1；开场和补电均按此规格施加／替换。" % [spec.hp,spec.hp*1.3]
  if type=="iron_drone": text="生命：%s；小魔女遭遇时为%s。\n铁男战名称：凑数型无人机。\n开场：独立施加20/100捕缚；解除后准备1回合再重新施加。捕缚生效时待机。\n捕缚效果：每累计消耗3能量，施加1件初级2档或中级1档胶带并使捕缚＋5；随机遥控1件主动刺激型特殊装备额外结算并消耗1电量；随机为1件拘束具上锁。\n铁男被击败时立即停机。" % [spec.hp,spec.hp*1.3]
  if type=="mixed_bundle": text="生命：%s\n开场：散缚，施加2件初级2档拘束具。\n行动：之后随机选招。散缚同开场；翻卷收紧先施加1件初级2档拘束具，再加固1件至3档；躁动膨胀获得1层狂躁。\n狂躁：每层使后续施加数量＋1，加固次数保留。\n限制：散缚、躁动膨胀之间需穿插其他招式，翻卷收紧最多连用2次。可施加原白名单内的普通拘束具（含口球、链接绳），仅填入空位。" % spec.hp
  if type=="rope_serpent": text="生命：%s\n行动：缠身→随机收紧或甩缚，循环；两种招式各50%%。\n缠身：紧缠＋1层。每个玩家回合结束，每层施加1件初级2档或中级1档绳索类拘束具。\n收紧：加固1件绳索类拘束具至3档。甩缚：施加2件初级2档或中级1档绳索类拘束具，含链接绳。\n特殊：预告收紧时没有目标则改为甩缚；预告后失去目标则跳过。紧缠持续至来源离场，击败该绳蛇才停止。" % spec.hp
  if type=="ominous_circle": text="生命：%s\n开场：获得%d点仪式，此后每个自身回合结束，施加数量＋%d。\n行动：从第2次行动起持续施加拘束具，数量通常为%d、%d、%d……；每件随机为初级2档或中级1档，含链接绳。\n无位置时：剩余每次施加改为加固1次；也无法加固则结束，剩余次数随本次行动结束清空。\n特殊：仪式启动后，数量增长在打断后仍持续；击败后停止。" % [spec.hp,spec.ritual_gain,spec.ritual_gain,1+spec.ritual_gain,1+2*spec.ritual_gain,1+3*spec.ritual_gain]
  if type=="small_circle": text="生命：%s\n开场：获得%d点仪式，此后每个自身回合结束，施加数量＋%d。\n行动：从第2次行动起持续施加拘束具，数量通常为%d、%d、%d……；每件均为初级2档，含链接绳。\n无位置时：剩余每次施加改为加固1次；也无法加固则结束，剩余次数随本次行动结束清空。\n特殊：仪式启动后，数量增长在打断后仍持续；击败后停止。" % [spec.hp,spec.ritual_gain,spec.ritual_gain,1+spec.ritual_gain,1+2*spec.ritual_gain,1+3*spec.ritual_gain]
  if not spec.get("humanoid",false) or not spec.has("capture_kind"):
   var limit="\n长战斗：首领战之外，从第%d回合起，佩戴拘束具≥%d件或总紧度≥%d时，自动离场；全部敌人离场按胜利结算。首领战及其随行单位维持原规则。"
   if spec.get("humanoid",false): limit="\n长战斗：首领战之外，从第%d回合起，佩戴拘束具≥%d件或总紧度≥%d时，反复准备逮捕；仍可打断。首领战及其随行单位维持原规则。"
   text+=limit % [B.ENEMY_LONG_BATTLE_ROUND,B.ENEMY_LONG_BATTLE_COUNT,B.ENEMY_LONG_BATTLE_TIGHTNESS]
  if spec.has("capture_kind"): text+="\n"+CAPTURE_RULES
  if spec.has("defeat_spawns"):
   var spawn_counts={}
   for spawn in spec.defeat_spawns: spawn_counts[spawn.type]=spawn_counts.get(spawn.type,0)+1
   var names=[]
   for spawn_type in spawn_counts: names.append("%d只%s" % [spawn_counts[spawn_type],N.TYPES[spawn_type].name])
   text+="\n击败后：分裂为"+"、".join(names)+"，下回合开始行动。"
  text+="\n出现："+("玩偶师召唤" if type=="puppet" else ("暂无塔内遭遇" if sources.is_empty() else "、".join(sources)))
  var entry=row(type,"enemies",group,spec.get("full_name",spec.name),text);entry.visual=spec.visual;out.append(entry)
 return out

static func special_notes(type: String) -> String:
 var spec=S.TYPES[type]
 var design=S.DESIGNS[type]
 var lines=[]
 for timing in ["energy","turn_start"]:
  var slots=spec.get("turn_stimulates",spec.stimulates) if timing=="turn_start" else spec.stimulates
  var sensitivity=slots.reduce(func(total,slot):return total+float(S.SENSITIVITY.get(slot,0.0)),0.0)
  var gain=spec.turn_gain if timing=="turn_start" else spec.energy_gain
  if gain>0: lines.append("%s：基础值×部位倍率%s×来源倍率。" % ["回合开始" if timing=="turn_start" else "牵扯",str(sensitivity*float(spec.get("turn_stimulus_factor",1.0) if timing=="turn_start" else 1.0))])
 if "manual" in design.methods: lines.append("双臂、双腕和双手完全自由时，花费1能量直接取出。")
 if "strain" in design.methods or "slip" in design.methods: lines.append("普通挣扎／滑脱需要可用手部辅助，或接触本件支持的借力环境。")
 if S.is_chastity_type(type):
  lines.append(spec.detail)
  lines.append("快感上限＋5×（品质＋紧度）；锁外来源快感×［1＋0.05×（品质＋紧度）］。每次高潮后按（品质＋紧度）×保留系数保留快感，系数初始3、每次永久＋1，普通模式最高10。")
 if spec.family in S.CUP_REINFORCEMENT_FAMILIES: lines.append("紧度达到3档时自动附加同品质固定带；滑脱杯体需先切断固定带，也可通过挣扎破坏杯体。")
 if spec.get("component_only",false): lines.append(spec.detail)
 if spec.family=="crotch_rope": lines.append("可连接手腕或大腿根装备；对手腕算下端，对大腿根算上端。")
 return "\n".join(lines)

# Pool provenance only; never draws or evaluates live admission from the catalogue.
static func encounter_contains(id: String, type: String) -> bool:
 var spec=N.ENCOUNTERS[id]
 if spec.members.any(func(m):return m.type==type): return true
 if spec.get("fixed_members",[]).any(func(m):return m.type==type): return true
 if spec.get("variants",[]).any(func(v):return encounter_contains(v,type)): return true
 if spec.has("family") and encounter_contains(spec.family,type): return true
 var strength=N.TYPES[type].get("strength",0)
 if strength<=0 or strength>spec.get("weak_strength",0): return false
 if spec.get("max_weak_strength",0)>0 and strength>spec.max_weak_strength: return false
 return N.FirstFloor.choices("weak").any(func(v):return N.ENCOUNTERS[v].members.any(func(m):return m.type==type))

