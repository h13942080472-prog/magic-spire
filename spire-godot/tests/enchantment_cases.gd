extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")
const Enchant=preload("res://core/card_enchantments.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func game():
 var g=Game.new(42);g._discard_end();g.state.energy=30;g.state.relics=[]
 return g

static func give(g, type: String, id: String) -> Dictionary:
 var card=Cards.give(g,type)
 card.enchantment=id
 for original in g.state.deck:
  if original.uid==card.uid: original.enchantment=id
 return card

static func live(g, card: Dictionary) -> Dictionary:
 return g.Cards.instance(g,card.uid)

static func contains(g, zone: String, card: Dictionary) -> bool:
 return g.state[zone].any(func(c):return c.uid==card.uid)

static func play(t, g, card: Dictionary, free: bool=true, extra: Dictionary={}) -> Dictionary:
 var p={"uid":card.uid,"free":free};p.merge(extra,true)
 return t.action(g,"card",p)

static func rest():
 var g=game();g.state.room="rest";g._start_rest()
 return g

static func run(t) -> void:
 eligibility(t)
 service(t)
 effects(t)
 circulation(t)
 casting_damage_replay(t)
 boundaries(t)
 validation(t)
 prison_lifetime(t)
 practice_entry(t)

static func practice_entry(t) -> void:
 var g=preload("res://core/game.gd").new(42,true,"rest")
 t.check(g.state.practice and g.state.phase=="rest_choice" and g.state.rest_left==6 and g.state.combat.turn==0 and g.state.hand.is_empty(),"CAMPFIRE practice starts before the first rest turn")
 var before=g.export_snapshot()
 t.check(not g.dispatch(g.command({"kind":"end"},g.state.version),g.state.version).ok and g.state==before,"CAMPFIRE choice phase rejects end-turn without starting or paying for a turn")
 t.check(g.validate()=="" and g.restart_snapshot()==g.state and g.room_data(g.state.room).enchantments.offers.size()==3,"CAMPFIRE practice freezes real offers in a valid entry checkpoint")
 var saved=Save.roundtrip(t,g,"campfire practice entry")
 if saved!=null: t.check(saved.state.practice and saved.state.phase=="rest_choice","CAMPFIRE practice entry remains a chooser after loading")
 t.check(t.action(g,"rest_begin").ok and g.state.phase=="rest" and g.state.rest_left==6,"CAMPFIRE practice skip starts six real turns")
 t.check(t.action(g,"finish_rest").ok and g.state.phase=="cleared" and g.state.reward_count==0,"CAMPFIRE practice ends without tower progress or combat rewards")
 var equipment=preload("res://core/game.gd").new(42,true,"equipment")
 t.check(equipment.state.phase=="rest" and equipment.state.rest_left==6 and not equipment.state.hand.is_empty(),"CAMPFIRE equipment practice still starts its playable turn immediately")

static func eligibility(t) -> void:
 var g=game()
 for type in ["panic","tease","tease_plus"]:
  if not g.Cards.Rules.SPECS.has(type): continue
  for id in Enchant.Data.TYPES: t.check(not Enchant.eligible(g,{"type":type},id),"ENCHANT curse/status ineligible: "+type+"/"+id)
 for id in ["recycle","recycle2"]:
  t.check(not Enchant.eligible(g,{"type":"pot_of_greed"},id) and not Enchant.eligible(g,{"type":"confluence"},id) and not Enchant.eligible(g,{"type":"adaptability"},id),"ENCHANT recycle excludes native exhaust on either face and powers")
 t.check(Enchant.eligible(g,{"type":"strain"},"powerful") and not Enchant.eligible(g,{"type":"unlock"},"powerful"),"ENCHANT powerful only actual escape damage")
 t.check(Enchant.eligible(g,{"type":"ease"},"adept") and not Enchant.eligible(g,{"type":"strain"},"adept"),"ENCHANT adept only magic")
 t.check(Enchant.eligible(g,{"type":"adaptability"},"sow_power") and not Enchant.eligible(g,{"type":"strain"},"sow_power"),"ENCHANT common sow only powers")
 t.check(not Enchant.eligible(g,{"type":"strain"},"sow_skill") and Enchant.eligible(g,{"type":"strain"},"innate"),"ENCHANT basic eligible but one energy skill not rare sow")
 t.check(not Enchant.eligible(g,{"type":"fire_mastery"},"replay") and Enchant.eligible(g,{"type":"adaptability"},"replay"),"ENCHANT replay excludes two unique faces")
 t.check(not Enchant.face_eligible(g,"mana_conversion","fickle",false) and Enchant.face_eligible(g,"mana_conversion","fickle",true),"ENCHANT eligibility uses original face cost")
 t.check(not Enchant.eligible(g,{"type":"strain","enchantment":"retain"},"retain") and Enchant.eligible(g,{"type":"strain","enchantment":"retain"},"innate"),"ENCHANT replacement excludes same slot value only")
 for count in range(10): t.check(Enchant.Data.refresh_price(count)==[10,10,10,20,20,20,40,40,40,80][count],"ENCHANT refresh tier boundary "+str(count))

static func service(t) -> void:
 var g=rest();var offers=g.room_data("rest").enchantments.offers
 t.check(offers.size()==3 and offers.all(func(id):return offers.count(id)==1) and offers.filter(func(id):return Enchant.Data.TYPES[id].rarity=="common").size()==2,"ENCHANT frozen two common one rare unique offers")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"ENCHANT opening and projection never spend or reroll")
 var twin=Save.roundtrip(t,g,"enchantment offers")
 if twin!=null: t.check(twin.room_data("rest").enchantments==g.room_data("rest").enchantments,"ENCHANT save preserves offers")
 g.state.mana=9;g.state.temporary_mana=100;g.state.flask_mana=9;before=g.export_snapshot()
 for payment in ["self","flask"]: t.check(not t.action(g,"enchant",{"op":"refresh","payment":payment}).ok and g.state==before,"ENCHANT refresh cannot use temporary or combine balances")
 g.state.mana=70;g.state.flask_mana=100
 for i in range(4):
  var amount=g.state.mana;var fact=t.find_action(g,"enchant",{"op":"refresh","payment":"self"})
  before=g.export_snapshot()
  t.check(not g.dispatch(g.command(fact.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"ENCHANT stale refresh leaves payment and offers")
  t.check(t.action(g,"enchant",{"op":"refresh","payment":"self"}).ok and g.state.mana==amount-(10 if i<3 else 20) and g.state.temporary_mana==100 and g.state.rest_left==6,"ENCHANT refresh charges tier and no rest turns")
 t.check(t.action(g,"enchant",{"op":"refresh","payment":"flask"}).ok and g.state.flask_mana==80,"ENCHANT flask payment uses same tier")
 var service_data=g.room_data("rest").enchantments
 service_data.offers=["retain","nimble","exhaust"]
 var chosen=t.find_action(g,"enchant",{"op":"apply","enchantment":"retain"});var uid=chosen.payload.uid
 t.check(t.action(g,"rest_flask").ok and g.state.phase=="rest_choice" and g.state.rest_left==3,"ENCHANT ordinary service leaves enchantment available")
 t.check(t.action(g,"enchant",{"op":"apply","enchantment":"retain","uid":uid}).ok and g.state.rest_left==1 and g.room_data("rest").enchantments.used,"ENCHANT common spends two turns once")
 t.check(g.state.deck.filter(func(c):return c.uid==uid)[0].enchantment=="retain" and g.Cards.instance(g,uid).enchantment=="retain","ENCHANT permanent and live card share slot")
 t.check(not t.find_action(g,"enchant",{"op":"apply"}).valid and not t.find_action(g,"enchant",{"op":"refresh"}).valid,"ENCHANT successful fire cannot repeat or refresh")
 t.check(t.action(g,"rest_begin").ok and g.state.phase=="rest" and g.state.rest_left==1,"ENCHANT one remaining real turn starts normally")
 t.check(t.action(g,"end").ok and g.state.phase=="map","ENCHANT rest ends after remaining budget")
 g=rest();g.room_data("rest").enchantments.offers=["exhaust","retain","nimble"]
 t.check(t.action(g,"enchant",{"op":"apply","enchantment":"exhaust"}).ok and g.state.rest_left==2 and not t.find_action(g,"rest_flask").valid,"ENCHANT rare spends four and blocks unaffordable ordinary service")
 # A later fire replaces the slot on the same physical card.
 var enchanted=g.state.deck.filter(func(c):return c.has("enchantment"))[0]
 g.room_data("rest").erase("enchantments");g._start_rest();g.room_data("rest").enchantments.offers=["retain"]
 t.check(t.action(g,"enchant",{"op":"apply","enchantment":"retain","uid":enchanted.uid}).ok and live(g,enchanted).enchantment=="retain","ENCHANT later fire replaces previous enchantment")
 var meta=g.Cards.metadata(g,enchanted.type,enchanted.uid)
 t.check(meta.face_keywords.bound.any(func(term):return term.get("id","")=="enchantment_retain") and not meta.face_keywords.bound.any(func(term):return term.get("id","")=="enchantment_exhaust"),"ENCHANT replacement removes former keyword")
 # Restrict the deck to a native innate/retain spell to exercise rarity fallback.
 g=rest()
 for zone in ["deck"]+g.Cards.ZONES: g.state[zone]=[]
 var card=give(g,"wildfire_descent","innate");g.state.hand.clear();g.state.discard=[card]
 Enchant.roll(g)
 t.check(g.room_data("rest").enchantments.offers.all(func(id):return Enchant.eligible(g,card,id)),"ENCHANT generated offers all have a real eligible physical card")

static func effects(t) -> void:
 var g=game();var card=give(g,"strain","nimble");var before=g.state.hand.size()
 t.check(play(t,g,card).ok and g.state.hand.size()==before,"ENCHANT nimble draws once after original effect")
 g=game();card=give(g,"strain","fickle");g.state.mana=40
 t.check(play(t,g,card).ok and g.state.mana==45,"ENCHANT fickle free restores five own mana")
 g=game();card=give(g,"strain","fickle");var target=g.add_fixture("ankle",100,100)
 t.check(play(t,g,card,false,{"target":target.id}).ok and g.state.charge==1,"ENCHANT fickle bound grants charge after damage")
 g=game();card=give(g,"mana_conversion","fickle");g.state.charge=0
 t.check(play(t,g,card,false).ok and g.state.charge==0,"ENCHANT zero cost side gains no fickle charge")
 for id in ["sow_power","blessing"]:
  g=game();card=give(g,"adaptability",id);var energy=g.state.energy
  t.check(play(t,g,card,false).ok,"ENCHANT ability activation "+id)
  if id=="sow_power": t.check(g.state.energy==energy,"ENCHANT sow refunds one after power")
  else:
   t.check(g.Cards.power_attribute_modifier(g,"strength")==2 and g.Cards.power_attribute_modifier(g,"dexterity")==2,"ENCHANT blessing grants persistent attributes")
   t.check(t.action(g,"end").ok and g.Cards.power_attribute_modifier(g,"strength")==2,"ENCHANT blessing persists across turn")
   g.Cards.end_powers(g);t.check(g.Cards.power_attribute_modifier(g,"strength")==0,"ENCHANT blessing ends with session")
 g=game();card=give(g,"strain","strengthen")
 t.check(play(t,g,card).ok and g.Cards.power_attribute_modifier(g,"strength")==1 and g.Cards.power_attribute_modifier(g,"dexterity")==1,"ENCHANT strengthen grants both temporary attributes")
 t.check(t.action(g,"end").ok and g.Cards.power_attribute_modifier(g,"strength")==0,"ENCHANT strengthen ends with turn")
 for id in ["absorb","swift"]:
  g=game();card=give(g,"strain",id);g.state.mana=10
  t.check(play(t,g,card).ok and live(g,card).enchant_used==1,"ENCHANT first successful use "+id)
  t.check(g.state.mana==30 if id=="absorb" else g.state.hand.size()==3,"ENCHANT first use grants benefit "+id)
  var mana=g.state.mana;var size=g.state.hand.size();card=live(g,card);g.state.discard.erase(card);g.state.hand.append(card)
  t.check(play(t,g,card).ok and g.state.mana==mana and g.state.hand.size()==size,"ENCHANT same session does not repeat once benefit "+id)

static func circulation(t) -> void:
 var g=game();var card=give(g,"strain","retain")
 t.check(t.action(g,"end").ok and g.state.hand.any(func(c):return c.uid==card.uid),"ENCHANT retain survives end discard")
 g=game();card=give(g,"strain","innate");g._reset_piles();g.Cards.Hannya.prepare_innate(g);g._draw(1)
 t.check(g.state.hand.any(func(c):return c.uid==card.uid),"ENCHANT innate participates in opening draw")
 for id in ["recycle","recycle2"]:
  g=game();card=give(g,"strain",id)
  for i in range(1,4):
   if not contains(g,"hand",card): break
   t.check(play(t,g,card).ok,"ENCHANT recycle real use "+str(i))
   t.check(contains(g,"hand",card)==(i<=(2 if id=="recycle2" else 1)),"ENCHANT recycle shared allowance "+id+str(i))
  t.check(Enchant.text(g,live(g,card)).is_empty(),"ENCHANT depleted recycle keyword removed")
 g=game();card=give(g,"pot_of_greed","exhaust")
 t.check(play(t,g,card,false).ok and contains(g,"discard",card) and Enchant.text(g,live(g,card)).name=="消耗","ENCHANT native exhaust first use discards and shows one remaining")
 card=live(g,card);g.state.discard.erase(card);g.state.hand.append(card)
 t.check(play(t,g,card,true).ok and contains(g,"exhaust",card),"ENCHANT opposite face shares second exhaust use")
 g._reset_piles();g.RelicEffects.begin_combat(g)
 t.check(not g.Cards.instance(g,card.uid).has("enchant_used") and Enchant.text(g,g.Cards.instance(g,card.uid)).name=="消耗2","ENCHANT new session resets shared counter")
 g=game();card=give(g,"strain","exhaust")
 t.check(play(t,g,card).ok and contains(g,"exhaust",card),"ENCHANT new exhaust consumes ordinary card on first use")
 g=game();card=give(g,"strain","nexus");g.state.hand.erase(card);g.state.draw.push_back(card)
 var energy=g.state.energy;g._draw(1)
 t.check(g.state.energy==energy+1,"ENCHANT actual draw triggers nexus")
 g.state.hand.erase(card);g._put_card_in_hand(card)
 t.check(g.state.energy==energy+1,"ENCHANT direct return does not trigger nexus")
 g=game();card=give(g,"strain","recycle2");play(t,g,card)
 g._gain_card("strain",live(g,card),true)
 var copies=g.state.hand.filter(func(c):return c.uid!=card.uid and c.get("enchantment","")=="recycle2")
 t.check(copies.size()==1 and copies[0].enchant_used==1,"ENCHANT copies inherit slot and spent allowance")

static func casting_damage_replay(t) -> void:
 var g=game();var card=give(g,"mana_conversion","adept");g.state.pressure=99
 t.check(t.find_action(g,"card",{"uid":card.uid,"free":false}).valid and g.Cards.metadata(g,card.type,card.uid).face_casting.bound.chance==1.0,"ENCHANT adept chance shown and executable near limit")
 t.check(play(t,g,card,false).ok and not g._magic_failed,"ENCHANT adept succeeds")
 g=game();card=give(g,"ease","adept");g.add_fixture("hand",30,30)
 t.check(not t.find_action(g,"card",{"uid":card.uid,"free":false}).valid,"ENCHANT adept does not bypass required body use")
 g=game();card=give(g,"strain","powerful");var target=g.add_fixture("ankle",100,100)
 var strong=t.find_action(g,"card",{"uid":card.uid,"free":false,"target":target.id});var plain=Cards.give(g,"strain")
 var normal=t.find_action(g,"card",{"uid":plain.uid,"free":false,"target":target.id})
 t.check(is_equal_approx(strong.payload.preview.damage,normal.payload.preview.damage*1.5),"ENCHANT powerful multiplies final escape damage")
 var before=target.durability
 t.check(play(t,g,card,false,{"target":target.id}).ok and is_equal_approx(g._equipment(target.id).durability,before-strong.payload.preview.damage),"ENCHANT powerful preview equals executed damage")
 g=game();card=give(g,"mana_conversion","replay");g.state.mana=20
 t.check(play(t,g,card,true).ok and g.state.mana==40 and live(g,card).enchant_used==1,"ENCHANT free face replays same face once with one physical use")
 g=game();card=give(g,"fire_control","replay");g.Cards.grant_buff(g,"echo_cast_bound")
 t.check(play(t,g,card,false).ok and g.state.temporary_mana==30,"ENCHANT replay adds to original replay buff")
 g=game();card=give(g,"double_unlock","replay");var a=g.add_fixture("ankle",30,30,true);var b=g.add_fixture("ankle",30,30,true)
 t.check(play(t,g,card,false,{"target":a.id}).ok and not g.state.card_chain.is_empty(),"ENCHANT replay holds physical card through continuation")
 var twin=Save.roundtrip(t,g,"enchantment replay continuation")
 if twin!=null: Save.step_both(t,g,twin,"chain",{"target":b.id})
 t.check(g.state.card_chain.is_empty() and live(g,card).enchant_used==1,"ENCHANT continuation settles affix once")
 g=game();g.state.pressure=50;card=give(g,"forced_climax","replay")
 var result=play(t,g,card,false)
 t.check(result.ok,"ENCHANT selected-exhaust begins")
 for i in range(3): t.check(t.action(g,"chain",{"action":"select_exhaust"}).ok,"ENCHANT selected-exhaust continuation")
 t.check(g.state.play.is_empty() and g.state.exhaust.size()==4 and live(g,card).enchant_used==1,"ENCHANT already exhausted replay targets are skipped without second selection")

static func validation(t) -> void:
 var g=rest();var before=g.export_snapshot()
 for value in ["not_registered",9]:
  var bad=before.duplicate(true);bad.deck[0].enchantment=value
  t.check(not g.restore_snapshot(bad).ok and g.state==before,"ENCHANT corrupt slot rejected atomically")
 var bad=before.duplicate(true);bad.rooms.filter(func(room):return room.id=="rest")[0].enchantments.offers=["retain","retain"]
 t.check(not g.restore_snapshot(bad).ok and g.state==before,"ENCHANT duplicate offers rejected atomically")
 bad=before.duplicate(true);bad.rooms.filter(func(room):return room.id=="rest")[0].erase("enchantments")
 t.check(g.restore_snapshot(bad).ok and g.room_data("rest").has("enchantments"),"ENCHANT older resting save backfills offers without touching caller")
 g=game();var card=give(g,"strain","swift");play(t,g,card);before=g.export_snapshot()
 bad=before.duplicate(true);bad.discard.filter(func(c):return c.uid==card.uid)[0].enchant_used=-1
 t.check(not g.restore_snapshot(bad).ok and g.state==before,"ENCHANT negative spent allowance rejected atomically")

static func boundaries(t) -> void:
 var g=game();var card=give(g,"peel","sow_skill")
 t.check(Enchant.eligible(g,{"type":"peel"},"sow_skill") and play(t,g,card,true).ok and g.state.energy==29,"ENCHANT rare sow applies to original two-energy skill")
 g=game();card=give(g,"mana_conversion","absorb");g.state.pressure=99;g.state.mana=40
 t.check(play(t,g,card,false).ok and g._magic_failed and not live(g,card).has("enchant_used") and g.state.mana==30,"ENCHANT failed cast cannot trigger or consume once effect")
 g=game();card=give(g,"mana_search","recycle")
 for i in range(9): Cards.give(g,"strain")
 for i in range(2):
  g._gain_card("ease");g.state.draw.append(g.state.discard.pop_back())
 t.check(play(t,g,card,true).ok and g.state.hand.size()==10 and contains(g,"discard",card),"ENCHANT recycle into full hand discards instead without losing the card")
 g=game();card=give(g,"mana_conversion","nexus");g.state.hand.erase(card);g.state.draw.push_back(card)
 var energy=g.state.energy
 t.check(Cards.play(t,g,"mana_search",true).ok and g.state.energy==energy and contains(g,"hand",card),"ENCHANT filtered draw triggers nexus after paying search")
 g=game();card=give(g,"strain","swift");play(t,g,card);g._finish_battle()
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare" and live(g,card).enchant_used==1,"ENCHANT battle to preparation preserves once allowance")
 t.check(t.action(g,"finish_prepare").ok and not live(g,card).has("enchant_used"),"ENCHANT preparation end resets runtime allowance")
 g=rest();var old=g.export_snapshot();var facts=g.command_facts().filter(func(f):return f.payload.kind=="enchant" and f.payload.op=="apply")
 var forged=facts[0].payload.duplicate(true);forged.enchantment="bogus"
 t.check(not g.dispatch(g.command(forged,g.state.version),g.state.version).ok and g.state==old,"ENCHANT forged affix cannot bypass offered membership")
 g=game();card=give(g,"concentration","powerful");g.state.wall="rough"
 var F=preload("res://tests/follow_through_cases.gd")
 var primary=F.piece(g,"thigh","thigh_root",80,100);var peer=F.piece(g,"thigh","thigh_root",80,100)
 var fact=t.find_action(g,"card",{"uid":card.uid,"target":primary.id,"free":false})
 var Splash=preload("res://core/card_splash.gd")
 var splashes=Splash.select(g,fact.payload)
 t.check(not splashes.is_empty(),"ENCHANT powerful fixture has a splash recipient")
 if not splashes.is_empty():
  t.check(play(t,g,card,false,{"target":primary.id}).ok and is_equal_approx(g._equipment(peer.id).durability,80-splashes[0].preview.damage),"ENCHANT powerful splash uses the same final multiplier once")
 g=game()
 for i in range(7): give(g,"strain","innate")
 g._start_battle()
 t.check(g.state.hand.size()==g.B.DRAW and g.state.hand.all(func(c):return c.get("enchantment","")=="innate"),"ENCHANT seven innate enchantments occupy normal opening slots without expanding draw")
 for x in [0,1,2]:
  t.check(Enchant.face_eligible(g,"self_binding","fickle",false,x)==(x>0) and Enchant.face_eligible(g,"self_binding","sow_skill",false,x)==(x>=2),"ENCHANT X cost eligibility boundary "+str(x))
 g=game();g.state.energy=2;card=give(g,"self_binding","sow_skill")
 for slot in ["ankle","foot"]: g.add_fixture(slot,4)
 var x_result=play(t,g,card,false)
 t.check(x_result.ok and g.state.energy==1,"ENCHANT X two spends actual energy then triggers rare sow: "+str(x_result)+" energy="+str(g.state.energy))

static func prison_lifetime(t) -> void:
 var Prison=preload("res://tests/prison_cases.gd")
 var g=Prison.intake(t,2);Prison.clear_fixture(g)
 Prison.exit_to_route(t,g);Prison.travel_route(t,g,"prison_rest")
 g.room_data("prison_rest").enchantments.offers=["retain"]
 t.check(t.action(g,"enchant",{"op":"apply","enchantment":"retain"}).ok and t.action(g,"rest_flask").ok,"ENCHANT prison fire supports both services")
 t.action(g,"rest_begin");t.action(g,"finish_rest");Prison.travel_route(t,g,"prison_gate")
 Save.roundtrip(t,g,"enchanted prison route")
 var before=g.export_snapshot();var bad=before.duplicate(true)
 bad.rooms.filter(func(r):return r.id=="prison_rest")[0].enchantments.used="bad"
 t.check(not g.restore_snapshot(bad).ok and g.state==before,"ENCHANT route comparison cannot bypass malformed service progress")
 g=Prison.intake(t);Prison.clear_fixture(g);g._discard_end()
 var card=give(g,"pot_of_greed","exhaust")
 t.check(play(t,g,card,false).ok and live(g,card).enchant_used==1,"ENCHANT prison play consumes shared first exhaust use")
 Prison.inspect(t,g)
 for op in ["inspect","accept","resume"]: t.check(t.action(g,"prison",{"action":op}).ok,"ENCHANT inspection step "+op)
 t.check(g.state.phase=="prison" and live(g,card).enchant_used==1,"ENCHANT inspection resume preserves the same session allowance")
 Save.roundtrip(t,g,"enchantment after inspection")
