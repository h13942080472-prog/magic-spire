extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const TYPE="crossed_legs"

static func isolate(g, card: Dictionary) -> void:
 var others=[]
 for zone in ["draw","hand","discard"]:
  for physical in g.state[zone]:
   if physical.uid!=card.uid: others.append(physical)
 g.state.draw=[]
 g.state.hand=[card]
 g.state.discard=[]
 g.state.exhaust.append_array(others)

static func run(t) -> void:
 for slot in ["thigh","calf","ankle","foot","toes","wrist","upper_arm","eyes"]:
  var fixture=Game.new(42);fixture._discard_end();fixture.state.wall="normal"
  var item=fixture.add_fixture(slot,6);var copy=Cards.give(fixture,TYPE)
  var valid=fixture.command_facts().any(func(action):return action.payload.get("uid")==copy.uid and action.payload.get("target")==item.id and action.valid)
  t.check(valid==(slot in fixture.B.LEG_SLOTS),"CROSS target selection uses actual leg region: "+slot)
  if slot not in fixture.B.LEG_SLOTS:
   var frozen=fixture.export_snapshot()
   t.check(not t.action(fixture,"card",{"uid":copy.uid,"target":item.id}).ok and fixture.state==frozen,"CROSS outside-region rejection preserves card, resources and randomness")
 var g=Game.new(42);g._discard_end();g.state.wall="normal"
 var target=g.add_fixture("ankle",60,100);var card=Cards.give(g,TYPE)
 var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id})
 var before=g.export_snapshot()
 t.check(c.cost==1 and c.payload.mode=="slip" and c.payload.preview.base==8 and TYPE in g.Cards.Rules.COMMON,"CROSS common skill bound face uses eight-base slip and one energy")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.hand.size()==1 and g.state.draw.size()==before.draw.size()-1 and is_equal_approx(g._equipment(target.id).durability,60-c.payload.preview.damage),"CROSS bound face applies ordinary slip formula then draws one")
 t.check(g.state.energy==2 and g.state.discard.any(func(x):return x.uid==card.uid) and g.state.exhaust.is_empty(),"CROSS bound face pays once and normally discards")
 g=Game.new(42);g._discard_end();g.state.wall="normal";target=g.add_fixture("ankle",100,100);card=Cards.give(g,TYPE)
 t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and g._equipment(target.id).durability==100 and g.state.hand.size()==1,"CROSS immune but valid slip still draws one")
 for restricted in [false,true]:
  g=Game.new(42);g._discard_end();g.state.energy=0;g.state.mana=0
  g.add_fixture("thigh",10);g.add_fixture("calf",10)
  if restricted: g.add_fixture("ankle",1)
  card=Cards.give(g,TYPE);c=t.find_action(g,"card",{"uid":card.uid,"free":true})
  before=g.export_snapshot()
  t.check(g.level("legs")== (3 if restricted else 1) and c.cost==0 and c.valid!=restricted,"CROSS zero-cost free face checks aggregate leg level rather than individual tightness")
  if restricted:
   t.check(c.reason.contains("腿部束缚等级≤1") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"CROSS blocked free face explains actual leg level and preserves all state")
  else:
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==0 and g.state.mana==0 and g.state.hand.size()==1 and g.state.draw.size()==before.draw.size()-1,"CROSS level one free face draws at zero energy without refund or mana")
 g=Game.new(42);g._discard_end();card=Cards.give(g,TYPE)
 c=t.find_action(g,"card",{"uid":card.uid,"free":true});g.add_fixture("ankle",1);before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"CROSS commit rechecks changed leg restriction before drawing")
 g=Game.new(42);g._discard_end();target=g.add_fixture("ankle",6);card=Cards.give(g,TYPE);g.state.energy=0;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and g.state==before,"CROSS bound face still needs one energy even when free face is discounted")
 var spec=g.Cards.Rules.SPECS[TYPE].duplicate(true);spec.free_energy_discount=-1
 t.check(g.Cards.Rules.definition_reason(spec)!="","CROSS invalid negative discount rejected")
 spec=g.Cards.Rules.SPECS[TYPE].duplicate(true);spec.free_max_levels={"legs":5}
 t.check(g.Cards.Rules.definition_reason(spec)!="","CROSS invalid region-level boundary rejected")

 # The physical card being resolved is not eligible for its own draw effect.
 g=Game.new(42);g._discard_end();card=Cards.give(g,TYPE);isolate(g,card);g.state.energy=0
 before=g.export_snapshot()
 var result=t.action(g,"card",{"uid":card.uid,"free":true})
 t.check(result.ok and g.state.hand.is_empty() and g.state.draw.is_empty() and g.state.discard.size()==1 and g.state.discard[0].uid==card.uid,"CROSS empty draw and discard cannot draw the card currently being played")
 t.check(result.card_feedback.map(func(event):return event.kind)==["play"] and g.state.exhaust.size()==g.state.deck.size()-1 and g.Cards.validate(g)=="","CROSS empty piles settle the used card only after its draw effect")
 # A different discard can still be shuffled and drawn before the used card arrives.
 g=Game.new(42);g._discard_end();card=Cards.give(g,TYPE);isolate(g,card);g.state.energy=0
 var other=g.state.exhaust.pop_back();g.state.discard.append(other)
 result=t.action(g,"card",{"uid":card.uid,"free":true})
 t.check(result.ok and g.state.hand.size()==1 and g.state.hand[0].uid==other.uid and g.state.discard.size()==1 and g.state.discard[0].uid==card.uid,"CROSS draw reshuffles another discard without recycling the resolving card")
 t.check(result.card_feedback.map(func(event):return event.kind)==["shuffle","draw","play"],"CROSS transfer feedback follows shuffle, draw, then played-card discard order")
