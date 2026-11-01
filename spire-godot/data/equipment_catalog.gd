extends RefCounted

const B=preload("res://data/balance.gd")
const C=preload("res://data/composites.gd")
const E=preload("res://data/equipment.gd")
const Enemies=preload("res://data/enemies.gd")

# Playable fixtures use the same factories as all equipment sources, never a second rules engine.
static func scenario(name: String, hint: String, equipment: Array=[], assemblies: Array=[]) -> Dictionary:
 return {"name":name,"description":"6回合 · 挂钩3次 · 切割工具2件 · 仅限拘束面","hint":hint,"equipment":equipment,"composites":assemblies,"items":["shard","saw"]}

static func ordinary(template: String, slot: String, grade: int=1, locked: bool=false, ratio: float=0.8) -> Dictionary:
 return {"template":template,"slot":slot,"grade":grade,"durability":E.maximum(grade)*ratio,"locked":locked}

static func assembly(kind: String, variant: String, tier: int=2, grade: int=2) -> Dictionary:
 return {"kind":kind,"variant":variant,"tier":tier,"grade":grade,"parts":{}}

static func entry(id: String, focus: String, spec: Dictionary) -> Dictionary:
 return {"label":spec.name,"node":"Practice_"+id,"focus":focus,"spec":spec}

static func entries() -> Dictionary:
 var result={}
 var henshin=scenario("音乐战斗练习","henshin播放雨爱，般若汤-其二播放鸳鸯戏。",[ordinary("rope","wrist",1,false,0.5),ordinary("belt","ankle",1,true)])
 henshin.description="对战两只敌人，开场4能量，手牌额外加入两种henshin与般若汤-其二各一张。"
 henshin.encounter="rope_tape";henshin.items=[]
 henshin.opening_cards=["henshin","hannya_henshin","hannya_2"]
 henshin.opening_energy=1
 result.henshin=entry("henshin","wrist",henshin)
 result.henshin.label="音乐战斗练习 · henshin／般若汤-其二"
 var shop=scenario("进入商店","浏览商品，选择自身或魔瓶魔力付款。")
 shop.start="shop";shop.items=[];shop.description="直接进入正式商店，使用当前商店库存与价格。"
 result.shop=entry("shop","",shop)
 var rest=scenario("进入火堆","选择奖励或附魔，然后开始休息。")
 rest.start="rest";rest.items=[];rest.description="6回合，可选择奖励和附魔。"
 result.rest=entry("rest","",rest)
 var puppet=scenario("玩偶师练习","保护从玩偶出生起生效；嘲讽出现前可以直接攻击玩偶师。")
 puppet.description="%d生命人形精英。开场携带受保护的玩偶；首次行动激活玩偶反击与嘲讽，随后循环缝补、复合装束和特殊装束。玩偶溢出伤害全额转给玩偶师。" % Enemies.TYPES.puppeteer.hp
 puppet.encounter="puppeteer_solo";puppet.items=[]
 result.puppeteer_solo=entry("puppeteer_solo","wrist",puppet)
 var iron=scenario("铁男练习","用挣扎或滑脱削减共用捕缚；达到100后，下一次敌方行动执行收押。击败铁男会让两名随行单位停机。")
 iron.description="%d生命首领，与捕缚无人机、魔导拘束盒一同出场。使用正式捕缚与五步强化循环；小魔女沿用该遭遇的生命加成。" % Enemies.TYPES.iron_man.hp
 iron.encounter="iron_man_solo";iron.items=[]
 result.iron_man_solo=entry("iron_man_solo","wrist",iron)
 var artist=scenario("绳艺大师练习","绳索库存、捕缚阈值与助理复活。")
 artist.description="大师%d生命，助理%d生命；击败大师结束战斗。" % [Enemies.TYPES.rope_master.hp,Enemies.TYPES.rope_assistant.hp]
 artist.encounter="rope_master_solo";artist.items=[]
 result.rope_master_solo=entry("rope_master_solo","wrist",artist)
 var box=scenario("魔导拘束盒练习","用魔法突破坚硬，及时削减捕缚进度。")
 box.description="%d生命。首次施加40/100捕缚，固定为坐姿；每个玩家回合开始追加中级2档皮革拘束具并推进10点。盒内有三件中级2档复合装备。" % Enemies.TYPES.binding_box.hp
 box.encounter="binding_box_solo";box.items=[]
 result.binding_box_solo=entry("binding_box_solo","thigh",box)
 var drone=scenario("魔导无人机练习","用魔法突破坚硬；注意消耗能量时的捕缚增长。")
 drone.description="%d生命。首回合建立30/100捕缚；之后施加或加固胶带、捕缚＋10、发呆，三步循环。" % Enemies.TYPES.drone.hp
 drone.encounter="drone_solo";drone.items=[]
 result.drone_solo=entry("drone_solo","wrist",drone)
 var mixed=scenario("杂乱拘束具练习","抓住躁动膨胀的空当，尽快击散这一团拘束具。")
 mixed.description="%d生命。首招散缚，之后随机散缚、翻卷收紧或躁动膨胀；狂躁永久增加施加数量。" % Enemies.TYPES.mixed_bundle.hp
 mixed.encounter="mixed_bundle_solo";mixed.items=[]
 result.mixed_bundle_solo=entry("mixed_bundle_solo","wrist",mixed)
 var pair=mixed.duplicate(true);pair.name="两团杂乱拘束具练习";pair.encounter="mixed_pair"
 result.mixed_pair=entry("mixed_pair","wrist",pair)
 var serpent=scenario("绳蛇练习","紧缠会在你的回合结束时施加装备；击败绳蛇可以停止它。")
 serpent.description="与%d生命的游动的绳蛇战斗。缠身增加1层紧缠，之后等概率收紧或甩缚，再返回缠身。" % Enemies.TYPES.rope_serpent.hp
 serpent.encounter="rope_serpent_solo";serpent.items=[]
 result.rope_serpent_solo=entry("rope_serpent_solo","wrist",serpent)
 var circle=scenario("魔法阵练习","首回合启动仪式，之后每回合施加数量持续增长，尽快击破法阵。")
 circle.description="与看着不妙的魔法阵战斗。仪式每个自身回合末增加3件数量加成；正常第2、3、4次行动分别尝试施加4、7、10件。"
 circle.encounter="ominous_circle_solo";circle.items=[]
 result.ominous_circle_solo=entry("ominous_circle_solo","wrist",circle)
 var small_circle=circle.duplicate(true)
 small_circle.name="小型魔法阵练习";small_circle.encounter="small_circle_solo"
 small_circle.description="与%d生命的小型魔法阵战斗。首回合获得3点仪式，之后正常每次施加4、7、10……件。" % Enemies.TYPES.small_circle.hp
 result.small_circle_solo=entry("small_circle_solo","wrist",small_circle)
 var trader=scenario("奴隶贩子练习","先施加两件初级拘束具，再让你无力化1个玩家回合，随后施加中级拘束具并获得准备就绪，最后优先施加马具口球或眼罩。后两轮跳过无力化，第11次行动收押。")
 trader.description="与被魔法控制的奴隶贩子进行独立战斗。无力化会禁用三种基础攻击，火球和卡牌魔法照常使用；准备就绪可叠层，每成功施加一件消耗一层，使该件紧度为3档，失败保留。"
 trader.encounter="trader_solo";trader.items=[]
 result.trader_solo=entry("trader_solo","wrist",trader)
 var versatile=scenario("多面手练习","第1回合发呆；之后安装性玩具，并在随机上锁或加固两件之间行动。",[ordinary("belt","wrist",1,false,0.4),ordinary("belt","forearm",1,false,0.4)])
 versatile.description="与%d生命的多面手战斗。它会施加特殊装备、上锁或加固拘束具。" % Enemies.TYPES.versatile.hp
 versatile.encounter="versatile_solo";versatile.items=[]
 result.versatile_solo=entry("versatile_solo","special_3",versatile)
 var shoulders=scenario("肩部链接练习","左右肩独立处理；两条都在时需先解除一条，剩一条时套体滑脱效果减半。肩带可滑脱或切割，交叉型须先松到一档。",[ordinary("rope","upper_arm",1,false,0.8)])
 shoulders.shoulders=[{"host":0,"template":"belt","grade":2}]
 result.shoulder_links=entry("shoulder_links","neck",shoulders)
 for size in ["mass","heap"]:
  for material in ["rope","belt"]:
   var id=material+"_"+size+"_solo"
   var name=("一团" if size=="mass" else "一堆")+("绳" if material=="rope" else "皮带")
   var hint="准备、施加中级2档同类装备、加固，三步循环。击败后分裂成两只同材质漂浮怪，下回合开始行动。" if size=="mass" else "半血分裂；尽早打散可以阻止第六次行动的全身施加。"
   var spec=scenario(name+"练习",hint)
   spec.description="独立战斗，全部分裂敌人离场后领取一次奖励。"
   spec.encounter=id;spec.items=[]
   result[id]=entry(id,"wrist",spec)
 result.shoulder_auto=entry("shoulder_auto","neck",scenario("三档肩绳练习","大臂三档自动附带一对；高级肩绳自身三档为交叉型，独立耐久。",[ordinary("rope","upper_arm",3,false,1.0)]))
 for blind in [false,true]:
  var id="prison_blind" if blind else "prison_test"
  var equipment=[ordinary("rope","wrist",1,false,0.4),ordinary("belt","thigh",1,false,0.4)]
  if blind: equipment.append(ordinary("eye_cloth","eyes",1,false,0.4))
  var spec={"name":"牢房测试 · "+("蒙眼" if blind else "无眼罩"),"description":"一级牢房，躺姿、靠墙，巡视周期%d回合。携带基础卡组，手腕和大腿各有一件1档装备。" % B.PRISON_INTERVALS[0],"hint":"可以探索、挣脱、换姿势、等待巡视或尝试逃离。无眼罩选择目的地；蒙眼选择方向，附近地点会亮起。移动步长和费用与向墙移动相同。","equipment":equipment,"items":[],"start":"prison"}
  result[id]=entry(id,"eyes" if blind else "thigh",spec)
 result.torso_binding=entry("torso_binding","forearm",scenario("躯干固缚练习","大臂、小臂或手腕单件达到3档，随机形成连接式或一体式固缚，持续至对应解除条件满足。连接式可以单独挣脱，再加固到3档会恢复。",[ordinary("rope","forearm",1,false,1.0),ordinary("belt","upper_arm",1,false,1.0)]))
 for id in ["rope_solo","belt_solo","tape_solo","cable_tie_solo","gag_solo","toybox_solo","lock_solo","belt_gag"]:
  var names={"rope_solo":"漂浮绳索","belt_solo":"漂浮皮带","tape_solo":"漂浮胶带","cable_tie_solo":"漂浮扎带","gag_solo":"漂浮口球","toybox_solo":"漂浮玩具箱","lock_solo":"漂浮锁","belt_gag":"皮带与口球"}
  var hint="施加初级2档、加固、准备、附着中级3档并离场。预告加固时若无目标，改为预告自身的施加行动；出手时再选目标，加固已无目标则空过。"
  if id in ["gag_solo","belt_gag"]: hint="口球准备两回合后附着中级3档并离场；需要空闲口部。"
  if id=="toybox_solo": hint="准备、佩戴、停顿，每三回合循环。打断会推迟当前步骤。"
  if id=="lock_solo": hint="预告上锁、上锁，两步循环。开启平板锁池时，无目标后尝试附加中级3档负数平板锁及其加固带再离场；无法佩戴仍离场。"
  var spec=scenario(names[id]+"练习",hint)
  spec.description="独立战斗，正常奖励与三回合整备。"
  spec.encounter=id
  if id=="lock_solo": spec.equipment=[ordinary("belt","wrist"),ordinary("belt","ankle")]
  result[id]=entry(id,"mouth" if id in ["gag_solo","belt_gag"] else "thigh",spec)
 for variant in C.LEGS:
  var id="leg_"+variant
  var a=assembly("leg",variant)
  for key in C.spec("leg",variant).parts:
   if key!="body": a.parts[key]={"tier":1}
  result[id]=entry(id,C.LEGS[variant][0],scenario(C.spec("leg",variant).name+"练习","先处理全部外带，再滑脱套体；直接破坏套体会留下仍环绕身体的独立外带。",[],[a]))
 result.leg_layers=entry("leg_layers","thigh",scenario("长短单腿套叠层练习","长套穿在两段短套外面。",[],[assembly("leg","upper"),assembly("leg","lower"),assembly("leg","ankle")]))
 result.jacket=entry("jacket","wrist",scenario("拘束衣练习","袖部连接需用挣扎或适用工具解除；解除它和下摆固定后，才可滑脱衣身。衣身破坏会同时清除依附组件。",[],[assembly("jacket","standard")]))
 for side in ["left","right"]:
  var id="wrap_"+side
  result[id]=entry(id,"palm",scenario(C.spec("wrap",side).name+"练习","另一只手仍能施法、握持工具。包裹共享一条耐久，解除后该侧手掌和手指同时恢复。",[],[assembly("wrap",side,1,1)]))
 result.wrap_both=entry("wrap_both","fingers",scenario("双侧独立包裹练习","双手分别被包裹，手势施法与握持受限，双臂共同固定状态保持原样。可借挂钩或安装工具逐侧解除。",[],[assembly("wrap","left",1,1),assembly("wrap","right",1,1)]))
 result.head_harness=entry("head_harness","eyes",scenario("眼罩与马具口球练习","口球和马具是一件装备。马具比眼罩更紧时阻止眼罩滑脱。口球解除仅限挣扎或徒手；徒手需要锁已打开且手部条件满足。滑脱牌可用于眼罩。",[ordinary("mouth_band","mouth",2),ordinary("eye_cloth","eyes",1,false,0.4),ordinary("eye_tape","eyes")]))
 for combination in [[1,0],[2,0],[2,1],[3,0]]:
  var gag=ordinary("mouth_band","mouth",combination[0])
  gag.material_variant=combination[1]
  var id="mouth_combination_%d_%d" % combination
  var title=E.name_for("mouth_band","mouth",combination[0],combination[1])
  result[id]=entry(id,"mouth",scenario(title+"练习","尝试使用卡牌或徒手解除口部装备。",[gag]))
 result.head_tape=entry("head_tape","mouth",scenario("眼口胶带练习","眼部仅有滑脱，口部可以挣扎与滑脱。头部胶带请用对应解除牌处理。",[ordinary("eye_tape","eyes"),ordinary("mouth_tape","mouth")]))
 for grade in [2,3]:
  var id="eye_leather_%d" % grade
  result[id]=entry(id,"eyes",scenario(E.GRADES[grade]+"皮革眼罩练习","皮革眼罩遮挡视线，可以上锁。解除请使用滑脱牌。",[ordinary("eye_leather","eyes",grade)]))
 var linked=scenario("复合外带链接练习","大腿外带与小腿外带通过链接绳相连。切断套体后外带及其连接保留；解除任一所连外带时移除链接。",[],[assembly("leg","upper"),assembly("leg","lower")])
 linked.component_links=[{"a_root":0,"a_part":"above_knee","b_root":1,"b_part":"below_knee","slots":["thigh","calf"],"durability":6.4,"blocks_a":true}]
 result.component_links=entry("component_links","thigh",linked)
 result.advanced=entry("advanced","wrist",scenario("高级材料练习","高级材料练习：更高耐久。",[ordinary("rope","wrist",3,false,0.4),ordinary("fine_belt","toes",3,true,0.4),ordinary("tape","calf",3,false,0.4),ordinary("cable_tie","thigh",3,false,0.4),ordinary("eye_cloth","eyes",3,false,0.4)]))
 var special=scenario("性玩具与快感练习","无线乳夹在回合开始时震动，马眼棒会在实际支付能量时产生刺激；裆部股绳同时经过小穴与后庭，但只刺激小穴。",[])
 special.special_equipment=[{"type":"nipple_clamp_medium","slot":"special_1_a"},{"type":"urethral_rod_medium","slot":"special_2_d"},{"type":"crotch_rope_medium","slot":"special_3_a"}]
 result.special_equipment=entry("special_equipment","special_1",special)
 var plate_lock=scenario("平板锁练习","开场佩戴高级3档负数跳蛋锁（导尿管），已经上锁并附带平板锁加固带。可安装锯条切断加固带后滑脱；也可先用术式解锁开锁，再以任意正数滑脱伤害解除整件。",[])
 plate_lock.description="6回合平板锁专项练习。开场装备会提高快感上限、持续产生刺激，并按真实上锁与加固带规则限制解除。提供小石片、锯条和额外一张术式解锁。"
 plate_lock.special_equipment=[{"type":"negative_vibrator_lock_catheter_high","slot":"special_2_a","tier":3}]
 plate_lock.opening_cards=["unlock"]
 result.plate_lock=entry("plate_lock","special_2",plate_lock)
 var pressure=scenario("快感与持续刺激练习","本房挣扎后快感增加20，每回合结束增加25。每回合可深呼吸2次，每次花1能量降低20快感，下回合能量＋1；普通固定带仅提供固定效果。",[ordinary("belt","wrist",2)])
 pressure.pressure=70.0
 pressure.pressure_sources=[{"id":"practice_resonance","name":"挣扎时身体与训练垫的摩擦","timing":"strain","amount":20.0,"room":"rest"},{"id":"practice_field","name":"训练室的低频震动装置","timing":"turn_end","amount":25.0,"room":"rest"}]
 result.pressure=entry("pressure","wrist",pressure)
 var climax=scenario("高潮练习","当前快感为99。打出开场的「用力！」，支付能量后马眼棒的刺激会让你进入一次正常高潮。",[])
 climax.description="独立战斗练习：初始99快感并佩戴初级马眼棒，开场额外抽入一张普通「用力！」。"
 climax.encounter="rope_solo";climax.items=[];climax.pressure=99.0
 climax.special_equipment=[{"type":"urethral_rod_low","slot":"special_2_d"}]
 climax.opening_cards=["strain"]
 result.climax_card=entry("climax_card","",climax)
 var battle=scenario("贴身刺激与高潮练习","两条浮游绳索每次实际行动都会贴身摩擦，使快感增加65；打断会让这次刺激一并延后。高潮后其余敌人继续行动。",[])
 battle.description="独立战斗练习：初始70快感，两名敌人，含正常战斗奖励与三回合整备。"
 battle.encounter="pressure_drill"; battle.pressure=70.0
 result.pressure_battle=entry("pressure_battle","wrist",battle)
 for count in [1,2]:
  var id="guard" if count==1 else "double_guard"
  var guard=scenario("魅魔警卫练习" if count==1 else "双魅魔警卫收押练习","开场会束住手腕、口部和脚踝，再准备并施加50/100的捕缚。无法新增或合法替换时，改为加固该处1次；紧度3且可上锁时，上锁并恢复满耐久。用挣扎或滑脱牌削减捕缚；达到100后，警卫下一次行动会收押你。",[])
  guard.description="捕缚存在时，每次花能量都会牵动一个随机特殊部位；只能依次从躺姿坐起、再站起，且每次切换使进度＋10。击败全部警卫获得正常奖励；被收押则保留装备与快感，收押时榨精并损失最多20魔力；传送符保留，其他道具没收。"
  guard.encounter="guard_solo" if count==1 else "double_guard"
  result[id]=entry(id,"wrist",guard)
 var gamble={"name":"魅魔的三局赌牌 · 事件练习","description":"进行三局赌牌，可以中途兑现筹码离开。","hint":"可以在第一局前拒绝；第一、二局后可兑现筹码离开。第三局会在故事中描写魅魔暂时解下、随后重新戴回原有性玩具。","equipment":[ordinary("rope","wrist",1,false,0.8),ordinary("belt","ankle",2,true,0.8)],"items":[],"start":"event","event":"succubus_three_games"}
 result.succubus_three_games=entry("succubus_three_games","special_2",gamble)
 var pawnshop={"name":"魅魔的魔力典当铺 · 事件练习","description":"进入后须完成一项交易：小额、大额，或附带两件固定性玩具。","hint":"再加点料固定安装中级无线乳夹跳蛋与中级无线后庭跳蛋；需同时具备两件的佩戴位置。","equipment":[],"items":[],"start":"event","event":"succubus_magic_pawnshop"}
 result.succubus_magic_pawnshop=entry("succubus_magic_pawnshop","special_1",pawnshop)
 var cleric={"name":"缚疗修女 · 事件练习","description":"接受补魔并佩戴两件初级2档单件拘束具、射精一次后移除一张牌，或无惩罚离开。","hint":"补魔选项仅生成普通单件；删牌在射精结算后打开卡组选择窗口。","equipment":[],"items":[],"start":"event","event":"binding_cleric"}
 result.binding_cleric=entry("binding_cleric","wrist",cleric)
 var bound_adventurer={"name":"拘束具堆里的微光 · 事件练习","description":"反复靠近皮包寻找遗物；每次尝试都会新增一件初级2档单件拘束具，失败后下次成功率提高10%。","hint":"新增拘束具来自周围的活化拘束具；可以随时带着它们离开。","equipment":[],"items":[],"start":"event","event":"bound_adventurer_relic"}
 result.bound_adventurer_relic=entry("bound_adventurer_relic","wrist",bound_adventurer)
 var studio={"name":"魅纹师的空房 · 事件练习","description":"可以同时解除两件拘束具，或取得稀有遗物「魅纹师的针匣」并获得诅咒「淫纹」；也可以原样离开。","hint":"回火通过二级窗口选择两件各异的拘束具；淫纹在手牌中时，每次实际花费能量都会增加4点快感。","equipment":[ordinary("rope","wrist",1,false,0.8),ordinary("belt","ankle",1,true,0.8)],"items":[],"start":"event","event":"enchanters_empty_studio"}
 result.enchanters_empty_studio=entry("enchanters_empty_studio","wrist",studio)
 var smuggler={"name":"偷渡商人的魔药箱 · 事件练习","description":"可以赊下走私魔力药水，让贴身魔瓶直接获得90魔力并取得诅咒「敏感」；也可以原样离开。","hint":"走私药水直接化作魔瓶魔力；也可直接离开。","equipment":[],"items":[],"start":"event","event":"smuggled_mana_potions"}
 result.smuggled_mana_potions=entry("smuggled_mana_potions","wrist",smuggler)
 var belt_cluster={"name":"漂浮皮带群 · 事件练习","description":"可以迎战三只初级漂浮皮带并取得稀有遗物「软化扣环」，或接受魔力灌注，恢复25魔力并获得诅咒「淫纹」。","hint":"击败全部三只漂浮皮带后直接返回塔路。","equipment":[],"items":[],"start":"event","event":"floating_belt_cluster"}
 result.floating_belt_cluster=entry("floating_belt_cluster","thigh",belt_cluster)
 var tasting={"name":"女药师的试饮摊 · 事件练习","description":"进入后须选择一种试饮：魔力补剂、解缚溶剂或魅魔特调。","hint":"解缚溶剂通过二级窗口选择并完全解除一件拘束具；魅魔特调会给予一件随机遗物和诅咒「敏感」。","equipment":[ordinary("rope","wrist",1,false,0.8)],"items":[],"start":"event","event":"alchemist_tasting_stall"}
 result.alchemist_tasting_stall=entry("alchemist_tasting_stall","wrist",tasting)
 var storeroom={"name":"废弃储物室 · 事件练习","description":"搜索后在共用战利品界面分别领取一件随机药剂、一件随机卷轴和一件随机工具。","hint":"每件道具单独领取，需要道具栏空位；继续将放弃剩余道具并直接返回塔路。","equipment":[],"items":[],"start":"event","event":"abandoned_storeroom"}
 result.abandoned_storeroom=entry("abandoned_storeroom","wrist",storeroom)
 var guest_room={"name":"缚梦客房 · 事件练习","description":"可以睡到自然醒，恢复全部魔力并佩戴三件中级1档拘束具；也可以永久失去8点最大魔力，拔走床芯换取随机遗物。","hint":"睡眠选项只随机佩戴普通单件，三件必须全部有合法位置；拔走床芯会在当前魔力超过新上限时一并压低当前值。","equipment":[],"items":[],"start":"event","event":"bound_dream_guest_room"}
 result.bound_dream_guest_room=entry("bound_dream_guest_room","wrist",guest_room)
 var statue={"name":"神秘女人的雕像 · 事件练习","description":"可以使用浅盘里固定的飞机杯高潮一次并移除一张牌，也可以收集30～60点魔瓶魔力，或直接离开。","hint":"魔瓶收益在进入事件时冻结；使用飞机杯的剧情结算后会打开共用删牌窗口。","equipment":[],"items":[],"start":"event","event":"mysterious_woman_statue"}
 result.mysterious_woman_statue=entry("mysterious_woman_statue","special_2",statue)
 var survey={"name":"迷宫测绘队 · 事件练习","description":"可以独自探险，获得100魔瓶魔力并佩戴两件中级2档拘束具；也可以结伴而行，安全获得30魔瓶魔力。","hint":"独自探险添加两件普通单件拘束具，需要两件的佩戴空间。","equipment":[],"items":[],"start":"event","event":"maze_survey_team"}
 result.maze_survey_team=entry("maze_survey_team","wrist",survey)
 var exit_practices={
  "prison_release":["到期出狱练习","从正常收押开始，按1级监狱规则佩戴装备并登记；进入牢房后从第1回合开始，初始刑期20回合，巡视间隔16回合。","自行挣脱、探索或等待；每次检查有违规最多延长8回合。刑期结束后须通过出狱检查，才能选择10—11层非休息、非宝箱起点。"],
  "prison_release_violation":["巡视与延期练习","从第1回合开始服刑。可尝试解除已登记装备，观察巡视时的补装和延期。","登记装备缺失或检查时工具被没收，当次期限延长8回合。刑期结束进行出狱检查；检查失败则继续服刑8回合。"],
  "prison_gate_exit":["击败守卫出狱练习","保留正常收押生成的装备，从出口守卫战开始，守卫使用正常血量。胜利后领取稀有卡三选一、遗物和60魔瓶魔力，再选择10—11层起点。","守卫胜利后选择新地图起点，可选战斗、事件与商店。"]}
 for id in exit_practices:
  var info=exit_practices[id]
  var practice=scenario(info[0],info[2])
  practice.start=id;practice.items=[]
  practice.description=info[1]
  result[id]=entry(id,"",practice)
 return result
