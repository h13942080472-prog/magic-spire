extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func fresh() -> RefCounted:
 var g=Game.new(42);g.state.relics=["olihakimi"];g.state.mana=40.0
 return g

static func run(t) -> void:
 var g=fresh()
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="olihakimi");g.state.relics=[]
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,"uncommon",excluded)=="olihakimi","OLI real uncommon reward pool")
 g=fresh();var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and not g.dispatch(g.command({"kind":"card","uid":"missing"},g.state.version),g.state.version).ok and g.state==before,"OLI read-only and invalid actions never spend or reward")
 var ended=t.action(g,"end")
 t.check(ended.ok and g.state.mana==48 and not g.state.combat.mana_used,"OLI actual unspent turn restores eight and next turn resets flag")
 t.check(ended.resource_feedback.any(func(event):return event.field=="mana" and event.source=="奥利哈基米" and event.after-event.before==8),"OLI named resource animation receives actual recovery")
 t.check(t.action(g,"attack",{"type":"fireball"}).ok and g.state.combat.mana_used,"OLI real fireball marks paid mana")
 g.state.posture="sit";g._gain_tool("mana_potion");var item=g.state.items.back().id
 t.check(t.action(g,"item_use",{"item":item}).ok,"OLI refill after paying is legal")
 var restored=g.state.mana
 t.check(t.action(g,"end").ok and g.state.mana==restored,"OLI restoration never erases earlier mana spending")
 g=fresh();g.state.mana=97
 t.check(t.action(g,"end").ok and g.state.mana==100,"OLI recovery caps at current maximum")
 g=fresh();var free=t.hand_card(g,"ease")
 t.check(t.action(g,"card",{"uid":free.uid,"free":true}).ok and not g.state.combat.mana_used and t.action(g,"end").ok and g.state.mana==48,"OLI zero-cost magical preparation remains eligible")
 g=fresh()
 t.check(t.action(g,"flask",{"op":"deposit"}).ok and not g.state.combat.mana_used,"OLI flask transfer is not expenditure")
 t.check(t.action(g,"end").ok and g.state.mana==38 and g.state.flask_mana==10,"OLI transfer turn restores only personal mana")
 g=fresh();g.state.relics=[]
 t.check(t.action(g,"attack",{"type":"fireball"}).ok,"OLI expenditure before obtaining relic commits")
 g.RelicEffects.gain(g,"olihakimi");var paid=g.state.mana
 t.check(t.action(g,"end").ok and g.state.mana==paid,"OLI late pickup still knows earlier expenditure")
 g=fresh();g.state.relics.append("mana_earring");g.RelicEffects.mana_lost(g,30)
 t.check(g.state.combat.mana_spent==0 and g.state.combat.mana_used,"OLI earring threshold reset cannot erase turn expenditure")
 g.RelicEffects.end_turn(g)
 t.check(g.state.mana==40,"OLI spent turn has no reward even after earring threshold")
 var failure_seen=false
 for seed_value in range(8):
  g=Game.new(seed_value);g.state.relics=["olihakimi"];g.state.pressure=75
  var result=t.action(g,"attack",{"type":"fireball"})
  t.check(result.ok and g.state.combat.mana_used,"OLI paid casting records spending regardless of success")
  if g.state.logs.filter(func(log):return log.data.has("spell")).any(func(log):return not log.data.spell.success):
   failure_seen=true;var mana=g.state.mana;g.RelicEffects.end_turn(g)
   t.check(g.state.mana==mana,"OLI failed paid spell prevents end-turn recovery");break
 t.check(failure_seen,"OLI actual failed cast exercised")
 for phase in ["battle","prison","rest","prepare"]:
  g=fresh();g.state.phase=phase;g.RelicEffects.begin_combat(g);g.RelicEffects.begin_turn(g)
  g.RelicEffects.end_turn(g)
  t.check(g.state.mana==48,"OLI shared turn hook in "+phase)
  g.RelicEffects.mana_lost(g,1);g.RelicEffects.end_combat(g)
  t.check(not g.state.combat.mana_used,"OLI ending session clears spent marker")
 # Current-version validation only; no old-save migration.
 g=fresh();t.action(g,"attack",{"type":"fireball"});var saved=g.export_snapshot();var twin=fresh()
 var restored_result=twin.restore_snapshot(saved)
 t.check(restored_result.ok and twin.state.combat.mana_used,"OLI active turn preserves spent fact: "+str(restored_result))
 var corrupt=saved.duplicate(true);corrupt.combat.erase("mana_used")
 var unchanged=twin.export_snapshot()
 t.check(not twin.restore_snapshot(corrupt).ok and twin.state==unchanged,"OLI incomplete turn fact rejected atomically")
