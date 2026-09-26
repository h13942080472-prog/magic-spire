extends RefCounted
const Game=preload("res://core/game.gd")
const TYPE="universal_scanner"

static func shop():
 for seed in range(512):
  var g=Game.new(seed,true,"shop")
  if g.room_data(g.state.room).stock.any(func(row):return row.type==TYPE): return g
 return null

static func run(t) -> void:
 var g=shop()
 t.check(g!=null,"SCANNER naturally appears in shop stock")
 if g==null: return
 t.check(g.Relics.TYPES[TYPE].rarity=="uncommon" and TYPE in g.Relics.shop_pool() and TYPE not in g.Relics.REWARDS and TYPE not in g.Relics.BOSS_POOL,"SCANNER is an uncommon shop-exclusive relic")
 for source in ["normal","small","medium","large","rare"]:
  t.check(TYPE not in g.RelicRewards.available(g,source),"SCANNER excluded from other reward source: "+source)
 var rules=g.Cards.Rules
 var excluded=[];var allowed=[]
 for type in rules.SPECS:
  if not g.Character.allowed_card(g,type) or rules.SPECS[type].card_type!="power": continue
  g._gain_card(type)
  if rules.unique_face(type,false) and rules.unique_face(type,true): excluded.append(type)
  else: allowed.append(type)
 for i in range(2): g._gain_card("inch")
 var source=g.state.deck.filter(func(card):return card.type=="inch")[0].duplicate(true)
 var room=g.room_data(g.state.room)
 var index=room.stock.find(room.stock.filter(func(row):return row.type==TYPE)[0])
 g.state.mana=69;g.state.flask_mana=70;g.state.temporary_mana=100
 var before=g.export_snapshot()
 t.check(not t.action(g,"service",{"op":"take","index":index,"payment":"self"}).ok and g.state==before,"SCANNER insufficient payment cannot grant relic or open selection")
 var purchase=t.find_action(g,"service",{"op":"take","index":index,"payment":"flask"})
 t.check(purchase.mana==70 and not g.dispatch(g.command(purchase.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SCANNER stale purchase rolls back")
 var count=g.state.deck.size()
 t.check(g.dispatch(g.command(purchase.payload,g.state.version),g.state.version).ok and g.state.flask_mana==0 and g.state.deck.size()==count and g.state.relic_bundle.source==TYPE,"SCANNER purchase pays once and waits for card choice")
 t.check(g.command_facts().all(func(c):return c.payload.kind!="service"),"SCANNER pending selection blocks shop leave, removal and further purchases")
 var choices=g.command_facts().filter(func(c):return c.payload.kind=="relic_bundle" and c.payload.op=="copy")
 t.check(not excluded.is_empty() and choices.all(func(c):return c.payload.type not in excluded),"SCANNER excludes every double-unique power by existing reward eligibility")
 t.check(allowed.all(func(type):return choices.any(func(c):return c.payload.type==type)),"SCANNER permits single-unique and stackable powers")
 t.check(choices.all(func(c):return rules.SPECS[c.payload.type].rarity!="basic"),"SCANNER excludes basic cards from copy facts")
 t.check(choices.filter(func(c):return c.payload.type=="inch").size()==g.state.deck.filter(func(c):return c.type=="inch").size(),"SCANNER preserves individual choices for same-type non-basic physical cards")
 var pending=g.export_snapshot();var restored=Game.new(42)
 t.check(restored.restore_snapshot(pending).ok and restored.state.relic_bundle==g.state.relic_bundle and restored.state.deck==g.state.deck,"SCANNER pending selection survives snapshot restore")
 var restored_choice=t.find_action(restored,"relic_bundle",{"op":"copy","uid":source.uid})
 t.check(restored.dispatch(restored.command(restored_choice.payload,restored.state.version),restored.state.version).ok and restored.state.deck.size()==count+1 and restored.state.relic_bundle.is_empty(),"SCANNER restored pending selection can complete once")
 var restored_before=restored.export_snapshot()
 t.check(not restored.dispatch(restored.command(restored_choice.payload,restored.state.version),restored.state.version).ok and restored.state==restored_before,"SCANNER restored selection cannot be replayed")
 var invalid=pending.duplicate(true);invalid.relic_bundle.entries=[{}]
 t.check(not restored.restore_snapshot(invalid).ok and restored.state==restored_before,"SCANNER malformed pending records reject without changing state")
 before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"SCANNER preview does not copy cards or advance random state")
 var choice=t.find_action(g,"relic_bundle",{"op":"copy","uid":source.uid})
 t.check(not g.dispatch(g.command(choice.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SCANNER stale card choice cannot create a copy")
 t.check(g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and g.state.relic_bundle.is_empty() and g.state.deck.size()==count+1,"SCANNER selected card is copied exactly once and returns to shop")
 var copied=g.state.deck.back()
 t.check(copied.type==source.type and copied.uid!=source.uid and g.state.discard.any(func(c):return c.uid==copied.uid) and g.state.deck.any(func(c):return c==source),"SCANNER copy has a new UID in deck and discard and leaves original unchanged")
 t.check(g.state.mana==69 and g.state.flask_mana==0 and g.state.temporary_mana==100 and g.validate()=="","SCANNER selection costs no further resources and keeps valid state")
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and g.state==before,"SCANNER replayed consumed choice cannot duplicate again")
 g.RelicEffects.gain(g,TYPE)
 t.check(g.state==before,"SCANNER repeated relic gain cannot reopen selection")
 t.check(restored.restore_snapshot(g.export_snapshot()).ok and restored.state.deck==g.state.deck,"SCANNER completed copy survives restore without repeating")
 for only_unique in [false,true]:
  var empty=Game.new(42,true,"shop")
  for zone in ["deck"]+empty.Cards.ZONES: empty.state[zone]=[]
  if only_unique: empty._gain_card("endless_war_goddess")
  var empty_count=empty.state.deck.size()
  empty.RelicEffects.gain(empty,TYPE)
  t.check(empty.RelicBundle.copy_cards(empty).is_empty() and t.action(empty,"relic_bundle",{"op":"finish"}).ok and empty.state.relic_bundle.is_empty() and empty.state.deck.size()==empty_count,"SCANNER empty or all-ineligible deck can skip without granting a card")
 var store=preload("res://tests/persistence_cases.gd").store_for("scanner")
 t.check(store.write_game(g).ok,"SCANNER normal save uses the existing store entry")
 var saved=store.read_slot("practice")
 t.check(saved.ok and saved.snapshot==g.restart_snapshot() and TYPE not in saved.snapshot.relics and saved.snapshot.relic_bundle.is_empty(),"SCANNER normal continue returns to shop scene start, not the middle of a purchase")
 var book=preload("res://data/encyclopedia.gd").entries().filter(func(e):return e.category=="relics" and e.id==TYPE)[0]
 t.check(book.group=="商店限定" and book.rarity=="uncommon" and book.text.contains("双面唯一") and book.text.contains("基础牌"),"SCANNER catalog presents source rarity and both exclusions")
 var witch=Game.new(42,true,"shop",true,false,25,false,false,"witch")
 witch._gain_card("witch_escape_practice_10")
 witch.state.deck.back().practice_plays=12;witch.state.discard.back().practice_plays=12
 var training=witch.state.deck.back().duplicate(true)
 witch.RelicEffects.gain(witch,TYPE)
 before=witch.export_snapshot()
 t.check(not t.action(witch,"relic_bundle",{"op":"copy","uid":training.uid}).ok and witch.state==before,"SCANNER cannot copy basic training or mutate its permanent progress")
 t.check(witch.RelicBundle.copy_cards(witch).is_empty() and t.action(witch,"relic_bundle",{"op":"finish"}).ok,"SCANNER all-basic witch starter deck can skip")
 var witch_reward=Game.new(42,true,"shop",true,false,25,false,false,"witch")
 witch_reward._gain_card("witch_mana_transfer")
 source=witch_reward.state.deck.back().duplicate(true)
 witch_reward.RelicEffects.gain(witch_reward,TYPE)
 t.check(t.action(witch_reward,"relic_bundle",{"op":"copy","uid":source.uid}).ok and witch_reward.state.deck.back().type==source.type and witch_reward.state.deck.back().uid!=source.uid and witch_reward.validate()=="","SCANNER still copies non-basic character-exclusive cards")
 var growing=Game.new(42,true,"shop")
 growing._gain_card("concentration")
 var growing_uid=growing.state.deck.back().uid
 growing.state.discard.back().damage_bonus=int(growing.Cards.Rules.SPECS.concentration.damage_growth)
 growing.RelicEffects.gain(growing,TYPE)
 t.check(t.action(growing,"relic_bundle",{"op":"copy","uid":growing_uid}).ok and not growing.state.discard.back().has("damage_bonus") and not growing.state.deck.back().has("damage_bonus") and growing.validate()=="","SCANNER copy excludes live battle-only growth")
