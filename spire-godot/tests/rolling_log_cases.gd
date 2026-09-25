extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

class TierRandom extends RefCounted:
 var roll: int
 func _init(tier: String): roll={"common":0,"uncommon":50,"rare":83}[tier]
 func randi_range(_low: int, high: int) -> int: return roll if high==99 else 0

static func offer_tier(g, tier: String, excluded: Array=[]) -> String:
 return g.RelicRewards.offer(g,"normal",TierRandom.new(tier),excluded)

static func run(t) -> void:
 rediscovery(t)
 var g=Game.new(42)
 t.check(g.Relics.TYPES.rolling_log.rarity=="special" and g.Relics.TYPES.rolling_log.modifiers.is_empty() and "rolling_log" not in g.Relics.REWARDS,"LOG no-effect special collectible stays outside normal rarity pools")
 for tier in g.RelicRewards.TIERS:
  g=Game.new(42)
  var others=g.Relics.REWARDS.filter(func(id):return g.Relics.TYPES[id].rarity!=tier)
  g.state.relics.append_array(g.Relics.REWARDS.filter(func(id):return g.Relics.TYPES[id].rarity==tier))
  t.check(offer_tier(g,tier)==("intellect_cloak" if tier=="common" else "rolling_log") and others.all(func(id):return id not in g.state.relic_seen),"LOG exhausted tier uses its own fallback without consuming another tier: "+tier)
  var next=g.RelicRewards.TIERS[(g.RelicRewards.TIERS.find(tier)+1)%3]
  t.check(offer_tier(g,next)!="rolling_log","LOG nonempty tier still yields a normal relic")
 g=Game.new(42);g.state.relics.append_array(g.Relics.REWARDS)
 var before=g.export_snapshot()
 for i in range(3):
  t.check(offer_tier(g,"uncommon")=="rolling_log","LOG exhausted uncommon tier can repeatedly offer fallback")
  g.RelicEffects.gain(g,"rolling_log")
  t.check(g.RelicEffects.counter(g,"rolling_log").text==str(i+1),"LOG pickup increments quantity")
 t.check(g.state.relics.count("rolling_log")==1 and g.state.relic_seen.count("rolling_log")==1,"LOG one owned icon and one seen entry regardless of quantity")
 for key in ["energy","mana","mana_max","flask_mana","strength","dexterity","pressure","charge","tick"]:
  t.check(g.state[key]==before[key],"LOG pickup does not change gameplay resource: "+key)
 var frozen=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==frozen and g.RelicEffects.validate(g)=="","LOG quantity view is read-only and runtime-valid")
 t.check(t.action(g,"end").ok and g.state.relic_counters.rolling_log==3,"LOG quantity survives turns without ticking")
 # Real elite reward flow permits another copy even when already owned.
 g.state.room_encounters[g.state.room]="guard_solo";g._finish_battle()
 var dropped=g.state.battle_relic_drop
 var old_count=int(g.state.relic_counters.get(dropped,1))
 t.check(dropped in ["rolling_log","intellect_cloak"],"LOG elite exhaustion freezes the rolled tier fallback")
 var pick=t.find_action(g,"reward",{"category":"relic"});var version=g.state.version
 t.check(pick.valid and g.dispatch(g.command(pick.payload,version),version).ok and g.state.relic_counters[dropped]==old_count+1,"LOG existing owner can claim another elite fallback copy")
 frozen=g.export_snapshot()
 t.check(not g.dispatch(g.command(pick.payload,version),version).ok and g.state==frozen,"LOG stale claim cannot duplicate collectible")
 for kind in ["shop","treasure"]:
  g=Game.new(42);g.state.relics.append_array(g.Relics.shop_pool() if kind=="shop" else g.Relics.REWARDS);g.RelicEffects.gain(g,"rolling_log")
  g.state.room=g.state.rooms.filter(func(room):return room.kind==kind)[0].id
  g.state.flask_mana=200;g.Services.start(g)
  var stock=g.room_data(g.state.room).stock
  var logs=stock.filter(func(offer):return offer.kind=="relic")
  t.check(logs.size()==(3 if kind=="shop" else 1) and logs.all(func(offer):return offer.type in ["rolling_log","intellect_cloak"]),"LOG and cloak fill their exhausted "+kind+" relic slots")
  var original=stock.duplicate(true);g.Services.start(g)
  t.check(stock==original,"LOG revisiting does not reroll stock")
  before=g.export_snapshot()
  var quoted_payment=0.0
  for index in range(stock.size()):
   if stock[index].kind!="relic": continue
   var choice={"op":"take","index":index}
   if kind=="shop": choice.payment="flask"
   quoted_payment+=t.find_action(g,"service",choice).mana_payment.flask_mana
   t.check(t.action(g,"service",choice).ok,"LOG real "+kind+" pickup remains available with copies owned")
  var log_count=logs.filter(func(offer):return offer.type=="rolling_log").size()
  var cloak_count=logs.size()-log_count
  t.check(g.state.relic_counters.rolling_log==1+log_count and g.state.relic_counters.get("intellect_cloak",1)==1+cloak_count and g.state.mana==before.mana and g.state.mana_max==before.mana_max,"LOG and cloak acquisition increments the right counts with explicit shop payment")
  t.check(g.state.flask_mana==before.flask_mana-quoted_payment and ((quoted_payment>0)==(kind=="shop")),"LOG shop pays the actual quote including owned relic discounts, chest is free")
 t.check(Game.new(42).state.relic_counters.is_empty(),"LOG new runs do not inherit collectible count")

static func rediscovery(t) -> void:
 var g=Game.new(42)
 g.state.relic_seen=g.Relics.REWARDS.duplicate()
 var first=offer_tier(g,"common")
 t.check(first!=g.Relics.FALLBACK and offer_tier(g,"common")==first,"RELIC declined offers can recur in the same run even when every relic has been seen")
 var second=offer_tier(g,"common",[first])
 t.check(second!=first and second!=g.Relics.FALLBACK,"RELIC explicit current-batch exclusion prevents duplicate offers")
 g.RelicEffects.gain(g,first)
 t.check(first not in g.RelicRewards.available(g) and offer_tier(g,"common")!=first,"RELIC claimed relics remain excluded")
 var twin=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"seen relics remain eligible")
 if twin!=null: t.check(twin.RelicRewards.available(twin)==g.RelicRewards.available(g),"RELIC restored offer history does not exhaust unowned relics")
 g.state.room=g.state.rooms.filter(func(room):return room.kind=="shop")[0].id
 g.Services.start(g)
 var stock=g.room_data(g.state.room).stock
 var offers=stock.filter(func(row):return row.kind=="relic").map(func(row):return row.type)
 t.check(offers.size()==3 and offers.all(func(id):return id!=g.Relics.FALLBACK and id not in g.state.relics and offers.count(id)==1),"RELIC shop has three distinct unowned relics despite fully seen history")
 var frozen=stock.duplicate(true);g.Services.start(g)
 t.check(stock==frozen,"RELIC revisiting the same shop preserves its frozen stock")
 t.check(t.action(g,"service",{"op":"leave"}).ok,"RELIC leave shop through the normal action")
 preload("res://tests/event_cases.gd").arrive(g,"bound_dream_guest_room")
 var reward=g.state.room_event.relic
 t.check(reward!=g.Relics.FALLBACK and reward!="" and reward not in g.state.relics,"RELIC subsequent event in the same run still offers a real unowned relic")
 t.check(t.action(g,"event",{"action":"choose","choice":"take_core"}).ok and reward in g.state.relics,"RELIC event trade grants the frozen real relic rather than a seen-history fallback")
