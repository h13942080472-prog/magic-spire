extends RefCounted

# Session progress uses the existing battle-buff lifetime and temporary-card zones.
static func level(g) -> int:
 for id in g.state.card_buffs:
  var value=int(g.Cards.Rules.BUFFS.get(id,{}).get("hannya_level",0))
  if value>0: return value
 return 0

static func mouth_restraint_value(g) -> int:
 var score=0
 for item in g.equipment_at("mouth"):
  var tightness=g.equipment_tier(item)
  if tightness>0: score=maxi(score,g.RestraintValue.from_profile(item.grade,tightness))
 return score

static func energy_cost(g) -> int:
 var score=mouth_restraint_value(g)
 return 1 if score<=2 else (2 if score<=4 else 3)

static func reason(g) -> String:
 if mouth_restraint_value(g)>=6: return "嘴部拘束为高级、紧度3档，无法饮用。"
 if g.restraint_degree("arms")>0 and g.state.posture not in ["sit","lie"]: return "上身受拘束，需要坐姿或躺姿饮用。"
 return ""

static func next_level(g, stage: int) -> int:
 var current=level(g)
 return 0 if stage<current or current==4 else current+1

static func detail(g, stage: int, free: bool) -> String:
 var next=next_level(g,stage)
 if next==0: return "当前般若汤%d级：本次仅将一张「好汤喝够饮饮饮饮」加入弃牌堆。" % level(g)
 var reward=g.Cards.Rules.HANNYA_REWARDS[next]
 return "般若汤%d → %d级：力量＋1、灵巧＋1，恢复5魔力。%s" % [level(g),next,reward["free" if free else "bound"]]

static func status_detail(g) -> String:
 var current=level(g)
 var text="力量＋%d，灵巧＋%d。" % [current,current]
 for id in ["hannya_short_strike","hannya_justice"]:
  if id in g.state.card_buffs: text+="\n"+g.Cards.Rules.BUFFS[id].detail
 return text+"\n各级升级奖励本场仅一次；低级或满级时仅生成好汤。"

static func heavy_bonus(g, type: String, form: int) -> int:
 return (2 if form==0 else 1) if type=="heavy" and "hannya_short_strike" in g.state.card_buffs else 0

static func give(g, type: String, hand: bool, messages: Array) -> void:
 var card=g._gain_temporary_card(type)
 assert(not card.is_empty())
 if hand and g._put_card_in_hand(card):
  g.state.discard.erase(card)
  messages.append("「%s」加入手牌" % g.B.CARD_NAMES[type])
 else:
  messages.append(("手牌已满，" if hand else "")+"「%s」加入弃牌堆" % g.B.CARD_NAMES[type])

static func resolve(g, p: Dictionary) -> void:
 # Repeating an effect is not another physical card play.
 if p.get("replay",false):
  g._emit("event","般若汤每级升级奖励仅领取一次。",{"card":p.type,"replay":true})
  return
 var old=level(g)
 var next=next_level(g,g.Cards.Rules.SPECS[p.type].hannya_stage)
 var messages=[]
 var mana_before=g.state.mana
 if next==0:
  give(g,"good_soup",false,messages)
 else:
  for id in g.state.card_buffs.duplicate():
   if g.Cards.Rules.BUFFS[id].has("hannya_level"): g.state.card_buffs.erase(id)
  g.Cards.grant_buff(g,"hannya_level_%d" % next)
  g.state.mana=minf(g.state.mana_max,g.state.mana+g.Cards.Rules.HANNYA_MANA_GAIN)
  messages.append("般若汤升至%d级，力量＋1、灵巧＋1，恢复%s魔力" % [next,g.number(g.state.mana-mana_before)])
  var reward=g.Cards.Rules.HANNYA_REWARDS[next]
  if next==1:
   var id="hannya_short_strike" if p.free else "hannya_justice"
   g.Cards.grant_buff(g,id);messages.append(g.Cards.Rules.BUFFS[id].detail.trim_suffix("。"))
  if reward.has("hand"): give(g,reward.hand,true,messages)
  give(g,reward.discard,false,messages)
 g._emit("event","打出「%s」。%s。" % [g.B.CARD_NAMES[p.type],"；".join(messages)],{"card":p.type,"free":p.free,"hannya_before":old,"hannya_after":level(g),"mana_gain":g.state.mana-mana_before})

static func prepare_innate(g) -> int:
 if not g.state.combat.active or g.state.combat.turn!=1: return 0
 var innate=g.state.draw.filter(func(c):return g.Enchantments.has_trait(g,c,"innate"))
 for card in innate:
  g.state.draw.erase(card);g.state.draw.append(card)
 # Enchanted Innate only reorders; native Innate retains its opening draw rule.
 return mini(innate.filter(func(card):return g.B.CARD_TRAITS.get(card.type,{}).get("innate",false)).size(),g.B.HAND_LIMIT)

static func validate(g) -> String:
 var levels=g.state.card_buffs.filter(func(id):return g.Cards.Rules.BUFFS[id].has("hannya_level"))
 var styles=g.state.card_buffs.filter(func(id):return id in ["hannya_short_strike","hannya_justice"])
 if levels.size()>1 or styles.size()>1 or levels.is_empty()!=styles.is_empty(): return "般若汤等级与首次饮用效果存在差异。"
 return ""
