extends RefCounted

# Target-specific hand assistance. No state writes or independent action pipeline.
const E=preload("res://data/equipment.gd")
const Special=preload("res://data/special_equipment.gd")
const SIDES=["left","right"]

const Contact=preload("res://core/contact.gd")

static func profile(g, side: String) -> Dictionary:
 return Contact.profile(g,side)

static func profiles(g) -> Array:
 return Contact.profiles(g)

static func summary(g) -> String:
 var current=profiles(g).filter(func(reach):return not reach.points.is_empty())
 var amount=0.0
 for reach in current: amount+=g.B.HAND_ASSIST_BONUS*reach.assist_factor
 return label(current.map(func(reach):return reach.side),amount)

static func at_point(g, point: String, current: Array=[]) -> Array:
 var available=profiles(g) if current.is_empty() else current
 return available.filter(func(reach):return point in reach.points).map(func(reach):return reach.side)

static func preview(g, target: Dictionary, current: Array=[]) -> Dictionary:
 var hands=[]
 var contributions=[]
 var amount=0.0
 var reasons=[]
 var available=profiles(g) if current.is_empty() else current
 for reach in available:
  var result=Contact.evaluate(g,target,reach)
  if result.code=="":
   hands.append(reach.side)
   var factor=reach.get("assist_factor",1.0)
   var bonus=g.B.HAND_ASSIST_BONUS*factor
   amount+=bonus
   contributions.append({"side":reach.side,"bonus":bonus,"factor":factor})
  else: reasons.append({"side":reach.side,"code":result.code,"reason":result.reason})
 return {"hands":hands,"bonus":amount,"label":label(hands,amount),"reasons":reasons,"contributions":contributions,"detail":explain(hands,amount,reasons,contributions)}

static func label(hands: Array, amount: float) -> String:
 if hands.is_empty(): return "无手部辅助"
 return ("双手" if hands.size()==2 else ("左手" if hands[0]=="left" else "右手"))+"辅助＋"+str(amount).trim_suffix(".0")

static func description(g) -> String:
 var lines=["每只手必须手指自由；手掌可用时＋1，手掌受限时减半为＋0.5。两手分别相加，适用于挣扎、普通滑脱和魔法滑脱；手腕、触及与外露条件仍须满足。"]
 for side in SIDES:
  var reach=profile(g,side)
  var name="左手" if side=="left" else "右手"
  if reach.get("assist_factor",0.0)==0.5: lines.append(name+"：手指自由，手掌受限，辅助效果减半为＋0.5。")
  if reach.reason!="": lines.append(name+"："+reach.reason)
  elif E.ANATOMY.all(func(point):return point in reach.points): lines.append(name+"：所有身体位置以及乳头、肉棒和双穴区域均可触及。")
  else:
   var names=[]
   for point in reach.points:
    var text=Special.slot_name(point) if point in Special.slots() else E.point_name(point)
    if text not in names: names.append(text)
   lines.append(name+"："+("可触及"+"、".join(names)+"。" if not names.is_empty() else "当前固定方式挡住了可辅助的位置。"))
 return "\n".join(lines)

static func explain(hands: Array, amount: float, reasons: Array, contributions: Array=[]) -> String:
 var lines=[label(hands,amount)]
 for contribution in contributions:
  if contribution.factor==0.5: lines.append(("左手" if contribution.side=="left" else "右手")+"：手指自由，手掌受限，辅助减半为＋"+str(contribution.bonus).trim_suffix(".0")+"。")
 for issue in reasons:
  lines.append(("左手" if issue.side=="left" else "右手")+"："+issue.reason)
 return "\n".join(lines)
