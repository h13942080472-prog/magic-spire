extends RefCounted

const Give=preload("res://tests/curse_cases.gd")
const Setup=preload("res://tests/confluence_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func fresh():
 var g=Setup.setup()
 g.state.energy=30
 return g

static func run(t) -> void:
 wave(t)
 slippery(t)
 martial(t)
 chant(t)
 chant_outside_battle(t)
 study(t)

static func wave(t) -> void:
 var g=fresh()
 var thigh=g.add_fixture("thigh",8.0)
 var toy=g._install_special("vaginal_egg_low","special_3_a",2)
 var spell=Give.give(g,"shockwave")
 var attack=g.escape_preview(thigh,"strain",4).damage
 var slip=g.escape_preview(thigh,"slip",4).damage
 var fact=t.find_action(g,"card",{"uid":spell.uid,"free":false})
 t.check(fact.valid and fact.cost==2 and fact.mana==10 and g.Cards.Rules.SPECS.shockwave.casting.parts==["hand"],"WAVE both-face hand spell pays two energy and ten mana")
 var before=g.export_snapshot()
 t.check(not g.dispatch(g.command(fact.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"WAVE stale application leaves targets and payments unchanged")
 t.check(t.action(g,"card",{"uid":spell.uid,"free":false}).ok and g.state.energy==28 and g.state.mana==30 and g.state.exhaust.any(func(c):return c.uid==spell.uid),"WAVE bound shockwave pays once and exhausts")
 t.check((g.state.enemies+g.action_targets()).all(func(e):return g.Cards.vulnerable(g,e.id)==4) and not toy.is_empty(),"WAVE marks every present enemy and worn target including special equipment")
 t.check(is_equal_approx(g.escape_preview(thigh,"strain",4).damage,attack*1.5) and is_equal_approx(g.escape_preview(thigh,"slip",4).damage,slip),"WAVE vulnerability multiplies struggle only")
 var newcomer=g.add_fixture("ankle",4)
 t.check(g.Cards.vulnerable(g,newcomer.id)==0 and g.get_view().statuses.any(func(s):return s.owner==g.state.enemies[0].id and s.badge=="4"),"WAVE current targets have visible stacks and later equipment starts clean")
 var twin=Save.roundtrip(t,g,"shockwave enemy and equipment stacks")
 if twin!=null: t.check(twin.Cards.vulnerable(twin,toy.id)==4,"WAVE special equipment vulnerability survives real save")
 var invalid=g.export_snapshot();invalid.combat.vulnerable[toy.id]=-1
 t.check(not g.restore_snapshot(invalid).ok,"WAVE invalid stack count rejected")
 invalid=g.export_snapshot();invalid.combat.vulnerable["never_equipped"]=4
 t.check(not g.restore_snapshot(invalid).ok and g.Cards.vulnerable(g,toy.id)==4,"WAVE unknown target cannot enter restored combat")
 var removed=g.add_fixture("calf",4)
 g.Cards.add_vulnerable(g,removed.id,4);removed.durability=0;g._cleanup()
 var clean=g.export_snapshot()
 t.check(not clean.combat.vulnerable.has(removed.id) and g.restore_snapshot(clean).ok,"WAVE removed targets leave no dangling save reference")
 t.check(Give.play(t,g,"shockwave",true).ok and g.state.card_buff_uses.get("slippery")==3 and g.Cards.vulnerable(g,toy.id)==4 and g.Cards.vulnerable(g,g.state.enemies[0].id)==8,"WAVE free adds slippery and extends only enemy vulnerability")
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.Cards.vulnerable(g,toy.id)==3 and g.state.card_buff_uses.get("slippery")==2,"WAVE end and start each remove one respective layer")
 g=fresh();g._install_assembly("wrap","left","fixture",1,1);g._install_assembly("wrap","right","fixture",1,1)
 for free in [false,true]:
  spell=Give.give(g,"shockwave");before=g.export_snapshot()
  t.check(not t.action(g,"card",{"uid":spell.uid,"free":free}).ok and g.state==before,"WAVE both faces reject blocked hand with no side effects")

static func slippery(t) -> void:
 var g=fresh()
 g.Cards.grant_buff(g,"slippery",3)
 var tight=g.add_fixture("ankle",10)
 var loose=g.add_fixture("thigh",3)
 var special=g._install_special("vaginal_egg_low","special_3_a",3)
 var assembly=g._install_assembly("wrap","left","fixture",2,2)
 t.check(g.equipment_tier(tight)==2 and loose.durability==3 and g.equipment_tier(special)==2 and assembly.components.all(func(e):return g.equipment_tier(e)==1),"WAVE slippery lowers ordinary, special and composite pieces once, leaving tier one intact")
 t.check(g.state.card_buff_uses.slippery==3,"WAVE slippery counts turns rather than installations")
 g=fresh();g.Cards.grant_buff(g,"slippery")
 var anchor=g._install_template("rope","forearm",4,8,false,"fixture",1,-1,0,"mid_forearm")
 var wrist=g._install_template("rope","wrist",4,8,false,"fixture")
 var linked=g._install_link(anchor.id,wrist.id,g.Equipment.maximum(1),"fixture")
 t.check(not linked.is_empty() and g.equipment_tier(linked)==2,"WAVE new link receives the same one-tier reduction")
 g=fresh();g.state.strength=8
 var high=g.add_fixture("thigh",10)
 var baseline=g.escape_preview(high,"magic_slip",5).damage
 t.check(g.escape_preview(high,"slip",5).immune,"YIELD ordinary slip starts immune at tier three")
 t.check(Give.play(t,g,"yield_force",false).ok and g.RelicEffects.attribute(g,"strength")==6,"YIELD bound applies strength penalty")
 t.check(not g.escape_preview(high,"slip",5).immune and is_equal_approx(g.escape_preview(high,"magic_slip",5).damage,baseline*1.5),"YIELD bound opens tier three and multiplies magic slip")
 var duplicate=Give.give(g,"yield_force");var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":duplicate.uid,"free":false}).ok and g.state==before,"YIELD duplicate bound is unique and rejects payment")
 t.check(t.action(g,"card",{"uid":duplicate.uid,"free":true}).ok and Give.play(t,g,"yield_force",true).ok and g.RelicEffects.attribute(g,"strength")==2,"YIELD two free copies coexist with unique bound")
 g.Cards.begin_turn(g);g.Cards.begin_turn(g)
 t.check(g.state.card_buff_uses.get("slippery")==3,"YIELD existing layer expires before both free powers grant new layers")

static func martial(t) -> void:
 var g=fresh();var enemy=g.state.enemies[0]
 Give.play(t,g,"find_weakness",false);Give.play(t,g,"find_weakness",true)
 var hp=g._enemy(enemy.id).hp
 t.check(t.action(g,"attack",{"type":"fireball","enemy":enemy.id}).ok and g.Cards.vulnerable(g,enemy.id)==0,"WEAKNESS spells never consume a martial mark")
 hp=g._enemy(enemy.id).hp
 t.check(t.action(g,"attack",{"type":"strike","form":1,"enemy":enemy.id}).ok and g._enemy(enemy.id).hp==hp-8 and g.Cards.vulnerable(g,enemy.id)==2,"WEAKNESS multi-hit marks after complete attack")
 hp=g._enemy(enemy.id).hp
 t.check(t.action(g,"attack",{"type":"strike","form":0,"enemy":enemy.id}).ok and g._enemy(enemy.id).hp==hp-12 and g.Cards.vulnerable(g,enemy.id)==2,"WEAKNESS vulnerable physical hits gain fifty percent and do not grow stacks")
 t.check(t.action(g,"attack",{"type":"kick","form":1,"enemy":enemy.id}).ok and g.Cards.vulnerable(g,enemy.id)==4 and g.Cards.vulnerable(g,g.state.enemies[1].id)==2,"WEAKNESS a sweep grants two layers to each hit enemy exactly once")
 Give.play(t,g,"find_weakness",true);Give.play(t,g,"find_weakness",true);Give.play(t,g,"find_weakness",false)
 t.check(t.action(g,"attack",{"type":"heavy","form":1,"enemy":enemy.id}).ok and g.Cards.vulnerable(g,enemy.id)==10 and not g.state.card_buff_uses.has("find_weakness_hand"),"WEAKNESS mixed-limb strike resolves every armed copy once")

static func chant(t) -> void:
 var g=fresh()
 var initial=g.state.deck.filter(func(c):return c.type=="dual_chant")
 t.check(initial.size()==1 and g.state.deck.size()==11 and g.Cards.Rules.SPECS.dual_chant.rarity=="basic","CHANT original starter has one physical dual-faced basic card")
 var card=Give.give(g,"dual_chant");var fact=t.find_action(g,"card",{"uid":card.uid,"free":true})
 var metadata=g.Cards.text_entry(g,"dual_chant",card.uid)
 t.check(fact.cost==1 and fact.mana==10 and metadata.face_titles=={"bound":"沉稳咏唱","free":"即刻咏唱"} and g.Cards.Rules.SPECS.dual_chant.casting.parts==["mouth"],"CHANT both named faces share mouth casting and initial cost")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.card_buff_uses.get("instant_chant")==1 and g.state.discard.any(func(c):return c.uid==card.uid and c.exhaust_spent==1),"CHANT first success discards with one use left")
 g.state.energy=0;g.state.mana=0
 var skill=Give.give(g,"find_weakness")
 t.check(t.action(g,"card",{"uid":skill.uid,"free":true}).ok and g.state.card_buff_uses.get("instant_chant")==1,"CHANT skills preserve next-magic charges")
 var same=g.state.discard.filter(func(c):return c.uid==card.uid)[0]
 g.state.discard.erase(same);g.state.hand.append(same)
 fact=t.find_action(g,"card",{"uid":card.uid,"free":false})
 t.check(fact.valid and fact.cost==0 and fact.mana==0 and t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.exhaust.any(func(c):return c.uid==card.uid) and not g.state.card_buffs.has("instant_chant"),"CHANT opposite face spends the waiver and exhausts the same card on use two")
 g.state.mana=50;g.state.energy=10;g.state.pressure=75
 var fire=g.cast_view(g.Cards.cast_profile(g,"fireball",false))
 t.check(fire.chance<1 and g.state.card_buff_uses.get("steady_chant")==1,"CHANT guarantee excludes basic Fireball")
 var wave=Give.give(g,"shockwave");var chances=g.Cards.text_entry(g,"shockwave",wave.uid)
 t.check(chances.face_casting.bound.chance==1 and t.action(g,"card",{"uid":wave.uid,"free":false}).ok and not g._magic_failed and not g.state.card_buffs.has("steady_chant"),"CHANT next magic card consumes the guarantee and casts successfully")
 g=fresh();g.state.pressure=75;g.state.mana=0;g.state.energy=0
 g.Cards.grant_buff(g,"instant_chant")
 wave=Give.give(g,"shockwave")
 wave.enchantment="assist"
 g.state.deck.filter(func(c):return c.uid==wave.uid)[0].enchantment="assist"
 var assisted=t.find_action(g,"card",{"uid":wave.uid,"free":true})
 t.check(assisted.valid and assisted.mana==0 and assisted.cost==0,"CHANT free magic covers assist enchantment surcharge")
 preload("res://tests/practiced_cases.gd").force_failure(g,"shockwave")
 var failed=t.action(g,"card",{"uid":wave.uid,"free":true})
 t.check(failed.ok and g._magic_failed and g.state.mana==0 and g.state.energy==0 and g.state.hand.any(func(c):return c.uid==wave.uid) and not g.state.combat.has("vulnerable") and not g.state.card_buffs.has("slippery") and not g.state.card_buffs.has("instant_chant"),"CHANT failed free Shockwave spends only its waiver, retains the spell and applies no stacks")
 g.Cards.grant_buff(g,"instant_chant");g.Cards.grant_buff(g,"steady_chant")
 var all_mana=Give.give(g,"endless_war_goddess")
 all_mana.enchantment="assist"
 g.state.deck.filter(func(c):return c.uid==all_mana.uid)[0].enchantment="assist"
 var quote=t.find_action(g,"card",{"uid":all_mana.uid,"free":false})
 t.check(quote.valid and quote.cost==0 and quote.mana==0 and g.Cards.text_entry(g,all_mana.type,all_mana.uid).face_mana.bound.is_empty() and t.action(g,"card",{"uid":all_mana.uid,"free":false}).ok and not g._magic_failed,"CHANT zero-resource waiver covers the spend-all magic price on the card and at checkout")
 g.Cards.grant_buff(g,"instant_chant");g.Cards.grant_buff(g,"steady_chant")
 g.Cards.finish_battle_effects(g)
 t.check(not g.state.card_buff_uses.has("instant_chant") and not g.state.card_buffs.has("steady_chant"),"CHANT unused next-card effects clear at victory")
 g._start_preparation();g.state.mana=50;g.state.energy=6
 var study_card=Give.give(g,"study")
 for free in [false,true]:
  var before=g.export_snapshot()
  t.check(not t.action(g,"card",{"uid":study_card.uid,"free":free}).ok and g.state==before,"STUDY battle-only card rejects post-victory play without payment")

static func chant_outside_battle(t) -> void:
 for phase in ["prepare","rest","prison"]:
  for free in [false,true]:
   var g=Give.Game.new(42,true,"prison_test") if phase=="prison" else fresh()
   match phase:
    "prepare": g._start_preparation()
    "rest": g._start_rest();t.action(g,"rest_begin")
   g.state.energy=4;g.state.mana=50;g.state.pressure=0
   var first=Give.give(g,"dual_chant")
   var result=t.action(g,"card",{"uid":first.uid,"free":free})
   if phase=="rest" and free:
    t.check(not result.ok and g.state.energy==4 and g.state.mana==50,"CHANT rest keeps its shared free-face restriction")
    continue
   var buff="instant_chant" if free else "steady_chant"
   t.check(g.state.phase==phase and result.ok and g.state.card_buff_uses.get(buff)==1 and g.state.mana==40 and g.state.energy==3,"CHANT can be cast in "+phase+" on "+buff)
   var next=Give.give(g,"dual_chant")
   g.state.pressure=75
   var quote=t.find_action(g,"card",{"uid":next.uid,"free":false})
   var casting=g.Cards.text_entry(g,"dual_chant",next.uid).face_casting.bound
   t.check(quote.valid and (quote.cost==0 and quote.mana==0 if free else casting.chance==1),"CHANT applies to the next magic card in "+phase+" on "+buff)
   t.check(t.action(g,"card",{"uid":next.uid,"free":false}).ok and (not g.state.card_buffs.has(buff) if free else g.state.card_buff_uses.get(buff)==1),"CHANT spends one use on the next magic card in "+phase+" on "+buff)
   g.RelicEffects.end_combat(g)
   t.check(not g.state.card_buff_uses.has("steady_chant") and not g.state.card_buff_uses.has("instant_chant"),"CHANT remaining uses clear at the end of "+phase)

static func study(t) -> void:
 var g=fresh();g.state.strength=6;g.state.dexterity=6
 var fire=g.BasicAttacks.fireball_damage(g)
 t.check(Give.play(t,g,"study",true).ok and g.RelicEffects.attribute(g,"strength")==5 and g.RelicEffects.attribute(g,"dexterity")==5 and g.BasicAttacks.fireball_damage(g)==fire+2,"STUDY free face trades both attributes for fireball damage")
 t.check(Give.play(t,g,"study",false).ok and g.RelicEffects.attribute(g,"strength")==7 and g.RelicEffects.attribute(g,"dexterity")==7 and g.BasicAttacks.fireball_damage(g)==fire-2,"STUDY opposite face stacks algebraically for the encounter")
 for i in range(4): Give.play(t,g,"study",false)
 t.check(g.BasicAttacks.fireball_damage(g)==0,"STUDY reduced fireball damage stops at zero")
 g.Cards.finish_battle_effects(g)
 t.check(g.RelicEffects.attribute(g,"strength")==6 and g.RelicEffects.attribute(g,"dexterity")==6 and g.BasicAttacks.fireball_damage(g)==fire,"STUDY encounter cleanup restores both attributes and Fireball")
