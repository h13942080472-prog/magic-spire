extends RefCounted
const Data=preload("res://data/card_enchantments.gd")
const Rules=preload("res://data/card_rules.gd")

static func ordinary(g, card: Dictionary) -> bool:
 return Rules.SPECS.has(card.get("type","")) and Rules.SPECS[card.type].card_type not in ["curse","status"] and not g.B.CARD_TRAITS.get(card.type,{}).get("temporary",false)

static func original_cost(type: String, free: bool, x: int=0) -> int:
 return x if Rules.SPECS[type].get("x_cost",false) else Rules.energy_cost(type,free)

static func face_eligible(g, type: String, id: String, free: bool, x: int=0) -> bool:
 var tags=Rules.type_tags(type,free)
 match id:
  "fickle": return original_cost(type,free,x)>0
  "sow_skill": return "skill" in tags and original_cost(type,free,x)>=2
  "adept": return "magic" in tags
  "sow_power","blessing": return Rules.SPECS[type].card_type=="power"
  "replay": return not Rules.unique_face(type,free)
 return true

static func eligible(g, card: Dictionary, id: String) -> bool:
 if not ordinary(g,card) or not Data.TYPES.has(id) or card.get("enchantment","")==id: return false
 var type=card.type
 var traits=g.B.CARD_TRAITS.get(type,{})
 if id in ["innate","retain"] and traits.get(id,false): return false
 if id in ["recycle","recycle2","exhaust"] and Rules.SPECS[type].card_type=="power": return false
 if id in ["recycle","recycle2"] and [false,true].any(func(free):return Rules.exhausts(type,free,traits)): return false
 if id=="powerful" and not Rules.damage(type): return false
 return [false,true].any(func(free):return face_eligible(g,type,id,free,2))

static func prepare(g) -> void:
 var room=g.room_data(g.state.room)
 if room.kind!="rest" or room.has("enchantments"): return
 room.enchantments={"used":false,"refreshes":0,"offers":[]}
 roll(g)

static func roll(g) -> void:
 var room=g.room_data(g.state.room)
 var rng=RandomNumberGenerator.new()
 rng.seed=int(g.state.seed)+int(g.state.tower_generation)*1000003+int(room.id.hash())+573901+room.enchantments.refreshes*1000033
 var pool=Data.TYPES.keys().filter(func(id):return g.state.deck.any(func(card):return eligible(g,card,id)))
 room.enchantments.offers=[]
 for rarity in ["common","common","rare"]:
  var options=pool.filter(func(id):return Data.TYPES[id].rarity==rarity)
  if options.is_empty(): options=pool.duplicate()
  if options.is_empty(): break
  var id=options[rng.randi_range(0,options.size()-1)]
  room.enchantments.offers.append(id);pool.erase(id)

static func facts(g) -> Array:
 var out=[]
 var service=g.room_data(g.state.room).get("enchantments",{})
 if service.is_empty() or service.used: return out
 for id in service.offers:
  var spec=Data.TYPES[id]
  var turns=Data.TURNS[spec.rarity]
  for card in g.state.deck:
   if not eligible(g,card,id): continue
   out.append(g._fact({"kind":"enchant","op":"apply","enchantment":id,"uid":card.uid},"附魔 · "+spec.name,"花费%d回合。%s" % [turns,spec.detail],0,0.0,"需要更多休息回合。" if g.state.rest_left<turns else "","","rest_service"))
 var price=Data.refresh_price(service.refreshes)
 var issue="没有可附魔的卡牌。" if not Data.TYPES.keys().any(func(id):return g.state.deck.any(func(card):return eligible(g,card,id))) else ("需要更多休息回合。" if g.state.rest_left<2 else "")
 for payment in ["self","flask"]:
  out.append(g._fact({"kind":"enchant","op":"refresh","payment":payment},"刷新附魔 · %s魔力" % g.number(price),"重新选择附魔词条。",0,price,issue,"","rest_service"))
 return out

static func execute(g, p: Dictionary) -> void:
 var service=g.room_data(g.state.room).enchantments
 if p.op=="refresh":
  service.refreshes+=1
  roll(g)
  return
 for zone in ["deck"]+g.Cards.ZONES:
  for card in g.state[zone]:
   if card.uid!=p.uid: continue
   card.enchantment=p.enchantment
   card.erase("enchant_used");card.erase("enchant_pending")
 service.used=true
 g.state.rest_left-=Data.TURNS[Data.TYPES[p.enchantment].rarity]
 g._emit("event","附魔完成："+Data.TYPES[p.enchantment].name+"。")

static func panel(g, facts: Array) -> Dictionary:
 var service=g.room_data(g.state.room).get("enchantments",{})
 var out={"used":service.get("used",false),"offers":[],"refresh_keys":[]}
 for id in service.get("offers",[]):
  var entry=Data.TYPES[id].duplicate(true)
  entry.id=id;entry.turns=Data.TURNS[entry.rarity];entry.cards=[]
  for fact in facts:
   if fact.payload.kind!="enchant" or fact.payload.op!="apply" or fact.payload.enchantment!=id: continue
   var source=g.state.deck.filter(func(card):return card.uid==fact.payload.uid)[0]
   var card=source.duplicate(true)
   card.action_key=fact.key;card.available=fact.valid
   card.text=g.live_card_text(card.type,card.uid)
   entry.cards.append(card)
  out.offers.append(entry)
 out.refresh_keys=facts.filter(func(f):return f.payload.kind=="enchant" and f.payload.op=="refresh").map(func(f):return f.key)
 return out

static func card_for(g, uid: String="") -> Dictionary:
 if uid!="": return g.Cards.instance(g,uid)
 return g.state.play[0] if not g.state.play.is_empty() else {}

static func has_trait(g, card: Dictionary, trait_id: String) -> bool:
 return g.B.CARD_TRAITS.get(card.type,{}).get(trait_id,false) or card.get("enchantment","")==trait_id

static func multiplier(g, uid: String="") -> float:
 return 1.5 if card_for(g,uid).get("enchantment","")=="powerful" else 1.0

static func guaranteed(g, uid: String) -> bool:
 return uid!="" and card_for(g,uid).get("enchantment","")=="adept"

static func replay_count(g, card: Dictionary, free: bool) -> int:
 return int(card.get("enchantment","")=="replay" and not Rules.unique_face(card.type,free))

static func begin_play(card: Dictionary, p: Dictionary) -> void:
 if card.has("enchantment"): card.enchant_pending={"free":p.free,"x":p.get("x",0)}

static func after_play(g, card: Dictionary) -> void:
 if not card.has("enchant_pending"): return
 var pending=card.enchant_pending
 card.erase("enchant_pending")
 var id=card.enchantment
 var used=int(card.get("enchant_used",0))
 card.enchant_used=used+1
 if not face_eligible(g,card.type,id,pending.free,pending.x): return
 match id:
  "nimble": g._draw(1)
  "fickle":
   if pending.free: g.Cards.apply_effects(g,[{"op":"mana","amount":5}],{},Data.TYPES[id].name)
   else: g._gain_charge(1)
  "sow_power","sow_skill": g._gain_energy(1)
  "strengthen": g.Cards.grant_buff(g,"enchantment_strengthen")
  "blessing": g.Cards.grant_buff(g,"enchantment_blessing")
  "absorb":
   if used==0: g.Cards.apply_effects(g,[{"op":"mana","amount":20}],{},Data.TYPES[id].name)
  "swift":
   if used==0: g._draw(3)

static func drawn(g, card: Dictionary) -> void:
 if card.get("enchantment","")=="nexus": g._gain_energy(1)

# Resolve extra draws while the physical card is still outside both draw piles.
static func destination(g, card: Dictionary, exhaust: bool) -> String:
 var id=card.get("enchantment","")
 var used=int(card.get("enchant_used",0))
 if id in ["recycle","recycle2"] and used<=(2 if id=="recycle2" else 1):
  return "hand" if g.state.hand.size()<g.B.HAND_LIMIT else "discard"
 if id=="exhaust":
  var native=[false,true].any(func(free):return Rules.exhausts(card.type,free,g.B.CARD_TRAITS.get(card.type,{})))
  exhaust=used>=(2 if native else 1)
 return "exhaust" if exhaust else "discard"

static func reset(g) -> void:
 for zone in ["deck"]+g.Cards.ZONES:
  for card in g.state[zone]:
   card.erase("enchant_used");card.erase("enchant_pending")

static func text(g, card: Dictionary) -> Dictionary:
 var id=card.get("enchantment","")
 if not Data.TYPES.has(id): return {}
 var spec=Data.TYPES[id]
 var name=spec.name
 var used=int(card.get("enchant_used",0))
 if id in ["recycle","recycle2"]:
  var left=maxi(0,(2 if id=="recycle2" else 1)-used)
  if left==0: return {}
  name="回收"+(str(left) if left>1 else "")
 elif id=="exhaust":
  var native=[false,true].any(func(free):return Rules.exhausts(card.type,free,g.B.CARD_TRAITS.get(card.type,{})))
  if native and used==0: name="消耗2"
 return {"id":"enchantment_"+id,"name":name,"detail":spec.detail,"rarity":spec.rarity}

static func decorate_text(g, type: String, uid: String, free: bool, body: String) -> String:
 var card=card_for(g,uid) if uid!="" else {}
 var term=text(g,card)
 if term.is_empty() or not face_eligible(g,type,card.enchantment,free,2): return body
 return body+term.name+"。"

static func show_native_exhaust(g, uid: String) -> bool:
 return uid=="" or card_for(g,uid).get("enchantment","")!="exhaust"

static func card_issue(g, card: Dictionary, zone: String) -> String:
 if card.has("enchantment") and (not card.enchantment is String or not Data.TYPES.has(card.enchantment) or not ordinary(g,card)): return "卡牌附魔记录有误。"
 if card.has("enchant_used") and (not card.has("enchantment") or not card.enchant_used is int or card.enchant_used<0): return "附魔次数记录有误。"
 if card.has("enchant_pending"):
  if zone!="play" or not card.has("enchantment") or not card.enchant_pending is Dictionary or not card.enchant_pending.get("free") is bool or not card.enchant_pending.get("x") is int or card.enchant_pending.x<0: return "附魔结算记录有误。"
 return ""

static func room_issue(room: Dictionary) -> String:
 if room.has("rest_reward_used") and (room.kind!="rest" or not room.rest_reward_used is bool): return "火堆服务记录有误。"
 if not room.has("enchantments"): return ""
 var value=room.enchantments
 if room.kind!="rest" or not value is Dictionary or not value.get("used") is bool or not value.get("refreshes") is int or value.refreshes<0 or not is_finite(Data.refresh_price(value.refreshes)) or not value.get("offers") is Array or value.offers.size()>3: return "火堆附魔记录有误。"
 var seen=[]
 for id in value.offers:
  if not id is String or not Data.TYPES.has(id) or id in seen: return "附魔选项记录有误。"
  seen.append(id)
 return ""
