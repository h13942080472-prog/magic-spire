extends RefCounted

const TYPES={"item":"道具","skill":"技能","magic":"魔法","power":"能力","curse":"诅咒","status":"状态"}
const REWARD_POOL_RELICS={"lewd_magic":"desire_cube_pro_max"}
const RARITIES={"basic":"基础","common":"普通","uncommon":"罕见","rare":"稀有","curse":"诅咒","status":"状态"}
const UPPER_BODY_SLOTS=["eyes","mouth","neck","shoulder","upper_arm","forearm","wrist","palm","fingers"]

# Mechanical card definitions. Display templates in balance.gd read these values.
const VULNERABLE_FACTOR=1.5
const VULNERABLE_DETAIL="受到的体术和挣扎伤害增加50%。回合结束时失去1层。"
const SLIPPERY_DETAIL="新佩戴的拘束具和特殊装备紧度降低1档，最低1档。回合开始时失去1层。"

static var BUFFS={
 "grace_free":{"name":"恩赐解脱·自由","duration":"turn","attacks":["strike","heavy","kick"],"physical_factor_per_x":0.5,"detail":"本回合下一次体术造成 X×0.5 倍伤害。"},
 "grace_bound":{"name":"恩赐解脱·拘束","duration":"battle","stack_uses":true,"extra_escape_hit":true,"detail":"接下来的挣扎或滑脱各追加一段伤害。"},
 "steady_chant":{"name":"沉稳咏唱","duration":"battle","stack_uses":true,"next_magic":"guarantee","detail":"本场下一张魔法牌必定施放成功。"},
 "instant_chant":{"name":"即刻咏唱","duration":"battle","stack_uses":true,"next_magic":"free","detail":"本场下一张魔法牌的能量与魔力费用均为0。"},
 "study_free":{"name":"钻研·自由","duration":"battle","stack_uses":true,"attributes":{"strength":-1,"dexterity":-1},"spell":"fireball","base_bonus":2,"detail":"力量－1，灵巧－1，火球术伤害＋2。"},
 "study_bound":{"name":"钻研·拘束","duration":"battle","stack_uses":true,"attributes":{"strength":2,"dexterity":2},"spell":"fireball","base_bonus":-4,"detail":"力量＋2，灵巧＋2，火球术伤害－4。"},
 "slippery":{"name":"滑溜","duration":"battle","stack_uses":true,"detail":SLIPPERY_DETAIL},
 "find_weakness_hand":{"name":"弱点发现·手部","duration":"battle","attacks":["strike","heavy"],"stack_uses":true,"hit_vulnerable":2,"detail":"下一次手部体术结束时，每层使目标获得2层脆弱。"},
 "find_weakness_leg":{"name":"弱点发现·腿部","duration":"battle","attacks":["heavy","kick"],"stack_uses":true,"hit_vulnerable":2,"detail":"下一次腿部体术结束时，每层使目标获得2层脆弱。"},
 "yield_force_free":{"name":"消力·自由","duration":"battle","stackable":true,"attributes":{"strength":-2},"turn_start_effects":[{"op":"slippery","amount":1}],"detail":"力量－2。回合开始时获得1层滑溜。"},
 "yield_force_bound":{"name":"消力·拘束","duration":"battle","attributes":{"strength":-2},"slip_multiplier":1.5,"detail":"力量－2。滑脱可作用于紧度3的装备，滑脱伤害×1.5。"},
 "spell_curse":{"name":"法术诅咒","duration":"battle","harmful":true,"duration_text":"战斗结束","detail":"每主动打出一张魔法牌，在抽牌堆随机加入一张「扰乱」。施法失败也会触发。"},
 "royal_attributes":{"name":"成王之礼","duration":"battle","stack_uses":true,"attributes":{"strength":1,"dexterity":1},"detail":"每层力量＋1、灵巧＋1。"},
 "witch_royal_attributes":{"name":"成王之礼","duration":"battle","stack_uses":true,"attributes":{"dexterity":1},"detail":"每层灵巧＋1。"},
 "disrupt_draw":{"name":"扰乱","duration":"turn","stack_uses":true,"harmful":true,"attributes":{"strength":-1,"dexterity":-1},"detail":"抽到「扰乱」时，本回合力量－1、灵巧－1。"},
 "enchantment_strengthen":{"name":"强化","duration":"turn","stack_uses":true,"attributes":{"strength":1,"dexterity":1},"detail":"本回合力量＋1、灵巧＋1。"},
 "enchantment_blessing":{"name":"祝福","duration":"battle","stack_uses":true,"attributes":{"strength":2,"dexterity":2},"detail":"力量＋2、灵巧＋2，持续到整备结束。"},
 "enchantment_assault":{"name":"猛攻","duration":"battle","attacks":["strike","heavy","kick"],"stack_uses":true,"hit_vulnerable":2,"detail":"下一次体术结算后，每层使目标获得2层脆弱。"},
 "enchantment_assist":{"name":"助力","duration":"turn","detail":"本回合变换姿势和室内移动免费。"},
 "binding_power_current":{"name":"拘束就是力量！","duration":"next_turn_start","stack_uses":true,"attributes":{"strength":1},"on_expire_buff":"binding_power_last","duration_text":"下回合结束","detail":"力量加成持续到你的下回合结束。"},
 "binding_power_last":{"name":"拘束就是力量！","duration":"turn","stack_uses":true,"attributes":{"strength":1},"detail":"力量加成持续到你的本回合结束。"},
 "psychological_suggestion":{"name":"心理暗示","duration":"battle","next_action_freedom":true,"stack_uses":true,"detail":"下一次出牌或基础动作无视拘束具的使用限制、施法倍率与威力削减；目标的锁与外层覆盖、姿势、快感、费用照常。"},
 "rally_spirit_next":{"name":"强打精神·下回合","duration":"next_turn_start","stack_uses":true,"on_expire_effects":[{"op":"pressure","amount":40}],"detail":"下回合开始时，获得40快感。"},
 "desire_rune_bound":{"name":"爱欲魔纹·拘束","duration":"battle","pressure_gained":{"step":30,"effects":[{"op":"charge","amount":1}]},"detail":"每实际获得30快感，获得1层蓄力。进度跨回合保留。"},
 "desire_rune_free":{"name":"爱欲魔纹·自由","duration":"battle","pressure_gained":{"step":40,"effects":[{"op":"draw","amount":1}]},"detail":"每实际获得40快感，抽1张牌。进度跨回合保留。"},
 "supple_flesh_bound":{"name":"活动媚肉·灵巧","duration":"turn","stack_uses":true,"attributes":{"dexterity":4},"detail":"本回合灵巧＋4。"},
 "supple_flesh_free":{"name":"活动媚肉·力量","duration":"turn","stack_uses":true,"attributes":{"strength":2},"detail":"本回合力量＋2。"},
 "mana_attachment_free":{"name":"魔力附着·自由","duration":"battle","toggleable":true,"physical_attachment":{"mana":10.0,"multiplier":0.5},"detail":"体术额外消耗10魔力，造成全体伤害，威力减半。魔力低于费用时按原招式发动。右键开关。"},
 "mana_attachment_bound":{"name":"魔力附着·拘束","duration":"battle","toggleable":true,"skill_charge":{"mana":5.0,"amount":1},"detail":"成功打出技能牌时，若有至少5魔力，额外消耗5魔力并获得1层蓄力。右键开关。"},
 "kip_up_free":{"name":"鲤鱼打挺","duration":"next_attack","attacks":["heavy","kick"],"ignore_posture":true,"detail":"下一次腿部体术无视姿势限制，按站姿招式发动，姿势保持原状；包括近身短打和各类踢击。持续至下一次完整攻击；捕缚强制姿势优先，击后躺下、拘束、费用、冷却及次数限制照常。"},
 "sympathetic_form_free":{"name":"交感形态·自由","duration":"battle","stackable":true,"turn_end_requirements":{"no_restraints":true,"include_special":false},"turn_end_effects":[{"op":"mana","amount":20},{"op":"pressure","amount":10},{"op":"buff","buff":"sympathetic_growth"}],"detail":"回合结束时，若未佩戴拘束具，恢复20魔力，获得10快感。本场战斗力量＋1、灵巧＋1、火球术伤害＋2。"},
 "sympathetic_growth":{"name":"交感强化","duration":"battle","stack_uses":true,"attributes":{"strength":1,"dexterity":1},"spell":"fireball","base_bonus":2,"detail":"每层力量＋1、灵巧＋1、火球术伤害＋2，持续至本场战斗结束。"},
 "sympathetic_form_bound":{"name":"交感形态·拘束","duration":"battle","stackable":true,"turn_start_effects":[{"op":"reserve_mana","amount":2},{"op":"energy","amount":1}],"detail":"回合开始时，获得2层魔力预备和1点能量。"},
 "endless_war_goddess":{"name":"无尽魔法少女战神","duration":"battle","attack":"all","ignore_restraints":true,"unrestricted_basics":true,"mana_per_turn":10,"detail":"效果持续期间，所有基础动作和火球术都无视拘束、快感与姿势限制。右键可切换所有踢击招式。使用动作仍需付费、等待冷却，并受每回合次数上限限制。"},
 "prepared_chant":{"name":"预备咏唱","duration":"turn","cast_minimum":1.0,"detail":"本回合施法成功率固定为100%。"},
 "prepared_chant_casts":{"name":"预备咏唱·拘束","duration":"battle","cast_minimum":1.0,"cast_uses":3,"detail":"接下来3次施法的成功率固定为100%。"},
 "prepared_chant_next":{"name":"预备咏唱·下回合","duration":"next_turn_start","on_expire_buff":"prepared_chant","detail":"下回合施法成功率固定为100%。"},
 "reuse_free":{"name":"魔路精通·自由","duration":"battle","reserve_payment_effects":[{"op":"draw","amount":1}],"failure_conversion":{"temporary_only":true,"refund":0.0,"energy":1,"zero_cost_limit":2},"exclusive_group":"reuse","detail":"耗魔全部由魔力预备抵扣时，抽1张牌。若施法失败，获得1能量，返还魔力为0。0费牌每回合最多以此获得2次能量。两面互斥。唯一。"},
 "reuse_bound":{"name":"魔路精通·拘束","duration":"battle","min_levels":{"arms":3,"legs":3},"failure_conversion":{"refund":1.0,"energy":1,"zero_cost_limit":2,"unlimited_worn":{"count":10,"min_tier":2,"include_special":false}},"exclusive_group":"reuse","detail":"若上身和腿部束缚等级均≥3，施法失败时返还100%耗魔并获得1点能量。0费牌每回合限2次。若你当前佩戴至少10件紧度≥2的拘束具，取消次数限制。两面互斥。唯一。"},
 "resonance_bound":{"name":"共鸣·拘束","duration":"battle","worn_mana_reduction":0.05,"detail":"你每佩戴1件拘束具或性玩具，施法消耗的魔力降低5%，最低为0。固定兑换和追加消耗仍按原价支付。"},
 "mana_arm_free":{"name":"魔力臂·自由","duration":"turn","stack_uses":true,"attack_charge":1,"detail":"每次体术攻击前，每层消耗5魔力并获得1层蓄力。"},
 "mana_arm_bound":{"name":"魔力臂·拘束","duration":"turn","attacks":["strike","heavy"],"detail":"每次体术消耗5魔力，手部体术无视拘束和姿势限制。"},
 "finesse_free":{"name":"巧劲·自由","duration":"battle","stackable":true,"charge_bonus":2,"detail":"每层蓄力的伤害加成＋2。"},
 "finesse_bound":{"name":"巧劲·拘束","duration":"battle","charge_switch":true,"detail":"可切换蓄力的消耗模式。"},
 "formation_free":{"name":"布阵·自由","duration":"battle","stackable":true,"max_degree_any":{"arms":1},"first_magic":{"energy_discount":1},"detail":"每回合第一张魔法牌能量费用－1，最低0。打出当回合立即获得次数，回合开始刷新。仅主动出牌消耗次数，包括0费牌与施法失败。"},
 "formation_bound":{"name":"布阵·拘束","duration":"battle","stackable":true,"max_degree_any":{"arms":1,"legs":1},"first_magic":{"cast_minimum":1.0},"detail":"每回合第一张魔法牌必定成功。打出当回合立即获得次数，回合开始刷新。仅主动出牌消耗次数，包括0费牌及直接生效的魔法牌；出牌与施法部位要求照常。"},
 "practiced_free":{"name":"熟练而已·熟手","duration":"battle","card_cast_bonus":0.08,"detail":"每成功打出另一张牌，本回合施法成功率额外＋8%。回合开始清零。唯一。"},
 "practiced_bound":{"name":"熟练而已·稳手","duration":"battle","cast_minimum":0.75,"magic_card_traction":1,"detail":"施法成功率最低75%；每次使用魔法牌，额外牵扯1次（按1能量），无论成败。唯一。"},
 "hannya_level_1":{"name":"般若汤","duration":"battle","hannya_level":1,"attributes":{"strength":1,"dexterity":1},"detail":"般若汤1级：力量＋1、灵巧＋1。各级奖励本场仅一次。"},
 "hannya_level_2":{"name":"般若汤","duration":"battle","hannya_level":2,"attributes":{"strength":2,"dexterity":2},"detail":"般若汤2级：力量＋2、灵巧＋2。各级奖励本场仅一次。"},
 "hannya_level_3":{"name":"般若汤","duration":"battle","hannya_level":3,"attributes":{"strength":3,"dexterity":3},"detail":"般若汤3级：力量＋3、灵巧＋3。各级奖励本场仅一次。"},
 "hannya_level_4":{"name":"般若汤","duration":"battle","hannya_level":4,"attributes":{"strength":4,"dexterity":4},"detail":"般若汤4级：力量＋4、灵巧＋4。各级奖励本场仅一次。"},
 "hannya_short_strike":{"name":"般若汤·短打","duration":"battle","hidden":true,"detail":"近身短打基础伤害＋2，连击每段基础伤害＋1。"},
 "hannya_justice":{"name":"般若汤·飞踢","duration":"battle","hidden":true,"detail":"正义飞踢费用＋1，获得打断，与坐姿踢击及并腿踢击共用3回合冷却。"},

 "magic_hand_free":{"name":"魔术手","duration":"battle","attacks":["strike","heavy"],"attack_uses":2,"stack_uses":true,"ignore_restraints":true,"detail":"接下来2次手部体术按自由态发动，忽略拘束限制与减益；包括肘击、近身短打及其连击。每次完整攻击消耗1次，姿势、费用与次数限制照常。每次使用增加2次，剩余次数可累计。"},
 "light_as_swallow_bound":{"name":"身轻如燕","duration":"battle","card_damage_type":"slip","damage_multiplier":2.0,"detail":"下一次卡牌滑脱伤害×2。"},
 "breath_control_free":{"name":"运气","duration":"next_attack","attacks":["strike","heavy","kick"],"energy_discount":1,"detail":"下一次体术费用－1，最低0。"},
 "restraint_embrace_free":{"name":"拘束之拥·自由","duration":"battle","stackable":true,"restraint_draw":{"event":"released","next_turn":false,"amount":1,"energy":1},"detail":"每挣脱1件拘束具，抽1张牌，恢复1能量。"},
 "restraint_embrace_bound":{"name":"拘束之拥·拘束","duration":"battle","stackable":true,"restraint_draw":{"event":"worn","next_turn":true,"amount":1},"detail":"每被佩戴1件拘束具，下回合抽1张牌。"},
 "infusion_free":{"name":"灌注·手部","duration":"next_attack","attacks":["strike","heavy"],"interrupt":true,"detail":"下一次手部体术附加1层打断，包括肘击和近身短打。与自带打断取较高值。"},
 "infusion_bound":{"name":"灌注·腿部","duration":"next_attack","attacks":["heavy","kick"],"interrupt":true,"detail":"下一次腿部体术附加1层打断，包括近身短打和各类踢击。与自带打断取较高值。"},
 "ready_to_strike_free":{"name":"蓄势待发","duration":"next_attack","attacks":["strike","heavy","kick"],"energy_discount":1,"detail":"下一次体术费用－1，最低0。"},
 "mana_circuit_free":{"name":"魔力回路·能量","duration":"battle","stackable":true,"mana_spent":{"step":30,"effects":[{"op":"energy","amount":1}]},"detail":"每累计消耗30魔力，恢复1能量。计入魔力预备抵扣的耗魔。"},
 "mana_circuit_bound":{"name":"魔力回路·蓄力","duration":"battle","stackable":true,"mana_spent":{"step":20,"effects":[{"op":"charge","amount":1}]},"detail":"每累计消耗20魔力，获得1层蓄力。计入魔力预备抵扣的耗魔。"},
 "echo_cast_bound":{"name":"余势复演·拘束","duration":"battle","stack_uses":true,"replay":{"kind":"card","distinct_faces":true},"detail":"下一张成功打出的双面效果各异的拘束面牌，每层额外释放一次。免费复放，只作用原目标，目标失效则跳过。"},
 "echo_cast_free":{"name":"余势复演·火球","duration":"battle","stack_uses":true,"replay":{"kind":"attack","spell":"fireball"},"detail":"下一次火球术每层免费额外施放一次，使用次数保留；只作用原目标，目标失效则跳过。每次施法各自判定成功率。"},
 "echo_firepower":{"name":"余势复演·拘束","duration":"battle","stack_uses":true,"spell":"fireball","base_bonus":5,"detail":"本场战斗，火球术伤害＋5。"},
 "echo_recharge":{"name":"余势复演·自由","duration":"turn","stack_uses":true,"recharge_on_magic":"fireball","detail":"本回合，每成功打出一张魔法牌，恢复1次火球术使用次数。"},
 "embers_free":{"name":"余火","duration":"turn","spell":"fireball","attack":"fireball","base_bonus":4.0,"detail":"本回合火球术基础伤害＋4。同源仅生效一次。"},
 "wildfire_descent":{"name":"猛火下山","duration":"battle","stackable":true,"spell":"fireball","spell_use_effects":[{"op":"draw","amount":1}],"detail":"本场每成功施放一次火球术，抽1张牌。"},
 "fire_dynamics_bound":{"name":"火动力学·稳燃","duration":"battle","stackable":true,"spell":"fireball","chance_bonus":0.30,"base_bonus":4,"detail":"火球术施法成功率＋30%，伤害＋4。"},
 "fire_dynamics_free":{"name":"火动力学·扩散","duration":"battle","spell":"fireball","all_enemies":true,"detail":"火球术对全体敌人造成伤害，每次施法只判定一次成功率。"},
 "flame_flourish_bound":{"name":"炫火·自解","duration":"battle","spell":"fireball","equipment_damage_factor":0.5,"detail":"火球术可对选中的最外层拘束具使用，造成当前火球术一半的魔法伤害。与对敌人施法共用次数。"},
 "flame_flourish_free":{"name":"炫火·连发","duration":"battle","stackable":true,"spell":"fireball","extra_uses":1,"detail":"每回合火球术可用次数＋1。"},
 "fire_mastery_bound":{"name":"火焰精通·无拘施法","duration":"battle","spell":"fireball","ignore_body":true,"disable_gesture":true,"detail":"火球术无视身体限制，手势加成为0。"},
 "fire_mastery_free":{"name":"火焰精通·烈焰","duration":"battle","attack":"fireball","damage_multiplier":2.0,"detail":"火球术伤害×2。"},
 "strong_elbow_free":{"name":"强力肘击","duration":"next_attack","attack":"strike","damage_multiplier":2.0,"detail":"下一次完整肘击伤害×2，多段形态的每一击均生效。"},
 "binding_enthusiast":{"name":"紧缚爱好","duration":"battle","stackable":true,"worn_attributes":{"strength":1,"dexterity":1},"bound_card_pressure":10,"detail":"你每佩戴1件拘束具或性玩具，力量和灵巧各增加1点。每成功打出1张其他牌的拘束面，固定获得10点快感。"},
 "henshin_free":{"name":"henshin","duration":"battle","attack":"all","damage_multiplier":2.0,"detail":"自身造成的全部伤害×2，同源仅生效一次；包括对拘束具与行动触发的被动伤害。"}}
const REWARD_RATES={"normal":{"rare":3,"uncommon":37},"elite":{"rare":10,"uncommon":40},"boss":{"rare":100,"uncommon":0}}
const RARE_OFFSET_INITIAL=-5
const RARE_OFFSET_MAX=40
const FOLLOW_THROUGH_REGIONS={"head":["eyes","mouth","neck"],"arms":["shoulder","upper_arm","forearm","wrist","palm","fingers"],"legs":["thigh","calf","ankle","foot","toes"]}
const FOLLOW_THROUGH_SLOTS=FOLLOW_THROUGH_REGIONS.head+FOLLOW_THROUGH_REGIONS.arms+FOLLOW_THROUGH_REGIONS.legs
const SUPER_FOLLOW_THROUGH_TEXT="先按顺延处理；区域内无合法目标后，按手腕→口部／手指→其他部位寻找全身合法目标，同级随机。没有合法目标时结束。"
const FOLLOW_THROUGH_TEXT="顺延：原件仍佩戴时继续攻击；解除后，剩余段数依次转向同一指定部位、同一大部位的其他部位、同一大片区域的最外层拘束具。同一级随机选择，仅在同区域内转移，无目标则结束。"
const MAGIC_HAND={"card_type":"magic","rarity":"uncommon","cost":1,"mana_cost":20.0,"mode":"lower","hits":3,"follow_through":true,"follow_through_scope":"body","target_slots":FOLLOW_THROUGH_SLOTS,"cast_free":true,"casting":{"parts":["mouth"],"multiplier":1.0},"free_effects":[{"op":"buff","buff":"magic_hand_free"}]}
const HANNYA_MANA_GAIN=5.0
const HANNYA_REWARDS={
 1:{"free":"近身短打基础伤害＋2，连击每段基础伤害＋1。般若汤-其二加入弃牌堆。","bound":"正义飞踢费用＋1，获得打断，与坐姿踢击及并腿踢击共用3回合冷却。般若汤-其二加入弃牌堆。","discard":"hannya_2"},
 2:{"free":"0费消耗／虚无的身轻如燕加入手牌；般若汤-其三加入弃牌堆。","bound":"0费消耗／虚无的身轻如燕加入手牌；般若汤-其三加入弃牌堆。","hand":"hannya_swallow","discard":"hannya_3"},
 3:{"free":"0费消耗／虚无的灌注加入手牌；般若汤-其四加入弃牌堆。","bound":"0费消耗／虚无的灌注加入手牌；般若汤-其四加入弃牌堆。","hand":"hannya_infusion","discard":"hannya_4"},
 4:{"free":"虚无的完美henshin加入手牌；好汤喝够饮饮饮饮加入弃牌堆。","bound":"虚无的完美henshin加入手牌；好汤喝够饮饮饮饮加入弃牌堆。","hand":"hannya_henshin","discard":"good_soup"}}

static var SPECS=_with_hannya({
 "itching_heart":{"card_type":"magic","reward_pool":"lewd_magic","rarity":"basic","cost":1,"mana_cost":0.0,"pressure_cost":10.0,"mode":"lower","casting":{"parts":["none"],"multiplier":1.0},"cast_free":true,"free_effects":[{"op":"self_toy","amount":1}]},
 "self_satisfaction":{"card_type":"skill","reward_pool":"lewd_magic","rarity":"common","cost":0,"mode":"self","self_faces":{"bound":{"mana_cost":10.0,"effects":[{"op":"pressure","amount":20}]},"free":{"energy_cost":1,"effects":[{"op":"pressure","amount":10},{"op":"charge","amount":2}]}}},
 "psychological_suggestion":{"card_type":"magic","reward_pool":"lewd_magic","rarity":"common","cost":0,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"energy_cost":1,"pressure_cost":20.0,"effects":[{"op":"buff","buff":"psychological_suggestion"}]},"free":{"cast":true,"pressure_cost":10.0,"effects":[{"op":"draw","amount":1},{"op":"charge","amount":1}]}}},
 "rally_spirit":{"card_type":"skill","reward_pool":"lewd_magic","rarity":"common","cost":1,"mode":"lower","bound_energy_discount":1,"hit_effects":[{"op":"pressure","amount":10}],"free_effects":[{"op":"pressure_loss","amount":20},{"op":"buff","buff":"rally_spirit_next"}]},
 "desire_rune":{"card_type":"power","reward_pool":"lewd_magic","rarity":"uncommon","cost":1,"mode":"power","self_faces":{"bound":{"pressure_cost":30.0,"buff":"desire_rune_bound"},"free":{"energy_cost":1,"pressure_cost":30.0,"buff":"desire_rune_free"}}},
 "forced_climax":{"card_type":"magic","reward_pool":"lewd_magic","rarity":"rare","cost":1,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"select_exhaust":3,"self_faces":{"bound":{"cast":true},"free":{"cast":true}}},
 "forced_edging":{"card_type":"magic","reward_pool":"lewd_magic","rarity":"rare","cost":0,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"pressure_cost":20.0,"effects":[{"op":"energy","amount":1}]},"free":{"cast":true,"energy_cost":1,"mana_cost":10.0,"effects":[{"op":"draw","amount":2},{"op":"pressure_loss","amount":20}]}}},
 "supple_flesh":{"card_type":"skill","rarity":"uncommon","cost":0,"mode":"self","self_faces":{"bound":{"buff":"supple_flesh_bound"},"free":{"buff":"supple_flesh_free"}}},
 "binding_power":{"card_type":"skill","rarity":"common","cost":1,"mode":"self","bound_modes":["self","self"],"self_faces":{"bound":{"worn_resource":{"resource":"strength","divisor":2,"buff":"binding_power_current"}},"free":{"worn_resource":{"resource":"charge","divisor":4}}}},
 "mana_attachment":{"card_type":"power","type_tags":["magic","power"],"rarity":"uncommon","cost":1,"mode":"power","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":10.0,"buff":"mana_attachment_bound","effects":[{"op":"charge","amount":1}]},"free":{"cast":true,"mana_cost":10.0,"buff":"mana_attachment_free","effects":[{"op":"charge","amount":1}]}}},
 "binding_search":{"card_type":"magic","type_tags":["magic","skill"],"rarity":"uncommon","cost":1,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":10.0,"body_draw_divisor":2},"free":{"cast":true,"mana_cost":10.0,"self_install":{"grade":2,"tier":2},"effects":[{"op":"draw","amount":3}]}}},
 "kip_up":{"card_type":"skill","rarity":"common","cost":1,"zero_cost_strength":4,"mode":"self","self_faces":{"bound":{"requires_posture":"lie","posture":"stand"},"free":{"buff":"kip_up_free"}}},
 "sympathetic_form":{"card_type":"power","rarity":"rare","cost":3,"mode":"power","self_faces":{"bound":{"buff":"sympathetic_form_bound"},"free":{"buff":"sympathetic_form_free"}}},
 "self_binding":{"card_type":"skill","rarity":"uncommon","cost":0,"x_cost":true,"mode":"self","self_binding":{"templates":["rope","cord","belt","fine_belt","tape","cable_tie"],"slots":FOLLOW_THROUGH_REGIONS.legs,"tighten_per_x":2,"mana_per_x":15},"self_faces":{"bound":{},"free":{}}},
 "prepared_chant":{"card_type":"magic","rarity":"common","cost":1,"mode":"self","casting":{"parts":["mouth"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":10.0,"buff":"prepared_chant_casts"},"free":{"cast":true,"mana_cost":10.0,"buff":"prepared_chant_next"}}},
 "reuse":{"card_type":"power","rarity":"rare","cost":1,"mode":"power","self_faces":{"free":{"buff":"reuse_free"},"bound":{"energy_cost":2,"buff":"reuse_bound"}}},
 "confluence":{"card_type":"skill","rarity":"common","cost":0,"mode":"self","self_faces":{"bound":{"worn_resource":{"resource":"turn_strength","divisor":2}},"free":{"exhaust":true,"worn_resource":{"resource":"mana","divisor":1,"amount":2}}}},
 "mana_arm":{"card_type":"skill","rarity":"common","cost":0,"mode":"self","self_faces":{"bound":{"buff":"mana_arm_bound"},"free":{"buff":"mana_arm_free"}}},
 "finesse":{"card_type":"power","rarity":"uncommon","cost":1,"mode":"power","self_faces":{"bound":{"buff":"finesse_bound"},"free":{"energy_cost":1,"buff":"finesse_free"}}},
 "resonance":{"card_type":"power","rarity":"uncommon","cost":1,"mode":"power","type_tags":["power","skill"],"self_faces":{"bound":{"card_type":"power","buff":"resonance_bound"},"free":{"card_type":"skill","energy_cost":1,"exhaust":true,"effects":[{"op":"evasion","amount":2}]}}},
 "formation":{"card_type":"power","rarity":"uncommon","cost":2,"mode":"power","self_faces":{"bound":{"buff":"formation_bound"},"free":{"buff":"formation_free"}}},
 "practiced":{"card_type":"power","rarity":"rare","cost":2,"mode":"power","self_faces":{"bound":{"buff":"practiced_bound"},"free":{"buff":"practiced_free"}}},
 "siphon_strength":{"card_type":"magic","rarity":"rare","cost":1,"mode":"self","casting":{"parts":["hand"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"exhaust_hand_batch":{"exclude_type":"magic","effects":[{"op":"charge","amount":1}]}},"free":{"cast":true,"exhaust_hand_batch":{"include_type":"magic","mana_gain":10.0}}}},
 "shared_fate":{"card_type":"skill","rarity":"rare","cost":0,"mode":"self","self_faces":{"bound":{"balance_mana_pressure":true},"free":{"balance_mana_pressure":true}}},
 "magic_hand":MAGIC_HAND.duplicate(true),
 "magic_hand_gift":MAGIC_HAND.merged({"reward_excluded":true,"encyclopedia_hidden":true}).duplicate(true),
 "leverage":{"card_type":"skill","rarity":"common","cost":1,"mode":"strain","damage_type":"strain","base":0.0,"worn_damage":{"per_item":2,"include_special":false},"free_max_levels":{"arms":0},"free_effects":[{"op":"evasion","amount":1},{"op":"charge","amount":1}]},
 "light_as_swallow":{"card_type":"skill","rarity":"rare","cost":1,"mode":"self","free_max_levels":{"legs":0},"self_faces":{"bound":{"buff":"light_as_swallow_bound"},"free":{"effects":[{"op":"evasion","amount":2}]}}},
 "breath_control":{"card_type":"skill","rarity":"common","cost":2,"mode":"slip","damage_type":"slip","base":8.0,"hits":2,"exhaust_hand":true,"free_slots":["mouth"],"free_effects":[{"op":"charge","amount":1},{"op":"buff","buff":"breath_control_free"}]},
 "restraint_embrace":{"card_type":"power","rarity":"uncommon","cost":1,"mode":"power","self_faces":{"bound":{"buff":"restraint_embrace_bound"},"free":{"energy_cost":1,"buff":"restraint_embrace_free"}}},
 "dual_chant":{"card_type":"magic","rarity":"basic","cost":1,"mode":"self","exhaust_uses":2,"face_titles":{"bound":"沉稳咏唱","free":"即刻咏唱"},"casting":{"parts":["mouth"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":10.0,"buff":"steady_chant"},"free":{"cast":true,"mana_cost":10.0,"buff":"instant_chant"}}},
 "study":{"card_type":"skill","rarity":"uncommon","battle_only":true,"cost":1,"mode":"self","self_faces":{"bound":{"buff":"study_bound"},"free":{"buff":"study_free"}}},
 "shockwave":{"card_type":"magic","rarity":"uncommon","cost":2,"mode":"self","casting":{"parts":["hand"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":10.0,"effects":[{"op":"vulnerable","targets":"enemies","amount":4},{"op":"vulnerable","targets":"equipment","amount":4}]},"free":{"cast":true,"mana_cost":10.0,"effects":[{"op":"vulnerable","targets":"enemies","amount":4},{"op":"slippery","amount":3}]}}},
 "find_weakness":{"card_type":"skill","rarity":"common","cost":0,"mode":"self","self_faces":{"bound":{"buff":"find_weakness_leg"},"free":{"buff":"find_weakness_hand"}}},
 "yield_force":{"card_type":"power","rarity":"uncommon","cost":2,"mode":"power","self_faces":{"bound":{"buff":"yield_force_bound"},"free":{"buff":"yield_force_free"}}},
 "infusion":{"card_type":"magic","rarity":"rare","cost":1,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"energy_cost":1,"mana_cost":10.0,"buff":"infusion_bound"},"free":{"cast":true,"mana_cost":20.0,"buff":"infusion_free"}}},
 "siphon":{"card_type":"magic","rarity":"uncommon","cost":0,"mode":"self","casting":{"parts":["mouth"],"multiplier":1.0},"free_max_levels":{"legs":0},"self_faces":{"bound":{"mana_gain":5.0},"free":{"cast":true,"energy_cost":1,"mana_gain":10.0,"effects":[{"op":"draw","amount":2}]}}},
 "concentration":{"card_type":"skill","rarity":"uncommon","cost":1,"mode":"strain","damage_type":"strain","base":6,"bound_modes":["strain","slip"],"damage_growth":3},
 "mana_circuit":{"card_type":"power","rarity":"rare","cost":2,"mode":"power","free_max_levels":{"arms":0,"legs":0},"self_faces":{"bound":{"buff":"mana_circuit_bound"},"free":{"buff":"mana_circuit_free"}}},
 "ready_to_strike":{"card_type":"magic","rarity":"common","cost":1,"mode":"self","casting":{"parts":["mouth"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":10.0,"exhaust_hand":true,"effects":[{"op":"charge","amount":3}]},"free":{"cast":true,"mana_cost":10.0,"exhaust_hand":true,"buff":"ready_to_strike_free"}}},
 "crossed_legs":{"card_type":"skill","rarity":"common","cost":1,"mode":"slip","damage_type":"slip","base":8.0,"target_slots":FOLLOW_THROUGH_REGIONS.legs,"hit_effects":[{"op":"draw","amount":1}],"free_effects":[{"op":"draw","amount":1}],"free_energy_discount":1,"free_max_levels":{"legs":1}},
 "but_also":{"card_type":"skill","rarity":"rare","reward_excluded":true,"cost":0,"mode":"self","self_faces":{"bound":{"effects":[{"op":"evasion","amount":1},{"op":"energy","amount":1}]},"free":{"effects":[{"op":"evasion","amount":1},{"op":"energy","amount":1}]}}},
 "forethought":{"card_type":"skill","rarity":"common","cost":1,"mode":"self","self_faces":{"bound":{"effects":[{"op":"charge","amount":1}],"to_hand_from":"discard"},"free":{"no_restraints":true,"effects":[{"op":"reserve_mana","amount":1}],"to_hand_from":"draw"}}},
 "mana_search":{"card_type":"skill","rarity":"common","cost":1,"mode":"self","free_max_levels":{"arms":0},"self_faces":{"bound":{"effects":[{"op":"draw","amount":1,"filter":{"tag":"magic"}}]},"free":{"effects":[{"op":"draw","amount":2,"filter":{"tag":"magic"}}]}}},
 "liberating_grace":{"card_type":"skill","rarity":"rare","cost":0,"x_cost":true,"mode":"self","self_faces":{"bound":{"buff":"grace_bound","buff_from_x":true},"free":{"buff":"grace_free","buff_from_x":true}}},
 "shining_debut":{"card_type":"skill","rarity":"rare","cost":0,"mode":"self","self_faces":{"bound":{"body_draw_divisor":1,"region_draw":true,"draw_bonus":1,"energy_gain":1},"free":{"mana_cost":20,"energy_gain":2,"effects":[{"op":"draw","amount":3}]}}},
 "last_resort":{"card_type":"skill","rarity":"uncommon","cost":0,"mode":"self","requires_empty_mana_and_unused_flask":true,"self_faces":{"bound":{"effects":[{"op":"charge","amount":3}]},"free":{"effects":[{"op":"draw","amount":3}]}}},
 "pot_of_greed":{"card_type":"skill","rarity":"uncommon","cost":0,"mode":"self","self_faces":{"bound":{"effects":[{"op":"draw","amount":2}]},"free":{"effects":[{"op":"draw","amount":2}]}}},
 "repeated_strain":{"card_type":"skill","rarity":"common","cost":1,"mode":"strain","damage_type":"strain","base":1.0,"hits":5,"follow_through":true,"target_slots":FOLLOW_THROUGH_SLOTS,"free_effects":[{"op":"charge","amount":2}]},
 "echo_cast":{"card_type":"skill","rarity":"uncommon","cost":1,"mode":"self","casting":{"parts":["mouth"],"multiplier":1.0},"self_faces":{"bound":{"buff":"echo_firepower","when_spell_empty":"fireball"},"free":{"cast":true,"buff":"echo_recharge"}}},
 "embers":{"card_type":"magic","rarity":"common","cost":0,"mode":"self","casting":{"parts":["hand"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":6.0,"requires_successful_spell":"fireball","effects":[{"op":"draw","amount":1}],"optional_draw":{"mana_cost":6.0,"count":1}},"free":{"cast":true,"mana_cost":6.0,"buff":"embers_free"}}},
 "endless_war_goddess":{"card_type":"magic","rarity":"rare","cost":2,"mode":"self","all_mana_minimum":0,"play_cue":"hero.endless_war_goddess","casting":{"parts":["mouth"],"multiplier":1.0},"self_faces":{"bound":{"buff":"endless_war_goddess","cast":true,"free_slots":["mouth"]},"free":{"buff":"endless_war_goddess","cast":true,"free_slots":["mouth"]}}},
 "wildfire_descent":{"card_type":"power","type_tags":["magic","power"],"rarity":"uncommon","cost":1,"mode":"power","casting":{"parts":["mouth"],"multiplier":1.0},"self_faces":{"bound":{"buff":"wildfire_descent","cast":true,"mana_cost":10.0},"free":{"buff":"wildfire_descent","cast":true,"mana_cost":10.0}}},
 "boar_emperor_blaze":{"card_type":"skill","rarity":"rare","cost":3,"mode":"strain","damage_type":"strain","base":6.0,"fireball_hits":true,"follow_through":true,"follow_through_scope":"body","target_slots":FOLLOW_THROUGH_SLOTS,"free_effects":[{"op":"charge","amount":"fireballs_succeeded"}]},
 "adaptability":{"card_type":"skill","rarity":"uncommon","cost":1,"mode":"self","self_faces":{"bound":{"convert_to":"charge"},"free":{"convert_to":"reserve_mana"}}},
 "rekindle":{"card_type":"magic","rarity":"common","cost":1,"mode":"self","exhaust_uses":2,"casting":{"parts":["hand"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":10.0,"refresh_spell":"fireball"},"free":{"cast":true,"mana_cost":10.0,"refresh_spell":"fireball"}}},
 "fire_dynamics":{"card_type":"power","rarity":"rare","cost":2,"bound_energy_discount":1,"mode":"power","self_faces":{"bound":{"buff":"fire_dynamics_bound"},"free":{"buff":"fire_dynamics_free"}}},
 "fire_control":{"card_type":"skill","rarity":"uncommon","cost":1,"mode":"self","free_max_levels":{"arms":1},"self_faces":{"bound":{"effects":[{"op":"reserve_mana","amount":2}]},"free":{"exhaust":true,"requires_hand":true,"spell_base_bonus":{"spell":"fireball","amount":1}}}},
 "mana_invocation":{"card_type":"magic","rarity":"common","cost":1,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_gain":20.0},"free":{"cast":true,"mana_gain":20.0}}},
 "strong_elbow":{"card_type":"skill","rarity":"common","cost":1,"mode":"strain","damage_type":"strain","base":8.0,"target_slots":["upper_arm","forearm"],"free_effects":[{"op":"buff","buff":"strong_elbow_free"}],"hit_effects":[{"op":"draw","amount":1}]},
 "pleasure_conversion":{"card_type":"skill","rarity":"rare","cost":0,"mode":"self","self_faces":{"bound":{"pressure_energy":20},"free":{"pressure_temporary_mana":10}}},
 "mana_conversion":{"card_type":"magic","rarity":"uncommon","cost":0,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"fixed_mana_cost":true,"self_faces":{"bound":{"cast":true,"mana_cost":20.0,"energy_gain":2},"free":{"cast":true,"energy_cost":1,"mana_gain":10.0}}},
 "mana_surge":{"card_type":"magic","rarity":"common","cost":0,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":5.0,"effects":[{"op":"charge","amount":2}]},"free":{"cast":true,"mana_cost":0.0,"effects":[{"op":"reserve_mana","amount":2}]}}},
 "henshin":{"play_music":"rain_love","card_type":"magic","rarity":"rare","cost":2,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"energy_cost":1,"mana_cost":40.0,"release_all":true},"free":{"cast":true,"energy_cost":2,"mana_cost":40.0,"buff":"henshin_free"}}},
 "flame_flourish":{"card_type":"power","rarity":"uncommon","cost":1,"mode":"power","self_faces":{"bound":{"buff":"flame_flourish_bound"},"free":{"buff":"flame_flourish_free"}}},
 "fire_mastery":{"card_type":"power","rarity":"rare","cost":2,"bound_energy_discount":1,"mode":"power","self_faces":{"bound":{"buff":"fire_mastery_bound"},"free":{"buff":"fire_mastery_free"}}},
 "binding_enthusiast":{"card_type":"power","rarity":"rare","cost":3,"mode":"power","self_faces":{"bound":{"buff":"binding_enthusiast"},"free":{"buff":"binding_enthusiast"}}},
 "strain":{"card_type":"skill","rarity":"basic","free_effects":[{"op":"charge","amount":1}],"cost":1,"mode":"strain","damage_type":"strain","base":6.0},
 "slip":{"card_type":"skill","rarity":"basic","free_effects":[{"op":"next_energy","amount":1}],"cost":1,"mode":"slip","damage_type":"slip","base":6.0},
 "brace":{"card_type":"skill","rarity":"common","free_effects":[{"op":"charge","amount":2}],"hit_effects":[{"op":"charge","amount":1}],"cost":1,"mode":"strain","damage_type":"strain","base":5.0},
 "inch":{"card_type":"skill","rarity":"common","free_effects":[{"op":"draw","amount":1},{"op":"slippery","amount":1}],"lowered_effects":[{"op":"draw","amount":1}],"cost":1,"bound_energy_discount":1,"mode":"slip","damage_type":"slip","base":5.0},
 "ease":{"card_type":"magic","rarity":"basic","lower_steps":2,"free_effects":[{"op":"reserve_mana","amount":2}],"cost":1,"mode":"lower","casting":{"parts":["mouth"],"multiplier":1.0}},
 "unlock":{"card_type":"magic","rarity":"uncommon","free_effects":[{"op":"reserve_mana","amount":2}],"cost":1,"bound_energy_discount":1,"mode":"unlock","casting":{"parts":["hand"],"multiplier":1.0}},
 "magic_slip":{"card_type":"magic","rarity":"basic","free_effects":[{"op":"reserve_mana","amount":1},{"op":"draw","amount":1}],"cost":0,"mode":"magic_slip","damage_type":"slip","base":5.0,"cast_free":true,"free_mana_cost":0.0,"casting":{"parts":["mouth"],"multiplier":1.0}},
 "focus":{"card_type":"skill","rarity":"uncommon","cost":1,"mode":"self","self_faces":{"bound":{"effects":[{"op":"charge","amount":1},{"op":"draw","amount":1}]},"free":{"effects":[{"op":"retain","amount":1,"draw_after":1}]}}},
 "tear":{"card_type":"skill","rarity":"uncommon","free_effects":[{"op":"charge","amount":1},{"op":"next_energy","amount":1}],"destroyed_effects":[{"op":"energy","amount":"refund"}],"cost":2,"mode":"strain","damage_type":"strain","base":9.0,"refund":1},
 "chain":{"card_type":"skill","rarity":"uncommon","free_effects":[{"op":"charge","amount":2},{"op":"draw","amount":2}],"cost":2,"mode":"strain","damage_type":"strain","base":4.0,"hits":3,"follow_through":true,"target_slots":FOLLOW_THROUGH_SLOTS},
 "peel":{"card_type":"skill","rarity":"uncommon","free_effects":[{"op":"slippery","amount":2},{"op":"retain","all":true}],"cost":2,"mode":"slip","damage_type":"slip","base":4.0,"hits":3,"follow_through":true,"target_slots":FOLLOW_THROUGH_SLOTS},
 "full_escape":{"card_type":"skill","rarity":"uncommon","cost":0,"x_cost":true,"mode":"strain","bound_modes":["strain","slip"],"base":4.0,"follow_through":true,"target_slots":FOLLOW_THROUGH_SLOTS,"sweep_slots":true},
 "double_unlock":{"reward_excluded":true,"encyclopedia_hidden":true,"card_type":"magic","rarity":"uncommon","free_effects":[{"op":"reserve_mana","amount":1}],"cost":1,"mode":"unlock","casting":{"parts":["hand","mouth"],"multiplier":1.0},"hits":2},
 "panic":{"card_type":"curse","rarity":"curse","cost":1,"mode":"none"},
 "sensitive":{"card_type":"curse","rarity":"curse","cost":0,"mode":"none","hand_modifiers":{"pleasure_multiplier":1.2}},
 "lewd_mark":{"card_type":"curse","rarity":"curse","cost":0,"mode":"none","hand_modifiers":{"energy_pressure":4.0}},
 "pocket_knife":{"card_type":"item","rarity":"basic","cost":0,"mode":"tool","reward_excluded":true,"wall_face":true,"wall_cost":1,"cut_tool":"shard","tool_damage":8,"enemy_max_degree":1},
 "art_submission":{"card_type":"status","rarity":"status","cost":0,"mode":"none","reward_excluded":true},
 "detective_provoke":{"card_type":"status","rarity":"status","cost":1,"mode":"none"},
 "disrupt":{"card_type":"status","rarity":"status","cost":0,"mode":"none"},
 "tease":{"card_type":"status","rarity":"status","cost":0,"mode":"none","end_turn_pressure":5.0},
 "tease_plus":{"card_type":"status","rarity":"status","cost":0,"mode":"none","end_turn_pressure":8.0}})
static func _with_hannya(specs: Dictionary) -> Dictionary:
 for stage in range(1,5):
  specs["hannya_%d" % stage]={"card_type":"skill","rarity":"rare","cost":1,"mode":"self","reward_excluded":true,"drinking":true,"hannya_stage":stage,"self_faces":{"bound":{},"free":{}}}
  specs["hannya_%d" % stage].encyclopedia_hidden=stage>1
 specs.hannya_2.play_music="mandarin_duck_play"
 specs.hannya_2.play_music_text="打出时自动播放鸳鸯戏。"
 var gift_effects=[{"op":"draw","amount":"gift_value"},{"op":"energy","amount":"gift_value"},{"op":"buff","buff":"royal_attributes","amount":"gift_value"},{"op":"charge","amount":"gift_value"},{"op":"reserve_mana","amount":"gift_value"}]
 specs.royal_gift={"card_type":"skill","rarity":"rare","cost":0,"mode":"self","reward_excluded":true,"gift_value":1,"self_faces":{"bound":{"effects":gift_effects},"free":{"effects":gift_effects.duplicate(true)}}}
 specs.good_soup={"card_type":"skill","rarity":"rare","cost":1,"mode":"self","reward_excluded":true,"drinking":true,"self_faces":{"bound":{"mana_gain":10.0},"free":{"mana_gain":10.0}}}
 specs.good_soup.encyclopedia_hidden=true
 for pair in [["hannya_swallow","light_as_swallow"],["hannya_infusion","infusion"],["hannya_henshin","henshin"]]:
  var variant=specs[pair[1]].duplicate(true)
  variant.cost=0;variant.reward_excluded=true;variant.art_source=pair[1];variant.encyclopedia_hidden=true
  for side in variant.self_faces: variant.self_faces[side].erase("energy_cost")
  if pair[0]=="hannya_infusion":
   variant.self_faces.bound.mana_cost=10.0;variant.self_faces.free.mana_cost=10.0
  if pair[0]=="hannya_henshin":
   variant.self_faces.bound.mana_cost=20.0;variant.self_faces.free.mana_cost=20.0
   variant.self_faces.free.energy_cost=2
  specs[pair[0]]=variant
 return specs

static var FIXED_MAGIC={"fireball":{"parts":["mouth"],"multiplier":1.0}}
static var CAST_PART_NAMES={"mouth":"嘴部","hand":"手部","none":"无"}

static func cast_profile(type: String) -> Dictionary:
 return SPECS[type].get("casting",{}) if SPECS.has(type) else FIXED_MAGIC.get(type,{})

static func face_casts(type: String, free: bool) -> bool:
 var spec=SPECS[type]
 if spec.has("self_faces"): return spec.self_faces["free" if free else "bound"].get("cast",false)
 return spec.has("casting") and (not free or spec.get("cast_free",false))

static func body_draw_amount(face: Dictionary, count: int) -> int:
 return floori(float(count)/face.body_draw_divisor)+int(face.get("draw_bonus",0))

static func face_mana_base(type: String, free: bool, spell_cost: float) -> float:
 var spec=SPECS[type]
 if spec.has("self_faces"): return float(spec.self_faces["free" if free else "bound"].get("mana_cost",0))
 if free and spec.has("free_mana_cost"): return float(spec.free_mana_cost)
 return float(spec.get("mana_cost",spell_cost)) if face_casts(type,free) else 0.0

static func lewd_magic(type: String) -> bool:
 return SPECS.has(type) and SPECS[type].get("reward_pool","")=="lewd_magic" and "magic" in type_tags(type)

static func face_pressure_cost(type: String, free: bool) -> float:
 var spec=SPECS.get(type,{})
 if spec.has("self_faces"): return float(spec.self_faces["free" if free else "bound"].get("pressure_cost",0))
 return float(spec.get("free_pressure_cost" if free else "pressure_cost",0))

const COMMON=["find_weakness","mana_arm","self_satisfaction","psychological_suggestion","rally_spirit","binding_power","kip_up","prepared_chant","confluence","leverage","breath_control","ready_to_strike","crossed_legs","forethought","mana_search","repeated_strain","embers","brace","inch","strong_elbow","mana_surge","mana_invocation","rekindle"]
const UNCOMMON=["study","shockwave","yield_force","finesse","siphon","desire_rune","supple_flesh","mana_attachment","binding_search","self_binding","resonance","formation","magic_hand","flame_flourish","wildfire_descent","restraint_embrace","last_resort","pot_of_greed","concentration","focus","tear","chain","peel","full_escape","unlock","mana_conversion","adaptability","echo_cast","fire_control"]
const RARE=["shining_debut","reuse","forced_climax","forced_edging","sympathetic_form","shared_fate","siphon_strength","practiced","light_as_swallow","infusion","mana_circuit","boar_emperor_blaze","fire_mastery","binding_enthusiast","pleasure_conversion","henshin","fire_dynamics","endless_war_goddess","liberating_grace"]
const REWARDS=COMMON+UNCOMMON+RARE

static func power_face(spec: Dictionary, face: Dictionary) -> bool:
 return spec.mode=="power" and face.get("card_type","power")=="power"

static func unique_face(type: String, free: bool) -> bool:
 var spec=SPECS[type]
 var face=spec.get("self_faces",{}).get("free" if free else "bound",{})
 var ids=[]
 if face.has("buff"): ids.append(face.buff)
 for effect in face.get("effects",[])+spec.get("free_effects" if free else "hit_effects",[]):
  if effect.op=="buff": ids.append(effect.buff)
 return ids.any(func(id):return not BUFFS[id].get("stackable",false) and not BUFFS[id].get("stack_uses",false))

static func follow_through_region(slot: String) -> String:
 for region in FOLLOW_THROUGH_REGIONS:
  if slot in FOLLOW_THROUGH_REGIONS[region]: return region
 return ""

static func remove_label(remaining: int) -> String:
 return "移除"+(str(remaining) if remaining>1 else "")

static func single_face(type: String) -> bool:
 return SPECS[type].mode=="none" or (SPECS[type].card_type=="item" and not SPECS[type].wall_face)

static func hand_source(type: String, free: bool) -> String:
 return SPECS[type].get("self_faces",{}).get("free" if free else "bound",{}).get("to_hand_from","")

static func matches_draw_filter(type: String, filter: Dictionary) -> bool:
 return not filter.has("tag") or filter.tag in type_tags(type)

static func type_tags(type: String, free: Variant=null) -> Array:
 if free!=null:
  var face=SPECS[type].get("self_faces",{}).get("free" if free else "bound",{})
  if face.has("card_type"): return [face.card_type]
 return SPECS[type].get("type_tags",[SPECS[type].card_type]).duplicate()

static func draw_label(filter: Dictionary) -> String:
 if filter.get("tag","")=="magic": return "魔力牌"
 return TYPES[filter.tag]+"牌" if filter.has("tag") else "牌"

static func exhausts(type: String, free: bool, traits: Dictionary) -> bool:
 return SPECS[type].has("exhaust_uses") or traits.get("exhaust",false) or SPECS[type].get("self_faces",{}).get("free" if free else "bound",{}).get("exhaust",false)

static func exhaust_label(remaining: int) -> String:
 return "消耗%d" % remaining if remaining>1 else "消耗"

static func native_exhaust_remaining(type: String, card: Dictionary={}) -> int:
 return maxi(1,int(SPECS[type].get("exhaust_uses",1))-int(card.get("exhaust_spent",0)))

static func energy_cost(type: String, free: bool=false) -> int:
 var spec=SPECS[type]
 var side="free" if free else "bound"
 if free and spec.has("wall_cost"): return spec.wall_cost
 var extra=int(spec.get("self_faces",{}).get(side,{}).get("energy_cost",0))
 return maxi(0,spec.cost+extra-int(spec.get(side+"_energy_discount",0)))

static func energy_label(type: String) -> String:
 return "X" if SPECS[type].get("x_cost",false) else str(SPECS[type].cost)

static func distinct_faces(type: String) -> bool:
 var spec=SPECS[type]
 if spec.has("self_binding"): return true
 if spec.has("hannya_stage"): return spec.hannya_stage==1
 if single_face(type): return false
 if not spec.has("self_faces"): return true
 var faces=spec.self_faces.duplicate(true)
 for face in faces.values():
  if face.has("buff"):
   face.buff=BUFFS[face.buff].duplicate(true)
   face.buff.erase("name");face.buff.erase("detail")
 return faces.bound!=faces.free

static func classification(type: String) -> Dictionary:
 var spec=SPECS[type]
 return {"card_type":spec.card_type,"type_tags":type_tags(type),"rarity":spec.rarity,"type_name":"／".join(type_tags(type).map(func(tag):return TYPES[tag])),"rarity_name":"初始" if spec.get("starting_card",false) else RARITIES[spec.rarity]}

static func damage(type: String) -> bool:
 return damage_type(type)!=""

static func free_effect(type: String, second: bool) -> bool:
 return second and not SPECS[type].get("wall_face",false) and not SPECS[type].has("bound_modes")

static func face_mode(type: String, second: bool=false) -> String:
 var spec=SPECS[type]
 if spec.mode=="power" and not power_face(spec,spec.self_faces["free" if second else "bound"]): return "self"
 return SPECS[type].bound_modes[1 if second else 0] if SPECS[type].has("bound_modes") else SPECS[type].mode

static func face_name(type: String, second: bool=false) -> String:
 if SPECS[type].card_type=="item": return ("借墙" if second else "手持") if SPECS[type].wall_face else "道具"
 return ("拘束2" if second else "拘束1") if SPECS[type].has("bound_modes") else ("自由" if second else "拘束")

static func damage_type(type: String, second: bool=false) -> String:
 if SPECS[type].has("bound_modes") and SPECS[type].mode!="self": return face_mode(type,second)
 return SPECS[type].get("damage_type","")

const EFFECT_GROUPS=["free_effects","hit_effects","lowered_effects","destroyed_effects"]
const MANA_ARM_COST=5
const RESERVE_MANA_VALUE=5
const EFFECT_OPS=["vulnerable","slippery","mind_preparation","evasion","buff","charge","next_energy","reserve_mana","energy","mana","pressure","pressure_loss","self_toy","draw","retain","witch_focus"]

static func amount(effect: Dictionary, spec: Dictionary) -> int:
 var value=effect.get("amount",0)
 return int(spec.get(value,0) if value is String else value)

static func worn_gain(face: Dictionary, count: int) -> int:
 return int(count/int(face.worn_resource.divisor))*int(face.worn_resource.get("amount",1)) if face.has("worn_resource") else 0

static func hand_batch_matches(type: String, batch: Dictionary) -> bool:
 return batch.include_type in type_tags(type) if batch.has("include_type") else batch.exclude_type not in type_tags(type)

static func hand_batch_type_text(batch: Dictionary) -> String:
 return TYPES[batch.include_type] if batch.has("include_type") else "非"+TYPES[batch.exclude_type]

static func definition_reason(spec: Dictionary) -> String:
 if spec.has("exhaust_uses") and (not spec.exhaust_uses is int or spec.exhaust_uses<2): return "多次消耗的次数至少为2。"
 if spec.has("all_mana_minimum") and (not (spec.all_mana_minimum is int or spec.all_mana_minimum is float) or not is_finite(float(spec.all_mana_minimum)) or spec.all_mana_minimum<0 or not spec.has("casting")): return "耗尽魔力需要非负门槛和施法配置。"
 if spec.has("self_binding"):
  var rule=spec.self_binding
  if not spec.get("x_cost",false) or spec.mode!="self" or not rule is Dictionary: return "自缚需要X费自身技能配置。"
  if rule.get("tighten_per_x")!=2 or rule.get("mana_per_x")!=15 or rule.get("slots")!=FOLLOW_THROUGH_REGIONS.legs or rule.get("templates")!=["rope","cord","belt","fine_belt","tape","cable_tie"]: return "自缚的收紧、回魔或腿部装备配置有误。"
 if spec.has("sweep_slots") and (spec.sweep_slots!=true or spec.get("x_cost",false)!=true or spec.get("follow_through",false)!=true or spec.get("bound_modes")!=["strain","slip"] or spec.mode!="strain" or spec.get("target_slots")!=FOLLOW_THROUGH_SLOTS or spec.get("follow_through_scope","region")!="region" or spec.has("hits")): return "多部位挣脱需要X费双拘束面和同区域顺延。"
 if spec.has("x_cost") and (spec.x_cost!=true or spec.cost!=0 or (spec.mode!="self" and not spec.get("sweep_slots",false))): return "X费卡需要零占位费用及自身或多部位挣脱效果。"
 if spec.has("reward_excluded") and not spec.reward_excluded is bool: return "卡牌随机奖励资格需要布尔配置。"
 if spec.has("encyclopedia_hidden") and not spec.encyclopedia_hidden is bool: return "卡牌图鉴展示设置需要布尔配置。"
 if spec.has("cast_free") and (not spec.cast_free is bool or not spec.has("casting") or spec.has("self_faces")): return "自由面施法需要有效施法配置。"
 if spec.has("free_mana_cost") and (not (spec.free_mana_cost is int or spec.free_mana_cost is float) or not is_finite(float(spec.free_mana_cost)) or spec.free_mana_cost<0 or not spec.get("cast_free",false)): return "自由面魔力费用需要有效施法配置和非负数值。"
 if spec.has("mana_cost") and (not (spec.mana_cost is int or spec.mana_cost is float) or not is_finite(float(spec.mana_cost)) or spec.mana_cost<0 or not spec.has("casting") or spec.has("self_faces")): return "卡牌魔力费用有误。"
 if spec.has("worn_damage"):
  var scaling=spec.worn_damage
  if not scaling is Dictionary or not scaling.get("per_item") is int or scaling.per_item<=0 or not scaling.get("include_special") is bool or spec.get("damage_type","")=="": return "佩戴数量伤害需要正整数倍率、特殊装备计数规则和伤害类型。"
 if spec.has("exhaust_hand") and (not spec.exhaust_hand is bool or spec.mode not in ["strain","slip","magic_slip"]): return "目标卡牌的手牌消耗需要布尔配置。"
 if spec.has("free_slots") and (not spec.free_slots is Array or spec.free_slots.is_empty() or spec.free_slots.any(func(slot):return slot not in UPPER_BODY_SLOTS+FOLLOW_THROUGH_REGIONS.legs)): return "卡牌自由部位条件有误。"
 if spec.has("bound_modes"):
  var self_modes=spec.mode=="self" and spec.bound_modes==["self","self"]
  if not self_modes and (not spec.bound_modes is Array or spec.bound_modes.size()!=2 or spec.bound_modes.any(func(mode):return mode not in ["strain","slip"]) or spec.has("self_faces")) or spec.has("casting"): return "双拘束面需要两种挣扎、滑脱或成对自身效果。"
 if spec.has("damage_growth") and (not spec.damage_growth is int or spec.damage_growth<=0 or spec.get("damage_type","")==""): return "卡牌成长需要正整数增量和伤害效果。"
 if spec.get("card_type","") not in TYPES or spec.get("rarity","") not in RARITIES: return "卡牌缺少有效的类型或稀有度。"
 if spec.has("drinking") and (spec.drinking!=true or spec.mode!="self" or spec.card_type!="skill" or spec.has("casting")): return "饮用牌必须是无施法的自身技能牌。"
 if spec.has("hannya_stage") and (not spec.hannya_stage is int or spec.hannya_stage not in HANNYA_REWARDS or not spec.get("drinking",false)): return "般若汤阶段或饮用配置有误。"
 var tags=spec.get("type_tags",[spec.card_type])
 if not tags is Array or spec.card_type not in tags or tags.any(func(tag):return tag not in TYPES or tags.count(tag)!=1): return "卡牌类型词条有误。"
 if spec.has("casting") and "magic" not in tags:
  var faces=spec.get("self_faces",{})
  if spec.card_type!="skill" or not faces is Dictionary or not faces.values().any(func(face):return face is Dictionary and face.get("cast")==true): return "施法需要魔法词条或明确施法的技能牌面。"
 if (spec.card_type=="curse")!=(spec.rarity=="curse"): return "诅咒牌需要独立的诅咒分类。"
 if (spec.card_type=="status")!=(spec.rarity=="status"): return "状态牌需要独立的状态分类。"
 if (spec.card_type=="power")!=(spec.mode=="power"): return "能力牌需要能力出牌方式。"
 if spec.mode in ["self","power"]:
  var faces=spec.get("self_faces",{})
  if not faces is Dictionary or faces.size()!=2: return "自身卡牌的双面效果缺损。"
  for side in ["bound","free"]:
   if not faces.get(side) is Dictionary: return "卡牌缺少对应牌面。"
   var face=faces[side]
   if spec.mode=="power" and face.get("card_type","power") not in ["power","skill"]: return "卡牌类型词条有误。"
   if power_face(spec,face) and (not face.has("buff") or face.keys().any(func(key):return key not in ["buff","cast","mana_cost","pressure_cost","energy_cost","free_slots","effects","card_type"])): return "能力牌的每个牌面需要一个持续增益及可选的施法费用。"
   if face.has("convert_to") and (spec.mode!="self" or face.convert_to not in ["charge","reserve_mana"]): return "层数转换需要蓄力或魔力预备作为目标。"
   if face.has("exhaust") and (not face.exhaust is bool or power_face(spec,face)): return "牌面消耗需要技能或魔法自身效果的布尔配置。"
   if face.has("cast") and (not face.cast is bool or (face.cast and spec.get("casting",{}).get("parts",[]).is_empty())): return "施法牌面需要有效的施法条件。"
   if face.has("buff") and face.buff not in BUFFS: return "卡牌增益没有登记。"
   if face.has("buff_from_x") and (face.buff_from_x!=true or not spec.get("x_cost",false) or not face.has("buff")): return "X费卡需要零占位费用及自身或多部位挣脱效果。"
   if face.has("exhaust_hand") and (not face.exhaust_hand is bool or spec.mode!="self"): return "指定消耗手牌需要自身牌面的布尔配置。"
   if face.has("to_hand_from") and (spec.mode!="self" or face.to_hand_from not in ["draw","discard"]): return "选牌来源需要抽牌堆或弃牌堆。"
   if face.has("no_restraints") and not face.no_restraints is bool: return "拘束条件需要布尔值。"
   if face.has("refresh_spell") and face.refresh_spell not in FIXED_MAGIC: return "刷新次数需要已登记的法术。"
   if face.has("when_spell_empty") and (not face.has("buff") or face.when_spell_empty not in FIXED_MAGIC): return "法术次数条件需要已登记的法术和增益。"
   if face.has("requires_successful_spell") and face.requires_successful_spell not in FIXED_MAGIC: return "施法前置需要已登记的法术。"
   if face.has("requires_hand") and not face.requires_hand is bool: return "手部使用条件必须为布尔值。"
   if face.has("exhaust_hand_batch"):
    var batch=face.exhaust_hand_batch
    if spec.mode!="self" or face.get("exhaust_hand",false) or not batch is Dictionary: return "批量消耗手牌需要自身牌面的效果配置。"
    if batch.has("include_type")==batch.has("exclude_type") or batch.get("include_type",batch.get("exclude_type","")) not in TYPES: return "批量消耗手牌需要一个有效的包含或排除类型。"
    if batch.keys().any(func(key):return key not in ["include_type","exclude_type","mana_gain","effects"]): return "批量消耗手牌包含待支持效果。"
    if batch.has("mana_gain") and (not (batch.mana_gain is int or batch.mana_gain is float) or not is_finite(float(batch.mana_gain)) or batch.mana_gain<=0): return "每张手牌恢复魔力必须为正数。"
   if face.has("balance_mana_pressure") and (not face.balance_mana_pressure is bool or spec.mode!="self"): return "资源均分需要自身牌面的布尔配置。"
   if face.has("optional_draw"):
    var extra=face.optional_draw
    if not extra is Dictionary or not (extra.get("mana_cost") is float or extra.get("mana_cost") is int) or not is_finite(float(extra.mana_cost)) or extra.mana_cost<=0 or not extra.get("count") is int or extra.count<1 or extra.count>10: return "追加抽牌需要正数魔力费用及1—10张牌。"
   if face.has("spell_base_bonus"):
    var bonus=face.spell_base_bonus
    if not bonus is Dictionary or bonus.get("spell","") not in FIXED_MAGIC or not bonus.get("amount") is int or bonus.amount<1 or bonus.amount>100: return "永久法术加伤需要已登记的法术及1—100整数。"
   if face.has("worn_resource"):
    var gain=face.worn_resource
    if spec.mode!="self" or not gain is Dictionary or gain.keys().any(func(key):return key not in ["resource","divisor","amount","buff"]) or gain.get("resource","") not in ["mana","turn_strength","charge","strength"] or not gain.get("divisor") is int or gain.divisor<1 or not gain.get("amount",1) is int or gain.get("amount",1)<1: return "佩戴件数收益需要合法资源、正整数除数与收益。"
    if gain.resource=="strength" and (not BUFFS.has(gain.get("buff","")) or not BUFFS[gain.buff].get("stack_uses",false) or BUFFS[gain.buff].get("attributes",{}).get("strength",0)!=1): return "力量收益需要可叠加的每层1点力量增益。"
   for key in ["mana_cost","pressure_cost","mana_gain","energy_cost","energy_gain","pressure_energy","pressure_temporary_mana"]:
    if face.has(key) and (not (face[key] is int or face[key] is float) or not is_finite(float(face[key])) or face[key]<0): return "卡牌资源数值有误。"
   if face.has("pressure_energy") and face.pressure_energy<=0: return "能量转换需要正数快感间隔。"
   if face.has("pressure_temporary_mana") and face.pressure_temporary_mana<=0: return "临时魔力转换需要正数快感间隔。"
   if face.has("free_slots"):
    if not face.free_slots is Array or face.free_slots.is_empty() or face.free_slots.any(func(slot):return slot not in ["eyes","mouth","neck","shoulder","upper_arm","forearm","wrist","palm","fingers","thigh","calf","ankle","foot","toes"]): return "卡牌自由部位条件有误。"
 if spec.has("lower_steps") and (spec.mode!="lower" or not spec.lower_steps is int or spec.lower_steps not in [1,2,3]): return "每次降紧的档数须为1至3。"
 if spec.has("free_energy_discount") and (not spec.free_energy_discount is int or spec.free_energy_discount<0): return "自由面减费必须是非负整数。"
 if spec.has("free_max_levels"):
  var limits=spec.free_max_levels
  if not limits is Dictionary or limits.is_empty() or limits.keys().any(func(region):return region not in ["arms","legs"] or not limits[region] is int or limits[region]<0 or limits[region]>4): return "自由面需要有效的身体区域束缚等级上限。"
 if not spec.get("hits",1) is int or spec.get("hits",1)<1: return "卡牌段数必须是正整数。"
 if spec.has("fireball_hits") and (spec.fireball_hits!=true or spec.has("hits") or spec.mode!="strain" or not spec.get("follow_through",false)): return "火球术决定段数时，需要使用顺延挣扎。"
 if spec.has("follow_through"):
  if not spec.follow_through is bool or spec.mode not in ["strain","slip","lower"] or (spec.get("hits",1)<2 and not spec.get("sweep_slots",false) and not spec.get("fireball_hits",false)) or not spec.has("target_slots") or spec.target_slots.any(func(slot):return slot not in FOLLOW_THROUGH_SLOTS): return "顺延需要多段挣扎／滑脱／降紧及已划分区域的目标部位。"
 if spec.has("follow_through_scope") and (not spec.get("follow_through",false) or spec.follow_through_scope not in ["region","body"]): return "顺延范围必须为同区域或全身。"
 var effect_groups=EFFECT_GROUPS.map(func(group):return spec.get(group,[]))
 if spec.mode in ["self","power"]:
  for face in spec.self_faces.values():
   effect_groups.append(face.get("effects",[]))
   effect_groups.append(face.get("exhaust_hand_batch",{}).get("effects",[]))
   if face.has("buff"):
    var buff=BUFFS[face.buff]
    effect_groups.append(buff.get("reserve_payment_effects",[]))
    if buff.has("exclusive_group") and (spec.mode!="power" or not buff.exclusive_group is String or buff.exclusive_group==""): return "互斥能力需要有效的互斥组。"
    if buff.has("failure_conversion"):
     var conversion=buff.failure_conversion
     if spec.mode!="power" or not conversion is Dictionary or conversion.get("refund",-1.0) not in [0.0,1.0] or conversion.get("energy")!=1 or conversion.get("zero_cost_limit")!=2: return "失败转换的返还、能量或次数配置有误。"
     if conversion.has("temporary_only") and not conversion.temporary_only is bool: return "临时魔力付款条件需要布尔配置。"
    if buff.has("recharge_on_magic") and buff.recharge_on_magic not in FIXED_MAGIC: return "回充需要已登记的法术。"
    if buff.has("stack_uses") and (not buff.stack_uses is bool or not (buff.has("attack_uses") or buff.has("replay") or buff.has("next_action_freedom") or buff.has("on_expire_effects") or buff.get("extra_escape_hit",false) or buff.has("base_bonus") or buff.has("attack_charge") or buff.has("hit_vulnerable") or buff.has("next_magic") or buff.has("recharge_on_magic") or (buff.duration=="turn" and buff.has("attributes")))): return "累计次数需要可叠加的效果。"
    if buff.has("stackable") and (not buff.stackable is bool or spec.mode!="power"): return "能力叠加需要布尔配置。"
    for key in ["card_cast_bonus","cast_minimum"]:
     if buff.has(key) and ((key=="card_cast_bonus" and spec.mode!="power") or not (buff[key] is int or buff[key] is float) or not is_finite(float(buff[key])) or buff[key]<=0 or buff[key]>1): return "施法能力需要0至1之间的正数。"
    if buff.has("magic_card_traction") and (spec.mode!="power" or not buff.magic_card_traction is int or buff.magic_card_traction!=1): return "魔法牌额外牵扯按1能量触发。"
    if buff.has("worn_mana_reduction") and (spec.mode!="power" or not (buff.worn_mana_reduction is float or buff.worn_mana_reduction is int) or not is_finite(float(buff.worn_mana_reduction)) or buff.worn_mana_reduction<=0 or buff.worn_mana_reduction>1): return "每件拘束的耗魔减免需要0至1之间的正数。"
    if buff.has("worn_attributes"):
     var attributes=buff.worn_attributes
     if spec.mode!="power" or not attributes is Dictionary or attributes.is_empty() or attributes.keys().any(func(key):return key not in ["strength","dexterity"] or not attributes[key] is int or attributes[key]<=0 or attributes[key]>100): return "动态装备属性需要有效的力量或灵巧整数加值。"
    if buff.has("bound_card_pressure") and (spec.mode!="power" or not buff.bound_card_pressure is int or buff.bound_card_pressure<=0 or buff.bound_card_pressure>100): return "拘束面快感触发需要1—100的固定整数。"
    for meter_key in ["mana_spent","pressure_gained"]:
     if not buff.has(meter_key): continue
     var meter=buff[meter_key]
     if spec.mode!="power" or not meter is Dictionary or not meter.get("step") is int or meter.step<=0 or not meter.get("effects") is Array or meter.effects.is_empty(): return "耗魔触发需要正整数阈值和效果列表。"
     effect_groups.append(meter.effects)
    if buff.has("restraint_draw"):
     var trigger=buff.restraint_draw
     if spec.mode!="power" or not trigger is Dictionary or trigger.get("event","") not in ["worn","released"] or not trigger.get("next_turn") is bool or not trigger.get("amount") is int or trigger.amount<1: return "装备触发抽牌需要有效时机和正整数张数。"
     if trigger.has("energy") and (trigger.event!="released" or trigger.next_turn or not trigger.energy is int or trigger.energy<1): return "挣脱回能需要即时触发的正整数能量。"
    if buff.has("replay"):
     var replay=buff.replay
     if not replay is Dictionary or replay.get("kind","") not in ["card","attack"] or (replay.kind=="card" and replay.get("distinct_faces")!=true) or (replay.kind=="attack" and replay.get("spell","") not in FIXED_MAGIC): return "复放增益需要有效的卡牌或法术条件。"
    effect_groups.append(buff.get("turn_start_effects",[]))
    effect_groups.append(buff.get("turn_end_effects",[]))
    effect_groups.append(buff.get("spell_use_effects",[]))
    if buff.has("spell_use_effects") and buff.get("spell","") not in FIXED_MAGIC: return "法术使用触发需要已登记的法术。"
 for effects in effect_groups:
  if not effects is Array: return "卡牌附加效果必须是列表。"
  for effect in effects:
   if not effect is Dictionary or effect.get("op","") not in EFFECT_OPS: return "卡牌附加效果类型有误。"
   if effect.op=="vulnerable" and effect.get("targets","") not in ["enemies","equipment"]: return "脆弱需要指定敌人或装备。"
   if effect.op in ["vulnerable","slippery"] and (not effect.get("amount") is int or effect.amount<1): return "状态层数必须是正整数。"
   if effect.op=="buff" and effect.get("buff","") not in BUFFS: return "卡牌增益没有登记。"
   if effect.has("filter"):
    var filter=effect.filter
    if effect.op!="draw" or not filter is Dictionary or filter.size()!=1 or filter.get("tag","") not in TYPES: return "定向抽牌条件有误。"
   var value=effect.get("amount",0)
   if value is String: value=0 if value=="fireballs_succeeded" and effect.op=="charge" else spec.get(value,null)
   if effect.has("all") and (effect.op!="retain" or effect.all!=true or effect.has("amount")): return "全部保留模式需要省略选牌数量。"
   if not value is int or value<0 or (effect.op=="retain" and value==0 and not effect.get("all",false)): return "卡牌附加效果数量有误。"
   if not effect.get("draw_after",0) is int or effect.get("draw_after",0)<0: return "保留后的抽牌数有误。"
 var modifiers=spec.get("hand_modifiers",{})
 if not modifiers is Dictionary: return "手牌持续加成必须是属性表。"
 for key in modifiers:
  if key not in ["strength","dexterity","pleasure_multiplier","energy_pressure"] or not (modifiers[key] is int or modifiers[key] is float) or not is_finite(float(modifiers[key])): return "手牌持续加成属性有误。"
  if key=="pleasure_multiplier" and modifiers[key]<=0: return "手牌快感倍率必须大于零。"
  if key=="energy_pressure" and modifiers[key]<=0: return "手牌能量刺激必须大于零。"
 if spec.has("end_turn_pressure") and (not (spec.end_turn_pressure is int or spec.end_turn_pressure is float) or not is_finite(float(spec.end_turn_pressure)) or spec.end_turn_pressure<=0): return "回合末快感值必须大于零。"
 return ""

static func pressure_reserve_layers(pressure: float, interval: float) -> float:
 return floorf(pressure/interval)

static func effect_text(effect: Dictionary, spec: Dictionary, compact: bool=false) -> String:
 var value=amount(effect,spec)
 if effect.op=="slippery": return "获得%d层滑溜" % value
 if effect.op=="vulnerable": return ("使所有敌人获得%d层脆弱" if effect.targets=="enemies" else "使身上所有拘束具和特殊装备获得%d层脆弱") % value
 if effect.op=="mind_preparation": return "精神施法预备%d" % value
 if effect.op=="witch_focus": return "精神集中%d" % value
 if effect.op=="buff" and BUFFS[effect.buff].get("witch_hand",false): return "下2次手部基础动作忽略拘束条件"
 if effect.op=="retain" and effect.get("all",false): return "保留全部手牌"+("，随后抽%d张" % effect.draw_after if effect.get("draw_after",0)>0 else "")
 if compact:
  if effect.op=="buff" and BUFFS[effect.buff].get("ignore_restraints",false): return "下%d次手部体术无视拘束限制与减益" % BUFFS[effect.buff].attack_uses
  match effect.op:
   "draw": return ("抽取"+TYPES[effect.filter.tag] if effect.has("filter") else "抽牌")+str(value)
   "retain": return "保留%d" % value+("，随后抽牌%d" % effect.draw_after if effect.get("draw_after",0)>0 else "")
   "charge": return "蓄力%d" % value
   "reserve_mana": return "获得%d层魔力预备" % value
   "energy": return "能量＋%d" % value
 match effect.op:
  "self_toy": return "随机佩戴一件初级性玩具"
  "pressure_loss": return "失去%d快感" % value
  "buff": return "获得「"+BUFFS[effect.buff].name+"」："+BUFFS[effect.buff].detail
  "draw": return "抽%d张%s" % [value,draw_label(effect.get("filter",{}))]
  "retain": return "至多保留%d张牌" % value+("，随后抽%d张" % effect.draw_after if effect.get("draw_after",0)>0 else "")
  "energy": return "获得%d能量" % value
  "mana": return "恢复%d魔力" % value
  "pressure": return "获得%d快感" % value
  "evasion": return "获得%d层闪避" % value
  "charge": return "获得%d层蓄力" % value
  "reserve_mana": return "获得%d层魔力预备" % value
  _: return "下回合能量＋%d" % value



static func effect_details(spec: Dictionary, compact: bool=false) -> String:
 var result=""
 for group in ["hit_effects","lowered_effects","destroyed_effects"]:
  for effect in spec.get(group,[]):
   result+="\n"+({"hit_effects":"随后","lowered_effects":"松脱后仍佩戴：","destroyed_effects":"解除目标："} if compact else {"hit_effects":"随后","lowered_effects":"目标松脱后仍佩戴时，","destroyed_effects":"直接解除所选目标时，"})[group]+effect_text(effect,spec,compact)+"。"
 return result
