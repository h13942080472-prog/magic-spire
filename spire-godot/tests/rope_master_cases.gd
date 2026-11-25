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

static func fixed_type_reduction(t) -> void:
 var expected=[Vector2i(3,3),Vector2i(3,2),Vector2i(3,1),Vector2i(2,1),Vector2i(1,1)]
 for reduction in range(expected.size()):
  var g=encounter()
  var boss=g.RopeArt.master(g)
  boss.rope_art.stock=6-reduction
  var spec={"pool":"ordinary","templates":["mouth_band"],"grade":3,"tier":3}
  var applied=g.RopeArt.install(g,boss,spec)
  var worn=g.equipment_at("mouth")
  t.check(applied and worn.size()==1 and worn[0].template=="mouth_band" and Vector2i(worn[0].grade,g.equipment_tier(worn[0]))==expected[reduction],"VALUE named restraint spends tightness before grade at reduction "+str(reduction))
  t.check(boss.rope_art.stock==0 and spec.grade==3 and spec.tier==3,"VALUE only the installed profile is charged and the declaration is reusable")
 var g=encounter()
 var boss=g.RopeArt.master(g)
 t.check(g.RestraintValue.reduced_profile(2,1,20)=={"grade":1,"tier":1},"VALUE excess reduction clamps both dimensions")
 boss.rope_art.stock=2
 var family={"pool":"special","templates":["crotch_rope_low","crotch_rope_medium","crotch_rope_high"],"grade":2,"tier":1}
 t.check(g.RopeArt.install(g,boss,family) and g.state.special_equipment.any(func(item):return item.type=="crotch_rope_low" and g.equipment_tier(item)==1) and boss.rope_art.stock==0,"VALUE named special family uses its authored lower-grade model")
 g=encounter();boss=g.RopeArt.master(g);boss.rope_art.stock=3
 g.RopeArt.ordinary(g,boss,2,2,{"slot":"wrist"})
 t.check(g.equipment_at("wrist").any(func(item):return item.grade==1 and g.equipment_tier(item)==2),"VALUE random ordinary pool keeps its grade-first shortage rule")
 g=encounter();boss=g.RopeArt.master(g);boss.rope_art.stock=1
 var rng=g.state.rng.duplicate(true)
 t.check(not g.RopeArt.install(g,boss,{"pool":"ordinary","templates":["mouth_band"],"grade":2,"tier":2}) and boss.rope_art.refill and boss.rope_art.stock==1 and g.state.rng==rng and g.equipment_at("mouth").is_empty(),"VALUE stock below the minimum requests refill without installing or drawing")
 boss.rope_art.stock=10
 g.Cards.grant_buff(g,"slippery")
 t.check(g.RopeArt.install(g,boss,{"pool":"ordinary","templates":["mouth_band"],"grade":3,"tier":1}) and g.equipment_at("mouth")[0].grade==3 and g.equipment_tier(g.equipment_at("mouth")[0])==1,"VALUE slippery alone never downgrades a tier-one named restraint")

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

static func growth_and_refill(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 t.check(g.RopeArt.stock_limit(boss)==24 and not boss.rope_art.has("admired"),"ROPE pre-growth saves use the original stock limit without migration")
 g.RopeArt.summon(g,boss)
 t.check(g.RopeArt.assistant(g).name=="绳艺助手" and g.RopeArt.ACTIONS.art_revive=="回来吧我亲爱的手","ROPE updated helper and revival names keep their stable IDs")
 boss.stage=10;boss.intent=g._plan(boss)
 var stock=boss.rope_art.stock
 turn(t,g)
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.get("admired",0)==1 and g.RopeArt.stock_limit(boss)==28 and boss.rope_art.stock==stock,"ROPE real admiration grows the limit once without granting stock")
 boss.stage=14;boss.intent=g._plan(boss)
 turn(t,g)
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.admired==2 and g.RopeArt.stock_limit(boss)==32,"ROPE a second admiration stacks another four capacity and one weave target")
 var before=g.export_snapshot()
 g.get_view();g.command_facts()
 t.check(g.export_snapshot()==before and g.RopeArt.description(boss).contains("/32") and g.RopeArt.description(boss).contains("4件"),"ROPE readonly display reports the grown capacity and actual weave count")
 var restored=Game.new(0,false,"equipment",false)
 t.check(restored.restore_snapshot(before).ok and g.RopeArt.stock_limit(restored.RopeArt.master(restored))==32,"ROPE growth survives a real snapshot restore")
 for invalid in [-1,1.5,"2"]:
  var broken=before.duplicate(true)
  broken.enemies.filter(func(e):return e.type==g.RopeArt.MASTER)[0].rope_art.admired=invalid
  t.check(not g.restore_snapshot(broken).ok and g.export_snapshot()==before,"ROPE invalid growth rejects restoration atomically: "+str(invalid))
 boss=g.RopeArt.master(g)
 boss.rope_art.stock=0;g.RopeArt.observe(g)
 t.check(boss.intent.kind=="art_refill" and g.RopeArt.assistant(g).intent.kind=="art_help","ROPE low stock immediately updates both announced intents")
 var stage=boss.stage
 turn(t,g)
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.stock==32 and boss.stage==stage,"ROPE helper refills the grown limit without advancing the interrupted cycle")
 g.RopeArt.assistant(g).gone=true
 boss.rope_art.stock=1;g.RopeArt.observe(g)
 turn(t,g)
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.stock==17 and boss.stage==stage,"ROPE absent helper adds half the current limit to the existing stock")
 boss.rope_art.stock=40;g.RopeArt.execute(g,boss,{"kind":"art_refill"})
 t.check(boss.rope_art.stock==56,"ROPE solo refill retains the original over-capacity allowance")

 # Compare actual installations from otherwise identical states, not loop metadata.
 for growth in [0,1,2]:
  g=encounter();boss=g.RopeArt.master(g)
  g._install_template("rope","wrist",6.4,8.0,false,"fixture")
  g._install_template(g.Equipment.default_template("palm"),"palm",6.4,8.0,false,"fixture")
  boss.rope_art.admired=growth
  boss.stage=7;boss.intent=g._plan(boss)
  var total=g.action_targets().size()
  turn(t,g)
  boss=g.RopeArt.master(g)
  t.check(g.action_targets().size()-total==2+growth and boss.rope_art.stock==48-(6+3*growth) and g.state.links.is_empty(),"ROPE grown weave installs the extra value-three ropes at their actual stock cost: %s count=%s stock=%s" % [growth,g.action_targets().size()-total,boss.rope_art.stock])

 g=encounter();boss=g.RopeArt.master(g)
 boss.rope_art.stock=3;boss.stage=2;boss.intent=g._plan(boss)
 g.RopeArt.ordinary(g,boss,2,2,{"slot":"wrist"})
 t.check(boss.rope_art.refill and boss.intent.kind=="art_refill","ROPE even a downgraded installation announces refill as soon as its requested stock is insufficient")
 g=encounter();boss=g.RopeArt.master(g)
 boss.rope_art.stock=5;boss.stage=7;boss.intent=g._plan(boss)
 g.RopeArt.hogtie(g,boss,3)
 t.check(boss.rope_art.stock==0 and boss.intent.kind=="art_refill","ROPE threshold equipment spending the final stock also updates the next intent")
 boss.rope_art.grief=true;boss.rope_art.revive=true
 t.check(g.RopeArt.plan(g,boss).kind=="art_refill","ROPE low-stock refill precedes queued grief and revival")
 boss.rope_art.domain=true;boss.rope_art.total=100
 t.check(g.RopeArt.plan(g,boss).kind=="capture","ROPE completed capture still outranks refill")

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

static func hogtie_action_overrides(t) -> void:
 var cards=preload("res://tests/curse_cases.gd")
 var war=preload("res://tests/endless_war_goddess_cases.gd")
 for rope_first in [false,true]:
  var g=war.fresh()
  var rope={}
  if rope_first:
   rope=g._install_template(g.RopeArt.HOGTIE,"wrist",1,8,false,"fixture")
   g.state.energy=8
   t.check(cards.play(t,g,"kip_up",true).ok,"HOGTIE Kip Up can prepare a future kick")
   g.Cards.grant_buff(g,"psychological_suggestion")
   var blocked=t.find_action(g,"attack",{"type":"kick","form":1})
   var unchanged=g.export_snapshot()
   t.check(not blocked.valid and not blocked.posture_available and blocked.reason==g.RopeArt.HOGTIE_REASON and not g.dispatch(g.command(blocked.payload),g.state.version).ok and g.state==unchanged,"HOGTIE Kip Up and Suggestion alone cannot start a kick")
  war.activate(t,g)
  g.state.energy=12;g.state.mana=80
  if not rope_first: t.check(cards.play(t,g,"kip_up",true).ok,"HOGTIE Kip Up may prepare a future leg action")
  if not rope_first: rope=g._install_template(g.RopeArt.HOGTIE,"wrist",1,8,false,"fixture")
  var kip=cards.give(g,"kip_up")
  g.state.strength=4
  g.Cards.grant_buff(g,"psychological_suggestion")
  var stand=t.find_action(g,"card",{"uid":kip.uid,"free":false})
  var before=g.export_snapshot()
  t.check(stand.cost==0 and stand.reason==g.RopeArt.HOGTIE_REASON and not g.dispatch(g.command(stand.payload),g.state.version).ok and g.state==before,"HOGTIE free-cost Kip Up cannot stand under Suggestion or War Goddess")
  var physical=g.command_facts().filter(func(c):return c.payload.kind=="attack" and c.payload.enemy==g.state.enemies[0].id and c.payload.type in g.BasicAttacks.PHYSICAL_PARTS)
  t.check(physical.size()==12,"HOGTIE tests all War Goddess physical forms including alternate kicks")
  for c in physical:
   t.check(c.valid and c.posture_available and g.dispatch(g.command(c.payload),g.state.version).ok and g.RopeArt.hogtied(g) and g.state.posture=="lie","HOGTIE War Goddess executes the selected form while still tied: "+c.label)
   t.check(g.restore_snapshot(before).ok,"HOGTIE restore the same available resources and cooldowns for the next form")
  t.check(t.action(g,"attack",{"type":"fireball"}).ok and g.state.posture=="lie" and "kip_up_free" in g.state.card_buffs,"HOGTIE allows Fireball without consuming the pending leg action")
  t.check(cards.play(t,g,"strain",false,{"target":rope.id}).ok and not g.RopeArt.hogtied(g),"HOGTIE a real struggle removes the physical restriction")
  t.check(t.action(g,"attack",{"type":"kick","form":1}).ok and "kip_up_free" not in g.state.card_buffs and g.state.posture=="lie","HOGTIE the pending leg action can be spent immediately after release")
  t.check(t.action(g,"card",{"uid":kip.uid,"free":false}).ok and g.state.posture=="stand","HOGTIE Kip Up may stand after release")
 var witch=war.fresh(true)
 var rope=witch._install_template(witch.RopeArt.HOGTIE,"wrist",1,8,false,"fixture")
 witch.state.energy=10;witch.state.mana=60;witch.state.witch_charges.legs=4
 var kick=t.find_action(witch,"attack",{"type":"witch_legs","form":1})
 var before=witch.export_snapshot()
 t.check(not kick.posture_available and kick.reason==witch.RopeArt.HOGTIE_REASON and not witch.dispatch(witch.command(kick.payload),witch.state.version).ok and witch.state==before,"HOGTIE Witch Kick stays unavailable with four charges before War Goddess activates")
 war.activate(t,witch)
 witch.state.energy=10;witch.state.mana=60
 t.check(t.action(witch,"attack",{"type":"witch_legs","form":0}).ok and witch.state.witch_charges.legs==5 and t.action(witch,"attack",{"type":"witch_mind","form":1}).ok,"HOGTIE Witch leg preparation and mental casting remain usable")
 t.check(t.action(witch,"attack",{"type":"witch_legs","form":1}).ok and witch.state.witch_charges.legs==0 and witch.RopeArt.hogtied(witch) and witch.state.posture=="lie","HOGTIE War Goddess enables Witch Kick and spends its preparations without releasing the rope")
 t.check(cards.play(t,witch,"witch_strain",false,{"target":rope.id}).ok and not witch.RopeArt.hogtied(witch),"HOGTIE the same rope remains available for normal struggle")

static func hogtie_recovery(t) -> void:
 var g=Game.new(42)
 var rope=g._install_template(g.RopeArt.HOGTIE,"wrist",6.4,8.0,false,"fixture")
 var other=g.add_fixture("thigh",8)
 var id=rope.id
 g.state.mana=40
 var potion=t.take_item_card(g,"mana_potion")
 var snap=g.export_snapshot()
 var saved=snap.duplicate(true);saved.posture="sit"
 t.check(g.restore_snapshot(saved).ok and g.state.posture=="lie","ROPE legacy snapshot restores the equipped special posture without a master")
 t.check(g.movement_profile().speed==0 and g.wall_movement_profile().distance==0 and not t.find_action(g,"posture",{"dest":"sit"}).valid,"ROPE equipped posture prevents travel, wall movement and rising")
 var use=t.find_action(g,"card",{"uid":potion})
 t.check(not use.valid and not g.dispatch(g.command(use.payload),g.state.version).ok and g.state.mana==40,"ROPE a converted potion stays in hand until the posture permits its use")
 g._start_preparation();g.state.prepare_left=1
 t.check(not t.find_action(g,"finish_prepare").valid and t.find_action(g,"end").valid,"ROPE remaining preparation turn allows normal actions and blocks early departure")
 turn(t,g)
 t.check(g.state.phase=="prepare" and g.state.prepare_left==0,"ROPE last preparation turn stops for a worn hogtie")
 var tick=g.state.tick
 for relic in ["sundial","ethereal_pendant","olihakimi"]: g.RelicEffects.gain(g,relic)
 var mana=g.state.mana;var flask=g.state.flask_mana
 var counters=g.state.relic_counters.duplicate(true)
 for i in range(6):
  turn(t,g)
 t.check(g.state.mana==mana and g.state.flask_mana==flask and g.state.relic_counters==counters and g.state.tick==tick,"ROPE repeated recovery hands cannot earn mana, bottle reserves or shuffle relic progress")
 var before=g.export_snapshot()
 var first=t.find_action(g,"card",{"target":id})
 t.check(first.valid and not first.payload.free and first.cost>0 and first.payload.preview.damage>0,"ROPE recovery offers a costed physical card and actual wear preview")
 for f in g.command_facts():
  t.check(f.payload.kind=="end" or (f.payload.kind=="card" and f.payload.target==id and f.payload.mode=="strain"),"ROPE only bound strain shapes against the equipped rope and redraw are offered")
 for p in [{"kind":"manual","target":id},{"kind":"depart","room":"east"},{"kind":"finish_prepare"},{"kind":"flask","op":"store"}]:
  t.check(not g.dispatch(g.command(p),g.state.version).ok and g.export_snapshot()==before,"ROPE restricted hand rejects unrelated commands atomically: "+str(p))
 for edits in [{"target":other.id},{"free":true,"target":""}]:
  var p=first.payload.duplicate(true);p.merge(edits,true)
  t.check(not g.dispatch(g.command(p),g.state.version).ok and g.export_snapshot()==before,"ROPE point lookup rejects forged equipment and free face")
 var once=g.command(first.payload)
 var energy=g.state.energy
 var expected=maxf(0.0,g._equipment(id).durability-first.payload.preview.damage)
 t.check(g.dispatch(once,once.expected_version).ok and is_equal_approx(g._equipment(id).get("durability",0.0),expected),"ROPE selected card deals the displayed damage")
 t.check(g.state.energy==energy-first.cost,"ROPE struggles pay their displayed energy cost")
 t.check(not g.dispatch(once,once.expected_version).ok and g.state.tick==tick,"ROPE stale release cannot resolve twice")
 t.check(g.restore_snapshot(g.export_snapshot()).ok,"ROPE recovery hand roundtrips through the save validator")
 for i in range(20):
  if g.state.phase!="prepare": break
  var next=t.find_action(g,"card",{"target":id})
  if next.valid: t.check(g.dispatch(g.command(next.payload),g.state.version).ok,"ROPE hand card commits")
  else: turn(t,g)
 t.check(g.state.phase=="map" and g.state.completed_rooms.has(g.state.room) and g.state.tick==tick and g._equipment(other.id).durability==8,"ROPE last hit returns to map immediately and preserves other restraints")
 t.check(t.action(g,"depart",{"room":"east"}).ok,"ROPE ordinary route works after release")
 var journey=g.state.journey.duplicate(true)
 rope=g._install_template(g.RopeArt.HOGTIE,"wrist",0.5,8.0,false,"fixture")
 t.check(not g.dispatch(g.command({"kind":"travel_step"}),g.state.version).ok and t.action(g,"end").ok and t.action(g,"card",{"target":rope.id}).ok and g.state.journey==journey and t.action(g,"travel_step").ok,"ROPE en-route recovery preserves the selected journey")
 var rest=Game.new(42,true,"equipment")
 rest.state.rest_left=1
 for zone in ["deck"]+rest.Cards.ZONES: rest.state[zone]=[]
 rest._gain_card("mana_potion")
 var deck=rest.state.deck.duplicate(true)
 var next_uid=rest.state.next_card
 rope=rest._install_template(rest.RopeArt.HOGTIE,"wrist",0.5,8.0,false,"fixture")
 for i in range(3):
  turn(t,rest)
  t.check(rest.state.phase=="rest" and rest.state.deck==deck and rest.state.next_card==next_uid and rest.state.hand.size()==1 and rest.state.hand[0].uid==deck[0].uid and not t.find_action(rest,"card",{"target":rope.id}).valid,"ROPE a hand with no struggle card can pass repeatedly using only owned cards")
 var checkpoint=rest.export_snapshot()
 t.check(rest.restore_snapshot(checkpoint).ok and rest.state.deck==deck,"ROPE a hand without a struggle card survives reload")
 checkpoint=rest.export_snapshot()
 for bad in [17,"card_99999",deck[0].uid]:
  var broken=checkpoint.duplicate(true);broken.hogtie_loan_uid=bad
  t.check(not rest.restore_snapshot(broken).ok and rest.export_snapshot()==checkpoint,"ROPE invalid loan record preserves the valid save and real cards")
 # The retired mechanic persisted a physical basic card in both deck and a live pile.
 rest._gain_card("strain")
 var owned_uid=rest.state.deck.back().uid
 rest._gain_card("strain",{},true)
 var legacy=rest.export_snapshot();legacy.hogtie_loan_uid=legacy.hand.back().uid
 var wrong_copy=legacy.duplicate(true);wrong_copy.hogtie_loan_uid=owned_uid
 t.check(not rest.restore_snapshot(wrong_copy).ok and rest.state.deck==legacy.deck,"ROPE a corrupt legacy marker cannot remove an older owned basic card")
 var original_cards=legacy.deck.filter(func(card):return card.uid!=legacy.hogtie_loan_uid)
 t.check(rest.restore_snapshot(legacy).ok and not rest.state.has("hogtie_loan_uid") and rest.state.deck==original_cards and rest.Cards.instance(rest,legacy.hogtie_loan_uid).is_empty() and t.find_action(rest,"end").valid,"ROPE loading removes only the retired loan and keeps the owned copy")
 t.check(t.action(rest,"end").ok and t.action(rest,"card",{"uid":owned_uid,"target":rope.id}).ok and rest.state.phase=="cleared","ROPE a naturally drawn owned card can finish the struggle after passing")

 var hit=Game.new(42,true,"equipment")
 hit.state.rest_left=1
 for zone in ["deck"]+hit.Cards.ZONES: hit.state[zone]=[]
 hit._gain_card("brace")
 rope=hit._install_template(hit.RopeArt.HOGTIE,"wrist",14.0,16.0,false,"fixture")
 turn(t,hit)
 var charge=hit.state.charge
 var hp=hit._equipment(rope.id).durability
 t.check(t.action(hit,"card",{"target":rope.id}).ok and hit._equipment(rope.id).durability<hp and hit.state.charge<=charge,"ROPE bound struggle deals wear without farming the charge granted on a normal hit")
 var layered=Game.new(42,true,"equipment")
 layered.state.rest_left=1
 for zone in ["deck"]+layered.Cards.ZONES: layered.state[zone]=[]
 layered._gain_card("repeated_strain",{"enchantment":"absorb"})
 var wrist=layered.add_fixture("wrist",8)
 var ankle=layered.add_fixture("ankle",8)
 rope=layered._install_template(layered.RopeArt.HOGTIE,"wrist",0.25,8.0,false,"fixture")
 layered.state.mana=10
 turn(t,layered)
 var saved_mana=layered.state.mana
 var multi=t.find_action(layered,"card",{"type":"repeated_strain","target":rope.id})
 t.check(multi.valid and layered.dispatch(layered.command(multi.payload),layered.state.version).ok,"ROPE multihit can target the hogtie beneath tighter gear")
 t.check(layered.state.phase=="cleared" and layered.state.hand.is_empty() and layered.state.mana==saved_mana and layered._equipment(wrist.id).durability==8 and layered._equipment(ankle.id).durability==8,"ROPE final multihit stops at the broken rope, closes the hand and grants no absorb mana")
 var jail=preload("res://tests/prison_cases.gd").intake(t)
 preload("res://tests/prison_cases.gd").clear_fixture(jail)
 rope=jail._install_template(jail.RopeArt.HOGTIE,"wrist",3.2,8.0,false,"fixture")
 preload("res://tests/exploration_fixture.gd").at_site(jail,"vent")
 preload("res://tests/exploration_fixture.gd").mark_found(jail,"vent")
 jail.state.prison.key=true
 var prison_rows=jail.command_facts().filter(func(row):return row.payload.get("action","") in ["explore","vent_kick","vent_exit","door_exit","key"])
 t.check(prison_rows.size()>=5 and prison_rows.all(func(row):return not row.valid and row.reason==jail.RopeArt.HOGTIE_REASON),"ROPE cell movement, vent, key and exits share the equipped restriction")
 jail._apply_manual_release(rope,0.0);jail._cleanup()
 jail.state.posture="sit"
 t.check(t.action(jail,"prison",{"action":"vent_kick"}).ok,"ROPE kicking the vent works again after release")

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

static func capture_evasion(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.state.evasion=2
 g._enemy_operation(boss,{"kind":"art_domain"})
 t.check(g.state.evasion==2 and g.equipment_at("wrist").size()==1 and g.equipment_at("forearm").size()==1 and boss.rope_art.total==8,"CAPTURE EVASION domain installs both initial ropes and preserves dodge")
 var stock=boss.rope_art.stock
 g._enemy_operation(boss,{"kind":"art_weave"})
 t.check(g.state.evasion==0 and boss.rope_art.stock==stock and boss.rope_art.total==8,"CAPTURE EVASION subsequent weave is evaded and spends no rope")
 g=Game.new(42,false,"equipment",true,false,25,false,false,"witch")
 g.state.room_encounters.entrance="rope_master_solo";g._start_battle()
 boss=g.RopeArt.master(g)
 g.state.evasion=2;g.state.witch_charges.hand=2
 g._enemy_operation(boss,{"kind":"art_domain"})
 t.check(g.state.evasion==2 and g.state.witch_charges.hand==0 and boss.rope_art.total==4,"CAPTURE EVASION witch hand preparation can intercept one initial rope independently")

static func run(t) -> void:
 capture_evasion(t)
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
 fixed_type_reduction(t)
 card_layers(t)
 enchantments_and_helper(t)
 persistence(t)
 growth_and_refill(t)
 hogtie_attachments(t)
 hogtie_shared_release(t)
 hogtie_action_overrides(t)
 hogtie_recovery(t)
 reported_turn_sequence(t)
