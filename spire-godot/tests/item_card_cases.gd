extends RefCounted

const Game=preload("res://tests/game_fixture.gd")
const TowerGame=preload("res://core/game.gd")
const ItemCards=preload("res://core/item_cards.gd")
const Queries=preload("res://ui/target_queries.gd")

static func run(t) -> void:
 pocket_knife(t)
 var g=Game.new(42)
 var book_rules=ItemCards.conditions(g.Tools.TYPES.saw,true)
 t.check(book_rules.size()==4 and "目标外露" in book_rules and book_rules.all(func(line):return line.length()<16),"ITEM CARD catalog lists three distinct posture ranges and exposure")
 for type in g.Tools.TYPES:
  var spec=g.Cards.Rules.SPECS[type]
  t.check(spec.card_type=="item" and "remove" in g.B.keyword_ids(type,false) and not g.can_offer_card(type),"ITEM CARD classification, keyword and reward exclusion: "+type)
 g.state.mana=40
 g._gain_tool("mana_potion")
 t.check(t.action(g,"item_use",{"item":g.state.items.back().id}).ok and g.state.mana==40,"ITEM CARD inventory conversion does not apply effect")
 var shop_detail=g.Services.offer_detail(g,{"offer":{"kind":"tool","type":"shard"}})
 t.check(shop_detail.contains("借墙1费") and not shop_detail.contains("安装"),"ITEM CARD shop uses current cutting rules")
 var card=g.state.hand.back()
 t.check(card.type=="mana_potion" and card.remove_left==1,"ITEM CARD converted copy in hand")
 var uid=card.uid
 t.check(t.action(g,"card",{"uid":uid}).ok and g.state.mana==60,"ITEM CARD self potion uses card play")
 t.check(not g.state.deck.any(func(c):return c.uid==uid) and g.Cards.instance(g,uid).is_empty(),"ITEM CARD last use leaves all zones")
 g._gain_tool("shard")
 t.check(t.action(g,"item_use",{"item":g.state.items.back().id}).ok,"ITEM CARD draw knife")
 var knife=g.state.hand.back()
 g.add_fixture("thigh",8)
 var target=g.state.equipment.back().id
 var view=g.get_view()
 var body=Queries.body_at(view,"thigh")
 var drag={"card_uid":knife.uid,"free":true,"version":view.version}
 var choice=Queries.release_candidate(view,body,target,drag,view.version)
 t.check(not choice.is_empty() and choice.valid and choice.cost==1,"ITEM CARD knife is a standard equipment drag target")
 var energy=g.state.energy
 t.check(t.action(g,"card",{"uid":knife.uid,"target":target,"free":true}).ok and g.state.energy==energy-1,"ITEM CARD wall side cost")
 var left=g.state.deck.filter(func(c):return c.uid==knife.uid)
 t.check(left.size()==1 and left[0].remove_left==2 and g.Cards.instance(g,knife.uid).remove_left==2,"ITEM CARD zones share permanent use count")
 var restored=Game.new(9)
 t.check(restored.restore_snapshot(g.export_snapshot()).ok and restored.Cards.instance(restored,knife.uid).remove_left==2,"ITEM CARD save roundtrip")
 var corrupt=g.export_snapshot()
 for c in corrupt.discard:
  if c.uid==knife.uid: c.remove_left=1
 t.check(not restored.restore_snapshot(corrupt).ok,"ITEM CARD mismatched remaining uses rejected")
 var tower=TowerGame.new(112)
 t.check("return_seal" in tower.state.relics and tower.RelicEffects.counter(tower,"return_seal").value==1 and tower.state.items.is_empty(),"SEAL initial extra charged relic")
 tower.state.mana=1
 tower._gain_tool("mana_potion")
 t.check(t.action(tower,"item_use",{"item":tower.state.items.back().id}).ok and t.action(tower,"card",{"type":"mana_potion"}).ok and tower.state.mana==21,"ITEM CARD mana potion usable outside battle")
 var old=tower.export_snapshot()
 old.save_revision=55
 old.relics.erase("return_seal");old.relic_counters.erase("return_seal")
 t.check(tower.restore_snapshot(old).ok and tower.state.relic_counters.return_seal==0,"SEAL spent legacy scroll stays spent")
 var cell=preload("res://tests/prison_cases.gd").intake(t)
 preload("res://tests/prison_cases.gd").clear_fixture(cell)
 t.check(t.action(cell,"relic_discharge",{"relic":"return_seal"}).ok and cell.state.phase=="map" and cell.state.relic_counters.return_seal==0,"SEAL right-click command consumes a charge and leaves prison")
 g.state.relic_counters.return_seal=0
 g.room_data(g.state.room).boss=true
 g.state.room_encounters[g.state.room]="iron_man_solo"
 g.state.enemies=[{"type":"iron_man","defeated":false,"gone":true},{"type":"binding_box","defeated":true,"gone":true}]
 g.RelicEffects.boss_key(g,false)
 t.check(g.state.relic_counters.return_seal==0,"SEAL killing an add does not refill")
 g.state.enemies[0].defeated=true
 g.RelicEffects.boss_key(g,false);g.RelicEffects.boss_key(g,false)
 t.check(g.RelicEffects.counter(g,"return_seal").value==1,"SEAL Boss refill caps at one")
 g=Game.new(42)
 g.state.mana=g.state.mana_max
 g._gain_tool("mana_potion")
 t.check(t.action(g,"item_use",{"item":g.state.items.back().id}).ok and not t.find_action(g,"card",{"type":"mana_potion"}).valid,"ITEM CARD full mana allows conversion and blocks card play")
 var data=g.get_view().hand.back()
 t.check("魔力低于上限" in data.face_requirements.bound and "口部受限时药效减半" in data.face_requirements.bound and data.face_effects.bound.contains("移除。"),"ITEM CARD face presents use conditions and permanent removal")
 var potion_uid=data.uid
 var blocked=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":potion_uid}).ok and g.state==blocked,"ITEM CARD rejected play preserves the physical card")
 g.state.mana-=20
 t.check(t.action(g,"card",{"uid":potion_uid}).ok and g.state.mana==g.state.mana_max,"ITEM CARD same copy becomes playable once its mana condition is met")
 tower=TowerGame.new(112)
 tower._gain_tool("saw")
 t.check(t.action(tower,"item_use",{"item":tower.state.items.back().id}).ok and tower.state.hand.back().type=="saw","ITEM CARD knife enters hand without a target outside combat")
 var full=g.state.hand.size()
 for i in range(g.B.HAND_LIMIT-full): g._gain_card("strain",{},true)
 g._gain_tool("picks")
 var original=g.export_snapshot()
 t.check(not t.action(g,"item_use",{"item":g.state.items.back().id}).ok and g.state==original,"ITEM CARD full hand preserves inventory and deck")

 var enchants=preload("res://tests/enchantment_cases.gd")
 g=enchants.game()
 var repeated=enchants.give(g,"saw","replay")
 var rope=g.add_fixture("thigh",20,20)
 t.check(enchants.play(t,g,repeated,false,{"target":rope.id}).ok and g._equipment(rope.id).durability==6 and g.Cards.instance(g,repeated.uid).remove_left==1,"ITEM CARD replays both cuts but spends one physical use")

static func pocket_knife(t) -> void:
 for role in ["original","witch"]:
  var g=Game.new(42,false,"equipment",true,false,25,false,false,role)
  g.state.relics=["pocket_knife"]
  g._start_battle()
  var knives=g.state.hand.filter(func(card):return card.type=="pocket_knife")
  t.check(knives.size()==1 and not g.can_offer_card("pocket_knife"),"KNIFE one generated opening item for "+role)
  if knives.size()!=1: continue
  var uid=knives[0].uid
  t.check(t.action(g,"end").ok and not g._card(uid).is_empty() and g.state.deck.filter(func(c):return c.type=="pocket_knife").size()==1,"KNIFE retained across turns without another grant")
  g.state.equipment.clear()
  var palm=g.add_fixture("palm",10)
  var enemy=g.state.enemies[0]
  var fields={"uid":uid,"target":enemy.id,"free":false}
  var hp=enemy.hp
  var stale=t.find_action(g,"card",fields)
  t.check(g.restraint_degree("arms")==1 and stale.get("valid",false) and not t.find_action(g,"card",{"uid":uid,"target":palm.id}).valid,"KNIFE at upper degree one only enemies are offered")
  if not stale.valid: continue
  if role=="original":
   var play=t.action(g,"card",fields)
   t.check(play.ok and is_equal_approx(hp-g._enemy(enemy.id).hp,8) and g.state.exhaust.any(func(c):return c.uid==uid),"KNIFE deals eight to enemy and exhausts")
  else:
   g.state.equipment.clear()
   g.add_fixture("wrist",10)
   var leg=g.add_fixture("thigh",16,16)
   var version=g.state.version
   t.check(g.restraint_degree("arms")==2 and not t.find_action(g,"card",fields).valid and not g.dispatch(g.command(stale.payload,version),version).ok and not g._card(uid).is_empty(),"KNIFE obsolete enemy target cannot spend card")
   var energy=g.state.energy
   var cut=t.action(g,"card",{"uid":uid,"target":leg.id,"free":true})
   t.check(cut.ok and g._equipment(leg.id).get("durability",-1)==8 and g.state.energy==energy-1 and g.state.exhaust.any(func(c):return c.uid==uid),"KNIFE wall cut deals eight and pays standard tool cost")
  if role=="original":
   for remaining in g.state.enemies:
    if remaining.id!=enemy.id: remaining.gone=true
   g._enemy(enemy.id).hp=8
   g._gain_card("pocket_knife",{},true)
   t.check(t.action(g,"card",{"uid":g.state.hand.back().uid,"target":enemy.id}).ok and g.state.phase=="reward","KNIFE killing the last enemy settles combat")
  else: g._finish_battle()
  t.check(t.action(g,"reward",{"type":"skip"}).ok,"KNIFE enters preparation")
  t.check(t.action(g,"finish_prepare").ok,"KNIFE finishes the session through the normal transition")
  t.check(not g.state.deck.any(func(c):return c.uid==uid) and g.Cards.instance(g,uid).is_empty(),"KNIFE session cleanup removes spent copy")
