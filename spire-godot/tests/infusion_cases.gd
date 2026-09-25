extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")

static func setup():
 var g=Game.new(42);g._discard_end();g.state.energy=12
 for enemy in g.state.enemies: enemy.hp=200;enemy.max_hp=200
 return g

static func cast(t,g,free: bool) -> Dictionary:
 var card=Give.give(g,"infusion")
 return t.action(g,"card",{"uid":card.uid,"free":free})

static func attack(t,g,type: String,form: int=0) -> Dictionary:
 return t.find_action(g,"attack",{"type":type,"form":form,"enemy":g.state.enemies[0].id})

static func run(t) -> void:
 for free in [false,true]:
  var g=setup();var card=Give.give(g,"infusion")
  g.add_fixture("mouth",4);g.add_fixture("palm",4);g.add_fixture("fingers",4)
  var c=t.find_action(g,"card",{"uid":card.uid,"free":free});var before=g.export_snapshot()
  var buff="infusion_free" if free else "infusion_bound"
  t.check(c.valid and c.cost==(1 if free else 2) and c.mana==(20 if free else 10) and g.Cards.Rules.SPECS.infusion.casting.parts==["none"] and "infusion" in g.Cards.Rules.RARE,"INFUSION rare faces use their own prices and no body casting requirement")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"INFUSION stale cast is atomic")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and buff in g.state.card_buffs and g.state.energy==before.energy-c.cost and g.state.mana==before.mana-c.mana and g.state.discard.any(func(x):return x.uid==card.uid),"INFUSION successful cast pays once grants its pending effect and discards normally")
  var duplicate=Give.give(g,"infusion");before=g.export_snapshot()
  t.check(not t.action(g,"card",{"uid":duplicate.uid,"free":free}).ok and g.state==before,"INFUSION same face cannot stack or consume a duplicate card")
  var restored=Game.new(8)
  t.check(restored.restore_snapshot(before).ok and buff in restored.state.card_buffs and restored.get_view().statuses.any(func(s):return s.id=="power_"+buff and s.value=="打断1层"),"INFUSION save and status preserve the typed pending interrupt")
  g=setup();g.state.pressure=80;g.state.rng.magic=0
  card=Give.give(g,"infusion");before=g.export_snapshot()
  t.check(t.action(g,"card",{"uid":card.uid,"free":free}).ok and buff not in g.state.card_buffs and g.state.hand.any(func(x):return x.uid==card.uid) and g.state.mana<before.mana,"INFUSION no body requirement still uses the existing pleasure cast chance")
 for free in [false,true]:
  for type in ["strike","heavy","kick","fireball"]:
   var g=setup();t.check(cast(t,g,free).ok,"INFUSION grant via formal card action")
   var c=attack(t,g,type);var before=g.export_snapshot()
   var matches=type in (["strike","heavy"] if free else ["heavy","kick"])
   t.check(c.valid and c.payload.interrupt==matches and g.state==before,"INFUSION attack family preview matches the required limbs: "+str(free)+type)
   var buff="infusion_free" if free else "infusion_bound"
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and (buff in g.state.card_buffs)==not matches and g.state.enemies[0].intent.delayed==matches,"INFUSION only the next matching physical attack consumes and interrupts: "+str(free)+type)
 var g=setup();t.check(cast(t,g,true).ok and cast(t,g,false).ok,"INFUSION distinct limb preparations coexist")
 var before=g.export_snapshot();var c=attack(t,g,"heavy",1)
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.enemies[0].hp==before.enemies[0].hp-18 and g.state.card_buffs.is_empty(),"INFUSION multi-hit short strike uses both matching preparations once")
 t.check(g.state.logs.slice(before.logs.size()).filter(func(log):return log.data.has("interrupt")).size()==1,"INFUSION multi-hit emits only one interruption")
 g=setup();g.add_fixture("ankle",4);t.check(cast(t,g,false).ok,"INFUSION leg preparation casts while bound")
 c=attack(t,g,"kick");before=g.export_snapshot()
 t.check(c.payload.interrupt and c.payload.fall and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and "infusion_bound" not in g.state.card_buffs and g.state.logs.slice(before.logs.size()).filter(func(log):return log.data.has("interrupt")).size()==1,"INFUSION innate interrupt consumes the preparation but never doubles delay")
 g=setup();t.check(cast(t,g,false).ok,"INFUSION prepare area attack")
 c=attack(t,g,"kick",1)
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.enemies.all(func(e):return e.intent.delayed) and "infusion_bound" not in g.state.card_buffs,"INFUSION sweep interrupts each living target and consumes once")
 g=setup();cast(t,g,true);g.state.energy=0;c=attack(t,g,"strike");before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"INFUSION invalid physical attack preserves the preparation")
 g=setup();cast(t,g,true);g.state.enemies[0].hp=1;c=attack(t,g,"strike");before=g.export_snapshot()
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and "infusion_free" not in g.state.card_buffs and g.state.logs.slice(before.logs.size()).all(func(log):return not log.data.has("interrupt")),"INFUSION lethal attack consumes its preparation without delaying a defeated enemy")
