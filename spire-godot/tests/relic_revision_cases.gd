extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func run(t) -> void:
 preload("res://tests/lewd_relic_cases.gd").run(t)
 preload("res://tests/lucidity_necklace_cases.gd").run(t)
 preload("res://tests/edging_seal_cases.gd").run(t)
 preload("res://tests/desire_cube_cases.gd").run(t)
 preload("res://tests/scrap_robot_cases.gd").run(t)
 preload("res://tests/ditto_cases.gd").run(t)
 preload("res://tests/first_turn_control_cases.gd").run(t)
 preload("res://tests/sundial_cases.gd").run(t)
 preload("res://tests/great_wand_cases.gd").run(t)
 preload("res://tests/secret_weapon_cases.gd").run(t)
 preload("res://tests/combat_extension_cases.gd").run(t)
 preload("res://tests/axe_amulet_cases.gd").run(t)
 preload("res://tests/oune_hand_cases.gd").run(t)
 preload("res://tests/boss_relic_cases.gd").run(t)
 preload("res://tests/relic_bundle_cases.gd").run(t)
 preload("res://tests/ember_crystal_cases.gd").run(t)
 preload("res://tests/pressure_relic_cases.gd").run(t)
 preload("res://tests/olihakimi_cases.gd").run(t)
 preload("res://tests/rolling_log_cases.gd").run(t)
 preload("res://tests/graduate_certificate_cases.gd").run(t)
 pickup(t)
 combat(t)
 lifecycle(t)
 attributes(t)
 wrist_and_ribbon(t)
 preload("res://tests/relic_mana_cases.gd").run(t)
 drops(t)
 casting_manual(t)
 periodic_energy(t)
 desire_cube(t)
 small_gem(t)
 marble(t)
 kings_gift(t)
 spicy_rice_noodles(t)
 mana_cap_pickups(t)
 green_bird(t)
 green_bird_dynamic(t)

static func green_bird(t) -> void:
 var id="green_bird"
 var g=Game.new(42)
 var excluded=g.Relics.REWARDS.filter(func(key):return key!=id)
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,"rare",excluded)==id,"BIRD rare reward pool")
 for phase in ["battle","prepare","rest","prison"]:
  g=Game.new(42,true,"prison_test") if phase=="prison" else Game.new(42)
  g.state.relics=[id];g.RelicEffects.end_combat(g);g.state.pressure=99.5
  match phase:
   "battle": g._start_battle()
   "prepare": g._start_preparation();g.state.prepare_left=10
   "rest": g._start_rest();t.action(g,"rest_begin");g.state.rest_left=10
   "prison": g.Prison.enter(g)
  t.check(g.state.pressure==99 and g.state.combat.turn==1,"BIRD new session clamps existing fraction and begins first turn: "+phase)
  for turn in range(1,7):
   var mana=g.state.mana;var energy=g.state.energy;var hand=g.state.hand.duplicate(true);var total=g.state.overload_total
   g.Pressure.gain(g,250,"测试来源")
   t.check(g.state.pressure==99 and g.state.mana==mana and g.state.energy==energy and g.state.hand==hand and g.state.overload_total==total and g.RelicEffects.counter(g,id).value==7-turn,"BIRD all six turns cap without overflow side effects: "+phase+str(turn))
   for enemy in g.state.enemies: enemy.intent.delayed=true
   t.check(t.action(g,"end").ok and g.state.combat.turn==turn+1,"BIRD real turn advance: "+phase+str(turn))
  var total=g.state.overload_total
  var remaining=99 if phase=="prison" else 97
  t.check(g.state.pressure==remaining and g.RelicEffects.pressure_guard(g)=="","BIRD seventh turn expires after applicable free cooling: "+phase)
  g.Pressure.gain(g,100-remaining,"测试来源")
  t.check(g.state.pressure==0 and g.state.overload_total==total+1,"BIRD seventh turn restores normal threshold: "+phase)
 g=Game.new(42);g.state.combat.turn=3;g.state.pressure=99.5;g.RelicEffects.gain(g,id)
 t.check(g.state.pressure==99 and g.RelicEffects.counter(g,id).value==4,"BIRD pickup uses current session turn rather than a fresh duration")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"BIRD reading progress does not consume protection")
 g.RelicEffects.end_combat(g);g.state.phase="travel";g.Pressure.gain(g,1,"测试来源")
 t.check(g.state.pressure==0,"BIRD outside a combat session has no protection")
 g=Game.new(80,true,"prison_test");g.state.relics=[id];g.state.combat.turn=6;g.state.prison.left=1
 t.action(g,"end");t.action(g,"prison",{"action":"inspect"});t.action(g,"prison",{"action":"accept"});t.action(g,"prison",{"action":"resume"})
 t.check(g.state.phase=="prison" and g.state.combat.turn==7 and g.RelicEffects.pressure_guard(g)=="","BIRD inspection resume continues the same session count")

static func green_bird_dynamic(t) -> void:
 var g=Game.new(42)
 var lock=g._install_special("negative_plate_lock_medium","special_2_a",2)
 g.state.pressure=119.5;g.RelicEffects.gain(g,"green_bird")
 t.check(g.Pressure.maximum(g)==120 and g.state.pressure==119,"BIRD pickup caps against current maximum rather than fixed ninety-nine")
 g.Pressure.gain(g,250,"测试来源")
 t.check(g.state.pressure==119 and g.state.overload_total==0,"BIRD increased maximum protects gains without overload")
 var before=g.export_snapshot();var view=g.get_view()
 t.check(view.pressure.sources.any(func(row):return row.name=="绿色小鸟" and row.text.contains("119")) and g.RelicEffects.counter(g,"green_bird").detail.contains("119") and g.state==before,"BIRD dynamic limit projections are accurate and readonly")
 lock.durability=lock.maximum*0.3;g._cleanup()
 t.check(g.Pressure.maximum(g)==115 and g.state.pressure==114 and g.state.overload_total==0,"BIRD tightening loss immediately lowers protected limit without overload")
 lock.durability=0;g._cleanup()
 t.check(g.Pressure.maximum(g)==100 and g.state.pressure==99 and g.state.overload_total==0,"BIRD equipment removal clamps to normal protected limit")

static func mana_cap_pickups(t) -> void:
 for entry in [["braised_eggplant","rare",20],["shrimp_paste","uncommon",12]]:
  var id=entry[0];var amount=entry[2];var g=Game.new(42)
  var excluded=g.Relics.REWARDS.filter(func(key):return key!=id)
  t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,entry[1],excluded)==id,"CAP PICKUP correct rarity reward pool: "+id)
  for mana in [40,100]:
   g=Game.new(42);g._finish_battle();g.state.battle_relic_drop=id;g.state.mana=mana
   var claim=t.find_action(g,"reward",{"category":"relic"});var version=g.state.version
   t.check(g.dispatch(g.command(claim.payload,version),version).ok and g.state.mana_max==100+amount and g.state.mana==mana+amount,"CAP PICKUP increases cap before recovery: "+id+" at "+str(mana))
   var before=g.export_snapshot();var view=g.get_view();g.RelicEffects.gain(g,id)
   t.check(view.mana_max==100+amount and view.mana==mana+amount and g.state==before and not g.dispatch(g.command(claim.payload,version),version).ok and g.state==before,"CAP PICKUP projection, duplicate and stale claim cannot reapply: "+id)
   t.action(g,"reward",{"type":"skip"})
   t.check(g.state.mana_max==100+amount and g.state.mana==mana+amount,"CAP PICKUP later session does not repeat effect: "+id)

static func spicy_rice_noodles(t) -> void:
 var id="spicy_rice_noodles"
 var g=Game.new(42)
 var excluded=g.Relics.REWARDS.filter(func(key):return key!=id)
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,"common",excluded)==id,"NOODLES available from common relic pool")
 g.state.charge=1;g.RelicEffects.gain(g,id)
 t.check(g.state.charge==1,"NOODLES mid-session pickup does not grant opening stacks")
 for phase in ["battle","prepare","rest","prison"]:
  g=Game.new(42,true,"prison_test") if phase=="prison" else Game.new(42)
  g.state.relics=[id];g.RelicEffects.end_combat(g);g.state.charge=1
  match phase:
   "battle": g._start_battle()
   "prepare": g._start_preparation()
   "rest": g._start_rest();t.action(g,"rest_begin")
   "prison": g.Prison.enter(g)
  t.check(g.state.phase==phase and g.state.charge==3,"NOODLES actual session opening stacks charge: "+phase)
  t.check(t.action(g,"end").ok and g.state.charge==3,"NOODLES ordinary turn does not repeat opening: "+phase)
 g=Game.new(42);g.state.relics=[id];g._finish_battle()
 var choice=t.find_action(g,"reward",{"type":"skip"});var version=g.state.version
 t.check(g.dispatch(g.command(choice.payload,version),version).ok and g.state.phase=="prepare" and g.state.charge==0,"NOODLES preparation does not trigger another opening")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and not g.dispatch(g.command(choice.payload,version),version).ok and g.state==before,"NOODLES viewing and stale transition cannot duplicate stacks")
 t.check(not g.state.logs.any(func(log):return log.data.get("relic_trigger",{}).get("id","")==id),"NOODLES no duplicate opening feedback during preparation")
 g=Game.new(80,true,"prison_test");g.state.relics=[id];g.state.charge=2;g.state.prison.left=1
 var serial=g.state.combat.serial
 var opening_logs=g.state.logs.filter(func(log):return log.data.get("relic_trigger",{}).get("id","")==id).size()
 t.check(t.action(g,"end").ok and t.action(g,"prison",{"action":"inspect"}).ok,"NOODLES reaches inspection through formal actions")
 t.check(t.action(g,"prison",{"action":"accept"}).ok and g.state.charge==1 and g.state.logs.any(func(log):return log.data.has("prison_inspection_climax")),"NOODLES inspection climax halves two carried charge stacks before resume")
 var carried_charge=g.state.charge
 t.check(t.action(g,"prison",{"action":"resume"}).ok and g.state.phase=="prison" and g.state.charge==carried_charge and g.state.combat.serial==serial,"NOODLES inspection resume preserves charge and the original session")
 t.check(g.state.logs.filter(func(log):return log.data.get("relic_trigger",{}).get("id","")==id).size()==opening_logs,"NOODLES inspection resume does not repeat opening feedback")

static func kings_gift(t) -> void:
 var id="kings_gift_revised"
 var g=Game.new(42)
 var excluded=g.Relics.REWARDS.filter(func(key):return key!=id)
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,"rare",excluded)==id,"KING rare relic is in real reward pool")
 g.state.relics=[id];g.state.round=6;g.state.enemies=[]
 g._append_enemies([{"type":"rope","grade":1,"hp":200},{"type":"drone","grade":1,"hp":200}])
 for e in g.state.enemies: e.intent=g._plan(e);e.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.round==7 and g.state.enemies.all(func(e):return e.hp==200),"KING sixth ending does not fire; seventh turn has begun")
 g.state.strength=10;g.state.charge=3;g.state.card_buffs=["henshin_free"]
 var before=g.export_snapshot();var shown=g.get_view()
 t.check(g.state==before and shown.relics.filter(func(row):return row.id==id)[0].counter.value==7,"KING countdown projects current round without firing")
 t.check(t.action(g,"end").ok and g.state.enemies.all(func(e):return e.hp==123) and g.state.charge==3,"KING seventh ending deals fixed 77 to ordinary and mechanical enemies without consuming charge or doubling")
 t.check(g.RelicEffects.used(g,id) and g.RelicEffects.counter(g,id).text=="✓","KING once-per-battle marker and displayed completion agree")
 t.check(t.action(g,"end").ok and g.state.enemies.all(func(e):return e.hp==123),"KING later endings do not repeat damage")
 # Killing the original team completes rewards before any surviving enemy phase.
 g=Game.new(42);g.state.relics=[id];g.state.round=7;g.state.enemies=[]
 g._append_enemies([{"type":"belt","grade":1},{"type":"drone","grade":1}])
 var end=t.find_action(g,"end");var version=g.state.version;var rewards=g.state.reward_count
 t.check(g.dispatch(g.command(end.payload,version),version).ok and g.state.phase=="reward" and g.state.enemies.all(func(e):return e.gone) and g.state.reward_count==rewards+1,"KING full-team defeat immediately awards one battle completion")
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(end.payload,version),version).ok and g.state==before,"KING stale ending cannot repeat damage or rewards")
 g._start_battle()
 t.check(g.state.round==1 and not g.RelicEffects.used(g,id) and g.RelicEffects.counter(g,id).value==1,"KING new battle resets the existing round and trigger scope")
 # Both threshold and death splits use ordinary enemy handling; newborns are outside the volley.
 for kind in ["rope_mass_solo","rope_heap_solo"]:
  g=Game.new(42,true,kind);g.state.relics=[id];g.state.round=7
  var parent=g.state.enemies[0]
  t.check(t.action(g,"end").ok and g._enemy(parent.id).gone and g.state.phase=="battle","KING damage resolves normal split in "+kind)
  var children=g.state.enemies.filter(func(e):return e.get("spawned_from","")==parent.id)
  t.check(children.size()==(2 if kind=="rope_mass_solo" else 3) and children.all(func(e):return e.hp==e.max_hp and e.spawned_round==7 and e.acted_round==7),"KING new split enemies keep inherited health and skip birth-round action")
 g=Game.new(42,true,"equipment");g.state.relics=[id];g.state.round=7
 t.check(t.action(g,"end").ok and not g.RelicEffects.used(g,id) and g.RelicEffects.counter(g,id).value==0,"KING rest does not consume a battle-only trigger")

static func marble(t) -> void:
 var g=Game.new(42)
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="marble")
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,g.Relics.TYPES.marble.rarity,excluded)=="marble" and g.Relics.TYPES.marble.rarity=="uncommon","MARBLE uncommon relic joins shared rewards")
 g.state.relics=["marble"];g.state.mana=50
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"MARBLE preview does not heal")
 for sample in [[100,50,80,["ember","marble"]],[100,49,79,["marble","ember"]],[156,78,108,["ember","marble"]],[100,50.01,60.01,["ember","marble"]],[30,15,30,["ember","marble"]]]:
  g=Game.new(42);g.state.relics=sample[3];g.state.mana_max=float(sample[0]);g.state.mana=float(sample[1])
  g._finish_battle()
  t.check(g.state.mana==float(sample[1]),"MARBLE victory defers ending recovery")
  t.check(t.action(g,"reward",{"type":"skip"}).ok and t.action(g,"finish_prepare").ok,"MARBLE complete preparation through formal actions")
  t.check(is_equal_approx(g.state.mana,float(sample[2])),"MARBLE actual ending threshold, cap and pendant order "+str(sample.slice(0,3)))
  var triggers=g.state.logs.filter(func(log):return log.data.get("relic_trigger",{}).get("id","") in ["marble","ember"]).map(func(log):return log.data.relic_trigger.id)
  t.check(triggers==(["marble","ember"] if sample[1]<=sample[0]*0.5 else ["ember"]),"MARBLE condition and payout precede pendant regardless of inventory order")
 before=g.export_snapshot();g.RelicEffects.end_combat(g)
 t.check(g.state==before,"MARBLE closed session cannot heal twice")
 g=Game.new(42,true,"equipment");g.state.relics=["marble","ember"];g.state.mana=40
 t.check(t.action(g,"finish_rest").ok and g.state.mana==40,"MARBLE rest ending excludes all battle-ending recovery")
 var PrisonCases=preload("res://tests/prison_cases.gd")
 g=Game.new(42,true,"prison_test");PrisonCases.clear_fixture(g);g.state.relics=["ember","marble"];g.state.mana=40
 t.check(t.action(g,"wall_move",{"direction":"away"}).ok and g.state.mana==40,"MARBLE exploration movement does not end the session or heal")
 g.state.prison.left=1
 t.check(t.action(g,"end").ok and g.state.phase=="inspection" and g.state.mana==40,"MARBLE patrol only pauses exploration without healing")
 t.check(t.action(g,"prison",{"action":"resist"}).ok and g.state.phase=="battle" and g.state.mana==70,"MARBLE paused exploration ends before resistance and heals before pendant")
 g=Game.new(42,true,"prison_test");PrisonCases.clear_fixture(g);g.state.relics=["ember","marble"];g.state.mana=50
 PrisonCases.exit_to_route(t,g)
 t.check(g.state.phase=="map" and g.state.mana==80,"MARBLE real prison escape settles exploration once")

static func small_gem(t) -> void:
 var g=Game.new(42)
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="small_gem")
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,g.Relics.TYPES.small_gem.rarity,excluded)=="small_gem" and g.Relics.TYPES.small_gem.rarity=="common","GEM common relic joins shared rewards")
 var energy=g.state.energy
 g.RelicEffects.gain(g,"small_gem")
 t.check(g.state.energy==energy,"GEM pickup does not retroactively award opening energy")
 for phase in ["battle","prepare","rest","prison"]:
  g.state.phase=phase;g.state.relics=["small_gem","ready_backpack","donut"]
  g.RelicEffects.end_combat(g);g.RelicEffects.begin_combat(g)
  g._reset_piles();g.state.enemies=[];g.state.next_energy=1;g._begin_player_turn()
  t.check(g.state.energy==5 and g.state.hand.size()==7,"GEM first turn stacks with energy and opening draw in "+phase)
  g.state.energy=2;g.RelicEffects.end_turn(g);g._discard_end();g._begin_player_turn()
  t.check(g.state.energy==5 and g.state.hand.size()==5,"GEM later turn retains energy without repeating opening bonus in "+phase)
 # Inspect only the reward-to-preparation transition, not the battle's earlier opening.
 g=Game.new(42);g.RelicEffects.gain(g,"small_gem");g._finish_battle()
 var log_start=g.state.logs.size()
 var choice=t.find_action(g,"reward",{"type":"skip"});var version=g.state.version
 t.check(g.dispatch(g.command(choice.payload,version),version).ok and g.state.phase=="prepare" and g.state.energy==3,"GEM preparation does not repeat opening energy")
 var before=g.export_snapshot();var shown=g.get_view()
 t.check(shown.relics.any(func(r):return r.id=="small_gem" and r.detail.contains("额外获得1能量")) and g.state==before,"GEM description and views are read-only")
 t.check(not g.dispatch(g.command(choice.payload,version),version).ok and g.state==before,"GEM stale transition cannot award again")
 t.check(not g.state.logs.slice(log_start).any(func(log):return log.data.get("relic_trigger",{}).get("id","")=="small_gem"),"GEM no opening gain is emitted for preparation")

static func desire_cube(t) -> void:
 var A=preload("res://core/equipment_application.gd")
 var R=preload("res://tests/replacement_cases.gd")
 var Replacement=preload("res://core/equipment_replacement.gd")
 var g=Game.new(42,true,"trader_solo")
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="desire_cube")
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,g.Relics.TYPES.desire_cube.rarity,excluded)=="desire_cube" and g.Relics.TYPES.desire_cube.rarity=="rare","CUBE rare relic enters shared reward pool")
 g.RelicEffects.gain(g,"desire_cube");g.state.mana=0
 t.check(t.action(g,"end").ok and g.state.mana==10,"CUBE real enemy turn grants five for each of two successful installations")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and g.get_view().relics.any(func(r):return r.id=="desire_cube" and r.detail.contains("恢复5魔力")),"CUBE views expose rule without granting mana")
 t.check(g.state.logs.any(func(log):return log.data.get("relic_trigger",{}).get("id","")=="desire_cube" and log.text.contains("恢复5魔力")),"CUBE recovery has named actual-result log")
 g=Game.new(42);g.state.relics=["desire_cube"];g.state.mana=0
 var root=g._install_assembly("glove","short","event:fixture",2,2)
 t.check(not root.is_empty() and root.components.size()>1 and g.state.mana==5,"CUBE composite and all attached components count as one")
 g=Game.new(42);g.state.relics=["desire_cube"];g.state.mana=0;g.state.phase="inspection"
 var lower=g.add_fixture("wrist",4);var upper=g._install_template("rope","forearm",4,10,false,"fixture",1,0,0,"mid_forearm")
 var link=g._install_link(lower.id,upper.id,4,"inspection")
 t.check(not link.is_empty() and g.state.mana==15,"CUBE noncombat ordinary roots and independent link each count once")
 before=g.export_snapshot()
 t.check(g._install_link(lower.id,upper.id,4,"inspection").is_empty() and g.state==before,"CUBE rejected duplicate link grants nothing")
 lower.locked=true;g._refresh_equipment(lower);lower.durability=lower.maximum;g._refresh_equipment(lower)
 t.check(g.state.mana==15,"CUBE locking reinforcing and attachment refresh grant nothing")
 var special_type=g.SpecialEquipment.TYPES.keys()[0]
 var special_slot=g.SpecialEquipment.DESIGNS[special_type].slots[0]
 var special=g._install_special(special_type,special_slot)
 t.check(not special.is_empty() and g.state.mana==20,"CUBE special equipment counts once")
 g.state.mana=g.state.mana_max-2
 t.check(not g.add_fixture("ankle",4).is_empty() and g.state.mana==g.state.mana_max,"CUBE recovery caps at current maximum")
 g=Game.new(42);R.install(g,R.request("mouth"));g.state.relics=["desire_cube"];g.state.mana=0
 before=g.export_snapshot()
 var plan=Replacement.plan(g,[R.request("mouth",2,2)],"event:fixture")
 t.check(plan.ok and g.state==before,"CUBE replacement preview restores mana and logs")
 t.check(Replacement.execute(g,plan).ok and g.state.mana==5,"CUBE replacement commits exactly one new-equipment recovery")
 before=g.export_snapshot()
 t.check(not Replacement.execute(g,plan).ok and g.state==before,"CUBE repeated replacement cannot pay again")
 var group={"kind":"application_group","requests":[R.request("ankle"),R.request("mouth",1,1)]}
 t.check(not A.execute_concrete(g,group,"event:fixture",true).ok and g.state==before,"CUBE failed atomic group rolls back tentative installation recovery")

static func periodic_energy(t) -> void:
 var g=Game.new(42)
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="happy_fa")
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,g.Relics.TYPES.happy_fa.rarity,excluded)=="happy_fa" and g.Relics.TYPES.happy_fa.rarity=="uncommon","FA uncommon relic joins real shared reward pool")
 g.RelicEffects.gain(g,"happy_fa")
 var before=g.export_snapshot();var shown=g.get_view()
 t.check(shown.relics.filter(func(r):return r.id=="happy_fa")[0].counter.value==0 and g.state==before,"FA pickup and read-only projection do not count the current turn")
 for count in [1,2]:
  t.check(t.action(g,"end").ok and g.state.relic_counters.happy_fa==count and g.state.energy==3,"FA real player turn increments once before threshold")
 g._finish_battle()
 t.check(g.state.relic_counters.happy_fa==2 and g.state.energy==3,"FA progress survives actual combat end")
 var choice=t.find_action(g,"reward",{"type":"skip"});var version=g.state.version
 t.check(g.dispatch(g.command(choice.payload,version),version).ok and g.state.phase=="prepare" and g.state.energy==4 and g.state.relic_counters.happy_fa==0,"FA third turn in next session grants one immediate energy and wraps")
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(choice.payload,version),version).ok and g.state==before,"FA stale transition cannot advance counter or duplicate energy")
 t.check(g.state.logs.any(func(log):return log.get("data",{}).get("relic_trigger",{}).get("id","")=="happy_fa" and log.text.contains("获得1能量")),"FA real energy proc emits named feedback")
 for phase in ["battle","prepare","rest","prison"]:
  g.state.phase=phase;g.state.relic_counters.happy_fa=2;g.state.combat.energy=2;g.state.next_energy=1
  g._begin_player_turn()
  t.check(g.state.energy==7 and g.state.relic_counters.happy_fa==0,"FA adds after regular and retained energy in "+phase)
 for phase in ["map","travel","shop","event","reward","inspection"]:
  g.state.phase=phase;g.state.relic_counters.happy_fa=2;before=g.export_snapshot()
  g.RelicEffects.begin_turn(g)
  t.check(g.state==before,"FA non-player-turn phases never advance: "+phase)
 g.state.phase="prepare";g.state.relic_counters.happy_fa=1;g.RelicEffects.gain(g,"happy_fa")
 t.check(g.state.relic_counters.happy_fa==1,"FA duplicate grant preserves accumulated progress")
 var fresh=Game.new(42)
 t.check(fresh.state.relic_counters.is_empty(),"FA new game starts without carried progress")
 for carried in [1,2]:
  var replay=Game.new(42)
  replay.RelicEffects.gain(replay,"happy_fa")
  replay.state.relic_counters.happy_fa=carried
  replay._start_battle()
  var entry=replay.export_snapshot()
  t.check(entry.relic_counters.happy_fa==(carried+1)%3 and entry.energy==(4 if carried==2 else 3),"FA battle entry carries progress and includes an opening proc in energy")
  t.check(t.action(replay,"end").ok,"FA advances a real turn before quick SL")
  var next_turn=replay.export_snapshot()
  t.check(replay.restore_snapshot(replay.restart_snapshot()).ok,"FA quick SL restores the battle entry")
  var restored=replay.export_snapshot();entry.erase("version");restored.erase("version")
  t.check(restored==entry,"FA quick SL preserves counter and already-granted opening energy without a second trigger")
  t.check(t.action(replay,"end").ok,"FA replay advances the same real player turn")
  restored=replay.export_snapshot();next_turn.erase("version");restored.erase("version")
  t.check(restored==next_turn and replay.state.energy==(4 if carried==1 else 3),"FA replay still triggers the originally due energy and does not duplicate an earlier proc")

static func casting_manual(t) -> void:
 var g=Game.new(42)
 var target=g.add_fixture("ankle",8,10,true)
 var card=t.grant_fixture_card(g,"unlock")
 g._install_assembly("wrap","left","fixture",1,1)
 var choice=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 var before=g.export_snapshot()
 t.check(not choice.valid and choice.reason.contains("双手") and not g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and g.state==before,"MANUAL default requires both complete hands and blocked play spends nothing")
 var fire=t.find_action(g,"attack",{"type":"fireball"})
 t.check(fire.valid and fire.payload.damage==g.B.FIREBALL,"MANUAL single free hand without relic keeps mouth-only fireball damage")
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="casting_manual")
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,g.Relics.TYPES.casting_manual.rarity,excluded)=="casting_manual","MANUAL rare relic participates in the real shared reward pool")
 g.RelicEffects.gain(g,"casting_manual")
 var shown=g.get_view().relics.filter(func(e):return e.id=="casting_manual")
 t.check(shown.size()==1 and shown[0].rarity=="rare" and shown[0].name=="施法动作教程","MANUAL acquired relic projects rare classification and player text")
 choice=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 fire=t.find_action(g,"attack",{"type":"fireball"})
 t.check(choice.valid and fire.payload.damage==g.B.FIREBALL_ASSISTED,"MANUAL one intact hand unlocks spell qualification and fireball gestures")
 var twin=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"casting manual")
 if twin!=null: t.check(t.find_action(twin,"attack",{"type":"fireball"}).payload.damage==g.B.FIREBALL_ASSISTED and t.find_action(twin,"card",{"uid":card.uid,"target":target.id}).valid,"MANUAL restored relic uses the same body qualification")
 t.check(g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and not g._equipment(target.id).locked,"MANUAL actual hand spell works with one wrapped hand")
 fire=t.find_action(g,"attack",{"type":"fireball"})
 var hp=g._enemy(fire.payload.enemy).hp
 t.check(g.dispatch(g.command(fire.payload,g.state.version),g.state.version).ok and g._enemy(fire.payload.enemy).hp==hp-fire.payload.damage,"MANUAL actual fireball applies the gesture bonus")
 var palm=g._install_template("fine_belt","palm",4,10,false,"fixture")
 fire=t.find_action(g,"attack",{"type":"fireball"})
 t.check(not palm.is_empty() and g.hand_cast_reason()!="" and fire.payload.damage==g.B.FIREBALL,"MANUAL free fingers without a free palm do not qualify")
 g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
 g.state.powers=[];g.state.card_buffs=[]
 card=preload("res://tests/card_expansion_cases.gd").give(t,g,"fire_mastery");g.state.energy=3
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and t.find_action(g,"attack",{"type":"fireball"}).payload.damage==g.B.FIREBALL,"MANUAL does not restore gestures disabled by fire mastery")

static func pickup(t) -> void:
 var g=Game.new(73)
 g.state.mana=40
 g.RelicEffects.gain(g,"strawberry")
 g.RelicEffects.gain(g,"braised_eggplant")
 t.check(g.state.mana_max==126 and g.state.mana==66 and g.get_view().mana_max==126,"RELIC pickup adds permanent cap before recovery and projects real cap")
 var saved=g.export_snapshot()
 var twin=Game.new(73)
 t.check(twin.restore_snapshot(saved).ok and twin.state.mana_max==126 and twin.state.mana==66,"RELIC restore does not reapply pickup")
 g.RelicEffects.gain(g,"strawberry")
 t.check(g.state.mana_max==126 and g.state.mana==66,"RELIC duplicate grant cannot repeat permanent increase")
 var restored=twin.export_snapshot()
 var bad=saved.duplicate(true);bad.mana=127
 t.check(not twin.restore_snapshot(bad).ok and twin.export_snapshot()==restored,"RELIC over-cap restore is atomic")
 bad=saved.duplicate(true);bad.combat.energy=-1
 t.check(not twin.restore_snapshot(bad).ok and twin.export_snapshot()==restored,"RELIC invalid retained energy rejected atomically")

static func combat(t) -> void:
 var g=Game.new(74)
 g.state.relics=["mana_earring"]
 var opening_energy=g.state.energy
 g.RelicEffects.mana_lost(g,20)
 t.check(g.state.energy==opening_energy and g.state.combat.mana_spent==20,"RELIC earring no longer triggers at twenty mana")
 g.RelicEffects.mana_lost(g,9)
 t.check(g.state.energy==opening_energy and g.RelicEffects.counter(g,"mana_earring").goal==30 and g.state.combat.mana_spent==29,"RELIC earring displays thirty-mana threshold and waits at twenty-nine")
 g.RelicEffects.mana_lost(g,1)
 t.check(g.state.energy==opening_energy+1 and g.state.combat.mana_spent==0,"RELIC earring grants one energy at exactly thirty mana")
 g.state.relics=["ember","small_sigil","ready_backpack","enchanters_needle_case","donut","mana_earring","ember_crystal"]
 for phase in ["battle","prepare","rest","prison"]:
  g.state.phase=phase;g.state.mana=30;g.state.next_energy=0
  g._reset_piles();g.state.enemies=[]
  g.RelicEffects.begin_combat(g)
  g._begin_player_turn()
  t.check(g.state.mana==35 and g.state.hand.size()==8 and g.state.energy==3,"RELIC opening and every-turn draw hooks in "+phase)
  g.state.energy=2
  g.RelicEffects.end_turn(g);g._discard_end();g._begin_player_turn()
  t.check(g.state.energy==5 and g.state.hand.size()==6,"RELIC donut plus regular refill; needle case remains active after the first turn "+phase)
  var before=g.state.energy
  g.RelicEffects.mana_lost(g,15)
  g.RelicEffects.end_turn(g);g._discard_end();g._begin_player_turn()
  g.RelicEffects.mana_lost(g,45)
  t.check(g.state.energy==before+3+2 and g.state.combat.mana_spent==0,"RELIC mana spending remainder crosses turns and supports multiple thresholds "+phase)
  g.RelicEffects.end_combat(g)
  var after=g.state.mana
  g.RelicEffects.end_combat(g)
  t.check(after==(35 if phase=="rest" else 45) and g.state.mana==after and g.state.energy==0 and not g.state.combat.active and g.state.next_energy==1,"RELIC ending pays once outside rest and caps carried bonus energy "+phase)
 # Actual paid conversion and rejected actions use the authoritative transaction.
 g=Game.new(75);g.state.relics=["mana_earring"];g.state.mana=60
 var card=preload("res://tests/reward_cases.gd").give(t,g,"mana_conversion")
 g.state.combat.mana_spent=20
 var energy=g.state.energy
 t.check(t.action(g,"card",{"uid":card.uid,"target":"self","free":false}).ok and g.state.energy==energy+3 and g.state.mana==40,"RELIC actual fixed mana exchange triggers earring as well as card energy")
 var before=JSON.stringify(g.state)
 t.check(not g.dispatch(g.command({"kind":"card","uid":"missing"},g.state.version),g.state.version).ok and JSON.stringify(g.state)==before,"RELIC invalid command grants no resources or progress")
 for phase in ["map","travel","event","inspection"]:
  g.state.phase=phase;g.RelicEffects.mana_lost(g,40)
 t.check(g.state.combat.mana_spent==10 and g.state.energy==energy+3,"RELIC non-card phases never accumulate mana loss")
 var needle=g.Relics.view(["enchanters_needle_case"])[0]
 t.check(needle.rarity=="rare" and needle.rarity_name=="稀有" and needle.detail.contains("额外抽1张牌") and "enchanters_needle_case" not in g.Relics.REWARDS,"RELIC needle case is a rare event-only relic with its draw effect disclosed")

static func attributes(t) -> void:
 var g=Game.new(76);g.state.wall="normal"
 var calf=g._install_template("rope","calf",6,10,false,"fixture",1,-1,0,"mid_calf")
 var wrist=g.add_fixture("wrist",6)
 var baseline=g.escape_preview(calf,"slip",5)
 var passive=g.escape_preview(calf,"slip",1.2,[],true)
 g.state.relics.append("smooth_stockings")
 var active=g.escape_preview(calf,"slip",5)
 var enhanced=g.escape_preview(calf,"slip",1.2,[],true)
 t.check(active.bonus==2 and active.damage>baseline.damage and enhanced.bonus==2 and enhanced.damage>passive.damage,"RELIC scoped dexterity affects active and passive slip")
 t.check(g.escape_preview(wrist,"slip",5).bonus==0,"RELIC stockings do not increase arm dexterity")
 g.state.equipment.clear();g.state.links.clear();g.state.composites.clear()
 var before=g.attack_facts()
 g.state.relics.append("martial_book")
 var after=g.attack_facts()
 for i in range(before.size()):
  t.check(is_equal_approx(after[i].payload.damage-before[i].payload.damage,0.0 if before[i].payload.type=="fireball" else 1.0),"RELIC strength enters every physical variant per hit, excludes magic")
 wrist=g.add_fixture("wrist",6)
 t.check(g.escape_preview(wrist,"strain",5).bonus==1,"RELIC strength also increases restraint strain")

static func wrist_and_ribbon(t) -> void:
 var g=Game.new(76)
 g.state.wall="normal"
 g.state.equipment.clear();g.state.links.clear();g.state.composites.clear();g.state.relics=[]
 for id in ["wrist_bracer","wraith_ribbon"]:
  var excluded=g.Relics.REWARDS.filter(func(key):return key!=id)
  t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,"common",excluded)==id and id in g.Relics.shop_pool(),"WRIST/RIBBON common reward and shop availability: "+id)
 g.RelicEffects.gain(g,"wrist_bracer")
 t.check(g.RelicEffects.attribute(g,"strength")==0 and g.RelicEffects.attribute(g,"dexterity")==0,"WRIST free wrists grant no attributes")
 var forearm=g.add_fixture("forearm",1)
 t.check(g.RelicEffects.attribute(g,"strength")==0,"WRIST forearm restriction alone does not qualify")
 var wrist=g.add_fixture("wrist",1)
 t.check(g.RelicEffects.attribute(g,"strength")==2 and g.RelicEffects.attribute(g,"dexterity")==0,"WRIST bound wrists grant only two strength")
 t.check(g.escape_preview(wrist,"strain",6).bonus==2 and g.escape_preview(wrist,"slip",6).bonus==0,"WRIST actual escape previews use strength without dexterity")
 var second=g.add_fixture("wrist",4,10,false,1)
 t.check(g.RelicEffects.attribute(g,"strength")==2,"WRIST multiple restraints do not multiply the bonus")
 var card=preload("res://tests/reward_cases.gd").give(t,g,"slip")
 t.check(t.action(g,"card",{"uid":card.uid,"target":second.id,"slot":"wrist","free":false}).ok and not g.state.equipment.any(func(item):return item.id==second.id) and g.RelicEffects.attribute(g,"strength")==2,"WRIST removing one layer keeps the bonus")
 card=preload("res://tests/reward_cases.gd").give(t,g,"slip")
 t.check(t.action(g,"card",{"uid":card.uid,"target":wrist.id,"slot":"wrist","free":false}).ok and not g.state.equipment.any(func(item):return item.id==wrist.id) and g.RelicEffects.attribute(g,"strength")==0,"WRIST final removal through formal play clears the bonus immediately")
 g._install_assembly("glove","short","fixture",2,2)
 t.check(g.RelicEffects.attribute(g,"strength")==2,"WRIST composite wrist coverage also qualifies")
 g.RelicEffects.gain(g,"wraith_ribbon")
 t.check(g.RelicEffects.attribute(g,"strength")==2 and g.RelicEffects.attribute(g,"dexterity")==1,"RIBBON grants one dexterity alongside the conditional wrist strength")
 t.check(g.escape_preview(forearm,"slip",6).bonus==1 and g.escape_preview(forearm,"magic_slip",6).bonus==1 and g.escape_preview(forearm,"slip",1.2,[],true).bonus==1,"RIBBON normal magical and passive slip use the same attribute")
 var snapshot=g.export_snapshot();var twin=Game.new(76)
 t.check(twin.restore_snapshot(snapshot).ok and twin.RelicEffects.attribute(twin,"strength")==2 and twin.RelicEffects.attribute(twin,"dexterity")==1,"WRIST/RIBBON snapshot restores derived attributes without bonus state")
 g.get_view();g.command_facts()
 t.check(g.state==snapshot,"WRIST/RIBBON repeated projection never accumulates attributes or consumes random state")
 g.state.composites.clear();g.state.equipment.clear();g._cleanup()
 t.check(g.RelicEffects.attribute(g,"strength")==0 and g.RelicEffects.attribute(g,"dexterity")==1,"RIBBON remains active with all wrists free")

static func lifecycle(t) -> void:
 var g=Game.new(79)
 g.state.relics=["ember","small_sigil","ready_backpack","donut"]
 g.state.mana=20
 g._finish_battle()
 t.check(g.state.mana==20 and g.state.combat.active,"RELIC victory keeps the session active")
 var serial=g.state.combat.serial
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare" and g.state.combat.serial==serial and g.state.mana==20 and g.state.hand.size()==5,"RELIC reward enters preparation and triggers its opening exactly once")
 t.check(t.action(g,"finish_prepare").ok and g.state.mana==30 and not g.state.combat.active,"RELIC early preparation exit settles ending once")
 g=Game.new(80,true,"prison_test")
 g.state.relics=["ember","small_sigil","ready_backpack","donut"]
 g.state.mana=30;g.state.prison.left=1;g.state.energy=2
 serial=g.state.combat.serial
 t.check(t.action(g,"end").ok and g.state.phase=="inspection" and g.state.combat.serial==serial and g.state.combat.energy==2 and g.state.mana==30,"RELIC inspection pauses prison and keeps donut energy without ending")
 var saved=g.export_snapshot();var twin=Game.new(80)
 t.check(twin.restore_snapshot(saved).ok and twin.state.combat==g.state.combat,"RELIC paused special battle restores its own lifecycle")
 t.action(g,"prison",{"action":"inspect"});t.action(g,"prison",{"action":"accept"});t.action(g,"prison",{"action":"resume"})
 t.check(g.state.phase=="prison" and g.state.combat.serial==serial and g.state.energy==5 and g.state.mana==10,"RELIC inspection resume neither reopens session nor loses saved energy, while the accepted inspection keeps its scripted twenty-mana loss")
 g.state.mana=140;g.state.mana_max=156
 g._gain_tool("mana_potion")
 # Clear only the potion's operator obstruction in this focused resource fixture.
 g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[];g._cleanup()
 t.check(t.action(g,"item_use",{"item":g.state.items.back().id}).ok and g.state.mana==156,"RELIC ordinary mana restoration obeys enlarged cap")

static func drops(t) -> void:
 var g=Game.new(77)
 for source in g.RelicRewards.RATES:
  var counts=[0,0,0]
  for roll in range(100): counts[g.RelicRewards.TIERS.find(g.RelicRewards.rarity(source,roll))]+=1
  t.check(counts==g.RelicRewards.RATES[source],"RELIC exact rarity interval coverage "+source)
 var saved=g.export_snapshot();var twin=Game.new(77);twin.restore_snapshot(saved)
 var result=g.RelicRewards.offer(g)
 t.check(result==twin.RelicRewards.offer(twin) and g.state.rng==twin.state.rng,"RELIC seeded draw and restore reproducible")
 var before=g.state.rng.duplicate()
 g.get_view();g.command_facts()
 t.check(g.state.rng==before,"RELIC inspection never advances reward RNG")
 var pool=g.RelicRewards.available(g)
 g.state.relic_seen=g.Relics.REWARDS.duplicate()
 t.check(g.RelicRewards.available(g)==pool,"RELIC previously offered but unclaimed relics remain available in this run")
 for id in pool: g.state.relics.append(id)
 t.check(g.RelicRewards.available(g).is_empty() and g.RelicRewards.offer(g) in [g.Relics.FALLBACK,g.Relics.COMMON_FALLBACK],"RELIC owning the entire pool uses the rolled tier fallback")
 g=Game.new(78);g.RelicRewards.battle_drop(g)
 t.check(g.state.battle_relic_drop=="","RELIC ordinary battle does not award a relic")
 g.state.room_encounters[g.state.room]="guard_solo"
 g.RelicRewards.battle_drop(g)
 t.check(g.state.battle_relic_drop!="" and g.state.battle_relic_drop not in g.state.relics and g.get_view().battle_relic_drop!="","RELIC elite freezes a pending relic for explicit pickup")
