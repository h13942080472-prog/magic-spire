extends RefCounted
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
const BASIC_DURABILITY = 10.0
const MEDIUM_DURABILITY = 16.0
const HIGH_DURABILITY = 24.0
const DAMAGE_REDUCTION_MAX = 0.5
const LOOSE_DAMAGE_BONUS = 0.25
const WALL_BONUS = 2.0
const POSTURE_COSTS = [[1,2,1,2], [1,2,1,2], [1,3,1,2], [1,3,1,3], [1,4,1,3]]
const BODY_DAMAGE = [1.0, 1.0, 0.8, 0.6, 0.4]
const SLOTS = ["upper_arm", "forearm", "wrist", "palm", "fingers", "thigh", "calf", "ankle", "foot", "toes", "mouth", "eyes"]
const SLOT_NAMES = {"neck":"脖颈", "shoulder":"肩部", "upper_arm":"大臂", "forearm":"小臂", "wrist":"手腕", "palm":"手掌", "fingers":"手指", "thigh":"大腿", "calf":"小腿", "ankle":"脚踝", "foot":"脚掌", "toes":"脚趾", "mouth":"口部", "eyes":"眼部"}
const ARM_SLOTS = ["upper_arm", "forearm", "wrist", "palm", "fingers"]
const LEG_SLOTS = ["thigh", "calf", "ankle", "foot", "toes"]
const POSE_NAMES = {"stand":"站姿", "sit":"坐姿", "lie":"躺姿"}
static var CARD_TRAITS={"psychological_suggestion":{"retain":true},"forced_climax":{"exhaust":true},"binding_power":{"exhaust":true},"kip_up":{"retain":true},"prepared_chant":{"retain":true,"exhaust":true},"hannya_1":{"exhaust":true,"innate":true},"hannya_2":{"exhaust":true,"temporary":true},"hannya_3":{"exhaust":true,"temporary":true},"hannya_4":{"exhaust":true,"temporary":true},"hannya_swallow":{"temporary":true,"exhaust":true,"ethereal":true},"hannya_infusion":{"temporary":true,"exhaust":true,"ethereal":true},"hannya_henshin":{"temporary":true,"exhaust":true,"ethereal":true},"good_soup":{"temporary":true},"magic_hand":{"exhaust":true},"pot_of_greed":{"exhaust":true},"repeated_strain":{"exhaust":true},"mana_invocation":{"exhaust":true},"mana_surge":{"exhaust":true},"henshin":{"exhaust":true},"panic":{"curse":true,"exhaust":true},"sensitive":{"curse":true,"unplayable":true,"retain":true},"lewd_mark":{"curse":true,"unplayable":true},"tease":{"status":true,"unplayable":true,"temporary":true},"tease_plus":{"status":true,"unplayable":true,"temporary":true}}
static var CARD_NAMES = {"itching_heart":"心痒难耐","self_satisfaction":"自我满足","psychological_suggestion":"心理暗示","rally_spirit":"强打精神","desire_rune":"爱欲魔纹","forced_edging":"强制寸止","forced_climax":"强制高潮","supple_flesh":"活动媚肉","binding_power":"拘束就是力量！","mana_attachment":"魔力附着","binding_search":"紧缚检索","kip_up":"鲤鱼打挺","sympathetic_form":"交感形态","formation":"布阵","endless_war_goddess":"无尽魔法少女战神","self_binding":"自缚","prepared_chant":"预备咏唱","reuse":"魔路精通","confluence":"汇流","resonance":"共鸣","practiced":"熟练而已","hannya_1":"般若汤-其一","hannya_2":"般若汤-其二","hannya_3":"般若汤-其三","hannya_4":"般若汤-其四","hannya_swallow":"身轻如燕","hannya_infusion":"灌注","hannya_henshin":"henshin（品相完美!）","good_soup":"好汤喝够饮饮饮饮","siphon_strength":"汲取力量","shared_fate":"命运同担","magic_hand_gift":"魔术手","magic_hand":"魔术手","leverage":"借力打力","light_as_swallow":"身轻如燕","breath_control":"运气","restraint_embrace":"拘束之拥","binding_enthusiast":"紧缚爱好","infusion":"灌注","siphon":"汲取","concentration":"专心致志","mana_circuit":"魔力回路","ready_to_strike":"蓄势待发","crossed_legs":"翘腿无视","mana_search":"魔路检索","pot_of_greed":"强欲之壶","repeated_strain":"连续挣","echo_cast":"余势复演","embers":"余火","wildfire_descent":"猛火下山","boar_emperor_blaze":"猪神之皇焚","adaptability":"灵活变通","rekindle":"死灰复燃","fire_dynamics":"火动力学","flame_flourish":"炫火","fire_control":"控火","letter_opener":"开信刀play","mana_invocation":"激发魔力","strong_elbow":"强力肘击","pleasure_conversion":"欲能转换","mana_conversion":"魔力转换","mana_surge":"魔力涌流","henshin":"henshin","fire_mastery":"火焰精通","focus":"找准松处","tear":"扯开缺口","chain":"接连挣动","peel":"逐层抽离","double_unlock":"双重解锁","panic":"慌乱","sensitive":"敏感","lewd_mark":"淫纹","tease":"玩弄","tease_plus":"玩弄+","strain":"用力！", "slip":"顾涌！", "ease":"魔力撑隙", "unlock":"术式解锁", "brace":"绷紧再挣", "inch":"一点点抽出", "magic_slip":"魔力松缚"}
static var CARD_INFO = {"itching_heart":["淫魔法","降紧1。","随机佩戴一件初级性玩具。","拘束面消耗10快感；施法失败全部返还。"],"self_satisfaction":["技能","获得20快感。","获得10快感，蓄力2。",""],"psychological_suggestion":["淫魔法","下次出牌或基础动作无视拘束具的影响。","抽取1，蓄力1。","保留。快感费用在施法失败时全部返还。"],"rally_spirit":["技能","降紧1。获得10快感。","失去20快感；下回合获得40快感。",""],"desire_rune":["能力","每获得30快感，蓄力1。","每获得40快感，抽1张牌。","不判施法。按实际快感增加量累计，进度跨回合保留。"],"forced_edging":["淫魔法","能量＋1。","抽取2，失去20快感。","拘束面消耗20快感，施法失败全部返还。"],"forced_climax":["淫魔法","选择3张牌消耗，抽3张牌，获得30快感，然后触发一次高潮；这次高潮不改变快感值。","选择3张牌消耗，抽3张牌，获得30快感，然后触发一次高潮；这次高潮不改变快感值。","从本场抽牌堆、手牌、弃牌堆选择，不含自身。消耗。"],"supple_flesh":["技能","获得4点临时灵巧。","获得2点临时力量。","本回合有效，可叠加；两面可同时生效。"],"binding_power":["技能","获得⌊当前佩戴拘束具件数÷{bound_worn_divisor}⌋点临时力量，直到你的下回合结束前。{bound_worn_preview}","获得⌊当前佩戴拘束具件数÷{free_worn_divisor}⌋层蓄力。{free_worn_preview}","向下取整；复合拘束具整件计1件。"],"mana_attachment":["魔法／能力","获得1层蓄力。本场战斗中，成功打出技能牌时消耗5魔力，获得1层蓄力。","获得1层蓄力。本场战斗中，体术变为全体伤害，威力减半，每次额外消耗10魔力。","魔力不足时不触发。右键状态开关。"],"binding_search":["魔法／技能","抽{bound_body_draw}张牌{bound_body_preview}。X为有拘束具的非性器部位数，结果向下取整。","在非性器部位随机佩戴1件紧度2的中级拘束具，抽3张牌。","同一身体栏小部位只计1次。"],"kip_up":["技能","变为站姿。力量≥4时，本牌变为0费。","下一次腿部体术无视姿势限制。力量≥4时，本牌变为0费。","按当前总力量实时判断。腿部体术包括近身短打和各类踢击，按站姿招式发动，但不会因此站起；捕缚的强制姿势与起身顺序优先，其他限制照常。重复使用不叠加。"],"sympathetic_form":["能力","回合开始时，获得10点临时魔力与1能量。","回合开始时，若未佩戴非特殊装备的拘束具，恢复20魔力并获得10快感。",""],"formation":["能力","每回合第一张魔法牌必定成功。","每回合第一张魔法牌能量－1，最低0。","两面可同时生效。打出当回合立即获得次数，下回合刷新。0费牌也消耗次数。严密度仅在打出布阵时检查。"],"endless_war_goddess":["能力","耗尽自身与临时魔力（合计≥50）。本场战斗，基础动作无视拘束、快感与姿势限制。","耗尽自身与临时魔力（合计≥50）。本场战斗，基础动作无视拘束、快感与姿势限制。","火球术也无视拘束、快感与姿势限制。右键可切换所有踢击招式。使用动作仍需付费、等待冷却，并受每回合次数上限限制。"],"self_binding":["技能","随机收紧拘束具共2X档，不上锁。随后恢复15X自身魔力。空间不足时无法使用。","腿部随机佩戴2件拘束具，每件品质＋紧度＝2X。随后恢复15X自身魔力。空间不足时无法使用。","X为打出前的全部剩余能量。主动佩戴不触发闪避或蓄力抵挡，不替换已有装备。自由面X需为1—3；拘束面X＝0时无效果。复放沿用原X并重新检查空间。"],"prepared_chant":["魔法","{mana_cost}本回合施法成功率固定为100%。","{mana_cost}下回合施法成功率固定为100%。",""],"reuse":["能力","施法失败返还100%耗魔并获得1能量。0费牌每回合最多触发2次；当前佩戴紧度≥2的拘束具≥10件时不限次数，不计特殊装备。实时检测。","本次耗魔全部为临时魔力时，施法失败不返还魔力，改为获得1能量。0费牌每回合最多触发2次。","两面互斥。0费按本次实际能量费用判定；达到次数上限后恢复普通失败返还50%魔力。"],"confluence":["技能","每佩戴{bound_worn_divisor}件拘束具，本回合获得1点力量，不足{bound_worn_divisor}件不计。{bound_worn_preview}","每佩戴{free_worn_divisor}件拘束具，恢复{free_worn_amount}点魔力。{free_worn_preview}","按打出时的当前佩戴件数计算；复合拘束具整件计1件。力量可通过重复使用叠加，回合结束消失。"],"resonance":["能力","每佩戴一件拘束具，魔法耗魔－5%。","回合开始：闪避1。","减耗随当前佩戴件数变化，最低0。自由面从下回合生效，可叠加。"],"practiced":["能力","施法成功率最低75%。每次使用魔法牌，无论成败，额外牵扯1次。","每打出一张牌，本回合施法成功率额外＋3%。回合开始清零。","牵扯按1能量判定，不额外扣能量。两面可同时生效。"],"hannya_1":["技能","力量＋1，灵巧＋1，魔力＋5。正义飞踢费用＋1，获得打断，与坐姿踢击及并腿踢击共用3回合冷却。般若汤-其二加入弃牌堆。","力量＋1，灵巧＋1，魔力＋5。近身短打基础伤害＋2，连击每段基础伤害＋1。般若汤-其二加入弃牌堆。","升级时领取效果；当前等级详见出牌预览。"],"hannya_2":["技能","力量＋1，灵巧＋1，魔力＋5。0费消耗／虚无的身轻如燕加入手牌；般若汤-其三加入弃牌堆。","力量＋1，灵巧＋1，魔力＋5。0费消耗／虚无的身轻如燕加入手牌；般若汤-其三加入弃牌堆。","升级时领取效果；当前等级详见出牌预览。"],"hannya_3":["技能","力量＋1，灵巧＋1，魔力＋5。0费消耗／虚无的灌注加入手牌；般若汤-其四加入弃牌堆。","力量＋1，灵巧＋1，魔力＋5。0费消耗／虚无的灌注加入手牌；般若汤-其四加入弃牌堆。","升级时领取效果；当前等级详见出牌预览。"],"hannya_4":["技能","力量＋1，灵巧＋1，魔力＋5。虚无的完美henshin加入手牌；好汤喝够饮饮饮饮加入弃牌堆。","力量＋1，灵巧＋1，魔力＋5。虚无的完美henshin加入手牌；好汤喝够饮饮饮饮加入弃牌堆。","升级时领取效果；当前等级详见出牌预览。"],"good_soup":["技能","{mana_gain}","{mana_gain}","本场整备结束时移除。"],"hannya_swallow":["技能","下一次卡牌滑脱伤害×2。","闪避2。","本场整备结束时移除。"],"hannya_infusion":["魔法","{mana_cost}下一次腿部体术获得打断。","{mana_cost}下一次手部体术获得打断。","不与自带打断叠加。本场整备结束时移除。"],"hannya_henshin":["魔法","{mana_cost}解除全部拘束与捕缚。打出时播放dj版雨爱。","{mana_cost}本场全部伤害×2。打出时播放dj版雨爱。","同源不叠加。本场整备结束时移除。"],"siphon_strength":["魔法","{bound_batch}","{free_batch}",""],"shared_fate":["技能","将快感与魔力均设为两者总和的一半。","将快感与魔力均设为两者总和的一半。",""],"magic_hand_gift":["魔法","{mana_cost}降紧{hits}。超级顺延。","{mana_cost}{free_effects}","欧内的手赠予：使用后正常弃置。"],"magic_hand":["魔法","{mana_cost}降紧{hits}。超级顺延。","{mana_cost}{free_effects}",""],
 "leverage":["挣扎","造成拘束具数量×{worn_per_item}的挣扎伤害{dynamic_damage}。不计特殊装备。","{free_effects}",""],
 "light_as_swallow":["技能","下一次卡牌滑脱伤害×2。","获得2层闪避。",""],"breath_control":["滑脱","滑脱{base}×{hits}。选择并消耗1张手牌。","获得1层蓄力。下一次体术费用－1。选择并消耗1张手牌。","自由面需要嘴部自由。"],
 "restraint_embrace":["能力","每被佩戴1件拘束具，下回合抽1张牌。","每挣脱1件拘束具，抽1张牌，恢复1能量。抽牌与回能均可叠加。","从生效后开始计数；复合拘束具整件计1件，加固不计。敌人替换旧装备不算挣脱。两面可同时生效，抽牌与回能均可叠加；满手仍可回能。"],
 "binding_enthusiast":["能力","当前每件拘束具/性玩具：力量、灵巧＋1。使用拘束面牌时，快感固定＋10。","当前每件拘束具/性玩具：力量、灵巧＋1。使用拘束面牌时，快感固定＋10。","可叠加，属性加成与快感增长均叠加。复合拘束具整件计1件，连接绳与组件不计。"],
 "infusion":["魔法","{mana_cost}下一次腿部体术附加1层打断。","{mana_cost}下一次手部体术附加1层打断。","手部：肘击、近身短打。腿部：近身短打、各类踢击。同一面不叠加；对应体术使用后消耗，不与自带打断叠加。"],
 "concentration": ["技能","挣扎{base}。使用后，本场两面伤害＋{damage_growth}。","滑脱{base}。使用后，本场两面伤害＋{damage_growth}。","同一张牌的两面共享成长。"],
 "mana_circuit":["能力","每耗魔20：蓄力1。","每耗魔30：能量＋1。","自身及临时魔力均计入，失败施法也计入。各张独立累计，余数跨回合保留。"],
 "ready_to_strike":["魔法","{mana_cost}消耗一张指定手牌；{bound_effects}","{mana_cost}消耗一张指定手牌；{self_free_buff}","所选手牌仅在施法成功时消耗。体术包括肘击、近身短打及各类踢击，不包括火球术。减费不叠加。"],
 "crossed_legs":["滑脱","滑脱{base}。","{free_effects}",""],
 "mana_search":["技能","{bound_effects}","{self_free_effects}",""],
 "pot_of_greed":["技能","{bound_effects}","{self_free_effects}",""],
 "echo_cast":["技能","下张拘束面牌：复放1。双面相同不适用。","下次火球术：复放1。","同面可累计；下次触发消耗全部层数。原牌施法失败时保留拘束面复放。"],
 "embers":["魔法","本回合成功使用过火球术后可用。{mana_cost}抽牌1；魔力足够时再耗{optional_draw_cost}魔力、抽牌1。","{mana_cost}本回合火球术基础伤害＋4。","追加抽牌自动耗魔，不另判施法。火球强化不叠加。"],
 "wildfire_descent":["能力","{mana_cost}火球术施法成功时：抽牌1。","{mana_cost}火球术施法成功时：抽牌1。","可叠加。群攻每层触发一次。"],
 "adaptability":["能力","回合开始：蓄力1。","回合开始：获得1层魔力预备。","从下回合生效，可叠加。"],
 "rekindle":["魔法","{mana_cost}刷新本回合火球次数。","{mana_cost}刷新本回合火球次数。","包含炫火增加的次数。"],
 "fire_dynamics":["能力","火球术施法成功率＋30%。","火球改为全体攻击。","同面不叠加。群攻只施法一次；炫火自解仍为单目标。"],
 "fire_control":["技能","{bound_effects}","火球基础伤害永久＋{free_spell_bonus}。","加伤跨战保留。"],
 "siphon":["魔法","{mana_gain}","{mana_gain}{self_free_effects}",""],
 "mana_invocation":["魔法","{mana_gain}","{mana_gain}",""],
 "letter_opener":["能力","每使用3张技能牌：全部最外层拘束具挣扎3，仅乘倍率。","每使用3张技能牌：全体敌人受到5伤害。","可叠加，各张独立累计；跨回合保留，多段只计一张。"],
 "repeated_strain":["挣扎","挣扎{base}×{hits}。顺延。","{free_effects}",""],
 "boar_emperor_blaze":["挣扎","挣扎{base}×{hits}。超级顺延。无视紧度减伤。","{free_effects}",""],
 "flame_flourish":["能力","火球现在可以对拘束具使用,但是伤害减半","每回合火球次数＋1。","自由面次数可叠加，拘束面不叠加。敌人与拘束具共用次数。"],
 "fire_mastery":["能力","火球无视身体限制；不获得手势加成。","火球伤害×2。","同面不叠加；费用与快感施法概率不变。"],
 "strong_elbow":["挣扎","挣扎{base}。","下次肘击伤害×2。","对下一次肘击的所有段数生效。"],
 "pleasure_conversion":["转换","每20当前快感：能量＋1。","每20当前快感：能量＋1。","向下取整，不消耗快感。"],
 "mana_conversion":["魔法","{mana_cost}能量＋2。","{mana_gain}","固定兑换不受遗物施法返还影响；失败仍返还50%耗魔。"],
 "mana_surge":["魔法","{mana_cost}{bound_effects}","{mana_cost}{self_free_effects}",""],
 "henshin":["魔法","{mana_cost}解除全部拘束具与捕缚。打出时播放dj版雨爱。","{mana_cost}本场全部伤害×2。打出时播放dj版雨爱。","伤害加倍同源不叠加。"],
 "focus":["技能","{bound_effects}","{self_free_effects}",""],
 "tear":["挣扎","挣扎{base}。","{free_effects}","连带移除其他装备不会额外返还能量。"],
 "chain":["挣扎","挣扎{base}×{hits}。顺延。","{free_effects}",""],
 "peel":["滑脱","滑脱{base}×{hits}。顺延。","{free_effects}",""],
 "double_unlock":["魔法","{mana_cost}开锁至多{hits}。","{free_effects}",""],
 "panic":["诅咒","","",""],
 "sensitive":["诅咒","在手牌中：快感增长×{pleasure_multiplier}。","在手牌中：快感增长×{pleasure_multiplier}。","多张相乘，不影响快感降低。"],
 "lewd_mark":["诅咒","在手牌中：每次支付能量后，快感＋{energy_pressure}。","在手牌中：每次支付能量后，快感＋{energy_pressure}。","每次付费行动触发一次，零费不触发。"],
 "tease":["状态牌","回合结束仍在手中：快感＋5。","回合结束仍在手中：快感＋5。","战斗结束或被收押时消失。"],
 "tease_plus":["状态牌","回合结束仍在手中：快感＋8。","回合结束仍在手中：快感＋8。","战斗结束或被收押时消失。"],
 "strain":["挣扎","挣扎{base}。","{free_effects}","按该部位最高紧度选择目标；并列时先处理其中最内层。"],
 "slip":["滑脱","滑脱{base}。","{free_effects}","同层非最高紧度目标伤害减半。"],
 "ease":["魔法","{mana_cost}降紧1。","{free_effects}",""],
 "unlock":["魔法","{mana_cost}开锁1。","{free_effects}",""],
 "brace":["挣扎","挣扎{base}。","{free_effects}",""],
 "inch":["滑脱","滑脱{base}。","{free_effects}",""],
 "magic_slip":["魔法","{mana_cost}魔法滑脱{base}。","{free_effects}",""]
}

static func card_info(type: String, mana: Variant=null, base: Variant=null, inline_mana: bool=true, worn_count: Variant=null, body_count: Variant=null) -> Array:
 var rules=preload("res://data/card_rules.gd")
 var spec=rules.SPECS[type]
 var values={"follow_through":rules.FOLLOW_THROUGH_TEXT}
 if spec.has("worn_damage"):
  values.worn_per_item=str(spec.worn_damage.per_item)
  values.dynamic_damage="" if base==null or base is Dictionary else "（当前%s）" % str(base).trim_suffix(".0")
 for key in spec.get("hand_modifiers",{}): values[key]=str(spec.hand_modifiers[key]).trim_suffix(".0")
 for key in ["base","bonus","refund","hits","damage_growth"]:
  if spec.has(key): values[key]=str(spec[key]).trim_suffix(".0")
 if base!=null and not base is Dictionary: values.base=str(base).trim_suffix(".0")
 if spec.has("free_effects"):
  var effects=spec.free_effects.map(func(effect):return rules.effect_text(effect,spec,true))
  values.free_effects="；".join(effects)+("。" if not effects.is_empty() else "")
 if spec.has("self_faces"):
  for side in ["bound","free"]:
   var face=spec.self_faces[side]
   if face.has("body_draw_divisor"):
    values[side+"_body_draw"]="X/%d" % face.body_draw_divisor if body_count==null else str(int(int(body_count)/face.body_draw_divisor))
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
   if batch.has("mana_gain"): rewards.append("恢复%s魔力" % str(batch.mana_gain).trim_suffix(".0"))
   for effect in batch.get("effects",[]): rewards.append(rules.effect_text(effect,spec,false))
   values[side+"_batch"]="" if batch.is_empty() else "消耗手牌中全部%s牌。每消耗1张，%s。" % [rules.hand_batch_type_text(batch),"、".join(rewards)]
   values[side+"_spell_bonus"]=str(spec.self_faces[side].get("spell_base_bonus",{}).get("amount",0))
   values["bound_buff" if side=="bound" else "self_free_buff"]=rules.BUFFS.get(spec.self_faces[side].get("buff",""),{}).get("detail","")
   var effects=spec.self_faces[side].get("effects",[]).map(func(effect):return rules.effect_text(effect,spec,true))
   values["bound_effects" if side=="bound" else "self_free_effects"]="；".join(effects)+("。" if not effects.is_empty() else "")
 var result=CARD_INFO[type].duplicate()
 for index in range(result.size()):
  var free=index==2
  if base is Dictionary:
   var damage=base.get("free" if free else "bound",[])
   if not damage.is_empty():
    values.base=str(damage[0]).trim_suffix(".0")
    if spec.has("worn_damage"): values.dynamic_damage="（当前%s）" % values.base
    if damage.size()>1: result[index]=result[index].replace("{base}×{hits}",damage_sequence(damage))
  var face_mana=mana.get("free" if free else "bound") if mana is Dictionary else mana
  var cost=rules.face_mana_base(type,free,SPELL_COST) if face_mana==null else float(face_mana)
  var gain=float(spec.get("self_faces",{}).get("free" if free else "bound",{}).get("mana_gain",0))
  values.optional_draw_cost=String.num(float(spec.get("self_faces",{}).get("free" if free else "bound",{}).get("optional_draw",{}).get("mana_cost",0)),2).trim_suffix(".0")
  values.mana_cost=("耗魔"+(str(face_mana).trim_suffix(".0") if face_mana!=null else String.num(cost,2).trim_suffix(".0"))+"。") if inline_mana and cost>0 else ""
  values.mana_gain=("魔力＋"+String.num(gain,2).trim_suffix(".0")+"。") if inline_mana and gain>0 else ""
  result[index]=result[index].format(values)
 result[1]+=preload("res://data/card_rules.gd").effect_details(spec,true)
 var traits=CARD_TRAITS.get(type,{})
 for side in [1,2]:
  result[side]+=spec.get("play_music_text","")
  if traits.get("unplayable",false): result[side]="不可打出。"+result[side]
  if traits.get("retain",false): result[side]+="保留。"
  if rules.unique_face(type,side==2): result[side]+="唯一。"
  if rules.exhausts(type,side==2,traits): result[side]+="消耗。"
  if traits.get("ethereal",false): result[side]+="虚无。"
  if traits.get("innate",false): result[side]="固有。"+result[side]
 return result

# Compress equal consecutive hits without pretending limited Charge buffs every hit.
static func damage_sequence(values: Array) -> String:
 var groups=[]
 for value in values:
  if not groups.is_empty() and groups[-1].value==value: groups[-1].count+=1
  else: groups.append({"value":value,"count":1})
 return "＋".join(groups.map(func(group):return "%s×%d" % [str(group.value).trim_suffix(".0"),group.count]))

static func card_metadata(type: String, mana_costs: Dictionary={}, base: Variant=null, worn_count: Variant=null, body_count: Variant=null) -> Dictionary:
 var costs={}
 for side in ["bound","free"]: costs[side]=mana_costs.get(side,preload("res://data/card_rules.gd").face_mana_base(type,side=="free",SPELL_COST))
 var result=preload("res://data/card_text.gd").metadata(type,CARD_TRAITS.get(type,{}),SLOT_NAMES,costs,worn_count)
 var effects=card_info(type,costs,base,false,worn_count,body_count)
 result.face_effects={"bound":effects[1],"free":effects[2]}
 return result

static func keyword_ids(type: String, free: bool) -> Array:
 return preload("res://data/card_text.gd").keyword_ids(type,free,CARD_TRAITS.get(type,{}))
