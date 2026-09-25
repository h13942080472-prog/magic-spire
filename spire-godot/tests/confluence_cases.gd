extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")
static func setup():
 var g=Game.new(42);g._discard_end();g.state.mana=40
 for e in g.state.enemies: e.hp=200;e.max_hp=200
 return g
static func run(t) -> void:
 var g=setup();var spec=g.Cards.Rules.SPECS.confluence
 t.check(spec.cost==0 and spec.card_type=="skill" and spec.rarity=="common" and "confluence" in g.Cards.Rules.COMMON and g.Cards.Rules.definition_reason(spec)=="","CONFLUENCE registered zero-energy common skill")
 for count in range(5):
  for free in [false,true]:
   g=setup()
   for slot in g.B.SLOTS.slice(0,count): g.add_fixture(slot,8)
   var card=Give.give(g,"confluence");var c=t.find_action(g,"card",{"uid":card.uid,"free":free});var before=g.export_snapshot()
   var text=g.Cards.face_text(g,"confluence",free)
   t.check(text.contains("每佩戴2件拘束具，本回合获得1点力量，不足2件不计。") if not free else text.contains("每佩戴1件拘束具，恢复2点魔力。"),"CONFLUENCE card always explains the rule, including zero equipment")
   t.check(text.contains("当前：本回合力量＋%d。" % int(count/2)) if not free else text.contains("当前：恢复%d魔力。" % (count*2)),"CONFLUENCE current result supplements the permanent rule")
   t.check(c.valid and c.cost==0 and c.mana==0 and not c.get("casting",{}).get("roll_required",false) and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"CONFLUENCE no casting or energy and stale request rolls back")
   t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.strength==0 and g.state.turn_strength==(int(count/2) if not free else 0) and g.state.mana==40+(0 if not free else count*2) and g.state.energy==before.energy,"CONFLUENCE odd even zero counts grant exact values")
   t.check(g.state.exhaust.any(func(x):return x.uid==card.uid)==free and g.state.discard.any(func(x):return x.uid==card.uid)!=free and text.contains("消耗。")==free,"CONFLUENCE only free face exhausts even with zero gain")
   t.check("magic" not in g.Cards.Rules.type_tags("confluence") and not g.Cards.Rules.face_casts("confluence",free),"CONFLUENCE gains never add magic classification")
 g=setup();g.add_fixture("eyes",8);g._install_assembly("glove","short","fixture",2,1);g._install_special("vaginal_egg_low","special_3_a")
 t.check(g.Cards.worn_count(g)==3 and Give.play(t,g,"confluence",true).ok and g.state.mana==46,"CONFLUENCE composite and special count once")
 g=setup();g.add_fixture("eyes",8);g.add_fixture("ankle",8);var ankle=g.state.equipment.back()
 t.check(Give.play(t,g,"confluence",false).ok and Give.play(t,g,"confluence",false).ok and g.state.turn_strength==2,"CONFLUENCE repeat bound face accumulates frozen strength")
 var c=t.find_action(g,"attack",{"type":"strike"});var enhanced=c.payload.damage
 t.check(g.RelicEffects.attribute(g,"strength")==2,"CONFLUENCE bonus reaches formal strength resolver")
 g._equipment(ankle.id).durability=0;g._cleanup()
 t.check(g.state.turn_strength==2 and g.Cards.worn_count(g)==1 and g.Cards.metadata(g,"confluence").face_mana.free[0].text=="+2" and g.Cards.face_text(g,"confluence",false).contains("力量＋0"),"CONFLUENCE equipment change updates next card values without revoking old strength")
 var copy=Save.roundtrip(t,g,"temporary confluence strength")
 if copy!=null: t.check(copy.state.turn_strength==2 and copy.RelicEffects.attribute(copy,"strength")==2,"CONFLUENCE save preserves temporary strength")
 var before=g.export_snapshot();var bad=before.duplicate(true);bad.turn_strength=-1
 t.check(not g.restore_snapshot(bad).ok and g.state==before,"CONFLUENCE negative temporary strength save rejected atomically")
 for e in g.state.enemies: e.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.turn_strength==0 and g.RelicEffects.attribute(g,"strength")==0 and t.find_action(g,"attack",{"type":"strike"}).payload.damage==enhanced-2,"CONFLUENCE next turn clears only temporary strength and actual attack bonus")
 g=setup();g.add_fixture("eyes",8);g.state.mana=99.5;g.state.temporary_mana=12
 t.check(Give.play(t,g,"confluence",true).ok and g.state.mana==100 and g.state.temporary_mana==12,"CONFLUENCE own mana caps without changing temporary pool")

 var invalid=spec.duplicate(true);invalid.self_faces.free.worn_resource.divisor=0
 t.check(g.Cards.Rules.definition_reason(invalid)!="","CONFLUENCE zero divisor definition is rejected")
 for amount in [0,-1,1.5,"2"]:
  invalid=spec.duplicate(true);invalid.self_faces.free.worn_resource.amount=amount
  t.check(g.Cards.Rules.definition_reason(invalid)!="","CONFLUENCE invalid per-group amount rejected: "+str(amount))
 var catalog=g.B.card_metadata("confluence")
 var descriptions=g.B.card_info("confluence")
 t.check(descriptions[1].contains("每佩戴2件") and descriptions[2].contains("每佩戴1件拘束具，恢复2点魔力。") and descriptions[2].contains("消耗。") and not descriptions[1].contains("消耗。") and not descriptions[1].contains("当前：") and not descriptions[2].contains("当前："),"CONFLUENCE context-free catalog keeps both formulas without inventing a current value")
 t.check(catalog.face_mana.free[0].text=="+X" and catalog.face_mana.bound.is_empty(),"CONFLUENCE standalone catalog explains unknown count without claiming mana on strength face")
