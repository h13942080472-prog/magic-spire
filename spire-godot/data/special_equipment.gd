extends RefCounted
const RestraintValue=preload("res://data/restraint_value.gd")

const BATTERY_TURNS={1:6,2:9,3:12}

# Sexual equipment remains an independent equipment family. Stable special_* ids
# are retained for saves and targeting; only player-facing anatomy is named here.
const REGIONS=[
 {"id":"special_1","name":"乳头","slots":["special_1_a"]},
 {"id":"special_2","name":"肉棒","slots":["special_2_a","special_2_b","special_2_c","special_2_d"]},
 {"id":"special_3","name":"双穴","slots":["special_3_a","special_3_b"]}]
const SLOT_NAMES={
 "special_1_a":"乳头",
 "special_2_a":"柱身",
 "special_2_b":"龟头",
 "special_2_c":"冠沟",
 "special_2_d":"马眼",
 "special_3_a":"小穴",
 "special_3_b":"后庭"}
const SENSITIVITY={
 "special_1_a":1.0,
 "special_2_a":0.6,
 "special_2_b":1.5,
 "special_2_c":1.5,
 "special_2_d":1.5,
 "special_3_a":1.0,
 "special_3_b":1.0}
const CAPACITIES={"special_1_a":2,"special_2_a":2,"special_2_b":2,"special_2_c":2,"special_2_d":1,"special_3_a":1,"special_3_b":1}
const PHYSICAL_METHODS=["strain","slip","magic_slip","lower"]
const MANUAL_ONLY=["manual"]
const Environments=preload("res://data/environments.gd")
const ALL_ENVIRONMENTS=Environments.CLASSES
const ENVIRONMENT_NAMES=Environments.NAMES
const INSTANCE_FIELDS=["id","template","type","slot","coverage","contact_slots","remaining","name","grade","maximum","durability","locked","layer","material","variant","owner_id"]
const OPTIONAL_INSTANCE_FIELDS=["reinforcement_state"]
const CLIMAX_SLIP_BASE=6.0
const CHASTITY_FAMILY="chastity_lock"
const CURSED_VIBRATOR_TURNS=6
const CHASTITY_CLIMAX_FACTOR_LIMIT=10
const CHASTITY_TYPES=["negative_plate_lock_medium","negative_plate_lock_catheter_medium","negative_vibrator_lock_catheter_high","cursed_plate_lock"]
const CURSED_PLATE_REASON="诅咒平板锁只能用下一个Boss掉落的专属钥匙解除。"
const CHASTITY_COMPONENTS=["chastity_reinforcement_medium","chastity_reinforcement_high"]
const CUP_REINFORCEMENT_FAMILIES=["full_cup","urethral_full_cup"]
const CUP_COMPONENTS=["cup_reinforcement_medium","cup_reinforcement_high"]
const REINFORCEMENT_COMPONENTS=CHASTITY_COMPONENTS+CUP_COMPONENTS

# Explicit enemy/event generation pools. Cup families are authored equipment but
# never random results; the external wand starts at medium grade.
const RANDOM_POOLS={
 1:["nipple_clamp_low","nipple_ring_low","shaft_ring_low","corona_ring_low","urethral_rod_low","vaginal_egg_low","anal_egg_low","crotch_rope_low"],
 2:["nipple_clamp_medium","nipple_ring_medium","shaft_ring_medium","corona_ring_medium","urethral_rod_medium","vaginal_egg_medium","anal_egg_medium","external_wand_medium","crotch_rope_medium","negative_plate_lock_medium","negative_plate_lock_catheter_medium"],
 3:["negative_vibrator_lock_catheter_high"]}
const CUP_FAMILIES=["glans_cup","full_cup","urethral_full_cup","forced_milking_cup"]

# Reusable event prose. Every concrete type receives its displayed name here so
# event authors never have to invent a generic "sex toy was equipped" sentence.
const WEAR_TEXTS={
 "nipple_clamp":"指尖捏住两侧乳头，将「{name}」的夹口分别扣紧。两枚震动夹咬住乳头，开关亮起后便贴着乳肉持续颤动。",
 "nipple_ring":"两侧乳头被揉得挺起，「{name}」逐一套上乳尖，在根部紧紧收住。震动沿着硅胶环贴上乳头，随身体扭动仍牢牢固定。",
 "shaft_ring":"「{name}」被撑开后缓缓套过龟头，一直推到柱身中段。硅胶环贴着肉棒收紧，启动后便隔着表皮持续震动。",
 "corona_ring":"「{name}」沿着龟头慢慢套下，在冠沟处紧紧收住。震动环贴着最敏感的一圈持续颤动，每次肉棒跳动都会被它重新磨过。",
 "urethral_rod":"马眼被指尖轻轻分开，涂过润滑的「{name}」随即缓缓送进尿道。细密颗粒贴着内壁一路没入，肉棒正面显出清楚的棒身轮廓，只有拉环留在马眼外面。",
 "vaginal_egg":"双腿被分开后，涂过润滑的「{name}」抵住小穴，一点点推入深处。跳蛋整个滑进穴内，开关亮起时，震动立刻从体内扩散开来。",
 "anal_egg":"臀肉被分开，涂满润滑的「{name}」抵住后庭，缓缓挤过收紧的入口。跳蛋整个没入体内，启动后的震动随即贴着后庭深处一阵阵传开。",
 "external_wand":"「{name}」的圆头贴住小穴外侧，固定带从胯下绕过腰臀逐一扣紧。按摩棒被牢牢压在原处，启动后持续隔着湿润的缝隙震动。",
 "crotch_rope":"「{name}」从腰后绕来，绳股贴着胯下穿过双穴之间，再向上收紧打结。粗糙的绳身嵌在小穴外侧，身体稍一活动便会被来回磨过。",
 "glans_cup":"「{name}」罩住龟头与冠沟，柔软内衬贴着敏感处合拢，外侧固定带随即扣紧。杯体启动后便裹住龟头持续抽送，将肉棒牢牢固定在里面。",
 "full_cup":"「{name}」从龟头一路套到根部，将柱身、龟头和冠沟全部包进湿软内腔。外壳在根部扣紧，启动后整段肉棒都被内衬反复套弄。",
 "urethral_full_cup":"内置马眼棒先被缓缓送进尿道，「{name}」随后从龟头一直套到根部。杯体扣紧后，尿道内的颗粒与包住肉棒的湿软内衬同时开始动作。",
 "forced_milking_cup":"「{name}」套住整根肉棒，皮革固定带绕过腰臀逐条扣紧，将杯体牢牢锁在胯间。机关启动后，湿软内腔便沿着柱身持续抽送，无法靠夹腿或后退将它甩开。"}

# Current-wear prose is deliberately separate from installation prose. It is
# shared by the equipment detail and the compact stimulation status, while the
# latter omits removal instructions supplied by the action UI.
const STIMULATION_TEXTS={
 "nipple_clamp":"两枚夹口紧紧咬住乳头，震动持续贴着乳尖传进乳房。",
 "nipple_ring":"硅胶环紧套在乳头根部，震动沿着挺起的乳尖持续传开。",
 "shaft_ring":"硅胶环箍在柱身中段，肉棒每次跳动都会重新蹭过震动的环身。",
 "corona_ring":"震动环紧贴冠沟，沿着龟头下方最敏感的一圈持续摩擦。",
 "urethral_rod":"马眼棒插在尿道内，棒身的凸粒隔着肉棒正面清楚鼓起；肉棒一有动作，尿道内壁与外侧突起便会同时受到摩擦。",
 "vaginal_egg":"跳蛋完全没入小穴，震动紧贴穴内软肉持续传开。",
 "anal_egg":"跳蛋塞在后庭深处，震动贴着收紧的内壁持续扩散。",
 "external_wand":"固定带把按摩棒的圆头牢牢压在小穴外侧，身体稍一挪动，震动便会贴着湿润的缝隙来回摩擦。",
 "crotch_rope":"绳股紧贴胯下，从小穴与后庭之间勒过；每次行动都会带动绳身来回摩擦小穴，后庭只被绳索贴住。",
 "glans_cup":"湿软内衬紧紧包住龟头与冠沟，杯体启动后便沿着最敏感的一圈反复抽送。",
 "full_cup":"湿软内腔从龟头一直包到根部，启动后沿着整段肉棒反复套弄。",
 "urethral_full_cup":"杯体包住整根肉棒，内置马眼棒同时贴着尿道内壁动作，内外刺激一起传来。",
 "forced_milking_cup":"飞机杯套住整根肉棒，腰臀间的固定带让杯体无法被甩开，湿软内腔持续沿着柱身抽送。"}

static func _chastity_type(name: String, catheter: bool, vibrator: bool=false) -> Dictionary:
 var slots=["special_2_a","special_2_b","special_2_c"]
 if catheter: slots.append("special_2_d")
 return {"name":name,"family":CHASTITY_FAMILY,"energy_gain":8.0 if vibrator else (6.0 if catheter else 0.0),"turn_gain":12.0 if vibrator else 0.0,"duration":BATTERY_TURNS[3] if vibrator else 0,"stimulates":["special_2_d"] if catheter else [],"turn_stimulates":slots.duplicate() if vibrator else [],"turn_stimulus_factor":0.4 if vibrator else 1.0,"material_text":"魔导金属与硅胶","detail":"自动上锁的复合性玩具；开锁后受到任意正数挣扎或滑脱伤害便会整件解除，无视加固带。","wear_text":"「%s」合拢包住柱身、龟头与冠沟，锁芯随即自动扣死。" % name,"integrated_catheter":catheter,"integrated_vibrator":vibrator}

static func _reinforcement_type(name: String, owner_name: String) -> Dictionary:
 return {"name":name,"family":name,"energy_gain":0.0,"turn_gain":0.0,"duration":0,"stimulates":[],"material_text":"加固皮带与金属扣","detail":"%s达到紧度3档时自动附加的独立固定带；只能用切割类道具破坏。" % owner_name,"wear_text":"","component_only":true}

static func _wear_text(name: String, family: String) -> String:
 return str(WEAR_TEXTS.get(family,"将「{name}」佩戴到相应位置。")).replace("{name}",name)

static func _type(name: String, family: String, energy_gain: float, turn_gain: float, duration: int, stimulates: Array, material_text: String, detail: String) -> Dictionary:
 var result={"name":name,"family":family,"energy_gain":energy_gain,"turn_gain":turn_gain,"duration":duration,"stimulates":stimulates,"material_text":material_text,"detail":detail,"wear_text":_wear_text(name,family)}
 if family=="urethral_rod": result.climax_slip_base=CLIMAX_SLIP_BASE
 return result

static func _design(grade: int, covered_slots: Array, environments: Array, material: String="plastic", methods: Array=PHYSICAL_METHODS, capacity_cost: int=1) -> Dictionary:
 return {"grade":grade,"maximum":{1:10.0,2:16.0,3:24.0}[grade],"ratio":0.8,"slots":covered_slots,"methods":methods.duplicate(),"tools":["shard","saw"] if "sharp" in environments else [],"environments":environments,"damage_factor":1.0,"material":material,"capacity_cost":capacity_cost}

# Amounts are base pleasure before the stimulated-position sensitivity multiplier.
# Powered equipment uses 6/9/12 player-turn starts for low/medium/high batteries.
static var TYPES={
 "nipple_clamp_low":_type("初级无线乳夹跳蛋","nipple_clamp",0,6,BATTERY_TURNS[1],["special_1_a"],"金属与硅胶","夹在乳头上的无线震动夹。"),
 "nipple_clamp_medium":_type("中级无线乳夹跳蛋","nipple_clamp",0,8,BATTERY_TURNS[2],["special_1_a"],"金属与硅胶","夹在乳头上的无线震动夹。"),
 "nipple_clamp_high":_type("高级无线乳夹跳蛋","nipple_clamp",0,10,BATTERY_TURNS[3],["special_1_a"],"金属与硅胶","夹在乳头上的无线震动夹。"),
 "nipple_ring_low":_type("初级硅胶乳头震动环","nipple_ring",0,5,BATTERY_TURNS[1],["special_1_a"],"柔软硅胶","环绕乳头持续震动。"),
 "nipple_ring_medium":_type("中级硅胶乳头震动环","nipple_ring",0,7,BATTERY_TURNS[2],["special_1_a"],"柔软硅胶","环绕乳头持续震动。"),
 "nipple_ring_high":_type("高级硅胶乳头震动环","nipple_ring",0,9,BATTERY_TURNS[3],["special_1_a"],"柔软硅胶","环绕乳头持续震动。"),
 "shaft_ring_low":_type("初级硅胶柱身震动环","shaft_ring",0,4,BATTERY_TURNS[1],["special_2_a"],"柔软硅胶","套在柱身上的震动环。"),
 "shaft_ring_medium":_type("中级硅胶柱身震动环","shaft_ring",0,5,BATTERY_TURNS[2],["special_2_a"],"柔软硅胶","套在柱身上的震动环。"),
 "shaft_ring_high":_type("高级硅胶柱身震动环","shaft_ring",0,6,BATTERY_TURNS[3],["special_2_a"],"柔软硅胶","套在柱身上的震动环。"),
 "corona_ring_low":_type("初级硅胶冠沟震动环","corona_ring",0,6,BATTERY_TURNS[1],["special_2_c"],"柔软硅胶","固定在冠沟位置的震动环。"),
 "corona_ring_medium":_type("中级硅胶冠沟震动环","corona_ring",0,8,BATTERY_TURNS[2],["special_2_c"],"柔软硅胶","固定在冠沟位置的震动环。"),
 "corona_ring_high":_type("高级硅胶冠沟震动环","corona_ring",0,10,BATTERY_TURNS[3],["special_2_c"],"柔软硅胶","固定在冠沟位置的震动环。"),
 "urethral_rod_low":_type("5毫米×10厘米硅胶马眼棒","urethral_rod",4,0,0,["special_2_d"],"医用硅胶","细短的初级马眼棒插入浅段，表面只有少量细颗粒；行动时产生刺激。"),
 "urethral_rod_medium":_type("8毫米×20厘米硅胶马眼棒","urethral_rod",6,0,0,["special_2_d"],"医用硅胶","更粗更长的中级马眼棒深入中段，表面颗粒更多；行动时产生刺激。"),
 "urethral_rod_high":_type("10毫米×30厘米硅胶马眼棒","urethral_rod",8,0,0,["special_2_d"],"医用硅胶","最粗最长的高级马眼棒深入至最深处，表面颗粒最密；行动时产生刺激。"),
 "vaginal_egg_low":_type("初级无线阴道跳蛋","vaginal_egg",0,8,BATTERY_TURNS[1],["special_3_a"],"柔软硅胶","置于小穴内的无线跳蛋。"),
 "vaginal_egg_medium":_type("中级无线阴道跳蛋","vaginal_egg",0,10,BATTERY_TURNS[2],["special_3_a"],"柔软硅胶","置于小穴内的无线跳蛋。"),
 "vaginal_egg_high":_type("高级无线阴道跳蛋","vaginal_egg",0,12,BATTERY_TURNS[3],["special_3_a"],"柔软硅胶","置于小穴内的无线跳蛋。"),
 "anal_egg_low":_type("初级无线后庭跳蛋","anal_egg",0,7,BATTERY_TURNS[1],["special_3_b"],"柔软硅胶","置于后庭内的无线跳蛋。"),
 "anal_egg_medium":_type("中级无线后庭跳蛋","anal_egg",0,9,BATTERY_TURNS[2],["special_3_b"],"柔软硅胶","置于后庭内的无线跳蛋。"),
 "anal_egg_high":_type("高级无线后庭跳蛋","anal_egg",0,11,BATTERY_TURNS[3],["special_3_b"],"柔软硅胶","置于后庭内的无线跳蛋。"),
 "external_wand_low":_type("初级外置震动按摩棒","external_wand",0,10,BATTERY_TURNS[1],["special_3_a"],"硅胶与塑料","由外部固定件压在小穴上的按摩棒。"),
 "external_wand_medium":_type("中级外置震动按摩棒","external_wand",0,12,BATTERY_TURNS[2],["special_3_a"],"硅胶与塑料","由外部固定件压在小穴上的按摩棒。"),
 "external_wand_high":_type("高级外置震动按摩棒","external_wand",0,15,BATTERY_TURNS[3],["special_3_a"],"硅胶与塑料","由外部固定件压在小穴上的按摩棒。"),
 "crotch_rope_low":_type("初级裆部股绳","crotch_rope",3,0,0,["special_3_a"],"粗劣麻绳","同时经过双穴区域，但只刺激小穴。"),
 "crotch_rope_medium":_type("中级裆部股绳","crotch_rope",5,0,0,["special_3_a"],"尼龙绳","同时经过双穴区域，但只刺激小穴。"),
 "crotch_rope_high":_type("高级裆部股绳","crotch_rope",7,0,0,["special_3_a"],"魔导纤维绳","同时经过双穴区域，但只刺激小穴。"),
 "glans_cup_medium":_type("中级龟头榨精杯","glans_cup",2,8,BATTERY_TURNS[2],["special_2_b","special_2_c"],"硅胶与塑料","包覆龟头和冠沟的主动榨精杯。"),
 "glans_cup_high":_type("高级龟头榨精杯","glans_cup",3,11,BATTERY_TURNS[3],["special_2_b","special_2_c"],"硅胶与塑料","包覆龟头和冠沟的主动榨精杯。"),
 "full_cup_medium":_type("中级全包榨精杯","full_cup",4,11,BATTERY_TURNS[2],["special_2_a","special_2_b","special_2_c"],"硅胶与塑料","完整包覆柱身、龟头和冠沟。"),
 "full_cup_high":_type("高级全包榨精杯","full_cup",6,14,BATTERY_TURNS[3],["special_2_a","special_2_b","special_2_c"],"硅胶与塑料","完整包覆柱身、龟头和冠沟。"),
 "urethral_full_cup_medium":_type("中级马眼全包榨精杯","urethral_full_cup",6,14,BATTERY_TURNS[2],["special_2_a","special_2_b","special_2_c","special_2_d"],"硅胶与塑料","全包榨精杯内整合中级马眼组件。"),
 "urethral_full_cup_high":_type("高级马眼全包榨精杯","urethral_full_cup",8,18,BATTERY_TURNS[3],["special_2_a","special_2_b","special_2_c","special_2_d"],"硅胶与塑料","全包榨精杯内整合高级马眼组件。"),
 "forced_milking_cup_high":_type("高级强制榨精飞机杯","forced_milking_cup",8,16,0,["special_2_a","special_2_b","special_2_c"],"硅胶、塑料与皮革","由固定结构持续驱动。")}

static func _add_chastity_types() -> void:
 if TYPES.has("negative_plate_lock_medium"): return
 TYPES.negative_plate_lock_medium=_chastity_type("负数平板锁",false)
 TYPES.negative_plate_lock_catheter_medium=_chastity_type("负数平板锁（导尿管）",true)
 TYPES.negative_vibrator_lock_catheter_high=_chastity_type("负数跳蛋锁（导尿管）",true,true)
 TYPES.cursed_plate_lock=TYPES.negative_vibrator_lock_catheter_high.duplicate(true)
 TYPES.cursed_plate_lock.name="诅咒平板锁"
 TYPES.cursed_plate_lock.duration=0
 TYPES.cursed_plate_lock.relic_only=true
 TYPES.cursed_plate_lock.detail="高级、紧度3档。默认跳蛋每场只在前6回合生效，高潮保留系数最高10；抖M专用版持续生效。解除需要专属钥匙；击败下一个Boss后自动取下整件。"
 TYPES.cursed_plate_lock.wear_text="诅咒平板锁已佩戴并上锁。"
 TYPES.chastity_reinforcement_medium=_reinforcement_type("中级平板锁加固带","平板锁")
 TYPES.chastity_reinforcement_high=_reinforcement_type("高级平板锁加固带","平板锁")
 TYPES.cup_reinforcement_medium=_reinforcement_type("中级榨精杯固定带","全包榨精杯")
 TYPES.cup_reinforcement_high=_reinforcement_type("高级榨精杯固定带","全包榨精杯")

static var DESIGNS={
 "nipple_clamp_low":_design(1,["special_1_a"],["hook","wall"],"metal"),
 "nipple_clamp_medium":_design(2,["special_1_a"],["hook","wall"],"metal"),
 "nipple_clamp_high":_design(3,["special_1_a"],["hook","wall"],"metal"),
 "nipple_ring_low":_design(1,["special_1_a"],["hook","sharp"]),
 "nipple_ring_medium":_design(2,["special_1_a"],["hook","sharp"]),
 "nipple_ring_high":_design(3,["special_1_a"],["hook","sharp"]),
 "shaft_ring_low":_design(1,["special_2_a"],ALL_ENVIRONMENTS),
 "shaft_ring_medium":_design(2,["special_2_a"],ALL_ENVIRONMENTS),
 "shaft_ring_high":_design(3,["special_2_a"],ALL_ENVIRONMENTS),
 "corona_ring_low":_design(1,["special_2_c"],ALL_ENVIRONMENTS),
 "corona_ring_medium":_design(2,["special_2_c"],ALL_ENVIRONMENTS),
 "corona_ring_high":_design(3,["special_2_c"],ALL_ENVIRONMENTS),
 "urethral_rod_low":_design(1,["special_2_d"],["hook"]),
 "urethral_rod_medium":_design(2,["special_2_d"],["hook"]),
 "urethral_rod_high":_design(3,["special_2_d"],["hook"]),
 "vaginal_egg_low":_design(1,["special_3_a"],[],"plastic",MANUAL_ONLY),
 "vaginal_egg_medium":_design(2,["special_3_a"],[],"plastic",MANUAL_ONLY),
 "vaginal_egg_high":_design(3,["special_3_a"],[],"plastic",MANUAL_ONLY),
 "anal_egg_low":_design(1,["special_3_b"],[],"plastic",MANUAL_ONLY),
 "anal_egg_medium":_design(2,["special_3_b"],[],"plastic",MANUAL_ONLY),
 "anal_egg_high":_design(3,["special_3_b"],[],"plastic",MANUAL_ONLY),
 "external_wand_low":_design(1,["special_3_a"],ALL_ENVIRONMENTS),
 "external_wand_medium":_design(2,["special_3_a"],ALL_ENVIRONMENTS),
 "external_wand_high":_design(3,["special_3_a"],ALL_ENVIRONMENTS),
 "crotch_rope_low":_design(1,["special_3_a","special_3_b"],ALL_ENVIRONMENTS,"rope",PHYSICAL_METHODS,0),
 "crotch_rope_medium":_design(2,["special_3_a","special_3_b"],ALL_ENVIRONMENTS,"rope",PHYSICAL_METHODS,0),
 "crotch_rope_high":_design(3,["special_3_a","special_3_b"],ALL_ENVIRONMENTS,"rope",PHYSICAL_METHODS,0),
 "glans_cup_medium":_design(2,["special_2_b","special_2_c"],["hook","wall"]),
 "glans_cup_high":_design(3,["special_2_b","special_2_c"],["hook","wall"]),
 "full_cup_medium":_design(2,["special_2_a","special_2_b","special_2_c"],["hook","wall"]),
 "full_cup_high":_design(3,["special_2_a","special_2_b","special_2_c"],["hook","wall"]),
 "urethral_full_cup_medium":_design(2,["special_2_a","special_2_b","special_2_c","special_2_d"],["hook","wall"]),
 "urethral_full_cup_high":_design(3,["special_2_a","special_2_b","special_2_c","special_2_d"],["hook","wall"]),
 "forced_milking_cup_high":_design(3,["special_2_a","special_2_b","special_2_c"],["hook","wall"],"leather")}

static func _add_chastity_designs() -> void:
 if DESIGNS.has("negative_plate_lock_medium"): return
 DESIGNS.negative_plate_lock_medium=_design(2,["special_2_a","special_2_b","special_2_c"],[],"metal",["strain","slip","magic_slip","unlock"],1)
 DESIGNS.negative_plate_lock_catheter_medium=_design(2,["special_2_a","special_2_b","special_2_c","special_2_d"],[],"metal",["strain","slip","magic_slip","unlock"],1)
 DESIGNS.negative_vibrator_lock_catheter_high=_design(3,["special_2_a","special_2_b","special_2_c","special_2_d"],[],"metal",["strain","slip","magic_slip","unlock"],1)
 DESIGNS.cursed_plate_lock=DESIGNS.negative_vibrator_lock_catheter_high.duplicate(true)
 DESIGNS.chastity_reinforcement_medium=_design(2,["special_2_a","special_2_b","special_2_c"],["sharp"],"leather",["strain","slip"],0)
 DESIGNS.chastity_reinforcement_high=_design(3,["special_2_a","special_2_b","special_2_c"],["sharp"],"leather",["strain","slip"],0)
 DESIGNS.cup_reinforcement_medium=_design(2,["special_2_a","special_2_b","special_2_c"],["sharp"],"leather",["strain","slip"],0)
 DESIGNS.cup_reinforcement_high=_design(3,["special_2_a","special_2_b","special_2_c"],["sharp"],"leather",["strain","slip"],0)
 for type in REINFORCEMENT_COMPONENTS: DESIGNS[type].tools=["shard","saw"]

static func ensure_catalog() -> void:
 _add_chastity_types();_add_chastity_designs()

# Prison selection is separate from enemy/event pools. It keeps crotch ropes,
# follows the current security grade, and admits cup families from security 3.
static func prison_pool(grade: int, cups: bool, include_chastity: bool=false) -> Array:
 ensure_catalog()
 var result=[]
 for type in DESIGNS:
  if DESIGNS[type].grade!=grade: continue
  var family=TYPES[type].family
  if TYPES[type].get("component_only",false) or TYPES[type].get("relic_only",false): continue
  if is_chastity_type(type) and not include_chastity: continue
  if family=="external_wand" and grade==1: continue
  if family in CUP_FAMILIES and not cups: continue
  result.append(type)
 result.sort()
 return result

static func is_special(item: Dictionary) -> bool:
 return item.get("template","")=="special"

static func exclusive_family(type: String) -> String:
 var family=TYPES[type].family
 return "cup" if family in CUP_FAMILIES else family

static func is_chastity_type(type: String) -> bool:
 return type in CHASTITY_TYPES

static func catheter_type(type: String) -> bool:
 ensure_catalog()
 return is_chastity_type(type) and TYPES[type].get("integrated_catheter",false)

static func chastity_rank(type: String) -> Array:
 ensure_catalog()
 if not is_chastity_type(type): return [-1,-1]
 return [int(DESIGNS[type].grade),int(TYPES[type].get("integrated_catheter",false))+int(TYPES[type].get("integrated_vibrator",false))]

static func can_upgrade(old_type: String, incoming_type: String) -> bool:
 if not is_chastity_type(old_type) or not is_chastity_type(incoming_type) or old_type==incoming_type: return false
 if old_type=="cursed_plate_lock": return false
 if incoming_type=="cursed_plate_lock": return true
 var old=chastity_rank(old_type);var incoming=chastity_rank(incoming_type)
 return incoming[0]>old[0] or incoming[1]>old[1]

static func is_chastity(item: Dictionary) -> bool:
 return is_special(item) and is_chastity_type(item.get("type",""))

static func is_cursed_plate(item: Dictionary) -> bool:
 return is_special(item) and item.get("type","")=="cursed_plate_lock"

static func is_reinforcement(item: Dictionary) -> bool:
 return is_special(item) and item.get("type","") in REINFORCEMENT_COMPONENTS

static func is_chastity_reinforcement(item: Dictionary) -> bool:
 return is_special(item) and item.get("type","") in CHASTITY_COMPONENTS

static func is_cup_reinforcement(item: Dictionary) -> bool:
 return is_special(item) and item.get("type","") in CUP_COMPONENTS

static func is_reinforced_cup(item: Dictionary) -> bool:
 return is_special(item) and TYPES.get(item.get("type",""),{}).get("family","") in CUP_REINFORCEMENT_FAMILIES

static func supports_reinforcement(item: Dictionary) -> bool:
 return is_chastity(item) or is_reinforced_cup(item)

static func reinforcement_type(owner: Dictionary) -> String:
 if is_chastity(owner): return "chastity_reinforcement_high" if owner.grade==3 else "chastity_reinforcement_medium"
 if is_reinforced_cup(owner): return "cup_reinforcement_high" if owner.grade==3 else "cup_reinforcement_medium"
 return ""

static func reinforcement_matches(component: Dictionary, owner: Dictionary) -> bool:
 return component.get("owner_id","")==owner.get("id","") and ((is_chastity_reinforcement(component) and is_chastity(owner)) or (is_cup_reinforcement(component) and is_reinforced_cup(owner)))

static func migrate_reinforcement_state(items: Array) -> void:
 ensure_catalog()
 var valid=items.filter(func(item):return item is Dictionary)
 for owner in valid:
  if not supports_reinforcement(owner) or owner.has("reinforcement_state"): continue
  var straps=valid.filter(func(item):return reinforcement_matches(item,owner))
  owner.reinforcement_state="active" if straps.size()==1 else "none"
  # Older cups had no band at any tightness; loading must not add a new restraint.
  if straps.is_empty() and is_reinforced_cup(owner) and float(owner.get("durability",0))>float(owner.get("maximum",0))*0.80000001: owner.reinforcement_state="removed"

static func catheter(item: Dictionary) -> bool:
 return is_chastity(item) and TYPES[item.type].get("integrated_catheter",false)

static func portrait_layers(items: Array) -> Array:
 ensure_catalog()
 var layers=[]
 var has_chastity=items.any(func(item):return item.get("durability",0)>0 and is_chastity(item))
 if has_chastity:
  layers.append("flat_lock")
 if items.any(func(item):return item.get("durability",0)>0 and is_chastity_reinforcement(item)):
  layers.append("flat_lock_reinforcement")
 var has_urethral=items.any(func(item):return item.get("durability",0)>0 and (catheter(item) or TYPES.get(item.get("type",""),{}).get("family","")=="urethral_rod"))
 if has_chastity and has_urethral:
  layers.append("urethral_rod")
 if items.any(func(item):return item.get("durability",0)>0 and TYPES.get(item.get("type",""),{}).get("family","")=="crotch_rope"):
  layers.append("crotch_rope")
 return layers

static func generation_pool(types: Array, include_chastity: bool) -> Array:
 ensure_catalog()
 return types.filter(func(type):return not TYPES.get(type,{}).get("relic_only",false) and (include_chastity or not is_chastity_type(type)))

static func allows(item: Dictionary, method: String) -> bool:
 if is_chastity(item) and method=="strain": return unlocked_release(item,method)
 return DESIGNS.has(item.get("type","")) and method in DESIGNS[item.type].methods

# Shared by eligibility, damage resolution and the read-only release projection.
static func unlocked_release(item: Dictionary, method: String) -> bool:
 return is_chastity(item) and not is_cursed_plate(item) and not item.get("locked",true) and method in ["strain","slip","magic_slip"]

static func capacity(slot: String) -> int:
 return CAPACITIES.get(slot,0)

static func occupied_slots(item: Dictionary) -> Array:
 return DESIGNS.get(item.get("type",""),{}).get("slots",[])

static func occupies(item: Dictionary, slot: String) -> bool:
 return slot in occupied_slots(item)

static func capacity_cost(item_or_type) -> int:
 var type=item_or_type.type if item_or_type is Dictionary else str(item_or_type)
 return int(DESIGNS.get(type,{}).get("capacity_cost",1))

static func used_capacity(items: Array, slot: String) -> int:
 var used=0
 for item in items:
  if occupies(item,slot): used+=capacity_cost(item)
 return used

static func method_reason(item: Dictionary, method: String) -> String:
 if allows(item,method): return ""
 if is_chastity(item) and method=="strain": return CURSED_PLATE_REASON if is_cursed_plate(item) else "平板锁仍上锁，先开锁才能挣扎取下。"
 if TYPES.get(item.get("type",""),{}).get("family","") in ["vaginal_egg","anal_egg"]:
  return item.name+"双臂和双手完全自由后，可直接取出。"
 if method=="hook" and "hook" in DESIGNS.get(item.get("type",""),{}).get("environments",[]):
  return "挂钩为挣脱牌提供环境条件，需出牌削减耐久。"
 return item.name+"请选择适用的解除方法。"

static func environment_contact(g, item: Dictionary, environment: String) -> bool:
 if environment=="sharp": return g.state.items.any(func(tool):return tool.uses>0 and tool_reason(g,item,tool)=="")
 if not g.at_wall() or environment not in DESIGNS[item.type].environments: return false
 if environment=="wall": return Environments.WALLS.get(g.state.wall,"")==environment
 if not g.wall_contact(): return false
 if environment=="hook": return Environments.HOOK_CLASS==environment and g.state.phase=="rest" and g.state.hook_uses>0 and occupied_slots(item).any(func(slot):return slot in g.Tools.height_points(g,g.Tools.HOOK_MOUNT))
 return false

static func mounted_contact(g, item: Dictionary, tool: Dictionary) -> bool:
 if g.Tools.assisted(g): return true
 if g.Prison.Space.mounted_reason(g,tool)!="": return false
 return occupied_slots(item).any(func(slot):return slot in g.Tools.reach(g,tool))

static func escape_reason(g, item: Dictionary, method: String, hands: Array) -> String:
 if is_cursed_plate(item): return CURSED_PLATE_REASON
 var issue=method_reason(item,method)
 if issue!="": return issue
 if is_reinforcement(item):
  return "" if environment_contact(g,item,"sharp") else "固定带只能借助已安装且能够接触该部位的切割类道具处理。"
 if method not in ["strain","slip"]: return ""
 if not hands.is_empty(): return ""
 for environment in DESIGNS[item.type].environments:
  if environment_contact(g,item,environment): return ""
 var names=DESIGNS[item.type].environments.map(func(environment):return ENVIRONMENT_NAMES[environment])
 return "手腕受限，无法用手处理；需要接触"+"、".join(names)+"中的一种环境，才能使用这张牌。"

static func manual_reason(g, item: Dictionary) -> String:
 if not allows(item,"manual"): return method_reason(item,"manual")
 if g.level("arms")!=0 or g.occupied("wrist") or g.occupied("palm") or g.occupied("fingers"):
  return "必须先让双臂、双腕和双手完全自由，才能直接取出。"
 return ""

static func tool_reason(g, item: Dictionary, tool: Dictionary) -> String:
 if not g.Tools.is_fixed(g,tool): return item.name+"需要借助尖锐环境使用挣脱牌。"
 if g.Tools.TYPES[tool.type].get("environment_class","")!="sharp" or "sharp" not in DESIGNS[item.type].environments or tool.type not in DESIGNS[item.type].tools: return item.name+"请选择适用工具。"
 if not g.Tools.assisted(g) and not g.wall_contact(): return "需要先靠到墙边，才能使用已安装的工具。"
 return "" if mounted_contact(g,item,tool) else "当前姿势下，"+location_name(item)+"请调整姿势，使目标触及工具。"

static func slots() -> Array:
 return SLOT_NAMES.keys()

static func slot_name(slot: String) -> String:
 return SLOT_NAMES.get(slot,"")

static func location_name(item: Dictionary) -> String:
 return "、".join(occupied_slots(item).map(func(slot):return slot_name(slot)))

static func material_name(item: Dictionary) -> String:
 return TYPES.get(item.get("type",""),{}).get("material_text","特殊材质")

static func gain(item: Dictionary, timing: String) -> float:
 var spec=TYPES[item.type]
 if spec.duration>0 and item.remaining<=0: return 0.0
 var base=float(spec.energy_gain if timing=="energy" else spec.turn_gain)
 var slots=spec.get("turn_stimulates",spec.stimulates) if timing=="turn_start" else spec.stimulates
 var sensitivity=0.0
 for slot in slots: sensitivity+=float(SENSITIVITY.get(slot,0.0))
 return base*sensitivity*float(spec.get("turn_stimulus_factor",1.0) if timing=="turn_start" else 1.0)

static func effective_gain(g, item: Dictionary, timing: String) -> float:
 if is_cursed_plate(item) and timing=="turn_start" and not g.state.get("cursed_plate_masochist_mode",false):
  if not g.state.combat.active or g.state.combat.turn>CURSED_VIBRATOR_TURNS: return 0.0
 return gain(item,timing)

static func climax_slip_damage(item: Dictionary, tightness: int) -> float:
 var base=float(TYPES.get(item.get("type",""),{}).get("climax_slip_base",0.0))
 return maxf(0.0,base-RestraintValue.from_profile(int(item.get("grade",0)),tightness))

static func climax_slip_rule(type: String) -> String:
 var base=float(TYPES.get(type,{}).get("climax_slip_base",0.0))
 return "" if base<=0 else "每次高潮：受到%s－当前紧度档位－装备等级的固定滑脱伤害。" % str(base).trim_suffix(".0")

static func _number(value: float) -> String:
 if value>0.0 and value<0.005: return "小于0.01"
 var text="%.2f" % value
 return text.trim_suffix("0").trim_suffix("0").trim_suffix(".") if text.contains(".") else text

static func _stimulus_sentence(item: Dictionary) -> String:
 if is_chastity(item):
  var spec=TYPES[item.type]
  return "平板锁紧压着肉棒，使肉棒无法正常勃起"+("；内置导尿管贴在尿道中" if catheter(item) else "")+("，无线跳蛋同时在锁内震动。" if spec.get("integrated_vibrator",false) else "。")
 if is_chastity_reinforcement(item): return "加固带把平板锁紧紧固定在胯间，仅提供固定效果。"
 if is_cup_reinforcement(item): return "固定带把全包榨精杯牢牢固定在腰胯间，仅提供固定效果。"
 return STIMULATION_TEXTS.get(TYPES[item.type].family,TYPES[item.type].detail)

static func _stimulus_formula(item: Dictionary, timing: String, multiplier: float) -> String:
 var spec=TYPES[item.type]
 var base=float(spec.energy_gain if timing=="energy" else spec.turn_gain)
 var slots=spec.get("turn_stimulates",spec.stimulates) if timing=="turn_start" else spec.stimulates
 var sensitivity=0.0
 for slot in slots: sensitivity+=float(SENSITIVITY.get(slot,0.0))
 var internal=float(spec.get("turn_stimulus_factor",1.0) if timing=="turn_start" else 1.0)
 var factors=["基础"+_number(base),"部位倍率"+_number(sensitivity)]
 if internal!=1.0: factors.append("锁内震动系数"+_number(internal))
 factors.append("当前来源倍率"+_number(multiplier))
 return " × ".join(factors)+"＝"+_number(base*sensitivity*internal*multiplier)+"快感"

static func stimulation_text(item: Dictionary, multiplier: float=1.0, tightness: int=-1, protected: bool=false, context: Dictionary={}) -> String:
 if protected and is_reinforcement(item): return _stimulus_sentence(item)
 var spec=TYPES[item.type]
 var lines=[_stimulus_sentence(item)]
 if is_chastity(item):
  var sum=RestraintValue.from_profile(item.grade,maxi(0,tightness))
  lines.append("当前快感上限＋%d；锁外来源快感×%s。" % [sum*5,_number(1.0+0.05*sum)])
 if spec.energy_gain>0:
  if spec.duration>0 and item.remaining<=0: lines.append("消耗能量行动：电量耗尽＝0快感。")
  else: lines.append("消耗能量行动："+_stimulus_formula(item,"energy",multiplier)+"。")
 if spec.turn_gain>0:
  if is_cursed_plate(item) and not bool(context.get("masochist",false)):
   var turn=int(context.get("session_turn",0));var active=bool(context.get("session_active",false))
   if active and turn>CURSED_VIBRATOR_TURNS:
    lines.append("内置无线跳蛋：本场前6回合的刺激已经结束；超过回合限制＝0快感。")
   else:
    lines.append("回合开始："+_stimulus_formula(item,"turn_start",multiplier)+"；仅在每场前6回合生效"+("，当前第%d／6回合。" % maxi(1,turn) if active else "。"))
  elif spec.duration>0 and item.remaining<=0:
   lines.append("回合开始：电量耗尽＝0快感；装备仍留在原位。")
  else:
   lines.append("回合开始："+_stimulus_formula(item,"turn_start",multiplier)+"。")
   if is_cursed_plate(item): lines.append("抖M专用版：内置无线跳蛋持续生效。")
   elif spec.duration>0: lines.append("电量剩余%d回合。" % item.remaining)
   else: lines.append("无电量限制，佩戴期间持续生效。")
 var climax_rule=climax_slip_rule(item.type)
 if climax_rule!="":
  if tightness>=0: climax_rule="高潮时滑脱伤害：%s－紧度%d－等级%d＝%s。" % [_number(float(spec.climax_slip_base)),tightness,int(item.grade),_number(climax_slip_damage(item,tightness))]
  lines.append(climax_rule)
 if is_chastity(item):
  var factor=int(context.get("climax_factor",3));var masochist=bool(context.get("masochist",false))
  var shown_factor=factor if masochist else mini(factor,CHASTITY_CLIMAX_FACTOR_LIMIT)
  var sum=RestraintValue.from_profile(item.grade,maxi(0,tightness))
  lines.append("高潮后保留快感：（品质%d＋紧度%d）×当前系数%d＝%d。" % [int(item.grade),maxi(0,tightness),shown_factor,sum*shown_factor])
  lines.append("每次佩戴平板锁高潮，系数永久＋1"+("，没有上限。" if masochist else "，最高10。"))
 return "\n".join(lines)

static func description(item: Dictionary, multiplier: float=1.0, tightness: int=-1, protected: bool=false, context: Dictionary={}) -> String:
 if protected and is_reinforcement(item): return _stimulus_sentence(item)+"\n无法提前解除；获得专属钥匙后随主体一并取下。"
 var lines=[stimulation_text(item,multiplier,tightness,protected,context)]
 if is_chastity(item):
  if not is_cursed_plate(item): lines.append("佩戴时自动上锁；滑脱需先开锁或解除加固带。开锁后受到任意正数挣扎或滑脱伤害即整件解除，无视加固带。")
  else: lines.append("无法提前开锁或解除；击败下一个Boss后自动取下整件。")
 elif is_reinforced_cup(item): lines.append("紧度达到3档时自动附加同品质固定带；滑脱需先切断固定带，也可通过挣扎破坏杯体。固定带只接受切割伤害，杯体解除时一并取下。")
 elif is_reinforcement(item): lines.append("只接受已安装切割类道具造成的伤害；所属主体解除时一并取下。")
 elif allows(item,"manual"): lines.append("双臂、双腕和双手完全自由时，可花费1能量直接取出。")
 return "\n".join(lines)

static func wear_text(type: String) -> String:
 return str(TYPES.get(type,{}).get("wear_text",""))

static func validate(items, legacy_cups: bool=false) -> String:
 ensure_catalog()
 if not items is Array: return "性玩具列表缺损。"
 var used=[]
 var families=[]
 var counts={}
 for item in items:
  if not item is Dictionary or not item.get("type") is String or not TYPES.has(item.type) or not item.get("slot") is String or not item.get("remaining") is int: return "性玩具类型、位置或电量有误。"
  for key in INSTANCE_FIELDS:
   if not item.has(key): return "性玩具实例缺少必要属性。"
  for key in item:
   if key not in INSTANCE_FIELDS and key not in OPTIONAL_INSTANCE_FIELDS: return "性玩具实例包含额外属性。"
  var spec=DESIGNS[item.type]
  var family=TYPES[item.type].family
  var climax_base=TYPES[item.type].get("climax_slip_base",0.0)
  if (family=="urethral_rod")!=(climax_base==CLIMAX_SLIP_BASE): return "马眼棒的高潮滑脱规则有误。"
  if not item.get("id") is String or not item.id.begins_with("special_") or item.id in used: return "性玩具编号重复或有误。"
  var wear_family=family if legacy_cups else exclusive_family(item.type)
  if wear_family in families: return "同一种性玩具限佩戴1件。"
  if item.slot!=spec.slots[0] or item.coverage!=spec.slots or item.contact_slots!=spec.slots or item.get("template")!="special" or item.get("name")!=TYPES[item.type].name or item.get("grade")!=spec.grade or item.get("maximum")!=spec.maximum or (is_chastity(item) and not item.get("locked") is bool) or (not is_chastity(item) and item.get("locked")!=false) or item.get("layer")!=0 or item.get("material")!=spec.material or item.get("variant")!=0: return "性玩具的品质、位置或固定类型有误。"
  if not item.get("owner_id") is String: return "性玩具所属关系有误。"
  if is_reinforcement(item):
   var owners=items.filter(func(owner):return reinforcement_matches(item,owner) and owner.grade==item.grade)
   if owners.size()!=1 or item.locked or item.owner_id=="" or item.durability<=0 or item.durability>item.maximum: return "固定带缺少对应主体或状态有误。"
  elif item.owner_id!="": return "普通性玩具需要独立佩戴。"
  if supports_reinforcement(item) and not item.has("reinforcement_state"): return "固定带状态记录缺失。"
  if item.has("reinforcement_state") and (not item.reinforcement_state is String or not supports_reinforcement(item) or item.reinforcement_state not in ["none","active","removed"]): return "固定带状态记录有误。"
  if typeof(item.get("durability")) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(item.durability) or item.durability<=0 or item.durability>spec.maximum: return "性玩具耐久有误。"
  for covered in spec.slots: counts[covered]=counts.get(covered,0)+int(spec.capacity_cost)
  var duration=TYPES[item.type].duration
  if item.remaining<0 or item.remaining>duration or (duration==0 and item.remaining!=0): return "性玩具剩余电量有误。"
  used.append(item.id);families.append(wear_family)
 var locks=items.filter(func(item):return is_chastity(item))
 if locks.size()>1: return "同一时间只能佩戴一件平板锁。"
 for owner in items.filter(supports_reinforcement):
  var straps=items.filter(func(item):return reinforcement_matches(item,owner))
  var status=owner.reinforcement_state
  if status=="none" and (not straps.is_empty() or owner.durability/owner.maximum>0.80000001): return "主体的固定带缺省状态有误。"
  if status=="active" and straps.size()!=1: return "主体记录的固定带缺失或重复。"
  if status=="removed" and not straps.is_empty(): return "已切断的固定带需要清除。"
 for slot in counts:
  if counts[slot]>capacity(slot): return slot_name(slot)+"的性玩具超出容量。"
 return ""

static func view(g) -> Array:
 ensure_catalog()
 var result=[]
 var assist_profiles=g.HandAssist.profiles(g)
 for region in REGIONS:
  if not g.Character.has_slot(g,region.id): continue
  var entry=region.duplicate(true);entry.items=[]
  for slot in region.slots:
   var equipped=g.state.special_equipment.filter(func(e):return occupies(e,slot))
   var projected=[]
   for item in equipped:
    var detail=g.View.equipment_entry(g,item,slot)
    var slots=TYPES[item.type].get("turn_stimulates",TYPES[item.type].stimulates)
    var multiplier=g.Pressure.source_multiplier(g,slots)
    var context={"climax_factor":g.state.chastity_climax_factor,"masochist":g.state.cursed_plate_masochist_mode,"session_turn":g.state.combat.turn,"session_active":g.state.combat.active}
    detail.text=stimulation_text(item,multiplier,g.tier(item.durability,item.maximum),g.cursed_plate(item),context)
    detail.remaining=item.remaining
    projected.append(detail)
   entry.items.append({"slot":slot,"name":slot_name(slot),"capacity":capacity(slot),"used":used_capacity(g.state.special_equipment,slot),"hand_reach":g.HandAssist.at_point(g,slot,assist_profiles),"equipment":projected})
  result.append(entry)
 return result
