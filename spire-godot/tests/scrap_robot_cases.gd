extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func fixture(owned: bool=true):
 var g=Game.new(42);g.state.relics=[];g.state.energy=30;g.state.enemies=[]
 g._append_enemies([{"type":"drone","grade":1},{"type":"binding_box","grade":1},{"type":"rope","grade":1}])
 for enemy in g.state.enemies: enemy.intent=g._plan(enemy)
 if owned: g.RelicEffects.gain(g,"scrap_robot")
 return g

static func run(t) -> void:
 var g=fixture(false)
 var excluded=g.Relics.REWARDS.filter(func(id):return id!="scrap_robot")
 t.check(g.Relics.TYPES.scrap_robot.rarity=="uncommon" and "scrap_robot" in g.Relics.shop_pool() and preload("res://tests/rolling_log_cases.gd").offer_tier(g,"uncommon",excluded)=="scrap_robot","SCRAP uncommon relic can be offered in rewards and shops")
 for owned in [false,true]:
  for enemy_type in ["drone","binding_box","rope"]:
   for form in [0,1]:
    g=fixture(owned)
    var target=g.state.enemies.filter(func(e):return e.type==enemy_type)[0]
    var id=target.id;var hp=target.hp
    var c=t.find_action(g,"attack",{"type":"strike","form":form,"enemy":id})
    var multiplier=(0.75 if owned else 0.5) if enemy_type!="rope" else 1.0
    var expected=c.payload.damage*multiplier
    t.check(c.valid and c.brief==g.number(expected)+(" × 2" if form==1 else "")+" 伤害","SCRAP single and multi-hit previews use target armor: "+str([owned,enemy_type,form]))
    var before=g.export_snapshot();g.get_view();g.command_facts()
    t.check(g.state==before and not g.dispatch(g.command(c.payload,g.state.version-1),g.state.version-1).ok and g.state==before,"SCRAP preview and stale submission cannot change enemy health or relic state")
    t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and is_equal_approx(g._enemy(id).hp,hp-expected*c.payload.hits),"SCRAP real physical hit agrees with preview: "+str([owned,enemy_type,form]))
 g=fixture();var hp={}
 for e in g.state.enemies: hp[e.id]=e.hp
 var sweep=t.find_action(g,"attack",{"type":"kick","form":1})
 t.check(g.candidate_detail(sweep).contains("减少25%") and g.dispatch(g.command(sweep.payload,g.state.version),g.state.version).ok,"SCRAP all-target preview describes current mechanical reduction")
 for e in g.state.enemies:
  t.check(is_equal_approx(e.hp,hp[e.id]-sweep.payload.damage*(0.75 if e.type!="rope" else 1.0)),"SCRAP mixed group resolves each target separately: "+e.type)
 for damage_type in ["magic","fixed"]:
  g=fixture();var target=g.state.enemies[0];var id=target.id;var old_hp=target.hp
  g._damage_enemy(target,8,damage_type,"test")
  t.check(g._enemy(id).hp==old_hp-8,"SCRAP leaves magic and fixed damage unchanged: "+damage_type)
 g=fixture();var target=g.state.enemies[0];var id=target.id;var old_hp=target.hp
 var fire=t.find_action(g,"attack",{"type":"fireball","enemy":id})
 t.check(g.dispatch(g.command(fire.payload,g.state.version),g.state.version).ok and g._enemy(id).hp==old_hp-fire.payload.damage,"SCRAP real fireball retains full damage")
 g=fixture()
 var snapshot=g.export_snapshot();var restored=Game.new(42);var restoration=restored.restore_snapshot(snapshot)
 t.check(restoration.ok and restored.Enemies.damage_multiplier(restored,"drone","physical")==0.75,"SCRAP current snapshot retains armor override without new state: "+str(restoration))
 var status=g.get_view().statuses.filter(func(s):return s.id=="hard_"+g.state.enemies[0].id)[0]
 t.check(status.value.contains("25%") and status.detail.contains("0.75"),"SCRAP enemy hard status displays effective armor")
 g.state.relics=["ditto"];g.state.ditto_form="scrap_robot"
 t.check(g.Enemies.damage_multiplier(g,"drone","physical")==0.75,"SCRAP transformed relic uses the existing definition resolver")
 g.state.relics.append("scrap_robot")
 t.check(g.Enemies.damage_multiplier(g,"drone","physical")==0.75,"SCRAP duplicate override sets armor rather than adding reductions")
 g.state.relics=[];g.state.ditto_form=""
 t.check(g.Enemies.damage_multiplier(g,"drone","physical")==0.5,"SCRAP absent source restores normal mechanical armor")
 g=preload("res://tests/witch_character_cases.gd").fresh();g.state.enemies=[];g.state.energy=20;g.state.witch_charges.legs=4
 id=g._append_enemies([{"type":"drone","grade":1}])[0].id;g.RelicEffects.gain(g,"scrap_robot")
 var kick=t.find_action(g,"attack",{"type":"witch_legs","form":1,"enemy":id});old_hp=g._enemy(id).hp
 var own_after=g.state.mana-kick.mana_payment.mana
 var expected=kick.payload.damage*0.75*g.Character.damage_multiplier(g,own_after,g.state.temporary_mana-kick.mana_payment.temporary_mana)
 t.check(kick.valid and kick.brief==g.number(expected)+" × 1" and g.dispatch(g.command(kick.payload,g.state.version),g.state.version).ok and is_equal_approx(g._enemy(id).hp,old_hp-expected),"SCRAP witch physical kick preview and execution share armor adjustment: "+str([kick.valid,kick.reason,kick.brief,expected,g._enemy(id).hp,old_hp]))
