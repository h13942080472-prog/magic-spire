extends RefCounted
const Game=preload("res://core/game.gd")
const Data=preload("res://data/departure.gd")

static func fixture(id: String):
 var g=Game.new(42);var rng=RandomNumberGenerator.new();rng.seed=123
 for i in range(Data.GROUPS.size()):
  if id in Data.GROUPS[i]: g.state.departure.options[i]=g.Departure.freeze(g,id,rng)
 return g

static func run(t) -> void:
 custom_start(t)
 var g=Game.new(42);var before=g.export_snapshot()
 t.check(g.state.deck.size()==10 and g.state.deck.filter(func(card):return card.type=="strain").size()==4 and g.state.deck.filter(func(card):return card.type=="slip").size()==4 and g.state.deck.filter(func(card):return card.type=="ease").size()==1 and g.state.deck.filter(func(card):return card.type=="magic_slip").size()==1 and g.state.deck.all(func(card):return g.Cards.Rules.SPECS[card.type].rarity=="basic"),"OPENING ten basic cards contain one magic slip instead of unlock")
 t.check(g.state.phase=="departure" and g.state.round==0 and not g.state.combat.active and g.state.departure.options.size()==5,"OPENING actual run starts at zero with five choices and no combat effects")
 t.check(g.get_view().reward_panel.entries.size()==6 and g.command_facts().all(func(c):return c.payload.kind=="departure" or (c.payload.kind=="flask" and c.payload.op=="withdraw")) and not g.room_entry_reason(g.room_data(g.room_data(g.state.room).next[0])).is_empty(),"OPENING choices and resource recovery do not let route bypass opening")
 for i in range(3): g.get_view();g.route_view();g.command_facts()
 t.check(g.export_snapshot()==before and Game.new(42).state.departure==g.state.departure,"OPENING previews and same seed preserve offers, hidden outcomes and resources")
 var restored=Game.new(99)
 t.check(restored.restore_snapshot(g.restart_snapshot()).ok and restored.state.departure==g.state.departure,"OPENING scene restart restores frozen opening")
 t.check(t.action(g,"departure",{"op":"skip"}).ok and g.state.phase=="map" and g.state.deck.size()==10 and g.state.relics==["ember"] and g.state.tick==0,"OPENING skip costs nothing and keeps starter deck/relic")
 var after=g.export_snapshot()
 t.check(not t.action(g,"departure",{"op":"skip"}).ok and g.export_snapshot()==after,"OPENING cannot claim again after leaving")
 var next=g.room_data(g.state.room).next[0]
 t.check(t.action(g,"depart",{"room":next}).ok and t.action(g,"travel_step").ok and g.state.phase=="battle","OPENING departure enters existing first-floor travel and battle")
 t.check(Game.new(42,true).state.departure.is_empty() and preload("res://tests/game_fixture.gd").new(42).state.phase=="battle","OPENING practice and existing battle fixture stay independent")
 for id in Data.OPTIONS:
  g=fixture(id);before=g.export_snapshot()
  var entry=g.state.departure.options.filter(func(e):return e.id==id)[0].duplicate(true)
  t.check(t.action(g,"departure",{"op":"choose","option":id}).ok,"OPENING commits category "+id)
  if id in Data.PICKERS:
   t.check(g.state.departure.stage=="card" and g.state.mana_max==before.mana_max and g.state.deck==before.deck and not g.command_facts().any(func(c):return c.payload.op in ["skip","finish"]),"OPENING bound selection has no skip and pays only with final card "+id)
   var pending=g.export_snapshot();var first=g.command_facts()[0]
   t.check(g.dispatch(g.command(first.payload,g.state.version),g.state.version).ok,"OPENING selected card commits "+id)
   t.check(not g.dispatch(g.command(first.payload,pending.version),pending.version).ok,"OPENING duplicate old card click rejects "+id)
   if id=="remove": t.check(g.state.deck.size()==9 and not g.state.draw.any(func(c):return c.uid==first.payload.uid),"OPENING removes exact physical card from deck and draw")
   if id=="transform": t.check(g.state.deck.size()==10 and g.state.deck[0].type==entry.changes[first.payload.uid] and g.state.draw[0].type==g.state.deck[0].type,"OPENING transforms selected basic card consistently across deck and draw")
   if id=="uncommon": t.check(g.state.deck.size()==11 and g.state.deck.back().type in g.Cards.Rules.UNCOMMON,"OPENING uncommon selected reward is permanent")
   if id=="rare_card": t.check(g.state.mana_max==90 and g.state.mana==90 and g.state.deck.back().type in g.Cards.Rules.RARE,"OPENING rare choice pays max mana and clamps current mana atomically")
  match id:
   "flask": t.check(g.state.flask_mana==40,"OPENING flask receives forty")
   "mana": t.check(g.state.mana_max==110 and g.state.mana==110,"OPENING max and current mana increase together")
   "potion": t.check(g.item_capacity()==4 and g.state.items.back().type==entry.potion,"OPENING permanent extra capacity and frozen potion")
   "rare_relic": t.check(g.state.mana==60 and g.state.combat.mana_spent==0,"OPENING loss uses own mana and is not spell spending")
   "curse": t.check(g.state.flask_mana==100 and g.state.deck.back().type==entry.curse,"OPENING curse and flask reward apply together")
   "basics": t.check(g.state.deck.size()==12 and g.state.deck[-2].type=="strain" and g.state.deck[-1].type=="slip","OPENING basic pair is the real starting pair")
   "wrist": t.check(g.state.equipment.size()==1 and g.state.equipment[0].grade==2 and g.tier(g.state.equipment[0].durability,g.state.equipment[0].maximum)==3 and not g.state.equipment[0].locked and g.state.equipment[0].slot=="wrist","OPENING medium tier-three wrist rope is actually installed unlocked")
   "boss": t.check("ember" not in g.state.relics and entry.relics[0] in g.state.relics,"OPENING fourth choice replaces starter with boss relic")
  t.check(entry.relics.all(func(relic):return relic in g.state.relics) and g.state.departure.stage=="done" and g.state.tick==before.tick and not g.state.combat.active,"OPENING reward has real effects without consuming a combat turn "+id)
  t.check(g.validate()=="" and restored.restore_snapshot(g.export_snapshot()).ok,"OPENING completed choice has a valid current snapshot "+id)
 g=fixture("rare_relic");g.state.mana=39;before=g.export_snapshot()
 t.check(not t.action(g,"departure",{"op":"choose","option":"rare_relic"}).ok and g.export_snapshot()==before,"OPENING insufficient own mana rejects without cost/reward")
 g=fixture("transform");t.action(g,"departure",{"op":"choose","option":"transform"});before=g.export_snapshot()
 t.check(not t.action(g,"departure",{"op":"card","uid":"missing","type":"strain"}).ok and g.export_snapshot()==before,"OPENING invalid target is atomic")
 var damaged=g.export_snapshot();damaged.departure.options[0].changes["bad"]="henshin"
 t.check(not restored.restore_snapshot(damaged).ok,"OPENING malformed transformation cannot restore")
 for boss in g.Relics.BOSS_POOL:
  g=fixture("boss");g.state.departure.options[3].relics=[boss]
  if boss not in g.state.relic_seen: g.state.relic_seen.append(boss)
  t.check(t.action(g,"departure",{"op":"choose","option":"boss"}).ok and "ember" not in g.state.relics and boss in g.state.relics,"OPENING all boss relics use formal pickup "+boss)
  match boss:
   "cursed_blindfold": t.check(g.state.equipment.any(func(e):return e.slot=="eyes" and e.grade==3 and e.locked),"OPENING boss blindfold applies its real permanent equipment cost")
   "shining_lamp": t.check(g.state.mana_max==50 and g.state.mana==50,"OPENING boss lamp pays full max-mana cost")
   "tattoo_sticker": t.check(g.state.deck.filter(func(c):return c.type=="lewd_mark").size()==2,"OPENING tattoo applies both curse cards")
   "nesting_doll":
    t.check(g.get_view().reward_panel.layout=="relic_bundle" and g.command_facts().all(func(c):return c.payload.kind=="relic_bundle" or (c.payload.kind=="flask" and c.payload.op=="withdraw")),"OPENING nesting doll preserves its three-relic selection while allowing resource recovery")
    t.action(g,"relic_bundle",{"op":"finish"})
    t.check(g.get_view().reward_panel.layout=="departure" and g.state.departure.stage=="done","OPENING nesting doll returns to completed opening")
  t.check(g.validate()=="" and restored.restore_snapshot(g.export_snapshot()).ok,"OPENING boss pickup and costs have valid snapshot "+boss)
 var found={};var signatures={}
 for seed in range(128 if t.exhaustive else 24):
  g=Game.new(seed)
  var ids=g.state.departure.options.map(func(e):return e.id)
  for id in ids: found[id]=true
  signatures[str(ids)]=true
  t.check(g.validate()=="" and ids[3]=="boss" and g.state.rare_offset==g.Cards.Rules.RARE_OFFSET_INITIAL,"OPENING generated options are valid with fixed boss swap and unchanged card rarity offset")
 t.check(found.size()==Data.OPTIONS.size() and signatures.size()>10,"OPENING seeded generation reaches all opening choices and varied category combinations")

static func custom_start(t) -> void:
 var g=Game.new(42,false,"equipment",true,true,25,true)
 t.check(g.state.relics==["cursed_plate_lock"] and g.max_energy()==4,"CUSTOM START replaces starter via real boss relic pickup")
 t.check(g.state.departure.options.size()==3 and g.state.departure.options.all(func(e):return e.id!="boss") and g.get_view().reward_panel.destination.contains("三选一"),"CUSTOM START keeps first three categories and truthful subtitle")
 t.check(g.state.special_equipment.filter(g.SpecialEquipment.is_cursed_plate).size()==1 and g.validate()=="","CUSTOM START pickup installs the real equipment and valid state")
 var before=g.export_snapshot();var restored=Game.new(99)
 var result=restored.restore_snapshot(g.restart_snapshot())
 var expected=before.duplicate(true);expected.version=restored.state.version
 t.check(result.ok and restored.state.version>before.version and restored.export_snapshot()==expected,"CUSTOM START scene restart restores exact choices and pickup without duplication, advancing version")
 t.check(not t.action(g,"departure",{"op":"choose","option":"boss"}).ok and g.export_snapshot()==before,"CUSTOM START removed boss choice cannot be submitted")
 var malformed=before.duplicate(true);malformed.departure.options.append(Game.new(42).state.departure.options[3])
 t.check(not restored.restore_snapshot(malformed).ok and restored.export_snapshot()==expected,"CUSTOM START snapshot rejects reintroduced fourth option atomically")
 t.check(t.action(g,"departure",{"op":"skip"}).ok and g.state.phase=="map" and g.state.relics==["cursed_plate_lock"],"CUSTOM START skipping optional reward keeps custom starter")
 t.check(restored.restore_snapshot(g.export_snapshot()).ok,"CUSTOM START map snapshot retains custom opening")
 var next=g.room_data(g.state.room).next[0]
 t.check(t.action(g,"depart",{"room":next}).ok and t.action(g,"travel_step").ok and g.state.energy==4,"CUSTOM START first battle receives relic energy bonus")
 for enabled in [false,true]:
  var regular=Game.new(42,false,"equipment",true,enabled,25,false)
  t.check(regular.state.relics==["ember"] and regular.state.departure.options.size()==5,"CUSTOM START unchecked retains default opening with pool "+str(enabled))
 var blocked=Game.new(42,false,"equipment",true,false,25,true)
 t.check(blocked.state.relics==["ember"] and blocked.state.departure.options.size()==5,"CUSTOM START core ignores custom flag without enabled pool")
 var practice=Game.new(42,true,"equipment",true,true,25,true)
 t.check("cursed_plate_lock" not in practice.state.relics and practice.state.departure.is_empty(),"CUSTOM START never overrides practice equipment or relics")
