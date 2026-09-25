extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const TYPE="ready_to_strike"

static func run(t) -> void:
 physical_discount(t)
 for free in [false,true]:
  var g=Game.new(42);g._discard_end()
  var source=Cards.give(g,TYPE);var chosen=Cards.give(g,"sensitive");var peer=Cards.give(g,"sensitive")
  g.Cards.grant_buff(g,"echo_cast_bound")
  var c=t.find_action(g,"card",{"uid":source.uid,"free":free,"hand_uid":chosen.uid})
  var before=g.export_snapshot()
  t.check(c.valid and c.cost==1 and c.mana==10 and TYPE in g.Cards.Rules.COMMON and g.Cards.Rules.SPECS[TYPE].casting.parts==["mouth"],"READY common mouth spell selects an exact other physical hand card on either face")
  t.check(g.Cards.Rules.distinct_faces(TYPE) and g.command_facts().filter(func(x):return x.payload.get("uid","")==source.uid).size()==4 and g.state==before,"READY two distinct faces expose two physical targets each without mutation")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"READY stale selection rejects before costs or exhaustion")
  var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
  t.check(result.ok and g.state.energy==2 and g.state.mana==90 and g.state.charge==(0 if free else 3),"READY successful spell pays once and grants the selected face effect")
  t.check(g.state.exhaust.size()==1 and g.state.exhaust[0].uid==chosen.uid and g.state.discard.any(func(card):return card.uid==source.uid) and g.state.hand.any(func(card):return card.uid==peer.uid),"READY consumes selected duplicate only; caster discards and unselected twin stays")
  t.check(g.state.deck.size()==before.deck.size() and ("echo_cast_bound" in g.state.card_buffs)==free and result.card_feedback.filter(func(e):return e.kind=="exhaust" and e.uid==chosen.uid).size()==1,"READY exhaust keeps permanent deck and emits one existing animation while bound replay skips the exhausted target")
  t.check(g.state.logs.any(func(e):return e.data.get("exhausted_card","")==chosen.uid and e.text.contains("敏感")),"READY outcome names the selected card and records its physical identity")
  preload("res://tests/persistence_cases.gd").roundtrip(t,g,"selected hand exhaustion")
 var g=Game.new(42);g._discard_end();var source=Cards.give(g,TYPE)
 var before=g.export_snapshot();var c=t.find_action(g,"card",{"uid":source.uid,"free":false})
 t.check(not c.valid and c.reason.contains("另一张") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"READY cannot consume itself when it is the only hand card")
 var chosen=Cards.give(g,"strain");c=t.find_action(g,"card",{"uid":source.uid,"hand_uid":chosen.uid,"free":false})
 g.state.hand.erase(chosen);g.state.discard.append(chosen);before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"READY target no longer in hand refuses atomically even without version change")
 for free in [false,true]:
  g=Game.new(42);g._discard_end();source=Cards.give(g,TYPE);chosen=Cards.give(g,"strain");g.state.pressure=99
  c=t.find_action(g,"card",{"uid":source.uid,"hand_uid":chosen.uid,"free":free})
  var rng=g.state.rng.magic
  while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,TYPE)).winning_rolls: rng=g.state.rng.magic
  g.state.rng.magic=rng;before=g.export_snapshot()
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and g.state.energy==2 and is_equal_approx(g.state.mana,before.mana-c.mana*0.5),"READY failed cast on either face still pays normal costs")
  t.check(g.state.hand==before.hand and g.state.exhaust==before.exhaust and g.state.charge==0 and "ready_to_strike_free" not in g.state.card_buffs,"READY failed cast leaves both cards in hand and grants neither face effect")
 g=Game.new(42);g._discard_end();source=Cards.give(g,TYPE);chosen=Cards.give(g,"strain");g.state.mana=0;g.state.temporary_mana=10
 t.check(t.action(g,"card",{"uid":source.uid,"hand_uid":chosen.uid,"free":false}).ok and g.state.temporary_mana==0 and g.state.mana==0 and g.state.charge==3,"READY existing temporary mana pays the spell")
 g=Game.new(42);g._discard_end();source=Cards.give(g,TYPE);chosen=Cards.give(g,"strain")
 g._install_template("mouth_band","mouth",24,24,false,"fixture",3,0)
 before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":source.uid,"hand_uid":chosen.uid,"free":true}).ok and g.state==before,"READY blocked mouth casting grants neither exhaustion nor charge")

static func physical_discount(t) -> void:
 for type in ["strike","heavy","kick"]:
  for form in range(preload("res://data/basic_attacks.gd").TYPES[type].size()):
   var g=Game.new(42);g.state.round=2;g._discard_end()
   var source=Cards.give(g,TYPE);var chosen=Cards.give(g,"sensitive")
   t.check(t.action(g,"card",{"uid":source.uid,"hand_uid":chosen.uid,"free":true}).ok and g.state.charge==0,"READY free face grants discount without charge")
   var spec=g.BasicAttacks.TYPES[type][form]
   if spec.get("x_cost",false):
    t.check(t.action(g,"posture",{"dest":"sit","wall":false}).ok,"READY enter the seated X-cost attack through the normal posture action")
   var c=t.find_action(g,"attack",{"type":type,"form":form})
   var before=g.export_snapshot();var expected=g.state.energy if spec.get("x_cost",false) else spec.cost-1
   t.check(c.valid and c.cost==expected and g.state==before,"READY physical preview discounts fixed costs and preserves all-energy X payment without consuming the buff: "+type+str(form))
   t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"READY stale attack preserves discount and resources")
   var hp=g._enemy(c.payload.enemy).hp
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==before.energy-c.cost and g._enemy(c.payload.enemy).hp<hp and "ready_to_strike_free" not in g.state.card_buffs,"READY full physical action pays discounted cost and consumes once: "+type+str(form))
   t.check(t.find_action(g,"attack",{"type":"strike","form":0}).cost==1,"READY subsequent physical action restores full cost")
 var g=Game.new(42);g._discard_end()
 var source=Cards.give(g,TYPE);var chosen=Cards.give(g,"sensitive")
 t.action(g,"card",{"uid":source.uid,"hand_uid":chosen.uid,"free":true})
 var saved=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"next physical attack discount")
 t.check(saved!=null and t.find_action(saved,"attack",{"type":"heavy"}).cost==1,"READY snapshot retains discount through existing buff state")
 var twin=Cards.give(g,TYPE);var peer=Cards.give(g,"slip");var before=g.export_snapshot()
 var duplicate=t.find_action(g,"card",{"uid":twin.uid,"hand_uid":peer.uid,"free":true})
 t.check(not duplicate.valid and not g.dispatch(g.command(duplicate.payload,g.state.version),g.state.version).ok and g.state==before,"READY existing next-attack effect rejects stacking before exhausting another card")
 var fire=t.find_action(g,"attack",{"type":"fireball"})
 t.check(fire.cost==1 and g.dispatch(g.command(fire.payload,g.state.version),g.state.version).ok and "ready_to_strike_free" in g.state.card_buffs,"READY first fireball keeps its one-energy cost and does not consume physical discount")
 t.check(t.action(g,"posture",{"dest":"sit","wall":false}).ok and "ready_to_strike_free" in g.state.card_buffs,"READY posture action preserves discount")
 before=g.export_snapshot()
 t.check(not t.action(g,"attack",{"type":"strike"}).ok and g.state==before,"READY discount does not bypass standing requirement")
 g.state.energy=0
 var kick=t.find_action(g,"attack",{"type":"kick","form":2})
 t.check(kick.valid and kick.cost==0 and g.dispatch(g.command(kick.payload,g.state.version),g.state.version).ok and g.state.energy==0,"READY seated kick works at zero energy without negative cost")
