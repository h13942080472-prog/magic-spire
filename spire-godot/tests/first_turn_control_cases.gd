extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func next(g) -> Dictionary:
 var choices=g.command_facts().filter(func(c):return c.get("automated",false))
 return choices[0] if not choices.is_empty() else {}

static func enter(t, phase: String, mode: int=0, character: String="original"):
 var g=Game.new(42,phase=="prison","prison_test" if phase=="prison" else "equipment",true,false,25,false,false,character)
 g.RelicEffects.gain(g,"doubao")
 if mode==1: g.state.relic_counters.doubao=mode
 match phase:
  "battle": g._start_battle()
  "prepare": g._start_preparation()
  "rest": g._start_rest();t.action(g,"rest_begin")
  "prison": g.Prison.enter(g)
 return g

static func run(t) -> void:
 for phase in ["battle","prepare","rest","prison"]:
  for character in ["original","witch"]:
   var g=enter(t,phase,1,character)
   t.check(not g.FirstTurnControl.active(g) and g.state.energy==0 and g.max_energy()==4,"CONTROL DeepSeek drains opening energy without taking control: "+phase+character)
   var frozen=g.export_snapshot()
   t.check(not t.action(g,"relic_toggle",{"relic":"doubao"}).ok and g.state==frozen,"CONTROL combat-like phases still reject toggles atomically: "+phase)
   var tick=g.state.tick
   t.check(next(g).is_empty() and not g.get_view().first_turn_control.locked,"CONTROL DeepSeek never supplies an automatic command")
   var before=g.export_snapshot();g.get_view();g.command_facts()
   t.check(g.state==before,"CONTROL queries do not consume resources")
   var restored=Game.new(9)
   t.check(restored.restore_snapshot(before).ok and restored.state.energy==0 and next(restored).is_empty(),"CONTROL zero-energy first turn survives restore without skipping")
   # The drain is a turn-start event, not a continuing energy cap.
   g.state.energy=2;g.FirstTurnControl.begin_turn(g)
   t.check(g.state.energy==2,"CONTROL gaining energy after opening remains usable")
   for enemy in g.state.enemies: enemy.intent.delayed=true
   t.check(t.action(g,"end").ok and g.state.tick>tick and g.state.energy>0 and g.get_view().first_turn_control.is_empty(),"CONTROL manual end advances normally and next turn restores energy: "+phase)
 var g=enter(t,"battle",1)
 g.RelicEffects.gain(g,"ice_heart");g.state.pressure=30
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.logs.any(func(log):return log.text.contains("冰心诀：回合结束")),"CONTROL manual DeepSeek turn retains normal end effects")
 g._finish_battle()
 t.check(t.action(g,"relic_toggle",{"relic":"doubao"}).ok and g.FirstTurnControl.mode(g).name=="豆包","CONTROL noncombat reward screen permits switching back")
 t.check(t.action(g,"relic_toggle",{"relic":"doubao"}).ok and g.FirstTurnControl.mode(g).name=="DeepSeek","CONTROL noncombat switch is bidirectional")
 g=enter(t,"battle",1)
 var original=g.export_snapshot()
 t.check(not t.action(g,"relic_toggle",{"relic":"doubao"}).ok and g.state==original and next(g).is_empty(),"CONTROL rejected switch cannot start automation")
 t.check(g.get_view().relics.filter(func(r):return r.id=="doubao")[0].icon=="deepseek" and g.max_energy()==4,"CONTROL rejected switch retains one relic and one energy modifier")
 var c={}
 for value in [-1,2,"1"]:
  var before=g.export_snapshot();var bad=before.duplicate(true);bad.relic_counters.doubao=value
  t.check(not g.restore_snapshot(bad).ok and g.state==before,"CONTROL malformed mode cannot enter a live game")
 for change in [{"mode":2},{"mode":1,"stage":0},{"mode":1,"stage":5},{"stage":7},{"remaining":4},{"cursor":-1},{"seen":["battle","battle"]},{"phase":"shop"},{"attempted":["a","a"]},{"tick":-1}]:
  var before=g.export_snapshot();var bad=before.duplicate(true);bad.combat.first_turn_control.merge(change,true)
  t.check(not g.restore_snapshot(bad).ok and g.state==before,"CONTROL malformed progress is rejected atomically")
 for posture in ["stand","sit","lie"]:
  g=Game.new(42);g.RelicEffects.gain(g,"masochist_mark");g.state.posture=posture;g._start_round()
  t.check(g.state.order=="last" and g.max_energy()==4,"CONTROL mark forces last initiative independent of posture: "+posture)
  g.state.posture="stand"
  t.check(g.state.order=="last","CONTROL midturn posture cannot change frozen initiative")
 g=Game.new(42);g.state.posture="stand";g._start_round()
 t.check(g.state.order=="first","CONTROL absent mark preserves ordinary initiative")
 for character in ["original","witch"]:
  var practice=Game.new(42,true,"doubao",true,false,25,false,false,character)
  t.check(practice.validate()=="" and practice.state.phase=="battle" and practice.FirstTurnControl.active(practice) and practice.max_energy()==4,"CONTROL declared practice initializes regular battle for "+character)
  t.check(practice.state.relics.count("doubao")==1 and practice.state.energy==4,"CONTROL practice supplies one relic without artificial energy boost")
 sequence(t)
 drawing(t)
 interruptions(t)

static func sequence(t) -> void:
 var g=enter(t,"battle")
 g.state.energy=30
 for enemy in g.state.enemies: enemy.hp=999;enemy.max_hp=999
 var stages=[];var basics=0;var tick=g.state.tick;var steps=0
 while g.FirstTurnControl.active(g) and steps<60:
  var c=next(g)
  if c.is_empty(): t.check(false,"CONTROL active phase always provides a next command");break
  var kind=c.payload.kind
  var stage={"posture":0,"wall_move":1,"attack":2,"card":3,"chain":3,"retain":3,"retain_skip":3,"flask":4,"end":5,"relic_control_done":5}.get(kind,-1)
  t.check(stage>=0 and (stages.is_empty() or stage>=stages.back()),"CONTROL committed actions preserve user sequence: "+kind)
  stages.append(stage)
  if kind=="attack": basics+=1
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"CONTROL each autonomous step uses a legal paid command: "+kind)
  steps+=1
 t.check(steps<60 and basics in [1,2] and 3 in stages and stages.back()==5 and g.state.tick==tick+1,"CONTROL finite first turn performs mandatory basics and cards before end")
 t.check(not g.get_view().has("control_next") and g.FirstTurnControl.validate(g)=="","CONTROL settled state validates")
 g._finish_battle();t.action(g,"reward",{"type":"skip"})
 t.check(g.state.phase=="prepare" and not g.FirstTurnControl.active(g) and next(g).is_empty() and g.get_view().first_turn_control.is_empty(),"CONTROL postbattle preparation returns control to player in shared session")
 t.check(t.find_action(g,"end").valid and g.state.energy>0,"CONTROL preparation retains normal energy and manual end")
 for character in ["original","witch"]:
  g=enter(t,"prepare",0,character)
  t.check(not g.FirstTurnControl.active(g) and next(g).is_empty() and g.state.energy>0,"CONTROL Doubao never opens preparation takeover: "+character)
  var old=g.export_snapshot()
  old.combat.first_turn_control={"seen":["prepare"],"phase":"prepare","tick":g.state.tick,"mode":0,"stage":0,"remaining":-1,"cursor":0,"attempted":[]}
  t.check(g.restore_snapshot(old).ok and not g.FirstTurnControl.active(g) and g.get_view().first_turn_control.is_empty() and t.find_action(g,"end").valid,"CONTROL old preparation progress restores without locking input")
 for phase in ["battle","rest","prison"]:
  g=enter(t,phase)
  t.check(g.FirstTurnControl.active(g) and not next(g).is_empty(),"CONTROL Doubao retains takeover in eligible phase: "+phase)

static func drawing(t) -> void:
 var g=enter(t,"battle")
 g._discard_end();g.state.energy=4
 var draw=Cards.give(g,"pot_of_greed");var follow=Cards.give(g,"strain")
 g.state.hand.erase(follow);g.state.draw.append(follow)
 # Start at the card stage to isolate redraw and failed-card identity from random basic actions.
 g.state.combat.first_turn_control.stage=3
 var c=next(g)
 t.check(c.payload.get("uid","")==draw.uid,"CONTROL card phase begins with leftmost playable card")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.hand.any(func(card):return card.uid==follow.uid),"CONTROL draw action introduces a fresh hand card")
 var played=false
 for i in range(15):
  c=next(g)
  if c.is_empty() or c.payload.kind!="card": break
  if c.payload.uid==follow.uid: played=true
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"CONTROL newly drawn card commits")
 t.check(played,"CONTROL newly drawn cards are included before flask/end")
 g=enter(t,"battle");g.state.energy=0;g.state.combat.first_turn_control.stage=3
 t.check(next(g).payload.kind in ["flask","end"],"CONTROL zero energy stops even zero-cost cards")

static func interruptions(t) -> void:
 var g=enter(t,"battle",0,"witch")
 g.Cards.grant_buff(g,"witch_authority_lock");g.state.combat.first_turn_control.stage=5
 var c=next(g);var tick=g.state.tick
 t.check(c.payload.kind=="relic_control_done" and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"CONTROL forbidden end returns control instead of auto-surrender or bypass")
 t.check(g.state.tick==tick and not g.FirstTurnControl.active(g) and not t.find_action(g,"end").valid,"CONTROL forbidden-end card restriction survives takeover completion")
 g=enter(t,"battle")
 g.state.combat.first_turn_control.stage=2;g.state.combat.first_turn_control.remaining=2;g.state.energy=30
 for enemy in g.state.enemies: enemy.hp=1.0
 for i in range(4):
  c=next(g)
  if c.is_empty(): break
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"CONTROL lethal basic action commits through normal combat")
 t.check(g.state.phase=="reward" and not g.FirstTurnControl.active(g) and next(g).is_empty(),"CONTROL victory interrupts automation and never claims rewards")
 for value in [null,{},"invalid"]:
  var before=g.export_snapshot();var bad=before.duplicate(true);bad.combat.first_turn_control=value
  t.check(not g.restore_snapshot(bad).ok and g.state==before,"CONTROL malformed record shape is rejected before querying")
 var seen_skip=false;var seen_posture=false;var seen_zero_flask=false;var seen_flask=false
 var basic_types={};var legal_basics=true;var stable_preview=true
 for seed_value in range(16):
  g=enter(t,"battle");g.state.seed=seed_value
  c=next(g)
  seen_posture=seen_posture or c.payload.kind=="posture"
  seen_skip=seen_skip or c.payload.kind!="posture"
  g.state.combat.first_turn_control.stage=2
  var before_pick=g.export_snapshot()
  c=next(g)
  legal_basics=legal_basics and c.valid and c.payload.kind=="attack"
  basic_types[c.payload.get("type","")]=true
  stable_preview=stable_preview and next(g)==c and g.state==before_pick
  g.state.combat.first_turn_control.stage=4;g.state.mana=50;g.state.flask_mana=50
  c=next(g)
  seen_zero_flask=seen_zero_flask or c.payload.kind=="end"
  seen_flask=seen_flask or c.payload.kind=="flask"
 t.check(seen_skip and seen_posture and seen_zero_flask and seen_flask,"CONTROL optional posture and flask stages include both act and do-nothing outcomes")
 t.check(legal_basics and basic_types.size()>1 and stable_preview,"CONTROL seeds select different legal basic actions without advancing random state on preview")
 g=enter(t,"battle");g.state.combat.first_turn_control.stage=4;g.state.combat.first_turn_control.remaining=3
 g.state.flask_deposits=3;g.state.combat.flask_withdrawals=3;g.state.mana=50;g.state.flask_mana=50
 t.check(next(g).payload.kind=="end","CONTROL exhausted flask quotas cannot be bypassed by automatic actions")
 g=enter(t,"battle");g.state.combat.first_turn_control.stage=2;g.state.item_drop_chance=1
 c=next(g);var original=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==original,"CONTROL aggregate validation rollback restores paid resources and random progress together")
 g=Game.new(42,true,"pressure_battle")
 g.RelicEffects.gain(g,"masochist_mark");g.RelicEffects.gain(g,"doubao");g.state.pressure=70;g.state.posture="stand"
 g._start_round();c=next(g)
 t.check(g.state.order=="last" and g.state.overloaded and g.state.enemies.all(func(e):return e.stage==2) and c.payload.kind=="end","CONTROL mark forces enemy-first interruption before Doubao can choose basic actions")
 var round_number=g.state.round
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.round==round_number+1 and not g.FirstTurnControl.active(g) and g.state.enemies.all(func(e):return e.stage==3),"CONTROL enemy-first interruption continues normally without repeating old enemy turn or takeover")
