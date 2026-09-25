extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func fixture(draw_count: int=0, discard_count: int=1):
 var g=Game.new(42);g.state.relics=[]
 g._reset_piles();g.state.draw.clear();g.state.hand.clear();g.state.discard.clear()
 for i in range(g.state.deck.size()):
  var card=g.state.deck[i].duplicate(true)
  if i<draw_count: g.state.draw.append(card)
  elif i<draw_count+discard_count: g.state.discard.append(card)
  else: g.state.exhaust.append(card)
 g.RelicEffects.gain(g,"sundial")
 return g

static func progress(g) -> int:
 return int(g.state.relic_counters.get("sundial",0))

static func run(t) -> void:
 var g=fixture()
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="sundial")
 g.state.relics=[]
 t.check(preload("res://tests/rolling_log_cases.gd").offer_tier(g,"uncommon",excluded)=="sundial" and "sundial" in g.Relics.shop_pool(),"SUNDIAL uncommon reward and shop pools")
 g.RelicEffects.gain(g,"sundial")
 var energy=g.state.energy
 for i in range(3):
  g._draw(1)
  t.check(progress(g)==(i+1)%3 and g.state.energy==energy+(2 if i==2 else 0),"SUNDIAL third real reshuffle grants exactly two energy: "+str(i))
  if i<2: g._discard_end()
 t.check(g.RelicEffects.counter(g,"sundial").text=="0" and g.state.logs.any(func(row):return row.data.get("relic_trigger",{}).get("id","")=="sundial" and row.data.get("energy_gain",0)==2),"SUNDIAL reset counter and actual energy feedback")
 for amount in [2,8]:
  g=fixture();energy=g.state.energy;g._draw(amount)
  t.check(progress(g)==2 and g.state.hand.size()==1 and g.state.energy==energy,"SUNDIAL one available card overdraw counts real and empty shuffle exactly once: "+str(amount))
 g=fixture();g.state.relic_counters.sundial=1;energy=g.state.energy;g._draw(2)
 t.check(progress(g)==0 and g.state.energy==energy+2,"SUNDIAL empty reshuffle can be the third trigger")
 g=fixture(1,0);g._draw(2)
 t.check(progress(g)==1,"SUNDIAL drawing past a nonempty draw pile counts one final empty shuffle")
 for amount in [0,1,8]:
  g=fixture(0,0);energy=g.state.energy;g._draw(amount)
  t.check(progress(g)==0 and g.state.energy==energy,"SUNDIAL initially empty piles never generate counters: "+str(amount))
 g=fixture(1,0);g._draw(1)
 t.check(progress(g)==0,"SUNDIAL exact draw without recycling does not count")
 g=fixture()
 while g.state.hand.size()<g.B.HAND_LIMIT: preload("res://tests/curse_cases.gd").give(g,"strain")
 g._draw(2)
 t.check(progress(g)==0 and g.state.discard.size()==1,"SUNDIAL full hand prevents reshuffle attempts")
 g=fixture();g.state.hand.append_array(g.state.exhaust.slice(0,g.B.HAND_LIMIT-1));g.state.exhaust=g.state.exhaust.slice(g.B.HAND_LIMIT-1);g._draw(2)
 t.check(progress(g)==1 and g.state.hand.size()==g.B.HAND_LIMIT,"SUNDIAL hand filling after first draw suppresses the empty second shuffle")
 g=fixture();g.state.relic_counters.sundial=2
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before,"SUNDIAL view and facts do not advance count or RNG")
 var twin=Game.new(42)
 t.check(twin.restore_snapshot(before).ok and progress(twin)==2,"SUNDIAL save restores cross-battle progress")
 for bad_value in [-1,3,1.5]:
  var bad=before.duplicate(true);bad.relic_counters.sundial=bad_value
  t.check(not g.restore_snapshot(bad).ok and g.state==before,"SUNDIAL malformed counter is rejected atomically: "+str(bad_value))
 g._reset_piles()
 t.check(progress(g)==2,"SUNDIAL opening pile initialization does not count")
 g.RelicEffects.end_combat(g);g._start_battle()
 t.check(progress(g)==2,"SUNDIAL combat boundary preserves progress without counting opening shuffle")
 formal_draw(t)

static func formal_draw(t) -> void:
 var g=fixture();g.state.relic_counters.sundial=1
 var card=preload("res://tests/curse_cases.gd").give(g,"pot_of_greed")
 var action=t.find_action(g,"card",{"uid":card.uid,"free":false})
 var energy=g.state.energy;var version=g.state.version
 t.check(action.valid and g.dispatch(g.command(action.payload,version),version).ok and progress(g)==0 and g.state.energy==energy+2,"SUNDIAL real draw-two card triggers two shuffles and pays out immediately")
 var before=g.export_snapshot()
 t.check(not g.dispatch(g.command(action.payload,version),version).ok and g.state==before,"SUNDIAL stale play cannot duplicate the energy reward")
