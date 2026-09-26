extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func battle_climax_scope(t) -> void:
 for phase in ["event","rest","prison","prepare","travel","battle"]:
  for prior in [0,3,4,12]:
   var g=Game.new(42)
   g.state.phase=phase
   if prior>0: g.Pressure.gain(g,100.0*prior,"计数检查")
   t.check(g.state.overload_total==prior,"SIX SCOPE global history remains available: "+phase+str(prior))
   g.state.room_encounters.entrance="six_bind_solo"
   g._start_battle()
   var e=g.state.enemies[0]
   t.check(e.next_climax_capture==prior+4 and e.intent.kind=="six_prepare","SIX SCOPE entry excludes all prior phases: "+phase+str(prior))
   t.check(g.validate()=="","SIX SCOPE entry with prior history validates")
   var saved=g.export_snapshot()
   var restored=Game.new(43)
   t.check(restored.restore_snapshot(saved).ok and restored.state.enemies[0].next_climax_capture==prior+4,"SIX SCOPE restore preserves entry threshold")
   var bad=saved.duplicate(true)
   bad.enemies[0].next_climax_capture=prior+5
   var before=restored.export_snapshot()
   t.check(not restored.restore_snapshot(bad).ok and restored.export_snapshot()==before,"SIX SCOPE impossible future threshold rejects atomically")
   for count in range(1,5):
    g.Pressure.gain(g,100.0,"本场计数检查")
    e.intent=g._plan(e)
    t.check(g.state.overload_total==prior+count and (e.intent.kind=="capture")== (count==4),"SIX SCOPE only the fourth in this encounter prepares arrest")
   g._start_battle()
   t.check(g.state.enemies[0].next_climax_capture==prior+8 and g.state.enemies[0].intent.kind=="six_prepare","SIX SCOPE another encounter starts a fresh four-count window")

static func encounter(seed_value: int=42):
 var g=Game.new(seed_value)
 g.state.room_encounters.entrance="six_bind_solo"
 g._start_battle()
 return g

static func area_has_target(g, slots: Array) -> bool:
 for item in g.action_targets():
  var covered=item.get("slots",[]) if item.get("template","")=="link_rope" else (g.SpecialEquipment.occupied_slots(item) if g.SpecialEquipment.is_special(item) else g.Equipment.coverage(item))
  if covered.any(func(slot):return slot in slots): return true
 return false

static func run(t) -> void:
 battle_climax_scope(t)
 idle_cycle(t)
 interrupted_bound_kick_cycle(t)
 var g=encounter()
 var e=g.state.enemies[0]
 t.check(e.type=="six_bind" and e.name=="六缚" and e.hp==200 and e.constriction==0 and e.intent.kind=="six_prepare","SIX BIND summit boss starts with preparation and zero constriction")
 var result=t.action(g,"end");e=g.state.enemies[0]
 t.check(result.ok and e.stage==2 and e.intent.kind=="six_opening" and g.state.equipment.is_empty(),"SIX BIND first action only prepares the formation")
 result=t.action(g,"end");e=g.state.enemies[0]
 t.check(result.ok and e.stage==3 and e.intent.kind=="six_tease" and g.state.special_equipment.size()==1,"SIX BIND opening applies six-area restraints and one legal toy")
 for area in g.EnemyPlans.six_areas():
  t.check(area_has_target(g,area.slots),"SIX BIND opening reaches "+area.name)
 t.check(g.validate()=="","SIX BIND opening leaves a valid state")

 g=encounter(17);e=g.state.enemies[0]
 for slot in ["wrist","ankle","mouth"]: g.add_fixture(slot,4)
 e.stage=5;e.constriction=2;e.intent=g.EnemyPlans.six_plan(g,e)
 t.check(e.intent.kind=="six_tune" and e.intent.count==3 and e.intent.grade==1,"SIX BIND warming freezes one plus current constriction at announcement")
 result=t.action(g,"end");e=g.state.enemies[0]
 t.check(result.ok and e.constriction==3 and g.state.special_equipment.size()==3,"SIX BIND warming installs three legal toys, reinforces three times, then gains one constriction")
 e.stage=13;e.intent=g.EnemyPlans.six_plan(g,e)
 t.check(e.intent.kind=="six_tune" and e.intent.count==4 and e.intent.grade==2,"SIX BIND later cycles use medium toys without changing the stack formula")

 g=encounter(23);e=g.state.enemies[0]
 g._enemy_operation(e,{"kind":"six_tease","text":"戏弄封缚","delayed":false})
 var curse=g.state.discard.filter(func(card):return card.type=="tease")[0]
 g.state.discard.erase(curse);g.state.hand.append(curse)
 var pressure=g.state.pressure
 g.Cards.end_hand(g)
 t.check(g.state.pressure==pressure+5,"SIX BIND 玩弄 adds its printed pleasure only while held at turn end")
 g._six_add_curses(e,"tease_plus",3)
 t.check(g.state.deck.filter(func(card):return card.type=="tease_plus").size()==3,"SIX BIND finale curse injection creates three distinct combat cards")
 g._finish_battle()
 t.check(g.state.phase=="reward" and g.state.deck.any(func(card):return g.B.CARD_TRAITS.get(card.type,{}).get("temporary",false)),"SIX BIND victory retains temporary curses for preparation")
 t.check(t.action(g,"reward",{"type":"skip"}).ok and t.action(g,"finish_prepare").ok and not g.state.deck.any(func(card):return g.B.CARD_TRAITS.get(card.type,{}).get("temporary",false)),"SIX BIND preparation end purges temporary curses")

 g=encounter(31);e=g.state.enemies[0]
 var ordinary=g.EnemyPlans.six_ordinary(g.Enemies.TYPES.six_bind,2,3,1,false)
 for i in range(400):
  if not g.Application.execute(g,ordinary,e.id).ok: break
 for i in range(400):
  var targets=g.EnemyPlans.targets(g,e,"tighten")
  if targets.is_empty(): break
  g._enemy_operation(e,{"kind":"tighten","target":targets[0].id,"tier":3,"text":"加固","delayed":false})
 t.check(g.EnemyPlans.can_affect_equipment(g,e) and g._plan(e).kind!="capture" and not g._finish_if_saturated(),"SIX BIND remaining special equipment or replacement space keeps the boss battle active")
 # Higher-grade fixtures also cover genuine replacement refusal, without
 # assuming that swapping two different equal-grade designs is a no-op.
 for type in g.SpecialEquipment.DESIGNS:
  var design=g.SpecialEquipment.DESIGNS[type]
  if design.grade==3 and not g.SpecialEquipment.TYPES[type].get("relic_only",false): g._install_special(type,design.slots[0],3)
 # Newly installed anchors may open real links from the ordinary source pool.
 for i in range(100):
  if not g.Application.execute(g,ordinary,e.id).ok: break
 for i in range(200):
  var targets=g.EnemyPlans.targets(g,e,"tighten")
  if targets.is_empty(): break
  g._enemy_operation(e,{"kind":"tighten","target":targets[0].id,"tier":3,"text":"加固","delayed":false})
 var before=g.export_snapshot()
 t.check(not g.EnemyPlans.can_affect_equipment(g,e) and not g._finish_if_saturated() and g.state==before,"SIX BIND shared capacity check exhausts add reinforce and replace without awarding victory")
 e.intent=g._plan(e)
 t.check(e.intent.kind=="capture" and t.action(g,"end").ok and g.state.phase=="captured","SIX BIND announces and executes actual capture after its full repertoire is exhausted")

 g=encounter(37);e=g.state.enemies[0]
 var threshold=g.Enemies.TYPES.six_bind.climax_capture_threshold
 t.check(threshold==4 and g.Enemies.TYPES.six_bind.climax_capture_repeat==1 and e.next_climax_capture==4,"SIX BIND starts at four climaxes then checks every later climax")
 g.state.overload_total=threshold-1;e.intent=g._plan(e)
 t.check(e.intent.kind=="six_prepare","SIX BIND does not replace its original sequence below four cumulative climaxes")
 g.state.overload_total=threshold;e.intent=g._plan(e)
 t.check(e.intent.kind=="capture" and e.intent.text=="准备逮捕" and e.intent.cancel_on_interrupt and e.intent.climax_threshold==4,"SIX BIND announces interruptible arrest at four cumulative climaxes")
 var restored=Save.roundtrip(t,g,"six-bind climax arrest announcement")
 t.check(restored._enemy(e.id).intent==e.intent and restored._enemy(e.id).next_climax_capture==4,"SIX BIND snapshot preserves the announced threshold arrest")
 var good=g.export_snapshot();var bad=good.duplicate(true);bad.enemies[0].intent.climax_threshold=5
 t.check(not g.restore_snapshot(bad).ok and g.export_snapshot()==good,"SIX BIND snapshot rejects a mismatched arrest threshold atomically")
 t.check(t.action(g,"end").ok and g.state.phase=="captured","SIX BIND completes an uninterrupted climax arrest through the normal capture flow")

 g=encounter(41);e=g.state.enemies[0]
 g.state.overload_total=threshold;e.intent=g._plan(e)
 var original_stage=e.stage
 g.state.card_buffs.append("infusion_bound")
 t.check(t.action(g,"attack",{"type":"kick","form":2,"enemy":e.id}).ok and g._enemy(e.id).intent.delayed,"SIX BIND climax arrest accepts the shared physical-attack interrupt route")
 t.check(g.state.logs.any(func(log):return log.text=="六缚的逮捕准备被打断。"),"SIX BIND interruption reports cancellation instead of a one-turn delay")
 t.check(t.action(g,"end").ok,"SIX BIND resolves the cancelled arrest turn")
 e=g._enemy(e.id)
 t.check(g.state.phase=="battle" and e.next_climax_capture==5 and e.stage==original_stage and e.intent.kind=="six_prepare","SIX BIND cancelled arrest advances to the next climax and resumes the unadvanced original action next round")
 t.check(t.action(g,"end").ok and g._enemy(e.id).stage==original_stage+1 and g._enemy(e.id).intent.kind=="six_opening","SIX BIND executes the restored original sequence before checking the next threshold")
 g.state.overload_total=5
 t.check(t.action(g,"end").ok and g._enemy(e.id).stage==original_stage+2 and g._enemy(e.id).intent.kind=="capture" and g._enemy(e.id).intent.climax_threshold==5,"SIX BIND prepares another arrest on every climax after the fourth")
 t.check(g.validate()=="","SIX BIND climax arrest paths leave a valid current snapshot")

static func interrupted_bound_kick_cycle(t) -> void:
 var g=encounter(47);var e=g.state.enemies[0]
 g.add_fixture("ankle",1)
 g.state.energy=20;e.stage=3;e.intent=g._plan(e)
 var original=e.intent.duplicate(true);var stage=e.stage
 t.check(t.action(g,"attack",{"type":"kick","form":0,"enemy":e.id}).ok and g.state.posture=="lie" and g._enemy(e.id).intent.delayed,"SIX KICK bound kick interrupts the published action and leaves the player lying down")
 var copy=Save.roundtrip(t,g,"six-bind bound-kick interruption")
 t.check(t.action(g,"end").ok and g.state.order=="last" and g._enemy(e.id).stage==stage+1 and not g.state.logs.filter(func(row):return row.round==g.state.round and row.text.contains("六缚")).is_empty(),"SIX KICK delayed action resumes when the following player turn starts as last order")
 t.check(t.action(copy,"end").ok and Save.same(g.state,copy.state),"SIX KICK restored interruption resumes through the same last-order boundary")
 t.check(g.state.deck.any(func(card):return card.type=="tease") and g.physical_pieces().size()>1,"SIX KICK resumed action actually installs equipment and adds its curse")
 for turn in range(3):
  var before_stage=g._enemy(e.id).stage
  t.check(t.action(g,"end").ok and g.state.phase=="battle" and g._enemy(e.id).stage==before_stage+1,"SIX KICK six-bind cycle keeps advancing after the interrupted action")
 t.check(original.kind=="six_tease" and g._enemy(e.id).constriction==1 and g.validate()=="","SIX KICK resumed cycle applies its later strengthening and leaves a valid snapshot")

static func idle_cycle(t) -> void:
 var g=encounter(43);var e=g.state.enemies[0]
 var kinds=["six_tease","apply","six_tune","six_tease","six_composite","six_tune","six_finale","idle"]
 for cycle in range(3):
  for step in range(kinds.size()):
   e.stage=3+cycle*kinds.size()+step
   var plan=g.EnemyPlans.six_plan(g,e)
   t.check(plan.kind==kinds[step],"SIX IDLE preserves seven actions then rests once each cycle")
   if plan.kind=="six_tune": t.check(plan.grade==(1 if cycle==0 else 2),"SIX IDLE extra turn does not shift first-cycle toy quality")
 e.stage=9;e.intent=g._plan(e)
 t.check(e.intent.kind=="six_finale" and t.action(g,"end").ok,"SIX IDLE finale still executes before the idle turn")
 e=g.state.enemies[0]
 t.check(e.stage==10 and e.intent.kind=="idle","SIX IDLE finale announces a genuine idle turn")
 # Isolate the idle action from passive equipment and held curse effects.
 g=encounter(44);e=g.state.enemies[0];e.stage=10;e.constriction=2;e.intent=g._plan(e)
 var copy=Save.roundtrip(t,g,"six-bind idle turn")
 var before=g.export_snapshot();var end=t.find_action(g,"end")
 t.check(g.dispatch(g.command(end.payload,g.state.version),g.state.version).ok,"SIX IDLE uses the formal enemy turn")
 e=g.state.enemies[0]
 t.check(e.stage==11 and e.intent.kind=="six_tease" and e.constriction==2,"SIX IDLE advances once into the next cycle without gaining constriction")
 t.check(g.state.equipment==before.equipment and g.state.special_equipment==before.special_equipment and g.state.deck==before.deck and g.state.rng.equipment==before.rng.equipment and g.state.rng.enemy==before.rng.enemy,"SIX IDLE neither equips, reinforces, injects cards nor consumes enemy/equipment randomness")
 t.check(g.state.logs.any(func(row):return row.text=="六缚暂不行动。"),"SIX IDLE logs the actual idle outcome")
 t.check(t.action(copy,"end").ok and Save.same(g.state,copy.state),"SIX IDLE restoring the frozen idle turn gives identical results")
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(end.payload,before.version-1),before.version-1).ok and g.export_snapshot()==before,"SIX IDLE stale end-turn cannot advance the cycle twice")
 t.check(t.action(g,"end").ok and g.state.enemies[0].stage==12 and g.state.deck.any(func(card):return card.type=="tease"),"SIX IDLE following turn resumes real equipment and curse actions")
 g=encounter(45);e=g.state.enemies[0];e.stage=10;e.intent=g._plan(e);e.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.enemies[0].stage==10 and g.state.enemies[0].intent.kind=="idle" and not g.state.enemies[0].intent.delayed,"SIX IDLE shared interruption retains the unexecuted idle step")
 t.check(t.action(g,"end").ok and g.state.enemies[0].stage==11,"SIX IDLE delayed idle executes exactly once on the following turn")
 g=encounter(46);e=g.state.enemies[0];e.stage=10;g.state.overload_total=4;e.intent=g._plan(e)
 t.check(e.intent.kind=="capture" and e.intent.cancel_on_interrupt,"SIX IDLE does not suppress priority climax arrest")
 e.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.enemies[0].stage==10 and g.state.enemies[0].intent.kind=="idle","SIX IDLE cancelled climax arrest resumes the original idle step")
