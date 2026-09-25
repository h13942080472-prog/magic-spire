extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func run(t) -> void:
 marble_reduction(t)
 for entry in [["ice_heart","common"],["magic_blood","uncommon"]]:
  var g=Game.new(42)
  var excluded=g.Relics.REWARDS.filter(func(id):return id!=entry[0])
  t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,entry[1],excluded)==entry[0],"PRESSURE RELIC enters its rarity reward pool")
 for phase in ["battle","prepare","rest","prison"]:
  var g=Game.new(42,true,"prison_test") if phase=="prison" else Game.new(42)
  g.state.relics=["ice_heart","magic_blood"]
  g.RelicEffects.end_combat(g);g.state.pressure=10
  match phase:
   "battle": g._start_battle()
   "prepare": g._start_preparation()
   "rest": g._start_rest();t.action(g,"rest_begin")
   "prison": g.Prison.enter(g)
  t.check(g.state.pressure==15 and g.RelicEffects.attribute(g,"strength")==2,"PRESSURE RELIC first player turn gains five and strength two: "+phase)
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(g.state==before and not g.dispatch(g.command({"kind":"card","uid":"missing"},g.state.version),g.state.version).ok and g.state==before,"PRESSURE RELIC previews and rejected commands do not trigger")
  var start=g.state.logs.size()
  t.check(t.action(g,"end").ok,"PRESSURE RELIC real turn ends: "+phase)
  var logs=g.state.logs.slice(start)
  var cooling=logs.filter(func(log):return log.data.get("relic_trigger",{}).get("id","")=="ice_heart")
  var blood=logs.filter(func(log):return log.data.get("source","")=="魔血")
  t.check(cooling.size()==1 and cooling[0].data.loss==3 and blood.size()==1 and blood[0].data.gain==5,"PRESSURE RELIC each turn boundary triggers exactly once: "+phase)
 var g=Game.new(42);g.state.relics=["ice_heart"];g.state.pressure=2
 t.check(t.action(g,"end").ok and g.state.pressure==0,"ICE HEART floors actual reduction at zero")
 g=Game.new(42);g.state.relics=["magic_blood"]
 var attack=t.find_action(g,"attack",{"type":"strike","form":0})
 var target=g.add_fixture("wrist",60,100)
 t.check(attack.payload.damage==10 and g.RelicEffects.attribute(g,"strength",target)==2,"MAGIC BLOOD existing strength applies to body attacks and restraint calculations")
 g.state.pressure=98;var count=g.state.overload_total
 t.check(t.action(g,"end").ok and g.state.overload_total==count+1 and g.state.pressure==3 and g.state.overloaded and g.state.hand.is_empty(),"MAGIC BLOOD uses real threshold and clears drawn cards on overload")
 g=Game.new(42);g.state.relics=["magic_blood","green_bird"];g.state.pressure=98
 t.check(t.action(g,"end").ok and g.state.pressure==99 and g.state.overload_total==0,"MAGIC BLOOD respects existing pressure cap protection")
 var saved=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"pressure relics")
 t.check(saved!=null and saved.state.relics==g.state.relics,"PRESSURE RELIC ownership survives save and load")
 g.RelicEffects.end_combat(g);g.state.phase="map";g.state.pressure=10
 g.Pressure.tick(g,"turn_start");g.Pressure.tick(g,"turn_end")
 t.check(g.state.pressure==10,"PRESSURE RELIC does not create turns outside combat sessions")

static func marble_reduction(t) -> void:
 var g=Game.new(42)
 var id="marble_stone"
 var excluded=g.Relics.REWARDS.filter(func(key):return key!=id)
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,"rare",excluded)==id,"MARBLE reduction joins rare rewards")
 g.state.pressure=20
 g.RelicEffects.gain(g,id)
 t.check(id in g.state.relics and g.state.pressure==20,"MARBLE pickup preserves existing pleasure")
 var Icons=preload("res://ui/relic_icon.gd")
 t.check(g.Relics.TYPES.marble.name=="西兰花" and g.Relics.TYPES.marble_stone.name=="大理石" and Icons.ART.marble.resource_path.ends_with("broccoli.svg") and Icons.ART.marble_stone.resource_path.ends_with("marble.svg"),"MARBLE and BROCCOLI shared names and art remain distinct")
 preload("res://tests/curse_cases.gd").give(g,"sensitive")
 g.Pressure.gain(g,10,"普通来源")
 t.check(is_equal_approx(g.state.pressure,27.2),"MARBLE multiplies sensitive and relic once")
 g.Pressure.gain(g,10,"固定来源",true)
 t.check(is_equal_approx(g.state.pressure,33.2) and is_equal_approx(g.state.logs.back().data.gain_multiplier,0.6),"MARBLE also reduces fixed gains without applying Sensitive")
 var before=g.export_snapshot();var view=g.get_view();g.command_facts()
 t.check(g.state==before and is_equal_approx(view.pressure.gain_multiplier,0.72),"MARBLE preview uses combined multiplier without changing state")
 t.check(t.action(g,"calm").ok and is_equal_approx(g.state.pressure,13.2),"MARBLE never reduces cooling amounts")
 g.state.pressure=97;g.Pressure.gain(g,5,"阈值")
 t.check(g.state.overload_total==1 and is_equal_approx(g.state.pressure,0.6),"MARBLE reduced amount drives overload and remainder")
 g=Game.new(42);g.state.relics=[id,"green_bird"];g.state.pressure=98
 g.Pressure.gain(g,10,"上限")
 t.check(g.state.pressure==99 and g.state.overload_total==0,"MARBLE is applied before green-bird cap")
 for phase in ["battle","prepare","rest","prison"]:
  g=Game.new(42,true,"prison_test") if phase=="prison" else Game.new(42)
  g.RelicEffects.end_combat(g);g.state.relics=[id,"magic_blood","ice_heart"];g.state.pressure=20
  match phase:
   "battle": g._start_battle()
   "prepare": g._start_preparation()
   "rest": g._start_rest();t.action(g,"rest_begin")
   "prison": g.Prison.enter(g)
  t.check(is_equal_approx(g.state.pressure,23),"MARBLE real turn-start gain is reduced: "+phase)
  var start=g.state.logs.size()
  t.check(t.action(g,"end").ok,"MARBLE formal turn commits: "+phase)
  var logs=g.state.logs.slice(start)
  t.check(logs.any(func(log):return log.data.get("source","")=="魔血" and log.data.gain==3) and logs.any(func(log):return log.data.get("relic_trigger",{}).get("id","")=="ice_heart" and log.data.loss==3),"MARBLE growth and unchanged reduction share all sessions: "+phase)
