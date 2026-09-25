extends RefCounted

static func start(g, source: String) -> void:
 var entries=[]
 if source=="universal_scanner":
  g.state.relic_bundle={"source":source,"entries":entries}
  return
 for rarity in g.RelicRewards.TIERS:
  entries.append({"type":g.RelicRewards.offer(g,rarity),"rarity":rarity,"status":"pending"})
 g.state.relic_bundle={"source":source,"entries":entries}

# 遗物抽取包的显示事实（批 R5：行生产转发改显示事实构建，docs/spec/candidate-removal.md §2.1 T5／T8）。
static func facts(g) -> Array:
 var out=[]
 if g.state.relic_bundle.source=="universal_scanner":
  for card in copy_cards(g):
   var args={"card_type":card.type}
   out.append(g._fact({"kind":"relic_bundle","op":"copy","uid":card.uid,"type":card.type},"复制「"+g.B.CARD_NAMES[card.type]+"」",{"kind":"relic_bundle.claim","args":args,"fallback":claim_detail(g,args)},0,0.0,"","","reward"))
  out.append(g._fact({"kind":"relic_bundle","op":"finish"},"跳过",{"kind":"relic_bundle.finish","args":{},"fallback":finish_detail(g,{})},0,0.0,"","","reward"))
  return out
 for i in range(g.state.relic_bundle.entries.size()):
  var entry=g.state.relic_bundle.entries[i]
  if entry.status!="pending": continue
  var reason=g.RelicEffects.gain_reason(g,entry.type)
  if not g.Relics.can_gain(g.state.relics,entry.type): reason="已经拥有这件遗物。"
  var claim_args={"relic_id":entry.type}
  out.append(g._fact({"kind":"relic_bundle","op":"claim","index":i},"领取「"+g.Relics.TYPES[entry.type].name+"」",{"kind":"relic_bundle.claim","args":claim_args,"fallback":claim_detail(g,claim_args)},0,0.0,reason,"","reward"))
  out.append(g._fact({"kind":"relic_bundle","op":"skip","index":i},"跳过",{"kind":"relic_bundle.skip","args":{},"fallback":skip_detail(g,{})},0,0.0,"","","reward"))
 out.append(g._fact({"kind":"relic_bundle","op":"finish"},"返回奖励",{"kind":"relic_bundle.finish","args":{},"fallback":finish_detail(g,{})},0,0.0,"","","reward"))
 return out

# R4（docs/ondemand-copy.md §11.5）：直呼点文案改走路由，正文留在本模块。
static func copy_cards(g) -> Array:
 return g.state.deck.filter(func(card):return g.Cards.Rules.SPECS[card.type].rarity!="basic" and g.can_offer_card(card.type))

static func claim_detail(g, args: Dictionary) -> String:
 if args.has("card_type"): return "复制这张牌，加入你的卡组。"
 return g.Relics.TYPES[String(args.get("relic_id",""))].detail

static func skip_detail(_g, _args: Dictionary) -> String:
 return "放弃这件遗物，其他两件仍可领取。"

static func finish_detail(_g, _args: Dictionary) -> String:
 if _g.state.relic_bundle.get("source","")=="universal_scanner": return "放弃本次复制。"
 return "未领取的遗物将被放弃。"

static func execute(g, p: Dictionary) -> void:
 if g.state.relic_bundle.source=="universal_scanner":
  if p.op=="copy":
   var card=copy_cards(g).filter(func(entry):return entry.uid==p.uid)[0]
   g._gain_card(card.type,card)
   g._emit("event","扫描全能王：复制了「%s」。" % g.B.CARD_NAMES[card.type],{"relic_trigger":{"id":"universal_scanner","name":"扫描全能王"},"card_copy":{"source_uid":card.uid,"type":card.type}})
  else: g._emit("event","放弃本次复制。")
  g.state.relic_bundle={}
  return
 if p.op=="finish":
  var count=g.state.relic_bundle.entries.filter(func(entry):return entry.status=="pending").size()
  if count>0: g._emit("event","放弃套娃中剩余的%d件遗物。" % count)
  g.state.relic_bundle={}
  return
 var entry=g.state.relic_bundle.entries[p.index]
 entry.status="claimed" if p.op=="claim" else "skipped"
 if p.op=="claim": g.RelicEffects.gain(g,entry.type)
 else: g._emit("event","跳过「"+g.Relics.TYPES[entry.type].name+"」。")

static func panel(g, facts: Array) -> Dictionary:
 if g.state.relic_bundle.source=="universal_scanner":
  var cards=copy_cards(g)
  var copies=facts.filter(func(c):return c.payload.get("kind","")=="relic_bundle" and c.payload.op=="copy")
  var exits=facts.filter(func(c):return c.payload.get("kind","")=="relic_bundle" and c.payload.op=="finish")
  return {"active":true,"layout":"relic_bundle","selection":"card_copy","title":g.Relics.TYPES.universal_scanner.name,"destination":"选择一张牌复制。基础牌、双面唯一能力牌除外。" if not cards.is_empty() else "没有可复制的卡牌。","continue_key":String(exits[0].key),"continue_label":"跳过","extra_keys":[],"rows":[],"entries":[],"cards":cards.duplicate(true),"action_keys":copies.map(func(c):return String(c.key))}
 var entries=[]
 for i in range(g.state.relic_bundle.entries.size()):
  var saved=g.state.relic_bundle.entries[i]
  var entry=g.Relics.view([saved.type])[0]
  entry.index=i;entry.status=saved.status
  entry.rarity_label=g.Relics.RARITIES[saved.rarity]
  var matches=facts.filter(func(c):return c.payload.get("kind","")=="relic_bundle" and c.payload.get("index",-1)==i)
  entry.claim_key="";entry.skip_key="";entry.reason=""
  for c in matches:
   if c.payload.op=="claim": entry.claim_key=String(c.key);entry.reason=c.reason
   else: entry.skip_key=String(c.key)
  entries.append(entry)
 var exits=facts.filter(func(c):return c.payload.get("kind","")=="relic_bundle" and c.payload.op=="finish")
 return {"active":true,"layout":"relic_bundle","title":g.Relics.TYPES[g.state.relic_bundle.source].name,"destination":"三件遗物可分别领取或跳过。","continue_key":String(exits[0].key),"continue_label":"返回奖励  ›","extra_keys":[],"rows":[],"entries":entries}

static func validate(g, state: Dictionary) -> String:
 var bundle=state.get("relic_bundle")
 if not bundle is Dictionary: return "遗物待领取记录不完整。"
 if bundle.is_empty(): return ""
 if bundle.get("source","")=="universal_scanner":
  if bundle.size()!=2 or bundle.source not in state.relics or not bundle.get("entries") is Array or not bundle.entries.is_empty(): return "卡牌复制领取记录不正确。"
  return ""
 if bundle.size()!=2 or bundle.get("source","")!="nesting_doll" or bundle.source not in state.relics or not bundle.get("entries") is Array or bundle.entries.size()!=3: return "套娃奖励记录不正确。"
 var seen=[]
 for i in range(3):
  var entry=bundle.entries[i]
  if not entry is Dictionary or entry.size()!=3 or entry.get("rarity","")!=g.RelicRewards.TIERS[i] or entry.get("status","") not in ["pending","claimed","skipped"]: return "套娃遗物领取状态不正确。"
  var id=entry.get("type","")
  if id not in g.Relics.TYPES or id not in state.relic_seen: return "套娃遗物来源不正确。"
  if id!=g.Relics.FALLBACK:
   if id not in g.Relics.REWARDS or g.Relics.TYPES[id].rarity!=entry.rarity or id in seen: return "套娃遗物品质或重复记录不正确。"
   if not g.Relics.TYPES[id].get("collectible",false) and (id in state.relics)!=(entry.status=="claimed"): return "套娃遗物持有记录与领取状态不符。"
   if entry.status=="claimed" and id not in state.relics: return "套娃遗物领取记录缺少已获遗物。"
  elif entry.status=="claimed" and id not in state.relics: return "套娃遗物领取记录缺少已获遗物。"
  seen.append(id)
 return ""
