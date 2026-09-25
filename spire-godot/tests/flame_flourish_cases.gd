extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/card_expansion_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func run(t) -> void:
 var g=Game.new(42)
 t.check(g.Cards.Rules.SPECS.flame_flourish.rarity=="uncommon" and "flame_flourish" in g.Cards.Rules.UNCOMMON and "flame_flourish" not in g.Cards.Rules.RARE,"FLAME uncommon rarity agrees with reward and shop pool registration")
 g.state.energy=10
 var enemy=g.state.enemies[0]
 var target=g.add_fixture("thigh",60.0,60.0,true)
 t.check(g.BasicAttacks.usage(g,"fireball").limit==2 and not g.command_facts().any(func(c):return c.payload.get("target","")==target.id and c.payload.kind=="attack"),"FLAME default two casts and no equipment spell before ability")
 t.check(Cards.cast(t,g,"flame_flourish",false).ok and g.state.energy==9 and g.state.mana==100,"FLAME uncommon one-energy ability activates without mana or casting")
 var c=t.find_action(g,"attack",{"target":target.id})
 var before=g.export_snapshot()
 g.get_view();g.command_facts()
 t.check(c.valid and c.payload.damage==g.BasicAttacks.fireball_damage(g)/2 and c.payload.damage_type=="magic" and g.state==before,"FLAME locked equipment preview uses half current fireball without state changes")
 t.check(not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"FLAME stale cast preserves payment, durability and uses")
 g.state.charge=2
 var initial=target.durability
 t.check(t.action(g,"attack",{"target":target.id}).ok and is_equal_approx(g._equipment(target.id).durability,initial-c.payload.damage) and g.state.charge==2,"FLAME equipment takes direct magic damage without spending strain charge")
 t.check(t.action(g,"attack",{"type":"fireball","enemy":enemy.id}).ok and g.BasicAttacks.usage(g,"fireball").remaining==0,"FLAME enemy and equipment spells share two uses")
 before=g.export_snapshot()
 t.check(not t.action(g,"attack",{"target":target.id}).ok and g.state==before and not t.find_action(g,"attack",{"type":"fireball","enemy":enemy.id}).valid,"FLAME third cast rejected for either target before payment")
 t.check(Cards.cast(t,g,"flame_flourish",true).ok and g.BasicAttacks.usage(g,"fireball").remaining==1 and g.state.powers.size()==2,"FLAME free face adds one remaining use without resetting two spent uses")
 var duplicate=Cards.give(t,g,"flame_flourish");before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":duplicate.uid,"free":true}).ok and g.BasicAttacks.usage(g,"fireball").remaining==2,"FLAME repeated free face adds a use without resetting spent uses")
 duplicate=Cards.give(t,g,"flame_flourish");before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":duplicate.uid,"free":false}).ok and g.state==before,"FLAME bound face still refuses duplicates atomically")
 t.check(t.action(g,"attack",{"target":target.id}).ok and g.BasicAttacks.usage(g,"fireball").remaining==1,"FLAME added third use really casts")
 var restored=Save.roundtrip(t,g,"flame ability and shared cast count")
 if restored!=null: t.check(restored.BasicAttacks.usage(restored,"fireball").remaining==1,"FLAME snapshot retains stacked limit and spent uses")
 t.check(t.action(g,"end").ok and g.BasicAttacks.usage(g,"fireball").remaining==4,"FLAME next real player turn refreshes stacked ability limit")
 g.RelicEffects.end_combat(g)
 t.check(g.state.combat.attack_uses.is_empty() and g.state.powers.is_empty() and g.BasicAttacks.usage(g,"fireball").limit==2,"FLAME ending combat clears ability and spent uses")

 g=Game.new(42);g.state.energy=20
 t.check(Cards.cast(t,g,"flame_flourish",false).ok and Cards.cast(t,g,"fire_mastery",true).ok and Cards.cast(t,g,"henshin",true).ok,"FLAME distinct damage abilities activate together")
 g.state.spell_base_bonuses.fireball=1
 target=g.add_fixture("thigh",60.0,60.0,true)
 c=t.find_action(g,"attack",{"target":target.id});initial=target.durability
 t.check(c.payload.damage==(g.B.FIREBALL_ASSISTED+1)*2 and g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(target.id).durability,initial-c.payload.damage),"FLAME permanent bonus and both multipliers applied once before halving")
 t.check(Cards.cast(t,g,"fire_mastery",false).ok and t.find_action(g,"attack",{"target":target.id}).payload.damage==(g.B.FIREBALL+1)*2,"FLAME gesture exemption updates both enemy and equipment damage through one formula")
 var outer=g._install_template(target.template,"thigh",10.0,10.0,false,"fixture",1,1,0,target.points[0])
 t.check(not t.find_action(g,"attack",{"target":target.id}).valid and t.find_action(g,"attack",{"target":outer.id}).valid,"FLAME magic keeps physical outer-layer obstruction")
 t.check(t.action(g,"attack",{"target":outer.id}).ok and g._equipment(outer.id).is_empty() and not g._equipment(target.id).is_empty(),"FLAME destroyed equipment cleans up only selected outer target")

 var failed=false
 for seed_value in range(8):
  g=Game.new(seed_value);g.state.energy=10
  Cards.cast(t,g,"flame_flourish",false)
  target=g.add_fixture("thigh",24.0,24.0)
  g.state.pressure=75
  c=t.find_action(g,"attack",{"target":target.id});before=g.export_snapshot()
  t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok,"FLAME uncertain spell still commits")
  var spell=g.state.logs.filter(func(log):return log.data.has("spell")).back().data.spell
  if not spell.success:
   failed=true
   t.check(g._equipment(target.id).durability==24.0 and g.BasicAttacks.usage(g,"fireball").used==0 and g.state.energy==before.energy-1 and is_equal_approx(g.state.mana,before.mana-c.mana*0.5) and g.state.combat.mana_used,"FLAME failed first spell preserves shared use, pays one energy and half mana without durability damage")
   break
 t.check(failed,"FLAME deterministic sample includes casting failure")
