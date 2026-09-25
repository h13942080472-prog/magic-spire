extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func play(t,g,type: String,free: bool) -> Dictionary:
 var card=Cards.give(g,type)
 return t.action(g,"card",{"uid":card.uid,"free":free})

static func run(t) -> void:
 var g=Game.new(42)
 g._discard_end();g.state.energy=20
 t.check(play(t,g,"fire_dynamics",false).ok and g.state.energy==19 and g.state.mana==100,"DYNAMICS power costs one energy and no mana")
 for sample in [[0,1.0],[75,0.55]]:
  g.state.pressure=sample[0]
  t.check(is_equal_approx(g.cast_view(g.Cards.cast_profile(g,"fireball")).chance,sample[1]),"DYNAMICS independent addition and upper cap")
 g._install_template("mouth_band","mouth",24.0,24.0,false,"fixture",3,0)
 var view=g.get_view()
 var shot=view.display_facts.filter(func(c):return c.payload.kind=="attack" and c.payload.type=="fireball")[0]
 t.check(shot.valid and shot.casting.percent=="30%" and shot.casting.formula.contains("倍率之后") and g.cast_view(g.Cards.cast_profile(g,"ease")).chance==0,"DYNAMICS additive term follows zero mouth multiplier; other spells unchanged")
 t.check(play(t,g,"fire_mastery",false).ok and is_equal_approx(g.cast_view(g.Cards.cast_profile(g,"fireball")).chance,0.55),"DYNAMICS body exemption and chance addition coexist")
 t.check(play(t,g,"fire_dynamics",true).ok and g.Cards.spell_power(g,"fireball").all_enemies,"DYNAMICS both faces coexist")
 var card=Cards.give(g,"fire_dynamics");var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state==before,"DYNAMICS repeated face rejected atomically")
 var restored=Game.new(7)
 t.check(restored.restore_snapshot(g.export_snapshot()).ok and restored.Cards.spell_power(restored,"fireball").all_enemies and restored.cast_view(restored.Cards.cast_profile(restored,"fireball")).chance==0.55,"DYNAMICS current snapshot restores both effects")
 g.Cards.end_powers(g)
 t.check(not g.Cards.spell_power(g,"fireball").has("all_enemies") and g.cast_view(g.Cards.cast_profile(g,"fireball")).chance==0,"DYNAMICS session cleanup removes both effects")

 g=Game.new(42);g._discard_end();g.state.energy=20;g.state.enemies.clear()
 g._append_enemies([{"type":"rope_mass","grade":2},{"type":"drone","grade":1}])
 t.check(play(t,g,"fire_dynamics",true).ok and play(t,g,"fire_mastery",true).ok,"DYNAMICS area and damage powers activate")
 var mass=g.state.enemies[0].id;var drone=g.state.enemies[1].id
 g._enemy(mass).hp=1
 shot=t.find_action(g,"attack",{"type":"fireball","enemy":mass})
 var hp=g._enemy(drone).hp;var mana=g.state.mana;var energy=g.state.energy;var start=g.state.logs.size()
 t.check(shot.payload.all and shot.detail.contains("全部敌人") and not shot.detail.contains("非魔法") and shot.payload.damage==g.B.FIREBALL_ASSISTED*2,"DYNAMICS area preview retains gesture and damage multipliers")
 t.check(g.dispatch(g.command(shot.payload,g.state.version),g.state.version).ok and g.state.energy==energy-shot.cost and g.state.mana==mana-shot.mana and g.state.combat.attack_uses.fireball==1,"DYNAMICS area cast pays and consumes use only once")
 t.check(g._enemy(mass).gone and g._enemy(drone).hp==maxf(0,hp-shot.payload.damage) and g.state.enemies.filter(func(e):return e.type=="rope").all(func(e):return e.hp==e.max_hp),"DYNAMICS magic ignores hardness and split children escape current wave")
 t.check(g.state.logs.slice(start).filter(func(log):return log.data.has("spell")).size()==1,"DYNAMICS one casting result per area attack")
 g=Game.new(42);g._discard_end();g.state.energy=20
 play(t,g,"fire_dynamics",true);g.state.pressure=99
 shot=t.find_action(g,"attack",{"type":"fireball"})
 var rng=g.state.rng.magic
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"fireball")).winning_rolls: rng=g.state.rng.magic
 g.state.rng.magic=rng
 var health=g.state.enemies.map(func(e):return e.hp)
 mana=g.state.mana;energy=g.state.energy
 t.check(g.dispatch(g.command(shot.payload,g.state.version),g.state.version).ok and g.state.enemies.map(func(e):return e.hp)==health and is_equal_approx(g.state.mana,mana-shot.mana*0.5) and g.state.energy==energy-shot.cost and g.BasicAttacks.usage(g,"fireball").used==0 and g.state.rng.magic==rng+1,"DYNAMICS failed area cast rolls once and pays without any hits")
 g=Game.new(42);g._discard_end();g.state.energy=20
 play(t,g,"fire_dynamics",true);play(t,g,"flame_flourish",false)
 var equipment=g.add_fixture("wrist",8)
 shot=t.find_action(g,"attack",{"type":"fireball","target":equipment.id})
 var other_hp=g.state.enemies.map(func(e):return e.hp)
 t.check(not shot.payload.all and g.dispatch(g.command(shot.payload,g.state.version),g.state.version).ok and g.state.enemies.map(func(e):return e.hp)==other_hp,"DYNAMICS flourish equipment spell stays single target without enemy splash")
