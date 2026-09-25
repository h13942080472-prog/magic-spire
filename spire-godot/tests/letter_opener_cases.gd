extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func run(t) -> void:
 var g=Game.new(42)
 g._discard_end();g.state.energy=30
 var hp=g.state.enemies.map(func(e):return e.hp)
 t.check(Cards.play(t,g,"letter_opener",true).ok and g.state.energy==29 and g.state.powers[0].power_progress==0,"OPENER uncommon power pays one energy")
 t.check(Cards.play(t,g,"strain",true).ok and Cards.play(t,g,"slip",true).ok,"OPENER first two real skills")
 t.check(g.state.enemies.map(func(e):return e.hp)==hp and g.state.powers[0].power_progress==2,"OPENER two skills do not trigger")
 t.check(Cards.play(t,g,"mana_invocation",true).ok and Cards.play(t,g,"panic",false).ok,"OPENER magic and curse played normally")
 t.check(g.state.powers[0].power_progress==2,"OPENER excludes magic and curse types")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and g.Cards.progress_text(g,"letter_opener_free")=="2／3张","OPENER count is read-only projection")
 var skill=Cards.give(g,"slip");var c=t.find_action(g,"card",{"uid":skill.uid,"free":true})
 before=g.export_snapshot()
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"OPENER stale skill does not count or damage")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g.state.powers[0].power_progress==0,"OPENER third skill resets count")
 t.check(range(hp.size()).all(func(i):return is_equal_approx(g.state.enemies[i].hp,hp[i]-5)),"OPENER hits every enemy for five")
 for i in range(3): t.check(Cards.play(t,g,"slip",true).ok,"OPENER next batch skill")
 t.check(range(hp.size()).all(func(i):return is_equal_approx(g.state.enemies[i].hp,hp[i]-10)),"OPENER six skills trigger twice")
 t.check(Cards.play(t,g,"slip",true).ok and g.state.powers[0].power_progress==1,"OPENER incomplete next batch")
 var twin=Save.roundtrip(t,g,"opener incomplete skill batch")
 Save.step_both(t,g,twin,"end")
 t.check(g.state.powers[0].power_progress==1,"OPENER actual next turn retains incomplete progress")
 g.state.energy=20;g._discard_end()
 for enemy in g.state.enemies: enemy.hp=5
 for i in range(2): t.check(Cards.play(t,g,"slip",true).ok,"OPENER lethal batch continues from last turn")
 t.check(g.state.phase=="reward" and not g.state.powers.is_empty(),"OPENER lethal proc preserves ability through victory")
 t.check(t.action(g,"reward",{"type":"skip"}).ok and t.action(g,"finish_prepare").ok and g.state.powers.is_empty(),"OPENER ability expires at preparation end")
 t.check(g.state.discard.filter(func(card):return card.type=="letter_opener").all(func(card):return not card.has("power_progress")),"OPENER battle end erases progress")
 equipment(t)
 bound_cross_turn(t)

static func bound_cross_turn(t) -> void:
 var g=Game.new(42);g._discard_end();g.state.energy=20
 var target=g.add_fixture("ankle",10)
 t.check(Cards.play(t,g,"letter_opener",false).ok,"OPENER cross-turn bound ability activates")
 for i in range(2): t.check(Cards.play(t,g,"pleasure_conversion",true).ok,"OPENER bound incomplete batch")
 t.check(t.action(g,"end").ok and g.state.powers[0].power_progress==2,"OPENER bound progress also survives the real turn boundary")
 var damage=g.escape_preview(g._equipment(target.id),"strain",3,[],false,true).damage
 var durability=g._equipment(target.id).durability
 t.check(Cards.play(t,g,"pleasure_conversion",true).ok and g.state.powers[0].power_progress==0 and is_equal_approx(g._equipment(target.id).durability,durability-damage),"OPENER next-turn third skill triggers original bound damage exactly once")
 g.RelicEffects.end_combat(g);g.RelicEffects.begin_combat(g)
 t.check(g.state.powers.is_empty() and g.state.discard.filter(func(card):return card.type=="letter_opener").all(func(card):return not card.has("power_progress")),"OPENER incomplete progress never carries into another battle")

static func equipment(t) -> void:
 var g=Game.new(42);g._discard_end();g.state.energy=30
 var inner=g._install_template("belt","calf",10.0,10.0,false,"fixture",1,0,0,"mid_calf")
 var outer=g._install_template("belt","calf",10.0,10.0,true,"fixture",1,1,0,"mid_calf")
 var other=g.add_fixture("ankle",10)
 var eye=g.add_fixture("eyes",10)
 var ids=[outer.id,other.id,eye.id];var inner_id=inner.id
 g.state.strength=8;g.state.charge=4;g.state.card_buffs=["henshin_free"]
 t.check(Cards.play(t,g,"letter_opener",false).ok,"OPENER bound power can be played while restrained")
 t.check(is_equal_approx(g.escape_preview(g._equipment(outer.id),"strain",3,[],false,true).damage,0.75),"OPENER locked two-layer full-tightness damage is 3 x 0.5 x 0.5 / 2 x 2")
 var expected={}
 for id in ids:
  var e=g._equipment(id);var p=g.escape_preview(e,"strain",3,[],false,true)
  expected[id]=maxf(0,e.durability-p.damage)
  t.check(p.bonus==0 and p.charge==0 and p.assist.bonus==0 and p.environment_true==0 and p.damage_buff_multiplier==2,"OPENER area formula only multiplies base")
 for i in range(3): t.check(Cards.play(t,g,"slip",true,{"slot":"palm"}).ok,"OPENER bound effect counts free skill face")
 for id in ids:
  var e=g._equipment(id)
  t.check(e.is_empty() if expected[id]<=0 else is_equal_approx(e.durability,expected[id]),"OPENER every frozen outer target uses its own full multiplier set")
 t.check(g._equipment(inner_id).durability==10 and g.state.charge==4 and g.state.strength==8,"OPENER inner layer and additive resources unaffected")
 t.check(g.validate()=="","OPENER applied area remains valid")
 # Multi-hit skill counts once and finishes before the triggered wave.
 g=Game.new(42);g._discard_end();g.state.energy=30
 t.check(Cards.play(t,g,"letter_opener",true).ok,"OPENER multi-hit setup")
 for i in range(2): t.check(Cards.play(t,g,"slip",true).ok,"OPENER two skills before multi-hit")
 var target=g.add_fixture("ankle",10)
 var hp=g.state.enemies.map(func(e):return e.hp)
 t.check(Cards.play(t,g,"chain",false,{"target":target.id}).ok and g.state.card_chain.is_empty(),"OPENER multi-hit skill completes through normal continuation")
 t.check(g.state.powers[0].power_progress==0 and range(hp.size()).all(func(i):return is_equal_approx(g.state.enemies[i].hp,hp[i]-5)),"OPENER three hits count as exactly one skill")
 # An outer piece breaking does not add its newly exposed inner piece to this wave.
 g=Game.new(42);g._discard_end();g.state.energy=20
 inner=g._install_template("belt","calf",10.0,10.0,false,"fixture",1,0,0,"mid_calf");inner_id=inner.id
 outer=g._install_template("belt","calf",1.0,10.0,false,"fixture",1,1,0,"mid_calf");var outer_id=outer.id
 t.check(Cards.play(t,g,"letter_opener",false).ok,"OPENER fragile outer setup")
 for i in range(3): t.check(Cards.play(t,g,"pleasure_conversion",true).ok,"OPENER zero-cost skills count")
 t.check(g._equipment(outer_id).is_empty() and g._equipment(inner_id).durability==10,"OPENER destroys low-tightness outer without tunneling or selecting tighter inner")
 # The shared equipment practice contains composite components and independent structures.
 g=Game.new(42,true,"equipment");g._discard_end();g.state.energy=20
 t.check(Cards.play(t,g,"letter_opener",false).ok,"OPENER equipment practice activation")
 var eligible=g.action_targets().filter(func(e):return e.durability>0 and g._outer(e)).map(func(e):return e.id)
 for i in range(3): t.check(Cards.play(t,g,"pleasure_conversion",false).ok,"OPENER legal bound skill in equipment practice rest")
 var damaged=g.state.logs.filter(func(log):return log.data.has("power_damage")).map(func(log):return log.data.power_damage.target)
 t.check(not damaged.is_empty() and damaged.all(func(id):return id in eligible and damaged.count(id)==1) and g.validate()=="","OPENER composite and independent targets are unique, outer and valid")
