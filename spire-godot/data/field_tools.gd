extends RefCounted

# Shared definitions and state-independent descriptions. Runtime queries live in core/tool_rules.gd.
const Environments=preload("res://data/environments.gd")
const TYPES={
 "lubricant_potion":{"name":"润滑油","category":"potion","operation":"buff","effect":"slip_boost","target_scope":"body_group","unrestricted_use":true,"mouth_reduction":false,"amount":2,"uses":3,"damage":0.0,"materials":[]},
 "mana_potion":{"name":"魔力药剂","category":"potion","operation":"buff","effect":"mana","unrestricted_outside_battle":true,"amount":20,"uses":1,"damage":0.0,"materials":[]},
 "energy_potion":{"name":"活力药剂","category":"potion","operation":"buff","effect":"energy","amount":2,"uses":1,"damage":0.0,"materials":[]},
 "charge_potion":{"name":"蓄势药剂","category":"potion","operation":"buff","effect":"charge","amount":2,"uses":1,"damage":0.0,"materials":[]},
 "draw_scroll":{"name":"应变卷轴","category":"scroll","operation":"buff","effect":"draw","amount":3,"uses":1,"damage":0.0,"materials":[]},
 "mana_scroll":{"name":"节魔卷轴","category":"scroll","operation":"buff","effect":"reserve_mana","amount":2,"uses":1,"damage":0.0,"materials":[]},
 "casting_scroll":{"name":"定咒卷轴","category":"scroll","operation":"buff","effect":"sure_cast","amount":1,"uses":1,"damage":0.0,"materials":[]},
 "return_seal":{"name":"传送符","category":"scroll","uses":1,"damage":0.0,"materials":[],"operation":"escape","keep_on_capture":true},
 "picks":{"name":"便携开锁针","uses":2,"damage":0.0,"materials":[],"operation":"unlock"},
 "shard":{"environment_class":"sharp","trigger_damage_types":["strain","slip"],"mouth_install":true,"name":"尖锐的小石片","uses":3,"damage":5.0,"materials":["leather","rope","tape"]},
 "saw":{"environment_class":"sharp","trigger_damage_types":["strain","slip"],"mouth_install":true,"name":"锈掉的锯条","uses":2,"damage":7.0,"materials":["leather","rope","tape","plastic"]}
}

const DROP_POOL=["mana_potion","energy_potion","charge_potion","draw_scroll","mana_scroll","casting_scroll","shard","saw","lubricant_potion"]
const DROP_INITIAL=40
const DROP_STEP=10

static func operation(type: String) -> String:
 return TYPES[type].get("operation","cut")

static func effect_description(type: String, damage: float, assisted: bool=false) -> String:
 var spec=TYPES[type]
 var lines: Array[String]=[]
 if spec.get("keep_on_capture",false): lines.append("入狱时保留。")
 match operation(type):
  "cut":
   lines.append("切割：每次造成%s点真实伤害%s。" % [(str(int(damage)) if is_equal_approx(damage,roundf(damage)) else "%.2f" % damage),"（基础%s）" % str(spec.damage) if damage!=spec.damage else ""])
   lines.append("无视紧度、锁和堆叠减伤。适用材料："+"、".join(spec.materials.map(func(material):return preload("res://data/equipment.gd").MATERIAL_NAMES[material]))+"。")
   lines.append("目标须外露且可触及。" if not assisted else "触手朋友：固定工具对全身有效，无身体、姿态或触及限制。")
  "unlock":
   lines.append("开锁：解除1把装备锁或牢门锁，耐久保留。")
   lines.append("需要手腕、手指自由并能触及目标；牢门须站姿或坐姿。" if not assisted else "触手朋友：无需满足身体、姿态和触及条件。")
  "escape":
   lines.append("逃离：直接离开当前牢房，进入监狱外部路线。")
   lines.append("仅限安全等级1—4的牢房行动回合，使用后背包须在容量内。")
   if not assisted: lines.append("手指或脚趾任一部位自由即可使用。")
 lines.append("每次消耗1次使用次数，能量与魔力费用为0。")
 if not spec.get("trigger_damage_types",[]).is_empty(): lines.append("安装1能量，取回免费，使用次数保留。")
 return "\n".join(lines)

static func mount_label(mount: String) -> String:
 return "随身" if mount=="carry" else "离地%s米的墙缝" % str(HEIGHTS[mount].height)

# Fixed world heights; posture changes reach, never the installed height.
const MOUNTS=["carry","foot_wall","hand_wall","high_wall"]
const HEIGHTS={"foot_wall":{"name":"低位","height":0.2,"range":"离地0—0.4米"},"hand_wall":{"name":"中位","height":0.8,"range":"离地大于0.4—1米"},"high_wall":{"name":"高位","height":1.4,"range":"离地大于1—1.6米"}}
const HOOK_MOUNT="hand_wall"
const OPERATOR_NAMES={"hand":"手指","foot":"脚趾","mouth":"嘴部","helper":"触手朋友"}
const OPERATOR_HEIGHTS={
 "stand":{"hand":["hand_wall","high_wall"],"mouth":["high_wall"],"foot":["foot_wall"]},
 "sit":{"hand":["foot_wall","hand_wall"],"mouth":["hand_wall"],"foot":["foot_wall"]},
 "lie":{"hand":["foot_wall"],"mouth":["foot_wall"],"foot":["foot_wall","hand_wall","high_wall"]}}
const POINT_HEIGHTS={
 "stand":{"high_wall":["shoulder","upper_arm_top","above_elbow"],"hand_wall":["above_elbow","below_elbow","mid_forearm","wrist","palm_left","palm_right","fingers_left","fingers_right","thigh_root","mid_thigh"],"foot_wall":["above_knee","below_knee","mid_calf","ankle","foot","toes"]},
 "sit":{"high_wall":[],"hand_wall":["shoulder","upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist","palm_left","palm_right","fingers_left","fingers_right"],"foot_wall":["below_elbow","mid_forearm","wrist","palm_left","palm_right","fingers_left","fingers_right","thigh_root","mid_thigh","above_knee","below_knee","mid_calf","ankle","foot","toes"]},
 "lie":{"high_wall":["ankle","foot","toes"],"hand_wall":["below_knee","mid_calf","ankle","foot","toes"],"foot_wall":["shoulder","upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist","palm_left","palm_right","fingers_left","fingers_right","thigh_root","mid_thigh","above_knee","below_knee","mid_calf","ankle","foot","toes"]}}
