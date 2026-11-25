extends RefCounted

const Rules=preload("res://data/card_rules.gd")

static func card_effect(effect: String, uses: int) -> String:
 return effect+Rules.remove_label(uses)+"。"

static func set_remove_terms(keywords: Dictionary, uses: int) -> void:
 for side in keywords:
  for term in keywords[side]:
   if term.get("id","")=="remove": term.name=Rules.remove_label(uses)

# Inventory copy is a read-only presentation of the same effect values used on use.
static func summary(g, type: String) -> String:
 var spec=g.Tools.TYPES[type]
 var value=g.Consumables.amount(g,type) if spec.has("effect") else 0
 return _summary(g,type,value,spec.damage*g.Cards.damage_multiplier(g,"equipment"))

static func base_summary(g, type: String) -> String:
 var spec=g.Tools.TYPES[type]
 return _summary(g,type,spec.get("amount",0),spec.damage)

static func _summary(g, type: String, value: int, damage: float) -> String:
 var spec=g.Tools.TYPES[type]
 match g.Tools.operation(type):
  "escape": return "离开当前牢房，前往监狱外部路线。"
  "unlock": return "解除1把拘束具锁或牢门锁。"
  "cut":
   var materials=spec.materials.map(func(id):return g.Equipment.MATERIAL_NAMES[id])
   return "切割：造成%s点真实伤害。\n适用材料：%s。" % [g.number(damage),"、".join(materials)]
  "buff":
   match spec.effect:
    "mana": return "恢复%d魔力。" % value
    "energy": return "获得%d能量。" % value
    "charge": return "获得%d层蓄力。" % value
    "draw": return "抽%d张牌。" % value
    "reserve_mana": return "获得%d层魔力预备。" % value
    "sure_cast": return "本场下一次施法成功率100%。"
    "slip_boost": return "本场所选部位滑脱伤害×%d，可滑脱紧度3档拘束具。仅生效一次。" % value
 return ""

static func note(g, type: String) -> String:
 var spec=g.Tools.TYPES[type]
 if spec.get("unrestricted_use",false): return "无视身体限制，口部受限时保留完整效果。"
 if g.Tools.assisted(g): return "触手朋友协助展开。" if spec.get("category","")=="scroll" else ""
 if spec.get("category","")=="potion" and spec.get("mouth_reduction",true) and g.occupied("mouth"):
  return "已计入口部受限的药效折损。"
 return ""
