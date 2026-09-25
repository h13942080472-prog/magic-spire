extends RefCounted
const Data=preload("res://data/room_services.gd")
const ShopCopy=preload("res://data/shop_copy.gd")

static func start(g) -> void:
 var room=g.room_data(g.state.room)
 g._apply_transition("shop_enter",{"phase":room.kind});g.state.wall=room.wall;g.state.energy=0;g.state.enemies=[]
 if not room.has("stock"):
  room.remove_used=false
  if room.kind=="shop": g.RelicEffects._mana_hook(g,"shop_flask_mana","进入商店","flask_mana")
  _restock(g,room)
 g._emit("event","来到魔力商店。商品已摆好，价格以魔力结算。" if room.kind=="shop" else "发现遗物宝箱，可以打开领取，也可以直接离开。",{"shop_entry":{"room":room.id}} if room.kind=="shop" else {})

static func _restock(g, room: Dictionary, refresh: int=0) -> void:
 room.stock=[]
 var rng=RandomNumberGenerator.new()
 # Refreshes have a deterministic stock stream without advancing combat/reward RNG.
 rng.seed=int(g.state.seed)+int(g.state.tower_generation)*1000003+int(room.id.hash())+194701+refresh*1000033
 if room.kind=="shop":
  for rarity in Data.CARD_SLOTS:
   var pool=g.Cards.Rules.REWARDS.filter(func(type):return g.Cards.Rules.SPECS[type].rarity==rarity)
   for type in g.reward_offer(pool,"fixed",rng,Data.CARD_SLOTS[rarity]):
    _add(room,"card",type,Data.CARD_PRICES[rarity])
  var tools=Data.TOOLS.duplicate()
  for i in range(mini(Data.TOOL_SLOTS,tools.size())):
   var type=tools.pop_at(rng.randi_range(0,tools.size()-1))
   _add(room,"tool",type,Data.PRICES[type])
 if room.kind=="treasure": room.chest_size=g.RelicRewards.chest(g,rng)
 for i in range(Data.RELIC_SLOTS if room.kind=="shop" else 1):
  var excluded=room.stock.filter(func(row):return row.kind=="relic").map(func(row):return row.type)
  var relic=g.RelicRewards.offer(g,"shop" if room.kind=="shop" else room.chest_size,rng,excluded)
  _add(room,"relic",relic,Data.RELIC_PRICES[g.Relics.TYPES[relic].rarity] if room.kind=="shop" else 0.0)

static func _add(room: Dictionary, kind: String, type: String, price: float) -> void:
 room.stock.append({"kind":kind,"type":type,"price":price,"taken":false})

static func name(g, offer: Dictionary) -> String:
 match offer.kind:
  "card": return g.B.CARD_NAMES[offer.type]
  "tool": return g.Tools.TYPES[offer.type].name
  "relic": return g.Relics.TYPES[offer.type].name
 return ""

static func detail(g, offer: Dictionary) -> String:
 match offer.kind:
  "card": return g.CopyRouter.two_face(g,offer.type)
  "tool":
   return "共%d次使用。\n" % g.Tools.TYPES[offer.type].uses+g.Tools.description(g,offer.type)
  "relic": return g.Relics.RARITIES[g.Relics.TYPES[offer.type].rarity]+"遗物 · "+g.Relics.TYPES[offer.type].detail
 return ""

static func discounted_price(g, base: float) -> float:
 # Stored stock prices stay undiscounted; every quote derives from current relics.
 var price=base
 if g.state.phase=="shop":
  for id in g.state.relics: price*=maxf(0.0,1.0-g.RelicEffects.definition(g,id).modifiers.get("shop_discount_percent",0.0)/100.0)
 return price

static func payment_notice(g, source: String) -> String:
 if source=="self" and g.state.special_equipment.any(func(item):return item.get("durability",0)>0 and g.SpecialEquipment.is_chastity(item)):
  return ShopCopy.PLATE_SELF_BLOCK_REASON
 return ""

# R3（docs/ondemand-copy.md §11.5）：「购买／解除／移除」三处文案的 builder，正文留在本模块。
static func offer_detail(g, args: Dictionary) -> String:
 return detail(g,args.get("offer",{}))

static func release_job_detail(_g, args: Dictionary) -> String:
 var job=args.get("job",{})
 return String(job.get("detail",""))+"\n"+String(job.get("price_detail",""))

static func remove_card_detail(_g, _args: Dictionary) -> String:
 return "永久移除这张牌。本店仅能使用一次。"

static func refresh_detail(_g, _args: Dictionary) -> String:
 return "重新随机全部商品并补满货位。每次刷新后价格翻倍，换店不重置。"

static func leave_detail(_g, _args: Dictionary) -> String:
 return "保留已获得的物品，继续向上一层前进。"

# 付费服务的显示事实（批 R5：行生产转发改显示事实构建，docs/spec/candidate-removal.md §2.1 T5／T8）：
# 每个付费服务按支付来源产出各自的显示点（自身魔力／魔瓶），供投影与提交复核共用。
static func paid_fact(g, payload: Dictionary, label: String, info, price: float, reason: String, group: String, required_payment: String="") -> Array:
 var out=[]
 for source in (["self","flask"] if g.state.phase=="shop" else ["self"]):
  var action=payload.duplicate();action.payment=source
  var payment_reason=reason
  var plate_release=payload.get("op","")=="release" and g.SpecialEquipment.is_chastity(g._equipment(payload.get("target","")))
  var plate_blocked=reason=="" and not plate_release and required_payment!="flask" and payment_notice(g,source)!=""
  if required_payment!="" and source!=required_payment: payment_reason="仅可使用魔瓶购买。" if required_payment=="flask" else "仅可使用自身魔力购买。"
  elif plate_blocked: payment_reason=ShopCopy.PLATE_SELF_BLOCK_REASON
  var fact=g._fact(action,label,info,0,price,payment_reason,"",group)
  if plate_blocked:
   fact.copy_context="plate_self_block"
   fact.reason_scope="payment"
  out.append(fact)
 return out

static func facts(g) -> Array:
 var out=[]
 var room=g.room_data(g.state.room)
 for index in range(room.stock.size()):
  var offer=room.stock[index]
  if offer.taken: continue
  if offer.kind=="card" and not g.can_offer_card(offer.type): continue
  var reason=""
  if offer.kind=="tool" and g.carried_items()>=g.item_capacity(): reason="随身道具已满，请先放下一件。"
  if offer.kind=="relic" and not g.Relics.can_gain(g.state.relics,offer.type): reason="已经拥有这件遗物。"
  var payload={"kind":"service","op":"take","index":index}
  if room.kind=="treasure":
   var treasure_args={"offer":offer}
   out.append(g._fact(payload,"打开宝箱 · "+name(g,offer),{"kind":"service.offer","args":treasure_args,"fallback":offer_detail(g,treasure_args)},0,0.0,reason,"","service"))
  else:
   var required_payment=g.Relics.TYPES[offer.type].get("shop_payment","") if offer.kind=="relic" else ""
   var offer_args={"offer":offer}
   out.append_array(paid_fact(g,payload,"购买 · "+name(g,offer),{"kind":"service.offer","args":offer_args,"fallback":offer_detail(g,offer_args)},discounted_price(g,offer.price),reason,"service",required_payment))
 if room.kind=="shop":
  out.append_array(paid_fact(g,{"kind":"service","op":"refresh"},"刷新商品",{"kind":"service.refresh","args":{},"fallback":refresh_detail(g,{})},discounted_price(g,Data.refresh_price(int(g.state.get("shop_refreshes",0)))),"","service_refresh"))
  for job in release_jobs(g):
   var job_args={"job":job}
   out.append_array(paid_fact(g,{"kind":"service","op":"release","target":job.id},"解除「"+job.name+"」",{"kind":"service.release_job","args":job_args,"fallback":release_job_detail(g,job_args)},job.price,job.reason,"service_release"))
 if room.kind=="shop" and not room.remove_used:
  for card in g.state.deck:
   out.append_array(paid_fact(g,{"kind":"service","op":"remove","uid":card.uid},"移除「"+g.B.CARD_NAMES[card.type]+"」",{"kind":"service.remove_card","args":{},"fallback":remove_card_detail(g,{})},discounted_price(g,Data.removal_price(g.state.shop_removals)),"","service_remove"))
 out.append(g._fact({"kind":"service","op":"leave"},"离开房间",{"kind":"service.leave","args":{},"fallback":leave_detail(g,{})},0,0.0,"","","service_flow"))
 return out

static func execute(g, p: Dictionary) -> String:
 var room=g.room_data(g.state.room)
 if p.op=="leave":
  g._finish_preparation()
  return ""
 if p.op=="refresh":
  var trade=_shop_trade(g,p)
  g.state.shop_refreshes=int(g.state.get("shop_refreshes",0))+1
  _restock(g,room,g.state.shop_refreshes)
  g._emit("event","商店商品已刷新。",{"shop_trade":trade,"shop_refresh":{"count":g.state.shop_refreshes}})
  return ""
 if p.op=="release":
  var trade=_shop_trade(g,p)
  var jobs=release_jobs(g).filter(func(job):return job.id==p.target)
  if jobs.is_empty(): return "所选拘束具已经不在身上。"
  var job=jobs[0]
  if job.reason!="": return job.reason
  if job.pieces.any(func(id):
   var piece=g._equipment(id)
   return not piece.is_empty() and g.SpecialEquipment.is_chastity(piece)
  ): trade.copy_variant="plate_release"
  var removed=[]
  for id in job.pieces:
   var target=g._equipment(id)
   if target.is_empty(): return "所选装备的组成已经变化，请重新选择。"
   target.locked=false
   g._apply_manual_release(target,0.0)
   removed.append(target.id)
  g._emit("event","店主"+("先开锁，再" if job.locked else "")+"卸下了"+job.name+"。支付%s魔力。" % g.number(job.price),{"shop_release":{"room":g.state.room,"target":job.id,"name":job.name,"pieces":removed,"price":job.price,"composite":job.composite,"unlocked":job.locked},"shop_trade":trade})
  return ""
 if p.op=="remove":
  var trade=_shop_trade(g,p)
  var removed_type=g.Cards.remove_permanent(g,p.uid)
  if removed_type=="": return "所选卡牌已经不在卡组中。"
  var title=g.B.CARD_NAMES[removed_type]
  var price=discounted_price(g,Data.removal_price(g.state.shop_removals))
  room.remove_used=true
  g.state.shop_removals+=1
  g._emit("event","在商店移除了「"+title+"」，支付%s魔力。" % g.number(price),{"shop_trade":trade,"shop_card_removal":{"count":g.state.shop_removals,"price":price}})
  return ""
 var trade=_shop_trade(g,p) if room.kind=="shop" else {}
 var offer=room.stock[p.index]
 offer.taken=true
 match offer.kind:
  "card": g._gain_card(offer.type)
  "tool": g._gain_tool(offer.type)
  "relic": g.RelicEffects.gain(g,offer.type)
 var data={"shop_purchase":{"room":g.state.room,"kind":offer.kind,"type":offer.type}}
 if not trade.is_empty(): data.shop_trade=trade
 g._emit("event",("购买了" if room.kind=="shop" else "打开宝箱，获得")+name(g,offer)+"。",data)
 return ""

static func _shop_trade(g, p: Dictionary) -> Dictionary:
 var source=str(p.get("payment","self"))
 var arms_level=g.level("arms")
 var method="flask"
 if source=="self":
  if arms_level==0:
   method="self"
  else:
   var methods=["sleeve","hand","foot"]
   var target=str(p.get("target",p.get("uid",p.get("index",-1))))
   var key="%d:%s:%s:%s:%s:%d" % [g.state.seed,g.state.room,p.get("op",""),source,target,g.state.version]
   method=methods[posmod(key.hash(),methods.size())]
 return {"room":g.state.room,"source":source,"arms_level":arms_level,"method":method}

static func validate(g) -> String:
 if not g.Snapshot.fields(g.state,"shop_removals:i") or g.state.shop_removals<0: return "商店删牌次数不正确。"
 var refreshes=g.state.get("shop_refreshes",0)
 if not refreshes is int or refreshes<0: return "商店刷新次数不正确。"
 for room in g.state.rooms:
  if not room.has("stock"): continue
  if room.kind not in ["shop","treasure"] or not room.stock is Array or not room.get("remove_used") is bool: return "商品或宝箱记录损坏。"
  if room.kind=="treasure" and room.get("chest_size","") not in g.RelicRewards.CHESTS: return "宝箱大小记录损坏。"
  for offer in room.stock:
   if not g.Snapshot.fields(offer,"kind:s type:s price:n taken:b") or offer.price<0: return "商品记录不完整。"
   match offer.kind:
    "card":
     if not g.Character.reward_member(g,offer.type): return "商品卡牌不存在。"
    "tool":
     if offer.type not in Data.TOOLS: return "商品道具不存在。"
    "relic":
     if not g.Relics.is_reward(offer.type,room.kind): return "商品遗物不存在。"
    _: return "商品种类不存在。"
 if g.state.phase in ["shop","treasure"]:
  var current=g.room_data(g.state.room)
  if current.kind!=g.state.phase or not current.has("stock"): return "缺少本房间已经确定的商品。"
 return ""

# The provider has two free arms. Only target structure/exposure is inspected;
# the player's posture, limbs, spell chance and equipment are never falsified.
static func release_jobs(g) -> Array:
 if g.state.phase!="shop": return []
 var jobs=[]
 for item in g.state.equipment:
  var pieces=[item]
  pieces.append_array(g.Shoulders.attached(g,item))
  if g.Binding.present(item) and item.binding.kind=="linked": pieces.append(item.binding)
  jobs.append(_job(g,item.id,item.name,pieces,false))
 for root in g.state.composites:
  if g.Composites.active(root):
   jobs.append(_job(g,root.id,root.name,root.components,true))
  else:
   for part in root.components: jobs.append(_job(g,part.id,g._equipment_name(part),[part],false))
 for link in g.state.links: jobs.append(_job(g,link.id,link.name,[link],false))
 for lock in g.state.special_equipment:
  if not g.SpecialEquipment.is_chastity(lock) or lock.get("durability",0)<=0: continue
  var pieces=[lock]
  pieces.append_array(g.state.special_equipment.filter(func(item):return g.SpecialEquipment.is_reinforcement(item) and item.get("owner_id","")==lock.id and item.get("durability",0)>0))
  jobs.append(_job(g,lock.id,lock.name,pieces,false))
 return jobs

static func _job(g, id: String, title: String, pieces: Array, composite: bool) -> Dictionary:
 var locked=pieces.any(func(p):return p.locked)
 var base_price=Data.RELEASE.base+(Data.RELEASE.composite if composite else 0.0)+(Data.RELEASE.locked if locked else 0.0)
 var price=discounted_price(g,base_price)
 var reason="";var locations=[];var ids=[]
 for piece in pieces:
  ids.append(piece.id)
  if g.cursed_eyes(piece): reason="诅咒眼罩无法解除。"
  if g.Equipment.lock_only(piece): reason=g.Equipment.LOCK_ONLY_REASON
  if g.cursed_plate(piece): reason=g.SpecialEquipment.CURSED_PLATE_REASON
  for point in g.Equipment.display_points(piece):
   var label=g.Equipment.point_name(point)
   if label not in locations: locations.append(label)
  if reason=="" and not g._outer(piece): reason="有其他装备盖住这件拘束具，请先处理外层装备。"
 if g.state.special_equipment.any(func(item):return item.get("durability",0)>0 and g.SpecialEquipment.is_cursed_plate(item)): reason=ShopCopy.CURSED_PLATE_SERVICE_REASON
 var price_detail="基础%s魔力" % g.number(Data.RELEASE.base)
 if composite: price_detail+="＋复合处理%s" % g.number(Data.RELEASE.composite)
 if locked: price_detail+="＋开锁%s" % g.number(Data.RELEASE.locked)
 if price!=base_price: price_detail+="；折后%s魔力" % g.number(price)
 return {"id":id,"name":title,"pieces":ids,"composite":composite,"locked":locked,"price":price,"price_detail":price_detail,"location":"、".join(locations),"reason":reason,"detail":"店主用双手完整卸下这一件"+("及其全部组件" if composite else "及附带固定")+"。"+("费用包含开锁。" if locked else "")+"不消耗你的能量，不推进回合。"}

static func view(g) -> Dictionary:
 if g.state.phase not in ["shop","treasure"]: return {}
 var room=g.room_data(g.state.room);var stock=[]
 for index in range(room.stock.size()):
  var offer=room.stock[index]
  if offer.kind=="card" and not offer.taken and not g.can_offer_card(offer.type): continue
  stock.append({"index":index,"kind":offer.kind,"type":offer.type,"name":name(g,offer),"detail":detail(g,offer),"price":discounted_price(g,offer.price),"taken":offer.taken})
  if offer.kind=="relic":
   stock.back().required_payment=g.Relics.TYPES[offer.type].get("shop_payment","")
   stock.back().rarity=g.Relics.TYPES[offer.type].rarity
   stock.back().rarity_name=g.Relics.RARITIES[stock.back().rarity]
 var greeting=ShopCopy.ENTRY
 var greeting_id="shop:%s:entry" % g.state.room
 var performance={}
 for index in range(g.state.logs.size()-1,-1,-1):
  var log=g.state.logs[index]
  var data=log.data
  # Room ids repeat across towers. Only this visit can supply a payment scene.
  # The phase boundary also scopes older saves without an explicit entry marker.
  if log.get("phase","")!="shop" or data.has("shop_entry"): break
  if data.has("shop_trade") and data.shop_trade.get("room","")==g.state.room:
   var trade=data.shop_trade
   if trade.get("source","")=="flask":
    greeting=ShopCopy.FLASK_PAYMENT
    greeting_id="shop:%s:%d:flask" % [g.state.room,index]
   else:
    greeting=""
    performance=ShopCopy.performance(trade.get("method",""),trade.get("copy_variant",""))
    if not performance.is_empty():
     performance.id="shop:%s:%d:%s" % [g.state.room,index,trade.method]
     performance.method=trade.method
   break
 return {"chest_name":g.RelicRewards.CHESTS.get(room.get("chest_size",""),"遗物宝箱"),"stock":stock,"release_jobs":release_jobs(g),"remove_used":room.remove_used,"remove_price":discounted_price(g,Data.removal_price(g.state.shop_removals)),"greeting":greeting,"greeting_id":greeting_id,"performance":performance,"payment_notices":{"self":payment_notice(g,"self"),"flask":payment_notice(g,"flask")}}
