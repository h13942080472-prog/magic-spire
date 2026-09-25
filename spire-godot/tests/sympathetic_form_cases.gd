extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")
const TYPE="sympathetic_form"

static func fresh():
 var g=Game.new(42);g._discard_end();g.state.energy=30;g.state.mana=35;g.state.pressure=20
 return g

static func advance(t,g) -> void:
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok,"SYMPATHETIC real end-turn succeeds")

static func gains(g) -> Array:
 return g.state.logs.filter(func(e):return e.data.get("source","")=="交感形态·自由" and e.data.has("base_gain"))

static func run(t) -> void:
 var g=fresh();var card=Cards.give(g,TYPE)
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true});var before=g.export_snapshot()
 t.check(c.valid and c.cost==3 and c.mana==0 and TYPE in g.Cards.Rules.RARE and g.Cards.Rules.classification(TYPE).rarity=="rare","SYMPATHETIC rare three-energy power has no spell or mana payment")
 g.get_view();g.command_facts()
 t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SYMPATHETIC previews and stale activation are read only")
 g.state.energy=2;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"SYMPATHETIC insufficient energy rejects without power or resource gain")
 g.state.energy=3
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.mana==35 and gains(g).is_empty() and g.state.powers[0].uid==card.uid,"SYMPATHETIC activation waits until next turn")
 advance(t,g)
 t.check(g.state.mana==55 and gains(g).size()==1 and gains(g)[0].data.base_gain==10,"SYMPATHETIC clear body restores twenty mana and gains ten base arousal")
 g.state.mana=95;advance(t,g)
 t.check(g.state.mana==100 and gains(g).size()==2,"SYMPATHETIC full mana cap does not prevent the paired arousal effect")
 for kind in ["ordinary","collar","composite","link","shoulder"]:
  g=fresh()
  if kind=="ordinary": g.add_fixture("eyes",1)
  elif kind=="collar": g._install_template("restriction_collar","neck",1,1,false,"fixture",3)
  elif kind=="composite": g._install_assembly("glove","short","fixture",2,1)
  else:
   var a=g.add_fixture("forearm",4);var b=g.add_fixture("wrist",4)
   if kind=="link": g._install_link(a.id,b.id,4,"fixture",1,[],["forearm","wrist"],["mid_forearm","wrist"])
   else: g._install_template("rope","upper_arm",10,10,false,"fixture",1)
  t.check(Cards.play(t,g,TYPE,true).ok,"SYMPATHETIC free activation is allowed while trigger condition is blocked: "+kind)
  advance(t,g)
  t.check(g.state.mana==35 and gains(g).is_empty(),"SYMPATHETIC non-special root suppresses both turn gains: "+kind)
  for target in g.state.equipment+g.action_targets(): g._apply_manual_release(target,0.0,true)
  g._cleanup();advance(t,g)
  t.check(g.state.mana==55 and gains(g).size()==1,"SYMPATHETIC removing restraints re-enables the next turn trigger: "+kind)
 g=fresh();g._install_special("vaginal_egg_low","special_3_a")
 t.check(Cards.play(t,g,TYPE,true).ok,"SYMPATHETIC special-only activation is legal")
 advance(t,g)
 t.check(g.state.mana==55 and gains(g).size()==1,"SYMPATHETIC special equipment does not block free turn gains")
 g=fresh();g.RelicEffects.gain(g,"marble_stone");Cards.play(t,g,TYPE,true);advance(t,g)
 t.check(gains(g).size()==1 and is_equal_approx(gains(g)[0].data.gain,6),"SYMPATHETIC arousal uses the shared relic multiplier")
 g=fresh();Cards.play(t,g,TYPE,true);Cards.play(t,g,TYPE,true);advance(t,g)
 t.check(g.state.mana==75 and gains(g).size()==2,"SYMPATHETIC duplicate free faces each grant twenty mana and ten base arousal")
 g=fresh();Cards.play(t,g,TYPE,true);g.state.pressure=99
 advance(t,g)
 t.check(g.state.overload_total==1 and g.state.mana==55-g.B.OVERLOAD_MANA and g.state.energy==0 and gains(g).size()==1,"SYMPATHETIC turn arousal enters ordinary climax mana loss and energy reset")
 g=fresh();Cards.play(t,g,TYPE,false);Cards.play(t,g,TYPE,false);Cards.play(t,g,TYPE,true)
 t.check(g.state.temporary_mana==0 and gains(g).is_empty(),"SYMPATHETIC stacked and opposite faces have no immediate grants")
 var twin=Save.roundtrip(t,g,"sympathetic both faces and duplicate stacks")
 advance(t,g)
 t.check(g.state.temporary_mana==20 and g.state.energy==g.max_energy()+2 and g.state.mana==55,"SYMPATHETIC bound stacks add uncapped temporary mana and energy after turn refill")
 if twin!=null:
  advance(t,twin)
  t.check(twin.state.powers==g.state.powers and twin.state.mana==g.state.mana and twin.state.temporary_mana==g.state.temporary_mana and twin.state.pressure==g.state.pressure and twin.state.energy==g.state.energy and twin.state.rng==g.state.rng,"SYMPATHETIC saved powers reproduce real turn effects")
 g.RelicEffects.end_combat(g);var temporary=g.state.temporary_mana
 g.RelicEffects.begin_combat(g);g._begin_player_turn()
 t.check(g.state.powers.is_empty() and g.state.temporary_mana==temporary and gains(g).size()==1,"SYMPATHETIC cleared powers do not trigger in the next encounter")
