extends RefCounted
const Equipment=preload("res://data/equipment.gd")
const DisplayNumbers=preload("res://data/display_numbers.gd")

const TIGHTEN="tighten"
const TOUGH="tough"
const Effects={TIGHTEN:{"name":"收紧","turn_end_durability":2},TOUGH:{"name":"坚韧","bonus_durability":8}}

static func supports(item: Dictionary, relics: Array) -> bool:
 return not Equipment.lock_only(item) and not Equipment.is_shackle(item) and not (item.slot=="eyes" and "cursed_blindfold" in relics)

static func eligible(g, item: Dictionary) -> bool:
 return not item.is_empty() and item.durability>0.000001 and not item.has("enchantment") and supports(item,g.state.relics)

static func attach(g, item: Dictionary, id: String, source: String) -> bool:
 if not Effects.has(id) or not eligible(g,item): return false
 item.enchantment=id
 if id==TOUGH: item.tough_durability=float(Effects[TOUGH].bonus_durability)
 g._emit("event","%s为%s附加了「%s」。" % [source,item.name,Effects[id].name],{"equipment":item.id,"equipment_enchantment":id})
 return true

static func text(item: Dictionary) -> String:
 var effect=Effects.get(item.get("enchantment",""),{})
 if effect.is_empty(): return ""
 if item.enchantment==TOUGH: return "附魔·%s：额外耐久 %s/%d，优先承受伤害。" % [effect.name,DisplayNumbers.amount(item.tough_durability),effect.bonus_durability]
 return "附魔·%s：战斗回合结束时，耐久＋%d。" % [effect.name,effect.turn_end_durability]

static func total_durability(item: Dictionary) -> float:
 return item.durability+item.get("tough_durability",0.0)

static func absorb_damage(item: Dictionary, damage: float) -> float:
 var absorbed=minf(maxf(0.0,damage),item.get("tough_durability",0.0))
 if absorbed>0.0: item.tough_durability-=absorbed
 return damage-absorbed

static func turn_end(g) -> void:
 if g.state.phase!="battle": return
 for item in g.state.equipment:
  var effect=Effects.get(item.get("enchantment",""),{})
  var recovery=effect.get("turn_end_durability",0)
  if recovery<=0 or item.durability<=0.000001 or item.durability>=item.maximum: continue
  var gain=minf(recovery,item.maximum-item.durability)
  item.durability+=gain
  g._refresh_equipment(item)
  g._emit("event","%s的「%s」恢复了%s点耐久。" % [item.name,effect.name,g.number(gain)],{"equipment":item.id,"equipment_enchantment":item.enchantment,"recovered":gain})

static func issue(g, item: Dictionary, relics: Array) -> String:
 if item.get("enchantment","")!=TOUGH and item.has("tough_durability"): return "该装备没有坚韧附魔。"
 if not item.has("enchantment"): return ""
 if not item.enchantment is String or not Effects.has(item.enchantment): return "装备附魔记录有误。"
 if not supports(item,relics): return "该装备不支持附魔。"
 if item.enchantment==TOUGH:
  if item.grade not in Equipment.GRADES or not is_equal_approx(item.maximum,Equipment.maximum(item.grade)): return "坚韧附魔的本体耐久上限有误。"
  if not g.Snapshot.fields(item,"tough_durability:n") or item.tough_durability<0.0 or item.tough_durability>Effects[TOUGH].bonus_durability: return "坚韧附魔的额外耐久有误。"
 return ""

static func migrate(g, saved: Dictionary) -> String:
 if not saved.get("equipment") is Array: return "装备记录缺损。"
 var bonus=float(Effects[TOUGH].bonus_durability)
 for item in saved.equipment:
  if not item is Dictionary or item.get("enchantment","")!=TOUGH: continue
  if not g.Snapshot.fields(item,"grade:i durability:n maximum:n") or item.grade not in Equipment.GRADES or item.has("tough_durability"): return "旧存档的坚韧附魔记录有误。"
  var base=Equipment.maximum(item.grade)
  if not is_equal_approx(item.maximum,base+bonus) or item.durability<0.0 or item.durability>item.maximum: return "旧存档的坚韧附魔耐久有误。"
  # The old pool cannot identify which points were spent. Keep its total and tightness ratio.
  var ratio=item.durability/item.maximum
  item.maximum=base
  item.durability=ratio*base
  item.tough_durability=ratio*bonus
 return ""
