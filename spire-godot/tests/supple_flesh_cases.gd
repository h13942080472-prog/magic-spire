extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const Type="supple_flesh"

static func fresh():
 var g=preload("res://tests/confluence_cases.gd").setup();g.state.relics=[]
 return g

static func run(t) -> void:
 var g=fresh();var rules=g.Cards.Rules
 t.check(Type in rules.UNCOMMON and rules.SPECS[Type].rarity=="uncommon" and rules.definition_reason(rules.SPECS[Type])=="","SUPPLE uncommon zero-cost skill is a valid normal reward")
 for free in [false,true]:
  g=fresh();g.state.energy=0
  var card=Give.give(g,Type);var c=t.find_action(g,"card",{"uid":card.uid,"free":free});var before=g.export_snapshot()
  t.check(c.valid and c.cost==0 and c.mana==0 and not rules.face_casts(Type,free) and not rules.exhausts(Type,free,g.B.CARD_TRAITS.get(Type,{})) and not rules.unique_face(Type,free),"SUPPLE both faces cost no resources and are repeatable non-exhausting skills")
  g.get_view();g.command_facts()
  t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SUPPLE queries and stale requests grant no attributes")
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.RelicEffects.attribute(g,"strength")== (2 if free else 0) and g.RelicEffects.attribute(g,"dexterity")== (0 if free else 4) and g.state.energy==0 and g.state.mana==before.mana and g.state.rng.magic==before.rng.magic and g.state.discard.any(func(item):return item.uid==card.uid),"SUPPLE zero-energy play grants the correct temporary attribute and discards")
  t.check(Give.play(t,g,Type,free).ok and g.RelicEffects.attribute(g,"strength")== (4 if free else 0) and g.RelicEffects.attribute(g,"dexterity")== (0 if free else 8),"SUPPLE repeated same-face cards stack the exact attribute")
  var id="supple_flesh_free" if free else "supple_flesh_bound"
  var status=g.get_view().statuses.filter(func(row):return row.id=="power_"+id)[0]
  t.check(status.value==("力量＋4" if free else "灵巧＋8") and status.duration=="本回合结束" and status.badge=="2","SUPPLE status shows stacked value and turn expiry")
  var restored=Game.new(42)
  t.check(restored.restore_snapshot(g.export_snapshot()).ok and restored.Cards.buff_stacks(restored,id)==2 and restored.RelicEffects.attribute(restored,"dexterity" if not free else "strength")== (8 if not free else 4),"SUPPLE existing buff snapshot preserves stack count and effect")
  var bad=g.export_snapshot();bad.card_buff_uses.erase(id);var current=g.export_snapshot()
  t.check(not g.restore_snapshot(bad).ok and g.state==current,"SUPPLE missing persisted stack count is rejected atomically")
  for enemy in g.state.enemies: enemy.intent.delayed=true
  t.check(t.action(g,"end").ok and g.RelicEffects.attribute(g,"strength")==0 and g.RelicEffects.attribute(g,"dexterity")==0 and not g.state.card_buff_uses.has(id),"SUPPLE actual turn end clears both attribute and count")
 g=fresh();g.state.energy=20;g.state.strength=1;g.state.dexterity=2;g.state.turn_strength=3
 t.check(Give.play(t,g,Type,false).ok and Give.play(t,g,Type,true).ok and g.RelicEffects.attribute(g,"strength")==6 and g.RelicEffects.attribute(g,"dexterity")==6,"SUPPLE faces coexist and add to existing permanent and temporary attributes")
 var enemy_id=g.state.enemies[0].id;var old_hp=g._enemy(enemy_id).hp
 var strike=t.find_action(g,"attack",{"type":"strike","form":0,"enemy":enemy_id})
 t.check(strike.payload.damage==14 and g.dispatch(g.command(strike.payload,g.state.version),g.state.version).ok and g._enemy(enemy_id).hp==old_hp-14 and g.Cards.buff_stacks(g,"supple_flesh_free")==1,"SUPPLE strength reaches real martial preview and damage without consuming the turn buff")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.RelicEffects.attribute(g,"strength")==1 and g.RelicEffects.attribute(g,"dexterity")==2,"SUPPLE expiry preserves permanent stats and removes earlier temporary strength too")
 g=fresh();var target=g._install_template("rope","ankle",16,20,false,"fixture",3);var card=Give.give(g,"slip")
 var before=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false}).payload.preview.damage
 Give.play(t,g,Type,false)
 var slip=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false});var damage=slip.payload.preview.damage
 t.check(slip.valid and damage>before and g.dispatch(g.command(slip.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(target.id).durability,16-damage) and g.RelicEffects.attribute(g,"dexterity")==4,"SUPPLE dexterity increases real slip preview and damage without consuming stacks: "+str([slip.valid,slip.reason,before,damage]))
 g=fresh();g.Cards.grant_buff(g,"echo_cast_bound")
 t.check(Give.play(t,g,Type,false).ok and g.RelicEffects.attribute(g,"dexterity")==8 and g.state.discard.size()>0,"SUPPLE bound replay stacks dexterity through the original buff grant")
 g=Game.new(42,true,"pressure");g.state.pressure_sources=[];g.state.pressure=0
 t.check(Give.play(t,g,Type,false).ok,"SUPPLE bound face works during rest")
 var free_card=Give.give(g,Type);var before_free=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":free_card.uid,"free":true}).ok and g.state==before_free,"SUPPLE ordinary free face obeys the existing rest ban")
 g=fresh();g._start_preparation();Give.play(t,g,Type,false);Give.play(t,g,Type,true)
 t.check(t.action(g,"finish_prepare").ok and g.RelicEffects.attribute(g,"strength")==0 and g.RelicEffects.attribute(g,"dexterity")==0 and g.validate()=="","SUPPLE skipping remaining preparation clears turn buffs with their counters")
