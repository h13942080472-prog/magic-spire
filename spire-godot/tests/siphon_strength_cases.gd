extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const TYPE="siphon_strength"

static func run(t) -> void:
 for free in [false,true]:
  var g=Game.new(42);g._discard_end();g.state.mana=20
  var source=Cards.give(g,TYPE)
  var removed=[]
  for type in ["strain","strain","sensitive","tease","adaptability"]: removed.append(Cards.give(g,type).uid)
  var kept=[]
  for type in ["ease","wildfire_descent",TYPE]: kept.append(Cards.give(g,type).uid)
  if free:
   var swap=removed;removed=kept;kept=swap
  var c=t.find_action(g,"card",{"uid":source.uid,"free":free})
  var before=g.export_snapshot()
  t.check(c.valid and c.cost==1 and c.mana==0 and g.Cards.Rules.SPECS[TYPE].casting.parts==["hand"] and TYPE in g.Cards.Rules.RARE and TYPE not in g.Cards.Rules.UNCOMMON,"SIPHON STRENGTH rare one-energy hand spell needs no mana")
  t.check(g.Cards.Rules.SPECS[TYPE].rarity=="rare" and preload("res://data/encyclopedia.gd").card(TYPE).rarity=="rare" and g.get_view().hand.filter(func(row):return row.uid==source.uid)[0].rarity=="rare","SIPHON STRENGTH runtime card and encyclopedia share rare rarity")
  t.check(g.command_facts().filter(func(a):return a.payload.get("uid","")==source.uid).size()==2 and not c.payload.has("hand_uid") and g.state==before,"SIPHON STRENGTH one candidate per face with no manual selection")
  t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SIPHON STRENGTH stale play rolls back every zone and resource")
  var result=g.dispatch(g.command(c.payload,g.state.version),g.state.version)
  t.check(result.ok and g.state.energy==2 and g.state.mana==(50 if free else 20) and g.state.charge==(0 if free else 5),"SIPHON STRENGTH free rewards three magic cards; bound rewards five nonmagic cards")
  t.check(g.state.exhaust.map(func(card):return card.uid)==removed and g.state.hand.map(func(card):return card.uid)==kept,"SIPHON STRENGTH opposite filters preserve physical identities and classify dual-tag magic and same-name twin correctly")
  t.check(g.state.discard.any(func(card):return card.uid==source.uid) and g.state.deck==before.deck,"SIPHON STRENGTH caster discards normally and permanent deck stays unchanged")
  t.check(result.card_feedback.filter(func(e):return e.kind=="exhaust").map(func(e):return e.uid)==removed,"SIPHON STRENGTH emits an existing exhaustion animation for every removed card")
  t.check(g.state.logs.any(func(e):return e.data.get("exhausted_cards",[])==removed and e.text.contains("3张魔法牌" if free else "5张非魔法牌")),"SIPHON STRENGTH logs actual type count and physical card identities")
  var after=g.export_snapshot()
  t.check(not g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state==after,"SIPHON STRENGTH repeated submission cannot pay or exhaust twice")
 for free in [false,true]:
  var g=Game.new(42);g._discard_end();var source=Cards.give(g,TYPE);g.state.mana=0
  t.check(t.action(g,"card",{"uid":source.uid,"free":free}).ok and g.state.exhaust.is_empty() and g.state.mana==0 and g.state.charge==0,"SIPHON STRENGTH empty eligible hand permits zero-reward cast at zero mana")
  g=Game.new(42);g._discard_end();source=Cards.give(g,TYPE);Cards.give(g,"ease" if free else "strain");g.state.pressure=99
  var c=t.find_action(g,"card",{"uid":source.uid,"free":free})
  var rng=g.state.rng.magic
  while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,TYPE)).winning_rolls: rng=g.state.rng.magic
  g.state.rng.magic=rng;var before=g.export_snapshot()
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._magic_failed and g.state.energy==before.energy-1,"SIPHON STRENGTH both faces use normal hand pressure casting failure")
  t.check(g.state.hand==before.hand and g.state.exhaust==before.exhaust and g.state.mana==before.mana and g.state.charge==before.charge,"SIPHON STRENGTH failed cast exhausts nothing and grants no reward")
 var g=Game.new(42);g._discard_end();var source=Cards.give(g,TYPE);Cards.give(g,"ease");g.state.mana=98
 t.check(t.action(g,"card",{"uid":source.uid,"free":true}).ok and g.state.mana==100 and g.state.exhaust.size()==1,"SIPHON STRENGTH mana cap never reduces number exhausted")
 g=Game.new(42);g._discard_end();source=Cards.give(g,TYPE);Cards.give(g,"strain")
 var palm=g.add_fixture("palm",2);palm.side="left"
 var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":source.uid,"free":false}).ok and g.state==before,"SIPHON STRENGTH default requires both complete hands")
 g.state.relics.append("casting_manual")
 t.check(t.action(g,"card",{"uid":source.uid,"free":false}).ok and g.state.charge==1,"SIPHON STRENGTH existing casting manual permits one complete free hand")
 var spec=g.Cards.Rules.SPECS[TYPE].duplicate(true);spec.self_faces.free.exhaust_hand_batch.include_type="unknown"
 t.check(g.Cards.Rules.definition_reason(spec)!="","SIPHON STRENGTH invalid batch filter is rejected")
 var info=g.B.card_metadata(TYPE)
 t.check(info.face_effects.free.contains("全部魔法牌") and info.face_effects.bound.contains("全部非魔法牌") and info.face_effects.free.contains("每消耗1张，恢复10魔力") and info.face_effects.bound.contains("每消耗1张，获得1层蓄力") and info.face_mana.free[0].text=="+10×" and info.face_mana.bound.is_empty(),"SIPHON STRENGTH opposite face filters copy and per-card mana badge come from shared configuration")
