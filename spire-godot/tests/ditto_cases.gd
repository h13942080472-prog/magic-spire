extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

class ForcedGame extends "res://tests/game_fixture.gd":
 var forced_form=""
 func _random_index(domain: String, count: int) -> int:
  if domain=="relic" and forced_form!="": return RelicEffects.transform_pool(self).find(forced_form)
  return super._random_index(domain,count)

static func fixture(form: String, duplicate: bool=true):
 var g=ForcedGame.new(42)
 g.state.relics=["ditto",form] if duplicate else ["ditto"]
 g.forced_form=form
 g.RelicEffects.end_combat(g)
 g._start_battle()
 return g

static func run(t) -> void:
 lifecycle(t)
 var g=fixture("rolling_log",false)
 var pool=g.RelicEffects.transform_pool(g)
 for id in ["rolling_log","membership_card","martial_book","magnifying_glass"]:
  t.check(id in pool,"DITTO eligible passive form: "+id)
 for id in ["ditto","universal_scanner","strawberry","shrimp_paste","oune_hand","m_donalds"]+g.Relics.BOSS_POOL:
  t.check(id not in pool,"DITTO excludes pickup and boss forms: "+id)
 t.check("ditto" in g.Relics.shop_pool() and "ditto" not in g.Relics.REWARDS,"DITTO shop exclusive pool")
 t.check(g.state.relics==["ditto"] and g.state.ditto_form=="rolling_log" and g.RelicEffects.validate(g)=="","DITTO rolling log remains a form, not physical ownership")
 var before=g.export_snapshot()
 g.get_view();g.command_facts()
 t.check(g.state==before,"DITTO read projections do not reroll")
 var twin=Game.new(99)
 t.check(twin.restore_snapshot(before).ok and twin.state.ditto_form=="rolling_log","DITTO save restores selected form")
 for bad_form in [3,"missing","strawberry","binding_pyramid"]:
  var bad=before.duplicate(true);bad.ditto_form=bad_form
  t.check(not g.restore_snapshot(bad).ok and g.state==before,"DITTO malformed form rejects atomically: "+str(bad_form))
 var bad=before.duplicate(true);bad.relics=[]
 t.check(not g.restore_snapshot(bad).ok and g.state==before,"DITTO form requires physical owner")
 g=fixture("martial_book")
 t.check(g.RelicEffects.attribute(g,"strength")==g.state.strength+2,"DITTO duplicate strength adds another copy")
 g=fixture("small_sigil");g.state.mana=30;g.RelicEffects.end_combat(g);g._start_battle()
 t.check(g.state.mana==40,"DITTO transform participates in both opening mana hooks")
 g=fixture("ice_heart");g.state.pressure=20;g.RelicEffects.pressure_tick(g,"turn_end")
 t.check(g.state.pressure==14,"DITTO duplicate end-turn pressure loss")
 g=fixture("marble_stone")
 t.check(is_equal_approx(g.Pressure.source_multiplier(g),0.36),"DITTO duplicate pressure multipliers compose")
 g=fixture("membership_card");g.state.phase="shop"
 t.check(g.Services.discounted_price(g,100)==25,"DITTO duplicate membership discounts compose")
 g=fixture("mana_earring");var energy=g.state.energy
 g.RelicEffects.mana_lost(g,35)
 t.check(g.state.energy==energy+2 and g.state.combat.mana_spent==5 and g.state.relic_counters.ditto==5,"DITTO independent mana meters each pay at thirty")
 before=g.export_snapshot()
 t.check(twin.restore_snapshot(before).ok and twin.state.relic_counters.ditto==5,"DITTO fractional-capable mana meter restores")
 g.forced_form="rolling_log";g.RelicEffects.end_combat(g);g._start_battle()
 t.check(not g.state.relic_counters.has("ditto") and g.state.ditto_form=="rolling_log","DITTO switching clears former meter")
 g=fixture("sundial");g.state.relic_counters.sundial=2;g.state.relic_counters.ditto=1;energy=g.state.energy
 g.RelicEffects.shuffled(g)
 t.check(g.state.energy==energy+2 and g.state.relic_counters.sundial==0 and g.state.relic_counters.ditto==2,"DITTO duplicate sundials keep independent progress")
 g.RelicEffects.shuffled(g)
 t.check(g.state.energy==energy+4 and g.state.relic_counters.sundial==1 and g.state.relic_counters.ditto==0,"DITTO second sundial pays independently")
 g.state.relic_counters.ditto=2;g.forced_form="rolling_log"
 g._start_preparation()
 t.check(g.state.ditto_form=="sundial" and g.state.relic_counters.ditto==2,"DITTO postbattle preparation retains same session form")
 g.RelicEffects.end_combat(g);g._start_battle()
 t.check(g.state.relic_counters.sundial==1 and not g.state.relic_counters.has("ditto"),"DITTO reroll preserves original relic progress")
 g=fixture("break_bracer");g.RelicEffects.strain_destroyed(g)
 t.check(g.state.relic_pending.has("ditto") and g.state.relic_pending.has("break_bracer"),"DITTO duplicate once-per-turn triggers queue independently")
 before=g.export_snapshot()
 t.check(twin.restore_snapshot(before).ok,"DITTO snapshot validates pending trigger against saved form")
 var charge=g.state.charge;g.RelicEffects.flush(g)
 t.check(g.state.charge==charge+2,"DITTO both pending trigger effects settle")
 g.RelicEffects.strain_destroyed(g)
 t.check(g.state.relic_pending.is_empty(),"DITTO both trigger limits prevent double payout")
 g=fixture("great_wand");g.state.mana=30;g.state.relic_counters.ditto=4;g.state.relic_counters.great_wand=2
 var c=t.find_action(g,"relic_discharge",{"relic":"ditto"})
 t.check(c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.mana==34 and g.state.relic_counters.great_wand==2 and g.state.relic_counters.ditto==0,"DITTO formal manual discharge only consumes selected source")
 var row=g.RelicEffects.view(g).filter(func(r):return r.id=="ditto")[0]
 t.check(row.icon=="great_wand" and row.name.contains("百变怪") and row.counter.value==0,"DITTO live projection exposes form and its own counter")
 for form in pool:
  g=fixture(form,false)
  t.check(g.RelicEffects.validate(g)=="" and g.state.relics==["ditto"],"DITTO every eligible opening form obeys relic contract: "+form)

static func lifecycle(t) -> void:
 var Save=preload("res://tests/persistence_cases.gd")
 for duplicate in [false,true]:
  var g=fixture("magnifying_glass",duplicate)
  g._finish_battle()
  t.check(g.state.reward_options.size()==(5 if duplicate else 4),"DITTO lens duplicate adds another actual reward option")
  Save.roundtrip(t,g,"ditto lens battle rewards "+str(duplicate))
  g.RelicEffects.end_combat(g);g.state.room="rest";g.state.practice=false
  g._start_rest();var cards=g.state.rest_cards.duplicate();g.forced_form="rolling_log"
  t.check(t.action(g,"rest_begin").ok and g.state.ditto_form=="rolling_log" and g.state.rest_cards==cards,"DITTO rest reroll retains previously frozen card choices")
  Save.roundtrip(t,g,"ditto frozen lens rest rewards "+str(duplicate))
 for phase in ["battle","prepare","rest","prison"]:
  var g=ForcedGame.new(42,true,"prison_test") if phase=="prison" else ForcedGame.new(42)
  g.state.relics=["ditto"];g.forced_form="spicy_rice_noodles";g.RelicEffects.end_combat(g)
  match phase:
   "battle": g._start_battle()
   "prepare": g._start_preparation()
   "rest": g._start_rest();t.action(g,"rest_begin")
   "prison": g.Prison.enter(g)
  t.check(g.state.ditto_form=="spicy_rice_noodles" and g.state.charge==2,"DITTO formal session opening applies new form: "+phase)
  g.forced_form="rolling_log"
  t.check(t.action(g,"end").ok and g.state.ditto_form=="spicy_rice_noodles","DITTO ordinary round does not reroll: "+phase)
 var a=Game.new(93);var b=Game.new(93)
 for g in [a,b]: g.RelicEffects.gain(g,"ditto");g.RelicEffects.end_combat(g);g._start_battle()
 t.check(a.state.ditto_form==b.state.ditto_form and a.state.rng==b.state.rng,"DITTO seeded session openings reproduce form and RNG")
 var g=ForcedGame.new(42,false,"equipment",true,false,25,false,false,"witch")
 g.state.relics=["ditto","witch_noodles"];g.forced_form="witch_noodles"
 g.RelicEffects.end_combat(g);g.state.witch_focus=0;g.state.phase="travel";g._start_battle()
 t.check(g.state.witch_focus==4,"DITTO witch travel-to-battle applies both opening focus sources")
 g.RelicEffects.end_combat(g);g.state.witch_focus=0;g._start_rest();t.action(g,"rest_begin")
 t.check(g.state.witch_focus==0,"DITTO witch battle-only opening does not fire at rest")
 var pool=g.RelicEffects.transform_pool(g)
 t.check("witch_noodles" in pool and "mana_earring" not in pool and "break_bracer" not in pool,"DITTO uses current character eligibility")
