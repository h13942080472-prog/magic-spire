extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func run(t) -> void:
 var g=Game.new(42,true,"rope_mass_solo")
 var id=g.state.enemies[0].id
 t.check(g.state.phase=="battle" and g.state.enemies[0].hp==48 and g.Enemies.TYPES.rope_mass.strength==3,"MASS playable strong individual with independent strength")
 var book=preload("res://data/encyclopedia.gd").entries().filter(func(e):return e.category=="enemies" and e.id=="rope_mass")[0]
 t.check(book.group=="强怪" and book.text.contains("分裂") and not book.text.contains("强度"),"MASS encyclopedia shows actual behavior without backend strength")
 var before=g.export_snapshot();g.get_view();g.command_facts()
 t.check(g.state==before and g._enemy(id).intent.kind=="charge","MASS preparation preview is readonly")
 var twin=Save.roundtrip(t,g,"mass charge")
 Save.step_both(t,g,twin,"end")
 t.check(g.state.equipment.is_empty() and g._enemy(id).intent.kind=="apply" and g._enemy(id).intent.grade==2 and g._enemy(id).intent.tier==2 and not g._enemy(id).intent.final,"MASS preparation advances to middle-grade application without installing")
 t.check(t.action(g,"end").ok and g.state.equipment.size()==1 and g.state.equipment[0].grade==2 and g.tier(g.state.equipment[0].durability,g.state.equipment[0].maximum)==2,"MASS announced install creates middle grade tier two")
 t.check(t.action(g,"end").ok and g.tier(g.state.equipment[0].durability,g.state.equipment[0].maximum)==3 and not g._enemy(id).gone and g._enemy(id).intent.kind=="charge","MASS tighten closes loop and prepares again without leaving")
 Save.roundtrip(t,g,"mass second cycle")

 # A published reinforcement with no remaining target uses its action and keeps the cycle.
 g=Game.new(42,true,"rope_mass_solo");id=g.state.enemies[0].id
 t.action(g,"end");t.action(g,"end")
 g.state.equipment[0].durability=0;g._cleanup()
 twin=Save.roundtrip(t,g,"mass last reinforcement piece removed")
 Save.step_both(t,g,twin,"end")
 t.check(g.physical_pieces().is_empty() and g._enemy(id).stage==4 and g._enemy(id).intent.kind=="charge" and g.state.logs.any(func(l):return l.text.contains("没有可以加固")),"MASS empty reinforcement completes its step and returns to preparation")

 # No target when building reinforcement draws this monster's middle-grade application.
 g=Game.new(42,true,"rope_mass_solo");id=g.state.enemies[0].id
 g._enemy(id).stage=3;g._enemy(id).intent=g._plan(g._enemy(id))
 t.check(g._enemy(id).intent.kind=="apply","MASS empty reinforcement generation selects an existing application")
 t.check(t.action(g,"end").ok and g.state.equipment.size()==1 and g.state.equipment[0].grade==2 and g.state.equipment[0].template in g.Enemies.TYPES.rope_mass.install_pool and g.tier(g.state.equipment[0].durability,g.state.equipment[0].maximum)==2 and not g._enemy(id).gone,"MASS generated substitute installs its own middle-grade tier-two equipment and stays")

 g=Game.new(42,true,"rope_mass_solo");id=g.state.enemies[0].id
 var declared=g._enemy(id).intent.duplicate(true)
 g.state.round=2
 g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.check(t.action(g,"attack",{"type":"kick","form":2,"enemy":id}).ok,"MASS preparation can be interrupted")
 t.action(g,"end")
 t.check(g._enemy(id).stage==1 and g._enemy(id).intent==declared and g.state.equipment.is_empty(),"MASS interruption delays the same preparation step")

 # An actual lethal attack creates the children in the same transaction, once.
 g=Game.new(42,true,"rope_mass_solo");id=g.state.enemies[0].id
 g._enemy(id).hp=1
 var candidate=t.find_action(g,"attack",{"type":"strike","enemy":id})
 var version=g.state.version
 t.check(g.dispatch(g.command(candidate.payload,version),version).ok,"MASS lethal formal attack commits")
 var children=g.state.enemies.filter(func(e):return not e.gone)
 t.check(children.size()==2 and children.all(func(e):return e.type=="rope" and e.hp==g.Enemies.TYPES.rope.hp and e.stage==1 and e.spawned_from==id and e.acted_round==g.state.round),"MASS death yields exactly two fresh weak instances")
 t.check(g.state.phase=="battle" and g.state.reward_count==0 and g._enemy(id).defeated and g._enemy(id).intent.is_empty(),"MASS death cancels old plan and suppresses premature reward")
 t.check(children[0].id!=children[1].id and children.all(func(e):return e.id!=id),"MASS parent and children have independent stable IDs")
 t.check(g.get_view().action_log.any(func(l):return l.cue=="enemy.split" and l.text.contains("下一回合")) and g.get_view().enemies.filter(func(e):return not e.gone).all(func(e):return e.intent_icons.any(func(icon):return icon.kind=="wait")),"MASS split result and delayed entry visible")
 before=g.export_snapshot()
 g._defeat_enemy(g._enemy(id))
 t.check(g.state==before and not g.dispatch(g.command(candidate.payload,version),version).ok and g.state==before,"MASS repeated death and stale action cannot spawn twice")
 twin=Save.roundtrip(t,g,"mass split before first child action")
 var invalid=g.export_snapshot();invalid.enemies.pop_back()
 t.check(not g.restore_snapshot(invalid).ok and g.state==before,"MASS missing saved child rejected atomically")
 invalid=g.export_snapshot();invalid.enemies[1].spawned_from="enemy_missing"
 t.check(not g.restore_snapshot(invalid).ok and g.state==before,"MASS invalid child source rejected atomically")
 invalid=g.export_snapshot();invalid.enemies[1].acted_round=0
 t.check(not g.restore_snapshot(invalid).ok and g.state==before,"MASS corrupted birth timing rejected")
 Save.step_both(t,g,twin,"end")
 t.check(g.state.enemies.filter(func(e):return not e.gone).all(func(e):return e.stage==1) and g.state.equipment.is_empty(),"MASS children skip remainder of birth round")
 Save.step_both(t,g,twin,"end")
 t.check(g.state.enemies.filter(func(e):return not e.gone).all(func(e):return e.stage==2) and g.state.equipment.size()==2,"MASS children start normal weak actions next round")

 # Defeat the two children independently; reward is still one per battle.
 g=Game.new(42,true,"rope_mass_solo");id=g.state.enemies[0].id;g._enemy(id).hp=1
 t.action(g,"attack",{"type":"strike","enemy":id})
 var child_ids=g.state.enemies.filter(func(e):return not e.gone).map(func(e):return e.id)
 for child_id in child_ids: g._enemy(child_id).hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":child_ids[0]}).ok and g.state.phase=="battle" and g.state.reward_count==0,"MASS one child defeated keeps battle active")
 t.check(t.action(g,"attack",{"type":"strike","enemy":child_ids[1]}).ok and g.state.phase=="reward" and g.state.reward_count==1,"MASS last child defeated grants exactly one reward")
 Save.roundtrip(t,g,"mass final reward")

 # Enemy-first chronology also defers new children until next round.
 g=Game.new(42,true,"rope_mass_solo");id=g.state.enemies[0].id
 g.state.posture="lie";g.state.order="last";g._enemy_phase();g._enemy(id).hp=1
 t.check(t.action(g,"attack",{"type":"fireball","enemy":id}).ok and g.state.enemies.size()==3,"MASS lethal spell works after enemy-first preparation")
 t.check(g.state.enemies.filter(func(e):return not e.gone).all(func(e):return e.stage==1),"MASS enemy-first split does not immediately act")
 t.check(t.action(g,"end").ok and g.state.enemies.filter(func(e):return not e.gone).all(func(e):return e.stage==2),"MASS enemy-first children act once on next round")

