extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func encounter(seed_value: int=42):
 var g=Game.new(seed_value,false,"equipment",true)
 g.state.room_encounters.entrance="rope_master_solo"
 g._start_battle()
 return g

static func turn(t,g) -> void:
 var result=g.dispatch(g.command({"kind":"end"},g.state.version),g.state.version)
 t.check(result.ok,"ROPE real end-turn commits: "+str(result.get("error","")))

static func threshold_and_stock(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.stock=1
 g.RopeArt.hogtie(g,boss,2)
 t.check(boss.rope_art.refill and boss.rope_art.hogtie_pending==2 and boss.rope_art.hogtie=="","ROPE insufficient stock defers the required hogtie without a partial install")
 g.RopeArt.execute(g,boss,{"kind":"art_refill"})
 var hog=g._equipment(boss.rope_art.hogtie)
 t.check(not hog.is_empty() and hog.grade==2 and g.equipment_tier(hog)==2 and boss.rope_art.stock==9 and boss.rope_art.hogtie_pending==0,"ROPE refill completes the pending medium tier-two hogtie and pays its value")

 g=encounter();boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 g.state.guard_bind={"progress":0.0,"sources":{g.RopeArt.MASTER:{"enemy":boss.id,"energy":0}}}
 boss.rope_art.total=49;boss.rope_art.previous=49
 g.RopeArt.observe(g)
 t.check(boss.rope_art.drunk==0 and boss.rope_art.hogtie=="","ROPE values below the first threshold do not trigger")
 boss.rope_art.total=50;g.RopeArt.observe(g)
 hog=g._equipment(boss.rope_art.hogtie)
 t.check(boss.rope_art.drunk==2 and not hog.is_empty() and hog.grade==2 and boss.rope_art.total==54,"ROPE first crossing 50 adds two drunk layers and a counted medium hogtie")
 boss.rope_art.total=75;boss.rope_art.previous=74;g.RopeArt.observe(g)
 t.check(boss.rope_art.drunk==4,"ROPE first crossing 75 adds two drunk layers")
 boss.rope_art.total=80;boss.rope_art.previous=79;g.RopeArt.observe(g)
 hog=g._equipment(boss.rope_art.hogtie)
 t.check(hog.grade==3 and g.equipment_tier(hog)==2 and boss.rope_art.total==81,"ROPE crossing 80 upgrades and resets the hogtie while counting its added value")
 boss.rope_art.total=90;boss.rope_art.previous=89;g.RopeArt.observe(g)
 var first=boss.rope_art.drunk
 g.RopeArt.observe(g)
 boss.rope_art.total=89;boss.rope_art.previous=90;g.RopeArt.observe(g)
 boss.rope_art.total=90;g.RopeArt.observe(g)
 t.check(first==6 and boss.rope_art.drunk==8,"ROPE 90 triggers once per upward crossing and can trigger again after falling below")

static func card_layers(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var rope=g.action_targets().filter(g.RopeArt.is_rope)[0]
 var other=g.Application.execute_concrete(g,{"kind":"install","template":"belt","slot":"thigh","point":"thigh_root","grade":1,"tier":1,"variant":0,"locked":false},"fixture").installed[0]
 boss.rope_art.submission=1;boss.rope_art.drunk=1
 var shown=g.get_view().statuses.filter(func(row):return row.id in ["rope_submission","rope_drunk"])
 t.check(shown.size()==2 and shown.all(func(row):return row.active and row.owner=="hero" and row.badge=="1" and row.icon!="info"),"ROPE status projection exposes both player debuffs and their actual stack badges")
 g.state.play=[g._make_card("strain")]
 var first_rope=g.RopeArt.card_damage(g,rope,7.0)
 var same_card_other=g.RopeArt.card_damage(g,other,7.0)
 t.check(first_rope==0 and same_card_other==0 and boss.rope_art.submission==0 and boss.rope_art.drunk==1,"ROPE submission has priority and nullifies every equipment hit of one card")
 shown=g.get_view().statuses.filter(func(row):return row.id in ["rope_submission","rope_drunk"])
 t.check(shown.size()==1 and shown[0].id=="rope_drunk" and shown[0].badge=="1","ROPE status projection removes spent submission while retaining drunk")
 g.state.play=[g._make_card("strain")]
 var drunk_first=g.RopeArt.card_damage(g,rope,7.0)
 var drunk_second=g.RopeArt.card_damage(g,rope,7.0)
 t.check(drunk_first==0 and drunk_second==0 and boss.rope_art.drunk==0,"ROPE drunk consumes one layer per card rather than per hit")
 t.check(not g.get_view().statuses.any(func(row):return row.id in ["rope_submission","rope_drunk"]),"ROPE zero-stack debuffs leave the status projection")
 g.state.play=[g._make_card("strain")]
 t.check(g.RopeArt.card_damage(g,rope,7.0)==7.0,"ROPE damage resumes on the following card after both blockers are spent")

static func enchantments_and_helper(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true;boss.rope_art.total=1;boss.rope_art.previous=1
 g.state.guard_bind={"progress":1.0,"sources":{g.RopeArt.MASTER:{"enemy":boss.id,"energy":0}}}
 g.state.strength=5;g.state.dexterity=5;boss.rope_art.active=2
 t.check(g.RelicEffects.attribute(g,"strength")==3 and g.RelicEffects.attribute(g,"dexterity")==3,"ROPE active enchantment dynamically lowers both attributes")
 boss.rope_art.total=0
 t.check(g.RelicEffects.attribute(g,"strength")==5 and g.RelicEffects.attribute(g,"dexterity")==5,"ROPE enchantments pause when capture value reaches zero")
 boss.rope_art.total=1;boss.rope_art.drain=2;g.state.mana=20
 g.RopeArt.turn_end(g)
 boss.rope_art.desire=2;g.state.pressure=0
 g.RopeArt.played(g,{"replay":false,"target":""},true)
 t.check(g.state.mana==10 and g.state.pressure==2,"ROPE drain uses own mana and desire settles once for a played card")
 var enchantments=g.get_view().statuses.filter(func(row):return row.id in ["rope_active","rope_drain","rope_desire"])
 t.check(enchantments.size()==3 and enchantments.all(func(row):return row.active and row.owner=="hero" and row.badge=="2"),"ROPE all three enchantments share the player status strip and actual stack counters")

 g.RopeArt.summon(g,boss)
 var helper=g.RopeArt.assistant(g)
 g.RopeArt.execute(g,helper,{"kind":"art_status"})
 var cards=g.state.draw.filter(func(card):return card.type==g.RopeArt.STATUS)
 var gag=g.equipment_at("mouth")[0]
 t.check(cards.size()==1 and gag.grade==3 and g.equipment_tier(gag)==2 and gag.name.contains("假阳具口球"),"ROPE hard assault adds the status card and the required advanced tier-two dildo gag")
 var status=cards[0];g.state.draw.erase(status);g._put_card_in_hand(status)
 t.check(boss.rope_art.submission==1,"ROPE drawing the helper status grants one submission layer")
 t.check(g.get_view().statuses.any(func(row):return row.id=="rope_submission" and row.active and row.badge=="1"),"ROPE drawing the real status card exposes its debuff badge")
 var before=g.state.special_equipment.map(func(item):return item.id)
 g._damage_enemy(helper,999,"fixed","test")
 var added=g.state.special_equipment.filter(func(item):return item.id not in before)
 t.check(added.size()==2 and added.all(func(item):return g.RestraintValue.from_profile(item.grade,g.equipment_tier(item))==4),"ROPE helper death leaves two distinct value-four special restraints")
 t.check(boss.rope_art.submission==0 and (["deck"]+g.Cards.ZONES).all(func(zone):return not g.state[zone].any(func(card):return card.type==g.RopeArt.STATUS)),"ROPE helper death removes every status copy and its debuff")
 t.check(not g.get_view().statuses.any(func(row):return row.id=="rope_submission"),"ROPE helper death also removes the submission status row")

static func persistence(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_intro"})
 boss.rope_art.active=1;boss.rope_art.hogtie_pending=3;boss.rope_art.refill=true
 var saved=g.export_snapshot()
 var restored=Game.new(0,false,"equipment",false)
 var result=restored.restore_snapshot(saved)
 var loaded=restored.RopeArt.master(restored)
 t.check(result.ok and loaded.rope_art.active==1 and loaded.rope_art.hogtie_pending==3 and loaded.rope_art.refill and not restored.RopeArt.assistant(restored).is_empty(),"ROPE snapshot restores encounter counters, pending threshold work and assistant state")

static func hogtie_shared_release(t) -> void:
 for slot in ["wrist","ankle"]:
  var g=encounter();var boss=g.RopeArt.master(g)
  g.RopeArt.hogtie(g,boss,2)
  var hog=g._equipment(boss.rope_art.hogtie);var id=hog.id
  t.check(g.equipment_at("wrist").any(func(e):return e.id==id) and g.equipment_at("ankle").any(func(e):return e.id==id),"ROPE both slots expose the same physical instance")
  var target=g.equipment_at(slot).filter(func(e):return e.id==id)[0]
  g._apply_equipment_damage(target,7,"strain");g._cleanup()
  var wrist=g.equipment_at("wrist").filter(func(e):return e.id==id)[0]
  var ankle=g.equipment_at("ankle").filter(func(e):return e.id==id)[0]
  t.check(wrist.durability==ankle.durability and g.equipment_tier(wrist)==1 and g.equipment_tier(ankle)==1,"ROPE damage through either slot lowers shared tightness")
  g._apply_equipment_damage(target,999,"strain");g._cleanup()
  t.check(g.equipment_at("wrist").all(func(e):return e.id!=id) and g.equipment_at("ankle").all(func(e):return e.id!=id) and not g.RopeArt.hogtied(g),"ROPE breaking either contact releases both slots")

static func hogtie_attachments(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.hogtie(g,boss,2)
 var hog=g._equipment(boss.rope_art.hogtie)
 t.check(not g.Binding.eligible(hog) and g.Links.anchor_slots(hog).is_empty() and not g.Shoulders.eligible(hog),"ROPE hogtie supplies no ordinary, torso or shoulder attachment anchor")
 for grade in [2,3]:
  var stock=boss.rope_art.stock
  var rng=g.state.rng.duplicate(true)
  g.RopeArt.hogtie(g,boss,grade)
  t.check(hog.grade==grade and g.equipment_tier(hog)==2 and not hog.has("binding") and boss.rope_art.stock==stock and g.state.rng==rng,"ROPE repeated or upgraded hogtie preserves stock value and RNG without attachments")
  g._reinforce_equipment(hog)
  t.check(g.equipment_tier(hog)==3 and not hog.has("binding") and g.state.rng==rng,"ROPE tier-three hogtie never generates or rolls a torso attachment")
 var wrist=g._install_template("rope","wrist",6.4,8.0,false,"fixture")
 var palm=g._install_template(g.Equipment.default_template("palm"),"palm",6.4,8.0,false,"fixture")
 var ankle=g._install_template("rope","ankle",6.4,8.0,false,"fixture")
 var foot=g._install_template(g.Equipment.default_template("foot"),"foot",6.4,8.0,false,"fixture")
 var crotch=g._install_special("crotch_rope_low","special_3_a")
 var before=g.export_snapshot()
 for pair in [[palm,"wrist","palm","palm_left"],[foot,"ankle","foot","foot"],[crotch,"wrist",g.Links.CROTCH_CONTACT,g.Links.CROTCH_CONTACT]]:
  for reverse in [false,true]:
   var ends=[hog.id,pair[0].id];var slots=[pair[1],pair[2]];var points=[pair[1],pair[3]]
   if reverse: ends.reverse();slots.reverse();points.reverse()
   t.check(g._install_link(ends[0],ends[1],6.4,"fixture",1,[],slots,points).is_empty() and g.export_snapshot()==before,"ROPE explicit link installation rejects either hogtie endpoint without IDs, resources or RNG changes")
 var offers=g.EquipmentOffers.links(g,1)
 t.check(not offers.is_empty() and offers.all(func(offer):return hog.id not in offer.ends) and g.export_snapshot()==before,"ROPE enemy link candidates exclude hogtie while retaining valid neighbours read-only")
 t.check(not g._install_link(wrist.id,palm.id,6.4,"fixture",1,[],["wrist","palm"],["wrist","palm_left"]).is_empty() and not g._install_link(ankle.id,foot.id,6.4,"fixture").is_empty(),"ROPE ordinary wrist and ankle anchors retain their real links")
 g._reinforce_equipment(wrist)
 t.check(wrist.has("binding") and not hog.has("binding") and g.validate()=="","ROPE ordinary tier-three wrist still gains its own torso binding")
 var restored=Game.new(0,false,"equipment",false)
 t.check(restored.restore_snapshot(g.export_snapshot()).ok,"ROPE hogtie and independent ordinary attachments roundtrip through the real validator")
 before=g.export_snapshot()
 for kind in ["linked","integrated"]:
  var saved=before.duplicate(true)
  saved.equipment.filter(func(item):return item.id==hog.id)[0].binding={"kind":kind}
  t.check(not g.restore_snapshot(saved).ok and g.export_snapshot()==before,"ROPE forbidden hogtie attachment rejects restoration atomically: "+kind)

static func reported_turn_sequence(t) -> void:
 var g=preload("res://core/game.gd").new(3364630912,true,"rope_master_solo")
 var crossed_upgrade=false
 for step in range(20):
  if g.state.phase!="battle": break
  var result=g.dispatch(g.command({"kind":"end"},g.state.version),g.state.version)
  t.check(result.ok,"ROPE reported seed end-turn commits through upgrade and capture: "+str(result.get("error","")))
  if not result.ok: break
  crossed_upgrade=crossed_upgrade or g.state.equipment.any(func(item):return item.template==g.RopeArt.HOGTIE and item.grade==3)
  t.check(g.state.equipment.filter(func(item):return item.template==g.RopeArt.HOGTIE).all(func(item):return not item.has("binding") and g.state.links.all(func(link):return item.id not in link.ends)),"ROPE live end-turn sequence never attaches a connection to hogtie")
 t.check(crossed_upgrade and g.state.phase=="captured" and g.state.guard_bind.is_empty() and g.validate()=="","ROPE reported sequence crosses hogtie upgrade and reaches valid capture")
 t.check(not g.get_view().statuses.any(func(row):return row.id.begins_with("rope_")),"ROPE battle-only statuses disappear after capture even with retained enemy records")
 var copy=Game.new(0,false,"equipment",false)
 t.check(copy.restore_snapshot(g.export_snapshot()).ok,"ROPE completed capture remains a valid save checkpoint")
 var h=encounter()
 h.RopeArt.execute(h,h.RopeArt.master(h),{"kind":"art_domain"})
 var before=h.state.guard_bind.duplicate(true)
 h.CaptureBind.clear_bind(h)
 t.check(h.state.guard_bind==before,"ROPE ordinary in-battle clearing still respects the domain immunity")
 var result=h.dispatch(h.command({"kind":"surrender"},h.state.version),h.state.version)
 t.check(result.ok and h.state.phase=="captured" and h.state.guard_bind.is_empty(),"ROPE real surrender clears the domain only as part of capture")

static func run(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 t.check(boss.hp==140 and boss.rope_art.stock==48 and boss.intent.kind=="art_intro","ROPE approved opening health, stock and intent")
 t.check(g.validate()=="","ROPE initial state validates: "+g.validate())
 await turn(t,g)
 boss=g.RopeArt.master(g)
 var helper=g.RopeArt.assistant(g)
 t.check(not helper.is_empty() and helper.hp==36 and helper.stage==1,"ROPE summon skips its birth turn")
 t.check(g.RopeArt.target_reason(g,helper,false)!="" and g.RopeArt.target_reason(g,helper,true)=="","ROPE protection rejects single targeting but permits area attacks")
 await turn(t,g)
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.domain and boss.rope_art.total==8 and boss.rope_art.stock==40,"ROPE domain installs two medium tier-two ropes and spends eight")
 var before=g.export_snapshot()
 g.get_view();g.get_view()
 t.check(g.export_snapshot()==before,"ROPE views preserve inventory, thresholds and RNG")
 g.CaptureBind.damage_bind(g,100,"test")
 t.check(g.state.guard_bind.progress==8,"ROPE capture cannot be attacked directly")
 await turn(t,g)
 t.check(g.validate()=="","ROPE opening sweep validates: "+g.validate())
 boss=g.RopeArt.master(g)
 boss.rope_art.seal=true
 var rope=g.state.equipment.filter(func(item):return item.material=="rope")[0]
 g._apply_equipment_damage(rope,999,"cut")
 g._apply_manual_release(rope,0.0)
 g._cleanup()
 t.check(rope.durability>0 and g._equipment(rope.id).id==rope.id,"ROPE final seal blocks damage destruction and direct release")
 boss.rope_art.seal=false
 g.RopeArt.hogtie(g,boss,2)
 var hog=g._equipment(boss.rope_art.hogtie)
 t.check(not hog.is_empty() and g.Equipment.coverage(hog)==["wrist","ankle"] and g.Equipment.capacity_points(hog).is_empty(),"ROPE hogtie is one instance with two contacts and no ordinary capacity")
 t.check(g._slip_reason(hog)!="","ROPE hogtie rejects slipping")
 g.RopeArt.observe(g)
 t.check(g.state.posture=="lie" and g.state.order=="last","ROPE hogtie enforces lying and acting last")
 var stock=boss.rope_art.stock
 g.RopeArt.hogtie(g,boss,3)
 t.check(hog.grade==3 and boss.rope_art.stock==stock-1,"ROPE hogtie grade upgrade pays only the added value")
 var cup=g._install_special("glans_cup_medium","special_2_b",2)
 t.check(not cup.is_empty() and g.RopeArt.unavailable(g),"ROPE cup equipment disables the primary body branch")
 helper=g.RopeArt.assistant(g)
 g._damage_enemy(helper,999,"fixed","test")
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.deaths==1 and boss.intent.kind=="art_grief","ROPE first assistant death preempts the master with grief")
 g.RopeArt.execute(g,boss,boss.intent)
 t.check(g.RopeArt.plan(g,boss).kind=="art_revive","ROPE grief schedules exactly one resurrection")
 g.RopeArt.execute(g,boss,g.RopeArt.plan(g,boss))
 helper=g.RopeArt.assistant(g)
 t.check(helper.hp==36 and helper.stage==1,"ROPE resurrected assistant resets health and its action sequence: id=%s hp=%s stage=%s assistants=%s" % [helper.get("id","missing"),helper.get("hp","missing"),helper.get("stage","missing"),g.state.enemies.filter(func(row):return row.type==g.RopeArt.ASSISTANT).map(func(row):return [row.id,row.gone,row.stage])])
 g._damage_enemy(helper,999,"fixed","test")
 boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,g.RopeArt.plan(g,boss))
 t.check(boss.rope_art.deaths==2 and not boss.rope_art.revive,"ROPE second death causes grief without another resurrection")
 g._damage_enemy(boss,999,"fixed","test")
 t.check(g._all_gone(),"ROPE master defeat ends the encounter")
 threshold_and_stock(t)
 card_layers(t)
 enchantments_and_helper(t)
 persistence(t)
 hogtie_attachments(t)
 hogtie_shared_release(t)
 reported_turn_sequence(t)
