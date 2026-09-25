extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const PressureCases=preload("res://tests/pressure_cases.gd")

static func fresh():
 var g=Game.new(42);g.state.relics=[]
 g.RelicEffects.gain(g,"lucidity_necklace")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 return g

static func pending(g) -> int:
 return int(g.state.relic_counters.get("lucidity_necklace",0))

static func run(t) -> void:
 var g=fresh()
 t.check(pending(g)==0 and g.Relics.TYPES.lucidity_necklace.rarity=="rare","NECKLACE rare pickup grants no immediate draw")
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="lucidity_necklace")
 var pool=Game.new(42);pool.state.relics=[]
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(pool,"rare",excluded)=="lucidity_necklace","NECKLACE shared rare pool offers the relic")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"NECKLACE previews leave pending draw unchanged")
 g.Pressure.gain(g,99,"fixture",true)
 t.check(pending(g)==0,"NECKLACE subthreshold pressure never queues cards")
 g.state.pressure_sources=[PressureCases.source("necklace_fixture","posture",1)]
 var action=t.find_action(g,"posture",{"dest":"sit","wall":false});var version=g.state.version
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(action.payload,version-1),version-1).ok and g.state==before,"NECKLACE stale trigger action rolls back")
 t.check(g.dispatch(g.command(action.payload,version),version).ok and pending(g)==1 and g.state.hand.is_empty() and g.state.overloaded,"NECKLACE real climax queues one and does not draw into the interrupted turn")
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(action.payload,version),version).ok and g.state==before,"NECKLACE duplicate trigger cannot queue twice")
 t.check(g.RelicEffects.counter(g,"lucidity_necklace").value==1,"NECKLACE shared icon projection exposes pending count")
 var restored=Game.new(42)
 t.check(restored.restore_snapshot(before).ok and pending(restored)==1,"NECKLACE snapshot preserves pending reward without repeating it")
 for invalid in [-1,0.5]:
  var bad=before.duplicate(true);bad.relic_counters.lucidity_necklace=invalid
  t.check(not g.restore_snapshot(bad).ok and g.state==before,"NECKLACE invalid saved counter is rejected atomically: "+str(invalid))
 t.check(t.action(g,"end").ok and g.state.hand.size()==g.B.DRAW+1 and pending(g)==0,"NECKLACE next real player turn draws one extra and consumes pending once")
 t.check(t.action(g,"end").ok and g.state.hand.size()==g.B.DRAW and pending(g)==0,"NECKLACE following turn does not draw the old bonus again")
 g=fresh();g.Pressure.gain(g,300,"fixture",true)
 t.check(pending(g)==3 and g.state.hand.is_empty(),"NECKLACE batched climaxes accumulate one per occurrence")
 t.check(t.action(g,"end").ok and g.state.hand.size()==g.B.DRAW+3 and pending(g)==0,"NECKLACE stacked bonus joins the ordinary opening draw")
 g=fresh();g.Pressure.gain(g,2000,"fixture",true)
 t.check(t.action(g,"end").ok and g.state.hand.size()==g.B.HAND_LIMIT and pending(g)==0,"NECKLACE oversized bonus respects hand cap and is consumed even when capped")
 g=fresh();g.state.pressure_sources=[PressureCases.source("necklace_start","turn_start",100)]
 t.check(t.action(g,"end").ok and g.state.overloaded and pending(g)==1 and g.state.hand.is_empty(),"NECKLACE a new-turn climax queues for the following turn")
 g.state.pressure_sources=[]
 t.check(t.action(g,"end").ok and pending(g)==0 and g.state.hand.size()==g.B.DRAW+1,"NECKLACE newly queued opening reward is delivered only on the following turn")
 g=fresh();g.state.pressure=70;g.Cards.grant_buff(g,"rally_spirit_next")
 t.check(t.action(g,"end").ok and pending(g)==1 and g.state.hand.size()==g.B.DRAW,"NECKLACE pre-draw turn-start climax cannot consume its newly queued bonus in the same opening")
 g=fresh();g._install_special("negative_plate_lock_catheter_medium","special_2_a")
 g.Pressure.gain(g,g.Pressure.maximum(g),"fixture",true)
 t.check(g.state.slip_ejaculation_turns==2 and pending(g)==1,"NECKLACE deferred-loss climax uses the same queue")
 g=fresh();var hand=g.state.hand.duplicate(true)
 g.Pressure.scripted_climax(g,"fixture")
 t.check(pending(g)==1 and g.state.hand==hand and g.state.logs[-1].data.get("scripted_climax",{}).get("source","")=="fixture","NECKLACE scripted climax queues rather than drawing and preserves the final receipt")
 g.Pressure.forced_climax(g,"fixture")
 t.check(pending(g)==2,"NECKLACE forced climax shares the same queue")
 g.RelicEffects.end_combat(g)
 t.check(pending(g)==2,"NECKLACE session end preserves unclaimed next-turn reward")
 g._start_battle()
 t.check(pending(g)==0 and g.state.hand.size()==g.B.DRAW+2,"NECKLACE next scene opening consumes the carried reward once")
 g=preload("res://tests/ditto_cases.gd").fixture("lucidity_necklace")
 g.Pressure.gain(g,100,"fixture",true)
 t.check(pending(g)==1 and g.state.relic_counters.get("ditto",0)==1,"NECKLACE Ditto and original queue independently")
 t.check(t.action(g,"end").ok and g.state.hand.size()==g.B.DRAW+2 and pending(g)==0 and not g.state.relic_counters.has("ditto"),"NECKLACE both independent bonuses are consumed by the shared opening draw")
 g=fresh();g.RelicEffects.gain(g,"sundial");g.state.relic_counters.sundial=2
 g.state.discard.append_array(g.state.draw);g.state.draw.clear()
 g.Pressure.gain(g,100,"fixture",true)
 t.check(t.action(g,"end").ok and g.state.hand.size()==g.B.DRAW+1 and g.state.relic_counters.sundial==0 and not g.state.overloaded,"NECKLACE next-turn draw uses the ordinary shuffle and Sundial path")
