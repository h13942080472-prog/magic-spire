extends RefCounted
const Tools=preload("res://core/tool_rules.gd")

static func amount(g, type: String, base: int=-1) -> int:
 var spec=Tools.TYPES[type]
 var value=spec.amount if base<0 else base
 if spec.category!="potion" or not spec.get("mouth_reduction",true): return value
 return int(potion_amount(g,value))

static func potion_amount(g, value: float) -> float:
 if not g.occupied("mouth"): return value
 var severity=0
 for piece in g.equipment_at("mouth"):
  severity=maxi(severity,piece.grade+g.tier(piece.durability,piece.maximum))
 return floorf(value/2.0) if severity>4 else ceilf(value/2.0)

static func description(g, type: String) -> String:
 return effect_description(type,amount(g,type),Tools.assisted(g),outside_battle(g,type))

static func outside_battle(g, type: String) -> bool:
 return Tools.TYPES.get(type,{}).get("unrestricted_outside_battle",false) and g.state.phase not in ["battle","cleared","prison_end"]

static func effect_description(type: String, value: int, assisted: bool=false, noncombat: bool=false) -> String:
 var spec=Tools.TYPES[type]
 var text=""
 match spec.effect:
  "mana": text="恢复%d魔力，不超过上限。" % value
  "energy": text="本回合获得%d能量。" % value
  "charge": text="获得%d层蓄力。" % value
  "draw": text="抽%d张牌，最多抽到%d张手牌。" % [value,preload("res://data/balance.gd").HAND_LIMIT]
  "reserve_mana": text="获得%d点临时魔力，优先抵扣法术和卡牌耗魔。" % (value*preload("res://data/card_rules.gd").RESERVE_MANA_VALUE)
  "sure_cast": text="本场战斗下一次合法施法成功率100%，费用照常。"
  "slip_boost": text="选择一个部位，组内全部位置可滑脱3级紧度的拘束具，滑脱最终伤害×%d。本场战斗或整备结束时失效，重复不叠加。" % value
 if spec.get("unrestricted_use",false):
  text+="不受身体和姿势限制。"
 elif noncombat:
  text+="非战斗与探索阶段不受身体和姿势限制。"
 elif spec.category=="potion":
  if spec.get("unrestricted_outside_battle",false): text+="非战斗与探索阶段不受身体和姿势限制；战斗中："
  text+="触手朋友协助饮用，不受身体和姿势限制。" if assisted else "上肢拘束分值小于1可站着喝，0.5也可；达到1时须坐下或躺下。坐躺时无需手指握持。"
 else: text+="触手朋友协助展开，无需手指或脚趾自由。" if assisted else "手指或脚趾任一部位自由即可使用。"
 if spec.category=="potion": text+="嘴部不自由时效果减半；整数按嘴部装备等级＋紧度≤4向上取整，>4向下取整。" if spec.get("mouth_reduction",true) else "不受口部减效影响。"
 return text+("使用1次后消失" if spec.uses==1 else "每瓶可用%d次，每次消耗1次" % spec.uses)+"，不消耗能量或魔力。"

static func scroll_reason(g) -> String:
 if not Tools.assisted(g) and not ["fingers","toes"].any(func(slot):return ["left","right"].any(func(side):return not g.hand_blocked(slot,side))): return "手指和脚趾均被拘束，无法展开卷轴。"
 return ""

static func reason(g, type: String) -> String:
 var spec=Tools.TYPES[type]
 if not spec.get("unrestricted_use",false) and not outside_battle(g,type) and not Tools.assisted(g) and spec.category=="potion" and g.state.posture not in ["sit","lie"]:
  if g.restraint_degree("arms")>=1: return "上肢拘束分值达到1，需要坐下或躺下才能喝药。"
  if not g.hands_can_hold(): return "手指无法握持药剂，需要坐下或躺下才能喝药。"
 if not spec.get("unrestricted_use",false) and spec.category=="scroll" and scroll_reason(g)!="": return scroll_reason(g)
 if spec.effect in ["energy","draw"] and g.state.phase not in ["battle","prepare","rest","prison"]: return "进入可行动回合后才能使用。"
 if spec.effect=="mana" and g.state.mana>=g.state.mana_max: return "魔力已经达到上限。"
 if spec.effect=="draw":
  if g.state.hand.size()>=g.B.HAND_LIMIT: return "手牌已达到10张上限。"
  if g.state.draw.is_empty() and g.state.discard.is_empty(): return "抽牌堆和弃牌堆均没有牌。"
 if spec.effect=="sure_cast":
  if g.state.phase not in g.RelicEffects.COMBAT_PHASES: return "定咒卷轴只能在战斗或特殊战斗中使用。"
  if g.state.sure_cast: return "本场战斗已有一次必定成功的施法尚未使用。"
 return ""

# 道具使用事实（道具域，批 R4 起、R5 收口）：显示事实的唯一来源（docs/spec/candidate-removal.md §2.1 T5／T8）。
static func use_facts(g, item: Dictionary) -> Array:
 var facts=[]
 var spec=Tools.TYPES[item.type]
 var targets=g.Equipment.panel_groups() if spec.get("target_scope","")=="body_group" else [{"id":"hero","name":""}]
 for target in targets:
  var label="使用"+spec.name+(" · "+target.name if target.name!="" else "")
  var use_args={"item_type":item.type}
  facts.append(g._fact({"kind":"item_use","item":item.id,"target":target.id},label,{"kind":"consumables.description","args":use_args,"fallback":description_detail(g,use_args)},0,0.0,reason(g,item.type),"","item"))
 return facts

# 非战斗可用道具的事实（道具域，批 R4 起、R5 收口）：existing＝已产出的显示事实，用于「同一道具只留
# 一条使用点」的去重——与改动前的行扫描语义一致。
static func noncombat_facts(g, existing: Array) -> Array:
 var facts=[]
 for item in g.state.items:
  if not outside_battle(g,item.type): continue
  if existing.any(func(entry):return entry.payload.kind=="item_use" and entry.payload.get("item","")==item.id): continue
  facts.append_array(use_facts(g,item))
 return facts

# R4（docs/ondemand-copy.md §11.5）：直呼点文案改走路由，正文留在本模块。
static func description_detail(g, args: Dictionary) -> String:
 return description(g,String(args.get("item_type","")))

static func slip_multiplier(g, target: Dictionary) -> float:
 var result=1.0
 var points=g.Equipment.slip_points(target)
 for buff in g.state.body_buffs:
  var spec=Tools.TYPES[buff.type]
  if spec.effect!="slip_boost": continue
  var group=g.Equipment.panel_groups().filter(func(p):return p.id==buff.group)[0]
  if group.slots.any(func(slot):return g.Equipment.points(slot).any(func(point):return point in points)):
   result=maxf(result,spec.amount)
 return result

static func validate_buffs(g, buffs: Variant) -> String:
 if not buffs is Array: return "部位药剂效果记录不完整。"
 var seen=[]
 var groups=g.Equipment.panel_groups().map(func(group):return group.id)
 for buff in buffs:
  if not g.Snapshot.fields(buff,"type:s group:s") or not Tools.TYPES.has(buff.type): return "部位药剂效果记录不正确。"
  if Tools.TYPES[buff.type].get("target_scope","")!="body_group" or buff.group not in groups: return "部位药剂的作用位置不正确。"
  var key=buff.type+":"+buff.group
  if key in seen: return "同一部位的药剂效果重复。"
  seen.append(key)
 return ""

static func use(g, item: Dictionary, target: String="hero") -> void:
 var spec=Tools.TYPES[item.type]
 var value=amount(g,item.type)
 match spec.effect:
  "slip_boost":
   var buff={"type":item.type,"group":target}
   if buff not in g.state.body_buffs: g.state.body_buffs.append(buff)
   var group=g.Equipment.panel_groups().filter(func(p):return p.id==target)[0]
   g._emit("event","在%s使用%s；剩余%d次。" % [group.name,spec.name,item.uses-1],{"body_buff":buff.duplicate()})
  "mana":
   var restored=minf(value,g.state.mana_max-g.state.mana)
   g.state.mana+=restored
   g._emit("event","使用"+spec.name+"，恢复%s魔力。" % g.number(restored))
  "sure_cast":
   g.state.sure_cast=true
   g._emit("event","展开定咒卷轴，获得「定咒」。")
  _: g.Cards.apply_effects(g,[{"op":spec.effect,"amount":value}],{},spec.name)
 item.uses-=1
