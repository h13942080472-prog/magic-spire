extends RefCounted

# Card-only fixed cutting, using the existing world contact/material rules.
static func reason(g, item: Dictionary, target: Dictionary) -> String:
 if not g.Tools.is_fixed(g,item) or item.uses<=0: return "需要已安装且有剩余次数的工具。"
 var issue="" if g.Tools.assisted(g) else g.Prison.Space.mounted_reason(g,item)
 if issue!="": return issue
 if not g.Tools.assisted(g) and not g.wall_contact(): return "需要先靠到工具所在墙边。"
 if target.is_empty() or target.durability<=0: return "目标已经解除。"
 if g.SpecialEquipment.is_special(target): return g.SpecialEquipment.tool_reason(g,target,item)
 if g.Equipment.TEMPLATES[target.template].get("damage_factor",1.0)==0.0: return "需要适用于此固定结构的工具。"
 if not g.Tools.TYPES[item.type].materials.has(target.material): return "需要适用于此材料的切割工具。"
 return g.Tools.contact_reason(g,target,item)

static func select(g, target: Dictionary, damage_type: String, used: Array=[]) -> Dictionary:
 var best={}
 for item in g.state.items:
  var spec=g.Tools.TYPES[item.type]
  if damage_type not in spec.get("trigger_damage_types",[]) or item.id in used or reason(g,item,target)!="": continue
  if best.is_empty() or spec.damage>best.damage:
   best={"item":item.id,"name":spec.name,"damage":spec.damage,"mount":g.Tools.mount_name(g,item)}
 if not best.is_empty(): best.damage*=g.Cards.damage_multiplier(g,"equipment")
 return best

static func preview(g, target: Dictionary, damage_type: String, base: Dictionary) -> Dictionary:
 if g.SpecialEquipment.is_reinforcement(target):
  return {} if base.reason!="" else select(g,target,damage_type,g.state.card_chain.get("tools_used",[]))
 if base.damage<=0 or base.reason!="" or base.immune or base.release or base.damage>=target.durability: return {}
 return select(g,target,damage_type,g.state.card_chain.get("tools_used",[]))

static func apply(g, target: Dictionary, bonus: Dictionary) -> String:
 if bonus.is_empty() or target.durability<=0: return ""
 var item=g._item(bonus.item)
 if item.is_empty() or reason(g,item,target)!="": return ""
 var before=target.durability
 g._apply_equipment_damage(target,bonus.damage,"cut")
 if target.durability>=before: return ""
 item.uses-=1
 g._emit("mechanical","借助%s的%s，额外削减%s耐久；%s耐久 %s → %s，工具剩余%d次。" % [bonus.mount,bonus.name,g.number(before-target.durability),g._equipment_name(target),g.number(before),g.number(target.durability),item.uses],{"tool_bonus":{"item":item.id,"target":target.id,"fixed":bonus.damage,"actual":before-target.durability,"remaining":item.uses}})
 return item.id

static func description(g, item: Dictionary) -> String:
 var issue=""
 if not g.Tools.assisted(g):
  issue=g.Prison.Space.mounted_reason(g,item)
  if issue=="" and not g.wall_contact(): issue="需要先靠到工具所在墙边。"
 return ("触手朋友协助固定，对全身生效。" if g.Tools.assisted(g) else "")+effect_description(item.type,g.Tools.TYPES[item.type].damage*g.Cards.damage_multiplier(g,"equipment"))+"\n"+(issue if issue!="" else "仍需目标材料兼容且外露。")

static func effect_description(type: String, damage: float) -> String:
 var spec=preload("res://data/field_tools.gd").TYPES[type]
 var types=spec.get("trigger_damage_types",[]).map(func(kind):return {"strain":"挣扎","slip":"滑脱"}[kind])
 return "牌造成%s伤害时触发；额外固定削减%s耐久，每张牌对本工具最多一次，触发消耗1次。魔法牌同样按实际伤害类型判断。" % ["／".join(types),(str(int(damage)) if is_equal_approx(damage,roundf(damage)) else "%.2f" % damage)]
