extends RefCounted
const Game=preload("res://core/game.gd")
const TYPE="membership_card"

static func shop():
 for seed in range(512):
  var g=Game.new(seed,true,"shop")
  if g.room_data(g.state.room).stock.any(func(row):return row.type==TYPE): return g
 return null

static func run(t) -> void:
 var g=shop()
 t.check(g!=null,"MEMBERSHIP natural shop generation includes the rare exclusive relic")
 if g==null: return
 for source in ["normal","small","medium","large","rare"]:
  t.check(TYPE not in g.RelicRewards.available(g,source),"MEMBERSHIP absent from non-shop pool: "+source)
 t.check(TYPE not in g.Relics.BOSS_POOL and TYPE in g.RelicRewards.available(g,"shop") and g.Relics.TYPES[TYPE].rarity=="rare","MEMBERSHIP source and rarity use formal relic registry")
 var room=g.room_data(g.state.room)
 var index=room.stock.find(room.stock.filter(func(row):return row.type==TYPE)[0])
 var original_stock=room.stock.duplicate(true)
 g.state.mana=99;g.state.flask_mana=500;g.state.temporary_mana=500
 var before=g.export_snapshot()
 t.check(not t.action(g,"service",{"op":"take","index":index,"payment":"self"}).ok and g.state==before,"MEMBERSHIP cannot supplement personal balance with bottle or temporary mana")
 g.state.mana=100
 before=g.export_snapshot()
 var bottle=t.find_action(g,"service",{"op":"take","index":index,"payment":"flask"},false)
 t.check(not bottle.valid and bottle.reason=="仅可使用自身魔力购买。" and not g.dispatch(g.command(bottle.payload,g.state.version),g.state.version).ok and g.state==before,"MEMBERSHIP purchase rejects bottle payment atomically")
 var purchase=t.find_action(g,"service",{"op":"take","index":index,"payment":"self"})
 t.check(purchase.mana==100 and not g.dispatch(g.command(purchase.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"MEMBERSHIP own purchase stays full price and rejects stale version")
 t.check(g.dispatch(g.command(purchase.payload,g.state.version),g.state.version).ok and g.state.mana==0 and g.state.flask_mana==500 and g.state.temporary_mana==500,"MEMBERSHIP activates only after paying full personal price")
 room=g.room_data(g.state.room)
 t.check(TYPE in g.state.relics and TYPE not in g.RelicRewards.available(g,"shop"),"MEMBERSHIP owned nonstacking relic leaves the shop pool")
 var view=g.get_view().shop
 for row in view.stock:
  t.check(row.price==original_stock[row.index].price/2.0 and room.stock[row.index].price==original_stock[row.index].price,"MEMBERSHIP immediate half-price projection preserves original inventory price")
 for c in g.command_facts().filter(func(c):return c.payload.kind=="service" and c.payload.op=="take"):
  t.check(c.mana==original_stock[c.payload.index].price/2.0,"MEMBERSHIP both payment facts match displayed discounted goods")
 var first_card=room.stock.filter(func(row):return row.kind=="card")[0]
 g.state.mana=first_card.price/2.0-0.01
 before=g.export_snapshot()
 t.check(not t.action(g,"service",{"op":"take","index":room.stock.find(first_card),"payment":"self"}).ok and g.state==before,"MEMBERSHIP insufficient fractional discounted price rejects without mixed payment or mutation")
 g.state.mana=100;g.state.items=[]
 for kind in ["card","tool","relic"]:
  room=g.room_data(g.state.room)
  var offers=room.stock.filter(func(row):return row.kind==kind and not row.taken and row.type!="m_donalds")
  if offers.is_empty(): continue
  var row=offers[0];var at=room.stock.find(row)
  var old_flask=g.state.flask_mana
  t.check(t.action(g,"service",{"op":"take","index":at,"payment":"flask"}).ok and g.state.flask_mana==old_flask-row.price/2.0,"MEMBERSHIP discounted goods retain bottle payment: "+kind)
 var wrist=g.add_fixture("wrist",8)
 var release=t.find_action(g,"service",{"op":"release","target":wrist.id,"payment":"flask"})
 var quoted=g.Services.release_jobs(g).filter(func(job):return job.id==wrist.id)[0]
 var balance=g.state.flask_mana
 t.check(quoted.price==10 and quoted.price_detail.contains("折后10魔力") and release.mana==10 and g.dispatch(g.command(release.payload,g.state.version),g.state.version).ok and g.state.flask_mana==balance-10,"MEMBERSHIP release quote and real payment receive exactly one half discount")
 g.state.shop_removals=1
 var removal=t.find_action(g,"service",{"op":"remove","payment":"flask"})
 balance=g.state.flask_mana
 t.check(g.get_view().shop.remove_price==25 and removal.mana==25 and g.dispatch(g.command(removal.payload,g.state.version),g.state.version).ok and g.state.flask_mana==balance-25 and g.state.shop_removals==2,"MEMBERSHIP removal discount applies after its persistent base-price increase")
 t.check(g.state.logs.any(func(log):return log.data.get("shop_card_removal",{}).get("price",-1)==25),"MEMBERSHIP removal log records actual discounted payment")
 var restored=Game.new(42)
 t.check(restored.restore_snapshot(g.export_snapshot()).ok and restored.get_view().shop.stock==g.get_view().shop.stock,"MEMBERSHIP snapshot preserves discount without compounding saved prices")
 before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and g.validate()=="","MEMBERSHIP repeated previews preserve state and RNG")
 var entry=preload("res://data/encyclopedia.gd").entries().filter(func(e):return e.category=="relics" and e.id==TYPE)[0]
 t.check(entry.group=="商店限定" and entry.rarity=="rare" and entry.text.contains("五折"),"MEMBERSHIP encyclopedia states source, rarity and discount")
 var locale=preload("res://ui/localization.gd").new();locale.set_locale("en_US")
 t.check(locale.display("会员卡")=="Membership Card" and locale.display(quoted.price_detail)=="Base 20 mana; discounted: 10 mana","MEMBERSHIP English translates the actual complete release quote")
 var locked=g.add_fixture("wrist",8);locked.locked=true
 var combined=g.Services._job(g,locked.id,locked.name,[locked],true)
 t.check(combined.price==22.5 and locale.display(combined.price_detail)=="Base 20 mana + composite handling 15 + unlocking 10; discounted: 22.50 mana","MEMBERSHIP complete surcharge quote preserves fractional half-price in English")
 t.check(locale.display(g.Services.release_job_detail(g,{"job":quoted}))=="The shopkeeper removes the entire item and its attached fastenings with both hands. This costs no energy and advances no turn.\nBase 20 mana; discounted: 10 mana","MEMBERSHIP actual basic release UI detail translates description and discounted quote together")
 t.check(locale.display(g.Services.release_job_detail(g,{"job":combined}))=="The shopkeeper removes the entire item and all its components with both hands. Unlocking is included. This costs no energy and advances no turn.\nBase 20 mana + composite handling 15 + unlocking 10; discounted: 22.50 mana","MEMBERSHIP actual composite release UI detail translates the complete multiline message")
