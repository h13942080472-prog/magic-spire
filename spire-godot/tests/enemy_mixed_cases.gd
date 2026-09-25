extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func run(t) -> void:
 var seen={};var resumed=false
 for seed_value in t.seed_values("enemy_cycle"):
  var g=Game.new(seed_value,true,"mixed_bundle_solo")
  var id=g.state.enemies[0].id
  t.check(g._enemy(id).intent.move=="scatter" and g._enemy(id).hp==56,"MIXED opens with scatter at fifty-six HP")
  for turn in range(5):
   var enemy=g._enemy(id);var plan=enemy.intent.duplicate(true)
   var prior=g.export_snapshot();g.get_view();g.command_facts()
   t.check(g.state==prior,"MIXED published weighted move is stable under queries")
   if plan.move=="swell" and not resumed:
    g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
    if g.level("legs")>0: t.check(t.action(g,"posture",{"dest":"sit","wall":false}).ok,"MIXED reaches a legal seated kick through the formal posture action")
    t.check(t.action(g,"attack",{"type":"kick","form":2,"enemy":id}).ok,"MIXED infused ordinary kick interrupts with its actual posture requirement")
    var twin=Save.roundtrip(t,g,"mixed interrupted swell")
    Save.step_both(t,g,twin,"end")
    t.check(g._enemy(id).intent==plan and g._enemy(id).application_bonus==prior.enemies[0].application_bonus and g._enemy(id).last_move==prior.enemies[0].last_move,"MIXED interrupt preserves selected move, bonus and executed history")
    twin=Save.roundtrip(t,g,"mixed resumed swell")
    Save.step_both(t,g,twin,"end");resumed=true
   else: t.check(t.action(g,"end").ok,"MIXED declared move commits")
   enemy=g._enemy(id);seen[plan.move]=true
   # Tightening can create attached shoulder components; count newly installed roots.
   var delta=g.state.equipment.size()+g.state.links.size()-prior.equipment.size()-prior.links.size()
   if plan.move=="swell":
    t.check(delta==0 and enemy.application_bonus==prior.enemies[0].application_bonus+1,"MIXED swell grants permanent quantity without installing")
   else:
    t.check(delta==plan.count+prior.enemies[0].application_bonus and enemy.application_bonus==prior.enemies[0].application_bonus,"MIXED application uses current permanent bonus once: seed %d turn %d move %s delta %d expected %d" % [seed_value,turn,plan.move,delta,plan.count+prior.enemies[0].application_bonus])
    if plan.move=="roll": t.check(g.physical_pieces().any(func(p):return g.tier(p.durability,p.maximum)==3),"MIXED roll applies then reinforces an eligible piece")
   t.check(enemy.last_move==plan.move and enemy.move_streak<=g.Enemies.TYPES.mixed_bundle.weighted_moves[plan.move].limit,"MIXED actual executed history obeys consecutive limits")
   t.check(g.physical_pieces().all(func(p):return p.grade==1) and g.validate()=="","MIXED generated equipment and resulting state are valid")
  if seed_value==t.seed_values("enemy_cycle")[0]:
   Save.roundtrip(t,g,"mixed weighted history and bonus")
   var before=g.export_snapshot();var broken=before.duplicate(true)
   broken.enemies[0].move_streak=3
   t.check(not g.restore_snapshot(broken).ok and g.export_snapshot()==before,"MIXED corrupted move history rejects atomically")
 t.check(seen.size()==3 and resumed,"MIXED sampled real histories cover all three moves and interruption")
 var pair=Game.new(42,true,"mixed_pair")
 t.check(pair.state.enemies.size()==2 and pair.state.enemies.all(func(e):return e.type=="mixed_bundle" and e.hp==56),"MIXED strong recipe produces two full-strength bundles")
 var twin=Save.roundtrip(t,pair,"mixed strong pair")
 Save.step_both(t,pair,twin,"end")
 t.check(pair.physical_pieces().size()+pair.state.links.size()==4,"MIXED both members independently execute their opening action")
