extends RefCounted

const Rules=preload("res://data/card_rules.gd")

# Internal effect repetition: never dispatches another command or moves a card.
static func take(g, kind: String, type: String, free: bool=false) -> int:
 for id in g.state.card_buffs.duplicate():
  var rule=g.Cards.Rules.BUFFS[id].get("replay",{})
  if rule.get("kind","")!=kind: continue
  if kind=="card" and (g.Cards.Rules.free_effect(type,free) or not g.Cards.Rules.distinct_faces(type)): continue
  if kind=="attack" and rule.get("spell","")!=type: continue
  var count=int(g.state.card_buff_uses.get(id,1))
  g.state.card_buffs.erase(id)
  g.state.card_buff_uses.erase(id)
  return count
 return 0

static func target(p: Dictionary) -> Dictionary:
 var result={"slot":p.get("slot",""),"target":p.target,"self_target":p.get("self_target",false)}
 if p.has("hand_uid"): result.hand_uid=p.hand_uid
 if Rules.SPECS[p.type].get("x_cost",false): result.x=p.x
 result.free=p.get("free",false);result.uid=p.get("uid","")
 return result

static func valid_target(value: Variant) -> bool:
 if not value is Dictionary or not value.get("slot") is String or not value.get("target") is String or not value.get("self_target") is bool: return false
 if value.keys().any(func(key):return key not in ["slot","target","self_target","free","uid","hand_uid","x","selected_uids"]): return false
 if value.has("free") and not value.free is bool: return false
 for key in ["uid","hand_uid"]:
  if value.has(key) and not value[key] is String: return false
 if value.has("x") and (not value.x is int or value.x<0): return false
 if value.has("selected_uids") and (not value.selected_uids is Array or value.selected_uids.any(func(uid):return not uid is String or value.selected_uids.count(uid)!=1)): return false
 return true

static func payload(g, type: String, original: Dictionary, used: Array) -> Dictionary:
 var spec=g.Cards.Rules.SPECS[type]
 var p={"kind":"card","type":type,"mode":spec.mode,"free":false,"uid":"","replay":true}
 p.merge(original,true)
 if p.has("selected_uids") and p.selected_uids.any(func(uid):return not g.Cards.selection_cards(g).any(func(entry):return entry.card.uid==uid)): return {}
 if p.self_target: return p if g.Cards.reason(g,p)=="" else {}
 if p.target=="prison_door":
  if g.state.phase!="prison" or g.state.prison.door_open or not g.Prison.Space.at(g,"door"): return {}
 elif p.target==g.CaptureBind.BIND_TARGET:
  if not g.CaptureBind.has_bind(g): return {}
  p.merge(g.Cards.bind_payload(g,type,p.uid,p.free),true)
 else:
  var equipment=g._equipment(p.target)
  if equipment.is_empty() or equipment.durability<=0: return {}
  p.merge(g.Cards.target_payload(g,type,p.slot,equipment,g.HandAssist.profiles(g),p.uid,p.free,spec.get("follow_through",false)),true)
  if p.get("tool_bonus",{}).get("item","") in used: p.tool_bonus={}
 if p.target!="prison_door" and g.Cards.reason(g,p)!="": return {}
 return p

static func cards(g, type: String, targets: Array, used: Array=[], count: int=1) -> void:
 for repeat in range(count): _cards_once(g,type,targets,used)

static func _cards_once(g, type: String, targets: Array, used: Array) -> void:
 var first={}
 for original in targets:
  first=payload(g,type,original,used)
  if not first.is_empty(): break
 if first.is_empty():
  g._emit("event","余势复演：原目标已失效，跳过额外释放。",{"replay":{"type":type,"skipped":true}})
  return
 g._emit("event","余势复演：免费额外释放「"+g.B.CARD_NAMES[type]+"」。",{"replay":{"type":type,"skipped":false}})
 var failed=g._magic_failed
 var success=not g.Cards.uses_magic(first) or g._cast_magic({"payload":first,"label":g.B.CARD_NAMES[type],"mana_payment":{"mana":0.0}})
 g._magic_failed=failed
 if not success: return
 for original in targets:
  var p=payload(g,type,original,used)
  if p.is_empty(): continue
  var tool=g.Cards.resolve(g,p)
  g.Cards.grow(g,type,p.uid)
  if tool!="" and tool not in used: used.append(tool)
  g._cleanup()

static func spell(g, c: Dictionary, targets: Array, count: int=1) -> void:
 for repeat in range(count): _spell_once(g,c,targets)

static func _spell_once(g, c: Dictionary, targets: Array) -> void:
 var p=c.payload.duplicate(true)
 p.replay=true
 if p.get("target","")!="":
  var equipment=g._equipment(p.target)
  if equipment.is_empty() or equipment.durability<=0 or not g._outer(equipment):
   g._emit("event","余势复演：原目标已解除，跳过额外施法。",{"replay":{"type":p.type,"skipped":true}})
   return
  p.damage=g.BasicAttacks.fireball_damage(g)*g.Cards.spell_power(g,p.type).get("equipment_damage_factor",0.0)
 else:
  targets=targets.filter(func(id):return not g._enemy(id).is_empty() and not g._enemy(id).gone)
  if targets.is_empty():
   g._emit("event","余势复演：原目标已离场，跳过额外施法。",{"replay":{"type":p.type,"skipped":true}})
   return
  p.damage=g.BasicAttacks.fireball_damage(g)
 g._emit("event","余势复演：免费额外施放火球术。",{"replay":{"type":p.type,"skipped":false}})
 var failed=g._magic_failed
 g._execute_attack({"payload":p,"label":"额外火球术","mana_payment":{"mana":0.0}},targets)
 g._magic_failed=failed
