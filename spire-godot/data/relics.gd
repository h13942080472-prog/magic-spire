extends RefCounted

const SECRET_WEAPON_TRACTION={2:1.0,3:2.0,4:3.0,5:4.0,6:6.0}

const MODIFIER_LIMITS={"pressure_gain_flat":100,"turn_charge":10,"climax_continue":1,"climax_half_pressure":1,"cast_chance_percent":100,"desire_cast_curve":1,"pickup_pressure":100,"battle_end_pressure":100,"mechanical_damage_reduction_percent":100,"battle_force_last":1,"shuffle_energy_step":100,"shop_discount_percent":100,"skill_mana_cap":15,"preparation_turn_mana":100,"card_mana_discount":100,"toe_cast":1,"battle_turn_reserve":10,"battle_opening_focus":10,"reward_card_options":1,"elite_entry_mana":100,"boss_entry_mana":100,"prison_entry_mana":100,"pickup_mana_full":1,"pressure_reduction_percent":100,"max_energy":10,"keep_hand":1,"turn_end_pressure_loss":100,"turn_start_pressure":100,"combat_retention_layers":10,"unspent_turn_mana":100,"pressure_guard_turns":10,"unrestricted_items":1,"shop_flask_mana":100,"climax_flask_mana":100,"climax_next_draw":10,"capacity":10,"battle_mana":100,"low_mana_end_restore":100,"restraint_mana":100,"preparation_turns":10,"strength":10,"dexterity":10,"leg_dexterity":10,"opening_draw":10,"opening_energy":10,"opening_charge":10,"turn_draw":10,"opening_mana":100,"retain_energy":1,"pickup_mana_max":100,"pickup_mana":100,"mana_energy_step":100,"turn_energy_step":100,"single_hand_cast":1,"soften_locked_strain":1,"always_wall":1}

const RARITIES={"common":"普通","uncommon":"罕见","rare":"稀有","boss":"Boss","special":"特殊"}
const BOSS_POOL=["masochist_mark","doubao","gourd_flask","tattoo_sticker","cursed_blindfold","nesting_doll","binding_pyramid","shining_lamp","cursed_plate_lock","desire_cube_pro_max"]
const FALLBACK="rolling_log"
const COMMON_FALLBACK="intellect_cloak"
const WRIST_BRACER_STRENGTH=2
const SHUFFLE_ENERGY_GAIN=2

const FIRST_TURN_MODES=[
 {
  "name": "豆包",
  "icon": "doubao",
  "detail": "能量上限＋1。\n战斗、休息及监狱的首回合由豆包接管。\n离开战斗、战后整备、休息及监狱后，右键切换为DeepSeek。"
 },
 {
  "name": "DeepSeek",
  "icon": "deepseek",
  "detail": "能量上限＋1。\n战斗、战后整备、休息及监狱的首回合开始时，能量变为0；仍可自行行动。\n仅限上述阶段之外右键切回豆包。"
 }
]

static var TYPES={
 "edging_seal":{"rarity":"uncommon","name":"寸止钢印","detail":"每场类战斗1次，快感达到上限时，先将快感减半，再获得3层蓄力。绿色小鸟优先生效；战后整备沿用战斗次数。","modifiers":{},"trigger":{"event":"pressure_threshold","scope":"battle","op":"halve_pressure_charge","amount":3}},
 "scrap_robot":{"rarity":"uncommon","name":"破铜烂铁机器人","detail":"机械系敌人的体术减伤改为25%（受到75%伤害）。仅影响体术伤害。","modifiers":{"mechanical_damage_reduction_percent":25}},
 "ditto":{"rarity":"uncommon","name":"百变怪","detail":"战斗开始时，随机变成一件非拾取触发、非Boss遗物，包含滚木；可与已有遗物重复生效。","shop_only":true,"modifiers":{}},
 "masochist_mark":{"rarity":"boss","name":"抖M印记","detail":"能量上限＋1。战斗中永远为后手。","modifiers":{"max_energy":1,"battle_force_last":1}},
 "doubao":{"rarity":"boss","name":"豆包","detail":FIRST_TURN_MODES[0].detail,"modifiers":{"max_energy":1}},
 "sundial":{"rarity":"uncommon","name":"日晷","detail":"每洗牌3次，获得2能量。","modifiers":{"shuffle_energy_step":3}},
 "great_wand":{"rarity":"uncommon","name":"大魔棒","detail":"每成功打出1张技能牌，积攒1点，上限15。右键图标消耗全部点数，恢复等量自身魔力；满15点自动兑换并清空。点数跨回合、跨战斗保留，仅主动出牌计数；恢复至多为魔力上限。","modifiers":{"skill_mana_cap":15}},
 "secret_weapon":{"rarity":"rare","name":"秘密武器","detail":"脚趾自由时可代替手部施法，取两者较高成功率。脚趾被拘束时改为产生牵扯。等级＋紧度为2／3／4／5／6时，每次牵扯基础快感＋1／2／3／4／6，多件累加；脚趾的拘束优先级提高至与嘴部相同，仅次于手腕。","modifiers":{"toe_cast":1}},
 "witch_amulet":{"rarity":"special","character_id":"witch","name":"魔女护符","detail":"战斗中每回合开始时，获得1层魔力预备。","modifiers":{"battle_turn_reserve":1}},
 "witch_noodles":{"rarity":"common","character_id":"witch","name":"辣椒炒肉拌面","detail":"战斗开始时，获得2层精神集中。","modifiers":{"battle_opening_focus":2}},
 "gourd_flask":{"rarity":"boss","name":"葫芦酒壶","detail":"拾取时，将一张「般若汤-其一」加入卡组。","modifiers":{},"pickup_cards":["hannya_1"]},
 "shrimp_paste":{"rarity":"uncommon","name":"虾滑","detail":"拾起时，魔力上限＋12，恢复12魔力。","modifiers":{"pickup_mana_max":12,"pickup_mana":12}},
 "magnifying_glass":{"rarity":"rare","name":"放大镜","detail":"选择奖励牌时，候选增加1张。从下次生成奖励起生效。","modifiers":{"reward_card_options":1}},
 "axe_amulet":{"rarity":"uncommon","name":"斧护符","detail":"进入精英房、Boss房或监狱时，恢复20魔力。","modifiers":{"elite_entry_mana":20,"boss_entry_mana":20,"prison_entry_mana":20}},
 "oune_hand":{"rarity":"uncommon","name":"欧内的手","detail":"拾取时，将1张没有“消耗”的「魔术手」加入卡组。","modifiers":{},"pickup_cards":["magic_hand_gift"]},
 "universal_scanner":{"rarity":"uncommon","name":"扫描全能王","pickup_bundle":true,"detail":"拾取时，选择一张卡组中的牌复制，基础牌、双面唯一能力牌除外。","shop_only":true,"modifiers":{}},
 "membership_card":{"rarity":"rare","name":"会员卡","detail":"商店限定。购买会员卡仅可使用自身魔力。持有后，商店全部商品、删牌及解除拘束服务五折；其他交易仍可使用自身魔力或魔瓶付款。","shop_only":true,"shop_payment":"self","modifiers":{"shop_discount_percent":50}},
 "m_donalds":{"rarity":"uncommon","name":"M当劳","detail":"商店限定，仅可用魔瓶购买。拾取时，魔力上限＋10，并回满自身魔力。","shop_only":true,"shop_payment":"flask","modifiers":{"pickup_mana_max":10,"pickup_mana_full":1}},
 "tattoo_sticker":{"rarity":"boss","name":"纹身贴","detail":"最大能量＋1。拾取时，将2张「淫纹」加入卡组。","modifiers":{"max_energy":1}},
 "cursed_blindfold":{"rarity":"boss","name":"诅咒眼罩","detail":"最大能量＋1。拾起时，永久佩戴一件眼罩。","modifiers":{"max_energy":1}},
 "cursed_plate_lock":{"rarity":"boss","name":"诅咒平板锁","detail":"能量上限＋1。拾取时，强制佩戴紧度3档的高级平板锁；跳蛋每场只在前6回合生效，高潮后快感保留系数最高10。击败下一个Boss获得专属钥匙，自动解锁并取下整件；此前无法解除。","modifiers":{"max_energy":1}},
 "nesting_doll":{"rarity":"boss","name":"套娃","pickup_bundle":true,"detail":"拾取时，随机出现普通、罕见、稀有遗物各1件，可分别领取或跳过。","modifiers":{}},
 "binding_pyramid":{"rarity":"boss","name":"缚纹金字塔","detail":"回合结束时，手牌全部保留。","modifiers":{"keep_hand":1}},
 "shining_lamp":{"rarity":"boss","name":"闪耀的灯球","detail":"最大能量＋1。拾取时，魔力上限－50。","modifiers":{"max_energy":1}},
 "ice_heart":{"rarity":"common","name":"冰心诀","detail":"回合结束时，快感－3。","modifiers":{"turn_end_pressure_loss":3}},
 "magic_blood":{"rarity":"uncommon","name":"魔血","detail":"力量＋2。回合开始时，快感＋5。","modifiers":{"strength":2,"turn_start_pressure":5}},
 "turtle_shell":{"rarity":"rare","name":"乌龟壳","detail":"能量、蓄力、临时魔力的跨战斗保留上限各增加2层：额外能量最多3点、蓄力最多4层、临时魔力最多30点。","modifiers":{"combat_retention_layers":2}},
 "olihakimi":{"rarity":"uncommon","name":"奥利哈基米","detail":"回合结束时，本回合耗魔为0则恢复8魔力。","modifiers":{"unspent_turn_mana":8}},
 "green_bird":{"rarity":"rare","name":"绿色小鸟","detail":"每场战斗前6回合，快感至多达到当前上限－1。","modifiers":{"pressure_guard_turns":6}},
 "braised_eggplant":{"rarity":"rare","name":"红烧鱼香茄子","detail":"拾取时，魔力上限＋20，恢复20魔力。","modifiers":{"pickup_mana_max":20,"pickup_mana":20}},
 "tentacle_friend":{"rarity":"rare","name":"触手朋友","detail":"使用道具无视身体、姿势和触及限制。切割、尖锐工具随身即视为固定，对全身生效。药剂口部减效，以及次数、材料、目标要求照常。","modifiers":{"unrestricted_items":1}},
 "spicy_rice_noodles":{"rarity":"common","name":"爆炒麻辣米线","detail":"战斗开始时，获得2层蓄力。","modifiers":{"opening_charge":2}},
 "flyer":{"rarity":"common","name":"传单","detail":"进入商店时，魔瓶补充20点魔力。","modifiers":{"shop_flask_mana":20}},
 "kings_gift_revised":{"rarity":"rare","name":"成王之礼精装修订重置版","detail":"每场战斗第7回合结束时，对所有敌人造成77点固定伤害。","modifiers":{},"trigger":{"event":"turn_end","scope":"battle","phase":"battle","round":7,"op":"fixed_enemy_damage","amount":77}},
 "rolling_log":{"rarity":"special","name":"滚木","detail":"没有效果。","modifiers":{},"collectible":true},
 "marble":{"rarity":"uncommon","name":"西兰花","detail":"战后整备或牢房探索结束时，魔力≤上限的50%则恢复20魔力。","modifiers":{"low_mana_end_restore":20}},
 "marble_stone":{"rarity":"rare","name":"大理石","detail":"所有来源的快感增长×0.6。","modifiers":{"pressure_reduction_percent":40}},
 "graduate_certificate":{"rarity":"uncommon","name":"优秀学员毕业证书","detail":"「用力！」和「顾涌！」的卡面基础伤害＋4。","modifiers":{},"card_base_bonuses":{"strain":4,"slip":4}},
 "little_pig":{"rarity":"rare","name":"一只小猪","detail":"始终视为贴墙。操作环境工具仍需靠近。","modifiers":{"always_wall":1}},
 "small_gem":{"rarity":"common","name":"小宝石","detail":"战斗第1回合，额外获得1能量。","modifiers":{"opening_energy":1}},
 "desire_cube_pro_max":{"rarity":"boss","name":"欲望魔方 Pro Max","detail":"拾取时，获得50点快感。每场战斗结束后，获得10点快感。\n改变快感对施法成功率的影响：快感0%／100%时为0%，25%／75%时为50%，50%时为100%；部位拘束等其他判定照常。\n解锁淫魔法卡牌与专用遗物池。\n从Boss遗物池获得时，额外获得1件随机专用遗物与1张随机淫魔法稀有卡，并将1张「心痒难耐」加入卡组和手牌。","modifiers":{"pickup_pressure":50,"battle_end_pressure":10,"desire_cast_curve":1}},
 "desire_cube":{"rarity":"rare","name":"欲望魔方","detail":"每被施加一件拘束具，恢复5魔力。复合装备整件计1次。","modifiers":{"restraint_mana":5}},
 "happy_fa":{"rarity":"uncommon","name":"开心小fa","detail":"每累计3个玩家回合，获得1能量。进度跨战斗保留。","modifiers":{"turn_energy_step":3}},
 "casting_manual":{"rarity":"rare","name":"施法动作教程","detail":"只需一只手的手掌和手指自由，即可满足手部施法条件。","modifiers":{"single_hand_cast":1}},
 "enchanters_needle_case":{"rarity":"rare","name":"魅纹师的针匣","detail":"每回合开始时，额外抽1张牌。","modifiers":{"turn_draw":1}},
 "softened_buckle":{"rarity":"rare","name":"软化扣环","detail":"上锁拘束具的挣扎伤害倍率提高至×0.75。","modifiers":{"soften_locked_strain":1}},
 "mana_earring":{"rarity":"rare","name":"魔力耳坠","detail":"每场战斗中，每累计消耗30魔力，获得1能量。","modifiers":{"mana_energy_step":30}},
 "ready_backpack":{"rarity":"common","name":"准备背包","detail":"战斗第1回合，额外抽2张牌。","modifiers":{"opening_draw":2}},
 "smooth_stockings":{"rarity":"uncommon","name":"光滑的丝袜","detail":"腿部、脚踝及足部灵巧＋2。","modifiers":{"leg_dexterity":2}},
 "donut":{"rarity":"rare","name":"甜甜圈","detail":"剩余能量保留到下一回合。","modifiers":{"retain_energy":1}},
 "small_sigil":{"rarity":"common","name":"小刻印","detail":"战斗开始时，恢复5魔力。","modifiers":{"opening_mana":5}},
 "martial_book":{"rarity":"common","name":"体术书","detail":"力量＋1。","modifiers":{"strength":1}},
 "wrist_bracer":{"rarity":"common","name":"护腕","detail":"手腕被拘束时，力量＋2。","modifiers":{}},
 "wraith_ribbon":{"rarity":"common","name":"怨灵系带","detail":"灵巧＋1。","modifiers":{"dexterity":1}},
 "brainwash_earrings":{"rarity":"common","required_relic":"desire_cube_pro_max","name":"洗脑耳环","detail":"获得快感时，额外获得2。","modifiers":{"pressure_gain_flat":2}},
 "hypnosis_hairpin":{"rarity":"rare","required_relic":"desire_cube_pro_max","name":"催眠发卡","detail":"主动或效果降低快感时，获得10快感；高潮回落除外。","modifiers":{},"trigger":{"event":"pressure_lost","scope":"repeat","op":"pressure","amount":10}},
 "lewd_silk_bodysuit":{"rarity":"uncommon","required_relic":"desire_cube_pro_max","name":"淫纹连体丝","detail":"每回合获得1层蓄力。每消耗1层蓄力，获得5快感。高潮不再跳过回合，快感变为上限的50%。","modifiers":{"turn_charge":1,"climax_continue":1,"climax_half_pressure":1},"trigger":{"event":"charge_spent","scope":"repeat","op":"pressure","amount":5}},
 "lewd_silk_gloves":{"rarity":"common","required_relic":"desire_cube_pro_max","name":"淫纹丝手套","detail":"魔法／淫魔法施法成功率＋25个百分点。施法成功时，获得5快感。","modifiers":{"cast_chance_percent":25},"trigger":{"event":"spell_succeeded","scope":"repeat","op":"pressure","amount":5}},
 "lucidity_necklace":{"rarity":"rare","name":"清醒项链","detail":"高潮时，下回合多抽1张牌。","modifiers":{"climax_next_draw":1}},
 "pleasure_extractor":{"rarity":"uncommon","name":"快感汲取器","detail":"高潮后，魔瓶魔力＋10。","modifiers":{"climax_flask_mana":10}},
 "ethereal_pendant":{"rarity":"common","name":"空灵挂件","detail":"每个整备回合结束时，恢复1魔力。","modifiers":{"preparation_turn_mana":1}},
 "intellect_cloak":{"rarity":"common","name":"智力斗篷","detail":"魔法牌耗魔－1，最低为0。可叠加。","collectible":true,"modifiers":{"card_mana_discount":1}},
 "strawberry":{"rarity":"common","name":"草莓","detail":"拾取时，魔力上限＋6，恢复6魔力。","modifiers":{"pickup_mana_max":6,"pickup_mana":6}},
 "break_bracer":{"rarity":"uncommon","trigger":{"event":"strain_destroyed","scope":"turn","op":"charge","amount":1},"name":"断缚护腕","detail":"挣扎直接使一个目标归零后，行动结束获得1层蓄力；每玩家回合1次。","modifiers":{}},
 "silk_ring":{"rarity":"uncommon","trigger":{"event":"card_slipped","scope":"turn","op":"draw","amount":1},"name":"游丝指环","detail":"每回合首次通过卡牌滑脱使拘束具降档或解除，行动结束抽1张牌。","modifiers":{}},
 "turn_ribbon":{"rarity":"common","trigger":{"event":"fell","scope":"turn","phase":"battle","op":"posture_discount","from":"lie","to":"sit","amount":1},"name":"回身缎带","detail":"战斗中并腿踢击后躺下时，本回合下一次躺→坐少花1能量，最低0；每玩家回合1次。","modifiers":{}},
 "ember_crystal":{"rarity":"rare","trigger":{"event":"paid_cast","scope":"turn","op":"guarantee","amount":1},"name":"余烬晶石","detail":"每回合首次耗魔施法必定成功。","modifiers":{}},
 "ember":{"rarity":"common","name":"余烬护符","detail":"战后整备结束时，恢复10魔力。","modifiers":{"battle_mana":10.0}},
 "toolbox":{"rarity":"common","name":"折叠工具匣","detail":"随身道具容量＋1。","modifiers":{"capacity":1}},
 "hourglass":{"rarity":"uncommon","name":"整备沙漏","detail":"战后整备延长1回合。","modifiers":{"preparation_turns":1}}}
static var REWARDS=["brainwash_earrings","hypnosis_hairpin","lewd_silk_bodysuit","lewd_silk_gloves","lucidity_necklace","edging_seal","pleasure_extractor","scrap_robot","sundial","great_wand","secret_weapon","witch_noodles","shrimp_paste","magnifying_glass","axe_amulet","oune_hand","marble_stone","ice_heart","magic_blood","turtle_shell","olihakimi","green_bird","braised_eggplant","tentacle_friend","spicy_rice_noodles","flyer","kings_gift_revised","marble","graduate_certificate","little_pig","small_gem","desire_cube","happy_fa","casting_manual","mana_earring","ready_backpack","smooth_stockings","donut","small_sigil","martial_book","wrist_bracer","wraith_ribbon","ethereal_pendant","intellect_cloak","strawberry","toolbox","hourglass","break_bracer","silk_ring","turn_ribbon","ember_crystal"]

static func definition(id: String, form: String="") -> Dictionary:
 return TYPES[form if id=="ditto" and form!="" else id]

static func pickup_triggered(id: String) -> bool:
 var spec=TYPES[id]
 return spec.get("pickup_bundle",false) or spec.has("pickup_cards") or spec.modifiers.keys().any(func(key):return String(key).begins_with("pickup_"))

static func transformable(id: String) -> bool:
 return TYPES.has(id) and id!="ditto" and TYPES[id].rarity!="boss" and not pickup_triggered(id)

static func form_issue(state: Dictionary) -> String:
 var form=state.get("ditto_form","")
 if not form is String: return "百变怪形态记录有误。"
 if form!="" and ("ditto" not in state.relics or not transformable(form)): return "百变怪形态来源有误。"
 return ""

static func trigger(id: String, form: String="") -> Dictionary:
 return definition(id,form).get("trigger",{})

static func can_gain(ids: Array, id: String) -> bool:
 return id not in ids or TYPES[id].get("collectible",false)

static func shop_pool() -> Array:
 return REWARDS+TYPES.keys().filter(func(id):return TYPES[id].get("shop_only",false) and id not in REWARDS)

static func is_reward(id: String, source: String="normal") -> bool:
 return id==FALLBACK or id in (shop_pool() if source=="shop" else REWARDS) or id in BOSS_POOL

static func shop_reason(spec: Dictionary) -> String:
 if not spec.get("shop_only",false) is bool: return "商店限定标记必须为布尔值。"
 if spec.get("shop_only",false) and spec.rarity not in ["common","uncommon","rare"]: return "商店限定遗物需要普通、罕见或稀有品质。"
 if spec.has("shop_payment") and (not spec.get("shop_only",false) or spec.shop_payment not in ["self","flask"]): return "指定付款来源需要商店限定遗物及有效来源。"
 return ""

static func collectible_reason(spec: Dictionary) -> String:
 if not spec.get("collectible",false) is bool: return "收藏遗物标记必须为布尔值。"
 if not spec.get("collectible",false): return ""
 if spec.rarity=="common" and spec.modifiers=={"card_mana_discount":1} and not spec.has("trigger") and not spec.has("card_base_bonuses") and not spec.has("pickup_cards"): return ""
 if spec.rarity!="special" or not spec.modifiers.is_empty() or spec.has("trigger") or spec.has("card_base_bonuses"): return "可重复收藏的特殊遗物需使用空效果列表。"
 return ""

static func card_base_bonus(ids: Array, type: String, form: String="") -> float:
 var total=0.0
 for id in ids: total+=definition(id,form).get("card_base_bonuses",{}).get(type,0.0)
 return total

static func card_bonuses_reason(bonuses, cards: Dictionary) -> String:
 if not bonuses is Dictionary or bonuses.is_empty(): return "卡牌基础加成需要至少一个卡牌与数值。"
 for type in bonuses:
  if not cards.has(type) or not cards[type].has("base"): return "卡牌基础加成需要具有基础伤害的卡牌。"
  var amount=bonuses[type]
  if not (amount is int or amount is float): return "卡牌基础加成必须为1—100整数。"
  if not is_finite(float(amount)) or amount<1 or amount>100 or floorf(amount)!=amount: return "卡牌基础加成必须为1—100整数。"
 return ""

static func trigger_reason(spec) -> String:
 if not spec is Dictionary or spec.is_empty(): return "遗物触发配置需要至少一项。"
 for key in spec:
  if key not in ["event","scope","phase","op","amount","ratio","from_tier","to_tier","from","to","round"]: return "遗物触发字段待支持。"
 if spec.get("event","") not in ["strain_destroyed","card_slipped","magic_paid","fell","turn_end","paid_cast","pressure_threshold","pressure_lost","charge_spent","spell_succeeded"] or spec.get("scope","") not in ["turn","battle","repeat"]: return "遗物触发事件或周期有误。"
 if (spec.scope=="repeat" or spec.get("op","")=="pressure" or spec.event in ["pressure_lost","charge_spent","spell_succeeded"]) and (spec.scope!="repeat" or spec.get("op","")!="pressure" or spec.event not in ["pressure_lost","charge_spent","spell_succeeded"]): return "重复快感触发需要对应事件与快感效果。"
 if spec.has("phase") and spec.phase not in ["battle","prepare","rest","prison"]: return "遗物触发阶段有误。"
 if spec.get("op","") not in ["charge","draw","mana","posture_discount","fixed_enemy_damage","guarantee","halve_pressure_charge","pressure"]: return "遗物触发效果有误。"
 if (spec.op=="guarantee" or spec.event=="paid_cast") and (spec.op!="guarantee" or spec.event!="paid_cast" or spec.scope!="turn" or spec.get("amount",0)!=1): return "必定施法需要每回合首次耗魔施法触发。"
 if (spec.event=="pressure_threshold" or spec.op=="halve_pressure_charge") and (spec.event!="pressure_threshold" or spec.op!="halve_pressure_charge" or spec.scope!="battle"): return "快感临界保护需要数值触发，每场一次。"
 if spec.has("round") and (spec.event!="turn_end" or not spec.round is int or spec.round<1 or spec.round>100): return "指定回合需要回合结束触发和1—100整数。"
 if spec.op=="fixed_enemy_damage" and (spec.event!="turn_end" or spec.scope!="battle" or spec.get("phase","")!="battle" or not spec.has("round")): return "全体固定伤害需要指定战斗回合结束，每场一次。"
 if spec.op=="mana":
  if spec.event!="magic_paid" or spec.has("amount") or not (spec.get("ratio") is int or spec.get("ratio") is float): return "魔力返还需要支付事件和返还比例。"
  if not is_finite(float(spec.ratio)) or spec.ratio<=0 or spec.ratio>1: return "魔力返还比例必须在(0, 1]内。"
 elif not spec.get("amount") is int or spec.amount<1 or spec.has("ratio"): return "遗物效果数量必须为正整数。"
 for key in ["from_tier","to_tier"]:
  if spec.has(key) and (spec.event!="card_slipped" or not spec[key] is int or spec[key] not in [1,2,3]): return "滑脱档位条件有误。"
 if spec.op=="posture_discount":
  if spec.event!="fell" or spec.scope!="turn" or spec.get("from","") not in ["stand","sit","lie"] or spec.get("to","") not in ["stand","sit","lie"]: return "姿态减免配置有误。"
 elif spec.has("from") or spec.has("to"): return "只有姿态减免支持起止姿态。"
 return ""

static func value(ids: Array, hook: String, counters: Dictionary={}, form: String="") -> float:
 var total=0.0
 for id in ids:
  var spec=definition(id,form)
  var count=int(counters.get(id,1)) if id!="ditto" and spec.get("collectible",false) else 1
  total+=spec.modifiers.get(hook,0.0)*count
 return total

static func view(ids: Array) -> Array:
 return ids.map(func(id):return {"id":id,"name":TYPES[id].name,"detail":TYPES[id].detail,"rarity":TYPES[id].rarity,"rarity_name":RARITIES[TYPES[id].rarity]})

static func pickup_cards_reason(cards, specs: Dictionary) -> String:
 if not cards is Array or cards.is_empty() or cards.size()>10: return "拾取赠牌需要1—10张卡牌。"
 for type in cards:
  if not type is String or not specs.has(type) or specs[type].get("card_type","")=="status": return "拾取赠牌需要有效的永久卡牌。"
 return ""
