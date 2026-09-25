extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const TYPE="breath_control"

static func run(t) -> void:
 for free in [false,true]:
  var g=Game.new(42);g._discard_end();g.state.wall_distance=1
  var target=g.add_fixture("wrist",70,100)
  var source=Give.give(g,TYPE);var chosen=Give.give(g,"sensitive");var peer=Give.give(g,"sensitive")
  g.state.mana=0;g.state.pressure=99
  var c=t.find_action(g,"card",{"uid":source.uid,"free":free,"hand_uid":chosen.uid})
  var before=g.export_snapshot();var spec=g.Cards.Rules.SPECS[TYPE]
  t.check(c.valid and c.cost==2 and c.mana==0 and not g.Cards.uses_magic(c.payload) and spec.rarity=="common" and TYPE in g.Cards.Rules.COMMON and g.Cards.Rules.definition_reason(spec)=="","BREATH ordinary two-energy skill has no mana cost or cast roll on either face")
  t.check(g.B.card_info(TYPE)[1]=="滑脱8×2。选择并消耗1张手牌。" and not spec.get("follow_through",false),"BREATH printed damage is eight twice without follow-through")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"BREATH stale choice rejects both targets atomically")
  var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
  t.check(result.ok and g.state.energy==1 and g.state.mana==0 and g.state.rng.magic==before.rng.magic,"BREATH pays once without rolling even at high pleasure")
  t.check(g.state.exhaust.size()==1 and g.state.exhaust[0].uid==chosen.uid and g.state.hand.any(func(x):return x.uid==peer.uid) and g.state.discard.any(func(x):return x.uid==source.uid) and g.state.deck==before.deck,"BREATH exact other card exhausts, source discards, duplicate and permanent deck remain")
  t.check(result.card_feedback.filter(func(e):return e.kind=="exhaust" and e.uid==chosen.uid).size()==1 and g.state.card_chain.is_empty(),"BREATH all hits complete with one exhaustion animation and no extra cost")
  if free:
   t.check(g.state.charge==1 and g._equipment(target.id).durability==70 and t.find_action(g,"attack",{"type":"heavy","form":0}).cost==1,"BREATH free grants one charge and next physical discount without touching equipment")
  else:
   var hits=g.state.logs.filter(func(e):return e.kind=="mechanical" and e.text.begins_with("「运气」处理"))
   t.check(hits.size()==2 and hits.all(func(e):return e.data.base==8) and g._equipment(target.id).durability<70 and g.state.charge==0,"BREATH bound applies two actual eight-base slips using current target multipliers")
 for tightness in [1.0,4.0,8.0,10.0]:
  var g=Game.new(42);g._discard_end();g.add_fixture("mouth",tightness)
  var source=Give.give(g,TYPE);var chosen=Give.give(g,"strain")
  var c=t.find_action(g,"card",{"uid":source.uid,"free":true,"hand_uid":chosen.uid});var before=g.export_snapshot()
  t.check(not c.valid and c.reason.contains("口部无拘束") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"BREATH every positive mouth tier blocks free face without spending or exhausting")
 var g=Game.new(42);g._discard_end();var source=Give.give(g,TYPE)
 var c=t.find_action(g,"card",{"uid":source.uid,"free":true});var before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("另一张") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"BREATH source cannot exhaust itself when alone")
 var chosen=Give.give(g,"strain");c=t.find_action(g,"card",{"uid":source.uid,"free":true,"hand_uid":chosen.uid})
 g.state.hand.erase(chosen);g.state.discard.append(chosen);before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"BREATH removed selected card rejects without charge, discount or payment")
 for replay in [false,true]:
  g=Game.new(42);g._discard_end();g.state.wall_distance=1
  g.add_fixture("mouth",10);var target=g.add_fixture("wrist",700,1000)
  source=Give.give(g,TYPE);chosen=Give.give(g,"sensitive")
  if replay: g.Cards.grant_buff(g,"echo_cast_bound")
  t.check(t.action(g,"card",{"uid":source.uid,"free":false,"target":target.id,"hand_uid":chosen.uid}).ok,"BREATH bound needs no free mouth")
  var hits=g.state.logs.filter(func(e):return e.kind=="mechanical" and e.text.begins_with("「运气」处理"))
  t.check(hits.size()==(4 if replay else 2) and g.state.exhaust.size()==1 and g.state.energy==1,"BREATH continuation and replay never pay or exhaust again")
 g=Game.new(42);g._discard_end();source=Give.give(g,TYPE);chosen=Give.give(g,"sensitive")
 t.action(g,"card",{"uid":source.uid,"free":true,"hand_uid":chosen.uid})
 before=g.export_snapshot();c=t.find_action(g,"attack",{"type":"strike","form":0})
 var hp=g._enemy(c.payload.enemy).hp
 t.check(c.cost==0 and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"BREATH discounted attack still revalidates version")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==1 and g.state.charge==0 and g._enemy(c.payload.enemy).hp<hp and "breath_control_free" not in g.state.card_buffs and t.find_action(g,"attack",{"type":"strike","form":0}).cost==1,"BREATH next physical attack consumes charge and discount once, following cost restored")
