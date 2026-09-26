extends RefCounted
const Game=preload("res://core/game.gd")
const Save=preload("res://tests/persistence_cases.gd")
const ShopCopy=preload("res://data/shop_copy.gd")

static func previous_tower_shop(t):
 var g=Game.new(37)
 g.state.room="floor_10_4";g.Services.start(g)
 var buy=g.command_facts().filter(func(c):return c.valid and c.payload.kind=="service" and c.payload.op=="take" and c.payload.payment=="self")[0]
 t.check(g.dispatch(g.command(buy.payload,g.state.version),g.state.version).ok and not g.get_view().shop.performance.is_empty(),"SHOP reentry fixture commits real payment in the old tower")
 return g

static func shop_entry_scope(t) -> void:
 var g=previous_tower_shop(t)
 g._restart_tower()
 var mana=g.state.mana;var flask=g.state.flask_mana
 t.check(t.action(g,"depart",{"room":"floor_10_4"}).ok and g.state.phase=="shop","SHOP new tower allows formal arrival at the repeated room id")
 t.check(g.state.mana==mana and g.state.flask_mana==flask and g.room_data(g.state.room).stock.all(func(row):return not row.taken),"SHOP entry does not pay or purchase any new stock")
 t.check(g.get_view().shop.performance.is_empty() and g.get_view().shop.greeting==ShopCopy.ENTRY,"SHOP new visit never inherits old tower payment presentation")
 var old=g.export_snapshot()
 for log in old.logs: log.data.erase("shop_entry")
 var restored=Game.new(1)
 t.check(restored.restore_snapshot(old).ok and restored.get_view().shop.performance.is_empty(),"SHOP legacy entry without a marker still stops at the previous phase")
 var buy=t.find_action(g,"service",{"op":"take","payment":"self"})
 t.check(g.dispatch(g.command(buy.payload,g.state.version),g.state.version).ok and not g.get_view().shop.performance.is_empty(),"SHOP new visit actual payment still opens its own performance")
 g.Services.start(g)
 t.check(g.get_view().shop.performance.is_empty(),"SHOP explicit reentry does not replay the preceding visit even without an intervening phase log")

static func merchant_speech(t) -> void:
 var g=Game.new(42,true,"shop")
 var shop_text=ShopCopy.ENTRY+ShopCopy.FLASK_PAYMENT+JSON.stringify(ShopCopy.BROWSE)+JSON.stringify(ShopCopy.INSUFFICIENT_FLASK)+JSON.stringify(ShopCopy.INSUFFICIENT_SELF_FREE)+JSON.stringify(ShopCopy.INSUFFICIENT_SELF_BOUND)+JSON.stringify(ShopCopy.PERFORMANCES)+JSON.stringify(ShopCopy.PLATE_SELF_BROWSE)+JSON.stringify(ShopCopy.PLATE_RELEASE_PERFORMANCES)
 t.check(not shop_text.contains("杂鱼") and not shop_text.contains("姐姐") and shop_text.contains("zako"),"SHOP shopkeeper copy consistently uses zako without the former address")
 t.check(g.get_view().shop.greeting==ShopCopy.ENTRY and g.get_view().shop.performance.is_empty(),"SHOP entry uses the approved merchant dialogue without a performance")
 var previous=""
 for i in range(2):
  var c=t.find_action(g,"service",{"op":"take","payment":"self"})
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"SHOP self payment follows actual purchase")
  var current=g.get_view().shop
  t.check(current.greeting=="" and current.performance.method=="self" and current.performance.text==ShopCopy.PERFORMANCES.self.text,"SHOP free upper body uses the approved self-payment performance")
  t.check(current.performance.id!=previous,"SHOP separate self payments give fresh frozen performance identities")
  previous=current.performance.id
 var before=g.export_snapshot()
 t.check(g.get_view().shop.performance.id==previous and g.export_snapshot()==before,"SHOP viewing performance identity is read-only")
 for i in range(14): g._emit("event","记录",{})
 t.check(g.get_view().shop.performance.id==previous and g.get_view().shop.performance.method=="self","SHOP unrelated logs do not replace the frozen performance")
 var bound=Game.new(42,true,"shop")
 bound.add_fixture("wrist",4)
 var bound_action=t.find_action(bound,"service",{"op":"take","payment":"self"})
 t.check(bound.level("arms")>0 and bound.dispatch(bound.command(bound_action.payload,bound.state.version),bound.state.version).ok,"SHOP restrained self payment commits normally")
 var bound_view=bound.get_view().shop
 t.check(bound_view.performance.method in ["sleeve","hand","foot"] and bound_view.performance.text==ShopCopy.PERFORMANCES[bound_view.performance.method].text,"SHOP restrained upper body freezes one approved assisted payment scene")
 var bound_before=bound.export_snapshot();var bound_id=bound_view.performance.id
 t.check(bound.get_view().shop.performance.id==bound_id and bound.export_snapshot()==bound_before,"SHOP assisted scene never rerolls while viewing")
 var flask=Game.new(42,true,"shop");flask.state.flask_mana=500
 var flask_action=t.find_action(flask,"service",{"op":"take","payment":"flask"})
 t.check(flask.dispatch(flask.command(flask_action.payload,flask.state.version),flask.state.version).ok,"SHOP flask payment commits normally")
 var flask_view=flask.get_view().shop
 t.check(flask_view.performance.is_empty() and flask_view.greeting==ShopCopy.FLASK_PAYMENT and flask_view.greeting_id.ends_with(":flask"),"SHOP flask payment uses ordinary approved merchant dialogue only")
 t.check(ShopCopy.chatter_pool("self",0,true)==ShopCopy.INSUFFICIENT_SELF_FREE and ShopCopy.chatter_pool("self",1,true)==ShopCopy.INSUFFICIENT_SELF_BOUND and ShopCopy.chatter_pool("flask",0,true)==ShopCopy.INSUFFICIENT_FLASK,"SHOP insufficient chatter follows selected payment and upper-body state")
 var plate=Game.new(42,true,"shop");plate.state.flask_mana=500
 var lock=plate._install_special("negative_plate_lock_medium","special_2_a",2)
 var plate_self=t.find_action(plate,"service",{"op":"take","payment":"self"})
 var plate_flask=t.find_action(plate,"service",{"op":"take","payment":"flask","index":plate_self.payload.index})
 t.check(not plate_self.valid and plate_self.reason==ShopCopy.PLATE_SELF_BLOCK_REASON and plate_self.get("copy_context","")=="plate_self_block","SHOP flat lock blocks own-mana product payment with its explicit chatter context")
 t.check(plate_flask.valid,"SHOP flat lock leaves flask payment available for the same product")
 var plate_release=t.find_action(plate,"service",{"op":"release","target":lock.id,"payment":"self"})
 t.check(plate_release.valid and plate.dispatch(plate.command(plate_release.payload,plate.state.version),plate.state.version).ok,"SHOP own-mana release remains available because the shopkeeper removes the flat lock before collecting payment")
 var plate_scene=plate.get_view().shop.performance
 t.check(plate._equipment(lock.id).is_empty() and plate_scene.method=="self" and plate_scene.text==ShopCopy.PLATE_RELEASE_PERFORMANCES.self.text and plate_scene.button=="完成付款","SHOP flat-lock release freezes the dedicated copy while retaining the original payment method")

static func rest_choice(t) -> void:
 var room_game=Game.new(42)
 var room_before=room_game.export_snapshot()
 var description=room_game.room_description(room_game.room_data("rest"))
 t.check(description.contains("扣3回合随机获得1张稀有卡") and description.contains("扣3回合选择1张罕见卡") and description.contains("扣3回合补充50魔瓶魔力") and description.contains("跳过奖励"),"REST map description matches all current reward choices and their actual costs")
 t.check(room_game.state==room_before,"REST room description leaves resources, facts and random state unchanged")
 var observed=[]
 for seed_value in range(8):
  var sample=Game.new(seed_value);sample.state.room="rest";sample._start_rest()
  var old_count=sample.state.deck.size()
  t.check(t.action(sample,"rest_rare").ok and sample.state.deck.size()==old_count+1 and sample.Cards.Rules.SPECS[sample.state.deck[-1].type].rarity=="rare","REST random rare always grants one registered gold card")
  observed.append(sample.state.deck[-1].type)
 t.check(observed.any(func(id):return id!=observed[0]),"REST rare reward varies with actual reward RNG")
 var short_rest=Game.new(42);short_rest.state.room="rest";short_rest._start_rest();short_rest.state.rest_left=2
 var short_before=short_rest.export_snapshot()
 t.check(not t.action(short_rest,"rest_rare").ok and short_rest.state==short_before,"REST insufficient time rejects rare claim without payment or random draw")
 for option in ["rare","uncommon","rest_flask","rest_begin"]:
  var is_card=option in ["rare","uncommon"]
  var kind=("rest_rare" if option=="rare" else "rest_card") if is_card else option
  var remaining_turns={"rare":3,"uncommon":3,"rest_flask":3,"rest_begin":6}[option]
  var g=Game.new(42)
  g.state.room="rest";g.state.mana=40;g.state.flask_mana=1000
  g.state.relics=["green_bird","spicy_rice_noodles","small_gem","olihakimi"]
  g.state.pressure_sources=[preload("res://tests/pressure_cases.gd").source("rest_test","turn_end",20)]
  g._install_template("rope","wrist",4,10,false,"fixture",1)
  var tick=g.state.tick;var serial=g.state.combat.serial;var offset=g.state.rare_offset
  g._start_rest()
  t.check(g.state.phase=="rest_choice" and g.state.rest_left==6 and g.state.tick==tick and g.state.combat.serial==serial and g.state.charge==0,"REST choice precedes opening effects")
  t.check(g.state.rest_cards.size()==3 and g.state.rest_cards.all(func(id):return g.Cards.Rules.SPECS[id].rarity=="uncommon") and g.state.rest_cards.all(func(id):return g.state.rest_cards.count(id)==1) and g.state.rare_offset==offset,"REST freezes only three distinct uncommon cards without altering rarity progression")
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(before==g.state and not t.find_action(g,"end").valid and not t.find_action(g,"rest_tool").valid,"REST selection does not tick or offer old services")
  var absent=g.Cards.Rules.REWARDS.filter(func(id):return g.Cards.Rules.SPECS[id].rarity=="rare" and id not in g.state.rest_cards)[0]
  t.check(not t.action(g,"rest_card",{"type":absent}).ok and g.state==before,"REST cannot claim an unoffered rare card")
  var twin=Save.roundtrip(t,g,"rest before rare selection") if option=="rare" else null
  var reward_rng=g.state.rng.reward
  var payload={"type":g.state.rest_cards.filter(func(id):return g.Cards.Rules.SPECS[id].rarity==option)[0]} if option=="uncommon" else {}
  var chosen=t.find_action(g,kind,payload);var version=g.state.version;var deck=g.state.deck.size()
  t.check(not g.dispatch(g.command(chosen.payload,version-1),version-1).ok and g.state==before,"REST stale claim preserves rewards, time and random state")
  t.check(g.dispatch(g.command(chosen.payload,version),version).ok and g.state.phase=="rest" and g.state.rest_left==remaining_turns,"REST correct remaining time after "+option)
  t.check(g.state.tick==tick+1 and g.state.combat.turn==1 and g.state.combat.serial==serial+1 and g.state.charge==2 and g.state.energy==4 and g.state.pressure==0 and g.state.mana==40,"REST no skipped-turn effects, exactly one real opening")
  t.check(g.state.deck.size()==deck+(1 if is_card else 0) and g.state.flask_mana==1000+(50 if option=="rest_flask" else 0),"REST grants only selected benefit")
  t.check((g.state.rng.reward!=reward_rng if option=="rare" else g.state.rng.reward==reward_rng) and g.state.rare_offset==offset,"REST only random rare selection consumes reward RNG without changing rarity correction")
  if is_card:
   var gained=g.state.deck[-1].type
   t.check(g.Cards.Rules.SPECS[gained].rarity==option and (option=="rare" or gained==payload.type),"REST grants exactly the requested rarity and chosen card")
   t.check(g.state.logs.any(func(log):return log.text.contains(g.B.CARD_NAMES[gained]) and log.text.contains("扣除%d回合，剩余%d回合休息" % [6-remaining_turns,remaining_turns])),"REST log identifies the actual card and paid rest duration")
  if twin!=null:
   t.check(t.action(twin,kind,payload).ok and Save.same(g.state,twin.state),"REST current snapshot preserves both offers and reproduces chosen card and opening effects")
  before=g.export_snapshot()
  t.check(not g.dispatch(g.command(chosen.payload,version),version).ok and g.state==before and ["rest_rare","rest_card","rest_flask"].all(func(action_kind):return not t.find_action(g,action_kind).valid),"REST cannot claim another benefit or replay the choice after entry")
  var remaining=g.state.rest_left
  for i in range(remaining): t.check(t.action(g,"end").ok,"REST remaining real turn")
  t.check(g.state.phase=="map" and not g.state.combat.active,"REST ends at selected duration")

static func flyer(t) -> void:
 var g=Game.new(42)
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="flyer")
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,"common",excluded)=="flyer","FLYER enters ordinary reward pool")
 g.state.flask_mana=1000;g.state.mana=61
 g.RelicEffects.gain(g,"flyer")
 t.check(g.state.flask_mana==1000 and g.state.mana==61,"FLYER pickup itself grants no mana")
 for kind in ["treasure","shop"]:
  arrive(g,kind)
  var id=g.room_data(g.state.room).next.filter(func(next):return g.room_data(next).kind==kind)[0]
  t.check(t.action(g,"depart",{"room":id}).ok,"FLYER actual route to "+kind)
  var stale={}
  while g.state.phase=="travel":
   var c=t.find_action(g,"travel_step")
   stale={"payload":c.payload,"version":g.state.version}
   t.check(t.action(g,"travel_step").ok,"FLYER real travel commits")
  var amount=1020 if kind=="shop" else 1000
  t.check(g.state.flask_mana==amount and g.state.mana==61 and g.state.energy==0,"FLYER only shop entry adds uncapped flask mana")
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(g.state==before and not g.dispatch(g.command(stale.payload,stale.version),stale.version).ok and g.state==before,"FLYER view and stale arrival cannot duplicate grant")
  g.state.flask_deposits=2
  g.Services.start(g)
  t.check(g.state.flask_mana==amount and g.state.flask_deposits==2,"FLYER reopening service never grants or resets manual deposits")
 t.check(g.state.logs.any(func(log):return log.data.get("relic_trigger",{}).get("id","")=="flyer" and log.text.contains("魔瓶补充20魔力")),"FLYER emits named flask trigger")
 var next_shop=g.state.rooms.filter(func(room):return room.kind=="shop" and not room.has("stock"))[0]
 g.state.room=next_shop.id;g.Services.start(g)
 t.check(g.state.flask_mana==1040 and g.state.flask_deposits==2,"FLYER each new shop grants again without using deposits")
 g=Game.new(42)
 g.state.room=g.state.rooms.filter(func(room):return room.kind=="shop")[0].id
 g.Services.start(g);g.RelicEffects.gain(g,"flyer");g.Services.start(g)
 t.check(g.state.flask_mana==0,"FLYER acquired inside shop does not retroactively trigger")

static func arrive(g, kind: String) -> void:
 var room=g.state.rooms.filter(func(r):return r.kind==kind)[0]
 var parent=g.state.rooms.filter(func(r):return room.id in r.next)[0]
 g.state.room=parent.id;g.state.phase="map";g.state.completed_rooms=[parent.id]

static func removal_prices(t) -> void:
 var g=Game.new(42)
 for index in range(4):
  var price=[30.0,50.0,70.0,90.0][index]
  if index>0: g._restart_tower(true)
  g.state.room=g.state.rooms.filter(func(room):return room.kind=="shop")[0].id;g.Services.start(g)
  var uid=g.state.deck[0].uid
  var payment="self" if index%2==0 else "flask"
  var field="mana" if payment=="self" else "flask_mana"
  g.state.mana=100;g.state.flask_mana=100;g.state.temporary_mana=100;g.state[field]=price-0.5
  var payload={"op":"remove","uid":uid,"payment":payment}
  var c=t.find_action(g,"service",payload);var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(c.mana==price and g.get_view().shop.remove_price==price and not c.valid and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"REMOVE progressive price is shared and insufficient selected balance cannot mix or increase count")
  g.state[field]=price;c=t.find_action(g,"service",payload);before=g.export_snapshot()
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"REMOVE stale selection cannot pay or raise future price")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state[field]==0 and g.state.shop_removals==index+1 and not g.state.deck.any(func(card):return card.uid==uid),"REMOVE actual purchases cost 30,50,70,90 across fresh towers and both payment pools")
  var committed=g.export_snapshot()
  t.check(not g.dispatch(g.command(c.payload,before.version),before.version).ok and g.state==committed,"REMOVE same purchase cannot advance the price twice")
  if index==1:
   var restored=Save.roundtrip(t,g,"progressive shop removal count")
   if restored!=null: g=restored
 var saved=g.export_snapshot();var bad=saved.duplicate(true);bad.shop_removals=-1
 t.check(not g.restore_snapshot(bad).ok and g.state==saved,"REMOVE invalid persisted count refuses atomically")
 t.check(Game.new(42).state.shop_removals==0 and g.Services.Data.removal_price(g.state.shop_removals)==110,"REMOVE a genuinely new game starts at thirty while the next removal costs 110")

static func refresh_stock(t) -> void:
 var g=Game.new(42,true,"shop")
 t.check(t.action(g,"service",{"op":"take","index":0,"payment":"self"}).ok and t.action(g,"service",{"op":"remove","payment":"self"}).ok,"REFRESH setup buys a card and uses removal")
 g.state.relics.append_array(["flyer","mana_earring"])
 g.state.mana=49.5;g.state.flask_mana=500.0;g.state.temporary_mana=1000.0
 var before=g.export_snapshot();var refresh=t.find_action(g,"service",{"op":"refresh","payment":"self"},false)
 g.get_view();g.command_facts()
 t.check(refresh.mana==50 and not refresh.valid and not g.dispatch(g.command(refresh.payload,g.state.version),g.state.version).ok and g.state==before,"REFRESH insufficient payment and previews preserve stock, count and RNG without mixing sources")
 g.state.mana=50.0;refresh=t.find_action(g,"service",{"op":"refresh","payment":"self"});before=g.export_snapshot()
 t.check(not g.dispatch(g.command(refresh.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"REFRESH stale request rejects before payment")
 t.check(g.dispatch(g.command(refresh.payload,g.state.version),g.state.version).ok and g.state.mana==0 and g.state.shop_refreshes==1,"REFRESH first refresh costs fifty")
 var room=g.room_data(g.state.room)
 t.check(room.stock.size()==12 and room.stock.all(func(row):return not row.taken) and room.stock!=before.rooms.filter(func(r):return r.id==g.state.room)[0].stock,"REFRESH replaces stock and refills sold slots")
 t.check(room.remove_used and g.state.shop_removals==before.shop_removals and g.state.deck==before.deck,"REFRESH preserves purchases and removal service usage")
 t.check(g.state.tick==before.tick and g.state.rng==before.rng and g.state.charge==before.charge and g.state.flask_mana==before.flask_mana and g.state.temporary_mana==before.temporary_mana,"REFRESH avoids spell, entry and combat RNG hooks")
 var saved=g.export_snapshot()
 t.check(not g.dispatch(g.command(refresh.payload,before.version),before.version).ok and g.state==saved,"REFRESH duplicate request cannot pay twice")
 var twin=Save.roundtrip(t,g,"global shop refresh count and frozen stock")
 if twin==null: return
 var stock=room.stock.duplicate(true)
 g.Services.start(g)
 t.check(g.room_data(g.state.room).stock==stock and t.find_action(g,"service",{"op":"refresh","payment":"flask"}).mana==100,"REFRESH reopening preserves stock and price")
 for sample in [g,twin]:
  var candidate=t.find_action(sample,"service",{"op":"refresh","payment":"flask"})
  t.check(candidate.mana==100 and sample.dispatch(sample.command(candidate.payload,sample.state.version),sample.state.version).ok and sample.state.flask_mana==400 and sample.state.shop_refreshes==2,"REFRESH second costs one hundred flask mana")
 t.check(g.room_data(g.state.room).stock==twin.room_data(twin.state.room).stock,"REFRESH snapshot reproduces next stock")
 var old_shop=g.state.room
 g.state.room=g.state.rooms.filter(func(r):return r.kind=="shop" and r.id!=old_shop)[0].id;g.Services.start(g)
 t.check(t.find_action(g,"service",{"op":"refresh","payment":"flask"}).mana==200,"REFRESH another shop preserves global cost")
 var balance=g.state.flask_mana
 t.check(t.action(g,"service",{"op":"refresh","payment":"flask"}).ok and g.state.flask_mana==balance-200 and g.state.shop_refreshes==3,"REFRESH third costs two hundred")
 for from_exit in [true,false]:
  g._restart_tower(from_exit)
  g.state.room=g.state.rooms.filter(func(r):return r.kind=="shop")[0].id;g.Services.start(g)
  t.check(t.find_action(g,"service",{"op":"refresh","payment":"flask"},false).mana==400,"REFRESH continuation and prison escape preserve cost")
 saved=g.export_snapshot()
 for invalid in [-1,"3"]:
  var bad=saved.duplicate(true);bad.shop_refreshes=invalid
  t.check(not g.restore_snapshot(bad).ok and g.state==saved,"REFRESH corrupt count rejects atomically")
 var fresh=Game.new(42,true,"shop")
 t.check(t.find_action(fresh,"service",{"op":"refresh","payment":"self"}).mana==50,"REFRESH new game resets cost")
 fresh.state.relics.append("membership_card");fresh.state.flask_mana=100.0
 t.check(t.find_action(fresh,"service",{"op":"refresh","payment":"flask"}).mana==25 and t.action(fresh,"service",{"op":"refresh","payment":"flask"}).ok and fresh.state.flask_mana==75,"REFRESH uses membership discount")
 fresh._install_special("negative_plate_lock_medium","special_2_a",2)
 before=fresh.export_snapshot()
 t.check(not t.action(fresh,"service",{"op":"refresh","payment":"self"}).ok and fresh.state==before,"REFRESH flat lock blocks own payment")
 t.check(t.action(fresh,"service",{"op":"refresh","payment":"flask"}).ok and fresh.state.flask_mana==25,"REFRESH flat lock permits bottle payment")
 var chest=Game.new(42);chest.state.room=chest.state.rooms.filter(func(r):return r.kind=="treasure")[0].id;chest.Services.start(chest)
 t.check(not chest.command_facts().any(func(c):return c.payload.kind=="service" and c.payload.op=="refresh"),"REFRESH absent from treasure")

static func treasure_with_plate(t) -> void:
 var g=Game.new(42)
 g.state.room=g.state.rooms.filter(func(r):return r.kind=="treasure")[0].id;g.Services.start(g)
 var room=g.room_data(g.state.room)
 room.stock=[{"kind":"relic","type":"small_sigil","price":0.0,"taken":false}]
 g._install_special("negative_plate_lock_medium","special_2_a",2)
 g.state.mana=0;g.state.flask_mana=0
 var before=g.export_snapshot();var claim=t.find_action(g,"service",{"op":"take","index":0})
 var reward=g.get_view().battle_rewards[0]
 t.check(claim.valid and claim.mana==0 and not claim.payload.has("payment") and reward.available and reward.reason=="","TREASURE flat lock and empty mana do not block free reward or show shop restrictions")
 t.check(not g.dispatch(g.command(claim.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"TREASURE stale free claim cannot change equipment, resources or reward")
 t.check(g.dispatch(g.command(claim.payload,g.state.version),g.state.version).ok and "small_sigil" in g.state.relics and g.state.mana==0 and g.state.flask_mana==0 and g.state.special_equipment==before.special_equipment,"TREASURE free relic claim succeeds with the lock still equipped")
 var after=g.export_snapshot()
 t.check(not t.action(g,"service",{"op":"take","index":0}).ok and g.state==after,"TREASURE collected reward cannot be claimed twice")

# docs/spec/transition-pipeline.md「证据入口」：代表性非迁移提交不写状态（迁移日志为空、阶段／房间不变）。
static func non_transitions_do_not_write(t) -> void:
 var arch=preload("res://tests/architecture_cases.gd")
 var cases=[]
 var battle=preload("res://tests/game_fixture.gd").new(42)
 battle.add_fixture("thigh",4,10)
 cases.append({"name":"card","game":battle,"command":func(g): return _play_first_card(t,g)})
 var turn=preload("res://tests/game_fixture.gd").new(42)
 cases.append({"name":"end_turn","game":turn,"command":func(g): return t.action(g,"end")})
 var shop=Game.new(42,true,"shop")
 cases.append({"name":"shop_trade","game":shop,"command":func(g): return t.action(g,"service",{"op":"take","index":0,"payment":"self"})})
 var event=Game.new(42,true,"succubus_magic_pawnshop")
 cases.append({"name":"event_choice","game":event,"command":func(g): return t.action(g,"event",{"action":"choose","choice":"small_trade"})})
 var prison=Game.new(42,true,"prison_test")
 cases.append({"name":"prison_action","game":prison,"command":func(g): return t.action(g,"wall_move",{"direction":"away"})})
 for entry in cases:
  var g=entry.game
  var before=arch.transition_log(g)
  var phase=String(g.state.phase);var room=String(g.state.room)
  var outcome=entry.command.call(g)
  t.check(outcome.ok,"TRANSITION IDLE the representative command commits "+entry.name+": "+str(outcome.get("error","")))
  t.check(arch.transition_delta(g,before).is_empty(),"TRANSITION IDLE no transition is logged "+entry.name+": "+str(arch.transition_delta(g,before)))
  t.check(String(g.state.phase)==phase and String(g.state.room)==room,"TRANSITION IDLE phase and room stay put "+entry.name+": "+String(g.state.phase)+"/"+String(g.state.room))

static func _play_first_card(t, g) -> Dictionary:
 var card=t.hand_card(g,"strain")
 return t.action(g,"card",{"uid":card.uid,"target":g.equipment_at("thigh")[0].id})
static func run(t) -> void:
 refresh_stock(t)
 preload("res://tests/universal_scanner_cases.gd").run(t)
 preload("res://tests/membership_card_cases.gd").run(t)
 non_transitions_do_not_write(t)
 preload("res://tests/unique_power_reward_cases.gd").shop(t)

 treasure_with_plate(t)
 removal_prices(t)
 m_donalds(t)
 var shop_practice=Game.new(42,true,"shop")
 t.check(shop_practice.state.phase=="shop" and shop_practice.state.practice and shop_practice.get_view().shop.stock.size()==12,"SHOP practice uses formal stock generation")
 t.check(shop_practice.restart_snapshot()==shop_practice.state and shop_practice.validate()=="","SHOP practice is a valid scene-start checkpoint")
 rest_choice(t)
 flyer(t)
 stock_layout(t)
 rarity_prices(t)
 merchant_speech(t)
 shop_entry_scope(t)
 for kind in ["shop","treasure"]:
  var g=Game.new(42)
  arrive(g,kind)
  var id=g.room_data(g.state.room).next.filter(func(next):return g.room_data(next).kind==kind)[0]
  t.check(t.action(g,"depart",{"room":id}).ok,"SERVICE enters real adjacent "+kind)
  while g.state.phase=="travel":t.action(g,"travel_step")
  t.check(g.state.phase==kind and g.state.energy==0 and g.state.mana==100 and g.state.reward_count==0,"SERVICE arrival grants no turn or battle recovery")
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(g.export_snapshot()==before,"SERVICE views never reroll stock")
  var twin=Game.new(3)
  t.check(twin.restore_snapshot(before).ok,"SERVICE stock restores through real snapshot validation")
  var c=t.find_action(g,"service",{"op":"take"})
  var price=c.mana
  var reward_count=g.state.relics.size()
  var stock=g.room_data(id).stock[c.payload.index]
  var pickup=g.Relics.TYPES[stock.type].modifiers.get("pickup_mana",0.0) if stock.kind=="relic" else 0.0
  t.check(t.action(g,"service",{"op":"take","index":c.payload.index}).ok and t.action(twin,"service",{"op":"take","index":c.payload.index}).ok,"SERVICE real claim succeeds after restore")
  t.check(g.state.mana==100-price+pickup and g.state.mana==twin.state.mana and g.state.mana_max==twin.state.mana_max and g.state.deck==twin.state.deck and g.state.relics==twin.state.relics and g.room_data(id).stock==twin.room_data(id).stock,"SERVICE exact price and reward deterministic")
  var committed=g.export_snapshot()
  t.check(not t.action(g,"service",{"op":"take","index":c.payload.index}).ok and g.export_snapshot()==committed,"SERVICE cannot claim same stock twice")
  if kind=="treasure":t.check(g.state.relics.size()==reward_count+1,"SERVICE chest grants one unique relic")
  t.check(t.action(g,"service",{"op":"leave"}).ok and g.state.phase=="map" and g.state.prepare_left==0,"SERVICE exit grants no preparation")
 var g=Game.new(42)
 var room=g.state.rooms.filter(func(r):return r.kind=="shop")[0]
 g.state.room=room.id;g.Services.start(g)
 g.state.mana=0
 var before=g.export_snapshot()
 t.check(not t.action(g,"service",{"op":"take"}).ok and g.export_snapshot()==before,"SERVICE insufficient mana preserves stock and state")
 g.state.mana=100;g.state.pressure=75;g.state.temporary_mana=15
 var c=t.find_action(g,"service",{"op":"take"})
 t.action(g,"service",{"op":"take","index":c.payload.index})
 t.check(g.state.mana==100-c.mana and g.state.temporary_mana==15,"SERVICE purchase is currency, no spell discount or reserve consumption")
 var uid=g.state.deck[0].uid
 var count=g.state.deck.size();var mana=g.state.mana
 var before_removal=g.export_snapshot()
 t.check(t.action(g,"service",{"op":"remove","uid":uid}).ok and g.state.deck.size()==count-1 and g.state.mana==mana-30 and g.state.shop_removals==1,"SERVICE first removal pays thirty and advances successful purchase count")
 t.check(["deck","draw","hand","discard","exhaust"].all(func(zone):return g.state[zone].all(func(card):return card.uid!=uid)) and not t.action(g,"service",{"op":"remove"}).ok,"SERVICE removed card disappears from every pile and service cannot repeat")
 t.check(["deck","draw","hand","discard","exhaust"].all(func(zone):return g.state[zone]==before_removal[zone].filter(func(card):return card.uid!=uid)) and g.state.rng==before_removal.rng and g.state.energy==before_removal.energy,"SERVICE removal preserves other physical cards, pile order and random domains")
 g.state.mana=100
 while g.carried_items()<g.item_capacity(): g._gain_tool("shard")
 var item_offer=g.room_data(g.state.room).stock.filter(func(o):return o.kind=="tool" and not o.taken)[0]
 var index=g.room_data(g.state.room).stock.find(item_offer)
 t.check(not t.find_action(g,"service",{"op":"take","index":index}).valid,"SERVICE full inventory blocks purchase before payment")
 t.action(g,"item_discard",{"item":g.state.items[0].id})
 var purchase=t.action(g,"service",{"op":"take","index":index})
 t.check(purchase.ok and g.carried_items()==g.item_capacity(),"SERVICE freeing space enables real item purchase: "+str(purchase.get("error",""))+"; carried="+str(g.carried_items()))
 before=g.export_snapshot();var bad=before.duplicate(true)
 bad.rooms.filter(func(r):return r.id==g.state.room)[0].stock[0].price=-1
 t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==before,"SERVICE damaged stock restore rolls back")
 # Fresh opening and ordinary combat progression use production Game, not fixtures.
 for seed in range(10):
  g=Game.new(seed)
  t.check(t.action(g,"departure",{"op":"skip"}).ok,"MAP starting bonus can be skipped before selecting first floor")
  t.check(g.state.phase=="map" and g.state.enemies.is_empty() and g.room_data("entrance").next.size()>=2,"MAP genuine opening offers multiple first-floor entries")
  var combats=g.state.rooms.filter(func(r):return r.get("pool","")=="ordinary")
  for i in range(4):
   var selected=combats[i]
   g.state.room=selected.id;g._start_battle()
   t.check(selected.encounter_selected==("weak" if i<3 or g.Enemies.FirstFloor.POOLS.strong.is_empty() else "strong") and (g.state.room_encounters[selected.id]=="weak_group" and selected.enemy_members.reduce(func(total,m):return total+g.Enemies.TYPES[m.type].strength,0)==2 if selected.encounter_selected=="weak" else g.state.room_encounters[selected.id] in g.Enemies.FirstFloor.POOLS.strong),"MAP first three ordinary combats use weak strength two, then registered strong combinations")
   g.state.completed_rooms.append(selected.id)

static func stock_layout(t) -> void:
 var seen_tools=[]
 for seed in range(32):
  var g=Game.new(seed);var twin=Game.new(seed)
  var initial_rng=g.state.rng.duplicate(true)
  for game in [g,twin]:
   game.state.rare_offset=-5 if game==g else 40
   game.state.room=game.state.rooms.filter(func(r):return r.kind=="shop")[0].id
   game.Services.start(game)
  var stock=g.room_data(g.state.room).stock
  var cards=stock.filter(func(o):return o.kind=="card")
  var tools=stock.filter(func(o):return o.kind=="tool")
  var relics=stock.filter(func(o):return o.kind=="relic")
  t.check(cards.size()==5 and cards.map(func(o):return g.Cards.Rules.SPECS[o.type].rarity)==["common","common","uncommon","uncommon","rare"],"SHOP fixed 2 common 2 uncommon 1 rare seed "+str(seed))
  t.check(tools.size()==4 and relics.size()==3 and stock.all(func(o):return stock.filter(func(other):return other.kind==o.kind and other.type==o.type).size()==1),"SHOP unique 5/4/3 stock seed "+str(seed))
  t.check(stock==twin.room_data(twin.state.room).stock and g.state.rare_offset==-5 and twin.state.rare_offset==40 and g.state.rng==initial_rng,"SHOP room seed reproduces stock independently of card rarity correction")
  for offer in tools:
   if offer.type not in seen_tools: seen_tools.append(offer.type)
   if g.Tools.TYPES[offer.type].get("category","") in ["potion","scroll"]:
    t.check(offer.price==15 and g.Consumables.description(g,offer.type) in g.Services.detail(g,offer),"SHOP consumable price and actual effect description")
  var before=stock.duplicate(true);var seen=g.state.relic_seen.duplicate();g.Services.start(g)
  t.check(stock==before and g.state.relic_seen==seen,"SHOP reopening does not refill or reserve new relics")
 t.check(preload("res://data/room_services.gd").TOOLS.all(func(id):return id in seen_tools),"SHOP seeded matrix covers all nine tools including six consumables")
 for left in [0,1,2]:
  var g=Game.new(42)
  g.state.relics.append_array(g.Relics.shop_pool().slice(left))
  g.state.room=g.state.rooms.filter(func(r):return r.kind=="shop")[0].id;g.Services.start(g)
  var stock=g.room_data(g.state.room).stock
  var relics=stock.filter(func(o):return o.kind=="relic")
  var ordinary=relics.filter(func(o):return o.type not in [g.Relics.FALLBACK,g.Relics.COMMON_FALLBACK])
  t.check(relics.size()==3 and stock.size()==12 and ordinary.size()<=left and ordinary.all(func(o):return ordinary.filter(func(other):return other.type==o.type).size()==1),"SHOP exhausted tiers use common cloak or other-tier logs; ordinary relics remain unique")

static func rarity_prices(t) -> void:
 var seen=[]
 var expected={"card":{"common":20.0,"uncommon":30.0,"rare":50.0},"relic":{"common":50.0,"uncommon":70.0,"rare":100.0,"special":45.0}}
 for seed in range(16):
  for source in ["self","flask"]:
   var g=Game.new(seed)
   g.state.room=g.state.rooms.filter(func(r):return r.kind=="shop")[0].id;g.Services.start(g)
   g.state.mana_max=2000;g.state.mana=1000;g.state.flask_mana=1000
   var stock=g.room_data(g.state.room).stock
   for index in range(stock.size()):
    var offer=stock[index]
    if offer.kind not in expected: continue
    var rarity=g.Cards.Rules.SPECS[offer.type].rarity if offer.kind=="card" else g.Relics.TYPES[offer.type].rarity
    var key=offer.kind+"/"+rarity+"/"+source
    if key in seen: continue
    seen.append(key)
    var price=expected[offer.kind][rarity]
    var candidate=t.find_action(g,"service",{"op":"take","index":index,"payment":source})
    var own=g.state.mana;var flask=g.state.flask_mana
    var pickup=g.Relics.TYPES[offer.type].modifiers.get("pickup_mana",0.0) if offer.kind=="relic" else 0.0
    t.check(offer.price==price and candidate.mana==price,"SHOP rarity price matches frozen stock and payment candidate "+key)
    t.check(g.dispatch(g.command(candidate.payload,g.state.version),g.state.version).ok and g.state.mana==own-(price if source=="self" else 0)+pickup and g.state.flask_mana==flask-(price if source=="flask" else 0),"SHOP both mana sources pay the exact rarity price "+key)
 t.check(seen.size()==12,"SHOP verifies all three card and relic rarities with both payment sources")

static func m_donalds_shop():
 for seed in range(256):
  var g=Game.new(seed,true,"shop")
  if g.room_data(g.state.room).stock.any(func(row):return row.kind=="relic" and row.type=="m_donalds"): return g
 return null

static func m_donalds(t) -> void:
 var g=m_donalds_shop()
 t.check(g!=null,"M SHOP actual seeded stock can generate the exclusive relic")
 if g==null: return
 var type="m_donalds"
 var excluded=g.Relics.REWARDS+g.Relics.BOSS_POOL
 for source in ["normal","small","medium","large","common","uncommon","rare","boss"]:
  t.check(g.RelicRewards.offer(g,source,null,excluded) in [g.Relics.FALLBACK,g.Relics.COMMON_FALLBACK] and type not in g.RelicRewards.available(g,source),"M SHOP exclusive relic is absent from non-shop source "+source)
 var rng=preload("res://tests/rolling_log_cases.gd").TierRandom.new("uncommon")
 excluded.append_array(g.Relics.shop_pool().filter(func(id):return id!=type and id not in excluded))
 t.check(g.RelicRewards.offer(g,"shop",rng,excluded)==type and g.Relics.TYPES[type].rarity=="uncommon","M SHOP joins the existing uncommon probability band")
 var index=g.room_data(g.state.room).stock.find(g.room_data(g.state.room).stock.filter(func(row):return row.type==type)[0])
 var row=g.get_view().shop.stock[index]
 t.check(row.price==70 and row.required_payment=="flask" and row.detail.contains("上限＋10") and row.detail.contains("回满"),"M SHOP price, payment restriction and exact effect are projected together")
 g.state.mana=100;g.state.flask_mana=69;g.state.temporary_mana=100
 var before=g.export_snapshot()
 var own=t.find_action(g,"service",{"op":"take","index":index,"payment":"self"},false)
 var bottle=t.find_action(g,"service",{"op":"take","index":index,"payment":"flask"},false)
 t.check(not own.valid and own.reason=="仅可使用魔瓶购买。" and not g.dispatch(g.command(own.payload,g.state.version),g.state.version).ok and g.state==before,"M SHOP self payment is rejected atomically despite sufficient personal mana")
 t.check(not bottle.valid and not g.dispatch(g.command(bottle.payload,g.state.version),g.state.version).ok and g.state==before,"M SHOP cannot combine bottle balance with personal or temporary mana")
 g.state.mana_max=135;g.state.mana=7;g.state.flask_mana=70;g.state.pressure=99
 g._install_template("mouth_band","mouth",24,24,false,"fixture",3)
 bottle=t.find_action(g,"service",{"op":"take","index":index,"payment":"flask"},false)
 before=g.export_snapshot()
 t.check(bottle.valid and bottle.mana==70 and not g.dispatch(g.command(bottle.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"M SHOP current payment ignores spell multipliers; stale purchase does nothing")
 t.check(g.dispatch(g.command(bottle.payload,g.state.version),g.state.version).ok and g.state.flask_mana==0 and g.state.mana_max==145 and g.state.mana==145 and g.state.temporary_mana==100 and g.state.energy==before.energy,"M SHOP purchase pays only bottle and restores full personal mana after increasing the actual cap")
 t.check(g.room_data(g.state.room).stock[index].taken and type in g.state.relics and type not in g.RelicRewards.available(g,"shop") and g.validate()=="","M SHOP purchase sells out, excludes owned relic and leaves valid state")
 before=g.export_snapshot();g.RelicEffects.gain(g,type)
 t.check(g.state==before and not t.action(g,"service",{"op":"take","index":index,"payment":"flask"}).ok,"M SHOP repeated pickup cannot repeat the permanent gain")
 var entry=preload("res://data/encyclopedia.gd").entries().filter(func(e):return e.category=="relics" and e.id==type)[0]
 t.check(entry.group=="商店限定" and entry.rarity=="uncommon" and entry.text.contains("魔瓶"),"M SHOP encyclopedia identifies exclusive source and payment")
