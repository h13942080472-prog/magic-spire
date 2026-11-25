extends RefCounted
const DisplayNumbers=preload("res://data/display_numbers.gd")
const SILENCER_HP=24.0
const ENEMY_DEPARTURE_GRADE=2
const ENEMY_DEPARTURE_TIER=3
const ENEMY_LONG_BATTLE_ROUND=15
const ENEMY_LONG_BATTLE_COUNT=20
const ENEMY_LONG_BATTLE_TIGHTNESS=40

# Prototype values only. No numbers imported from the old web implementation.
const ENERGY = 3
const DRAW = 5
const HAND_LIMIT = 10
const MANA_MAX = 100.0
const TEMPORARY_MANA_RETENTION = 20.0
const CHARGE_RETENTION = 2
const ENERGY_RETENTION = 1
const MANA_MAX_FLOOR = 1.0
const PRESSURE_MAX = 100.0
const FREE_PRESSURE_RELIEF = 2.0
const OVERLOAD_MANA = 20.0
const OVERLOAD_CHARGE_RETENTION = 0.5
const SLIP_EJACULATION_MANA = 10.0
const OVERLOAD_ENERGY = 1
const PRESSURE_MAGIC_SURCHARGE = 0.5
const PRESSURE_MAGIC_SURCHARGE_ENABLED = false
const CAST_SAFE_PRESSURE = 0.5
const CAST_FALLOFF_POWER = 2.0
const CAST_ROLL_STEPS = 10000
const CAST_FAILURE_REFUND = 0.5
const MOUTH_CAST_GRADE = {1:0.5,2:0.25,3:0.0}
const MOUTH_CAST_TIGHTNESS = {1:1.5,2:1.0,3:0.5}
const CALM_COST = 1
const CALM_REDUCTION = 20.0
const CALM_USES_PER_TURN = 2
const CALM_MOUTH_MULTIPLIERS = {0:1.0,1:1.0,2:0.8,3:0.6,4:0.4,5:0.2,6:0.0}
const CALM_NEXT_ENERGY = 1
const PREPARATION_TURNS = 3
const REST_TURNS = 6
const REST_CARD_TURNS = {"rare":3,"uncommon":3}
const REST_FLASK_TURNS = 3
const REST_FLASK_MANA = 50
const BOSS_FLASK_MANA = 80
const REST_HOOK_USES = 3
const RNG_SALTS = {"card_target":3391939,"deck":73471,"enemy":193939,"equipment":391939,"encounter":591939,"prison":791939,"event":991939,"reward":1191939,"position":1391939,"magic":1591939,"binding":1791939,"motion":1991939,"explore":2191939,"fall":2391939,"capture_bind":2591939,"item_drop":2791939,"enemy_visual":2991939,"relic":3191939}
const HAND_ASSIST_BONUS = 1.0
const CHARGE_BONUS = 3.0
const SPELL_COST = 10.0
const KICK = 18.0
const SEATED_KICK = 4.0
const BOUND_KICK = 10.0
const BOUND_SEATED_KICK = 5.0
const FIREBALL = 8.0
const FIREBALL_ASSISTED = 12.0
const BELT_HP = 30.0
const LOCK_HP = 28.0
const ROPE_HP = 30.0
const GUARD_HP = 90.0
const CAPTURE_EXTRA_BASE = 1
const PRISON_INTAKE = {1:{"floor":6,"extra":2,"special":2},2:{"floor":8,"extra":2,"special":2},3:{"floor":10,"extra":3,"special":3},4:{"floor":12,"extra":3,"special":3}}
const PRISON_COLLAR_LEVEL = 3
const PRISON_INTERVALS = [16,14,12,10,8]
const PRISON_SENTENCE = [20,30,50,0]
const PRISON_SENTENCE_PENALTY = 8
const PRISON_EXIT_FLASK_MANA = 60
const PRISON_VIOLATION_EXTRA = 2
const PRISON_SECURITY = {
 1:{"grade":1,"tier":2,"composites":false},
 2:{"grade":2,"tier":2,"composites":false},
 3:{"grade":2,"tier":3,"composites":true},
 4:{"grade":3,"tier":2,"composites":true},
 5:{"grade":3,"tier":3,"composites":true},
}
const PRISON_VENT_HITS = 3
const BASIC_DURABILITY = 8.0
const MEDIUM_DURABILITY = 15.0
const HIGH_DURABILITY = 30.0
const DAMAGE_REDUCTION_MAX = 0.5
const LOOSE_DAMAGE_BONUS = 0.25
const LEATHER_SLIP_MULTIPLIER = 1.5
const WALL_BONUS = 2.0
const POSTURE_COSTS = [[1,2,1,2], [1,2,1,2], [1,3,1,2], [1,3,1,3], [1,4,1,3]]
const BODY_DAMAGE = [1.0, 1.0, 0.8, 0.6, 0.4]
const SLOTS = ["upper_arm", "forearm", "wrist", "palm", "fingers", "thigh", "calf", "ankle", "foot", "toes", "mouth", "eyes"]
const SLOT_NAMES = {"neck":"脖颈", "shoulder":"肩部", "upper_arm":"大臂", "forearm":"小臂", "wrist":"手腕", "palm":"手掌", "fingers":"手指", "thigh":"大腿", "calf":"小腿", "ankle":"脚踝", "foot":"脚掌", "toes":"脚趾", "mouth":"口部", "eyes":"眼部"}
const ARM_SLOTS = ["upper_arm", "forearm", "wrist", "palm", "fingers"]
const LEG_SLOTS = ["thigh", "calf", "ankle", "foot", "toes"]
const POSE_NAMES = {"stand":"站姿", "sit":"坐姿", "lie":"躺姿"}
static var CARD_TRAITS={"liberating_grace":{"exhaust":true},"shining_debut":{"exhaust":true},"pocket_knife":{"temporary":true,"retain":true,"exhaust":true},"shockwave":{"exhaust":true},"but_also":{"innate":true,"exhaust":true},"royal_gift":{"temporary":true,"exhaust":true},"art_submission":{"status":true,"unplayable":true,"temporary":true},"psychological_suggestion":{"retain":true},"forced_climax":{"exhaust":true},"binding_power":{"exhaust":true},"kip_up":{"retain":true},"prepared_chant":{"retain":true,"exhaust":true},"hannya_1":{"exhaust":true,"innate":true},"hannya_2":{"exhaust":true,"temporary":true},"hannya_3":{"exhaust":true,"temporary":true},"hannya_4":{"exhaust":true,"temporary":true},"hannya_swallow":{"temporary":true,"exhaust":true,"ethereal":true},"hannya_infusion":{"temporary":true,"exhaust":true,"ethereal":true},"hannya_henshin":{"temporary":true,"exhaust":true,"ethereal":true},"good_soup":{"temporary":true},"magic_hand":{"exhaust":true},"pot_of_greed":{"exhaust":true},"repeated_strain":{"exhaust":true},"mana_invocation":{"exhaust":true},"mana_surge":{"exhaust":true},"henshin":{"exhaust":true},"panic":{"curse":true,"exhaust":true},"sensitive":{"curse":true,"unplayable":true,"retain":true},"lewd_mark":{"curse":true,"unplayable":true},"detective_provoke":{"status":true,"exhaust":true,"temporary":true},"disrupt":{"status":true,"unplayable":true,"temporary":true},"tease":{"status":true,"unplayable":true,"temporary":true},"tease_plus":{"status":true,"unplayable":true,"temporary":true}}
static var CARD_NAMES = {"liberating_grace":"恩赐解脱","shining_debut":"闪耀登场！","pocket_knife":"小刀","dual_chant":"沉稳咏唱／即刻咏唱","study":"钻研","shockwave":"震荡波","find_weakness":"弱点发现","yield_force":"消力","royal_gift":"成王之礼","art_submission":"强人锁女","itching_heart":"心痒难耐","self_satisfaction":"自我满足","psychological_suggestion":"心理暗示","rally_spirit":"强打精神","desire_rune":"爱欲魔纹","forced_edging":"强制寸止","forced_climax":"强制高潮","supple_flesh":"活动媚肉","binding_power":"拘束就是力量！","mana_attachment":"魔力附着","binding_search":"紧缚检索","kip_up":"鲤鱼打挺","sympathetic_form":"交感形态","formation":"布阵","endless_war_goddess":"无尽魔法少女战神","self_binding":"自缚","full_escape":"浑身解数","prepared_chant":"预备咏唱","reuse":"魔路精通","confluence":"汇流","mana_arm":"魔力臂","finesse":"巧劲","resonance":"共鸣","practiced":"熟练而已","hannya_1":"般若汤-其一","hannya_2":"般若汤-其二","hannya_3":"般若汤-其三","hannya_4":"般若汤-其四","hannya_swallow":"身轻如燕","hannya_infusion":"灌注","hannya_henshin":"henshin（品相完美!）","good_soup":"好汤喝够饮饮饮饮","siphon_strength":"汲取力量","shared_fate":"命运同担","magic_hand_gift":"魔术手","magic_hand":"魔术手","leverage":"借力打力","light_as_swallow":"身轻如燕","breath_control":"运气","restraint_embrace":"拘束之拥","binding_enthusiast":"紧缚爱好","infusion":"灌注","siphon":"汲取","concentration":"专心致志","mana_circuit":"魔力回路","ready_to_strike":"蓄势待发","crossed_legs":"翘腿无视","but_also":"可是🥺...也...😅","forethought":"瞻前顾后","mana_search":"魔路检索","last_resort":"底力","pot_of_greed":"强欲之壶","repeated_strain":"连续挣","echo_cast":"余势复演","embers":"余火","wildfire_descent":"猛火下山","boar_emperor_blaze":"猪神之皇焚","adaptability":"灵活变通","rekindle":"死灰复燃","fire_dynamics":"火动力学","flame_flourish":"炫火","fire_control":"控火","mana_invocation":"激发魔力","strong_elbow":"强力肘击","pleasure_conversion":"欲能转换","mana_conversion":"魔力转换","mana_surge":"魔力涌流","henshin":"henshin","fire_mastery":"火焰精通","focus":"找准松处","tear":"扯开缺口","chain":"接连挣动","peel":"逐层抽离","double_unlock":"双重解锁","panic":"慌乱","sensitive":"敏感","lewd_mark":"淫纹","detective_provoke":"挑弄","disrupt":"扰乱","tease":"玩弄","tease_plus":"玩弄+","strain":"用力！", "slip":"顾涌！", "ease":"魔力撑隙", "unlock":"术式解锁", "brace":"绷紧再挣", "inch":"一点点抽出", "magic_slip":"魔力松缚"}
static var CARD_INFO = {
 "dual_chant":["魔法","本场下一张魔法牌必定施放成功。","本场下一张魔法牌的能量与魔力费用均为0。",""],
 "study":["技能","本场力量＋2，灵巧＋2，火球术伤害－4。","本场力量－1，灵巧－1，火球术伤害＋2。",""],
 "shockwave":["魔法","所有敌人及身上所有拘束具和特殊装备获得4层脆弱。","所有敌人获得4层脆弱。获得3层滑溜。",""],
 "find_weakness":["技能","下一次腿部体术使目标获得2层脆弱。","下一次手部体术使目标获得2层脆弱。",""],
 "yield_force":["能力","力量－2。滑脱可作用于紧度3的装备，滑脱伤害×1.5。","力量－2。回合开始时获得1层滑溜。",""],
 "pocket_knife":["道具","上身拘束严密度≤1时，对敌人造成8点伤害；否则对自身装备造成8点切割伤害。","上身拘束严密度＞1时，借墙对自身装备造成8点切割伤害。","可切割绳索、皮革、胶带及固定带。"],
 "liberating_grace":["技能","接下来 X 次挣扎或滑脱各追加一段伤害。","本回合下一次体术造成 X×0.5 倍伤害。",""],
 "shining_debut":["技能","获得1点能量。抽{bound_body_draw}张牌（受拘束的大部位数＋1）。","{mana_cost}获得2点能量，抽3张牌。",""],
 "royal_gift":["技能","抽{gift}张牌。能量、力量、灵巧、蓄力、魔力预备各＋{gift}。","抽{gift}张牌。能量、力量、灵巧、蓄力、魔力预备各＋{gift}。","第4回合升至3，第7回合升至6并封顶。"],"art_submission":["状态","抽到时获得1层不可反抗。","抽到时获得1层不可反抗。","下一张对拘束具造成伤害的牌伤害为0。助理死亡后移除本牌及此效果。"],"itching_heart":["淫魔法","降紧1。","随机佩戴一件初级性玩具。","拘束面消耗10快感；施法失败全部返还。"],"self_satisfaction":["技能","获得20快感。","获得10快感，蓄力2。",""],"psychological_suggestion":["淫魔法","下次出牌或基础动作无视拘束具的影响。","抽取1，蓄力1。","保留。快感费用在施法失败时全部返还。"],"rally_spirit":["技能","降紧1。获得10快感。","失去20快感；下回合获得40快感。",""],"desire_rune":["能力","每获得30快感，蓄力1。","每获得40快感，抽1张牌。","直接生效。按实际快感增加量累计，进度跨回合保留。"],"forced_edging":["淫魔法","能量＋1。","抽取2，失去20快感。","拘束面消耗20快感，施法失败全部返还。"],"forced_climax":["淫魔法","选择3张牌消耗，抽3张牌，获得30快感，然后触发一次高潮；这次高潮保留当前快感值。","选择3张牌消耗，抽3张牌，获得30快感，然后触发一次高潮；这次高潮保留当前快感值。","从本场抽牌堆、其他手牌、弃牌堆选择。消耗。"],"supple_flesh":["技能","获得4点临时灵巧。","获得2点临时力量。","持续到回合结束。"],"binding_power":["技能","你每佩戴{bound_worn_divisor}件拘束具或性玩具，获得1点临时力量，直到你的下回合结束前。{bound_worn_preview}","你每佩戴{free_worn_divisor}件拘束具或性玩具，获得1层蓄力。{free_worn_preview}","向下取整；复合拘束具整件计1件。"],"mana_attachment":["魔法／能力","获得1层蓄力。本场战斗中，成功打出技能牌时消耗5魔力，获得1层蓄力。","获得1层蓄力。本场战斗中，体术变为全体伤害，威力减半，每次额外消耗10魔力。","需有足够魔力触发。右键状态开关。"],"binding_search":["魔法／技能","抽{bound_body_draw}张牌{bound_body_preview}。X为有拘束具的非性器部位数，结果向下取整。","在非性器部位随机佩戴1件紧度2的中级拘束具，抽3张牌。","同一身体栏小部位只计1次。"],"kip_up":["技能","变为站姿。力量≥4时，本牌变为0费。","下一次腿部体术无视姿势限制。力量≥4时，本牌变为0费。","按当前总力量实时判断。腿部体术包括近身短打和各类踢击，按站姿招式发动，姿势保持原状；捕缚的强制姿势与起身顺序优先，其他限制照常。同面仅生效一次。"],"sympathetic_form":["能力","回合开始时，获得2层魔力预备和1点能量。","回合结束时，若未佩戴拘束具，恢复20魔力，获得10快感。本场战斗力量＋1、灵巧＋1、火球术伤害＋2。",""],"formation":["能力","每回合第一张魔法牌必定成功。","每回合第一张魔法牌能量－1，最低0。","两面可同时生效。打出当回合立即获得次数，下回合刷新。0费牌也消耗次数。严密度仅在打出布阵时检查。"],"endless_war_goddess":["魔法","耗尽当前自身魔力与魔力预备。每消耗10魔力，基础动作无视拘束、快感与姿势限制1回合。","耗尽当前自身魔力与魔力预备。每消耗10魔力，基础动作无视拘束、快感与姿势限制1回合。","火球术也无视拘束、快感与姿势限制。右键可切换所有踢击招式。使用动作仍需付费、等待冷却，并受每回合次数上限限制。"],"self_binding":["技能","随机收紧拘束具共2X档，锁保持原状。随后恢复15X自身魔力。需要足够空间。","腿部随机佩戴2件拘束具，每件品质＋紧度＝2X。随后恢复15X自身魔力。需要足够空间。","X为打出前的全部剩余能量。主动佩戴直接生效，已有装备保留，需要足够空位。自由面X需为1—3；拘束面X＝0时效果为0。复放沿用原X并重新检查空间。"],"prepared_chant":["魔法","{mana_cost}接下来3次施法的成功率固定为100%。","{mana_cost}下回合施法成功率固定为100%。",""],"reuse":["能力","施法失败时，返还100%耗魔并获得1点能量。0费牌每回合限2次。若你当前佩戴至少10件紧度≥2的拘束具，取消次数限制。","耗魔全部由魔力预备抵扣时，抽1张牌。若施法失败，获得1能量，返还魔力为0。0费牌每回合最多以此获得2次能量。","两面互斥。0费按本次实际能量费用判定；达到次数上限后按普通施法失败结算。"],"confluence":["技能","你每佩戴{bound_worn_divisor}件拘束具或性玩具，本回合获得1点力量。{bound_worn_preview}","你每佩戴{free_worn_divisor}件拘束具或性玩具，恢复{free_worn_amount}点魔力。{free_worn_preview}","按出牌时的佩戴件数计算。复合拘束具按1件计算。"],"mana_arm":["技能","本回合每次体术消耗5魔力，手部体术无视限制。","本回合每次体术攻击前，消耗5魔力并获得1层蓄力。","魔力不足时，按原体术发动。"],"finesse":["能力","可在消耗1层与消耗全部蓄力之间切换。","每层蓄力的伤害加成＋2。",""],"resonance":["能力","你每佩戴1件拘束具或性玩具，施法消耗的魔力降低5%。","获得2层闪避。",""],"practiced":["能力","施法成功率最低75%。每次使用魔法牌，无论成败，额外牵扯1次。","你每成功打出1张其他牌，本回合的施法成功率提高8%。","牵扯按1能量判定，额外能量费用为0。两面可同时生效。"],"hannya_1":["技能","力量＋1，灵巧＋1，魔力＋5。正义飞踢费用＋1，获得打断，与坐姿踢击及并腿踢击共用3回合冷却。般若汤-其二加入弃牌堆。","力量＋1，灵巧＋1，魔力＋5。近身短打基础伤害＋2，连击每段基础伤害＋1。般若汤-其二加入弃牌堆。","升级时领取效果；当前等级详见出牌预览。"],"hannya_2":["技能","力量＋1，灵巧＋1，魔力＋5。0费消耗／虚无的身轻如燕加入手牌；般若汤-其三加入弃牌堆。","力量＋1，灵巧＋1，魔力＋5。0费消耗／虚无的身轻如燕加入手牌；般若汤-其三加入弃牌堆。","升级时领取效果；当前等级详见出牌预览。"],"hannya_3":["技能","力量＋1，灵巧＋1，魔力＋5。0费消耗／虚无的灌注加入手牌；般若汤-其四加入弃牌堆。","力量＋1，灵巧＋1，魔力＋5。0费消耗／虚无的灌注加入手牌；般若汤-其四加入弃牌堆。","升级时领取效果；当前等级详见出牌预览。"],"hannya_4":["技能","力量＋1，灵巧＋1，魔力＋5。虚无的完美henshin加入手牌；好汤喝够饮饮饮饮加入弃牌堆。","力量＋1，灵巧＋1，魔力＋5。虚无的完美henshin加入手牌；好汤喝够饮饮饮饮加入弃牌堆。","升级时领取效果；当前等级详见出牌预览。"],"good_soup":["技能","{mana_gain}","{mana_gain}","本场整备结束时移除。"],"hannya_swallow":["技能","下一次卡牌滑脱伤害×2。","闪避2。","本场整备结束时移除。"],"hannya_infusion":["魔法","{mana_cost}下一次腿部体术获得打断。","{mana_cost}下一次手部体术获得打断。","与自带打断取较高值。本场整备结束时移除。"],"hannya_henshin":["魔法","{mana_cost}解除全部拘束与捕缚。打出时播放dj版雨爱。","{mana_cost}本场全部伤害×2。打出时播放dj版雨爱。","同源仅生效一次。本场整备结束时移除。"],"siphon_strength":["魔法","{bound_batch}","{free_batch}",""],"shared_fate":["技能","将快感与魔力均设为两者总和的一半。","将快感与魔力均设为两者总和的一半。",""],"magic_hand_gift":["魔法","{mana_cost}降紧{hits}。超级顺延。","{mana_cost}{free_effects}","欧内的手赠予：使用后正常弃置。"],"magic_hand":["魔法","{mana_cost}降紧{hits}。超级顺延。","{mana_cost}{free_effects}",""],
 "leverage":["挣扎","你每佩戴1件拘束具，这张牌的基础挣扎伤害增加{worn_per_item}点{dynamic_damage}。","{free_effects}",""],
 "light_as_swallow":["技能","下一次卡牌滑脱伤害×2。","获得2层闪避。",""],"breath_control":["滑脱","滑脱{base}×{hits}。选择并消耗1张手牌。","获得1层蓄力。下一次体术费用－1。选择并消耗1张手牌。","自由面需要嘴部自由。"],
 "restraint_embrace":["能力","每被佩戴1件拘束具，下回合抽1张牌。","每挣脱1件拘束具，抽1张牌，恢复1能量。","复合拘束具完全挣脱时计1件。手牌已满时仍恢复能量。"],
 "binding_enthusiast":["能力","你每佩戴1件拘束具或性玩具，力量和灵巧各增加1点。每成功打出1张其他牌的拘束面，固定获得10点快感。","你每佩戴1件拘束具或性玩具，力量和灵巧各增加1点。每成功打出1张其他牌的拘束面，固定获得10点快感。","复合拘束具按1件计算。"],
 "infusion":["魔法","{mana_cost}下一次腿部体术附加1层打断。","{mana_cost}下一次手部体术附加1层打断。","手部：肘击、近身短打。腿部：近身短打、各类踢击。同一面仅生效一次；对应体术使用后消耗，与自带打断取较高值。"],
 "concentration": ["技能","挣扎{base}。使用后，本场两面伤害＋{damage_growth}。","滑脱{base}。使用后，本场两面伤害＋{damage_growth}。","同一张牌的两面共享成长。"],
 "mana_circuit":["能力","每累计消耗20点魔力，获得1层蓄力。","每累计消耗30点魔力，获得1点能量。","自身魔力和魔力预备抵扣的耗魔均计入，失败施法也计入。各张独立累计，余数跨回合保留。"],
 "ready_to_strike":["魔法","{mana_cost}消耗一张指定手牌；{bound_effects}","{mana_cost}消耗一张指定手牌；{self_free_buff}","所选手牌仅在施法成功时消耗。体术包括肘击、近身短打及各类踢击，排除火球术。减费仅生效一次。"],
 "crossed_legs":["滑脱","滑脱{base}。","{free_effects}",""],
 "but_also":["技能","{bound_effects}","{self_free_effects}",""],
 "forethought":["技能","{bound_effects}从弃牌堆选择1张牌置入手牌。","{self_free_effects}从抽牌堆选择1张牌置入手牌。",""],
 "mana_search":["技能","{bound_effects}","{self_free_effects}",""],
 "last_resort":["技能","若自身魔力为0且上回合未使用魔瓶，获得3层蓄力。","若自身魔力为0且上回合未使用魔瓶，抽3张牌。",""],
 "pot_of_greed":["技能","{bound_effects}","{self_free_effects}",""],
 "echo_cast":["技能","若火球术剩余次数为0，本场战斗火球术伤害＋5。","本回合，每成功打出一张魔法牌，恢复1次火球术使用次数。",""],
 "embers":["魔法","本回合成功使用过火球术后可用。{mana_cost}抽牌1；魔力足够时再耗{optional_draw_cost}魔力、抽牌1。","{mana_cost}本回合火球术基础伤害＋4。","追加抽牌自动耗魔并直接生效。火球强化仅生效一次。"],
 "wildfire_descent":["能力","{mana_cost}每当你成功施放火球术，抽1张牌。","{mana_cost}每当你成功施放火球术，抽1张牌。","群攻每层触发一次。"],
 "adaptability":["技能","将全部魔力预备转化为等量蓄力。","将全部蓄力转化为等量魔力预备。","仅转化整层，不足1层的魔力预备保留。"],
 "rekindle":["魔法","{mana_cost}刷新本回合火球次数。","{mana_cost}刷新本回合火球次数。","包含炫火增加的次数。"],
 "fire_dynamics":["能力","火球术施法成功率＋30%，伤害＋4。","火球改为全体攻击。","群攻只施法一次；炫火自解仍为单目标。"],
 "fire_control":["技能","{bound_effects}","火球基础伤害永久＋{free_spell_bonus}。","加伤跨战保留。"],
 "siphon":["魔法","{mana_gain}","{mana_gain}{self_free_effects}",""],
 "mana_invocation":["魔法","{mana_gain}","{mana_gain}",""],
 "repeated_strain":["挣扎","挣扎{base}×{hits}。顺延。","{free_effects}",""],
 "boar_emperor_blaze":["挣扎","挣扎{base}×{hits}。超级顺延。","蓄力{fireball_charge}。","拘束面次数为当前火球术伤害向下取整，自由面蓄力等于本场成功施放火球术的次数。"],
 "flame_flourish":["能力","火球术可以攻击最外层的拘束具，对其造成一半伤害。","每回合火球次数＋1。","敌人与拘束具共用火球术次数。"],
 "fire_mastery":["能力","火球无视身体限制；手势加成为0。","火球伤害×2。","同面仅生效一次；费用与快感施法概率保持原值。"],
 "strong_elbow":["挣扎","挣扎{base}。","下次肘击伤害×2。","对下一次肘击的所有段数生效。"],
 "pleasure_conversion":["转换","你当前每有20点快感，就获得1点能量。","当前每满10点快感，获得1层魔力预备。","快感保留。"],
 "mana_conversion":["魔法","{mana_cost}能量＋2。","{mana_gain}","固定兑换按牌面耗魔结算，成功时遗物返还为0；施法失败按普通返还规则结算。"],
 "mana_surge":["魔法","{mana_cost}{bound_effects}","{mana_cost}{self_free_effects}",""],
 "henshin":["魔法","{mana_cost}解除全部拘束具与捕缚。打出时播放dj版雨爱。","{mana_cost}本场全部伤害×2。打出时播放dj版雨爱。","同源伤害加倍仅生效一次。"],
 "focus":["技能","{bound_effects}","{self_free_effects}",""],
 "tear":["挣扎","挣扎{base}。","{free_effects}","每次仅直接解除的装备返还能量。"],
 "chain":["挣扎","挣扎{base}×{hits}。顺延。","{free_effects}",""],
 "peel":["滑脱","滑脱{base}×{hits}。顺延。","{free_effects}",""],
 "full_escape":["技能","对所有非敏感部位的外层拘束具各挣扎{base}×X。顺延。","对所有非敏感部位的外层拘束具各滑脱{base}×X。顺延。","X为本次消耗的全部可用能量。"],
 "double_unlock":["魔法","{mana_cost}开锁至多{hits}。","{free_effects}",""],
 "panic":["诅咒","","",""],
 "sensitive":["诅咒","在手牌中：快感增长×{pleasure_multiplier}。","在手牌中：快感增长×{pleasure_multiplier}。","多张相乘，仅影响快感增长。"],
 "lewd_mark":["诅咒","在手牌中：每次支付能量后，快感＋{energy_pressure}。","在手牌中：每次支付能量后，快感＋{energy_pressure}。","每次付费行动触发一次。"],
 "detective_provoke":["状态牌","抽到或打出时，快感＋10，额外触发一次牵扯。","抽到或打出时，快感＋10，额外触发一次牵扯。","消耗"],
 "disrupt":["状态牌","抽到时，本回合力量－1、灵巧－1。","抽到时，本回合力量－1、灵巧－1。","无法打出。战斗结束时移除。"],
 "tease":["状态牌","回合结束仍在手中：快感＋5。","回合结束仍在手中：快感＋5。","战斗结束或被收押时消失。"],
 "tease_plus":["状态牌","回合结束仍在手中：快感＋8。","回合结束仍在手中：快感＋8。","战斗结束或被收押时消失。"],
 "strain":["挣扎","挣扎{base}。","{free_effects}","按该部位最高紧度选择目标；并列时先处理其中最内层。"],
 "slip":["滑脱","滑脱{base}。","{free_effects}","同层非最高紧度目标伤害减半。"],
 "ease":["魔法","{mana_cost}降紧2。","{free_effects}",""],
 "unlock":["魔法","{mana_cost}开锁1。","{free_effects}",""],
 "brace":["挣扎","挣扎{base}。","{free_effects}",""],
 "inch":["滑脱","滑脱{base}。","{free_effects}",""],
 "magic_slip":["魔法","{mana_cost}魔法滑脱{base}。","{free_effects}",""]
}

static func card_info(type: String, mana: Variant=null, base: Variant=null, inline_mana: bool=true, worn_count: Variant=null, body_count: Variant=null, exhaust_display: int=-1, gift: int=1, fireball_charge: int=-1) -> Array:
 var rules=preload("res://data/card_rules.gd")
 var spec=rules.SPECS[type]
 var values={"gift":gift,"follow_through":rules.FOLLOW_THROUGH_TEXT}
 if spec.has("worn_damage"):
  values.worn_per_item=str(spec.worn_damage.per_item)
  values.dynamic_damage="" if base==null or base is Dictionary else "（当前%s）" % DisplayNumbers.amount(base)
 for key in spec.get("hand_modifiers",{}): values[key]=DisplayNumbers.amount(spec.hand_modifiers[key])
 for key in ["base","bonus","refund","hits","damage_growth"]:
  if spec.has(key): values[key]=DisplayNumbers.amount(spec[key])
 if spec.get("fireball_hits",false):
  values.hits=str(base.get("bound",[]).size()) if base is Dictionary else "X"
  values.fireball_charge=str(fireball_charge) if fireball_charge>=0 else "X"
 if base!=null and not base is Dictionary: values.base=DisplayNumbers.amount(base)
 if spec.has("free_effects"):
  var effects=spec.free_effects.map(func(effect):return rules.effect_text(effect,spec,true))
  values.free_effects="；".join(effects)+("。" if not effects.is_empty() else "")
 if spec.has("self_faces"):
  for side in ["bound","free"]:
   var face=spec.self_faces[side]
   if face.has("body_draw_divisor"):
    values[side+"_body_draw"]=("X＋1" if face.get("region_draw",false) else "X/%d" % face.body_draw_divisor) if body_count==null else str(rules.body_draw_amount(face,body_count))
    values[side+"_body_preview"]="" if body_count==null else "（X＝%d）" % int(body_count)
   if face.has("worn_resource"):
    values[side+"_worn_gain"]=("佩戴件数" if face.worn_resource.divisor==1 else "⌊佩戴件数÷%d⌋" % face.worn_resource.divisor) if worn_count==null else str(rules.worn_gain(face,int(worn_count)))
    values[side+"_worn_divisor"]=str(face.worn_resource.divisor)
    values[side+"_worn_amount"]=str(face.worn_resource.get("amount",1))
    if worn_count==null and face.worn_resource.get("amount",1)!=1: values[side+"_worn_gain"]+="×"+values[side+"_worn_amount"]
    var gain_copy={"mana":"恢复%s魔力。","turn_strength":"本回合力量＋%s。","strength":"力量＋%s。","charge":"获得%s层蓄力。"}[face.worn_resource.resource]
    values[side+"_worn_preview"]="" if worn_count==null else "\n当前："+(gain_copy % values[side+"_worn_gain"])
   var batch=spec.self_faces[side].get("exhaust_hand_batch",{})
   var rewards=[]
   if batch.has("mana_gain"): rewards.append("恢复%s魔力" % DisplayNumbers.amount(batch.mana_gain))
   for effect in batch.get("effects",[]): rewards.append(rules.effect_text(effect,spec,false))
   values[side+"_batch"]="" if batch.is_empty() else "消耗手牌中全部%s牌。每消耗1张，%s。" % [rules.hand_batch_type_text(batch),"、".join(rewards)]
   values[side+"_spell_bonus"]=str(spec.self_faces[side].get("spell_base_bonus",{}).get("amount",0))
   values["bound_buff" if side=="bound" else "self_free_buff"]=rules.BUFFS.get(spec.self_faces[side].get("buff",""),{}).get("detail","")
   var effects=spec.self_faces[side].get("effects",[]).map(func(effect):return rules.effect_text(effect,spec,true))
   values["bound_effects" if side=="bound" else "self_free_effects"]="；".join(effects)+("。" if not effects.is_empty() else "")
 var result=CARD_INFO[type].duplicate()
 for index in range(result.size()):
  var free=index==2
  if base is Dictionary and not spec.get("sweep_slots",false):
   var damage=base.get("free" if free else "bound",[])
   if not damage.is_empty():
    values.base=DisplayNumbers.amount(damage[0])
    if spec.has("worn_damage"): values.dynamic_damage="（当前%s）" % values.base
    if damage.size()>1:
     var token="{base}×{hits}" if result[index].contains("{base}×{hits}") else "{base}"
     result[index]=result[index].replace(token,damage_sequence(damage))
  var face_mana=mana.get("free" if free else "bound") if mana is Dictionary else mana
  var cost=rules.face_mana_base(type,free,SPELL_COST) if face_mana==null else float(face_mana)
  var gain=float(spec.get("self_faces",{}).get("free" if free else "bound",{}).get("mana_gain",0))
  values.optional_draw_cost=DisplayNumbers.amount(spec.get("self_faces",{}).get("free" if free else "bound",{}).get("optional_draw",{}).get("mana_cost",0))
  values.mana_cost=("耗魔"+DisplayNumbers.measured(cost)+"。") if inline_mana and cost>0 else ""
  values.mana_gain=("魔力＋"+DisplayNumbers.measured(gain)+"。") if inline_mana and gain>0 else ""
  result[index]=result[index].format(values)
 result[1]+=preload("res://data/card_rules.gd").effect_details(spec,true)
 var traits=CARD_TRAITS.get(type,{})
 for side in [1,2]:
  if spec.has("remove_uses"): result[side]+=rules.remove_label(spec.remove_uses)+"。"
  result[side]+=spec.get("play_music_text","")
  if traits.get("retain",false): result[side]+="保留。"
  if rules.unique_face(type,side==2): result[side]+="唯一。"
  if exhaust_display!=0 and rules.exhausts(type,side==2,traits): result[side]+=rules.exhaust_label(rules.native_exhaust_remaining(type) if exhaust_display<0 else exhaust_display)+"。"
  if traits.get("ethereal",false): result[side]+="虚无。"
  if traits.get("innate",false): result[side]="固有。"+result[side]
 return result

# Compress equal consecutive hits without pretending limited Charge buffs every hit.
static func damage_sequence(values: Array) -> String:
 var groups=[]
 for value in values:
  if not groups.is_empty() and groups[-1].value==value: groups[-1].count+=1
  else: groups.append({"value":value,"count":1})
 return "＋".join(groups.map(func(group):return "%s×%d" % [DisplayNumbers.amount(group.value),group.count]))

static func card_metadata(type: String, mana_costs: Dictionary={}, base: Variant=null, worn_count: Variant=null, body_count: Variant=null, exhaust_display: int=-1, fireball_charge: int=-1) -> Dictionary:
 var costs={}
 for side in ["bound","free"]: costs[side]=mana_costs.get(side,preload("res://data/card_rules.gd").face_mana_base(type,side=="free",SPELL_COST))
 var result=preload("res://data/card_text.gd").metadata(type,CARD_TRAITS.get(type,{}),SLOT_NAMES,costs,worn_count,exhaust_display)
 var effects=card_info(type,costs,base,false,worn_count,body_count,exhaust_display,1,fireball_charge)
 result.face_effects={"bound":effects[1],"free":effects[2]}
 return result

static func keyword_ids(type: String, free: bool) -> Array:
 return preload("res://data/card_text.gd").keyword_ids(type,free,CARD_TRAITS.get(type,{}))

static func slot_target_ids() -> Array:
 return preload("res://data/card_text.gd").SLOT_TARGET_IDS

static func card_collects_slots(card_type: String) -> bool:
 return preload("res://data/card_text.gd").collects_slots(card_type,CARD_TRAITS.get(card_type,{}),preload("res://data/card_rules.gd").SPECS[card_type].has("target_slots"))
