extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func fire(t,g) -> Dictionary:
 return t.find_action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})

static func run(t) -> void:
 var g=Game.new(42);g._discard_end()
 var card=Cards.give(g,"fire_control")
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and c.valid and c.cost==1 and c.mana==0,"CONTROL free skill preview is one energy without casting")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"CONTROL stale play rejects without permanent gain")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.energy==2 and g.state.spell_base_bonuses.fireball==1 and g.state.exhaust.any(func(e):return e.uid==card.uid),"CONTROL free face adds permanent damage and exhausts physical card")
 t.check(fire(t,g).payload.damage==g.B.FIREBALL_ASSISTED+1,"CONTROL gesture fireball base gains one")
 card=Cards.give(g,"fire_control")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.spell_base_bonuses.fireball==2,"CONTROL separate copies stack permanent base")
 g.state.card_buffs=["henshin_free"]
 t.check(fire(t,g).payload.damage==(g.B.FIREBALL_ASSISTED+2)*2,"CONTROL adds before global damage multiplier")
 g.Cards.end_powers(g)
 var palm=g.add_fixture("palm",2.0);palm.side="left"
 t.check(not palm.is_empty(),"CONTROL fixture uses existing single-hand test representation")
 t.check(fire(t,g).payload.damage==g.B.FIREBALL+2,"CONTROL no-gesture fireball gains same permanent amount")
 card=Cards.give(g,"fire_control");c=t.find_action(g,"card",{"uid":card.uid,"free":true},false)
 before=g.export_snapshot()
 t.check(not c.valid and c.reason.contains("手掌") and not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==before,"CONTROL one hand with low tightness blocks free face atomically")
 g._equipment(palm.id).durability=0.0000001
 g._cleanup()
 t.check(t.find_action(g,"card",{"uid":card.uid,"free":true}).valid,"CONTROL canonical cleanup releases the hand after floating residue is removed")
 palm=g.add_fixture("palm",2.0);palm.side="left"
 g.state.mana=0.0;g.state.pressure=99.0;g.state.energy=3
 var rng=g.state.rng.magic;var reserve=g.state.temporary_mana
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.temporary_mana==reserve+10 and g.state.rng.magic==rng and g.state.spell_base_bonuses.fireball==2,"CONTROL bound face grants two reserves without mana or spell roll")
 g.RelicEffects.end_combat(g)
 t.check(g.state.spell_base_bonuses.fireball==2,"CONTROL permanent gain survives scene cleanup")
 g.state.phase="battle";g.RelicEffects.begin_combat(g)
 t.check(g.state.spell_base_bonuses.fireball==2 and g.validate()=="","CONTROL next battle preserves permanent gain")
 var twin=Game.new(42)
 t.check(twin.restore_snapshot(g.export_snapshot()).ok and twin.state.spell_base_bonuses.fireball==2,"CONTROL current-format snapshot preserves permanent gain")
 t.check(Game.new(42).state.spell_base_bonuses.is_empty(),"CONTROL new run starts with no permanent bonus")
 for slot in ["eyes","mouth","upper_arm","forearm","wrist","fingers","thigh"]:
  g=Game.new(42);g._discard_end();g.add_fixture(slot,2.0)
  card=Cards.give(g,"fire_control")
  c=t.find_action(g,"card",{"uid":card.uid,"free":true},false)
  t.check(c.valid==(slot not in ["wrist","fingers"]),"CONTROL free-side exact body region: "+slot)
 g.state.energy=0;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"CONTROL insufficient energy preserves card and bonus")
 revised_conditions(t)
 bound_reuse(t)

static func bound_reuse(t) -> void:
 var g=Game.new(42);g._discard_end()
 g.state.exhaust.append_array(g.state.draw);g.state.exhaust.append_array(g.state.discard)
 g.state.draw.clear();g.state.discard.clear()
 var rules=g.Cards.Rules
 t.check(rules.SPECS.fire_control.rarity=="uncommon" and "fire_control" in rules.UNCOMMON and "fire_control" not in rules.COMMON and "fire_control" not in rules.RARE,"CONTROL rarity and acquisition pools agree")
 var book=preload("res://data/encyclopedia.gd").card("fire_control")
 t.check(book.rarity=="uncommon" and not book.face_keywords.bound.any(func(term):return term.name=="消耗") and book.face_keywords.free.any(func(term):return term.name=="消耗"),"CONTROL encyclopedia only marks free face as exhaust")
 var card=Cards.give(g,"fire_control")
 for play in range(2):
  t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.discard.any(func(c):return c.uid==card.uid) and not g.state.exhaust.any(func(c):return c.uid==card.uid),"CONTROL bound play discards the same physical card")
  g._draw(1)
  t.check(g.state.hand.size()==1 and g.state.hand[0].uid==card.uid,"CONTROL bound card reshuffles and can be drawn again")
 t.check(g.state.temporary_mana==20 and g.state.spell_base_bonuses.get("fireball",0)==0,"CONTROL repeated bound plays keep two reserves each without permanent damage")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.spell_base_bonuses.fireball==1 and g.state.exhaust.any(func(c):return c.uid==card.uid),"CONTROL reused card still exhausts when played free")

static func revised_conditions(t) -> void:
 var g=Game.new(42);g._discard_end();g.state.pressure=90
 g.add_fixture("upper_arm",2);g.add_fixture("forearm",2)
 var card=Cards.give(g,"fire_control")
 var c=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var before=g.export_snapshot()
 t.check(g.restraint_degree("arms")==1 and c.valid and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.spell_base_bonuses.fireball==1 and g.state.rng.magic==before.rng.magic and g.state.mana==before.mana,"CONTROL upper total exactly one permits permanent one without a spell roll at high pressure")
 g=Game.new(42);g._discard_end()
 var left=g.add_fixture("palm",2);left.side="left"
 card=Cards.give(g,"fire_control")
 t.check(g.level("arms")==1 and not t.find_action(g,"card",{"uid":card.uid,"free":true}).valid,"CONTROL upper limit alone cannot replace hand freedom")
 g.state.relics.append("casting_manual")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.spell_base_bonuses.fireball==1,"CONTROL existing casting manual allows one completely free hand")
 var right=g.add_fixture("fingers",2);right.side="right";card=Cards.give(g,"fire_control")
 t.check(not t.find_action(g,"card",{"uid":card.uid,"free":true}).valid,"CONTROL palm on one hand and fingers on the other leave no whole free hand")
 var spec=g.Cards.Rules.SPECS.fire_control.duplicate(true)
 g.Cards.Rules.SPECS.fire_control.self_faces.free.spell_base_bonus.amount=3
 t.check(g.B.card_info("fire_control")[2].contains("永久＋3"),"CONTROL printed permanent increment follows shared rule data")
 g.Cards.Rules.SPECS.fire_control=spec
 spec=spec.duplicate(true);spec.self_faces.free.requires_hand="yes"
 t.check(g.Cards.Rules.definition_reason(spec)!="","CONTROL rejects malformed hand condition")
