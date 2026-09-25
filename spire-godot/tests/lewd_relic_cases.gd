extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const IDS=["brainwash_earrings","hypnosis_hairpin","lewd_silk_bodysuit","lewd_silk_gloves"]

static func fresh(ids: Array=[]):
 var g=Game.new(42);g.state.relics=ids.duplicate();g.state.pressure=0
 for enemy in g.state.enemies: enemy.intent.delayed=true
 return g

static func run(t) -> void:
 pools(t)
 pressure(t)
 boundaries(t)
 bodysuit(t)
 casting(t)
 persistence(t)

static func pools(t) -> void:
 var g=fresh()
 for source in ["normal","shop"]:
  t.check(IDS.all(func(id):return id not in g.RelicRewards.available(g,source)),"LEWD RELICS locked pool excludes all four: "+source)
  t.check("pleasure_extractor" in g.RelicRewards.available(g,source) and "lucidity_necklace" in g.RelicRewards.available(g,source),"LEWD RELICS previous two relics remain ordinary rewards")
 t.check(IDS.all(func(id):return id in g.RelicEffects.transform_pool(g)),"LEWD RELICS Ditto can transform without Pro Max")
 g.state.relics=["desire_cube_pro_max"]
 for id in IDS:
  var excluded=g.Relics.REWARDS.filter(func(other):return other!=id)
  t.check(id in g.RelicRewards.available(g,"shop") and g.RelicRewards.offer(g,g.Relics.TYPES[id].rarity,null,excluded)==id,"LEWD RELICS unlocked shared pool offers the correct tier: "+id)
  t.check(g.Relics.trigger_reason(g.Relics.TYPES[id].trigger)=="" if g.Relics.TYPES[id].has("trigger") else true,"LEWD RELICS trigger declaration is accepted: "+id)
  g.state.relics.append(id)
  t.check(id not in g.RelicRewards.available(g),"LEWD RELICS owned reward is not duplicated")
 var invalid=g.Relics.TYPES.hypnosis_hairpin.trigger.duplicate(true);invalid.scope="turn"
 t.check(g.Relics.trigger_reason(invalid)!="","LEWD RELICS repeating pressure event rejects once-per-turn scope")
 invalid=g.Relics.TYPES.hypnosis_hairpin.trigger.duplicate(true);invalid.erase("op")
 t.check(g.Relics.trigger_reason(invalid)!="","LEWD RELICS missing trigger operation rejects without a property error")

static func pressure(t) -> void:
 var g=fresh(["brainwash_earrings"])
 g.Pressure.gain(g,10,"fixture")
 t.check(g.state.pressure==12,"LEWD RELICS earrings add two once per gain without recursion")
 g.Pressure.gain(g,10,"fixture");g.Pressure.gain(g,0,"fixture")
 t.check(g.state.pressure==24,"LEWD RELICS repeated gains each add two and zero requests do not trigger")
 g=fresh(["brainwash_earrings","marble_stone"]);g.Pressure.gain(g,10,"fixture")
 t.check(g.state.pressure==8,"LEWD RELICS earrings flat gain follows ordinary multipliers")
 g=fresh(["brainwash_earrings","green_bird"]);g.state.pressure=98;g.Pressure.gain(g,10,"fixture")
 t.check(g.state.pressure==99 and g.state.overload_total==0,"LEWD RELICS earrings cannot bypass the existing cap guard")
 g=fresh(["hypnosis_hairpin"]);g.state.pressure=40
 t.check(t.action(g,"calm").ok and g.state.pressure==30,"LEWD RELICS actual calm loss triggers hairpin after the action")
 t.check(t.action(g,"calm").ok and g.state.pressure==20,"LEWD RELICS hairpin has no once-per-turn limit")
 g.Pressure.lose(g,0);g.RelicEffects.flush(g)
 t.check(g.state.pressure==20,"LEWD RELICS zero loss does not trigger hairpin")
 g.Pressure.lose(g,100);g.RelicEffects.flush(g)
 t.check(g.state.pressure==10,"LEWD RELICS saturated loss triggers once rather than per point")
 g.state.pressure=95;g.Pressure.gain(g,10,"fixture");g.RelicEffects.flush(g)
 t.check(g.state.pressure==5 and g.state.relic_pending.is_empty(),"LEWD RELICS ordinary climax remainder does not trigger hairpin")
 g=fresh(["brainwash_earrings","hypnosis_hairpin"]);g.state.pressure=40
 t.check(t.action(g,"calm").ok and g.state.pressure==32,"LEWD RELICS hairpin gain receives earrings exactly once")
 g=fresh(["hypnosis_hairpin","edging_seal"]);g.state.pressure=95;g.Pressure.gain(g,10,"fixture");g.RelicEffects.flush(g)
 t.check(g.state.pressure==62.5 and g.state.overload_total==0 and g.state.relic_pending.is_empty(),"LEWD RELICS passive seal reduction triggers hairpin and drains the reaction queue")
 g=fresh(["hypnosis_hairpin","edging_seal"]);g.state.pressure=95
 g.RelicEffects.gain(g,"shrimp_paste");g.state.mana=g.state.mana_max
 var shared=t.grant_fixture_card(g,"shared_fate")
 t.check(t.action(g,"card",{"uid":shared.uid,"free":true}).ok and is_equal_approx(g.state.pressure,61.75),"LEWD RELICS shared fate increase followed by seal loss triggers hairpin only for the seal")
 g=fresh(["hypnosis_hairpin","edging_seal","lucidity_necklace"]);g.state.pressure=95
 g.add_fixture("wrist",8,10)
 g.state.enemies[0].intent.delayed=false;g.state.enemies[0].intent.pressure=95
 t.check(t.action(g,"end").ok and g.state.overload_total==1 and not g.state.overloaded and g.state.hand.size()==g.B.DRAW+1 and g.state.relic_pending.is_empty(),"LEWD RELICS enemy-induced reaction and climax settle before the next player reset and draw")
 g=fresh(["hypnosis_hairpin","ice_heart"]);g.state.pressure=40
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.pressure>=47 and g.state.relic_pending.is_empty(),"LEWD RELICS passive turn loss settles its reward before leaving the turn")

static func boundaries(t) -> void:
 var g=preload("res://core/game.gd").new(42)
 t.action(g,"departure",{"op":"skip"});g.state.relics=["hypnosis_hairpin"]
 var next=g.room_data(g.state.room).next[0]
 t.action(g,"depart",{"room":next});g.state.pressure=30
 t.check(t.action(g,"travel_step").ok and g.state.phase=="battle" and g.state.pressure==38 and g.state.relic_pending.is_empty(),"LEWD RELICS final travel relief settles before battle initialization clears pending effects")
 g=fresh(["hypnosis_hairpin","edging_seal"]);g.state.pressure=70
 g.state.discard.append_array(g.state.hand);g.state.hand.clear()
 var curse=t.grant_fixture_card(g,"sensitive");g.state.hand.erase(curse);g.state.draw.push_back(curse)
 g.Cards.grant_buff(g,"rally_spirit_next");g._begin_player_turn()
 t.check(g.state.hand.any(func(c):return c.uid==curse.uid) and g.state.pressure==65 and g.state.relic_pending.is_empty(),"LEWD RELICS pre-draw reaction uses the old hand multiplier before a sensitivity curse is drawn")
 g=fresh(["hypnosis_hairpin","edging_seal"]);g.state.pressure=95
 g.state.pressure_sources=[preload("res://tests/pressure_cases.gd").source("hairpin_start","turn_start",10)]
 g._begin_player_turn()
 t.check(g.state.pressure==62.5 and g.state.relic_pending.is_empty(),"LEWD RELICS opening stimulus reactions settle before a first-moving enemy can act")
 g=fresh(["hypnosis_hairpin","edging_seal","desire_cube_pro_max"]);g.state.pressure=95
 t.grant_fixture_card(g,"sensitive");g.RelicEffects.end_combat(g)
 t.check(g.state.pressure==65.5 and g.state.relic_pending.is_empty() and not g.state.combat.active,"LEWD RELICS session-end reaction uses the old hand multiplier and settles before cleanup")

static func bodysuit(t) -> void:
 var g=fresh(["lewd_silk_bodysuit","hypnosis_hairpin","pleasure_extractor","lucidity_necklace"])
 g.state.charge=5;g.state.energy=3;g.state.mana=60;g.state.flask_mana=0
 var hand=g.state.hand.duplicate(true)
 g.Pressure.gain(g,300,"fixture",true);g.RelicEffects.flush(g)
 t.check(g.state.overload_total==3 and g.state.pressure==50 and not g.state.overloaded,"LEWD RELICS bodysuit preserves climax counts and fixes pressure at half without hairpin")
 t.check(g.state.charge==5 and g.state.energy==3 and g.state.mana==60 and g.state.hand==hand and g.state.overload_energy==0 and g.state.slip_ejaculation_turns==0,"LEWD RELICS bodysuit prevents resource, hand, charge and future-turn penalties")
 t.check(g.state.flask_mana==30 and g.state.relic_counters.get("lucidity_necklace",0)==3,"LEWD RELICS beneficial climax rewards remain active")
 g=fresh(["lewd_silk_bodysuit","brainwash_earrings"]);g.state.charge=3;g.state.charge_all=true
 g._consume_charge();g.RelicEffects.flush(g)
 t.check(g.state.charge==0 and g.state.pressure==21 and not g.state.charge_all,"LEWD RELICS consuming three layers triggers three five-point gains, each with earrings")
 g._gain_charge(2);g._clear_charge();g.RelicEffects.flush(g)
 t.check(g.state.pressure==21,"LEWD RELICS clearing unused charge is not spending it")
 for phase in ["battle","prepare","rest","prison"]:
  g=Game.new(42,true,"prison_test") if phase=="prison" else fresh()
  g.state.relics=["lewd_silk_bodysuit"]
  if phase=="prepare": g._start_preparation()
  elif phase=="rest": g._start_rest();g._begin_rest()
  else: g._begin_player_turn()
  t.check(g.state.charge==1,"LEWD RELICS body grants charge at each real player-turn boundary: "+phase)
 g=fresh(["lewd_silk_bodysuit"]);g._install_special("negative_plate_lock_catheter_medium","special_2_a")
 g.Pressure.gain(g,g.Pressure.maximum(g),"fixture",true)
 t.check(g.state.slip_ejaculation_turns==0 and not g.state.slip_ejaculation_force_last and g.state.pressure==g.Pressure.maximum(g)*0.5,"LEWD RELICS bodysuit also prevents deferred-loss variant penalties")
 g=fresh(["lewd_silk_bodysuit"]);g.state.pressure=12;g.Pressure.forced_climax(g,"fixture")
 t.check(g.state.pressure==50 and not g.state.overloaded,"LEWD RELICS comfort replaces forced-climax pressure preservation")
 g.Pressure.scripted_climax(g,"fixture")
 t.check(g.state.logs[-1].data.get("scripted_climax",{}).get("source","")=="fixture" and g.state.pressure==50,"LEWD RELICS comfortable scripted climax keeps the final receipt")
 g=Game.new(42,true,"guard");g.state.relics=["lewd_silk_bodysuit"]
 g.CaptureBind.apply_bind(g,g.state.enemies[0]);var progress=g.state.guard_bind.progress
 g.Pressure.gain(g,100,"fixture",true)
 t.check(g.state.guard_bind.progress==progress,"LEWD RELICS bodysuit prevents climax capture-progress penalty")

static func casting(t) -> void:
 var g=fresh(["lewd_silk_gloves"]);g.state.pressure=75
 var profile=g.Cards.cast_profile(g,"fireball")
 t.check(is_equal_approx(g.cast_view(profile).chance,0.5),"LEWD RELICS gloves add 25 percentage points after the pressure curve")
 g.state.pressure=0
 t.check(g.cast_view(profile).chance==1,"LEWD RELICS glove probability clamps at 100 percent")
 g._install_assembly("wrap","left","fixture",1,1)
 t.check(g.cast_view(g.Cards.cast_profile(g,"unlock")).chance==0,"LEWD RELICS glove bonus cannot bypass required hand freedom")
 g=fresh(["lewd_silk_gloves","hypnosis_hairpin","brainwash_earrings"]);g.state.pressure=40;g.state.sure_cast=true
 var card=t.grant_fixture_card(g,"forced_edging");var before=g.export_snapshot()
 var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
 t.check(c.valid and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"LEWD RELICS stale magical pressure payment rejects atomically")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.pressure==39 and g.state.discard.any(func(row):return row.uid==card.uid) and g.validate()=="","LEWD RELICS successful lewd cast and pressure payment both settle after card movement")
 g=fresh(["lewd_silk_gloves"]);g.state.pressure=99;g.state.sure_cast=true
 var enemy=g.state.enemies[0];var hp=enemy.hp
 t.check(t.action(g,"attack",{"type":"fireball","enemy":enemy.id,"form":0}).ok and g._enemy(enemy.id).hp<hp and g.state.overloaded,"LEWD RELICS success-triggered climax occurs after the spell effect")
 var failure_seen=false
 for seed_value in range(8):
  g=Game.new(seed_value);g.state.relics=["lewd_silk_gloves"];g.state.pressure=95
  enemy=g.state.enemies[0]
  t.action(g,"attack",{"type":"fireball","enemy":enemy.id,"form":0})
  var spell=g.state.logs.filter(func(row):return row.data.has("spell"))
  if not spell.is_empty() and not spell.back().data.spell.success:
   failure_seen=true;t.check(g.state.pressure==95,"LEWD RELICS failed casts do not grant pressure");break
 t.check(failure_seen,"LEWD RELICS deterministic seeds include a failed cast")

static func persistence(t) -> void:
 var g=fresh(["hypnosis_hairpin"]);g.state.pressure=30
 g.Pressure.lose(g,5)
 var saved=g.export_snapshot();var twin=Game.new(42)
 t.check(twin.restore_snapshot(saved).ok and twin.state.relic_pending==g.state.relic_pending,"LEWD RELICS pending repeating reaction survives save restoration")
 var bad=saved.duplicate(true);bad.relic_pending.hypnosis_hairpin.amount=1
 var original=twin.export_snapshot()
 t.check(not twin.restore_snapshot(bad).ok and twin.state==original,"LEWD RELICS malformed repeat count is rejected atomically")
 g.RelicEffects.flush(g);twin.RelicEffects.flush(twin)
 t.check(g.state.pressure==35 and twin.state.pressure==35 and g.state.relic_pending.is_empty(),"LEWD RELICS saved reaction delivers exactly once")
 for id in IDS:
  g=preload("res://tests/ditto_cases.gd").fixture(id,false)
  t.check(g.state.ditto_form==id and g.validate()=="","LEWD RELICS Ditto copies the gated relic without selecting Pro Max: "+id)
